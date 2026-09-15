# MLB Playoff Picture (128x32)
#
# The playoff bracket as it stands right now: 8 pages - an intro card, the
# first-round byes (#1/#2 seeds in each league), AL and NL Wild Card Series
# matchups, AL and NL Division Series previews, and AL and NL "on the
# bubble" pages for the teams just missing the field. Each league's 6-team
# field follows the format used since 2022 (3 division winners seeded 1-3
# by record, 3 wild cards seeded 4-6): #1/#2 bye, #3 hosts #6, #4 hosts #5
# in the Wild Card Round, then #1 hosts the #4/#5 winner and #2 hosts the
# #3/#6 winner in the Division Series.
#
# Data from MLB's own public Stats API (statsapi.mlb.com) - no key required.
# Sibling app to mlb-offensive-leaders / mlb-pitching-leaders, same team
# color source.
#
# DESIGN. A scorebook on a black ground. Every team is the same object on
# every page: a small tile in the team's color carrying its seed, with the
# nickname in white beside it - the color identifies, the white text reads.
# Earlier builds painted whole rows in team colors, and "YANKEES" on navy or
# "RAYS" on Columbia blue were hard to pull off the panel from across a room.
# Each page opens on a league chip (AL red, NL blue) so a viewer knows which
# half of the bracket they're on, the tiles and names sit on one shared
# column grid so the pages line up as they scroll past, and everything stays
# 6px inside both edges so the app reads as its own unit in the stream.
# "@" marks the host, which replaces the old "GAMES IN <CITY>" lines.

TEAM_COLORS = {
    108: ["#BA0021"],  # LAA (Red)
    109: ["#A71930"],  # AZ (Sedona Red)
    110: ["#DF4601"],  # BAL (Orange)
    111: ["#BD3039"],  # BOS (Red)
    112: ["#0E3386"],  # CHC (Cubs Blue)
    113: ["#C6011F"],  # CIN (Red)
    114: ["#E31937"],  # CLE (Red)
    115: ["#333366", "#C4CED4"],  # COL (purple, silver - black dropped, too dark to read as a stripe)
    116: ["#FA4616"],  # DET (Orange)
    117: ["#F4911E"],  # HOU (Orange)
    118: ["#004687"],  # KC (Royal Blue)
    119: ["#005A9C"],  # LAD (Dodger Blue)
    120: ["#AB0003"],  # WSH (Red)
    121: ["#FF5910"],  # NYM (Orange)
    133: ["#EFB21E"],  # ATH (Gold)
    134: ["#FDB827"],  # PIT (Gold)
    135: ["#FFC425"],  # SD (Gold)
    136: ["#005C5C"],  # SEA (Northwest Green)
    137: ["#FD5A1E"],  # SF (Orange)
    138: ["#C41E3A"],  # STL (Cardinal Red)
    139: ["#8FBCE6"],  # TB (Columbia Blue)
    140: ["#003278"],  # TEX (Blue)
    141: ["#134A8E"],  # TOR (Blue)
    142: ["#D31145"],  # MIN (Scarlet Red)
    143: ["#E81828"],  # PHI (Red)
    144: ["#CE1141"],  # ATL (Scarlet)
    145: ["#27251F"],  # CWS
    146: ["#00A3E0"],  # MIA (Miami Blue)
    147: ["#0C2340"],  # NYY (Navy)
    158: ["#12284B"],  # MIL (Navy Blue)
}

AL_ID = 103
NL_ID = 104
LEAGUE_ID = {"AL": AL_ID, "NL": NL_ID}

# ---------- palette & grid ----------

INK = "#F4F7FF"     # names, live numbers
DIM = "#6E7A94"     # labels, meta
STRUCT = "#282828"  # dividers
AMBER = "#E8B04A"   # the one attention state (a tiebreaker on the bubble)
LEAGUE = {"AL": "#D22D3A", "NL": "#2A66D9"}

