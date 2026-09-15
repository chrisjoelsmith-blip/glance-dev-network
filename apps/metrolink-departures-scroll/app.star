# Metrolink Departures
#
# The next Metrolink train at your Southern California station, live from
# Metrolink's own train tracker: rtt.metrolinktrains.com/StationScheduleList
# .json (every station, every train in the next few hours, scheduled and
# estimated times, track, status) and trainlist.json (every train running
# now, with its delay status). Keyless JSON, one call per page.
#
# DESIGN. A station departure board, in the tracker's own language. The
# identity is a 38 x 11 side profile of Metrolink's F125 locomotive - silver
# cab, black windshield, navy body and the light-blue swoosh - on a rail at
# the left of the panel, with the departure time and train number under it.
# The hero is a split-flap countdown: each digit on its own dark tile with
# the split running through it, MIN under the tiles, NOW when the train is
# due, and the clock itself once a train is 100 minutes or more away (a
# three-tile countdown would crowd out the destination). Beside it: the
# line as a pill in Metrolink's own line colour, where the train is going,
# and a status pill - ON TIME green, N MIN LATE amber, extended delays and
# cancellations red - with the rail wearing that same state colour. Page two
# is the board: the next three trains as rows, each opened by a bar in its
# line colour, with a short status pill. Page three is the whole system at
# a glance: every Metrolink line, how many of its trains are running late
# right now, the line you follow drawn in its own colour. Everything sits
# inside x 10..181.
#
# Line colours are Metrolink's GTFS route_color values, lifted where the
# official shade is too dark to read on an LED panel (SB A32136 -> E0314F,
# RIV 682E86 -> A15CD6, IEOC E92076 -> F0368A, 91/PV 0071CE -> 2F8FFF).
# Arrow and the Amtrak trains that share the tracks are not in that feed,
# so they get a teal and a soft Amtrak blue of their own.
#
# Cadence: the tracker updates every 60 seconds and the countdown is only
# as good as its last fetch, so refresh 60 and ttl 60 are in sync. The
# response is cached by URL, so a render host fetches it once a minute no
# matter how many panels show it.

FEED = "https://rtt.metrolinktrains.com/StationScheduleList.json"
TRAINS = "https://rtt.metrolinktrains.com/trainlist.json"
HEADERS = {"User-Agent": "glance-metrolink-departures (glance-led.dev)"}
TTL = 60

# ----------------------------------------------------------------- palette
INK = "#F4F7FF"
DIM = "#6E7A94"
TILE = "#1A1F2B"
RAIL_C = "#3A3F4A"
OFFLINE = "#3C4043"
BRAND = "#1B7FD6"      # Metrolink blue, the chip
C_OK = "#2FE06F"
C_LATE = "#FFBF00"
C_BAD = "#FF3B3B"

# code -> [pill word, colour]
LINES = {
    "AV": ["AV LINE", "#00C24A"],
    "VC": ["VC LINE", "#FFB81D"],
    "SB": ["SB LINE", "#E0314F"],
    "RIV": ["RIV LINE", "#A15CD6"],
    "OC": ["OC LINE", "#FF8400"],
    "IEOC": ["IEOC LINE", "#F0368A"],
    "91PV": ["91/PV LINE", "#2F8FFF"],
    "ARROW": ["ARROW", "#00B5B8"],
    "SURF": ["SURFLINER", "#7FA6D9"],
    "STAR": ["STARLIGHT", "#7FA6D9"],
    "OTHER": ["TRAIN", "#B0BCCB"],
}
LINE_ORDER = ["AV", "VC", "SB", "RIV", "OC", "IEOC", "91PV", "ARROW"]

# The tracker's RouteCode, letters and digits only, -> line code.
ROUTE = {"AVLINE": "AV", "VCLINE": "VC", "SBLINE": "SB", "RVSLINE": "RIV", "RIVLINE": "RIV",
         "OCLINE": "OC", "IEOCLINE": "IEOC", "91PVLINE": "91PV", "ARROW": "ARROW",
         "PACSURF": "SURF", "CSTSTRLT": "STAR"}

