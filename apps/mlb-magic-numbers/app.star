# MLB Magic Numbers (128x32)
#
# Each division and wild-card race, if the season ended today: the leader's
# magic number to clinch, and every other team's elimination number (how
# many combined losses/leader-wins puts them out). Scoped to one league at
# a time (AL/NL dropdown input) rather than both - the 8-page platform
# limit doesn't stretch to 3 divisions + wild card for both leagues at
# once. 8 pages: intro, a leaders summary (all 3 division leaders with
# their division AND playoff-clinch magic numbers side by side), 4
# "chasers" pages (every non-division-leader in the league, pooled across
# all 3 divisions and sorted by record - not grouped by division), a
# home-field page (which division leader is on track for home field
# advantage through the whole league playoffs), and a bye page (which two
# of the three are on track for a first-round bye). Both of those last two
# are 3-team races among the leaders, not the simple 2-team cutoffs
# everything else here uses, and are each other's mirror image - see
# homefield_status and bye_status for the math. A dedicated wild-card
# standings page was here too but is dropped for now - easy to re-add
# later, same pattern as everything else.
#
# DESIGN. A dark scoreboard. Black ground; a gold league chip up top with
# the page title beside it and quiet gray column labels; then three
# team-colored pills down the left with their numbers on black to the
# right. The numbers are the hero - 5x7, in their status color - and the
# outcomes that matter most (clinched, eliminated, and anything within
# URGENT_THRESHOLD of either) become filled pills so they jump out across
# a room. 6 px of padding on both sides keeps the app from merging with
# its neighbors in the scroll stream. Every page is the same 7 px header
# plus three 7 px rows on 1 px gaps (y 8/16/24), so text on every pill
# gets an even 1 px of padding top and bottom - four rows plus a header
# can't do that in 32 px, which is why the 12 chasers take 4 pages of 3.
#
# Data from MLB's own public Stats API (statsapi.mlb.com) - no key required.
# Sibling app to mlb-playoff-picture - same standings endpoint. Division
# magic/elimination numbers come precomputed (magicNumber/
# eliminationNumberDivision); the wild-card magic number doesn't (the API
# only ever precomputes a magic number for a division leader, never for a
# wild-card cutoff), so it's derived here with the same formula MLB itself
# uses - see SEASON_GAMES below for the verification against live data.

# Same source/format as mlb-playoff-picture (lists, not single hexes) - a
# couple of teams get a 2nd option so badge_color() has a genuinely dark
# choice to fall back to instead of a near-white or neon primary color.
TEAM_COLORS = {
    108: ["#BA0021"],  # LAA
    109: ["#A71930"],  # AZ
    110: ["#DF4601"],  # BAL
    111: ["#BD3039"],  # BOS
    112: ["#0E3386"],  # CHC
    113: ["#C6011F"],  # CIN
    114: ["#E31937"],  # CLE
    115: ["#333366", "#C4CED4"],  # COL
    116: ["#FA4616"],  # DET
    117: ["#F4911E"],  # HOU
    118: ["#004687"],  # KC
    119: ["#005A9C"],  # LAD
    120: ["#AB0003"],  # WSH
    121: ["#FF5910"],  # NYM
    133: ["#EFB21E"],  # ATH
    134: ["#FDB827"],  # PIT
    135: ["#FFC425"],  # SD
    136: ["#005C5C"],  # SEA
    137: ["#FD5A1E"],  # SF
    138: ["#C41E3A"],  # STL
    139: ["#8FBCE6"],  # TB
    140: ["#003278"],  # TEX
    141: ["#134A8E"],  # TOR
    142: ["#D31145"],  # MIN
    143: ["#E81828"],  # PHI
    144: ["#CE1141"],  # ATL
    145: ["#27251F"],  # CWS
    146: ["#00A3E0"],  # MIA
    147: ["#0C2340"],  # NYY
    158: ["#12284B"],  # MIL
}

# division.id per MLB Stats API, keyed by league then by page name.
DIVISION_IDS = {
    "AL": {"east": 201, "central": 202, "west": 200},
    "NL": {"east": 204, "central": 205, "west": 203},
}

