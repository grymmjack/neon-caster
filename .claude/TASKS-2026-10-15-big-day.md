# NEON-CASTER big day — branch `big-day` (until 6pm ET, 2026-10-15)

## ✅ LOOP DONE — every item finished (17:25)
_Rick: "every time I sit down to play I find something off, or buggy" + "connect the Steam achievements" + "come up with things yourself". Every item is tested in a silent capped Xvfb copy and committed on `big-day` (pushed). The repo's neon-caster.run and saves/ are never touched._

## 🔨 NOW — doing right now



## The list

- [x] 23. Final regression with the newest build (1224b9f): 30/30 sectors to the exit, 12/12 showcases clean; report v7 published; big-day pushed and clean (34 commits)

- [x] 21. HUD/maps/particles (12) + events/triggers (6) reviewers: hoard sealing wrong doors (sector 1 from the start; sector 3 thief locked behind its own door!), rewards inside pillars, survive lockdown lifting in its corridor, trigger wait across levels, sky scorch, marks left where walls vanish / on lifts, double-floor sparks, gun after ART change, event lines, HUD minus, GL sky horizon (1224b9f). FOUND, NOT FIXED: the 3D world is a mirror image of the map/editor/level files (facing east, north is on your right) - a handedness flip, too big for today; put to Rick
- [x] 22. Visual tour (OpenGL, 30 frames NEW + 10 remastered): nothing new broken; under open skies posts/blocks/awnings rise to the sky height (looks like towers) - pre-existing, design trade-off, left


- [x] 20. Wrap-up: report v6 published (https://claude.ai/artifact/MHXaLEaP2LAZz73jqjkwwC), branch big-day pushed and clean (33 commits, not merged/released - Rick's call), memory note of his open decisions (death loadout, 1-wall fall, LOOK aim miss, Windows untested)

- [x] 19. Software glass clipped by nearer ledges/lintels (as sprites) - commit after this list update; Conservatory glass still draws

- [x] 18. Software diagonals in height sectors drawn as diagonals (1f2725d); tested sector 3 tunnel, 5 sectors to exit, EXPO soak

- [x] 17. Software renderer doors in height sectors: slabs found in their cell with DoorRay, sliding/parting, under the lintel (beb91ac); screenshot before/after; 6 sectors to exit, 2 soaked

- [x] 13. Field report refreshed (v4: all sections, regression note, final numbers, 30 commits) https://claude.ai/artifact/MHXaLEaP2LAZz73jqjkwwC ; branch big-day clean and pushed

- [x] 16. Final regression pass, final build (342a8c8): 30/30 numbered sectors reach the exit, 12/12 showcases soaked with no errors

- [x] 15. Regression review of today's diff: found saves shifted in every sector with pads (numLightsBase before the pads' lights - my bug from this afternoon), ShotPasses never passing (NOT of -1 AND 1), bolt marks at 0.49, Z losing a zone's ceiling, pool reach 0.6, elevator step-down, glow stacking, puzzle command state, borrowed core slot - all fixed (cc70a9a); save/load/save files match; miss margin made generous after a test (crawler down a step)

