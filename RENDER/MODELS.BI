''
' NEON-CASTER - RENDER/MODELS.BI
' =============================================================================
' 3D props: decorations and pickups that are models - triangles - instead
' of a flat picture. RENDER/MODELS.BM loads and picks them.
'

' The models, numModels of them (1 to MAX_MODELS): each from
' neon-caster/models/NAME.obj (mdlName$), tinted mdlTint~& (a keycard's
' colour; 0: as it is). decoMdl(kind) and itemMdl(kind) say which model a
' decoration or pickup is - 0: it's a sprite (no model for it).
DIM SHARED numModels AS INTEGER, mdlName$(MAX_MODELS), mdlTint(MAX_MODELS) AS _UNSIGNED LONG
DIM SHARED turMuzX(2) AS SINGLE, turMuzY(2) AS SINGLE, turMuzZ(2) AS SINGLE ' (a turret head's two barrel ends - its model's muzzles: where its shots come out)
DIM SHARED plateMdl AS INTEGER ' (a pressure plate: models.py's plate - lying flat, square to the map)
DIM SHARED rocketMdl AS INTEGER, turBaseMdl AS INTEGER, turHeadMdl AS INTEGER, turPivot AS SINGLE, turPlateMdl AS INTEGER, turHoleMdl AS INTEGER ' (...and its mounting plate - whole, and blown open) ' (and a turret in two parts: its base, and its head turning on it turPivot up) ' (a rocket in flight: its model - models.py's rocket)
DIM SHARED mimicNapMdl AS INTEGER ' (the mimic asleep: a chest's model, but its lock)
DIM SHARED wreckMdl(DECO_KINDS) AS INTEGER ' (a decoration's own wreck - or an open chest - with a model: NAME-wreck.obj, chest-open.obj)
DIM SHARED decoMdl(DECO_KINDS) AS INTEGER, itemMdl(ITEM_KINDS) AS INTEGER, mtypeMdl(MON_TYPES) AS INTEGER ' (a monster with a model: the turret - mtypeMdl, by its name)
' Its triangles, every model's one after another: model m's are mdlFirst(m)
' to mdlFirst(m) + mdlCount(m) - 1. Corner j of triangle t is number
' t * 3 + j: where it is (mdlPX, PY, PZ: in cells, x the way the prop faces,
' y its right-hand side, z up from its floor) and where on the texture
' (mdlU, V: 0 to 1 from its top left). Each triangle's normal - the way it
' faces - is worked out once, as it's loaded (mdlNX, NY, NZ).
CONST MAX_MDL_TRIS = 16000
DIM SHARED mdlFirst(MAX_MODELS) AS LONG, mdlCount(MAX_MODELS) AS LONG, mdlTris AS LONG
DIM SHARED mdlPX(MAX_MDL_TRIS * 3) AS SINGLE, mdlPY(MAX_MDL_TRIS * 3) AS SINGLE, mdlPZ(MAX_MDL_TRIS * 3) AS SINGLE
DIM SHARED mdlU(MAX_MDL_TRIS * 3) AS SINGLE, mdlV(MAX_MDL_TRIS * 3) AS SINGLE
DIM SHARED mdlNX(MAX_MDL_TRIS) AS SINGLE, mdlNY(MAX_MDL_TRIS) AS SINGLE, mdlNZ(MAX_MDL_TRIS) AS SINGLE
' The 8 pictures of each, for the software renderer (MDL_PIC square, ART or
' not: it never draws a sprite bigger): model m's picture a (0-7) is
' mdlPic(x, y, (m - 1) * MDL_ANGLES + a + 1). They're mdlFrame(m) cells
' across - wider than the prop, so it fits seen from any way round.
CONST MDL_ANGLES = 8, MDL_PIC = 64
' OpenGL draws a model out to MODEL_NEAR cells away, if its cell was seen
' this frame; further, and in reflections, its picture from the nearest of
' its 8 ways round, as the software renderer does - so it never seems to
' turn as it changes. (Every corner of a model is worked out by QB64 each
' frame: at 32 cells, a sector's props cost 8 to 19 ms a frame.)
' A small one (under 3/4 of a cell across its pictures - a barrel, a
' pickup) only out to MODEL_NEAR_SMALL: that far off it's a few dozen
' pixels tall, and a stockpile's stacks of barrels were tens of thousands
' of corners a frame.
CONST MODEL_NEAR = 12, MODEL_NEAR_SMALL = 6, MODEL_NEAR_MID = 9 ' (under a cell across - a vending machine, a desk: 9)
DIM SHARED mdlPic(MDL_PIC - 1, MDL_PIC - 1, MAX_MODELS * MDL_ANGLES) AS _UNSIGNED LONG, mdlFrame(MAX_MODELS) AS SINGLE
