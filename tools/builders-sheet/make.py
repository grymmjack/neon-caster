#!/usr/bin/env python3
"""The level builder's sheet: every texture, map character, thing, light,
event, trigger, name and console command on one page.

    python3 tools/builders-sheet/make.py            -> BUILDERS-SHEET.html (repo root)
    python3 tools/builders-sheet/make.py --embed OUT -> one file, pictures and
                                                        sounds inside (to share)

The usual page links the game's own files (neon-caster/NAME.png, sfx/), so it
is small and shows whatever pictures the folder holds - keep it beside the
neon-caster folder. Its words: names.json (machines, pickups, puzzles),
sounds.json (when each sound plays), example.txt (the example sector), the
tables in this file, and the console's own help (conhelp.py reads ConHelp).
Re-run it after adding a texture, sound, command or kind of thing."""
import base64, html, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
A = os.path.join(ROOT, "neon-caster")
EMBED = "--embed" in sys.argv
args = [a for a in sys.argv[1:] if a != "--embed"]
OUT = os.path.abspath(args[0]) if args else os.path.join(ROOT, "BUILDERS-SHEET.html")
E = html.escape

def link(p):
    """A file of the game's: inside the page (--embed), else a path from the page."""
    if EMBED:
        kind = "image/png" if p.endswith(".png") else "audio/wav"
        return "data:%s;base64,%s" % (kind, base64.b64encode(open(p, "rb").read()).decode())
    return os.path.relpath(p, os.path.dirname(OUT)).replace(os.sep, "/")

def img(name):
    p = os.path.join(A, name if name.endswith(".png") else name + ".png")
    return link(p) if os.path.exists(p) else ""

def pics(prefix):
    return sorted(f[:-4] for f in os.listdir(A) if f.startswith(prefix) and f.endswith(".png"))

# ---------- pictures ----------
SPECIAL = {
    "wall-jack": "data station @", "wall-code": "code terminal $", "wall-turret": "turret panel ;",
    "wall-switch": "a switch: put a use/shoot trigger on it", "wall-lightstrip": "lit strips",
    "wall-new1": "made in the editor", "wall-sheet1-1": "made in the editor",
    "wall-sheet1-2": "made in the editor", "wall-sheet1-3": "made in the editor",
    "floor-molten": "BURNS", "floor-murky": "SLOWS", "ceiling-lamp": "the lamp fixture",
}
HOT = {"floor-molten", "floor-murky"}

def tiles(names, kind):
    out = []
    for n in names:
        note = SPECIAL.get(n, "")
        cls = "tile" + (" hot" if n in HOT else "") + (" own" if note == "made in the editor" else "")
        out.append(
            f'<button class="{cls}" data-copy="{E(n)}.png" data-k="{E(n + " " + note + " " + kind)}" title="Copy {E(n)}.png">'
            f'<img src="{img(n)}" alt="" loading="lazy"><span class="nm">{E(n)}</span>'
            + (f'<span class="tag">{E(note)}</span>' if note else "") + "</button>")
    return "\n".join(out)

walls = [w for w in pics("wall") if not w.startswith(("wall-new", "wall-sheet"))]
floors = pics("floor")
ceils = pics("ceiling")
skies = pics("sky-")
smears = pics("smear-")

