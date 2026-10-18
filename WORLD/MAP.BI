''
' NEON-CASTER - WORLD/MAP.BI
' =============================================================================
' Chapter 2: the world is a grid - walls, diagonals, blocks, and each
' cell's floor and ceiling pictures.
'

'-----------------------------------------------------------------------------
' CHAPTER 2: THE WORLD IS A GRID
'-----------------------------------------------------------------------------
' A level is a 48 x 48 grid of cells (MAP_SIZE). Positions in the world are
' measured in cells: x runs left to right, y runs top to bottom, and you
' might be standing at (20.5, 24.5) - the middle of cell (20, 24). Turning a
' position into its cell is just INT().
'
' worldMap() says what each cell is: 0 floor, 2 a door, and 1, 3, 4, 5, 6,
' 7 the six kinds of wall (they only differ in looks). The other arrays add
' details for some cells. They're DIM SHARED so every SUB and FUNCTION can
' use them without passing them in.
'
' Diagonal walls cut a cell corner to corner: half wall, half floor.
' diagCorner() says which corner's half is solid (chapter 15 draws them,
' chapter 23 has the maths), and the floor and ceiling can be split the same
' way (floorSplit, ceilSplit) to paint diagonal stripes.
CONST MAP_SIZE = 48
' worldMap: 0 floor, 2 door; walls 1 (#), 3 (N), 4 (C), 5 (K), 6 (P), 7 (G):
' six kinds of wall, whose textures each level picks (see chapter 22)
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
' Diagonal walls: which corner's half of the cell is solid - 0 not diagonal,
' 1 top-left, 2 top-right, 3 bottom-right, 4 bottom-left. Its worldMap value
' is the wall it looks like.
DIM SHARED diagCorner(MAP_SIZE, MAP_SIZE) AS INTEGER
' Boxes: a solid block standing in an open cell - a pillar, a thin wall, the
' back of an alcove - its edges anywhere in the cell, in eighths (boxX0 ..
' boxX1 across, boxY0 .. boxY1 down, 0 to 1), floor to ceiling. boxOn is
' the wall it looks like (1 to 7, as worldMap's walls; 0: no box). The
' level file's [boxes] lines (lvlBox: x, y, x0, y0, x1, y1 in eighths,
' and its wall, 1 to 6 for # N C K P G) - chapter 23 has the maths.
CONST MAX_BOXES = 256, BOX_MIN = 0.125
DIM SHARED boxOn(MAP_SIZE, MAP_SIZE) AS INTEGER, boxAny AS INTEGER
DIM SHARED boxX0(MAP_SIZE, MAP_SIZE) AS SINGLE, boxY0(MAP_SIZE, MAP_SIZE) AS SINGLE, boxX1(MAP_SIZE, MAP_SIZE) AS SINGLE, boxY1(MAP_SIZE, MAP_SIZE) AS SINGLE
DIM SHARED lvlNumBoxes AS INTEGER, lvlBox(MAX_BOXES, 7) AS SINGLE
' Each cell's floor and ceiling texture (a texture slot - chapter 5)
DIM SHARED floorTex(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilTex(MAP_SIZE, MAP_SIZE) AS INTEGER
' Floor / ceiling diagonals: a cell's floor (or ceiling) can be split corner
' to corner like a diagonal wall. floorSplit (ceilSplit) is the corner whose
' half uses floorTex2 (ceilTex2) instead; 0 = all of it is floorTex (ceilTex).
DIM SHARED floorTex2(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilTex2(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED floorSplit(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilSplit(MAP_SIZE, MAP_SIZE) AS INTEGER
