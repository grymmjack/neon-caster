''
' NEON-CASTER - GAME/TUNING.BI
' =============================================================================
' The tuning table: every number that decides how many shots a thing takes -
' machines' and breakables' health, each gun's damage, rate and pellets, the
' rocket's hit and blast, the kick, a headshot, a barrel's blast - and how
' hard you're hurt. One row each, with four values: one a difficulty (EASY,
' NORMAL, HARD, NIGHTMARE: tuneV(row, skill)).
'
' As coded (tuneC), every row is the game as it was: EASY the numbers the
' code always had (so its demos - every shipped one is EASY - stay in step),
' NORMAL to NIGHTMARE what SkillHP and SkillHurt made of them. A hook that
' finds its row still as coded runs the old code.
'
' The defaults (tuneD) are those, with neon-caster/tuning-defaults.txt's
' rows over them - the game as shipped. neon-caster/tuning.txt keeps the
' player's rows that differ from the defaults (ReadTuning, WriteTuning); a
' monster's EASY health is monsters.txt's. tuning bake makes what's tuned
' the defaults (TuneBake: tuning-original.txt lists every row as coded, and
' the defaults it replaced go to tuning-defaults.bak).
' The tuner (EDITOR/TUNER.BM; the tuning command, SETTINGS > GAMEPLAY)
' changes them, works out how many shots each thing takes with each gun at
' each difficulty, and writes and reads saves/tuning.csv (and a report,
' saves/tuning-report.csv). EASY is locked there unless unlocked (E).
'
CONST TUNE_MAX = 128
DIM SHARED tuneN, tuneKey$(TUNE_MAX), tuneName$(TUNE_MAX), tuneGroup$(TUNE_MAX), tuneUnit$(TUNE_MAX)
DIM SHARED tuneV(TUNE_MAX, 3) AS SINGLE, tuneD(TUNE_MAX, 3) AS SINGLE ' (its four values, and the defaults: tuning-defaults.txt's)
DIM SHARED tuneC(TUNE_MAX, 3) AS SINGLE ' (as coded: still this, a hook runs the old code)
DIM SHARED tuneLo(TUNE_MAX) AS SINGLE, tuneHi(TUNE_MAX) AS SINGLE, tuneStep(TUNE_MAX) AS SINGLE
DIM SHARED tuneKind(TUNE_MAX), tuneRef(TUNE_MAX) ' (what it is - TK_ - and which: a monster's type, a decoration's kind, a gun)
CONST TK_MONHP = 1, TK_DECOHP = 2, TK_GLASS = 3, TK_DROID = 4, TK_GUNDMG = 5, TK_GUNDELAY = 6, TK_PELLETS = 7
CONST TK_ROCKHIT = 8, TK_ROCKMON = 9, TK_KICK = 10, TK_WEAK = 11, TK_BLAST = 12, TK_HURT = 13
CONST TK_AMMOMAX = 14, TK_AMMOPICK = 15, TK_GUNPICK = 16 ' (the most of an ammo you carry, a box of it, a gun's own when you pick it up)
DIM SHARED tuneMaxRow(NUM_AMMO), tuneAmmoPick(NUM_AMMO), tuneGunPick(NUM_GUNS)
DIM SHARED tuneMonRow(MON_TYPES), tuneDecoRow(DECO_KINDS), tuneGunDmg(NUM_GUNS), tuneGunDelay(NUM_GUNS) ' (each one's row)
DIM SHARED tuGlass, tuDroid, tuPellets, tuRockHit, tuRockMon, tuKick, tuWeak, tuBlast, tuHurt
DIM SHARED tuneEasyOpen ' (the tuner's EASY column unlocked - E)
DIM SHARED tuneMonEasy ' (a monster's EASY health changed in the tuner: saving writes monsters.txt too)
DIM SHARED tuneDirty ' (changed since the last save)
DIM SHARED tnBlaster& ' (the tuner's picture of the blaster)
DIM SHARED tnRow, tnCol, tnTop, tnDone, tnLeave, tnMsg$, tnType$ ' (the tuner's: EDITOR/TUNER.BM)

TuneSetup ' (after the monsters' and guns' own numbers: chapter 3, GAME/GUNS.BI)
ReadTuning ' (tuning-defaults.txt, then the player's tuning.txt)
