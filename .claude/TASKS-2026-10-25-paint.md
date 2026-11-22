# Solid colours, gradients, and an in-game paint editor (2026-10-25)

## ✅ LOOP DONE — every item finished (not committed: left for Rick)

Rick's ask (2026-10-25, before sleeping): "solid colour and gradients in the texture
editor painter thing ... a little paint editor with lines, paint brush, color picker,
shapes" - "do both" - "it's just to do more immediate work in painting and
experimentation with filters". Not committed: left for Rick to review.

## 🔨 NOW

(nothing - all done)

## Part 1 - solid colours and gradients

- [x] G1. Generated pictures: `#RRGGBB`, `#RRGGBB-RRGGBB-D` (D: V H D R M) - GenPic/GenParse/GenName$/GenAt~&/MakeGenTex/GenImage&/PicImage& in RENDER/PICTURES.BM; LoadTex makes them, PcSlotFor + LOADLEVEL accept them, thumbnails (EditFileThumb&, PrThumb&) through PicImage&, the picture menu locked for them. Checked in software + OpenGL, CLASSIC + MODERN, with filters (test copy's level1.txt is a real file - restore the symlink at the end)
- [x] G2. Picker: COLOUR and GRADIENT tiles after + NEW (labelled), then the sector's own made colours - plain PK_TEX entries so a click is the brush and paints the selection; picker key rebuilds them; picture menu/OPEN IN locked for them
- [x] G3. PICTURE pane: a COLOUR: ... (CHANGE...) row opens EditPaneGen (SOLID/GRADIENT, FROM/TO swatches, 12 colours, RGB -/+, TYPE hex, DOWN ACROSS SLANT ROUND BAND, SWAP, BACK); nothing selected it sets the tiles. Tested on Xvfb: paint, change way/colours/typed, solid, save -> `30, 9, S, 0, #00FF80`
- [x] G4. Tested software + OpenGL, CLASSIC + MODERN, filters on them (posterize, invert); lvlkit accepts # names; guide (Solid colours and gradients paragraph, picker table) + CLAUDE.md entry

## Part 2 - the in-game paint editor

- [x] P1. EDITOR/PAINTER.BI/.BM: its own loop (PaRun: GLCapture/ShowFrame like the tuner), opened by Ctrl+E (PaOpenKey: picker, face under pointer, selection, brush), PAINT HERE on the PICTURE pane (513), the picker menu's PAINT HERE row (rows renumbered, NP_MROWS 13); a made colour becomes wall-newN.png first (EditTexOp 15 swaps exactly it on the selection; left unsaved it goes back and the file is removed); zoom (wheel at pointer, + -, FIT), pan (middle/Space drag, arrows), grid; Ctrl+S writes the PNG and NpReload shows it. Tested software + OpenGL
- [x] P2. Tools: pencil, round brush (size [ ]), line, box, filled box, ellipse, filled ellipse (Shift: straight/square/round), flood fill, pick (Ctrl+click any tool), two colours (left/right), 32-colour palette, RGB -/+, typed hex, swap, undo/redo (40), MIRROR L-R / U-D, WRAP, TILED view, previews (as is, 2x2). Presses read from the mouse event queue (quick taps count). All tested on Xvfb
- [x] P4. PAINT ACROSS THE n FACES (PICTURE pane 514, PaAcross): floors/ceilings on the map grid, walls facing one way along the wall as seen (gaps kept, each line a row), mixed in a row; 64-px tiles start as the faces' pictures; Ctrl+S writes wall-sheetN-K.png each and (first save, one undo) puts each on its face with its look let go (PaAcrossPut). Tested: 3 faces round a door - gap kept, drawn across, saved and shown
- [x] P3. Tested on Xvfb (draw, save, shown in the sector; floors across in an L - laid on the map grid, gap kept, floor-sheet1-1..3 saved and shown); guide + CLAUDE.md; final compile clean; test copy cleaned (level1.txt symlink back)
