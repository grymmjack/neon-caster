"""NEW SECTORS: ten more sectors for NEON-CASTER, built with the level kit
on everything the game has grown since the first ten - blocks (solid
boxes inside a cell: pillars, thin walls, the backs of alcoves), decorations
moved off their cell's middle, liquids (water, poison, slime, lava, acid),
loot tables, lockdowns that slam shut, lasers, lifts, heights, skies, glass,
event rooms, triggers, pictures on single faces and lights that tint them.

    python3 newsectors.py            build every sector and check it
    python3 newsectors.py -show      ...and print the maps
    python3 newsectors.py --write    build, check, and (if all is well) write
                                     new/level1.txt .. new/level10.txt - the
                                     files GAME > NEW SECTORS plays
    python3 newsectors.py --check    just check the files as they are

The game plays them as a set of ten (sectorSet 1): a new game starts in
sector 1 with only the blaster, and each sector's music and NEXUS's words
go by its number, as in the first ten.

THE TEN (and what each shows off):

 1 ARRIVAL DOCK      a landing hall of slim lit posts and alcoves with
                     terminals, a flooded loading channel, crates worth
                     kicking (loot), the first lockdown, the scatter gun
 2 THE AQUEDUCT      water everywhere: channels, a reservoir crossed on
                     lifts, slime in the drains, gunners on ledges (heads
                     up), a laser gallery, the repeater
 3 NEON MARKET       outdoors at night (sky): market stalls built of thin
                     block walls, vending machines in alcoves, thieves and
                     their hoard, a shooting gallery, drones
 4 ACID WORKS        vats of acid (it eats armour), catwalks, pressure
                     plates, a data station sealing the vat room, the railgun
 5 THE FORGE         lava rivers crossed on lifts, fire traps, a blackout,
                     heavies, generators in alcoves
 6 THE CHAPEL        a machine cathedral: a nave of slim pillars three walls
                     high, shrines (alcoves) with holograms, a poison font, a
                     survive lockdown, a spawner nest
 7 COLD STORAGE      cryo vaults behind glass, cubicles of thin block walls,
                     specimen tanks in alcoves, a freezer shaft (death pit),
                     an ice-floored hall
 8 THE SKYWAY        outdoors in a storm: rooftops, bridges and lifts over a
                     street that kills, sentries, a cutter on the gantry
 9 THE ARCHIVE       data halls of rack alcoves, laser grids, closets of
                     stalkers, a cutter, a code terminal and a data station
10 NEXUS HEART       the finale: the overseer's arena - a lava moat, a ring of
                     lit pillars, lockdowns on the way in
"""
import os, sys, random
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from lvlkit import N, validate, check_level, write_level_file, read_level_file
from showcase import Show
import levels as camp   # the first ten's dressing (closets, windows, stations, terminals...)

ASSETS = os.path.dirname(HERE)
OUT = os.path.join(HERE, "new")
WALL_OF = {"#": 1, "N": 2, "C": 3, "K": 4, "P": 5, "G": 6}
SIDE_D = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
OPP = {"N": "S", "S": "N", "E": "W", "W": "E"}
DECO = lvlkit.DECO
PROBLEMS = []


def fail(msg):
    print("  PROBLEM:", msg)
    PROBLEMS.append(msg)


