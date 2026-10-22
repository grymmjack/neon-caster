"""Masters every sound and voice line into after/ (the game's files untouched), from before.json's analysis.

The chain, each sound's own amounts:
  highpass 30 Hz (rumble) -> low shelf 180 Hz up (body, only where there's something down there to lift)
  -> high shelf 3 kHz down (the tilt back towards the target) -> peaking cut at 3.2 kHz (the piercing band, when it
  dominates) -> de-esser (when its sibilant bursts are sharp) -> low-pass 13 kHz (air, sound effects only)
  -> gain back towards its loudness before (its loudest 400 ms), but never past -1 dBTP or +3 dB (none for a sound that was mostly air): no limiter, no distortion.
Writes after/sfx/NAME.wav, after/speech/KEY.wav and chains.json (what was done to each)."""
import json, os, re, subprocess, sys
S = os.path.dirname(os.path.abspath(__file__)); GAME = os.path.expanduser('~/git/neon-caster/neon-caster')
TARGET_TILT = -3.0 # dB per octave in 1/3-octave band power: darker than pink, as a pleasant mix is
A = json.load(open(os.path.join(S, 'before.json')))
C = A['centres']

def momentary(path):
    """(its loudest 400 ms, LUFS; its true peak, dBTP)"""
    r = subprocess.run(['ffmpeg', '-nostdin', '-v', 'verbose', '-i', path, '-af', 'apad=whole_dur=0.5,ebur128=framelog=verbose:peak=true', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = [float(x) for x in re.findall(r'M:\s*(-?[\d.]+)', r)]
    tp = re.findall(r'Peak:\s*(-?[\d.]+) dBFS', r)
    return (max(m) if m else -99), (float(tp[-1]) if tp else 0)

def info(path):
    r = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'stream=sample_rate,channels', '-of', 'csv=p=0', path], capture_output=True, text=True).stdout.strip().split(',')
    return r[0], r[1]

def chain(name, a):
    speech = name.startswith('speech/')
    f = ['highpass=f=30']
    ex = a['tilt'] - TARGET_TILT
    b = dict(zip(C, a['bands']))
    has_low = max(b[100], b[125], b[160], b[200]) > -30 # (something there to lift)
    hs = ls = pk = 0
    if speech and ex < 1.5: ex = 0 # (voices: left alone unless bright)
    if ex > 0.5:
        hs = -min(12.0, round(ex * 1.6, 1))
        if has_low: ls = min(5.0, round(ex * 0.7, 1))
    elif ex < -3.0 and not speech: # (a dull one: a touch of air back)
        hs = min(3.0, round(-ex * 0.5, 1))
    if a['regions']['presence'] > 0.30: pk = -min(6.0, round((a['regions']['presence'] - 0.25) * 20, 1)) # (2.5-5 kHz piling up)
    if ls: f.append('lowshelf=f=180:g=%g:t=s:w=0.7' % ls)
    if hs: f.append('highshelf=f=3000:g=%g:t=s:w=0.7' % hs)
    if pk: f.append('equalizer=f=3200:t=o:w=1:g=%g' % pk)
    de = 0
    if (a['sib'] > 0.35 and not speech) or a['sib'] > 0.5:
        de = 0.6 if a['sib'] > 0.6 else 0.4
        f.append('deesser=i=%g:m=0.5:f=0.5:s=o' % de)
    if not speech: f.append('lowpass=f=12000:p=2')
    return f, dict(lowshelf=ls, highshelf=hs, peak3k=pk, deess=de, lowpass=0 if speech else 12000)

out = {}
for name, a in sorted(A['sounds'].items()):
    src = os.path.join(GAME, name + '.wav'); dst = os.path.join(S, 'after', name + '.wav')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    sr, ch = info(src)
    f, what = chain(name, a)
    tmp = dst + '.tmp.wav'
    subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-y', '-i', src, '-af', ','.join(f), '-ar', sr, '-ac', ch, '-c:a', 'pcm_f32le', tmp], check=True)
    (m0, _), (m1, tp1) = momentary(src), momentary(tmp)
    g = min(m0 - m1, -1.0 - tp1, 3.0) # (back towards how loud it was - never past its own headroom, so no limiter, no distortion)
    if a['regions']['air'] > 0.4: g = min(g, 0.0) # (a whistle up top: the low-pass took the harshness - let it be quieter)
    subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-y', '-i', tmp, '-af', 'volume=%gdB' % g,
                    '-ar', sr, '-ac', ch, '-c:a', 'pcm_s16le', dst], check=True)
    os.remove(tmp)
    what['gain'] = round(g, 1); out[name] = what
    print(name, what, flush=True)
json.dump(out, open(os.path.join(S, 'chains.json'), 'w'))
