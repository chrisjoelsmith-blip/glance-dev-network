# Brightline Departures
#
# The next Brightline train out of (or into) one of its six Florida
# stations, from the same feed that drives the departure boards on the
# platforms: schedules.gobrightline.com/api/schedulefordisplay. Keyless
# JSON, one call, both directions in the answer.
#
# DESIGN. A platform board in Brightline's own colours: black ground,
# the yellow of the locomotive. The train IS the identity - a 44 x 14
# side profile of the Siemens Charger, yellow with the black windshield
# mask sweeping back over the cab windows, grey roof and frame, headlight
# lit, standing on a rail at the left of the panel with the direction in
# small type beneath. The hero is the next train's time in 10x16. Beside
# it, three quiet lines: where it goes, its track, its train number.
# Under the hero the status lives in a PILL, black type on the state
# colour, so the eye lands on it from across the room: ON TIME green,
# BOARDING / FINAL CALL / LEAVING / ARRIVING sky blue, DELAYED and N MIN
# LATE amber, CANCELED red, doors CLOSED grey - and the rail wears the
# same colour. Next to the pill: IN 12 MIN, counted from the live
# estimate when the board has one, so nobody does the arithmetic. Page
# two is the board: three rows, time / place / pill, with +N MORE in the
# chip row when the day has more. Everything lives inside x 10..181.
#
# Cadence: 300 s, the catalog's transit rate, with a matching ttl.

FEED = "https://schedules.gobrightline.com/api/schedulefordisplay"
UA = "glance-brightline-departures (glance-led.dev)"
TTL = 300

# --------------------------------------------------------------- palette
BL_YELLOW = "#FFD200"     # the nose, the chip
INK = "#F4F7FF"
DIM = "#6E7A94"
RAIL_C = "#4A4A4A"        # the track under the train
OK_C = "green"
WAIT_C = "skyblue"        # the boarding family
LATE_C = "amber"
BAD_C = "red"
GONE_C = "gray"
OFFLINE = "#3C4043"

STATIONS = {
    "MIAMI": "Miami",
    "AVENTURA": "Aventura",
    "FORT LAUDERDALE": "Fort Lauderdale",
    "BOCA RATON": "Boca Raton",
    "WEST PALM BEACH": "West Palm Beach",
    "ORLANDO": "Orlando",
}
# Feed codes -> names sized for the column beside the hero (max 49 px in
# 4x5, which is what is left when the hour has two digits).
SHORT = {"MIA": "MIAMI", "AVE": "AVENTURA", "FTL": "LAUDERDALE",
         "BOC": "BOCA RATON", "WPB": "PALM BEACH", "ORL": "ORLANDO"}
# Names for the chip row, next to the BRIGHTLINE chip, in 5x7 so the
# station you are tracking reads first (max 63 px; the widest are 59).
CHIP = {"MIAMI": "MIAMI", "AVENTURA": "AVENTURA", "FORT LAUDERDALE": "LAUDERDALE",
        "BOCA RATON": "BOCA RATON", "WEST PALM BEACH": "PALM BEACH", "ORLANDO": "ORLANDO"}

# ------------------------------------------------------------- pixel art
# The Siemens Charger in Brightline yellow, nose to the left, 44 x 14.
# Y body; K the swept-back windshield mask, tapering as it drops, that
# runs on as the black window band down the side, and the skirt band;
# G roof and frame; L the headlight; W the cab-door window.
TRAIN = """
..........GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
........GGYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYG
......GYYKKKKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYG
.....GYYKKKKKKKKKKKKKYYYKKKKKYYYKKKKKYYWWYYG
....GYYYKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKWWYYG
...GYYYYYKKKKKKKKKKKKYYYKKKKKYYYKKKKKYYWWYYG
..GYYYYYYYYKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYYG
.GYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYG
.GLLYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYG
GYLLYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYG
GKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKG
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
....KKKK.KKKK..............KKKK.KKKK........
....KKKK.KKKK..............KKKK.KKKK........
"""
TRAIN_LEGEND = {"Y": BL_YELLOW, "K": "#14161C", "G": "#8E96A3",
                "L": "#FFF6C8", "W": "#5FA8FF"}
TRAIN_W = 44

# ------------------------------------------------------------- text tools
def clip(c, text, font, maxw):
    t = str(text)
    if c.text_width(t, font) <= maxw:
        return t
    for k in range(len(t), 0, -1):
        if c.text_width(t[:k], font) <= maxw:
            return t[:k]
    return ""

def fit(c, text, fonts, maxw):
    t = str(text)
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(t, f) <= maxw:
            pick = f
            break
    return [pick, clip(c, t, pick, maxw)]

