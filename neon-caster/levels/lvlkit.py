"""NEON-CASTER level kit: carve maps on a 48x48 grid, check them, and read or
write the game's level DATA. See levels.py for how the levels are built.

Coordinates are the game's: x left to right, y top to bottom, 0..47. Cell
(x, y) covers X in [x, x+1], Y in [y, y+1] - so slanted edges are lines like
X + Y = s or X - Y = d through cell corners, and the cells such a line cuts
become the game's diagonal walls (/ or \\).
"""
import os, re
from collections import deque

N = 48
WALLS = set("#NCKPG")
DOORS = set("DHXRBYE!")  # ! a door sealed until its data station (@) is hacked
DIAG = set("/\\")
ITEMS = set("rby+ae23u*4Mqj8")  # ... q overcharge, j damage amp
MONS = set("mghcskwzT")  # ... k stalker, w spitter, z the overseer, T thief
DECO = set("oiptxlnfSdAFIJLOQUWZV")  # ... Z chair, V a body; x crate, l rack, n vending, f tank, S spawner, d desk, A console, F monitors, I specimen, J lab bench, L generator, O cryo pod, Q hologram, U lockers, W bench
START = set("<>^v")
GLASS = set("=")  # a pane of glass: see through it, but not walk
STATION = set("@$")  # a data station (@): a wall you jack into; a code terminal ($): a QB64 puzzle
PAD = set("&")  # a teleporter pad: they pair up in reading order (1st-2nd, 3rd-4th)
SECRET = set("?")  # a secret wall: looks like the walls beside it (on the map too) until Space finds it


