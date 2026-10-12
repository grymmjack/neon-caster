'=============================================================================
' NEON-CASTER - a little first-person shooter in QB64PE, written to learn from
'=============================================================================
'
' This is a whole game in one file of plain QB64PE: four levels, five kinds
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
'   Click or Ctrl  fire                 Space     open doors, use the exit
'   1-4 or wheel   choose a gun         Esc       the menu (pause, save,
'   Right button   hold to aim down                load, settings, exit)
'                  the sights (zoom)    F5 / F9   quick save / quick load
'   Tab            the full-screen map (all of it once you find the map)
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
'     TEX_       TEXture: TEX_SIZE, how big each one is (64)    (chapter 5)
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
' QB64_GJ_LIB, cloned next to this repository: its .BI here, its .BM at the
' very end of the file.
'$INCLUDE:'../../../QB64_GJ_LIB/GLSL/GLSL.BI'
_TITLE "NEON-CASTER"
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
CONST PLAYER_RADIUS = 0.3 ' Your body's half-width, so the camera can't touch a wall
' worldMap: 0 floor, 2 door; walls 1 (#), 3 (N), 4 (C), 5 (K), 6 (P), 7 (G):
' six kinds of wall, whose textures each level picks (see chapter 22)
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
' Doors: how far open (0 shut .. 1 open), which keycard opens it (0 any,
' 1 red, 2 blue, 3 yellow), and what kind it is (DOOR_ constants below)
DIM SHARED doorOpen(MAP_SIZE, MAP_SIZE) AS SINGLE
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
CONST NUM_LEVELS = 4 ' NUM_ = how many there are

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
CONST MAX_MON = 64, MON_TYPES = 5
CONST MON_SIGHT = 14
CONST MON_DYING = 24
DIM SHARED monsterX(MAX_MON) AS SINGLE, monsterY(MAX_MON) AS SINGLE, monsterType(MAX_MON) AS INTEGER
DIM SHARED monsterHP(MAX_MON) AS INTEGER, monsterState(MAX_MON) AS INTEGER
DIM SHARED monsterTimer(MAX_MON) AS INTEGER, monsterHurt(MAX_MON) AS INTEGER
DIM SHARED numMonsters AS INTEGER
' A second set of arrays describes each TYPE of monster, numbered 1-5 (the
' "mtype" arrays, filled in chapter 6). Per type: hit points, speed (tiles a frame; you walk 0.12), height (of a
' wall), hover height and bob, attack reach, damage (min + random), frames
' between attacks, sprite slots, whether it shoots bolts, and sounds
DIM SHARED mtypeHP(MON_TYPES), mtypeSpeed(MON_TYPES), mtypeScale(MON_TYPES), mtypeLift(MON_TYPES), mtypeBob(MON_TYPES)
DIM SHARED mtypeReach(MON_TYPES), mtypeDamage(MON_TYPES), mtypeDamageRnd(MON_TYPES), mtypeCooldown(MON_TYPES)
DIM SHARED mtypeSprite(MON_TYPES), mtypeName$(MON_TYPES), mtypeRanged(MON_TYPES)
DIM SHARED mtypeAlertSnd&(MON_TYPES), mtypeAttackSnd&(MON_TYPES), mtypeHitSnd&(MON_TYPES), mtypeDieSnd&(MON_TYPES)
' GUNNER_ = gunners (and sentries) like to keep between GUNNER_NEAR and
' GUNNER_FAR cells away from you
CONST GUNNER_NEAR = 3.5, GUNNER_FAR = 7

' --- Energy bolts (what gunners and sentries shoot): a position and a
' direction each, moved a little every frame ---
' (BOLT_SPEED is in cells a frame - you walk at 0.12)
CONST MAX_BOLTS = 32, BOLT_SPEED = 0.14
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
DIM SHARED gunSnd&(NUM_GUNS), gunImg&(NUM_GUNS), gunMuzzleX(NUM_GUNS), gunMuzzleY(NUM_GUNS), gunScale(NUM_GUNS)
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
CONST TEST_ALL_GUNS = -1
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
' SPR_ = SPRite picture storage: each picture is up to SPR_TEX pixels square,
' and there are SPR_SLOTS of them. A "slot" is just a picture's number - the
' third index of spriteTex(x, y, slot):
'   1-3 keycards, 4 medkit, 5 cells, 6 shells, 7 scatter gun, 8 repeater,
'   9/10 drone (/hit), 11/12 gunner, 13/14 heavy, 15/16 crawler, 17/18 sentry,
'   19 bolt, 20-23 decorations (barrel, lamp, plant, terminal), 24 explosion,
'   25 armour, 26 big medkit, 27 railgun, 28 map
CONST SPR_TEX = 64, SPR_SLOTS = 28
' S_ = Sprite slot: names for a few of those numbers. S_DECO + kind is a
' decoration's slot (barrel = S_DECO + 1 = 20, and so on).
CONST S_BOLT = 19, S_DECO = 19, S_BLAST = 24
' How tall pickups stand (in walls): keycards, other pickups, guns
CONST CARD_SCALE = 0.3, ITEM_SCALE = 0.3, GUN_ITEM_SCALE = 0.45
DIM SHARED spriteTex(SPR_TEX - 1, SPR_TEX-1, SPR_SLOTS) AS _UNSIGNED LONG, spriteSize(SPR_SLOTS) AS INTEGER
DIM SHARED cardImg&(3) ' The keycards as images, for the HUD
' The draw list: every sprite to draw this frame (chapter 16)
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS + MAX_DECO + MAX_BLASTS
DIM drawX(MAX_DRAW) AS SINGLE, drawY(MAX_DRAW) AS SINGLE, drawDistSq(MAX_DRAW) AS SINGLE
DIM drawSprite(MAX_DRAW) AS INTEGER, drawScale(MAX_DRAW) AS SINGLE, drawLift(MAX_DRAW) AS SINGLE
DIM drawSquash(MAX_DRAW) AS SINGLE, drawMinShade(MAX_DRAW) AS INTEGER, drawOrder(MAX_DRAW) AS INTEGER

' --- The 3D view: drawn at half size, then stretched 2x onto the window ---
' RENDER_ = the size of the 3D view in pixels (W = width, H = height);
' TEX_SIZE = every texture is 64 x 64 pixels
CONST RENDER_W = 400, RENDER_H = 300, TEX_SIZE = 128
' T_ = Texture slot: which picture in texture(x, y, slot). The slots are:
'   1-6 the level's six walls (# N C K P G), 7 sliding door, 8-10 key doors,
'   11 shutter, 12 split door, 13 exit, 14-17 the level's four floors,
'   18-19 its two ceilings
' T_DOORK + card is a key door (8 red, 9 blue, 10 yellow); T_FLOOR + n is
' floor n, and T_CEIL + n ceiling n; T_SLOTS is how many slots there are.
CONST T_DOOR = 7, T_DOORK = 7
CONST T_SHUTTER = 11, T_SPLIT = 12, T_EXIT = 13
CONST T_FLOOR = 13, T_CEIL = 17
CONST T_SLOTS = 19
DIM SHARED texture(TEX_SIZE - 1, TEX_SIZE-1, T_SLOTS) AS _UNSIGNED LONG
' For each worldMap wall value: its texture slot, and its colour on the minimap
DIM SHARED wallTexSlot(7) AS INTEGER, wallMapColor(7) AS _UNSIGNED LONG
wallTexSlot(1) = 1 : wallTexSlot(3) = 2 : wallTexSlot(4) = 3 : wallTexSlot(5) = 4 : wallTexSlot(6) = 5 : wallTexSlot(7) = 6
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
CONST GL_DYN = 4, MAX_PART = 400, GL_HEAT = 4
DIM SHARED glReady AS INTEGER, glBuf AS INTEGER, glFrameNo AS LONG, glMode AS INTEGER
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
' (texture slots 1-19, then sprite slots after them), which texture version
' it has, the cells it's drawing, the camera and light it's drawing with,
' the camera as a matrix (chapter 24), and how long it took (for SHOW FPS)
' (one more texture name after the sprites: GL_GLOW_TEX, the glows' soft
' round spot)
CONST GL_GLOW_TEX = T_SLOTS + SPR_SLOTS + 1
DIM SHARED glTexName(GL_GLOW_TEX) AS _UNSIGNED LONG, glTexDone AS LONG
DIM SHARED glUpload(TEX_SIZE * TEX_SIZE - 1) AS _UNSIGNED LONG ' (a picture on its way to the card)
' The world shader (chapter 24): the program, where its uniforms and
' attributes are, whether we've tried to build it, and why it failed (if)
DIM SHARED glWorldProg AS _UNSIGNED LONG, glWorldTried AS INTEGER, glShaderOn AS INTEGER, glShaderError$
DIM SHARED glTanLoc AS LONG, glLightLoc AS LONG, glDynLoc AS LONG
' ...the post-processing shaders and render targets, and how this frame is
' going: post-processing or not, the mirror image drawn, the floor pass on
DIM SHARED glPostProg AS _UNSIGNED LONG, glBrightProg AS _UNSIGNED LONG, glBlurProg AS _UNSIGNED LONG
DIM SHARED glTargScene AS LONG, glTargA AS LONG, glTargB AS LONG, glTargRetro AS INTEGER
DIM SHARED glPost AS INTEGER, glReflecting AS INTEGER, glFloorPass AS INTEGER, glNeonOn AS INTEGER
' ...the WORLD MESH (GLBuildMesh): every floor, ceiling and wall face of
' the level, built once and kept in graphics memory (glMeshBuf), sorted by
' kind (0 floors, 1 ceilings, 2 walls) and texture, glMeshFirst/Count saying
' where each kind-and-texture run is; the corners while it's being built
' (glMB...); the doors (they move, so they're drawn each frame); the light
' tables' textures; and whether corners are lit from the tables (cellLit)
CONST MESH_MAX = 60000
DIM SHARED glMeshBuf AS _UNSIGNED LONG, glMeshN AS LONG, glMeshBuilding AS INTEGER, glMeshKind AS INTEGER
DIM SHARED glMeshFirst(2, GL_GLOW_TEX) AS LONG, glMeshCount(2, GL_GLOW_TEX) AS LONG
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
DIM SHARED glSet(40, 1), glPitch(1)
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
CONST PART_SPARK = 1, PART_EMBER = 2, PART_DUST = 3
DIM SHARED partX(MAX_PART), partY(MAX_PART), partZ(MAX_PART), partVX(MAX_PART), partVY(MAX_PART), partVZ(MAX_PART)
DIM SHARED partLife(MAX_PART) AS INTEGER, partMax(MAX_PART) AS INTEGER, partR(MAX_PART), partG(MAX_PART), partB(MAX_PART)
DIM SHARED partSize(MAX_PART), partKind(MAX_PART) AS INTEGER, partNext AS INTEGER, dustCount AS INTEGER
' Each texture slot's file name (LoadTex), so OpenGL can tell what a
' texture is - a floor that should shine, a screen that should flicker
DIM SHARED texName$(T_SLOTS)
DIM SHARED pitch ' (looking up and down, chapter 8 - OpenGL only)

'-----------------------------------------------------------------------------
' CHAPTER 6: LOADING THE PICTURES AND SOUNDS
'-----------------------------------------------------------------------------
' Every picture is a PNG in the neon-caster/ folder. LoadTex and LoadSprite
' (chapter 23) open one with _LOADIMAGE and copy its colours into the
' texture() or spriteTex() array. The level's own walls, floors and
' ceilings are loaded with the level (chapter 20); these are the ones every
' level shares.
'
' Some pictures are made rather than loaded: the keycards and key doors are
' one picture tinted three colours, each monster gets a second, red-washed
' copy to flash when it's hit, and the bolt is drawn with maths (MakeBolt).
LoadTex "door.png", T_DOOR
LoadTex "door-shutter.png", T_SHUTTER
LoadTex "door-split.png", T_SPLIT
LoadTex "exit.png", T_EXIT : ExitSign
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
FOR slot = 9 TO 17 STEP 2 ' The hit flash: each monster washed hot red, in the next slot
    FOR y = 0 TO SPR_TEX - 1 : FOR x = 0 TO SPR_TEX-1
        spriteTex(x, y, slot + 1) = Tint~&(spriteTex(x, y, slot), _RGB32(255, 90, 70), 0.7)
    NEXT : NEXT
    spriteSize(slot + 1) = spriteSize(slot)
NEXT
MakeBolt S_BOLT
LoadSprite "barrel.png", S_DECO + 1
LoadSprite "lamp.png", S_DECO + 2
LoadSprite "plant.png", S_DECO + 3
LoadSprite "terminal.png", S_DECO + 4
LoadSprite "explosion.png", S_BLAST
LoadSprite "armor.png", 25
LoadSprite "bigmed.png", 26
LoadSprite "pickup-rail.png", 27
LoadSprite "map.png", 28

' The guns you hold are kept as ordinary images (not arrays): they're drawn
' over the finished view with _PUTIMAGE, at full size (chapter 18). LoadGun
' also works out where each one's muzzle is, for the muzzle flash.
gunScale(1) = 3 : gunScale(2) = 3.6 : gunScale(3) = 4 : gunScale(4) = 3.6 ' Drawn this many times their size
CONST GUN_Y = 600 ' A gun's bottom sits here, its muzzle straight below the crosshair
LoadGun 1, "gun.png"
LoadGun 2, "gun-scatter.png"
LoadGun 3, "gun-repeater.png"
LoadGun 4, "gun-rail.png"

' Sounds: WAV files from neon-caster/sfx/ (made with PWMSFXR - see
' make-sfx.sh there). _SNDOPEN loads one and gives back a handle, a number
' we keep in a & (LONG) variable and play with PlaySfx (chapter 23).
sndStep1& = LoadSnd&("step1.wav") : sndStep2& = LoadSnd&("step2.wav")
sndBump& = LoadSnd&("bump.wav") : sndHump& = LoadSnd&("wallhump.wav")
sndDoor& = LoadSnd&("door.wav") : sndShutter& = LoadSnd&("door-shutter.wav") : sndSplit& = LoadSnd&("door-split.wav")
sndCard& = LoadSnd&("keycard.wav") : sndLocked& = LoadSnd&("locked.wav")
sndEmpty& = LoadSnd&("empty.wav") : sndWeapon& = LoadSnd&("weapon.wav")
sndHealth& = LoadSnd&("health.wav") : sndAmmo& = LoadSnd&("ammo.wav") : sndShells& = LoadSnd&("shells.wav")
sndBoltWall& = LoadSnd&("bolt-wall.wav")
sndHurt& = LoadSnd&("hurt.wav") : sndDie& = LoadSnd&("die.wav")
gunSnd&(1) = LoadSnd&("shoot.wav") : gunSnd&(2) = LoadSnd&("scatter.wav") : gunSnd&(3) = LoadSnd&("repeater.wav")
gunSnd&(4) = LoadSnd&("rail.wav")
sndBarrel& = LoadSnd&("barrel.wav") : sndArmor& = LoadSnd&("armor.wav") : sndExit& = LoadSnd&("exit.wav")
' A decoration taking a hit, and breaking (by kind: 2 lamp, 3 plant, 4 terminal)
DIM decoBreakSnd&(4)
sndDecoHit& = LoadSnd&("deco-hit.wav")
decoBreakSnd&(2) = LoadSnd&("lamp-break.wav") : decoBreakSnd&(3) = LoadSnd&("plant-break.wav") : decoBreakSnd&(4) = LoadSnd&("terminal-break.wav")
CONST STEP_LEN = 2.6 ' Cells walked per footstep (about 2.8 a second at full speed)