# Dropdown label -> line filter.
LINE_INPUT = {"ALL LINES": "ALL", "ANTELOPE VALLEY LINE": "AV", "VENTURA COUNTY LINE": "VC",
              "SAN BERNARDINO LINE": "SB", "RIVERSIDE LINE": "RIV", "ORANGE COUNTY LINE": "OC",
              "INLAND EMPIRE-ORANGE COUNTY LINE": "IEOC", "91/PERRIS VALLEY LINE": "91PV",
              "ARROW": "ARROW", "AMTRAK": "AMTRAK"}

# Dropdown label -> [tracker PlatformName with only letters and digits,
# name for the chip row]. The tracker is a rolling window, so a station
# with no train in the next few hours is simply absent; matching on the
# normalised name keeps that an empty board rather than a broken one.
# Chip names are 69 px or less in 4x5, what is left beside "DEPARTURES".
STATIONS = {
    "ANAHEIM - ARTIC": ["ARTIC", "ANAHEIM ARTIC"],
    "ANAHEIM CANYON": ["ANAHEIMCANYON", "ANAHEIM CANYON"],
    "BALDWIN PARK": ["BALDWINPARK", "BALDWIN PARK"],
    "BUENA PARK": ["BUENAPARK", "BUENA PARK"],
    "BURBANK - DOWNTOWN": ["DOWNTOWNBURBANK", "BURBANK"],
    "BURBANK AIRPORT - NORTH": ["BURBANKAIRPORTNORTH", "BURBANK ARPT N"],
    "BURBANK AIRPORT - SOUTH": ["BURBANKAIRPORTSOUTH", "BURBANK ARPT S"],
    "CAL STATE LA": ["CALSTATE", "CAL STATE LA"],
    "CAMARILLO": ["CAMARILLO", "CAMARILLO"],
    "CHATSWORTH": ["CHATSWORTH", "CHATSWORTH"],
    "CLAREMONT": ["CLAREMONT", "CLAREMONT"],
    "COMMERCE": ["COMMERCE", "COMMERCE"],
    "CORONA - NORTH MAIN": ["MAINCORONANORTH", "CORONA N MAIN"],
    "CORONA - WEST": ["CORONAWEST", "CORONA WEST"],
    "COVINA": ["COVINA", "COVINA"],
    "EL MONTE": ["ELMONTE", "EL MONTE"],
    "FONTANA": ["FONTANA", "FONTANA"],
    "FULLERTON": ["FULLERTON", "FULLERTON"],
    "GLENDALE": ["GLENDALE", "GLENDALE"],
    "INDUSTRY": ["INDUSTRY", "INDUSTRY"],
    "IRVINE": ["IRVINE", "IRVINE"],
    "JURUPA VALLEY / PEDLEY": ["PEDLEY", "PEDLEY"],
    "L.A. UNION STATION": ["LAUS", "UNION STATION"],
    "LAGUNA NIGUEL / MISSION VIEJO": ["LAGUNANIGUELMISSIONVIEJO", "LAGUNA NIGUEL"],
    "LANCASTER": ["LANCASTER", "LANCASTER"],
    "MONTCLAIR": ["MONTCLAIR", "MONTCLAIR"],
    "MONTEBELLO / COMMERCE": ["MONTEBELLO", "MONTEBELLO"],
    "MOORPARK": ["MOORPARK", "MOORPARK"],
    "MORENO VALLEY / MARCH FIELD": ["MORENOVALLEYMARCHFIELD", "MORENO VALLEY"],
    "NEWHALL": ["NEWHALL", "NEWHALL"],
    "NORTHRIDGE": ["NORTHRIDGE", "NORTHRIDGE"],
    "NORWALK / SANTA FE SPRINGS": ["NORWALKSANTAFESPRINGS", "NORWALK"],
    "OCEANSIDE": ["OCEANSIDE", "OCEANSIDE"],
    "ONTARIO - EAST": ["ONTARIOEAST", "ONTARIO EAST"],
    "ORANGE": ["ORANGE", "ORANGE"],
    "OXNARD": ["OXNARD", "OXNARD"],
    "PALMDALE": ["PALMDALE", "PALMDALE"],
    "PERRIS - DOWNTOWN": ["PERRISDOWNTOWN", "PERRIS"],
    "PERRIS - SOUTH": ["PERRISSOUTH", "SOUTH PERRIS"],
    "POMONA - DOWNTOWN": ["POMONADOWNTOWN", "POMONA"],
    "POMONA - NORTH": ["POMONANORTH", "POMONA NORTH"],
    "RANCHO CUCAMONGA": ["RANCHOCUCAMONGA", "R. CUCAMONGA"],
    "REDLANDS - DOWNTOWN": ["REDLANDSDOWNTOWNARROW", "REDLANDS"],
    "REDLANDS - ESRI": ["REDLANDSESRI", "REDLANDS ESRI"],
    "REDLANDS - UNIVERSITY": ["REDLANDSUNIVERSITY", "REDLANDS UNIV"],
    "RIALTO": ["RIALTO", "RIALTO"],
    "RIVERSIDE - DOWNTOWN": ["RIVERSIDEDOWNTOWN", "RIVERSIDE"],
    "RIVERSIDE - HUNTER PARK / UCR": ["RIVERSIDEHUNTERPARK", "HUNTER PARK"],
    "RIVERSIDE - LA SIERRA": ["RIVERSIDELASIERRA", "LA SIERRA"],
    "SAN BERNARDINO - DOWNTOWN": ["SANBERNARDINOTRAN", "SAN BERNARDINO"],
    "SAN BERNARDINO - TIPPECANOE": ["SANBERNARDINOTIPPECANOE", "TIPPECANOE"],
    "SAN BERNARDINO DEPOT": ["SANBERNARDINO", "SB DEPOT"],
    "SAN CLEMENTE": ["SANCLEMENTE", "SAN CLEMENTE"],
    "SAN CLEMENTE PIER": ["SANCLEMENTEPIER", "CLEMENTE PIER"],
    "SAN JUAN CAPISTRANO": ["SANJUANCAPISTRANO", "SJ CAPISTRANO"],
    "SANTA ANA": ["SANTAANA", "SANTA ANA"],
    "SANTA CLARITA": ["SANTACLARITA", "SANTA CLARITA"],
    "SIMI VALLEY": ["SIMIVALLEY", "SIMI VALLEY"],
    "SUN VALLEY": ["SUNVALLEY", "SUN VALLEY"],
    "SYLMAR / SAN FERNANDO": ["SYLMARSANFERNANDO", "SYLMAR"],
    "TUSTIN": ["TUSTIN", "TUSTIN"],
    "UPLAND": ["UPLAND", "UPLAND"],
    "VAN NUYS": ["VANNUYS", "VAN NUYS"],
    "VENTURA - EAST": ["VENTURAEAST", "EAST VENTURA"],
    "VIA PRINCESSA": ["VIAPRINCESSA", "VIA PRINCESSA"],
    "VINCENT GRADE / ACTON": ["VINCENTGRADEACTON", "ACTON"],
    "VISTA CANYON": ["VISTACANYON", "VISTA CANYON"],
}

