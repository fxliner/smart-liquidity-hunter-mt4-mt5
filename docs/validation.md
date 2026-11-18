# Validation checklist — v1.11

This is a **reproducible test plan**, not a certification that every test has passed in every trading environment.

## Installation checks
- [ ] Load compiled EX4 on MT4 and EX5 on MT5 without compile/runtime errors.
- [ ] Verify symbol, timeframe and broker point size.
- [ ] Show dashboard and compare buffers: bullish, bearish and reference levels.
- [ ] Confirm alerts are disabled by default and can be enabled individually.

## Closed-bar behavior
1. Record the last closed candle timestamp and signal arrow positions for unchanged history.
2. Allow several ticks on the still-forming candle. Expect no arrow on index 0.
3. Advance to the next candle; only the newly completed bar may get a new signal, subject to all filters.
4. Reload the **same** fixed historical dataset and parameters; compare historical marks.
5. Deliberately change history or settings to document how a full rebuild can differ.

## Filter boundaries
- [ ] Exactly at the minimum sweep threshold versus **strictly greater** penetration.
- [ ] Exactly at and immediately below the wick and close-location percentages.
- [ ] Fresh versus previously pierced swing levels.
- [ ] Multiple swing-strength values with enough warm-up candles.
- [ ] Same candle sweeping both sides: both arrows suppressed.
- [ ] Invalid parameters rejected (such as `SwingStrength=0`).
- [ ] Two instances on a chart with distinct `DashboardInstanceId` values.

## Issue evidence

In a [bug report](https://github.com/fxliner/smart-liquidity-hunter-mt4-mt5/issues/new/choose), include a terminal build, broker symbol, timeframe, exact parameters, timestamp/timezone and reproducible chart steps. Do **not** include account logins, IDs or sensitive data.
