# WNBA Leaders (128x32)
#
# The top 3 league-wide leaders in one stat per page (Points, Rebounds,
# Assists, Steals, Blocks, Field Goal Pct, Three-Point Pct, Free Throw
# Pct) - the whole league, no conference split. Data from ESPN's public
# stats-by-athlete API (site.web.api.espn.com) - no key required. Same
# scorebook layout and team-badge system as the MLB/NFL/NHL sibling apps,
# with basketball colors and stats.
#
# Basketball leaders are conventionally shown as per-game averages (PPG/
# RPG/APG/SPG/BPG), not season totals, so the 5 counting-stat pages use
# ESPN's own avg* fields directly rather than a raw total. The three
# shooting-percentage pages rely on ESPN's isqualified=true flag, which
# works correctly for this endpoint: an unqualified sort puts a bench
# player who made their only shot of the season at a flukey 100% on top,
# but isqualified=true filters that out and surfaces real, meaningful-
# volume shooters instead. No pooled/computed workaround is needed here.
#
# Pages in this SDK are a fixed list declared in the manifest, so all 8
# category pages always exist.
#
# DESIGN. Same scorebook as the sibling apps, on a black ground. The top
# row opens on a plain "WNBA" badge in the league's own orange - a single
# fixed color rather than a split pill, since there's no conference input
# to distinguish - then the stat in white and the season in gray. Under
# it, three rows: the rank in gray, a team badge, the last name in white,
# and the number in white against the right edge. The badge is how a fan
# spots their team across a room: the team's code in its own two colors,
# like a jersey. Everything stays 6px inside both edges so the app reads
# as its own unit in the stream.

# id: [code, fill, ink]. Fill is the color the team wears most, ink its
# accent - both taken directly from ESPN's own team color/alternateColor
# fields. Two inks are swapped for a brighter, higher-contrast color where
# the literal ESPN pair is too close in brightness to read as text on this
# fill at 4x5 (brightness delta < 60): the Dream (red fill, a medium blue
# too close in brightness) and the Tempo (two dark colors, neither bright
# enough to read) - both pushed to plain white.
TEAMS = {
    20: ["ATL", "#E31837", "#FFFFFF"],   # Dream: red, white
    19: ["CHI", "#5091CD", "#FFD520"],   # Sky: blue, yellow
    18: ["CON", "#F05023", "#0A2240"],   # Sun: orange, navy
    3: ["DAL", "#002B5C", "#C4D600"],    # Wings: navy, volt green
    129689: ["GS", "#B38FCF", "#000000"],  # Valkyries: violet, black
    5: ["IND", "#002D62", "#E03A3E"],    # Fever: navy, red
    17: ["LV", "#A7A8AA", "#000000"],    # Aces: silver, black
    6: ["LA", "#552583", "#FDB927"],     # Sparks: purple, gold
    8: ["MIN", "#266092", "#79BC43"],    # Lynx: blue, green
    9: ["NY", "#86CEBC", "#000000"],     # Liberty: seafoam, black
    11: ["PHX", "#3C286E", "#FA4B0A"],   # Mercury: purple, orange
    132052: ["POR", "#CEE5EB", "#000000"],  # Fire: ice blue, black
    14: ["SEA", "#2C5235", "#FEE11A"],   # Storm: green, yellow
    131935: ["TOR", "#33476D", "#FFFFFF"],  # Tempo: slate blue, white
    16: ["WSH", "#E03A3E", "#002B5C"],   # Mystics: red, navy
}

# ---------- palette & grid ----------

INK = "#F4F7FF"      # names, live numbers, the stat title
DIM = "#6E7A94"       # ranks, season, sub-lines
AMBER = "#E8B04A"     # the one attention state (feed offline)
WNBA_ORANGE = "#FF6B00"