# The tracker's TrainDestination, normalised -> [short name, station key].
# The key lets the departures board drop a train that ends at your station.
DEST = {
    "LAUNIONSTATION": ["UNION STATION", "LAUS"],
    "SANBERNARDINODOWNTOWN": ["SAN BERNARDINO", "SANBERNARDINOTRAN"],
    "DOWNTOWNRIVERSIDE": ["RIVERSIDE", "RIVERSIDEDOWNTOWN"],
    "LAGUNANIGUELMISSIONVIEJO": ["LAGUNA NIGUEL", "LAGUNANIGUELMISSIONVIEJO"],
    "EASTVENTURA": ["EAST VENTURA", "VENTURAEAST"],
    "SOUTHPERRIS": ["SOUTH PERRIS", "PERRISSOUTH"],
    "REDLANDSUNIVERSITY": ["REDLANDS", "REDLANDSUNIVERSITY"],
    "SANLUISOBISPO": ["SAN LUIS OBISPO", ""],
}

# --------------------------------------------------------------- pixel art
# Metrolink's F125, nose to the left. S silver cab and roof, K windshield
# and wheels, L the light-blue swoosh, N navy body, H headlight, G frame.
LOCO = """
........SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
......SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
....SSKKKKKSSSSSSSSSSSSSSSSSSSSSSSSSSS
...SSKKKKKKSSSSSSSSSSSSSSSSSSSSSSSSSSS
..SSSSSSSSSSSSSSSSSSLLLLLLLLLLLLLLLLLL
.SSSSSSSSSSLLLLLLLLLLLLLLLLNNNNNNNNNNN
.HNNNNNLLLLLLLLLLLLNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
...KKKK.KKKK..............KKKK.KKKK...
"""
LOCO_LEGEND = {"S": "#D9DEE6", "K": "#101418", "L": "#5CC8F0", "N": "#1F5BC4",
               "H": "#FFF6C8", "G": "#6B7280"}

