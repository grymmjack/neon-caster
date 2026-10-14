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
- **Never drive the user's display.** Run GUI tests under `Xvfb :99` and find
  windows by the PID you started (`xdotool search --pid`), never by title:
  the user often has their own NEON-CASTER window open.
- **Mute every test run.** Xvfb hides the window, not the sound. Start with
  `+sfx 0 +music 0 +speech 0`; command-line settings last only for that run.
- **Prefer the game's own command line** to xdotool:
  `./neon-caster.run +logfile out.log +map 5 +give all +wait 60 +screenshot five.png +quit`.
  `ConPrint` output goes to the log. A game started with `+` commands never
  saves settings. The map-from-above editor (`edit`, `newsector`) runs its own
  loop and stalls the command queue until a key (Tab) is pressed.
- To check a sound plays without listening, build a throwaway copy with a
  `ConPrint` probe in `PlaySfxPan` and count the log lines.

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

## Levels

- `neon-caster/levels/levelN.txt` (1-10) are built by the level kit:
  `cd neon-caster/levels && python3 levels.py --check` (or `--write`, which
  overwrites all ten - never after hand or editor edits). Running it with no
  flag just builds and checks in memory.
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
Always pass `-R grymmjack/neon-caster` to `gh`.