LEAGUE_IDS = {"AL": 103, "NL": 104}

# Standard 162-game season - the magic/elimination number formula is
# (season games + 1) - leaderWins - rivalLosses, where "rival" is whoever
# the number is being computed against, not the team it belongs to.
# Verified against live data both directions: matches the API's own AL East
# magicNumber exactly (163 - Rays' 75 wins - 2nd-place Yankees' 55 losses =
# 33), and independently matches a live wildCardEliminationNumber (163 -
# WC3 Orioles' 61 wins - WC4 Rangers' 64 losses = 38, exactly what the API
# reports as Rangers' own wildCardEliminationNumber) - same arithmetic,
# just read from whichever side of the cutoff you're standing on.
SEASON_GAMES = 162

CLINCH_COLOR = "#2ECC71"
MAGIC_COLOR = "#2ECC71"
ELIM_COLOR = "#E74C3C"
PLAYOFF_COLOR = "#3498DB"
TRAGIC_COLOR = "#F39C12"

# A magic/tragic number this low means it's basically about to happen - it
# looked identical to a lazy mid-teens number before this. See draw_value.
URGENT_THRESHOLD = 5

# The one purely decorative gold accent in the app - the league chip, the
# intro sparkles, and the glint on a clinched pill - so it never gets
# mistaken for a status color like CLINCH/ELIM/TRAGIC.
SPARKLE_COLOR = "#FFD700"
SEAM_RED = "#E0302A"

# ---------- layout ----------

PAD_L = 6    # first lit column
PAD_R = 121  # last lit column (128 - 1 - 6)

# Header y 0-6, then three 7 px rows on 1 px gaps: 8-14, 16-22, 24-30.
ROW_TOPS = [8, 16, 24]
ROWS_PER_PAGE = 3

# Team pills run PAD_L..TEAM_X1. The two number columns are centered on
# COL_A / COL_B: the widest thing either can hold is the ELIM pill ('ELIM'
# is 19 px in 4x5, 23 px with padding), which centered on 110 spans 99-121
# (flush with PAD_R) and centered on 84 spans 73-95 - leaving a 3 px gap
# after the team pill and 3 px between the two columns.
TEAM_X1 = 69
COL_A = 84
COL_B = 110

LABEL_COLOR = "#6E7A94"
DASH_COLOR = "#505050"

NODATA_BG = "#0B0C12"
NODATA_TITLE = "#E8B04A"
NODATA_SUB = "#6A7090"
NODATA_FONTS = ["10x16", "6x8", "5x7", "4x5"]
FONTH = {"10x16": 16, "7x12": 12, "6x8": 8, "5x7": 7, "4x5": 5}

BASEBALL = """
.....WWWWW.....
...WWWWWWWWW...
..WRWWWWWWWRW..
.WWRWWWWWWWRWW.
.WWWRWWWWWRWWW.
WWWWRWWWWWRWWWW
WWWWWRWWWRWWWWW
WWWWWRWWWRWWWWW
WWWWWRWWWRWWWWW
WWWWRWWWWWRWWWW
.WWWRWWWWWRWWW.
.WWRWWWWWWWRWW.
..WRWWWWWWWRW..
...WWWWWWWWW...
.....WWWWW.....
"""

# ---------- color helpers (ported from mlb-playoff-picture) ----------

def brightness(hex_color):
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return (r * 299 + g * 587 + b * 114) // 1000

def badge_color(team_id):
    # Darkest of the team's colors - full-row badges carry white text by
    # default, so a near-white option (e.g. LAD's white) would be
    # unreadable; the darkest color gives the best contrast while still
    # reading as the team's color.
    colors = TEAM_COLORS.get(team_id, ["#444444"])
    best = colors[0]
    best_brightness = brightness(best)
    for color in colors:
        b = brightness(color)
        if b < best_brightness:
            best = color
            best_brightness = b
    return best

def text_color_for(team_id):
    # badge_color already picks each team's darkest option, but a few teams
    # (TB's Columbia Blue, HOU/ATH/PIT/SD's gold/orange) have no dark option
    # at all - white text on those reads weak. Fall back to black above this
    # brightness instead of assuming white always works.
    if brightness(badge_color(team_id)) > 150:
        return "black"
    return "white"

