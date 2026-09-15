# Metrolink Departures

The next Metrolink train at your Southern California station, live from
Metrolink's own train tracker. No key or account needed.

## Settings

| setting | what it is |
|---|---|
| **Station** | Any of Metrolink's 67 stations. |
| **Line** | `ALL LINES`, or one of Antelope Valley, Ventura County, San Bernardino, Riverside, Orange County, Inland Empire-Orange County, 91/Perris Valley, Arrow. `AMTRAK` shows the Pacific Surfliner and Coast Starlight trains that stop at Metrolink stations. |
| **Board** | `DEPARTURES` leaves out trains that end their trip at your station. `ARRIVALS` shows every train pulling in, for when you are picking someone up. |

## What the pages show

- **Next train** - a split-flap countdown in minutes (`NOW` when it is due,
  the clock itself once it is 100 minutes or more away), the line in its
  Metrolink colour, where it is going, a status pill, the track, the
  departure time and the train number.
- **Upcoming** - the next three trains, each opened by a bar in its line
  colour, with the time, destination and a status pill, and how many more
  are due in the corner.
- **Line status** - every Metrolink line and how many of its trains are
  running late right now. The line you picked is drawn in its own colour.

## Status pills

| pill | meaning |
|---|---|
| `ON TIME` (green) | running to schedule |
| `12 MIN LATE` (amber) | delayed; the minutes are estimated minus scheduled time |
| `12 MIN LATE` (red) | Metrolink lists it as an extended delay |
| `CANCELED` (red) | not running |

The left edge of the panel wears the same colour as the pill.

## Notes

- The tracker is a rolling window of the next few hours. A station with no
  train due in that window shows a green `NO TRAINS DUE`, not an error.
- The panel refreshes every minute, matching how often Metrolink updates
  the tracker.
- Data: Metrolink's public train tracker at `rtt.metrolinktrains.com`.
