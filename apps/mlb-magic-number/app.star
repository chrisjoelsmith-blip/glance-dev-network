# DESIGN. The user's 128x32 strip: team-colored "{NICK} MAGIC NUMBER"
# across the top, the club mark on the left of the 20px band, and one
# giant number centered — the Braves example, for every MLB club.
# Title steps 6x8 -> 5x7 -> 4x5 so WASHINGTON-class names never collide
# with the 128px edge. The number is the magic number when the club can
# still clinch; otherwise it is the elimination number, labelled as such.
#
# NUMBERS. We do not copy MLB's precomputed magicNumber / elimination
# fields — those sometimes drop 1 when a tiebreaker is already in hand,
# so they disagree with the published "tragic number" (CBS, Google):
# any mix of leader wins and trailer losses totaling N.
#     N = 162 + 1 - W_leader - L_trailer
# Worked example, after the 2026-09-12 finals:
#   Guardians 75-74 hold AL WC3. Orioles 72-77 are chasing.
#   N = 163 - 75 - 77 = 11.
# Friday 9/11 (BAL 72-76, CLE 75-73) was 12 — that's the figure Google
# cached. One Orioles loss drops it by 1; a Guardians win does too.

# mlb_id, short nick for the title, LED-readable title color, crest file.
TEAMS = {
    "ARI": [109, "D-BACKS", "#A71930", "ari.png"],
    "ATH": [133, "ATHLETICS", "#EFB21E", "ath.png"],
    "ATL": [144, "BRAVES", "#CE1141", "atl.png"],
    "BAL": [110, "ORIOLES", "#DF4601", "bal.png"],
    "BOS": [111, "RED SOX", "#BD3039", "bos.png"],
    "CHC": [112, "CUBS", "#4A90E2", "chc.png"],
    "CHW": [145, "WHITE SOX", "#C4CED4", "chw.png"],
    "CIN": [113, "REDS", "#C6011F", "cin.png"],
    "CLE": [114, "GUARDIANS", "#E31937", "cle.png"],
    "COL": [115, "ROCKIES", "#C4CED4", "col.png"],
    "DET": [116, "TIGERS", "#FA4616", "det.png"],
    "HOU": [117, "ASTROS", "#EB6E1F", "hou.png"],
    "KC": [118, "ROYALS", "#5B9BD5", "kc.png"],
    "LAA": [108, "ANGELS", "#BA0021", "laa.png"],
    "LAD": [119, "DODGERS", "#3D9BE9", "lad.png"],
    "MIA": [146, "MARLINS", "#00A3E0", "mia.png"],
    "MIL": [158, "BREWERS", "#FFC52F", "mil.png"],
    "MIN": [142, "TWINS", "#D31145", "min.png"],
    "NYM": [121, "METS", "#FF5910", "nym.png"],
    "NYY": [147, "YANKEES", "#C4CED4", "nyy.png"],
    "PHI": [143, "PHILLIES", "#E81828", "phi.png"],
    "PIT": [134, "PIRATES", "#FDB827", "pit.png"],
    "SD": [135, "PADRES", "#FFC425", "sd.png"],
    "SF": [137, "GIANTS", "#FD5A1E", "sf.png"],
    "SEA": [136, "MARINERS", "#1C9B9B", "sea.png"],
    "STL": [138, "CARDINALS", "#C41E3A", "stl.png"],
    "TB": [139, "RAYS", "#8FBCE6", "tb.png"],
    "TEX": [140, "RANGERS", "#C0111F", "tex.png"],
    "TOR": [141, "BLUE JAYS", "#3E7FDB", "tor.png"],
    "WSH": [120, "NATIONALS", "#E4002B", "wsh.png"],
}