' The monster types table: SetMonType fills in the "mtype" arrays (one
' entry per TYPE of monster - see chapter 3) for types 1-5. Speed is in
' cells a frame; height is in walls (1 = as tall as a wall); lift and bob
' are how high it hovers and how much it bobs; reach is how close it must
' be to hit you; damage is dmg plus a random 0 to +rnd - 1; cooldown (cool)
' is frames between attacks; slot is its sprite slot (chapter 5).
'          type name       HP  speed  height lift bob   reach dmg +rnd cool slot
SetMonType 1,   "drone",   3,  0.045, 0.65,  0.2, 0.05, 0.95, 8,  6,   50,  9
SetMonType 2,   "gunner",  4,  0.035, 0.8,   0,   0,    0,    9,  6,   90,  11
SetMonType 3,   "heavy",   10, 0.028, 0.95,  0,   0,    1.25, 20, 10,  80,  13
SetMonType 4,   "crawler", 2,  0.07,  0.4,   0,   0.02, 0.75, 5,  4,   35,  15
SetMonType 5,   "sentry",  8,  0,     0.75,  0,   0,    0,    7,  5,   50,  17
mtypeRanged(2) = -1 : mtypeRanged(5) = -1
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
CONST NUM_SETTINGS = 28
CONST SET_SFX = 1, SET_MUSIC = 2, SET_SPEECH = 3, SET_FOV = 4, SET_XSTYLE = 5
CONST SET_XCOLOR = 6, SET_XSIZE = 7, SET_BOB = 8, SET_SHAKE = 9, SET_MOUSE = 10
CONST SET_XALPHA = 11, SET_XFEEDBACK = 12, SET_HURTDIR = 13, SET_RENDERER = 14, SET_FPS = 15
CONST SET_BUMP = 16, SET_GLOW = 17, SET_NEON = 18, SET_SMOOTH = 19, SET_DYNLIGHT = 20, SET_SHADOWS = 21
CONST SET_PARTICLES = 22, SET_REFLECT = 23, SET_BLOOM = 24, SET_SCREENFX = 25, SET_HITFX = 26, SET_RETRO = 27, SET_LOOK = 28
DIM SHARED setting(NUM_SETTINGS), setDefault(NUM_SETTINGS), setMin(NUM_SETTINGS), setMax(NUM_SETTINGS)
DIM SHARED setStep(NUM_SETTINGS), setKind(NUM_SETTINGS), setKey$(NUM_SETTINGS), setLabel$(NUM_SETTINGS)
' MI_ = Menu Item kinds (what a line of a menu is and does)
CONST MI_ACTION = 1, MI_SUBMENU = 2, MI_SLIDER = 3, MI_TOGGLE = 4, MI_CHOICE = 5
CONST MI_KEY = 6, MI_BACK = 7, MI_TEXT = 8
'             setting        file name             menu label            control    min max  step start
DefineSetting SET_SFX,       "sfx",                "SFX VOLUME",         MI_SLIDER, 0,  100, 5,   80
DefineSetting SET_MUSIC,     "music",              "MUSIC VOLUME",       MI_SLIDER, 0,  100, 5,   60
DefineSetting SET_SPEECH,    "speech",             "SPEECH VOLUME",      MI_SLIDER, 0,  100, 5,   80
DefineSetting SET_FOV,       "fov",                "FIELD OF VIEW",      MI_SLIDER, 50, 110, 2,   66
DefineSetting SET_XSTYLE,    "crosshair_style",    "CROSSHAIR STYLE",    MI_CHOICE, 1,  6,   1,   1
DefineSetting SET_XCOLOR,    "crosshair_color",    "CROSSHAIR COLOR",    MI_CHOICE, 1,  6,   1,   1
DefineSetting SET_XSIZE,     "crosshair_size",     "CROSSHAIR SIZE",     MI_SLIDER, 1,  5,   1,   2
DefineSetting SET_BOB,       "weapon_bob",         "WEAPON BOBBING",     MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHAKE,     "screen_shake",       "SCREEN SHAKE",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_MOUSE,     "mouse_speed",        "MOUSE LOOK SPEED",   MI_SLIDER, 1,  10,  1,   5
DefineSetting SET_XALPHA,    "crosshair_opacity",  "CROSSHAIR OPACITY",  MI_SLIDER, 10, 100, 10,  100
DefineSetting SET_XFEEDBACK, "crosshair_feedback", "CROSSHAIR FEEDBACK", MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_HURTDIR,   "damage_indicators",  "DAMAGE INDICATORS",  MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RENDERER,  "renderer",           "RENDERER",           MI_CHOICE, 1,  2,   1,   1 ' 1 software, 2 OpenGL (chapter 24)
DefineSetting SET_FPS,       "show_fps",           "SHOW FPS",           MI_TOGGLE, 0,  1,   1,   0
DefineSetting SET_BUMP,      "bump_mapping",       "BUMP MAPPING",       MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
DefineSetting SET_GLOW,      "glows",              "GLOWS",              MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
' The OpenGL effects (chapter 24; SETTINGS > EFFECTS) and the two OpenGL
' view settings (SETTINGS > VIDEO). SCREEN FX: 1 off, 2 scanlines, 3 CRT.
DefineSetting SET_NEON,      "neon",               "NEON",               MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SMOOTH,    "smooth_light",       "SMOOTH LIGHT",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_DYNLIGHT,  "moving_lights",      "MOVING LIGHTS",      MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHADOWS,   "shadows",            "SHADOWS",            MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_PARTICLES, "particles",          "PARTICLES",          MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_REFLECT,   "reflections",        "WET FLOORS",         MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_BLOOM,     "bloom",              "BLOOM",              MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SCREENFX,  "screen_fx",          "SCREEN FX",          MI_CHOICE, 1,  3,   1,   1
DefineSetting SET_HITFX,     "hit_fx",             "HIT FX",             MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RETRO,     "retro_res",          "RETRO RESOLUTION",   MI_TOGGLE, 0,  1,   1,   0
DefineSetting SET_LOOK,      "look_up_down",       "LOOK UP / DOWN",     MI_TOGGLE, 0,  1,   1,   1
' BIND_ = a key binding's number: what each one does, its name in the
' settings file, its menu label, and its key to start with (a _KEYDOWN
' code: letters as lower case, 32 Space, 100306 left Ctrl, 16128 F5,
' 17152 F9, 9 Tab)
CONST NUM_BINDS = 9
CONST BIND_FORWARD = 1, BIND_BACK = 2, BIND_LEFT = 3, BIND_RIGHT = 4
CONST BIND_USE = 5, BIND_FIRE = 6, BIND_QUICKSAVE = 7, BIND_QUICKLOAD = 8, BIND_MAP = 9
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
' SCR_ = the menu's screens; MA_ = Menu Actions (what choosing a button does)
CONST SCR_MAIN = 1, SCR_GAME = 2, SCR_SAVE = 3, SCR_LOAD = 4, SCR_SETTINGS = 5
CONST SCR_AUDIO = 6, SCR_GAMEPLAY = 7, SCR_CONTROLS = 8, SCR_CREDITS = 9, SCR_QUIT = 10, SCR_VIDEO = 11, SCR_EFFECTS = 12
CONST MA_RESUME = 1, MA_NEW = 2, MA_SAVE = 3, MA_LOAD = 4, MA_QUIT = 5, MA_KEYS_DEFAULT = 6
' The items on the menu screen showing now: label, kind (MI_), what it
' refers to (a screen, a setting, a binding or a save slot), its action
' (MA_), whether it can be chosen, and a line of small print beside it
CONST MAX_MI = 16
DIM SHARED miLabel$(MAX_MI), miKind(MAX_MI), miRef(MAX_MI), miAct(MAX_MI), miOn(MAX_MI), miInfo$(MAX_MI)
DIM SHARED numMI, menuTitle$, menuSel, menuCapture, menuWide, menuScreen, menuInGame
DIM menuStack(10), menuStackSel(10) ' The screens you came through (for BACK)
' MENU_ = where the menu is drawn: the first row, the gap between rows,
' where labels start, and where sliders and other controls go
CONST MENU_TOP = 176, MENU_ROW = 32, MENU_LABEL_X = 140, MENU_WIDGET_X = 470, MENU_WIDGET_W = 200
CONST SPLASH_SECONDS = 3.5 ' How long the splash screen stays up (any key skips it)
' Saved games: the slots, and the file's first bytes, so a file from
' something else (or an older version) is never read as a save
CONST NUM_SLOTS = 3, SAVE_TAG = "NCSAVE02", SAVE_INFO_LEN = 48
' Things the settings change, worked out by ApplySettings: the camera
' plane's length (from the field of view) and the mouse turn speed
DIM SHARED fovPlane, turnSpeed
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
DIM SHARED menuMusic&, levelMusic&(NUM_LEVELS), nowPlaying&
menuMusic& = LoadMusic&("menu.ogg")
FOR k = 1 TO NUM_LEVELS : levelMusic&(k) = LoadMusic&("level" + LTRIM$(STR$(k)) + ".ogg") : NEXT
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
DIM cellFloor AS LONG, cellCeil AS LONG, splitCell AS LONG
DIM savedHasGun(NUM_GUNS) ' What you had on entering the level (you get it back if you die)

