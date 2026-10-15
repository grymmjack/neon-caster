# NEON-CASTER - notes for Claude

A first-person shooter and a 24-chapter QB64PE course in one file,
`neon-caster.bas`. Assets live in `neon-caster/`. Use `qb64ref` (see the
global CLAUDE.md) to find QB64 definitions and references.

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

- 45 achievements (`AchDef` lines in `AchSetup`) go through `lib/steam`
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