# ---------- map characters ----------
# (char, picture, name, note)
STRUCT = [
    (".", "floor", "Floor", ""),
    ("#", "wall", "Wall 1", "1st of walls ="),
    ("N", "wall", "Wall 2", "2nd of walls ="),
    ("C", "wall", "Wall 3", "3rd"),
    ("K", "wall", "Wall 4", "4th"),
    ("P", "wall", "Wall 5", "5th"),
    ("G", "wall", "Wall 6", "6th"),
    ("/", "", "Diagonal /", "half wall, corner to corner"),
    ("\\", "", "Diagonal \\", "half wall, corner to corner"),
    ("%", "", "Closet wall", "opens on a closet event (kind 6) within 3"),
    ("?", "", "Secret wall", "Space slides it; or trigger secret X Y"),
    ("=", "", "Glass", "1 thick, in a straight wall; [glass]"),
    ("-", "bars", "Bars", "see through, never break"),
    ("@", "wall-jack", "Data station", "jack in; opens near ! doors"),
    ("$", "wall-code", "Code terminal", "QB64 puzzle from puzzles ="),
    (";", "wall-turret", "Turret control", "word hack: turrets within 12 off"),
    ("&", "", "Teleporter", "pairs in reading order; [pads]"),
    ("<", "", "Start, facing W", "exactly one start"),
    (">", "", "Start, facing E", ""),
    ("^", "", "Start, facing N", ""),
    ("v", "", "Start, facing S", ""),
]
DOORS = [
    ("D", "door", "Sliding door", "Space, open 4 s"),
    ("H", "door-shutter", "Shutter", "rolls up, open 6 s"),
    ("X", "door-split", "Split door", "fastest, open 3 s"),
    ("R", "door", "Red key door", "needs r", "red"),
    ("B", "door", "Blue key door", "needs b", "blue"),
    ("Y", "door", "Yellow key door", "needs y", "yellow"),
    ("!", "door", "Sealed door", "opens when nearest @ hacked"),
    ("E", "exit", "EXIT", "Space ends the sector"),
    ("", "door-keypad", "Keypad door", "[doors] x, y, 0, CODE (or ?)"),
    ("", "door-stronghold", "Stronghold door", "[doors] x, y, KICKS"),
]
PICKUPS = [
    ("r", "keycard", "Red keycard", "", "red"), ("b", "keycard", "Blue keycard", "", "blue"),
    ("y", "keycard", "Yellow keycard", "", "yellow"),
    ("+", "medkit", "Health +25", "to 100"), ("*", "bigmed", "Big medkit +50", ""),
    ("u", "armor", "Armour +50", ""), ("q", "overcharge", "Overcharge +100", "to 200"),
    ("j", "amp", "Damage amp", "x2 for 30 s"), ("M", "map", "The map", ""),
    ("a", "ammo", "Cells +15", "blaster"), ("e", "shells", "Shells +8", ""),
    ("{", "rounds", "Rounds +40", "repeater"), ("}", "slugs", "Slugs +5", "railgun"),
    ("(", "rockets", "Rockets +5", ""),
    ("2", "pickup-scatter", "Scatter gun", "+8 shells"), ("3", "pickup-repeater", "Repeater", "+60 rounds"),
    ("4", "pickup-rail", "Railgun", "+6 slugs"), ("5", "pickup-rocket", "Rocket launcher", "+5 rockets"),
    ("8", "goggles", "Night vision", "N toggles"), ("9", "suit", "Hazmat suit", "poison, slime, acid"),
    ("`", "jetpack", "Jetpack", "[fuel] x, y, N"), (",", "jetfuel", "Jet fuel +40", "[fuel] x, y, N"),
    ('"', "repairkit", "repairkit", "fixes a brokenpc"), ('"', "invuln", "invuln", "5 s"),
    ('"', "flashlight", "flashlight", "L toggles"), ('"', "battery", "battery", "spare, 4 max"),
]
MONSTERS = [
    ("m", "drone", "drone", "3"), ("g", "gunner", "gunner", "4"), ("h", "heavy", "heavy", "10"),
    ("c", "crawler", "crawler", "2"), ("s", "sentry", "sentry", "8"), ("k", "stalker", "stalker", "3"),
    ("w", "spitter", "spitter", "6"), ("z", "overseer", "overseer", "80 · boss"),
    ("T", "thief", "thief", "5 · runs to its hoard"), ("1", "sniper", "sniper", "4 · laser"),
    (")", "trooper", "trooper", "6 · bursts"), ("6", "ripper", "ripper", "3 · fast"),
    ("7", "warden", "warden", "60 · field boss"), ("0", "colossus", "colossus", "90 · field boss"),
    ("~", "turret", "turret, ceiling", "6"), ("_", "turret", "turret, floor", "6"),
    ("|", "turret", "turret, wall", "needs a wall beside"),
    ("]", "mimic-asleep", "mimic", "8 · looks like a chest"),
    ('"', "robodog", "robodog", "5 · barks, wakes 10"), ('"', "guard", "guard", "4 · runs to alarms"),
    ('"', "eyebot", "eyebot", "3 · flies, dives, blows up"),
]
DECOS = [
    ("o", "barrel", "Barrel", "explodes; stacks"), ("i", "lamp", "Lamp", "cyan light"),
    ("p", "plant", "Plant", ""), ("t", "terminal", "Terminal", "pong"), ("x", "crate", "Crate", ""),
    ("l", "rack", "Server rack", "blinks"), ("n", "vending", "Vending machine", "slot machine"),
    ("f", "tank", "Coolant tank", "explodes"), ("S", "spawner", "Spawner", "nest events"),
    ("d", "desk", "Desk", "searchable; note"), ("A", "console", "Control console", "glows, pong"),
    ("F", "screens", "Wall of screens", "glows, pong"), ("I", "specimen", "Specimen tank", "may release"),
    ("J", "labbench", "Lab bench", ""), ("L", "generator", "Generator", "fire glow"),
    ("O", "cryopod", "Cryo pod", "glows"), ("Q", "hologram", "Hologram", "glows"),
    ("U", "locker", "Lockers", ""), ("W", "bench", "Bench", ""), ("Z", "chair", "Chair", "faces its desk"),
    ("V", "body", "Body", "flat, no block"),
    (":", "barrel-water", "Liquid barrel", "[barrels] x, y, 1-5, stack"),
    ("[", "chest", "Treasure chest", "Space opens"), ("'", "note", "Note", "[notes]"),
]
THINGS = [
    ("table", "table-flipped", "cover, see over, 10 hits", "(a \" with no line)"),
    ("brokenmonitor", "monitor-broken", "flat on the floor", ""),
    ("deadscientist", "body-scientist", "body, flat", ""), ("deadguard", "body-guard", "body, flat", ""),
    ("deadcyborg", "body-cyborg", "body, flat", ""),
    ("bookshelf", "bookshelf", "searched once; loot, note", ""),
    ("safe", "safe", "keypad safe", "CODE or ?"),
    ("brokenpc", "terminal-broken", "fix with a repairkit", "X, Y it opens"),
    ("computer", "terminal", "word hack opens a door/safe", "X, Y it opens"),
    ("camera", "camera", "follows you; 3 shots", "NAME"),
    ("secmon", "screens", "watch the cameras", ""),
    ("alarm", "alarm", "switch: wakes 24 cells", "off"),
    ("alarmpc", "alarmpc", "switches alarms off/on", "X, Y of its alarm"),
    ("jumppad", "jumppad", "launches you", "DIR, ANGLE, POWER"),
    ("padpc", "console", "sets a pad's numbers", "X, Y of its pad"),
]

