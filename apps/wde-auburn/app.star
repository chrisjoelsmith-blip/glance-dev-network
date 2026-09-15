# War Eagle - an Auburn spirit card. (192x32)
#
#   [AU monogram]     WAR DAMN EAGLE      [tiger]
#                  AUBURN GO! GO! GO!
#
# Static: no inputs, nothing fetched, so `refresh` is hourly only because the
# panel has to ask for something.
#
# The AU monogram is drawn inline, from AU_HALF below: 32x32, the full height
# of the panel, in Auburn navy and orange. The logo is perfectly symmetrical,
# so only its left half is written out and the right half is its mirror image
# -- half the data, and the two sides cannot drift apart when it is edited.
#
# The tiger is drawn inline too, from TIGER below: 32x32 and drawn at 32x32
# -- the size it was authored, per the design guidelines -- from the top row,
# so like the monogram it fills the panel's full height. It is not
# symmetrical, so all 32 columns are written out.
#
# With both marks inline the app has no assets and no files to keep in step
# with the code.
#
# Both lines use text_stroke with a WHITE stroke, which is load-bearing
# rather than decorative. Auburn navy is #0C2341 -- luminance 31 against a
# near-black ground of 9 -- so the lower line would be close to invisible
# painted flat. The stroke gives every glyph an edge the panel can resolve,
# and the same treatment on the orange line keeps the two matched.

INK = "#08090D"          # near-black ground, per the contrast rule
ORANGE = "#E86100"       # upper line
NAVY = "#0C2341"         # lower line
STROKE = "#FFFFFF"       # the outline that makes both legible

PAD = 3
ART = 32                 # the inline tiger is 32x32
AU_W = 32                # the inline monogram is 32x32
GAP = 1                  # logo to text

# The left 16 columns of the 32x32 AU monogram; mirror() supplies the right 16.
# B navy, O orange, . transparent.
AU_HALF = [
    "..............OO",
    ".............OOB",
    ".............OBB",
    "OOOOOOOOOO..OOBB",
    "OBBBBBBBBO.OOBBB",
    "OBBBBBBBBO.OBBBB",
    "OOOBBBBOOOOOBBBB",
    "..OBBBBO..OBBBBO",
    "..OBBBBO.OOBBBOO",
    "..OBBBBOOOBBBBO.",
    "..OBBBBOOBBBBOO.",
    "..OBBBBOBBBBBO..",
    "..OBBBOOBBBBOO..",
    "..OBBBOBBBBBO...",
    "..OBBOOBBBBOOOOO",
    "..OBOOBBBBBBBBBB",
    "..OBOBBBBBBBBBBB",
    "..OOOBBBBOOOOOOO",
    "..OOBBBBOO......",
    "..OOBBBBO.......",
    "OOOBBBBOOOO.....",
    "OBBBBBBBBBO.....",
    "OBBBBBBBBBO.....",
    "OOOOOOOOOOO.....",
    "..OBBBBOO.......",
    "..OBBBBBOOOO....",
    "..OBBBBBBBBOOOOO",
    "..OOBBBBBBBBBBBB",
    "...OOOBBBBBBBBBB",
    ".....OOOBBBBBBBB",
    ".......OOOBBBBBB",
    ".........OOOOOOO",
]
AU_LEGEND = {"B": "#0B2341", "O": "#E86100"}


def mirror(half):
    """Each row followed by its own reverse: a half logo made whole."""
    rows = []
    for r in half:
        rev = ""
        for i in range(len(r) - 1, -1, -1):
            rev += r[i]
        rows.append(r + rev)
    return rows


AU = mirror(AU_HALF)

