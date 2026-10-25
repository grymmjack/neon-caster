''
' NEON-CASTER - GAME/FLASHLIGHT.BI
' =============================================================================
' THE FLASHLIGHT (GAME/FLASHLIGHT.BM): a pickup (IT_FLASHLIGHT) - yours till
' you die, as the jetpack is - that FLASHLIGHT (L) switches on and off. Its
' battery runs down while it's on (BATTERY LIFE), spare batteries (IT_BATTERY,
' up to FL_SPARES) go in as one runs out. A beam where you look: OpenGL's
' world shader lights each pixel in its cone (flashPos, flashDir, flashCone,
' flashCol); the software renderer lights the cells in it (FlCells). Its
' look - SETTINGS > GAMEPLAY > FLASHLIGHT: BEAM WIDTH, REACH, BRIGHTNESS,
' SOFT EDGE, COLOUR, BEAM IN THE AIR (its haze), EFFECT, BATTERY LIFE.
' It only lights: nothing in the game sees it (demos stay in step).
'
CONST FL_SPARES = 4 ' (the most spare batteries carried)
CONST FL_DEMO_MINS = 4 ' (a demo's battery life, recording or playing: not the setting's)
CONST FL_COLOURS = 9 ' (COLOUR's choices: WARM ... UV, then YOUR OWN - flashlight_rgb=)
DIM SHARED flHave AS INTEGER, flOn AS INTEGER, flBatt AS SINGLE, flSpares AS INTEGER ' (a flashlight; on; its battery, 0-100; spares)
DIM SHARED flNow AS SINGLE ' (this frame's strength: 0 dark - its effect and its battery - FlStep)
DIM SHARED flTimer AS INTEGER, flKeyWas AS INTEGER, flLowSaid AS INTEGER
DIM SHARED flRGB$ ' (flashlight_rgb= in settings: YOUR OWN colour, RRGGBB)
DIM SHARED glFl(1) AS SINGLE ' (OpenGL's copy of flNow, each frame: chapter 17)
DIM SHARED flHazeImg&, flHazeKey$ ' (the beam in the air: a soft round glow, made again when its colour or strength changes)
