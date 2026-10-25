''
' NEON-CASTER - LEVEL/PIECES.BI
' =============================================================================
' Pieces: a face divided, and its pieces divided again - up to four times
' (PC_DEPTH), so as many as 16 pieces (PC_LEAF), each with its own
' picture, slide, stretch, quarter turn and tint.
'
' A face's pieces are a tree, written in preorder: H a piece split left |
' right (across, as you see it), V one split top | bottom, . a piece that
' isn't - "H.V.." is a left piece, and a right one split top and bottom.
' The pieces (the dots, in order) each have a line of their own:
'   picture*turn*slide*stretch*tint*amount*colour*start*filters
' picture "" the usual one; turn 0-3 (quarter turns clockwise; 4-7 the
' same, flipped left for right first); slide and
' stretch as a [faces] line's (across + 64 * up, across + 2048 * up - 0 as
' made); tint 0 none, 1 TINT (multiplied), 2 WASH (mixed), 3 GLOW (added),
' its amount 0-100 and colour RRGGBB; start where its picture starts - 0
' the face's (it runs on across the pieces), 1 the piece's own top left
' corner, 2 one picture fitted to the piece; filters (PcFxApply) letters
' each with its number, in the order they're done (PC_FX$): X pixelate
' (blocks across: 32, 16, 8, 4), L blur, R sharpen, E emboss (1-4), B
' brightness, C contrast, S saturation (-100 to 100: -100 grey), H hue
' (degrees round), P posterize (levels: 32 down to 2), I invert - "B20S-100"
' brighter and grey. Left off from the end when as made.
' A [faces] line with division 3 keeps the tree as its first picture and
' the pieces, joined by |, as its second; a face only whole or halved,
' with no turn or tint and its halves slid alike, keeps the old line.
'
' Built (LoadLevel's BuildLevel): each such face is one of pcN, its
' pieces' rectangles a 16 x 16 grid (pcGrid: the piece at u 0-15 across,
' + 16 * v 0-15 down) - the renderers look a spot up in it - and each
' piece's picture slot (a turned or tinted one a copy of its own,
' MakePieceTex), slide and stretch.
'

CONST PC_MAX = 1024, PC_LEAF = 16, PC_DEPTH = 4
DIM SHARED pcN AS INTEGER, pcNL(PC_MAX) AS INTEGER ' (how many pieces each has)
DIM SHARED pcGrid(PC_MAX, 255) AS _UNSIGNED _BYTE
DIM SHARED pcGU0(PC_MAX, PC_LEAF) AS _BYTE, pcGV0(PC_MAX, PC_LEAF) AS _BYTE, pcGU1(PC_MAX, PC_LEAF) AS _BYTE, pcGV1(PC_MAX, PC_LEAF) AS _BYTE ' (each piece's rectangle, in 16ths: OpenGL's strips)
DIM SHARED pcSl(PC_MAX, PC_LEAF) AS INTEGER ' (0: the usual picture)
DIM SHARED pcOU(PC_MAX, PC_LEAF) AS INTEGER, pcOV(PC_MAX, PC_LEAF) AS INTEGER ' (slid: 64ths of the picture)
DIM SHARED pcKU(PC_MAX, PC_LEAF) AS INTEGER, pcKV(PC_MAX, PC_LEAF) AS INTEGER ' (stretched: percent - 0 as made)
DIM SHARED pcAn(PC_MAX, PC_LEAF) AS _BYTE ' (where its picture starts: 0 the face's, 1 the piece's corner, 2 fitted to the piece)
' A tree being read or changed (PcTreeRead, PcTreeForm and the editor):
' its shape and its pieces
DIM SHARED ptShape$, ptN AS INTEGER
DIM SHARED ptPic$(PC_LEAF), ptRot(PC_LEAF) AS INTEGER, ptO(PC_LEAF) AS INTEGER, ptK(PC_LEAF) AS LONG
DIM SHARED ptTM(PC_LEAF) AS INTEGER, ptTA(PC_LEAF) AS INTEGER, ptTC(PC_LEAF) AS _UNSIGNED LONG, ptA(PC_LEAF) AS INTEGER
DIM SHARED ptFx$(PC_LEAF) ' (its filters: "" none)
CONST PC_FX$ = "XLREBCSHPI" ' (the filters, in the order they're done)
REDIM SHARED pcFxBuf(0) AS _UNSIGNED LONG ' (a picture being filtered: n x n, row by row - PcFxApply)
' The pieces' rectangles (PcRects): u across, v down, 0 to 1
DIM SHARED pcRU0(PC_LEAF), pcRV0(PC_LEAF), pcRU1(PC_LEAF), pcRV1(PC_LEAF)
