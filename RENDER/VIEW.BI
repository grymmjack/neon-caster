''
' NEON-CASTER - RENDER/VIEW.BI
' =============================================================================
' The 3D view (chapter 5): its size, the pixels it's drawn into, the
' sky, and the drawing code's LONG loop counters.
'

' --- The 3D view: drawn at half size, then stretched 2x onto the window ---
' RENDER_ = the size of the 3D view in pixels (W = width, H = height);
' (texSize: how big each texture is - see sprTex above)
CONST RENDER_W = 400, RENDER_H = 300
CONST MAX_CLIPS = 24
DIM SHARED clipN(RENDER_W) AS INTEGER, clipD(RENDER_W, MAX_CLIPS) AS SINGLE, clipT(RENDER_W, MAX_CLIPS) AS INTEGER, clipB(RENDER_W, MAX_CLIPS) AS INTEGER
DIM SHARED glassT(RENDER_W) AS SINGLE, glassU(RENDER_W) AS SINGLE, glassCX(RENDER_W) AS INTEGER, glassCY(RENDER_W) AS INTEGER, glassDone(RENDER_W) AS INTEGER
DIM SHARED pixels(0 TO RENDER_W * RENDER_H - 1) AS _UNSIGNED LONG
DIM SHARED zBuffer(RENDER_W - 1) AS SINGLE
' The image the view is copied into each frame. _MEMIMAGE and _MEM give us
' "memory blocks" for the image and the array, so _MEMCOPY can copy all
' 120,000 colours from one to the other at once.
renderImg& = _NEWIMAGE(RENDER_W, RENDER_H, 32)
DIM renderMem AS _MEM, pixelsMem AS _MEM
renderMem = _MEMIMAGE(renderImg&) : pixelsMem = _MEM(pixels())

' Loop counters and pixel positions used by the drawing code are LONG
' (whole numbers) - integer maths is quicker in the inner loops. Anything
' not DIMmed is a SINGLE (a decimal number), QB64PE's default.
DIM SHARED rowF(RENDER_H - 1) AS SINGLE, rowC(RENDER_H - 1) AS SINGLE ' (HeightColumn: each row's distance per unit of height)
' SKY: a ceiling picture called sky-*.png isn't laid on the ceiling - it's
' drawn by the way you look, like Doom's sky, so it seems endlessly far
' off: across, the whole way round (SKY_REPEAT copies); up, its bottom row
' at the horizon and its top SKY_EL radians (72 degrees) up. (Painted five
' times as wide as it's tall and squeezed square - levels/skies.py.)
' texSky(slot): that slot is a sky. skyU / skyV: the software renderer's
' column and row into it, worked out once a frame.
CONST SKY_REPEAT = 1, SKY_EL = 1.2566 ' (a panorama: the whole way round across, 72 degrees up)
DIM SHARED skyU(RENDER_W - 1) AS INTEGER, skyV(RENDER_H - 1) AS INTEGER

DIM SHARED x AS LONG, y AS LONG, texU AS LONG, texV AS LONG, texX AS LONG
DIM floorRow AS LONG, ceilRow AS LONG, drawStart AS LONG, drawEnd AS LONG
DIM cellX AS LONG, cellY AS LONG, lastCellX AS LONG, lastCellY AS LONG, floorSlot AS LONG, ceilSlot AS LONG
DIM cellFloor AS LONG, cellCeil AS LONG, splitCell AS LONG, cellTrack AS LONG


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED hB&, hBot, hDOut, hG&, hor, hR&, hSlot, hSlot2, hTexX, hTop, hVOff, tMask, yA, yB, hZ0, hZ1 ' (hZ0 and hZ1: the face's top and bottom, for the exit's sign)
