# Smart Liquidity Hunter - MT4 and MT5

Free open-source MetaTrader 4 and MetaTrader 5 indicator, version 1.11.

Smart Liquidity Hunter analyzes confirmed swing high and swing low price sweeps on closed candles. It plots bullish and bearish markers and eligible reference levels, with configurable rejection wick, volatility, freshness and candle-direction filters, a small chart dashboard and optional alerts.

**What it does not do:** This is an OHLC price-action proxy, not access to real resting orders, broker stop-loss data or liquidity pools. It does not place trades or guarantee price reversals.

## Latest download

Download the complete MT4/MT5 package from [GitHub Releases](https://github.com/fxliner/smart-liquidity-hunter-mt4-mt5/releases/latest). The package includes source code, precompiled indicators, screenshots and the MIT license.

## Installation

1. Download the latest ZIP from Releases or the SourceForge Files page.
2. In MetaTrader use File > Open Data Folder.
3. For MT4, copy the EX4 from bin/MT4 into MQL4/Indicators. For MT5, copy the EX5 from bin/MT5 into MQL5/Indicators.
4. Restart or refresh Navigator > Indicators and attach it to a chart.
5. Start with default settings; optional popup, sound and push alerts are disabled initially.

Source code is provided in MQL4/Indicators and MQL5/Indicators. See LICENSE for MIT terms and original contributor attribution.

## Screenshots

![Bullish sweep in MetaTrader 5](Screenshot_1_Bullish_Sweep.png)

![Bearish sweep in MetaTrader 5](Screenshot_2_Bearish_Sweep.png)

## More information
- Developer hub and forex education: https://forexreview.top/
- Indicator documentation: https://forexsignal24.com/smart-liquidity-hunter/
- Official MT5 Market download: https://www.mql5.com/en/market/product/209580
- Free MQL5 Code Base source: https://www.mql5.com/en/code/79546
- Developer profile: https://www.mql5.com/en/users/fxliner

For help, open a GitHub Issue or use the MQL5 product Comments. Include symbol, timeframe, settings and a screenshot without sensitive information.

**Risk notice:** Price patterns and historical signals are not trade recommendations or guarantees of future outcomes.
