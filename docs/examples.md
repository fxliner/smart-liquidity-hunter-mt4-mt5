# Illustrated signal examples (hypothetical)

The numerical scenarios below illustrate conditions in the released source. They are **not backtest results**, live trading records or profit predictions.

## Example 1: bullish sweep

Assume a confirmed swing low of **1.10000**, symbol point size **0.00001**, and an already-calculated required penetration of **0.00012**.

Signal candle: `open 1.10050`, `high 1.10120`, `low 1.09970`, `close 1.10080`.

- Minimum breach: 1.09970 is below `1.10000−0.00012`.
- Re-entry: 1.10080 is above the swing low.
- Lower wick ratio: `(1.10050−1.09970)/(1.10120−1.09970)=53.3%`.
- Close location from low: `(1.10080−1.09970)/0.00150=73.3%`.

Both default rejection percentages pass, but a final signal still depends on the eligible confirmed swing, freshness and complete historical volatility window.

## Example 2: bearish sweep

Assume a confirmed swing high **1.21000** and required penetration **0.00012**.

Signal candle: `open 1.20960`, `high 1.21040`, `low 1.20880`, `close 1.20930`.

- Minimum breach: 1.21040 exceeds `1.21000+0.00012`.
- Re-entry: close is below the swing high.
- Upper wick: `(1.21040−1.20960)/(1.21040−1.20880)=50%`.
- Close location from high: `(1.21040−1.20930)/0.00160=68.75%`.

The wick and close filters pass with defaults; other preconditions still apply.

## Responsible interpretation

An arrow means that a *specific candle pattern* passed these conditions. It is not an instruction to buy or sell. Review market context, spreads, execution conditions and position sizing independently. For additional cost-planning and education tools, visit [FOREXREVIEW.TOP](https://forexreview.top/).
