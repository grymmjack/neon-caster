# Music arranger (2026-10-24) - from .claude/PLAN-2026-10-23-music-arranger.md

## ✅ LOOP DONE — every phase finished 2026-10-24 ~03:00 (branch music-arranger pushed, not merged)

Work happens on branch `music-arranger` in a worktree (`~/git/neon-caster-music`),
so the game in `~/git/neon-caster` (Rick's) is untouched until he merges.
Lossless sources: `~/Music/NEON-CASTER/sources/` (46 WAVs + shipped gains in its README).

## 🔨 NOW — doing right now
(nothing - all done)

## To do

### Phase 2 - in-game editor (SOUND TEST)

### Phase 3 - Renoise  (music/daw.py, built by a helper agent)

### Phase 4 - Bitwig

### Wrap-up

## Done
- [x] Commit 0bc602d on `music-arranger`, branch pushed to origin (main untouched); final report in chat
- [x] Report page: https://claude.ai/artifact/CSrzd4Kq9mzhUnLjZUicky - all 58 tracks (bar grid, clips, arrangement + joins, seam map, before/after players with playheads), phases 2-4 screenshots, questions. EDIT > MUSIC tested on :99 (opens SOUND TEST's MUSIC; E -> arranger)
- [x] DAWproject import: Bitwig-style nested clips, edits (swap, moved clip -> new clip, loop -> X*2), seconds-timed arrangements all read back. Demo-mode Bitwig can't save, so no Bitwig-written file was round-tripped
- [x] DAWproject export (daw.py --dawproject): tempo, the FLAC inside, one audio track, a clip per play placed in beats, cue markers, one looping launcher scene per clip; passes the official XSD; Bitwig 5.3.13 opened level1 (9 scenes, markers right). All 58 in ~/Music/NEON-CASTER/daw/bitwig
- [x] .xrns import (daw.py --from-xrns): a Renoise-saved file reads back identical; Renoise-edited new4 gave new clips M N O. 116/116 round trips identical (checked level3 again myself)
- [x] .xrns export (daw.py --xrns): source sliced at every bar (bar 1 = C-4), a pattern per clip, the sequence = the arrangement (sections named), unused clips after it in CLIPS; fractional tempo kept; Renoise 3.5.4 opened and re-saved it. All 58 in ~/Music/NEON-CASTER/daw/renoise
- [x] Docs: README, TUTORIAL (arranger command, music folder, Hear the joins), CLAUDE.md (The music is arranged), LEVEL-EDITOR-GUIDE (EDIT > MUSIC - new menu entry to SOUND TEST's MUSIC), music/README.md (workflow, keys, --render/--seams/--sources, daw.py); SOUND TEST help shows E ARRANGE. Built OK
- [x] MUSIC ARRANGER (EDITOR/ARRANGER.BI/.BM): reads/writes .arr (LF, auto no; python reads it back), plays live from music/edit/NAME.flac via _SNDRAWBATCH 0.1 s ahead, equal-power 15 ms crossfades before bar lines; heard position from a ring of what was pushed. Live arrangement vs rendered level1.ogg: correlation 0.998, no dropouts. Opened by E on a track in SOUND TEST, or `arranger TRACK` (ConExec/ConHelp/ConNames)
- [x] The take's strip: waveform, bar grid + numbers, the fade shaded, clips in lanes (drag an end to a bar line; , . < > keys), the playhead; BPM, bar, block and time while playing. SOUND TEST's seek bar shows an arranged track's blocks and BAR n CLIP BPM (checked: BAR 9 F at 0:08)
- [x] Pattern row: blocks as long as they play, joins coloured by seam score (green/yellow/red, grey unscored); Ins/+ add, Del/- remove, Up/Down/wheel repeats, Shift+arrows or drag to move, double-click/Enter plays from one; undo/redo; Ctrl+S save, Ctrl+E render in the background (arrange.py --render). Tested by xdotool on :99
- [x] Session grid: pads per clip - click or letter launches on the next bar (Ctrl+Q: at the clip's end), loops; Ctrl+R records launches into the arrangement (a pass cut short becomes its own clip; the end cut by the stop left off) - tested: B, cut B, C -> "B J C". Ctrl/Shift and quick clicks followed through the event queues (xdotool found both races). arrange.py --seams added: every arrangement join + clip self-loop scored into all 58 .arr (grids re-derived identical)
- [x] Arranged tracks in the game: originals to music/src/ (left out of releases by the workflow), cyber.flac -> cyber.ogg, viz.py + soundtest.py re-run; built and played muted: SECTOR 1 four minutes - no gaps, the loop came round at exactly 192.000 s; NEW SECTORS 3 streamed new3. Committed on music-arranger (d74bbf5)
- [x] Renderer, all 58: bars cut on the grid, joins crossfaded before the bar line (15-120 ms, doubled till the highs are no more than 1.15x the original's there; linear when the sides match, equal-power when not), the end crossfaded into the start; turned down only, to the original's loudness (within ~1 dB) and peak; oggenc q5 from lossless / q6 from lossy, decoded peak checked. 185-215 s each, joins <= 1.11x, 237 MB in all
- [x] Per-bar features (loudness, lows, brightness, onsets, fall), bar similarity (beats' MFCC + chroma, 1 = as alike as a loop's repeats), seams, sections (Foote novelty, leaning to 8-bar lines, 8-bar clips), the fade tail; NAME.arr writer/reader (auto yes/no keeps hand edits)
- [x] Automatic arrangements, all 58: a bar-by-bar walk (beam search per phrase start) jumping only phrase-end -> phrase-start where the bars match (>= 0.5), target shape lull/build/high/lull/peak, 185-215 s; 49 clean, weak (a join < 0.5, mostly the loop point): level3 level10 remix2 remix3 remix4 remix8 remix10 sector13 sector31
- [x] Beat grid, all 58: librosa onsets + a refined straight grid (round tempos snapped), beat_this (CPJKU) as second opinion - fixed remix6 (128 not 170) and sector29 (140 not 93), bar 1 from its downbeats on 37 tracks; drift <= 5 ms everywhere; grid moved onto the kick's attack (4 ms ahead); checked on spectrograms + click renders (scratchpad/clicks)
- [x] Setup: worktree ~/git/neon-caster-music (branch music-arranger), venv ~/.venvs/music (librosa 1.0), arrange.py loads all 58 (46 lossless WAVs at shipped gain, 11 .ogg, cyber.flac)
