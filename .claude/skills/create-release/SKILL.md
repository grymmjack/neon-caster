---
name: create-release
description: Prepare a NEON-CASTER release — bump the version, check the docs and levels, compile, write release notes; the tag push makes CI build and publish it
---

# Release Skill

When the user invokes this skill (e.g. "do a release", "prep a release", "release skill"), execute the following steps **in order**. Do not skip steps. Do not batch steps that require user input.

(Adapted from grymmjack/DRAW's create-release skill.)

---

## Step 1 — Determine version bump

Ask the user:

> "Is this a **major**, **minor**, or **patch** release?"
> (major = breaking/large new features, minor = new features, patch = bug fixes / polish)

Parse the current version from `neon-caster.bas`:

```
CONST GAME_VERSION$ = "X.Y.Z"
```

Compute the new version:

- **major** → `(X+1).0.0`
- **minor** → `X.(Y+1).0`
- **patch** → `X.Y.(Z+1)`

Show the user: `Current: X.Y.Z → New: A.B.C` and confirm before proceeding.

---

## Step 2 — Collect changes

Run:

```bash
git log --oneline --no-merges $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD
```

If no tags exist, compare against the very first commit.

Also check **merged pull requests** since the last tag:

```bash
gh pr list --repo grymmjack/neon-caster --state merged --limit 20 --json number,title,body,mergedAt,headRefName --jq '.[] | "PR #\(.number): \(.title) | Branch: \(.headRefName) | Merged: \(.mergedAt[0:10])\n\(.body)\n---"'
```

Filter to PRs merged **after** the last tag date (`git log --format="%ci" -1 <tag>`).

Also review the **current conversation history** for features, fixes, or changes discussed and implemented during this session that may not yet be in the git log (e.g. uncommitted work).

Produce a deduplicated, categorised list of changes:

- **New Features** — new sectors, monsters, weapons, editors, settings, console commands
- **Improvements** — refinements to existing features, art, sound, performance
- **Bug Fixes** — defects corrected
- **Internal / Refactoring** — code structure, the level kit, CI (not user-facing)
- **Breaking Changes** — anything that changes level files, `monsters.txt`, `hud.txt`, `settings.ini`, saved games or default keys

---

## Step 3 — Update `neon-caster.bas`

Replace:

```qb64
CONST GAME_VERSION$ = "X.Y.Z"
```

with:

```qb64
CONST GAME_VERSION$ = "A.B.C"
```

(It shows in the window title, the bottom right of the menu, and the console's `version` command.)

---

## Step 4 — Update `neon-caster/TUTORIAL.md`

Review the tutorial against the change list from Step 2:

- The **controls** table and the console paragraph under "Running it": add, change or remove keys, mouse actions and console commands.
- **"The sectors, and their heights"** table: if a sector's layout changed.
- **"Things to try"**: if a change makes an entry wrong (a renamed SUB, CONST or file), fix it; add an entry for a notable new feature if there's a good small experiment for it.
- **"What's in the folder"**: new or moved files and folders.

Preserve the existing formatting and table structure. Only edit sections that need updating.

---

## Step 5 — Update `README.md`

Review `README.md` against the change list from Step 2:

- The opening feature paragraph (add new features, update changed ones, remove removed ones)
- The download table, if the release files or supported systems changed
- The screenshots in `docs/screenshots/` if the game has visually changed a lot (note only — do not replace automatically)
- Do not rewrite sections that are still accurate

---

## Step 6 — Check the levels

If any level, the level kit or the map characters changed since the last tag:

```bash
cd neon-caster/levels && python3 levels.py --check
```

It must report no `ERROR` lines (it checks every key and the exit can be reached, by the game's own rules for heights, lifts and teleporters, and that there's nowhere you can get stuck). Report any errors and fix before continuing.

---

## Step 7 — Compile verification

```bash
qb64pe -w -x neon-caster.bas -o neon-caster.run 2>&1 | tail -5
```

(Use the user's qb64pe — e.g. `~/git/qb64pe/qb64pe` — at the commit CI pins: `QB64PE_REF` in `.github/workflows/build-release.yml`.) Confirm `Output: .../neon-caster.run` appears. Report any errors and fix before continuing. Delete `neon-caster.run` and `neon-caster/saves/` afterwards (they're ignored, but keep the tree clean).

---

## Step 8 — Output release notes in chat

Print the following markdown block in chat so the user can copy it to the GitHub release:

---

```markdown
## NEON-CASTER vA.B.C

> Released YYYY-MM-DD

### New Features

- ...

### Improvements

- ...

### Bug Fixes

- ...

### Internal / Refactoring

- ...

### Breaking Changes

- ...

```

---

## Step 9 — Tell the user how it ships

Releases are built by GitHub Actions, not by hand. Tell the user the commands (do not run them):

```bash
git commit -am "NEON-CASTER vA.B.C"
git tag -a vA.B.C -m "NEON-CASTER vA.B.C"
git push && git push origin vA.B.C
```

Pushing the `vA.B.C` tag runs `.github/workflows/build-release.yml`: it builds Windows, macOS (Apple silicon) and Linux, smoke-tests Linux in both renderers, and publishes the release with the three downloads. Once it's up, the notes from Step 8 can go on top of the generated ones:

```bash
gh release edit vA.B.C --notes-file notes.md
```

---

## Rules

- **Always ask** before applying a version bump (Step 1). Never assume.
- **Never auto-commit, tag or push**. The user commits and tags; the tag push publishes the release.
- If a step produces no changes (e.g. TUTORIAL.md is already accurate), state that explicitly and move on.
- If the git log is empty (no commits since last tag), say so and rely entirely on the conversation history for the change list.
- Keep release notes **user-facing**: omit internal refactors unless they affect users (level file format changes, settings renames, etc.).
- Date in release notes should be today's date in `YYYY-MM-DD` format.
