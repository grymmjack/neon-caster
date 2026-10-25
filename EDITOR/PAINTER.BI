''
' NEON-CASTER - EDITOR/PAINTER.BI
' =============================================================================
' THE PAINTER: a little paint program inside the game, for the editor's
' pictures - Ctrl+E (or PAINT HERE on the PICTURE pane, or the picker's
' right-click menu) opens the picture under the pointer. Pencil, a round
' brush, lines, rectangles and ellipses (outlined or filled), flood fill
' and a colour picker; two colours (left button, right button), a palette,
' red green blue and typed hex; undo and redo; zoom, a grid, the picture
' TILED round itself (to see its seams) and WRAP (drawing off one edge
' comes in at the other); MIRROR left-right and up-down. Ctrl+S saves the
' PNG and the sector shows it at once (NpReload).
'
' What it paints is a sheet: one picture, or several faces' pictures laid
' side by side (PAINT ACROSS on the PICTURE pane: paTN tiles, each saved to
' its own file and put on its own face - paTG says which tile a sheet's
' square of paTS pixels is, 0 a gap that isn't painted). (EDITOR/PAINTER.BM)
'
CONST PA_UNDO = 40, PA_TILES = 64, PA_BTNS = 140
CONST PA_CX = 98, PA_CY = 30, PA_CW = 588, PA_CH = 536 ' (the canvas's part of the screen)
CONST PA_PENCIL = 1, PA_BRUSH = 2, PA_LINE = 3, PA_RECT = 4, PA_RECTF = 5, PA_ELL = 6, PA_ELLF = 7, PA_FILL = 8, PA_PICK = 9
DIM SHARED paImg&, paView&, paBack&, paMem AS _MEM, paMemOn AS INTEGER, paW, paH, paZ, paOX, paOY
DIM SHARED paTN, paTF$(PA_TILES), paTP$(PA_TILES), paTX(PA_TILES), paTY(PA_TILES), paTW(PA_TILES), paTH(PA_TILES)
DIM SHARED paTS, paTG(32, 32) AS INTEGER, paTFace(PA_TILES, 5) ' (a sheet's tiles: each one's face - x, y, face code, the editor's kind and side - for PAINT ACROSS)
DIM SHARED paTool, paSize, paFg AS _UNSIGNED LONG, paBg AS _UNSIGNED LONG, paMirX, paMirY, paWrap, paGrid, paTile
DIM SHARED paUndo&(PA_UNDO), paUndoN, paRedo&(PA_UNDO), paRedoN, paDirty, paMsg$, paTyping, paType$, paAsk, paNew
DIM SHARED paBN, paBX(PA_BTNS), paBY(PA_BTNS), paBW(PA_BTNS), paBH(PA_BTNS), paBId(PA_BTNS), paMX, paMY
DIM SHARED paPal~&(32), paPut, paSaved ' (paPut: a sheet's tiles are on their faces - PaAcrossPut; paSaved: Ctrl+S since it opened)
paTool = PA_BRUSH : paSize = 3 : paFg = &HFFFF2080~& : paBg = &HFF101020~& : paGrid = -1
