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
CONST MAX_DECALS = 160, DECAL_HEAT = 24
DIM SHARED decalX(MAX_DECALS), decalY(MAX_DECALS), decalZ(MAX_DECALS), decalNX(MAX_DECALS), decalNY(MAX_DECALS), decalNZ(MAX_DECALS)
DIM SHARED decalSize(MAX_DECALS), decalHeat(MAX_DECALS) AS INTEGER, decalOn(MAX_DECALS) AS INTEGER, decalNext AS INTEGER
' (a decal's kind: 0 a scorch, 1 an acid splash - a chemical stain, the
' inverse of what it's on, smoking for decalSmoke frames; newDecalKind:
' the next AddDecal's)
DIM SHARED decalKind(MAX_DECALS) AS INTEGER, decalSmoke(MAX_DECALS) AS INTEGER, newDecalKind AS INTEGER
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS + MAX_DECO + MAX_BLASTS + MAX_DECALS + 160 ' (+ traps)
DIM SHARED drawX(MAX_DRAW) AS SINGLE, drawY(MAX_DRAW) AS SINGLE, drawDistSq(MAX_DRAW) AS SINGLE
DIM SHARED drawSprite(MAX_DRAW) AS INTEGER, drawScale(MAX_DRAW) AS SINGLE, drawLift(MAX_DRAW) AS SINGLE
DIM SHARED drawSquash(MAX_DRAW) AS SINGLE, drawMinShade(MAX_DRAW) AS INTEGER, drawOrder(MAX_DRAW) AS INTEGER
DIM SHARED drawRed(MAX_DRAW) AS INTEGER ' (a 3D monster just hit: OpenGL draws its model flushed red)
DIM SHARED drawMdl(MAX_DRAW) AS INTEGER, drawAng(MAX_DRAW), drawPic(MAX_DRAW) AS INTEGER ' (a 3D prop: which model, the way it faces, and its picture from where you are - RENDER/MODELS.BM)
' (a turret: tinted by its weapon - drawTint, its muzzles drawCap; hanging
' upside down - drawFlip; its model's up, if it isn't straight up - drawUpX,
' Y, Z - and then where its model stands, drawOX, OY, OZ: a ceiling or wall)
DIM SHARED drawTint(MAX_DRAW) AS _UNSIGNED LONG, drawCap(MAX_DRAW) AS _UNSIGNED LONG, drawFlip(MAX_DRAW) AS INTEGER
' (its pitch - nose up or down: a rocket - and a turret's head, aimed at
' you on its base: drawHead, its own way round and pitch)
DIM SHARED drawMZ(MAX_DRAW) AS SINGLE ' (a model squashed down to this much of its height: a broken prop, crumpled)
DIM SHARED drawPitch(MAX_DRAW) AS SINGLE, drawHead(MAX_DRAW) AS INTEGER, drawHAng(MAX_DRAW) AS SINGLE, drawHPitch(MAX_DRAW) AS SINGLE
DIM SHARED drawUpX(MAX_DRAW) AS SINGLE, drawUpY(MAX_DRAW) AS SINGLE, drawUpZ(MAX_DRAW) AS SINGLE, drawOX(MAX_DRAW) AS SINGLE, drawOY(MAX_DRAW) AS SINGLE, drawOZ(MAX_DRAW) AS SINGLE
DIM SHARED drawFace(MAX_DRAW) AS INTEGER ' (0: it turns to face you; 1-4: it stands flat, facing east, south, west or north - DrawFlat)
