# Treasury Yields
#
# The daily par yield for one US Treasury maturity, straight from
# treasury.gov's own XML feed (keyless, one call per month of history,
# every maturity in one row). The dropdown picks which bond to follow -
# the 10 year is the default because it is the one people ask for - and a
# second page draws the whole curve so the chosen maturity has context.
#
# DESIGN. A bond certificate, not a stock ticker. Ground is black; the
# identity is an engraved Treasury facade in ivory (columns, pediment,
# steps) that says "TREASURY" without the word. The hero is the yield in
# 16x20 with a smaller percent sign hung on its baseline, the way a rate
# is printed on paper. White is the resting colour for the number; green
# and red are reserved for the day's move in basis points, and the rail
# wears that same state so the page never argues with itself. Thirty days
# of history sits at the right as a mint sparkline, dim, with only the
# newest point lit - the story is "where it has been", the number is "where
# it is". Page two is the curve: eleven bars, one per maturity, the chosen
# one lit in ivory, the rest a dim mint, with the shape of the curve
# (NORMAL / FLAT / INVERTED) named in the chip row because an inverted
# curve is the thing a bond watcher wants to know. Nothing draws to the
# edge on the scroll build: everything lives inside x 10..181.
#
# Cadence: treasury.gov posts once a business day (mid-afternoon ET), so
# refresh 3600 and ttl 3600 are in sync - hourly is the fastest that can
# ever show something new, and a wall panel does not need to poll a
# daily feed harder than that.

FEED = "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/pages/xml"

# ----------------------------------------------------------------- palette
INK = "#F4F7FF"       # the hero number
IVORY = "#E9DCB4"     # identity: the facade, labels, the chosen bar
PARCH = "#8C845F"     # dim ivory for secondary labels
MINT = "#5FCB8A"      # the sparkline / curve bars
MINT_DIM = "#1F5C38"  # sparkline track, unlit bars
MINT_WASH = "#0B2416" # area under the sparkline
RULE = "#2A2A2A"      # hairlines
UP = "green"
DOWN = "red"
FLAT = "gray"
OFFLINE = "#3C4043"
DIM = "#6E7A94"

# The maturities treasury.gov publishes, in curve order. Dropdown label ->
# [feed tag, short code]. The 1.5-, 2- and 4-month bills exist in the feed
# but are left off the curve page: eleven bars is what fits with a label
# under each, and nobody follows the 4-month.
TENORS = {
    "1 MONTH": ["BC_1MONTH", "1M"],
    "2 MONTH": ["BC_2MONTH", "2M"],
    "3 MONTH": ["BC_3MONTH", "3M"],
    "6 MONTH": ["BC_6MONTH", "6M"],
    "1 YEAR": ["BC_1YEAR", "1Y"],
    "2 YEAR": ["BC_2YEAR", "2Y"],
    "3 YEAR": ["BC_3YEAR", "3Y"],
    "5 YEAR": ["BC_5YEAR", "5Y"],
    "7 YEAR": ["BC_7YEAR", "7Y"],
    "10 YEAR": ["BC_10YEAR", "10Y"],
    "20 YEAR": ["BC_20YEAR", "20Y"],
    "30 YEAR": ["BC_30YEAR", "30Y"],
}
CURVE = ["1 MONTH", "3 MONTH", "6 MONTH", "1 YEAR", "2 YEAR", "3 YEAR",
         "5 YEAR", "7 YEAR", "10 YEAR", "20 YEAR", "30 YEAR"]

MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

