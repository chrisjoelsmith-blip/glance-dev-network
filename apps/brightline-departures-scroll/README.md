# Brightline Departures

The next Brightline train at your Florida station, live from the same feed
that runs the boards on the platforms. No key.

## Settings

| setting | what it is |
|---|---|
| **Station** | Miami, Aventura, Fort Lauderdale, Boca Raton, West Palm Beach or Orlando. |
| **Direction** | `BOTH` shows whichever train is next. `NORTHBOUND` is toward Orlando, `SOUTHBOUND` toward Miami. Miami only has northbound trains and Orlando only southbound, so pick the matching one there or leave it on BOTH. |
| **Board** | `DEPARTURES` for trains leaving your station; `ARRIVALS` for trains coming in, which is the one you want when you are picking someone up. |

## What the pages show

- **Next train** - the time as the hero, where it goes (or, for arrivals,
  where it is from), its track and train number, a status pill, and how
  long until it goes, counted from Brightline's live estimate when the
  board has one. A canceled train names the one after it.
- **Board** - the next three trains as rows with a pill each, and how many
  more are left today in the corner.

## Status pills

| pill | meaning |
|---|---|
| `ON TIME` (green) | running to schedule |
| `BOARDING`, `FINAL CALL`, `LEAVING`, `ARRIVING` (blue) | at the platform now |
| `12 MIN LATE`, `DELAYED` (amber) | the board's delay, in minutes when it gives one |
| `CANCELED` (red) | not running |
| `CLOSED` (grey) | boarding closed, doors shut |

## Notes

- Refresh is every 5 minutes. Platform statuses like FINAL CALL can change
  faster than that, so the countdown is computed from the clock at render
  time rather than trusted from a five-minute-old word.
- When the day's trains are done the panel says so in green; that is not an
  error.
