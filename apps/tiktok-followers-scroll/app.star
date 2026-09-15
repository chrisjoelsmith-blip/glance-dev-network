# TikTok Followers
#
# A live follower counter for one TikTok account. TikTok has no public
# API, but every profile page carries its stats in embedded JSON, so the
# app fetches https://www.tiktok.com/@<user> with a browser user agent
# and cuts the numbers out with find(). Followers, likes, videos, display
# name and the verified flag all come from one request.
#
# DESIGN. TikTok's own look is the panel's native look: a black ground,
# white type, and the cyan / red "glitch" offset behind the note logo.
# Page one is the follower count as the hero, every digit, with commas,
# in the largest font that fits - a counter that reads 95.7M is a
# summary, a counter that reads 95,737,977 is a counter. The note logo
# stands at the left, drawn three times (cyan up-left, red down-right,
# white on top) so it is the real mark and not a monochrome stand-in.
# Beneath the hero: FOLLOWERS in cyan, and when the owner has set a goal,
# a red bar filling toward it with the goal named beside it. Page two is
# likes, with a heart in place of the note and the video count as the
# footnote. The 64 panel keeps the same bones: logo + handle in the top
# rows, the count as big as the panel allows (exact if it fits, compact
# if not), the label and goal along the bottom.
#
# Cadence: 600 s. Counts move by the minute, but a scrape of a page that
# size every few minutes from a shared host is asking to be blocked;
# ten minutes is the compromise. ttl matches refresh.

TT_CYAN = "#25F4EE"
TT_RED = "#FE2C55"
INK = "white"
DIM = "#6E7A94"
TRACK = "#2A2A2A"
OFFLINE = "#3C4043"

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
HEADERS = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"}
TTL = 600

# --------------------------------------------------------------- pixel art
# The note. 14 x 16. Drawn three times with offsets for the glitch.
NOTE = """
.........###..
.........#####
.........##.##
.........##..#
.........##...
.........##...
.........##...
.........##...
.........##...
..##.....##...
.###.....##...
##.......##...
##......###...
###....###....
.########.....
..#####.......
"""

# 7 x 9 for the 64 panel's header.
NOTE_SM = """
....##.
....###
....#.#
....#..
....#..
.#..#..
##..#..
##.##..
.####..
"""

HEART = """
..###....###..
.#####..#####.
##############
##############
##############
.############.
..##########..
...########...
....######....
.....####.....
......##......
.......#......
"""

HEART_SM = """
.##.##.
#######
#######
.#####.
..###..
...#...
"""

CHECK = """
....#
...##
#.##.
###..
.#...
"""

def glitch(c, art, x, y, off):
    """The TikTok mark: cyan shifted up-left, red shifted down-right,
    white on top. `off` is the shift in pixels (1 on 64, 2 on scroll)."""
    c.sprite(art, x - off, y - off, color = TT_CYAN)
    c.sprite(art, x + off, y + off, color = TT_RED)
    c.sprite(art, x, y, color = INK)

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
    """[font, clipped text] for the largest listed font that fits."""
    t = str(text)
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(t, f) <= maxw:
            pick = f
            break
    return [pick, clip(c, t, pick, maxw)]

FONTH = {"16x20": 20, "10x16": 16, "7x12": 12, "6x8": 8, "5x7": 7, "4x5": 5}