# Dropdown labels (and a few short aliases) -> TEAMS key.
NAME_TO_ABBR = {
    "ARIZONA DIAMONDBACKS": "ARI",
    "ATHLETICS": "ATH",
    "ATLANTA BRAVES": "ATL",
    "BALTIMORE ORIOLES": "BAL",
    "BOSTON RED SOX": "BOS",
    "CHICAGO CUBS": "CHC",
    "CHICAGO WHITE SOX": "CHW",
    "CINCINNATI REDS": "CIN",
    "CLEVELAND GUARDIANS": "CLE",
    "COLORADO ROCKIES": "COL",
    "DETROIT TIGERS": "DET",
    "HOUSTON ASTROS": "HOU",
    "KANSAS CITY ROYALS": "KC",
    "LOS ANGELES ANGELS": "LAA",
    "LOS ANGELES DODGERS": "LAD",
    "MIAMI MARLINS": "MIA",
    "MILWAUKEE BREWERS": "MIL",
    "MINNESOTA TWINS": "MIN",
    "NEW YORK METS": "NYM",
    "NEW YORK YANKEES": "NYY",
    "PHILADELPHIA PHILLIES": "PHI",
    "PITTSBURGH PIRATES": "PIT",
    "SAN DIEGO PADRES": "SD",
    "SAN FRANCISCO GIANTS": "SF",
    "SEATTLE MARINERS": "SEA",
    "ST. LOUIS CARDINALS": "STL",
    "TAMPA BAY RAYS": "TB",
    "TEXAS RANGERS": "TEX",
    "TORONTO BLUE JAYS": "TOR",
    "WASHINGTON NATIONALS": "WSH",
}

SEASON_GAMES = 162
NODATA_FONTS = ["10x16", "6x8", "5x7", "4x5"]
TITLE_FONTS = ["6x8", "5x7", "4x5"]
HERO_FONTS = ["16x20", "10x16", "7x12"]
FONTH = {"16x20": 20, "10x16": 16, "7x12": 12, "6x8": 8, "5x7": 7, "4x5": 5}


def resolve_team(raw):
    s = str(raw).strip().upper()
    if s == "":
        return "ATL"
    if s in TEAMS:
        return s
    if s in NAME_TO_ABBR:
        return NAME_TO_ABBR[s]
    return None


def _fit_clip(c, text, fonts, maxw):
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(text, f) <= maxw:
            pick = f
            break
    t = text
    if c.text_width(t, pick) > maxw:
        for k in range(len(t), 0, -1):
            if c.text_width(t[:k], pick) <= maxw:
                t = t[:k]
                break
    return [pick, t]