moveSpeed = 0.12 ' Cells a frame
LoadSettings ' Your settings and keys, from neon-caster/saves/settings.ini
ApplySettings
GOSUB ShowSplash
menuInGame = 0 : GOSUB RunMenu ' The title menu: it returns once a game is started or loaded

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
    mouseDX = 0 : mouseDY = 0 : mouseWheel = 0
    WHILE _MOUSEINPUT
        mouseDX = mouseDX + _MOUSEMOVEMENTX : mouseDY = mouseDY + _MOUSEMOVEMENTY
        mouseWheel = mouseWheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1
    WEND
    ' Keys go through the key bindings (chapter 21): KeyHeld(BIND_FIRE) asks
    ' "is the key you chose for firing held down?" - left Ctrl, unless you
    ' changed it in the menu.
    fireDown = _MOUSEBUTTON(1) OR clicked OR KeyHeld(BIND_FIRE)
    clicked = 0
    spaceDown = KeyHeld(BIND_USE)

    ' Esc opens the menu (chapter 21), and the game waits while it's open
    escDown = _KEYDOWN(27)
    IF escDown AND NOT escWas THEN
        menuInGame = -1 : GOSUB RunMenu
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
    IF _MOUSEBUTTON(2) AND NOT dead THEN aimTarget = 1 ELSE aimTarget = 0
    IF swapTimer > 0 THEN aimTarget = 0 ' Changing guns: lower it (no jump in zoom)
    IF aimAmount < aimTarget THEN aimAmount = aimAmount + 1 / ADS_FRAMES : IF aimAmount > 1 THEN aimAmount = 1
    IF aimAmount > aimTarget THEN aimAmount = aimAmount - 1 / ADS_FRAMES : IF aimAmount < 0 THEN aimAmount = 0
    zoom = 1 + (gunZoom(currentGun) - 1) * aimAmount ' (each gun zooms its own amount)

    mouseDX = mouseDX / DisplayScale! ' The same turn speed in a window or full screen
    turn = - mouseDX * turnSpeed / zoom ' (slower when zoomed, so aiming stays steady)
    oldDirX = dirX : dirX = dirX * COS(turn) - dirY * SIN(turn) : dirY = oldDirX * SIN(turn) + dirY * COS(turn)
    oldPlaneX = planeX : planeX = planeX * COS(turn) - planeY * SIN(turn) : planeY = oldPlaneX * SIN(turn) + planeY * COS(turn)

    ' Looking up and down - only with OpenGL (chapter 24), which can tilt
    ' its camera; the raycaster's world has no up or down to look at
    ' (LOOK UP / DOWN in SETTINGS > VIDEO). Moving the mouse forward looks
    ' up, as far as 0.6 radians (about 34 degrees) each way. Shots still go
    ' straight ahead: like Doom, whatever's in the middle column is hit,
    ' high or low. Otherwise the view eases back to level.
    IF glMode AND setting(SET_LOOK) AND NOT dead THEN
        pitch = pitch - mouseDY / DisplayScale! * turnSpeed / zoom
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
    IF _KEYDOWN(49) THEN wantGun = 1
    IF _KEYDOWN(50) THEN wantGun = 2
    IF _KEYDOWN(51) THEN wantGun = 3
    IF _KEYDOWN(52) THEN wantGun = 4
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

    '-------------------------------------------------------------------------
    ' CHAPTER 9: MOVING, AND BUMPING INTO THINGS
    '-------------------------------------------------------------------------
    ' W and S move you along (dirX, dirY); A and D move you sideways, along
    ' (dirY, -dirX) - your direction turned 90 degrees. Pressing W and D
    ' together adds the two, which would be about 1.4 times as fast, so the
    ' sum is "normalized": divided by its own length (moveLen) to make it one
    ' cell long, then scaled to walking speed. Now every direction is the
    ' same speed, and opposite keys simply cancel out.
    forward = 0 : strafe = 0
    IF NOT dead THEN
        IF KeyHeld(BIND_FORWARD) THEN forward = forward + 1 ' W, unless rebound
        IF KeyHeld(BIND_BACK) THEN forward = forward - 1 ' S
        IF KeyHeld(BIND_LEFT) THEN strafe = strafe - 1 ' A (strafe left)
        IF KeyHeld(BIND_RIGHT) THEN strafe = strafe + 1 ' D (strafe right)
    END IF
    moveX = dirX * forward + dirY * strafe : moveY = dirY * forward - dirX * strafe
    moveLen = SQR(moveX * moveX + moveY * moveY)
    IF moveLen > 0 THEN
        moveX = moveX / moveLen * moveSpeed : moveY = moveY / moveLen * moveSpeed
        bobPhase = bobPhase + 0.2
    END IF

    ' Collision. You're a square, PLAYER_RADIUS from your middle to each
    ' side, so the camera can never get right up against a wall (it would
    ' fill the screen with one blurry texel). MoveBody (chapter 23) tries the
    ' X part of the move and the Y part separately: walk into a wall at an
    ' angle and the blocked part stops, while the other part carries on -
    ' so you slide along the wall instead of sticking to it. Monsters move
    ' with MoveBody too.
    prevX = playerX : prevY = playerY
    IF godMode THEN ' No clipping: straight through anything, but stay inside the border
        playerX = playerX + moveX : playerY = playerY + moveY
        IF playerX < 1.01 THEN playerX = 1.01
        IF playerX > MAP_SIZE - 1.01 THEN playerX = MAP_SIZE - 1.01
        IF playerY < 1.01 THEN playerY = 1.01
        IF playerY > MAP_SIZE - 1.01 THEN playerY = MAP_SIZE - 1.01
    ELSE
        MoveBody playerX, playerY, moveX, moveY
    END IF
    ' ...and you can't walk through a monster: if a step takes you inside one
    ' (closer than touchDist) and closer than you were, take it back
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 2 AND NOT godMode THEN
            touchDist = 0.3 + mtypeScale(monsterType(i)) * 0.35
            newDistSq = (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2
            IF newDistSq < touchDist * touchDist AND newDistSq <(monsterX(i) - prevX) ^ 2 + (monsterY(i) -prevY) ^ 2 THEN playerX = prevX : playerY = prevY
        END IF
    NEXT

    ' Footsteps: one every STEP_LEN cells actually walked, alternating feet
    ' (so walking into a wall makes no footsteps)
    moved = SQR((playerX - prevX) ^ 2 + (playerY - prevY) ^ 2)
    IF moved > 0 THEN
        stepDist = stepDist + moved
        IF stepDist >= STEP_LEN THEN
            stepDist = stepDist - STEP_LEN : stepFoot = 1 - stepFoot
            IF stepFoot THEN PlaySfx sndStep1&, 0.35 ELSE PlaySfx sndStep2&, 0.35
        END IF
    ELSE
        stepDist = STEP_LEN * 0.85
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
        IF itemOn(i) AND NOT dead AND (itemX(i) - playerX) ^ 2 + (itemY(i) -playerY) ^ 2 < 0.45 * 0.45 THEN
            SELECT CASE itemKind(i)
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
    IF CHEAT_KEYS AND kKeyDown AND NOT kKeyWas AND NOT dead THEN
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT
        hasMap = -1
        PlaySfx sndCard&, 0.8 : ShowMsg "All keycards, and the map"
    END IF
    kKeyWas = kKeyDown
    ' G: god mode on / off - no damage, and you walk through walls (testing)
    gKeyDown = _KEYDOWN(103) OR _KEYDOWN(71)
    IF CHEAT_KEYS AND gKeyDown AND NOT gKeyWas AND NOT dead THEN
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
    ' Tab: the full-screen map on or off (drawn in chapter 18)
    mapKeyDown = KeyHeld(BIND_MAP)
    IF mapKeyDown AND NOT mapKeyWas THEN mapOpen = NOT mapOpen
    mapKeyWas = mapKeyDown

    '-------------------------------------------------------------------------
    ' CHAPTER 11: DOORS
    '-------------------------------------------------------------------------
    ' Space opens the door in front of you. To find it, we take small steps
    ' (0.05 cells) out from you along (dirX, dirY), up to 2 cells, and look
    ' at the cell each step lands in: the first shut door is the one, and a
    ' wall first means there's nothing to open. The exit door is a door that
    ' never opens - Space on it ends the level (chapter 20).
    '
    ' A door's doorOpen() goes from 0 (shut) to 1 (open). Space just nudges
    ' it off 0; after that the loop below adds a little every frame until it
    ' reaches 1. The wall drawing (chapter 15) uses the number to slide the
    ' door aside, raise the shutter, or part the split door's halves.
    IF spaceDown AND NOT spaceWas AND NOT dead THEN ' (once per press)
        FOR reach = 0.05 TO 2 STEP 0.05
            cellX = INT(playerX + dirX * reach) : cellY = INT(playerY + dirY * reach)
            IF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) = 0 THEN
                keyNeeded = doorKey(cellX, cellY)
                IF doorType(cellX, cellY) = DOOR_EXIT THEN
                    GOSUB LevelDone
                ELSEIF keyNeeded = 0 OR hasCard(keyNeeded) THEN
                    doorOpen(cellX, cellY) = 0.01
                    SELECT CASE doorType(cellX, cellY)
                        CASE DOOR_SHUTTER : PlaySfx sndShutter&, 0.9
                        CASE DOOR_SPLIT : PlaySfx sndSplit&, 0.9
                        CASE ELSE : PlaySfx sndDoor&, 0.9
                    END SELECT
                ELSE
                    PlaySfx sndLocked&, 0.8
                    ShowMsg "Locked - you need the " + CardName$(keyNeeded) + " keycard"
                END IF
                EXIT FOR
            END IF
            IF SolidAt(playerX + dirX * reach, playerY + dirY * reach) THEN
                IF reach <= 1.2 THEN PlaySfx sndHump&, 0.8 ' Trying to open a plain wall
                EXIT FOR
            END IF
        NEXT
    END IF
    FOR doorY = 0 TO MAP_SIZE - 1 : FOR doorX = 0 TO MAP_SIZE-1
        IF doorOpen(doorX, doorY) > 0 AND doorOpen(doorX, doorY) < 1 THEN
            SELECT CASE doorType(doorX, doorY) ' Shutters are heavy and slow, split doors snap open
                CASE DOOR_SHUTTER : doorOpen(doorX, doorY) = doorOpen(doorX, doorY) + 0.025
                CASE DOOR_SPLIT : doorOpen(doorX, doorY) = doorOpen(doorX, doorY) + 0.06
                CASE ELSE : doorOpen(doorX, doorY) = doorOpen(doorX, doorY) + 0.04
            END SELECT
            IF doorOpen(doorX, doorY) > 1 THEN doorOpen(doorX, doorY) = 1
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
    IF fireDown AND NOT dead AND fireWait = 0 AND swapTimer = 0 THEN
        ammoType = gunAmmoType(currentGun)
        IF ammoCount(ammoType) >= gunAmmoPerShot(currentGun) THEN
            ammoCount(ammoType) = ammoCount(ammoType) - gunAmmoPerShot(currentGun) : fireWait = gunDelay(currentGun) : recoil = gunKick(currentGun) : muzzleFlash = 4
            PlaySfx gunSnd&(currentGun), 0.7
            hitDamage = gunDamage(currentGun) : IF gunPierce(currentGun) THEN railBeam = 8
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
                FOR i = 1 TO numMonsters
                    IF monsterState(i) < 2 THEN
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
                    IF decoOn(i) THEN
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
                ELSEIF bestDeco = 0 THEN
                    hitDist = zBuffer(screenCol) * 0.97
                    SELECT CASE currentGun
                        CASE W_BLASTER : SpawnSparks playerX + (dirX + planeX * aim) * hitDist, playerY + (dirY + planeY * aim) * hitDist, 0.5, 6, 255, 70, 120
                        CASE W_SCATTER : SpawnSparks playerX + (dirX + planeX * aim) * hitDist, playerY + (dirY + planeY * aim) * hitDist, 0.5, 3, 255, 180, 70
                        CASE W_REPEATER : SpawnSparks playerX + (dirX + planeX * aim) * hitDist, playerY + (dirY + planeY * aim) * hitDist, 0.5, 4, 80, 220, 255
                        CASE ELSE : SpawnSparks playerX + (dirX + planeX * aim) * hitDist, playerY + (dirY + planeY * aim) * hitDist, 0.5, 14, 170, 240, 255
                    END SELECT
                END IF
            NEXT
        ELSEIF NOT fireWas THEN
            PlaySfx sndEmpty&, 0.7
            IF ammoType = AM_SHELLS THEN ShowMsg "Out of shells" ELSE ShowMsg "Out of energy cells"
            fireWait = 20
        END IF
    END IF
    fireWas = fireDown : spaceWas = spaceDown

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
    '   2 dying    shrinks into the floor for MON_DYING frames
    '   3 dead     gone; skipped from now on
    '
    ' Shooting an idle monster wakes it too (HitMonster, chapter 19).
    ' Monsters steer the dumbest way possible - straight at you - and slide
    ' along walls with MoveBody like you do. They also push gently apart, so
    ' a pack doesn't merge into one sprite.
    FOR i = 1 TO numMonsters
        IF monsterHurt(i) > 0 THEN monsterHurt(i) = monsterHurt(i) -1
        mtype = monsterType(i)
        SELECT CASE monsterState(i)
            CASE 0 ' Idle: wake when it can see you
                IF NOT dead THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2 < MON_SIGHT * MON_SIGHT THEN
                        IF CanSee(monsterX(i), monsterY(i), playerX, playerY) THEN
                            monsterState(i) = 1 : monsterTimer(i) = 30
                            SfxAt mtypeAlertSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                        END IF
                    END IF
                END IF
            CASE 1 ' Hunting
                IF monsterTimer(i) > 0 THEN monsterTimer(i) = monsterTimer(i) -1
                toPlayerX = playerX - monsterX(i) : toPlayerY = playerY - monsterY(i) : distance = SQR(toPlayerX * toPlayerX + toPlayerY * toPlayerY)
                IF NOT dead AND distance > 0.01 THEN
                    goX = 0 : goY = 0
                    IF mtypeRanged(mtype) THEN
                        ' Gunner: keep its distance, shoot when it has a clear line
                        ' (a sentry can't move, so it just shoots)
                        seen = CanSee(monsterX(i), monsterY(i), playerX, playerY)
                        IF distance > GUNNER_FAR OR NOT seen THEN goX = toPlayerX / distance : goY = toPlayerY / distance
                        IF distance < GUNNER_NEAR THEN goX = - toPlayerX / distance : goY = -toPlayerY / distance
                        IF seen AND monsterTimer(i) = 0 AND distance < 11 THEN
                            FireBolt monsterX(i), monsterY(i), toPlayerX / distance, toPlayerY / distance, mtypeDamage(mtype) + INT(RND * mtypeDamageRnd(mtype))
                            SfxAt mtypeAttackSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                            monsterTimer(i) = mtypeCooldown(mtype) + INT(RND * 30)
                        END IF
                    ELSEIF distance > mtypeReach(mtype) THEN
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' The rest: close in...
                    ELSEIF monsterTimer(i) = 0 THEN ' ...and hit
                        damage = mtypeDamage(mtype) + INT(RND * mtypeDamageRnd(mtype)) : monsterTimer(i) = mtypeCooldown(mtype)
                        PlaySfx mtypeAttackSnd&(mtype), 0.9
                        hurtFromX = monsterX(i) : hurtFromY = monsterY(i) : GOSUB HurtPlayer
                    END IF
                    IF goX <> 0 OR goY <> 0 THEN MoveBody monsterX(i), monsterY(i), goX * mtypeSpeed(mtype), goY * mtypeSpeed(mtype)
                END IF
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
            boltX(i) = boltX(i) + boltDX(i) * BOLT_SPEED : boltY(i) = boltY(i) + boltDY(i) * BOLT_SPEED
            IF NOT Walkable(boltX(i), boltY(i)) THEN
                boltOn(i) = 0 : SfxAt sndBoltWall&, boltX(i), boltY(i), playerX, playerY
                SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, 0.49, 7, 255, 60, 230
            ELSEIF NOT dead AND (boltX(i) - playerX) ^ 2 + (boltY(i) -playerY) ^ 2 < 0.35 * 0.35 THEN
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
    ' on; dust drifts in around you with the PARTICLES effect on
    UpdateParticles
    IF glMode AND setting(SET_PARTICLES) THEN SpawnDust playerX, playerY

    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
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
    IF NOT glMode THEN ' (OpenGL draws the floor and ceiling itself)
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
                        lightR& = litR(cellX, cellY) * fog& \ 256 : lightG& = litG(cellX, cellY) * fog& \ 256 : lightB& = litB(cellX, cellY) * fog& \ 256
                    ELSE
                        cellFloor = T_FLOOR + 1 : cellCeil = T_CEIL + 1
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
                texU = INT(floorX * TEX_SIZE) AND (TEX_SIZE - 1) : texV = INT(floorY * TEX_SIZE) AND (TEX_SIZE - 1)
                ' The same sum as ShadeRGB~& (chapter 23), written out here: this
                ' runs 120,000 times a frame, and calling a FUNCTION each time
                ' would cost more than the sum itself
                texel~& = texture(texU, texV, floorSlot)
                pixels(floorRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                texel~& = texture(texU, texV, ceilSlot)
                pixels(ceilRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                floorX = floorX + floorStepX : floorY = floorY + floorStepY
            NEXT
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
    '   DOORS are drawn on the near face of their cell. The ray stops there
    '   only where the door still is: a sliding door has slid doorOpen of
    '   the way across, so a ray hitting the part it slid away from carries
    '   on into the room beyond. A rising shutter is drawn in a second pass,
    '   over whatever is behind it ("shutterSeen" remembers it).
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

        hit = 0 : side = 0 : shutterSeen = 0 : diagHit = 0
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
                IF side = 0 THEN doorDist = (mapX - playerX + (1 - stepX) / 2) / rayDirX : doorU = playerY + doorDist * rayDirY ELSE doorDist = (mapY - playerY + (1 - stepY) / 2) / rayDirY : doorU = playerX + doorDist * rayDirX
                doorU = doorU - INT(doorU) : doorOpenAmt = doorOpen(mapX, mapY)
                SELECT CASE doorType(mapX, mapY)
                    CASE DOOR_SLIDE ' Slides sideways
                        IF doorU > doorOpenAmt THEN hit = 2
                    CASE DOOR_SPLIT ' Halves part from the middle
                        IF doorU < 0.5 - doorOpenAmt / 2 OR doorU > 0.5 + doorOpenAmt / 2 THEN hit = 2
                    CASE DOOR_EXIT ' Never opens
                        hit = 2
                    CASE DOOR_SHUTTER ' Rises: shut, it's a wall; rising, you see under it
                        IF doorOpenAmt <= 0 THEN
                            hit = 2
                        ELSEIF doorOpenAmt < 1 AND shutterSeen = 0 THEN
                            shutterSeen = -1 : shutterDist = doorDist : shutterU = doorU : shutterOpen = doorOpenAmt : shutterSide = side
                            IF side = 0 THEN shutterLitX = mapX - stepX : shutterLitY = mapY ELSE shutterLitX = mapX : shutterLitY = mapY - stepY
                        END IF
                END SELECT
            ELSEIF cellValue > 0 THEN
                hit = cellValue
            END IF
        WEND

        IF diagHit = 0 THEN
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
            texX = INT(wallX * TEX_SIZE) : texSlot = wallTexSlot(hit)
        ELSEIF hit = 2 THEN
            doorOpenAmt = doorOpen(mapX, mapY)
            SELECT CASE doorType(mapX, mapY)
                CASE DOOR_SLIDE
                    texX = INT((wallX - doorOpenAmt) * TEX_SIZE)
                    IF doorKey(mapX, mapY) THEN texSlot = T_DOORK + doorKey(mapX, mapY) ELSE texSlot = T_DOOR
                CASE DOOR_SPLIT
                    IF wallX < 0.5 THEN texX = INT((wallX + doorOpenAmt / 2) * TEX_SIZE) ELSE texX = INT((wallX - doorOpenAmt / 2) * TEX_SIZE)
                    texSlot = T_SPLIT
                CASE DOOR_EXIT ' (turned like a wall, so its sign reads the right way)
                    texX = INT(wallX * TEX_SIZE) : texSlot = T_EXIT
                    IF side = 0 AND rayDirX > 0 THEN texX = TEX_SIZE - 1 - texX
                    IF side = 1 AND rayDirY < 0 THEN texX = TEX_SIZE - 1 - texX
                CASE ELSE
                    texX = INT(wallX * TEX_SIZE) : texSlot = T_SHUTTER
            END SELECT
        ELSE
            texX = INT(wallX * TEX_SIZE) : texSlot = wallTexSlot(hit)
            IF side = 0 AND rayDirX > 0 THEN texX = TEX_SIZE - 1 - texX
            IF side = 1 AND rayDirY < 0 THEN texX = TEX_SIZE - 1 - texX
        END IF
        texX = texX AND (TEX_SIZE - 1)

        lineHeight = viewH / perpWallDist
        drawStart = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2)
        texStep = TEX_SIZE / lineHeight : texPos = (drawStart - RENDER_H / 2 + lineHeight / 2) * texStep
        IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
        IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1

        ' Light: the light of the cell in front of the face we hit (for a
        ' diagonal, its own cell), dimmed by distance fog, y-sides darker and
        ' diagonals in between
        fog& = 256 - perpWallDist * 16
        IF fog& < 0 THEN fog& = 0
        IF diagHit THEN fog& = fog& * 0.85 ELSE IF side = 1 THEN fog& = fog& * 0.7
        IF diagHit THEN
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

        IF NOT glMode THEN ' (OpenGL draws the walls itself)
            FOR y = drawStart TO drawEnd ' (ShadeRGB~&, written out - see the floor)
                texel~& = texture(texX, INT(texPos) AND (TEX_SIZE - 1), texSlot)
                pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                texPos = texPos + texStep
            NEXT
        END IF

        ' A rising shutter in front: its lower edge has lifted shutterOpen of
        ' the way up, so draw only the part still hanging down
        IF shutterSeen THEN
            lineHeight = viewH / shutterDist
            shutterTop = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2 - shutterOpen * lineHeight)
            texStep = TEX_SIZE / lineHeight : texPos = shutterOpen * TEX_SIZE
            drawStart = shutterTop
            IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
            IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1
            fog& = 256 - shutterDist * 16
            IF fog& < 0 THEN fog& = 0
            IF shutterSide = 1 THEN fog& = fog& * 0.7
            lightR& = litR(shutterLitX, shutterLitY) * fog& \ 256 : lightG& = litG(shutterLitX, shutterLitY) * fog& \ 256 : lightB& = litB(shutterLitX, shutterLitY) * fog& \ 256
            texX = INT(shutterU * TEX_SIZE) AND (TEX_SIZE - 1)
            IF NOT glMode THEN
                FOR y = drawStart TO drawEnd
                    pixels(y * RENDER_W + x) = ShadeRGB~&(texture(texX, INT(texPos) AND (TEX_SIZE - 1), T_SHUTTER), lightR&, lightG&, lightB&)
                    texPos = texPos + texStep
                NEXT
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
        IF itemOn(i) THEN
            numDraw = numDraw + 1 : drawX(numDraw) = itemX(i) : drawY(numDraw) = itemY(i)
            drawSprite(numDraw) = ItemSprite(itemKind(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 96 ' They glow: less fog
            SELECT CASE itemKind(i)
                CASE 1 TO 3 : drawScale(numDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL : drawScale(numDraw) = GUN_ITEM_SCALE
                CASE ELSE : drawScale(numDraw) = ITEM_SCALE
            END SELECT
            drawLift(numDraw) = 0.12 + 0.04 * SIN(TIMER * 3 + i) ' Hovering, bobbing
        END IF
    NEXT
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 3 THEN
            mtype = monsterType(i)
            numDraw = numDraw + 1 : drawX(numDraw) = monsterX(i) : drawY(numDraw) = monsterY(i)
            drawScale(numDraw) = mtypeScale(mtype) : drawMinShade(numDraw) = 40
            IF monsterHurt(i) > 0 THEN drawSprite(numDraw) = mtypeSprite(mtype) + 1 ELSE drawSprite(numDraw) = mtypeSprite(mtype)
            IF monsterState(i) = 2 THEN ' Collapsing to the floor
                drawSquash(numDraw) = monsterTimer(i) / MON_DYING : drawLift(numDraw) = mtypeLift(mtype) * drawSquash(numDraw) : drawSprite(numDraw) = mtypeSprite(mtype) + 1
            ELSE
                drawSquash(numDraw) = 1 : drawLift(numDraw) = mtypeLift(mtype) + mtypeBob(mtype) * SIN(TIMER * 2.5 + i * 1.7)
            END IF
        END IF
    NEXT
    FOR i = 1 TO numDecos
        IF decoOn(i) OR decoTimer(i) > 0 THEN
            numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) : drawY(numDraw) = decoY(i)
            drawSprite(numDraw) = S_DECO + decoKind(i) : drawScale(numDraw) = DecoScale(decoKind(i)) : drawLift(numDraw) = 0
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40
            IF NOT decoOn(i) THEN drawSquash(numDraw) = decoTimer(i) / DECO_BREAK_FRAMES ' Broken: sinking into the floor
            IF decoKind(i) = 2 THEN drawMinShade(numDraw) = 200 ' Lamps glow
        END IF
    NEXT
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN ' Explosions swell as they fade
            numDraw = numDraw + 1 : drawX(numDraw) = blastX(i) : drawY(numDraw) = blastY(i)
            drawSprite(numDraw) = S_BLAST : drawScale(numDraw) = (0.6 + 0.7 * (1 - blastTime(i) / BLAST_FRAMES)) * blastSize(i)
            drawLift(numDraw) = 0.05 + (1 - blastSize(i)) * 0.35 ' (a small puff of sparks floats at the broken thing's middle)
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) THEN
            numDraw = numDraw + 1 : drawX(numDraw) = boltX(i) : drawY(numDraw) = boltY(i)
            drawSprite(numDraw) = S_BOLT : drawScale(numDraw) = 0.22 : drawLift(numDraw) = 0.38
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
            spriteTop = INT(RENDER_H / 2 + (0.5 - drawLift(i)) * viewH / transformY) -spriteH ' Bottom edge lifted off the floor
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
                glSprX(n, glWrite) = drawX(i) : glSprY(n, glWrite) = drawY(i) : glSprLift(n, glWrite) = drawLift(i)
                glSprHalfW(n, glWrite) = drawScale(i) * fovPlane * RENDER_H / RENDER_W
                glSprH(n, glWrite) = drawScale(i) * drawSquash(i) : glSprSlot(n, glWrite) = spriteSlot
                glSprR(n, glWrite) = lightR& / 256 : glSprG(n, glWrite) = lightG& / 256 : glSprB(n, glWrite) = lightB& / 256
            ELSE
                FOR screenX = spriteLeft TO spriteLeft + spriteW - 1
                    IF screenX >= 0 AND screenX < RENDER_W THEN
                        IF transformY < zBuffer(screenX) THEN
                            spriteU = (screenX - spriteLeft) * spriteSz \ spriteW
                            FOR screenY = spriteTop TO spriteTop + spriteH - 1
                                IF screenY >= 0 AND screenY < RENDER_H THEN
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
    ' With OpenGL (chapter 24) there's no picture to copy: instead we finish
    ' the snapshot - the camera, every cell's light, every door - and then
    ' switch glBuf over to it, in one line, so SUB _GL only ever sees a
    ' whole frame. The screen is cleared to see-through (alpha 0), so the
    ' graphics card's view shows from underneath (chapter 1) wherever the
    ' HUD below doesn't draw.
    IF glMode THEN
        glCamX(glWrite) = playerX : glCamY(glWrite) = playerY : glDirX(glWrite) = dirX : glDirY(glWrite) = dirY
        glPlaneLen(glWrite) = fovPlane / zoom : glZoom(glWrite) = zoom : glFullMode(glWrite) = _FULLSCREEN
        glShakeX(glWrite) = shakeX : glShakeY(glWrite) = shakeY : glShakeEdge(glWrite) = shakeEdge
        FOR i = 1 TO NUM_SETTINGS : glSet(i, glWrite) = setting(i) : NEXT
        glPitch(glWrite) = pitch : glHurt(glWrite) = hurtFlash / 14 : glRail(glWrite) = railBeam / 8
        IF ABS(pitch) > 0.01 THEN GLMarkWide playerX, playerY, dirX, dirY, fovPlane / zoom, zoom ' (tilted, the view sees past the rays' edges)
        GLHandOverExtras playerX, playerY, dirX, dirY, muzzleFlash ' Moving lights, particles, explosions (chapter 24)
        FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
            glLitR(x, y, glWrite) = litR(x, y) : glLitG(x, y, glWrite) = litG(x, y) : glLitB(x, y, glWrite) = litB(x, y)
            glDoor(x, y, glWrite) = doorOpen(x, y)
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
    gunW = _WIDTH(gunImage&) * gunScale(currentGun) : gunH = _HEIGHT(gunImage&) * gunScale(currentGun)
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
    IF dead THEN gunY = gunY + (TIMER - deadAt!) * 400 ' Drops out of view
    IF gunY < 600 THEN _PUTIMAGE (gunX, gunY)-(gunX + gunW - 1, gunY + gunH - 1), gunImage&
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
    IF godMode THEN HudText 16, 498, "GOD MODE", _RGB32(255, 215, 30)

    ' The map (DrawMap, chapter 23). The minimap in the corner only appears
    ' once you've found this level's map pickup. Tab opens the full-screen
    ' map: without the pickup it shows only the cells you've seen - you draw
    ' it as you explore - and with it, the whole level.
    IF hasMap AND NOT mapOpen THEN
        DrawMap MINIMAP_X, MINIMAP_Y, MINIMAP_CELL, -1, playerX, playerY, dirX, dirY
        killsY = MINIMAP_Y + MAP_SIZE * MINIMAP_CELL + 6
    ELSE
        killsY = MINIMAP_Y
    END IF
    IF mapOpen THEN
        LINE (0, 0)-(799, 599), _RGBA32(0, 4, 14, 225), BF
        MenuText 400, 14, levelName$, 2, _RGB32(255, 100, 215), 1
        DrawMap 400 - MAP_SIZE * 5, 60, 10, hasMap, playerX, playerY, dirX, dirY
        IF hasMap THEN mapNote$ = "TAB  CLOSE THE MAP" ELSE mapNote$ = "NO MAP YET - ONLY WHERE YOU'VE BEEN.   TAB  CLOSE"
        MenuText 400, 552, mapNote$, 1, _RGB32(170, 170, 200), 1
    END IF
    IF NOT mapOpen THEN HudText MINIMAP_X, killsY, "KILLS" + STR$(kills) + " /" + STR$(numMonsters), _RGB32(255, 90, 90)

    ' Keycards you hold, top right
    cardX = 800 - 16
    FOR k = 3 TO 1 STEP - 1
        IF hasCard(k) THEN cardX = cardX - 68 : _PUTIMAGE (cardX, 8)-STEP(63, 63), cardImg&(k)
    NEXT

    ' Armour and health (bottom left)
    IF armor > 0 THEN
        HudText 16, 516, "ARMOR" + STR$(armor), _RGB32(90, 160, 255)
        LINE (16, 534)-STEP(201, 9), _RGBA32(0, 0, 0, 170), BF
        LINE (17, 535)-STEP(armor * 2 - 1, 7), _RGB32(90, 160, 255), BF
    END IF
    IF health > 60 THEN healthColor~& = _RGB32(60, 230, 90) ELSE IF health > 25 THEN healthColor~& = _RGB32(255, 200, 40) ELSE healthColor~& = _RGB32(255, 50, 50)
    HudText 16, 552, "HEALTH" + STR$(health), healthColor~&
    LINE (16, 570)-STEP(201, 13), _RGBA32(0, 0, 0, 170), BF
    IF health > 0 THEN LINE (17, 571)-STEP(health * 2 - 1, 11), healthColor~&, BF

    ' Gun and its ammo (bottom right), and which guns you have
    ammoType = gunAmmoType(currentGun)
    IF ammoCount(ammoType) = 0 THEN
        ammoColor~& = _RGB32(255, 50, 50)
    ELSEIF ammoType = AM_SHELLS THEN
        ammoColor~& = _RGB32(255, 150, 40)
    ELSE
        ammoColor~& = _RGB32(60, 220, 255)
    END IF
    ammoText$ = gunName$(currentGun) + "  " + LTRIM$(STR$(ammoCount(ammoType)))
    HudText 800 - 16 - 8 * LEN(ammoText$), 552, ammoText$, ammoColor~&
    LINE (800 - 16 - 202, 570)-STEP(201, 13), _RGBA32(0, 0, 0, 170), BF
    IF ammoCount(ammoType) > 0 THEN LINE (800 - 16 - 1 - ammoCount(ammoType) * 200 \ ammoMax(ammoType), 571)-(800 - 16 - 1, 582), ammoColor~&, BF
    FOR gun = 1 TO NUM_GUNS
        gunNumColor~& = _RGB32(60, 60, 70)
        IF hasGun(gun) THEN gunNumColor~& = _RGB32(150, 150, 160)
        IF gun = currentGun THEN gunNumColor~& = _RGB32(255, 255, 255)
        HudText 800 - 16 - 202 + (gun - 1) * 20, 534, LTRIM$(STR$(gun)), gunNumColor~&
    NEXT

    ' Message line
    IF TIMER < messageUntil! AND LEN(message$) AND NOT mapOpen THEN
        HudText 400 - LEN(message$) * 4, 510, message$, _RGB32(255, 255, 255)
    END IF

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
        IF glMode THEN fpsText$ = "OPENGL" ELSE fpsText$ = "SOFTWARE"
        fpsText$ = fpsText$ + "   FPS" + STR$(fpsShown) + "   3D VIEW" + STR$(INT(viewAvg * 10) / 10) + " MS"
        HudText 400 - LEN(fpsText$) * 4, 8, fpsText$, _RGB32(255, 255, 120)
    END IF

    ' With OpenGL, the HUD goes to the graphics card as a picture, to be
    ' laid over the 3D view there (chapter 24): GLSL_filter_capture copies
    ' the screen for SUB _GL, and our own screen layer is switched off
    IF glMode THEN GLSL_filter_capture
    GLScreenLayer glMode
    _DISPLAY ' Show the finished frame (chapter 7)
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

