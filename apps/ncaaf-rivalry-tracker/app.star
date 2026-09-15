PAD = 8  # scroll safe zone: keep the app's outer 8 px clear of content
HEX = "0123456789abcdef"
FONT_H = {"4x5": 5, "5x7": 7, "6x8": 8, "10x16": 16}
TITLE_COLOR = "#E8C25A"
TIE_COLOR = "#505050"
FALLBACK_TEAM_COLOR = "#B4B4B4"
DEMO_TEAMS = {
    "oklahoma": {"color": "#841617", "alt": "#ffffff"},
    "texas": {"color": "#bf5700", "alt": "#ffffff"},
}

def _s(ctx, key, fallback):
    v = ctx.inputs.get(key, fallback)
    if v == None:
        return fallback
    return str(v).strip()

def _norm(name):
    return str(name).strip().lower()

def _display(s):
    # Bitmap fonts have no accents or apostrophes; they would be skipped silently.
    return str(s).replace("é", "e").replace("É", "E").replace("'", "").replace("’", "").upper()

def _abbr(name, teams_map):
    if not name:
        return "TEAM"

    name_str = str(name)
    n = _norm(name_str)

    if n in teams_map and teams_map[n].get("abbreviation"):
        return teams_map[n]["abbreviation"].upper()

    if len(name_str) <= 4:
        return name_str.upper()

    parts = name_str.upper().split()
    if len(parts) >= 2:
        return (parts[0][:3] + parts[1][:1]).upper()

    return name_str[:4].upper()

def _hex_rgb(col):
    if col == None:
        return None
    s = str(col).strip().lower()
    if s.startswith("#"):
        s = s[1:]
    if len(s) != 6:
        return None
    rgb = []
    for i in [0, 2, 4]:
        hi = HEX.find(s[i])
        lo = HEX.find(s[i + 1])
        if hi < 0 or lo < 0:
            return None
        rgb.append(hi * 16 + lo)
    return rgb