def charcards(rows, kind):
    out = []
    for r in rows:
        ch, pic, name, note = r[:4]
        tint = r[4] if len(r) > 4 else ""
        src = img(pic) if pic else ""
        im = (f'<img src="{src}" alt="" loading="lazy">' if src else '<span class="noimg"></span>')
        chb = (f'<b class="ch" data-copy="{E(ch)}" title="Copy {E(ch)}">{E(ch)}</b>' if ch else '<b class="ch dim">[ ]</b>')
        if ch == '"':
            chb = f'<b class="ch thing" data-copy="{E(name)}" title="Copy {E(name)}">"</b>'
        out.append(
            f'<div class="cc {tint}" data-k="{E(ch + " " + name + " " + note + " " + kind)}">'
            f'{chb}<span class="im">{im}</span><span class="tx"><span class="nm">{E(name)}</span>'
            + (f'<span class="nt">{E(note)}</span>' if note else "") + "</span></div>")
    return "\n".join(out)

def thingrows():
    out = []
    for name, pic, what, more in THINGS:
        out.append(
            f'<div class="cc" data-k="{E(name + " " + what + " " + more + " thing")}">'
            f'<b class="ch thing" data-copy="{E(name)}" title="Copy {E(name)}">"</b>'
            f'<span class="im"><img src="{img(pic)}" alt="" loading="lazy"></span>'
            f'<span class="tx"><span class="nm mono">{E(name)}</span><span class="nt">{E(what)}'
            + (f' · <code>{E(more)}</code>' if more else "") + "</span></span></div>")
    return "\n".join(out)

# ---------- tables ----------
def table(head, rows, k=""):
    h = "".join(f"<th>{E(c)}</th>" for c in head)
    b = []
    for r in rows:
        b.append(f'<tr data-k="{E(re.sub("<[^>]+>", "", " ".join(r)) + " " + k)}">' + "".join(
            f"<td>{c}</td>" if str(c).startswith("<") else f"<td>{E(str(c))}</td>" for c in r) + "</tr>")
    return f'<div class="tw"><table><thead><tr>{h}</tr></thead><tbody>{"".join(b)}</tbody></table></div>'

C = lambda s: f"<code>{E(s)}</code>"

HEIGHTS = [
    (C("."), "usual: floor 0, ceiling 8"), (C("0") + "–" + C("9"), "0–9 eighths up (8 = one wall)"),
    (C("a") + "–" + C("z"), "10–35 up (g = two walls)"), (C("A") + "–" + C("H"), "1–8 down; H = death pit"),
]
HRULES = [("Step up", "2 eighths"), ("Blocks you", "3 eighths"), ("Least headroom", "6 eighths"),
          ("Hurts to fall", "8 eighths (7 doesn't)"), ("Floor max", "ceiling − 2"), ("Top", "240 eighths (30 walls)")]
LIQ = [(C("w"), "water", "slows", "1"), (C("p"), "poison", "hurts, green", "2"), (C("s"), "slime", "slows a lot, stings", "3"),
       (C("l"), "lava", "burns, glows", "4"), (C("a"), "acid", "eats armour", "5")]
