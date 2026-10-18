# NEON-CASTER: make a little FPS in QB64PE

NEON-CASTER is a complete first-person shooter in plain QB64PE:
ten levels, ten kinds of monster (one of them a thief), four guns and a
kick, doors and keycards, exploding barrels, traps and event rooms, glass
you can see (and shoot) through, floors and ceilings at different heights
with lifts and pits, teleporters, data stations that turn the level into a
neon network, code terminals that lock you in until you repair a real
QB64 program, secret walls in every sector (and switches you shoot),
vending machines that pay out or blow up, NEON PONG on the computers, a
night vision headset, service droids going about their business, a
villain who talks to you through a vocoder, sound placed around you, a
minimap, music, a menu with settings, a console, saved games, DOOM-style
demos with an autopilot that plays like a person - and editors for its levels, its monsters and its HUD, inside the
game. It's built like Wolfenstein 3D, as a *raycaster*, and the
source is written to be read: its comments are a course in how it all
works, in 24 chapters, from opening a window to casting rays - and then
handing the same 3D view to the graphics card with OpenGL.

This page is the map for that course. The lessons themselves are in the
source, right next to the code they explain: [`../neon-caster.bas`](../neon-caster.bas)
and the include files in the folders beside it.

**You'll need:** some BASIC already (variables, arrays, loops, SUBs and
FUNCTIONs). Everything else, from the 3D maths to the QB64PE features, is
explained as it comes up.

## Running it

