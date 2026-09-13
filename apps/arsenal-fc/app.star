# Arsenal FC — a GDN Starlark app (64x32, 3 pages).
#
# DESIGN. Arsenal red (#EF0107) header band on every page, carrying a bold
# "ARS" wordmark — plain text, not a reproduction of the club crest — so the
# app identifies itself at a glance with no full "ARSENAL" text needed.
# Black ground everywhere else for contrast. Four pages
# rotate: LIVE (score + minute while a match is on, else a compact "not
# live, next up" card), NEXT (upcoming fixture), RESULT (last final score —
# the header color reads win/draw/loss at a glance), TABLE (current
# Premier League position). No inputs: this app is Arsenal, always.
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
WHITE = "white"
GRAY = "gray"
AMBER = "amber"
GREEN = "green"
NODATA_BG = "#0B0C12"
NODATA_TITLE = "#E8B04A"
NODATA_SUB = "#6A7090"

TEAM_ID = "133604"
LEAGUE_ID = "4328"

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

def header(c, tag, accent):
    """Shared top band: ARS wordmark + short page tag, on an accent color."""
    c.rect(0, 0, c.width - 1, 7, fill = accent)
    c.text("ARS", 2, 1, font = "5x7", color = "black")
    c.text(tag, 62, 1, font = "4x5", color = "black", align = "right")

def state_card(c, title, sub, title_color, sub_color, bg):
    """Two-line fallback card: what happened, what it means (or what to do)."""
    c.fill(bg)
    t, tf = fit_clip(c, title, HEADLINE_FONTS, c.width - 6)
    c.text(t, c.width // 2, 10, font = tf, color = title_color, align = "center")
    s, sf = fit_clip(c, sub, ["4x5"], c.width - 6)
    c.text(s, c.width // 2, 20, font = sf, color = sub_color, align = "center")

def nodata(c, title, sub):
    state_card(c, title, sub, NODATA_TITLE, NODATA_SUB, NODATA_BG)

def empty_state(c, title, sub):
    state_card(c, title, sub, GREEN, GRAY, "black")

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
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "not_live":
        # Not an error or a happy empty — just off-hours. Point at NEXT.
        fx, fx_state = fetch_next_fixture()
        header(c, "LIVE", RED)
        c.text("NOT LIVE", c.width // 2, 11, font = "5x7", color = GRAY, align = "center")
        if fx_state == "ok":
            sub = "NEXT " + fx["date"]
        else:
            sub = "CHECK NEXT PAGE"
        sub, sf = fit_clip(c, sub, ["4x5"], c.width - 4)
        c.text(sub, c.width // 2, 22, font = sf, color = AMBER, align = "center")
        return

    c.rect(0, 0, c.width - 1, 7, fill = RED)
    c.text("ARS", 2, 1, font = "5x7", color = "black")
    name, _ = fit_clip(c, m["opponent"], ["4x5"], c.width - 12)
    c.text(name, 62, 1, font = "4x5", color = "black", align = "right")

    # Score is the hero, in white — the match isn't decided yet, so no
    # win/draw/loss color. The minute below is the "in-play" attention cue.
    score = "%d-%d" % (m["score_for"], m["score_against"])
    c.text(score, c.width // 2, 9, font = "10x16", color = WHITE, align = "center")

    c.text(m["minute"], c.width // 2, 26, font = "4x5", color = AMBER, align = "center")

def next(c, ctx):
    fx, state = fetch_next_fixture()
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "empty":
        empty_state(c, "NO FIXTURE", "TRY LATER")
        return

    header(c, "NEXT", RED)

    name, font = fit_clip(c, fx["opponent"], HEADLINE_FONTS, c.width - 4)
    c.text(name, c.width // 2, 9, font = font, color = WHITE, align = "center")

    ha_color = GREEN if fx["home"] else GRAY
    ha_label = "HOME" if fx["home"] else "AWAY"
    c.text(fx["comp"], 2, 18, font = "4x5", color = GRAY)
    c.text(ha_label, 62, 18, font = "4x5", color = ha_color, align = "right")

    when = fx["date"] + " " + fx["time"]
    when, wf = fit_clip(c, when, ["4x5"], c.width - 4)
    c.text(when, c.width // 2, 25, font = wf, color = AMBER, align = "center")

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
    accent = GREEN if won else (AMBER if drew else "red")

    c.rect(0, 0, c.width - 1, 7, fill = accent)
    c.text("ARS", 2, 1, font = "5x7", color = "black")
    name, _ = fit_clip(c, r["opponent"], ["4x5"], c.width - 12)
    c.text(name, 62, 1, font = "4x5", color = "black", align = "right")

    # Score is the hero: 10x16 fills rows 9-24, leaving a clean footer band.
    score = "%d-%d" % (r["score_for"], r["score_against"])
    c.text(score, c.width // 2, 9, font = "10x16", color = accent, align = "center")

    foot = r["comp"] + " " + r["date"]
    foot, ff = fit_clip(c, foot, ["4x5"], c.width - 4)
    c.text(foot, c.width // 2, 26, font = ff, color = GRAY, align = "center")

FORM_COLOR = {"W": GREEN, "D": AMBER, "L": "red"}

def table(c, ctx):
    row, state = fetch_table_row(ctx.now)
    c.fill("black")

    if state == "offline":
        nodata(c, "NO DATA", "TRY LATER")
        return
    if state == "empty" or state == "outside_top5":
        # Not "empty" (that's a happy zero) and not a network error either —
        # the free lookup only covers the top 5 rows, so treat it like the
        # nodata card: amber, informational.
        nodata(c, "NOT RANKED", "TOP 5 ONLY")
        return

    header(c, "EPL", RED)

    rank = "#%d" % row["rank"]
    c.text(rank, c.width // 2, 9, font = "10x16", color = WHITE, align = "center")

    c.text("%d PTS" % row["points"], c.width // 2, 26, font = "4x5",
           color = GRAY, align = "center")

    # Form as small colored squares, most recent match on the right.
    form = row["form"]
    n = len(form)
    if n > 0:
        sq = 4
        gap = 2
        total_w = n * sq + (n - 1) * gap
        x0 = (c.width - total_w) // 2
        for i in range(n):
            x = x0 + i * (sq + gap)
            col = FORM_COLOR.get(form[i], GRAY)
            c.rect(x, 19, x + sq - 1, 19 + sq - 1, fill = col)
