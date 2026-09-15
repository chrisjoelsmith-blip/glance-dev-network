# Fantasy Football News

NFL player news sorted the way a fantasy manager reads it, plus the waiver
wire's hottest pickups. No key or account needed.

## Settings

| setting | what it is |
|---|---|
| **News for** | `ALL NFL` (default) shows the latest player updates league-wide from RotoWire. Pick a team to see only that team's fantasy players (QB, RB, WR, TE, K) from ESPN, with their position, injury status, body part and expected return. |
| **Waiver wire** | `ADDS` shows who managers are grabbing most on Sleeper in the last 24 hours; `DROPS` shows who they are cutting. |
| **Waiver wire position** | `ALL`, or one of `QB` `RB` `WR` `TE` `K` `DEF` to narrow the waiver page. The news page is not filtered by this. |

## What the pages show

- **News** - one player update at a time, rotating every minute through the
  latest few, with a `1/5` counter. The player's name is the hero, the
  headline sits under it, and a coloured pill and pixel-art icon say what kind
  of news it is before you read a word.
- **Waiver wire** - the top three trending players, one at a time, with a
  flame for adds or an ice cube for drops, the position pill, team, how many
  managers added or dropped him, and `OWNED`: the percentage of Sleeper
  leagues where he is already on a roster.

## The pills

| pill | icon | meaning |
|---|---|---|
| `OUT`, `INJURED RESERVE` (red) | red cross | ruled out, inactive, or on IR |
| `DOUBTFUL` (red-orange) | cross | listed doubtful |
| `QUESTIONABLE`, `INJURY` (amber) | cross | questionable, limited in practice, or hurt |
| `SUSPENDED` (amber) | penalty flag | suspended |
| `CLEARED` (green) | check | full practice, no designation, activated |
| `SIGNED` `TRADED` `RELEASED` `CLAIMED` `PROMOTED` (purple) | swap arrows | roster moves |
| `BOOM` (orange) | flame | touchdowns or a 100-yard day |
| `BUST` (ice) | ice cube | a quiet, fumbling or no-target game |
| `DEPTH CHART` (pink) | clipboard | starter, backup, workload news |
| `STAT LINE` (teal) | football | a box-score line |
| `NEWS` (white) | megaphone | anything else |

When following a team, ESPN's official designation (Out, Injured Reserve,
Doubtful, Questionable) always sets the pill. Otherwise the app reads the
headline for those phrases.

## Notes

- Sources: RotoWire's public NFL news RSS, ESPN's site API, and Sleeper's
  public API. Player news is cached for 10 minutes, trending players for 30.
- The panel redraws every minute so the rotation moves; the feeds are not
  asked that often.
- Nothing new to show is not an error: the page says `ALL QUIET` in green.
- On the 64 panel the pills use short words: `QUES`, `DOUBT`, `IR`, `SUSP`,
  `CLEAR`, `CUT`, `CLAIM`, `UP`, `ROLE`, `STATS`.
