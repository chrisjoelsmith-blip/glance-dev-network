# Arsenal FC — a GDN Starlark app (192x32 SCROLL, 4 pages).
#
# DESIGN. Arsenal colors only — red, white, black, and shades of them (no
# green, no amber/gold): loss is bold red, win/draw/home/live are white or
# a lighter red tint, never a different hue. This is the scroll build's own
# layout, not the 64px classic build stretched wide — the extra room buys a
# real logo badge and a label next to every value, not just a bigger
# number. A 52px badge zone (wearing the page's state color) runs the full
# left edge carrying the real Arsenal cannon mark at 48x22. The remaining
# content band sits inside the safe zone (x 58-184, well clear of
# the 6-10px edges neighbor apps play up against) and splits into a
# tag/meta row plus two zones separated by a hairline: a hero on the left,
# supporting detail on the right — so nothing has to share a line with
# something else. Four pages rotate: LIVE, NEXT, RESULT, TABLE — same
# rotation and same data layer as the classic build.
#
# LOGO. assets/cannon.png is Arsenal's own 1921-22 club crest — a real,
# public-domain historical mark (see README.md for provenance and why the
# modern shield crest doesn't work at this resolution), thresholded to
# pure black/white at 48x22px — roughly the minimum width where the wheel
# spokes and barrel stay legible; the 64px classic build only has room for
# a rougher ~20px rendition of the same source.
#
# DATA. TheSportsDB (team id 133604, league id 4328), shared free "3" test
# key — no signup, no api-key input. Same three trade-offs as the classic
# build: the free table lookup only returns the top 5 rows; kickoff time is
# the fixture's own local time, not the viewer's; and LIVE scans the whole
# cross-sport livescore feed for Arsenal's team id. Refresh 300s.

RED = "#EF0107"
RED_LIGHT = "#FF6B61"  # attention/live/draw — a lighter tint of brand red
WHITE = "white"
GRAY = "gray"
DIVIDER = "#3A3A3A"
NODATA_BG = "#0B0C12"
NODATA_TITLE = "#E8B04A"
NODATA_SUB = "#6A7090"

TEAM_ID = "133604"
LEAGUE_ID = "4328"

GUTTER_W = 52
CONTENT_X0 = 58
CONTENT_X1 = 184
ZONE_SPLIT = 134  # vline between hero zone and detail zone
CANNON_W = 48
CANNON_H = 22

HERO_FONTS = ["16x20", "10x16", "6x8", "5x7"]

MONTHS = {
    "01": "JAN", "02": "FEB", "03": "MAR", "04": "APR",
    "05": "MAY", "06": "JUN", "07": "JUL", "08": "AUG",
    "09": "SEP", "10": "OCT", "11": "NOV", "12": "DEC",
}

COMP_SHORT = {
    "ENGLISH PREMIER LEAGUE": "PREMIER LEAGUE",
    "UEFA CHAMPIONS LEAGUE": "CHAMPIONS LEAGUE",
    "UEFA EUROPA LEAGUE": "EUROPA LEAGUE",
    "UEFA EUROPA CONFERENCE LEAGUE": "CONFERENCE LGE",
    "FA CUP": "FA CUP",
    "EFL CUP": "EFL CUP",
    "FA COMMUNITY SHIELD": "COMMUNITY SHIELD",
    "EMIRATES CUP": "FRIENDLY",
    "CLUB FRIENDLIES": "FRIENDLY",
}

# The hero zone (~92px) is narrower than the full panel, so even here the
# longest club names need shortening — same map as the classic build.
# Unmapped names still fall through fit_clip's hard-clip, so nothing can
# overflow, but every current Premier League club is covered.
CLUB_SHORT = {
    "MANCHESTER UNITED": "MAN UTD",
    "MANCHESTER CITY": "MAN CITY",
    "TOTTENHAM HOTSPUR": "SPURS",
    "WEST HAM UNITED": "WEST HAM",
    "BRIGHTON AND HOVE ALBION": "BRIGHTON",
    "WOLVERHAMPTON WANDERERS": "WOLVES",
    "NOTTINGHAM FOREST": "FOREST",
    "CRYSTAL PALACE": "PALACE",
    "LEICESTER CITY": "LEICESTER",
    "SHEFFIELD UNITED": "SHEFF UTD",
    "WEST BROMWICH ALBION": "WEST BROM",
    "IPSWICH TOWN": "IPSWICH",
    "LEEDS UNITED": "LEEDS",
    "NEWCASTLE UNITED": "NEWCASTLE",
    "AFC BOURNEMOUTH": "BOURNEMOUTH",
}

