# Steam Players — live counts + store glanceables (192x32).
#
# Data (no API key):
#   Players — ISteamUserStats/GetNumberOfCurrentPlayers
#   Name / price / F2P / genre / year — Store appdetails
#   Review % — Store appreviews summary
#
# Settings: type AppIDs into AppID 1–4 (none / blank = unused). One page only —
# a single AppID never pads the playlist with empty frames. Multiple AppIDs
# rotate on each refresh. Optional slots default to "none" so mobile can save
# without filling every field.
#
# Bitmap fonts are UPPERCASE ONLY.

PLAYERS_URL = "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/"
STORE_URL = "https://store.steampowered.com/api/appdetails"
REVIEWS_URL = "https://store.steampowered.com/appreviews/"

# Optional shortcuts if someone types a name instead of an AppID.
ALIASES = {
    "CS2": "730",
    "CSGO": "730",
    "DOTA": "570",
    "DOTA2": "570",
    "TF2": "440",
    "GTA5": "271590",
    "GTAV": "271590",
    "ELDEN": "1245620",
    "ELDENRING": "1245620",
    "RUST": "252490",
    "PUBG": "578080",
    "APEX": "1172470",
    "VALHEIM": "892970",
    "HELLDIVERS": "553850",
    "HELLDIVERS2": "553850",
    "BG3": "1086940",
    "CYBERPUNK": "1091500",
    "WARFRAME": "230410",
    "DESTINY2": "1085660",
    "STARDEW": "413150",
    "HADES": "1145360",
    "PALWORLD": "1623730",
}

KNOWN_NAMES = {
    "730": "COUNTER-STRIKE 2",
    "570": "DOTA 2",
    "440": "TEAM FORTRESS 2",
    "271590": "GRAND THEFT AUTO V",
    "1245620": "ELDEN RING",
    "252490": "RUST",
    "578080": "PUBG",
    "1172470": "APEX LEGENDS",
    "892970": "VALHEIM",
    "553850": "HELLDIVERS 2",
    "1086940": "BALDURS GATE 3",
    "1091500": "CYBERPUNK 2077",
    "230410": "WARFRAME",
    "1085660": "DESTINY 2",
    "413150": "STARDEW VALLEY",
    "1145360": "HADES",
    "1623730": "PALWORLD",
}

STEAM_BLUE = "#66C0F4"
STEAM_DIM = "#4B619B"
PRICE_GOLD = "#FFE566"
REVIEW_TEAL = "#5EEAD4"
REVIEW_NEG = "#FF6B6B"
WARN = "#FFB84D"
MUTED = "#8B9BB0"
BG = "#0B141C"
RULE = "#1B2838"
# Scroll safe zone: nothing within 8 px of either edge so neighbours never merge.
PAD = 8
# Steam mark, 13x13: a blue disc, then the piston (big joint, arm, small joint)
# knocked out of it in the background colour.
STEAM_DISC = [
    [0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
]
STEAM_PISTON = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]
LOGO = 13
MAX_GAMES = 4
ROTATE_EVERY = 120


def normalize_token(raw):
    t = str(raw).upper().strip()
    cleaned = ""
    for i in range(len(t)):
        ch = t[i]
        if ch >= "A" and ch <= "Z":
            cleaned += ch
        elif ch >= "0" and ch <= "9":
            cleaned += ch
    return cleaned


def resolve_appid(token):
    raw = str(token).strip()
    if raw == "":
        return None
    key = normalize_token(raw)
    if key == "" or key == "NONE" or key == "OFF":
        return None
    if key in ALIASES:
        return ALIASES[key]
    digits = True
    for i in range(len(raw)):
        ch = raw[i]
        if ch < "0" or ch > "9":
            digits = False
            break
    if not digits:
        return None
    n = raw
    for _ in range(8):
        if len(n) > 1 and n[0] == "0":
            n = n[1:]
        else:
            break
    if n == "" or n == "0":
        return None
    return n


