# MLB Magic Number

MLB Magic Number is a Glance sports app by John McRae. It shows **one club's magic number** (or elimination number) on a 128×32 panel, with that team's mark and colors. Pick any of the 30 MLB clubs. No API key is required.

![MLB Magic Number preview](preview/preview.png)

The panel is a single still: `{TEAM} MAGIC NUMBER` (or `ELIM NUMBER`) across the top, the club mark on the left, and one giant number. Division leaders see the number that clinches the division. Clubs holding a wild-card slot see the number that clinches a playoff berth. Everyone else still in the hunt sees the **tragic number** against the last team in the field.

**MLB Magic Number is not affiliated with or endorsed by Major League Baseball or its clubs.** Club marks are used to identify the selected team.

## Preview

From the Glance Developer Network repository:

```powershell
pip install -e .
gdn studio apps/mlb-magic-number
```

Browser-only preview:

```powershell
gdn preview apps/mlb-magic-number
```

If `gdn` is not on `PATH`, use `python -m gdn.cli` instead.

## Configuration

| Setting | Default | Notes |
|---------|---------|--------|
| **Team** | `Atlanta Braves` | All 30 clubs. The panel title, color, and crest follow this pick. |

Panel size is **128×32**. Refresh is **300 seconds**. HTTP TTL is **300 seconds**, so a game that just went Final updates on the next redraw.

## Pages

| Page | Contents |
|------|----------|
| **main** | Team-colored title, club mark, one hero number (`MAGIC NUMBER`, `ELIM NUMBER`, green `0` if already in, or `OUT`) |

## How the number is computed

The app does **not** copy MLB's precomputed `magicNumber` / `eliminationNumber` fields. Those sometimes drop 1 when a head-to-head tiebreaker is already wrapped up, which disagrees with the published combo used by CBS and similar recaps:

```text
N = 162 + 1 − (leader wins) − (trailer losses)
```

That is "any mix of leader wins and trailer losses totaling N."

| Situation | Leader | Trailer | Title |
|-----------|--------|---------|--------|
| Division rank 1, not yet clinched | The selected club | 2nd place in that division | `MAGIC NUMBER` |
| Wild-card rank 1–3 | The selected club | Wild-card rank 4 (first team out) | `MAGIC NUMBER` |
| Chasing a playoff spot | Wild-card rank 3 (last team in) | The selected club | `ELIM NUMBER` |
| Already clinched | — | — | `MAGIC NUMBER` `0` |
| Eliminated (`E`, or combo hits 0) | — | — | `OUT` |

Worked example after the 2026-09-12 finals: Guardians 75–74 hold AL wild-card 3; Orioles 72–77 are chasing. `163 − 75 − 77 = 11`. The day before (Orioles 72–76, Guardians 75–73) that same formula was 12.

A same-day news recap can lag one Final. This app uses live MLB standings, not a cached article.

## Data source

Keyless public MLB Stats API:

```text
https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season={year}&standingsTypes=regularSeason
```

- **Wins / losses** — `leagueRecord` on each team row
- **Division / wild-card order** — `divisionRank`, `wildCardRank`
- **Clinched / out** — `clinched`, `wildCardEliminationNumber` (`E` means out of the wild-card race)
- **Season year** — `ctx.now.year`, rolled back to the previous season in January and February

Club crests are 30×20 (or shorter) PNGs in `assets/`, drawn at native size.

## Display behavior

- Title font steps `6x8` → `5x7` → `4x5` so `WHITE SOX MAGIC NUMBER` and `NATIONALS ELIM NUMBER` never run off 128 px. `BRAVES MAGIC NUMBER` stays `6x8`.
- Title color is that club's LED-readable brand color (navy clubs use silver or a lifted blue so the letters read on black).
- The hero is `16x20`, then `10x16` / `7x12` if the string would collide with the 30 px mark.
- Magic numbers are white. Elimination numbers are amber. Clinched `0` and `OUT` are green.
- Offseason (no standings row) keeps the mark and shows `--`.
- Fonts are uppercase only. Frames are still images; the next refresh shows new data.

## Errors and empty states

| Situation | Panel |
|-----------|--------|
| MLB standings unreachable | `NO STANDINGS` / `TRY AGAIN LATER` |
| Unknown team setting | `UNKNOWN TEAM` / `PICK A CLUB` |
| Club eliminated | `{TEAM} MAGIC NUMBER` + green `OUT` |
| Already clinched | `{TEAM} MAGIC NUMBER` + green `0` |
| Offseason / team missing from the feed | `{TEAM} MAGIC NUMBER` + dim `--` |

Command-line example:

```powershell
gdn render apps/mlb-magic-number --input "team=Atlanta Braves"
gdn render apps/mlb-magic-number --input "team=Baltimore Orioles"
gdn render apps/mlb-magic-number --input "team=Los Angeles Dodgers"
gdn validate apps/mlb-magic-number
```

## Current technical limitations

- Season length is **162** games. A makeup that creates a 163rd game is not modeled.
- Head-to-head tiebreakers are **not** folded into `N`. MLB.com may show one lower when the leader already owns the season series.
- Wild-card math uses MLB's `wildCardRank` (three wild-card spots, format used since 2022).
- Crests are small LED marks, not full-resolution logos. A few dark marks (Yankees, Royals, White Sox) are lifted so they read on a black panel.
- GDN `http.get` times out at 4 seconds. The 8-request cap is not an issue (one standings call, plus a previous-season retry only if the current year is empty).

## Accuracy

This app reports a combo number computed from official MLB wins and losses. It does not infer clinches from news, models, or tiebreaker speculation. When a recap and the panel disagree, prefer the panel if the standings feed has the later Final.

## Originality and attribution

The 128×32 layout, title/hero split, and Starlark drawing code were created for this app. Records come only from MLB's public Stats API. Club identity marks are used solely to label the selected team.

Built for the [Glance Developer Network](https://github.com/glance-led-dev/glance-dev-network).
