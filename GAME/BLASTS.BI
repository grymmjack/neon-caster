''
' NEON-CASTER - GAME/BLASTS.BI
' =============================================================================
' Explosions: how far a blast reaches, and the blasts going off.
'

' BLAST_ = explosions: how far a blast reaches (in cells), and - for the
' picture of one - up to MAX_BLASTS on show at once, each fading over
' BLAST_FRAMES frames. blastSize is 1 for a barrel, smaller for the puff of
' sparks from a broken lamp or terminal.
CONST BLAST_RADIUS = 2.2
CONST MAX_BLASTS = 12, BLAST_FRAMES = 18
DIM SHARED blastX(MAX_BLASTS) AS SINGLE, blastY(MAX_BLASTS) AS SINGLE, blastTime(MAX_BLASTS) AS INTEGER
DIM SHARED blastSize(MAX_BLASTS) AS SINGLE