PAD = 6             # scroll safe zone, both edges
# A 5x7 seed digit with 2px of team color either side. At 7px wide (1px
# margins) a black "6" on the SD gold tile read as "B", and "3" on HOU as "8".
TILE_W = 9
TILE_H = 9
NAME_GAP = 2
MID = 64            # the "@" / divider column
LEFT_TILE = PAD
LEFT_NAME = LEFT_TILE + TILE_W + NAME_GAP   # 17
RIGHT_TILE = MID + 4                        # 68: "@" is x62-66, 1px clear
RIGHT_NAME = RIGHT_TILE + TILE_W + NAME_GAP # 79
NAME_W = 43         # x79-121 on the right; left names (x17-60) stop 1px shy of "@"
ROW_Y = [10, 21]    # two 9px team rows under the 7px chip row

# Names get one font per page, not per row: "GUARDIANS" (53px at 5x7) in
# 4x7 beside "ASTROS" in 5x7 reads as a mistake. 5x7 when every name on the
# page fits, else 4x7 (43px for GUARDIANS), then a hard clip.
NAME_FONTS = ["5x7", "4x7"]

# Original pixel-art baseball for the intro card: white hide, gray rim, red
# seams bowing in toward the middle.
BALL = [
    ".....ssssss.....",
    "...sswwwwwwss...",
    "..srwwwwwwwwrs..",
    ".swrwwwwwwwwrws.",
    ".swwrwwwwwwrwws.",
    "swwwrwwwwwwrwwws",
    "swwwrwwwwwwrwwws",
    "swwwrwwwwwwrwwws",
    "swwwrwwwwwwrwwws",
    "swwwrwwwwwwrwwws",
    "swwwrwwwwwwrwwws",
    ".swwrwwwwwwrwws.",
    ".swrwwwwwwwwrws.",
    "..srwwwwwwwwrs..",
    "...sswwwwwwss...",
    ".....ssssss.....",
]
BALL_LEGEND = {"s": "#8C95A8", "w": INK, "r": "#E03A3E"}
BALL_W = 16

# ---------- color helpers ----------

HEX = "0123456789ABCDEF"

def brightness(hex_color):
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return (r * 299 + g * 587 + b * 114) // 1000

