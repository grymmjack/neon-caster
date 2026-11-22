# NEON-CASTER level editor overhaul — branch `level-editor-gui`

## ✅ LOOP DONE — every item checked (11:42 ET)
_Started 09:10 ET 2026-10-14 while Rick is at work. Each item is built, tested in a silent Xvfb copy, and committed on the branch (pushed, not released)._

## 🔨 NOW — doing right now
_(nothing - all done; the pit-wall texture glitch from last night is still waiting on Rick: which sector, wall, renderer and MODE)_

## Engine limit, said up front
The world is a 48×48 grid: walls, floors and collision are per cell. So **heights move in 1/8 steps (8 px on a 64-px texture)** and **walls push/pull a whole cell**; a half-cell block can't pop out without rebuilding the renderer and collision. "Divide" therefore splits a FACE for texturing (two textures, left/right or top/bottom), not its geometry.

## The list

- [x] 1. Editor foundation — noclip + flight (Space up / C down) in the editor, no damage, edits no longer shove you; shared editor state block (commit on branch)
- [x] 2. 3D cursor — free pointer, right button to look; EditPick ray-walks the map in 3D (pitch included) and outlines + names the face under it (wall/floor/ceiling/step/lintel), both renderers; gun hidden in the editor
- [x] 3. Selection — click selects (never builds), Shift+click toggles, Ctrl+click floods a floor/ceiling at one height, Ctrl+D clears; orange outlines in 3D, marked on the 2D map
- [x] 4. Wheel editing — floors/steps/ceilings/lintels an eighth a turn (Ctrl: a wall); walls: Shift pull / Alt push a cell, Ctrl+Shift = block on the floor (its top), Alt+Shift = block from the ceiling (its bottom); scrolled face stays selected; one undo per run
- [x] 5. Arrow nudge — arrows move the selection's cells a cell relative to facing (contents, heights, things); vacated cells copy the cell behind; selection follows
- [x] 6. Toolbar — SELECT/PLACE/LIGHT/HEIGHT tools, DELETE (Del), UNDO, SAVE, GRID + drag slider, 2D/3D, HELP panel (F1); tooltips; same bar in the map view (select there by click/box, arrows nudge); held button no longer re-clicks each frame (4075310)
- [x] 8. Picker — 9 tabs, 2×8 thumbnails from the game's own art (lights animate), wheel/arrow scroll + bar, big brush preview; click = brush + tool (PLACE/PAINT/LIGHT), applied to the selection at once for things; P toggles; HUD bars hidden in the editor (d967418)
- [x] 9. Per-face pictures — PAINT a picture on any wall side/step/lintel/floor/ceiling (Ctrl+click fills a floor, Shift+click resets, picking with a selection paints it); [faces] in the level file, 24 custom texture slots, both renderers, undo, level kit passes it through (4b9d42d)
- [x] 10. Divide — H left|right, V top|bottom (again: whole) on selection or hovered face; halves picked/outlined/selected/painted separately; both renderers (software per column/row, GL two strips/quads; GL steps' u now match software); floors west|east, north|south; H help moved to F1 (44d3fae) + picker tucks away to a strip (auto/pinned/off) so near floors aren't hidden
- [x] 11. Placing — PLACE ghost (magenta cell box + see-through brush sprite) where it'll go; drag places along floors (one undo); Shift+click erases, Alt+click eyedrops (PAINT: picks the face's picture); pads say their pair
- [x] 12. Properties pane — door kind/key buttons; teleporter: where it goes, LINK any two pads ([pads], kit-aware), UNLINK, 3D pair lines; floor → MAKE A LIFT; lift low/high/speed ±, mode, REMOVE; undo keeps lifts (f4bc5c6)
- [x] 13. Face lights — LIGHT on a face (anchored just in front), LIGHTS tab: 6 effects animated live + 12 colours, light pane (colour/effect/reach/brightness/remove), face tinted its light's colour (self-lit + animated in GL; both renderers), 3D light markers
- [x] 14. Monster pane — click a monster (things are pickable now); sight/hearing/health%/speed%/wake (sees you, you're near, when hit, hunting) + reset; sight & hearing rings on the floor; [monsters] by start cell (nudge carries it); game applies at level start; shots wake monsters with hearing (default 0 = unchanged play) (18c40c9)
- [x] 15. 2D map — picker in the panel (4×3, same tabs), panes over the map (door/pad+LINK/light/monster/lift/floor), PAINT floors/ceilings/wall sides with drag, wheel raises selected floors (Ctrl ceilings), < SECT / SECT > / MONSTER KINDS buttons; fast clicks no longer lost or stuck
- [x] 16. Docs — LEVEL-EDITOR-GUIDE.md rewritten (toolbar/picker, 3D tools, shaping, faces/Divide, panes, map view, face lights, [faces]/[pads]/[monsters], gotchas), TUTORIAL + README editor text, CLAUDE.md test notes; F no longer kicks / 1-4 no gun swap in the editor (4ae060d)
- [x] 17. Three showcase sectors (YOUR SECTORS 11-13: THE GALLERY, THE SUNKEN DEPOT, THE RELAY) built by levels/showcase.py with the level kit, all checks pass, viewed in both renderers; face-tint pass fixed (read map rows; no wasted half/lintel copies), >24 slots warns, kit validate honours [pads] (b4aa375)
- [x] 18. Monster settings verified in play with a test sector + new `mons` console command: sight range (asleep at 6.5 with sight 5, awake at 3.5), near (wakes behind a pillar; default twin sleeps), hit-only (sleeps in view, wakes when shot), hunting from start, hearing (wakes on a shot; deaf twin sleeps); health/speed applied
- [x] 19. Sector 14 THE CONSERVATORY — woven divided floor (soil/white), bottomless pond crossed on six mode-1 lifts at their own speeds, glass-walled specimen garden behind the red door, the light lab (all six effects); docs say four showcases (9d102ba)
- [x] 20. SECTOR pane — name typed in place (keys held from walking/menu while typing), ambient brightness ± and 12 tints, the 6 wall kinds / 4 floors / 2 ceilings each chosen from the picker (stays open till chosen); guide + help
- [x] 22. README screenshots — editor-walk.jpg (3D: statue's pane, picker, lit painting), editor-map.jpg (map: door pane, DOORS tab), light-lab.jpg (the Conservatory), all OpenGL + MODERN art (ab92751)
- [x] 21. Review (3 agents: data, renderers, UI) and fixes — LINK pairs dropped by a bitwise AND (now verified: all 4 Relay pads reach their chambers), typing leaks (F2/console/F5/F9), stale editor clicks, state reset on enter/leave/sector, undo of name+ambient, nudge carries faces/pads/monster settings, EditPut drops stale settings, cross-view selections, 2D off-map box release, diagonals/closets, 4000-faces note, kit [pads] robustness (d4ddfa1)
- [x] 23. EVENT pane — MAKE AN EVENT ROOM from a floor box; an event cell's pane: 12 kinds by name (switch = sensible numbers), its two numbers labelled by meaning (frames shown as seconds, monster kinds by name), prize, REMOVE; events in undo; tested save
- [x] 24. TRIGGER pane — TRIGGERS... on door/floor/wall panes: the selection's triggers listed with x to remove; new: ENTER/USE/CLEAR/TIME, once/every time, commands typed in place; triggers in undo (undo now covers everything); tested end to end
- [x] 25. Sector 15 THE LISTENING POST — hearing guards (sight 4, hear 14), crawler closets, survive room (blue card), statue over the red card, archive locked by `time 0` trigger and opened by a USE trigger on a lit terminal face (tested in play)
- [x] 26. Sector 16 THE OBSERVATORY — tower in a garden, glass windows, stairs → elevator → mode-1 lift to the summit, ledge edges painted (one divided) and lit, summit pad LINKed to the exit vestibule + a garden pair (both verified in play)
- [x] 27. Scripted runs: sectors 11-16 each played in god mode - every key picked up by teleport, the exit used - all reach SECTOR CLEAR, no errors.log; the Listening Post's survive room locked down as designed
- [x] 28. YOUR SECTORS holds 20 (MAX_CUSTOM 20): page 1 lists 11-20 + MORE SECTORS (21-30); both pages checked; docs say 17+ for the player (fourteen free)
- [x] 29. Sector 17 THE FLOODED ARCHIVE — hall floor painted floor-murky cell by cell (wading via texName$ of the custom slot - verified in code), lit stack ends, near-wake crawlers, broken catwalk, dying/flicker lights, spitters that hear; runs to SECTOR CLEAR
- [x] 30. Sector 18 THE CORE — reactor block with red pulsing faces, molten ring painted to burn, four mode-1 lift bridges at their own paces, fire traps on the island corners, near-sprung guardian, strobing wall alarms, armoury behind red; runs to SECTOR CLEAR (8 showcase sectors now; 12 YOUR SECTORS slots free)
- [x] 7. Grid overlay — G toggles, Shift+G stronger; drawn into surfaces (GL shader via fwidth, software renderer's floors/walls/steps), depth-correct; on the 2D map too; G/K cheats off in the editor