' --- A shot (or blast) hits monster number target, for hitDamage
HitMonster:
monsterHP(target) = monsterHP(target) - hitDamage : monsterHurt(target) = 8
IF monsterState(target) = 0 THEN monsterState(target) = 1 : monsterTimer(target) = 30 ' Shot awake (chapter 13)
IF monsterHP(target) <= 0 AND monsterState(target) < 2 THEN
    monsterState(target) = 2 : monsterTimer(target) = MON_DYING : kills = kills + 1
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
IF godMode THEN hurtFromX = -1 : RETURN
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
    PlaySfx sndHurt&, 0.8
END IF
RETURN

' --- Barrel number `barrel` explodes: it hurts everything near it that it
' can see (more the closer it is), lights the fuses of other barrels close
' by, so they go off a moment later, and breaks the other decorations near it
Explode:
decoOn(barrel) = 0 : decoFuse(barrel) = 0 : decoCell(INT(decoX(barrel)), INT(decoY(barrel))) = 0
SfxAt sndBarrel&, decoX(barrel), decoY(barrel), playerX, playerY
newBlastX = decoX(barrel) : newBlastY = decoY(barrel) : newBlastSize = 1 : GOSUB AddBlast
distance = SQR((playerX - decoX(barrel)) ^ 2 + (playerY - decoY(barrel)) ^ 2) ' You feel it from a way off
IF distance < BLAST_RADIUS * 4 THEN shake = shake + 14 * (1 - distance / (BLAST_RADIUS * 4))
FOR j = 1 TO numMonsters
    IF monsterState(j) < 2 THEN
        distance = SQR((monsterX(j) - decoX(barrel)) ^ 2 + (monsterY(j) - decoY(barrel)) ^ 2)
        IF distance < BLAST_RADIUS THEN
            IF CanSee(decoX(barrel), decoY(barrel), monsterX(j), monsterY(j)) THEN target = j : hitDamage = INT(8 * (1 - distance / BLAST_RADIUS)) + 1 : GOSUB HitMonster
        END IF
    END IF
NEXT
distance = SQR((playerX - decoX(barrel)) ^ 2 + (playerY - decoY(barrel)) ^ 2)
IF distance < BLAST_RADIUS AND NOT dead THEN
    IF CanSee(decoX(barrel), decoY(barrel), playerX, playerY) THEN
        damage = INT(40 * (1 - distance / BLAST_RADIUS)) + 5
        hurtFromX = decoX(barrel) : hurtFromY = decoY(barrel) : GOSUB HurtPlayer
    END IF
END IF
FOR j = 1 TO numDecos
    IF decoOn(j) THEN
        distance = SQR((decoX(j) - decoX(barrel)) ^ 2 + (decoY(j) - decoY(barrel)) ^ 2)
        IF distance < BLAST_RADIUS THEN
            IF decoKind(j) = 1 THEN
                IF decoFuse(j) = 0 THEN decoFuse(j) = 8 ' Another barrel: it goes off in 8 frames
            ELSEIF CanSee(decoX(barrel), decoY(barrel), decoX(j), decoY(j)) THEN
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
HitDeco:
IF decoKind(targetDeco) = 1 THEN
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

' --- An explosion (or puff of sparks) to show at (newBlastX, newBlastY),
' newBlastSize big, in the first free slot - if all MAX_BLASTS are busy,
' this one isn't shown
AddBlast:
FOR blastSlot = 1 TO MAX_BLASTS
    IF blastTime(blastSlot) = 0 THEN
        blastX(blastSlot) = newBlastX : blastY(blastSlot) = newBlastY
        blastSize(blastSlot) = newBlastSize : blastTime(blastSlot) = BLAST_FRAMES
        SpawnEmbers newBlastX, newBlastY, newBlastSize ' (and a burst of embers: chapter 24's particles)
        EXIT FOR
    END IF
NEXT
RETURN

'-----------------------------------------------------------------------------
' CHAPTER 20: LEVELS
'-----------------------------------------------------------------------------
' A game is four levels in a row. What you carry - health, armour, ammo,
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
' LoadLevel reads a level from the DATA lines in chapter 22. RESTORE points
' READ at a label - Level1, Level2... - and READ then takes the values one
' after another: the name, the texture files, the floor zones, and the 48
' rows of the map, which it turns into worldMap() and the lists of things.

' --- A new game: level 1, just the blaster
NewGame:
level = 1 : totalKills = 0 : totalMonsters = 0 : totalTime! = 0
health = MAX_HP : armor = 0
ammoCount(AM_CELLS) = 30 : ammoCount(AM_SHELLS) = 0
FOR gun = 1 TO NUM_GUNS : hasGun(gun) = 0 : NEXT
hasGun(W_BLASTER) = -1 : currentGun = W_BLASTER
IF TEST_ALL_GUNS THEN ' Testing: every gun, full ammo
    FOR gun = 1 TO NUM_GUNS : hasGun(gun) = -1 : NEXT
    ammoCount(AM_CELLS) = ammoMax(AM_CELLS) : ammoCount(AM_SHELLS) = ammoMax(AM_SHELLS)
END IF
GOSUB EnterLevel
RETURN

' --- Into level number `level`, remembering what you bring with you
EnterLevel:
savedHealth = health : savedArmor = armor : savedCells = ammoCount(AM_CELLS) : savedShells = ammoCount(AM_SHELLS) : savedGun = currentGun
FOR gun = 1 TO NUM_GUNS : savedHasGun(gun) = hasGun(gun) : NEXT
GOSUB LoadLevel
RETURN

' --- You died: the level starts over, and you have what you came in with
RestartLevel:
health = savedHealth : armor = savedArmor : ammoCount(AM_CELLS) = savedCells : ammoCount(AM_SHELLS) = savedShells : currentGun = savedGun
FOR gun = 1 TO NUM_GUNS : hasGun(gun) = savedHasGun(gun) : NEXT
GOSUB LoadLevel
RETURN

' --- You used the exit: the level's tally, then on to the next level (after
' the last, the game's totals, and a new game)
LevelDone:
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
        IF level = NUM_LEVELS THEN prompt$ = "CLICK OR PRESS SPACE TO PLAY AGAIN" ELSE prompt$ = "CLICK OR PRESS SPACE FOR THE NEXT SECTOR"
        MenuText 400, 520, prompt$, 1, _RGB32(220, 220, 240), 1
    END IF
    IF glReady THEN GLSL_filter_capture ' (OpenGL draws the tally over its view: chapter 24)
    GLScreenLayer glReady
    _DISPLAY
LOOP
_FREEIMAGE screenshot&
IF level >= NUM_LEVELS THEN
    GOSUB NewGame
ELSE
    level = level + 1 : GOSUB EnterLevel
END IF
RETURN

' --- Start (or restart) the level: read its map, and reset everything in it
LoadLevel:
glReady = 0 ' (OpenGL: nothing to draw until the level's first frame - chapter 24)
FOR i = 1 TO MAX_PART : partLife(i) = 0 : NEXT : pitch = 0
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
    worldMap(x, y) = 0 : doorOpen(x, y) = 0 : doorKey(x, y) = 0 : doorType(x, y) = 0 : diagCorner(x, y) = 0
    floorTex(x, y) = T_FLOOR + 1 : ceilTex(x, y) = T_CEIL + 1 : floorSplit(x, y) = 0 : ceilSplit(x, y) = 0 : decoCell(x, y) = 0
    cellSeen(x, y) = 0
NEXT : NEXT
numItems = 0 : numMonsters = 0 : numDecos = 0 : hasMap = 0 : mapOpen = 0
FOR k = 1 TO 3 : hasCard(k) = 0 : NEXT
FOR i = 1 TO MAX_BOLTS : boltOn(i) = 0 : NEXT
FOR i = 1 TO MAX_BLASTS : blastTime(i) = 0 : NEXT
SELECT CASE level
    CASE 1 : RESTORE Level1
    CASE 2 : RESTORE Level2
    CASE 3 : RESTORE Level3
    CASE ELSE : RESTORE Level4
