''
' NEON-CASTER - RENDER/PARTICLES.BI
' =============================================================================
' Particles, scorch marks and light shafts (chapter 24).
'

' The particles themselves (spawned and moved by the game, chapter 13):
' where, how fast, how long they've left (partLife, 0 = free) out of
' partMax, colour, size, and kind (PART_)
CONST PART_SPARK = 1, PART_EMBER = 2, PART_DUST = 3, PART_FLAME = 4, PART_SMOKE = 5, PART_ARC = 6 ' (flames rise, smoke drifts up and spreads, an arc's points hang still a moment)
DIM SHARED partX(MAX_PART), partY(MAX_PART), partZ(MAX_PART), partVX(MAX_PART), partVY(MAX_PART), partVZ(MAX_PART)
DIM SHARED partLife(MAX_PART) AS INTEGER, partMax(MAX_PART) AS INTEGER, partR(MAX_PART), partG(MAX_PART), partB(MAX_PART)
DIM SHARED partSize(MAX_PART), partKind(MAX_PART) AS INTEGER, partNext AS INTEGER, dustCount AS INTEGER
' LIGHT SHAFTS: a beam under each of the level's own lights (not a lamp's or
' a terminal's) standing in an open cell - shaftCell(x, y) is the light
' whose beam starts in that cell (0: none), from BuildShafts. A beam is
' SHAFT_TOP wide (from its middle to its edge) at the ceiling, spreading to
' SHAFT_FOOT at the floor; SHAFT_AMT is how much light it adds.
CONST SHAFT_TOP = 0.22, SHAFT_FOOT = 0.75, SHAFT_AMT = 1.1
DIM SHARED shaftCell(MAP_SIZE, MAP_SIZE) AS INTEGER
' The dust stirred by you: how far round you your walking moves it
CONST WAKE_REACH = 1.1
