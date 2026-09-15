# Fantasy Football News
#
# Player news the way a fantasy manager reads it: who, what happened, and
# whether it helps or hurts - plus the waiver wire, which is where that news
# turns into a move.
#
#   news  RotoWire's latest NFL player updates (keyless RSS), or - when a team
#         is picked - ESPN's player feed for that team (the site.web API's
#         injuries?team= call, which returns the team's 25 latest player
#         updates with position, status, body part and return date).
#   wire  Sleeper's trending adds or drops over the last 24 hours, each player
#         looked up by id, with the share of Sleeper leagues that own him.
#
# DESIGN. A black ground and a pill that tells you, before you read a word,
# what kind of news this is. Every update is sorted into one of a handful of
# kinds - OUT and IR in red, DOUBTFUL, QUESTIONABLE and INJURY in the orange
# and amber family, CLEARED green, SIGNED / TRADED / RELEASED / CLAIMED /
# PROMOTED purple, BOOM orange, BUST ice, DEPTH CHART pink, STAT LINE teal,
# plain NEWS white - and each kind has its own pixel-art icon, drawn at 2x on
# the scroll panel: a red cross, a green check, swap arrows, a penalty flag, a
# clipboard of Xs and Os, a flame, an ice cube, a football, a megaphone. The
# rail wears the pill's colour so the page never contradicts itself. The
# player's name is the hero, as big as it will go (full name, then initial +
# last name, then last name alone, then smaller faces); the headline sits
# under it. ESPN's own status (Out, Injured Reserve, Doubtful, Questionable)
# always wins over the keyword read, because a player listed OUT is out
# whatever the blurb says. The waiver page swaps the icon for a flame (adds)
# or an ice cube (drops) and puts the numbers that decide a pickup under the
# name: position pill, team, how many managers added him, how widely owned.
#
# Frames: each page shows one story (or one player) at a time and rotates by
# the minute, with a 1/5 counter so the rotation reads as deliberate. That
# is why refresh is 60 while the feeds are cached far longer - news 600 s,
# trending 1800 s, player records 6 h. The panel re-draws every minute; the
# sources are asked at most every ten.

ROTOWIRE = "https://www.rotowire.com/rss/news.php"
ESPN_TEAM_FEED = "https://site.web.api.espn.com/apis/site/v2/sports/football/nfl/injuries"
SLEEPER = "https://api.sleeper.app/v1/"
SLEEPER_RESEARCH = "https://api.sleeper.com/players/nfl/research/"
HEADERS = {"User-Agent": "glance-fantasy-football-news (glance-led.dev)"}

NEWS_TTL = 600
TREND_TTL = 1800
STATE_TTL = 3600
RESEARCH_TTL = 3600
PLAYER_TTL = 21600

# ----------------------------------------------------------------- palette
INK = "#F4F7FF"
DIM = "#6E7A94"
OFFLINE = "#3C4043"
GOOD = "#2FE06F"

C_OUT = "#FF2D2D"      # OUT, IR          - white type
C_DOUBT = "#FF4F1F"    # DOUBTFUL         - white type
C_QUES = "#FFBF00"     # QUESTIONABLE, INJURY, SUSPENDED
C_CLEAR = "#2FE06F"    # CLEARED
C_MOVE = "#B18CFF"     # SIGNED, TRADED, RELEASED, CLAIMED, PROMOTED
C_BOOM = "#FF9A1F"     # BOOM, trending adds
C_BUST = "#9FC9FF"     # BUST, trending drops
C_ROLE = "#FF7EB6"     # DEPTH CHART
C_STAT = "#2DD4BF"     # STAT LINE
C_NEWS = "#F4F7FF"     # NEWS

POS_COLOR = {"QB": "#FF6F9C", "RB": "#2EE6C8", "WR": "#5CB8FF", "TE": "#FFB45C",
             "K": "#C792FF", "DEF": "#B0BCCB"}

# ESPN team id and abbreviation, keyed by the dropdown label.
TEAMS = {
    "ARIZONA CARDINALS": ["22", "ARI"], "ATLANTA FALCONS": ["1", "ATL"],
    "BALTIMORE RAVENS": ["33", "BAL"], "BUFFALO BILLS": ["2", "BUF"],
    "CAROLINA PANTHERS": ["29", "CAR"], "CHICAGO BEARS": ["3", "CHI"],
    "CINCINNATI BENGALS": ["4", "CIN"], "CLEVELAND BROWNS": ["5", "CLE"],
    "DALLAS COWBOYS": ["6", "DAL"], "DENVER BRONCOS": ["7", "DEN"],
    "DETROIT LIONS": ["8", "DET"], "GREEN BAY PACKERS": ["9", "GB"],
    "HOUSTON TEXANS": ["34", "HOU"], "INDIANAPOLIS COLTS": ["11", "IND"],
    "JACKSONVILLE JAGUARS": ["30", "JAX"], "KANSAS CITY CHIEFS": ["12", "KC"],
    "LAS VEGAS RAIDERS": ["13", "LV"], "LOS ANGELES CHARGERS": ["24", "LAC"],
    "LOS ANGELES RAMS": ["14", "LAR"], "MIAMI DOLPHINS": ["15", "MIA"],
    "MINNESOTA VIKINGS": ["16", "MIN"], "NEW ENGLAND PATRIOTS": ["17", "NE"],
    "NEW ORLEANS SAINTS": ["18", "NO"], "NEW YORK GIANTS": ["19", "NYG"],
    "NEW YORK JETS": ["20", "NYJ"], "PHILADELPHIA EAGLES": ["21", "PHI"],
    "PITTSBURGH STEELERS": ["23", "PIT"], "SAN FRANCISCO 49ERS": ["25", "SF"],
    "SEATTLE SEAHAWKS": ["26", "SEA"], "TAMPA BAY BUCCANEERS": ["27", "TB"],
    "TENNESSEE TITANS": ["10", "TEN"], "WASHINGTON COMMANDERS": ["28", "WSH"],
}
# Abbreviation -> nickname, for Sleeper's team defenses ("TB" -> BUCCANEERS).
NICK = {TEAMS[k][1]: k.split(" ")[len(k.split(" ")) - 1] for k in TEAMS}

