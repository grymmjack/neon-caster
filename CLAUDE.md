# NEON-CASTER - notes for Claude

A first-person shooter and a 24-chapter QB64PE course. `neon-caster.bas`
is the front page (the course's introduction, start-up, the game loop) and
includes the rest, laid out like DRAW. Assets live in `neon-caster/`. Use
`qb64ref ~/git/neon-caster ...` (see the global CLAUDE.md) to find QB64
definitions and references: it follows the includes.

## Source layout

- Folders by subsystem: `CORE WORLD GAME LEVEL RENDER GL MENU EDITOR AUDIO
  DEMO ACH`, each module a `NAME.BI` (CONSTs, DIM SHARED, and start-up that
  only fills in its own tables) and a `NAME.BM` (SUBs and FUNCTIONs). `LOOP/07-FRAME.BI` ... `18-HUD.BI` are the game loop's chapters,
  `$INCLUDE`d in place inside the DO ... LOOP in `neon-caster.bas`.
- `_ALL.BI` is in declare-before-use order (a CONST or array before
  anything that uses it, in any file); `_ALL.BM` order doesn't matter.
  Includes live only in the root files (paths `./FOLDER/FILE`).
- No GOSUB or GOTO (they break the editor's IntelliSense and flow): code
  is SUBs and FUNCTIONs in a module's `.BM`, skips are `_CONTINUE` / `EXIT`.
  The only labels left are `GameError` (ON ERROR needs one) and
  `SpeechLines` (RESTORE). A new global goes in the module's `.BI`.
- **Shared names shadow.** `CORE/STATE.BI` shares the main program's working
  variables, short ones included (`i`, `k`, `x`, `y`...). A SUB using one of
  those as its own must `DIM` it (most already do: `DIM ... ' (its own...)`)
  or it silently uses the shared one. Converted SUBs are `SUB X STATIC`. Start-up that depends on other modules' (settings loaded, pictures
  loaded) belongs in `neon-caster.bas`'s STARTING UP.
- The chapters' text stays with their code: a chapter's banner is at the
  top of its file. `neon-caster/TUTORIAL.md` maps chapter to file.

## Build

```
~/git/qb64pe/qb64pe -w -x neon-caster.bas -o neon-caster.run
```

The output must not be called `neon-caster`: that's the asset folder. CI pins
QB64PE to the commit in `.github/workflows/build-release.yml` (`QB64PE_REF`).
`neon-caster.run` and `neon-caster/saves/` are git-ignored.

## Testing - the user plays this very folder

- **The repo build is the user's game.** `neon-caster/saves/` here holds their
  real settings and saved games, and they may have `neon-caster.run` open.
  Never delete or clean up anything in `neon-caster/saves/`, and don't
  overwrite or delete the repo's `neon-caster.run` without asking.
- **Test from a copy in the scratchpad:**
  ```
  P=<scratchpad>/play; rm -rf $P; mkdir -p $P
  cp -as "$PWD/neon-caster" $P/ && rm -rf $P/neon-caster/saves
  ~/git/qb64pe/qb64pe -w -x neon-caster.bas -o $P/neon-caster.run
  ```
  Hard links (`cp -al`) fail: /tmp is another disk. The symlinked copy writes
  its own `saves/`.
  The copy links each file that existed when it was made: assets added
  later (new sounds, pictures) are missing from it until linked in too -
  remake it, or `ln -s` the new ones. A test that "passes" without them
  only proves the code path, not the asset.
- **Xvfb's OpenGL is software (llvmpipe)**: it breaks depth ties
  consistently, so z-fighting and similar GPU-only artefacts don't show
  there. When the user sees one, reason it out from the code.
- **Never drive the user's display.** Run GUI tests under `Xvfb :99` and find
  windows by the PID you started (`xdotool search --pid`), never by title:
  the user often has their own NEON-CASTER window open.
- **The desktop is Wayland: unset it for every test run.** QB64's error
  dialogs ("Critical Error", "Failed to initialize window") are a Qt helper
  that prefers `WAYLAND_DISPLAY` over `DISPLAY`, so they pop up on the
  user's screen even when the game is on :99. Start each run with
  `unset WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS; export XDG_SESSION_TYPE=x11 QT_QPA_PLATFORM=xcb DISPLAY=:99`,
  and check `xdpyinfo -display :99` first - never launch if :99 isn't up.
- **Silence every test run.** Xvfb hides the window, not the sound, and
  `+sfx 0` applies a few frames too late. Send the game's audio to a silent
  sink instead:
  ```
  pactl list short sinks | grep -q claude_mute || pactl load-module module-null-sink sink_name=claude_mute
  PULSE_SINK=claude_mute DISPLAY=:99 ./neon-caster.run ...
  ```
  (Checked: the stream lands on `claude_mute`, and WirePlumber saves no
  device for `neon-caster.run`, so the player's own game still plays aloud.)
- **Prefer the game's own command line** to xdotool:
  `./neon-caster.run +logfile out.log +map 5 +give all +wait 60 +screenshot five.png +quit`.
  `ConPrint` output goes to the log. A game started with `+` commands never
  saves settings. The map-from-above editor (`edit`, `newsector`) runs its own
  loop and stalls the command queue until a key (Tab) is pressed.
- To check a sound plays without listening, build a throwaway copy with a
  `ConPrint` probe in `PlaySfxPan` and count the log lines.
- **Check a compile by its `Output:` line**, not by the absence of the word
  "error": QB64PE reports most mistakes as e.g. `Name already in use (base)`
  plus a `LINE nnnn:` - grep for `Output:|in use|LINE|Caused`. If `Output:`
  is missing, the old binary is still there and tests run against it.
- **xdotool in the editor:** letter keys don't reach the game by `type` (bind
  movement to the arrows), and a mouse move to exactly the screen centre
  (400, 300) isn't seen - the game warps the pointer there. OpenGL under
  Xvfb is too slow for click timing; drive clicks with `+renderer 1`.
- **Demos are tests.** `+record NAME [SEED] [quit]` restarts the sector
  and records every frame's input (saves/demos/NAME.ncd, text); `+bot on`
  lets the autopilot play it. `+playdemo NAME quit` replays it and exits 3
  if it went out of step (4 if it couldn't play at all) - a sector still playing frame for frame the same.
  `NEON_DEMO_TRACE=1` logs each frame's state in both runs: diff the logs
  to find where they part. `NEON_DEMO_FAST=1` plays a demo back uncapped (no `_LIMIT 60`): checking them is quicker. Gameplay dice are `GRnd`, never `RND` (that's
  for looks), and nothing that changes the game may read `TIMER` - use
  `lvFrame`. Any change to gameplay can put shipped demos (neon-caster/demos)
  out of step: replay them, and re-record what changed.
  Droids roll by their own dice, `DRnd` (so they never shift `GRnd`).
  The shipped demos - one a sector, every set: `sectorN`, `newN`, `remixN`,
  `hugeN` - were recorded on the Mac (full speed OpenGL):
  `+renderer 2 +set look_up_down 1 +wait 30 +sectorset SET +map N +record NAME quit +bot on +wait 18000 +stopdemo`
  - without the wait OpenGL isn't up yet and the demo records `look 0`; the
  wait-and-stopdemo caps it (5 minutes, 15 for a huge one). A demo needn't
  reach the exit: one where the bot dies is fine. A demo records god, fly,
  notarget and buddha, and plays back with them.
- **Builds use `-f:ExtraCppFlags=-ffp-contract=off`** (CI does): without
  it the Mac fuses multiply-adds and plays a Linux demo differently.
- **Saving in a `cp -as` copy** replaces the symlinked level file with a real
  one (the repo's is untouched): put the symlink back before the next test,
  or later tests start from the edited level.

## Code gotchas

- **Arrays sized by a constant must use it.** `glSet` was sized 40 by hand,
  and the 41st setting (MODE) crashed the game. Size from `NUM_SETTINGS`,
  `NUM_LEVELS + MAX_CUSTOM` and so on.
- **Main-module variables aren't seen in SUBs** unless `DIM SHARED`. A SUB
  that reads `sndBarrel&` gets a local 0.
- **`AND` and `OR` don't short-circuit**: `IF a AND F(x)` calls `F` even when `a` is false. A FUNCTION used in a condition must not change anything (a shot's `ShotPasses` waking turrets woke every hidden turret in the sector, every shot).
- **A held key reads -1.** `1 + 9 * shiftOn` is 1 - 9 = -8 with Shift held;
  write `1 - 9 * shiftOn` for x10.
- **Loops of their own** (menu, tally, puzzle, editor, console) don't run the
  game loop's per-frame work. The sound limiter now keeps its own time
  because only the game loop called `SfxFrame`.
- **Runtime errors are trapped** (`ON ERROR GOTO GameError`): logged to
  `neon-caster/saves/errors.log` and the console, then `RESUME NEXT`. Check
  that log when something silently misbehaves.
- **A console command needs three things** in MENU/CONSOLE.BM: its `CASE` in `ConExec`, a `help` line in `ConHelp` (every alias too, and its place in the overview, 96 characters a line at most), and its name in `ConNames$` (Tab). The three have been checked against each other: keep them so. Console text takes colour codes, Quake's: `^1` red, `^2` green, `^3` yellow (a command's syntax in its help), `^4` blue, `^5` cyan, `^6` magenta, `^7` white, `^8` grey, `^9` orange, `^0` back to the line's own (`ConColour~&`); they take no width, and the log file gets the line without them.
- **Ammo is per gun**: cells (blaster), shells, rockets, rounds `{` (repeater), slugs `}` (railgun) - `AM_`, `NUM_AMMO`. Dropped or thrown cells go through `LootAmmo` (TossItem, DropItemAt): ammo for one of your energy guns, unless `lootExact` (a thief's cells back, the `item` command). The level kit's `split_ammo` places rounds and slugs in kit-built sectors.
- **Turrets have states**: `monTMode` (out when it wakes / held in / out), `monEject` (frames to come out), `monTWant`, `monTOff`; the `turret WHO WHAT` command drives them (console or trigger). `[monsters]` columns 10 and 11.
- **Console scripting**: `alias` (MAX_ALIAS, `AliasRun`, $1-$9 $*), `saves/autoexec.cfg` run at start-up (`ConAutoexec`, before the + commands); `ConSemi` splits at a `;` outside quotes - use it, not INSTR, wherever commands are split.
- **The autopilot's steps** (`BotStep`) mirror the game's rules: a block passes if it leaves 0.6 of a cell free, no drop of more than 3 walls, no death pit floor (`BotPits`); a pickup it failed to reach is left alone 20 minutes (`botItemIgnore`).
- Settings are one table (`DefineSetting`); text-valued ones like `qb64pe=`
  are read and written by hand in `LoadSettings`/`SaveSettings`. MODE is
  worked out from the others (`ModeNow`), never loaded.

## Achievements and Steam

- 50 achievements (`AchDef` lines in `AchSetup`) go through `lib/steam`
  (QB64_GJ_LIB's STEAM, vendored). With `NEON_APP_ID = 0` the library's
  mock keeps them in `saves/achievements.txt`. `steam/make_tables.py`
  writes Steamworks' CSVs from the `AchDef` lines; `steam/README.md` is the
  go-live guide.
- **A test run is a cheat run:** `+map`, `god`, `give`, `tp` and the like set
  `achCheat`, which holds achievements and records. Run with
  `NEON_ACH_TEST=1` to test them anyway. A level's own triggers don't count
  (`conFromTrig`).
- Badges: `neon-caster/achievements/NAME.png` and `NAME_locked.png` (64 px)
  and `steam/achievements/*.jpg` (256), drawn by pixelmon (`steam/badges.txt`
  has the prompts; use `--server rtx`, it's ~4x faster than local) and cut
  round by `steam/make_icons.sh FOLDER`.
- The sector clock (`levelStart!`) skips any frame over half a second (a
  menu, the console, the editor): read times through `frameAt!`, not
  `TIMER`, anywhere the game might be paused.

## Levels

- `neon-caster/levels/levelN.txt` (1-10) are built by the level kit:
  `cd neon-caster/levels && python3 levels.py --check` (or `--write`, which
  overwrites all ten - never after hand or editor edits). Running it with no
  flag just builds and checks in memory.
- Three more sets of ten, picked in GAME (sectorSet 1, 2, 3): NEW SECTORS
  `levels/new/levelN.txt` by `newsectors.py`, OLD SECTORS NEW
  `levels/remix/levelN.txt` by `remaster.py` (built from the originals),
  HUGE SECTORS `levels/huge/levelN.txt` by `hugesectors.py` (112-192 cells:
  districts on a grid, each sector in its own process with `lvlkit.N` its
  size, seeds tried until the kit passes it). All take `--write` / `--check` like levels.py; `--write` rewrites all ten
  of its set. Test one with `+sectorset new +map 3` (or `remix`); saves keep
  the set as 100 a set on in the sector number.
- Teleport tests: a `+use` on the exit stalls the command queue in the
  tally (it waits for a click) - a `timeout` there means the exit worked.
  Grab the screen with `ffmpeg -f x11grab -i :99.0` to see it.
- `custom1-11.txt` are showcase sectors (`showcase.py`), `custom18.txt` is THE MONOLITH (`giant.py`: the biggest sector - 256 x 256, ceiling 240 eighths, a pyramid to 200 and a lift near the ceiling), `custom19.txt` is THE STOCKPILE (`stockpile.py`: liquid barrels, chests, mimics, the jetpack), `custom14.txt` is
  THE NEON EXPO (`megasector.py`: every feature in one sector). `custom12`
  and `custom13` are the user's own - never write them.
- Players' own sectors are `neon-caster/levels/custom/customN.txt`
  (sector 10+N), made by NEW SECTOR / `newsector`; the kit never touches them.
  Check one with
  `python3 -c "import lvlkit; lvlkit.check_level(lvlkit.read_level_file('custom/custom1.txt','custom1'), '..')"`.
- 3D props: any decoration or pickup with a `neon-caster/models/NAME.obj` is a model (NAME: its picture's name; keycards share `keycard`, tinted). `models.py --write [NAME]` (run with `~/ComfyUI/.venv/bin/python`: numpy, Pillow) builds each from its MODERN painting by `SHAPES`: extruded (outline pushed out to a depth, with optional thinner bands - a desk's monitor) or lathed (outline spun round), and writes the `.obj`, textures (64, `hd/models/` 256) and 8 pictures round it. Only the chair and plant are pixelmon meshes (`models/src/`): AI meshes from one painting came out lumpy and broken, so don't go back to them for boxy or round props. OpenGL draws the model within `MODEL_NEAR` cells (`GLDrawModel`), the software renderer the nearest picture (`ModelPic`, RENDER/MODELS.BM). ComfyUI's Python hangs on a script piped to stdin: give it a file.
- Monsters 11-16 (sniper `1`, trooper `5`, ripper `6`, warden `7`, colossus `0`, turret `~` ceiling / `_` floor) fight by `mtypeStyle` (`MonStyleTurn`, GAME/MONSTERS.BM); map characters come from `MonChars$`/`MonOfChar`, not a literal list. Lasers and beams are lines of glowing dots (`AddBeam`, chapter 16). A turret can't be hit till it's out (`monDeploy`), and is a 3D model (`mtypeMdl`: any monster with a `models/NAME.obj`; models.py builds it from parts, `turret_kit`); a `;` wall is a turret control panel - the word hack (GAME/HACK.BM) - and a vending machine is a slot machine (`SlotUse`, GAME/ARCADE.BM: its result rolled by `GRnd` first, so a demo plays it back without the screen).
- Gun 5 is the rocket launcher (`W_ROCKET`, ammo `AM_ROCKETS`, `NUM_AMMO` kinds); pickups `)` launcher and `(` rockets (`ItemChars$`/`ItemOfChar`, GAME/ITEMS.BM - every pickup-character list goes through them). Rockets, turret missiles and the spray turrets' puffs are bolts with a kind (`boltKind`, GAME/ROCKETS.BM: `BoltFly`, `BlastSized`, `PuffHurt`); plasma bolts still fly by chapter 13's own code, so old demos stay in step. Saves keep the launcher and rockets at the end of the file (older saves load without them).
- Turrets have a mount (`monFrom`: `TURRET_CEIL` `~`, `TURRET_FLOOR` `_`, `TURRET_WALL` `|` - `TurretMount` sets a wall one against its wall once the level is built) and a weapon (`monWeap`, `TW_`: the 8th number of a `[monsters]` line, left off when 0); GAME/TURRETS.BM fires all but plasma. `summon wallturret flame` and the like. NEW SECTORS places them by `ARMS` in newsectors.py (`arm`, checked against the level kit's heights).
- **Sectors have their own size**: `MAP_SIZE` (256) is only the arrays' capacity; `mapN` is this sector's (its file's rows/columns, square - the game's 48). Everything that walks or bounds the map uses `mapN` (a 48 sector plays exactly as before); arrays and the load's clears use `MAP_SIZE`. A cell index (`y * mapN + x`) can pass 32767: keep it in a LONG. Per-frame work stays near you: lights relit within `LIGHT_NEAR`, rays stop at `RAY_FAR` (the fog's black by 16 cells), doors moved from a list (`ListDoors`). Heights go to `H_MAX` (240 eighths): past `z` each is one of `H_HIGH$`'s spare characters in memory (one byte a cell - why 240 is the top) and `[floor high]` / `[ceiling high]` in the file. The world mesh grows as it needs (`GLMeshCorner`). lvlkit's `read_level_file` sets `lvlkit.N` to the file's size.
- **A level file's numbers are clamped** as it loads (`LevelClamp`, LEVEL/LEVELFILE.BM: every section's cells kept on the map, heights to H_MAX, times and speeds within reason), its edge is made wall and a map with no start gets one - a hand-typed or broken file loads, it doesn't hang. Section caps (`MAX_ZONES` 256, `MAX_PAIRS`, `MAX_LIGHTS` 1024...) are checked by the kit's `check_level` too: past them the game drops the rest.
- **Liquid barrels, chests, mimics, jetpacks** (GAME/BARRELS): one map character for every liquid barrel, `:` - its liquid (and any barrel's stack, `o` too) in a `[barrels]` line (`x, y, liquid 0-5, stack 1-8`, `BARREL_STACK`, and no more than fit under the ceiling: `StackFits`); decoration kinds 22-26 inside (`DK_LQBARREL + LQ_`), 27 the chest `[`. Decoration characters go through `DecoChars$` / `DecoOfChar` (not literal lists). A painted wreck (`NAME-wreck.png`, the chest's `chest-open.png`) and its model replace `MakeWreck`'s. The mimic is monster 17 (`]`, `MT_MIMIC`): drawn as the chest (`S_MIMICNAP`, `mimic-asleep` model) till `MimicWake`. Jetpack `` ` `` and fuel `,` (items 22, 23): a booster - while FLY / JET UP is held (or looking up and walking) it pushes `playerVZ` up (`JET_THRUST`) and burns `JET_BURN`; let go and gravity has you (`rocketAir`: a rocket jump's fall). `jetOn` = firing this frame. Each can's own amount: `[fuel]`, `itemAmt`. Stacks: `decoZ`, `StacksSettle`, `DecoCellAfter`; shots check height only on a stack (demos unchanged).
- **Diagonals** (`/` `\`): the open half walks like a floor (Walkable's step and headroom checks), and one sunk more than a step below the floors it opens onto is raised to them at load (BuildLevel) - sector 9's band was a trap.
- **Saved games end with a tail per addition** (rounds and slugs, then the turrets' states, flight, vending machines, `lvFrame`), each read only `IF LOC < LOF`: an older save loads as the sector starts it. Something new to save goes on the end the same way.
- A level file should list 6 walls, 4 floors and 2 ceilings: a missing or misspelt one is drawn as `wall.png` (`LoadTex` says so in the console); only a missing `wall.png` itself stops at "Missing texture" waiting for a key.
- **Map characters ran out** (all printable ASCII is used but space): `"` is a *thing* - its kind (a decoration, pickup or monster by name: `ThingCode`, LEVEL/THINGS.BM) in a `[things]` line; `'` a note; `-` bars (glass with `BARS_HP`: never breaks). New kinds go in as things, not characters. `[doors]` `[things]` `[notes]` `[smears]` are kept as raw text lines (`lvlXSec$`/`lvlXtra$`, `XtraFind`/`XtraSet`/`XtraField$`) - the writer, undo snapshot (after `CHR$(17)`), arrow moves, resize and `EditPut` all handle them in one place.
- GAME/SECURE.BM: stronghold doors (`doorHP`, `KickDoor`), keypad doors and safes (`KeypadRun`, demo result `c`; codes `?` are made up by `GRnd` at load, `{code x y}` in notes), searching desks/bookshelves (a cell-hash roll, not `GRnd`, so old demos with a Space at a desk stay in step), broken computers + repair kits, computers hacked by the word hack (`hackTitle$`, `hack x y` triggers), notes (`NoteRun`), the guard dog's bark (`WakeNear`), and **views from elsewhere** - a security camera's or your rocket's (`ViewAwayGo`/`ViewBackGo` swap the eye round chapters 14-17; the rocket camera is view-only, the camera monitor is driven by recorded inputs).
- Smears are decals kept in `1..decalBase` (`SmearsBuild`); the marks shots leave take turns with the rest. `DecoFlat` (bodies, notes, cameras...) replaced the old `<> DK_BODY` checks. Invulnerability gates `HurtPlayer` and `Poisoned` (`invTimer`), not pits.
- GAME/ALARMS: alarm switches (`DK_ALARM`, on = `vendState` 0), `AlarmRaise` (wakes everything within `ALARM_REACH`), `alarmDist` (the guards' flood-filled way to a switch: `BuildAlarmWay` again whenever a switch changes), guards (`MT_GUARD` 19, `GuardRun`), `AlarmMobPress` rolls `GRnd` only beside a switch (old sectors' demos untouched). `drain X Y` (WORLD/LIQUIDS: `DrainStart`/`DrainStep`). ROCKET CAM is a key bind (`BIND_ROCKETCAM`, mouse buttons bind as `KEY_MOUSE + n`), view-only. JUMP (`BIND_JUMP`, demo bit `J`: `DB_JUMP`, so `DB_GUN` is 65536). A sector's gravity: `lvlGravity` (percent; exactly `FALL_G` at 100 - keep it that way, or old demos drift). Liquid opacity is per cell: `[liquid opacity]`, `liqOp`. Jump pads (GAME/JUMPPADS: `DK_JUMPPAD`, `jpDir/jpAng/jpPow`, `padAir` - no walking in the air, `knockX/Y` kept; monsters: `MonPadStep`, `monFly` as their height) and launch controls (`DK_PADPC`, `JumpPadRun`, demo result `j`).
- `custom20.txt` is THE COMPOUND (`compound.py`): every one of those in one sector. `custom21.txt` is THE LAUNCH BAY (`launchbay.py`): jump pads (fixed, and one set by its launch control from a note's numbers), 60% gravity, the jetpack and fuel cans, a pool clear-to-solid, floors dry-to-soaked. `MAX_CUSTOM` is 30 (MORE SECTORS lists 11-30, scrolling); 22-30 are free.
- **Floor wetness** (how much of OpenGL's mirror image a floor shows): `wetness = 0-9` in the header (`lvlWet`; left out, -1: each floor picture's own `glTexReflect`), `[floor wetness]` per cell (`wetCell`, `FloorWet`). The GPU path's mesh has floor kinds 4-13 for them (`GL_MESH_KINDS`), the other path a pass per level (`GLWetKey`); `glFloorWet` overrides the reflection in `GLBindSlot`. A change needs `glMeshVersion` bumped. Console `wetness`, `wet X0 Y0 X1 Y1 N`.
- **Models cost CPU per corner** (`GLDrawModel` works out every corner each frame): a small one (`mdlFrame` < 0.75 - barrels, pickups) is a model only within `MODEL_NEAR_SMALL` (6), one under a cell across within `MODEL_NEAR_MID` (9); round props are lathed at 10-12 slices (models.py `lathe` seg/tol), and every model but a turret's parts is `simplify`d (corners snapped to a grid, 16 steps across a pickup, 22 a prop; the pixelmon meshes 16) - 19,163 triangles in all down to 10,712. Keep a new model near 200. THE STOCKPILE's stacks were 47,000 corners a frame. Xvfb's llvmpipe is 3-4 fps in every sector, so it can't show this: count corners with a probe build instead.
- **The eyebot** is monster 20 (`MT_EYEBOT`, a thing `eyebot`; `STYLE_EYEBOT` in MonStyleTurn): lasers (`MonLaser`), then a rush (`monRush` 1) and `EyebotBoom` (a `BlastSized`); shot mid-rush it's `monRush` 3 and blows up on its next turn (HitMonster is STATIC - never blast from inside it). Its eye: `S_EYE` (yellow, hunting) and `S_EYE + 1` (red, rushing). It's left out of the Bestiary (`KILL_KINDS` stays 18). The robot dog is drawn by `DogPose` (head on running at you, mirrored side on - `drawMirror`), looks only.
- **The network** (GAME/NETWORK): `NetSetup` (end of JackIn) adds ICE kinds (`iceKind`: hunter, sentinel, tracer, black - `IceTurn`), firewalls (`fence*`, laser beams kept 2 frames: chapter 13 counts beams down before chapter 16 draws them) and far cells for the TRACE (`traceAmt`, `NetFrame`). Its places come from `NRnd` (its own dice), so the hunters JackIn always placed still are, as before - but the new ICE fights with `GRnd`, so demos that jack in are re-recorded. `cores` lists firewalls and the trace.
- **Voices**: NEXUS is Kokoro `bm_lewis` through `neon-caster/speech/vocoder.py` at 85 Hz (soundmon `--narrate-file`, resampled to 22050); soldiers `am_onyx` at 120, heavies `bm_lewis` slowed at 68, cyborgs `am_fenrir` at 150. Lines are `DATA` in GAME/NEXUS.BM (`MAX_LINES`); `LineCount("taunt")` counts them, `MonVoice$` picks a monster's group, `MonSpeak` says one.
- **Watching a camera** (`viewOn = VIEW_CAM`) ignores every input but the walk keys (leave) and USE (next camera): `inBits` is masked in chapter 8, and `turn` is 0. After any screen of its own (menu, keypad, computer, hack...) `mouseSettle` drops the mouse for 8 frames: the pointer's snap back to the middle isn't a turn.
- `LEVEL-EDITOR-GUIDE.md` documents the editor; keep it in step with editor
  changes (it ships in every release).

## Releases

Use the `create-release` skill. A `v*.*.*` tag push makes CI build Windows,
macOS and Linux and publish the release. To re-release the same version:
save the notes, `gh release delete vX -R grymmjack/neon-caster --yes`,
`git tag -fa vX`, `git push --force origin vX`, wait for CI, then
`gh release edit vX -R grymmjack/neon-caster --notes-file ...`.
Always pass `-R grymmjack/neon-caster` to `gh`. Let the previous build
finish first (`gh run list -R grymmjack/neon-caster`): while one is running
there's no release to delete yet, and it publishes over whatever comes next.
