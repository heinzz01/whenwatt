# WhenWatt

**Your car doesn't care when it charges. You should.**

Every energy app tells you when the grid is clean. None of them know what you
own — so none of them can tell you whether waiting is worth it.

WhenWatt does. It knows your appliance needs 6 hours and 60 kWh, so it finds the
cheapest *run* of 6 consecutive hours, not the single cheapest hour, and tells
you what that is worth in euros and kilograms.

Built at the ClickHouse AI Hackathon.

---

## The stack, and why each piece is there

| | What it holds | Why |
|---|---|---|
| **ClickHouse** | 6,281,734 rows of 15-minute generation mix (2015–2026) and 82,367 day-ahead prices (Oct 2018–2026) | Every answer is a different slice — the user's country, month, appliance, tolerance. Nothing can be precomputed. |
| **Postgres** | The household's appliances | Small, mutable, written from the browser. OLTP. |
| **Query API Endpoint** | The read path | No backend. ClickHouse *is* the backend. |

The page is one static HTML file. It queries ClickHouse live and falls back to a
built-in copy of the data if the network dies mid-demo.

## The data

Energy-Charts API, Fraunhofer ISE. No API key required.
CC BY 4.0 — Bundesnetzagentur | SMARD.de.

Loading takes one statement: ClickHouse fetches the API itself with `url()`, so
nothing is downloaded to a laptop and re-uploaded. Twelve years of German
generation data lands in about 21 seconds. See `queries.sql`.

## Setup

```bash
cp config.example.js config.js     # then fill in your ClickHouse endpoint + key
python3 -m http.server 8000
```

`config.js` is gitignored. It holds an API key that reaches the browser, so the
endpoint behind it must use a **read-only** database role, an API key with the
**Member** organisation role, and CORS restricted to your own domain.

Without `config.js` the page still runs — on its built-in copy of the data.

## What the numbers say

German day-ahead prices, averaged across eight years:

- The best window flips from **03:00 in winter** to **13:00–14:00 in summer**.
  Solar rewrites the curve halfway through the year, so any fixed rule is wrong
  for half of it.
- In January, February, October, November and December the **cheapest** window is
  not the **cleanest** one. Overnight is cheap but coal-heavy; midday is clean
  but not the price minimum.
- Backtested on 2025 with a rule built only from 2018–2024 — no lookahead:
  **350 of 353 days** beat plugging in at 19:00. Median benefit 88.6 €/MWh.
  Even the worst 5% of days still came out ahead.

## Honest limits

- Assumes a dynamic tariff (Tibber, aWATTar). On a fixed tariff the carbon
  saving still holds; the money saving does not.
- Carbon uses the *average* hourly generation mix. Marginal emissions — what the
  last plant on the grid actually does — would roughly double the numbers and be
  more correct.
- The appliance's availability is not yet modelled. A commuter's car is not
  plugged in at 13:00, and constraining the search to 18:00–07:00 cuts the annual
  saving from €493 to €356.
- Germany only, so far. Every other country is one `INSERT` away.

## Licence

Data: CC BY 4.0 (Fraunhofer ISE / Bundesnetzagentur | SMARD.de).