def fit_clip(c, text, fonts, maxw):
    """Pick the largest font in `fonts` that fits maxw; hard-clip if none do."""
    for f in fonts:
        if c.text_width(text, font = f) <= maxw:
            return text, f
    f = fonts[-1]
    for i in range(len(text) - 1):
        if c.text_width(text, font = f) <= maxw:
            break
        text = text[:-1]
    return text, f

def short_club(name):
    up = name.upper()
    return CLUB_SHORT.get(up, up)

def short_comp(name):
    up = name.upper()
    return COMP_SHORT.get(up, up)

def fmt_date(date_iso):
    # "2026-09-15" -> "SEP 15"
    month = MONTHS.get(date_iso[5:7], "???")
    day = date_iso[8:10]
    if day[0] == "0":
        day = day[1:]
    return month + " " + day

def fmt_time12(hhmmss):
    # "20:00:00" -> "8:00PM"
    h = int(hhmmss[0:2])
    m = hhmmss[3:5]
    ap = "AM" if h < 12 else "PM"
    h12 = h % 12
    if h12 == 0:
        h12 = 12
    return "%d:%s%s" % (h12, m, ap)

def season_str(now):
    # EPL season spans Aug-May; treat Jul+ as the start of the new season.
    y = now.year
    if now.month >= 7:
        return "%d-%d" % (y, y + 1)
    return "%d-%d" % (y - 1, y)

def gutter(c, accent):
    """The rail: a full-height accent badge zone carrying the cannon mark."""
    c.rect(0, 0, GUTTER_W - 1, c.height - 1, fill = accent)
    x = (GUTTER_W - CANNON_W) // 2
    y = (c.height - CANNON_H) // 2
    c.image("cannon.png", x, y)

def tag_meta(c, tag, meta, meta_color):
    """Top row inside the content band: page tag (left), context (right)."""
    c.text(tag, CONTENT_X0, 1, font = "4x5", color = GRAY)
    m, mf = fit_clip(c, meta, ["4x5"], CONTENT_X1 - CONTENT_X0 - 40)
    c.text(m, CONTENT_X1, 1, font = mf, color = meta_color, align = "right")

def zone_divider(c):
    c.vline(ZONE_SPLIT, 8, c.height - 9, DIVIDER)

def state_card(c, title, sub, title_color, sub_color, bg, accent):
    """Full-width fallback card: what happened, what it means (or to do).

    The panel is 32px tall no matter how wide it is, so this borrows the
    classic build's proven two-line font sizes (6x8 / 4x5) rather than the
    scroll build's bigger hero ladder — a taller title here would collide
    with the sub line exactly like it did on the 64px build."""
    c.fill(bg)
    gutter(c, accent)
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 8
    t, tf = fit_clip(c, title, ["6x8", "5x7", "4x5"], maxw)
    c.text(t, cx, 10, font = tf, color = title_color, align = "center")
    s, sf = fit_clip(c, sub, ["4x5"], maxw)
    c.text(s, cx, 20, font = sf, color = sub_color, align = "center")

def nodata(c, title, sub):
    state_card(c, title, sub, NODATA_TITLE, NODATA_SUB, NODATA_BG, RED)

def empty_state(c, title, sub):
    state_card(c, title, sub, WHITE, GRAY, "black", RED)

def fetch_next_fixture():
    resp = http.get(
        "https://www.thesportsdb.com/api/v1/json/3/eventsnext.php",
        params = {"id": TEAM_ID},
        ttl_seconds = 1800,
    )
    if resp["status_code"] != 200:
        return None, "offline"
    events = resp["json"].get("events")
    if not events:
        return None, "empty"
    e = events[0]
    home = e.get("idHomeTeam") == TEAM_ID
    opponent = e.get("strAwayTeam") if home else e.get("strHomeTeam")
    return {
        "opponent": short_club(opponent or "TBD"),
        "home": home,
        "comp": short_comp(e.get("strLeague") or ""),
        "date": fmt_date(e.get("dateEvent") or "0000-01-01"),
        "time": fmt_time12(e.get("strTimeLocal") or e.get("strTime") or "00:00:00"),
    }, "ok"

