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
'     19-22  game events, levels, the map format, and the helper SUBs
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
' CONTROLS
'   Mouse          look around          W A S D   walk and strafe
'   Click or Ctrl  fire                 Space     open doors, use the exit
'   1-4 or wheel   choose a gun         Esc       quit
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
_TITLE "NEON-CASTER"
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE _DISABLE
_PRINTMODE _KEEPBACKGROUND

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
' chapter 22 has the maths), and the floor and ceiling can be split the same
' way (floorSplit, ceilSplit) to paint diagonal stripes.
CONST MAP_SIZE = 48
' MINIMAP_ = where the minimap is drawn: each map cell is MINIMAP_CELL pixels
' square, and its top-left corner is at (MINIMAP_X, MINIMAP_Y) on the screen
CONST MINIMAP_CELL = 3, MINIMAP_X = 8, MINIMAP_Y = 8
CONST PLAYER_RADIUS = 0.3 ' Your body's half-width, so the camera can't touch a wall
' worldMap: 0 floor, 2 door; walls 1 (#), 3 (N), 4 (C), 5 (K), 6 (P), 7 (G):
' six kinds of wall, whose textures each level picks (see chapter 21)
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
CONST IT_ARMOR = 9, IT_BIGMED = 10, IT_RAIL = 11
' MAX_ = the most there can be: the arrays below have room for this many
CONST MAX_ITEMS = 64
DIM SHARED itemX(MAX_ITEMS) AS SINGLE, itemY(MAX_ITEMS) AS SINGLE
DIM SHARED itemKind(MAX_ITEMS) AS INTEGER, itemOn(MAX_ITEMS) AS INTEGER, numItems AS INTEGER
DIM SHARED hasCard(3) AS INTEGER

