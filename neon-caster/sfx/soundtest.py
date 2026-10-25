"""Writes soundtest.txt: every sound and track the SOUND TEST (SETTINGS > AUDIO) plays, by
category. Run it again after adding sounds or music:  python3 soundtest.py

Each line of soundtest.txt is   [CATEGORY]   or   path|label   (path under neon-caster/:
sfx/NAME.wav, speech/KEY.wav, music/NAME.ogg). A sound in no group below lands in OTHER."""
import os, re
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)

GROUPS = [
    ('WEAPONS', 'shoot charge charge-full scatter repeater rail rocket-fire rocket-boom empty weapon kick kick-swing headshot bolt-wall zap laser-zap'),
    ('PICKUPS', 'health ammo shells armor keycard core overcharge amp amp-end invuln invuln-end jetpack jetfuel repair power-up power-down'),
    ('DOORS', 'door door-shutter door-split door-kick door-break locked closet secret exit safe-open hoard-open keypad-beep keypad-ok keypad-bad'),
    ('WORLD', 'lift-start lift-move lift-stop crusher-slam plate-click trap-electric trap-fire teleport spawn jumppad jack-in jack-out camera note search barrel barrel-leak crate-break lamp-break plant-break terminal-break deco-hit glass-hit glass-break droid-break droid-chirp1 droid-chirp2 droid-chirp3 alarm alarm-press alarm-arm alarm-disarm drain sizzle'),
    ('YOU', 'hurt hurt2 hurt3 hurt-zap die gasp1 gasp2 gasp3 groan breath heartbeat step1 step2 bump wallhump swish'),
    ('WATER', 'splash swim1 swim2 wade1 wade2 bubble'),
    ('MENU', 'menu-move menu-select menu-back menu-slide menu-on menu-off menu-choice achievement fanfare fail'),
]
MON_PARTS = ('alert', 'hunt', 'idle', 'attack', 'shoot', 'hit', 'pain', 'die', 'bark', 'bite', 'wake', 'charge', 'laser', 'rush', 'beep', 'boom')
VOICES = ('soldier', 'heavy', 'cyborg', 'bark', 'thief')

def stem(f): return os.path.splitext(f)[0]
def num_key(s): return [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', s)]

out = []
# MUSIC: the title's, the ten's, the network's - then any set's or sector's own
names = {}
for d in ('', 'new/', 'remix/', 'huge/'):
    for n in range(1, 11):
        p = os.path.join(ROOT, 'levels', d + 'level%d.txt' % n)
        if os.path.exists(p):
            m = re.search(r'^name\s*=\s*(.+)$', open(p, errors='replace').read(), re.M)
            if m: names[(d.rstrip('/') or 'level') + str(n)] = m.group(1).strip()
for n in range(1, 31):
    p = os.path.join(ROOT, 'levels', 'custom', 'custom%d.txt' % n)
    if os.path.exists(p):
        m = re.search(r'^name\s*=\s*(.+)$', open(p, errors='replace').read(), re.M)
        if m: names['sector%d' % (10 + n)] = m.group(1).strip()
out.append('[MUSIC]')
music = sorted(os.listdir(os.path.join(ROOT, 'music')), key=lambda f: (0 if f.startswith('menu') else 1 if f.startswith('level') else 2 if f.startswith('cyber') else 3, num_key(f)))
for f in music:
    if not f.endswith(('.ogg', '.flac', '.mp3', '.wav')): continue
    s = stem(f)
    lab = {'menu': 'THE TITLE MENU', 'cyber': 'THE NETWORK'}.get(s) or names.get(s) or s.upper()
    if s.startswith(('new', 'remix', 'huge')) and s in names: lab = {'new': 'NEW ', 'remix': 'OLD NEW ', 'huge': 'HUGE '}[re.match(r'[a-z]+', s).group()] + lab
    out.append('music/%s|%s' % (f, lab))

sfx = sorted(stem(f) for f in os.listdir(HERE) if f.endswith('.wav'))
used = set()
for cat, lst in GROUPS:
    out.append('[%s]' % cat)
    for n in lst.split():
        if n in sfx: out.append('sfx/%s.wav|%s' % (n, n)); used.add(n)
# MONSTERS: every NAME-PART sound, a monster at a time (spitter, ICE and mimic too)
mons = sorted({n.rsplit('-', 1)[0] for n in sfx if '-' in n and n.rsplit('-', 1)[1] in MON_PARTS and n not in used and n.rsplit('-', 1)[0] not in ('deco', 'glass', 'keypad', 'rocket')})
out.append('[MONSTERS]')
for m in mons:
    for part in MON_PARTS:
        n = m + '-' + part
        if n in sfx and n not in used: out.append('sfx/%s.wav|%s' % (n, n)); used.add(n)
    for n in sfx: # (anything else of its: robodog-bark2...)
        if n.startswith(m + '-') and n not in used: out.append('sfx/%s.wav|%s' % (n, n)); used.add(n)
# NEXUS and the other voices (speech/): NEXUS's words come from GAME/NEXUS.BM's DATA lines
words = dict(re.findall(r'^DATA "([^"]+)", "([^"]*)"', open(os.path.join(ROOT, '..', 'GAME', 'NEXUS.BM')).read(), re.M))
speech = sorted((stem(f) for f in os.listdir(os.path.join(ROOT, 'speech')) if f.endswith('.wav')), key=num_key)
out.append('[NEXUS]')
for k in speech:
    if not k.startswith(VOICES): out.append('speech/%s.wav|%s' % (k, (k + ': ' + words[k]) if k in words else k))
out.append('[VOICES]')
for k in speech:
    if k.startswith(VOICES): out.append('speech/%s.wav|%s' % (k, (k + ': ' + words[k]) if k in words else k))
rest = [n for n in sfx if n not in used]
if rest:
    out.append('[OTHER]')
    out += ['sfx/%s.wav|%s' % (n, n) for n in rest]
open(os.path.join(HERE, 'soundtest.txt'), 'w').write('\n'.join(out) + '\n')
print('%d lines, %d categories' % (len(out), sum(1 for l in out if l.startswith('['))))