- [x] 14. Bug hunt part 5: sound (8: barks from where the guard is, limiter keeps loudest, NEXUS lines don't overlap, switch grunt, hums off in console/editor, footsteps, midnight, leak) (69f8c9d) + hum panning (e510b1e); terminals/network (11: keycard doors opened by a solve, puzzle reshuffled on return, name table, comments anywhere, broken compiler soft-lock, hidden console, jack-out position, exit/use from the network, dead clock, cores where walkable, ICE count) (5a49c2c); bump light height (f9c26c1); toast bottom-right (a1d02d2). 10 originals + 2 more played to exit; soak 31/31 clean

- [x] 12. Bug hunt part 4: combat (11) + rendering (11) reviewers. Fixed: bolts aimed at map corner (playerX not shared!), network ghosts, frozen spawned monsters on load, railgun msg, thief across ledges / mid-swap / pit drops, wheel notches, 128 monsters (fd89fd1); GL doors at their floor (9f787be); shafts/shadows/glows/shot marks/lamp relight/lift walls (10500fd); vertical aim with LOOK (3981892); lift positions saved (be378fc). Not done: software renderer doors/diagonals in height levels (big rewrite; GL is default), bump-light height (subtle)

- [x] 10. Docs: README, TUTORIAL, editor guide, steam/README, CLAUDE.md all updated as we went; field report published (https://claude.ai/artifact/MHXaLEaP2LAZz73jqjkwwC); all pushed

- [x] 7. Soak: software renderer, all 42 (3 sets x 10 + 12 showcases) clean; OpenGL, 11 across the sets + EXPO with the newest build, no errors (GL under Xvfb is ~4 fps, so some hit the time limit after their first status - not a hang)
- [x] 11. Bug hunt part 3: physics (10) + menus/saves (11) reviewers: fixed load height, terminals/stations in saves, load mismatch, menu time in saves, dead saves, old-save slots, stale trigger queue, Esc after intro, long menus, slider/choice name clicks, F9 in editor, wide mouse; monster shove rules, claws/kicks across ledges, kick shove, lift vs ceiling, fast-lift snap, exact glass, thief round glass (5ac1796); ledge slide-off (34f0bf1); elevators both ways (46e4b5e); no blocks on lifts (96f6059); tally badges. Not done (judged not worth the risk today): hitscan through step rims; 1-wall drop costs ~4 HP (as designed)

- [x] 8. Bug hunt part 2: review 1 (11, cheat lock, saves, headshots, close button, records names) + review 2 editor (13: F2 bounce, unsaved re-entry, wheel over pane, event pane, undo loop var, lift modes, nudge pools/lights, typing stuck, Z zones, Del ceiling, Ctrl+PAINT selection, honest notes) + flood glow + lqUsed after load + monsters out of raised blocks: all fixed (fad0850), tested flood/block/save-load in GL, STATS screen; compiles on macOS too
- [x] 1. Bug hunt part 1: 3 reviewers found ~27 bugs; fixed 24 (blocks: light, tints, melee/grab through, block cmd rebuild, place inside, loot, marks, cores, GL cutoff; sets: sectorset/ReadSectorNames clobbering the edited level → wrong file saved, editor+load, SELECT SECTOR names, drop moving bodies, core overflow; events: saves keep triggers/floods/lockdowns/cheats, ambush stuck when full, survive clock reset, LockRoom ownership, nest spawn on player, dead rooms, trap hum reuse, sound cmd, wait-trigger cheat, editor bubbling) (724364a + next). Left: block on a lift (GL gap), liquid lights static, custom-in-set save label (minor)
- [x] 4. 45 achievements + 12 stats hooked through the game (story, combat, skill, events, hacking, liquids, editor, hidden); cheat lock (console/editor, not triggers; kept in saves); tested unlocks (first kill, headshot, arsenal, search, teleport)
- [x] 5. Toast (gold trophy + chime) + GAME > ACHIEVEMENTS card grid (scroll, progress bars, hidden) + console achievements/achieve/resetachievements; screenshots checked
- [x] 6. Records: saves/records.txt (best time, kills, items, clears per sector, all sets + yours), BEST / NEW RECORD! on the tally, RECORDS tab (Tab, Left/Right sets); tested
- [x] 2. Thief escape route + network cores skip block cells
- [x] 3. Steam vendored into lib/steam (QB64_GJ_LIB b8187cb), mock backend → saves/achievements.txt, STEAM_update per frame, store at sector end + quit, NEON_APP_ID=0 until a real App ID; tested (unlock written to the file)
- [x] 9. Fun of my own: 45 badges (pixelmon on rtx, colour + grey, game + Steam icons, 0dfc347); STATS tab with ranks + lifetime totals; SECTOR TIMER on the HUD (green inside your best, red past it) + the sector clock now stops while paused (it counted menu/console/editor time!) (65381d7); Steam-style ACHIEVEMENT PROGRESS notes every quarter (89a1443). All screenshot-tested.