' --- Decorations: 1 barrel (explodes when shot), 2 lamp, 3 plant, 4 terminal.
' You, monsters and bolts can't pass through them; shots fly past (except
' into barrels). ---
' DECO_ = settings for decorations: DECO_RADIUS is how far from its middle a
' decoration blocks you (in cells)
CONST MAX_DECO = 64, DECO_RADIUS = 0.3
DIM SHARED decoX(MAX_DECO) AS SINGLE, decoY(MAX_DECO) AS SINGLE, decoKind(MAX_DECO) AS INTEGER
DIM SHARED decoOn(MAX_DECO) AS INTEGER, decoFuse(MAX_DECO) AS INTEGER, numDecos AS INTEGER
DIM SHARED decoCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' Which decoration stands in a cell (0 none)
' BLAST_ = explosions: how far a blast reaches (in cells), and - for the
' picture of one - up to MAX_BLASTS on show at once, each fading over
' BLAST_FRAMES frames
CONST BLAST_RADIUS = 2.2
CONST MAX_BLASTS = 8, BLAST_FRAMES = 18
DIM SHARED blastX(MAX_BLASTS) AS SINGLE, blastY(MAX_BLASTS) AS SINGLE, blastTime(MAX_BLASTS) AS INTEGER

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
' every monster in its line, recoil, sound, picture, and where its muzzle is
DIM SHARED gunName$(NUM_GUNS), gunAmmoType(NUM_GUNS), gunAmmoPerShot(NUM_GUNS), gunDelay(NUM_GUNS), gunPellets(NUM_GUNS), gunSpread(NUM_GUNS)
DIM SHARED gunDamage(NUM_GUNS), gunPierce(NUM_GUNS), gunKick(NUM_GUNS)
DIM SHARED gunSnd&(NUM_GUNS), gunImg&(NUM_GUNS), gunMuzzleX(NUM_GUNS), gunMuzzleY(NUM_GUNS), gunScale(NUM_GUNS)
'      gun name        ammo       cost delay pellets spread damage pierce recoil
SetGun 1,  "BLASTER",  AM_CELLS,  1,   16,   1,      0,     1,     0,     1
SetGun 2,  "SCATTER",  AM_SHELLS, 1,   40,   7,      0.12,  1,     0,     1.7
SetGun 3,  "REPEATER", AM_CELLS,  1,   5,    1,      0.025, 1,     0,     0.45
SetGun 4,  "RAILGUN",  AM_CELLS,  5,   55,   1,      0,     5,     -1,    2.2
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
'   25 armour, 26 big medkit, 27 railgun
CONST SPR_TEX = 64, SPR_SLOTS = 27
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
CONST RENDER_W = 400, RENDER_H = 300, TEX_SIZE = 64
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

'-----------------------------------------------------------------------------
' CHAPTER 6: LOADING THE PICTURES AND SOUNDS
'-----------------------------------------------------------------------------
' Every picture is a PNG in the neon-caster/ folder. LoadTex and LoadSprite
' (chapter 22) open one with _LOADIMAGE and copy its colours into the
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
' we keep in a & (LONG) variable and play with PlaySfx (chapter 22).
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
DIM x AS LONG, y AS LONG, texU AS LONG, texV AS LONG, texX AS LONG
DIM floorRow AS LONG, ceilRow AS LONG, drawStart AS LONG, drawEnd AS LONG
DIM savedHasGun(NUM_GUNS) ' What you had on entering the level (you get it back if you die)

moveSpeed = 0.12 ' Cells a frame
turnSpeed = 0.003 ' Mouse sensitivity: radians per mouse step
GOSUB NewGame

'-----------------------------------------------------------------------------
' CHAPTER 7: THE GAME LOOP
'-----------------------------------------------------------------------------
' Everything from here to LOOP happens once a frame, 60 times a second
' (_LIMIT 60 waits as needed so it never goes faster). Each frame:
'
'   read the mouse and keys          chapter 8
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
    '       \        |       /    length (0.66 each side of dir, set in
    '        \       | dir  /     LoadLevel) makes the view 66 degrees wide:
    '         \      |     /      a longer plane is a wider, fish-eye view.
    '          \     |    /
    '              you
    '
    ' Turning is rotating both pairs by the same small angle. The rotation
    ' formula for turning a point (x, y) by angle a is:
    '   newX = x * COS(a) - y * SIN(a)
    '   newY = x * SIN(a) + y * COS(a)
    ' (oldDirX keeps dirX's old value, since newY needs it after dirX changed.)
    '
    ' The mouse: the pointer is captured (chapter 1), so we add up how far
    ' it moved since the last frame. QB64PE queues every mouse event;
    ' WHILE _MOUSEINPUT reads them all, one at a time, until the queue is
    ' empty. A click that starts and ends between two frames would be
    ' missed by just checking the button, so "clicked" remembers it.
    mouseDX = 0 : mouseWheel = 0
    WHILE _MOUSEINPUT
        mouseDX = mouseDX + _MOUSEMOVEMENTX
        mouseWheel = mouseWheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1
    WEND
    ' _KEYDOWN takes a key code: 100305 and 100306 are the two Ctrl keys, 32 Space
    fireDown = _MOUSEBUTTON(1) OR clicked OR _KEYDOWN(100305) OR _KEYDOWN(100306)
    clicked = 0
    spaceDown = _KEYDOWN(32)

    IF dead THEN
        ' Dead: the view stays put; click or Space (after a moment) starts over
        IF TIMER - deadAt! > 1.2 AND ((fireDown AND NOT fireWas) OR (spaceDown AND NOT spaceWas)) THEN GOSUB RestartLevel
        mouseDX = 0 : mouseWheel = 0
    END IF

    mouseDX = mouseDX / DisplayScale! ' The same turn speed in a window or full screen
    turn = - mouseDX * turnSpeed
    oldDirX = dirX : dirX = dirX * COS(turn) - dirY * SIN(turn) : dirY = oldDirX * SIN(turn) + dirY * COS(turn)
    oldPlaneX = planeX : planeX = planeX * COS(turn) - planeY * SIN(turn) : planeY = oldPlaneX * SIN(turn) + planeY * COS(turn)

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
        IF _KEYDOWN(119) OR _KEYDOWN(87) THEN forward = forward + 1 ' W
        IF _KEYDOWN(115) OR _KEYDOWN(83) THEN forward = forward - 1 ' S
        IF _KEYDOWN(97) OR _KEYDOWN(65) THEN strafe = strafe - 1 ' A (strafe left)
        IF _KEYDOWN(100) OR _KEYDOWN(68) THEN strafe = strafe + 1 ' D (strafe right)
    END IF
    moveX = dirX * forward + dirY * strafe : moveY = dirY * forward - dirX * strafe
    moveLen = SQR(moveX * moveX + moveY * moveY)
    IF moveLen > 0 THEN
        moveX = moveX / moveLen * moveSpeed : moveY = moveY / moveLen * moveSpeed
        bobPhase = bobPhase + 0.2
    END IF

    ' Collision. You're a square, PLAYER_RADIUS from your middle to each
    ' side, so the camera can never get right up against a wall (it would
    ' fill the screen with one blurry texel). MoveBody (chapter 22) tries the
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
        PlaySfx sndCard&, 0.8 : ShowMsg "All keycards"
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
    ' Barrels can be hit the same way (chapter 13 blows them up), and the
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
            invDet = 1 /(planeX * dirY - dirX * planeY)
            FOR pellet = 1 TO gunPellets(currentGun)
                aim = (RND * 2 - 1) * gunSpread(currentGun) ' Across the view: -1 left edge .. 1 right
                IF gunPellets(currentGun) > 1 THEN aim = ((pellet - 1) /(gunPellets(currentGun) -1) * 2 - 1) * gunSpread(currentGun) + (RND - 0.5) * 0.02
                screenCol = INT(RENDER_W / 2 * (1 + aim)) : IF screenCol < 0 THEN screenCol = 0
                IF screenCol > RENDER_W - 1 THEN screenCol = RENDER_W-1
                ' (a piercing shot hits everything in its line that's nearer than
                ' the wall; any other shot just the nearest monster or barrel)
                bestMonster = 0 : bestBarrel = 0 : bestDist = zBuffer(screenCol)
                FOR i = 1 TO numMonsters
                    IF monsterState(i) < 2 THEN
                        relX = monsterX(i) - playerX : relY = monsterY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < RENDER_H / transformY * mtypeScale(monsterType(i)) * 0.3 THEN
                                IF gunPierce(currentGun) THEN target = i : GOSUB HitMonster ELSE bestMonster = i : bestDist = transformY
                            END IF
                        END IF
                    END IF
                NEXT
                FOR i = 1 TO numDecos
                    IF decoOn(i) AND decoKind(i) = 1 THEN
                        relX = decoX(i) - playerX : relY = decoY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < RENDER_H / transformY * DecoScale(1) * 0.35 THEN
                                IF gunPierce(currentGun) THEN
                                    IF decoFuse(i) = 0 THEN decoFuse(i) = 1
                                ELSE
                                    bestBarrel = i : bestMonster = 0 : bestDist = transformY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                IF bestMonster THEN target = bestMonster : GOSUB HitMonster
                IF bestBarrel THEN IF decoFuse(bestBarrel) = 0 THEN decoFuse(bestBarrel) = 1
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
    '              to you, checking for walls and shut doors - chapter 22)
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
                        GOSUB HurtPlayer
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
            ELSEIF NOT dead AND (boltX(i) - playerX) ^ 2 + (boltY(i) -playerY) ^ 2 < 0.35 * 0.35 THEN
                boltOn(i) = 0 : damage = boltDamage(i) : GOSUB HurtPlayer
            END IF
        END IF
    NEXT
    ' Barrels: a shot lights a fuse (decoFuse), which counts down frames and
    ' then the barrel blows up (Explode, chapter 19). A blast lights the
    ' fuses of barrels near it, so they go off in a quick chain. Explosions
    ' on show fade out over BLAST_FRAMES.
    FOR i = 1 TO numDecos
        IF decoFuse(i) > 0 THEN
            decoFuse(i) = decoFuse(i) - 1
            IF decoFuse(i) = 0 THEN barrel = i : GOSUB Explode
        END IF
    NEXT
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN blastTime(i) = blastTime(i) - 1
    NEXT
    IF railBeam > 0 THEN railBeam = railBeam - 1

    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
    IF pickFlash > 0 THEN pickFlash = pickFlash - 1

    '-------------------------------------------------------------------------
    ' CHAPTER 14: DRAWING THE FLOOR AND CEILING
    '-------------------------------------------------------------------------
    ' Now we draw the frame into pixels() - floor and ceiling first, then the
    ' walls on top of them (chapter 15), then the sprites (chapter 16).
    '
    ' The horizon is the middle row of the screen. Your eye is half a wall up
    ' from the floor, so every row below the horizon shows the floor at one
    ' fixed distance: the further down the screen, the closer the floor. By
    ' similar triangles, row y sees the floor at
    '
    '     rowDist = (RENDER_H / 2) / (y - RENDER_H / 2)
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
    ' The fog: light& goes from 256 (full colour) close up down to 0 (black)
    ' 16 cells away, and Shade~& (chapter 22) darkens each colour by it.
    rayDirX0 = dirX - planeX : rayDirY0 = dirY - planeY
    rayDirX1 = dirX + planeX : rayDirY1 = dirY + planeY
    FOR y = RENDER_H \ 2 TO RENDER_H - 1
        rowDist = (RENDER_H / 2) /(y - RENDER_H / 2 + 0.5)
        floorStepX = rowDist * (rayDirX1 - rayDirX0) / RENDER_W : floorStepY = rowDist * (rayDirY1 - rayDirY0) / RENDER_W
        floorX = playerX + rowDist * rayDirX0 : floorY = playerY + rowDist * rayDirY0
        light& = 256 - rowDist * 16
        IF light& < 0 THEN light& = 0
        floorRow = y * RENDER_W : ceilRow = (RENDER_H - 1 - y) * RENDER_W
        FOR x = 0 TO RENDER_W - 1
            cellX = INT(floorX) : cellY = INT(floorY)
            IF cellX >= 0 AND cellX < MAP_SIZE AND cellY >= 0 AND cellY < MAP_SIZE THEN
                floorSlot = floorTex(cellX, cellY) : ceilSlot = ceilTex(cellX, cellY)
                IF floorSplit(cellX, cellY) THEN IF InDiagonalWall(floorSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN floorSlot = floorTex2(cellX, cellY)
                IF ceilSplit(cellX, cellY) THEN IF InDiagonalWall(ceilSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN ceilSlot = ceilTex2(cellX, cellY)
            ELSE
                floorSlot = T_FLOOR + 1 : ceilSlot = T_CEIL + 1
            END IF
            texU = INT(floorX * TEX_SIZE) AND (TEX_SIZE - 1) : texV = INT(floorY * TEX_SIZE) AND (TEX_SIZE - 1)
            pixels(floorRow + x) = Shade~&(texture(texU, texV, floorSlot), light&)
            pixels(ceilRow + x) = Shade~&(texture(texU, texV, ceilSlot), light&)
            floorX = floorX + floorStepX : floorY = floorY + floorStepY
        NEXT
    NEXT

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
    '    RENDER_H / perpWallDist pixels tall, centred on the horizon.
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
    '   cell's diagonal (DiagonalHit, chapter 22). If it does before leaving
    '   the cell, that's the hit, at that distance; otherwise the ray is in
    '   the open half and carries on.
    FOR x = 0 TO RENDER_W - 1
        cameraX = 2 * x / RENDER_W - 1
        rayDirX = dirX + planeX * cameraX : rayDirY = dirY + planeY * cameraX
        mapX = INT(playerX) : mapY = INT(playerY)
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

        lineHeight = RENDER_H / perpWallDist
        drawStart = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2)
        texStep = TEX_SIZE / lineHeight : texPos = (drawStart - RENDER_H / 2 + lineHeight / 2) * texStep
        IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
        IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1

        ' Light: distance fog, y-sides darker, diagonals in between
        light& = 256 - perpWallDist * 16
        IF light& < 0 THEN light& = 0
        IF diagHit THEN light& = light& * 0.85 ELSE IF side = 1 THEN light& = light& * 0.7

        FOR y = drawStart TO drawEnd
            pixels(y * RENDER_W + x) = Shade~&(texture(texX, INT(texPos) AND (TEX_SIZE - 1), texSlot), light&)
            texPos = texPos + texStep
        NEXT

        ' A rising shutter in front: its lower edge has lifted shutterOpen of
        ' the way up, so draw only the part still hanging down
        IF shutterSeen THEN
            lineHeight = RENDER_H / shutterDist
            shutterTop = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2 - shutterOpen * lineHeight)
            texStep = TEX_SIZE / lineHeight : texPos = shutterOpen * TEX_SIZE
            drawStart = shutterTop
            IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
            IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1
            light& = 256 - shutterDist * 16
            IF light& < 0 THEN light& = 0
            IF shutterSide = 1 THEN light& = light& * 0.7
            texX = INT(shutterU * TEX_SIZE) AND (TEX_SIZE - 1)
            FOR y = drawStart TO drawEnd
                pixels(y * RENDER_W + x) = Shade~&(texture(texX, INT(texPos) AND (TEX_SIZE - 1), T_SHUTTER), light&)
                texPos = texPos + texStep
            NEXT
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
    '   - size: RENDER_H / transformY, like a wall slice, times its scale
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
        IF decoOn(i) THEN
            numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) : drawY(numDraw) = decoY(i)
            drawSprite(numDraw) = S_DECO + decoKind(i) : drawScale(numDraw) = DecoScale(decoKind(i)) : drawLift(numDraw) = 0
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40
            IF decoKind(i) = 2 THEN drawMinShade(numDraw) = 200 ' Lamps glow
        END IF
    NEXT
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN ' Explosions swell as they fade
            numDraw = numDraw + 1 : drawX(numDraw) = blastX(i) : drawY(numDraw) = blastY(i)
            drawSprite(numDraw) = S_BLAST : drawScale(numDraw) = 0.6 + 0.7 * (1 - blastTime(i) / BLAST_FRAMES) : drawLift(numDraw) = 0.05
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
            spriteW = INT(RENDER_H / transformY * drawScale(i)) : spriteH = INT(spriteW * drawSquash(i))
            IF spriteH < 1 THEN spriteH = 1
            spriteTop = INT(RENDER_H / 2 + (0.5 - drawLift(i)) * RENDER_H / transformY) -spriteH ' Bottom edge lifted off the floor
            spriteLeft = INT(RENDER_W / 2 * (1 + transformX / transformY)) - spriteW \ 2
            light& = 256 - transformY * 10
            IF light& < drawMinShade(i) THEN light& = drawMinShade(i)
            spriteSz = spriteSize(drawSprite(i)) : spriteSlot = drawSprite(i)
            FOR screenX = spriteLeft TO spriteLeft + spriteW - 1
                IF screenX >= 0 AND screenX < RENDER_W THEN
                    IF transformY < zBuffer(screenX) THEN
                        spriteU = (screenX - spriteLeft) * spriteSz \ spriteW
                        FOR screenY = spriteTop TO spriteTop + spriteH - 1
                            IF screenY >= 0 AND screenY < RENDER_H THEN
                                texel~& = spriteTex(spriteU,(screenY - spriteTop) * spriteSz \ spriteH, spriteSlot)
                                IF _ALPHA32(texel~&) > 128 THEN pixels(screenY * RENDER_W + screenX) = Shade~&(texel~&, light&)
                            END IF
                        NEXT
                    END IF
                END IF
            NEXT
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
    _MEMCOPY pixelsMem, pixelsMem.OFFSET, pixelsMem.SIZE TO renderMem, renderMem.OFFSET
    _PUTIMAGE (0, 0)-(799, 599), renderImg&, 0

    '-------------------------------------------------------------------------
    ' CHAPTER 18: THE GUN AND THE HUD
    '-------------------------------------------------------------------------
    ' Everything from here is drawn straight onto the window, at full size,
    ' with ordinary QB64PE graphics: _PUTIMAGE for pictures, LINE for boxes,
    ' _PRINTSTRING for text. Colours made with _RGBA32 have an alpha (0
    ' clear .. 255 solid), so a LINE ... BF over the whole screen with a low
    ' alpha tints everything: red when you're hurt, yellow for a pickup.
    '
    ' The gun sways as you walk (bobPhase, from chapter 9), kicks when it
    ' fires (recoil, which shrinks a quarter every frame), and dips out of
    ' sight to swap.
    IF recoil > 0 THEN recoil = recoil * 0.75 : IF recoil < 0.02 THEN recoil = 0
    gunImage& = gunImg&(currentGun)
    gunW = _WIDTH(gunImage&) * gunScale(currentGun) : gunH = _HEIGHT(gunImage&) * gunScale(currentGun)
    gunX = 400 - gunW * gunMuzzleX(currentGun) + COS(bobPhase / 2) * 10
    gunY = GUN_Y - gunH + ABS(SIN(bobPhase / 2)) * 10 + recoil * 36 + 12
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

    IF NOT dead THEN LINE (395, 300)-(405, 300), _RGB32(255, 0, 0) : LINE (400, 295)-(400, 305), _RGB32(255, 0, 0)
    IF hurtFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 0, 0, hurtFlash * 9), BF
    IF pickFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 255, 160, pickFlash * 4), BF
    IF godMode THEN HudText 16, 498, "GOD MODE", _RGB32(255, 215, 30)

    ' Minimap: one small square per map cell, straight from worldMap. Walls
    ' are each kind's texture colour; doors orange (key doors in their
    ' card's colour, dark centre) when shut, white while opening, green when
    ' open; the exit blinks green; then keycards, and you with a line
    ' showing which way you face.
    LINE (MINIMAP_X - 2, MINIMAP_Y - 2)-(MINIMAP_X + MAP_SIZE * MINIMAP_CELL + 1, MINIMAP_Y + MAP_SIZE * MINIMAP_CELL + 1), _RGBA32(0, 0, 0, 160), BF
    FOR mapY = 0 TO MAP_SIZE - 1 : FOR mapX = 0 TO MAP_SIZE-1
        mmColor~& = 0
        SELECT CASE worldMap(mapX, mapY)
            CASE 1, 3 TO 7 : mmColor~& = wallMapColor(worldMap(mapX, mapY))
            CASE 2
                IF doorType(mapX, mapY) = DOOR_EXIT THEN
                    IF (TIMER * 4 AND 1) = 0 THEN mmColor~& = _RGB32(80, 255, 120) ELSE mmColor~& = _RGB32(20, 120, 50)
                ELSEIF doorOpen(mapX, mapY) = 0 THEN
                    IF doorKey(mapX, mapY) THEN mmColor~& = CardRGB~&(doorKey(mapX, mapY)) ELSE mmColor~& = _RGB32(255, 140, 20)
                ELSEIF doorOpen(mapX, mapY) < 1 THEN
                    mmColor~& = _RGB32(230, 230, 230)
                ELSE
                    mmColor~& = _RGB32(40, 200, 80)
                END IF
        END SELECT
        IF mmColor~& <> 0 AND diagCorner(mapX, mapY) <> 0 THEN ' Diagonal: just its solid half
            FOR mmPixY = 0 TO MINIMAP_CELL - 1 : FOR mmPixX = 0 TO MINIMAP_CELL - 1
                IF InDiagonalWall(diagCorner(mapX, mapY), (mmPixX + 0.5) / MINIMAP_CELL, (mmPixY + 0.5) / MINIMAP_CELL) THEN PSET (MINIMAP_X + mapX * MINIMAP_CELL + mmPixX, MINIMAP_Y + mapY * MINIMAP_CELL + mmPixY), mmColor~&
            NEXT : NEXT
        ELSEIF mmColor~& THEN
            LINE (MINIMAP_X + mapX * MINIMAP_CELL, MINIMAP_Y + mapY * MINIMAP_CELL)-STEP(MINIMAP_CELL - 1, MINIMAP_CELL-1), mmColor~&, BF
            IF doorKey(mapX, mapY) AND doorOpen(mapX, mapY) = 0 THEN PSET (MINIMAP_X + mapX * MINIMAP_CELL + MINIMAP_CELL \ 2, MINIMAP_Y + mapY * MINIMAP_CELL + MINIMAP_CELL \ 2), _RGB32(0, 0, 0)
        END IF
    NEXT : NEXT
    IF (TIMER * 4 AND 1) = 0 THEN ' Keycards blink (on for a quarter second, off for one)
        FOR i = 1 TO numItems
            IF itemOn(i) AND itemKind(i) <= 3 THEN LINE (MINIMAP_X + itemX(i) * MINIMAP_CELL - 1, MINIMAP_Y + itemY(i) * MINIMAP_CELL - 1)-STEP(2, 2), CardRGB~&(itemKind(i)), BF
        NEXT
    END IF
    mmPlayerX = MINIMAP_X + playerX * MINIMAP_CELL : mmPlayerY = MINIMAP_Y + playerY * MINIMAP_CELL
    LINE (mmPlayerX, mmPlayerY)-(mmPlayerX + dirX * 6, mmPlayerY + dirY * 6), _RGB32(255, 255, 0)
    LINE (mmPlayerX - 1, mmPlayerY - 1)-STEP(2, 2), _RGB32(255, 255, 0), BF
    HudText MINIMAP_X, MINIMAP_Y + MAP_SIZE * MINIMAP_CELL + 6, "KILLS" + STR$(kills) + " /" + STR$(numMonsters), _RGB32(255, 90, 90)

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
    IF TIMER < messageUntil! AND LEN(message$) THEN
        HudText 400 - LEN(message$) * 4, 510, message$, _RGB32(255, 255, 255)
    END IF

    IF dead THEN
        LINE (0, 0)-(799, 599), _RGBA32(90, 0, 0, 110), BF
        BigText "YOU DIED", 230, 6, _RGB32(255, 60, 60)
        IF TIMER - deadAt! > 1.2 THEN HudText 400 - 15 * 8, 330, "Click or press Space to try again", _RGB32(255, 255, 255)
    END IF

    _DISPLAY ' Show the finished frame (chapter 7)
