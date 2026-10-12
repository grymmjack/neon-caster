# NEON-CASTER: make a little FPS in QB64PE

NEON-CASTER is a complete first-person shooter in one file of plain QB64PE:
four levels, five kinds of monster, four guns, doors and keycards, exploding
barrels, a minimap, music, a menu with settings, and saved games. It's built like Wolfenstein 3D, as a *raycaster*, and the
source is written to be read: its comments are a course in how it all
works, in 24 chapters, from opening a window to casting rays - and then
handing the same 3D view to the graphics card with OpenGL.

This page is the map for that course. The lessons themselves are in
[`../neon-caster.bas`](../neon-caster.bas), right next to the code they
explain.

**You'll need:** some BASIC already (variables, arrays, loops, SUBs and
FUNCTIONs). Everything else, from the 3D maths to the QB64PE features, is
explained as it comes up.

## Running it

1. Install [QB64 Phoenix Edition](https://qb64phoenix.com) 4.7 or newer
   (the mouse look needs `_MOUSEHIDE _DISABLE`, new in 4.7).
2. Open `neon-caster.bas` in the QB64PE IDE and press F5, or compile it from
   a terminal: `qb64pe -x neon-caster.bas`.
3. The OpenGL renderer's shaders use the GLSL library from
   [QB64_GJ_LIB](https://github.com/grymmjack/QB64_GJ_LIB): clone it next to
   this repository (`../../../QB64_GJ_LIB` from the game, as the `$INCLUDE`
   lines at the top and bottom of the source say).
4. Keep the `neon-caster/` folder next to the program. All the pictures,
   sounds and music are in there. Your settings and saved games go in
   `neon-caster/saves/`.

| Control | Does |
|---|---|
| Mouse | look around |
| W A S D | walk and strafe |
| Click or Ctrl | fire |
| Space | open doors, use the exit |
| 1-4 or mouse wheel | choose a gun |
| Right button (hold) | aim down the sights (zooms in) |
| Esc | the menu: pause, new game, save, load, settings, exit |
| F5 / F9 | quick save / quick load |
| Tab | the full-screen map (all of it once you've found the map pickup) |
| K / G | testing cheats: every keycard / god mode |

Every key can be changed in the menu, under **SETTINGS > CONTROLS**. The
menu works with the arrow keys or W A S D, Enter, and Esc to go back - or
just point and click.

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
| **Drawing it** | 14 Light, and the floor and ceiling | per-cell coloured light (Doom-style), flicker and strobe effects, floor casting, fog, `AND 63` texture wrapping |
| | 15 The walls: the raycaster | rays, the DDA grid walk, fish-eye correction, texturing |
| | 16 Sprites | camera space, painter's algorithm, hiding behind walls |
| | 17 Onto the screen | `_MEMCOPY` and `_PUTIMAGE` scaling |
| | 18 The gun and the HUD | alpha colours, the minimap, bars and text |
| **The rest** | 19 Game events | `GOSUB` routines and why they're used here |
| | 20 Levels | `RESTORE`/`READ`, carrying your gear between levels, the tally screen |
| | 21 The splash screen, the menu, settings and saved games | a menu driven by a list, `_KEYHIT` vs `_KEYDOWN`, easing animations, a settings file, `PUT`/`GET` save files |
| | 22 The levels' data | the map format: make your own levels |
| | 23 The helpers | the SUBs and FUNCTIONs, grouped by topic |
| **On the GPU** | 24 The same view, drawn by the graphics card | `SUB _GL` and OpenGL: triangles, texture coordinates, a camera matrix and `_glFrustum`, the depth buffer, alpha test; sharing a frame safely with double buffering; batching with `_glDrawArrays`; why OpenGL questions stall; GLSL shaders for bump mapping, specular highlights, self-lit neon, animated textures and moving point lights; smooth (bilinear) light; projected shadows; additive glows and particles; a mirrored pass for wet floors; render targets and post-processing (bloom, heat shimmer, hurt pulse, rail zoom, scanlines, CRT, retro resolution); premultiplied alpha; looking up and down |

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
- **Your own level** (ch. 22): draw a map in the `DATA` lines, or build one
  with the level kit in `neon-caster/levels/` (`python3 levels.py --check`
  checks hand-made maps too: doors, keycards, the exit).

- **Your own menu screen** (ch. 21, 23): add a SCR_ constant, a `CASE`
  for it in `BuildMenu`, and a button that leads to it. A new setting is
  one `DefineSetting` line plus an `AddSettingItem`.
- **A splash picture** (ch. 21): drop a `splash.png` (800 x 600) into
  `neon-caster/` and it replaces the title on the splash screen.

- **Your own lights** (ch. 14, 22): add a line to a level's lights - try
  a red strobe (effect 3) in a dark corridor, or set a level's ambient
  brightness to 40 and light it only with lamps.

**The graphics card** (set RENDERER to OPENGL and SHOW FPS on, in
SETTINGS > VIDEO, along with RETRO RESOLUTION and LOOK UP / DOWN; every
effect has a switch in SETTINGS > EFFECTS)
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
  `_GL_NEAREST`s to `_GL_LINEAR`. Blurry or better?
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