END SELECT
READ levelName$
FOR k = 1 TO 6 : READ file$ : LoadTex file$, k : NEXT ' Walls # N C K P G
FOR k = 1 TO 4 : READ file$ : LoadTex file$, T_FLOOR + k : NEXT
FOR k = 1 TO 2 : READ file$ : LoadTex file$, T_CEIL + k : NEXT
glTexVersion = glTexVersion + 1 ' (new textures: OpenGL needs them again - chapter 24)
READ ambientLevel, ambientTintR, ambientTintG, ambientTintB ' The level's ambient light: brightness, then colour
ambientR = ambientLevel * ambientTintR / 255 : ambientG = ambientLevel * ambientTintG / 255 : ambientB = ambientLevel * ambientTintB / 255
FOR k = 1 TO 7
    IF k <> 2 THEN wallMapColor(k) = MinimapColor~&(wallTexSlot(k))
NEXT
' Floor and ceiling zones (chapter 22): each paints a rectangle - or the
' triangle on one side of its diagonal - with a floor and/or ceiling texture
READ numZones
FOR k = 1 TO numZones
    READ zoneX0, zoneY0, zoneX1, zoneY1, zoneFloor, zoneCeil, zoneShape
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
' The level's lights: x, y, radius, brightness, red, green, blue, effect
numLights = 0
READ numLightsData
FOR k = 1 TO numLightsData
    READ lx, ly, lRadius, lBright, lRed, lGreen, lBlue, lEffect
    AddLight lx, ly, lRadius, lBright * lRed / 255, lBright * lGreen / 255, lBright * lBlue / 255, lEffect, 0
NEXT
FOR y = 0 TO MAP_SIZE - 1
    READ row$
    FOR x = 0 TO MAP_SIZE - 1
        cell$ = MID$(row$, x + 1, 1)
        SELECT CASE cell$
            CASE "#" : worldMap(x, y) = 1
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
            CASE "r", "b", "y", "+", "a", "e", "2", "3", "u", "*", "4", "M" ' Something to pick up
                IF numItems < MAX_ITEMS THEN
                    numItems = numItems + 1
                    itemX(numItems) = x + 0.5 : itemY(numItems) = y + 0.5 : itemOn(numItems) = -1
                    itemKind(numItems) = INSTR("rby+ae23u*4M", cell$)
                END IF
            CASE "o", "i", "p", "t" ' A decoration
                IF numDecos < MAX_DECO THEN
                    numDecos = numDecos + 1 : decoCell(x, y) = numDecos
                    decoX(numDecos) = x + 0.5 : decoY(numDecos) = y + 0.5 : decoKind(numDecos) = INSTR("oipt", cell$) : decoOn(numDecos) = -1 : decoFuse(numDecos) = 0
                    decoHP(numDecos) = DecoMaxHP(decoKind(numDecos)) : decoTimer(numDecos) = 0
                END IF
            CASE "m", "g", "h", "c", "s" ' A monster
                IF numMonsters < MAX_MON THEN
                    numMonsters = numMonsters + 1
                    monsterX(numMonsters) = x + 0.5 : monsterY(numMonsters) = y + 0.5 : monsterType(numMonsters) = INSTR("mghcs", cell$)
                    monsterHP(numMonsters) = mtypeHP(monsterType(numMonsters)) : monsterState(numMonsters) = 0 : monsterTimer(numMonsters) = 0 : monsterHurt(numMonsters) = 0
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
NEXT
FOR y = 0 TO MAP_SIZE - 1 : FOR x = 0 TO MAP_SIZE - 1
    IF worldMap(x, y) = 2 AND doorType(x, y) = DOOR_EXIT THEN AddLight x + 0.5, y + 0.5, 3.5, 50, 160, 70, FX_PULSE, 0
NEXT : NEXT
BuildLights ' Which cells each light reaches (now the walls are all in place)
' The camera plane (chapter 8): your direction turned 90 degrees, fovPlane long
planeX = dirY * fovPlane : planeY = - dirX * fovPlane
aimAmount = 0 : zoom = 1 : viewH = RENDER_H
kills = 0 : dead = 0 : swapTimer = 0
hurtFlash = 0 : pickFlash = 0 : muzzleFlash = 0 : recoil = 0 : railBeam = 0
fireWait = 20 ' (so the click that started the level doesn't fire)
bobPhase = 0 : stepDist = STEP_LEN * 0.85 ' The first footstep sounds soon after you start walking
levelStart! = TIMER : shake = 0 : hurtFromX = -1
FOR i = 1 TO MAX_HURTDIRS : hurtDirTime(i) = 0 : NEXT
PlayMusic levelMusic&(level)
ShowMsg levelName$ + "  -  find the EXIT"
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
' read and edit it too. Key bindings work the same way (KeyHeld, chapter
' 23, is how the game asks about a key).
'
' SAVED GAMES are BINARY files. PUT writes a variable's bytes into the file
' and GET reads them back, so LoadGame just GETs the very same variables,
' in the very same order, that SaveGame PUT. A save holds the level you're
' on and everything that has changed since it started: you, your gear,
' every door, pickup, monster and decoration. Loading rebuilds the level
' from its map (LoadLevel, chapter 20) and then puts all of that back.

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
_MOUSESHOW
IF menuInGame THEN menuBackdrop& = _COPYIMAGE(0) ELSE PlayMusic menuMusic&
menuDepth = 0 : menuScreen = SCR_MAIN : GOSUB EnterMenuScreen
menuDone = 0 : menuCapture = 0 : menuDrag = 0 : mouseWasDown = -1
_KEYCLEAR
DO
    _LIMIT 60
    menuT = menuT + 1

    ' The keyboard: every press since last frame, one at a time
    keyCode& = _KEYHIT
    DO WHILE keyCode& <> 0 AND NOT menuDone
        IF keyCode& > 0 THEN ' (a negative code is a key being let go)
            IF menuCapture THEN
                GOSUB CaptureKey
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
    mouseX = _MOUSEX : mouseY = _MOUSEY : mouseDown = _MOUSEBUTTON(1)
    IF NOT menuDone AND menuCapture = 0 THEN
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
                    IF miKind(overItem) = MI_CHOICE AND mouseX < MENU_WIDGET_X + MENU_WIDGET_W / 2 THEN menuAdjust = -1 ELSE menuAdjust = 1
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
            CASE MA_SAVE
                saveSlot = miRef(menuSel) : GOSUB SaveGame : menuDone = -1
            CASE MA_LOAD
                saveSlot = miRef(menuSel) : GOSUB LoadGame
                IF loadOK THEN menuDone = -1
            CASE MA_QUIT
                SaveSettings : SYSTEM
            CASE MA_KEYS_DEFAULT
                FOR b = 1 TO NUM_BINDS : keyBind&(b) = bindDefault&(b) : NEXT
        END SELECT
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
PUT #fileNum, , numItems
FOR i = 1 TO numItems : PUT #fileNum, , itemOn(i) : NEXT
PUT #fileNum, , numMonsters
FOR i = 1 TO numMonsters
    PUT #fileNum, , monsterX(i) : PUT #fileNum, , monsterY(i) : PUT #fileNum, , monsterHP(i)
    PUT #fileNum, , monsterState(i) : PUT #fileNum, , monsterTimer(i)
NEXT
PUT #fileNum, , numDecos
FOR i = 1 TO numDecos : PUT #fileNum, , decoOn(i) : PUT #fileNum, , decoHP(i) : PUT #fileNum, , decoTimer(i) : NEXT
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
' The level must have the same things in it as when it was saved
GET #fileNum, , savedCount : IF savedCount <> numItems THEN GOSUB LoadMismatch : RETURN
FOR i = 1 TO numItems : GET #fileNum, , itemOn(i) : NEXT
GET #fileNum, , savedCount : IF savedCount <> numMonsters THEN GOSUB LoadMismatch : RETURN
FOR i = 1 TO numMonsters
    GET #fileNum, , monsterX(i) : GET #fileNum, , monsterY(i) : GET #fileNum, , monsterHP(i)
    GET #fileNum, , monsterState(i) : GET #fileNum, , monsterTimer(i)
NEXT
GET #fileNum, , savedCount : IF savedCount <> numDecos THEN GOSUB LoadMismatch : RETURN
FOR i = 1 TO numDecos
    GET #fileNum, , decoOn(i) : GET #fileNum, , decoHP(i) : GET #fileNum, , decoTimer(i)
    IF NOT decoOn(i) THEN decoCell(INT(decoX(i)), INT(decoY(i))) = 0 ' Broken ones don't block
NEXT
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
' CHAPTER 22: THE LEVELS' DATA (MapData)
'-----------------------------------------------------------------------------
' The levels, Level1: to Level4:, as DATA lines. LoadLevel (chapter 20)
' reads one every time it starts or restarts; you go from one to the next
' through its exit. This chapter is the reference for making your own.
'
' Coordinates: x runs left to right (0 to MAP_SIZE - 1), y runs top to bottom
' (row 0 is the top line). Each map cell is one "tile": a wall block, a door,
' or a square of floor. You walk around in the same units (moving at 0.12
' tiles a frame), and things on the map stand in the middle of their tile.
'
' Each level is, in order:
'
' --- Part 1: its name, textures and ambient light -------------------------
'
'   DATA "SECTOR 2: REACTOR CORE"            shown as you arrive, and on the tally
'   DATA six wall pictures                   for # N C K P G, in that order
'   DATA four floor pictures                 floors 1-4 (for the zones below)
'   DATA two ceiling pictures                ceilings 1-2
'   DATA brightness, red, green, blue        the ambient light (chapter 14)
'
' (pictures from neon-caster/, 64x64; doors, keycards and the exit are the
' same in every level). On the minimap each wall kind is its picture's
' colour. The ambient light is the light every cell has before any lights
' are added: brightness 0 (black) to 256 (textures in their own colours),
' tinted by red, green and blue (0-255 each; 255, 255, 255 is white).
'
' --- Part 2: floor / ceiling zones -----------------------------------------
'
' First a count, then that many lines of: x0, y0, x1, y1, floor, ceiling, shape
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
' --- Part 3: lights ----------------------------------------------------------
'
' First a count, then that many lines of:
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
' --- Part 4: the map, one string per row ------------------------------------
'
' Exactly MAP_SIZE strings of exactly MAP_SIZE characters. Anything not
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
' DOORS - closed until you face one within 2 tiles and press Space; then
' they open for good (they never close again). They block you, monsters and
' sight while mostly shut, and count as open once 80% of the way. A door
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
'
' MONSTERS - each waits where it stands until it can see you (within 14
' tiles, with no wall or shut door in the way) or until you shoot it. Then
' it hunts you for good. Numbers are in the SetMonType lines.
'   m  drone:   hovers, 3 hits. Flies straight at you (about a third of
'               your speed) and bites up close for 8-13, about once a second.
'   g  gunner:  walks, 4 hits. Keeps 3.5 to 7 tiles away (backs off if you
'               get close) and, when it can see you, fires a magenta energy
'               bolt for 9-14 every 1.5-2 s. Bolts fly straight and burst on
'               walls - you can dodge them.
'   h  heavy:   walks slowly, 10 hits. Closes in and smashes for 20-29 about
'               every 1.3 s. Big enough that a scatter blast hits it with
'               more pellets.
'   c  crawler: a small spider bot, 2 hits, low to the ground. Scuttles at
'               you at over half your speed and nips for 5-8 about twice a
'               second. They come in packs.
'   s  sentry:  a gun turret, 8 hits. Never moves; when it can see you it
'               fires a bolt for 7-11 about every second.
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
' Rules: the outer border must be all walls (nothing else stops a ray or a
' monster from leaving the map). Up to MAX_ITEMS pickups, MAX_MON monsters
' and MAX_DECO decorations; extra ones are ignored.
'
' The level kit: neon-caster/levels/levels.py builds these levels (rooms
' carved with exact 45-degree edges) and checks them - doors between walls,
' every keycard reachable before its doors, the exit reachable, textures
' present. "python3 levels.py --check" checks the DATA below as it stands;
' "--write" rebuilds it from levels.py (replacing any edits made here).
'
Level1:
' Level 1: the station. Exit: behind the red doors, in the pipe room.
DATA "SECTOR 1: NEON STATION"
DATA "wall.png", "wall2.png", "wall-concrete.png", "wall-servers.png", "wall-pipes.png", "wall-biolab.png"
DATA "floor.png", "floor-plates.png", "floor-concrete.png", "floor-lab.png"
DATA "ceiling.png", "ceiling-lights.png"
DATA 165, 225, 220, 255
DATA 5
DATA 19, 19, 28, 28, 2, 1, 0
DATA 5, 5, 21, 21, 3, 2, 0
DATA 26, 5, 42, 21, 2, 2, 0
DATA 30, 26, 42, 42, 4, 2, 0
DATA 30, 30, 42, 42, 2, 0, 3
DATA 14
DATA 23.5, 23.5, 6, 130, 210, 120, 255, 0
DATA 10.5, 2.5, 5, 150, 220, 230, 255, 1
DATA 35.5, 2.5, 5, 150, 220, 230, 255, 1
DATA 2.5, 24.5, 5, 140, 220, 230, 255, 1
DATA 24.5, 45.5, 5, 160, 220, 230, 255, 5
DATA 44.5, 24.5, 5, 140, 220, 230, 255, 0
DATA 8.5, 7.5, 5, 130, 255, 215, 170, 0
DATA 10.5, 16.5, 5, 110, 230, 230, 255, 1
DATA 34.5, 5.5, 6, 140, 110, 220, 255, 2
DATA 30.5, 14.5, 5, 110, 110, 220, 255, 2
DATA 36.5, 30.5, 7, 150, 130, 255, 160, 0
DATA 36.5, 33.5, 4, 170, 255, 50, 50, 3
DATA 10.5, 30.5, 5, 150, 255, 160, 80, 4
DATA 10.5, 39.5, 5, 130, 255, 160, 80, 4
DATA "################################################"
DATA "################################################"
DATA "###/.......................................+\###"
DATA "##/..........................................\##"
DATA "##..CCCCHCCCCCCCCCCCCCC..KKKKKKKKKYKKKKKKKKK..##"
DATA "##..C/....e\C......Ma.C..K.................K..##"
DATA "##..C.......C.........C..Y..KKK......KKK...K..##"
DATA "##..C...m...H.........C..K.oo...g.......m..K..##"
DATA "##..C.......C.....g...H..Ka................K..##"
DATA "##..C.+.....C...2.....C..KKKDKKKKKKDKKKKKDKK..##"
DATA "##..C\...../C.........C..K......K......K...K..##"
DATA "##..CCCCHCCCCCCCCCCCCCC..K......K...g..K.+.K..##"
DATA "##..C...........aCCCCCC..K.K..K.K..K...Ke..K..##"
DATA "##..C.m.....o....CCCCCC..KtK..K.D..K...K...Y..##"
DATA "##..C............CCCCCC..K..m...K..K...K...K..##"
DATA "##..C...C....C...CCCCCC..K......K......K.m.K..##"
DATA "##..H.....y......CCCCCC..K......K......K...K..##"
DATA "##..C............CCCCCC..KKKKKKKKKKDKKKKKKKK..##"
DATA "##..C...C....C...CNNNNNXNNNNNNK............K..##"
DATA "##..C..e.........CNN/......\NNK.........b..K..##"
DATA "##..C..........h.CN/..a...p.\NK..h...3.....K..##"
DATA "##..C............CN..N....N..NK............K..##"
DATA "##..CCCCCCHCCCCCCCN..........NKKKKKKKKYKKKKK..##"
DATA "##................X..........X................##"
DATA "##................N.>........N..............e.##"
DATA "##..PPPPPPRPPPPPPPN..........NGGGGGGBGGGGGGG..##"
DATA "##..PP/.........aPN..N....N..Na............G..##"
DATA "##..P/...........PN\.p.....+/N.i..e........G..##"
DATA "##..P..m.........PNN\....../NN.g...........G..##"
DATA "##..P....P..P....PNNNNNXNNNNNN...G.....G...G..##"
DATA "##..R............EP.........aG...........g.G..##"
DATA "##..P.........g..PP..........G......s......G..##"
DATA "##..P.........../PP..........G.............G..##"
DATA "##..P........../PPP..........G.............G..##"
DATA "##..PPPPHPPPPPPPPPP..........G...G..r..G...B..##"
DATA "##..P............PP..........G.............G..##"
DATA "##..P.+u.........PP..........B.............G..##"
DATA "##..P............PP...m......G....../\.....G..##"
DATA "##..P....P..P....PP..........G......\/.....G..##"
DATA "##..P............PP..........G...G.....G...G..##"
DATA "##..P.h...c.c....PP........g.G......h......G..##"
DATA "##..P...e......m.PP..........G.m...........G..##"
DATA "##..P............PP+.........G............+G..##"
DATA "##..PPPPPPPPRPPPPPPPPPPPPHPPPGGGGGGGBGGGGGGG..##"
DATA "##\........................................../##"
DATA "###\a......................................a/###"
DATA "################################################"
DATA "################################################"