def message(c, head, sub):
    """The shared failure screen. head / sub are [wide, narrow] copy."""
    wide = c.width >= 128
    h = head[0] if wide else head[1]
    u = sub[0] if wide else sub[1]
    # Scroll copy stays inside the safe zone (x 10..181) even when a long
    # username is part of the line; 64 uses everything but the edge pixels.
    maxw = 172 if wide else c.width - 4
    hf = fit(c, h, ["5x7", "4x5"], maxw)
    c.text(hf[1], c.width // 2, 11, font = hf[0], color = "amber", align = "center")
    sf = fit(c, u, ["4x5", "picopixel"], maxw)
    c.text(sf[1], c.width // 2, 23, font = sf[0], color = DIM, align = "center")

# ------------------------------------------------------------ number tools
def digits(s):
    """Leading digits of a string as an int, or -1 if there are none."""
    t = str(s).strip()
    d = ""
    for ch in t.elems():
        if ch >= "0" and ch <= "9":
            d += ch
        else:
            break
    return int(d) if d != "" else -1

def compact(n):
    """95737977 -> 95.7M, 1234567 -> 1.2M, 45321 -> 45.3K, 999 -> 999.
    One decimal, dropped when the whole part has three digits (457M)."""
    if n < 1000:
        return str(n)
    for unit in [[1000000000, "B"], [1000000, "M"], [1000, "K"]]:
        if n >= unit[0]:
            tenths = (n * 10 + unit[0] // 2) // unit[0]
            whole, frac = tenths // 10, tenths % 10
            if whole >= 100:
                return str((n + unit[0] // 2) // unit[0]) + unit[1]
            return str(whole) + "." + str(frac) + unit[1]
    return str(n)

def parse_goal(s):
    """'100K', '1.5M', '250000' -> an int, or 0 when blank / unreadable."""
    t = str(s).strip().upper().replace(",", "")
    if t == "":
        return 0
    mult = 1
    if t.endswith("K"):
        mult, t = 1000, t[:-1]
    elif t.endswith("M"):
        mult, t = 1000000, t[:-1]
    elif t.endswith("B"):
        mult, t = 1000000000, t[:-1]
    parts = t.split(".")
    whole = digits(parts[0]) if parts[0] != "" else 0
    if whole < 0 or len(parts) > 2:
        return 0
    frac = 0
    if len(parts) == 2 and parts[1] != "":
        f = (parts[1] + "000")[:3]
        frac = digits(f)
        if frac < 0:
            return 0
        return whole * mult + frac * mult // 1000
    return whole * mult

# ------------------------------------------------------------------- feed
def field(body, key, start, quoted):
    """Value of "key":... after `start`. quoted=True reads up to the next
    quote, otherwise the run of digits. None if absent."""
    i = body.find('"' + key + '":', start)
    if i < 0:
        return None
    i = i + len(key) + 3
    if quoted:
        if body[i:i + 1] != '"':
            return None
        j = body.find('"', i + 1)
        return body[i + 1:j] if j > i else None
    return digits(body[i:i + 24])

def fetch_data(ctx):
    user = str(ctx.inputs.get("username", "")).strip()
    if user.startswith("@"):
        user = user[1:]
    user = user.strip().lower()
    if user == "":
        return {"ok": False, "head": ["SET A USERNAME", "NO USERNAME"],
                "sub": ["IN THIS APP'S SETTINGS", "SET ONE UP"]}
    at = "@" + user.upper()
    r = http.get("https://www.tiktok.com/@" + user, headers = HEADERS, ttl_seconds = TTL)
    status = r["status_code"]
    if status == 0:
        return {"ok": False, "head": ["TIKTOK OFFLINE", "OFFLINE"],
                "sub": ["RETRY IN 10 MIN", "RETRY SOON"]}
    if status == 404:
        return {"ok": False, "head": [at + " NOT FOUND", "NOT FOUND"],
                "sub": ["CHECK THE SPELLING", "CHECK NAME"]}
    if status != 200:
        return {"ok": False, "head": ["TIKTOK BLOCKED US", "BLOCKED"],
                "sub": ["HTTP " + str(status) + " - RETRY LATER", "RETRY LATER"]}
    body = r["body"]
    ui = body.find('"userInfo":')
    if ui < 0:
        # A 200 without the profile block: TikTok served a bot check or an
        # unknown-user page. The page's own status code tells them apart.
        sc = field(body, "statusCode", 0, False)
        if sc == 10221 or sc == 10202:
            return {"ok": False, "head": [at + " NOT FOUND", "NOT FOUND"],
                    "sub": ["CHECK THE SPELLING", "CHECK NAME"]}
        return {"ok": False, "head": ["TIKTOK BLOCKED US", "BLOCKED"],
                "sub": ["RETRY IN 10 MIN", "RETRY SOON"]}
    # statsV2 carries the exact counts as strings; stats rounds them.
    sv = body.find('"statsV2":', ui)
    followers = field(body, "followerCount", sv, True) if sv >= 0 else None
    likes = field(body, "heartCount", sv, True) if sv >= 0 else None
    videos = field(body, "videoCount", sv, True) if sv >= 0 else None
    followers = digits(followers) if followers != None else field(body, "followerCount", ui, False)
    likes = digits(likes) if likes != None else field(body, "heartCount", ui, False)
    videos = digits(videos) if videos != None else field(body, "videoCount", ui, False)
    if followers == None or followers < 0:
        return {"ok": False, "head": [at + " NOT FOUND", "NOT FOUND"],
                "sub": ["CHECK THE SPELLING", "CHECK NAME"]}
    # The user's own "verified" sits between userInfo and its stats block;
    # a later one would belong to some other object on the page.
    ver = body.find('"verified":true', ui)
    st = body.find('"stats":', ui)
    verified = ver >= 0 and (st < 0 or ver < st)
    goal = parse_goal(ctx.inputs.get("goal", ""))
    return {
        "ok": True, "at": at,
        "followers": followers,
        "likes": likes if likes != None and likes >= 0 else 0,
        "videos": videos if videos != None and videos >= 0 else 0,
        "verified": verified,
        "goal": goal,
    }

# ------------------------------------------------------------ shared bits
def handle(c, at, verified, x, y, maxw):
    """@NAME with the verified check after it. The check is 5 px plus a
    2 px gap, taken off the name's room first so it never gets pushed
    past maxw by a long name."""
    room = maxw - 7 if verified else maxw
    t = clip(c, at, "4x5", room)
    c.text(t, x, y, font = "4x5", color = INK)
    if verified:
        c.sprite(CHECK, x + c.text_width(t, "4x5") + 2, y, color = TT_CYAN)

def hero_count(c, n, x, y, maxw, fonts):
    """The exact count with commas in the largest font that fits; only
    when even the smallest listed font cannot hold it does it fall back to
    the compact form. Returns [font, text]."""
    exact = fmt.commas(n)
    for f in fonts:
        if c.text_width(exact, f) <= maxw:
            c.text(exact, x, y, font = f, color = INK)
            return [f, exact]
    short = compact(n)
    hf = fit(c, short, fonts, maxw)
    c.text(hf[1], x, y, font = hf[0], color = INK)
    return hf

def goal_bar(c, x0, x1, y, h, n, goal, label_font):
    """Red bar filling toward the goal, the goal named at the right. Turns
    cyan and says GOAL HIT once the count is past it."""
    hit = n >= goal
    word = ("GOAL " + compact(goal)) if not hit else "GOAL HIT"
    ww = c.text_width(word, label_font)
    c.text(word, x1, y, font = label_font, color = TT_CYAN if hit else DIM, align = "right")
    bx1 = x1 - ww - 3
    bw = bx1 - x0 + 1
    if bw < 6:
        return
    c.rect(x0, y, bx1, y + h - 1, fill = TRACK)
    fillw = bw if hit else (n * bw) // goal
    if fillw > 0:
        c.rect(x0, y, x0 + fillw - 1, y + h - 1, fill = TT_CYAN if hit else TT_RED)

def fail(c, d):
    c.fill("black")
    if c.width >= 128:
        c.rect(0, 0, 1, 31, fill = OFFLINE)
        glitch(c, NOTE_SM, 13, 2, 1)
    else:
        glitch(c, NOTE_SM, 1, 1, 1)
    message(c, d["head"], d["sub"])

# --------------------------------------------------------- page: followers
def followers(c, ctx):
    d = fetch_data(ctx)
    if not d["ok"]:
        fail(c, d)
        return
    c.fill("black")
    if c.width >= 128:
        followers_wide(c, d)
    else:
        followers_narrow(c, d)

def followers_wide(c, d):
    # Rail in TikTok red; the note at x 12..27 (with its offsets), y 6..25.
    c.rect(0, 0, 1, 31, fill = TT_RED)
    glitch(c, NOTE, 14, 8, 2)

    # Content column x 36..181 (146 px). Row 1: the handle.
    x0, x1 = 36, 181
    handle(c, d["at"], d["verified"], x0, 1, 90)

    # Hero: "95,737,977" is 169 px in 16x20 and 109 in 10x16, so the
    # eight-digit accounts land in 10x16 and anything under a million
    # ("123,456", 118 px) gets 16x20. The label band is y 27..31, so the
    # 20-tall face starts at y 7 (7..26) and the 16-tall one at y 9.
    exact = fmt.commas(d["followers"])
    f = "16x20" if c.text_width(exact, "16x20") <= x1 - x0 + 1 else "10x16"
    hero_count(c, d["followers"], x0, 7 if f == "16x20" else 9, x1 - x0 + 1,
               [f, "7x12"])

    # Label band y 27..31: FOLLOWERS in cyan, then the goal bar to the right.
    c.text("FOLLOWERS", x0, 27, font = "4x5", color = TT_CYAN)
    if d["goal"] > 0:
        goal_bar(c, x0 + 45 + 6, x1, 27, 5, d["followers"], d["goal"], "4x5")

def followers_narrow(c, d):
    # Header y 0..8: the small note with 1 px offsets at x 0..8, the
    # handle beside it, clipped to what is left.
    glitch(c, NOTE_SM, 1, 1, 1)
    handle(c, d["at"], d["verified"], 11, 2, 52)

    # Hero y 10..25: exact if it fits ("1,234,567" is 55 px in 7x12),
    # otherwise compact in 10x16 ("95.7M" 54 px).
    hero_count(c, d["followers"], 1, 10, 62, ["10x16", "7x12"])

    # Footer y 27..31: the label, and the goal percentage on the right.
    c.text("FOLLOWERS", 0, 27, font = "4x5", color = TT_CYAN)
    if d["goal"] > 0:
        if d["followers"] >= d["goal"]:
            c.text("HIT", 63, 27, font = "4x5", color = TT_CYAN, align = "right")
        else:
            p = (d["followers"] * 100) // d["goal"]
            c.text(str(p) + "%", 63, 27, font = "4x5", color = TT_RED, align = "right")

# ------------------------------------------------------------- page: likes
def likes(c, ctx):
    d = fetch_data(ctx)
    if not d["ok"]:
        fail(c, d)
        return
    c.fill("black")
    if c.width >= 128:
        likes_wide(c, d)
    else:
        likes_narrow(c, d)

def likes_wide(c, d):
    c.rect(0, 0, 1, 31, fill = TT_CYAN)
    glitch(c, HEART, 13, 10, 2)
    x0, x1 = 36, 181
    handle(c, d["at"], d["verified"], x0, 1, 90)
    exact = fmt.commas(d["likes"])
    f = "16x20" if c.text_width(exact, "16x20") <= x1 - x0 + 1 else "10x16"
    hero_count(c, d["likes"], x0, 7 if f == "16x20" else 9, x1 - x0 + 1, [f, "7x12"])
    c.text("LIKES", x0, 27, font = "4x5", color = TT_RED)
    # Footnote: how many videos earned them. "1,503 VIDEOS" right-aligned.
    v = fmt.commas(d["videos"]) + " VIDEOS"
    c.text(clip(c, v, "4x5", 80), x1, 27, font = "4x5", color = DIM, align = "right")

def likes_narrow(c, d):
    glitch(c, HEART_SM, 1, 2, 1)
    handle(c, d["at"], d["verified"], 11, 2, 52)
    hero_count(c, d["likes"], 1, 10, 62, ["10x16", "7x12"])
    c.text("LIKES", 0, 27, font = "4x5", color = TT_RED)
    # "1.5K VID" is the widest footnote that shares the row with LIKES.
    v = compact(d["videos"]) + " VID"
    c.text(clip(c, v, "4x5", 36), 63, 27, font = "4x5", color = DIM, align = "right")
