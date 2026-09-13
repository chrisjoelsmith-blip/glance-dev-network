# Arsenal FC — a GDN Starlark app (64x32, 4 pages).
#
# DESIGN. Arsenal colors only — red, white, black, and shades of them (no
# green, no amber/gold): loss is bold red, win/draw/home/live are white or
# a lighter red tint, never a different hue. A left-edge gutter (24px,
# wearing the page's state color) carries the real Arsenal cannon mark, so
# the app identifies itself with no top header band eating into the
# panel's 32 rows. The content zone
# (x 27-62) stacks a small page tag, one hero value, and one or two detail
# lines beneath it — single column, since 35px doesn't leave room for the
# side-by-side zones the 192px scroll build uses. Four pages rotate: LIVE
# (score + minute while a match is on, else a compact "not live" card),
# NEXT (upcoming fixture), RESULT (last final score), TABLE (current
# Premier League position). No inputs: this app is Arsenal, always.
#
# LOGO. assets/cannon.png is Arsenal's own 1921-22 club crest — a real,
# public-domain historical mark (see README.md for provenance and why the
# modern shield crest doesn't work at this resolution), thresholded to
# pure black/white at 20x9px, the size that still reads in this gutter.
#
# DATA. TheSportsDB (team id 133604, league id 4328) using the shared free
# "3" test key — no signup, no api-key input. Three known trade-offs,
# called out where they bite below: the free key's table lookup only
# returns the top 5 rows, so TABLE has a dedicated "outside the top 5"
# state; kickoff time is the fixture's own local time (the ground's
# timezone), not the viewer's, since there's no location input to convert
# it with; and the free key's livescore feed is shared across every sport
# and league, so LIVE scans the whole feed for Arsenal's two team ids —
# refresh is 300s (vs. 1800s for the slower pages) to keep the minute
# reasonably fresh without hammering the other endpoints.

RED = "#EF0107"
RED_LIGHT = "#FF6B61"  # attention/live/draw — a lighter tint of brand red
WHITE = "white"
GRAY = "gray"
NODATA_BG = "#0B0C12"
NODATA_TITLE = "#E8B04A"
NODATA_SUB = "#6A7090"

TEAM_ID = "133604"
LEAGUE_ID = "4328"

GUTTER_W = 24
CONTENT_X0 = 26
CONTENT_X1 = 63
CANNON_W = 20
CANNON_H = 9

HEADLINE_FONTS = ["6x8", "5x7", "4x5"]

MONTHS = {
    "01": "JAN", "02": "FEB", "03": "MAR", "04": "APR",
    "05": "MAY", "06": "JUN", "07": "JUL", "08": "AUG",
    "09": "SEP", "10": "OCT", "11": "NOV", "12": "DEC",
}

COMP_SHORT = {
    "ENGLISH PREMIER LEAGUE": "PL",
    "UEFA CHAMPIONS LEAGUE": "UCL",
    "UEFA EUROPA LEAGUE": "UEL",
    "UEFA EUROPA CONFERENCE LEAGUE": "UECL",
    "FA CUP": "FA CUP",
    "EFL CUP": "EFL CUP",
    "FA COMMUNITY SHIELD": "SHIELD",
    "EMIRATES CUP": "FRIENDLY",
    "CLUB FRIENDLIES": "FRIENDLY",
}

# Common long club names, shortened to fit a 64px panel; anything unmapped
# still falls through fit_clip's hard-clip, so no name can overflow.
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
    return COMP_SHORT.get(up, up[:8])

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
    """Left-edge rail: full-height accent color carrying the cannon mark."""
    c.rect(0, 0, GUTTER_W - 1, c.height - 1, fill = accent)
    x = (GUTTER_W - CANNON_W) // 2
    y = (c.height - CANNON_H) // 2
    c.image("cannon.png", x, y)

def tag(c, text):
    c.text(text, CONTENT_X0, 1, font = "4x5", color = GRAY)

def state_card(c, title, sub, title_color, sub_color, bg, accent):
    """Two-line fallback card: what happened, what it means (or what to do)."""
    c.fill(bg)
    gutter(c, accent)
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1
    t, tf = fit_clip(c, title, HEADLINE_FONTS, maxw)
    c.text(t, cx, 9, font = tf, color = title_color, align = "center")
    s, sf = fit_clip(c, sub, ["4x5"], maxw)
    c.text(s, cx, 19, font = sf, color = sub_color, align = "center")

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
            "score_for": home_score if home else away_score,
            "score_against": away_score if home else home_score,
            "minute": minute,
        }, "ok"
    return None, "not_live"