Level2:
' Level 2: the reactor. Red key in the storage bay (west), yellow and
' blue in the coolant wing (east, red door); the exit is in the control
' room (north, yellow door); the armoury (south-east, blue) has the railgun.
DATA "SECTOR 2: REACTOR CORE"
DATA "wall-reactor.png", "wall-coils.png", "wall-rusty.png", "wall-control.png", "wall-hazard.png", "wall-stripes.png"
DATA "floor-glow.png", "floor-scorched.png", "floor-hazard.png", "floor-plates.png"
DATA "ceiling-vents.png", "ceiling-warning.png"
DATA 115, 255, 190, 150
DATA 11
DATA 15, 15, 32, 32, 1, 2, 0
DATA 15, 15, 22, 22, 3, 0, 1
DATA 25, 15, 32, 22, 3, 0, 2
DATA 25, 25, 32, 32, 3, 0, 3
DATA 15, 25, 22, 32, 3, 0, 4
DATA 3, 3, 13, 33, 2, 1, 0
DATA 34, 3, 45, 33, 4, 1, 0
DATA 34, 3, 45, 14, 1, 0, 2
DATA 15, 3, 32, 13, 4, 2, 0
DATA 3, 35, 45, 45, 2, 1, 0
DATA 39, 35, 45, 45, 3, 2, 0
DATA 14
DATA 24, 19.5, 7, 190, 255, 140, 50, 2
DATA 24, 28.5, 7, 190, 255, 140, 50, 2
DATA 19.5, 24, 7, 190, 255, 140, 50, 2
DATA 28.5, 24, 7, 190, 255, 140, 50, 2
DATA 24.5, 8.5, 6, 150, 255, 230, 150, 0
DATA 17.5, 11.5, 3, 180, 255, 50, 40, 3
DATA 40.5, 10.5, 6, 130, 120, 220, 255, 0
DATA 40.5, 25.5, 6, 130, 120, 220, 255, 1
DATA 8.5, 15.5, 6, 120, 230, 230, 255, 5
DATA 8.5, 28.5, 5, 120, 255, 220, 170, 0
DATA 6.5, 37.5, 4, 200, 255, 40, 30, 3
DATA 33.5, 37.5, 4, 200, 255, 40, 30, 3
DATA 20.5, 42.5, 8, 110, 255, 150, 70, 4
DATA 42.5, 40.5, 5, 170, 240, 240, 255, 0
DATA "################################################"
DATA "################################################"
DATA "##CCCCCCCCCCCCKKKKKKKKKKEKKKKKKKKKPPPPPPPPPPPPP#"
DATA "##CC/.......\CKKK/............\KKKP/........\PP#"
DATA "##C/.........\KK/.......+......\KK/..........\P#"
DATA "##C.......oo..K/.t............t.\K......y.....P#"
DATA "##C..r....o...K..................K..s.........P#"
DATA "##C...........K....K........K....K.../\.......P#"
DATA "##C...........K....K....h...K....K...\/.......P#"
DATA "##C...M.e.....K....K........K....K............P#"
DATA "##C...........K..................K......./\...P#"
DATA "##C...........K\..g...........g./K...a...\/...P#"
DATA "##C..oo.......KK\....t.....t.../KK..........s.P#"
DATA "##C...........KKK\............/KKK.../\.......P#"
DATA "##C...........KKKKKKKKKKYKKKKKKKKK...\/.......P#"
DATA "##C...........NNNNN/........\NNNNN............P#"
DATA "##C...........NNNN/..........\NNNN......./\...P#"
DATA "##C...........NNN/......a.....\NNN..o....\/m..P#"
DATA "##C...c..c....NN/...g..........\NN..o.........P#"
DATA "##C...........N/................\N.../\.......P#"
DATA "##C........o..N...............m..N...\/.......P#"
DATA "##C........o..N......../\........N............P#"
DATA "##C...........N..o..../NN\.......N......./\...P#"
DATA "##C...........N....../NNNN\......N......g\/...P#"
DATA "##C....c......D......\NNNN/......R..........o.P#"
DATA "##C...........N.......\NN/.......N.../\.......P#"
DATA "##C...........N...m....\/......o.N...\/.......P#"
DATA "##C...........N..................N............P#"
DATA "##C.o.....h...N\................/N......./\...P#"
DATA "##C...........NN\............../NN.......\/...P#"
DATA "##C...........NNN\..........g./NNN..s......b..P#"
DATA "##C.+.......u.NNNN\.....+..../NNNN............P#"
DATA "##C\........./NNNNN\......../NNNNN\.........e/P#"
DATA "##CC\......./CNNNNNNNNNNXNNNNNNNNNP\......../PP#"
DATA "##GGGGGGHGGGGGGGGGGGGGGG.GGGGGGGGGGGGGGGGGGGGGG#"
DATA "##G...................................GG/...\GG#"
DATA "##G...................................G/.....\G#"
DATA "##G...a.....m......i.........i.e......G.u.....G#"
DATA "##G...................................G.......G#"
DATA "##G.......G.....G.....G.....G.....G...G.......G#"
DATA "##G.......G.....G.....G.....G.....G...B...4...G#"
DATA "##G...................................G.......G#"
DATA "##G.............................m.....G.......G#"
DATA "##G..........+......c...^.c...........G..a..*.G#"
DATA "##G..oo.............................o.G\...../G#"
DATA "##G...................................GG\.../GG#"
DATA "##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#"
DATA "################################################"

Level3:
' Level 3: the sewers - one long tunnel at 45 degrees with water down its
' middle. Red key in the nest (left), yellow in the pump hall (red door),
' blue in the cistern; the exit is in the outflow (yellow door).
DATA "SECTOR 3: UNDERCITY"
DATA "wall-brick.png", "wall-graffiti.png", "wall-moss.png", "wall-grate.png", "wall-greenpipes.png", "wall-slime.png"
DATA "floor-cobbles.png", "floor-murky.png", "floor-rustgrate.png", "floor-concrete.png"
DATA "ceiling-stone.png", "ceiling-pipes.png"
DATA 80, 170, 230, 190
DATA 9
DATA 2, 3, 44, 45, 2, 0, 2
DATA 3, 2, 45, 44, 1, 0, 2
DATA 12, 3, 22, 7, 4, 2, 0
DATA 26, 3, 45, 14, 3, 2, 0
DATA 34, 18, 45, 28, 2, 1, 0
DATA 3, 12, 7, 22, 4, 1, 0
DATA 3, 26, 14, 45, 2, 1, 0
DATA 3, 26, 14, 37, 4, 0, 1
DATA 18, 34, 28, 45, 3, 2, 0
DATA 9
DATA 12.5, 12.5, 5, 120, 120, 255, 140, 2
DATA 36.5, 36.5, 5, 120, 120, 255, 140, 2
DATA 17.5, 5.5, 5, 140, 255, 210, 150, 1
DATA 35.5, 10.5, 8, 140, 200, 255, 200, 0
DATA 43.5, 6.5, 3, 190, 255, 50, 40, 3
DATA 37.5, 26.5, 6, 130, 120, 230, 255, 2
DATA 5.5, 17.5, 4, 110, 255, 80, 60, 4
DATA 8.5, 35.5, 7, 120, 140, 220, 255, 5
DATA 23.5, 40.5, 6, 160, 230, 230, 255, 1
DATA "################################################"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CC...\CCCC#...........#PPPP/..............\PPP#"
DATA "#CC....\CCC#..u.....g..#PPP/................\PP#"
DATA "#CC..>....D.......e....#PP/..oo...h........y.\P#"
DATA "#CC\.....\C#.M..o....a.#PP..g.................P#"
DATA "#CCC\.....\#...........#PP..../\.../\.../\....P#"
DATA "#CCCC\.....\############PP....\/...\/...\/....P#"
DATA "#CCCCC\..c..\CCCCCCCCCCPPP....................P#"
DATA "#CCCCCC\............R.......................s.P#"
DATA "#CCCCCCC\i....\CCCCCCCCPPP....................P#"
DATA "#CC.....C\.....\CCCCCCCPPP\t.....t....g...a../P#"
DATA "#CC.....D.....c.\CCCCCCPPPP\................/PP#"
DATA "#CC..+..CCC\.....\CCCCCPPPPP\............../PPP#"
DATA "#CC.c...CCCC\o....\CCCCPPPPPPPPPPPPPPPPP.PPPPPP#"
DATA "#CC.....CCCCC\....i\CCCCCCCCCCCCCGGGGGGGHGGGGGG#"
DATA "#CC...c.CCCCCC\....a\CCCCCCCCCCCCGGGGGGG.GGGGGG#"
DATA "#CC.....CCCCCCC\.c...\CCCCCCCCCCCGG/........\GG#"
DATA "#CC.c...CCCCCCCC\.....\CCCCCCCCCCG/m........m\G#"
DATA "#CC...c.CCCCCCCCC\.....\CCCCCCCCCG............G#"
DATA "#CC..r..CCCCCCCCCC\...m.\CCCCCCCCG...../\.....G#"
DATA "#CC.....CCCCCCCCCCC\....i\CCCCCCCG..../GG\....G#"
DATA "#CCCCCCCCCCCCCCCCCCC\....o\CCCCCCG.e..\GG/....G#"
DATA "#CCCCCCCCCCCCCCCCCCCC\.........D.......\/.....G#"
DATA "#KKKKKKKKKKKKKKKCCCCCC\.....\CCCCG............G#"
DATA "#KKK/........\KKCCCCCCC\.....\CCCG............G#"
DATA "#KK/a.........\KCCCCCCCC\.....\CCG\.g.......b/G#"
DATA "#KK..........e......B......c...\CGG\......../GG#"
DATA "#KK............KCCCCCCCCCC\.....\GGGGGGGGGGGGGG#"
DATA "#KK............KCCCCCCCCCCC\.....\CCCCCCCCCCCCC#"
DATA "#KK...#....#...KCCCCCCCCCCCC\.m...\CCCCCCCCCCCC#"
DATA "#KK............KCCCCCCCCCCCCC\.....\CCCCCCCCCCC#"
DATA "#KK.....h......KCNNNNNNNNNNNNN\i....\CCCCCCCCCC#"
DATA "#KK............KCNN/.......\NNC\...c.\CCCCCCCCC#"
DATA "#KK............KCN/.........\NCC\.....\CCCCCCCC#"
DATA "#KK...#....#...KCN..h......g.NCCC\.....\CCCCCCC#"
DATA "#KK............KCN...........NCCCC\.o...\CCCCCC#"
DATA "#KK.....p......KCN.............Y........i\CCCCC#"
DATA "#KK............KCN...........NCCCCCC\.....\CCCC#"
DATA "#KK............KCN...........NCCCCCCC\c....\CCC#"
DATA "#KK...#....#...KCN......s....NCCCCCCCC\....+\CC#"
DATA "#KK......h.....KCN...........NCCCCCCCCC\.m...CC#"
DATA "#KK............KCN..........aNCCCCCCCCCC\....CC#"
DATA "#KK\*........u/KCN\+......../NCCCCCCCCCCC\.c.CC#"
DATA "#KKK\......../KKCNN\......./NNCCCCCCCCCCCCCCCCC#"
DATA "#KKKKKKKKKKKKKKKCNNNNNNENNNNNNCCCCCCCCCCCCCCCCC#"
DATA "################################################"

Level4:
' Level 4: the lab. A diamond atrium and four labs: SW (open) has the
' red key, NW (red) blue, SE (blue) yellow, and NE (yellow) the exit.
DATA "SECTOR 4: CRYO LAB"
DATA "wall-white.png", "wall-terminals.png", "wall-frost.png", "wall-tiles.png", "wall-cryo.png", "wall-ice.png"
DATA "floor-white.png", "floor-frostgrate.png", "floor-ice.png", "floor-lab.png"
DATA "ceiling-lights.png", "ceiling-frost.png"
DATA 175, 200, 225, 255
DATA 11
DATA 2, 2, 45, 45, 2, 2, 0
DATA 12, 12, 36, 36, 1, 1, 0
DATA 16, 16, 32, 32, 4, 0, 0
DATA 16, 16, 23, 23, 1, 0, 1
DATA 25, 16, 32, 23, 1, 0, 2
DATA 25, 25, 32, 32, 1, 0, 3
DATA 16, 25, 23, 32, 1, 0, 4
DATA 3, 3, 15, 15, 4, 1, 0
DATA 33, 3, 45, 15, 1, 1, 0
DATA 3, 33, 15, 45, 4, 1, 0
DATA 33, 33, 45, 45, 3, 2, 0
DATA 10
DATA 24, 28.5, 7, 160, 120, 230, 255, 2
DATA 24, 19.5, 7, 160, 120, 230, 255, 2
DATA 9.5, 9.5, 6, 150, 240, 240, 255, 0
DATA 39.5, 9.5, 6, 150, 120, 230, 255, 0
DATA 9.5, 39.5, 6, 150, 240, 240, 255, 1
DATA 36.5, 42.5, 6, 150, 140, 180, 255, 2
DATA 24.5, 5.5, 5, 140, 230, 240, 255, 1
DATA 24.5, 43.5, 5, 140, 230, 240, 255, 0
DATA 5.5, 24.5, 4, 180, 255, 50, 40, 3
DATA 43.5, 24.5, 5, 140, 230, 240, 255, 5
DATA "################################################"
DATA "###############KKKKKKKKKKKKKKKKKPPPPPPPPPPPPPPPP"
DATA "###############KKKKKKKKKKKKKKKKKPPPPPPPEPPPPPPPP"
DATA "#####/.......\#KKK.............KPPP/.......\PPPP"
DATA "####/.........\KKK..i......c...KPP/.+.....a.\PPP"
DATA "###/.b......s..\KK.............KP/.....h.....\PP"
DATA "###.............KK.e..m.....i..KP.............PP"
DATA "###..............R.............Y.....P...P....PP"
DATA "###......h......KKKKKKKK.KKKKKKKP.............PP"
DATA "###.t...........KKKKKKKK.KKKKKKKP..s........s.PP"
DATA "###.............########X#######P.............PP"
DATA "###.........u...CCCCCCCC.CCCCCCCP....P...P....PP"
DATA "###...g.........CCCCCCC/.CCCCCCCP.............PP"
DATA "###\....a....t./CCCCCC/..\CCCCCCP\t....g....t/PP"
DATA "####\........./CCCCCC/....\CCCCCPP\........./PPP"
DATA "#KKKK\......./CCCCCC/...p..\CCCCPPP\......./PPPP"
DATA "#KKKKKK.KK#CCCCCCCC/........\CCCPPPPPPPPP.PPPPPP"
DATA "#KKKKKKRKK#CCCCCCC/..........\CCCCCCCC#KKYKKKKKK"
DATA "#KK.....KK#CCCCCC/......+.....\CCCCCCC#KK.....KK"
DATA "#KK.....KK#CCCCC/..............\CCCCCC#KK.....KK"
DATA "#KK.i...KK#CCCC/....g.......h...\CCCCC#KK...i.KK"
DATA "#KK.....KK#CCC/..................\CCCC#KK.+...KK"
DATA "#KK.....KK#CC/........./\.........\CCC#KK.....KK"
DATA "#KK.....KK#C/........./NN\.........\CC#KK.....KK"
DATA "#KK.g.....X....p..c...\NN/....c..p./..X.......KK"
DATA "#KK.....KK#CC\.........\/........./CCC#KK...g.KK"
DATA "#KK.....KK#CCC\................../CCCC#KK.....KK"
DATA "#KK.....KK#CCCC\................/CCCCC#KK.....KK"
DATA "#KK...i.KK#CCCCC\...s.......g../CCCCCC#KK.i...KK"
DATA "#KK..a..KK#CCCCCC\............/CCCCCCC#KK.....KK"
DATA "#KK.....KK#CCCCCCC\.....m..../CCCCCCCC#KK.....KK"
DATA "#KKKKKKDKK#CCCCCCCC\.....a../CCCCCCCCC#KKBKKKKKK"
DATA "#KKKKKK.KK#CCCCCCCCC\....../CCCCGGGGGGGGG.GGGGGG"
DATA "#KKKK/.......\CCCCCCC\..p./CCCCCGGG/.......\GGGG"
DATA "####/.........\CCCCCCC\../CCCCCCGG/.........\GGG"
DATA "###/.......t...\CCCCCCC\/CCCCCCCG/..h........\GG"
DATA "###..g..e.......CCCCCCCC.CCCCCCCG...........s.GG"
DATA "###.............CCCCCCCC.CCCCCCCG..a../\......GG"
DATA "###...M.........########X#######G..../GG\.....GG"
DATA "###.........m...KKKKKKKK.KKKKKKKG....\GG/.....GG"
DATA "###.t...........KKKKKKKK.KKKKKKKG.....\/...*..GG"
DATA "###..........+...D.............B..............GG"
DATA "###...r.........KK..i.m.....i..KG....c.....y..GG"
DATA "###\.........../KK......^......KG\.........../GG"
DATA "####\....c...c/KKK.a.........e.KGG\g......../GGG"
DATA "#####\......./#KKK.............KGGG\......./GGGG"
DATA "###############KKKKKKKKKKKKKKKKKGGGGGGGGGGGGGGGG"
DATA "###############KKKKKKKKKKKKKKKKKGGGGGGGGGGGGGGGG"