# ------------------------------------------------------------- text tools
ALNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
KEEP = ALNUM + " .-/&"

def key_of(s):
    out = ""
    for ch in str(s).upper().elems():
        if ALNUM.find(ch) >= 0:
            out += ch
    return out

def clean(s):
    out = ""
    last_space = True
    for ch in str(s).upper().elems():
        if KEEP.find(ch) < 0:
            continue
        if ch == " ":
            if last_space:
                continue
            last_space = True
        else:
            last_space = False
        out += ch
    return out.strip()

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

HEXD = "0123456789abcdef"

def ink_for(fill):
    """Black type on a bright pill, white on a dark one (brightness 150)."""
    h = str(fill).lower()
    if not h.startswith("#") or len(h) != 7:
        return "black"
    v = [HEXD.find(h[i]) * 16 + HEXD.find(h[i + 1]) for i in [1, 3, 5]]
    return "black" if (299 * v[0] + 587 * v[1] + 114 * v[2]) // 1000 >= 150 else "white"

def pill(c, word, fill, x, y):
    return c.badge(word, x, y, color = ink_for(fill), bg = fill, font = "4x5")

def pill_w(c, word):
    return c.text_width(word, "4x5") + 4

def rail(c, color):
    c.rect(0, 0, 1, 31, fill = color)

def get(obj, key, fallback = None):
    if obj == None or type(obj) != "dict":
        return fallback
    v = obj.get(key, fallback)
    return fallback if v == None else v

def num(s, fallback = -1):
    t = str(s).strip()
    if t == "":
        return fallback
    for ch in t.elems():
        if ch < "0" or ch > "9":
            return fallback
    return int(t)

# ------------------------------------------------------------------ feed
def date_minutes(s):
    """'/Date(1789495560000)/' -> minutes since the epoch, or None."""
    t = str(s)
    i = t.find("(")
    j = t.find(")", i + 1)
    if i < 0 or j < 0:
        return None
    ms = num(t[i + 1:j])
    return None if ms < 0 else ms // 60000

def clock_parts(s):
    """'10:42 AM' -> ['10:42', 'AM']."""
    t = str(s).strip().upper().split(" ")
    if len(t) != 2 or t[0].find(":") < 0:
        return ["", ""]
    return [t[0], t[1]]

def line_code(route):
    return ROUTE.get(key_of(route), "OTHER")

def train_label(designation):
    """M316 -> NO. 316, A769S -> AMTK 769. Both fit the 38 px under the
    locomotive; TRAIN 316 (41 px) ran into the status pill beside it."""
    d = clean(designation)
    digits = ""
    for ch in d.elems():
        if ch >= "0" and ch <= "9":
            digits += ch
    if d.startswith("A") and digits != "":
        return "AMTK " + digits
    return "NO. " + (digits if digits != "" else d)

def status_info(status, late):
    """[long pill, short pill, colour]. Banded here only, so the word and
    the colour can never disagree."""
    s = str(status).upper()
    if s.find("CANCEL") >= 0:
        return ["CANCELED", "CANCELED", C_BAD]
    if s.find("DELAY") >= 0:
        col = C_BAD if s.find("EXTENDED") >= 0 else C_LATE
        if late > 0:
            return [str(late) + " MIN LATE", str(late) + " LATE", col]
        return ["DELAYED", "DELAYED", col]
    if s == "ON TIME" or s == "":
        return ["ON TIME", "ON TIME", C_OK]
    w = clean(s)[:12]
    return [w, w, DIM]