LOOP UNTIL _KEYDOWN(27) ' Esc
SYSTEM

'-----------------------------------------------------------------------------
' CHAPTER 19: GAME EVENTS
'-----------------------------------------------------------------------------
' Things that happen from more than one place - a monster getting hit (by a
' shot or a blast), you getting hurt (by a bite, a bolt, a blast), a barrel
' going off - are GOSUB routines: a label, some lines, and RETURN. Unlike a
' SUB, a GOSUB routine is part of the main program, so it can use all its
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

' --- You take `damage` (armour soaks up a third of it while it lasts)
HurtPlayer:
IF godMode THEN RETURN
absorbed = damage \ 3 : IF absorbed > armor THEN absorbed = armor
armor = armor - absorbed : damage = damage - absorbed
health = health - damage : hurtFlash = 14
IF health <= 0 THEN
    health = 0 : dead = -1 : deadAt! = TIMER
    PlaySfx sndDie&, 1 : ShowMsg ""
ELSE
    PlaySfx sndHurt&, 0.8
END IF
RETURN

' --- Barrel number `barrel` explodes: it hurts everything near it that it
' can see (more the closer it is), and lights the fuses of other barrels
' close by, so they go off a moment later
Explode:
decoOn(barrel) = 0 : decoFuse(barrel) = 0 : decoCell(INT(decoX(barrel)), INT(decoY(barrel))) = 0
SfxAt sndBarrel&, decoX(barrel), decoY(barrel), playerX, playerY
FOR j = 1 TO MAX_BLASTS
    IF blastTime(j) = 0 THEN blastX(j) = decoX(barrel) : blastY(j) = decoY(barrel) : blastTime(j) = BLAST_FRAMES : EXIT FOR
