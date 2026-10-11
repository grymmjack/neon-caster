# NEON-CASTER: make a little FPS in QB64PE

NEON-CASTER is a complete first-person shooter in one file of plain QB64PE:
four levels, five kinds of monster, four guns, doors and keycards, exploding
barrels, a minimap. It's built like Wolfenstein 3D, as a *raycaster*, and the
source is written to be read: its comments are a course in how it all
works, in 22 chapters, from opening a window to casting rays.

This page is the map for that course. The lessons themselves are in
[`../neon-caster.bas`](../neon-caster.bas), right next to the code they
explain.

**You'll need:** some BASIC already (variables, arrays, loops, SUBs and
FUNCTIONs). Everything else, from the 3D maths to the QB64PE features, is
explained as it comes up.

## Running it

1. Install [QB64 Phoenix Edition](https://qb64phoenix.com) (4.x).
2. Open `neon-caster.bas` in the QB64PE IDE and press F5, or compile it from
   a terminal: `qb64pe -x neon-caster.bas`.
3. Keep the `neon-caster/` folder next to the program. All the pictures and
   sounds are in there.

| Control | Does |
|---|---|
| Mouse | look around |
| W A S D | walk and strafe |
| Click or Ctrl | fire |
| Space | open doors, use the exit |
| 1-4 or mouse wheel | choose a gun |
| K / G | testing cheats: every keycard / god mode |
| Esc | quit |

Two switches near the top of the source are on for testing:
`TEST_ALL_GUNS` (start with every gun and full ammo) and `CHEAT_KEYS`
(the K and G keys). Set both to `0` for the real game.

## How to read the course

Search the source for `CHAPTER` to jump from one chapter to the next. They
run top to bottom, in the same order as the code:

| | Chapter | What you'll learn |
|---|---|---|
| **Setting up** | 1 A window | `SCREEN _NEWIMAGE`, 32-bit colour, capturing the mouse |
| | 2 The world is a grid | the map as a 2D array; cells, positions and `INT()` |
| | 3 Things in the world | lists of things in parallel arrays |
| | 4 You | health, ammo, and guns as a table of numbers |
| | 5 Pictures in arrays | why the 3D view is drawn into an array, not with `PSET` |
| | 6 Loading the pictures and sounds | `_LOADIMAGE`, `POINT`, tinting, `_SNDOPEN` |
| **One frame** | 7 The game loop | `_LIMIT`, `_DISPLAY`, the order of a frame |
| | 8 Looking around | direction and camera plane vectors; rotating them |
| | 9 Moving, and bumping into things | normalized movement; sliding along walls |
| | 10 Pickups and cheat keys | distance checks without `SQR`; edge detection |
| | 11 Doors | finding the door in front of you; animating it |
| | 12 Shooting | hitscan, using the z-buffer to see past walls |
| | 13 Monsters, bolts and barrels | a state machine for AI; line of sight; chain reactions |
| **Drawing it** | 14 The floor and ceiling | floor casting, fog, `AND 63` texture wrapping |
| | 15 The walls: the raycaster | rays, the DDA grid walk, fish-eye correction, texturing |
| | 16 Sprites | camera space, painter's algorithm, hiding behind walls |
| | 17 Onto the screen | `_MEMCOPY` and `_PUTIMAGE` scaling |
| | 18 The gun and the HUD | alpha colours, the minimap, bars and text |
| **The rest** | 19 Game events | `GOSUB` routines and why they're used here |
| | 20 Levels | `RESTORE`/`READ`, carrying your gear between levels, the tally screen |
| | 21 The levels' data | the map format: make your own levels |
| | 22 The helpers | the SUBs and FUNCTIONs, grouped by topic |

### Reading the names

The top of the source has the full key. In short:

- `UPPER_CASE` is a `CONST` (a fixed number), `camelCase` a variable, and
  `PascalCase` a `SUB`, `FUNCTION` or `GOSUB` label.
- A symbol at the end of a name is its type: `$` text, `&` a whole number
  (image and sound handles), `~&` a colour, `!` a decimal number, `%` a
  small whole number.
- True is `-1` and false is `0`.

| Prefix | Means | Example |
|---|---|---|
| `MAX_` | the most there can be | `MAX_MON` = room for 64 monsters |
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
| `snd...&` | a loaded sound | `sndDoor&` |

If you only read one chapter, read **15**: it's the raycaster itself.
Chapters 8 (the camera), 14 (floors) and 16 (sprites) are the rest of the 3D.

The maths uses the same names as Lode Vandevenne's classic
[raycasting tutorial](https://lodev.org/cgtutor/raycasting.html) (`dirX`,
`planeX`, `rayDirX`, `sideDistX`, `deltaDistX`, `perpWallDist`...), so you
can read the two side by side.

## Things to try

Each one is a small change to the code. Look first, then change something,
run it and see what happens. That's the fastest way to learn how it works.

**Warm-ups**
- **Wider or narrower view** (ch. 8): in `LoadLevel`, change the `0.66` in
  `planeX = dirY * 0.66 : planeY = - dirX * 0.66` to `1.0`, then `0.4`.
- **No fog** (ch. 14, 15): set `light& = 256` instead of working it out
  from the distance. Then try fog that reaches 30 cells instead of 16.
- **Flat lighting** (ch. 15): remove the line that makes y-sides darker.
  Can you still tell where the corners are?
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
- **Doors that close** (ch. 11): count down a timer once a door is fully
  open, then let it slide shut again (unless you're standing in it).
- **Your own level** (ch. 21): draw a map in the `DATA` lines, or build one
  with the level kit in `neon-caster/levels/` (`python3 levels.py --check`
  checks hand-made maps too: doors, keycards, the exit).

**Bigger projects**
- **Look up and down** (ch. 14-16): everything uses `RENDER_H / 2` as the
  horizon. Make it a variable, move it with the mouse's Y movement, and
  fix up the floor, walls and sprites to use it. ("Y-shearing", as in
  Heretic and Duke Nukem 3D.)
- **Records instead of parallel arrays** (ch. 3): rewrite the monsters as
  one array of a `TYPE` with `x`, `y`, `kind`, `hp`, `state` fields.
- **Doors in the middle of their cell** (ch. 15): Wolfenstein's doors sit
  half a cell back from the wall face. Move the hit half a cell along the
  ray.

## What's in the folder

| Path | What |
|---|---|
| `neon-caster.bas` | the game and the course |
| `neon-caster/*.png` | textures (64 x 64), sprites, the guns |
| `neon-caster/sfx/` | sound effects, and `make-sfx.sh`, which builds them with PWMSFXR |
| `neon-caster/levels/` | the level kit: carves rooms with 45-degree walls and checks maps |

## Further reading

- Lode Vandevenne, [Raycasting](https://lodev.org/cgtutor/raycasting.html),
  [part II: floor and ceiling](https://lodev.org/cgtutor/raycasting2.html),
  [part III: sprites](https://lodev.org/cgtutor/raycasting3.html). These
  are the maths this game uses, explained with diagrams.
- Fabien Sanglard, *Game Engine Black Book: Wolfenstein 3D*. How the real
  thing squeezed all this onto a 1992 PC.
- The [QB64PE wiki](https://qb64phoenix.com/qb64wiki/) for every
  `_KEYWORD` used here.
