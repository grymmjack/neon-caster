"""Channel vocoder, Cylon style: the voice's spectral envelope (a few dozen
bands) imposed on a buzzing sawtooth carrier, with the old 1978 warble
(a slow pitch wobble and a tremolo), plus a little dry voice for clarity.
    vocoder.py in.wav out.wav [pitch_hz] [dry]"""
import sys, warnings, numpy as np
warnings.filterwarnings('ignore')
from scipy.io import wavfile
from scipy.signal import stft, istft, butter, sosfilt

src, dst = sys.argv[1], sys.argv[2]
f0 = float(sys.argv[3]) if len(sys.argv) > 3 else 85.0
dry = float(sys.argv[4]) if len(sys.argv) > 4 else 0.12
sr, x = wavfile.read(src)
x = x.astype(np.float64)
if x.ndim > 1: x = x.mean(axis=1)
x /= (np.abs(x).max() + 1e-9)
n = len(x); t = np.arange(n) / sr

# the carrier: a sawtooth with a slow wobble in pitch (the Cylon warble), plus
# a whisper of noise for the s and t sounds
wob = f0 * (1 + 0.035 * np.sin(2 * np.pi * 4.2 * t))
phase = np.cumsum(wob) / sr
car = 2 * (phase % 1.0) - 1
car += 0.5 * (2 * ((phase * 2.003) % 1.0) - 1)       # an octave up, slightly off: buzzier
car += 0.15 * np.random.default_rng(1).standard_normal(n)

nper = 1024
_, _, X = stft(x, sr, nperseg=nper, noverlap=nper * 3 // 4)
_, _, C = stft(car, sr, nperseg=nper, noverlap=nper * 3 // 4)
freqs = np.linspace(0, sr / 2, X.shape[0])

# 28 bands, log-spaced 80 Hz - 7 kHz: each band's energy in the voice sets
# that band's level in the carrier
edges = np.geomspace(80, min(7000, sr / 2 - 1), 29)
env = np.zeros_like(np.abs(X)); cenv = np.ones_like(env)
for lo, hi in zip(edges[:-1], edges[1:]):
    m = (freqs >= lo) & (freqs < hi)
    if not m.any(): continue
    env[m] = np.sqrt((np.abs(X[m]) ** 2).mean(axis=0, keepdims=True))
    cenv[m] = np.sqrt((np.abs(C[m]) ** 2).mean(axis=0, keepdims=True)) + 1e-9
Y = C / cenv * env
_, y = istft(Y, sr, nperseg=nper, noverlap=nper * 3 // 4)
y = np.nan_to_num(y[:n])
if len(y) < n: y = np.pad(y, (0, n - len(y)))

# tremolo, then a touch of the dry voice, a high-pass, normalise
y *= 0.82 + 0.18 * np.sin(2 * np.pi * 7.5 * t)
y = y / (np.abs(y).max() + 1e-9) + dry * x
y = sosfilt(butter(2, 90, "hp", fs=sr, output="sos"), y)
y = y / (np.abs(y).max() + 1e-9) * 0.89
wavfile.write(dst, sr, (y * 32767).astype(np.int16))
