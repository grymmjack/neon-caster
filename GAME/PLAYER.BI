''
' NEON-CASTER - GAME/PLAYER.BI
' =============================================================================
' Chapter 4: you - health, armour, ammo, where you are, the kick, how
' fast you walk and run.
'

CONST PLAYER_RADIUS = 0.3 ' Your body's half-width, so the camera can't touch a wall
'-----------------------------------------------------------------------------
' CHAPTER 4: YOU
'-----------------------------------------------------------------------------
' Health, armour, three kinds of ammo and five guns. Each gun is a row in a
' table of numbers (SetGun, below), so the shooting code (chapter 12) works
' the same way for all of them - a new gun is mostly a new SetGun line and
' a picture. Your position and the way you face are in chapter 8.
' The most health (HP = "hit points") and armour you can have
CONST MAX_HP = 100, MAX_ARMOR = 100
' AM_ = AMmo: the kinds (NUM_AMMO of them). They number the ammo arrays:
' ammoCount(AM_CELLS) is how many energy cells you have, ammoMax(AM_SHELLS)
' the most shells you can carry. Rockets come five to a box, fifty at most.
CONST AM_CELLS = 1, AM_SHELLS = 2, AM_ROCKETS = 3, NUM_AMMO = 3
DIM SHARED ammoCount(NUM_AMMO) AS INTEGER, ammoMax(NUM_AMMO) AS INTEGER
ammoMax(AM_CELLS) = 99 : ammoMax(AM_SHELLS) = 40 : ammoMax(AM_ROCKETS) = 50
' TEST_ and CHEAT_ = testing aids - set both to 0 for the real game:
'   TEST_ALL_GUNS  -1 starts you with every gun and full ammo
'   CHEAT_KEYS     -1 lets K give you every keycard, and G switch god mode
'                  (no damage, walk through walls) on and off
CONST TEST_ALL_GUNS = 0
CONST CHEAT_KEYS = -1

DIM SHARED pitch ' (looking up and down, chapter 8 - OpenGL only)

DIM SHARED kickTimer AS INTEGER, kickImg&, sndKick&, sndKickSwing& ' (the kick: chapter 12)
CONST STEP_WALK = 1.4, STEP_RUN = 2.2 ' Cells walked per footstep: walking (about 2.6 steps a second) and running (3.3 - longer strides)

DIM SHARED playerX AS SINGLE, playerY AS SINGLE ' (where you are - shared, so FireBolt aims a bolt's climb at you and TrapFx hears its hum from you)
DIM SHARED playerZ AS SINGLE, playerVZ AS SINGLE, eyeZ AS SINGLE, walkZ AS SINGLE
DIM SHARED boltZ(MAX_BOLTS) AS SINGLE, boltDZ(MAX_BOLTS) AS SINGLE

' THE KICK (F, or Fire with no ammo - chapter 12): KICK_FRAMES long, the
' boot landing KICK_HIT frames in; reach KICK_REACH cells, KICK_DAMAGE
' damage, pushing a monster back KICK_PUSH cells
CONST KICK_FRAMES = 22, KICK_HIT = 8, KICK_REACH = 1.35, KICK_DAMAGE = 2, KICK_PUSH = 0.45
' How fast you go, in cells a frame: walking, and running (holding Shift)
CONST WALK_SPEED = 0.06, RUN_SPEED = 0.12 ' (walking: half as fast)
