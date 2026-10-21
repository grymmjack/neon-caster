''
' NEON-CASTER - GAME/DECOS.BI
' =============================================================================
' Decorations: barrels, lamps, terminals, vending machines... - and the
' ones moved off their cell's middle.
'

' Decorations moved off their cell's middle (lvlNudge: x, y, then how far
' across and down, in eighths) - one in an alcove, against a wall
CONST MAX_NUDGES = 160
DIM SHARED lvlNumNudges AS INTEGER, lvlNudge(MAX_NUDGES, 5) AS SINGLE ' (5: which way it faces, flat - 0 it turns to face you, 1-4 east, south, west, north)
' --- Decorations: 1 barrel, 2 lamp, 3 plant, 4 terminal. You, monsters and
' bolts can't pass through them. Shoot one and it breaks: a barrel blows up
' at once (chapter 13), the others take a few hits (DecoMaxHP, chapter 23)
' and then collapse into the floor. ---
' DECO_ = settings for decorations: DECO_RADIUS is how far from its middle a
' decoration blocks you (in cells), DECO_BREAK_FRAMES how long a broken one
' takes to collapse
CONST MAX_DECO = 160, DECO_RADIUS = 0.3, DECO_BREAK_FRAMES = 14
DIM SHARED decoX(MAX_DECO) AS SINGLE, decoY(MAX_DECO) AS SINGLE, decoKind(MAX_DECO) AS INTEGER
DIM SHARED decoOn(MAX_DECO) AS INTEGER, decoFuse(MAX_DECO) AS INTEGER, numDecos AS INTEGER
' decoCharge: how charged a spawner is, 0..1 (0 = asleep), and decoBurst:
' frames left of the flash as it sends a monster out - both only for show
DIM SHARED decoCharge(MAX_DECO) AS SINGLE, decoBurst(MAX_DECO) AS INTEGER
' decoHP: hits left before it breaks; decoTimer: frames left of its collapse
DIM SHARED decoHP(MAX_DECO) AS INTEGER, decoTimer(MAX_DECO) AS INTEGER
DIM SHARED decoFace(MAX_DECO) AS INTEGER ' (0: it turns to face you, as sprites do; 1-4: it stands flat, facing east, south, west or north - [nudges], or its back to its wall: LoadLevel)
' decoLootA: which way its loot flies when it breaks - back towards you if
' your boot broke it, else (NO_AIM) any way at all (DecoLoot)
CONST NO_AIM = -99
DIM SHARED decoLootA(MAX_DECO) AS SINGLE
DIM SHARED decoCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' Which decoration stands in a cell (0 none)
' Barrels on barrels ([barrels]: a cell's stack): decoZ how high one stands
' (0 on the floor), decoLeak a liquid barrel's frames of leaking (its fuse,
' shown), decoOpen a chest opened
DIM SHARED decoZ(MAX_DECO) AS SINGLE, decoLeak(MAX_DECO) AS INTEGER, decoOpen(MAX_DECO) AS INTEGER
' [barrels]: x, y, liquid (0 a plain barrel, 1-5 LQ_), stack (1-3 high)
CONST MAX_BARRELS = 96, BARREL_STACK = 3
DIM SHARED lvlNumBarrels AS INTEGER, lvlBarrel(MAX_BARRELS, 4) AS INTEGER

CONST DK_CHAIR = 20, DK_BODY = 21 ' (a body doesn't block the way, and can't be broken)
CONST DK_SPECIMEN = 13 ' (a specimen tank: break it open, and half the time what's in it gets out - HitDeco)
CONST DK_VENDING = 7 ' (a vending machine: Space on it - a slot machine, SlotUse: three alike pay out, or go off)
CONST DK_TERMINAL = 4, DK_CONSOLE = 11, DK_SCREENS = 12 ' (computers: Space on one plays NEON PONG - ArcadeRun - and beating it pays out)
CONST ARC_TOP = 90, ARC_BOT = 570, ARC_PAD = 80, ARC_WIN = 3 ' (NEON PONG's court, its paddles' length, and the points to win)
DIM SHARED vendState(MAX_DECO) AS INTEGER, vendTimer(MAX_DECO) AS INTEGER, vendBomb(MAX_DECO) AS INTEGER ' (0 waiting, 1 counting down, 2 paying out, 3 sold out)
CONST DK_LQBARREL = 21 ' (a barrel of a liquid: kind DK_LQBARREL + its liquid, 22-26 - one map character, :, its liquid in [barrels]: LQ_WATER to LQ_ACID)
CONST DK_CHEST = 27 ' (a treasure chest: Space opens it - ChestOpen)
CONST DECO_KINDS = 27, ITEM_KINDS = 21 ' (kinds of decoration and of pickup - see chapter 3)
' ...and each decoration's wreck, the same way (MakeWreck)
DIM SHARED wreckScale(DECO_KINDS), wreckSquash(DECO_KINDS)
