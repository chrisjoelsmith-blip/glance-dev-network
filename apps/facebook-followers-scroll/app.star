# Facebook Page Followers
#
# A live follower counter for one public Facebook Page. The Graph API
# wants a token and the page itself refuses anything that is not a
# logged-in browser, but Facebook's own Page Plugin (the embeddable
# "like box") is served to anyone and prints the page's name, its
# verified badge and the exact follower count. One request, no key.
#
# DESIGN. Facebook blue on black. The "f" mark sits at the left in its
# rounded blue tile, drawn with a round_rect and a sprite so it is crisp
# at both sizes and costs no asset. The page's NAME is on the panel, not
# just the handle, because Facebook resolves an unknown vanity name to
# whatever page it thinks you meant - a viewer must be able to see whose
# count this is. The hero is the count with commas in the largest font
# that fits; FOLLOWERS in blue beneath it, the page ID in dim on the right
# so the name and the address are both present. The 64 panel keeps the
# tile and name in the top rows and gives the rest to the number.
#
# Cadence: 600 s with a matching ttl. The plugin is light (44 KB) but a
# shared host hitting it every minute is how pools get throttled.

FB_BLUE = "#1877F2"
FB_DIM = "#0E3F80"
INK = "white"
DIM = "#6E7A94"
OFFLINE = "#3C4043"

PLUGIN = "https://www.facebook.com/plugins/page.php"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
HEADERS = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"}
TTL = 600

# --------------------------------------------------------------- pixel art
# The f, 7 x 12, for the 20 px tile on scroll.
F_BIG = """
...####
..##...
..##...
######.
..##...
..##...
..##...
..##...
..##...
..##...
..##...
..##...
"""

# The f, 4 x 6, for the 9 px tile on 64.
F_SM = """
.###
.#..
###.
.#..
.#..
.#..
"""

CHECK = """
....#
...##
#.##.
###..
.#...
"""

def tile(c, x, y, big):
    """The Facebook mark: a rounded blue square with the f low-right, the
    way the real one sits. 20 px on scroll, 9 px on 64."""
    if big:
        c.round_rect(x, y, x + 19, y + 19, 4, fill = FB_BLUE)
        c.sprite(F_BIG, x + 7, y + 6, color = INK)
    else:
        c.round_rect(x, y, x + 8, y + 8, 2, fill = FB_BLUE)
        c.sprite(F_SM, x + 3, y + 2, color = INK)

# ------------------------------------------------------------- text tools
def clip(c, text, font, maxw):
    t = str(text)
    if c.text_width(t, font) <= maxw:
        return t
    for k in range(len(t), 0, -1):
        if c.text_width(t[:k], font) <= maxw:
            return t[:k]
    return ""

def clip_words(c, text, font, maxw):
    """clip(), backed up to the last whole word unless that loses more
    than 30% of what fit."""
    t = clip(c, text, font, maxw)
    if t == str(text):
        return t
    sp = t.rfind(" ")
    if sp > 0 and sp * 10 >= len(t) * 7:
        return t[:sp]
    return t

def fit(c, text, fonts, maxw):
    t = str(text)
    pick = fonts[len(fonts) - 1]
    for f in fonts:
        if c.text_width(t, f) <= maxw:
            pick = f
            break
    return [pick, clip(c, t, pick, maxw)]

