"""maker.py - INFILTRATION: ten sectors planned, laid out, furnished and lit.

The older builders lay out rooms and sprinkle things. This one PLANS a
sector first - a chain of obstacles between the start and the exit, each
with what gets you past it placed before it - then lays it out, furnishes
each room for what it's for, dresses it with the editor's tools (pictures
in pieces, filters, tints, made colours, lights that come from something,
liquids, glass), checks it can be played through in order, and gives it
the looks pass (lvldress.py) on top.

    python3 maker.py            build all ten and check them
    python3 maker.py 3          just sector 3 (-show prints its map)
    python3 maker.py --write    build, check and write levels/infil/levelN.txt
    python3 maker.py --check    check the files as they are

THE PLAN. A sector is rooms on a 4 x 4 grid of 15-cell blocks (a 64-cell
map), joined by a tree of corridors (and a loop or two inside a stretch).
The way from the start to the exit crosses GATES; whatever opens a gate is
placed in a room you reach before it - on a side branch, if there is one,
so the sector asks you to explore:

    key     a key door (R B Y) - the keycard in a room before
    pad     a keypad door - its code in a note: on a desk, a bookshelf,
            the floor, or in a safe (whose code is in another note)
    fix     a door a computer opens - a broken computer, and the repair kit
            to fix it, before it
    seal    a sealed door - its data station (the network) before it
    kick    a stronghold door: no key, just kicks - and the noise wakes
            everything near it

Rooms on the way are ENCOUNTERS (a turret line and the panel that shuts
it down, an alarm wing - guards, switches, cameras - a blackout and the
flashlight before it, a hazard to cross by jump pad, a lockdown...);
rooms off it are SIDE ROOMS (an office, a security post, a server room,
a lab, a workshop, a vault...). Each kind of room has its own ART KIT: a
feature wall in pieces, floors laid in a pattern, its own light, liquid
where it makes sense.

Nothing here reads TIMER or the game's dice: it's all seeded, so a
sector comes out the same every time it's built.
"""
import os, sys, random, math
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
SIZE = 64
lvlkit.N = SIZE
import lvldress

OUT = os.path.join(HERE, "infil")
ASSETS = os.path.dirname(HERE)
BLOCK, GRID, ORG = 15, 4, 2
SIDES = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
OPP = {"N": "S", "S": "N", "E": "W", "W": "E"}
WALLS = lvlkit.WALLS
PROBLEMS = []


def fail(msg):
    PROBLEMS.append(msg)
    print("  PROBLEM: " + msg)


# ---------------------------------------------------------------------------
# Pieces (LEVEL/PIECES.BI): H splits left | right, V top | bottom; leaves in
# preorder. A leaf is picture*turn*slide*stretch*tint*amount*RRGGBB*start*filters
# ---------------------------------------------------------------------------
def leaf(pic="", rot=0, tint=0, amt=50, col="FFFFFF", start=0, fx=""):
    f = [pic, str(rot), "0", "0", str(tint), str(amt), col, str(start), fx]
    last = 1
    if rot: last = 2
    if tint: last = 7
    if start: last = 8
    if fx: last = 9
    return "*".join(f[:last])


def solid(hexcol):
    return "#" + hexcol


# Walls: top to bottom
T_BAND = "VV..V.V.V.."      # 1 [0,1/4] 2 [1/4,1/2] 3 [1/2,3/4] 4 [3/4,7/8] 5 line [7/8,15/16] 6 skirting
T_PANEL = "VV..V.V.."       # 1 [0,1/4] 2 [1/4,1/2] 3 [1/2,3/4] 4 [3/4,7/8] 5 [7/8,1]
T_SPLIT = "V.V.V.."         # 1 [0,1/2] 2 [1/2,3/4] 3 [3/4,7/8] 4 [7/8,1]
T_LAMP = "HH.H.H..HHH...."  # a strip an eighth wide down the middle: leaves 4 and 5
T_HALF = "H.."               # left | right
# Floors: u east, v south - a strip an eighth wide along one edge
F_EDGE = {"N": ("VVV....", 0), "S": ("V.V.V..", 3), "W": ("HHH....", 0), "E": ("H.H.H..", 3)}
F_QUAD = "HV..V.."          # four quarters: NW SW NE SE


def tree_ok(t, n):
    return lvldress.tree_leaves(t) == n


# ---------------------------------------------------------------------------
# The ten
# ---------------------------------------------------------------------------
# walls: # base, N office/accent, C tech, K industrial, P secure, G special
SPECS = {
    1: dict(name="INTAKE", style="clinical", seed=11, gates=["pad", "key:r", "pad"],
            enc=["lobby", "ambush", "lasers"], side=["office", "office", "lab", "storage", "office"],
            walls=["wall-white.png", "wall-tiles.png", "wall-terminals.png", "wall-pipes.png", "wall-vault.png", "wall-biolab.png"],
            floors=["floor-white.png", "floor-lab.png", "floor-plates.png", "floor-concrete.png"],
            ceils=["ceiling-lights.png", "ceiling-vents.png"], ambient=(170, 225, 235, 255),
            mons="ggcmm", nmons=14, guns="2", puzzles="",
            story="Intake processing: the way in is through the offices. Read what people left on their desks."),
    2: dict(name="SECURITY WING", style="neon", seed=21, gates=["key:b", "pad", "key:r"],
            enc=["alarm", "alarm", "survive"], side=["security", "office", "storage", "server", "office"],
            walls=["wall-concrete.png", "wall-control.png", "wall-servers.png", "wall-grate.png", "wall-hull.png", "wall-stripes.png"],
            floors=["floor-deck.png", "floor-plates.png", "floor-circuit.png", "floor-concrete.png"],
            ceils=["ceiling-lights.png", "ceiling-cables.png"], ambient=(160, 210, 225, 255),
            mons="gg5km", nmons=16, guns="23", puzzles="",
            story="Cameras everywhere and guards who run for the alarm. Find the monitors first."),
    3: dict(name="TURRET LINE", style="data", seed=31, gates=["key:y", "fix", "pad"],
            enc=["gauntlet", "gauntlet", "nest"], side=["workshop", "server", "office", "storage", "security"],
            walls=["wall-hull.png", "wall-terminals.png", "wall-datastream.png", "wall-coils.png", "wall-turret.png", "wall-code.png"],
            floors=["floor-circuit.png", "floor-deck.png", "floor-platform.png", "floor-rustgrate.png"],
            ceils=["ceiling-cables.png", "ceiling-girders.png"], ambient=(150, 200, 190, 255),
            mons="ggh51", nmons=16, guns="23", puzzles="",
            story="The corridors are covered. Every turret line has a panel within reach - get to it."),
    4: dict(name="SPILLWAY", style="toxic", seed=41, gates=["key:r", "pad", "key:b"],
            enc=["crossing", "crossing", "fire"], side=["lab", "workshop", "office", "storage", "garden"],
            walls=["wall-greenpipes.png", "wall-biolab.png", "wall-terminals.png", "wall-pipes.png", "wall-hazard.png", "wall-slime.png"],
            floors=["floor-rustgrate.png", "floor-murky.png", "floor-hazard.png", "floor-concrete.png"],
            ceils=["ceiling-pipes.png", "ceiling-warning.png"], ambient=(150, 200, 235, 190),
            mons="wgcs6", nmons=16, guns="234", puzzles="",
            story="Acid and slime between every room. A hazmat suit, or the jump pads."),
    5: dict(name="LIGHTS OUT", style="cold", seed=51, gates=["fix", "key:y", "pad"],
            enc=["blackout", "blackout", "ambush"], side=["workshop", "office", "storage", "cold", "security"],
            walls=["wall-frost.png", "wall-cryo.png", "wall-control.png", "wall-pipes.png", "wall-hull.png", "wall-ice.png"],
            floors=["floor-frostgrate.png", "floor-ice.png", "floor-plates.png", "floor-deck.png"],
            ceils=["ceiling-frost.png", "ceiling-vents.png"], ambient=(95, 170, 205, 255),
            mons="ckmEw", nmons=16, guns="234", puzzles="",
            story="The power's failing. A flashlight, its batteries - and the eyebots that like the dark."),
    6: dict(name="THE VAULT", style="infernal", seed=61, gates=["pad", "fix", "key:y"],
            enc=["gallery", "ambush", "lasers"], side=["vault", "office", "security", "storage", "office"],
            walls=["wall-brick.png", "wall-control.png", "wall-terminals.png", "wall-girders.png", "wall-vault.png", "wall-obsidian.png"],
            floors=["floor-plates.png", "floor-deck.png", "floor-scorched.png", "floor-concrete.png"],
            ceils=["ceiling-hull.png", "ceiling-girders.png"], ambient=(160, 255, 220, 180),
            mons="gh5k6", nmons=17, guns="234)", puzzles="", kick=True,
            story="Safes, a strongroom you have to kick your way into, and a chest that bites."),
    7: dict(name="DEEP NETWORK", style="data", seed=71, gates=["seal", "pad", "seal"],
            enc=["network", "cutter", "network"], side=["server", "office", "server", "storage", "security"],
            walls=["wall-servers.png", "wall-terminals.png", "wall-datastream.png", "wall-coils.png", "wall-jack.png", "wall-code.png"],
            floors=["floor-circuit.png", "floor-glow.png", "floor-deck.png", "floor-platform.png"],
            ceils=["ceiling-cables.png", "ceiling-core.png"], ambient=(150, 170, 150, 255),
            mons="gk51E", nmons=18, guns="234)", puzzles="password, select",
            story="Sealed doors only the network opens. Jack in at each data station."),
    8: dict(name="LOW ORBIT", style="outdoor", seed=81, gates=["key:b", "pad", "key:r"],
            enc=["shaft", "crossing", "survive"], side=["storage", "workshop", "office", "lab", "security"],
            walls=["wall-hull.png", "wall-viewport.png", "wall-control.png", "wall-girders.png", "wall-transit.png", "wall-lightstrip.png"],
            floors=["floor-platform.png", "floor-deck.png", "floor-plates.png", "floor-glow.png"],
            ceils=["ceiling-girders.png", "ceiling-hull.png"], ambient=(150, 200, 190, 255),
            mons="m1Egw", nmons=18, guns="234)", puzzles="", gravity=60,
            story="Gravity at sixty percent. A jetpack, fuel, and shafts to climb."),
    9: dict(name="COMPOUND", style="neon", seed=91, gates=["key:b", "pad", "fix", "key:r"],
            enc=["alarm", "gauntlet", "crossing", "blackout"], side=["security", "office", "workshop", "server", "vault", "storage"],
            walls=["wall-concrete.png", "wall-control.png", "wall-servers.png", "wall-pipes.png", "wall-vault.png", "wall-hazard.png"],
            floors=["floor-deck.png", "floor-plates.png", "floor-circuit.png", "floor-hazard.png"],
            ceils=["ceiling-lights.png", "ceiling-warning.png"], ambient=(150, 210, 210, 255),
            mons="g5kh7", nmons=20, guns="234)", puzzles="", kick=True,
            story="Everything at once: alarms, turrets, acid, the dark."),
    10: dict(name="CORE BREACH", style="infernal", seed=101, gates=["seal", "key:y", "pad", "key:r"],
             enc=["reactor", "gauntlet", "survive", "boss"], side=["security", "server", "workshop", "office", "storage"],
             walls=["wall-reactor.png", "wall-control.png", "wall-core.png", "wall-furnace.png", "wall-vault.png", "wall-obsidian.png"],
             floors=["floor-core.png", "floor-scorched.png", "floor-molten.png", "floor-plates.png"],
             ceils=["ceiling-core.png", "ceiling-girders.png"], ambient=(150, 255, 190, 150),
             mons="h5k06", nmons=20, guns="234)", puzzles="sum",
             story="The core. Lava round it, its guardian on it."),
}

