#!/usr/bin/env python3
"""NEON-CASTER - music/arrange.py: the music's bars, clips and arrangements.

Every track was made by Stable Audio, which stops at ~47 s - so each one
ends just as it gets going and loops abruptly. This finds each track's
beat and bar grid, cuts it into clips that start and end on bar lines,
finds where playback can jump from one bar to another without the join
being heard (seams), and arranges the clips into 3-4 minutes that loop -
then renders that, at the shipped loudness, as the .ogg the game streams.

    ~/.venvs/music/bin/python arrange.py --analyze [NAME ...]   # write NAME.arr (keeps a hand-edited arrangement: --fresh to redo it)
    ~/.venvs/music/bin/python arrange.py --render  [NAME ...]   # NAME.arr -> NAME.ogg (from the lossless source)
    ~/.venvs/music/bin/python arrange.py --clicks  NAME         # the source with a click on every beat (bar 1s louder) - checking the grid
    ~/.venvs/music/bin/python arrange.py --seams   [NAME ...]   # score every join the .arr's arrangement makes (and each clip looping on itself) into its seams
    ~/.venvs/music/bin/python arrange.py --sources [NAME ...]   # edit/NAME.flac: the source at the shipped loudness, for SOUND TEST's arranger (git-ignored)

(needs librosa, numpy, soundfile, scipy: python3 -m venv ~/.venvs/music &&
~/.venvs/music/bin/pip install librosa soundfile numpy scipy matplotlib)

Sources, best first: ~/Music/NEON-CASTER/sources/NAME.wav (the lossless
take, turned down by its shipped gain - README.md there), music/src/NAME.*
(the originals kept when the arranged .ogg replaced them), then the .ogg
or .flac in this folder.

NAME.arr is plain text, and meant to be edited (by hand, by the SOUND TEST's
editor, or read back from Renoise / Bitwig):

    bpm 128.003   offset 0.212   bars 24   tail 23   ; bar 1 starts at offset seconds; bars from tail on are the fade
    clip A  bars 1-4    intro
    clip B  bars 5-12   groove
    arrange A B*2 C D B*3
    seam 12 5 0.93      ; after bar 12, bar 5 can follow (how alike: 0-1) - the analysis's, for the editors

A clip repeated (B*2) plays its bars again; a clip followed by one that
doesn't start on the bar after it jumps - at a bar line, with a short
equal-power crossfade. The file loops as a whole, so the arrangement's
last clip leads back into its first.
"""
import os, re, sys, glob, math
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LOSSLESS = os.path.expanduser("~/Music/NEON-CASTER/sources")
SR = 44100


def tracks():
    """Every track's name: the .ogg and .flac files here (and music/src/ originals)."""
    names = set()
    for pat in ("*.ogg", "*.flac", "src/*.ogg", "src/*.flac"):
        for f in glob.glob(os.path.join(HERE, pat)):
            names.add(os.path.splitext(os.path.basename(f))[0])
    def key(n):
        m = re.match(r"([a-z]+)(\d*)$", n)
        return (m.group(1), int(m.group(2) or 0)) if m else (n, 0)
    return sorted(names, key=key)


def shipped_gains():
    """The dB each lossless take was turned down by in the game (~/Music/NEON-CASTER/README.md's table)."""
    g = {}
    readme = os.path.join(os.path.dirname(LOSSLESS), "README.md")
    if os.path.exists(readme):
        for line in open(readme, encoding="utf-8"):
            m = re.match(r"\|\s*`([a-z0-9]+)\.wav`\s*\|.*\|\s*([+-]?[0-9.]+) dB\s*\|", line)
            if m:
                g[m.group(1)] = float(m.group(2))
    return g


def source_path(name):
    """(path, gain dB, lossless?) - the best copy of a track there is."""
    w = os.path.join(LOSSLESS, name + ".wav")
    if os.path.exists(w):
        return w, shipped_gains().get(name, 0.0), True
    for d in ("src", ""):
        for ext in (".flac", ".wav", ".ogg"):
            p = os.path.join(HERE, d, name + ext)
            if os.path.exists(p):
                return p, 0.0, ext != ".ogg"
    raise FileNotFoundError(name)


def load(name, gain=True):
    """A track's samples: float32, (n, 2), 44.1 kHz - at the shipped loudness if gain."""
    import soundfile as sf
    path, g, _ = source_path(name)
    y, sr = sf.read(path, dtype="float32", always_2d=True)
    if y.shape[1] == 1:
        y = np.repeat(y, 2, axis=1)
    y = y[:, :2]
    if sr != SR:
        import librosa
        y = librosa.resample(y.T, orig_sr=sr, target_sr=SR).T.astype(np.float32)
    if gain and g:
        y = y * np.float32(10 ** (g / 20))
    return y


# --- THE GRID ---------------------------------------------------------------
HOP = 256          # analysis hop at 22050 Hz: 11.6 ms
ASR = 22050


def onset_env(mono22):
    """Onset strength (all bands) and the lows' (the kick and bass, under 200 Hz)."""
    import librosa
    S = np.abs(librosa.stft(mono22, n_fft=2048, hop_length=HOP))
    M = librosa.feature.melspectrogram(S=S ** 2, sr=ASR, n_mels=64)
    L = librosa.power_to_db(M)
    full = librosa.onset.onset_strength(S=L, sr=ASR, hop_length=HOP)
    lowbins = librosa.mel_frequencies(n_mels=64, fmax=ASR / 2) < 200
    low = librosa.onset.onset_strength(S=L[lowbins], sr=ASR, hop_length=HOP)
    return full, low, S


def grid_score(env, period, phase, n):
    """How much onset falls on a grid (period, phase in seconds): the envelope at each beat, interpolated."""
    t = phase + period * np.arange(n)
    f = t * ASR / HOP
    f = f[f < len(env) - 1]
    i = f.astype(int); w = f - i
    return float(np.mean(env[i] * (1 - w) + env[i + 1] * w))


