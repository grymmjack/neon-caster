''
' NEON-CASTER - RENDER/SPRITES.BI
' =============================================================================
' The draw list (chapter 16): every sprite to draw this frame - and the
' scorch marks.
'

' The draw list: every sprite to draw this frame (chapter 16)
' DECALS: marks left where shots and explosions hit - where (x, y, z),
' which way the surface faces (nx, ny, nz), how big, and how many frames
' more it glows hot (decalHeat). The oldest is reused when they're all
' taken (decalNext). AddDecal makes one.
CONST MAX_DECALS = 96, DECAL_HEAT = 24
DIM SHARED decalX(MAX_DECALS), decalY(MAX_DECALS), decalZ(MAX_DECALS), decalNX(MAX_DECALS), decalNY(MAX_DECALS), decalNZ(MAX_DECALS)
DIM SHARED decalSize(MAX_DECALS), decalHeat(MAX_DECALS) AS INTEGER, decalOn(MAX_DECALS) AS INTEGER, decalNext AS INTEGER
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS + MAX_DECO + MAX_BLASTS + MAX_DECALS + 160 ' (+ traps)
DIM SHARED drawX(MAX_DRAW) AS SINGLE, drawY(MAX_DRAW) AS SINGLE, drawDistSq(MAX_DRAW) AS SINGLE
DIM SHARED drawSprite(MAX_DRAW) AS INTEGER, drawScale(MAX_DRAW) AS SINGLE, drawLift(MAX_DRAW) AS SINGLE
DIM SHARED drawSquash(MAX_DRAW) AS SINGLE, drawMinShade(MAX_DRAW) AS INTEGER, drawOrder(MAX_DRAW) AS INTEGER
DIM SHARED drawFace(MAX_DRAW) AS INTEGER ' (0: it turns to face you; 1-4: it stands flat, facing east, south, west or north - DrawFlat)
