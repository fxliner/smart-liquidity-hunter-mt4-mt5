# Input parameters — Smart Liquidity Hunter v1.11

The table below is transcribed from the released MT4/MT5 source. **Points** mean symbol-specific `_Point` units, which are not always equivalent to a pip.

| Source input | Default | Meaning |
| --- | --- | --- |
| `SwingStrength` | `3` | Bars required on each side of a confirmed swing |
| `MaxSwingAge` | `100` | Maximum pivot age in bars |
| `MaxBarsToScan` | `1000` | Historical scan limit |
| `MinSweepPoints` | `12` | Minimum sweep penetration in symbol points |
| `VolatilityPeriod` | `14` | Historical simple mean true-range lookback |
| `MinSweepVolRatio` | `0.10` | Threshold as fraction of mean true range |
| `MinWickPercent` | `25.0` | Minimum rejection wick as % of candle range |
| `MinCloseLocationPct` | `60.0` | Close location % measured from the relevant extreme |
| `RequireFreshLevel` | `true` | Exclude previously pierced swing levels |
| `RequireCandleColor` | `false` | Require direction-matching candle body |
| `ShowLiquidityLevels` | `true` | Draw candidate swing levels |
| `ShowDashboard` | `true` | Display compact status dashboard |
| `ArrowPaddingPoints` | `8` | Minimum chart arrow offset |
| `ArrowOffsetVolRatio` | `0.18` | Arrow offset as fraction of mean TR |
| `DashboardInstanceId` | `"A"` | Unique dashboard namespace, 1–40 chars |
| `DashboardTextColor` | `clrDodgerBlue` | Dashboard text color |
| `AlertPopup` | `false` | Optional popup alert |
| `AlertSound` | `false` | Optional sound alert |
| `AlertPush` | `false` | Optional push notification |
| `DashboardX` | `15` | Horizontal panel position in pixels |
| `DashboardY` | `30` | Vertical panel position in pixels |

**Validation bounds:** `SwingStrength` must be 1–20; `MaxSwingAge` at least `SwingStrength+1` and at most 2000; `MaxBarsToScan` 50–10000; `VolatilityPeriod` 2–500; rejection percentages 0–100. Distances and offsets must be nonnegative.

**Key formula:** `requiredSweep = max(MinSweepPoints × _Point, MinSweepVolRatio × meanTR)`.

The volatility term is a **simple mean of historical true ranges**, not Wilder's smoothed ATR. See [Methodology](methodology.md) for the exact signal tests.