def find_grid(y, center=None):
    """The beat grid: (bpm, first beat's time, beats in the track, drift ms, fit) - a straight
    grid fitted to the onsets (Stable Audio keeps a steady tempo), then refined on them."""
    import librosa
    mono = librosa.resample(y.mean(axis=1), orig_sr=SR, target_sr=ASR)
    full, low, S = onset_env(mono)
    env = full / (full.max() + 1e-9) + low / (low.max() + 1e-9)
    tempo, beats = librosa.beat.beat_track(onset_envelope=env, sr=ASR, hop_length=HOP, start_bpm=126, tightness=100, units="time")
    tempo = float(np.atleast_1d(tempo)[0])
    if center: tempo = center
    while tempo < 85: tempo *= 2
    while tempo > 175: tempo /= 2
    dur = len(mono) / ASR
    best = None
    # refine: periods within 1.5% of the tracker's, every phase - the grid the onsets sit on most
    for bpm in np.arange(tempo * 0.985, tempo * 1.015, 0.01):
        p = 60.0 / bpm
        n = int(dur / p) + 1
        for ph in np.arange(0, p, 0.002):
            s = grid_score(env, p, ph, n)
            if best is None or s > best[0]:
                best = (s, bpm, ph)
    s, bpm, ph = best
    # a round tempo (or a half) that fits as well is the one it was made at: snap to it
    for r in sorted({round(bpm), round(bpm * 2) / 2}, key=lambda r: abs(r - bpm)):
        if abs(r - bpm) > 0.2: continue
        p = 60.0 / r
        n = int(dur / p) + 1
        sb = max((grid_score(env, p, x, n), x) for x in np.arange(max(0, ph - 0.03), ph + 0.03, 0.001))
        if sb[0] >= s * 0.995:
            bpm, ph = r, sb[1]
            break
    p = 60.0 / bpm
    # drift: the best phase for the first half and for the second, on this period (ms apart) -
    # large if the tempo wanders and a straight grid won't do
    n2 = int((dur - ph) / p) // 2
    def bestph(t0):
        return max((grid_score(env, p, t0 + x, n2), x) for x in np.arange(-0.05, 0.05, 0.001))[1]
    drift = abs(bestph(ph + n2 * p) - bestph(ph)) * 1000
    return dict(bpm=float(bpm), phase=float(ph), period=p, n=int((dur - ph) / p), drift=drift, env=env, low=low / (low.max() + 1e-9), mono=mono, S=S)


def beat_features(g):
    """Each beat's sound: MFCC (timbre), chroma (notes), loudness - as columns, for the downbeat and the seams."""
    import librosa
    mono, S = g["mono"], g["S"]
    frames = librosa.time_to_frames(g["phase"] + g["period"] * np.arange(g["n"] + 1), sr=ASR, hop_length=HOP)
    frames = np.clip(frames, 0, S.shape[1] - 1)
    mf = librosa.feature.mfcc(S=librosa.power_to_db(librosa.feature.melspectrogram(S=S ** 2, sr=ASR, n_mels=64)), n_mfcc=14)
    ch = librosa.feature.chroma_stft(S=S ** 2, sr=ASR)
    rms = librosa.feature.rms(S=S)
    out = []
    for a, b in zip(frames[:-1], frames[1:]):
        b = max(b, a + 1)
        out.append(np.concatenate([mf[1:, a:b].mean(axis=1) / 40.0, ch[:, a:b].mean(axis=1), [np.log10(rms[0, a:b].mean() + 1e-6)]]))
    return np.array(out)


def find_downbeat(g, F):
    """Which of every four beats is bar 1: where the sound changes most (new parts come in on the
    bar, and more on the 4- and 8-bar phrase), plus where the lows hit hardest."""
    d = np.r_[0, np.linalg.norm(np.diff(F, axis=0), axis=1)]
    d = d / (d.mean() + 1e-9)
    t = g["phase"] + g["period"] * np.arange(len(d))
    lowat = np.interp(t * ASR / HOP, np.arange(len(g["low"])), g["low"])
    lowat = lowat / (lowat.mean() + 1e-9)
    best = None
    for p in range(4):
        idx = np.arange(p, len(d), 4)
        s = d[idx].mean() + 0.25 * lowat[idx].mean()
        # phrase changes: every 4th bar's start counted again
        s += 0.25 * d[np.arange(p, len(d), 16)].mean() if len(d) > p + 16 else 0
        # Stable Audio starts its tracks on bar 1: a grid starting at once leans that way
        if p == 0 and g["phase"] < 0.1: s += 0.15
        if best is None or s > best[0]:
            best = (s, p)
    return best[1]


_BT = None
def beat_this_beats(y):
    """beat_this's (CPJKU, 2024 - a trained beat and downbeat tracker) beats and downbeats, if it's installed."""
    global _BT
    try:
        if _BT is None:
            from beat_this.inference import Audio2Beats
            _BT = Audio2Beats(checkpoint_path="final0", device="cpu", dbn=False)
        b, d = _BT(y.mean(axis=1), SR)
        return np.asarray(b), np.asarray(d)
    except Exception:
        return np.array([]), np.array([])


def attack_phase(y, period, phase):
    """The grid moved onto the beats' attacks: where the kick (under 150 Hz) starts to rise, a few
    ms before - so a cut on a bar line lands just ahead of the hit, never in it."""
    from scipy.signal import butter, sosfilt
    lo = sosfilt(butter(4, 150, "low", fs=SR, output="sos"), y.mean(axis=1))
    e = np.convolve(lo ** 2, np.ones(44) / 44, "same")
    offs = []
    for k in range(int((len(y) / SR - phase) / period)):
        i = int((phase + k * period) * SR)
        w0, w1 = i - int(0.06 * SR), i + int(0.04 * SR)
        if w0 < 0 or w1 >= len(e): continue
        seg = e[w0:w1]
        pk = int(np.argmax(seg))
        if seg[pk] < 1e-6: continue
        mn = int(np.argmin(seg[:pk + 1]))
        rise = np.nonzero(seg[mn:pk + 1] > seg[mn] + 0.15 * (seg[pk] - seg[mn]))[0]
        if len(rise): offs.append((w0 + mn + rise[0] - i) / SR)
    if len(offs) < 8: return phase, None
    offs = np.array(offs)
    spread = float(np.percentile(offs, 75) - np.percentile(offs, 25))
    if spread > 0.025: return phase, spread   # no steady kick to line up on
    return phase + float(np.median(offs)) - 0.004, spread