def games_list(ctx):
    out = []
    seen = {}
    for key in ["game1", "game2", "game3", "game4"]:
        default = "730" if key == "game1" else "none"
        raw = ctx.inputs.get(key, default)
        if raw == None:
            raw = default
        appid = resolve_appid(raw)
        if appid == None or appid in seen:
            continue
        seen[appid] = True
        out.append(appid)

    # Legacy free-text favorites / custom from older builds.
    if len(out) == 0:
        for key in ["favorites", "custom"]:
            legacy = ctx.inputs.get(key, None)
            if legacy == None or str(legacy).strip() == "":
                continue
            for part in str(legacy).split(","):
                appid = resolve_appid(part)
                if appid == None or appid in seen:
                    continue
                seen[appid] = True
                out.append(appid)

    if len(out) == 0:
        out.append("730")
    if len(out) > MAX_GAMES:
        out = out[0:MAX_GAMES]
    return out


def active_slot(ctx, picks):
    total = len(picks)
    if total <= 1:
        return 0
    return (ctx.now.unix // ROTATE_EVERY) % total


def format_count(n):
    if n >= 1000000:
        whole = n // 1000000
        frac = (n % 1000000) // 100000
        if frac == 0:
            return str(whole) + "M"
        return str(whole) + "." + str(frac) + "M"
    if n >= 10000:
        return str(n // 1000) + "K"
    if n >= 1000:
        whole = n // 1000
        frac = (n % 1000) // 100
        if frac == 0:
            return str(whole) + "K"
        return str(whole) + "." + str(frac) + "K"
    return str(n)


def format_price(price):
    if price == None:
        return None
    discount = price.get("discount_percent", 0)
    if discount == None:
        discount = 0
    discount = int(discount)
    final = price.get("final", None)
    if final == None:
        return None
    dollars = int(final) // 100
    cents = int(final) % 100
    if cents == 0:
        tag = "$" + str(dollars)
    else:
        c = str(cents)
        if len(c) == 1:
            c = "0" + c
        tag = "$" + str(dollars) + "." + c
    if discount > 0:
        return tag + " -" + str(discount) + "%"
    return tag


def release_year(date_str):
    if date_str == None:
        return None
    t = str(date_str).strip()
    if len(t) < 4:
        return None
    year = t[len(t) - 4:len(t)]
    for i in range(4):
        ch = year[i]
        if ch < "0" or ch > "9":
            return None
    return year


def pick_genre(genres):
    if genres == None:
        return None
    for g in genres:
        desc = g.get("description", None)
        if desc == None:
            continue
        label = str(desc).upper().strip()
        if label == "" or label == "FREE TO PLAY" or label == "FREE-TO-PLAY":
            continue
        return label
    return None


def led_text(raw):
    # Bitmap fonts are A–Z / digits / basic punct only.
    t = str(raw).upper()
    out = ""
    for i in range(len(t)):
        ch = t[i]
        if ch >= "A" and ch <= "Z":
            out += ch
        elif ch >= "0" and ch <= "9":
            out += ch
        elif ch in " $%-+.,:#/'":
            out += ch
        elif ch == "&":
            out += "AND"
        else:
            # Collapse other junk to a single space.
            if len(out) == 0 or out[len(out) - 1] != " ":
                out += " "
    # Trim edges / squeeze double spaces.
    cleaned = ""
    for i in range(len(out)):
        ch = out[i]
        if ch == " " and (cleaned == "" or cleaned[len(cleaned) - 1] == " "):
            continue
        cleaned += ch
    for _ in range(4):
        if cleaned != "" and cleaned[len(cleaned) - 1] == " ":
            cleaned = cleaned[0:len(cleaned) - 1]
        else:
            break
    return cleaned


def fit_clip(c, text, maxw, fonts):
    # Prefer keeping the longest prefix that fits (avoid "OUTBRK"-style word chops).
    t = led_text(text)
    if t == "":
        return [fonts[len(fonts) - 1], ""]
    for font in fonts:
        if c.text_width(t, font) <= maxw:
            return [font, t]
    font = fonts[len(fonts) - 1]
    out = ""
    for i in range(len(t)):
        trial = out + t[i]
        if c.text_width(trial, font) > maxw:
            break
        out = trial
    # If we end mid-word with room for "..", leave a clean cut.
    if len(out) > 3 and out[len(out) - 1] != " ":
        trim = out
        for _ in range(8):
            if trim == "" or trim[len(trim) - 1] == " ":
                break
            if c.text_width(trim + "..", font) <= maxw:
                return [font, trim + ".."]
            trim = trim[0:len(trim) - 1]
    return [font, out]


def fetch_players(appid):
    r = http.get(
        PLAYERS_URL,
        headers = {
            "User-Agent": "(glance-steam-players, reyos86@github)",
            "Accept": "application/json",
        },
        params = {"appid": appid},
        ttl_seconds = 180,
    )
    if r["status_code"] != 200:
        return None
    j = r["json"]
    if j == None:
        return None
    resp = j.get("response", None)
    if resp == None or resp.get("result", 0) != 1:
        return None
    count = resp.get("player_count", None)
    if count == None:
        return None
    return int(count)


def fetch_store(appid):
    r = http.get(
        STORE_URL,
        headers = {
            "User-Agent": "(glance-steam-players, reyos86@github)",
            "Accept": "application/json",
        },
        params = {
            "appids": appid,
            "cc": "us",
            "filters": "basic,price_overview,genres,release_date",
        },
        ttl_seconds = 86400,
    )
    info = {
        "name": None,
        "is_free": False,
        "price": None,
        "genre": None,
        "year": None,
    }
    if r["status_code"] != 200:
        return info
    j = r["json"]
    if j == None:
        return info
    entry = j.get(appid, None)
    if entry == None or entry.get("success", False) != True:
        return info
    data = entry.get("data", None)
    if data == None:
        return info

    name = data.get("name", None)
    if name != None and str(name).strip() != "":
        info["name"] = led_text(name)

    info["is_free"] = data.get("is_free", False) == True
    info["price"] = format_price(data.get("price_overview", None))
    genre = pick_genre(data.get("genres", None))
    if genre != None:
        info["genre"] = led_text(genre)

    rel = data.get("release_date", None)
    if rel != None:
        info["year"] = release_year(rel.get("date", None))
    return info


def fetch_review_pct(appid):
    r = http.get(
        REVIEWS_URL + appid,
        headers = {
            "User-Agent": "(glance-steam-players, reyos86@github)",
            "Accept": "application/json",
        },
        params = {
            "json": "1",
            "purchase_type": "all",
            "num_per_page": "0",
            "language": "all",
        },
        ttl_seconds = 86400,
    )
    if r["status_code"] != 200:
        return None
    j = r["json"]
    if j == None:
        return None
    summary = j.get("query_summary", None)
    if summary == None:
        return None
    total = summary.get("total_reviews", 0)
    pos = summary.get("total_positive", 0)
    if total == None or pos == None:
        return None
    total = int(total)
    pos = int(pos)
    if total <= 0:
        return None
    return (pos * 100) // total


def game_name(appid, store_name):
    if store_name != None and store_name != "":
        return store_name
    if appid in KNOWN_NAMES:
        return KNOWN_NAMES[appid]
    return "APP " + appid


def review_chip(pct):
    # Steam-ish bands: positive / mixed / negative.
    if pct >= 70:
        return [str(pct) + "% POS", REVIEW_TEAL]
    if pct < 40:
        return [str(pct) + "% NEG", REVIEW_NEG]
    return [str(pct) + "% MIX", WARN]


def meta_chips(store, review_pct):
    chips = []
    if review_pct != None:
        chips.append(review_chip(review_pct))
    if store["is_free"]:
        chips.append(["F2P", PRICE_GOLD])
    elif store["price"] != None:
        chips.append([store["price"], PRICE_GOLD])
    if store["genre"] != None:
        chips.append([store["genre"], MUTED])
    if store["year"] != None:
        chips.append([store["year"], STEAM_DIM])
    return chips


def pack_chips(c, chips, maxw, font):
    out = []
    used = 0
    gap = 5
    for chip in chips:
        w = c.text_width(chip[0], font)
        need = w if used == 0 else used + gap + w
        if need > maxw:
            continue
        out.append(chip)
        used = need
    return out


def games(c, ctx):
    """Every AppID that is set, at once.

    The app used to have a single page that rotated between the configured
    games on a two-minute timer, so somebody who filled in four slots saw one
    arbitrary game and no sign of the other three -- and which one it was
    depended on the wall clock. This page answers "how are my games doing"
    without waiting, and DETAIL still gives each of them the full card.

    Four games cost eight requests (store name + player count each), which is
    the per-render cap. Store appdetails is cached 24h and shared with DETAIL,
    so later refreshes only pay for player counts. Reviews stay off this page
    so the first uncached render still fits."""
    picks = games_list(ctx)
    n = len(picks)
    c.fill(BG)
    if n == 0:
        c.text("NO APPIDS SET", c.width // 2, 8, font = "5x7", color = WARN,
               align = "center")
        c.text("ADD ONE FROM A STORE URL", c.width // 2, 19, font = "4x5",
               color = MUTED, align = "center")
        return

    rows = n if n < MAX_GAMES else MAX_GAMES
    fetched = []
    for i in range(rows):
        appid = picks[i]
        store = fetch_store(appid)
        count = fetch_players(appid)
        fetched.append([game_name(appid, store["name"]), count])

    # Identity column: the Steam mark over the wordmark.
    col_w = c.text_width("STEAM", "5x7")
    logo_x = PAD + (col_w - LOGO) // 2
    c.bitmap(STEAM_DISC, logo_x, 5, STEAM_BLUE)
    c.bitmap(STEAM_PISTON, logo_x, 5, BG)
    c.text("STEAM", PAD, 20, font = "5x7", color = STEAM_BLUE)
    rail = PAD + col_w + 4
    c.line(rail, 3, rail, 28, RULE)

    # Stacked rows, 8 px each; fewer than four are centred on the panel.
    top = (32 - rows * 8) // 2 + 1
    x = rail + 5
    right = c.width - PAD
    for i in range(rows):
        name = fetched[i][0]
        count = fetched[i][1]
        y = top + i * 8

        # Right side first: draw the value, then fit the name into what is left.
        if count != None:
            num = format_count(count)
            num_color = "white"
        else:
            # One game the API would not answer for is not a broken panel: the
            # row says so and the others still report.
            num = "--"
            num_color = WARN
        cw = c.text_width(num, "4x7")
        c.text(num, right, y, font = "4x7", color = num_color, align = "right")

        # fit_clip returns [font, text], not a string.
        fitted = fit_clip(c, name, right - cw - 6 - x, ["4x7", "4x5"])
        name_y = y + 1 if fitted[0] == "4x5" else y
        c.text(fitted[1], x, name_y, font = fitted[0], color = STEAM_BLUE)

def detail(c, ctx):
    picks = games_list(ctx)
    total = len(picks)
    slot = active_slot(ctx, picks)
    appid = picks[slot]

    store = fetch_store(appid)
    name = game_name(appid, store["name"])
    count = fetch_players(appid)
    review_pct = fetch_review_pct(appid)

    c.fill(BG)
    right = c.width - PAD

    # Hero zone — the live player count, labelled; amber dashes when Steam is down.
    if count != None:
        num = [format_count(count), "white"]
        label = ["PLAYING", STEAM_DIM]
    else:
        num = ["--", WARN]
        label = ["OFFLINE", WARN]
    # Fixed zone width so the title column does not jump between refreshes.
    zone_w = max(c.text_width("9.9M", "10x16"), c.text_width(num[0], "10x16"),
                 c.text_width(label[0], "4x5"))
    c.text(num[0], right, 4, font = "10x16", color = num[1], align = "right")
    c.text(label[0], right, 23, font = "4x5", color = label[1], align = "right")
    rail = right - zone_w - 5
    c.line(rail, 3, rail, 28, RULE)
    left_w = rail - 5 - PAD

    # Left zone — brand + slot, title, then review / price / genre / year.
    c.text("STEAM", PAD, 2, font = "5x7", color = STEAM_BLUE)
    if total > 1:
        c.text(str(slot + 1) + "/" + str(total),
               PAD + c.text_width("STEAM", "5x7") + 4, 4, font = "4x5",
               color = STEAM_DIM)

    fitted = fit_clip(c, name, left_w, ["6x8", "5x7", "4x7", "4x5"])
    c.text(fitted[1], PAD, 12, font = fitted[0], color = "white")

    chips = meta_chips(store, review_pct)
    if len(chips) > 0:
        chip_font = "5x7"
        shown = pack_chips(c, chips, left_w, chip_font)
        if len(shown) == 0:
            chip_font = "4x5"
            shown = pack_chips(c, chips, left_w, chip_font)
        x = PAD
        for chip in shown:
            c.text(chip[0], x, 22, font = chip_font, color = chip[1])
            x += c.text_width(chip[0], chip_font) + 5
    elif count == None:
        # Error screen second line: say what happens next, not just that it broke.
        hint = fit_clip(c, "RETRYING NEXT REFRESH", left_w, ["5x7", "4x5"])
        c.text(hint[1], PAD, 22, font = hint[0], color = MUTED)
