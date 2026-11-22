# NEON-CASTER overnight: 10 NEW SECTORS + OLD SECTORS NEW — branch `more-sectors`

## ✅ LOOP DONE — every item checked
_Started 2026-10-15 ~00:15 ET while Rick sleeps. Each item is built, checked by the level kit, played in a silent capped Xvfb copy (LP_NUM_THREADS=2 nice -n 19, PULSE_SINK=claude_mute, Wayland unset), and committed on the branch (pushed, not released). The repo's neon-caster.run and saves/ are never touched._

## 🔨 NOW — doing right now
_(nothing - all done)_

## Plan
Three sets of ten, each numbered 1-10 (music, NEXUS intros, the tally at 10 all by number): the originals (`levels/levelN.txt`), **NEW SECTORS** (`levels/new/levelN.txt`, built by `levels/newsectors.py`) and **OLD SECTORS NEW** (`levels/remix/levelN.txt`, built by `levels/remaster.py` from the originals - which stay as they are). GAME menu: NEW GAME, SELECT SECTOR, NEW SECTORS, OLD SECTORS NEW, YOUR SECTORS... Saves remember the set.

## The list

- [x] 1. Sector sets — sectorSet + SetDir$/SetName$/SetSectorName$, levels/new/ and levels/remix/, GAME menu NEW SECTORS / OLD SECTORS NEW (shown once files exist), progression within a set, saves keep the set (set*100+n; old saves fine), sectorset console command; tested save/load across sets, menu, finish → next in set (07459bd)
- [x] 2. newsectors.py — Sector class (blk, post, column, thin_wall, alcove, pool, loot), campaign dressing kept off blocks/lifts/liquids, block-aware reach, limits checked; the ten planned in its header
- [x] 3. NEW 1 ARRIVAL DOCK — posts, alcoves, lit columns, water channel, customs lockdown (scatter prize), cargo shelves + loot, glass gate; kit OK, both renderers, played to SECTOR CLEAR
- [x] 4. NEW 2 THE AQUEDUCT — laser duct, 3-high hall with water channel + lit piers, gunner ledges (stairs/elevator), pump room survive lockdown (repeater), reservoir with stairs out + 4 bobbing lifts to the blue card, outflow under the storm; kit OK, keys and doors verified in play
- [x] 5. NEW 3 NEON MARKET — night sky square, 10 stall kiosks (thin-wall blocks under awnings, lit signs), shopfront alcoves (vending/screens), puddles, stage with holograms + lit posts, thieves hoard, arcade gallery (overcharge), noodle bar lockdown; kit OK, both renderers, doors verified
- [x] 6. NEW 4 ACID WORKS — deep acid channel (steps both ends, catwalks, lift crossing to railgun island), 4 shallow vats (acid eats armour: verified), filter room electric trap + data station seal, pump control lockdown, control room exit; kit OK, played through
- [x] 7. NEW 5 THE FORGE — two lava rivers (steps out, bridge, bobbing lift), generator alcoves (fire glow), girder columns, casting room fire trap, pattern store heavy lockdown, furnace exit, blackout; kit OK, both renderers, played through
- [x] 8. NEW 6 THE CHAPEL — 4-high nave between lit pillar rows, aisles with hologram shrines, poison font + posts, apse spawner nest, crypt survive lockdown + cryo alcoves, sacristy exit; kit OK, played through
- [x] 9. NEW 7 COLD STORAGE — ice hall + bottomless freezer shaft (death pit), cryo vaults behind glass (lockdown, sealed, red door), specimen tank alcoves, thin-wall office cubicles, loading dock exit; kit OK, played through
- [x] 10. NEW 8 THE SKYWAY — storm-sky rooftops at 5 heights, bridges/stairs, roof-to-roof lift, gantry laser cutter, street death pit, sentries, tower sheds (blue card, exit); kit OK, played through
- [x] 11. NEW 9 THE ARCHIVE — rack rows between thin partitions + rack alcoves, laser grids, sorter cutter, shelving stacks, stalker closets, data station, code terminal, index/records/core; kit OK, played through
- [x] 12. NEW 10 NEXUS HEART — ring hall, two lockdown antechambers (ambush/survive, repeater/railgun), lava-moat heart with red pillar ring, 4 bridges, corner portals, overseer; played to YOU ESCAPED!; event banners now stack (game fix)
- [x] 13. remaster.py — loads originals into Sector, safe passes (themed alcoves, lit columns, exit posts, deco nudges, murky→water/slime, molten→lava only off-route, loot), per-sector hook; all ten pass the kit
- [x] 14. OLD NEW 1 NEON STATION — hub fountain, lit-strip pillars (cyan), neon signs + violet posts on the ring, themed alcoves, exit posts; kit OK, keys+exit run REACHED
- [x] 15. OLD NEW 2 REACTOR CORE — coolant in the reactor bowl, amber light-strip pillars in the south hall, red strobes, themed alcoves, lit columns; kit OK, keys+exit REACHED
- [x] 16. OLD NEW 3 UNDERCITY — slime in the nest, cistern pillars glowing green round a pool, lit graffiti, alcoves; kit OK, keys+exit REACHED
- [x] 17. OLD NEW 4 CRYO LAB — chilled water ring round the atrium core, cyan lit columns, tank/pod alcoves; kit OK, keys+exit REACHED
- [x] 18. OLD NEW 5 FOUNDRY — molten → lava off the route, amber firelight pillars (lights kept under 96), generator/tank alcoves; kit OK, keys+exit REACHED
- [x] 19. OLD NEW 6 HYDROPONICS — murky → water, grow-light posts in all 9 bays, poison spill in the dome, alcoves; kit OK, keys+exit REACHED
- [x] 20. OLD NEW 7 DATA VAULT — rack-row ends in light strips, vault faces lit violet, rack/screen alcoves; kit OK, keys+exit REACHED
- [x] 21. OLD NEW 8 MAGLEV DEPOT — neon adverts on both platforms, rain puddles, vending/screen alcoves; kit OK, keys+exit REACHED
- [x] 22. OLD NEW 9 ORBITAL SPIRE — eight cyan/pink lit columns round the ring, pod/console alcoves; kit OK, keys+exit REACHED
- [x] 23. OLD NEW 10 THE CORE — red lit columns round the overseer, lava in off-route corners (safe_pool), alcoves; kit OK, keys+exit REACHED
- [x] 24. Docs — README (three sets, blocks/liquids), TUTORIAL (NEW SECTORS table, remaster, folders, sectorset), guide (editing a set), CLAUDE.md (sets, scripts, testing); CI already ships all of neon-caster/
- [x] 25. Final pass — all 30 sectors load clean in OpenGL and software (no errors.log), kit --check passes for levels.py/newsectors.py/remaster.py, originals + custom byte-identical to main, user saves/custom12 untouched; morning report https://claude.ai/artifact/8uPqG7s35xntVUKskajBYv