def analyze_grid(name, y=None):
    if y is None:
        y = load(name)
    g = find_grid(y)
    # a second opinion: beat_this. Where its beats are steady and its tempo isn't ours (a third or a
    # half off: triplet feels, half-time), its tempo is the better start - kept to 100-175
    b, d = beat_this_beats(y)
    btok = False
    if len(b) >= 16:
        k = np.arange(len(b))
        pfit, t0 = np.polyfit(k, b, 1)
        resid = np.median(np.abs(b - (t0 + k * pfit)))
        btok = resid < 0.015
        if btok:
            bt = 60 / pfit
            while bt < 100: bt *= 2
            while bt > 175: bt /= 2
            if abs(bt / g["bpm"] - 1) > 0.03:
                g = find_grid(y, center=bt)
                g["tempo_from"] = "beat_this"
    ph, spread = attack_phase(y, g["period"], g["phase"])
    g["attack_spread"] = spread
    while ph < 0: ph += g["period"]
    g["phase"] = ph
    g["n"] = int((len(y) / SR - ph) / g["period"])
    F = beat_features(g)
    db = find_downbeat(g, F)
    g["downbeat_from"] = "sound"
    # bar 1: beat_this's downbeats, where they keep to one beat of our bar
    if btok and len(d) >= 4:
        pos = np.round((d - ph) / g["period"]).astype(int) % 4
        mode = int(np.bincount(pos, minlength=4).argmax())
        if np.mean(pos == mode) >= 0.6:
            db = mode
            g["downbeat_from"] = "beat_this"
    off = ph + db * g["period"]
    bar = 4 * g["period"]
    if off - bar > -0.01:  # a whole bar before it: that's bar 1
        off -= bar * int((off + 0.01) / bar)
    nbars = int((len(y) / SR - off) / bar + 1e-6)
    g.update(downbeat=db, offset=off, bar=bar, nbars=nbars, F=F)
    return g


def click_track(name, out):
    """The source with a click on every beat (bar 1s higher and louder): for checking the grid by ear."""
    import soundfile as sf
    y = load(name)
    g = analyze_grid(name, y)
    t = np.arange(int(0.03 * SR)) / SR
    for k in range(-4, g["nbars"] * 4 + 4):
        tt = g["offset"] + k * g["period"]
        if tt < 0: continue
        i = int(tt * SR)
        if i + len(t) >= len(y): break
        f, a = (1760, 0.5) if k % 4 == 0 else (880, 0.3)
        c = (a * np.sin(2 * np.pi * f * t) * np.exp(-t * 120)).astype(np.float32)
        y[i:i + len(t)] += c[:, None]
    sf.write(out, np.clip(y, -1, 1), SR)
    return g


# --- BARS: WHAT EACH SOUNDS LIKE, WHERE IT CAN JUMP, THE SECTIONS ----------
def bar_features(y, g):
    """Per bar: loudness (dB), lows' share, brightness (centroid Hz), onsets a beat, and a
    vector for comparing bars (its four beats' timbre and notes)."""
    import librosa
    mono = g["mono"]
    out = []
    F = g["F"]                      # beats from g["phase"]
    first = g["downbeat"]           # beat index of bar 1
    oenv = g["env"]
    peaks = librosa.util.peak_pick(oenv, pre_max=3, post_max=3, pre_avg=10, post_avg=10, delta=0.15, wait=6)
    ptimes = peaks * HOP / ASR
    for i in range(g["nbars"]):
        t0 = g["offset"] + i * g["bar"]; t1 = t0 + g["bar"]
        a, b = int(max(t0, 0) * ASR), int(t1 * ASR)
        seg = mono[a:b]
        rms = float(np.sqrt(np.mean(seg ** 2)) + 1e-9)
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))) ** 2
        fr = np.fft.rfftfreq(len(seg), 1 / ASR)
        low = float(spec[fr < 150].sum() / (spec.sum() + 1e-12))
        cen = float((spec * fr).sum() / (spec.sum() + 1e-12))
        half = len(seg) // 2
        r1 = np.sqrt(np.mean(seg[:half] ** 2)) + 1e-9; r2 = np.sqrt(np.mean(seg[half:] ** 2)) + 1e-9
        ons = int(np.sum((ptimes >= t0) & (ptimes < t1)))
        bi = first + 4 * i
        vec = F[bi:bi + 4].reshape(-1) if bi + 4 <= len(F) else np.concatenate([F[bi:], np.zeros((bi + 4 - len(F), F.shape[1]))]).reshape(-1)
        out.append(dict(db=20 * np.log10(rms), low=low, cen=cen, ons=ons / 4.0, fall=float(20 * np.log10(r2 / r1)), vec=vec))
    return out


def bar_similarity(bars):
    """How alike every two bars are, 0-1 (1: the same), from their beats' timbre, notes and loudness."""
    V = np.array([b["vec"] for b in bars])
    V = (V - V.mean(axis=0)) / (V.std(axis=0) + 1e-6)
    D = np.sqrt(((V[:, None, :] - V[None, :, :]) ** 2).mean(axis=2))
    off = D[~np.eye(len(D), dtype=bool)]
    sig = np.median(off) + 1e-6
    S = np.exp(-(D / sig) ** 2)
    # 1 = as alike as the most alike tenth of its pairs (a loop's repeats), not just identical
    base = np.percentile(S[~np.eye(len(S), dtype=bool)], 90) + 1e-6
    return np.minimum(1.0, S / base)


