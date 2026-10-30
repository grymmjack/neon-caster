"""lvldress.py - art direction for a built sector: LOOKS ONLY.

The level kit's builders lay out where you walk and fight. This dresses the
result the way a person in the editor would - with the editor's newer
tools, used for a reason:

  * every room has a ROLE (where you start, the exit, a keycard's room, a
    hazard, a hall, a corridor) and a COLOUR for it - the keycard's own
    colour, the exit's green, a hazard's liquid - so a room tells you what
    it is before you've seen what's in it;
  * walls get TRIM in pieces (a dark skirting and a neon line low down;
    a second line high up in the rooms that matter): the wall's own picture
    runs on unbroken above them;
  * light comes FROM SOMETHING: a wall light is a lit strip on its wall
    (a piece of the face) with a lamp-less light in front of it;
  * key doors, the exit and sealed doors get a light of their colour each
    side and a tinted floor in front - you can read the way round from a
    distance;
  * each room's own ambient (a cell light) leans to its colour;
    corridors' walls are dimmed and greyed a little, so rooms stand out;
  * floors near liquids are wetter;
  * glowing props (consoles, screens, holograms, tanks, pods) take their
    room's colour.

Nothing here changes what you can walk on, shoot or pick up: map rows,
heights, blocks, things and triggers are untouched, so a sector's demos
stay in step. A face, light or look the builder already set is left alone.

    python3 lvldress.py IN.txt [-o OUT.txt] [--style NAME] [--name NAME]
    python3 lvldress.py IN.txt --report      what it would do, nothing written

Styles (picked from the sector's pictures and name, or --style): neon,
infernal, cold, toxic, data, clinical, outdoor.
"""
import os, sys, re
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lvlkit

WALLS = lvlkit.WALLS
DOORS = lvlkit.DOORS
SIDES = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
OPP = {"N": "S", "S": "N", "E": "W", "W": "E"}
BLOCKING = set(WALLS) | set(DOORS) | set("?%@$;=-")   # (not open floor: walls, doors, secrets, stations, panels, glass, bars)
GLOWING = set("AFIOQ")   # console, screens, specimen tank, cryo pod, hologram

# Budgets (the game's limits, with room to spare for the editor)
PC_BUDGET = 900      # faces in pieces (LEVEL/PIECES.BI's PC_MAX is 1024)
FACE_BUDGET = 3600   # [faces] lines (MAX_FACES 4000)
LIGHTS_48 = 150      # lights in a 48-cell sector (each one costs a little every frame)
LIGHTS_BIG = 420     # ...in a bigger one (MAX_LIGHTS 1024 - lamps and glows come out of it too)

# Wall trim trees (LEVEL/PIECES.BI: V splits top | bottom; leaves top to bottom)
TRIM = "V.V.V.V.."           # 1 [0,1/2] 2 [1/2,3/4] 3 [3/4,7/8] | 4 line [7/8,15/16] | 5 skirting [15/16,1]
COVE = "VVVV....V.V.V.."     # 1 high line [0,1/16] 2-6 wall | 7 line | 8 skirting
STRIP = "#%s"   # (a made colour: a solid piece)

STYLES = {
    # base: skirting; line: the neon line; light: wall lights; corr: corridors' walls' filters
    "neon":     dict(base="12141C", line="28E6FF", high="FF4FD8", light=(110, 200, 255), corr="B-12S-25", wet=4),
    "infernal": dict(base="1A0E08", line="FF7A1A", high="FFB040", light=(255, 150, 70), corr="B-15S-15", wet=0),
    "cold":     dict(base="0C1620", line="9FEFFF", high="E0FAFF", light=(170, 225, 255), corr="B-10S-30", wet=5),
    "toxic":    dict(base="0E180E", line="7CFF4F", high="C8FF3C", light=(150, 255, 130), corr="B-14S-20", wet=6),
    "data":     dict(base="100C1C", line="A060FF", high="28E6FF", light=(150, 120, 255), corr="B-12S-25", wet=3),
    "clinical": dict(base="1C2026", line="4FD0FF", high="FFFFFF", light=(220, 235, 255), corr="B-8S-35", wet=2),
    "outdoor":  dict(base="141018", line="FF3FA0", high="28E6FF", light=(255, 120, 200), corr="", wet=7),
}
STYLE_WORDS = [  # (first match wins: words in the sector's pictures and name)
    ("infernal", ("furnace", "molten", "lava", "reactor", "forge", "scorched", "obsidian", "core")),
    ("cold", ("cryo", "frost", "ice", "cold", "freez")),
    ("toxic", ("biolab", "greenhouse", "moss", "slime", "acid", "vines", "greenpipes", "soil")),
    ("data", ("servers", "datastream", "code", "archive", "circuit", "jack")),
    ("clinical", ("white", "lab", "tiles")),
    ("outdoor", ("sky", "roof", "street", "market", "storm")),
]