def fetch_last_result():
    resp = http.get(
        "https://www.thesportsdb.com/api/v1/json/3/eventslast.php",
        params = {"id": TEAM_ID},
        ttl_seconds = 1800,
    )
    if resp["status_code"] != 200:
        return None, "offline"
    results = resp["json"].get("results")
    if not results:
        return None, "empty"
    r = results[0]
    home = r.get("idHomeTeam") == TEAM_ID
    opponent = r.get("strAwayTeam") if home else r.get("strHomeTeam")
    home_score = int(r.get("intHomeScore") or 0)
    away_score = int(r.get("intAwayScore") or 0)
    return {
        "opponent": short_club(opponent or "TBD"),
        "score_for": home_score if home else away_score,
        "score_against": away_score if home else home_score,
        "comp": short_comp(r.get("strLeague") or ""),
        "date": fmt_date(r.get("dateEvent") or "0000-01-01"),
    }, "ok"

def fetch_table_row(now):
    resp = http.get(
        "https://www.thesportsdb.com/api/v1/json/3/lookuptable.php",
        params = {"l": LEAGUE_ID, "s": season_str(now)},
        ttl_seconds = 3600,
    )
    if resp["status_code"] != 200:
        return None, "offline"
    rows = resp["json"].get("table")
    if not rows:
        return None, "empty"
    for row in rows:
        if row.get("idTeam") == TEAM_ID:
            return {
                "rank": int(row.get("intRank") or 0),
                "points": int(row.get("intPoints") or 0),
                "played": int(row.get("intPlayed") or 0),
                "form": (row.get("strForm") or "").upper(),
            }, "ok"
    # The shared free API key only returns the table's top 5 rows.
    return None, "outside_top5"

NOT_LIVE_STATUS = {"NS": True, "FT": True, "POSTPONED": True, "PPD": True,
                    "CANC": True, "ABD": True, "TBD": True, "": True}

def fetch_live_match():
    resp = http.get(
        "https://www.thesportsdb.com/api/v1/json/3/livescore.php",
        params = {"s": "Soccer"},
        ttl_seconds = 300,
    )
    if resp["status_code"] != 200:
        return None, "offline"
    rows = resp["json"].get("livescore")
    if not rows:
        return None, "not_live"
    for row in rows:
        if row.get("idHomeTeam") != TEAM_ID and row.get("idAwayTeam") != TEAM_ID:
            continue
        status = (row.get("strStatus") or "").upper()
        if NOT_LIVE_STATUS.get(status):
            continue
        home = row.get("idHomeTeam") == TEAM_ID
        opponent = row.get("strAwayTeam") if home else row.get("strHomeTeam")
        home_score = int(row.get("intHomeScore") or 0)
        away_score = int(row.get("intAwayScore") or 0)
        progress = row.get("strProgress") or status
        minute = progress if status == "HT" else progress + "'"
        return {
            "opponent": short_club(opponent or "TBD"),
            "home": home,
            "score_for": home_score if home else away_score,
            "score_against": away_score if home else home_score,
            "minute": minute,
        }, "ok"
    return None, "not_live"

def live(c, ctx):
    m, state = fetch_live_match()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "not_live":
        fx, fx_state = fetch_next_fixture()
        gutter(c, RED)
        tag_meta(c, "LIVE", "", GRAY)
        cx = (CONTENT_X0 + CONTENT_X1) // 2
        c.text("NOT LIVE", cx, 10, font = "6x8", color = GRAY, align = "center")
        if fx_state == "ok":
            sub = "NEXT: " + fx["opponent"] + " " + fx["date"]
        else:
            sub = "CHECK NEXT PAGE"
        sub, sf = fit_clip(c, sub, ["5x7", "4x5"], CONTENT_X1 - CONTENT_X0 - 8)
        c.text(sub, cx, 21, font = sf, color = RED_LIGHT, align = "center")
        return

    # In play: amber gutter (attention), score in white since it isn't
    # decided yet, minute + opponent as the supporting detail zone.
    gutter(c, RED_LIGHT)
    tag_meta(c, "LIVE", m["minute"], RED_LIGHT)
    zone_divider(c)

    score = "%d-%d" % (m["score_for"], m["score_against"])
    score, sf = fit_clip(c, score, HERO_FONTS, ZONE_SPLIT - CONTENT_X0 - 6)
    c.text(score, CONTENT_X0 + (ZONE_SPLIT - CONTENT_X0) // 2, 8,
           font = sf, color = WHITE, align = "center")

    zx = ZONE_SPLIT + (CONTENT_X1 - ZONE_SPLIT) // 2
    name, nf = fit_clip(c, m["opponent"], ["6x8", "5x7", "4x5"], CONTENT_X1 - ZONE_SPLIT - 8)
    c.text(name, zx, 12, font = nf, color = WHITE, align = "center")
    ha = "HOME" if m["home"] else "AWAY"
    c.text(ha, zx, 22, font = "4x5", color = GRAY, align = "center")

