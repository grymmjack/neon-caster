"""Frequency analysis of every NEON-CASTER sound and voice line.

For each file: the average spectrum (only frames that aren't silence) in 1/3-octave bands, its
spectral tilt against pink (an even spread: 0 dB/octave in 1/3-octave band power), the share of
energy in each region, and how sharp its sibilant bursts are. Writes JSON for the report.

usage: python analyze.py OUT.json DIR [DIR...]"""
import base64, json, os, subprocess, sys
import numpy as np

SR = 44100
CENTRES = [31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
           2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000]
REGIONS = {'sub': (20, 80), 'low': (80, 250), 'lowmid': (250, 1000), 'mid': (1000, 2500),
           'presence': (2500, 5000), 'sibilance': (5000, 10000), 'air': (10000, 20000)}

def load(path):
    raw = subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR), '-f', 'f32le', '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)

def analyse(x):
    n = 2048; hop = 512
    if len(x) < n: x = np.pad(x, (0, n - len(x)))
    win = np.hanning(n)
    frames = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * win
    spec = np.abs(np.fft.rfft(frames, axis=1)) ** 2
    fr = np.fft.rfftfreq(n, 1 / SR)
    e = spec.sum(axis=1)
    keep = e > e.max() * 10 ** (-40 / 10) # (frames within 40 dB of the loudest)
    mean = spec[keep].mean(axis=0) + 1e-20
    bands = []
    for c in CENTRES:
        lo, hi = c / 2 ** (1 / 6), c * 2 ** (1 / 6)
        bands.append(10 * np.log10(mean[(fr >= lo) & (fr < hi)].sum() + 1e-20))
    bands = np.array(bands)
    tot = mean[(fr >= 20)].sum()
    region = {k: float(mean[(fr >= a) & (fr < b)].sum() / tot) for k, (a, b) in REGIONS.items()}
    # tilt: slope of band level against octave, from 63 Hz to 12.5 kHz, weighted by how much is there
    sel = slice(3, 27); oct_ = np.log2(np.array(CENTRES[sel]) / 1000)
    w = 10 ** ((bands[sel] - bands[sel].max()) / 20) + 0.05
    tilt = float(np.polyfit(oct_, bands[sel], 1, w=w)[0])
    centroid = float((fr * mean).sum() / mean.sum())
    # sibilance bursts: 5-9 kHz short-term energy, peak against its median (only loud frames)
    sib = spec[:, (fr >= 5000) & (fr < 9000)].sum(axis=1)
    sibr = sib[keep] / (e[keep] + 1e-20)
    sib_peak = float(np.percentile(sibr, 95)) if len(sibr) else 0
    harsh = region['presence'] + region['sibilance'] + region['air'] # (share of energy above 2.5 kHz)
    # harsh seconds: frames (within 20 dB of the loudest) with over half their energy above 2.5 kHz
    hfe = spec[:, fr >= 2500].sum(axis=1)
    loud = e > e.max() * 10 ** (-20 / 10)
    harsh_s = float(((hfe / (e + 1e-20) > 0.5) & loud).sum() * hop / SR)
    # spectrogram: 40 ms columns, the 1/3-octave bands 63 Hz - 16 kHz, 0-60 dB below its loudest cell -> 0-255
    step = max(1, int(round(0.04 * SR / hop)))
    rows = []
    for c in CENTRES[3:]:
        lo, hi = c / 2 ** (1 / 6), c * 2 ** (1 / 6)
        rows.append(spec[:, (fr >= lo) & (fr < hi)].sum(axis=1))
    g = np.array(rows) # bands x frames
    pad = (-g.shape[1]) % step
    if pad: g = np.pad(g, ((0, 0), (0, pad)), mode='edge')
    g = g.reshape(len(rows), -1, step).mean(axis=2)[:, :250] # (10 s at most)
    gd = 10 * np.log10(g + 1e-20); gd = np.clip((gd - gd.max() + 60) / 60, 0, 1)
    sg = base64.b64encode((gd * 255).astype(np.uint8).T.tobytes()).decode() # (column by column)
    return dict(harsh_s=round(harsh_s, 2), sg=sg, sgcols=int(gd.shape[1]), bands=[round(float(b - bands.max()), 1) for b in bands], tilt=round(tilt, 2), centroid=round(centroid),
                regions={k: round(v, 4) for k, v in region.items()}, sib=round(sib_peak, 3), harsh=round(harsh, 4),
                seconds=round(len(x) / SR, 2), peak=round(float(20 * np.log10(np.abs(x).max() + 1e-9)), 1))

out = {}
for d in sys.argv[2:]:
    for f in sorted(os.listdir(d)):
        if f.endswith('.wav'):
            out[os.path.join(os.path.basename(d.rstrip('/')), f[:-4])] = analyse(load(os.path.join(d, f)))
json.dump(dict(centres=CENTRES, sounds=out), open(sys.argv[1], 'w'))
print(len(out), 'analysed')
