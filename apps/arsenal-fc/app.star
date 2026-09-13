# Arsenal FC — a GDN Starlark app (64x32, 4 pages).
#
# DESIGN. Arsenal colors only — red, white, black, and shades of them (no
# green, no amber/gold): loss is bold red, win/draw/home/live are white or
# a lighter red tint, never a different hue. A left-edge gutter (24px,
# wearing the page's state color) carries the real Arsenal cannon mark, so
# the app identifies itself with no top header band eating into the
# panel's 32 rows. The content zone (x 26-63) stacks a small page tag,
# one hero value, and up to three detail lines beneath it — single
# column, since 37px doesn't leave room for the side-by-side zones the
# 192px scroll build uses; every page's rows are tight-packed against the
# full 32px height (tag flush at y0), the same trick that made room for
# WIN/LOSS/DRAW below. Four pages rotate: LIVE (score + minute while a
# match is on, else a compact "not live" card), NEXT (upcoming fixture,
# with a same/tomorrow/N-days countdown and a star badge on European
# nights), RESULT (last final score), TABLE (rank, points, goal
# difference, games played, last-5 form). No inputs but one: a kickoff
# time zone (see TZ_OFFSET) — this is otherwise Arsenal, always.
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
# state; kickoff time is converted from the fixture's own local (UK) time
# using a fixed standard-time offset (no daylight-saving adjustment); and
# the free key's livescore feed is shared across every sport and league,
# so LIVE scans the whole feed for Arsenal's team id — refresh is 300s
# (vs. 1800s for the slower pages) to keep the minute reasonably fresh
# without hammering the other endpoints.

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

# Kickoff times come from the API in the fixture's own (UK) local time.
# Fixed standard-time offsets from UK — not DST-adjusted: doing that
# correctly needs a real tz database, which isn't available here. Good
# enough to get viewers within an hour outside of the ~6 weeks a year the
# two regions' clocks change on different dates.
TZ_OFFSET = {
    "UK": 0, "US EASTERN": -5, "US CENTRAL": -6, "US MOUNTAIN": -7,
    "US PACIFIC": -8, "CENTRAL EUROPE": 1,
}

EUROPEAN_COMPS = {"UCL": True, "UEL": True, "UECL": True}

# 5x5 star — the "big European night" badge, drawn next to the
# competition tag instead of reaching for a new accent color.
STAR = [
    [0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1],
    [0, 1, 1, 1, 0],
    [0, 1, 0, 1, 0],
    [1, 0, 0, 0, 1],
]

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

def fmt_ymd(y, m, d):
    key = str(m) if m >= 10 else "0" + str(m)
    month = MONTHS.get(key, "???")
    return month + " " + str(d)

def fmt_hm12(h, m):
    ap = "AM" if h < 12 else "PM"
    h12 = h % 12
    if h12 == 0:
        h12 = 12
    mm = str(m) if m >= 10 else "0" + str(m)
    return "%d:%s%s" % (h12, mm, ap)

def parse_iso_date(date_iso):
    return int(date_iso[0:4]), int(date_iso[5:7]), int(date_iso[8:10])

def parse_hms(hhmmss):
    return int(hhmmss[0:2]), int(hhmmss[3:5])

# Julian day number <-> Gregorian date, so a kickoff can be shifted by a
# timezone offset (and a countdown computed) with plain integer math —
# no date library is available in this sandbox, and there's no `while`
# (see apply_tz), so this has to stay a couple of `if`s, not a loop.
def ymd_to_jdn(y, m, d):
    a = (14 - m) // 12
    y2 = y + 4800 - a
    m2 = m + 12 * a - 3
    return d + (153 * m2 + 2) // 5 + 365 * y2 + y2 // 4 - y2 // 100 + y2 // 400 - 32045