'-----------------------------------------------------------------------------
' CHAPTER 23: THE HELPERS
'-----------------------------------------------------------------------------
' The SUBs and FUNCTIONs the rest of the game calls, grouped by what they're
' for. QB64PE doesn't mind what order they're in, and each one only sees its
' own variables (plus the DIM SHARED ones, and anything it lists as SHARED).

' === PICTURES AND COLOUR ======================================================

' A 64 x 64 texture from neon-caster/ into texture slot `slot`. The picture
' is first drawn into a 64 x 64 image with _PUTIMAGE, which squashes any size
' to fit; then POINT reads its pixels into the array. POINT is slow, but this
' only happens while loading.
SUB LoadTex(file$, slot AS INTEGER)
    texName$(slot) = LCASE$(file$) ' (what it is, for OpenGL's effects - chapter 24)
    path$ = AssetPath$(file$)
    img& = _LOADIMAGE(path$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; path$ : SLEEP : SYSTEM
    tex& = _NEWIMAGE(TEX_SIZE, TEX_SIZE, 32) : _PUTIMAGE, img&, tex&
    _SOURCE tex&
    FOR y = 0 TO TEX_SIZE - 1 : FOR x = 0 TO TEX_SIZE-1 : texture(x, y, slot) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0 : _FREEIMAGE img& : _FREEIMAGE tex&
END SUB

' A sprite picture from neon-caster/ into spriteTex slot `slot` (up to
' SPR_TEX pixels square - bigger pictures are shrunk). Pixels keep their
' alpha, so the sprite drawing (chapter 16) can skip the see-through ones.
SUB LoadSprite(file$, slot)
    path$ = AssetPath$(file$)
    img& = _LOADIMAGE(path$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; path$ : SLEEP : SYSTEM
    sprSize = _WIDTH(img&) : IF sprSize > SPR_TEX THEN sprSize = SPR_TEX
    spriteSize(slot) = sprSize
    _SOURCE img&
    FOR y = 0 TO sprSize - 1 : FOR x = 0 TO sprSize-1
        spriteTex(x, y, slot) = POINT(x * _WIDTH(img&) \ sprSize, y * _HEIGHT(img&) \ sprSize)
    NEXT : NEXT
    _SOURCE 0 : _FREEIMAGE img&
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
        FOR y = 0 TO TEX_SIZE - 1 : FOR x = 0 TO TEX_SIZE-1
            texture(x, y, T_DOORK + card) = Tint~&(texture(x, y, T_DOOR), CardRGB~&(card), 0.85)
        NEXT : NEXT
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
    img& = _NEWIMAGE(TEX_SIZE, TEX_SIZE, 32)
    _DEST img&
    FOR y = 0 TO TEX_SIZE - 1 : FOR x = 0 TO TEX_SIZE - 1 : PSET (x, y), texture(x, y, T_EXIT) : NEXT : NEXT
    LINE (13, 5)-(50, 24), _RGB32(10, 40, 20), BF
    LINE (13, 5)-(50, 24), _RGB32(60, 255, 120), B
    _PRINTMODE _KEEPBACKGROUND : COLOR _RGB32(110, 255, 150) : _PRINTSTRING (16, 7), "EXIT"
    _SOURCE img&
    FOR y = 0 TO TEX_SIZE - 1 : FOR x = 0 TO TEX_SIZE - 1 : texture(x, y, T_EXIT) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0 : _DEST 0 : _FREEIMAGE img&
END SUB

' A texture's average colour, a little brighter (each wall kind's minimap
' colour)
FUNCTION MinimapColor~&(slot)
    FOR y = 0 TO TEX_SIZE - 1 STEP 2 : FOR x = 0 TO TEX_SIZE - 1 STEP 2
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
FUNCTION Walkable%(x, y)
    cellX = INT(x) : cellY = INT(y)
    IF diagCorner(cellX, cellY) THEN Walkable% = NOT InDiagonalWall(diagCorner(cellX, cellY), x - cellX, y - cellY) : EXIT FUNCTION
    deco = decoCell(cellX, cellY)
    IF deco THEN
        IF (x - decoX(deco)) ^ 2 + (y - decoY(deco)) ^ 2 < DECO_RADIUS * DECO_RADIUS THEN EXIT FUNCTION
    END IF
    Walkable% = worldMap(cellX, cellY) <= 0 OR doorOpen(cellX, cellY) > 0.8
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
    FOR i = 1 TO steps
        cellX = INT(x1 + dx * i / steps) : cellY = INT(y1 + dy * i / steps)
        IF SolidAt(x1 + dx * i / steps, y1 + dy * i / steps) THEN EXIT FUNCTION
        IF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) <= 0.8 THEN EXIT FUNCTION
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
    IF _FILEEXISTS(path$) THEN LoadSnd& = _SNDOPEN(path$)
END FUNCTION

' Play a copy of a sound (_SNDPLAYCOPY), so the same one can overlap itself
' - footsteps, a fast gun. vol! goes from 0 to 1, and is turned down by the
' SFX VOLUME setting.
SUB PlaySfx(snd&, vol!)
    IF snd& > 0 THEN _SNDPLAYCOPY snd&, vol! * setting(SET_SFX) / 100
END SUB

' A sound made at (x, y): the further it is from you at (listenX, listenY),
' the quieter (but never silent)
SUB SfxAt(snd&, x, y, listenX, listenY)
    vol! = 1 - SQR((x - listenX) ^ 2 + (y-listenY) ^ 2) / 18
    IF vol! < 0.12 THEN vol! = 0.12
    PlaySfx snd&, vol!
END SUB

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
    path$ = AssetPath$(file$)
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
            EXIT SUB
        END IF
    NEXT
END SUB

' Which sprite slot a pickup kind is drawn with
FUNCTION ItemSprite(kind)
    IF kind <= IT_REPEATER THEN ItemSprite = kind ELSE ItemSprite = 16 + kind
END FUNCTION

' How many hits a decoration kind takes before it breaks (a barrel: 1)
FUNCTION DecoMaxHP(kind)
    SELECT CASE kind
        CASE 1 : DecoMaxHP = 1 ' Barrel
        CASE 2 : DecoMaxHP = 2 ' Lamp
        CASE 3 : DecoMaxHP = 2 ' Plant
        CASE ELSE : DecoMaxHP = 4 ' Terminal
    END SELECT
END FUNCTION

' How tall a decoration kind stands (in walls)
FUNCTION DecoScale(kind)
    SELECT CASE kind
        CASE 1 : DecoScale = 0.45 ' Barrel
        CASE 2 : DecoScale = 0.85 ' Lamp
        CASE 3 : DecoScale = 0.6 ' Plant
        CASE ELSE : DecoScale = 0.55 ' Terminal
    END SELECT
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

' Show a message at the bottom of the screen for a few seconds. message$ and
' messageUntil! belong to the main program; SHARED inside a SUB lets it use
' main-program variables by name.
SUB ShowMsg(text$)
    SHARED message$, messageUntil!
    message$ = text$ : messageUntil! = TIMER + 2.5
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
FUNCTION KeyHeld%(bindNum)
    code& = keyBind&(bindNum)
    IF code& >= 97 AND code& <= 122 THEN KeyHeld% = _KEYDOWN(code&) OR _KEYDOWN(code& - 32) ELSE KeyHeld% = _KEYDOWN(code&)
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
    fovPlane = TAN(setting(SET_FOV) / 2 * 3.14159265 / 180)
    turnSpeed = setting(SET_MOUSE) * 0.0006
    IF nowPlaying& > 0 THEN _SNDVOL nowPlaying&, setting(SET_MUSIC) / 100
END SUB

' Left (-1) or right (1) on setting id: a slider moves a step (and stops at
' its ends), a choice goes round to the next one, a toggle flips
SUB ChangeSetting(id, dir)
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
        CASE SET_SFX, SET_MUSIC, SET_SPEECH, SET_XALPHA : SettingText$ = v$ + "%"
        CASE SET_FOV : SettingText$ = v$ + CHR$(248) ' (a degree sign in QB64PE's font)
        CASE SET_XSTYLE : SettingText$ = CrossStyleName$(setting(id))
        CASE SET_XCOLOR : SettingText$ = CrossColorName$(setting(id))
        CASE SET_RENDERER : IF setting(id) = 2 THEN SettingText$ = "OPENGL" ELSE SettingText$ = "SOFTWARE"
        CASE SET_SCREENFX : SettingText$ = MID$("OFF      SCANLINESCRT      ", setting(id) * 9 - 8, 9)
        CASE ELSE : SettingText$ = v$
    END SELECT
END FUNCTION

' Read the settings file, if there is one. Every setting starts at its
' default; a "name=value" line for it (with a value in range) changes it.
SUB LoadSettings
    FOR i = 1 TO NUM_SETTINGS : setting(i) = setDefault(i) : NEXT
    FOR i = 1 TO NUM_BINDS : keyBind&(i) = bindDefault&(i) : NEXT
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
            FOR i = 1 TO NUM_BINDS
                IF iniKey$ = bindKey$(i) AND v > 0 THEN keyBind&(i) = v
            NEXT
        END IF
    LOOP
    CLOSE #fileNum
END SUB

' Write every setting and key binding to the settings file
SUB SaveSettings
    MakeSaveDir
    fileNum = FREEFILE
    OPEN SaveDir$ + "settings.ini" FOR OUTPUT AS #fileNum
    PRINT #fileNum, "; NEON-CASTER settings: one name and value a line (chapter 21 explains them)"
    FOR i = 1 TO NUM_SETTINGS : PRINT #fileNum, setKey$(i) + "=" + LTRIM$(STR$(setting(i))) : NEXT
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
            AddMenuItem "LOAD GAME", MI_SUBMENU, SCR_LOAD, 0, -1, ""
            AddMenuItem "SAVE GAME", MI_SUBMENU, SCR_SAVE, 0, menuInGame, "" ' (only during a game)
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
            AddMenuItem "AUDIO", MI_SUBMENU, SCR_AUDIO, 0, -1, ""
            AddMenuItem "GAMEPLAY", MI_SUBMENU, SCR_GAMEPLAY, 0, -1, ""
            AddMenuItem "VIDEO", MI_SUBMENU, SCR_VIDEO, 0, -1, ""
            AddMenuItem "EFFECTS", MI_SUBMENU, SCR_EFFECTS, 0, -1, ""
            AddMenuItem "CONTROLS", MI_SUBMENU, SCR_CONTROLS, 0, -1, ""
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_VIDEO
            menuTitle$ = "VIDEO" : menuWide = -1
            AddSettingItem SET_RENDERER : AddSettingItem SET_RETRO : AddSettingItem SET_LOOK : AddSettingItem SET_FPS
            AddMenuItem "RETRO, LOOK UP / DOWN AND EFFECTS: OPENGL", MI_TEXT, 0, 0, 0, ""
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_EFFECTS
            menuTitle$ = "EFFECTS (OPENGL)" : menuWide = -1
            AddSettingItem SET_BUMP : AddSettingItem SET_SMOOTH : AddSettingItem SET_NEON : AddSettingItem SET_DYNLIGHT
            AddSettingItem SET_SHADOWS : AddSettingItem SET_GLOW : AddSettingItem SET_PARTICLES : AddSettingItem SET_REFLECT
            AddSettingItem SET_BLOOM : AddSettingItem SET_SCREENFX : AddSettingItem SET_HITFX
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_AUDIO
            menuTitle$ = "AUDIO" : menuWide = -1
            AddSettingItem SET_SFX : AddSettingItem SET_MUSIC : AddSettingItem SET_SPEECH
            AddMenuItem "BACK", MI_BACK, 0, 0, -1, ""
        CASE SCR_GAMEPLAY
            menuTitle$ = "GAMEPLAY" : menuWide = -1
            AddSettingItem SET_FOV : AddSettingItem SET_XSTYLE : AddSettingItem SET_XCOLOR
            AddSettingItem SET_XSIZE : AddSettingItem SET_XALPHA : AddSettingItem SET_XFEEDBACK
            AddSettingItem SET_BOB : AddSettingItem SET_SHAKE : AddSettingItem SET_HURTDIR
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
            AddMenuItem "SOUND  PWMSFXR", MI_TEXT, 0, 0, 0, ""
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
                MenuText wx, rowY, "<  " + SettingText$(miRef(i)) + "  >", 2, col~&, 0
            CASE MI_KEY
                IF menuCapture = i THEN
                    IF (t \ 10) MOD 2 = 0 THEN MenuText wx, rowY, "PRESS A KEY", 2, _RGBA32(255, 230, 60, alpha), 0
                ELSE
                    MenuText wx, rowY, KeyName$(keyBind&(miRef(i))), 2, col~&, 0
                END IF
        END SELECT
        IF LEN(miInfo$(i)) THEN MenuText MENU_LABEL_X + 160 + slide, rowY + 9, miInfo$(i), 1, col~&, 0
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
    IF _FILEEXISTS(path$) THEN LoadMusic& = _SNDOPEN(path$)
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
    FOR cellY = 0 TO MAP_SIZE - 1 : FOR cellX = 0 TO MAP_SIZE - 1
        litR(cellX, cellY) = ambientR : litG(cellX, cellY) = ambientG : litB(cellX, cellY) = ambientB
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
                CASE 1, 3 TO 7
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
' hit effects - and in SETTINGS > VIDEO, retro resolution and looking up
' and down. Most are done with shaders: little programs the card runs for
' every corner and every pixel (GLBuildShaders, near the end of the
' chapter, explains them).
'
' What's different? The view is drawn at the window's full size, not half
' size, so its edges are sharp (the textures stay chunky). Sprites can't
' be lit brighter than their picture (a colour can't go past 1 on the
' card). Otherwise, it's the same game - same maths, same light.
SUB _GL
    IF NOT glReady THEN EXIT SUB ' Nothing to draw (or the software renderer is on)
    glStart# = TIMER(0.001)
    b = glBuf ' The newest finished snapshot
    IF glTexDone <> glTexVersion THEN GLSendTextures : GLBuildMesh ' (a new level)
    IF glWorldTried = 0 THEN GLBuildShaders
    glGPU = (glWorldProg <> 0 AND glMeshBuf <> 0) ' The world mesh, lit by the shader from the light tables

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

    ' POST-PROCESSING. With BLOOM, a SCREEN FX, HIT FX or RETRO RESOLUTION
    ' on, the 3D view isn't drawn on the window but into a texture (a
    ' "render target", from the GLSL library) - so that afterwards a shader
    ' can read the finished picture and do things to all of it at once
    ' (GLPostProcess). RETRO RESOLUTION draws it at the software renderer's
    ' 400 x 300 and blows it up with square pixels, as chapter 17 does.
    glPost = 0
    IF glPostProg <> 0 THEN
        IF glSet(SET_BLOOM, b) OR glSet(SET_SCREENFX, b) > 1 OR glSet(SET_HITFX, b) OR glSet(SET_RETRO, b) THEN glPost = -1
    END IF
    IF glPost THEN
        sw = vw : sh = vh
        IF glSet(SET_RETRO, b) THEN sw = RENDER_W : sh = RENDER_H
        IF NOT GLMakeTargets(sw, sh, glSet(SET_RETRO, b) <> 0) THEN glPost = 0
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
    halfW# = glPlaneLen(b) * GL_NEAR : halfH# = GL_NEAR / (2 * glZoom(b))
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
    glEyeX = glCamX(b) : glEyeY = glCamY(b) : glEyeDX = glDirX(b) : glEyeDY = glDirY(b)
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
        GLPostProcess b, vx, vy, vw, vh, sw, sh
    ELSE
        GLDrawHUD
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
    glMat(1) = 0 : glMat(5) = 0 : glMat(9) = 1 : glMat(13) = -0.5
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
    glCellLitMode = 1
    GLSL_buffer_bind glMeshBuf
    n& = glMeshN
    _glVertexPointer 3, _GL_FLOAT, 0, 0 ' (offsets into the mesh: positions first...)
    _glTexCoordPointer 2, _GL_FLOAT, 0, n& * 12 ' (...then texture spots, normals, tangents)
    _glNormalPointer _GL_FLOAT, 0, n& * 20
    GLSL_attrib_array glTanLoc, 3, n& * 32
    GLSL_attrib_off glLightLoc : GLSL_attrib_off glDynLoc
    _glDisableClientState _GL_COLOR_ARRAY : _glColor4f 1, 1, 1, 1 ' (the light comes from the tables)
    FOR kind = 0 TO 2 ' Floors (not in the mirror - it's under them), ceilings, walls
        IF kind = 0 AND mirror THEN GOTO NextKind
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

    ' The doors: each side of each door cell, built now (they slide and lift)
    FOR k = 1 TO glNumDoors
        FOR side = 1 TO 4 : GLFace glDoorCX(k), glDoorCY(k), side, b : NEXT
    NEXT
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
            glMeshKind = 0 : glFaceNZ = 1 : GLFlat cx, cy, 0, floorTex(cx, cy), floorTex2(cx, cy), floorSplit(cx, cy)
            glMeshKind = 1 : glFaceNZ = -1 : GLFlat cx, cy, 1, ceilTex(cx, cy), ceilTex2(cx, cy), ceilSplit(cx, cy)
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
    glMeshBuilding = 0
    n& = glMeshN
    ' Counting sort, by kind * (number of textures) + texture
    FOR kind = 0 TO 2 : FOR slot = 0 TO GL_GLOW_TEX : glMeshCount(kind, slot) = 0 : NEXT : NEXT
    FOR i& = 0 TO n& - 1 : glMeshCount(glMBKind(i&), glMBSlot(i&)) = glMeshCount(glMBKind(i&), glMBSlot(i&)) + 1 : NEXT
    at& = 0
    FOR kind = 0 TO 2 : FOR slot = 0 TO GL_GLOW_TEX
        glMeshFirst(kind, slot) = at& : at& = at& + glMeshCount(kind, slot)
    NEXT : NEXT
    FOR kind = 0 TO 2 : FOR slot = 0 TO GL_GLOW_TEX : glSlotFill(slot) = glMeshFirst(kind, slot) : NEXT
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
    IF n& > 0 THEN glMeshBuf = GLSL_buffer_new~&(_OFFSET(glMeshData(0)), n& * 44) ' (11 numbers, 44 bytes, a corner)
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
                    GLFlat cx, cy, 0, floorTex(cx, cy), floorTex2(cx, cy), floorSplit(cx, cy)
                ELSE
                    glFaceNZ = -1 ' (...the ceiling down)
                    GLFlat cx, cy, 1, ceilTex(cx, cy), ceilTex2(cx, cy), ceilSplit(cx, cy)
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
        uv = spriteSize(slot) / SPR_TEX ' (a smaller picture uses only part of its 64 x 64)
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

    ' Glows: a soft round spot facing you, ADDED to what's behind it
    ' (_glBlendFunc with _GL_ONE) instead of covering it - light adds up, so
    ' it brightens and tints whatever is there, like real glare. They're
    ' hidden by anything in front (the depth test) but don't hide anything
    ' themselves (_glDepthMask off), so they overlap without seams.
    ' Particles - sparks, embers, dust - are tiny glows.
    _glEnable _GL_BLEND : _glBlendFunc _GL_SRC_ALPHA, _GL_ONE : _glDepthMask _GL_FALSE
    IF glSet(SET_GLOW, b) THEN
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
        IF slot = S_BOLT OR slot = S_BLAST THEN GOTO NextShadow ' (they glow)
        sx = glSprX(i, b) : sy = glSprY(i, b) : cx = INT(sx) : cy = INT(sy)
        strength = glLitDir(cx, cy, b) * 1.2 : IF strength > 0.65 THEN strength = 0.65
        lx = glLitCX(cx, cy, b) : ly = glLitCY(cx, cy, b)
        dx = sx - lx : dy = sy - ly : d = SQR(dx * dx + dy * dy)
        IF strength < 0.08 OR d < 0.15 THEN GOTO NextShadow
        sideX = -dy / d : sideY = dx / d ' (across the shadow: square to the light)
        hw = glSprHalfW(i, b) : zLow = glSprLift(i, b) : zHigh = zLow + glSprH(i, b)
        lz = GL_LIGHT_Z * 2
        IF zHigh > lz * 0.7 THEN zHigh = lz * 0.7 ' (or it would stretch forever)
        uv = spriteSize(slot) / SPR_TEX
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

' Make (or resize) the render targets for post-processing: the scene, w x
' h with a depth buffer, read with square pixels for RETRO RESOLUTION; and
' two quarter-size ones the bloom is blurred between. FALSE if the driver
' can't (then the view goes straight to the window, without post effects).
FUNCTION GLMakeTargets(w, h, retro)
    IF glTargScene = 0 THEN
        IF NOT GLSL_targets_supported% THEN glPostProg = 0 : EXIT FUNCTION
        glTargScene = GLSL_target_new&(w, h, -1) : glTargA = GLSL_target_new&(w \ 4 + 1, h \ 4 + 1, 0) : glTargB = GLSL_target_new&(w \ 4 + 1, h \ 4 + 1, 0)
        IF glTargScene = 0 OR glTargA = 0 OR glTargB = 0 THEN glShaderError$ = GLSL_error$ : glPostProg = 0 : EXIT FUNCTION
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
' and the HUD goes in between, so a CRT curves it too.
SUB GLPostProcess(b, vx, vy, vw, vh, sw, sh)
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

    ' The final picture: scene (unit 0), bloom (unit 1), HUD (unit 2)
    _glViewport vx, vy, vw, vh
    GLSL_texture_unit 2 : hudTex~& = GLSL_filter_texture~&(0)
    GLSL_texture_unit 1 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargA)
    GLSL_texture_unit 0 : _glBindTexture _GL_TEXTURE_2D, GLSL_target_texture~&(glTargScene)
    p~& = glPostProg
    GLSL_use p~&
    GLSL_uniform_1i p~&, "scene", 0 : GLSL_uniform_1i p~&, "bloom", 1 : GLSL_uniform_1i p~&, "hud", 2
    GLSL_uniform_1f p~&, "hudOn", (hudTex~& <> 0) * -1
    GLSL_uniform_1f p~&, "bloomAmt", bloomOn * -0.9
    GLSL_uniform_1f p~&, "fxMode", glSet(SET_SCREENFX, b) - 1
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
    sx = 0.5 + 0.5 * rx / (depth * glPlaneLen(b)) : sy = 0.5 + up2 * glZoom(b) / depth
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
' names 1-19 of glTexName(), the sprites after them, then the glow spot.
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
        FOR y = 0 TO TEX_SIZE - 1 : FOR x = 0 TO TEX_SIZE - 1
            col~& = texture(x, y, slot)
            height = (((col~& \ 65536) AND 255) * 0.3 + ((col~& \ 256) AND 255) * 0.59 + (col~& AND 255) * 0.11)
            glUpload(y * TEX_SIZE + x) = (col~& AND &HFFFFFF) OR _SHL(INT(height) AND 255, 24)
        NEXT : NEXT
        GLSendPicture glTexName(slot), TEX_SIZE, _OFFSET(glUpload(0))
        n$ = texName$(slot)
        glTexShine(slot) = 0.2 : glTexReflect(slot) = 0 : glTexNeon(slot) = 1 : glTexAnim(slot) = 0
        IF slot >= T_DOOR AND slot <= T_SPLIT THEN glTexShine(slot) = 0.6
        IF INSTR(n$, "plates") OR INSTR(n$, "grate") OR INSTR(n$, "pipes") OR INSTR(n$, "coils") THEN glTexShine(slot) = 0.5
        IF INSTR(n$, "ice") OR INSTR(n$, "frost") OR INSTR(n$, "cryo") THEN glTexShine(slot) = 0.7
        IF slot > T_FLOOR AND slot <= T_FLOOR + 4 THEN ' Floors: how wet
            glTexReflect(slot) = 0.16 : glTexNeon(slot) = 0.5
            IF INSTR(n$, "ice") THEN glTexReflect(slot) = 0.45
            IF INSTR(n$, "murky") THEN glTexReflect(slot) = 0.4
            IF INSTR(n$, "glow") OR INSTR(n$, "frost") THEN glTexReflect(slot) = 0.32
            IF INSTR(n$, "white") OR INSTR(n$, "lab") OR INSTR(n$, "plates") THEN glTexReflect(slot) = 0.28
            IF INSTR(n$, "concrete") OR INSTR(n$, "cobbles") OR INSTR(n$, "scorched") THEN glTexReflect(slot) = 0.08
            IF INSTR(n$, "glow") THEN glTexNeon(slot) = 1
        END IF
        IF slot > T_CEIL THEN glTexShine(slot) = 0.1
        IF INSTR(n$, "white") OR INSTR(n$, "ice") OR INSTR(n$, "frost") THEN glTexNeon(slot) = 0 ' (white isn't neon)
        IF INSTR(n$, "brick") OR INSTR(n$, "rust") OR INSTR(n$, "moss") OR INSTR(n$, "biolab") OR INSTR(n$, "slime") THEN glTexNeon(slot) = 0.35 ' (nor rust and slime, much)
        IF INSTR(n$, "servers") OR INSTR(n$, "terminals") OR INSTR(n$, "control") THEN glTexAnim(slot) = 1
        IF INSTR(n$, "hazard") OR INSTR(n$, "stripes") OR INSTR(n$, "warning") THEN glTexAnim(slot) = 2
        IF INSTR(n$, "glow") OR INSTR(n$, "lights") OR INSTR(n$, "reactor") OR INSTR(n$, "cryo") OR INSTR(n$, "coils") THEN glTexAnim(slot) = 3
        IF slot = T_EXIT THEN glTexAnim(slot) = 3
    NEXT
    FOR slot = 1 TO SPR_SLOTS
        GLSendPicture glTexName(T_SLOTS + slot), SPR_TEX, _OFFSET(spriteTex(0, 0, slot))
        glTexShine(T_SLOTS + slot) = 0.3 : glTexReflect(T_SLOTS + slot) = 0 : glTexNeon(T_SLOTS + slot) = 0.6 : glTexAnim(T_SLOTS + slot) = 0
    NEXT
    ' The glows' spot: white, see-through at its edge, solid in the middle
    FOR y = 0 TO 63 : FOR x = 0 TO 63
        d = SQR((x - 31.5) ^ 2 + (y - 31.5) ^ 2) / 32 : IF d > 1 THEN d = 1
        glUpload(y * 64 + x) = _RGBA32(255, 255, 255, 255 * (1 - d) ^ 2)
    NEXT : NEXT
    GLSendPicture glTexName(GL_GLOW_TEX), 64, _OFFSET(glUpload(0))
    glTexDone = glTexVersion
