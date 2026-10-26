''
' NEON-CASTER - GL/TEXTART.BI
' =============================================================================
' TEXT ART's characters and palettes (GL/TEXTART.BM; the post shader in
' GL/OPENGL.BM draws with them).
'

' TEXT ART (SETTINGS > EFFECTS, OpenGL): the view drawn in characters, a
' cell each. Four sets - ASCII (QB64PE's font, emptiest to fullest), ANSI
' (DOS's shades and half blocks), PETSCII (the Commodore's quarter blocks,
' checks and slants: square cells) and MATRIX (falling code) - in a picture
' TA_W x TA_H (taPix, made by TextArtFont on the main thread, sent by SUB
' _GL as taTex): set s's characters on rows (s - 1) * 16, each 8 x 16, then
' under them, a pixel row each, what each one is: its ink in each quarter
' (row 64 + s - 1, RGBA = top left, top right, bottom left, bottom right)
' and its use (row 68 + s - 1: R a step of the ramp, G a shape, B how full
' it is next to the set's fullest).
CONST TA_SETS = 4, TA_MAX = 32, TA_W = 256, TA_H = 128
CONST TA_ASCII = 1, TA_ANSI = 2, TA_PETSCII = 3, TA_MATRIX = 4, TA_MAC = 5, TA_RETRO = 6 ' (RETRO: big pixels in a palette, dithered - the shader's retro(); (MAC has no characters: 1 bit, dithered - TaMacPass)
' Its colours (SET_ASCIICOL): AUTO is each set's own - ASCII its own colour,
' ANSI DOS's 16, PETSCII the C64's 16, MATRIX green rain (TC_RAIN)
CONST TC_AUTO = 0, TC_OWN = 1, TC_GREEN = 2, TC_AMBER = 3, TC_WHITE = 4, TC_DOS = 5, TC_C64 = 6, TC_RAIN = 7
DIM SHARED taPix(TA_W * TA_H - 1) AS _UNSIGNED LONG, taMade AS INTEGER, taTex AS _UNSIGNED LONG
' MAC: the view drawn small into taMacTarg (MAC_LINES / size lines - 342 at 16, the Macintosh's),
' read back (taMacIn: SUB _GL), dithered by Atkinson's rule (taMacErr: the game's thread) into taMacOut, sent as taMacTex
' - at most MAC_MAXW x MAC_MAXH: the tables are made once, here (a REDIM in SUB _GL stopped the game: QB64PE's runtime isn't for two threads)
CONST MAC_LINES = 5472, MAC_MAXW = 1280, MAC_MAXH = 480
DIM SHARED taMacTarg AS LONG, taMacTex AS _UNSIGNED LONG, taMacW AS LONG, taMacH AS LONG, taMacTexW AS LONG, taMacTexH AS LONG
DIM SHARED taMacState AS INTEGER, taMacInW AS LONG, taMacInH AS LONG, taMacOutW AS LONG, taMacOutH AS LONG ' (0 waiting, 1 pixels in - to dither, 2 dithered - to send)
DIM SHARED taMacIn(MAC_MAXW * MAC_MAXH) AS _UNSIGNED LONG, taMacOut(MAC_MAXW * MAC_MAXH) AS _UNSIGNED LONG, taMacErr(MAC_MAXW * (MAC_MAXH + 2) + 2) AS SINGLE
DIM SHARED taMacLift(255) AS SINGLE ' (a grey's brightness, lifted: the game is darker than a Mac's desk)
' PRESETS: TEXT ART's settings at once, each a line of the console's textart words - neon-caster/textart-presets.txt
' (the game's), then saves/textart-presets.txt (yours: SAVE AS PRESET, textart save NAME); a name of yours the same as
' one of the game's takes its place. NAME = words, or just the words (its name, then, in capitals)
CONST TA_PRESETS = 64, TA_IDS = 12
' RETRO's palettes: every .gpl in neon-caster/palettes/ and saves/palettes/ (yours: one of the same name takes the
' game's place), by name - the file's, less ".gpl" and its "(N)" - and the one in use, up to 256 colours, for SUB _GL
CONST RETRO_PALS = 160
DIM SHARED retroPals$(RETRO_PALS), retroPalPath$(RETRO_PALS), retroPalCount(RETRO_PALS) AS INTEGER, retroPalsN AS INTEGER, retroScanned AS INTEGER, retroPalWant$
DIM SHARED retroRamp AS INTEGER, retroLo AS SINGLE, retroHi AS SINGLE ' (a palette of one hue - a Game Boy's, 1 bit: matched by brightness, from its darkest to its brightest)
DIM SHARED retroPal(255) AS _UNSIGNED LONG, retroN AS INTEGER, retroVer AS LONG, retroSent AS LONG, retroLoadedK AS INTEGER, retroTex AS _UNSIGNED LONG
DIM SHARED taPreName$(TA_PRESETS), taPreWords$(TA_PRESETS), taPreMine(TA_PRESETS) AS INTEGER, taPreN AS INTEGER, taPreLoaded AS INTEGER, taQuiet AS INTEGER
DIM SHARED taCount(TA_SETS) AS INTEGER, taPal(1, 15) AS _UNSIGNED LONG ' (how many characters each set has; DOS's and the C64's colours)

' DOS's 16 (CGA/EGA's) and the C64's 16 (Pepto's measurements)
taPal(0, 0) = &HFF000000~& : taPal(0, 1) = &HFF0000AA~& : taPal(0, 2) = &HFF00AA00~& : taPal(0, 3) = &HFF00AAAA~&
taPal(0, 4) = &HFFAA0000~& : taPal(0, 5) = &HFFAA00AA~& : taPal(0, 6) = &HFFAA5500~& : taPal(0, 7) = &HFFAAAAAA~&
taPal(0, 8) = &HFF555555~& : taPal(0, 9) = &HFF5555FF~& : taPal(0, 10) = &HFF55FF55~& : taPal(0, 11) = &HFF55FFFF~&
taPal(0, 12) = &HFFFF5555~& : taPal(0, 13) = &HFFFF55FF~& : taPal(0, 14) = &HFFFFFF55~& : taPal(0, 15) = &HFFFFFFFF~&
taPal(1, 0) = &HFF000000~& : taPal(1, 1) = &HFFFFFFFF~& : taPal(1, 2) = &HFF68372B~& : taPal(1, 3) = &HFF70A4B2~&
taPal(1, 4) = &HFF6F3D86~& : taPal(1, 5) = &HFF588D43~& : taPal(1, 6) = &HFF352879~& : taPal(1, 7) = &HFFB8C76F~&
taPal(1, 8) = &HFF6F4F25~& : taPal(1, 9) = &HFF433900~& : taPal(1, 10) = &HFF9A6759~& : taPal(1, 11) = &HFF444444~&
taPal(1, 12) = &HFF6C6C6C~& : taPal(1, 13) = &HFF9AD284~& : taPal(1, 14) = &HFF6C5EB5~& : taPal(1, 15) = &HFF959595~&
