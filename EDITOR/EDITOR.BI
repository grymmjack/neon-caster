''
' NEON-CASTER - EDITOR/EDITOR.BI
' =============================================================================
' The level editor (F2): its own state.
'

CONST ED_PALX = 596, ED_PALY = 44 ' (the editor's palette - chapter 21)
' The map from above: where cell (0, 0) is on the screen and how big a cell
' is - 12 pixels, as it opens on one of the game's sectors; a bigger one
' fits the view. Space + drag pans it, Space + the wheel zooms (EditFitMap,
' EditPanZoom). ED_VIEWW, ED_VIEWH: the part of the screen it's drawn in.
CONST ED_VIEWW = 588, ED_VIEWH = 578
DIM SHARED edMapX AS INTEGER, edMapY AS INTEGER, edCell AS INTEGER, edPanWas AS INTEGER, edPanMX AS INTEGER, edPanMY AS INTEGER
edMapX = 8 : edMapY = 8 : edCell = 12
' --- The level editor (chapter 21): F2. editMode: on; editView: 0 the map
' from above (RunEditor), 1 walking round inside it (EditFP, in the game
' loop). editGlyph$: what you're placing - a map character (chapter 22).
' Each change is made to the level as its file says it (lvlRow$() and
' the rest) and the level built again from that (BuildLevel); editUndo$()
' remembers how it was before each change. texFile$(): which picture is in
' each texture slot now, so building it again only loads what changed.
CONST EDIT_GLYPHS = ".#NCKPG/\DHXRBYE!=-@$%?&;rby+*uae2345Mqj89({}`,mghcskwzT1)670~_|]oiptxlnfSdAFIJLOQUWZV:['<>^v"
CONST EDIT_UNDO = 40
CONST EDIT_OPEN$ = ".rby+*uae2345Mqj89({}`,mghcskwzT1)670~_|]oiptxlnfSdAFIJLOQUWZV:['<>^v&" ' (the map characters that are floor - with something on it, or not: where a liquid can lie)
DIM SHARED editMode AS INTEGER, editView AS INTEGER, editGlyph$, editDirty AS INTEGER, editRebuild AS INTEGER
DIM SHARED edFullBright AS INTEGER, edFBDown AS INTEGER, edFBAlt AS INTEGER
DIM SHARED edMoving AS INTEGER, edMvDX AS INTEGER, edMvDY AS INTEGER, edMvSnap$ ' (from above: a drag moving the selection - 1 pressed on it, 2 moved, its undo kept; how far it's moved, and the sector before it) ' (Alt+L: every cell lit evenly while editing - UpdateLight; and the key still down)
DIM SHARED editUndo$(EDIT_UNDO), editUndoN AS INTEGER, editRedo$(EDIT_UNDO), editRedoN AS INTEGER, editMsg$, editMsgUntil!, editLightP AS INTEGER, editLights AS INTEGER, editHeights AS INTEGER
' THE EDITOR'S OWN STATE, the same in both views (the map from above and
' the 3D view), so switching between them loses nothing:
'   ed hover...   the face under the cursor (kind, cell, side, part) - ED_ kinds
'   edSel...      the faces selected (up to ED_MAXSEL), kept until Ctrl+D
'   edTool        what a click does (ET_ tools); edBrush... what it places
'   edGrid...     the wireframe grid over the world, and how strong it is
'   edPick...     the picker panel: its tab and how far it's scrolled
CONST ED_WALL = 1, ED_FLOOR = 2, ED_CEIL = 3, ED_STEP = 4, ED_LINTEL = 5, ED_BOX = 6, ED_DIAG = 7, ED_DEDGE = 8, ED_TRACK = 9 ' (a door's edges - a shutter's underside - and its track; a face: a diagonal wall's slanted face (side 0); a box's side; a wall's side, a floor, a ceiling, the face of a step up, the face of a ceiling stepping down)
CONST ED_MAXSEL = 16384 ' (a 128 x 128 plaza - a 48 map's whole, twice over and more)
CONST ET_SELECT = 1, ET_PLACE = 2, ET_PAINT = 3, ET_LIGHT = 4, ET_HEIGHT = 5
DIM SHARED edHovKind AS INTEGER, edHovX AS INTEGER, edHovY AS INTEGER, edHovSide AS INTEGER, edHovPart AS INTEGER
DIM SHARED edHovPX, edHovPY, edHovPZ ' (exactly where the cursor's ray met it)
DIM SHARED edHovThing AS INTEGER ' (the pointer's on a thing standing in a cell - a monster, a pickup... - not a face: EditPickThing)
DIM SHARED edSelN AS LONG, edSelKind(ED_MAXSEL) AS INTEGER, edSelX(ED_MAXSEL) AS INTEGER, edSelY(ED_MAXSEL) AS INTEGER
DIM SHARED edSelSide(ED_MAXSEL) AS INTEGER, edSelPart(ED_MAXSEL) AS INTEGER
DIM SHARED edKeepN AS LONG, edKeepKind(ED_MAXSEL) AS INTEGER, edKeepX(ED_MAXSEL) AS INTEGER, edKeepY(ED_MAXSEL) AS INTEGER, edKeepSide(ED_MAXSEL) AS INTEGER, edKeepPart(ED_MAXSEL) AS INTEGER ' (the selection, kept while Ctrl+click PAINT borrows it - EditSelKeep)
DIM SHARED edTool AS INTEGER, edGrid AS INTEGER, edGridAlpha AS INTEGER, edPickTab AS INTEGER, edPickScroll AS INTEGER
DIM SHARED edLooking AS INTEGER ' (the right button held in the 3D view: the mouse turns you instead of moving the cursor)
DIM SHARED edMouseFix AS INTEGER, edWheel AS INTEGER, edCurX AS INTEGER, edCurY AS INTEGER ' (put the pointer right again; the wheel's turns for the editor; where the pointer is)
DIM SHARED edCamPX, edCamPY, edCamDX, edCamDY, edCamPlane, edCamZoom ' (the camera, this frame: EditFP copies it here for the picking and outlines)
DIM SHARED edWheelT! ' (when the wheel last moved something: a run of turns is one undo)
' Each letter key held down now (a to z, by its small letter) - and whether
' Ctrl was down when it went down: only then is it Ctrl+S, Ctrl+Z, Ctrl+D.
' (Walking with D held and pressing Ctrl for the wheel, D's auto-repeat
' would otherwise clear the selection - and S's would save.)
DIM SHARED edKeyHeld(122) AS INTEGER, edKeyCtrl(122) AS INTEGER
DIM SHARED edCtrl AS INTEGER ' (Ctrl, as the keys arrive - in order, so a quick Ctrl+S still is one)
DIM SHARED gridOn AS INTEGER, gridW AS INTEGER ' (the software renderer's grid this frame, and its lines' width in texels)
DIM SHARED gridA AS INTEGER, gridKeyWas AS INTEGER ' (...how strong, 0-255: the editor's edGridAlpha, or in play GRID STRENGTH - and the grid keys held last frame)
' THE TOOLBAR (EditTBLayout): its buttons this frame - which (TB_), where -
' the one under the pointer, the slider being dragged, the help panel
CONST TB_SELECT = 1, TB_PLACE = 2, TB_LIGHT = 3, TB_HEIGHT = 4, TB_DELETE = 5, TB_UNDO = 6, TB_SAVE = 7, TB_GRID = 8, TB_ALPHA = 9, TB_VIEW = 10, TB_HELP = 11, TB_PAINT = 12, TB_PICK = 13, TB_PREV = 14, TB_NEXT = 15, TB_KINDS = 16, TB_SECTOR = 17, TB_VERSIONS = 18, TB_REDO = 19
CONST TB_MAX = 24 ' (the most buttons a toolbar has)
DIM SHARED edTbN AS INTEGER, edTbId(TB_MAX) AS INTEGER, edTbX(TB_MAX) AS INTEGER, edTbY(TB_MAX) AS INTEGER, edTbW(TB_MAX) AS INTEGER, edTbH(TB_MAX) AS INTEGER
DIM SHARED edTbDrag AS INTEGER, edHelp AS INTEGER
' THE PICKER (EditPkBuild): the tab's entries - each a kind (PK_), what it
' is (a map character, a picture's file name, a light's number) and its
' thumbnail, made once per tab (and again when the level or ART changes:
' edPkKey$) - the brush (what PLACE puts, PAINT paints), and whether the
' picker's up at all
CONST PK_GLYPH = 1, PK_TEX = 2, PK_LIGHT = 3, PK_LIQUID = 4, PK_NEW = 5 ' (PK_LIQUID: a liquid and its depth - "w3"; "-" drains)
CONST PK_TABS = 10, PK_MAX = 160, PK_COLS = 8, PK_ROWS = 2, PK_SIZE = 50
CONST PK_X = 8, PK_Y = 438 ' (the picker's top left, in 3D: tabs, then the thumbnails under them)
DIM SHARED edPkN AS INTEGER, edPkKind(PK_MAX) AS INTEGER, edPkVal$(PK_MAX), edPkImg&(PK_MAX), edPkKey$
DIM SHARED edPickOn AS INTEGER, edBrushKind AS INTEGER, edBrushTex$, edBrushImg&, edBrushLiq$ ' (edBrushLiq$: the liquid PAINT pours - "w3", or "-" to drain)
DIM SHARED edPickOpen AS INTEGER ' (edPickOn: 1 tucked away till the pointer comes down to it, -1 always open, 0 off; edPickOpen: open now)
CONST PK_TUCK = 580 ' (tucked away: a strip along the bottom from here)
edPickOn = 1 : edBrushKind = PK_GLYPH
' The light brush: what LIGHT puts on a face (colour, effect - FX_ -
' reach in cells, brightness): set by the picker's LIGHTS tab, the keys
' 1-8 (EditLightPreset) and a light's pane
DIM SHARED edLR AS INTEGER, edLG AS INTEGER, edLB AS INTEGER, edLFx AS INTEGER, edLRad, edLBri AS INTEGER, edLNoLamp AS INTEGER ' (edLNoLamp: a light's lamp picture left off its ceiling)
edLR = 230 : edLG = 235 : edLB = 255 : edLFx = FX_STEADY : edLRad = 3 : edLBri = 150
' THE PROPERTIES PANE (EditPaneBuild): what's selected - a door, a
' teleporter's pad, a lift, a floor - and its buttons, down the right
CONST PN_X = 592, PN_Y = 58, PN_W = 200
' The pane in small print (TinyText): built on a 23-pixel row, then packed
' to PN_SQ of that - its buttons PN_BH tall (EditPaneBuild)
CONST PN_SQ = 0.7, PN_BH = 14
' A face's picture stretched (PAINT: Shift+[ ] and Shift+- =, the PICTURE
' pane): percent, from TEX_K_MIN to TEX_K_MAX, by these steps (5 a number)
CONST TEX_K_MIN = 10, TEX_K_MAX = 1000
' PAINT's COPY / PASTE (Ctrl+C / Ctrl+V, the PICTURE pane): a face's look -
' how it's divided, its pictures (the usual one written out by name), slid
' and stretched - pasted onto other faces
DIM SHARED edClipOn AS INTEGER, edClipD AS INTEGER, edClipP1$, edClipP2$, edClipOU AS INTEGER, edClipOV AS INTEGER, edClipKU AS INTEGER, edClipKV AS INTEGER
CONST TEX_K_STEPS$ = "   10   25   50   75  100  125  150  200  250  300  400  500  600  800 1000"
CONST PN_MAX = 96 ' (the most buttons and lines a pane has)
DIM SHARED edPnH(PN_MAX) AS INTEGER, edPnImg&(PN_MAX) ' (a button taller than PN_BH, in pixels - 0 as usual; a picture in it: a preset's)
DIM SHARED edLootSet AS INTEGER, edRoomW AS INTEGER, edRoomH AS INTEGER, edMapWant AS INTEGER ' (the SECTOR pane: its loot preset - 0 as made - and the room MAKE THE ROOM makes)
DIM SHARED edPnN AS INTEGER, edPnId(PN_MAX) AS INTEGER, edPnX(PN_MAX) AS INTEGER, edPnY(PN_MAX) AS INTEGER, edPnW(PN_MAX) AS INTEGER, edPnLab$(PN_MAX), edPnLit(PN_MAX) AS INTEGER
DIM SHARED edPnTitle$, edPnBot AS INTEGER, edPnCX AS INTEGER, edPnCY AS INTEGER, edPnLift AS INTEGER, edPnLight AS INTEGER, edPnEvent AS INTEGER, edPnCol(PN_MAX) AS _UNSIGNED LONG
DIM SHARED edSectorPane AS INTEGER, edTyping AS INTEGER, edTypeBuf$, edSlotPick AS INTEGER, edTypeFresh AS INTEGER
DIM SHARED edTypeX AS INTEGER, edTypeY AS INTEGER ' (typing a door's code (edTypeFor 3), a thing's own (4), a note's words (5) or picture (6): for cell edTypeX, edTypeY - or a picture's tint colour (7), a thing's look's (8), a picture's new name (9), a light's colour (10), a cell light's (11) - for the selection)
' The TRIGGER pane: open on the selection; the trigger being made - when
' (1 enter, 2 use, 3 clear, 4 time), again each time?, after how long (time),
' its commands; what's being typed (edTypeFor: 1 the sector's name, 2 the
' commands); the triggers listed (edTrigIdx: their numbers in lvlTrig$)
DIM SHARED edEvPane AS INTEGER ' (the event room's pane is open - EVENT ROOM... on a floor's)
DIM SHARED edCellLtPane AS INTEGER ' (the selection's CELL LIGHT pane is open)
DIM SHARED edFxPane AS INTEGER ' (the PICTURE pane's FILTERS are open - EditPaneFilters)
' Made colours (generated pictures, #RRGGBB and #RRGGBB-RRGGBB-D - RENDER/PICTURES.BM):
' the picker's COLOUR and GRADIENT tiles are edGenC1 (and to edGenC2, edGenDir$'s way);
' edGenPane: the PICTURE pane's COLOUR (EditPaneGen) is open - edGenWhich the colour
' being set (1 FROM, 2 TO), edGenSrc$ what it shows, edGenFromSel whether that's the
' selected faces' (EditTexOp 14 puts edGenSet$ on them) or the tiles'
DIM SHARED edGenC1 AS _UNSIGNED LONG, edGenC2 AS _UNSIGNED LONG, edGenDir$, edGenPane AS INTEGER, edGenWhich AS INTEGER
DIM SHARED edGenSrc$, edGenFromSel AS INTEGER, edGenSet$, edGenFrom$ ' (edGenFrom$: EditTexOp 15 puts edGenSet$ where exactly that picture is)
edGenC1 = &HFF2080 : edGenC2 = &H2040FF : edGenDir$ = "V" : edGenWhich = 1
DIM SHARED edTrigPane AS INTEGER, edTrigWhen AS INTEGER, edTrigRepeat AS INTEGER, edTrigTime AS INTEGER, edTrigCmd$, edTypeFor AS INTEGER, edTrigIdx(8) AS INTEGER
edTrigWhen = 1 : edTrigTime = 10 ' (the SECTOR pane; typing its name; which of its pictures the picker's choosing - 1-6 a wall kind, 7-10 a floor, 11-12 a ceiling)
' FULL WIDE (the 3D view, OpenGL, the window wider than 4:3): the editor is
' drawn on the HUD's canvas (HudWideBegin) - the toolbar and the info box at
' the window's left edge, the pane at its right, the picker and the message
' bar all the way across. edWX: how far the canvas reaches past our 800
' screen on each side (0 otherwise). The pointer (edCurX) stays in our
' screen's numbers, the 3D picking with it; each part's own (EditTBAt,
' EditPaneAt, EditPkHit) moves it onto itself.
DIM SHARED edWX AS INTEGER
DIM SHARED edPnX0 AS INTEGER, edPnY0 AS INTEGER ' (where the pane is: down the right in 3D, over the map's right from above)
DIM SHARED edLinkPad AS INTEGER, edLinkX AS INTEGER, edLinkY AS INTEGER ' (LINK: waiting for the pad this one's to go to)
edTool = ET_SELECT : edGridAlpha = 120 : edPickTab = 1


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED edDone, edDragOn, fpLWas, levelWas, lt, ndx, ndy, pkIdx, pkWhat, pnHit, tbHit, tbMX

' Doors, lifts and crushers held still in the editor, to see and paint
' them open, up or down (O): by cell - a door's own, a lift's first
' corner (liftX0, liftY0) - 1 open / at the top, -1 at the bottom, 0 as
' in play (a door shut, a lift running). Only the editor's: never saved,
' forgotten when a sector loads (BuildLevel), put back after each change
' (EditHeldSnap)
DIM SHARED edHeld(MAP_SIZE, MAP_SIZE) AS _BYTE
DIM SHARED edStateBack AS INTEGER ' (EditEnter: this sector's editor state came back from its save - EditStateLoad)