def text_color_on(bg):
    # Same flip for the status pills, at 140 rather than 150: CLINCH_COLOR
    # (brightness 146) reads far better with black digits than white.
    if brightness(bg) > 140:
        return "black"
    return "white"

# ---------- input ----------

def league_choice(ctx):
    v = ctx.inputs.get("league", "AL")
    if v == None or v not in LEAGUE_IDS:
        return "AL"
    return v

# ---------- network (keyless) ----------

def fetch_standings(standings_type, season):
    return http.get(
        "https://statsapi.mlb.com/api/v1/standings",
        params = {"leagueId": "103,104", "season": str(season), "standingsTypes": standings_type},
        ttl_seconds = 7200,
    )

def fetch_teams():
    return http.get(
        "https://statsapi.mlb.com/api/v1/teams",
        params = {"sportId": "1"},
        ttl_seconds = 2592000,
    )

def team_nickname_map():
    resp = fetch_teams()
    m = {}
    if resp["status_code"] != 200:
        return m
    for t in resp["json"].get("teams", []):
        m[t["id"]] = t.get("teamName", "")
    return m

# ---------- standings ----------

def sort_by_division_rank(teams):
    # Small manual sort (<=5 items) - Starlark has no sorted(..., key=...).
    # Don't trust teamRecords' own array order for this - it happened to
    # match divisionRank in earlier testing, but that's not a documented
    # guarantee from the API, just what one data pull looked like.
    items = list(teams)
    n = len(items)
    for i in range(n):
        for j in range(n - 1 - i):
            r1 = int(items[j].get("divisionRank", "999"))
            r2 = int(items[j + 1].get("divisionRank", "999"))
            if r1 > r2:
                items[j], items[j + 1] = items[j + 1], items[j]
    return items

def division_block(records, division_id):
    for block in records:
        if block.get("division", {}).get("id") == division_id:
            return sort_by_division_rank(block.get("teamRecords", []))
    return []

def wildcard_block(records, league_id):
    for block in records:
        if block.get("league", {}).get("id") == league_id:
            # Already excludes division winners and sorts by wildCardRank
            # ascending (see mlb-playoff-picture's wildcard_top3, same block).
            return block.get("teamRecords", [])
    return []

# The API only includes "magicNumber" at all for the division's current
# leader - everyone else gets an eliminationNumberDivision instead (the
# same stat sports pages print as "E#"). "ELIM" (no countdown left) renders
# as a red pill via draw_value, not text, once a team's actually out.
def magic_status(t):
    # Only ever called by the leaders page, so "WON" (division-specific,
    # since this is the DIV column) is safe to hardcode here rather than
    # needing a page-level override like playoff_magic's "IN" does below.
    if t.get("divisionChamp", False):
        return "WON", CLINCH_COLOR
    magic = t.get("magicNumber")
    if magic != None:
        return str(magic), MAGIC_COLOR
    elim = t.get("eliminationNumberDivision", "-")
    if elim == "E":
        return "ELIM", ELIM_COLOR
    if elim in ("-", "", None):
        return "-", "gray"
    return str(elim), "gray"

# The "tragic number" (the elimination number, read as bad news instead of
# good) is the same wildCardEliminationNumber field already used elsewhere
# for the "E" badge - this only fires before that, while it's still a
# countdown rather than "E". When it's the closer of the two outcomes, it's
# the more newsworthy number: showing a hopeful magic number for a team
# that's actually closer to being eliminated than to clinching is
# misleading. magic_color is whichever color the caller would otherwise
# have used for the plain magic number (division pages and the wild-card
# page use different ones), so this stays neutral about who's calling it.
def magic_or_tragic(t, magic, magic_color):
    tragic = t.get("wildCardEliminationNumber", "-")
    if tragic in ("-", "", None, "E"):
        return str(magic), magic_color
    tragic_val = int(tragic)
    if tragic_val < magic:
        return str(tragic_val), TRAGIC_COLOR
    return str(magic), magic_color