PAD = 6              # scroll safe zone, both edges
RANK_W = 5           # one 5x7 digit
BADGE_X = PAD + RANK_W + 2  # 13
BADGE_H = 7
NAME_GAP = 2
GAP = 3              # blank px between a name and its value
ROW_Y = [9, 17, 25]  # three 7px rows, 1px apart, under the 8px header row
HEAD_Y = 2           # 4x5 header text, centered on the badge

# Names get one font per page, not per row: a long last name in 4x7 beside a
# short one in 5x7 reads as a mistake. 5x7 when every name on the page fits,
# else 4x7, then a hard clip.
NAME_FONTS = ["5x7", "4x7"]
VALUE_FONT = "5x7"

# ---------- name normalization ----------
# The bitmap fonts only cover plain ASCII - an accented letter renders as a
# stray symbol otherwise, so strip to the closest ASCII letter first.
ACCENT_MAP = {
    "Á": "A", "À": "A", "Â": "A", "Ä": "A", "Ã": "A", "Å": "A",
    "É": "E", "È": "E", "Ê": "E", "Ë": "E",
    "Í": "I", "Ì": "I", "Î": "I", "Ï": "I",
    "Ó": "O", "Ò": "O", "Ô": "O", "Ö": "O", "Õ": "O",
    "Ú": "U", "Ù": "U", "Û": "U", "Ü": "U",
    "Ñ": "N", "Ç": "C", "Ý": "Y",
    "á": "a", "à": "a", "â": "a", "ä": "a", "ã": "a", "å": "a",
    "é": "e", "è": "e", "ê": "e", "ë": "e",
    "í": "i", "ì": "i", "î": "i", "ï": "i",
    "ó": "o", "ò": "o", "ô": "o", "ö": "o", "õ": "o",
    "ú": "u", "ù": "u", "û": "u", "ü": "u",
    "ñ": "n", "ç": "c", "ý": "y",
}

def strip_accents(s):
    out = ""
    for i in range(len(s)):
        ch = s[i]
        out += ACCENT_MAP.get(ch, ch)
    return out

# ---------- color helpers ----------

HEX = "0123456789ABCDEF"

def brightness(hex_color):
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return (r * 299 + g * 587 + b * 114) // 1000

