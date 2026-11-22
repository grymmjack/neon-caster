# NEON-CASTER — liquid barrels, treasure chests, mimics, stacked barrels (2026-10-20 night)

## ✅ LOOP DONE — barrels, chests, mimics, stacks, jetpack (22:30 ET)
_Rick: "jet pack and jet fuel ... limited fuel and lets character fly like we have already" · "barrels for different liquids ... explode, fuse, ignite, and cause toxicity damage of the same type as liquid inside. Several 3d models for each type with destroyed models and sprites too" · "treasure chest caches that open on use and mimics ... which attack but look almost identical" · "allow barrels to be stacked on top of each other". Rick is playing his own build: builds and tests only in scratch copies; never his neon-caster.run or saves._

## 🔨 NOW — doing right now

## Queue

## Done
- [x] 10. REGRESSION — all 49 shipped demos replayed on the Mac on the new code (7e0a90c): every one in step (existing sectors play exactly as before); kits clean; committed + pushed (dc05e1e); field kit
- [x] 9. SHOWCASE + TEST — THE STOCKPILE (sector 29, custom19, stockpile.py, kit ALL GOOD) instead of changing the EXPO (its demo stays); tests: each liquid barrel bursting alone, chained stacks, chest open + empty, mimic wake/bite, jetpack climb/hover/burn/fall, editor round-trip of [barrels], bot 3000 frames in the stockpile - errors.log clean
- [x] 8. EDITOR + KIT + DOCS — picker tabs/glyph lists/names/colours for ` , ] : [; kit ITEMS/MONS/DECO/[barrels]/loot names; guide (characters block from EDIT_GLYPHS, items, mimic, barrels+chests paragraph, [barrels]), CLAUDE.md, README; editor-written file keeps [barrels], kit checks it
- [x] 7b. JETPACK + JET FUEL — IT_JETPACK 22 '`', IT_JETFUEL 23 ','; E lights it (fly-mode flight), fuel 0.12/frame aloft +0.18 climbing (~8 s), out → fall, landed → off; HUD JET %, saves, death, give jetpack, bot wants, art/models/sounds; tested: climb, hover, burn to 0, fall
- [x] 7. STACKED BARRELS — [barrels] stack 1-3 (o and :), decoZ drawn in both renderers (sprites, models), StacksSettle drops them, DecoCellAfter keeps the cell blocked, BoltDeco/shots by height on stacks only (demos unchanged), editor STACK +/-, saved heights
- [x] 6. MIMICS — MT_MIMIC 17 ']' (MON_TYPES 17): asleep drawn as the chest (S_MIMICNAP / mimic-asleep model, pink lock the only tell), wakes on Space, within 1 cell, or a shot (WAKE_HIT), bites 14+; sounds by soundmon; Bestiary 16 + steam tables; ambush kinds capped at colossus; tested: 'It's a MIMIC!', bit 100→72
- [x] 5. CHESTS — Space on '[' opens it (ChestOpen: sound, each loot slot its own roll, tossed to you; open picture/model), 'Empty' after; saved open; shots don't open it (HP 99)
- [x] 4. 3D MODELS — models.py: 5 barrels + 5 wrecks (lathe), chest, chest-open, mimic-asleep, jetpack, jetfuel (extrude); wreckMdl drawn for broken barrels / open chests; MAX_MODELS 64; seen in OpenGL with stacks and wrecks in their pools
- [x] 3. LIQUID BARRELS — GAME/BARRELS: shot → leaks (spray of its liquid, hiss) 40 frames → bursts: blast (water a pop), a one-eighth pool (LiquidSpill), poison gas+dose, lava ignites (monsters, decos, you), acid on armour + wall stains, slime burns, water douses; burning cooks off; stacks settle; tested each alone: water 0, poison 14+ticks, acid -28 armour (bd6456b)
- [x] 2. DECORATIONS — DecoChars$/DecoOfChar/DecoCharOf$ replace the literals; kinds 22-26 (liquid barrels, one char ':' + [barrels] x,y,liquid,stack) and 27 chest '['; names, files, scale, HP, explosive, loot (chest), sounds, painted wrecks/open chest load, decoZ stacks drawn; editor LIQUID/STACK on a barrel's pane, undo, nudge, shrink; kit DECO/[barrels]; seen in both renderers
- [x] 1. ART — pixelmon (rtx): 5 upright liquid barrels, the chest shut and open, the mimic awake and dead, the jetpack and fuel can; wrecks cut from each barrel's own painting (jagged, scorched, its liquid on the tear); the sleeping mimic is the chest with its lock pink; hd 256/128 + pixel 64/32 into neon-caster/ and hd/
