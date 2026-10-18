''
' NEON-CASTER - GAME/TELEPORTERS.BI
' =============================================================================
' Teleporters (& on the map): pads that pair up.
'

' --- Teleporters (& on the map): pads that pair up in the order they're
' found, reading the map like a book - the 1st with the 2nd, the 3rd with
' the 4th. Step on one and you're on the other (padReady: you've stepped
' off since, so you don't bounce straight back).
CONST MAX_PADS = 16
DIM SHARED numPads AS INTEGER, padX(MAX_PADS) AS INTEGER, padY(MAX_PADS) AS INTEGER, padReady AS INTEGER
DIM SHARED padFlown(MAX_PADS) AS INTEGER ' (you've teleported from this pad this time in the sector: Frequent Flyer counts each pad once - not back and forth)