# --------------------------------------------------------------- pixel art
# Small art is drawn at 1x on the 64 panel and in the chip row; the scroll
# hero draws the big art (or the small art when there is none) at 2x.
BALL = """
...DDDDD...
.DBBBBBBBD.
DBBWBWBWBBD
DBWWWWWWWBD
DBBWBWBWBBD
.DBBBBBBBD.
...DDDDD...
"""
CROSS = """
..XXX..
..XXX..
XXXXXXX
XXXXXXX
XXXXXXX
..XXX..
..XXX..
"""
CHECK = """
......X
.....XX
X...XX.
XX.XX..
.XXX...
..X....
"""
SWAP = """
....X..
XXXXXX.
....X..
.......
..X....
.XXXXXX
..X....
"""
FLAG = """
PXXXXX.
PXXXXXX
PXXXXX.
PXXXX..
P......
P......
P......
"""
CLIP = """
..GGG..
BBGGGBB
BWXWXWB
BWWXWWB
BWXWXWB
BWWWWWB
BBBBBBB
"""
# 9 x 9: an X and an O on the play sheet, 18 x 18 at 2x.
CLIP_BIG = """
...GGG...
BBBGGGBBB
BWWWWWWWB
BXWXWOOOB
BWXWWOWOB
BXWXWOOOB
BWWWWWWWB
BWWWWWWWB
BBBBBBBBB
"""
FIRE = """
...R...
..RR..R
.RROR.R
.ROYORR
RROYYOR
ROYWYOR
.RYWYR.
"""
ICE = """
.IIIII.
IWWIIIL
IWIIIIL
IIIIIIL
IIIIIIL
IIIIIIL
.LLLLL.
"""
MEGA = """
.....X..
...XXX..
XXXXXX.S
XXXXXX..
XXXXXX.S
...XXX..
.....X..
"""
# 10 x 7: the bell, a handle, and three sound marks.
MEGA_BIG = """
......XX..
....XXXX.S
XXXXXXXX..
XXXXXXXXSS
XXXXXXXX..
.X..XXXX.S
.X....XX..
"""

# name -> [small art, fixed legend, big art or ""]; "X" takes the kind's colour.
ICONS = {
    "BALL": [BALL, {"D": "#5A2E0E", "B": "#A0522D", "W": "#FFFFFF"}, ""],
    "CROSS": [CROSS, {}, ""],
    "CHECK": [CHECK, {}, ""],
    "SWAP": [SWAP, {}, ""],
    "FLAG": [FLAG, {"P": "#D9DEE8"}, ""],
    "CLIP": [CLIP, {"G": "#9AA3B2", "B": "#8B5A2B", "W": "#F4F7FF", "O": "#2B3A55"}, CLIP_BIG],
    "FIRE": [FIRE, {"R": "#FF3D00", "O": "#FF9100", "Y": "#FFE000", "W": "#FFF6C8"}, ""],
    "ICE": [ICE, {"I": "#9FC9FF", "W": "#FFFFFF", "L": "#4A7FC0"}, ""],
    "MEGA": [MEGA, {"S": DIM}, MEGA_BIG],
}

# kind -> [pill word, short pill word for 64, colour, icon]
KIND = {
    "OUT": ["OUT", "OUT", C_OUT, "CROSS"],
    "IR": ["INJURED RESERVE", "IR", C_OUT, "CROSS"],
    "DOUBTFUL": ["DOUBTFUL", "DOUBT", C_DOUBT, "CROSS"],
    "QUESTIONABLE": ["QUESTIONABLE", "QUES", C_QUES, "CROSS"],
    "INJURY": ["INJURY", "INJURY", C_QUES, "CROSS"],
    "SUSPENDED": ["SUSPENDED", "SUSP", C_QUES, "FLAG"],
    "CLEARED": ["CLEARED", "CLEAR", C_CLEAR, "CHECK"],
    "TRADED": ["TRADED", "TRADED", C_MOVE, "SWAP"],
    "RELEASED": ["RELEASED", "CUT", C_MOVE, "SWAP"],
    "CLAIMED": ["CLAIMED", "CLAIM", C_MOVE, "SWAP"],
    "PROMOTED": ["PROMOTED", "UP", C_MOVE, "SWAP"],
    "SIGNED": ["SIGNED", "SIGNED", C_MOVE, "SWAP"],
    "BOOM": ["BOOM", "BOOM", C_BOOM, "FIRE"],
    "BUST": ["BUST", "BUST", C_BUST, "ICE"],
    "ROLE": ["DEPTH CHART", "ROLE", C_ROLE, "CLIP"],
    "STATS": ["STAT LINE", "STATS", C_STAT, "BALL"],
    "NEWS": ["NEWS", "NEWS", C_NEWS, "MEGA"],
}

# ------------------------------------------------------- reading the news
# Phrases are matched against " " + lowercase text + " " with punctuation
# turned into spaces, so " knee " cannot match "kneel". Order is the
# precedence: an injury outranks the box score it happened in.
KW_OUT = [" ruled out ", " out for the ", " won't play ", " will not play ", " will miss ",
          " won't return ", " will not return ", " season-ending ", " out indefinitely ",
          " underwent surgery ", " undergo surgery ", " torn ", " tore ", " is out ",
          " inactive ", " healthy scratch "]
KW_CLEAR = [" cleared ", " full participant ", " practiced fully ", " full practice ",
            " no injury designation ", " not have an injury designation ",
            " without an injury designation ", " not on the injury report ",
            " did not appear on ", " off the injury report ", " activated ",
            " return to practice ", " returns to practice ", " returned to practice ",
            " back at practice ", " good to go ", " will play ", " expected to play ",
            " set to return ", " will return ", " healthy "]
