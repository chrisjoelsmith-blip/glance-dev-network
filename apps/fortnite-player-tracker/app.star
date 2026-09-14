# Fortnite Player Tracker — a GDN Starlark app (64x32, 5 pages).
#
# DESIGN. You + 9 named friend slots = 10 players, but GDN caps an app at 8
# pages — so players are paired up, 2 per page (page 1 is you + friend 1,
# page 2 is friends 2-3, and so on). Every page shares the same skeleton — a
# tiny gold Victory Royale crown + the current player's Epic name up top (the
# app's identity mark, since no game logo is used), then one big lifetime
# stat filling the rest of the panel. Every 60s the page advances one step
# through a combined cycle of "player A's 5 stats, then player B's 5 stats",
# so each player on a page gets 5 uninterrupted minutes before it hands off.
# The accent rail across the very top always wears the current stat's color,
# so a glance at the rail tells you what the number means before you've read
# the label underneath it.
#
# Data comes from fortnite-api.com's public BR stats endpoint (Epic accounts
# only, per the human's platform). Accuracy, headshots and "crown wins" were
# on the original wishlist but got dropped on purpose: no current, legitimate
# Fortnite API exposes them (Epic pulled that data years ago), and a stat card
# that always reads zero is worse than one fewer card. What's left — wins,
# K/D, win rate, kills, top 10s — is all real, live, lifetime data.

CROWN = [
    [1, 0, 1, 0, 1],
    [1, 1, 1, 1, 1],
    [0, 1, 1, 1, 0],
    [1, 1, 1, 1, 1],
]
CROWN_COLOR = "amber"

# key into the stats dict, on-panel label, rail/hero color for that stat.
STATS = [
    ("wins", "WINS", "amber"),
    ("kd", "K/D", "cyan"),
    ("winRate", "WIN RATE", "green"),
    ("kills", "KILLS", "orange"),
    ("top10", "TOP 10S", "purple"),
]

HERO_FONTS = ["10x16", "9x12", "6x8"]  # the big number, biggest that fits
MSG_FONTS = ["6x8", "5x7", "4x5"]  # error/empty headline, same ladder pattern
NAME_MAXW = 53  # 64 - 9 (crown + gap) - 2 (right margin)
HERO_MAXW = 60  # 64 - 2px margin each side
MSG_MAXW = 60

def _fit(c, text, fonts, maxw):
    """Largest font in the ladder that fits; last resort if none do."""
    for f in fonts:
        if c.text_width(text, font = f) <= maxw:
            return f
    return fonts[-1]

def _clip(c, text, font, maxw):
    """Hard-clip a single word (Epic names have no spaces) to fit maxw."""
    if c.text_width(text, font = font) <= maxw:
        return text
    n = len(text)
    for i in range(n - 1, 0, -1):
        cand = text[:i]
        if c.text_width(cand, font = font) <= maxw:
            return cand
    return text[:1]

def _fmt_count(n):
    """Big integer counters (wins/kills/top10) compact past 10,000."""
    if n >= 10000:
        return _fmt1(n / 1000.0) + "K"
    return str(int(n))

def _fmt2(x):
    """Two decimal places without relying on %.2f float formatting."""
    v = int(x * 100 + 0.5)
    if v < 0:
        v = 0
    whole = v // 100
    frac = v % 100
    fracstr = str(frac)
    if len(fracstr) < 2:
        fracstr = "0" + fracstr
    return str(whole) + "." + fracstr

def _fmt1(x):
    """One decimal place, same trick as _fmt2."""
    v = int(x * 10 + 0.5)
    if v < 0:
        v = 0
    whole = v // 10
    frac = v % 10
    return str(whole) + "." + str(frac)

def _stat_value(d, key):
    if key == "kd":
        return _fmt2(d.get("kd", 0.0))
    if key == "winRate":
        return _fmt1(d.get("winRate", 0.0)) + "%"
    return _fmt_count(d.get(key, 0))

def fetch_stats(name, apikey):
    """One http.get per render; cached 5 min so the 60s frame-cycle refresh
    doesn't multiply API calls."""
    resp = http.get(
        "https://fortnite-api.com/v2/stats/br/v2",
        params = {"name": name, "accountType": "epic"},
        headers = {"Authorization": apikey},
        ttl_seconds = 300,
    )
    status = resp["status_code"]
    if status == 200:
        j = resp["json"]
        data = j.get("data") if j else None
        if not data:
            return {"state": "notfound"}
        overall = data.get("stats", {}).get("all", {}).get("overall", {})
        if not overall:
            return {"state": "nostats"}
        overall["state"] = "ok"
        overall["name"] = data.get("account", {}).get("name", name)
        return overall
    if status == 401 or status == 403:
        return {"state": "badkey"}
    if status == 404:
        return {"state": "notfound"}
    return {"state": "offline"}