LFX = [("0", "steady"), ("1", "flicker"), ("2", "pulse"), ("3", "strobe"), ("4", "fire"), ("5", "dying")]
TYPES = "monster types: 1 drone · 2 gunner · 3 heavy · 4 crawler · 5 sentry · 6 stalker · 7 spitter · 8 overseer · 9 thief"
SEC = " (60 frames = 1 second.)"
EVENT_TIPS = {
    "1": "Walk in and the room's doors (every door within 5 cells) slam shut and lock. a monsters teleport in, a few at a time, all of type b, or a mix with 0. Kill them all and the doors open and the reward appears in the middle of the room. Teleporters in the room don't work while it's on. " + TYPES,
    "2": "Walk in and you're locked in for a seconds while monsters keep arriving, one every b frames. Hold out till the clock runs down: the doors open and the reward appears." + SEC,
    "3": "The room's floor becomes a glowing wire grid that never stops: live for a frames, then safe for b. It crackles for half a second before going live. While live it hurts 6 about every quarter second. Cross on the off beat. a of 0 is a mistake (it logs an error)." + SEC,
    "4": "A mini game: walk in and break every decoration in the room within a seconds to win the reward. Fill the room with breakables (crates, barrels, plants). No chests in a gallery.",
    "5": "Spawners (S) in the room send out a monster of type a every b frames while you're near. Break every spawner to win the reward. " + TYPES + "." + SEC,
    "6": "Walk in and the closet walls (%) within 3 cells slide away, letting out what was waiting behind them. Once those monsters are dead, something clicks at the back: a stash in the wall, opened with Space (it counts as a secret). a and b are unused.",
    "7": "A sealed treasure room. Thieves (T) run to it with what they steal from you. When the last thief dies it opens; if a thief gets home with your things, it slips inside and the hoard is locked for good. a and b are unused.",
    "8": "A pressure plate: when you or a walking monster steps in the room, it clicks and beeps, and a frames later an explosion lands on it. It re-arms after b frames. A one-cell room makes a single plate." + SEC,
    "9": "A laser beam across the room (put it across a corridor): on for a frames, off for b frames, and always on when b is 0. It flickers before it comes on, and touching it burns." + SEC,
    "10": "A laser beam that runs across the room's short way and sweeps along its long way, there and back every a frames. a of 0 is a mistake (it logs an error)." + SEC,
    "11": "Walk in and the power fails: the lights die for a seconds and b monsters come out of the dark. Leave a flashlight or night vision somewhere before it.",
    "12": "The electric trap's twin, as a burner grate: smoke and embers as its warning, then the floor blazes. Live for a frames, safe for b. Use it in hot places (reactors, foundries)." + SEC,
    "13": "Land on the room's lowest floor, from any height, and you die: a pit with a bottom you can see, or streets under rooftops. Higher floors in the same room are safe. It never locks or ends. a and b are unused.",
}
EVENTS = [
    ("1", "Ambush", "how many", "type (0 mix)"), ("2", "Survive", "seconds", "frames between"),
    ("3", "Trap, electric", "frames live", "frames safe"), ("4", "Gallery", "seconds", ""),
    ("5", "Nest", "type", "frames between"), ("6", "Closet", "", "opens % within 3"),
    ("7", "Hoard", "", "sealed till thieves die"), ("8", "Plate", "frames to blast", "frames to re-arm"),
    ("9", "Laser", "frames on", "frames off (0 always)"), ("10", "Cutter", "frames a sweep", ""),
    ("11", "Blackout", "seconds", "monsters"), ("12", "Trap, fire", "frames live", "frames safe"),
    ("13", "Death pit", "", "lowest floor kills"),
]
REWARDS = "1 red · 2 blue · 3 yellow · 4 health · 5 cells · 6 shells · 7 scatter · 8 repeater · 9 armour · 10 medkit · 11 railgun · 12 map · 13 overcharge · 14 amp"
LIFTS = [("1", "up and down by itself"), ("2", "elevator"), ("3", "only by liftgo"), ("4", "CRUSHER (ceiling)"), ("5", "SMASHER (ceiling)")]
WHENS = [
    ("enter X0 Y0 X1 Y1", "you step into the box"), ("use X Y", "Space facing the cell"),
    ("shoot X Y", "shot or kicked (wall-switch.png)"), ("clear X0 Y0 X1 Y1", "every monster that started there dead"),
    ("time S", "S seconds in"), ("hack X Y", "that computer hacked"),
    ("alarm [X Y]", "that switch (or any) sounds"), ("calm", "the alarm stops"),
]
CMDS = [
    ("door X Y open|close|lock|unlock|toggle", "work a door"), ("secret X Y", "open a ? wall"),
    ("message TEXT", "show a message"), ("sound NAME", "play sfx/NAME.wav"),
    ("spawn TYPE X Y [N]", "monsters teleport in, hunting"), ("item KIND X Y", "a pickup appears"),
    ("light N on|off|toggle", "switch light N ([lights] line)"), ("light N colour RRGGBB", "recolour it"),
    ("ambient BRIGHT [RRGGBB] [FX]", "sector light (<0 darkens all)"),
    ("cell-light X0 Y0 X1 Y1 B RRGGBB [FX]", "cells' own light; … off"),
    ("liquid KIND X0 Y0 X1 Y1 [D]", "flood a box; none drains"), ("drain X Y [SPEED]", "drain a pool"),
    ("wet X0 Y0 X1 Y1 N", "floors wetter 0-9"), ("gravity N", "percent"),
    ("liftgo N up|down", "send a lift"), ("turret WHO WHAT", "drive turrets"),
    ("wall X Y CHAR", "swap a wall till rebuild"), ("program NAME", "run programs/NAME.bas"),
    ("give / take …", "health, armor, ammo, keys"), ("die [MESSAGE]", "you die"),
]
HEADER = [
    ("name", "SECTOR 31: THE LAUNCH BAY"), ("walls", "6 textures: # N C K P G"), ("floors", "4 textures (zones 1-4)"),
    ("ceilings", "2 textures (zones 1-2)"), ("ambient", "BRIGHT, R, G, B  (165, 225, 220, 255)"),
    ("puzzles", "one per $, in reading order"), ("gravity", "1-300 % (100)"), ("wetness", "0-9"),
    ("glass_reflect", "0-9 (2)"), ("glass_style", "0-7"), ("droids", "0-6 (3)"),
]
SECTIONS = [
    ("[zones]", "x0, y0, x1, y1, floor 1-4, ceiling 1-2, shape 0-4"),
    ("[lights]", "x, y, radius, bright 0-400, r, g, b, fx [, 1 no lamp]"),
    ("[cell lights]", "x0, y0, x1, y1, bright 0-256, r, g, b, fx"),
    ("[events]", "kind, x0, y0, x1, y1, a, b, reward"),
    ("[lifts]", "x0, y0, x1, y1, low, high, mode, speed"),
    ("[faces]", "x, y, face, divided, picture, second [, slideU, slideV, stretchU%, stretchV%]"),
    ("[blocks]", "x, y, x0, y0, x1, y1, wall 1-6  (eighths)"),
    ("[barrels]", "x, y, liquid 0-5, stack 1-8"),
    ("[doors]", "x, y, kicks, code (digits or ?)"),
    ("[things]", "x, y, kind [, more]"),
    ("[notes]", "x, y, picture or -, words  (| new line, {code X Y})"),
    ("[fuel]", "x, y, amount 1-100"),
    ("[smears]", "x, y, face, blood1-3 | oil1-2"),
    ("[difficulty]", "x, y, easy normal hard nightmare | none"),
    ("[looks]", "x, y, tint 0-3, amount, RRGGBB [, size %]"),
    ("[glass]", "x, y, reflect [, blur, frost, ripple [, style [, through [, strength]]]]"),
    ("[nudges]", "x, y, dx, dy, facing 0-5  (eighths, -3..3)"),
    ("[pads]", "x1, y1, x2, y2"),
    ("[monsters]", "x, y, sight, hearing, hp%, speed%, wake 0-3 [, weapon, turn, eject, mode]"),
    ("[triggers]", "WHEN [repeat] : CMD ; CMD"),
    ("[loot]", "breakable = pickup:chance, … (4 at most)"),
    ("[liquid] [liquid depth] [liquid opacity] [floor wetness]", "maps, a character a cell"),
    ("[map] [floor] [ceiling]", "maps, a character a cell"),
]
FACES = [("E S W N", "a wall's (or step's) sides"), ("LE LS LW LN", "lintels"), ("F C", "floor, ceiling"),
         ("BE BS BW BN", "a block's sides"), ("DG", "diagonal's slant"), ("DE DT", "door edges, door track")]
