''
' NEON-CASTER - GAME/MONSTERS.BI
' =============================================================================
' Monsters (chapter 3): each monster, and each TYPE of monster - and
' the bolts they shoot.
'

' --- Monsters: 1 drone (bites), 2 gunner (shoots bolts), 3 heavy (smashes),
' 4 crawler (fast, bites), 5 sentry (a turret: stays put, shoots bolts) ---
' Each monster is in one of four states (chapter 13): 0 idle, 1 hunting,
' 2 dying, 3 dead. monsterTimer counts frames - down to its next attack while
' hunting, or through its collapse while dying - and monsterHurt is how many
' more frames it flashes red after a hit.
' MON_ = MONster settings shared by every monster: MON_TYPES kinds of monster,
' MON_SIGHT how far away (in cells) they notice you, MON_DYING how many
' frames one takes to collapse when killed
CONST MAX_MON = 128, MON_TYPES = 10 ' (a level places up to 64 - the level kit checks - and its event rooms, nests and the network bring more)
CONST MT_ICE = 10 ' (ICE: the network's hunter programs - only in the network, chapter 19)
CONST MT_THIEF = 9 ' (the thief bot: steals, then runs - ThiefStep, chapter 13)
CONST MON_SIGHT = 14
' Each monster's own (the level's [monsters] - the editor's monster pane -
' else as every monster is): how far it sees you, how far it hears your
' shots (0: not at all), how fast (times its kind's speed), and what wakes
' it - WAKE_SEE seeing you, WAKE_NEAR you coming within its sight (round a
' corner too: an ambush), WAKE_HIT only being hit, WAKE_HUNT nothing: it's
' hunting from the start
CONST WAKE_SEE = 0, WAKE_NEAR = 1, WAKE_HIT = 2, WAKE_HUNT = 3
CONST MON_DYING = 24
CONST MON_STRIDE = 0.12 ' How far a monster walks per frame of its walk
DIM SHARED monsterX(MAX_MON) AS SINGLE, monsterY(MAX_MON) AS SINGLE, monsterType(MAX_MON) AS INTEGER
DIM SHARED monsterHP(MAX_MON) AS INTEGER, monsterState(MAX_MON) AS INTEGER
DIM SHARED monsterTimer(MAX_MON) AS INTEGER, monsterHurt(MAX_MON) AS INTEGER
' ...where each one is in its animation (frames of it, as a decimal: chapter
' 13 moves it on as the monster moves), and frames left of its attack pose
DIM SHARED monsterAnim(MAX_MON) AS SINGLE, monsterAtk(MAX_MON) AS INTEGER
DIM SHARED monSight(MAX_MON), monHear(MAX_MON), monSpd(MAX_MON), monWake(MAX_MON) AS INTEGER
DIM SHARED monsterEv(MAX_MON) AS INTEGER ' (the event room that sent it, 0 for none - chapter 3)
' ...and what a thief bot has stolen: cells, shells and a gun (0 none);
' thiefState 0 coming for you, 1 running home empty-handed, 2 running home
' with your things
DIM SHARED thiefCells(MAX_MON) AS INTEGER, thiefShells(MAX_MON) AS INTEGER, thiefGun(MAX_MON) AS INTEGER, thiefState(MAX_MON) AS INTEGER
DIM SHARED numMonsters AS INTEGER
' A second set of arrays describes each TYPE of monster, numbered 1-5 (the
' "mtype" arrays, filled in chapter 6). Per type: hit points, speed (tiles a frame; you walk 0.12), height (of a
' wall), hover height and bob, attack reach, damage (min + random), frames
' between attacks, sprite slots, whether it shoots bolts, and sounds
DIM SHARED mtypeHP(MON_TYPES), mtypeSpeed(MON_TYPES), mtypeScale(MON_TYPES), mtypeLift(MON_TYPES), mtypeBob(MON_TYPES)
DIM SHARED mtypeReach(MON_TYPES), mtypeDamage(MON_TYPES), mtypeDamageRnd(MON_TYPES), mtypeCooldown(MON_TYPES)
DIM SHARED mtypeSprite(MON_TYPES), mtypeName$(MON_TYPES), mtypeRanged(MON_TYPES)
DIM SHARED mtypeDrop(MON_TYPES), mtypeDropChance(MON_TYPES) ' (what it may leave when it dies - a pickup kind - and how likely: monsters.txt)
' ...and its weak spot - a head, or an eye, a lens, a core - as a box on its
' picture: across from mtypeWS(t, 1) to (t, 2), down from (t, 3) to (t, 4),
' each 0 to 1 of the picture. A shot that lands in it does WEAK_MULT times
' the damage (a headshot), with its pain cry (mtypePainSnd&) - chapter 12
CONST WEAK_MULT = 2
DIM SHARED mtypeWS(MON_TYPES, 4) AS SINGLE, mtypePainSnd&(MON_TYPES), sndHeadshot&
' ...and its body, once it's dead (MakeCorpse): how wide it's drawn (as
' drawScale), and how tall for that width (as drawSquash)
DIM SHARED corpseScale(MON_TYPES), corpseSquash(MON_TYPES)
DIM SHARED mtypeAlertSnd&(MON_TYPES), mtypeAttackSnd&(MON_TYPES), mtypeHitSnd&(MON_TYPES), mtypeDieSnd&(MON_TYPES)
' ...and the sounds it makes now and then: waiting (idle), and hunting you
DIM SHARED mtypeIdleSnd&(MON_TYPES), mtypeHuntSnd&(MON_TYPES)
' GUNNER_ = gunners (and sentries) like to keep between GUNNER_NEAR and
' GUNNER_FAR cells away from you
CONST GUNNER_NEAR = 3.5, GUNNER_FAR = 7

' --- Energy bolts (what gunners and sentries shoot): a position and a
' direction each, moved a little every frame ---
' (BOLT_SPEED is in cells a frame - you walk at 0.12)
CONST MAX_BOLTS = 32, BOLT_SPEED = 0.11
DIM SHARED boltX(MAX_BOLTS) AS SINGLE, boltY(MAX_BOLTS) AS SINGLE, boltDX(MAX_BOLTS) AS SINGLE, boltDY(MAX_BOLTS) AS SINGLE
DIM SHARED boltOn(MAX_BOLTS) AS INTEGER, boltDamage(MAX_BOLTS) AS INTEGER