def lighten(hex_color, pct):
    out = "#"
    for i in [1, 3, 5]:
        v = int(hex_color[i:i + 2], 16)
        v = v + (255 - v) * pct // 100
        out += HEX[v // 16] + HEX[v % 16]
    return out

def team_color(team_id):
    # Darkest of the team's colors - it carries the seed digit, and COL's
    # silver would wash the tile out.
    colors = TEAM_COLORS.get(team_id, ["#444444"])
    best = colors[0]
    for col in colors:
        if brightness(col) < brightness(best):
            best = col
    return best

def ink_on(fill):
    # TB's Columbia Blue and the HOU/ATH/PIT/SD golds have no dark option,
    # so the digit flips to black above this brightness.
    return "black" if brightness(fill) > 150 else "white"

# ---------- network (keyless) ----------

def standings(ctx, standings_type):
    resp = http.get(
        "https://statsapi.mlb.com/api/v1/standings",
        params = {
            "leagueId": "103,104",
            "season": str(ctx.now.year),
            "standingsTypes": standings_type,
        },
        # matches manifest.yaml's refresh - keep in sync
        ttl_seconds = 7200,
    )
    if resp["status_code"] != 200 or type(resp["json"]) != "dict":
        return None
    return resp["json"].get("records", [])

def team_info():
    # One call for both abbreviations and nicknames (it was three calls to
    # the same URL). Team names change about once a decade, hence the ttl.
    resp = http.get(
        "https://statsapi.mlb.com/api/v1/teams",
        params = {"sportId": "1"},
        ttl_seconds = 2592000,
    )
    out = {}
    if resp["status_code"] != 200 or type(resp["json"]) != "dict":
        return out
    for t in resp["json"].get("teams", []):
        out[t.get("id")] = {
            "abbr": t.get("abbreviation", ""),
            "name": t.get("teamName", ""),
        }
    return out

# ---------- seeding ----------
# Format used since 2022: 3 division winners seeded 1-3 by record, then the
# top 3 non-division-winners by wild card standing seeded 4-6.

def division_winners(div_records, league_id):
    winners = []
    for block in div_records:
        if block.get("league", {}).get("id") != league_id:
            continue
        for t in block.get("teamRecords", []):
            if t.get("divisionRank") == "1":
                winners.append(t)
    return winners  # up to 3, one per division

def sort_by_league_rank(teams):
    # Small manual sort (<=3 items) - Starlark has no sorted(..., key=...).
    items = list(teams)
    n = len(items)
    for i in range(n):
        for j in range(n - 1 - i):
            r1 = int(items[j].get("leagueRank", "999"))
            r2 = int(items[j + 1].get("leagueRank", "999"))
            if r1 > r2:
                items[j], items[j + 1] = items[j + 1], items[j]
    return items

def wildcard_top3(wc_records, league_id):
    for block in wc_records:
        if block.get("league", {}).get("id") == league_id:
            # the wildCard standingsType block already excludes division
            # winners and sorts the rest by wildCardRank ascending
            return block.get("teamRecords", [])[:3]
    return []

def seeds_for_league(div_records, wc_records, league_id):
    winners = sort_by_league_rank(division_winners(div_records, league_id))
    wc = wildcard_top3(wc_records, league_id)
    seeds = []
    for t in winners:
        seeds.append(t)
    for t in wc:
        seeds.append(t)
    return seeds  # seed order: index 0 = seed 1 ... index 5 = seed 6

def load_seeds(ctx):
    div = standings(ctx, "regularSeason")
    wc = standings(ctx, "wildCard")
    if div == None or wc == None:
        return None
    return {
        "AL": seeds_for_league(div, wc, AL_ID),
        "NL": seeds_for_league(div, wc, NL_ID),
    }

# ---------- text helpers ----------

def clip(c, text, font, maxw):
    # Longest prefix that fits - nothing in the API clips on its own.
    t = str(text)
    if c.text_width(t, font) <= maxw:
        return t
    for k in range(len(t), 0, -1):
        if c.text_width(t[:k], font) <= maxw:
            return t[:k]
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

def team_id_of(t):
    return t.get("team", {}).get("id", -1)

def nickname(t, teams):
    info = teams.get(team_id_of(t))
    if info and info["name"]:
        return info["name"].upper()
    # teams feed down: "New York Yankees" -> "YANKEES" beats a blank row
    return t.get("team", {}).get("name", "???").split(" ")[-1].upper()

def abbrev(t, teams):
    info = teams.get(team_id_of(t))
    if info and info["abbr"]:
        return info["abbr"].upper()
    return nickname(t, teams)[:3]

# ---------- chrome ----------

def chip(c, word, bg, x, right = False):
    # 7px pill: 4x5 text with 1px of fill above and below, 2px either side.
    w = c.text_width(word, "4x5") + 4
    x0 = x - w + 1 if right else x
    c.round_rect(x0, 0, x0 + w - 1, 6, 1, fill = bg)
    c.text(word, x0 + 2, 1, font = "4x5", color = ink_on(bg))
    return x0 + w

def header(c, lg, title):
    x = chip(c, lg, LEAGUE[lg], PAD)
    c.text(title, x + 3, 1, font = "4x5", color = INK)

def message(c, head, sub, head_color):
    # Sits in the band under the chip row, so a failed page still says
    # which page it is.
    w = c.width - 2 * PAD
    c.text(clip(c, head, "5x7", w), c.width // 2, 12, font = "5x7", color = head_color, align = "center")
    c.text(clip(c, sub, "4x5", w), c.width // 2, 23, font = "4x5", color = DIM, align = "center")

def offline(c):
    message(c, "STANDINGS OFFLINE", "TRYING AGAIN SOON", AMBER)

def not_yet(c):
    # Before opening day there's simply no field to show - not an error.
    message(c, "NO STANDINGS YET", "BACK ON OPENING DAY", INK)

def tile(c, x, y, h, team_id, label):
    fill = team_color(team_id)
    # Navy (NYY, MIL) and near-black (CWS) tiles vanish into the ground, so
    # the darkest colors get a rim in a lighter tint of themselves.
    edge = lighten(fill, 45) if brightness(fill) < 64 else fill
    c.round_rect(x, y, x + TILE_W - 1, y + h - 1, 1, fill = fill, outline = edge)
    if label != "":
        c.text(label, x + TILE_W // 2, y + (h - 7) // 2, font = "5x7", color = ink_on(fill), align = "center")

def team_cell(c, x, y, seed, t, text, font):
    tile(c, x, y, TILE_H, team_id_of(t), str(seed))
    c.text(clip(c, text, font, NAME_W), x + TILE_W + NAME_GAP, y + 1, font = font, color = INK)

def at_sign(c, y):
    c.text("@", MID, y + 1, font = "5x7", color = DIM, align = "center")

# ---------- pages ----------

def intro(c, ctx):
    c.clear()
    hero = "PLAYOFFS"
    hw = c.text_width(hero, "10x16")
    lockup = BALL_W + 6 + hw
    x0 = max(PAD, (c.width - lockup) // 2)
    hx = x0 + BALL_W + 6
    c.sprite(BALL, x0, 8, legend = BALL_LEGEND)
    c.text("MLB " + str(ctx.now.year), hx, 1, font = "4x5", color = DIM)
    c.text(hero, hx, 8, font = "10x16", color = INK)
    c.text("IF SEASON ENDED TODAY", c.width // 2, 26, font = "4x5", color = DIM, align = "center")

def byes(c, ctx):
    c.clear()
    chip(c, "AL", LEAGUE["AL"], PAD)
    chip(c, "NL", LEAGUE["NL"], c.width - PAD, right = True)
    c.text("FIRST-ROUND BYES", c.width // 2, 1, font = "4x5", color = INK, align = "center")

    data = load_seeds(ctx)
    if data == None:
        return offline(c)
    if len(data["AL"]) < 2 or len(data["NL"]) < 2:
        return not_yet(c)

    teams = team_info()
    al_names = [nickname(data["AL"][i], teams) for i in range(2)]
    nl_names = [nickname(data["NL"][i], teams) for i in range(2)]
    font = page_font(c, al_names + nl_names, NAME_W)
    for i in range(2):
        team_cell(c, LEFT_TILE, ROW_Y[i], i + 1, data["AL"][i], al_names[i], font)
        team_cell(c, RIGHT_TILE, ROW_Y[i], i + 1, data["NL"][i], nl_names[i], font)
    c.vline(MID, ROW_Y[0], 21, STRUCT)

def wc_page(c, ctx, lg):
    c.clear()
    header(c, lg, "WILD CARD SERIES")

    data = load_seeds(ctx)
    if data == None:
        return offline(c)
    seeds = data[lg]
    if len(seeds) < 6:
        return not_yet(c)

    teams = team_info()
    # [visitor seed, host seed] - #3 hosts #6, #4 hosts #5
    pairs = [[6, 3], [5, 4]]
    names = []
    for p in pairs:
        names.append(nickname(seeds[p[0] - 1], teams))
        names.append(nickname(seeds[p[1] - 1], teams))
    font = page_font(c, names, NAME_W)
    for i in range(2):
        y = ROW_Y[i]
        team_cell(c, LEFT_TILE, y, pairs[i][0], seeds[pairs[i][0] - 1], names[i * 2], font)
        at_sign(c, y)
        team_cell(c, RIGHT_TILE, y, pairs[i][1], seeds[pairs[i][1] - 1], names[i * 2 + 1], font)

def ds_page(c, ctx, lg):
    c.clear()
    header(c, lg, "DIVISION SERIES")

    data = load_seeds(ctx)
    if data == None:
        return offline(c)
    seeds = data[lg]
    if len(seeds) < 6:
        return not_yet(c)

    teams = team_info()
    # One column per series, on the byes page's grid. The waiting seed is the
    # top row; the wild card pair it will host sits under it as "VS NYY/BOS".
    # A single row ("4 NYY 5 BOS @ 1 RAYS") needed four cells 2px apart and
    # read as one run-on string.
    cols = [[1, [4, 5]], [2, [3, 6]]]   # #1 hosts the 4/5 winner, #2 the 3/6
    hosts = [nickname(seeds[col[0] - 1], teams) for col in cols]
    font = page_font(c, hosts, NAME_W)
    pairs = [[abbrev(seeds[s - 1], teams) for s in col[1]] for col in cols]
    # "WSH/NYM" is the worst pair: 41px at 5x7, inside the 43px name column.
    pair_font = page_font(c, [p[0] + "/" + p[1] for p in pairs], NAME_W)
    slash_w = c.text_width("/", pair_font)

    y = ROW_Y[1]
    for i in range(2):
        tx = LEFT_TILE if i == 0 else RIGHT_TILE
        nx = tx + TILE_W + NAME_GAP
        h = cols[i][0]
        team_cell(c, tx, ROW_Y[0], h, seeds[h - 1], hosts[i], font)
        # "VS" sits under the tile, baseline-aligned with the codes
        c.text("VS", tx + TILE_W // 2, y + 2, font = "4x5", color = DIM, align = "center")
        x = nx
        for j in range(2):
            if j == 1:
                c.text("/", x, y, font = pair_font, color = DIM)
                x += slash_w + 1
            code = clip(c, pairs[i][j], pair_font, 17)
            w = c.text_width(code, pair_font)
            c.text(code, x, y, font = pair_font, color = INK)
            # the team's color as a 2px bar under its code, 1px clear of it
            bar = team_color(team_id_of(seeds[cols[i][1][j] - 1]))
            if brightness(bar) < 64:
                bar = lighten(bar, 45)
            c.rect(x, y + 8, x + w - 1, y + 9, fill = bar)
            x += w + 1
    c.vline(MID, ROW_Y[0], 21, STRUCT)

def al(c, ctx):
    wc_page(c, ctx, "AL")

def nl(c, ctx):
    wc_page(c, ctx, "NL")

def alds(c, ctx):
    ds_page(c, ctx, "AL")

def nlds(c, ctx):
    ds_page(c, ctx, "NL")

# ---------- on the bubble ----------
# The 3 teams just missing the field: ranks 4-6 in the wildCard standingsType
# block (ranks 1-3 there are the wild card holders, i.e. seeds 4-6 overall).

BUBBLE_Y = [9, 17, 25]  # 7px rows, 1px apart - three won't fit at tile height

def wildcard_bubble3(wc_records, league_id):
    for block in wc_records:
        if block.get("league", {}).get("id") == league_id:
            return block.get("teamRecords", [])[3:6]
    return []

def bubble_gb(t):
    # [value, value color, label]. Every team on this page is already outside
    # the field, so no GB means level with the last spot but behind on the
    # tiebreaker - amber, and said outright, since "TIED" alone left it
    # unclear why that team isn't holding the spot.
    gb = t.get("wildCardGamesBack", "-")
    if gb in ("-", "", None):
        # "LOSE TB" (31px) not "LOSES TB" (36px): the extra 5px would push a
        # 43px name like GUARDIANS into a clip.
        return ["TIED", AMBER, "LOSE TB"]
    return [str(gb), INK, "GB"]

def bubble_page(c, ctx, lg):
    c.clear()
    header(c, lg, "ON THE BUBBLE")

    wc = standings(ctx, "wildCard")
    if wc == None:
        return offline(c)
    bubble = wildcard_bubble3(wc, LEAGUE_ID[lg])
    if len(bubble) < 3:
        return not_yet(c)

    teams = team_info()
    right = c.width - PAD
    names = []
    gbs = []
    room = NAME_W * 2
    for t in bubble:
        g = bubble_gb(t)
        gbs.append(g)
        names.append(nickname(t, teams))
        # right side measured first; the name gets what's left, 4px clear
        vw = c.text_width(g[0], "5x7") + 2 + c.text_width(g[2], "4x5")
        room = min(room, right - vw - 4 - LEFT_NAME + 1)
    font = page_font(c, names, room)

    for i in range(3):
        y = BUBBLE_Y[i]
        g = gbs[i]
        tile(c, LEFT_TILE, y, 7, team_id_of(bubble[i]), "")
        c.text(clip(c, names[i], font, room), LEFT_NAME, y, font = font, color = INK)
        c.text(g[2], right, y + 2, font = "4x5", color = DIM, align = "right")
        c.text(g[0], right - c.text_width(g[2], "4x5") - 2, y, font = "5x7", color = g[1], align = "right")

def albubble(c, ctx):
    bubble_page(c, ctx, "AL")

def nlbubble(c, ctx):
    bubble_page(c, ctx, "NL")
