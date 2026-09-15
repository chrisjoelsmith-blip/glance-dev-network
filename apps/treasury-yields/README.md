# Treasury Yields

The daily yield on the US Treasury bond you pick, with the day's move in
basis points, thirty days of history, and the whole yield curve on a second
page. No API key: the numbers come straight from treasury.gov's daily par
yield curve feed.

## Settings

| setting | what it is |
|---|---|
| **Bond to follow** | Which maturity to show. `10 YEAR` (the default) is the benchmark most people mean by "the bond yield". `2 YEAR` tracks Fed expectations, `30 YEAR` is the long bond, and the bills (`1 MONTH` to `1 YEAR`) track cash rates. |

## What the pages show

- **Yield** - the chosen maturity's closing yield, the change from the
  previous business day in basis points (1 bp = 0.01%), and a 30-day
  sparkline with the newest point lit. The left rail is green when the yield
  rose, red when it fell.
- **Curve** - every maturity from 1 month to 30 years as bars, the one you
  follow lit in ivory. The chip names the shape from the 2s/10s spread:
  `NORMAL` (10-year at least 10 bp above the 2-year), `FLAT`, or `INVERTED`
  (2-year above 10-year), which is the signal bond watchers look for.

## Notes

- Treasury publishes once per business day in the afternoon (Eastern), so
  the panel refreshes hourly and the number carries its date. Weekends and
  market holidays show the last business day.
- Data: <https://home.treasury.gov/resource-center/data-chart-center/interest-rates/>
  (Daily Treasury Par Yield Curve Rates).