Just to play: download a ready-built copy for Windows, macOS or Linux from
the [releases](https://github.com/grymmjack/neon-caster/releases). To build
it yourself:

1. Install [QB64 Phoenix Edition](https://qb64phoenix.com) 4.7 or newer
   (the mouse look needs `_MOUSEHIDE _DISABLE`, new in 4.7).
2. Open `neon-caster.bas` in the QB64PE IDE and press F5, or compile it from
   a terminal: `qb64pe -x neon-caster.bas`. It `$INCLUDE`s the rest (see
   "How the source is laid out", below), so keep the folders beside it.
3. The OpenGL renderer's shaders use the GLSL library from
   [QB64_GJ_LIB](https://github.com/grymmjack/QB64_GJ_LIB); a copy of it is
   in `lib/glsl/`, which `_ALL.BI` and `_ALL.BM` include.
4. Keep the `neon-caster/` folder next to the program. All the pictures,
   sounds and music are in there. Your settings and saved games go in
   `neon-caster/saves/`.

| Control | Does |
|---|---|
| Mouse | look around |
| W A S D | walk and strafe |
| Shift (hold) | run |
| F | kick (Fire with no ammo kicks too) |
| Click or Ctrl | fire |
| Space | open or shut doors, use the exit, jack into a data station, use a code terminal, search a wall for a secret, work a vending machine, play NEON PONG on a computer |
| N | night vision on and off, once you've found a headset |
| 1-4 or mouse wheel | choose a gun |
| Right button (hold) | aim down the sights (zooms in) |
| Esc | the menu: pause, new game, save, load, settings, exit |
| F5 / F9 | quick save / quick load |
| Tab | the full-screen map (all of it once you've found the map pickup): pools in their colours, pits, lifts and teleporter pads |
| ` (backtick) | the console: type `help` for the commands |
| Ctrl+R | record a demo: the sector starts again and every key from there is kept, till Ctrl+R again or the exit - **DEMO REPLAYS** (the main menu) plays it back |
| F2 | the level editor (see below); in it, F1 shows a cheatsheet of every key |
| K / G | testing cheats: every keycard / god mode (no damage, through walls, flying with E up and C down, and the monsters ignore you) |

**The console and the command line.** The console (`) runs commands for
nearly everything: `map 7` or `map vault` jumps to a sector (`sectorset new` or `remix` first for another set), `give all`,
`god`, `kill`, `respawn`, `summon heavy 3`, `tp 20 24 90`, `save 2`,
`load quick`, `restart`, `finish`, any setting by its name (`fov 100`,
`renderer 2`, `display 2` - `settings` lists them), `bind`, `events`,
`screenshot`, `record`, `playdemo` and `bot` (demos - below), `cutscene 4` (a sector's transmission), `say taunt2`
(any of NEXUS's lines) and `achievements` (with `achieve NAME` and
`resetachievements` - see below). There are commands for building too: `edit`, `put
X Y CHAR`, `box X0 Y0 X1 Y1 CHAR`, `raise`, `lift`, `trigger`, `undo`,
`savelevel` - and `door`, `wall`, `light`, `liftgo`, `message`, `sound`,
`give`/`take` (health, armour, ammo by kind, all), `die`, `spawn TYPE X Y`
and `item KIND X Y`, which a level's triggers use. `mons` lists every
monster and whether it's awake. `qb64pe` says which compiler the code
terminals use (see below). Up and Down bring back earlier lines, Tab
finishes a command's name, and `;` puts several on one line.

Every command also works from the command line, each one starting with a
`+`. Then the game skips its title, starts a new game and runs them one a
frame - `wait` holds the rest back - so a test can drive it with no hands:

```
./neon-caster.run +map 5 +give all +god on +wait 120 +screenshot five.png +quit
./neon-caster.run +logfile test.log +exec mytest.cfg
```

Settings changed from the command line last only for that run.

**Demos.** **DEMO REPLAYS** in the main menu lists every demo - yours
and the ten that come with the game - and Enter plays one (Esc, then
STOP DEMO, ends it early). F (or FOLDER) opens the folder yours are kept in,
`neon-caster/saves/demos`, to copy, rename or delete them. Leave the title menu alone for 15 seconds and
they play by themselves, one after another, till you press a key. Ctrl+R records one: the sector you're in
starts again, and Ctrl+R again (or the exit) keeps it as `run1`, `run2`...
From the console, `record NAME` does the same with a name of your own. A
demo is how DOOM did it: not a video, but every key and turn, frame by
frame. The exit (or `stopdemo`) ends it, and `playdemo NAME` plays it
back exactly - the same monsters, the same shots,
the same loot - in either renderer. `demos` lists them; they're small text
files in `neon-caster/saves/demos/`. `bot` turns on the autopilot, which
plays the sector itself, so `record mine` then `bot` makes a demo with no
hands. It plays like someone new to the sector: it knows only what it has
seen, so it explores room by room, fights what it notices (in front of it,
or what hurts it), goes for a medkit when it's hurt and ammo when it's low,
picks up what's lying near, and heads for the exit once it has found it.
`bot human 0-100` sets how human it plays (60 to start): slower, eased
turns that overshoot, aim that wanders and misses (high, low, either
side) and settles as it holds on, a beat before it fires at something it's
just seen, aiming down the sights at range, bursts instead of a held
trigger, strafing as it walks, and now and then a stop to look round. `bot safe` (off to start) gives it buddha mode, which `buddha` in
the console turns on for you too: you're hurt as ever, but never below 1
health (a pit or a death trap still kills).
`playdemo NAME quit` ends the game when the demo does, with exit code 3 if
it went out of step - a test that a sector still plays the same. Ten come
with the game: `playdemo sector1` to `playdemo sector10` watch the
autopilot play the original ten, to the exit or till it dies (recorded
in OpenGL with LOOK UP / DOWN on - in OpenGL you see its aim go high
and low).

```
./neon-caster.run +map 3 +record three +bot on
./neon-caster.run +playdemo three quit
```

Every key can be changed in the menu, under **SETTINGS > CONTROLS**. The
menu works with the arrow keys or W A S D, Enter, and Esc to go back - or
just point and click.

**MODE** (the top of **SETTINGS**) sets every video and effects setting in
one go: OLDSCHOOL (RETRO resolution, the pixel art, no effects), 90S (720P,
the pixel art, scanlines and phosphor glow, every effect but NEON and WET
FLOORS) or NEWSCHOOL (as sharp as your display goes, the modern paintings,
everything on) - all full screen 4:3. It isn't kept as itself: it shows
the mode your settings all match, and CUSTOM once you change one.
(`ModeWants` lists what each one sets.)

If something goes wrong while the game runs, it doesn't stop: the error
and the line it was on go into `neon-caster/saves/errors.log` (and the
console), and it carries on.

**The code terminals and qb64pe.** A code terminal ($ on a map) locks the
doors until you put a little QB64 program back together. When the game can
find qb64pe, pressing F5 really compiles and runs your program, and its
output has to match. When it can't, nothing breaks: your lines are checked
against the puzzle's answer instead (so a fix that works but is written
differently won't pass), and the bottom of the puzzle screen says so. It
looks in the order:

1. the one you chose: **SETTINGS > QB64PE COMPILER** - TYPE IT (the path
   to qb64pe, or the folder it's in; Ctrl+V pastes), BROWSE (a file
   window), or FIND IT (forget yours and look again)
2. `$QB64PE`, if you set it
3. every folder on your `PATH`
4. the usual places: `~/git/qb64pe/`, `~/qb64pe/`, `C:\qb64pe\`,
   `Program Files\qb64pe\`, `/Applications/qb64pe/`, `/usr/local/bin/`...

The console does the same: `qb64pe` shows which one it's using,
`qb64pe ~/tools/qb64pe` chooses one, and `qb64pe auto` goes back to
looking. Your choice is kept in `settings.ini` as `qb64pe=`.

**The editors.** F2 opens the level editor on the level you're in, and Tab
switches between its two views of it: the map from above, and inside it in
3D - the game frozen, nothing hurting you, flying through walls (Space up,
C down), with a mouse pointer that picks out the face under it (a wall, a
floor, a ceiling, the face of a step) or the monster or thing; hold the
right button to look round. A toolbar has the tools - SELECT, PLACE, PAINT,
LIGHT, HEIGHT - and a picker has everything you can put in a level as
pictures, in tabs (walls, floors, ceilings, doors, items, monsters,
decorations, specials, lights). Click faces to select them, then the wheel
raises and lowers floors and ceilings, and with Shift pushes walls back or
pulls them out a cell; the arrows slide the selection along; H and V divide
a face in two for its pictures; PAINT puts any picture on any face; LIGHT
puts a light on one, in any colour, steady, pulsing or flickering. Select a
door, a teleporter, a lift or a monster and a pane sets it up - a monster's
own sight, hearing, health, speed and what wakes it, for staging ambushes.
Ctrl+S saves the level's file, Ctrl+Z undoes, F1 lists every key, F2 goes
back to playing it. M opens the monster kinds editor (every kind's
numbers, and what it drops: `monsters.txt`), U the HUD layout editor (drag
the HUD about, over the game: `hud.txt`).

**Your own sectors.** To start from nothing, **GAME > YOUR SECTORS > NEW
SECTOR** makes a blank one - solid wall, with one lit room in the middle,
you facing the exit - and opens the editor on it. Carve rooms outwards by
pushing walls back or placing floor (`.`), add doors, keycards,
monsters, lights and heights, and Ctrl+S saves it. Your sectors are numbered on from the game's (11, 12
and so on, up to 30 - the first eleven are examples built with the editor) and kept in `neon-caster/levels/custom/` (`custom1.txt`
is sector 11), where the level kit never touches them. YOUR SECTORS lists
them to play; finishing one starts it again. In the console, `newsector`
makes one, `sectorname NAME` renames the sector you're in (then
`savelevel`), `map 11` goes there and `maps` lists them all. In the
editor, PgUp/PgDn steps through every sector, yours included. The whole
editor - every tool, key, map character, height, light, event and trigger - is in
[LEVEL-EDITOR-GUIDE.md](../LEVEL-EDITOR-GUIDE.md).

Two switches near the top of the source are on for testing:
`TEST_ALL_GUNS` (start with every gun and full ammo) and `CHEAT_KEYS`
(the K and G keys). Set both to `0` for the real game.

## How the source is laid out

It's organised like grymmjack's DRAW: a folder for each part of the game,
and in it a module or two. A module is a pair of files - a `.BI` (its
`CONST`s, its `DIM SHARED` arrays, and any start-up that fills them in)
and a `.BM` (its `SUB`s and `FUNCTION`s).
`_ALL.BI` includes every `.BI`, `_ALL.BM` every `.BM`, and `neon-caster.bas`
includes `_ALL.BI` at its top and `_ALL.BM` at its bottom. In between it has
the course's introduction, the start-up, and the game loop - whose twelve
chapters are in `LOOP/`, each pasted in place inside the `DO ... LOOP`.
`$INCLUDE` pastes a file in where it's named, so QB64PE still sees one
program.

| Folder | What's in it |
|---|---|
| `CORE/` | the window, the dice (and the game's own `SIN`/`COS`), settings, keys, files, small helpers |
| `WORLD/` | the grid: walls and collision, doors, heights, glass, liquids, lifts |
| `GAME/` | you, the guns, monsters and their types, pickups, decorations, droids, explosions, event rooms, secrets, triggers, teleporters, code terminals, the network, the arcade, NEXUS |
| `LEVEL/` | levels and sectors, loading one, and the level files |
| `RENDER/` | pictures, the 3D view and its helpers, the sprite list, light, particles, the HUD, text, the screen |
| `GL/` | the OpenGL renderer, and its extras |
| `MENU/` | the menu, the splash screen, the console, saved games |
| `EDITOR/` | the level editor, the HUD editor, the monster editor |
| `AUDIO/` | sounds and music |
| `DEMO/` | demos, and the autopilot |
| `ACH/` | achievements and records |
| `LOOP/` | the game loop, a chapter a file (`07-FRAME.BI` to `18-HUD.BI`) |

## How to read the course

Search the source for `CHAPTER` to jump from one chapter to the next. In
order, and where each one is:

| | Chapter | Where | What you'll learn |
|---|---|---|---|
| **Setting up** | 1 A window | `CORE/WINDOW.BI` | `SCREEN _NEWIMAGE`, 32-bit colour, capturing the mouse |
| | 2 The world is a grid | `WORLD/MAP.BI` | the map as a 2D array; cells, positions and `INT()` |
| | 3 Things in the world | `GAME/ITEMS.BI` | lists of things in parallel arrays |
| | 4 You | `GAME/PLAYER.BI` | health, ammo, and guns as a table of numbers |
| | 5 Pictures in arrays | `RENDER/PICTURES.BI` | why the 3D view is drawn into an array, not with `PSET` |
| | 6 Loading the pictures and sounds | `AUDIO/SOUND.BI` | `_LOADIMAGE`, `POINT`, tinting, `_SNDOPEN` |
| **One frame** | 7 The game loop | `neon-caster.bas`, `LOOP/07-FRAME.BI` | `_LIMIT`, `_DISPLAY`, the order of a frame |
| | 8 Looking around | `LOOP/08-LOOK.BI` | direction and camera plane vectors; rotating them |
| | 9 Moving, and bumping into things | `LOOP/09-MOVE.BI` | normalized movement; sliding along walls |
| | 10 Pickups and cheat keys | `LOOP/10-PICKUPS.BI` | distance checks without `SQR`; edge detection |
| | 11 Doors | `LOOP/11-DOORS.BI` | finding the door in front of you; animating it; shutting itself, never on anyone; always showing an edge; monsters opening them |
| | 12 Shooting | `LOOP/12-SHOOTING.BI` | hitscan, using the z-buffer to see past walls; where a shot lands, for marks and shooting out lights |
| | 13 Monsters, bolts and barrels | `LOOP/13-MONSTERS.BI` | a state machine for AI; line of sight; chain reactions; animation frames made from one picture; bodies and wreckage that stay where they fell; a thief that runs home along a flow field |
| **Drawing it** | 14 Light, and the floor and ceiling | `LOOP/14-FLOORS.BI` | per-cell coloured light (Doom-style), flicker and strobe effects, floor casting, fog, `AND 63` texture wrapping |
| | 15 The walls: the raycaster | `LOOP/15-WALLS.BI` | rays, the DDA grid walk, fish-eye correction, texturing; doors as slabs with edges and tracks; glass you see through; floors and ceilings at different heights, Doom's way (HeightColumn: a column drawn front to back, closing in from above and below) |
| | 16 Sprites | `LOOP/16-SPRITES.BI` | camera space, painter's algorithm, hiding behind walls - and behind ledges |
| | 17 Onto the screen | `LOOP/17-SCREEN.BI` | `_MEMCOPY` and `_PUTIMAGE` scaling |
| | 18 The gun and the HUD | `LOOP/18-HUD.BI` | alpha colours, the minimap, bars and text; the HUD's layout as data (`hud.txt`) |
| **The rest** | 19 Game events | `GAME/EVENTS.BM` SUBs that work on the main program's shared variables (`DIM SHARED`, `SUB ... STATIC`); event rooms: ambushes, mini games, monster closets, pressure plates, lasers and cutters, blackouts, the thieves' hoard; glass that cracks and shatters; the data stations' network; triggers (their actions are console commands) and teleporters; code terminals that compile a real QB64 program with `SHELL _DONTWAIT`; sound placed in space (panning, distance, walls) under a limiter; NEXUS's voice, taunts and subtitles |
| | 20 Levels | `LEVEL/LEVELS.BM` | reading a level's file and building it, carrying your gear between levels (and starting over clean on a retry), the tally screen, the route map between sectors, the incoming transmission |
| | 21 The splash screen, the menu, settings, saved games, the console and the editors | `MENU/MENU.BM` | a menu driven by a list, `_KEYHIT` vs `_KEYDOWN`, easing animations, a settings file, `PUT`/`GET` save files; the level editor (the map from above, and walking round in it with a cursor ray), the monster editor and the HUD layout editor - changing plain text files live |
| | 22 The level files | `LEVEL/LEVELFILE.BM` | the level file's format - its map, zones, lights, event rooms, heights, lifts, triggers: make your own levels |
| | 23 The helpers | `CORE/HELPERS.BM`, and the other `.BM` files | the SUBs and FUNCTIONs, grouped by topic |
| **On the GPU** | 24 The same view, drawn by the graphics card | `GL/OPENGL.BM` | `SUB _GL` and OpenGL: triangles, texture coordinates, a camera matrix and `_glFrustum`, the depth buffer, alpha test; sharing a frame safely with double buffering; batching with `_glDrawArrays`; why OpenGL questions stall; GLSL shaders for bump mapping, specular highlights, self-lit neon, animated textures and moving point lights; smooth (bilinear) light; projected shadows; additive glows and particles; light shafts and dust that swirls round you; a mirrored pass for wet floors; render targets and post-processing (bloom, heat shimmer, hurt pulse, rail zoom, scanlines, CRT); choosing the resolution, supersampling and mipmaps; premultiplied alpha; looking up and down |

### Reading the names

The top of `neon-caster.bas` has the full key. In short:

- `UPPER_CASE` is a `CONST` (a fixed number), `camelCase` a variable, and
  `PascalCase` a `SUB` or `FUNCTION`.
- A symbol at the end of a name is its type: `$` text, `&` a whole number
  (image and sound handles), `~&` a colour, `!` a decimal number, `%` a
  small whole number.
- True is `-1` and false is `0`.

| Prefix | Means | Example |
|---|---|---|
| `MAX_` | the most there can be | `MAX_MON` = room for 128 monsters |
| `NUM_` (constants) | how many there are | `NUM_GUNS` = 4 |
| `DOOR_` | a kind of door | `DOOR_SHUTTER` |
| `IT_` | **it**em: a kind of pickup | `IT_HEALTH` |
| `MON_` | **mon**ster settings | `MON_SIGHT` |
| `AM_` | **am**mo: which kind | `AM_SHELLS` |
| `W_` | **w**eapon: which gun | `W_RAIL` = gun 4 |
| `SPR_`, `S_` | **spr**ite storage, **s**prite slot | `S_BOLT` |
| `T_` | **t**exture slot | `T_EXIT` |
| `RENDER_` | size of the 3D view | `RENDER_W` = 400 |
| `player...` | you | `playerX` |
| `monster...` | one monster, by number | `monsterHP(i)` |
| `mtype...` | a *type* of monster, by type number | `mtypeSpeed(t)` |
| `gun...` | a gun, by number | `gunDamage(g)` |
| `num...` (variables) | how many are in use now | `numItems` |
| `has...` | a yes/no flag | `hasCard(c)` |
| `SET_`, `setting()` | a setting, and the settings table | `setting(SET_FOV)` |
| `BIND_`, `keyBind&()` | a key binding | `keyBind&(BIND_FIRE)` |
| `SCR_`, `MI_`, `MA_` | a menu screen, a menu item's kind, a menu action | `SCR_AUDIO`, `MI_SLIDER` |
| `snd...&` | a loaded sound | `sndDoor&` |

If you only read one chapter, read **15**: it's the raycaster itself.
Chapters 8 (the camera), 14 (floors) and 16 (sprites) are the rest of the 3D.

The maths uses the same names as Lode Vandevenne's classic
[raycasting tutorial](https://lodev.org/cgtutor/raycasting.html) (`dirX`,
`planeX`, `rayDirX`, `sideDistX`, `deltaDistX`, `perpWallDist`...), so you
can read the two side by side.

## The sectors, and their heights

Each sector is built around floors and ceilings at different heights
(chapter 22's `[floor]` and `[ceiling]` grids). `levels.py` builds them all:

| Sector | Its heights |
|---|---|
| 1 Neon Station | a sunken atrium in the hub; a mezzanine a wall up in the bio-lab, by elevator |
| 2 Reactor Core | a raised control deck with the exit at its back; a bowl sunk round the core; a walkway along the south hall |
| 3 Undercity | a low tunnel with a channel to wade; a raised gantry; a flooded cistern pit; a hall that terraces down into the water |
| 4 Cryo Lab | an observation deck round the atrium's core, by elevator; split-level labs, the ice lab sunk |
| 5 Foundry | a hall four walls tall; a molten trough that burns, with bridges; a pouring floor up by stairs and elevators |
| 6 Hydroponics | every bay a stepped pyramid of planters; a pool under the dome |
| 7 Data Vault | a canyon between racks five walls tall, a catwalk round its edge |
| 8 Maglev Depot | galleries over both platforms for the snipers; track trenches to duck into |
| 9 Orbital Spire | an amphitheatre stepping down to the core; sniper ledges with elevators |
| 10 The Core | a spiral climbing as it winds in; an arena with a ring of pit (kick them in) round the overseer's dais |

## Achievements and records

49 achievements, and each sector's best time, kills and items, in **GAME >
ACHIEVEMENTS** (Tab goes on to the RECORDS page, then STATS: your rank,
from how many you've got, and lifetime totals). They're Steam's: chapter 23's
ACHIEVEMENTS section uses the STEAM library from QB64_GJ_LIB (`lib/steam`),
which loads Valve's `steam_api` while the game runs, once it has a Steam
App ID. Until then the library's stand-in keeps them in
`saves/achievements.txt`, and records go in `saves/records.txt`.

How they work, to read alongside the code:

- **Achieve.** Each achievement is unlocked by its API name.
- **Counted ones.** `AchAdd` adds to a stat (kills, headshots) and unlocks
  every achievement that stat's goal now reaches. Each quarter of the way
  to a big one (a goal of ten or more, not hidden), it queues a quieter
  ACHIEVEMENT PROGRESS note with a bar, as Steam does.
- **Sets of things.** `AchBit` ticks one bit of a stat (each kind of machine
  killed, each set finished) and counts the bits.
- **Where they're unlocked.** The hooks sit where things happen:
  `HitMonster` for kills, `WinEvent` for the event rooms, `LevelDone` for
  how a sector was finished.
- **Cheats.** God mode, `give`, the editor and the like set `achCheat`, which
  holds achievements and records until a new game. A level's own triggers
  don't count: `TriggerRun` sets `conFromTrig` while they run.

In the console:

- `achievements` lists them all.
- `achieve NAME` unlocks one (as a cheat).
- `resetachievements` starts over.
- `NEON_ACH_TEST=1` in the environment lets scripted test runs count with
  cheats on.

`steam/README.md` covers what Steamworks needs to go live.

## The other two sets

**NEW SECTORS** (GAME > NEW SECTORS, `levels/new/`) are ten more, built by
`levels/newsectors.py` on everything the game grew after the first ten:

| Sector | What it shows off |
|---|---|
| 1 Arrival Dock | slim lit posts, terminal alcoves, lit columns, a flooded channel, a lockdown with the scatter gun as its prize, shelves of crates (loot) |
| 2 The Aqueduct | a channel down a hall three walls high, gunner ledges (aim for heads), a survive lockdown, a deep reservoir crossed on bobbing lifts |
| 3 Neon Market | outdoors at night: stall kiosks of thin walls under awnings, signs lit their own colours, shopfront alcoves, thieves, a shooting gallery |
| 4 Acid Works | a deep acid channel with steps out, catwalks, a lift to the railgun's island, vats that eat armour |
| 5 The Forge | two lava rivers, generators roaring in alcoves, a fire floor, heavies locking you in, a power failure |
| 6 The Chapel | a nave four walls high between rows of lit pillars, hologram shrines, a poison font, a spawner nest, a crypt to survive |
| 7 Cold Storage | cryo vaults behind glass, a bottomless freezer shaft, tank alcoves, thin-walled office cubicles |
| 8 The Skyway | rooftops in a storm over a street that kills, bridges, a lift between roofs, a laser cutter on the gantry |
| 9 The Archive | rack rows between partitions, rack alcoves, laser grids, a cutter sweeping the sorter, stalker closets |
| 10 Nexus Heart | the overseer on a platform ringed by red-lit pillars in a lava moat, spawners, two lockdowns on the way in |

**OLD SECTORS NEW** (GAME > OLD SECTORS NEW, `levels/remix/`) are the
first ten remade by `levels/remaster.py`, which reads each original and
adds to it without moving its walls, keys or doors: alcoves cut into long
walls with the sector's theme glowing in them, slim lit columns in open
floor, posts at the exit, decorations moved back against walls, its
murky floors made water and its molten ones lava (only where the way
doesn't cross them), and touches of its own - a fountain in Neon
Station's hub, coolant in the Reactor's bowl, the Foundry's pillars lit
like fire, neon adverts on the Maglev's platforms, red pillars round the
overseer.

Each set is played 1 to 10 on its own (`sectorset 0|1|2` in the console
picks one for `map`), and a save remembers its set. Both scripts check
what they build with the level kit, as `levels.py` does - `--write` to
write the files, `--check` to check them as they are.

The level kit's height helpers (`lvlkit.py`): `m.floor`, `m.ceiling`,
`m.stairs` (two eighths a step, as much as you can climb), `m.pit` (with
steps out), `m.lift` and `m.headroom`. `python3 levels.py --check` walks
every level the way you would - step up two eighths, drop any distance,
need room for your body, ride the lifts and pads, pick up keys in order -
and fails a level with an exit or a key out of reach, or a *stuck spot*:
somewhere you can get into and not out of.

## Things to try

Each one is a small change to the code. Look first, then change something,
run it and see what happens. That's the fastest way to learn how it works.

**Warm-ups**
- **Wider or narrower view** (ch. 8, 21): try the FIELD OF VIEW slider in
  the menu, then read how `ApplySettings` turns degrees into `fovPlane`.
  Then try `ADS_ZOOM` at `3` for a sniper scope.
- **No fog** (ch. 14, 15): set `light& = 256` instead of working it out
  from the distance. Then try fog that reaches 30 cells instead of 16.
- **Flat lighting** (ch. 15): remove the line that makes y-sides darker.
  Can you still tell where the corners are?
- **The world in a mirror** (ch. 8): build the camera plane the classic
  raycaster's way, `planeX = dirY * fovPlane : planeY = -dirX * fovPlane`
  (in the line that rebuilds it each frame), and play with the map open
  (Tab): everything's on the wrong side of you, and the EXIT signs read
  backwards. Chapter 8 says why our map needs `(-dirY, dirX)`.
- **Faster, slower** (ch. 4, 9): change `moveSpeed`, a gun's delay in its
  `SetGun` line, or a monster's speed in `SetMonType`.

**See the maths**
- **The fish-eye** (ch. 15): right after `perpWallDist` is worked out, add
  `perpWallDist = perpWallDist * SQR(rayDirX * rayDirX + rayDirY * rayDirY)`
  to use the true length of the ray instead. Walk up to a long, flat wall.
- **Full resolution** (ch. 5, 17): set `RENDER_W = 800` and
  `RENDER_H = 600`. It's sharper, and four times the work. How's the speed?
- **Sprites through walls** (ch. 16): take out the `zBuffer` test and watch
  every monster show through every wall.

**Add things**
- **A new gun** (ch. 4, 6, 12): add a fifth `SetGun` line (raise
  `NUM_GUNS`), a picture for `LoadGun`, a sound, and a key to pick it.
- **A new monster** (ch. 3, 6, 13): copy a `SetMonType` line, raise
  `MON_TYPES`, load a sprite into two new slots (raise `SPR_SLOTS`, and
  stretch the hit-flash loop in chapter 6 to cover them), and give it a map
  letter in `LoadLevel`.
- **Hand-drawn animation** (ch. 13, 23): each monster's walk and attack
  frames are made from its picture (`MakeMonFrames`, `MonMove`), a pixel or
  two at a time. Draw your own as `<name>-walk1.png` to `-walk4.png` and
  `<name>-attack.png` - each one you add replaces the made one.
- **Your own event room** (ch. 19, 22): an ambush, survival round, trap,
  shooting gallery, spawner nest, monster closet, pressure plate, laser,
  laser cutter, blackout or thieves' hoard is one DATA line (`m.event(...)`
  in the level kit). Try an ambush of heavies (type 3) in a small room, a
  laser that's always on (b = 0) across a corridor you must run, or a
  cutter that sweeps faster (a smaller a).
- **Dress a level differently** (ch. 22): `dress()` in `levels.py` adds
  the furniture, closets, plates, lasers, cutters, hoards and blackouts.
  Its `DRESS` table says how many of each a level gets - change a line and
  run `python3 levels.py --write`.
- **Give the droids a new job** (ch. 19): every sector has three service
  droids (`PlaceDroids`) rolling between machines and scrubbing scorch
  marks off the floor (`UpdateDroids`, `DroidPlan`). They roll by dice of
  their own (`DRnd`), so they never change what a monster does - and go
  the same way in a demo. `droids` in the console says where they are.
  A level file's `droids = N` (0-6; `droids N` in the console) sets how
  many a sector has. Send them to the exit, make one follow you, or raise
  `MAX_DROIDS` for a busier station.
- **Teach the thief new tricks** (ch. 13): `ThiefStep` decides what it
  grabs. Make it take keycards, or only shells. It runs home down
  `thiefDist`, a map of steps to the hoard worked out by `BuildThiefWay` -
  a flow field, the way real-time strategy games move armies.
- **NEXUS says something new** (ch. 19): the lines are DATA in
  `SpeechLines`, each with a key and its words. A line with no
  `speech/<key>.wav` still shows its subtitle, so you can write the words
  first. Record your own voice, and run it through a vocoder - or any
  robot voice changer - for the sound.
- **Hear the room** (ch. 19): turn 3D SOUND and the LIMITER off and on
  in SETTINGS > AUDIO and listen to a fight. Then look at `SfxAt`: how
  loud is a sound behind a wall? Try a lower `SFX_HEADROOM` for a quieter,
  squashed mix.
- **Your own boot** (ch. 12, 18): the kick draws `kick.png`, stretched to
  360 pixels tall and rising from the bottom of the screen. Redraw it, or
  tune `KICK_DAMAGE`, `KICK_REACH` and `KICK_PUSH`.
- **Your own bodies** (ch. 13, 23): a dead monster is drawn from
  `dead-<name>.png` (`dead-drone.png`...), cropped and laid on the floor by
  `MakeCorpse`. Draw your own - delete one and the monster just falls on
  its side instead.
- **Monsters with keycards** (ch. 11, 13): monsters open plain doors
  (`MonsterDoor`) but never keycard doors. Give a heavy the red card, so
  red doors are no longer safe.
- **Marks that fade** (ch. 12, 24): shot marks and scorches (`AddDecal`)
  stay until 96 newer ones push them out. Fade each one's alpha with age
  instead.
- **Your own level (ch. 21, 22)**: GAME > YOUR SECTORS > NEW SECTOR, and
  build from a blank slate - push walls back with Shift+wheel, wheel
  floors down into pits, paint pictures on single faces, light them,
  stage an ambush in a monster's pane, Ctrl+S. For an outdoor level, give
  the open cells a `sky-` ceiling (the CEILINGS tab): the sky is drawn by
  the way you look - `neon-caster/levels/skies.py` paints them. Or open
  `neon-caster/levels/custom/custom1.txt` (or any `level1.txt`) in a text
  editor: the map is right there, one character a cell. For the game's
  own sectors, `python3 levels.py --check` (in `neon-caster/levels/`)
  checks them: doors, keycards, the exit.
- **Your own puzzle (ch. 19)**: copy `neon-caster/puzzles/countdown.txt`,
  write a little program that teaches one thing, say what it prints, pick
  the words to blank out - and name it in a level's `puzzles =` line.
  With qb64pe, every program is really compiled: try `puzzle NAME` in
  the console.
- **Your own trigger (ch. 19, 22)**: in the console, `trigger enter 20 20
  22 22 : message AMBUSH! | summon stalker 3` - then walk there. Any
  console command is an action: lights out, a lift moving, a wall sliding
  away (`wall X Y .`), a teleport.
- **Your own secret (ch. 22)**: in the editor, turn a stretch of wall
  into `?` with a little room carved behind it, and put something good in
  there. Space finds it. For a DOOM-style switch, paint `wall-switch.png`
  on a wall nearby and add `shoot X Y : secret X2 Y2` (the switch's cell,
  then the secret's). `AssignSecrets` and `OpenSecret` show how it works.
- **Another arcade game (ch. 19)**: `ArcadeRun` and `DrawArcade` are NEON
  PONG - its own loop, like the code terminals'. Make the machine's
  paddle quicker (the `5.2`s), the ball faster, or write BREAKOUT next to
  it.
- **Retune the monsters (ch. 3, 21)**: M in the editor - give the drone
  the heavy's hit points, make the crawler drop medkits - or change
  `monsters.txt` by hand.
- **Rearrange the HUD (ch. 18, 21)**: U in the editor, then drag things;
  S saves `hud.txt`. Delete the file for the game's own layout.
- **Steps and ledges (ch. 15, 22, 24)**: the two renderers draw heights
  their own ways - OpenGL builds them into its mesh (`GLStep`), the
  software renderer walks each column front to back (`HeightColumn`).
  Raise a floor with PgUp in the editor and compare them (`renderer 1`,
  `renderer 2`).

- **Your own menu screen** (ch. 21, 23): add a SCR_ constant, a `CASE`
  for it in `BuildMenu`, and a button that leads to it. A new setting is
  one `DefineSetting` line plus an `AddSettingItem`.
- **A splash picture** (ch. 21): drop a `splash.png` (800 x 600) into
  `neon-caster/` and it replaces the title on the splash screen.

- **Floors that bite** (ch. 22): a floor whose picture is called
  `*molten*` or `*lava*` burns whoever stands in it (`FloorHazard`,
  `BURN_DAMAGE`), and `*murky*` or `*slime*` slows you to `SLOW_WADE`.
  Monsters won't step into fire. Give a sunken pit a molten floor, or
  invent your own kind: ice that slides you along?

- **Your own lights** (ch. 14, 22): add a line to a level's lights - try
  a red strobe (effect 3) in a dark corridor, or set a level's ambient
  brightness to 40 and light it only with lamps.

**The graphics card** (the game starts with RENDERER on OPENGL - turn
SHOW FPS on to see what each effect costs; both are in SETTINGS > VIDEO,
along with ART (CLASSIC: the pixel art; MODERN: high-resolution paintings
of the same things, from `neon-caster/hd/`), DISPLAY (a window, or full screen: WIDE, 4:3 or stretched),
RESOLUTION, LOOK UP / DOWN and the screen effects - SCREEN FX, the
scanlines' darkness, spacing and thickness, and PHOSPHOR GLOW; every other
effect has a switch in SETTINGS > EFFECTS. Settings change behind the menu
as you set them. Set RENDERER to SOFTWARE to see chapters 14-17 at work.)
- **Sharper guns** (ch. 6, 24): `gunSize` is how tall a gun is drawn,
  whatever size its picture is. Draw `gun.png` again at 4 or 8 times the
  pixels (384 or 768 across, still square, the muzzle in the same place)
  and with OPENGL in full screen every extra pixel shows.
- **The gun in its light** (ch. 17): the gun takes the colour and
  brightness of the light where you stand (`LightAt`). Try `GUN_TINT = 3`
  for strongly coloured light, or `GUN_DARKEST = 0` to lose it in the dark.
- **Your own lamp** (ch. 24): every ceiling light hangs from
  `ceiling-lamp.png` (`BuildShafts`). Draw your own - it's tinted by its
  light, so keep it pale.
- **One at a time** (ch. 24): switch the effects off, then on again one by
  one, and find each in the code. Which costs the most milliseconds?
- **Your own post effect** (ch. 24): in `GLBuildShaders`, the last shader
  (the one ending `glPostProg = ...`) sees the whole finished picture. Try
  `c = vec3(dot(c, vec3(0.3, 0.59, 0.11)));` just before the HUD line for
  black and white, or `c = floor(c * 4.0) / 4.0;` for four shades a colour.
- **Compare** (ch. 17, 24): walk around with each renderer and watch the
  3D VIEW milliseconds. Then set `RENDER_W = 800` and `RENDER_H = 600`
  and compare again: the software renderer gets about four times slower,
  and OpenGL hardly notices (only its rays double).
- **Smooth textures** (ch. 24): in `GLSendPicture`, change both
  `_GL_NEAREST`s to `_GL_LINEAR`. Blurry or better? (MODERN art is drawn
  smooth already - compare the two.)
- **Your own modern art** (ch. 6, 23): every picture in `neon-caster/hd/`
  has the same name as its pixel-art twin in `neon-caster/`. Paint your own
  (textures 512 x 512, sprites 256 x 256 on a see-through background,
  standing where the old one stood), drop it in `hd/`, and set ART to
  MODERN. `ArtPath$` picks it; `ReadPicture` shrinks it for the software
  renderer; delete it and the pixel art comes back.
- **Smooth light** (ch. 24): give each corner in `GLCorner` the average
  light of the four cells that meet there, instead of one cell's light.
  The software renderer couldn't afford that per pixel; the card blends
  it for free.
- **Longer shadows, brighter neon** (ch. 24): in `GLShadows`, try `lz =
  GL_LIGHT_Z * 1.2`; in the world shader, lower the `0.68` in the neon
  line so more colours light themselves.
- **Flatter, bumpier, shinier** (ch. 24): change `GL_BUMP` (0 is flat, 5
  is very craggy), `GL_LIGHT_Z` (lights lower down rake across the walls),
  or a texture's shine in `GLShine`.
- **Write a shader** (ch. 24): in `GLBuildShader`, try
  `gl_FragColor = vec4(nb * 0.5 + 0.5, 1.0);` as the last line to see the
  bumpy normals as colours. Then try your own ideas with QB64_GJ_LIB's
  `GLSL/GLSL-TEST.BAS`, which runs any Shadertoy-style `.frag` file.
- **See the triangles** (ch. 24): add `_glPolygonMode _GL_FRONT_AND_BACK,
  _GL_LINE` after `_glDisable _GL_CULL_FACE`, to draw only their edges
  (put it back with `_GL_FILL` at the end of `SUB _GL`).

**Bigger projects**
- **A height design of your own** (ch. 22): in `levels.py`, give a sector a
  new shape with `m.floor`, `m.stairs`, `m.pit` and `m.lift`, then run
  `python3 levels.py` - the check tells you if you've made a spot you
  can't get out of - and `--write` to play it. Try a pit with no bottom
  (`m.pit(..., 8)`) and a bridge across it.
- **Look up and down** (ch. 14-16): everything uses `RENDER_H / 2` as the
  horizon. Make it a variable, move it with the mouse's Y movement, and
  fix up the floor, walls and sprites to use it. ("Y-shearing", as in
  Heretic and Duke Nukem 3D.)
- **Records instead of parallel arrays** (ch. 3): rewrite the monsters as
  one array of a `TYPE` with `x`, `y`, `kind`, `hp`, `state` fields.
- **Door jambs** (ch. 15, 24): doors are slabs across the middle of their
  doorway now (`DoorRay`, `GLDoorBox`), so the walls either side show.
  Wolfenstein gave those a texture of their own - in `DoorRay`'s
  neighbours, use a door-frame texture when the wall beside a door is hit.

## What's in the folder

| Path | What |
|---|---|
| `neon-caster.bas` | the course's introduction, the start-up and the game loop: start reading here |
| `_ALL.BI`, `_ALL.BM` | every declaration file and every routine file, in order |
| `CORE/` ... `LOOP/` | the rest of the game and the course - see "How the source is laid out" |
| `neon-caster/*.png` | textures (64 x 64), sprites, the guns: the CLASSIC pixel art |
| `neon-caster/hd/` | the same pictures painted again at high resolution (textures 512, sprites 256): the MODERN art (ART in SETTINGS > VIDEO) |
| `neon-caster/sfx/` | sound effects, made with soundmon (the droids' chirps are synthesized whistles); `pwmsfxr/` has the first set, PC-speaker style, built by `make-sfx.sh` with PWMSFXR |
| `neon-caster/demos/` | demos that come with the game: `sector1.ncd` to `sector10.ncd`, the autopilot playing each of the original ten (`playdemo sector3`) - plain text, a line a frame |
| `neon-caster/programs/` | programs the computers in a level can run (`program NAME` in a trigger): `invaders.bas`, NEON INVADERS - copy it and make your own |
| `neon-caster/speech/` | NEXUS's lines and the minions' barks: a text-to-speech voice through a channel vocoder |
| `neon-caster/levels/` | the levels (`level1.txt`...: plain text - chapter 22), the level kit that builds and checks them (`levels.py`, `lvlkit.py`), the showcase sectors' builder (`showcase.py`), the other sets' builders (`newsectors.py`, `remaster.py`) and the skies' painter (`skies.py`) |
| `neon-caster/levels/new/`, `remix/` | NEW SECTORS and OLD SECTORS NEW, `level1.txt`... each |
| `neon-caster/levels/custom/` | your own sectors (`customN.txt` is sector 10+N), made by NEW SECTOR - the level kit leaves them alone; 1-11 are the showcase sectors (19-21 outdoors), 14 is THE NEON EXPO (sector 24: every feature in one, built by `levels/megasector.py`) |
| `neon-caster/puzzles/` | the code terminals' QB64 programs, one a file (`README.txt` says how to write one) |
| `neon-caster/achievements/` | each achievement's badge (`NAME.png`) and its grey, locked one (`NAME_locked.png`) |
| `neon-caster/saves/achievements.txt`, `records.txt` | the achievements and stats (Steam's stand-in, until the game is on Steam) and each sector's best |
| `neon-caster/monsters.txt`, `hud.txt` | every monster's numbers and what it drops; the HUD's layout - both changed by their editors, or by hand |
| `neon-caster/music/` | a track for each sector, the menu's, and the network's (`cyber.flac`) |
| `lib/glsl/`, `lib/steam/` | libraries from QB64_GJ_LIB: the OpenGL shaders' helpers, and Steam's achievements and stats (with a stand-in until the game is on Steam) |

## Further reading

- Lode Vandevenne, [Raycasting](https://lodev.org/cgtutor/raycasting.html),
  [part II: floor and ceiling](https://lodev.org/cgtutor/raycasting2.html),
  [part III: sprites](https://lodev.org/cgtutor/raycasting3.html). These
  are the maths this game uses, explained with diagrams.
- Fabien Sanglard, *Game Engine Black Book: Wolfenstein 3D*. How the real
  thing squeezed all this onto a 1992 PC.
- The [QB64PE wiki](https://qb64phoenix.com/qb64wiki/) for every
  `_KEYWORD` used here.
