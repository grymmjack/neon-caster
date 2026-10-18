''
' NEON-CASTER - EDITOR/EDITOR.BI
' =============================================================================
' The level editor (F2): its own state.
'

CONST ED_MAPX = 8, ED_MAPY = 8, ED_CELL = 12, ED_PALX = 596, ED_PALY = 44 ' (the editor's map from above, and its palette - chapter 21)
' --- The level editor (chapter 21): F2. editMode: on; editView: 0 the map
' from above (RunEditor), 1 walking round inside it (EditFP, in the game
' loop). editGlyph$: what you're placing - a map character (chapter 22).
' Each change is made to the level as its file says it (lvlRow$() and
' the rest) and the level built again from that (BuildLevel); editUndo$()
' remembers how it was before each change. texFile$(): which picture is in
' each texture slot now, so building it again only loads what changed.
CONST EDIT_GLYPHS = ".#NCKPG/\DHXRBYE!=@$%?&rby+*uae234Mqj8mghcskwzToiptxlnfSdAFIJLOQUWZV<>^v"
CONST EDIT_UNDO = 40
CONST EDIT_OPEN$ = ".rby+*uae234MqjmghcskwzToiptxlnfSdAFIJLOQUWZV<>^v&" ' (the map characters that are floor - with something on it, or not: where a liquid can lie)
DIM SHARED editMode AS INTEGER, editView AS INTEGER, editGlyph$, editDirty AS INTEGER, editRebuild AS INTEGER
DIM SHARED editUndo$(EDIT_UNDO), editUndoN AS INTEGER, editMsg$, editMsgUntil!, editLightP AS INTEGER, editLights AS INTEGER, editHeights AS INTEGER
' THE EDITOR'S OWN STATE, the same in both views (the map from above and
' the 3D view), so switching between them loses nothing:
'   ed hover...   the face under the cursor (kind, cell, side, part) - ED_ kinds
'   edSel...      the faces selected (up to ED_MAXSEL), kept until Ctrl+D
'   edTool        what a click does (ET_ tools); edBrush... what it places
'   edGrid...     the wireframe grid over the world, and how strong it is
'   edPick...     the picker panel: its tab and how far it's scrolled
CONST ED_WALL = 1, ED_FLOOR = 2, ED_CEIL = 3, ED_STEP = 4, ED_LINTEL = 5, ED_BOX = 6 ' (a face: a box's side; a wall's side, a floor, a ceiling, the face of a step up, the face of a ceiling stepping down)
CONST ED_MAXSEL = 2304 ' (the whole map, if it comes to it)
CONST ET_SELECT = 1, ET_PLACE = 2, ET_PAINT = 3, ET_LIGHT = 4, ET_HEIGHT = 5
DIM SHARED edHovKind AS INTEGER, edHovX AS INTEGER, edHovY AS INTEGER, edHovSide AS INTEGER, edHovPart AS INTEGER
DIM SHARED edHovPX, edHovPY, edHovPZ ' (exactly where the cursor's ray met it)
DIM SHARED edHovThing AS INTEGER ' (the pointer's on a thing standing in a cell - a monster, a pickup... - not a face: EditPickThing)
DIM SHARED edSelN AS INTEGER, edSelKind(ED_MAXSEL) AS INTEGER, edSelX(ED_MAXSEL) AS INTEGER, edSelY(ED_MAXSEL) AS INTEGER
DIM SHARED edSelSide(ED_MAXSEL) AS INTEGER, edSelPart(ED_MAXSEL) AS INTEGER
DIM SHARED edKeepN AS INTEGER, edKeepKind(ED_MAXSEL) AS INTEGER, edKeepX(ED_MAXSEL) AS INTEGER, edKeepY(ED_MAXSEL) AS INTEGER, edKeepSide(ED_MAXSEL) AS INTEGER, edKeepPart(ED_MAXSEL) AS INTEGER ' (the selection, kept while Ctrl+click PAINT borrows it - EditSelKeep)
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
' THE TOOLBAR (EditTBLayout): its buttons this frame - which (TB_), where -
' the one under the pointer, the slider being dragged, the help panel
CONST TB_SELECT = 1, TB_PLACE = 2, TB_LIGHT = 3, TB_HEIGHT = 4, TB_DELETE = 5, TB_UNDO = 6, TB_SAVE = 7, TB_GRID = 8, TB_ALPHA = 9, TB_VIEW = 10, TB_HELP = 11, TB_PAINT = 12, TB_PICK = 13, TB_PREV = 14, TB_NEXT = 15, TB_KINDS = 16, TB_SECTOR = 17
DIM SHARED edTbN AS INTEGER, edTbId(16) AS INTEGER, edTbX(16) AS INTEGER, edTbY(16) AS INTEGER, edTbW(16) AS INTEGER, edTbH(16) AS INTEGER
DIM SHARED edTbDrag AS INTEGER, edHelp AS INTEGER
' THE PICKER (EditPkBuild): the tab's entries - each a kind (PK_), what it
' is (a map character, a picture's file name, a light's number) and its
' thumbnail, made once per tab (and again when the level or ART changes:
' edPkKey$) - the brush (what PLACE puts, PAINT paints), and whether the
' picker's up at all
CONST PK_GLYPH = 1, PK_TEX = 2, PK_LIGHT = 3, PK_LIQUID = 4 ' (PK_LIQUID: a liquid and its depth - "w3"; "-" drains)
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
DIM SHARED edLR AS INTEGER, edLG AS INTEGER, edLB AS INTEGER, edLFx AS INTEGER, edLRad, edLBri AS INTEGER
edLR = 230 : edLG = 235 : edLB = 255 : edLFx = FX_STEADY : edLRad = 3 : edLBri = 150
' THE PROPERTIES PANE (EditPaneBuild): what's selected - a door, a
' teleporter's pad, a lift, a floor - and its buttons, down the right
CONST PN_X = 592, PN_Y = 58, PN_W = 200
DIM SHARED edPnN AS INTEGER, edPnId(40) AS INTEGER, edPnX(40) AS INTEGER, edPnY(40) AS INTEGER, edPnW(40) AS INTEGER, edPnLab$(40), edPnLit(40) AS INTEGER
DIM SHARED edPnTitle$, edPnBot AS INTEGER, edPnCX AS INTEGER, edPnCY AS INTEGER, edPnLift AS INTEGER, edPnLight AS INTEGER, edPnEvent AS INTEGER, edPnCol(40) AS _UNSIGNED LONG
DIM SHARED edSectorPane AS INTEGER, edTyping AS INTEGER, edTypeBuf$, edSlotPick AS INTEGER, edTypeFresh AS INTEGER
' The TRIGGER pane: open on the selection; the trigger being made - when
' (1 enter, 2 use, 3 clear, 4 time), again each time?, after how long (time),
' its commands; what's being typed (edTypeFor: 1 the sector's name, 2 the
' commands); the triggers listed (edTrigIdx: their numbers in lvlTrig$)
DIM SHARED edEvPane AS INTEGER ' (the event room's pane is open - EVENT ROOM... on a floor's)
DIM SHARED edTrigPane AS INTEGER, edTrigWhen AS INTEGER, edTrigRepeat AS INTEGER, edTrigTime AS INTEGER, edTrigCmd$, edTypeFor AS INTEGER, edTrigIdx(8) AS INTEGER
edTrigWhen = 1 : edTrigTime = 10 ' (the SECTOR pane; typing its name; which of its pictures the picker's choosing - 1-6 a wall kind, 7-10 a floor, 11-12 a ceiling)
DIM SHARED edPnX0 AS INTEGER, edPnY0 AS INTEGER ' (where the pane is: down the right in 3D, over the map's right from above)
DIM SHARED edLinkPad AS INTEGER, edLinkX AS INTEGER, edLinkY AS INTEGER ' (LINK: waiting for the pad this one's to go to)
edTool = ET_SELECT : edGridAlpha = 120 : edPickTab = 1
