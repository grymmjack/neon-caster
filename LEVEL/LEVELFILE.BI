''
' NEON-CASTER - LEVEL/LEVELFILE.BI
' =============================================================================
' A level as its file says it (chapter 22): the [sections] read in.
'

' A level as its file says it (ReadLevelFile, chapter 22): its name, its
' pictures, its ambient light, its zones, lights and event rooms, and its
' map's rows - LoadLevel builds the level from these
CONST MAX_ZONES = 256 ' (a huge sector has 70-odd)
DIM SHARED lvlNote$ ' (the comments at the top of its file, kept when the editor saves it)
' [faces]: a picture on one face - a wall's side, a step's or a lintel's,
' a floor, a ceiling - instead of the usual. lvlFaceS: 1-4 a side (east,
' south, west, north - a wall's, or a step's face), 5-8 a lintel's side,
' 9 the floor, 10 the ceiling. lvlFaceD: 0 the whole face; 1 divided
' left | right, 2 top | bottom - the second picture on the second half;
' 3 in pieces (LEVEL/PIECES.BI: the tree and each piece's look).
' BuildLevel gives each picture a slot (T_CUSTOM + n) and the cells
' faceTex(x, y, 1-8) - 0: the usual - floorTex, ceilTex.
CONST MAX_FACES = 4000
' [pads]: teleporters paired by hand (the editor's LINK) - x1, y1, x2, y2.
' Pads in no pair here pair up as ever, in reading order.
CONST MAX_PAIRS = MAX_PADS \ 2 ' (two pads a pair)
DIM SHARED lvlNumPairs AS INTEGER, lvlPair(MAX_PAIRS, 4) AS INTEGER
' [monsters]: one monster's own settings, by the cell it starts in - x, y,
' sight, hearing (cells), health, speed (% of its kind's), wake (WAKE_),
' and a turret's weapon (TW_ - an 8th number, left off when it's 0) and
' how fast it turns (degrees a second - a 9th, left off when it's 0: as made)
CONST MON_COLS = 11
DIM SHARED lvlReadFrom$ ' (a level file to read in place of the sector's own - loadlevelfromdisk: EditReload)
DIM SHARED lvlMonN AS INTEGER, lvlMon(MAX_MON, MON_COLS) AS SINGLE
DIM SHARED lvlNumFaces AS INTEGER, lvlFaceX(MAX_FACES) AS INTEGER, lvlFaceY(MAX_FACES) AS INTEGER, lvlFaceS(MAX_FACES) AS INTEGER, lvlFaceD(MAX_FACES) AS INTEGER
DIM SHARED lvlFaceP1$(MAX_FACES), lvlFaceP2$(MAX_FACES)
DIM SHARED lvlFaceO(MAX_FACES) AS INTEGER ' (its picture's offset: across + 64 * up, each in 64ths of the picture - a pixel of a 64 one - 0-63: the 7th and 8th numbers of a [faces] line)
DIM SHARED lvlFaceK(MAX_FACES) AS LONG ' (its picture's stretch: across + 2048 * up, each a percentage - 0 as it is, 100 - the 9th and 10th numbers)
DIM SHARED faceAny AS INTEGER ' (any face with a slot of its own this level: the renderers ask faceTex only then)
CONST FACE_BOX = 10, FACE_MAX = 14 ' (a box's sides are faces 11 to 14 - FACE_BOX + 1 east .. 4 north: BE, BS, BW, BN)
DIM SHARED faceTex(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER, faceTex2(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER, faceDiv(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER
' A face's picture slid along (across) and up it, in 64ths of the picture (0-63;
' floors and ceilings too, faces 9 and 10), and stretched across and up
' (faceKU, faceKV: percent, 0 as it is): both renderers read the picture at
' (where they would) / stretch + slide - the stretch measured from the
' map's own grid, so faces stretched alike run on into each other (a
' picture 200% wide covers two cells of a wall, not one cell's half twice).
' faceOffAny: any this sector.
DIM SHARED faceOU(MAP_SIZE, MAP_SIZE, FACE_MAX) AS _BYTE, faceOV(MAP_SIZE, MAP_SIZE, FACE_MAX) AS _BYTE, faceOffAny AS INTEGER
DIM SHARED faceKU(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER, faceKV(MAP_SIZE, MAP_SIZE, FACE_MAX) AS INTEGER
DIM SHARED lvlName$, lvlWall$(6), lvlFloor$(4), lvlCeil$(2), lvlAmb(4), lvlOK AS INTEGER
' Cell lights ([cell lights]): a cell with an ambient light of its own, not
' the sector's - lvlCLBright 0-256 (-1: the sector's light), its colour
' lvlCLCol~&, its effect lvlCLFx (a light's FX_: steady, flicker, pulse,
' strobe, fire, dying). In the file, boxes of cells alike.
DIM SHARED lvlCLBright(MAP_SIZE - 1, MAP_SIZE - 1) AS INTEGER, lvlCLCol(MAP_SIZE - 1, MAP_SIZE - 1) AS _UNSIGNED LONG, lvlCLFx(MAP_SIZE - 1, MAP_SIZE - 1) AS INTEGER
DIM SHARED lvlNumZones AS INTEGER, lvlZone(MAX_ZONES, 7) AS INTEGER
DIM SHARED lvlNumLights AS INTEGER, lvlLight(MAX_LIGHTS, 9) AS SINGLE
DIM SHARED lvlNumEvents AS INTEGER, lvlEvent(MAX_EVENTS, 8) AS INTEGER
DIM SHARED lvlRow$(MAP_SIZE - 1)
