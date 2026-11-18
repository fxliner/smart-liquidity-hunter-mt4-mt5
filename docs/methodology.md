# Methodology and non-repainting scope

This page documents the **v1.11 source behavior**, not an external trading strategy.

## Confirmed swing selection

A pivot requires `SwingStrength = S` bars **on both sides**. In MT4/MT5 series indexing, bar 0 is still forming; a historical sweep candidate at bar `i` can use a swing at `j` only when `j >= i+S+1`. Therefore, the swing must already have been confirmed before the sweep candle.

Candidate levels must be no older than `MaxSwingAge`; when `RequireFreshLevel=true`, intermediary bars that previously breached a level make it ineligible.

## Volatility and penetration

The indicator calculates the simple average of preceding historical true ranges, using

`TR(k) = max(high[k]-low[k], abs(high[k]-close[k+1]), abs(low[k]-close[k+1]))`

for `VolatilityPeriod` older bars. It **does not use future bars** and **does not use a Wilder-smoothed ATR handle**.

`requiredSweep = max(MinSweepPoints × _Point, MinSweepVolRatio × meanTR)`.

## Bullish sweep

All of these conditions must be true for a qualifying **closed** candle `i`:

1. A confirmed, eligible swing low exists.
2. `low[i] < swingLow-requiredSweep` (strict).
3. `close[i] > swingLow` — closing back inside the level.
4. `(min(open[i],close[i])-low[i]) / range × 100 >= MinWickPercent`.
5. `(close[i]-low[i]) / range × 100 >= MinCloseLocationPct`.
6. If `RequireCandleColor` is true, `close[i]>open[i]`.

## Bearish sweep

An eligible confirmed swing high must exist, `high[i]>swingHigh+requiredSweep`, and `close[i]<swingHigh`, with:

- `(high[i]-max(open[i],close[i]))/range × 100 >= MinWickPercent`.
- `(high[i]-close[i])/range × 100 >= MinCloseLocationPct`.
- When required, `close[i]<open[i]`.

If **both bullish and bearish sweeps qualify on the same outside candle**, the signal is suppressed as ambiguous. Zero-range candles fail rejection checks.

## What “non-repainting” means here

The current candle (index 0) **never receives a signal arrow**. The implementation calculates marks for closed candles and updates new signals when new bars begin, avoiding live-candle arrow flicker.

This does **not** mean that every historical annotation is immutable. A broker can revise OHLC history; terminals can load new older data; user inputs can change; and the indicator may rebuild historical buffers. Do not claim that a closed-bar rule eliminates all forms of historical change.

The word **liquidity** is an OHLC-based swing-level proxy: real resting orders, broker stops or order-book data are neither observed nor inferred with certainty.

See [the validation checklist](validation.md). Independent forex education: [FOREXREVIEW.TOP](https://forexreview.top/).