class Sector(Show):
    """A showcase map plus helpers for the newer pieces."""

    def __init__(self, fill="#"):
        super().__init__(fill)
        self.loot = []          # [loot] lines
        self.block_pics = {}    # (x, y, side) -> picture, to count slots
        self.block_glows = []   # (pic, r, g, b, amt, fx)
        self.puzzles = ""

    # --- rooms and heights -------------------------------------------------
    def room(self, x0, y0, x1, y1, floor=None, ceil=None, zone=None):
        """Carve a room; optionally its floor (eighths), ceiling (eighths, 8 =
        one wall) and floor/ceiling zone (f, c)."""
        self.rect(x0, y0, x1, y1, ".")
        if floor is not None:
            self.floor(x0, y0, x1, y1, floor, only_open=False)
        if ceil is not None:
            self.ceiling(x0, y0, x1, y1, ceil, only_raise=False)
        if zone:
            self.zone(x0, y0, x1, y1, zone[0], zone[1])

    # --- blocks ------------------------------------------------------------
    def blk(self, x, y, x0, y0, x1, y1, wall=1, pics=None, glow=None, fx=0, bright=150, rad=2.0):
        """A block in open cell (x, y): edges in eighths. pics: {side: picture}
        on its sides (E S W N); glow: (r, g, b) - a light on each pictured
        side that tints it (and lights the room by it)."""
        if self.g[y][x] in lvlkit.WALLS or self.g[y][x] in lvlkit.DOORS:
            fail("block at %d,%d on '%s'" % (x, y, self.g[y][x]))
            return
        self.block(x, y, x0, y0, x1, y1, wall)
        for side, pic in (pics or {}).items():
            self.face(x, y, "B" + side, pic)
            self.block_pics[(x, y, side)] = pic
            if glow:
                ax, ay = self.block_anchor(x, y, x0, y0, x1, y1, side)
                self.light(round(ax, 4), round(ay, 4), rad, bright, *glow, fx)
                self.block_glows.append((pic,) + tuple(glow) + (int((0.35 + 0.55 * bright / 255) * 100), fx))

    @staticmethod
    def block_anchor(x, y, x0, y0, x1, y1, side):
        """Where the editor's LIGHT puts a light on a block's side: 0.12 in
        front of its middle (the game tints that side by it)."""
        bx0, bx1, by0, by1 = x + x0 / 8, x + x1 / 8, y + y0 / 8, y + y1 / 8
        if side == "E": return bx1 + 0.12, (by0 + by1) / 2
        if side == "W": return bx0 - 0.12, (by0 + by1) / 2
        if side == "S": return (bx0 + bx1) / 2, by1 + 0.12
        return (bx0 + bx1) / 2, by0 - 0.12

    def post(self, x, y, against, at=4, w=2, d=2, wall=4, pic="wall-lightstrip.png", glow=None, fx=0, faces="all"):
        """A slim post standing in cell (x, y) against its `against` edge
        (N S E W), `w` eighths wide centred on `at`, `d` deep. Its sides
        that show get `pic`; glow (r, g, b) lights the front."""
        lo, hi = max(0, at - w // 2), min(8, at - w // 2 + w)
        if against == "N": e = (lo, 0, hi, d); front = "S"
        elif against == "S": e = (lo, 8 - d, hi, 8); front = "N"
        elif against == "W": e = (0, lo, d, hi); front = "E"
        else: e = (8 - d, lo, 8, hi); front = "W"
        sides = [s for s in "NSEW" if s != against] if faces == "all" else [front]
        pics = {s: pic for s in sides} if pic else None
        self.blk(x, y, *e, wall=wall, pics=pics)
        if glow and pic:  # (one light: on its front, tinting it)
            ax, ay = self.block_anchor(x, y, *e, front)
            self.light(round(ax, 4), round(ay, 4), 2.0, 160, *glow, fx)
            self.block_glows.append((pic,) + tuple(glow) + (int((0.35 + 0.55 * 160 / 255) * 100), fx))

    def column(self, x, y, size=2, wall=3, pic=None, glow=None, fx=0):
        """A free-standing square column `size` eighths across, in the middle
        of cell (x, y)."""
        lo = 4 - size // 2
        pics = {s: pic for s in "NSEW"} if pic else None
        self.blk(x, y, lo, lo, lo + size, lo + size, wall=wall, pics=pics)
        if glow:
            self.light(x + 0.5, y + 0.5 + size / 16 + 0.12, 2.5, 140, *glow, fx)

    def thin_wall(self, x0, y0, x1, y1, edge, t=1, wall=3, pic=None):
        """A wall `t` eighths thick along the `edge` (N S E W) of every cell
        in the rectangle - partitions, stall walls, railings you can't pass."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if edge == "N": e = (0, 0, 8, t)
                elif edge == "S": e = (0, 8 - t, 8, 8)
                elif edge == "W": e = (0, 0, t, 8)
                else: e = (8 - t, 0, 8, 8)
                sides = {"N": "S", "S": "N", "W": "E", "E": "W"}[edge]
                self.blk(x, y, *e, wall=wall, pics={sides: pic} if pic else None)

    def alcove(self, x, y, opens, depth=4, floor=4, ceil=7, deco="t", nudge=None, glow=(60, 220, 255), fx=2, wall=None, back_pic=None):
        """Wall cell (x, y) made an alcove opening `opens` (N S E W): a block
        fills its back (8 - depth eighths), its floor raised and ceiling
        lowered (eighths), a decoration moved into the open part, and a
        pulsing light in front of it."""
        c = self.g[y][x]
        if c not in lvlkit.WALLS:
            fail("alcove at %d,%d isn't a wall ('%s')" % (x, y, c))
            return
        w = WALL_OF[c] if wall is None else wall
        self.g[y][x] = deco or "."
        b = 8 - depth
        if opens == "S": e = (0, 0, 8, b)
        elif opens == "N": e = (0, depth, 8, 8)
        elif opens == "E": e = (0, 0, b, 8)
        else: e = (depth, 0, 8, 8)
        self.blk(x, y, *e, wall=w, pics={opens: back_pic} if back_pic else None)
        self.fh[y][x] = hstr(floor)
        self.ch[y][x] = "." if ceil == 8 else hstr(ceil)
        if deco:
            n = nudge if nudge is not None else min(3, b // 2 + 1)
            dx, dy = SIDE_D[opens]
            self.nudge(x, y, dx * n, dy * n)
        if glow:
            dx, dy = SIDE_D[opens]
            self.light(round(x + 0.5 + dx * 0.3, 2), round(y + 0.5 + dy * 0.3, 2), 2.5, 170, *glow, fx)

    # --- liquids -----------------------------------------------------------
    def pool(self, x0, y0, x1, y1, kind, sink=4, depth=None):
        """A pool: floors sunk `sink` eighths (from where they are), filled
        with `kind` (w p s l a) to just under the floor round it."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.g[y][x] in lvlkit.WALLS or self.g[y][x] in lvlkit.DOORS:
                    continue
                f = self.floor_at(x, y) - sink
                self.fh[y][x] = hstr(f)
                d = depth if depth is not None else max(1, min(8, sink - 1))
                self.liquid(x, y, kind, d)

    # --- the rest ----------------------------------------------------------
    def loot_line(self, line):
        self.loot.append(line)

    def level(self, label, name, walls, floors, ceils):
        lv = super().level(label, name, walls, floors, ceils)
        lv["liquid"] = ["".join(r) for r in self.lq]
        lv["liquid_depth"] = ["".join(r) for r in self.ld]
        lv["loot"] = list(self.loot)
        lv["puzzles"] = self.puzzles
        return lv

    def slots(self):
        pics, glows = super().slots()
        allp = {p for (d, p1, p2) in self.faces.values() for p in (p1, p2) if p}
        return len(allp), glows + len(set(self.block_glows))


def hstr(e):
    """The [floor]/[ceiling] character for e eighths."""
    if e == 0: return "."
    if e > 0: return camp.HUP[e]
    return "ABCDEFGH"[-e - 1]


def tight_blocks(m):
    """Cells whose block leaves no way through for a body (0.6 wide) - the
    kit's walk counts them as walls."""
    out = set()
    for (x, y, x0, y0, x1, y1, w) in m.blocks:
        free_y = max(y0, 8 - y1) / 8   # (a strip across the cell, west to east)
        free_x = max(x0, 8 - x1) / 8   # (...north to south)
        if free_y < 0.65 and free_x < 0.65:
            out.add((x, y))
    return out


def counts(m):
    g = m.g
    c = lambda s: sum(1 for r in g for ch in r if ch in s)
    glowing = c("itlnAFILOQ")   # (decorations with a light of their own)
    return dict(items=c("rby+*uae234Mqj"), mons=c("mghcskwzT"), decos=c("".join(DECO)),
                lights=len(m.lights) + glowing + c("E") + c("&"))


def reach_with_blocks(lv):
    """validate() on the map with tight blocks as walls."""
    tb = set()
    for (x, y, x0, y0, x1, y1, w) in lv.get("blocks", []):
        if max(y0, 8 - y1) < 5.2 and max(x0, 8 - x1) < 5.2:
            tb.add((x, y))
    rows = [list(r) for r in lv["rows"]]
    for (x, y) in tb:
        if rows[y][x] == ".":
            rows[y][x] = "#"
    return validate(["".join(r) for r in rows], lv["label"], pairs=lv.get("pads", []))


def finish(m, lev, dress=None):
    """The campaign's dressing on a built map (dress: a dict of how many of
    each), with blocks' and lifts' cells kept clear of it."""
    keep = {(x, y) for (x, y, *_r) in m.blocks}
    keep |= {(x, y) for (x0, y0, x1, y1, *_r) in m.lifts for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}
    keep |= {(x, y) for y in range(N) for x in range(N) if m.lq[y][x] != "."}
    was = {}
    for (x, y) in keep:
        if m.g[y][x] == ".":
            was[(x, y)] = "."
            m.g[y][x] = "~"
    if dress:
        rng = random.Random(5000 + lev)
        st, dist = camp._reach(m)
        if dress.get("hoard"): camp.dress_hoard(m, rng, dist, dress["hoard"])
        st, dist = camp._reach(m)
        if dress.get("obs"): camp.dress_observation(m, rng, dress["obs"], dist, dress.get("obskinds", "ghm"))
        st, dist = camp._reach(m)
        if dress.get("windows"): camp.dress_windows(m, rng, dress["windows"], dist)
        st, dist = camp._reach(m)
        if dress.get("closets"): camp.dress_closets(m, rng, dress["closets"], dist, dress.get("cmons", "c"))
        st, dist = camp._reach(m)
        if dress.get("props"): camp.dress_props(m, rng, dress.get("propchars", "xop"), dress["props"], dist)
        st, dist = camp._reach(m)
        if dress.get("lasers"): camp.dress_lasers(m, rng, dress["lasers"], dist)
        if dress.get("plates"): camp.dress_plates(m, rng, dress["plates"], dist)
        if dress.get("cutter"): camp.dress_cutter(m, rng, dist)
        if dress.get("blackout"): camp.dress_blackout(m, rng, dist, dress["blackout"])
        st, dist = camp._reach(m)
        if dress.get("station"): camp.dress_station(m, rng, dist)
    for (x, y) in was:
        if m.g[y][x] == "~":
            m.g[y][x] = "."
    for y in range(N):
        for x in range(N):
            if m.g[y][x] == "~":
                m.g[y][x] = "."
    m.headroom(8)   # (a ceiling less than a wall over its floor - a raised door's - goes up)


SECTORS = []   # (function, "SECTOR n: NAME", walls, floors, ceils, comment lines)


def sector(name, walls, floors, ceils):
    def wrap(fn):
        SECTORS.append((fn, name, walls, floors, ceils))
        return fn
    return wrap


def build_all(write=False, show=False):
    ok = True
    out = []
    for i, (fn, name, walls, floors, ceils) in enumerate(SECTORS, 1):
        print("NEW %d: %s" % (i, name))
        m = fn()
        lv = m.level("level%d" % i, name, walls, floors, ceils)
        if show:
            m.show()
        good = check_level(lv, ASSETS)
        errs, warns = reach_with_blocks(lv)
        for e in errs:
            print("  BLOCKED:", e)
        good = good and not errs
        herrs, hwarns = lvlkit.check_heights(lv)
        for e in herrs:
            print("  HEIGHTS ERROR", e)
        good = good and not herrs
        pics, glows = m.slots()
        c = counts(m)
        print("  slots %d+%d of 24; items %d, monsters %d, decorations %d, lights ~%d, events %d, lifts %d, triggers %d, blocks %d"
              % (pics, glows, c["items"], c["mons"], c["decos"], c["lights"], len(m.events), len(m.lifts), len(m.triggers), len(m.blocks)))
        for what, n, mx in (("slots", pics + glows, 24), ("items", c["items"], 64), ("monsters", c["mons"], 64),
                            ("decorations", c["decos"], 64), ("lights", c["lights"], 96), ("events", len(m.events), 16),
                            ("lifts", len(m.lifts), 16), ("triggers", len(m.triggers), 48), ("nudges", len(m.nudges), 64)):
            if n > mx:
                print("  TOO MANY %s: %d (max %d)" % (what, n, mx))
                good = False
        for (x, y, f), (d, p1, p2) in m.faces.items():
            for p in (p1, p2):
                if p and not os.path.exists(os.path.join(ASSETS, p)):
                    print("  MISSING picture", p)
                    good = False
        ok = ok and good
        doc = [l.strip() for l in (fn.__doc__ or "").strip().splitlines()]
        out.append((lv, doc))
    ok = ok and not PROBLEMS
    if write:
        if not ok:
            print("not writing: fix the problems above first")
            return False
        os.makedirs(OUT, exist_ok=True)
        for lv, doc in out:
            write_level_file(os.path.join(OUT, lv["label"] + ".txt"), lv, doc)
        print("wrote %d sectors into %s" % (len(out), os.path.normpath(OUT)))
    print("ALL GOOD" if ok else "PROBLEMS")
    return ok


# =====================================================================
# The sectors (one function each, in order)
# =====================================================================

LIT = "wall-lightstrip.png"
CYAN, PINK, GREEN, AMBER, RED, VIOLET = (80, 220, 255), (255, 80, 220), (80, 255, 140), (255, 180, 60), (255, 60, 50), (170, 90, 255)


# ---------------------------------------------------------------- 1
@sector("SECTOR 1: ARRIVAL DOCK",
        ["wall.png", "wall-concrete.png", "wall-control.png", "wall-servers.png", "wall-hull.png", "wall-transit.png"],
        ["floor-plates.png", "floor-deck.png", "floor-concrete.png", "floor-platform.png"],
        ["ceiling-lights.png", "ceiling-hull.png"])
def arrival():
    """NEW 1: ARRIVAL DOCK. You step off the shuttle into the bay (south):
    slim lit posts along its walls, terminals glowing in alcoves. North, the
    arrival hall - two walls high, a flooded loading channel across it,
    lit columns in rows. Customs (west) locks down when you walk in: kill
    the drones for the scatter gun. The red card is in the cargo hold
    (east), among shelves and crates worth kicking open. The departure
    gate (north, red door, glass onto the hall) has the exit."""
    m = Sector("#")
    m.ambient = (165, 220, 230, 255)
    m.puzzles = "multiply"
    # The shuttle bay (south): you, facing north
    m.room(16, 36, 31, 44, ceil=12, zone=(4, 2))
    m.put(24, 43, "^")
    for y in (38, 42):
        m.post(16, y, "W", wall=5, glow=CYAN)
        m.post(31, y, "E", wall=5, glow=CYAN)
    m.alcove(19, 45, "N", deco="t", glow=GREEN)
    m.alcove(29, 45, "N", deco="t", glow=GREEN)
    for (x, y, c) in ((17, 37, "W"), (30, 37, "W"), (17, 44, "x"), (30, 44, "x"), (22, 39, "M"), (26, 39, "+")):
        m.put(x, y, c)
    m.put(24, 35, "D"); m.put(24, 34, ".")
    # The arrival hall: two walls high, lit columns, the channel
    m.room(10, 19, 37, 33, ceil=16, zone=(1, 1))
    for (x0, x1) in ((10, 16), (19, 28), (31, 37)):
        m.pool(x0, 26, x1, 27, "w", sink=2, depth=2)
    for x in (14, 21, 26, 33):
        for y in (22, 30):
            m.column(x, y, size=2, wall=3, pic=LIT)
    for (x, y) in ((12, 22), (35, 22), (12, 31), (35, 31), (24, 22), (24, 31)):
        m.light(x + 0.5, y + 0.5, 7, 150, 110, 190, 255, 0)
    m.light(17.5, 26.5, 4, 130, 60, 160, 255, 2); m.light(30.5, 26.5, 4, 130, 60, 160, 255, 2)
    for (x, y, c) in ((11, 20, "x"), (12, 20, "o"), (36, 32, "x"), (36, 20, "p"), (11, 32, "p"),
                      (16, 24, "m"), (31, 24, "m"), (24, 29, "m"), (13, 29, "c"), (34, 29, "c"), (24, 21, "g"),
                      (18, 32, "a"), (30, 20, "a")):
        m.put(x, y, c)
    # glass onto the departure gate, the red door
    for x in (13, 14, 15, 16, 31, 32, 33, 34):
        m.put(x, 18, "=")
    m.put(24, 18, "R")
    # Customs (west): cubicles of thin walls; a lockdown, the scatter gun
    m.room(3, 21, 8, 29, zone=(3, 1))
    m.put(9, 25, "D")
    m.thin_wall(5, 21, 5, 23, "E", t=1, wall=3)
    m.thin_wall(5, 27, 5, 29, "E", t=1, wall=3)
    for (x, y, c) in ((4, 22, "d"), (4, 23, "Z"), (4, 28, "d"), (4, 27, "Z"), (7, 21, "t"), (7, 29, "U"), (3, 22, "W")):
        m.put(x, y, c)
    m.nudge(7, 21, 0, -2); m.nudge(7, 29, 0, 2)
    m.put(2, 25, "$")
    m.event(1, 3, 21, 8, 29, 4, 1, 7)
    # The cargo hold (east): shelves, crates, the red card
    m.room(39, 13, 44, 31, ceil=12, zone=(3, 2))
    m.put(38, 26, "H")
    for y in (17, 21, 25):
        m.thin_wall(41, y, 44, y, "S", t=2, wall=4, pic="wall-servers.png")
    for (x, y, c) in ((42, 15, "x"), (43, 16, "x"), (44, 18, "x"), (42, 22, "x"), (44, 23, "o"), (43, 28, "x"),
                      (44, 30, "x"), (40, 30, "u"), (44, 14, "r"), (40, 19, "g"), (43, 27, "g"), (40, 15, "c"), (39, 29, "e")):
        m.put(x, y, c)
    m.light(41.5, 15.5, 5, 140, 255, 200, 120, 1); m.light(41.5, 27.5, 5, 140, 255, 200, 120, 0)
    # The departure gate (north): a counter, holograms, the exit
    m.room(14, 8, 34, 17, ceil=12, zone=(2, 2))
    m.thin_wall(17, 12, 22, 12, "S", t=2, wall=6)
    m.thin_wall(26, 12, 31, 12, "S", t=2, wall=6)
    m.alcove(18, 7, "S", deco="Q", glow=PINK)
    m.alcove(30, 7, "S", deco="Q", glow=PINK)
    m.put(24, 7, "E")
    m.post(23, 8, "N", at=7, w=2, d=2, wall=5, glow=GREEN)
    m.post(25, 8, "N", at=1, w=2, d=2, wall=5, glow=GREEN)
    for (x, y, c) in ((15, 9, "W"), (33, 9, "W"), (16, 16, "g"), (32, 16, "g"), (24, 10, "h"), (20, 15, "+"), (28, 15, "e")):
        m.put(x, y, c)
    m.light(24.5, 13.5, 8, 150, 255, 255, 255, 0)
    m.loot_line("crate    = ammo:30, shells:25, medkit:20, armor:10")
    m.loot_line("locker   = armor:40, medkit:30, overcharge:10, -")
    finish(m, 1, dict(closets=1, cmons="c", windows=1, lasers=1))
    return m



# ---------------------------------------------------------------- 2
@sector("SECTOR 2: THE AQUEDUCT",
        ["wall-brick.png", "wall-greenpipes.png", "wall-moss.png", "wall-grate.png", "wall-slime.png", "wall-pipes.png"],
        ["floor-cobbles.png", "floor-rustgrate.png", "floor-concrete.png", "floor-murky.png"],
        ["ceiling-pipes.png", "sky-storm.png"])
def aqueduct():
    """NEW 2: THE AQUEDUCT. The city's water runs through here. From the
    intake (south-west), a laser-swept duct leads to the aqueduct hall -
    three walls high, a channel down its middle between lit piers, ledges
    a wall up on both sides where gunners wait (aim for their heads). The
    pump room (west) seals you in: survive, and the repeater is yours.
    Behind the red door, past another laser, the reservoir: deep water,
    stairs out at its north end, lifts bobbing out to the island with the
    blue card. The outflow (north, blue door) is open to the storm - the
    exit is there."""
    m = Sector("#")
    m.ambient = (175, 205, 235, 250)
    m.puzzles = "sum"
    # The intake: you, facing north; a duct with a laser to the hall
    m.room(3, 36, 9, 44, zone=(3, 1))
    m.put(6, 43, "^")
    m.put(10, 40, "D"); m.rect(11, 40, 13, 40)
    m.event(9, 12, 40, 12, 40, 75, 75)
    for (x, y, c) in ((4, 37, "a"), (8, 38, "M"), (3, 44, "x"), (9, 44, "o"), (5, 40, "m")):
        m.put(x, y, c)
    m.light(6.5, 39.5, 5, 140, 120, 200, 255, 0)
    # The aqueduct hall: three walls high, the channel, piers, ledges
    m.room(14, 6, 33, 44, ceil=24, zone=(1, 1))
    for (y0, y1) in ((6, 14), (16, 29), (31, 44)):
        m.pool(22, y0, 25, y1, "w", sink=2, depth=2)
    for y in (10, 18, 26, 34, 40):
        m.column(20, y, size=3, wall=2, pic=LIT if y in (18, 34) else None)
        m.column(27, y, size=3, wall=2, pic=LIT if y in (18, 34) else None)
    m.floor(14, 8, 16, 33, 8); m.zone(14, 8, 16, 33, 2, 0)
    m.floor(31, 8, 33, 33, 8); m.zone(31, 8, 33, 33, 2, 0)
    m.stairs(14, 34, 16, 37, "N", 0, 8)
    m.lift(32, 34, 32, 34, 0, 8, mode=2, speed=6)
    for y in (9, 21, 33, 43):
        m.light(23.5, y + 0.5, 6, 140, 60, 170, 255, 2)
    for (x, y) in ((15, 14), (15, 28), (32, 14), (32, 28)):
        m.light(x + 0.5, y + 0.5, 5, 130, 255, 210, 140, 0)
    m.mon(15, 12, "g", hear=10); m.mon(15, 26, "g", hear=10); m.mon(32, 16, "g", hear=10); m.mon(32, 29, "g", hear=10)
    for (x, y, c) in ((24, 20, "m"), (24, 37, "m"), (19, 25, "c"), (29, 12, "c"), (28, 41, "w"), (18, 8, "k"),
                      (15, 9, "q"), (32, 9, "j"), (33, 12, "r"), (18, 42, "+"), (30, 7, "a"), (19, 31, "e"), (29, 36, "x"), (30, 36, "x")):
        m.put(x, y, c)
    # The pump room (west): generators in alcoves, slime drains, a survive lockdown
    m.room(3, 12, 12, 28, floor=8, ceil=20, zone=(2, 1))   # (a wall up: off the west ledge)
    m.put(13, 20, "D"); m.floor(13, 20, 13, 20, 8, only_open=False)
    m.alcove(2, 15, "E", deco="L", floor=8, ceil=15, glow=AMBER, fx=4)
    m.alcove(2, 25, "E", deco="L", floor=8, ceil=15, glow=AMBER, fx=4)
    m.put(2, 20, "$")
    m.pool(5, 14, 6, 15, "s", sink=2, depth=1)
    m.pool(9, 24, 10, 25, "s", sink=2, depth=1)
    for (x, y, c) in ((12, 13, "U"), (12, 27, "U"), (8, 13, "u"), (4, 27, "a"), (11, 18, "f")):
        m.put(x, y, c)
    m.light(7.5, 20.5, 6, 140, 255, 160, 80, 1)
    m.event(2, 3, 12, 12, 28, 30, 100, 8)
    # The reservoir (east, red door, a laser in the duct): deep water,
    # stairs out at its north end, lifts out to the island
    m.put(34, 22, "R"); m.rect(35, 22, 37, 22)   # (a wall up: off the east ledge)
    m.floor(34, 22, 37, 22, 8, only_open=False); m.ceiling(35, 22, 37, 22, 16, only_raise=False)
    m.event(9, 36, 22, 36, 22, 60, 90)
    m.room(38, 8, 45, 36, floor=8, ceil=24, zone=(3, 1))
    m.pool(39, 11, 45, 11, "w", sink=2, depth=1)
    m.pool(39, 12, 45, 12, "w", sink=4, depth=3)
    m.pool(39, 13, 45, 36, "w", sink=6, depth=5)
    for (x, y) in ((43, 23), (44, 23), (43, 24), (44, 24), (43, 25), (44, 25)):
        m.fh[y][x] = hstr(8); m.lq[y][x] = "."; m.ld[y][x] = "."
    for i, x in enumerate(range(39, 43)):
        m.lq[24][x] = "."; m.ld[24][x] = "."
        m.lift(x, 24, x, 24, 2, 8, mode=1, speed=(4, 6, 5, 3)[i])
    m.put(44, 24, "b"); m.column(45, 23, size=2, wall=2, pic=LIT, glow=CYAN)
    m.mon(41, 18, "m"); m.mon(42, 31, "m"); m.mon(38, 30, "k", wake="near"); m.mon(42, 9, "g", sight=12)
    m.put(38, 35, "*"); m.put(45, 9, "e")
    for y in (16, 24, 32):
        m.light(41.5, y + 0.5, 6, 150, 50, 150, 255, 2)
    m.light(43.5, 24.5, 4, 180, 80, 220, 255, 0)
    # The outflow (north, blue door): under the storm, the exit
    m.room(18, 2, 29, 4, ceil=24, zone=(4, 2))
    m.put(24, 5, "B"); m.put(24, 1, "E")
    m.pool(19, 3, 22, 4, "w", sink=2, depth=2); m.pool(26, 3, 28, 4, "w", sink=2, depth=2)
    m.post(23, 2, "N", at=7, w=2, d=2, wall=2, glow=GREEN); m.post(25, 2, "N", at=1, w=2, d=2, wall=2, glow=GREEN)
    m.mon(20, 2, "h", wake="near")
    m.loot_line("barrel   = ammo:15, shells:15, -, -")
    m.loot_line("locker   = armor:40, medkit:30, shells:30, overcharge:10")
    finish(m, 2, dict(closets=1, cmons="c", props=4, propchars="xop"))
    return m

if __name__ == "__main__":
    args = sys.argv[1:]
    if "--check" in args:
        good = True
        n = 1
        while os.path.exists(os.path.join(OUT, "level%d.txt" % n)):
            lv = read_level_file(os.path.join(OUT, "level%d.txt" % n), "new%d" % n)
            good = check_level(lv, ASSETS) and good
            errs, _ = reach_with_blocks(lv)
            for e in errs: print("  BLOCKED:", e)
            good = good and not errs
            n += 1
        sys.exit(0 if good else 1)
    sys.exit(0 if build_all("--write" in args, "-show" in args) else 1)