def jdn_to_ymd(jdn):
    a = jdn + 32044
    b = (4 * a + 3) // 146097
    c = a - (146097 * b) // 4
    d2 = (4 * c + 3) // 1461
    e = c - (1461 * d2) // 4
    m2 = (5 * e + 2) // 153
    day = e - (153 * m2 + 2) // 5 + 1
    month = m2 + 3 - 12 * (m2 // 10)
    year = 100 * b + d2 - 4800 + m2 // 10
    return year, month, day

def apply_tz(y, m, d, h, mi, offset_hours):
    total_min = h * 60 + mi + offset_hours * 60
    day_shift = 0
    if total_min < 0:
        total_min += 24 * 60
        day_shift = -1
    elif total_min >= 24 * 60:
        total_min -= 24 * 60
        day_shift = 1
    if day_shift != 0:
        y, m, d = jdn_to_ymd(ymd_to_jdn(y, m, d) + day_shift)
    return y, m, d, total_min // 60, total_min % 60

def days_until(now, y, m, d):
    return ymd_to_jdn(y, m, d) - ymd_to_jdn(now.year, now.month, now.day)

def countdown_label(days, date_str):
    if days == 0:
        return "TODAY"
    if days == 1:
        return "TMRW"
    if days >= 2 and days <= 6:
        return "%d DAYS" % days
    return date_str  # far out, or a past-due edge case — just show the date

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

def row_width(c, parts):
    """Total px width of a run of ("text", str, font, color) / ("star",) parts."""
    w = 0
    for i in range(len(parts)):
        if i > 0:
            w += 2
        p = parts[i]
        w += 5 if p[0] == "star" else c.text_width(p[1], font = p[2])
    return w

def draw_row(c, cx, y, parts, color, maxw):
    """Center a run of text/star parts as one unit at (cx, y).

    If the whole run is too wide (worst case: "AWAY" + star + "UECL" is
    48px against a 36px zone), hard-clip the last text part rather than
    let the row run off the panel."""
    parts = list(parts)
    last = parts[len(parts) - 1]
    if last[0] != "star":
        text = last[1]
        for i in range(len(text) - 1):
            if row_width(c, parts) <= maxw:
                break
            text = text[:-1]
            parts[len(parts) - 1] = ("text", text, last[2])

    x = cx - row_width(c, parts) // 2
    for i in range(len(parts)):
        if i > 0:
            x += 2
        p = parts[i]
        if p[0] == "star":
            c.bitmap(STAR, x, y, color = color)
            x += 5
        else:
            c.text(p[1], x, y, font = p[2], color = color)
            x += c.text_width(p[1], font = p[2])

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

def fetch_next_fixture(now, tz_offset):
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
    comp = short_comp(e.get("strLeague") or "")
    y, m, d = parse_iso_date(e.get("dateEvent") or "0000-01-01")
    hh, mm = parse_hms(e.get("strTimeLocal") or e.get("strTime") or "00:00:00")
    y, m, d, hh, mm = apply_tz(y, m, d, hh, mm, tz_offset)
    days = days_until(now, y, m, d)
    date_str = fmt_ymd(y, m, d)
    return {
        "opponent": short_club(opponent or "TBD"),
        "home": home,
        "comp": comp,
        "european": EUROPEAN_COMPS.get(comp, False),
        "date": date_str,
        "time": fmt_hm12(hh, mm),
        "countdown": countdown_label(days, date_str),
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
    y, m, d = parse_iso_date(r.get("dateEvent") or "0000-01-01")
    return {
        "opponent": short_club(opponent or "TBD"),
        "score_for": home_score if home else away_score,
        "score_against": away_score if home else home_score,
        "comp": short_comp(r.get("strLeague") or ""),
        "date": fmt_ymd(y, m, d),
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
                "goal_diff": int(row.get("intGoalDifference") or 0),
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
        # 4x5/5x7 have no apostrophe glyph (it's silently skipped, not
        # drawn) — "M" for minutes avoids that trap.
        minute = progress if status == "HT" else progress + "M"
        comp = short_comp(row.get("strLeague") or "")
        return {
            "opponent": short_club(opponent or "TBD"),
            "home": home,
            "score_for": home_score if home else away_score,
            "score_against": away_score if home else home_score,
            "minute": minute,
            "comp": comp,
            "european": EUROPEAN_COMPS.get(comp, False),
        }, "ok"
    return None, "not_live"

def live(c, ctx):
    m, state = fetch_live_match()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "LATER")
        return

    tz_offset = TZ_OFFSET.get(ctx.inputs.get("timezone", "UK"), 0)
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    if state == "not_live":
        fx, fx_state = fetch_next_fixture(ctx.now, tz_offset)
        gutter(c, RED)
        tag(c, "LIVE")
        nl, nlf = fit_clip(c, "NOT LIVE", ["5x7", "4x5"], maxw)
        c.text(nl, cx, 9, font = nlf, color = GRAY, align = "center")
        sub = fx["countdown"] if fx_state == "ok" else "SEE NEXT"
        sub, sf = fit_clip(c, sub, ["4x5"], maxw)
        c.text(sub, cx, 19, font = sf, color = RED_LIGHT, align = "center")
        return

    gutter(c, RED_LIGHT)

    # Five rows, same tight rhythm as RESULT: tag, score (capped at 6x8 to
    # leave room for three detail lines instead of one), opponent,
    # minute + competition (with the European star badge when it applies),
    # home/away.
    c.text("LIVE", CONTENT_X0, 0, font = "4x5", color = GRAY)

    # Score is the hero, in white — the match isn't decided yet, so no
    # win/draw/loss color.
    score = "%d-%d" % (m["score_for"], m["score_against"])
    score, sf = fit_clip(c, score, ["6x8", "5x7"], maxw)
    c.text(score, cx, 6, font = sf, color = WHITE, align = "center")

    name, nf = fit_clip(c, m["opponent"], ["4x5"], maxw)
    c.text(name, cx, 15, font = nf, color = WHITE, align = "center")

    if m["european"]:
        draw_row(c, cx, 21, [
            ("text", m["minute"], "4x5"), ("star",), ("text", m["comp"], "4x5"),
        ], RED_LIGHT, maxw)
    else:
        c.text(m["minute"] + " " + m["comp"], cx, 21, font = "4x5",
               color = RED_LIGHT, align = "center")

    ha_label = "HOME" if m["home"] else "AWAY"
    ha_color = WHITE if m["home"] else GRAY
    c.text(ha_label, cx, 27, font = "4x5", color = ha_color, align = "center")

def next(c, ctx):
    tz_offset = TZ_OFFSET.get(ctx.inputs.get("timezone", "UK"), 0)
    fx, state = fetch_next_fixture(ctx.now, tz_offset)
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

    # Competition normally doesn't fit next to HOME/AWAY at this width
    # (measured "AWAY FRIENDLY" at 62px vs. a 36px zone) — but a European
    # night is worth the squeeze: "AWAY ★UCL" is short enough to earn its
    # own row, so only European fixtures get it.
    ha_label = "HOME" if fx["home"] else "AWAY"
    ha_color = WHITE if fx["home"] else GRAY
    if fx["european"]:
        draw_row(c, cx, 15, [
            ("text", ha_label, "4x5"), ("star",), ("text", fx["comp"], "4x5"),
        ], ha_color, maxw)
    else:
        c.text(ha_label, cx, 15, font = "4x5", color = ha_color, align = "center")

    cd, cdf = fit_clip(c, fx["countdown"], ["4x5"], maxw)
    c.text(cd, cx, 21, font = cdf, color = RED_LIGHT, align = "center")
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

FORM_COLOR = {"W": WHITE, "D": RED_LIGHT, "L": RED}

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
    cx = (CONTENT_X0 + CONTENT_X1) // 2
    maxw = CONTENT_X1 - CONTENT_X0 - 1

    # Five rows, same tight rhythm as RESULT/NEXT: tag, rank (6x8), points
    # + goal difference, games played, last-5 form as small squares.
    c.text("TABLE", CONTENT_X0, 0, font = "4x5", color = GRAY)

    rank = "#%d" % row["rank"]
    rank, rf = fit_clip(c, rank, ["6x8", "5x7"], maxw)
    c.text(rank, cx, 6, font = rf, color = WHITE, align = "center")

    gd = row["goal_diff"]
    gd_str = "+%d" % gd if gd > 0 else str(gd)
    pts_line, pf = fit_clip(c, "%d PTS%s" % (row["points"], gd_str), ["4x5"], maxw)
    c.text(pts_line, cx, 15, font = pf, color = WHITE, align = "center")

    c.text("PLD %d" % row["played"], cx, 21, font = "4x5", color = GRAY, align = "center")

    # Form squares, most recent match on the right.
    form = row["form"]
    n = len(form)
    if n > 0:
        sq = 4
        gap = 1
        total_w = n * sq + (n - 1) * gap
        x0 = cx - total_w // 2
        for i in range(n):
            x = x0 + i * (sq + gap)
            col = FORM_COLOR.get(form[i], GRAY)
            c.rect(x, 27, x + sq - 1, 27 + sq - 1, fill = col)
