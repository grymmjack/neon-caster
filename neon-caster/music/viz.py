"""Writes NAME.viz beside each .ogg track in neon-caster/music/: what the SOUND TEST's player
draws for it (MENU/SOUNDTEST.BM). The game reads a WAV's or FLAC's samples as it plays, but
not an Ogg's (the sound engine keeps those in pages, which _MEMSOUND can't hand over), so
for these it's worked out here, the same way the game does it:

  - the seek bar's waveform: the track mixed to one channel, squeezed to ST_OVW (648)
    columns, each its lowest and highest sample
  - the spectrum, 30 times a second: 2048 samples round that moment, a Hann window, the
    FFT, and ST_BANDS (48) bars spaced as we hear (50 Hz to 16 kHz), each the loudest
    bin in it, in decibels - 72 below full scale is 0, full scale 255

A .viz is zlib-deflated (the game's _INFLATE$) text-and-bytes:
  "NCVIZ 30 48 FRAMES\\n", then 648 x (min, max) signed bytes, then FRAMES x 48 bytes.

Run it after adding or changing a track (needs numpy and ffmpeg):
  ~/ComfyUI/.venv/bin/python viz.py          every track whose .viz is missing or older
  ~/ComfyUI/.venv/bin/python viz.py --all    every track
"""
import os, subprocess, sys, zlib
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
FPS, BANDS, OVW, N, RATE = 30, 48, 648, 2048, 44100


def samples(path):
    raw = subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(RATE),
                          '-f', 'f32le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def viz(path):
    w = samples(path)
    n = len(w)
    # The seek bar: each column's lowest and highest
    ov = bytearray()
    for c in range(OVW):
        a, b = c * n // OVW, max(c * n // OVW + 1, (c + 1) * n // OVW)
        seg = w[a:b]
        lo, hi = min(0.0, seg.min()), max(0.0, seg.max())
        ov += bytes([int(round(max(-1, lo) * 127)) & 255, int(round(min(1, hi) * 127)) & 255])
    # The spectrum, FPS times a second
    frames = int(n / RATE * FPS) + 1
    hann = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(N) / (N - 1))
    hi_f = min(16000.0, RATE * 0.48)
    edges = [50 * (hi_f / 50) ** (b / BANDS) for b in range(BANDS + 1)]
    bins = [(int(edges[b] * N / RATE), max(int(edges[b] * N / RATE), int(edges[b + 1] * N / RATE))) for b in range(BANDS)]
    pad = np.concatenate([np.zeros(N), w, np.zeros(N)])
    sp = bytearray()
    for f in range(frames):
        at = int(f / FPS * RATE)
        win = pad[at + N - N // 2: at + N + N // 2] * hann
        mag = np.abs(np.fft.rfft(win)) * 4 / N
        for i0, i1 in bins:
            lo, hi = max(1, i0), min(N // 2 - 1, i1)
            m = mag[lo:hi + 1].max() if hi >= lo else 0.0
            lv = (20 * np.log10(m) + 72) / 72 if m > 1e-7 else 0.0
            sp.append(int(round(min(1.0, max(0.0, lv)) * 255)))
    data = ('NCVIZ %d %d %d\n' % (FPS, BANDS, frames)).encode() + bytes(ov) + bytes(sp)
    return zlib.compress(data, 9), frames


def main():
    every = '--all' in sys.argv
    for name in sorted(os.listdir(HERE)):
        if not name.endswith('.ogg'):
            continue
        src = os.path.join(HERE, name)
        dst = os.path.join(HERE, name[:-4] + '.viz')
        if not every and os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
            continue
        out, frames = viz(src)
        with open(dst, 'wb') as fh:
            fh.write(out)
        print('%-16s %5d frames  %6d bytes' % (name[:-4] + '.viz', frames, len(out)))


if __name__ == '__main__':
    main()
