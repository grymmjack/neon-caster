''
' NEON-CASTER - WORLD/LIQUIDS.BI
' =============================================================================
' Liquids (chapter 22's [liquid]): water, poison, slime, lava and acid -
' the table of what each does to you.
'

' --- Liquids (chapter 22's [liquid] and [liquid depth]): a pool lying on
' a cell's floor, its surface liqZ - its depth above the floor. You see the
' floor through it (OpenGL: GLLiquids; the software renderer draws it as
' a surface, rippling - HeightColumn, LiquidAnimate), wade in it, and it
' does to you what its kind does (LiquidStep): LQ_ = the kinds, and for
' each how much of your speed you keep in it at LQ_FULL deep (lqSlow), how
' much it hurts (lqHurt, every lqEvery frames - 0: not at all), whether
' it eats your armor before you (lqAcid), how see-through it is (lqSee:
' OpenGL), its colour (lqR, lqG, lqB) and its name. In the level file, a
' map of one character a cell: . none, or the kind's letter (LQ_CHARS$);
' and its depth, in eighths, another (. = LQ_DEPTH). liqAny: any at all.
CONST LQ_WATER = 1, LQ_POISON = 2, LQ_SLIME = 3, LQ_LAVA = 4, LQ_ACID = 5, LQ_KINDS = 5
CONST LQ_CHARS$ = "wpsla", LQ_DEPTH = 3, LQ_FULL = 0.375
DIM SHARED liqKind(MAP_SIZE, MAP_SIZE) AS INTEGER, liqZ(MAP_SIZE, MAP_SIZE) AS SINGLE, liqAny AS INTEGER
DIM SHARED lqSlow(LQ_KINDS) AS SINGLE, lqHurt(LQ_KINDS) AS INTEGER, lqEvery(LQ_KINDS) AS INTEGER, lqAcid(LQ_KINDS) AS INTEGER
' Draining (drain X Y [SPEED] - a switch's trigger): every cell of the pool
' joined to X Y, going down DRAIN_SPEED eighths a second (or SPEED) till
' the floor's dry - its glow gone with it (DrainStart, DrainStep)
CONST MAX_DRAIN = 4096, DRAIN_SPEED = 4
DIM SHARED drainN AS INTEGER, drainX(MAX_DRAIN) AS INTEGER, drainY(MAX_DRAIN) AS INTEGER, drainS(MAX_DRAIN) AS SINGLE
DIM SHARED drainMark(MAP_SIZE, MAP_SIZE) AS _BYTE ' (DrainStart's flood fill: the cells reached)
' How see-through each liquid cell is ([liquid opacity] - set where it's
' placed, in the editor): liqOp 0 as its kind is made, 1-9 that many tenths
' more solid, 10 solid - you can't see the bottom (OpenGL: the software
' renderer draws liquids solid). In the file: . 0, 1-9, x 10
DIM SHARED lvlLiqORow$(MAP_SIZE - 1), liqOp(MAP_SIZE, MAP_SIZE) AS _BYTE, glLiqMurk AS SINGLE
' How wet the floors look - how much of OpenGL's mirror image shows in
' them (WET FLOORS): lvlWet the sector's (wetness = 0-9; -1, as made: each
' floor picture its own - concrete hardly, ice a lot), wetCell a cell's own
' ([floor wetness]: -1 the sector's, 0 dry - 9 soaked). FloorWet, the one
' a cell has; glFloorWet, the one being drawn (-1: its picture's)
CONST WET_STEP = 0.06 ' (each step's share of the mirror image: 9 is 0.54, wetter than ice)
DIM SHARED lvlWetRow$(MAP_SIZE - 1), wetCell(MAP_SIZE, MAP_SIZE) AS _BYTE, lvlWet AS INTEGER, glFloorWet AS SINGLE
lvlWet = -1 : glFloorWet = -1
DIM SHARED lqSee(LQ_KINDS) AS SINGLE, lqR(LQ_KINDS) AS INTEGER, lqG(LQ_KINDS) AS INTEGER, lqB(LQ_KINDS) AS INTEGER, lqName$(LQ_KINDS)
DIM SHARED lvlLiqRow$(MAP_SIZE - 1), lvlLiqDRow$(MAP_SIZE - 1), lqUsed(LQ_KINDS) AS INTEGER ' (lqUsed: that kind's in this level - LiquidAnimate moves only those)
DIM SHARED liqWait AS INTEGER, liqWas AS INTEGER, poisonTint AS INTEGER, liqTick AS LONG ' (frames to your next hurt in one; the kind you were in last frame; the green of poison, fading)
DIM SHARED liqBase(511, 511) AS SINGLE ' (the ripples: a height a texel, 0 to 1, that every liquid's picture is coloured from - MakeLiquidTex)
DIM SHARED liqTex(511, 511, LQ_KINDS) AS _UNSIGNED LONG, liqTexAt AS INTEGER ' (each liquid's picture, still - the software renderer moves it: LiquidAnimate)
' The liquids table (LQ_, above): what each one does to whoever wades
' in it. slow: how much of your speed you keep, LQ_FULL deep (less deep,
' less slowed); hurt every how many frames (0: never); acid: eats armor
' first; see: how see-through (OpenGL); its colour.
'           kind       name      slow  hurt every acid see   red  green blue
SetLiquid LQ_WATER,  "water",   0.6,  0,   0,    0,   0.55, 40,  110, 120
SetLiquid LQ_POISON, "poison",  0.8,  3,   40,   0,   0.4,  120, 60,  170
SetLiquid LQ_SLIME,  "slime",   0.4,  2,   45,   0,   0.25, 90,  220, 40
SetLiquid LQ_LAVA,   "lava",    0.5,  12,  20,   0,   0.05, 255, 90,  20
SetLiquid LQ_ACID,   "acid",    0.7,  4,   25,   -1,  0.35, 200, 240, 40
