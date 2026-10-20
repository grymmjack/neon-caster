''
' NEON-CASTER - WORLD/LIFTS.BI
' =============================================================================
' Lifts ([lifts] in the level file): floors that move up and down.
'

' --- Lifts ([lifts] in the level file): a rectangle of floor that moves
' between two heights (low, high) - mode 1 up and down by itself, mode 2
' an elevator: step on and it takes you to its other end (MoveLifts),
' mode 3 only when it's told to (liftgo - a trigger's). Modes 4 and 5 move
' its CEILING, as DOOM's crushers: low is how far down it comes, high its
' top - 4 a CRUSHER (down slowly, up again, over and over: it hurts you
' while it presses on you), 5 a SMASHER (waits up top, slams down hard, a
' big hit, then grinds back up). Their cells' ceilH is set to liftZ.
' Each frame (MoveLifts) its cells' floorH is set to where it is (liftZ),
' so standing, falling and drawing all just follow it; OpenGL draws it
' each frame, like a door (GLLifts), not in the world mesh.
CONST MAX_LIFTS = 16
DIM SHARED numLifts AS INTEGER, liftCell(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED liftX0(MAX_LIFTS) AS INTEGER, liftY0(MAX_LIFTS) AS INTEGER, liftX1(MAX_LIFTS) AS INTEGER, liftY1(MAX_LIFTS) AS INTEGER
DIM SHARED liftLow(MAX_LIFTS) AS SINGLE, liftHigh(MAX_LIFTS) AS SINGLE, liftMode(MAX_LIFTS) AS INTEGER, liftSpeed(MAX_LIFTS) AS SINGLE
DIM SHARED liftWasDir(MAX_LIFTS) AS INTEGER, liftHum&(MAX_LIFTS) ' (which way it went last frame; its motor - its own looping copy of lift-move.wav: LiftSound)
DIM SHARED liftZ(MAX_LIFTS) AS SINGLE, liftDir(MAX_LIFTS) AS INTEGER, liftWait(MAX_LIFTS) AS INTEGER
DIM SHARED liftArm(MAX_LIFTS) AS INTEGER ' (an elevator: you've been off it since it last moved you - stepping on now sends it)
DIM SHARED lvlNumLifts AS INTEGER, lvlLift(MAX_LIFTS, 8) AS SINGLE
CONST LIFT_CRUSHER = 4, LIFT_SMASHER = 5
CONST CRUSH_HURT = 10, CRUSH_EVERY = 8, SMASH_HURT = 45 ' (a crusher pressing on you: 10 every 8 frames; a smasher's slam: 45 at once)
DIM SHARED liftHit(MAX_LIFTS) AS INTEGER ' (a smasher has hit you this slam: once a slam)