def make_demo(name):
    """Deterministic-per-name sample data so each demo page differs a bit."""
    seed = len(name) * 7 + 13
    return {
        "state": "ok",
        "name": name,
        "wins": 30 + (seed * 11) % 300,
        "kd": 1.2 + (seed % 15) * 0.15,
        "winRate": 4 + (seed * 3) % 18,
        "kills": 800 + (seed * 97) % 12000,
        "top10": 120 + (seed * 41) % 900,
    }

def draw_crown(c, x, y):
    c.bitmap(CROWN, x, y, CROWN_COLOR)

def draw_frame(c, rail_color):
    c.fill("black")
    c.rect(0, 0, c.width - 1, 1, fill = rail_color)

def draw_header(c, name_text):
    draw_crown(c, 2, 3)
    label = _clip(c, name_text.upper(), "4x5", NAME_MAXW)
    c.text(label, 9, 3, font = "4x5", color = "white")

def draw_message(c, rail_color, header_text, msg1, msg2):
    draw_frame(c, rail_color)
    draw_header(c, header_text)
    f1 = _fit(c, msg1, MSG_FONTS, MSG_MAXW)
    m1 = _clip(c, msg1, f1, MSG_MAXW)
    c.text(m1, c.width // 2, 13, font = f1, color = rail_color, align = "center")
    m2 = _clip(c, msg2, "picopixel", MSG_MAXW)
    c.text(m2, c.width // 2, 26, font = "picopixel", color = "gray", align = "center")

def draw_stats(c, d, demo, stat_idx):
    key, label, color = STATS[stat_idx]

    draw_frame(c, color)
    draw_header(c, d["name"])

    value = _stat_value(d, key)
    hf = _fit(c, value, HERO_FONTS, HERO_MAXW)
    value = _clip(c, value, hf, HERO_MAXW)
    c.text(value, c.width // 2, 9, font = hf, color = color, align = "center")

    label_text = label + (" DEMO" if demo else "")
    label_text = _clip(c, label_text, "picopixel", MSG_MAXW)
    c.text(label_text, c.width // 2, 26, font = "picopixel", color = "gray", align = "center")

def render_player(c, ctx, slot_key, stat_idx):
    name = ctx.inputs.get(slot_key, "").strip()
    if not name:
        draw_message(c, "midgray", "SLOT EMPTY", "ADD A NAME", "IN SETTINGS")
        return

    apikey = ctx.inputs.get("apikey", "")
    if not apikey:
        draw_stats(c, make_demo(name), demo = True, stat_idx = stat_idx)
        return

    d = fetch_stats(name, apikey)
    state = d["state"]
    if state == "ok":
        draw_stats(c, d, demo = False, stat_idx = stat_idx)
    elif state == "notfound":
        draw_message(c, "amber", name, "NOT FOUND", "CHECK SPELLING")
    elif state == "badkey":
        draw_message(c, "amber", name, "BAD KEY", "CHECK SETTINGS")
    elif state == "nostats":
        draw_message(c, "green", name, "NO MATCHES", "PLAY A GAME")
    else:
        draw_message(c, "amber", name, "OFFLINE", "RETRY SOON")

# Each page pairs two player slots; a page-scoped clock hands off between
# them every 5 minutes (5 stats x 60s each), so both players get equal time.
PAGE_SLOTS = [
    ["name1", "name2"],
    ["name3", "name4"],
    ["name5", "name6"],
    ["name7", "name8"],
    ["name9", "name10"],
]

def render_page(c, ctx, slots):
    total = len(slots) * len(STATS)
    frame = (ctx.now.unix // 60) % total
    slot_idx = frame // len(STATS)
    stat_idx = frame % len(STATS)
    render_player(c, ctx, slots[slot_idx], stat_idx)

def p1(c, ctx):
    render_page(c, ctx, PAGE_SLOTS[0])

def p2(c, ctx):
    render_page(c, ctx, PAGE_SLOTS[1])

def p3(c, ctx):
    render_page(c, ctx, PAGE_SLOTS[2])

def p4(c, ctx):
    render_page(c, ctx, PAGE_SLOTS[3])

def p5(c, ctx):
    render_page(c, ctx, PAGE_SLOTS[4])