# --------------------------------------------------------------- pixel art
# The Treasury facade. Legend: A ivory stone, B the dark portico between
# the columns, C the lit doorway. 26 wide x 22 tall on the scroll build.
FACADE = """
............AA............
..........AAAAAA..........
........AAAAAAAAAA........
......AAAAAAAAAAAAAA......
....AAAAAAAAAAAAAAAAAA....
..AAAAAAAAAAAAAAAAAAAAAA..
.AAAAAAAAAAAAAAAAAAAAAAAA.
.AAAAAAAAAAAAAAAAAAAAAAAA.
..AABBAABBAABBAABBAABBAA..
..AABBAABBAABBAABBAABBAA..
..AABBAABBAABBAABBAABBAA..
..AABBAABBAABBAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
..AABBAABBAACCAABBAABBAA..
.AAAAAAAAAAAAAAAAAAAAAAAA.
.AAAAAAAAAAAAAAAAAAAAAAAA.
AAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAA
"""

# The same building at 12 x 9 for the 64 panel's header.
FACADE_SM = """
.....AA.....
...AAAAAA...
.AAAAAAAAAA.
AAAAAAAAAAAA
.ABABACABAB.
.ABABACABAB.
.ABABACABAB.
.AAAAAAAAAA.
AAAAAAAAAAAA
"""

FACADE_LEGEND = {"A": IVORY, "B": "#3A3620", "C": "#FFD36A"}

# ------------------------------------------------------------- text tools
def clip(c, text, font, maxw):
    """Longest prefix of `text` that fits `maxw`. Nothing in the API clips,
    so every string near an edge comes through here."""
    t = str(text)
    if c.text_width(t, font) <= maxw:
        return t
    for k in range(len(t), 0, -1):
        if c.text_width(t[:k], font) <= maxw:
            return t[:k]
    return ""

def fit(c, text, fonts, maxw):
    """[font, clipped text] for the largest listed font that fits."""
    t = str(text)
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(t, f) <= maxw:
            pick = f
            break
    return [pick, clip(c, t, pick, maxw)]

def tab(c, word, accent, x):
    """The page chip: black text on the state colour."""
    w = c.badge(word, x, 0, color = "black", bg = accent, font = "4x5")
    return x + w + 1

def rail(c, color):
    c.rect(0, 0, 1, 31, fill = color)

