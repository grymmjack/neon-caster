# Menu intro, arranger export, widescreen everywhere, Bitwig stems (2026-10-24, branch music-arranger)

## ▶️ WORKING — Rick's asks of 2026-10-24 ~11:00, in order (not an armed loop: progress shown here)

## 🔨 NOW
_(nothing in hand - waiting on Rick)_

## Done
- [x] Committed + pushed: soundmon feat/instruments (PR #4: instruments.py, bwpreset.py, stems.py fix, README + INFINITE-SAMPLES docs); neon-caster music-arranger 2f0f070 + 20cc5e3 (Renoise instruments linked into daw/renoise/instruments/, 461 links)
- [x] Arranger: drag a clip's body to move it along the take (start and end together, start to the grid, length kept; 4 px before it moves, so a click still picks; Ctrl+Z puts it back) - checked offscreen: J 17.2 -> 16.3.3; help panel and music README
- [x] Renoise .xrni for every track: 457 over 56 tracks; level6 + level9 had no stems (stems.py crashed on a track with no drums - fixed: bars from the mix, one-shots without drums), re-run on daw: bass + bass chords each (they're ambient: the rest is one 'synths + fx' stem); a first run's stale synth stems moved to '1 Stems/older split'; their Bitwig projects re-exported
- [x] Renoise .xrni instruments (soundmon instruments.py `write_xrni`, 5 Instruments/Renoise/): drum kit (one-shots, unpitched, C-2 up = MIDI 36), notes, chords (C-4 up), pads (looped) - loaded in sandboxed Renoise 3.5.4 offscreen (own Xvfb, no sound devices, throwaway HOME; a Lua tool dumps what it read): all 14 of new3 with every sample, key, range and loop right; docs (docstring, INFINITE-SAMPLES.md)
- [x] Arranger: a clip's end off the strip when zoomed is grabbed where its block is cut off (Rick couldn't move a start made zoomed in) - checked offscreen: 17.2 dragged to 17.4
- [x] Alt+X quits from anywhere, no prompt (ShowFrame: every screen's frame; QuitGame saves settings) - checked offscreen in the arranger; TUTORIAL controls
- [x] Arranger: finer than a bar - time in 1/32-bar steps (AR_TPB), clips down to a 32nd (click vs drag by a 4 px move: one grid square is a clip), wheel zoom round the pointer / Shift slides / middle = all, the grid follows the zoom (1/1-1/32, GRID and ZOOM in the header), places as BAR.BEAT.16TH; .arr `clip X at 5.25-5.5`; arrange.py reads/writes/renders them (byte-same as the game's save; render length exact); daw.py: Renoise slices at finer edges (LPB 8 for 32nds), Bitwig exact, both imports to a 32nd - round trips SAME (plain, 1/4, 1 1/2, 1/32 clips); checked offscreen 1600x900 and 800x600
- [x] Arranger keys as a panel (Rick, 12:55): six columns - PLAY / ARRANGEMENT / CLIPS / MOUSE / FILE / JOINS, keys in the group's colour, swatches for the joins; centred on wide screens
- [x] Bitwig stems batch: all tracks' stems in ~/Music/NEON-CASTER/samples, instruments built (568 .bwpreset); the export stopped at menu-intro (not a track - arrange.tracks() now leaves NAME-intro out) and the 36 after it were exported again
- [x] Native Bitwig presets (soundmon tools/bwpreset.py): reads/writes Bitwig's .bwpreset (all 157 plain presets on disk round-trip byte for byte), builds a Drum Machine (a Sampler a pad) and Samplers (one sample, or zones; loops) on Bitwig's own default devices; instruments.py writes 5 Instruments/Bitwig/*.bwpreset where Bitwig is installed. Loaded in the sandboxed Bitwig: kit pads with their samples, the bass's 3 zones, the pad's loop
- [x] Widescreen helper for loops of their own (ScreenWideBegin) - the census below
- [x] Widescreen census at 1600x900 (FULL WIDE): title, attract, game, tuner, monster editor, puzzle, tally, pause menu, arranger. The rest (keypad, hack, slots, pong, launch control, notes) are solid panels over the dimmed view, like the puzzle; transmission/route/achievements use the wide backdrop. Fixed: the pause menu's box edge (the shader's side dimming now purple, as the menu's: GL/OPENGL.BM), the monster editor's SPEED line cut off at 800. Not wide: the software renderer and windowed mode (WideView needs OpenGL + fullscreen) - for Rick
- [x] Docs: music README (Ctrl+L, |, intro files, Ctrl+B, stems), README.md, CLAUDE.md
- [x] soundmon tools/instruments.py: one-shots -> .multisample (drum kit from C1 + key list, notes, chords, pads); stems.py runs it at the end; INFINITE-SAMPLES.md
- [x] daw.py: stem tracks in groups (STEMS playing, take + finer splits muted), external files, the take's clips; schema validates, round trip SAME; opened in sandboxed Bitwig (new3): groups, stems with waveforms, clips coloured
- [x] Arranger: Ctrl+B exports Renoise + Bitwig (ArRunTool: daw.py --xrns --dawproject in the background, like Ctrl+E; the message names the two files)
- [x] Arranger widescreen: ScreenWideBegin + ArLayout (arW = scrW - 32, pads a row by width, overview re-squeezed); checked on a 1600x900 Xvfb: waveform, lanes, row and help span it, a click at x 1400 plays bar 21
- [x] Menu intro: `L | C E F...` (clip L = IN-4); arrange.py renders menu-intro.ogg (9.05 s: lead-in + 4 bars + 0.5 s of the loop) and menu.ogg (the loop, 112 bars); PlayMusicIntro / MusicFrame (in ShowFrame) hand over - recorded from claude_mute: the loop lands within 0.5 ms, no click
- [x] Arranger: the loop point (Ctrl+L), INTRO/LOOP marks on the row, playback wraps to it, saved as `|`; SOUND TEST's arranged-track check counts the loop's bars
- [x] daw.py: `|` through Renoise (section "| ...") and Bitwig (marker "| ...") and back - menu round trips SAME, schema validates