# A division leader's OWN magic number (from magic_status) only covers the
# division route. This is their fallback route: how close they are to
# clinching at least a wild-card spot instead, racing their wins against
# that league's current wild-card rank-4 (same rank-4-rival formula the
# now-removed dedicated wild-card page used). "clinched" (not divisionChamp)
# is checked here since a team can lock up a playoff spot via wild card
# without having clinched the division outright.
# Also used for the division pages' non-leader teams - which meant this
# needed its own elimination check (wildCardEliminationNumber == "E"), not
# just clinched-or-magic-number: a team genuinely out of the wild-card race
# would otherwise still get a plausible-looking countdown from the formula
# below, since that formula alone has no way to represent "already out."
# Deliberately NOT given the tragic-number treatment below - this is also
# what the leaders page calls directly, which should stay pure magic-number.
def playoff_magic(t, wc_teams):
    if t.get("clinched", False):
        return "IN", CLINCH_COLOR
    if t.get("wildCardEliminationNumber", "-") == "E":
        return "ELIM", ELIM_COLOR
    if len(wc_teams) < 4:
        return "-", "gray"
    wins = t.get("wins", 0)
    rival_losses = wc_teams[3].get("losses", 0)
    magic = SEASON_GAMES + 1 - wins - rival_losses
    if magic <= 0:
        return "IN", CLINCH_COLOR
    return str(magic), PLAYOFF_COLOR

# The division pages' wrapper around playoff_magic - same clinch/eliminated
# terminal states pass straight through, but a plain magic number gets
# checked against the tragic number too. Kept separate from playoff_magic
# itself so the leaders page (which calls that directly) is unaffected.
def playoff_or_tragic(t, wc_teams):
    text, color = playoff_magic(t, wc_teams)
    if text == "IN" or text == "ELIM" or text == "-":
        return text, color
    return magic_or_tragic(t, int(text), color)

def sort_by_pct(teams):
    # Small manual sort - Starlark has no sorted(..., key=...). Winning
    # percentage, not raw win count - teams don't all have the same number
    # of games played, so pct is the fair "record" comparison across
    # divisions (wins alone would bias toward whoever's played more games).
    items = list(teams)
    n = len(items)
    for i in range(n):
        for j in range(n - 1 - i):
            p1 = float(items[j].get("winningPercentage", "0"))
            p2 = float(items[j + 1].get("winningPercentage", "0"))
            if p1 < p2:
                items[j], items[j + 1] = items[j + 1], items[j]
    return items

def league_leaders(div_records, league):
    ids = DIVISION_IDS[league]
    leaders = []
    for key in ("east", "central", "west"):
        teams = division_block(div_records, ids[key])
        if teams:
            leaders.append(teams[0])  # teamRecords is already divisionRank-sorted
    return leaders

def league_chasers(div_records, league):
    # Every non-division-leader in the league, pooled across all 3
    # divisions and sorted by record - the leaders page already covers
    # each division's #1 team, so these pages are everyone else.
    ids = DIVISION_IDS[league]
    combined = []
    for key in ("east", "central", "west"):
        combined += division_block(div_records, ids[key])[1:]
    return sort_by_pct(combined)

# Home field advantage throughout the league's playoffs goes to whichever
# division leader ends up with the best overall record - a genuine 3-team
# race among the leaders, not a fixed 2-team cutoff like division or wild
# card, and not something the API precomputes at all. Still built from the
# same validated magic/elimination formula, just applied against BOTH other
# leaders: a team needs to out-finish each of them individually to lock up
# the #1 seed, so its magic number is the LARGER of the two pairwise magic
# numbers (the harder of the two to secure) - once that clears, the easier
# one has necessarily cleared too, since the team's own wins count toward
# both simultaneously while each rival's losses only help their own pairing.
# Symmetrically, it's eliminated as soon as EITHER single pairing goes to
# zero, so its elimination number is the SMALLER of the two. Verified
# against live AL data before wiring this in: the current leader (best
# record) gets a plain magic number, while the other two - both plausibly
# closer to being knocked out of the race than to winning it - correctly
# get tragic numbers instead.
def homefield_status(x, others):
    x_wins = x.get("wins", 0)
    x_losses = x.get("losses", 0)
    magics = [SEASON_GAMES + 1 - x_wins - o.get("losses", 0) for o in others]
    elims = [SEASON_GAMES + 1 - o.get("wins", 0) - x_losses for o in others]
    magic = max(magics)
    elim = min(elims)
    if magic <= 0:
        return "IN", CLINCH_COLOR
    if elim <= 0:
        return "ELIM", ELIM_COLOR
    if elim < magic:
        return str(elim), TRAGIC_COLOR
    return str(magic), MAGIC_COLOR