KW_INJ = [" game-time ", " limited participant ", " limited in practice ", " limited at practice ",
          " did not practice ", " didn't practice ", " not practicing ", " missed practice ",
          " day-to-day ", " injury ", " injured ", " exited ", " left the game ", " carted ",
          " concussion ", " hamstring ", " ankle ", " knee ", " shoulder ", " groin ", " calf ",
          " quad ", " illness ", " sprained ", " strained ", " hip ", " foot ", " toe ", " wrist ",
          " rib ", " ribs ", " oblique ", " glute ", " pectoral ", " achilles ", " neck ",
          " back injury "]
KW_BOOM = [" touchdown ", " touchdowns ", " td ", " tds ", " scores ", " scored ",
           " career-high ", " career high ", " dazzling ", " explodes ", " big day ",
           " huge day ", " monster ", " dominant ", " breakout "]
KW_BUST = [" miserable ", " struggle ", " struggles ", " struggled ", " quiet ",
           " limited to ", " held to ", " bust ", " disappointing ", " rough ", " fumble ",
           " fumbles ", " didn't see a target ", " did not see a target ", " failed to ",
           " no catches ", " minus-", " only target ", " sole target ", " lone target ",
           " didn't record ", " did not record ", " did not play ", " didn't play ",
           " wasn't targeted ", " was not targeted ", " not targeted ", " without a catch "]
KW_ROLE = [" starter ", " will start ", " to start ", " starting ", " named the ", " backup ",
           " depth chart ", " lead back ", " workhorse ", " snap share ", " workload ",
           " benched ", " demoted ", " role ", " first-team ", " in line to ", " in line for ",
           " committee "]
KW_STATS = [" yards ", " yard ", " targets ", " target ", " carries ", " carry ", " catch ",
            " catches ", " caught ", " receptions ", " completed ", " passes ", " field goal ",
            " field-goal ", " pats ", " extra point ", " tackles ", " sacks ", " returned ",
            " rushed ", " snaps ", " kicks ", " punts "]

def norm(s):
    t = " " + str(s).lower().replace("’", "'") + " "
    for p in [",", ".", ";", ":", "(", ")", "!", "?", "\"", "“", "”"]:
        t = t.replace(p, " ")
    return t

def has_any(t, words):
    for w in words:
        if t.find(w) >= 0:
            return True
    return False

def big_yards(t):
    """A yardage of 100 or more anywhere in the text ('for 173 yards')."""
    i = 0
    for step in range(12):
        j = t.find(" yards", i)
        if j < 0:
            return False
        k = j
        for m in range(4):
            if k > 0 and t[k - 1] >= "0" and t[k - 1] <= "9":
                k -= 1
            else:
                break
        if j - k >= 3:
            return True
        i = j + 6
    return False

def paren_injury(raw):
    """RotoWire writes the ailment in parentheses right after the subject:
    'Jones (calf) ...'. Only a parenthetical in the first 30 characters
    counts - one later in the sentence is usually about someone else
    ('Lock is likely to start with Sam Darnold (glute) sidelined')."""
    t = str(raw).lower()
    i = t.find("(")
    if i < 0 or i > 30:
        return False
    j = t.find(")", i)
    if j < 0 or j - i > 24:
        return False
    inner = t[i + 1:j]
    return inner not in ["coach's decision", "coach’s decision", "personal", "not injury related", "rest"]

# Injury words come in two strengths. A practice report or an exit is about
# the subject of the sentence; a bare "injury" or body part often is not
# ("Lock is likely to start with Darnold nursing a soft-tissue injury"), so
# the weak ones wait until roster moves and starting news have had a look.
KW_INJ_STRONG = [" game-time ", " limited participant ", " limited in practice ",
                 " limited at practice ", " did not practice ", " didn't practice ",
                 " not practicing ", " missed practice ", " day-to-day ", " exited ",
                 " left the game ", " carted ", " concussion "]
KW_START = [" to start ", " will start ", " starting ", " named the starter ", " named starter ",
            " will be the starter ", " expected to start "]

def classify(raw):
    t = norm(raw)
    if has_any(t, [" injured reserve ", " placed on ir ", " to ir ", " on ir "]):
        return "IR"
    if has_any(t, KW_OUT):
        return "OUT"
    if has_any(t, KW_CLEAR):
        return "CLEARED"
    if t.find(" doubtful ") >= 0:
        return "DOUBTFUL"
    if t.find(" questionable ") >= 0:
        return "QUESTIONABLE"
    if has_any(t, KW_INJ_STRONG) or paren_injury(raw):
        return "INJURY"
    kind = roster_or_start(t)
    if kind != "":
        return kind
    if has_any(t, KW_INJ):
        return "INJURY"
    return performance(t)

def roster_or_start(t):
    if t.find(" suspend") >= 0:
        return "SUSPENDED"
    if has_any(t, [" traded ", " trade ", " trades ", " acquired ", " acquires "]):
        return "TRADED"
    if has_any(t, [" released ", " releases ", " waived ", " waives ", " cut by ", " cuts "]):
        return "RELEASED"
    if has_any(t, [" claimed ", " claims "]):
        return "CLAIMED"
    if has_any(t, [" elevated ", " elevates ", " promoted ", " promotes "]):
        return "PROMOTED"
    if has_any(t, [" signed ", " signs ", " re-signed ", " re-signs ", " agreed to ", " agrees to ",
                   " contract ", " extension "]):
        return "SIGNED"
    if has_any(t, KW_START):
        return "ROLE"
    return ""

def performance(t):
    """No injury, move or start: judge the game itself."""
    if has_any(t, KW_BOOM) or big_yards(t):
        return "BOOM"
    if has_any(t, KW_BUST):
        return "BUST"
    if has_any(t, KW_ROLE):
        return "ROLE"
    if has_any(t, KW_STATS):
        return "STATS"
    return "NEWS"

