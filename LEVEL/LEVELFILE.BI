''
' NEON-CASTER - LEVEL/LEVELFILE.BI
' =============================================================================
' A level as its file says it (chapter 22): the [sections] read in.
'

' A level as its file says it (ReadLevelFile, chapter 22): its name, its
' pictures, its ambient light, its zones, lights and event rooms, and its
' map's rows - LoadLevel builds the level from these
CONST MAX_ZONES = 64
DIM SHARED lvlNote$ ' (the comments at the top of its file, kept when the editor saves it)
' [faces]: a picture on one face - a wall's side, a step's or a lintel's,
' a floor, a ceiling - instead of the usual. lvlFaceS: 1-4 a side (east,
' south, west, north - a wall's, or a step's face), 5-8 a lintel's side,
' 9 the floor, 10 the ceiling. lvlFaceD: 0 the whole face; 1 divided
' left | right, 2 top | bottom - the second picture on the second half.
' BuildLevel gives each picture a slot (T_CUSTOM + n) and the cells
' faceTex(x, y, 1-8) - 0: the usual - floorTex, ceilTex.
CONST MAX_FACES = 4000
' [pads]: teleporters paired by hand (the editor's LINK) - x1, y1, x2, y2.
' Pads in no pair here pair up as ever, in reading order.
DIM SHARED lvlNumPairs AS INTEGER, lvlPair(16, 4) AS INTEGER
' [monsters]: one monster's own settings, by the cell it starts in - x, y,
' sight, hearing (cells), health, speed (% of its kind's), wake (WAKE_)
DIM SHARED lvlMonN AS INTEGER, lvlMon(MAX_MON, 7) AS SINGLE
DIM SHARED lvlNumFaces AS INTEGER, lvlFaceX(MAX_FACES) AS INTEGER, lvlFaceY(MAX_FACES) AS INTEGER, lvlFaceS(MAX_FACES) AS INTEGER, lvlFaceD(MAX_FACES) AS INTEGER
DIM SHARED lvlFaceP1$(MAX_FACES), lvlFaceP2$(MAX_FACES)
DIM SHARED faceAny AS INTEGER ' (any face with a slot of its own this level: the renderers ask faceTex only then)
CONST FACE_BOX = 10, FACE_MAX = 14 ' (a box's sides are faces 11 to 14 - FACE_BOX + 1 east .. 4 north: BE, BS, BW, BN)
DIM SHARED faceTex(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER, faceTex2(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER, faceDiv(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER
DIM SHARED lvlName$, lvlWall$(6), lvlFloor$(4), lvlCeil$(2), lvlAmb(4), lvlOK AS INTEGER
DIM SHARED lvlNumZones AS INTEGER, lvlZone(MAX_ZONES, 7) AS INTEGER
DIM SHARED lvlNumLights AS INTEGER, lvlLight(MAX_LIGHTS, 8) AS SINGLE
DIM SHARED lvlNumEvents AS INTEGER, lvlEvent(MAX_EVENTS, 8) AS INTEGER
DIM SHARED lvlRow$(MAP_SIZE - 1)
