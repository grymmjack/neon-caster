# The music

Every track began as a ~45 second take from Stable Audio (soundmon), which
ended just as it got going and looped abruptly. Each one is now cut on its
own bars into clips and arranged into 3-4 minutes that loop: `NAME.ogg` is
what the game plays, and `NAME.arr` (plain text) is how it was put together:

```
bpm 135.000   offset 0.0350   bars 23   tail 24   ; bar 1 starts 0.035 s in; bars from 24 on are the fade
source level1.ogg (lossy)
auto yes          ; no once you've changed it: arrange.py --analyze leaves it alone then
clip E  bars 17-20   groove
clip F  bars 9-20    peak
clip J  at 17.25-17.5 groove   ; finer than a bar: bar places, to a 128th (17.25 = bar 17's 2nd beat; the end not included)
pattern A1  C*2 B   ; a pattern: a little arrangement of clips, played as one block
arrange E A1 F G C H I F*2 G E C H I A1*2
seam 20 9 0.73    ; after bar 20, bar 9 can follow - how alike the join is (0-1)
```

The takes are in `src/` (left out of the downloads); Rick's lossless copies
of most are in `~/Music/NEON-CASTER/sources/`.

## Changing an arrangement

In the game: SETTINGS > AUDIO > SOUND TEST, MUSIC, pick a track and press
**E** (or `arranger level1` in the console). The MUSIC ARRANGER plays it live
from its take, so you hear a change at once:

- the take across the top, with its bars and clips (click: play from there;
  drag a clip's end to resize it, or the clip itself to move it along - its
  start lands on the grid, its length stays). Drag across it to make a new clip - a click
  and a drag are told apart by a 4-pixel move, so even one square of the grid
  is a clip. The mouse wheel over the take zooms round the pointer (Shift+wheel
  slides along, the middle button shows it all), and the **grid follows the
  zoom**: a bar, 1/2, 1/4... down to a 128th of a bar, whichever is the finest
  with squares 40 pixels wide (GRID in the header). Clips, their ends (`,` `.`
  `<` `>` move them a square) and the clip launcher all work to it. Places
  read BAR.BEAT.16TH (17.2.3; `+N` is N 128ths past it - `+4` a 32nd), lengths as "1/4 BAR".
  Most takes start a little before bar 1: that's the lead-in, IN (bar 0 in
  the .arr), and a clip can start there - an intro, with the take's very
  first notes,
- a pad for each clip: click it (or type its letter) and it starts on the next
  bar and loops - Ctrl+R records what you launch into the arrangement.
  Ctrl+K changes the picked clip's kind (intro, groove, build, peak...),
- the arrangement as blocks: Ins adds the picked clip after the block,
  Shift+Ins before it (Home, then Shift+Ins: first), Del takes one out,
  Ctrl+Del clears them all (Ctrl+Z brings them back), Up/Down for repeats,
  Shift+arrows or a drag to move one, Enter or a double-click to play from it,
  Ctrl+L: the loop goes round from this block (the ones before it are an
  intro, played once),
- **patterns** (between the pads and the arrangement): a pattern is a little
  arrangement of clips that goes into the arrangement as one block, drawn
  with its clips' colours and its name. There are 54, A1-F9: click a BANK
  (A-F) and a slot (1-9) to open one in the pattern row (a slot with a pattern
  in it is lit). Shift+click a run of blocks in the arrangement and Ctrl+P
  makes a pattern of them (the next free slot; they become one block of it),
  Ctrl+Shift+P opens a pattern block back out into its clips. In the pattern
  row the same keys edit it as edit the arrangement (PgUp: the keys work on
  the pattern, PgDn: on the arrangement; clicking a row does it too). Drag a
  slot's number into the arrangement, right-click it (Shift: before the
  block picked), or Ctrl+Ins, to put that pattern in. A pattern is as long as
  its clips, and holds clips only (no patterns in patterns). Clicking a
  pattern block in the arrangement opens it above,
- Ctrl+S saves `NAME.arr`, Ctrl+E makes `NAME.ogg` from it, Ctrl+B makes the
  Renoise and Bitwig sessions (below). Both run in the background.