END SUB

' One square picture, size pixels across, from memory at pixelsAt. Nearest
' pixel (no smoothing), and "clamp": a texture coordinate of 1 is the last
' pixel, not the first one again.
SUB GLSendPicture(texName AS _UNSIGNED LONG, size, pixelsAt AS _OFFSET)
    _glBindTexture _GL_TEXTURE_2D, texName
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_S, _GL_CLAMP
    _glTexParameteri _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_T, _GL_CLAMP
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
            GLSL_uniform_1f p~&, "isSprite", 1 : GLSL_uniform_1f p~&, "texel", 1 / SPR_TEX
            GLSL_uniform_1f p~&, "bump", 0 : GLSL_uniform_1f p~&, "shine", 0
        ELSE
            GLSL_uniform_1f p~&, "isSprite", 0 : GLSL_uniform_1f p~&, "texel", 1 / TEX_SIZE
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
    IF worldMap(cx, cy) <> 2 THEN ' A wall
        GLStrip ax, ay, bx, by, 0, 1, u0, u1, 0, 1, 0, 1, wallTexSlot(worldMap(cx, cy))
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
    GLStrip ax, ay, bx, by, 0, 1, u0, u1, 0, 1, 0, 1, wallTexSlot(worldMap(cx, cy))
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
    fs$ = fs$ + "uniform sampler2D scene, bloom, hud;" + nl$
    fs$ = fs$ + "uniform float bloomAmt, fxMode, hurt, rail, secs, hudOn;" + nl$
    fs$ = fs$ + "uniform vec2 res;         // the window's size in pixels" + nl$
    fs$ = fs$ + "uniform vec4 heat[4];     // explosions: where (0..1), how big, how strong" + nl$
    fs$ = fs$ + "varying vec2 uv;" + nl$
    fs$ = fs$ + "vec2 curve(vec2 p) { p = p * 2.0 - 1.0; p *= 1.0 + 0.06 * dot(p.yx, p.yx); return p * 0.5 + 0.5; }" + nl$
    fs$ = fs$ + "void main() {" + nl$
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
    fs$ = fs$ + "    if (hudOn > 0.5) { vec4 h = texture2D(hud, vec2(p.x, 1.0 - p.y)); c = h.rgb + c * (1.0 - h.a); }  // the HUD (premultiplied)" + nl$
    fs$ = fs$ + "    if (fxMode > 0.5) c *= 0.82 + 0.18 * sin(p.y * res.y * 1.5708);  // scanlines" + nl$
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
    FOR k = 1 TO count
        SpawnPart PART_SPARK, x, y, z, (RND - 0.5) * 0.12, (RND - 0.5) * 0.12, 0.015 + RND * 0.06, 16 + INT(RND * 16), r / 255, g / 255, b / 255, 0.03 + RND * 0.02
    NEXT
END SUB

' Embers flying up out of an explosion (size 1: a barrel)
SUB SpawnEmbers(x, y, size)
    FOR k = 1 TO INT(26 * size) + 3
        SpawnPart PART_EMBER, x, y, 0.3 + RND * 0.3, (RND - 0.5) * 0.1, (RND - 0.5) * 0.1, 0.03 + RND * 0.07, 30 + INT(RND * 40), 1, 0.45 + RND * 0.35, 0.1, 0.04 + RND * 0.04
    NEXT
END SUB

' Dust motes drifting in the light round you, at (px, py): faint, slow,
' tinted by the light of the cell they start in - there's always a few
SUB SpawnDust(px, py)
    IF dustCount >= 70 OR RND > 0.5 THEN EXIT SUB
    x = px + (RND - 0.5) * 9 : y = py + (RND - 0.5) * 9
    IF x < 1 OR y < 1 OR x >= MAP_SIZE - 1 OR y >= MAP_SIZE - 1 THEN EXIT SUB ' (inside the map...)
    IF NOT Walkable%(x, y) THEN EXIT SUB ' (...and not in a wall)
    cx = INT(x) : cy = INT(y)
    SpawnPart PART_DUST, x, y, 0.05 + RND * 0.9, (RND - 0.5) * 0.003, (RND - 0.5) * 0.003, (RND - 0.5) * 0.002, 200 + INT(RND * 150), litR(cx, cy) / 2200, litG(cx, cy) / 2200, litB(cx, cy) / 2200, 0.018
END SUB

' Move every particle a frame on. Sparks and embers fall (embers slowly,
' they're hot and light) and bounce off the floor and walls, losing speed;
' dust just drifts.
SUB UpdateParticles
    dustCount = 0
    FOR i = 1 TO MAX_PART
        IF partLife(i) > 0 THEN
            partLife(i) = partLife(i) - 1
            IF partKind(i) = PART_DUST THEN
                dustCount = dustCount + 1
                partVX(i) = partVX(i) + (RND - 0.5) * 0.0004 : partVY(i) = partVY(i) + (RND - 0.5) * 0.0004
            ELSEIF partKind(i) = PART_EMBER THEN
                partVZ(i) = partVZ(i) - 0.0015
            ELSE
                partVZ(i) = partVZ(i) - 0.0045
            END IF
            partX(i) = partX(i) + partVX(i) : partY(i) = partY(i) + partVY(i) : partZ(i) = partZ(i) + partVZ(i)
            IF partX(i) < 1 OR partY(i) < 1 OR partX(i) >= MAP_SIZE - 1 OR partY(i) >= MAP_SIZE - 1 THEN partLife(i) = 0 : GOTO NextPart ' (off the map: gone)
            IF partZ(i) < 0.01 THEN partZ(i) = 0.01 : partVZ(i) = -partVZ(i) * 0.35 : partVX(i) = partVX(i) * 0.7 : partVY(i) = partVY(i) * 0.7
            IF partZ(i) > 0.98 THEN partZ(i) = 0.98 : partVZ(i) = -partVZ(i) * 0.3
            IF SolidAt(partX(i), partY(i)) THEN ' Back out, and bounce
                partX(i) = partX(i) - partVX(i) : partY(i) = partY(i) - partVY(i)
                partVX(i) = -partVX(i) * 0.4 : partVY(i) = -partVY(i) * 0.4
            END IF
        END IF
        NextPart:
    NEXT
END SUB

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

    n = 0
    FOR i = 1 TO MAX_PART
        IF partLife(i) > 0 THEN
            n = n + 1 : f = partLife(i) / partMax(i)
            IF partKind(i) = PART_DUST THEN f = SIN(f * 3.14159)
            glPartX(n, w) = partX(i) : glPartY(n, w) = partY(i) : glPartZ(n, w) = partZ(i) : glPartSize(n, w) = partSize(i)
            glPartR(n, w) = partR(i) * f : glPartG(n, w) = partG(i) * f : glPartB(n, w) = partB(i) * f
        END IF
    NEXT
    glNumPart(w) = n
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

'$INCLUDE:'../../../QB64_GJ_LIB/GLSL/GLSL.BM'