# First-round byes go to the TOP 2 of the 3 division leaders (2022+ format:
# #1/#2 seed get a bye, #3 hosts a Wild Card series) - the mirror image of
# homefield_status's math, not the same computation despite both being
# 3-team races among the leaders. Home field needs to out-finish BOTH other
# leaders (magic = MAX, elim = MIN of the pairwise numbers); a bye only
# needs to out-finish AT LEAST ONE of them (missing a bye means finishing
# last among the 3), so here it flips: magic = MIN (only the easier of the
# two pairwise races needs to be secured), elim = MAX (both pairwise races
# have to fail before a bye is truly out of reach). Verified against live
# AL data and 3 synthetic cases (two clear leaders both already "IN" with
# the straggler "ELIM", a 3-way dead heat, and a team mathematically unable
# to avoid finishing last) before wiring this in.
def bye_status(x, others):
    x_wins = x.get("wins", 0)
    x_losses = x.get("losses", 0)
    magics = [SEASON_GAMES + 1 - x_wins - o.get("losses", 0) for o in others]
    elims = [SEASON_GAMES + 1 - o.get("wins", 0) - x_losses for o in others]
    magic = min(magics)
    elim = max(elims)
    if magic <= 0:
        return "IN", CLINCH_COLOR
    if elim <= 0:
        return "ELIM", ELIM_COLOR
    if elim < magic:
        return str(elim), TRAGIC_COLOR
    return str(magic), MAGIC_COLOR

# A magic-side (non-tragic) team isn't remotely in elimination danger, so it
# sorts above any real E# - "IN" (already clinched, no elimination number
# even applies) sorts above that, and "ELIM" sorts to the very bottom below
# every real number. Only used for the home-field page (sort_by_e_number) -
# the bye page keeps the simpler two-bucket order below.
def e_number_sort_key(text, color):
    if text == "IN":
        return 999999
    if text == "ELIM":
        return -1
    if color == TRAGIC_COLOR:
        return int(text)
    return 999998

# ---------- drawing ----------

def fit_text(c, text, font, maxw):
    # Truncates on actual pixel width, not a guessed character count - long
    # nicknames like "Diamondbacks" would otherwise run into the numbers.
    if c.text_width(text, font) <= maxw:
        return text
    for i in range(len(text), 0, -1):
        candidate = text[:i] + ".."
        if c.text_width(candidate, font) <= maxw:
            return candidate
    return ".."

def centered_x(c, text, font, cx):
    return cx - c.text_width(text, font) // 2

def draw_header(c, league, title, col_a, col_b):
    # Gold league chip (2 px side padding, 1 px top/bottom), the page title
    # 3 px after it in white, and the column labels in quiet gray centered
    # over the columns they name.
    w = c.text_width(league, "4x5")
    c.round_rect(PAD_L, 0, PAD_L + w + 3, 6, 1, fill = SPARKLE_COLOR)
    c.text(league, PAD_L + 2, 1, font = "4x5", color = "black")
    c.text(title, PAD_L + w + 7, 1, font = "4x5", color = "white")
    c.text(col_a, centered_x(c, col_a, "4x5", COL_A), 1, font = "4x5", color = LABEL_COLOR)
    c.text(col_b, centered_x(c, col_b, "4x5", COL_B), 1, font = "4x5", color = LABEL_COLOR)

