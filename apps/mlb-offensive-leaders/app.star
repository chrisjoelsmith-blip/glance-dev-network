# MLB Offensive Leaders (128x32)
#
# The top 3 hitters in one stat per page (AVG/HR/RBI/SB/Hits/Runs/SLG/OPS),
# for MLB overall, the AL, or the NL. Data from MLB's own public Stats API
# (statsapi.mlb.com) - no key required. Sibling app to mlb-pitching-leaders
# and mlb-playoff-picture.
#
# Pages in this SDK are a fixed list declared in the manifest, so all 8
# category pages always exist.
#
# DESIGN. The mlb-pitching-leaders scorebook, on a black ground. The top row
# opens on the MLB batterman in 16x8 pixel art - blue field, red corner, the
# white batter, bat and ball - then an AL red / NL blue chip when a league is
# picked, the stat in white and the season in gray. Under it, three rows: the
# rank in gray, a team badge, the last name in white, and the number in white
# against the right edge. The badge is how a fan spots their team across a
# room: the team's code in its own two colors - orange on navy for the
# Tigers, gold on brown for the Padres, black on gold for the Pirates - like a
# cap patch. Everything stays 6px inside both edges so the app reads as its
# own unit in the stream.

# id: [code, fill, ink]. Fill is the color the team wears most, ink its
# second color. Inks are LED-tuned where the official shade washed out at
# 4x5: the Red Sox/Guardians/Rangers/Twins/Braves reds on navy read as dim
# maroon, so they're pushed brighter, as are the Royals' gold and the
# Mariners' Northwest green.
TEAMS = {
    108: ["LAA", "#BA0021", "#FFFFFF"],  # Angels: red, white
    109: ["AZ", "#A71930", "#E3D4AD"],   # D-backs: Sedona red, sand
    110: ["BAL", "#DF4601", "#000000"],  # Orioles: orange, black
    111: ["BOS", "#0C2340", "#FF4C57"],  # Red Sox: navy, red
    112: ["CHC", "#0E3386", "#FFFFFF"],  # Cubs: blue, white
    113: ["CIN", "#C6011F", "#FFFFFF"],  # Reds: red, white
    114: ["CLE", "#0C2340", "#FF3B4F"],  # Guardians: navy, red
    115: ["COL", "#333366", "#C4CED4"],  # Rockies: purple, silver
    116: ["DET", "#0C2340", "#FA4616"],  # Tigers: navy, orange
    117: ["HOU", "#EB6E1F", "#002D62"],  # Astros: orange, navy
    118: ["KC", "#004687", "#E8C47E"],   # Royals: royal blue, gold
    119: ["LAD", "#005A9C", "#FFFFFF"],  # Dodgers: Dodger blue, white
    120: ["WSH", "#AB0003", "#FFFFFF"],  # Nationals: red, white
    121: ["NYM", "#002D72", "#FF5910"],  # Mets: blue, orange
    133: ["ATH", "#003831", "#EFB21E"],  # Athletics: green, gold
    134: ["PIT", "#FDB827", "#000000"],  # Pirates: gold, black
    135: ["SD", "#2F241D", "#FFC425"],   # Padres: brown, gold
    136: ["SEA", "#0C2C56", "#2FD1C5"],  # Mariners: navy, Northwest green
    137: ["SF", "#27251F", "#FD5A1E"],   # Giants: black, orange
    138: ["STL", "#C41E3A", "#FFFFFF"],  # Cardinals: red, white
    139: ["TB", "#092C5C", "#8FBCE6"],   # Rays: navy, Columbia blue
    140: ["TEX", "#003278", "#FF3B47"],  # Rangers: blue, red
    141: ["TOR", "#134A8E", "#FFFFFF"],  # Blue Jays: blue, white
    142: ["MIN", "#002B5C", "#FF3868"],  # Twins: navy, red
    143: ["PHI", "#E81828", "#FFFFFF"],  # Phillies: red, white
    144: ["ATL", "#13274F", "#FF3A5C"],  # Braves: navy, red
    145: ["CWS", "#27251F", "#C4CED4"],  # White Sox: black, silver
    146: ["MIA", "#00A3E0", "#000000"],  # Marlins: Miami blue, black
    147: ["NYY", "#0C2340", "#FFFFFF"],  # Yankees: navy, white
    158: ["MIL", "#12284B", "#FFC52F"],  # Brewers: navy, gold
}

