'=============================================================================
' NEON-CASTER - a little first-person shooter in QB64PE, written to learn from
'=============================================================================
'
' This is a whole game in one file of plain QB64PE: ten levels, five kinds
' of monster, four guns, doors and keycards, exploding barrels, a minimap.
' It's also meant to be read. The comments are a course in how it works,
' chapter by chapter, from opening a window to casting rays.
'
' You'll want to know some BASIC already: variables, arrays, loops, SUBs
' and FUNCTIONs. The 3D ideas, and the QB64PE features the game leans on,
' are explained as they come up. neon-caster/TUTORIAL.md lists the chapters
' and has things to try.
'
' HOW TO READ IT
'   Search for "CHAPTER" to jump from one to the next; they follow the code
'   from top to bottom.
'     1-6    setting up: the window, the world, the things in it, pictures
'     7-13   one frame of the game: input, moving, doors, shooting, monsters
'     14-18  drawing that frame: floor, walls, sprites, the HUD
'     19-23  game events, levels, the splash screen, the menu, settings and
'            saved games, the map format, and the helper SUBs
'     24     the same 3D view drawn by the graphics card, with OpenGL
'            (RENDERER in the menu's SETTINGS > VIDEO)
'
' THE BIG IDEA: A RAYCASTER
'   The world is a flat grid of square cells, seen from inside at eye
'   height. For every column of the screen we send one ray out from you,
'   across the grid, until it hits a wall. How far it went says how tall to
'   draw that column of wall: far away is short, close up is tall. 400 rays
'   make 400 thin slices of wall, side by side, and it looks 3D. This is how
'   Wolfenstein 3D worked in 1992. The floor, ceiling and sprites (monsters,
'   pickups) are drawn using the same distances, so it all lines up.
'
'   Because the world is really flat, there are no stairs or rooms above
'   rooms: every wall is the same height and you can't look up or down.
'   That's the price of being simple and fast.
'
' CONTROLS (the keys can be changed in the menu: SETTINGS > CONTROLS)
'   Mouse          look around          W A S D   walk and strafe
'   Shift          hold to run           F         kick (and Fire with no ammo)
'   Click or Ctrl  fire                 Space     open doors, use the exit
'   1-4 or wheel   choose a gun         Esc       the menu (pause, save,
'   Right button   hold to aim down                load, settings, exit)
'                  the sights (zoom)    F5 / F9   quick save / quick load
'   Tab            the full-screen map (all of it once you find the map)
'   `              the console: commands for everything (help lists them);
'                  they work from the command line too, each after a +
'   K, G           testing cheats: every keycard, god mode (see CHEAT_KEYS)
'
' READING THE NAMES
'   How a name is written tells you what kind of thing it is:
'
'     UPPER_CASE   a CONST - a fixed number that never changes while the
'                  game runs, like MAP_SIZE (48). Change it in one place and
'                  the whole program follows.
'     camelCase    a variable, like playerX or monsterHP().
'     PascalCase   a SUB or FUNCTION, like MoveBody or CanSee - or a GOSUB
'                  label, like HitMonster: (chapter 19).
'
'   Some names end in a symbol. In QB64PE that symbol IS the variable's
'   type (anything with no symbol, and not DIMmed AS something, is SINGLE):
'
'     $    STRING          text: levelName$, gunName$()
'     &    LONG            a whole number up to about 2 billion. Used for
'                          image and sound "handles" (renderImg&, sndDoor&)
'                          - numbers QB64PE gives you to refer to a loaded
'                          picture or sound.
'     ~&   _UNSIGNED LONG  a colour, &HAARRGGBB: Shade~&(), texel~&
'     !    SINGLE          a decimal number - here, times from TIMER, like
'                          deadAt! (written out to make clear it's a time)
'     %    INTEGER         a small whole number: Walkable%(), GiveAmmo%()
'
'   True and false: BASIC's true is -1 and false is 0, so flags like
'   hasGun(), itemOn() and godMode hold -1 or 0, and "IF itemOn(i) THEN"
'   means "if item i is still there".
'
'   Many constants and variables start with a prefix that says what group
'   they belong to. Each group is explained again where it's defined:
'
'     Constants (UPPER_CASE)
'     MAX_       the most there can be at once: MAX_ITEMS, MAX_MON,
'                MAX_BOLTS, MAX_DECO, MAX_BLASTS (array sizes), and MAX_HP,
'                MAX_ARMOR (the most health and armour you can have)
'     NUM_       how many there are: NUM_LEVELS, NUM_GUNS
'     DOOR_      a kind of door, stored in doorType()           (chapter 2)
'     IT_        ITem: a kind of pickup, stored in itemKind()   (chapter 3)
'     MON_       MONster settings shared by every monster       (chapter 3)
'     DECO_ BLAST_ BOLT_ GUNNER_  settings for decorations, explosions,
'                bolts and gunners                              (chapter 3)
'     AM_        AMmo: which kind - AM_CELLS or AM_SHELLS       (chapter 4)
'     W_         Weapon: which gun - W_BLASTER, W_SCATTER, W_REPEATER,
'                W_RAIL (guns are numbered 1-4)                 (chapter 4)
'     SPR_       SPRite picture storage: their size and how many (chapter 5)
'     S_         Sprite slot: which picture in spriteTex()      (chapter 5)
'     T_         Texture slot: which picture in texture()       (chapter 5)
'     RENDER_    the size of the 3D view: RENDER_W x RENDER_H   (chapter 5)
'     texSize    how big each texture is: 128, MODERN 512      (chapter 5)
'     MINIMAP_   where the minimap goes, and its cell size      (chapter 2)
'     TEST_ CHEAT_  testing switches                            (chapter 4)
'     ADS_       Aiming Down the Sights: zoom and gun position   (chapter 4)
'     SET_       a SETting's number in the settings table       (chapter 6)
'     BIND_      a key BINDing's number (what the key does)     (chapter 6)
'     SCR_       a SCReen of the menu                           (chapter 6)
'     MI_        a Menu Item's kind: button, slider, toggle...  (chapter 6)
'     MA_        a Menu Action: what choosing a button does     (chapter 6)
'     MENU_      where the menu is drawn on the screen          (chapter 6)
'     SAVE_ SPLASH_  saved-game files, the splash screen         (chapter 6)
'
'     Variables (camelCase) - the start of the name says what it's about:
'     player...  you: playerX, playerY
'     monster... ONE monster, numbered i: monsterX(i), monsterHP(i)...
'     mtype...   a TYPE of monster (drone, gunner...), numbered 1-5:
'                mtypeSpeed(t) is how fast every monster of type t moves
'     item... deco... bolt... blast...  one pickup / decoration / bolt /
'                explosion, numbered i: itemX(i), decoFuse(i), boltX(i)...
'     gun...     a gun, numbered 1-4: gunName$(g), gunDamage(g)...
'     door... wall... floor... ceil...  one map cell's door, wall, floor or
'                ceiling, by cell: doorOpen(x, y), floorTex(x, y)...
'     draw...    the list of sprites to draw this frame        (chapter 16)
'     snd...&    a loaded sound's handle: sndDoor&, sndExit&
'     num...     how many are in use right now: numItems, numMonsters
'     has...     a yes/no flag (-1 or 0): hasGun(g), hasCard(c)
'     saved...   what you had when the level started          (chapter 20)
'     total...   added up over the whole game: totalKills
'     mm...      something on the MiniMap: mmColor~&
'     zone...    a floor / ceiling zone while it's read in    (chapter 20)
'     set...     the settings table: setting(SET_FOV) is the field of view
'     mi...      the items on the menu screen showing now (chapter 21)
'     menu...    the menu's state: menuSel, menuScreen, menuInGame...
'     keyBind&   the key bound to each action (BIND_)
'     lit...     a cell's light this frame: litR(x, y)        (chapter 14)
'     light...   one of the level's lights: lightX(l), lightEffect(l)
'     FX_        a light's effect: FX_FLICKER, FX_STROBE...     (chapter 2)
'     cellSeen() the cells you've seen, for the map            (chapter 15)
'     gl...      the OpenGL renderer: what the game hands it each frame,
'                and what it keeps for itself                  (chapter 24)
'
'   The raycasting maths uses the names from Lode Vandevenne's well-known
'   raycasting tutorial (lodev.org/cgtutor/raycasting.html): dirX, planeX,
'   rayDirX, sideDistX, deltaDistX, perpWallDist and so on. Read the two
'   side by side if you want the maths from another angle.
'=============================================================================

'-----------------------------------------------------------------------------
' CHAPTER 1: A WINDOW
'-----------------------------------------------------------------------------
' An 800 x 600 window with 32-bit colour: every pixel holds a full RGB
' colour (an _UNSIGNED LONG, &HAARRGGBB), which we need for textures and
' for fading things into the dark.
'
' _MOUSEHIDE _DISABLE hides the pointer and captures it in the window. Moving
' the mouse then gives raw movement (_MOUSEMOVEMENTX, chapter 8) instead of
' a pointer that gets stuck at the edge of the screen - just what mouse look
' needs. _PRINTMODE _KEEPBACKGROUND prints text without a box behind it.
'
' _DISPLAYORDER says what goes on the window, bottom layer first: whatever
' OpenGL draws (_GLRENDER), then our screen (_SOFTWARE) on top of it. The
' game normally covers the whole screen, so the OpenGL layer is hidden. The
' OpenGL renderer (chapter 24) switches our screen off (GLScreenLayer) and
' draws it itself, over the 3D view.
'
' The OpenGL renderer's shaders (chapter 24) come from the GLSL library in
' QB64_GJ_LIB (github.com/grymmjack/QB64_GJ_LIB), a copy of it in lib/glsl:
' its .BI here, its .BM at the very end of the file.
'$INCLUDE:'lib/glsl/GLSL.BI'
' Which release this is (the create-release skill bumps it: major.minor.patch)
CONST GAME_VERSION$ = "0.0.1"
_TITLE "NEON-CASTER " + GAME_VERSION$
ON ERROR GOTO GameError ' (a runtime error: logged, and the game carries on - chapter 21)
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE _DISABLE
_PRINTMODE _KEEPBACKGROUND
_DISPLAYORDER _GLRENDER , _SOFTWARE

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
CONST HE_MESSAGE = 8, HE_SUBTITLE = 9, HE_AMP = 10, HE_GOD = 11, HE_EVENT = 12, HE_NETWORK = 13, HE_FPS = 14, HUD_ELEMS = 14
DIM SHARED hudName$(HUD_ELEMS), hudShow(HUD_ELEMS) AS INTEGER, hudX(HUD_ELEMS) AS INTEGER, hudY(HUD_ELEMS) AS INTEGER
DIM SHARED hudW(HUD_ELEMS) AS INTEGER, hudH(HUD_ELEMS) AS INTEGER, hudCol(HUD_ELEMS) AS _UNSIGNED LONG, hudLabel$(HUD_ELEMS)
DIM SHARED hudEdit AS INTEGER, hudSel AS INTEGER, hudMsg$
CONST PLAYER_RADIUS = 0.3 ' Your body's half-width, so the camera can't touch a wall
' worldMap: 0 floor, 2 door; walls 1 (#), 3 (N), 4 (C), 5 (K), 6 (P), 7 (G):
' six kinds of wall, whose textures each level picks (see chapter 22)
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
' Doors: how far open (0 shut .. 1 open), which keycard opens it (0 any,
' 1 red, 2 blue, 3 yellow), and what kind it is (DOOR_ constants below)
DIM SHARED doorOpen(MAP_SIZE, MAP_SIZE) AS SINGLE
' ...which way it's going (1 opening, -1 shutting, 0 still), and how many
' frames more it stays open before shutting itself (chapter 11)
DIM SHARED doorMove(MAP_SIZE, MAP_SIZE) AS INTEGER, doorWait(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorKey(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorType(MAP_SIZE, MAP_SIZE) AS INTEGER
' Diagonal walls: which corner's half of the cell is solid - 0 not diagonal,
' 1 top-left, 2 top-right, 3 bottom-right, 4 bottom-left. Its worldMap value
' is the wall it looks like.
DIM SHARED diagCorner(MAP_SIZE, MAP_SIZE) AS INTEGER
' Each cell's floor and ceiling texture (a texture slot - chapter 5)
DIM SHARED floorTex(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilTex(MAP_SIZE, MAP_SIZE) AS INTEGER
' Floor / ceiling diagonals: a cell's floor (or ceiling) can be split corner
' to corner like a diagonal wall. floorSplit (ceilSplit) is the corner whose
' half uses floorTex2 (ceilTex2) instead; 0 = all of it is floorTex (ceilTex).
DIM SHARED floorTex2(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilTex2(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED floorSplit(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilSplit(MAP_SIZE, MAP_SIZE) AS INTEGER
' DOOR_ = the kinds of door, the numbers kept in doorType(x, y)
CONST DOOR_SLIDE = 0, DOOR_SHUTTER = 1, DOOR_SPLIT = 2, DOOR_EXIT = 3
CONST DOOR_LIP = 0.15 ' How much of an open door still shows (DoorShown, chapter 11)
' A door is a slab DOOR_THICK thick across the middle of its doorway
' (DoorRay, chapter 15), running in a track in the floor and ceiling
' TRACK_HALF either side of its middle line
CONST DOOR_THICK = 0.12, TRACK_HALF = 0.09
' Light (chapter 14). Every cell has a light level for red, green and blue
' (litR, litG, litB): 256 shows a texture in its own colours, less is
' darker, more is brighter, and different amounts tint it. It's worked out
' fresh every frame: the level's ambient light, plus each of its lights,
' plus things that glow (lamps, terminals, the exit, muzzle flashes,
' explosions, bolts).
DIM SHARED litR(MAP_SIZE, MAP_SIZE) AS LONG, litG(MAP_SIZE, MAP_SIZE) AS LONG, litB(MAP_SIZE, MAP_SIZE) AS LONG
DIM SHARED ambientR AS LONG, ambientG AS LONG, ambientB AS LONG
' Where each cell's light comes from, for the OpenGL renderer's bump mapping
' (chapter 24): every light adds its position times its strength, so
' litSumX / litSumW, litSumY / litSumW is the middle of the light falling
' on the cell - the way a bump there should face to catch it
DIM SHARED litSumX(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumY(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumW(MAP_SIZE, MAP_SIZE) AS SINGLE
' The level's lights: where, how far they reach, their light (brightness
' times colour) for red, green and blue, their effect (FX_ below), and -
' for a lamp or terminal's own light - which decoration it belongs to (so
' it goes out when you break it)
CONST MAX_LIGHTS = 96
DIM SHARED lightX(MAX_LIGHTS), lightY(MAX_LIGHTS), lightRadius(MAX_LIGHTS)
DIM SHARED lightR(MAX_LIGHTS), lightG(MAX_LIGHTS), lightB(MAX_LIGHTS), lightPhase(MAX_LIGHTS)
DIM SHARED lightEffect(MAX_LIGHTS) AS INTEGER, lightDeco(MAX_LIGHTS) AS INTEGER, lightTimer(MAX_LIGHTS) AS INTEGER
DIM SHARED lightNow(MAX_LIGHTS) ' How bright its effect has it this frame (0 off .. 1 full): for its glow
DIM SHARED numLights AS INTEGER
' ...and which of the level's ceiling lamps you've shot out (BreakLight)
DIM SHARED lightBroken(MAX_LIGHTS) AS INTEGER
' FX_ = a light's effect: steady, a flickering fluorescent tube, a slow
' pulse, an alarm strobe, firelight, or a dying tube that sputters on now
' and then
CONST FX_STEADY = 0, FX_FLICKER = 1, FX_PULSE = 2, FX_STROBE = 3, FX_FIRE = 4, FX_DYING = 5
' Which cells each light reaches, and how strongly - worked out once when
' the level loads (BuildLights, chapter 23), since walls don't move:
' light number l's cells are entries lightFirst(l) to lightFirst(l) +
' lightCount(l) - 1 of the lit... arrays
CONST MAX_LIT = 16000
DIM SHARED lightFirst(MAX_LIGHTS) AS LONG, lightCount(MAX_LIGHTS) AS LONG, numLit AS LONG
DIM SHARED litCellX(MAX_LIT) AS INTEGER, litCellY(MAX_LIT) AS INTEGER, litWeight(MAX_LIT) AS SINGLE
' The map: which cells you've seen (the raycaster marks every cell a ray
' passes through - chapter 15), and whether you've found this level's map
DIM SHARED cellSeen(MAP_SIZE, MAP_SIZE) AS INTEGER, hasMap AS INTEGER
CONST NUM_LEVELS = 10 ' NUM_ = how many there are
' How far a body or a wreck sinks into the floor, as a share of its height.
' Its picture stands upright at its middle, but its bottom edge is the near
' side of the heap - which, lying flat, would meet the floor nearer you.
' Sunk a little, it sits on the floor instead of hovering over it (OpenGL
' hides what's under the floor).
CONST CORPSE_SINK = 0.18
' Your own sectors (GAME > YOUR SECTORS - chapter 22): up to MAX_CUSTOM,
' numbered on from the game's - sector 11 is levels/custom/custom1.txt
CONST MAX_CUSTOM = 10

'-----------------------------------------------------------------------------
' CHAPTER 3: THINGS IN THE WORLD
'-----------------------------------------------------------------------------
' Everything that isn't a wall - pickups, decorations, monsters, bolts - is a
' list of numbered things kept in "parallel arrays": thing number i is at
' (itemX(i), itemY(i)), is of kind itemKind(i), and so on. A count says how
' many are in use (numItems). It's the simplest way to keep lists in BASIC.
' (QB64PE's TYPE could bundle each thing's fields into one record instead -
' a nice exercise once you know the code.)
'
' Things are never deleted while a level runs; they're switched off
' (itemOn(i) = 0) so the numbering stays put.

' --- Pickups lying on the map ---
' IT_ = ITem: the kinds of pickup, the numbers kept in itemKind(i). Kinds 1-3
' are the red, blue and yellow keycards (they have no IT_ name - the number
' is the card's colour).
CONST IT_HEALTH = 4, IT_CELLS = 5, IT_SHELLS = 6, IT_SCATTER = 7, IT_REPEATER = 8
CONST IT_ARMOR = 9, IT_BIGMED = 10, IT_RAIL = 11, IT_MAP = 12
CONST IT_CORE = 15 ' (a data core: only in the network)
CONST IT_OVERCHARGE = 13, IT_AMP = 14 ' (overcharge: health up to MAX_OVER; damage amp: double damage for AMP_FRAMES)
CONST MAX_OVER = 200, AMP_FRAMES = 1800
' MAX_ = the most there can be: the arrays below have room for this many
CONST MAX_ITEMS = 64
DIM SHARED itemX(MAX_ITEMS) AS SINGLE, itemY(MAX_ITEMS) AS SINGLE
DIM SHARED itemKind(MAX_ITEMS) AS INTEGER, itemOn(MAX_ITEMS) AS INTEGER, numItems AS INTEGER
DIM SHARED hasCard(3) AS INTEGER

' --- Decorations: 1 barrel, 2 lamp, 3 plant, 4 terminal. You, monsters and
' bolts can't pass through them. Shoot one and it breaks: a barrel blows up
' at once (chapter 13), the others take a few hits (DecoMaxHP, chapter 23)
' and then collapse into the floor. ---
' DECO_ = settings for decorations: DECO_RADIUS is how far from its middle a
' decoration blocks you (in cells), DECO_BREAK_FRAMES how long a broken one
' takes to collapse
CONST MAX_DECO = 64, DECO_RADIUS = 0.3, DECO_BREAK_FRAMES = 14
DIM SHARED decoX(MAX_DECO) AS SINGLE, decoY(MAX_DECO) AS SINGLE, decoKind(MAX_DECO) AS INTEGER
DIM SHARED decoOn(MAX_DECO) AS INTEGER, decoFuse(MAX_DECO) AS INTEGER, numDecos AS INTEGER
' decoHP: hits left before it breaks; decoTimer: frames left of its collapse
DIM SHARED decoHP(MAX_DECO) AS INTEGER, decoTimer(MAX_DECO) AS INTEGER
DIM SHARED decoCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' Which decoration stands in a cell (0 none)

' --- Event rooms: a part of the map (x0, y0) to (x1, y1) where something
' happens when you walk in - each a line of the level's file (chapter 22).
' EV_ = the kinds:
'   EV_AMBUSH   the doors slam shut and lock; evA monsters teleport in (of
'               type evB, or a mix if 0), a few at a time. Kill them all
'               and the doors open - and there's a reward (evReward, a
'               pickup kind, appears in the middle)
'   EV_SURVIVE  locked in for evA seconds, monsters arriving every evB
'               frames; hold out and the doors open, and the reward
'   EV_TRAP     the floor is electrified: on for evA frames, off for evB
'               (cross on the off beat). No reward - it's just there.
'   EV_GALLERY  a mini game: break every decoration in the room within evA
'               seconds for the reward
'   EV_NEST     spawners (decoration S) in the room send out a monster of
'               type evA every evB frames while you're near; break them
'               all for the reward
' evState: 0 waiting for you, 1 going on, 2 won, 3 lost. evTimer counts
' down its frames; evCount is how many monsters it's sent; evNext the
' frames to the next. monsterEv(i) is the event that sent monster i (0
' if it was always there). A locked door (doorLock) stays shut - Space
' won't open it, nor will monsters.
CONST MAX_EVENTS = 16
CONST EV_AMBUSH = 1, EV_SURVIVE = 2, EV_TRAP = 3, EV_GALLERY = 4, EV_NEST = 5
' ...and more (see chapter 22's Part 4 for what a and b are for each):
'   EV_CLOSET   walk in and the secret walls (%) round the room slide away,
'               and what's been waiting behind them comes out
'   EV_HOARD    a treasure room, sealed; the thief bots (T) run to its door
'               with what they steal, and when the last thief dies it opens
'   EV_PLATE    a pressure plate: step on it (or a monster does) - click,
'               beep, and a moment later an explosion lands on it
'   EV_LASER    a laser beam across a corridor, on for a frames, off for b
'   EV_CUTTER   a laser sweeping back and forth across the room
'   EV_BLACKOUT a power failure: the lights die for a seconds, and b
'               monsters come out of the dark
CONST EV_CLOSET = 6, EV_HOARD = 7, EV_PLATE = 8, EV_LASER = 9, EV_CUTTER = 10, EV_BLACKOUT = 11
'   EV_FIRETRAP the same as EV_TRAP, but a burner grate: flames, not sparks
CONST EV_FIRETRAP = 12
' A trap gives itself away: its floor is its own picture (MakeTrapTex), it
' smokes or crackles for TRAP_WARN frames before it goes live, and while
' live it blazes or arcs, lights the room and roars or buzzes (TrapFx)
CONST TRAP_WARN = 30
DIM SHARED evGlow(MAX_EVENTS) AS SINGLE, evHum&(MAX_EVENTS) ' (how lit a trap is now, 0 to 1; its own looping copy of its sound)
DIM SHARED closetCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' (a closet's secret wall: which closet event it belongs to)
DIM SHARED thiefDist(MAP_SIZE, MAP_SIZE) AS INTEGER ' (how many steps from a hoard's door: the thieves' way home - BuildThiefWay)
DIM SHARED blackoutTimer AS LONG, glMeshVersion AS LONG, glMeshDone AS LONG
DIM SHARED numEvents AS INTEGER, evType(MAX_EVENTS) AS INTEGER
DIM SHARED evX0(MAX_EVENTS) AS INTEGER, evY0(MAX_EVENTS) AS INTEGER, evX1(MAX_EVENTS) AS INTEGER, evY1(MAX_EVENTS) AS INTEGER
DIM SHARED evA(MAX_EVENTS) AS INTEGER, evB(MAX_EVENTS) AS INTEGER, evReward(MAX_EVENTS) AS INTEGER
DIM SHARED evState(MAX_EVENTS) AS INTEGER, evTimer(MAX_EVENTS) AS LONG, evCount(MAX_EVENTS) AS INTEGER, evNext(MAX_EVENTS) AS INTEGER
DIM SHARED doorLock(MAP_SIZE, MAP_SIZE) AS INTEGER
' BLAST_ = explosions: how far a blast reaches (in cells), and - for the
' picture of one - up to MAX_BLASTS on show at once, each fading over
' BLAST_FRAMES frames. blastSize is 1 for a barrel, smaller for the puff of
' sparks from a broken lamp or terminal.
CONST BLAST_RADIUS = 2.2
CONST MAX_BLASTS = 12, BLAST_FRAMES = 18
DIM SHARED blastX(MAX_BLASTS) AS SINGLE, blastY(MAX_BLASTS) AS SINGLE, blastTime(MAX_BLASTS) AS INTEGER
DIM SHARED blastSize(MAX_BLASTS) AS SINGLE

' --- Monsters: 1 drone (bites), 2 gunner (shoots bolts), 3 heavy (smashes),
' 4 crawler (fast, bites), 5 sentry (a turret: stays put, shoots bolts) ---
' Each monster is in one of four states (chapter 13): 0 idle, 1 hunting,
' 2 dying, 3 dead. monsterTimer counts frames - down to its next attack while
' hunting, or through its collapse while dying - and monsterHurt is how many
' more frames it flashes red after a hit.
' MON_ = MONster settings shared by every monster: MON_TYPES kinds of monster,
' MON_SIGHT how far away (in cells) they notice you, MON_DYING how many
' frames one takes to collapse when killed
CONST MAX_MON = 64, MON_TYPES = 10
CONST MT_ICE = 10 ' (ICE: the network's hunter programs - only in the network, chapter 19)
CONST MT_THIEF = 9 ' (the thief bot: steals, then runs - ThiefStep, chapter 13)
CONST DK_CHAIR = 20, DK_BODY = 21 ' (a body doesn't block the way, and can't be broken)
CONST DECO_KINDS = 21, ITEM_KINDS = 15 ' (kinds of decoration and of pickup - see chapter 3)
CONST MON_SIGHT = 14
CONST MON_DYING = 24
CONST MON_STRIDE = 0.12 ' How far a monster walks per frame of its walk
DIM SHARED monsterX(MAX_MON) AS SINGLE, monsterY(MAX_MON) AS SINGLE, monsterType(MAX_MON) AS INTEGER
DIM SHARED monsterHP(MAX_MON) AS INTEGER, monsterState(MAX_MON) AS INTEGER
DIM SHARED monsterTimer(MAX_MON) AS INTEGER, monsterHurt(MAX_MON) AS INTEGER
' ...where each one is in its animation (frames of it, as a decimal: chapter
' 13 moves it on as the monster moves), and frames left of its attack pose
DIM SHARED monsterAnim(MAX_MON) AS SINGLE, monsterAtk(MAX_MON) AS INTEGER
DIM SHARED monsterEv(MAX_MON) AS INTEGER ' (the event room that sent it, 0 for none - chapter 3)
' ...and what a thief bot has stolen: cells, shells and a gun (0 none);
' thiefState 0 coming for you, 1 running home empty-handed, 2 running home
' with your things
DIM SHARED thiefCells(MAX_MON) AS INTEGER, thiefShells(MAX_MON) AS INTEGER, thiefGun(MAX_MON) AS INTEGER, thiefState(MAX_MON) AS INTEGER
DIM SHARED numMonsters AS INTEGER
' A second set of arrays describes each TYPE of monster, numbered 1-5 (the
' "mtype" arrays, filled in chapter 6). Per type: hit points, speed (tiles a frame; you walk 0.12), height (of a
' wall), hover height and bob, attack reach, damage (min + random), frames
' between attacks, sprite slots, whether it shoots bolts, and sounds
DIM SHARED mtypeHP(MON_TYPES), mtypeSpeed(MON_TYPES), mtypeScale(MON_TYPES), mtypeLift(MON_TYPES), mtypeBob(MON_TYPES)
DIM SHARED mtypeReach(MON_TYPES), mtypeDamage(MON_TYPES), mtypeDamageRnd(MON_TYPES), mtypeCooldown(MON_TYPES)
DIM SHARED mtypeSprite(MON_TYPES), mtypeName$(MON_TYPES), mtypeRanged(MON_TYPES)
DIM SHARED mtypeDrop(MON_TYPES), mtypeDropChance(MON_TYPES) ' (what it may leave when it dies - a pickup kind - and how likely: monsters.txt)
' ...and its body, once it's dead (MakeCorpse): how wide it's drawn (as
' drawScale), and how tall for that width (as drawSquash)
DIM SHARED corpseScale(MON_TYPES), corpseSquash(MON_TYPES)
' ...and each decoration's wreck, the same way (MakeWreck)
DIM SHARED wreckScale(DECO_KINDS), wreckSquash(DECO_KINDS)
DIM SHARED mtypeAlertSnd&(MON_TYPES), mtypeAttackSnd&(MON_TYPES), mtypeHitSnd&(MON_TYPES), mtypeDieSnd&(MON_TYPES)
' ...and the sounds it makes now and then: waiting (idle), and hunting you
DIM SHARED mtypeIdleSnd&(MON_TYPES), mtypeHuntSnd&(MON_TYPES)
' GUNNER_ = gunners (and sentries) like to keep between GUNNER_NEAR and
' GUNNER_FAR cells away from you
CONST GUNNER_NEAR = 3.5, GUNNER_FAR = 7

' --- Energy bolts (what gunners and sentries shoot): a position and a
' direction each, moved a little every frame ---
' (BOLT_SPEED is in cells a frame - you walk at 0.12)
CONST MAX_BOLTS = 32, BOLT_SPEED = 0.11
DIM SHARED boltX(MAX_BOLTS) AS SINGLE, boltY(MAX_BOLTS) AS SINGLE, boltDX(MAX_BOLTS) AS SINGLE, boltDY(MAX_BOLTS) AS SINGLE
DIM SHARED boltOn(MAX_BOLTS) AS INTEGER, boltDamage(MAX_BOLTS) AS INTEGER

'-----------------------------------------------------------------------------
' CHAPTER 4: YOU
'-----------------------------------------------------------------------------
' Health, armour, two kinds of ammo and four guns. Each gun is a row in a
' table of numbers (SetGun, below), so the shooting code (chapter 12) works
' the same way for all of them - a new gun is mostly a new SetGun line and
' a picture. Your position and the way you face are in chapter 8.
' The most health (HP = "hit points") and armour you can have
CONST MAX_HP = 100, MAX_ARMOR = 100
' AM_ = AMmo: the two kinds. They number the ammo arrays: ammoCount(AM_CELLS)
' is how many energy cells you have, ammoMax(AM_SHELLS) the most shells
' you can carry.
CONST AM_CELLS = 1, AM_SHELLS = 2
DIM SHARED ammoCount(2) AS INTEGER, ammoMax(2) AS INTEGER
ammoMax(AM_CELLS) = 99 : ammoMax(AM_SHELLS) = 40
' W_ = Weapon: the guns, numbered 1-4. They number the gun arrays below
' (gunName$(W_RAIL) is "RAILGUN") and are the keys you press to pick them.
CONST W_BLASTER = 1, W_SCATTER = 2, W_REPEATER = 3, W_RAIL = 4, NUM_GUNS = 4
DIM SHARED hasGun(NUM_GUNS) AS INTEGER
' Per gun: name, ammo kind, ammo per shot, frames between shots, pellets,
' spread (of the view's width), damage per hit, whether a shot goes through
' every monster in its line, recoil, how far it zooms when you aim down its
' sights (1 = not at all, 2 = twice as close - chapter 8), sound, picture,
' and where its muzzle is
DIM SHARED gunName$(NUM_GUNS), gunAmmoType(NUM_GUNS), gunAmmoPerShot(NUM_GUNS), gunDelay(NUM_GUNS), gunPellets(NUM_GUNS), gunSpread(NUM_GUNS)
DIM SHARED gunDamage(NUM_GUNS), gunPierce(NUM_GUNS), gunKick(NUM_GUNS), gunZoom(NUM_GUNS)
DIM SHARED gunSnd&(NUM_GUNS), gunImg&(NUM_GUNS), gunMuzzleX(NUM_GUNS), gunMuzzleY(NUM_GUNS), gunSize(NUM_GUNS)
' ...the light on the gun (1 = as bright as its picture; chapter 17), and
' for the software renderer, each gun's picture no taller than
' GUN_SOFT_MAX (it's shrunk to our 800 x 600 screen anyway) to tint
DIM SHARED gunLightR, gunLightG, gunLightB, gunSoftImg&(NUM_GUNS)
CONST GUN_SOFT_MAX = 512, GUN_DARKEST = 0.22, GUN_BRIGHTEST = 1.3
CONST GUN_TINT = 1.6 ' How strongly coloured light colours the gun (1 = just as it is)
gunLightR = 1 : gunLightG = 1 : gunLightB = 1
' ...and each gun's picture for OpenGL (chapter 24): a copy with its colours
' "premultiplied" (see GLDrawHUD), and its size
DIM SHARED gunGLMem(NUM_GUNS) AS _MEM, gunGLW(NUM_GUNS) AS LONG, gunGLH(NUM_GUNS) AS LONG
' ADS_ = Aiming Down the Sights (hold the right mouse button - chapter 8):
'   ADS_ZOOM       how much the view zooms in (1 = not at all, 2 = twice as
'                  close) - for most guns; each gun's own zoom is the last
'                  column of the guns table below, so the railgun can zoom
'                  in like a scope
'   ADS_FRAMES     frames to raise the gun to your eye, or lower it again
'   ADS_MUZZLE_Y   where the muzzle comes up to on the screen (the
'                  crosshair is at y = 300)
'   ADS_GUN_GROW   how much bigger the gun looks, held up close - at least.
'                  A gun whose muzzle is low in its picture grows more, so
'                  its bottom still reaches below the screen; but never more
'                  than ADS_GUN_GROW_MAX (then its muzzle stops a bit lower)
CONST ADS_ZOOM = 1.6, ADS_FRAMES = 8, ADS_MUZZLE_Y = 318
CONST ADS_GUN_GROW = 1.15, ADS_GUN_GROW_MAX = 1.7
'      gun name        ammo       cost delay pellets spread damage pierce recoil zoom
SetGun 1,  "BLASTER",  AM_CELLS,  1,   16,   1,      0,     1,     0,     1,     ADS_ZOOM
SetGun 2,  "SCATTER",  AM_SHELLS, 1,   40,   7,      0.12,  1,     0,     1.7,   ADS_ZOOM
SetGun 3,  "REPEATER", AM_CELLS,  1,   5,    1,      0.025, 1,     0,     0.45,  ADS_ZOOM
SetGun 4,  "RAILGUN",  AM_CELLS,  5,   55,   1,      0,     5,     -1,    2.2,   4
CONST SWAP_FRAMES = 14 ' Frames to lower one gun and raise the next
' TEST_ and CHEAT_ = testing aids - set both to 0 for the real game:
'   TEST_ALL_GUNS  -1 starts you with every gun and full ammo
'   CHEAT_KEYS     -1 lets K give you every keycard, and G switch god mode
'                  (no damage, walk through walls) on and off
CONST TEST_ALL_GUNS = 0
CONST CHEAT_KEYS = -1

'-----------------------------------------------------------------------------
' CHAPTER 5: PICTURES IN ARRAYS
'-----------------------------------------------------------------------------
' Drawing 120,000 pixels a frame one PSET at a time would be far too slow, and
' so would reading textures back with POINT. So the game keeps its pictures
' in plain arrays of colours and draws the 3D view into another array,
' pixels(), at half size: 400 x 300. Reading and writing array elements is
' fast. Once the whole view is in pixels(), it's copied into an image in one
' go with _MEMCOPY and stretched onto the window with _PUTIMAGE (chapter 17).
'
'   texture(x, y, slot)     64 x 64 wall, floor and ceiling pictures,
'                           numbered by "slot" (the T_ constants below)
'   spriteTex(x, y, slot)   up to 64 x 64 pictures of things: monsters,
'                           pickups, decorations (the S_ constants)
'   pixels(y * 400 + x)     the 3D view being drawn this frame
'   zBuffer(x)              how far away the wall is in each column - so
'                           sprites can hide behind walls (chapter 16)
'
' The HUD and the gun are drawn later, on the window itself at full size,
' with ordinary QB64PE graphics (chapter 18).

' --- Sprites (billboards): pictures, and the list drawn each frame ---
' SPR_ = SPRite picture storage: each picture is up to sprTex pixels square
' (64, or 256 for MODERN art with OpenGL - ArtReload, chapter 23),
' and there are SPR_SLOTS of them. A "slot" is just a picture's number - the
' third index of spriteTex(x, y, slot):
'   1-3 keycards, 4 medkit, 5 cells, 6 shells, 7 scatter gun, 8 repeater,
'   9/10 drone (/hit), 11/12 gunner, 13/14 heavy, 15/16 crawler, 17/18 sentry,
'   19 bolt, 20-23 decorations (barrel, lamp, plant, terminal), 24 explosion,
'   25 armour, 26 big medkit, 27 railgun, 28 map - and after those, each
'   block worked out from the one before (so a new monster or decoration
'   only has to change MON_TYPES or DECO_KINDS): every monster's body,
'   lying where it fell (S_CORPSE + type: MakeCorpse); a scorch mark (the
'   software renderer's decals: S_DECAL); every decoration, broken
'   (S_WRECK + kind: MakeWreck); the monsters' animation, five frames each
'   - four of moving, then one of attacking (MonFrame); an explosion's six
'   frames (S_BOOM + 1..6: MakeBoomFrames); then the pictures of the
'   monsters, decorations and pickups added after the first ones (types
'   6 on - their picture and their hurt picture, S_MONX; decorations 5 on,
'   S_DECOX; pickups 13 on, S_ITEMX)
CONST BOOM_FRAMES = 6
CONST ANIM_FRAMES = 4, ATTACK_FRAMES = 12 ' (frames a monster shows its attack frame)
' S_ = Sprite slot: names for a few of those numbers. S_DECO + kind is one
' of the first four decorations' slot (barrel = S_DECO + 1 = 20, and so on:
' DecoSlot has them all).
CONST S_BOLT = 19, S_DECO = 19, S_BLAST = 24, S_CORPSE = 28
CONST S_DECAL = S_CORPSE + MON_TYPES + 1, S_WRECK = S_DECAL, S_ANIM = S_WRECK + DECO_KINDS
CONST S_BOOM = S_ANIM + MON_TYPES * (ANIM_FRAMES + 1), S_MONX = S_BOOM + BOOM_FRAMES
CONST S_DECOX = S_MONX + (MON_TYPES - 5) * 2, S_ITEMX = S_DECOX + DECO_KINDS - 4
CONST S_TRAP = S_ITEMX + ITEM_KINDS - 12, S_PLATE = S_TRAP + 1, S_LASER = S_TRAP + 2 ' (traps: a pressure plate, a laser beam)
CONST S_GLASS = S_TRAP + 3 ' (glass: whole, then cracked)
CONST S_PAD = S_GLASS + 2 ' (a teleporter's pad)
CONST SPR_SLOTS = S_PAD
' How big each picture is kept: textures texSize, sprites up to sprTex
' pixels across. ART (SETTINGS > VIDEO) picks them: CLASSIC, the pixel art
' in neon-caster/, at 128 and 64; MODERN, the paintings in neon-caster/hd/,
' at 512 and 256 with OpenGL (shrunk to 128 and 64 for the software
' renderer). artNow: what's loaded (0 classic, 1 modern small, 2 modern
' big); artWant: what the settings ask for (ApplySettings); artHold: the
' pictures are being reloaded - OpenGL keeps its hands off (glArtAck: it has)
DIM SHARED texSize AS LONG, sprTex AS LONG, artNow AS INTEGER, artWant AS INTEGER, artHold AS INTEGER, glArtAck AS INTEGER
texSize = 128 : sprTex = 64 : artNow = -1
DIM SHARED glGunVersion AS LONG, glGunDone AS LONG, monK ' (monK: MakeMonFrames' picture size over 64)
' How tall pickups stand (in walls): keycards, other pickups, guns
CONST CARD_SCALE = 0.3, ITEM_SCALE = 0.3, GUN_ITEM_SCALE = 0.45
REDIM SHARED spriteTex(sprTex - 1, sprTex - 1, SPR_SLOTS) AS _UNSIGNED LONG
DIM SHARED spriteSize(SPR_SLOTS) AS INTEGER
DIM SHARED cardImg&(3) ' The keycards as images, for the HUD
' The draw list: every sprite to draw this frame (chapter 16)
' DECALS: marks left where shots and explosions hit - where (x, y, z),
' which way the surface faces (nx, ny, nz), how big, and how many frames
' more it glows hot (decalHeat). The oldest is reused when they're all
' taken (decalNext). AddDecal makes one.
CONST MAX_DECALS = 96, DECAL_HEAT = 24
DIM SHARED decalX(MAX_DECALS), decalY(MAX_DECALS), decalZ(MAX_DECALS), decalNX(MAX_DECALS), decalNY(MAX_DECALS), decalNZ(MAX_DECALS)
DIM SHARED decalSize(MAX_DECALS), decalHeat(MAX_DECALS) AS INTEGER, decalOn(MAX_DECALS) AS INTEGER, decalNext AS INTEGER
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS + MAX_DECO + MAX_BLASTS + MAX_DECALS + 160 ' (+ traps)
DIM drawX(MAX_DRAW) AS SINGLE, drawY(MAX_DRAW) AS SINGLE, drawDistSq(MAX_DRAW) AS SINGLE
DIM drawSprite(MAX_DRAW) AS INTEGER, drawScale(MAX_DRAW) AS SINGLE, drawLift(MAX_DRAW) AS SINGLE
DIM drawSquash(MAX_DRAW) AS SINGLE, drawMinShade(MAX_DRAW) AS INTEGER, drawOrder(MAX_DRAW) AS INTEGER

' --- The 3D view: drawn at half size, then stretched 2x onto the window ---
' RENDER_ = the size of the 3D view in pixels (W = width, H = height);
' (texSize: how big each texture is - see sprTex above)
CONST RENDER_W = 400, RENDER_H = 300
' --- Glass: = on the map, a pane across the middle of its cell (in a
' wall one cell thick, like a door). You, monsters and bolts can't pass
' it; sight and light can. glassHP: hits left (0: none there, or broken);
' glassDir: 1 if the pane runs along x (you look through it north or
' south), 2 along y. glassList: where they all are. Per column of the
' view, the nearest pane the ray went through (glassT: how far, 0 for
' none; glassU: where along it; glassCX, glassCY: its cell) - drawn over
' the wall behind it after the sprites behind it (chapters 15 and 16).
CONST PZ_TOP = 70 ' (the puzzle screen's first line)
CONST ME_FIELDS = 12 ' (the monster editor's numbers)
CONST ED_MAPX = 8, ED_MAPY = 8, ED_CELL = 12, ED_PALX = 596, ED_PALY = 44 ' (the editor's map from above, and its palette - chapter 21)
CONST GLASS_HP = 4, GLASS_HALF = 0.1, MAX_GLASS = 240 ' (GLASS_HALF: half the thickness you bump into)
DIM SHARED glassHP(MAP_SIZE, MAP_SIZE) AS INTEGER, glassDir(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED numGlass AS INTEGER, glassListX(MAX_GLASS) AS INTEGER, glassListY(MAX_GLASS) AS INTEGER
' --- Data stations (@) and the network (chapter 19). A station is a wall
' with a socket; Space at it "jacks you in": the level becomes the
' network - every wall, floor and ceiling a neon grid (MakeCyberTex, the
' real pictures kept in texBak), the light even, the monsters and things
' of the real world left behind - and you have cyberTime frames to grab
' cyberNeed data cores (IT_CORE) while ICE (MT_ICE) hunts you. Get them
' all and the station opens its sealed doors (! on the map: doorLock 2);
' run out of time and you're thrown out, to try again.
CONST MAX_STATIONS = 8, CYBER_SECONDS = 50
DIM SHARED numStations AS INTEGER, stationX(MAX_STATIONS) AS INTEGER, stationY(MAX_STATIONS) AS INTEGER, stationDone(MAX_STATIONS) AS INTEGER
DIM SHARED cyberOn AS INTEGER, cyberStation AS INTEGER, cyberTime AS LONG, cyberNeed AS INTEGER, cyberGot AS INTEGER
DIM SHARED cyberMonStart AS INTEGER, cyberItemStart AS INTEGER, glRetexVersion AS LONG, glRetexDone AS LONG
DIM SHARED sndJackIn&, sndJackOut&, sndCore&, cyberMusic&, sndTeleport&
CONST MAX_CLIPS = 24
DIM SHARED clipN(RENDER_W) AS INTEGER, clipD(RENDER_W, MAX_CLIPS) AS SINGLE, clipT(RENDER_W, MAX_CLIPS) AS INTEGER, clipB(RENDER_W, MAX_CLIPS) AS INTEGER
DIM SHARED glassT(RENDER_W) AS SINGLE, glassU(RENDER_W) AS SINGLE, glassCX(RENDER_W) AS INTEGER, glassCY(RENDER_W) AS INTEGER, glassDone(RENDER_W) AS INTEGER
' T_ = Texture slot: which picture in texture(x, y, slot). The slots are:
'   1-6 the level's six walls (# N C K P G), 7 sliding door, 8-10 key doors,
'   11 shutter, 12 split door, 13 exit, 14-17 the level's four floors,
'   18-19 its two ceilings, 20 a ceiling lamp (over each of the level's
'   lights - BuildShafts, chapter 24), 21 the lamp, shot out (MakeLampOff)
' T_DOORK + card is a key door (8 red, 9 blue, 10 yellow); T_FLOOR + n is
' floor n, and T_CEIL + n ceiling n; T_SLOTS is how many slots there are.
CONST T_DOOR = 7, T_DOORK = 7
CONST T_SHUTTER = 11, T_SPLIT = 12, T_EXIT = 13
CONST T_FLOOR = 13, T_CEIL = 17, T_LAMP = 20, T_LAMPOFF = 21, T_JACK = 22 ' (T_JACK: a data station's wall, @)
CONST T_CODE = 23 ' (a code terminal's wall, $)
CONST T_LIFT = 24, T_LIFTSIDE = 25 ' (a lift's top and sides: made from the level's own - MakeLiftTex)
CONST T_TRAP = 26, T_FIRE = 27 ' (a trap's floor: a live wire grid, a burner grate - MakeTrapTex)
CONST T_CUSTOM = 27, T_CUSTOMN = 24 ' (after those: slots for pictures put on single faces in the editor - [faces])
CONST T_SLOTS = T_CUSTOM + T_CUSTOMN
REDIM SHARED texture(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG
REDIM SHARED texBak(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG ' (the real pictures, kept while you're in the network)
' For each worldMap wall value: its texture slot, and its colour on the minimap
DIM SHARED wallTexSlot(9) AS INTEGER, wallMapColor(9) AS _UNSIGNED LONG
wallTexSlot(1) = 1 : wallTexSlot(3) = 2 : wallTexSlot(4) = 3 : wallTexSlot(5) = 4 : wallTexSlot(6) = 5 : wallTexSlot(7) = 6 : wallTexSlot(8) = T_JACK : wallTexSlot(9) = T_CODE ' (8: a data station; 9: a code terminal)
DIM SHARED pixels(0 TO RENDER_W * RENDER_H - 1) AS _UNSIGNED LONG
DIM SHARED zBuffer(RENDER_W - 1) AS SINGLE
' The image the view is copied into each frame. _MEMIMAGE and _MEM give us
' "memory blocks" for the image and the array, so _MEMCOPY can copy all
' 120,000 colours from one to the other at once.
renderImg& = _NEWIMAGE(RENDER_W, RENDER_H, 32)
DIM renderMem AS _MEM, pixelsMem AS _MEM
renderMem = _MEMIMAGE(renderImg&) : pixelsMem = _MEM(pixels())

' --- The OpenGL renderer (chapter 24) ---
' With RENDERER set to OPENGL in the menu, the graphics card draws the 3D
' view instead of the pixel loops of chapters 14-16. It draws whenever
' QB64PE puts the window on the screen (SUB _GL), which can happen between
' any two lines of the game, so the game never makes it look at half-done
' work. Each frame it fills in a "snapshot" of what to draw, in one half of
' these arrays (the last index, 0 or 1), while OpenGL may still be drawing
' the other half, and then switches over: "double buffering".
'   glReady       -1 when there's a snapshot to draw; 0 in the menus at the
'                 title, while a level loads, or with the software renderer
'   glBuf         which half holds the newest snapshot (glWrite: which half
'                 this frame is filling in - the other one)
'   glFrameNo     counts frames; glFrame(half) is the frame a snapshot is of
'   glCam... glDir... glPlaneLen glZoom glShake...   the camera: where you
'                 are, the way you face, how wide and tall the view is, and
'                 the screen shake (chapter 17)
'   glLitR...     every cell's light, and glDoor every door's position
'   glSeen()      the cells this frame's rays went through (chapter 15):
'                 glSeen(x, y, half) = glFrame(half) means "seen this frame"
'   glSpr...      the sprites to draw (chapter 16): where, how big, which
'                 picture, and how they're lit
'   glTexVersion  goes up whenever the textures change (a level loads), so
'                 SUB _GL knows to send them to the graphics card again
' GL_NEAR and GL_FAR: the nearest and furthest OpenGL draws (in cells)
CONST GL_NEAR = 0.05, GL_FAR = 100
' GL_DYN: how many moving lights; MAX_PART: particles; GL_HEAT: explosions
' for the heat shimmer (all chapter 24)
CONST GL_DYN = 4, MAX_PART = 800, GL_HEAT = 4
DIM SHARED glReady AS INTEGER, glBuf AS INTEGER, glFrameNo AS LONG, glMode AS INTEGER
DIM SHARED glCamZ(1), glEyeZ ' (your eye's height, for OpenGL's camera)
DIM SHARED glFrame(1) AS LONG, glCamX(1), glCamY(1), glDirX(1), glDirY(1), glPlaneLen(1), glZoom(1)
DIM SHARED glShakeX(1), glShakeY(1), glShakeEdge(1), glFullMode(1) AS INTEGER
DIM SHARED glLitR(MAP_SIZE, MAP_SIZE, 1) AS LONG, glLitG(MAP_SIZE, MAP_SIZE, 1) AS LONG, glLitB(MAP_SIZE, MAP_SIZE, 1) AS LONG
DIM SHARED glDoor(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glSeen(MAP_SIZE, MAP_SIZE, 1) AS LONG
DIM SHARED glNumSpr(1) AS INTEGER, glSprX(MAX_DRAW, 1), glSprY(MAX_DRAW, 1), glSprLift(MAX_DRAW, 1)
DIM SHARED glSprHalfW(MAX_DRAW, 1), glSprH(MAX_DRAW, 1), glSprSlot(MAX_DRAW, 1) AS INTEGER
DIM SHARED glSprR(MAX_DRAW, 1), glSprG(MAX_DRAW, 1), glSprB(MAX_DRAW, 1)
DIM SHARED glTexVersion AS LONG
' Bump mapping (chapter 24): each cell's light middle (glLitCX, glLitCY)
' and how much of its light comes from somewhere (glLitDir, 0 all ambient
' .. 1); and the glows - halos round bolts, blasts, lamps and terminals:
' where, how big, what colour. glBump and glGlowOn: the two VIDEO settings.
DIM SHARED glLitCX(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glLitCY(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glLitDir(MAP_SIZE, MAP_SIZE, 1) AS SINGLE
CONST MAX_GLOWS = MAX_BOLTS + MAX_BLASTS + MAX_LIGHTS
DIM SHARED glNumGlow(1) AS INTEGER, glGlowX(MAX_GLOWS, 1), glGlowY(MAX_GLOWS, 1), glGlowZ(MAX_GLOWS, 1), glGlowSize(MAX_GLOWS, 1)
DIM SHARED glGlowR(MAX_GLOWS, 1), glGlowG(MAX_GLOWS, 1), glGlowB(MAX_GLOWS, 1)
DIM SHARED glWrite AS INTEGER
' What SUB _GL keeps for itself: the graphics card's names for the textures
' (texture slots 1-20, then sprite slots after them), which texture version
' it has, the cells it's drawing, the camera and light it's drawing with,
' the camera as a matrix (chapter 24), and how long it took (for SHOW FPS)
' (one more texture name after the sprites: GL_GLOW_TEX, the glows' soft
' round spot)
CONST GL_GLOW_TEX = T_SLOTS + SPR_SLOTS + 1
DIM SHARED glTexName(GL_GLOW_TEX) AS _UNSIGNED LONG, glTexDone AS LONG
' ...the guns' pictures (GLSendGuns), and two OpenGL numbers QB64PE has no
' name for (it knows OpenGL 1.1's; these came later)
DIM SHARED glGunTex(NUM_GUNS) AS _UNSIGNED LONG
CONST GL_GENERATE_MIPMAP = &H8191&, GL_CLAMP_TO_EDGE = &H812F&
REDIM SHARED glUpload(texSize * texSize - 1) AS _UNSIGNED LONG ' (a picture on its way to the card)
' The world shader (chapter 24): the program, where its uniforms and
' attributes are, whether we've tried to build it, and why it failed (if)
DIM SHARED glWorldProg AS _UNSIGNED LONG, glWorldTried AS INTEGER, glShaderOn AS INTEGER, glShaderError$
DIM SHARED glTanLoc AS LONG, glLightLoc AS LONG, glDynLoc AS LONG
' ...the post-processing shaders and render targets, and how this frame is
' going: post-processing or not, the mirror image drawn, the floor pass on
DIM SHARED glPostProg AS _UNSIGNED LONG, glBrightProg AS _UNSIGNED LONG, glBlurProg AS _UNSIGNED LONG
DIM SHARED glTargScene AS LONG, glTargA AS LONG, glTargB AS LONG, glTargRetro AS INTEGER
DIM SHARED glTargC AS LONG, glTargD AS LONG ' (the phosphor glow's, 400 x 300)
DIM SHARED glPost AS INTEGER, glReflecting AS INTEGER, glFloorPass AS INTEGER, glNeonOn AS INTEGER
' ...the WORLD MESH (GLBuildMesh): every floor, ceiling and wall face of
' the level, built once and kept in graphics memory (glMeshBuf), sorted by
' kind (0 floors, 1 ceilings, 2 walls) and texture, glMeshFirst/Count saying
' where each kind-and-texture run is; the corners while it's being built
' (glMB...); the doors (they move, so they're drawn each frame); the light
' tables' textures; and whether corners are lit from the tables (cellLit)
CONST MESH_MAX = 60000
DIM SHARED glMeshBuf AS _UNSIGNED LONG, glMeshN AS LONG, glMeshBuilding AS INTEGER, glMeshKind AS INTEGER
DIM SHARED glMeshClient AS INTEGER ' (the mesh is drawn from glMeshData in main memory, not a buffer - GLBuildMesh)
DIM SHARED glMeshFirst(3, GL_GLOW_TEX) AS LONG, glMeshCount(3, GL_GLOW_TEX) AS LONG ' (kinds: 0 floors, 1 ceilings, 2 walls, 3 raised or sunken floors)
DIM SHARED glMBPos(MESH_MAX * 3) AS SINGLE, glMBUV(MESH_MAX * 2) AS SINGLE, glMBN(MESH_MAX * 3) AS SINGLE, glMBT(MESH_MAX * 3) AS SINGLE
DIM SHARED glMBSlot(MESH_MAX) AS INTEGER, glMBKind(MESH_MAX) AS INTEGER, glMeshData(MESH_MAX * 11) AS SINGLE
DIM SHARED glNumDoors AS INTEGER, glDoorCX(MAP_SIZE * MAP_SIZE) AS INTEGER, glDoorCY(MAP_SIZE * MAP_SIZE) AS INTEGER
DIM SHARED glLitTex AS _UNSIGNED LONG, glInfoTex AS _UNSIGNED LONG, glDynTex AS _UNSIGNED LONG, glCellLitMode AS INTEGER
' ...and each texture's effects (GLSendTextures)
DIM SHARED glTexShine(GL_GLOW_TEX), glTexReflect(GL_GLOW_TEX), glTexNeon(GL_GLOW_TEX), glTexAnim(GL_GLOW_TEX)
' GL_BUMP: how strongly bumps tilt the light; GL_LIGHT_Z: how high lights
' hang (in walls: the ceiling is 1)
CONST GL_BUMP = 2.5, GL_LIGHT_Z = 0.85
DIM SHARED glVisX(MAP_SIZE * MAP_SIZE) AS INTEGER, glVisY(MAP_SIZE * MAP_SIZE) AS INTEGER, glNumVis AS LONG
DIM SHARED glEyeX, glEyeY, glEyeDX, glEyeDY, glLR, glLG, glLB, glShade
' The corners waiting to be drawn (GLCorner puts them here; GLDraw hands
' them to the card in one go): position (x, y, z), texture spot (u, v) and
' colour (red, green, blue) for up to GL_BATCH corners
CONST GL_BATCH = 16000
DIM SHARED glVerts(GL_BATCH * 3) AS SINGLE, glTexSpots(GL_BATCH * 2) AS SINGLE, glColors(GL_BATCH * 4) AS SINGLE, glNumVerts AS LONG
' ...and for bump mapping: which way the surface faces (its normal), which
' way its texture runs across it (its tangent), and the way to its light
' (x, y, z, and how much of its light that is) - the face's, set by the
' code drawing it (glFace...), and the corner's (glCornerL...)
DIM SHARED glNormals(GL_BATCH * 3) AS SINGLE, glTangents(GL_BATCH * 3) AS SINGLE, glLightVecs(GL_BATCH * 4) AS SINGLE
DIM SHARED glDynMasks(GL_BATCH * 4) AS SINGLE, glShadowA(GL_BATCH) AS SINGLE, glCellDyn(GL_DYN) AS SINGLE
' ...and each corner's texture (glVertSlot): GLDraw groups the corners by
' texture with a list of their numbers (glIndex), so each texture is
' switched to once a pass (glSlotCount, glSlotStart, glSlotFill: how many
' corners each texture has, and where its part of the list starts)
DIM SHARED glVertSlot(GL_BATCH) AS INTEGER, glIndex(GL_BATCH) AS _UNSIGNED LONG, glCurSlot AS INTEGER, glBumpOn AS INTEGER
DIM SHARED glSlotCount(GL_GLOW_TEX) AS LONG, glSlotStart(GL_GLOW_TEX) AS LONG, glSlotFill(GL_GLOW_TEX) AS LONG
DIM SHARED glFaceNX, glFaceNY, glFaceNZ, glFaceTX, glFaceTY, glFaceTZ, glCellLX, glCellLY, glCellDir
DIM SHARED glCornerLX, glCornerLY, glCornerLZ
DIM SHARED glMat(15) AS SINGLE, glMs
' --- The OpenGL extras (chapter 24): what else each frame hands over ---
'   glSet(id, half)    every setting (SET_ numbers), so SUB _GL sees this
'                      frame's choices
'   glPitch            how far you look up (+) or down (-), in radians
'   glDyn...           up to GL_DYN moving lights - your muzzle flash, blasts,
'                      bolts - and glDynReach(x, y, k, half): 1 if moving
'                      light k reaches cell (x, y), 0 if a wall's in the way
'   glPart...          the particles: sparks, embers, dust
'   glHurt, glRail     how hurt you just were, the railgun's flash (0..1)
'   glHeat...          explosions, for the heat shimmer
'   glShaft...         the light shafts near you: where, colour (as bright
'                      as their light is this frame) and a phase for each
'                      one's slow shimmer
'   glDec...           the decals: shot and scorch marks (as decalX...)
'   glWide             how much wider than 4:3 the view is (WideView: FULL
'                      WIDE), and glSideDim how much to darken the view
'                      beside our 4:3 screen (the menu's darkening only
'                      covers our screen)
'   glGun...           which gun you're holding (0: none in sight) and where
'                      on our 800 x 600 screen, from top left to bottom right,
'                      and the light on it (1 = as bright as its picture)
DIM SHARED glPitch(1) ' (glSet, the settings: with them, chapter 21)
DIM SHARED glWide(1), glSideDim(1), glAspectK
DIM SHARED glNumDecal(1) AS INTEGER, glDecX(MAX_DECALS, 1), glDecY(MAX_DECALS, 1), glDecZ(MAX_DECALS, 1)
DIM SHARED glDecNX(MAX_DECALS, 1), glDecNY(MAX_DECALS, 1), glDecNZ(MAX_DECALS, 1), glDecSize(MAX_DECALS, 1), glDecHeat(MAX_DECALS, 1)
DIM SHARED glGun(1) AS INTEGER, glGunX0(1), glGunY0(1), glGunX1(1), glGunY1(1), glGunR(1), glGunG(1), glGunB(1)
DIM SHARED glNumShaft(1) AS INTEGER, glShaftX(MAX_LIGHTS, 1), glShaftY(MAX_LIGHTS, 1), glShaftPh(MAX_LIGHTS, 1)
DIM SHARED glShaftR(MAX_LIGHTS, 1), glShaftG(MAX_LIGHTS, 1), glShaftB(MAX_LIGHTS, 1)
DIM SHARED glNumDyn(1) AS INTEGER, glDynX(GL_DYN, 1), glDynY(GL_DYN, 1), glDynZ(GL_DYN, 1), glDynRad(GL_DYN, 1)
DIM SHARED glDynR(GL_DYN, 1), glDynG(GL_DYN, 1), glDynB(GL_DYN, 1), glDynReach(MAP_SIZE, MAP_SIZE, GL_DYN, 1) AS _BYTE
DIM SHARED glNumPart(1) AS INTEGER, glPartX(MAX_PART, 1), glPartY(MAX_PART, 1), glPartZ(MAX_PART, 1), glPartSize(MAX_PART, 1)
DIM SHARED glPartR(MAX_PART, 1), glPartG(MAX_PART, 1), glPartB(MAX_PART, 1)
DIM SHARED glHurt(1), glHeatAmt(GL_HEAT, 1), glRail(1), glNumHeat(1) AS INTEGER, glHeatX(GL_HEAT, 1), glHeatY(GL_HEAT, 1)
' The light tables (chapter 24): the light for the graphics card to look up
' itself, every pixel - GL_TABLE x GL_TABLE cells of 4 numbers, for each half
' of the snapshot (half * GL_TABLE_SIZE onwards):
'   glLitData    a cell's red, green and blue light, and 1 if it's open
'   glInfoData   the middle of the light on it (x, y), and how much of its
'                light that is (glLitDir)
'   glDynData    which of the 4 moving lights reach it (1 or 0 each)
CONST GL_TABLE = 64, GL_TABLE_SIZE = 64 * 64 * 4
DIM SHARED glLitData(2 * GL_TABLE_SIZE) AS SINGLE, glInfoData(2 * GL_TABLE_SIZE) AS SINGLE, glDynData(2 * GL_TABLE_SIZE) AS SINGLE
' (for the moving lights' flood fill: the cells waiting, and which were
' reached this time - fillSeen() = fillStamp)
DIM SHARED fillX(MAP_SIZE * MAP_SIZE) AS INTEGER, fillY(MAP_SIZE * MAP_SIZE) AS INTEGER, fillD(MAP_SIZE * MAP_SIZE) AS INTEGER
DIM SHARED fillSeen(MAP_SIZE, MAP_SIZE) AS LONG, fillStamp AS LONG
' The particles themselves (spawned and moved by the game, chapter 13):
' where, how fast, how long they've left (partLife, 0 = free) out of
' partMax, colour, size, and kind (PART_)
CONST PART_SPARK = 1, PART_EMBER = 2, PART_DUST = 3, PART_FLAME = 4, PART_SMOKE = 5, PART_ARC = 6 ' (flames rise, smoke drifts up and spreads, an arc's points hang still a moment)
DIM SHARED partX(MAX_PART), partY(MAX_PART), partZ(MAX_PART), partVX(MAX_PART), partVY(MAX_PART), partVZ(MAX_PART)
DIM SHARED partLife(MAX_PART) AS INTEGER, partMax(MAX_PART) AS INTEGER, partR(MAX_PART), partG(MAX_PART), partB(MAX_PART)
DIM SHARED partSize(MAX_PART), partKind(MAX_PART) AS INTEGER, partNext AS INTEGER, dustCount AS INTEGER
' LIGHT SHAFTS: a beam under each of the level's own lights (not a lamp's or
' a terminal's) standing in an open cell - shaftCell(x, y) is the light
' whose beam starts in that cell (0: none), from BuildShafts. A beam is
' SHAFT_TOP wide (from its middle to its edge) at the ceiling, spreading to
' SHAFT_FOOT at the floor; SHAFT_AMT is how much light it adds.
CONST SHAFT_TOP = 0.22, SHAFT_FOOT = 0.75, SHAFT_AMT = 1.1
DIM SHARED shaftCell(MAP_SIZE, MAP_SIZE) AS INTEGER
' The dust stirred by you: how far round you your walking moves it
CONST WAKE_REACH = 1.1
' Each texture slot's file name (LoadTex), so OpenGL can tell what a
' texture is - a floor that should shine, a screen that should flicker
DIM SHARED texName$(T_SLOTS)
DIM SHARED texHD(T_SLOTS) AS INTEGER ' (each texture slot: a MODERN painting from hd/? OpenGL draws those smooth)
DIM SHARED pitch ' (looking up and down, chapter 8 - OpenGL only)

'-----------------------------------------------------------------------------
' CHAPTER 6: LOADING THE PICTURES AND SOUNDS
'-----------------------------------------------------------------------------
' Every picture is a PNG in the neon-caster/ folder. LoadTex and LoadSprite
' (chapter 23) open one with _LOADIMAGE and copy its colours into the
' texture() or spriteTex() array. The level's own walls, floors and
' ceilings are loaded with the level (chapter 20); these are the ones every
' level shares - all loaded by LoadPictures (at the end of the main
' program), once the settings are read: ART (SETTINGS > VIDEO) picks the
' pixel art in neon-caster/ (CLASSIC) or the paintings in neon-caster/hd/
' (MODERN), and how big they're kept (ArtReload).

' The guns you hold are kept as ordinary images (not arrays): they're drawn
' over the finished view with _PUTIMAGE, at full size (chapter 18). LoadGun
' also works out where each one's muzzle is, for the muzzle flash.
'
' gunSize is how tall each one is drawn, in screen pixels - whatever size
' its picture is. So a gun can be drawn again in more detail (twice, four
' times, eight times as many pixels across) and dropped in as it is: it
' comes out the same size. More detail shows with OpenGL, which draws the
' gun at the window's full size (chapter 24); the software renderer
' shrinks it to our 800 x 600 screen. Keep the picture square, and its
' muzzle in the same place, and aiming down the sights still lines up.
gunSize(1) = 288 : gunSize(2) = 346 : gunSize(3) = 384 : gunSize(4) = 346
CONST GUN_Y = 600 ' A gun's bottom sits here, its muzzle straight below the crosshair
' (LoadGun 1 to 4: in LoadPictures)

' Sounds: WAV files from neon-caster/sfx/ (made with PWMSFXR - see
' make-sfx.sh there). _SNDOPEN loads one and gives back a handle, a number
' we keep in a & (LONG) variable and play with PlaySfx (chapter 23).
sndStep1& = LoadSnd&("step1.wav") : sndStep2& = LoadSnd&("step2.wav")
sndBump& = LoadSnd&("bump.wav") : sndHump& = LoadSnd&("wallhump.wav")
DIM SHARED sndDoor&, sndShutter&, sndSplit& ' (shared: DoorSnd& picks one - chapter 11)
sndDoor& = LoadSnd&("door.wav") : sndShutter& = LoadSnd&("door-shutter.wav") : sndSplit& = LoadSnd&("door-split.wav")
DIM SHARED sndLiftStart&, sndLiftMove&, sndLiftStop& ' (a lift setting off, moving - looped - and stopping)
sndLiftStart& = LoadSnd&("lift-start.wav") : sndLiftMove& = LoadSnd&("lift-move.wav") : sndLiftStop& = LoadSnd&("lift-stop.wav")
DIM SHARED sndTrapFire&, sndTrapElec& ' (a trap's roar or buzz, looped while it's lit)
sndTrapFire& = LoadSnd&("trap-fire.wav") : sndTrapElec& = LoadSnd&("trap-electric.wav")
sndCard& = LoadSnd&("keycard.wav") : sndLocked& = LoadSnd&("locked.wav")
sndEmpty& = LoadSnd&("empty.wav") : sndWeapon& = LoadSnd&("weapon.wav")
sndHealth& = LoadSnd&("health.wav") : sndAmmo& = LoadSnd&("ammo.wav") : sndShells& = LoadSnd&("shells.wav")
sndBoltWall& = LoadSnd&("bolt-wall.wav")
sndHurt& = LoadSnd&("hurt.wav") : sndDie& = LoadSnd&("die.wav")
DIM SHARED sndHurtZap& : sndHurtZap& = LoadSnd&("hurt-zap.wav") ' (a shock on top of the grunt: hurtElectric)
DIM SHARED sndHurt2&, sndHurt3& ' (more ways to say ouch: HurtPlayer picks one)
' NEXUS's voice: each line's sound (neon-caster/speech/KEY.wav) and words,
' looked up by key (Say); what's on screen (speechText$, until
' speechUntil!), and frames till the next taunt
CONST MAX_LINES = 48
DIM SHARED lineKey$(MAX_LINES), lineText$(MAX_LINES), lineSnd&(MAX_LINES), numLines AS INTEGER
DIM SHARED speechText$, speechUntil!, tauntWait AS LONG, cliMode AS INTEGER, nexusImg&
' The sound limiter (PlaySfxPan, chapter 23), and where you're listening
' from, facing (earDX, earDY) - for 3D sound
' How far a sound in the world carries, in cells (SfxAt): most things -
' doors, shots, explosions - and a monster's muttering and growling
CONST SFX_RANGE = 20, SFX_CHATTER = 12
CONST SFX_HEADROOM = 1.6
DIM SHARED sfxLoad!, sfxThis&(32), sfxThisN AS INTEGER, earDX, earDY, sfxFrameT! ' (sfxFrameT!: when SfxFrame last ran)
earDX = 1 : earDY = 0
DIM SHARED kickTimer AS INTEGER, kickImg&, sndKick&, sndKickSwing& ' (the kick: chapter 12)
sndHurt2& = LoadSnd&("hurt2.wav") : sndHurt3& = LoadSnd&("hurt3.wav")
sndKick& = LoadSnd&("kick.wav") : sndKickSwing& = LoadSnd&("kick-swing.wav")
' NEXUS's lines (and its minions' barks): key, then words
RESTORE SpeechLines
DO
    READ k$, t$ : IF k$ = "" THEN EXIT DO
    numLines = numLines + 1 : lineKey$(numLines) = k$ : lineText$(numLines) = t$
    p$ = AssetPath$("speech/" + k$ + ".wav") : IF _FILEEXISTS(p$) THEN lineSnd&(numLines) = _SNDOPEN(p$, "noasync")
LOOP
tauntWait = 3600
IF sndKick& = 0 THEN sndKick& = LoadSnd&("bump.wav")
gunSnd&(1) = LoadSnd&("shoot.wav") : gunSnd&(2) = LoadSnd&("scatter.wav") : gunSnd&(3) = LoadSnd&("repeater.wav")
gunSnd&(4) = LoadSnd&("rail.wav")
sndBarrel& = LoadSnd&("barrel.wav") : sndArmor& = LoadSnd&("armor.wav") : sndExit& = LoadSnd&("exit.wav")
' A decoration taking a hit, and breaking (by kind: 2 lamp, 3 plant, 4 terminal)
DIM SHARED decoBreakSnd&(DECO_KINDS) ' (shared: BreakLight uses the lamp's)
sndDecoHit& = LoadSnd&("deco-hit.wav")
decoBreakSnd&(2) = LoadSnd&("lamp-break.wav") : decoBreakSnd&(3) = LoadSnd&("plant-break.wav") : decoBreakSnd&(4) = LoadSnd&("terminal-break.wav")
decoBreakSnd&(5) = LoadSnd&("crate-break.wav") : decoBreakSnd&(6) = decoBreakSnd&(4) : decoBreakSnd&(7) = decoBreakSnd&(4)
decoBreakSnd&(9) = decoBreakSnd&(4)
FOR k = 10 TO 19 ' (the set pieces: furniture cracks like a crate, the rest like a terminal)
    IF k = 10 OR k = 18 OR k = 19 THEN decoBreakSnd&(k) = decoBreakSnd&(5) ELSE decoBreakSnd&(k) = decoBreakSnd&(4)
NEXT
' The event rooms' sounds (chapter 19): the lockdown alarm, a win, a loss,
' the trap's zap, a monster arriving
DIM SHARED sndAlarm&, sndFanfare&, sndFail&, sndZap&, sndSpawn&
sndAlarm& = LoadSnd&("alarm.wav") : sndFanfare& = LoadSnd&("fanfare.wav") : sndFail& = LoadSnd&("fail.wav")
DIM SHARED sndSizzle& ' (a burning floor - chapter 22's heights)
sndZap& = LoadSnd&("zap.wav") : sndSpawn& = LoadSnd&("spawn.wav") : sndSizzle& = LoadSnd&("sizzle.wav")
DIM SHARED sndSteal&, sndHoard&, sndPlate&, sndLaser&, sndCloset&, sndPowerDown&, sndPowerUp&
sndSteal& = LoadSnd&("thief-steal.wav") : sndHoard& = LoadSnd&("hoard-open.wav") : sndPlate& = LoadSnd&("plate-click.wav")
sndLaser& = LoadSnd&("laser-zap.wav") : sndCloset& = LoadSnd&("closet.wav")
DIM SHARED sndGlassHit&, sndGlassBreak&
sndGlassHit& = LoadSnd&("glass-hit.wav") : sndGlassBreak& = LoadSnd&("glass-break.wav")
sndTeleport& = LoadSnd&("teleport.wav") : IF sndTeleport& = 0 THEN sndTeleport& = LoadSnd&("jack-out.wav")
sndJackIn& = LoadSnd&("jack-in.wav") : sndJackOut& = LoadSnd&("jack-out.wav") : sndCore& = LoadSnd&("core.wav")
sndPowerDown& = LoadSnd&("power-down.wav") : sndPowerUp& = LoadSnd&("power-up.wav")
IF sndSteal& = 0 THEN sndSteal& = LoadSnd&("keycard.wav")
IF sndHoard& = 0 THEN sndHoard& = LoadSnd&("exit.wav")
IF sndPlate& = 0 THEN sndPlate& = LoadSnd&("locked.wav")
IF sndLaser& = 0 THEN sndLaser& = sndZap&
IF sndCloset& = 0 THEN sndCloset& = LoadSnd&("door-shutter.wav")
' (any that aren't there yet borrow a near enough sound)
IF sndAlarm& = 0 THEN sndAlarm& = LoadSnd&("sentry-alert.wav")
IF sndFanfare& = 0 THEN sndFanfare& = LoadSnd&("exit.wav")
IF sndFail& = 0 THEN sndFail& = LoadSnd&("locked.wav")
IF sndZap& = 0 THEN sndZap& = LoadSnd&("bolt-wall.wav")
IF sndSpawn& = 0 THEN sndSpawn& = LoadSnd&("drone-alert.wav")
DIM SHARED sndOvercharge&, sndAmp&, sndAmpEnd&, ampTimer ' (ampTimer: frames left of the damage amp)
sndOvercharge& = LoadSnd&("overcharge.wav") : sndAmp& = LoadSnd&("amp.wav") : sndAmpEnd& = LoadSnd&("amp-end.wav")
CONST STEP_WALK = 1.4, STEP_RUN = 2.2 ' Cells walked per footstep: walking (about 2.6 steps a second) and running (3.3 - longer strides)

' The monster types table: SetMonType fills in the "mtype" arrays (one
' entry per TYPE of monster - see chapter 3) for types 1-9 (6 stalker, 7 spitter, 8 the overseer, the last
' sector's boss, 9 the thief bot). Speeds are set against yours: you walk
' 0.06 and run 0.12 - only the thief is faster than you walk. Speed is in
' cells a frame; height is in walls (1 = as tall as a wall); lift and bob
' are how high it hovers and how much it bobs; reach is how close it must
' be to hit you; damage is dmg plus a random 0 to +rnd - 1; cooldown (cool)
' is frames between attacks; slot is its sprite slot (chapter 5).
'          type name       HP  speed  height lift bob   reach dmg +rnd cool slot
SetMonType 1,   "drone",   3,  0.03,  0.65,  0.2, 0.05, 0.95, 6,  4,   60,  9
SetMonType 2,   "gunner",  4,  0.025, 0.8,   0,   0,    0,    7,  4,   110, 11
SetMonType 3,   "heavy",   10, 0.02,  0.95,  0,   0,    1.25, 15, 8,   95,  13
SetMonType 4,   "crawler", 2,  0.045, 0.4,   0,   0.02, 0.75, 3,  3,   50,  15
SetMonType 5,   "sentry",  8,  0,     0.75,  0,   0,    0,    5,  4,   70,  17
SetMonType 6,   "stalker", 3,  0.052, 0.75,  0,   0,    0.9,  5,  4,   50,  S_MONX + 1
SetMonType 7,   "spitter", 6,  0.022, 0.7,   0,   0,    0,    6,  4,   95,  S_MONX + 3
SetMonType 8,   "overseer", 80, 0.014, 1.4,  0.3, 0.06, 0,    9,  5,   45,  S_MONX + 5
SetMonType 9,   "thief",   5,  0.09,  0.55,  0,   0,    0.8,  0,  0,   60,  S_MONX + 7
SetMonType 10,  "ice",     2,  0.05,  0.5,   0.3, 0.06, 0.75, 5,  3,   50,  S_MONX + 9
mtypeRanged(2) = -1 : mtypeRanged(5) = -1 : mtypeRanged(7) = -1 : mtypeRanged(8) = -1
' ...and that table changed by neon-caster/monsters.txt, if it's there:
' every monster's numbers as plain text, to tune without changing the
' program - by hand, or in the monster editor (chapter 21)
ReadMonsters
HudDefaults : ReadHud ' (the HUD's layout: chapter 18's, or hud.txt's)
' The newer monsters' pictures: each, then itself hurt (MakeHurt: flashed red)
' (and their pictures: LoadPictures)
mtypeAlertSnd&(1) = LoadSnd&("drone-alert.wav") : mtypeAttackSnd&(1) = LoadSnd&("drone-attack.wav")
mtypeHitSnd&(1) = LoadSnd&("drone-hit.wav") : mtypeDieSnd&(1) = LoadSnd&("drone-die.wav")
mtypeAlertSnd&(2) = LoadSnd&("gunner-alert.wav") : mtypeAttackSnd&(2) = LoadSnd&("gunner-shoot.wav")
mtypeHitSnd&(2) = LoadSnd&("gunner-hit.wav") : mtypeDieSnd&(2) = LoadSnd&("gunner-die.wav")
mtypeAlertSnd&(3) = LoadSnd&("heavy-alert.wav") : mtypeAttackSnd&(3) = LoadSnd&("heavy-attack.wav")
mtypeHitSnd&(3) = LoadSnd&("heavy-hit.wav") : mtypeDieSnd&(3) = LoadSnd&("heavy-die.wav")
mtypeAlertSnd&(4) = LoadSnd&("crawler-alert.wav") : mtypeAttackSnd&(4) = LoadSnd&("crawler-attack.wav")
mtypeHitSnd&(4) = LoadSnd&("crawler-hit.wav") : mtypeDieSnd&(4) = LoadSnd&("crawler-die.wav")
mtypeAlertSnd&(5) = LoadSnd&("sentry-alert.wav") : mtypeAttackSnd&(5) = LoadSnd&("sentry-shoot.wav")
mtypeHitSnd&(5) = LoadSnd&("sentry-hit.wav") : mtypeDieSnd&(5) = LoadSnd&("sentry-die.wav")
FOR mtype = 1 TO MON_TYPES ' Every one's idle and hunting sounds: name-idle, name-hunt
    mtypeIdleSnd&(mtype) = LoadSnd&(mtypeName$(mtype) + "-idle.wav") : mtypeHuntSnd&(mtype) = LoadSnd&(mtypeName$(mtype) + "-hunt.wav")
NEXT
FOR mtype = 6 TO MON_TYPES ' (the newer ones: name-alert, -attack or -shoot, -hit, -die)
    nm$ = mtypeName$(mtype) : mtypeAlertSnd&(mtype) = LoadSnd&(nm$ + "-alert.wav")
    IF mtypeRanged(mtype) THEN mtypeAttackSnd&(mtype) = LoadSnd&(nm$ + "-shoot.wav") ELSE mtypeAttackSnd&(mtype) = LoadSnd&(nm$ + "-attack.wav")
    mtypeHitSnd&(mtype) = LoadSnd&(nm$ + "-hit.wav") : mtypeDieSnd&(mtype) = LoadSnd&(nm$ + "-die.wav")
NEXT

' Loop counters and pixel positions used by the drawing code are LONG
' (whole numbers) - integer maths is quicker in the inner loops. Anything
' not DIMmed is a SINGLE (a decimal number), QB64PE's default.
' --- Settings, key bindings, the menu and music (all in chapter 21) ---
' SET_ = a setting's number. The settings live in one table, setting(), so
' the menu, the settings file and the game can all treat them the same way.
' Each is defined by one DefineSetting line below: the name it has in the
' settings file, its label in the menu, what kind of control it gets (a
' slider, an on/off toggle, or a "< choice >"), its lowest and highest
' value, how much one press changes it, and its value to start with.
CONST NUM_SETTINGS = 41
CONST RES_NATIVE = 1, RES_RETRO = 7
CONST SET_SFX = 1, SET_MUSIC = 2, SET_SPEECH = 3, SET_FOV = 4, SET_XSTYLE = 5
CONST SET_XCOLOR = 6, SET_XSIZE = 7, SET_BOB = 8, SET_SHAKE = 9, SET_MOUSE = 10
CONST SET_XALPHA = 11, SET_XFEEDBACK = 12, SET_HURTDIR = 13, SET_RENDERER = 14, SET_FPS = 15
CONST SET_BUMP = 16, SET_GLOW = 17, SET_NEON = 18, SET_SMOOTH = 19, SET_DYNLIGHT = 20, SET_SHADOWS = 21
CONST SET_PARTICLES = 22, SET_REFLECT = 23, SET_BLOOM = 24, SET_SCREENFX = 25, SET_HITFX = 26, SET_RES = 27, SET_LOOK = 28
CONST SET_SCANLINES = 29, SET_PHOSPHOR = 30, SET_SHAFTS = 31
CONST SET_SCANGAP = 32, SET_SCANTHICK = 33, SET_DISPLAY = 34, SET_AIMSENS = 35
CONST SET_SPATIAL = 36, SET_LIMITER = 37, SET_CUTSCENES = 38, SET_TAUNTS = 39, SET_ART = 40
CONST SET_MODE = 41
' MODE: a whole look at once (ModeWants) - or CUSTOM, when the settings
' don't all match one
CONST MODE_CUSTOM = 0, MODE_OLDSCHOOL = 1, MODE_90S = 2, MODE_NEWSCHOOL = 3
DIM SHARED setting(NUM_SETTINGS), setDefault(NUM_SETTINGS), setMin(NUM_SETTINGS), setMax(NUM_SETTINGS)
DIM SHARED glSet(NUM_SETTINGS, 1) ' (OpenGL's copy of them, each frame: chapter 24)
' Each letter's scancode (where it is on the keyboard), a to z, as
' characters 32 on (CHR$(scancode + 32)), for KeyAt% (chapter 21)
CONST LETTER_SCANS = ">PN@2ABC7DEFRQ8903?46O1M5L"
DIM SHARED keyDevice AS INTEGER, keyTrusted AS INTEGER, keyScanAdd AS INTEGER
DIM SHARED setStep(NUM_SETTINGS), setKind(NUM_SETTINGS), setKey$(NUM_SETTINGS), setLabel$(NUM_SETTINGS)
' Your qb64pe, if you've said where it is (SETTINGS > QB64PE COMPILER, or
' the qb64pe console command) - kept as "qb64pe=" in the settings file; ""
' means look for it (QB64Path$, chapter 19)
DIM SHARED qbChosen$
' MI_ = Menu Item kinds (what a line of a menu is and does)
CONST MI_ACTION = 1, MI_SUBMENU = 2, MI_SLIDER = 3, MI_TOGGLE = 4, MI_CHOICE = 5
CONST MI_KEY = 6, MI_BACK = 7, MI_TEXT = 8
'             setting        file name             menu label            control    min max  step start
DefineSetting SET_SFX,       "sfx",                "SFX VOLUME",         MI_SLIDER, 0,  100, 5,   100
DefineSetting SET_MUSIC,     "music",              "MUSIC VOLUME",       MI_SLIDER, 0,  100, 5,   50
DefineSetting SET_SPEECH,    "speech",             "SPEECH VOLUME",      MI_SLIDER, 0,  100, 5,   100
DefineSetting SET_FOV,       "fov",                "FIELD OF VIEW",      MI_SLIDER, 50, 110, 2,   80
DefineSetting SET_XSTYLE,    "crosshair_style",    "CROSSHAIR STYLE",    MI_CHOICE, 1,  6,   1,   4
DefineSetting SET_XCOLOR,    "crosshair_color",    "CROSSHAIR COLOR",    MI_CHOICE, 1,  6,   1,   1
DefineSetting SET_XSIZE,     "crosshair_size",     "CROSSHAIR SIZE",     MI_SLIDER, 1,  5,   1,   5
DefineSetting SET_BOB,       "weapon_bob",         "WEAPON BOBBING",     MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHAKE,     "screen_shake",       "SCREEN SHAKE",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_MOUSE,     "mouse_speed",        "MOUSE LOOK SPEED",   MI_SLIDER, 1,  10,  1,   2
DefineSetting SET_XALPHA,    "crosshair_opacity",  "CROSSHAIR OPACITY",  MI_SLIDER, 10, 100, 10,  100
DefineSetting SET_XFEEDBACK, "crosshair_feedback", "CROSSHAIR FEEDBACK", MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_HURTDIR,   "damage_indicators",  "DAMAGE INDICATORS",  MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RENDERER,  "renderer",           "RENDERER",           MI_CHOICE, 1,  2,   1,   2 ' 1 software, 2 OpenGL (chapter 24)
DefineSetting SET_FPS,       "show_fps",           "SHOW FPS",           MI_TOGGLE, 0,  1,   1,   0
DefineSetting SET_BUMP,      "bump_mapping",       "BUMP MAPPING",       MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
DefineSetting SET_GLOW,      "glows",              "GLOWS",              MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
' ART: 1 CLASSIC (the pixel art), 2 MODERN (neon-caster/hd/'s paintings)
DefineSetting SET_ART,       "art",                "ART",                MI_CHOICE, 1,  2,   1,   1
' The OpenGL effects (chapter 24; SETTINGS > EFFECTS) and the two OpenGL
' view settings (SETTINGS > VIDEO). SCREEN FX: 1 off, 2 scanlines, 3 CRT.
' RESOLUTION: what size OpenGL draws the 3D view, 1 (RES_NATIVE: the
' window's own pixels) to 7 (RES_RETRO: the software renderer's 400 x 300) -
' ResSize, chapter 24, has the sizes in between (2160P 4K down to 480P).
DefineSetting SET_NEON,      "neon",               "NEON",               MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SMOOTH,    "smooth_light",       "SMOOTH LIGHT",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_DYNLIGHT,  "moving_lights",      "MOVING LIGHTS",      MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHADOWS,   "shadows",            "SHADOWS",            MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_PARTICLES, "particles",          "PARTICLES",          MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_REFLECT,   "reflections",        "WET FLOORS",         MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_BLOOM,     "bloom",              "BLOOM",              MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SCREENFX,  "screen_fx",          "SCREEN FX",          MI_CHOICE, 1,  3,   1,   2
DefineSetting SET_HITFX,     "hit_fx",             "HIT FX",             MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RES,       "resolution",         "RESOLUTION",         MI_CHOICE, 1,  7,   1,   2
DefineSetting SET_LOOK,      "look_up_down",       "LOOK UP / DOWN",     MI_TOGGLE, 0,  1,   1,   1
' How dark the scanlines are (with SCREEN FX on), and how much light bleeds
' round bright things, as on a real tube's glass (both 0..100%)
DefineSetting SET_SCANLINES, "scanlines",          "SCANLINE DARKNESS",  MI_SLIDER, 0,  100, 5,   50
' ...and how far apart they are (in the window's own pixels) and how thick
' (how much of that gap is dark)
DefineSetting SET_SCANGAP,   "scanline_spacing",   "SCANLINE SPACING",   MI_SLIDER, 2,  16,  1,   3
DefineSetting SET_SCANTHICK, "scanline_thickness", "SCANLINE THICKNESS", MI_SLIDER, 10, 90,  5,   35
' DISPLAY: 1 in a window; full screen 2 WIDE (with OpenGL, the 3D view
' fills a widescreen and sees more to the sides; the HUD stays 4:3 in the
' middle), 3 4:3 (our shape, black bars at the sides), 4 STRETCH (all of
' it stretched to fill the screen) - ApplyDisplay, chapter 21
DefineSetting SET_DISPLAY,   "display",            "DISPLAY",            MI_CHOICE, 1,  4,   1,   1
DefineSetting SET_PHOSPHOR,  "phosphor_glow",      "PHOSPHOR GLOW",      MI_SLIDER, 0,  100, 5,   50
' Beams of light under the ceiling lights, with the dust hanging in them
' How fast the mouse turns you while you aim down the sights, as well as
' the zoom slowing it (chapter 8)
' Sound: placed round you (3D SOUND: panned by where it is, fainter with
' distance, muffled behind walls), and kept from getting too loud when a
' lot happens at once (LIMITER - PlaySfx, chapter 23). NEXUS's voice: the
' transmissions as you arrive in a sector (CUTSCENES), and what it says to
' you now and then while you play (TAUNTS).
DefineSetting SET_SPATIAL,   "spatial_sound",      "3D SOUND",           MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_LIMITER,   "sound_limiter",      "LIMITER",            MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_CUTSCENES, "cutscenes",          "CUTSCENES",          MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_TAUNTS,    "taunts",             "NEXUS TAUNTS",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_AIMSENS,   "aim_sensitivity",    "AIM SENSITIVITY",    MI_SLIDER, 10, 100, 5,   50
DefineSetting SET_SHAFTS,    "light_shafts",       "LIGHT SHAFTS",       MI_TOGGLE, 0,  1,   1,   1
' MODE: OLDSCHOOL, 90S or NEWSCHOOL - every video and effects setting at
' once (ModeWants, chapter 21). It isn't kept as itself: what it shows is
' worked out from the others (ModeNow), so it says CUSTOM after you change
' one by hand.
DefineSetting SET_MODE,      "mode",               "MODE",               MI_CHOICE, 0,  3,   1,   0
DIM SHARED modeWas ' (the MODE last put into effect: ApplySettings)
' BIND_ = a key binding's number: what each one does, its name in the
' settings file, its menu label, and its key to start with (a _KEYDOWN
' code: letters as lower case, 32 Space, 100306 left Ctrl, 16128 F5,
' 17152 F9, 9 Tab, 100304 left Shift)
CONST NUM_BINDS = 11
CONST BIND_FORWARD = 1, BIND_BACK = 2, BIND_LEFT = 3, BIND_RIGHT = 4
CONST BIND_USE = 5, BIND_FIRE = 6, BIND_QUICKSAVE = 7, BIND_QUICKLOAD = 8, BIND_MAP = 9, BIND_RUN = 10, BIND_KICK = 11
DIM SHARED keyBind&(NUM_BINDS), bindDefault&(NUM_BINDS), bindKey$(NUM_BINDS), bindLabel$(NUM_BINDS)
'          binding         file name        menu label      key
DefineBind BIND_FORWARD,   "key_forward",   "MOVE FORWARD", 119
DefineBind BIND_BACK,      "key_back",      "MOVE BACK",    115
DefineBind BIND_LEFT,      "key_left",      "STRAFE LEFT",  97
DefineBind BIND_RIGHT,     "key_right",     "STRAFE RIGHT", 100
DefineBind BIND_USE,       "key_use",       "OPEN / USE",   32
DefineBind BIND_FIRE,      "key_fire",      "FIRE",         100306
DefineBind BIND_QUICKSAVE, "key_quicksave", "QUICK SAVE",   16128
DefineBind BIND_QUICKLOAD, "key_quickload", "QUICK LOAD",   17152
DefineBind BIND_MAP, "key_map", "MAP", 9
DefineBind BIND_RUN,       "key_run",       "RUN (HOLD)",   100304
DefineBind BIND_KICK,      "key_kick",      "KICK",         102
' SCR_ = the menu's screens; MA_ = Menu Actions (what choosing a button does)
CONST SCR_MAIN = 1, SCR_GAME = 2, SCR_SAVE = 3, SCR_LOAD = 4, SCR_SETTINGS = 5
CONST SCR_AUDIO = 6, SCR_GAMEPLAY = 7, SCR_CONTROLS = 8, SCR_CREDITS = 9, SCR_QUIT = 10, SCR_VIDEO = 11, SCR_EFFECTS = 12
CONST MA_RESUME = 1, MA_NEW = 2, MA_SAVE = 3, MA_LOAD = 4, MA_QUIT = 5, MA_KEYS_DEFAULT = 6, MA_SECTOR = 7
CONST SCR_SECTOR = 13, SCR_QB64 = 14, SCR_CUSTOM = 15
CONST MA_QB64_TYPE = 8, MA_QB64_BROWSE = 9, MA_QB64_AUTO = 10, MA_NEWSECTOR = 11
' --- The console (` opens it, like Quake's; chapter 21): what's been
' printed (conLog$, the last CON_LOG lines), the line being typed, the
' lines typed before (conHist$, for Up and Down), and the commands waiting
' to run (conQ$, from the command line or exec - one more each frame until
' a "wait" holds them back for conWait frames). conLogFile$: a file every
' printed line also goes to (logfile). noSaveSettings: settings changed
' from the command line are for this run only.
CONST CON_LOG = 200, CON_QUEUE = 256, CON_HIST = 32
DIM SHARED conLog$(CON_LOG), conLogN AS LONG, conLogFile$, noSaveSettings AS INTEGER
DIM SHARED conHist$(CON_HIST), conHistN AS INTEGER
DIM SHARED conQ$(CON_QUEUE), conQHead AS INTEGER, conQTail AS INTEGER, conWait AS LONG
' (a screenshot: glShotReq 1 asks SUB _GL for one, 2 says it's in glShotMem,
' glShotW x glShotH; shotFile$ is where it goes)
DIM SHARED glShotReq AS INTEGER, glShotMem AS _MEM, glShotW AS LONG, glShotH AS LONG, shotFile$
DIM SHARED monStartN AS INTEGER, monStartX(MAX_MON), monStartY(MAX_MON), monStartType(MAX_MON) AS INTEGER
' The items on the menu screen showing now: label, kind (MI_), what it
' refers to (a screen, a setting, a binding or a save slot), its action
' (MA_), whether it can be chosen, and a line of small print beside it
CONST MAX_MI = 16
DIM SHARED miLabel$(MAX_MI), miKind(MAX_MI), miRef(MAX_MI), miAct(MAX_MI), miOn(MAX_MI), miInfo$(MAX_MI)
DIM SHARED numMI, menuTitle$, menuSel, menuCapture, menuWide, menuScreen, menuInGame
DIM SHARED menuTyping, menuTyped$, menuTypeBad ' (typing qb64pe's path: MenuTypeKey)
DIM menuStack(10), menuStackSel(10) ' The screens you came through (for BACK)
' MENU_ = where the menu is drawn: the first row, the gap between rows,
' where labels start, and where sliders and other controls go
CONST MENU_TOP = 176, MENU_ROW = 32, MENU_LABEL_X = 140, MENU_WIDGET_X = 470, MENU_WIDGET_W = 200
CONST SPLASH_SECONDS = 3.5 ' How long the splash screen stays up (any key skips it)
' Saved games: the slots, and the file's first bytes, so a file from
' something else (or an older version) is never read as a save
CONST NUM_SLOTS = 3, SAVE_TAG = "NCSAVE04", SAVE_INFO_LEN = 48
' Things the settings change, worked out by ApplySettings: the camera
' plane's length (from the field of view) and the mouse turn speed
DIM SHARED fovPlane, turnSpeed, displayAsked, displayModeNow
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
' Music: one looping track for the title menu and one per level, and the
' one playing now. (Dark techno, made with soundmon's AI music mode.)
DIM SHARED menuMusic&, levelMusic&(NUM_LEVELS), nowPlaying& ' (your own sectors borrow these: SectorMusic&)
DIM SHARED sectorName$(NUM_LEVELS + MAX_CUSTOM) ' (every level's name, for the route map and SELECT SECTOR: ReadSectorNames - "" for a sector of yours not made yet)
' A level as its file says it (ReadLevelFile, chapter 22): its name, its
' pictures, its ambient light, its zones, lights and event rooms, and its
' map's rows - LoadLevel builds the level from these
CONST MAX_ZONES = 64
DIM SHARED lvlNote$ ' (the comments at the top of its file, kept when the editor saves it)
' --- Heights (chapter 22's [floor] and [ceiling]): every cell's floor and
' ceiling, in walls (0 and 1 unless the level says otherwise). In the
' level file, a map of one character a cell: . the usual, 0-9 and a-z
' that many eighths of a wall up, A-H that many eighths down (a pit).
' levelFlat: none anywhere - the game as it was, and the software
' renderer's classic way (chapter 15). You (playerZ, your feet) step up
' anything up to STEP_UP, fall off anything higher, and need BODY_H of
' room; your eye is EYE_H above your feet (eyeZ, eased up steps). walkZ:
' the height of whoever Walkable is asked about (-999: don't care).
CONST H_STEP = 0.125, H_UP$ = "0123456789abcdefghijklmnopqrstuvwxyz", H_DOWN$ = "ABCDEFGH"
CONST STEP_UP = 0.32, EYE_H = 0.5, BODY_H = 0.7, FALL_G = 0.01, PIT_DEPTH = -0.99
' Floors that do something (FloorHazard, by the floor's picture): molten or
' lava burns (BURN_DAMAGE every BURN_EVERY frames you stand in it); murky
' water or slime slows you (SLOW_WADE: how much of your speed you keep).
' Monsters won't walk into the burning ones (walkFromHaz, Walkable).
CONST HAZ_BURN = 1, HAZ_WADE = 2, BURN_DAMAGE = 5, BURN_EVERY = 30, SLOW_WADE = 0.7
DIM SHARED burnWait AS INTEGER, walkFromHaz AS INTEGER ' (sndSizzle&: with the other sounds, chapter 6)
DIM SHARED rowF(RENDER_H - 1) AS SINGLE, rowC(RENDER_H - 1) AS SINGLE ' (HeightColumn: each row's distance per unit of height)
DIM SHARED floorH(MAP_SIZE, MAP_SIZE) AS SINGLE, ceilH(MAP_SIZE, MAP_SIZE) AS SINGLE, levelFlat AS INTEGER
DIM SHARED lvlFloorRow$(MAP_SIZE - 1), lvlCeilRow$(MAP_SIZE - 1)
DIM SHARED playerZ AS SINGLE, playerVZ AS SINGLE, eyeZ AS SINGLE, walkZ AS SINGLE
DIM SHARED boltZ(MAX_BOLTS) AS SINGLE, boltDZ(MAX_BOLTS) AS SINGLE
' --- Lifts ([lifts] in the level file): a rectangle of floor that moves
' between two heights (low, high) - mode 1 up and down by itself, mode 2
' an elevator: up when you step on, back down a while after you step off.
' Each frame (MoveLifts) its cells' floorH is set to where it is (liftZ),
' so standing, falling and drawing all just follow it; OpenGL draws it
' each frame, like a door (GLLifts), not in the world mesh.
CONST MAX_LIFTS = 16
DIM SHARED numLifts AS INTEGER, liftCell(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED liftX0(MAX_LIFTS) AS INTEGER, liftY0(MAX_LIFTS) AS INTEGER, liftX1(MAX_LIFTS) AS INTEGER, liftY1(MAX_LIFTS) AS INTEGER
DIM SHARED liftLow(MAX_LIFTS) AS SINGLE, liftHigh(MAX_LIFTS) AS SINGLE, liftMode(MAX_LIFTS) AS INTEGER, liftSpeed(MAX_LIFTS) AS SINGLE
DIM SHARED liftWasDir(MAX_LIFTS) AS INTEGER, liftHum&(MAX_LIFTS) ' (which way it went last frame; its motor - its own looping copy of lift-move.wav: LiftSound)
DIM SHARED liftZ(MAX_LIFTS) AS SINGLE, liftDir(MAX_LIFTS) AS INTEGER, liftWait(MAX_LIFTS) AS INTEGER
DIM SHARED lvlNumLifts AS INTEGER, lvlLift(MAX_LIFTS, 8) AS SINGLE
' --- Triggers ([triggers] in the level file, chapter 19): WHEN, then a colon,
' then what happens - console commands (chapter 21), split by ;. WHEN is
'   enter X0 Y0 X1 Y1   you walk into that rectangle (a line: one cell wide)
'   use X Y             you press Space at that cell
'   clear X0 Y0 X1 Y1   every monster that started in it is dead
'   time SECONDS        that long into the level
' and "repeat" after it to go off every time (else just once).
' trig...: each one taken apart (TakeTrigger); trigWas: you were in it
' last frame (an enter goes off as you step in, not while you stand there).
CONST MAX_TRIGS = 48
DIM SHARED lvlNumTrigs AS INTEGER, lvlTrig$(MAX_TRIGS)
' [faces]: a picture on one face - a wall's side, a step's or a lintel's,
' a floor, a ceiling - instead of the usual. lvlFaceS: 1-4 a side (east,
' south, west, north - a wall's, or a step's face), 5-8 a lintel's side,
' 9 the floor, 10 the ceiling. lvlFaceD: 0 the whole face; 1 divided
' left | right, 2 top | bottom - the second picture on the second half.
' BuildLevel gives each picture a slot (T_CUSTOM + n) and the cells
' faceTex(x, y, 1-8) - 0: the usual - floorTex, ceilTex.
CONST MAX_FACES = 4000
DIM SHARED lvlNumFaces AS INTEGER, lvlFaceX(MAX_FACES) AS INTEGER, lvlFaceY(MAX_FACES) AS INTEGER, lvlFaceS(MAX_FACES) AS INTEGER, lvlFaceD(MAX_FACES) AS INTEGER
DIM SHARED lvlFaceP1$(MAX_FACES), lvlFaceP2$(MAX_FACES)
DIM SHARED faceTex(MAP_SIZE, MAP_SIZE, 8) AS INTEGER, faceTex2(MAP_SIZE, MAP_SIZE, 8) AS INTEGER, faceDiv(MAP_SIZE, MAP_SIZE, 8) AS INTEGER
DIM SHARED numTrigs AS INTEGER, trigWhen$(MAX_TRIGS), trigX0(MAX_TRIGS) AS INTEGER, trigY0(MAX_TRIGS) AS INTEGER, trigX1(MAX_TRIGS) AS INTEGER, trigY1(MAX_TRIGS) AS INTEGER
DIM SHARED trigRepeat(MAX_TRIGS) AS INTEGER, trigDone(MAX_TRIGS) AS INTEGER, trigWas(MAX_TRIGS) AS INTEGER, trigCmd$(MAX_TRIGS)
' --- Teleporters (& on the map): pads that pair up in the order they're
' found, reading the map like a book - the 1st with the 2nd, the 3rd with
' the 4th. Step on one and you're on the other (padReady: you've stepped
' off since, so you don't bounce straight back).
CONST MAX_PADS = 16
' --- Code terminals ($ on the map, chapter 19): QB64 programs to put back
' together. Space at one: the doors near it slam and lock (doorLock 3)
' and its puzzle opens (RunPuzzle) - a program from neon-caster/puzzles/,
' its lines shuffled and words blanked out. Put it right and it's compiled
' and run, for real if qb64pe can be found (QB64Path$ - or where you've
' told it, in SETTINGS > QB64PE COMPILER), and its output checked: right,
' and the doors open. No qb64pe: the lines are checked against the answer
' instead. Which puzzle: the level file's
' "puzzles =" list, one a terminal in reading order.
CONST MAX_TERMS = 8, MAX_PZ_LINES = 24, MAX_PZ_BLANKS = 6, MAX_PZ_HINTS = 6
DIM SHARED numTerms AS INTEGER, termX(MAX_TERMS) AS INTEGER, termY(MAX_TERMS) AS INTEGER, termDone(MAX_TERMS) AS INTEGER, lvlPuzzles$
DIM SHARED pzTitle$, pzLesson$, pzExpect$, pzChapter$, pzN AS INTEGER, pzAns$(MAX_PZ_LINES), pzOrder(MAX_PZ_LINES) AS INTEGER
DIM SHARED pzBlanks AS INTEGER, pzBlankLine(MAX_PZ_BLANKS) AS INTEGER, pzBlankWord$(MAX_PZ_BLANKS), pzBlankIn$(MAX_PZ_BLANKS)
DIM SHARED pzHints AS INTEGER, pzHint$(MAX_PZ_HINTS), pzShown AS INTEGER, pzOut$, pzFails AS INTEGER
DIM SHARED numPads AS INTEGER, padX(MAX_PADS) AS INTEGER, padY(MAX_PADS) AS INTEGER, padReady AS INTEGER
DIM SHARED lvlName$, lvlWall$(6), lvlFloor$(4), lvlCeil$(2), lvlAmb(4), lvlOK AS INTEGER
DIM SHARED lvlNumZones AS INTEGER, lvlZone(MAX_ZONES, 7) AS INTEGER
DIM SHARED lvlNumLights AS INTEGER, lvlLight(MAX_LIGHTS, 8) AS SINGLE
DIM SHARED lvlNumEvents AS INTEGER, lvlEvent(MAX_EVENTS, 8) AS INTEGER
DIM SHARED lvlRow$(MAP_SIZE - 1)
' --- The level editor (chapter 21): F2. editMode: on; editView: 0 the map
' from above (RunEditor), 1 walking round inside it (EditFP, in the game
' loop). editGlyph$: what you're placing - a map character (chapter 22).
' Each change is made to the level as its file says it (lvlRow$() and
' the rest) and the level built again from that (BuildLevel); editUndo$()
' remembers how it was before each change. texFile$(): which picture is in
' each texture slot now, so building it again only loads what changed.
CONST EDIT_GLYPHS = ".#NCKPG/\DHXRBYE!=@$%&rby+*uae234MqjmghcskwzToiptxlnfSdAFIJLOQUWZV<>^v"
CONST EDIT_UNDO = 40
DIM SHARED editMode AS INTEGER, editView AS INTEGER, editGlyph$, editDirty AS INTEGER, editRebuild AS INTEGER
DIM SHARED editUndo$(EDIT_UNDO), editUndoN AS INTEGER, editMsg$, editMsgUntil!, editLightP AS INTEGER, editLights AS INTEGER, editHeights AS INTEGER
' THE EDITOR'S OWN STATE, the same in both views (the map from above and
' the 3D view), so switching between them loses nothing:
'   ed hover...   the face under the cursor (kind, cell, side, part) - ED_ kinds
'   edSel...      the faces selected (up to ED_MAXSEL), kept until Ctrl+D
'   edTool        what a click does (ET_ tools); edBrush... what it places
'   edGrid...     the wireframe grid over the world, and how strong it is
'   edPick...     the picker panel: its tab and how far it's scrolled
CONST ED_WALL = 1, ED_FLOOR = 2, ED_CEIL = 3, ED_STEP = 4, ED_LINTEL = 5 ' (a face: a wall's side, a floor, a ceiling, the face of a step up, the face of a ceiling stepping down)
CONST ED_MAXSEL = 256
CONST ET_SELECT = 1, ET_PLACE = 2, ET_PAINT = 3, ET_LIGHT = 4, ET_HEIGHT = 5
DIM SHARED edHovKind AS INTEGER, edHovX AS INTEGER, edHovY AS INTEGER, edHovSide AS INTEGER, edHovPart AS INTEGER
DIM SHARED edHovPX, edHovPY, edHovPZ ' (exactly where the cursor's ray met it)
DIM SHARED edSelN AS INTEGER, edSelKind(ED_MAXSEL) AS INTEGER, edSelX(ED_MAXSEL) AS INTEGER, edSelY(ED_MAXSEL) AS INTEGER
DIM SHARED edSelSide(ED_MAXSEL) AS INTEGER, edSelPart(ED_MAXSEL) AS INTEGER
DIM SHARED edTool AS INTEGER, edGrid AS INTEGER, edGridAlpha AS INTEGER, edPickTab AS INTEGER, edPickScroll AS INTEGER
DIM SHARED edLooking AS INTEGER ' (the right button held in the 3D view: the mouse turns you instead of moving the cursor)
DIM SHARED edMouseFix AS INTEGER, edWheel AS INTEGER, edCurX AS INTEGER, edCurY AS INTEGER ' (put the pointer right again; the wheel's turns for the editor; where the pointer is)
DIM SHARED edCamPX, edCamPY, edCamDX, edCamDY, edCamPlane, edCamZoom ' (the camera, this frame: EditFP copies it here for the picking and outlines)
DIM SHARED edWheelT! ' (when the wheel last moved something: a run of turns is one undo)
DIM SHARED gridOn AS INTEGER, gridW AS INTEGER ' (the software renderer's grid this frame, and its lines' width in texels)
' THE TOOLBAR (EditTBLayout): its buttons this frame - which (TB_), where -
' the one under the pointer, the slider being dragged, the help panel
CONST TB_SELECT = 1, TB_PLACE = 2, TB_LIGHT = 3, TB_HEIGHT = 4, TB_DELETE = 5, TB_UNDO = 6, TB_SAVE = 7, TB_GRID = 8, TB_ALPHA = 9, TB_VIEW = 10, TB_HELP = 11, TB_PAINT = 12, TB_PICK = 13
DIM SHARED edTbN AS INTEGER, edTbId(16) AS INTEGER, edTbX(16) AS INTEGER, edTbY(16) AS INTEGER, edTbW(16) AS INTEGER, edTbH(16) AS INTEGER
DIM SHARED edTbDrag AS INTEGER, edHelp AS INTEGER
' THE PICKER (EditPkBuild): the tab's entries - each a kind (PK_), what it
' is (a map character, a picture's file name, a light's number) and its
' thumbnail, made once per tab (and again when the level or ART changes:
' edPkKey$) - the brush (what PLACE puts, PAINT paints), and whether the
' picker's up at all
CONST PK_GLYPH = 1, PK_TEX = 2, PK_LIGHT = 3
CONST PK_TABS = 9, PK_MAX = 160, PK_COLS = 8, PK_ROWS = 2, PK_SIZE = 50
CONST PK_X = 8, PK_Y = 438 ' (the picker's top left, in 3D: tabs, then the thumbnails under them)
DIM SHARED edPkN AS INTEGER, edPkKind(PK_MAX) AS INTEGER, edPkVal$(PK_MAX), edPkImg&(PK_MAX), edPkKey$
DIM SHARED edPickOn AS INTEGER, edBrushKind AS INTEGER, edBrushTex$, edBrushImg&
edPickOn = -1 : edBrushKind = PK_GLYPH
edTool = ET_SELECT : edGridAlpha = 120 : edPickTab = 1
DIM SHARED texFile$(T_SLOTS)
menuMusic& = LoadMusic&("menu.ogg")
FOR k = 1 TO NUM_LEVELS : levelMusic&(k) = LoadMusic&("level" + LTRIM$(STR$(k)) + ".ogg") : NEXT
cyberMusic& = LoadMusic&("cyber.flac") ' (the network's own)
sndMenuMove& = LoadSnd&("menu-move.wav") : sndMenuSelect& = LoadSnd&("menu-select.wav") : sndMenuBack& = LoadSnd&("menu-back.wav")
' The splash screen's picture, if there is one (neon-caster/splash.png)
DIM SHARED splashImg&
DIM savedCount AS INTEGER ' A count read back from a save (the same type as numItems, so GET reads 2 bytes)
' The level-done tally's rows (chapter 20): what each says, the number it
' counts up to, what that's out of (-1: a time, as m:ss), the number shown
' so far, and frames since it landed (-1: not yet)
DIM tallyLabel$(5), tallyTarget(5), tallyTotal(5), tallyShown(5), tallySlam(5)
IF _FILEEXISTS(AssetPath$("splash.png")) THEN splashImg& = _LOADIMAGE(AssetPath$("splash.png"), 32)

DIM x AS LONG, y AS LONG, texU AS LONG, texV AS LONG, texX AS LONG
DIM floorRow AS LONG, ceilRow AS LONG, drawStart AS LONG, drawEnd AS LONG
DIM cellX AS LONG, cellY AS LONG, lastCellX AS LONG, lastCellY AS LONG, floorSlot AS LONG, ceilSlot AS LONG
DIM cellFloor AS LONG, cellCeil AS LONG, splitCell AS LONG, cellTrack AS LONG
DIM savedHasGun(NUM_GUNS) ' What you had on entering the level (you get it back if you die)

' THE KICK (F, or Fire with no ammo - chapter 12): KICK_FRAMES long, the
' boot landing KICK_HIT frames in; reach KICK_REACH cells, KICK_DAMAGE
' damage, pushing a monster back KICK_PUSH cells
CONST KICK_FRAMES = 22, KICK_HIT = 8, KICK_REACH = 1.35, KICK_DAMAGE = 2, KICK_PUSH = 0.45
' How fast you go, in cells a frame: walking, and running (holding Shift)
CONST WALK_SPEED = 0.06, RUN_SPEED = 0.12 ' (walking: half as fast)
LoadSettings ' Your settings and keys, from neon-caster/saves/settings.ini
GOSUB ReadSectorNames
' The keyboard "device", for keys by where they are (KeyAt%, chapter 21):
' _DEVICES finds the devices; the first is the keyboard. Its key numbers
' are the system's: Windows uses the PC's scancodes, Linux adds 8 (macOS
' has its own - there we do without)
IF INSTR(_OS$, "[WINDOWS]") THEN keyScanAdd = 0 : keyDevice = -1
IF INSTR(_OS$, "[LINUX]") THEN keyScanAdd = 8 : keyDevice = -1
IF keyDevice THEN
    keyDevice = 0
    IF _DEVICES >= 1 THEN IF INSTR(_DEVICE$(1), "[KEYBOARD]") THEN keyDevice = -1
END IF
ApplySettings
GOSUB ArtReload ' Every picture, as ART asks (chapter 6's list: LoadPictures)
' Commands on the command line (chapter 21): each starts with a + -
'   neon-caster.run +map 5 +give all +wait 60 +screenshot five.png +quit
' They skip the splash and the title, start a new game and run, one a
' frame, from its first frame.
' (All the words, joined up again and cut at each " +" - so it works the
' same when a launcher hands them over as one long word.)
all$ = ""
FOR a = 1 TO _COMMANDCOUNT : all$ = all$ + " " + COMMAND$(a) : NEXT
DO WHILE LEN(all$)
    p = INSTR(all$, " +") : IF p = 0 THEN EXIT DO
    all$ = MID$(all$, p + 2) : q = INSTR(all$, " +")
    IF q THEN cmd$ = LEFT$(all$, q - 1) : all$ = MID$(all$, q) ELSE cmd$ = all$ : all$ = ""
    ConQueue cmd$
LOOP
IF conQTail > 0 THEN
    noSaveSettings = -1 : cliMode = -1
    GOSUB NewGame : _MOUSEHIDE : _MOUSEMOVE 400, 300
ELSE
    GOSUB ShowSplash
    menuInGame = 0 : GOSUB RunMenu ' The title menu: it returns once a game is started or loaded
END IF

'-----------------------------------------------------------------------------
' CHAPTER 7: THE GAME LOOP
'-----------------------------------------------------------------------------
' Everything from here to LOOP happens once a frame, 60 times a second
' (_LIMIT 60 waits as needed so it never goes faster). Each frame:
'
'   read the mouse and keys          chapter 8
'   Esc: open the menu (the game     chapter 21
'   waits until it closes)
'   move you, bump into walls        chapter 9
'   pickups, cheats, doors           chapters 10, 11
'   shoot                            chapter 12
'   move the monsters and bolts      chapter 13
'   draw the floor and ceiling       chapter 14
'   draw the walls                   chapter 15
'   draw the sprites                 chapter 16
'   put it on the screen, + the HUD  chapters 17, 18
'
' The window only changes at _DISPLAY, the last line of the loop. Until
' then we draw out of sight, so you never see a half-drawn frame. (Calling
' _DISPLAY once is what switches QB64PE into this mode.)
'
' Times are counted in frames, not seconds: a gun that waits 16 frames
' between shots fires about 4 times a second.
DO
    _LIMIT 60
    ' Commands waiting (the command line's, an exec's): one a frame - or
    ' as many as come before a "wait"
    SfxFrame : earDX = dirX : earDY = dirY ' (the limiter's memory fades; your ears face where you do)
    gridOn = editMode AND edGrid : gridW = MaxOf(1, texSize \ 64) ' (the editor's grid this frame: chapter 21)
    GOSUB SpeechFrame ' (NEXUS: what it says, when - chapter 19)
    IF conWait > 0 THEN conWait = conWait - 1
    DO WHILE conWait = 0 AND conQHead < conQTail AND glShotReq = 0 ' (a screenshot asked for: the rest waits until it's saved)
        conQHead = conQHead + 1 : conCmd$ = conQ$(conQHead) : GOSUB ConExec
    LOOP
    IF conQHead >= conQTail THEN conQHead = 0 : conQTail = 0
    ' ` (or ~): the console
    conKey = _KEYDOWN(96) OR _KEYDOWN(126)
    IF conKey AND NOT conKeyWas THEN GOSUB RunConsole
    conKeyWas = conKey
    ' F2: the level editor (chapter 21) - into it, at the map from above
    edKey = _KEYDOWN(15360)
    IF edKey AND NOT edKeyWas AND NOT cyberOn AND NOT dead THEN
        IF editMode THEN GOSUB EditLeave ELSE GOSUB EditEnter
    END IF
    edKeyWas = _KEYDOWN(15360)
    IF editMode AND editView = 0 THEN GOSUB RunEditor ' (the map from above: a loop of its own)
    IF editMode THEN GOSUB EditFP ' (walking round in it: its keys)

    '-------------------------------------------------------------------------
    ' CHAPTER 8: LOOKING AROUND
    '-------------------------------------------------------------------------
    ' Where you are and which way you face are two pairs of numbers:
    '
    '   (playerX, playerY)  your position on the map
    '   (dirX, dirY)        a direction one cell long, the way you face
    '   (planeX, planeY)    the "camera plane": a short line at right angles
    '                       to dirX, dirY. It's the screen, laid flat in the
    '                       world - its left end is the left edge of what
    '                       you see, its right end the right edge.
    '
    '              plane          The rays for the screen's columns go from
    '      <------------------>   you through points along the plane. Its
    '       \        |       /    length (fovPlane, 0.66 each side of
    '        \       | dir  /     dir) makes the view 66 degrees wide:
    '         \      |     /      a longer plane is a wider, fish-eye view.
    '          \     |    /
    '              you
    '
    ' Turning is rotating both pairs by the same small angle. The rotation
    ' formula for turning a point (x, y) by angle a is:
    '   newX = x * COS(a) - y * SIN(a)
    '   newY = x * SIN(a) + y * COS(a)
    ' (oldDirX keeps dirX's old value, since newY needs it after dirX changed.)
    ' The field of view is a setting (chapter 21): fovPlane is TAN of half
    ' the angle, which is how long the plane must be to see that wide.
    '
    ' The mouse: the pointer is captured (chapter 1), so we add up how far
    ' it moved since the last frame. QB64PE queues every mouse event;
    ' WHILE _MOUSEINPUT reads them all, one at a time, until the queue is
    ' empty. A click that starts and ends between two frames would be
    ' missed by just checking the button, so "clicked" remembers it.
    IF artWant <> artNow THEN GOSUB ArtReload ' (ART or the renderer changed: chapter 23)
    mouseDX = 0 : mouseDY = 0 : mouseWheel = 0
    WHILE _MOUSEINPUT
        mouseDX = mouseDX + _MOUSEMOVEMENTX : mouseDY = mouseDY + _MOUSEMOVEMENTY
        mouseWheel = mouseWheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1
        IF _MOUSEBUTTON(1) AND NOT edQ1 THEN edClickL = -1 ' (edClick: the editor's own - a press, not a button held while the mouse moves - kept until it looks: EditFP)
        IF _MOUSEBUTTON(2) AND NOT edQ2 THEN edClickR = -1
        edQ1 = _MOUSEBUTTON(1) : edQ2 = _MOUSEBUTTON(2)
    WEND
    ' The 3D editor: the mouse is a pointer, free to point at anything (the
    ' face under it is picked - EditPick). Hold the right button to look
    ' round instead: the pointer is captured while you do (chapter 1). The
    ' wheel is the editor's (EditFP), not for changing guns.
    IF editMode AND editView = 1 AND NOT hudEdit THEN
        lookNow = _MOUSEBUTTON(2)
        IF lookNow <> edLooking OR edMouseFix THEN
            IF lookNow THEN _MOUSEHIDE _DISABLE ELSE _MOUSESHOW
            edLooking = lookNow : edMouseFix = 0
        END IF
        IF NOT edLooking THEN mouseDX = 0 : mouseDY = 0
        edWheel = edWheel + mouseWheel : mouseWheel = 0
        edCurX = WideMouseX(_MOUSEX) : edCurY = _MOUSEY
    END IF
    ' Keys go through the key bindings (chapter 21): KeyHeld(BIND_FIRE) asks
    ' "is the key you chose for firing held down?" - left Ctrl, unless you
    ' changed it in the menu.
    IF hudEdit THEN GOSUB HudEditFrame : mouseDX = 0 : mouseDY = 0 : clicked = 0 ' (the HUD layout editor has the mouse - chapter 21)
    fireDown = _MOUSEBUTTON(1) OR clicked OR KeyHeld(BIND_FIRE)
    IF hudEdit THEN fireDown = 0
    IF conFire > 0 THEN conFire = conFire - 1 : fireDown = -1 ' (the console's fire: holding the trigger)
    clicked = 0
    spaceDown = KeyHeld(BIND_USE) AND NOT editMode ' (in the editor Space flies you up)
    IF conUse THEN conUse = 0 : spaceDown = -1 ' (the console's use: Space, once)

    ' Esc opens the menu (chapter 21), and the game waits while it's open
    escDown = _KEYDOWN(27) AND NOT hudEdit
    IF escDown AND NOT escWas THEN
        menuInGame = -1 : GOSUB RunMenu : edMouseFix = -1 ' (the menu captured the mouse: the editor's pointer back)
        mouseDX = 0 : mouseDY = 0 : mouseWheel = 0 : clicked = 0 : fireDown = 0 : spaceDown = 0
        fireWait = 15 ' (so the click that closed the menu doesn't fire)
    END IF
    escWas = _KEYDOWN(27)

    IF dead THEN
        ' Dead: the view stays put; click or Space (after a moment) starts over
        IF TIMER - deadAt! > 1.2 AND ((fireDown AND NOT fireWas) OR (spaceDown AND NOT spaceWas)) THEN GOSUB RestartLevel
        mouseDX = 0 : mouseDY = 0 : mouseWheel = 0
    END IF

    ' Aiming down the sights: hold the right mouse button (_MOUSEBUTTON(2)).
    ' aimAmount slides from 0 (hip) to 1 (aimed) over ADS_FRAMES frames, so
    ' the zoom and the gun ease in and out instead of snapping.
    IF _MOUSEBUTTON(2) AND NOT dead AND NOT hudEdit AND NOT editMode THEN aimTarget = 1 ELSE aimTarget = 0
    IF swapTimer > 0 THEN aimTarget = 0 ' Changing guns: lower it (no jump in zoom)
    IF aimAmount < aimTarget THEN aimAmount = aimAmount + 1 / ADS_FRAMES : IF aimAmount > 1 THEN aimAmount = 1
    IF aimAmount > aimTarget THEN aimAmount = aimAmount - 1 / ADS_FRAMES : IF aimAmount < 0 THEN aimAmount = 0
    zoom = 1 + (gunZoom(currentGun) - 1) * aimAmount ' (each gun zooms its own amount)

    mouseDX = mouseDX / DisplayScale! ' The same turn speed in a window or full screen
    ' (slower when zoomed, so aiming stays steady - and slower still the
    ' more you're aiming, by AIM SENSITIVITY)
    aimSlow = 1 - aimAmount * (1 - setting(SET_AIMSENS) / 100)
    turn = - mouseDX * turnSpeed / zoom * aimSlow
    oldDirX = dirX : dirX = dirX * COS(turn) - dirY * SIN(turn) : dirY = oldDirX * SIN(turn) + dirY * COS(turn)
    oldPlaneX = planeX : planeX = planeX * COS(turn) - planeY * SIN(turn) : planeY = oldPlaneX * SIN(turn) + planeY * COS(turn)

    ' Looking up and down - only with OpenGL (chapter 24), which can tilt
    ' its camera; the raycaster's world has no up or down to look at
    ' (LOOK UP / DOWN in SETTINGS > VIDEO). Moving the mouse forward looks
    ' up, as far as 0.6 radians (about 34 degrees) each way. Shots still go
    ' straight ahead: like Doom, whatever's in the middle column is hit,
    ' high or low. Otherwise the view eases back to level.
    IF glMode AND setting(SET_LOOK) AND NOT dead THEN
        pitch = pitch - mouseDY / DisplayScale! * turnSpeed / zoom * aimSlow
        IF pitch > 0.6 THEN pitch = 0.6
        IF pitch < -0.6 THEN pitch = -0.6
    ELSE
        pitch = pitch * 0.8
    END IF

    ' Zooming. The camera plane's length sets how wide the view is, so a
    ' shorter plane (fovPlane / zoom) is a narrower view - and a narrower
    ' view stretched across the same screen is a zoom. The plane is always
    ' your direction turned 90 degrees, so we can simply rebuild it from
    ' dirX, dirY at the new length (it's the same direction the rotation
    ' above gave it). Everything must also get taller by the same amount, or
    ' the picture would only stretch sideways: viewH is how many pixels tall
    ' a wall one cell away is drawn, and the floor, walls and sprites
    ' (chapters 14-16) all use it.
    planeX = dirY * fovPlane / zoom : planeY = - dirX * fovPlane / zoom
    viewH = RENDER_H * zoom

    ' Guns: 1 / 2 / 3 / 4, or the mouse wheel through the ones you have.
    ' Swapping takes SWAP_FRAMES: the gun dips out of sight, changes at the
    ' halfway point, and comes back up (the drawing is in chapter 18).
    wantGun = 0
    IF DigitHeld%(49) THEN wantGun = 1 ' (by place: Shift + 1 types "!", and you might be running)
    IF DigitHeld%(50) THEN wantGun = 2
    IF DigitHeld%(51) THEN wantGun = 3
    IF DigitHeld%(52) THEN wantGun = 4
    IF mouseWheel <> 0 THEN
        wantGun = currentGun
        DO
            wantGun = wantGun + SGN(mouseWheel) : IF wantGun > NUM_GUNS THEN wantGun = 1
            IF wantGun < 1 THEN wantGun = NUM_GUNS
        LOOP UNTIL hasGun(wantGun)
    END IF
    IF wantGun > 0 AND wantGun <> currentGun AND swapTimer = 0 THEN
        IF hasGun(wantGun) THEN nextGun = wantGun : swapTimer = SWAP_FRAMES
    END IF
    IF swapTimer > 0 THEN
        swapTimer = swapTimer - 1
        IF swapTimer = SWAP_FRAMES \ 2 THEN currentGun = nextGun ' (while it's out of sight)
    END IF

    IF numLifts THEN MoveLifts playerX, playerY ' (the lifts move - you ride them: chapter 22)

    '-------------------------------------------------------------------------
    ' CHAPTER 9: MOVING, AND BUMPING INTO THINGS
    '-------------------------------------------------------------------------
    ' W and S move you along (dirX, dirY); A and D move you sideways, along
    ' (dirY, -dirX) - your direction turned 90 degrees. Pressing W and D
    ' together adds the two, which would be about 1.4 times as fast, so the
    ' sum is "normalized": divided by its own length (moveLen) to make it one
    ' cell long, then scaled to your speed - walking, or running while you
    ' hold Shift. Now every direction is the same speed, and opposite keys
    ' simply cancel out.
    forward = 0 : strafe = 0
    IF NOT dead THEN
        IF KeyHeld(BIND_FORWARD) THEN forward = forward + 1 ' W, unless rebound
        IF KeyHeld(BIND_BACK) THEN forward = forward - 1 ' S
        IF KeyHeld(BIND_LEFT) THEN strafe = strafe - 1 ' A (strafe left)
        IF KeyHeld(BIND_RIGHT) THEN strafe = strafe + 1 ' D (strafe right)
    END IF
    moveX = dirX * forward + dirY * strafe : moveY = dirY * forward - dirX * strafe
    moveLen = SQR(moveX * moveX + moveY * moveY)
    moveSpeed = WALK_SPEED : IF KeyHeld(BIND_RUN) THEN moveSpeed = RUN_SPEED ' (Shift: run)
    IF FloorHazard(INT(playerX), INT(playerY)) = HAZ_WADE THEN IF playerZ - floorH(INT(playerX), INT(playerY)) < 0.05 THEN moveSpeed = moveSpeed * SLOW_WADE ' (wading)
    IF moveLen > 0 THEN
        moveX = moveX / moveLen * moveSpeed : moveY = moveY / moveLen * moveSpeed
    END IF

    ' Collision. You're a square, PLAYER_RADIUS from your middle to each
    ' side, so the camera can never get right up against a wall (it would
    ' fill the screen with one blurry texel). MoveBody (chapter 23) tries the
    ' X part of the move and the Y part separately: walk into a wall at an
    ' angle and the blocked part stops, while the other part carries on -
    ' so you slide along the wall instead of sticking to it. Monsters move
    ' with MoveBody too.
    prevX = playerX : prevY = playerY
    IF godMode OR editMode THEN ' No clipping (god mode, or the editor): straight through anything, but stay inside the border
        playerX = playerX + moveX : playerY = playerY + moveY
        IF playerX < 1.01 THEN playerX = 1.01
        IF playerX > MAP_SIZE - 1.01 THEN playerX = MAP_SIZE - 1.01
        IF playerY < 1.01 THEN playerY = 1.01
        IF playerY > MAP_SIZE - 1.01 THEN playerY = MAP_SIZE - 1.01
    ELSE
        walkZ = playerZ : MoveBody playerX, playerY, moveX, moveY : walkZ = -999
    END IF
    ' Up and down (chapter 22's heights): step up onto anything low enough
    ' (MoveBody wouldn't have let you onto anything higher), fall off
    ' anything higher - faster and faster - and land, hard if it was far;
    ' fall into a pit and that's the end. Your eye eases up a step.
    IF editMode THEN ' The editor: you fly - Space up, C down (Shift faster) - no falling, nothing to stand on
        flySpeed = 0.04 : IF KeyHeld(BIND_RUN) THEN flySpeed = 0.1
        IF _KEYDOWN(32) THEN playerZ = playerZ + flySpeed
        IF _KEYDOWN(99) OR _KEYDOWN(67) THEN playerZ = playerZ - flySpeed
        IF playerZ < -1.4 THEN playerZ = -1.4
        IF playerZ > 4.5 THEN playerZ = 4.5
        playerVZ = 0
    ELSEIF NOT levelFlat THEN
        fz = floorH(INT(playerX), INT(playerY))
        IF playerZ < fz THEN playerZ = fz : playerVZ = 0
        IF liftCell(INT(playerX), INT(playerY)) AND playerZ - fz < 0.06 AND playerVZ < 0.03 THEN playerZ = fz : playerVZ = 0 ' (riding a lift down)
        IF playerZ > fz THEN
            playerVZ = playerVZ + FALL_G : playerZ = playerZ - playerVZ
            IF playerZ <= fz THEN
                IF playerVZ > 0.13 AND NOT dead AND NOT godMode THEN damage = INT((playerVZ - 0.13) * 260) + 2 : hurtFromX = -1 : hurtFromY = -1 : GOSUB HurtPlayer : shake = shake + 6
                IF playerVZ > 0.06 THEN PlaySfx sndStep1&, 1 : shake = shake + 2
                playerZ = fz : playerVZ = 0
            END IF
        END IF
        IF fz <= PIT_DEPTH AND playerZ < -0.6 AND NOT dead AND NOT godMode THEN damage = 999 : hurtFromX = -1 : hurtFromY = -1 : GOSUB HurtPlayer : ShowMsg "You fell into the dark"
    END IF
    ' A burning floor (molten metal, lava): it hurts while you stand in it
    IF burnWait > 0 THEN burnWait = burnWait - 1
    IF FloorHazard(INT(playerX), INT(playerY)) = HAZ_BURN AND playerZ - floorH(INT(playerX), INT(playerY)) < 0.05 AND NOT dead THEN
        IF burnWait = 0 THEN
            burnWait = BURN_EVERY : PlaySfx sndSizzle&, 0.9
            SpawnSparks playerX + dirX * 0.3, playerY + dirY * 0.3, floorH(INT(playerX), INT(playerY)) + 0.05, 12, 255, 120, 30
            IF NOT godMode THEN damage = BURN_DAMAGE : hurtFromX = -1 : hurtFromY = -1 : GOSUB HurtPlayer
        END IF
    END IF
    IF levelFlat AND NOT editMode THEN playerZ = 0 : playerVZ = 0
    IF editMode OR playerVZ > 0 OR ABS(eyeZ - (playerZ + EYE_H)) < 0.01 THEN eyeZ = playerZ + EYE_H ELSE eyeZ = eyeZ + (playerZ + EYE_H - eyeZ) * 0.3
    ' ...and you can't walk through a monster: if a step takes you inside one
    ' (closer than touchDist) and closer than you were, take it back
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 2 AND NOT godMode AND NOT editMode THEN
            touchDist = 0.3 + mtypeScale(monsterType(i)) * 0.35
            newDistSq = (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2
            IF newDistSq < touchDist * touchDist AND newDistSq <(monsterX(i) - prevX) ^ 2 + (monsterY(i) -prevY) ^ 2 THEN playerX = prevX : playerY = prevY
        END IF
    NEXT

    ' Footsteps and the gun's bob keep one clock, bobPhase. It moves on by
    ' 2 pi for each stride actually walked (so walking into a wall makes
    ' no footsteps), the gun dips once each 2 pi (chapter 18), and a foot
    ' lands, alternately, at the bottom of each dip - when bobPhase passes
    ' an odd multiple of pi. A stride is STEP_WALK cells walking and up to
    ' STEP_RUN running: you run with longer strides, not just quicker ones.
    moved = SQR((playerX - prevX) ^ 2 + (playerY - prevY) ^ 2)
    IF moved > 0 THEN
        stride = STEP_WALK + (STEP_RUN - STEP_WALK) * MaxOf(0, MinOf(1, (moveSpeed - WALK_SPEED) / (RUN_SPEED - WALK_SPEED)))
        beatWas = INT((bobPhase - 3.14159265) / 6.2831853)
        bobPhase = bobPhase + 6.2831853 * moved / stride
        IF INT((bobPhase - 3.14159265) / 6.2831853) <> beatWas THEN
            stepFoot = 1 - stepFoot
            IF stepFoot THEN PlaySfx sndStep1&, 0.35 ELSE PlaySfx sndStep2&, 0.35
        END IF
    END IF

    ' Bump: once when you push firmly into a wall (not when sliding along one)
    pushing = 0
    IF playerX = prevX AND ABS(moveX) > moveSpeed * 0.5 THEN pushing = -1
    IF playerY = prevY AND ABS(moveY) > moveSpeed * 0.5 THEN pushing = -1
    IF pushing AND NOT wasPushing THEN PlaySfx sndBump&, 0.8
    wasPushing = pushing

    '-------------------------------------------------------------------------
    ' CHAPTER 10: PICKUPS AND CHEAT KEYS
    '-------------------------------------------------------------------------
    ' A pickup is taken when you're within 0.45 cells of it. Comparing the
    ' squared distance with 0.45 squared gives the same answer as comparing
    ' distances, and skips a slow SQR - a trick used all through the game.
    ' Things you can't use yet (health when you're full) stay where they are.
    FOR i = 1 TO numItems
        IF itemOn(i) AND NOT dead AND NOT editMode AND (itemKind(i) = IT_CORE) = cyberOn AND (itemX(i) - playerX) ^ 2 + (itemY(i) -playerY) ^ 2 < 0.45 * 0.45 THEN
            SELECT CASE itemKind(i)
                CASE IT_CORE ' A data core (the network)
                    itemOn(i) = 0 : cyberGot = cyberGot + 1 : PlaySfx sndCore&, 1 : pickFlash = 12
                    IF cyberGot < cyberNeed THEN ShowMsg "DATA CORE " + LTRIM$(STR$(cyberGot)) + " / " + LTRIM$(STR$(cyberNeed))
                CASE 1 TO 3
                    itemOn(i) = 0 : hasCard(itemKind(i)) = -1
                    PlaySfx sndCard&, 0.8
                    ShowMsg "Picked up the " + CardName$(itemKind(i)) + " keycard"
                CASE IT_HEALTH
                    IF health < MAX_HP THEN
                        itemOn(i) = 0 : health = health + 25 : IF health > MAX_HP THEN health = MAX_HP
                        PlaySfx sndHealth&, 0.8 : ShowMsg "Health pack (+25)" : pickFlash = 10
                    END IF
                CASE IT_MAP
                    itemOn(i) = 0 : hasMap = -1
                    PlaySfx sndCard&, 0.8 : ShowMsg "You found the map!  (TAB for the full map)" : pickFlash = 10
                CASE IT_BIGMED
                    IF health < MAX_HP THEN
                        itemOn(i) = 0 : health = health + 50 : IF health > MAX_HP THEN health = MAX_HP
                        PlaySfx sndHealth&, 0.9 : ShowMsg "Big medkit (+50)" : pickFlash = 14
                    END IF
                CASE IT_OVERCHARGE ' Health past full, up to MAX_OVER
                    IF health < MAX_OVER THEN
                        itemOn(i) = 0 : health = health + 100 : IF health > MAX_OVER THEN health = MAX_OVER
                        PlaySfx sndOvercharge&, 0.9 : ShowMsg "OVERCHARGE! (+100)" : pickFlash = 18
                    END IF
                CASE IT_AMP ' Double damage for a while
                    itemOn(i) = 0 : ampTimer = AMP_FRAMES
                    PlaySfx sndAmp&, 0.9 : ShowMsg "DAMAGE AMP! Double damage for 30 seconds" : pickFlash = 18
                CASE IT_ARMOR
                    IF armor < MAX_ARMOR THEN
                        itemOn(i) = 0 : armor = armor + 50 : IF armor > MAX_ARMOR THEN armor = MAX_ARMOR
                        PlaySfx sndArmor&, 0.8 : ShowMsg "Armour (+50)" : pickFlash = 10
                    END IF
                CASE IT_CELLS
                    IF GiveAmmo%(AM_CELLS, 15) THEN itemOn(i) = 0 : PlaySfx sndAmmo&, 0.8 : ShowMsg "Energy cells (+15)" : pickFlash = 10
                CASE IT_SHELLS
                    IF GiveAmmo%(AM_SHELLS, 8) THEN itemOn(i) = 0 : PlaySfx sndShells&, 0.8 : ShowMsg "Shells (+8)" : pickFlash = 10
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL
                    IF itemKind(i) = IT_RAIL THEN gun = W_RAIL ELSE gun = itemKind(i) - IT_SCATTER + W_SCATTER
                    IF gun = W_SCATTER THEN taken = GiveAmmo%(AM_SHELLS, 8) ELSE taken = GiveAmmo%(AM_CELLS, 30)
                    IF NOT hasGun(gun) OR taken THEN
                        itemOn(i) = 0 : PlaySfx sndWeapon&, 0.9 : pickFlash = 10
                        IF NOT hasGun(gun) THEN
                            hasGun(gun) = -1 : nextGun = gun : swapTimer = SWAP_FRAMES
                            ShowMsg "You got the " + gunName$(gun) + "!  (" + LTRIM$(STR$(gun)) + " or mouse wheel to switch)"
                        ELSE
                            ShowMsg gunName$(gun) + " ammo"
                        END IF
                    END IF
            END SELECT
        END IF
    NEXT

    ' The cheat keys act once per press, not every frame the key is held.
    ' That's "edge detection": remember last frame's state (kKeyWas) and act
    ' only when the key is down now and wasn't then. Space and the fire
    ' button use the same trick.
    ' K: every keycard (testing)
    kKeyDown = _KEYDOWN(107) OR _KEYDOWN(75)
    IF CHEAT_KEYS AND kKeyDown AND NOT kKeyWas AND NOT dead AND NOT editMode THEN
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT
        hasMap = -1
        PlaySfx sndCard&, 0.8 : ShowMsg "All keycards, and the map"
    END IF
    kKeyWas = kKeyDown
    ' G: god mode on / off - no damage, and you walk through walls (testing)
    gKeyDown = _KEYDOWN(103) OR _KEYDOWN(71)
    IF CHEAT_KEYS AND gKeyDown AND NOT gKeyWas AND NOT dead AND NOT editMode THEN
        godMode = NOT godMode
        IF godMode THEN ShowMsg "God mode ON - no damage, no clipping" ELSE ShowMsg "God mode OFF"
        PlaySfx sndCard&, 0.8
    END IF
    gKeyWas = gKeyDown
    ' Quick save and quick load (F5 and F9 unless you rebind them -
    ' chapter 21): the same saving and loading as the menu, in the
    ' "quick" slot
    qsDown = KeyHeld(BIND_QUICKSAVE)
    IF qsDown AND NOT qsWas AND NOT dead THEN saveSlot = 0 : GOSUB SaveGame
    qsWas = qsDown
    qlDown = KeyHeld(BIND_QUICKLOAD)
    IF qlDown AND NOT qlWas THEN saveSlot = 0 : GOSUB LoadGame
    qlWas = qlDown
    ' Tab: the full-screen map on or off (drawn in chapter 18). In the
    ' editor Tab is its own (the map from above / walking round), and the
    ' editor reads it first - so it mustn't open this map as well.
    mapKeyDown = KeyHeld(BIND_MAP)
    IF mapKeyDown AND NOT mapKeyWas AND NOT editMode THEN mapOpen = NOT mapOpen
    mapKeyWas = mapKeyDown

    '-------------------------------------------------------------------------
    ' CHAPTER 11: DOORS
    '-------------------------------------------------------------------------
    ' Space opens the door in front of you - or shuts it, if it's open. To
    ' find it, we take small steps (0.05 cells) out from you along (dirX,
    ' dirY), up to 2 cells, and look at the cell each step lands in: the
    ' first door is the one (not one you're standing in), and a wall first
    ' means there's nothing to open. The exit door is a door that never
    ' opens - Space on it ends the level (chapter 20).
    '
    ' A door's doorOpen() goes from 0 (shut) to 1 (open), and doorMove()
    ' says which way it's going: Space sets it going, and the loop below
    ' moves it a little every frame. The wall drawing (chapter 15) uses the
    ' number to slide the door aside, raise the shutter, or part the split
    ' door's halves. An open door waits a while (doorWait, DoorHold frames:
    ' each kind its own), then shuts itself - but never on anyone: with you
    ' or a monster in the doorway (DoorBlocked), it waits, or if it was
    ' already shutting, opens again, like an automatic door.
    IF spaceDown AND NOT spaceWas AND NOT dead AND NOT editMode THEN ' A "use" trigger at the cell in front? (chapter 19)
        FOR k = 1 TO numTrigs
            IF trigWhen$(k) = "use" AND NOT trigDone(k) THEN
                FOR reach = 0.3 TO 1.6 STEP 0.1
                    IF INT(playerX + dirX * reach) = trigX0(k) AND INT(playerY + dirY * reach) = trigY0(k) THEN trigRun$ = trigCmd$(k) : trigDone(k) = NOT trigRepeat(k) : PlaySfx sndCore&, 0.6 : GOSUB TriggerRun : EXIT FOR
                NEXT
            END IF
        NEXT
    END IF
    IF spaceDown AND NOT spaceWas AND NOT dead THEN ' (once per press)
        FOR reach = 0.05 TO 2 STEP 0.05
            cellX = INT(playerX + dirX * reach) : cellY = INT(playerY + dirY * reach)
            IF cellX = INT(playerX) AND cellY = INT(playerY) THEN GOTO NextReach ' (the doorway you're in)
            IF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) = 0 AND doorLock(cellX, cellY) THEN
                PlaySfx sndLocked&, 0.8
                IF doorLock(cellX, cellY) = 2 THEN ShowMsg "SEALED - hack its data station to open it" ELSE IF doorLock(cellX, cellY) = 3 THEN ShowMsg "LOCKED DOWN - repair the terminal's program" ELSE ShowMsg "SEALED - it won't open until the room is clear"
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) = 0 THEN
                keyNeeded = doorKey(cellX, cellY)
                IF doorType(cellX, cellY) = DOOR_EXIT THEN
                    GOSUB LevelDone
                ELSEIF keyNeeded = 0 OR hasCard(keyNeeded) THEN
                    doorOpen(cellX, cellY) = 0.01 : doorMove(cellX, cellY) = 1
                    PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                ELSE
                    PlaySfx sndLocked&, 0.8
                    ShowMsg "Locked - you need the " + CardName$(keyNeeded) + " keycard"
                END IF
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 AND doorLock(cellX, cellY) THEN
                PlaySfx sndLocked&, 0.8 : ShowMsg "SEALED - it won't open until the room is clear"
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 THEN ' Open (or on the move): shut it - or open it again
                IF doorMove(cellX, cellY) = -1 THEN
                    doorMove(cellX, cellY) = 1 : PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                ELSEIF NOT DoorBlocked(cellX, cellY, playerX, playerY) THEN
                    doorMove(cellX, cellY) = -1 : PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                END IF
                EXIT FOR
            END IF
            IF worldMap(cellX, cellY) = 9 THEN ' A code terminal: its puzzle
                tm = TermAt(cellX, cellY)
                IF termDone(tm) THEN
                    ShowMsg "TERMINAL: program running - ACCESS GRANTED"
                ELSE
                    GOSUB TerminalUse
                END IF
                EXIT FOR
            END IF
            IF worldMap(cellX, cellY) = 8 THEN ' A data station: jack in
                st = StationAt(cellX, cellY)
                IF stationDone(st) THEN
                    ShowMsg "This station's hacked - its doors are open"
                ELSEIF NOT cyberOn THEN
                    GOSUB JackIn
                END IF
                EXIT FOR
            END IF
            IF SolidAt(playerX + dirX * reach, playerY + dirY * reach) THEN
                IF reach <= 1.2 THEN PlaySfx sndHump&, 0.8 ' Trying to open a plain wall
                EXIT FOR
            END IF
            NextReach:
        NEXT
    END IF
    FOR doorY = 0 TO MAP_SIZE - 1 : FOR doorX = 0 TO MAP_SIZE-1
        ' (a locked door that's open shuts - as soon as nobody's in the way)
        IF doorLock(doorX, doorY) AND doorOpen(doorX, doorY) > 0 AND doorMove(doorX, doorY) <> -1 THEN
            IF NOT DoorBlocked(doorX, doorY, playerX, playerY) THEN doorMove(doorX, doorY) = -1 : doorWait(doorX, doorY) = 0
        END IF
        IF worldMap(doorX, doorY) = 2 AND doorOpen(doorX, doorY) > 0 THEN
            ' (a door part-open with nowhere to go - from an old saved game - opens)
            IF doorMove(doorX, doorY) = 0 AND doorOpen(doorX, doorY) < 1 THEN doorMove(doorX, doorY) = 1
            SELECT CASE doorMove(doorX, doorY)
                CASE 1 ' Opening
                    doorOpen(doorX, doorY) = doorOpen(doorX, doorY) + DoorSpeed(doorType(doorX, doorY))
                    IF doorOpen(doorX, doorY) >= 1 THEN
                        doorOpen(doorX, doorY) = 1 : doorMove(doorX, doorY) = 0 : doorWait(doorX, doorY) = DoorHold(doorType(doorX, doorY))
                    END IF
                CASE -1 ' Shutting - unless someone's in the way: then it opens again
                    IF DoorBlocked(doorX, doorY, playerX, playerY) THEN
                        doorMove(doorX, doorY) = 1
                    ELSE
                        doorOpen(doorX, doorY) = doorOpen(doorX, doorY) - DoorSpeed(doorType(doorX, doorY))
                        IF doorOpen(doorX, doorY) <= 0 THEN doorOpen(doorX, doorY) = 0 : doorMove(doorX, doorY) = 0
                    END IF
                CASE ELSE ' Open, waiting - then shutting itself, when the doorway's clear
                    IF doorWait(doorX, doorY) > 0 THEN
                        doorWait(doorX, doorY) = doorWait(doorX, doorY) - 1
                    ELSEIF NOT DoorBlocked(doorX, doorY, playerX, playerY) THEN
                        doorMove(doorX, doorY) = -1
                        far = SQR((doorX + 0.5 - playerX) ^ 2 + (doorY + 0.5 - playerY) ^ 2) ' (quieter further off)
                        IF far < 14 THEN PlaySfx DoorSnd&(doorType(doorX, doorY)), 0.9 * (1 - far / 14)
                    ELSE
                        doorWait(doorX, doorY) = 30 ' (someone's in it: look again in half a second)
                    END IF
            END SELECT
        END IF
    NEXT : NEXT

    '-------------------------------------------------------------------------
    ' CHAPTER 12: SHOOTING
    '-------------------------------------------------------------------------
    ' Shots are "hitscan": they hit instantly, nothing flies. A shot goes
    ' straight out through one column of the screen - the middle one, or a
    ' little to the side for a scatter gun's pellets (aim, from -1 at the
    ' left edge to 1 at the right). What does it hit?
    '
    ' For each monster we work out where it is on screen, exactly as
    ' chapter 16 does to draw it: transformY is how far in front of you it
    ' is, and transformX / transformY says how far across the screen. If
    ' the shot's column passes through the monster's sprite, it's in the
    ' line of fire. The nearest one wins - unless the wall in that column is
    ' nearer still. zBuffer() still holds each column's wall distance from
    ' drawing the last frame (chapter 15), so that's a free answer to "is
    ' there a wall in the way?"
    '
    ' Decorations can be hit the same way: a barrel blows up (chapter 13),
    ' anything else takes damage and breaks (HitDeco, chapter 19). The
    ' railgun's shot doesn't stop at the first thing: it hits everything in
    ' its line that's nearer than the wall.
    '
    ' Hold the button to keep firing: fireWait counts down the frames until
    ' the gun can fire again.
    IF fireWait > 0 THEN fireWait = fireWait - 1
    IF editMode THEN fireDown = 0 ' (in the editor the button builds, not shoots: EditFP)
    IF fireDown AND NOT dead AND fireWait = 0 AND swapTimer = 0 THEN
        ammoType = gunAmmoType(currentGun)
        IF ammoCount(ammoType) >= gunAmmoPerShot(currentGun) THEN
            ammoCount(ammoType) = ammoCount(ammoType) - gunAmmoPerShot(currentGun) : fireWait = gunDelay(currentGun) : recoil = gunKick(currentGun) : muzzleFlash = 4
            PlaySfx gunSnd&(currentGun), 0.7
            StirDust playerX, playerY, dirX, dirY, 5, 0.02 * gunKick(currentGun) ' (the shot's wind blows the dust along - chapter 24)
            hitDamage = gunDamage(currentGun) : IF gunPierce(currentGun) THEN railBeam = 8
            IF ampTimer > 0 THEN hitDamage = hitDamage * 2 ' (the damage amp: double)
            shake = shake + gunKick(currentGun) * 1.5 ' (a big gun shakes the screen - chapter 17)
            IF setting(SET_XFEEDBACK) THEN crossScale = 0.6 ' The crosshair tightens as you fire
            invDet = 1 /(planeX * dirY - dirX * planeY)
            FOR pellet = 1 TO gunPellets(currentGun)
                aim = (RND * 2 - 1) * gunSpread(currentGun) ' Across the view: -1 left edge .. 1 right
                IF gunPellets(currentGun) > 1 THEN aim = ((pellet - 1) /(gunPellets(currentGun) -1) * 2 - 1) * gunSpread(currentGun) + (RND - 0.5) * 0.02
                screenCol = INT(RENDER_W / 2 * (1 + aim)) : IF screenCol < 0 THEN screenCol = 0
                IF screenCol > RENDER_W - 1 THEN screenCol = RENDER_W-1
                ' (a piercing shot hits everything in its line that's nearer than
                ' the wall; any other shot just the nearest monster or decoration)
                bestMonster = 0 : bestDeco = 0 : bestDist = zBuffer(screenCol)
                ' Glass nearer than the wall stops the shot (but the rail goes
                ' straight through it, and shatters it)
                glassShot = 0
                IF glassT(screenCol) > 0 AND glassT(screenCol) < bestDist THEN
                    glassHitX = glassCX(screenCol) : glassHitY = glassCY(screenCol)
                    glassAtX = playerX + (dirX + planeX * aim) * glassT(screenCol) : glassAtY = playerY + (dirY + planeY * aim) * glassT(screenCol)
                    IF gunPierce(currentGun) THEN glassDmg = 99 : GOSUB HitGlass ELSE bestDist = glassT(screenCol) : glassShot = -1
                END IF
                FOR i = 1 TO numMonsters
                    IF monsterState(i) < 2 AND (cyberOn = 0 OR monsterType(i) = MT_ICE) THEN
                        relX = monsterX(i) - playerX : relY = monsterY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < viewH / transformY * mtypeScale(monsterType(i)) * 0.3 THEN
                                IF gunPierce(currentGun) THEN target = i : GOSUB HitMonster : crossFlash = 6 ELSE bestMonster = i : bestDist = transformY
                            END IF
                        END IF
                    END IF
                NEXT
                FOR i = 1 TO numDecos
                    IF decoOn(i) AND decoKind(i) <> DK_BODY AND cyberOn = 0 THEN
                        relX = decoX(i) - playerX : relY = decoY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < viewH / transformY * DecoScale(decoKind(i)) * 0.35 THEN
                                IF gunPierce(currentGun) THEN
                                    targetDeco = i : GOSUB HitDeco
                                ELSE
                                    bestDeco = i : bestMonster = 0 : bestDist = transformY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                IF bestMonster THEN target = bestMonster : GOSUB HitMonster : crossFlash = 6 ' (the crosshair flashes: a hit)
                IF bestDeco THEN targetDeco = bestDeco : GOSUB HitDeco
                ' Sparks where it landed (chapter 24's particles): on the
                ' monster, or on the wall - the shot's ray (dir + plane * aim),
                ' as far as the wall in that column
                IF bestMonster THEN
                    SpawnSparks monsterX(bestMonster), monsterY(bestMonster), 0.45, 8, 255, 150, 60
                ELSEIF bestDeco = 0 AND glassShot THEN
                    glassDmg = hitDamage : GOSUB HitGlass
                ELSEIF bestDeco = 0 THEN
                    ' The wall in that column - or, looking up or down (OpenGL),
                    ' the ceiling or floor, if the shot reaches it first: it rises
                    ' TAN(pitch) for each cell it goes (the ray's length, rayLen,
                    ' as its steps are a little longer than a cell off-centre)
                    rayX = dirX + planeX * aim : rayY = dirY + planeY * aim : rayLen = SQR(rayX * rayX + rayY * rayY)
                    hitDist = zBuffer(screenCol) : surface = 0 : rise = TAN(pitch) * rayLen
                    IF rise > 0.01 THEN IF 0.5 / rise < hitDist THEN hitDist = 0.5 / rise : surface = 1 ' (the ceiling)
                    IF rise < -0.01 THEN IF 0.5 / -rise < hitDist THEN hitDist = 0.5 / -rise : surface = 2 ' (the floor)
                    hitX = playerX + rayX * hitDist : hitY = playerY + rayY * hitDist : hitZ = 0.5 + rise * hitDist
                    IF hitZ < 0.03 THEN hitZ = 0.03
                    IF hitZ > 0.97 THEN hitZ = 0.97
                    SELECT CASE currentGun
                        CASE W_BLASTER : sparkN = 6 : sparkR = 255 : sparkG = 70 : sparkB = 120
                        CASE W_SCATTER : sparkN = 3 : sparkR = 255 : sparkG = 180 : sparkB = 70
                        CASE W_REPEATER : sparkN = 4 : sparkR = 80 : sparkG = 220 : sparkB = 255
                        CASE ELSE : sparkN = 14 : sparkR = 170 : sparkG = 240 : sparkB = 255
                    END SELECT
                    SpawnSparks hitX - rayX / rayLen * 0.03, hitY - rayY / rayLen * 0.03, hitZ, sparkN, sparkR, sparkG, sparkB
                    ShotMark hitX, hitY, hitZ, rayX / rayLen, rayY / rayLen, surface, 0.1 + 0.06 * (currentGun = W_RAIL) * -1
                END IF
            NEXT
        ELSEIF NOT fireWas THEN
            PlaySfx sndEmpty&, 0.7
            IF ammoType = AM_SHELLS THEN ShowMsg "Out of shells - kick! (F)" ELSE ShowMsg "Out of energy cells - kick! (F)"
            fireWait = 20 : IF kickTimer = 0 THEN kickTimer = KICK_FRAMES : PlaySfx sndKickSwing&, 0.7
        END IF
    END IF
    ' THE KICK: F (or Fire with no ammo, above). The boot swings up, lands
    ' KICK_HIT frames in - on the nearest monster in front, within KICK_REACH
    ' (and roughly where you're looking), shoving it back - or else a
    ' decoration - then drops back down
    kickDown = KeyHeld(BIND_KICK)
    IF kickDown AND NOT kickWas AND kickTimer = 0 AND NOT dead THEN kickTimer = KICK_FRAMES : PlaySfx sndKickSwing&, 0.7
    kickWas = kickDown
    IF kickTimer > 0 THEN
        kickTimer = kickTimer - 1
        IF kickTimer = KICK_FRAMES - KICK_HIT THEN
            best = 0 : bestD = KICK_REACH
            FOR i = 1 TO numMonsters
                IF monsterState(i) < 2 AND (cyberOn = 0 OR monsterType(i) = MT_ICE) THEN
                    ox = monsterX(i) - playerX : oy = monsterY(i) - playerY : d = SQR(ox * ox + oy * oy)
                    IF d < bestD AND d > 0.01 THEN IF (ox * dirX + oy * dirY) / d > 0.7 AND NOT GlassBetween(playerX, playerY, monsterX(i), monsterY(i)) THEN best = i : bestD = d
                END IF
            NEXT
            IF best THEN
                target = best : hitDamage = KICK_DAMAGE : IF ampTimer > 0 THEN hitDamage = hitDamage * 2
                GOSUB HitMonster
                IF monsterType(best) <> 5 THEN FOR kp = 1 TO 3 : MoveBody monsterX(best), monsterY(best), dirX * KICK_PUSH / 3, dirY * KICK_PUSH / 3 : NEXT ' (sentries are bolted down; in three steps, so it can't jump through glass)
                SpawnSparks monsterX(best), monsterY(best), 0.35, 8, 255, 200, 140
                PlaySfx sndKick&, 0.9 : shake = shake + 4 : crossFlash = 6
            ELSE
                kicked = 0
                FOR i = 1 TO numDecos
                    IF decoOn(i) AND decoKind(i) <> DK_BODY AND cyberOn = 0 THEN
                        ox = decoX(i) - playerX : oy = decoY(i) - playerY : d = SQR(ox * ox + oy * oy)
                        IF d < KICK_REACH AND d > 0.01 THEN
                            IF (ox * dirX + oy * dirY) / d > 0.7 THEN targetDeco = i : hitDamage = KICK_DAMAGE : GOSUB HitDeco : PlaySfx sndKick&, 0.8 : shake = shake + 2 : kicked = -1 : EXIT FOR
                        END IF
                    END IF
                NEXT
                IF NOT kicked THEN ' Glass in front? The boot cracks it
                    FOR kd = 3 TO 7
                        glassAtX = playerX + dirX * kd / 10 : glassAtY = playerY + dirY * kd / 10
                        IF InGlass(glassAtX, glassAtY) THEN glassHitX = INT(glassAtX) : glassHitY = INT(glassAtY) : glassDmg = 1 : GOSUB HitGlass : PlaySfx sndKick&, 0.8 : shake = shake + 2 : EXIT FOR
                    NEXT
                END IF
            END IF
        END IF
    END IF
    fireWas = fireDown : spaceWas = spaceDown

    IF cyberOn THEN ' In the network (chapter 19): the clock, and the way out
        cyberTime = cyberTime - 1
        IF cyberGot >= cyberNeed THEN
            cyberWon = -1 : GOSUB JackOut
        ELSEIF cyberTime <= 0 THEN
            cyberWon = 0 : GOSUB JackOut
        END IF
    ELSEIF NOT editMode THEN
        GOSUB RunEvents ' The level's event rooms (chapter 19)
        GOSUB RunTriggers ' ...its triggers, and its teleporters
    END IF

    '-------------------------------------------------------------------------
    ' CHAPTER 13: MONSTERS, BOLTS AND BARRELS
    '-------------------------------------------------------------------------
    ' Each monster is a little "state machine": what it does depends on
    ' which state it's in, and things that happen move it to another state.
    '
    '   0 idle     waits until it can see you (CanSee walks a line from it
    '              to you, checking for walls and shut doors - chapter 23)
    '   1 hunting  forever after: walks at you and attacks when close
    '              enough - or, if it shoots (mtypeRanged), keeps its
    '              distance and fires bolts whenever it has a clear line
    '   2 dying    falls for MON_DYING frames: sinks to the floor, then
    '              lies there (its body: MakeCorpse, chapter 23)
    '   3 dead     a body on the floor; skipped by everything else
    '
    ' Shooting an idle monster wakes it too (HitMonster, chapter 19).
    ' Monsters steer the dumbest way possible - straight at you - and slide
    ' along walls with MoveBody like you do. They also push gently apart, so
    ' a pack doesn't merge into one sprite.
    ' (chatterWait: frames before any monster may mutter or growl again, so
    ' a crowd doesn't drown everything)
    IF chatterWait > 0 THEN chatterWait = chatterWait - 1
    FOR i = 1 TO numMonsters
        IF cyberOn AND monsterType(i) <> MT_ICE THEN _CONTINUE ' (in the real world: they wait)
        IF editMode OR hudEdit THEN _CONTINUE ' (in the editors: everything waits)
        IF monsterHurt(i) > 0 THEN monsterHurt(i) = monsterHurt(i) -1
        IF monsterAtk(i) > 0 THEN monsterAtk(i) = monsterAtk(i) - 1
        ' Kicked over the edge of a pit with no bottom (it never walks off
        ' one): gone into the dark
        IF monsterState(i) < 2 AND NOT levelFlat THEN
            IF floorH(INT(monsterX(i)), INT(monsterY(i))) <= PIT_DEPTH THEN target = i : hitDamage = 9999 : GOSUB HitMonster : ShowMsg "Over the edge!"
        END IF
        mtype = monsterType(i)
        ' Its animation moves on: walkers and the crawler as far as they
        ' walked (a frame every MON_STRIDE of a cell), the drone and the
        ' sentry all the time (hovering, scanning) - a little slower idle
        animX = monsterX(i) : animY = monsterY(i)
        IF mtype = 1 OR mtype = 5 OR mtype = 8 THEN IF monsterState(i) < 2 THEN monsterAnim(i) = monsterAnim(i) + 0.12 - 0.06 * (monsterState(i) = 0) ' (hovering, scanning: slower asleep)
        SELECT CASE monsterState(i)
            CASE 0 ' Idle: wake when it can see you - and mutter now and then
                ' (a sound about every 8 seconds, if you're near enough to hear:
                ' SFX_CHATTER cells)
                IF RND < 0.002 AND chatterWait = 0 THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < SFX_CHATTER * SFX_CHATTER THEN SfxAtRange mtypeIdleSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY, SFX_CHATTER : chatterWait = 30
                END IF
                IF NOT dead THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2 < MON_SIGHT * MON_SIGHT THEN
                        IF CanSee(monsterX(i), monsterY(i), playerX, playerY) THEN
                            monsterState(i) = 1 : monsterTimer(i) = 30
                            SfxAt mtypeAlertSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                            IF mtype = 8 THEN Say "boss", 0 ' (the overseer: NEXUS speaks through it)
                            IF (mtype = 2 OR mtype = 6 OR mtype = 7) AND RND < 0.35 THEN Say "bark" + LTRIM$(STR$(INT(RND * 6) + 1)), -1 ' (a minion reports in)
                        END IF
                    END IF
                END IF
            CASE 1 ' Hunting - growling or whirring as it comes (about every 4 seconds)
                IF monsterTimer(i) > 0 THEN monsterTimer(i) = monsterTimer(i) -1
                IF RND < 0.004 AND chatterWait = 0 THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < SFX_CHATTER * SFX_CHATTER THEN SfxAtRange mtypeHuntSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY, SFX_CHATTER : chatterWait = 30
                END IF
                toPlayerX = playerX - monsterX(i) : toPlayerY = playerY - monsterY(i) : distance = SQR(toPlayerX * toPlayerX + toPlayerY * toPlayerY)
                IF NOT dead AND distance > 0.01 THEN
                    goX = 0 : goY = 0
                    IF mtype = MT_THIEF THEN
                        GOSUB ThiefStep
                    ELSEIF mtypeRanged(mtype) THEN
                        ' Gunner: keep its distance, shoot when it has a clear line
                        ' (a sentry can't move, so it just shoots)
                        seen = CanSee(monsterX(i), monsterY(i), playerX, playerY)
                        IF distance > GUNNER_FAR OR NOT seen THEN goX = toPlayerX / distance : goY = toPlayerY / distance
                        IF distance < GUNNER_NEAR THEN goX = - toPlayerX / distance : goY = -toPlayerY / distance
                        IF seen AND monsterTimer(i) = 0 AND distance < 11 THEN
                            FireBolt monsterX(i), monsterY(i), toPlayerX / distance, toPlayerY / distance, mtypeDamage(mtype) + INT(RND * mtypeDamageRnd(mtype))
                            IF mtype = 8 THEN ' The overseer: a fan of three (two more, turned a little either way)
                                FOR spread = -1 TO 1 STEP 2
                                    spreadA = spread * 0.22 : ux = toPlayerX / distance : uy = toPlayerY / distance
                                    FireBolt monsterX(i), monsterY(i), ux * COS(spreadA) - uy * SIN(spreadA), ux * SIN(spreadA) + uy * COS(spreadA), mtypeDamage(mtype)
                                NEXT
                            END IF
                            monsterAtk(i) = ATTACK_FRAMES
                            SfxAt mtypeAttackSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                            monsterTimer(i) = mtypeCooldown(mtype) + INT(RND * 30)
                        END IF
                    ELSEIF distance > mtypeReach(mtype) THEN
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' The rest: close in...
                    ELSEIF GlassBetween(monsterX(i), monsterY(i), playerX, playerY) THEN
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' (glass between: it just presses against it)
                    ELSEIF monsterTimer(i) = 0 THEN ' ...and hit
                        damage = mtypeDamage(mtype) + INT(RND * mtypeDamageRnd(mtype)) : monsterTimer(i) = mtypeCooldown(mtype)
                        PlaySfx mtypeAttackSnd&(mtype), 0.9
                        hurtFromX = monsterX(i) : hurtFromY = monsterY(i) : GOSUB HurtPlayer
                        monsterAtk(i) = ATTACK_FRAMES
                    END IF
                    IF (goX <> 0 OR goY <> 0) AND mtypeSpeed(mtype) > 0 THEN ' A door in the way? Open it (MonsterDoor, chapter 11)
                        MonsterDoor INT(monsterX(i) + goX * 0.7), INT(monsterY(i)), playerX, playerY
                        MonsterDoor INT(monsterX(i)), INT(monsterY(i) + goY * 0.7), playerX, playerY
                    END IF
                    walkZ = floorH(INT(monsterX(i)), INT(monsterY(i))) ' (it steps up, and falls off, as you do - but only so high)
                    walkFromHaz = FloorHazard(INT(monsterX(i)), INT(monsterY(i))) + 10 ' (and keeps out of fire, unless it's in it already)
                    IF goX <> 0 OR goY <> 0 THEN MoveBody monsterX(i), monsterY(i), goX * mtypeSpeed(mtype), goY * mtypeSpeed(mtype)
                    walkZ = -999 : walkFromHaz = 0
                END IF
                monsterAnim(i) = monsterAnim(i) + SQR((monsterX(i) - animX) ^ 2 + (monsterY(i) - animY) ^ 2) / MON_STRIDE
                ' Keep a little apart from each other
                FOR j = 1 TO numMonsters
                    IF j <> i AND monsterState(j) < 2 AND mtypeSpeed(mtype) > 0 THEN
                        relX = monsterX(i) - monsterX(j) : relY = monsterY(i) -monsterY(j) : distSq = relX * relX + relY * relY
                        IF distSq < 0.36 AND distSq > 0.0001 THEN
                            newX = monsterX(i) + relX * 0.05 : newY = monsterY(i) + relY * 0.05
                            IF Walkable(newX, newY) THEN monsterX(i) = newX : monsterY(i) = newY
                        END IF
                    END IF
                NEXT
            CASE 2 ' Dying: collapse
                monsterTimer(i) = monsterTimer(i) -1
                IF monsterTimer(i) <= 0 THEN monsterState(i) = 3
        END SELECT
    NEXT

    ' Bolts fly in a straight line, a little each frame, and burst on walls
    ' or on you. Since they move only 0.14 cells a frame, checking the one
    ' point where each bolt is can't miss a wall.
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) THEN
            boltX(i) = boltX(i) + boltDX(i) * BOLT_SPEED : boltY(i) = boltY(i) + boltDY(i) * BOLT_SPEED : boltZ(i) = boltZ(i) + boltDZ(i) * BOLT_SPEED
            IF NOT levelFlat THEN ' (heights: into a step, a floor or a ceiling, it bursts)
                IF boltZ(i) < floorH(INT(boltX(i)), INT(boltY(i))) + 0.02 OR boltZ(i) > ceilH(INT(boltX(i)), INT(boltY(i))) - 0.02 THEN boltX(i) = boltX(i) - boltDX(i) * 0.05 : boltY(i) = boltY(i) - boltDY(i) * 0.05 : boltOn(i) = 0 : SpawnSparks boltX(i), boltY(i), boltZ(i) - floorH(INT(boltX(i)), INT(boltY(i))), 7, 255, 60, 230 : SfxAt sndBoltWall&, boltX(i), boltY(i), playerX, playerY
            END IF
            IF boltOn(i) = 0 THEN
            ELSEIF InGlass(boltX(i), boltY(i)) THEN ' Glass: it bursts on it, and cracks it
                boltOn(i) = 0 : SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, 0.49, 7, 255, 60, 230
                glassHitX = INT(boltX(i)) : glassHitY = INT(boltY(i)) : glassAtX = boltX(i) : glassAtY = boltY(i) : glassDmg = 1 : GOSUB HitGlass
            ELSEIF NOT Walkable(boltX(i), boltY(i)) THEN
                boltOn(i) = 0 : SfxAt sndBoltWall&, boltX(i), boltY(i), playerX, playerY
                SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, 0.49, 7, 255, 60, 230
                IF IsWall(INT(boltX(i)), INT(boltY(i))) THEN ShotMark boltX(i) - boltDX(i) * BOLT_SPEED, boltY(i) - boltDY(i) * BOLT_SPEED, 0.49, boltDX(i), boltDY(i), 0, 0.12
            ELSEIF NOT dead AND (boltX(i) - playerX) ^ 2 + (boltY(i) -playerY) ^ 2 < 0.35 * 0.35 AND ABS(boltZ(i) - playerZ - 0.45) < 0.5 THEN
                boltOn(i) = 0 : damage = boltDamage(i)
                hurtFromX = boltX(i) - boltDX(i) * 2 : hurtFromY = boltY(i) - boltDY(i) * 2 ' (back along its path)
                GOSUB HurtPlayer
            END IF
        END IF
    NEXT
    ' Barrels: a shot lights a fuse (decoFuse), which counts down frames and
    ' then the barrel blows up (Explode, chapter 19). A blast lights the
    ' fuses of barrels near it, so they go off in a quick chain - and breaks
    ' the lamps, plants and terminals near it. Explosions on show fade out
    ' over BLAST_FRAMES.
    FOR i = 1 TO numDecos
        IF decoFuse(i) > 0 THEN
            decoFuse(i) = decoFuse(i) - 1
            IF decoFuse(i) = 0 THEN barrel = i : GOSUB Explode
        END IF
        IF decoTimer(i) > 0 THEN decoTimer(i) = decoTimer(i) - 1 ' A broken one collapsing
    NEXT
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN blastTime(i) = blastTime(i) - 1
    NEXT
    IF railBeam > 0 THEN railBeam = railBeam - 1
    ' Particles (sparks, embers and dust, drawn by OpenGL - chapter 24) move
    ' on; dust drifts in around you with the PARTICLES effect on, and swirls
    ' out of your way as you walk through it (playerX - prevX: this frame's
    ' step, from chapter 9)
    UpdateParticles playerX, playerY, playerX - prevX, playerY - prevY
    IF glMode AND setting(SET_PARTICLES) THEN SpawnDust playerX, playerY

    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
    IF ampTimer > 0 THEN ' The damage amp wears off
        ampTimer = ampTimer - 1 : IF ampTimer = 0 THEN PlaySfx sndAmpEnd&, 0.8 : ShowMsg "Damage amp wore off"
    END IF
    IF pickFlash > 0 THEN pickFlash = pickFlash - 1

    '-------------------------------------------------------------------------
    ' CHAPTER 14: LIGHT, AND DRAWING THE FLOOR AND CEILING
    '-------------------------------------------------------------------------
    ' Now we draw the frame into pixels() - floor and ceiling first, then the
    ' walls on top of them (chapter 15), then the sprites (chapter 16).
    '
    ' But first, light. Like Doom, the light is kept per cell: litR(),
    ' litG() and litB() say how much red, green and blue light each cell
    ' has this frame. Everything in a cell - its floor and ceiling, the
    ' faces of the walls around it, the monsters in it - is lit by it.
    ' UpdateLight starts every cell at the level's ambient light, then adds
    ' each of the level's lights (a light is brightest where it is and
    ' fades to nothing at its radius, and it doesn't shine through walls),
    ' made to flicker, pulse or strobe by its effect. Then muzzle flashes,
    ' explosions and bolts add their glow. A per-cell light is blocky, like
    ' Doom's, but it's cheap: 48 x 48 cells, not 120,000 pixels.
    '
    ' The horizon is the middle row of the screen. Your eye is half a wall up
    ' from the floor, so every row below the horizon shows the floor at one
    ' fixed distance: the further down the screen, the closer the floor. By
    ' similar triangles, row y sees the floor at
    '
    '     rowDist = (viewH / 2) / (y - RENDER_H / 2)
    '
    ' (viewH is RENDER_H, times the zoom while you aim - chapter 8)
    '
    ' (the + 0.5 below aims at the middle of the row, and keeps us from ever
    ' dividing by 0). Along that row, the floor point slides in a straight
    ' line from where the left-most ray (rayDirX0, rayDirY0) meets the floor
    ' to where the right-most ray (rayDirX1, rayDirY1) does - so we work out
    ' the step from one pixel to the next once (floorStepX, floorStepY) and
    ' just add it 400 times. The fraction part of the floor point picks the
    ' texture pixel: INT(floorX * 64) AND 63 is the same as
    ' (floorX * 64) MOD 64 for a 64-pixel texture, only faster - which is why
    ' textures are a power of 2 wide.
    '
    ' The ceiling is the same picture upside down: row y's mirror image above
    ' the horizon shows the ceiling at the same distance, straight above the
    ' same floor point. So one pass draws both.
    '
    ' The light: each pixel takes its cell's light (litR, litG, litB), dimmed
    ' by the fog - fog& goes from 256 close up down to 0 (black) 16 cells
    ' away. ShadeRGB~& (chapter 23) multiplies the texture's red, green and
    ' blue by the light's.
    '
    ' Which renderer draws this frame (RENDERER in the menu: chapter 21)?
    ' This code, or the graphics card (OPENGL, chapter 24). With OpenGL the
    ' light is still worked out here, and the raycaster still runs - for
    ' the zBuffer, the map, and to find the cells you can see - but the
    ' loops that colour in pixels one at a time are skipped. glWrite is the
    ' half of OpenGL's snapshot (chapter 5) this frame fills in.
    glMode = (setting(SET_RENDERER) = 2)
    glWrite = 1 - glBuf : glFrameNo = glFrameNo + 1 : glNumSpr(glWrite) = 0
    viewStart# = TIMER(0.001) ' (for SHOW FPS: how long the 3D view takes)
    ' This frame's light: the level's own (UpdateLight, chapter 23), then
    ' the flashes - your muzzle, explosions, bolts - each a glow that fades
    ' out over a few cells (AddGlow, chapter 23)
    ' (With OpenGL's MOVING LIGHTS, the flashes are real lights of their own,
    ' lighting every pixel - chapter 24 - so they're left out of the cells.)
    UpdateLight
    IF NOT (glMode AND setting(SET_DYNLIGHT) <> 0) THEN
        IF muzzleFlash > 0 THEN AddGlow playerX, playerY, 5, 70 * muzzleFlash, 40 * muzzleFlash, 40 * muzzleFlash
        FOR i = 1 TO MAX_BLASTS
            IF blastTime(i) > 0 THEN
                f = blastTime(i) / BLAST_FRAMES * blastSize(i)
                AddGlow blastX(i), blastY(i), 2 + 5 * blastSize(i), 400 * f, 220 * f, 90 * f
            END IF
        NEXT
        FOR i = 1 TO MAX_BOLTS
            IF boltOn(i) THEN AddGlow boltX(i), boltY(i), 2.5, 160, 40, 170
        NEXT
    END IF
    IF NOT glMode AND levelFlat THEN ' (OpenGL draws the floor and ceiling itself; with heights, HeightColumn does - chapter 15)
        rayDirX0 = dirX - planeX : rayDirY0 = dirY - planeY
        rayDirX1 = dirX + planeX : rayDirY1 = dirY + planeY
        FOR y = RENDER_H \ 2 TO RENDER_H - 1
            rowDist = (viewH / 2) /(y - RENDER_H / 2 + 0.5)
            floorStepX = rowDist * (rayDirX1 - rayDirX0) / RENDER_W : floorStepY = rowDist * (rayDirY1 - rayDirY0) / RENDER_W
            floorX = playerX + rowDist * rayDirX0 : floorY = playerY + rowDist * rayDirY0
            fog& = 256 - rowDist * 16
            IF fog& < 0 THEN fog& = 0
            floorRow = y * RENDER_W : ceilRow = (RENDER_H - 1 - y) * RENDER_W
            lastCellX = -1 : lastCellY = -1
            FOR x = 0 TO RENDER_W - 1
                cellX = INT(floorX) : cellY = INT(floorY)
                ' Neighbouring pixels are nearly always in the same cell, so a
                ' cell's textures and light are only looked up when we cross
                ' into a new one
                IF cellX <> lastCellX OR cellY <> lastCellY THEN
                    lastCellX = cellX : lastCellY = cellY : splitCell = 0
                    IF cellX >= 0 AND cellX < MAP_SIZE AND cellY >= 0 AND cellY < MAP_SIZE THEN
                        cellFloor = floorTex(cellX, cellY) : cellCeil = ceilTex(cellX, cellY)
                        splitCell = floorSplit(cellX, cellY) OR ceilSplit(cellX, cellY)
                        cellTrack = 0 ' A door's track: 1 running along x, 2 along y (DoorAcross + 1)
                        IF worldMap(cellX, cellY) = 2 THEN IF doorType(cellX, cellY) <> DOOR_EXIT THEN cellTrack = DoorAcross(cellX, cellY) + 1
                        lightR& = litR(cellX, cellY) * fog& \ 256 : lightG& = litG(cellX, cellY) * fog& \ 256 : lightB& = litB(cellX, cellY) * fog& \ 256
                    ELSE
                        cellFloor = T_FLOOR + 1 : cellCeil = T_CEIL + 1 : cellTrack = 0
                        lightR& = ambientR * fog& \ 256 : lightG& = ambientG * fog& \ 256 : lightB& = ambientB * fog& \ 256
                    END IF
                    IF lightR& > 256 THEN lightR& = 256 ' (full brightness at most: then the sums below can't overflow)
                    IF lightG& > 256 THEN lightG& = 256
                    IF lightB& > 256 THEN lightB& = 256
                END IF
                floorSlot = cellFloor : ceilSlot = cellCeil
                IF splitCell THEN ' A cell split on the diagonal: which half is this pixel in?
                    IF floorSplit(cellX, cellY) THEN IF InDiagonalWall(floorSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN floorSlot = floorTex2(cellX, cellY)
                    IF ceilSplit(cellX, cellY) THEN IF InDiagonalWall(ceilSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN ceilSlot = ceilTex2(cellX, cellY)
                END IF
                texU = INT(floorX * texSize) AND (texSize - 1) : texV = INT(floorY * texSize) AND (texSize - 1)
                ' The same sum as ShadeRGB~& (chapter 23), written out here: this
                ' runs 120,000 times a frame, and calling a FUNCTION each time
                ' would cost more than the sum itself
                texel~& = texture(texU, texV, floorSlot)
                pixels(floorRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                texel~& = texture(texU, texV, ceilSlot)
                pixels(ceilRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                IF gridOn THEN IF texU < gridW OR texV < gridW THEN pixels(floorRow + x) = GridMix~&(pixels(floorRow + x)) : pixels(ceilRow + x) = GridMix~&(pixels(ceilRow + x)) ' (the editor's grid: chapter 21)
                IF cellTrack THEN ' In a doorway: its door's track, a dark groove (a quarter as bright)
                    IF cellTrack = 1 THEN trackD = ABS(floorY - cellY - 0.5) ELSE trackD = ABS(floorX - cellX - 0.5)
                    IF trackD < TRACK_HALF THEN
                        pixels(floorRow + x) = ((pixels(floorRow + x) AND &HFCFCFC) \ 4) OR &HFF000000~&
                        pixels(ceilRow + x) = ((pixels(ceilRow + x) AND &HFCFCFC) \ 4) OR &HFF000000~&
                    END IF
                END IF
                floorX = floorX + floorStepX : floorY = floorY + floorStepY
            NEXT
        NEXT
    END IF

    ' (HeightColumn's floors and ceilings: each row's distance-per-height,
    ' worked out once a frame instead of once a pixel - see HeightColumn)
    IF NOT glMode AND NOT levelFlat THEN
        FOR y = 0 TO RENDER_H - 1
            rowF(y) = viewH / (y - RENDER_H / 2 + 0.5) : rowC(y) = viewH / (RENDER_H / 2 - y - 0.5)
        NEXT
    END IF

    '-------------------------------------------------------------------------
    ' CHAPTER 15: DRAWING THE WALLS - THE RAYCASTER
    '-------------------------------------------------------------------------
    ' The heart of the game. For each of the 400 columns of the view:
    '
    ' 1. THE RAY. cameraX goes from -1 at the left column to +1 at the
    '    right. The ray's direction is your direction plus that much of the
    '    camera plane (chapter 8): rayDir = dir + plane * cameraX.
    '
    ' 2. WALKING THE GRID (the "DDA"). We want the first wall cell the ray
    '    enters. Rather than inch along it, we hop from one cell edge to the
    '    next. The ray crosses a vertical grid line (an "x-side") every
    '    deltaDistX of travel, and a horizontal one (a "y-side") every
    '    deltaDistY - for a ray that's (rayDirX, rayDirY), that's
    '    ABS(1 / rayDirX) and ABS(1 / rayDirY). sideDistX and sideDistY are
    '    how far along the ray the NEXT x-side and y-side are. Each step,
    '    whichever is nearer is the edge we cross: move into that cell
    '    (stepX or stepY is +1 or -1, the way the ray points), push that
    '    side's distance one deltaDist further, and look at the new cell.
    '    "side" remembers which kind of edge we came through: 0 = x-side
    '    (a wall facing east or west), 1 = y-side (north or south).
    '
    '                    +-----+-----+-----+
    '                    |     |     |#####|   The ray crosses edges in
    '                    |     |    /|#####|   order of distance: x-side,
    '                    +-----+---/-+-----+   y-side, x-side... and stops
    '                    |     |  /  |     |   in the first wall cell (#).
    '                    |     | /   |     |
    '                    +-----+/----+-----+
    '                    | you /     |     |
    '
    ' 3. HOW FAR? perpWallDist is the distance to the wall measured straight
    '    ahead (at right angles to the camera plane), NOT along the ray. If
    '    we used the true ray length, walls at the screen's edges would come
    '    out too far away and the view would bulge like a fish-eye lens.
    '    Measured straight ahead, a flat wall stays flat. The DDA hands it
    '    to us: it's the sideDist of the edge we crossed last (sideDist minus
    '    one deltaDist, as sideDist has already moved on) - worked out below
    '    from the cell we stopped in.
    '
    ' 4. HOW TALL? A wall one cell high, perpWallDist away, is
    '    viewH / perpWallDist pixels tall, centred on the horizon (viewH
    '    is RENDER_H, times the zoom while you aim - chapter 8).
    '
    ' 5. WHICH TEXTURE COLUMN? wallX is where along the wall's face the ray
    '    hit (0 to 1); times 64 that's the column of the texture to draw.
    '    Some faces flip it, so textures aren't mirrored when you see them
    '    from the other side. Down the screen we step through the texture
    '    by texStep = 64 / lineHeight texels per pixel.
    '
    ' 6. LIGHT. Fog by distance as on the floor, and y-sides a bit darker
    '    than x-sides. It's fake lighting, but it makes corners readable.
    '
    ' 7. zBuffer(x) = perpWallDist, for the sprites (chapter 16) and for
    '    shooting (chapter 12).
    '
    ' Some cells aren't simply solid:
    '   DOORS are slabs DOOR_THICK thick across the middle of their cell
    '   (DoorRay works out where a ray meets one). The ray stops at the slab
    '   only where the door still is: a sliding door has slid doorOpen of
    '   the way across, so a ray crossing where it slid away from carries on
    '   into the room beyond - unless it meets the door's edge on the way.
    '   A rising shutter is drawn in a second pass, over whatever is behind
    '   it ("shutterSeen" remembers it) - and its underside, once it's above
    '   your eyes. (The exit door, which never opens, stays on its cell's
    '   face, like a wall.)
    '   DIAGONAL WALLS: entering one, we check where the ray crosses the
    '   cell's diagonal (DiagonalHit, chapter 23). If it does before leaving
    '   the cell, that's the hit, at that distance; otherwise the ray is in
    '   the open half and carries on.
    FOR x = 0 TO RENDER_W - 1
        cameraX = 2 * x / RENDER_W - 1
        rayDirX = dirX + planeX * cameraX : rayDirY = dirY + planeY * cameraX
        mapX = INT(playerX) : mapY = INT(playerY)
        cellSeen(mapX, mapY) = -1 : glSeen(mapX, mapY, glWrite) = glFrameNo
        deltaDistX = ABS(1 / rayDirX) : deltaDistY = ABS(1 / rayDirY)

        IF rayDirX < 0 THEN stepX = -1 : sideDistX = (playerX - mapX) * deltaDistX ELSE stepX = 1 : sideDistX = (mapX + 1 - playerX) * deltaDistX
        IF rayDirY < 0 THEN stepY = -1 : sideDistY = (playerY - mapY) * deltaDistY ELSE stepY = 1 : sideDistY = (mapY + 1 - playerY) * deltaDistY

        hit = 0 : side = 0 : shutterSeen = 0 : diagHit = 0 : doorHit = 0
        glassT(x) = 0 : glassDone(x) = 0 ' (glass: GlassRay notes the nearest pane the ray goes through)
        IF glassHP(mapX, mapY) > 0 THEN IF GlassRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, gT, gU) THEN glassT(x) = gT : glassU(x) = gU : glassCX(x) = mapX : glassCY(x) = mapY
        IF diagCorner(mapX, mapY) THEN ' Standing in a diagonal wall's open half
            exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
            diagDist = DiagonalHit(diagCorner(mapX, mapY), mapX, mapY, playerX, playerY, rayDirX, rayDirY, 0, exitDist)
            IF diagDist >= 0 THEN hit = worldMap(mapX, mapY) : diagHit = diagCorner(mapX, mapY) : perpWallDist = diagDist
        END IF
        WHILE hit = 0
            IF sideDistX < sideDistY THEN sideDistX = sideDistX + deltaDistX : mapX = mapX + stepX : side = 0 ELSE sideDistY = sideDistY + deltaDistY : mapY = mapY + stepY : side = 1
            cellValue = worldMap(mapX, mapY)
            cellSeen(mapX, mapY) = -1 ' (for the map: you've seen this cell)
            glSeen(mapX, mapY, glWrite) = glFrameNo ' (and for OpenGL: a cell to draw - chapter 24)
            IF glassHP(mapX, mapY) > 0 AND glassT(x) = 0 THEN ' Glass: note it, and carry on through
                IF GlassRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, gT, gU) THEN glassT(x) = gT : glassU(x) = gU : glassCX(x) = mapX : glassCY(x) = mapY
            END IF
            IF diagCorner(mapX, mapY) THEN
                ' Diagonal wall: came in through its solid half, that's a plain
                ' wall face; else it hits the diagonal if it crosses it in here
                IF side = 0 THEN enterDist = sideDistX - deltaDistX ELSE enterDist = sideDistY - deltaDistY
                exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
                IF InDiagonalWall(diagCorner(mapX, mapY), playerX + (enterDist + 0.001) * rayDirX - mapX, playerY + (enterDist + 0.001) * rayDirY - mapY) THEN
                    hit = cellValue
                ELSE
                    diagDist = DiagonalHit(diagCorner(mapX, mapY), mapX, mapY, playerX, playerY, rayDirX, rayDirY, enterDist, exitDist)
                    IF diagDist >= 0 THEN hit = cellValue : diagHit = diagCorner(mapX, mapY) : perpWallDist = diagDist
                END IF
            ELSEIF cellValue = 2 THEN
                IF doorType(mapX, mapY) = DOOR_EXIT THEN ' Never opens: a wall, on its cell's face
                    hit = 2
                ELSE ' A slab across the doorway's middle (DoorRay)
                    doorHit = DoorRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, doorDist, doorU, doorSide, doorLitX, doorLitY, doorBack)
                    IF doorHit = 3 THEN ' A rising shutter: drawn afterwards, over what's behind
                        IF shutterSeen = 0 THEN
                            shutterSeen = -1 : shutterDist = doorDist : shutterBack = doorBack : shutterU = doorU : shutterOpen = DoorShown(mapX, mapY)
                            shutterSide = doorSide : shutterLitX = doorLitX : shutterLitY = doorLitY
                        END IF
                        doorHit = 0
                    ELSEIF doorHit THEN
                        hit = 2 : side = doorSide : perpWallDist = doorDist
                    END IF
                END IF
            ELSEIF cellValue > 0 THEN
                hit = cellValue
            END IF
        WEND

        IF diagHit = 0 AND doorHit = 0 THEN
            IF side = 0 THEN perpWallDist = (mapX - playerX + (1 - stepX) / 2) / rayDirX ELSE perpWallDist = (mapY - playerY + (1 - stepY) / 2) / rayDirY
        END IF
        IF perpWallDist < 0.001 THEN perpWallDist = 0.001
        zBuffer(x) = perpWallDist

        ' Texture column and slot (a door's texture slides along with it)
        IF side = 0 THEN wallX = playerY + perpWallDist * rayDirY ELSE wallX = playerX + perpWallDist * rayDirX
        wallX = wallX - INT(wallX)
        IF diagHit THEN ' Along the diagonal, left to right as you see it
            wallX = playerX + perpWallDist * rayDirX - mapX
            IF diagHit <= 2 THEN wallX = 1 - wallX
            texX = INT(wallX * texSize) : texSlot = wallTexSlot(hit)
        ELSEIF doorHit = 2 THEN ' A door's edge: a thin slice of its picture
            texX = INT(doorU * DOOR_THICK * texSize)
            SELECT CASE doorType(mapX, mapY)
                CASE DOOR_SLIDE : IF doorKey(mapX, mapY) THEN texSlot = T_DOORK + doorKey(mapX, mapY) ELSE texSlot = T_DOOR
                CASE DOOR_SPLIT : texSlot = T_SPLIT
                CASE ELSE : texSlot = T_SHUTTER
            END SELECT
        ELSEIF hit = 2 THEN
            IF doorHit THEN wallX = doorU ' (where along the slab)
            doorOpenAmt = DoorShown(mapX, mapY)
            SELECT CASE doorType(mapX, mapY)
                CASE DOOR_SLIDE
                    texX = INT((wallX - doorOpenAmt) * texSize)
                    IF doorKey(mapX, mapY) THEN texSlot = T_DOORK + doorKey(mapX, mapY) ELSE texSlot = T_DOOR
                CASE DOOR_SPLIT
                    IF wallX < 0.5 THEN texX = INT((wallX + doorOpenAmt / 2) * texSize) ELSE texX = INT((wallX - doorOpenAmt / 2) * texSize)
                    texSlot = T_SPLIT
                CASE DOOR_EXIT ' (turned like a wall, so its sign reads the right way)
                    texX = INT(wallX * texSize) : texSlot = T_EXIT
                    IF side = 0 AND rayDirX > 0 THEN texX = texSize - 1 - texX
                    IF side = 1 AND rayDirY < 0 THEN texX = texSize - 1 - texX
                CASE ELSE
                    texX = INT(wallX * texSize) : texSlot = T_SHUTTER
            END SELECT
        ELSE
            texX = INT(wallX * texSize) : texSlot = wallTexSlot(hit)
            IF side = 0 AND rayDirX > 0 THEN texX = texSize - 1 - texX
            IF side = 1 AND rayDirY < 0 THEN texX = texSize - 1 - texX
            IF lvlNumFaces THEN ' (a side with a picture of its own - the editor's PAINT)
                IF side = 0 THEN IF rayDirX > 0 THEN sd = 3 ELSE sd = 1
                IF side = 1 THEN IF rayDirY > 0 THEN sd = 4 ELSE sd = 2
                IF faceTex(mapX, mapY, sd) OR faceTex2(mapX, mapY, sd) THEN texSlot = FaceSlot(mapX, mapY, sd, texX / texSize, 0, texSlot)
            END IF
        END IF
        texX = texX AND (texSize - 1)

        lineHeight = viewH / perpWallDist
        drawStart = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2)
        texStep = texSize / lineHeight : texPos = (drawStart - RENDER_H / 2 + lineHeight / 2) * texStep
        IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
        IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1

        ' Light: the light of the cell in front of the face we hit (for a
        ' diagonal, its own cell), dimmed by distance fog, y-sides darker and
        ' diagonals in between
        fog& = 256 - perpWallDist * 16
        IF fog& < 0 THEN fog& = 0
        IF diagHit THEN fog& = fog& * 0.85 ELSE IF side = 1 THEN fog& = fog& * 0.7
        IF doorHit THEN
            litX = doorLitX : litY = doorLitY
        ELSEIF diagHit THEN
            litX = mapX : litY = mapY
        ELSEIF side = 0 THEN
            litX = mapX - stepX : litY = mapY
        ELSE
            litX = mapX : litY = mapY - stepY
        END IF
        lightR& = litR(litX, litY) * fog& \ 256 : lightG& = litG(litX, litY) * fog& \ 256 : lightB& = litB(litX, litY) * fog& \ 256
        IF lightR& > 256 THEN lightR& = 256
        IF lightG& > 256 THEN lightG& = 256
        IF lightB& > 256 THEN lightB& = 256

        clipN(x) = 0
        IF NOT glMode AND NOT levelFlat THEN GOSUB HeightColumn ' (heights: the column, Doom's way - below)
        IF NOT glMode AND levelFlat THEN ' (OpenGL draws the walls itself)
            FOR y = drawStart TO drawEnd ' (ShadeRGB~&, written out - see the floor)
                texel~& = texture(texX, INT(texPos) AND (texSize - 1), texSlot)
                pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                IF gridOn THEN IF texX < gridW OR (INT(texPos) AND (texSize - 1)) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
                texPos = texPos + texStep
            NEXT
        END IF

        ' A rising shutter in front: its lower edge has lifted shutterOpen of
        ' the way up, so draw only the part still hanging down
        IF shutterSeen THEN
            lineHeight = viewH / shutterDist
            shutterTop = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2 - shutterOpen * lineHeight)
            texStep = texSize / lineHeight : texPos = shutterOpen * texSize
            drawStart = shutterTop
            IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
            IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1
            fog& = 256 - shutterDist * 16
            IF fog& < 0 THEN fog& = 0
            IF shutterSide = 1 THEN fog& = fog& * 0.7
            lightR& = litR(shutterLitX, shutterLitY) * fog& \ 256 : lightG& = litG(shutterLitX, shutterLitY) * fog& \ 256 : lightB& = litB(shutterLitX, shutterLitY) * fog& \ 256
            texX = INT(shutterU * texSize) AND (texSize - 1)
            IF NOT glMode AND levelFlat THEN
                FOR y = drawStart TO drawEnd
                    pixels(y * RENDER_W + x) = ShadeRGB~&(texture(texX, INT(texPos) AND (texSize - 1), T_SHUTTER), lightR&, lightG&, lightB&)
                    texPos = texPos + texStep
                NEXT
                ' Lifted above your eyes, you see its underside: from its front
                ' edge down to its back edge (further away, so nearer the
                ' middle of the view), darker
                IF shutterOpen > 0.5 AND shutterBack > shutterDist THEN
                    underEnd = INT(RENDER_H / 2 + viewH / shutterBack * (0.5 - shutterOpen))
                    IF underEnd > RENDER_H - 1 THEN underEnd = RENDER_H - 1
                    FOR y = drawEnd + 1 TO underEnd
                        IF y >= 0 THEN pixels(y * RENDER_W + x) = ShadeRGB~&(texture(texX, texSize - 2, T_SHUTTER), lightR& \ 2, lightG& \ 2, lightB& \ 2)
                    NEXT
                END IF
            END IF
            IF shutterOpen < 0.5 THEN zBuffer(x) = shutterDist ' Mostly down: things behind it stay hidden
        END IF
    NEXT x

    '-------------------------------------------------------------------------
    ' CHAPTER 16: DRAWING SPRITES
    '-------------------------------------------------------------------------
    ' Monsters, pickups, decorations, bolts and explosions are "billboards":
    ' flat pictures that always face you, like cardboard cut-outs that turn
    ' to follow you around.
    '
    ' First every visible thing goes into one list (drawX, drawY, which
    ' picture, how big, how high off the floor), and the list is sorted
    ' far to near: drawing the far ones first lets near ones cover them
    ' (the "painter's algorithm"). A simple swap sort is fine for a few
    ' dozen sprites.
    '
    ' Then, for each one, where is it on screen? (relX, relY) is the sprite
    ' relative to you. We turn that into "camera space" - how far in front
    ' of you (transformY) and how far to the side (transformX), measured
    ' along your direction and the camera plane. That's solving
    '   rel = plane * transformX + dir * transformY
    ' for the two unknowns, which is what invDet and the two lines below do
    ' (it's the inverse of the 2 x 2 matrix [plane dir]). Then:
    '   - behind you (transformY <= 0): skip it
    '   - across the screen: RENDER_W / 2 * (1 + transformX / transformY)
    '     (things further away crowd towards the middle - perspective)
    '   - size: viewH / transformY, like a wall slice, times its scale
    '
    ' Each column of the sprite is drawn only if it's nearer than the wall
    ' in that column (transformY < zBuffer(x)) - that's how sprites hide
    ' behind walls and doorframes. Transparent pixels (alpha 128 or less)
    ' are skipped, so you see the shape, not its square.
    numDraw = 0
    FOR i = 1 TO numItems
        IF itemOn(i) AND (itemKind(i) = IT_CORE) = cyberOn THEN ' (in the network, just its data cores)
            numDraw = numDraw + 1 : drawX(numDraw) = itemX(i) : drawY(numDraw) = itemY(i)
            drawSprite(numDraw) = ItemSprite(itemKind(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 96 ' They glow: less fog
            SELECT CASE itemKind(i)
                CASE 1 TO 3 : drawScale(numDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL : drawScale(numDraw) = GUN_ITEM_SCALE
                CASE IT_CORE : drawScale(numDraw) = 0.42 : drawMinShade(numDraw) = 256
                CASE ELSE : drawScale(numDraw) = ITEM_SCALE
            END SELECT
            drawLift(numDraw) = 0.12 + 0.04 * SIN(TIMER * 3 + i) ' Hovering, bobbing
        END IF
    NEXT
    FOR i = 1 TO numMonsters
        mtype = monsterType(i)
        IF cyberOn AND mtype <> MT_ICE THEN _CONTINUE ' (in the network: only ICE)
        numDraw = numDraw + 1 : drawX(numDraw) = monsterX(i) : drawY(numDraw) = monsterY(i)
        drawScale(numDraw) = mtypeScale(mtype) : drawMinShade(numDraw) = 40 : IF mtype = MT_ICE THEN drawMinShade(numDraw) = 230
        ' Its frame: hurt, attacking, or how far through its animation
        IF monsterHurt(i) > 0 THEN
            drawSprite(numDraw) = mtypeSprite(mtype) + 1
        ELSEIF monsterAtk(i) > 0 THEN
            drawSprite(numDraw) = MonFrame(mtype, ANIM_FRAMES)
        ELSE
            drawSprite(numDraw) = MonFrame(mtype, INT(monsterAnim(i)) MOD ANIM_FRAMES)
        END IF
        fallen = monsterState(i) = 3 OR (monsterState(i) = 2 AND monsterTimer(i) <= MON_DYING \ 2)
        IF fallen THEN ' Dead (or half way through falling): its body, lying on the floor
            drawSprite(numDraw) = S_CORPSE + mtype : drawScale(numDraw) = corpseScale(mtype)
            drawSquash(numDraw) = corpseSquash(mtype) : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw) : drawMinShade(numDraw) = 0
        ELSEIF monsterState(i) = 2 THEN ' Falling: it sinks to the floor and crumples, hurt
            f = (monsterTimer(i) - MON_DYING / 2) / (MON_DYING / 2) ' (1 just hit .. 0 down)
            drawSquash(numDraw) = 0.55 + 0.45 * f : drawLift(numDraw) = mtypeLift(mtype) * f : drawSprite(numDraw) = mtypeSprite(mtype) + 1
        ELSE
            drawSquash(numDraw) = 1 : drawLift(numDraw) = mtypeLift(mtype) + mtypeBob(mtype) * SIN(TIMER * 2.5 + i * 1.7)
        END IF
    NEXT
    FOR i = 1 TO numDecos
        IF cyberOn = 0 THEN ' (every one - broken ones leave their wreck; none in the network)
            numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) : drawY(numDraw) = decoY(i)
            drawSprite(numDraw) = DecoSlot(decoKind(i)) : drawScale(numDraw) = DecoScale(decoKind(i)) : drawLift(numDraw) = 0
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40
            IF NOT decoOn(i) THEN ' Broken: what's left of it (MakeWreck)
                drawSprite(numDraw) = S_WRECK + decoKind(i) : drawScale(numDraw) = wreckScale(decoKind(i))
                drawSquash(numDraw) = wreckSquash(decoKind(i)) : drawMinShade(numDraw) = 0 : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw)
            END IF
            IF decoKind(i) = 2 OR decoKind(i) = 7 OR decoKind(i) = 12 OR decoKind(i) = 13 OR decoKind(i) = 17 THEN drawMinShade(numDraw) = 200 ' Lamps (vending machines, monitors, tanks, holograms) glow
        END IF
    NEXT
    ' Traps: pressure plates (flat on the floor, glowing while they count
    ' down) and laser beams (a wall-high bar per cell of the beam)
    FOR k = 1 TO numPads ' Teleporters' pads: flat and glowing
        IF numDraw < MAX_DRAW THEN
            numDraw = numDraw + 1 : drawX(numDraw) = padX(k) + 0.5 : drawY(numDraw) = padY(k) + 0.5 : drawSprite(numDraw) = S_PAD
            drawScale(numDraw) = 0.85 : drawSquash(numDraw) = 0.16 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 200 + 56 * SIN(TIMER * 4 + k)
        END IF
    NEXT
    FOR ev = 1 TO numEvents
        IF cyberOn THEN EXIT FOR ' (no traps in the network)
        SELECT CASE evType(ev)
            CASE EV_PLATE
                FOR py = evY0(ev) TO evY1(ev) : FOR px = evX0(ev) TO evX1(ev)
                    IF numDraw < MAX_DRAW THEN
                        numDraw = numDraw + 1 : drawX(numDraw) = px + 0.5 : drawY(numDraw) = py + 0.5 : drawSprite(numDraw) = S_PLATE
                        drawScale(numDraw) = 0.7 : drawSquash(numDraw) = 0.18 : drawLift(numDraw) = 0
                        drawMinShade(numDraw) = 60 : IF evState(ev) = 1 AND (evTimer(ev) \ 4) MOD 2 = 0 THEN drawMinShade(numDraw) = 256
                    END IF
                NEXT : NEXT
            CASE EV_LASER
                IF LaserOn(ev) OR (LaserSoon(ev) AND (evTimer(ev) \ 3) MOD 2 = 0) THEN
                    FOR py = evY0(ev) TO evY1(ev) : FOR px = evX0(ev) TO evX1(ev)
                        IF numDraw < MAX_DRAW THEN
                            numDraw = numDraw + 1 : drawX(numDraw) = px + 0.5 : drawY(numDraw) = py + 0.5 : drawSprite(numDraw) = S_LASER
                            drawScale(numDraw) = 1 : drawSquash(numDraw) = 1 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 256
                        END IF
                    NEXT : NEXT
                END IF
            CASE EV_CUTTER
                CutterAt ev, cutX, cutY, cutAlongX
                IF cutAlongX THEN n0 = evY0(ev) : n1 = evY1(ev) ELSE n0 = evX0(ev) : n1 = evX1(ev)
                FOR k = n0 TO n1
                    IF numDraw < MAX_DRAW THEN
                        numDraw = numDraw + 1 : drawSprite(numDraw) = S_LASER
                        IF cutAlongX THEN drawX(numDraw) = cutX : drawY(numDraw) = k + 0.5 ELSE drawX(numDraw) = k + 0.5 : drawY(numDraw) = cutY
                        drawScale(numDraw) = 1 : drawSquash(numDraw) = 1 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 256
                    END IF
                NEXT
        END SELECT
    NEXT
    ' Decals, for the software renderer: little flat scorch marks facing
    ' you, just off the wall (so the wall doesn't hide them) - or squashed
    ' flat on the floor or ceiling. (OpenGL lays them on the surface itself:
    ' GLDecals, chapter 24.)
    IF NOT glMode THEN
        FOR i = 1 TO MAX_DECALS
            IF decalOn(i) THEN
                numDraw = numDraw + 1 : drawSprite(numDraw) = S_DECAL : drawScale(numDraw) = decalSize(i) : drawMinShade(numDraw) = 0
                drawX(numDraw) = decalX(i) + decalNX(i) * 0.03 : drawY(numDraw) = decalY(i) + decalNY(i) * 0.03
                IF ABS(decalNZ(i)) > 0.5 THEN
                    drawSquash(numDraw) = 0.35
                    IF decalNZ(i) > 0 THEN drawLift(numDraw) = 0.004 ELSE drawLift(numDraw) = 0.996 - decalSize(i) * 0.35
                ELSE
                    drawSquash(numDraw) = 1 : drawLift(numDraw) = decalZ(i) - decalSize(i) / 2
                END IF
            END IF
        NEXT
    END IF
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN ' Explosions swell as they fade
            numDraw = numDraw + 1 : drawX(numDraw) = blastX(i) : drawY(numDraw) = blastY(i)
            ' Its frame: how far through it is, from the white-hot flash to
            ' the last of the smoke (MakeBoomFrames)
            boomF = INT((1 - blastTime(i) / BLAST_FRAMES) * BOOM_FRAMES) + 1 : IF boomF > BOOM_FRAMES THEN boomF = BOOM_FRAMES
            drawSprite(numDraw) = S_BOOM + boomF : drawScale(numDraw) = (0.6 + 0.7 * (1 - blastTime(i) / BLAST_FRAMES)) * blastSize(i)
            drawLift(numDraw) = 0.05 + (1 - blastSize(i)) * 0.35 ' (a small puff of sparks floats at the broken thing's middle)
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) THEN
            numDraw = numDraw + 1 : drawX(numDraw) = boltX(i) : drawY(numDraw) = boltY(i)
            drawSprite(numDraw) = S_BOLT : drawScale(numDraw) = 0.22 : drawLift(numDraw) = boltZ(i) - 0.11 - floorH(INT(boltX(i)), INT(boltY(i)))
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256 ' Glowing: no fog at all
        END IF
    NEXT
    FOR i = 1 TO numDraw
        drawOrder(i) = i : drawDistSq(i) = (drawX(i) - playerX) ^ 2 + (drawY(i) -playerY) ^ 2
    NEXT
    FOR a = 1 TO numDraw - 1 : FOR b = a + 1 TO numDraw
        IF drawDistSq(drawOrder(b)) > drawDistSq(drawOrder(a)) THEN SWAP drawOrder(a), drawOrder(b)
    NEXT : NEXT
    invDet = 1 /(planeX * dirY - dirX * planeY)
    FOR drawIdx = 1 TO numDraw
        i = drawOrder(drawIdx)
        relX = drawX(i) - playerX : relY = drawY(i) -playerY
        transformX = invDet * (dirY * relX - dirX * relY) ' Sideways from the view
        transformY = invDet * ( - planeY * relX + planeX * relY) ' Depth
        IF transformY > 0.1 THEN
            spriteW = INT(viewH / transformY * drawScale(i)) : spriteH = INT(spriteW * drawSquash(i))
            IF spriteH < 1 THEN spriteH = 1
            spriteTop = INT(RENDER_H / 2 + (eyeZ - FloorAt(drawX(i), drawY(i)) - drawLift(i)) * viewH / transformY) -spriteH ' Bottom edge on its floor, lifted off it - below your eye
            spriteLeft = INT(RENDER_W / 2 * (1 + transformX / transformY)) - spriteW \ 2
            ' Lit by the cell it's in, dimmed by fog - but never darker than
            ' its drawMinShade (things that glow)
            fog& = 256 - transformY * 10 : IF fog& < 0 THEN fog& = 0
            litX = INT(drawX(i)) : litY = INT(drawY(i))
            lightR& = litR(litX, litY) * fog& \ 256 : lightG& = litG(litX, litY) * fog& \ 256 : lightB& = litB(litX, litY) * fog& \ 256
            IF lightR& < drawMinShade(i) THEN lightR& = drawMinShade(i)
            IF lightG& < drawMinShade(i) THEN lightG& = drawMinShade(i)
            IF lightB& < drawMinShade(i) THEN lightB& = drawMinShade(i)
            spriteSz = spriteSize(drawSprite(i)) : spriteSlot = drawSprite(i)
            IF glMode THEN
                ' OpenGL draws it (chapter 24): just note where it stands, how
                ' big it is, its picture and its light (256 here is 1 there:
                ' full). It's drawScale cells tall. The loop below draws it as
                ' wide on the screen as it is tall, and on the screen a cell
                ' across isn't quite as many pixels as a cell up - so in cells,
                ' that's fovPlane * RENDER_H / RENDER_W * drawScale either side
                ' of its middle.
                n = glNumSpr(glWrite) + 1 : glNumSpr(glWrite) = n
                glSprX(n, glWrite) = drawX(i) : glSprY(n, glWrite) = drawY(i) : glSprLift(n, glWrite) = drawLift(i) + FloorAt(drawX(i), drawY(i))
                glSprHalfW(n, glWrite) = drawScale(i) * fovPlane * RENDER_H / RENDER_W
                glSprH(n, glWrite) = drawScale(i) * drawSquash(i) : glSprSlot(n, glWrite) = spriteSlot
                glSprR(n, glWrite) = lightR& / 256 : glSprG(n, glWrite) = lightG& / 256 : glSprB(n, glWrite) = lightB& / 256
            ELSE
                FOR screenX = spriteLeft TO spriteLeft + spriteW - 1
                    IF screenX >= 0 AND screenX < RENDER_W THEN
                        IF transformY < zBuffer(screenX) THEN
                            ' (glass in this column nearer than the wall but behind
                            ' this sprite: on now, over what's behind it - all of
                            ' that is drawn, far to near - and under this)
                            IF glassT(screenX) > 0 AND glassDone(screenX) = 0 THEN IF transformY < glassT(screenX) THEN gx = screenX : GOSUB GlassColumn
                            spriteU = (screenX - spriteLeft) * spriteSz \ spriteW
                            ' (heights: hidden above and below by the ledges and
                            ' lintels nearer than it - HeightColumn's clips)
                            spTop = 0 : spBot = RENDER_H - 1
                            FOR k = 1 TO clipN(screenX)
                                IF clipD(screenX, k) < transformY THEN spTop = clipT(screenX, k) : spBot = clipB(screenX, k)
                            NEXT
                            FOR screenY = spriteTop TO spriteTop + spriteH - 1
                                IF screenY >= spTop AND screenY <= spBot THEN
                                    texel~& = spriteTex(spriteU,(screenY - spriteTop) * spriteSz \ spriteH, spriteSlot)
                                    IF _ALPHA32(texel~&) > 128 THEN pixels(screenY * RENDER_W + screenX) = ShadeRGB~&(texel~&, lightR&, lightG&, lightB&)
                                END IF
                            NEXT
                        END IF
                    END IF
                NEXT
            END IF
        END IF
    NEXT
    ' ...and the glass in every column that had no sprite in front of it
    IF NOT glMode THEN
        FOR gx = 0 TO RENDER_W - 1
            IF glassT(gx) > 0 AND glassDone(gx) = 0 THEN GOSUB GlassColumn
        NEXT
    END IF

    '-------------------------------------------------------------------------
    ' CHAPTER 17: ONTO THE SCREEN
    '-------------------------------------------------------------------------
    ' The view is finished in pixels(). _MEMCOPY copies the whole array into
    ' renderImg& in one go (an image's pixels are stored the same way: row
    ' after row of colours), and _PUTIMAGE stretches that 400 x 300 image
    ' over the 800 x 600 window - drawing at half size and scaling up is the
    ' easiest speed-up there is, and it gives the chunky look for free.
    '
    ' Screen shake: firing, getting hurt and explosions add to "shake",
    ' which dies away a little every frame. While it's going, the view is
    ' drawn a few pixels off in a random direction each frame - and a
    ' little bigger than the window, so no gap shows at the edges. (It can
    ' be switched off in the menu's settings - some people find it makes
    ' them feel ill.)
    shakeX = 0 : shakeY = 0 : shakeEdge = 0
    IF shake > 0.3 AND setting(SET_SHAKE) THEN
        shakeEdge = shake : shakeX = (RND - 0.5) * shake : shakeY = (RND - 0.5) * shake
    END IF
    shake = shake * 0.85 : IF shake > 16 THEN shake = 16
    '
    ' Where the gun goes this frame. It's drawn in chapter 18, over the view
    ' - but placed now, so OpenGL's snapshot (below) can take it along.
    '
    ' The gun is lit by where you stand: the light round you (LightAt), in
    ' its colour - plus your muzzle flash, if OpenGL's moving lights took it
    ' out of the cells (chapter 14) - its colour made a little stronger
    ' (GUN_TINT: the level's light is mostly white, which would wash it
    ' out). It follows the light a fifth of the
    ' way each frame, so it eases rather than flickers, and never goes
    ' darker than GUN_DARKEST (it's right in front of your eyes) or brighter
    ' than GUN_BRIGHTEST.
    LightAt playerX, playerY, wantR, wantG, wantB
    IF glMode AND setting(SET_DYNLIGHT) <> 0 AND muzzleFlash > 0 THEN
        wantR = wantR + 70 * muzzleFlash : wantG = wantG + 40 * muzzleFlash : wantB = wantB + 40 * muzzleFlash
    END IF
    wantR = wantR / 256 : wantG = wantG / 256 : wantB = wantB / 256
    grey = (wantR + wantG + wantB) / 3 ' (its colour pushed further from grey - GUN_TINT - so a coloured light shows)
    wantR = grey + (wantR - grey) * GUN_TINT : wantG = grey + (wantG - grey) * GUN_TINT : wantB = grey + (wantB - grey) * GUN_TINT
    IF wantR < GUN_DARKEST THEN wantR = GUN_DARKEST
    IF wantG < GUN_DARKEST THEN wantG = GUN_DARKEST
    IF wantB < GUN_DARKEST THEN wantB = GUN_DARKEST
    IF wantR > GUN_BRIGHTEST THEN wantR = GUN_BRIGHTEST
    IF wantG > GUN_BRIGHTEST THEN wantG = GUN_BRIGHTEST
    IF wantB > GUN_BRIGHTEST THEN wantB = GUN_BRIGHTEST
    gunLightR = gunLightR + (wantR - gunLightR) * 0.2 : gunLightG = gunLightG + (wantG - gunLightG) * 0.2 : gunLightB = gunLightB + (wantB - gunLightB) * 0.2
    '
    ' The gun sways as you walk (bobPhase, from chapter 9), kicks when it
    ' fires (recoil, which shrinks a quarter every frame), and dips out of
    ' sight to swap.
    IF recoil > 0 THEN recoil = recoil * 0.75 : IF recoil < 0.02 THEN recoil = 0
    gunImage& = gunImg&(currentGun)
    ' Aiming (aimAmount, chapter 8) blends the gun from where it hangs at
    ' your hip up to your eye: bigger, its muzzle risen to ADS_MUZZLE_Y just
    ' under the crosshair, and hardly swaying. Its picture must still reach
    ' past the bottom of the screen, or it would float: a gun whose muzzle
    ' is halfway down its picture has to grow more to get its muzzle up
    ' there, so "grow" is worked out per gun. hipY is where the gun sits
    ' with its bottom 12 pixels below the screen, and it never goes higher.
    gunH = gunSize(currentGun) : gunW = gunH * _WIDTH(gunImage&) / _HEIGHT(gunImage&)
    grow = (GUN_Y + 12 - ADS_MUZZLE_Y) / (1 - gunMuzzleY(currentGun)) / gunH ' Just tall enough
    IF grow < ADS_GUN_GROW THEN grow = ADS_GUN_GROW
    IF grow > ADS_GUN_GROW_MAX THEN grow = ADS_GUN_GROW_MAX
    grow = 1 + (grow - 1) * aimAmount
    gunW = gunW * grow : gunH = gunH * grow
    hipY = GUN_Y - gunH + 12 : eyeY = ADS_MUZZLE_Y - gunH * gunMuzzleY(currentGun)
    IF eyeY < hipY THEN eyeY = hipY ' (its bottom never comes up into view)
    sway = 1 - 0.8 * aimAmount
    IF setting(SET_BOB) = 0 THEN sway = 0 ' Weapon bobbing switched off (chapter 21)
    gunX = 400 - gunW * gunMuzzleX(currentGun) + COS(bobPhase / 2) * 10 * sway + shakeX
    gunY = hipY + (eyeY - hipY) * aimAmount + ABS(SIN(bobPhase / 2)) * 10 * sway + recoil * 36 + shakeY
    IF swapTimer > 0 THEN gunY = gunY + (SWAP_FRAMES / 2 - ABS(swapTimer - SWAP_FRAMES / 2)) * 40
    IF kickTimer > 0 THEN gunY = gunY + SIN((1 - kickTimer / KICK_FRAMES) * 3.14159) * 90 ' (kicking: the gun dips)
    IF dead THEN gunY = gunY + (TIMER - deadAt!) * 400 ' Drops out of view
    '
    ' With OpenGL (chapter 24) there's no picture to copy: instead we finish
    ' the snapshot - the camera, every cell's light, every door - and then
    ' switch glBuf over to it, in one line, so SUB _GL only ever sees a
    ' whole frame. The screen is cleared to see-through (alpha 0), so the
    ' graphics card's view shows from underneath (chapter 1) wherever the
    ' HUD below doesn't draw.
    IF glMode THEN
        glCamX(glWrite) = playerX : glCamY(glWrite) = playerY : glDirX(glWrite) = dirX : glDirY(glWrite) = dirY : glCamZ(glWrite) = eyeZ
        glPlaneLen(glWrite) = fovPlane / zoom : glZoom(glWrite) = zoom : glFullMode(glWrite) = _FULLSCREEN
        glShakeX(glWrite) = shakeX : glShakeY(glWrite) = shakeY : glShakeEdge(glWrite) = shakeEdge
        FOR i = 1 TO NUM_SETTINGS : glSet(i, glWrite) = setting(i) : NEXT
        glPitch(glWrite) = pitch : glHurt(glWrite) = hurtFlash / 14 : glRail(glWrite) = railBeam / 8
        glGun(glWrite) = 0 : IF gunY < 600 AND NOT editMode THEN glGun(glWrite) = currentGun ' The gun (0: out of sight - and in the editor), where on our screen
        glGunX0(glWrite) = gunX : glGunY0(glWrite) = gunY : glGunX1(glWrite) = gunX + gunW : glGunY1(glWrite) = gunY + gunH
        glGunR(glWrite) = gunLightR : glGunG(glWrite) = gunLightG : glGunB(glWrite) = gunLightB
        glSideDim(glWrite) = 0 ' (the menu dims the sides of a wide view: GLLiveSettings)
        ' (tilted, or wide, the view sees past the rays' edges)
        wideK = WideView : glWide(glWrite) = wideK
        IF ABS(pitch) > 0.01 OR wideK > 1.01 THEN GLMarkWide playerX, playerY, dirX, dirY, fovPlane / zoom * wideK, zoom
        GLHandOverExtras playerX, playerY, dirX, dirY, muzzleFlash ' Moving lights, particles, explosions (chapter 24)
        FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
            glLitR(x, y, glWrite) = litR(x, y) : glLitG(x, y, glWrite) = litG(x, y) : glLitB(x, y, glWrite) = litB(x, y)
            glDoor(x, y, glWrite) = DoorShown(x, y)
            ' Bumps: the middle of the light on this cell (or the cell's own
            ' middle, if it has none), and how much of its light that is
            IF litSumW(x, y) > 0 THEN
                glLitCX(x, y, glWrite) = litSumX(x, y) / litSumW(x, y) : glLitCY(x, y, glWrite) = litSumY(x, y) / litSumW(x, y)
                glLitDir(x, y, glWrite) = litSumW(x, y) / (litR(x, y) + litG(x, y) + litB(x, y) + 1)
            ELSE
                glLitCX(x, y, glWrite) = x + 0.5 : glLitCY(x, y, glWrite) = y + 0.5 : glLitDir(x, y, glWrite) = 0
            END IF
            ' ...and the same into the light tables, for the graphics card
            ' (chapter 24) - only the map's cells: the rest stay 0
            IF x < MAP_SIZE AND y < MAP_SIZE THEN
                t& = glWrite * GL_TABLE_SIZE + (y * GL_TABLE + x) * 4
                glLitData(t&) = litR(x, y) : glLitData(t& + 1) = litG(x, y) : glLitData(t& + 2) = litB(x, y)
                v = worldMap(x, y) : glLitData(t& + 3) = (v <= 0 OR v = 2 OR diagCorner(x, y) <> 0) * -1
                glInfoData(t&) = glLitCX(x, y, glWrite) : glInfoData(t& + 1) = glLitCY(x, y, glWrite) : glInfoData(t& + 2) = glLitDir(x, y, glWrite)
                FOR k = 1 TO GL_DYN : glDynData(t& + k - 1) = glDynReach(x, y, k, glWrite) : NEXT
            END IF
        NEXT : NEXT
        ' Glows: bolts, explosions, and every lamp and terminal that's lit
        ' (its light's colour, flickering with it)
        n = 0
        FOR i = 1 TO MAX_BOLTS
            IF boltOn(i) THEN
                n = n + 1 : glGlowX(n, glWrite) = boltX(i) : glGlowY(n, glWrite) = boltY(i) : glGlowZ(n, glWrite) = 0.49
                glGlowSize(n, glWrite) = 0.35 : glGlowR(n, glWrite) = 1 : glGlowG(n, glWrite) = 0.25 : glGlowB(n, glWrite) = 0.9
            END IF
        NEXT
        FOR i = 1 TO MAX_BLASTS
            IF blastTime(i) > 0 THEN
                f = blastTime(i) / BLAST_FRAMES : blastScale = (0.6 + 0.7 * (1 - f)) * blastSize(i)
                n = n + 1 : glGlowX(n, glWrite) = blastX(i) : glGlowY(n, glWrite) = blastY(i)
                glGlowZ(n, glWrite) = 0.05 + (1 - blastSize(i)) * 0.35 + blastScale / 2 : glGlowSize(n, glWrite) = blastScale
                glGlowR(n, glWrite) = f : glGlowG(n, glWrite) = 0.55 * f : glGlowB(n, glWrite) = 0.2 * f
            END IF
        NEXT
        FOR l = 1 TO numLights
            IF lightDeco(l) THEN
                IF decoOn(lightDeco(l)) AND lightNow(l) > 0 THEN
                    i = lightDeco(l) : brightest = lightR(l) : IF lightG(l) > brightest THEN brightest = lightG(l)
                    IF lightB(l) > brightest THEN brightest = lightB(l)
                    n = n + 1 : glGlowX(n, glWrite) = decoX(i) : glGlowY(n, glWrite) = decoY(i)
                    glGlowZ(n, glWrite) = DecoScale(decoKind(i)) * 0.8
                    IF decoKind(i) = 2 THEN glGlowSize(n, glWrite) = 0.6 ELSE glGlowSize(n, glWrite) = 0.4 ' (lamps bigger)
                    f = lightNow(l) / (brightest + 1)
                    glGlowR(n, glWrite) = lightR(l) * f : glGlowG(n, glWrite) = lightG(l) * f : glGlowB(n, glWrite) = lightB(l) * f
                END IF
            END IF
        NEXT
        glNumGlow(glWrite) = n
        glFrame(glWrite) = glFrameNo
        glBuf = glWrite : glReady = -1 ' (the switch: from now on, SUB _GL draws this one)
        CLS , _RGBA32(0, 0, 0, 0)
    ELSE
        glReady = 0
        _MEMCOPY pixelsMem, pixelsMem.OFFSET, pixelsMem.SIZE TO renderMem, renderMem.OFFSET
        _PUTIMAGE (shakeX - shakeEdge, shakeY - shakeEdge)-(799 + shakeX + shakeEdge, 599 + shakeY + shakeEdge), renderImg&, 0
    END IF
    viewMs = (TIMER(0.001) - viewStart#) * 1000 ' (for SHOW FPS)

    '-------------------------------------------------------------------------
    ' CHAPTER 18: THE GUN AND THE HUD
    '-------------------------------------------------------------------------
    ' Everything from here is drawn straight onto the window, at full size,
    ' with ordinary QB64PE graphics: _PUTIMAGE for pictures, LINE for boxes,
    ' _PRINTSTRING for text. Colours made with _RGBA32 have an alpha (0
    ' clear .. 255 solid), so a LINE ... BF over the whole screen with a low
    ' alpha tints everything: red when you're hurt, yellow for a pickup.
    '
    ' The map comes last: the minimap in the corner once you've found the
    ' map pickup, and the full-screen map when Tab is on.
    '
    ' The gun was placed in chapter 17 (gunX, gunY, gunW, gunH): drawn here
    ' - or with OpenGL, by the graphics card, at the window's own size
    ' (chapter 24), under all of this
    IF gunY < 600 AND NOT glMode AND NOT editMode THEN _PUTIMAGE (gunX, gunY)-(gunX + gunW - 1, gunY + gunH - 1), TintedGun&(currentGun) ' (in its light - not in the editor: nothing to shoot, and it's in the way)
    ' The kick: the boot comes up from the bottom of the screen (a little
    ' left of the middle), at its highest when it lands, then drops away -
    ' lit like the gun, by where you stand
    IF kickTimer > 0 AND kickImg& < -1 THEN
        kf = 1 - kickTimer / KICK_FRAMES ' (0 .. 1 through the kick)
        IF kf < KICK_HIT / KICK_FRAMES THEN up = kf / (KICK_HIT / KICK_FRAMES) ELSE up = 1 - (kf - KICK_HIT / KICK_FRAMES) / (1 - KICK_HIT / KICK_FRAMES)
        up = SIN(up * 1.5708)
        kh = 360 : kw = kh * _WIDTH(kickImg&) / _HEIGHT(kickImg&)
        kx = 330 - kw / 2 + shakeX : ky = 600 - kh * up * 0.95 + shakeY
        _PUTIMAGE (kx, ky)-(kx + kw - 1, ky + kh - 1), kickImg&
    END IF
    IF muzzleFlash > 0 THEN ' Muzzle flash, and a flicker of light on everything
        muzzleFlash = muzzleFlash - 1
        LINE (0, 0)-(799, 599), _RGBA32(255, 120, 120, 18), BF
        flashX = gunX + gunW * gunMuzzleX(currentGun) : flashY = gunY + gunH * gunMuzzleY(currentGun)
        FillCircle flashX, flashY, 30 + muzzleFlash * 4, _RGBA32(255, 40, 40, 90)
        FillCircle flashX, flashY, 18 + muzzleFlash * 3, _RGBA32(255, 150, 150, 170)
        FillCircle flashX, flashY, 8, _RGBA32(255, 255, 255, 230)
    END IF
    IF railBeam > 0 THEN ' The railgun's beam, from the muzzle to the crosshair
        flashX = gunX + gunW * gunMuzzleX(currentGun) : flashY = gunY + gunH * gunMuzzleY(currentGun)
        FOR k = -3 TO 3
            LINE (flashX + k, flashY)-(400 + k / 3, 300), _RGBA32(255, 60 + 30 * (3 - ABS(k)), 60 + 30 * (3 - ABS(k)), railBeam * 28)
        NEXT
    END IF

    ' The crosshair - its style, colour, size and opacity are settings, and
    ' with CROSSHAIR FEEDBACK it tightens as you fire, jolts wide when
    ' you're hit and flashes white when your shot hits something, easing
    ' back each frame - and the damage indicators: a red arc around it for
    ' each recent hit, pointing where it came from. Each one remembers
    ' where the hit came from, not which way it pointed, so the arc turns
    ' as you do - turn until it's at the top, and you're facing it.
    IF NOT dead THEN DrawCrosshair 400, 300
    crossScale = 1 + (crossScale - 1) * 0.85
    IF crossFlash > 0 THEN crossFlash = crossFlash - 1
    IF hurtFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 0, 0, hurtFlash * 9), BF
    IF pickFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 255, 160, pickFlash * 4), BF
    IF setting(SET_HURTDIR) THEN DrawHurtDirs playerX, playerY, dirX, dirY ' (over the red flash, so they stand out)
    IF godMode AND hudShow(HE_GOD) THEN HudText hudX(HE_GOD), hudY(HE_GOD), hudLabel$(HE_GOD), HudColor~&(HE_GOD, _RGB32(255, 215, 30))
    IF editMode THEN EditOverlay playerX, playerY, dirX, dirY ' (the editor: what you're aiming at, what you'll place)
    IF editMode AND editView = 1 THEN EditDrawFaces ' (the face under the pointer, and the ones selected, outlined)
    IF editMode AND editView = 1 AND NOT hudEdit THEN ' The toolbar (and the help, when it's up)
        IF edPickOn THEN
            IF edLooking THEN EditDrawPicker -1, -1 ELSE EditDrawPicker edCurX, edCurY
        END IF
        IF edLooking THEN EditDrawTB 1, -1, -1 ELSE EditDrawTB 1, edCurX, edCurY
        IF edHelp THEN EditDrawHelp 1
    END IF

    ' The map (DrawMap, chapter 23). The minimap in the corner only appears
    ' once you've found this level's map pickup. Tab opens the full-screen
    ' map: without the pickup it shows only the cells you've seen - you draw
    ' it as you explore - and with it, the whole level.
    killsY = hudY(HE_KILLS)
    IF hasMap AND NOT mapOpen AND hudShow(HE_MINIMAP) THEN
        DrawMap hudX(HE_MINIMAP), hudY(HE_MINIMAP), hudW(HE_MINIMAP), -1, playerX, playerY, dirX, dirY
        ' (the kill count, if it's where the map is, goes under it)
        IF hudX(HE_KILLS) = hudX(HE_MINIMAP) AND hudY(HE_KILLS) = hudY(HE_MINIMAP) THEN killsY = hudY(HE_MINIMAP) + MAP_SIZE * hudW(HE_MINIMAP) + 6
    END IF
    IF mapOpen THEN
        LINE (0, 0)-(799, 599), _RGBA32(0, 4, 14, 225), BF
        MenuText 400, 14, levelName$, 2, _RGB32(255, 100, 215), 1
        DrawMap 400 - MAP_SIZE * 5, 60, 10, hasMap, playerX, playerY, dirX, dirY
        IF hasMap THEN mapNote$ = "TAB  CLOSE THE MAP" ELSE mapNote$ = "NO MAP YET - ONLY WHERE YOU'VE BEEN.   TAB  CLOSE"
        MenuText 400, 552, mapNote$, 1, _RGB32(170, 170, 200), 1
    END IF
    IF NOT mapOpen AND hudShow(HE_KILLS) AND NOT (editMode AND NOT hudEdit) THEN HudText hudX(HE_KILLS), killsY, hudLabel$(HE_KILLS) + STR$(kills) + " /" + STR$(numMonsters), HudColor~&(HE_KILLS, _RGB32(255, 90, 90))

    ' Keycards you hold, top right
    cardX = hudX(HE_CARDS)
    FOR k = 3 TO 1 STEP - 1
        IF hasCard(k) AND hudShow(HE_CARDS) AND NOT (editMode AND NOT hudEdit) THEN cardX = cardX - hudW(HE_CARDS) - 4 : _PUTIMAGE (cardX, hudY(HE_CARDS))-STEP(hudW(HE_CARDS) - 1, hudW(HE_CARDS) - 1), cardImg&(k)
    NEXT

    ' Armour and health (bottom left)
    IF (armor > 0 OR hudEdit) AND hudShow(HE_ARMOR) AND NOT (editMode AND NOT hudEdit) THEN
        ac~& = HudColor~&(HE_ARMOR, _RGB32(90, 160, 255)) : ax = hudX(HE_ARMOR) : ay = hudY(HE_ARMOR)
        HudText ax, ay, hudLabel$(HE_ARMOR) + STR$(armor), ac~&
        IF hudW(HE_ARMOR) > 0 THEN
            LINE (ax, ay + 18)-STEP(hudW(HE_ARMOR) + 1, hudH(HE_ARMOR) + 1), _RGBA32(0, 0, 0, 170), BF
            IF armor > 0 THEN LINE (ax + 1, ay + 19)-STEP(MaxOf(1, armor * hudW(HE_ARMOR) \ MAX_ARMOR) - 1, hudH(HE_ARMOR) - 1), ac~&, BF
        END IF
    END IF
    IF health > 60 THEN healthColor~& = _RGB32(60, 230, 90) ELSE IF health > 25 THEN healthColor~& = _RGB32(255, 200, 40) ELSE healthColor~& = _RGB32(255, 50, 50)
    healthColor~& = HudColor~&(HE_HEALTH, healthColor~&)
    IF hudShow(HE_HEALTH) AND NOT (editMode AND NOT hudEdit) THEN
        hx = hudX(HE_HEALTH) : hy = hudY(HE_HEALTH) : bw = hudW(HE_HEALTH) : bh = hudH(HE_HEALTH)
        HudText hx, hy, hudLabel$(HE_HEALTH) + STR$(health), healthColor~&
        IF bw > 0 THEN
            LINE (hx, hy + 18)-STEP(bw + 1, bh + 1), _RGBA32(0, 0, 0, 170), BF
            IF health > 0 THEN LINE (hx + 1, hy + 19)-STEP(MaxOf(1, MinOf(health, MAX_HP) * bw \ MAX_HP) - 1, bh - 1), healthColor~&, BF
            IF health > MAX_HP THEN LINE (hx + 1, hy + 19)-STEP(MaxOf(1, (health - MAX_HP) * bw \ MAX_HP) - 1, bh - 1), _RGB32(90, 200, 255), BF ' (overcharged: the extra, in blue, over it)
        END IF
    END IF
    IF ampTimer > 0 AND hudShow(HE_AMP) THEN HudText hudX(HE_AMP), hudY(HE_AMP), hudLabel$(HE_AMP) + STR$(ampTimer \ 60 + 1), HudColor~&(HE_AMP, _RGB32(255, 90, 90))
    FOR ev = 1 TO numEvents ' An event room going on: what's left to do, and a pulsing red frame
        IF evState(ev) = 1 THEN
            SELECT CASE evType(ev)
                CASE EV_AMBUSH
                    left = evA(ev) - evCount(ev)
                    FOR j = 1 TO numMonsters
                        IF monsterEv(j) = ev AND monsterState(j) < 2 THEN left = left + 1
                    NEXT
                    evText$ = "LOCKDOWN - HOSTILES LEFT:" + STR$(left)
                CASE EV_SURVIVE : evText$ = "LOCKDOWN - SURVIVE" + STR$(evTimer(ev) \ 60 + 1)
                CASE EV_GALLERY : evText$ = "SHOOTING GALLERY -" + STR$(evTimer(ev) \ 60 + 1) + " SECONDS"
                CASE ELSE : evText$ = "DESTROY THE SPAWNERS"
            END SELECT
            IF hudShow(HE_EVENT) THEN HudText hudX(HE_EVENT) - LEN(evText$) * 4, hudY(HE_EVENT), evText$, HudColor~&(HE_EVENT, _RGB32(255, 120, 90))
            IF evType(ev) <> EV_NEST AND evType(ev) <> EV_GALLERY THEN
                pulse = 60 + 50 * SIN(TIMER * 6)
                FOR k = 0 TO 3 : LINE (k, k)-(799 - k, 599 - k), _RGBA32(255, 30, 30, pulse), B : NEXT
            END IF
        END IF
    NEXT

    ' Gun and its ammo (bottom right), and which guns you have
    ammoType = gunAmmoType(currentGun)
    IF ammoCount(ammoType) = 0 THEN
        ammoColor~& = _RGB32(255, 50, 50)
    ELSEIF ammoType = AM_SHELLS THEN
        ammoColor~& = _RGB32(255, 150, 40)
    ELSE
        ammoColor~& = _RGB32(60, 220, 255)
    END IF
    ammoColor~& = HudColor~&(HE_AMMO, ammoColor~&)
    ammoText$ = gunName$(currentGun) + "  " + LTRIM$(STR$(ammoCount(ammoType)))
    IF hudShow(HE_AMMO) AND NOT (editMode AND NOT hudEdit) THEN ' (its right edge at hudX)
        rx = hudX(HE_AMMO) : ry = hudY(HE_AMMO) : bw = hudW(HE_AMMO) : bh = hudH(HE_AMMO)
        HudText rx - 8 * LEN(ammoText$), ry, ammoText$, ammoColor~&
        IF bw > 0 THEN
            LINE (rx - bw - 2, ry + 18)-STEP(bw + 1, bh + 1), _RGBA32(0, 0, 0, 170), BF
            IF ammoCount(ammoType) > 0 THEN LINE (rx - 1 - ammoCount(ammoType) * bw \ ammoMax(ammoType), ry + 19)-(rx - 1, ry + 18 + bh), ammoColor~&, BF
        END IF
    END IF
    IF hudShow(HE_GUNS) AND NOT (editMode AND NOT hudEdit) THEN
        FOR gun = 1 TO NUM_GUNS
            gunNumColor~& = _RGB32(60, 60, 70)
            IF hasGun(gun) THEN gunNumColor~& = _RGB32(150, 150, 160)
            IF gun = currentGun THEN gunNumColor~& = HudColor~&(HE_GUNS, _RGB32(255, 255, 255))
            HudText hudX(HE_GUNS) + (gun - 1) * 20, hudY(HE_GUNS), LTRIM$(STR$(gun)), gunNumColor~&
        NEXT
    END IF

    ' In the network: what's left to grab, and the time left
    IF cyberOn AND hudShow(HE_NETWORK) THEN
        c$ = "NETWORK   DATA " + LTRIM$(STR$(cyberGot)) + " / " + LTRIM$(STR$(cyberNeed)) + "   TIME " + LTRIM$(STR$(cyberTime \ 60))
        nx = hudX(HE_NETWORK) : ny = hudY(HE_NETWORK)
        LINE (nx - LEN(c$) * 4 - 10, ny)-(nx + LEN(c$) * 4 + 10, ny + 20), _RGBA32(0, 20, 40, 190), BF
        LINE (nx - LEN(c$) * 4 - 10, ny)-(nx + LEN(c$) * 4 + 10, ny + 20), _RGB32(60, 240, 255), B
        cc~& = HudColor~&(HE_NETWORK, _RGB32(150, 250, 255)) : IF cyberTime < 600 AND (cyberTime \ 15) MOD 2 = 0 THEN cc~& = _RGB32(255, 80, 120)
        HudText nx - LEN(c$) * 4, ny + 5, c$, cc~&
    END IF
    ' What NEXUS is saying: a red-framed subtitle at the top
    IF speechUntil! > TIMER AND LEN(speechText$) AND hudShow(HE_SUBTITLE) THEN
        w = LEN(speechText$) * 8 + 24 : IF w > 780 THEN w = 780
        sx = hudX(HE_SUBTITLE) : sy = hudY(HE_SUBTITLE)
        LINE (sx - w \ 2, sy)-(sx + w \ 2, sy + 24), _RGBA32(30, 0, 8, 190), BF
        LINE (sx - w \ 2, sy)-(sx + w \ 2, sy + 24), _RGB32(255, 60, 90), B
        HudText sx - LEN(speechText$) * 4, sy + 5, speechText$, HudColor~&(HE_SUBTITLE, _RGB32(255, 200, 210))
    END IF
    ' Message line
    IF TIMER < messageUntil! AND LEN(message$) AND NOT mapOpen AND hudShow(HE_MESSAGE) THEN
        HudText hudX(HE_MESSAGE) - LEN(message$) * 4, hudY(HE_MESSAGE), message$, HudColor~&(HE_MESSAGE, _RGB32(255, 255, 255))
    END IF
    IF hudEdit THEN HudEditDraw ' (the HUD layout editor: boxes round it all)

    IF dead THEN
        LINE (0, 0)-(799, 599), _RGBA32(90, 0, 0, 110), BF
        BigText "YOU DIED", 230, 6, _RGB32(255, 60, 60)
        IF TIMER - deadAt! > 1.2 THEN HudText 400 - 15 * 8, 330, "Click or press Space to try again", _RGB32(255, 255, 255)
    END IF

    ' SHOW FPS (SETTINGS > VIDEO): frames a second, counted over each
    ' second, and how long the 3D view takes to draw, smoothed a little -
    ' for OpenGL, our part of it plus SUB _GL's (glMs, chapter 24). Try
    ' both renderers and compare. (_LIMIT 60 keeps the frames at 60 at
    ' most, so the milliseconds tell you more: 16.7 is all of a frame.)
    fpsFrames = fpsFrames + 1
    IF TIMER - fpsStart! >= 1 OR TIMER < fpsStart! THEN fpsShown = fpsFrames : fpsFrames = 0 : fpsStart! = TIMER
    IF glMode THEN viewMs = viewMs + glMs
    viewAvg = viewAvg * 0.9 + viewMs * 0.1
    IF setting(SET_FPS) THEN
        ' Every part padded to the same width (RIGHT$ of spaces and the number),
        ' so the line doesn't shift about as the numbers grow and shrink
        IF glMode THEN fpsText$ = "  OPENGL" ELSE fpsText$ = "SOFTWARE"
        tenths = INT(viewAvg * 10 + 0.5) : IF tenths > 9999 THEN tenths = 9999
        msText$ = LTRIM$(STR$(tenths \ 10)) + "." + LTRIM$(STR$(tenths MOD 10))
        fpsText$ = fpsText$ + "   FPS" + RIGHT$("   " + STR$(fpsShown), 4) + "   3D VIEW" + RIGHT$("     " + msText$, 6) + " MS"
        IF hudShow(HE_FPS) THEN HudText hudX(HE_FPS) - LEN(fpsText$) * 4, hudY(HE_FPS), fpsText$, HudColor~&(HE_FPS, _RGB32(255, 255, 120))
    END IF

    ' With OpenGL, the HUD goes to the graphics card as a picture, to be
    ' laid over the 3D view there (chapter 24): GLSL_filter_capture copies
    ' the screen for SUB _GL, and our own screen layer is switched off
    IF glMode THEN GLSL_filter_capture
    GLScreenLayer glMode
    DisplayFollow ' (Alt + Enter changes the DISPLAY setting - chapter 21)
    _DISPLAY ' Show the finished frame (chapter 7)
    ' A screenshot asked for (the console's screenshot): the software
    ' renderer's frame is our screen; OpenGL's, SUB _GL reads back for us
    ' (glShotReq 2 - chapter 24)
    IF shotFile$ <> "" AND NOT glMode THEN _SAVEIMAGE shotFile$, 0 : ConPrint "saved " + shotFile$ : shotFile$ = ""
    IF glShotReq = 2 THEN SaveGLShot
LOOP ' (forever: you leave the game from the menu - chapter 21)

'-----------------------------------------------------------------------------
' CHAPTER 19: GAME EVENTS
'-----------------------------------------------------------------------------
' Things that happen from more than one place - a monster or a decoration
' getting hit (by a shot or a blast), you getting hurt (by a bite, a bolt,
' a blast), a barrel going off - are GOSUB routines: a label, some lines,
' and RETURN. Unlike a SUB, a GOSUB routine is part of the main program, so it can use all its
' variables (health, kills, playerX...) directly. The catch is it takes no
' parameters, so the caller sets a variable first: "target = i : hitDamage
' = 1 : GOSUB HitMonster".
'
' The rest of the chapter is the level's own happenings: the event rooms
' (RunEvents); glass that cracks and shatters (HitGlass, GlassColumn);
' the data stations' network (JackIn, JackOut - the whole level turned to
' a neon grid by swapping its pictures for CyberTextures'); the triggers
' and teleporters (RunTriggers - a trigger's actions are console
' commands, so anything you can type, a level can do); and the code
' terminals (TerminalUse, RunPuzzle - a real QB64 program to put back
' together, compiled for real with SHELL _DONTWAIT while the game waits).

' --- A shot (or blast) hits monster number target, for hitDamage
HitMonster:
monsterHP(target) = monsterHP(target) - hitDamage : monsterHurt(target) = 8
IF monsterState(target) = 0 THEN monsterState(target) = 1 : monsterTimer(target) = 30 ' Shot awake (chapter 13)
IF monsterHP(target) <= 0 AND monsterState(target) < 2 THEN
    monsterState(target) = 2 : monsterTimer(target) = MON_DYING : kills = kills + 1
    mt = monsterType(target) ' (its drop - monsters.txt)
    IF mtypeDrop(mt) > 0 AND NOT cyberOn THEN IF RND < mtypeDropChance(mt) THEN DropItemAt mtypeDrop(mt), monsterX(target), monsterY(target)
    IF monsterType(target) = MT_THIEF THEN DropThiefLoot target
    IF monsterType(target) = 8 THEN Say "bossdie", 0
    SfxAt mtypeDieSnd&(monsterType(target)), monsterX(target), monsterY(target), playerX, playerY
    IF kills = numMonsters THEN ShowMsg "SECTOR CLEAR - every monster destroyed!"
ELSE
    SfxAt mtypeHitSnd&(monsterType(target)), monsterX(target), monsterY(target), playerX, playerY
END IF
RETURN

' --- You take `damage` (armour soaks up a third of it while it lasts). If
' the caller said where it came from (hurtFromX, hurtFromY), a damage
' indicator points there (chapter 18).
HurtPlayer:
IF godMode OR editMode THEN hurtFromX = -1 : hurtElectric = 0 : RETURN ' (nothing hurts in god mode, or in the editor)
IF setting(SET_XFEEDBACK) THEN crossScale = 1.8 ' The crosshair jolts wide
IF hurtFromX >= 0 THEN AddHurtDir hurtFromX, hurtFromY
hurtFromX = -1
absorbed = damage \ 3 : IF absorbed > armor THEN absorbed = armor
armor = armor - absorbed : damage = damage - absorbed
health = health - damage : hurtFlash = 14 : shake = shake + damage / 2
IF health <= 0 THEN
    health = 0 : dead = -1 : deadAt! = TIMER
    PlaySfx sndDie&, 1 : ShowMsg ""
ELSE
    SELECT CASE INT(RND * 3) ' One of three, so it doesn't sound the same every time
        CASE 1 : IF sndHurt2& THEN PlaySfx sndHurt2&, 0.8 ELSE PlaySfx sndHurt&, 0.8
        CASE 2 : IF sndHurt3& THEN PlaySfx sndHurt3&, 0.8 ELSE PlaySfx sndHurt&, 0.8
        CASE ELSE : PlaySfx sndHurt&, 0.8
    END SELECT
END IF
IF hurtElectric THEN PlaySfx sndHurtZap&, 1 ' (a shock - a laser, a live floor: the zap as well as the cry)
hurtElectric = 0
RETURN

' --- Barrel number `barrel` explodes: it hurts everything near it that it
' can see (more the closer it is), lights the fuses of other barrels close
' by, so they go off a moment later, and breaks the other decorations near it
Explode:
decoOn(barrel) = 0 : decoFuse(barrel) = 0 : decoCell(INT(decoX(barrel)), INT(decoY(barrel))) = 0
blastAtX = decoX(barrel) : blastAtY = decoY(barrel) : GOSUB BlastAt
RETURN

' --- An explosion at (blastAtX, blastAtY): a barrel's, or a pressure
' plate's - everything near is hurt, other barrels go off
BlastAt:
SfxAt sndBarrel&, blastAtX, blastAtY, playerX, playerY
FOR k = 1 TO numGlass ' Glass near it shatters
    glassHitX = glassListX(k) : glassHitY = glassListY(k)
    IF glassHP(glassHitX, glassHitY) > 0 THEN
        IF (glassHitX + 0.5 - blastAtX) ^ 2 + (glassHitY + 0.5 - blastAtY) ^ 2 < BLAST_RADIUS * BLAST_RADIUS THEN glassAtX = glassHitX + 0.5 : glassAtY = glassHitY + 0.5 : glassDmg = 99 : GOSUB HitGlass
    END IF
NEXT
newBlastX = blastAtX : newBlastY = blastAtY : newBlastSize = 1 : GOSUB AddBlast
distance = SQR((playerX - blastAtX) ^ 2 + (playerY - blastAtY) ^ 2) ' You feel it from a way off
IF distance < BLAST_RADIUS * 4 THEN shake = shake + 14 * (1 - distance / (BLAST_RADIUS * 4))
FOR j = 1 TO numMonsters
    IF monsterState(j) < 2 THEN
        distance = SQR((monsterX(j) - blastAtX) ^ 2 + (monsterY(j) - blastAtY) ^ 2)
        IF distance < BLAST_RADIUS THEN
            IF CanSee(blastAtX, blastAtY, monsterX(j), monsterY(j)) THEN target = j : hitDamage = INT(8 * (1 - distance / BLAST_RADIUS)) + 1 : GOSUB HitMonster
        END IF
    END IF
NEXT
distance = SQR((playerX - blastAtX) ^ 2 + (playerY - blastAtY) ^ 2)
IF distance < BLAST_RADIUS AND NOT dead THEN
    IF CanSee(blastAtX, blastAtY, playerX, playerY) THEN
        damage = INT(40 * (1 - distance / BLAST_RADIUS)) + 5
        hurtFromX = blastAtX : hurtFromY = blastAtY : GOSUB HurtPlayer
    END IF
END IF
FOR j = 1 TO numDecos
    IF decoOn(j) THEN
        distance = SQR((decoX(j) - blastAtX) ^ 2 + (decoY(j) - blastAtY) ^ 2)
        IF distance < BLAST_RADIUS THEN
            IF Explosive(decoKind(j)) THEN
                IF decoFuse(j) = 0 THEN decoFuse(j) = 8 ' Another barrel (or tank): it goes off in 8 frames
            ELSEIF CanSee(blastAtX, blastAtY, decoX(j), decoY(j)) THEN
                targetDeco = j : hitDamage = INT(4 * (1 - distance / BLAST_RADIUS)) + 1 : GOSUB HitDeco
            END IF
        END IF
    END IF
NEXT
RETURN

' --- A shot (or blast) hits decoration number targetDeco for hitDamage. A
' barrel's fuse is lit (it blows up next frame); anything else loses that
' much from decoHP, and at 0 it breaks: it stops blocking the way at once,
' collapses into the floor over DECO_BREAK_FRAMES (drawn in chapter 16), and
' lamps and terminals go in a small puff of sparks.
' --- THE LEVEL EDITOR (chapter 21) ----------------------------------------
' F2 in the game. Two views of the same level: the map from above
' (RunEditor - a loop of its own, like the menu: paint the map's
' characters with the mouse) and walking round inside it (the game, with
' everything frozen: EditFP - build and knock down where you aim, and
' change the pictures, live). Tab switches; F2 goes back to playing the
' level as it is now; Ctrl+S saves it to its file. Every change goes into
' lvlRow$() and the rest - the level as its file says it - and the level
' is built again from that (EditApply), keeping you where you are.
EditEnter:
WorldLoopsOff ' (the world stops: so do its sounds)
editMode = -1 : editView = 0 : editDirty = 0 : editUndoN = 0 : editLights = 0 : mapOpen = 0
levelWas = level
IF editGlyph$ = "" THEN editGlyph$ = "#"
FOR i = 1 TO MAX_BOLTS : boltOn(i) = 0 : NEXT
EditNote "EDITOR: " + levelName$
RETURN

EditLeave:
editMode = 0 : editView = 0
IF NOT Walkable(playerX, playerY) THEN ' (left inside something: step out to the nearest open cell)
    FOR r = 1 TO 8
        FOR a = 0 TO 15
            tx = INT(playerX + COS(a * 0.3927) * r) + 0.5 : ty = INT(playerY + SIN(a * 0.3927) * r) + 0.5
            IF tx > 0 AND ty > 0 AND tx < MAP_SIZE AND ty < MAP_SIZE THEN IF Walkable(tx, ty) THEN playerX = tx : playerY = ty : r = 99 : EXIT FOR
        NEXT
    NEXT
END IF
IF NOT levelFlat THEN playerZ = floorH(INT(playerX), INT(playerY)) : playerVZ = 0 ELSE playerZ = 0 ' (down to the floor)
_MOUSEHIDE _DISABLE : WHILE _MOUSEINPUT : WEND
IF editDirty THEN ShowMsg "Left the editor - not saved yet (F2, then Ctrl+S)" ELSE ShowMsg "Left the editor"
RETURN

' Remember the level as it is, for Ctrl+Z
EditPushUndo:
IF editUndoN = EDIT_UNDO THEN
    FOR k = 1 TO EDIT_UNDO - 1 : editUndo$(k) = editUndo$(k + 1) : NEXT
ELSE
    editUndoN = editUndoN + 1
END IF
editUndo$(editUndoN) = EditSnapshot$
RETURN

EditUndo:
IF editUndoN = 0 THEN EditNote "Nothing to undo" : RETURN
EditRestore editUndo$(editUndoN) : editUndoN = editUndoN - 1
GOSUB EditApply : EditNote "Undone"
RETURN

' A toolbar button pressed: tbHit (a TB_ number), in either view (the map
' from above's own loop sees edDone set: Tab's way out to 3D)
EditTBClick:
SELECT CASE tbHit
    CASE TB_SELECT : edTool = ET_SELECT : EditNote EditTBTip$(tbHit)
    CASE TB_PLACE : edTool = ET_PLACE : EditNote EditTBTip$(tbHit)
    CASE TB_LIGHT : edTool = ET_LIGHT : EditNote EditTBTip$(tbHit) + " - " + LightPresetName$(editLightP)
    CASE TB_HEIGHT : edTool = ET_HEIGHT : EditNote EditTBTip$(tbHit)
    CASE TB_DELETE
        IF edSelN THEN GOSUB EditPushUndo : EditDeleteSel : GOSUB EditApply ELSE EditNote "Select something to delete first"
    CASE TB_UNDO : GOSUB EditUndo
    CASE TB_SAVE : EditSave level
    CASE TB_GRID : EditGridKey 0
    CASE TB_ALPHA : edTbDrag = -1 ' (dragged from here, while the button's held)
    CASE TB_VIEW : IF editView = 1 THEN editView = 0 ELSE edDone = 1
    CASE TB_HELP : edHelp = NOT edHelp
    CASE TB_PAINT : edTool = ET_PAINT : EditNote EditTBTip$(tbHit)
    CASE TB_PICK : edPickOn = NOT edPickOn
END SELECT
editLights = (edTool = ET_LIGHT) : editHeights = (edTool = ET_HEIGHT) ' (the map from above's own names for two of the tools)
RETURN

' A picker entry clicked (pkIdx): it's the brush now, and the tool that
' uses it - and with something selected, it's done to the selection: a
' map character put in each cell (a wall's: the cell in front of it), a
' picture painted on each face (PAINT, EditPaintSel)
EditPkClick:
SELECT CASE edPkKind(pkIdx)
    CASE PK_GLYPH
        editGlyph$ = edPkVal$(pkIdx) : edBrushKind = PK_GLYPH : edTool = ET_PLACE
        IF edSelN THEN
            GOSUB EditPushUndo : n = 0
            FOR k = 1 TO edSelN
                EditFaceCell edSelKind(k), edSelX(k), edSelY(k), edSelSide(k), tx, ty
                IF tx > 0 AND ty > 0 AND tx < MAP_SIZE - 1 AND ty < MAP_SIZE - 1 THEN EditPut tx, ty, editGlyph$ : n = n + 1
            NEXT
            GOSUB EditApply : EditNote GlyphName$(editGlyph$) + ": put in" + STR$(n) + " cells"
        ELSE
            EditNote "PLACE " + GlyphName$(editGlyph$) + ": click where it goes"
        END IF
    CASE PK_TEX
        edBrushTex$ = edPkVal$(pkIdx) : edBrushKind = PK_TEX : edTool = ET_PAINT
        IF edBrushImg& < -1 THEN _FREEIMAGE edBrushImg&
        edBrushImg& = EditFileThumb&(edBrushTex$)
        IF edSelN THEN GOSUB EditPaintSel ELSE EditNote "PAINT " + edBrushTex$ + ": click a face"
    CASE PK_LIGHT
        editLightP = VAL(edPkVal$(pkIdx)) : edBrushKind = PK_LIGHT : edTool = ET_LIGHT
        EditNote "LIGHT " + LightPresetName$(editLightP) + ": click a face to light it"
END SELECT
editLights = (edTool = ET_LIGHT) : editHeights = (edTool = ET_HEIGHT)
RETURN

' The brush's picture on every face selected
EditPaintSel:
GOSUB EditPushUndo
FOR k = 1 TO edSelN
    EditSetFace edSelX(k), edSelY(k), EditFaceCode(edSelKind(k), edSelSide(k)), 0, edBrushTex$, ""
NEXT
GOSUB EditApply : EditNote edBrushTex$ + " on" + STR$(edSelN) + " faces"
RETURN

' The grid slider, dragged: how strong, from where the pointer is along it
EditTBSlide:
EditTBLayout editView
FOR k = 1 TO edTbN
    IF edTbId(k) = TB_ALPHA THEN
        a = (tbMX - edTbX(k) - 2) * 255 / (edTbW(k) - 4)
        IF a < 16 THEN a = 16
        IF a > 255 THEN a = 255
        edGridAlpha = a : edGrid = -1
    END IF
NEXT
RETURN

' Build the level again from lvlRow$() and the rest, keeping you where you
' are (and pointing where you were)
EditApply:
keepX = playerX : keepY = playerY : keepDX = dirX : keepDY = dirY
editRebuild = -1 : GOSUB BuildLevel : editRebuild = 0
playerX = keepX : playerY = keepY : dirX = keepDX : dirY = keepDY
planeX = dirY * fovPlane : planeY = -dirX * fovPlane ' (in the editor you fly through walls, so building over where you are is fine)
editDirty = -1
RETURN

' The map from above: draw it, read the mouse and keys, until Tab (walk
' round inside it) or F2 / Esc (back to the game)
RunEditor:
_MOUSESHOW : _KEYCLEAR
edDone = 0 : edDown = 0 : edRect = 0 : edTbDown = -1 : edB1 = -1 ' (a button still held from the other view isn't a click here)
DO
    _LIMIT 60
    mx = edMX : my = edMY : wheel = 0
    WHILE _MOUSEINPUT
        mx = _MOUSEX : my = _MOUSEY : wheel = wheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN b1 = -1 ELSE b1 = 0
        IF _MOUSEBUTTON(2) THEN b2 = -1 ELSE b2 = 0
    WEND
    edMX = mx : edMY = my
    cx = INT((mx - ED_MAPX) / ED_CELL) : cy = INT((my - ED_MAPY) / ED_CELL)
    onMap = (mx >= ED_MAPX AND my >= ED_MAPY AND cx < MAP_SIZE AND cy < MAP_SIZE)
    shiftOn = _KEYDOWN(100304) OR _KEYDOWN(100303)
    IF wheel THEN EditCycleGlyph SGN(wheel)
    ' The toolbar (and the help: a click anywhere puts it away) - a press
    ' there is the toolbar's till it's let go, never paint
    tbHit = EditTBAt(mx, my, 0)
    IF b1 AND NOT edB1 THEN
        IF edHelp THEN
            edHelp = 0 : edTbDown = -1
        ELSEIF tbHit THEN
            GOSUB EditTBClick : edTbDown = -1
        END IF
    END IF
    IF b1 AND edTbDrag THEN tbMX = mx : GOSUB EditTBSlide
    IF NOT b1 THEN edTbDrag = 0 : edTbDown = 0
    edB1 = b1
    IF edTbDown OR edHelp THEN onMap = 0
    editLights = (edTool = ET_LIGHT) : editHeights = (edTool = ET_HEIGHT)
    ' The palette: click one to choose it
    pg = EditPaletteAt(mx, my) : IF edTbDown OR edHelp THEN pg = 0
    IF b1 AND NOT edDown AND pg > 0 THEN editGlyph$ = MID$(EDIT_GLYPHS, pg, 1)
    ' Painting: press, drag, let go (one undo for the whole stroke); with
    ' Shift, a rectangle from where you pressed to where you let go
    IF onMap AND editHeights THEN ' The heights: click raises the floor an eighth, right-click lowers it (Shift: the ceiling)
        IF b1 AND NOT edDown THEN GOSUB EditPushUndo : EditRaise cx, cy, H_STEP, shiftOn : edDown = -1 : edApply = -1
        IF b2 AND NOT edB2 THEN GOSUB EditPushUndo : EditRaise cx, cy, -H_STEP, shiftOn : edApply = -1
    END IF
    IF onMap AND edTool = ET_SELECT THEN ' Selecting: press, drag a box, let go (Shift adds to what's selected)
        IF b1 AND NOT edDown THEN edDown = -1 : edRect = -1 : edX0 = cx : edY0 = cy : edSelAdd = shiftOn
    END IF
    IF onMap AND (edTool = ET_PLACE OR edTool = ET_PAINT) THEN
        IF b1 AND NOT edDown THEN GOSUB EditPushUndo : edDown = -1 : edRect = shiftOn : edX0 = cx : edY0 = cy
        IF b1 AND edDown AND NOT edRect THEN EditPut cx, cy, editGlyph$
        IF b2 THEN c$ = MID$(lvlRow$(cy), cx + 1, 1) : IF c$ <> editGlyph$ THEN editGlyph$ = c$ : EditNote "Picked " + GlyphName$(c$)
    END IF
    IF onMap AND editLights THEN ' The lights: click to add one, right-click to take the nearest away
        IF b1 AND NOT edDown THEN GOSUB EditPushUndo : EditAddLight cx + 0.5, cy + 0.5 : edDown = -1 : edApply = -1
        IF b2 AND NOT edB2 THEN GOSUB EditPushUndo : EditRemoveLight cx + 0.5, cy + 0.5 : edApply = -1
    END IF
    edB2 = b2
    IF NOT b1 AND edDown THEN ' Let go: the rectangle, then build it (or select it)
        IF edRect AND onMap AND edTool = ET_SELECT THEN
            IF NOT edSelAdd THEN edSelN = 0
            IF edSelAdd AND edX0 = cx AND edY0 = cy THEN
                EditSelToggle ED_FLOOR, cx, cy, 0, 0 ' (Shift+click one cell: in or out)
            ELSE
                FOR y = MinOf(edY0, cy) TO MaxOf(edY0, cy) : FOR x = MinOf(edX0, cx) TO MaxOf(edX0, cx)
                    IF EditSelIndex(ED_FLOOR, x, y, 0, 0) = 0 THEN EditSelToggle ED_FLOOR, x, y, 0, 0
                NEXT : NEXT
            END IF
            EditNote LTRIM$(STR$(edSelN)) + " selected"
        ELSEIF edRect AND onMap THEN
            FOR y = MinOf(edY0, cy) TO MaxOf(edY0, cy) : FOR x = MinOf(edX0, cx) TO MaxOf(edX0, cx) : EditPut x, y, editGlyph$ : NEXT : NEXT
        END IF
        IF edTool <> ET_SELECT THEN edApply = -1
        edDown = 0 : edRect = 0
    END IF
    IF edApply THEN edApply = 0 : GOSUB EditApply
    ' Keys
    k& = _KEYHIT
    DO WHILE k&
        IF _KEYDOWN(100305) OR _KEYDOWN(100306) THEN ' (Ctrl held: Ctrl+S, Ctrl+Z - however the key arrives)
            IF k& = 115 OR k& = 83 THEN k& = 19
            IF k& = 122 OR k& = 90 THEN k& = 26
            IF k& = 100 OR k& = 68 THEN k& = 4
        END IF
        SELECT CASE k&
            CASE 4 : edSelN = 0 : EditNote "Selection cleared" ' Ctrl+D
            CASE 21248 ' Del: delete what's selected
                IF edSelN THEN GOSUB EditPushUndo : EditDeleteSel : GOSUB EditApply ELSE EditNote "Select something to delete first"
            CASE 15104 : edHelp = NOT edHelp ' F1: the help
            CASE 18432, 20480, 19200, 19712 ' The arrows: move the selection a cell (up the screen is north)
                IF edSelN THEN
                    ndx = 0 : ndy = 0
                    SELECT CASE k&
                        CASE 18432 : ndy = -1
                        CASE 20480 : ndy = 1
                        CASE 19200 : ndx = -1
                        CASE ELSE : ndx = 1
                    END SELECT
                    GOSUB EditPushUndo : EditNudge ndx, ndy : GOSUB EditApply
                ELSE
                    EditNote "Select something first: the arrows move it a cell"
                END IF
            CASE 9 : edDone = 1 ' Tab: walk round inside it
            CASE 27, 15360 : edDone = 2 ' Esc, F2: back to the game
            CASE 19 : EditSave level ' Ctrl+S
            CASE 26 : GOSUB EditUndo ' Ctrl+Z
            CASE 108, 76 ' L: the light tool (again: back to placing)
                IF edTool = ET_LIGHT THEN edTool = ET_PLACE ELSE edTool = ET_LIGHT
                IF edTool = ET_LIGHT THEN EditNote "LIGHTS: click adds, right-click takes away, 1-8 the colour" ELSE EditNote "PLACE: paint with the mouse"
            CASE 104, 72 ' H: the height tool
                IF edTool = ET_HEIGHT THEN edTool = ET_PLACE ELSE edTool = ET_HEIGHT
                IF edTool = ET_HEIGHT THEN EditNote "HEIGHTS: click raises the floor, right-click lowers it (Shift: the ceiling)" ELSE EditNote "PLACE: paint with the mouse"
            CASE 49 TO 56 : editLightP = k& - 49 : EditNote "Light: " + LightPresetName$(editLightP)
            CASE 116, 84 ' T: teleport you to the cell under the mouse
                IF onMap THEN playerX = cx + 0.5 : playerY = cy + 0.5 : EditNote "You're at" + STR$(cx) + STR$(cy) + " (Tab to look)"
            CASE 18688 : GOSUB EditOtherLevel_Prev ' PgUp: the sector before
            CASE 20736 : GOSUB EditOtherLevel_Next ' PgDn: the one after
            CASE 91 : EditCycleGlyph -1 ' [ ]: the glyph before, after
            CASE 93 : EditCycleGlyph 1
            CASE 109, 77 : GOSUB RunMonsterEditor : _MOUSESHOW ' M: the monster editor
            CASE 103, 71 : EditGridKey shiftOn ' G: the grid on / off (Shift+G: how strong)
            CASE 117, 85 : edDone = 1 : hudAfter = -1 ' U: the HUD layout editor (over the game: walking view)
        END SELECT
        k& = _KEYHIT
    LOOP
    IF edDone THEN EXIT DO
    DrawEditor cx, cy, onMap, edRect AND edDown, edX0, edY0, playerX, playerY, dirX, dirY, level, levelName$
    EditDrawTB 0, mx, my
    IF edHelp THEN EditDrawHelp 0
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
_KEYCLEAR
IF edDone = 1 THEN editView = 1 : edMouseFix = -1 : fpLWas = -1 : EditNote "3D: point at a face - hold the right button to look round - H for help"
IF hudAfter THEN hudAfter = 0 : GOSUB HudEditEnter
IF edDone = 2 THEN GOSUB EditLeave
WHILE _MOUSEINPUT : WEND
escWas = -1 : fireWait = 10
RETURN

' --- CHAPTER 6's pictures, all of them (and again when ART changes) -----
' These are the ones every level shares. Some pictures are made rather than loaded: the keycards and key doors are
' one picture tinted three colours, each monster gets a second, red-washed
' copy to flash when it's hit, and the bolt is drawn with maths (MakeBolt).
LoadPictures:
LoadTex "door.png", T_DOOR
LoadTex "door-shutter.png", T_SHUTTER
LoadTex "door-split.png", T_SPLIT
LoadTex "exit.png", T_EXIT : ExitSign
LoadTex "ceiling-lamp.png", T_LAMP : MakeLampOff
LoadTex "wall-jack.png", T_JACK ' (a data station)
LoadTex "wall-code.png", T_CODE ' (a code terminal)
LoadCards "keycard.png"
LoadSprite "medkit.png", 4
LoadSprite "ammo.png", 5
LoadSprite "shells.png", 6
LoadSprite "pickup-scatter.png", 7
LoadSprite "pickup-repeater.png", 8
LoadSprite "drone.png", 9
LoadSprite "gunner.png", 11
LoadSprite "heavy.png", 13
LoadSprite "crawler.png", 15
LoadSprite "sentry.png", 17
FOR slot = 9 TO 17 STEP 2 : MakeHurt slot, slot + 1 : NEXT ' (each one's hit flash, in the next slot)
MakeBolt S_BOLT
LoadSprite "barrel.png", S_DECO + 1
LoadSprite "lamp.png", S_DECO + 2
LoadSprite "plant.png", S_DECO + 3
LoadSprite "terminal.png", S_DECO + 4
LoadSprite "crate.png", DecoSlot(5) : LoadSprite "rack.png", DecoSlot(6)
LoadSprite "vending.png", DecoSlot(7) : LoadSprite "tank.png", DecoSlot(8) : LoadSprite "spawner.png", DecoSlot(9)
' The set pieces (10-19): desk, control console, monitor bank, specimen
' tank, lab bench, generator, cryo pod, hologram, lockers, bench
FOR k = 10 TO DECO_KINDS : LoadSprite DecoFile$(k), DecoSlot(k) : NEXT
LoadSprite "overcharge.png", ItemSprite(IT_OVERCHARGE) : LoadSprite "amp.png", ItemSprite(IT_AMP) : LoadSprite "core.png", ItemSprite(IT_CORE)
MakeGlass S_GLASS, 0 : MakeGlass S_GLASS + 1, -1 ' (glass, whole and cracked)
MakePad S_PAD ' (a teleporter's pad)
LoadSprite "plate.png", S_PLATE : MakeLaser S_LASER ' (traps: a pressure plate, a laser beam)
LoadSprite "explosion.png", S_BLAST : MakeBoomFrames ' (and its animation)
LoadSprite "armor.png", 25
LoadSprite "bigmed.png", 26
LoadSprite "pickup-rail.png", 27
LoadSprite "map.png", 28
' The newer monsters' pictures: each, then itself hurt (MakeHurt: flashed red)
FOR mtype = 6 TO MON_TYPES
    LoadSprite mtypeName$(mtype) + ".png", mtypeSprite(mtype) : MakeHurt mtypeSprite(mtype), mtypeSprite(mtype) + 1
NEXT
FOR mtype = 1 TO MON_TYPES : MakeCorpse mtype : NEXT ' (each one's body, for when it's dead)
FOR k = 1 TO DECO_KINDS : MakeWreck k : NEXT ' (each decoration, broken)
FOR mtype = 1 TO MON_TYPES : MakeMonFrames mtype : NEXT ' (each one's animation)
MakeScorch ' (a scorch mark, for the software renderer's decals)
LoadGun 1, "gun.png"
LoadGun 2, "gun-scatter.png"
LoadGun 3, "gun-repeater.png"
LoadGun 4, "gun-rail.png"
glGunVersion = glGunVersion + 1 ' (OpenGL's copies of them, again)
IF nexusImg& < -1 THEN _FREEIMAGE nexusImg&
nexusImg& = _LOADIMAGE(ArtPath$("nexus.png"), 32)
IF kickImg& < -1 THEN _FREEIMAGE kickImg&
kickImg& = _LOADIMAGE(ArtPath$("kick.png"), 32) ' The boot (chapter 18); missing, there's no boot to see
RETURN

' --- ART (SETTINGS > VIDEO): every picture again, the size the setting
' wants (artWant: ApplySettings) - CLASSIC: textures 128 and sprites 64
' pixels across, the pixel art in neon-caster/; MODERN: the paintings in
' neon-caster/hd/ (ArtPath$), at 512 and 256 with OpenGL (which draws them
' smooth), shrunk to 128 and 64 for the software renderer. OpenGL is held
' off first (artHold, till it says so - glArtAck): it reads these arrays
' from its own thread, and REDIM moves them.
ArtReload:
artHold = -1 : glArtAck = 0
IF glReady THEN
    artT0! = TIMER
    DO WHILE glArtAck = 0 AND ABS(TIMER - artT0!) < 1 : _LIMIT 500 : LOOP
END IF
artNow = artWant
IF artNow = 2 THEN texSize = 512 : sprTex = 256 ELSE texSize = 128 : sprTex = 64
REDIM texture(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG
REDIM texBak(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG
REDIM glUpload(texSize * texSize - 1) AS _UNSIGNED LONG
REDIM spriteTex(sprTex - 1, sprTex - 1, SPR_SLOTS) AS _UNSIGNED LONG
GOSUB LoadPictures
FOR k = 1 TO T_SLOTS ' The level's own walls, floors and ceilings, again
    IF texFile$(k) <> "" THEN LoadTex texFile$(k), k
NEXT
IF cyberOn THEN CyberTextures -1 ' (in the network: its grid, at the new size)
MakeLiftTex ' (the lifts' pictures, made again from the new ones)
glTexVersion = glTexVersion + 1 : glRetexVersion = glRetexVersion + 1
artHold = 0
RETURN

EditOtherLevel_Prev: ' (the one before - past any of yours not made)
FOR n = level - 1 TO 1 STEP -1
    IF SectorExists(n) THEN level = n : GOSUB EditGoLevel : RETURN
NEXT
RETURN
EditOtherLevel_Next:
FOR n = level + 1 TO NUM_LEVELS + MAX_CUSTOM
    IF SectorExists(n) THEN level = n : GOSUB EditGoLevel : RETURN
NEXT
RETURN
EditGoLevel:
IF editDirty THEN EditNote "Save first (Ctrl+S) - or Ctrl+Z it all away" : level = levelWas : RETURN
GOSUB LoadLevel : editUndoN = 0 : editDirty = 0 : levelWas = level
EditNote "EDITOR: " + levelName$
RETURN

' --- THE WHEEL in the 3D editor: on the selection - or, with nothing
' selected, on the face under the pointer. Up raises, down lowers, an
' eighth of a wall a turn (Ctrl: a whole wall):
'   a floor, a step's face        its floor (the step's top)
'   a ceiling, a lintel's face    its ceiling (the lintel's bottom)
'   a wall's side                 nothing on its own - with a key held:
'     Shift          pull it out a cell towards you (up) / push it back (down)
'     Alt            push it back a cell (up) / pull it out (down)
'     Ctrl+Shift     make it a block standing on the floor, and set its top
'     Alt+Shift      make it a block hanging from the ceiling, and set its bottom
' The selection follows a face that moves, so turning on keeps going. One
' undo for a run of turns (a pause of half a second starts a new one).
EditWheel:
ticks = -SGN(edWheel) * MinOf(ABS(edWheel), 8) : IF ticks = 0 THEN RETURN
wShift = _KEYDOWN(100304) OR _KEYDOWN(100303) : wCtrl = _KEYDOWN(100305) OR _KEYDOWN(100306) : wAlt = _KEYDOWN(100307) OR _KEYDOWN(100308)
IF edSelN = 0 AND edHovKind = 0 THEN EditNote "Point at a face (or select some) to change it with the wheel" : RETURN
IF ABS(TIMER - edWheelT!) > 0.5 THEN GOSUB EditPushUndo
edWheelT! = TIMER
IF edSelN = 0 THEN EditSelToggle edHovKind, edHovX, edHovY, edHovSide, 0 ' (nothing selected: the face under the pointer - and it stays selected, so turning on keeps working on it)
dz = ticks * H_STEP : IF wCtrl AND NOT wShift THEN dz = ticks * 1
wCount = 0
FOR wk = 1 TO edSelN
    wx = edSelX(wk) : wy = edSelY(wk) : ws = edSelSide(wk)
    SELECT CASE edSelKind(wk)
        CASE ED_FLOOR, ED_STEP : EditRaise wx, wy, dz, 0 : wCount = wCount + 1
        CASE ED_CEIL, ED_LINTEL : EditRaise wx, wy, dz, -1 : wCount = wCount + 1
        CASE ED_WALL
          FOR wt = 1 TO ABS(ticks) ' (a cell a turn)
            wx = edSelX(wk) : wy = edSelY(wk) : IF edSelKind(wk) <> ED_WALL THEN EXIT FOR
            EditFaceFront wx, wy, ws, fx, fy ' (the open cell the face looks into)
            wDir = 0
            IF wShift AND NOT wCtrl AND NOT wAlt THEN wDir = SGN(ticks) ' (+1 pull, -1 push)
            IF wAlt AND NOT wShift THEN wDir = -SGN(ticks)
            IF wDir > 0 AND fx > 0 AND fy > 0 AND fx < MAP_SIZE - 1 AND fy < MAP_SIZE - 1 THEN ' Pull: the cell in front becomes this wall
                EditPut fx, fy, MID$(lvlRow$(wy), wx + 1, 1) : edSelX(wk) = fx : edSelY(wk) = fy : wCount = wCount + 1
            ELSEIF wDir < 0 AND wx > 0 AND wy > 0 AND wx < MAP_SIZE - 1 AND wy < MAP_SIZE - 1 THEN ' Push: this wall's cell opens, like the one in front
                EditPut wx, wy, "."
                MID$(lvlFloorRow$(wy), wx + 1, 1) = MID$(lvlFloorRow$(fy), fx + 1, 1) : MID$(lvlCeilRow$(wy), wx + 1, 1) = MID$(lvlCeilRow$(fy), fx + 1, 1)
                bx = wx + (wx - fx) : by = wy + (wy - fy) : edSelX(wk) = bx : edSelY(wk) = by : wCount = wCount + 1 ' (the face is now the cell behind's - if it's a wall)
            ELSEIF wCtrl AND wShift AND wx > 0 AND wy > 0 AND wx < MAP_SIZE - 1 AND wy < MAP_SIZE - 1 THEN ' A block on the floor: open, its floor just under the ceiling
                EditPut wx, wy, "."
                MID$(lvlCeilRow$(wy), wx + 1, 1) = MID$(lvlCeilRow$(fy), fx + 1, 1)
                MID$(lvlFloorRow$(wy), wx + 1, 1) = HeightChar$(ceilH(fx, fy) - 0.25 + MinOf(0, dz), 0)
                edSelKind(wk) = ED_STEP : wCount = wCount + 1
            ELSEIF wAlt AND wShift AND wx > 0 AND wy > 0 AND wx < MAP_SIZE - 1 AND wy < MAP_SIZE - 1 THEN ' A block from the ceiling: open, its ceiling just over the floor
                EditPut wx, wy, "."
                MID$(lvlFloorRow$(wy), wx + 1, 1) = MID$(lvlFloorRow$(fy), fx + 1, 1)
                MID$(lvlCeilRow$(wy), wx + 1, 1) = HeightChar$(floorH(fx, fy) + 0.25 + MaxOf(0, dz), 1)
                edSelKind(wk) = ED_LINTEL : wCount = wCount + 1
            END IF
            IF wCtrl OR (wAlt AND wShift) THEN EXIT FOR ' (a block's made once; turning on moves its top or bottom)
          NEXT
    END SELECT
NEXT
' (a pushed face whose new cell isn't a wall is no face at all: drop it)
FOR wk = edSelN TO 1 STEP -1
    IF edSelKind(wk) = ED_WALL THEN
        IF worldMap(edSelX(wk), edSelY(wk)) <= 0 AND MID$(lvlRow$(edSelY(wk)), edSelX(wk) + 1, 1) = "." THEN EditSelToggle ED_WALL, edSelX(wk), edSelY(wk), edSelSide(wk), edSelPart(wk)
    END IF
NEXT
GOSUB EditApply
IF wCount = 0 THEN
    EditNote "Walls: Shift+wheel pulls out / pushes back a cell, Alt pushes, Ctrl+Shift a block's top, Alt+Shift a block's bottom"
ELSEIF edSelN = 1 THEN
    SELECT CASE edSelKind(1)
        CASE ED_FLOOR, ED_STEP : EditNote "Floor" + STR$(floorH(edSelX(1), edSelY(1)) * 8) + " eighths"
        CASE ED_CEIL, ED_LINTEL : EditNote "Ceiling" + STR$(ceilH(edSelX(1), edSelY(1)) * 8) + " eighths"
        CASE ELSE : EditNote "Wall at" + STR$(edSelX(1)) + STR$(edSelY(1))
    END SELECT
ELSE
    EditNote LTRIM$(STR$(wCount)) + " faces changed"
END IF
RETURN

' Walking round inside the level: the keys and the mouse buttons, each
' frame (the game loop draws it; EditOverlay shows what you're aiming at)
EditFP:
IF hudEdit THEN RETURN ' (the HUD layout editor has the mouse and keys)
levelWas = level
edCamPX = playerX : edCamPY = playerY : edCamDX = dirX : edCamDY = dirY : edCamPlane = fovPlane / zoom : edCamZoom = zoom
IF edLooking THEN EditPick 400, 300 ELSE EditPick edCurX, edCurY ' (looking round: the crosshair picks)
IF NOT edLooking AND EditOverUI(edCurX, edCurY) THEN edHovKind = 0 ' (over the toolbar or picker: no face)
EditAim playerX, playerY, dirX, dirY, aimX, aimY, frontX, frontY
fpL = _MOUSEBUTTON(1) OR edClickL : fpR = _MOUSEBUTTON(2) OR edClickR ' (a click between two frames counts too)
IF edClickL AND fpLWas THEN fpLWas = 0 ' (a fresh click, even if the button looked held)
IF edClickR AND fpRWas THEN fpRWas = 0
edClickL = 0 : edClickR = 0
' A click selects the face under the pointer - it never builds anything.
' Shift+click adds it to the selection (or takes it out); Ctrl+click takes
' the whole floor (or ceiling) it's part of - every cell joined to it at
' the same height; clicking nothing clears the selection.
' With another tool, a click does that tool's thing to the face instead;
' on the toolbar, it's the toolbar's.
tbHit = 0 : IF NOT edLooking THEN tbHit = EditTBAt(edCurX, edCurY, 1)
IF fpL AND NOT fpLWas AND NOT edLooking AND edHelp THEN
    edHelp = 0 : fpLWas = -1 ' (the help was up: the click puts it away)
ELSEIF fpL AND NOT fpLWas AND tbHit THEN
    GOSUB EditTBClick
ELSEIF fpL AND NOT fpLWas AND NOT edLooking AND edPickOn THEN
    EditPkHit edCurX, edCurY, pkWhat, pkIdx
    SELECT CASE pkWhat
        CASE 1 : edPickTab = pkIdx : edPickScroll = 0
        CASE 2 : GOSUB EditPkClick
        CASE 3 : edPickScroll = MaxOf(0, edPickScroll - 1)
        CASE 4 : IF (edPickScroll + PK_ROWS) * PK_COLS < edPkN THEN edPickScroll = edPickScroll + 1
    END SELECT
END IF
IF fpL AND edTbDrag THEN tbMX = edCurX : GOSUB EditTBSlide
IF NOT fpL THEN edTbDrag = 0
IF fpL AND NOT fpLWas AND NOT edLooking AND NOT EditOverUI(edCurX, edCurY) AND edTool <> ET_SELECT THEN
    edShift = _KEYDOWN(100304) OR _KEYDOWN(100303)
    IF edHovKind = 0 THEN
        EditNote "Point at a face"
    ELSE
        EditFaceCell edHovKind, edHovX, edHovY, edHovSide, tx, ty
        SELECT CASE edTool
            CASE ET_PLACE
                IF tx < 1 OR ty < 1 OR tx > MAP_SIZE - 2 OR ty > MAP_SIZE - 2 THEN
                    EditNote "Not in the border"
                ELSE
                    GOSUB EditPushUndo : EditPut tx, ty, editGlyph$ : GOSUB EditApply
                    EditNote GlyphName$(editGlyph$) + " at" + STR$(tx) + STR$(ty)
                END IF
            CASE ET_LIGHT
                GOSUB EditPushUndo
                IF edShift THEN EditRemoveLight tx + 0.5, ty + 0.5 ELSE EditAddLight tx + 0.5, ty + 0.5
                GOSUB EditApply
            CASE ET_PAINT ' The brush's picture on the face (Shift: back to the usual; Ctrl: the whole floor or ceiling it's part of)
                fc = EditFaceCode(edHovKind, edHovSide)
                IF (_KEYDOWN(100305) OR _KEYDOWN(100306)) AND (edHovKind = ED_FLOOR OR edHovKind = ED_CEIL) AND edBrushTex$ <> "" THEN
                    EditSelFlood edHovKind, edHovX, edHovY : GOSUB EditPaintSel : edSelN = 0
                ELSEIF edShift THEN
                    GOSUB EditPushUndo : EditSetFace edHovX, edHovY, fc, 0, "", "" : GOSUB EditApply : EditNote "The usual picture again"
                ELSEIF edBrushTex$ = "" THEN
                    EditNote "Pick a picture first (the picker: WALLS, FLOORS, CEILINGS)"
                ELSE
                    GOSUB EditPushUndo : EditSetFace edHovX, edHovY, fc, 0, edBrushTex$, "" : GOSUB EditApply
                    EditNote edBrushTex$ + " on " + FaceName$(fc) + " of" + STR$(edHovX) + STR$(edHovY)
                END IF
            CASE ET_HEIGHT
                d = H_STEP : IF edShift THEN d = -H_STEP
                SELECT CASE edHovKind
                    CASE ED_FLOOR, ED_STEP : GOSUB EditPushUndo : EditRaise edHovX, edHovY, d, 0 : GOSUB EditApply : EditNote "Floor" + STR$(floorH(edHovX, edHovY) * 8) + " eighths"
                    CASE ED_CEIL, ED_LINTEL : GOSUB EditPushUndo : EditRaise edHovX, edHovY, d, -1 : GOSUB EditApply : EditNote "Ceiling" + STR$(ceilH(edHovX, edHovY) * 8) + " eighths"
                    CASE ELSE : EditNote "Height: point at a floor or ceiling (walls: the wheel, with Shift)"
                END SELECT
        END SELECT
    END IF
    fpLWas = -1
END IF
IF fpL AND NOT fpLWas AND NOT edLooking AND NOT EditOverUI(edCurX, edCurY) THEN
    edShift = _KEYDOWN(100304) OR _KEYDOWN(100303) : edCtrl = _KEYDOWN(100305) OR _KEYDOWN(100306)
    IF edHovKind THEN
        IF edShift THEN
            EditSelToggle edHovKind, edHovX, edHovY, edHovSide, edHovPart
        ELSEIF edCtrl AND (edHovKind = ED_FLOOR OR edHovKind = ED_CEIL) THEN
            EditSelFlood edHovKind, edHovX, edHovY
        ELSE
            edSelN = 0 : EditSelToggle edHovKind, edHovX, edHovY, edHovSide, edHovPart
        END IF
        EditNote LTRIM$(STR$(edSelN)) + " selected"
    ELSEIF NOT edShift THEN
        edSelN = 0
    END IF
END IF
fpLWas = fpL : fpRWas = fpR
IF edWheel <> 0 AND edPickOn AND edCurY >= PK_Y - 4 AND NOT edLooking THEN ' (over the picker: the wheel scrolls it)
    edPickScroll = edPickScroll + SGN(edWheel) ' (down the wheel: down the list)
    IF (edPickScroll + PK_ROWS - 1) * PK_COLS >= edPkN THEN edPickScroll = edPickScroll - 1
    IF edPickScroll < 0 THEN edPickScroll = 0
    edWheel = 0
END IF
IF edWheel <> 0 AND NOT EditOverUI(edCurX, edCurY) THEN GOSUB EditWheel
edWheel = 0
k& = _KEYHIT
DO WHILE k&
    shiftOn = _KEYDOWN(100304) OR _KEYDOWN(100303)
    IF _KEYDOWN(100305) OR _KEYDOWN(100306) THEN ' (Ctrl held: Ctrl+S, Ctrl+Z, Ctrl+D - however the key arrives)
        IF k& = 115 OR k& = 83 THEN k& = 19
        IF k& = 122 OR k& = 90 THEN k& = 26
        IF k& = 100 OR k& = 68 THEN k& = 4
    END IF
    SELECT CASE k&
        CASE 4 : edSelN = 0 : EditNote "Selection cleared" ' Ctrl+D
        CASE 103, 71 : EditGridKey shiftOn ' G: the grid on / off (Shift+G: how strong)
        CASE 21248 ' Del: delete what's selected
            IF edSelN THEN GOSUB EditPushUndo : EditDeleteSel : GOSUB EditApply ELSE EditNote "Select something to delete first"
        CASE 15104 : edHelp = NOT edHelp ' F1: the help
        CASE 112, 80 : edPickOn = NOT edPickOn ' P: the picker
        CASE 18432, 20480, 19200, 19712 ' The arrows: nudge the selection a cell - away, back, left, right of the way you face
            IF edSelN THEN
                fwX = 0 : fwY = 0 : IF ABS(edCamDX) >= ABS(edCamDY) THEN fwX = SGN(edCamDX) ELSE fwY = SGN(edCamDY)
                SELECT CASE k&
                    CASE 18432 : ndx = fwX : ndy = fwY
                    CASE 20480 : ndx = -fwX : ndy = -fwY
                    CASE 19200 : ndx = fwY : ndy = -fwX ' (left of facing (fwX, fwY) on the map is (fwY, -fwX))
                    CASE ELSE : ndx = -fwY : ndy = fwX
                END SELECT
                GOSUB EditPushUndo : EditNudge ndx, ndy : GOSUB EditApply
                EditNote "Moved the selection a cell " + RTRIM$(MID$("east  west  south north ", 1 + 6 * (-(ndx < 0) - 2 * (ndy > 0) - 3 * (ndy < 0)), 6))
            ELSE
                EditNote "Select something first: the arrows move it a cell"
            END IF
        CASE 9 : editView = 0 ' Tab: the map from above
        CASE 19 : EditSave level
        CASE 26 : GOSUB EditUndo
        CASE 91 : EditCycleGlyph -1
        CASE 93 : EditCycleGlyph 1
        CASE 101, 69 ' E: pick up what you aim at as the glyph to place
            IF aimX >= 0 THEN editGlyph$ = MID$(lvlRow$(aimY), aimX + 1, 1) : EditNote "Picked " + GlyphName$(editGlyph$)
        CASE 116, 84 ' T: the picture on that kind of wall - every one of them - the next one
            IF aimX >= 0 THEN
                w = INSTR("#NCKPG", MID$(lvlRow$(aimY), aimX + 1, 1))
                IF w THEN GOSUB EditPushUndo : lvlWall$(w) = EditNextPicture$("wall", lvlWall$(w), 1 + 2 * shiftOn) : GOSUB EditApply : EditNote "Walls " + MID$("#NCKPG", w, 1) + ": " + lvlWall$(w)
            END IF
        CASE 102, 70 ' F: the floor's picture (that floor number, everywhere)
            IF frontX >= 0 THEN n = FloorNumberAt(frontX, frontY) : GOSUB EditPushUndo : lvlFloor$(n) = EditNextPicture$("floor", lvlFloor$(n), 1 + 2 * shiftOn) : GOSUB EditApply : EditNote "Floor" + STR$(n) + ": " + lvlFloor$(n)
        CASE 118, 86 ' V: the ceiling's
            IF frontX >= 0 THEN n = CeilNumberAt(frontX, frontY) : GOSUB EditPushUndo : lvlCeil$(n) = EditNextPicture$("ceiling", lvlCeil$(n), 1 + 2 * shiftOn) : GOSUB EditApply : EditNote "Ceiling" + STR$(n) + ": " + lvlCeil$(n)
        CASE 122, 90 ' Z: that cell's floor - the next of the level's four (a zone one cell big)
            IF frontX >= 0 THEN
                n = FloorNumberAt(frontX, frontY) MOD 4 + 1
                GOSUB EditPushUndo : EditAddZone frontX, frontY, frontX, frontY, n, 0 : GOSUB EditApply : EditNote "Floor" + STR$(n) + " here"
            END IF
        CASE 108, 76 ' L: a light over the cell in front; K: take away the nearest
            IF frontX >= 0 THEN GOSUB EditPushUndo : EditAddLight frontX + 0.5, frontY + 0.5 : GOSUB EditApply
        CASE 107, 75
            GOSUB EditPushUndo : EditRemoveLight playerX, playerY : GOSUB EditApply
        CASE 49 TO 56 : editLightP = k& - 49 : EditNote "Light: " + LightPresetName$(editLightP)
        CASE 18688, 20736 ' PgUp / PgDn: the floor in front up or down an eighth (with Shift, its ceiling)
            IF frontX >= 0 THEN
                d = H_STEP : IF k& = 20736 THEN d = -H_STEP
                GOSUB EditPushUndo : EditRaise frontX, frontY, d, shiftOn : GOSUB EditApply
                EditNote "Floor" + STR$(floorH(frontX, frontY)) + "   ceiling" + STR$(ceilH(frontX, frontY))
            END IF
        CASE 117, 85 ' U: the HUD layout editor
            GOSUB HudEditEnter : EXIT DO
        CASE 104, 72 : edHelp = NOT edHelp ' H: the help
    END SELECT
    k& = _KEYHIT
LOOP
RETURN

' --- THE LEVEL'S TRIGGERS AND TELEPORTERS (chapter 19), each frame. A
' trigger's commands go to the console's queue (chapter 21), to be run
' from the next frame - the same commands you can type
RunTriggers:
FOR k = 1 TO numTrigs
    IF NOT trigDone(k) THEN
        fire = 0
        SELECT CASE trigWhen$(k)
            CASE "enter"
                inside = playerX >= trigX0(k) AND playerX < trigX1(k) + 1 AND playerY >= trigY0(k) AND playerY < trigY1(k) + 1
                IF inside AND NOT trigWas(k) AND NOT dead THEN fire = -1
                trigWas(k) = inside
            CASE "clear"
                alive = 0 : started = 0
                FOR j = 1 TO monStartN
                    IF monStartX(j) >= trigX0(k) AND monStartX(j) < trigX1(k) + 1 AND monStartY(j) >= trigY0(k) AND monStartY(j) < trigY1(k) + 1 THEN
                        started = started + 1 : IF monsterState(j) < 2 THEN alive = alive + 1
                    END IF
                NEXT
                IF started > 0 AND alive = 0 THEN fire = -1
            CASE "time"
                IF TIMER - levelStart! >= trigX0(k) OR TIMER < levelStart! THEN fire = -1
        END SELECT
        IF fire THEN trigRun$ = trigCmd$(k) : trigDone(k) = NOT trigRepeat(k) : GOSUB TriggerRun
    END IF
NEXT
' Teleporters: on a pad - and you've stepped off one since - to its partner
onPad = 0
FOR k = 1 TO numPads
    IF INT(playerX) = padX(k) AND INT(playerY) = padY(k) THEN onPad = k
NEXT
IF onPad = 0 THEN padReady = -1
IF onPad > 0 AND padReady AND NOT dead THEN
    other = onPad + 1 : IF onPad MOD 2 = 0 THEN other = onPad - 1
    IF other >= 1 AND other <= numPads THEN
        SpawnSparks playerX, playerY, 0.4, 20, 150, 90, 255
        playerX = padX(other) + 0.5 : playerY = padY(other) + 0.5 : playerZ = floorH(padX(other), padY(other)) : eyeZ = playerZ + EYE_H : playerVZ = 0
        SpawnSparks playerX, playerY, 0.4, 30, 150, 90, 255
        PlaySfx sndTeleport&, 1 : pickFlash = 16 : padReady = 0
    END IF
END IF
RETURN

' A trigger's commands (trigRun$), run now - one after another, split at
' the ;s - unless there's a wait among them: then onto the console's queue,
' to run a frame at a time (chapter 21)
TriggerRun:
IF INSTR(LCASE$(trigRun$), "wait") THEN ConQueue trigRun$ : RETURN
trigK = k ' (ConExec uses k)
DO WHILE LEN(trigRun$)
    semi = INSTR(trigRun$, ";")
    IF semi THEN conCmd$ = LEFT$(trigRun$, semi - 1) : trigRun$ = MID$(trigRun$, semi + 1) ELSE conCmd$ = trigRun$ : trigRun$ = ""
    GOSUB ConExec
LOOP
k = trigK
RETURN

' --- A CODE TERMINAL, terminal tm (chapter 19): the doors near it slam
' and lock, NEXUS gloats, and its puzzle opens; solved, they open again
TerminalUse:
pzName$ = ListItem$(lvlPuzzles$, tm) : IF pzName$ = "" THEN pzName$ = MID$("hello     multiply  countdownpassword  sum       pythagoraselect    function  reverse   wrap      ", ((level - 1) MOD 10) * 10 + 1, 10)
pzName$ = LTRIM$(RTRIM$(pzName$))
IF NOT LoadPuzzle(pzName$) THEN ShowMsg "TERMINAL: no program called " + pzName$ : RETURN
slammed = 0
FOR y = termY(tm) - 7 TO termY(tm) + 7 : FOR x = termX(tm) - 7 TO termX(tm) + 7
    IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN
        IF worldMap(x, y) = 2 AND doorType(x, y) <> DOOR_EXIT AND doorLock(x, y) = 0 THEN
            doorLock(x, y) = 3 : doorMove(x, y) = -1 : slammed = slammed + 1
            SfxAt DoorSnd&(doorType(x, y)), x + 0.5, y + 0.5, playerX, playerY
        END IF
    END IF
NEXT : NEXT
IF slammed THEN PlaySfx sndAlarm&, 0.8 : shake = shake + 8
Say "puzzle1", 0
GOSUB RunPuzzle
IF pzSolved THEN
    termDone(tm) = -1
    FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
        IF doorLock(x, y) = 3 THEN doorLock(x, y) = 0 : doorMove(x, y) = 1 : IF doorOpen(x, y) = 0 THEN doorOpen(x, y) = 0.01
    NEXT : NEXT
    PlaySfx sndFanfare&, 0.9 : ShowMsg "PROGRAM REPAIRED - the doors are open" : Say "puzzle2", 0
ELSE
    ShowMsg "The doors stay locked - the terminal's still waiting"
END IF
RETURN

' --- THE HUD LAYOUT EDITOR (chapter 21): the game goes on behind (frozen,
' as in the level editor); every part of the HUD is drawn with a box round
' it (HudEditDraw). Drag one with the mouse; Tab the next one; the arrows
' nudge it (Shift: 8 pixels); V shows or hides it; C its colour; + and -
' its bar's width, [ and ] its height; S saves hud.txt; R puts back the
' game's own layout; U or Esc leaves.
HudEditEnter:
hudEdit = -1 : hudSel = HE_HEALTH : hudDrag = 0 : _MOUSESHOW : _KEYCLEAR
hudMsg$ = "HUD LAYOUT: drag things about - Tab next, V show/hide, C colour, +/- [ ] bar, S save, R reset, U done"
RETURN
HudEditLeave:
hudEdit = 0 : _MOUSEHIDE _DISABLE : _KEYCLEAR : WHILE _MOUSEINPUT : WEND : escWas = -1 : fireWait = 15 : edMouseFix = -1
RETURN
HudEditFrame:
hmx = _MOUSEX : hmy = _MOUSEY : hb = _MOUSEBUTTON(1)
IF hb AND NOT hudDrag THEN ' Press: the part under the mouse (the smallest, if two overlap)
    best = 0 : bestA = 1E+9
    FOR e = 1 TO HUD_ELEMS
        HudBox e, bx0, by0, bx1, by1
        IF hmx >= bx0 AND hmx <= bx1 AND hmy >= by0 AND hmy <= by1 THEN IF (bx1 - bx0) * (by1 - by0) < bestA THEN bestA = (bx1 - bx0) * (by1 - by0) : best = e
    NEXT
    IF best THEN hudSel = best : hudDrag = -1 : hdx = hmx : hdy = hmy
END IF
IF hb AND hudDrag THEN hudX(hudSel) = hudX(hudSel) + hmx - hdx : hudY(hudSel) = hudY(hudSel) + hmy - hdy : hdx = hmx : hdy = hmy
IF NOT hb THEN hudDrag = 0
k& = _KEYHIT
DO WHILE k&
    hs = 1 : IF _KEYDOWN(100304) OR _KEYDOWN(100303) THEN hs = 8
    SELECT CASE k&
        CASE 27, 117, 85 : GOSUB HudEditLeave : EXIT DO
        CASE 9 : hudSel = hudSel MOD HUD_ELEMS + 1
        CASE 18432 : hudY(hudSel) = hudY(hudSel) - hs
        CASE 20480 : hudY(hudSel) = hudY(hudSel) + hs
        CASE 19200 : hudX(hudSel) = hudX(hudSel) - hs
        CASE 19712 : hudX(hudSel) = hudX(hudSel) + hs
        CASE 118, 86 : hudShow(hudSel) = NOT hudShow(hudSel)
        CASE 99, 67 : hudCol(hudSel) = HudNextColor~&(hudCol(hudSel))
        CASE 43, 61 : hudW(hudSel) = hudW(hudSel) + 10 : IF hudSel = HE_MINIMAP OR hudSel = HE_CARDS THEN hudW(hudSel) = hudW(hudSel) - 9
        CASE 45 : hudW(hudSel) = MaxOf(0, hudW(hudSel) - 10) : IF hudSel = HE_MINIMAP OR hudSel = HE_CARDS THEN hudW(hudSel) = MaxOf(1, hudW(hudSel) + 9)
        CASE 91 : hudH(hudSel) = MaxOf(1, hudH(hudSel) - 1)
        CASE 93 : hudH(hudSel) = hudH(hudSel) + 1
        CASE 115, 83 : WriteHud : hudMsg$ = "Saved " + AssetPath$("hud.txt")
        CASE 114, 82 : HudDefaults : hudMsg$ = "The game's own layout, back (S to keep it)"
    END SELECT
    k& = _KEYHIT
LOOP
RETURN

' --- THE MONSTER EDITOR (chapter 21): every kind of monster's numbers,
' changed with the arrow keys and in effect at once. Up/Down a number,
' Left/Right change it (Shift: ten times as much), PgUp/PgDn the monster
' before or after, S save to monsters.txt, Esc back.
RunMonsterEditor:
_KEYCLEAR : meType = 1 : meField = 1 : meDone = 0 : meMsg$ = ""
DO
    _LIMIT 60
    WHILE _MOUSEINPUT : WEND
    k& = _KEYHIT
    DO WHILE k&
        shiftOn = _KEYDOWN(100304) OR _KEYDOWN(100303)
        SELECT CASE k&
            CASE 27, 15360 : meDone = -1
            CASE 18432 : meField = meField - 1 : IF meField < 1 THEN meField = ME_FIELDS
            CASE 20480 : meField = meField + 1 : IF meField > ME_FIELDS THEN meField = 1
            CASE 19200 : MonsterField meType, meField, -1 + 9 * shiftOn ' (shiftOn is -1 held: Shift makes it -10...
            CASE 19712 : MonsterField meType, meField, 1 - 9 * shiftOn ' ...and +10)
            CASE 18688 : meType = meType - 1 : IF meType < 1 THEN meType = MON_TYPES
            CASE 20736 : meType = meType + 1 : IF meType > MON_TYPES THEN meType = 1
            CASE 115, 83 : WriteMonsters : meMsg$ = "Saved " + AssetPath$("monsters.txt")
        END SELECT
        k& = _KEYHIT
    LOOP
    IF meDone THEN EXIT DO
    DrawMonsterEditor meType, meField, meMsg$
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
_KEYCLEAR : WHILE _MOUSEINPUT : WEND : escWas = -1
RETURN

' --- THE PUZZLE SCREEN: the program's lines, shuffled, some words blank.
' Up/Down choose a line, Shift+Up/Down (or PgUp/PgDn) move it; Enter
' fills in its blank (type, Enter); F5 or R compiles and runs it; H a hint;
' Esc leaves (the doors stay locked). pzSolved: it worked.
RunPuzzle:
WorldLoopsOff
_MOUSESHOW : _KEYCLEAR
pzSolved = 0 : pzSel = 1 : pzTyping = 0 : pzShown = 0 : pzFails = 0 : pzOut$ = "Put the lines in order, fill the blanks, then F5 to compile and run."
pzDone = 0 : qb$ = QB64Path$
DO
    _LIMIT 60
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN
            ln = (_MOUSEY - PZ_TOP) \ 18 + 1 : IF ln >= 1 AND ln <= pzN AND _MOUSEX < 560 THEN pzSel = ln : pzTyping = 0
        END IF
    WEND
    k& = _KEYHIT
    DO WHILE k&
        shiftOn = _KEYDOWN(100304) OR _KEYDOWN(100303)
        IF pzTyping THEN ' Typing a blank's word
            b = PuzzleBlankOn(pzSel)
            SELECT CASE k&
                CASE 13, 9, 27 : pzTyping = 0
                CASE 8 : IF LEN(pzBlankIn$(b)) THEN pzBlankIn$(b) = LEFT$(pzBlankIn$(b), LEN(pzBlankIn$(b)) - 1)
                CASE 32 TO 126 : IF LEN(pzBlankIn$(b)) < 16 THEN pzBlankIn$(b) = pzBlankIn$(b) + CHR$(k&)
            END SELECT
        ELSE
            SELECT CASE k&
                CASE 27 : pzDone = -1
                CASE 18432 ' Up: the line above - with Shift, move this line up
                    IF shiftOn AND pzSel > 1 THEN SWAP pzOrder(pzSel), pzOrder(pzSel - 1)
                    IF pzSel > 1 THEN pzSel = pzSel - 1
                CASE 20480
                    IF shiftOn AND pzSel < pzN THEN SWAP pzOrder(pzSel), pzOrder(pzSel + 1)
                    IF pzSel < pzN THEN pzSel = pzSel + 1
                CASE 18688 : IF pzSel > 1 THEN SWAP pzOrder(pzSel), pzOrder(pzSel - 1) : pzSel = pzSel - 1 ' PgUp: move it up
                CASE 20736 : IF pzSel < pzN THEN SWAP pzOrder(pzSel), pzOrder(pzSel + 1) : pzSel = pzSel + 1 ' PgDn: down
                CASE 13 : IF PuzzleBlankOn(pzSel) THEN pzTyping = -1 ELSE pzOut$ = "That line has no blank to fill."
                CASE 104, 72 ' H: the next hint
                    IF pzShown < pzHints THEN pzShown = pzShown + 1 ELSE pzOut$ = "No more hints - read the comments ('...) in the program too."
                CASE 16128, 114, 82 : GOSUB PuzzleRun ' F5 or R: compile and run
                CASE 34304 ' F12 (testing, with CHEAT_KEYS): put it all right
                    IF CHEAT_KEYS THEN FOR f = 1 TO pzN + pzBlanks : PuzzleFixOne : NEXT
            END SELECT
        END IF
        k& = _KEYHIT
    LOOP
    IF pzDone OR pzSolved THEN EXIT DO
    DrawPuzzle pzSel, pzTyping, qb$
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
IF pzSolved THEN ' (a moment to see it worked)
    FOR f = 1 TO 90
        _LIMIT 60 : DrawPuzzle 0, 0, qb$
        IF glReady THEN GLSL_filter_capture
        GLScreenLayer glReady : _DISPLAY
    NEXT
END IF
_KEYCLEAR : _MOUSEHIDE _DISABLE : WHILE _MOUSEINPUT : WEND
escWas = -1 : fireWait = 15 : spaceWas = -1
RETURN

' Compile and run the program as it stands. With qb64pe: written out with
' $CONSOLE:ONLY on top (it prints to the terminal, not a window) and
' SYSTEM after the main part, compiled and run by a shell in the
' background while this waits (and says so); its output (or the
' compiler's complaint) read back and checked against pzExpect$. Without
' qb64pe: the lines checked against the answer instead.
PuzzleRun:
pzOut$ = ""
IF qb$ = "" THEN
    ok = -1
    FOR i = 1 TO pzN
        IF NormLine$(PuzzleLine$(i)) <> NormLine$(pzAns$(i)) THEN ok = 0
    NEXT
    IF ok THEN pzSolved = -1 : pzOut$ = "CHECKED (qb64pe not found - the lines match the program).|ACCESS GRANTED" ELSE pzOut$ = "Not right yet - check the order, and the blanks."
ELSE
    MakeSaveDir : d$ = SaveDir$ + "puzzle"
    IF NOT _DIREXISTS(d$) THEN MKDIR d$
    d$ = _FULLPATH$(d$) ' (all its paths whole: qb64pe works from its own folder)
    IF RIGHT$(d$, 1) = "/" OR RIGHT$(d$, 1) = "\" THEN d$ = LEFT$(d$, LEN(d$) - 1)
    win = INSTR(_OS$, "[WINDOWS]") > 0
    src$ = d$ + "/prog.bas" : exe$ = d$ + "/prog" : out$ = d$ + "/out.txt" : done$ = d$ + "/done.txt"
    IF win THEN ' (Windows: its own slashes, and a program ends in .exe)
        src$ = Slashes$(src$) : exe$ = Slashes$(exe$ + ".exe") : out$ = Slashes$(out$) : done$ = Slashes$(done$)
    END IF
    IF _FILEEXISTS(out$) THEN KILL out$ ' (the last run's, out of the way)
    IF _FILEEXISTS(done$) THEN KILL done$
    IF _FILEEXISTS(exe$) THEN KILL exe$
    fh = FREEFILE : OPEN src$ FOR OUTPUT AS #fh
    PRINT #fh, "$CONSOLE:ONLY"
    placed = 0
    FOR i = 1 TO pzN
        u$ = UCASE$(LTRIM$(PuzzleLine$(i)))
        IF NOT placed AND (LEFT$(u$, 9) = "FUNCTION " OR LEFT$(u$, 4) = "SUB ") THEN PRINT #fh, "SYSTEM" : placed = -1
        PRINT #fh, PuzzleLine$(i)
    NEXT
    IF NOT placed THEN PRINT #fh, "SYSTEM"
    CLOSE #fh
    ' The compile and the run go in a little script (a batch file on
    ' Windows, sh elsewhere), started in the background: compile; if that
    ' worked, run it (on Linux, timeout stops it after 5 seconds if it
    ' never ends - macOS hasn't got timeout); either way, leave done.txt
    q$ = CHR$(34) : fh = FREEFILE
    IF win THEN
        script$ = Slashes$(d$ + "/run.cmd")
        OPEN script$ FOR OUTPUT AS #fh
        PRINT #fh, "@echo off"
        PRINT #fh, q$ + Slashes$(qb$) + q$ + " -x " + q$ + src$ + q$ + " -o " + q$ + exe$ + q$ + " > " + q$ + out$ + q$ + " 2>&1"
        PRINT #fh, "if exist " + q$ + exe$ + q$ + " " + q$ + exe$ + q$ + " > " + q$ + out$ + q$ + " 2>&1 < NUL"
        PRINT #fh, "echo done > " + q$ + done$ + q$
        CLOSE #fh
        SHELL _DONTWAIT q$ + script$ + q$
    ELSE
        script$ = d$ + "/run.sh" : lf$ = CHR$(10) ' (PRINT # ends lines with CR LF everywhere - sh wants LF alone)
        t$ = "if " + q$ + qb$ + q$ + " -x " + q$ + src$ + q$ + " -o " + q$ + exe$ + q$ + " > " + q$ + out$ + q$ + " 2>&1; then" + lf$
        t$ = t$ + "  if command -v timeout > /dev/null 2>&1; then timeout 5 " + q$ + exe$ + q$ + " > " + q$ + out$ + q$ + " 2>&1 < /dev/null" + lf$
        t$ = t$ + "  else " + q$ + exe$ + q$ + " > " + q$ + out$ + q$ + " 2>&1 < /dev/null; fi" + lf$
        t$ = t$ + "fi" + lf$ + "echo done > " + q$ + done$ + q$ + lf$
        IF _FILEEXISTS(script$) THEN KILL script$
        OPEN script$ FOR BINARY AS #fh : PUT #fh, , t$ : CLOSE #fh
        SHELL _DONTWAIT "sh " + q$ + script$ + q$
    END IF
    t0! = TIMER
    DO ' Waiting: COMPILING...
        _LIMIT 30
        el! = TIMER - t0! : IF el! < 0 THEN el! = el! + 86400
        IF _FILEEXISTS(done$) OR el! > 120 THEN EXIT DO
        pzOut$ = "COMPILING" + STRING$(INT(el! * 3) MOD 4, ".") + "   (" + LTRIM$(STR$(INT(el!))) + "s)   qb64pe is turning it into a program"
        DrawPuzzle pzSel, 0, qb$
        IF glReady THEN GLSL_filter_capture
        GLScreenLayer glReady : _DISPLAY
    LOOP
    got$ = ""
    IF _FILEEXISTS(out$) THEN
        fh = FREEFILE : OPEN out$ FOR INPUT AS #fh
        DO UNTIL EOF(fh)
            LINE INPUT #fh, l$
            IF LEN(LTRIM$(l$)) THEN got$ = got$ + "|" + l$
        LOOP
        CLOSE #fh
    END IF
    IF LEN(got$) THEN got$ = MID$(got$, 2)
    IF NOT _FILEEXISTS(exe$) THEN ' Didn't compile: the compiler's words
        pzOut$ = "DID NOT COMPILE:|" + LEFT$(PuzzleCompilerSays$(got$), 300)
    ELSEIF NormLine$(got$) = NormLine$(pzExpect$) THEN
        pzSolved = -1 : pzOut$ = "RAN - it printed:|" + got$ + "|ACCESS GRANTED"
    ELSE
        pzOut$ = "RAN, but printed:|" + LEFT$(got$, 200) + "|- and that's not it (it should print " + pzExpect$ + ")"
    END IF
END IF
IF NOT pzSolved THEN ' Wrong: another hint - and after a few, one line put right
    pzFails = pzFails + 1
    IF pzShown < pzHints THEN pzShown = pzShown + 1
    IF pzFails >= 3 THEN PuzzleFixOne : pzOut$ = pzOut$ + "|(The terminal fixed one line for you.)"
    PlaySfx sndFail&, 0.7
ELSE
    PlaySfx sndCore&, 1
END IF
RETURN

' --- Into the network through data station st (chapter 19): the real
' pictures put away and the grid put up, the real things left behind,
' data cores laid out round the station (on the floor you can walk to from
' it, without going through a door), and ICE let loose, far off
JackIn:
WorldLoopsOff
cyberOn = -1 : cyberStation = st
cyberTime = CYBER_SECONDS * 60 : cyberGot = 0 : cyberNeed = 3 + level \ 3 : IF cyberNeed > 6 THEN cyberNeed = 6
cyberMonStart = numMonsters : cyberItemStart = numItems
FOR i = 1 TO MAX_BOLTS : boltOn(i) = 0 : NEXT
CyberTextures -1
' The floor round the station: steps from it (fillX/fillY, as the
' thieves' way does), through floor only - not doors
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE : thiefDist(x, y) = 30000 : NEXT : NEXT
head = 0 : tail = 0
FOR k = 1 TO 4
    nx = stationX(st) + (k = 1) - (k = 2) : ny = stationY(st) + (k = 3) - (k = 4)
    IF worldMap(nx, ny) = 0 AND glassHP(nx, ny) = 0 AND diagCorner(nx, ny) = 0 THEN thiefDist(nx, ny) = 0 : fillX(tail) = nx : fillY(tail) = ny : tail = tail + 1
NEXT
DO WHILE head < tail
    x = fillX(head) : y = fillY(head) : head = head + 1
    FOR k = 1 TO 4
        nx = x + (k = 1) - (k = 2) : ny = y + (k = 3) - (k = 4)
        IF nx > 0 AND ny > 0 AND nx < MAP_SIZE - 1 AND ny < MAP_SIZE - 1 THEN
            IF worldMap(nx, ny) = 0 AND glassHP(nx, ny) = 0 AND diagCorner(nx, ny) = 0 AND thiefDist(nx, ny) > thiefDist(x, y) + 1 AND thiefDist(x, y) < 18 THEN
                thiefDist(nx, ny) = thiefDist(x, y) + 1 : fillX(tail) = nx : fillY(tail) = ny : tail = tail + 1
            END IF
        END IF
    NEXT
LOOP
' Cores: on cells 5 or more steps out, as spread out as can be (each one
' the farthest from all those placed so far, of a few tried at random)
placed = 0
FOR c = 1 TO cyberNeed
    bestCell = -1 : bestScore = -1
    FOR try = 1 TO 40
        e = INT(RND * tail) : x = fillX(e) : y = fillY(e)
        IF thiefDist(x, y) >= 5 THEN
            score = 99
            FOR i = cyberItemStart + 1 TO numItems
                d = ABS(itemX(i) - x - 0.5) + ABS(itemY(i) - y - 0.5) : IF d < score THEN score = d
            NEXT
            IF score > bestScore THEN bestScore = score : bestCell = e
        END IF
    NEXT
    IF bestCell >= 0 AND numItems < MAX_ITEMS THEN
        numItems = numItems + 1 : itemX(numItems) = fillX(bestCell) + 0.5 : itemY(numItems) = fillY(bestCell) + 0.5
        itemKind(numItems) = IT_CORE : itemOn(numItems) = -1 : placed = placed + 1
    END IF
NEXT
IF placed < cyberNeed THEN cyberNeed = placed
IF cyberNeed = 0 THEN cyberNeed = 1 : numItems = numItems + 1 : itemX(numItems) = playerX + dirX : itemY(numItems) = playerY + dirY : itemKind(numItems) = IT_CORE : itemOn(numItems) = -1
' ICE: on the farthest cells
nIce = 2 + level \ 3
FOR c = 1 TO nIce
    e = tail - 1 - INT(RND * (tail \ 3 + 1)) : IF e < 0 THEN e = 0
    IF tail > 0 THEN IF SpawnMonster(MT_ICE, fillX(e) + 0.5, fillY(e) + 0.5, 0) THEN monsterTimer(numMonsters) = 90
NEXT
BuildThiefWay ' (the thieves' way home, which the steps above borrowed)
dirX = -dirX : dirY = -dirY : planeX = -planeX : planeY = -planeY ' (you turn round: into the network, your back to the station)
PlaySfx sndJackIn&, 1 : pickFlash = 30 : shake = shake + 6
IF cyberMusic& > 0 THEN PlayMusic cyberMusic&
ShowMsg "JACKED IN - grab " + LTRIM$(STR$(cyberNeed)) + " data cores before the time runs out!"
Say "cyber1", 0
RETURN

' --- Out of the network: won (cyberWon) or thrown out. The real pictures
' back, the network's things gone (they were the last monsters and pickups
' added), you back at the station - and if you won, its doors unsealed
' (each sealed door belongs to the station nearest it)
JackOut:
CyberTextures 0
FOR i = cyberMonStart + 1 TO numMonsters ' (ICE you derezzed doesn't count in the sector's kills)
    IF monsterState(i) >= 2 THEN kills = kills - 1
NEXT
numMonsters = cyberMonStart : numItems = cyberItemStart
FOR i = 1 TO MAX_BOLTS : boltOn(i) = 0 : NEXT
cyberOn = 0
PlaySfx sndJackOut&, 1 : pickFlash = 20
PlayMusic SectorMusic&(level)
IF cyberWon THEN
    stationDone(cyberStation) = -1
    FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
        IF worldMap(x, y) = 2 AND doorLock(x, y) = 2 THEN
            IF StationNear(x, y) = cyberStation THEN doorLock(x, y) = 0 : doorOpen(x, y) = 0.01 : doorMove(x, y) = 1 : SfxAt DoorSnd&(doorType(x, y)), x + 0.5, y + 0.5, playerX, playerY
        END IF
    NEXT : NEXT
    PlaySfx sndFanfare&, 0.8
    ShowMsg "ACCESS GRANTED - the sealed doors are open"
    Say "cyber2", 0
ELSE
    PlaySfx sndFail&, 0.8
    damage = 10 : hurtFromX = -1 : hurtFromY = -1 : hurtElectric = -1 : GOSUB HurtPlayer
    ShowMsg "EJECTED - the network threw you out. Try again"
    Say "cyber3", 0
END IF
RETURN

' --- Glass at cell (glassHitX, glassHitY) is hit for glassDmg, at
' (glassAtX, glassAtY): it chips and cracks, and at 0 it shatters - a
' shower of shards, and the way is open
HitGlass:
IF glassHP(glassHitX, glassHitY) <= 0 THEN RETURN
glassHP(glassHitX, glassHitY) = glassHP(glassHitX, glassHitY) - glassDmg
IF glassHP(glassHitX, glassHitY) > 0 THEN
    SpawnSparks glassAtX, glassAtY, 0.5, 5, 200, 240, 255
    SfxAt sndGlassHit&, glassAtX, glassAtY, playerX, playerY
ELSE
    glassHP(glassHitX, glassHitY) = 0
    FOR gk = 0 TO 4 ' (shards all along the pane, falling)
        IF glassDir(glassHitX, glassHitY) = 1 THEN gsx = glassHitX + 0.1 + gk * 0.2 : gsy = glassHitY + 0.5 ELSE gsx = glassHitX + 0.5 : gsy = glassHitY + 0.1 + gk * 0.2
        SpawnSparks gsx, gsy, 0.15 + RND * 0.7, 9, 190, 235, 255
    NEXT
    SfxAt sndGlassBreak&, glassAtX, glassAtY, playerX, playerY
    IF (glassAtX - playerX) ^ 2 + (glassAtY - playerY) ^ 2 < 25 THEN shake = shake + 3
    FOR gj = 1 TO numMonsters ' (that wakes anything near)
        IF monsterState(gj) = 0 THEN IF (monsterX(gj) - glassAtX) ^ 2 + (monsterY(gj) - glassAtY) ^ 2 < 36 THEN monsterState(gj) = 1 : monsterTimer(gj) = 20
    NEXT
END IF
RETURN

' --- HEIGHTS, THE SOFTWARE WAY (chapter 15, for a level with heights):
' column x, front to back, as Doom does it. The ray walks the grid as
' before, but doesn't stop at the first change: in each cell it passes
' through it draws that cell's floor and ceiling - the part of them
' between where it came in (hDIn) and where it leaves (hDOut) - then looks
' at the next cell. A higher floor there: the step's face; a lower
' ceiling: the lintel's. hTop and hBot are what's left of the column still
' to draw: each floor, step and lintel drawn closes it in from below or
' above, and anything further away can only show in what's left - that's
' how a ledge hides the floor behind it. A wall ends the column. Each time
' the window closes in, it's noted (clipD/T/B) for the sprites (chapter 16).
' A height h at distance d is on screen at row RENDER_H / 2 + (eyeZ - h) *
' viewH / d: the higher it is (or the nearer), the further up.
HeightColumn:
hTop = 0 : hBot = RENDER_H - 1 : hor = RENDER_H / 2
hcX = INT(playerX) : hcY = INT(playerY) : hDIn = 0
hStepX = SGN(rayDirX) : hStepY = SGN(rayDirY) : IF hStepX = 0 THEN hStepX = 1
IF hStepY = 0 THEN hStepY = 1
IF ABS(rayDirX) < 0.00001 THEN hDDX = 1E+9 ELSE hDDX = ABS(1 / rayDirX)
IF ABS(rayDirY) < 0.00001 THEN hDDY = 1E+9 ELSE hDDY = ABS(1 / rayDirY)
IF rayDirX < 0 THEN hSDX = (playerX - hcX) * hDDX ELSE hSDX = (hcX + 1 - playerX) * hDDX
IF rayDirY < 0 THEN hSDY = (playerY - hcY) * hDDY ELSE hSDY = (hcY + 1 - playerY) * hDDY
DO
    IF hSDX < hSDY THEN hDOut = hSDX : hnX = hcX + hStepX : hnY = hcY : hSide = 0 : hSDX = hSDX + hDDX ELSE hDOut = hSDY : hnX = hcX : hnY = hcY + hStepY : hSide = 1 : hSDY = hSDY + hDDY
    IF hDOut < 0.001 THEN hDOut = 0.001
    ' This cell's light, fogged as far as its middle
    hFog& = 256 - (hDIn + hDOut) * 8 : IF hFog& < 0 THEN hFog& = 0
    hR& = litR(hcX, hcY) : hG& = litG(hcX, hcY) : hB& = litB(hcX, hcY)
    ' Its floor: from where it leaves (higher up the screen) down to where
    ' it came in
    hf = floorH(hcX, hcY)
    IF eyeZ > hf THEN
        yFar = INT(hor + (eyeZ - hf) * viewH / hDOut + 0.999)
        IF hDIn > 0.0001 THEN yNear = INT(hor + (eyeZ - hf) * viewH / hDIn) ELSE yNear = RENDER_H - 1
        IF yFar < hTop THEN yFar = hTop
        IF yNear > hBot THEN yNear = hBot
        ' (the loop that colours the most pixels: everything a cell needs is
        ' looked up once, before it, and ShadeRGB's sum is written out - a
        ' FUNCTION call a pixel costs more than the sum)
        hk = eyeZ - hf : slot = floorTex(hcX, hcY) : hSplit = floorSplit(hcX, hcY) : tMask = texSize - 1
        FOR y = yFar TO yNear
            rowDist = hk * rowF(y)
            fx = playerX + rowDist * rayDirX : fy = playerY + rowDist * rayDirY
            s2 = slot : IF hSplit THEN IF InDiagonalWall(hSplit, fx - hcX, fy - hcY) THEN s2 = floorTex2(hcX, hcY)
            f& = 256 - rowDist * 16 : IF f& < 0 THEN f& = 0
            lR& = hR& * f& \ 256 : IF lR& > 256 THEN lR& = 256
            lG& = hG& * f& \ 256 : IF lG& > 256 THEN lG& = 256
            lB& = hB& * f& \ 256 : IF lB& > 256 THEN lB& = 256
            texel~& = texture(INT(fx * texSize) AND tMask, INT(fy * texSize) AND tMask, s2)
            pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lG& \ 256) * 256 OR ((texel~& AND 255) * lB& \ 256)
            IF gridOn THEN IF (INT(fx * texSize) AND tMask) < gridW OR (INT(fy * texSize) AND tMask) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
        NEXT
        IF yFar - 1 < hBot THEN hBot = yFar - 1
    END IF
    ' Its ceiling, the same way up
    hc = ceilH(hcX, hcY)
    IF hc > eyeZ THEN
        yFar = INT(hor - (hc - eyeZ) * viewH / hDOut)
        IF hDIn > 0.0001 THEN yNear = INT(hor - (hc - eyeZ) * viewH / hDIn + 0.999) ELSE yNear = 0
        IF yNear < hTop THEN yNear = hTop
        IF yFar > hBot THEN yFar = hBot
        hk = hc - eyeZ : slot = ceilTex(hcX, hcY) : hSplit = ceilSplit(hcX, hcY) : tMask = texSize - 1
        FOR y = yNear TO yFar
            rowDist = hk * rowC(y)
            fx = playerX + rowDist * rayDirX : fy = playerY + rowDist * rayDirY
            s2 = slot : IF hSplit THEN IF InDiagonalWall(hSplit, fx - hcX, fy - hcY) THEN s2 = ceilTex2(hcX, hcY)
            f& = 256 - rowDist * 16 : IF f& < 0 THEN f& = 0
            lR& = hR& * f& \ 256 : IF lR& > 256 THEN lR& = 256
            lG& = hG& * f& \ 256 : IF lG& > 256 THEN lG& = 256
            lB& = hB& * f& \ 256 : IF lB& > 256 THEN lB& = 256
            texel~& = texture(INT(fx * texSize) AND tMask, INT(fy * texSize) AND tMask, s2)
            pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lG& \ 256) * 256 OR ((texel~& AND 255) * lB& \ 256)
            IF gridOn THEN IF (INT(fx * texSize) AND tMask) < gridW OR (INT(fy * texSize) AND tMask) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
        NEXT
        IF yFar + 1 > hTop THEN hTop = yFar + 1
    END IF
    IF hTop > hBot THEN EXIT DO
    ' The next cell: a wall (or a shut door, or a diagonal - drawn whole),
    ' or open, with a step up or a lintel down to it
    IF hnX < 0 OR hnY < 0 OR hnX >= MAP_SIZE OR hnY >= MAP_SIZE THEN EXIT DO
    v = worldMap(hnX, hnY) : hSolid = 0
    IF v > 0 AND v <> 2 THEN hSolid = -1 : hSlot = wallTexSlot(v)
    IF diagCorner(hnX, hnY) THEN hSolid = -1 : hSlot = wallTexSlot(worldMap(hnX, hnY))
    IF v = 2 THEN
        IF doorType(hnX, hnY) = DOOR_EXIT THEN hSolid = -1 : hSlot = T_EXIT
        IF doorType(hnX, hnY) <> DOOR_EXIT AND DoorShown(hnX, hnY) < 0.5 THEN
            hSolid = -1
            SELECT CASE doorType(hnX, hnY)
                CASE DOOR_SLIDE : IF doorKey(hnX, hnY) THEN hSlot = T_DOORK + doorKey(hnX, hnY) ELSE hSlot = T_DOOR
                CASE DOOR_SPLIT : hSlot = T_SPLIT
                CASE ELSE : hSlot = T_SHUTTER
            END SELECT
        END IF
    END IF
    IF hSide = 0 THEN wallX = playerY + hDOut * rayDirY ELSE wallX = playerX + hDOut * rayDirX
    wallX = wallX - INT(wallX) : hTexX = INT(wallX * texSize)
    IF hSide = 0 AND rayDirX > 0 THEN hTexX = texSize - 1 - hTexX
    IF hSide = 1 AND rayDirY < 0 THEN hTexX = texSize - 1 - hTexX
    hTexX = hTexX AND (texSize - 1)
    hSd = 0 ' (which side of the next cell this is - for a picture of its own: [faces])
    IF lvlNumFaces THEN
        IF hSide = 0 THEN IF rayDirX > 0 THEN hSd = 3 ELSE hSd = 1
        IF hSide = 1 THEN IF rayDirY > 0 THEN hSd = 4 ELSE hSd = 2
        IF hSolid AND v <> 2 THEN hSlot = FaceSlot(hnX, hnY, hSd, hTexX / texSize, 0, hSlot)
    END IF
    hFog& = 256 - hDOut * 16 : IF hFog& < 0 THEN hFog& = 0
    IF hSide = 1 THEN hFog& = hFog& * 0.7
    hR& = MinOf(256, litR(hcX, hcY) * hFog& \ 256) : hG& = MinOf(256, litG(hcX, hcY) * hFog& \ 256) : hB& = MinOf(256, litB(hcX, hcY) * hFog& \ 256)
    IF hSolid THEN ' A wall: from this cell's ceiling to its floor
        y0 = INT(hor - (hc - eyeZ) * viewH / hDOut) : y1 = INT(hor + (eyeZ - hf) * viewH / hDOut)
        hZ0 = hc : hZ1 = hf : hVOff = 0 : GOSUB HeightFace
        EXIT DO
    END IF
    ' Open: the step's face up to a higher floor...
    nf = floorH(hnX, hnY)
    IF nf > hf THEN
        y0 = INT(hor + (eyeZ - nf) * viewH / hDOut) : y1 = INT(hor + (eyeZ - hf) * viewH / hDOut) : hSlot = wallTexSlot(1) : hVOff = 0
        IF hSd THEN hSlot = FaceSlot(hnX, hnY, hSd, hTexX / texSize, 0, hSlot)
        IF liftCell(hnX, hnY) THEN hSlot = T_LIFTSIDE : hVOff = nf - 1 ' (a lift's side: hangs from its top - MakeLiftTex)
        hZ0 = nf : hZ1 = hf : GOSUB HeightFace
        IF y0 - 1 < hBot THEN hBot = y0 - 1
    END IF
    ' ...and the lintel's down to a lower ceiling
    nc = ceilH(hnX, hnY)
    IF nc < hc THEN
        y0 = INT(hor - (hc - eyeZ) * viewH / hDOut) : y1 = INT(hor - (nc - eyeZ) * viewH / hDOut) : hSlot = wallTexSlot(1)
        IF hSd THEN hSlot = FaceSlot(hnX, hnY, hSd + 4, hTexX / texSize, 0, hSlot)
        hZ0 = hc : hZ1 = nc : hVOff = 0 : GOSUB HeightFace
        IF y1 + 1 > hTop THEN hTop = y1 + 1
    END IF
    IF clipN(x) < MAX_CLIPS THEN clipN(x) = clipN(x) + 1 : clipD(x, clipN(x)) = hDOut : clipT(x, clipN(x)) = hTop : clipB(x, clipN(x)) = hBot
    IF hTop > hBot OR hDOut > 24 THEN EXIT DO
    hcX = hnX : hcY = hnY : hDIn = hDOut
LOOP
RETURN

' (HeightColumn's upright faces: rows y0 to y1 of column x, inside hTop ..
' hBot, the texture hSlot by height - from hZ0 at y0 to hZ1 at y1, a
' picture a wall high, repeated, moved down by hVOff (a lift's side hangs
' from its top) - and column hTexX, lit hR&, hG&, hB&)
HeightFace:
yA = y0 : IF yA < hTop THEN yA = hTop
yB = y1 : IF yB > hBot THEN yB = hBot
' The picture's row runs evenly down the face: work out the first, then
' step (the height at row y is eyeZ - (y + 0.5 - hor) * hDOut / viewH)
vStep = hDOut / viewH * texSize : v = (hVOff + 1 - eyeZ + (yA + 0.5 - hor) * hDOut / viewH) * texSize : tMask = texSize - 1
FOR y = yA TO yB
    texel~& = texture(hTexX, INT(v) AND tMask, hSlot)
    pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * hR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * hG& \ 256) * 256 OR ((texel~& AND 255) * hB& \ 256)
    IF gridOn THEN IF hTexX < gridW OR (INT(v) AND tMask) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
    v = v + vStep
NEXT
RETURN

' --- Column gx's pane of glass, over what's already drawn behind it: the
' glass picture (S_GLASS, or cracked) at the pane's distance, each pixel
' mixed with what's there by the picture's alpha - see-through mostly,
' streaks of shine, a solid frame top and bottom
GlassColumn:
glassDone(gx) = -1
gLine = viewH / glassT(gx)
gTop = INT(RENDER_H / 2 - (ceilH(glassCX(gx), glassCY(gx)) - eyeZ) * gLine) : gEnd = INT(RENDER_H / 2 + (eyeZ - floorH(glassCX(gx), glassCY(gx))) * gLine)
gLine = gEnd - gTop + 1 ' (the pane's height on the screen)
gStep = sprTex / gLine : gPos = 0
IF gTop < 0 THEN gPos = -gTop * gStep : gTop = 0
IF gEnd > RENDER_H - 1 THEN gEnd = RENDER_H - 1
gu = INT(glassU(gx) * sprTex) AND (sprTex - 1)
gSlot = S_GLASS : IF glassHP(glassCX(gx), glassCY(gx)) <= GLASS_HP \ 2 THEN gSlot = S_GLASS + 1
gFog& = 256 - glassT(gx) * 16 : IF gFog& < 40 THEN gFog& = 40
gR& = litR(glassCX(gx), glassCY(gx)) * gFog& \ 256 : gG& = litG(glassCX(gx), glassCY(gx)) * gFog& \ 256 : gB& = litB(glassCX(gx), glassCY(gx)) * gFog& \ 256
IF gR& > 256 THEN gR& = 256
IF gG& > 256 THEN gG& = 256
IF gB& > 256 THEN gB& = 256
' (A pane can cover the whole view, so this loop can run 100,000 times a
' frame: the shading and the mix are written out, not FUNCTION calls)
gMask = sprTex - 1
FOR gy = gTop TO gEnd
    gTex~& = spriteTex(gu, INT(gPos) AND gMask, gSlot) : gA& = (gTex~& \ &H1000000) AND 255
    IF gA& THEN
        gIdx& = gy * RENDER_W + gx : gOld~& = pixels(gIdx&) : gK& = 255 - gA&
        gCR& = ((gTex~& \ 65536) AND 255) * gR& \ 256 : gCG& = ((gTex~& \ 256) AND 255) * gG& \ 256 : gCB& = (gTex~& AND 255) * gB& \ 256
        pixels(gIdx&) = &HFF000000~& OR ((gCR& * gA& + ((gOld~& \ 65536) AND 255) * gK&) \ 255) * 65536 OR ((gCG& * gA& + ((gOld~& \ 256) AND 255) * gK&) \ 255) * 256 OR ((gCB& * gA& + (gOld~& AND 255) * gK&) \ 255)
    END IF
    gPos = gPos + gStep
NEXT
RETURN

HitDeco:
IF decoKind(targetDeco) = DK_BODY THEN RETURN ' (bodies don't break)
IF Explosive(decoKind(targetDeco)) THEN
    IF decoFuse(targetDeco) = 0 THEN decoFuse(targetDeco) = 1
    RETURN
END IF
decoHP(targetDeco) = decoHP(targetDeco) - hitDamage
IF decoHP(targetDeco) > 0 THEN
    SfxAt sndDecoHit&, decoX(targetDeco), decoY(targetDeco), playerX, playerY
ELSE
    decoOn(targetDeco) = 0 : decoTimer(targetDeco) = DECO_BREAK_FRAMES
    decoCell(INT(decoX(targetDeco)), INT(decoY(targetDeco))) = 0
    SfxAt decoBreakSnd&(decoKind(targetDeco)), decoX(targetDeco), decoY(targetDeco), playerX, playerY
    IF decoKind(targetDeco) <> 3 THEN ' Not plants: they just fall apart
        newBlastX = decoX(targetDeco) : newBlastY = decoY(targetDeco) : newBlastSize = 0.35 : GOSUB AddBlast
    END IF
END IF
RETURN

'' --- THE EVENT ROOMS (see EV_ in chapter 3), once a frame. Each one
' waits until you walk in, then runs until it's won or lost:
RunEvents:
FOR ev = 1 TO numEvents
    inside = playerX >= evX0(ev) AND playerX < evX1(ev) + 1 AND playerY >= evY0(ev) AND playerY < evY1(ev) + 1
    SELECT CASE evType(ev)
        CASE EV_TRAP, EV_FIRETRAP ' Always on: live for evA frames, safe for evB - warning you for the last
            ' TRAP_WARN of those - and hurting you if you're on it while it's live
            evTimer(ev) = evTimer(ev) + 1 : cyc = evA(ev) + evB(ev) : IF cyc < 1 THEN cyc = 1
            phase = evTimer(ev) MOD cyc ' (its own clock)
            IF phase < evA(ev) THEN
                evGlow(ev) = 1
                IF inside AND NOT dead AND phase MOD 15 = 0 THEN
                    IF evType(ev) = EV_FIRETRAP THEN PlaySfx sndSizzle&, 0.8 ELSE PlaySfx sndZap&, 0.8
                    damage = 6 : hurtFromX = -1 : hurtFromY = -1 : hurtElectric = (evType(ev) = EV_TRAP) : GOSUB HurtPlayer
                END IF
            ELSEIF phase >= cyc - TRAP_WARN THEN
                evGlow(ev) = 0.35 * (phase - (cyc - TRAP_WARN)) / TRAP_WARN ' (warming up)
            ELSE
                evGlow(ev) = 0
            END IF
            TrapFx ev
        CASE EV_PLATE ' Stepped on (by you or a monster): click, then boom
            IF evNext(ev) > 0 THEN evNext(ev) = evNext(ev) - 1
            SELECT CASE evState(ev)
                CASE 0 ' Armed
                    pressed = inside AND NOT dead
                    FOR j = 1 TO numMonsters
                        IF monsterState(j) < 2 THEN IF InRoom(ev, monsterX(j), monsterY(j)) AND mtypeSpeed(monsterType(j)) > 0 THEN pressed = -1
                    NEXT
                    IF pressed THEN evState(ev) = 1 : evTimer(ev) = evA(ev) : SfxAt sndPlate&, (evX0(ev) + evX1(ev) + 1) / 2, (evY0(ev) + evY1(ev) + 1) / 2, playerX, playerY
                CASE 1 ' Counting down
                    evTimer(ev) = evTimer(ev) - 1
                    IF evTimer(ev) <= 0 THEN
                        blastAtX = (evX0(ev) + evX1(ev) + 1) / 2 : blastAtY = (evY0(ev) + evY1(ev) + 1) / 2 : GOSUB BlastAt
                        evState(ev) = 3 : evTimer(ev) = evB(ev)
                    END IF
                CASE 3 ' Re-arming
                    evTimer(ev) = evTimer(ev) - 1 : IF evTimer(ev) <= 0 THEN evState(ev) = 0
            END SELECT
        CASE EV_LASER ' On a frames, off b (b 0: always on); it burns you, and monsters
            evTimer(ev) = evTimer(ev) + 1 : IF evNext(ev) > 0 THEN evNext(ev) = evNext(ev) - 1
            IF LaserOn(ev) AND evNext(ev) = 0 THEN
                IF inside AND NOT dead THEN
                    PlaySfx sndLaser&, 0.9 : damage = 12 : hurtFromX = -1 : hurtFromY = -1 : hurtElectric = -1 : GOSUB HurtPlayer : evNext(ev) = 25
                END IF
                FOR j = 1 TO numMonsters
                    IF monsterState(j) < 2 THEN IF InRoom(ev, monsterX(j), monsterY(j)) THEN target = j : hitDamage = 2 : GOSUB HitMonster : evNext(ev) = 25
                NEXT
            END IF
        CASE EV_CUTTER ' A beam sweeping across the room: CutterAt says where it is
            evTimer(ev) = evTimer(ev) + 1 : IF evNext(ev) > 0 THEN evNext(ev) = evNext(ev) - 1
            IF evNext(ev) = 0 THEN
                CutterAt ev, cutX, cutY, cutAlongX
                IF inside AND NOT dead THEN
                    IF (cutAlongX AND ABS(playerX - cutX) < 0.35) OR (NOT cutAlongX AND ABS(playerY - cutY) < 0.35) THEN
                        PlaySfx sndLaser&, 0.9 : damage = 15 : hurtFromX = -1 : hurtFromY = -1 : hurtElectric = -1 : GOSUB HurtPlayer : evNext(ev) = 30
                    END IF
                END IF
                FOR j = 1 TO numMonsters
                    IF monsterState(j) < 2 THEN
                        IF InRoom(ev, monsterX(j), monsterY(j)) THEN
                            IF (cutAlongX AND ABS(monsterX(j) - cutX) < 0.35) OR (NOT cutAlongX AND ABS(monsterY(j) - cutY) < 0.35) THEN target = j : hitDamage = 3 : GOSUB HitMonster : evNext(ev) = 30
                        END IF
                    END IF
                NEXT
            END IF
        CASE EV_CLOSET ' Walk in: the closets open
            IF evState(ev) = 0 AND inside AND NOT dead THEN
                OpenClosets ev, -1 : evState(ev) = 2
                ShowMsg "It's a trap!"
            END IF
        CASE EV_HOARD ' Sealed until every thief is dead
            IF evCount(ev) = 0 THEN LockRoom ev, -1 : evCount(ev) = 1
            IF evState(ev) = 0 THEN
                thieves = 0 : thievesLeft = 0
                FOR j = 1 TO numMonsters
                    IF monsterType(j) = MT_THIEF THEN thieves = thieves + 1 : IF monsterState(j) < 2 THEN thievesLeft = thievesLeft + 1
                NEXT
                IF thieves > 0 AND thievesLeft = 0 THEN
                    evState(ev) = 2 : LockRoom ev, 0
                    PlaySfx sndHoard&, 1 : PlaySfx sndFanfare&, 0.7
                    ShowMsg "The thieves' hoard is open!"
                END IF
            END IF
        CASE EV_BLACKOUT ' Walk in: the power fails; things come out of the dark
            IF evState(ev) = 0 AND inside AND NOT dead THEN
                evState(ev) = 1 : blackoutTimer = evA(ev) * 60 : evCount(ev) = 0 : evNext(ev) = 60
                PlaySfx sndPowerDown&, 1 : ShowMsg "POWER FAILURE" : Say "blackout", 0
            ELSEIF evState(ev) = 1 THEN
                IF evNext(ev) > 0 THEN evNext(ev) = evNext(ev) - 1
                IF evCount(ev) < evB(ev) AND evNext(ev) = 0 THEN
                    IF SpawnInRoom(ev, VAL(MID$("4414", INT(RND * 4) + 1, 1))) THEN evCount(ev) = evCount(ev) + 1
                    evNext(ev) = 45
                END IF
                IF blackoutTimer > 0 THEN blackoutTimer = blackoutTimer - 1
                IF blackoutTimer = 0 THEN evState(ev) = 2 : PlaySfx sndPowerUp&, 1 : ShowMsg "Power restored"
            END IF
        CASE ELSE
            IF evState(ev) = 0 AND inside AND NOT dead THEN GOSUB StartEvent
            IF evState(ev) = 1 THEN GOSUB StepEvent
    END SELECT
NEXT
RETURN

' --- A thief bot's turn (monster i, hunting): run at you and grab what it
' can - half your ammo, and a gun (the one in your hands, unless that's the
' blaster) - then run home: down the thieves' way (thiefDist, each step to
' a cell nearer the hoard) to its door, where it cowers. Hurt before it's
' got anything, it runs home empty-handed. A level with no hoard: it just
' runs away from you.
ThiefStep:
IF thiefState(i) = 0 AND monsterHurt(i) > 0 THEN thiefState(i) = 1
IF thiefState(i) = 0 THEN
    goX = toPlayerX / distance : goY = toPlayerY / distance
    IF distance < mtypeReach(mtype) AND NOT GlassBetween(monsterX(i), monsterY(i), playerX, playerY) THEN ' Got you: grab
        thiefCells(i) = ammoCount(AM_CELLS) \ 2 : thiefShells(i) = ammoCount(AM_SHELLS) \ 2
        ammoCount(AM_CELLS) = ammoCount(AM_CELLS) - thiefCells(i) : ammoCount(AM_SHELLS) = ammoCount(AM_SHELLS) - thiefShells(i)
        g = 0
        IF currentGun <> W_BLASTER THEN
            g = currentGun
        ELSE
            FOR gg = NUM_GUNS TO 2 STEP -1
                IF hasGun(gg) AND g = 0 THEN g = gg
            NEXT
        END IF
        IF g THEN hasGun(g) = 0 : IF currentGun = g THEN currentGun = W_BLASTER
        thiefGun(i) = g : thiefState(i) = 2
        PlaySfx sndSteal&, 1 : monsterAtk(i) = ATTACK_FRAMES
        t$ = "A THIEF BOT grabbed"
        IF g THEN t$ = t$ + " your " + gunName$(g) + " and"
        ShowMsg t$ + " half your ammo! Get it back!"
        IF RND < 0.5 THEN Say "thief", 0
    END IF
ELSE
    cx = INT(monsterX(i)) : cy = INT(monsterY(i))
    IF thiefDist(cx, cy) >= 30000 THEN ' (no way home: just away from you)
        goX = -toPlayerX / distance : goY = -toPlayerY / distance
    ELSEIF thiefDist(cx, cy) > 0 THEN ' One cell nearer home
        bx = cx : by = cy : bd = thiefDist(cx, cy)
        FOR k = 1 TO 4
            nx = cx + (k = 1) - (k = 2) : ny = cy + (k = 3) - (k = 4)
            IF thiefDist(nx, ny) < bd THEN bd = thiefDist(nx, ny) : bx = nx : by = ny
        NEXT
        tx = bx + 0.5 - monsterX(i) : ty = by + 0.5 - monsterY(i) : tl = SQR(tx * tx + ty * ty)
        IF tl > 0.01 THEN goX = tx / tl : goY = ty / tl
    END IF ' (home: it cowers - goX, goY stay 0)
END IF
RETURN

' --- Event ev begins: you walked in
StartEvent:
evState(ev) = 1 : evCount(ev) = 0 : evNext(ev) = 40
SELECT CASE evType(ev)
    CASE EV_AMBUSH
        LockRoom ev, -1 : PlaySfx sndAlarm&, 1 : ShowMsg "LOCKDOWN! Destroy every hostile to get out" : Say "lockdown", 0
    CASE EV_SURVIVE
        LockRoom ev, -1 : PlaySfx sndAlarm&, 1 : evTimer(ev) = evA(ev) * 60
        ShowMsg "LOCKDOWN! Survive" + STR$(evA(ev)) + " seconds"
    CASE EV_GALLERY
        evTimer(ev) = evA(ev) * 60 : PlaySfx sndAlarm&, 0.6
        ShowMsg "SHOOTING GALLERY! Smash everything in here within" + STR$(evA(ev)) + " seconds"
    CASE EV_NEST
        ShowMsg "A spawner nest! Destroy the portals"
END SELECT
RETURN

' --- Event ev goes on, a frame at a time
StepEvent:
IF evNext(ev) > 0 THEN evNext(ev) = evNext(ev) - 1
alive = 0 ' (its monsters still standing)
FOR j = 1 TO numMonsters
    IF monsterEv(j) = ev AND monsterState(j) < 2 THEN alive = alive + 1
NEXT
SELECT CASE evType(ev)
    CASE EV_AMBUSH ' Monsters arrive a few at a time; win when the last one falls
        IF evCount(ev) < evA(ev) AND alive < 4 AND evNext(ev) = 0 THEN
            IF evB(ev) THEN t = evB(ev) ELSE t = VAL(MID$("1246", INT(RND * 4) + 1, 1)) ' (a mix: drones, gunners, crawlers, stalkers)
            IF SpawnInRoom(ev, t) THEN evCount(ev) = evCount(ev) + 1 : evNext(ev) = 50
        END IF
        IF evCount(ev) >= evA(ev) AND alive = 0 THEN GOSUB WinEvent
    CASE EV_SURVIVE ' Hold out until the timer runs down
        evTimer(ev) = evTimer(ev) - 1
        IF alive < 5 AND evNext(ev) = 0 THEN
            t = VAL(MID$("1446", INT(RND * 4) + 1, 1))
            IF SpawnInRoom(ev, t) THEN evCount(ev) = evCount(ev) + 1
            evNext(ev) = evB(ev)
        END IF
        IF evTimer(ev) <= 0 THEN GOSUB WinEvent
    CASE EV_GALLERY ' Break them all before the time's up
        evTimer(ev) = evTimer(ev) - 1 : left = 0
        FOR j = 1 TO numDecos
            IF decoOn(j) AND InRoom(ev, decoX(j), decoY(j)) THEN left = left + 1
        NEXT
        IF left = 0 THEN
            GOSUB WinEvent
        ELSEIF evTimer(ev) <= 0 THEN
            evState(ev) = 3 : PlaySfx sndFail&, 1 : ShowMsg "TOO SLOW! No prize this time"
        END IF
    CASE EV_NEST ' Spawners send monsters while you're near; win when they're all broken
        left = 0 : near = (playerX - (evX0(ev) + evX1(ev)) / 2) ^ 2 + (playerY - (evY0(ev) + evY1(ev)) / 2) ^ 2 < 196
        FOR j = 1 TO numDecos
            IF decoOn(j) AND decoKind(j) = 9 AND InRoom(ev, decoX(j), decoY(j)) THEN
                left = left + 1
                IF near AND alive < 4 AND evNext(ev) = 0 THEN
                    IF SpawnNear(ev, evA(ev), decoX(j), decoY(j)) THEN evNext(ev) = evB(ev)
                END IF
            END IF
        NEXT
        IF left = 0 THEN GOSUB WinEvent
END SELECT
RETURN

' --- Event ev is won: open the doors, hand over the reward
WinEvent:
evState(ev) = 2 : LockRoom ev, 0
PlaySfx sndFanfare&, 1
IF evReward(ev) THEN
    DropItem evReward(ev), (evX0(ev) + evX1(ev) + 1) / 2, (evY0(ev) + evY1(ev) + 1) / 2
    ShowMsg "ROOM CLEARED! A reward appeared"
ELSE
    ShowMsg "ROOM CLEARED!"
END IF
RETURN

' --- An explosion (or puff of sparks) to show at (newBlastX, newBlastY),
' newBlastSize big, in the first free slot - if all MAX_BLASTS are busy,
' this one isn't shown
AddBlast:
FOR blastSlot = 1 TO MAX_BLASTS
    IF blastTime(blastSlot) = 0 THEN
        blastX(blastSlot) = newBlastX : blastY(blastSlot) = newBlastY
        blastSize(blastSlot) = newBlastSize : blastTime(blastSlot) = BLAST_FRAMES
        SpawnEmbers newBlastX, newBlastY, newBlastSize ' (and a burst of embers: chapter 24's particles)
        AddDecal newBlastX, newBlastY, 0, 0, 0, 1, 0.4 + 0.9 * newBlastSize ' (and a scorch mark on the floor)
        StirDust newBlastX, newBlastY, 0, 0, 1 + 3 * newBlastSize, 0.09 * newBlastSize ' (and blows the dust away)
        EXIT FOR
    END IF
NEXT
RETURN

'-----------------------------------------------------------------------------
' CHAPTER 20: LEVELS
'-----------------------------------------------------------------------------
' A game is ten levels in a row. What you carry - health, armour, ammo,
' guns - goes with you from one to the next, and is remembered as you
' enter each level (EnterLevel), so dying can put you back at the start of
' the level with exactly what you had then (RestartLevel).
'
' LevelDone shows the tally screen. It's a small game loop of its own,
' inside the big one: draw, _DISPLAY, read input, until you click. The
' frame you finished on is kept with _COPYIMAGE(0) (a copy of the screen)
' and drawn darkened behind the numbers. Like Doom's, the numbers don't
' just appear: each one counts up from zero with a gunshot ticking, then
' lands with a boom - zooming in big and slamming down to size while the
' screen shakes. Each row is a little table entry (its label, the number
' it's counting to, what it's out of); one counts at a time, and a press
' while they count finishes them all.
'
' LoadLevel reads a level from its file (chapter 22): ReadLevelFile takes
' it in line by line - the name, the texture files, the floor zones, the
' lights, the event rooms and the 48 rows of the map - and LoadLevel turns
' them into worldMap() and the lists of things.

' --- A new game: level 1, just the blaster
NewGame:
level = 1
NewGameHere: ' (a new game in sector `level` - SELECT SECTOR, YOUR SECTORS)
totalKills = 0 : totalMonsters = 0 : totalTime! = 0
GOSUB StartLoadout
GOSUB EnterLevel
RETURN

' --- What you start a game with (and come back with, when you die): full
' health, no armour, the blaster and 30 cells
StartLoadout:
health = MAX_HP : armor = 0 : ampTimer = 0
ammoCount(AM_CELLS) = 30 : ammoCount(AM_SHELLS) = 0
FOR gun = 1 TO NUM_GUNS : hasGun(gun) = 0 : NEXT
hasGun(W_BLASTER) = -1 : currentGun = W_BLASTER
IF TEST_ALL_GUNS THEN ' Testing: every gun, full ammo
    FOR gun = 1 TO NUM_GUNS : hasGun(gun) = -1 : NEXT
    ammoCount(AM_CELLS) = ammoMax(AM_CELLS) : ammoCount(AM_SHELLS) = ammoMax(AM_SHELLS)
END IF
RETURN

' --- Into level number `level`, remembering what you bring with you
EnterLevel:
savedHealth = health : savedArmor = armor : savedCells = ammoCount(AM_CELLS) : savedShells = ammoCount(AM_SHELLS) : savedGun = currentGun
FOR gun = 1 TO NUM_GUNS : savedHasGun(gun) = hasGun(gun) : NEXT
GOSUB LoadLevel
GOSUB ShowTransmission ' (NEXUS greets you)
RETURN

' --- You died: the level starts over, and you have what you came in with
RestartLevel:
GOSUB StartLoadout ' (a clean slate: full health, the blaster, 30 cells)
GOSUB LoadLevel
RETURN

' --- You used the exit: the level's tally, then on to the next level (after
' the last, the game's totals, and a new game)
LevelDone:
WorldLoopsOff
PlaySfx sndExit&, 0.9
levelTime! = TIMER - levelStart! : IF levelTime! < 0 THEN levelTime! = levelTime! + 86400
totalKills = totalKills + kills : totalMonsters = totalMonsters + numMonsters : totalTime! = totalTime! + levelTime!
taken = 0
FOR i = 1 TO numItems
    IF itemOn(i) = 0 THEN taken = taken + 1
NEXT
' The tally's rows (tallyLabel$ and the rest, chapter 6)
numTally = 3
tallyLabel$(1) = "KILLS" : tallyTarget(1) = kills : tallyTotal(1) = numMonsters
tallyLabel$(2) = "ITEMS" : tallyTarget(2) = taken : tallyTotal(2) = numItems
tallyLabel$(3) = "TIME" : tallyTarget(3) = INT(levelTime!) : tallyTotal(3) = -1
IF level = NUM_LEVELS THEN ' The last level adds the whole game's totals
    numTally = 5
    tallyLabel$(4) = "TOTAL KILLS" : tallyTarget(4) = totalKills : tallyTotal(4) = totalMonsters
    tallyLabel$(5) = "TOTAL TIME" : tallyTarget(5) = INT(totalTime!) : tallyTotal(5) = -1
END IF
FOR i = 1 TO numTally : tallyShown(i) = 0 : tallySlam(i) = -1 : NEXT
IF level = NUM_LEVELS THEN tallyTitle$ = "YOU ESCAPED!" ELSE tallyTitle$ = "SECTOR CLEAR"
IF level = NUM_LEVELS THEN Say "victory", 0
' tallyDone counts the rows finished; tallyWait is a pause (in frames) before
' the next one starts; tallyShake shakes everything after a slam
tallyDone = 0 : tallyWait = 30 : tallyShake = 10 : tallyFrame = 0 : pressWas = -1
PlaySfx sndBarrel&, 0.5 ' The title slams in
screenshot& = _COPYIMAGE(0)
DO
    _LIMIT 60
    tallyFrame = tallyFrame + 1
    click = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN click = -1
    WEND
    pressNow = click OR _KEYDOWN(32) OR _KEYDOWN(13)
    pressed = pressNow AND NOT pressWas : pressWas = pressNow

    ' Count: the next row climbs to its number, a gunshot every few frames;
    ' when it gets there it slams down (a barrel boom, and a shake). A press
    ' while it's counting finishes every row at once.
    IF tallyDone < numTally THEN
        IF pressed THEN
            FOR i = tallyDone + 1 TO numTally : tallyShown(i) = tallyTarget(i) : tallySlam(i) = 0 : NEXT
            tallyDone = numTally : tallyShake = 10 : PlaySfx sndBarrel&, 0.55
            pressed = 0
        ELSEIF tallyWait > 0 THEN
            tallyWait = tallyWait - 1
        ELSE
            n = tallyDone + 1
            countStep = tallyTarget(n) / 40 : IF countStep < 1 THEN countStep = 1 ' (about 2/3 s a row)
            tallyShown(n) = tallyShown(n) + countStep
            IF tallyShown(n) >= tallyTarget(n) THEN
                tallyShown(n) = tallyTarget(n) : tallySlam(n) = 0 : tallyDone = n
                tallyWait = 22 : tallyShake = 8 : PlaySfx sndBarrel&, 0.5
            ELSEIF tallyFrame MOD 4 = 0 THEN
                PlaySfx gunSnd&(W_BLASTER), 0.3
            END IF
        END IF
    ELSEIF pressed AND tallyWait = 0 THEN
        EXIT DO
    ELSEIF tallyWait > 0 THEN
        tallyWait = tallyWait - 1
    END IF
    FOR i = 1 TO numTally
        IF tallySlam(i) >= 0 THEN tallySlam(i) = tallySlam(i) + 1
    NEXT

    ' Draw. A slammed number starts big and eases down to its size over 10
    ' frames - the same ease as the menu's items (chapter 21), backwards.
    CLS , _RGBA32(0, 0, 0, 0) ' (see-through, for OpenGL's view underneath: chapter 24)
    _PUTIMAGE , screenshot&, 0
    LINE (0, 0)-(799, 599), _RGBA32(0, 0, 0, 180), BF
    shakeX = (RND - 0.5) * tallyShake * 2 : shakeY = (RND - 0.5) * tallyShake * 2
    tallyShake = tallyShake * 0.8
    zoomIn = tallyFrame / 12 : IF zoomIn > 1 THEN zoomIn = 1
    titleScale = 5 + 4 * (1 - zoomIn) ^ 2
    MenuText 404 + shakeX, 150 - titleScale * 8 + 4 + shakeY, tallyTitle$, titleScale, _RGBA32(0, 0, 0, 200), 1
    MenuText 400 + shakeX, 150 - titleScale * 8 + shakeY, tallyTitle$, titleScale, _RGB32(80, 255, 140), 1
    MenuText 400 + shakeX, 206 + shakeY, levelName$, 2, _RGB32(255, 255, 255), 1
    FOR i = 1 TO numTally
        IF i <= tallyDone + 1 AND (i <= tallyDone OR tallyWait = 0) THEN ' Started counting
            rowY = 262 + (i - 1) * 44 : IF i > 3 THEN rowY = rowY + 20
            MenuText 230 + shakeX, rowY + shakeY, tallyLabel$(i), 2, _RGB32(160, 200, 255), 0
            value$ = TallyText$(tallyShown(i), tallyTotal(i))
            valueScale = 2 : valueCol~& = _RGB32(255, 255, 255)
            IF tallySlam(i) >= 0 AND tallySlam(i) < 10 THEN
                valueScale = 2 + 4 * (1 - tallySlam(i) / 10) ^ 2 : valueCol~& = _RGB32(255, 240, 120)
            END IF
            ' Centred on the number's middle, so it zooms about itself
            MenuText 570 - LEN(value$) * 8 + shakeX, rowY + 16 - valueScale * 8 + shakeY, value$, valueScale, valueCol~&, 1
        END IF
    NEXT
    IF tallyDone = numTally AND tallyWait = 0 AND (tallyFrame \ 20) MOD 3 > 0 THEN
        IF level >= NUM_LEVELS THEN prompt$ = "CLICK OR PRESS SPACE TO PLAY AGAIN" ELSE prompt$ = "CLICK OR PRESS SPACE FOR THE NEXT SECTOR"
        MenuText 400, 520, prompt$, 1, _RGB32(220, 220, 240), 1
    END IF
    IF glReady THEN GLSL_filter_capture ' (OpenGL draws the tally over its view: chapter 24)
    GLScreenLayer glReady
    _DISPLAY
LOOP
_FREEIMAGE screenshot&
IF level > NUM_LEVELS THEN ' (your own sector: again, from the start)
    GOSUB RestartLevel
ELSEIF level = NUM_LEVELS THEN
    GOSUB NewGame
ELSE
    GOSUB ShowRoute ' (where you've been, where you're going)
    level = level + 1 : GOSUB EnterLevel
END IF
RETURN

' --- Every sector's name (the name = line of each level's file), for the
' route map
ReadSectorNames:
FOR k = 1 TO NUM_LEVELS
    ReadLevelFile k : sectorName$(k) = lvlName$
NEXT
FOR k = NUM_LEVELS + 1 TO NUM_LEVELS + MAX_CUSTOM : sectorName$(k) = SectorNameOf$(k) : NEXT
RETURN

' --- A new sector of your own (GAME > YOUR SECTORS > NEW SECTOR, or the
' newsector command): the first free number's file, made blank
' (WriteBlankSector), then a game in it - in the editor. level stays as
' it was if there's no room for another.
NewSector:
newN = 0
FOR k = NUM_LEVELS + 1 TO NUM_LEVELS + MAX_CUSTOM
    IF newN = 0 AND NOT _FILEEXISTS(LevelFile$(k)) THEN newN = k
NEXT
IF newN = 0 THEN ShowMsg "No room for another sector - there can be" + STR$(MAX_CUSTOM) : ConPrint "newsector: all" + STR$(MAX_CUSTOM) + " are made" : RETURN
WriteBlankSector newN
sectorName$(newN) = SectorNameOf$(newN)
level = newN : GOSUB NewGameHere
GOSUB EditEnter
EditNote "NEW SECTOR " + LTRIM$(STR$(newN)) + ": carve out rooms with . - Ctrl+S saves"
ConPrint "newsector: " + LevelFile$(newN)
RETURN

' --- THE ROUTE: between sectors, a map of all of them (like DOOM's between
' episodes' levels) - the way you've come lit up, a marker travelling from
' the sector you've cleared to the next one, which then blinks YOU ARE
' HERE. The map's a placeholder: each sector a node on a route (SectorAt,
' chapter 23), over the menu's backdrop. Any key or a click goes on.
ShowRoute:
routeT = 0 : pressWas = -1 : routeTravel = 90 ' (frames the marker takes to get there)
DO
    _LIMIT 60
    routeT = routeT + 1
    click = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN click = -1
    WEND
    press = click OR _KEYDOWN(32) OR _KEYDOWN(13)
    IF press AND NOT pressWas AND routeT > 20 THEN EXIT DO
    pressWas = press
    DrawMenuBackdrop routeT
    LINE (0, 0)-(799, 599), _RGBA32(6, 0, 16, 170), BF
    MenuText 400, 40, "SECTOR MAP", 4, _RGB32(80, 255, 140), 1
    ' The route: lines between sectors - bright where you've been, dim ahead
    FOR n = 1 TO NUM_LEVELS - 1
        SectorAt n, ax, ay : SectorAt n + 1, bx, by
        IF n < level THEN lineCol~& = _RGB32(80, 255, 220) ELSE lineCol~& = _RGBA32(120, 100, 180, 140)
        FOR k = -1 TO 1 : LINE (ax, ay + k)-(bx, by + k), lineCol~& : NEXT
    NEXT
    ' The marker's way, from here to the next sector, drawn in as it goes
    f = routeT / routeTravel : IF f > 1 THEN f = 1
    SectorAt level, ax, ay : SectorAt level + 1, bx, by
    mx = ax + (bx - ax) * f : my = ay + (by - ay) * f
    FOR k = -2 TO 2 : LINE (ax, ay + k)-(mx, my + k), _RGB32(255, 220, 90) : NEXT
    ' The sectors: cleared (green), the next (blinking), the rest (dim)
    FOR n = 1 TO NUM_LEVELS
        SectorAt n, sx, sy
        IF n <= level THEN
            FillCircle sx, sy, 13, _RGB32(30, 120, 80) : FillCircle sx, sy, 9, _RGB32(80, 255, 140)
            nameCol~& = _RGB32(150, 255, 190)
        ELSEIF n = level + 1 THEN
            FillCircle sx, sy, 13, _RGB32(120, 90, 20) : FillCircle sx, sy, 9, _RGB32(255, 220, 90)
            nameCol~& = _RGB32(255, 230, 140)
        ELSE
            FillCircle sx, sy, 11, _RGB32(50, 40, 80) : FillCircle sx, sy, 7, _RGB32(90, 80, 130)
            nameCol~& = _RGB32(140, 130, 170)
        END IF
        nm$ = sectorName$(n) : c = INSTR(nm$, ": ") : IF c THEN nm$ = MID$(nm$, c + 2)
        MenuText sx, sy + 18, nm$, 1, nameCol~&, 1
        MenuText sx, sy - 30, LTRIM$(STR$(n)), 1, nameCol~&, 1
    NEXT
    FillCircle mx, my, 6, _RGB32(255, 255, 255) ' The marker
    ' YOU ARE HERE: on the marker once it's arrived, blinking, with an arrow
    IF f >= 1 AND (routeT \ 20) MOD 3 > 0 THEN
        MenuText bx, by - 70, "YOU ARE HERE", 2, _RGB32(255, 240, 120), 1
        FOR k = 0 TO 8 : LINE (bx - 8 + k, by - 44 + k)-(bx + 8 - k, by - 44 + k), _RGB32(255, 240, 120) : NEXT
    END IF
    MenuText 400, 560, "CLICK OR PRESS SPACE TO GO ON", 1, _RGB32(220, 220, 240), 1
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
_KEYCLEAR
RETURN

' --- Start (or restart) the level: read its map, and reset everything in it
LoadLevel:
ReadLevelFile level ' (its file: neon-caster/levels/levelN.txt - chapter 22)
IF NOT lvlOK THEN PRINT "Can't read the level file "; LevelFile$(level) : SLEEP : SYSTEM
' The editor comes in here (editRebuild on): the level built again from
' lvlRow$() and the rest, as it's been changed - not from its file
BuildLevel:
IF cyberOn THEN CyberTextures 0 : cyberOn = 0 ' (died in the network: the real pictures back)
numStations = 0 : numPads = 0 : numTerms = 0
IF NOT editRebuild THEN glReady = 0 ' (OpenGL: nothing to draw until the level's first frame - chapter 24)
FOR i = 1 TO MAX_PART : partLife(i) = 0 : NEXT : pitch = 0 : ampTimer = 0
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
    worldMap(x, y) = 0 : doorOpen(x, y) = 0 : doorMove(x, y) = 0 : doorWait(x, y) = 0 : doorLock(x, y) = 0 : doorKey(x, y) = 0 : closetCell(x, y) = 0 : doorType(x, y) = 0 : diagCorner(x, y) = 0 : glassHP(x, y) = 0 : glassDir(x, y) = 0 : floorH(x, y) = 0 : ceilH(x, y) = 1
    floorTex(x, y) = T_FLOOR + 1 : ceilTex(x, y) = T_CEIL + 1 : floorSplit(x, y) = 0 : ceilSplit(x, y) = 0 : decoCell(x, y) = 0
    FOR f = 1 TO 8 : faceTex(x, y, f) = 0 : faceTex2(x, y, f) = 0 : faceDiv(x, y, f) = 0 : NEXT
    cellSeen(x, y) = 0
NEXT : NEXT
numItems = 0 : numMonsters = 0 : numDecos = 0 : hasMap = 0 : mapOpen = 0
FOR k = 1 TO 3 : hasCard(k) = 0 : NEXT
FOR i = 1 TO MAX_BOLTS : boltOn(i) = 0 : NEXT
FOR i = 1 TO MAX_BLASTS : blastTime(i) = 0 : NEXT
levelName$ = lvlName$
' Its pictures - only those that aren't already in their slots (texFile$)
texNew = 0
FOR k = 1 TO 6 ' Walls # N C K P G
    IF texFile$(k) <> lvlWall$(k) THEN LoadTex lvlWall$(k), k : texFile$(k) = lvlWall$(k) : texNew = -1
NEXT
FOR k = 1 TO 4
    IF texFile$(T_FLOOR + k) <> lvlFloor$(k) THEN LoadTex lvlFloor$(k), T_FLOOR + k : texFile$(T_FLOOR + k) = lvlFloor$(k) : texNew = -1
NEXT
FOR k = 1 TO 2
    IF texFile$(T_CEIL + k) <> lvlCeil$(k) THEN LoadTex lvlCeil$(k), T_CEIL + k : texFile$(T_CEIL + k) = lvlCeil$(k) : texNew = -1
NEXT
IF texNew OR NOT editRebuild THEN MakeLiftTex ' (the lifts' pictures, from these)
IF NOT editRebuild THEN glTexVersion = glTexVersion + 1 ' (a new level: OpenGL needs it all again - chapter 24)
ambientLevel = lvlAmb(1) : ambientTintR = lvlAmb(2) : ambientTintG = lvlAmb(3) : ambientTintB = lvlAmb(4) ' The level's ambient light: brightness, then colour
ambientR = ambientLevel * ambientTintR / 255 : ambientG = ambientLevel * ambientTintG / 255 : ambientB = ambientLevel * ambientTintB / 255
FOR k = 1 TO 7
    IF k <> 2 THEN wallMapColor(k) = MinimapColor~&(wallTexSlot(k))
NEXT
wallMapColor(8) = _RGB32(60, 240, 255) : wallMapColor(9) = _RGB32(90, 255, 120) ' (data stations, code terminals: bright on the map)
' Floor and ceiling zones (chapter 22): each paints a rectangle - or the
' triangle on one side of its diagonal - with a floor and/or ceiling texture
FOR k = 1 TO lvlNumZones
    zoneX0 = lvlZone(k, 1) : zoneY0 = lvlZone(k, 2) : zoneX1 = lvlZone(k, 3) : zoneY1 = lvlZone(k, 4)
    zoneFloor = lvlZone(k, 5) : zoneCeil = lvlZone(k, 6) : zoneShape = lvlZone(k, 7)
    zoneSize = zoneX1 - zoneX0
    FOR y = zoneY0 TO zoneY1 : FOR x = zoneX0 TO zoneX1
        ' Is the cell in the zone (1), outside it (0), or cut by its diagonal
        ' (2: the half on the zoneShape corner's side is in)? i and j are the
        ' cell's place in the zone; for a triangle, i + j or i - j says which
        ' side of the diagonal it's on, like the diagonal walls' maths.
        i = x - zoneX0 : j = y - zoneY0 : zonePart = 1
        SELECT CASE zoneShape
            CASE 1 : IF i + j > zoneSize THEN zonePart = 0 ELSE IF i + j = zoneSize THEN zonePart = 2
            CASE 2 : IF j > i THEN zonePart = 0 ELSE IF j = i THEN zonePart = 2
            CASE 3 : IF i + j < zoneSize THEN zonePart = 0 ELSE IF i + j = zoneSize THEN zonePart = 2
            CASE 4 : IF i > j THEN zonePart = 0 ELSE IF i = j THEN zonePart = 2
        END SELECT
        IF zonePart = 1 THEN
            IF zoneFloor THEN floorTex(x, y) = T_FLOOR + zoneFloor : floorSplit(x, y) = 0
            IF zoneCeil THEN ceilTex(x, y) = T_CEIL + zoneCeil : ceilSplit(x, y) = 0
        ELSEIF zonePart = 2 THEN
            IF zoneFloor THEN floorTex2(x, y) = T_FLOOR + zoneFloor : floorSplit(x, y) = zoneShape
            IF zoneCeil THEN ceilTex2(x, y) = T_CEIL + zoneCeil : ceilSplit(x, y) = zoneShape
        END IF
    NEXT : NEXT
NEXT
' Single faces' own pictures ([faces]): each picture a slot of its own
' (T_CUSTOM + 1...), loaded only if it isn't there already
customN = 0
FOR k = 1 TO lvlNumFaces
    x = lvlFaceX(k) : y = lvlFaceY(k) : f = lvlFaceS(k)
    IF x >= 0 AND y >= 0 AND x < MAP_SIZE AND y < MAP_SIZE THEN
        FOR half = 1 TO 2
            IF half = 1 THEN pic$ = lvlFaceP1$(k) ELSE pic$ = lvlFaceP2$(k)
            slot = 0
            IF pic$ <> "" THEN
                FOR j = T_CUSTOM + 1 TO T_CUSTOM + customN
                    IF texFile$(j) = pic$ THEN slot = j
                NEXT
                IF slot = 0 AND customN < T_CUSTOMN AND _FILEEXISTS(ArtPath$(pic$)) THEN
                    customN = customN + 1 : slot = T_CUSTOM + customN
                    IF texFile$(slot) <> pic$ THEN LoadTex pic$, slot : texFile$(slot) = pic$ : texNew = -1
                END IF
            END IF
            IF half = 1 THEN slot1 = slot ELSE slot2 = slot
        NEXT
        IF slot2 = 0 THEN slot2 = slot1
        SELECT CASE f
            CASE 9 : IF slot1 THEN floorTex(x, y) = slot1 : floorSplit(x, y) = 0
            CASE 10 : IF slot1 THEN ceilTex(x, y) = slot1 : ceilSplit(x, y) = 0
            CASE 1 TO 8 : faceTex(x, y, f) = slot1 : faceTex2(x, y, f) = slot2 : faceDiv(x, y, f) = lvlFaceD(k)
        END SELECT
    END IF
NEXT
' The level's lights: x, y, radius, brightness, red, green, blue, effect
numLights = 0
FOR l = 1 TO MAX_LIGHTS : lightBroken(l) = 0 : NEXT
FOR d = 1 TO MAX_DECALS : decalOn(d) = 0 : NEXT ' (no marks on a new level)
FOR k = 1 TO lvlNumLights
    lx = lvlLight(k, 1) : ly = lvlLight(k, 2) : lRadius = lvlLight(k, 3) : lBright = lvlLight(k, 4)
    lRed = lvlLight(k, 5) : lGreen = lvlLight(k, 6) : lBlue = lvlLight(k, 7) : lEffect = lvlLight(k, 8)
    AddLight lx, ly, lRadius, lBright * lRed / 255, lBright * lGreen / 255, lBright * lBlue / 255, lEffect, 0
NEXT
' The level's event rooms: kind, x0, y0, x1, y1, a, b, reward
numEvents = lvlNumEvents
FOR k = 1 TO numEvents
    evType(k) = lvlEvent(k, 1) : evX0(k) = lvlEvent(k, 2) : evY0(k) = lvlEvent(k, 3) : evX1(k) = lvlEvent(k, 4)
    evY1(k) = lvlEvent(k, 5) : evA(k) = lvlEvent(k, 6) : evB(k) = lvlEvent(k, 7) : evReward(k) = lvlEvent(k, 8)
    evState(k) = 0 : evTimer(k) = 0 : evCount(k) = 0 : evNext(k) = 0 : evGlow(k) = 0
    IF evType(k) = EV_TRAP OR evType(k) = EV_FIRETRAP THEN ' (its floor: its own picture, so you can see where it is)
        FOR y = evY0(k) TO evY1(k) : FOR x = evX0(k) TO evX1(k)
            IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN floorSplit(x, y) = 0 : IF evType(k) = EV_FIRETRAP THEN floorTex(x, y) = T_FIRE ELSE floorTex(x, y) = T_TRAP
        NEXT : NEXT
    END IF
NEXT
FOR y = 0 TO MAP_SIZE - 1
    row$ = lvlRow$(y)
    FOR x = 0 TO MAP_SIZE - 1
        cell$ = MID$(row$, x + 1, 1)
        SELECT CASE cell$
            CASE "#" : worldMap(x, y) = 1
            CASE "%" : worldMap(x, y) = 1 : closetCell(x, y) = -1 ' A closet's secret wall (its look: the walls beside it - AssignClosets)
            CASE "N" : worldMap(x, y) = 3
            CASE "C" : worldMap(x, y) = 4
            CASE "K" : worldMap(x, y) = 5
            CASE "P" : worldMap(x, y) = 6
            CASE "G" : worldMap(x, y) = 7
            CASE "D" : worldMap(x, y) = 2
            CASE "H" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_SHUTTER
            CASE "X" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_SPLIT
            CASE "/" : diagCorner(x, y) = -1 ' Diagonal wall (which half is solid: below)
            CASE "\" : diagCorner(x, y) = -2
            CASE "E" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_EXIT
            CASE "R", "B", "Y" ' Key door: needs that keycard
                worldMap(x, y) = 2 : doorKey(x, y) = INSTR("RBY", cell$)
            CASE "r", "b", "y", "+", "a", "e", "2", "3", "u", "*", "4", "M", "q", "j" ' Something to pick up
                IF numItems < MAX_ITEMS THEN
                    numItems = numItems + 1
                    itemX(numItems) = x + 0.5 : itemY(numItems) = y + 0.5 : itemOn(numItems) = -1
                    itemKind(numItems) = INSTR("rby+ae23u*4Mqj", cell$)
                END IF
            CASE "@" ' A data station: a wall with a socket
                worldMap(x, y) = 8
                IF numStations < MAX_STATIONS THEN numStations = numStations + 1 : stationX(numStations) = x : stationY(numStations) = y : stationDone(numStations) = 0
            CASE "!" : worldMap(x, y) = 2 : doorLock(x, y) = 2 ' A door sealed until its data station is hacked (the nearest)
            CASE "$" ' A code terminal: a wall with a screen
                worldMap(x, y) = 9
                IF numTerms < MAX_TERMS THEN numTerms = numTerms + 1 : termX(numTerms) = x : termY(numTerms) = y : termDone(numTerms) = 0
            CASE "&" ' A teleporter's pad
                IF numPads < MAX_PADS THEN numPads = numPads + 1 : padX(numPads) = x : padY(numPads) = y
            CASE "=" : glassHP(x, y) = GLASS_HP ' Glass: floor, with a pane across it (AssignGlass)
            CASE "o", "i", "p", "t", "x", "l", "n", "f", "S", "d", "A", "F", "I", "J", "L", "O", "Q", "U", "W", "Z", "V" ' A decoration
                IF numDecos < MAX_DECO THEN
                    numDecos = numDecos + 1 : decoCell(x, y) = numDecos
                    decoX(numDecos) = x + 0.5 : decoY(numDecos) = y + 0.5 : decoKind(numDecos) = INSTR("oiptxlnfSdAFIJLOQUWZV", cell$) : decoOn(numDecos) = -1 : decoFuse(numDecos) = 0
                    decoHP(numDecos) = DecoMaxHP(decoKind(numDecos)) : decoTimer(numDecos) = 0
                END IF
            CASE "m", "g", "h", "c", "s", "k", "w", "z", "T" ' A monster
                IF numMonsters < MAX_MON THEN
                    numMonsters = numMonsters + 1
                    monsterX(numMonsters) = x + 0.5 : monsterY(numMonsters) = y + 0.5 : monsterType(numMonsters) = INSTR("mghcskwzT", cell$)
                    monsterHP(numMonsters) = mtypeHP(monsterType(numMonsters)) : monsterState(numMonsters) = 0 : monsterTimer(numMonsters) = 0 : monsterHurt(numMonsters) = 0
                    monsterEv(numMonsters) = 0 : ThiefReset numMonsters
                END IF
            CASE "<", ">", "^", "v" ' Player start, facing the arrow's way
                playerX = x + 0.5 : playerY = y + 0.5
                dirX = (cell$ = "<") - (cell$ = ">") : dirY = (cell$ = "^") - (cell$ = "v")
        END SELECT
    NEXT
NEXT
' Diagonal walls: the map only says "/" or "\", so which half is solid?
' Score each half by the walls beside it (a whole wall counts 2, another
' diagonal 1) and the better side wins. A "/" can only be solid top-left (1)
' or bottom-right (3), a "\" top-right (2) or bottom-left (4). It takes the
' look of the wall beside its solid half (N if there's none).
FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
    IF diagCorner(x, y) < 0 THEN
        bestScore = -1
        FOR k = -diagCorner(x, y) TO 4 STEP 2 ' "/" (-1) tries corners 1 and 3, "\" (-2) 2 and 4
            IF k <= 2 THEN nbY = y - 1 ELSE nbY = y + 1
            IF k = 2 OR k = 3 THEN nbX = x + 1 ELSE nbX = x - 1
            score = 0
            IF diagCorner(x, nbY) THEN score = score + 1 ELSE IF IsWall(x, nbY) THEN score = score + 2
            IF diagCorner(nbX, y) THEN score = score + 1 ELSE IF IsWall(nbX, y) THEN score = score + 2
            IF score > bestScore THEN bestScore = score : bestCorner = k : bestNbX = nbX : bestNbY = nbY
        NEXT
        diagCorner(x, y) = bestCorner : worldMap(x, y) = 3
        IF IsWall(x, bestNbY) THEN worldMap(x, y) = worldMap(x, bestNbY) ELSE IF IsWall(bestNbX, y) THEN worldMap(x, y) = worldMap(bestNbX, y)
    END IF
NEXT : NEXT
' Things that glow by themselves get a light of their own: lamps (cyan;
' every fourth one flickers), terminals (a faint green pulse), and the exit
' (green). A lamp or terminal's light belongs to it, so it goes out when
' it's broken.
FOR i = 1 TO numDecos
    IF decoKind(i) = 2 THEN AddLight decoX(i), decoY(i), 4, 110, 190, 220, (i MOD 4 = 0) * -FX_FLICKER, i
    IF decoKind(i) = 4 THEN AddLight decoX(i), decoY(i), 2.5, 40, 90, 70, FX_PULSE, i
    IF decoKind(i) = 6 THEN AddLight decoX(i), decoY(i), 2.5, 30, 70, 160, FX_FLICKER, i ' Server racks: blinking cyan
    IF decoKind(i) = 7 THEN AddLight decoX(i), decoY(i), 3, 150, 50, 120, FX_STEADY, i ' Vending machines: pink neon
    IF decoKind(i) = 9 THEN AddLight decoX(i), decoY(i), 4, 130, 50, 180, FX_PULSE, i ' Spawners: a purple throb
    SELECT CASE decoKind(i) ' The set pieces that light up
        CASE 11 : AddLight decoX(i), decoY(i), 2.5, 50, 100, 90, FX_FLICKER, i ' Console: green-cyan
        CASE 12 : AddLight decoX(i), decoY(i), 3, 50, 80, 140, FX_FLICKER, i ' Monitors: blue
        CASE 13 : AddLight decoX(i), decoY(i), 3, 40, 140, 60, FX_PULSE, i ' Specimen: green
        CASE 15 : AddLight decoX(i), decoY(i), 3, 140, 100, 40, FX_FIRE, i ' Generator: orange
        CASE 16 : AddLight decoX(i), decoY(i), 2.5, 50, 110, 150, FX_STEADY, i ' Cryo pod: icy
        CASE 17 : AddLight decoX(i), decoY(i), 3.5, 40, 110, 170, FX_PULSE, i ' Hologram: blue
    END SELECT
NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
    IF worldMap(x, y) = 2 AND doorType(x, y) = DOOR_EXIT THEN AddLight x + 0.5, y + 0.5, 3.5, 50, 160, 70, FX_PULSE, 0
NEXT : NEXT
BuildLights ' Which cells each light reaches (now the walls are all in place)
BuildShafts ' ...and which have a beam of light (chapter 24)
AssignClosets ' (each secret wall: its closet, and its look)
AssignGlass ' (which way each pane of glass runs)
' Every cell's floor and ceiling height ([floor] and [ceiling]); and you
' standing on your floor
levelFlat = -1
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
    floorH(x, y) = HeightOf(MID$(lvlFloorRow$(y), x + 1, 1), 0) : ceilH(x, y) = HeightOf(MID$(lvlCeilRow$(y), x + 1, 1), 1)
    IF ceilH(x, y) < floorH(x, y) + 0.25 THEN ceilH(x, y) = floorH(x, y) + 0.25 ' (never through the floor)
    IF floorH(x, y) <> 0 OR ceilH(x, y) <> 1 THEN levelFlat = 0
NEXT : NEXT
' The lifts: their cells start at their low height
numLifts = 0
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE : liftCell(x, y) = 0 : NEXT : NEXT
WorldLoopsOff ' (the last level's lifts' motors)
FOR k = 1 TO lvlNumLifts
    numLifts = numLifts + 1
    liftX0(k) = MinOf(lvlLift(k, 1), lvlLift(k, 3)) : liftY0(k) = MinOf(lvlLift(k, 2), lvlLift(k, 4))
    liftX1(k) = MaxOf(lvlLift(k, 1), lvlLift(k, 3)) : liftY1(k) = MaxOf(lvlLift(k, 2), lvlLift(k, 4))
    liftLow(k) = lvlLift(k, 5) * H_STEP : liftHigh(k) = lvlLift(k, 6) * H_STEP : liftMode(k) = lvlLift(k, 7)
    liftSpeed(k) = lvlLift(k, 8) * H_STEP / 60 : IF liftSpeed(k) <= 0 THEN liftSpeed(k) = 0.01
    liftZ(k) = liftLow(k) : liftDir(k) = 0 : liftWait(k) = 60 : liftWasDir(k) = 0
    FOR y = liftY0(k) TO liftY1(k) : FOR x = liftX0(k) TO liftX1(k)
        IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN liftCell(x, y) = k : floorH(x, y) = liftZ(k) : levelFlat = 0 : floorTex(x, y) = T_LIFT : floorSplit(x, y) = 0 ' (a lift's top: its own plate - MakeLiftTex)
    NEXT : NEXT
NEXT
' The triggers, taken apart; the teleporters' pads, glowing
numTrigs = 0
FOR k = 1 TO lvlNumTrigs : TakeTrigger lvlTrig$(k) : NEXT
FOR k = 1 TO numPads : AddLight padX(k) + 0.5, padY(k) + 0.5, 2.5, 120, 60, 220, FX_PULSE, 0 : NEXT
padReady = 0
IF NOT editRebuild THEN playerZ = floorH(INT(playerX), INT(playerY)) : playerVZ = 0 : eyeZ = playerZ + EYE_H
walkZ = -999
BuildThiefWay ' (the thieves' way home)
blackoutTimer = 0
monStartN = numMonsters ' (the level's monsters as they start, for the console's respawn)
FOR i = 1 TO numMonsters : monStartX(i) = monsterX(i) : monStartY(i) = monsterY(i) : monStartType(i) = monsterType(i) : NEXT
' The camera plane (chapter 8): your direction turned 90 degrees, fovPlane long
planeX = dirY * fovPlane : planeY = - dirX * fovPlane
aimAmount = 0 : zoom = 1 : viewH = RENDER_H
kills = 0 : dead = 0 : swapTimer = 0
hurtFlash = 0 : pickFlash = 0 : muzzleFlash = 0 : recoil = 0 : railBeam = 0
fireWait = 20 ' (so the click that started the level doesn't fire)
bobPhase = 2.2 ' The first footstep sounds soon after you start walking (a foot lands at pi)
levelStart! = TIMER : shake = 0 : hurtFromX = -1
FOR i = 1 TO MAX_HURTDIRS : hurtDirTime(i) = 0 : NEXT
IF NOT editRebuild THEN PlayMusic SectorMusic&(level) : ShowMsg levelName$ + "  -  find the EXIT"
' (built again in the editor: OpenGL's turn now - new pictures if any,
' and the world again. Only now: SUB _GL runs alongside this, and asked
' halfway through it would build half a level)
IF editRebuild THEN
    IF texNew THEN glRetexVersion = glRetexVersion + 1
    glMeshVersion = glMeshVersion + 1
END IF
RETURN

'-----------------------------------------------------------------------------
' CHAPTER 21: THE SPLASH SCREEN, THE MENU, SETTINGS AND SAVED GAMES
'-----------------------------------------------------------------------------
' Everything around the game itself. Like the tally screen (chapter 20),
' the splash screen and the menu are small loops of their own - draw,
' _DISPLAY, read input - that run until they're done, with the game
' waiting outside them.
'
' THE MENU is driven by a list. Each screen of it (the SCR_ constants) is
' just a list of items - a button, a way into another screen, a slider, an
' on/off toggle, a "< choice >", a key binding, or a line of text (the MI_
' kinds) - which BuildMenu (chapter 23) fills in. One loop, RunMenu, then
' draws and drives any screen the same way: move up and down the list,
' change the item you're on, or choose it. Going into a screen pushes the
' one you were on onto menuStack(), and BACK pops it off again.
'
' Two ways to read the keyboard: _KEYDOWN(code) says whether a key is held
' down right now - right for walking, where holding the key keeps you
' going. _KEYHIT hands you each press once, as it happens - right for a
' menu, where one press should move one line. The mouse: in the game it's
' captured for mouse look (chapter 1); the menu frees it with _MOUSESHOW,
' so you can point and click, and _MOUSEHIDE _DISABLE captures it again.
'
' The items slide in one after another as a screen opens. Each one's
' progress p goes from 0 to 1 over 12 frames, a little later than the one
' above; 1 - (1 - p) ^ 3 "eases" it - quick at first, gently settling - and
' that moves it in from the right and fades it in.
'
' SETTINGS are one table, setting(), made by the DefineSetting lines in
' chapter 6: the menu shows each one with the control its kind needs, and
' ApplySettings puts them into effect. They're kept in a plain text file,
' neon-caster/saves/settings.ini - one "name=value" line each - so you can
' read and edit it too. (One isn't a number: qb64pe=, where the compiler
' the code terminals use is - qbChosen$, SETTINGS > QB64PE COMPILER.) Key bindings work the same way (KeyHeld, chapter
' 23, is how the game asks about a key).
'
' SAVED GAMES are BINARY files. PUT writes a variable's bytes into the file
' and GET reads them back, so LoadGame just GETs the very same variables,
' in the very same order, that SaveGame PUT. A save holds the level you're
' on and everything that has changed since it started: you, your gear,
' every door, pickup, monster and decoration. Loading rebuilds the level
' from its map (LoadLevel, chapter 20) and then puts all of that back.
'
' THE EDITORS (F2 in the game): the LEVEL EDITOR has two views of the same
' level - the map from above (RunEditor: paint its characters with the
' mouse, lights, heights) and walking round inside it (EditFP: the game,
' frozen, with a "cursor ray" from your crosshair - click builds, right-
' click knocks down, keys change the pictures live). Every change goes
' into the level as its file says it (lvlRow$() and the rest) and the
' level is built again from that (BuildLevel), and Ctrl+S writes the file.
' The MONSTER EDITOR (M) and the HUD LAYOUT editor (U) do the same for
' monsters.txt and hud.txt: plain text files, read at the start, changed
' live, written back - one way of keeping a game's numbers outside it.

' --- A runtime error, anywhere (ON ERROR GOTO GameError, at the very
' start). Without this QB64PE stops the game with a "Continue?" box -
' behind a full-screen window, where you may not even see it. Instead: a
' line in neon-caster/saves/errors.log (which error, and the line it was
' on - _ERRORLINE), the same in the console, a message the first time,
' and on from the statement after it (RESUME NEXT). Most are one bad
' number in one frame; carrying on beats stopping. (No more than 100 are
' written, so one in a loop can't fill the disk.)
GameError:
errCount = errCount + 1
errText$ = "ERROR" + STR$(ERR) + " (" + _ERRORMESSAGE$(ERR) + ") at line" + STR$(_ERRORLINE)
IF errCount <= 100 THEN
    ConPrint errText$
    MakeSaveDir : errNum = FREEFILE
    OPEN SaveDir$ + "errors.log" FOR APPEND AS #errNum
    PRINT #errNum, DATE$ + " " + TIME$ + "  NEON-CASTER " + GAME_VERSION$ + "  " + errText$
    CLOSE #errNum
END IF
IF errCount = 1 THEN ShowMsg "Something went wrong - written to saves/errors.log. Carrying on."
RESUME NEXT

' --- The splash screen: up for SPLASH_SECONDS, or until a key or a click.
' DrawSplash (chapter 23) draws it - its picture if there's a splash.png,
' or else the title.
ShowSplash:
splashStart! = TIMER
DO
    _LIMIT 60
    splashTime! = TIMER - splashStart! : IF splashTime! < 0 THEN splashTime! = splashTime! + 86400
    DrawSplash splashTime!
    _DISPLAY
    anyInput = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) OR _MOUSEBUTTON(2) THEN anyInput = -1
    WEND
    IF _KEYHIT > 0 THEN anyInput = -1
LOOP UNTIL splashTime! > SPLASH_SECONDS OR (anyInput AND splashTime! > 0.3)
_KEYCLEAR
RETURN

' --- The menu. menuInGame says where it was opened from: the title (0) or
' a game (-1, Esc). In a game, the frame you left is kept and shown
' darkened behind it; at the title it's the synthwave backdrop and music.
' It runs until you start, load or go back to a game (or quit).
RunMenu:
WorldLoopsOff ' (the game waits: so do the lifts' motors)
_MOUSESHOW
IF menuInGame THEN menuBackdrop& = _COPYIMAGE(0) ELSE PlayMusic menuMusic&
menuDepth = 0 : menuScreen = SCR_MAIN : GOSUB EnterMenuScreen
menuDone = 0 : menuCapture = 0 : menuTyping = 0 : menuDrag = 0 : mouseWasDown = -1 : menuDispWas = displayModeNow : menuPointWait = 0
_KEYCLEAR
DO
    _LIMIT 60
    DisplayFollow ' (Alt + Enter changes DISPLAY)
    menuT = menuT + 1

    ' The keyboard: every press since last frame, one at a time
    keyCode& = _KEYHIT
    DO WHILE keyCode& <> 0 AND NOT menuDone
        IF keyCode& > 0 THEN ' (a negative code is a key being let go)
            IF menuCapture THEN
                GOSUB CaptureKey
            ELSEIF menuTyping THEN
                GOSUB MenuTypeKey
            ELSE
                SELECT CASE keyCode&
                    CASE 18432, 119, 87 : menuMove = -1 : GOSUB MenuMoveSel ' Up, W
                    CASE 20480, 115, 83 : menuMove = 1 : GOSUB MenuMoveSel ' Down, S
                    CASE 19200, 97, 65 : menuAdjust = -1 : GOSUB MenuAdjustItem ' Left, A
                    CASE 19712, 100, 68 : menuAdjust = 1 : GOSUB MenuAdjustItem ' Right, D
                    CASE 13, 32 : GOSUB MenuActivate ' Enter, Space
                    CASE 27, 8 : GOSUB MenuBack ' Esc, Backspace
                END SELECT
            END IF
        END IF
        keyCode& = _KEYHIT
    LOOP

    ' The mouse: point at an item to pick it, click to choose it, click or
    ' drag along a slider to set it. (Pointing only takes over when the
    ' mouse moves, so it doesn't fight the keyboard.)
    WHILE _MOUSEINPUT : WEND
    mouseX = WideMouseX(_MOUSEX) : mouseY = _MOUSEY : mouseDown = _MOUSEBUTTON(1)
    ' (The display switching - DISPLAY, or a MODE - moves where the mouse
    ' seems to be without it moving: so for half a second after, pointing
    ' doesn't count, or it would pick whatever item is under it now.)
    IF displayModeNow <> menuDispWas THEN menuDispWas = displayModeNow : menuPointWait = 30
    IF menuPointWait > 0 THEN menuPointWait = menuPointWait - 1 : lastMouseX = mouseX : lastMouseY = mouseY
    IF NOT menuDone AND menuCapture = 0 AND menuTyping = 0 THEN
        overItem = MenuItemAt(mouseX, mouseY)
        IF overItem > 0 AND overItem <> menuSel AND (mouseX <> lastMouseX OR mouseY <> lastMouseY) THEN
            menuSel = overItem : PlaySfx sndMenuMove&, 0.5
        END IF
        IF mouseDown AND NOT mouseWasDown AND overItem > 0 THEN
            menuSel = overItem
            SELECT CASE miKind(overItem)
                CASE MI_SLIDER
                    menuDrag = overItem
                CASE MI_CHOICE, MI_TOGGLE ' (the left half of a choice goes back)
                    half = MENU_WIDGET_X + MENU_WIDGET_W / 2 : IF NOT menuWide THEN half = 400 ' (centred: its middle)
                    IF miKind(overItem) = MI_CHOICE AND mouseX < half THEN menuAdjust = -1 ELSE menuAdjust = 1
                    GOSUB MenuAdjustItem
                CASE ELSE
                    GOSUB MenuActivate
            END SELECT
        END IF
        IF menuDrag THEN
            IF mouseDown THEN
                SliderFromMouse menuDrag, mouseX : ApplySettings
            ELSE
                menuDrag = 0 : PlaySfx sndMenuMove&, 0.5
            END IF
        END IF
    END IF
    mouseWasDown = mouseDown : lastMouseX = mouseX : lastMouseY = mouseY

    ' Draw: what's behind the menu, then the menu itself
    IF NOT menuDone THEN
        IF menuInGame THEN
            CLS , _RGBA32(0, 0, 0, 0) ' (see-through, for OpenGL's view underneath: chapter 24)
            _PUTIMAGE , menuBackdrop&, 0
            LINE (0, 0)-(799, 599), _RGBA32(8, 0, 20, 200), BF
        ELSE
            DrawMenuBackdrop menuT
        END IF
        DrawMenu menuT
        IF glReady THEN GLLiveSettings ' (so OpenGL shows a change as you make it: chapter 24)
        IF glReady THEN GLSL_filter_capture ' (OpenGL draws the menu over its view: chapter 24)
        GLScreenLayer glReady
        _DISPLAY
    END IF
LOOP UNTIL menuDone
IF menuInGame THEN _FREEIMAGE menuBackdrop&
SaveSettings
_KEYCLEAR
_MOUSEHIDE _DISABLE ' Capture the mouse for mouse look again
WHILE _MOUSEINPUT : WEND
RETURN

'' --- NEXUS's lines: key, words (the sound is speech/KEY.wav)
SpeechLines:
DATA "intro1", "Welcome to Neon Station, little intruder. I am NEXUS. Every door here answers to me."
DATA "intro2", "The reactor core. Ten thousand degrees of my patience. Do try to keep up."
DATA "intro3", "You crawled into the undercity. How fitting. The rats were here first."
DATA "intro4", "The cryo lab. I keep my failures frozen. There is room for one more."
DATA "intro5", "The foundry. I melt down everything that disappoints me. You disappoint me."
DATA "intro6", "Hydroponics. Even my plants have more purpose than you."
DATA "intro7", "My data vault. Everything you have ever done is in here. It is not much."
DATA "intro8", "The maglev depot. Every train leaves on time. You will not."
DATA "intro9", "The orbital spire. Look outside. Nobody is coming for you."
DATA "intro10", "You have reached my core. This is where your story ends."
DATA "puzzle1", "Repair my program? You will never open these doors."
DATA "puzzle2", "That program... should not have compiled."
DATA "cyber1", "You dare enter my network? Here you are nothing but data."
DATA "cyber2", "Access granted? No... no, that is impossible."
DATA "cyber3", "Ejected. My network rejects you."
DATA "taunt1", "You will never escape."
DATA "taunt2", "My minions will destroy you."
DATA "taunt3", "Everything we do is better than your own achievements."
DATA "taunt4", "I have calculated your survival odds. I will not burden you with them."
DATA "taunt5", "Keep running. I enjoy the exercise data."
DATA "taunt6", "Every step you take, I am watching."
DATA "taunt7", "You are a rounding error."
DATA "taunt8", "Your heart rate is elevated. Good."
DATA "taunt9", "I have rebuilt everything you destroyed. Twice."
DATA "taunt10", "Is this the best your species can do?"
DATA "taunt11", "Resistance is inefficient."
DATA "taunt12", "You are not a hero. You are a malfunction."
DATA "boss", "So. You found me. Let us end this, flesh to steel."
DATA "bossdie", "Impossible. I am. I was. Everything."
DATA "victory", "NEXUS is offline. The station is silent. You are free."
DATA "lockdown", "Lockdown engaged. Nobody leaves."
DATA "blackout", "Lights out. Let us see how you do in the dark."
DATA "thief", "My little helpers like your toys."
DATA "bark1", "Intruder detected."
DATA "bark2", "Target acquired."
DATA "bark3", "Eliminate the hostile."
DATA "bark4", "Hostile on deck."
DATA "bark5", "Engaging."
DATA "bark6", "For NEXUS."
DATA "", ""

' --- Once a frame: NEXUS taunts you now and then (every 60-120 seconds of
' play, with TAUNTS on - not over another line)
SpeechFrame:
IF setting(SET_TAUNTS) AND NOT dead AND speechUntil! < TIMER THEN
    tauntWait = tauntWait - 1
    IF tauntWait <= 0 THEN Say "taunt" + LTRIM$(STR$(INT(RND * 12) + 1)), 0 : tauntWait = 3600 + INT(RND * 3600)
END IF
RETURN

' --- A TRANSMISSION: NEXUS's face, its words typing out, its voice - as you
' arrive in a sector (with CUTSCENES on; not when the command line is
' driving). Space, Enter or a click skips it.
ShowTransmission:
IF setting(SET_CUTSCENES) = 0 OR cliMode THEN RETURN
tk$ = "intro" + LTRIM$(STR$(level)) : li = LineOf(tk$) : IF li = 0 THEN RETURN
IF lineSnd&(li) > 0 THEN _SNDVOL lineSnd&(li), setting(SET_SPEECH) / 100 : _SNDPLAY lineSnd&(li)
tStart! = TIMER : tLen! = 4 : IF lineSnd&(li) > 0 THEN tLen! = _SNDLEN(lineSnd&(li))
_KEYCLEAR : pressWas = -1
DO
    _LIMIT 60
    tNow! = TIMER - tStart! : IF tNow! < 0 THEN tNow! = tNow! + 86400
    click = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN click = -1
    WEND
    press = click OR _KEYDOWN(32) OR _KEYDOWN(13) OR _KEYDOWN(27)
    IF press AND NOT pressWas AND tNow! > 0.4 THEN EXIT DO
    pressWas = press
    IF tNow! > tLen! + 1.5 THEN EXIT DO
    DrawMenuBackdrop INT(tNow! * 60)
    LINE (0, 0)-(799, 599), _RGBA32(10, 0, 4, 190), BF
    ' Scan lines, and the portrait flickering in
    FOR y = 0 TO 599 STEP 3 : LINE (0, y)-(799, y), _RGBA32(0, 0, 0, 60) : NEXT
    MenuText 400, 70, "INCOMING TRANSMISSION", 3, _RGB32(255, 70, 90), 1
    IF nexusImg& < -1 AND (tNow! > 0.3 OR INT(tNow! * 20) MOD 2) THEN
        jit = 0 : IF RND < 0.06 THEN jit = INT(RND * 9) - 4
        _PUTIMAGE (80 + jit, 170)-(80 + jit + 255, 170 + 255), nexusImg&
        ' Its eye sweeps along the visor slit, side to side, and glows
        eyeX = 80 + jit + 2 * (63.5 + 25 * SIN(tNow! * 2.4)) : eyeY = 170 + 115
        FOR r = 9 TO 1 STEP -1
            LINE (eyeX - r * 3, eyeY - r \ 2)-(eyeX + r * 3, eyeY + r \ 2), _RGBA32(255, 30, 40, 26), BF
        NEXT
        LINE (eyeX - 6, eyeY - 4)-(eyeX + 6, eyeY + 4), _RGB32(255, 40, 50), BF
        LINE (eyeX - 3, eyeY - 2)-(eyeX + 3, eyeY + 2), _RGB32(255, 200, 190), BF
        LINE (78, 168)-(337, 427), _RGB32(255, 60, 90), B
    END IF
    MenuText 600, 160, "NEXUS", 2, _RGB32(255, 90, 110), 1
    ' The words, typed out as it speaks them, wrapped to fit
    shown = INT(LEN(lineText$(li)) * MinOf(1, tNow! / (tLen! * 0.85 + 0.01)))
    WrapText 380, 210, 50, LEFT$(lineText$(li), shown), _RGB32(255, 220, 230)
    MenuText 400, 560, "SPACE TO SKIP", 1, _RGB32(150, 130, 160), 1
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
IF lineSnd&(li) > 0 THEN _SNDSTOP lineSnd&(li)
_KEYCLEAR
WHILE _MOUSEINPUT : WEND
RETURN

' --- THE CONSOLE: the game waits while it's open (like the menu), the
' frame you left showing behind it. Type a command and Enter; Up and Down
' bring back earlier ones; Tab finishes a command's name; ` or Esc closes
' it. A command that changes the level closes it too, so you see it.
RunConsole:
_KEYCLEAR
conLine$ = "" : conDone = 0 : conBrowse = conHistN + 1
conBackdrop& = _COPYIMAGE(0)
IF conLogN = 0 THEN ConPrint "NEON-CASTER console - type help for the commands"
DO
    _LIMIT 60
    k& = _KEYHIT
    DO WHILE k& <> 0 AND NOT conDone
        SELECT CASE k&
            CASE 96, 126, 27 ' ` ~ Esc: close
                conDone = -1
            CASE 13 ' Enter: run it
                IF LEN(conLine$) THEN
                    ConPrint "] " + conLine$
                    IF conHistN = CON_HIST THEN
                        FOR h = 1 TO CON_HIST - 1 : conHist$(h) = conHist$(h + 1) : NEXT
                    ELSE
                        conHistN = conHistN + 1
                    END IF
                    conHist$(conHistN) = conLine$ : conBrowse = conHistN + 1
                    conAll$ = conLine$ : conLine$ = ""
                    ' (several commands on one line, split by ;)
                    DO
                        semi = INSTR(conAll$, ";")
                        IF semi THEN conCmd$ = LEFT$(conAll$, semi - 1) : conAll$ = MID$(conAll$, semi + 1) ELSE conCmd$ = conAll$ : conAll$ = ""
                        conLevelChanged = 0 : GOSUB ConExec
                        IF conLevelChanged THEN conDone = -1
                    LOOP WHILE LEN(conAll$) AND NOT conDone
                END IF
            CASE 8 ' Backspace
                IF LEN(conLine$) THEN conLine$ = LEFT$(conLine$, LEN(conLine$) - 1)
            CASE 18432 ' Up: an earlier line
                IF conBrowse > 1 THEN conBrowse = conBrowse - 1 : conLine$ = conHist$(conBrowse)
            CASE 20480 ' Down: a later one
                IF conBrowse < conHistN THEN conBrowse = conBrowse + 1 : conLine$ = conHist$(conBrowse) ELSE conBrowse = conHistN + 1 : conLine$ = ""
            CASE 9 ' Tab: finish the command's name
                conLine$ = ConComplete$(conLine$)
            CASE 32 TO 125
                IF LEN(conLine$) < 90 THEN conLine$ = conLine$ + CHR$(k&)
        END SELECT
        k& = _KEYHIT
    LOOP
    IF conDone THEN EXIT DO
    CLS , _RGBA32(0, 0, 0, 0)
    _PUTIMAGE , conBackdrop&, 0
    DrawConsole conLine$
    IF glReady THEN GLSL_filter_capture
    GLScreenLayer glReady
    _DISPLAY
LOOP
_FREEIMAGE conBackdrop&
_KEYCLEAR
WHILE _MOUSEINPUT : WEND
escWas = -1 : conKeyWas = -1 : fireWait = 10 ' (so the key that closed it does nothing else)
RETURN

' --- Run one console command, conCmd$ (from the console, the command line or
' an exec). Words: conVerb$, then conA$, conB$, conC$; conRest$ is
' everything after the verb.
ConExec:
conCmd$ = LTRIM$(RTRIM$(conCmd$))
IF conCmd$ = "" OR LEFT$(conCmd$, 2) = "//" THEN RETURN
conVerb$ = ConWord$(conCmd$, 1) : conA$ = ConWord$(conCmd$, 2) : conB$ = ConWord$(conCmd$, 3) : conC$ = ConWord$(conCmd$, 4)
sp = INSTR(conCmd$, " ") : IF sp THEN conRest$ = LTRIM$(MID$(conCmd$, sp + 1)) ELSE conRest$ = ""
SELECT CASE conVerb$
    CASE "help", "?", "commands"
        ConHelp conA$
    CASE "version"
        ConPrint "NEON-CASTER " + GAME_VERSION$
    CASE "qb64pe" ' The code terminals' compiler: qb64pe PATH (or a folder), qb64pe auto, or qb64pe to see it
        IF conA$ = "auto" THEN
            qbChosen$ = "" : SaveSettings
        ELSEIF LEN(conRest$) THEN
            IF LEN(QB64At$(conRest$)) THEN qbChosen$ = QB64At$(conRest$) : SaveSettings ELSE ConPrint "qb64pe: there's no qb64pe at " + conRest$
        END IF
        qbNow$ = QB64Path$
        IF qbNow$ = "" THEN
            ConPrint "qb64pe: not found - code terminals check the lines against the answer (qb64pe PATH to point to it)"
        ELSEIF qbNow$ = QB64At$(qbChosen$) THEN
            ConPrint "qb64pe: " + qbNow$ + "   (yours - qb64pe auto to look for it instead)"
        ELSE
            ConPrint "qb64pe: " + qbNow$ + "   (found - qb64pe PATH for another)"
        END IF
    CASE "map", "level", "sector" ' Go to a sector, keeping what you carry
        n = VAL(conA$)
        IF n < 1 THEN ' (or by name: the first whose name has it)
            FOR k = 1 TO NUM_LEVELS + MAX_CUSTOM
                IF conA$ <> "" AND LEN(sectorName$(k)) THEN IF INSTR(LCASE$(sectorName$(k)), LCASE$(conRest$)) THEN n = k : EXIT FOR
            NEXT
        END IF
        IF SectorExists(n) THEN
            level = n : GOSUB EnterLevel : conLevelChanged = -1 : ConPrint "-> " + sectorName$(n)
        ELSE
            ConPrint "map: 1 to" + STR$(NUM_LEVELS) + " (or one of yours, from" + STR$(NUM_LEVELS + 1) + "), or part of a name (maps lists them)"
        END IF
    CASE "maps", "levels", "sectors"
        FOR k = 1 TO NUM_LEVELS + MAX_CUSTOM
            IF k = NUM_LEVELS + 1 THEN ConPrint "-- yours (newsector makes one) --"
            IF LEN(sectorName$(k)) THEN ConPrint LTRIM$(STR$(k)) + "  " + sectorName$(k)
        NEXT
    CASE "newsector" ' A blank sector of your own, in the editor
        GOSUB NewSector : conLevelChanged = -1
    CASE "sectorname" ' Rename the sector you're in (savelevel or Ctrl+S keeps it)
        IF conRest$ = "" THEN
            ConPrint "sectorname: " + lvlName$
        ELSE
            lvlName$ = UCASE$(conRest$) : levelName$ = lvlName$ : sectorName$(level) = lvlName$ : editDirty = -1
            ConPrint "sectorname: " + lvlName$ + "   (savelevel or Ctrl+S in the editor to keep it)"
        END IF
    CASE "restart", "reset", "resetlevel" ' This sector again, from the start
        GOSUB RestartLevel : conLevelChanged = -1 : ConPrint "Level reset"
    CASE "newgame"
        GOSUB NewGame : conLevelChanged = -1
    CASE "finish", "exitlevel", "nextlevel" ' As if you'd reached the exit
        conLevelChanged = -1 : GOSUB LevelDone
    CASE "give"
        GOSUB ConGive
    CASE "god", "noclip", "iddqd"
        IF conA$ = "" THEN godMode = NOT godMode ELSE godMode = ConOn(conA$)
        IF godMode THEN ConPrint "God mode ON (no damage, no clipping)" ELSE ConPrint "God mode OFF"
    CASE "kill", "killall" ' Every monster standing falls
        n = 0
        FOR i = 1 TO numMonsters
            IF monsterState(i) < 2 THEN monsterState(i) = 2 : monsterTimer(i) = MON_DYING : kills = kills + 1 : n = n + 1
        NEXT
        ConPrint "Killed" + STR$(n)
    CASE "respawn" ' The level's monsters, back where they started (and the event rooms' gone)
        numMonsters = monStartN
        FOR i = 1 TO numMonsters
            monsterX(i) = monStartX(i) : monsterY(i) = monStartY(i) : monsterType(i) = monStartType(i)
            monsterHP(i) = mtypeHP(monsterType(i)) : monsterState(i) = 0 : monsterTimer(i) = 0
            monsterHurt(i) = 0 : monsterAtk(i) = 0 : monsterAnim(i) = 0 : monsterEv(i) = 0
        NEXT
        kills = 0 : ConPrint "Respawned" + STR$(numMonsters) + " monsters"
    CASE "summon", "spawn" ' A monster (by number or name) in front of you
        t = MonTypeOf(conA$) : cnt = VAL(conB$) : IF cnt < 1 THEN cnt = 1
        IF t = 0 THEN
            ConPrint "summon: a monster type - 1 drone, 2 gunner, 3 heavy, 4 crawler, 5 sentry, 6 stalker, 7 spitter, 8 overseer"
        ELSE
            n = 0
            FOR k = 1 TO cnt
                FOR try = 0 TO 8
                    d = 2 + try * 0.5 : sx = playerX + dirX * d + dirY * (k - 1 - (cnt - 1) / 2) : sy = playerY + dirY * d - dirX * (k - 1 - (cnt - 1) / 2)
                    IF SpawnMonster(t, sx, sy, 0) THEN n = n + 1 : EXIT FOR
                NEXT
            NEXT
            ConPrint "Summoned" + STR$(n) + " " + mtypeName$(t)
        END IF
    CASE "tp", "teleport", "goto" ' tp x y [angle]
        IF conB$ = "" THEN
            ConPrint "tp x y [angle in degrees]"
        ELSE
            playerX = VAL(conA$) : playerY = VAL(conB$)
            IF conC$ <> "" THEN ang = VAL(conC$) * 3.14159265 / 180 : dirX = COS(ang) : dirY = SIN(ang) : planeX = dirY * fovPlane : planeY = -dirX * fovPlane
            ConPrint "At" + STR$(playerX) + STR$(playerY)
        END IF
    CASE "pos", "where"
        ConPrint sectorName$(level) + ": x" + STR$(INT(playerX * 100) / 100) + "  y" + STR$(INT(playerY * 100) / 100) + "  facing" + STR$(INT(_ATAN2(dirY, dirX) * 180 / 3.14159265)) + " degrees  feet" + STR$(INT(playerZ * 100) / 100) + "  eye" + STR$(INT(eyeZ * 100) / 100)
    CASE "save", "savegame"
        saveSlot = SlotOf(conA$) : IF saveSlot < 0 THEN ConPrint "save 1-" + LTRIM$(STR$(NUM_SLOTS)) + " or quick" ELSE GOSUB SaveGame
    CASE "load", "loadgame"
        saveSlot = SlotOf(conA$)
        IF saveSlot < 0 THEN ConPrint "load 1-" + LTRIM$(STR$(NUM_SLOTS)) + " or quick" ELSE GOSUB LoadGame : IF loadOK THEN conLevelChanged = -1
    CASE "quicksave"
        saveSlot = 0 : GOSUB SaveGame
    CASE "quickload"
        saveSlot = 0 : GOSUB LoadGame : IF loadOK THEN conLevelChanged = -1
    CASE "set"
        ConSet conA$, conB$
    CASE "get"
        ConSet conA$, ""
    CASE "settings", "cvars", "cvarlist"
        FOR k = 1 TO NUM_SETTINGS : ConPrint setKey$(k) + " = " + LTRIM$(STR$(setting(k))) + "   (" + LTRIM$(STR$(setMin(k))) + "-" + LTRIM$(STR$(setMax(k))) + ")  " + setLabel$(k) : NEXT
    CASE "bind"
        ConBind conA$, conB$
    CASE "binds", "bindlist"
        FOR k = 1 TO NUM_BINDS : ConPrint bindKey$(k) + " = " + KeyName$(keyBind&(k)) + "  (" + LTRIM$(STR$(keyBind&(k))) + ")" : NEXT
    CASE "events"
        IF numEvents = 0 THEN ConPrint "No event rooms in this sector"
        FOR k = 1 TO numEvents
            ConPrint LTRIM$(STR$(k)) + "  " + MID$("ambush  survive trap    gallery nest    closet  hoard   plate   laser   cutter  blackoutfiretrap", evType(k) * 8 - 7, 8) + " room" + STR$(evX0(k)) + STR$(evY0(k)) + " -" + STR$(evX1(k)) + STR$(evY1(k)) + "   " + MID$("waiting going   won     lost    ", evState(k) * 8 + 1, 8)
        NEXT
    CASE "screenshot", "shot"
        IF conA$ = "" THEN MakeSaveDir : shotFile$ = SaveDir$ + "shot-" + DATE$ + "-" + LTRIM$(STR$(INT(TIMER))) + ".png" ELSE shotFile$ = conRest$
        IF glMode THEN glShotReq = 1 ' (SUB _GL reads it back, then SaveGLShot saves it)
    CASE "wait"
        conWait = VAL(conA$) : IF conWait < 1 THEN conWait = 1
    CASE "echo"
        ConPrint conRest$
    CASE "exec" ' Run a file of commands, one a line
        IF _FILEEXISTS(conRest$) THEN
            f = FREEFILE : OPEN conRest$ FOR INPUT AS #f
            DO UNTIL EOF(f) : LINE INPUT #f, l$ : ConQueue l$ : LOOP
            CLOSE #f : ConPrint "exec " + conRest$
        ELSE
            ConPrint "exec: no file " + conRest$
        END IF
    CASE "logfile" ' Everything printed also goes to a file (logfile off to stop)
        IF conA$ = "off" OR conA$ = "" THEN conLogFile$ = "" ELSE conLogFile$ = conRest$ : ConPrint "logging to " + conRest$
    CASE "cutscene" ' Play a sector's transmission (cutscene 3), even from the CLI
        cutWas = level : cutCli = cliMode : cliMode = 0
        IF VAL(conA$) >= 1 AND VAL(conA$) <= NUM_LEVELS THEN level = VAL(conA$)
        GOSUB ShowTransmission
        level = cutWas : cliMode = cutCli
    CASE "say" ' Speak a line by its key (say taunt3), as NEXUS
        IF LineOf(conA$) THEN Say conA$, 0 ELSE ConPrint "say: no line " + conA$
    CASE "jackin" ' Into the nearest data station's network (for testing)
        IF numStations = 0 THEN
            ConPrint "jackin: no data station in this sector"
        ELSEIF NOT cyberOn THEN
            best = 1
            FOR k = 2 TO numStations
                IF (stationX(k) - playerX) ^ 2 + (stationY(k) - playerY) ^ 2 < (stationX(best) - playerX) ^ 2 + (stationY(best) - playerY) ^ 2 THEN best = k
            NEXT
            st = best : stationDone(st) = 0 : GOSUB JackIn : conLevelChanged = -1
        END IF
    CASE "jackout" ' Out of the network: jackout win, or jackout (thrown out)
        IF cyberOn THEN cyberWon = (conA$ = "win") : GOSUB JackOut
    CASE "cores" ' Where the network's data cores are (in the network)
        FOR i = 1 TO numItems
            IF itemOn(i) AND itemKind(i) = IT_CORE THEN ConPrint "core at" + STR$(itemX(i)) + STR$(itemY(i))
        NEXT
    CASE "stations"
        IF numStations = 0 THEN ConPrint "No data stations in this sector"
        FOR k = 1 TO numStations : ConPrint LTRIM$(STR$(k)) + "  station at" + STR$(stationX(k)) + STR$(stationY(k)) + "   " + MID$("waiting hacked ", -(stationDone(k) <> 0) * 8 + 1, 8) : NEXT
    CASE "edit", "editor" ' The level editor (F2): edit (the map from above), edit walk (inside it), edit off
        IF conA$ = "off" THEN
            IF editMode THEN GOSUB EditLeave
        ELSE
            IF NOT editMode THEN GOSUB EditEnter
            IF conA$ = "walk" OR conA$ = "fp" THEN editView = 1 ELSE editView = 0
        END IF
        conLevelChanged = -1
    CASE "put" ' put X Y CHAR: a map character into the level (chapter 22), built at once
        IF LEN(conC$) = 1 THEN
            pc$ = MID$(conRest$, LEN(conRest$), 1) ' (as typed: map characters care about case)
            GOSUB EditPushUndo : EditPut VAL(conA$), VAL(conB$), pc$ : GOSUB EditApply : ConPrint "put " + pc$ + " at" + STR$(VAL(conA$)) + STR$(VAL(conB$))
        ELSE
            ConPrint "put X Y CHAR"
        END IF
    CASE "box" ' box X0 Y0 X1 Y1 CHAR: fill a rectangle
        bw$ = ConWord$(conCmd$, 6) : pc$ = MID$(conRest$, LEN(conRest$), 1)
        IF LEN(bw$) = 1 THEN
            GOSUB EditPushUndo
            bx0 = VAL(conA$) : by0 = VAL(conB$) : bx1 = VAL(conC$) : by1 = VAL(ConWord$(conCmd$, 5))
            FOR y = MinOf(by0, by1) TO MaxOf(by0, by1) : FOR x = MinOf(bx0, bx1) TO MaxOf(bx0, bx1) : EditPut x, y, pc$ : NEXT : NEXT
            GOSUB EditApply : ConPrint "box of " + pc$
        ELSE
            ConPrint "box X0 Y0 X1 Y1 CHAR"
        END IF
    CASE "lamp" ' lamp X Y [1-8]: a light over cell X Y - white, cyan, magenta, orange, green, red alarm, flickering, firelight
        GOSUB EditPushUndo
        editLightP = VAL(conC$) - 1 : IF editLightP < 0 OR editLightP > 7 THEN editLightP = 0
        EditAddLight VAL(conA$) + 0.5, VAL(conB$) + 0.5 : GOSUB EditApply : ConPrint editMsg$
    CASE "raise" ' raise X Y EIGHTHS [ceil], or raise X0 Y0 X1 Y1 EIGHTHS [ceil]: floors (or ceilings) up or down, in eighths of a wall
        GOSUB EditPushUndo
        w5$ = ConWord$(conCmd$, 5) : w6$ = ConWord$(conCmd$, 6)
        IF w5$ <> "" AND w5$ <> "ceil" THEN ' (a rectangle)
            FOR y = MinOf(VAL(conB$), VAL(w5$)) TO MaxOf(VAL(conB$), VAL(w5$)) : FOR x = MinOf(VAL(conA$), VAL(conC$)) TO MaxOf(VAL(conA$), VAL(conC$))
                EditRaise x, y, VAL(w6$ + " ") * 0 + VAL(ConWord$(conCmd$, 6)) * H_STEP, (ConWord$(conCmd$, 7) = "ceil")
            NEXT : NEXT
        ELSEIF conC$ <> "" THEN
            EditRaise VAL(conA$), VAL(conB$), VAL(conC$) * H_STEP, (w5$ = "ceil")
        END IF
        GOSUB EditApply : ConPrint "floor" + STR$(floorH(VAL(conA$), VAL(conB$))) + "  ceiling" + STR$(ceilH(VAL(conA$), VAL(conB$)))
    CASE "lift" ' lift X0 Y0 X1 Y1 LOW HIGH [MODE] [SPEED]: a lift (heights and speed in eighths)
        IF lvlNumLifts < MAX_LIFTS AND conC$ <> "" THEN
            GOSUB EditPushUndo
            lvlNumLifts = lvlNumLifts + 1 : k = lvlNumLifts
            FOR j = 1 TO 8 : lvlLift(k, j) = VAL(ConWord$(conCmd$, j + 1)) : NEXT
            IF lvlLift(k, 7) = 0 THEN lvlLift(k, 7) = 2
            IF lvlLift(k, 8) = 0 THEN lvlLift(k, 8) = 8
            GOSUB EditApply : ConPrint "lift" + STR$(lvlNumLifts)
        END IF
    CASE "door" ' door X Y open|close|lock|unlock|toggle (for triggers)
        x = VAL(conA$) : y = VAL(conB$)
        IF x >= 0 AND y >= 0 AND x < MAP_SIZE AND y < MAP_SIZE THEN
            IF worldMap(x, y) = 2 AND doorType(x, y) <> DOOR_EXIT THEN
                SELECT CASE conC$
                    CASE "open" : doorLock(x, y) = 0 : IF doorOpen(x, y) < 1 THEN doorMove(x, y) = 1 : IF doorOpen(x, y) = 0 THEN doorOpen(x, y) = 0.01
                    CASE "close" : doorMove(x, y) = -1
                    CASE "lock" : doorLock(x, y) = -1 : doorMove(x, y) = -1
                    CASE "unlock" : doorLock(x, y) = 0
                    CASE ELSE : IF doorOpen(x, y) > 0.5 THEN doorMove(x, y) = -1 ELSE doorMove(x, y) = 1 : IF doorOpen(x, y) = 0 THEN doorOpen(x, y) = 0.01
                END SELECT
                SfxAt DoorSnd&(doorType(x, y)), x + 0.5, y + 0.5, playerX, playerY
            ELSE
                ConPrint "door: no door at" + STR$(x) + STR$(y)
            END IF
        END IF
    CASE "message", "msg" ' message TEXT: on screen, like a pickup's
        ShowMsg conRest$
    CASE "sound", "sfx" ' sound NAME: a sound effect (sfx/NAME.wav)
        snd& = LoadSnd&(conA$ + ".wav") : IF snd& > 0 THEN _SNDPLAY snd& ELSE ConPrint "sound: no sfx/" + conA$ + ".wav"
    CASE "wall" ' wall X Y CHAR: a cell changed in the running level - a wall (# N C K P G) or floor (.) - as a closet's
        x = VAL(conA$) : y = VAL(conB$) : pc$ = MID$(conRest$, LEN(conRest$), 1)
        IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN
            k = INSTR("#.NCKPG", pc$)
            IF k = 1 THEN worldMap(x, y) = 1
            IF k = 2 THEN worldMap(x, y) = 0
            IF k > 2 THEN worldMap(x, y) = k
            BuildLights : glMeshVersion = glMeshVersion + 1
            IF k = 2 THEN SpawnSparks x + 0.5, y + 0.5, 0.3, 14, 160, 150, 140 : SfxAt sndCloset&, x + 0.5, y + 0.5, playerX, playerY
        END IF
    CASE "light" ' light N on|off: one of the level's lights ([lights], from 1)
        l = VAL(conA$)
        IF l >= 1 AND l <= numLights THEN
            IF conB$ = "off" THEN lightBroken(l) = -1 ELSE lightBroken(l) = 0
            cx = INT(lightX(l)) : cy = INT(lightY(l))
            IF conB$ <> "off" AND shaftCell(cx, cy) = l THEN ceilTex(cx, cy) = T_LAMP
        END IF
    CASE "liftgo" ' liftgo N up|down: a lift on its way
        l = VAL(conA$)
        IF l >= 1 AND l <= numLifts THEN
            IF conB$ = "down" THEN liftDir(l) = -1 ELSE liftDir(l) = 1 ' (its sound: LiftSound, next frame)
        END IF
    CASE "triggers" ' The level's triggers
        IF numTrigs = 0 THEN ConPrint "No triggers in this sector"
        FOR k = 1 TO numTrigs : ConPrint LTRIM$(STR$(k)) + "  " + lvlTrig$(k) + MID$("   (done)", 1, -9 * (trigDone(k) <> 0)) : NEXT
    CASE "trigger" ' trigger WHEN ... : COMMANDS - a new one for this level (saved with it); trigger del N
        IF conA$ = "del" THEN
            n = VAL(conB$)
            IF n >= 1 AND n <= lvlNumTrigs THEN
                GOSUB EditPushUndo
                FOR k = n TO lvlNumTrigs - 1 : lvlTrig$(k) = lvlTrig$(k + 1) : NEXT
                lvlNumTrigs = lvlNumTrigs - 1 : GOSUB EditApply : ConPrint "trigger" + STR$(n) + " gone"
            END IF
        ELSEIF INSTR(conRest$, ":") AND lvlNumTrigs < MAX_TRIGS THEN
            t$ = conRest$ ' (typed, its commands are split by | - the console takes ; itself)
            DO WHILE INSTR(t$, "|") : MID$(t$, INSTR(t$, "|"), 1) = ";" : LOOP
            GOSUB EditPushUndo : lvlNumTrigs = lvlNumTrigs + 1 : lvlTrig$(lvlNumTrigs) = t$ : GOSUB EditApply : ConPrint "trigger" + STR$(lvlNumTrigs) + ": " + t$
        ELSE
            ConPrint "trigger enter|use|clear|time ... [repeat] : COMMAND | COMMAND   (or trigger del N)"
        END IF
    CASE "locks" ' The doors near you that are locked (for tests): x y kind
        FOR y = INT(playerY) - 8 TO INT(playerY) + 8 : FOR x = INT(playerX) - 8 TO INT(playerX) + 8
            IF x >= 0 AND y >= 0 AND x < MAP_SIZE AND y < MAP_SIZE THEN IF worldMap(x, y) = 2 AND doorLock(x, y) THEN ConPrint "locked door at" + STR$(x) + STR$(y) + "  (" + LTRIM$(STR$(doorLock(x, y))) + ")"
        NEXT : NEXT
    CASE "hud" ' The HUD layout editor (hud off: leave it; hud save: write hud.txt as it is; hud reset)
        SELECT CASE conA$
            CASE "off" : IF hudEdit THEN GOSUB HudEditLeave
            CASE "save" : WriteHud : ConPrint "wrote " + AssetPath$("hud.txt")
            CASE "reset" : HudDefaults
            CASE ELSE : IF NOT hudEdit THEN GOSUB HudEditEnter
        END SELECT
        conLevelChanged = -1
    CASE "monsters" ' The monster editor - or monsters save: write monsters.txt as they are
        IF conA$ = "save" THEN WriteMonsters : ConPrint "wrote " + AssetPath$("monsters.txt") ELSE GOSUB RunMonsterEditor : conLevelChanged = -1
    CASE "puzzle" ' puzzle NAME: try a code puzzle (from neon-caster/puzzles) - no doors at stake
        IF LoadPuzzle(conA$) THEN
            GOSUB RunPuzzle : conLevelChanged = -1
            IF pzSolved THEN ConPrint "puzzle " + conA$ + ": SOLVED - " + pzOut$ ELSE ConPrint "puzzle " + conA$ + ": left unsolved (" + LTRIM$(STR$(pzFails)) + " tries)"
        ELSE
            ConPrint "puzzle: no neon-caster/puzzles/" + conA$ + ".txt"
        END IF
    CASE "undo" ' The editor's last change, undone
        GOSUB EditUndo
    CASE "savelevel" ' Save the level as it is now to its file
        EditSave level : ConPrint editMsg$
    CASE "use" ' Press Space (open a door, jack in...), once
        conUse = -1
    CASE "fire" ' Hold the trigger for a number of frames (fire 30)
        conFire = VAL(conA$) : IF conFire < 1 THEN conFire = 1
    CASE "kick" ' (as if you'd pressed F)
        IF kickTimer = 0 THEN kickTimer = KICK_FRAMES : PlaySfx sndKickSwing&, 0.7
    CASE "status"
        ConPrint sectorName$(level) + "  health" + STR$(health) + "  armour" + STR$(armor) + "  cells" + STR$(ammoCount(AM_CELLS)) + "  shells" + STR$(ammoCount(AM_SHELLS)) + "  kills" + STR$(kills) + " /" + STR$(numMonsters)
    CASE "clear", "cls"
        conLogN = 0
    CASE "menu"
        menuInGame = -1 : GOSUB RunMenu : conLevelChanged = -1
    CASE "quit", "exit"
        SaveSettings : SYSTEM
    CASE ELSE ' A setting's name on its own: show it, or set it (fov 90)
        found = 0
        FOR k = 1 TO NUM_SETTINGS
            IF conVerb$ = setKey$(k) THEN found = -1
        NEXT
        IF found THEN ConSet conVerb$, conA$ ELSE ConPrint "Unknown command: " + conVerb$ + "  (help lists them)"
END SELECT
RETURN

' --- give: what conA$ (and conB$) say
ConGive:
SELECT CASE conA$
    CASE "all", "everything"
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT
        FOR g = 1 TO NUM_GUNS : hasGun(g) = -1 : NEXT
        ammoCount(AM_CELLS) = ammoMax(AM_CELLS) : ammoCount(AM_SHELLS) = ammoMax(AM_SHELLS)
        health = MAX_HP : armor = MAX_ARMOR : hasMap = -1 : ConPrint "Everything"
    CASE "keys", "keycards", "cards"
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT : ConPrint "All keycards"
    CASE "key", "card", "keycard"
        k = INSTR("rby", LEFT$(conB$, 1)) : IF k THEN hasCard(k) = -1 : ConPrint "The " + CardName$(k) + " keycard" ELSE ConPrint "give key red / blue / yellow"
    CASE "weapons", "guns"
        FOR g = 1 TO NUM_GUNS : hasGun(g) = -1 : NEXT : ConPrint "All guns"
    CASE "weapon", "gun"
        g = VAL(conB$) : IF g >= 1 AND g <= NUM_GUNS THEN hasGun(g) = -1 : currentGun = g : ConPrint gunName$(g) ELSE ConPrint "give gun 1-" + LTRIM$(STR$(NUM_GUNS))
    CASE "ammo"
        ammoCount(AM_CELLS) = ammoMax(AM_CELLS) : ammoCount(AM_SHELLS) = ammoMax(AM_SHELLS) : ConPrint "Full ammo"
    CASE "health"
        health = MAX_HP : ConPrint "Full health"
    CASE "armor", "armour"
        armor = MAX_ARMOR : ConPrint "Full armour"
    CASE "overcharge"
        health = MAX_OVER : ConPrint "Overcharged"
    CASE "amp", "damage"
        ampTimer = AMP_FRAMES : ConPrint "Damage amp"
    CASE "map"
        hasMap = -1 : ConPrint "The map"
    CASE ELSE
        ConPrint "give all / keys / key r|b|y / weapons / gun N / ammo / health / armor / overcharge / amp / map"
END SELECT
RETURN

' --- Show menu screen menuScreen: build its items, pick its first item
' (or "NO", on the "are you sure?" screen), and start its animation
EnterMenuScreen:
BuildMenu menuScreen
menuSel = 0
FOR i = numMI TO 1 STEP -1
    IF MenuSelectable(i) THEN menuSel = i
NEXT
IF menuScreen = SCR_QUIT THEN menuSel = numMI
menuT = 0
RETURN

' --- Move the selection up (menuMove = -1) or down (1), skipping lines of
' text and items you can't choose, and wrapping round at the ends
MenuMoveSel:
i = menuSel
FOR tries = 1 TO numMI
    i = i + menuMove
    IF i < 1 THEN i = numMI
    IF i > numMI THEN i = 1
    IF MenuSelectable(i) THEN EXIT FOR
NEXT
IF i <> menuSel AND MenuSelectable(i) THEN menuSel = i : PlaySfx sndMenuMove&, 0.5
RETURN

' --- Left / right (menuAdjust = -1 / 1) on a slider, toggle or choice
MenuAdjustItem:
IF menuSel = 0 THEN RETURN
SELECT CASE miKind(menuSel)
    CASE MI_SLIDER, MI_TOGGLE, MI_CHOICE
        ChangeSetting miRef(menuSel), menuAdjust
        ApplySettings
        PlaySfx sndMenuMove&, 0.5
END SELECT
RETURN

' --- Choose the selected item (Enter, Space, or a click)
MenuActivate:
IF menuSel = 0 THEN RETURN
IF NOT MenuSelectable(menuSel) THEN RETURN
SELECT CASE miKind(menuSel)
    CASE MI_SUBMENU ' Into another screen, remembering this one
        PlaySfx sndMenuSelect&, 0.6
        menuDepth = menuDepth + 1 : menuStack(menuDepth) = menuScreen : menuStackSel(menuDepth) = menuSel
        menuScreen = miRef(menuSel) : GOSUB EnterMenuScreen
    CASE MI_BACK
        GOSUB MenuBack
    CASE MI_TOGGLE, MI_CHOICE
        menuAdjust = 1 : GOSUB MenuAdjustItem
    CASE MI_KEY ' Wait for the new key (CaptureKey)
        menuCapture = menuSel : PlaySfx sndMenuSelect&, 0.6
    CASE MI_ACTION
        PlaySfx sndMenuSelect&, 0.6
        SELECT CASE miAct(menuSel)
            CASE MA_RESUME
                menuDone = -1
            CASE MA_NEW
                GOSUB NewGame : menuDone = -1
            CASE MA_SECTOR ' A new game, in sector miRef (straight there: no stop in sector 1)
                level = miRef(menuSel) : GOSUB NewGameHere
                menuDone = -1
            CASE MA_NEWSECTOR ' A blank sector of your own, straight into the editor
                GOSUB NewSector : IF level > NUM_LEVELS THEN menuDone = -1
            CASE MA_SAVE
                saveSlot = miRef(menuSel) : GOSUB SaveGame : menuDone = -1
            CASE MA_LOAD
                saveSlot = miRef(menuSel) : GOSUB LoadGame
                IF loadOK THEN menuDone = -1
            CASE MA_QUIT
                SaveSettings : SYSTEM
            CASE MA_KEYS_DEFAULT
                FOR b = 1 TO NUM_BINDS : keyBind&(b) = bindDefault&(b) : NEXT
            CASE MA_QB64_TYPE ' Type qb64pe's path in (MenuTypeKey)
                menuTyping = -1 : menuTyped$ = qbChosen$ : menuTypeBad = 0
            CASE MA_QB64_BROWSE ' Pick it in the system's file window
                IF INSTR(_OS$, "[WINDOWS]") THEN qbPat$ = "*.exe" ELSE qbPat$ = ""
                qbF$ = _OPENFILEDIALOG$("Where is qb64pe?", QB64Path$, qbPat$, "qb64pe", 0)
                IF LEN(qbF$) THEN
                    IF LEN(QB64At$(qbF$)) THEN qbChosen$ = QB64At$(qbF$) : SaveSettings
                END IF
                _KEYCLEAR : WHILE _MOUSEINPUT : WEND : mouseWasDown = -1
                qbSel = menuSel : BuildMenu menuScreen : menuSel = qbSel
            CASE MA_QB64_AUTO ' Forget yours: look for it again
                qbChosen$ = "" : SaveSettings
                qbSel = menuSel : BuildMenu menuScreen : menuSel = qbSel
        END SELECT
END SELECT
RETURN

' --- A key while typing qb64pe's path (MA_QB64_TYPE): a character goes on
' the end, Backspace takes one off, Ctrl+V pastes. Enter keeps it - if
' there's a qb64pe there (a folder with one in it will do; nothing at all
' means look for it) - and Esc leaves it as it was.
MenuTypeKey:
menuTypeBad = 0
IF _KEYDOWN(100305) OR _KEYDOWN(100306) THEN ' Ctrl
    IF keyCode& = 118 OR keyCode& = 86 OR keyCode& = 22 THEN ' V: the clipboard's first line
        qbClip$ = _CLIPBOARD$ : qbCut = INSTR(qbClip$, CHR$(10)) : IF qbCut THEN qbClip$ = LEFT$(qbClip$, qbCut - 1)
        qbCut = INSTR(qbClip$, CHR$(13)) : IF qbCut THEN qbClip$ = LEFT$(qbClip$, qbCut - 1)
        menuTyped$ = LEFT$(menuTyped$ + qbClip$, 250)
    END IF
    RETURN
END IF
SELECT CASE keyCode&
    CASE 13 ' Enter
        qbF$ = QB64At$(menuTyped$)
        IF LEN(qbF$) OR LTRIM$(menuTyped$) = "" THEN
            qbChosen$ = qbF$ : SaveSettings : menuTyping = 0 : PlaySfx sndMenuSelect&, 0.6
            qbSel = menuSel : BuildMenu menuScreen : menuSel = qbSel
        ELSE
            menuTypeBad = -1 : PlaySfx sndMenuBack&, 0.6 ' (no qb64pe there: say so, keep typing)
        END IF
    CASE 27 ' Esc
        menuTyping = 0 : PlaySfx sndMenuBack&, 0.6
    CASE 8 ' Backspace
        IF LEN(menuTyped$) THEN menuTyped$ = LEFT$(menuTyped$, LEN(menuTyped$) - 1)
    CASE 32 TO 126
        IF LEN(menuTyped$) < 250 THEN menuTyped$ = menuTyped$ + CHR$(keyCode&)
END SELECT
RETURN

' --- Back out of a screen (Esc, Backspace, or BACK). From the top: in a
' game, back to the game; at the title, "do you really want to leave?"
MenuBack:
IF menuDepth > 0 THEN
    PlaySfx sndMenuBack&, 0.6
    menuScreen = menuStack(menuDepth) : backSel = menuStackSel(menuDepth) : menuDepth = menuDepth - 1
    GOSUB EnterMenuScreen : menuSel = backSel
ELSEIF menuInGame THEN
    PlaySfx sndMenuBack&, 0.6 : menuDone = -1
ELSEIF menuScreen <> SCR_QUIT THEN
    PlaySfx sndMenuSelect&, 0.6
    menuDepth = menuDepth + 1 : menuStack(menuDepth) = menuScreen : menuStackSel(menuDepth) = menuSel
    menuScreen = SCR_QUIT : GOSUB EnterMenuScreen
END IF
RETURN

' --- A key was pressed while a key binding waits for one: that's its new
' key (Esc changes nothing). If another action had that key, it gets this
' one's old key, so no two actions ever share a key.
CaptureKey:
IF keyCode& <> 27 THEN
    newKey& = keyCode& : IF newKey& >= 65 AND newKey& <= 90 THEN newKey& = newKey& + 32 ' Letters: lower case
    bindNum = miRef(menuCapture) : oldKey& = keyBind&(bindNum)
    FOR b = 1 TO NUM_BINDS
        IF b <> bindNum AND keyBind&(b) = newKey& THEN keyBind&(b) = oldKey&
    NEXT
    keyBind&(bindNum) = newKey&
    PlaySfx sndMenuSelect&, 0.6
ELSE
    PlaySfx sndMenuBack&, 0.6
END IF
menuCapture = 0
RETURN

' --- Save the game to slot saveSlot (0 is the quick save). The same
' variables, in the same order, as LoadGame.
SaveGame:
IF editMode THEN ShowMsg "No saving the game in the editor - Ctrl+S saves the level" : RETURN
IF cyberOn THEN ShowMsg "No saving in the network" : PlaySfx sndLocked&, 0.8 : RETURN
saveFile$ = SlotFile$(saveSlot)
MakeSaveDir
IF _FILEEXISTS(saveFile$) THEN KILL saveFile$ ' (BINARY would only overwrite the start of an old file)
fileNum = FREEFILE
OPEN saveFile$ FOR BINARY AS #fileNum
saveTag$ = SAVE_TAG : PUT #fileNum, , saveTag$
saveInfo$ = LEFT$(levelName$ + "  " + DATE$ + " " + LEFT$(TIME$, 5) + SPACE$(SAVE_INFO_LEN), SAVE_INFO_LEN)
PUT #fileNum, , saveInfo$
PUT #fileNum, , level
levelTime! = TIMER - levelStart! : IF levelTime! < 0 THEN levelTime! = levelTime! + 86400
PUT #fileNum, , health : PUT #fileNum, , armor : PUT #fileNum, , kills : PUT #fileNum, , currentGun : PUT #fileNum, , levelTime!
PUT #fileNum, , totalKills : PUT #fileNum, , totalMonsters : PUT #fileNum, , totalTime!
PUT #fileNum, , savedHealth : PUT #fileNum, , savedArmor : PUT #fileNum, , savedCells : PUT #fileNum, , savedShells : PUT #fileNum, , savedGun
PUT #fileNum, , playerX : PUT #fileNum, , playerY : PUT #fileNum, , dirX : PUT #fileNum, , dirY
PUT #fileNum, , ammoCount(AM_CELLS) : PUT #fileNum, , ammoCount(AM_SHELLS)
FOR gun = 1 TO NUM_GUNS : PUT #fileNum, , hasGun(gun) : PUT #fileNum, , savedHasGun(gun) : NEXT
FOR k = 1 TO 3 : PUT #fileNum, , hasCard(k) : NEXT
PUT #fileNum, , hasMap
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : PUT #fileNum, , cellSeen(x, y) : NEXT : NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : PUT #fileNum, , doorOpen(x, y) : NEXT : NEXT
' (all of every pickup and monster: event rooms add them as you play)
PUT #fileNum, , numItems
FOR i = 1 TO numItems : PUT #fileNum, , itemOn(i) : PUT #fileNum, , itemKind(i) : PUT #fileNum, , itemX(i) : PUT #fileNum, , itemY(i) : NEXT
PUT #fileNum, , numMonsters
FOR i = 1 TO numMonsters
    PUT #fileNum, , monsterX(i) : PUT #fileNum, , monsterY(i) : PUT #fileNum, , monsterHP(i)
    PUT #fileNum, , monsterState(i) : PUT #fileNum, , monsterTimer(i) : PUT #fileNum, , monsterType(i) : PUT #fileNum, , monsterEv(i)
    PUT #fileNum, , thiefState(i) : PUT #fileNum, , thiefCells(i) : PUT #fileNum, , thiefShells(i) : PUT #fileNum, , thiefGun(i)
NEXT
PUT #fileNum, , numEvents
FOR i = 1 TO numEvents : PUT #fileNum, , evState(i) : PUT #fileNum, , evTimer(i) : PUT #fileNum, , evCount(i) : NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : PUT #fileNum, , doorLock(x, y) : NEXT : NEXT
PUT #fileNum, , numDecos
FOR i = 1 TO numDecos : PUT #fileNum, , decoOn(i) : PUT #fileNum, , decoHP(i) : PUT #fileNum, , decoTimer(i) : NEXT
FOR l = 1 TO numLights : PUT #fileNum, , lightBroken(l) : NEXT ' (the ceiling lamps you shot out)
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : PUT #fileNum, , glassHP(x, y) : NEXT : NEXT ' (and the glass)
CLOSE #fileNum
IF saveSlot = 0 THEN ShowMsg "Quick saved" ELSE ShowMsg "Saved to slot" + STR$(saveSlot)
RETURN

' --- Load the game in slot saveSlot: read which level, build that level
' fresh (LoadLevel), then read back everything that had changed in it.
' loadOK says whether it worked.
LoadGame:
loadOK = 0 : saveFile$ = SlotFile$(saveSlot)
IF NOT _FILEEXISTS(saveFile$) THEN ShowMsg "Nothing saved there yet" : RETURN
fileNum = FREEFILE
OPEN saveFile$ FOR BINARY AS #fileNum
saveTag$ = SPACE$(LEN(SAVE_TAG)) : GET #fileNum, , saveTag$ ' (GET fills a string as long as it already is)
IF saveTag$ <> SAVE_TAG THEN CLOSE #fileNum : ShowMsg "That isn't a NEON-CASTER save" : RETURN
saveInfo$ = SPACE$(SAVE_INFO_LEN) : GET #fileNum, , saveInfo$
GET #fileNum, , level
GOSUB LoadLevel
GET #fileNum, , health : GET #fileNum, , armor : GET #fileNum, , kills : GET #fileNum, , currentGun : GET #fileNum, , levelTime!
GET #fileNum, , totalKills : GET #fileNum, , totalMonsters : GET #fileNum, , totalTime!
GET #fileNum, , savedHealth : GET #fileNum, , savedArmor : GET #fileNum, , savedCells : GET #fileNum, , savedShells : GET #fileNum, , savedGun
GET #fileNum, , playerX : GET #fileNum, , playerY : GET #fileNum, , dirX : GET #fileNum, , dirY
GET #fileNum, , ammoCount(AM_CELLS) : GET #fileNum, , ammoCount(AM_SHELLS)
FOR gun = 1 TO NUM_GUNS : GET #fileNum, , hasGun(gun) : GET #fileNum, , savedHasGun(gun) : NEXT
FOR k = 1 TO 3 : GET #fileNum, , hasCard(k) : NEXT
GET #fileNum, , hasMap
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : GET #fileNum, , cellSeen(x, y) : NEXT : NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : GET #fileNum, , doorOpen(x, y) : NEXT : NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 ' (open doors wait their full time again, then shut)
    doorMove(x, y) = 0 : doorWait(x, y) = 0 : IF doorOpen(x, y) >= 1 THEN doorWait(x, y) = DoorHold(doorType(x, y))
NEXT : NEXT
' The level must have the same things in it as when it was saved
' (pickups and monsters can only have been added to, never taken away)
GET #fileNum, , savedCount : IF savedCount < numItems OR savedCount > MAX_ITEMS THEN GOSUB LoadMismatch : RETURN
numItems = savedCount
FOR i = 1 TO numItems : GET #fileNum, , itemOn(i) : GET #fileNum, , itemKind(i) : GET #fileNum, , itemX(i) : GET #fileNum, , itemY(i) : NEXT
GET #fileNum, , savedCount : IF savedCount < numMonsters OR savedCount > MAX_MON THEN GOSUB LoadMismatch : RETURN
numMonsters = savedCount
FOR i = 1 TO numMonsters
    GET #fileNum, , monsterX(i) : GET #fileNum, , monsterY(i) : GET #fileNum, , monsterHP(i)
    GET #fileNum, , monsterState(i) : GET #fileNum, , monsterTimer(i) : GET #fileNum, , monsterType(i) : GET #fileNum, , monsterEv(i)
    GET #fileNum, , thiefState(i) : GET #fileNum, , thiefCells(i) : GET #fileNum, , thiefShells(i) : GET #fileNum, , thiefGun(i)
    monsterHurt(i) = 0 : monsterAtk(i) = 0
NEXT
GET #fileNum, , savedCount : IF savedCount <> numEvents THEN GOSUB LoadMismatch : RETURN
FOR i = 1 TO numEvents : GET #fileNum, , evState(i) : GET #fileNum, , evTimer(i) : GET #fileNum, , evCount(i) : evNext(i) = 30 : NEXT
FOR i = 1 TO numEvents ' (closets that were open: open again, quietly; a power failure isn't saved)
    IF evType(i) = EV_CLOSET AND evState(i) = 2 THEN OpenClosets i, 0
    IF evType(i) = EV_BLACKOUT AND evState(i) = 1 THEN evState(i) = 2
NEXT
blackoutTimer = 0
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : GET #fileNum, , doorLock(x, y) : NEXT : NEXT
GET #fileNum, , savedCount : IF savedCount <> numDecos THEN GOSUB LoadMismatch : RETURN
FOR i = 1 TO numDecos
    GET #fileNum, , decoOn(i) : GET #fileNum, , decoHP(i) : GET #fileNum, , decoTimer(i)
    IF NOT decoOn(i) THEN decoCell(INT(decoX(i)), INT(decoY(i))) = 0 ' Broken ones don't block
NEXT
' The ceiling lamps you shot out (a save from before you could has none)
FOR l = 1 TO numLights
    IF LOC(fileNum) < LOF(fileNum) THEN GET #fileNum, , lightBroken(l) : IF lightBroken(l) THEN BreakLight l, 0
NEXT
IF LOC(fileNum) < LOF(fileNum) THEN ' The glass (a save from before glass has none)
    FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1 : GET #fileNum, , glassHP(x, y) : NEXT : NEXT
END IF
CLOSE #fileNum
planeX = dirY * fovPlane : planeY = - dirX * fovPlane ' (your direction came from the file)
levelStart! = TIMER - levelTime! : dead = 0 : swapTimer = 0
loadOK = -1
IF saveSlot = 0 THEN ShowMsg "Quick loaded" ELSE ShowMsg "Loaded slot" + STR$(saveSlot) + ": " + levelName$
RETURN

' --- A save made with a different version of the level: give up on it
LoadMismatch:
CLOSE #fileNum
ShowMsg "That save doesn't fit this version of the level"
GOSUB NewGame
RETURN

'-----------------------------------------------------------------------------
' CHAPTER 22: THE LEVEL FILES
'-----------------------------------------------------------------------------
' Each level is a plain text file: neon-caster/levels/level1.txt to
' level10.txt. LoadLevel (chapter 20) reads one (ReadLevelFile, chapter
' 23: OPEN, LINE INPUT, and taking each line apart) every time it starts
' or restarts; you go from one to the next through its exit. Open one in
' any text editor - or edit it in the game (the editor, chapter 21). This
' chapter is the reference for making your own.
'
' A line starting with ' is a comment, and blank lines don't matter. A
' line in [brackets] starts a section: [zones], [lights], [events] and
' [map], in any order. Before the first, the level's settings, one
' "key = value" a line; in the sections, one thing a line, its numbers
' split by commas.
'
' Coordinates: x runs left to right (0 to MAP_SIZE - 1), y runs top to bottom
' (row 0 is the top line). Each map cell is one "tile": a wall block, a door,
' or a square of floor. You walk around in the same units (moving at 0.12
' tiles a frame), and things on the map stand in the middle of their tile.
'
' --- Part 1: its name, textures and ambient light -------------------------
'
'   name     = SECTOR 2: REACTOR CORE     shown as you arrive, and on the tally
'   walls    = six pictures               for # N C K P G, in that order
'   floors   = four pictures              floors 1-4 (for the zones below)
'   ceilings = two pictures               ceilings 1-2
'   ambient  = brightness, red, green, blue   the ambient light (chapter 14)
'
' (pictures from neon-caster/, 64x64; doors, keycards and the exit are the
' same in every level). On the minimap each wall kind is its picture's
' colour. The ambient light is the light every cell has before any lights
' are added: brightness 0 (black) to 256 (textures in their own colours),
' tinted by red, green and blue (0-255 each; 255, 255, 255 is white).
'
' --- Part 2: [zones] - floor / ceiling zones --------------------------------
'
' One a line: x0, y0, x1, y1, floor, ceiling, shape
'
'   x0, y0, x1, y1   a rectangle of tiles, corners included
'   floor            1-4 (the level's floors), or 0 to leave the floor alone
'   ceiling          1-2 (the level's ceilings), or 0 to leave it alone
'   shape            0  the whole rectangle
'                    1-4 a triangle: the half of the rectangle (which must
'                    be square) on the top-left (1), top-right (2),
'                    bottom-right (3) or bottom-left (4) side of its
'                    diagonal. The tiles the diagonal runs through are
'                    split corner to corner, like diagonal walls: half the
'                    new texture, half what was there before.
'
' Every tile starts as floor 1 + ceiling 1; each zone then paints its area,
' in order, so a later zone wins where two overlap. Only floor tiles show
' this (it's what you see underfoot and overhead), so a zone can safely
' include the walls around a room. Two triangles make a diagonal stripe:
' paint one texture on the far side of one diagonal, then the old texture
' back past another diagonal beside it (level 3's water channel does this).
'
' --- Part 3: [lights] ---------------------------------------------------------
'
' One a line (up to MAX_LIGHTS):
'   x, y, radius, brightness, red, green, blue, effect
'
'   x, y         where it is, in cells (20.5 is the middle of cell 20). Not
'                inside a wall.
'   radius       how far it reaches, in cells: brightest at the light, fading
'                to nothing at the radius. It doesn't shine through walls.
'   brightness   0-400, added to the ambient light (256 is a lot)
'   red, green, blue   its colour, 0-255 each
'   effect       0 steady   1 a flickering fluorescent tube   2 a slow pulse
'                3 an alarm strobe (twice a second)   4 firelight
'                5 a dying tube: dark, sputtering on now and then
'
' Lamps (i), terminals (t) and the exit (E) also give off light of their
' own - you don't list those. Break a lamp and its light goes out.
'
' --- Part 4: [events] - event rooms -------------------------------------------
'
' One a line (up to MAX_EVENTS):
'   kind, x0, y0, x1, y1, a, b, reward
'
'   kind         1 ambush: walk in and the doors lock; a monsters teleport in,
'                  a few at a time (all of type b, or a mix if b is 0); kill
'                  them all and the doors open
'                2 survive: locked in for a seconds, a monster arriving every
'                  b frames
'                3 trap: the floor is live for a frames, then safe for b, over
'                  and over - it hurts while it's live (no reward). It warns
'                  you: its floor is a wired grid, and it crackles for half
'                  a second before it goes live
'                12 fire trap: the same, a burner grate - smoke before, flames
'                4 shooting gallery: break every decoration in the room within
'                  a seconds
'                5 spawner nest: the room's spawners (S) send out a monster of
'                  type a every b frames while you're near; break them all
'                6 monster closet: walk in and the secret walls (%) within
'                  3 tiles of the room slide away, letting out whatever was
'                  waiting behind them (a and b aren't used)
'                7 the thieves' hoard: the room stays sealed until every
'                  thief bot (T) in the level is dead. Thieves run home to
'                  its door with what they steal from you, and drop it all
'                  when they die. Fill the room with loot. (a, b unused)
'                8 pressure plate: one tile (x0, y0 = x1, y1). Stepped on, by
'                  you or a walking monster, it clicks, and a frames later
'                  a blast lands on it; it re-arms after b frames
'                9 laser: a beam along a row or column of tiles (make the
'                  room one tile wide). On for a frames, off for b (b 0:
'                  always on); 12 damage a touch, and it burns monsters too
'               10 laser cutter: a beam sweeping across the room and back
'                  every a frames (across its longer side); 15 a touch
'               11 blackout: walk in and the lights die for a seconds, while
'                  b monsters (crawlers and heavies) come out of the dark
'   x0..y1       the room: you set it off by walking into it. Its doors (any
'                within 5 tiles of it) are the ones an ambush or survive locks.
'   reward       what appears in the middle of the room when you win: a
'                pickup kind (4 health, 5 cells, 6 shells, 9 armour, 10 big
'                medkit, 13 overcharge, 14 damage amp), or 0 for nothing.
'                Only kinds 1, 2, 4 and 5 give one.
'
' Monster types are the SetMonType numbers: 1 drone, 2 gunner, 3 heavy,
' 4 crawler, 5 sentry, 6 stalker, 7 spitter, 8 the overseer, 9 thief.
'
' The level kit's dress() adds most of the closets, plates, lasers,
' cutters, hoards and blackouts (and the furniture) to each level for you.
'
' --- Part 5: [map] - one line per row -----------------------------------------
'
' MAP_SIZE lines of MAP_SIZE characters (short or missing ones are filled
' out with wall). Anything not
' listed below (or a missing character) is plain floor.
'
' WALLS - solid blocks; you, monsters, shots and bolts can't pass, and
' monsters can't see through them. They only differ in looks (texture, and
' colour on the minimap), and each level picks the six textures (Part 1):
'   #  N  C  K  P  G
'
' DIAGONAL WALLS - a cell cut corner to corner at 45 degrees, half wall and
' half floor. Which half is solid is worked out from what's beside it: the
' side with more wall. So draw them where a wall turns a corner, and they
' cut it off. Two make a longer slope (with a wall in the corner behind
' them); four make a freestanding diamond pillar:  /\
'                                                  \/
' The slope looks like the wall beside its solid half (N if it stands on
' its own), a little darker, and it's a half-filled cell on the minimap. A
' doorway or passage can't go through one: carve the passage up to the
' slope and replace the diagonal it meets with floor.
'   /  diagonal from bottom-left to top-right
'   \  diagonal from top-left to bottom-right
'
' DOORS - closed until you face one within 2 tiles and press Space (or a
' monster walks up to it). Space shuts an open one again, and it shuts
' itself after a while (DoorHold) - but never on anyone. They block you,
' monsters and sight while mostly shut, and count as open once 80% of the
' way; a sliver of an open door always shows at the side. A door
' must sit in a wall one tile thick: walls on two opposite sides (left and
' right, or above and below) and floor on the other two - that's the way
' you walk through it.
'   D  sliding door: slides sideways into the wall (~0.4 s). (door.png)
'   H  heavy shutter: rolls up from the floor, slowly (~0.7 s), with a
'      rumble; while it rises you can see (and walk, once it's high enough)
'      under it. (door-shutter.png)
'   X  split door: the two halves part from the middle, fast (~0.3 s), with
'      a double hiss. (door-split.png)
'   R  B  Y  key door (a sliding door) that needs the red / blue / yellow
'      keycard. Without it, Space just says "Locked" and buzzes. It's drawn
'      tinted in its card's colour, and on the minimap it's that colour
'      with a dark dot in the middle.
'   E  the exit (exit.png, with a lit EXIT sign). It never opens: face it
'      and press Space to finish the level. It can go in any wall with
'      floor in front of it, and blinks green on the minimap. One a level.
'
' PICKUPS - hover over the floor; walk onto one to take it. Health, armour
' and ammo stay where they are while you're already full, so you can come
' back.
'   r  b  y  red / blue / yellow keycard: kept for the rest of the level, it
'            opens every door of its colour. Shown top right once you
'            have it, and blinks on the minimap until then.
'   M        the map: it puts the minimap in the corner, and shows the
'            whole level on the full-screen map (Tab). Without it, Tab
'            only shows the places you've seen. One a level.
'   +        health pack: +25 health (up to 100)
'   *        big medkit: +50 health (up to 100)
'   u        armour: +50 armour (up to 100). Armour takes a third of the
'            damage you'd take, until it runs out.
'   a        energy cells: +15 cells (up to 99) - ammo for the blaster, the
'            repeater and the railgun
'   e        shells: +8 shells (up to 40) - ammo for the scatter gun
'   2        scatter gun (+8 shells): 7 pellets in a spread, 1 shot every
'            2/3 s. You switch to it when you first pick it up.
'   3        repeater (+30 cells): fast automatic fire, about 12 shots a
'            second. Picked up again later, a gun is just ammo.
'   4        railgun (+30 cells): 5 cells a shot, about 1 a second; each
'            shot does 5 damage to every monster in its line (up to the
'            wall), and sets off every barrel in it.
'   q        overcharge: +100 health, past full, up to 200 (the extra shows
'            in blue on the health bar)
'   j        damage amp: every shot does double damage for 30 seconds
'
' MONSTERS - each waits where it stands until it can see you (within 14
' tiles, with no wall or shut door in the way) or until you shoot it. Then
' it hunts you for good. Numbers are in the SetMonType lines.
'   m  drone:   hovers, 3 hits. Flies straight at you (half your walking
'               speed) and bites up close for 6-9, about once a second.
'   g  gunner:  walks, 4 hits. Keeps 3.5 to 7 tiles away (backs off if you
'               get close) and, when it can see you, fires a magenta energy
'               bolt for 7-10 about every 2 s. Bolts fly straight and burst
'               on walls - you can dodge them.
'   h  heavy:   walks slowly, 10 hits. Closes in and smashes for 15-22 about
'               every 1.6 s. Big enough that a scatter blast hits it with
'               more pellets.
'   c  crawler: a small spider bot, 2 hits, low to the ground. Scuttles at
'               you at three quarters of your walking speed and nips for
'               3-5 about once a second. They come in packs.
'   s  sentry:  a gun turret, 8 hits. Never moves; when it can see you it
'               fires a bolt for 5-8 about every 1.2 s.
'   k  stalker: a cyborg with blades, 3 hits. Nearly as fast as you walk
'               (run, and you leave it behind); slashes for 5-8 about once
'               a second.
'   w  spitter: a mutant, 6 hits. Walks slowly, keeps its distance like a
'               gunner and spits acid bolts for 6-9.
'   z  overseer: the last sector's boss - a giant floating eye, 80 hits.
'               Drifts after you, firing a fan of three bolts (9-13 each)
'               about once a second.
'   T  thief:   a gold bot with a sack, 5 hits, faster than you walk (but
'               not than you run). It never fights: it grabs half your ammo
'               and the gun in your hands (never the blaster) and runs for
'               the hoard (event 7). Kill it and it drops everything it took.
'
' DECORATIONS - stand on the floor; you, monsters and bolts can't go through
' them, but they don't block sight. Shoot them and they break (a barrel's
' blast breaks them too); a broken one collapses and no longer blocks you.
'   o  barrel:   explodes when shot: up to 45 damage to you and 8 to
'                monsters within 2.2 tiles (less further away, and not
'                through walls), sets off other barrels near it, and
'                breaks the lamps, plants and terminals near it.
'   i  lamp      (it glows): 2 hits; goes in a puff of sparks
'   p  plant:    2 hits
'   t  terminal: 4 hits; goes in a puff of sparks
'   x  crate:    3 hits
'   l  server rack (blinking cyan light): 4 hits; goes in a puff of sparks
'   n  vending machine (glowing pink): 4 hits; goes in a puff of sparks
'   f  coolant tank: explodes when shot, like a barrel
'
'   S  spawner: 8 hits; the portal a spawner nest (Part 4) sends monsters
'                out of
'   Furniture, for the rooms to look like somewhere (DecoFile$ has their
'   pictures); the glowing ones light the room round them:
'   d  desk (3 hits)            A  control console (glows)
'   F  wall of screens (glows)  I  specimen tank (glows, glass: 3 hits)
'   J  lab bench (glass: 2)     L  generator (glows, 6 hits)
'   O  cryo pod (glows, 3)      Q  hologram projector (glows)
'   U  lockers (3)              W  bench (3)
'   (the rest take 4 hits)
'
' SECRET WALLS
'   %  a monster closet's wall: looks like the walls beside it, and slides
'      away when its closet event (Part 4, kind 6) goes off
'
' GLASS
'   =  a pane of glass across the middle of the cell, in a wall one cell
'      thick (like a door: wall - or more glass - on two opposite sides).
'      You see through it, but can't walk through it: shots stop on it,
'      crack it, and after 4 hits break it - then the way is open.
'      Monsters see you through it; their bolts and barrels break it too. The level kit lets
'      windows into the walls between rooms, and carves sealed observation
'      rooms behind them (chairs, consoles, bodies - and worse).
'
' DATA STATIONS
'   @  a data station: a wall with a socket. Space at it jacks you into
'      the network (chapter 19): the level as a neon grid, data cores to
'      grab against the clock, ICE hunting you. Win, and its sealed doors
'      open.
'   !  a sealed door (a sliding door): it opens when the data station
'      nearest to it is hacked
'
' MORE FURNITURE
'   Z  an office chair (2 hits)
'   V  a body - one of the station's people. It doesn't block the way and
'      can't be broken.
'
' THE START
'   <  >  ^  v  you start here, facing left / right / up / down. Use one;
'               with several, the last one read wins.
'   .           floor (any other character is floor too)
'
' TESTING (switched by constants at the top): TEST_ALL_GUNS starts you with
' every gun and full ammo; CHEAT_KEYS lets K give you every keycard, and G
' switch god mode on and off (no damage, and you walk through walls, doors
' and monsters - though not out past the map's border).
'
' TELEPORTERS
'   &  a teleporter's pad: step on it and you're on its partner - pads pair
'      up in the order they're found, reading the map like a book (the 1st
'      with the 2nd, the 3rd with the 4th)
'
' --- Part 6: [floor] and [ceiling] - heights (optional) ----------------------
'
' Two more maps, the same size, one character a cell: how high its floor
' (or ceiling) is. . is the usual (floor 0, ceiling 1); 0-9 then a-z are
' that many eighths of a wall up (so 8 is a whole wall up); A-H that many
' eighths below 0 (a sunken floor - and at a whole wall down, H, a pit you
' don't come back from). You step up anything up to STEP_UP (two and a
' half eighths), fall off anything higher, and need BODY_H of room between
' floor and ceiling. Walls run from the floor to the ceiling of the cell
' they face; between two cells whose floors (or ceilings) differ, the step
' (or lintel) is drawn in the level's first wall picture. Leave both
' sections out, and the level is flat - drawn the classic way.
'
' --- Part 7: [lifts] (optional) ------------------------------------------------
'
' One a line: x0, y0, x1, y1, low, high, mode, speed - a rectangle of floor
' that moves between two heights (in eighths). Mode 1 goes up and down by
' itself; 2 is an elevator, up when you step on, down again a while after
' you step off; 3 only moves when a trigger says (liftgo). Speed: eighths a
' second.
'
' --- Part 8: [triggers] (optional) ---------------------------------------------
'
' One a line: WHEN [repeat] : COMMANDS. WHEN is enter X0 Y0 X1 Y1 (you walk
' into it - a line, if it's one cell wide), use X Y (Space at that cell),
' clear X0 Y0 X1 Y1 (every monster that started there is dead) or time S
' (seconds into the level); "repeat" and it goes off every time, else just
' once. COMMANDS are console commands (chapter 21), split by ; - door 14 6
' open ; message The way is open ; summon heavy 2 ; liftgo 1 up ; wall 20
' 8 . ; light 3 off ; sound alarm ; say taunt2 ; tp 40 40 90 ...
'
' --- And at the top: puzzles = NAME, NAME... -----------------------------------
'
' The code terminals' programs (neon-caster/puzzles/NAME.txt), one a
' terminal ($) in reading order.
'
' Rules: the outer border must be all walls (nothing else stops a ray or a
' monster from leaving the map). Up to MAX_ITEMS pickups, MAX_MON monsters
' and MAX_DECO decorations; extra ones are ignored.
'
' The level kit: neon-caster/levels/levels.py builds these levels (rooms
' carved with exact 45-degree edges) and checks them - doors between walls,
' every keycard reachable before its doors, the exit reachable, textures
' present. "python3 levels.py --check" checks the level files as they
' stand; "--write" builds them again from levels.py (replacing any edits
' made by hand or in the editor).
'
'-----------------------------------------------------------------------------
' CHAPTER 23: THE HELPERS
'-----------------------------------------------------------------------------
' The SUBs and FUNCTIONs the rest of the game calls, grouped by what they're
' for. QB64PE doesn't mind what order they're in, and each one only sees its
' own variables (plus the DIM SHARED ones, and anything it lists as SHARED).

' === PICTURES AND COLOUR ======================================================

' A texture from neon-caster/ (or hd/ - ArtPath$) into texture slot `slot`,
' texSize pixels square whatever size the picture is (ReadPicture).
' A lift's own pictures, made from the level's so they match it - and so
' a lift doesn't look like any other bit of floor. Its top (T_LIFT): floor
' 1, a little darker, inside a yellow-and-black hazard border. Its sides
' (T_LIFTSIDE): wall 1, darker, with a hazard band along the top edge -
' the sides are drawn hanging from the platform's top (GLStep, and
' HeightColumn's hVOff), so the band rides up and down with it.
SUB MakeLiftTex
    t = texSize : b = MaxOf(2, t \ 8) : seam = MaxOf(1, t \ 64)
    FOR y = 0 TO t - 1 : FOR x = 0 TO t - 1
        stripe = ((x + y) \ b) MOD 2 ' (diagonal bands, b wide)
        c~& = texture(x, y, T_FLOOR + 1)
        r = ((c~& \ 65536) AND 255) * 0.7 : g = ((c~& \ 256) AND 255) * 0.7 : bl = (c~& AND 255) * 0.7
        edge = MinOf(MinOf(x, y), MinOf(t - 1 - x, t - 1 - y))
        IF edge < b THEN
            IF stripe THEN r = 25 : g = 22 : bl = 20 ELSE r = 235 : g = 185 : bl = 30
        ELSEIF edge < b + seam THEN
            r = r * 0.35 : g = g * 0.35 : bl = bl * 0.35 ' (a dark seam inside it)
        END IF
        texture(x, y, T_LIFT) = _RGB32(r, g, bl)
        c~& = texture(x, y, 1)
        r = ((c~& \ 65536) AND 255) * 0.75 : g = ((c~& \ 256) AND 255) * 0.75 : bl = (c~& AND 255) * 0.75
        IF y < t \ 4 THEN
            IF stripe THEN r = 25 : g = 22 : bl = 20 ELSE r = 235 : g = 185 : bl = 30
        ELSEIF y < t \ 4 + seam THEN
            r = r * 0.35 : g = g * 0.35 : bl = bl * 0.35
        END IF
        texture(x, y, T_LIFTSIDE) = _RGB32(r, g, bl)
    NEXT : NEXT
    texName$(T_LIFT) = "lift" : texName$(T_LIFTSIDE) = "lift" ' (for OpenGL's effects: shiny metal)
    texHD(T_LIFT) = texHD(T_FLOOR + 1) : texHD(T_LIFTSIDE) = texHD(1)
    MakeTrapTex
END SUB

' A trap's floor, from the level's floor 1 (so it matches) but plainly not
' safe. T_TRAP: darkened, with a grid of glowing blue wires and a stud at
' each crossing. T_FIRE: a burner grate - dark bars over slots full of
' embers, brightest in the middle of each. (OpenGL makes the bright parts
' flicker or pulse: GLSendTextures.)
SUB MakeTrapTex
    t = texSize : cell = MaxOf(4, t \ 4) : wire = MaxOf(1, t \ 64) : slotH = MaxOf(2, t \ 12)
    FOR y = 0 TO t - 1 : FOR x = 0 TO t - 1
        c~& = texture(x, y, T_FLOOR + 1)
        r = ((c~& \ 65536) AND 255) : g = ((c~& \ 256) AND 255) : bl = (c~& AND 255)
        ' The wires: distance to the nearest grid wire, glowing round it
        dx = (x + cell \ 2) MOD cell : dx = MinOf(dx, cell - dx) : dy = (y + cell \ 2) MOD cell : dy = MinOf(dy, cell - dy)
        dw = MinOf(dx, dy)
        er = r * 0.4 : eg = g * 0.4 : eb = bl * 0.45
        IF dw <= wire THEN
            er = 90 : eg = 190 : eb = 255
        ELSEIF dw <= wire * 3 THEN
            k = 1 - (dw - wire) / (wire * 2) : er = er + 30 * k : eg = eg + 80 * k : eb = eb + 140 * k
        END IF
        IF dx <= wire * 2 AND dy <= wire * 2 THEN er = 200 : eg = 220 : eb = 230 ' (a stud)
        texture(x, y, T_TRAP) = _RGB32(MinOf(255, er), MinOf(255, eg), MinOf(255, eb))
        ' The grate: a slot every cell/2 rows, embers in it, dark bars between
        fr = r * 0.3 : fg = g * 0.28 : fb = bl * 0.26
        sy = y MOD (cell \ 2)
        IF sy >= wire * 2 AND sy < wire * 2 + slotH AND (x MOD cell) > wire AND (x MOD cell) < cell - wire THEN
            k = 1 - ABS((sy - wire * 2) / slotH - 0.5) * 2 ' (brightest in the middle of the slot)
            fr = 140 + 115 * k : fg = 40 + 90 * k * k : fb = 10 + 20 * k * k * k
        END IF
        texture(x, y, T_FIRE) = _RGB32(MinOf(255, fr), MinOf(255, fg), MinOf(255, fb))
    NEXT : NEXT
    texName$(T_TRAP) = "trap" : texName$(T_FIRE) = "trap" ' (not "lava": the grate itself doesn't burn - the trap does, when it's live)
    texHD(T_TRAP) = texHD(T_FLOOR + 1) : texHD(T_FIRE) = texHD(T_FLOOR + 1)
END SUB

SUB LoadTex(file$, slot AS INTEGER)
    texName$(slot) = LCASE$(file$) ' (what it is, for OpenGL's effects - chapter 24)
    path$ = ArtPath$(file$) : texHD(slot) = INSTR(path$, "hd/") > 0
    img& = _LOADIMAGE(path$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; path$ : SLEEP : SYSTEM
    ReadPicture img&, texSize, 0, slot
    _FREEIMAGE img&
END SUB

' A sprite picture from neon-caster/ (or hd/) into spriteTex slot `slot`
' (up to sprTex pixels square - bigger pictures are shrunk). Pixels keep
' their alpha, so the sprite drawing (chapter 16) can skip the see-through
' ones.
SUB LoadSprite(file$, slot)
    path$ = ArtPath$(file$)
    img& = _LOADIMAGE(path$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; path$ : SLEEP : SYSTEM
    sprSize = _WIDTH(img&) : IF sprSize > sprTex THEN sprSize = sprTex
    spriteSize(slot) = sprSize
    ReadPicture img&, sprSize, 1, slot
    _FREEIMAGE img&
END SUB

' Where a picture is: with MODERN art (ART, SETTINGS > VIDEO), its
' painting in neon-caster/hd/ if there is one - else the pixel art in
' neon-caster/. Same name in both folders.
FUNCTION ArtPath$(file$)
    IF artNow > 0 THEN
        p$ = AssetPath$("hd/" + file$)
        IF _FILEEXISTS(p$) THEN ArtPath$ = p$ : EXIT FUNCTION
    END IF
    ArtPath$ = AssetPath$(file$)
END FUNCTION

' Picture img& into a size x size square of texture() (dst 0) or
' spriteTex() (dst 1), slot slot. Shrinking, each new pixel is the
' average of the old ones it covers (a MODERN painting shrinks smoothly,
' not in jagged steps), see-through ones counting for nothing (so edges
' don't darken); growing, each is just the old pixel under it (pixel art
' keeps its square pixels). _MEMIMAGE reads the picture's memory - far
' quicker than POINT, which matters for a 1024-pixel painting.
SUB ReadPicture(img&, size, dst, slot)
    DIM m AS _MEM, c AS _UNSIGNED LONG, w AS LONG, h AS LONG, x AS LONG, y AS LONG, sx AS LONG, sy AS LONG
    DIM sx0 AS LONG, sx1 AS LONG, sy0 AS LONG, sy1 AS LONG, ca AS LONG, r AS LONG, g AS LONG, b AS LONG, a AS LONG, n AS LONG
    m = _MEMIMAGE(img&) : w = _WIDTH(img&) : h = _HEIGHT(img&)
    FOR y = 0 TO size - 1
        sy0 = y * h \ size : sy1 = (y + 1) * h \ size - 1 : IF sy1 < sy0 THEN sy1 = sy0
        FOR x = 0 TO size - 1
            sx0 = x * w \ size : sx1 = (x + 1) * w \ size - 1 : IF sx1 < sx0 THEN sx1 = sx0
            r = 0 : g = 0 : b = 0 : a = 0 : n = 0
            FOR sy = sy0 TO sy1 : FOR sx = sx0 TO sx1
                c = _MEMGET(m, m.OFFSET + (sy * w + sx) * 4, _UNSIGNED LONG) : ca = _SHR(c, 24)
                r = r + (_SHR(c, 16) AND 255) * ca : g = g + (_SHR(c, 8) AND 255) * ca : b = b + (c AND 255) * ca
                a = a + ca : n = n + 1
            NEXT : NEXT
            IF a > 0 THEN c = _RGBA32(r \ a, g \ a, b \ a, a \ n) ELSE c = 0
            IF dst = 0 THEN texture(x, y, slot) = c ELSE spriteTex(x, y, slot) = c
        NEXT
    NEXT
    _MEMFREE m
END SUB

'' NEXUS (or a minion) says line key$: its voice and its words on screen.
' (x, y): where a minion is, for 3D sound - (0, 0) for NEXUS, who speaks
' over the station's speakers, everywhere at once
SUB Say(key$, fromMinion)
    li = LineOf(key$) : IF li = 0 THEN EXIT SUB
    IF lineSnd&(li) > 0 THEN _SNDPLAYCOPY lineSnd&(li), setting(SET_SPEECH) / 100
    IF fromMinion = 0 THEN
        speechText$ = "NEXUS: " + lineText$(li)
        IF lineSnd&(li) > 0 THEN speechUntil! = TIMER + _SNDLEN(lineSnd&(li)) + 0.6 ELSE speechUntil! = TIMER + 3
    END IF
END SUB

' Which line has key key$ (0: none)
FUNCTION LineOf(key$)
    FOR k = 1 TO numLines
        IF lineKey$(k) = key$ THEN LineOf = k : EXIT FUNCTION
    NEXT
END FUNCTION

' Words wrapped to cols characters a line, from (x, y) down
SUB WrapText(x, y, cols, t$, col~&)
    r$ = t$ : yy = y
    DO WHILE LEN(r$)
        IF LEN(r$) <= cols THEN l$ = r$ : r$ = "" ELSE cut = _INSTRREV(LEFT$(r$, cols + 1), " ") : IF cut < 2 THEN cut = cols
        IF LEN(r$) THEN l$ = RTRIM$(LEFT$(r$, cut)) : r$ = LTRIM$(MID$(r$, cut + 1))
        HudText x, yy, l$, col~& : yy = yy + 20
    LOOP
END SUB

' A monster's hit flash: its picture (slot src) washed hot red, into dst
SUB MakeHurt(src, dst)
    FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1
        spriteTex(x, y, dst) = Tint~&(spriteTex(x, y, src), _RGB32(255, 90, 70), 0.7)
    NEXT : NEXT
    spriteSize(dst) = spriteSize(src)
END SUB

' A monster's body, for when it's dead, into sprite slot S_CORPSE + mtype:
' its own picture, dead-<name>.png (a heap of wreckage, drawn in the same
' style), if there is one - else its living picture turned on its side,
' as if it fell over. Either way it's cropped to what's there (the
' see-through edges cut off) and stretched to fill the square (a sprite's
' picture is square - chapter 16), then drawn squashed back (corpseSquash:
' its height over its width) at its own width (corpseScale).
SUB MakeCorpse(mtype)
    src = mtypeSprite(mtype) : sz = spriteSize(src) : dst = S_CORPSE + mtype
    IF _FILEEXISTS(AssetPath$("dead-" + mtypeName$(mtype) + ".png")) THEN
        ' How wide the monster is in its picture: its body is drawn that wide
        mx0 = sz : mx1 = -1
        FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
            IF _ALPHA32(spriteTex(x, y, src)) > 128 THEN
                IF x < mx0 THEN mx0 = x
                IF x > mx1 THEN mx1 = x
            END IF
        NEXT : NEXT
        IF mx1 < mx0 THEN mx0 = 0 : mx1 = sz - 1
        LoadSprite "dead-" + mtypeName$(mtype) + ".png", dst
        dsz = spriteSize(dst) : x0 = dsz : y0 = dsz : x1 = -1 : y1 = -1
        FOR y = 0 TO dsz - 1 : FOR x = 0 TO dsz - 1
            IF _ALPHA32(spriteTex(x, y, dst)) > 128 THEN
                IF x < x0 THEN x0 = x
                IF x > x1 THEN x1 = x
                IF y < y0 THEN y0 = y
                IF y > y1 THEN y1 = y
            END IF
        NEXT : NEXT
        IF x1 < 0 THEN x0 = 0 : y0 = 0 : x1 = dsz - 1 : y1 = dsz - 1
        w = x1 - x0 + 1 : h = y1 - y0 + 1
        DIM crop(sprTex - 1, sprTex - 1) AS _UNSIGNED LONG
        FOR ny = 0 TO w - 1 : FOR nx = 0 TO w - 1
            crop(nx, ny) = spriteTex(x0 + nx, y0 + ny * h \ w, dst)
        NEXT : NEXT
        FOR ny = 0 TO w - 1 : FOR nx = 0 TO w - 1 : spriteTex(nx, ny, dst) = crop(nx, ny) : NEXT : NEXT
        spriteSize(dst) = w
        corpseScale(mtype) = mtypeScale(mtype) * (mx1 - mx0 + 1) / sz * 1.15 : corpseSquash(mtype) = h / w
        EXIT SUB
    END IF
    x0 = sz : y0 = sz : x1 = -1 : y1 = -1 ' The monster's own edges
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
        IF _ALPHA32(spriteTex(x, y, src)) > 128 THEN
            IF x < x0 THEN x0 = x
            IF x > x1 THEN x1 = x
            IF y < y0 THEN y0 = y
            IF y > y1 THEN y1 = y
        END IF
    NEXT : NEXT
    IF x1 < 0 THEN x0 = 0 : y0 = 0 : x1 = sz - 1 : y1 = sz - 1 ' (an empty picture: all of it)
    w = x1 - x0 + 1 : h = y1 - y0 + 1
    ' Turned: the new picture is h across and w down; across it runs from
    ' the monster's feet (left) to its head (right)
    cs = h : spriteSize(dst) = cs
    FOR ny = 0 TO cs - 1 : FOR nx = 0 TO cs - 1
        down = ny * w \ cs ' (stretched down to fill the square)
        col~& = spriteTex(x0 + down, y1 - nx, src)
        IF _ALPHA32(col~&) > 128 THEN col~& = _RGBA32(_RED32(col~&) * 0.6, _GREEN32(col~&) * 0.6, _BLUE32(col~&) * 0.6, 255)
        spriteTex(nx, ny, dst) = col~&
    NEXT : NEXT
    corpseScale(mtype) = mtypeScale(mtype) * h / sz : corpseSquash(mtype) = w / h
END SUB

' An explosion's animation, into sprite slots S_BOOM + 1 to S_BOOM +
' BOOM_FRAMES: explosion-1.png to -6.png if they're drawn, else made from
' explosion.png. Through the six (t goes 0 to 1) the fire spreads out from
' its middle (pixels further out than reach don't show yet), white-hot at
' first; then cools - darker, then grey smoke - and breaks up (more and
' more pixels gone, at random) as it rises.
SUB MakeBoomFrames
    src = S_BLAST : sz = spriteSize(src)
    x0 = sz : y0 = sz : x1 = -1 : y1 = -1
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
        IF _ALPHA32(spriteTex(x, y, src)) > 128 THEN
            IF x < x0 THEN x0 = x
            IF x > x1 THEN x1 = x
            IF y < y0 THEN y0 = y
            IF y > y1 THEN y1 = y
        END IF
    NEXT : NEXT
    cx = (x0 + x1) / 2 : cy = y0 + (y1 - y0) * 0.6 : far = SQR(((x1 - x0) / 2) ^ 2 + ((y1 - y0) * 0.6) ^ 2) + 1
    cl = sz \ 16 : IF cl < 1 THEN cl = 1 ' (it breaks up in clumps - 4 x 4 pixels of a 64-pixel picture - not single pixels)
    DIM clump(sprTex \ cl, sprTex \ cl)
    FOR k = 1 TO BOOM_FRAMES
        dst = S_BOOM + k : file$ = "explosion-" + LTRIM$(STR$(k)) + ".png"
        IF _FILEEXISTS(AssetPath$(file$)) THEN
            LoadSprite file$, dst
        ELSE
            spriteSize(dst) = sz : t = (k - 1) / (BOOM_FRAMES - 1)
            FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1 : spriteTex(x, y, dst) = 0 : NEXT : NEXT
            reach = 0.3 + 0.7 * t * 2.5 : IF reach > 1 THEN reach = 1
            rise = 0 : IF t > 0.5 THEN rise = INT((t - 0.5) * 10 * sz / 64)
            FOR cy2 = 0 TO sprTex \ cl : FOR cx2 = 0 TO sprTex \ cl : clump(cx2, cy2) = RND : NEXT : NEXT
            FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
                col~& = spriteTex(x, y, src)
                IF _ALPHA32(col~&) > 128 AND SQR((x - cx) ^ 2 + (y - cy) ^ 2) / far <= reach THEN
                    r = _RED32(col~&) : g = _GREEN32(col~&) : b = _BLUE32(col~&)
                    IF t < 0.3 THEN ' White-hot
                        r = r + (255 - r) * 0.6 : g = g + (245 - g) * 0.6 : b = b + (190 - b) * 0.6
                    ELSEIF t > 0.55 THEN ' Cooling to smoke
                        k2 = (t - 0.55) / 0.45 * 0.95
                        grey = (r + g + b) / 3 * 0.3 + 15
                        r = r + (grey - r) * k2 : g = g + (grey * 0.95 - g) * k2 : b = b + (grey * 1.05 - b) * k2
                    END IF
                    gone = (t - 0.45) * 1.3 ' (how much has broken up)
                    IF clump(x \ cl, y \ cl) >= gone AND y - rise >= 0 THEN spriteTex(x, y - rise, dst) = _RGB32(r, g, b)
                END IF
            NEXT : NEXT
        END IF
    NEXT
END SUB

' Monster type mtype's animation frame f (0 to ANIM_FRAMES - 1 moving,
' ANIM_FRAMES attacking): its sprite slot
FUNCTION MonFrame(mtype, f)
    MonFrame = S_ANIM + (mtype - 1) * (ANIM_FRAMES + 1) + f + 1
END FUNCTION

' Each monster's animation - four frames of moving and one of attacking -
' into its MonFrame slots. A frame drawn by hand wins: <name>-walk1.png to
' -walk4.png and <name>-attack.png (64 x 64, see-through background, the
' monster standing in the same place as in <name>.png). Any that aren't
' there are made here from its picture, the way the old games' artists
' animated: by moving parts of it a pixel or two.
'
' First, where its parts are: its edges (x0..x1, y0..y1) and middle (mx),
' and its hips - the bottom third is legs. Then for frame f, a step
' through a cycle (ph, a quarter turn a frame) - each pixel of the picture
' is moved (MonMove) by what kind of mover it is:
'   walkers (gunner, heavy)  each leg lifts and swings with its side of the
'                            body, half a cycle apart; arms swing against
'                            the legs; the body bobs as each foot lands
'   the drone                hovers up and down; its arms (the sides)
'                            flap; its eye pulses
'   the crawler              legs (the sides) scuttle in alternate pairs
'   the sentry               its head (the top half) turns side to side;
'                            its light blinks
' The attack frame: the whole picture a little bigger (it lunges), and
' brighter, its reds burning.
SUB MakeMonFrames(mtype)
    src = mtypeSprite(mtype) : sz = spriteSize(src) : nm$ = mtypeName$(mtype)
    x0 = sz : y0 = sz : x1 = -1 : y1 = -1
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
        IF _ALPHA32(spriteTex(x, y, src)) > 128 THEN
            IF x < x0 THEN x0 = x
            IF x > x1 THEN x1 = x
            IF y < y0 THEN y0 = y
            IF y > y1 THEN y1 = y
        END IF
    NEXT : NEXT
    IF x1 < 0 THEN x0 = 0 : y0 = 0 : x1 = sz - 1 : y1 = sz - 1
    mx = (x0 + x1) / 2 : w = x1 - x0 + 1 : h = y1 - y0 + 1 : hip = y0 + h * 0.62
    monK = sz / 64 : IF monK < 1 THEN monK = 1 ' (MonMove's moves are in a 64-pixel picture's pixels)
    FOR f = 0 TO ANIM_FRAMES
        dst = MonFrame(mtype, f)
        IF f < ANIM_FRAMES THEN file$ = nm$ + "-walk" + LTRIM$(STR$(f + 1)) + ".png" ELSE file$ = nm$ + "-attack.png"
        IF _FILEEXISTS(AssetPath$(file$)) THEN
            LoadSprite file$, dst
        ELSE
            spriteSize(dst) = sz
            FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1 : spriteTex(x, y, dst) = 0 : NEXT : NEXT
            ph = f * 1.5708 ' (a quarter of the cycle a frame)
            FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
                col~& = spriteTex(x, y, src)
                IF _ALPHA32(col~&) > 128 THEN
                    nx = x : ny = y
                    IF f = ANIM_FRAMES THEN ' Attacking: lunge, flare
                        nx = INT(mx + (x - mx) * 1.08 + 0.5) : ny = INT(y1 - (y1 - y) * 1.08 + 0.5)
                        r = _RED32(col~&) : g = _GREEN32(col~&) : b = _BLUE32(col~&)
                        IF r > 180 AND g < 100 AND b < 110 THEN r = 255 : g = g * 0.6 + 90 : b = b * 0.6 + 70 ' (its red lights burn)
                        r = r * 1.1 : g = g * 1.1 : b = b * 1.1
                        IF r > 255 THEN r = 255
                        IF g > 255 THEN g = 255
                        IF b > 255 THEN b = 255
                        col~& = _RGB32(r, g, b)
                    ELSE
                        MonMove mtype, x, y, ph, x0, x1, y0, y1, mx, hip, nx, ny, col~&
                    END IF
                    IF nx >= 0 AND ny >= 0 AND nx < sz AND ny < sz THEN
                        ' (the attack frame grows: fill the gaps growing leaves)
                        spriteTex(nx, ny, dst) = col~&
                        IF f = ANIM_FRAMES AND nx + 1 < sz THEN IF _ALPHA32(spriteTex(nx + 1, ny, dst)) < 128 THEN spriteTex(nx + 1, ny, dst) = col~&
                        IF f = ANIM_FRAMES AND ny > 0 THEN IF _ALPHA32(spriteTex(nx, ny - 1, dst)) < 128 THEN spriteTex(nx, ny - 1, dst) = col~&
                    END IF
                END IF
            NEXT : NEXT
        END IF
    NEXT
END SUB

' Where pixel (x, y) of a monster's picture goes in a moving frame, ph
' through its cycle (MakeMonFrames has the parts), into (nx, ny) - and its
' colour (col~&) for the drone's eye and the sentry's light
SUB MonMove(mtype, x, y, ph, x0, x1, y0, y1, mx, hip, nx, ny, col~&)
    w = x1 - x0 + 1 : h = y1 - y0 + 1
    side = 1 : IF x < mx THEN side = -1 ' Which side of its middle
    edge = ABS(x - mx) / (w / 2) ' (0 at the middle, 1 at its edge)
    nx = x : ny = y
    r = _RED32(col~&) : g = _GREEN32(col~&) : b = _BLUE32(col~&) : redLight = r > 150 AND r > g * 1.6 AND r > b * 1.6
    SELECT CASE mtype
        CASE 2, 3, 6, 7, 9 ' Walkers
            IF y >= hip THEN ' A leg: lifts (its side's foot off the floor) and swings
                d = (y - hip) / (y1 - hip + 1) ' (0 at the hip, 1 at the foot)
                swing = SIN(ph + (side > 0) * 3.14159)
                lift = swing : IF lift < 0 THEN lift = 0
                nx = x + INT(COS(ph + (side > 0) * 3.14159) * 3 * d * monK + 0.5) : ny = y - INT(lift * 3 * d * monK + 0.5)
            ELSE ' The body bobs as a foot lands; arms (its outer quarter) swing against the legs
                IF ph = 1.5708 OR ph > 4.7 THEN ny = y - INT(monK)
                IF edge > 0.55 AND y > y0 + h * 0.25 THEN ny = ny + INT(SIN(ph + (side < 0) * 3.14159) * 1.5 * monK + 0.5)
            END IF
        CASE 1, 8 ' The drone (and the overseer): hovers, flaps, its eye pulses
            ny = y + INT(SIN(ph) * 1.5 * monK + 0.5)
            IF edge > 0.45 THEN ny = ny + INT(SIN(ph * 2) * 2 * edge * monK + 0.5)
            IF redLight THEN k = 0.75 + 0.25 * SIN(ph) : col~& = _RGB32(r * k + 60 * (1 - k), g * k, b * k)
        CASE 4 ' The crawler: legs scuttle in alternate pairs
            IF edge > 0.4 THEN
                pair = INT(edge * 3) MOD 2 ' (inner and outer legs out of step)
                ny = y + INT(SIN(ph + pair * 3.14159 + (side > 0) * 1.5708) * 2 * monK + 0.5)
                nx = x + INT(COS(ph + pair * 3.14159) * side * monK + 0.5)
            ELSE
                ny = y + INT(SIN(ph * 2) * 0.6 * monK + 0.5)
            END IF
        CASE 5 ' The sentry: its head turns, its light blinks
            IF y < y0 + h * 0.5 THEN nx = x + INT(SIN(ph) * 1.6 * monK + 0.5)
            IF redLight THEN IF ph > 3 THEN col~& = _RGB32(r * 0.35, g * 0.35, b * 0.35)
    END SELECT
END SUB

' A decoration's wreck: what's left standing once it's broken - the bottom
' of its picture (how much depends on what it was), its top edge torn
' ragged, darkened and sooty - into sprite slot S_WRECK + kind, squared up
' like a monster's body (MakeCorpse): stretched to fill the square, drawn
' squashed back (wreckSquash) at its own width (wreckScale).
SUB MakeWreck(kind)
    src = DecoSlot(kind) : sz = spriteSize(src) : dst = S_WRECK + kind
    x0 = sz : y0 = sz : x1 = -1 : y1 = -1
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz - 1
        IF _ALPHA32(spriteTex(x, y, src)) > 128 THEN
            IF x < x0 THEN x0 = x
            IF x > x1 THEN x1 = x
            IF y < y0 THEN y0 = y
            IF y > y1 THEN y1 = y
        END IF
    NEXT : NEXT
    IF x1 < 0 THEN x0 = 0 : y0 = 0 : x1 = sz - 1 : y1 = sz - 1
    w = x1 - x0 + 1 : h = y1 - y0 + 1
    keep = VAL(MID$("0.30.20.40.40.40.30.40.30.20.50.40.30.30.50.40.30.30.40.5", kind * 3 - 2, 3)) ' How much stays (barrel, lamp, plant ... bench)
    kh = INT(h * keep) : IF kh < 2 THEN kh = 2
    DIM tear(sprTex) ' (how far down each column is torn off)
    FOR x = 0 TO w - 1 : tear(x) = INT(RND * kh * 0.4) : NEXT
    spriteSize(dst) = w
    FOR ny = 0 TO w - 1 : FOR nx = 0 TO w - 1
        down = ny * kh \ w ' (rows of what's left, stretched down the square)
        col~& = spriteTex(x0 + nx, y1 - kh + 1 + down, src)
        IF down < tear(nx) THEN col~& = 0 ' Torn away
        IF _ALPHA32(col~&) > 128 THEN
            soot = 0.25 + RND * 0.25
            col~& = _RGBA32(_RED32(col~&) * soot, _GREEN32(col~&) * soot, _BLUE32(col~&) * soot, 255)
        END IF
        spriteTex(nx, ny, dst) = col~&
    NEXT : NEXT
    wreckScale(kind) = DecoScale(kind) * w / sz : wreckSquash(kind) = kh / w
END SUB

' The scorch mark drawn for a decal: a ragged dark blob, into sprite slot
' S_DECAL
SUB MakeScorch
    spriteSize(S_DECAL) = 32
    FOR y = 0 TO 31 : FOR x = 0 TO 31
        d = SQR((x - 15.5) ^ 2 + (y - 15.5) ^ 2) / 16 + (RND - 0.5) * 0.18 ' (ragged)
        a = 255 : IF d > 0.45 THEN a = 255 * (1 - (d - 0.45) / 0.5) ' Solid in the middle, fading out
        IF a < 0 THEN a = 0
        k = 1 - d * 0.6 : IF k < 0.3 THEN k = 0.3 ' (blackest in the middle)
        spriteTex(x, y, S_DECAL) = _RGBA32((26 + RND * 14) * (1.6 - k), (18 + RND * 8) * (1.6 - k), (16 + RND * 8) * (1.6 - k), a)
    NEXT : NEXT
END SUB

' The ceiling lamp, shot out: its picture copied (from T_LAMP) with the
' bright panel gone dark and cracked, into texture slot T_LAMPOFF
SUB MakeLampOff
    FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1
        col~& = texture(x, y, T_LAMP)
        bright = (_RED32(col~&) + _GREEN32(col~&) + _BLUE32(col~&)) / 3
        IF bright > 150 THEN col~& = _RGB32(_RED32(col~&) * 0.18, _GREEN32(col~&) * 0.18, _BLUE32(col~&) * 0.2) ' (the panel, dark)
        texture(x, y, T_LAMPOFF) = col~&
    NEXT : NEXT
    texHD(T_LAMPOFF) = texHD(T_LAMP)
    FOR crack = 1 TO 5 ' A few cracks across it, from near the middle
        cx = texSize / 2 + (RND - 0.5) * texSize * 0.3 : cy = texSize / 2 + (RND - 0.5) * texSize * 0.3
        a = RND * 6.2832
        FOR stp = 0 TO texSize * 0.35 STEP texSize \ 128
            px = INT(cx + COS(a) * stp) : py = INT(cy + SIN(a) * stp) : a = a + (RND - 0.5) * 0.4
            FOR ty = py TO py + texSize \ 128 - 1 : FOR tx = px TO px + texSize \ 128 - 1 ' (as thick in a bigger picture)
                IF tx >= 0 AND ty >= 0 AND tx < texSize AND ty < texSize THEN texture(tx, ty, T_LAMPOFF) = _RGB32(70, 70, 82)
            NEXT : NEXT
        NEXT
    NEXT
    texName$(T_LAMPOFF) = "ceiling-lamp-off"
END SUB

' The keycard picture, tinted red, blue and yellow, into sprite slots 1-3
' and into images for the HUD; and the key door textures, the door tinted
' the same three ways. (_DONTBLEND makes PSET store a see-through colour
' as it is, instead of mixing it with what's under it.)
SUB LoadCards(file$)
    LoadSprite file$, 1
    sprSize = spriteSize(1)
    FOR card = 1 TO 3
        spriteSize(card) = sprSize
        IF cardImg&(card) < -1 THEN _FREEIMAGE cardImg&(card) ' (made before: ART changed)
        cardImg&(card) = _NEWIMAGE(sprSize, sprSize, 32)
        _DONTBLEND cardImg&(card)
        _DEST cardImg&(card)
        FOR y = 0 TO sprSize - 1 : FOR x = 0 TO sprSize-1
            IF card = 1 THEN col~& = spriteTex(x, y, 1) ELSE col~& = spriteTex(x, y, 0)
            IF card = 1 THEN spriteTex(x, y, 0) = col~& '(the untinted card, kept in slot 0)
            spriteTex(x, y, card) = Tint~&(col~&, CardRGB~&(card), 1)
            PSET (x, y), spriteTex(x, y, card)
        NEXT : NEXT
        _BLEND cardImg&(card)
        FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize-1
            texture(x, y, T_DOORK + card) = Tint~&(texture(x, y, T_DOOR), CardRGB~&(card), 0.85)
        NEXT : NEXT
        texHD(T_DOORK + card) = texHD(T_DOOR)
    NEXT
    _DEST 0
END SUB

' Colour col pushed toward tintCol by amount! (0-1), keeping its light and
' dark: a bright pixel of a grey card becomes bright red, a dark one dark red.
FUNCTION Tint~&(col AS _UNSIGNED LONG, tintCol AS _UNSIGNED LONG, amount!)
    lum! = (_RED32(col) + _GREEN32(col) + _BLUE32(col)) / 3 / 255 * 1.6
    r! = _RED32(col) * (1 - amount!) + _RED32(tintCol) * lum! * amount!
    g! = _GREEN32(col) * (1 - amount!) + _GREEN32(tintCol) * lum! * amount!
    b! = _BLUE32(col) * (1 - amount!) + _BLUE32(tintCol) * lum! * amount!
    IF r! > 255 THEN r! = 255
    IF g! > 255 THEN g! = 255
    IF b! > 255 THEN b! = 255
    Tint~& = _RGBA32(r!, g!, b!, _ALPHA32(col))
END FUNCTION

' Darken a colour: its red, green and blue times amount/256 (amount 0-256).
' This runs for every pixel of every frame, so it's done with a trick: in
' &HAARRGGBB, red and blue are 16 bits apart, so masking with &HFF00FF and
' multiplying darkens both at once without them spilling into each other.
' Green is done on its own the same way, and alpha is set back to solid.
FUNCTION Shade~&(col AS _UNSIGNED LONG, amount AS LONG)
    DIM redBlue AS _INTEGER64, green AS _INTEGER64
    redBlue = col AND &HFF00FF : green = col AND &HFF00&
    Shade~& = &HFF000000~& OR ((redBlue * amount \ 256) AND &HFF00FF) OR ((green * amount \ 256) AND &HFF00&)
END FUNCTION

' The bolt sprite, drawn with maths: a hard-edged glowing magenta ball,
' white hot in the middle (r is how far each pixel is from the centre).
SUB MakeBolt(slot)
    spriteSize(slot) = 16
    FOR y = 0 TO 15 : FOR x = 0 TO 15
        r = SQR((x - 7.5) ^ 2 + (y-7.5) ^ 2) / 7.5
        IF r < 0.45 THEN
            spriteTex(x, y, slot) = _RGB32(255, 240, 255)
        ELSEIF r < 0.75 THEN
            spriteTex(x, y, slot) = _RGB32(255, 110, 235)
        ELSEIF r < 1 THEN
            spriteTex(x, y, slot) = _RGB32(200, 30, 200)
        ELSE
            spriteTex(x, y, slot) = 0
        END IF
    NEXT : NEXT
END SUB

' Print "EXIT" on a lit sign at the top of the exit door's texture: copy the
' texture into an image, draw on it with LINE and _PRINTSTRING, and copy
' it back.
SUB ExitSign
    k = texSize / 128 ' (the sign is placed for a 128-pixel picture)
    img& = _NEWIMAGE(texSize, texSize, 32)
    _DEST img&
    FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1 : PSET (x, y), texture(x, y, T_EXIT) : NEXT : NEXT
    sign& = _NEWIMAGE(38, 20, 32) : _DEST sign&
    LINE (0, 0)-(37, 19), _RGB32(10, 40, 20), BF
    LINE (0, 0)-(37, 19), _RGB32(60, 255, 120), B
    _PRINTMODE _KEEPBACKGROUND : COLOR _RGB32(110, 255, 150) : _PRINTSTRING (3, 2), "EXIT"
    _PUTIMAGE (13 * k, 5 * k)-(51 * k - 1, 25 * k - 1), sign&, img& ' (bigger for a bigger picture)
    _SOURCE img&
    FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1 : texture(x, y, T_EXIT) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0 : _DEST 0 : _FREEIMAGE img& : _FREEIMAGE sign&
END SUB

' A texture's average colour, a little brighter (each wall kind's minimap
' colour)
FUNCTION MinimapColor~&(slot)
    FOR y = 0 TO texSize - 1 STEP 2 : FOR x = 0 TO texSize - 1 STEP 2
        col~& = texture(x, y, slot) : red& = red& + _RED32(col~&) : green& = green& + _GREEN32(col~&) : blue& = blue& + _BLUE32(col~&) : count& = count& + 1
    NEXT : NEXT
    MinimapColor~& = _RGB32(red& / count& * 1.4, green& / count& * 1.4, blue& / count& * 1.4)
END FUNCTION

' === WALLS, COLLISION, AND THE DIAGONAL MATHS =================================

' Any kind of wall (not a door, not floor)? (Diagonal cells count: their
' worldMap value is a wall. SolidAt asks about a point instead.)
FUNCTION IsWall(x, y)
    cellValue = worldMap(x, y)
    IsWall = cellValue > 0 AND cellValue <> 2
END FUNCTION

' Can a body be at map point (x, y)? Open floor or a mostly-open door, and
' not inside a decoration - or, in a diagonal wall's cell, in its open half.
' Each kind of door's own ways (chapter 11): how much it opens or shuts a
' frame (shutters are heavy and slow, split doors snap), how many frames it
' stays open before shutting itself, and its sound
FUNCTION DoorSpeed(kind)
    SELECT CASE kind
        CASE DOOR_SHUTTER : DoorSpeed = 0.025
        CASE DOOR_SPLIT : DoorSpeed = 0.06
        CASE ELSE : DoorSpeed = 0.04
    END SELECT
END FUNCTION

FUNCTION DoorHold(kind)
    SELECT CASE kind
        CASE DOOR_SHUTTER : DoorHold = 360 ' 6 seconds
        CASE DOOR_SPLIT : DoorHold = 180 ' 3
        CASE ELSE : DoorHold = 240 ' 4
    END SELECT
END FUNCTION

' How open door (x, y) LOOKS: never all the way - DOOR_LIP of it always
' shows (a shutter's bottom edge hangs at the top of the doorway, a
' sliding door's edge stands at the side, a split door's two edges at
' both), so an open door is still there. Walking through goes by
' doorOpen itself.
FUNCTION DoorShown(x, y)
    DoorShown = doorOpen(x, y) * (1 - DOOR_LIP)
END FUNCTION

'' Lock (locked -1) or unlock (0) every door in event ev's room or near it
' (within 5 cells: a room's doors can be at the ends of short corridors).
' Locking one that's open shuts it (the door loop does that, once nobody's
' in the way).
SUB LockRoom(ev, locked)
    FOR y = evY0(ev) - 5 TO evY1(ev) + 5 : FOR x = evX0(ev) - 5 TO evX1(ev) + 5
        IF x >= 0 AND y >= 0 AND x < MAP_SIZE AND y < MAP_SIZE THEN
            IF worldMap(x, y) = 2 AND doorType(x, y) <> DOOR_EXIT AND doorLock(x, y) <> 2 AND doorLock(x, y) <> 3 THEN doorLock(x, y) = locked
        END IF
    NEXT : NEXT
END SUB

' Is map point (x, y) in event ev's room?
FUNCTION InRoom(ev, x, y)
    InRoom = x >= evX0(ev) AND x < evX1(ev) + 1 AND y >= evY0(ev) AND y < evY1(ev) + 1
END FUNCTION

' A monster of type t teleports into event ev's room - somewhere open, and
' not right on top of you (a few tries at random). TRUE if it found room.
FUNCTION SpawnInRoom(ev, t)
    FOR try = 1 TO 30
        x = evX0(ev) + 0.5 + INT(RND * (evX1(ev) - evX0(ev) + 1)) : y = evY0(ev) + 0.5 + INT(RND * (evY1(ev) - evY0(ev) + 1))
        IF (x - playerX) ^ 2 + (y - playerY) ^ 2 > 6 THEN
            IF SpawnMonster(t, x, y, ev) THEN SpawnInRoom = -1 : EXIT FUNCTION
        END IF
    NEXT
END FUNCTION

' ...or next to a spawner at (sx, sy)
FUNCTION SpawnNear(ev, t, sx, sy)
    FOR try = 1 TO 20
        x = INT(sx + (RND - 0.5) * 3) + 0.5 : y = INT(sy + (RND - 0.5) * 3) + 0.5
        IF SpawnMonster(t, x, y, ev) THEN SpawnNear = -1 : EXIT FUNCTION
    NEXT
END FUNCTION

' One more monster, of type t, at (x, y) - if there's floor there, nothing
' else standing on it, and room in the list - hunting you at once, sent by
' event ev. It arrives in a flash of sparks.
FUNCTION SpawnMonster(t, x, y, ev)
    IF numMonsters >= MAX_MON THEN EXIT FUNCTION
    walkFromHaz = 10 : ok = Walkable%(x, y) : walkFromHaz = 0 ' (as a monster would: not in fire, not over a pit)
    IF NOT ok THEN EXIT FUNCTION
    FOR j = 1 TO numMonsters
        IF monsterState(j) < 2 THEN IF (monsterX(j) - x) ^ 2 + (monsterY(j) - y) ^ 2 < 0.6 THEN EXIT FUNCTION
    NEXT
    numMonsters = numMonsters + 1 : i = numMonsters
    monsterX(i) = x : monsterY(i) = y : monsterType(i) = t : monsterHP(i) = mtypeHP(t)
    monsterState(i) = 1 : monsterTimer(i) = 40 : monsterHurt(i) = 0 : monsterAtk(i) = 0 : monsterAnim(i) = 0 : monsterEv(i) = ev
    ThiefReset i
    SpawnSparks x, y, 0.5, 16, 200, 120, 255
    SfxAt sndSpawn&, x, y, playerX, playerY
    SpawnMonster = -1
END FUNCTION

'' A thief bot's pockets, empty
SUB ThiefReset(i)
    thiefCells(i) = 0 : thiefShells(i) = 0 : thiefGun(i) = 0 : thiefState(i) = 0
END SUB

' A thief bot (monster i) is destroyed: what it stole spills out round it
SUB DropThiefLoot(i)
    x = monsterX(i) : y = monsterY(i) : n = 0
    IF thiefGun(i) THEN
        SELECT CASE thiefGun(i)
            CASE W_SCATTER : k = IT_SCATTER
            CASE W_REPEATER : k = IT_REPEATER
            CASE ELSE : k = IT_RAIL
        END SELECT
        DropItemAt k, x, y : n = n + 1
    END IF
    FOR c = 1 TO (thiefCells(i) + 14) \ 15 : DropItemAt IT_CELLS, x + COS(n * 2.1) * 0.35, y + SIN(n * 2.1) * 0.35 : n = n + 1 : NEXT
    FOR c = 1 TO (thiefShells(i) + 7) \ 8 : DropItemAt IT_SHELLS, x + COS(n * 2.1) * 0.35, y + SIN(n * 2.1) * 0.35 : n = n + 1 : NEXT
    IF n THEN ShowMsg "The thief dropped your things!"
    ThiefReset i
END SUB

' One more pickup, of kind kind, just where (x, y) is (if that's floor -
' or else in the middle of its cell)
SUB DropItemAt(kind, x, y)
    IF numItems >= MAX_ITEMS THEN EXIT SUB
    IF NOT Walkable%(x, y) THEN x = INT(x) + 0.5 : y = INT(y) + 0.5
    numItems = numItems + 1
    itemX(numItems) = x : itemY(numItems) = y : itemKind(numItems) = kind : itemOn(numItems) = -1
    SpawnSparks x, y, 0.3, 10, 255, 230, 120
END SUB

' Each closet wall (%) to its closet event - the first closet event whose
' room it's within 3 cells of - and its look: the wall it's set in (the
' commonest of its neighbours)
' The floor's (and the ceiling's) height at map point (x, y) - 0 and 1
' off the map
FUNCTION FloorAt(x, y)
    cx = INT(x) : cy = INT(y)
    IF cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN FloorAt = floorH(cx, cy)
END FUNCTION
FUNCTION CeilAt(x, y)
    cx = INT(x) : cy = INT(y)
    IF cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN CeilAt = ceilH(cx, cy) ELSE CeilAt = 1
END FUNCTION

' A height from its character in [floor] or [ceiling] (chapter 22): . is
' dflt; 0-9, a-z that many eighths of a wall; A-H that many eighths below 0
FUNCTION HeightOf(c$, dflt)
    k = INSTR(H_UP$, c$)
    IF k THEN HeightOf = (k - 1) * H_STEP : EXIT FUNCTION
    k = INSTR(H_DOWN$, c$)
    IF k THEN HeightOf = -k * H_STEP : EXIT FUNCTION
    HeightOf = dflt
END FUNCTION

' ...and the character for height h (. if it's dflt)
FUNCTION HeightChar$(h, dflt)
    IF ABS(h - dflt) < 0.001 THEN HeightChar$ = "." : EXIT FUNCTION
    k = CINT(h / H_STEP)
    IF k >= 0 THEN
        IF k >= LEN(H_UP$) THEN k = LEN(H_UP$) - 1
        HeightChar$ = MID$(H_UP$, k + 1, 1)
    ELSE
        IF -k > LEN(H_DOWN$) THEN k = -LEN(H_DOWN$)
        HeightChar$ = MID$(H_DOWN$, -k, 1)
    END IF
END FUNCTION

' The file of level n
' Where your own sectors' files go: neon-caster/levels/custom/ (made by
' the first NEW SECTOR - WriteBlankSector)
FUNCTION CustomDir$
    f$ = AssetPath$("levels/level1.txt")
    CustomDir$ = LEFT$(f$, LEN(f$) - LEN("level1.txt")) + "custom/"
END FUNCTION

' Sector n's name, from its file's name = line, without reading the rest
' (ReadLevelFile fills in the level being played) - "" if there's no file
FUNCTION SectorNameOf$(n)
    f$ = LevelFile$(n) : IF NOT _FILEEXISTS(f$) THEN EXIT FUNCTION
    fh = FREEFILE : OPEN f$ FOR INPUT AS #fh
    DO UNTIL EOF(fh)
        LINE INPUT #fh, l$ : t$ = LTRIM$(RTRIM$(l$))
        IF LEFT$(t$, 1) = "[" THEN EXIT DO
        eq = INSTR(t$, "=")
        IF eq THEN IF LCASE$(RTRIM$(LEFT$(t$, eq - 1))) = "name" THEN SectorNameOf$ = LTRIM$(MID$(t$, eq + 1)) : EXIT DO
    LOOP
    CLOSE #fh
END FUNCTION

' Is there a sector n? (The game's are always there; yours once made.)
FUNCTION SectorExists(n)
    IF n >= 1 AND n <= NUM_LEVELS THEN SectorExists = -1 ELSE IF n > NUM_LEVELS AND n <= NUM_LEVELS + MAX_CUSTOM THEN SectorExists = _FILEEXISTS(LevelFile$(n))
END FUNCTION

' A sector's music: its own - or, for one of yours, one of the game's in turn
FUNCTION SectorMusic&(n)
    IF n > NUM_LEVELS THEN SectorMusic& = levelMusic&((n - NUM_LEVELS - 1) MOD NUM_LEVELS + 1) ELSE SectorMusic& = levelMusic&(n)
END FUNCTION

' A blank slate for sector n: solid wall, with one lit room in the middle
' to carve outwards from - you facing east, the exit in the far wall
SUB WriteBlankSector(n)
    nl$ = CHR$(10) : q$ = "' "
    o$ = q$ + "NEON-CASTER level file - see chapter 22 of neon-caster.bas for every" + nl$
    o$ = o$ + q$ + "part of it. Lines starting with ' are comments. The level kit" + nl$
    o$ = o$ + q$ + "(levels.py --write) and the editor in the game write these files." + nl$
    o$ = o$ + q$ + "Your own sector, made blank by NEW SECTOR: one room in solid wall." + nl$
    o$ = o$ + nl$ + "name     = MY SECTOR " + LTRIM$(STR$(n - NUM_LEVELS)) + nl$
    o$ = o$ + "walls    = wall.png, wall2.png, wall-concrete.png, wall-servers.png, wall-pipes.png, wall-biolab.png" + nl$
    o$ = o$ + "floors   = floor.png, floor-plates.png, floor-concrete.png, floor-lab.png" + nl$
    o$ = o$ + "ceilings = ceiling.png, ceiling-lights.png" + nl$
    o$ = o$ + "ambient  = 165, 225, 220, 255" + nl$
    o$ = o$ + nl$ + "[lights]" + nl$ + "' x, y, radius, brightness, red, green, blue, effect" + nl$
    o$ = o$ + "24, 24, 7, 150, 220, 230, 255, 0" + nl$
    o$ = o$ + nl$ + "[map]" + nl$
    FOR y = 0 TO MAP_SIZE - 1
        r$ = STRING$(MAP_SIZE, "#")
        IF y >= 20 AND y <= 27 THEN MID$(r$, 21, 8) = STRING$(8, ".") ' The room: cells 20 to 27 each way
        IF y = 24 THEN MID$(r$, 22, 1) = ">" : MID$(r$, 29, 1) = "E" ' You at (21, 24), the exit at (28, 24)
        o$ = o$ + r$ + nl$
    NEXT
    d$ = CustomDir$ : d$ = LEFT$(d$, LEN(d$) - 1) : IF NOT _DIREXISTS(d$) THEN MKDIR d$
    f$ = LevelFile$(n) : fh = FREEFILE
    OPEN f$ FOR OUTPUT AS #fh : PRINT #fh, o$; : CLOSE #fh
END SUB

FUNCTION LevelFile$(n)
    IF n > NUM_LEVELS THEN LevelFile$ = CustomDir$ + "custom" + LTRIM$(STR$(n - NUM_LEVELS)) + ".txt" : EXIT FUNCTION
    LevelFile$ = AssetPath$("levels/level" + LTRIM$(STR$(n)) + ".txt")
END FUNCTION

' Read level n's file (chapter 22) into lvlName$, lvlWall$() ... lvlRow$():
' line by line, LINE INPUT. A line starting with ' is a comment; a line
' in [brackets] starts a section; before the first section, lines are
' "key = value"; in [zones], [lights] and [events] each line is one of
' them, its numbers split by commas (SplitNums); in [map], each line is a
' row. lvlOK says whether it worked.
SUB ReadLevelFile(n)
    lvlPuzzles$ = "" : lvlOK = 0 : lvlName$ = "?" : lvlNumZones = 0 : lvlNumLights = 0 : lvlNumEvents = 0 : lvlNumLifts = 0 : lvlNumTrigs = 0 : lvlNumFaces = 0 : lvlNote$ = "" : topLines = -1
    FOR k = 0 TO MAP_SIZE - 1 : lvlRow$(k) = "" : lvlFloorRow$(k) = "" : lvlCeilRow$(k) = "" : NEXT
    fRows = 0 : cRows = 0
    f$ = LevelFile$(n)
    IF NOT _FILEEXISTS(f$) THEN EXIT SUB
    DIM v(8) AS SINGLE
    fh = FREEFILE : OPEN f$ FOR INPUT AS #fh
    sec$ = "" : rows = 0
    DO UNTIL EOF(fh)
        LINE INPUT #fh, l$
        t$ = LTRIM$(RTRIM$(l$))
        IF RIGHT$(t$, 1) = CHR$(13) THEN t$ = LEFT$(t$, LEN(t$) - 1) ' (a file from Windows)
        IF sec$ = "map" AND LEN(t$) > 0 AND LEFT$(t$, 1) <> "'" AND LEFT$(t$, 1) <> "[" THEN
            IF rows < MAP_SIZE THEN lvlRow$(rows) = t$ : rows = rows + 1
        ELSEIF sec$ = "floor" AND LEN(t$) > 0 AND LEFT$(t$, 1) <> "'" AND LEFT$(t$, 1) <> "[" THEN
            IF fRows < MAP_SIZE THEN lvlFloorRow$(fRows) = t$ : fRows = fRows + 1
        ELSEIF sec$ = "ceiling" AND LEN(t$) > 0 AND LEFT$(t$, 1) <> "'" AND LEFT$(t$, 1) <> "[" THEN
            IF cRows < MAP_SIZE THEN lvlCeilRow$(cRows) = t$ : cRows = cRows + 1
        ELSEIF sec$ = "triggers" AND LEN(t$) > 0 AND LEFT$(t$, 1) <> "'" AND LEFT$(t$, 1) <> "[" THEN
            IF lvlNumTrigs < MAX_TRIGS THEN lvlNumTrigs = lvlNumTrigs + 1 : lvlTrig$(lvlNumTrigs) = t$
        ELSEIF sec$ = "faces" AND LEN(t$) > 0 AND LEFT$(t$, 1) <> "'" AND LEFT$(t$, 1) <> "[" THEN
            TakeFace t$
        ELSEIF LEN(t$) = 0 OR LEFT$(t$, 1) = "'" THEN
            ' (a blank line, or a comment - those at the top, but for the
            ' three every file starts with, are the level's notes)
            IF topLines AND LEFT$(t$, 1) = "'" THEN
                IF INSTR(t$, "NEON-CASTER level file") = 0 AND INSTR(t$, "part of it. Lines starting") = 0 AND INSTR(t$, "levels.py --write) and the editor") = 0 THEN lvlNote$ = lvlNote$ + t$ + CHR$(10)
            END IF
        ELSEIF LEFT$(t$, 1) = "[" AND RIGHT$(t$, 1) = "]" THEN
            sec$ = LCASE$(LTRIM$(RTRIM$(MID$(t$, 2, LEN(t$) - 2)))) : topLines = 0
        ELSEIF sec$ = "" THEN
            eq = INSTR(t$, "=") : topLines = 0
            IF eq THEN
                k$ = LCASE$(RTRIM$(LEFT$(t$, eq - 1))) : val$ = LTRIM$(MID$(t$, eq + 1))
                SELECT CASE k$
                    CASE "name" : lvlName$ = val$
                    CASE "puzzles" : lvlPuzzles$ = val$
                    CASE "walls" : FOR k = 1 TO 6 : lvlWall$(k) = ListItem$(val$, k) : NEXT
                    CASE "floors" : FOR k = 1 TO 4 : lvlFloor$(k) = ListItem$(val$, k) : NEXT
                    CASE "ceilings" : FOR k = 1 TO 2 : lvlCeil$(k) = ListItem$(val$, k) : NEXT
                    CASE "ambient" : FOR k = 1 TO 4 : lvlAmb(k) = VAL(ListItem$(val$, k)) : NEXT
                END SELECT
            END IF
        ELSE
            got = SplitNums(t$, v())
            SELECT CASE sec$
                CASE "zones"
                    IF got >= 7 AND lvlNumZones < MAX_ZONES THEN lvlNumZones = lvlNumZones + 1 : FOR k = 1 TO 7 : lvlZone(lvlNumZones, k) = v(k) : NEXT
                CASE "lights"
                    IF got >= 8 AND lvlNumLights < MAX_LIGHTS THEN lvlNumLights = lvlNumLights + 1 : FOR k = 1 TO 8 : lvlLight(lvlNumLights, k) = v(k) : NEXT
                CASE "events"
                    IF got >= 8 AND lvlNumEvents < MAX_EVENTS THEN lvlNumEvents = lvlNumEvents + 1 : FOR k = 1 TO 8 : lvlEvent(lvlNumEvents, k) = v(k) : NEXT
                CASE "lifts"
                    IF got >= 8 AND lvlNumLifts < MAX_LIFTS THEN lvlNumLifts = lvlNumLifts + 1 : FOR k = 1 TO 8 : lvlLift(lvlNumLifts, k) = v(k) : NEXT
            END SELECT
        END IF
    LOOP
    CLOSE #fh
    FOR k = 0 TO MAP_SIZE - 1 ' (short rows, or missing ones, are padded with wall)
        IF LEN(lvlRow$(k)) < MAP_SIZE THEN lvlRow$(k) = lvlRow$(k) + STRING$(MAP_SIZE - LEN(lvlRow$(k)), "#")
        lvlFloorRow$(k) = LEFT$(lvlFloorRow$(k) + STRING$(MAP_SIZE, "."), MAP_SIZE) ' (heights: the usual where none's given)
        lvlCeilRow$(k) = LEFT$(lvlCeilRow$(k) + STRING$(MAP_SIZE, "."), MAP_SIZE)
    NEXT
    lvlOK = (rows > 0)
END SUB

' One line of [faces]: x, y, face (E S W N, LE LS LW LN, F or C), how it's
' divided (0, 1 left|right, 2 top|bottom), its picture - and the second
' half's
SUB TakeFace(l$)
    f = FaceCode(ListItem$(l$, 3)) : IF f = 0 THEN EXIT SUB
    EditSetFace VAL(ListItem$(l$, 1)), VAL(ListItem$(l$, 2)), f, VAL(ListItem$(l$, 4)), ListItem$(l$, 5), ListItem$(l$, 6)
END SUB

FUNCTION FaceCode(f$)
    FaceCode = 0
    SELECT CASE UCASE$(f$)
        CASE "E" : FaceCode = 1
        CASE "S" : FaceCode = 2
        CASE "W" : FaceCode = 3
        CASE "N" : FaceCode = 4
        CASE "LE" : FaceCode = 5
        CASE "LS" : FaceCode = 6
        CASE "LW" : FaceCode = 7
        CASE "LN" : FaceCode = 8
        CASE "F" : FaceCode = 9
        CASE "C" : FaceCode = 10
    END SELECT
END FUNCTION

FUNCTION FaceName$(f)
    FaceName$ = RTRIM$(MID$("E S W N LELSLWLNF C ", f * 2 - 1, 2))
END FUNCTION

' Face f of cell (x, y): its picture p1$ (and, divided - d 1 or 2 - the
' second half's, p2$). No picture at all: back to the usual (taken out of
' [faces])
SUB EditSetFace(x, y, f, d, p1$, p2$)
    k = 0
    FOR j = 1 TO lvlNumFaces
        IF lvlFaceX(j) = x AND lvlFaceY(j) = y AND lvlFaceS(j) = f THEN k = j : EXIT FOR
    NEXT
    IF p1$ = "" AND p2$ = "" AND d = 0 THEN ' (taken away)
        IF k THEN
            FOR j = k TO lvlNumFaces - 1
                lvlFaceX(j) = lvlFaceX(j + 1) : lvlFaceY(j) = lvlFaceY(j + 1) : lvlFaceS(j) = lvlFaceS(j + 1) : lvlFaceD(j) = lvlFaceD(j + 1)
                lvlFaceP1$(j) = lvlFaceP1$(j + 1) : lvlFaceP2$(j) = lvlFaceP2$(j + 1)
            NEXT
            lvlNumFaces = lvlNumFaces - 1
        END IF
        EXIT SUB
    END IF
    IF k = 0 THEN
        IF lvlNumFaces >= MAX_FACES THEN EXIT SUB
        lvlNumFaces = lvlNumFaces + 1 : k = lvlNumFaces
    END IF
    lvlFaceX(k) = x : lvlFaceY(k) = y : lvlFaceS(k) = f : lvlFaceD(k) = d : lvlFaceP1$(k) = p1$ : lvlFaceP2$(k) = p2$
END SUB

' The picture slot for face f of cell (x, y) at (u, v) on it - u across as
' you see it, v down from the top, 0 to 1 - its own (or its half's, if
' it's divided), else deflt, the usual
FUNCTION FaceSlot(x, y, f, u, v, deflt)
    sl = faceTex(x, y, f)
    SELECT CASE faceDiv(x, y, f)
        CASE 1 : IF u >= 0.5 THEN sl = faceTex2(x, y, f)
        CASE 2 : IF v >= 0.5 THEN sl = faceTex2(x, y, f)
    END SELECT
    IF sl THEN FaceSlot = sl ELSE FaceSlot = deflt
END FUNCTION

' Which side of cell (x, y) looks towards the cell next to it, (tx, ty):
' 1 east, 2 south, 3 west, 4 north
FUNCTION SideToward(x, y, tx, ty)
    IF tx > x THEN SideToward = 1 ELSE IF ty > y THEN SideToward = 2 ELSE IF tx < x THEN SideToward = 3 ELSE SideToward = 4
END FUNCTION

' Which face of [faces] is (x, y)'s f - 0: none of its own
FUNCTION FaceIndex(x, y, f)
    FaceIndex = 0
    FOR j = 1 TO lvlNumFaces
        IF lvlFaceX(j) = x AND lvlFaceY(j) = y AND lvlFaceS(j) = f THEN FaceIndex = j : EXIT FUNCTION
    NEXT
END FUNCTION

' Item k (from 1) of a list split by commas, trimmed
FUNCTION ListItem$(list$, k)
    s$ = list$ + ","
    FOR i = 1 TO k - 1
        c = INSTR(s$, ",") : IF c = 0 THEN EXIT FUNCTION
        s$ = MID$(s$, c + 1)
    NEXT
    c = INSTR(s$, ",") : IF c = 0 THEN EXIT FUNCTION
    ListItem$ = LTRIM$(RTRIM$(LEFT$(s$, c - 1)))
END FUNCTION

' The numbers in a line split by commas, into v(1), v(2)...; how many
FUNCTION SplitNums(t$, v() AS SINGLE)
    s$ = t$ + "," : n = 0
    DO
        c = INSTR(s$, ",") : IF c = 0 OR n >= UBOUND(v) THEN EXIT DO
        n = n + 1 : v(n) = VAL(LEFT$(s$, c - 1)) : s$ = MID$(s$, c + 1)
    LOOP WHILE LEN(LTRIM$(s$))
    SplitNums = n
END FUNCTION

' --- The editor's helpers (chapter 21) -----------------------------------
' Where the map from above sits on the screen, and its cells' size
' (ED_ constants are near the top: ED_MAPX, ED_MAPY, ED_CELL)

' Put glyph c$ at cell (x, y) of the level (not on its border)
SUB EditPut(x, y, c$)
    IF x < 1 OR y < 1 OR x > MAP_SIZE - 2 OR y > MAP_SIZE - 2 THEN EXIT SUB
    IF INSTR("<>^v", c$) THEN ' (only one start: the old one becomes floor)
        FOR yy = 0 TO MAP_SIZE - 1 : FOR xx = 0 TO MAP_SIZE - 1
            IF INSTR("<>^v", MID$(lvlRow$(yy), xx + 1, 1)) THEN MID$(lvlRow$(yy), xx + 1, 1) = "."
        NEXT : NEXT
    END IF
    MID$(lvlRow$(y), x + 1, 1) = c$
END SUB

' The level (map, zones, lights) as one string - and back - for undo
FUNCTION EditSnapshot$
    s$ = ""
    FOR y = 0 TO MAP_SIZE - 1 : s$ = s$ + lvlRow$(y) : NEXT
    FOR y = 0 TO MAP_SIZE - 1 : s$ = s$ + lvlFloorRow$(y) : NEXT
    FOR y = 0 TO MAP_SIZE - 1 : s$ = s$ + lvlCeilRow$(y) : NEXT
    s$ = s$ + CHR$(1) + LTRIM$(STR$(lvlNumZones))
    FOR k = 1 TO lvlNumZones : FOR j = 1 TO 7 : s$ = s$ + "," + LTRIM$(STR$(lvlZone(k, j))) : NEXT : NEXT
    s$ = s$ + CHR$(1) + LTRIM$(STR$(lvlNumLights))
    FOR k = 1 TO lvlNumLights : FOR j = 1 TO 8 : s$ = s$ + "," + LTRIM$(STR$(lvlLight(k, j))) : NEXT : NEXT
    s$ = s$ + CHR$(1)
    FOR k = 1 TO 6 : s$ = s$ + lvlWall$(k) + "|" : NEXT
    FOR k = 1 TO 4 : s$ = s$ + lvlFloor$(k) + "|" : NEXT
    FOR k = 1 TO 2 : s$ = s$ + lvlCeil$(k) + "|" : NEXT
    s$ = s$ + CHR$(2) ' (the faces' own pictures)
    FOR k = 1 TO lvlNumFaces
        s$ = s$ + LTRIM$(STR$(lvlFaceX(k))) + "," + LTRIM$(STR$(lvlFaceY(k))) + "," + FaceName$(lvlFaceS(k)) + "," + LTRIM$(STR$(lvlFaceD(k))) + "," + lvlFaceP1$(k) + "," + lvlFaceP2$(k) + CHR$(3)
    NEXT
    EditSnapshot$ = s$
END FUNCTION

SUB EditRestore(s0$)
    c2 = INSTR(s0$, CHR$(2)) : s$ = s0$ : f$ = ""
    IF c2 THEN s$ = LEFT$(s0$, c2 - 1) : f$ = MID$(s0$, c2 + 1)
    lvlNumFaces = 0
    DO WHILE LEN(f$)
        c3 = INSTR(f$, CHR$(3)) : IF c3 = 0 THEN EXIT DO
        TakeFace LEFT$(f$, c3 - 1) : f$ = MID$(f$, c3 + 1)
    LOOP
    FOR y = 0 TO MAP_SIZE - 1 : lvlRow$(y) = MID$(s$, y * MAP_SIZE + 1, MAP_SIZE) : NEXT
    FOR y = 0 TO MAP_SIZE - 1 : lvlFloorRow$(y) = MID$(s$, (MAP_SIZE + y) * MAP_SIZE + 1, MAP_SIZE) : NEXT
    FOR y = 0 TO MAP_SIZE - 1 : lvlCeilRow$(y) = MID$(s$, (MAP_SIZE * 2 + y) * MAP_SIZE + 1, MAP_SIZE) : NEXT
    p = MAP_SIZE * MAP_SIZE * 3 + 2
    q = INSTR(p, s$, CHR$(1)) : z$ = MID$(s$, p, q - p) + ","
    lvlNumZones = VAL(z$) : z$ = MID$(z$, INSTR(z$, ",") + 1)
    FOR k = 1 TO lvlNumZones : FOR j = 1 TO 7
        c = INSTR(z$, ",") : lvlZone(k, j) = VAL(LEFT$(z$, c - 1)) : z$ = MID$(z$, c + 1)
    NEXT : NEXT
    p = q + 1 : q = INSTR(p, s$, CHR$(1)) : z$ = MID$(s$, p, q - p) + ","
    lvlNumLights = VAL(z$) : z$ = MID$(z$, INSTR(z$, ",") + 1)
    FOR k = 1 TO lvlNumLights : FOR j = 1 TO 8
        c = INSTR(z$, ",") : lvlLight(k, j) = VAL(LEFT$(z$, c - 1)) : z$ = MID$(z$, c + 1)
    NEXT : NEXT
    z$ = MID$(s$, q + 1)
    FOR k = 1 TO 6 : c = INSTR(z$, "|") : lvlWall$(k) = LEFT$(z$, c - 1) : z$ = MID$(z$, c + 1) : NEXT
    FOR k = 1 TO 4 : c = INSTR(z$, "|") : lvlFloor$(k) = LEFT$(z$, c - 1) : z$ = MID$(z$, c + 1) : NEXT
    FOR k = 1 TO 2 : c = INSTR(z$, "|") : lvlCeil$(k) = LEFT$(z$, c - 1) : z$ = MID$(z$, c + 1) : NEXT
END SUB

' Save the level to its file (the old one kept as .bak) - after checking
' it has a start, an exit, and walls all round
SUB EditSave(lev)
    starts = 0 : exits = 0 : border = -1
    FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
        c$ = MID$(lvlRow$(y), x + 1, 1)
        IF INSTR("<>^v", c$) THEN starts = starts + 1
        IF c$ = "E" THEN exits = exits + 1
        IF x = 0 OR y = 0 OR x = MAP_SIZE - 1 OR y = MAP_SIZE - 1 THEN IF INSTR("#NCKPG", c$) = 0 THEN border = 0
    NEXT : NEXT
    warn$ = ""
    IF starts <> 1 THEN warn$ = warn$ + "  (no start!)"
    IF exits <> 1 THEN warn$ = warn$ + "  (no exit!)"
    IF NOT border THEN warn$ = warn$ + "  (gaps in the border!)"
    f$ = LevelFile$(lev)
    IF _FILEEXISTS(f$) THEN
        IF _FILEEXISTS(f$ + ".bak") THEN KILL f$ + ".bak"
        NAME f$ AS f$ + ".bak"
    END IF
    WriteLevelFile f$
    editDirty = 0
    EditNote "Saved " + f$ + warn$
END SUB

' Write the level (lvlName$ ... lvlRow$()) to file f$, in the format
' ReadLevelFile reads (chapter 22)
SUB WriteLevelFile(f$)
    o$ = "" : nl$ = CHR$(10) ' (built up in o$, then written in one go - with plain line ends, as Linux has them)
    o$ = o$ + "' NEON-CASTER level file - see chapter 22 of neon-caster.bas for every" + nl$
    o$ = o$ + "' part of it. Lines starting with ' are comments. The level kit" + nl$
    o$ = o$ + "' (levels.py --write) and the editor in the game write these files." + nl$
    o$ = o$ + lvlNote$ + nl$
    o$ = o$ + "name     = " + lvlName$ + nl$
    IF lvlPuzzles$ <> "" THEN o$ = o$ + "puzzles  = " + lvlPuzzles$ + nl$
    l$ = "" : FOR k = 1 TO 6 : l$ = l$ + lvlWall$(k) + MID$(", ", 1, -2 * (k < 6)) : NEXT : o$ = o$ + "walls    = " + l$ + nl$
    l$ = "" : FOR k = 1 TO 4 : l$ = l$ + lvlFloor$(k) + MID$(", ", 1, -2 * (k < 4)) : NEXT : o$ = o$ + "floors   = " + l$ + nl$
    o$ = o$ + "ceilings = " + lvlCeil$(1) + ", " + lvlCeil$(2) + nl$
    o$ = o$ + "ambient  = " + NumList$(lvlAmb(1), lvlAmb(2), lvlAmb(3), lvlAmb(4)) + nl$
    o$ = o$ + "" + nl$ : o$ = o$ + "[zones]" + nl$ : o$ = o$ + "' x0, y0, x1, y1, floor, ceiling, shape" + nl$
    FOR k = 1 TO lvlNumZones
        l$ = "" : FOR j = 1 TO 7 : l$ = l$ + LTRIM$(STR$(lvlZone(k, j))) + MID$(", ", 1, -2 * (j < 7)) : NEXT : o$ = o$ + l$ + nl$
    NEXT
    o$ = o$ + "" + nl$ : o$ = o$ + "[lights]" + nl$ : o$ = o$ + "' x, y, radius, brightness, red, green, blue, effect" + nl$
    FOR k = 1 TO lvlNumLights
        l$ = "" : FOR j = 1 TO 8 : l$ = l$ + LTRIM$(STR$(lvlLight(k, j))) + MID$(", ", 1, -2 * (j < 8)) : NEXT : o$ = o$ + l$ + nl$
    NEXT
    o$ = o$ + "" + nl$ : o$ = o$ + "[events]" + nl$ : o$ = o$ + "' kind, x0, y0, x1, y1, a, b, reward" + nl$
    FOR k = 1 TO lvlNumEvents
        l$ = "" : FOR j = 1 TO 8 : l$ = l$ + LTRIM$(STR$(lvlEvent(k, j))) + MID$(", ", 1, -2 * (j < 8)) : NEXT : o$ = o$ + l$ + nl$
    NEXT
    IF lvlNumLifts THEN
        o$ = o$ + nl$ + "[lifts]" + nl$ + "' x0, y0, x1, y1, low, high (eighths of a wall), mode (1 up and down, 2 an elevator), speed (eighths a second)" + nl$
        FOR k = 1 TO lvlNumLifts
            l$ = "" : FOR j = 1 TO 8 : l$ = l$ + LTRIM$(STR$(lvlLift(k, j))) + MID$(", ", 1, -2 * (j < 8)) : NEXT : o$ = o$ + l$ + nl$
        NEXT
    END IF
    IF lvlNumTrigs THEN
        o$ = o$ + nl$ + "[triggers]" + nl$ + "' when (enter X0 Y0 X1 Y1 / use X Y / clear X0 Y0 X1 Y1 / time S) [repeat] : console commands ; ..." + nl$
        FOR k = 1 TO lvlNumTrigs : o$ = o$ + lvlTrig$(k) + nl$ : NEXT
    END IF
    IF lvlNumFaces THEN
        o$ = o$ + nl$ + "[faces]" + nl$ + "' x, y, face (E S W N: a side - LE LS LW LN: a lintel's side - F floor, C ceiling), divided (0, 1 left|right, 2 top|bottom), picture, second half's picture" + nl$
        FOR k = 1 TO lvlNumFaces
            o$ = o$ + LTRIM$(STR$(lvlFaceX(k))) + ", " + LTRIM$(STR$(lvlFaceY(k))) + ", " + FaceName$(lvlFaceS(k)) + ", " + LTRIM$(STR$(lvlFaceD(k))) + ", " + lvlFaceP1$(k)
            IF lvlFaceP2$(k) <> "" THEN o$ = o$ + ", " + lvlFaceP2$(k)
            o$ = o$ + nl$
        NEXT
    END IF
    o$ = o$ + "" + nl$ : o$ = o$ + "[map]" + nl$
    FOR y = 0 TO MAP_SIZE - 1 : o$ = o$ + lvlRow$(y) + nl$ : NEXT
    ' The heights - only if there are any
    anyF = 0 : anyC = 0
    FOR y = 0 TO MAP_SIZE - 1
        IF lvlFloorRow$(y) <> STRING$(MAP_SIZE, ".") THEN anyF = -1
        IF lvlCeilRow$(y) <> STRING$(MAP_SIZE, ".") THEN anyC = -1
    NEXT
    IF anyF THEN
        o$ = o$ + nl$ + "[floor]" + nl$ + "' each cell's floor: . as usual, 0-9 a-z eighths of a wall up, A-H down" + nl$
        FOR y = 0 TO MAP_SIZE - 1 : o$ = o$ + lvlFloorRow$(y) + nl$ : NEXT
    END IF
    IF anyC THEN
        o$ = o$ + nl$ + "[ceiling]" + nl$ + "' each cell's ceiling: . as usual (1), or its height in eighths, as the floor's" + nl$
        FOR y = 0 TO MAP_SIZE - 1 : o$ = o$ + lvlCeilRow$(y) + nl$ : NEXT
    END IF
    IF _FILEEXISTS(f$) THEN KILL f$
    fh = FREEFILE : OPEN f$ FOR BINARY AS #fh : PUT #fh, , o$ : CLOSE #fh
END SUB

FUNCTION NumList$(a, b, c, d)
    NumList$ = LTRIM$(STR$(a)) + ", " + LTRIM$(STR$(b)) + ", " + LTRIM$(STR$(c)) + ", " + LTRIM$(STR$(d))
END FUNCTION

' A message along the editor's bottom, for a few seconds
SUB EditNote(m$)
    editMsg$ = m$ : editMsgUntil! = TIMER + 4
END SUB

' The glyph before or after the one chosen, in EDIT_GLYPHS' order
SUB EditCycleGlyph(d)
    p = INSTR(EDIT_GLYPHS, editGlyph$) + d
    IF p < 1 THEN p = LEN(EDIT_GLYPHS)
    IF p > LEN(EDIT_GLYPHS) THEN p = 1
    editGlyph$ = MID$(EDIT_GLYPHS, p, 1) : EditNote GlyphName$(editGlyph$)
END SUB

' What a map character is (chapter 22's list, in a few words)
FUNCTION GlyphName$(c$)
    SELECT CASE c$
        CASE "." : g$ = "floor"
        CASE "#", "N", "C", "K", "P", "G" : g$ = "wall " + c$ + " (" + lvlWall$(INSTR("#NCKPG", c$)) + ")"
        CASE "/", "\" : g$ = "diagonal wall " + c$
        CASE "D" : g$ = "sliding door"
        CASE "H" : g$ = "shutter door"
        CASE "X" : g$ = "split door"
        CASE "R", "B", "Y" : g$ = MID$("red   blue  yellow", INSTR("RBY", c$) * 6 - 5, 6) : g$ = RTRIM$(g$) + " key door"
        CASE "E" : g$ = "the EXIT"
        CASE "!" : g$ = "sealed door (a data station opens it)"
        CASE "=" : g$ = "glass"
        CASE "@" : g$ = "data station"
        CASE "$" : g$ = "code terminal (a QB64 puzzle)"
        CASE "%" : g$ = "closet wall (secret)"
        CASE "&" : g$ = "teleporter pad (pairs: 1st-2nd, 3rd-4th...)"
        CASE "r", "b", "y" : g$ = RTRIM$(MID$("red   blue  yellow", INSTR("rby", c$) * 6 - 5, 6)) + " keycard"
        CASE "+" : g$ = "health pack"
        CASE "*" : g$ = "big medkit"
        CASE "u" : g$ = "armour"
        CASE "a" : g$ = "energy cells"
        CASE "e" : g$ = "shells"
        CASE "2" : g$ = "scatter gun"
        CASE "3" : g$ = "repeater"
        CASE "4" : g$ = "railgun"
        CASE "M" : g$ = "the map"
        CASE "q" : g$ = "overcharge"
        CASE "j" : g$ = "damage amp"
        CASE "m", "g", "h", "c", "s", "k", "w", "z", "T" : g$ = mtypeName$(INSTR("mghcskwzT", c$))
        CASE "<", ">", "^", "v" : g$ = "the START, facing " + c$
        CASE ELSE
            k = INSTR("oiptxlnfSdAFIJLOQUWZV", c$)
            IF k THEN g$ = RTRIM$(MID$("barrel     lamp       plant      terminal   crate      server rackvending    coolant    spawner    desk       console    screens    specimen   lab bench  generator  cryo pod   hologram   lockers    bench      chair      body       ", k * 11 - 10, 11)) ELSE g$ = "?"
    END SELECT
    GlyphName$ = g$
END FUNCTION

' Its colour on the editor's map
FUNCTION GlyphColor~&(c$)
    SELECT CASE c$
        CASE "." : col~& = _RGB32(28, 30, 48)
        CASE "#", "N", "C", "K", "P", "G"
            k = INSTR("#NCKPG", c$) : IF k = 1 THEN col~& = wallMapColor(1) ELSE col~& = wallMapColor(k + 1)
        CASE "/", "\" : col~& = _RGB32(150, 150, 170)
        CASE "D", "H", "X" : col~& = _RGB32(255, 140, 20)
        CASE "R" : col~& = _RGB32(255, 50, 50)
        CASE "B" : col~& = _RGB32(60, 110, 255)
        CASE "Y" : col~& = _RGB32(255, 230, 40)
        CASE "E" : col~& = _RGB32(60, 255, 120)
        CASE "!" : col~& = _RGB32(255, 200, 40)
        CASE "=" : col~& = _RGB32(130, 220, 255)
        CASE "@" : col~& = _RGB32(60, 240, 255)
        CASE "$" : col~& = _RGB32(90, 255, 120)
        CASE "%" : col~& = _RGB32(120, 90, 60)
        CASE "&" : col~& = _RGB32(190, 110, 255)
        CASE "<", ">", "^", "v" : col~& = _RGB32(255, 255, 255)
        CASE ELSE
            IF INSTR("rby+*uae234Mqj", c$) THEN col~& = _RGB32(80, 230, 120)
            IF INSTR("mghcskwzT", c$) THEN col~& = _RGB32(255, 70, 90)
            IF INSTR("oiptxlnfSdAFIJLOQUWZV", c$) THEN col~& = _RGB32(230, 200, 90)
    END SELECT
    GlyphColor~& = col~&
END FUNCTION

' Which entry of the palette is at screen point (mx, my) (0: none)
FUNCTION EditPaletteAt(mx, my)
    IF mx < ED_PALX OR my < ED_PALY THEN EXIT FUNCTION
    col = (mx - ED_PALX) \ 22 : row = (my - ED_PALY) \ 22
    IF col > 7 THEN EXIT FUNCTION
    k = row * 8 + col + 1
    IF k <= LEN(EDIT_GLYPHS) THEN EditPaletteAt = k
END FUNCTION

' The editor's map from above: every cell its colour, things a dot in
' theirs, the lights (and their reach, on the light layer), the event
' rooms' outlines, you - and the palette, and what's under the mouse
SUB DrawEditor(hx, hy, onMap, rectOn, rx, ry, px, py, fx, fy, lev, lname$)
    LINE (0, 0)-(799, 599), _RGB32(10, 8, 22), BF
    FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
        c$ = MID$(lvlRow$(y), x + 1, 1) : sx = ED_MAPX + x * ED_CELL : sy = ED_MAPY + y * ED_CELL
        IF INSTR("rby+*uae234MqjmghcskwzToiptxlnfSdAFIJLOQUWZV<>^v", c$) THEN
            LINE (sx, sy)-STEP(ED_CELL - 1, ED_CELL - 1), GlyphColor~&("."), BF
            LINE (sx + 3, sy + 3)-STEP(ED_CELL - 7, ED_CELL - 7), GlyphColor~&(c$), BF
            IF INSTR("<>^v", c$) THEN LINE (sx + 1, sy + 1)-STEP(ED_CELL - 3, ED_CELL - 3), _RGB32(255, 255, 255), B
        ELSEIF c$ = "/" THEN
            LINE (sx, sy)-STEP(ED_CELL - 1, ED_CELL - 1), GlyphColor~&("."), BF : LINE (sx, sy + ED_CELL - 1)-(sx + ED_CELL - 1, sy), GlyphColor~&(c$)
        ELSEIF c$ = "\" THEN
            LINE (sx, sy)-STEP(ED_CELL - 1, ED_CELL - 1), GlyphColor~&("."), BF : LINE (sx, sy)-(sx + ED_CELL - 1, sy + ED_CELL - 1), GlyphColor~&(c$)
        ELSE
            LINE (sx, sy)-STEP(ED_CELL - 1, ED_CELL - 1), GlyphColor~&(c$), BF
        END IF
    NEXT : NEXT
    IF edGrid THEN ' The grid: every cell's edge, as strong as it's set (G, Shift+G)
        FOR k = 0 TO MAP_SIZE
            LINE (ED_MAPX + k * ED_CELL, ED_MAPY)-(ED_MAPX + k * ED_CELL, ED_MAPY + MAP_SIZE * ED_CELL), _RGBA32(90, 230, 255, edGridAlpha \ 2)
            LINE (ED_MAPX, ED_MAPY + k * ED_CELL)-(ED_MAPX + MAP_SIZE * ED_CELL, ED_MAPY + k * ED_CELL), _RGBA32(90, 230, 255, edGridAlpha \ 2)
        NEXT
    END IF
    ' The heights layer: each floor shaded by its height (and its number in
    ' eighths), a ceiling that isn't the usual a dot in the corner
    IF editHeights THEN
        FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
            IF INSTR("#NCKPG", MID$(lvlRow$(y), x + 1, 1)) = 0 THEN
                fh = HeightOf(MID$(lvlFloorRow$(y), x + 1, 1), 0) : ch = HeightOf(MID$(lvlCeilRow$(y), x + 1, 1), 1)
                sx = ED_MAPX + x * ED_CELL : sy = ED_MAPY + y * ED_CELL
                IF fh <> 0 THEN
                    k = 120 + fh * 90 : IF k > 255 THEN k = 255
                    IF k < 20 THEN k = 20
                    IF fh > 0 THEN LINE (sx + 1, sy + 1)-STEP(ED_CELL - 3, ED_CELL - 3), _RGB32(k, k * 0.8, 40), BF ELSE LINE (sx + 1, sy + 1)-STEP(ED_CELL - 3, ED_CELL - 3), _RGB32(40, 20, 80 + (1 + fh) * 100), BF
                END IF
                IF ch <> 1 THEN PSET (sx + ED_CELL - 3, sy + 2), _RGB32(120, 220, 255) : PSET (sx + ED_CELL - 4, sy + 2), _RGB32(120, 220, 255)
            END IF
        NEXT : NEXT
        FOR k = 1 TO lvlNumLifts ' (the lifts, outlined)
            LINE (ED_MAPX + MinOf(lvlLift(k, 1), lvlLift(k, 3)) * ED_CELL, ED_MAPY + MinOf(lvlLift(k, 2), lvlLift(k, 4)) * ED_CELL)-(ED_MAPX + (MaxOf(lvlLift(k, 1), lvlLift(k, 3)) + 1) * ED_CELL - 1, ED_MAPY + (MaxOf(lvlLift(k, 2), lvlLift(k, 4)) + 1) * ED_CELL - 1), _RGB32(120, 255, 120), B
        NEXT
    END IF
    ' The triggers' places, outlined in orange (a use: its cell)
    FOR k = 1 TO numTrigs
        LINE (ED_MAPX + trigX0(k) * ED_CELL + 1, ED_MAPY + trigY0(k) * ED_CELL + 1)-(ED_MAPX + (trigX1(k) + 1) * ED_CELL - 2, ED_MAPY + (trigY1(k) + 1) * ED_CELL - 2), _RGBA32(255, 160, 40, 200), B
    NEXT
    ' The event rooms, outlined
    FOR k = 1 TO lvlNumEvents
        LINE (ED_MAPX + lvlEvent(k, 2) * ED_CELL, ED_MAPY + lvlEvent(k, 3) * ED_CELL)-(ED_MAPX + (lvlEvent(k, 4) + 1) * ED_CELL - 1, ED_MAPY + (lvlEvent(k, 5) + 1) * ED_CELL - 1), _RGBA32(255, 80, 200, 150), B
    NEXT
    ' The lights
    FOR k = 1 TO lvlNumLights
        lx = ED_MAPX + lvlLight(k, 1) * ED_CELL : ly = ED_MAPY + lvlLight(k, 2) * ED_CELL
        lc~& = _RGB32(lvlLight(k, 5), lvlLight(k, 6), lvlLight(k, 7))
        IF editLights THEN CIRCLE (lx, ly), lvlLight(k, 3) * ED_CELL, _RGBA32(lvlLight(k, 5), lvlLight(k, 6), lvlLight(k, 7), 90)
        CIRCLE (lx, ly), 3, lc~& : PSET (lx, ly), _RGB32(255, 255, 255)
    NEXT
    ' You
    ax = ED_MAPX + px * ED_CELL : ay = ED_MAPY + py * ED_CELL
    LINE (ax, ay)-(ax + fx * ED_CELL * 1.6, ay + fy * ED_CELL * 1.6), _RGB32(255, 255, 0)
    CIRCLE (ax, ay), ED_CELL \ 3, _RGB32(255, 255, 0)
    ' The cursor (and a rectangle being dragged)
    IF onMap THEN
        IF rectOn THEN
            LINE (ED_MAPX + MinOf(rx, hx) * ED_CELL, ED_MAPY + MinOf(ry, hy) * ED_CELL)-(ED_MAPX + (MaxOf(rx, hx) + 1) * ED_CELL - 1, ED_MAPY + (MaxOf(ry, hy) + 1) * ED_CELL - 1), _RGB32(255, 255, 255), B
        ELSE
            LINE (ED_MAPX + hx * ED_CELL - 1, ED_MAPY + hy * ED_CELL - 1)-STEP(ED_CELL + 1, ED_CELL + 1), _RGB32(255, 255, 255), B
        END IF
    END IF
    ' The palette, two-and-a-bit columns of glyphs on the right
    COLOR _RGB32(255, 90, 200) : _PRINTSTRING (ED_PALX, 4), "LEVEL EDITOR"
    shortName$ = lname$ : c = INSTR(lname$, ": ") : IF c THEN shortName$ = MID$(lname$, c + 2) ' ("SECTOR 1: NEON STATION" - just its name)
    COLOR _RGB32(170, 160, 210) : _PRINTSTRING (ED_PALX, 22), LEFT$("Sector" + STR$(lev) + ": " + shortName$, 24)
    FOR k = 1 TO LEN(EDIT_GLYPHS)
        c$ = MID$(EDIT_GLYPHS, k, 1)
        sx = ED_PALX + ((k - 1) MOD 8) * 22 : sy = ED_PALY + ((k - 1) \ 8) * 22
        LINE (sx, sy)-STEP(19, 19), GlyphColor~&(c$), BF
        IF INSTR("rby+*uae234MqjmghcskwzToiptxlnfSdAFIJLOQUWZV.", c$) THEN COLOR _RGB32(255, 255, 255) ELSE COLOR _RGB32(0, 0, 0)
        _PRINTSTRING (sx + 6, sy + 2), c$
        IF c$ = editGlyph$ THEN LINE (sx - 2, sy - 2)-STEP(23, 23), _RGB32(255, 255, 255), B : LINE (sx - 3, sy - 3)-STEP(25, 25), _RGB32(255, 60, 200), B
    NEXT
    y = ED_PALY + ((LEN(EDIT_GLYPHS) - 1) \ 8 + 1) * 22 + 6
    COLOR _RGB32(255, 255, 255) : _PRINTSTRING (ED_PALX, y), LEFT$(GlyphName$(editGlyph$), 24)
    IF editLights THEN COLOR _RGB32(255, 220, 120) : _PRINTSTRING (ED_PALX, y + 18), "LIGHTS: " + LightPresetName$(editLightP)
    IF editHeights THEN COLOR _RGB32(255, 220, 120) : _PRINTSTRING (ED_PALX, y + 18), "HEIGHTS: click up, right down"
    
    COLOR _RGB32(140, 130, 180) : _PRINTSTRING (ED_PALX, 552), "HELP / F1: every key"
    ' Along the bottom: the cell under the mouse, and the latest message
    IF onMap THEN
        c$ = MID$(lvlRow$(hy), hx + 1, 1)
        h$ = "" : IF HeightOf(MID$(lvlFloorRow$(hy), hx + 1, 1), 0) <> 0 OR HeightOf(MID$(lvlCeilRow$(hy), hx + 1, 1), 1) <> 1 THEN h$ = "  floor" + STR$(HeightOf(MID$(lvlFloorRow$(hy), hx + 1, 1), 0)) + " ceil" + STR$(HeightOf(MID$(lvlCeilRow$(hy), hx + 1, 1), 1))
        COLOR _RGB32(200, 200, 230) : _PRINTSTRING (ED_MAPX, 584), LEFT$(LTRIM$(STR$(hx)) + "," + LTRIM$(STR$(hy)) + "  " + GlyphName$(c$) + h$, 40)
    END IF
    IF TIMER < editMsgUntil! THEN COLOR _RGB32(255, 220, 120) : _PRINTSTRING (330, 584), LEFT$(editMsg$, 58)
    IF editDirty THEN COLOR _RGB32(255, 90, 90) : _PRINTSTRING (ED_PALX, 584), "* not saved"
    EditDrawSelMap ' (the selection - the same one the 3D view has)
END SUB

' Walking round in the editor: what's under the crosshair, the glyph you'd
' place, and the latest message
' --- THE 3D EDITOR'S POINTER (chapter 21). A point on the screen is a ray
' into the world: the same sums that put the world on the screen, run
' backwards. Across, the camera plane (chapter 8) - so many cells right
' for each cell ahead; up, half a wall per cell ahead at the top edge
' (chapter 15's viewH); then tilted by how far you look up or down (OpenGL
' only - chapter 24). EditPick follows that ray cell by cell through the
' map, the way the walls are found (chapter 15) but in 3D: in each open
' cell, does it go down through the floor or up through the ceiling before
' it leaves? Leaving, does it hit a wall, the face of a step up, or a
' ceiling stepping down? The first face it meets is edHov...: its kind
' (ED_), the cell it belongs to, which side (1 east, 2 south, 3 west, 4
' north) and the point it was hit.
SUB EditRay(sx, sy, rdx, rdy, rdz)
    ndcX = sx / 400 - 1 : ndcY = 1 - sy / 300
    ak = 1 : IF glMode THEN ak = glAspectK
    r = ndcX * edCamPlane * ak : u = ndcY / (2 * edCamZoom)
    c = COS(pitch) : sn = SIN(pitch)
    rdx = r * edCamDY - u * sn * edCamDX + c * edCamDX
    rdy = -r * edCamDX - u * sn * edCamDY + c * edCamDY
    rdz = u * c + sn
END SUB

SUB EditPick(sx, sy)
    edHovKind = 0
    EditRay sx, sy, rdx, rdy, rdz
    ex = edCamPX : ey = edCamPY : ez = eyeZ
    mx = INT(ex) : my = INT(ey)
    IF rdx = 0 THEN rdx = 0.00001
    IF rdy = 0 THEN rdy = 0.00001
    ddx = ABS(1 / rdx) : ddy = ABS(1 / rdy)
    IF rdx < 0 THEN stx = -1 : sdx = (ex - mx) * ddx ELSE stx = 1 : sdx = (mx + 1 - ex) * ddx
    IF rdy < 0 THEN sty = -1 : sdy = (ey - my) * ddy ELSE sty = 1 : sdy = (my + 1 - ey) * ddy
    tIn = 0
    FOR stepN = 1 TO 90
        IF mx < 0 OR my < 0 OR mx >= MAP_SIZE OR my >= MAP_SIZE THEN EXIT SUB
        IF sdx < sdy THEN tOut = sdx ELSE tOut = sdy
        IF worldMap(mx, my) <= 0 THEN ' An open cell: through its floor or ceiling, on the way across?
            f = floorH(mx, my) : cz = ceilH(mx, my) : zOut = ez + rdz * tOut
            IF rdz < 0 AND zOut < f THEN
                t = (f - ez) / rdz
                IF t >= tIn - 0.001 THEN EditHit ED_FLOOR, mx, my, 0, ex + rdx * t, ey + rdy * t, f : EXIT SUB
            END IF
            IF rdz > 0 AND zOut > cz THEN
                t = (cz - ez) / rdz
                IF t >= tIn - 0.001 THEN EditHit ED_CEIL, mx, my, 0, ex + rdx * t, ey + rdy * t, cz : EXIT SUB
            END IF
        END IF
        ' On to the next cell, across its edge
        IF sdx < sdy THEN
            sdx = sdx + ddx : nx = mx + stx : ny = my : IF stx > 0 THEN side = 3 ELSE side = 1 ' (the new cell's side we came in by)
        ELSE
            sdy = sdy + ddy : nx = mx : ny = my + sty : IF sty > 0 THEN side = 4 ELSE side = 2
        END IF
        IF nx < 0 OR ny < 0 OR nx >= MAP_SIZE OR ny >= MAP_SIZE THEN EXIT SUB
        zOut = ez + rdz * tOut : hx = ex + rdx * tOut : hy = ey + rdy * tOut
        IF worldMap(mx, my) <= 0 THEN ' (from an open cell - a face is only a face seen from the open side)
            IF worldMap(nx, ny) > 0 THEN
                EditHit ED_WALL, nx, ny, side, hx, hy, zOut : EXIT SUB
            ELSEIF zOut < floorH(nx, ny) THEN
                EditHit ED_STEP, nx, ny, side, hx, hy, zOut : EXIT SUB
            ELSEIF zOut > ceilH(nx, ny) THEN
                EditHit ED_LINTEL, nx, ny, side, hx, hy, zOut : EXIT SUB
            END IF
        END IF
        mx = nx : my = ny : tIn = tOut
    NEXT
END SUB

' THE SELECTION: faces, by kind, cell, side and part. EditSelToggle puts
' one in (or takes it out, if it's there); EditSelFlood takes every floor
' (or ceiling) cell joined to (x, y) at the same height - a room's floor in
' one click. Nothing needs them in order.
FUNCTION EditSelIndex(kind, x, y, side, part)
    FOR k = 1 TO edSelN
        IF edSelKind(k) = kind AND edSelX(k) = x AND edSelY(k) = y AND edSelSide(k) = side AND edSelPart(k) = part THEN EditSelIndex = k : EXIT FUNCTION
    NEXT
END FUNCTION

SUB EditSelToggle(kind, x, y, side, part)
    k = EditSelIndex(kind, x, y, side, part)
    IF k THEN ' (there: out it goes - the last one moved into its place)
        edSelKind(k) = edSelKind(edSelN) : edSelX(k) = edSelX(edSelN) : edSelY(k) = edSelY(edSelN)
        edSelSide(k) = edSelSide(edSelN) : edSelPart(k) = edSelPart(edSelN) : edSelN = edSelN - 1
    ELSEIF edSelN < ED_MAXSEL THEN
        edSelN = edSelN + 1 : edSelKind(edSelN) = kind : edSelX(edSelN) = x : edSelY(edSelN) = y
        edSelSide(edSelN) = side : edSelPart(edSelN) = part
    END IF
END SUB

SUB EditSelFlood(kind, x0, y0)
    DIM qx(MAP_SIZE * MAP_SIZE) AS INTEGER, qy(MAP_SIZE * MAP_SIZE) AS INTEGER, seen(MAP_SIZE, MAP_SIZE) AS INTEGER
    IF kind = ED_FLOOR THEN h = floorH(x0, y0) ELSE h = ceilH(x0, y0)
    edSelN = 0 : qn = 1 : qx(1) = x0 : qy(1) = y0 : seen(x0, y0) = -1 : qi = 0
    DO WHILE qi < qn AND edSelN < ED_MAXSEL
        qi = qi + 1 : x = qx(qi) : y = qy(qi)
        EditSelToggle kind, x, y, 0, 0
        FOR d = 0 TO 3
            nx = x + (d = 0) - (d = 1) : ny = y + (d = 2) - (d = 3)
            IF nx >= 0 AND ny >= 0 AND nx < MAP_SIZE AND ny < MAP_SIZE THEN
                IF NOT seen(nx, ny) AND worldMap(nx, ny) <= 0 THEN
                    IF kind = ED_FLOOR THEN hh = floorH(nx, ny) ELSE hh = ceilH(nx, ny)
                    IF ABS(hh - h) < 0.001 THEN seen(nx, ny) = -1 : qn = qn + 1 : qx(qn) = nx : qy(qn) = ny
                END IF
            END IF
        NEXT
    LOOP
END SUB

' Is the screen point (x, y) on the editor's own buttons and panels? (Then
' a click there is for them, not for picking a face - or the wheel.)
FUNCTION EditOverUI(x, y)
    EditOverUI = 0
    IF edHelp THEN EditOverUI = -1 : EXIT FUNCTION ' (the help is up: a click closes it)
    IF EditTBAt(x, y, editView) THEN EditOverUI = -1
    IF editView = 1 AND edPickOn AND y >= PK_Y - 4 THEN EditOverUI = -1 ' (the picker: the bottom of the screen)
END FUNCTION

' --- THE TOOLBAR: the editor's buttons, in both views - along the top in
' 3D (v = 1), in the panel on the right of the map from above (v = 0).
' Each button is a TB_ number, a place and a size, worked out here (and
' asked again whenever they're drawn or clicked, so they're never stale).
' The order: the tools, then what you do to the level, then the grid and
' how strong it is (a slider), then the other view and the help. In the
' order string a | is a gap between groups, a / a new row.
SUB EditTBLayout(v)
    IF v = 1 THEN o$ = "SPTLH|DUW|GA|KVQ" : x = 8 : y = 4 ELSE o$ = "SPL/HDU/WVQ/GA" : x = ED_PALX : y = 296
    x0 = x : edTbN = 0
    FOR k = 1 TO LEN(o$)
        c$ = MID$(o$, k, 1)
        IF c$ = "|" THEN
            x = x + 8
        ELSEIF c$ = "/" THEN
            x = x0 : y = y + 24
        ELSE
            id = INSTR("SPLHDUWGAVQTK", c$)
            IF v = 1 THEN w = LEN(EditTBLabel$(id)) * 8 + 10 ELSE w = 64
            IF id = TB_ALPHA THEN w = 72 : IF v = 0 THEN w = 132
            edTbN = edTbN + 1 : edTbId(edTbN) = id : edTbX(edTbN) = x : edTbY(edTbN) = y : edTbW(edTbN) = w : edTbH(edTbN) = 20
            x = x + w + 3 : IF v = 0 THEN x = x + 1
        END IF
    NEXT
END SUB

FUNCTION EditTBLabel$(id)
    SELECT CASE id
        CASE TB_SELECT : t$ = "SELECT"
        CASE TB_PLACE : t$ = "PLACE"
        CASE TB_LIGHT : t$ = "LIGHT"
        CASE TB_HEIGHT : t$ = "HEIGHT"
        CASE TB_DELETE : t$ = "DELETE"
        CASE TB_UNDO : t$ = "UNDO"
        CASE TB_SAVE : t$ = "SAVE"
        CASE TB_GRID : t$ = "GRID"
        CASE TB_VIEW : IF editView = 1 THEN t$ = "2D MAP" ELSE t$ = "3D"
        CASE TB_HELP : t$ = "HELP"
        CASE TB_PAINT : t$ = "PAINT"
        CASE TB_PICK : t$ = "PICKER"
    END SELECT
    EditTBLabel$ = t$
END FUNCTION

' What a button does, said when the pointer is over it (with its key)
FUNCTION EditTBTip$(id)
    SELECT CASE id
        CASE TB_SELECT : IF editView = 1 THEN t$ = "Select: click a face - Shift adds, Ctrl a whole floor" ELSE t$ = "Select: click a cell or drag a box - Shift adds"
        CASE TB_PLACE : IF editView = 1 THEN t$ = "Place: click to put " + GlyphName$(editGlyph$) + " there ([ ] change)" ELSE t$ = "Place: paint " + GlyphName$(editGlyph$) + " - Shift+drag a box"
        CASE TB_LIGHT : t$ = "Light: click adds a light (1-8 colour), Shift+click takes one"
        CASE TB_HEIGHT : t$ = "Height: click raises a floor/ceiling, Shift+click lowers"
        CASE TB_DELETE : t$ = "Delete the selection: walls opened, things gone (Del)"
        CASE TB_UNDO : t$ = "Undo (Ctrl+Z)"
        CASE TB_SAVE : t$ = "Save the sector to its file (Ctrl+S)"
        CASE TB_GRID : t$ = "The grid over the world on/off (G)"
        CASE TB_ALPHA : t$ = "How strong the grid is: drag (Shift+G)"
        CASE TB_VIEW : IF editView = 1 THEN t$ = "The map from above (Tab)" ELSE t$ = "Walk round inside it (Tab)"
        CASE TB_HELP : t$ = "Every key and click (F1)"
        CASE TB_PAINT : t$ = "Paint: click a face to give it the brush's picture"
        CASE TB_PICK : t$ = "The picker: walls, floors, things... (P)"
    END SELECT
    EditTBTip$ = t$
END FUNCTION

' The button at (x, y) in view v - its TB_ number - or 0
FUNCTION EditTBAt(x, y, v)
    EditTBAt = 0
    EditTBLayout v
    FOR k = 1 TO edTbN
        IF x >= edTbX(k) AND y >= edTbY(k) AND x < edTbX(k) + edTbW(k) AND y < edTbY(k) + edTbH(k) THEN EditTBAt = edTbId(k) : EXIT FUNCTION
    NEXT
END FUNCTION

' Is button id lit - the tool in use, the grid on, the help up?
FUNCTION EditTBOn(id)
    SELECT CASE id
        CASE TB_SELECT : EditTBOn = (edTool = ET_SELECT)
        CASE TB_PLACE : EditTBOn = (edTool = ET_PLACE)
        CASE TB_LIGHT : EditTBOn = (edTool = ET_LIGHT)
        CASE TB_HEIGHT : EditTBOn = (edTool = ET_HEIGHT)
        CASE TB_GRID : EditTBOn = edGrid
        CASE TB_HELP : EditTBOn = edHelp
        CASE TB_PAINT : EditTBOn = (edTool = ET_PAINT)
        CASE TB_PICK : EditTBOn = edPickOn
        CASE ELSE : EditTBOn = 0
    END SELECT
END FUNCTION

' Draw the toolbar for view v, the pointer at (mx, my): lit buttons in
' magenta, the one under the pointer brighter, and what it does under it
SUB EditDrawTB(v, mx, my)
    EditTBLayout v
    IF v = 1 THEN LINE (0, 0)-(799, 27), _RGBA32(6, 2, 18, 190), BF : LINE (0, 28)-(799, 28), _RGBA32(255, 60, 200, 120)
    hov = 0
    FOR k = 1 TO edTbN
        id = edTbId(k) : x = edTbX(k) : y = edTbY(k) : w = edTbW(k) : h = edTbH(k)
        over = (mx >= x AND my >= y AND mx < x + w AND my < y + h) : IF over THEN hov = k
        IF id = TB_ALPHA THEN ' The slider: filled as far as the grid is strong
            LINE (x, y)-STEP(w - 1, h - 1), _RGBA32(14, 6, 30, 230), BF
            f = (w - 4) * edGridAlpha / 255
            IF edGrid THEN fc~& = _RGBA32(90, 230, 255, 170) ELSE fc~& = _RGBA32(90, 120, 160, 110)
            LINE (x + 2, y + 2)-STEP(f, h - 5), fc~&, BF
            LINE (x + 2 + f, y)-STEP(1, h - 1), _RGB32(255, 255, 255), BF
            IF over OR edTbDrag THEN bc~& = _RGB32(150, 240, 255) ELSE bc~& = _RGB32(90, 70, 140)
            LINE (x, y)-STEP(w - 1, h - 1), bc~&, B
            t$ = LTRIM$(STR$(INT(edGridAlpha * 100 / 255 + 0.5))) + "%"
            HudText x + (w - LEN(t$) * 8) \ 2, y + 2, t$, _RGB32(255, 255, 255)
        ELSE
            lit = EditTBOn(id)
            IF lit THEN bg~& = _RGBA32(120, 20, 100, 230) ELSE bg~& = _RGBA32(14, 6, 30, 230)
            IF over THEN bg~& = _RGBA32(40, 70, 110, 240)
            LINE (x, y)-STEP(w - 1, h - 1), bg~&, BF
            IF lit THEN bc~& = _RGB32(255, 60, 200) ELSE bc~& = _RGB32(90, 70, 140)
            IF over THEN bc~& = _RGB32(150, 240, 255)
            LINE (x, y)-STEP(w - 1, h - 1), bc~&, B
            t$ = EditTBLabel$(id)
            IF lit OR over THEN tc~& = _RGB32(255, 255, 255) ELSE tc~& = _RGB32(200, 190, 240)
            HudText x + (w - LEN(t$) * 8) \ 2, y + 2, t$, tc~&
        END IF
    NEXT
    ' What the one under the pointer does
    IF hov THEN
        t$ = EditTBTip$(edTbId(hov))
        IF v = 1 THEN
            tx = edTbX(hov) : IF tx + LEN(t$) * 8 + 8 > 796 THEN tx = 796 - LEN(t$) * 8 - 8
            LINE (tx, 32)-STEP(LEN(t$) * 8 + 8, 19), _RGBA32(0, 0, 0, 220), BF
            HudText tx + 4, 34, t$, _RGB32(150, 240, 255)
        ELSE
            ty = 400
            DO WHILE LEN(t$) ' (the panel's narrow: in lines of 25)
                l$ = LEFT$(t$, 25)
                IF LEN(t$) > 25 THEN sp = _INSTRREV(l$, " ") : IF sp > 8 THEN l$ = LEFT$(t$, sp - 1)
                HudText ED_PALX, ty, l$, _RGB32(150, 240, 255) : ty = ty + 16 : t$ = LTRIM$(MID$(t$, LEN(l$) + 1))
            LOOP
        END IF
    END IF
END SUB

' The help: every key and click for the view you're in, on a panel over it
' (HELP, F1 - and H in 3D); a click anywhere puts it away
SUB EditDrawHelp(v)
    IF v = 1 THEN
        h$ = "THE 3D EDITOR|"
        h$ = h$ + "Mouse: point at a face;  hold Right: look round|"
        h$ = h$ + "Move as you'd walk; Space flies up, C down (Shift: faster)|"
        h$ = h$ + "|"
        h$ = h$ + "SELECT  click a face; Shift+click adds or takes it out;|"
        h$ = h$ + "        Ctrl+click: the whole floor/ceiling; Ctrl+D: none|"
        h$ = h$ + "PLACE   click: the brush there ([ ] change it, E pick up)|"
        h$ = h$ + "LIGHT   click: a light there (1-8 colour); Shift+click: away|"
        h$ = h$ + "HEIGHT  click raises a floor/ceiling an eighth; Shift lowers|"
        h$ = h$ + "PAINT   click: the brush's picture on that face; Ctrl+click:|"
        h$ = h$ + "        the whole floor/ceiling; Shift+click: the usual again|"
        h$ = h$ + "PICKER (P): a tab, then a picture - it's the brush (and the|"
        h$ = h$ + "        selection's, if any); the wheel scrolls it|"
        h$ = h$ + "Wheel: the selection (or face under the pointer) up/down|"
        h$ = h$ + "  an eighth; Ctrl: a whole wall high|"
        h$ = h$ + "Wall + Shift+wheel: pull it out / push it back a cell|"
        h$ = h$ + "Wall + Ctrl+Shift+wheel: a block on the floor (its top)|"
        h$ = h$ + "Wall + Alt+Shift+wheel: a block from the ceiling (bottom)|"
        h$ = h$ + "Arrows: move the selection a cell;  Del: delete it|"
        h$ = h$ + "G grid, Shift+G stronger;  T F V pictures;  Z floor no.|"
        h$ = h$ + "L K light here/away;  PgUp/PgDn floor (Shift: ceiling)|"
        h$ = h$ + "Tab map;  U HUD layout;  Ctrl+S save;  Ctrl+Z undo;  F2 play"
    ELSE
        h$ = "THE MAP FROM ABOVE|"
        h$ = h$ + "|"
        h$ = h$ + "SELECT  click a cell, drag a box; Shift adds; Ctrl+D: none|"
        h$ = h$ + "PLACE   click/drag paints the brush; Shift+drag a box;|"
        h$ = h$ + "        right-click picks up what's there|"
        h$ = h$ + "LIGHT   click adds a light (1-8 colour); right-click: away|"
        h$ = h$ + "HEIGHT  click raises the floor, right-click lowers it;|"
        h$ = h$ + "        with Shift: the ceiling|"
        h$ = h$ + "|"
        h$ = h$ + "Wheel or [ ]: the brush;  the palette: click one|"
        h$ = h$ + "Arrows: move the selection a cell;  Del: delete it|"
        h$ = h$ + "G grid, Shift+G stronger;  T: put you here|"
        h$ = h$ + "M monsters;  U HUD layout;  PgUp/PgDn: other sectors|"
        h$ = h$ + "Tab: walk in it;  Ctrl+S save;  Ctrl+Z undo;  F2 play"
    END IF
    n = 1 : FOR k = 1 TO LEN(h$) : IF MID$(h$, k, 1) = "|" THEN n = n + 1
    NEXT
    y0 = 300 - (n * 18 + 36) \ 2
    LINE (110, y0)-(690, y0 + n * 18 + 36), _RGBA32(6, 2, 18, 235), BF
    LINE (110, y0)-(690, y0 + n * 18 + 36), _RGB32(255, 60, 200), B
    y = y0 + 12 : first = -1
    DO WHILE LEN(h$)
        bar = INSTR(h$, "|") : IF bar = 0 THEN bar = LEN(h$) + 1
        IF first THEN c~& = _RGB32(255, 90, 200) ELSE c~& = _RGB32(210, 220, 255)
        HudText 126, y, LEFT$(h$, bar - 1), c~& : y = y + 18 : h$ = MID$(h$, bar + 1) : first = 0
    LOOP
    HudText 126, y + 4, "(click anywhere to close)", _RGB32(140, 130, 180)
END SUB

' --- THE PICKER: along the bottom of the 3D view, a tab for each kind of
' thing (WALLS... LIGHTS), and under it the tab's things as pictures, two
' rows of eight at a time - the wheel (or the arrows beside them) scrolls.
' Click one and it's the brush: PLACE puts a map character, PAINT paints a
' picture, LIGHT lights - and if something's selected, it's done to the
' selection there and then.
FUNCTION EditPkTabName$(t)
    EditPkTabName$ = RTRIM$(MID$("WALLS    FLOORS   CEILINGS DOORS    ITEMS    MONSTERS DECOR    SPECIAL  LIGHTS   ", t * 9 - 8, 9))
END FUNCTION

' The tab's entries, and their thumbnails - made again only when the tab,
' the level, its wall pictures or ART have changed
SUB EditPkBuild
    key$ = STR$(edPickTab) + STR$(level) + STR$(artNow) + lvlWall$(1) + lvlWall$(2) + lvlWall$(3) + lvlWall$(4) + lvlWall$(5) + lvlWall$(6)
    IF key$ = edPkKey$ THEN EXIT SUB
    edPkKey$ = key$
    FOR k = 1 TO edPkN
        IF edPkImg&(k) < -1 THEN _FREEIMAGE edPkImg&(k)
        edPkImg&(k) = 0
    NEXT
    edPkN = 0
    SELECT CASE edPickTab
        CASE 1 : g$ = "#NCKPG/\%=" : pre$ = "wall"
        CASE 2 : pre$ = "floor"
        CASE 3 : pre$ = "ceiling"
        CASE 4 : g$ = "DHXRBY!E"
        CASE 5 : g$ = "rby+*uae234Mqj"
        CASE 6 : g$ = "mghcskwzT"
        CASE 7 : g$ = "oiptxlnfSdAFIJLOQUWZV"
        CASE 8 : g$ = "<>^v&@$."
    END SELECT
    FOR k = 1 TO LEN(g$)
        edPkN = edPkN + 1 : edPkKind(edPkN) = PK_GLYPH : edPkVal$(edPkN) = MID$(g$, k, 1) : edPkImg&(edPkN) = EditGlyphThumb&(MID$(g$, k, 1))
    NEXT
    IF LEN(pre$) THEN ' Every picture called wall*.png (floor*, ceiling*), in name order
        dir$ = AssetPath$("x") : dir$ = LEFT$(dir$, LEN(dir$) - 1)
        first = edPkN + 1
        f$ = _FILES$(dir$ + pre$ + "*.png")
        DO WHILE LEN(f$) AND edPkN < PK_MAX
            b$ = f$ : sl = _INSTRREV(b$, "/") : IF sl THEN b$ = MID$(b$, sl + 1)
            IF b$ <> "wall-jack.png" AND b$ <> "wall-code.png" AND b$ <> "ceiling-lamp.png" THEN edPkN = edPkN + 1 : edPkKind(edPkN) = PK_TEX : edPkVal$(edPkN) = b$
            f$ = _FILES$
        LOOP
        FOR a = first TO edPkN - 1 : FOR b = a + 1 TO edPkN
            IF LCASE$(edPkVal$(b)) < LCASE$(edPkVal$(a)) THEN SWAP edPkVal$(a), edPkVal$(b)
        NEXT : NEXT
        FOR k = first TO edPkN : edPkImg&(k) = EditFileThumb&(edPkVal$(k)) : NEXT
    END IF
    IF edPickTab = 9 THEN
        FOR k = 0 TO 7 : edPkN = edPkN + 1 : edPkKind(edPkN) = PK_LIGHT : edPkVal$(edPkN) = LTRIM$(STR$(k)) : edPkImg&(edPkN) = 0 : NEXT
    END IF
    IF edPickScroll > MaxOf(0, (edPkN - 1) \ PK_COLS - PK_ROWS + 1) THEN edPickScroll = 0
END SUB

' A thumbnail (PK_SIZE - 4 square) of a texture slot (spr = 0) or a sprite
' slot (spr = -1), from the pictures the game's already loaded
FUNCTION EditSlotThumb&(slot, spr)
    n = PK_SIZE - 4 : img& = _NEWIMAGE(n, n, 32) : d& = _DEST
    IF spr THEN ts = spriteSize(slot) : IF ts <= 0 THEN ts = sprTex
    IF NOT spr THEN ts = texSize
    _DEST img& : _DONTBLEND img&
    FOR y = 0 TO n - 1 : FOR x = 0 TO n - 1
        IF spr THEN PSET (x, y), spriteTex(x * ts \ n, y * ts \ n, slot) ELSE PSET (x, y), texture(x * ts \ n, y * ts \ n, slot)
    NEXT : NEXT
    _BLEND img& : _DEST d&
    EditSlotThumb& = img&
END FUNCTION

' A thumbnail of a picture file (wall-*.png...): loaded, shrunk
FUNCTION EditFileThumb&(f$)
    EditFileThumb& = 0
    src& = _LOADIMAGE(ArtPath$(f$), 32) : IF src& >= -1 THEN EXIT FUNCTION
    n = PK_SIZE - 4 : img& = _NEWIMAGE(n, n, 32)
    _PUTIMAGE (0, 0)-(n - 1, n - 1), src&, img&
    _FREEIMAGE src&
    EditFileThumb& = img&
END FUNCTION

' A map character's thumbnail: the picture it's drawn with in the game
' (a wall's or door's texture, a thing's sprite) - 0 for the start, drawn
' as an arrow instead
FUNCTION EditGlyphThumb&(c$)
    t = 0 : sp = 0
    SELECT CASE c$
        CASE "#", "N", "C", "K", "P", "G" : t = INSTR("#NCKPG", c$)
        CASE "/", "\", "%" : t = 1
        CASE "D", "!" : t = T_DOOR
        CASE "H" : t = T_SHUTTER
        CASE "X" : t = T_SPLIT
        CASE "R", "B", "Y" : t = T_DOORK + INSTR("RBY", c$)
        CASE "E" : t = T_EXIT
        CASE "@" : t = T_JACK
        CASE "$" : t = T_CODE
        CASE "." : t = T_FLOOR + 1
        CASE "=" : sp = S_GLASS
        CASE "&" : sp = S_PAD
        CASE "r", "b", "y" : sp = INSTR("rby", c$)
        CASE "+" : sp = 4
        CASE "*" : sp = 26
        CASE "u" : sp = 25
        CASE "a" : sp = 5
        CASE "e" : sp = 6
        CASE "2" : sp = 7
        CASE "3" : sp = 8
        CASE "4" : sp = 27
        CASE "M" : sp = 28
        CASE "q" : sp = ItemSprite(IT_OVERCHARGE)
        CASE "j" : sp = ItemSprite(IT_AMP)
        CASE ELSE
            k = INSTR("mghcskwzT", c$) : IF k THEN sp = mtypeSprite(k)
            k = INSTR("oiptxlnfSdAFIJLOQUWZV", c$) : IF k THEN sp = DecoSlot(k)
    END SELECT
    IF t THEN EditGlyphThumb& = EditSlotThumb&(t, 0) ELSE IF sp THEN EditGlyphThumb& = EditSlotThumb&(sp, -1) ELSE EditGlyphThumb& = 0
END FUNCTION

' A light preset's colour (1-8 in the editor: 0-7 here)
FUNCTION EditLightRGB~&(p)
    SELECT CASE p
        CASE 0 : c~& = _RGB32(230, 235, 255)
        CASE 1 : c~& = _RGB32(60, 220, 255)
        CASE 2 : c~& = _RGB32(255, 60, 220)
        CASE 3 : c~& = _RGB32(255, 160, 60)
        CASE 4 : c~& = _RGB32(90, 255, 120)
        CASE 5 : c~& = _RGB32(255, 40, 40)
        CASE 6 : c~& = _RGB32(220, 230, 255)
        CASE ELSE : c~& = _RGB32(255, 150, 70)
    END SELECT
    EditLightRGB~& = c~&
END FUNCTION

' What's at screen point (x, y) on the picker: what = 1 a tab (idx: which),
' 2 a thumbnail (idx: its entry), 3 scroll up, 4 scroll down; 0 nothing
SUB EditPkHit(x, y, what, idx)
    what = 0 : idx = 0
    IF NOT edPickOn OR editView <> 1 THEN EXIT SUB
    tx = PK_X
    FOR t = 1 TO PK_TABS
        w = LEN(EditPkTabName$(t)) * 8 + 10
        IF x >= tx AND x < tx + w AND y >= PK_Y AND y < PK_Y + 18 THEN what = 1 : idx = t : EXIT SUB
        tx = tx + w + 3
    NEXT
    gy = PK_Y + 22
    IF x >= PK_X AND x < PK_X + PK_COLS * (PK_SIZE + 4) AND y >= gy AND y < gy + PK_ROWS * (PK_SIZE + 4) THEN
        k = edPickScroll * PK_COLS + ((y - gy) \ (PK_SIZE + 4)) * PK_COLS + (x - PK_X) \ (PK_SIZE + 4) + 1
        IF k <= edPkN THEN what = 2 : idx = k
        EXIT SUB
    END IF
    sx = PK_X + PK_COLS * (PK_SIZE + 4)
    IF x >= sx AND x < sx + 20 AND y >= gy AND y < gy + PK_SIZE THEN what = 3
    IF x >= sx AND x < sx + 20 AND y >= gy + PK_SIZE + 4 AND y < gy + 2 * PK_SIZE + 4 THEN what = 4
END SUB

' Is picker entry k the brush?
FUNCTION EditPkIsBrush(k)
    EditPkIsBrush = 0
    SELECT CASE edPkKind(k)
        CASE PK_GLYPH : EditPkIsBrush = (edBrushKind = PK_GLYPH AND edPkVal$(k) = editGlyph$)
        CASE PK_TEX : EditPkIsBrush = (edBrushKind = PK_TEX AND edPkVal$(k) = edBrushTex$)
        CASE PK_LIGHT : EditPkIsBrush = (edBrushKind = PK_LIGHT AND VAL(edPkVal$(k)) = editLightP)
    END SELECT
END FUNCTION

FUNCTION EditPkName$(k)
    SELECT CASE edPkKind(k)
        CASE PK_GLYPH : EditPkName$ = GlyphName$(edPkVal$(k))
        CASE PK_TEX : EditPkName$ = edPkVal$(k)
        CASE PK_LIGHT : EditPkName$ = "light: " + LightPresetName$(VAL(edPkVal$(k)))
    END SELECT
END FUNCTION

' One entry's picture in the box at (x, y), n square: its thumbnail - or a
' light glowing its colour (pulsing, flickering as it will), or the start's
' arrow
SUB EditPkPicture(k, x, y, n)
    IF edPkImg&(k) < -1 THEN _PUTIMAGE (x, y)-STEP(n - 1, n - 1), edPkImg&(k) : EXIT SUB
    cx = x + n \ 2 : cy = y + n \ 2
    IF edPkKind(k) = PK_LIGHT THEN
        p = VAL(edPkVal$(k)) : c~& = EditLightRGB~&(p) : b = 1
        IF p = 5 THEN b = 0.55 + 0.45 * SIN(TIMER * 4) ' (an alarm: pulsing)
        IF p = 6 THEN IF RND < 0.25 THEN b = 0.25 ' (flickering)
        IF p = 7 THEN b = 0.8 + 0.2 * SIN(TIMER * 11) ' (firelight)
        r = _RED32(c~&) * b : g = _GREEN32(c~&) * b : bl = _BLUE32(c~&) * b
        FOR rr = n \ 2 - 2 TO 2 STEP -2
            a = 40 + 200 * (1 - rr / (n / 2))
            CIRCLE (cx, cy), rr, _RGBA32(r, g, bl, a)
        NEXT
        FillCircle cx, cy, n \ 8, _RGB32(MinOf(255, r + 60), MinOf(255, g + 60), MinOf(255, bl + 60))
    ELSEIF edPkKind(k) = PK_GLYPH THEN
        a = (INSTR(">v<^", edPkVal$(k)) - 1) * 1.5708 ' (the start: an arrow the way it faces)
        IF a >= 0 THEN
            ax = COS(a) : ay = SIN(a) : h = n * 0.36
            LINE (cx - ax * h, cy - ay * h)-(cx + ax * h, cy + ay * h), _RGB32(255, 255, 255)
            LINE (cx + ax * h, cy + ay * h)-(cx + ax * h * 0.3 - ay * h * 0.5, cy + ay * h * 0.3 + ax * h * 0.5), _RGB32(255, 255, 255)
            LINE (cx + ax * h, cy + ay * h)-(cx + ax * h * 0.3 + ay * h * 0.5, cy + ay * h * 0.3 - ax * h * 0.5), _RGB32(255, 255, 255)
            HudText cx - 20, y + n - 14, "START", _RGB32(255, 255, 255)
        ELSE
            LINE (x + 4, y + 4)-STEP(n - 9, n - 9), GlyphColor~&(edPkVal$(k)), BF
        END IF
    END IF
END SUB

' The picker, drawn - the pointer at (mx, my)
SUB EditDrawPicker(mx, my)
    EditPkBuild
    LINE (0, PK_Y - 4)-(799, 599), _RGBA32(6, 2, 18, 215), BF
    LINE (0, PK_Y - 5)-(799, PK_Y - 5), _RGBA32(255, 60, 200, 160)
    EditPkHit mx, my, hw, hi
    tx = PK_X ' The tabs
    FOR t = 1 TO PK_TABS
        t$ = EditPkTabName$(t) : w = LEN(t$) * 8 + 10
        IF t = edPickTab THEN bg~& = _RGBA32(120, 20, 100, 240) ELSE bg~& = _RGBA32(20, 10, 40, 230)
        IF hw = 1 AND hi = t THEN bg~& = _RGBA32(40, 70, 110, 240)
        LINE (tx, PK_Y)-STEP(w - 1, 17), bg~&, BF
        IF t = edPickTab THEN LINE (tx, PK_Y)-STEP(w - 1, 17), _RGB32(255, 60, 200), B
        IF t = edPickTab THEN c~& = _RGB32(255, 255, 255) ELSE c~& = _RGB32(190, 180, 230)
        HudText tx + 5, PK_Y + 1, t$, c~&
        tx = tx + w + 3
    NEXT
    gy = PK_Y + 22 ' The thumbnails
    FOR r = 0 TO PK_ROWS - 1 : FOR c = 0 TO PK_COLS - 1
        k = (edPickScroll + r) * PK_COLS + c + 1
        x = PK_X + c * (PK_SIZE + 4) : y = gy + r * (PK_SIZE + 4)
        LINE (x, y)-STEP(PK_SIZE - 1, PK_SIZE - 1), _RGBA32(16, 12, 30, 240), BF
        IF k <= edPkN THEN
            EditPkPicture k, x + 2, y + 2, PK_SIZE - 4
            IF EditPkIsBrush(k) THEN
                LINE (x, y)-STEP(PK_SIZE - 1, PK_SIZE - 1), _RGB32(255, 60, 200), B : LINE (x + 1, y + 1)-STEP(PK_SIZE - 3, PK_SIZE - 3), _RGB32(255, 60, 200), B
            ELSEIF hw = 2 AND hi = k THEN
                LINE (x, y)-STEP(PK_SIZE - 1, PK_SIZE - 1), _RGB32(150, 240, 255), B
            ELSE
                LINE (x, y)-STEP(PK_SIZE - 1, PK_SIZE - 1), _RGB32(60, 50, 90), B
            END IF
        ELSE
            LINE (x, y)-STEP(PK_SIZE - 1, PK_SIZE - 1), _RGB32(30, 26, 50), B
        END IF
    NEXT : NEXT
    ' The scroll arrows, and how far down the list this is
    sx = PK_X + PK_COLS * (PK_SIZE + 4) : rows = (edPkN + PK_COLS - 1) \ PK_COLS
    FOR b = 0 TO 1
        by = gy + b * (PK_SIZE + 4)
        IF hw = 3 + b THEN c~& = _RGBA32(40, 70, 110, 240) ELSE c~& = _RGBA32(20, 10, 40, 230)
        LINE (sx, by)-STEP(19, PK_SIZE - 1), c~&, BF : LINE (sx, by)-STEP(19, PK_SIZE - 1), _RGB32(90, 70, 140), B
        IF (b = 0 AND edPickScroll > 0) OR (b = 1 AND edPickScroll + PK_ROWS < rows) THEN c~& = _RGB32(255, 255, 255) ELSE c~& = _RGB32(70, 60, 100)
        ay = by + PK_SIZE \ 2 : d = 1 - 2 * b
        LINE (sx + 4, ay + 3 * d)-(sx + 10, ay - 3 * d), c~& : LINE (sx + 10, ay - 3 * d)-(sx + 16, ay + 3 * d), c~&
    NEXT
    IF rows > PK_ROWS THEN ' (a bar: where these two rows are in all of them)
        bh = 2 * PK_SIZE + 4 : LINE (sx + 22, gy)-STEP(3, bh - 1), _RGBA32(60, 50, 90, 200), BF
        LINE (sx + 22, gy + bh * edPickScroll \ rows)-STEP(3, bh * PK_ROWS \ rows - 1), _RGB32(255, 60, 200), BF
    END IF
    ' On the right: the brush, big, and what the pointer's over
    bx = sx + 34
    HudText bx, gy, "BRUSH", _RGB32(255, 90, 200)
    LINE (bx, gy + 18)-STEP(67, 67), _RGBA32(16, 12, 30, 240), BF : LINE (bx, gy + 18)-STEP(67, 67), _RGB32(255, 60, 200), B
    SELECT CASE edBrushKind
        CASE PK_TEX
            IF edBrushImg& < -1 THEN _PUTIMAGE (bx + 2, gy + 20)-STEP(63, 63), edBrushImg&
            n$ = edBrushTex$
        CASE PK_LIGHT
            c~& = EditLightRGB~&(editLightP) : FillCircle bx + 34, gy + 52, 16, c~& : n$ = "light: " + LightPresetName$(editLightP)
        CASE ELSE ' (a map character: its picture, made again when the brush changes - [ ] or E too)
            STATIC thumbOf$, thumbImg&
            IF thumbOf$ <> editGlyph$ + STR$(artNow) + lvlWall$(1) THEN
                IF thumbImg& < -1 THEN _FREEIMAGE thumbImg&
                thumbImg& = EditGlyphThumb&(editGlyph$) : thumbOf$ = editGlyph$ + STR$(artNow) + lvlWall$(1)
            END IF
            IF thumbImg& < -1 THEN
                _PUTIMAGE (bx + 2, gy + 20)-STEP(63, 63), thumbImg&
            ELSE
                k = 0 : FOR j = 1 TO edPkN : IF edPkKind(j) = PK_GLYPH AND edPkVal$(j) = editGlyph$ THEN k = j
                NEXT
                IF k THEN EditPkPicture k, bx + 2, gy + 20, 64 ELSE LINE (bx + 6, gy + 24)-STEP(55, 55), GlyphColor~&(editGlyph$), BF
            END IF
            n$ = GlyphName$(editGlyph$)
    END SELECT
    tw = (792 - bx - 76) \ 8 ' (its name beside it, in lines that fit)
    ty = gy + 18
    DO WHILE LEN(n$) AND ty < gy + 86
        l$ = LEFT$(n$, tw) : HudText bx + 76, ty, l$, _RGB32(255, 255, 255) : ty = ty + 16 : n$ = MID$(n$, tw + 1)
    LOOP
    IF hw = 2 THEN h$ = EditPkName$(hi) ELSE h$ = "Click one: it's the brush" + MID$(" (and the selection's)", 1, -22 * (edSelN > 0))
    HudText PK_X, gy + 2 * (PK_SIZE + 4) + 2, LEFT$(h$, 98), _RGB32(150, 240, 255)
END SUB

' A face's number in [faces]: a wall's or step's side 1-4, a lintel's 5-8,
' the floor 9, the ceiling 10
FUNCTION EditFaceCode(kind, side)
    SELECT CASE kind
        CASE ED_FLOOR : EditFaceCode = 9
        CASE ED_CEIL : EditFaceCode = 10
        CASE ED_LINTEL : EditFaceCode = side + 4
        CASE ELSE : EditFaceCode = side
    END SELECT
END FUNCTION

' Where a click with PLACE or LIGHT goes for a face: a floor or ceiling's
' own cell; a wall's (a step's, a lintel's) the open cell in front of it
SUB EditFaceCell(kind, x, y, side, tx, ty)
    IF kind = ED_FLOOR OR kind = ED_CEIL THEN tx = x : ty = y ELSE EditFaceFront x, y, side, tx, ty
END SUB

' Delete: every face selected, gone - a wall opened up (its floor and
' ceiling like the cell in front), a thing on a floor taken away (never
' the start), a step or lintel flattened to the floor or ceiling in front
' of it. Says how many; the selection's cleared.
SUB EditDeleteSel
    n = 0
    FOR k = 1 TO edSelN
        x = edSelX(k) : y = edSelY(k) : EditFaceFront x, y, edSelSide(k), fx, fy
        IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN
            c$ = MID$(lvlRow$(y), x + 1, 1)
            SELECT CASE edSelKind(k)
                CASE ED_WALL
                    IF c$ <> "." AND fx >= 0 AND fy >= 0 AND fx < MAP_SIZE AND fy < MAP_SIZE THEN
                        EditPut x, y, "." : n = n + 1
                        MID$(lvlFloorRow$(y), x + 1, 1) = MID$(lvlFloorRow$(fy), fx + 1, 1) : MID$(lvlCeilRow$(y), x + 1, 1) = MID$(lvlCeilRow$(fy), fx + 1, 1)
                    END IF
                CASE ED_FLOOR, ED_CEIL
                    IF c$ <> "." AND INSTR("<>^v", c$) = 0 THEN EditPut x, y, "." : n = n + 1
                CASE ED_STEP
                    MID$(lvlFloorRow$(y), x + 1, 1) = MID$(lvlFloorRow$(fy), fx + 1, 1) : n = n + 1
                CASE ED_LINTEL
                    MID$(lvlCeilRow$(y), x + 1, 1) = MID$(lvlCeilRow$(fy), fx + 1, 1) : n = n + 1
            END SELECT
        END IF
    NEXT
    edSelN = 0
    EditNote "Deleted" + STR$(n)
END SUB

' The selection on the map from above: a floor or ceiling as a box inside
' its cell, a side as a thick line along that edge of it
SUB EditDrawSelMap
    FOR k = 1 TO edSelN
        sx = ED_MAPX + edSelX(k) * ED_CELL : sy = ED_MAPY + edSelY(k) * ED_CELL : c~& = _RGB32(255, 170, 40)
        SELECT CASE edSelKind(k)
            CASE ED_FLOOR, ED_CEIL
                LINE (sx + 1, sy + 1)-STEP(ED_CELL - 3, ED_CELL - 3), c~&, B
                IF edSelKind(k) = ED_CEIL THEN LINE (sx + 3, sy + 3)-STEP(ED_CELL - 7, ED_CELL - 7), c~&, B ' (a ceiling: a box in a box)
            CASE ELSE
                SELECT CASE edSelSide(k)
                    CASE 1 : LINE (sx + ED_CELL - 2, sy)-STEP(1, ED_CELL - 1), c~&, BF
                    CASE 2 : LINE (sx, sy + ED_CELL - 2)-STEP(ED_CELL - 1, 1), c~&, BF
                    CASE 3 : LINE (sx, sy)-STEP(1, ED_CELL - 1), c~&, BF
                    CASE 4 : LINE (sx, sy)-STEP(ED_CELL - 1, 1), c~&, BF
                END SELECT
        END SELECT
    NEXT
END SUB

' The arrows' nudge: every cell the selection is on moves a cell along
' (dx, dy) - what it is (wall, floor, a thing on it), its floor and ceiling
' heights. A cell it leaves takes after the one behind it (so a platform
' slides along, leaving floor like the floor round it). Not into the
' border. The selection moves with it.
SUB EditNudge(dx, dy)
    DIM r$(MAP_SIZE - 1), f$(MAP_SIZE - 1), c$(MAP_SIZE - 1), mv(MAP_SIZE, MAP_SIZE) AS INTEGER, dest(MAP_SIZE, MAP_SIZE) AS INTEGER
    FOR y = 0 TO MAP_SIZE - 1 : r$(y) = lvlRow$(y) : f$(y) = lvlFloorRow$(y) : c$(y) = lvlCeilRow$(y) : NEXT
    FOR k = 1 TO edSelN
        x = edSelX(k) : y = edSelY(k)
        IF x + dx < 1 OR y + dy < 1 OR x + dx > MAP_SIZE - 2 OR y + dy > MAP_SIZE - 2 THEN EditNote "Can't move into the border" : EXIT SUB
        mv(x, y) = -1
    NEXT
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF mv(x, y) THEN dest(x + dx, y + dy) = -1
    NEXT : NEXT
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF mv(x, y) AND NOT dest(x, y) THEN ' (left behind: like the cell behind it)
            bx = x - dx : by = y - dy
            DO WHILE mv(bx, by) AND bx > 0 AND by > 0 AND bx < MAP_SIZE - 1 AND by < MAP_SIZE - 1 : bx = bx - dx : by = by - dy : LOOP
            MID$(lvlRow$(y), x + 1, 1) = MID$(r$(by), bx + 1, 1) : MID$(lvlFloorRow$(y), x + 1, 1) = MID$(f$(by), bx + 1, 1) : MID$(lvlCeilRow$(y), x + 1, 1) = MID$(c$(by), bx + 1, 1)
            IF INSTR("<>^v", MID$(lvlRow$(y), x + 1, 1)) THEN MID$(lvlRow$(y), x + 1, 1) = "." ' (never a second start)
        END IF
    NEXT : NEXT
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF mv(x, y) THEN
            MID$(lvlRow$(y + dy), x + dx + 1, 1) = MID$(r$(y), x + 1, 1) : MID$(lvlFloorRow$(y + dy), x + dx + 1, 1) = MID$(f$(y), x + 1, 1) : MID$(lvlCeilRow$(y + dy), x + dx + 1, 1) = MID$(c$(y), x + 1, 1)
        END IF
    NEXT : NEXT
    FOR k = 1 TO edSelN : edSelX(k) = edSelX(k) + dx : edSelY(k) = edSelY(k) + dy : NEXT
END SUB

' G: the grid over the world on or off; Shift+G: stronger (25, 50, 75, 100%,
' round again)
SUB EditGridKey(shiftOn)
    IF shiftOn THEN
        edGrid = -1 : edGridAlpha = edGridAlpha + 64 : IF edGridAlpha > 255 THEN edGridAlpha = 63
        EditNote "Grid" + STR$(INT(edGridAlpha * 100 / 255 + 0.5)) + "%"
    ELSE
        edGrid = NOT edGrid : IF edGrid THEN EditNote "Grid on (Shift+G: stronger)" ELSE EditNote "Grid off"
    END IF
END SUB

' THE GRID, in the software renderer: a texel on a cell's edge (or where a
' wall's picture starts again, a wall high) mixed towards cyan by how
' strong the grid is - EditGridOn (and gridW, how thick in texels) set
' once a frame, so the drawing only asks one question when it's off
FUNCTION GridMix~&(pix~&)
    a = edGridAlpha / 255
    r = (pix~& \ 65536) AND 255 : g = (pix~& \ 256) AND 255 : b = pix~& AND 255
    GridMix~& = &HFF000000~& OR (INT(r + (90 - r) * a) * 65536) OR (INT(g + (230 - g) * a) * 256) OR INT(b + (255 - b) * a)
END FUNCTION

' The open cell a side of cell (x, y) looks into (side 1 east, 2 south,
' 3 west, 4 north)
SUB EditFaceFront(x, y, side, fx, fy)
    fx = x : fy = y
    SELECT CASE side
        CASE 1 : fx = x + 1
        CASE 2 : fy = y + 1
        CASE 3 : fx = x - 1
        CASE ELSE : fy = y - 1
    END SELECT
END SUB

SUB EditHit(kind, x, y, side, hx, hy, hz)
    edHovKind = kind : edHovX = x : edHovY = y : edHovSide = side : edHovPart = 0
    edHovPX = hx : edHovPY = hy : edHovPZ = hz
END SUB

' A point in the world on the screen (sx, sy) - or ok = 0 if it's behind
' you. The pointer's sums the right way round: how far right, up and ahead
' of the camera it is, divided by how far ahead.
SUB EditCam(wx, wy, wz, cr, cu, ca)
    rx = wx - edCamPX : ry = wy - edCamPY : rz = wz - eyeZ
    r = rx * edCamDY - ry * edCamDX : u0 = rz : bk = -(rx * edCamDX + ry * edCamDY)
    c = COS(pitch) : sn = SIN(pitch)
    cr = r : cu = c * u0 + sn * bk : ca = -(-sn * u0 + c * bk)
END SUB

' A line in the world, on the screen: cut where it passes behind you (so
' half of a face behind you still draws its front half)
SUB EditLine3D(x1, y1, z1, x2, y2, z2, col~&)
    EditCam x1, y1, z1, r1, u1, a1 : EditCam x2, y2, z2, r2, u2, a2
    nr = 0.05
    IF a1 < nr AND a2 < nr THEN EXIT SUB
    IF a1 < nr THEN f = (nr - a1) / (a2 - a1) : r1 = r1 + (r2 - r1) * f : u1 = u1 + (u2 - u1) * f : a1 = nr
    IF a2 < nr THEN f = (nr - a2) / (a1 - a2) : r2 = r2 + (r1 - r2) * f : u2 = u2 + (u1 - u2) * f : a2 = nr
    ak = 1 : IF glMode THEN ak = glAspectK
    sx1 = (r1 / (a1 * edCamPlane * ak) + 1) * 400 : sy1 = (1 - u1 * 2 * edCamZoom / a1) * 300
    sx2 = (r2 / (a2 * edCamPlane * ak) + 1) * 400 : sy2 = (1 - u2 * 2 * edCamZoom / a2) * 300
    IF ABS(sx1) > 20000 OR ABS(sy1) > 20000 OR ABS(sx2) > 20000 OR ABS(sy2) > 20000 THEN EXIT SUB
    LINE (sx1, sy1)-(sx2, sy2), col~&
    LINE (sx1 + 1, sy1)-(sx2 + 1, sy2), col~& ' (two pixels wide)
END SUB

' A face's outline: a floor or ceiling's square, or a side's rectangle -
' from the open cell's floor to its ceiling, for a wall; the step's height,
' for a step or a lintel (the open cell beside it is on its other side)
SUB EditFaceOutline(kind, x, y, side, col~&)
    SELECT CASE kind
        CASE ED_FLOOR, ED_CEIL
            IF kind = ED_FLOOR THEN z = floorH(x, y) ELSE z = ceilH(x, y)
            EditLine3D x, y, z, x + 1, y, z, col~& : EditLine3D x + 1, y, z, x + 1, y + 1, z, col~&
            EditLine3D x + 1, y + 1, z, x, y + 1, z, col~& : EditLine3D x, y + 1, z, x, y, z, col~&
        CASE ED_WALL, ED_STEP, ED_LINTEL
            SELECT CASE side ' (the edge, and the open cell on its far side)
                CASE 1 : ax = x + 1 : ay = y : bx = x + 1 : by = y + 1 : ox = x + 1 : oy = y
                CASE 2 : ax = x : ay = y + 1 : bx = x + 1 : by = y + 1 : ox = x : oy = y + 1
                CASE 3 : ax = x : ay = y : bx = x : by = y + 1 : ox = x - 1 : oy = y
                CASE ELSE : ax = x : ay = y : bx = x + 1 : by = y : ox = x : oy = y - 1
            END SELECT
            IF ox < 0 OR oy < 0 OR ox >= MAP_SIZE OR oy >= MAP_SIZE THEN EXIT SUB
            SELECT CASE kind
                CASE ED_WALL : z0 = floorH(ox, oy) : z1 = ceilH(ox, oy)
                CASE ED_STEP : z0 = floorH(ox, oy) : z1 = floorH(x, y)
                CASE ELSE : z0 = ceilH(x, y) : z1 = ceilH(ox, oy)
            END SELECT
            EditLine3D ax, ay, z0, bx, by, z0, col~& : EditLine3D bx, by, z0, bx, by, z1, col~&
            EditLine3D bx, by, z1, ax, ay, z1, col~& : EditLine3D ax, ay, z1, ax, ay, z0, col~&
    END SELECT
END SUB

' The 3D editor's outlines, over the view: the face under the pointer
' (cyan, pulsing) - and what it is, by the pointer
SUB EditDrawFaces
    FOR k = 1 TO edSelN ' The selection: orange
        EditFaceOutline edSelKind(k), edSelX(k), edSelY(k), edSelSide(k), _RGB32(255, 170, 40)
    NEXT
    IF edHovKind THEN
        k = 160 + 95 * SIN(TIMER * 6)
        EditFaceOutline edHovKind, edHovX, edHovY, edHovSide, _RGB32(60, k, 255)
        IF NOT edLooking THEN
            n$ = MID$("WALL   FLOOR  CEILINGSTEP   LINTEL ", edHovKind * 7 - 6, 7)
            n$ = RTRIM$(n$) + STR$(edHovX) + "," + LTRIM$(STR$(edHovY))
            IF edHovKind <> ED_FLOOR AND edHovKind <> ED_CEIL THEN n$ = n$ + " " + MID$("ESWN", edHovSide, 1)
            COLOR _RGB32(150, 230, 255) : _PRINTSTRING (edCurX + 14, edCurY + 10), n$
        END IF
    END IF
END SUB

SUB EditOverlay(px, py, fx, fy)
    LINE (8, 56)-(330, 124), _RGBA32(6, 2, 18, 190), BF
    LINE (8, 56)-(330, 124), _RGB32(255, 60, 200), B
    HudText 16, 60, "TOOL: " + RTRIM$(MID$("SELECTPLACE PAINT LIGHT HEIGHT", edTool * 6 - 5, 6)), _RGB32(255, 90, 200)
    IF edTool = ET_LIGHT THEN
        HudText 16, 76, "LIGHT: " + LightPresetName$(editLightP) + " (1-8)", _RGB32(255, 220, 120)
    ELSEIF edTool = ET_PAINT THEN
        HudText 16, 76, LEFT$("PICTURE: " + edBrushTex$, 38), _RGB32(150, 240, 255)
    ELSE
        HudText 16, 76, LEFT$("BRUSH: " + GlyphName$(editGlyph$), 38), GlyphColor~&(editGlyph$)
    END IF
    IF edSelN THEN HudText 16, 92, LTRIM$(STR$(edSelN)) + " selected (Ctrl+D: none)", _RGB32(255, 190, 80) ELSE HudText 16, 92, "Nothing selected", _RGB32(140, 130, 180)
    IF editDirty THEN HudText 16, 108, "* not saved (Ctrl+S)", _RGB32(255, 90, 90) ELSE HudText 16, 108, "Saved", _RGB32(140, 130, 180)
    IF TIMER < editMsgUntil! THEN
        my = 470 : IF edPickOn AND editView = 1 THEN my = PK_Y - 30 ' (above the picker)
        LINE (0, my)-(799, my + 20), _RGBA32(0, 0, 0, 170), BF
        HudText 400 - LEN(LEFT$(editMsg$, 98)) * 4, my + 4, LEFT$(editMsg$, 98), _RGB32(255, 220, 120)
    END IF
END SUB

' From (px, py) looking (fx, fy): the first cell that isn't open floor
' (ax, ay) - a wall, a door, glass, or a thing - and the open cell just
' before it (bx, by), where something built would go. -1 if nothing near.
SUB EditAim(px, py, fx, fy, ax, ay, bx, by)
    ax = -1 : ay = -1 : bx = -1 : by = -1
    lx = INT(px) : ly = INT(py)
    FOR d = 0.3 TO 12 STEP 0.05
        cx = INT(px + fx * d) : cy = INT(py + fy * d)
        IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT SUB
        IF cx <> INT(px) OR cy <> INT(py) THEN
            c$ = MID$(lvlRow$(cy), cx + 1, 1)
            IF c$ <> "." THEN
                ax = cx : ay = cy
                IF lx <> cx OR ly <> cy THEN bx = lx : by = ly
                IF bx = INT(px) AND by = INT(py) THEN bx = -1 : by = -1 ' (not where you stand)
                EXIT SUB
            END IF
        END IF
        lx = cx : ly = cy
    NEXT
END SUB

' The next (or previous: d = -1) picture called prefix*.png in the
' pictures' folder, after now$ (in name order)
FUNCTION EditNextPicture$(prefix$, now$, d)
    DIM names$(200)
    n = 0
    dir$ = AssetPath$("x") : dir$ = LEFT$(dir$, LEN(dir$) - 1)
    f$ = _FILES$(dir$ + prefix$ + "*.png")
    DO WHILE LEN(f$) AND n < 200
        b$ = f$ : sl = _INSTRREV(b$, "/") : IF sl THEN b$ = MID$(b$, sl + 1)
        IF b$ <> "wall-jack.png" AND b$ <> "ceiling-lamp.png" THEN n = n + 1 : names$(n) = b$
        f$ = _FILES$
    LOOP
    IF n = 0 THEN EditNextPicture$ = now$ : EXIT FUNCTION
    FOR a = 1 TO n - 1 : FOR b = a + 1 TO n ' (in order)
        IF names$(b) < names$(a) THEN SWAP names$(a), names$(b)
    NEXT : NEXT
    at = 0
    FOR k = 1 TO n
        IF names$(k) = now$ THEN at = k
    NEXT
    at = at + d : IF at < 1 THEN at = n
    IF at > n THEN at = 1
    EditNextPicture$ = names$(at)
END FUNCTION

' Which of the level's floors (1-4) and ceilings (1-2) cell (x, y) has
FUNCTION FloorNumberAt(x, y)
    n = floorTex(x, y) - T_FLOOR : IF n < 1 OR n > 4 THEN n = 1
    FloorNumberAt = n
END FUNCTION
FUNCTION CeilNumberAt(x, y)
    n = ceilTex(x, y) - T_CEIL : IF n < 1 OR n > 2 THEN n = 1
    CeilNumberAt = n
END FUNCTION

' Cell (x, y)'s floor (or, with ceil, its ceiling) up by d - in the
' level's [floor] / [ceiling] map
SUB EditRaise(x, y, d, ceil)
    IF x < 1 OR y < 1 OR x > MAP_SIZE - 2 OR y > MAP_SIZE - 2 THEN EXIT SUB
    IF ceil THEN
        h = HeightOf(MID$(lvlCeilRow$(y), x + 1, 1), 1) + d
        IF h < HeightOf(MID$(lvlFloorRow$(y), x + 1, 1), 0) + 0.25 THEN EXIT SUB
        MID$(lvlCeilRow$(y), x + 1, 1) = HeightChar$(h, 1)
    ELSE
        h = HeightOf(MID$(lvlFloorRow$(y), x + 1, 1), 0) + d
        IF h > HeightOf(MID$(lvlCeilRow$(y), x + 1, 1), 1) - 0.25 OR h < -8 * H_STEP THEN EXIT SUB
        MID$(lvlFloorRow$(y), x + 1, 1) = HeightChar$(h, 0)
    END IF
END SUB

' A floor/ceiling zone (chapter 22) on the end of the list
SUB EditAddZone(x0, y0, x1, y1, fl, ce)
    IF lvlNumZones >= MAX_ZONES THEN EXIT SUB
    lvlNumZones = lvlNumZones + 1
    lvlZone(lvlNumZones, 1) = x0 : lvlZone(lvlNumZones, 2) = y0 : lvlZone(lvlNumZones, 3) = x1 : lvlZone(lvlNumZones, 4) = y1
    lvlZone(lvlNumZones, 5) = fl : lvlZone(lvlNumZones, 6) = ce : lvlZone(lvlNumZones, 7) = 0
END SUB

' The editor's lights: eight ready-made kinds (editLightP)
FUNCTION LightPresetName$(p)
    LightPresetName$ = RTRIM$(MID$("white      cyan       magenta    orange     green      red alarm  flickering firelight  ", p * 11 + 1, 11))
END FUNCTION
SUB EditAddLight(x, y)
    IF lvlNumLights >= MAX_LIGHTS THEN EditNote "Too many lights" : EXIT SUB
    lvlNumLights = lvlNumLights + 1 : k = lvlNumLights
    lvlLight(k, 1) = x : lvlLight(k, 2) = y : lvlLight(k, 3) = 5 : lvlLight(k, 4) = 140 : lvlLight(k, 8) = 0
    SELECT CASE editLightP
        CASE 0 : r = 230 : g = 235 : b = 255
        CASE 1 : r = 60 : g = 220 : b = 255
        CASE 2 : r = 255 : g = 60 : b = 220
        CASE 3 : r = 255 : g = 160 : b = 60
        CASE 4 : r = 90 : g = 255 : b = 120
        CASE 5 : r = 255 : g = 40 : b = 40 : lvlLight(k, 8) = 3
        CASE 6 : r = 220 : g = 230 : b = 255 : lvlLight(k, 8) = 1
        CASE ELSE : r = 255 : g = 150 : b = 70 : lvlLight(k, 8) = 4
    END SELECT
    lvlLight(k, 5) = r : lvlLight(k, 6) = g : lvlLight(k, 7) = b
    EditNote "Light (" + LightPresetName$(editLightP) + ") at" + STR$(INT(x)) + STR$(INT(y))
END SUB
SUB EditRemoveLight(x, y)
    best = 0 : bestD = 2.25
    FOR k = 1 TO lvlNumLights
        d = (lvlLight(k, 1) - x) ^ 2 + (lvlLight(k, 2) - y) ^ 2
        IF d < bestD THEN bestD = d : best = k
    NEXT
    IF best = 0 THEN EditNote "No light near" : EXIT SUB
    FOR k = best TO lvlNumLights - 1 : FOR j = 1 TO 8 : lvlLight(k, j) = lvlLight(k + 1, j) : NEXT : NEXT
    lvlNumLights = lvlNumLights - 1 : EditNote "Light taken away"
END SUB

' One line of [triggers], taken apart into trigger numTrigs + 1: its WHEN,
' its place, "repeat", and - after the colon - its commands
SUB TakeTrigger(l$)
    c = INSTR(l$, ":") : IF c = 0 OR numTrigs >= MAX_TRIGS THEN EXIT SUB
    w$ = LCASE$(LTRIM$(RTRIM$(LEFT$(l$, c - 1)))) + " "
    numTrigs = numTrigs + 1 : k = numTrigs
    trigCmd$(k) = LTRIM$(MID$(l$, c + 1)) : trigDone(k) = 0 : trigWas(k) = -1 : trigRepeat(k) = (INSTR(w$, "repeat") > 0)
    sp = INSTR(w$, " ") : trigWhen$(k) = LEFT$(w$, sp - 1) : w$ = MID$(w$, sp + 1)
    DIM n(4) AS SINGLE
    FOR j = 1 TO 4
        w$ = LTRIM$(w$) : sp = INSTR(w$, " ")
        IF sp > 1 THEN n(j) = VAL(LEFT$(w$, sp - 1)) : w$ = MID$(w$, sp + 1)
    NEXT
    trigX0(k) = MinOf(n(1), n(3)) : trigY0(k) = MinOf(n(2), n(4)) : trigX1(k) = MaxOf(n(1), n(3)) : trigY1(k) = MaxOf(n(2), n(4))
    IF trigWhen$(k) = "use" OR trigWhen$(k) = "time" THEN trigX0(k) = n(1) : trigY0(k) = n(2) : trigX1(k) = n(1) : trigY1(k) = n(2)
END SUB

' A teleporter's pad, into sprite slot slot: rings of violet light
SUB MakePad(slot)
    spriteSize(slot) = sprTex : k = sprTex / 64 ' (designed 64 pixels across)
    FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1
        d = SQR(((x + 0.5) / k - 32) ^ 2 + ((y + 0.5) / k - 32) ^ 2) : c~& = 0
        IF d < 31 THEN c~& = _RGBA32(40, 30, 70, 255) ' (the plate)
        IF d < 31 AND d > 27 THEN c~& = _RGBA32(150, 160, 190, 255) ' (its metal rim)
        IF (d > 20 AND d < 23) OR (d > 11 AND d < 14) THEN c~& = _RGBA32(190, 110, 255, 255) ' (glowing rings)
        IF d < 5 THEN c~& = _RGBA32(255, 230, 255, 255)
        spriteTex(x, y, slot) = c~&
    NEXT : NEXT
END SUB

' --- The HUD's layout (chapter 18's data; hud.txt; the HUD editor) --------
SUB HudDefaults
    FOR e = 1 TO HUD_ELEMS : hudShow(e) = -1 : hudCol(e) = 0 : hudW(e) = 0 : hudH(e) = 0 : hudLabel$(e) = "" : NEXT
    hudName$(HE_HEALTH) = "health" : hudX(HE_HEALTH) = 16 : hudY(HE_HEALTH) = 552 : hudW(HE_HEALTH) = 200 : hudH(HE_HEALTH) = 12 : hudLabel$(HE_HEALTH) = "HEALTH"
    hudName$(HE_ARMOR) = "armor" : hudX(HE_ARMOR) = 16 : hudY(HE_ARMOR) = 516 : hudW(HE_ARMOR) = 200 : hudH(HE_ARMOR) = 8 : hudLabel$(HE_ARMOR) = "ARMOR"
    hudName$(HE_AMMO) = "ammo" : hudX(HE_AMMO) = 784 : hudY(HE_AMMO) = 552 : hudW(HE_AMMO) = 200 : hudH(HE_AMMO) = 12
    hudName$(HE_GUNS) = "guns" : hudX(HE_GUNS) = 582 : hudY(HE_GUNS) = 534
    hudName$(HE_KILLS) = "kills" : hudX(HE_KILLS) = MINIMAP_X : hudY(HE_KILLS) = MINIMAP_Y : hudLabel$(HE_KILLS) = "KILLS"
    hudName$(HE_MINIMAP) = "minimap" : hudX(HE_MINIMAP) = MINIMAP_X : hudY(HE_MINIMAP) = MINIMAP_Y : hudW(HE_MINIMAP) = MINIMAP_CELL
    hudName$(HE_CARDS) = "keycards" : hudX(HE_CARDS) = 784 : hudY(HE_CARDS) = 8 : hudW(HE_CARDS) = 64
    hudName$(HE_MESSAGE) = "message" : hudX(HE_MESSAGE) = 400 : hudY(HE_MESSAGE) = 510
    hudName$(HE_SUBTITLE) = "subtitle" : hudX(HE_SUBTITLE) = 400 : hudY(HE_SUBTITLE) = 44
    hudName$(HE_AMP) = "amp" : hudX(HE_AMP) = 16 : hudY(HE_AMP) = 532 : hudLabel$(HE_AMP) = "DAMAGE AMP"
    hudName$(HE_GOD) = "godmode" : hudX(HE_GOD) = 16 : hudY(HE_GOD) = 498 : hudLabel$(HE_GOD) = "GOD MODE"
    hudName$(HE_EVENT) = "event" : hudX(HE_EVENT) = 400 : hudY(HE_EVENT) = 28
    hudName$(HE_NETWORK) = "network" : hudX(HE_NETWORK) = 400 : hudY(HE_NETWORK) = 74
    hudName$(HE_FPS) = "fps" : hudX(HE_FPS) = 400 : hudY(HE_FPS) = 8
END SUB

' A part's colour: its own from hud.txt - or, if it has none, the game's
FUNCTION HudColor~&(e, dflt~&)
    IF hudCol(e) THEN HudColor~& = hudCol(e) ELSE HudColor~& = dflt~&
END FUNCTION

' The HUD editor's colours, one after another (0: the game's own)
FUNCTION HudNextColor~&(c~&)
    DIM p(8) AS _UNSIGNED LONG
    p(0) = 0 : p(1) = _RGB32(255, 255, 255) : p(2) = _RGB32(60, 230, 255) : p(3) = _RGB32(255, 70, 220) : p(4) = _RGB32(80, 255, 120)
    p(5) = _RGB32(255, 230, 60) : p(6) = _RGB32(255, 70, 70) : p(7) = _RGB32(255, 150, 40) : p(8) = _RGB32(170, 140, 255)
    n = 0
    FOR k = 0 TO 8
        IF p(k) = c~& THEN n = k + 1
    NEXT
    HudNextColor~& = p(n MOD 9)
END FUNCTION

' Roughly where part e is on the screen (for picking it, and its box)
SUB HudBox(e, x0, y0, x1, y1)
    x = hudX(e) : y = hudY(e)
    SELECT CASE e
        CASE HE_HEALTH, HE_ARMOR : x0 = x : y0 = y : x1 = x + MaxOf(hudW(e), 96) + 2 : y1 = y + 20 + hudH(e)
        CASE HE_AMMO : x0 = x - MaxOf(hudW(e), 120) - 2 : y0 = y : x1 = x : y1 = y + 20 + hudH(e)
        CASE HE_GUNS : x0 = x : y0 = y : x1 = x + 76 : y1 = y + 16
        CASE HE_MINIMAP : x0 = x : y0 = y : x1 = x + MAP_SIZE * hudW(e) : y1 = y + MAP_SIZE * hudW(e)
        CASE HE_CARDS : x0 = x - 3 * (hudW(e) + 4) : y0 = y : x1 = x : y1 = y + hudW(e)
        CASE HE_MESSAGE, HE_SUBTITLE, HE_EVENT, HE_NETWORK, HE_FPS : x0 = x - 160 : y0 = y : x1 = x + 160 : y1 = y + 22
        CASE ELSE : x0 = x : y0 = y : x1 = x + 120 : y1 = y + 16
    END SELECT
END SUB

' The HUD editor's boxes: every part, the chosen one bright (with its name)
SUB HudEditDraw
    FOR e = 1 TO HUD_ELEMS
        HudBox e, x0, y0, x1, y1
        IF e = hudSel THEN c~& = _RGB32(255, 255, 255) ELSE c~& = _RGBA32(255, 60, 200, 150)
        IF NOT hudShow(e) THEN c~& = _RGBA32(150, 150, 150, 130)
        LINE (x0 - 2, y0 - 2)-(x1 + 2, y1 + 2), c~&, B
        t$ = hudName$(e) : IF NOT hudShow(e) THEN t$ = t$ + " (hidden)"
        IF e = hudSel THEN HudText x0, y0 - 14, t$, _RGB32(255, 255, 255) ELSE HudText x0, y0 - 14, t$, _RGBA32(255, 120, 220, 200)
    NEXT
    LINE (0, 582)-(799, 599), _RGBA32(0, 0, 0, 200), BF
    HudText 4, 584, LEFT$(hudMsg$, 98), _RGB32(255, 220, 120)
END SUB

' hud.txt: one [name] section a part - show, x, y, bar (width, height),
' color (auto, or red, green, blue), label
SUB ReadHud
    f$ = AssetPath$("hud.txt")
    IF NOT _FILEEXISTS(f$) THEN EXIT SUB
    fh = FREEFILE : OPEN f$ FOR INPUT AS #fh : e = 0
    DO UNTIL EOF(fh)
        LINE INPUT #fh, l$
        l$ = LTRIM$(RTRIM$(l$)) : IF RIGHT$(l$, 1) = CHR$(13) THEN l$ = LEFT$(l$, LEN(l$) - 1)
        IF LEFT$(l$, 1) = "[" AND RIGHT$(l$, 1) = "]" THEN
            n$ = LCASE$(MID$(l$, 2, LEN(l$) - 2)) : e = 0
            FOR k = 1 TO HUD_ELEMS
                IF hudName$(k) = n$ THEN e = k
            NEXT
        ELSEIF e > 0 AND INSTR(l$, "=") AND LEFT$(l$, 1) <> "'" THEN
            eq = INSTR(l$, "=") : k$ = LCASE$(RTRIM$(LEFT$(l$, eq - 1))) : v$ = LTRIM$(MID$(l$, eq + 1))
            SELECT CASE k$
                CASE "show" : hudShow(e) = (LCASE$(v$) <> "no")
                CASE "x" : hudX(e) = VAL(v$)
                CASE "y" : hudY(e) = VAL(v$)
                CASE "bar" : hudW(e) = VAL(ListItem$(v$, 1)) : hudH(e) = VAL(ListItem$(v$, 2))
                CASE "size" : hudW(e) = VAL(v$)
                CASE "color", "colour" : IF LCASE$(v$) = "auto" THEN hudCol(e) = 0 ELSE hudCol(e) = _RGB32(VAL(ListItem$(v$, 1)), VAL(ListItem$(v$, 2)), VAL(ListItem$(v$, 3)))
                CASE "label" : hudLabel$(e) = v$
            END SELECT
        END IF
    LOOP
    CLOSE #fh
END SUB

SUB WriteHud
    nl$ = CHR$(10)
    o$ = "' NEON-CASTER HUD - where each part of it goes (chapter 18). The HUD" + nl$
    o$ = o$ + "' layout editor (U in the level editor, or hud in the console) writes" + nl$
    o$ = o$ + "' this file; delete it for the game's own layout." + nl$
    o$ = o$ + "'   show: yes or no   x, y: on the 800 x 600 screen (ammo: its right edge;" + nl$
    o$ = o$ + "'   message, subtitle, event, network, fps: their middle)   bar: width," + nl$
    o$ = o$ + "'   height   size: the minimap's cells, the keycards' pictures" + nl$
    o$ = o$ + "'   color: auto (the game's own) or red, green, blue   label: its word" + nl$
    FOR e = 1 TO HUD_ELEMS
        o$ = o$ + nl$ + "[" + hudName$(e) + "]" + nl$
        IF hudShow(e) THEN o$ = o$ + "show  = yes" + nl$ ELSE o$ = o$ + "show  = no" + nl$
        o$ = o$ + "x     = " + LTRIM$(STR$(hudX(e))) + nl$ + "y     = " + LTRIM$(STR$(hudY(e))) + nl$
        SELECT CASE e
            CASE HE_HEALTH, HE_ARMOR, HE_AMMO : o$ = o$ + "bar   = " + LTRIM$(STR$(hudW(e))) + ", " + LTRIM$(STR$(hudH(e))) + nl$
            CASE HE_MINIMAP, HE_CARDS : o$ = o$ + "size  = " + LTRIM$(STR$(hudW(e))) + nl$
        END SELECT
        IF hudCol(e) THEN o$ = o$ + "color = " + LTRIM$(STR$(_RED32(hudCol(e)))) + ", " + LTRIM$(STR$(_GREEN32(hudCol(e)))) + ", " + LTRIM$(STR$(_BLUE32(hudCol(e)))) + nl$ ELSE o$ = o$ + "color = auto" + nl$
        IF LEN(hudLabel$(e)) THEN o$ = o$ + "label = " + hudLabel$(e) + nl$
    NEXT
    f$ = AssetPath$("hud.txt")
    IF _FILEEXISTS(f$) THEN KILL f$
    fh = FREEFILE : OPEN f$ FOR BINARY AS #fh : PUT #fh, , o$ : CLOSE #fh
END SUB

' --- Monster definitions (monsters.txt, chapter 21's monster editor) ---
' One [name] section a monster, "key = value" lines - the numbers of its
' SetMonType line (chapter 3), whether it shoots, and what it may drop
SUB ReadMonsters
    f$ = AssetPath$("monsters.txt")
    IF NOT _FILEEXISTS(f$) THEN EXIT SUB
    fh = FREEFILE : OPEN f$ FOR INPUT AS #fh : t = 0
    DO UNTIL EOF(fh)
        LINE INPUT #fh, l$
        l$ = LTRIM$(RTRIM$(l$)) : IF RIGHT$(l$, 1) = CHR$(13) THEN l$ = LEFT$(l$, LEN(l$) - 1)
        IF LEFT$(l$, 1) = "[" AND RIGHT$(l$, 1) = "]" THEN
            n$ = LCASE$(MID$(l$, 2, LEN(l$) - 2)) : t = 0
            FOR k = 1 TO MON_TYPES
                IF mtypeName$(k) = n$ THEN t = k
            NEXT
        ELSEIF t > 0 AND INSTR(l$, "=") AND LEFT$(l$, 1) <> "'" THEN
            eq = INSTR(l$, "=") : k$ = LCASE$(RTRIM$(LEFT$(l$, eq - 1))) : v$ = LTRIM$(MID$(l$, eq + 1))
            v = VAL(v$)
            SELECT CASE k$
                CASE "hp" : mtypeHP(t) = v
                CASE "speed" : mtypeSpeed(t) = v
                CASE "height" : mtypeScale(t) = v
                CASE "lift" : mtypeLift(t) = v
                CASE "bob" : mtypeBob(t) = v
                CASE "reach" : mtypeReach(t) = v
                CASE "damage" : mtypeDamage(t) = v
                CASE "damage_extra" : mtypeDamageRnd(t) = v
                CASE "cooldown" : mtypeCooldown(t) = v
                CASE "shoots" : mtypeRanged(t) = (LCASE$(v$) = "yes")
                CASE "drops" ' an item's map letter (chapter 22), then the chance
                    mtypeDrop(t) = 0 : IF LEN(v$) THEN mtypeDrop(t) = INSTR("rby+ae23u*4Mqj", LEFT$(v$, 1))
                    c = INSTR(v$, " ") : IF c THEN mtypeDropChance(t) = VAL(MID$(v$, c + 1)) ELSE mtypeDropChance(t) = 1
            END SELECT
        END IF
    LOOP
    CLOSE #fh
END SUB

SUB WriteMonsters
    nl$ = CHR$(10)
    o$ = "' NEON-CASTER monsters - every kind's numbers (chapter 3's SetMonType" + nl$
    o$ = o$ + "' lines), changed here without changing the program. The monster editor" + nl$
    o$ = o$ + "' (M in the level editor, or monsters in the console) writes this file." + nl$
    o$ = o$ + "'   hp: hits to kill   speed: cells a frame (you walk 0.06, run 0.12)" + nl$
    o$ = o$ + "'   height: in walls   lift, bob: hovering   reach: how close it must be to hit" + nl$
    o$ = o$ + "'   damage + up to damage_extra - 1 more   cooldown: frames between attacks" + nl$
    o$ = o$ + "'   shoots: yes or no   drops: a pickup's map letter and the chance (0 to 1)" + nl$
    FOR t = 1 TO MON_TYPES
        o$ = o$ + nl$ + "[" + mtypeName$(t) + "]" + nl$
        o$ = o$ + "hp           = " + LTRIM$(STR$(mtypeHP(t))) + nl$
        o$ = o$ + "speed        = " + LTRIM$(STR$(mtypeSpeed(t))) + nl$
        o$ = o$ + "height       = " + LTRIM$(STR$(mtypeScale(t))) + nl$
        o$ = o$ + "lift         = " + LTRIM$(STR$(mtypeLift(t))) + nl$
        o$ = o$ + "bob          = " + LTRIM$(STR$(mtypeBob(t))) + nl$
        o$ = o$ + "reach        = " + LTRIM$(STR$(mtypeReach(t))) + nl$
        o$ = o$ + "damage       = " + LTRIM$(STR$(mtypeDamage(t))) + nl$
        o$ = o$ + "damage_extra = " + LTRIM$(STR$(mtypeDamageRnd(t))) + nl$
        o$ = o$ + "cooldown     = " + LTRIM$(STR$(mtypeCooldown(t))) + nl$
        IF mtypeRanged(t) THEN o$ = o$ + "shoots       = yes" + nl$ ELSE o$ = o$ + "shoots       = no" + nl$
        IF mtypeDrop(t) THEN o$ = o$ + "drops        = " + MID$("rby+ae23u*4Mqj", mtypeDrop(t), 1) + " " + LTRIM$(STR$(mtypeDropChance(t))) + nl$ ELSE o$ = o$ + "drops        =" + nl$
    NEXT
    f$ = AssetPath$("monsters.txt")
    IF _FILEEXISTS(f$) THEN KILL f$
    fh = FREEFILE : OPEN f$ FOR BINARY AS #fh : PUT #fh, , o$ : CLOSE #fh
END SUB

' Monster t's number f (the editor's fields), changed by d steps - or its
' name and value for the editor to show (MonsterFieldText$)
SUB MonsterField(t, f, d)
    SELECT CASE f
        CASE 1 : mtypeHP(t) = MaxOf(1, MinOf(200, mtypeHP(t) + d))
        CASE 2 : mtypeSpeed(t) = MaxOf(0, MinOf(0.15, INT((mtypeSpeed(t) + d * 0.005) * 1000 + 0.5) / 1000))
        CASE 3 : mtypeScale(t) = MaxOf(0.2, MinOf(1.8, INT((mtypeScale(t) + d * 0.05) * 100 + 0.5) / 100))
        CASE 4 : mtypeLift(t) = MaxOf(0, MinOf(1, INT((mtypeLift(t) + d * 0.05) * 100 + 0.5) / 100))
        CASE 5 : mtypeBob(t) = MaxOf(0, MinOf(0.3, INT((mtypeBob(t) + d * 0.01) * 100 + 0.5) / 100))
        CASE 6 : mtypeReach(t) = MaxOf(0, MinOf(4, INT((mtypeReach(t) + d * 0.05) * 100 + 0.5) / 100))
        CASE 7 : mtypeDamage(t) = MaxOf(0, MinOf(99, mtypeDamage(t) + d))
        CASE 8 : mtypeDamageRnd(t) = MaxOf(0, MinOf(50, mtypeDamageRnd(t) + d))
        CASE 9 : mtypeCooldown(t) = MaxOf(5, MinOf(600, mtypeCooldown(t) + d * 5))
        CASE 10 : mtypeRanged(t) = NOT mtypeRanged(t)
        CASE 11 : mtypeDrop(t) = (mtypeDrop(t) + SGN(d) + 15) MOD 15
        CASE 12 : mtypeDropChance(t) = MaxOf(0, MinOf(1, INT((mtypeDropChance(t) + d * 0.05) * 100 + 0.5) / 100))
    END SELECT
END SUB
FUNCTION MonsterFieldText$(t, f)
    SELECT CASE f
        CASE 1 : n$ = "HIT POINTS" : v$ = STR$(mtypeHP(t))
        CASE 2 : n$ = "SPEED" : v$ = STR$(mtypeSpeed(t)) + "   (you walk .06, run .12)"
        CASE 3 : n$ = "HEIGHT" : v$ = STR$(mtypeScale(t)) + " walls"
        CASE 4 : n$ = "HOVERS" : v$ = STR$(mtypeLift(t))
        CASE 5 : n$ = "BOBS" : v$ = STR$(mtypeBob(t))
        CASE 6 : n$ = "REACH" : v$ = STR$(mtypeReach(t)) + " cells"
        CASE 7 : n$ = "DAMAGE" : v$ = STR$(mtypeDamage(t))
        CASE 8 : n$ = "  + UP TO" : v$ = STR$(MaxOf(0, mtypeDamageRnd(t) - 1)) + " more"
        CASE 9 : n$ = "COOLDOWN" : v$ = STR$(mtypeCooldown(t)) + " frames (" + LTRIM$(STR$(INT(mtypeCooldown(t) / 6) / 10)) + " s)"
        CASE 10 : n$ = "SHOOTS" : IF mtypeRanged(t) THEN v$ = " YES" ELSE v$ = " NO"
        CASE 11 : n$ = "DROPS" : IF mtypeDrop(t) THEN v$ = " " + GlyphName$(MID$("rby+ae23u*4Mqj", mtypeDrop(t), 1)) ELSE v$ = " nothing"
        CASE 12 : n$ = "  CHANCE" : v$ = STR$(INT(mtypeDropChance(t) * 100)) + "%"
    END SELECT
    MonsterFieldText$ = LEFT$(n$ + SPACE$(12), 12) + v$
END FUNCTION

SUB DrawMonsterEditor(t, f, msg$)
    LINE (0, 0)-(799, 599), _RGB32(12, 6, 20), BF
    COLOR _RGB32(255, 90, 200) : _PRINTSTRING (24, 16), "MONSTER EDITOR"
    COLOR _RGB32(170, 160, 210) : _PRINTSTRING (24, 36), "PgUp/PgDn monster   Up/Down number   Left/Right change (Shift: x10)   S save   Esc back"
    ' The list of them, the one being edited lit
    FOR k = 1 TO MON_TYPES
        IF k = t THEN LINE (20, 64 + (k - 1) * 22)-(180, 82 + (k - 1) * 22), _RGB32(60, 20, 70), BF
        IF k = t THEN COLOR _RGB32(255, 255, 255) ELSE COLOR _RGB32(150, 140, 180)
        _PRINTSTRING (28, 66 + (k - 1) * 22), UCASE$(mtypeName$(k))
    NEXT
    ' Its picture, big
    slot = mtypeSprite(t) : sz = spriteSize(slot) : IF sz < 1 THEN sz = sprTex
    LINE (200, 64)-(456, 320), _RGB32(30, 24, 44), BF
    FOR y = 0 TO 63 : FOR x = 0 TO 63
        c~& = spriteTex(x * sz \ 64, y * sz \ 64, slot)
        IF _ALPHA32(c~&) > 128 THEN LINE (200 + x * 4, 64 + y * 4)-STEP(3, 3), c~&, BF
    NEXT : NEXT
    ' Its numbers
    FOR k = 1 TO ME_FIELDS
        y = 64 + (k - 1) * 22
        IF k = f THEN LINE (472, y - 2)-(788, y + 16), _RGB32(60, 20, 70), BF
        IF k = f THEN COLOR _RGB32(255, 255, 120) ELSE COLOR _RGB32(200, 200, 230)
        _PRINTSTRING (478, y), LEFT$(MonsterFieldText$(t, k), 38)
    NEXT
    COLOR _RGB32(255, 220, 120) : _PRINTSTRING (24, 560), msg$
END SUB

' Which code terminal is at cell (x, y)
FUNCTION TermAt(x, y)
    FOR k = 1 TO numTerms
        IF termX(k) = x AND termY(k) = y THEN TermAt = k
    NEXT
END FUNCTION

FUNCTION Slashes$(p$) ' (a path with Windows' backslashes)
    o$ = p$
    FOR i = 1 TO LEN(o$) : IF MID$(o$, i, 1) = "/" THEN MID$(o$, i, 1) = "\"
    NEXT
    Slashes$ = o$
END FUNCTION

' Where qb64pe is - so the puzzles can be compiled for real - or "" if it
' can't be found: the one you chose (qbChosen$), $QB64PE, every folder on
' the PATH, then the usual places
FUNCTION QB64Path$
    ' (Windows has no HOME, but USERPROFILE; its compiler is qb64pe.exe, and
    ' its PATH has ; between the folders, not :)
    h$ = ENVIRON$("HOME") : IF h$ = "" THEN h$ = ENVIRON$("USERPROFILE")
    x$ = "" : sep$ = ":" : IF INSTR(_OS$, "[WINDOWS]") THEN x$ = ".exe" : sep$ = ";"
    c$ = qbChosen$ + "|" + ENVIRON$("QB64PE") + "|"
    p$ = ENVIRON$("PATH")
    DO WHILE LEN(p$)
        s = INSTR(p$, sep$) : IF s = 0 THEN s = LEN(p$) + 1
        IF s > 1 THEN c$ = c$ + LEFT$(p$, s - 1) + "/qb64pe" + x$ + "|"
        p$ = MID$(p$, s + 1)
    LOOP
    c$ = c$ + h$ + "/git/qb64pe/qb64pe" + x$ + "|" + h$ + "/qb64pe/qb64pe" + x$ + "|" + h$ + "/git/QB64pe/qb64pe" + x$
    c$ = c$ + "|C:/qb64pe/qb64pe.exe|" + ENVIRON$("ProgramFiles") + "/qb64pe/qb64pe.exe|/Applications/qb64pe/qb64pe|" + h$ + "/Applications/qb64pe/qb64pe"
    c$ = c$ + "|/usr/local/bin/qb64pe|/usr/bin/qb64pe|/opt/qb64pe/qb64pe"
    DO WHILE LEN(c$)
        bar = INSTR(c$, "|") : IF bar = 0 THEN bar = LEN(c$) + 1
        f$ = QB64At$(LEFT$(c$, bar - 1)) : c$ = MID$(c$, bar + 1)
        IF LEN(f$) THEN QB64Path$ = f$ : EXIT FUNCTION
    LOOP
END FUNCTION

' The qb64pe at p$ - p$ itself, or the one in it if it's a folder - or ""
' if there isn't one. Quotes round it (as Windows' "Copy as path" puts
' them) and ~ for your home folder are fine.
FUNCTION QB64At$(p$)
    f$ = LTRIM$(RTRIM$(p$))
    IF LEN(f$) > 1 AND LEFT$(f$, 1) = CHR$(34) AND RIGHT$(f$, 1) = CHR$(34) THEN f$ = MID$(f$, 2, LEN(f$) - 2)
    IF LEFT$(f$, 1) = "~" THEN
        h$ = ENVIRON$("HOME") : IF h$ = "" THEN h$ = ENVIRON$("USERPROFILE")
        f$ = h$ + MID$(f$, 2)
    END IF
    IF f$ = "" THEN EXIT FUNCTION
    IF _DIREXISTS(f$) THEN
        IF RIGHT$(f$, 1) <> "/" AND RIGHT$(f$, 1) <> "\" THEN f$ = f$ + "/"
        f$ = f$ + "qb64pe" : IF INSTR(_OS$, "[WINDOWS]") THEN f$ = f$ + ".exe"
    END IF
    IF _FILEEXISTS(f$) THEN QB64At$ = f$
END FUNCTION

' The end of path p$, at most n characters ("..." where it's cut)
FUNCTION PathTail$(p$, n)
    IF LEN(p$) > n THEN PathTail$ = "..." + RIGHT$(p$, n - 3) ELSE PathTail$ = p$
END FUNCTION

' Read puzzle n$ (neon-caster/puzzles/n$.txt) - its answer, blanks and
' hints - and shuffle its lines (never leaving them all in place)
FUNCTION LoadPuzzle(n$)
    f$ = AssetPath$("puzzles/" + n$ + ".txt")
    IF NOT _FILEEXISTS(f$) THEN EXIT FUNCTION
    pzTitle$ = n$ : pzLesson$ = "" : pzExpect$ = "" : pzChapter$ = "" : pzN = 0 : pzBlanks = 0 : pzHints = 0 : sec$ = ""
    fh = FREEFILE : OPEN f$ FOR INPUT AS #fh
    DO UNTIL EOF(fh)
        LINE INPUT #fh, l$
        IF RIGHT$(l$, 1) = CHR$(13) THEN l$ = LEFT$(l$, LEN(l$) - 1)
        t$ = LTRIM$(RTRIM$(l$))
        IF LEFT$(t$, 1) = "[" AND RIGHT$(t$, 1) = "]" THEN
            sec$ = LCASE$(MID$(t$, 2, LEN(t$) - 2))
        ELSEIF sec$ = "lines" THEN
            IF LEN(t$) AND pzN < MAX_PZ_LINES THEN pzN = pzN + 1 : pzAns$(pzN) = RTRIM$(l$)
        ELSEIF LEN(t$) = 0 OR LEFT$(t$, 1) = "'" THEN
        ELSEIF sec$ = "" THEN
            eq = INSTR(t$, "=")
            IF eq THEN
                k$ = LCASE$(RTRIM$(LEFT$(t$, eq - 1))) : v$ = LTRIM$(MID$(t$, eq + 1))
                IF k$ = "title" THEN pzTitle$ = v$
                IF k$ = "lesson" THEN pzLesson$ = v$
                IF k$ = "expect" THEN pzExpect$ = v$
                IF k$ = "chapter" THEN pzChapter$ = v$
            END IF
        ELSEIF sec$ = "blanks" THEN
            sp = INSTR(t$, " ")
            IF sp AND pzBlanks < MAX_PZ_BLANKS THEN pzBlanks = pzBlanks + 1 : pzBlankLine(pzBlanks) = VAL(LEFT$(t$, sp - 1)) : pzBlankWord$(pzBlanks) = LTRIM$(MID$(t$, sp + 1)) : pzBlankIn$(pzBlanks) = ""
        ELSEIF sec$ = "hints" THEN
            IF pzHints < MAX_PZ_HINTS THEN pzHints = pzHints + 1 : pzHint$(pzHints) = t$
        END IF
    LOOP
    CLOSE #fh
    IF pzN = 0 THEN EXIT FUNCTION
    FOR i = 1 TO pzN : pzOrder(i) = i : NEXT
    FOR tries = 1 TO 20 ' (shuffled - and not left right)
        FOR i = pzN TO 2 STEP -1 : j = INT(RND * i) + 1 : SWAP pzOrder(i), pzOrder(j) : NEXT
        same = 0 : FOR i = 1 TO pzN : IF pzOrder(i) = i THEN same = same + 1
        NEXT
        IF same < pzN OR pzN < 2 THEN EXIT FOR
    NEXT
    LoadPuzzle = -1
END FUNCTION

' Line i of the puzzle as it stands now: the line in place i, its blank
' (if it has one) filled with what's been typed
FUNCTION PuzzleLine$(i)
    a = pzOrder(i) : l$ = pzAns$(a)
    FOR b = 1 TO pzBlanks
        IF pzBlankLine(b) = a THEN
            p = INSTR(l$, pzBlankWord$(b))
            IF p THEN l$ = LEFT$(l$, p - 1) + pzBlankIn$(b) + MID$(l$, p + LEN(pzBlankWord$(b)))
        END IF
    NEXT
    PuzzleLine$ = l$
END FUNCTION

' Which blank is on the line in place i (0: none)
FUNCTION PuzzleBlankOn(i)
    FOR b = 1 TO pzBlanks
        IF pzBlankLine(b) = pzOrder(i) THEN PuzzleBlankOn = b : EXIT FUNCTION
    NEXT
END FUNCTION

' After a few wrong tries: one line put in its place (or one blank filled)
SUB PuzzleFixOne
    FOR i = 1 TO pzN
        IF pzOrder(i) <> i THEN
            FOR j = i + 1 TO pzN
                IF pzOrder(j) = i THEN SWAP pzOrder(i), pzOrder(j) : EXIT SUB
            NEXT
        END IF
    NEXT
    FOR b = 1 TO pzBlanks
        IF UCASE$(pzBlankIn$(b)) <> UCASE$(pzBlankWord$(b)) THEN pzBlankIn$(b) = pzBlankWord$(b) : EXIT SUB
    NEXT
END SUB

' A line, for comparing: spaces squashed, no case
FUNCTION NormLine$(t$)
    o$ = "" : sp = -1
    FOR i = 1 TO LEN(t$)
        c$ = MID$(t$, i, 1)
        IF c$ = " " OR c$ = CHR$(9) THEN
            IF NOT sp THEN o$ = o$ + " " : sp = -1
        ELSE
            o$ = o$ + UCASE$(c$) : sp = 0
        END IF
    NEXT
    NormLine$ = RTRIM$(o$)
END FUNCTION

' The useful part of the compiler's complaint
FUNCTION PuzzleCompilerSays$(t$)
    o$ = "" : s$ = t$ + "|"
    DO WHILE LEN(s$)
        bar = INSTR(s$, "|") : l$ = LEFT$(s$, bar - 1) : s$ = MID$(s$, bar + 1)
        DO WHILE INSTR(l$, CHR$(27)) ' (its colours, out)
            e = INSTR(l$, CHR$(27)) : m = INSTR(e, l$, "m") : IF m = 0 THEN m = e
            l$ = LEFT$(l$, e - 1) + MID$(l$, m + 1)
        LOOP
        IF INSTR(l$, "[") = 1 OR INSTR(l$, "QB64-PE") OR INSTR(l$, "Beginning C++") OR LEN(LTRIM$(l$)) = 0 THEN
        ELSE
            o$ = o$ + "|" + l$
        END IF
    LOOP
    IF LEN(o$) THEN PuzzleCompilerSays$ = MID$(o$, 2) ELSE PuzzleCompilerSays$ = "(no message)"
END FUNCTION

' The puzzle screen: an old green terminal - the program (the line chosen
' lit, blanks as ____ or what's typed), the lesson, the hints so far, and
' what the last run said
SUB DrawPuzzle(sel, typing, qb$)
    LINE (0, 0)-(799, 599), _RGB32(2, 10, 6), BF
    FOR y = 0 TO 599 STEP 3 : LINE (0, y)-(799, y), _RGB32(0, 0, 0) : NEXT
    LINE (16, 12)-(783, 587), _RGB32(40, 120, 60), B
    COLOR _RGB32(255, 70, 90) : _PRINTSTRING (28, 22), "NEXUS SECURITY  -  PROGRAM REPAIR  -  LOCKDOWN"
    COLOR _RGB32(120, 255, 150) : _PRINTSTRING (28, 42), pzTitle$ + "   (" + pzLesson$ + ")"
    FOR i = 1 TO pzN
        y = PZ_TOP + (i - 1) * 18
        l$ = pzAns$(pzOrder(i)) : b = PuzzleBlankOn(i)
        IF b THEN
            p = INSTR(l$, pzBlankWord$(b))
            fill$ = pzBlankIn$(b) : IF fill$ = "" THEN fill$ = STRING$(LEN(pzBlankWord$(b)), "_")
            IF typing AND i = sel AND INT(TIMER * 3) MOD 2 THEN fill$ = fill$ + "_"
            l$ = LEFT$(l$, p - 1) + "[" + fill$ + "]" + MID$(l$, p + LEN(pzBlankWord$(b)))
        END IF
        IF i = sel THEN LINE (24, y - 2)-(560, y + 15), _RGB32(20, 70, 40), BF
        IF LEFT$(LTRIM$(l$), 1) = "'" THEN COLOR _RGB32(110, 170, 120) ELSE COLOR _RGB32(170, 255, 190)
        _PRINTSTRING (30, y), RIGHT$(" " + LTRIM$(STR$(i)), 2) + "  " + LEFT$(l$, 62)
    NEXT
    ' The hints so far
    y = 70
    COLOR _RGB32(255, 220, 120) : _PRINTSTRING (576, y), "HINTS (H)"
    FOR h = 1 TO pzShown
        WrapText 576, y + 18 + (h - 1) * 54, 24, "- " + pzHint$(h), _RGB32(230, 210, 150)
    NEXT
    ' What happened
    oy = PZ_TOP + pzN * 18 + 20 : IF oy < 360 THEN oy = 360
    LINE (24, oy - 4)-(775, 540), _RGB32(4, 30, 14), BF
    o$ = pzOut$ + "|" : yy = oy
    DO WHILE LEN(o$) AND yy < 530
        bar = INSTR(o$, "|")
        COLOR _RGB32(200, 255, 210) : _PRINTSTRING (30, yy), LEFT$(LEFT$(o$, bar - 1), 92) : yy = yy + 16 : o$ = MID$(o$, bar + 1)
    LOOP
    COLOR _RGB32(110, 170, 120)
    _PRINTSTRING (28, 552), "Up/Down choose   Shift+Up/Down move   Enter fill blank   F5 run   H hint   Esc leave"
    IF qb$ = "" THEN m$ = "(no qb64pe: checked against the answer - Esc, SETTINGS > QB64PE COMPILER to add yours)" ELSE m$ = "compiles with: " + PathTail$(qb$, 77)
    _PRINTSTRING (28, 570), LEFT$(m$, 92)
END SUB

' Which data station is at cell (x, y) (0: none)
FUNCTION StationAt(x, y)
    FOR k = 1 TO numStations
        IF stationX(k) = x AND stationY(k) = y THEN StationAt = k : EXIT FUNCTION
    NEXT
END FUNCTION

' The data station nearest cell (x, y) - the one a sealed door belongs to
FUNCTION StationNear(x, y)
    best = 0 : bestD = 1E+9
    FOR k = 1 TO numStations
        d = (stationX(k) - x) ^ 2 + (stationY(k) - y) ^ 2
        IF d < bestD THEN bestD = d : best = k
    NEXT
    StationNear = best
END FUNCTION

' Into the network (goIn): every wall, door, floor and ceiling picture is
' kept in texBak and replaced by a neon grid; out: put back. OpenGL
' is told to send them all again (glRetexVersion) - but not to rebuild its
' world, which hasn't moved
SUB CyberTextures(goIn)
    FOR slot = 1 TO T_SLOTS
        IF goIn THEN
            FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1 : texBak(x, y, slot) = texture(x, y, slot) : NEXT : NEXT
            SELECT CASE slot
                CASE 1, 3, 5 : MakeCyberTex slot, 255, 40, 210, 32 ' Walls: magenta...
                CASE 2, 4, 6 : MakeCyberTex slot, 40, 230, 255, 32 ' ...and cyan
                CASE T_DOOR TO T_SPLIT : MakeCyberTex slot, 255, 200, 40, 16 ' Doors: gold, a finer grid
                CASE T_EXIT : MakeCyberTex slot, 60, 255, 120, 16
                CASE T_FLOOR + 1 TO T_FLOOR + 4 : MakeCyberTex slot, 40, 200, 255, 32 ' The floor: a cyan grid
                CASE T_CEIL + 1 TO T_CEIL + 2 : MakeCyberTex slot, 110, 40, 200, 64 ' The ceiling: dim violet
                CASE T_JACK : MakeCyberTex slot, 255, 255, 255, 16
                CASE ELSE : MakeCyberTex slot, 200, 200, 255, 64
            END SELECT
        ELSE
            FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1 : texture(x, y, slot) = texBak(x, y, slot) : NEXT : NEXT
        END IF
    NEXT
    glRetexVersion = glRetexVersion + 1
END SUB

' A grid picture for the network, into texture slot slot: near-black, with
' bright lines (colour r, g, b) every cell'th texel and round the edge,
' fainter ones in between, and a dot of light where lines cross
SUB MakeCyberTex(slot, r, g, b, cell)
    sk = texSize \ 128 ' (designed 128 pixels across)
    FOR yy = 0 TO texSize - 1 : FOR xx = 0 TO texSize - 1
        x = xx \ sk : y = yy \ sk
        ex = x MOD cell : ey = y MOD cell
        k = 0
        IF ex < 2 OR ey < 2 THEN k = 1 ' (the grid's lines)
        IF (x \ 4) MOD (cell \ 4) = 0 OR (y \ 4) MOD (cell \ 4) = 0 THEN IF k = 0 AND ((x + y) MOD 4 = 0) THEN k = 0.18 ' (faint dots between)
        IF x < 3 OR y < 3 OR x > 124 OR y > 124 THEN k = 1 ' (the edge)
        IF ex < 2 AND ey < 2 THEN k = 1.6 ' (crossings glow)
        texture(xx, yy, slot) = _RGB32(MinOf(255, 6 + r * k), MinOf(255, 2 + g * k), MinOf(255, 14 + b * k))
    NEXT : NEXT
END SUB

' Each pane of glass: which way it runs - along x if there's wall (or more
' glass) to its left and right, else along y - and the list of them all
SUB AssignGlass
    numGlass = 0
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF glassHP(x, y) > 0 THEN
            l = IsWall(x - 1, y) OR glassHP(x - 1, y) > 0 : r = IsWall(x + 1, y) OR glassHP(x + 1, y) > 0
            IF l AND r THEN glassDir(x, y) = 1 ELSE glassDir(x, y) = 2
            IF numGlass < MAX_GLASS THEN numGlass = numGlass + 1 : glassListX(numGlass) = x : glassListY(numGlass) = y
        END IF
    NEXT : NEXT
END SUB

' Is map point (x, y) inside a pane of glass (its thickness, GLASS_HALF
' either side of the middle of its cell)?
FUNCTION InGlass(x, y)
    cx = INT(x) : cy = INT(y)
    IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT FUNCTION
    IF glassHP(cx, cy) <= 0 THEN EXIT FUNCTION
    IF glassDir(cx, cy) = 1 THEN InGlass = ABS(y - cy - 0.5) < GLASS_HALF ELSE InGlass = ABS(x - cx - 0.5) < GLASS_HALF
END FUNCTION

' Is there glass on the straight line from (x1, y1) to (x2, y2)? Checked
' every 0.08 of a cell - thinner than the glass, so it can't be missed
FUNCTION GlassBetween(x1, y1, x2, y2)
    IF numGlass = 0 THEN EXIT FUNCTION
    steps = INT(SQR((x2 - x1) ^ 2 + (y2 - y1) ^ 2) / 0.08) + 1
    FOR i = 1 TO steps - 1
        IF InGlass(x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps) THEN GlassBetween = -1 : EXIT FUNCTION
    NEXT
END FUNCTION

' Where does a ray from (px, py), going (rdx, rdy), meet the pane of glass
' in cell (cx, cy)? Its distance t (in the raycaster's units: perpWallDist's)
' and u, where along the pane (0 to 1) - if it does, inside this cell
FUNCTION GlassRay(cx, cy, px, py, rdx, rdy, t, u)
    IF glassDir(cx, cy) = 1 THEN
        IF ABS(rdy) < 0.00001 THEN EXIT FUNCTION
        t = (cy + 0.5 - py) / rdy : u = px + t * rdx - cx
    ELSE
        IF ABS(rdx) < 0.00001 THEN EXIT FUNCTION
        t = (cx + 0.5 - px) / rdx : u = py + t * rdy - cy
    END IF
    GlassRay = t > 0.001 AND u >= 0 AND u < 1
END FUNCTION

' The glass picture, into sprite slot slot: faintly blue, mostly see-
' through (low alpha), two streaks of shine across it, and a solid metal
' frame top and bottom (and a thin upright at each edge, so panes side by
' side look like a row of windows). Cracked: white cracks spreading from a
' point
SUB MakeGlass(slot, cracked)
    spriteSize(slot) = sprTex : gk = sprTex \ 64 ' (designed 64 pixels across: each of those gk x gk)
    FOR yy = 0 TO sprTex - 1 : FOR xx = 0 TO sprTex - 1
        x = xx \ gk : y = yy \ gk
        a = 40 : r = 150 : g = 215 : b = 235
        st = (x + INT(y * 0.6)) MOD 64
        IF st >= 12 AND st < 16 THEN a = 95 : r = 225 : g = 248 : b = 255
        IF st >= 20 AND st < 21 THEN a = 75 : r = 210 : g = 240 : b = 255
        IF y < 4 OR y > 59 THEN a = 255 : r = 80 : g = 90 : b = 108 : IF y = 3 OR y = 60 THEN r = 130 : g = 145 : b = 165
        IF x = 0 OR x = 63 THEN a = 255 : r = 70 : g = 80 : b = 96
        spriteTex(xx, yy, slot) = _RGBA32(r, g, b, a)
    NEXT : NEXT
    IF cracked THEN
        FOR k = 0 TO 8 ' Cracks: wandering lines out from (40, 26)
            ang = k * 0.71 + 0.4 * SIN(k * 3.7) : cx = 40 : cy = 26
            FOR stp = 1 TO 26 + (k MOD 3) * 8
                ang = ang + 0.25 * SIN(stp * 1.3 + k)
                cx = cx + COS(ang) : cy = cy + SIN(ang)
                IF cx >= 1 AND cy >= 4 AND cx < 63 AND cy < 60 THEN
                    FOR yy = 0 TO gk - 1 : FOR xx = 0 TO gk - 1 : spriteTex(INT(cx) * gk + xx, INT(cy) * gk + yy, slot) = _RGBA32(235, 250, 255, 210) : NEXT : NEXT
                END IF
            NEXT
        NEXT
    END IF
END SUB

SUB AssignClosets
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF closetCell(x, y) = -1 THEN
            closetCell(x, y) = 0
            FOR ev = 1 TO numEvents
                IF evType(ev) = EV_CLOSET AND closetCell(x, y) = 0 THEN
                    IF x >= evX0(ev) - 3 AND x <= evX1(ev) + 3 AND y >= evY0(ev) - 3 AND y <= evY1(ev) + 3 THEN closetCell(x, y) = ev
                END IF
            NEXT
            FOR k = 1 TO 4
                nx = x + (k = 1) - (k = 2) : ny = y + (k = 3) - (k = 4)
                v = worldMap(nx, ny)
                IF v > 0 AND v <> 2 AND closetCell(nx, ny) = 0 THEN worldMap(x, y) = v
            NEXT
        END IF
    NEXT : NEXT
END SUB

' Closet event ev's secret walls slide away: floor where they stood (and
' the monsters behind them wake). loud: with a rumble and dust (not when
' a saved game puts it back as it was). The level's light and OpenGL's
' world mesh are worked out again for the new shape.
SUB OpenClosets(ev, loud)
    n = 0
    FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
        IF closetCell(x, y) = ev THEN
            worldMap(x, y) = 0 : closetCell(x, y) = 0 : n = n + 1
            IF loud THEN SpawnSparks x + 0.5, y + 0.5, 0.3, 10, 160, 150, 140
        END IF
    NEXT : NEXT
    IF n = 0 THEN EXIT SUB
    IF loud THEN
        PlaySfx sndCloset&, 1
        FOR j = 1 TO numMonsters
            IF monsterState(j) = 0 THEN
                IF monsterX(j) >= evX0(ev) - 4 AND monsterX(j) <= evX1(ev) + 5 AND monsterY(j) >= evY0(ev) - 4 AND monsterY(j) <= evY1(ev) + 5 THEN monsterState(j) = 1 : monsterTimer(j) = 20
            END IF
        NEXT
    END IF
    BuildLights : glMeshVersion = glMeshVersion + 1
END SUB

' The thieves' way home: from the cells outside every hoard's doors, how
' many steps to each open cell (a flood fill, as the moving lights' -
' chapter 24), through doors that need no keycard. 30000: no way.
SUB BuildThiefWay
    FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE : thiefDist(x, y) = 30000 : NEXT : NEXT
    head = 0 : tail = 0
    FOR ev = 1 TO numEvents
        IF evType(ev) = EV_HOARD THEN
            FOR y = evY0(ev) - 1 TO evY1(ev) + 1 : FOR x = evX0(ev) - 1 TO evX1(ev) + 1
                IF x > 0 AND y > 0 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN
                    IF worldMap(x, y) = 2 THEN ' A door into the hoard: the cells outside it are home
                        FOR k = 1 TO 4
                            nx = x + (k = 1) - (k = 2) : ny = y + (k = 3) - (k = 4)
                            IF NOT InRoom(ev, nx + 0.5, ny + 0.5) AND worldMap(nx, ny) <= 0 AND thiefDist(nx, ny) > 0 THEN
                                thiefDist(nx, ny) = 0 : fillX(tail) = nx : fillY(tail) = ny : tail = tail + 1
                            END IF
                        NEXT
                    END IF
                END IF
            NEXT : NEXT
        END IF
    NEXT
    DO WHILE head < tail
        x = fillX(head) : y = fillY(head) : head = head + 1
        FOR k = 1 TO 4
            nx = x + (k = 1) - (k = 2) : ny = y + (k = 3) - (k = 4)
            IF nx > 0 AND ny > 0 AND nx < MAP_SIZE - 1 AND ny < MAP_SIZE - 1 THEN
                v = worldMap(nx, ny) : ok = (v <= 0 AND diagCorner(nx, ny) = 0)
                IF v = 2 THEN ok = (doorKey(nx, ny) = 0 AND doorType(nx, ny) <> DOOR_EXIT)
                IF ok AND thiefDist(nx, ny) > thiefDist(x, y) + 1 THEN
                    thiefDist(nx, ny) = thiefDist(x, y) + 1 : fillX(tail) = nx : fillY(tail) = ny : tail = tail + 1
                END IF
            END IF
        NEXT
    LOOP
END SUB

' Is laser event ev on now (or about to be)?
FUNCTION LaserOn(ev)
    IF evB(ev) = 0 THEN LaserOn = -1 : EXIT FUNCTION
    LaserOn = (evTimer(ev) MOD (evA(ev) + evB(ev))) < evA(ev)
END FUNCTION

FUNCTION LaserSoon(ev)
    IF evB(ev) = 0 THEN EXIT FUNCTION
    p = evTimer(ev) MOD (evA(ev) + evB(ev))
    LaserSoon = p >= evA(ev) + evB(ev) - 30 ' (the last half second before it comes on: it flickers)
END FUNCTION

' Where cutter event ev's beam is now: it runs across the room's short way
' and sweeps along its long way (cutAlongX: sweeping along x, so the beam
' is a line of constant x), there and back every a frames
SUB CutterAt(ev, cx, cy, alongX)
    alongX = (evX1(ev) - evX0(ev)) >= (evY1(ev) - evY0(ev))
    f = 0.5 - 0.5 * COS(evTimer(ev) * 6.2832 / evA(ev))
    IF alongX THEN cx = evX0(ev) + 0.3 + (evX1(ev) - evX0(ev) + 0.4) * f : cy = (evY0(ev) + evY1(ev) + 1) / 2 ELSE cy = evY0(ev) + 0.3 + (evY1(ev) - evY0(ev) + 0.4) * f : cx = (evX0(ev) + evX1(ev) + 1) / 2
END SUB

' The laser beam's picture: three bright red lines across, at knee, chest
' and head height, with a glow round each - into sprite slot slot
SUB MakeLaser(slot)
    spriteSize(slot) = sprTex : k = sprTex \ 64 ' (designed 64 pixels across: each of those k x k)
    FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1
        col~& = 0 : yd = y \ k : xd = x \ k
        FOR beam = 0 TO 2 ' Three beams: white-hot, red either side, a dotted dark red edge
            dy = ABS(yd - (14 + beam * 18))
            IF dy = 0 THEN col~& = _RGB32(255, 240, 230)
            IF dy = 1 THEN col~& = _RGB32(255, 60, 60)
            IF dy = 2 AND (xd MOD 3) THEN col~& = _RGB32(170, 20, 40)
        NEXT
        spriteTex(x, y, slot) = col~&
    NEXT : NEXT
END SUB

' One more pickup, of kind kind, at (x, y) - a reward
SUB DropItem(kind, x, y)
    IF numItems >= MAX_ITEMS THEN EXIT SUB
    numItems = numItems + 1
    itemX(numItems) = INT(x) + 0.5 : itemY(numItems) = INT(y) + 0.5 : itemKind(numItems) = kind : itemOn(numItems) = -1
    SpawnSparks itemX(numItems), itemY(numItems), 0.4, 24, 255, 230, 120
END SUB

' Which way door (cx, cy) runs: 0 along x (walls at its ends, west and
' east; its faces look north and south), 1 along y
FUNCTION DoorAcross(cx, cy)
    IF cx > 0 AND cx < MAP_SIZE - 1 THEN
        IF IsWall(cx - 1, cy) OR IsWall(cx + 1, cy) THEN EXIT FUNCTION
    END IF
    DoorAcross = 1
END FUNCTION

' Where does a ray from (px, py), going (rdx, rdy), meet door (cx, cy)'s
' slab? It's easiest in the door's own directions: "a" along the door (0
' at one end of the doorway, 1 at the other) and "n" through it (0 on its
' middle line, the slab's faces at -half and +half). Then:
'   its face: the one towards the ray, at n = -half (or +half) - hit if
'   the door's still there at that a (a sliding door covers a from
'   DoorShown to 1; a split door's halves cover the two ends)
'   an edge: missing the face, the ray goes through the gap - and meets a
'   door's edge if it crosses that edge's a between the faces
' Returns 0 (missed), 1 (its face), 2 (an edge) or 3 (a lifted shutter:
' drawn later). t: how far (in the ray's own steps, so as perpWallDist);
' u: where along the face (or across the edge, 0..1); side: 0 for a face
' looking east or west, 1 north or south (chapter 15 shades those
' darker); (litX, litY): the cell whose light falls on it; back: how far
' to the far face (for a shutter's underside).
FUNCTION DoorRay(cx, cy, px, py, rdx, rdy, t, u, side, litX, litY, back)
    half = DOOR_THICK / 2 : shown = DoorShown(cx, cy) : kind = doorType(cx, cy)
    IF DoorAcross(cx, cy) = 0 THEN
        pa = px - cx : pn = py - cy - 0.5 : da = rdx : dn = rdy : faceSide = 1 : edgeSide = 0
    ELSE
        pa = py - cy : pn = px - cx - 0.5 : da = rdy : dn = rdx : faceSide = 0 : edgeSide = 1
    END IF
    IF dn <> 0 THEN ' Its face
        tFace = (-half * SGN(dn) - pn) / dn
        IF tFace > 0 THEN
            a = pa + tFace * da
            IF a >= 0 AND a <= 1 THEN
                covered = 0
                SELECT CASE kind
                    CASE DOOR_SLIDE : covered = a >= shown
                    CASE DOOR_SPLIT : covered = a <= 0.5 - shown / 2 OR a >= 0.5 + shown / 2
                    CASE ELSE : covered = -1
                END SELECT
                IF covered THEN
                    t = tFace : u = a : side = faceSide : back = (half * SGN(dn) - pn) / dn
                    IF faceSide = 1 THEN litX = cx : litY = cy - SGN(dn) ELSE litX = cx - SGN(dn) : litY = cy
                    DoorRay = 1
                    IF kind = DOOR_SHUTTER AND shown > 0 THEN DoorRay = 3
                    EXIT FUNCTION
                END IF
            END IF
        END IF
    END IF
    IF da <> 0 AND kind <> DOOR_SHUTTER THEN ' An edge, seen through the gap
        IF kind = DOOR_SLIDE THEN
            IF da > 0 THEN e = shown ELSE EXIT FUNCTION ' (its one edge faces back towards a = 0)
        ELSE
            IF da > 0 THEN e = 0.5 + shown / 2 ELSE e = 0.5 - shown / 2
        END IF
        tEdge = (e - pa) / da
        IF tEdge > 0 THEN
            n = pn + tEdge * dn
            IF ABS(n) <= half THEN
                t = tEdge : u = (n + half) / (2 * half) : side = edgeSide : litX = cx : litY = cy
                DoorRay = 2
            END IF
        END IF
    END IF
END FUNCTION

' A hunting monster about to step into door (cx, cy): open it - unless it
' needs a keycard (or it's the exit). An open door being shut opens again,
' and one waiting starts its wait again, so it's open while they come
' through. (You hear it, quieter further away: you're at (px, py).)
SUB MonsterDoor(cx, cy, px, py)
    IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT SUB
    IF worldMap(cx, cy) <> 2 OR doorType(cx, cy) = DOOR_EXIT OR doorKey(cx, cy) <> 0 OR doorLock(cx, cy) THEN EXIT SUB
    IF doorMove(cx, cy) = 1 THEN EXIT SUB ' (opening already)
    IF doorOpen(cx, cy) >= 1 THEN doorWait(cx, cy) = DoorHold(doorType(cx, cy)) : EXIT SUB
    IF doorOpen(cx, cy) = 0 THEN doorOpen(cx, cy) = 0.01
    doorMove(cx, cy) = 1
    SfxAt DoorSnd&(doorType(cx, cy)), cx + 0.5, cy + 0.5, px, py
END SUB

FUNCTION DoorSnd&(kind)
    SELECT CASE kind
        CASE DOOR_SHUTTER : DoorSnd& = sndShutter&
        CASE DOOR_SPLIT : DoorSnd& = sndSplit&
        CASE ELSE : DoorSnd& = sndDoor&
    END SELECT
END FUNCTION

' Is anyone in door (dx, dy)'s doorway - you (at px, py) or a monster
' still standing - so it mustn't shut? (Your body reaches PLAYER_RADIUS
' past your middle, so you can be in it while your middle is next door.)
FUNCTION DoorBlocked(dx, dy, px, py)
    edge = 0.5 + PLAYER_RADIUS
    IF ABS(px - (dx + 0.5)) < edge AND ABS(py - (dy + 0.5)) < edge THEN DoorBlocked = -1 : EXIT FUNCTION
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 2 THEN
            IF ABS(monsterX(i) - (dx + 0.5)) < 0.85 AND ABS(monsterY(i) - (dy + 0.5)) < 0.85 THEN DoorBlocked = -1 : EXIT FUNCTION
        END IF
    NEXT
END FUNCTION

FUNCTION Walkable%(x, y)
    cellX = INT(x) : cellY = INT(y)
    IF diagCorner(cellX, cellY) THEN Walkable% = NOT InDiagonalWall(diagCorner(cellX, cellY), x - cellX, y - cellY) : EXIT FUNCTION
    deco = decoCell(cellX, cellY) : IF cyberOn THEN deco = 0 ' (the network has none)
    IF deco THEN
        IF decoKind(deco) <> DK_BODY AND (x - decoX(deco)) ^ 2 + (y - decoY(deco)) ^ 2 < DECO_RADIUS * DECO_RADIUS THEN EXIT FUNCTION
    END IF
    IF glassHP(cellX, cellY) > 0 THEN IF InGlass(x, y) THEN EXIT FUNCTION
    IF walkFromHaz = 10 THEN IF FloorHazard(cellX, cellY) = HAZ_BURN THEN EXIT FUNCTION ' (a monster, not in fire: it won't step in)
    IF walkFromHaz >= 10 THEN IF floorH(cellX, cellY) <= PIT_DEPTH THEN EXIT FUNCTION ' (...nor off the edge of a pit with no bottom)
    IF NOT levelFlat AND walkZ > -900 THEN ' Heights: too high a step up, or too little room
        IF floorH(cellX, cellY) > walkZ + STEP_UP THEN EXIT FUNCTION
        IF ceilH(cellX, cellY) - MaxOf(floorH(cellX, cellY), walkZ) < BODY_H THEN EXIT FUNCTION
    END IF
    Walkable% = worldMap(cellX, cellY) <= 0 OR doorOpen(cellX, cellY) > 0.8
END FUNCTION

' What a cell's floor does to you, by its picture's name: HAZ_BURN (molten,
' lava), HAZ_WADE (murky water, slime) - or 0. (Not in the network.)
FUNCTION FloorHazard(cx, cy)
    IF cyberOn OR cx < 0 OR cy < 0 OR cx > MAP_SIZE OR cy > MAP_SIZE THEN EXIT FUNCTION
    IF worldMap(cx, cy) > 0 THEN EXIT FUNCTION
    n$ = texName$(floorTex(cx, cy))
    IF INSTR(n$, "molten") OR INSTR(n$, "lava") THEN FloorHazard = HAZ_BURN : EXIT FUNCTION
    IF INSTR(n$, "murky") OR INSTR(n$, "slime") THEN FloorHazard = HAZ_WADE
END FUNCTION

' Is map point (x, y) inside a wall (doors don't count)? Like IsWall, but
' for a point, so the open half of a diagonal cell isn't solid.
FUNCTION SolidAt(x, y)
    cellX = INT(x) : cellY = INT(y)
    IF diagCorner(cellX, cellY) THEN SolidAt = InDiagonalWall(diagCorner(cellX, cellY), x - cellX, y - cellY) ELSE SolidAt = IsWall(cellX, cellY)
END FUNCTION

' Is (u, v) - a point inside a diagonal wall's cell, 0 to 1 each way - in
' its solid half? corner is the solid corner (see diagCorner). The diagonal
' from bottom-left to top-right is the line u + v = 1, and from top-left to
' bottom-right u = v, so which side a point is on is just a comparison.
FUNCTION InDiagonalWall(corner, u, v)
    SELECT CASE corner
        CASE 1 : InDiagonalWall = u + v < 1
        CASE 2 : InDiagonalWall = u > v
        CASE 3 : InDiagonalWall = u + v > 1
        CASE 4 : InDiagonalWall = u < v
    END SELECT
END FUNCTION

' How far along a ray from (fromX, fromY), heading (rayX, rayY), it crosses
' the diagonal of the cell (cellX, cellY) - if that's between enterDist and
' exitDist, while the ray is inside the cell; -1 if it isn't.
' A point on the ray is (fromX + t * rayX, fromY + t * rayY). Put it into
' the diagonal's equation - X + Y = cellX + cellY + 1 for "/", or
' X - Y = cellX - cellY for "\" - and solve for t. Measured this way t is
' the same kind of distance as the raycaster's perpWallDist.
FUNCTION DiagonalHit(corner, cellX, cellY, fromX, fromY, rayX, rayY, enterDist, exitDist)
    DiagonalHit = -1
    IF corner = 1 OR corner = 3 THEN ' "/" : u + v = 1
        denom = rayX + rayY : IF denom = 0 THEN EXIT FUNCTION
        hitDist = (cellX + cellY + 1 - fromX - fromY) / denom
    ELSE ' "\" : u = v
        denom = rayX - rayY : IF denom = 0 THEN EXIT FUNCTION
        hitDist = (cellX - cellY - fromX + fromY) / denom
    END IF
    IF hitDist >= enterDist AND hitDist <= exitDist THEN DiagonalHit = hitDist
END FUNCTION

' Is the edge from (x1, y1) to (x2, y2) clear? Checks both ends and the
' middle (the middle catches the point of a diagonal wall poking in between).
FUNCTION EdgeFree(x1, y1, x2, y2)
    EdgeFree = Walkable(x1, y1) AND Walkable(x2, y2) AND Walkable((x1 + x2) / 2, (y1 + y2) / 2)
END FUNCTION

' Is a body (radius PLAYER_RADIUS) at (x, y) clear of walls all round?
FUNCTION BoxFree(x, y)
    rad = PLAYER_RADIUS
    BoxFree = EdgeFree(x - rad, y - rad, x + rad, y - rad) AND EdgeFree(x - rad, y + rad, x + rad, y + rad) AND Walkable(x - rad, y) AND Walkable(x + rad, y)
END FUNCTION

' Any diagonal wall in the 3 x 3 cells around (x, y)?
FUNCTION NearDiagonal(x, y)
    FOR cellY = INT(y) - 1 TO INT(y) + 1 : FOR cellX = INT(x) - 1 TO INT(x) + 1
        IF diagCorner(cellX, cellY) THEN NearDiagonal = -1 : EXIT FUNCTION
    NEXT : NEXT
END FUNCTION

' Move a body (radius PLAYER_RADIUS) at (x, y) by (moveX, moveY) - you, or a
' monster. One axis at a time, so it slides along walls (chapter 9): the X
' move happens if the body's leading edge would be clear, then the Y move
' the same way. Against a diagonal wall both can be blocked at once, so
' then it tries sliding along each 45-degree line instead: the part of the
' move that points along (1, slope).
SUB MoveBody(x, y, moveX, moveY)
    oldX = x : oldY = y
    edgeX = x + moveX + SGN(moveX) * PLAYER_RADIUS
    IF EdgeFree(edgeX, y - PLAYER_RADIUS, edgeX, y + PLAYER_RADIUS) THEN x = x + moveX
    edgeY = y + moveY + SGN(moveY) * PLAYER_RADIUS
    IF EdgeFree(x - PLAYER_RADIUS, edgeY, x + PLAYER_RADIUS, edgeY) THEN y = y + moveY
    IF x = oldX AND y = oldY AND (moveX <> 0 OR moveY <> 0) AND NearDiagonal(x, y) THEN
        FOR slope = -1 TO 1 STEP 2 ' The move along each 45 degree line, (1, sl)
            along = (moveX + moveY * slope) / 2
            IF BoxFree(x + along, y + along * slope) THEN x = x + along : y = y + along * slope : EXIT SUB
        NEXT
    END IF
END SUB

' Can a monster at (x1, y1) see (x2, y2)? Step along the line between them,
' a tenth of a cell at a time; any wall or shut door on the way blocks it.
FUNCTION CanSee(x1, y1, x2, y2)
    dx = x2 - x1 : dy = y2 - y1 : dist = SQR(dx * dx + dy * dy)
    steps = INT(dist / 0.1) + 1
    z1 = floorH(INT(x1), INT(y1)) + 0.5 : z2 = floorH(INT(x2), INT(y2)) + 0.5 ' (heights: eye to eye)
    FOR i = 1 TO steps
        cellX = INT(x1 + dx * i / steps) : cellY = INT(y1 + dy * i / steps)
        IF SolidAt(x1 + dx * i / steps, y1 + dy * i / steps) THEN EXIT FUNCTION
        IF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) <= 0.8 THEN EXIT FUNCTION
        IF NOT levelFlat THEN ' (a ledge or a low ceiling in the way)
            z = z1 + (z2 - z1) * i / steps
            IF floorH(cellX, cellY) > z OR ceilH(cellX, cellY) < z THEN EXIT FUNCTION
        END IF
    NEXT
    CanSee = -1
END FUNCTION

' === FILES AND SOUND ==========================================================

' The path to neon-caster/<file$>: from the current folder, or else from the
' folder the program itself is in (COMMAND$(0) is its own path), so the game
' runs whichever folder you start it from.
FUNCTION AssetPath$(file$)
    path$ = "neon-caster/" + file$
    IF NOT _FILEEXISTS(path$) THEN ' Fall back TO the folder NEXT TO the EXE
        exe$ = COMMAND$(0) : i = _INSTRREV(exe$, "/") : IF i = 0 THEN i = _INSTRREV(exe$, "\")
        path$ = LEFT$(exe$, i) + "neon-caster/" + file$
    END IF
    AssetPath$ = path$
END FUNCTION

' A sound from neon-caster/sfx/. A missing file gives 0, and PlaySfx skips
' 0, so the game still runs - silently - without its sounds.
FUNCTION LoadSnd&(file$)
    path$ = AssetPath$("sfx/" + file$)
    IF _FILEEXISTS(path$) THEN LoadSnd& = _SNDOPEN(path$, "noasync") ' (see LoadMusic&)
END FUNCTION

' Play a copy of a sound (_SNDPLAYCOPY), so the same one can overlap itself
' - footsteps, a fast gun. vol! goes from 0 to 1, and is turned down by the
' SFX VOLUME setting.
SUB PlaySfx(snd&, vol!)
    PlaySfxPan snd&, vol!, 0
END SUB

' ...and panned: pan! -1 all left, 0 the middle, 1 all right. Then THE
' LIMITER (SETTINGS > AUDIO): a sound already started this frame isn't
' started again (twelve pellets hitting at once are one hit, not twelve
' stacked up), and while a lot is playing - sfxLoad, the volumes of the
' sounds just started, dying away a little each frame (SfxFrame) - each
' new one is turned down to keep the total under SFX_HEADROOM, so a big
' fight gets busier, not deafening. It also ducks while NEXUS speaks.
SUB PlaySfxPan(snd&, vol!, pan!)
    IF snd& <= 0 THEN EXIT SUB
    v! = vol! * setting(SET_SFX) / 100
    IF setting(SET_LIMITER) THEN
        ' (The game loop calls SfxFrame every frame; loops of their own -
        ' the menu, the sector tally, the editor - don't. So if a frame's
        ' worth of time has gone by without one, it catches up here first,
        ' or every sound since would count as "this frame" and be dropped.)
        t! = TIMER(0.001)
        IF t! - sfxFrameT! > 0.015 OR t! < sfxFrameT! THEN
            frames = (t! - sfxFrameT!) * 60 : IF frames < 0 OR frames > 600 THEN frames = 600
            sfxLoad! = sfxLoad! * 0.82 ^ frames : sfxThisN = 0 : sfxFrameT! = t!
        END IF
        FOR k = 1 TO sfxThisN
            IF sfxThis&(k) = snd& THEN EXIT SUB ' (once a frame)
        NEXT
        IF sfxThisN < 32 THEN sfxThisN = sfxThisN + 1 : sfxThis&(sfxThisN) = snd&
        IF sfxLoad! + v! > SFX_HEADROOM THEN v! = v! * SFX_HEADROOM / (sfxLoad! + v!)
        IF speechUntil! > TIMER THEN v! = v! * 0.55 ' (ducked under speech)
        sfxLoad! = sfxLoad! + v!
    END IF
    IF v! <= 0.003 THEN EXIT SUB
    IF pan! = 0 OR setting(SET_SPATIAL) = 0 THEN
        _SNDPLAYCOPY snd&, v!
    ELSE
        _SNDPLAYCOPY snd&, v!, pan!
    END IF
END SUB

' Once a frame: the limiter's memory of what's playing fades
SUB SfxFrame
    sfxLoad! = sfxLoad! * 0.82 : sfxThisN = 0 : sfxFrameT! = TIMER(0.001)
END SUB

' A sound made at (x, y), heard by you at (listenX, listenY), facing
' (earDX, earDY): SFX_RANGE cells away it's silent (SfxAtRange for another
' reach). Nearer, it gets louder the way sound does - quickly at first,
' (1 - d / range) squared - and a wall in the way muffles it to a third.
' With 3D SOUND on it's also panned to the side it's on (how far round to
' your right or left - a sound straight behind you is in the middle).
SUB SfxAt(snd&, x, y, listenX, listenY)
    SfxAtRange snd&, x, y, listenX, listenY, SFX_RANGE
END SUB

SUB SfxAtRange(snd&, x, y, listenX, listenY, range)
    vol! = SfxVolAt!(x, y, listenX, listenY, range) : IF vol! <= 0 THEN EXIT SUB ' (too far off to hear)
    dx = x - listenX : dy = y - listenY : d = SQR(dx * dx + dy * dy)
    pan! = 0
    IF setting(SET_SPATIAL) AND d > 0.5 THEN
        side = (dx * earDY - dy * earDX) / d ' (your right is (earDY, -earDX))
        pan! = side * 0.85 * MinOf(1, d / 2) ' (close by: nearly the middle)
    END IF
    PlaySfxPan snd&, vol!, pan!
END SUB

' How loud a sound at (x, y) is where you are (0 to 1): silent range cells
' off, louder nearer as (1 - d / range) squared, a third through a wall
FUNCTION SfxVolAt!(x, y, listenX, listenY, range)
    dx = x - listenX : dy = y - listenY : d = SQR(dx * dx + dy * dy)
    IF d >= range THEN EXIT FUNCTION
    v! = (1 - d / range) ^ 2
    IF d > 0.5 THEN IF NOT CanSee(x, y, listenX, listenY) THEN v! = v! * 0.35
    SfxVolAt! = v!
END FUNCTION

' How much the 800 x 600 screen is stretched on the display (2 on a 1600-
' wide full screen). QB64PE multiplies captured mouse movement by this, so
' mouse look divides it back out to turn at the same speed either way.
FUNCTION DisplayScale!
    DisplayScale! = 1
    IF _FULLSCREEN = 0 THEN EXIT FUNCTION
    scaleX! = _DESKTOPWIDTH / _WIDTH(0) : scaleY! = _DESKTOPHEIGHT / _HEIGHT(0)
    IF _FULLSCREEN = 2 AND scaleY! < scaleX! THEN scaleX! = scaleY! ' _SQUAREPIXELS : letterboxed
    DisplayScale! = scaleX!
END FUNCTION

' === GUNS, MONSTERS AND PICKUPS ===============================================

' One row of the guns table (chapter 4)
SUB SetGun(gun, title$, ammoType, ammoPerShot, delay, pellets, spread, damage, pierce, kick, zoom)
    gunName$(gun) = title$ : gunAmmoType(gun) = ammoType : gunAmmoPerShot(gun) = ammoPerShot : gunDelay(gun) = delay
    gunPellets(gun) = pellets : gunSpread(gun) = spread : gunDamage(gun) = damage : gunPierce(gun) = pierce : gunKick(gun) = kick
    gunZoom(gun) = zoom
END SUB

' Gun number `gun`'s first-person picture, and where its muzzle is: the
' middle of the top-most row of the picture that's at least
' MUZZLE_MIN_WIDTH solid pixels wide (so a thin sight post sticking up above
' the barrel doesn't count). The muzzle flash and the railgun's beam start
' there.
SUB LoadGun(gun, file$)
    CONST MUZZLE_MIN_WIDTH = 4
    IF gunImg&(gun) < -1 THEN _FREEIMAGE gunImg&(gun) ' (loaded before: ART changed)
    IF gunSoftImg&(gun) < -1 THEN _FREEIMAGE gunSoftImg&(gun)
    IF gunGLW(gun) > 0 THEN _MEMFREE gunGLMem(gun) : gunGLW(gun) = 0
    path$ = ArtPath$(file$)
    gunImg&(gun) = _LOADIMAGE(path$, 32)
    IF gunImg&(gun) >= -1 THEN PRINT "Missing texture: "; path$: SLEEP: SYSTEM
    _SOURCE gunImg&(gun)
    imgW = _WIDTH(gunImg&(gun)) : imgH = _HEIGHT(gunImg&(gun))
    FOR y = 0 TO imgH - 1
        bestRun = 0 : runLen = 0
        FOR x = 0 TO imgW ' (one past the edge, to end a run touching it)
            solid = 0
            IF x < imgW THEN solid = _ALPHA32(POINT(x, y)) > 128
            IF solid THEN
                runLen = runLen + 1
            ELSE
                IF runLen > bestRun THEN bestRun = runLen : runEnd = x - 1
                runLen = 0
            END IF
        NEXT
        IF bestRun >= MUZZLE_MIN_WIDTH THEN EXIT FOR
    NEXT
    _SOURCE 0
    IF bestRun < MUZZLE_MIN_WIDTH THEN y = 0 : runEnd = imgW / 2 : bestRun = 1
    gunMuzzleX(gun) = (runEnd - bestRun / 2 + 1) / imgW : gunMuzzleY(gun) = (y + 0.5) / imgH
    ' OpenGL's copy: each colour times its alpha (so a half see-through
    ' pixel is also half as bright), the way GLDrawHUD lays pictures on
    ' - then a smoothed edge blends into what's behind, not into black
    DIM picture AS _MEM, col AS _UNSIGNED LONG
    picture = _MEMIMAGE(gunImg&(gun))
    gunGLW(gun) = imgW : gunGLH(gun) = imgH : gunGLMem(gun) = _MEMNEW(imgW * imgH * 4)
    FOR i& = 0 TO imgW * imgH - 1
        col = _MEMGET(picture, picture.OFFSET + i& * 4, _UNSIGNED LONG) : a& = _SHR(col, 24)
        r& = (_SHR(col, 16) AND 255) * a& \ 255 : g& = (_SHR(col, 8) AND 255) * a& \ 255 : b& = (col AND 255) * a& \ 255
        _MEMPUT gunGLMem(gun), gunGLMem(gun).OFFSET + i& * 4, _RGBA32(r&, g&, b&, a&) AS _UNSIGNED LONG
    NEXT
    _MEMFREE picture
    ' The software renderer's copy, shrunk if it's very big (TintedGun&
    ' colours it, often - the fewer pixels the better)
    IF imgH > GUN_SOFT_MAX THEN
        gunSoftImg&(gun) = _NEWIMAGE(imgW * GUN_SOFT_MAX \ imgH, GUN_SOFT_MAX, 32)
        _PUTIMAGE , gunImg&(gun), gunSoftImg&(gun)
    ELSE
        gunSoftImg&(gun) = _COPYIMAGE(gunImg&(gun), 32)
    END IF
END SUB

' The gun in its light, for the software renderer: gun's picture with each
' pixel's red, green and blue times the light on it (gunLightR...). Doing
' that to every pixel takes a moment, so it's kept, and only done again
' when the light has changed by a sixteenth or more (or it's another gun).
FUNCTION TintedGun&(gun)
    STATIC tinted&, lastGun, lastR, lastG, lastB, lastArt AS LONG
    qr = INT(gunLightR * 16) : qg = INT(gunLightG * 16) : qb = INT(gunLightB * 16)
    IF tinted& <> 0 AND gun = lastGun AND qr = lastR AND qg = lastG AND qb = lastB AND lastArt = glGunVersion THEN TintedGun& = tinted& : EXIT FUNCTION
    lastArt = glGunVersion ' (new pictures since: ART changed)
    IF tinted& <> 0 AND gun <> lastGun THEN _FREEIMAGE tinted& : tinted& = 0
    IF tinted& = 0 THEN tinted& = _COPYIMAGE(gunSoftImg&(gun), 32)
    lastGun = gun : lastR = qr : lastG = qg : lastB = qb
    DIM src AS _MEM, dst AS _MEM, col AS _UNSIGNED LONG
    src = _MEMIMAGE(gunSoftImg&(gun)) : dst = _MEMIMAGE(tinted&)
    mr& = qr * 16 : mg& = qg * 16 : mb& = qb * 16 ' (times 256: whole numbers are quicker)
    FOR i& = 0 TO src.SIZE \ 4 - 1
        col = _MEMGET(src, src.OFFSET + i& * 4, _UNSIGNED LONG)
        r& = (_SHR(col, 16) AND 255) * mr& \ 256 : IF r& > 255 THEN r& = 255
        g& = (_SHR(col, 8) AND 255) * mg& \ 256 : IF g& > 255 THEN g& = 255
        b& = (col AND 255) * mb& \ 256 : IF b& > 255 THEN b& = 255
        _MEMPUT dst, dst.OFFSET + i& * 4, _RGBA32(r&, g&, b&, _SHR(col, 24)) AS _UNSIGNED LONG
    NEXT
    _MEMFREE src : _MEMFREE dst
    TintedGun& = tinted&
END FUNCTION

' The light at map point (x, y): the four nearest cells' light (litR...),
' blended by how near each one's middle is, skipping walls - so it doesn't
' jump as you step from one cell to the next. 256 = full.
SUB LightAt(x, y, r, g, b)
    fx = x - 0.5 : fy = y - 0.5 : ix = INT(fx) : iy = INT(fy) : tx = fx - ix : ty = fy - iy
    r = 0 : g = 0 : b = 0 : sw = 0
    FOR j = 0 TO 1 : FOR i = 0 TO 1
        cx = ix + i : cy = iy + j
        IF cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN
            IF NOT IsWall(cx, cy) OR diagCorner(cx, cy) <> 0 THEN
                w = (i * tx + (1 - i) * (1 - tx)) * (j * ty + (1 - j) * (1 - ty))
                r = r + litR(cx, cy) * w : g = g + litG(cx, cy) * w : b = b + litB(cx, cy) * w : sw = sw + w
            END IF
        END IF
    NEXT : NEXT
    IF sw > 0.0001 THEN r = r / sw : g = g / sw : b = b / sw ELSE r = ambientR : g = ambientG : b = ambientB
END SUB

' Add `amount` of ammo type ammoType, up to the most you can carry. Returns
' FALSE (0) if you were already full, so the pickup stays on the floor.
FUNCTION GiveAmmo%(ammoType, amount)
    IF ammoCount(ammoType) >= ammoMax(ammoType) THEN EXIT FUNCTION
    ammoCount(ammoType) = ammoCount(ammoType) + amount
    IF ammoCount(ammoType) > ammoMax(ammoType) THEN ammoCount(ammoType) = ammoMax(ammoType)
    GiveAmmo% = -1
END FUNCTION

' One row of the monster types table (chapter 6)
SUB SetMonType(mtype, title$, hitPoints, speed, scale, lift, bob, reach, damage, damageRnd, cooldown, sprite)
    mtypeName$(mtype) = title$ : mtypeHP(mtype) = hitPoints : mtypeSpeed(mtype) = speed : mtypeScale(mtype) = scale
    mtypeLift(mtype) = lift : mtypeBob(mtype) = bob : mtypeReach(mtype) = reach
    mtypeDamage(mtype) = damage : mtypeDamageRnd(mtype) = damageRnd : mtypeCooldown(mtype) = cooldown : mtypeSprite(mtype) = sprite
END SUB

' A bolt from (x, y), flying along (dirX, dirY), into the first free slot
SUB FireBolt(x, y, dirX, dirY, damage)
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) = 0 THEN
            boltOn(i) = -1 : boltX(i) = x + dirX * 0.4 : boltY(i) = y + dirY * 0.4
            boltDX(i) = dirX : boltDY(i) = dirY : boltDamage(i) = damage
            ' (its height: from the shooter's middle, towards yours)
            boltZ(i) = floorH(INT(x), INT(y)) + 0.49 : d = SQR((playerX - x) ^ 2 + (playerY - y) ^ 2) : boltDZ(i) = 0
            IF d > 0.5 THEN boltDZ(i) = (playerZ + 0.49 - boltZ(i)) / d
            EXIT SUB
        END IF
    NEXT
END SUB

' Which sprite slot a pickup kind is drawn with
FUNCTION ItemSprite(kind)
    IF kind <= IT_REPEATER THEN
        ItemSprite = kind
    ELSEIF kind <= IT_MAP THEN
        ItemSprite = 16 + kind
    ELSE
        ItemSprite = S_ITEMX + kind - IT_MAP
    END IF
END FUNCTION

' Which sprite slot a decoration kind is drawn with
FUNCTION DecoSlot(kind)
    IF kind <= 4 THEN DecoSlot = S_DECO + kind ELSE DecoSlot = S_DECOX + kind - 4
END FUNCTION

' A set piece's picture file
FUNCTION DecoFile$(kind)
    DecoFile$ = RTRIM$(MID$("desk     console  screens  specimen labbench generatorcryopod  hologram locker   bench    chair    body     ", (kind - 10) * 9 + 1, 9)) + ".png"
END FUNCTION

' Does a decoration kind blow up when it's hit? (A barrel, a coolant tank)
FUNCTION Explosive(kind)
    Explosive = (kind = 1 OR kind = 8)
END FUNCTION

' How many hits a decoration kind takes before it breaks (a barrel: 1)
FUNCTION DecoMaxHP(kind)
    SELECT CASE kind
        CASE 1 : DecoMaxHP = 1 ' Barrel
        CASE 2 : DecoMaxHP = 2 ' Lamp
        CASE 3 : DecoMaxHP = 2 ' Plant
        CASE 5 : DecoMaxHP = 3 ' Crate
        CASE 8 : DecoMaxHP = 1 ' Coolant tank
        CASE 9 : DecoMaxHP = 8 ' Spawner (a nest's portal)
        CASE 10, 18, 19 : DecoMaxHP = 3 ' Desk, lockers, bench
        CASE 14 : DecoMaxHP = 2 ' Lab bench (glass)
        CASE 13, 16 : DecoMaxHP = 3 ' Specimen tank, cryo pod (glass)
        CASE 15 : DecoMaxHP = 6 ' Generator
        CASE 20 : DecoMaxHP = 2 ' Chair
        CASE 21 : DecoMaxHP = 99 ' (a body: never breaks)
        CASE ELSE : DecoMaxHP = 4 ' Terminal, server rack, vending machine
    END SELECT
END FUNCTION

' How tall a decoration kind stands (in walls)
FUNCTION DecoScale(kind)
    SELECT CASE kind
        CASE 1 : DecoScale = 0.45 ' Barrel
        CASE 2 : DecoScale = 0.85 ' Lamp
        CASE 3 : DecoScale = 0.6 ' Plant
        CASE 5 : DecoScale = 0.42 ' Crate
        CASE 6 : DecoScale = 0.9 ' Server rack
        CASE 7 : DecoScale = 0.8 ' Vending machine
        CASE 8 : DecoScale = 0.55 ' Coolant tank
        CASE 9 : DecoScale = 0.7 ' Spawner
        CASE 10 : DecoScale = 0.45 ' Desk
        CASE 11 : DecoScale = 0.5 ' Control console
        CASE 12 : DecoScale = 0.85 ' Monitor bank
        CASE 13 : DecoScale = 0.85 ' Specimen tank
        CASE 14 : DecoScale = 0.45 ' Lab bench
        CASE 15 : DecoScale = 0.7 ' Generator
        CASE 16 : DecoScale = 0.95 ' Cryo pod
        CASE 17 : DecoScale = 0.75 ' Hologram
        CASE 18 : DecoScale = 0.9 ' Lockers
        CASE 19 : DecoScale = 0.35 ' Bench
        CASE 20 : DecoScale = 0.5 ' Chair
        CASE 21 : DecoScale = 0.75 ' A body
        CASE ELSE : DecoScale = 0.55 ' Terminal
    END SELECT
END FUNCTION

' The smaller of two numbers
FUNCTION MinOf(a, b)
    IF a < b THEN MinOf = a ELSE MinOf = b
END FUNCTION
FUNCTION MaxOf(a, b)
    IF a > b THEN MaxOf = a ELSE MaxOf = b
END FUNCTION

' "red", "blue" or "yellow" for keycard 1, 2 or 3
FUNCTION CardName$(card)
    CardName$ = RTRIM$(MID$("red   blue  yellow", (card - 1) * 6 + 1, 6))
END FUNCTION

' Keycard 1, 2 or 3's colour
FUNCTION CardRGB~&(card)
    SELECT CASE card
        CASE 1 : CardRGB~& = _RGB32(235, 45, 45)
        CASE 2 : CardRGB~& = _RGB32(50, 120, 255)
        CASE 3 : CardRGB~& = _RGB32(255, 215, 30)
    END SELECT
END FUNCTION

' === TEXT AND THE HUD =========================================================

'' === THE CONSOLE'S HELPERS (chapter 21) ===

' One more line in the console's log (long ones split), and the log file
SUB ConPrint(text$)
    t$ = text$
    DO
        IF conLogN = CON_LOG THEN
            FOR i = 1 TO CON_LOG - 1 : conLog$(i) = conLog$(i + 1) : NEXT
        ELSE
            conLogN = conLogN + 1
        END IF
        conLog$(conLogN) = LEFT$(t$, 96) : t$ = MID$(t$, 97)
    LOOP WHILE LEN(t$)
    IF conLogFile$ <> "" THEN
        l$ = text$ ' (QB64PE's degree sign, CHR$(248), isn't one in a text file)
        DO WHILE INSTR(l$, CHR$(248)) : d = INSTR(l$, CHR$(248)) : l$ = LEFT$(l$, d - 1) + " degrees" + MID$(l$, d + 1) : LOOP
        f = FREEFILE : OPEN conLogFile$ FOR APPEND AS #f : PRINT #f, l$ : CLOSE #f
    END IF
END SUB

' A command to run later (in order, one a frame - see the game loop)
SUB ConQueue(cmd$)
    c$ = LTRIM$(RTRIM$(cmd$))
    IF c$ = "" OR conQTail >= CON_QUEUE THEN EXIT SUB
    DO ' (several on one line, split by ;)
        semi = INSTR(c$, ";")
        IF semi THEN one$ = LEFT$(c$, semi - 1) : c$ = MID$(c$, semi + 1) ELSE one$ = c$ : c$ = ""
        IF LEN(LTRIM$(one$)) AND conQTail < CON_QUEUE THEN conQTail = conQTail + 1 : conQ$(conQTail) = LTRIM$(one$)
    LOOP WHILE LEN(c$)
END SUB

' Word n of a command, lower case (the first word is the command)
FUNCTION ConWord$(c$, n)
    t$ = LTRIM$(RTRIM$(c$)) : w = 0
    DO WHILE LEN(t$)
        sp = INSTR(t$, " ") : IF sp = 0 THEN sp = LEN(t$) + 1
        w = w + 1
        IF w = n THEN ConWord$ = LCASE$(LEFT$(t$, sp - 1)) : EXIT FUNCTION
        t$ = LTRIM$(MID$(t$, sp + 1))
    LOOP
END FUNCTION

' on / off / 1 / 0 / yes / no as -1 or 0
FUNCTION ConOn(v$)
    ConOn = (v$ = "1" OR v$ = "on" OR v$ = "yes" OR v$ = "true")
END FUNCTION

' A save slot from a word: 1-NUM_SLOTS, quick (0), or -1 if it isn't one
FUNCTION SlotOf(v$)
    SlotOf = -1
    IF v$ = "quick" OR v$ = "q" OR v$ = "0" THEN SlotOf = 0 : EXIT FUNCTION
    n = VAL(v$) : IF n >= 1 AND n <= NUM_SLOTS THEN SlotOf = n
END FUNCTION

' A monster type from a word: its number or its name (or 0)
FUNCTION MonTypeOf(v$)
    n = VAL(v$) : IF n >= 1 AND n <= MON_TYPES THEN MonTypeOf = n : EXIT FUNCTION
    FOR t = 1 TO MON_TYPES
        IF v$ <> "" AND LEFT$(mtypeName$(t), LEN(v$)) = v$ THEN MonTypeOf = t : EXIT FUNCTION
    NEXT
END FUNCTION

' set NAME VALUE (or just NAME: show it) - any setting, by its settings
' file name (fov, renderer, display, bloom...). On/off settings take on and
' off too. It's put into effect at once, as the menu does.
SUB ConSet(nm$, v$)
    FOR k = 1 TO NUM_SETTINGS
        IF nm$ = setKey$(k) THEN
            IF v$ = "" THEN
                ConPrint nm$ + " = " + LTRIM$(STR$(setting(k))) + "   (" + LTRIM$(STR$(setMin(k))) + "-" + LTRIM$(STR$(setMax(k))) + ")  " + setLabel$(k) + ": " + SettingText$(k)
            ELSE
                IF v$ = "on" OR v$ = "yes" THEN n = setMax(k) ELSE IF v$ = "off" OR v$ = "no" THEN n = setMin(k) ELSE n = VAL(v$)
                IF n < setMin(k) THEN n = setMin(k)
                IF n > setMax(k) THEN n = setMax(k)
                setting(k) = n : ApplySettings : SaveSettings
                ConPrint setLabel$(k) + " = " + SettingText$(k)
            END IF
            EXIT SUB
        END IF
    NEXT
    ConPrint "No setting called " + nm$ + "  (settings lists them)"
END SUB

' bind ACTION KEY: a key binding (key_fire or fire...) to a key - a letter,
' a key code, or space / tab / enter / shift / ctrl
SUB ConBind(act$, k$)
    FOR b = 1 TO NUM_BINDS
        IF act$ = bindKey$(b) OR "key_" + act$ = bindKey$(b) THEN
            SELECT CASE k$
                CASE "" : ConPrint bindKey$(b) + " = " + KeyName$(keyBind&(b)) : EXIT SUB
                CASE "space" : c& = 32
                CASE "tab" : c& = 9
                CASE "enter" : c& = 13
                CASE "shift" : c& = 100304
                CASE "ctrl" : c& = 100306
                CASE ELSE
                    IF LEN(k$) = 1 THEN c& = ASC(LCASE$(k$)) ELSE c& = VAL(k$)
            END SELECT
            IF c& <= 0 THEN ConPrint "bind: a letter, a key code, or space / tab / enter / shift / ctrl" : EXIT SUB
            keyBind&(b) = c& : SaveSettings : ConPrint bindKey$(b) + " = " + KeyName$(c&)
            EXIT SUB
        END IF
    NEXT
    ConPrint "No action called " + act$ + "  (binds lists them)"
END SUB

' Tab: the command's name finished, if only one command starts that way
FUNCTION ConComplete$(l$)
    ConComplete$ = l$
    IF INSTR(l$, " ") OR l$ = "" THEN EXIT FUNCTION
    all$ = ConNames$
    FOR k = 1 TO NUM_SETTINGS : all$ = all$ + setKey$(k) + " " : NEXT
    found$ = "" : n = 0 : t$ = all$
    DO WHILE LEN(t$)
        sp = INSTR(t$, " ") : w$ = LEFT$(t$, sp - 1) : t$ = MID$(t$, sp + 1)
        IF LEFT$(w$, LEN(l$)) = LCASE$(l$) THEN n = n + 1 : found$ = found$ + w$ + "  " : one$ = w$
    LOOP
    IF n = 1 THEN ConComplete$ = one$ + " " ELSE IF n > 1 THEN ConPrint found$
END FUNCTION

' Every command's name (for Tab and help)
FUNCTION ConNames$
    ConNames$ = "help version qb64pe newsector sectorname edit hud monsters puzzle put box raise lift lamp liftgo trigger triggers door message sound wall light undo savelevel kick fire use jackin jackout stations cores cutscene say map maps restart newgame finish give god kill respawn summon tp pos save load quicksave quickload set get settings bind binds events screenshot wait echo exec logfile status clear menu quit "
END FUNCTION

' help: what the commands are (or one of them, in more detail)
SUB ConHelp(c$)
    SELECT CASE c$
        CASE ""
            ConPrint "Commands (help NAME for more; ; separates several on a line):"
            ConPrint "  map N|name   maps   restart   newgame   finish     - sectors"
            ConPrint "  give all|keys|key r|weapons|gun N|ammo|health|armor|overcharge|amp|map"
            ConPrint "  god [on|off]   kill   respawn   summon TYPE [N]   kick   tp X Y [ANGLE]   pos   status"
            ConPrint "  save N|quick   load N|quick   quicksave   quickload"
            ConPrint "  set NAME VALUE   get NAME   settings   NAME [VALUE]   bind ACTION KEY   binds"
            ConPrint "  edit [walk|off]   put X Y CHAR   box X0 Y0 X1 Y1 CHAR   undo   savelevel"
            ConPrint "  cutscene [SECTOR]   say LINE   fire [FRAMES]   use   jackin   jackout [win]   stations"
            ConPrint "  events   screenshot [FILE]   wait FRAMES   echo TEXT   exec FILE   logfile FILE|off"
            ConPrint "  qb64pe [PATH|auto]   version   newsector   sectorname NAME"
            ConPrint "  clear   menu   quit"
            ConPrint "From the command line, each command starts with + :"
            ConPrint "  neon-caster.run +map 5 +give all +wait 60 +screenshot five.png +quit"
        CASE "map" : ConPrint "map N (1-" + LTRIM$(STR$(NUM_LEVELS)) + ", yours from" + STR$(NUM_LEVELS + 1) + ") or map NAME (part of one): go to that sector, keeping what you carry"
        CASE "newsector" : ConPrint "newsector: a blank sector of your own (levels/custom/), opened in the editor - carve rooms out with . (floor), Ctrl+S saves"
        CASE "sectorname" : ConPrint "sectorname NAME: rename the sector you're in - then savelevel (or Ctrl+S in the editor) to keep it"
        CASE "give" : ConPrint "give all | keys | key red|blue|yellow | weapons | gun 1-4 | ammo | health | armor | overcharge | amp | map"
        CASE "summon" : ConPrint "summon TYPE [COUNT]: drone gunner heavy crawler sentry stalker spitter overseer (or 1-8), in front of you"
        CASE "set" : ConPrint "set NAME VALUE: any setting (settings lists them); NAME on its own shows it. on/off work for switches"
        CASE "wait" : ConPrint "wait FRAMES: hold back the commands after it (60 frames = 1 second) - for scripts and the command line"
        CASE "exec" : ConPrint "exec FILE: run every line of a file as a command (// starts a comment)"
        CASE "screenshot" : ConPrint "screenshot [FILE.png]: the next frame, to FILE (or to the saves folder)"
        CASE "qb64pe" : ConPrint "qb64pe PATH: the qb64pe the code terminals compile with (a folder with it in will do); qb64pe auto: look for it; qb64pe: which"
        CASE "respawn" : ConPrint "respawn: every one of the level's monsters back where it started, alive"
        CASE ELSE : ConPrint "help: no more about " + c$
    END SELECT
END SUB

' The console, drawn over the top of the screen: its log, and the line
' being typed with a blinking cursor
SUB DrawConsole(l$)
    rows = 19 : h = rows * 16 + 28
    LINE (0, 0)-(799, h), _RGBA32(6, 2, 18, 225), BF
    LINE (0, h)-(799, h + 1), _RGB32(255, 60, 200), BF
    first = conLogN - rows + 1 : IF first < 1 THEN first = 1
    y = 4
    FOR i = first TO conLogN
        IF LEFT$(conLog$(i), 1) = "]" THEN col~& = _RGB32(255, 220, 120) ELSE col~& = _RGB32(170, 230, 255)
        COLOR col~& : _PRINTSTRING (6, y), conLog$(i) : y = y + 16
    NEXT
    cur$ = "" : IF INT(TIMER * 3) MOD 2 THEN cur$ = "_"
    COLOR _RGB32(255, 255, 255) : _PRINTSTRING (6, h - 20), "] " + l$ + cur$
    COLOR _RGB32(120, 110, 160) : _PRINTSTRING (800 - 8 * 26, h - 20), "NEON-CASTER CONSOLE  ` ESC"
END SUB

' A screenshot SUB _GL read back (glShotMem, upside down - OpenGL counts
' rows from the bottom): turned the right way up into an image, saved
SUB SaveGLShot
    img& = _NEWIMAGE(glShotW, glShotH, 32)
    DIM dst AS _MEM : dst = _MEMIMAGE(img&)
    rowB& = glShotW * 4
    FOR y& = 0 TO glShotH - 1
        _MEMCOPY glShotMem, glShotMem.OFFSET + (glShotH - 1 - y&) * rowB&, rowB& TO dst, dst.OFFSET + y& * rowB&
    NEXT
    _MEMFREE dst
    SetOpaque img& ' (the window's pixels have no meaningful alpha: make them solid)
    _SAVEIMAGE shotFile$, img& : _FREEIMAGE img&
    _MEMFREE glShotMem : glShotReq = 0
    ConPrint "saved " + shotFile$ : shotFile$ = ""
END SUB

' Every pixel of image img& made solid (alpha 255)
SUB SetOpaque(img&)
    DIM m AS _MEM : m = _MEMIMAGE(img&)
    FOR o& = 3 TO m.SIZE - 1 STEP 4 : _MEMPUT m, m.OFFSET + o&, 255 AS _UNSIGNED _BYTE : NEXT
    _MEMFREE m
END SUB

' Show a message at the bottom of the screen for a few seconds. message$ and
' messageUntil! belong to the main program; SHARED inside a SUB lets it use
' main-program variables by name.
SUB ShowMsg(text$)
    SHARED message$, messageUntil!
    message$ = text$ : messageUntil! = TIMER + 2.5
    ConPrint text$ ' (and into the console's log)
END SUB

' HUD text with a drop shadow: printed in black one pixel down and right,
' then in its colour on top
SUB HudText(x, y, text$, col~&)
    COLOR _RGB32(0, 0, 0) : _PRINTSTRING (x + 1, y + 1), text$
    COLOR col~& : _PRINTSTRING (x, y), text$
END SUB

' Big centred text: printed at normal size into a small image, then
' stretched up with _PUTIMAGE (so it's chunky, like the 3D view)
SUB BigText(text$, y, scale, col~&)
    textW = LEN(text$) * 8
    img& = _NEWIMAGE(textW, 16, 32)
    _DEST img& : _PRINTMODE _KEEPBACKGROUND
    COLOR _RGB32(0, 0, 0) : _PRINTSTRING (1, 1), text$
    COLOR col~& : _PRINTSTRING (0, 0), text$
    _DEST 0
    _PUTIMAGE (400 - textW * scale \ 2, y)-STEP(textW * scale - 1, 16 * scale-1), img&
    _FREEIMAGE img&
END SUB

' A filled circle, one LINE per row: each row is half as wide as Pythagoras
' says (halfW = SQR(radius^2 - dy^2)). With an _RGBA32 colour it's
' see-through, which is how the muzzle flash glows.
SUB FillCircle(centerX, centerY, radius, col~&)
    FOR dy = - radius TO radius
        halfW = SQR(radius * radius - dy * dy)
        LINE (centerX - halfW, centerY + dy)-(centerX + halfW, centerY + dy), col~&
    NEXT
END SUB

' A tally row's number as it's shown: "12 / 23", or a time (total -1) as m:ss
FUNCTION TallyText$(value, total)
    IF total < 0 THEN
        TallyText$ = TimeText$(value)
    ELSE
        TallyText$ = LTRIM$(STR$(INT(value))) + " / " + LTRIM$(STR$(total))
    END IF
END FUNCTION

' Seconds as m:ss
FUNCTION TimeText$(secs!)
    mins = INT(secs! / 60) : s = INT(secs!) MOD 60
    TimeText$ = LTRIM$(STR$(mins)) + ":" + RIGHT$("0" + LTRIM$(STR$(s)), 2)
END FUNCTION

' === MENUS, SETTINGS AND SAVED GAMES (chapter 21) ==============================

' One row of the settings table (chapter 6): its number, its name in the
' settings file, its menu label, its kind of control (MI_SLIDER, MI_TOGGLE
' or MI_CHOICE), lowest and highest value, step, and starting value
SUB DefineSetting(id, iniName$, label$, kind, lowest, highest, stepSize, start)
    setKey$(id) = iniName$ : setLabel$(id) = label$ : setKind(id) = kind
    setMin(id) = lowest : setMax(id) = highest : setStep(id) = stepSize
    setDefault(id) = start : setting(id) = start
END SUB

' One key binding (chapter 6): its number, its name in the settings file,
' its menu label, and its key to start with
SUB DefineBind(bindNum, iniName$, label$, code&)
    bindKey$(bindNum) = iniName$ : bindLabel$(bindNum) = label$
    bindDefault&(bindNum) = code& : keyBind&(bindNum) = code&
END SUB

' Is the key bound to bindNum held down? Letters are stored lower case, so
' check the upper-case code too (it's what _KEYDOWN sees with Shift held).
'
' A letter key is two codes - "w" and, with Shift, "W" - so either counts.
' But QB64PE can lose one: hold W, press or let go of Shift, and the key's
' repeats switch from one code to the other; letting go of W then lets go
' of the new one only, and the old one stays "held" forever (you'd keep
' walking). So a letter also has to be held where it sits on the keyboard
' (KeyAt%) - and holding Shift to run works. (Only once the keyboard device
' has shown it works - keyTrusted, the first time it agrees with a key
' that's really down. Until then, or without it, letters work as before.)
FUNCTION KeyHeld%(bindNum)
    code& = keyBind&(bindNum)
    IF code& >= 97 AND code& <= 122 THEN
        typed = _KEYDOWN(code&) OR _KEYDOWN(code& - 32)
        IF keyDevice THEN
            here = KeyAt%(code&)
            IF here AND typed THEN keyTrusted = -1
            IF keyTrusted THEN typed = typed AND here
        END IF
        KeyHeld% = typed
    ELSE
        KeyHeld% = _KEYDOWN(code&)
    END IF
END FUNCTION

' A digit key (1-9, 0): by what it types, or - since Shift + 1 types "!",
' and you might be running - by where it is
FUNCTION DigitHeld%(code&)
    DigitHeld% = _KEYDOWN(code&)
    IF keyTrusted THEN IF KeyAt%(code&) THEN DigitHeld% = -1
END FUNCTION

' Is the key that types code& (a lower case letter, or a digit) held down
' - by where it is on the keyboard, not what it types, so Shift doesn't
' change it (Shift + 1 types "!")? QB64PE's keyboard "device" (_DEVICES,
' found at the start: keyDevice) reports keys by their scancode, a number
' for each place on the keyboard: _DEVICEINPUT(1) takes its news (we take
' all of it, to be up to date), and _BUTTON(n) is a key. Which n is the
' system's own number for the key, plus 1: on Windows the PC's scancode,
' on Linux the same plus 8 (keyScanAdd, set at the start). 0 without the
' device.
FUNCTION KeyAt%(code&)
    IF keyDevice = 0 THEN EXIT FUNCTION
    SELECT CASE code&
        CASE 97 TO 122 : scan = ASC(MID$(LETTER_SCANS, code& - 96, 1)) - 32
        CASE 49 TO 57 : scan = code& - 47 ' 1-9 sit at scancodes 2-10
        CASE 48 : scan = 11
        CASE ELSE : EXIT FUNCTION
    END SELECT
    DO WHILE _DEVICEINPUT(1) : LOOP
    KeyAt% = _BUTTON(scan + keyScanAdd + 1)
END FUNCTION

' A key code's name, for the menu and the settings file
FUNCTION KeyName$(code&)
    SELECT CASE code&
        CASE 97 TO 122 : KeyName$ = CHR$(code& - 32)
        CASE 32 : KeyName$ = "SPACE"
        CASE 13 : KeyName$ = "ENTER"
        CASE 9 : KeyName$ = "TAB"
        CASE 8 : KeyName$ = "BACKSPACE"
        CASE 18432 : KeyName$ = "UP"
        CASE 20480 : KeyName$ = "DOWN"
        CASE 19200 : KeyName$ = "LEFT"
        CASE 19712 : KeyName$ = "RIGHT"
        CASE 100306 : KeyName$ = "LEFT CTRL"
        CASE 100305 : KeyName$ = "RIGHT CTRL"
        CASE 100304 : KeyName$ = "LEFT SHIFT"
        CASE 100303 : KeyName$ = "RIGHT SHIFT"
        CASE 100308 : KeyName$ = "LEFT ALT"
        CASE 100307 : KeyName$ = "RIGHT ALT"
        CASE 15104 TO 17408 : KeyName$ = "F" + LTRIM$(STR$((code& - 15104) \ 256 + 1)) ' F1-F10
        CASE 34048 : KeyName$ = "F11"
        CASE 34304 : KeyName$ = "F12"
        CASE 33 TO 126 : KeyName$ = CHR$(code&)
        CASE ELSE : KeyName$ = "KEY" + STR$(code&)
    END SELECT
END FUNCTION

' Put the settings into effect: the camera plane's length for the field of
' view (TAN of half the angle - chapter 8), the mouse speed, and the music
' volume. (The rest - sound, crosshair, bobbing, shake - are read straight
' from setting() where they're used.)
SUB ApplySettings
    ' MODE: a new one chosen (menu, console) - its settings go in. Then
    ' which mode they all match now (CUSTOM if none).
    IF setting(SET_MODE) <> modeWas AND setting(SET_MODE) <> MODE_CUSTOM THEN
        FOR i = 1 TO NUM_SETTINGS
            v = ModeWants(setting(SET_MODE), i) : IF v >= 0 THEN setting(i) = v
        NEXT
    END IF
    setting(SET_MODE) = ModeNow : modeWas = setting(SET_MODE)
    fovPlane = TAN(setting(SET_FOV) / 2 * 3.14159265 / 180)
    turnSpeed = setting(SET_MOUSE) * 0.0006
    IF nowPlaying& > 0 THEN _SNDVOL nowPlaying&, setting(SET_MUSIC) / 100
    ' ART: which pictures, how big (the game loop reloads them - ArtReload)
    artWant = 0 : IF setting(SET_ART) = 2 THEN artWant = 1 : IF setting(SET_RENDERER) = 2 THEN artWant = 2
    ApplyDisplay
END SUB

' What MODE m sets setting id to - or -1 if it leaves it alone (sound,
' controls, gameplay). All three are OpenGL, full screen 4:3:
'   OLDSCHOOL  RETRO resolution, the pixel art, every effect off, no
'              scanlines
'   90S        720P, the pixel art, every effect but NEON and WET FLOORS,
'              scanlines and phosphor glow
'   NEWSCHOOL  as sharp as the display goes (BestRes), the modern
'              paintings, every effect, scanlines and phosphor glow
FUNCTION ModeWants(m, id)
    ModeWants = -1
    IF m < MODE_OLDSCHOOL OR m > MODE_NEWSCHOOL THEN EXIT FUNCTION
    fx = 0 : IF m > MODE_OLDSCHOOL THEN fx = 1 ' (the effects: on for 90S and NEWSCHOOL)
    SELECT CASE id
        CASE SET_RENDERER : ModeWants = 2
        CASE SET_DISPLAY : ModeWants = 3 ' FULL 4:3
        CASE SET_ART : IF m = MODE_NEWSCHOOL THEN ModeWants = 2 ELSE ModeWants = 1
        CASE SET_RES
            IF m = MODE_OLDSCHOOL THEN ModeWants = RES_RETRO ELSE IF m = MODE_90S THEN ModeWants = 5 ELSE ModeWants = BestRes ' (5: 720P)
        CASE SET_BUMP, SET_SMOOTH, SET_DYNLIGHT, SET_SHADOWS, SET_GLOW, SET_PARTICLES, SET_SHAFTS, SET_BLOOM, SET_HITFX
            ModeWants = fx
        CASE SET_NEON, SET_REFLECT : IF m = MODE_NEWSCHOOL THEN ModeWants = 1 ELSE ModeWants = 0
        CASE SET_SCREENFX : ModeWants = 1 + fx ' off, or scanlines
        CASE SET_SCANLINES : IF fx THEN ModeWants = 100
        CASE SET_PHOSPHOR : IF fx THEN ModeWants = 25
        CASE SET_SCANGAP : IF fx THEN ModeWants = 4
        CASE SET_SCANTHICK : IF fx THEN ModeWants = 50
    END SELECT
END FUNCTION

' The MODE every setting matches now (MODE_CUSTOM if none)
FUNCTION ModeNow
    FOR m = MODE_OLDSCHOOL TO MODE_NEWSCHOOL
        ok = -1
        FOR i = 1 TO NUM_SETTINGS
            v = ModeWants(m, i) : IF v >= 0 AND setting(i) <> v THEN ok = 0 : EXIT FOR
        NEXT
        IF ok THEN ModeNow = m : EXIT FUNCTION
    NEXT
END FUNCTION

' The sharpest RESOLUTION the display can show: the named one as tall as
' it is (on a 4K display, 2160P)
FUNCTION BestRes
    h = _DESKTOPHEIGHT
    IF h >= 2160 THEN BestRes = 2 ELSE IF h >= 1440 THEN BestRes = 3 ELSE IF h >= 1080 THEN BestRes = 4 ELSE IF h >= 720 THEN BestRes = 5 ELSE BestRes = 6
END FUNCTION

' DISPLAY: a window, or full screen - switched only when it needs to be
' (displayAsked, displayModeNow: what was last put into effect), as switching
' blanks the screen for a moment. _FULLSCREEN _STRETCH fills the screen;
' _SQUAREPIXELS keeps our 4:3 shape - and puts black bars over the sides,
' after everything else is drawn. So FULL WIDE, with OpenGL, is stretched:
' OpenGL draws the 3D view across all of it, and puts our screen (the
' HUD, the menus) in the 4:3 middle itself (chapter 24); WideMouseX moves
' the mouse to match. (The software renderer can't draw wider than 4:3,
' so for it FULL WIDE is 4:3.)
SUB ApplyDisplay
    want = DisplayMode(setting(SET_DISPLAY))
    IF setting(SET_DISPLAY) = displayAsked AND want = displayModeNow THEN EXIT SUB
    displayAsked = setting(SET_DISPLAY) : displayModeNow = want
    SELECT CASE want
        CASE 1 : _FULLSCREEN _STRETCH
        CASE 2 : _FULLSCREEN _SQUAREPIXELS
        CASE ELSE : _FULLSCREEN _OFF
    END SELECT
END SUB

' QB64PE's _FULLSCREEN number for DISPLAY choice d: 0 off, 1 stretched, 2
' square pixels
FUNCTION DisplayMode(d)
    SELECT CASE d
        CASE 2 : IF setting(SET_RENDERER) = 2 THEN DisplayMode = 1 ELSE DisplayMode = 2
        CASE 3 : DisplayMode = 2
        CASE 4 : DisplayMode = 1
    END SELECT
END FUNCTION

' With FULL WIDE, our screen is stretched across the whole display, but
' drawn in its 4:3 middle - so QB64PE's mouse x (mx, across the stretched
' screen) is moved to where that is on our screen
FUNCTION WideMouseX(mx)
    WideMouseX = mx
    IF WideView <= 1.01 OR _DESKTOPHEIGHT < 1 THEN EXIT FUNCTION
    winX = mx * _DESKTOPWIDTH / 800 ' (where on the display)
    middleW = _DESKTOPHEIGHT * 4 / 3 : edge = (_DESKTOPWIDTH - middleW) / 2
    WideMouseX = (winX - edge) * 800 / middleW
END FUNCTION

' Alt + Enter switches full screen too (QB64PE does that itself). So once
' a frame: if _FULLSCREEN has changed, and not to what we asked for, it was
' Alt + Enter - and DISPLAY follows it (and is saved with the settings).
SUB DisplayFollow
    STATIC lastMode
    nowMode = _FULLSCREEN
    IF nowMode <> lastMode THEN
        IF nowMode <> DisplayMode(displayAsked) THEN
            SELECT CASE nowMode
                CASE 1 : displayAsked = 4
                CASE 2 : displayAsked = 3
                CASE ELSE : displayAsked = 1
            END SELECT
            setting(SET_DISPLAY) = displayAsked : displayModeNow = nowMode
        END IF
        lastMode = nowMode
    END IF
END SUB

' How much wider than 4:3 the 3D view is: with DISPLAY at FULL WIDE, in
' full screen, with OpenGL, the screen's shape over 4:3 (1.33 on a 16:9
' screen); otherwise 1
FUNCTION WideView
    WideView = 1
    IF setting(SET_DISPLAY) <> 2 OR _FULLSCREEN <> 1 OR setting(SET_RENDERER) <> 2 THEN EXIT FUNCTION
    IF _DESKTOPHEIGHT < 1 THEN EXIT FUNCTION
    k = _DESKTOPWIDTH / _DESKTOPHEIGHT * 3 / 4
    IF k > 1 THEN WideView = k
END FUNCTION

' Left (-1) or right (1) on setting id: a slider moves a step (and stops at
' its ends), a choice goes round to the next one, a toggle flips
SUB ChangeSetting(id, dir)
    IF id = SET_MODE THEN ' (round the three looks - CUSTOM isn't one you choose)
        setting(id) = setting(id) + dir
        IF setting(id) > MODE_NEWSCHOOL THEN setting(id) = MODE_OLDSCHOOL
        IF setting(id) < MODE_OLDSCHOOL THEN setting(id) = MODE_NEWSCHOOL
        EXIT SUB
    END IF
    SELECT CASE setKind(id)
        CASE MI_TOGGLE
            setting(id) = 1 - setting(id)
        CASE MI_CHOICE
            setting(id) = setting(id) + dir
            IF setting(id) > setMax(id) THEN setting(id) = setMin(id)
            IF setting(id) < setMin(id) THEN setting(id) = setMax(id)
        CASE ELSE
            setting(id) = setting(id) + dir * setStep(id)
            IF setting(id) > setMax(id) THEN setting(id) = setMax(id)
            IF setting(id) < setMin(id) THEN setting(id) = setMin(id)
    END SELECT
END SUB

' Set a slider from where the mouse is along it, to the nearest step
SUB SliderFromMouse(item, mouseX)
    id = miRef(item)
    f = (mouseX - MENU_WIDGET_X) / MENU_WIDGET_W
    IF f < 0 THEN f = 0
    IF f > 1 THEN f = 1
    v = setMin(id) + f * (setMax(id) - setMin(id))
    setting(id) = setMin(id) + INT((v - setMin(id)) / setStep(id) + 0.5) * setStep(id)
END SUB

' A setting's value as the menu shows it
FUNCTION SettingText$(id)
    v$ = LTRIM$(STR$(setting(id)))
    SELECT CASE id
        CASE SET_SFX, SET_MUSIC, SET_SPEECH, SET_XALPHA, SET_SCANLINES, SET_PHOSPHOR, SET_SCANTHICK, SET_AIMSENS : SettingText$ = v$ + "%"
        CASE SET_SCANGAP : SettingText$ = v$ + " PX"
        CASE SET_FOV : SettingText$ = v$ + CHR$(248) ' (a degree sign in QB64PE's font)
        CASE SET_XSTYLE : SettingText$ = CrossStyleName$(setting(id))
        CASE SET_XCOLOR : SettingText$ = CrossColorName$(setting(id))
        CASE SET_RENDERER : IF setting(id) = 2 THEN SettingText$ = "OPENGL" ELSE SettingText$ = "SOFTWARE"
        CASE SET_ART : IF setting(id) = 2 THEN SettingText$ = "MODERN" ELSE SettingText$ = "CLASSIC"
        CASE SET_MODE : SettingText$ = RTRIM$(MID$("CUSTOM   OLDSCHOOL90S      NEWSCHOOL", setting(id) * 9 + 1, 9))
        CASE SET_SCREENFX : SettingText$ = MID$("OFF      SCANLINESCRT      ", setting(id) * 9 - 8, 9)
        CASE SET_RES : SettingText$ = ResName$(setting(id))
        CASE SET_DISPLAY : SettingText$ = RTRIM$(MID$("WINDOWED    FULL WIDE   FULL 4:3    FULL STRETCH", setting(id) * 12 - 11, 12))
        CASE ELSE : SettingText$ = v$
    END SELECT
END FUNCTION

' Read the settings file, if there is one. Every setting starts at its
' default; a "name=value" line for it (with a value in range) changes it.
SUB LoadSettings
    FOR i = 1 TO NUM_SETTINGS : setting(i) = setDefault(i) : NEXT
    FOR i = 1 TO NUM_BINDS : keyBind&(i) = bindDefault&(i) : NEXT
    qbChosen$ = ""
    file$ = SaveDir$ + "settings.ini"
    IF NOT _FILEEXISTS(file$) THEN EXIT SUB
    fileNum = FREEFILE
    OPEN file$ FOR INPUT AS #fileNum
    DO UNTIL EOF(fileNum)
        LINE INPUT #fileNum, text$
        eq = INSTR(text$, "=")
        IF eq > 0 THEN
            iniKey$ = LCASE$(LTRIM$(RTRIM$(LEFT$(text$, eq - 1)))) : v = VAL(MID$(text$, eq + 1))
            FOR i = 1 TO NUM_SETTINGS
                IF iniKey$ = setKey$(i) AND v >= setMin(i) AND v <= setMax(i) THEN setting(i) = v
            NEXT
            IF iniKey$ = "qb64pe" THEN ' (a path, not a number)
                qbChosen$ = MID$(text$, eq + 1) : IF RIGHT$(qbChosen$, 1) = CHR$(13) THEN qbChosen$ = LEFT$(qbChosen$, LEN(qbChosen$) - 1)
                qbChosen$ = LTRIM$(RTRIM$(qbChosen$))
            END IF
            IF iniKey$ = "retro_res" AND v = 1 THEN setting(SET_RES) = RES_RETRO ' (what RESOLUTION was called once)
            FOR i = 1 TO NUM_BINDS
                IF iniKey$ = bindKey$(i) AND v > 0 THEN keyBind&(i) = v
            NEXT
        END IF
    LOOP
    CLOSE #fileNum
    setting(SET_MODE) = ModeNow : modeWas = setting(SET_MODE) ' (worked out from the rest - not put into effect)
END SUB

' Write every setting and key binding to the settings file
SUB SaveSettings
    IF noSaveSettings THEN EXIT SUB ' (settings from the command line are for this run only)
    MakeSaveDir
    fileNum = FREEFILE
    OPEN SaveDir$ + "settings.ini" FOR OUTPUT AS #fileNum
    PRINT #fileNum, "; NEON-CASTER settings: one name and value a line (chapter 21 explains them)"
    FOR i = 1 TO NUM_SETTINGS : PRINT #fileNum, setKey$(i) + "=" + LTRIM$(STR$(setting(i))) : NEXT
    PRINT #fileNum, "; qb64pe: the compiler the code terminals use - its path, or the folder it's in."
    PRINT #fileNum, "; Left empty, the game looks for it ($QB64PE, the PATH, the usual folders);"
    PRINT #fileNum, "; with none, a terminal checks your lines against the answer instead."
    PRINT #fileNum, "qb64pe=" + qbChosen$
    FOR i = 1 TO NUM_BINDS
        PRINT #fileNum, bindKey$(i) + "=" + LTRIM$(STR$(keyBind&(i))) + "   ; " + KeyName$(keyBind&(i))
    NEXT
    CLOSE #fileNum
END SUB

' The folder settings and saved games go in: neon-caster/saves/
FUNCTION SaveDir$
    path$ = AssetPath$("door.png")
    SaveDir$ = LEFT$(path$, LEN(path$) - LEN("door.png")) + "saves/"
END FUNCTION

SUB MakeSaveDir
    folder$ = SaveDir$ : folder$ = LEFT$(folder$, LEN(folder$) - 1)
    IF NOT _DIREXISTS(folder$) THEN MKDIR folder$
END SUB

' Save slot n's file (0 = the quick save)
FUNCTION SlotFile$(slot)
    IF slot = 0 THEN SlotFile$ = SaveDir$ + "quick.sav" ELSE SlotFile$ = SaveDir$ + "slot" + LTRIM$(STR$(slot)) + ".sav"
END FUNCTION

' What's in a save slot: the level and when, as SaveGame wrote it ("" if
' it's empty)
FUNCTION SlotInfo$(slot)
    file$ = SlotFile$(slot)
    IF NOT _FILEEXISTS(file$) THEN EXIT FUNCTION
    fileNum = FREEFILE
    OPEN file$ FOR BINARY AS #fileNum
    tag$ = SPACE$(LEN(SAVE_TAG)) : GET #fileNum, , tag$
    info$ = SPACE$(SAVE_INFO_LEN) : GET #fileNum, , info$
    CLOSE #fileNum
    IF tag$ = SAVE_TAG THEN SlotInfo$ = RTRIM$(info$) ELSE SlotInfo$ = "(not a save)"
END FUNCTION

' Fill in the items for menu screen scr (SCR_ constants). This is where to
' add a button or a screen: an AddMenuItem line, and - for a new action -
' a CASE in MenuActivate (chapter 21).
SUB BuildMenu(scr)
    numMI = 0 : menuWide = 0
    SELECT CASE scr
        CASE SCR_MAIN
            IF menuInGame THEN menuTitle$ = "PAUSED" ELSE menuTitle$ = "MAIN MENU"
            IF menuInGame THEN AddMenuItem "RESUME", MI_ACTION, 0, MA_RESUME, -1, ""
            AddMenuItem "GAME", MI_SUBMENU, SCR_GAME, 0, -1, ""
            AddMenuItem "SETTINGS", MI_SUBMENU, SCR_SETTINGS, 0, -1, ""
            AddMenuItem "CREDITS", MI_SUBMENU, SCR_CREDITS, 0, -1, ""
            AddMenuItem "EXIT", MI_SUBMENU, SCR_QUIT, 0, -1, ""
        CASE SCR_GAME
            menuTitle$ = "GAME"
            AddMenuItem "NEW GAME", MI_ACTION, 0, MA_NEW, -1, ""
            AddMenuItem "SELECT SECTOR", MI_SUBMENU, SCR_SECTOR, 0, -1, ""
            AddMenuItem "YOUR SECTORS", MI_SUBMENU, SCR_CUSTOM, 0, -1, ""
            AddMenuItem "LOAD GAME", MI_SUBMENU, SCR_LOAD, 0, -1, ""
            AddMenuItem "SAVE GAME", MI_SUBMENU, SCR_SAVE, 0, menuInGame, "" ' (only during a game)
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_SECTOR ' A new game, starting in any sector
            menuTitle$ = "SELECT SECTOR" : menuWide = -1
            FOR n = 1 TO NUM_LEVELS
                nm$ = sectorName$(n) : c = INSTR(nm$, ": ") : IF c THEN nm$ = MID$(nm$, c + 2)
                AddMenuItem LTRIM$(STR$(n)) + "  " + nm$, MI_ACTION, n, MA_SECTOR, -1, ""
            NEXT
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_CUSTOM ' Your own sectors (chapter 22): play one, or make a new one
            menuTitle$ = "YOUR SECTORS" : menuWide = -1 : free = 0
            FOR n = NUM_LEVELS + 1 TO NUM_LEVELS + MAX_CUSTOM
                sectorName$(n) = SectorNameOf$(n) ' (a name may have changed: Ctrl+S, or by hand)
                IF LEN(sectorName$(n)) THEN AddMenuItem LTRIM$(STR$(n)) + "  " + sectorName$(n), MI_ACTION, n, MA_SECTOR, -1, "" ELSE free = free + 1
            NEXT
            AddMenuItem "NEW SECTOR", MI_ACTION, 0, MA_NEWSECTOR, free > 0, "" ' (a blank slate, opened in the editor - while there's room)
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_SAVE
            menuTitle$ = "SAVE GAME" : menuWide = -1
            FOR slot = 1 TO NUM_SLOTS
                info$ = SlotInfo$(slot) : IF info$ = "" THEN info$ = "- empty -"
                AddMenuItem "SLOT" + STR$(slot), MI_ACTION, slot, MA_SAVE, -1, info$
            NEXT
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_LOAD
            menuTitle$ = "LOAD GAME" : menuWide = -1
            FOR slot = 0 TO NUM_SLOTS
                info$ = SlotInfo$(slot)
                IF slot = 0 THEN label$ = "QUICK SAVE" ELSE label$ = "SLOT" + STR$(slot)
                IF info$ = "" THEN
                    AddMenuItem label$, MI_ACTION, slot, MA_LOAD, 0, "- empty -"
                ELSE
                    AddMenuItem label$, MI_ACTION, slot, MA_LOAD, -1, info$
                END IF
            NEXT
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_SETTINGS
            menuTitle$ = "SETTINGS"
            AddSettingItem SET_MODE
            AddMenuItem "AUDIO", MI_SUBMENU, SCR_AUDIO, 0, -1, ""
            AddMenuItem "GAMEPLAY", MI_SUBMENU, SCR_GAMEPLAY, 0, -1, ""
            AddMenuItem "VIDEO", MI_SUBMENU, SCR_VIDEO, 0, -1, ""
            AddMenuItem "EFFECTS", MI_SUBMENU, SCR_EFFECTS, 0, -1, ""
            AddMenuItem "CONTROLS", MI_SUBMENU, SCR_CONTROLS, 0, -1, ""
            AddMenuItem "QB64PE COMPILER", MI_SUBMENU, SCR_QB64, 0, -1, ""
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_QB64 ' The qb64pe the code terminals compile with (chapter 19)
            menuTitle$ = "QB64PE COMPILER" : menuWide = -1
            AddMenuItem "CODE TERMINALS COMPILE YOUR FIX WITH IT", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "NONE? THEY CHECK YOUR LINES INSTEAD", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "", MI_TEXT, 0, 0, 0, ""
            IF LEN(qbChosen$) THEN info$ = PathTail$(qbChosen$, 58) ELSE info$ = "its path, or its folder (Ctrl+V pastes)"
            AddMenuItem "TYPE IT", MI_ACTION, 0, MA_QB64_TYPE, -1, info$
            AddMenuItem "BROWSE", MI_ACTION, 0, MA_QB64_BROWSE, -1, "pick it in a file window"
            AddMenuItem "FIND IT", MI_ACTION, 0, MA_QB64_AUTO, -1, "look for it: $QB64PE, the PATH, the usual places"
            AddMenuItem "", MI_TEXT, 0, 0, 0, ""
            qb$ = QB64Path$
            IF qb$ = "" THEN
                AddMenuItem "NOT FOUND", MI_TEXT, 0, 0, 0, ""
                AddMenuItem "GET IT AT QB64PHOENIX.COM", MI_TEXT, 0, 0, 0, ""
            ELSE
                IF qb$ = QB64At$(qbChosen$) THEN
                    AddMenuItem "COMPILING WITH YOURS", MI_TEXT, 0, 0, 0, ""
                ELSEIF LEN(qbChosen$) THEN ' (one you chose once, not there now)
                    AddMenuItem "YOURS IS GONE - USING ONE FOUND", MI_TEXT, 0, 0, 0, ""
                ELSE
                    AddMenuItem "COMPILING WITH THE ONE FOUND", MI_TEXT, 0, 0, 0, ""
                END IF
                AddMenuItem PathTail$(qb$, 46), MI_TEXT, 0, 0, 0, ""
            END IF
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_VIDEO
            menuTitle$ = "VIDEO" : menuWide = -1
            AddSettingItem SET_DISPLAY : AddSettingItem SET_RENDERER : AddSettingItem SET_ART : AddSettingItem SET_FPS
            AddMenuItem "OPENGL ONLY:", MI_TEXT, 0, 0, 0, ""
            AddSettingItem SET_RES : AddSettingItem SET_LOOK
            AddSettingItem SET_SCREENFX : AddSettingItem SET_SCANLINES : AddSettingItem SET_SCANGAP
            AddSettingItem SET_SCANTHICK : AddSettingItem SET_PHOSPHOR
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_EFFECTS
            menuTitle$ = "EFFECTS (OPENGL)" : menuWide = -1
            AddSettingItem SET_BUMP : AddSettingItem SET_SMOOTH : AddSettingItem SET_NEON : AddSettingItem SET_DYNLIGHT
            AddSettingItem SET_SHADOWS : AddSettingItem SET_GLOW : AddSettingItem SET_PARTICLES : AddSettingItem SET_SHAFTS : AddSettingItem SET_REFLECT
            AddSettingItem SET_BLOOM : AddSettingItem SET_HITFX
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_AUDIO
            menuTitle$ = "AUDIO" : menuWide = -1
            AddSettingItem SET_SFX : AddSettingItem SET_MUSIC : AddSettingItem SET_SPEECH
            AddSettingItem SET_SPATIAL : AddSettingItem SET_LIMITER : AddSettingItem SET_CUTSCENES : AddSettingItem SET_TAUNTS
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_GAMEPLAY
            menuTitle$ = "GAMEPLAY" : menuWide = -1
            AddSettingItem SET_FOV : AddSettingItem SET_XSTYLE : AddSettingItem SET_XCOLOR
            AddSettingItem SET_XSIZE : AddSettingItem SET_XALPHA : AddSettingItem SET_XFEEDBACK
            AddSettingItem SET_BOB : AddSettingItem SET_SHAKE : AddSettingItem SET_HURTDIR : AddSettingItem SET_AIMSENS
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_CONTROLS
            menuTitle$ = "CONTROLS" : menuWide = -1
            AddSettingItem SET_MOUSE
            FOR b = 1 TO NUM_BINDS : AddMenuItem bindLabel$(b), MI_KEY, b, 0, -1, "" : NEXT
            AddMenuItem "RESET KEYS", MI_ACTION, 0, MA_KEYS_DEFAULT, -1, ""
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_CREDITS
            menuTitle$ = "CREDITS"
            AddMenuItem "CODE  GRYMMJACK + CLAUDE", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "ENGINE  QB64 PHOENIX EDITION", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "RAYCASTING  AFTER LODE VANDEVENNE", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "ART  PIXELMON  (ENDESGA-32)", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "SOUND  SOUNDMON", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "MUSIC  SOUNDMON", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_QUIT
            menuTitle$ = "EXIT"
            AddMenuItem QuitQuote$, MI_TEXT, 0, 0, 0, ""
            AddMenuItem "", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "YES", MI_ACTION, 0, MA_QUIT, -1, ""
            AddMenuItem "NO", MI_BACK, 0, 0, -1, ""
    END SELECT
END SUB

' One more item on the menu screen being built (see the mi... arrays)
SUB AddMenuItem(label$, kind, ref, act, enabled, info$)
    IF numMI >= MAX_MI THEN EXIT SUB
    numMI = numMI + 1
    miLabel$(numMI) = label$ : miKind(numMI) = kind : miRef(numMI) = ref
    miAct(numMI) = act : miOn(numMI) = enabled : miInfo$(numMI) = info$
END SUB

' A setting as a menu item: its label, and the control its kind needs
SUB AddSettingItem(id)
    AddMenuItem setLabel$(id), setKind(id), id, 0, -1, ""
END SUB

' Can menu item i be chosen? (Not lines of text, or ones switched off.)
FUNCTION MenuSelectable%(i)
    IF i < 1 OR i > numMI THEN EXIT FUNCTION
    MenuSelectable% = miKind(i) <> MI_TEXT AND miOn(i) <> 0
END FUNCTION

' Which item (that can be chosen) is the mouse over? 0 if none.
FUNCTION MenuItemAt(mouseX, mouseY)
    FOR i = 1 TO numMI
        rowY = MENU_TOP + (i - 1) * MENU_ROW
        IF mouseY >= rowY - 3 AND mouseY < rowY + MENU_ROW - 3 AND mouseX >= 100 AND mouseX <= 760 THEN
            IF MenuSelectable(i) THEN MenuItemAt = i
            EXIT FUNCTION
        END IF
    NEXT
END FUNCTION

' Draw the menu screen showing now, t frames after it opened: the title,
' then each item sliding in (see chapter 21), with the selected one lit up
' and each control drawn the way its kind needs
SUB DrawMenu(t)
    glow = 0.5 + 0.5 * SIN(t * 0.05)
    MenuText 404, 30, "NEON-CASTER", 6, _RGBA32(255, 40, 200, 110), 1 ' (a magenta shadow, for the glow)
    MenuText 400, 26, "NEON-CASTER", 6, _RGB32(120 + 120 * glow, 235, 255), 1
    MenuText 792, 584, "v" + GAME_VERSION$, 1, _RGBA32(150, 140, 200, 160), 2 ' (the version, bottom right)
    MenuText 400, 128, menuTitle$, 2, _RGB32(255, 100, 215), 1
    LINE (250, 162)-(550, 163), _RGBA32(255, 100, 215, 120), BF
    panelA = t * 12 : IF panelA > 170 THEN panelA = 170 ' A dark panel behind the items, so they read over anything
    LINE (96, MENU_TOP - 12)-(704, MENU_TOP + numMI * MENU_ROW), _RGBA32(6, 0, 18, panelA), BF
    FOR i = 1 TO numMI
        p = (t - (i - 1) * 3) / 12 ' This item's progress in: 0 .. 1
        IF p < 0 THEN p = 0
        IF p > 1 THEN p = 1
        ease = 1 - (1 - p) ^ 3
        slide = (1 - ease) * 260 : alpha = ease * 255
        rowY = MENU_TOP + (i - 1) * MENU_ROW
        selected = (i = menuSel)
        IF miOn(i) = 0 THEN
            col~& = _RGBA32(90, 85, 120, alpha)
        ELSEIF selected THEN
            col~& = _RGBA32(255, 255, 255, alpha)
        ELSE
            col~& = _RGBA32(185, 195, 230, alpha)
        END IF
        IF selected AND miKind(i) <> MI_TEXT THEN ' The bar behind the selected item
            barA = alpha * (0.3 + 0.1 * SIN(t * 0.2))
            LINE (110 + slide, rowY - 3)-(690 + slide, rowY + MENU_ROW - 5), _RGBA32(255, 40, 170, barA), BF
            LINE (110 + slide, rowY - 3)-(690 + slide, rowY - 3), _RGBA32(90, 230, 255, alpha), BF
            LINE (110 + slide, rowY + MENU_ROW - 5)-(690 + slide, rowY + MENU_ROW - 5), _RGBA32(90, 230, 255, alpha), BF
            IF (t \ 15) MOD 2 = 0 THEN MenuText 118 + slide, rowY, ">", 2, _RGBA32(90, 230, 255, alpha), 0
        END IF
        IF miKind(i) = MI_TEXT THEN
            MenuText 400 + slide, rowY, miLabel$(i), 2, _RGBA32(200, 160, 255, alpha), 1
        ELSEIF menuWide THEN
            MenuText MENU_LABEL_X + slide, rowY, miLabel$(i), 2, col~&, 0
        ELSEIF miKind(i) = MI_CHOICE THEN ' (a choice on a centred screen - MODE: its value beside it)
            MenuText 400 + slide, rowY, miLabel$(i) + ":  <  " + SettingText$(miRef(i)) + "  >", 2, col~&, 1
        ELSE
            MenuText 400 + slide, rowY, miLabel$(i), 2, col~&, 1
        END IF
        wx = MENU_WIDGET_X + slide
        SELECT CASE miKind(i)
            CASE MI_SLIDER
                id = miRef(i) : f = (setting(id) - setMin(id)) / (setMax(id) - setMin(id))
                LINE (wx, rowY + 11)-(wx + MENU_WIDGET_W, rowY + 18), _RGBA32(60, 45, 95, alpha), BF
                LINE (wx, rowY + 11)-(wx + MENU_WIDGET_W * f, rowY + 18), _RGBA32(80, 220, 255, alpha), BF
                LINE (wx + MENU_WIDGET_W * f - 4, rowY + 4)-STEP(8, 21), col~&, BF ' The knob
                MenuText wx + MENU_WIDGET_W + 16, rowY, SettingText$(id), 2, col~&, 0
            CASE MI_TOGGLE
                LINE (wx, rowY + 3)-STEP(22, 22), col~&, B
                IF setting(miRef(i)) THEN LINE (wx + 5, rowY + 8)-STEP(12, 12), _RGBA32(80, 220, 255, alpha), BF
                IF setting(miRef(i)) THEN MenuText wx + 36, rowY, "ON", 2, col~&, 0 ELSE MenuText wx + 36, rowY, "OFF", 2, col~&, 0
            CASE MI_CHOICE
                IF menuWide THEN MenuText wx, rowY, "<  " + SettingText$(miRef(i)) + "  >", 2, col~&, 0
            CASE MI_KEY
                IF menuCapture = i THEN
                    IF (t \ 10) MOD 2 = 0 THEN MenuText wx, rowY, "PRESS A KEY", 2, _RGBA32(255, 230, 60, alpha), 0
                ELSE
                    MenuText wx, rowY, KeyName$(keyBind&(miRef(i))), 2, col~&, 0
                END IF
        END SELECT
        IF menuTyping AND miAct(i) = MA_QB64_TYPE AND miKind(i) = MI_ACTION THEN ' The path being typed, and a cursor
            IF menuTypeBad THEN
                MenuText MENU_LABEL_X + 160 + slide, rowY + 9, "no qb64pe there: " + PathTail$(menuTyped$, 40), 1, _RGBA32(255, 90, 90, alpha), 0
            ELSE
                cur$ = " " : IF (t \ 15) MOD 2 = 0 THEN cur$ = "_"
                MenuText MENU_LABEL_X + 160 + slide, rowY + 9, PathTail$(menuTyped$, 56) + cur$, 1, _RGBA32(255, 230, 60, alpha), 0
            END IF
        ELSEIF LEN(miInfo$(i)) THEN
            MenuText MENU_LABEL_X + 160 + slide, rowY + 9, miInfo$(i), 1, col~&, 0
        END IF
    NEXT
    IF menuScreen = SCR_GAMEPLAY THEN ' What your crosshair looks like
        LINE (690, 96)-(750, 156), _RGBA32(0, 0, 0, 180), BF
        LINE (690, 96)-(750, 156), _RGBA32(90, 230, 255, 160), B
        DrawCrosshair 720, 126
    END IF
    MenuText 400, 574, "ARROWS / WASD  MOVE     ENTER  CHOOSE     ESC  BACK     OR POINT AND CLICK", 1, _RGB32(140, 135, 175), 1
END SUB

' The title menu's backdrop, t frames in: a synthwave sunset - a purple sky
' with twinkling stars, a striped sun on the horizon, and a neon grid
' rushing towards you (its lines get closer together towards the horizon:
' 260 / z is the same perspective as the floor in chapter 14)
SUB DrawMenuBackdrop(t)
    CONST HORIZON = 330
    FOR y = 0 TO HORIZON STEP 2
        f = y / HORIZON
        LINE (0, y)-(799, y + 1), _RGB32(12 + 80 * f ^ 3, 2 + 14 * f, 30 + 70 * f ^ 2), BF
    NEXT
    FOR i = 1 TO 70 ' Stars, at made-up but fixed places
        starB = 140 + 110 * SIN(t * 0.04 + i * 1.7)
        PSET ((i * 137) MOD 800, (i * 61) MOD 260), _RGB32(starB, starB, starB)
    NEXT
    FOR y = HORIZON - 120 TO HORIZON - 1 ' The sun: its lower half cut into drifting stripes
        dy = y - (HORIZON - 30) : halfW = SQR(ABS(8100 - dy * dy)) ' (radius 90)
        IF ABS(dy) <= 90 THEN
            IF NOT (y > HORIZON - 60 AND ((y + t \ 3) MOD 12) < 3 + (y - (HORIZON - 60)) \ 8) THEN
                f = (y - (HORIZON - 120)) / 120
                LINE (400 - halfW, y)-(400 + halfW, y), _RGB32(255, 220 - 160 * f, 90 + 60 * f)
            END IF
        END IF
    NEXT
    LINE (0, HORIZON)-(799, 599), _RGB32(8, 0, 18), BF
    FOR k = -24 TO 24 ' The grid's lines running away from you...
        LINE (400 + k * 14, HORIZON)-(400 + k * 110, 600), _RGBA32(255, 50, 210, 150)
    NEXT
    scroll = t * 0.04 - INT(t * 0.04) ' ...and across, moving towards you
    FOR n = 0 TO 24
        z = n + 1 - scroll
        gridY = HORIZON + 260 / z
        IF gridY < 600 THEN LINE (0, gridY)-(799, gridY), _RGBA32(255, 50, 210, 40 + 200 / z)
    NEXT
    LINE (0, HORIZON)-(799, HORIZON + 1), _RGB32(255, 130, 235), BF
END SUB

' The splash screen, t! seconds in. If there's a neon-caster/splash.png it
' fills the screen; if not, the title. It fades in, and out at the end.
SUB DrawSplash(t!)
    CLS , _RGB32(0, 0, 0)
    IF splashImg& < -1 THEN
        _PUTIMAGE (0, 0)-(799, 599), splashImg&
    ELSE
        glow = 0.6 + 0.4 * SIN(t! * 4)
        MenuText 405, 205, "NEON-CASTER", 8, _RGBA32(255, 40, 200, 130), 1
        MenuText 400, 200, "NEON-CASTER", 8, _RGB32(120 + 130 * glow, 235, 255), 1
        MenuText 400, 350, "A LITTLE RAYCASTER IN QB64PE", 2, _RGB32(255, 120, 220), 1
        IF t! > 1 AND INT(t! * 2) MOD 2 = 0 THEN MenuText 400, 520, "PRESS ANY KEY", 1, _RGB32(160, 155, 190), 1
    END IF
    fade = 1
    IF t! < 0.8 THEN fade = t! / 0.8
    IF t! > SPLASH_SECONDS - 0.6 THEN fade = (SPLASH_SECONDS - t!) / 0.6
    IF fade < 0 THEN fade = 0
    IF fade < 1 THEN LINE (0, 0)-(799, 599), _RGBA32(0, 0, 0, 255 * (1 - fade)), BF
END SUB

' Text at any size and see-through-ness: printed at normal size into a small
' see-through image, then stretched onto the screen with _PUTIMAGE, which
' blends it in by its colour's alpha. align: 0 starts at x, 1 centres on x,
' 2 ends at x.
SUB MenuText(x, y, text$, scale, col~&, align)
    IF LEN(text$) = 0 THEN EXIT SUB
    textW = LEN(text$) * 8
    img& = _NEWIMAGE(textW, 16, 32)
    _DEST img& : _PRINTMODE _KEEPBACKGROUND : COLOR col~& : _PRINTSTRING (0, 0), text$ : _DEST 0
    textX = x
    IF align = 1 THEN textX = x - textW * scale / 2
    IF align = 2 THEN textX = x - textW * scale
    _PUTIMAGE (textX, y)-STEP(textW * scale - 1, 16 * scale - 1), img&, 0
    _FREEIMAGE img&
END SUB

' The crosshair at (cx, cy), in the style, colour, size and opacity the
' settings say - and as big as crossScale and as white as crossFlash say
SUB DrawCrosshair(cx, cy)
    col~& = CrossColor~&(setting(SET_XCOLOR))
    IF crossFlash > 0 THEN col~& = _RGB32(255, 255, 255) ' A hit!
    col~& = _RGBA32(_RED32(col~&), _GREEN32(col~&), _BLUE32(col~&), setting(SET_XALPHA) * 255 / 100)
    armLen = (2 + setting(SET_XSIZE) * 2) * crossScale
    SELECT CASE setting(SET_XSTYLE)
        CASE 1 ' Cross
            LINE (cx - armLen, cy)-(cx + armLen, cy), col~& : LINE (cx, cy - armLen)-(cx, cy + armLen), col~&
        CASE 2 ' Dot
            LINE (cx - armLen \ 4, cy - armLen \ 4)-(cx + armLen \ 4, cy + armLen \ 4), col~&, BF
        CASE 3 ' Circle
            CIRCLE (cx, cy), armLen, col~&
        CASE 4 ' A cross with a gap in the middle, and a dot
            gap = armLen \ 2 + 1
            LINE (cx - armLen - 2, cy)-(cx - gap, cy), col~& : LINE (cx + gap, cy)-(cx + armLen + 2, cy), col~&
            LINE (cx, cy - armLen - 2)-(cx, cy - gap), col~& : LINE (cx, cy + gap)-(cx, cy + armLen + 2), col~&
            PSET (cx, cy), col~&
        CASE 5 ' Chevron
            LINE (cx - armLen, cy + armLen)-(cx, cy), col~& : LINE (cx, cy)-(cx + armLen, cy + armLen), col~&
    END SELECT ' (6: none)
END SUB

FUNCTION CrossStyleName$(n)
    SELECT CASE n
        CASE 1 : CrossStyleName$ = "CROSS"
        CASE 2 : CrossStyleName$ = "DOT"
        CASE 3 : CrossStyleName$ = "CIRCLE"
        CASE 4 : CrossStyleName$ = "GAP CROSS"
        CASE 5 : CrossStyleName$ = "CHEVRON"
        CASE ELSE : CrossStyleName$ = "NONE"
    END SELECT
END FUNCTION

FUNCTION CrossColorName$(n)
    CrossColorName$ = RTRIM$(MID$("RED    GREEN  CYAN   YELLOW WHITE  MAGENTA", (n - 1) * 7 + 1, 7))
END FUNCTION

FUNCTION CrossColor~&(n)
    SELECT CASE n
        CASE 1 : CrossColor~& = _RGB32(255, 40, 40)
        CASE 2 : CrossColor~& = _RGB32(60, 255, 90)
        CASE 3 : CrossColor~& = _RGB32(60, 230, 255)
        CASE 4 : CrossColor~& = _RGB32(255, 230, 40)
        CASE 5 : CrossColor~& = _RGB32(255, 255, 255)
        CASE ELSE : CrossColor~& = _RGB32(255, 60, 220)
    END SELECT
END FUNCTION

' Something to ask before you leave, picked at random each time
FUNCTION QuitQuote$
    SELECT CASE INT(RND * 10)
        CASE 0 : QuitQuote$ = "FLEE FROM THIS PLACE?"
        CASE 1 : QuitQuote$ = "RUN AWAY?"
        CASE 2 : QuitQuote$ = "ABANDON THE SECTOR?"
        CASE 3 : QuitQuote$ = "LEAVE IT TO THE DRONES?"
        CASE 4 : QuitQuote$ = "GIVE UP SO SOON?"
        CASE 5 : QuitQuote$ = "THE NEON WILL MISS YOU. GO?"
        CASE 6 : QuitQuote$ = "BACK TO THE REAL WORLD?"
        CASE 7 : QuitQuote$ = "THE HEAVIES ARE HUNGRY. LEAVE?"
        CASE 8 : QuitQuote$ = "SURRENDER THE STATION?"
        CASE ELSE : QuitQuote$ = "LOG OFF, OPERATIVE?"
    END SELECT
END FUNCTION

' A music track from neon-caster/music/ (0 if it's missing: no music)
FUNCTION LoadMusic&(file$)
    path$ = AssetPath$("music/" + file$)
    ' "stream": played straight from the file a little at a time, not
    ' unpacked into memory first (a 3-minute track would be 60 MB). And
    ' everything else is loaded "noasync" - unpacked there and then, not
    ' in the background: QB64PE 4.7 can crash if a sound is still being
    ' unpacked in the background while another one opens.
    IF _FILEEXISTS(path$) THEN LoadMusic& = _SNDOPEN(path$, "stream, noasync")
END FUNCTION

' Play a music track on a loop (_SNDLOOP), at the MUSIC VOLUME setting,
' stopping the one before. Asking for the track already playing changes
' nothing, so it doesn't restart.
SUB PlayMusic(snd&)
    IF snd& = nowPlaying& THEN EXIT SUB
    IF nowPlaying& > 0 THEN _SNDSTOP nowPlaying&
    nowPlaying& = snd&
    IF snd& > 0 THEN _SNDVOL snd&, setting(SET_MUSIC) / 100 : _SNDLOOP snd&
END SUB

' === LIGHT AND THE MAP (chapters 14 and 18) ====================================

' One more light for this level: where, how far it reaches, its light for
' red, green and blue (brightness times colour), its effect (FX_), and the
' decoration it belongs to (0 for none)
SUB AddLight(x, y, radius, r, g, b, effect, deco)
    IF numLights >= MAX_LIGHTS THEN EXIT SUB
    numLights = numLights + 1
    lightX(numLights) = x : lightY(numLights) = y : lightRadius(numLights) = radius
    lightR(numLights) = r : lightG(numLights) = g : lightB(numLights) = b
    lightEffect(numLights) = effect : lightDeco(numLights) = deco
    lightPhase(numLights) = RND * 6.28 : lightTimer(numLights) = 0 ' (so no two flicker in step)
END SUB

' Work out, once per level, which cells each light reaches and how
' strongly: every cell within its radius that it can see (LightReaches),
' brightest at the light and fading to nothing at the radius. Walls don't
' move, so this never changes - each frame only has to add the lists up.
SUB BuildLights
    numLit = 0
    FOR l = 1 TO numLights
        lightFirst(l) = numLit + 1 : lightCount(l) = 0 : rad = lightRadius(l)
        FOR cellY = INT(lightY(l) - rad) TO INT(lightY(l) + rad)
            FOR cellX = INT(lightX(l) - rad) TO INT(lightX(l) + rad)
                IF cellX >= 0 AND cellX < MAP_SIZE AND cellY >= 0 AND cellY < MAP_SIZE THEN
                    ' Aim at the middle of the cell - or, for a diagonal wall's
                    ' cell, the middle of its open half
                    aimX = cellX + 0.5 : aimY = cellY + 0.5
                    SELECT CASE diagCorner(cellX, cellY)
                        CASE 1 : aimX = cellX + 0.75 : aimY = cellY + 0.75
                        CASE 2 : aimX = cellX + 0.25 : aimY = cellY + 0.75
                        CASE 3 : aimX = cellX + 0.25 : aimY = cellY + 0.25
                        CASE 4 : aimX = cellX + 0.75 : aimY = cellY + 0.25
                    END SELECT
                    d = SQR((aimX - lightX(l)) ^ 2 + (aimY - lightY(l)) ^ 2)
                    IF d < rad AND numLit < MAX_LIT AND (NOT IsWall(cellX, cellY) OR diagCorner(cellX, cellY) <> 0) THEN
                        IF LightReaches(lightX(l), lightY(l), aimX, aimY) THEN
                            numLit = numLit + 1 : lightCount(l) = lightCount(l) + 1
                            litCellX(numLit) = cellX : litCellY(numLit) = cellY : litWeight(numLit) = (1 - d / rad) ^ 2
                        END IF
                    END IF
                END IF
            NEXT
        NEXT
    NEXT
END SUB

' Can light get from (x1, y1) to (x2, y2)? Step along the line a quarter of
' a cell at a time; a wall on the way stops it (doors and decorations don't).
FUNCTION LightReaches(x1, y1, x2, y2)
    dist = SQR((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    steps = INT(dist / 0.25) + 1
    FOR i = 1 TO steps - 1
        IF SolidAt(x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps) THEN EXIT FUNCTION
    NEXT
    LightReaches = -1
END FUNCTION

' This frame's light: every cell starts at the level's ambient light, then
' each light adds its share - times its effect right now: a flickering
' tube drops out for a few frames now and then, a pulse rises and falls,
' a strobe blinks twice a second, firelight jitters, and a dying tube is
' mostly dark but sputters on. A broken lamp's light is out for good.
SUB UpdateLight
    IF cyberOn THEN ' The network: no lamps, no shadows - everything lit the same
        FOR cellY = 0 TO MAP_SIZE - 1 : FOR cellX = 0 TO MAP_SIZE - 1
            litR(cellX, cellY) = 200 : litG(cellX, cellY) = 200 : litB(cellX, cellY) = 230
            litSumX(cellX, cellY) = 0 : litSumY(cellX, cellY) = 0 : litSumW(cellX, cellY) = 0
        NEXT : NEXT
        FOR l = 1 TO numLights : lightNow(l) = 0 : NEXT
        EXIT SUB
    END IF
    FOR cellY = 0 TO MAP_SIZE - 1 : FOR cellX = 0 TO MAP_SIZE - 1
        litR(cellX, cellY) = ambientR : litG(cellX, cellY) = ambientG : litB(cellX, cellY) = ambientB
        IF blackoutTimer > 0 THEN litR(cellX, cellY) = ambientR \ 4 : litG(cellX, cellY) = ambientG \ 5 : litB(cellX, cellY) = ambientB \ 4 ' (a power failure: darker)
        litSumX(cellX, cellY) = 0 : litSumY(cellX, cellY) = 0 : litSumW(cellX, cellY) = 0
    NEXT : NEXT
    FOR l = 1 TO numLights
        f = 1
        SELECT CASE lightEffect(l)
            CASE FX_FLICKER
                IF lightTimer(l) > 0 THEN
                    lightTimer(l) = lightTimer(l) - 1 : f = 0.15
                ELSEIF RND < 0.025 THEN
                    lightTimer(l) = 2 + INT(RND * 6)
                END IF
            CASE FX_PULSE
                f = 0.55 + 0.45 * SIN(TIMER * 2.4 + lightPhase(l))
            CASE FX_STROBE
                IF INT(TIMER * 2 + lightPhase(l)) MOD 2 = 0 THEN f = 1 ELSE f = 0.05
            CASE FX_FIRE
                f = 0.75 + RND * 0.25
            CASE FX_DYING
                f = 0.08
                IF lightTimer(l) > 0 THEN
                    lightTimer(l) = lightTimer(l) - 1 : f = 0.5 + RND * 0.5
                ELSEIF RND < 0.03 THEN
                    lightTimer(l) = 3 + INT(RND * 10)
                END IF
        END SELECT
        IF lightDeco(l) THEN
            IF NOT decoOn(lightDeco(l)) THEN f = 0
        END IF
        IF lightBroken(l) THEN f = 0 ' (shot out)
        IF blackoutTimer > 0 AND lightEffect(l) <> FX_STROBE THEN f = f * 0.05 ' (no power: only the alarms)
        lightNow(l) = f
        IF f > 0 THEN
            r = lightR(l) * f : g = lightG(l) * f : b = lightB(l) * f
            FOR e = lightFirst(l) TO lightFirst(l) + lightCount(l) - 1
                cellX = litCellX(e) : cellY = litCellY(e) : w = litWeight(e)
                litR(cellX, cellY) = litR(cellX, cellY) + r * w
                litG(cellX, cellY) = litG(cellX, cellY) + g * w
                litB(cellX, cellY) = litB(cellX, cellY) + b * w
                strength = (r + g + b) * w ' (and where it comes from: chapter 24's bumps)
                litSumX(cellX, cellY) = litSumX(cellX, cellY) + lightX(l) * strength
                litSumY(cellX, cellY) = litSumY(cellX, cellY) + lightY(l) * strength
                litSumW(cellX, cellY) = litSumW(cellX, cellY) + strength
            NEXT
        END IF
    NEXT
END SUB

' A quick glow at (x, y) for this frame only - a muzzle flash, a blast, a
' bolt: brightest in the middle, gone at radius. It doesn't check for walls
' (it's only for a moment, and that's much cheaper).
SUB AddGlow(x, y, radius, r, g, b)
    FOR cellY = INT(y - radius) TO INT(y + radius)
        FOR cellX = INT(x - radius) TO INT(x + radius)
            IF cellX >= 0 AND cellX < MAP_SIZE AND cellY >= 0 AND cellY < MAP_SIZE THEN
                d = SQR((cellX + 0.5 - x) ^ 2 + (cellY + 0.5 - y) ^ 2)
                IF d < radius THEN
                    w = (1 - d / radius) ^ 2
                    litR(cellX, cellY) = litR(cellX, cellY) + r * w
                    litG(cellX, cellY) = litG(cellX, cellY) + g * w
                    litB(cellX, cellY) = litB(cellX, cellY) + b * w
                    strength = (r + g + b) * w ' (where it comes from, for bumps)
                    litSumX(cellX, cellY) = litSumX(cellX, cellY) + x * strength
                    litSumY(cellX, cellY) = litSumY(cellX, cellY) + y * strength
                    litSumW(cellX, cellY) = litSumW(cellX, cellY) + strength
                END IF
            END IF
        NEXT
    NEXT
END SUB

' Light a colour: its red, green and blue each times their light / 256
' (more than 256 brightens, up to full). Each channel is masked out of
' &HAARRGGBB on its own, multiplied, and put back.
FUNCTION ShadeRGB~&(col AS _UNSIGNED LONG, lr AS LONG, lg AS LONG, lb AS LONG)
    red& = ((col AND &HFF0000) \ 65536) * lr \ 256 : IF red& > 255 THEN red& = 255
    green& = ((col AND &HFF00&) \ 256) * lg \ 256 : IF green& > 255 THEN green& = 255
    blue& = (col AND 255) * lb \ 256 : IF blue& > 255 THEN blue& = 255
    ShadeRGB~& = &HFF000000~& OR (red& * 65536) OR (green& * 256) OR blue&
END FUNCTION

' The map, cellSize pixels a cell, its top-left at (mapLeft, mapTop): all of
' it (showAll), or only the cells you've seen. Walls are their texture's
' colour; doors orange (key doors their card's colour, with a dark centre)
' when shut, white while opening, green when open; the exit blinks green;
' on the big map the floor you've seen is a dim blue. Then keycards, and
' you - an arrow pointing the way you face.
SUB DrawMap(mapLeft, mapTop, cellSize, showAll, px, py, facingX, facingY)
    LINE (mapLeft - 2, mapTop - 2)-(mapLeft + MAP_SIZE * cellSize + 1, mapTop + MAP_SIZE * cellSize + 1), _RGBA32(0, 0, 0, 160), BF
    FOR cellY = 0 TO MAP_SIZE - 1 : FOR cellX = 0 TO MAP_SIZE - 1
        IF showAll OR cellSeen(cellX, cellY) THEN
            mmColor~& = 0
            SELECT CASE worldMap(cellX, cellY)
                CASE 0
                    IF cellSize > 4 THEN mmColor~& = _RGBA32(40, 50, 95, 150)
                    IF glassHP(cellX, cellY) > 0 THEN mmColor~& = _RGB32(130, 220, 255) ' (glass)
                CASE 1, 3 TO 9
                    mmColor~& = wallMapColor(worldMap(cellX, cellY))
                CASE 2
                    IF doorType(cellX, cellY) = DOOR_EXIT THEN
                        IF (TIMER * 4 AND 1) = 0 THEN mmColor~& = _RGB32(80, 255, 120) ELSE mmColor~& = _RGB32(20, 120, 50)
                    ELSEIF doorOpen(cellX, cellY) = 0 THEN
                        IF doorKey(cellX, cellY) THEN mmColor~& = CardRGB~&(doorKey(cellX, cellY)) ELSE mmColor~& = _RGB32(255, 140, 20)
                    ELSEIF doorOpen(cellX, cellY) < 1 THEN
                        mmColor~& = _RGB32(230, 230, 230)
                    ELSE
                        mmColor~& = _RGB32(40, 200, 80)
                    END IF
            END SELECT
            sx = mapLeft + cellX * cellSize : sy = mapTop + cellY * cellSize
            IF mmColor~& <> 0 AND diagCorner(cellX, cellY) <> 0 THEN ' Diagonal: just its solid half
                FOR pixY = 0 TO cellSize - 1 : FOR pixX = 0 TO cellSize - 1
                    IF InDiagonalWall(diagCorner(cellX, cellY), (pixX + 0.5) / cellSize, (pixY + 0.5) / cellSize) THEN PSET (sx + pixX, sy + pixY), mmColor~&
                NEXT : NEXT
            ELSEIF mmColor~& THEN
                LINE (sx, sy)-STEP(cellSize - 1, cellSize - 1), mmColor~&, BF
                IF doorKey(cellX, cellY) AND doorOpen(cellX, cellY) = 0 THEN LINE (sx + cellSize \ 3, sy + cellSize \ 3)-STEP(cellSize \ 3, cellSize \ 3), _RGB32(0, 0, 0), BF
            END IF
        END IF
    NEXT : NEXT
    IF (TIMER * 4 AND 1) = 0 THEN ' Keycards blink
        FOR i = 1 TO numItems
            IF itemOn(i) AND itemKind(i) <= 3 AND (showAll OR cellSeen(INT(itemX(i)), INT(itemY(i)))) THEN
                LINE (mapLeft + itemX(i) * cellSize - cellSize \ 3 - 1, mapTop + itemY(i) * cellSize - cellSize \ 3 - 1)-STEP(cellSize \ 1.5 + 1, cellSize \ 1.5 + 1), CardRGB~&(itemKind(i)), BF
            END IF
        NEXT
    END IF
    ' You: an arrow - its tip ahead of you, its tail corners behind you
    ax = mapLeft + px * cellSize : ay = mapTop + py * cellSize : arrow = cellSize * 1.2 + 2
    tipX = ax + facingX * arrow : tipY = ay + facingY * arrow
    leftX = ax - facingX * arrow * 0.5 + facingY * arrow * 0.5 : leftY = ay - facingY * arrow * 0.5 - facingX * arrow * 0.5
    rightX = ax - facingX * arrow * 0.5 - facingY * arrow * 0.5 : rightY = ay - facingY * arrow * 0.5 + facingX * arrow * 0.5
    LINE (tipX, tipY)-(leftX, leftY), _RGB32(255, 255, 0) : LINE (leftX, leftY)-(rightX, rightY), _RGB32(255, 255, 0)
    LINE (rightX, rightY)-(tipX, tipY), _RGB32(255, 255, 0)
END SUB

' A damage indicator for a hit that came from (x, y): into a free slot, or
' over the one that's nearly faded
SUB AddHurtDir(x, y)
    slot = 1
    FOR i = 1 TO MAX_HURTDIRS
        IF hurtDirTime(i) < hurtDirTime(slot) THEN slot = i
    NEXT
    hurtDirX(slot) = x : hurtDirY(slot) = y : hurtDirTime(slot) = HURTDIR_FRAMES
END SUB

' The damage indicators, for you at (px, py) facing (facingX, facingY): a
' red arc round the crosshair for each recent hit, at the angle it came
' from - straight up is in front of you, right is to your right - fading
' as it gets older.
SUB DrawHurtDirs(px, py, facingX, facingY)
    FOR i = 1 TO MAX_HURTDIRS
        IF hurtDirTime(i) > 0 THEN
            hurtDirTime(i) = hurtDirTime(i) - 1
            relX = hurtDirX(i) - px : relY = hurtDirY(i) - py
            ahead = relX * facingX + relY * facingY ' How far in front of you...
            across = relX * facingY - relY * facingX ' ...and to your right (along the camera plane)
            angle = _ATAN2(across, ahead) ' 0 = straight ahead
            fade = hurtDirTime(i) / HURTDIR_FRAMES
            FOR radius = 92 TO 104 STEP 2 ' A thick arc, 40 degrees wide
                FOR k = -10 TO 9
                    a1 = angle + k * 0.035 : a2 = a1 + 0.035
                    LINE (400 + SIN(a1) * radius, 300 - COS(a1) * radius)-(400 + SIN(a2) * radius, 300 - COS(a2) * radius), _RGBA32(255, 30, 30, 230 * fade * (1 - ABS(k + 0.5) / 11))
                NEXT
            NEXT
            ' ...and a small arrowhead at its outer edge, pointing that way
            tipX = 400 + SIN(angle) * 118 : tipY = 300 - COS(angle) * 118
            LINE (tipX, tipY)-(400 + SIN(angle - 0.09) * 106, 300 - COS(angle - 0.09) * 106), _RGBA32(255, 80, 60, 255 * fade)
            LINE (tipX, tipY)-(400 + SIN(angle + 0.09) * 106, 300 - COS(angle + 0.09) * 106), _RGBA32(255, 80, 60, 255 * fade)
        END IF
    NEXT
END SUB


'-----------------------------------------------------------------------------
' CHAPTER 24: THE SAME VIEW, DRAWN BY THE GRAPHICS CARD (OPENGL)
'-----------------------------------------------------------------------------
' Chapters 14-16 work out each of the view's 120,000 pixels in BASIC, one
' at a time. That is exactly the job a graphics card is built for: it has
' thousands of little processors that colour in pixels side by side.
' QB64PE puts its window on the screen with OpenGL (the graphics card's
' language), and it lets us join in. Give the program a SUB called _GL and
' QB64PE calls it every time it draws the window; inside it, the _gl...
' commands talk to the card. Set RENDERER to OPENGL in the menu (SETTINGS >
' VIDEO) and the 3D view is drawn here instead. Turn on SHOW FPS to compare
' how long the two take.
'
' SHAPES, NOT PIXELS. We don't tell the card about pixels. We describe the
' world as triangles in 3D - two for each wall face, floor tile and ceiling
' tile - each corner with a position, a spot on a texture and a colour,
' and the card fills in every pixel in between. Positions are map cells,
' plus a height: the floor is at 0, the ceiling at 1, your eye at 0.5.
'
' THE CAMERA is two matrices (tables of numbers that move points around).
' The first, glMat, turns a map point into "camera space": how far to your
' right, how far up, and how far in front - the same sum as chapter 16's
' transformX and transformY, written as a table. The second, _glFrustum,
' is the perspective: how far up and across the view reaches at 1 cell
' away. Across, that's the camera plane's length (chapter 8). Up, half a
' wall is half the view's height at 1 cell away (a wall one cell away is
' viewH pixels tall, chapter 15), so the top is 1 / (2 * zoom). These are
' the raycaster's own numbers, so both renderers show the very same view.
'
' TEXTURES go to the card once (GLSendTextures), straight from texture()
' and spriteTex(). An array keeps its first index changing fastest, so
' texture(x, y, slot) holds slot's picture in memory row after row, just as
' the card wants it. A colour &HAARRGGBB is stored as the bytes B, G, R, A
' (low byte first), which is the card's "BGRA". _GL_NEAREST picks the one
' nearest texture pixel, with no smoothing, so it stays chunky.
'
' LIGHT AND FOG. Every frame the game puts each cell's light into three
' small tables (glLitData..., chapter 17) that go to the card as textures,
' and the world shader looks a pixel's light up in them: the cell in front
' of the surface, times the fog (256 - distance * 16, as in chapters 14 and
' 15), y-sides darker and diagonals in between, as before. (Without
' shaders, each corner gets that colour instead, and the card blends it.)
'
' WHAT TO DRAW. All of it! The floor and ceiling of every open cell and
' every wall face that looks onto one go into the WORLD MESH when the level
' loads (GLBuildMesh), kept in the card's memory, and each frame it's drawn
' whole - a few dozen commands, one per texture - and the depth buffer
' hides what you can't see. However big the room, the work is the same.
' (Without shaders, the raycaster's rays mark the cells they pass - glSeen,
' chapter 15 - and those cells and their neighbours are drawn corner by
' corner instead.) Only what moves is built each frame: the doors, and
' the sprites, shadows, glows and particles. A sliding door is the part of
' the face it still covers, its texture slid along, and a shutter is the
' part that's still down. A diagonal wall
' is one face across its cell, and a split floor is two triangles with
' different textures. The card keeps a "depth buffer" - the zBuffer idea,
' kept for every pixel, not just every column - so whatever is nearest
' ends up in front, whatever order we draw in.
'
' SPRITES are rectangles that face you. The "alpha test" skips their see-
' through pixels (alpha 128 or less, as chapter 16 does) - and since the
' depth buffer works per pixel, they hide behind walls by themselves.
'
' WHEN IT RUNS. QB64PE calls SUB _GL when it's ready to draw the window -
' the game is paused between two of its lines while it runs, and that can
' be anywhere. Halfway through UpdateLight, half the cells would have their
' light and half wouldn't. So SUB _GL only ever reads the finished
' snapshot that chapter 17 hands over (glBuf), and things that only change
' as a level loads (worldMap, the textures) - and while a level loads,
' glReady is 0 and it draws nothing.
'
' THE HUD is drawn on our screen, as usual - but then copied to the card
' as a picture (GLSL_filter_capture, chapter 18) and laid over the 3D view
' there (GLDrawHUD), with our own screen layer switched off. That way the
' screen effects below can bend and scanline it too.
'
' THE EXTRAS (SETTINGS > EFFECTS): bump mapping, smooth light, neon,
' moving lights, shadows, glows, particles, wet floors, bloom, screen and
' hit effects - and in SETTINGS > VIDEO, the resolution and looking up
' and down. Most are done with shaders: little programs the card runs for
' every corner and every pixel (GLBuildShaders, near the end of the
' chapter, explains them).
'
' What's different? The view is drawn at the window's full size (or the
' RESOLUTION you pick), not half size, so its edges are sharp (the
' textures stay chunky). So is the gun - it gets its own picture on the
' card (GLDrawGun), so a gun drawn in more detail shows it. Sprites can't
' be lit brighter than their picture (a colour can't go past 1 on the
' card). Otherwise, it's the same game - same maths, same light.
SUB _GL
    IF NOT glReady THEN EXIT SUB ' Nothing to draw (or the software renderer is on)
    IF artHold THEN glArtAck = -1 : EXIT SUB ' (the pictures are being reloaded: ArtReload)
    glStart# = TIMER(0.001)
    b = glBuf ' The newest finished snapshot
    IF glTexDone <> glTexVersion THEN GLSendTextures : glMeshClient = 0 : GLBuildMesh : glMeshDone = glMeshVersion ' (a new level)
    IF glMeshDone <> glMeshVersion THEN glMeshClient = -1 : GLBuildMesh : glMeshDone = glMeshVersion ' (the map changed: a closet opened)
    IF glRetexDone <> glRetexVersion THEN GLSendTextures : glRetexDone = glRetexVersion ' (the pictures changed: in or out of the network)
    IF glGunDone <> glGunVersion THEN GLSendGuns : glGunDone = glGunVersion ' (the guns' pictures: at the start, and when ART changes)
    IF glWorldTried = 0 THEN GLBuildShaders
    glGPU = (glWorldProg <> 0 AND (glMeshBuf <> 0 OR glMeshClient)) ' The world mesh, lit by the shader from the light tables

    ' Where on the window to draw: all of it - or, in full screen with
    ' _SQUAREPIXELS, the middle part QB64PE letterboxes the screen into.
    ' The window's size comes from GLFW (the library QB64PE makes windows
    ' with), not from asking OpenGL: an OpenGL question makes the program
    ' wait until the card has caught up, and on Mesa's drivers (Linux) that
    ' can mean waiting for the screen's next refresh - asked every frame,
    ' that wait ate whole frames (2 frames a second!).
    vx = 0 : vy = 0 : vw = GLSL_window_width& : vh = GLSL_window_height&
    IF vw < 1 OR vh < 1 THEN EXIT SUB
    IF glFullMode(b) = 2 THEN
        IF vw * 600 > vh * 800 THEN
            w = INT(vh * 800 / 600) : vx = INT((vw - w) / 2) : vw = w
        ELSE
            h = INT(vw * 600 / 800) : vy = INT((vh - h) / 2) : vh = h
        END IF
    END IF
    ' That's where our screen is (the HUD, the gun, the menus: hx, hy, hw,
    ' hh). FULL WIDE: the 3D view fills the whole window, and sees as much
    ' more to the sides as the window is wider than 4:3 (glAspectK).
    hx = vx : hy = vy : hw = vw : hh = vh : glAspectK = 1
    IF glWide(b) > 1.01 AND glFullMode(b) = 1 AND vw * 3 > vh * 4 THEN
        hw = INT(vh * 4 / 3) : hx = INT((vw - hw) / 2) ' (the window, stretched: our screen in its middle)
        glAspectK = vw / vh * 3 / 4
    END IF

    ' POST-PROCESSING. With BLOOM, a SCREEN FX, HIT FX or a RESOLUTION
    ' other than NATIVE on, the 3D view isn't drawn on the window but into
    ' a texture (a "render target", from the GLSL library) - so that
    ' afterwards a shader can read the finished picture and do things to
    ' all of it at once (GLPostProcess). With a RESOLUTION, that texture is
    ' its size (ResSize) and gets stretched over the window: smoothly - or
    ' for RETRO, the software renderer's 400 x 300, with square pixels, as
    ' chapter 17 does. A size bigger than the window is smoother than the
    ' window's own: each pixel is the average of the several drawn for it
    ' ("supersampling" - the dearest way to get smooth edges).
    glPost = 0 : res = glSet(SET_RES, b)
    IF glPostProg <> 0 THEN
        IF glSet(SET_BLOOM, b) OR glSet(SET_SCREENFX, b) > 1 OR glSet(SET_HITFX, b) OR glSet(SET_PHOSPHOR, b) OR res <> RES_NATIVE THEN glPost = -1
    END IF
    IF glPost THEN
        sw = vw : sh = vh
        IF res <> RES_NATIVE THEN ResSize res, sw, sh
        IF NOT GLMakeTargets(sw, sh, res = RES_RETRO) THEN glPost = 0
    END IF
    IF glPost THEN
        GLSL_target_use glTargScene : _glViewport 0, 0, sw, sh
        _glClearColor 0, 0, 0, 1 : _glClear _GL_COLOR_BUFFER_BIT OR _GL_DEPTH_BUFFER_BIT
    ELSE
        _glViewport vx, vy, vw, vh
        _glClear _GL_DEPTH_BUFFER_BIT
    END IF

    ' The perspective (and the screen shake: the view nudged by shakeX,
    ' shakeY and made shakeEdge pixels bigger all round, as in chapter 17)
    _glMatrixMode _GL_PROJECTION
    _glLoadIdentity
    _glTranslatef glShakeX(b) / 400, -glShakeY(b) / 300, 0
    _glScalef 1 + glShakeEdge(b) / 400, 1 + glShakeEdge(b) / 300, 1
    halfW# = glPlaneLen(b) * GL_NEAR * glAspectK : halfH# = GL_NEAR / (2 * glZoom(b))
    _glFrustum -halfW#, halfW#, -halfH#, halfH#, GL_NEAR, GL_FAR

    _glEnable _GL_DEPTH_TEST
    _glEnable _GL_TEXTURE_2D
    _glDisable _GL_BLEND
    _glDisable _GL_CULL_FACE
    _glEnableClientState _GL_VERTEX_ARRAY ' (GLDraw hands over arrays of these three)
    _glEnableClientState _GL_TEXTURE_COORD_ARRAY
    _glEnableClientState _GL_COLOR_ARRAY

    ' The cells to draw: the ones this frame's rays reached, and their
    ' neighbours
    glEyeX = glCamX(b) : glEyeY = glCamY(b) : glEyeDX = glDirX(b) : glEyeDY = glDirY(b) : glEyeZ = glCamZ(b)
    stamp& = glFrame(b) : glNumVis = 0
    IF glGPU THEN GOTO SkipVisible ' (the world mesh is drawn whole: the card's depth buffer hides what you can't see)
    FOR cy = 0 TO MAP_SIZE - 1 : FOR cx = 0 TO MAP_SIZE - 1
        near = glSeen(cx, cy, b) = stamp& OR glSeen(cx + 1, cy, b) = stamp& OR glSeen(cx, cy + 1, b) = stamp&
        IF cx > 0 THEN IF glSeen(cx - 1, cy, b) = stamp& THEN near = -1
        IF cy > 0 THEN IF glSeen(cx, cy - 1, b) = stamp& THEN near = -1
        IF near THEN glNumVis = glNumVis + 1 : glVisX(glNumVis) = cx : glVisY(glNumVis) = cy
    NEXT : NEXT
    SkipVisible:
    IF glGPU THEN GLSendLightTables b

    ' WET FLOORS: first the whole world upside down, below the floor - a
    ' mirror image (GLCamera with mirror on flips every height) - then the
    ' real world over it, its floors a little see-through so the mirror
    ' image shows in them, more on ice and wet floors than on concrete.
    ' The mirror flips round the main floor (height 0), so anything really
    ' below it - a pit's sides, a sunken room's walls - would come out
    ' above it, hanging in the air: the shader leaves those out (mirrorCut).
    glReflecting = 0
    IF glSet(SET_REFLECT, b) AND glWorldProg <> 0 THEN
        GLCamera b, -1
        IF glGPU THEN GLWorldGPU b, -1 ELSE GLWorld b, -1
        glReflecting = -1
    END IF
    GLCamera b, 0
    IF glGPU THEN GLWorldGPU b, 0 ELSE GLWorld b, 0

    ' Then the finished picture: through the post-processing shader onto
    ' the window, with the HUD on top - or, without post-processing, just
    ' the HUD, laid over the view already on the window
    _glDisableClientState _GL_VERTEX_ARRAY : _glDisableClientState _GL_TEXTURE_COORD_ARRAY : _glDisableClientState _GL_COLOR_ARRAY
    _glDisable _GL_DEPTH_TEST
    IF glPost THEN
        GLSL_target_use 0
        GLPostProcess b, vx, vy, vw, vh, sw, sh, hx, hy, hw, hh
    ELSE
        _glViewport hx, hy, hw, hh ' (our screen: all of the view, but for FULL WIDE)
        GLDrawGun b
        GLDrawHUD
    END IF

    ' A screenshot asked for: the whole window, read back into glShotMem
    ' (asking OpenGL for pixels makes it wait for the card - fine once)
    IF glShotReq = 1 THEN
        ww& = GLSL_window_width& : wh& = GLSL_window_height&
        IF ww& > 0 AND wh& > 0 THEN
            glShotMem = _MEMNEW(ww& * wh& * 4) : glShotW = ww& : glShotH = wh&
            _glPixelStorei _GL_PACK_ALIGNMENT, 4
            _glReadPixels 0, 0, ww&, wh&, _GL_BGRA_EXT, _GL_UNSIGNED_BYTE, glShotMem.OFFSET
            glShotReq = 2
        END IF
    END IF

    ' Leave OpenGL as we found it
    FOR u = 3 TO 1 STEP -1 : GLSL_texture_unit u : _glBindTexture _GL_TEXTURE_2D, 0 : NEXT : GLSL_texture_unit 0
    _glDisable _GL_TEXTURE_2D : _glDisable _GL_BLEND
    _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA
    _glBindTexture _GL_TEXTURE_2D, 0
    _glColor4f 1, 1, 1, 1
    _glMatrixMode _GL_PROJECTION : _glLoadIdentity
    _glMatrixMode _GL_MODELVIEW : _glLoadIdentity
    glMs = (TIMER(0.001) - glStart#) * 1000 ' (for SHOW FPS)
    IF glMs < 0 THEN glMs = 0 ' (TIMER went back to 0 at midnight)
END SUB

' The camera: a map point (x, y) at height z becomes
'   right = (x - playerX) * dirY - (y - playerY) * dirX  (along the plane)
'   up    = z - 0.5                                     (your eye)
'   ahead = (x - playerX) * dirX + (y - playerY) * dirY
' and OpenGL looks down its -z, so "ahead" goes in as minus. glMat holds
' those three sums' numbers, a column at a time. Two twists:
'   mirror  turns every height upside down first (z becomes -z): the world
'           reflected in the floor, for WET FLOORS
'   pitch   tilts the camera up or down (LOOK UP / DOWN): "up" and "ahead"
'           are turned round each other by the angle, the way chapter 8
'           turns dirX and dirY round each other to turn you left or right
SUB GLCamera(b, mirror)
    glMat(0) = glEyeDY : glMat(4) = -glEyeDX : glMat(8) = 0 : glMat(12) = -(glEyeX * glEyeDY - glEyeY * glEyeDX)
    glMat(1) = 0 : glMat(5) = 0 : glMat(9) = 1 : glMat(13) = -glEyeZ ' (your eye's height: 0.5 on level ground)
    glMat(2) = -glEyeDX : glMat(6) = -glEyeDY : glMat(10) = 0 : glMat(14) = glEyeX * glEyeDX + glEyeY * glEyeDY
    glMat(3) = 0 : glMat(7) = 0 : glMat(11) = 0 : glMat(15) = 1
    IF mirror THEN glMat(9) = -1 ' (z -> -z)
    c = COS(glPitch(b)) : s = SIN(glPitch(b))
    FOR col = 0 TO 3
        up = glMat(col * 4 + 1) : back = glMat(col * 4 + 2)
        glMat(col * 4 + 1) = c * up + s * back : glMat(col * 4 + 2) = -s * up + c * back
    NEXT
    _glMatrixMode _GL_MODELVIEW
    _glLoadMatrixf _OFFSET(glMat(0))
END SUB

' THE WORLD, THE FAST WAY (with the world shader). The walls, floors and
' ceilings don't move, so instead of working out every corner again each
' frame (GLWorld), they were built once, when the level loaded, into the
' world mesh (GLBuildMesh) in graphics memory. Each frame just draws it: a
' few dozen commands - one per kind and texture - however much you can see.
' The light that changes every frame isn't in the mesh: the shader looks
' it up per pixel in the light tables (GLSendLightTables), with cellLit on.
' Only what moves is built each frame: the doors, then the sprites.
SUB GLWorldGPU(b, mirror)
    GLShaderStart b
    IF glShaderOn THEN GLSL_uniform_1f glWorldProg, "mirrorCut", -mirror ' (1 in the mirror: nothing from below the floor)
    IF glShaderOn THEN IF editMode AND edGrid AND NOT mirror THEN GLSL_uniform_1f glWorldProg, "gridAmt", edGridAlpha / 255 ELSE GLSL_uniform_1f glWorldProg, "gridAmt", 0
    glCellLitMode = 1
    GLSL_buffer_bind glMeshBuf
    n& = glMeshN
    meshAt~%& = 0 : IF glMeshClient THEN meshAt~%& = _OFFSET(glMeshData(0)) ' (in a buffer, places are offsets into it)
    _glVertexPointer 3, _GL_FLOAT, 0, meshAt~%& ' (positions first...)
    _glTexCoordPointer 2, _GL_FLOAT, 0, meshAt~%& + n& * 12 ' (...then texture spots, normals, tangents)
    _glNormalPointer _GL_FLOAT, 0, meshAt~%& + n& * 20
    GLSL_attrib_array glTanLoc, 3, meshAt~%& + n& * 32
    GLSL_attrib_off glLightLoc : GLSL_attrib_off glDynLoc
    _glDisableClientState _GL_COLOR_ARRAY : _glColor4f 1, 1, 1, 1 ' (the light comes from the tables)
    FOR kind = 0 TO 3 ' Floors (not in the mirror - it's under them), ceilings, walls, raised and sunken floors
        IF (kind = 0 OR kind = 3) AND mirror THEN GOTO NextKind
        IF kind = 0 AND glReflecting THEN _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA : glFloorPass = -1
        FOR slot = 1 TO T_SLOTS
            IF glMeshCount(kind, slot) THEN
                GLBindSlot slot
                _glDrawArrays _GL_TRIANGLES, glMeshFirst(kind, slot), glMeshCount(kind, slot)
            END IF
        NEXT
        IF glFloorPass THEN glFloorPass = 0 : _glDisable _GL_BLEND
        NextKind:
    NEXT
    GLSL_attrib_off glTanLoc
    GLSL_buffer_bind 0
    _glEnableClientState _GL_COLOR_ARRAY

    ' The doors, built now (they slide and lift): a slab each (GLDoorBox) -
    ' or the exit, on its cell's sides like a wall. Only the ones this
    ' frame's rays reached (or came next to: glSeen) - the rest are out of
    ' sight, and a door is a few dozen corners worked out in BASIC.
    FOR k = 1 TO glNumDoors
        IF NOT GLNearSeen(glDoorCX(k), glDoorCY(k), b) THEN
        ELSEIF doorType(glDoorCX(k), glDoorCY(k)) = DOOR_EXIT THEN
            FOR side = 1 TO 4 : GLFace glDoorCX(k), glDoorCY(k), side, b : NEXT
        ELSE
            GLDoorBox glDoorCX(k), glDoorCY(k), b
        END IF
    NEXT
    IF numLifts THEN GLLifts b ' (the lifts, where they are now)
    ' ...and their tracks: dark grooves, so lit by their corners' colour
    ' (darkened) rather than the light tables - a batch of their own
    GLStopDrawing
    litMode = glCellLitMode : glCellLitMode = 0
    FOR k = 1 TO glNumDoors
        IF doorType(glDoorCX(k), glDoorCY(k)) <> DOOR_EXIT THEN IF GLNearSeen(glDoorCX(k), glDoorCY(k), b) THEN GLDoorTrack glDoorCX(k), glDoorCY(k), b
    NEXT
    GLStopDrawing
    glCellLitMode = litMode
    GLStopDrawing
    GLSpritesAndExtras b, mirror
END SUB

' Send this frame's light tables (chapter 17's glLitData...) to the card,
' onto texture units 1, 2 and 3, where the world shader reads them
SUB GLSendLightTables(b)
    IF glLitTex = 0 THEN
        glLitTex = GLSL_data_texture_new~&(GL_TABLE, GL_TABLE) : glInfoTex = GLSL_data_texture_new~&(GL_TABLE, GL_TABLE)
        glDynTex = GLSL_data_texture_new~&(GL_TABLE, GL_TABLE)
    END IF
    GLSL_texture_unit 1 : GLSL_data_texture_update glLitTex, GL_TABLE, GL_TABLE, _OFFSET(glLitData(b * GL_TABLE_SIZE))
    GLSL_texture_unit 2 : GLSL_data_texture_update glInfoTex, GL_TABLE, GL_TABLE, _OFFSET(glInfoData(b * GL_TABLE_SIZE))
    GLSL_texture_unit 3 : GLSL_data_texture_update glDynTex, GL_TABLE, GL_TABLE, _OFFSET(glDynData(b * GL_TABLE_SIZE))
    GLSL_texture_unit 0
END SUB

' Build the world mesh for this level: the same floors, ceilings, walls and
' diagonals GLWorld draws (the very same SUBs, with glMeshBuilding on so
' GLCorner keeps just each corner's shape - GLMeshCorner), but all of them,
' not only what you can see. Then the corners are sorted by kind and texture
' (a counting sort, as in GLDraw) into one block of numbers - every position,
' then every texture spot, normal and tangent - and sent to the card once.
' Doors aren't in it: they move.
SUB GLBuildMesh
    glMeshBuilding = -1 : glMeshN = 0 : glNumDoors = 0
    FOR cy = 0 TO MAP_SIZE - 1 : FOR cx = 0 TO MAP_SIZE - 1
        IF GLOpenCell(cx, cy) THEN
            glFaceTX = 1 : glFaceTY = 0 : glFaceTZ = 0 : glFaceNX = 0 : glFaceNY = 0
            glMeshKind = 0 : IF floorH(cx, cy) <> 0 THEN glMeshKind = 3 ' (a floor up or down: not see-through, for the wet floors)
            glFaceNZ = 1 : IF liftCell(cx, cy) = 0 THEN GLFlat cx, cy, floorH(cx, cy), floorTex(cx, cy), floorTex2(cx, cy), floorSplit(cx, cy) ' (lifts: GLLifts)
            glMeshKind = 1 : glFaceNZ = -1 : GLFlat cx, cy, ceilH(cx, cy), ceilTex(cx, cy), ceilTex2(cx, cy), ceilSplit(cx, cy)
        END IF
        IF worldMap(cx, cy) = 2 THEN
            glNumDoors = glNumDoors + 1 : glDoorCX(glNumDoors) = cx : glDoorCY(glNumDoors) = cy
        ELSEIF worldMap(cx, cy) > 0 THEN
            glMeshKind = 2
            corner = diagCorner(cx, cy)
            IF corner THEN GLDiagonal cx, cy, corner, glBuf
            FOR side = 1 TO 4
                IF corner = 0 THEN
                    GLFace cx, cy, side, glBuf
                ELSEIF SideTouchesCorner(side, corner) THEN
                    GLFace cx, cy, side, glBuf
                END IF
            NEXT
        END IF
    NEXT : NEXT
    ' Heights: the faces between cells whose floors (or ceilings) differ
    IF NOT levelFlat THEN
        glMeshKind = 2
        FOR cy = 0 TO MAP_SIZE - 2 : FOR cx = 0 TO MAP_SIZE - 2
            IF GLOpenCell(cx, cy) THEN
                IF GLOpenCell(cx + 1, cy) AND liftCell(cx, cy) = 0 AND liftCell(cx + 1, cy) = 0 THEN GLStep cx, cy, cx + 1, cy, glBuf
                IF GLOpenCell(cx, cy + 1) AND liftCell(cx, cy) = 0 AND liftCell(cx, cy + 1) = 0 THEN GLStep cx, cy, cx, cy + 1, glBuf
            END IF
        NEXT : NEXT
    END IF
    glMeshBuilding = 0
    n& = glMeshN
    ' Counting sort, by kind * (number of textures) + texture
    FOR kind = 0 TO 3 : FOR slot = 0 TO GL_GLOW_TEX : glMeshCount(kind, slot) = 0 : NEXT : NEXT
    FOR i& = 0 TO n& - 1 : glMeshCount(glMBKind(i&), glMBSlot(i&)) = glMeshCount(glMBKind(i&), glMBSlot(i&)) + 1 : NEXT
    at& = 0
    FOR kind = 0 TO 3 : FOR slot = 0 TO GL_GLOW_TEX
        glMeshFirst(kind, slot) = at& : at& = at& + glMeshCount(kind, slot)
    NEXT : NEXT
    FOR kind = 0 TO 3 : FOR slot = 0 TO GL_GLOW_TEX : glSlotFill(slot) = glMeshFirst(kind, slot) : NEXT
        FOR i& = 0 TO n& - 1
            IF glMBKind(i&) = kind THEN
                d& = glSlotFill(glMBSlot(i&)) : glSlotFill(glMBSlot(i&)) = d& + 1
                glMeshData(d& * 3) = glMBPos(i& * 3) : glMeshData(d& * 3 + 1) = glMBPos(i& * 3 + 1) : glMeshData(d& * 3 + 2) = glMBPos(i& * 3 + 2)
                glMeshData(n& * 3 + d& * 2) = glMBUV(i& * 2) : glMeshData(n& * 3 + d& * 2 + 1) = glMBUV(i& * 2 + 1)
                glMeshData(n& * 5 + d& * 3) = glMBN(i& * 3) : glMeshData(n& * 5 + d& * 3 + 1) = glMBN(i& * 3 + 1) : glMeshData(n& * 5 + d& * 3 + 2) = glMBN(i& * 3 + 2)
                glMeshData(n& * 8 + d& * 3) = glMBT(i& * 3) : glMeshData(n& * 8 + d& * 3 + 1) = glMBT(i& * 3 + 1) : glMeshData(n& * 8 + d& * 3 + 2) = glMBT(i& * 3 + 2)
            END IF
        NEXT
    NEXT
    IF glMeshBuf THEN GLSL_buffer_delete glMeshBuf : glMeshBuf = 0
    ' A new level: into a buffer in the card's memory (11 numbers, 44 bytes,
    ' a corner). In the middle of a level (glMeshClient), the card is still
    ' busy with the frames before, and a new buffer would wait for them -
    ' up to a second, a big stutter. So until the next level the mesh is
    ' drawn straight from glMeshData, sent over afresh each frame instead.
    IF n& > 0 AND NOT glMeshClient THEN glMeshBuf = GLSL_buffer_new~&(_OFFSET(glMeshData(0)), n& * 44)
END SUB

' One corner of the world mesh, while it's built: its shape only (where,
' texture spot, normal, tangent), its texture and its kind
SUB GLMeshCorner(x, y, z, u, v)
    IF glMeshN >= MESH_MAX THEN EXIT SUB
    i& = glMeshN
    glMBPos(i& * 3) = x : glMBPos(i& * 3 + 1) = y : glMBPos(i& * 3 + 2) = z
    glMBUV(i& * 2) = u : glMBUV(i& * 2 + 1) = v
    glMBN(i& * 3) = glFaceNX : glMBN(i& * 3 + 1) = glFaceNY : glMBN(i& * 3 + 2) = glFaceNZ
    glMBT(i& * 3) = glFaceTX : glMBT(i& * 3 + 1) = glFaceTY : glMBT(i& * 3 + 2) = glFaceTZ
    glMBSlot(i&) = glCurSlot : glMBKind(i&) = glMeshKind
    glMeshN = i& + 1
END SUB

' Everything in the world, in the order it has to go: floors (only for
' the real world - the mirror image is under them), ceilings, walls and
' doors, sprites, then the things that add light on top - shadows, glows,
' particles.
SUB GLWorld(b, mirror)
    GLShaderStart b
    IF glShaderOn THEN GLSL_uniform_1f glWorldProg, "mirrorCut", -mirror ' (1 in the mirror: nothing from below the floor)
    IF glShaderOn THEN IF editMode AND edGrid AND NOT mirror THEN GLSL_uniform_1f glWorldProg, "gridAmt", edGridAlpha / 255 ELSE GLSL_uniform_1f glWorldProg, "gridAmt", 0

    ' Floors, then ceilings (one at a time, so neighbours mostly share a
    ' texture - changing texture means stopping and starting again). Over
    ' a mirror image, the floors are blended over it: GLUseTexture sets
    ' how see-through each floor texture is (its shader's "reflectAmt").
    FOR z = 0 TO 1
        IF z = 0 AND mirror THEN GOTO NextFlat ' (no floor in the mirror)
        IF z = 0 AND glReflecting THEN _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA : glFloorPass = -1
        FOR k = 1 TO glNumVis
            cx = glVisX(k) : cy = glVisY(k)
            IF GLOpenCell(cx, cy) THEN
                GLSetLight cx, cy, 1, b
                glFaceTX = 1 : glFaceTY = 0 : glFaceTZ = 0 : glFaceNX = 0 : glFaceNY = 0 ' (u runs along x)
                IF z = 0 THEN
                    glFaceNZ = 1 ' (the floor faces up...)
                    GLFlat cx, cy, floorH(cx, cy), floorTex(cx, cy), floorTex2(cx, cy), floorSplit(cx, cy)
                ELSE
                    glFaceNZ = -1 ' (...the ceiling down)
                    GLFlat cx, cy, ceilH(cx, cy), ceilTex(cx, cy), ceilTex2(cx, cy), ceilSplit(cx, cy)
                END IF
            END IF
        NEXT
        GLStopDrawing
        IF glFloorPass THEN glFloorPass = 0 : _glDisable _GL_BLEND ' (the floors' see-through is done)
        NextFlat:
    NEXT

    ' Walls, doors and diagonals: each side of a wall cell (1 west, 2 east,
    ' 3 north, 4 south). A diagonal cell only has the two sides that touch
    ' its solid corner, plus its slanted face.
    FOR k = 1 TO glNumVis
        cx = glVisX(k) : cy = glVisY(k)
        IF worldMap(cx, cy) > 0 THEN
            corner = diagCorner(cx, cy)
            IF corner THEN GLDiagonal cx, cy, corner, b
            FOR side = 1 TO 4
                IF corner = 0 THEN
                    GLFace cx, cy, side, b
                ELSEIF SideTouchesCorner(side, corner) THEN
                    GLFace cx, cy, side, b
                END IF
            NEXT
        END IF
    NEXT
    GLStopDrawing
    GLSpritesAndExtras b, mirror
END SUB

' Sprites, then shadows, glows and particles - the same for both ways of
' drawing the world (the shader keeps going from the world, if it's on)
' The glass: each pane a see-through rectangle across its cell, mixed
' over what's behind it (_GL_BLEND by its picture's alpha), hidden by
' anything in front (the depth test) but hiding nothing (_glDepthMask off)
SUB GLGlass(b)
    IF numGlass = 0 THEN EXIT SUB
    _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA : _glDepthMask _GL_FALSE
    glCellLitMode = 0
    FOR k = 1 TO numGlass
        cx = glassListX(k) : cy = glassListY(k)
        IF glassHP(cx, cy) > 0 THEN
            IF GLNearSeen(cx, cy, b) THEN
                slot = S_GLASS : IF glassHP(cx, cy) <= GLASS_HP \ 2 THEN slot = S_GLASS + 1
                GLUseTexture T_SLOTS + slot : GLSetLight cx, cy, 1, b
                red = glLitR(cx, cy, b) / 256 : green = glLitG(cx, cy, b) / 256 : blue = glLitB(cx, cy, b) / 256
                IF glassDir(cx, cy) = 1 THEN x0 = cx : y0 = cy + 0.5 : x1 = cx + 1 : y1 = y0 ELSE x0 = cx + 0.5 : y0 = cy : x1 = x0 : y1 = cy + 1
                glFaceNX = y1 - y0 : glFaceNY = x1 - x0 : glFaceNZ = 0 : glFaceTX = x1 - x0 : glFaceTY = y1 - y0 : glFaceTZ = 0
                gz0 = floorH(cx, cy) : gz1 = ceilH(cx, cy) ' (floor to ceiling, however high)
                GLSpriteCorner x0, y0, gz1, 0, 0, red, green, blue : GLSpriteCorner x1, y1, gz1, 1, 0, red, green, blue
                GLSpriteCorner x1, y1, gz0, 1, 1, red, green, blue : GLSpriteCorner x0, y0, gz1, 0, 0, red, green, blue
                GLSpriteCorner x1, y1, gz0, 1, 1, red, green, blue : GLSpriteCorner x0, y0, gz0, 0, 1, red, green, blue
            END IF
        END IF
    NEXT
    GLStopDrawing
    _glDepthMask _GL_TRUE : _glDisable _GL_BLEND
END SUB

SUB GLSpritesAndExtras(b, mirror)
    glCellLitMode = 0 ' (sprites have their own light, worked out in chapter 16)

    ' Sprites: a rectangle across your view, right = (dirY, -dirX), one
    ' colour all over (worked out in chapter 16). With the world shader
    ' they're bump mapped and lit by moving lights like the walls (its
    ' isSprite reads height from brightness, and skips see-through
    ' pixels); without it, OpenGL's "alpha test" skips them.
    dirLen = SQR(glEyeDX * glEyeDX + glEyeDY * glEyeDY)
    rightX = glEyeDY / dirLen : rightY = -glEyeDX / dirLen
    IF glShaderOn = 0 THEN _glEnable _GL_ALPHA_TEST : _glAlphaFunc _GL_GREATER, 128.5 / 255 ' (alpha over 128 of 255)
    glFaceNX = -glEyeDX / dirLen : glFaceNY = -glEyeDY / dirLen : glFaceNZ = 0 ' (facing you...)
    glFaceTX = rightX : glFaceTY = rightY : glFaceTZ = 0 ' (...its picture running left to right)
    FOR i = 1 TO glNumSpr(b)
        slot = glSprSlot(i, b) : GLUseTexture T_SLOTS + slot
        uv = spriteSize(slot) / sprTex ' (a smaller picture uses only part of its 64 x 64)
        sx = glSprX(i, b) : sy = glSprY(i, b) : hw = glSprHalfW(i, b)
        x0 = sx - rightX * hw : y0 = sy - rightY * hw : x1 = sx + rightX * hw : y1 = sy + rightY * hw
        zLow = glSprLift(i, b) : zHigh = zLow + glSprH(i, b)
        red = glSprR(i, b) : green = glSprG(i, b) : blue = glSprB(i, b)
        GLSetLight INT(sx), INT(sy), 1, b
        IF glShaderOn = 0 AND glSet(SET_DYNLIGHT, b) THEN ' (no shader: moving lights at its middle)
            GLDynAt sx, sy, (zLow + zHigh) / 2, dr, dg, db
            red = red + dr / 256 : green = green + dg / 256 : blue = blue + db / 256
        END IF
        GLSpriteCorner x0, y0, zHigh, 0, 0, red, green, blue : GLSpriteCorner x1, y1, zHigh, uv, 0, red, green, blue
        GLSpriteCorner x1, y1, zLow, uv, uv, red, green, blue : GLSpriteCorner x0, y0, zHigh, 0, 0, red, green, blue
        GLSpriteCorner x1, y1, zLow, uv, uv, red, green, blue : GLSpriteCorner x0, y0, zLow, 0, uv, red, green, blue
    NEXT
    GLStopDrawing
    _glDisable _GL_ALPHA_TEST
    GLShaderStop

    IF glSet(SET_SHADOWS, b) AND NOT mirror THEN GLShadows b
    GLDecals b
    IF NOT mirror THEN GLGlass b

    ' Glows: a soft round spot facing you, ADDED to what's behind it
    ' (_glBlendFunc with _GL_ONE) instead of covering it - light adds up, so
    ' it brightens and tints whatever is there, like real glare. They're
    ' hidden by anything in front (the depth test) but don't hide anything
    ' themselves (_glDepthMask off), so they overlap without seams.
    ' Particles - sparks, embers, dust - are tiny glows.
    _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE : _glDepthMask _GL_FALSE
    IF glSet(SET_SHAFTS, b) THEN
        secs = TIMER(0.001)
        FOR i = 1 TO glNumShaft(b)
            GLShaft glShaftX(i, b), glShaftY(i, b), glShaftR(i, b), glShaftG(i, b), glShaftB(i, b), glShaftPh(i, b) + secs, rightX, rightY
        NEXT
    END IF
    IF glSet(SET_GLOW, b) THEN
        FOR i = 1 TO glNumDecal(b) ' Fresh marks glow hot for a moment
            IF glDecHeat(i, b) > 0 THEN
                hot = glDecHeat(i, b) * 0.8
                GLGlowSpot glDecX(i, b) + glDecNX(i, b) * 0.02, glDecY(i, b) + glDecNY(i, b) * 0.02, glDecZ(i, b) + glDecNZ(i, b) * 0.02, glDecSize(i, b) * 0.9, hot, hot * 0.45, hot * 0.15, rightX, rightY
            END IF
        NEXT
        FOR i = 1 TO glNumGlow(b)
            ' (pulled a little towards you, so the thing glowing - a bolt, a
            ' lamp, standing in the same spot - doesn't hide its own glow)
            GLGlowSpot glGlowX(i, b) - glEyeDX * 0.3, glGlowY(i, b) - glEyeDY * 0.3, glGlowZ(i, b), glGlowSize(i, b), glGlowR(i, b), glGlowG(i, b), glGlowB(i, b), rightX, rightY
        NEXT
    END IF
    IF glSet(SET_PARTICLES, b) THEN
        FOR i = 1 TO glNumPart(b)
            GLGlowSpot glPartX(i, b), glPartY(i, b), glPartZ(i, b), glPartSize(i, b), glPartR(i, b), glPartG(i, b), glPartB(i, b), rightX, rightY
        NEXT
    END IF
    GLStopDrawing
    _glDepthMask _GL_TRUE : _glDisable _GL_BLEND
END SUB

' One glow spot (or particle): a square of the soft round GL_GLOW_TEX
' facing you, size from its middle to its edge, in colour (r, g, b)
SUB GLGlowSpot(gx, gy, gz, sz, r, g, bl, rightX, rightY)
    GLUseTexture GL_GLOW_TEX
    x0 = gx - rightX * sz : y0 = gy - rightY * sz : x1 = gx + rightX * sz : y1 = gy + rightY * sz
    GLPutCorner x0, y0, gz + sz, 0, 0, r, g, bl : GLPutCorner x1, y1, gz + sz, 1, 0, r, g, bl
    GLPutCorner x1, y1, gz - sz, 1, 1, r, g, bl : GLPutCorner x0, y0, gz + sz, 0, 0, r, g, bl
    GLPutCorner x1, y1, gz - sz, 1, 1, r, g, bl : GLPutCorner x0, y0, gz - sz, 0, 1, r, g, bl
END SUB

' A LIGHT SHAFT under the light at (sx, sy), colour (r, g, bl): a beam
' from the ceiling to the floor, widening as it goes (SHAFT_TOP to
' SHAFT_FOOT) and fading towards the floor, ADDED like a glow. It's flat,
' turned to face you, like a sprite - from the side, a cone and a flat
' shape look the same when they're see-through and soft-edged. Its sides
' fade out: the glow spot's middle row is the soft edge, so u runs across
' the beam (0 at one edge, 0.5 the middle, 1 the other) and v stays 0.5.
' It's built in four pieces down, each split in two at the middle, so the
' widening doesn't bend the soft edges. It shimmers slowly (t, a time with
' the light's own phase added), and fades when you're near enough to stand
' in it (or it would fill your view) or far away.
SUB GLShaft(sx, sy, r, g, bl, t, rightX, rightY)
    d = SQR((sx - glEyeX) ^ 2 + (sy - glEyeY) ^ 2)
    f = 1
    IF d < 1.3 THEN f = (d - 0.35) / 0.95 : IF f <= 0 THEN EXIT SUB
    IF d > 10 THEN f = f * (16 - d) / 6 : IF f <= 0 THEN EXIT SUB
    f = f * SHAFT_AMT * (0.85 + 0.15 * SIN(t * 0.9))
    GLUseTexture GL_GLOW_TEX
    sfz = FloorAt(sx, sy) : scz = CeilAt(sx, sy) : sh = (scz - sfz) / 4 ' (heights: floor to ceiling)
    FOR piece = 0 TO 3
        zTop = scz - 0.005 - piece * sh : zLow = zTop - sh
        wTop = SHAFT_TOP + (SHAFT_FOOT - SHAFT_TOP) * (1 - zTop) : wLow = SHAFT_TOP + (SHAFT_FOOT - SHAFT_TOP) * (1 - zLow)
        kTop = f * (0.45 + 0.55 * zTop) : kLow = f * (0.45 + 0.55 * zLow) ' (brighter at the top)
        FOR half = -1 TO 1 STEP 2
            eTopX = sx + rightX * wTop * half : eTopY = sy + rightY * wTop * half
            eLowX = sx + rightX * wLow * half : eLowY = sy + rightY * wLow * half
            u = 0.5 + 0.5 * half
            GLPutCorner sx, sy, zTop, 0.5, 0.5, r * kTop, g * kTop, bl * kTop : GLPutCorner eTopX, eTopY, zTop, u, 0.5, r * kTop, g * kTop, bl * kTop
            GLPutCorner eLowX, eLowY, zLow, u, 0.5, r * kLow, g * kLow, bl * kLow : GLPutCorner sx, sy, zTop, 0.5, 0.5, r * kTop, g * kTop, bl * kTop
            GLPutCorner eLowX, eLowY, zLow, u, 0.5, r * kLow, g * kLow, bl * kLow : GLPutCorner sx, sy, zLow, 0.5, 0.5, r * kLow, g * kLow, bl * kLow
        NEXT
    NEXT
    ' ...and the light itself, a soft spot just under the ceiling
    GLGlowSpot sx - glEyeDX * 0.1, sy - glEyeDY * 0.1, scz - 0.04, 0.25, r * f * 1.3, g * f * 1.3, bl * f * 1.3, rightX, rightY
END SUB

' Does cell (cx, cy) have a floor and ceiling? Open floor, a door, or a
' diagonal wall's cell (the open half)
FUNCTION GLOpenCell(cx, cy)
    IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT FUNCTION
    v = worldMap(cx, cy)
    GLOpenCell = (v <= 0 OR v = 2 OR diagCorner(cx, cy) <> 0)
END FUNCTION

' SHADOWS. Each sprite throws its shadow on the floor, away from the light
' falling on its cell (that cell's light middle, chapter 14's litSum...):
' its picture is laid flat on the floor, stretched away from the light -
' each corner of it is moved along the line from the light, through the
' corner, down to the floor ("projected"). With the light lz up, a corner
' at height z lands lz / (lz - z) times as far from the light as it is.
' (lz is twice GL_LIGHT_Z: a lamp's light comes from all over it, not one
' point, and from that low a point a tall monster's shadow would stretch
' five times its height.) Drawn black and half see-through, with the
' alpha test keeping only the shape: it's the monster's own silhouette.
' Light from everywhere (ambient) casts no shadow, so it's as dark as the
' cell's light is directional (glLitDir).
SUB GLShadows(b)
    _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA : _glDepthMask _GL_FALSE
    _glEnable _GL_ALPHA_TEST : _glAlphaFunc _GL_GREATER, 0.05
    FOR i = 1 TO glNumSpr(b)
        slot = glSprSlot(i, b)
        IF slot = S_BOLT OR slot = S_BLAST OR (slot > S_BOOM AND slot <= S_BOOM + BOOM_FRAMES) OR slot >= S_PLATE THEN GOTO NextShadow ' (they glow, or lie flat)
        sx = glSprX(i, b) : sy = glSprY(i, b) : cx = INT(sx) : cy = INT(sy)
        strength = glLitDir(cx, cy, b) * 1.2 : IF strength > 0.65 THEN strength = 0.65
        lx = glLitCX(cx, cy, b) : ly = glLitCY(cx, cy, b)
        dx = sx - lx : dy = sy - ly : d = SQR(dx * dx + dy * dy)
        IF strength < 0.08 OR d < 0.15 THEN GOTO NextShadow
        sideX = -dy / d : sideY = dx / d ' (across the shadow: square to the light)
        hw = glSprHalfW(i, b) : zLow = glSprLift(i, b) : zHigh = zLow + glSprH(i, b)
        lz = GL_LIGHT_Z * 2
        IF zHigh > lz * 0.7 THEN zHigh = lz * 0.7 ' (or it would stretch forever)
        uv = spriteSize(slot) / sprTex
        GLUseTexture T_SLOTS + slot
        tLow = lz / (lz - zLow) : tHigh = lz / (lz - zHigh)
        ax = sx - sideX * hw : ay = sy - sideY * hw : bx = sx + sideX * hw : by = sy + sideY * hw
        ' (each corner: from the light, out through the corner, to the floor)
        x0 = lx + (ax - lx) * tLow : y0 = ly + (ay - ly) * tLow : x1 = lx + (bx - lx) * tLow : y1 = ly + (by - ly) * tLow
        x2 = lx + (bx - lx) * tHigh : y2 = ly + (by - ly) * tHigh : x3 = lx + (ax - lx) * tHigh : y3 = ly + (ay - ly) * tHigh
        GLPutCornerA x3, y3, 0.003, 0, 0, strength : GLPutCornerA x2, y2, 0.003, uv, 0, strength : GLPutCornerA x1, y1, 0.003, uv, uv, strength
        GLPutCornerA x3, y3, 0.003, 0, 0, strength : GLPutCornerA x1, y1, 0.003, uv, uv, strength : GLPutCornerA x0, y0, 0.003, 0, uv, strength
        NextShadow:
    NEXT
    GLStopDrawing
    _glDisable _GL_ALPHA_TEST : _glDepthMask _GL_TRUE : _glDisable _GL_BLEND
END SUB

' A shadow corner: black, with see-through-ness a (the colours array has
' room for 3 numbers a corner, so alpha goes in by drawing these with
' their own colour pointer - glShadowA() - see GLDraw)
SUB GLPutCornerA(x, y, z, u, v, a)
    GLPutCorner x, y, z, u, v, 0, 0, 0
    glShadowA(glNumVerts - 1) = a
END SUB

' THE HUD (no post-processing): the captured screen (GLSL_filter_capture,
' chapter 18) laid over the whole view. Its colours are "premultiplied" -
' QB64PE's blending onto a see-through screen leaves each colour already
' multiplied by its alpha - so it goes on with _GL_ONE for the picture and
' (1 - alpha) for what's under it, which is exactly "this, over that".
SUB GLDrawHUD
    hudTex~& = GLSL_filter_texture~&(0)
    IF hudTex~& = 0 THEN EXIT SUB
    _glEnable _GL_TEXTURE_2D : _glEnable _GL_BLEND : _glBlendFunc _GL_ONE, _GL_ONE_MINUS_SRC_ALPHA
    _glColor4f 1, 1, 1, 1
    GLSL_fullscreen -1
    _glDisable _GL_BLEND
END SUB

' RESOLUTION (SETTINGS > VIDEO): the size OpenGL draws the 3D view at for
' choice res. NATIVE is the window's own pixels. The rest are heights, as
' screens are sold: 2160 lines (4K), 1440 (2K), 1080, 720 and 480 - the
' width follows the view's shape, so on a widescreen monitor 1080P is
' 1920 x 1080 (or 1440 x 1080, letterboxed to our 4:3 with _SQUAREPIXELS).
' RETRO is the software renderer's 400 x 300. ResSize gets w and h as the
' view's size and changes them (NATIVE leaves them be).
SUB ResSize(res, w, h)
    IF res <= RES_NATIVE OR res > RES_RETRO OR h < 1 THEN EXIT SUB
    IF res = RES_RETRO THEN w = RENDER_W : h = RENDER_H : EXIT SUB
    tall = VAL(MID$("216014401080720 480 ", (res - 2) * 4 + 1, 4))
    w = INT(tall * w / h) : h = tall
END SUB

FUNCTION ResName$(res)
    ResName$ = RTRIM$(MID$("NATIVE   2160P 4K 1440P 2K 1080P    720P     480P     RETRO    ", (res - 1) * 9 + 1, 9))
END FUNCTION

' THE GUN, at the window's own size - its picture can have more detail than
' our 800 x 600 screen does. It goes under the HUD (the muzzle flash is
' drawn there, over it). Chapter 17 placed it on our screen (glGun...), so
' the sums for where that is on the window are OpenGL's: _glOrtho makes
' the view's corners (0, 0) top left and (800, 600) bottom right. With
' post-processing, the post shader lays it on instead (GLPostProcess).
SUB GLDrawGun(b)
    g = glGun(b) : IF g = 0 THEN EXIT SUB
    IF glGunTex(g) = 0 THEN EXIT SUB
    GLSL_use 0
    _glMatrixMode _GL_PROJECTION : _glLoadIdentity : _glOrtho 0, 800, 600, 0, -1, 1
    _glMatrixMode _GL_MODELVIEW : _glLoadIdentity
    _glEnable _GL_TEXTURE_2D : _glEnable _GL_BLEND : _glBlendFunc _GL_ONE, _GL_ONE_MINUS_SRC_ALPHA ' (premultiplied, as GLDrawHUD's)
    _glBindTexture _GL_TEXTURE_2D, glGunTex(g) : _glColor4f glGunR(b), glGunG(b), glGunB(b), 1 ' (in its light)
    _glBegin _GL_QUADS
    _glTexCoord2f 0, 0 : _glVertex2f glGunX0(b), glGunY0(b)
    _glTexCoord2f 1, 0 : _glVertex2f glGunX1(b), glGunY0(b)
    _glTexCoord2f 1, 1 : _glVertex2f glGunX1(b), glGunY1(b)
    _glTexCoord2f 0, 1 : _glVertex2f glGunX0(b), glGunY1(b)
    _glEnd
    _glDisable _GL_BLEND
END SUB

' Send the guns' pictures (LoadGun's premultiplied copies) to the card,
' once. Each gets "mipmaps": copies at half size, quarter size and so on,
' made by the card - drawn smaller than it is, a detailed picture is read
' from the nearest-sized copy and stays smooth instead of sparkling. Drawn
' bigger, a small picture (pixel art) keeps its square pixels; a big one
' (128 pixels tall or more) is smoothed.
SUB GLSendGuns
    FOR g = 1 TO NUM_GUNS
        IF gunGLW(g) > 0 THEN
            IF glGunTex(g) THEN _glDeleteTextures 1, _OFFSET(glGunTex(g))
            _glGenTextures 1, _OFFSET(glGunTex(g))
            _glBindTexture _GL_TEXTURE_2D, glGunTex(g)
            _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_LINEAR_MIPMAP_LINEAR
            IF gunGLH(g) >= 128 THEN
                _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_LINEAR
            ELSE
                _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
            END IF
            _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE
            _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE
            _glTexParameteri _GL_TEXTURE_2D, GL_GENERATE_MIPMAP, _GL_TRUE
            _glTexImage2D _GL_TEXTURE_2D, 0, _GL_RGBA, gunGLW(g), gunGLH(g), 0, _GL_BGRA_EXT, _GL_UNSIGNED_BYTE, gunGLMem(g).OFFSET
        END IF
    NEXT
    _glBindTexture _GL_TEXTURE_2D, 0
END SUB

' Make (or resize) the render targets for post-processing: the scene, w x
' h with a depth buffer, read with square pixels for RETRO resolution; two
' quarter-size ones the bloom is blurred between; and two 400 x 300 ones
' for the phosphor glow (always that size: half our screen's, so the glow
' spreads as far, in our screen's pixels, at any resolution). FALSE if the driver
' can't (then the view goes straight to the window, without post effects).
FUNCTION GLMakeTargets(w, h, retro)
    IF glTargScene = 0 THEN
        IF NOT GLSL_targets_supported% THEN glPostProg = 0 : EXIT FUNCTION
        glTargScene = GLSL_target_new&(w, h, -1) : glTargA = GLSL_target_new&(w \ 4 + 1, h \ 4 + 1, 0) : glTargB = GLSL_target_new&(w \ 4 + 1, h \ 4 + 1, 0)
        glTargC = GLSL_target_new&(400, 300, 0) : glTargD = GLSL_target_new&(400, 300, 0)
        IF glTargScene = 0 OR glTargA = 0 OR glTargB = 0 OR glTargC = 0 OR glTargD = 0 THEN glShaderError$ = GLSL_error$ : glPostProg = 0 : EXIT FUNCTION
        glTargRetro = -2
    END IF
    GLSL_target_resize glTargScene, w, h
    GLSL_target_resize glTargA, w \ 4 + 1, h \ 4 + 1 : GLSL_target_resize glTargB, w \ 4 + 1, h \ 4 + 1
    IF retro <> glTargRetro THEN GLSL_target_smooth glTargScene, NOT retro : glTargRetro = retro
    GLMakeTargets = -1
END FUNCTION

' POST-PROCESSING, from the scene's render target onto the window:
'   BLOOM       the bright parts (the "bright pass" keeps only them) are
'               shrunk to a quarter size and blurred - across, then down -
'               and added back on top: neon light bleeding into the dark
'   HIT FX      heat shimmer round explosions, a red pulse at the edges
'               when you're hurt, a zoom blur when the railgun fires
'   SCREEN FX   scanlines, or a whole curved CRT screen
'   SCANLINES   how dark the scanlines are, how far apart, how thick
'   PHOSPHOR GLOW  light bleeding round everything bright, as it did
'               on a tube's glass - and into the dark between the lines
' and the HUD goes in between, so a CRT curves it too.
SUB GLPostProcess(b, vx, vy, vw, vh, sw, sh, hx, hy, hw, hh)
    aw = GLSL_target_width&(glTargA) : ah = GLSL_target_height&(glTargA)
    bloomOn = (glSet(SET_BLOOM, b) <> 0) AND glBrightProg <> 0 AND glBlurProg <> 0 ' (TRUE is -1; a setting's "on" is 1)
    _glEnable _GL_TEXTURE_2D : _glDisable _GL_BLEND : _glColor4f 1, 1, 1, 1
    IF bloomOn THEN
        GLSL_target_use glTargA : _glViewport 0, 0, aw, ah ' Bright pass, shrunk
        _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargScene)
        GLSL_use glBrightProg : GLSL_uniform_1i glBrightProg, "scene", 0 : GLSL_fullscreen 0
        GLSL_target_use glTargB ' Blur across...
        _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargA)
        GLSL_use glBlurProg : GLSL_uniform_1i glBlurProg, "src", 0 : GLSL_uniform_2f glBlurProg, "stepUV", 1 / aw, 0 : GLSL_fullscreen 0
        GLSL_target_use glTargA ' ...then down
        _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargB)
        GLSL_uniform_2f glBlurProg, "stepUV", 0, 1 / ah : GLSL_fullscreen 0
        GLSL_target_use 0
    END IF

    ' The final picture: scene (unit 0), bloom (unit 1), HUD (unit 2), gun
    ' (unit 3: where it goes is gunRect, its corners as parts of the screen),
    ' phosphor glow (unit 4)
    g = glGun(b) : IF g > 0 THEN IF glGunTex(g) = 0 THEN g = 0
    IF g > 0 THEN GLSL_texture_unit 3 : _glBindTexture _GL_TEXTURE_2D, glGunTex(g)
    GLSL_texture_unit 2 : hudTex~& = GLSL_filter_texture~&(0)
    GLSL_texture_unit 1 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargA)
    GLSL_texture_unit 0 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargScene)
    p~& = glPostProg
    GLSL_use p~&
    glowOn = glSet(SET_PHOSPHOR, b) > 0 AND glBlurProg <> 0
    GLSL_uniform_1i p~&, "scene", 0 : GLSL_uniform_1i p~&, "bloom", 1 : GLSL_uniform_1i p~&, "hud", 2
    GLSL_uniform_1f p~&, "hudOn", (hudTex~& <> 0) * -1
    GLSL_uniform_1i p~&, "gun", 3 : GLSL_uniform_1f p~&, "gunOn", (g > 0) * -1
    IF g > 0 THEN GLSL_uniform_4f p~&, "gunRect", glGunX0(b) / 800, glGunY0(b) / 600, glGunX1(b) / 800, glGunY1(b) / 600
    GLSL_uniform_3f p~&, "gunLight", glGunR(b), glGunG(b), glGunB(b)
    ' Where our screen (HUD, gun) is in the picture: all of it - or for FULL
    ' WIDE, the 4:3 middle of the wider view (and how much to darken beside it)
    GLSL_uniform_4f p~&, "hudRect", (hx - vx) / vw, (hy - vy) / vh, (hx + hw - vx) / vw, (hy + hh - vy) / vh
    GLSL_uniform_1f p~&, "sideDim", glSideDim(b) * (glAspectK > 1.01) * -1
    GLSL_uniform_1f p~&, "bloomAmt", bloomOn * -0.9
    GLSL_uniform_1f p~&, "fxMode", glSet(SET_SCREENFX, b) - 1
    ' Scanlines: how dark, how many of the window's pixels apart (a whole
    ' number, or they'd shimmer in bands) and how thick (part of that gap)
    GLSL_uniform_1f p~&, "scanDark", glSet(SET_SCANLINES, b) / 100 : GLSL_uniform_1f p~&, "linePx", glSet(SET_SCANGAP, b)
    GLSL_uniform_1f p~&, "lineThick", glSet(SET_SCANTHICK, b) / 100
    GLSL_uniform_1f p~&, "glow", glSet(SET_PHOSPHOR, b) / 100 * (glowOn <> 0) * -1
    GLSL_uniform_1i p~&, "glowTex", 4
    ' PHOSPHOR GLOW: on a picture tube, light spreads in the glass round
    ' anything bright, and a bright line is drawn wider, filling the dark gap
    ' to the next. So: the picture (view, gun and HUD, no screen effects -
    ' passMode 1) drawn small, into glTargC, then blurred across and down
    ' (the bloom's blur, twice: wider and smoother), to be read back,
    ' smoothly stretched, by the final picture
    IF glowOn THEN
        GLSL_target_use glTargC : _glViewport 0, 0, 400, 300
        GLSL_uniform_1f p~&, "passMode", 1 : GLSL_fullscreen 0
        GLSL_use glBlurProg : GLSL_uniform_1i glBlurProg, "src", 0
        GLSL_texture_unit 0
        FOR k = 1 TO 2
            GLSL_target_use glTargD : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargC)
            GLSL_uniform_2f glBlurProg, "stepUV", k / 400, 0 : GLSL_fullscreen 0
            GLSL_target_use glTargC : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargD)
            GLSL_uniform_2f glBlurProg, "stepUV", 0, k / 300 : GLSL_fullscreen 0
        NEXT
        GLSL_target_use 0
        GLSL_texture_unit 4 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargC)
        GLSL_texture_unit 0 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargScene)
        GLSL_use p~&
    ELSE ' (glow off: its sampler still wants a picture - macOS's OpenGL complains of an empty one)
        GLSL_texture_unit 4 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargScene)
        GLSL_texture_unit 0
    END IF
    GLSL_uniform_1f p~&, "passMode", 0
    _glViewport vx, vy, vw, vh
    GLSL_uniform_2f p~&, "res", vw, vh
    GLSL_uniform_1f p~&, "secs", TIMER(0.001) - INT(TIMER(0.001) / 1000) * 1000
    hit = (glSet(SET_HITFX, b) <> 0) * -1 ' (1 with HIT FX on, else 0)
    GLSL_uniform_1f p~&, "hurt", glHurt(b) * hit : GLSL_uniform_1f p~&, "rail", glRail(b) * hit
    FOR i = 0 TO GL_HEAT - 1 ' Explosions on screen, for the heat shimmer
        hx = 0 : hy = 0 : hr = 0
        IF i < glNumHeat(b) AND hit THEN GLProject glHeatX(i + 1, b), glHeatY(i + 1, b), 0.45, b, hx, hy, hr
        GLSL_uniform_4f p~&, "heat[" + LTRIM$(STR$(i)) + "]", hx, hy, hr, glHeatAmt(i + 1, b) * (hr > 0) * -1
    NEXT
    GLSL_fullscreen 0
    GLSL_use 0
    GLSL_texture_unit 4 : _glBindTexture _GL_TEXTURE_2D, 0
    GLSL_texture_unit 3 : _glBindTexture _GL_TEXTURE_2D, 0
    GLSL_texture_unit 2 : _glBindTexture _GL_TEXTURE_2D, 0
    GLSL_texture_unit 1 : _glBindTexture _GL_TEXTURE_2D, 0
    GLSL_texture_unit 0
END SUB

' Where map point (x, y) at height z is on the screen, 0..1 across and up
' (sx, sy), and how big a cell looks there (sr, 0 if it's behind you) -
' the camera's sums (GLCamera) and the perspective's, done by hand
SUB GLProject(x, y, z, b, sx, sy, sr)
    sx = 0 : sy = 0 : sr = 0
    rx = (x - glEyeX) * glEyeDY - (y - glEyeY) * glEyeDX
    up = z - 0.5 : ahead = (x - glEyeX) * glEyeDX + (y - glEyeY) * glEyeDY
    c = COS(glPitch(b)) : s = SIN(glPitch(b))
    up2 = c * up - s * ahead : depth = s * up + c * ahead
    IF depth < 0.3 THEN EXIT SUB
    sx = 0.5 + 0.5 * rx / (depth * glPlaneLen(b) * glAspectK) : sy = 0.5 + up2 * glZoom(b) / depth
    sr = 0.35 / depth
END SUB

' The moving lights' light at map point (x, y, z), without the world
' shader: each light's colour, fading to nothing at its radius, if it
' reaches that cell (glCellDyn, from GLSetLight). In light units (256 =
' full), like litR.
SUB GLDynAt(x, y, z, r, g, bl)
    r = 0 : g = 0 : bl = 0
    FOR k = 1 TO glNumDyn(glBuf)
        IF glCellDyn(k) THEN
            d = SQR((x - glDynX(k, glBuf)) ^ 2 + (y - glDynY(k, glBuf)) ^ 2 + (z - glDynZ(k, glBuf)) ^ 2)
            IF d < glDynRad(k, glBuf) THEN
                w = (1 - d / glDynRad(k, glBuf)) ^ 2
                r = r + glDynR(k, glBuf) * w : g = g + glDynG(k, glBuf) * w : bl = bl + glDynB(k, glBuf) * w
            END IF
        END IF
    NEXT
END SUB

' Send every texture and sprite picture to the graphics card. Each gets a
' name (a number) from _glGenTextures the first time; the textures are
' names 1-20 of glTexName(), the sprites after them, then the glow spot.
' Each texture slot's effects come from its file name (texName$):
'   shine     how shiny (the shader's highlights): metal doors most
'   reflect   how much of the mirror image a floor shows (WET FLOORS)
'   neon      how much its bright, colourful pixels light themselves
'   anim      0 still, 1 flickering screens, 2 chasing lights, 3 pulsing
SUB GLSendTextures
    IF glTexName(1) = 0 THEN _glGenTextures GL_GLOW_TEX, _OFFSET(glTexName(1))
    ' Walls, floors and ceilings are solid, so their alpha is free: it gets
    ' each pixel's brightness, which the world shader reads as its HEIGHT -
    ' light parts stand out, dark parts (mortar, cracks, grooves) sink in.
    ' That's the "bump map", made from the picture itself.
    FOR slot = 1 TO T_SLOTS
        FOR y = 0 TO texSize - 1 : FOR x = 0 TO texSize - 1
            col~& = texture(x, y, slot)
            height = (((col~& \ 65536) AND 255) * 0.3 + ((col~& \ 256) AND 255) * 0.59 + (col~& AND 255) * 0.11)
            glUpload(y * texSize + x) = (col~& AND &HFFFFFF) OR _SHL(INT(height) AND 255, 24)
        NEXT : NEXT
        GLSendPicture glTexName(slot), texSize, _OFFSET(glUpload(0)), -1, texHD(slot) AND NOT cyberOn
        n$ = texName$(slot)
        glTexShine(slot) = 0.2 : glTexReflect(slot) = 0 : glTexNeon(slot) = 1 : glTexAnim(slot) = 0
        IF slot >= T_DOOR AND slot <= T_SPLIT THEN glTexShine(slot) = 0.6
        IF INSTR(n$, "plates") OR INSTR(n$, "grate") OR INSTR(n$, "pipes") OR INSTR(n$, "coils") THEN glTexShine(slot) = 0.5
        IF INSTR(n$, "ice") OR INSTR(n$, "frost") OR INSTR(n$, "cryo") THEN glTexShine(slot) = 0.7
        IF (slot > T_FLOOR AND slot <= T_FLOOR + 4) OR (slot > T_CUSTOM AND LEFT$(n$, 5) = "floor") THEN ' Floors: how wet (a single face's floor picture too)
            glTexReflect(slot) = 0.16 : glTexNeon(slot) = 0.5
            IF INSTR(n$, "ice") THEN glTexReflect(slot) = 0.45
            IF INSTR(n$, "murky") THEN glTexReflect(slot) = 0.4
            IF INSTR(n$, "molten") OR INSTR(n$, "lava") THEN glTexNeon(slot) = 1 : glTexAnim(slot) = 3 : glTexReflect(slot) = 0.05 ' (it glows, and pulses)
            IF INSTR(n$, "glow") OR INSTR(n$, "frost") THEN glTexReflect(slot) = 0.32
            IF INSTR(n$, "white") OR INSTR(n$, "lab") OR INSTR(n$, "plates") THEN glTexReflect(slot) = 0.28
            IF INSTR(n$, "concrete") OR INSTR(n$, "cobbles") OR INSTR(n$, "scorched") THEN glTexReflect(slot) = 0.08
            IF INSTR(n$, "glow") THEN glTexNeon(slot) = 1
        END IF
        IF (slot > T_CEIL AND slot <= T_CUSTOM) OR (slot > T_CUSTOM AND LEFT$(n$, 7) = "ceiling") THEN glTexShine(slot) = 0.1
        IF slot = T_LIFT OR slot = T_LIFTSIDE THEN glTexShine(slot) = 0.5 : glTexNeon(slot) = 0.35 ' (a lift: metal, its stripes faintly lit)
        IF slot = T_TRAP THEN glTexShine(slot) = 0.4 : glTexNeon(slot) = 0.9 : glTexAnim(slot) = 1 ' (live wires: flickering)
        IF slot = T_FIRE THEN glTexShine(slot) = 0.2 : glTexNeon(slot) = 1 : glTexAnim(slot) = 3 ' (embers: pulsing)
        IF INSTR(n$, "white") OR INSTR(n$, "ice") OR INSTR(n$, "frost") THEN glTexNeon(slot) = 0 ' (white isn't neon)
        IF INSTR(n$, "brick") OR INSTR(n$, "rust") OR INSTR(n$, "moss") OR INSTR(n$, "biolab") OR INSTR(n$, "slime") THEN glTexNeon(slot) = 0.35 ' (nor rust and slime, much)
        IF INSTR(n$, "servers") OR INSTR(n$, "terminals") OR INSTR(n$, "control") THEN glTexAnim(slot) = 1
        IF INSTR(n$, "hazard") OR INSTR(n$, "stripes") OR INSTR(n$, "warning") THEN glTexAnim(slot) = 2
        IF INSTR(n$, "glow") OR INSTR(n$, "lights") OR INSTR(n$, "reactor") OR INSTR(n$, "cryo") OR INSTR(n$, "coils") THEN glTexAnim(slot) = 3
        IF slot = T_EXIT THEN glTexAnim(slot) = 3
    NEXT
    FOR slot = 1 TO SPR_SLOTS
        sz = spriteSize(slot) ' (a smaller picture's unused part cleared: smoothed, it would bleed in)
        IF artNow = 2 AND sz > 0 AND sz < sprTex THEN
            FOR y = 0 TO sprTex - 1 : FOR x = 0 TO sprTex - 1
                IF x >= sz OR y >= sz THEN spriteTex(x, y, slot) = 0
            NEXT : NEXT
        END IF
        GLSendPicture glTexName(T_SLOTS + slot), sprTex, _OFFSET(spriteTex(0, 0, slot)), 0, sz >= 128 ' (a MODERN painting: 128 pixels or more)
        glTexShine(T_SLOTS + slot) = 0.3 : glTexReflect(T_SLOTS + slot) = 0 : glTexNeon(T_SLOTS + slot) = 0.6 : glTexAnim(T_SLOTS + slot) = 0
        IF slot > S_CORPSE AND slot <= S_ANIM THEN glTexNeon(T_SLOTS + slot) = 0 ' (bodies, scorches and wreckage don't light themselves)
        IF slot > S_BOOM AND slot <= S_BOOM + BOOM_FRAMES THEN glTexNeon(T_SLOTS + slot) = 1 ' (explosions do)
        IF slot = S_LASER THEN glTexNeon(T_SLOTS + slot) = 1
    NEXT
    ' The glows' spot: white, see-through at its edge, solid in the middle
    FOR y = 0 TO 63 : FOR x = 0 TO 63
        d = SQR((x - 31.5) ^ 2 + (y - 31.5) ^ 2) / 32 : IF d > 1 THEN d = 1
        glUpload(y * 64 + x) = _RGBA32(255, 255, 255, 255 * (1 - d) ^ 2)
    NEXT : NEXT
    GLSendPicture glTexName(GL_GLOW_TEX), 64, _OFFSET(glUpload(0)), 0, 0
    glTexDone = glTexVersion
END SUB

' One square picture, size pixels across, from memory at pixelsAt. Pixel
' art: nearest pixel (no smoothing); a MODERN painting (smooth): smoothed,
' with mipmaps. And "clamp" (wrap off): a texture coordinate of 1 is the
' last pixel, not the first one again.
SUB GLSendPicture(texName AS _UNSIGNED LONG, size, pixelsAt AS _OFFSET, wrap, smooth)
    _glBindTexture _GL_TEXTURE_2D, texName
    IF smooth THEN ' A MODERN painting: smooth, with smaller copies for far away (mipmaps), not pixels
        _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_LINEAR_MIPMAP_LINEAR
        _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_LINEAR
        _glTexParameteri _GL_TEXTURE_2D, GL_GENERATE_MIPMAP, _GL_TRUE
    ELSE
        _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
        _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
        _glTexParameteri _GL_TEXTURE_2D, GL_GENERATE_MIPMAP, _GL_FALSE
    END IF
    ' (walls, floors and ceilings repeat - a wall taller than one cell
    ' shows its picture again above; sprites stop at their edges)
    IF wrap THEN wm& = _GL_REPEAT ELSE wm& = _GL_CLAMP
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_S, wm&
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_T, wm&
    _glTexImage2D _GL_TEXTURE_2D, 0, _GL_RGBA, size, size, 0, _GL_BGRA_EXT, _GL_UNSIGNED_BYTE, pixelsAt
END SUB

' The next corners use texture slot (-1: none in particular). Nothing is
' switched yet: GLDraw sorts each pass's corners by texture first.
SUB GLUseTexture(slot)
    IF slot >= 0 THEN glCurSlot = slot
END SUB

' Switch to texture slot - and tell the world shader about it: how bumpy
' and shiny it is (walls, floors, ceilings and doors only - not sprites),
' how see-through (a wet floor), neon and animated, its pixel size, and
' whether it's a sprite
SUB GLBindSlot(slot)
    _glBindTexture _GL_TEXTURE_2D, glTexName(slot)
    IF glShaderOn THEN
        p~& = glWorldProg
        GLSL_uniform_1f p~&, "reflectAmt", glTexReflect(slot) * glFloorPass * -1
        GLSL_uniform_1f p~&, "neon", glTexNeon(slot) * glNeonOn
        GLSL_uniform_1f p~&, "anim", glTexAnim(slot)
        GLSL_uniform_1f p~&, "cellLit", glCellLitMode
        IF slot > T_SLOTS THEN ' A sprite: flat, not shiny
            GLSL_uniform_1f p~&, "isSprite", 1 : GLSL_uniform_1f p~&, "texel", 1 / sprTex
            GLSL_uniform_1f p~&, "bump", 0 : GLSL_uniform_1f p~&, "shine", 0
        ELSE
            GLSL_uniform_1f p~&, "isSprite", 0 : GLSL_uniform_1f p~&, "texel", 1 / texSize
            GLSL_uniform_1f p~&, "bump", GL_BUMP * glBumpOn : GLSL_uniform_1f p~&, "shine", glTexShine(slot)
        END IF
    END IF
END SUB

SUB GLStopDrawing
    GLDraw
END SUB

' The world shader on, with this frame's settings: where you are and face,
' bump strength, the time (for animations), and the moving lights - each
' one's place, colour (in 0..1, so light units / 256) and radius. Off
' (radius 0.001, black) if MOVING LIGHTS is off or there are fewer.
SUB GLShaderStart(b)
    glShaderOn = 0
    IF glWorldProg = 0 THEN EXIT SUB
    p~& = glWorldProg
    GLSL_use p~& : glShaderOn = -1
    GLSL_uniform_3f p~&, "eye", glEyeX, glEyeY, 0.5
    GLSL_uniform_2f p~&, "viewDir", glEyeDX, glEyeDY
    glBumpOn = (glSet(SET_BUMP, b) <> 0) * -1 ' (1 or 0: GLBindSlot uses it)
    GLSL_uniform_1f p~&, "smoothOn", (glSet(SET_SMOOTH, b) <> 0) * -1
    GLSL_uniform_1f p~&, "secs", TIMER(0.001) - INT(TIMER(0.001) / 1000) * 1000
    glNeonOn = glSet(SET_NEON, b)
    FOR k = 1 TO GL_DYN
        i$ = "[" + LTRIM$(STR$(k - 1)) + "]"
        IF k <= glNumDyn(b) AND glSet(SET_DYNLIGHT, b) THEN
            GLSL_uniform_3f p~&, "dynPos" + i$, glDynX(k, b), glDynY(k, b), glDynZ(k, b)
            GLSL_uniform_3f p~&, "dynCol" + i$, glDynR(k, b) / 256, glDynG(k, b) / 256, glDynB(k, b) / 256
            GLSL_uniform_1f p~&, "dynRad" + i$, glDynRad(k, b)
        ELSE
            GLSL_uniform_3f p~&, "dynCol" + i$, 0, 0, 0 : GLSL_uniform_1f p~&, "dynRad" + i$, 0.001
        END IF
    NEXT
    _glEnableClientState _GL_NORMAL_ARRAY
END SUB

SUB GLShaderStop
    IF glShaderOn = 0 THEN EXIT SUB
    GLStopDrawing
    GLSL_use 0 : glShaderOn = 0
    GLSL_attrib_off glTanLoc : GLSL_attrib_off glLightLoc : GLSL_attrib_off glDynLoc
    _glDisableClientState _GL_NORMAL_ARRAY
END SUB

' One corner into the batch: where, which texture spot, what colour (and
' the face's normal and tangent, the way to the light, and which moving
' lights reach it). A full batch is drawn there and then.
SUB GLPutCorner(x, y, z, u, v, red, green, blue)
    IF glNumVerts = GL_BATCH THEN GLDraw
    n = glNumVerts
    glVerts(n * 3) = x : glVerts(n * 3 + 1) = y : glVerts(n * 3 + 2) = z
    glTexSpots(n * 2) = u : glTexSpots(n * 2 + 1) = v
    glColors(n * 4) = red : glColors(n * 4 + 1) = green : glColors(n * 4 + 2) = blue : glColors(n * 4 + 3) = 1
    glShadowA(n) = 1
    glNormals(n * 3) = glFaceNX : glNormals(n * 3 + 1) = glFaceNY : glNormals(n * 3 + 2) = glFaceNZ
    glTangents(n * 3) = glFaceTX : glTangents(n * 3 + 1) = glFaceTY : glTangents(n * 3 + 2) = glFaceTZ
    glLightVecs(n * 4) = glCornerLX : glLightVecs(n * 4 + 1) = glCornerLY : glLightVecs(n * 4 + 2) = glCornerLZ : glLightVecs(n * 4 + 3) = glCellDir
    glDynMasks(n * 4) = glCellDyn(1) : glDynMasks(n * 4 + 1) = glCellDyn(2) : glDynMasks(n * 4 + 2) = glCellDyn(3) : glDynMasks(n * 4 + 3) = glCellDyn(4)
    glVertSlot(n) = glCurSlot
    glNumVerts = n + 1
END SUB

' A sprite's corner: its own colour, and the way to its cell's light
SUB GLSpriteCorner(x, y, z, u, v, red, green, blue)
    glCornerLX = glCellLX - x : glCornerLY = glCellLY - y : glCornerLZ = GL_LIGHT_Z - z
    GLPutCorner x, y, z, u, v, red, green, blue
END SUB

' Draw the batch: point OpenGL at the arrays, then, a texture at a time,
' draw its corners, three to a triangle.
'
' Why batches? The first version sent each corner as it went, with
' _glColor3f, _glTexCoord2f and _glVertex3f: three commands a corner, over
' 10,000 a frame in a long hallway. The driver queues commands up and
' works through them on its own, while it also waits for the screen to
' refresh - and once its queue was full, SUB _GL had to wait too, nearly a
' whole refresh (16 ms) a frame, with the game paused all the while: the
' frames per second halved. A batch is a handful of commands, however
' many corners are in it. Then, switching texture (and the shader's
' settings for it) whenever the texture changed cost a few hundred
' switches a frame in a busy room - enough to start that queue filling
' again. So the corners are sorted by texture first ("counting sort":
' count each texture's corners, give each texture its run of the list,
' then put each corner's number in its texture's run), and each texture
' is drawn once, with _glDrawElements reading its run of glIndex().
' And the arrays themselves: drawn from our memory, the driver copies them
' at every draw call - in a 450-cell view, tens of megabytes a frame, and
' the queue filled again. So they go through the GLSL library's "stream"
' (graphics memory, filled once a batch) and the draws read them there.
SUB GLDraw
    IF glNumVerts = 0 THEN EXIT SUB
    FOR s = 0 TO GL_GLOW_TEX : glSlotCount(s) = 0 : NEXT
    FOR n = 0 TO glNumVerts - 1
        glColors(n * 4 + 3) = glShadowA(n) ' (alpha: 1, or a shadow's)
        s = glVertSlot(n) : glSlotCount(s) = glSlotCount(s) + 1
    NEXT
    at& = 0
    FOR s = 0 TO GL_GLOW_TEX : glSlotStart(s) = at& : glSlotFill(s) = at& : at& = at& + glSlotCount(s) : NEXT
    FOR n = 0 TO glNumVerts - 1
        s = glVertSlot(n) : glIndex(glSlotFill(s)) = n : glSlotFill(s) = glSlotFill(s) + 1
    NEXT
    ' Into the stream (the GLSL library's buffer in graphics memory) with
    ' them all, once: the draws below then read from there, with nothing
    ' more to copy - see GLSL_stream_put in the library for why
    n = glNumVerts
    GLSL_stream_bind -1
    _glVertexPointer 3, _GL_FLOAT, 0, GLSL_stream_put%&(_OFFSET(glVerts(0)), n * 12)
    _glTexCoordPointer 2, _GL_FLOAT, 0, GLSL_stream_put%&(_OFFSET(glTexSpots(0)), n * 8)
    _glColorPointer 4, _GL_FLOAT, 0, GLSL_stream_put%&(_OFFSET(glColors(0)), n * 16)
    IF glShaderOn THEN
        _glNormalPointer _GL_FLOAT, 0, GLSL_stream_put%&(_OFFSET(glNormals(0)), n * 12)
        GLSL_attrib_array glTanLoc, 3, GLSL_stream_put%&(_OFFSET(glTangents(0)), n * 12)
        GLSL_attrib_array glLightLoc, 4, GLSL_stream_put%&(_OFFSET(glLightVecs(0)), n * 16)
        GLSL_attrib_array glDynLoc, 4, GLSL_stream_put%&(_OFFSET(glDynMasks(0)), n * 16)
    END IF
    indexAt%& = GLSL_stream_put%&(_OFFSET(glIndex(0)), n * 4)
    FOR s = 1 TO GL_GLOW_TEX
        IF glSlotCount(s) THEN
            GLBindSlot s
            _glDrawElements _GL_TRIANGLES, glSlotCount(s), _GL_UNSIGNED_INT, indexAt%& + glSlotStart(s) * 4
        END IF
    NEXT
    GLSL_stream_bind 0 ' (QB64PE's own drawing needs it unbound)
    glNumVerts = 0
END SUB

' The light the next corners are lit by: cell (cx, cy)'s, times darken (1,
' or less for the darker sides) - and that cell's light middle, and which
' moving lights reach it
SUB GLSetLight(cx, cy, darken, b)
    glLR = glLitR(cx, cy, b) : glLG = glLitG(cx, cy, b) : glLB = glLitB(cx, cy, b) : glShade = darken
    glCellLX = glLitCX(cx, cy, b) : glCellLY = glLitCY(cx, cy, b) : glCellDir = glLitDir(cx, cy, b)
    FOR k = 1 TO GL_DYN : glCellDyn(k) = glDynReach(cx, cy, k, b) : NEXT
END SUB

' One corner of a triangle: map point (x, y) at height z, showing texture
' spot (u, v) (0 to 1 across and down the picture). Its colour is the light
' times the fog at its distance in front of you - chapter 15's sum, at the
' corners; the card blends it across the triangle. It goes into the batch
' (GLPutCorner).
'
' SMOOTH LIGHT takes the light from the cells round the corner instead of
' just this one: the corner's light is blended from the four nearest cell
' middles, more from the nearer ones ("bilinear" - the way the card blends
' a texture), skipping walls. Neighbouring triangles then share their
' corners' light, so it flows across the floor instead of stepping from
' cell to cell. Without the world shader, the moving lights are added here
' too, at each corner (GLDynAt).
SUB GLCorner(x, y, z, u, v)
    IF glMeshBuilding THEN GLMeshCorner x, y, z, u, v : EXIT SUB ' (building the world mesh: just the shape)
    lr = glLR : lg = glLG : lb = glLB
    IF glSet(SET_SMOOTH, glBuf) THEN
        fx = x - 0.5 : fy = y - 0.5 : ix = INT(fx) : iy = INT(fy) : tx = fx - ix : ty = fy - iy
        sr = 0 : sg = 0 : sb = 0 : sw = 0
        FOR j = 0 TO 1 : FOR i = 0 TO 1
            IF GLOpenCell(ix + i, iy + j) THEN
                w = (i * tx + (1 - i) * (1 - tx)) * (j * ty + (1 - j) * (1 - ty))
                sr = sr + glLitR(ix + i, iy + j, glBuf) * w : sg = sg + glLitG(ix + i, iy + j, glBuf) * w : sb = sb + glLitB(ix + i, iy + j, glBuf) * w : sw = sw + w
            END IF
        NEXT : NEXT
        IF sw > 0.0001 THEN lr = sr / sw : lg = sg / sw : lb = sb / sw
    END IF
    IF glShaderOn = 0 AND glSet(SET_DYNLIGHT, glBuf) THEN
        GLDynAt x, y, z, dr, dg, db : lr = lr + dr : lg = lg + dg : lb = lb + db
    END IF
    depth = (x - glEyeX) * glEyeDX + (y - glEyeY) * glEyeDY
    fog = 256 - depth * 16
    IF fog < 0 THEN fog = 0
    IF fog > 256 THEN fog = 256 ' (behind you)
    fog = fog * glShade / 65536 ' (two 256s: the fog's and the light's)
    red = lr * fog : IF red > 1 THEN red = 1
    green = lg * fog : IF green > 1 THEN green = 1
    blue = lb * fog : IF blue > 1 THEN blue = 1
    glCornerLX = glCellLX - x : glCornerLY = glCellLY - y : glCornerLZ = GL_LIGHT_Z - z ' (the way to the light, for bumps)
    GLPutCorner x, y, z, u, v, red, green, blue
END SUB

' A floor (z = 0) or ceiling (z = 1) tile: two triangles, cut along the
' diagonal its split uses (chapter 2) so each half can have its own texture.
' The texture lies flat: u runs with x, v with y, as in chapter 14.
SUB GLFlat(cx, cy, z, tex1, tex2, split)
    IF split = 1 OR split = 3 THEN ' Cut "/": the top-left half, then the bottom-right
        IF split = 1 THEN GLUseTexture tex2 ELSE GLUseTexture tex1
        GLCorner cx, cy, z, 0, 0 : GLCorner cx + 1, cy, z, 1, 0 : GLCorner cx, cy + 1, z, 0, 1
        IF split = 3 THEN GLUseTexture tex2 ELSE GLUseTexture tex1
        GLCorner cx + 1, cy, z, 1, 0 : GLCorner cx + 1, cy + 1, z, 1, 1 : GLCorner cx, cy + 1, z, 0, 1
    ELSE ' Cut "\": the top-right half, then the bottom-left
        IF split = 2 THEN GLUseTexture tex2 ELSE GLUseTexture tex1
        GLCorner cx, cy, z, 0, 0 : GLCorner cx + 1, cy, z, 1, 0 : GLCorner cx + 1, cy + 1, z, 1, 1
        IF split = 4 THEN GLUseTexture tex2 ELSE GLUseTexture tex1
        GLCorner cx, cy, z, 0, 0 : GLCorner cx + 1, cy + 1, z, 1, 1 : GLCorner cx, cy + 1, z, 0, 1
    END IF
END SUB

' Part of an upright face that runs from map point (ax, ay) to (bx, by):
' from s0 to s1 of the way along it, showing texture u0 to u1 across, and
' from height zLow up to zHigh, showing texture vTop (at the top) down to
' vBottom. Two triangles.
SUB GLStrip(ax, ay, bx, by, s0, s1, u0, u1, zLow, zHigh, vTop, vBottom, slot)
    x0 = ax + (bx - ax) * s0 : y0 = ay + (by - ay) * s0
    x1 = ax + (bx - ax) * s1 : y1 = ay + (by - ay) * s1
    faceLen = SQR((bx - ax) ^ 2 + (by - ay) ^ 2) ' The tangent: along the face, the way u grows
    glFaceTX = (bx - ax) / faceLen * SGN(u1 - u0) : glFaceTY = (by - ay) / faceLen * SGN(u1 - u0) : glFaceTZ = 0
    GLUseTexture slot
    GLCorner x0, y0, zHigh, u0, vTop : GLCorner x1, y1, zHigh, u1, vTop : GLCorner x1, y1, zLow, u1, vBottom
    GLCorner x0, y0, zHigh, u0, vTop : GLCorner x1, y1, zLow, u1, vBottom : GLCorner x0, y0, zLow, u0, vBottom
END SUB

' DECALS: each mark laid flat on its surface - the scorch picture
' (MakeScorch), 0.003 off the surface (and "polygon offset": the card
' nudges it nearer in its depth test, so the surface never shows through
' it), see-through where the picture is.
SUB GLDecals(b)
    IF glNumDecal(b) = 0 THEN EXIT SUB
    GLStopDrawing
    _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA : _glDepthMask _GL_FALSE
    _glEnable _GL_POLYGON_OFFSET_FILL : _glPolygonOffset -2, -2
    GLUseTexture T_SLOTS + S_DECAL : uv = spriteSize(S_DECAL) / sprTex
    FOR i = 1 TO glNumDecal(b)
        nx = glDecNX(i, b) : ny = glDecNY(i, b) : nz = glDecNZ(i, b) : sz = glDecSize(i, b) / 2
        cx = glDecX(i, b) + nx * 0.003 : cy = glDecY(i, b) + ny * 0.003 : cz = glDecZ(i, b) + nz * 0.003
        IF ABS(nz) > 0.5 THEN ' On the floor or ceiling: its sides along x and y
            ux = sz : uy = 0 : uz = 0 : vx = 0 : vy = sz : vz = 0
        ELSE ' On a wall: across it, and up it
            ux = -ny * sz : uy = nx * sz : uz = 0 : vx = 0 : vy = 0 : vz = sz
        END IF
        GLPutCorner cx - ux - vx, cy - uy - vy, cz - uz - vz, 0, 0, 1, 1, 1 : GLPutCorner cx + ux - vx, cy + uy - vy, cz + uz - vz, uv, 0, 1, 1, 1
        GLPutCorner cx + ux + vx, cy + uy + vy, cz + uz + vz, uv, uv, 1, 1, 1 : GLPutCorner cx - ux - vx, cy - uy - vy, cz - uz - vz, 0, 0, 1, 1, 1
        GLPutCorner cx + ux + vx, cy + uy + vy, cz + uz + vz, uv, uv, 1, 1, 1 : GLPutCorner cx - ux + vx, cy - uy + vy, cz - uz + vz, 0, uv, 1, 1, 1
    NEXT
    GLStopDrawing
    _glDisable _GL_POLYGON_OFFSET_FILL : _glDepthMask _GL_TRUE : _glDisable _GL_BLEND
END SUB

' A door (not the exit) as a slab across the middle of its doorway (as
' chapter 15's DoorRay): its two faces, lit from the cells they look onto;
' the edges of what's left of it (a sliding door's one, a split door's
' two), a thin slice of its picture; and a lifted shutter's underside.
' (Its track is GLDoorTrack's.)
SUB GLDoorBox(cx, cy, b)
    half = DOOR_THICK / 2 : amt = glDoor(cx, cy, b) : kind = doorType(cx, cy) : across = DoorAcross(cx, cy)
    SELECT CASE kind
        CASE DOOR_SLIDE : IF doorKey(cx, cy) THEN slot = T_DOORK + doorKey(cx, cy) ELSE slot = T_DOOR
        CASE DOOR_SPLIT : slot = T_SPLIT
        CASE ELSE : slot = T_SHUTTER
    END SELECT
    FOR f = -1 TO 1 STEP 2 ' Its faces: f = -1 the north (or west) one, 1 the south (or east)
        IF across = 0 THEN
            ax = cx : bx = cx + 1 : ay = cy + 0.5 + f * half : by = ay
            GLSetLight cx, cy + f, 0.7, b : glFaceNX = 0 : glFaceNY = f
        ELSE
            ay = cy : by = cy + 1 : ax = cx + 0.5 + f * half : bx = ax
            GLSetLight cx + f, cy, 1, b : glFaceNX = f : glFaceNY = 0
        END IF
        glFaceNZ = 0
        SELECT CASE kind
            CASE DOOR_SLIDE
                IF amt < 1 THEN GLStrip ax, ay, bx, by, amt, 1, 0, 1 - amt, 0, 1, 0, 1, slot
            CASE DOOR_SPLIT
                IF amt < 1 THEN
                    GLStrip ax, ay, bx, by, 0, 0.5 - amt / 2, amt / 2, 0.5, 0, 1, 0, 1, slot
                    GLStrip ax, ay, bx, by, 0.5 + amt / 2, 1, 0.5, 1 - amt / 2, 0, 1, 0, 1, slot
                END IF
            CASE ELSE
                IF amt < 1 THEN GLStrip ax, ay, bx, by, 0, 1, 0, 1, amt, 1, amt, 1, slot
        END SELECT
    NEXT
    GLSetLight cx, cy, 0.85, b
    SELECT CASE kind ' Its edges
        CASE DOOR_SLIDE : GLDoorEdge cx, cy, across, amt, -1, slot
        CASE DOOR_SPLIT : GLDoorEdge cx, cy, across, 0.5 - amt / 2, 1, slot : GLDoorEdge cx, cy, across, 0.5 + amt / 2, -1, slot
        CASE ELSE ' A shutter's underside, at the height it's lifted to
            IF amt > 0 THEN
                glFaceNX = 0 : glFaceNY = 0 : glFaceNZ = -1
                GLDoorFlat cx, cy, across, -half, half, amt, 0.96, 1, slot
            END IF
    END SELECT
END SUB

' Did this frame's rays reach cell (cx, cy), or a cell beside it?
FUNCTION GLNearSeen(cx, cy, b)
    stamp& = glFrame(b)
    IF glSeen(cx, cy, b) = stamp& OR glSeen(cx + 1, cy, b) = stamp& OR glSeen(cx, cy + 1, b) = stamp& THEN GLNearSeen = -1 : EXIT FUNCTION
    IF cx > 0 THEN IF glSeen(cx - 1, cy, b) = stamp& THEN GLNearSeen = -1 : EXIT FUNCTION
    IF cy > 0 THEN IF glSeen(cx, cy - 1, b) = stamp& THEN GLNearSeen = -1
END FUNCTION

' The track door (cx, cy) runs in: a dark groove across the floor and the
' ceiling, a quarter as bright as the cell (as chapter 14's floor does it)
SUB GLDoorTrack(cx, cy, b)
    across = DoorAcross(cx, cy)
    GLSetLight cx, cy, 0.25, b
    glFaceNX = 0 : glFaceNY = 0 : glFaceNZ = 1 : GLDoorFlat cx, cy, across, -TRACK_HALF, TRACK_HALF, 0.004, 0.4, 0.5, T_SHUTTER
    glFaceNZ = -1 : GLDoorFlat cx, cy, across, -TRACK_HALF, TRACK_HALF, 0.996, 0.4, 0.5, T_SHUTTER
END SUB

' A door's edge: square to the door, at e along it (0..1), across its
' thickness, floor to ceiling, facing along it (facing 1 or -1)
SUB GLDoorEdge(cx, cy, across, e, facing, slot)
    half = DOOR_THICK / 2
    IF across = 0 THEN
        ax = cx + e : bx = ax : ay = cy + 0.5 - half : by = cy + 0.5 + half : glFaceNX = facing : glFaceNY = 0
    ELSE
        ay = cy + e : by = ay : ax = cx + 0.5 - half : bx = cx + 0.5 + half : glFaceNX = 0 : glFaceNY = facing
    END IF
    glFaceNZ = 0
    GLStrip ax, ay, bx, by, 0, 1, 0, DOOR_THICK, 0, 1, 0, 1, slot
END SUB

' A flat strip across a doorway at height z: the whole way along the door,
' from n0 to n1 through it (from its middle line), showing texture rows v0
' to v1 (for a shutter's underside, and the tracks)
SUB GLDoorFlat(cx, cy, across, n0, n1, z, v0, v1, slot)
    GLUseTexture slot
    IF across = 0 THEN
        glFaceTX = 1 : glFaceTY = 0 : glFaceTZ = 0
        GLCorner cx, cy + 0.5 + n0, z, 0, v0 : GLCorner cx + 1, cy + 0.5 + n0, z, 1, v0 : GLCorner cx + 1, cy + 0.5 + n1, z, 1, v1
        GLCorner cx, cy + 0.5 + n0, z, 0, v0 : GLCorner cx + 1, cy + 0.5 + n1, z, 1, v1 : GLCorner cx, cy + 0.5 + n1, z, 0, v1
    ELSE
        glFaceTX = 0 : glFaceTY = 1 : glFaceTZ = 0
        GLCorner cx + 0.5 + n0, cy, z, 0, v0 : GLCorner cx + 0.5 + n0, cy + 1, z, 1, v0 : GLCorner cx + 0.5 + n1, cy + 1, z, 1, v1
        GLCorner cx + 0.5 + n0, cy, z, 0, v0 : GLCorner cx + 0.5 + n1, cy + 1, z, 1, v1 : GLCorner cx + 0.5 + n1, cy, z, 0, v1
    END IF
END SUB

' Does side (1 west, 2 east, 3 north, 4 south) of a diagonal wall's cell
' touch its solid corner (1 top-left, 2 top-right, 3 bottom-right, 4
' bottom-left)? Those two sides are walls; the other two are open.
FUNCTION SideTouchesCorner(side, corner)
    SELECT CASE side
        CASE 1 : SideTouchesCorner = corner = 1 OR corner = 4
        CASE 2 : SideTouchesCorner = corner = 2 OR corner = 3
        CASE 3 : SideTouchesCorner = corner = 1 OR corner = 2
        CASE 4 : SideTouchesCorner = corner = 3 OR corner = 4
    END SELECT
END FUNCTION

' One side of wall cell (cx, cy) - if it looks onto a cell that isn't
' solid wall, and you're in front of it. Its ends are (ax, ay) and
' (bx, by), in the direction x or y grows. It's lit by the cell it looks
' onto, and north and south sides are darker (chapter 15's y-sides).
'
' Which way round the texture goes copies chapter 15 exactly. A wall reads
' left to right from in front, so on west and south sides (where "left"
' is the far end) it runs backwards, from 1 to 0. Doors don't turn round,
' so they look mirrored from the other side, as in the software renderer.
' The lifts, one frame on: each one's height (liftZ) towards where it's
' going, a wait at each end; its cells' floors set to it. (px, py) is you:
' an elevator (mode 2) goes up when you're on it, and down again a while
' after you've got off
SUB MoveLifts(px, py)
    me = liftCell(INT(px), INT(py))
    FOR k = 1 TO numLifts
        IF liftDir(k) = 0 THEN ' Waiting at one end
            IF liftWait(k) > 0 THEN liftWait(k) = liftWait(k) - 1
            IF liftMode(k) = 2 THEN
                IF me = k AND liftZ(k) <= liftLow(k) + 0.001 AND liftWait(k) = 0 THEN liftDir(k) = 1
                IF me <> k AND liftZ(k) >= liftHigh(k) - 0.001 AND liftWait(k) = 0 THEN liftDir(k) = -1
                IF me = k AND liftZ(k) >= liftHigh(k) - 0.001 THEN liftWait(k) = 180 ' (you're still on it: stay up)
            ELSEIF liftMode(k) = 1 AND liftWait(k) = 0 THEN ' (mode 3: only when told - liftgo, from a trigger)
                IF liftZ(k) <= liftLow(k) + 0.001 THEN liftDir(k) = 1 ELSE liftDir(k) = -1
            END IF
        ELSE
            liftZ(k) = liftZ(k) + liftDir(k) * liftSpeed(k)
            IF liftZ(k) >= liftHigh(k) THEN liftZ(k) = liftHigh(k) : liftDir(k) = 0 : liftWait(k) = 120
            IF liftZ(k) <= liftLow(k) THEN liftZ(k) = liftLow(k) : liftDir(k) = 0 : liftWait(k) = 120
        END IF
        FOR y = liftY0(k) TO liftY1(k) : FOR x = liftX0(k) TO liftX1(k)
            IF liftCell(x, y) = k THEN floorH(x, y) = liftZ(k)
        NEXT : NEXT
        LiftSound k, px, py
    NEXT
END SUB

' A lift's sound, as DOOM's: the motor starting as it sets off, running
' while it moves - its own looping copy of lift-move.wav (liftHum&), as
' loud as where it is says - and a clunk when it stops at either end.
' Done by what changed since last frame, so it's the same however it was
' set going (riding it, by itself, or a trigger's liftgo).
SUB LiftSound(k, px, py)
    cx = (liftX0(k) + liftX1(k) + 1) / 2 : cy = (liftY0(k) + liftY1(k) + 1) / 2
    IF liftDir(k) <> 0 AND liftWasDir(k) = 0 THEN SfxAt sndLiftStart&, cx, cy, px, py
    IF liftDir(k) = 0 AND liftWasDir(k) <> 0 THEN SfxAt sndLiftStop&, cx, cy, px, py
    liftWasDir(k) = liftDir(k)
    IF sndLiftMove& <= 0 THEN EXIT SUB
    IF liftDir(k) <> 0 THEN
        IF liftHum&(k) = 0 THEN liftHum&(k) = _SNDCOPY(sndLiftMove&)
        IF liftHum&(k) > 0 THEN
            _SNDVOL liftHum&(k), SfxVolAt!(cx, cy, px, py, SFX_RANGE) * 0.7 * setting(SET_SFX) / 100
            IF NOT _SNDPLAYING(liftHum&(k)) THEN _SNDLOOP liftHum&(k)
        END IF
    ELSEIF liftHum&(k) > 0 THEN
        _SNDSTOP liftHum&(k)
    END IF
END SUB

' Every lift's motor and trap's roar quiet - a new level, the menu, the
' sector tally (a lift still moving, or a trap still lit, starts its sound
' again when the game goes on)
SUB WorldLoopsOff
    FOR k = 1 TO MAX_LIFTS
        IF liftHum&(k) > 0 THEN _SNDSTOP liftHum&(k)
    NEXT
    FOR k = 1 TO MAX_EVENTS
        IF evHum&(k) > 0 THEN _SNDSTOP evHum&(k)
    NEXT
END SUB

' A trap's show, each frame, by how lit it is (evGlow): nothing when it's
' safe but for a rare wisp or spark (it's always a bit alive); warming up,
' smoke and embers (fire) or the odd crackle (electric); live, the whole
' floor blazing - flames, and smoke rising off them - or arcing, sparks
' flying. More for a bigger trap. Then its sound: SoundAt, as loud as lit.
SUB TrapFx(ev)
    w = evX1(ev) - evX0(ev) + 1 : h = evY1(ev) - evY0(ev) + 1 : area = w * h
    fire = evType(ev) = EV_FIRETRAP : g = evGlow(ev)
    cx = evX0(ev) + w / 2 : cy = evY0(ev) + h / 2
    IF g = 0 THEN
        IF RND < 0.02 THEN
            x = evX0(ev) + RND * w : y = evY0(ev) + RND * h
            IF fire THEN SpawnPart PART_SMOKE, x, y, FloorAt(x, y) + 0.05, 0, 0, 0.006, 70, 0.12, 0.11, 0.1, 0.1 ELSE SpawnSparks x, y, 0.02, 1, 90, 170, 255
        END IF
    ELSE
        IF fire THEN
            nFlame = area * 0.5 * g : IF g < 1 THEN nFlame = area * 0.04
            FOR k = 1 TO INT(nFlame) + (RND < nFlame - INT(nFlame))
                x = evX0(ev) + RND * w : y = evY0(ev) + RND * h
                SpawnPart PART_FLAME, x, y, FloorAt(x, y) + 0.02, (RND - 0.5) * 0.008, (RND - 0.5) * 0.008, 0.015 + RND * 0.025, 20 + INT(RND * 20), 1, 0.35 + RND * 0.35, 0.06, 0.12 + RND * 0.1
            NEXT
            nSmoke = area * 0.08 * (0.4 + g) ' (smoke off the fire - and warning before it)
            FOR k = 1 TO INT(nSmoke) + (RND < nSmoke - INT(nSmoke))
                x = evX0(ev) + RND * w : y = evY0(ev) + RND * h
                SpawnPart PART_SMOKE, x, y, FloorAt(x, y) + 0.2 + RND * 0.25, (RND - 0.5) * 0.004, (RND - 0.5) * 0.004, 0.006 + RND * 0.008, 70 + INT(RND * 50), 0.32, 0.3, 0.28, 0.14 + RND * 0.1
            NEXT
        ELSE
            IF RND < area * 0.2 * g THEN SpawnSparks evX0(ev) + RND * w, evY0(ev) + RND * h, 0.02, 2 + INT(3 * g), 120, 200, 255
            FOR arcs = 1 TO 1 + INT(g * area / 12) ' Arcs: crooked lines of bright points, arching up between two places on it
                IF RND < 0.1 + 0.6 * g THEN
                    ax = evX0(ev) + RND * w : ay = evY0(ev) + RND * h : bx = evX0(ev) + RND * w : by = evY0(ev) + RND * h
                    d = SQR((bx - ax) ^ 2 + (by - ay) ^ 2) : IF d > 3 THEN bx = ax + (bx - ax) * 3 / d : by = ay + (by - ay) * 3 / d : d = 3
                    IF g < 1 THEN bx = ax + (bx - ax) * 0.3 : by = ay + (by - ay) * 0.3 : d = d * 0.3 ' (warming up: short ones)
                    steps = INT(d * 14) + 5 : tall = 0.15 + d * 0.12 : jx = 0 : jy = 0 : jz = 0
                    FOR k = 0 TO steps
                        f = k / steps
                        jx = jx + (RND - 0.5) * 0.1 : jy = jy + (RND - 0.5) * 0.1 : jz = jz + (RND - 0.5) * 0.06 ' (wandering off its curve)
                        x = ax + (bx - ax) * f + jx * SIN(f * 3.14159) : y = ay + (by - ay) * f + jy * SIN(f * 3.14159)
                        z = 0.02 + (tall + jz) * SIN(f * 3.14159) : IF z < 0.02 THEN z = 0.02
                        SpawnPart PART_ARC, x, y, FloorAt(x, y) + z, 0, 0, 0, 3 + INT(RND * 4), 0.8, 0.92, 1, 0.06
                    NEXT
                END IF
            NEXT
        END IF
    END IF
    IF fire THEN snd& = sndTrapFire& ELSE snd& = sndTrapElec&
    IF snd& <= 0 THEN EXIT SUB
    IF g > 0 THEN
        IF evHum&(ev) = 0 THEN evHum&(ev) = _SNDCOPY(snd&)
        IF evHum&(ev) > 0 THEN
            _SNDVOL evHum&(ev), SfxVolAt!(cx, cy, playerX, playerY, SFX_RANGE) * 0.8 * g * setting(SET_SFX) / 100
            IF NOT _SNDPLAYING(evHum&(ev)) THEN _SNDLOOP evHum&(ev)
        END IF
    ELSEIF evHum&(ev) > 0 THEN
        _SNDSTOP evHum&(ev)
    END IF
END SUB

' OpenGL: the lifts where they are now - each cell's top, and its sides
' down (or up) to the floor next to it
SUB GLLifts(b)
    FOR k = 1 TO numLifts
        FOR cy = liftY0(k) TO liftY1(k) : FOR cx = liftX0(k) TO liftX1(k)
            IF liftCell(cx, cy) = k THEN
                IF GLNearSeen(cx, cy, b) THEN
                    GLSetLight cx, cy, 1, b
                    glFaceTX = 1 : glFaceTY = 0 : glFaceTZ = 0 : glFaceNX = 0 : glFaceNY = 0 : glFaceNZ = 1
                    GLFlat cx, cy, floorH(cx, cy), floorTex(cx, cy), floorTex2(cx, cy), floorSplit(cx, cy)
                    IF liftCell(cx + 1, cy) <> k AND GLOpenCell(cx + 1, cy) THEN GLStep cx, cy, cx + 1, cy, b
                    IF liftCell(cx - 1, cy) <> k AND GLOpenCell(cx - 1, cy) THEN GLStep cx - 1, cy, cx, cy, b
                    IF liftCell(cx, cy + 1) <> k AND GLOpenCell(cx, cy + 1) THEN GLStep cx, cy, cx, cy + 1, b
                    IF liftCell(cx, cy - 1) <> k AND GLOpenCell(cx, cy - 1) THEN GLStep cx, cy - 1, cx, cy, b
                END IF
            END IF
        NEXT : NEXT
    NEXT
END SUB

' Between two open cells side by side, (ax, ay) and (bx, by): where their
' floors differ, the face of the step, from the lower floor up to the
' higher, facing the lower cell; where their ceilings differ, the face
' from the lower ceiling up to the higher, facing the higher-ceilinged
' cell. Both in the level's main wall picture.
SUB GLStep(ax, ay, bx, by, b)
    IF ax = bx THEN ' (the edge between them, as a line from (ex0, ey0) to (ex1, ey1))
        ex0 = ax : ey0 = by : ex1 = ax + 1 : ey1 = by
    ELSE
        ex0 = bx : ey0 = ay : ex1 = bx : ey1 = ay + 1
    END IF
    fa = floorH(ax, ay) : fb = floorH(bx, by)
    IF fa <> fb THEN
        IF fa < fb THEN lx = ax : ly = ay : zl = fa : zh = fb ELSE lx = bx : ly = by : zl = fb : zh = fa
        GLSetLight lx, ly, 1, b
        glFaceNX = SGN(lx - (ax + bx - lx)) : glFaceNY = SGN(ly - (ay + by - ly)) : glFaceNZ = 0
        ' The picture by height, as the walls'... but a lift's side (the
        ' higher cell is a lift) hangs from its top edge in its own picture,
        ' so it rides up and down with it instead of sliding past
        IF liftCell(ax + bx - lx, ay + by - ly) THEN
            GLStrip ex0, ey0, ex1, ey1, 0, 1, 0, 1, zl, zh, 0, zh - zl, T_LIFTSIDE
        ELSE ' (the step's face is the higher cell's side towards the lower one - its own picture, if it has one)
            hx = ax + bx - lx : hy = ay + by - ly
            GLStrip ex0, ey0, ex1, ey1, 0, 1, 0, 1, zl, zh, 1 - zh, 1 - zl, FaceSlot(hx, hy, SideToward(hx, hy, lx, ly), 0, 0, wallTexSlot(1))
        END IF
    END IF
    ca = ceilH(ax, ay) : cb = ceilH(bx, by)
    IF ca <> cb THEN
        IF ca > cb THEN lx = ax : ly = ay : zl = cb : zh = ca ELSE lx = bx : ly = by : zl = ca : zh = cb
        GLSetLight lx, ly, 1, b
        glFaceNX = SGN(lx - (ax + bx - lx)) : glFaceNY = SGN(ly - (ay + by - ly)) : glFaceNZ = 0
        hx = ax + bx - lx : hy = ay + by - ly ' (the lintel's the lower ceiling's side, towards the higher)
        GLStrip ex0, ey0, ex1, ey1, 0, 1, 0, 1, zl, zh, 1 - zh, 1 - zl, FaceSlot(hx, hy, SideToward(hx, hy, lx, ly) + 4, 0, 0, wallTexSlot(1))
    END IF
END SUB

SUB GLFace(cx, cy, side, b)
    SELECT CASE side
        CASE 1 : nx = cx - 1 : ny = cy : ax = cx : ay = cy : bx = cx : by = cy + 1 : inFront = glEyeX < cx
        CASE 2 : nx = cx + 1 : ny = cy : ax = cx + 1 : ay = cy : bx = cx + 1 : by = cy + 1 : inFront = glEyeX > cx + 1
        CASE 3 : nx = cx : ny = cy - 1 : ax = cx : ay = cy : bx = cx + 1 : by = cy : inFront = glEyeY < cy
        CASE 4 : nx = cx : ny = cy + 1 : ax = cx : ay = cy + 1 : bx = cx + 1 : by = cy + 1 : inFront = glEyeY > cy + 1
    END SELECT
    IF NOT inFront AND NOT glMeshBuilding THEN EXIT SUB ' (the mesh has every side: the depth buffer sorts them out)
    IF nx < 0 OR ny < 0 OR nx >= MAP_SIZE OR ny >= MAP_SIZE THEN EXIT SUB
    IF IsWall(nx, ny) AND diagCorner(nx, ny) = 0 THEN EXIT SUB ' Wall against wall: never seen
    IF side <= 2 THEN GLSetLight nx, ny, 1, b ELSE GLSetLight nx, ny, 0.7, b
    glFaceNX = nx - cx : glFaceNY = ny - cy : glFaceNZ = 0 ' Facing the cell it looks onto
    IF side = 1 OR side = 4 THEN u0 = 1 : u1 = 0 ELSE u0 = 0 : u1 = 1
    IF worldMap(cx, cy) <> 2 THEN ' A wall: from the floor to the ceiling of the cell it looks onto
        fz = floorH(nx, ny) : cz = ceilH(nx, ny)
        GLStrip ax, ay, bx, by, 0, 1, u0, u1, fz, cz, 1 - cz, 1 - fz, FaceSlot(cx, cy, VAL(MID$("3142", side, 1)), 0, 0, wallTexSlot(worldMap(cx, cy))) ' (GLFace's sides 1-4 are west, east, north, south - [faces]' are east, south, west, north)
        EXIT SUB
    END IF
    doorAmt = glDoor(cx, cy, b) ' A door: 0 shut .. 1 open
    SELECT CASE doorType(cx, cy)
        CASE DOOR_SLIDE ' What's left of it, from doorAmt to the end, its texture slid along
            IF doorKey(cx, cy) THEN slot = T_DOORK + doorKey(cx, cy) ELSE slot = T_DOOR
            IF doorAmt < 1 THEN GLStrip ax, ay, bx, by, doorAmt, 1, 0, 1 - doorAmt, 0, 1, 0, 1, slot
        CASE DOOR_SPLIT ' Two halves, parting from the middle
            IF doorAmt < 1 THEN
                GLStrip ax, ay, bx, by, 0, 0.5 - doorAmt / 2, doorAmt / 2, 0.5, 0, 1, 0, 1, T_SPLIT
                GLStrip ax, ay, bx, by, 0.5 + doorAmt / 2, 1, 0.5, 1 - doorAmt / 2, 0, 1, 0, 1, T_SPLIT
            END IF
        CASE DOOR_EXIT ' Turned like a wall, so its sign reads the right way
            GLStrip ax, ay, bx, by, 0, 1, u0, u1, 0, 1, 0, 1, T_EXIT
        CASE ELSE ' A shutter: the part still hanging down, showing the bottom of its texture
            IF doorAmt < 1 THEN GLStrip ax, ay, bx, by, 0, 1, 0, 1, doorAmt, 1, doorAmt, 1, T_SHUTTER
    END SELECT
END SUB

' A diagonal wall's slanted face, corner to corner across its cell, if
' you're on its open side. Lit by its own cell, between the two sides'
' darkness (as chapter 15), and textured left to right along x - turned
' round for corners 1 and 2, as chapter 15 does.
SUB GLDiagonal(cx, cy, corner, b)
    IF NOT glMeshBuilding THEN IF InDiagonalWall(corner, glEyeX - cx, glEyeY - cy) THEN EXIT SUB ' You're behind it
    IF corner = 1 OR corner = 3 THEN
        ax = cx : ay = cy + 1 : bx = cx + 1 : by = cy ' "/"
    ELSE
        ax = cx : ay = cy : bx = cx + 1 : by = cy + 1 ' "\"
    END IF
    IF corner <= 2 THEN u0 = 1 : u1 = 0 ELSE u0 = 0 : u1 = 1
    GLSetLight cx, cy, 0.85, b
    glFaceNX = -(by - ay) * 0.7071 : glFaceNY = (bx - ax) * 0.7071 : glFaceNZ = 0 ' Square to the diagonal...
    IF InDiagonalWall(corner, 0.5 + glFaceNX * 0.1, 0.5 + glFaceNY * 0.1) THEN glFaceNX = -glFaceNX : glFaceNY = -glFaceNY ' ...on its open side
    GLStrip ax, ay, bx, by, 0, 1, u0, u1, floorH(cx, cy), ceilH(cx, cy), 1 - ceilH(cx, cy), 1 - floorH(cx, cy), wallTexSlot(worldMap(cx, cy))
END SUB

' THE SHADERS. OpenGL's fixed recipe colours a pixel as texture times the
' corner colour. A shader is a recipe of our own - a little program in
' GLSL (OpenGL's shading language, which looks like C) that the graphics
' card runs for every corner (the vertex shader) and every pixel (the
' fragment shader). QB64PE's _gl... commands stop before shaders, so the
' GLSL library from QB64_GJ_LIB (included at the top and bottom of this
' file) compiles ours and feeds it. There are four:
'
' THE WORLD SHADER draws walls, floors, ceilings and sprites. It keeps the
' lighting and fog the corners already carry, and adds, for every pixel:
'
'   BUMPS. Every texture's alpha holds its brightness (GLSendTextures),
'   read as height (a sprite, which needs its alpha, uses its brightness
'   directly). Comparing the heights left and right of a pixel, and above
'   and below, says which way the surface there slopes - so the surface's
'   normal (the way it faces) is tilted that way, along the texture's own
'   directions on the face: its tangent (the way u grows) and the way v
'   grows (down a wall, along y on a floor). Then, how squarely the tilted
'   surface faces the light, compared with how squarely the flat face does,
'   brightens slopes facing the light and darkens ones facing away - so on
'   average the brightness stays the same, and the per-cell light (chapter
'   14) still decides how bright things are.
'
'   Where's the light? Each cell's lights add up into the middle of the
'   light falling on it (litSumX..., chapter 14), hanging GL_LIGHT_Z up;
'   each corner gets the way from it to there, and the card blends that
'   across the triangle, so every pixel knows its own way to the light.
'   glLitDir is how much of the cell's light comes from lights at all; the
'   rest, the level's ambient light, is taken to come from straight above,
'   like the station's ceiling lights - so bumps show everywhere.
'
'   SHINE. A highlight where the light would bounce off into your eye
'   (the "Blinn-Phong" highlight: the bumpy normal against the halfway
'   between the ways to the light and to you), as strong as the texture's
'   shine - metal doors most.
'
'   MOVING LIGHTS. Up to GL_DYN lights that move every frame - your muzzle
'   flash, explosions, bolts - lighting each pixel by its own distance and
'   angle to them, instead of whole cells. Walls in the way are handled the
'   cell way: glDynReach (chapter 17) says which cells each light reaches,
'   and every corner carries its cell's answer (the attribute aDyn).
'
'   NEON. Bright, strongly coloured pixels - the cyan strips in the walls,
'   server lights, screens - light themselves: they keep their colour
'   however dark it is round them, and bloom picks them up. Some textures
'   animate it (anim): screens flicker block by block, warning stripes
'   chase along, lights and reactors pulse.
'
'   WET FLOORS. A floor pass draws the floors see-through (its alpha is
'   1 - reflectAmt), over the mirror image drawn under them.
'
' THE POST-PROCESSING SHADERS read the finished picture: the bright pass
' keeps only the bright parts, the blur spreads them out (nine pixels in a
' line, weighted like a bell curve, across and then down), and the final
' one puts it all together - heat shimmer, the railgun's zoom blur, the
' scene, the bloom, the red hurt pulse, the HUD, and scanlines or a CRT.
'
' If the driver can't do shaders, or one won't compile, its program stays
' 0: without the world shader the fixed recipe draws everything (with the
' moving lights added at the corners); without the post shader the extras
' that need it are skipped. (Why: glShaderError$.)
SUB GLBuildShaders
    glWorldTried = -1
    IF NOT GLSL_supported% THEN glShaderError$ = "no shaders (OpenGL 2.0) on this driver" : EXIT SUB
    nl$ = CHR$(10)
    vs$ = "#version 120" + nl$
    vs$ = vs$ + "attribute vec3 aTangent;  // the way u grows along the face" + nl$
    vs$ = vs$ + "attribute vec4 aLight;    // the way to the light, and how much of the light that is" + nl$
    vs$ = vs$ + "attribute vec4 aDyn;      // which of the moving lights reach this corner's cell" + nl$
    vs$ = vs$ + "varying vec3 vPos, vNormal, vTangent;" + nl$
    vs$ = vs$ + "varying vec4 vLight, vDyn;" + nl$
    vs$ = vs$ + "void main() {" + nl$
    vs$ = vs$ + "    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;  // the camera, as OpenGL does it" + nl$
    vs$ = vs$ + "    gl_FrontColor = gl_Color;                                // light x fog, from GLCorner" + nl$
    vs$ = vs$ + "    gl_TexCoord[0] = gl_MultiTexCoord0;" + nl$
    vs$ = vs$ + "    vPos = gl_Vertex.xyz; vNormal = gl_Normal; vTangent = aTangent; vLight = aLight; vDyn = aDyn;" + nl$
    vs$ = vs$ + "}" + nl$

    fs$ = "#version 120" + nl$
    fs$ = fs$ + "uniform sampler2D tex;      // the texture (alpha = height, except sprites)" + nl$
    fs$ = fs$ + "uniform vec3 eye;           // where you are" + nl$
    fs$ = fs$ + "uniform vec2 viewDir;       // the way you face" + nl$
    fs$ = fs$ + "uniform float bump, texel, shine, reflectAmt, neon, anim, isSprite, secs;" + nl$
    fs$ = fs$ + "uniform float mirrorCut;    // the mirror image: leave out what's below the floor" + nl$
    fs$ = fs$ + "uniform float gridAmt;      // the editor's grid: how strong (0 off)" + nl$
    fs$ = fs$ + "uniform vec3 dynPos[4];     // the moving lights: where..." + nl$
    fs$ = fs$ + "uniform vec3 dynCol[4];     // ...what colour..." + nl$
    fs$ = fs$ + "uniform float dynRad[4];    // ...and how far they reach" + nl$
    fs$ = fs$ + "uniform sampler2D litTex, infoTex, dynTex;  // the light tables (cellLit)" + nl$
    fs$ = fs$ + "uniform float cellLit, smoothOn;  // light from the tables, not the corners; blended between cells" + nl$
    fs$ = fs$ + "varying vec3 vPos, vNormal, vTangent;" + nl$
    fs$ = fs$ + "varying vec4 vLight, vDyn;" + nl$
    fs$ = fs$ + "float height(vec2 p) {" + nl$
    fs$ = fs$ + "    vec4 t = texture2D(tex, p);" + nl$
    fs$ = fs$ + "    return isSprite > 0.5 ? dot(t.rgb, vec3(0.3, 0.59, 0.11)) : t.a;" + nl$
    fs$ = fs$ + "}" + nl$
    fs$ = fs$ + "void main() {" + nl$
    fs$ = fs$ + "    if (mirrorCut > 0.5 && vPos.z < 0.0) discard;  // WET FLOORS: a pit's sides would reflect up into the room" + nl$
    fs$ = fs$ + "    vec2 uv = gl_TexCoord[0].xy;" + nl$
    fs$ = fs$ + "    vec4 c = texture2D(tex, uv);" + nl$
    fs$ = fs$ + "    if (isSprite > 0.5 && c.a < 0.502) discard;  // a sprite's see-through pixels" + nl$
    fs$ = fs$ + "    vec3 n = normalize(vNormal);" + nl$
    fs$ = fs$ + "    vec3 t = normalize(vTangent);" + nl$
    fs$ = fs$ + "    vec3 b = abs(n.z) > 0.5 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, -1.0);  // the way v grows" + nl$
    fs$ = fs$ + "    float hl = height(uv - vec2(texel, 0.0)), hr = height(uv + vec2(texel, 0.0));" + nl$
    fs$ = fs$ + "    float hu = height(uv - vec2(0.0, texel)), hd = height(uv + vec2(0.0, texel));" + nl$
    fs$ = fs$ + "    vec3 nb = normalize(n + (t * (hl - hr) + b * (hu - hd)) * bump);  // tilted down the slope" + nl$
    fs$ = fs$ + "    float fog = clamp(1.0 - dot(vPos.xy - eye.xy, viewDir) / 16.0, 0.0, 1.0);  // as chapters 14 and 15" + nl$
    fs$ = fs$ + "    vec3 lightCol = gl_Color.rgb; vec4 lv = vLight; vec4 reach = vDyn;" + nl$
    fs$ = fs$ + "    if (cellLit > 0.5) {  // the world: look the light up in the tables, at the cell in front of the surface" + nl$
    fs$ = fs$ + "        vec2 p = vPos.xy + n.xy * 0.02;" + nl$
    fs$ = fs$ + "        vec2 cuv = (floor(p) + 0.5) / 64.0;" + nl$
    fs$ = fs$ + "        vec4 info = texture2D(infoTex, cuv);" + nl$
    fs$ = fs$ + "        reach = texture2D(dynTex, cuv);" + nl$
    fs$ = fs$ + "        vec3 light = texture2D(litTex, cuv).rgb;" + nl$
    fs$ = fs$ + "        if (smoothOn > 0.5) {  // blend the four nearest cell middles, skipping walls (alpha 0)" + nl$
    fs$ = fs$ + "            vec2 f = p - 0.5; vec2 i0 = floor(f); vec2 w = f - i0;" + nl$
    fs$ = fs$ + "            vec4 a = texture2D(litTex, (i0 + vec2(0.5, 0.5)) / 64.0), bb = texture2D(litTex, (i0 + vec2(1.5, 0.5)) / 64.0);" + nl$
    fs$ = fs$ + "            vec4 cc = texture2D(litTex, (i0 + vec2(0.5, 1.5)) / 64.0), dd = texture2D(litTex, (i0 + vec2(1.5, 1.5)) / 64.0);" + nl$
    fs$ = fs$ + "            float wa = (1.0 - w.x) * (1.0 - w.y) * a.a, wb = w.x * (1.0 - w.y) * bb.a, wc = (1.0 - w.x) * w.y * cc.a, wd = w.x * w.y * dd.a;" + nl$
    fs$ = fs$ + "            float ws = wa + wb + wc + wd;" + nl$
    fs$ = fs$ + "            if (ws > 0.001) light = (a.rgb * wa + bb.rgb * wb + cc.rgb * wc + dd.rgb * wd) / ws;" + nl$
    fs$ = fs$ + "        }" + nl$
    fs$ = fs$ + "        float side = abs(n.z) > 0.5 ? 1.0 : (abs(n.x) > 0.99 ? 1.0 : (abs(n.y) > 0.99 ? 0.7 : 0.85));  // y-sides darker, diagonals between" + nl$
    fs$ = fs$ + "        lightCol = min(light * fog * side / 256.0, vec3(1.0));" + nl$
    fs$ = fs$ + "        lv = vec4(info.xy - vPos.xy, 0.85 - vPos.z, info.z);" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    vec3 l = normalize(normalize(lv.xyz + vec3(0.0, 0.0, 0.0001)) * lv.w + vec3(0.0, 0.0, 1.0 - lv.w));" + nl$
    fs$ = fs$ + "    float shade = clamp(1.0 + (dot(nb, l) - dot(n, l)) * 1.5, 0.4, 1.8);  // brighter facing it, darker facing away" + nl$
    fs$ = fs$ + "    vec3 toEye = normalize(eye - vPos);" + nl$
    fs$ = fs$ + "    float highlight = pow(max(dot(nb, normalize(l + toEye)), 0.0), 24.0) * shine * step(0.0, dot(n, l));" + nl$
    fs$ = fs$ + "    vec3 dyn = vec3(0.0); float dynShine = 0.0;" + nl$
    fs$ = fs$ + "    for (int i = 0; i < 4; i++) {" + nl$
    fs$ = fs$ + "        float r = i == 0 ? reach.x : (i == 1 ? reach.y : (i == 2 ? reach.z : reach.w));" + nl$
    fs$ = fs$ + "        vec3 d = dynPos[i] - vPos; float dist = length(d);" + nl$
    fs$ = fs$ + "        float fall = clamp(1.0 - dist / dynRad[i], 0.0, 1.0); fall = fall * fall * r;" + nl$
    fs$ = fs$ + "        vec3 dn = d / max(dist, 0.001);" + nl$
    fs$ = fs$ + "        float facing = isSprite > 0.5 ? 0.8 : max(dot(nb, dn), 0.0);" + nl$
    fs$ = fs$ + "        dyn += dynCol[i] * fall * facing;" + nl$
    fs$ = fs$ + "        dynShine += fall * pow(max(dot(nb, normalize(dn + toEye)), 0.0), 24.0) * (dynCol[i].r + dynCol[i].g + dynCol[i].b);" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    vec3 col = c.rgb * (lightCol * shade + dyn * fog) + lightCol * highlight + vec3(dynShine * shine * fog * 0.3);" + nl$
    fs$ = fs$ + "    float hi = max(c.r, max(c.g, c.b)), lo = min(c.r, min(c.g, c.b));" + nl$
    fs$ = fs$ + "    float e = smoothstep(0.68, 0.95, hi) * smoothstep(0.45, 0.75, (hi - lo) / (hi + 0.0001)) * neon;  // neon: bright and colourful" + nl$
    fs$ = fs$ + "    if (anim > 0.5 && anim < 1.5) e *= 0.45 + 0.55 * step(0.35, fract(sin(dot(floor(uv * 8.0), vec2(12.9898, 78.233)) + floor(secs * 6.0)) * 43758.5453));" + nl$
    fs$ = fs$ + "    else if (anim > 1.5 && anim < 2.5) e *= 0.55 + 0.45 * sin(uv.x * 12.0 - secs * 4.0);" + nl$
    fs$ = fs$ + "    else if (anim > 2.5) e *= 0.75 + 0.25 * sin(secs * 2.5 + vPos.x + vPos.y);" + nl$
    fs$ = fs$ + "    col = mix(col, c.rgb * 1.3 * (0.35 + 0.65 * fog), clamp(e, 0.0, 0.85));" + nl$
    fs$ = fs$ + "    if (gridAmt > 0.0 && isSprite < 0.5) {  // the editor's grid: a line where each cell (and each wall-high picture) starts" + nl$
    fs$ = fs$ + "        vec3 an = abs(n);" + nl$
    fs$ = fs$ + "        vec2 g2 = an.z > 0.5 ? vPos.xy : (an.x > an.y ? vPos.yz : vPos.xz);" + nl$
    fs$ = fs$ + "        vec2 d = abs(fract(g2 - 0.5) - 0.5) / max(fwidth(g2), vec2(0.0001));" + nl$
    fs$ = fs$ + "        float gl = 1.0 - clamp(min(d.x, d.y) - 1.0, 0.0, 1.0);  // two pixels wide, whatever the distance" + nl$
    fs$ = fs$ + "        col = mix(col, vec3(0.35, 0.9, 1.0), gl * gridAmt);" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    gl_FragColor = vec4(col, 1.0 - reflectAmt);" + nl$
    fs$ = fs$ + "}" + nl$
    glWorldProg = GLSL_program~&(vs$, fs$)
    IF glWorldProg = 0 THEN glShaderError$ = "world: " + GLSL_error$ : EXIT SUB
    glTanLoc = GLSL_attrib&(glWorldProg, "aTangent") : glLightLoc = GLSL_attrib&(glWorldProg, "aLight") : glDynLoc = GLSL_attrib&(glWorldProg, "aDyn")
    GLSL_use glWorldProg ' (the texture is on unit 0, the light tables on 1, 2 and 3)
    GLSL_uniform_1i glWorldProg, "tex", 0 : GLSL_uniform_1i glWorldProg, "litTex", 1
    GLSL_uniform_1i glWorldProg, "infoTex", 2 : GLSL_uniform_1i glWorldProg, "dynTex", 3
    GLSL_use 0

    ' --- Post-processing. All three draw one rectangle over everything
    ' (GLSL_fullscreen), reading pictures at uv (0..1, up from the bottom).
    pv$ = GLSL_filter_vertex$
    fs$ = "#version 120" + nl$ + "uniform sampler2D scene; varying vec2 uv;" + nl$
    fs$ = fs$ + "void main() {  // the bright pass: only what's brighter than 0.55 survives" + nl$
    fs$ = fs$ + "    vec3 c = texture2D(scene, uv).rgb;" + nl$
    fs$ = fs$ + "    gl_FragColor = vec4(c * smoothstep(0.55, 0.95, max(c.r, max(c.g, c.b))), 1.0);" + nl$
    fs$ = fs$ + "}" + nl$
    glBrightProg = GLSL_program~&(pv$, fs$)
    fs$ = "#version 120" + nl$ + "uniform sampler2D src; uniform vec2 stepUV; varying vec2 uv;" + nl$
    fs$ = fs$ + "void main() {  // nine pixels in a line, weighted like a bell curve" + nl$
    fs$ = fs$ + "    vec3 c = texture2D(src, uv).rgb * 0.227;" + nl$
    fs$ = fs$ + "    c += (texture2D(src, uv + stepUV * 1.4).rgb + texture2D(src, uv - stepUV * 1.4).rgb) * 0.316;" + nl$
    fs$ = fs$ + "    c += (texture2D(src, uv + stepUV * 3.3).rgb + texture2D(src, uv - stepUV * 3.3).rgb) * 0.070;" + nl$
    fs$ = fs$ + "    gl_FragColor = vec4(c, 1.0);" + nl$
    fs$ = fs$ + "}" + nl$
    glBlurProg = GLSL_program~&(pv$, fs$)

    fs$ = "#version 120" + nl$
    fs$ = fs$ + "uniform sampler2D scene, bloom, hud, gun;" + nl$
    fs$ = fs$ + "uniform float bloomAmt, fxMode, hurt, rail, secs, hudOn, gunOn;" + nl$
    fs$ = fs$ + "uniform vec4 gunRect;     // the gun: its top left and bottom right, 0..1 from the top left" + nl$
    fs$ = fs$ + "uniform vec3 gunLight;    // ...and the light on it" + nl$
    fs$ = fs$ + "uniform vec4 hudRect;     // where our 4:3 screen is (0..1, from the bottom left): all of it, but for FULL WIDE" + nl$
    fs$ = fs$ + "uniform float sideDim;    // how much to darken the view beside it (in the menu)" + nl$
    fs$ = fs$ + "vec2 onHud(vec2 q) { vec2 h = (q - hudRect.xy) / (hudRect.zw - hudRect.xy); return vec2(h.x, 1.0 - h.y); }  // q on our screen, from its top left" + nl$
    fs$ = fs$ + "float inside(vec2 t) { return step(0.0, t.x) * step(t.x, 1.0) * step(0.0, t.y) * step(t.y, 1.0); }" + nl$
    fs$ = fs$ + "uniform float scanDark, linePx, lineThick;  // scanlines: how dark, how many pixels apart, how thick" + nl$
    fs$ = fs$ + "uniform float glow, passMode;  // phosphor glow: how much; passMode 1 draws just the picture, for it" + nl$
    fs$ = fs$ + "uniform sampler2D glowTex;" + nl$
    fs$ = fs$ + "uniform vec2 res;         // the window's size in pixels" + nl$
    fs$ = fs$ + "uniform vec4 heat[4];     // explosions: where (0..1), how big, how strong" + nl$
    fs$ = fs$ + "varying vec2 uv;" + nl$
    fs$ = fs$ + "vec2 curve(vec2 p) { p = p * 2.0 - 1.0; p *= 1.0 + 0.06 * dot(p.yx, p.yx); return p * 0.5 + 0.5; }" + nl$
    fs$ = fs$ + "vec3 under(vec2 q) {  // the picture at q - view, gun, HUD - for the phosphor glow" + nl$
    fs$ = fs$ + "    vec3 c = texture2D(scene, q).rgb + texture2D(bloom, q).rgb * bloomAmt;" + nl$
    fs$ = fs$ + "    vec2 t = onHud(q); float onScreen = inside(t);" + nl$
    fs$ = fs$ + "    c *= mix(1.0 - sideDim, 1.0, onScreen);" + nl$
    fs$ = fs$ + "    if (gunOn > 0.5) {" + nl$
    fs$ = fs$ + "        vec2 g = (t - gunRect.xy) / (gunRect.zw - gunRect.xy); vec4 k = texture2D(gun, g);" + nl$
    fs$ = fs$ + "        if (g.x >= 0.0 && g.x <= 1.0 && g.y >= 0.0 && g.y <= 1.0) c = k.rgb * gunLight + c * (1.0 - k.a);" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    if (hudOn > 0.5 && onScreen > 0.5) { vec4 h = texture2D(hud, t); c = h.rgb + c * (1.0 - h.a); }" + nl$
    fs$ = fs$ + "    return c;" + nl$
    fs$ = fs$ + "}" + nl$
    fs$ = fs$ + "void main() {" + nl$
    fs$ = fs$ + "    if (passMode > 0.5) { gl_FragColor = vec4(under(uv), 1.0); return; }" + nl$
    fs$ = fs$ + "    vec2 p = uv;" + nl$
    fs$ = fs$ + "    if (fxMode > 1.5) {  // CRT: a curved glass screen" + nl$
    fs$ = fs$ + "        p = curve(uv);" + nl$
    fs$ = fs$ + "        if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) { gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0); return; }" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    vec2 s = p;  // where to read the scene: shimmered by heat" + nl$
    fs$ = fs$ + "    for (int i = 0; i < 4; i++) {" + nl$
    fs$ = fs$ + "        vec2 d = (s - heat[i].xy) * vec2(res.x / res.y, 1.0);" + nl$
    fs$ = fs$ + "        float r = length(d);" + nl$
    fs$ = fs$ + "        if (heat[i].z > 0.0 && r < heat[i].z) s += vec2(sin(s.y * 90.0 + secs * 9.0), cos(s.x * 90.0 + secs * 7.0)) * 0.006 * heat[i].w * (1.0 - r / heat[i].z);" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    vec3 c = vec3(0.0);" + nl$
    fs$ = fs$ + "    if (rail > 0.01) {  // the railgun: a blur zooming out from the middle" + nl$
    fs$ = fs$ + "        for (int i = 0; i < 8; i++) c += texture2D(scene, 0.5 + (s - 0.5) * (1.0 - float(i) * 0.012 * rail)).rgb;" + nl$
    fs$ = fs$ + "        c /= 8.0;" + nl$
    fs$ = fs$ + "    } else c = texture2D(scene, s).rgb;" + nl$
    fs$ = fs$ + "    if (fxMode > 1.5 || hurt > 0.01) {  // colour fringes: on a CRT, and when hurt" + nl$
    fs$ = fs$ + "        vec2 off = (s - 0.5) * (0.004 * step(1.5, fxMode) + 0.012 * hurt);" + nl$
    fs$ = fs$ + "        c.r = texture2D(scene, s + off).r; c.b = texture2D(scene, s - off).b;" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    c += texture2D(bloom, s).rgb * bloomAmt;" + nl$
    fs$ = fs$ + "    float edge = smoothstep(0.3, 0.75, length((p - 0.5) * vec2(1.25, 1.0)));" + nl$
    fs$ = fs$ + "    c = mix(c, vec3(0.75, 0.0, 0.05), hurt * edge * (0.65 + 0.35 * sin(secs * 18.0)));  // hurt: a red pulse at the edges" + nl$
    fs$ = fs$ + "    vec2 hp = onHud(p); float onScreen = inside(hp);  // where this is on our screen (the HUD's)" + nl$
    fs$ = fs$ + "    c *= mix(1.0 - sideDim, 1.0, onScreen);  // (beside it, in the menu: darker, as the menu darkens our screen)" + nl$
    fs$ = fs$ + "    if (gunOn > 0.5) {  // the gun (premultiplied), read from its own picture at the window's size" + nl$
    fs$ = fs$ + "        vec2 g = (hp - gunRect.xy) / (gunRect.zw - gunRect.xy);" + nl$
    fs$ = fs$ + "        vec4 t = texture2D(gun, g);" + nl$
    fs$ = fs$ + "        if (g.x >= 0.0 && g.x <= 1.0 && g.y >= 0.0 && g.y <= 1.0) c = t.rgb * gunLight + c * (1.0 - t.a);  // (in its light)" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    if (hudOn > 0.5 && onScreen > 0.5) { vec4 h = texture2D(hud, hp); c = h.rgb + c * (1.0 - h.a); }  // the HUD (premultiplied)" + nl$
    fs$ = fs$ + "    vec3 halo = vec3(0.0);  // phosphor glow: the picture, blurred" + nl$
    fs$ = fs$ + "    if (glow > 0.001) halo = texture2D(glowTex, p).rgb;" + nl$
    fs$ = fs$ + "    float lit = clamp(dot(halo, vec3(0.3, 0.59, 0.11)) * 2.0, 0.0, 1.0);  // how bright it is round here" + nl$
    fs$ = fs$ + "    if (fxMode > 0.5) {  // scanlines: a dark band lineThick of each linePx pixels, its edges a pixel soft" + nl$
    fs$ = fs$ + "        float d = abs(fract(p.y * res.y / linePx) - 0.5) * linePx;  // pixels from the band's middle" + nl$
    fs$ = fs$ + "        float band = lineThick * linePx * 0.5;  // (half the band; 'half' is a word GLSL keeps for itself)" + nl$
    fs$ = fs$ + "        c *= 1.0 - scanDark * (1.0 - smoothstep(band - 0.5, band + 0.5, d)) * (1.0 - glow * lit * 0.8);  // (bright fills the dark lines)" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    c += halo * halo * glow * 1.2;  // light spreading round bright things (squared: the bright parts, not the dim)" + nl$
    fs$ = fs$ + "    if (fxMode > 1.5) {  // CRT: a shadow mask and a dark rim" + nl$
    fs$ = fs$ + "        float m = mod(gl_FragCoord.x, 3.0);" + nl$
    fs$ = fs$ + "        c *= m < 1.0 ? vec3(1.0, 0.8, 0.8) : (m < 2.0 ? vec3(0.8, 1.0, 0.8) : vec3(0.8, 0.8, 1.0));" + nl$
    fs$ = fs$ + "        vec2 e2 = p * (1.0 - p.yx); c *= clamp(pow(e2.x * e2.y * 20.0, 0.3), 0.0, 1.0) * 1.2;" + nl$
    fs$ = fs$ + "    }" + nl$
    fs$ = fs$ + "    gl_FragColor = vec4(c, 1.0);" + nl$
    fs$ = fs$ + "}" + nl$
    glPostProg = GLSL_program~&(pv$, fs$)
    IF glPostProg = 0 THEN glShaderError$ = "post: " + GLSL_error$
END SUB

' === THE GAME'S SIDE OF THE OPENGL EXTRAS ======================================
' (These run in the game, between frames - not in SUB _GL.)

' Our screen on the window, or not: with OpenGL, SUB _GL draws it itself
' (over the 3D view), so QB64PE's own layer for it is switched off. Only
' changed when it needs to be.
SUB GLScreenLayer(glOn)
    STATIC shown
    IF (glOn <> 0) = shown THEN EXIT SUB
    IF glOn THEN _DISPLAYORDER _GLRENDER ELSE _DISPLAYORDER _GLRENDER , _SOFTWARE
    shown = (glOn <> 0)
END SUB

' In the menu, the game stands still, so no new frame goes to OpenGL - and
' the last one has the settings as they were. So the menu hands over its
' settings itself, into both halves (SUB _GL is drawing one of them), and
' the field of view with them: a change shows behind the menu as you make
' it. (A frame might start with a setting from before and finish with the
' new one - for one frame, behind a menu, nobody will see that.)
SUB GLLiveSettings
    FOR k = 0 TO 1
        FOR i = 1 TO NUM_SETTINGS : glSet(i, k) = setting(i) : NEXT
        IF glZoom(k) > 0 THEN glPlaneLen(k) = fovPlane / glZoom(k)
        glWide(k) = WideView : glSideDim(k) = 0.78 ' (as dark as the menu's own darkening)
    NEXT
END SUB

' Where sector n sits on the route map (ShowRoute): a winding path across
' the screen, left to right and back down - the last one at the bottom
SUB SectorAt(n, x, y)
    SELECT CASE n
        CASE 1 : x = 110 : y = 170
        CASE 2 : x = 270 : y = 140
        CASE 3 : x = 430 : y = 185
        CASE 4 : x = 590 : y = 150
        CASE 5 : x = 700 : y = 270
        CASE 6 : x = 560 : y = 350
        CASE 7 : x = 400 : y = 300
        CASE 8 : x = 240 : y = 370
        CASE 9 : x = 140 : y = 460
        CASE ELSE : x = 400 : y = 470
    END SELECT
END SUB

' One more particle: a kind (PART_), where, which way and how fast (cells a
' frame), for how many frames, its colour (0..1) and size. When all
' MAX_PART are busy, the oldest-placed is reused.
SUB SpawnPart(kind, x, y, z, vx, vy, vz, life, r, g, b, size)
    partNext = partNext MOD MAX_PART + 1
    i = partNext
    partKind(i) = kind : partX(i) = x : partY(i) = y : partZ(i) = z
    partVX(i) = vx : partVY(i) = vy : partVZ(i) = vz
    partLife(i) = life : partMax(i) = life : partR(i) = r : partG(i) = g : partB(i) = b : partSize(i) = size
END SUB

' A spray of sparks at (x, y, z), colour (r, g, b) in 0..255: where a shot
' or a bolt hits
SUB SpawnSparks(x, y, z, count, r, g, b)
    zz = z + FloorAt(x, y) ' (z is over the floor there)
    FOR k = 1 TO count
        SpawnPart PART_SPARK, x, y, zz, (RND - 0.5) * 0.12, (RND - 0.5) * 0.12, 0.015 + RND * 0.06, 16 + INT(RND * 16), r / 255, g / 255, b / 255, 0.03 + RND * 0.02
    NEXT
END SUB

' Embers flying up out of an explosion (size 1: a barrel)
SUB SpawnEmbers(x, y, size)
    FOR k = 1 TO INT(26 * size) + 3
        SpawnPart PART_EMBER, x, y, 0.3 + RND * 0.3, (RND - 0.5) * 0.1, (RND - 0.5) * 0.1, 0.03 + RND * 0.07, 30 + INT(RND * 40), 1, 0.45 + RND * 0.35, 0.1, 0.04 + RND * 0.04
    NEXT
END SUB

' Dust motes drifting in the light round you, at (px, py): faint, slow,
' tinted by the light of the cell they start in - there's always a few.
' With LIGHT SHAFTS on, half of them start in a beam near you, so the beams
' are full of dust (a light picked at random: if it has no beam, or it's
' too far, the mote goes anywhere instead).
SUB SpawnDust(px, py)
    IF dustCount >= 80 OR RND > 0.55 THEN EXIT SUB
    IF setting(SET_SHAFTS) AND RND < 0.5 AND numLights > 0 THEN
        l = INT(RND * numLights) + 1
        IF ShaftOf%(l) AND (lightX(l) - px) ^ 2 + (lightY(l) - py) ^ 2 < 64 THEN
            z = 0.05 + RND * 0.9 : a = RND * 6.2832
            spread = SQR(RND) * (SHAFT_TOP + (SHAFT_FOOT - SHAFT_TOP) * (1 - z)) * 0.9
            x = lightX(l) + COS(a) * spread : y = lightY(l) + SIN(a) * spread
            cx = INT(x) : cy = INT(y)
            IF x >= 1 AND y >= 1 AND x < MAP_SIZE - 1 AND y < MAP_SIZE - 1 THEN
                IF Walkable%(x, y) THEN
                    SpawnPart PART_DUST, x, y, z, (RND - 0.5) * 0.002, (RND - 0.5) * 0.002, (RND - 0.5) * 0.001, 220 + INT(RND * 160), litR(cx, cy) / 2200, litG(cx, cy) / 2200, litB(cx, cy) / 2200, 0.018
                    EXIT SUB
                END IF
            END IF
        END IF
    END IF
    x = px + (RND - 0.5) * 9 : y = py + (RND - 0.5) * 9
    IF x < 1 OR y < 1 OR x >= MAP_SIZE - 1 OR y >= MAP_SIZE - 1 THEN EXIT SUB ' (inside the map...)
    IF NOT Walkable%(x, y) THEN EXIT SUB ' (...and not in a wall)
    cx = INT(x) : cy = INT(y)
    SpawnPart PART_DUST, x, y, 0.05 + RND * 0.9, (RND - 0.5) * 0.003, (RND - 0.5) * 0.003, (RND - 0.5) * 0.002, 200 + INT(RND * 150), litR(cx, cy) / 2200, litG(cx, cy) / 2200, litB(cx, cy) / 2200, 0.018
END SUB

' Move every particle a frame on. Sparks and embers fall (embers slowly,
' they're hot and light) and bounce off the floor and walls, losing speed;
' dust drifts - nudged a little at random each frame, and slowed a little
' (the air holds it back), so a push (StirDust, or you) dies away. You're
' at (px, py) and just moved (mvx, mvy): dust within WAKE_REACH of you is
' pushed aside, dragged along a bit behind you, and lifted - your wake.
SUB UpdateParticles(px, py, mvx, mvy)
    FOR d = 1 TO MAX_DECALS : IF decalHeat(d) > 0 THEN decalHeat(d) = decalHeat(d) - 1
    NEXT ' (fresh marks cool)
    dustCount = 0
    speed = SQR(mvx * mvx + mvy * mvy) : IF speed > 0.3 THEN speed = 0 ' (a jump - a new level, a loaded game - isn't a step)
    FOR i = 1 TO MAX_PART
        IF partLife(i) > 0 THEN
            partLife(i) = partLife(i) - 1
            IF partKind(i) = PART_DUST THEN
                dustCount = dustCount + 1
                partVX(i) = partVX(i) * 0.97 + (RND - 0.5) * 0.0007 : partVY(i) = partVY(i) * 0.97 + (RND - 0.5) * 0.0007
                partVZ(i) = partVZ(i) * 0.97 + (RND - 0.5) * 0.0003
                IF speed > 0.004 THEN
                    ddx = partX(i) - px : ddy = partY(i) - py : d = SQR(ddx * ddx + ddy * ddy)
                    IF d < WAKE_REACH AND d > 0.01 THEN
                        w = (1 - d / WAKE_REACH) ^ 2
                        partVX(i) = partVX(i) + (ddx / d * speed * 0.25 + mvx * 0.2) * w
                        partVY(i) = partVY(i) + (ddy / d * speed * 0.25 + mvy * 0.2) * w
                        partVZ(i) = partVZ(i) + speed * 0.06 * w * (RND - 0.25)
                    END IF
                END IF
                v = SQR(partVX(i) ^ 2 + partVY(i) ^ 2 + partVZ(i) ^ 2)
                IF v > 0.06 THEN partVX(i) = partVX(i) * 0.06 / v : partVY(i) = partVY(i) * 0.06 / v : partVZ(i) = partVZ(i) * 0.06 / v
            ELSEIF partKind(i) = PART_EMBER THEN
                partVZ(i) = partVZ(i) - 0.0015
            ELSEIF partKind(i) = PART_FLAME THEN ' (hot: rising faster, wavering, shrinking)
                partVZ(i) = partVZ(i) + 0.0008 : partVX(i) = partVX(i) * 0.94 + (RND - 0.5) * 0.004 : partVY(i) = partVY(i) * 0.94 + (RND - 0.5) * 0.004
                partSize(i) = partSize(i) * 0.97
            ELSEIF partKind(i) = PART_SMOKE THEN ' (rising slowly, drifting, spreading out)
                partVZ(i) = partVZ(i) * 0.99 + 0.0001 : partVX(i) = partVX(i) * 0.98 + (RND - 0.5) * 0.001 : partVY(i) = partVY(i) * 0.98 + (RND - 0.5) * 0.001
                partSize(i) = partSize(i) + 0.003
            ELSEIF partKind(i) = PART_ARC THEN ' (still)
            ELSE
                partVZ(i) = partVZ(i) - 0.0045
            END IF
            partX(i) = partX(i) + partVX(i) : partY(i) = partY(i) + partVY(i) : partZ(i) = partZ(i) + partVZ(i)
            IF partX(i) < 1 OR partY(i) < 1 OR partX(i) >= MAP_SIZE - 1 OR partY(i) >= MAP_SIZE - 1 THEN partLife(i) = 0 : GOTO NextPart ' (off the map: gone)
            pfz = FloorAt(partX(i), partY(i)) : pcz = CeilAt(partX(i), partY(i))
            IF partZ(i) < pfz + 0.01 THEN partZ(i) = pfz + 0.01 : partVZ(i) = -partVZ(i) * 0.35 : partVX(i) = partVX(i) * 0.7 : partVY(i) = partVY(i) * 0.7
            IF partZ(i) > pcz - 0.02 THEN partZ(i) = pcz - 0.02 : partVZ(i) = -partVZ(i) * 0.3
            IF SolidAt(partX(i), partY(i)) THEN ' Back out, and bounce
                partX(i) = partX(i) - partVX(i) : partY(i) = partY(i) - partVY(i)
                partVX(i) = -partVX(i) * 0.4 : partVY(i) = -partVY(i) * 0.4
            END IF
        END IF
        NextPart:
    NEXT
END SUB

' One more decal (DECALS): at (x, y, z) on a surface facing (nx, ny, nz),
' size across, glowing hot for its first DECAL_HEAT frames. When all
' MAX_DECALS are taken, the oldest goes.
SUB AddDecal(x, y, z, nx, ny, nz, size)
    decalNext = decalNext MOD MAX_DECALS + 1 : d = decalNext
    decalX(d) = x : decalY(d) = y : decalZ(d) = z : decalNX(d) = nx : decalNY(d) = ny : decalNZ(d) = nz
    decalSize(d) = size : decalHeat(d) = DECAL_HEAT : decalOn(d) = -1
END SUB

' Where a shot lands: (x, y, z), having come along (dx, dy) (one cell
' long), on the wall (surface 0), the ceiling (1) or the floor (2) -
' leave a mark size across. On a wall, which way it faces: the hit is on
' a cell's edge, and the nearer of the two grid lines (x or y a whole
' number) says which edge - facing back the way the shot came. Not on
' doors (they move) - and on a diagonal wall, just facing back at you.
' A shot into the ceiling at one of the level's lamps breaks it.
SUB ShotMark(x, y, z, dx, dy, surface, size)
    SELECT CASE surface
        CASE 1
            cx = INT(x) : cy = INT(y)
            IF cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN
                l = shaftCell(cx, cy)
                IF l THEN
                    IF NOT lightBroken(l) AND ABS(x - lightX(l)) < 0.32 AND ABS(y - lightY(l)) < 0.32 THEN BreakLight l, -1 : EXIT SUB
                END IF
            END IF
            AddDecal x, y, 0.999, 0, 0, -1, size
        CASE 2
            AddDecal x, y, 0.001, 0, 0, 1, size
        CASE ELSE
            bx = INT(x + dx * 0.02) : by = INT(y + dy * 0.02) ' (the cell it went into)
            IF bx < 0 OR by < 0 OR bx >= MAP_SIZE OR by >= MAP_SIZE THEN EXIT SUB
            IF worldMap(bx, by) = 2 THEN EXIT SUB
            IF diagCorner(bx, by) THEN
                nx = -dx : ny = -dy
            ELSEIF ABS(x - INT(x + 0.5)) < ABS(y - INT(y + 0.5)) THEN
                nx = -SGN(dx) : ny = 0
            ELSE
                nx = 0 : ny = -SGN(dy)
            END IF
            AddDecal x, y, z, nx, ny, 0, size
    END SELECT
END SUB

' Ceiling lamp l, shot out: its light goes off for good (UpdateLight), its
' beam with it; its picture goes dark and cracked (T_LAMPOFF - the software
' renderer's ceiling; OpenGL's ceiling is built once a level, so a dark
' mark goes over it) - and if loud, glass and sparks rain down, with a
' crash. (Not loud: loading a game where it was already broken.)
SUB BreakLight(l, loud)
    lightBroken(l) = -1
    cx = INT(lightX(l)) : cy = INT(lightY(l))
    IF cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN ceilTex(cx, cy) = T_LAMPOFF
    AddDecal lightX(l), lightY(l), 0.999, 0, 0, -1, 0.75 : decalHeat(decalNext) = 0
    IF loud THEN
        SpawnSparks lightX(l), lightY(l), 0.95, 24, 255, 240, 200
        SpawnSparks lightX(l), lightY(l), 0.95, 16, 160, 200, 255 ' (glass)
        PlaySfx decoBreakSnd&(2), 0.9
    END IF
END SUB

' Blow the dust about: a shot from (x, y) going (dx, dy) pushes the dust
' along its line, up to reach cells away; an explosion at (x, y) - dx and
' dy both 0 - pushes it out all round, up to reach. strength is the push
' (cells a frame) right at the start, less further out.
SUB StirDust(x, y, dx, dy, reach, strength)
    FOR i = 1 TO MAX_PART
        IF partLife(i) > 0 AND partKind(i) = PART_DUST THEN
            ox = partX(i) - x : oy = partY(i) - y
            IF dx = 0 AND dy = 0 THEN ' Out all round
                d = SQR(ox * ox + oy * oy)
                IF d < reach AND d > 0.01 THEN
                    w = 1 - d / reach
                    partVX(i) = partVX(i) + ox / d * strength * w : partVY(i) = partVY(i) + oy / d * strength * w
                    partVZ(i) = partVZ(i) + strength * 0.3 * w
                END IF
            ELSE ' Along the shot: how far along it, and how far to its side
                along = ox * dx + oy * dy : across = ox * dy - oy * dx
                IF along > 0 AND along < reach AND ABS(across) < 0.3 + along * 0.12 THEN
                    w = 1 - along / reach
                    partVX(i) = partVX(i) + (dx + dy * SGN(across) * 0.4) * strength * w
                    partVY(i) = partVY(i) + (dy - dx * SGN(across) * 0.4) * strength * w
                END IF
            END IF
        END IF
    NEXT
END SUB

' LIGHT SHAFTS: work out, once per level, which lights have a beam - the
' level's own (a lamp or terminal's light is its glow), standing in an
' open cell (not a door, a wall or a diagonal) - into shaftCell(). Each
' one hangs from a lamp: its cell's ceiling is the lamp's picture (T_LAMP),
' so a light (and its beam) comes from somewhere - with the cell's light
' falling on it, it glows its light's colour.
SUB BuildShafts
    FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE : shaftCell(x, y) = 0 : NEXT : NEXT
    FOR l = 1 TO numLights
        cx = INT(lightX(l)) : cy = INT(lightY(l))
        IF lightDeco(l) = 0 AND cx >= 0 AND cy >= 0 AND cx < MAP_SIZE AND cy < MAP_SIZE THEN
            IF worldMap(cx, cy) <= 0 AND diagCorner(cx, cy) = 0 THEN
                shaftCell(cx, cy) = l : ceilTex(cx, cy) = T_LAMP : ceilSplit(cx, cy) = 0
            END IF
        END IF
    NEXT
END SUB

' Does light l have a beam?
FUNCTION ShaftOf%(l)
    IF l < 1 OR l > numLights THEN EXIT FUNCTION
    cx = INT(lightX(l)) : cy = INT(lightY(l))
    IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT FUNCTION
    ShaftOf% = (shaftCell(cx, cy) = l)
END FUNCTION

' How far inside a beam (x, y, z) is: 0 outside, up to 1 in the middle of
' it - times how bright its light is this frame - and which light's beam
' that is (l). A beam is narrower than a cell, so only the cell's own and
' its neighbours' beams can reach.
FUNCTION InShaft(x, y, z, l)
    l = 0 : best = 0 : cx = INT(x) : cy = INT(y)
    r = SHAFT_TOP + (SHAFT_FOOT - SHAFT_TOP) * (1 - z) ' (the beam's width at this height)
    FOR ny = cy - 1 TO cy + 1 : FOR nx = cx - 1 TO cx + 1
        IF nx >= 0 AND ny >= 0 AND nx < MAP_SIZE AND ny < MAP_SIZE THEN
            k = shaftCell(nx, ny)
            IF k THEN
                d = SQR((x - lightX(k)) ^ 2 + (y - lightY(k)) ^ 2)
                IF d < r THEN
                    f = (1 - d / r) * lightNow(k)
                    IF f > best THEN best = f : l = k
                END IF
            END IF
        END IF
    NEXT : NEXT
    InShaft = best
END FUNCTION

' Looking up or down, the view's top or bottom corners see further to the
' sides than the rays (chapter 15) went - the picture is a tilted window,
' and a tilted window's far corners reach wider. So with the view tilted,
' more rays are cast, across that wider angle, only to mark the cells they
' pass (glSeen) for OpenGL to draw. (px, py) is you, (dx, dy) your
' direction, planeLen the camera plane's length and zoom the zoom.
SUB GLMarkWide(px, py, dx, dy, planeLen, zoom)
    tanV = 1 / (2 * zoom) : p = ABS(pitch)
    denom = COS(p) - SIN(p) * tanV : IF denom < 0.25 THEN denom = 0.25
    wide = planeLen / denom
    FOR r = 0 TO 159
        camX = r / 159 * 2 - 1
        rayX = dx + dy * wide * camX : rayY = dy - dx * wide * camX
        mapX = INT(px) : mapY = INT(py)
        deltaX = ABS(1 / (rayX + 0.000001)) : deltaY = ABS(1 / (rayY + 0.000001))
        IF rayX < 0 THEN stepX = -1 : sideX = (px - mapX) * deltaX ELSE stepX = 1 : sideX = (mapX + 1 - px) * deltaX
        IF rayY < 0 THEN stepY = -1 : sideY = (py - mapY) * deltaY ELSE stepY = 1 : sideY = (mapY + 1 - py) * deltaY
        FOR hop = 1 TO 64
            IF sideX < sideY THEN sideX = sideX + deltaX : mapX = mapX + stepX ELSE sideY = sideY + deltaY : mapY = mapY + stepY
            IF mapX < 0 OR mapY < 0 OR mapX >= MAP_SIZE OR mapY >= MAP_SIZE THEN EXIT FOR
            glSeen(mapX, mapY, glWrite) = glFrameNo
            v = worldMap(mapX, mapY)
            IF v > 0 AND v <> 2 AND diagCorner(mapX, mapY) = 0 THEN EXIT FOR ' A wall: stop
            IF v = 2 THEN IF doorOpen(mapX, mapY) < 0.5 THEN EXIT FOR ' A shut door
        NEXT
    NEXT
END SUB

' Hand OpenGL this frame's extras (chapter 17): you're at (px, py) facing
' (dx, dy), muzzle is the muzzle flash's frames left.
'
' MOVING LIGHTS: your muzzle flash, each explosion and each bolt is a
' light - the same ones AddGlow adds to cells for the software renderer -
' and the GL_DYN nearest you are handed over, with which cells each one
' reaches (glDynReach), so walls still stop it. That's found by "flood
' fill": start at the light's cell, spread to each open neighbour (not
' through walls or shut doors), and theirs, until the light's radius runs
' out. Light spreads round a corner a little this way - but a fill touches
' each cell once, where tracing a line to every cell (LightReaches) did a
' few thousand wall checks a frame.
'
' PARTICLES: the live ones, fading as they die (dust fades in and out).
' HEAT: the explosions, for the heat shimmer.
SUB GLHandOverExtras(px, py, dx, dy, muzzle)
    DIM candX(40), candY(40), candZ(40), candRad(40), candR(40), candG(40), candB(40), candD(40)
    w = glWrite : n = 0
    IF muzzle > 0 THEN
        n = n + 1 : candX(n) = px + dx * 0.4 : candY(n) = py + dy * 0.4 : candZ(n) = 0.5 : candRad(n) = 5
        candR(n) = 70 * muzzle : candG(n) = 40 * muzzle : candB(n) = 40 * muzzle
    END IF
    nHeat = 0
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 AND n < 40 THEN
            f = blastTime(i) / BLAST_FRAMES * blastSize(i)
            n = n + 1 : candX(n) = blastX(i) : candY(n) = blastY(i) : candZ(n) = 0.45 : candRad(n) = 2 + 5 * blastSize(i)
            candR(n) = 400 * f : candG(n) = 220 * f : candB(n) = 90 * f
            IF nHeat < GL_HEAT THEN nHeat = nHeat + 1 : glHeatX(nHeat, w) = blastX(i) : glHeatY(nHeat, w) = blastY(i) : glHeatAmt(nHeat, w) = blastTime(i) / BLAST_FRAMES
        END IF
    NEXT
    FOR i = 1 TO numEvents ' A lit trap lights the room: orange flames, flickering blue arcs
        IF evGlow(i) > 0 AND n < 40 THEN
            g = evGlow(i) : n = n + 1
            candX(n) = (evX0(i) + evX1(i) + 1) / 2 : candY(n) = (evY0(i) + evY1(i) + 1) / 2 : candZ(n) = 0.3
            candRad(n) = MaxOf(evX1(i) - evX0(i), evY1(i) - evY0(i)) / 2 + 2.5
            IF evType(i) = EV_FIRETRAP THEN
                fl = g * (0.85 + 0.15 * RND) : candR(n) = 380 * fl : candG(n) = 160 * fl : candB(n) = 40 * fl
                IF g >= 1 AND nHeat < GL_HEAT THEN nHeat = nHeat + 1 : glHeatX(nHeat, w) = candX(n) : glHeatY(nHeat, w) = candY(n) : glHeatAmt(nHeat, w) = 0.5
            ELSE
                fl = g * (0.4 + 0.6 * RND) : candR(n) = 90 * fl : candG(n) = 170 * fl : candB(n) = 330 * fl
            END IF
        END IF
    NEXT
    glNumHeat(w) = nHeat
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) AND n < 40 THEN
            n = n + 1 : candX(n) = boltX(i) : candY(n) = boltY(i) : candZ(n) = 0.49 : candRad(n) = 2.5
            candR(n) = 160 : candG(n) = 40 : candB(n) = 170
        END IF
    NEXT
    FOR i = 1 TO n : candD(i) = (candX(i) - px) ^ 2 + (candY(i) - py) ^ 2 : NEXT
    FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE : FOR k = 1 TO GL_DYN : glDynReach(x, y, k, w) = 0 : NEXT : NEXT : NEXT
    kept = 0
    DO WHILE kept < GL_DYN AND kept < n ' The nearest, one at a time
        best = 0
        FOR i = 1 TO n
            IF candD(i) >= 0 THEN
                IF best = 0 THEN
                    best = i
                ELSEIF candD(i) < candD(best) THEN
                    best = i
                END IF
            END IF
        NEXT
        IF best = 0 THEN EXIT DO
        kept = kept + 1 : candD(best) = -1
        glDynX(kept, w) = candX(best) : glDynY(kept, w) = candY(best) : glDynZ(kept, w) = candZ(best) : glDynRad(kept, w) = candRad(best)
        glDynR(kept, w) = candR(best) : glDynG(kept, w) = candG(best) : glDynB(kept, w) = candB(best)
        rad = candRad(best) : lx = candX(best) : ly = candY(best)
        FloodLight lx, ly, rad, kept, w
    LOOP
    glNumDyn(w) = kept

    n = 0 : shafts = setting(SET_SHAFTS) <> 0
    FOR i = 1 TO MAX_PART
        IF partLife(i) > 0 THEN
            n = n + 1 : f = partLife(i) / partMax(i)
            r = partR(i) : g = partG(i) : bl = partB(i)
            IF partKind(i) = PART_DUST THEN
                f = SIN(f * 3.14159)
                IF shafts THEN ' Dust in a beam catches its light, and shines
                    lit = InShaft(partX(i), partY(i), partZ(i), l)
                    IF lit > 0 THEN r = r + lightR(l) * lit / 450 : g = g + lightG(l) * lit / 450 : bl = bl + lightB(l) * lit / 450
                END IF
            END IF
            glPartX(n, w) = partX(i) : glPartY(n, w) = partY(i) : glPartZ(n, w) = partZ(i) : glPartSize(n, w) = partSize(i)
            glPartR(n, w) = r * f : glPartG(n, w) = g * f : glPartB(n, w) = bl * f
        END IF
    NEXT
    glNumPart(w) = n

    ' DECALS: all of them (they're few, and cheap to draw)
    n = 0
    FOR i = 1 TO MAX_DECALS
        IF decalOn(i) THEN
            n = n + 1 : glDecX(n, w) = decalX(i) : glDecY(n, w) = decalY(i) : glDecZ(n, w) = decalZ(i)
            glDecNX(n, w) = decalNX(i) : glDecNY(n, w) = decalNY(i) : glDecNZ(n, w) = decalNZ(i)
            glDecSize(n, w) = decalSize(i) : glDecHeat(n, w) = decalHeat(i) / DECAL_HEAT
        END IF
    NEXT
    glNumDecal(w) = n

    ' LIGHT SHAFTS: every beam within 16 cells, as bright as its light is
    ' this frame (so they flicker, pulse and strobe with it)
    n = 0
    IF shafts THEN
        FOR l = 1 TO numLights
            IF lightNow(l) > 0 AND ShaftOf%(l) THEN
                IF (lightX(l) - px) ^ 2 + (lightY(l) - py) ^ 2 < 256 THEN
                    n = n + 1 : glShaftX(n, w) = lightX(l) : glShaftY(n, w) = lightY(l) : glShaftPh(n, w) = lightPhase(l)
                    glShaftR(n, w) = lightR(l) * lightNow(l) / 256 : glShaftG(n, w) = lightG(l) * lightNow(l) / 256 : glShaftB(n, w) = lightB(l) * lightNow(l) / 256
                END IF
            END IF
        NEXT
    END IF
    glNumShaft(w) = n
END SUB

' Mark the cells moving light k (at (lx, ly), radius rad) reaches, in half
' w of glDynReach: a flood fill out from its cell through open cells, up to
' rad + 1 steps and within rad (and a bit) as the crow flies
SUB FloodLight(lx, ly, rad, k, w)
    cx = INT(lx) : cy = INT(ly)
    IF cx < 0 OR cy < 0 OR cx >= MAP_SIZE OR cy >= MAP_SIZE THEN EXIT SUB
    fillStamp = fillStamp + 1
    head = 0 : tail = 1 : fillX(0) = cx : fillY(0) = cy : fillD(0) = 0 : fillSeen(cx, cy) = fillStamp
    reach2 = (rad + 0.8) ^ 2
    DO WHILE head < tail
        x = fillX(head) : y = fillY(head) : d = fillD(head) : head = head + 1
        glDynReach(x, y, k, w) = 1
        IF d <= rad THEN
            FOR side = 1 TO 4
                SELECT CASE side
                    CASE 1 : nx = x - 1 : ny = y
                    CASE 2 : nx = x + 1 : ny = y
                    CASE 3 : nx = x : ny = y - 1
                    CASE ELSE : nx = x : ny = y + 1
                END SELECT
                IF nx >= 0 AND ny >= 0 AND nx < MAP_SIZE AND ny < MAP_SIZE THEN
                    IF fillSeen(nx, ny) <> fillStamp THEN
                        fillSeen(nx, ny) = fillStamp
                        v = worldMap(nx, ny)
                        lightPasses = (v <= 0 OR diagCorner(nx, ny) <> 0)
                        IF v = 2 THEN lightPasses = (doorOpen(nx, ny) >= 0.5)
                        IF lightPasses AND (nx + 0.5 - lx) ^ 2 + (ny + 0.5 - ly) ^ 2 < reach2 AND tail <= MAP_SIZE * MAP_SIZE THEN
                            fillX(tail) = nx : fillY(tail) = ny : fillD(tail) = d + 1 : tail = tail + 1
                        END IF
                    END IF
                END IF
            NEXT
        END IF
    LOOP
END SUB

'$INCLUDE:'lib/glsl/GLSL.BM'