def read_inputs(ctx):
    label = str(ctx.inputs.get("station", "L.A. UNION STATION")).strip().upper()
    if label not in STATIONS:
        label = "L.A. UNION STATION"
    line = LINE_INPUT.get(str(ctx.inputs.get("line", "ALL LINES")).strip().upper(), "ALL")
    board = "ARRIVALS" if str(ctx.inputs.get("board", "DEPARTURES")).strip().upper() == "ARRIVALS" else "DEPARTURES"
    return {"key": STATIONS[label][0], "station": STATIONS[label][1], "line": line, "board": board}

def fetch_board(ctx):
    d = read_inputs(ctx)
    r = http.get(FEED, headers = HEADERS, ttl_seconds = TTL)
    if r["status_code"] == 0:
        return dict(d, ok = False, head = "METROLINK OFFLINE", sub = "RETRY IN A MINUTE")
    if r["status_code"] != 200 or type(r["json"]) != "list":
        return dict(d, ok = False, head = "TRACKER UNAVAILABLE", sub = "HTTP " + str(r["status_code"]) + " - RETRY SOON")
    now_m = ctx.now.unix // 60
    trains = []
    for row in r["json"]:
        if key_of(get(row, "PlatformName", "")) != d["key"]:
            continue
        code = line_code(get(row, "RouteCode", ""))
        if d["line"] == "AMTRAK":
            if code != "SURF" and code != "STAR":
                continue
        elif d["line"] != "ALL" and code != d["line"]:
            continue
        sch = date_minutes(get(row, "TrainMovementTime", ""))
        est = date_minutes(get(row, "CalcTrainMovementTime", ""))
        if est == None:
            est = sch
        if est == None or est < now_m - 1:
            continue
        dest_raw = str(get(row, "TrainDestination", ""))
        dinfo = DEST.get(key_of(dest_raw), [clean(dest_raw), key_of(dest_raw)])
        if d["board"] == "DEPARTURES" and dinfo[1] == d["key"]:
            continue    # ends here: nothing to board
        st = status_info(get(row, "CalculatedStatus", ""), est - sch if sch != None else 0)
        track = clean(get(row, "FormattedTrackDesignation", ""))
        if track == "" or get(row, "IsTBD", False) == True:
            track = "TRACK TBA"
        cp = clock_parts(get(row, "FormattedCalcTrainMovementTime", ""))
        trains.append({
            "est": est, "mins": est - now_m, "code": code, "dest": dinfo[0],
            "status": st[0], "short": st[1], "color": st[2], "track": track,
            "hm": cp[0], "ampm": cp[1], "clock": cp[0] + cp[1][:1],
            "label": train_label(get(row, "TrainDesignation", "")),
        })
    # Soonest first (insertion sort; a station rarely has more than 25 rows).
    for i in range(1, len(trains)):
        k = i
        for step in range(i):
            if k > 0 and trains[k]["est"] < trains[k - 1]["est"]:
                trains[k], trains[k - 1] = trains[k - 1], trains[k]
                k -= 1
    return dict(d, ok = True, trains = trains)

# ---------------------------------------------------------------- chrome
def chip_row(c, d, right, right_color):
    """METROLINK chip, the station, and a right-aligned word, measured right
    side first so a long station name is clipped, never overdrawn."""
    x = 10 + c.badge("METROLINK", 10, 0, color = ink_for(BRAND), bg = BRAND, font = "4x5") + 3
    rw = c.text_width(right, "4x5")
    c.text(right, 181, 1, font = "4x5", color = right_color, align = "right")
    c.text(clip(c, d["station"], "4x5", 181 - rw - 5 - x + 1), x, 1, font = "4x5", color = INK)

def loco(c, y):
    c.sprite(LOCO, 10, y, legend = LOCO_LEGEND)
    c.hline(10, y + 11, 38, RAIL_C)

def flaps(c, s, x, y):
    """Split-flap tiles, 14 x 18 each on a 16 px pitch. The split is drawn
    first and the glyph stroked over it, so the seam shows only between the
    strokes of the digit - the way a real flap reads."""
    for i in range(len(s)):
        tx = x + i * 16
        c.round_rect(tx, y, tx + 13, y + 17, 2, fill = TILE)
        c.hline(tx, y + 9, 14, "black")
        ch = s[i]
        c.text_stroke(ch, tx + (14 - c.text_width(ch, "10x16")) // 2, y + 2, font = "10x16",
                      color = INK, stroke = TILE)