# A room kind's wall (index into walls: 0 # .. 5 G), floor (1-4), ceiling (1-2), feature picture,
# light colour, and how its feature wall's picture is filtered
KINDS = {
    "start":    dict(wall=0, floor=1, ceil=1, feat=None, light=None),
    "exit":     dict(wall=4, floor=3, ceil=2, feat=4, light=(90, 255, 120)),
    "lobby":    dict(wall=1, floor=1, ceil=1, feat=1, light=None),
    "office":   dict(wall=1, floor=2, ceil=1, feat=2, light=(255, 220, 170), fx="S-25"),
    "security": dict(wall=2, floor=3, ceil=2, feat=2, light=(255, 90, 90)),
    "server":   dict(wall=2, floor=3, ceil=2, feat=2, light=(80, 200, 255), fx="H20"),
    "lab":      dict(wall=5, floor=1, ceil=1, feat=5, light=(200, 255, 230)),
    "storage":  dict(wall=3, floor=4, ceil=2, feat=3, light=(255, 200, 120), fx="B-10S-20"),
    "workshop": dict(wall=3, floor=4, ceil=2, feat=3, light=(255, 170, 80)),
    "vault":    dict(wall=4, floor=3, ceil=2, feat=4, light=(255, 210, 90), fx="H-15S20"),
    "cold":     dict(wall=5, floor=2, ceil=1, feat=5, light=(160, 230, 255)),
    "garden":   dict(wall=5, floor=4, ceil=1, feat=5, light=(140, 255, 120)),
    "key":      dict(wall=4, floor=3, ceil=2, feat=4, light=None),
    # encounters
    "ambush":   dict(wall=0, floor=3, ceil=2, feat=3, light=(255, 120, 80)),
    "survive":  dict(wall=3, floor=4, ceil=2, feat=3, light=(255, 80, 60)),
    "lasers":   dict(wall=2, floor=3, ceil=2, feat=2, light=(255, 60, 120)),
    "cutter":   dict(wall=2, floor=3, ceil=2, feat=2, light=(255, 60, 120)),
    "alarm":    dict(wall=2, floor=2, ceil=1, feat=1, light=(255, 230, 200)),
    "gauntlet": dict(wall=4, floor=3, ceil=2, feat=4, light=(255, 140, 60)),
    "nest":     dict(wall=5, floor=4, ceil=2, feat=5, light=(200, 80, 255)),
    "crossing": dict(wall=5, floor=3, ceil=2, feat=5, light=(140, 255, 90)),
    "fire":     dict(wall=3, floor=3, ceil=2, feat=3, light=(255, 120, 40)),
    "blackout": dict(wall=3, floor=4, ceil=2, feat=3, light=(120, 180, 255)),
    "gallery":  dict(wall=1, floor=2, ceil=1, feat=1, light=(255, 220, 160)),
    "network":  dict(wall=2, floor=3, ceil=2, feat=2, light=(90, 255, 220)),
    "shaft":    dict(wall=3, floor=4, ceil=2, feat=3, light=(160, 200, 255)),
    "reactor":  dict(wall=5, floor=3, ceil=1, feat=5, light=(255, 120, 40)),
    "boss":     dict(wall=5, floor=1, ceil=1, feat=5, light=(255, 60, 40)),
}
KEY_HEX = {"r": "FF3B3B", "b": "3B7BFF", "y": "FFD23B"}


def hx(c):
    return "%02X%02X%02X" % tuple(max(0, min(255, int(v))) for v in c)