NEXT
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
    IF CanSee(decoX(barrel), decoY(barrel), playerX, playerY) THEN damage = INT(40 * (1 - distance / BLAST_RADIUS)) + 5 : GOSUB HurtPlayer
END IF
FOR j = 1 TO numDecos
    IF decoOn(j) AND decoKind(j) = 1 AND decoFuse(j) = 0 THEN
        IF (decoX(j) - decoX(barrel)) ^ 2 + (decoY(j) - decoY(barrel)) ^ 2 < BLAST_RADIUS * BLAST_RADIUS THEN decoFuse(j) = 8
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
' and drawn darkened behind the numbers.
'
' LoadLevel reads a level from the DATA lines in chapter 21. RESTORE points
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
screenshot& = _COPYIMAGE(0) : tallyStart! = TIMER
DO
    _LIMIT 30
    _PUTIMAGE , screenshot&, 0
    LINE (0, 0)-(799, 599), _RGBA32(0, 0, 0, 180), BF
    IF level = NUM_LEVELS THEN BigText "YOU ESCAPED!", 110, 5, _RGB32(80, 255, 140) ELSE BigText "SECTOR CLEAR", 110, 5, _RGB32(80, 255, 140)
    HudText 400 - LEN(levelName$) * 4, 210, levelName$, _RGB32(255, 255, 255)
    TallyLine 260, "KILLS", LTRIM$(STR$(kills)) + " / " + LTRIM$(STR$(numMonsters))
    TallyLine 285, "ITEMS", LTRIM$(STR$(taken)) + " / " + LTRIM$(STR$(numItems))
    TallyLine 310, "TIME", TimeText$(levelTime!)
    IF level = NUM_LEVELS THEN
        TallyLine 360, "TOTAL KILLS", LTRIM$(STR$(totalKills)) + " / " + LTRIM$(STR$(totalMonsters))
        TallyLine 385, "TOTAL TIME", TimeText$(totalTime!)
    END IF
    IF TIMER - tallyStart! > 1 THEN
        IF level = NUM_LEVELS THEN prompt$ = "Click or press Space to play again" ELSE prompt$ = "Click or press Space for the next sector"
        HudText 400 - LEN(prompt$) * 4, 450, prompt$, _RGB32(255, 255, 255)
    END IF
    _DISPLAY
    click = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN click = -1
    WEND
    IF _KEYDOWN(27) THEN SYSTEM
    IF TIMER - tallyStart! > 1 AND (click OR _KEYDOWN(32)) THEN EXIT DO
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
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
    worldMap(x, y) = 0 : doorOpen(x, y) = 0 : doorKey(x, y) = 0 : doorType(x, y) = 0 : diagCorner(x, y) = 0
    floorTex(x, y) = T_FLOOR + 1 : ceilTex(x, y) = T_CEIL + 1 : floorSplit(x, y) = 0 : ceilSplit(x, y) = 0 : decoCell(x, y) = 0
