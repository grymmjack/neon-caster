# Level maker: a looks pass on every set, and a fifth set made by a new maker (2026-10-29)

Rick's asks: "modify the level creator to take advantage of [the editor's new tools] - lighting,
subdivided textures, colours, paints - much more finessed and purposeful"; then "we have alarms,
notes, codes, hazards, turrets... we can make a better level maker". Answers: a NEW SET OF TEN;
the looks pass over ALL FOUR SETS once tuned.

## A. Looks pass - neon-caster/levels/lvldress.py (looks only: demos stay in step)
- [x] A1. lvldress.py: rooms (zones, else floor between doors), roles (start exit key hazard sealed
      hall room corridor) and colours; trim in pieces (skirting + neon line, a high line in rooms that
      matter), wall lights (a lit strip piece + a lamp-less light 0.25 out), key/exit/sealed door lights
      and tinted floors in front, room ambients (cell lights), wetter floors near liquid, glowing props
      tinted; budgets (PC 900, faces, lights); tree check (tree_leaves); asserts nothing you play changed
- [x] A2. Pilot: NEW 1 dressed as custom22 in a scratch copy, screenshots plain vs dressed (OpenGL)
- [x] A3. Tune: lines thinner in tall rooms, strips saturated (neon needs bright AND colourful), lights
- [x] A4. Round trip (clean - only empty [zones]/[events] headers in 3 customs): read_level_file + level_text loses nothing on all 40 shipped files
- [x] A5. `--set NAME --write` (done: all 40 dressed, kit checks pass, play sections identical to HEAD; kit's light cap 256 -> 640 for big sectors; remaster reads read_plain; --in-place guard for custom/) (in place, marker line, refuses a dressed file) - dress all four sets;
      builders' --write dress too (so a rebuild keeps it)
- [x] A6. Software renderer check; a screenshot per set (orig 5, new 5, huge 4, orig 1 software); docs (LEVEL-EDITOR-GUIDE, CLAUDE.md). Rick to judge: tall rooms' skirting reads as a heavy plinth

## B. The maker (a fifth set)
- [x] B1. Inventory (scratchpad feature-inventory.md - copy into .claude/ if kept): every gameplay feature, its file syntax, kit support, what NEW/HUGE use
- [x] B2. Design (Rick: go, 2026-10-29; + 'ample lighting, liquids, per-surface effects, divided textures'): mission graph (gates + what opens them, placed before them) -> rooms -> set pieces
      (code chain, security wing, turret nest, hazard crossing, vault, blackout, server room...)
- [x] B3. maker.py + set pieces (written: infil/level1-10, kit checks + playthrough pass; screenshots of 4 sectors); checks: reach with each gate, every code findable before its door
- [x] B4. Game: sectorSet 4 (agent: NUM_SETS 4, SetDir$/SetName$, console, saves, NpLevelList$, MAX_RECORDS bug 64 -> 80, docs; compiles) (menus, SetName$, saves, music/intro keys, achievements?)
- [ ] B5. Ten sectors, played by the bot; demos (Mac) - ask Rick

## B2 design (proposed to Rick 2026-10-29, waiting on his go)
maker.py: plan -> layout -> set pieces -> verify -> lvldress (roles from the plan, not guessed).
- PLAN: start..exit as beats; each beat a GATE and its ANSWER placed before it (lock and key):
  keycard door; keypad door/safe (code in a note in a desk/bookshelf/safe, or a computer hack; brokenpc + repair kit);
  sealed door (data station); stronghold door (kicks - loud: wakes 10 cells); turret gauntlet (a ; panel on a flank
  route within 12); alarm zone (guards within 40 steps of switches, an alarm PC, cameras + secmon to scout);
  blackout (flashlight + batteries before it); lockdown arena; hazard crossing (jump pad + launch control + note,
  lifts, jetpack + fuel, hazmat before p/s/a).
- LAYOUT: rooms on a grid (64-96 cells), critical path + side branches (optional: vault, stash, secrets).
- SET PIECES: office, security post, server room, vault, lab, hangar, reactor... each places geometry + things +
  notes + triggers and states its needs.
- VERIFY: progression simulation (keys, codes known, stations, panels, kits, light) - every gate answerable in order;
  the kit's checks; the inventory's traps (no [doors] on !, $ locks doors within 7, lockdowns lock doors within 5,
  hoard needs thieves, gallery no chests, | needs real wall, never rebuild commands in triggers).
- DIFFICULTY: extra machines at HARD/NIGHTMARE by [difficulty].
- TEN: 1 notes+keypads, 2 security/alarms, 3 turrets+panels, 4 hazards+jump pads, 5 blackout+flashlight+eyebots,
  6 vault (stronghold, safe, mimic), 7 network, 8 jetpack+gravity, 9 all of it, 10 finale.
- GAME: sectorSet 4 (menus, SetName$, saves 100 a set, music/intro keys, achievement?), demos on the Mac.

## Open (for Rick)
- Play INFILTRATION (rebuild neon-caster.run first) - tune SPECS/KINDS; then demos infil1-10 on the Mac
- NEXUS intros intro-infil1..10 (DATA lines + voice), music infilN.ogg (else borrows the ten's)
- An achievement for the set? (agent's list: AchDef NC_INFIL, NUM_ACH 51, LEVELS.BM unlock, badges 64/256, make_tables.py)
- Looks pass: tall rooms' skirting (heavy plinth?), huge sectors' frame rate with 900 pieced faces