def nodata(c, title, sub):
    c.fill("#0B0C12")
    maxw = c.width - 6
    t = _fit_clip(c, title.upper(), NODATA_FONTS, maxw)
    c.text(t[1], c.width // 2, 4, font = t[0], color = "#E8B04A", align = "center")
    d = _fit_clip(c, sub.upper(), ["5x7", "4x5"], maxw)
    c.text(d[1], c.width // 2, 22, font = d[0], color = "#6A7090", align = "center")


def season_year(ctx):
    y = ctx.now.year
    if ctx.now.month < 3:
        y = y - 1
    return y


def fetch_standings(year):
    # ttl tracks refresh: 5 min so a Final updates the combo number tonight,
    # not on a 30-minute lag that can disagree with a same-day recap.
    resp = http.get(
        "https://statsapi.mlb.com/api/v1/standings",
        params = {
            "leagueId": "103,104",
            "season": str(year),
            "standingsTypes": "regularSeason",
        },
        ttl_seconds = 300,
    )
    if resp["status_code"] != 200 or resp["json"] == None:
        return None
    records = resp["json"].get("records", [])
    if records == None or len(records) == 0:
        return None
    return records


def flatten(records):
    # [team_record, league_id, division_id] — JSON dicts from http.get
    # are not something we mutate, so ids ride beside the row.
    out = []
    for block in records:
        lg = block.get("league", {})
        div = block.get("division", {})
        lid = lg.get("id", 0)
        did = div.get("id", 0)
        for t in block.get("teamRecords", []):
            out.append([t, lid, did])
    return out


def find_team(rows, mlb_id):
    for pair in rows:
        t = pair[0]
        tid = t.get("team", {}).get("id")
        if tid == mlb_id or str(tid) == str(mlb_id):
            return pair
    return None


def wl(row):
    rec = row.get("leagueRecord", {}) or {}
    return [int(rec.get("wins", 0) or 0), int(rec.get("losses", 0) or 0)]


def combo_number(w_leader, l_trailer):
    """Wins by the leader + losses by the trailer that finish the race.

    Same definition CBS/Google print as the magic / tragic number.
    """
    n = SEASON_GAMES + 1 - int(w_leader) - int(l_trailer)
    if n < 0:
        return 0
    return n


def by_wc_rank(rows, league_id, rank):
    want = str(rank)
    for pair in rows:
        if pair[1] != league_id:
            continue
        if str(pair[0].get("wildCardRank") or "") == want:
            return pair[0]
    return None


def by_div_rank(rows, league_id, division_id, rank):
    want = str(rank)
    for pair in rows:
        if pair[1] != league_id or pair[2] != division_id:
            continue
        if str(pair[0].get("divisionRank") or "") == want:
            return pair[0]
    return None


def board_for(pair, rows):
    """Return [hero_str, kind] or None.

    kind is MAGIC (club can still clinch) or ELIM (still alive, chasing).
    None means the race is over for this club.
    """
    row = pair[0]
    league_id = pair[1]
    division_id = pair[2]
    our = wl(row)
    div_rank = str(row.get("divisionRank") or "")
    wc_rank = str(row.get("wildCardRank") or "")
    wc_elim = str(row.get("wildCardEliminationNumber") or "")

    if row.get("clinched"):
        return ["0", "MAGIC"]

    # Division leader: magic number vs 2nd place in the same division.
    if div_rank == "1":
        second = by_div_rank(rows, league_id, division_id, 2)
        if second != None:
            n = combo_number(our[0], wl(second)[1])
            return [str(n), "MAGIC"]

    # Holding a wild-card slot: magic number vs the first team out (WC4).
    if wc_rank in ["1", "2", "3"]:
        first_out = by_wc_rank(rows, league_id, 4)
        if first_out != None:
            n = combo_number(our[0], wl(first_out)[1])
            return [str(n), "MAGIC"]

    # Chasing: tragic number vs the last team in (WC3) — Orioles vs Guardians.
    if wc_elim == "E":
        return None
    last_in = by_wc_rank(rows, league_id, 3)
    if last_in == None:
        return None
    n = combo_number(wl(last_in)[0], our[1])
    if n == 0:
        return None
    return [str(n), "ELIM"]


def draw_live(c, info, hero, kind):
    c.fill("black")
    nick = info[1]
    if kind == "ELIM":
        title = (nick + " ELIM NUMBER").upper()
    else:
        title = (nick + " MAGIC NUMBER").upper()

    # 1px side pad — 'BRAVES MAGIC NUMBER' is 126px at 6x8, the design point.
    fitted = _fit_clip(c, title, TITLE_FONTS, c.width - 2)
    font = fitted[0]
    y = 2
    if font == "4x5":
        y = 3
    c.text(fitted[1], c.width // 2, y, font = font, color = info[2], align = "center")

    c.image(info[3], 9, 11)

    color = "white"
    if kind == "ELIM":
        color = "amber"
    elif kind == "OUT" or hero == "0":
        color = "#3DDC84"
    elif kind == "OFF":
        color = "#6A7090"

    # Logo occupies x 9 plus up to 30px (the Braves mark). Keep a 2px
    # buffer so a two-digit 16x20 ('12' is 33px) never draws through it.
    logo_right = 9 + 30 + 2
    hf = _fit_clip(c, hero, HERO_FONTS, c.width - logo_right - 4)
    hfont = hf[0]
    label = hf[1]
    nw = c.text_width(label, hfont)
    nx = (c.width - nw) // 2
    if nx < logo_right:
        nx = logo_right
    hh = FONTH.get(hfont, 20)
    ny = 11 + (20 - hh) // 2
    c.text(label, nx, ny, font = hfont, color = color)


def main(c, ctx):
    abbr = resolve_team(ctx.inputs.get("team", "Atlanta Braves"))
    if abbr == None:
        nodata(c, "UNKNOWN TEAM", "PICK A CLUB")
        return

    info = TEAMS[abbr]
    year = season_year(ctx)
    records = fetch_standings(year)
    if records == None:
        records = fetch_standings(year - 1)
    if records == None:
        nodata(c, "NO STANDINGS", "TRY AGAIN LATER")
        return

    rows = flatten(records)
    if len(rows) == 0:
        draw_live(c, info, "--", "OFF")
        return

    row = find_team(rows, info[0])
    if row == None:
        draw_live(c, info, "--", "OFF")
        return

    board = board_for(row, rows)
    if board == None:
        # Still the club's panel — logo + title stay, hero reads OUT.
        draw_live(c, info, "OUT", "OUT")
        return

    draw_live(c, info, board[0], board[1])