NEXT : NEXT
numItems = 0 : numMonsters = 0 : numDecos = 0
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
FOR k = 1 TO 7
    IF k <> 2 THEN wallMapColor(k) = MinimapColor~&(wallTexSlot(k))
NEXT
' Floor and ceiling zones (chapter 21): each paints a rectangle - or the
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
            CASE "r", "b", "y", "+", "a", "e", "2", "3", "u", "*", "4" ' Something to pick up
                IF numItems < MAX_ITEMS THEN
                    numItems = numItems + 1
                    itemX(numItems) = x + 0.5 : itemY(numItems) = y + 0.5 : itemOn(numItems) = -1
                    itemKind(numItems) = INSTR("rby+ae23u*4", cell$)
                END IF
            CASE "o", "i", "p", "t" ' A decoration
                IF numDecos < MAX_DECO THEN
                    numDecos = numDecos + 1 : decoCell(x, y) = numDecos
                    decoX(numDecos) = x + 0.5 : decoY(numDecos) = y + 0.5 : decoKind(numDecos) = INSTR("oipt", cell$) : decoOn(numDecos) = -1 : decoFuse(numDecos) = 0
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
' The camera plane (chapter 8): your direction turned 90 degrees, 0.66 long
planeX = dirY * 0.66 : planeY = - dirX * 0.66
kills = 0 : dead = 0 : swapTimer = 0
hurtFlash = 0 : pickFlash = 0 : muzzleFlash = 0 : recoil = 0 : railBeam = 0
fireWait = 20 ' (so the click that started the level doesn't fire)
bobPhase = 0 : stepDist = STEP_LEN * 0.85 ' The first footstep sounds soon after you start walking
levelStart! = TIMER
ShowMsg levelName$ + "  -  find the EXIT"
RETURN

