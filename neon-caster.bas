'=============================================================================
' NEON-CASTER - a little first-person shooter in QB64PE, written to learn from
'=============================================================================
'
' This is a whole game in plain QB64PE: this file, and the include files in
' the folders beside it. Ten levels and more, ten kinds of monster, four
' guns, doors and keycards, exploding barrels, a minimap, a level editor.
' It's also meant to be read. The comments are a course in how it works,
' chapter by chapter, from opening a window to casting rays.
'
' You'll want to know some BASIC already: variables, arrays, loops, SUBs
' and FUNCTIONs. The 3D ideas, and the QB64PE features the game leans on,
' are explained as they come up. neon-caster/TUTORIAL.md lists the chapters
' and has things to try.
'
' HOW IT'S LAID OUT
'   Like grymmjack's DRAW, the program is split by what each part is for.
'   Each folder holds a few modules; a module is a .BI file (its CONSTs and
'   DIM SHARED arrays, and any start-up that fills them in) and a .BM file
'   (its SUBs and FUNCTIONs). _ALL.BI lists every
'   .BI and _ALL.BM every .BM; this file includes _ALL.BI at the top and
'   _ALL.BM at the bottom. $INCLUDE pastes a file in where it's named, so
'   to QB64PE it's still one program.
'     CORE/    the window, the dice, settings, keys, files, small helpers
'     WORLD/   the grid: walls, doors, heights, glass, liquids, lifts
'     GAME/    you, the guns, monsters, pickups, decorations, droids, event
'              rooms, secrets, triggers, terminals, the network, NEXUS
'     LEVEL/   levels and sectors, loading one, and the level files
'     RENDER/  pictures, the 3D view's helpers, light, particles, the HUD
'     GL/      the OpenGL renderer
'     MENU/    the menu, the splash screen, the console, saved games
'     EDITOR/  the level editor, the HUD editor, the monster editor
'     AUDIO/   sounds and music
'     DEMO/    demos, and the autopilot that plays them
'     ACH/     achievements and records
'     LOOP/    the game loop's chapters, included in place below
'
' HOW TO READ IT
'   Search for "CHAPTER" to jump from one to the next. In order:
'     1      CORE/WINDOW.BI                 a window
'     2      WORLD/MAP.BI, WORLD/DOORS.BI   the world is a grid
'     3      GAME/ITEMS.BI, DECOS, EVENTS, MONSTERS (.BI)  things in it
'     4      GAME/PLAYER.BI, GAME/GUNS.BI   you
'     5      RENDER/PICTURES.BI, VIEW.BI    pictures in arrays
'     6      AUDIO/SOUND.BI, GAME/MONTYPES.BI, RENDER/PICTURES.BM
'                                           loading the pictures and sounds
'     7-18   below, and LOOP/07-FRAME.BI to LOOP/18-HUD.BI: one frame of the
'            game - input, moving, doors, shooting, monsters - then drawing
'            it: floor, walls, sprites, the screen, the HUD
'     19     GAME/EVENTS.BM                 game events
'     20     LEVEL/LEVELS.BM                levels
'     21     MENU/MENU.BM                   the splash screen, the menu,
'                                           settings and saved games
'     22     LEVEL/LEVELFILE.BM             the level files
'     23     CORE/HELPERS.BM, and the rest of the .BM files: the helpers
'     24     GL/OPENGL.BM, GL/EXTRAS.BM     the same 3D view drawn by the
'                                           graphics card, with OpenGL
'                                           (RENDERER in SETTINGS > VIDEO)
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
'   1-5 or wheel   choose a gun         Esc       the menu (pause, save,
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
'     PascalCase   a SUB or FUNCTION, like MoveBody, CanSee or HitMonster.
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
'     AM_        AMmo: which kind - AM_CELLS, AM_SHELLS, AM_ROCKETS (ch. 4)
'     W_         Weapon: which gun - W_BLASTER, W_SCATTER, W_REPEATER,
'                W_RAIL, W_ROCKET (guns are numbered 1-5)       (chapter 4)
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
'     gun...     a gun, numbered 1-5: gunName$(g), gunDamage(g)...
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

'$INCLUDE:'./_ALL.BI'

'-----------------------------------------------------------------------------
' STARTING UP
'-----------------------------------------------------------------------------
' Everything is declared (_ALL.BI, which also filled in the tables and
' loaded the sounds). Now: your settings, the sectors' names, achievements
' and records, the keyboard, the pictures - and then either the commands
' on the command line, or the splash screen and the title menu.

LoadSettings ' Your settings and keys, from neon-caster/saves/settings.ini
ReadSectorNames
AchSetup ' (achievements: Steam, or the stand-in that keeps them in saves/achievements.txt)
RecordsLoad ' (each sector's best: saves/records.txt)
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
ArtReload ' Every picture, as ART asks (chapter 6's list: LoadPictures)
' Commands on the command line (chapter 21): each starts with a + -
'   neon-caster.run +map 5 +give all +wait 60 +screenshot five.png +quit
' They skip the splash and the title, start a new game and run, one a
' frame, from its first frame.
' (All the words, joined up again and cut at each " +" - so it works the
' same when a launcher hands them over as one long word.)
ConAutoexec ' (the saves folder's autoexec.cfg: your aliases, binds and settings, every time - MENU/CONSOLE.BM)
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
    NewGame : _MOUSEHIDE : _MOUSEMOVE 400, 300
ELSE
    ShowSplash
    menuInGame = 0 : RunMenu ' The title menu: it returns once a game is started or loaded
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
    '$INCLUDE:'./LOOP/07-FRAME.BI'
    '$INCLUDE:'./LOOP/08-LOOK.BI'
    '$INCLUDE:'./LOOP/09-MOVE.BI'
    '$INCLUDE:'./LOOP/10-PICKUPS.BI'
    '$INCLUDE:'./LOOP/11-DOORS.BI'
    '$INCLUDE:'./LOOP/12-SHOOTING.BI'
    '$INCLUDE:'./LOOP/13-MONSTERS.BI'
    '$INCLUDE:'./LOOP/14-FLOORS.BI'
    '$INCLUDE:'./LOOP/15-WALLS.BI'
    '$INCLUDE:'./LOOP/16-SPRITES.BI'
    '$INCLUDE:'./LOOP/17-SCREEN.BI'
    '$INCLUDE:'./LOOP/18-HUD.BI'
LOOP ' (forever: you leave the game from the menu - chapter 21)

'$INCLUDE:'./_ALL.BM'
