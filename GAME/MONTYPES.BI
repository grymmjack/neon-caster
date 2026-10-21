''
' NEON-CASTER - GAME/MONTYPES.BI
' =============================================================================
' The monster types table (chapter 6): SetMonType fills in each type's
' numbers, monsters.txt can change them, and SetWeakSpot marks each one's
' weak spot.
'

' The monster types table: SetMonType fills in the "mtype" arrays (one
' entry per TYPE of monster - see chapter 3) for types 1-9 (6 stalker, 7 spitter, 8 the overseer, the last
' sector's boss, 9 the thief bot). Speeds are set against yours: you walk
' 0.06 and run 0.12 - only the thief is faster than you walk. Speed is in
' cells a frame; height is in walls (1 = as tall as a wall); lift and bob
' are how high it hovers and how much it bobs; reach is how close it must
' be to hit you; damage is dmg plus a random 0 to +rnd - 1; cooldown (cool)
' is frames between attacks; slot is its sprite slot (chapter 5).
'          type name       HP  speed  height lift bob   reach dmg +rnd cool slot
SetMonType 1,   "drone",   3,  0.03,  0.65,  0.2, 0.05, 0.95, 6,  4,   60,  9
SetMonType 2,   "gunner",  4,  0.025, 0.8,   0,   0,    0,    7,  4,   110, 11
SetMonType 3,   "heavy",   10, 0.02,  0.95,  0,   0,    1.25, 15, 8,   95,  13
SetMonType 4,   "crawler", 2,  0.045, 0.4,   0,   0.02, 0.75, 3,  3,   50,  15
SetMonType 5,   "sentry",  8,  0,     0.75,  0,   0,    0,    5,  4,   70,  17
SetMonType 6,   "stalker", 3,  0.052, 0.75,  0,   0,    0.9,  5,  4,   50,  S_MONX + 1
SetMonType 7,   "spitter", 6,  0.022, 0.7,   0,   0,    0,    6,  4,   95,  S_MONX + 3
SetMonType 8,   "overseer", 80, 0.014, 1.4,  0.3, 0.06, 0,    9,  5,   45,  S_MONX + 5
SetMonType 9,   "thief",   5,  0.09,  0.55,  0,   0,    0.8,  0,  0,   60,  S_MONX + 7
SetMonType 10,  "ice",     2,  0.05,  0.5,   0.3, 0.06, 0.75, 5,  3,   50,  S_MONX + 9
SetMonType 11,  "sniper",  4,  0.022, 0.85,  0,   0,    0,    16, 6,   150, S_MONX + 11
SetMonType 12,  "trooper", 6,  0.028, 0.85,  0,   0,    0,    5,  3,   100, S_MONX + 13
SetMonType 13,  "ripper",  3,  0.072, 0.6,   0,   0.02, 0.85, 6,  4,   40,  S_MONX + 15
SetMonType 14,  "warden",  60, 0.016, 1.35,  0,   0,    0,    10, 6,   75,  S_MONX + 17
SetMonType 15,  "colossus", 90, 0.015, 1.5,  0,   0,    1.9,  22, 8,   80,  S_MONX + 19
SetMonType 16,  "turret",  6,  0,     0.55,  0,   0,    0,    4,  2,   80,  S_MONX + 21
SetMonType 17,  "mimic",   8,  0.034, 0.5,   0,   0.05, 0.95, 14, 6,   55,  S_MONX + 23
mtypeRanged(2) = -1 : mtypeRanged(5) = -1 : mtypeRanged(7) = -1 : mtypeRanged(8) = -1
mtypeRanged(11) = -1 : mtypeRanged(12) = -1 : mtypeRanged(14) = -1 : mtypeRanged(16) = -1
mtypeStyle(11) = STYLE_LASER : mtypeStyle(12) = STYLE_BURST : mtypeStyle(14) = STYLE_WARDEN : mtypeStyle(15) = STYLE_COLOSSUS : mtypeStyle(16) = STYLE_TURRET : mtypeStyle(13) = STYLE_RIPPER

' ...and that table changed by neon-caster/monsters.txt, if it's there:
' every monster's numbers as plain text, to tune without changing the
' program - by hand, or in the monster editor (chapter 21)
ReadMonsters
' Each one's weak spot (chapter 3's mtypeWS): where on its picture a shot
' does double - and the cry it gives when one lands there (name-pain, or
' else its usual hit sound)
'           type  across      down        (0 to 1 of its picture)
SetWeakSpot 1,    0.38, 0.62, 0.22, 0.55 ' drone: its red eye
SetWeakSpot 2,    0.40, 0.68, 0.06, 0.36 ' gunner: its head
SetWeakSpot 3,    0.42, 0.70, 0.06, 0.33 ' heavy: its head
SetWeakSpot 4,    0.36, 0.72, 0.60, 0.92 ' crawler: its red eyes, low at the front
SetWeakSpot 5,    0.38, 0.78, 0.03, 0.35 ' sentry: its camera, on top
SetWeakSpot 6,    0.35, 0.72, 0.03, 0.33 ' stalker: its visor
SetWeakSpot 7,    0.35, 0.68, 0.05, 0.36 ' spitter: its head
SetWeakSpot 8,    0.40, 0.66, 0.28, 0.58 ' overseer: its great red eye
SetWeakSpot 9,    0.32, 0.66, 0.20, 0.52 ' thief: its head
SetWeakSpot 10,   0.40, 0.72, 0.32, 0.66 ' ICE: its core
SetWeakSpot 11,   0.38, 0.62, 0.02, 0.22 ' sniper: its head
SetWeakSpot 12,   0.38, 0.62, 0.03, 0.28 ' trooper: its visor
SetWeakSpot 13,   0.36, 0.64, 0.05, 0.35 ' ripper: its eyes
SetWeakSpot 14,   0.40, 0.60, 0.30, 0.52 ' warden: its core
SetWeakSpot 15,   0.38, 0.62, 0.30, 0.55 ' colossus: its furnace
SetWeakSpot 16,   0.35, 0.65, 0.30, 0.65 ' turret: its eye
SetWeakSpot 17,   0.30, 0.70, 0.30, 0.62 ' mimic: its mouth
