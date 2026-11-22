# NEON-CASTER — Rick at work (2026-10-20): finish everything asked for

## ✅ LOOP DONE — every item finished (17:00 ET)
_Rick: "complete the remaining tasks ... everything i've asked for and described as broken ... turrets are good, can do demo recordings ... another batch of 10 levels, huge ones, with lots of good shit". Tests in the scratch copy on Xvfb :99, muted; the repo's neon-caster.run is only replaced when his game isn't running; saves/ never touched; custom12/13/15/16/17 and TASKS files never committed._

## 🔨 NOW — doing right now


## The list

- [x] 8. Demos: 49 shipped and replayed on Linux in step all the way - the original ten (sector1-10), NEW (new1-10), OLD NEW (remix1-10), the showcases + EXPO + MONOLITH (sector11-21, 24, 28), HUGE 1, 3, 5, 8, 9, 10; recorded on the Mac in OpenGL, to the exit or not (Rick: fine). HUGE 2, 4, 6, 7 left to Rick ("i can make them myself") - their unchecked Mac recordings are in the scratchpad's huge-unchecked/ and on the Mac in ~/qa/nc040/neon-caster/saves/demos. Commits 49764ea, d53abc6
- [x] 7. Regression: every sector of the four sets and the showcases played by the bot on the Mac (demo recordings) with no errors.log at all; Linux replays and soak runs: errors.log empty; 18 showcase/custom soaks clean; HUGE playthroughs 1, 2, 3, 6 to the exit; docs (README, TUTORIAL, guide, CLAUDE.md) in step; committed 49764ea (+ tutorial fix). (Exits not required - Rick)
- [x] 6. HUGE SECTORS: hugesectors.py, ten sectors 112-192 cells (districts, keycard stretches, heights, shapes, kinds, dressers), GAME > HUGE SECTORS, limits raised; kit + dry-reach + sealed-arena checks; bot finished 1, 2, 3, 6, played 4, 5, 7 30 min each with no errors (8-10 play on the Mac as their demos record); generator fixes for lava cutting a way (2) and an arena's buildings (4); commits 84fb7b7, d067043, e84bfac
- [x] 5. Verified: droids flee when shot (21 cells, out of the room); acid stains were hidden inside walls in OpenGL - fixed (marks on the wall's face); poison builds/ticks/cured; committed
- [x] 4. Own ammo per gun: repeater ROUNDS ({, 40/box, 200), railgun SLUGS (}, 5, 25, 1 a shot), cells the blaster's; pictures (rtx) + models; LootAmmo turns dropped cells into your energy guns' ammo (all sectors fed); kit split_ammo in every set + kit now writes heights past z; saves (old ones get some); HUD/msgs/console/editor/bot - tested pickups, firing, give/take, save/load, old saves, bot; committed e12ca52
- [x] 3. Console scripting: alias/unalias ($1-$9, $*, waits run next in the queue, no command names, self-loop stops at 8), saves/autoexec.cfg at start-up, quoted ; kept, exec looks in saves - tested; tutorial + guide; committed 82177e4
- [x] 2. Turret states: EJECT frames (col 10) + STARTS out-when-wakes/held/out (col 11), editor rows, kit checks, summon ejectslow/fast/held/hidden, `turret WHO WHAT` (eject/retract/off/on/weapon/track/ejectspeed; list) - tested held→eject→fire→retract→off/on, a timed trigger ejecting, file round-trip; guide; committed
- [x] 1. Rocket jumps: half gravity till you land, no landing damage — tested in OpenGL (NEW 1: up 0.85, ceiling-capped, down in ~30 frames, only the blast's 15 hurt); committed