def mixc(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


# ---------------------------------------------------------------------------
# The map
# ---------------------------------------------------------------------------
class Room:
    def __init__(self, rid, i, j):
        self.id, self.i, self.j = rid, i, j
        self.kind = "lobby"
        self.zone = 0          # gates crossed to get here
        self.path = False      # on the way from start to exit
        self.links = {}        # side -> (other room, corridor cells, door cell or None)
        self.mouths = set()    # room cells where a corridor comes in
        self.lane = set()      # cells kept clear between its ways in
        self.used = set()      # cells taken by something
        self.fe, self.ce = 0, 16
        self.zi = None         # its [zones] index

    def cells(self):
        return [(x, y) for y in range(self.y0, self.y1 + 1) for x in range(self.x0, self.x1 + 1)]

    @property
    def cx(self):
        return (self.x0 + self.x1) // 2

    @property
    def cy(self):
        return (self.y0 + self.y1) // 2


class Level(lvlkit.Map):
    def __init__(self, spec, k):
        super().__init__("#")
        self.spec, self.k = spec, k
        self.rng = random.Random(spec["seed"] * 7919)
        self.faces = {}        # (x, y, face) -> [faces] line
        self.things, self.notes, self.doorl, self.smears = [], [], [], []
        self.glass, self.looks, self.fuel, self.difficulty, self.barrels = [], [], [], [], []
        self.mons = {}         # (x, y) -> [monsters] line's numbers after x, y
        self.loot = []
        self.puzzles = spec.get("puzzles", "")
        self.wet = [["."] * SIZE for _ in range(SIZE)]
        self.opac = [["."] * SIZE for _ in range(SIZE)]
        self.rooms = {}
        self.knowledge = []    # (kind, needs, opens) for the progression check

    # --- small helpers
    def inside(self, x, y):
        return 0 < x < SIZE - 1 and 0 < y < SIZE - 1

    def is_floor(self, x, y):
        return self.inside(x, y) and self.g[y][x] == "."

    def wall_sides(self, x, y):
        return [s for s, (dx, dy) in SIDES.items() if self.g[y + dy][x + dx] in WALLS]

    def thing(self, x, y, kind, *extra):
        self.g[y][x] = '"'
        self.things.append(", ".join([str(x), str(y), kind] + [str(e) for e in extra]))

    def note(self, x, y, text, pic="-"):
        self.notes.append("%d, %d, %s, %s" % (x, y, pic, text))

    def face(self, x, y, f, tree, leaves):
        assert tree_ok(tree, len(leaves)), (tree, leaves)
        self.faces[(x, y, f)] = "%d, %d, %s, 3, %s, %s" % (x, y, f, tree, "|".join(leaves))

    def face_pic(self, x, y, f, pic):
        self.faces[(x, y, f)] = "%d, %d, %s, 0, %s" % (x, y, f, pic)

    def mon(self, x, y, ch, line=None, only=None):
        self.g[y][x] = ch
        if line:
            self.mons[(x, y)] = line
        if only:
            self.difficulty.append("%d, %d, %s" % (x, y, only))

    def pcount(self):
        return sum(1 for v in self.faces.values() if ", 3, " in v)

    # --- output
    def level_dict(self, label):
        sp = self.spec
        lv = dict(label=label, name="SECTOR %d: %s" % (self.k, sp["name"]), walls=sp["walls"], floors=sp["floors"],
                  ceils=sp["ceils"], ambient=sp["ambient"], zones=self.zones, lights=self.lights, events=self.events,
                  rows=self.rows(), lifts=self.lifts, floor=["".join(r) for r in self.fh],
                  ceiling=["".join(r) for r in self.ch], triggers=self.triggers,
                  faces=[self.faces[k] for k in sorted(self.faces, key=lambda t: (t[1], t[0], t[2]))],
                  pads=[], blocks=list(self.blocks), nudges=list(self.nudges),
                  monsters=[(x, y) + tuple(v) for (x, y), v in sorted(self.mons.items(), key=lambda t: (t[0][1], t[0][0]))],
                  loot=list(self.loot), liquid=["".join(r) for r in self.lq], liquid_depth=["".join(r) for r in self.ld],
                  liquid_opacity_rows=["".join(r) for r in self.opac], wetness_rows=["".join(r) for r in self.wet],
                  cell_lights=list(self.cell_lights), barrels=list(self.barrels),
                  doors=list(self.doorl), things=list(self.things), notes=list(self.notes), smears=list(self.smears),
                  fuel=list(self.fuel), difficulty=list(self.difficulty), looks=list(self.looks), glass=list(self.glass),
                  puzzles=self.puzzles, droids=sp.get("droids", 3))
        if sp.get("gravity"):
            lv["gravity"] = sp["gravity"]
        lv["wetness"] = 3
        lv["glass_reflect"] = 4
        return lv


# ---------------------------------------------------------------------------
# 1. The plan and the layout
# ---------------------------------------------------------------------------
def layout(L):
    rng = L.rng
    sp = L.spec
    want = len(sp["gates"]) + len(sp["enc"]) + len(sp["side"]) + 3
    want = min(16, max(11, want))
    # a tree over the grid: grown from a corner, a random neighbour of the tree at a time
    start = rng.choice([(0, 0), (3, 0), (0, 3), (3, 3)])
    tree, edges, last = {start}, [], start
    while len(tree) < want:
        cand = [(a, (a[0] + dx, a[1] + dy)) for a in tree for dx, dy in SIDES.values()
                if 0 <= a[0] + dx < GRID and 0 <= a[1] + dy < GRID and (a[0] + dx, a[1] + dy) not in tree]
        near = [c for c in cand if c[0] == last]
        a, b = rng.choice(near) if near and rng.random() < 0.7 else rng.choice(cand)   # (mostly winding on: a longer way through)
        tree.add(b)
        edges.append((a, b))
        last = b
    adj = {c: [] for c in tree}
    for a, b in edges:
        adj[a].append(b); adj[b].append(a)

    def bfs(src):
        d, par = {src: 0}, {src: None}
        q = deque([src])
        while q:
            c = q.popleft()
            for n in adj[c]:
                if n not in d:
                    d[n] = d[c] + 1; par[n] = c; q.append(n)
        return d, par
    d, par = bfs(start)
    exitc = max(d, key=lambda c: (d[c], rng.random()))
    path = [exitc]
    while par[path[-1]] is not None:
        path.append(par[path[-1]])
    path.reverse()
    if len(path) < len(sp["gates"]) + 2:
        return None
    # rooms
    for idx, c in enumerate(sorted(tree)):
        r = Room(idx, *c)
        bx, by = ORG + c[0] * BLOCK, ORG + c[1] * BLOCK
        r.x0 = bx + 1 + rng.randint(0, 3); r.x1 = bx + 13 - rng.randint(0, 3)
        r.y0 = by + 1 + rng.randint(0, 3); r.y1 = by + 13 - rng.randint(0, 3)
        L.rooms[c] = r
    for c in path:
        L.rooms[c].path = True
    # gates on the way: spread along it (never the first step out of the start)
    ng = len(sp["gates"])
    steps = len(path) - 1
    if steps - 1 < ng:
        return None
    # how many rooms come before each step out along the way (the side branches hanging off it count too)
    onpath = set(path)

    def branch(c, prev):
        n, q, seen = 0, [c], {c, prev}
        while q:
            x = q.pop(); n += 1
            for y in adj[x]:
                if y not in seen and y not in onpath:
                    seen.add(y); q.append(y)
        return n
    before, run = [], 0
    for s in range(steps + 1):
        run += branch(path[s], None)
        before.append(run)   # (rooms up to and including path[s] and its branches)
    total = before[-1]
    # gates where the rooms split most evenly, in order, never on the first or last step out
    at, lo = [], 1
    for g in range(ng):
        want = (g + 1) * total / (ng + 1)
        hi = steps - (ng - g)
        cands = list(range(lo, hi + 1)) or [lo]
        s_best = min(cands, key=lambda s: (abs(before[s] - want), s))
        at.append(s_best)
        lo = s_best + 1
    if len(set(at)) < ng or at[-1] > steps - 1:
        return None
    gate_at = {}   # (a, b) edge on the path -> gate kind
    for g, s in enumerate(at):
        gate_at[(path[s], path[s + 1])] = sp["gates"][g]
    # zones: gates crossed on the tree path from the start
    zone = {start: 0}
    q = deque([start])
    while q:
        c = q.popleft()
        for n in adj[c]:
            if n not in zone:
                zone[n] = zone[c] + (1 if (c, n) in gate_at else 0)
                q.append(n)
    for c, r in L.rooms.items():
        r.zone = zone[c]
    sizes = [sum(1 for c in zone if zone[c] == z) for z in range(ng + 1)]
    if max(sizes) > 0.4 * len(zone) or min(sizes) < 2:
        return None   # (a stretch with most of the sector, or one with a single room: try another)
    L.path, L.adj, L.gate_at, L.start_c, L.exit_c = path, adj, gate_at, start, exitc
    L.extra = []
    # a loop or two: neighbours in the same zone not yet joined
    loops = [(a, b) for a in tree for b in tree if a < b and abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1
             and b not in adj[a] and zone[a] == zone[b]]
    rng.shuffle(loops)
    for a, b in loops[:2]:
        adj[a].append(b); adj[b].append(a); L.extra.append((a, b))
    return True


def carve(L):
    rng = L.rng
    for c, r in L.rooms.items():
        cut = 2 if (r.x1 - r.x0 >= 9 and r.y1 - r.y0 >= 9 and rng.random() < 0.35 and r.kind not in ("crossing", "gauntlet")) else 0
        if cut:
            L.octagon(r.x0, r.y0, r.x1, r.y1, cut)
        else:
            L.rect(r.x0, r.y0, r.x1, r.y1, ".")
    done = set()
    for a in L.rooms:
        for b in L.adj[a]:
            if (b, a) in done:
                continue
            done.add((a, b))
            join(L, L.rooms[a], L.rooms[b], L.gate_at.get((a, b)) or L.gate_at.get((b, a)), (a, b) in L.gate_at)


def join(L, A, B, gate, forward):
    """A corridor between neighbours A and B (straight: every room spans its
    block's middle five rows and columns). A gate's door is at the end by
    the room past it."""
    rng = L.rng
    if A.j == B.j:   # side by side
        if A.i > B.i:
            A, B = B, A; forward = not forward
        lo, hi = max(A.y0, B.y0) + 2, min(A.y1, B.y1) - 2
        y = rng.randint(lo, hi)
        cells = [(x, y) for x in range(A.x1 + 1, B.x0)]
        wide = gate is None and rng.random() < 0.4
        if wide:
            cells += [(x, y + 1) for x in range(A.x1 + 1, B.x0)]
        ma, mb = (A.x1, y), (B.x0, y)
        sa, sb = "E", "W"
    else:
        if A.j > B.j:
            A, B = B, A; forward = not forward
        lo, hi = max(A.x0, B.x0) + 2, min(A.x1, B.x1) - 2
        x = rng.randint(lo, hi)
        cells = [(x, y) for y in range(A.y1 + 1, B.y0)]
        wide = gate is None and rng.random() < 0.4
        if wide:
            cells += [(x + 1, y) for y in range(A.y1 + 1, B.y0)]
        ma, mb = (x, A.y1), (x, B.y0)
        sa, sb = "S", "N"
    for (x, y) in cells:
        L.g[y][x] = "."
    # the rooms' edge cells where it comes in are floor (a cut corner never reaches the middle)
    for (x, y) in (ma, mb):
        L.g[y][x] = "."
    A.mouths.add(ma); B.mouths.add(mb)
    if wide:
        if sa == "E":
            A.mouths.add((ma[0], ma[1] + 1)); B.mouths.add((mb[0], mb[1] + 1))
        else:
            A.mouths.add((ma[0] + 1, ma[1])); B.mouths.add((mb[0] + 1, mb[1]))
    door = None
    if gate:
        later = B if forward else A
        door = cells[-1] if later is B else cells[0]
    elif not wide and rng.random() < 0.5:
        door = cells[rng.choice([0, -1])]
    A.links[sa] = (B, cells, door)
    B.links[sb] = (A, cells, door)
    if door:
        later = (B if forward else A) if gate else None
        L.corr_doors = getattr(L, "corr_doors", [])
        L.corr_doors.append((door, gate, later))


def heights(L):
    """Each room its own floor and ceiling: halls tall, offices low, a few raised."""
    rng = L.rng
    for r in L.rooms.values():
        big = (r.x1 - r.x0 + 1) * (r.y1 - r.y0 + 1)
        r.ce = 24 if big >= 110 else (16 if big >= 70 else 12)
        if r.kind in ("office", "security", "storage", "workshop"):
            r.ce = min(r.ce, 12)
        if r.kind in ("shaft", "reactor", "boss", "crossing", "gauntlet", "network"):
            r.ce = 32 if r.kind == "shaft" else 24
        r.fe = 0
        L.ceiling(r.x0 - 1, r.y0 - 1, r.x1 + 1, r.y1 + 1, r.ce, only_raise=False)
        r.zi = len(L.zones)
        kd = KINDS.get(r.kind, KINDS["lobby"])
        L.zone(r.x0, r.y0, r.x1, r.y1, kd["floor"], kd["ceil"])
        L.paint(r.x0 - 1, r.y0 - 1, r.x1 + 1, r.y1 + 1, "#NCKPG"[kd["wall"]])
    # corridors keep a wall's height (doors want walls round them)


# ---------------------------------------------------------------------------
# 2. What goes where: kinds of rooms, gates and their answers
# ---------------------------------------------------------------------------
def assign(L):
    sp, rng = L.spec, L.rng
    rooms = L.rooms
    st, ex = rooms[L.start_c], rooms[L.exit_c]
    st.kind, ex.kind = "start", "exit"
    pathrooms = [rooms[c] for c in L.path[1:-1]]
    enc = list(sp["enc"])
    # encounters: each its own room on the way, spread evenly (a boss in the last before the exit)
    n = len(pathrooms)
    if "boss" in enc and n:
        pathrooms[-1].kind = "boss"
        enc.remove("boss")
        n -= 1
    if n and enc:
        picks = sorted(set(min(n - 1, int((i + 0.5) * n / len(enc))) for i in range(len(enc))))
        for kind, p in zip(enc, picks):
            pathrooms[p].kind = kind
    left = [r for r in rooms.values() if r.kind == "lobby" and r is not st and r is not ex]
    side = [r for r in left if not r.path]
    rest = [r for r in left if r.path]
    rng.shuffle(side)
    want = list(sp["side"])
    if sp.get("kick"):   # a strongroom: a dead end off the way, behind a stronghold door
        ends = [r for r in side if len(r.links) == 1] or [r for r in rest if len(r.links) == 1]
        if ends:
            ends[0].kind = "vault"; ends[0].strong = True
            (side if ends[0] in side else rest).remove(ends[0])
            if "vault" in want:
                want.remove("vault")
    for r in side + rest:   # (side rooms first: what the sector's about goes off the way where it can)
        if want:
            r.kind = want.pop(0)
        else:
            r.kind = rng.choice(sp["side"] + ["lobby"])


def answer_room(L, zone, kinds=None, avoid=()):
    """A room you reach before a gate out of `zone`: a side room of that
    zone if there is one (exploring pays), else one on the way."""
    rs = [r for r in L.rooms.values() if r.zone <= zone and r.kind not in ("exit",) and r not in avoid]
    best = [r for r in rs if r.zone == zone and not r.path and (not kinds or r.kind in kinds)]
    best = best or [r for r in rs if r.zone == zone and not r.path]
    best = best or [r for r in rs if r.zone == zone and r.kind not in ("start",)]
    best = best or rs
    return L.rng.choice(best)


# ---------------------------------------------------------------------------
# 3. Spots in a room
# ---------------------------------------------------------------------------
def lane(L, r):
    """Cells kept clear: the straight lines between the room's ways in, and round them."""
    ms = sorted(r.mouths)
    keep = set()
    for m in ms:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                keep.add((m[0] + dx, m[1] + dy))
    for a in ms:
        for b in ms:
            if a < b:   # an L: across, then down
                for x in range(min(a[0], b[0]), max(a[0], b[0]) + 1):
                    keep.add((x, a[1]))
                for y in range(min(a[1], b[1]), max(a[1], b[1]) + 1):
                    keep.add((b[0], y))
    if len(ms) == 1:   # a dead end: a way to the middle
        a = ms[0]
        for x in range(min(a[0], r.cx), max(a[0], r.cx) + 1):
            keep.add((x, a[1]))
        for y in range(min(a[1], r.cy), max(a[1], r.cy) + 1):
            keep.add((r.cx, y))
    r.lane = keep


def free(L, r, c):
    x, y = c
    return L.g[y][x] == "." and c not in r.lane and c not in r.used and r.x0 <= x <= r.x1 and r.y0 <= y <= r.y1


def wall_spots(L, r):
    """Floor cells with exactly one wall side (furniture backs onto it): (x, y, side the wall is on)."""
    out = []
    for (x, y) in r.cells():
        if not free(L, r, (x, y)):
            continue
        ws = [s for s in L.wall_sides(x, y)]
        if len(ws) == 1 and not any(L.g[y + dy][x + dx] in "/\\" for dx, dy in SIDES.values()):
            out.append((x, y, ws[0]))
    L.rng.shuffle(out)
    return out


def take(r, c):
    r.used.add(c)


def floor_spots(L, r, margin=1):
    out = [(x, y) for (x, y) in r.cells() if free(L, r, (x, y)) and r.x0 + margin <= x <= r.x1 - margin and r.y0 + margin <= y <= r.y1 - margin]
    L.rng.shuffle(out)
    return out


def put_wall(L, r, ch=None, thing=None, extra=(), spots=None):
    spots = spots if spots is not None else wall_spots(L, r)
    for (x, y, s) in spots:
        if free(L, r, (x, y)):
            if thing:
                L.thing(x, y, thing, *extra)
            else:
                L.g[y][x] = ch
            take(r, (x, y))
            return (x, y, s)
    return None


def wall_cell(L, r, avoid_mouths=3):
    """A wall cell of room r's own wall (not a corner, not by a corridor) with floor in front: (wx, wy, face, fx, fy)."""
    out = []
    for (x, y) in r.cells():
        if L.g[y][x] != "." or (x, y) in r.used:
            continue
        for s, (dx, dy) in SIDES.items():
            wx, wy = x + dx, y + dy
            if L.g[wy][wx] in WALLS and L.inside(wx, wy) and wx not in (0, SIZE - 1) and wy not in (0, SIZE - 1):
                along = [(wx + dy, wy + dx), (wx - dy, wy - dx)]
                if all(L.g[ay][ax] in WALLS for ax, ay in along) and all(abs(x - m[0]) + abs(y - m[1]) > avoid_mouths for m in r.mouths):
                    out.append((wx, wy, OPP[s], x, y))
    L.rng.shuffle(out)
    return out


# ---------------------------------------------------------------------------
# 4. Gates and their answers
# ---------------------------------------------------------------------------
NOTE_WORDS = [
    "Door code for {where}: {code}. Don't write it down. - M.",
    "Reminder: the {where} keypad is {code}|Change it next week.",
    "{code} - the {where} door.|Burn this.",
    "Shift log: {where} access {code}|Night crew only.",
]


def gates(L):
    sp, rng = L.spec, L.rng
    keys_done = set()
    for (door, gate, later) in getattr(L, "corr_doors", []):
        x, y = door
        if gate is None:
            L.g[y][x] = rng.choice("DDXH")
            continue
        z = later.zone - 1   # the zone before it
        where = later.kind.upper() if later.kind not in ("lobby",) else "SECTOR %d" % (later.zone + 1)
        if gate.startswith("key:"):
            c = gate[4:]
            L.g[y][x] = c.upper()
            if c not in keys_done:
                r = answer_room(L, z, ("storage", "security", "office", "lab", "workshop"))
                spot = (floor_spots(L, r, 2) or floor_spots(L, r, 1))
                if spot:
                    kx, ky = spot[0]
                    L.g[ky][kx] = c; take(r, (kx, ky))
                    r.keyed = c
                    keys_done.add(c)
                else:
                    fail("no room for keycard %s" % c)
        elif gate == "pad":
            L.g[y][x] = "D"
            L.doorl.append("%d, %d, 0, ?" % (x, y))
            r = answer_room(L, z, ("office", "security", "lab"))
            how = rng.choice(["desk", "desk", "shelf", "floor", "safe"])
            text = rng.choice(NOTE_WORDS).format(where=where, code="{code %d %d}" % (x, y))
            place_note(L, r, how, text, z)
        elif gate == "fix":
            L.g[y][x] = "D"
            L.doorl.append("%d, %d, 0, ?" % (x, y))   # (a keypad too - but nobody left its code: the computer opens it)
            r = answer_room(L, z, ("server", "security", "office"))
            pc = put_wall(L, r, thing="brokenpc", extra=(x, y))
            r2 = answer_room(L, z, ("workshop", "storage"), avoid=(r,)) if pc else None
            kit = floor_spots(L, r2, 1) if r2 else None
            if not pc or not kit:
                fail("no room for the broken computer or its repair kit")
                continue
            L.thing(kit[0][0], kit[0][1], "repairkit"); take(r2, kit[0])
            L.triggers.append("hack %d %d : message The door to the %s unlocks." % (pc[0], pc[1], where))
            L.knowledge.append(("fix", (pc[0], pc[1]), (kit[0][0], kit[0][1]), (x, y)))
        elif gate == "seal":
            L.g[y][x] = "!"
            r = answer_room(L, z, ("server", "network"))
            if r.kind in ("lobby", "office", "storage", "lab", "workshop"):
                r.kind = "server"   # (a station's room is a server room - an encounter keeps what it is)
            st = wall_cell(L, r)
            if not st:
                fail("no wall for a data station")
                continue
            wx, wy, f, fx, fy = st[0]
            L.g[wy][wx] = "@"
            take(r, (fx, fy))
            L.knowledge.append(("seal", (wx, wy), (x, y)))
        elif gate == "kick":
            L.g[y][x] = "D"
            L.doorl.append("%d, %d, %d," % (x, y, rng.randint(5, 8)))
    # a strongroom off the way
    for r in L.rooms.values():
        if getattr(r, "strong", False):
            for s, (o, cells, door) in r.links.items():
                d = cells[-1] if (cells[-1][0] in range(r.x0 - 1, r.x1 + 2) and cells[-1][1] in range(r.y0 - 1, r.y1 + 2)) else cells[0]
                if L.g[d[1]][d[0]] in ".DXH" and all(L.g[d[1] + dy][d[0] + dx] in WALLS for dx, dy in ((0, 1), (0, -1))) \
                        or all(L.g[d[1] + dy][d[0] + dx] in WALLS for dx, dy in ((1, 0), (-1, 0))):
                    L.g[d[1]][d[0]] = "D"
                    L.doorl.append("%d, %d, %d," % (d[0], d[1], rng.randint(6, 9)))
                    L.triggers.append("enter %d %d %d %d : message STRONGROOM - kick it in (F). Everything near will hear." % (d[0], d[1], d[0], d[1]))


def terminals(L):
    """A code terminal ($) for each puzzle the sector names - only where no door is within 7 cells
    (using one locks every door that near until it's solved: it mustn't shut the way on)."""
    want = [p.strip() for p in L.spec.get("puzzles", "").split(",") if p.strip()]
    doors = [(x, y) for y in range(SIZE) for x in range(SIZE) if L.g[y][x] in lvlkit.DOORS]
    got = []
    rooms = sorted(L.rooms.values(), key=lambda r: (r.kind not in ("network", "server"), r.path, r.zone))
    for r in rooms:
        if len(got) >= len(want):
            break
        for (wx, wy, f, fx, fy) in wall_cell(L, r):
            if all(max(abs(wx - dx), abs(wy - dy)) > 7 for dx, dy in doors) and (fx, fy) not in r.used:
                L.g[wy][wx] = "$"; take(r, (fx, fy)); r.lane.add((fx, fy))
                got.append(want[len(got)])
                break
    L.puzzles = ", ".join(got)


def place_note(L, r, how, text, z):
    rng = L.rng
    if how == "safe":   # the code's in a safe, and the safe's code in a note elsewhere
        s = put_wall(L, r, thing="safe", extra=("?",))
        if s:
            L.note(s[0], s[1], text)
            r2 = answer_room(L, z, ("office", "security"), avoid=(r,))
            place_note(L, r2, "desk", "Office safe: {code %d %d}|Keep it locked." % (s[0], s[1]), z)
            return
        how = "desk"
    if how == "desk":
        s = put_wall(L, r, "d")
        if s:
            L.note(s[0], s[1], text)
            ch = [(s[0] + dx, s[1] + dy) for dx, dy in SIDES.values() if free(L, r, (s[0] + dx, s[1] + dy)) and L.g[s[1] + dy][s[0] + dx] == "."]
            if ch:
                L.g[ch[0][1]][ch[0][0]] = "Z"; take(r, ch[0])
            return
    if how == "shelf":
        s = put_wall(L, r, thing="bookshelf")
        if s:
            L.note(s[0], s[1], text)
            return
    f = floor_spots(L, r, 1)
    if not f:
        fail("no room for a note in %s" % r.kind)
        return
    L.g[f[0][1]][f[0][0]] = "'"
    take(r, f[0])
    L.note(f[0][0], f[0][1], text)


# ---------------------------------------------------------------------------
# 5. Encounters and side rooms (what's in them - gameplay)
# ---------------------------------------------------------------------------
def furnish(L, r):
    rng = L.rng
    k = r.kind
    W = r.x1 - r.x0 + 1
    H = r.y1 - r.y0 + 1
    if k == "start":
        sx, sy = r.cx, r.cy
        for m in sorted(r.mouths):   # face the way out
            dx, dy = m[0] - sx, m[1] - sy
            ch = (">" if dx > 0 else "<") if abs(dx) >= abs(dy) else ("v" if dy > 0 else "^")
            break
        else:
            ch = ">"
        L.g[sy][sx] = ch; take(r, (sx, sy))
        for _ in range(2):
            put_wall(L, r, rng.choice("tU"))
    elif k == "exit":
        w = wall_cell(L, r, 2)
        if w:
            wx, wy, f, fx, fy = w[0]
            L.g[wy][wx] = "E"; take(r, (fx, fy))
            L.exit_face = (wx, wy, f)
        else:
            fail("no wall for the exit")
    elif k == "office":
        for _ in range(rng.randint(2, 4)):
            s = put_wall(L, r, "d")
            if s:
                ch = [(s[0] + dx, s[1] + dy) for dx, dy in SIDES.values() if free(L, r, (s[0] + dx, s[1] + dy))]
                if ch:
                    L.g[ch[0][1]][ch[0][0]] = "Z"; take(r, ch[0])
        put_wall(L, r, thing="bookshelf")
        put_wall(L, r, "p")
        put_wall(L, r, "t")
    elif k == "security":
        cams = [(rr, wall_spots(L, rr)) for rr in L.rooms.values() if rr.kind in ("alarm", "gauntlet", "vault", "lobby", "server") and rr.zone >= r.zone]
        n = 0
        for rr, spots in cams[:4]:
            s = put_wall(L, rr, thing="camera", extra=("CAM %s" % rr.kind.upper(),), spots=spots)
            n += 1 if s else 0
        if n:
            put_wall(L, r, thing="secmon")
        if any(rr.kind == "alarm" for rr in L.rooms.values()):
            put_wall(L, r, thing="alarmpc")
        put_wall(L, r, "A"); put_wall(L, r, "F"); put_wall(L, r, "U")
    elif k == "server":
        for _ in range(rng.randint(4, 7)):
            put_wall(L, r, "l")
        put_wall(L, r, "A")
    elif k == "lab":
        for ch in "JJIO":
            put_wall(L, r, ch)
    elif k in ("storage", "workshop"):
        for (x, y) in floor_spots(L, r, 2)[:rng.randint(3, 6)]:
            L.g[y][x] = rng.choice("xxxo:" if k == "storage" else "xxof")
            take(r, (x, y))
            if L.g[y][x] == ":":
                L.barrels.append((x, y, rng.choice([1, 2, 3, 5]), rng.randint(1, 3)))
        if k == "workshop":
            put_wall(L, r, "L"); put_wall(L, r, "W")
    elif k == "cold":
        for ch in "OOI":
            put_wall(L, r, ch)
    elif k == "garden":
        for _ in range(5):
            put_wall(L, r, "p")
    elif k == "vault":
        put_wall(L, r, ch="[")
        put_wall(L, r, ch="]")   # (one of them bites)
        s = put_wall(L, r, thing="safe", extra=("?",))
        if s:
            o = answer_room(L, max(0, r.zone), ("office", "security"), avoid=(r,))
            place_note(L, o, "desk", "Strongroom safe: {code %d %d}" % (s[0], s[1]), r.zone)
        for (x, y) in floor_spots(L, r, 2)[:2]:
            L.g[y][x] = rng.choice("q*"); take(r, (x, y))
    elif k == "lobby":
        put_wall(L, r, "Q"); put_wall(L, r, "p"); put_wall(L, r, "n")
    # --- encounters
    elif k == "ambush":
        L.event(1, r.x0, r.y0, r.x1, r.y1, 4 + L.k // 2, 0, 9)
        for (x, y) in floor_spots(L, r, 2)[:4]:
            L.thing(x, y, "table"); take(r, (x, y))
    elif k == "survive":
        L.event(2, r.x0, r.y0, r.x1, r.y1, 20 + 2 * L.k, 100, 13)
        for (x, y) in floor_spots(L, r, 2)[:3]:
            L.g[y][x] = "x"; take(r, (x, y))
    elif k == "lasers":
        cols = [x for x in range(r.x0 + 2, r.x1 - 1, 3)]
        for i, x in enumerate(cols[:3]):
            L.event(9, x, r.y0, x, r.y1, 60 + 20 * i, 60, 0)
    elif k == "cutter":
        L.event(10, r.x0, r.y0, r.x1, r.y1, 200, 0, 0)
    elif k == "fire":
        L.event(12, r.x0 + 1, r.y0 + 1, r.x1 - 1, r.y1 - 1, 90, 120, 0)
    elif k == "nest":
        for (x, y) in floor_spots(L, r, 2)[:2]:
            L.g[y][x] = "S"; take(r, (x, y))
        L.event(5, r.x0, r.y0, r.x1, r.y1, 4, 180, 14)
    elif k == "gallery":
        for (x, y) in floor_spots(L, r, 1)[:7]:
            L.g[y][x] = rng.choice("xop"); take(r, (x, y))
        L.event(4, r.x0, r.y0, r.x1, r.y1, 25, 0, 13)
    elif k == "alarm":
        alarm_wing(L, r)
    elif k == "gauntlet":
        gauntlet(L, r)
    elif k == "blackout":
        blackout(L, r)
    elif k == "crossing":
        crossing(L, r)
    elif k == "network":
        for _ in range(3):
            put_wall(L, r, "l")
        put_wall(L, r, "A")
    elif k == "shaft":
        shaft(L, r)
    elif k == "reactor":
        reactor(L, r)
    elif k == "boss":
        boss(L, r)


def alarm_wing(L, r):
    """Guards and the switches they run for; the wing glows red while the alarm sounds."""
    rng = L.rng
    sw = []
    for _ in range(2):
        s = put_wall(L, r, thing="alarm")
        if s:
            sw.append(s)
    for (x, y) in floor_spots(L, r, 2)[:2 + L.k // 4]:
        L.thing(x, y, "guard"); take(r, (x, y))
    for (x, y) in floor_spots(L, r, 2)[:2]:
        L.thing(x, y, "table"); take(r, (x, y))
    box = (r.x0 - 1, r.y0 - 1, r.x1 + 1, r.y1 + 1)
    L.triggers.append("alarm : celllight %d %d %d %d 150 FF2020 pulse ; message ALARM - every machine near here is awake" % box)
    L.triggers.append("calm : celllight %d %d %d %d off" % box)
    r.switches = sw


def gauntlet(L, r):
    """A room covered by wall turrets, cover to move between, and the panel that shuts them off - by the way in."""
    rng = L.rng
    entry = min(r.mouths, key=lambda m: (m[0] - r.cx) ** 2 + (m[1] - r.cy) ** 2)
    far = [(x, y, s) for (x, y, s) in wall_spots(L, r) if abs(x - entry[0]) + abs(y - entry[1]) >= 6]
    n = 0
    weap = [1, 0, 6, 3, 2]
    for (x, y, s) in far:
        if n >= 2 + L.k // 4 or not free(L, r, (x, y)):
            continue
        L.mon(x, y, "|", (16, 0, 100, 100, 0, rng.choice(weap[:2 + L.k // 3])))
        take(r, (x, y))
        n += 1
    # cover: low crates and table halfway
    for (x, y) in floor_spots(L, r, 2)[:3]:
        L.thing(x, y, "table"); take(r, (x, y))
    # the panel: a wall cell near the way in
    pw = [w for w in wall_cell(L, r, 1) if 2 <= abs(w[3] - entry[0]) + abs(w[4] - entry[1]) <= 4]
    if pw:
        wx, wy, f, fx, fy = pw[0]
        L.g[wy][wx] = ";"; take(r, (fx, fy))
        r.panel = (wx, wy, f)
    else:
        fail("gauntlet: no wall for its panel")


def blackout(L, r):
    """The lights die; crawlers come out of the dark. The flashlight's in a room before."""
    rng = L.rng
    L.event(11, r.x0, r.y0, r.x1, r.y1, 25, 6 + L.k // 2, 0)
    if not getattr(L, "flash_done", False):
        a = answer_room(L, max(0, r.zone), ("workshop", "storage", "security"), avoid=(r,))
        f = floor_spots(L, a, 1)
        if f:
            L.thing(f[0][0], f[0][1], "flashlight"); take(a, f[0])
            if len(f) > 1:
                L.thing(f[1][0], f[1][1], "battery"); take(a, f[1])
            L.flash_done = True
    L.cell_light(r.x0, r.y0, r.x1, r.y1, 40, 120, 150, 220, 5)   # (dying already)


def crossing(L, r):
    """A band of acid (or slime, or lava) across the room: wade it, wear the hazmat suit, or take the jump pad."""
    rng = L.rng
    kind = rng.choice("aas") if L.k < 10 else "l"
    horiz = (r.x1 - r.x0) >= (r.y1 - r.y0)
    if horiz:   # a band north-south across the middle, crossed going east
        x0 = r.cx - 1; x1 = r.cx + 1
        band = [(x, y) for x in range(x0, x1 + 1) for y in range(r.y0, r.y1 + 1)]
    else:
        y0 = r.cy - 1; y1 = r.cy + 1
        band = [(x, y) for y in range(y0, y1 + 1) for x in range(r.x0, r.x1 + 1)]
    for (x, y) in band:
        if L.g[y][x] == ".":
            L.fh[y][x] = lvlkit.hchar(-2)   # (two down: a step - you can climb back out)
            L.liquid(x, y, kind, 2)
            L.opac[y][x] = "4"
            take(r, (x, y))
    r.lane = {c for c in r.lane if c not in band}
    # the pad: two cells before the band, aimed across (4 cells past its far edge)
    if horiz:
        px, py, d = x0 - 2, r.cy + (2 if r.cy + 2 <= r.y1 - 1 else -2), 0
    else:
        px, py, d = r.cx + (2 if r.cx + 2 <= r.x1 - 1 else -2), y0 - 2, 90
    g = (L.spec.get("gravity") or 100) / 100
    dist = 6.0
    power = int(round(math.sqrt(dist * 100 * g)))
    if L.g[py][px] == ".":
        L.thing(px, py, "jumppad", d, 45, power); take(r, (px, py))
        qx, qy = (px - 1, py) if horiz else (px, py - 1)
        if L.g[qy][qx] == ".":
            L.thing(qx, qy, "padpc", px, py); take(r, (qx, qy))
    # a hazmat suit before it, for those who'd rather wade
    a = answer_room(L, r.zone, ("storage", "lab", "workshop"), avoid=(r,))
    f = floor_spots(L, a, 1)
    if f and kind != "l":
        L.g[f[0][1]][f[0][0]] = "9"; take(a, f[0])


def shaft(L, r):
    """A tall room: a jetpack below, fuel on the ledges, a lift for those without."""
    rng = L.rng
    f = floor_spots(L, r, 2)
    if f:
        L.g[f[0][1]][f[0][0]] = "`"; take(r, f[0])
        L.fuel.append("%d, %d, 100" % f[0])
    # ledges round the walls, a wall and a half up
    for (x, y, s) in wall_spots(L, r)[:6]:
        L.fh[y][x] = lvlkit.hchar(12); take(r, (x, y))
        if rng.random() < 0.5 and L.g[y][x] == ".":
            L.g[y][x] = ","; L.fuel.append("%d, %d, 40" % (x, y))
    # stairs-free way: an elevator in a corner
    cx, cy = r.x1 - 1, r.y1 - 1
    if L.g[cy][cx] == "." and (cx, cy) not in r.lane:
        L.lift(cx, cy, cx, cy, 0, 12, 2, 8); take(r, (cx, cy))


def reactor(L, r):
    """A core on an island in a ring of lava, bridged on the way through."""
    ix0, iy0, ix1, iy1 = r.cx - 1, r.cy - 1, r.cx + 1, r.cy + 1
    ring = [(x, y) for x in range(ix0 - 2, ix1 + 3) for y in range(iy0 - 2, iy1 + 3)
            if not (ix0 <= x <= ix1 and iy0 <= y <= iy1) and r.x0 + 1 <= x <= r.x1 - 1 and r.y0 + 1 <= y <= r.y1 - 1]
    for (x, y) in ring:
        if (x, y) in r.lane or L.g[y][x] != ".":
            continue
        L.fh[y][x] = lvlkit.hchar(-2)
        L.liquid(x, y, "l", 2)
        take(r, (x, y))
    for x in range(ix0, ix1 + 1):
        for y in range(iy0, iy1 + 1):
            if (x, y) not in r.lane and L.g[y][x] == ".":
                L.fh[y][x] = lvlkit.hchar(2)
    L.g[r.cy][r.cx] = "L"; take(r, (r.cx, r.cy))


def boss(L, r):
    rng = L.rng
    f = floor_spots(L, r, 3)
    if f:
        L.mon(f[0][0], f[0][1], rng.choice("70"), (24, 24, 100, 100, 3))
        take(r, f[0])
    for (x, y) in floor_spots(L, r, 2)[:4]:
        L.blocks.append((x, y, 2, 2, 6, 6, 5)); take(r, (x, y))


# ---------------------------------------------------------------------------
# 6. Monsters, pickups
# ---------------------------------------------------------------------------
def populate(L):
    sp, rng = L.spec, L.rng
    st = L.rooms[L.start_c]
    rooms = [r for r in L.rooms.values() if r is not st]
    total = sp["nmons"]
    pool = sp["mons"]
    weights = [1 + r.zone + (2 if r.path else 0) for r in rooms]
    placed = 0
    tries = 0
    while placed < total and tries < 400:
        tries += 1
        r = rng.choices(rooms, weights)[0]
        f = floor_spots(L, r, 1)
        if not f:
            continue
        x, y = f[0]
        if abs(x - st.cx) + abs(y - st.cy) < 9:
            continue
        ch = rng.choice(pool)
        if ch == "E":
            L.thing(x, y, "eyebot")
        else:
            L.g[y][x] = ch
        take(r, (x, y))
        placed += 1
    # harder: more, only at HARD and NIGHTMARE
    for r in rng.sample(rooms, min(4, len(rooms))):
        f = floor_spots(L, r, 1)
        if f and abs(f[0][0] - st.cx) + abs(f[0][1] - st.cy) >= 9:
            L.mon(f[0][0], f[0][1], rng.choice(pool.replace("E", "")), only="hard nightmare")
            take(r, f[0])
    # pickups: health and ammo by the way, guns one a stretch, the map early
    guns = list(sp["guns"])
    order = sorted(rooms, key=lambda r: (r.zone, not r.path))
    for r in order:
        f = floor_spots(L, r, 1)
        n = 1 + (1 if not r.path else 0)
        for (x, y) in f[:n]:
            L.g[y][x] = rng.choice("+aae*u" if r.zone else "+ae")
            take(r, (x, y))
    for z in range(len(guns)):
        rs = [r for r in order if r.zone == min(z, max(rr.zone for rr in order)) and not r.path] or [r for r in order if r.zone == z] or order
        r = rs[0]
        f = floor_spots(L, r, 1)
        if f:
            L.g[f[0][1]][f[0][0]] = guns[z]; take(r, f[0])
            if guns[z] == ")":
                if len(f) > 1:
                    L.g[f[1][1]][f[1][0]] = "("; take(r, f[1])
    m = [r for r in order if r.zone == 0 and not r.path] or order
    f = floor_spots(L, m[0], 1)
    if f:
        L.g[f[0][1]][f[0][0]] = "M"; take(m[0], f[0])
    L.loot.append("crate    = cells:30, shells:25, medkit:20, armor:10")


# ---------------------------------------------------------------------------
# 7. ART: each room dressed for what it is (looks only)
# ---------------------------------------------------------------------------
def room_faces(L, r):
    """(wall x, wall y, face, floor x, floor y, side) round room r - the room's own walls."""
    out = []
    for (x, y) in r.cells():
        if L.g[y][x] in WALLS:
            continue
        for s, (dx, dy) in SIDES.items():
            wx, wy = x + dx, y + dy
            if L.g[wy][wx] in WALLS:
                out.append((wx, wy, OPP[s], x, y, s))
    return out


def feature_side(L, r):
    """The wall you see coming in: opposite the main way in."""
    if not r.mouths:
        return "N"
    m = sorted(r.mouths)[0]
    if m[0] <= r.x0: return "E"
    if m[0] >= r.x1: return "W"
    if m[1] <= r.y0: return "S"
    return "N"


def art(L, r, palette):
    rng = L.rng
    sp = L.spec
    kd = KINDS.get(r.kind, KINDS["lobby"])
    style = lvldress.STYLES[sp["style"]]
    base = style["base"]
    col = kd["light"] or tuple(int(palette["line"][i:i + 2], 16) for i in (0, 2, 4))
    colh = hx(col)
    keyc = getattr(r, "keyed", None)
    if keyc:
        colh = KEY_HEX[keyc]
        col = tuple(int(colh[i:i + 2], 16) for i in (0, 2, 4))
    feat_pic = sp["walls"][kd["feat"]] if kd["feat"] is not None else None
    fx = kd.get("fx", "")
    faces = room_faces(L, r)
    fs = feature_side(L, r)
    # --- the feature wall: a band of the room's own picture, filtered, framed by lines
    if feat_pic and L.pcount() < 520:
        row = [f for f in faces if f[5] == fs and (f[0], f[1], f[2]) not in L.faces]
        row.sort(key=lambda f: (f[0], f[1]))
        for i, (wx, wy, f, ox, oy, s) in enumerate(row):
            span = r.ce - r.fe
            if span > 32:
                continue
            band = leaf(feat_pic, start=1, fx=fx) if i % 4 != 3 else leaf("", fx="B-20")
            glow = solid(colh)
            if i % 4 == 3 and kd["light"]:   # every fourth: a light column, lit
                L.face(wx, wy, f, T_LAMP, ["", "", "", glow, glow, "", "", ""])
                # (a quarter cell out from the wall, lamp-less: the column is its lamp)
                ddx, ddy = SIDES[s]
                L.lights.append((round(ox + 0.5 + ddx * 0.25, 3), round(oy + 0.5 + ddy * 0.25, 3), 3.5, 160) + tuple(int(v) for v in col) + (0, 1))
            else:
                L.face(wx, wy, f, T_BAND, [solid(hx(mixc(col, (0, 0, 0), 0.55))), band, band, "", glow, solid(base)])
    # --- the floor: a border of light strips along the walls, a different floor in the middle
    if r.kind in ("lobby", "exit", "key", "vault", "network", "boss", "security", "lab", "start") and L.pcount() < 600:
        for (x, y) in r.cells():
            if L.g[y][x] in WALLS or L.g[y][x] in "/\\" or L.lq[y][x] != "." or (x, y, "F") in L.faces:
                continue
            ws = L.wall_sides(x, y)
            if len(ws) == 1:
                t, at = F_EDGE[ws[0]]
                lv = [""] * lvldress.tree_leaves(t)
                lv[at] = solid(hx(mixc(col, (255, 255, 255), 0.1)))
                L.face(x, y, "F", t, lv)
    if r.kind in ("lobby", "start", "exit", "office", "boss", "vault"):
        alt = sp["floors"][(kd["floor"]) % 4]
        for (x, y) in r.cells():
            if r.x0 + 2 <= x <= r.x1 - 2 and r.y0 + 2 <= y <= r.y1 - 2 and (x + y) % 2 == 0 and L.g[y][x] != "#" and (x, y, "F") not in L.faces and L.lq[y][x] == ".":
                L.face_pic(x, y, "F", alt)
    # --- the ceiling: light panels in a grid, a light under each (with its lamp)
    step = 5 if r.ce <= 16 else 6
    for y in range(r.y0 + 1, r.y1, step):
        for x in range(r.x0 + 1, r.x1, step):
            if L.g[y][x] in WALLS:
                continue
            if (x, y, "C") not in L.faces:
                L.face_pic(x, y, "C", "ceiling-lamp.png" if r.kind not in ("server", "network", "lab") else "ceiling-lights.png")
            if r.kind == "blackout":
                continue
            lc = mixc(sp["ambient"][1:4], col, 0.45) if kd["light"] else sp["ambient"][1:4]
            fxl = {"server": 1, "security": 0, "survive": 2, "lasers": 2, "reactor": 4, "fire": 4, "boss": 4, "cold": 0}.get(r.kind, 0)
            if fxl == 1 and (x + y) % 3:
                fxl = 0
            L.light(x + 0.5, y + 0.5, 5.5 if r.ce > 16 else 4.5, 150, *(int(v) for v in lc), fxl)
    # --- the room's own light leans to its colour
    amb = sp["ambient"]
    if kd["light"] and r.kind != "blackout":
        c = mixc(amb[1:4], kd["light"], 0.35)
        L.cell_light(r.x0, r.y0, r.x1, r.y1, amb[0] + (10 if r.kind in ("lobby", "lab", "exit") else 0), *(int(v) for v in c),
                     {"survive": 2, "reactor": 4, "boss": 4}.get(r.kind, 0))
    # --- liquids that are only looks: a channel of water along a lobby's or lab's long wall, a garden pool
    if r.kind in ("lobby", "lab", "garden", "cold") and r.x1 - r.x0 >= 8 and r.y1 - r.y0 >= 8:
        side = rng.choice(["N", "S"]) if (r.x1 - r.x0) >= (r.y1 - r.y0) else rng.choice(["W", "E"])
        cells = []
        if side in "NS":
            y = r.y0 + 1 if side == "N" else r.y1 - 1
            cells = [(x, y) for x in range(r.x0 + 2, r.x1 - 1)]
        else:
            x = r.x0 + 1 if side == "W" else r.x1 - 1
            cells = [(x, y) for y in range(r.y0 + 2, r.y1 - 1)]
        if all(free(L, r, c) for c in cells):
            for (x, y) in cells:
                L.fh[y][x] = lvlkit.hchar(-2)
                L.liquid(x, y, "w", 1)
                L.opac[y][x] = "2" if r.kind != "garden" else "6"
                take(r, (x, y))
            mx, my = cells[len(cells) // 2]
            L.light(mx + 0.5, my + 0.5, 4.0, 120, 80, 180, 255, 2)
    # --- glass: a pane between the room and a sealed alcove beyond its feature wall (a specimen, a server)
    if r.kind in ("lab", "cold", "server", "vault") and L.rng.random() < 0.8:
        glass_alcove(L, r, fs, col)
    # --- wet floors round water and in cold rooms
    for (x, y) in r.cells():
        if L.lq[y][x] != ".":
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    xx, yy = x + dx, y + dy
                    if L.g[yy][xx] not in WALLS and L.lq[yy][xx] == "." and L.wet[yy][xx] == ".":
                        L.wet[yy][xx] = "8"
    if r.kind in ("cold", "garden"):
        for (x, y) in r.cells():
            if L.wet[y][x] == ".":
                L.wet[y][x] = "6"
    # --- props in its colour
    for (x, y) in r.cells():
        if L.g[y][x] in "AFIOQl":
            L.looks.append("%d, %d, 3, 35, %s, 100" % (x, y, colh))
    # --- a story told on the floor: blood by the bodies, oil in the workshop
    if r.kind in ("workshop", "storage") and rng.random() < 0.7:
        for (x, y) in floor_spots(L, r, 1)[:3]:
            L.smears.append("%d, %d, F, oil%d" % (x, y, rng.randint(1, 2)))
    if r.kind in ("ambush", "survive", "alarm") and rng.random() < 0.8:
        f = floor_spots(L, r, 1)
        if f:
            x, y = f[0]
            L.thing(x, y, rng.choice(["deadguard", "deadscientist", "deadcyborg"])); take(r, (x, y))
            for dx, dy in ((1, 0), (0, 1), (-1, 0)):
                if L.g[y + dy][x + dx] == ".":
                    L.smears.append("%d, %d, F, blood%d" % (x + dx, y + dy, rng.randint(1, 3)))


def glass_alcove(L, r, side, col):
    """Behind the room's feature wall, a one-cell alcove behind a pane: something lit in it."""
    dx, dy = SIDES[side]
    cand = []
    for (x, y) in r.cells():
        if L.g[y][x] != "." or (x, y) in r.used:
            continue
        gx, gy = x + dx, y + dy
        bx, by = gx + dx, gy + dy
        if not (2 <= bx < SIZE - 2 and 2 <= by < SIZE - 2):
            continue
        if L.g[gy][gx] in WALLS and L.g[by][bx] in WALLS and all(L.g[by + ey][bx + ex] in WALLS for ex, ey in SIDES.values() if (bx + ex, by + ey) != (gx, gy)):
            side_ok = all(L.g[gy + sy][gx + sx] in WALLS for sx, sy in ((dy, dx), (-dy, -dx)))
            if side_ok and all(abs(x - m[0]) + abs(y - m[1]) > 2 for m in r.mouths):
                cand.append((x, y, gx, gy, bx, by))
    if not cand:
        return
    x, y, gx, gy, bx, by = L.rng.choice(cand)
    L.g[gy][gx] = "="
    L.g[by][bx] = L.rng.choice("IOl") if r.kind != "vault" else "["
    L.fh[by][bx] = lvlkit.hchar(0)
    L.ch[by][bx] = lvlkit.hchar(r.ce, ceiling=True)
    L.ch[gy][gx] = lvlkit.hchar(r.ce, ceiling=True)
    st = {"lab": 1, "cold": 2, "server": 4, "vault": 6}.get(r.kind, 1)
    frost = 5 if r.kind == "cold" else 0
    L.glass.append("%d, %d, 5, 1, %d, %d, %d, 0, 999" % (gx, gy, frost, 2 if r.kind == "lab" else 0, st))
    L.light(bx + 0.5, by + 0.5, 2.0, 200, *(int(v) for v in col), 2, )
    take(r, (x, y))
    r.lane.add((x, y))


# ---------------------------------------------------------------------------
# 8. Can it be played through? (a walk that learns as it goes)
# ---------------------------------------------------------------------------
BLOCKING = set(lvlkit.WALLS) | set("=-%?@$;/\\") | set(lvlkit.DECO) | set("\"'")


def playthrough(L, lv):
    rows = [list(r) for r in lv["rows"]]
    n = SIZE
    codes = {}
    for d in lv["doors"]:
        p = [s.strip() for s in d.split(",")]
        codes[(int(p[0]), int(p[1]))] = (int(p[2] or 0), p[3] if len(p) > 3 else "")
    things = {}
    for t in lv["things"]:
        p = [s.strip() for s in t.split(",")]
        things[(int(p[0]), int(p[1]))] = p[2:]
    notes = {}
    for t in lv["notes"]:
        p = t.split(",", 3)
        notes[(int(p[0]), int(p[1]))] = p[3]
    have, known, hacked, kits, seals = set(), set(), set(), 0, set()
    start = next((x, y) for y in range(n) for x in range(n) if rows[y][x] in "<>^v")
    safes_open = set()
    for _round in range(40):
        seen = {start}
        q = deque([start])
        touch = set()
        while q:
            x, y = q.popleft()
            c = rows[y][x]
            if c in "rby":
                have.add(c)
            if (things.get((x, y)) or [""])[0] == "repairkit":
                kits = max(kits, 1)
            for dx, dy in SIDES.values():
                a = (x + dx, y + dy)
                ch = rows[a[1]][a[0]]
                touch.add(a)
                if a in seen:
                    continue
                ok = ch not in BLOCKING
                if ch == '"':   # (a thing: you walk over a pickup, a body, a plate - a monster is in the way only till it's dead)
                    ok = lvlkit.THINGS.get((things.get(a) or ["table"])[0], "deco") in ("item", "flat", "mon")
                if ch in "RBY":
                    ok = ch.lower() in have
                if ch == "!":
                    ok = a in seals
                if ch in "DHX" and a in codes:
                    kicks, code = codes[a]
                    ok = kicks > 0 or a in known or a in hacked
                if (things.get(a) or [""])[0] in ("jumppad", "camera"):
                    ok = True
                if ch == "E":
                    ok = False
                if ok:
                    seen.add(a); q.append(a)
        before = (len(have), len(known), len(hacked), len(seals), len(safes_open))
        # what's learned from what's within reach
        for c in touch:
            if c in notes:
                th = things.get(c)
                if th and th[0] == "safe" and c not in safes_open:
                    continue
                for m in __import__("re").findall(r"\{code (\d+) (\d+)\}", notes[c]):
                    known.add((int(m[0]), int(m[1])))
            th = things.get(c)
            if th and th[0] == "safe" and (c in known):
                safes_open.add(c)
            if th and th[0] == "brokenpc" and kits:
                hacked.add((int(th[1]), int(th[2])))
            if th and th[0] == "computer":
                hacked.add((int(th[1]), int(th[2])))
            if rows[c[1]][c[0]] == "@":
                # the nearest station opens each sealed door
                for y in range(n):
                    for x in range(n):
                        if rows[y][x] == "!":
                            st = min(((sx, sy) for sy in range(n) for sx in range(n) if rows[sy][sx] == "@"),
                                     key=lambda s: (s[0] - x) ** 2 + (s[1] - y) ** 2)
                            if st == c:
                                seals.add((x, y))
        if any(rows[y][x] == "E" for (x, y) in touch):
            return True, seen
        if (len(have), len(known), len(hacked), len(seals), len(safes_open)) == before:
            return False, seen
    return False, seen


# ---------------------------------------------------------------------------
# All of it
# ---------------------------------------------------------------------------
DESK_SIZE = 150   # (percent: the game's desk is knee high next to its chair - looks only)


def desks(L):
    """Every desk drawn bigger ([looks] size), keeping any look its cell already has."""
    had = {tuple(int(v) for v in l.split(",")[:2]): i for i, l in enumerate(L.looks)}
    for y, row in enumerate(L.g):
        for x, ch in enumerate(row):
            if ch != "d":
                continue
            if (x, y) in had:
                f = [v.strip() for v in L.looks[had[(x, y)]].split(",")]
                f[5] = str(DESK_SIZE)
                L.looks[had[(x, y)]] = ", ".join(f)
            else:
                L.looks.append("%d, %d, 0, 0, FFFFFF, %d" % (x, y, DESK_SIZE))


def build(k, show=False):
    sp = SPECS[k]
    for attempt in range(60):
        L = Level(sp, k)
        L.rng = random.Random(sp["seed"] * 1000 + attempt)
        if not layout(L):
            continue
        assign(L)
        carve(L)
        heights(L)
        for r in L.rooms.values():
            lane(L, r)
        gates(L)
        terminals(L)
        order = sorted(L.rooms.values(), key=lambda r: (r.kind not in ("start", "exit", "gauntlet", "alarm", "crossing"), r.id))
        for r in order:
            furnish(L, r)
        populate(L)
        palette = lvldress.STYLES[sp["style"]]
        for r in sorted(L.rooms.values(), key=lambda r: (not r.path, r.zone)):
            art(L, r, palette)
        desks(L)
        L.headroom(8)
        lv = L.level_dict("infil%d" % k)
        ok, seen = playthrough(L, lv)
        if not ok:
            continue
        roles = {}
        for r in L.rooms.values():
            role = {"start": "start", "exit": "exit"}.get(r.kind)
            if getattr(r, "keyed", None):
                role = "key"
            elif r.kind in ("crossing", "reactor", "fire"):
                role = "hazard"
            roles[r.zi] = role
        lv, summary, notes = lvldress.dress(lv, sp["style"])
        return L, lv, summary, attempt
    return None, None, None, None


def main(argv):
    write = "--write" in argv
    show = "-show" in argv
    only = [int(a) for a in argv if a.isdigit()]
    if "--check" in argv:
        ok = True
        for k in only or range(1, 11):
            f = os.path.join(OUT, "level%d.txt" % k)
            ok &= lvlkit.check_level(lvlkit.read_level_file(f, "infil%d" % k), ASSETS)
        return 0 if ok else 1
    outs, ok = [], True
    for k in only or range(1, 11):
        del PROBLEMS[:]
        L, lv, summary, attempt = build(k, show)
        if not L:
            print("SECTOR %d: no layout played through" % k)
            ok = False
            continue
        print("SECTOR %d: %s (layout %d) - %d rooms; %d pieced faces, %d lights; %s" % (
            k, SPECS[k]["name"], attempt, len(L.rooms), L.pcount(), len(L.lights), summary))
        if show:
            L.show()
        good = lvlkit.check_level(lv, ASSETS)
        ok &= good and not PROBLEMS
        outs.append((k, lv))
    if write:
        if not ok:
            print("not writing: fix the problems above first")
            return 1
        os.makedirs(OUT, exist_ok=True)
        for k, lv in outs:
            doc = ["INFILTRATION: %s, made by maker.py - %s" % (SPECS[k]["name"], SPECS[k]["story"])]
            lvldress.write_dressed(os.path.join(OUT, "level%d.txt" % k), lv, doc)
        print("wrote %d sectors into %s" % (len(outs), os.path.normpath(OUT)))
    print("ALL GOOD" if ok else "PROBLEMS")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
