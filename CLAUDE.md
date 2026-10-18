# NEON-CASTER - notes for Claude

A first-person shooter and a 24-chapter QB64PE course. `neon-caster.bas`
is the front page (the course's introduction, start-up, the game loop) and
includes the rest, laid out like DRAW. Assets live in `neon-caster/`. Use
`qb64ref ~/git/neon-caster ...` (see the global CLAUDE.md) to find QB64
definitions and references: it follows the includes.

## Source layout

- Folders by subsystem: `CORE WORLD GAME LEVEL RENDER GL MENU EDITOR AUDIO
  DEMO ACH`, each module a `NAME.BI` (CONSTs, DIM SHARED, and start-up that
  only fills in its own tables) and a `NAME.BM` (SUBs, FUNCTIONs and GOSUB
  routines). `LOOP/07-FRAME.BI` ... `18-HUD.BI` are the game loop's chapters,
  `$INCLUDE`d in place inside the DO ... LOOP in `neon-caster.bas`.
- `_ALL.BI` is in declare-before-use order (a CONST or array before
  anything that uses it, in any file); `_ALL.BM` order doesn't matter.
  Includes live only in the root files (paths `./FOLDER/FILE`).
- A new SUB/FUNCTION goes in its module's `.BM`; a new GOSUB routine too
  (they're main-module code, after the loop - one that falls through into
  the next must stay just before it). A new global goes in the module's
  `.BI`. Start-up that depends on other modules' (settings loaded, pictures
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
  if it went out of step - a sector still playing frame for frame the same.
  `NEON_DEMO_TRACE=1` logs each frame's state in both runs: diff the logs
  to find where they part. Gameplay dice are `GRnd`, never `RND` (that's
  for looks), and nothing that changes the game may read `TIMER` - use
  `lvFrame`. Any change to gameplay can put shipped demos (neon-caster/demos)
  out of step: replay them, and re-record what changed.
  Droids roll by their own dice, `DRnd` (so they never shift `GRnd`).
  The shipped ten were recorded on the Mac (full speed OpenGL):
  `+renderer 2 +set look_up_down 1 +wait 30 +map N +record NAME quit +bot on`
  - without the wait OpenGL isn't up yet and the demo records `look 0`.
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
- **A held key reads -1.** `1 + 9 * shiftOn` is 1 - 9 = -8 with Shift held;
  write `1 - 9 * shiftOn` for x10.
- **Loops of their own** (menu, tally, puzzle, editor, console) don't run the
  game loop's per-frame work. The sound limiter now keeps its own time
  because only the game loop called `SfxFrame`.
- **Runtime errors are trapped** (`ON ERROR GOTO GameError`): logged to
  `neon-caster/saves/errors.log` and the console, then `RESUME NEXT`. Check
  that log when something silently misbehaves.
- Settings are one table (`DefineSetting`); text-valued ones like `qb64pe=`
  are read and written by hand in `LoadSettings`/`SaveSettings`. MODE is
  worked out from the others (`ModeNow`), never loaded.

## Achievements and Steam

- 49 achievements (`AchDef` lines in `AchSetup`) go through `lib/steam`
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
- Two more sets of ten, picked in GAME (sectorSet 1, 2): NEW SECTORS
  `levels/new/levelN.txt` by `newsectors.py`, OLD SECTORS NEW
  `levels/remix/levelN.txt` by `remaster.py` (built from the originals).
  Both take `--write` / `--check` like levels.py; `--write` rewrites all ten
  of its set. Test one with `+sectorset new +map 3` (or `remix`); saves keep
  the set as 100 a set on in the sector number.
- Teleport tests: a `+use` on the exit stalls the command queue in the
  tally (it waits for a click) - a `timeout` there means the exit worked.
  Grab the screen with `ffmpeg -f x11grab -i :99.0` to see it.
- `custom1-11.txt` are showcase sectors (`showcase.py`), `custom14.txt` is
  THE NEON EXPO (`megasector.py`: every feature in one sector). `custom12`
  and `custom13` are the user's own - never write them.
- Players' own sectors are `neon-caster/levels/custom/customN.txt`
  (sector 10+N), made by NEW SECTOR / `newsector`; the kit never touches them.
  Check one with
  `python3 -c "import lvlkit; lvlkit.check_level(lvlkit.read_level_file('custom/custom1.txt','custom1'), '..')"`.
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