def message(c, head, sub):
    """The one screen every failure state shares. `head` and `sub` are
    [wide, narrow] pairs: the 64 panel gets its own shorter copy rather
    than a clipped version of the long one ("TREASURY O" is not a message).
    On the narrow panel the facade owns x 0..11 of the top rows, so the
    text is centred in what is left."""
    wide = c.width >= 128
    h = head[0] if wide else head[1]
    u = sub[0] if wide else sub[1]
    maxw = c.width - 4
    hf = fit(c, h, ["5x7", "4x5"], maxw)
    c.text(hf[1], c.width // 2, 11, font = hf[0], color = "amber", align = "center")
    sf = fit(c, u, ["4x5", "picopixel"], maxw)
    c.text(sf[1], c.width // 2, 23, font = sf[0], color = DIM, align = "center")

# ------------------------------------------------------------- number tools
def num(s, fallback = -1):
    t = str(s).strip()
    if t == "":
        return fallback
    for ch in t.elems():
        if ch < "0" or ch > "9":
            return fallback
    return int(t)

def hundredths(s):
    """A yield string like 4.79 becomes 479 (basis points). Exact integer
    arithmetic; a value the feed leaves blank (a holiday row, a retired
    bill) comes back None."""
    t = str(s).strip()
    if t == "" or t == "N/A":
        return None
    parts = t.split(".")
    whole = num(parts[0], -1)
    if whole < 0:
        return None
    frac = 0
    if len(parts) == 2:
        f = (parts[1] + "00")[:2]
        frac = num(f, -1)
        if frac < 0:
            return None
    elif len(parts) > 2:
        return None
    return whole * 100 + frac

def pct_text(bp):
    """479 becomes 4.79."""
    return str(bp // 100) + "." + fmt.pad(bp % 100)

def bps_text(d):
    """Day-over-day move: +3 BPS, -12 BPS, UNCH."""
    if d == 0:
        return "UNCH"
    return ("+" if d > 0 else "-") + str(math.abs(d)) + " BPS"

def bps_short(d):
    if d == 0:
        return "UNCH"
    return ("+" if d > 0 else "-") + str(math.abs(d)) + "BP"

# ------------------------------------------------------------------- feed
def month_url_params(y, m):
    return {"data": "daily_treasury_yield_curve",
            "field_tdr_date_value_month": str(y) + fmt.pad(m)}

def between(s, open_tag, close_tag, start):
    """Text between two tags after `start`; [text, end] or None."""
    i = s.find(open_tag, start)
    if i < 0:
        return None
    i = s.find(">", i)
    if i < 0:
        return None
    j = s.find(close_tag, i)
    if j < 0:
        return None
    return [s[i + 1:j], j]

def parse_month(body):
    """The feed is Atom XML. Each <entry> carries one business day with a
    <d:NEW_DATE> and one <d:BC_*> per maturity. Cut it up with find();
    the sandbox has no XML parser and the shape is fixed."""
    rows = []
    pos = 0
    for i in range(40):
        e = body.find("<entry>", pos)
        if e < 0:
            break
        end = body.find("</entry>", e)
        if end < 0:
            break
        chunk = body[e:end]
        pos = end + 8
        d = between(chunk, "<d:NEW_DATE", "</d:NEW_DATE>", 0)
        if d == None:
            continue
        row = {"date": d[0][:10]}
        for label in TENORS:
            tag = TENORS[label][0]
            v = between(chunk, "<d:" + tag + " ", "</d:" + tag + ">", 0)
            if v == None:
                v = between(chunk, "<d:" + tag + ">", "</d:" + tag + ">", 0)
            row[tag] = hundredths(v[0]) if v != None else None
        rows.append(row)
    return rows

def fetch_rows(ctx):
    """This month plus last month, oldest first, so a sparkline on the 2nd
    of the month still has thirty points behind it. Two calls, both cached
    an hour to match refresh."""
    y, m = ctx.now.year, ctx.now.month
    py, pm = (y - 1, 12) if m == 1 else (y, m - 1)
    rows = []
    status = 0
    for ym in [[py, pm], [y, m]]:
        r = http.get(FEED, params = month_url_params(ym[0], ym[1]),
                     headers = {"User-Agent": "glance-treasury-yields"},
                     ttl_seconds = 3600)
        if r["status_code"] == 200:
            status = 200
            rows = rows + parse_month(r["body"])
        elif status == 0:
            status = r["status_code"]
    return [status, rows]

def fetch_data(ctx):
    """Everything the pages need, or {"ok": False, ...} with copy to draw."""
    label = str(ctx.inputs.get("tenor", "10 YEAR")).strip().upper()
    if label not in TENORS:
        label = "10 YEAR"
    tag = TENORS[label][0]
    code = TENORS[label][1]
    res = fetch_rows(ctx)
    status, rows = res[0], res[1]
    if status != 200:
        if status == 0:
            return {"ok": False, "head": ["TREASURY OFFLINE", "OFFLINE"],
                    "sub": ["RETRY NEXT HOUR", "RETRY IN 1H"]}
        return {"ok": False, "head": ["TREASURY ERROR", "FEED ERROR"],
                "sub": ["HTTP " + str(status), "HTTP " + str(status)]}
    # Only rows where the chosen maturity has a value: a bill that was
    # not issued that day leaves the cell blank.
    series = []
    dates = []
    for row in rows:
        if row.get(tag, None) != None:
            series.append(row[tag])
            dates.append(row["date"])
    if len(series) == 0:
        return {"ok": False, "head": ["NO " + code + " YIELD YET", "NO " + code + " YET"],
                "sub": ["TRY ANOTHER BOND", "PICK ANOTHER"]}
    last = rows[len(rows) - 1]
    today = series[len(series) - 1]
    prev = series[len(series) - 2] if len(series) >= 2 else today
    d = dates[len(dates) - 1]
    when = MONTHS[num(d[5:7], 1) - 1] + " " + str(num(d[8:10], 1))
    curve = []
    for lab in CURVE:
        curve.append([TENORS[lab][1], last.get(TENORS[lab][0], None), lab == label])
    return {
        "ok": True, "label": label, "code": code,
        "yield": today, "delta": today - prev, "when": when,
        "series": series[-30:], "curve": curve,
        "two": last.get("BC_2YEAR", None), "ten": last.get("BC_10YEAR", None),
    }

def state_color(delta):
    return UP if delta > 0 else (DOWN if delta < 0 else FLAT)

def curve_shape(two, ten):
    """[word, colour] from the 2s/10s spread, the inversion everyone
    watches. Banded in one place so the word and the colour never disagree."""
    if two == None or ten == None:
        return ["CURVE", IVORY]
    spread = ten - two
    if spread < 0:
        return ["INVERTED", DOWN]
    if spread < 10:
        return ["FLAT", "amber"]
    return ["NORMAL", UP]

# -------------------------------------------------------------- page: yield
def yield_page(c, ctx):
    c.fill("black")
    d = fetch_data(ctx)
    if not d["ok"]:
        if c.width >= 128:
            rail(c, OFFLINE)
            c.sprite(FACADE_SM, 12, 2, legend = FACADE_LEGEND)
        else:
            c.sprite(FACADE_SM, 0, 0, legend = FACADE_LEGEND)
        message(c, d["head"], d["sub"])
        return

    col = state_color(d["delta"])
    if c.width >= 128:
        yield_wide(c, d, col)
    else:
        yield_narrow(c, d, col)

def yield_wide(c, d, col):
    # Rail in the day's state colour; facade at x 10..35, y 5..26.
    rail(c, col)
    c.sprite(FACADE, 10, 5, legend = FACADE_LEGEND)

    # Eyebrow: "10 YEAR TREASURY" is 73 px in 4x5, so it fits the 82 px
    # between the facade (ends x 35) and the right zone (starts x 124).
    lx = 40
    c.text(clip(c, d["label"] + " TREASURY", "4x5", 82), lx, 3, font = "4x5",
           color = IVORY)

    # Hero: "4.79" is 67 px in 16x20 (x 40..106); the percent sign hangs on
    # the baseline in 6x8 at x 109, well clear of the right zone at 124.
    # A 2-digit yield ("12.50", 84 px) would reach x 123 - it drops to
    # 10x16 through fit() rather than colliding.
    v = pct_text(d["yield"])
    hf = fit(c, v, ["16x20", "10x16"], 68)
    c.text(hf[1], lx, 10, font = hf[0], color = INK)
    vw = c.text_width(hf[1], hf[0])
    vh = 20 if hf[0] == "16x20" else 16
    c.text("%", lx + vw + 2, 10 + vh - 8, font = "6x8", color = PARCH)

    # Right zone x 124..181 (58 px). Row 1: the day's move, right-aligned,
    # with the arrow to its left. "-12 BPS" is 30 px in 4x5.
    rx0, rx1 = 124, 181
    mv = bps_text(d["delta"])
    mw = c.text_width(mv, "4x5")
    c.text(mv, rx1, 3, font = "4x5", color = col, align = "right")
    c.trend_arrow(rx1 - mw - 7, 3, d["delta"], col)

    # Row 2: thirty days of the chosen yield, y 10..24, mint on a wash,
    # the newest point lit ivory. A hairline underlines it at y 25.
    sx, sy, sw, sh = rx0, 10, rx1 - rx0 + 1, 15
    if len(d["series"]) >= 2:
        c.sparkline(d["series"], sx, sy, sw, sh, color = MINT, fill = MINT_WASH)
    else:
        c.hline(sx, sy + sh // 2, sw, MINT_DIM)
    c.hline(sx, sy + sh, sw, RULE)
    # Light the last point: same maths the helper uses for its end pixel.
    lo, hi = min(d["series"]), max(d["series"])
    if hi > lo:
        ny = sy + sh - 1 - ((d["yield"] - lo) * (sh - 1) + (hi - lo) // 2) // (hi - lo)
    else:
        ny = sy + sh // 2
    c.rect(sx + sw - 3, ny - 1, sx + sw - 1, ny + 1, fill = IVORY)

    # Row 3: what the chart is, and when the number is from.
    c.text("30 DAY", rx0, 27, font = "4x5", color = PARCH)
    c.text(clip(c, d["when"], "4x5", 30), rx1, 27, font = "4x5", color = PARCH,
           align = "right")

def yield_narrow(c, d, col):
    # Header y 0..8: small facade at x 0, the maturity code beside it, the
    # day's move right-aligned. "-12BP" is 22 px; "30Y" 14 px; facade 12 px.
    c.sprite(FACADE_SM, 0, 0, legend = FACADE_LEGEND)
    mv = bps_short(d["delta"])
    mw = c.text_width(mv, "4x5")
    c.text(mv, 63, 2, font = "4x5", color = col, align = "right")
    c.trend_arrow(63 - mw - 6, 2, d["delta"], col)
    c.text(clip(c, d["code"], "4x5", 63 - mw - 8 - 15), 14, 2, font = "4x5",
           color = IVORY)
    c.hline(0, 9, 64, RULE)

    # Hero y 11..26: "4.96" is 43 px in 10x16 at x 1..43; "%" in 5x7 on the
    # baseline at x 46..50.
    v = pct_text(d["yield"])
    hf = fit(c, v, ["10x16", "6x8"], 43)
    c.text(hf[1], 1, 11, font = hf[0], color = INK)
    vw = c.text_width(hf[1], hf[0])
    vh = 16 if hf[0] == "10x16" else 8
    c.text("%", 1 + vw + 2, 11 + vh - 7, font = "5x7", color = PARCH)

    # Footer y 28..31: thirty days as a four-row sparkline, x 0..50, the
    # newest point lit; "30D" names it at x 52..63 (picopixel, 11 px), one
    # column clear of the percent sign above.
    sw = 51
    if len(d["series"]) >= 2:
        c.sparkline(d["series"], 0, 28, sw, 4, color = MINT)
        lo, hi = min(d["series"]), max(d["series"])
        ny = 31 - (((d["yield"] - lo) * 3 + (hi - lo) // 2) // (hi - lo) if hi > lo else 1)
        c.rect(sw - 2, ny, sw - 1, ny, fill = IVORY)
    else:
        c.hline(0, 30, sw, MINT_DIM)
    c.text("30D", 63, 27, font = "picopixel", color = PARCH, align = "right")

# -------------------------------------------------------------- page: curve
def curve_page(c, ctx):
    c.fill("black")
    d = fetch_data(ctx)
    if not d["ok"]:
        if c.width >= 128:
            rail(c, OFFLINE)
            c.sprite(FACADE_SM, 12, 2, legend = FACADE_LEGEND)
        else:
            c.sprite(FACADE_SM, 0, 0, legend = FACADE_LEGEND)
        message(c, d["head"], d["sub"])
        return
    shape = curve_shape(d["two"], d["ten"])
    if c.width >= 128:
        curve_wide(c, d, shape)
    else:
        curve_narrow(c, d, shape)

def bar_heights(curve, hmax):
    """Bar heights scaled to the curve's own range, floor 2 so a real
    value never vanishes; None (no value that day) stays 0."""
    vals = [p[1] for p in curve if p[1] != None]
    if len(vals) == 0:
        return [0 for p in curve]
    lo, hi = min(vals), max(vals)
    out = []
    for p in curve:
        if p[1] == None:
            out.append(0)
        elif hi == lo:
            out.append(hmax // 2)
        else:
            out.append(2 + ((p[1] - lo) * (hmax - 2) + (hi - lo) // 2) // (hi - lo))
    return out

def curve_wide(c, d, shape):
    rail(c, shape[1])
    x = tab(c, "CURVE", shape[1], 10)
    # Chip row: the shape word in its colour, then the chosen bond and its
    # yield right-aligned in ivory. "INVERTED" 37 px; "10Y 4.79%" 37 px.
    c.text(shape[0], x + 2, 1, font = "4x5", color = shape[1])
    sel = d["code"] + " " + pct_text(d["yield"]) + "%"
    c.text(clip(c, sel, "4x5", 60), 181, 1, font = "4x5", color = IVORY,
           align = "right")

    # Eleven bars, 14 wide with a 1 px gap, on a 15 px pitch: 165 px from
    # x 12 to 176, inside the safe zone. Labels sit under their bar at
    # y 26 in picopixel ("30Y" is 11 px, leaving 4 px between neighbours;
    # in 4x5 it is 14 px and "10Y20Y30Y" read as one word). Bars grow up
    # from y 24 into y 9.
    pitch, bw, x0 = 15, 14, 12
    top, base = 9, 24
    hs = bar_heights(d["curve"], base - top + 1)
    for i in range(len(d["curve"])):
        p = d["curve"][i]
        bx = x0 + i * pitch
        h = hs[i]
        if h > 0:
            c.rect(bx, base - h + 1, bx + bw - 1, base, fill = IVORY if p[2] else MINT_DIM)
            if not p[2]:
                c.hline(bx, base - h + 1, bw, MINT)
        c.text(p[0], bx + bw // 2, 27, font = "picopixel",
               color = IVORY if p[2] else PARCH, align = "center")
    c.hline(x0, base + 1, len(d["curve"]) * pitch - 1, RULE)

def curve_narrow(c, d, shape):
    # Header: "CURVE" 24 px left, the shape word right ("INVERTED" 37 px):
    # 24 + 37 = 61 of 64, so neither can be widened.
    c.text("CURVE", 0, 1, font = "4x5", color = IVORY)
    c.text(shape[0], 63, 1, font = "4x5", color = shape[1], align = "right")
    c.hline(0, 7, 64, RULE)

    # Eleven bars on a 4 px pitch (3 + 1 gap): the last bar ends at x 42,
    # which leaves exactly the 20 px that "4.96%" needs in 4x5 for the
    # column at x 44..63.
    pitch, bw, x0 = 4, 3, 0
    top, base = 9, 25
    hs = bar_heights(d["curve"], base - top + 1)
    for i in range(len(d["curve"])):
        p = d["curve"][i]
        bx = x0 + i * pitch
        h = hs[i]
        if h > 0:
            c.rect(bx, base - h + 1, bx + bw - 1, base, fill = IVORY if p[2] else MINT_DIM)
            if not p[2]:
                c.hline(bx, base - h + 1, bw, MINT)
    c.hline(x0, base + 1, 43, RULE)
    # Two anchor labels in picopixel under the first and last bar; every
    # bar labelled would collide, and the lit bar plus the column say
    # which one is being followed.
    c.text("1M", x0, 27, font = "picopixel", color = PARCH)
    c.text("30Y", 42, 27, font = "picopixel", color = PARCH, align = "right")

    # Right column x 44..63: code, yield, and the day's move, stacked with
    # a 2 px gap. "-12BP" is 17 px in picopixel.
    c.text(clip(c, d["code"], "4x5", 20), 63, 9, font = "4x5", color = IVORY,
           align = "right")
    c.text(clip(c, pct_text(d["yield"]) + "%", "4x5", 20), 63, 16, font = "4x5",
           color = INK, align = "right")
    c.text(clip(c, bps_short(d["delta"]), "picopixel", 20), 63, 24,
           font = "picopixel", color = state_color(d["delta"]), align = "right")
