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
DOORS = set("DHXRBYE")
DIAG = set("/\\")
ITEMS = set("rby+ae23u*4Mqj")  # ... q overcharge, j damage amp
MONS = set("mghcskwz")  # ... k stalker, w spitter, z the overseer
DECO = set("oiptxlnfS")  # ... x crate, l server rack, n vending machine, f coolant tank, S spawner
START = set("<>^v")


class Map:
    def __init__(self, fill="#"):
        self.g = [[fill] * N for _ in range(N)]
        self.zones = []
        self.ambient = (170, 255, 255, 255)  # brightness 0-256, then r g b
        self.lights = []
        self.events = []

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
    # 4 shooting gallery, 5 spawner nest; the room x0..x1, y0..y1; two numbers
    # whose meaning depends on the kind; the reward (a pickup kind, 0 none:
    # 4 health, 5 cells, 6 shells, 9 armour, 10 big medkit, 13 overcharge,
    # 14 damage amp)
    def event(self, kind, x0, y0, x1, y1, a, b, reward=0):
        self.events.append((kind, x0, y0, x1, y1, a, b, reward))

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


# ---------------------------------------------------------------- validate
def validate(rows, name="map", want_exit=True):
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
    iswall = lambda c: c in WALLS
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
                ok = c == "." or c in ITEMS or c in MONS or c in START or c in "DHX"
                if c in keyof and keyof[c] in keys:
                    ok = True
                if ok:
                    seen.add((a, b))
                    q.append((a, b))
        got = {at(x, y) for (x, y) in seen if at(x, y) in "rby"}
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


def check_level(lv, assets=None):
    """Print what's wrong with a level (and a summary); True if it's fine."""
    errs, warns = validate(lv["rows"], lv["label"])
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
        if not (1 <= kind <= 5 and 0 < x0 <= x1 < N - 1 and 0 < y0 <= y1 < N - 1):
            errs.append("event %s: kind 1-5, a room inside the map" % (e,))
        if reward not in (0, 4, 5, 6, 9, 10, 13, 14):
            errs.append("event %s: reward must be 0 or a pickup kind" % (e,))
        room = [lv["rows"][y][x] for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]
        if kind == 4 and not any(c in DECO for c in room):
            errs.append("event %s: a shooting gallery needs decorations in its room" % (e,))
        if kind == 5 and "S" not in room:
            errs.append("event %s: a nest needs spawners (S) in its room" % (e,))
        if kind in (1, 2) and not any(c in DOORS for r in lv["rows"][max(0, y0 - 5):y1 + 6] for c in r[max(0, x0 - 5):x1 + 6]):
            warns.append("event %s: no doors to lock round its room" % (e,))
    if len(lv.get("events", [])) > 8:
        errs.append("too many events (max 8)")
    if not any("M" in r for r in lv["rows"]):
        warns.append("no map pickup (M): the minimap never appears on this level")
    print("%s  %s  (%d lights)" % (lv["label"], lv["name"], len(lv.get("lights", []))))
    for e in errs:
        print("   ERROR", e)
    for w in warns:
        print("  ", w)
    return not errs
