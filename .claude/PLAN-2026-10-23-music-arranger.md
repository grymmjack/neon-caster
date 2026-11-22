# Music arranger - plan (2026-10-23)

Rick's ask: every music track is ~45 s, and just when it gets good it ends,
then loops abruptly (sometimes a fade or silence first). Turn each track into
clips with musical start/end points (BPM, bars), arrange them into something
longer that loops well - automatically to begin with - and let Rick see and
change the markers and the arrangement: in the game (a pattern-based
timeline), and in Bitwig or Renoise.

Why they're short: they're Stable Audio renders (soundmon, made on rtx), and
Stable Audio tops out at ~47 s. 58 tracks in `neon-caster/music/`: 57 `.ogg`
(31-46 s) and `cyber.flac`.

## Phase 1 - analysis + automatic arrangements (do first: Rick hears results soonest)

- `neon-caster/music/arrange.py` (in a venv with librosa + numpy + soundfile;
  install librosa into `~/ComfyUI/.venv` or a new venv - neither has it now).
- Per track:
  - BPM, beat grid, bar 1's downbeat (`offset`). Check each for tempo drift
    (AI tracks are usually steady). Prove the grid by rendering a click track
    over the song and listening / looking at onsets.
  - Per-bar features: RMS, low-end energy, spectral centroid, onset density
    -> an energy curve.
  - Bar-to-bar similarity (chroma + MFCC self-similarity) -> seams: pairs of
    bars where playback can jump without a join being heard (Paul Lamere's
    Infinite Jukebox idea, at bar level).
  - Section boundaries by novelty (where the sound changes): intro, build,
    groove, break, ending.
  - The dead tail: fade-out / silence / "finality" at the end - never loop into it.
- Writes `music/NAME.arr` (plain text, hand-editable):
  ```
  bpm 128.0   offset 0.212        ; bar 1 starts here (seconds)
  clip A  bars 1-4    intro
  clip B  bars 5-8    build
  clip C  bars 9-16   groove      ; loops seamlessly into itself
  clip D  bars 17-20  break
  arrange A B C*4 D C*2 B C*4 D
  loop from 3                     ; after the end, back to the 3rd entry, not the intro
  ```
- Automatic arrangement per track: intro once, build by energy, the best
  groove looped, a breakdown, back up; ~3-4 minutes before it loops
  (3-4 minutes: answered, below). Score each track's seams; list the ones
  with few or no clean seams for Rick's ear (or a new take).
- Render: `music/NAME.ogg` played by the game becomes the arranged version,
  cut at exact samples with short (5-20 ms) equal-power crossfades on bar
  lines. Keep the 45 s originals as sources (e.g. `music/src/`, or out of
  the release). The game streams the longer .ogg exactly as now: no glitch risk.
  Re-run `viz.py` after (the SOUND TEST's waveform/spectrum data).
- Report page: each track's grid, sections and seams over its waveform,
  the arrangement as blocks, and players for before/after (a hand-built HTML
  field report, as Rick likes).

## Phase 2 - Bitwig (DAWproject) round trip - FOURTH (after the editor and Renoise)

- Bitwig Studio 5.3.13 is installed: it imports/exports **DAWproject**
  (open format, Bitwig + PreSonus: a zip of `project.xml` + `metadata.xml` +
  audio). Bitwig's own `.bwproject` is undocumented binary - don't.
- Export per track: tempo set, the source audio, one clip per section laid
  out in the arrangement, markers at the sections.
- Import: read Rick's edited DAWproject back -> the `.arr` (clip
  start/end/offset in beats -> bars; the arrangement lane's order -> `arrange`).
- Ableton `.als` (gzipped XML, undocumented): only if Rick wants it.

## Phase 3 - in-game editor (SOUND TEST, MENU/SOUNDTEST.BM) - SECOND, after phase 1

- The seek bar gets the bar grid and the clips as coloured blocks; drag markers.
- Under it, a pattern row: the arrangement as blocks (A B C×4 ...): add,
  remove, repeat, reorder; BPM and the bar number while it plays.
- Exact preview needs samples: the game reads WAV/FLAC samples (`_MEMSOUND`)
  but not Ogg (paged - see CLAUDE.md). Options:
  - dev-only lossless sources (FLAC, not shipped) -> build the arranged audio
    in memory (`_SNDNEW`) and play it exactly; or
  - preview by `_SNDSETPOS` jumps (on a frame, ~16 ms: a little clicky) and
    the exact render on save (arrange.py).
- Saves the `.arr`; rendering stays a dev step.

## Phase 4 - Renoise: WANTED (Rick, 2026-10-23: "yes i want a xrns per track!")

- Renoise 3.5.4 installed. `.xrns` = zip with `Song.xml`: the track as a
  sample sliced on bar lines, one pattern per section, the pattern sequence
  = the arrangement. Reading it back is possible, harder than DAWproject.

## Not doing

- Jumping around inside the 45 s file at run time in the game: QB64 can only
  seek on a frame (clicks), and can't read an Ogg's samples.

## Answers so far (2026-10-23)

- **Length:** 3-4 minutes a sector; lulls and builds as well as excitement, Claude's judgment.
- **Sources:** lossless WAVs of the 46 picked tracks (three sets + showcases) are in
  `~/Music/NEON-CASTER/sources/KEY.wav` - fetched from rtx's ComfyUI output (`soundmon/`),
  checked identical to the shipped .ogg (which are turned down 0.4-4 dB: the gain per track is
  in `~/Music/NEON-CASTER/README.md` - render arrangements at the shipped loudness). Every
  other take is in `~/Music/NEON-CASTER/takes/KEY/` (spare material). The original ten +
  `menu.ogg` (2026-10-11) have no lossless copy: their .ogg is the source. Rick: keep the WAVs
  on disk for good.
- **Order:** phase 1 (analysis + automatic arrangements), then the **in-game editor**, then
  **Renoise**, then **Bitwig**.
- **Clips must be launchable, not only arranged** - "fire them in session clips not just in
  arranger":
  - Bitwig: DAWproject has `<Scenes>` / `<ClipSlot>` (the clip launcher) besides the
    arrangement - export both: each section a clip in a slot, scenes for sensible
    combinations, plus the arrangement. Check Bitwig 5.3's import fills the launcher.
  - Renoise has no session view, but patterns can be triggered live (the pattern matrix,
    scheduling a pattern with the mouse/keys/MIDI): one pattern per clip does that.
  - In the game: a session grid in the editor - click a clip and it starts at the next bar
    (queued, like Bitwig's launch quantise), looping until another fires. Sample-accurate
    playback from the lossless sources: QB64PE's `_SNDRAW` stream (push the clip's samples
    a frame ahead) or `_SNDNEW` buffers built from `_MEMSOUND` of the WAV - not `_SNDSETPOS`
    jumps. "Record" what you fire into the arrangement, as Bitwig does.

## Open questions for Rick (asked 2026-10-23, not answered yet)

1. ~~How long before it loops?~~ ANSWERED 2026-10-23: **3-4 minutes a sector**,
   Claude's judgment on the shape - "diversity and excitement but also
   sometimes lulls and builds". So: not just the best groove on repeat -
   vary which clips come round, drop to a lull (fewer layers / the break)
   before building back, end the cycle somewhere that leads back into the
   loop point.
2. ~~Lossless sources?~~ ANSWERED: yes for 46 - see "Answers so far".
3. ~~Which first after phase 1?~~ ANSWERED: in-game editor, then Renoise, then Bitwig.
4. ~~Renoise?~~ ANSWERED 2026-10-23: yes, an `.xrns` per track (phase 4 is in, not optional).
