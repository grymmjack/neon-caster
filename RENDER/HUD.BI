''
' NEON-CASTER - RENDER/HUD.BI
' =============================================================================
' The HUD as data (chapter 18): where each part goes, the minimap, the
' crosshair, vignettes and damage indicators.
'

' MINIMAP_ = where the minimap is drawn: each map cell is MINIMAP_CELL pixels
' square, and its top-left corner is at (MINIMAP_X, MINIMAP_Y) on the screen
CONST MINIMAP_CELL = 3, MINIMAP_X = 8, MINIMAP_Y = 8
' --- The HUD as data (chapter 18): where each part of it goes, shown or
' not, its bar's size, its colour (0: the game's own, which changes - red
' when you're low), its label. HudDefaults has the layout the game has
' always had; neon-caster/hud.txt (if it's there) changes it; the HUD
' layout editor (chapter 21: U in the level editor) moves things about
' with the mouse, over the game as it runs, and saves hud.txt.
CONST HE_HEALTH = 1, HE_ARMOR = 2, HE_AMMO = 3, HE_GUNS = 4, HE_KILLS = 5, HE_MINIMAP = 6, HE_CARDS = 7
CONST HE_MESSAGE = 8, HE_SUBTITLE = 9, HE_AMP = 10, HE_GOD = 11, HE_EVENT = 12, HE_NETWORK = 13, HE_FPS = 14, HE_TIMER = 15, HUD_ELEMS = 15
DIM SHARED hudName$(HUD_ELEMS), hudShow(HUD_ELEMS) AS INTEGER, hudX(HUD_ELEMS) AS INTEGER, hudY(HUD_ELEMS) AS INTEGER
DIM SHARED hudW(HUD_ELEMS) AS INTEGER, hudH(HUD_ELEMS) AS INTEGER, hudCol(HUD_ELEMS) AS _UNSIGNED LONG, hudLabel$(HUD_ELEMS)
DIM SHARED hudEdit AS INTEGER, hudSel AS INTEGER, hudMsg$
' The map: which cells you've seen (the raycaster marks every cell a ray
' passes through - chapter 15), and whether you've found this level's map
DIM SHARED cellSeen(MAP_SIZE, MAP_SIZE) AS INTEGER, hasMap AS INTEGER, mmFull AS INTEGER ' (mmFull: DrawMap's drawing the full-screen map, not the minimap)
' F3 (or info): where you are, in numbers - for tp, put, box and the rest
' (DrawInfo, like Minecraft's F3 screen)
DIM SHARED infoOn AS INTEGER, infoKeyWas AS INTEGER, infoFps$ ' (infoFps$: the F3 panel's frame rate line - chapter 18 writes it)
' VIGNETTES (DrawVignette, chapter 18): the edges of the screen washed with
' a colour, fading in towards the middle. Hurt: in the colour of what hurt
' you (painR/G/B - blood red, a shock's blue, poison's green, fire's
' orange, acid's yellow - the caller sets hurtR/G/B before HurtPlayer, 0
' for blood), fading away (painVig, 1 to 0). A lockdown strobes red. LOW
' on health (LOW_HP or less): a heartbeat - lub dub, faster the lower you
' are - the edges thumping red with it, a gasp or a groan now and then,
' and you move at LOW_SLOW of your speed.
CONST LOW_HP = 25, LOW_SLOW = 0.5
DIM SHARED painVig AS SINGLE, painR AS INTEGER, painG AS INTEGER, painB AS INTEGER, hurtR AS INTEGER, hurtG AS INTEGER, hurtB AS INTEGER
DIM SHARED beatAt AS DOUBLE, beatNext AS DOUBLE, gaspNext AS DOUBLE ' (when the last heartbeat was, and the next; the next gasp)
HudDefaults : ReadHud ' (the HUD's layout: chapter 18's, or hud.txt's)
' Crosshair feedback (chapter 18): how big it is right now (1 = its size;
' it shrinks when you fire, grows when you're hit, and eases back), and
' frames left of its white "you hit something" flash
DIM SHARED crossScale, crossFlash
crossScale = 1
' Damage indicators (chapter 18): where each recent hit came from, and
' frames left before it fades. HurtPlayer adds one when it's told where
' the damage came from (hurtFromX, hurtFromY; -1 for nowhere in particular).
CONST MAX_HURTDIRS = 8, HURTDIR_FRAMES = 70
DIM SHARED hurtDirX(MAX_HURTDIRS), hurtDirY(MAX_HURTDIRS), hurtDirTime(MAX_HURTDIRS)
' The full map's floors, textured (Duke3D's map, from above): drawn into
' fmImg& a cell at a time when what it shows changes (fmState: 0 nothing,
' 1 the map pickup's - dim, 2 where you've been), so holding Tab costs a
' put, not 2304 cells of pixels a frame. fmImgN/C/L: the sector, cell size
' and load it was made for - another, and it's made again
DIM SHARED fmImg&, fmImgN AS INTEGER, fmImgC AS INTEGER, fmImgL AS LONG, fmState(MAP_SIZE, MAP_SIZE) AS _BYTE