def tab(c, word, accent, x):
    w = c.badge(word, x, 0, color = "black", bg = accent, font = "4x5")
    return x + w + 1

def pill(c, word, color, x, y):
    """Status pill: black 4x5 type on the state colour, 7 px tall.
    Returns its width."""
    return c.badge(word, x, y, color = "black", bg = color, font = "4x5")

def pill_width(c, word):
    return c.text_width(word, "4x5") + 4

def rail(c, color):
    c.rect(0, 0, 1, 31, fill = color)

def message(c, head, sub, head_color = "amber"):
    hf = fit(c, head, ["5x7", "4x5"], 172)
    c.text(hf[1], c.width // 2, 11, font = hf[0], color = head_color, align = "center")
    sf = fit(c, sub, ["4x5", "picopixel"], 172)
    c.text(sf[1], c.width // 2, 23, font = sf[0], color = DIM, align = "center")

# ------------------------------------------------------------------ time
def num(s, fallback = -1):
    t = str(s).strip()
    if t == "":
        return fallback
    for ch in t.elems():
        if ch < "0" or ch > "9":
            return fallback
    return int(t)

def days_from_civil(y, m, d):
    yy = y - 1 if m <= 2 else y
    era = (yy if yy >= 0 else yy - 399) // 400
    yoe = yy - era * 400
    doy = (153 * (m + (-3 if m > 2 else 9)) + 2) // 5 + d - 1
    doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468

def weekday(z):
    """0 = Monday .. 6 = Sunday."""
    return (z + 3) % 7

def nth_sunday(y, m, n):
    first = days_from_civil(y, m, 1)
    return 1 + (6 - weekday(first)) % 7 + 7 * (n - 1)

def eastern_minutes(now):
    """Minutes since the epoch on Florida's wall clock. US DST runs from
    the second Sunday of March at 2:00 to the first Sunday of November
    at 2:00, so EDT (UTC-4) between and EST (UTC-5) outside."""
    utc_min = now.unix // 60
    y = now.year
    start = days_from_civil(y, 3, nth_sunday(y, 3, 2)) * 1440 + 7 * 60   # 2am EST = 07:00 UTC
    end = days_from_civil(y, 11, nth_sunday(y, 11, 1)) * 1440 + 6 * 60   # 2am EDT = 06:00 UTC
    off = 4 * 60 if (utc_min >= start and utc_min < end) else 5 * 60
    return utc_min - off

def parse_board_time(s):
    """'2026-09-14 6:17 PM' -> minutes since the epoch on the local clock;
    None for anything else, including the feed's 'undefined undefined'."""
    t = str(s).strip()
    if len(t) < 16 or t.find("undefined") >= 0:
        return None
    y, mo, d = num(t[0:4]), num(t[5:7]), num(t[8:10])
    if y < 2000 or mo < 1 or mo > 12 or d < 1 or d > 31:
        return None
    rest = t[11:].strip().split(" ")
    if len(rest) != 2:
        return None
    hm = rest[0].split(":")
    if len(hm) != 2:
        return None
    h, mi = num(hm[0]), num(hm[1])
    if h < 1 or h > 12 or mi < 0 or mi > 59:
        return None
    ap = rest[1].upper()
    if ap == "PM" and h != 12:
        h += 12
    if ap == "AM" and h == 12:
        h = 0
    return days_from_civil(y, mo, d) * 1440 + h * 60 + mi

def clock(mins):
    """6:17P, from minutes since the epoch."""
    tod = mins % 1440
    h, m = tod // 60, tod % 60
    ap = "P" if h >= 12 else "A"
    h12 = h % 12
    if h12 == 0:
        h12 = 12
    return str(h12) + ":" + fmt.pad(m) + ap

def until(mins, now_mins):
    d = mins - now_mins
    if d <= 0:
        return "NOW"
    if d < 60:
        return "IN " + str(d) + " MIN"
    return "IN " + str(d // 60) + "H " + fmt.pad(d % 60) + "M"

# ------------------------------------------------------------------ feed
def get(obj, key, fallback = None):
    if obj == None or type(obj) != "dict":
        return fallback
    v = obj.get(key, fallback)
    return fallback if v == None else v

def status_of(raw):
    """[pill word, colour, gone] from the board's status string. The
    platform board colours a bare number orange (minutes late), Cancel*
    red, On Time green and everything else blue; this keeps that contract
    and picks words that fit a pill (widest: 120 MIN LATE, 57 px)."""
    s = str(raw).strip()
    u = s.upper()
    n = num(s, -1)
    if n > 0:
        return [str(n) + " MIN LATE", LATE_C, False]
    if u == "ON TIME":
        return ["ON TIME", OK_C, False]
    if u.startswith("CANCEL"):
        return ["CANCELED", BAD_C, False]
    if u == "DELAYED":
        return ["DELAYED", LATE_C, False]
    if u == "FINAL CALL":
        return ["FINAL CALL", WAIT_C, False]
    if u == "BOARDING CLOSED":
        return ["CLOSED", GONE_C, False]
    if u.find("BOARDING") >= 0:
        return ["BOARDING", WAIT_C, False]
    if u == "DEPARTING SOON":
        return ["LEAVING", WAIT_C, False]
    if u == "ARRIVING SOON":
        return ["ARRIVING", WAIT_C, False]
    if u == "ARRIVED" or u == "DEPARTED":
        return [u, GONE_C, True]
    if u == "":
        return ["SCHEDULED", DIM, False]
    return [u[:10], WAIT_C, False]

def fetch_data(ctx):
    st = str(ctx.inputs.get("station", "FORT LAUDERDALE")).strip().upper()
    if st not in STATIONS:
        st = "FORT LAUDERDALE"
    board = str(ctx.inputs.get("board", "DEPARTURES")).strip().upper()
    if board != "ARRIVALS":
        board = "DEPARTURES"
    want = str(ctx.inputs.get("direction", "BOTH")).strip().upper()
    if want not in ["NORTHBOUND", "SOUTHBOUND"]:
        want = "BOTH"
    base = {"station": st, "board": board, "want": want}

    r = http.get(FEED, params = {"stationName": STATIONS[st],
                                 "DeparturesOrArrivals": "Departures" if board == "DEPARTURES" else "Arrivals"},
                 headers = {"User-Agent": UA}, ttl_seconds = TTL)
    if r["status_code"] == 0:
        return dict(base, ok = False, head = "BRIGHTLINE OFFLINE", sub = "RETRY IN 5 MIN")
    if r["status_code"] != 200:
        return dict(base, ok = False, head = "BOARD UNAVAILABLE", sub = "HTTP " + str(r["status_code"]))
    j = r["json"]
    if j == None or type(j) != "dict":
        return dict(base, ok = False, head = "BOARD UNAVAILABLE", sub = "BAD ANSWER FROM BRIGHTLINE")

    now_m = eastern_minutes(ctx.now)
    trains = []
    for key in ["scheduleNorth", "scheduleSouth"]:
        d = "NORTHBOUND" if key == "scheduleNorth" else "SOUTHBOUND"
        if want != "BOTH" and want != d:
            continue
        rows = get(j, key, [])
        if type(rows) != "list":
            continue
        for row in rows:
            t = parse_board_time(get(row, "time", ""))
            if t == None:
                continue
            live = parse_board_time(get(row, "liveTime", ""))
            stn = str(get(row, "stations", "")).upper().split("/")
            # Departures list the stops ahead (last = where it ends);
            # arrivals list the stops behind (first = where it came from).
            code = (stn[len(stn) - 1] if board == "DEPARTURES" else stn[0]).strip()
            stt = status_of(get(row, "status", ""))
            if stt[2]:
                continue            # already arrived / departed
            if t < now_m - 20 and stt[0] != "CANCELED":
                continue            # a stale row the board has not cleared
            trains.append({
                "t": t, "live": live if live != None else t, "when": clock(t),
                "place": SHORT.get(code, code), "dir": d,
                "status": stt[0], "color": stt[1],
                "track": str(get(row, "track", "-")).strip(),
                "train": str(get(row, "scheduleNumber", "")).strip(),
            })
    # Both directions merged in time order (insertion sort; n <= 12).
    for i in range(1, len(trains)):
        k = i
        for step in range(i):
            if k > 0 and trains[k]["t"] < trains[k - 1]["t"]:
                trains[k], trains[k - 1] = trains[k - 1], trains[k]
                k -= 1
    return dict(base, ok = True, trains = trains, now = now_m)

# ---------------------------------------------------------------- chrome
def chip_row(c, d, right):
    """BRIGHTLINE chip, the station, and a right-aligned word. The chip
    is 53 px, so the station gets 181 - right - 4 - 66 px; every CHIP
    name fits in 5x7 beside a 48 px DEPARTURES. The station is the one
    5x7 word in the row, in the chip's yellow, filling the chip's 7 px
    height (y 0..6) so it reads as the sign on the platform."""
    x = tab(c, "BRIGHTLINE", BL_YELLOW, 10)
    rw = c.text_width(right, "4x5")
    c.text(right, 181, 1, font = "4x5", color = DIM, align = "right")
    c.text(clip(c, CHIP[d["station"]], "5x7", 181 - rw - 4 - (x + 2)), x + 2, 0,
           font = "5x7", color = BL_YELLOW)

def train_art(c, x, y, word):
    """The locomotive on its rail, the direction word beneath."""
    c.sprite(TRAIN, x, y, legend = TRAIN_LEGEND)
    c.hline(x - 2, y + 14, TRAIN_W + 4, RAIL_C)
    c.text(clip(c, word, "picopixel", TRAIN_W + 4), x + TRAIN_W // 2, y + 17,
           font = "picopixel", color = DIM, align = "center")

def dir_word(d, train):
    if d["want"] != "BOTH":
        return d["want"]
    return train["dir"] if train != None else "NORTH + SOUTH"

def fail(c, d):
    c.fill("black")
    rail(c, OFFLINE)
    message(c, d["head"], d["sub"])

def empty(c, d):
    """Zero trains left is the answer, not an error: green rail, the
    train at rest, and a line that says when to look again."""
    c.fill("black")
    rail(c, OK_C)
    chip_row(c, d, d["board"])
    train_art(c, 12, 9, dir_word(d, None))
    # Text zone x 62..181, centred on 121; the sub line is 90 px so it
    # clears the direction word under the train (ends x 56) and x 181.
    what = "NO MORE " + ("DEPARTURES" if d["board"] == "DEPARTURES" else "ARRIVALS")
    c.text(clip(c, what, "5x7", 118), 121, 11, font = "5x7", color = OK_C, align = "center")
    c.text("BACK IN THE MORNING", 121, 22, font = "4x5", color = DIM, align = "center")

# ------------------------------------------------------------ page: next
def next_train(c, ctx):
    d = fetch_data(ctx)
    if not d["ok"]:
        fail(c, d)
        return
    if len(d["trains"]) == 0:
        empty(c, d)
        return
    t = d["trains"][0]
    c.fill("black")
    rail(c, t["color"])
    chip_row(c, d, d["board"])

    # Left zone x 10..55: the train on its rail, y 9..22, direction y 26.
    train_art(c, 12, 9, dir_word(d, t))

    # Hero: the time in 10x16 at x 60, y 8..23. "11:09P" is 63 px, so the
    # column beside it starts at x 128 at the latest, leaving 54 px - and
    # every SHORT name is 49 px or less.
    hx = 60
    c.text(t["when"], hx, 8, font = "10x16", color = INK)
    cx = hx + c.text_width(t["when"], "10x16") + 5
    cw = 181 - cx + 1
    c.text(clip(c, t["place"], "4x5", cw), cx, 8, font = "4x5", color = INK)
    trk = ("TRACK " + t["track"]) if (t["track"] != "" and t["track"] != "-") else "TRACK TBA"
    c.text(clip(c, trk, "4x5", cw), cx, 14, font = "4x5", color = DIM)
    c.text(clip(c, "TRAIN " + t["train"], "4x5", cw), cx, 20, font = "4x5", color = DIM)

    # Bottom band y 25..31: the status pill, then the countdown from the
    # live estimate. A canceled train points at the one after it instead.
    pw = pill(c, t["status"], t["color"], hx, 25)
    tx = hx + pw + 4
    if t["status"] == "CANCELED":
        line = ("NEXT " + d["trains"][1]["when"]) if len(d["trains"]) > 1 else "NO LATER TRAIN"
    else:
        line = until(t["live"], d["now"])
    c.text(clip(c, line, "4x5", 181 - tx + 1), tx, 26, font = "4x5", color = INK)

# ----------------------------------------------------------- page: board
def board(c, ctx):
    d = fetch_data(ctx)
    if not d["ok"]:
        fail(c, d)
        return
    if len(d["trains"]) == 0:
        empty(c, d)
        return
    c.fill("black")
    rail(c, d["trains"][0]["color"])
    shown = d["trains"][:3]
    more = len(d["trains"]) - len(shown)
    chip_row(c, d, ("+" + str(more) + " MORE") if more > 0 else d["board"])

    # Three rows on an 8 px pitch (7 px pill + 1 px gap) at y 8, 16, 24:
    # time, place, and the pill right-aligned at x 181. The pill is
    # measured first and the place is clipped into what is left.
    for i in range(len(shown)):
        t = shown[i]
        y = 8 + i * 8
        c.text(t["when"], 10, y + 1, font = "4x5", color = INK)
        pw = pill_width(c, t["status"])
        pill(c, t["status"], t["color"], 181 - pw + 1, y)
        px = 10 + 29 + 5            # "11:09P" is 29 px wide in 4x5
        c.text(clip(c, t["place"], "4x5", 181 - pw - 4 - px), px, y + 1,
               font = "4x5", color = INK if i == 0 else DIM)