def next(c, ctx):
    fx, state = fetch_next_fixture()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "empty":
        empty_state(c, "NO FIXTURE", "TRY LATER")
        return

    gutter(c, RED)
    tag_meta(c, "NEXT", fx["comp"], GRAY)
    zone_divider(c)

    name, nf = fit_clip(c, fx["opponent"], HERO_FONTS, ZONE_SPLIT - CONTENT_X0 - 6)
    c.text(name, CONTENT_X0 + (ZONE_SPLIT - CONTENT_X0) // 2, 8,
           font = nf, color = WHITE, align = "center")

    zx = ZONE_SPLIT + (CONTENT_X1 - ZONE_SPLIT) // 2
    ha_color = WHITE if fx["home"] else GRAY
    ha_label = "HOME" if fx["home"] else "AWAY"
    c.text(ha_label, zx, 10, font = "4x5", color = ha_color, align = "center")
    c.text(fx["date"], zx, 17, font = "4x5", color = WHITE, align = "center")
    c.text(fx["time"], zx, 24, font = "4x5", color = RED_LIGHT, align = "center")

def result(c, ctx):
    r, state = fetch_last_result()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "empty":
        empty_state(c, "NO RESULT", "NOT STARTED")
        return

    won = r["score_for"] > r["score_against"]
    drew = r["score_for"] == r["score_against"]
    accent = WHITE if won else (RED_LIGHT if drew else RED)
    outcome = "DRAW" if drew else ("WIN" if won else "LOSS")

    gutter(c, accent)
    tag_meta(c, "RESULT", r["comp"], GRAY)
    zone_divider(c)

    score = "%d-%d" % (r["score_for"], r["score_against"])
    score, sf = fit_clip(c, score, HERO_FONTS, ZONE_SPLIT - CONTENT_X0 - 6)
    c.text(score, CONTENT_X0 + (ZONE_SPLIT - CONTENT_X0) // 2, 8,
           font = sf, color = accent, align = "center")

    zx = ZONE_SPLIT + (CONTENT_X1 - ZONE_SPLIT) // 2
    name, nf = fit_clip(c, r["opponent"], ["6x8", "5x7", "4x5"], CONTENT_X1 - ZONE_SPLIT - 8)
    c.text(name, zx, 10, font = nf, color = WHITE, align = "center")
    c.text(outcome, zx, 20, font = "4x5", color = accent, align = "center")
    c.text(r["date"], zx, 26, font = "4x5", color = GRAY, align = "center")

FORM_COLOR = {"W": WHITE, "D": RED_LIGHT, "L": RED}

def table(c, ctx):
    row, state = fetch_table_row(ctx.now)
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "empty" or state == "outside_top5":
        # Not "empty" (that's a happy zero) and not a network error either —
        # the free lookup only covers the top 5 rows.
        nodata(c, "NOT RANKED", "TOP 5 ONLY")
        return

    gutter(c, RED)
    tag_meta(c, "TABLE", "%d PLAYED" % row["played"], GRAY)
    zone_divider(c)

    rank = "#%d" % row["rank"]
    rank, rf = fit_clip(c, rank, HERO_FONTS, ZONE_SPLIT - CONTENT_X0 - 6)
    c.text(rank, CONTENT_X0 + (ZONE_SPLIT - CONTENT_X0) // 2, 8,
           font = rf, color = WHITE, align = "center")

    zx = ZONE_SPLIT + (CONTENT_X1 - ZONE_SPLIT) // 2
    c.text("%d PTS" % row["points"], zx, 11, font = "5x7", color = WHITE, align = "center")

    # Form as small colored squares, most recent match on the right.
    form = row["form"]
    n = len(form)
    if n > 0:
        sq = 5
        gap = 2
        total_w = n * sq + (n - 1) * gap
        x0 = zx - total_w // 2
        for i in range(n):
            x = x0 + i * (sq + gap)
            col = FORM_COLOR.get(form[i], GRAY)
            c.rect(x, 22, x + sq - 1, 22 + sq - 1, fill = col)
