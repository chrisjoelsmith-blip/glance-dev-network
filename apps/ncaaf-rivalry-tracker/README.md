# NCAA College Football Rivalry Tracker – Glance

Display historic college football rivalry series, head-to-head records, rankings, last game outcomes, active winning streaks, and future matchup dates on a wide LED panel.

**Version 1.0** · App ID: `ncaaf-rivalry-tracker`  
**By** [SlaterDen](https://github.com/SlaterDen)

---

## App Settings

| Setting | Required | Description |
|--------|----------|-------------|
| **API Key** | Yes | Your API key from [CollegeFootballData.com](https://collegefootballdata.com/) |
| **Team 1** | Yes | First school, picked from the FBS list (e.g. `Oklahoma`, `Notre Dame`) |
| **Team 2** | Yes | Second school, picked from the FBS list (e.g. `Texas`, `Tennessee`) |
| **Team Name Length** | Yes | Choose between **Abbreviations** or **Full Name** (up to 12 characters + series win tally) |

---

## How to Get Your API Key

1. Go to [CollegeFootballData.com](https://collegefootballdata.com/).
2. Create a free account or sign in to access developer tokens.
3. Generate your API key and paste it into the Glance app settings as **API Key**.

The College Football Data API provides free tiers suitable for personal display tracking.

---

## Pages & Layout

| Page | What's shown |
|------|----------------|
| **Series View** | Team chips in each school's colors with the rivalry name between them, all-time win totals on either side of a tug-of-war bar (ties in gray; the white midfield marker shows who leads), and a footer with the last result, ties, and the next meeting. |
| **First Meeting View** | For teams that have never played: both team chips, **FIRST MEETING**, and the next scheduled date. |

### Reading the panel
* **#N** beside a win total: that team's current ranking (CFP when available, otherwise AP).
* **WN** beside a win total: that team has won the last N meetings.
* **LAST:** Most recent result, winner first.
* **TIES:** Tied games in the series (hidden when there are none).
* **NEXT:** Date of the next scheduled meeting, or TBD.

Team colors come from CFBD and are brightened for the LED. Black team colors use the school's alternate color, and when both teams' colors are too similar the second team switches to its alternate color.

---

## Data Sources

| Source | Used for |
|--------|----------|
| **College Football Data API** (`api.collegefootballdata.com`) | Historical team matchups, past game records, team directories, colors, and live rankings |
| **GitHub Hosted JSON** (`raw.githubusercontent.com/SlaterDen/ncaaf-rivalries`) | Dynamic mapping of classic rivalry game titles and trophies |

This app is **not** affiliated with the NCAA or CollegeFootballData.com. All sports data remains the property of its respective providers.

---

## Errors & Troubleshooting

| What you see | Likely cause | What to try |
|--------------|--------------|-------------|
| **DEMO** in the bottom row | No API key yet, so the panel shows a sample Red River screen | Enter your College Football Data API key in the app settings |
| **TEAM NOT RECOGNIZED** | A saved school name that isn't on the FBS list | Pick Team 1 and Team 2 again from the dropdowns |
| **PICK TWO DIFFERENT TEAMS** | Team 1 and Team 2 are the same school | Choose a different school for one of them |
| **NO SERIES DATA** | CFBD returned no series record for the pair | Try another matchup |
| **CFBD KEY REJECTED** | The API key is invalid or expired | Check the API key in the app settings |
| **CFBD UNAVAILABLE** | Network issue or CFBD is down | Check your key, or wait for the next refresh |

---

## Notes

- Panel: Designed for wide LED panels (e.g., **192×32**).
- Caching: Rivalry metadata uses short TTL caching for rapid testing and updates.

---

## Credits

**SlaterDen** · Built for the [Glance Developer Network](https://glance-led.dev).