TURRET_W = "0 plasma · 1 laser · 2 lightning · 3 flame · 4 poison · 5 acid · 6 missiles"
WAKE = "0 sees you · 1 you near · 2 hit · 3 hunting from the start"

SPAWN = "drone gunner heavy crawler sentry stalker spitter overseer thief sniper trooper ripper warden colossus turret mimic robodog guard eyebot".split()
ITEMS = "red blue yellow health ammo shells scatter repeater armor medkit rail map overcharge amp goggles suit launcher rockets rounds slugs jetpack jetfuel repairkit invuln flashlight battery".split()
PUZZLES = "countdown function hello multiply password pythagoras reverse select sum wrap".split()
SOUNDS = sorted(f[:-4] for f in os.listdir(os.path.join(A, "sfx")) if f.endswith(".wav"))
# Monster voices are many: keep the sheet to the ones a trigger would use.
VOICE_SUFFIX = ("-alert", "-attack", "-die", "-hit", "-hunt", "-idle", "-pain", "-shoot")
TRIGGER_SOUNDS = [s for s in SOUNDS if not s.endswith(VOICE_SUFFIX) and not s.startswith("menu-")]

def chips(words, kind, copy=True):
    return "".join(f'<button class="chip" data-copy="{E(w)}" data-k="{E(w + " " + kind)}">{E(w)}</button>' for w in words)

