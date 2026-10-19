''
' NEON-CASTER - RENDER/MODELS.BI
' =============================================================================
' 3D props: decorations that are models - triangles - instead of a flat
' picture (just the chair so far). RENDER/MODELS.BM loads them.
'

' A model's triangles, every prop's one after another: prop m's are
' mdlFirst(m) to mdlFirst(m) + mdlCount(m) - 1. Corner j of triangle t is
' number t * 3 + j: where it is (mdlPX, PY, PZ: in cells, x the way the
' prop faces, y its right-hand side, z up from its floor) and where on the
' texture (mdlU, V: 0 to 1 from its top left). Each triangle's normal - the
' way it faces - is worked out once, as it's loaded (mdlNX, NY, NZ).
CONST MAX_MDL_TRIS = 1500
DIM SHARED mdlFirst(MODEL_KINDS) AS LONG, mdlCount(MODEL_KINDS) AS LONG, mdlTris AS LONG
DIM SHARED mdlPX(MAX_MDL_TRIS * 3) AS SINGLE, mdlPY(MAX_MDL_TRIS * 3) AS SINGLE, mdlPZ(MAX_MDL_TRIS * 3) AS SINGLE
DIM SHARED mdlU(MAX_MDL_TRIS * 3) AS SINGLE, mdlV(MAX_MDL_TRIS * 3) AS SINGLE
DIM SHARED mdlNX(MAX_MDL_TRIS) AS SINGLE, mdlNY(MAX_MDL_TRIS) AS SINGLE, mdlNZ(MAX_MDL_TRIS) AS SINGLE