LEAGUE_ID = {"AL": "103", "NL": "104"}

# ---------- palette & grid ----------

INK = "#F4F7FF"     # names, live numbers, the stat title
DIM = "#6E7A94"     # ranks, season, sub-lines
AMBER = "#E8B04A"   # the one attention state (feed offline)
AL_RED = "#D22D3A"
NL_BLUE = "#2A66D9"

PAD = 6             # scroll safe zone, both edges
RANK_W = 5          # one 5x7 digit
BADGE_X = PAD + RANK_W + 2  # 13
BADGE_H = 7
NAME_GAP = 2
GAP = 3             # blank px between a name and its value
ROW_Y = [9, 17, 25] # three 7px rows, 1px apart, under the 8px logo row
HEAD_Y = 2          # 4x5 header text, centered on the logo

# The MLB batterman, traced from the real mark at 16x8: the ball low in the
# blue field, the batter's cap bill facing it, a sliver of blue between his
# head and the bat, and the bat splitting the red corner off. The logo's navy
# is near-invisible on LEDs, so the field takes the NL blue and the corner the
# AL red - the same two colors as the league chips beside it. Dotted corners
# round it off like the real mark.
LOGO = """
.BBBBBBBBBWRRRR.
BBBBBBBWWWBWRRRR
BBBBBBWWWWBBWRRR
BBBBBBBWWWBBBWRR
BBBBBBBWWWWWWWRR
BBWBBBWWWWWWWWWR
BBBBBBWWWWWWWWWR
.BBBBBWWWWWWWWR.
"""
LOGO_W = 16
LOGO_LEGEND = {"B": NL_BLUE, "R": AL_RED, "W": "#FFFFFF"}

# Names get one font per page, not per row: "CROW-ARMSTRONG" in 4x7 beside
# "JUDGE" in 5x7 reads as a mistake. 5x7 when every name on the page fits,
# else 4x7, then a hard clip.
NAME_FONTS = ["5x7", "4x7"]
VALUE_FONT = "5x7"

# ---------- name normalization ----------
# The bitmap fonts only cover plain ASCII - an accented letter renders as a
# stray symbol (or nothing: "SUAREZ" came out "SUREZ"), so strip to the
# closest ASCII letter first.
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

def league_choice(ctx):
    v = ctx.inputs.get("league", "MLB")
    return v if v in LEAGUE_ID else "MLB"

def fetch_leaders(stat_key, lg, season):
    params = {
        "leaderCategories": stat_key,
        "statGroup": "hitting",
        "season": str(season),
        "sportId": "1",
        "limit": str(len(ROW_Y)),
    }
    if lg in LEAGUE_ID:
        params["leagueId"] = LEAGUE_ID[lg]
    resp = http.get(
        "https://statsapi.mlb.com/api/v1/stats/leaders",
        params = params,
        # matches manifest.yaml's refresh - keep in sync
        ttl_seconds = 14400,
    )

    # [season, leaders]. The season comes from the feed, not the clock: ask
    # for a season that hasn't started and statsapi quietly answers with the
    # last one, so a February panel labelled "2027" would show 2026's board.
    if resp["status_code"] != 200 or type(resp["json"]) != "dict":
        return None
    blocks = resp["json"].get("leagueLeaders") or []
    if len(blocks) == 0 or type(blocks[0]) != "dict":
        return ["", []]
    block = blocks[0]
    return [str(block.get("season") or ""), (block.get("leaders") or [])[:len(ROW_Y)]]

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
    # keeps its last half whole: beside a 5-digit OPS, "CROW-ARMSTRONG"
    # becomes "C-ARMSTRONG" rather than clipping to "CROW-ARMSTRO".
    if "-" not in name or c.text_width(name, NAME_FONTS[-1]) <= maxw:
        return name
    parts = name.split("-")
    return parts[0][:1] + "-" + "-".join(parts[1:])

# ---------- chrome ----------

def league_chip(c, lg, x):
    # 7px pill on the logo's baseline: 4x5 text with 1px of fill above and
    # below, 2px either side.
    w = c.text_width(lg, "4x5") + 4
    c.round_rect(x, 1, x + w - 1, 7, 1, fill = AL_RED if lg == "AL" else NL_BLUE)
    c.text(lg, x + 2, HEAD_Y, font = "4x5", color = "white")
    return x + w