def live(c, ctx):
    m, state = fetch_live_match()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "LATER")
        return
    if state == "not_live":
        fx, fx_state = fetch_next_fixture()
        gutter(c, RED)
        tag(c, "LIVE")
        cx = (CONTENT_X0 + CONTENT_X1) // 2
        maxw = CONTENT_X1 - CONTENT_X0 - 1
        nl, nlf = fit_clip(c, "NOT LIVE", ["5x7", "4x5"], maxw)
        c.text(nl, cx, 9, font = nlf, color = GRAY, align = "center")
        sub = fx["date"] if fx_state == "ok" else "SEE NEXT"
        sub, sf = fit_clip(c, sub, ["4x5"], maxw)
        c.text(sub, cx, 19, font = sf, color = RED_LIGHT, align = "center")
        return

    gutter(c, RED_LIGHT)
    tag(c, "LIVE")
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    # Score is the hero, in white — the match isn't decided yet, so no
    # win/draw/loss color. Opponent + minute are the supporting detail.
    score = "%d-%d" % (m["score_for"], m["score_against"])
    score, sf = fit_clip(c, score, ["10x16", "6x8"], maxw)
    c.text(score, cx, 7, font = sf, color = WHITE, align = "center")

    name, nf = fit_clip(c, m["opponent"], ["4x5"], maxw)
    c.text(name, cx, 24, font = nf, color = GRAY, align = "center")
    c.text(m["minute"], CONTENT_X1, 24, font = "4x5", color = RED_LIGHT, align = "right")

def next(c, ctx):
    fx, state = fetch_next_fixture()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "LATER")
        return
    if state == "empty":
        empty_state(c, "NO FIXTURE", "LATER")
        return

    gutter(c, RED)
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    # Five rows, tight-packed (tag 5 + hero 8 + 3x5 + 4 gaps = 32 = exactly
    # the panel height, so the tag sits flush at y0 instead of this build's
    # usual y1): date and time get their own lines because "SEP 15 8:00PM"
    # together measures 57px against a 36px zone.
    c.text("NEXT", CONTENT_X0, 0, font = "4x5", color = GRAY)

    name, font = fit_clip(c, fx["opponent"], HEADLINE_FONTS, maxw)
    c.text(name, cx, 6, font = font, color = WHITE, align = "center")

    # Competition doesn't fit next to HOME/AWAY at this width (measured
    # "AWAY FRIENDLY" at 62px vs. a 36px zone) — dropped on this build; the
    # scroll build has room to show it.
    ha_color = WHITE if fx["home"] else GRAY
    ha_label = "HOME" if fx["home"] else "AWAY"
    c.text(ha_label, cx, 15, font = "4x5", color = ha_color, align = "center")

    c.text(fx["date"], cx, 21, font = "4x5", color = RED_LIGHT, align = "center")
    c.text(fx["time"], cx, 27, font = "4x5", color = RED_LIGHT, align = "center")

def result(c, ctx):
    r, state = fetch_last_result()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "LATER")
        return
    if state == "empty":
        empty_state(c, "NO RESULT", "NOT YET")
        return

    won = r["score_for"] > r["score_against"]
    drew = r["score_for"] == r["score_against"]
    accent = WHITE if won else (RED_LIGHT if drew else RED)
    outcome = "DRAW" if drew else ("WIN" if won else "LOSS")

    gutter(c, accent)
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    # Five rows, same tight rhythm as NEXT (tag flush at y0, hero capped at
    # 6x8 to leave room for WIN/LOSS/DRAW as its own line — white/red-tint
    # alone don't read as clearly as green/red used to, so the word carries
    # it now): score, outcome, opponent, date.
    c.text("RESULT", CONTENT_X0, 0, font = "4x5", color = GRAY)

    score = "%d-%d" % (r["score_for"], r["score_against"])
    score, sf = fit_clip(c, score, ["6x8", "5x7"], maxw)
    c.text(score, cx, 6, font = sf, color = accent, align = "center")

    c.text(outcome, cx, 15, font = "4x5", color = accent, align = "center")

    name, nf = fit_clip(c, r["opponent"], ["4x5"], maxw)
    c.text(name, cx, 21, font = nf, color = WHITE, align = "center")

    c.text(r["date"], cx, 27, font = "4x5", color = GRAY, align = "center")

def table(c, ctx):
    row, state = fetch_table_row(ctx.now)
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "LATER")
        return
    if state == "empty" or state == "outside_top5":
        # Not "empty" (that's a happy zero) and not a network error either —
        # the free lookup only covers the top 5 rows, so treat it like the
        # nodata card: amber, informational.
        nodata(c, "NO RANK", "TOP 5")
        return

    gutter(c, RED)
    tag(c, "TABLE")
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    rank = "#%d" % row["rank"]
    rank, rf = fit_clip(c, rank, ["10x16", "6x8"], maxw)
    c.text(rank, cx, 7, font = rf, color = WHITE, align = "center")

    c.text("%d PTS" % row["points"], cx, 24, font = "4x5", color = GRAY, align = "center")