def draw_pill(c, cx, y, text, bg, glint = False):
    # A 7 px status pill, text centered with even padding. Single digits get
    # 3 px a side so a lone "4" still reads as a pill, not a square.
    w = c.text_width(text, "4x5")
    pad = 3 if w < 8 else 2
    pw = w + pad * 2
    x0 = cx - pw // 2
    x1 = x0 + pw - 1
    c.round_rect(x0, y, x1, y + 6, 1, fill = bg)
    c.text(text, x0 + pad, y + 1, font = "4x5", color = text_color_on(bg))

    # A tiny gold glint in the pill's own top-right corner (never outside
    # its own pixels, so it's safe under any row spacing) celebrates an
    # actual clinch - "IN"/"WON" only, not the merely-close pills.
    if glint:
        c.pixel(x1, y, SPARKLE_COLOR)
        c.pixel(x1 - 1, y, SPARKLE_COLOR)
        c.pixel(x1, y + 1, SPARKLE_COLOR)

def draw_value(c, cx, y, text, color):
    # ELIM/IN/WON render as filled pills (red/green), not colored text -
    # much more visually distinct at a glance. A plain number becomes a pill
    # in its own status color once it's down to URGENT_THRESHOLD or less -
    # the countdown isn't over yet, but it's close enough to be the most
    # newsworthy thing on the row, and the color still previews which way
    # it's headed. "-" (no data / not applicable) is a quiet 3 px dash.
    if text in ("-", "", None):
        c.hline(cx - 1, y + 3, 3, DASH_COLOR)
    elif text == "ELIM":
        draw_pill(c, cx, y, text, ELIM_COLOR)
    elif text == "IN" or text == "WON":
        draw_pill(c, cx, y, text, CLINCH_COLOR, glint = True)
    elif color.startswith("#") and int(text) <= URGENT_THRESHOLD:
        draw_pill(c, cx, y, text, color)
    else:
        c.text(text, centered_x(c, text, "5x7", cx), y, font = "5x7", color = color)

def draw_team_pill(c, y, team_id, nickname):
    # 3 px of padding inside both ends; "GUARDIANS"/"NATIONALS" are 43 px in
    # 4x5, well inside the 58 px budget, but fit_text still guards it.
    c.round_rect(PAD_L, y, TEAM_X1, y + 6, 1, fill = badge_color(team_id))
    nick = fit_text(c, nickname.upper(), "4x5", TEAM_X1 - PAD_L - 5)
    c.text(nick, PAD_L + 3, y + 1, font = "4x5", color = text_color_for(team_id))

def draw_race_row(c, y, team_id, nickname, text, color):
    # playoff_or_tragic / the leader-race status functions give one result
    # per team, split across two columns: a magic number or IN lands in
    # column A with a dash in E#, and a tragic number or ELIM lands in E#
    # with a dash in column A. They're mutually exclusive, never both filled.
    draw_team_pill(c, y, team_id, nickname)
    if text == "ELIM" or color == TRAGIC_COLOR:
        draw_value(c, COL_A, y, "-", "gray")
        draw_value(c, COL_B, y, text, color)
    else:
        draw_value(c, COL_A, y, text, color)
        draw_value(c, COL_B, y, "-", "gray")