KEY_COL = {"r": "FF3B3B", "b": "3B7BFF", "y": "FFD23B"}
DOOR_COL = {"R": "FF3B3B", "B": "3B7BFF", "Y": "FFD23B", "E": "5AFF78", "!": "B05AFF"}
LIQ_COL = {"l": "FF6A1A", "a": "9CFF2E", "p": "C04BFF", "s": "6FE03A", "w": "3FB4FF"}
ROLE_ORDER = ["exit", "key", "start", "hazard", "sealed", "hall", "room", "corridor"]


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hexc(c):
    return "%02X%02X%02X" % tuple(max(0, min(255, int(round(v)))) for v in c)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def pick_style(lv):
    words = " ".join(lv["walls"] + lv["floors"] + lv["ceils"] + [lv["name"]]).lower()
    for st, ws in STYLE_WORDS:
        if sum(words.count(w) for w in ws) >= 2:
            return st
    return "neon"


class Dresser:
    def __init__(self, lv, style=None):
        self.lv = lv
        self.N = len(lv["rows"])
        self.g = [list(r) for r in lv["rows"]]
        self.style_name = style or pick_style(lv)
        self.st = STYLES[self.style_name]
        n = self.N
        fl = lv.get("floor") or ["." * n] * n
        ce = lv.get("ceiling") or ["." * n] * n
        self.fh = [[lvlkit.hval(fl[y][x], 0) for x in range(n)] for y in range(n)]
        self.ch = [[lvlkit.hval(ce[y][x], 8) for x in range(n)] for y in range(n)]
        lq = lv.get("liquid") or []
        self.lq = [list(r) for r in lq] if lq else [["."] * n for _ in range(n)]
        self.taken = set()   # (x, y, face) the builder already set
        self.pc_used = 0
        for line in lv.get("faces", []):
            p = [s.strip() for s in line.split(",")]
            if len(p) >= 4:
                self.taken.add((int(p[0]), int(p[1]), p[2]))
                if p[3] == "3":
                    self.pc_used += 1
        self.looked = {tuple(int(v) for v in l.split(",")[:2]) for l in lv.get("looks", [])}
        self.new_faces, self.new_lights, self.new_cl, self.new_looks = [], [], [], []
        self.notes = []

    # --- the map ----------------------------------------------------------
    def open(self, x, y):
        return 0 <= x < self.N and 0 <= y < self.N and self.g[y][x] not in BLOCKING

    def width(self, x, y):
        """How wide the floor is at (x, y): the shorter of its runs across and down."""
        def run(dx, dy):
            k = 1
            for s in (1, -1):
                i = 1
                while self.open(x + dx * i * s, y + dy * i * s) and i < 8:
                    i += 1
                k += i - 1
            return k
        return min(run(1, 0), run(0, 1))

    def rooms(self):
        """Each open cell's room: the last [zones] rectangle over it (as the
        game reads them), else its part of the floor between doors."""
        n = self.N
        room = [[-1] * n for _ in range(n)]
        zones = self.lv.get("zones", [])
        for k, z in enumerate(zones):
            x0, y0, x1, y1 = z[:4]
            for y in range(max(0, y0), min(n - 1, y1) + 1):
                for x in range(max(0, x0), min(n - 1, x1) + 1):
                    if self.open(x, y):
                        room[y][x] = k
        nxt = len(zones)
        for y in range(n):
            for x in range(n):
                if room[y][x] == -1 and self.open(x, y):
                    q = deque([(x, y)]); room[y][x] = nxt
                    while q:
                        cx, cy = q.popleft()
                        for dx, dy in SIDES.values():
                            ax, ay = cx + dx, cy + dy
                            if self.open(ax, ay) and room[ay][ax] == -1:
                                room[ay][ax] = nxt; q.append((ax, ay))
                    nxt += 1
        self.room = room
        self.cells = {}
        for y in range(n):
            for x in range(n):
                if room[y][x] >= 0:
                    self.cells.setdefault(room[y][x], []).append((x, y))
        self.nzones = len(zones)

    def roles(self):
        """What each room is for, and its colour."""
        self.role, self.col = {}, {}
        for r, cells in self.cells.items():
            chars = {self.g[y][x] for (x, y) in cells}
            near = {self.g[y + dy][x + dx] for (x, y) in cells for dx, dy in SIDES.values()
                    if 0 <= x + dx < self.N and 0 <= y + dy < self.N}
            liq = [self.lq[y][x] for (x, y) in cells if self.lq[y][x] in "lapsw"]
            narrow = sorted(self.width(x, y) for (x, y) in cells)[len(cells) // 2]
            line = rgb(self.st["line"])
            if "E" in near:
                role, col = "exit", rgb(DOOR_COL["E"])
            elif chars & set("rby"):
                role, col = "key", rgb(KEY_COL[sorted(chars & set("rby"))[0]])
            elif chars & lvlkit.START:
                role, col = "start", line
            elif len(liq) >= 3 and any(c in "laps" for c in liq):
                k = max("laps", key=liq.count)
                role, col = "hazard", rgb(LIQ_COL[k])
            elif "!" in near:
                role, col = "sealed", rgb(DOOR_COL["!"])
            elif narrow <= 2 and len(cells) >= 3:
                role, col = "corridor", mix(line, (60, 70, 90), 0.5)
            elif len(cells) >= 70:
                role, col = "hall", line
            else:
                role, col = "room", line
            self.role[r], self.col[r] = role, col

    # --- walls --------------------------------------------------------------
    def wall_faces(self, r):
        """(wall x, wall y, face, open x, open y) round room r."""
        out = []
        for (x, y) in self.cells[r]:
            for s, (dx, dy) in SIDES.items():
                wx, wy = x + dx, y + dy
                if 0 <= wx < self.N and 0 <= wy < self.N and self.g[wy][wx] in WALLS:
                    out.append((wx, wy, OPP[s], x, y))
        return out

    def leaf(self, pic="", rot=0, slide=0, stretch=0, tint=0, amt=50, col="FFFFFF", start=0, fx=""):
        f = [pic, str(rot), str(slide), str(stretch), str(tint), str(amt), col, str(start), fx]
        last = 1
        if rot: last = 2
        if slide: last = 3
        if stretch: last = 4
        if tint: last = 7
        if start: last = 8
        if fx: last = 9
        return "*".join(f[:last])

    def put_face(self, x, y, face, tree, leaves):
        if (x, y, face) in self.taken:
            return False
        assert tree_leaves(tree) == len(leaves), (tree, leaves)
        self.taken.add((x, y, face))
        self.new_faces.append("%d, %d, %s, 3, %s, %s" % (x, y, face, tree, "|".join(leaves)))
        self.pc_used += 1
        return True

    def trim_room(self, r):
        role, col = self.role[r], self.col[r]
        st = self.st
        faces = [f for f in self.wall_faces(r) if (f[0], f[1], f[2]) not in self.taken]
        if not faces:
            return
        if self.pc_used + len(faces) > PC_BUDGET or len(self.lv.get("faces", [])) + len(self.new_faces) + len(faces) > FACE_BUDGET:
            self.notes.append("room %d (%s): no trim, over the budget" % (r, role))
            return
        line = hexc(col)
        base = st["base"]
        wall = self.leaf(fx=st["corr"]) if role == "corridor" and st["corr"] else ""
        if role == "corridor":
            line = hexc(mix(col, rgb(base), 0.35))   # (a dim line: it leads on, it doesn't shout)
        lamps = self.lamp_spots(r, faces) if role not in ("corridor",) else set()
        for (wx, wy, f, ox, oy) in faces:
            span = self.ch[oy][ox] - self.fh[oy][ox]
            if span < 6 or span > 40:
                continue   # (a crawlway, or open sky: no skirting)
            if (wx, wy, f) in lamps:   # (the strip in the room's own colour, full: neon needs bright AND colourful)
                self.put_face(wx, wy, f, LAMP_TREE, lamp_leaves(self, wall, hexc(col) if role != "corridor" else self.st["line"]))
                continue
            # A piece is a part of the wall's height: in a tall room a sixteenth is a thick bar, so
            # the lines there go quieter (and the high one only where the ceiling's near)
            low = line if span <= 16 or role in ("exit", "key", "hazard", "sealed") else hexc(mix(rgb(line), rgb(base), 0.45))
            if role in ("exit", "key", "start", "sealed", "hall") and span <= 16:
                self.put_face(wx, wy, f, COVE, [STRIP % hexc(mix(col, rgb(base), 0.2))] + [wall] * 5 + [STRIP % low, STRIP % base])
            else:
                self.put_face(wx, wy, f, TRIM, [wall] * 3 + [STRIP % low, STRIP % base])

    def lamp_hex(self, r):
        role, c = self.role[r], self.col[r]
        if role in ("room", "hall", "start"):
            c = mix(self.st["light"], c, 0.5)
        return hexc(c)

    def lamp_spots(self, r, faces):
        """Wall lights round room r: on long walls, spaced out, away from
        doors and corners - each a lit strip on its face and a light."""
        cells = self.cells[r]
        if len(cells) < 16:
            return set()
        want = min(8, max(2, len(cells) // 22))
        cand = []
        for (wx, wy, f, ox, oy) in faces:
            if self.width(ox, oy) < 3 or self.ch[oy][ox] - self.fh[oy][ox] < 8:
                continue
            dx, dy = SIDES[f]   # (the face looks this way, into the room)
            ux, uy = abs(dy), abs(dx)   # (along the wall)
            ok = all(0 <= wy + uy * i < self.N and 0 <= wx + ux * i < self.N
                     and self.g[wy + uy * i][wx + ux * i] in WALLS and self.open(ox + ux * i, oy + uy * i) for i in (-1, 1))
            if not ok or self.g[oy][ox] in lvlkit.DECO:
                continue
            cand.append((wx, wy, f, ox, oy))
        cand.sort(key=lambda c: (c[4], c[3], c[2]))
        got = []
        for c in cand:
            if all(abs(c[3] - o[3]) + abs(c[4] - o[4]) >= 5 for o in got):
                got.append(c)
        if len(got) > want:   # (spread them: every k-th)
            k = len(got) / want
            got = [got[int(i * k)] for i in range(want)]
        out = set()
        col = rgb(self.lamp_hex(r))
        for (wx, wy, f, ox, oy) in got:
            if not self.light_room():
                break
            dx, dy = SIDES[f]
            lx = ox + 0.5 - dx * 0.25   # (a quarter-cell out from the wall: not the editor's 0.12, which would tint the whole face)
            ly = oy + 0.5 - dy * 0.25
            self.new_lights.append((round(lx, 3), round(ly, 3), 3.5, 160) + tuple(int(v) for v in col) + (0, 1))
            out.add((wx, wy, f))
        return out

    def light_room(self):
        most = LIGHTS_48 if self.N <= 64 else LIGHTS_BIG
        return len(self.lv["lights"]) + len(self.new_lights) < most

    # --- doors ----------------------------------------------------------------
    def doors(self):
        """Key doors, sealed doors and the exit: a light of their colour each
        side, and a floor in front tinted it."""
        for y in range(self.N):
            for x in range(self.N):
                c = self.g[y][x]
                if c not in DOOR_COL:
                    continue
                col = rgb(DOOR_COL[c])
                for s, (dx, dy) in SIDES.items():
                    ox, oy = x + dx, y + dy
                    if not self.open(ox, oy):
                        continue
                    if self.light_room():
                        self.new_lights.append((round(ox + 0.5 - dx * 0.3, 3), round(oy + 0.5 - dy * 0.3, 3), 1.8, 150)
                                               + tuple(int(v) for v in col) + (2 if c == "E" else 0, 1))
                    if self.pc_used < PC_BUDGET and self.g[oy][ox] in ".":
                        self.put_face(ox, oy, "F", ".", [self.leaf(tint=2, amt=38, col=hexc(col))])

    # --- the rest ---------------------------------------------------------------
    def fill(self):
        """Each zoned room's ambient leans to its colour (a cell light)."""
        amb = self.lv["ambient"]
        b0, c0 = amb[0], amb[1:4]
        have = {tuple(c[:4]) for c in self.lv.get("cell_lights", [])}
        for k, z in enumerate(self.lv.get("zones", [])):
            if k not in self.role:
                continue
            role = self.role[k]
            lean = {"exit": 0.3, "key": 0.3, "hazard": 0.35, "sealed": 0.3, "start": 0.15, "hall": 0.1, "room": 0.12, "corridor": 0.05}[role]
            bri = b0 + {"corridor": -18, "hall": 6, "exit": 8}.get(role, 0)
            c = mix(c0, self.col[k], lean)
            r4 = tuple(z[:4])
            if r4 in have:
                continue
            self.new_cl.append(r4 + (max(0, min(256, int(bri))),) + tuple(int(v) for v in c) + (0,))

    def wet(self):
        """Floors near liquid wetter (OpenGL's reflections)."""
        w = self.st["wet"]
        if w is None:
            return 0
        rows = [list(r) for r in (self.lv.get("wetness_rows") or ["." * self.N] * self.N)]
        liq = [(x, y) for y in range(self.N) for x in range(self.N) if self.lq[y][x] != "."]
        if not liq:
            return 0
        dist = {}
        q = deque()
        for c in liq:
            dist[c] = 0; q.append(c)
        while q:
            x, y = q.popleft()
            if dist[(x, y)] >= 3:
                continue
            for dx, dy in SIDES.values():
                a = (x + dx, y + dy)
                if self.open(*a) and a not in dist:
                    dist[a] = dist[(x, y)] + 1; q.append(a)
        n = 0
        for (x, y), d in dist.items():
            if 1 <= d <= 3 and rows[y][x] == ".":
                rows[y][x] = str(min(9, w + 2 * (4 - d)))
                n += 1
        self.lv["wetness_rows"] = ["".join(r) for r in rows]
        return n

    def props(self):
        """Glowing props take their room's colour."""
        for y in range(self.N):
            for x in range(self.N):
                if self.g[y][x] in GLOWING and (x, y) not in self.looked:
                    r = self.room[y][x] if self.room[y][x] >= 0 else None
                    if r is None:
                        continue
                    self.new_looks.append("%d, %d, 2, 30, %s, 100" % (x, y, hexc(self.col[r])))

    # --- all of it ----------------------------------------------------------------
    def run(self):
        # (decorations stand on open floor: a room is the floor round them too)
        self.rooms()
        self.roles()
        self.doors()
        for role in ROLE_ORDER:
            for r in sorted(self.cells, key=lambda r: -len(self.cells[r])):
                if self.role[r] == role:
                    self.trim_room(r)
        self.fill()
        nwet = self.wet()
        self.props()
        lv = self.lv
        lv["faces"] = list(lv.get("faces", [])) + self.new_faces
        lv["lights"] = list(lv["lights"]) + self.new_lights
        lv["cell_lights"] = list(lv.get("cell_lights", [])) + self.new_cl
        lv["looks"] = list(lv.get("looks", [])) + self.new_looks
        slots = set()
        for f in self.new_faces:
            slots |= set(re.findall(r"#[0-9A-F]{6}", f))
        counts = {}
        for r in self.role.values():
            counts[r] = counts.get(r, 0) + 1
        self.summary = ("style %s; rooms %s; %d faces in pieces (%d in all of %d), %d lights (%d in all), %d cell lights, "
                        "%d wetter floors, %d props tinted, %d made colours"
                        % (self.style_name, ", ".join("%d %s" % (v, k) for k, v in sorted(counts.items())),
                           len(self.new_faces), self.pc_used, PC_BUDGET, len(self.new_lights), len(lv["lights"]),
                           len(self.new_cl), nwet, len(self.new_looks), len(slots)))
        return lv


# The wall light's tree: a strip an eighth wide down the middle, from
# sixteenths either side of the half - left half H.H.H.. (its last piece
# the strip's left), right half HHH.... (its first the strip's right)
LAMP_TREE = "H" + "H.H.H.." + "HHH...."


def lamp_leaves(d, wall, strip):
    return [wall, wall, wall, STRIP % strip, STRIP % strip, wall, wall, wall]


def tree_leaves(shape, depth=4):
    """How many pieces tree shape has, as the game reads it (LEVEL/PIECES.BM's
    PcRects): -1 if it isn't one, or is finer than PC_DEPTH."""
    n, stack = 0, [0]
    for c in shape:
        if not stack:
            return -1
        d = stack.pop()
        if c in "HV":
            if d >= depth:
                return -1
            stack += [d + 1, d + 1]
        elif c == ".":
            n += 1
        else:
            return -1
    return n if not stack and 0 < n <= 16 else -1


assert tree_leaves(TRIM) == 5 and tree_leaves(COVE) == 8 and tree_leaves(LAMP_TREE) == 8 and tree_leaves(".") == 1


MARK = "lvldress:"   # (the marker comment: how many of each list the builder made, before the dressing)
DRESSED = ("lights", "faces", "cell_lights", "looks")


def dress(lv, style=None):
    """Dress level dict lv (as read_level_file gives it); returns it and a summary.
    lv["_plain"] remembers what the builder made, for the marker line."""
    plain = {k: len(lv.get(k) or []) for k in DRESSED}
    plain["wet"] = "keep" if any(r.strip(".") for r in (lv.get("wetness_rows") or [])) else "clear"
    d = Dresser(lv, style)
    if plain["wet"] == "keep":   # (a builder's own wet floors: left as they are)
        d.st = dict(d.st, wet=None)
    d.run()
    lv["_plain"] = plain
    return lv, d.summary, d.notes


def mark_line(lv):
    p = lv["_plain"]
    return MARK + " " + ", ".join("%s %s" % (k, p[k]) for k in DRESSED + ("wet",)) + \
        " - what the builder made; the rest is lvldress.py's (read_plain takes it off)"


def write_dressed(path, lv, comment=()):
    lvlkit.write_level_file(path, lv, list(comment) + [mark_line(lv)])


def is_dressed(path):
    return any(l.startswith("' " + MARK) for l in open(path).read().split("\n")[:60])


def read_plain(path, label=None):
    """A level file as its builder made it: a dressed one with the dressing taken off."""
    lv = lvlkit.read_level_file(path, label)
    for l in open(path).read().split("\n")[:60]:
        if l.startswith("' " + MARK):
            for part in l[len("' " + MARK):].split(" - ")[0].split(","):
                k, v = part.split()
                if k == "wet":
                    if v == "clear":
                        lv["wetness_rows"] = []
                else:
                    lv[k] = lv[k][:int(v)]
            break
    return lv


SETS = {"levels": ".", "new": "new", "remix": "remix", "huge": "huge"}


def dress_file(path, out=None, style=None, name=None, redo=False, report=False, quiet=False):
    """Dress one file (in place, or to out). A dressed one is undressed first with redo, else left."""
    if is_dressed(path) and not redo:
        print(path + ": already dressed (--redo dresses it again)")
        return True
    lv = read_plain(path)
    keep = {k: lv[k] for k in ("rows", "floor", "ceiling", "blocks", "things", "triggers", "events", "monsters", "doors", "liquid", "lifts", "pads", "notes", "nudges")}
    lv, summary, notes = dress(lv, style)
    assert all(lv[k] == v for k, v in keep.items()), "dressing changed something you play"
    if name:
        lv["name"] = name
    print(path + ": " + summary)
    if not quiet:
        for n in notes:
            print("  " + n)
    if report:
        return True
    ok = lvlkit.check_level(lv, os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) if not quiet else True
    head = [l[2:] for l in open(path).read().split("\n")[:60] if l.startswith("' ") and not l.startswith("' " + MARK)]
    doc = head[len(lvlkit.LEVEL_HEADER.rstrip("\n").split("\n")):]   # (the builder's own comment lines, kept)
    write_dressed(out or path, lv, doc)
    return ok


def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description="Dress a built sector: looks only.")
    ap.add_argument("level", nargs="?")
    ap.add_argument("-o", "--out")
    ap.add_argument("--set", choices=sorted(SETS), action="append", help="dress a whole set in place (with --write)")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--redo", action="store_true", help="take an earlier dressing off first")
    ap.add_argument("--in-place", action="store_true", help="dress a sector of your own (custom/) in its own file")
    ap.add_argument("--style", choices=sorted(STYLES))
    ap.add_argument("--name", help="a new name for the dressed sector")
    ap.add_argument("--report", action="store_true", help="say what it would do; write nothing")
    a = ap.parse_args(argv)
    here = os.path.dirname(os.path.abspath(__file__))
    if a.set:
        ok = True
        for st in a.set:
            for k in range(1, 11):
                f = os.path.join(here, SETS[st], "level%d.txt" % k)
                ok &= dress_file(f, None, a.style, None, a.redo, a.report or not a.write, quiet=True)
        if not a.write and not a.report:
            print("(nothing written: --write dresses them in place)")
        return 0 if ok else 1
    if not a.level:
        ap.error("a level file, or --set")
    if not a.out and not a.report and os.sep + "custom" + os.sep in os.path.abspath(a.level) and not a.in_place:
        ap.error("that's a sector of your own: -o a new file (or --in-place, if you mean it)")
    return 0 if dress_file(a.level, a.out, a.style, a.name, a.redo, a.report) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