class Map:
    def __init__(self, fill="#"):
        self.g = [[fill] * N for _ in range(N)]
        self.zones = []
        self.ambient = (170, 255, 255, 255)  # brightness 0-256, then r g b
        self.lights = []
        self.events = []
        self.fh = [["."] * N for _ in range(N)]  # [floor]: . or a height character (chapter 22)
        self.ch = [["."] * N for _ in range(N)]  # [ceiling]
        self.lq = [["."] * N for _ in range(N)]  # [liquid]: . or a liquid's letter (LIQUID_CHARS)
        self.ld = [["."] * N for _ in range(N)]  # [liquid depth]: . (LIQUID_DEPTH) or 1-8 eighths
        self.lifts = []
        self.triggers = []  # lines: "when ... : commands ; ..." (chapter 19)
        self.blocks = []  # [blocks]: (x, y, x0, y0, x1, y1, wall) - edges in eighths, wall 1-6 (# N C K P G)
        self.nudges = []  # [nudges]: (x, y, dx, dy) - a decoration off its cell's middle, eighths (-3 to 3)

    @classmethod
    def from_rows(cls, rows):
        m = cls()
        m.g = [list(r) for r in rows]
        return m

    # -- basic edits
    def put(self, x, y, c):
        self.g[y][x] = c

    def get(self, x, y):
        return self.g[y][x]

    def rect(self, x0, y0, x1, y1, c="."):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = c

    def paint(self, x0, y0, x1, y1, c):
        """Retexture only the walls in a rectangle."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.g[y][x] in WALLS:
                    self.g[y][x] = c

    # -- regions: continuous X in [x0,x1], Y in [y0,y1] (cell edges), and
    # 45-degree half-planes s1 <= X+Y <= s2, d1 <= X-Y <= d2 (integers)
    @staticmethod
    def classify(x, y, x0, y0, x1, y1, s1=None, s2=None, d1=None, d2=None):
        """'in', 'out', or ('cut', ch) for cell (x, y)."""
        if x < x0 or x + 1 > x1 or y < y0 or y + 1 > y1:
            return "out"
        cuts = []
        lo, hi = x + y, x + y + 2  # X+Y over the cell
        if s1 is not None:
            if hi <= s1: return "out"
            if lo < s1: cuts.append("/")  # cell cut by X+Y = s1 (only when s1 = lo+1)
        if s2 is not None:
            if lo >= s2: return "out"
            if hi > s2: cuts.append("/")
        lo, hi = x - y - 1, x - y + 1  # X-Y over the cell
        if d1 is not None:
            if hi <= d1: return "out"
            if lo < d1: cuts.append("\\")
        if d2 is not None:
            if lo >= d2: return "out"
            if hi > d2: cuts.append("\\")
        if not cuts:
            return "in"
        if len(cuts) > 1:
            return "out"
        return ("cut", cuts[0])

    def carve(self, x0, y0, x1, y1, s1=None, s2=None, d1=None, d2=None):
        """Open floor inside the region; its slanted edges become diagonals."""
        for y in range(N):
            for x in range(N):
                k = self.classify(x, y, x0, y0, x1, y1, s1, s2, d1, d2)
                c = self.g[y][x]
                if k == "in":
                    if c in WALLS or c in DIAG:
                        self.g[y][x] = "."
                elif k != "out":
                    if c in WALLS:
                        self.g[y][x] = k[1]

    def solid(self, x0, y0, x1, y1, s1=None, s2=None, d1=None, d2=None, wall="#"):
        """Fill a region with wall (a pillar); slanted edges become diagonals."""
        for y in range(N):
            for x in range(N):
                k = self.classify(x, y, x0, y0, x1, y1, s1, s2, d1, d2)
                if k == "in":
                    self.g[y][x] = wall
                elif k != "out" and self.g[y][x] == ".":
                    self.g[y][x] = k[1]

    def octagon(self, x0, y0, x1, y1, cut):
        """Room with interior cells x0..x1, y0..y1 and corners cut by `cut`."""
        X0, Y0, X1, Y1 = x0, y0, x1 + 1, y1 + 1
        self.carve(X0, Y0, X1, Y1, s1=X0 + Y0 + cut, s2=X1 + Y1 - cut,
                   d1=X0 - Y1 + cut, d2=X1 - Y0 - cut)

    def diamond(self, cx, cy, r):
        """Diamond room around the grid point (cx, cy), radius r."""
        self.carve(cx - r, cy - r, cx + r, cy + r, s1=cx + cy - r, s2=cx + cy + r,
                   d1=cx - cy - r, d2=cx - cy + r)

    def pillar(self, cx, cy, r, wall="#"):
        """Diamond pillar around grid point (cx, cy), radius r."""
        self.solid(cx - r, cy - r, cx + r, cy + r, s1=cx + cy - r, s2=cx + cy + r,
                   d1=cx - cy - r, d2=cx - cy + r, wall=wall)

    # -- floor / ceiling zones (see MapData): shape 0 rect, 1-4 triangle
    def zone(self, x0, y0, x1, y1, floor, ceil, shape=0):
        if shape:
            assert x1 - x0 == y1 - y0, "triangle zones must be square"
        self.zones.append((x0, y0, x1, y1, floor, ceil, shape))

    # -- lights (see MapData): effect 0 steady, 1 flicker, 2 pulse, 3 strobe,
    # 4 fire, 5 dying
    def light(self, x, y, radius, bright, r, g, b, effect=0):
        self.lights.append((x, y, radius, bright, r, g, b, effect))

    # -- event rooms (see EV_ in the game): kind 1 ambush, 2 survive, 3 trap,
    # 4 shooting gallery, 5 spawner nest, 6 closet, 7 hoard, 8 pressure
    # plate, 9 laser, 10 laser cutter, 11 power failure, 12 fire trap (3, burning),
    # 13 death pit (its floor kills - a pit with a bottom you can see);
    # the room x0..x1, y0..y1; two numbers
    # whose meaning depends on the kind; the reward (a pickup kind, 0 none:
    # 4 health, 5 cells, 6 shells, 9 armour, 10 big medkit, 13 overcharge,
    # 14 damage amp)
    def event(self, kind, x0, y0, x1, y1, a, b, reward=0):
        self.events.append((kind, x0, y0, x1, y1, a, b, reward))

    # -- heights (chapter 22): each cell's floor and ceiling, in eighths of a
    # wall. A floor of 0 is the zone's own; up to 35 eighths up, 8 down (a
    # floor 8 down is a pit with no bottom - you fall into the dark). A
    # ceiling is measured from the same 0: it's 8 (one wall) unless set.
    # You step up 2 eighths at most (STEP_UP), drop any distance, and need
    # BODY eighths of room; a lift carries you between its low and high.
    def floor_at(self, x, y):
        return hval(self.fh[y][x], 0)

    def ceil_at(self, x, y):
        return hval(self.ch[y][x], 8)

    def block(self, x, y, x0, y0, x1, y1, wall=1):
        """A solid block standing in open cell (x, y): its edges x0..x1 across
        and y0..y1 down, in eighths of the cell (0-8), looking like wall 1-6
        (# N C K P G) - a pillar, a thin wall, the back of an alcove."""
        self.blocks = [b for b in self.blocks if (b[0], b[1]) != (x, y)] + [(x, y, x0, y0, x1, y1, wall)]

    def nudge(self, x, y, dx, dy, face=0):
        """The decoration on cell (x, y) moved dx across, dy down, in eighths
        (-3 to 3) - and face: 0 it turns to face you, 1-4 it stands flat
        facing east, south, west or north."""
        self.nudges = [n for n in self.nudges if (n[0], n[1]) != (x, y)] + [(x, y, dx, dy, face)]

    def liquid(self, x, y, kind, depth=None):
        """A pool of kind (w p s l a) depth eighths deep on cell (x, y) - only
        on floor (LIQUID_ON), as the game would have it."""
        if self.g[y][x] in LIQUID_ON:
            self.lq[y][x] = kind
            self.ld[y][x] = "." if depth in (None, LIQUID_DEPTH) else str(depth)

    def floor(self, x0, y0, x1, y1, e, only_open=True):
        """Floors in a rectangle e eighths up (or down, if e < 0)."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if not only_open or self.g[y][x] not in WALLS:
                    self.fh[y][x] = hchar(e)

    def ceiling(self, x0, y0, x1, y1, e, only_raise=True):
        """Ceilings in a rectangle at e eighths (only ever raised, unless
        only_raise is off - for a low tunnel)."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.g[y][x] in WALLS:
                    continue
                if not only_raise or e > self.ceil_at(x, y):
                    self.ch[y][x] = hchar(e, ceiling=True)

    def stairs(self, x0, y0, x1, y1, up, e0, e1, rise=2):
        """A flight of stairs filling the rectangle, climbing toward `up`
        (N, S, E or W) from e0 to e1, `rise` eighths a step (2 is as much as
        you can step), then level at e1 to the far edge. Works down too."""
        horiz = up in "EW"
        n = (x1 - x0 + 1) if horiz else (y1 - y0 + 1)
        step = rise if e1 >= e0 else -rise
        for i in range(n):
            e = e0 + step * i
            if (step > 0 and e > e1) or (step < 0 and e < e1):
                e = e1
            if up == "E": self.floor(x0 + i, y0, x0 + i, y1, e)
            elif up == "W": self.floor(x1 - i, y0, x1 - i, y1, e)
            elif up == "S": self.floor(x0, y0 + i, x1, y0 + i, e)
            else: self.floor(x0, y1 - i, x1, y1 - i, e)

    def pit(self, x0, y0, x1, y1, depth, steps=None, rise=2, width=1):
        """A sunken floor `depth` eighths down (8 or more: bottomless). With
        steps (N, S, E or W: the side you climb out by), a flight `width`
        cells wide in the middle of that side, from the bottom back up to 0."""
        self.floor(x0, y0, x1, y1, -depth)
        if not steps or depth >= 8:
            return
        n = (depth - 1) // rise  # stair cells inside the pit (the last step is onto the rim)
        for i in range(n):
            e = -depth + rise * (n - i)  # i = 0 at the rim: the highest step
            if steps in "NS":
                cx = (x0 + x1) // 2 - (width - 1) // 2
                yy = y0 + i if steps == "N" else y1 - i
                self.floor(cx, yy, cx + width - 1, yy, e)
            else:
                cy = (y0 + y1) // 2 - (width - 1) // 2
                xx = x0 + i if steps == "W" else x1 - i
                self.floor(xx, cy, xx, cy + width - 1, e)

    def lift(self, x0, y0, x1, y1, low, high, mode=2, speed=6):
        """A lift: its cells ride between low and high (eighths). Mode 1
        goes up and down by itself, 2 is an elevator (up while you're on
        it), 3 waits for a trigger's liftgo."""
        self.lifts.append((x0, y0, x1, y1, low, high, mode, speed))
        self.floor(x0, y0, x1, y1, low)

    def headroom(self, gap=8):
        """Raise any ceiling closer than gap eighths above its floor."""
        for y in range(N):
            for x in range(N):
                if self.g[y][x] not in WALLS and self.ceil_at(x, y) - self.floor_at(x, y) < gap:
                    self.ch[y][x] = hchar(self.floor_at(x, y) + gap, ceiling=True)

    # -- output
    def rows(self):
        return ["".join(r) for r in self.g]

    def show(self):
        print("   " + "".join(str(i % 10) for i in range(N)))
        for i, r in enumerate(self.rows()):
            print("%2d %s" % (i, r))

    def data(self, name, walls, floors, ceils, comment):
        out = []
        out += ["' " + l for l in comment]
        out.append('DATA "%s"' % name)
        out.append("DATA " + ", ".join('"%s"' % w for w in walls))
        out.append("DATA " + ", ".join('"%s"' % f for f in floors))
        out.append("DATA " + ", ".join('"%s"' % c for c in ceils))
        out.append("DATA " + ", ".join(str(v) for v in self.ambient))
        out.append("DATA %d" % len(self.zones))
        for z in self.zones:
            out.append("DATA " + ", ".join(str(v) for v in z))
        out.append("DATA %d" % len(self.lights))
        for l in self.lights:
            out.append("DATA " + ", ".join(str(v) for v in l))
        out.append("DATA %d" % len(self.events))
        for e in self.events:
            out.append("DATA " + ", ".join(str(v) for v in e))
        for r in self.rows():
            out.append('DATA "%s"' % r)
        return out


# ---------------------------------------------------------------- heights
H_UP = "0123456789abcdefghijklmnopqrstuvwxyz"
H_DOWN = "ABCDEFGH"
STEP_UP = 2      # eighths you can step up (the game's STEP_UP, 0.32 of a wall)
BODY = 6         # eighths of room you need (BODY_H, 0.7)
DEADLY = -8      # a floor this far down has no bottom (PIT_DEPTH)


def hchar(e, ceiling=False):
    """The [floor] / [ceiling] character for e eighths."""
    e = int(e)
    if e == (8 if ceiling else 0):
        return "."
    if e >= 0:
        return H_UP[min(e, len(H_UP) - 1)]
    return H_DOWN[min(-e, 8) - 1]


def hval(c, default):
    if c == "." or c == " ":
        return default
    if c in H_UP:
        return H_UP.index(c)
    if c in H_DOWN:
        return -(H_DOWN.index(c) + 1)
    return default


def check_heights(lv):
    """Heights, walked the way the game walks them: step up STEP_UP at most,
    drop any distance (not into a bottomless pit), need BODY of room; lifts
    carry you from their low to their high; doors by key order as validate.
    Errors: the exit unreachable, a key unreachable, a stuck spot (somewhere
    you can get to but can't get from to the exit). Warnings: a pickup out of
    reach, a monster with no room, a melee monster that can never reach you."""
    rows = lv["rows"]
    fl = lv.get("floor") or []
    ce = lv.get("ceiling") or []
    g = [list(r) for r in rows]
    F = [[hval(fl[y][x] if y < len(fl) and x < len(fl[y]) else ".", 0) for x in range(N)] for y in range(N)]
    C = [[hval(ce[y][x] if y < len(ce) and x < len(ce[y]) else ".", 8) for x in range(N)] for y in range(N)]
    for e in lv.get("events", []):  # a death pit (13): its lowest floor kills, as a pit with no bottom does
        if len(e) == 8 and e[0] == 13:
            cells = [(x, y) for y in range(e[2], e[4] + 1) for x in range(e[1], e[3] + 1) if g[y][x] not in WALLS]
            lo = min((F[y][x] for (x, y) in cells), default=0)
            for (x, y) in cells:
                if F[y][x] <= lo:
                    F[y][x] = min(F[y][x], DEADLY)
    lift = {}
    for (x0, y0, x1, y1, lo, hi, mode, sp) in lv.get("lifts", []):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                lift[(x, y)] = (lo, hi)
    errs, warns = [], []
    keyof = {"R": "r", "B": "b", "Y": "y"}
    pads = pad_order(g, lv.get("pads", []))
    st = [(x, y) for y in range(N) for x in range(N) if g[y][x] in START]
    ex = [(x, y) for y in range(N) for x in range(N) if g[y][x] == "E"]
    if not st:
        return ["no start"], []

    def heights(x, y):
        return range(lift[(x, y)][0], lift[(x, y)][1] + 1) if (x, y) in lift else (F[y][x],)

    def can_enter(x, y, keys):
        c = g[y][x]
        ok = c == "." or c in ITEMS or c in MONS or c in START or c in "DHX" or c in PAD or c == "E"
        if c in keyof and keyof[c] in keys: ok = True
        if c == "!" and "@" in keys: ok = True
        return ok

    def moves(state, keys):
        x, y, z = state
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = x + dx, y + dy
            if not (0 <= a < N and 0 <= b < N) or not can_enter(a, b, keys):
                continue
            if (a, b) in lift:
                lo, hi = lift[(a, b)]
                if lo - z <= STEP_UP and C[b][a] - max(z, lo) >= BODY:
                    for zz in range(lo, hi + 1):  # on it, it carries you anywhere between
                        yield (a, b, zz)
                continue
            fb = F[b][a]
            if fb <= DEADLY or fb - z > STEP_UP or C[b][a] - max(z, fb) < BODY:
                continue
            yield (a, b, fb)
        if g[y][x] in PAD:  # a teleporter: to its partner
            k = pads.index((x, y)); o = k + 1 if k % 2 == 0 else k - 1
            if 0 <= o < len(pads):
                a, b = pads[o]
                yield (a, b, F[b][a])

    def walk():
        keys = set()
        s0 = (st[0][0], st[0][1], F[st[0][1]][st[0][0]])
        while True:
            seen = {s0}; q = deque([s0])
            while q:
                for n in moves(q.popleft(), keys):
                    if n not in seen:
                        seen.add(n); q.append(n)
            cells = {(x, y) for x, y, z in seen}
            got = {g[y][x] for (x, y) in cells if g[y][x] in "rby"}
            if any(g[y + dy][x + dx] in STATION for (x, y) in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                got.add("@")
            if got <= keys:
                return keys, seen, cells
            keys |= got

    # first flat (no heights at all: what the doors and walls allow), then
    # with the heights - anything lost between the two is the heights' doing
    realF, realC, reallift = F, C, lift
    F = [[0] * N for _ in range(N)]; C = [[8] * N for _ in range(N)]; lift = {}
    fkeys, fseen, flat = walk()
    F, C, lift = realF, realC, reallift
    keys, seen, cells = walk()
    for (x, y) in ex:  # (you use the exit from beside it, as validate has it)
        if not any((x + dx, y + dy) in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            errs.append("exit at %d,%d unreachable (heights)" % (x, y))
    for c in "RBY":
        if any(c in r for r in rows) and keyof[c] not in keys:
            errs.append("key %s unreachable (heights)" % keyof[c])
    # stuck spots: from where (with every key) can't you get to the exit?
    if ex:
        nex = {(x + dx, y + dy) for (x, y) in ex for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))}
        back = {s for s in seen if (s[0], s[1]) in ex or (s[0], s[1]) in nex}
        rev = {}
        for s in seen:
            for n in moves(s, keys):
                rev.setdefault(n, []).append(s)
        q = deque(back)
        while q:
            for p in rev.get(q.popleft(), []):
                if p not in back:
                    back.add(p); q.append(p)
        stuck = sorted({(x, y) for (x, y, z) in seen if (x, y, z) not in back and (x, y) not in lift})
        if stuck:
            errs.append("%d stuck spot(s) - you get in, you can't get out: %s" % (len(stuck), " ".join("%d,%d" % c for c in stuck[:12])))
    for y in range(N):
        for x in range(N):
            c = g[y][x]
            if c in ITEMS and (x, y) not in cells and (x, y) in flat:
                warns.append("pickup %s at %d,%d out of reach (heights)" % (c, x, y))
            if c in MONS:
                if F[y][x] <= DEADLY or C[y][x] - F[y][x] < BODY:
                    errs.append("monster %s at %d,%d has no room to stand" % (c, x, y))
                elif (x, y) not in cells and (x, y) in flat and c in "mchkT":
                    warns.append("melee monster %s at %d,%d can never reach you" % (c, x, y))
    lost = sorted(c for c in flat - cells if F[c[1]][c[0]] > DEADLY)  # (a pit with no bottom is meant to be out of reach)
    if lost:
        warns.append("%d cell(s) a flat walk reaches but the heights cut off: %s" % (len(lost), " ".join("%d,%d" % c for c in lost[:16])))
    used = sorted({F[y][x] for y in range(N) for x in range(N) if g[y][x] not in WALLS})
    raised = sum(1 for y in range(N) for x in range(N) if g[y][x] not in WALLS and F[y][x] != 0)
    warns.append("heights: %d cells off the ground, floor levels %s, %d lift(s), reach %d cells" % (raised, used, len(lift and lv.get("lifts", [])), len(cells)))
    return errs, warns


# ---------------------------------------------------------------- level files
# A level is a plain text file, neon-caster/levels/levelN.txt: some
# "key = value" lines, then [zones], [lights] and [events] (one per line,
# numbers split by commas) and the [map] (48 rows of 48 characters).
# Lines starting with ' are comments (the map's rows start with #).
LEVEL_HEADER = """' NEON-CASTER level file - see chapter 22 of neon-caster.bas for every
' part of it. Lines starting with ' are comments. The level kit
' (levels.py --write) and the editor in the game write these files.
"""


# [loot]: what breakables leave - the game's LOOT_HELP$, DecoKindOf and ItemOf
LOOT_HELP = "' breakable = up to four drops, A B C D - each pickup:chance (in %), or - for none. Breaking one rolls 1-100 once: the first drop whose chance (added to those before it) covers it comes out"
LOOT_BREAKABLES = {"barrel", "lamp", "plant", "terminal", "crate", "rack", "serverrack", "vending", "vendingmachine",
                   "coolant", "tank", "coolanttank", "spawner", "desk", "console", "screen", "specimen", "specimentank",
                   "labbench", "generator", "cryopod", "cryo", "hologram", "locker", "bench", "chair"}
LOOT_PICKUPS = {"red", "blue", "yellow", "health", "cells", "ammo", "shells", "scatter", "repeater", "armor", "armour",
                "medkit", "bigmed", "rail", "railgun", "map", "overcharge", "amp", "goggles", "nightvision", "headset"}


# [liquid]: the game's LQ_CHARS$ and LQ_DEPTH; the map characters a liquid can lie on (EDIT_OPEN$)
LIQUID_CHARS = "wpsla"
LIQUID_DEPTH = 3
LIQUID_ON = ".rby+*uae234Mqj8mghcskwzToiptxlnfSdAFIJLOQUWZV<>^v&"


def check_liquid(lv):
    """What's wrong with a level's liquids (a list of errors)."""
    errs = []
    lq = lv.get("liquid") or []
    ld = lv.get("liquid_depth") or []
    for y, r in enumerate(lq):
        for x, c in enumerate(r):
            if c == ".":
                continue
            if c not in LIQUID_CHARS:
                errs.append("liquid at %d,%d: '%s' is not a liquid (w p s l a)" % (x, y, c))
            elif y >= len(lv["rows"]) or lv["rows"][y][x] not in LIQUID_ON:
                errs.append("liquid at %d,%d: not on a floor" % (x, y))
            d = ld[y][x] if y < len(ld) and x < len(ld[y]) else "."
            if d != "." and d not in "12345678":
                errs.append("liquid depth at %d,%d: '%s' (. or 1-8)" % (x, y, d))
    return errs


def check_blocks(lv):
    """What's wrong with a level's blocks and nudges (a list of errors)."""
    errs, seen = [], set()
    rows = lv["rows"]
    for b in lv.get("blocks", []):
        if len(b) < 7:
            errs.append("block %s: needs x, y, x0, y0, x1, y1, wall" % (b,)); continue
        x, y, x0, y0, x1, y1, w = b[:7]
        if not (0 < x < N - 1 and 0 < y < N - 1):
            errs.append("block at %d,%d: in the border" % (x, y)); continue
        if rows[y][x] in WALLS or rows[y][x] in DOORS or rows[y][x] in "%@$/\\=":
            errs.append("block at %d,%d: only in an open cell (it's '%s')" % (x, y, rows[y][x]))
        if not (0 <= x0 < x1 <= 8 and 0 <= y0 < y1 <= 8):
            errs.append("block at %d,%d: edges %d-%d, %d-%d (0 to 8, low < high)" % (x, y, x0, x1, y0, y1))
        if not 1 <= w <= 6:
            errs.append("block at %d,%d: wall %d (1-6)" % (x, y, w))
        if (x, y) in seen:
            errs.append("block at %d,%d: a cell has only one" % (x, y))
        seen.add((x, y))
    for n in lv.get("nudges", []):
        if len(n) < 4:
            errs.append("nudge %s: needs x, y, dx, dy" % (n,)); continue
        x, y, dx, dy = n[:4]
        if not (0 <= x < N and 0 <= y < N) or rows[y][x] not in DECO:
            errs.append("nudge at %d,%d: no decoration there" % (x, y))
        if not (-3 <= dx <= 3 and -3 <= dy <= 3):
            errs.append("nudge at %d,%d: %d, %d (-3 to 3)" % (x, y, dx, dy))
        if len(n) > 4 and not 0 <= n[4] <= 5:
            errs.append("nudge at %d,%d: facing %d (0 as built, 1-4 east south west north, 5 turns to you)" % (x, y, n[4]))
    return errs


def check_loot(line):
    """What's wrong with one [loot] line ('' if nothing)."""
    if "=" not in line:
        return "loot '%s': needs BREAKABLE = DROPS" % line
    name, drops = line.split("=", 1)
    n = "".join(c for c in name.lower() if c not in " _-\t")
    if n.endswith("s"):
        n = n[:-1]
    if n not in LOOT_BREAKABLES:
        return "loot '%s': no breakable called %s" % (line, name.strip())
    slots = [d.strip() for d in drops.split(",")] if drops.strip() else []
    if len(slots) > 4:
        return "loot '%s': four drops at most" % line
    for d in slots:
        if d in ("", "-"):
            continue
        if ":" not in d:
            return "loot '%s': each drop is pickup:chance (or -)" % line
        k, c = [x.strip() for x in d.split(":", 1)]
        if k.lower() not in LOOT_PICKUPS and not (len(k) == 1 and k in "rby+ae23u*4Mqj"):
            return "loot '%s': no pickup called %s" % (line, k)
        try:
            if not 0 <= float(c) <= 100:
                raise ValueError
        except ValueError:
            return "loot '%s': a chance is 0 to 100" % line
    return ""


def _num(v):
    return str(int(v)) if float(v) == int(float(v)) else ("%g" % float(v))


def level_text(lv, comment=()):
    out = [LEVEL_HEADER.rstrip("\n")]
    out += ["' " + c for c in comment]
    out.append("")
    out.append("name     = %s" % lv["name"])
    if lv.get("puzzles"):
        out.append("puzzles  = %s" % lv["puzzles"])
    if lv.get("droids") is not None:  # how many droids (the game's own count, 3, if not said)
        out.append("droids   = %d" % lv["droids"])
    out.append("walls    = " + ", ".join(lv["walls"]))
    out.append("floors   = " + ", ".join(lv["floors"]))
    out.append("ceilings = " + ", ".join(lv["ceils"]))
    out.append("ambient  = " + ", ".join(_num(v) for v in lv["ambient"]))
    for sec, rows, what in (("zones", lv["zones"], "x0, y0, x1, y1, floor, ceiling, shape"),
                            ("lights", lv["lights"], "x, y, radius, brightness, red, green, blue, effect"),
                            ("events", lv["events"], "kind, x0, y0, x1, y1, a, b, reward")):
        out.append("")
        out.append("[%s]" % sec)
        out.append("' " + what)
        for r in rows:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("lifts"):
        out.append("")
        out.append("[lifts]")
        out.append("' x0, y0, x1, y1, low, high (eighths of a wall), mode (1 up and down, 2 an elevator), speed (eighths a second)")
        for r in lv["lifts"]:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("triggers"):
        out.append("")
        out.append("[triggers]")
        out.append("' when (enter X0 Y0 X1 Y1 / use X Y / shoot X Y / clear X0 Y0 X1 Y1 / time S) [repeat] : console commands ; ...")
        out += list(lv["triggers"])
    if lv.get("monsters"):  # monsters' own settings, from the editor's monster pane
        out.append("")
        out.append("[monsters]")
        out.append("' x, y, sight, hearing (cells), health %, speed %, wake (0 seeing you, 1 you close by, 2 being hit, 3 hunting from the start)")
        for r in lv["monsters"]:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("pads"):  # teleporters paired by hand in the editor
        out.append("")
        out.append("[pads]")
        out.append("' teleporters paired by hand: x1, y1, x2, y2 (the rest pair up in reading order)")
        for r in lv["pads"]:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("blocks"):  # solid blocks inside cells
        out.append("")
        out.append("[blocks]")
        out.append("' a solid block in an open cell: x, y, then its edges in eighths of the cell (x0, y0, x1, y1: 0 to 8), and its wall (1-6: # N C K P G)")
        for r in lv["blocks"]:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("nudges"):  # decorations off their cells' middles
        out.append("")
        out.append("[nudges]")
        out.append("' a decoration moved off its cell's middle: x, y, then across and down in eighths (-3 to 3), and which way it faces (0 it turns to face you; 1-4 it stands flat facing east, south, west, north)")
        for r in lv["nudges"]:
            out.append(", ".join(_num(v) for v in r))
    if lv.get("loot"):  # what breakables leave, by kind - kept as they are
        out.append("")
        out.append("[loot]")
        out.append(LOOT_HELP)
        out += list(lv["loot"])
    if lv.get("faces"):  # pictures on single faces, from the editor's PAINT - kept as they are
        out.append("")
        out.append("[faces]")
        out.append("' x, y, face (E S W N: a side - LE LS LW LN: a lintel's side - F floor, C ceiling - BE BS BW BN: a block's side), divided (0, 1 left|right, 2 top|bottom), picture, second half's picture")
        out += list(lv["faces"])
    out.append("")
    out.append("[map]")
    out += list(lv["rows"])
    fl = lv.get("floor") or []
    if any(r.strip(".") for r in fl):
        out += ["", "[floor]", "' each cell's floor: . as usual, 0-9 a-z eighths of a wall up, A-H down"] + list(fl)
    ce = lv.get("ceiling") or []
    if any(r.strip(".") for r in ce):
        out += ["", "[ceiling]", "' each cell's ceiling: . as usual (1), or its height in eighths, as the floor's"] + list(ce)
    lq = lv.get("liquid") or []
    if any(r.strip(".") for r in lq):  # pools: the game's [liquid] and [liquid depth], as the editor writes them
        ld = list(lv.get("liquid_depth") or [])
        ld = [(ld[y] if y < len(ld) else "").ljust(N, ".")[:N] for y in range(N)]
        out += ["", "[liquid]", "' each cell's liquid: . none, w water, p poison, s slime, l lava, a acid"] + list(lq)
        out += ["", "[liquid depth]", "' how deep, in eighths of a wall: . is %d, or 1-8" % LIQUID_DEPTH] + ld
    return "\n".join(out) + "\n"


def pad_order(g, pairs):
    """The teleporter pads in the order the game pairs them (1st-2nd, 3rd-4th):
    the [pads] pairs made by hand in the editor first, then the rest in
    reading order."""
    rd = [(x, y) for y in range(N) for x in range(N) if g[y][x] in PAD]
    out, used = [], set()
    for pr in pairs:
        if len(pr) < 4:
            continue
        x1, y1, x2, y2 = (int(v) for v in pr[:4])
        a, b = (x1, y1), (x2, y2)
        if a in rd and b in rd and a != b and a not in used and b not in used:
            out += [a, b]; used |= {a, b}
    return out + [p for p in rd if p not in used]


def write_level_file(path, lv, comment=()):
    open(path, "w").write(level_text(lv, comment))


def read_level_file(path, label=None):
    """A level file as the dict check_level and level_text use."""
    lv = dict(label=label or os.path.basename(path), name="", walls=[], floors=[], ceils=[],
              ambient=(), zones=[], lights=[], events=[], rows=[], lifts=[], floor=[], ceiling=[], triggers=[], faces=[], pads=[], monsters=[], loot=[],
              liquid=[], liquid_depth=[], blocks=[], nudges=[])
    sec = None
    for line in open(path).read().split("\n"):
        t = line.strip()
        if sec in ("triggers", "faces", "loot"):
            if t and not t.startswith("'") and not t.startswith("["):
                lv[sec].append(t)
                continue
        if sec in ("map", "floor", "ceiling", "liquid", "liquid depth"):
            if t and not t.startswith("'") and not t.startswith("["):
                lv["rows" if sec == "map" else sec.replace(" ", "_")].append(line.rstrip("\r")[:N])
                continue
        if not t or t.startswith("'"):
            continue
        if t.startswith("[") and t.endswith("]"):
            sec = t[1:-1].strip().lower(); continue
        if sec is None and "=" in t:
            k, v = [x.strip() for x in t.split("=", 1)]
            vals = [x.strip() for x in v.split(",")]
            if k == "name": lv["name"] = v
            elif k == "puzzles": lv["puzzles"] = v
            elif k == "droids": lv["droids"] = int(float(v))
            elif k == "walls": lv["walls"] = vals
            elif k == "floors": lv["floors"] = vals
            elif k == "ceilings": lv["ceils"] = vals
            elif k == "ambient": lv["ambient"] = tuple(int(float(x)) for x in vals)
        elif sec in ("zones", "events", "lifts", "pads", "monsters", "blocks", "nudges"):
            lv[sec].append(tuple(int(float(x)) for x in t.split(",")))
        elif sec == "lights":
            lv[sec].append(tuple(float(x) for x in t.split(",")))
    return lv


def level_files(folder):
    """Every levelN.txt in folder, in order."""
    out = []
    n = 1
    while os.path.exists(os.path.join(folder, "level%d.txt" % n)):
        out.append(read_level_file(os.path.join(folder, "level%d.txt" % n), "level%d" % n))
        n += 1
    return out


# ---------------------------------------------------------------- validate
def validate(rows, name="map", want_exit=True, pairs=()):
    errs, warns = [], []
    g = [list(r) for r in rows]
    if len(g) != N or any(len(r) != N for r in g):
        errs.append("not %dx%d" % (N, N))
        return errs, warns
    at = lambda x, y: g[y][x]
    for i in range(N):
        for (x, y) in ((i, 0), (i, N - 1), (0, i), (N - 1, i)):
            if at(x, y) not in WALLS:
                errs.append("border not wall at %d,%d" % (x, y))
    starts = [(x, y) for y in range(N) for x in range(N) if at(x, y) in START]
    if len(starts) != 1:
        errs.append("need exactly one start, got %d" % len(starts))
    iswall = lambda c: c in WALLS or c in STATION or c in SECRET
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            c = at(x, y)
            if c in DOORS and c != "E":
                h = iswall(at(x - 1, y)) and iswall(at(x + 1, y))
                v = iswall(at(x, y - 1)) and iswall(at(x, y + 1))
                if not (h or v):
                    errs.append("door %s at %d,%d not between two walls" % (c, x, y))
                # the other two sides must be passable
                if h and (at(x, y - 1) in WALLS or at(x, y + 1) in WALLS):
                    errs.append("door %s at %d,%d blocked" % (c, x, y))
                if v and not h and (at(x - 1, y) in WALLS or at(x + 1, y) in WALLS):
                    errs.append("door %s at %d,%d blocked" % (c, x, y))
            if c in GLASS:  # in a wall one cell thick, like a door
                isw = lambda cc: cc in WALLS or cc in GLASS or cc in SECRET
                h = isw(at(x - 1, y)) and isw(at(x + 1, y))
                v = isw(at(x, y - 1)) and isw(at(x, y + 1))
                if not (h or v) or (h and v):
                    errs.append("glass at %d,%d not in a straight wall" % (x, y))
            if c in DIAG:
                ks = (1, 3) if c == "/" else (2, 4)
                sc = []
                for k in ks:
                    ny = y - 1 if k <= 2 else y + 1
                    nx = x + 1 if k in (2, 3) else x - 1
                    s = 0
                    for (a, b) in ((x, ny), (nx, y)):
                        cc = at(a, b)
                        s += 1 if cc in DIAG else (2 if cc in WALLS else 0)
                    sc.append(s)
                if sc[0] == sc[1]:
                    warns.append("diagonal %s at %d,%d: sides tie %s" % (c, x, y, sc))
                elif max(sc) < 2:
                    warns.append("diagonal %s at %d,%d: weak side %s" % (c, x, y, sc))
    exits = [(x, y) for y in range(N) for x in range(N) if at(x, y) == "E"]
    if want_exit and len(exits) != 1:
        errs.append("need exactly one exit, got %d" % len(exits))
    if errs or not starts:
        return errs, warns

    # reachability with keys: walk floor, items, monsters, open doors;
    # decorations and diagonals block (conservative)
    keys = set()
    keyof = {"R": "r", "B": "b", "Y": "y"}
    pads = pad_order([list(r) for r in rows], pairs)  # (the editor's [pads] first, then reading order)
    while True:
        seen = set([starts[0]])
        q = deque([starts[0]])
        while q:
            x, y = q.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                a, b = x + dx, y + dy
                if (a, b) in seen:
                    continue
                c = at(a, b)
                ok = c == "." or c == "~" or c in ITEMS or c in MONS or c in START or c in "DHX" or c in PAD  # (~: a lift, while dressing)
                if c in keyof and keyof[c] in keys:
                    ok = True
                if c == "!" and "@" in keys:  # a sealed door: open once a station's reached
                    ok = True
                if ok:
                    seen.add((a, b))
                    q.append((a, b))
                    if c in PAD:  # a teleporter: its partner too
                        k = pads.index((a, b))
                        o = k + 1 if k % 2 == 0 else k - 1
                        if 0 <= o < len(pads) and pads[o] not in seen:
                            seen.add(pads[o]); q.append(pads[o])
        got = {at(x, y) for (x, y) in seen if at(x, y) in "rby"}
        if any(at(x + dx, y + dy) in STATION for (x, y) in seen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            got.add("@")
        if got <= keys:
            break
        keys |= got
    reach = seen
    for (x, y) in exits:
        if not any((x + dx, y + dy) in reach for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            errs.append("exit at %d,%d unreachable" % (x, y))
    for y in range(N):
        for x in range(N):
            c = at(x, y)
            if (c in ITEMS or c in MONS) and (x, y) not in reach:
                warns.append("unreachable %s at %d,%d" % (c, x, y))
            if c in STATION and not any(at(x + dx, y + dy) == "." for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                errs.append("station/terminal %s at %d,%d has no floor in front of it" % (c, x, y))
            if c in "RBY" and keyof[c] not in keys:
                warns.append("key door %s at %d,%d: its key is never reachable" % (c, x, y))
    count = lambda s: sum(1 for r in g for c in r if c in s)
    info = "%s: %d monsters, %d items, %d deco, keys %s, reach %d cells" % (
        name, count(MONS), count(ITEMS), count(DECO), "".join(sorted(keys)) or "-", len(reach))
    if count(MONS) > 64 or count(ITEMS) > 64 or count(DECO) > 64:
        errs.append("too many things (max 64 each)")
    return errs, warns + [info]


# ---------------------------------------------------------------- the game
def parse_bas(path):
    """The levels in neon-caster.bas: name, textures, zones and map rows."""
    src = open(path).read()
    levels = []
    for m in re.finditer(r"^(Level\d+):\n", src, re.M):
        lines = []
        for line in src[m.end():].split("\n"):
            line = line.strip()
            if line.startswith("DATA "):
                lines.append(line[5:])
            elif line and not line.startswith("'"):
                break
        strs = lambda l: re.findall(r'"([^"]*)"', l)
        nums = lambda l: [int(v) for v in l.split(",")]
        fnums = lambda l: [float(v) for v in l.split(",")]
        nz = int(lines[5])
        nl = int(lines[6 + nz])
        ne = int(lines[7 + nz + nl])
        ev0 = 8 + nz + nl
        levels.append(dict(
            label=m.group(1), name=strs(lines[0])[0], walls=strs(lines[1]),
            floors=strs(lines[2]), ceils=strs(lines[3]),
            ambient=tuple(nums(lines[4])),
            zones=[tuple(nums(l)) for l in lines[6:6 + nz]],
            lights=[tuple(fnums(l)) for l in lines[7 + nz:7 + nz + nl]],
            events=[tuple(nums(l)) for l in lines[ev0:ev0 + ne]],
            rows=[strs(l)[0] for l in lines[ev0 + ne:ev0 + ne + N]]))
    return levels


START_SAFE = 6.5  # cells: no monster in plain sight nearer than this to where you start


def check_start_safe(rows):
    """Monsters that can see you, close, the moment the sector starts: you'd
    be hit before you'd had a look round. (Thieves steal, they don't hit.)"""
    import math
    st = [(x, y) for y, r in enumerate(rows) for x, c in enumerate(r) if c in START]
    if not st:
        return []
    sx, sy = st[0]
    def clear(x, y):
        n = int(max(abs(x - sx), abs(y - sy)) * 4) + 1
        for i in range(1, n):
            c = rows[int(sy + 0.5 + (y - sy) * i / n)][int(sx + 0.5 + (x - sx) * i / n)]
            if c in WALLS or c in DOORS or c in DIAG or c in STATION or c in "%?":
                return False
        return True
    return ["monster %s at %d,%d: in sight of the start, %.1f cells away (keep it %.1f+ away, or out of sight)"
            % (c, x, y, math.hypot(x - sx, y - sy), START_SAFE)
            for y, r in enumerate(rows) for x, c in enumerate(r)
            if c in MONS and c != "T" and math.hypot(x - sx, y - sy) < START_SAFE and clear(x, y)]


def check_tips(rows):
    """Two diagonals meeting in a point with open floor on both sides of it:
    a way that looks open (on the map too) but is shut - CRYO LAB's atrium
    tips once sealed its corridors to the X doors this way."""
    OPEN = set(".&") | ITEMS | MONS | DECO | DOORS | START
    at = lambda x, y: rows[y][x]
    errs = []
    for y in range(1, N - 1):
        for x in range(1, N - 2):
            a, b = at(x, y), at(x + 1, y)
            if a == "\\" and b == "/" and (at(x, y + 1) in OPEN or at(x + 1, y + 1) in OPEN) and at(x, y - 1) in OPEN and at(x + 1, y - 1) in OPEN:
                errs.append("diagonals %d,%d and %d,%d meet in a point: the way south past them is shut" % (x, y, x + 1, y))
            if a == "/" and b == "\\" and (at(x, y - 1) in OPEN or at(x + 1, y - 1) in OPEN) and at(x, y + 1) in OPEN and at(x + 1, y + 1) in OPEN:
                errs.append("diagonals %d,%d and %d,%d meet in a point: the way north past them is shut" % (x, y, x + 1, y))
    for y in range(1, N - 2):
        for x in range(1, N - 1):
            a, b = at(x, y), at(x, y + 1)
            if a == "\\" and b == "/" and (at(x + 1, y) in OPEN or at(x + 1, y + 1) in OPEN) and at(x - 1, y) in OPEN and at(x - 1, y + 1) in OPEN:
                errs.append("diagonals %d,%d and %d,%d meet in a point: the way east past them is shut" % (x, y, x, y + 1))
            if a == "/" and b == "\\" and (at(x - 1, y) in OPEN or at(x - 1, y + 1) in OPEN) and at(x + 1, y) in OPEN and at(x + 1, y + 1) in OPEN:
                errs.append("diagonals %d,%d and %d,%d meet in a point: the way west past them is shut" % (x, y, x, y + 1))
    return errs


def sealed_rooms(rows, pairs=()):
    """Floor nothing reaches - out from the start through every door (keys
    or not), pad, closet (%) and secret wall (?): each such room as a set of
    cells, with whatever's in it. (A room you can only look into through
    glass is one.)"""
    from collections import deque
    OPEN = set(".&~") | ITEMS | MONS | DECO | START
    PASS = OPEN | DOORS | set("%?")
    pads = pad_order([list(r) for r in rows], pairs)
    st = [(x, y) for y in range(N) for x in range(N) if rows[y][x] in START]
    if not st:
        return set(), []
    seen = {st[0]}; q = deque([st[0]])
    while q:
        x, y = q.popleft()
        nb = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if rows[y][x] in PAD and (x, y) in pads:
            k = pads.index((x, y)); o = k + 1 if k % 2 == 0 else k - 1
            if 0 <= o < len(pads):
                nb.append(pads[o])
        for (a, b) in nb:
            if (a, b) not in seen and rows[b][a] in PASS:
                seen.add((a, b)); q.append((a, b))
    left = {(x, y) for y in range(N) for x in range(N) if rows[y][x] in OPEN and (x, y) not in seen}
    rooms = []
    while left:
        c = left.pop(); room = {c}; q = deque([c])
        while q:
            x, y = q.popleft()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in left:
                    left.remove(n); room.add(n); q.append(n)
        rooms.append(room)
    return seen, rooms


def secret_way(rows, room, reach):
    """The best wall to make a secret way into a sealed room through: one
    wall thick (or two, if it must be), the room on one side and floor you
    can reach on the other, in a straight wall - beside the room's glass if
    it has any (you see in, then find the way). Its cells, or None."""
    OPEN = set(".") | ITEMS | MONS | START
    best = None
    for (x, y) in room:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            for t in (1, 2):
                cells = [(x + dx * k, y + dy * k) for k in range(1, t + 1)]
                ox, oy = x + dx * (t + 1), y + dy * (t + 1)
                if not all(1 <= cx < N - 1 and 1 <= cy < N - 1 for (cx, cy) in cells) or not (0 <= ox < N and 0 <= oy < N):
                    break
                if not all(rows[cy][cx] in WALLS for (cx, cy) in cells):
                    break
                if (ox, oy) not in reach or rows[oy][ox] not in OPEN:
                    continue
                side = [rows[cy + dx][cx + dy] for (cx, cy) in cells] + [rows[cy - dx][cx - dy] for (cx, cy) in cells]  # (along the wall)
                if not all(c in WALLS or c in GLASS for c in side):
                    continue
                score = (4 if t == 1 else 0) + (2 if any(c in GLASS for c in side) else 0) + (1 if rows[y][x] == "." else 0)
                if best is None or score > best[0]:
                    best = (score, cells)
                break
    return None if best is None else best[1]


def carve_stash(m, loot, start_far=True):
    """A secret stash: a 2 x 2 room cut into solid rock behind a secret wall
    (?), off floor you can reach - as far from the start as there's room
    for one - with `loot` (pickup characters) in it and a dim light. Its
    floor and ceiling are the floor's in front. Returns the secret wall's
    cell and the way in from its front (x, y, dx, dy), or None if there's
    nowhere."""
    rows = m.rows()
    reach, _ = sealed_rooms(rows, getattr(m, "pads", ()))
    st = [(x, y) for y in range(N) for x in range(N) if rows[y][x] in START][0]
    solid = lambda x, y: 1 <= x < N - 1 and 1 <= y < N - 1 and rows[y][x] in WALLS
    best = None
    for y in range(2, N - 2):
        for x in range(2, N - 2):
            if rows[y][x] not in WALLS:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                fx, fy = x - dx, y - dy  # (the floor in front)
                if (fx, fy) not in reach or rows[fy][fx] != ".":
                    continue
                if not (solid(x + dy, y + dx) and solid(x - dy, y - dx)):
                    continue
                for (deep, wide) in ((2, 2), (2, 1), (1, 1)):  # (the room: 2 x 2 if there's rock for it, else smaller)
                    for px, py in ((dy, dx), (-dy, -dx)):  # (...to one side or the other)
                        room = [(x + dx * k + px * j, y + dy * k + py * j) for k in range(1, deep + 1) for j in range(wide)]
                        ring = {(a + u, b + v) for (a, b) in room for u in (-1, 0, 1) for v in (-1, 0, 1)} - set(room) - {(x, y)}
                        if all(solid(a, b) for (a, b) in room) and all(solid(a, b) for (a, b) in ring):
                            d = len(room) * 100 + abs(x - st[0]) + abs(y - st[1])  # (the biggest room, then the furthest)
                            if best is None or d > best[0]:
                                best = (d, x, y, room, fx, fy, dx, dy)
    if not best:
        return stash_shed(m, loot, rows, reach, st)
    _, x, y, room, fx, fy, dx, dy = best
    m.put(x, y, "?")
    loot = loot if len(room) > 1 else loot[:1]
    for i, (a, b) in enumerate(room):
        m.put(a, b, loot[i] if i < len(loot) else ".")
        m.fh[b][a] = m.fh[fy][fx]; m.ch[b][a] = m.ch[fy][fx]
    cx = sum(a for a, b in room) / len(room) + 0.5; cy = sum(b for a, b in room) / len(room) + 0.5
    m.light(round(cx, 2), round(cy, 2), 2.5, 110, 255, 200, 120, 1)
    return (x, y, dx, dy)


def stash_shed(m, loot, rows, reach, st):
    """No rock to cut a stash into (a sector in the open): a shed, then -
    3 x 3 walls on a flat stretch of floor, the loot in the middle, its
    door a secret wall - as far from the start as one fits."""
    from collections import Counter
    wall = Counter(c for r in rows for c in r[1:-1] if c in WALLS and c != "#").most_common(1)
    wall = wall[0][0] if wall else "#"
    taken = {(b[0], b[1]) for b in getattr(m, "blocks", [])}
    for l in getattr(m, "lifts", []):
        taken |= {(x, y) for x in range(l[0], l[2] + 1) for y in range(l[1], l[3] + 1)}
    best = None
    for y in range(3, N - 4):
        for x in range(3, N - 4):
            cells = [(x + i, y + j) for j in range(3) for i in range(3)]
            around = [(x + i, y + j) for j in range(-1, 4) for i in range(-1, 4)]
            h = m.fh[y + 1][x + 1]
            if not all(rows[b][a] == "." and m.fh[b][a] == h and m.lq[b][a] == "." and (a, b) not in taken and (a, b) in reach for (a, b) in around):
                continue
            d = abs(x + 1 - st[0]) + abs(y + 1 - st[1])
            if best is None or d > best[0]:
                best = (d, x, y)
    if not best:
        return None
    _, x, y = best
    for j in range(3):
        for i in range(3):
            m.put(x + i, y + j, wall)
    m.put(x + 1, y + 1, loot[0])
    door = (x + 1, y + 2) if abs(y + 3 - st[1]) < abs(y - 1 - st[1]) else (x + 1, y)  # (its door: on the side nearer the start)
    m.put(door[0], door[1], "?")
    m.light(x + 1.5, y + 1.5, 2.0, 110, 255, 200, 120, 1)
    return (door[0], door[1], 0, -1 if door[1] == y + 2 else 1)


def check_level(lv, assets=None):
    """Print what's wrong with a level (and a summary); True if it's fine."""
    errs, warns = validate(lv["rows"], lv["label"], pairs=lv.get("pads", []))
    if (len(lv["walls"]), len(lv["floors"]), len(lv["ceils"])) != (6, 4, 2):
        errs.append("need 6 walls, 4 floors, 2 ceilings")
    if assets:
        for f in lv["walls"] + lv["floors"] + lv["ceils"]:
            if not os.path.exists(os.path.join(assets, f)):
                errs.append("missing texture %s" % f)
    for z in lv["zones"]:
        if len(z) != 7:
            errs.append("zone %s: needs 7 numbers" % (z,))
            continue
        x0, y0, x1, y1, fl, ce, sh = z
        if not (0 <= x0 <= x1 < N and 0 <= y0 <= y1 < N):
            errs.append("zone %s: outside the map" % (z,))
        if not (0 <= fl <= 4 and 0 <= ce <= 2 and 0 <= sh <= 4):
            errs.append("zone %s: floor 0-4, ceiling 0-2, shape 0-4" % (z,))
        if sh and x1 - x0 != y1 - y0:
            errs.append("zone %s: a triangle needs a square" % (z,))
    amb = lv.get("ambient", ())
    if len(amb) != 4 or not (0 <= amb[0] <= 256 and all(0 <= c <= 255 for c in amb[1:])):
        errs.append("ambient %s: brightness 0-256, then r g b 0-255" % (amb,))
    for l in lv.get("lights", []):
        if len(l) != 8:
            errs.append("light %s: needs 8 numbers" % (l,))
            continue
        x, y, rad, br, cr, cg, cb, fx = l
        if not (0 < x < N and 0 < y < N):
            errs.append("light %s: outside the map" % (l,))
        elif lv["rows"][int(y)][int(x)] in WALLS:
            errs.append("light %s: inside a wall" % (l,))
        if not (0 < rad <= 16 and 0 <= br <= 400 and 0 <= fx <= 5 and all(0 <= c <= 255 for c in (cr, cg, cb))):
            errs.append("light %s: radius 1-16, brightness 0-400, colour 0-255, effect 0-5" % (l,))
    for e in lv.get("events", []):
        if len(e) != 8:
            errs.append("event %s: needs 8 numbers" % (e,))
            continue
        kind, x0, y0, x1, y1, a, b, reward = e
        if not (1 <= kind <= 13 and 0 < x0 <= x1 < N - 1 and 0 < y0 <= y1 < N - 1):
            errs.append("event %s: kind 1-13, a room inside the map" % (e,))
        if reward not in (0, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14):
            errs.append("event %s: reward must be 0 or a pickup kind (not a key: a lost event mustn't lock you out)" % (e,))
        room = [lv["rows"][y][x] for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]
        if kind == 4 and not any(c in DECO for c in room):
            errs.append("event %s: a shooting gallery needs decorations in its room" % (e,))
        if kind == 7 and not any(c in DOORS for r in lv["rows"][y0 - 1:y1 + 2] for c in r[x0 - 1:x1 + 2]):
            errs.append("event %s: a hoard needs a door to seal" % (e,))
        if kind == 5 and "S" not in room:
            errs.append("event %s: a nest needs spawners (S) in its room" % (e,))
        if kind in (1, 2) and not any(c in DOORS for r in lv["rows"][max(0, y0 - 5):y1 + 6] for c in r[max(0, x0 - 5):x1 + 6]):
            warns.append("event %s: no doors to lock round its room" % (e,))
    if len(lv.get("events", [])) > 16:
        errs.append("too many events (max 16)")
    errs += check_liquid(lv)
    errs += check_blocks(lv)
    for l in lv.get("loot", []):
        e = check_loot(l)
        if e:
            errs.append(e)
    if not any("M" in r for r in lv["rows"]):
        warns.append("no map pickup (M): the minimap never appears on this level")
    errs += check_start_safe(lv["rows"])
    errs += check_tips(lv["rows"])
    if not errs:
        he, hw = check_heights(lv)
        errs += he; warns += hw
    print("%s  %s  (%d lights)" % (lv["label"], lv["name"], len(lv.get("lights", []))))
    for e in errs:
        print("   ERROR", e)
    for w in warns:
        print("  ", w)
    return not errs
