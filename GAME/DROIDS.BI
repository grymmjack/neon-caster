''
' NEON-CASTER - GAME/DROIDS.BI
' =============================================================================
' Droids: the little service robots going about their business.
'

' DROIDS: little service robots going about their business - rolling from
' place to place, stopping to scrub the floor or see to a machine, chirping,
' and scuttling out of your way. Harmless; a shot breaks one. (UpdateDroids:
' they roll by their own dice, drSeed - started from the sector, so they go
' the same way every time, in a demo too.) droidKind 1 the tread droid,
' 2 the dome droid; droidState 0 deciding, 1 rolling to (droidTX, droidTY),
' 2 at work (droidWork: the decoration it's seeing to, or 0), 3 scuttling
' off; droidHP 0: broken.
CONST MAX_DROIDS = 6, DROID_SPEED = 0.02, DROID_HP = 4
DIM SHARED droidX(MAX_DROIDS) AS SINGLE, droidY(MAX_DROIDS) AS SINGLE, droidA(MAX_DROIDS) AS SINGLE, numDroids AS INTEGER
DIM SHARED droidKind(MAX_DROIDS) AS INTEGER, droidState(MAX_DROIDS) AS INTEGER, droidTimer(MAX_DROIDS) AS INTEGER, droidHP(MAX_DROIDS) AS INTEGER
DIM SHARED droidTX(MAX_DROIDS) AS SINGLE, droidTY(MAX_DROIDS) AS SINGLE, droidWork(MAX_DROIDS) AS INTEGER, droidZ(MAX_DROIDS) AS SINGLE, drSeed AS DOUBLE
DIM SHARED lvlDroids AS INTEGER ' (droids = in the level file: how many droids it has, 0 to MAX_DROIDS - or -1, not said: 3)