def message(c, head, sub):
    """The shared failure screen. head / sub are [wide, narrow] copy;
    scroll copy stays inside the safe zone."""
    wide = c.width >= 128
    h = head[0] if wide else head[1]
    u = sub[0] if wide else sub[1]
    maxw = 172 if wide else c.width - 4
    hf = fit(c, h, ["5x7", "4x5"], maxw)
    c.text(hf[1], c.width // 2, 11, font = hf[0], color = "amber", align = "center")
    sf = fit(c, u, ["4x5", "picopixel"], maxw)
    c.text(sf[1], c.width // 2, 23, font = sf[0], color = DIM, align = "center")

def ents(s):
    t = str(s)
    t = t.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    return t.replace("&quot;", '"').replace("&#39;", "'").replace("&#039;", "'").replace("&nbsp;", " ")

# ------------------------------------------------------------ number tools
def digits(s):
    """Leading digits of a string as an int, or -1 if there are none."""
    d = ""
    for ch in str(s).strip().elems():
        if ch >= "0" and ch <= "9":
            d += ch
        else:
            break
    return int(d) if d != "" else -1

def compact(n):
    """28715561 -> 28.7M, 66189 -> 66.2K, 999 -> 999."""
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

# ------------------------------------------------------------------- feed
def clean_page(raw):
    """What the user typed -> the path segment after facebook.com/. A pasted
    URL loses its scheme in transit (the colon ends the value), so the
    leftovers 'www.facebook.com/nasa' and 'facebook.com/nasa' are handled,
    as are a leading @ and a trailing slash."""
    t = str(raw).strip()
    for pre in ["https://", "http://", "www.facebook.com/", "facebook.com/",
                "m.facebook.com/", "web.facebook.com/"]:
        if t.lower().startswith(pre):
            t = t[len(pre):]
    if t.startswith("@"):
        t = t[1:]
    q = t.find("?")
    if q >= 0:
        t = t[:q]
    return t.strip("/").strip()

def count_before(body, marker):
    """Digits and commas immediately before `marker` ('28,715,561' from
    '...>28,715,561 followers<'), as an int. -1 if absent."""
    i = body.find(marker)
    if i < 0:
        return -1
    j = i
    for k in range(i - 1, i - 20, -1):
        if k < 0:
            break
        ch = body[k]
        if (ch >= "0" and ch <= "9") or ch == ",":
            j = k
        else:
            break
    if j == i:
        return -1
    return digits(body[j:i].replace(",", ""))

def page_name(body):
    """The page's display name: the text of the header link back to the
    page. The same link also wraps the profile picture, so the first
    match whose body is text (no tag) wins."""
    pos = 0
    for i in range(6):
        a = body.find('ref=embed_page" target="_blank">', pos)
        if a < 0:
            return ""
        s = a + len('ref=embed_page" target="_blank">')
        e = body.find("</a>", s)
        if e < 0:
            return ""
        inner = body[s:e]
        if inner.find("<") < 0 and inner.strip() != "":
            return ents(inner.strip())
        pos = e
    return ""

def fetch_data(ctx):
    page = clean_page(ctx.inputs.get("page", ""))
    if page == "":
        return {"ok": False, "head": ["SET A PAGE ID", "NO PAGE ID"],
                "sub": ["IN THIS APP'S SETTINGS", "ADD ONE"]}
    # The setting asks for the numeric page ID, shown as "ID 54971236771";
    # a name from the URL (nasa) still works and shows as "@NASA".
    at = "ID " + page if page.isdigit() else "@" + page.upper()
    params = {"href": "https://www.facebook.com/" + page, "tabs": "", "width": "340",
              "small_header": "false", "hide_cover": "true", "show_facepile": "false"}
    r = http.get(PLUGIN, params = params, headers = HEADERS, ttl_seconds = TTL)
    status = r["status_code"]
    if status == 0:
        return {"ok": False, "head": ["FACEBOOK OFFLINE", "OFFLINE"],
                "sub": ["RETRY IN 10 MIN", "RETRY SOON"]}
    if status != 200:
        return {"ok": False, "head": ["FACEBOOK BLOCKED US", "BLOCKED"],
                "sub": ["HTTP " + str(status) + " - RETRY LATER", "RETRY LATER"]}
    body = r["body"]
    n = count_before(body, " followers<")
    if n < 0:
        # The plugin renders an empty frame for a page it cannot show:
        # wrong name, an unpublished page, or a personal profile.
        return {"ok": False, "head": [at + " NOT FOUND", "NOT FOUND"],
                "sub": ["CHECK THE PAGE ID", "CHECK ID"]}
    name = page_name(body)
    if name == "":
        name = page
    return {
        "ok": True, "at": at, "name": name.upper(), "followers": n,
        "verified": body.find('aria-label="Verified Page"') >= 0,
    }

# ------------------------------------------------------------ shared bits
def title(c, name, verified, x, y, maxw):
    """The page name with the verified check after it; the check's 7 px
    come off the name's room first so a long name can never push it out."""
    room = maxw - 7 if verified else maxw
    t = clip_words(c, name, "4x5", room)
    c.text(t, x, y, font = "4x5", color = INK)
    if verified:
        c.sprite(CHECK, x + c.text_width(t, "4x5") + 2, y, color = FB_BLUE)

def hero_count(c, n, x, y, maxw, fonts):
    """Exact with commas in the largest font that fits; compact only when
    even the smallest listed font cannot hold the exact form."""
    exact = fmt.commas(n)
    for f in fonts:
        if c.text_width(exact, f) <= maxw:
            c.text(exact, x, y, font = f, color = INK)
            return [f, exact]
    hf = fit(c, compact(n), fonts, maxw)
    c.text(hf[1], x, y, font = hf[0], color = INK)
    return hf

def fail(c, d):
    c.fill("black")
    if c.width >= 128:
        c.rect(0, 0, 1, 31, fill = OFFLINE)
        tile(c, 12, 2, False)
    else:
        tile(c, 0, 0, False)
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
    # Rail and tile in Facebook blue; tile at x 12..31, y 6..25.
    c.rect(0, 0, 1, 31, fill = FB_BLUE)
    tile(c, 12, 6, True)

    # Column x 38..181 (144 px). Row 1: the page's name, word-clipped.
    # "NASA - NATIONAL AERONAUTICS AND SPACE ADMINISTRATION" is 250 px in
    # 4x5, so it ends up "NASA - NATIONAL AERONAUTICS AND" with the check.
    x0, x1 = 38, 181
    title(c, d["name"], d["verified"], x0, 1, x1 - x0 + 1)

    # Hero: "28,715,561" is 169 px in 16x20 and 109 in 10x16; under a
    # million ("123,456", 118 px) gets 16x20. The label band is y 27..31,
    # so the 20-tall face starts at y 7 and the 16-tall one at y 9.
    exact = fmt.commas(d["followers"])
    f = "16x20" if c.text_width(exact, "16x20") <= x1 - x0 + 1 else "10x16"
    hero_count(c, d["followers"], x0, 7 if f == "16x20" else 9, x1 - x0 + 1, [f, "7x12"])

    # Label band y 27..31: FOLLOWERS in blue, the page ID dim on the right.
    # "FOLLOWERS" is 45 px, so the ID gets what is left past a 6 px gap.
    c.text("FOLLOWERS", x0, 27, font = "4x5", color = FB_BLUE)
    c.text(clip(c, d["at"], "4x5", x1 - (x0 + 45 + 6) + 1), x1, 27, font = "4x5",
           color = DIM, align = "right")

def followers_narrow(c, d):
    # Header y 0..8: the 9 px tile, then the name clipped to x 11..63.
    tile(c, 0, 0, False)
    title(c, d["name"], d["verified"], 11, 2, 53)

    # Hero y 10..25: exact if it fits ("1,234,567" is 55 px in 7x12),
    # else compact in 10x16 ("28.7M" 54 px).
    hero_count(c, d["followers"], 1, 10, 62, ["10x16", "7x12"])

    # Footer y 27..31: the label. The page ID is left off here - the 15 px
    # beside FOLLOWERS only ever held "ID 5", and the name is in the header.
    c.text("FOLLOWERS", 0, 27, font = "4x5", color = FB_BLUE)