def _rgb_hex(rgb):
    out = "#"
    for v in rgb:
        out += HEX[v // 16] + HEX[v % 16]
    return out

def _luma(col):
    rgb = _hex_rgb(col)
    if rgb == None:
        return 0
    return (299 * rgb[0] + 587 * rgb[1] + 114 * rgb[2]) // 1000

def _too_close(a, b):
    ra = _hex_rgb(a)
    rb = _hex_rgb(b)
    return abs(ra[0] - rb[0]) + abs(ra[1] - rb[1]) + abs(ra[2] - rb[2]) < 80

def _team_color(team_name, teams_map, avoid=None):
    # CFBD colors are print colors: black and deep navy vanish on an LED. Skip black, lift the
    # rest to a bright version of the same hue, and fall back to the alternate color when the
    # primary is black or too close to the other team's color (`avoid`).
    info = teams_map.get(_norm(team_name), {})
    options = []
    for key in ["color", "alt"]:
        rgb = _hex_rgb(info.get(key))
        if rgb != None and max(rgb) >= 24:
            peak = max(rgb)
            if peak < 210:
                rgb = [min(255, v * 210 // peak) for v in rgb]
            options.append(_rgb_hex(rgb))
    if avoid != None:
        distinct = [o for o in options + [FALLBACK_TEAM_COLOR] if not _too_close(o, avoid)]
        if distinct:
            return distinct[0]
    return options[0] if options else FALLBACK_TEAM_COLOR

def _ink(fill):
    return "black" if _luma(fill) > 150 else "white"

def _text_y(font, top, height):
    return top + (height - FONT_H[font]) // 2

def _fit(c, text, fonts, maxw):
    # Largest font that fits; if none does, clip the smallest (at a word when cheap) and end with "..".
    for f in fonts:
        if c.text_width(text, font=f) <= maxw:
            return text, f
    f = fonts[len(fonts) - 1]
    s = text
    for _ in range(len(text)):
        if len(s) <= 1 or c.text_width(s + "..", font=f) <= maxw:
            break
        s = s[:len(s) - 1]
    cut = s.rfind(" ")
    if cut > 0 and cut * 10 >= len(s) * 7:
        s = s[:cut]
    return s.rstrip(" ,-") + "..", f

def _label_value(c, label, value, x, y, align):
    lw = c.text_width(label, font="4x5")
    vw = c.text_width(value, font="4x5")
    total = lw + 4 + vw
    if align == "right":
        x = x - total + 1
    elif align == "center":
        x = x - total // 2
    c.text(label, x, y, font="4x5", color="gray")
    c.text(value, x + lw + 4, y, font="4x5", color="white")

def _message(c, title, detail, color):
    # Two-line status screen: what happened, then what to do about it.
    c.text_center(title, 8, font="5x7", color=color)
    c.text_center(detail, 19, font="4x5", color="gray")

def _tags_width(c, tags):
    w = 0
    for t in tags:
        if t:
            w = max(w, c.text_width(t, font="4x5"))
    return w + 3 if w > 0 else 0

def _draw_header(c, titles, label1, label2, col1, col2, full_names):
    # Team chips pinned to the safe-zone edges, rivalry name centered between them.
    right = c.width - 1 - PAD
    font = "4x5" if full_names else "5x7"
    if full_names:
        label1, _ = _fit(c, label1, ["4x5"], 56)
        label2, _ = _fit(c, label2, ["4x5"], 56)
    w1 = c.text_width(label1, font=font) + 4
    w2 = c.text_width(label2, font=font) + 4
    ty = _text_y(font, 0, 9)
    c.rect(PAD, 0, PAD + w1 - 1, 8, fill=col1)
    c.text(label1, PAD + 2, ty, font=font, color=_ink(col1))
    c.rect(right - w2 + 1, 0, right, 8, fill=col2)
    c.text(label2, right - w2 + 3, ty, font=font, color=_ink(col2))

    # A real rivalry name is clipped if it must be; generic titles step down to shorter wording.
    x0 = PAD + w1 + 4
    x1 = right - w2 - 4
    maxw = x1 - x0 + 1
    title = titles[len(titles) - 1]
    for t in titles:
        if c.text_width(t, font="4x5") <= maxw:
            title = t
            break
    title, tfont = _fit(c, title, ["5x7", "4x5"], maxw)
    tw = c.text_width(title, font=tfont)
    c.text(title, x0 + (x1 - x0 + 1 - tw) // 2, _text_y(tfont, 0, 9), font=tfont, color=TITLE_COLOR)

def _draw_series(c, w1, w2, ties, col1, col2, tags1, tags2):
    # Win totals flank a tug-of-war bar; rank sits at the top of each total, streak at the bottom.
    right = c.width - 1 - PAD
    n1 = str(w1)
    n2 = str(w2)
    d1 = c.text_width(n1, font="10x16")
    d2 = c.text_width(n2, font="10x16")
    c.text(n1, PAD, 10, font="10x16", color="white")
    c.text(n2, right - d2 + 1, 10, font="10x16", color="white")

    for i in range(2):
        if tags1[i]:
            c.text(tags1[i], PAD + d1 + 3, 10 + 11 * i, font="4x5", color="white")
        if tags2[i]:
            tw = c.text_width(tags2[i], font="4x5")
            c.text(tags2[i], right - d2 - 2 - tw, 10 + 11 * i, font="4x5", color="white")

    side = max(d1 + _tags_width(c, tags1), d2 + _tags_width(c, tags2))
    bx0 = PAD + side + 4
    bx1 = right - side - 4
    bw = bx1 - bx0 + 1
    total = w1 + w2 + ties
    p1 = (bw * w1 + total // 2) // total
    pt = (bw * ties + total // 2) // total
    if ties > 0 and pt == 0:
        pt = 1

    c.rect(bx0, 13, bx1, 22, fill=col2)
    if p1 > 0:
        c.rect(bx0, 13, bx0 + p1 - 1, 22, fill=col1)
    if pt > 0:
        c.rect(bx0 + p1, 13, bx0 + p1 + pt - 1, 22, fill=TIE_COLOR)
    for sx in [bx0 + p1, bx0 + p1 + pt]:
        if sx > bx0 and sx <= bx1:
            c.vline(sx, 13, 10, "black")

    # Midfield marker: whichever color crosses it leads the series.
    mid = bx0 + bw // 2
    c.vline(mid, 10, 2, "white")

def _draw_first_meeting(c, rank1, rank2):
    right = c.width - 1 - PAD
    side = max(_tags_width(c, [rank1]), _tags_width(c, [rank2]))
    if rank1:
        c.text(rank1, PAD, 15, font="4x5", color="white")
    if rank2:
        c.text(rank2, right - c.text_width(rank2, font="4x5") + 1, 15, font="4x5", color="white")
    maxw = right - PAD + 1 - 2 * (side + 1)
    text, font = _fit(c, "FIRST MEETING", ["10x16", "6x8", "5x7"], maxw)
    c.text_center(text, _text_y(font, 10, 16), font=font, color="white")

def _draw_demo(c, full_names):
    # No API key yet: a sample Red River screen marked DEMO, so setup and catalog previews
    # show the real layout instead of an empty prompt.
    col1 = _team_color("Oklahoma", DEMO_TEAMS)
    col2 = _team_color("Texas", DEMO_TEAMS, col1)
    label1 = "OKLAHOMA" if full_names else "OU"
    label2 = "TEXAS" if full_names else "TEX"
    _draw_header(c, ["RED RIVER RIVALRY"], label1, label2, col1, col2, full_names)
    _draw_series(c, 51, 62, 5, col1, col2, ["#24", ""], ["#1", "W2"])
    _label_value(c, "LAST", "TEX 23-6", PAD, 27, "left")
    c.text_center("DEMO", 27, font="4x5", color="amber")
    _label_value(c, "NEXT", "OCT 10", c.width - 1 - PAD, 27, "right")

def get_rivalry_titles():
    url = "https://raw.githubusercontent.com/SlaterDen/ncaaf-rivalries/refs/heads/main/rivalries.json"
    res = http.get(url, ttl_seconds=86400)

    if res["status_code"] == 200 and res["json"] != None:
        return res["json"]

    # Fallback dictionary if the network fetch fails
    return {
        "oklahoma|texas": "RED RIVER RIVALRY",
        "michigan|ohio state": "THE GAME"
    }

def rivalry_title(t1, t2):
    a = _norm(t1)
    b = _norm(t2)
    key = (a + "|" + b) if a < b else (b + "|" + a)
    titles_map = get_rivalry_titles()
    return titles_map.get(key, None)

def cfbd_get(path, params, apikey):
    return http.get(
        "https://api.collegefootballdata.com" + path,
        headers={"Authorization": "Bearer " + apikey},
        params=params,
        ttl_seconds=86400,
    )

def _safe_int(val):
    if val == None:
        return None
    s = str(val).strip()
    if s.isdigit():
        return int(s)
    return None

def _parse_date(dt_str):
    if dt_str == None or len(str(dt_str)) < 10:
        return None
    parts = str(dt_str).split("T")[0].split("-")
    if len(parts) == 3:
        m_map = {"01":"JAN","02":"FEB","03":"MAR","04":"APR","05":"MAY","06":"JUN","07":"JUL","08":"AUG","09":"SEP","10":"OCT","11":"NOV","12":"DEC"}
        month_str = m_map.get(parts[1], parts[1])
        return month_str + " " + parts[2]
    return None

def main(c, ctx):
    c.fill("black")

    apikey = _s(ctx, "apikey", "")
    user_t1 = _s(ctx, "team1", "Oklahoma")
    user_t2 = _s(ctx, "team2", "Texas")
    name_mode = _s(ctx, "teamnamelength", "Abbreviations")

    if not apikey:
        _draw_demo(c, name_mode == "Full Name")
        return

    if _norm(user_t1) == _norm(user_t2):
        _message(c, "PICK TWO DIFFERENT TEAMS", "TEAM 1 AND TEAM 2 MATCH", "amber")
        return

    # Derive year dynamically, treating Jan/Feb as the previous CFB season
    now = ctx.now
    current_year = now.year
    if now.month <= 2:
        current_year -= 1

    # Fetch dynamic FBS team directory for validation, colors, and abbreviations
    teams_r = cfbd_get("/teams/fbs", {}, apikey)
    teams_map = {}
    if teams_r["status_code"] == 200 and teams_r["json"] != None:
        for t in teams_r["json"]:
            school = t.get("school", "")
            if school:
                teams_map[_norm(school)] = {
                    "abbreviation": t.get("abbreviation"),
                    "color": t.get("color"),
                    "alt": t.get("alternateColor")
                }

    # Validate that both user input teams exist in the FBS directory
    t1_norm = _norm(user_t1)
    t2_norm = _norm(user_t2)

    if len(teams_map) > 0 and (t1_norm not in teams_map or t2_norm not in teams_map):
        _message(c, "TEAM NOT RECOGNIZED", "PICK BOTH TEAMS AGAIN IN SETTINGS", "amber")
        return

    # Fetch dynamic rankings (CFP preferred, AP fallback)
    rankings_map = {}
    rank_r = cfbd_get("/rankings", {"year": current_year}, apikey)
    if rank_r["status_code"] == 200 and rank_r["json"] != None:
        weeks_data = rank_r["json"]
        if len(weeks_data) > 0:
            latest_week = weeks_data[len(weeks_data) - 1]
            polls = latest_week.get("polls", [])

            ap_polls = []
            cfp_polls = []
            for p in polls:
                p_type = _norm(p.get("poll", ""))
                if "playoff" in p_type or "cfp" in p_type:
                    cfp_polls = p.get("ranks", [])
                elif "ap" in p_type or "associated press" in p_type:
                    ap_polls = p.get("ranks", [])

            active_ranks = cfp_polls if len(cfp_polls) > 0 else ap_polls
            for item in active_ranks:
                school_name = item.get("school", "")
                rk = item.get("rank")
                if school_name and rk:
                    rankings_map[_norm(school_name)] = int(rk)

    r = cfbd_get("/teams/matchup", {
        "team1": user_t1,
        "team2": user_t2,
    }, apikey)

    if r["status_code"] != 200:
        if r["status_code"] in [401, 403]:
            _message(c, "CFBD KEY REJECTED", "CHECK THE API KEY IN SETTINGS", "red")
        else:
            _message(c, "CFBD UNAVAILABLE", "CHECK KEY OR TRY AGAIN LATER", "red")
        return

    data = r["json"]
    if data == None:
        _message(c, "NO SERIES DATA", "CFBD HAS NO RECORD FOR THIS PAIR", "amber")
        return

    api_t1 = data.get("team1", user_t1)
    raw_w1 = int(data.get("team1Wins", 0) or 0)
    raw_w2 = int(data.get("team2Wins", 0) or 0)
    ties = int(data.get("ties", 0) or 0)

    if _norm(user_t1) == _norm(api_t1):
        team1 = user_t1
        team2 = user_t2
        w1 = raw_w1
        w2 = raw_w2
    else:
        team1 = user_t2
        team2 = user_t1
        w1 = raw_w2
        w2 = raw_w1

    total = w1 + w2 + ties
    a1 = _abbr(team1, teams_map)
    a2 = _abbr(team2, teams_map)

    r1_val = rankings_map.get(_norm(team1))
    r2_val = rankings_map.get(_norm(team2))

    rivalry = rivalry_title(user_t1, user_t2)
    if rivalry != None:
        titles = [_display(rivalry)]
    elif total > 0:
        titles = ["ALL-TIME SERIES", "SERIES", "VS"]
    else:
        titles = ["HEAD TO HEAD", "VS"]

    games = data.get("games", [])
    if games == None:
        games = []

    past_games = []
    next_matchup_date = None

    for g in games:
        s1 = g.get("team1Score")
        s2 = g.get("team2Score")
        if s1 == None or s2 == None:
            s1 = g.get("homeScore")
            s2 = g.get("awayScore")

        if s1 != None and s2 != None:
            past_games.append(g)
        else:
            dt = _parse_date(g.get("startDate"))
            if dt != None:
                next_matchup_date = dt

    if next_matchup_date == None:
        sched_r = cfbd_get("/games", {
            "year": current_year,
            "team": team1,
        }, apikey)
        if sched_r["status_code"] == 200 and sched_r["json"] != None:
            for sg in sched_r["json"]:
                h = _norm(sg.get("homeTeam", ""))
                a = _norm(sg.get("awayTeam", ""))
                t2_norm = _norm(team2)
                if t2_norm in h or t2_norm in a:
                    hs = sg.get("home_points")
                    as_ = sg.get("away_points")
                    if hs == None and as_ == None:
                        dt = _parse_date(sg.get("startDate"))
                        if dt != None:
                            next_matchup_date = dt
                            break

    if next_matchup_date == None:
        next_matchup_date = "TBD"

    past_games = sorted(past_games, key=lambda g: g.get("season", 0), reverse=True)

    last_game_str = "-"
    streak_who = ""
    streak_len = 0

    if len(past_games) > 0:
        g0 = past_games[0]
        s1 = _safe_int(g0.get("team1Score"))
        s2 = _safe_int(g0.get("team2Score"))
        if s1 == None or s2 == None:
            s1 = _safe_int(g0.get("homeScore"))
            s2 = _safe_int(g0.get("awayScore"))

        if s1 != None and s2 != None:
            g_team1 = _norm(g0.get("team1", g0.get("homeTeam", "")))
            if _norm(team1) in g_team1 or g_team1 in _norm(team1):
                score_t1, score_t2 = s1, s2
            else:
                score_t1, score_t2 = s2, s1

            if score_t1 > score_t2:
                last_game_str = a1 + " " + str(score_t1) + "-" + str(score_t2)
            elif score_t2 > score_t1:
                last_game_str = a2 + " " + str(score_t2) + "-" + str(score_t1)
            else:
                last_game_str = "TIE " + str(score_t1) + "-" + str(score_t2)

        winner = None
        t1n = _norm(team1)

        for g in past_games:
            hs = _safe_int(g.get("homeScore"))
            as_ = _safe_int(g.get("awayScore"))
            if hs == None or as_ == None:
                hs = _safe_int(g.get("team1Score"))
                as_ = _safe_int(g.get("team2Score"))
                if hs == None or as_ == None:
                    break
                ht = _norm(g.get("team1", g.get("homeTeam", "")))
                at = _norm(g.get("team2", g.get("awayTeam", "")))
            else:
                ht = _norm(g.get("homeTeam", ""))
                at = _norm(g.get("awayTeam", ""))

            if hs > as_:
                w = ht
            elif as_ > hs:
                w = at
            else:
                break

            if winner == None:
                winner = w
            if w != winner:
                break

            streak_len += 1

        if streak_len > 0 and winner != None:
            if t1n in winner or winner in t1n:
                streak_who = a1
            else:
                streak_who = a2

    col1 = _team_color(team1, teams_map)
    col2 = _team_color(team2, teams_map, col1)
    full_names = name_mode == "Full Name"
    label1 = _display(team1) if full_names else a1
    label2 = _display(team2) if full_names else a2
    rank1 = "#" + str(r1_val) if r1_val != None else ""
    rank2 = "#" + str(r2_val) if r2_val != None else ""
    streak1 = "W" + str(streak_len) if streak_len > 0 and streak_who == a1 else ""
    streak2 = "W" + str(streak_len) if streak_len > 0 and streak_who == a2 else ""
    right = c.width - 1 - PAD

    _draw_header(c, titles, label1, label2, col1, col2, full_names)

    if total > 0:
        _draw_series(c, w1, w2, ties, col1, col2, [rank1, streak1], [rank2, streak2])
        _label_value(c, "LAST", last_game_str.upper(), PAD, 27, "left")
        if ties > 0:
            _label_value(c, "TIES", str(ties), c.width // 2, 27, "center")
        _label_value(c, "NEXT", next_matchup_date.upper(), right, 27, "right")
    else:
        _draw_first_meeting(c, rank1, rank2)
        _label_value(c, "NEXT", next_matchup_date.upper(), c.width // 2, 27, "center")
