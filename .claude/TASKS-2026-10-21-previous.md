# NEON-CASTER — textured Tab map, jetpack controls and cheats, taller stacks (2026-10-21)

## ✅ ALL DONE — tonight's second round
_Rick: "for the tab map, is it possible to texture it? like how duke3d does that?" · "a cheat for unlimited jetpack fuel, and ability to give jet pack fuel" · "jetpack up/down should be bindable controls ... default e and c ... also up and down with just fly mouselook - look up push forward == go up ... same for down" · "why are barrels max stacked 3 high?". Builds and tests in scratch only; his neon-caster.run only when his game isn't running._

## 🔨 NOW — doing right now
- (nothing: the list is done)

## Tonight, round 2 (Rick: "more nexus taunts", "agro sounds from humanoid/cyber enemies", "barking dogs", the eyebot)
- [x] 42. CYBERSPACE: 4 ICE kinds, firewalls, TRACE - 8ef27ad; the 8 demos that jack in re-recorded on the Mac (86d6576), 49/49 in step
- [x] 43. Cameras follow you and break; every model lighter (19,163 -> 10,712 triangles); hack log font - 8ef27ad
- [x] 35. Cameras, alarm toggle, 3D props, STOCKPILE slowdown, wetness, THE LAUNCH BAY - committed de8809e (push after the Mac's 49/49)
- [x] 36. NEXUS: 32 more taunts (44) - committed da162f1
- [x] 37. Dog animation (head on, mirrored side on, pounce) - committed da162f1
- [x] 38. Aggro voices: soldier / heavy / cyber line sets when they spot you; robodog barks (soundmon) on alert and hunting
- [x] 39. EYEBOT: a flying cybernetic eye - laser at range, rushes and self-destructs (rocket blast) up close; eye colour by state (plain idle, yellow hunting, red rushing)
- [x] 40. The cramped text was the hack screen's log (1.25 scale) - fixed in 8ef27ad
- [x] 41. Demos on the Mac (49/49), pushed (86d6576), Rick's build rebuilt, field kit republished

## Queue
### Rick, 2026-10-21 afternoon: "please make the dog attack look at us ... alarms, computers that disable/enable them, switches the guards and mobs can press ... a guard character ... jetpack fuel needs to be a pickup ... a setting to adjust the opacity of the liquids"

### Rick, later the same day: "these things will let me make more immersive levels" (/task-loop all this for today)
Each one: the game, the level file, the editor (pane / picker), the level kit, LEVEL-EDITOR-GUIDE.md; demos replayed; commit as each lands.

## Done
- [x] 34. JUMP PADS — " jumppad (DIR/ANGLE/POWER, pane < > - +), shot on a ballistic arc (knock kept, sector gravity, no walking - look and shoot; real fall damage unless water/jetpack); monsters launched too (MonPadStep, monFly); " padpc launch control (Space: - + buttons, arrows, typing; SET/LEAVE; demo result j), readout when pointed at; console jumppad X Y D A P; saved; guide formula. Tested: 9 cells at 45/30, ceiling-limited arc, 30% gravity 13 cells, padpc set 90/46/30, a gunner launched 9 cells
- [x] 33. JUMP — BIND_JUMP (Q), demo bit J (DB_JUMP 32768, DB_GUN 65536 - old demos' letters unchanged); JUMP_V 0.1 = half a wall. Tested: peak 0.45, down in 16 frames
- [x] 32. SECTOR GRAVITY — gravity = N (10-300), sector pane GRAVITY - +, console gravity [N] (a trigger's zero-g room), saved; exactly FALL_G at 100 (old demos). Tested: 50% jump 0.95
- [x] 31. JETPACK THRUST — a booster: thrust (JET_THRUST, up to JET_RISE) only while UP held or looking up + walking, JET_BURN a firing frame; let go, a rocket jump's fall (no hard landing). Tested: 30 frames up 1.8, 7.5 fuel; down in ~40
- [x] 30. REPLAY LENGTHS — DemoFrames& reads the demo's last line (e FRAMES) from its end: m:ss before each title. Tested: HUGE1 7:21, HUGE5 5:00
- [x] 28. MENUS SCROLL — a menu over MENU_FIT (14) rows shows a window that follows the selection (MenuScrollFix), ^ MORE / v MORE, the wheel moves it. Tested: CONTROLS scrolled to ROCKET CAM and back
- [x] 27. LIQUID OPACITY PER CELL — the setting and liquid_opacity = gone; [liquid opacity] rows (. 1-9 x), liqOp per cell, OpenGL a pass per step; editor: a liquid cell's pane LIQUID - + (selected cells), undo/move/resize/new carry it; console liquid ... DEPTH SOLID%; kit reads/writes. Tested: 3x3 solid in a see-through pool
- [x] 25. TEST + DEMOS + COMMIT — scratch tests of each (alarm chain, console, fuel 20+15, opacity 0/100, drain lava+water, rocket cam press/release, the dog's bite, editor panes); 49/49 on the Mac; 4fe4987 + e9c2623 pushed; Rick's build rebuilt; field kit 21 updated
- [x] 26. DRAIN — drain X Y [SPEED]: the joined pool (any kind) goes down till dry, saved mid-drain; lava's glow lights out with it; console help, guide (a wall-switch trigger). Tested: lava pool dry in 1.5 s, glows 4 -> 0; EXPO water 80 cells
- [x] 24. LIQUID OPACITY — setting LIQUID OPACITY (EFFECTS, 0-100) and a level's liquid_opacity = (sector pane LIQUIDS -/+): OpenGL's see-through scaled by the higher. Tested: 100 = you can't see the bottom
- [x] 23. JET FUEL AMOUNTS — [fuel] x,y,amount (pane FUEL -/+ on ` and , cells): a jetpack gives its amount (adds, if you have one), a can its own. Tested: 20 + 15 = 35
- [x] 22. ALARMS + GUARDS — GAME/ALARMS: " alarm (switch, on/off at first, 2 hits break it), " alarmpc (Space: off/on - all, or its ALARM X Y), AlarmRaise (siren, red edges, wakes everything within 24), guards (monster 19: plasma pistol, fast, run for the nearest switch by a flood-filled way, alarmDist), gunners/heavies/stalkers/snipers/troopers slap one they pass (GRnd only by a switch), hacked computer turns one off; console alarm on|off|raise|stop; trigger WHEN alarm [X Y] (pane ALARM); bodies renamed deadscientist/deadguard/deadcyborg; THE COMPOUND has 2 switches, 3 guards, a console. Tested: a guard raised it in ~70 frames, the console silenced it
- [x] 21. DOG ATTACK FACES YOU — robodog-attack.png: a front view of the same dog (pixelmon --turnaround from its picture), the bite frame (MonFrame's NAME-attack.png). Seen in game: head-on, ears up, as it bites
- [x] 20. SHOWCASE + RELEASE CHECKS — THE COMPOUND (custom20, sector 30, compound.py: kit ALL GOOD; every set's kit check unchanged); editor smoke-tested (map view things, 3D hover, SECMON pane); 49/49 demos in step on the Mac; e8244e0 pushed; Rick's neon-caster.run rebuilt from it; field kit 21 published https://claude.ai/artifact/9jevX3kmPiSdhJeryNcyPF
- [x] 19. SECURITY CAMERAS — " camera [name] (up its wall, back to it) + " secmon: Space → feed (REC, clock, name, pans), Space next, step leaves (inputs: demo-safe). Tested LOBBY → CAM2 → you
- [x] 18. ROBOT GUARD DOGS — MT_ROBODOG 18 (" robodog): fast biter, DogBark wakes machines within DOG_BARK 10 on sight; sprites + 7 sounds (soundmon rtx); Bestiary 17. Tested: it came through the door and bit
- [x] 17. ROCKET CAMERA — setting ROCKET CAMERA (rocket_cam, GAMEPLAY): view-only (ViewAway/ViewBack round chapters 14-17), rides the rocket, backs off at the burst VIEW_HOLD frames. Tested software + GL
- [x] 16. INVULNERABILITY — " invuln (IT_INVULN): INV_FRAMES 300, HurtPlayer + poison gate (not pits), golden edge glow + countdown, blink last second; give/take invuln. Tested: dog bit 0 while on, 16 after
- [x] 15. SMEARS — [smears] x,y,face,blood1-3/oil1-2: decals kept (decalBase, never overwritten), GL per-kind pass, software sprites; editor PAINT with smear-*.png (end of wall/floor/ceiling tabs), other paint wipes. Tested both renderers
- [x] 14. PROPS — " table (cover, 10 hits), brokenmonitor, scientist/guard/cyborg bodies (DecoFlat: walk over, no shots), all painted (pixelmon rtx) + hd
- [x] 13. BROKEN COMPUTERS + REPAIR KIT — " brokenpc [x y] + repairkit (IT_REPAIR, up to 3, give/take repairkit); fixed → DK_PC: the word hack (title COMPUTER) opens its target (door any lock / safe) + 'hack x y' triggers (console help, editor HACK); lockout alarm wakes near. Tested repair + hack screen + logout
- [x] 12. SEARCHABLE DESKS AND BOOKSHELVES — Space once: its note, and a find by its [loot] with a cell-hash roll (not GRnd: old demos stay); bookshelf = repairkit/medkit/ammo/shells. Tested both
- [x] 11. SAFES — " safe [code]: keypad (title SAFE) or a computer's target opens it; safe-open picture; loot (safe = armor/overcharge/rounds/amp) + note. Tested: random code 1651 read from the desk's note → open, 3 drops
- [x] 10. BARRED WINDOWS — - : glass with BARS_HP (never breaks, shots ping), S_BARS sprite; minimap grey; kit GLASS. Tested: walk blocked at 9.06, drawn both renderers
- [x] 9. NOTES — ' (DK_NOTE) and in desks/bookshelves/safes: [notes] x,y,picture,words (| lines, {code x y}); NoteRun shows paper + picture; editor pane NOTE WORDS/PICTURE/NONE. Tested both renderers
- [x] 8. KEYPAD DOORS — [doors] code (digits / ? made up each start): Space → keypad (own loop, mouse or digits, demo result 'c'); {code x y} in notes; door pane KEYPAD CODE TYPE/RANDOM/NONE. Tested: xdotool 1234 → ACCESS GRANTED
- [x] 7. STRONGHOLD DOORS — [doors] kicks: Space says BARRED, each kick (F) dents it (amp: 2), half: cracked texture, 0: down for good (doorBroke, crash, wakes near); door pane KICKS -/+. Tested: 4 kicks → broke
- [x] 6. TEST + DEMOS + COMMIT — 49/49 demos in step on the Mac; e7cd4ac + 005cb3a (jetpack/fuel weren't loading from a map - fixed) pushed; Rick's neon-caster.run rebuilt from 005cb3a (a clean worktree, not the WIP)
- [x] 4. MOUSELOOK FLIGHT — jetClimb also when lookAim, walking forward, pitch > JET_LOOK (0.26 rad); flight climbs/descends by DSin(pitch). Tested: look up 30 + W lit and climbed to 1.8, level hovered, look down descended and landed (off)
- [x] 3. BINDABLE FLY UP / DOWN — BIND_UP/BIND_DOWN (key_flyup E, key_flydown C) in CONTROLS; demo input reads the binds into DB_UP/DB_DOWN; editor fly down; messages via FlyKeys$. Tested: key_flyup=114 in settings.ini -> binds R, god says 'R up, C down'
- [x] 5. TALLER STACKS — BARREL_STACK 8; StackFits(k,x,y,want) trims a stack to what fits between the file's floor and ceiling (load, editor STACK +); kit range from lvlkit.BARREL_STACK; guide/CLAUDE.md/README/comments. Tested: stack 8 under 3 walls -> 6 liquid, under 2 -> 4 plain (decos 43 -> 50)
- [x] 2. JETPACK CHEAT + GIVE — infinitefuel/infjet [on|off] (jetInf: no burn; a cheat; demo verb + header line 'jetinf 1', restored after); give jetpack | give fuel [N] (a jetpack too if none); take jetpack | fuel [N]; help, overview, ConNames$
- [x] 1. TEXTURED TAB MAP — FullMapFloors: each known floor cell's own picture from above into a cached image (redrawn per cell as its state changes), dim/bright; walls as lines along the floors they face (MapFloorShown); pools/pits/lifts/doors over; sectors >160 keep colours
- [x] 29. TEST + DEMOS + COMMIT — 49/49 demos in step on the Mac (nc046), kits all clean; pushed 13a570a; Rick's neon-caster.run rebuilt from a clean worktree; field kit republished
