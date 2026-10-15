# NEON-CASTER

A first-person shooter in one file of QB64 Phoenix Edition BASIC, and a
course in how it's made. Ten sectors of a neon space station, ten kinds of
monster, four guns and a kick, glass you can shoot through, floors and
ceilings at every height, lifts and bottomless pits, open skies, teleporters, data
stations that turn the level into a wireframe network, code terminals that
lock you in until you fix a real QB64 program, and a villain who talks to
you. With a level editor built in - point and click inside the level in 3D
or on the map from above, with a picker of every wall, floor, door, item,
monster and light - and a monster editor and a HUD editor. Eleven more
sectors built with the editor come with it, three of them outdoors.

It draws its 3D two ways: a software raycaster, like Wolfenstein 3D, and an
OpenGL renderer with bump mapping, moving lights, wet floors, bloom and CRT
effects. Every picture comes in pixel art or a high-resolution painting
(ART in the video settings).

| | |
|---|---|
| ![The cryo lab's control room](docs/screenshots/cryo-lab.jpg) | ![The boss arena](docs/screenshots/boss-arena.jpg) |
| ![Jacked into the network](docs/screenshots/network.jpg) | ![The data vault's server canyon](docs/screenshots/data-vault.jpg) |
| ![A code terminal: a real QB64 program, compiled and run](docs/screenshots/code-terminal.jpg) | ![The level editor in 3D: a statue's pane, the picker, a lit painting](docs/screenshots/editor-walk.jpg) |
| ![The level editor's map view: a door's pane, the picker](docs/screenshots/editor-map.jpg) | ![The Conservatory's light lab, built with the editor](docs/screenshots/light-lab.jpg) |

## Play it

Download it for your computer from the
[releases page](https://github.com/grymmjack/neon-caster/releases), unzip
it, and run the program inside. Keep it next to its `neon-caster` folder:
that's all the pictures, sounds, music and levels.

| | Download | Run |
|---|---|---|
| Windows 10/11 | `neon-caster-windows-x64.zip` | `neon-caster.exe` |
| Mac, Apple silicon (M1 and later) | `neon-caster-macos-arm64.zip` | `neon-caster-mac` |
| Linux, x86-64 | `neon-caster-linux-x64.tar.gz` | `neon-caster.run` |

**On a Mac:** the program isn't signed, so macOS stops it the first time.
Right-click it and choose **Open**, or run
`xattr -dr com.apple.quarantine neon-caster` on the unzipped folder.

**Controls:** mouse to look, W A S D to move, Shift to run, click to fire,
right button to aim, Space to open and use things, F to kick, 1-4 for guns,
Tab for the map, Esc for the menu and settings, ` for the console, F2 for
the level editor. The full list is in the tutorial.

**The programming puzzles need QB64PE.** A code terminal locks you in
until you fix a little QB64 program, and to really compile and run your
fix the game needs [QB64 Phoenix Edition](https://qb64phoenix.com)
installed:

1. Install QB64PE 4.7 or newer.
2. In the game, open **SETTINGS > QB64PE COMPILER** and point it at your
   `qb64pe` (type its path or its folder, or BROWSE for it). The screen
   says **COMPILING WITH YOURS** when it's found. In the console,
   `qb64pe /path/to/qb64pe` does the same.

The game looks for it by itself too (`$QB64PE`, your `PATH` and the usual
folders), so you may find it's already set. Without QB64PE the terminals
still let you through, but they only check your lines against the answer:
nothing is compiled or run.

**Make your own:** **GAME > YOUR SECTORS > NEW SECTOR** gives you a
blank sector (one room in solid wall) and opens the level editor on it.
Push walls back, sink pits, add doors, monsters and lights, paint any
picture on any face, set up ambushes, and Ctrl+S saves it to
`neon-caster/levels/custom/`. The [level editor guide](LEVEL-EDITOR-GUIDE.md)
explains every tool, key, map character and level-file field, and YOUR
SECTORS starts with eleven example sectors (three of them outdoors, under skies) built with the editor to take
apart.

**Quick looks:** **SETTINGS > MODE** sets every video and effects setting
at once. OLDSCHOOL is chunky pixels with no effects, 90S is 720P with
scanlines and most effects, and NEWSCHOOL is as sharp as your display goes
with everything on. All three are full screen 4:3. Change any setting
afterwards and MODE shows CUSTOM.

## Learn from it

The source, [`neon-caster.bas`](neon-caster.bas), is written to be read:
its comments are a course in 24 chapters, from opening a window to casting
rays and handing the 3D to the graphics card with shaders.
[`neon-caster/TUTORIAL.md`](neon-caster/TUTORIAL.md) is the map for it,
with dozens of things to try.

## How it was built

[`docs/`](docs) has two illustrated write-ups made during development: a
[showcase](docs/showcase/index.html) of every system with real frames from
the game, animations, sounds and performance heat maps, and the earlier
[roadmap run](docs/roadmap-run/index.html) report.

## Build it yourself

1. Install [QB64 Phoenix Edition](https://qb64phoenix.com) 4.7 or newer.
2. Compile: `qb64pe -x neon-caster.bas -o neon-caster.run` (on Windows,
   `-o neon-caster.exe`; on a Mac, `-o neon-caster-mac`). Don't call the
   program just `neon-caster`: that's the name of its folder.
3. Run it from this folder.

The OpenGL shaders come from the GLSL library in
[QB64_GJ_LIB](https://github.com/grymmjack/QB64_GJ_LIB); a copy is in
[`lib/glsl/`](lib/glsl).

Releases are built by GitHub Actions
([`.github/workflows/build-release.yml`](.github/workflows/build-release.yml))
on Windows, macOS and Linux whenever a `v*.*.*` tag is pushed, with QB64-PE
built from a pinned commit.

## How it was made

Written by grymmjack with Claude. The modern art was painted with
pixelmon (Stable Diffusion XL, guided by the pixel art); the sound effects
and music were synthesized; NEXUS's voice is text-to-speech through a
vocoder.

The footsteps, your cries when hurt or killed, the shock, the glass, the
lifts and the traps (`neon-caster/sfx/step1.wav`, `step2.wav`, `hurt.wav`,
`hurt2.wav`, `hurt3.wav`, `hurt-zap.wav`, `die.wav`, `glass-hit.wav`,
`glass-break.wav`, `lift-start.wav`, `lift-move.wav`, `lift-stop.wav`,
`trap-fire.wav` and `trap-electric.wav`) are from Imphenzia's Universal
Sound FX pack, used under its licence, and are not covered by the MIT
licence.

MIT licensed - see [LICENSE](LICENSE). The GLSL library in `lib/glsl` is
MIT licensed too.