def flaps_width(s):
    return len(s) * 16 - 2

def fail_screen(c, d):
    c.fill("black")
    rail(c, OFFLINE)
    loco(c, 10)
    hf = fit(c, d["head"], ["5x7", "4x5"], 124)
    c.text(hf[1], 117, 10, font = hf[0], color = "amber", align = "center")
    sf = fit(c, d["sub"], ["4x5", "picopixel"], 124)
    c.text(sf[1], 117, 21, font = sf[0], color = DIM, align = "center")

def quiet_screen(c, d):
    """No train due is an answer, not an error."""
    c.fill("black")
    rail(c, C_OK)
    chip_row(c, d, d["board"], DIM)
    loco(c, 10)
    what = "NO TRAINS DUE" if d["line"] == "ALL" else "NO " + (LINES[d["line"]][0] if d["line"] in LINES else "AMTRAK") + " TRAINS"
    hf = fit(c, what, ["6x8", "5x7", "4x5"], 124)
    c.text(hf[1], 117, 11, font = hf[0], color = C_OK, align = "center")
    c.text(clip(c, "IN THE NEXT FEW HOURS", "4x5", 124), 117, 23, font = "4x5", color = DIM, align = "center")

# ------------------------------------------------------------ page: next
def next_train(c, ctx):
    d = fetch_board(ctx)
    if not d["ok"]:
        fail_screen(c, d)
        return
    if len(d["trains"]) == 0:
        quiet_screen(c, d)
        return
    t = d["trains"][0]
    c.fill("black")
    rail(c, t["color"])
    chip_row(c, d, t["track"], DIM)

    # Left zone x 10..47: the locomotive (y 8..18) on its rail (y 19), then
    # the departure clock (y 21..25) and the train number (y 27..31), each
    # with a 1 px gap. Both labels stay inside the 38 px the locomotive
    # spans, clear of the pills that start at x 52.
    loco(c, 8)
    c.text(t["clock"], 10, 21, font = "4x5", color = INK)
    c.text(clip(c, t["label"], "4x5", 38), 10, 27, font = "4x5", color = DIM)

    # Hero, right-aligned to x 181: flaps for NOW and 1..99 minutes, the
    # clock itself from 100 minutes out.
    if t["mins"] < 100:
        s = "NOW" if t["mins"] <= 0 else str(t["mins"])
        word = ("BOARDING" if d["board"] == "DEPARTURES" else "ARRIVING") if t["mins"] <= 0 else "MIN"
        fw = flaps_width(s)
        hx = 181 - fw + 1
        flaps(c, s, hx, 8)
        c.text(word, hx + fw // 2, 27, font = "4x5", color = DIM, align = "center")
    else:
        fw = c.text_width(t["hm"], "10x16")
        hx = 181 - fw + 1
        c.text(t["hm"], hx, 10, font = "10x16", color = INK)
        c.text(t["ampm"], hx + fw // 2, 27, font = "4x5", color = DIM, align = "center")

    # Text column x 52 .. hero - 4: line pill, destination, status pill.
    # Two flap tiles leave 96 px, the clock 75 - "SAN BERNARDINO" is 66 in
    # 4x5 and 81 in 5x7, so the destination drops a size rather than clips.
    tx = 52
    tw = hx - 4 - tx
    ln = LINES.get(t["code"], LINES["OTHER"])
    pill(c, ln[0] if pill_w(c, ln[0]) <= tw else clip(c, t["code"], "4x5", tw - 4), ln[1], tx, 8)
    df = fit(c, t["dest"], ["5x7", "4x5"], tw)
    c.text(df[1], tx, 17 if df[0] == "5x7" else 18, font = df[0], color = INK)
    pill(c, t["status"] if pill_w(c, t["status"]) <= tw else t["short"], t["color"], tx, 25)

# ------------------------------------------------------- page: upcoming
def upcoming(c, ctx):
    d = fetch_board(ctx)
    if not d["ok"]:
        fail_screen(c, d)
        return
    if len(d["trains"]) == 0:
        quiet_screen(c, d)
        return
    c.fill("black")
    rail(c, d["trains"][0]["color"])
    shown = d["trains"][:3]
    more = len(d["trains"]) - len(shown)
    chip_row(c, d, ("+" + str(more) + " MORE") if more > 0 else d["board"], DIM)

    # Three rows on an 8 px pitch: a bar in the line colour, the clock
    # ("12:17P" 24 px), the destination, and the short status pill measured
    # first at the right. The widest pill, "120 LATE", leaves 89 px for the
    # destination, more than any short name needs.
    for i in range(len(shown)):
        t = shown[i]
        y = 8 + i * 8
        c.rect(10, y, 12, y + 6, fill = LINES.get(t["code"], LINES["OTHER"])[1])
        c.text(t["clock"], 16, y + 1, font = "4x5", color = INK)
        pw = pill_w(c, t["short"])
        pill(c, t["short"], t["color"], 181 - pw + 1, y)
        c.text(clip(c, t["dest"], "4x5", 181 - pw - 4 - 46), 46, y + 1, font = "4x5", color = INK)

# ------------------------------------------------------------ page: lines
def lines(c, ctx):
    d = read_inputs(ctx)
    r = http.get(TRAINS, headers = HEADERS, ttl_seconds = TTL)
    if r["status_code"] == 0:
        fail_screen(c, dict(d, head = "METROLINK OFFLINE", sub = "RETRY IN A MINUTE"))
        return
    if r["status_code"] != 200 or type(r["json"]) != "list":
        fail_screen(c, dict(d, head = "TRACKER UNAVAILABLE", sub = "HTTP " + str(r["status_code"]) + " - RETRY SOON"))
        return

    # code -> [running, late, extended]
    counts = {code: [0, 0, 0] for code in LINE_ORDER}
    for tr in r["json"]:
        code = line_code(get(tr, "line", ""))
        if code not in counts:
            continue
        st = str(get(tr, "delay_status", "")).upper()
        counts[code][0] += 1
        if st.find("DELAY") >= 0:
            counts[code][1] += 1
            if st.find("EXTENDED") >= 0:
                counts[code][2] += 1
    # Starlark has no sum(); total the three columns by hand.
    running, late, extended = 0, 0, 0
    for k in LINE_ORDER:
        running += counts[k][0]
        late += counts[k][1]
        extended += counts[k][2]

    c.fill("black")
    rail(c, C_BAD if extended > 0 else (C_LATE if late > 0 else (C_OK if running > 0 else OFFLINE)))
    x = 10 + c.badge("METROLINK", 10, 0, color = ink_for(BRAND), bg = BRAND, font = "4x5") + 3
    c.text("LINE STATUS", x, 1, font = "4x5", color = INK)
    c.text(str(running) + (" TRAIN" if running == 1 else " TRAINS"), 181, 1, font = "4x5", color = DIM, align = "right")

    # Eight tiles, four across on a 43 px pitch (x 10..181) and two rows at
    # y 8 and y 20: a 2 px bar in the line colour down the tile's left edge,
    # the line code, and the state under it. The widest state, "10 LATE",
    # is 30 px of the 39 the tile leaves for text; the rows keep a 1 px gap
    # (state ends y 18, the next code starts y 20). The line you follow is
    # written in its own colour.
    for i in range(len(LINE_ORDER)):
        code = LINE_ORDER[i]
        tx = 10 + (i % 4) * 43
        ty = 8 + (i // 4) * 12
        n = counts[code]
        lc = LINES[code][1]
        c.rect(tx, ty, tx + 1, ty + 10, fill = lc)
        code_col = lc if code == d["line"] else (INK if n[0] > 0 else DIM)
        c.text(CODE_LABEL[code], tx + 4, ty, font = "4x5", color = code_col)
        if n[0] == 0:
            word, col = "IDLE", DIM
        elif n[1] == 0:
            word, col = "ON TIME", C_OK
        else:
            word, col = str(n[1]) + " LATE", C_BAD if n[2] > 0 else C_LATE
        c.text(clip(c, word, "4x5", 39), tx + 4, ty + 6, font = "4x5", color = col)

# The status page's line codes, as riders say them.
CODE_LABEL = {"AV": "AV", "VC": "VC", "SB": "SB", "RIV": "RIV", "OC": "OC", "IEOC": "IEOC",
              "91PV": "91/PV", "ARROW": "ARROW"}
