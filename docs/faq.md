# Frequently asked questions

**Does this detect real institutional stop orders?**  
No. It observes OHLC candle sweeps of previously confirmed swing levels. It does not access order-book depth or actual stop placement.

**Does Smart Liquidity Hunter repaint?**  
It does not calculate signal arrows on the still-forming candle. Historical data corrections, new older history, and parameter changes may still alter past chart output. See [Methodology](methodology.md).

**Why is there no arrow on my chart?**  
The pivot must be confirmed; the penetration must be strictly greater than the minimum, and the freshness, volatility, wick, close-location and optional candle-direction filters must all pass.

**Can this indicator trade for me?**  
No. It is not an Expert Advisor and does not send orders.

**Why do popup/sound/push notifications not work?**  
They default to false. Enable the desired option and ensure the MetaTrader notification system is correctly configured. An alert also requires a new qualifying closed bar.

**Can I run multiple instances on one chart?**  
Yes. Use different `DashboardInstanceId` values (A, B, etc.) to prevent dashboard naming conflicts.

**What are points versus pips?**  
`MinSweepPoints` is in symbol-specific `_Point` units, not universally in whole pips.

**Where can I get installation examples?**  
Read the [FOREXSIGNAL24 tutorial](https://forexsignal24.com/smart-liquidity-hunter/) and the public MQL5 [MT4](https://www.mql5.com/en/code/79545) and [MT5](https://www.mql5.com/en/code/79546) publications.

**Can I fork it?**  
Yes, under the repository's [MIT License](../LICENSE); preserve the copyright/license notices.