def status_kind(status):
    """ESPN's designation, when it says anything stronger than Active."""
    s = str(status).strip().lower()
    if s == "out":
        return "OUT"
    if s == "injured reserve" or s.startswith("physically unable"):
        return "IR"
    if s == "doubtful":
        return "DOUBTFUL"
    if s == "questionable" or s == "day-to-day":
        return "QUESTIONABLE"
    if s.startswith("suspen"):
        return "SUSPENDED"
    return ""

# ------------------------------------------------------------- text tools
KEEP = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,-:;/&+%#!?()$@"

def ents(s):
    t = str(s)
    for pair in [["&amp;", "&"], ["&lt;", "<"], ["&gt;", ">"], ["&quot;", "\""], ["&#39;", "'"],
                 ["&#039;", "'"], ["&apos;", "'"], ["&nbsp;", " "], ["–", "-"], ["—", "-"]]:
        t = t.replace(pair[0], pair[1])
    return t

def clean(s):
    """Panel-safe uppercase. Every font on the panel lacks ' and ", and a
    missing glyph is dropped silently, so they are removed on purpose here
    (JA'MARR -> JAMARR) along with anything outside plain ASCII."""
    out = ""
    last_space = True
    for ch in ents(s).upper().elems():
        if ch == "\n" or ch == "\t":
            ch = " "
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

def wrap(c, text, font, maxw, maxlines):
    """Word-wrap into at most `maxlines`; a cut ends in '..' so it reads
    as deliberate."""
    words = [w for w in str(text).split(" ") if w != ""]
    lines = []
    cur = ""
    cut = False
    for w in words:
        trial = w if cur == "" else cur + " " + w
        if c.text_width(trial, font) <= maxw:
            cur = trial
            continue
        if cur != "":
            lines.append(cur)
            cur = ""
            if len(lines) == maxlines:
                cut = True
                break
        cur = w if c.text_width(w, font) <= maxw else clip(c, w, font, maxw)
    if not cut and cur != "":
        if len(lines) < maxlines:
            lines.append(cur)
        else:
            cut = True
    if cut and len(lines) > 0:
        last = lines[len(lines) - 1]
        for k in range(len(last)):
            t = last[:len(last) - k].rstrip(" ,.;:-")
            if c.text_width(t + "..", font) <= maxw:
                lines[len(lines) - 1] = t + ".."
                break
    return lines

# Lit rows per face, top-aligned (10x16 draws its capitals in rows 0-14).
INKH = {"10x16": 15, "9x12": 12, "8x10": 10, "6x8": 8, "5x7": 7, "4x5": 5, "picopixel": 5}

SUFFIX = ["JR.", "JR", "SR.", "SR", "II", "III", "IV", "V"]
PARTICLE = ["ST.", "ST", "DE", "DI", "DA", "DU", "LA", "LE", "VAN", "VON", "DEL", "DOS"]

def name_forms(full, abbreviate):
    """[full, initial + last, last, surname]. The surname keeps a particle
    ('ST. BROWN') and drops a suffix; 'last' keeps the suffix ('HARRISON JR.')."""
    parts = [p for p in full.split(" ") if p != ""]
    if not abbreviate or len(parts) < 2:
        return [full, full, full, full]
    end = len(parts)
    suffix = ""
    if end >= 3 and parts[end - 1] in SUFFIX:
        suffix = parts[end - 1]
        end -= 1
    start = end - 1
    if start >= 2 and parts[start - 1] in PARTICLE:
        start -= 1
    surname = " ".join(parts[start:end])
    last = surname + (" " + suffix if suffix != "" else "")
    return [full, parts[0][:1] + ". " + last, last, surname]

def pick_name(c, forms, maxw, allow_big):
    order = [[0, "10x16"], [1, "10x16"]] if allow_big else []
    order = order + [[0, "9x12"], [1, "9x12"], [2, "9x12"], [0, "8x10"], [1, "8x10"], [2, "8x10"],
                     [0, "6x8"], [1, "6x8"], [2, "6x8"], [2, "5x7"], [2, "4x5"]]
    for o in order:
        if c.text_width(forms[o[0]], o[1]) <= maxw:
            return [forms[o[0]], o[1]]
    return [clip(c, forms[2], "4x5", maxw), "4x5"]

def pick_last(c, forms, maxw):
    return fit(c, forms[2], ["9x12", "8x10", "6x8", "5x7", "4x5", "picopixel"], maxw)

def strip_subject(head, surname, keep_paren):
    """ESPN blurbs open with the surname that is already on the panel. Drop
    it - but on the scroll panel keep 'KELCE (ANKLE) WAS..', where the
    parenthetical needs its subject to read."""
    if surname == "":
        return head
    if head.startswith(surname + " ("):
        return head if keep_paren else head[len(surname) + 1:]
    if head.startswith(surname + " "):
        return head[len(surname) + 1:]
    return head

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

def icon_art(name, big):
    e = ICONS[name]
    return e[2] if big and e[2] != "" else e[0]

def icon_dims(name, big):
    rows = icon_art(name, big).strip("\n").split("\n")
    return [max([len(r) for r in rows]), len(rows)]

def icon(c, name, color, x, y, scale, big = False):
    leg = dict(ICONS[name][1])
    leg["X"] = color
    c.sprite(icon_art(name, big), x, y, legend = leg, scale = scale)

def icon_centered(c, name, color, cx, cy):
    """The scroll hero: big art at 2x, centred on (cx, cy)."""
    d = icon_dims(name, True)
    icon(c, name, color, cx - d[0], cy - d[1], 2, True)

def rail(c, color):
    c.rect(0, 0, 1, 31, fill = color)

# ------------------------------------------------------------ numbers/time
def num(s, fallback = -1):
    t = str(s).strip()
    if t == "":
        return fallback
    for ch in t.elems():
        if ch < "0" or ch > "9":
            return fallback
    return int(t)