# The 32x32 tiger, every column. B navy, O orange, W white, . transparent.
TIGER = [
    "...........WW.WWWW..............",
    "...........WOWWOOOWW............",
    "..........WOOOOOOOOWWW..........",
    ".........WOOOOOOOBBBBW..........",
    "........WBBBBBOBBBBBWW..........",
    "........WWBBBBOOBBBBWWWWWWW.....",
    "...WWWWW..WBBOBBOBBW.WBBBBWW....",
    "..WWBBBWWWBBBBBBBBBBWWBWWBBWW...",
    "..WBBWBBBWBOOOOOBOOBBBBOOWBBW...",
    "..WBWOOOBBBOOBBOOBOOOOOBOWWBW...",
    "..WBWOOBOOOOBOBBBOOBOOBBOOWBW...",
    "..WBWOOBBOOOOBOOOOBOOOOBBOWBW...",
    "..WBBWOBOOBBBOBOOBOBBOOOBWBBW...",
    "..WWBBWBOOBWWBOOOOOBWBOOBOBWW...",
    "....WWBOOBWWWWBOOOBWWWBOOOBW....",
    "....WWBBOBWBBWBOOBWBBWBOOBBW....",
    "...WBBBOOBWBBBBOOBWBBBOOOBW.....",
    "..WWBWWBBOOOOOOOOOOOOOOBWBBWW...",
    "..WBBWBOOBBOOBOOOOBOOBBOBWBBW...",
    "..WBWOBBOBOOBWBBBBBBOOBBOWWBW...",
    "..WBWOBOBOOBWWWBBBWWBOBOOOWBW...",
    "..WBWWOOOOBBBWWWBWWWWBOOOOWBW...",
    "..WBBWWWOBBWWWWBBBWWWWBBOWBBW...",
    "..WWBBBWBWWWWWBBBBBWWWWBWBBWW...",
    "...WWWBBB.WWBBBBBOOBBBBWBBWW....",
    ".....WWWBBBBBBOBOWWOBWBBBWW.....",
    ".......WWWWBOOOOOWWWBWWWWW......",
    "..........WBOWWOWWWBBW..........",
    "..........WBBOOWWWBBW...........",
    "..........WWBBWWWWBW............",
    "...........WWBBBBBBW............",
    ".............WWWWWW.............",
]
TIGER_LEGEND = {"B": "#0B2341", "O": "#E86100", "W": "#FFFFFF"}

TOP = "WAR DAMN EAGLE"
BOTTOM = "AUBURN GO! GO! GO!"

# One font for both lines, the largest that fits the LONGER of the two. Sized
# per line instead, the two would land on different faces, and a chant whose
# second line has visibly chunkier letters reads as a mistake, not emphasis.
#
# The ladder starts at 6x9 on purpose: a size down from 8x10, so the chant sits
# a little lighter between the two logos. AUBURN GO! GO! GO! is 104px in it,
# comfortably inside the 120px between the art.
LINE_FONTS = ["6x9", "6x8", "5x7"]
FONT_H = {"6x9": 9, "6x8": 8, "5x7": 7}


def pick_font(c, avail):
    """Largest listed font that fits both lines AND can draw every character.

    The glyph check is not paranoia. 7x12 fits both lines comfortably, but it
    carries only 44 glyphs and has no "!", and this renderer draws a missing
    glyph as NOTHING rather than as a box: the panel showed "GO GO GO" with
    no warning from check, validate or the render. A zero-width "!" is the
    tell, so the ladder skips any face that cannot measure one.
    """
    for f in LINE_FONTS:
        if c.text_width("!", f) <= 0:
            continue
        if c.text_width(TOP, f) <= avail and c.text_width(BOTTOM, f) <= avail:
            return f
    return LINE_FONTS[len(LINE_FONTS) - 1]


def wde(c, ctx):
    c.fill(INK)

    # Art first, at the outer edges; the text is centred in what is left.
    c.sprite(AU, PAD, 0, legend = AU_LEGEND)
    c.sprite(TIGER, c.width - PAD - ART, 0, legend = TIGER_LEGEND)

    left = PAD + AU_W + GAP
    right = c.width - PAD - ART - GAP
    mid = (left + right) // 2
    font = pick_font(c, right - left)

    # Centre the pair of lines in the panel rather than pinning them: the
    # chosen face is not known until runtime, so the stack has to measure.
    h = FONT_H.get(font, 10)
    lead = 6
    y = (c.height - (2 * h + lead)) // 2
    c.text_stroke(TOP, mid, y, font = font, color = ORANGE,
                  stroke = STROKE, align = "center")
    c.text_stroke(BOTTOM, mid, y + h + lead, font = font, color = NAVY,
                  stroke = STROKE, align = "center")