'-----------------------------------------------------------------------------
' CHAPTER 21: THE LEVELS' DATA (MapData)
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
' --- Part 1: its name and textures ------------------------------------------
'
'   DATA "SECTOR 2: REACTOR CORE"            shown as you arrive, and on the tally
'   DATA six wall pictures                   for # N C K P G, in that order
'   DATA four floor pictures                 floors 1-4 (for the zones below)
'   DATA two ceiling pictures                ceilings 1-2
'
' (all from neon-caster/, 64x64; doors, keycards and the exit are the same
' in every level). On the minimap each wall kind is its picture's colour.
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
' --- Part 3: the map, one string per row ------------------------------------
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
' them, but they don't block sight, and shots fly past (except barrels).
'   o  barrel:   explodes when shot: up to 45 damage to you and 8 to
'                monsters within 2.2 tiles (less further away, and not
'                through walls), and sets off other barrels near it.
'   i  lamp      (it glows)
'   p  plant
'   t  terminal
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
DATA 5
DATA 19, 19, 28, 28, 2, 1, 0
DATA 5, 5, 21, 21, 3, 2, 0
DATA 26, 5, 42, 21, 2, 2, 0
DATA 30, 26, 42, 42, 4, 2, 0
DATA 30, 30, 42, 42, 2, 0, 3
DATA "################################################"
DATA "################################################"
DATA "###/.......................................+\###"
DATA "##/..........................................\##"
DATA "##..CCCCHCCCCCCCCCCCCCC..KKKKKKKKKYKKKKKKKKK..##"
DATA "##..C/....e\C.......a.C..K.................K..##"
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
DATA "################################################"
DATA "################################################"
DATA "##CCCCCCCCCCCCKKKKKKKKKKEKKKKKKKKKPPPPPPPPPPPPP#"
DATA "##CC/.......\CKKK/............\KKKP/........\PP#"
DATA "##C/.........\KK/.......+......\KK/..........\P#"
DATA "##C.......oo..K/.t............t.\K......y.....P#"
DATA "##C..r....o...K..................K..s.........P#"
DATA "##C...........K....K........K....K.../\.......P#"
DATA "##C...........K....K....h...K....K...\/.......P#"
DATA "##C.....e.....K....K........K....K............P#"
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
DATA "################################################"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CC...\CCCC#...........#PPPP/..............\PPP#"
DATA "#CC....\CCC#..u.....g..#PPP/................\PP#"
DATA "#CC..>....D.......e....#PP/..oo...h........y.\P#"
DATA "#CC\.....\C#....o....a.#PP..g.................P#"
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
DATA "###.............########X#######G..../GG\.....GG"
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
' CHAPTER 22: THE HELPERS
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
' - footsteps, a fast gun. vol! goes from 0 to 1.
SUB PlaySfx(snd&, vol!)
    IF snd& > 0 THEN _SNDPLAYCOPY snd&, vol!
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
SUB SetGun(gun, title$, ammoType, ammoPerShot, delay, pellets, spread, damage, pierce, kick)
    gunName$(gun) = title$ : gunAmmoType(gun) = ammoType : gunAmmoPerShot(gun) = ammoPerShot : gunDelay(gun) = delay
    gunPellets(gun) = pellets : gunSpread(gun) = spread : gunDamage(gun) = damage : gunPierce(gun) = pierce : gunKick(gun) = kick
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

' One line of the level-done tally: a label, and its number on the right
SUB TallyLine(y, label$, value$)
    HudText 270, y, label$, _RGB32(160, 200, 255)
    HudText 530 - LEN(value$) * 8, y, value$, _RGB32(255, 255, 255)
END SUB

' Seconds as m:ss
FUNCTION TimeText$(secs!)
    mins = INT(secs! / 60) : s = INT(secs!) MOD 60
    TimeText$ = LTRIM$(STR$(mins)) + ":" + RIGHT$("0" + LTRIM$(STR$(s)), 2)
END FUNCTION
