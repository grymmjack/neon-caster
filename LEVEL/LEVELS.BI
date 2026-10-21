''
' NEON-CASTER - LEVEL/LEVELS.BI
' =============================================================================
' Levels and sector sets (chapter 20).
'

CONST NUM_LEVELS = 10 ' NUM_ = how many there are
' Sector sets: the game's own ten (0), NEW SECTORS (1), OLD SECTORS NEW
' (2, the first ten remade) and HUGE SECTORS (3, ten big ones, up to 200
' cells across - levels/hugesectors.py) - each numbered 1 to NUM_LEVELS, so a sector's
' music, NEXUS's words for it and the tally at the end go by its number,
' and each in a folder of its own (SetDir$). sectorSet is the one played.
CONST NUM_SETS = 3
DIM SHARED sectorSet AS INTEGER
' Your own sectors (GAME > YOUR SECTORS - chapter 22; MORE SECTORS past ten): up to MAX_CUSTOM,
' numbered on from the game's - sector 11 is levels/custom/custom1.txt
CONST MAX_CUSTOM = 30 ' (YOUR SECTORS shows ten: MORE SECTORS the rest, scrolling)

DIM SHARED monStartN AS INTEGER, monStartX(MAX_MON), monStartY(MAX_MON), monStartType(MAX_MON) AS INTEGER
DIM SHARED sectorName$(NUM_LEVELS + MAX_CUSTOM) ' (every level's name, for the route map and SELECT SECTOR: ReadSectorNames - "" for a sector of yours not made yet)
' The level-done tally's rows (chapter 20): what each says, the number it
' counts up to, what that's out of (-1: a time, as m:ss), the number shown
' so far, and frames since it landed (-1: not yet)
DIM SHARED tallyLabel$(6), tallyTarget(6), tallyTotal(6), tallyShown(6), tallySlam(6)
DIM SHARED keepMX(MAX_MON), keepMY(MAX_MON), keepMDX(MAX_MON), keepMDY(MAX_MON), keepIX(MAX_ITEMS), keepIY(MAX_ITEMS), keepIK(MAX_ITEMS) ' (EditApply: the monsters you'd killed - where they started, where they fell - and the pickups you'd taken)
DIM SHARED savedHasGun(NUM_GUNS) ' What you had on entering the level (you get it back if you die)
