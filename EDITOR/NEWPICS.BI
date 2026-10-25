''
' NEON-CASTER - EDITOR/NEWPICS.BI
' =============================================================================
' New pictures, drawn in a paint program: the picker's WALLS, FLOORS and
' CEILINGS tabs start with + NEW, which makes a placeholder - wall-new1.png
' (floor-new1, ceiling-new1...) in neon-caster/, 64 x 64 (Shift: 512, HD's
' size), a checker saying PLACEHOLDER 1 WALL 64X64 - and makes it PAINT's
' picture. Alt+E (or OPEN IN DRAW on the PICTURE pane) opens a picture in
' your paint program: the one in the picker under the pointer, else on the
' face under it, else PAINT's. The editor keeps an eye on every picture it
' made or opened (twice a second, by a sum of its bytes): saved there, it's
' loaded again here - every face it's on, in both renderers. DRAW's Ctrl+S
' on a PNG keeps its layers in NAME.draw beside it and writes only that
' from then on: a .draw that changes is flattened into the PNG (NpFromDraw),
' and Alt+E opens the .draw when there is one, layers and all.
'
' Which program: image_editor= in settings.ini (the imageeditor command) -
' left empty, DRAW if it's in ~/git/DRAW, else the system's own opener
' (xdg-open, open, start). (EDITOR/NEWPICS.BM)
'
CONST NP_WATCH = 32
DIM SHARED imgEditor$ ' (image_editor= : a path - "" looks for DRAW)
DIM SHARED npN AS INTEGER, npFile$(NP_WATCH), npPath$(NP_WATCH), npSum&(NP_WATCH), npWant&(NP_WATCH), npT#
DIM SHARED npDPath$(NP_WATCH), npDSum&(NP_WATCH), npDWant&(NP_WATCH) ' (DRAW's project beside it, NAME.draw - a PNG of the flattened picture with its layers inside: DRAW's Ctrl+S writes that, not the PNG)
'
' The picker's right-click menu on a picture (NpMenuOpen): RENAME it (the
' part after wall- - typed, edTypeFor 9), its ANIMATION (an ending word
' OpenGL reads - NpEnd$: -flicker, -wave, -pulse, -pulse-dry, and -still
' for none when its name's words would make it go), OPEN IN DRAW, OPEN
' FOLDER, OPEN IN KALEIDOTRON and DELETE (npAsk: the menu asks first, its
' lines npAskLine$ saying what uses it). A picture that comes with the game
' (pictures-shipped.txt, read into npShip$) is never renamed or deleted.
' npMenuX/Y: its corner on the canvas the picker's drawn on (FULL WIDE: our
' screen's numbers + edWX in 3D). npEatR: the right press that opened (or
' closed) it isn't a look round, or a right-click on the map, till let go.
CONST NP_MW = 230, NP_MROWS = 12, NP_MROWH = 13
DIM SHARED npMenuOn AS INTEGER, npMenuPic$, npMenuX, npMenuY, npEatR AS INTEGER, npRWas AS INTEGER
DIM SHARED npAsk AS INTEGER, npAskLine$(8), npShip$, npShipRead AS INTEGER, npOtherN ' (npOtherN: how many other sectors' files the last rename or delete changed)