def header(c, lg, titles, season):
    # titles runs longest first; the header takes the first that fits beside
    # the logo, chip and season ("BATTING AVERAGE" with MLB, "BATTING AVG"
    # once an AL/NL chip takes 15px).
    right = c.width - PAD - 1
    c.sprite(LOGO, PAD, 0, legend = LOGO_LEGEND)
    x = PAD + LOGO_W + 3
    if lg in LEAGUE_ID:
        x = league_chip(c, lg, x) + 3
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
    # Sits in the band under the logo row, so a failed page still says
    # which stat and league it is.
    w = c.width - 2 * PAD
    c.text(clip(c, head, "5x7", w), c.width // 2, 12, font = "5x7", color = head_color, align = "center")
    c.text(clip(c, sub, "4x5", w), c.width // 2, 23, font = "4x5", color = DIM, align = "center")

# ---------- team badges ----------

def team_style(team_id, team_name):
    t = TEAMS.get(team_id)
    if t:
        return t
    # A club this table doesn't know (a new id, an expansion team): a
    # neutral badge with the start of its nickname beats a blank.
    code = strip_accents(team_name.split(" ")[-1])[:3].upper()
    return [code or "?", "#444444", "#FFFFFF"]

def badge_width(c):
    # One width for every badge so the names start on one column: the
    # widest code (WSH/NYM, 15px at 4x5) plus 2px of fill either side.
    w = 0
    for t in TEAMS.values():
        w = max(w, c.text_width(t[0], "4x5"))
    return w + 4

def badge(c, x, y, w, style):
    code, fill, ink = style[0], style[1], style[2]
    # Navy, brown and black fills vanish into the ground, so the dark ones
    # get a rim - a half-tone of their own ink, not gray, so a Tigers badge
    # stays navy and orange out to its edge.
    edge = blend(ink, fill, 50) if brightness(fill) < 64 else fill
    c.round_rect(x, y, x + w - 1, y + BADGE_H - 1, 1, fill = fill, outline = edge)
    c.text(clip(c, code, "4x5", w - 2), x + w // 2, y + 1, font = "4x5", color = ink, align = "center")

# ---------- the leaderboard ----------

def leaderboard(c, ctx, stat_key, titles):
    c.clear()
    lg = league_choice(ctx)
    data = fetch_leaders(stat_key, lg, ctx.now.year)
    if data == None:
        # No feed, so no season to vouch for - the logo and stat still say
        # which page this is.
        header(c, lg, titles, "")
        return message(c, "STATS OFFLINE", "TRYING AGAIN SOON", AMBER)
    header(c, lg, titles, data[0])
    leaders = data[1]
    if len(leaders) == 0:
        # Before a first-ever season there's simply no leaderboard - not an
        # error.
        return message(c, "NO STATS YET", "BACK ON OPENING DAY", INK)

    rows = []
    for i in range(len(leaders)):
        e = leaders[i]
        team = e.get("team") or {}
        rows.append({
            "rank": str(e.get("rank", i + 1)),
            "style": team_style(team.get("id", -1), str(team.get("name", ""))),
            "name": strip_accents(str((e.get("person") or {}).get("lastName", "?"))).upper(),
            "value": str(e.get("value", "-")).upper(),
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

# ---------- pages ----------

def avg(c, ctx):
    leaderboard(c, ctx, "battingAverage", ["BATTING AVERAGE", "BATTING AVG"])

def hr(c, ctx):
    leaderboard(c, ctx, "homeRuns", ["HOME RUNS"])

def rbi(c, ctx):
    leaderboard(c, ctx, "rbi", ["RUNS BATTED IN", "RBI"])

def sb(c, ctx):
    leaderboard(c, ctx, "stolenBases", ["STOLEN BASES"])

def hits(c, ctx):
    leaderboard(c, ctx, "hits", ["HITS"])

def runs(c, ctx):
    leaderboard(c, ctx, "runs", ["RUNS"])

def slg(c, ctx):
    leaderboard(c, ctx, "sluggingPercentage", ["SLUGGING PCT"])

def ops(c, ctx):
    leaderboard(c, ctx, "onBasePlusSlugging", ["OPS"])