def kv(rows, kind):
    return "".join(f'<div class="kv" data-k="{E(a + " " + b + " " + kind)}"><code>{E(a)}</code><span>{E(b)}</span></div>' for a, b in rows)

# ---------- the console (its own help, ConHelp) ----------
import conhelp
COLS = {"1": "c-red", "2": "c-green", "3": "c-syn", "4": "c-blue", "5": "c-cyan", "6": "c-mag", "7": "c-white", "8": "c-grey", "9": "c-orange"}

def coloured(t):
    """A console line's ^N colour codes as spans (^0: back to the line's own)."""
    out, cls, buf = [], None, ""
    i = 0
    def flush():
        nonlocal buf
        if buf:
            out.append(f'<span class="{cls}">{E(buf)}</span>' if cls else E(buf))
        buf = ""
    while i < len(t):
        if t[i] == "^" and i + 1 < len(t) and t[i + 1].isdigit():
            flush(); cls = COLS.get(t[i + 1]); i += 2; continue
        buf += t[i]; i += 1
    flush()
    return "".join(out)

GROUP_NAMES = {
    "sectors": "Sectors", "cheats": "Cheats & testing", "looking": "Looking round",
    "saves and settings": "Saves & settings", "playing, scripts": "Playing & scripts", "demos": "Demos & the bot",
    "editors, achievements, the rest": "Editors, achievements & the rest",
}
def group_name(g):
    for k, v in GROUP_NAMES.items():
        if g.startswith(k):
            return v
    if g.startswith("the level"):
        return "Building the level"
    return g.capitalize() or "More"

def console_html():
    ov, cmds = conhelp.read()
    groups = []
    for c in cmds:
        g = group_name(c["group"])
        if not groups or groups[-1][0] != g:
            groups.append((g, []))
        groups[-1][1].append(c)
    nav = "".join(f'<a href="#con-{i}">{E(g)}</a>' for i, (g, _) in enumerate(groups))
    out = [f'<div class="ovw"><div class="conlines">' + "".join(f'<div>{coloured(l)}</div>' for l in ov) + "</div></div>",
           f'<nav class="connav">{nav}</nav>']
    for i, (g, cs) in enumerate(groups):
        out.append(f'<h3 id="con-{i}">{E(g)} <small class="note">{len(cs)}</small></h3><div class="cmds">')
        for c in cs:
            n = c["names"]
            also = (' <span class="also">also ' + ", ".join(f"<code>{E(a)}</code>" for a in n[1:]) + "</span>") if len(n) > 1 else ""
            body = "".join(f"<div>{coloured(l)}</div>" for l in c["lines"])
            key = " ".join(n) + " " + re.sub(r"\^\d", "", " ".join(c["lines"])) + " console " + g
            out.append(f'<article class="cmd" data-k="{E(key)}"><header><button class="cname" data-copy="{E(n[0])}" title="Copy {E(n[0])}">{E(n[0])}</button>{also}</header>'
                       f'<div class="conlines">{body}</div></article>')
        out.append("</div>")
    return "\n".join(out), len(cmds)

CONSOLE, NCMDS = console_html()

# ---------- names: monsters, pickups, puzzles, sounds ----------
import json
ND = json.load(open(os.path.join(HERE, "names.json")))
SD = json.load(open(os.path.join(HERE, "sounds.json")))

def picof(t):
    m = re.search(r"[\w-]+\.png", t or "")
    return img(m.group(0)) if m else ""

def tintof(t):
    for c in ("red", "blue", "yellow"):
        if "tinted " + c in (t or ""):
            return c
    return ""

def chcell(ch):
    if not ch or ch.startswith("("):
        return '<span class="dim">none</span>'
    return f'<b class="chs" data-copy="{E(ch)}" title="Copy {E(ch)}">{E(ch)}</b>'

def namebtn(n):
    return f'<button class="nmc" data-copy="{E(n)}" title="Copy {E(n)}">{E(n)}</button>'