def message(c, title, sub, title_color):
    # The shared no-data card: a title from the NODATA_FONTS ladder over a
    # dim 4x5 sub, the pair centered as one block so they can never overlap.
    c.fill(NODATA_BG)
    font = NODATA_FONTS[-1]
    for f in NODATA_FONTS:
        if c.text_width(title, f) <= PAD_R - PAD_L + 1:
            font = f
            break
    top = (c.height - (FONTH[font] + 3 + 5)) // 2
    c.text(title, centered_x(c, title, font, c.width // 2), top, font = font, color = title_color)
    c.text(sub, centered_x(c, sub, "4x5", c.width // 2), top + FONTH[font] + 3, font = "4x5", color = NODATA_SUB)

def offline(c):
    message(c, "MLB OFFLINE", "RETRYING SOON", NODATA_TITLE)

def no_standings(c):
    # Not an error - the season just hasn't produced standings yet.
    message(c, "NO STANDINGS YET", "BACK ON OPENING DAY", "white")

def draw_chasers_page(c, ctx, league, page_index):
    # 12 non-leader teams per league, 3 per page - chasers pages 1-4 are
    # just sequential chunks of one combined, record-sorted list, not tied
    # to any particular division.
    c.clear()

    div_resp = fetch_standings("regularSeason", ctx.now.year)
    wc_resp = fetch_standings("wildCard", ctx.now.year)
    if div_resp["status_code"] != 200 or wc_resp["status_code"] != 200:
        offline(c)
        return

    chasers = league_chasers(div_resp["json"].get("records", []), league)
    start = page_index * ROWS_PER_PAGE
    teams = chasers[start:start + ROWS_PER_PAGE]
    if not teams:
        no_standings(c)
        return

    wc_teams = wildcard_block(wc_resp["json"].get("records", []), LEAGUE_IDS[league])[:5]
    nicknames = team_nickname_map()

    draw_header(c, league, "CHASERS", "WC", "E#")
    for i in range(len(teams)):
        t = teams[i]
        team_id = t.get("team", {}).get("id", -1)
        wc_text, wc_color = playoff_or_tragic(t, wc_teams)
        draw_race_row(c, ROW_TOPS[i], team_id, nicknames.get(team_id, "???"), wc_text, wc_color)

def draw_leaders_page(c, ctx, league):
    c.clear()

    div_resp = fetch_standings("regularSeason", ctx.now.year)
    wc_resp = fetch_standings("wildCard", ctx.now.year)
    if div_resp["status_code"] != 200 or wc_resp["status_code"] != 200:
        offline(c)
        return

    div_records = div_resp["json"].get("records", [])
    wc_teams = wildcard_block(wc_resp["json"].get("records", []), LEAGUE_IDS[league])[:5]

    leaders = league_leaders(div_records, league)

    if len(leaders) < 3:
        no_standings(c)
        return

    nicknames = team_nickname_map()

    # Rows go WC magic number low to high - whoever's closest to clinching a
    # playoff spot (not necessarily the division) leads the page. Already
    # clinched ("IN") sorts first (nothing left to chase); the "-"/"ELIM"
    # cases shouldn't come up for an actual division leader, but sort last
    # defensively rather than crashing on int(text) if they ever did.
    def wc_sort_key(text):
        if text == "IN":
            return -1
        if text in ("-", "ELIM"):
            return 999999
        return int(text)

    rows = []
    for t in leaders:
        team_id = t.get("team", {}).get("id", -1)
        div_text, div_color = magic_status(t)
        playoff_text, playoff_color = playoff_magic(t, wc_teams)
        rows.append((wc_sort_key(playoff_text), team_id, div_text, div_color, playoff_text, playoff_color))

    # Small manual sort (<=3 items) - Starlark has no sorted(..., key=...).
    n = len(rows)
    for i in range(n):
        for j in range(n - 1 - i):
            if rows[j][0] > rows[j + 1][0]:
                rows[j], rows[j + 1] = rows[j + 1], rows[j]

    draw_header(c, league, "LEADERS", "DIV", "WC")
    for i in range(n):
        _key, team_id, div_text, div_color, playoff_text, playoff_color = rows[i]
        y = ROW_TOPS[i]
        draw_team_pill(c, y, team_id, nicknames.get(team_id, "???"))
        draw_value(c, COL_A, y, div_text, div_color)

        # playoff_magic is shared with the chasers pages (via
        # playoff_or_tragic), which should keep "IN" - only relabel it here.
        if playoff_text == "IN":
            playoff_text = "WON"
        draw_value(c, COL_B, y, playoff_text, playoff_color)

# Shared by the home-field and bye pages - both are "3 division leaders,
# ranked by a pairwise magic/tragic computation" with the same visual
# layout (renders through draw_race_row, same as the chasers pages), the
# only difference is which status_fn does the ranking (homefield_status vs
# bye_status) and what the left column header says.
def draw_leader_race_page(c, ctx, league, title, col_label, status_fn, sort_by_e_number = False):
    c.clear()

    div_resp = fetch_standings("regularSeason", ctx.now.year)
    if div_resp["status_code"] != 200:
        offline(c)
        return

    leaders = league_leaders(div_resp["json"].get("records", []), league)
    if len(leaders) < 3:
        no_standings(c)
        return

    nicknames = team_nickname_map()

    if sort_by_e_number:
        # Home field: E# high to low - safest team (or already-clinched)
        # first, most endangered (or already eliminated) last.
        rows = []
        for i in range(len(leaders)):
            x = leaders[i]
            others = [leaders[j] for j in range(len(leaders)) if j != i]
            team_id = x.get("team", {}).get("id", -1)
            text, color = status_fn(x, others)
            rows.append((e_number_sort_key(text, color), team_id, nicknames.get(team_id, "???"), text, color))
        n = len(rows)  # small manual sort (<=3 items) - Starlark has no sorted(..., key=...)
        for i in range(n):
            for j in range(n - 1 - i):
                if rows[j][0] < rows[j + 1][0]:
                    rows[j], rows[j + 1] = rows[j + 1], rows[j]
        rows = [(team_id, nickname, text, color) for _key, team_id, nickname, text, color in rows]
    else:
        # Bye: whichever leader(s) sit on the magic-number side go on top,
        # not whichever division happened to be listed first.
        rows = []
        tragic_rows = []
        for i in range(len(leaders)):
            x = leaders[i]
            others = [leaders[j] for j in range(len(leaders)) if j != i]
            team_id = x.get("team", {}).get("id", -1)
            text, color = status_fn(x, others)
            row = (team_id, nicknames.get(team_id, "???"), text, color)
            if text == "ELIM" or color == TRAGIC_COLOR:
                tragic_rows.append(row)
            else:
                rows.append(row)
        rows += tragic_rows

    draw_header(c, league, title, col_label, "E#")
    for i in range(len(rows)):
        team_id, nickname, text, color = rows[i]
        draw_race_row(c, ROW_TOPS[i], team_id, nickname, text, color)

# ---------- pages ----------

def sparkle(c, x, y):
    # A 3x3 gold plus centered on (x, y).
    c.pixel(x, y - 1, SPARKLE_COLOR)
    c.pixel(x - 1, y, SPARKLE_COLOR)
    c.pixel(x, y, SPARKLE_COLOR)
    c.pixel(x + 1, y, SPARKLE_COLOR)
    c.pixel(x, y + 1, SPARKLE_COLOR)

def intro(c, ctx):
    league = league_choice(ctx)
    c.clear()

    # A 15 px baseball on the left with a couple of gold sparkles - the
    # "magic" - and a left-aligned lockup beside it. "MAGIC NUMBERS" is
    # 91 px in 7x12, so starting at x 28 it ends at 118, inside PAD_R.
    # (It used to read "MAGIC #", but 7x12 has no "#" glyph at all.)
    c.sprite(BASEBALL, PAD_L + 2, 8, legend = {"W": "white", "R": SEAM_RED})
    sparkle(c, 23, 4)
    c.pixel(PAD_L + 1, 26, SPARKLE_COLOR)
    c.pixel(24, 25, SPARKLE_COLOR)

    x = 28
    c.text("MAGIC NUMBERS", x, 2, font = "7x12", color = "white")

    w = c.text_width(league, "4x5")
    c.round_rect(x, 17, x + w + 3, 23, 1, fill = SPARKLE_COLOR)
    c.text(league, x + 2, 18, font = "4x5", color = "black")
    c.text("PLAYOFF RACE", x + w + 7, 18, font = "4x5", color = "gray")

    c.text("UPDATES EVERY 2 HOURS", x, 26, font = "picopixel", color = "#555555")

def leaders(c, ctx):
    draw_leaders_page(c, ctx, league_choice(ctx))

def chasers1(c, ctx):
    draw_chasers_page(c, ctx, league_choice(ctx), 0)

def chasers2(c, ctx):
    draw_chasers_page(c, ctx, league_choice(ctx), 1)

def chasers3(c, ctx):
    draw_chasers_page(c, ctx, league_choice(ctx), 2)

def chasers4(c, ctx):
    draw_chasers_page(c, ctx, league_choice(ctx), 3)

def homefield(c, ctx):
    draw_leader_race_page(c, ctx, league_choice(ctx), "HOME FIELD", "HFA", homefield_status, sort_by_e_number = True)

def bye(c, ctx):
    draw_leader_race_page(c, ctx, league_choice(ctx), "BYE", "BYE", bye_status)
