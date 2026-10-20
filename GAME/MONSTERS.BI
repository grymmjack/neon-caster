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
CONST MAX_MON = 192, MON_TYPES = 16 ' (a level places up to 64 - 128 in a sector over 64 cells across: the level kit checks - and its event rooms, nests and the network bring more)
CONST MT_ICE = 10 ' (ICE: the network's hunter programs - only in the network, chapter 19)
CONST MT_THIEF = 9 ' (the thief bot: steals, then runs - ThiefStep, chapter 13)
' The newer ones: a laser sniper, a trooper with a burst rifle, the ripper
' (fast, all claws), two field bosses - the warden and the colossus - and
' the turret, hidden in the ceiling or floor till it sees you
CONST MT_SNIPER = 11, MT_TROOPER = 12, MT_RIPPER = 13, MT_WARDEN = 14, MT_COLOSSUS = 15, MT_TURRET = 16
' How each kind fights, past a bite or a bolt (mtypeStyle): STYLE_LASER
' aims a beam you can see, lagging behind you, then fires it - step out of
' it; STYLE_BURST a burst of bolts; the warden's and the colossus's own;
' STYLE_TURRET a turret's (bursts, once it's out); STYLE_RIPPER hit and
' run - in fast, a slash, and a leap back out of reach (monBurst: frames
' of it left), so you see it come at you
CONST STYLE_LASER = 1, STYLE_BURST = 2, STYLE_WARDEN = 3, STYLE_COLOSSUS = 4, STYLE_TURRET = 5, STYLE_RIPPER = 6
CONST RIPPER_BACK = 22 ' (frames a ripper leaps back after a slash)
' A ripper's slash, on the screen: three claw marks torn across it (clawFx:
' frames left, CLAW_FX at first; where, and at what slant, a new each hit)
CONST CLAW_FX = 18
DIM SHARED clawFx AS INTEGER, clawX AS SINGLE, clawY AS SINGLE, clawA AS SINGLE
CONST LASER_AIM = 50, LASER_HIT = 0.45 ' (frames a laser aims; how near you its end must be when it fires)
CONST TURRET_UP = 36 ' (frames a turret takes to come out)
' A turret's mount (monFrom): out of the ceiling (~), up out of the floor
' (_), or out of a wall (| - monWallX, monWallY: the way it points out of
' it, into the room). And what it fires (monWeap, the 8th number of its
' [monsters] line): TW_ - plasma bolts in bursts, a laser that aims first
' (as the sniper's), lightning, a flame thrower, poison spray, acid mist,
' or missiles (they turn after you - GAME/ROCKETS.BM)
CONST TURRET_CEIL = 0, TURRET_FLOOR = 1, TURRET_WALL = 2
CONST TW_PLASMA = 0, TW_LASER = 1, TW_LIGHTNING = 2, TW_FLAME = 3, TW_POISON = 4, TW_ACID = 5, TW_MISSILE = 6, TURRET_WEAPONS = 6
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
' ...a laser's aim: frames left of it (monAim), and where it points
' (monAimX, monAimY: it follows you, a little behind); shots left of a
' burst (monBurst) and frames to the next (monGap); a turret's coming out
' (monDeploy: 0 hidden .. TURRET_UP out; -1 switched off) and whether it
' hangs from the ceiling (monFrom 0) or rises from the floor (1)
DIM SHARED monAim(MAX_MON) AS INTEGER, monAimX(MAX_MON) AS SINGLE, monAimY(MAX_MON) AS SINGLE
DIM SHARED monBurst(MAX_MON) AS INTEGER, monGap(MAX_MON) AS INTEGER, monDeploy(MAX_MON) AS SINGLE, monFrom(MAX_MON) AS INTEGER, monTurn(MAX_MON) AS INTEGER
' A turret's states: how fast it comes out and goes in (monEject: of
' TURRET_UP a frame - the level's 10th number, the frames it takes), how it
' starts (monTMode, the 11th: TURRET_AUTO out when it wakes, TURRET_HELD
' folded away till it's told - the turret command, a trigger's - TURRET_OUT
' out from the start), what it's been told (monTWant: 1 come out, -1 go in)
' and whether it's been switched off, out but still (monTOff)
CONST TURRET_AUTO = 0, TURRET_HELD = 1, TURRET_OUT = 2, TURRET_EJECT = 36 ' (TURRET_EJECT: the frames it takes as made - medium)
DIM SHARED monEject(MAX_MON) AS SINGLE, monTMode(MAX_MON) AS INTEGER, monTWant(MAX_MON) AS INTEGER, monTOff(MAX_MON) AS INTEGER
DIM SHARED monWeap(MAX_MON) AS INTEGER, monWallX(MAX_MON) AS SINGLE, monWallY(MAX_MON) AS SINGLE
' (a turret destroyed, monBlown: 1 its blast still to come - the monsters' next turn, not inside the hit that
' killed it - then 2: its mount, scorched, sparking and smoking for good - TurretBlown, TurretStump)
DIM SHARED monBlown(MAX_MON) AS INTEGER
' A turret's aim: the way it points (monAimA, radians), how fast it turns
' (monTrack, degrees a second - TURRET_TRACK as made; the 9th number of its
' [monsters] line), and how many frames it's had you in its sights
' (monLock): it fires only once it's turned to you and held you a moment
' (TurretReady - the slower it turns, the longer). turPrefX, turPrefY: the
' wall a summoned wall turret should go in (the one you face)
CONST TURRET_TRACK = 90
DIM SHARED monAimA(MAX_MON) AS SINGLE, monTrack(MAX_MON) AS SINGLE, monLock(MAX_MON) AS INTEGER, turPrefX AS INTEGER, turPrefY AS INTEGER
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
DIM SHARED mtypeSprite(MON_TYPES), mtypeName$(MON_TYPES), mtypeRanged(MON_TYPES), mtypeStyle(MON_TYPES)
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
CONST MAX_BOLTS = 96, BOLT_SPEED = 0.11 ' (rockets, missiles and sprays are bolts too: GAME/ROCKETS.BI)
DIM SHARED boltFromZ AS SINGLE ' (a bolt's own starting height, for FireBolt - 0: from the shooter's middle, as ever)
DIM SHARED boltX(MAX_BOLTS) AS SINGLE, boltY(MAX_BOLTS) AS SINGLE, boltDX(MAX_BOLTS) AS SINGLE, boltDY(MAX_BOLTS) AS SINGLE
DIM SHARED boltOn(MAX_BOLTS) AS INTEGER, boltDamage(MAX_BOLTS) AS INTEGER
' INFIGHTING: a monster's shots hit any other monster in their way - and
' the one hit may turn on it (a third of the time: monFoe, till one of them
' is dead). Each bolt's shooter (boltOwner; 0 none - yours); boltFromMon, the
' monster shooting now (FireBolt and FireKind note it); and in a monster's
' turn, who it's after (monVs: 0 you, or the monster it's turned on) and
' where they are (monTX, monTY, monTZ - their feet)
DIM SHARED boltOwner(MAX_BOLTS) AS INTEGER, boltFromMon AS INTEGER, monFoe(MAX_MON) AS INTEGER
DIM SHARED monVs AS INTEGER, monTX AS SINGLE, monTY AS SINGLE, monTZ AS SINGLE
' FLYING: what hovers (mtypeLift over 0 - the drone, the overseer, ICE)
' flies - monFly, how far over its hover height it is, rising and sinking
' towards the height of who it's after (MonFlyTurn), under the ceiling
DIM SHARED monFly(MAX_MON) AS SINGLE

' --- Beams: a laser aiming (a faint red line - BEAM_AIM) or firing (white-
' hot - BEAM_SHOT), from (beamX0, beamY0, beamZ0) to (X1, Y1, Z1), for
' beamT more frames. Drawn as a line of glowing dots (chapter 16).
CONST MAX_BEAMS = 24, BEAM_AIM = 0, BEAM_SHOT = 1, BEAM_SIGHT = 2 ' (BEAM_SIGHT + a turret's weapon: its laser sight, in the weapon's colour)
DIM SHARED beamX0(MAX_BEAMS) AS SINGLE, beamY0(MAX_BEAMS) AS SINGLE, beamZ0(MAX_BEAMS) AS SINGLE
DIM SHARED beamX1(MAX_BEAMS) AS SINGLE, beamY1(MAX_BEAMS) AS SINGLE, beamZ1(MAX_BEAMS) AS SINGLE
DIM SHARED beamT(MAX_BEAMS) AS INTEGER, beamKind(MAX_BEAMS) AS INTEGER