def compact(n):
    """954793 -> 955K, 1234567 -> 1.2M, 999 -> 999."""
    if n < 1000:
        return str(n)
    if n < 999500:
        return str((n + 500) // 1000) + "K"
    tenths = (n + 50000) // 100000
    return str(tenths // 10) + "." + str(tenths % 10) + "M"

def days_from_civil(y, m, d):
    yy = y - 1 if m <= 2 else y
    era = (yy if yy >= 0 else yy - 399) // 400
    yoe = yy - era * 400
    doy = (153 * (m + (-3 if m > 2 else 9)) + 2) // 5 + d - 1
    doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468

MON = {"JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
       "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12}
MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
TZ = {"PDT": 7, "PST": 8, "MDT": 6, "MST": 7, "CDT": 5, "CST": 6, "EDT": 4, "EST": 5,
      "GMT": 0, "UTC": 0, "Z": 0}

def parse_rfc822(s):
    """'Mon, 14 Sep 2026 9:32:00 PM PDT' -> UTC minutes since the epoch."""
    toks = [t for t in str(s).replace(",", " ").split(" ") if t != ""]
    if len(toks) > 0 and num(toks[0]) < 0:
        toks = toks[1:]
    if len(toks) < 4:
        return None
    d, mo, y = num(toks[0]), MON.get(toks[1][:3].upper(), 0), num(toks[2])
    hms = toks[3].split(":")
    if d < 1 or mo == 0 or y < 2000 or len(hms) < 2:
        return None
    h, mi = num(hms[0]), num(hms[1])
    if h < 0 or mi < 0:
        return None
    off = 7
    for r in toks[4:]:
        u = r.upper()
        if u == "PM" and h < 12:
            h += 12
        elif u == "AM" and h == 12:
            h = 0
        elif u in TZ:
            off = TZ[u]
        elif len(u) == 5 and (u.startswith("-") or u.startswith("+")) and num(u[1:3]) >= 0:
            off = num(u[1:3]) if u.startswith("-") else -num(u[1:3])
    return days_from_civil(y, mo, d) * 1440 + h * 60 + mi + off * 60

def parse_iso(s):
    """'2026-09-15T04:32Z' -> UTC minutes since the epoch."""
    t = str(s).strip()
    if len(t) < 16 or t[10] != "T":
        return None
    y, mo, d, h, mi = num(t[0:4]), num(t[5:7]), num(t[8:10]), num(t[11:13]), num(t[14:16])
    if y < 2000 or mo < 1 or mo > 12 or d < 1 or h < 0 or mi < 0:
        return None
    return days_from_civil(y, mo, d) * 1440 + h * 60 + mi

def ago(mins):
    if mins < 1:
        return "NOW"
    if mins < 60:
        return str(mins) + "M"
    if mins < 1440:
        return str(mins // 60) + "H"
    return str(mins // 1440) + "D"

def month_day(iso):
    t = str(iso)
    if len(t) < 10 or num(t[5:7]) < 1 or num(t[5:7]) > 12:
        return ""
    return MONTHS[num(t[5:7]) - 1] + " " + str(num(t[8:10]))

# ------------------------------------------------------------------ feeds
def get(obj, key, fallback = None):
    if obj == None or type(obj) != "dict":
        return fallback
    v = obj.get(key, fallback)
    return fallback if v == None else v

def dig(obj, path, fallback = None):
    cur = obj
    for k in path:
        if cur == None or type(cur) != "dict":
            return fallback
        cur = cur.get(k, None)
    return fallback if cur == None else cur

def tag_text(chunk, tag):
    i = chunk.find("<" + tag + ">")
    if i < 0:
        return ""
    i += len(tag) + 2
    j = chunk.find("</" + tag + ">", i)
    if j < 0:
        return ""
    t = chunk[i:j].strip()
    if t.startswith("<![CDATA["):
        t = t[9:]
        if t.endswith("]]>"):
            t = t[:len(t) - 3]
    return t

def parse_rotowire(body):
    items = []
    pos = 0
    for k in range(12):
        s = body.find("<item>", pos)
        if s < 0:
            break
        e = body.find("</item>", s)
        if e < 0:
            break
        chunk = body[s:e]
        pos = e + 7
        title = ents(tag_text(chunk, "title"))
        desc = ents(tag_text(chunk, "description")).replace("Visit RotoWire.com for more analysis on this update.", "")
        colon = title.find(": ")
        name = title[:colon] if colon > 0 else ""
        head = title[colon + 2:] if colon > 0 else title
        if clean(head) == "":
            continue
        kind = classify(head)
        if kind == "NEWS" or kind == "STATS":
            k2 = classify(desc)
            if k2 != "NEWS":
                kind = k2
        items.append({"name": clean(name), "head": clean(head), "kind": kind, "pos": "",
                      "team": "", "mins": parse_rfc822(tag_text(chunk, "pubDate"))})
    return items

def trim_tail(s):
    """ESPN's blurbs are whole sentences. Drop the reporter credit and the
    game-context tail so the part a manager needs fits two panel lines."""
    t = str(s).strip()
    if t.endswith("."):
        t = t[:len(t) - 1]
    r = t.rfind(", ")
    if r > 20 and t.endswith(" reports"):
        t = t[:r]
    cut = -1
    for m in [" in Sunday", " in Monday", " in Tuesday", " in Wednesday", " in Thursday",
              " in Friday", " in Saturday", " in last ", " in the ", " during ", " against the ",
              " on Sunday", " on Monday", " on Tuesday", " on Wednesday", " on Thursday",
              " on Friday", " on Saturday"]:
        i = t.find(m)
        if i >= 30 and (cut < 0 or i < cut):
            cut = i
    return t[:cut] if cut > 0 else t

def parse_espn(j, abbr):
    items = []
    for row in get(j, "injuries", []):
        if len(items) == 6:
            break
        a = get(row, "athlete", {})
        pos = str(dig(a, ["position", "abbreviation"], ""))
        if pos == "PK":
            pos = "K"
        if pos not in ["QB", "RB", "WR", "TE", "K"]:
            continue
        blurb = ents(get(row, "shortComment", ""))
        kind = status_kind(get(row, "status", ""))
        if kind == "":
            kind = classify(blurb)
        if len(blurb.strip()) < 16:
            # "out" / "inactive" rows carry their meaning in details instead.
            # A short row with no details and no designation says nothing a
            # panel can show, so it is skipped rather than drawn as filler.
            bits = []
            body = str(dig(row, ["details", "type"], ""))
            back = month_day(dig(row, ["details", "returnDate"], ""))
            if body != "":
                bits.append(body)
            if back != "":
                bits.append("BACK " + back)
            if len(bits) > 0:
                head = " - ".join(bits)
            elif blurb.lower().find("inactive") >= 0:
                head = "INACTIVE THIS WEEK"
            elif status_kind(get(row, "status", "")) != "":
                head = "LISTED " + KIND[kind][0]
            else:
                continue
        else:
            head = trim_tail(blurb)
        team = str(dig(a, ["team", "abbreviation"], abbr))
        items.append({"name": clean(get(a, "displayName", "")), "head": clean(head), "kind": kind,
                      "pos": pos, "team": clean(team), "mins": parse_iso(get(row, "date", ""))})
    return items

def fetch_news(ctx):
    follow = str(ctx.inputs.get("follow", "ALL NFL")).strip().upper()
    if follow in TEAMS:
        t = TEAMS[follow]
        r = http.get(ESPN_TEAM_FEED, params = {"team": t[0]}, headers = HEADERS, ttl_seconds = NEWS_TTL)
        if r["status_code"] == 0:
            return {"ok": False, "head": ["ESPN OFFLINE", "OFFLINE"], "sub": ["RETRY IN 10 MIN", "RETRY SOON"]}
        if r["status_code"] != 200 or type(r["json"]) != "dict":
            return {"ok": False, "head": ["ESPN FEED ERROR", "FEED ERROR"],
                    "sub": ["HTTP " + str(r["status_code"]) + " - RETRY SOON", "HTTP " + str(r["status_code"])]}
        return {"ok": True, "items": parse_espn(r["json"], t[1]), "scope": t[1]}
    r = http.get(ROTOWIRE, params = {"sport": "NFL"}, headers = HEADERS, ttl_seconds = NEWS_TTL)
    if r["status_code"] == 0:
        return {"ok": False, "head": ["NEWS FEED OFFLINE", "OFFLINE"], "sub": ["RETRY IN 10 MIN", "RETRY SOON"]}
    if r["status_code"] != 200:
        return {"ok": False, "head": ["NEWS FEED ERROR", "FEED ERROR"],
                "sub": ["HTTP " + str(r["status_code"]) + " - RETRY SOON", "HTTP " + str(r["status_code"])]}
    return {"ok": True, "items": parse_rotowire(r["body"]), "scope": "NFL"}

def fetch_wire(ctx):
    kind = "DROPS" if str(ctx.inputs.get("wire", "ADDS")).strip().upper() == "DROPS" else "ADDS"
    want = str(ctx.inputs.get("position", "ALL")).strip().upper()
    if want not in ["QB", "RB", "WR", "TE", "K", "DEF"]:
        want = "ALL"
    base = {"kind": kind, "want": want}

    tr = http.get(SLEEPER + "players/nfl/trending/" + ("add" if kind == "ADDS" else "drop"),
                  params = {"lookback_hours": "24", "limit": "25"}, headers = HEADERS,
                  ttl_seconds = TREND_TTL)
    if tr["status_code"] == 0:
        return dict(base, ok = False, head = ["SLEEPER OFFLINE", "OFFLINE"], sub = ["RETRY IN 30 MIN", "RETRY SOON"])
    if tr["status_code"] != 200 or type(tr["json"]) != "list":
        return dict(base, ok = False, head = ["SLEEPER ERROR", "FEED ERROR"],
                    sub = ["HTTP " + str(tr["status_code"]) + " - RETRY SOON", "HTTP " + str(tr["status_code"])])

    # Week and owned % are garnish: a failure costs the numbers, not the page.
    week = 0
    owned = {}
    st = http.get(SLEEPER + "state/nfl", headers = HEADERS, ttl_seconds = STATE_TTL)
    if st["status_code"] == 200 and type(st["json"]) == "dict":
        week = num(get(st["json"], "week", ""), 0)
        season = str(get(st["json"], "season", ""))
        stype = str(get(st["json"], "season_type", ""))
        if week > 0 and season != "" and stype in ["regular", "pre", "post"]:
            rs = http.get(SLEEPER_RESEARCH + stype + "/" + season + "/" + str(week),
                          headers = HEADERS, ttl_seconds = RESEARCH_TTL)
            if rs["status_code"] == 200 and type(rs["json"]) == "dict":
                owned = rs["json"]

    # Budget: trending + state + research = 3, so at most 5 player lookups
    # keeps the render inside the 8-request ceiling. Team defenses need none.
    players = []
    lookups = 0
    for t in tr["json"]:
        if len(players) == 3:
            break
        pid = str(get(t, "player_id", ""))
        if pid == "":
            continue
        count = num(get(t, "count", ""), 0)
        pct = get(get(owned, pid, {}), "owned", None)
        pct = int(pct + 0.5) if type(pct) in ["float", "int"] else -1
        if num(pid) < 0:
            if want != "ALL" and want != "DEF":
                continue
            abbr = "WSH" if pid == "WAS" else pid
            nick = NICK.get(abbr, abbr)
            players.append({"forms": [nick + " D/ST", nick + " D/ST", nick, nick], "pos": "DEF",
                            "team": abbr, "count": count, "pct": pct})
            continue
        if lookups == 5:
            break
        lookups += 1
        r = http.get(SLEEPER + "players/nfl/" + pid, headers = HEADERS, ttl_seconds = PLAYER_TTL)
        if r["status_code"] != 200 or type(r["json"]) != "dict":
            continue
        p = r["json"]
        ppos = str(get(p, "position", ""))
        if want != "ALL" and ppos != want:
            continue
        name = clean(str(get(p, "first_name", "")) + " " + str(get(p, "last_name", "")))
        if name == "":
            continue
        team = str(get(p, "team", "FA"))
        players.append({"forms": name_forms(name, True), "pos": ppos,
                        "team": "WSH" if team == "WAS" else team, "count": count, "pct": pct})
    return dict(base, ok = True, players = players, week = week)

# ------------------------------------------------------------ shared chrome
def chip_row(c, word, fill, right_limit, show_word):
    """Football + FANTASY + the pill, never past right_limit. The word is
    decided once per rotation by the caller, so it does not blink in and
    out between frames; the pill never moves."""
    icon(c, "BALL", "", 10, 0, 1)
    x = 24
    w = pill_w(c, word)
    if show_word and x + 33 + 4 + w - 1 <= right_limit:
        c.text("FANTASY", x, 1, font = "4x5", color = INK)
        x += 33 + 4
    if x + w - 1 <= right_limit:
        pill(c, word, fill, x, 0)

def meta_right(c, parts, pos, draw):
    """The chip row's right side, laid out from x 181 leftward: 4x5 text
    parts, then an optional position pill. Returns the free x to the left.
    With draw=False it only measures, so a caller can plan the left side."""
    x = 181
    for part in parts:
        if part[0] == "":
            continue
        if draw:
            c.text(part[0], x, 1, font = "4x5", color = part[1], align = "right")
        x = x - c.text_width(part[0], "4x5") - 5
    if pos != "":
        pw = pill_w(c, pos)
        if draw:
            pill(c, pos, POS_COLOR.get(pos, "#B0BCCB"), x - pw + 1, 0)
        x = x - pw - 3
    return x

def news_meta(c, it, label, n, now_m, draw):
    age = ago(now_m - it["mins"]) + " AGO" if it["mins"] != None else ""
    return meta_right(c, [[str(label) + "/" + str(n), DIM], [age, DIM], [it["team"], INK]], it["pos"], draw)

def fail_screen(c, d):
    c.fill("black")
    wide = c.width >= 128
    if wide:
        rail(c, OFFLINE)
        icon(c, "BALL", "", 10, 1, 1)
    else:
        icon(c, "BALL", "", 0, 0, 1)
    maxw = 172 if wide else c.width - 2
    hf = fit(c, d["head"][0 if wide else 1], ["5x7", "4x5"], maxw)
    c.text(hf[1], c.width // 2, 11, font = hf[0], color = "amber", align = "center")
    sf = fit(c, d["sub"][0 if wide else 1], ["4x5", "picopixel"], maxw)
    c.text(sf[1], c.width // 2, 23, font = sf[0], color = DIM, align = "center")

def quiet_screen(c, head, sub, head_n, sub_n):
    """Nothing to show is an answer, not an error: green, and calm."""
    c.fill("black")
    if c.width >= 128:
        rail(c, GOOD)
        icon_centered(c, "BALL", "", 21, 17)
        hf = fit(c, head, ["6x8", "5x7", "4x5"], 145)
        c.text(hf[1], 108, 9, font = hf[0], color = GOOD, align = "center")
        sf = fit(c, sub, ["4x5", "picopixel"], 145)
        c.text(sf[1], 108, 21, font = sf[0], color = DIM, align = "center")
    else:
        icon(c, "BALL", "", 0, 0, 1)
        hf = fit(c, head_n, ["5x7", "4x5"], 62)
        c.text(hf[1], 32, 11, font = hf[0], color = GOOD, align = "center")
        sf = fit(c, sub_n, ["4x5", "picopixel"], 62)
        c.text(sf[1], 32, 23, font = sf[0], color = DIM, align = "center")

# --------------------------------------------------------------- page: news
def news(c, ctx):
    d = fetch_news(ctx)
    if not d["ok"]:
        fail_screen(c, d)
        return
    items = d["items"]
    if len(items) == 0:
        where = "FOR " + d["scope"] if d["scope"] != "NFL" else "RIGHT NOW"
        quiet_screen(c, "ALL QUIET", "NO NEW PLAYER NEWS " + where, "ALL QUIET", "NO NEWS YET")
        return
    n = len(items)
    now_m = ctx.now.unix // 60
    idx = now_m % n
    c.fill("black")
    if c.width < 128:
        news_narrow(c, items[idx], now_m)
        return
    # FANTASY shows on every frame of the rotation or on none of them.
    show_word = True
    for it in items:
        rx = news_meta(c, it, n, n, now_m, False)
        k = KIND[it["kind"]]
        word = k[0] if 24 + pill_w(c, k[0]) - 1 <= rx else k[1]
        if 24 + 37 + pill_w(c, word) - 1 > rx:
            show_word = False
    news_wide(c, items[idx], idx, n, now_m, show_word)

def news_wide(c, it, idx, n, now_m, show_word):
    k = KIND[it["kind"]]
    rail(c, k[2])
    x = news_meta(c, it, idx + 1, n, now_m, True)
    chip_row(c, k[0] if 24 + pill_w(c, k[0]) - 1 <= x else k[1], k[2], x, show_word)

    # The kind's icon at 2x in the left zone (x 10..31), centred on y 19.
    icon_centered(c, k[3], k[2], 21, 19)

    # Text zone x 34..181 (148 px). A headline that fits one line lets the
    # name use 10x16; a longer one gets two lines under a 9x12-or-smaller
    # name. "MISERABLE SHOWING IN WEEK 1 LOSS" is exactly 148 px in 4x5,
    # which is why the zone starts at 34 and not 35.
    tx, tw = 34, 148
    if it["name"] == "":
        lines = wrap(c, it["head"], "5x7", tw, 3)
        for i in range(len(lines)):
            c.text(lines[i], tx, 9 + i * 8, font = "5x7", color = INK)
        return
    forms = name_forms(it["name"], True)
    head = strip_subject(it["head"], forms[3], True)
    one = c.text_width(head, "4x5") <= tw
    nm = pick_name(c, forms, tw, one)
    c.text(nm[0], tx, 8, font = nm[1], color = INK)
    bottom = 8 + INKH[nm[1]] - 1
    if nm[1] == "10x16" and c.text_width(head, "5x7") <= tw:
        c.text(head, tx, 25, font = "5x7", color = INK)
        return
    start = bottom + 3 if nm[1] == "10x16" else bottom + 2
    lines = wrap(c, head, "4x5", tw, (27 - start) // 6 + 1)
    for i in range(len(lines)):
        c.text(lines[i], tx, start + i * 6, font = "4x5", color = INK)

def news_narrow(c, it, now_m):
    k = KIND[it["kind"]]
    # Header y 0..6: the icon at 1x, the short pill, the age on the right.
    d = icon_dims(k[3], False)
    icon(c, k[3], k[2], 0, 0 if d[1] >= 7 else 1, 1)
    age = ago(now_m - it["mins"]) if it["mins"] != None else ""
    px = d[0] + 2
    pill(c, k[1], k[2], px, 0)
    if age != "" and px + pill_w(c, k[1]) - 1 <= 63 - c.text_width(age, "4x5") - 3:
        c.text(age, 63, 1, font = "4x5", color = DIM, align = "right")

    # The last name as big as it fits, then the headline in 4x5 lines.
    if it["name"] == "":
        lines = wrap(c, it["head"], "4x5", 63, 4)
        for i in range(len(lines)):
            c.text(lines[i], 0, 8 + i * 6, font = "4x5", color = INK)
        return
    forms = name_forms(it["name"], True)
    nm = pick_last(c, forms, 64)
    c.text(nm[1], 0, 8, font = nm[0], color = INK)
    start = 8 + INKH[nm[0]] + 1
    head = strip_subject(it["head"], forms[3], False)
    lines = wrap(c, head, "4x5", 63, (27 - start) // 6 + 1)
    for i in range(len(lines)):
        c.text(lines[i], 0, start + i * 6, font = "4x5", color = INK if i == 0 else DIM)

# --------------------------------------------------------------- page: wire
def wire(c, ctx):
    d = fetch_wire(ctx)
    if not d["ok"]:
        fail_screen(c, d)
        return
    ps = d["players"]
    if len(ps) == 0:
        pos = "" if d["want"] == "ALL" else d["want"] + " "
        quiet_screen(c, "WIRE IS QUIET", "NO TRENDING " + pos + d["kind"] + " IN THE LAST 24H",
                     "QUIET", "NO " + pos + d["kind"])
        return
    idx = (ctx.now.unix // 60) % len(ps)
    c.fill("black")
    if c.width >= 128:
        wire_wide(c, d, ps[idx], idx, len(ps))
    else:
        wire_narrow(c, d, ps[idx], idx, len(ps))

def wire_wide(c, d, p, idx, n):
    adds = d["kind"] == "ADDS"
    color = C_BOOM if adds else C_BUST
    rail(c, color)
    parts = [[str(idx + 1) + "/" + str(n), DIM]]
    if d["week"] > 0:
        parts.append(["WEEK " + str(d["week"]), DIM])
    if d["want"] != "ALL":
        parts.append([d["want"] + " ONLY", INK])
    x = meta_right(c, parts, "", True)
    chip_row(c, "WAIVER " + d["kind"], color, x, True)

    icon_centered(c, "FIRE" if adds else "ICE", color, 21, 17)

    # Name hero in y 8..22, centred when a smaller face wins.
    tx, tw = 34, 148
    nm = pick_name(c, p["forms"], tw, True)
    c.text(nm[0], tx, 8 + (15 - INKH[nm[1]]) // 2, font = nm[1], color = INK)

    # Bottom row y 25..31: position pill, team, the count, owned % right.
    # Worst case "[DEF] WSH +955K ADDS" ends at x 122 and "100% OWNED" is
    # 43 px, so it starts at x 139 - the two never meet.
    pw = pill(c, p["pos"], POS_COLOR.get(p["pos"], "#B0BCCB"), tx, 25)
    bx = tx + pw + 3
    c.text(p["team"], bx, 26, font = "4x5", color = INK)
    bx += c.text_width(p["team"], "4x5") + 5
    cnt = ("+" if adds else "") + compact(p["count"]) + " " + d["kind"]
    c.text(cnt, bx, 26, font = "4x5", color = color)
    bx += c.text_width(cnt, "4x5")
    if p["pct"] >= 0:
        ro = str(p["pct"]) + "% OWNED"
        if 181 - c.text_width(ro, "4x5") + 1 > bx + 4:
            c.text(ro, 181, 26, font = "4x5", color = DIM, align = "right")

def wire_narrow(c, d, p, idx, n):
    adds = d["kind"] == "ADDS"
    color = C_BOOM if adds else C_BUST
    icon(c, "FIRE" if adds else "ICE", color, 0, 0, 1)
    pill(c, d["kind"], color, 9, 0)
    c.text(str(idx + 1) + "/" + str(n), 63, 1, font = "4x5", color = DIM, align = "right")

    nm = pick_last(c, p["forms"], 64)
    c.text(nm[1], 0, 9 + (12 - INKH[nm[0]]) // 2, font = nm[0], color = INK)

    pw = pill(c, p["pos"], POS_COLOR.get(p["pos"], "#B0BCCB"), 0, 25)
    c.text(p["team"], pw + 2, 26, font = "4x5", color = INK)
    cnt = ("+" if adds else "") + compact(p["count"])
    c.text(cnt, 63, 26, font = "4x5", color = color, align = "right")