def mon_rows():
    rows = []
    for m in ND["monsters"]:
        aka = m.get("summon_names") or []
        aka = [a for a in (aka if isinstance(aka, list) else [aka]) if a != m["name"]]
        extra = (f'<div class="sm">also {", ".join(E(a) for a in aka)}</div>' if aka else "")
        flag = ' <span class="flag">network only</span>' if m["name"] == "ice" else ""
        unsure = f'<div class="sm warn">{E(m["unsure"])}</div>' if m.get("unsure") else ""
        key = " ".join(str(v) for v in m.values()) + " monster"
        rows.append(f'<tr data-k="{E(key)}"><td class="pic"><img src="{picof(m["picture"])}" alt="" loading="lazy"></td>'
            f'<td>{namebtn(m["name"])}{flag}{extra}<div class="sm">map {chcell(m["char"])} · type <b>{m["type_no"]}</b></div></td>'
            f'<td class="num"><b>{E(str(m["hp"]))}</b><div class="sm">{E(m.get("hp_by_difficulty", ""))}</div></td>'
            f'<td>{E(m["damage"])}</td><td>{E(m["attack"])}</td><td>{E(m["speed"])}</td>'
            f'<td>{E(m["sight/notes"])}{unsure}</td>'
            f'<td>{E(m.get("weak_spot", "") or "-")}</td><td>{E(m["drops"])}</td></tr>')
    return ('<div class="tw"><table class="names"><thead><tr><th>Looks</th><th>Name</th><th>Health<div class="sm">E / N / H / NM</div></th>'
            '<th>Damage</th><th>Attack</th><th>Speed</th><th>Behaviour</th><th>Weak spot</th><th>Drops</th></tr></thead><tbody>'
            + "".join(rows) + "</tbody></table></div>")

def item_rows():
    rows = []
    for it in ND["pickups"]:
        aka = it.get("aliases") or []
        aka = [a for a in (aka if isinstance(aka, list) else [aka]) if a != it["name"]]
        extra = (f'<div class="sm">also {", ".join(E(a) for a in aka)}</div>' if aka else "")
        bd = f'<div class="sm">E / N / H / NM: {E(it["by_difficulty"])}</div>' if it.get("by_difficulty") else ""
        flag = ' <span class="flag">network only</span>' if it["name"] == "core" else ""
        key = " ".join(str(v) for v in it.values()) + " pickup item"
        rows.append(f'<tr data-k="{E(key)}"><td class="pic {tintof(it["picture"])}"><img src="{picof(it["picture"])}" alt="" loading="lazy"></td>'
            f'<td>{namebtn(it["name"])}{flag}{extra}<div class="sm">map {chcell(it["char"])}</div></td>'
            f'<td>{E(it["what"])}{bd}</td><td>{E(it["for"])}</td></tr>')
    return ('<div class="tw"><table class="names"><thead><tr><th>Looks</th><th>Name</th><th>What it does</th><th>For</th></tr></thead><tbody>'
            + "".join(rows) + "</tbody></table></div>")

def puzzle_rows():
    rows = []
    for z in ND["puzzles"]:
        key = " ".join(str(v) for k, v in z.items() if k != "blanks") + " puzzle"
        where = f'<code>{E(z["file"])}</code>'
        sec = z.get("default_sector", "")
        ch = z.get("course_chapter", "")
        rows.append(f'<tr data-k="{E(key)}"><td>{namebtn(z["name"])}<div class="sm">{E(z["title"])}</div></td>'
            f'<td>{E(z["lesson"])}</td><td>{E(z["what"])}</td>'
            f'<td class="num">{E(str(sec))}' + (f'<div class="sm">course: {E(str(ch))}</div>' if ch else "") + f'</td><td>{where}</td></tr>')
    return ('<div class="tw"><table class="names"><thead><tr><th>Name</th><th>Teaches</th><th>What you do</th><th>Sector<div class="sm">with no puzzles =</div></th><th>Where</th></tr></thead><tbody>'
            + "".join(rows) + "</tbody></table></div>"
            + '<p class="lead">How the code runs one (the same for every puzzle):</p>'
            + '<div class="tw code"><pre>' + E(PUZZLE_FLOW) + '</pre></div>')

PUZZLE_FLOW = """GAME/TERMINALS.BM
  TerminalUse      Space at a $ code terminal (called from LOOP/11-DOORS.BI)
                   - locks the doors within 7 cells
                   - picks the puzzle: the level's 'puzzles =' list, one a terminal
                     in reading order, else one by sector number
  LoadPuzzle       reads neon-caster/puzzles/NAME.txt (AssetPath$),
                   shuffles the lines, blanks the words
  RunPuzzle        the puzzle screen
  PuzzleRun        compiles it with qb64pe (QB64Path$) and checks the output
                   against the puzzle's 'expect'
  PuzzleMatches    no qb64pe: the lines are checked against [lines] instead

MENU/CONSOLE.BM
  ConExec          'puzzle NAME' tries one with no doors at stake"""

def mp3(n):
    """A sound's file (the game's own .wav; --embed makes it a small mp3 when ffmpeg is there)."""
    p = os.path.join(A, "sfx", n + ".wav")
    if not os.path.exists(p):
        return ""
    if EMBED:
        import shutil, subprocess, tempfile
        if shutil.which("ffmpeg"):
            with tempfile.TemporaryDirectory() as t:
                o = os.path.join(t, "s.mp3")
                subprocess.run(["ffmpeg", "-loglevel", "error", "-i", p, "-ac", "1", "-b:a", "48k", o], check=True)
                return "data:audio/mpeg;base64," + base64.b64encode(open(o, "rb").read()).decode()
    return link(p)

