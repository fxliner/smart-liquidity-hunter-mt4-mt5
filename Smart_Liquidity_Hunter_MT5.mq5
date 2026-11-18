//+------------------------------------------------------------------+
//| Smart Liquidity Hunter v1.11 - standalone MT4 / MT5 source          |
//| MIT License - Smart Liquidity Hunter contributors                |
//| OHLC-based liquidity proxy. Does not read actual orders/stops.    |
//| Confirmed signals use closed bars only; no automatic trading.    |
//+------------------------------------------------------------------+
#property strict
#property copyright "Smart Liquidity Hunter contributors"
#property link      "https://www.mql5.com/en/code"
#property version   "1.11"
#property description "Closed-bar swing sweeps with rejection, volatility and freshness filters."
#property indicator_chart_window
#property indicator_buffers 4
#ifdef __MQL5__
#property indicator_plots 4
#property indicator_label1 "Bullish liquidity sweep"
#property indicator_type1 DRAW_ARROW
#property indicator_width1 2
#property indicator_label2 "Bearish liquidity sweep"
#property indicator_type2 DRAW_ARROW
#property indicator_width2 2
#property indicator_label3 "Buy-side liquidity (swing high)"
#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_DOT
#property indicator_width3 1
#property indicator_label4 "Sell-side liquidity (swing low)"
#property indicator_type4 DRAW_LINE
#property indicator_style4 STYLE_DOT
#property indicator_width4 1
#endif
#property indicator_color1 clrLimeGreen
#property indicator_color2 clrTomato
#property indicator_color3 clrOrangeRed
#property indicator_color4 clrDeepSkyBlue

//====================================================================
// Shared signal rules in the MT4 and MT5 standalone editions.
// Index 0 is the unfinished candle. All signals are calculated on
// index >= 1 using only information confirmed before that candle.
//====================================================================
input int    SwingStrength        = 3;       // Pivot bars on EACH side
input int    MaxSwingAge          = 100;     // Maximum age of a pivot (bars)
input int    MaxBarsToScan        = 1000;    // Historical bars to calculate
input int    MinSweepPoints       = 12;      // Minimum penetration in points
input int    VolatilityPeriod     = 14;      // Mean true range lookback
input double MinSweepVolRatio     = 0.10;    // Sweep >= ratio * mean TR
input double MinWickPercent      = 25.0;    // Minimum rejection wick / range
input double MinCloseLocationPct = 60.0;    // Close in top/bottom % of candle
input bool   RequireFreshLevel    = true;    // Ignore previously pierced level
input bool   RequireCandleColor   = false;   // Bull close>open; bear close<open
input bool   ShowLiquidityLevels  = true;    // Plot active high/low levels
input bool   ShowDashboard        = true;    // Draw compact chart text
input int    ArrowPaddingPoints   = 8;       // Minimum arrow offset
input double ArrowOffsetVolRatio  = 0.18;    // Arrow offset in mean TR units
input string DashboardInstanceId  = "A";     // Unique per chart instance, 1-40 characters
input color  DashboardTextColor   = clrDodgerBlue;
input bool   AlertPopup           = false;
input bool   AlertSound           = false;
input bool   AlertPush            = false;
input int    DashboardX           = 15;      // Panel distance from left (pixels)
input int    DashboardY           = 30;      // Panel distance from top (pixels)

