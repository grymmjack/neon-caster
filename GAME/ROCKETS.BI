''
' NEON-CASTER - GAME/ROCKETS.BI
' =============================================================================
' Rockets, missiles and the turrets' sprays: kinds of bolt (chapter 13).
'

' --- BK_ = Bolt Kind: what a bolt (MAX_BOLTS, GAME/MONSTERS.BI) is. A
' gunner's plasma (BK_PLASMA, 0) flies as ever; the rest fly by BoltFly:
'   BK_ROCKET   yours, from the rocket launcher (gun 5): it flies fast and
'               bursts on the first wall or monster it meets - a blast that
'               hurts everything near, you as well
'   BK_MISSILE  a missile turret's: slower, turning a little after you, and
'               it bursts as a rocket does, a smaller blast
'   BK_FLAME, BK_POISON, BK_ACID  the spray turrets' puffs: slow, short-
'               lived, they hurt as fire, poison or acid do (the hazmat
'               suit keeps out poison and acid; acid eats armour first)
' Each has its own speed (boltSpd), frames left to fly (boltLife - 0: till
' it hits something), and look (its glowing picture, S_PUFF + kind, and
' the colour of its light: bkR, bkG, bkB; its size: bkScale)
CONST BK_PLASMA = 0, BK_ROCKET = 1, BK_MISSILE = 2, BK_FLAME = 3, BK_POISON = 4, BK_ACID = 5, BOLT_KINDS = 5
DIM SHARED boltKind(MAX_BOLTS) AS INTEGER, boltLife(MAX_BOLTS) AS INTEGER, boltSpd(MAX_BOLTS) AS SINGLE
DIM SHARED bkR(BOLT_KINDS) AS INTEGER, bkG(BOLT_KINDS) AS INTEGER, bkB(BOLT_KINDS) AS INTEGER, bkScale(BOLT_KINDS) AS SINGLE
'                  light colour     size
bkR(BK_ROCKET) = 255 : bkG(BK_ROCKET) = 150 : bkB(BK_ROCKET) = 40 : bkScale(BK_ROCKET) = 0.2
bkR(BK_MISSILE) = 255 : bkG(BK_MISSILE) = 70 : bkB(BK_MISSILE) = 40 : bkScale(BK_MISSILE) = 0.18
bkR(BK_FLAME) = 255 : bkG(BK_FLAME) = 130 : bkB(BK_FLAME) = 20 : bkScale(BK_FLAME) = 0.34
bkR(BK_POISON) = 80 : bkG(BK_POISON) = 230 : bkB(BK_POISON) = 60 : bkScale(BK_POISON) = 0.38
bkR(BK_ACID) = 210 : bkG(BK_ACID) = 240 : bkB(BK_ACID) = 40 : bkScale(BK_ACID) = 0.36
' How fast each flies (cells a frame), and the blasts: a rocket's reach
' (cells), and the most it does to a monster and to you; a missile's
CONST ROCKET_SPEED = 0.3, MISSILE_SPEED = 0.15, PUFF_SPEED = 0.11, PUFF_LIFE = 40
CONST ROCKET_RADIUS = 2.4, ROCKET_MON = 14, ROCKET_YOU = 30, ROCKET_HIT = 6
CONST MISSILE_RADIUS = 1.7, MISSILE_MON = 4, MISSILE_YOU = 22
' (a rocket's blast, BlastSized: where, its reach, most to a monster and to
' you - set them, then call it)
DIM SHARED bsX AS SINGLE, bsY AS SINGLE, bsZ AS SINGLE, bsR AS SINGLE, bsMon AS INTEGER, bsYou AS INTEGER
' (where a rocket burst: the surface it hit - 0 a wall, 1 the ceiling, 2 the
' floor, -1 in the air, on something - and the way it was going: its scorch)
DIM SHARED bsSurf AS INTEGER, bsDX AS SINGLE, bsDY AS SINGLE, bsOwner AS INTEGER ' (bsOwner: the monster whose missile it was - those it hurts may turn on it)
DIM SHARED boltTgt(MAX_BOLTS) AS INTEGER ' (a missile: the monster it's after - 0, you)
' A blast knocks things away from it: you (knockX, knockY a frame, easing
' off - and up, if it's under you: a rocket jump) and the monsters near it
DIM SHARED knockX AS SINGLE, knockY AS SINGLE
' rocketAir: thrown up by a blast - a rocket jump - till you land: you fall
' at ROCKET_FALL of the usual pull (higher, and slower down), and the
' landing doesn't hurt
DIM SHARED rocketAir AS INTEGER
CONST ROCKET_FALL = 0.5
' Fire: a monster a rocket killed burns where it lies, and so does anything
' that burns that a blast caught - a crate, a plant, a desk (Flammable) -
' for monBurn / decoBurn frames
CONST BURN_FRAMES = 300
DIM SHARED monBurn(MAX_MON) AS INTEGER, decoBurn(MAX_DECO) AS INTEGER
' PIECES: what a rocket blew apart, flying out in a shower and lying where
' they land - a piece of its own picture each (S_GIB + monster type, or
' S_GIB + MON_TYPES + decoration kind - MakeGib), spinning till it lands
CONST MAX_GIBS = 64, GIB_LIFE = 900
DIM SHARED gibX(MAX_GIBS) AS SINGLE, gibY(MAX_GIBS) AS SINGLE, gibZ(MAX_GIBS) AS SINGLE
DIM SHARED gibVX(MAX_GIBS) AS SINGLE, gibVY(MAX_GIBS) AS SINGLE, gibVZ(MAX_GIBS) AS SINGLE
DIM SHARED gibLife(MAX_GIBS) AS INTEGER, gibSlot(MAX_GIBS) AS INTEGER, gibSize(MAX_GIBS) AS SINGLE, gibNext AS INTEGER
' POISON FOG: a poison turret's spray gathers where it lands, cell by cell
' (gasAmt: 0 none, about 1 thick), spreading a little through open cells
' and doorways and thinning away over a good few seconds - green haze in
' it, and while you stand in it, poison (the hazmat suit keeps it out)
DIM SHARED gasAmt(MAP_SIZE, MAP_SIZE) AS SINGLE, gasAny AS INTEGER, gasWait AS LONG
' POISONED: once poison gets to you (a poison turret's spray, its fog, a
' poison pool - not through the hazmat suit), it goes on hurting you
' (POISON DAMAGE, SETTINGS > GAMEPLAY: 3 health a second as made) for
' POISON_TIME frames more after the last of it - or till a health pack or
' medkit cures it
CONST POISON_TIME = 600
DIM SHARED poisonLeft AS INTEGER
' (it builds up first: poisonBuild, the poison you've taken lately - past
' POISON_BUILD, you're poisoned; it wears off slowly while you're out of it)
CONST POISON_BUILD = 12
DIM SHARED poisonBuild AS SINGLE