def sound_rows():
    cats = []
    for e in SD:
        if e["cat"] not in cats:
            cats.append(e["cat"])
    order = ["Player", "Weapons", "Pickups", "Doors", "World", "Hazards", "Machines", "Alarms & security", "Events", "Network", "Monster voices", "UI"]
    cats.sort(key=lambda c: order.index(c) if c in order else 99)
    out = []
    for c in cats:
        es = [e for e in SD if e["cat"] == c]
        rows = []
        for e in es:
            src = mp3(e["name"])
            play = (f'<button class="play" data-snd="{src}" aria-label="Play {E(e["name"])}">▶</button>' if src else "")
            nm = namebtn(e["name"]) if src else f'<code>{E(e["name"])}</code>'
            key = f'{e["name"]} {c} {e["when"]} {e.get("trigger_use", "")} sound'
            rows.append(f'<tr data-k="{E(key)}"><td class="pl">{play}</td><td>{nm}</td><td>{E(e["when"])}</td><td class="sm2">{E(e.get("trigger_use", ""))}</td></tr>')
        out.append(f'<h3>{E(c)} <small class="note">{len(es)}</small></h3><div class="tw"><table class="names snd"><thead><tr><th></th><th>Name</th><th>When the game plays it</th><th>In a trigger</th></tr></thead><tbody>'
                   + "".join(rows) + "</tbody></table></div>")
    return "\n".join(out)

NOTE_M = ("On NIGHTMARE you take a quarter more damage, and every machine but turrets, mimics, wardens, colossi and ICE comes in twins. "
          "A hit on the weak spot does double damage (x2.5 on HARD, x3 on NIGHTMARE). Every machine wakes when it sees you within its sight or is shot, then hunts you for good; "
          "woken machines open doors, and their shots can hit other machines, which may turn on them. Each one's sight, hearing, health, speed and waking can be changed per cell in [monsters].")

EXAMPLE = open(os.path.join(HERE, "example.txt")).read()

page = open(os.path.join(HERE, "page.html")).read()
for key, val in {
    "WALLS": tiles(walls, "wall"), "FLOORS": tiles(floors, "floor"), "CEILS": tiles(ceils, "ceiling"),
    "SKIES": tiles(skies, "sky ceiling"), "SMEARS": tiles(smears, "smear"),
    "STRUCT": charcards(STRUCT, "structure"), "DOORS": charcards(DOORS, "door"),
    "PICKUPS": charcards(PICKUPS, "pickup item"), "MONSTERS": charcards(MONSTERS, "monster"),
    "DECOS": charcards(DECOS, "decoration"), "THINGS": thingrows(),
    "HEIGHTS": table(["Char", "Means"], HEIGHTS, "height"),
    "HRULES": kv(HRULES, "height rule"),
    "LIQ": table(["Map", "Liquid", "Does", "Barrel #"], LIQ, "liquid"),
    "LFX": table(["fx value", "Effect", "Console name"], [(n, w.capitalize(), w) for n, w in LFX], "light effect fx"),
    "EVENTS": table(["kind value", "Event", "a", "b"], [(k, '<span class="ev">%s<button class="q" type="button" data-tip="%s" aria-label="About %s">?</button></span>' % (E(n), E(EVENT_TIPS[k]), E(n)), a, b) for k, n, a, b in EVENTS], "event"),
    "REWARDS": E(REWARDS),
    "LIFTS": table(["mode value", "Lift"], LIFTS, "lift mode"),
    "WHENS": kv(WHENS, "trigger when"), "CMDS": kv(CMDS, "trigger command"),
    "HEADER": kv(HEADER, "header key"), "SECTIONS": kv(SECTIONS, "section"),
    "FACES": kv(FACES, "face"),
    "TURRETW": E(TURRET_W), "WAKE": E(WAKE),
    "SPAWN": chips(SPAWN, "spawn monster"), "ITEMS": chips(ITEMS, "item pickup"),
    "PUZZLES": chips(PUZZLES, "puzzle"), "SOUNDS": chips(TRIGGER_SOUNDS, "sound"),
    "NWALLS": str(len(walls)), "NFLOORS": str(len(floors)), "NCEILS": str(len(ceils)),
    "NSOUNDS": str(len(TRIGGER_SOUNDS)), "MONTAB": mon_rows(), "ITEMTAB": item_rows(), "PUZTAB": puzzle_rows(), "SNDTAB": sound_rows(), "NOTEM": E(NOTE_M), "CONSOLE": CONSOLE, "NCMDS": str(NCMDS), "EXAMPLE": E(EXAMPLE.rstrip()), "NALLSOUNDS": str(len(SOUNDS)),
}.items():
    page = page.replace("{{" + key + "}}", val)
open(OUT, "w").write(page)
print(OUT, len(page) // 1024, "KB")
