# Mastering the sounds

How every sound effect (`sfx/`) and voice line (`speech/`) on this branch was mastered, so the game's sounds
sit together without grating when they stack up in a fight.

1. `analyze.py OUT.json DIR...` measures each sound: its spectrum in third-octave bands (only the frames that
   aren't silence), its tilt in dB a octave, its share of energy in seven regions (sub to air), its sibilant
   bursts, its "harsh seconds" (time spent mostly above 2.5 kHz while loud) and a sonogram. Run it on the game's
   files as `before.json`.
2. `master.py` reads `before.json` and writes every sound to `after/` through one chain, each sound's own amounts:
   high-pass 30 Hz; a low shelf at 180 Hz up (body, only where there's low end to lift); a high shelf at 3 kHz
   down, by how far its tilt is above -3 dB/octave; a cut at 3.2 kHz when 2.5-5 kHz dominates; a de-esser when
   its sibilant bursts are sharp; a 12 kHz low-pass (sound effects); then back towards its old loudness (its
   loudest 400 ms), at most +3 dB and never past -1 dBTP - no limiter, so nothing is distorted (and none for a
   sound that was mostly above 10 kHz: it's meant to end up quieter).

Run with a Python that has numpy (`~/ComfyUI/.venv/bin/python`) and ffmpeg. Result: the sound effects' energy
above 2.5 kHz went from 34% to 21%, their harsh seconds from 64 to 40; voices barely change.