def blend(a, b, pct):
    # pct% of a over b
    out = "#"
    for i in [1, 3, 5]:
        v = (int(a[i:i + 2], 16) * pct + int(b[i:i + 2], 16) * (100 - pct)) // 100
        out += HEX[v // 16] + HEX[v % 16]
    return out

# ---------- network (keyless) ----------

def fetch_leaders(sort_key, qualified = False, limit = 32):
    return http.get(
        "https://site.web.api.espn.com/apis/common/v3/sports/basketball/wnba/statistics/byathlete",
        params = {
            "region": "us",
            "lang": "en",
            "contentorigin": "espn",
            "isqualified": "true" if qualified else "false",
            "seasontype": "2",
            "sort": sort_key + ":desc",
            "limit": str(limit),
        },
        # matches manifest.yaml's refresh - keep in sync
        ttl_seconds = 14400,
    )

def season_of(resp):
    return str((resp.get("json") or {}).get("currentSeason", {}).get("displayName") or "")

# ---------- text helpers ----------

def clip(c, text, font, maxw):
    # Longest prefix that fits - nothing in the API clips on its own.
    t = str(text)
    if c.text_width(t, font) <= maxw:
        return t
    for n in range(len(t), 0, -1):
        if c.text_width(t[:n], font) <= maxw:
            return t[:n]
    return ""

def page_font(c, strings, maxw):
    for f in NAME_FONTS:
        fits = True
        for s in strings:
            if c.text_width(s, f) > maxw:
                fits = False
                break
        if fits:
            return f
    return NAME_FONTS[-1]

def short_name(c, name, maxw):
    # A double-barrelled name that won't fit even in the smallest name font
    # keeps its last half whole rather than clipping mid-word.
    if "-" not in name or c.text_width(name, NAME_FONTS[-1]) <= maxw:
        return name
    parts = name.split("-")
    return parts[0][:1] + "-" + "-".join(parts[1:])

# ---------- chrome ----------

def league_chip(c, x):
    # 7px pill opening the header: 4x5 text with 1px of fill above and
    # below, 2px either side. Always the same orange - there's no
    # conference input, so no second state to distinguish.
    w = c.text_width("WNBA", "4x5") + 4
    c.round_rect(x, 1, x + w - 1, 7, 1, fill = WNBA_ORANGE)
    c.text("WNBA", x + 2, HEAD_Y, font = "4x5", color = "white")
    return x + w

def header(c, titles, season):
    # titles runs longest first; the header takes the first that fits beside
    # the badge and season.
    right = c.width - PAD - 1
    x = league_chip(c, PAD) + 3
    sw = 0
    if season != "":
        sw = c.text_width(season, "4x5")
        c.text(season, right, HEAD_Y, font = "4x5", color = DIM, align = "right")
    room = right - sw - 2 - x
    title = clip(c, titles[-1], "4x5", room)
    for t in titles:
        if c.text_width(t, "4x5") <= room:
            title = t
            break
    c.text(title, x, HEAD_Y, font = "4x5", color = INK)

def message(c, head, sub, head_color):
    # Sits in the band under the header row, so a failed page still says
    # which stat it is.
    w = c.width - 2 * PAD
    c.text(clip(c, head, "5x7", w), c.width // 2, 12, font = "5x7", color = head_color, align = "center")
    c.text(clip(c, sub, "4x5", w), c.width // 2, 23, font = "4x5", color = DIM, align = "center")

# ---------- team badges ----------

def team_style(team_id, team_abbr):
    t = TEAMS.get(team_id)
    if t:
        return t
    # A club this table doesn't know (a bad/missing id, or a brand-new
    # expansion team not yet added): a neutral badge with whatever code
    # ESPN handed us beats a blank.
    return [team_abbr.upper() or "?", "#444444", "#FFFFFF"]

def badge_width(c):
    # One width for every badge so the names start on one column: the
    # widest code (3 chars at 4x5) plus 2px of fill either side.
    w = 0
    for t in TEAMS.values():
        w = max(w, c.text_width(t[0], "4x5"))
    return w + 4

def badge(c, x, y, w, style):
    code, fill, ink = style[0], style[1], style[2]
    # Navy/black/purple fills vanish into the ground, so the dark ones get
    # a rim - a half-tone of their own ink, not gray.
    edge = blend(ink, fill, 50) if brightness(fill) < 64 else fill
    c.round_rect(x, y, x + w - 1, y + BADGE_H - 1, 1, fill = fill, outline = edge)
    c.text(clip(c, code, "4x5", w - 2), x + w // 2, y + 1, font = "4x5", color = ink, align = "center")

# ---------- the leaderboard ----------

def render_leaders(c, titles, season, leaders):
    header(c, titles, season)
    if len(leaders) == 0:
        return message(c, "NO STATS YET", "CHECK BACK IN SEASON", INK)

    rows = []
    for i in range(len(leaders)):
        e = leaders[i]
        rows.append({
            "rank": str(e["rank"]),
            "style": team_style(e["team_id"], e["team_abbr"]),
            "name": strip_accents(e["name"]).upper(),
            "value": str(e["value"]).upper(),
        })

    # Values right-aligned on the edge and measured first; the names get
    # what's left.
    right = c.width - PAD - 1
    bw = badge_width(c)
    name_x = BADGE_X + bw + NAME_GAP
    valw = 0
    for r in rows:
        valw = max(valw, c.text_width(r["value"], VALUE_FONT))
    room = right - valw - GAP - name_x + 1
    for r in rows:
        r["name"] = short_name(c, r["name"], room)
    font = page_font(c, [r["name"] for r in rows], room)

    for i in range(len(rows)):
        r = rows[i]
        y = ROW_Y[i]
        c.text(clip(c, r["rank"], "5x7", RANK_W), PAD + RANK_W // 2, y, font = "5x7", color = DIM, align = "center")
        badge(c, BADGE_X, y, bw, r["style"])
        c.text(clip(c, r["name"], font, room), name_x, y, font = font, color = INK)
        c.text(clip(c, r["value"], VALUE_FONT, valw), right, y, font = VALUE_FONT, color = INK, align = "right")

def is_positive(v):
    # A zero-value entry means the stat hasn't actually happened for that
    # player yet, not a real ranked performance - the rest of the row(s)
    # should stay blank rather than fill with padding.
    s = str(v)
    if s == "" or s == "-":
        return False
    return float(s) > 0.0

def rank_candidates(candidates):
    # Competition-style ranking (1,2,3 or 1,2,2 on a tie) - ESPN's
    # byathlete endpoint doesn't hand us a rank directly, so it's computed
    # here from the already-sorted value order instead.
    leaders = []
    prev_value = None
    prev_rank = 0
    for entry in candidates:
        if not is_positive(entry["value"]):
            continue
        position = len(leaders) + 1
        rank = prev_rank if prev_value != None and entry["value"] == prev_value else position
        prev_value = entry["value"]
        prev_rank = rank
        entry["rank"] = rank
        leaders.append(entry)
        if len(leaders) >= len(ROW_Y):
            break
    return leaders

def draw_leaderboard(c, sort_key, category_name, idx, titles, qualified = False):
    c.clear()

    resp = fetch_leaders(sort_key, qualified = qualified)
    if resp["status_code"] != 200 or resp["json"] == None:
        header(c, titles, "")
        return message(c, "STATS OFFLINE", "TRYING AGAIN SOON", AMBER)

    athletes = resp["json"].get("athletes", [])
    candidates = []
    for a in athletes:
        athlete = a.get("athlete", {})
        team_id = athlete.get("teamId", -1)
        team_id = int(team_id) if team_id != None else -1
        value = ""
        for cat in a.get("categories", []):
            if cat.get("name") == category_name:
                totals = cat.get("totals", [])
                if idx < len(totals):
                    value = totals[idx]
        candidates.append({
            "name": strip_accents(athlete.get("lastName", "?")),
            "team_id": team_id,
            "team_abbr": athlete.get("teamShortName", ""),
            "value": value,
        })
        if len(candidates) >= len(ROW_Y):
            break

    render_leaders(c, titles, season_of(resp), rank_candidates(candidates))

# ---------- pages ----------

def points(c, ctx):
    draw_leaderboard(c, "offensive.avgPoints", "offensive", 1, ["POINTS"])

def rebounds(c, ctx):
    draw_leaderboard(c, "general.avgRebounds", "general", 5, ["REBOUNDS"])

def assists(c, ctx):
    draw_leaderboard(c, "offensive.avgAssists", "offensive", 11, ["ASSISTS"])

def steals(c, ctx):
    draw_leaderboard(c, "defensive.avgSteals", "defensive", 0, ["STEALS"])

def blocks(c, ctx):
    draw_leaderboard(c, "defensive.avgBlocks", "defensive", 1, ["BLOCKS"])

def fgpct(c, ctx):
    draw_leaderboard(c, "offensive.fieldGoalPct", "offensive", 4, ["FIELD GOAL PCT", "FG PCT"], qualified = True)

def tppct(c, ctx):
    draw_leaderboard(c, "offensive.threePointFieldGoalPct", "offensive", 7, ["THREE POINT PCT", "3PT PCT"], qualified = True)

def ftpct(c, ctx):
    draw_leaderboard(c, "offensive.freeThrowPct", "offensive", 10, ["FREE THROW PCT", "FT PCT"], qualified = True)