def find_tail(bars):
    """The first bar of the ending (a fade, a last hit dying away), or len(bars) if it doesn't end."""
    if not bars: return 0
    loud = np.array([b["db"] for b in bars])
    top = np.percentile(loud, 75)
    t = len(bars)
    for i in range(len(bars) - 1, max(len(bars) // 2, 0), -1):
        b = bars[i]
        if b["db"] < top - 8 or b["fall"] < -6 or (i == len(bars) - 1 and b["fall"] < -3):
            t = i
        else:
            break
    return t


def find_seams(S, tail, pickup_sim=None, keep=6, floor=0.35):
    """Where playback can jump: after bar i, bar j (0-based) - good when bar i sounds like the bar
    before j, and the bar after i like j. A dict {(i, j): score}, the best few for each i."""
    n = tail
    seams = {}
    for i in range(n):
        cand = []
        for j in range(n):
            if j == i + 1: continue
            before = S[i, j - 1] if j >= 1 else (pickup_sim[i] if pickup_sim is not None else 0.0)
            after = S[i + 1, j] if i + 1 < n else S[i, j]
            sc = float(np.sqrt(max(before, 0) * max(after, 0)))
            if sc >= floor: cand.append((sc, j))
        for sc, j in sorted(cand, reverse=True)[:keep]:
            seams[(i, j)] = sc
    return seams


def find_sections(S, bars, tail):
    """Sections where the sound changes (Foote's novelty on the bar self-similarity), on 4- or
    2-bar lines where it can - as [(first bar, last bar)], 0-based, up to the tail."""
    n = tail
    if n <= 4: return [(0, n - 1)], np.zeros(n + 1)
    w = 2
    K = np.kron(np.array([[1, -1], [-1, 1]]), np.ones((w, w)))
    Sp = np.pad(S[:n, :n], w, mode="edge")
    nov = np.array([max(0.0, float((Sp[i:i + 2 * w, i:i + 2 * w] * K).sum())) for i in range(n + 1)])
    loud = np.array([b["db"] for b in bars[:n]])
    for i in range(1, n):                       # a jump in loudness is a change too
        nov[i] += 0.15 * abs(loud[i] - loud[i - 1])
    nov[0] = nov[n] = 0
    weight = np.array([1.6 if i % 8 == 0 else 1.35 if i % 4 == 0 else 1.1 if i % 2 == 0 else 0.8 for i in range(n + 1)])
    cand = sorted(range(1, n), key=lambda i: -nov[i] * weight[i])
    want = max(2, int(round(n / 6)))
    top = max(nov * weight)
    cuts = []
    for i in cand:
        if len(cuts) >= want - 1: break
        if nov[i] * weight[i] < 0.5 * top: break
        # sections of 4 bars or more (2 where the change is as strong as the strongest)
        gap = 2 if nov[i] * weight[i] > 0.85 * top else 4
        if all(abs(i - c) >= gap for c in cuts) and i >= gap and n - i >= gap:
            cuts.append(i)
    cuts = sorted(cuts)
    edges = [0] + cuts + [n]
    return [(edges[k], edges[k + 1] - 1) for k in range(len(edges) - 1)], nov


def section_kinds(secs, bars):
    """intro / build / groove / break / peak for each section, by its loudness and busyness."""
    loud = np.array([np.mean([bars[i]["db"] for i in range(a, b + 1)]) for a, b in secs])
    busy = np.array([np.mean([bars[i]["ons"] for i in range(a, b + 1)]) for a, b in secs])
    e = (loud - loud.mean()) / (loud.std() + 1e-6) + 0.5 * (busy - busy.mean()) / (busy.std() + 1e-6)
    kinds = []
    for k, (a, b) in enumerate(secs):
        if k == 0 and e[k] < 0: kinds.append("intro")
        elif e[k] > 0.8: kinds.append("peak")
        elif e[k] >= -0.2: kinds.append("groove")
        elif k + 1 < len(secs) and e[k + 1] > e[k] + 0.5: kinds.append("build")
        else: kinds.append("break")
    return kinds, e


# --- NAME.arr ---------------------------------------------------------------
CLIP_NAMES = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def arr_path(name):
    return os.path.join(HERE, name + ".arr")


def write_arr(name, A):
    """A: bpm, offset, bars, tail, clips [(name, first, last, kind)] 1-based, arrange [(clip, times)],
    auto, seams {(i, j): score} 1-based, source."""
    L = ["; NEON-CASTER - %s's bars, clips and arrangement (music/arrange.py; bars count from 1)" % name,
         "; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)",
         "bpm %.3f   offset %.4f   bars %d   tail %d" % (A["bpm"], A["offset"], A["bars"], A["tail"]),
         "source %s" % A.get("source", ""),
         "auto %s          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours" % ("yes" if A.get("auto", True) else "no")]
    for c, a, b, kind in A["clips"]:
        L.append("clip %-2s bars %d-%d%s%s" % (c, a, b, " " * max(1, 8 - len("%d-%d" % (a, b))), kind))
    L.append("arrange " + " ".join(c if t == 1 else "%s*%d" % (c, t) for c, t in A["arrange"]))
    for (i, j), sc in sorted(A.get("seams", {}).items()):
        L.append("seam %d %d %.2f" % (i, j, sc))
    open(arr_path(name), "w").write("\n".join(L) + "\n")


def read_arr(name):
    A = dict(clips=[], arrange=[], seams={}, auto=True, source="")
    for line in open(arr_path(name), encoding="utf-8"):
        line = line.split(";")[0].strip()
        if not line: continue
        w = line.split()
        if w[0] == "bpm":
            kv = dict(zip(w[0::2], w[1::2]))
            A.update(bpm=float(kv["bpm"]), offset=float(kv["offset"]), bars=int(kv["bars"]), tail=int(kv.get("tail", kv["bars"])))
        elif w[0] == "source": A["source"] = " ".join(w[1:])
        elif w[0] == "auto": A["auto"] = w[1].lower() == "yes"
        elif w[0] == "clip":
            a, b = w[3].split("-")
            A["clips"].append((w[1], int(a), int(b), w[4] if len(w) > 4 else ""))
        elif w[0] == "arrange":
            for t in w[1:]:
                c, _, n = t.partition("*")
                A["arrange"].append((c, int(n) if n else 1))
        elif w[0] == "seam":
            A["seams"][(int(w[1]), int(w[2]))] = float(w[3])
    return A


def analyze(name, fresh=False):
    """Everything about a track, and its .arr written (clips and arrangement left alone if
    it's been edited: auto no) - returns (the .arr's dict, the analysis)."""
    y = load(name)
    g = analyze_grid(name, y)
    bars = bar_features(y, g)
    S = bar_similarity(bars)
    tail = find_tail(bars)
    # the pickup (anything before bar 1) as a 'bar 0', for jumps back to bar 1
    seams = find_seams(S, tail)
    secs, nov = find_sections(S, bars, tail)
    cuts = [a for a, b in secs[1:]]
    secs = split_sections(secs)
    kinds, energy = section_kinds(secs, bars)
    path, gain, lossless = source_path(name)
    A = dict(bpm=g["bpm"], offset=g["offset"], bars=g["nbars"], tail=tail + 1 if tail < g["nbars"] else g["nbars"] + 1,
             source="%s%s" % (os.path.basename(path), "" if lossless else " (lossy)"),
             clips=[(CLIP_NAMES[k], a + 1, b + 1, kinds[k]) for k, (a, b) in enumerate(secs)],
             seams={(i + 1, j + 1): sc for (i, j), sc in seams.items()}, auto=True)
    info = dict(g=g, bars=bars, S=S, nov=nov, cuts=cuts, secs=secs, kinds=kinds, energy=energy, tailbar=tail)
    old = None
    if os.path.exists(arr_path(name)) and not fresh:
        old = read_arr(name)
        if not old["auto"]:
            A["clips"], A["arrange"], A["auto"] = old["clips"], old["arrange"], False
            write_arr(name, A)
            return A, info
    A["clips"], A["arrange"] = runs_to_clips(A, auto_arrange(A, info))
    for b, na, sc in arrangement_joins(A, S):      # every jump it makes, scored in the file (the renderer reads them)
        if na != b + 1: A["seams"][(b, na)] = sc
    write_arr(name, A)
    return A, info


def split_sections(secs):
    """Clips the arranger can use: a section longer than 8 bars cut into 8s (then a 4-7 left
    over); 1-3 bars left over at a section's end aren't a clip (a phrase cut short) - but a
    short first section (bars before the music proper) stays."""
    out = []
    for k, (a, b) in enumerate(secs):
        L = b - a + 1
        if L <= 8:
            if L >= 4 or k == 0 or len(secs) == 1: out.append((a, b))
            continue
        x = a
        while b - x + 1 >= 4:
            n = 8 if b - x + 1 >= 8 else 4 * ((b - x + 1) // 4) if b - x + 1 < 8 else 8
            n = min(b - x + 1, 8) if b - x + 1 >= 8 else b - x + 1 if b - x + 1 >= 4 else 0
            if n == 0: break
            out.append((x, x + n - 1)); x += n
    return out


def trans_score(S, li, fj):
    """How well clip-ending-at-bar li leads into clip-starting-at-bar fj (0-based): 1 when it's
    the bar that followed anyway; else how alike the bars round the join are."""
    if fj == li + 1: return 1.0
    nb = len(S)
    v = []
    if fj >= 1: v.append(S[li, fj - 1])
    if li + 1 < nb: v.append(S[li + 1, fj])
    if not v: return 0.3
    return float(np.exp(np.mean(np.log(np.maximum(v, 1e-3)))))


def target_energy(f):
    """The shape of a cycle, 0-1 along it -> how lively (-1 the quietest clip, 1 the busiest): in
    from a lull, up, a long high, down to a lull, up again to the peak, easing back to the start."""
    pts = [(0, -1), (0.08, -1), (0.18, 0.2), (0.2, 0.7), (0.42, 0.7), (0.5, 0.1), (0.52, -0.7), (0.6, -0.7),
           (0.68, 0.5), (0.7, 1), (0.92, 1), (0.97, 0), (1, -0.5)]
    xs, ys = zip(*pts)
    return float(np.interp(f, xs, ys))


def jump_score(S, i, j, tail):
    """Bar i (0-based) followed by bar j instead of the bar after it: how alike the bars round the
    join are - bar i against the bar before j, the bar after i against j (when that isn't the
    fade). 1 = as alike as a loop's repeats."""
    v = []
    if j >= 1: v.append(S[i, j - 1])
    if i + 1 < tail: v.append(S[i + 1, j])
    if not v: return 0.3
    return float(np.exp(np.mean(np.log(np.maximum(v, 1e-3)))))


def bar_energy(bars, tail):
    """Each bar's liveliness, -1 (the quietest) to 1 (the busiest)."""
    d = np.array([b["db"] for b in bars[:tail]]); o = np.array([b["ons"] for b in bars[:tail]])
    e = (d - d.mean()) / (d.std() + 1e-6) + 0.5 * (o - o.mean()) / (o.std() + 1e-6)
    if tail < 2: return np.zeros(tail)
    rank = np.argsort(np.argsort(e)) / (tail - 1) * 2 - 1
    sc = (e - e.min()) / (e.max() - e.min() + 1e-9) * 2 - 1
    return 0.5 * rank + 0.5 * sc


def auto_arrange(A, info, seconds=210, beam=400):
    """A 3-4 minute cycle as a walk through the bars (Infinite Jukebox, by the bar): on to the next
    bar, or - after 4 bars at least - a jump where the bars match (keeping the 4-bar phrase),
    following the target_energy shape (lulls and builds), using every part, the last bar leading
    back into bar 1. The runs it plays become clips (the sections' own names where they match)."""
    S = info["S"]
    tail = A["tail"] - 1 if A["tail"] <= A["bars"] else A["bars"]
    tail = max(1, min(tail, len(S)))
    barsec = 240.0 / A["bpm"]
    T = int(round(seconds / barsec))
    lo, hi = int(185 / barsec), int(240 / barsec)
    er = bar_energy(info["bars"], tail)
    # 4-bar phrases: where the sound changes most often on one of every four bar lines
    nov = np.asarray(info["nov"])
    # (the sections' own lines, found leaning to every 8th bar from bar 1, say which: the commonest
    # place in four among them - bar 1's when they don't agree)
    cnt = np.bincount([c % 4 for c in info.get("cuts", [])], minlength=4)
    sh = int(np.argmax(cnt)) if cnt.max() > cnt[0] else 0
    starts = [j for j in range(tail) if (j - sh) % 4 == 0]
    info["phrase_shift"] = sh
    jumps = {}
    for i in range(tail):
        jumps[i] = []
        if (i + 1 - sh) % 4: continue            # only from a phrase's last bar...
        c = []
        for j in starts:                         # ...to a phrase's first
            if j == i + 1: continue
            sc = jump_score(S, i, j, tail)
            if sc >= 0.5: c.append((sc, j))
        jumps[i] = [(j, sc, 0) for sc, j in sorted(c, reverse=True)[:8]]
    WT, WE, WP, WJ, WB = 4.0, 0.12, 0.06, 0.5, 0.22

    def search(s0):
        """The best cycle starting on bar s0: (score, path) - a beam search, a step a bar."""
        # a state: (score, path, plays, jumpuses)
        states = [((1.5 if s0 == 0 else 0.0) - WE * 4 * abs(er[s0] + 1), (s0,), {s0: 1}, {})]
        done = []
        for step in range(hi):
            nxt = []
            for score, path, plays, ju in states:
                i = path[-1]; pos = len(path)
                opts = []
                if i + 1 < tail: opts.append((i + 1, 0.0, None))
                for j, sc, pen in jumps[i]:
                    opts.append((j, WT * np.log(sc) - pen - WJ * ju.get((i, j), 0) ** 1.3, (i, j)))
                for j, add, jk in opts:
                    # (WB a bar: what a bar costs on average, so a longer cycle isn't worse for it)
                    s2 = score + add + WB - WE * abs(er[j] - target_energy(pos / T)) - WP * max(0.0, plays.get(j, 0) - pos / tail)
                    p2 = dict(plays); p2[j] = p2.get(j, 0) + 1
                    j2 = ju
                    if jk: j2 = dict(ju); j2[jk] = j2.get(jk, 0) + 1
                    st = (s2, path + (j,), p2, j2)
                    nxt.append(st)
                    n = len(st[1])
                    if n >= lo and (j + 1 - sh) % 4 == 0:
                        close = 1.0 if j + 1 == s0 else jump_score(S, j, s0, tail)
                        unused = tail - len(p2)
                        done.append((s2 + WT * 3.0 * np.log(max(close, 0.02)) - 0.3 * unused - 0.4 * abs(n - T), st[1], close))
            if not nxt: break
            nxt.sort(key=lambda t: -t[0])
            keep, seen = [], {}
            for st in nxt:   # not all from one path: at most 25 states on any one bar
                key = st[1][-1]
                if seen.get(key, 0) >= 25: continue
                seen[key] = seen.get(key, 0) + 1
                keep.append(st)
                if len(keep) >= beam: break
            states = keep
        if done:
            if os.environ.get("ARR_DEBUG"):
                bn = {}
                for d in done: bn[len(d[1])] = max(bn.get(len(d[1]), -1e9), d[0])
                print(s0, sorted((k, round(v, 1)) for k, v in bn.items()))
            return max(done, key=lambda t: t[0])
        if states:
            b = max(states, key=lambda t: t[0]); return (b[0] - 1e6, b[1], 0)   # (no cycle closes: last resort)
        return (-1e9, tuple(range(s0, tail)), 0)

    # every phrase start (bar 1 favoured), each searched on its own - one start's paths would
    # crowd the others out of a shared beam
    cand = [0] + [j for j in starts if j > 0][:9]
    res = [search(s0) for s0 in cand if s0 < tail]
    info["starts"] = [(r[1][0] + 1, round(r[0], 1), len(r[1]), round(r[2], 2)) for r in res]
    best = max(res, key=lambda t: t[0])
    path = best[1]
    info["loop_close"] = best[2]
    # the walk as runs of bars
    runs = []
    a = path[0]
    for q in range(1, len(path) + 1):
        if q == len(path) or path[q] != path[q - 1] + 1:
            runs.append((a + 1, path[q - 1] + 1))
            if q < len(path): a = path[q]
    return runs


def runs_to_clips(A, runs):
    """Name the runs: a section's own name where a run is exactly it, else a new clip (named on
    from the sections' letters, its kind the section it starts in). Repeats run together (C*3)."""
    clips = list(A["clips"])
    names = {(a, b): c for c, a, b, k in clips}
    def kind_at(bar):
        for c, a, b, k in A["clips"]:
            if a <= bar <= b: return k
        return ""
    seq = []
    for a, b in runs:
        if (a, b) not in names:
            c = CLIP_NAMES[len(clips)] if len(clips) < 26 else "Z%d" % len(clips)
            clips.append((c, a, b, kind_at(a))); names[(a, b)] = c
        c = names[(a, b)]
        if seq and seq[-1][0] == c: seq[-1] = (c, seq[-1][1] + 1)
        else: seq.append((c, 1))
    return clips, seq


def arrangement_joins(A, S):
    """Every join in the arrangement (the loop back to the start included): [(from bar, to bar, score)], 1-based."""
    cl = {c: (a, b) for c, a, b, k in A["clips"]}
    seq = []
    for c, r in A["arrange"]:
        seq += [cl[c]] * r
    out = []
    for q in range(len(seq)):
        a, b = seq[q]; na, nb = seq[(q + 1) % len(seq)]
        out.append((b, na, 1.0 if na == b + 1 else jump_score(S, b - 1, na - 1, A["tail"] - 1)))
    return out


# --- RENDERING --------------------------------------------------------------
def bar_sample(A, k):
    """Where bar k (1-based) starts, in samples."""
    return int(round((A["offset"] + (k - 1) * 240.0 / A["bpm"]) * SR))


def xfade_len(score):
    """A jump's crossfade, by how alike the bars are: 8 ms when they're near the same, up to a
    quarter of a beat when they aren't (heard as a blend, not a cut). In samples."""
    if score >= 0.8: ms = 15
    elif score >= 0.6: ms = 30
    elif score >= 0.45: ms = 60
    else: ms = 120
    return int(ms * SR / 1000)


def piece(y, a, b):
    """y[a:b], with silence where it runs off either end."""
    n = b - a
    out = np.zeros((n, y.shape[1]), dtype=np.float32)
    s0, s1 = max(a, 0), min(b, len(y))
    if s1 > s0: out[s0 - a:s1 - a] = y[s0:s1]
    return out


_HPF = None
def hf(sig, at, w=0.003):
    """The high end (over 6 kHz) round sample at: RMS over +-w seconds - where a click shows."""
    global _HPF
    from scipy.signal import butter, sosfilt
    if _HPF is None: _HPF = butter(4, 6000, "high", fs=SR, output="sos")
    n = int(w * SR)
    seg = sig[max(at - n, 0):at + n].mean(axis=1)
    return float(np.sqrt(np.mean(sosfilt(_HPF, seg) ** 2)) + 1e-9)


def xfade(a, b):
    """a fading out as b fades in: equal power when they're unalike (keeps the level), equal gain
    when they're alike (equal power would add up to 3 dB there)."""
    X = len(a)
    t = np.linspace(0, 1, X, dtype=np.float32)[:, None]
    ma, mb = a.mean(axis=1), b.mean(axis=1)
    rho = float(np.dot(ma, mb) / (np.linalg.norm(ma) * np.linalg.norm(mb) + 1e-9))
    if rho > 0.3:
        return a * (1 - t) + b * t
    return a * np.cos(t * np.pi / 2) + b * np.sin(t * np.pi / 2)


def render(name, A=None, y=None, S=None):
    """The arrangement as audio: (samples, joins [(sample, score)]). Natural joins run on; a
    jump crossfades (equal power) over the stretch just before the bar line, so the new bar's
    hit is never blurred; the end crossfades into the start, so the file loops without a seam."""
    if A is None: A = read_arr(name)
    if y is None: y = load(name)
    cl = {c: (a, b) for c, a, b, k in A["clips"]}
    seq = []
    for c, r in A["arrange"]:
        seq += [cl[c]] * r
    tail = A["tail"] - 1
    def score(b, na):
        if na == b + 1: return 1.0
        if S is not None: return jump_score(S, b - 1, na - 1, tail)
        return A["seams"].get((b, na), 0.4)
    # each run of bars played straight through, as (from sample, to sample)
    spans = []
    for a, b in seq:
        s0, s1 = bar_sample(A, a), bar_sample(A, b + 1)
        if spans and a == spans[-1][2] + 1:
            spans[-1] = (spans[-1][0], s1, b, spans[-1][3])
        else:
            spans.append((s0, s1, b, a))
    out = []
    joins = []
    ins = []
    pos = 0
    lines = [bar_sample(A, k) for k in range(2, A["tail"])]
    linesref = float(np.median([hf(y, s) for s in lines if 0 < s < len(y)] or [1e-9]))
    for q, (s0, s1, lastbar, firstbar) in enumerate(spans):
        seg = piece(y, s0, s1)
        if q > 0:
            prev_last = spans[q - 1][2]
            sc = score(prev_last, firstbar)
            # the outgoing's last X samples, against the incoming's X samples before its bar line -
            # the shortest fade (from the score's on, doubling) that's no clickier than the
            # original was at that bar line
            ref = max(hf(y, s0), linesref)
            prev = out[-1]
            X0 = xfade_len(sc)
            for X in (X0, 2 * X0, 4 * X0, 8 * X0):
                X = min(X, len(seg) // 4, len(prev) // 2)
                pre = piece(y, s0 - X, s0)
                tryp = xfade(prev[-X:], pre)
                probe = np.concatenate([tryp[-int(0.01 * SR):], seg[:int(0.01 * SR)]])
                if hf(probe, min(int(0.01 * SR), len(tryp))) <= 1.15 * ref: break
            prev[-X:] = tryp
            joins.append((pos, sc))
            ins.append(firstbar)
        out.append(seg)
        pos += len(seg)
    y2 = np.concatenate(out)
    # the loop: the end crossfades into what comes before the first bar line
    s0, firstbar = spans[0][0], spans[0][3]
    sc = score(spans[-1][2], firstbar)
    X = xfade_len(sc)
    pre = piece(y, s0 - X, s0)
    y2[-X:] = xfade(y2[-X:], pre)
    joins.append((len(y2), sc))
    ins.append(firstbar)
    render.bars_in = ins
    # no louder than the original's music (its bars before the fade): turned down if it is, never up
    m0, m1 = bar_sample(A, 1), bar_sample(A, A["tail"])
    ref = float(np.sqrt(np.mean(y[max(m0, 0):m1] ** 2)) + 1e-12)
    now = float(np.sqrt(np.mean(y2 ** 2)) + 1e-12)
    g = min(1.0, ref / now)
    # and its peaks no higher than the original's (the shipped files peak at -1 dB at most)
    pk = float(np.abs(y2).max()) * g
    pk0 = max(float(np.abs(y).max()), 1e-6)
    if pk > pk0: g *= pk0 / pk
    if g < 1: y2 = y2 * np.float32(g)
    render.gain_db = 20 * np.log10(g)
    return y2, joins


def write_ogg(y, path, q=5):
    """Ogg Vorbis (quality q) by oggenc (libvorbis; this ffmpeg has no Vorbis encoder), through a temporary WAV."""
    import soundfile as sf, subprocess, tempfile
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    sf.write(tmp, np.clip(y, -1, 1), SR, subtype="PCM_16")
    subprocess.run(["oggenc", "-Q", "-q", str(q), "-o", path, tmp], check=True)
    os.unlink(tmp)


def join_clicks(y, joins, orig=None, A=None, bars_in=None):
    """How clicky each join is: the high end (over 6 kHz) in the 6 ms round it, against the same
    at the bar line it came in on in the original (or its bar lines' median, if that's more) -
    1 = no worse than the original had it there."""
    from scipy.signal import butter, sosfilt
    sos = butter(4, 6000, "high", fs=SR, output="sos")
    def hf(sig, at):
        w = int(0.003 * SR)
        seg = sig[max(at - w, 0):at + w].mean(axis=1)
        return float(np.sqrt(np.mean(sosfilt(sos, seg) ** 2)) + 1e-9)
    ref = 1e-9
    if orig is not None and A is not None:
        lines = [bar_sample(A, k) for k in range(2, A["tail"])]
        ref = np.median([hf(orig, s) for s in lines if 0 < s < len(orig)])
    yy = np.concatenate([y, y[:int(0.01 * SR)]])     # the loop's join: the end then the start again
    out = []
    for q, (p, sc) in enumerate(joins):
        r = ref
        if bars_in and orig is not None:
            r = max(ref, hf(orig, bar_sample(A, bars_in[q])))
        out.append((p, sc, hf(yy, p) / r))
    return out


def shipped_peak(name):
    """The game's own copy's peak (decoded), or -1 dB."""
    import soundfile as sf
    for ext in (".ogg", ".flac"):
        for d in ("src", ""):
            p = os.path.join(HERE, d, name + ext)
            if os.path.exists(p):
                o, _ = sf.read(p, dtype="float32")
                return float(np.abs(o).max())
    return 0.891


def render_to(name, path, A=None):
    """Render NAME.arr to path (.ogg: q5 from a lossless source, q6 from a lossy one - less lost
    again), its decoded peak no higher than the game's copy had (encoding adds a few %: turned
    down and encoded again if it does). Returns render's figures."""
    import soundfile as sf
    A = A or read_arr(name)
    y = load(name)
    y2, joins = render(name, A, y)
    ins, gdb = render.bars_in, render.gain_db
    _, _, lossless = source_path(name)
    q = 5 if lossless else 6
    limit = max(min(shipped_peak(name), 0.891), 0.5)
    for _ in range(3):
        write_ogg(y2, path, q)
        d, _ = sf.read(path, dtype="float32")
        pk = float(np.abs(d).max())
        if pk <= limit * 1.002: break
        g = limit / pk * 0.995
        y2 = y2 * np.float32(g); gdb += 20 * np.log10(g)
    clicks = join_clicks(y2, joins, y, A, ins)
    return dict(seconds=len(y2) / SR, peak=pk, gain_db=gdb, worst_click=max([c[2] for c in clicks if c[1] < 1] or [0]),
                joins=len([c for c in clicks if c[1] < 1]), mb=os.path.getsize(path) / 1e6)


# --- THE COMMAND LINE -------------------------------------------------------
def summary(name, A, info=None):
    L = {c: b - a + 1 for c, a, b, k in A["clips"]}
    bars = sum(r * L[c] for c, r in A["arrange"])
    s = "%-9s %6.2f bpm  %2d bars  %3.0f s  %s" % (name, A["bpm"], A["bars"], bars * 240 / A["bpm"],
        " ".join(c if r == 1 else "%s*%d" % (c, r) for c, r in A["arrange"]))
    if info is not None:
        J = arrangement_joins(A, info["S"])
        jumps = [j for j in J if j[1] != j[0] + 1]
        s += "  | jumps %d, worst %.2f, loop %.2f" % (len(jumps), min([j[2] for j in jumps] or [1]), J[-1][2])
    return s


def score_seams(name):
    """Every join NAME.arr's arrangement makes, and each clip looping round on itself, scored into
    its seams (SOUND TEST's arranger shows them; the renderer sizes a jump's crossfade by them) -
    for an arrangement changed by hand. The clips and arrangement are left as they are."""
    A = read_arr(name)
    y = load(name)
    g = analyze_grid(name, y)
    if abs(g["bpm"] - A["bpm"]) > 0.01 or abs(g["offset"] - A["offset"]) > 0.002:
        return "%-9s the grid's moved (.arr %.3f bpm at %.4f s, now %.3f at %.4f) - left alone" % (
            name, A["bpm"], A["offset"], g["bpm"], g["offset"])
    S = bar_similarity(bar_features(y, g))
    n = 0
    pairs = [(b, na) for b, na, sc in arrangement_joins(A, S) if na != b + 1]
    pairs += [(b, a) for c, a, b, k in A["clips"] if a != b + 1]
    for b, na in pairs:
        if (b, na) not in A["seams"] and 1 <= b <= S.shape[0] and 1 <= na <= S.shape[0]:
            A["seams"][(b, na)] = jump_score(S, b - 1, na - 1, A["tail"] - 1)
            n += 1
    write_arr(name, A)
    return "%-9s %d joins scored" % (name, n)


def write_source(name):
    """music/edit/NAME.flac: what the .arr's bars are counted on (the source, at the shipped
    loudness, 44.1 kHz) - SOUND TEST's arranger plays its clips from it. Ogg's samples can't be
    read in the game (_MEMSOUND), so even a lossy source is written out as FLAC."""
    import soundfile as sf
    os.makedirs(os.path.join(HERE, "edit"), exist_ok=True)
    out = os.path.join(HERE, "edit", name + ".flac")
    y = load(name)
    pk = float(np.abs(y).max())
    if pk > 0.999:
        y = y * np.float32(0.999 / pk)
    sf.write(out, y, SR, subtype="PCM_16")
    return "%-9s %5.1f s  %.1f MB  %s" % (name, len(y) / SR, os.path.getsize(out) / 1e6, out)


def main(argv):
    names = [a for a in argv if not a.startswith("--")] or tracks()
    if "--analyze" in argv:
        for n in names:
            A, info = analyze(n, fresh="--fresh" in argv)
            print(summary(n, A, info), flush=True)
    if "--render" in argv:
        for n in names:
            r = render_to(n, os.path.join(HERE, n + ".ogg"))
            print("%-9s %4.0f s  %.1f MB  peak %.3f  turned %+.1f dB  %d jumps, clickiest %.2f" % (
                n, r["seconds"], r["mb"], r["peak"], r["gain_db"], r["joins"], r["worst_click"]), flush=True)
    if "--clicks" in argv:
        for n in names:
            out = os.path.join(HERE, n + "-clicks.wav")
            click_track(n, out)
            print("wrote", out)
    if "--seams" in argv:
        for n in names:
            print(score_seams(n), flush=True)
    if "--sources" in argv:
        for n in names:
            print(write_source(n), flush=True)
    if not any(a in argv for a in ("--analyze", "--render", "--clicks", "--seams", "--sources")):
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
