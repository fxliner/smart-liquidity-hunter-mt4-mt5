# Installation and first run

This guide covers the free **Smart Liquidity Hunter v1.11** release.

## MetaTrader file locations

| Terminal | Compiled indicator from release ZIP | Source file |
| --- | --- | --- |
| MT4 | `bin/MT4/Smart_Liquidity_Hunter_MT4.ex4` | `MQL4/Indicators/Smart_Liquidity_Hunter_MT4.mq4` |
| MT5 | `bin/MT5/Smart_Liquidity_Hunter_MT5.ex5` | `MQL5/Indicators/Smart_Liquidity_Hunter_MT5.mq5` |

An MT4 `.ex4` cannot be run on MT5, nor an MT5 `.ex5` on MT4.

## Steps

1. [Download and extract the v1.11 release](https://github.com/fxliner/smart-liquidity-hunter-mt4-mt5/releases/tag/v1.11).
2. In the terminal, select **File → Open Data Folder**.
3. Copy the appropriate compiled file to **MQL4/Indicators** or **MQL5/Indicators**, according to the terminal version.
4. Restart MetaTrader or right-click **Navigator → Indicators → Refresh**.
5. Attach the indicator to a chart with enough price history. No new arrow is drawn on the currently forming candle.
6. Review the default parameters and configure optional alerts deliberately.

If you prefer compiling the source yourself, open the respective `.mq4` or `.mq5` in that platform's MetaEditor.

## Common issues

- **Not visible in Navigator:** verify your terminal's actual Data Folder and the file extension.
- **Nothing drawn:** allow price history to load; every signal needs a confirmed pivot and all rejection filters to pass.
- **Dashboard missing:** set `ShowDashboard=true` and check dashboard X/Y positioning.
- **Duplicate dashboards:** give each chart instance a distinct `DashboardInstanceId` (for example A and B).
- **No push notification:** `AlertPush` is false by default; MetaTrader also requires push-notification configuration.
- **Unexpected historical changes:** reloads, revised broker history and input changes can trigger a rebuild. See [Methodology](methodology.md).

The full product explanation is at [FOREXSIGNAL24](https://forexsignal24.com/smart-liquidity-hunter/).