- **other arrangements**, to try things without losing the game's: Ctrl+Shift+S
  saves as a name you type (the name it has is filled in, lit: typing
  replaces it, an arrow key keeps it to add to). Any name but the track's is
  `arrangements/NAME/THAT.arr`; the track's own name is the game's
  `NAME.arr` again - the one there is kept first, as `arrangements/NAME/before1.arr`
  (2, 3... after that). Ctrl+O lists them all to open (the game's first),
  Ctrl+Shift+N starts an empty one (the clips and patterns kept; Ctrl+S asks
  its name). Ctrl+E renders an alternative beside its .arr
  (`arrangements/NAME/THAT.ogg` - the game never plays it; save it as the
  track's name to make it the game's), Ctrl+B exports it as `NAME-THAT.xrns`
  and `.dawproject`.
  `arrangements/` is left out of the downloads.

Without a loop point the .ogg loops as a whole, so an intro comes round again
each loop. With one (`|` in the arrange line: `arrange L | C E F...`) the
render makes two files: `NAME-intro.ogg`, the blocks before the `|` (from the
take's very start, with half a second of the loop after them), and `NAME.ogg`,
the loop. The game plays the intro once and hands over to the loop on the
same sample (`PlayMusicIntro`, `MusicFrame`). Only the menu's music has one
so far (`menu.arr`: clip L, the lead-in and the first four bars).

It plays from `edit/NAME.flac` (each take, lossless, at the shipped
loudness - they ship with the game). After a take is added or changed, make
its FLAC again and commit it:

```
~/.venvs/music/bin/python arrange.py --sources NAME     # edit/NAME.flac
```

## From the command line

(Any NAME can be `NAME/ALT` - `level1/test` is `arrangements/level1/test.arr`.)

```
~/.venvs/music/bin/python arrange.py --analyze NAME     # the grid, clips and an arrangement (keeps one marked auto no)
~/.venvs/music/bin/python arrange.py --seams NAME       # score the joins of an arrangement changed by hand
~/.venvs/music/bin/python arrange.py --render NAME      # NAME.arr -> NAME.ogg
~/ComfyUI/.venv/bin/python viz.py                       # what SOUND TEST's player draws (any .viz older than its .ogg)
python3 ../sfx/soundtest.py                             # if a track was added
```

(The venv: `python3 -m venv ~/.venvs/music && ~/.venvs/music/bin/pip install
librosa soundfile numpy scipy matplotlib beat_this`.)

## In Renoise or Bitwig

```
~/.venvs/music/bin/python daw.py --xrns NAME            # ~/Music/NEON-CASTER/daw/renoise/NAME.xrns
~/.venvs/music/bin/python daw.py --dawproject NAME      # ~/Music/NEON-CASTER/daw/bitwig/NAME.dawproject
~/.venvs/music/bin/python daw.py --from-xrns FILE       # what you made there, back to NAME.arr
~/.venvs/music/bin/python daw.py --from-dawproject FILE
```

Renoise: the take is one instrument sliced at every bar (bar 1 is C-4, the
lead-in B-3, played late by its delay column), a pattern per clip, the
sequence is the arrangement; clips it doesn't use come after a CLIPS section,
to schedule live. Bitwig: the arrangement on one audio track with a marker at
each clip (a repeat is the clip again, end to end), and the clip launcher with
a scene per clip, each looping on exactly its bars; every clip has its colour
from the game's arranger. A loop point goes across as a Renoise section and a
Bitwig marker named `| ...`, and comes back from them. A pattern's block is
its clips, one after another, the first named `[A1] C peak` and the rest
`(A1) B groove`; those names bring it back as the pattern (a play of it that
was changed there comes back as its clips).

The track's **sampler instruments** (soundmon's `tools/instruments.py`: a drum
kit, each part's notes, chords, pads) are made beside its stems, in
`samples/NAME - TITLE/5 Instruments/` - `Renoise/*.xrni`, `Bitwig/*.bwpreset`
and `.multisample`. `--xrns` also links the Renoise ones next to the songs, in
`daw/renoise/instruments/NAME - TITLE/` (links, not copies), so Renoise's
browser (Instr. tab) finds them there.

Bitwig also gets the track's **stems** when they're there
(`~/Music/NEON-CASTER/samples/NAME - TITLE/`, made by soundmon's `tools/stems.py`
on the farm - its `INFINITE-SAMPLES.md` has the steps): a track per stem, cut on
the same clips, in groups - STEMS (drums, bass, synths + fx, vocals: playing,
with the take muted beside them) and the finer splits, muted (DRUMS SPLIT,
SYNTHS BY RANGE, SYNTHS BY KIND, SYNTHS DRY + REVERB). The same folder's
`5 Instruments/` has the one-shots as Sampler instruments (`.multisample`: a drum
kit, each part's notes, chords, pads) to drag onto a track.
Then `arrange.py --seams NAME` and `--render NAME`.
