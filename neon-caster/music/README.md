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
arrange E F G C H I F*2 G E C H I F H
seam 20 9 0.73    ; after bar 20, bar 9 can follow - how alike the join is (0-1)
```

The takes are in `src/` (left out of the downloads); Rick's lossless copies
of most are in `~/Music/NEON-CASTER/sources/`.

## Changing an arrangement

In the game: SETTINGS > AUDIO > SOUND TEST, MUSIC, pick a track and press
**E** (or `arranger level1` in the console). The MUSIC ARRANGER plays it live
from its take, so you hear a change at once:

- the take across the top, with its bars and clips (click: play from that bar;
  drag a clip's end to move it),
- a pad for each clip: click it (or type its letter) and it starts on the next
  bar and loops - Ctrl+R records what you launch into the arrangement,
- the arrangement as blocks: Ins/Del, Up/Down for repeats, Shift+arrows or a
  drag to move one, Enter or a double-click to play from it,
- Ctrl+S saves `NAME.arr`, Ctrl+E makes `NAME.ogg` from it.

It plays from `edit/NAME.flac`, which isn't in git:

```
~/.venvs/music/bin/python arrange.py --sources          # edit/*.flac, once
```

## From the command line

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

Renoise: the take is one instrument sliced at every bar (bar 1 is C-4), a
pattern per clip, the sequence is the arrangement; clips it doesn't use come
after a CLIPS section, to schedule live. Bitwig: the arrangement on one audio
track with a marker at each clip, and the clip launcher with a scene per clip.
Then `arrange.py --seams NAME` and `--render NAME`.