// Exposed buffers: 0 bullish, 1 bearish, 2 buy-side, 3 sell-side.
double BullSignal[], BearSignal[], BuySideLevel[], SellSideLevel[];
datetime g_last_open_time = 0;
datetime g_last_alert_time = 0;
string g_panel_prefix = "";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ValidInputs()
  {
   return(SwingStrength >= 1 && SwingStrength <= 20 &&
          MaxSwingAge >= SwingStrength + 1 && MaxSwingAge <= 2000 &&
          MaxBarsToScan >= 50 && MaxBarsToScan <= 10000 &&
          MinSweepPoints >= 0 && VolatilityPeriod >= 2 &&
          VolatilityPeriod <= 500 && MinSweepVolRatio >= 0.0 &&
          MinWickPercent >= 0.0 && MinWickPercent <= 100.0 &&
          MinCloseLocationPct >= 0.0 && MinCloseLocationPct <= 100.0 &&
          ArrowPaddingPoints >= 0 && ArrowOffsetVolRatio >= 0.0 &&
          DashboardX >= 0 && DashboardY >= 0 &&
          StringLen(DashboardInstanceId) >= 1 && StringLen(DashboardInstanceId) <= 40 &&
          MathIsValidNumber(MinSweepVolRatio) &&
          MathIsValidNumber(MinWickPercent) &&
          MathIsValidNumber(MinCloseLocationPct) &&
          MathIsValidNumber(ArrowOffsetVolRatio));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSwingHigh(const int j, const int bars, const double &h[])
  {
   if(j - SwingStrength < 0 || j + SwingStrength >= bars)
      return(false);
   for(int n=1; n<=SwingStrength; n++)
     {
      // Equal older highs are permitted, equal newer highs are not.
      if(h[j] <= h[j-n] || h[j] < h[j+n])
         return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSwingLow(const int j, const int bars, const double &l[])
  {
   if(j - SwingStrength < 0 || j + SwingStrength >= bars)
      return(false);
   for(int n=1; n<=SwingStrength; n++)
     {
      // Equal older lows are permitted, equal newer lows are not.
      if(l[j] >= l[j-n] || l[j] > l[j+n])
         return(false);
     }
   return(true);
  }

// Find the nearest ALREADY CONFIRMED pivot, optionally rejecting
// a level if ANY intermediary candle pierced it before bar i.
int FindLevel(const bool highSide, const int i, const int bars,
              const double &h[], const double &l[])
  {
   const int first = i + SwingStrength + 1;
   const int last  = (int)MathMin(i + MaxSwingAge, bars-SwingStrength-1);
   if(first > last)
      return(-1);
// Extremes of bars between i and candidate j. Excludes i and j.
// One forward pass replaces the previous per-candidate nested scan.
   double priorHigh = -DBL_MAX, priorLow = DBL_MAX;
   if(RequireFreshLevel)
      for(int k=i+1; k<first; k++)
        {priorHigh=MathMax(priorHigh,h[k]); priorLow=MathMin(priorLow,l[k]);}
   for(int j=first; j<=last; j++)
     {
      const bool pivot = highSide ? IsSwingHigh(j,bars,h) : IsSwingLow(j,bars,l);
      if(pivot)
        {
         const bool fresh = !RequireFreshLevel ||
                            (highSide ? priorHigh <= h[j]+0.01*_Point :
                             priorLow >= l[j]-0.01*_Point);
         if(fresh)
            return(j);
        }
      if(RequireFreshLevel)
        {priorHigh=MathMax(priorHigh,h[j]); priorLow=MathMin(priorLow,l[j]);}
     }
   return(-1);
  }

// Simple mean of historical true ranges. No future candles and no
// broker-specific iATR handle: same algorithm on both platforms.
// Returns -1 when the complete preceding window is unavailable.
double MeanTRBefore(const int i, const int bars,
                    const double &h[], const double &l[], const double &c[])
  {
   if(i + VolatilityPeriod + 1 >= bars)
      return(-1.0);
   double totalTR = 0.0;
   for(int k=i+1; k<=i+VolatilityPeriod; k++)
     {
      const double tr1 = h[k] - l[k];
      const double tr2 = MathAbs(h[k] - c[k+1]);
      const double tr3 = MathAbs(l[k] - c[k+1]);
      totalTR += MathMax(tr1,MathMax(tr2,tr3));
     }
   return(totalTR / (double)VolatilityPeriod);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RejectionPass(const bool bullish, const int i,
                   const double &o[],const double &h[],
                   const double &l[],const double &c[])
  {
   const double range = h[i] - l[i];
   if(range <= 0.0)
      return(false);
   const double wick = bullish ? (MathMin(o[i],c[i]) - l[i]) :
                       (h[i] - MathMax(o[i],c[i]));
   const double location = bullish ? ((c[i]-l[i])/range)*100.0 :
                           ((h[i]-c[i])/range)*100.0;
   if(100.0*wick/range + 1e-9 < MinWickPercent)
      return(false);
   if(location + 1e-9 < MinCloseLocationPct)
      return(false);
   if(RequireCandleColor && bullish && c[i] <= o[i])
      return(false);
   if(RequireCandleColor && !bullish && c[i] >= o[i])
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateBar(const int i,const int bars,
                  const double &o[],const double &h[],
                  const double &l[],const double &c[])
  {
   BullSignal[i]    = EMPTY_VALUE;
   BearSignal[i]    = EMPTY_VALUE;
   BuySideLevel[i]  = EMPTY_VALUE;
   SellSideLevel[i] = EMPTY_VALUE;

   const int sh = FindLevel(true,i,bars,h,l);
   const int sl = FindLevel(false,i,bars,h,l);
   if(sh >= 0)
      BuySideLevel[i]  = h[sh];
   if(sl >= 0)
      SellSideLevel[i] = l[sl];

// The unfinished bar (0) is shown only as a level extension.
   if(i == 0)
      return;
   const double meanTR = MeanTRBefore(i,bars,h,l,c);
   if(meanTR < 0.0)
      return;
   const double requiredSweep = MathMax(MinSweepPoints*_Point,
                                        MinSweepVolRatio*meanTR);
   bool bull = (sl >= 0 && l[i] < l[sl]-requiredSweep &&
                c[i] > l[sl] && RejectionPass(true,i,o,h,l,c));
   bool bear = (sh >= 0 && h[i] > h[sh]+requiredSweep &&
                c[i] < h[sh] && RejectionPass(false,i,o,h,l,c));

// An outside bar that sweeps both sides is ambiguous, not two trades.
   if(bull && bear)
      return;
   const double padding = MathMax(ArrowPaddingPoints*_Point,
                                  ArrowOffsetVolRatio*meanTR);
   if(bull)
      BullSignal[i] = l[i] - padding;
   if(bear)
      BearSignal[i] = h[i] + padding;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PriceOrDash(const double price)
  {
   return(price == EMPTY_VALUE ? "--" : DoubleToString(price,_Digits));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodLabel()
  {
   string label=EnumToString((ENUM_TIMEFRAMES)_Period);
   StringReplace(label,"PERIOD_","");
   return(label);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPanelLine(const string key,const string words,
                  const int row,const int fontSize,const color textColor)
  {
   const string name = g_panel_prefix + key;
   if(ObjectFind(0,name)<0)
      if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
         return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,DashboardX);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,DashboardY + row*19);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
   ObjectSetString(0,name,OBJPROP_TEXT,words);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard(const int bars,const datetime &time[])
  {
   if(!ShowDashboard)
      return;
   SetPanelLine("Header","SLH v1.11  |  "+_Symbol+"  "+PeriodLabel(),
                0,10,DashboardTextColor);
   SetPanelLine("Levels","Buy-side: "+PriceOrDash(BuySideLevel[0])+
                "  |  Sell-side: "+PriceOrDash(SellSideLevel[0]),
                1,9,DashboardTextColor);
   string last = "Last signal: none in scanned history";
   const int cap = (int)MathMin(MaxBarsToScan,bars-1);
   for(int i=1; i<=cap; i++)
     {
      if(BullSignal[i]!=EMPTY_VALUE)
        {last="Last signal: BULLISH  "+TimeToString(time[i],TIME_DATE|TIME_MINUTES); break;}
      if(BearSignal[i]!=EMPTY_VALUE)
        {last="Last signal: BEARISH  "+TimeToString(time[i],TIME_DATE|TIME_MINUTES); break;}
     }
   SetPanelLine("Last",last,2,9,DashboardTextColor);
   SetPanelLine("Note","OHLC proxy | confirmed closed candles only",3,8,DashboardTextColor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FireClosedBarNotice(const datetime &time[])
  {
   if(!AlertPopup && !AlertSound && !AlertPush)
      return;
   if(time[1] == g_last_alert_time)
      return;
   string kind = "";
   if(BullSignal[1]!=EMPTY_VALUE)
      kind="BULLISH sweep";
   if(BearSignal[1]!=EMPTY_VALUE)
      kind="BEARISH sweep";
   if(kind=="")
      return;
   g_last_alert_time=time[1];
   const string message = "SLH | "+_Symbol+" "+PeriodLabel()+" | "+kind+
                          " | "+TimeToString(time[1],TIME_DATE|TIME_MINUTES);
   if(AlertPopup)
      Alert(message);
   if(AlertSound)
      PlaySound("alert.wav");
   if(AlertPush)
     {
      ResetLastError();
      if(!SendNotification(message))
         Print("SLH: push notification failed, error ",GetLastError());
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RemoveDashboard()
  {
   if(g_panel_prefix=="")
      return;
   ObjectDelete(0,g_panel_prefix+"Header");
   ObjectDelete(0,g_panel_prefix+"Levels");
   ObjectDelete(0,g_panel_prefix+"Last");
   ObjectDelete(0,g_panel_prefix+"Note");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearAllBuffers()
  {
   ArrayInitialize(BullSignal,EMPTY_VALUE);
   ArrayInitialize(BearSignal,EMPTY_VALUE);
   ArrayInitialize(BuySideLevel,EMPTY_VALUE);
   ArrayInitialize(SellSideLevel,EMPTY_VALUE);
  }

// Locate the former open candle by timestamp, including when chart
// history is capped and rates_total does not grow on each new bar.
int NewlyClosedBars(const int bars,const datetime &time[])
  {
   const int cap=(int)MathMin(bars-1,MaxBarsToScan);
   for(int i=1; i<=cap; i++)
      if(time[i]==g_last_open_time)
         return(i);
   return(-1); // Large gap, changed time series, or old marker unavailable.
  }

// Called by the platform-specific OnCalculate wrapper.
int SLHCalculate(const int rates_total,const int prev_calculated,
                 const datetime &time[],const double &open[],
                 const double &high[],const double &low[],
                 const double &close[])
  {
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

   const int minimumBars=(int)MathMax(2*SwingStrength+3,VolatilityPeriod+3);
   if(rates_total < minimumBars)
     {
      ClearAllBuffers();
      g_last_open_time=0;
      RemoveDashboard();
      if(ShowDashboard)
         SetPanelLine("Header","SLH v1.11 | waiting for more price history",0,10,DashboardTextColor);
      return(0);
     }
   bool full=(prev_calculated<=0 || prev_calculated>rates_total || g_last_open_time==0);
   const bool newbar=(g_last_open_time!=time[0]);
// Unexpected size change without a new candle needs a clean rebuild.
   if(!full && !newbar && rates_total!=prev_calculated)
      full=true;
   if(!full && !newbar)
      return(rates_total);

   int added=0;
   if(!full && newbar)
     {
      added=NewlyClosedBars(rates_total,time);
      if(added<1)
         full=true;
     }
   if(full)
      ClearAllBuffers();
   const int maximum=(int)MathMin(MaxBarsToScan,rates_total-2*SwingStrength-2);
   const int start=full ? maximum : (int)MathMin(added,maximum);
   for(int i=start; i>=1; i--)
     {
      if(IsStopped())
         return(0);
      CalculateBar(i,rates_total,open,high,low,close);
     }
// Old output shifts right with every candle. Keep the display bounded
// so a refresh and incremental updates use the same historical window.
   if(!full)
     {
      const int clearTo=(int)MathMin(rates_total-1,maximum+added);
      for(int i=maximum+1; i<=clearTo; i++)
        {
         BullSignal[i]=EMPTY_VALUE;
         BearSignal[i]=EMPTY_VALUE;
         BuySideLevel[i]=EMPTY_VALUE;
         SellSideLevel[i]=EMPTY_VALUE;
        }
     }
   CalculateBar(0,rates_total,open,high,low,close);
   UpdateDashboard(rates_total,time);
// No alerts on attachment, history resets, or catch-up batches.
   if(!full && newbar && added==1)
      FireClosedBarNotice(time);
   g_last_open_time=time[0];
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ValidInputs())
     {Print("SLH: invalid input parameters"); return(INIT_FAILED);}
   if(!SetIndexBuffer(0,BullSignal,INDICATOR_DATA) ||
      !SetIndexBuffer(1,BearSignal,INDICATOR_DATA) ||
      !SetIndexBuffer(2,BuySideLevel,INDICATOR_DATA) ||
      !SetIndexBuffer(3,SellSideLevel,INDICATOR_DATA))
     {Print("SLH: cannot bind indicator buffers"); return(INIT_FAILED);}
   ArraySetAsSeries(BullSignal,true);
   ArraySetAsSeries(BearSignal,true);
   ArraySetAsSeries(BuySideLevel,true);
   ArraySetAsSeries(SellSideLevel,true);
#ifdef __MQL5__
   PlotIndexSetInteger(0,PLOT_ARROW,233); // Up triangle
   PlotIndexSetInteger(1,PLOT_ARROW,234); // Down triangle
   if(!ShowLiquidityLevels)
     {
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
     }
   for(int j=0; j<4; j++)
      PlotIndexSetDouble(j,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"Smart Liquidity Hunter v1.11");
#else
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrLimeGreen);
   SetIndexArrow(0,233);
   SetIndexLabel(0,"Bullish liquidity sweep");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,clrTomato);
   SetIndexArrow(1,234);
   SetIndexLabel(1,"Bearish liquidity sweep");
   SetIndexStyle(2,ShowLiquidityLevels ? DRAW_LINE : DRAW_NONE,
                 STYLE_DOT,1,clrOrangeRed);
   SetIndexLabel(2,"Buy-side liquidity (swing high)");
   SetIndexStyle(3,ShowLiquidityLevels ? DRAW_LINE : DRAW_NONE,
                 STYLE_DOT,1,clrDeepSkyBlue);
   SetIndexLabel(3,"Sell-side liquidity (swing low)");
   for(int j=0; j<4; j++)
      SetIndexEmptyValue(j,EMPTY_VALUE);
   IndicatorDigits(_Digits);
   IndicatorShortName("Smart Liquidity Hunter v1.11");
#endif
   g_last_open_time=0;
   g_last_alert_time=0;
// Object names are chart-local and stable across profile reloads.
// Use a distinct DashboardInstanceId for every copy on the same chart.
   g_panel_prefix="SLH_Dashboard_"+DashboardInstanceId+"_";
   RemoveDashboard(); // Clear this instance's saved labels before rebuilding.
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {RemoveDashboard();}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   return(SLHCalculate(rates_total,prev_calculated,
                       time,open,high,low,close));
  }
//+------------------------------------------------------------------+
