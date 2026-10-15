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


def stall(m, x, y, deco, glow, pic="wall-adverts.png", wall=2):
    """A market stall 3 cells wide and 2 deep, open to the south: a back
    wall (its sign lit), side walls in the front row, `deco` at the back."""
    m.ceiling(x, y, x + 2, y + 1, 12, only_raise=False)   # (its awning: a roof, not the sky)
    m.zone(x, y, x + 2, y + 1, 0, 1)
    m.thin_wall(x, y, x + 2, y, "N", t=2, wall=wall)
    m.blk(x + 1, y, 0, 0, 8, 2, wall=wall, pics={"S": pic}, glow=glow, bright=170, rad=2.5)
    m.blk(x, y + 1, 0, 0, 1, 8, wall=wall)
    m.blk(x + 2, y + 1, 7, 0, 8, 8, wall=wall)
    if deco:
        m.put(x + 1, y + 1, deco)
        m.nudge(x + 1, y + 1, 0, -3)


# ---------------------------------------------------------------- 3
@sector("SECTOR 3: NEON MARKET",
        ["wall-adverts.png", "wall-graffiti.png", "wall-brick.png", "wall-concrete.png", "wall-transit.png", "wall-grate.png"],
        ["floor-cobbles.png", "floor-concrete.png", "floor-plates.png", "floor-platform.png"],
        ["ceiling-pipes.png", "sky-neon-night.png"])
def market():
    """NEW 3: NEON MARKET. Out of the subway (south) into the night market:
    an open square under the city sky, stalls of thin walls in rows, each
    sign lit its own colour, vending machines glowing in the shopfronts,
    rain puddles, a stage with a hologram in the middle. Thieves work the
    crowd - kill them and their hoard opens. The arcade (north) is a
    shooting gallery: smash it all in time for an overcharge; the red card
    is in there. The noodle bar (west, red door) locks down round the blue
    card. The pawn shop (east, blue door) has the exit."""
    m = Sector("#")
    m.ambient = (150, 200, 190, 255)
    m.puzzles = "countdown"
    # The subway stairs: you, facing north
    m.room(20, 42, 27, 45, ceil=10, zone=(4, 1))
    m.put(23, 45, "^")
    m.stairs(22, 40, 25, 41, "N", 0, 0)
    m.rect(22, 40, 25, 41)
    m.put(21, 43, "M"); m.put(26, 43, "a")
    # The square: under the sky
    m.room(8, 8, 39, 39, ceil=24, zone=(1, 2))
    for (sx, sy) in ((10, 11), (17, 11), (28, 11), (35, 11), (10, 30), (17, 30), (28, 30), (35, 30), (10, 18), (35, 18)):
        stall(m, sx - 1, sy, None, None)
    colours = (PINK, CYAN, AMBER, VIOLET)
    decos = ("n", "x", "p", "t", "Q", "x", "n", "o", "p", "t")
    i = 0
    for (sx, sy) in ((10, 11), (17, 11), (28, 11), (35, 11), (10, 30), (17, 30), (28, 30), (35, 30), (10, 18), (35, 18)):
        x, y = sx - 1, sy
        m.blocks = [b for b in m.blocks if (b[0], b[1]) != (x + 1, y)]
        m.blk(x + 1, y, 0, 0, 8, 2, wall=2, pics={"S": "wall-adverts.png"}, glow=colours[i % 4], bright=170, rad=2.5)
        m.put(x + 1, y + 1, decos[i]); m.nudge(x + 1, y + 1, 0, -2)
        i += 1
    # the stage: raised, a hologram, four lit posts
    m.floor(21, 21, 26, 26, 2)
    m.put(23, 23, "Q"); m.put(24, 24, "Q")
    for (x, y, a) in ((21, 21, "N"), (26, 21, "N"), (21, 26, "S"), (26, 26, "S")):
        m.post(x, y, a, at=4, w=2, d=2, wall=5, glow=PINK if y == 21 else CYAN)
    # puddles
    for (x0, y0, x1, y1) in ((13, 24, 15, 25), (31, 23, 33, 25), (19, 35, 21, 36), (26, 15, 27, 16)):
        m.pool(x0, y0, x1, y1, "w", sink=1, depth=1)
    # street lamps
    for (x, y) in ((8, 8), (39, 8), (8, 39), (39, 39), (15, 24), (32, 24)):
        m.put(x, y, "i")
    # vending machines and screens in the shopfronts (alcoves in the walls round the square)
    for (x, y, o, d, g) in ((7, 14, "E", "n", PINK), (7, 34, "E", "n", PINK), (40, 34, "W", "n", CYAN), (40, 14, "W", "F", CYAN),
                            (13, 40, "N", "n", AMBER), (34, 40, "N", "F", AMBER)):
        m.alcove(x, y, o, depth=3, floor=0, ceil=8, deco=d, glow=g, fx=0)
    for (x, y, c) in ((12, 22, "m"), (30, 15, "m"), (18, 27, "m"), (33, 33, "m"), (24, 33, "m"), (20, 14, "k"),
                      (36, 26, "w"), (11, 36, "g"), (37, 10, "g"), (16, 9, "e"), (31, 38, "+"), (9, 26, "u"), (38, 20, "a")):
        m.put(x, y, c)
    # The arcade (north): a shooting gallery - and the red card
    m.room(13, 2, 34, 6, ceil=12, zone=(3, 1))
    m.put(23, 7, "D")
    for x in (15, 18, 21, 26, 29, 32):
        m.put(x, 3, "x" if x % 2 else "o")
    m.put(14, 6, "F"); m.put(33, 6, "F"); m.put(23, 2, "r"); m.put(24, 2, "j")
    for x in (16, 20, 27, 31):
        m.column(x, 5, size=2, wall=5, pic=LIT)
    m.light(23.5, 4.5, 8, 160, 255, 90, 220, 3)
    m.event(4, 13, 2, 34, 6, 25, 0, 13)
    # The noodle bar (west, red door): benches, a lockdown round the blue card
    m.room(2, 16, 6, 30, ceil=10, zone=(2, 1))
    m.put(7, 23, "R")
    for y in (18, 21, 25, 28):
        m.put(3, y, "W"); m.put(5, y, "Z")
    m.thin_wall(4, 17, 4, 29, "W", t=1, wall=4)
    m.put(2, 30, "b"); m.put(6, 16, "*")
    m.light(4.5, 20.5, 5, 160, 255, 160, 60, 1); m.light(4.5, 27.5, 5, 160, 255, 160, 60, 0)
    m.event(1, 2, 16, 6, 30, 5, 4, 10)
    # The pawn shop (east, blue door): the exit
    m.room(41, 16, 45, 30, ceil=10, zone=(3, 1))
    m.put(40, 23, "B"); m.put(46, 23, "E")
    m.post(45, 22, "E", at=7, w=2, d=2, wall=5, glow=GREEN); m.post(45, 24, "E", at=1, w=2, d=2, wall=5, glow=GREEN)
    for (x, y, c) in ((42, 17, "U"), (44, 17, "U"), (42, 29, "x"), (44, 29, "x"), (43, 20, "h"), (41, 26, "e")):
        m.put(x, y, c)
    m.loot_line("crate    = ammo:25, shells:25, medkit:15, armor:15")
    m.loot_line("vending  = ammo:40, shells:30, medkit:15, overcharge:5")
    m.loot_line("locker   = amp:15, armor:40, medkit:30, -")
    finish(m, 3, dict(hoard=2, closets=1, cmons="ck"))
    return m


# ---------------------------------------------------------------- 4
@sector("SECTOR 4: ACID WORKS",
        ["wall-hazard.png", "wall-pipes.png", "wall-rusty.png", "wall-greenpipes.png", "wall-control.png", "wall-stripes.png"],
        ["floor-hazard.png", "floor-rustgrate.png", "floor-plates.png", "floor-scorched.png"],
        ["ceiling-vents.png", "ceiling-pipes.png"])
def acidworks():
    """NEW 4: ACID WORKS. A chemical plant. The vat hall is cut in two by a
    channel of deep acid - two catwalks cross it, stairs climb out of its
    south end, and the middle crossing is broken: lifts bob out to the
    island with the railgun. Four shallow vats glow round it (wade in and
    the acid eats your armour first). The filter room (west) has the red
    card and an electric floor; pump control (east, red door) locks down
    round the blue. The control room (north, blue door) has the exit."""
    m = Sector("#")
    m.ambient = (155, 200, 235, 190)
    m.puzzles = "password"
    # The loading bay: you, facing north
    m.room(3, 37, 12, 44, ceil=12, zone=(3, 1))
    m.put(7, 44, "^")
    m.put(13, 40, "D"); m.rect(14, 40, 14, 40)
    for (x, y, c) in ((4, 38, "x"), (5, 38, "x"), (11, 38, "o"), (10, 43, "M"), (4, 43, "a"), (11, 44, "m")):
        m.put(x, y, c)
    m.light(7.5, 40.5, 6, 140, 200, 255, 160, 0)
    # The vat hall
    m.room(15, 12, 40, 41, ceil=20, zone=(1, 1))
    m.pool(26, 12, 29, 12, "a", sink=2, depth=1)   # (steps out at both ends)
    m.pool(26, 13, 29, 13, "a", sink=4, depth=3)
    m.pool(26, 14, 29, 38, "a", sink=6, depth=5)
    m.pool(26, 39, 29, 39, "a", sink=4, depth=3)
    m.pool(26, 40, 29, 40, "a", sink=2, depth=1)
    for (x0, y0, x1, y1) in ((18, 16, 22, 21), (33, 16, 37, 21), (18, 30, 22, 35), (33, 30, 37, 35)):
        m.pool(x0, y0, x1, y1, "a", sink=2, depth=1)
        for (cx, cy) in ((x0 - 1, y0 - 1), (x1 + 1, y0 - 1), (x0 - 1, y1 + 1), (x1 + 1, y1 + 1)):
            m.column(cx, cy, size=2, wall=2, pic=LIT if cy < 25 else None, glow=None)
    for y in (18, 34):  # catwalks
        for x in range(26, 30):
            m.fh[y][x] = "."; m.lq[y][x] = "."; m.ld[y][x] = "."
        m.zone(26, y, 29, y, 2, 0)
    for x in (27, 28):  # the island
        m.fh[26][x] = "."; m.lq[26][x] = "."; m.ld[26][x] = "."
    m.zone(27, 26, 28, 26, 2, 0)
    for i, x in enumerate((26, 29)):
        m.lq[26][x] = "."; m.ld[26][x] = "."
        m.lift(x, 26, x, 26, -6, 0, mode=1, speed=(4, 5)[i])
    m.put(27, 26, "4"); m.put(28, 26, "u")
    m.alcove(14, 20, "E", deco="f", floor=0, ceil=7, glow=GREEN, fx=2)
    m.alcove(14, 32, "E", deco="f", floor=0, ceil=7, glow=GREEN, fx=2)
    m.alcove(41, 32, "W", deco="A", floor=2, ceil=7, glow=CYAN, fx=0)
    for y in (16, 24, 32, 39):
        m.light(27.5, y + 0.5, 6, 130, 140, 255, 90, 2)
    for (x, y) in ((20, 25), (35, 25), (20, 39), (35, 13)):
        m.light(x + 0.5, y + 0.5, 6, 140, 230, 255, 200, 0)
    for (x, y, c) in ((20, 14, "w"), (35, 37, "w"), (24, 28, "c"), (31, 22, "c"), (31, 37, "c"), (17, 26, "m"), (38, 26, "m"),
                      (24, 40, "g"), (38, 13, "g"), (16, 13, "+"), (39, 40, "e"), (24, 14, "a"), (16, 40, "x"), (17, 40, "x")):
        m.put(x, y, c)
    # The filter room (west): the red card, an electric floor
    m.room(3, 14, 11, 30, ceil=12, zone=(2, 1))
    m.put(12, 22, "D"); m.rect(13, 22, 14, 22)
    for y in (16, 20, 24, 28):
        m.put(4, y, "I"); m.nudge(4, y, -2, 0)
    m.put(2, 22, "$")
    for (x, y, c) in ((10, 15, "J"), (10, 29, "J"), (7, 15, "r"), (9, 26, "k"), (6, 29, "e"), (10, 22, "u")):
        m.put(x, y, c)
    m.event(3, 6, 18, 9, 26, 60, 100)
    m.light(7.5, 22.5, 7, 150, 120, 255, 180, 0)
    # Pump control (east, red door): a lockdown round the blue card
    m.room(43, 14, 46, 30, ceil=12, zone=(3, 2))
    m.put(41, 22, "R"); m.rect(42, 22, 42, 22)
    for (x, y, c) in ((46, 15, "A"), (46, 29, "A"), (43, 15, "F"), (46, 22, "b"), (44, 18, "+")):
        m.put(x, y, c)
    m.event(1, 43, 14, 46, 30, 4, 2, 9)
    m.light(44.5, 22.5, 6, 160, 90, 200, 255, 1)
    # The control room (north, blue door): the exit
    m.room(18, 3, 37, 9, ceil=12, zone=(4, 2))
    m.put(22, 11, "B"); m.rect(22, 10, 22, 10)
    m.put(27, 2, "E")
    m.post(26, 3, "N", at=7, w=2, d=2, wall=5, glow=GREEN); m.post(28, 3, "N", at=1, w=2, d=2, wall=5, glow=GREEN)
    for x in (20, 23, 31, 34):
        m.put(x, 3, "F")
    for (x, y, c) in ((19, 8, "A"), (36, 8, "A"), (22, 6, "h"), (33, 6, "s"), (27, 8, "*"), (21, 4, "e")):
        m.put(x, y, c)
    m.light(27.5, 6.5, 8, 150, 200, 255, 220, 0)
    m.loot_line("crate    = ammo:25, shells:20, medkit:25, armor:20")
    m.loot_line("barrel   = ammo:10, shells:10, armor:10, -")
    finish(m, 4, dict(closets=1, cmons="cw", plates=2, station=1, props=3, propchars="xo"))
    return m


def river(m, x0, x1, y0, y1, kind, deep=6):
    """A river of `kind` across x0..x1 (rows y0..y1), `deep` eighths down,
    with steps up out of it at both ends."""
    for x in range(x0, x1 + 1):
        d = min(deep, 2 + 2 * min(x - x0, x1 - x))
        m.pool(x, y0, x, y1, kind, sink=d, depth=max(1, d - 1))


# ---------------------------------------------------------------- 5
@sector("SECTOR 5: THE FORGE",
        ["wall-furnace.png", "wall-girders.png", "wall-rusty.png", "wall-hazard.png", "wall-pipes.png", "wall-stripes.png"],
        ["floor-scorched.png", "floor-plates.png", "floor-hazard.png", "floor-rustgrate.png"],
        ["ceiling-girders.png", "ceiling-vents.png"])
def forge():
    """NEW 5: THE FORGE. The slag yard (south) opens onto the forge hall:
    two rivers of lava across it, steps out of each at its ends, girder
    columns, generators roaring in alcoves. Cross the south river on the
    bridge; the north one on the lifts (or the far bridge). The casting
    room (west) has the red card and a floor that bursts into flame; the
    pattern store (east, red door) locks down with heavies round the blue
    card. The furnace (north, blue door) has the exit. And the power fails."""
    m = Sector("#")
    m.ambient = (150, 255, 200, 170)
    m.puzzles = "wrap"
    # The slag yard: you, facing north
    m.room(18, 39, 29, 44, ceil=12, zone=(3, 1))
    m.put(23, 44, "^")
    m.put(23, 38, "H"); m.rect(23, 37, 23, 37)
    for (x, y, c) in ((19, 40, "x"), (28, 40, "o"), (20, 43, "M"), (27, 43, "a"), (25, 41, "c")):
        m.put(x, y, c)
    m.light(23.5, 41.5, 6, 150, 255, 170, 90, 4)
    # The forge hall
    m.room(9, 16, 38, 36, ceil=24, zone=(1, 1))
    river(m, 9, 38, 30, 31, "l")
    river(m, 9, 38, 22, 23, "l")
    for x in (14, 15):  # the south bridge
        for y in (30, 31):
            m.fh[y][x] = "."; m.lq[y][x] = "."; m.ld[y][x] = "."
        m.zone(x, 30, x, 31, 4, 0)
    for x in (34, 35):  # the far bridge north
        for y in (22, 23):
            m.fh[y][x] = "."; m.lq[y][x] = "."; m.ld[y][x] = "."
        m.zone(x, 22, x, 23, 4, 0)
    for y in (22, 23):
        for x in (23, 24):
            m.lq[y][x] = "."; m.ld[y][x] = "."
    m.lift(23, 22, 24, 23, -6, 0, mode=1, speed=4)
    for x in (14, 19, 28, 33):
        m.column(x, 26, size=3, wall=2)
    for (x, y, o) in ((12, 15, "S"), (34, 15, "S"), (12, 37, "N"), (34, 37, "N")):
        m.alcove(x, y, o, depth=4, floor=0, ceil=7, deco="L", glow=AMBER, fx=4)
    for (x, y) in ((16, 19), (31, 19), (16, 34), (31, 34), (23, 26)):
        m.light(x + 0.5, y + 0.5, 7, 140, 255, 150, 80, 0)
    for (x, y, c) in ((18, 26, "h"), (30, 18, "h"), (11, 18, "g"), (36, 34, "g"), (26, 26, "g"), (20, 30, "m"), (31, 22, "m"),
                      (10, 34, "w"), (37, 27, "c"), (12, 26, "c"), (16, 18, "e"), (31, 35, "e"), (10, 25, "+"), (36, 18, "a"), (24, 33, "j")):
        m.put(x, y, c)
    # The casting room (west): the red card, a fire floor
    m.room(2, 18, 6, 34, ceil=12, zone=(2, 2))
    m.put(8, 26, "D"); m.rect(7, 26, 7, 26)
    m.put(1, 26, "$")
    for (x, y, c) in ((2, 19, "L"), (6, 19, "x"), (2, 33, "L"), (6, 33, "x"), (4, 19, "r"), (5, 30, "u"), (3, 29, "e")):
        m.put(x, y, c)
    m.event(12, 3, 22, 5, 30, 50, 110)
    m.light(4.5, 26.5, 6, 150, 255, 140, 60, 4)
    # The pattern store (east, red door): heavies lock you in with the blue card
    m.room(41, 18, 45, 34, ceil=12, zone=(4, 2))
    m.put(39, 26, "R"); m.rect(40, 26, 40, 26)
    for y in (21, 25, 29):
        m.thin_wall(43, y, 45, y, "S", t=2, wall=5)
    for (x, y, c) in ((45, 19, "b"), (44, 33, "*"), (42, 20, "x"), (42, 32, "x"), (45, 27, "U")):
        m.put(x, y, c)
    m.event(1, 41, 18, 45, 34, 2, 3, 10)
    m.light(43.5, 26.5, 6, 150, 255, 120, 60, 1)
    # The furnace (north, blue door): the exit
    m.room(14, 3, 33, 12, ceil=16, zone=(2, 2))
    m.put(23, 15, "B"); m.rect(23, 13, 23, 14)
    m.pool(19, 6, 22, 8, "l", sink=2, depth=1); m.pool(25, 6, 28, 8, "l", sink=2, depth=1)
    m.put(23, 2, "E")
    m.post(22, 3, "N", at=7, w=2, d=2, wall=4, glow=GREEN); m.post(24, 3, "N", at=1, w=2, d=2, wall=4, glow=GREEN)
    for (x, y, c) in ((15, 4, "L"), (32, 4, "L"), (16, 10, "s"), (30, 9, "h"), (17, 5, "a"), (31, 11, "+")):
        m.put(x, y, c)
    m.light(23.5, 9.5, 7, 150, 255, 160, 80, 4)
    m.loot_line("crate    = ammo:20, shells:30, medkit:20, armor:10")
    m.loot_line("generator = ammo:30, -, -, -")
    finish(m, 5, dict(closets=1, cmons="c", blackout=4, props=2, propchars="xo"))
    return m


# ---------------------------------------------------------------- 6
@sector("SECTOR 6: THE CHAPEL",
        ["wall-vault.png", "wall-obsidian.png", "wall-core.png", "wall-tiles.png", "wall-datastream.png", "wall-white.png"],
        ["floor-white.png", "floor-circuit.png", "floor-glow.png", "floor-lab.png"],
        ["ceiling-core.png", "ceiling-lights.png"])
def chapel():
    """NEW 6: THE CHAPEL. NEXUS built itself a cathedral. The nave is four
    walls high between two rows of slim lit pillars, low aisles outside
    them with holograms in their shrines, a font of poison in the middle.
    Up the steps, the apse: spawner portals - break them. The west crypt
    locks you in to survive (the red card is there); the east crypt (red
    door) has the blue. The sacristy, off the apse (blue door), has the exit."""
    m = Sector("#")
    m.ambient = (150, 215, 200, 255)
    m.puzzles = "select"
    # The narthex: you, facing north
    m.room(19, 40, 28, 44, ceil=12, zone=(4, 1))
    m.put(23, 43, "^")
    m.rect(23, 38, 24, 39)
    for (x, y, c) in ((19, 40, "i"), (28, 40, "i"), (20, 44, "M"), (27, 44, "a"), (19, 44, "W"), (28, 44, "W")):
        m.put(x, y, c)
    # The nave and its aisles
    m.room(13, 10, 34, 37, ceil=12, zone=(1, 1))
    m.ceiling(17, 10, 30, 37, 32, only_raise=False)
    m.room(18, 4, 29, 9, ceil=32)   # (the apse)
    for y in range(13, 37, 3):
        lit = (y // 3) % 2 == 0
        m.column(17, y, size=2, wall=2, pic=LIT if lit else None, glow=VIOLET if lit else None)
        m.column(30, y, size=2, wall=2, pic=LIT if lit else None, glow=VIOLET if lit else None)
    for y in (14, 20, 26, 32):
        m.alcove(12, y, "E", depth=4, floor=2, ceil=7, deco="Q", glow=PINK, fx=2)
        m.alcove(35, y, "W", depth=4, floor=2, ceil=7, deco="Q", glow=CYAN, fx=2)
    m.pool(22, 22, 25, 25, "p", sink=2, depth=1)
    for (x, y, a) in ((21, 21, "N"), (26, 21, "N"), (21, 26, "S"), (26, 26, "S")):
        m.post(x, y, a, at=4, w=2, d=2, wall=5, glow=GREEN, fx=2)
    for (x, y) in ((23, 15), (23, 31), (14, 23), (33, 23)):
        m.light(x + 0.5, y + 0.5, 8, 150, 190, 120, 255, 0)
    # the apse: up the steps, the spawner nest
    m.floor(18, 4, 29, 9, 4); m.floor(18, 10, 29, 10, 2)
    m.zone(18, 4, 29, 9, 3, 2)
    for x in (20, 27):
        m.put(x, 5, "S")
    m.event(5, 18, 4, 29, 9, 6, 240)
    m.light(23.5, 6.5, 8, 170, 255, 60, 200, 2)
    for (x, y, c) in ((15, 10, "k"), (32, 30, "k"), (20, 30, "k"), (27, 16, "w"), (15, 34, "w"), (24, 12, "m"), (19, 27, "m"),
                      (28, 19, "m"), (32, 12, "g"), (14, 18, "g"), (14, 36, "+"), (33, 36, "e"), (19, 8, "a"), (28, 8, "u")):
        m.put(x, y, c)
    # The west crypt: survive - and the red card
    m.room(3, 14, 10, 32, ceil=10, zone=(2, 2))
    m.put(12, 23, "D"); m.rect(11, 23, 11, 23)
    for y in (17, 22, 27):
        m.alcove(2, y, "E", depth=5, floor=0, ceil=7, deco="O", glow=CYAN, fx=5)
    m.put(2, 30, "$")
    for (x, y, c) in ((10, 15, "r"), (9, 31, "*"), (5, 15, "V"), (7, 31, "V")):
        m.put(x, y, c)
    m.event(2, 3, 14, 10, 32, 30, 80, 10)
    m.light(6.5, 23.5, 6, 150, 120, 200, 255, 5)
    # The east crypt (red door): the blue card
    m.room(37, 14, 44, 32, ceil=10, zone=(2, 2))
    m.put(35, 23, "R"); m.rect(36, 23, 36, 23)
    for y in (17, 22, 27):
        m.alcove(45, y, "W", depth=5, floor=0, ceil=7, deco="O", glow=PINK, fx=5)
    for (x, y, c) in ((44, 31, "b"), (38, 15, "V"), (41, 30, "w"), (42, 16, "k"), (38, 31, "e")):
        m.put(x, y, c)
    m.light(40.5, 23.5, 6, 150, 255, 120, 200, 5)
    # The sacristy (off the apse, blue door): the exit
    m.room(32, 2, 40, 9, floor=4, ceil=14, zone=(3, 2))
    m.put(30, 6, "B"); m.rect(31, 6, 31, 6); m.floor(30, 6, 31, 6, 4, only_open=False)
    m.put(41, 6, "E")
    m.post(40, 5, "E", at=7, w=2, d=2, wall=5, glow=GREEN); m.post(40, 7, "E", at=1, w=2, d=2, wall=5, glow=GREEN)
    for (x, y, c) in ((33, 3, "F"), (39, 3, "F"), (36, 8, "h"), (34, 8, "j")):
        m.put(x, y, c)
    m.light(36.5, 5.5, 6, 150, 255, 220, 160, 0)
    m.loot_line("crate    = ammo:20, shells:20, medkit:20, armor:15")
    m.loot_line("hologram = overcharge:20, amp:10, -, -")
    finish(m, 6, dict(closets=2, cmons="kc", props=2, propchars="xp"))
    return m


# ---------------------------------------------------------------- 7
@sector("SECTOR 7: COLD STORAGE",
        ["wall-white.png", "wall-frost.png", "wall-cryo.png", "wall-tiles.png", "wall-ice.png", "wall-terminals.png"],
        ["floor-white.png", "floor-frostgrate.png", "floor-ice.png", "floor-lab.png"],
        ["ceiling-frost.png", "ceiling-lights.png"])
def coldstorage():
    """NEW 7: COLD STORAGE. Receiving (south-west) leads into the ice hall -
    and in its corner the freezer shaft, which has no bottom. North, a
    corridor runs past three cryo vaults behind glass: the first has the
    red card and locks you in; the middle one is sealed (look, don't
    touch); the last (red door) has the blue. The specimen lab (west) keeps
    its tanks in alcoves; the offices (east) are cubicles of thin walls.
    The loading dock (north-west, blue door) has the exit."""
    m = Sector("#")
    m.ambient = (165, 190, 225, 255)
    m.puzzles = "pythagoras"
    # Receiving: you, facing north
    m.room(4, 38, 11, 44, ceil=10, zone=(4, 1))
    m.put(7, 43, "^")
    m.put(13, 39, "D"); m.rect(12, 39, 12, 39)
    for (x, y, c) in ((4, 39, "x"), (5, 39, "x"), (11, 44, "x"), (9, 41, "M"), (5, 44, "a"), (10, 43, "c")):
        m.put(x, y, c)
    # The ice hall, and the freezer shaft in its corner
    m.room(14, 20, 33, 40, ceil=14, zone=(3, 1))
    m.rect(23, 19, 24, 19)
    m.pit(15, 35, 18, 39, 9)
    m.event(13, 15, 35, 18, 39, 0, 0)
    for (x, y) in ((14, 34), (19, 34), (19, 40)):
        m.post(x, y, "S" if y == 34 else "W", at=4, w=2, d=2, wall=3, glow=CYAN, fx=1)
    for x in (21, 26):
        for y in (24, 30, 36):
            m.column(x, y, size=2, wall=5, pic=LIT if y == 30 else None, glow=CYAN if y == 30 else None)
    for (x, y) in ((23, 22), (23, 33), (30, 27), (16, 27)):
        m.light(x + 0.5, y + 0.5, 7, 150, 150, 210, 255, 0)
    for (x, y, c) in ((30, 22, "c"), (28, 38, "c"), (17, 23, "k"), (31, 33, "g"), (24, 27, "m"), (32, 39, "+"), (15, 21, "e"), (32, 21, "u")):
        m.put(x, y, c)
    # The vault corridor, and the vaults behind glass
    m.room(14, 16, 33, 18, ceil=10, zone=(2, 2))
    m.room(14, 6, 19, 14, ceil=12, zone=(4, 2))
    m.room(21, 6, 26, 14, ceil=12, zone=(4, 2))
    m.room(28, 6, 33, 14, ceil=12, zone=(4, 2))
    for x in (16, 17, 18, 22, 23, 24, 25, 29, 30, 31):
        m.put(x, 15, "=")
    m.put(14, 15, "D"); m.put(33, 15, "R")
    for (x0, x1) in ((14, 19), (21, 26), (28, 33)):
        for x in range(x0 + 1, x1, 2):
            m.put(x, 7, "O")
        m.light((x0 + x1) / 2 + 0.5, 10.5, 5, 140, 120, 220, 255, 5)
    for (x, y, c) in ((15, 13, "r"), (18, 10, "V"), (23, 11, "V"), (22, 12, "k"), (25, 9, "g"), (32, 13, "b"), (29, 11, "V"), (31, 9, "*")):
        m.put(x, y, c)
    m.event(1, 14, 6, 19, 14, 4, 4, 9)
    # The specimen lab (west): tanks in alcoves, benches
    m.room(2, 20, 11, 36, ceil=12, zone=(4, 1))
    m.put(12, 30, "D"); m.rect(13, 30, 13, 30)
    for y in (22, 26, 30, 34):
        m.alcove(1, y, "E", depth=4, floor=0, ceil=7, deco="I", glow=GREEN, fx=2)
    for y in (23, 29, 35):
        m.put(6, y, "J"); m.put(7, y, "J")
    for (x, y, c) in ((10, 21, "w"), (4, 33, "w"), (10, 35, "e"), (3, 21, "q")):
        m.put(x, y, c)
    m.light(6.5, 27.5, 7, 150, 150, 255, 200, 0)
    # The offices (east): cubicles
    m.room(36, 20, 45, 40, ceil=10, zone=(2, 1))
    m.put(34, 32, "D"); m.rect(35, 32, 35, 32)
    for y in (23, 27, 31, 35, 39):
        for (x0, x1) in ((38, 40), (42, 44)):
            m.thin_wall(x0, y, x1, y, "N", t=1, wall=6)
        m.blk(41, y, 0, 0, 1, 8, wall=6)
    for (y, xs) in ((24, (38, 43)), (28, (39, 44)), (32, (38, 42)), (36, (40, 44))):
        for x in xs:
            m.put(x, y, "d"); m.put(x, y + 1, "Z")
    m.put(46, 30, "$")
    for (x, y, c) in ((37, 22, "k"), (44, 34, "k"), (43, 21, "t"), (37, 38, "e"), (45, 40, "+")):
        m.put(x, y, c)
    m.nudge(43, 21, 0, -2)
    m.light(40.5, 26.5, 6, 140, 255, 255, 255, 1); m.light(40.5, 36.5, 6, 140, 255, 255, 255, 0)
    # The loading dock (north-west, blue door): the exit
    m.room(3, 4, 10, 16, ceil=12, zone=(1, 2))
    m.put(13, 16, "B"); m.rect(11, 16, 12, 16)
    m.put(2, 9, "E")
    m.post(3, 8, "W", at=7, w=2, d=2, wall=3, glow=GREEN); m.post(3, 10, "W", at=1, w=2, d=2, wall=3, glow=GREEN)
    for (x, y, c) in ((9, 5, "x"), (10, 5, "x"), (9, 15, "o"), (6, 6, "h"), (8, 12, "a")):
        m.put(x, y, c)
    m.light(6.5, 9.5, 6, 140, 200, 230, 255, 0)
    m.loot_line("desk     = ammo:15, shells:10, medkit:15, -")
    m.loot_line("cryopod  = overcharge:15, medkit:30, -, -")
    finish(m, 7, dict(closets=1, cmons="c", props=2, propchars="xp"))
    return m


# ---------------------------------------------------------------- 8
@sector("SECTOR 8: THE SKYWAY",
        ["wall-concrete.png", "wall-adverts.png", "wall-transit.png", "wall-grate.png", "wall-hull.png", "wall-graffiti.png"],
        ["floor-platform.png", "floor-rustgrate.png", "floor-concrete.png", "floor-deck.png"],
        ["ceiling-hull.png", "sky-storm.png"])
def skyway():
    """NEW 8: THE SKYWAY. Over the city in a storm: rooftops at different
    heights, bridges and stairs between them, and the street far below -
    step off and you fall to your death. A lift rides between two roofs;
    a laser cutter sweeps the long gantry north. Sentries hold the roofs.
    The red card is on the east roof; the blue in the shed on the north-west
    tower (red door); the exit in the shed on the highest roof (blue door)."""
    m = Sector("#")
    m.ambient = (160, 190, 210, 255)
    m.puzzles = "function"
    m.room(1, 1, 46, 46, ceil=34, zone=(3, 2))   # (the street, under the sky - as high as a height goes, nearly)
    m.event(13, 1, 1, 46, 46, 0, 0)
    roofs = ((3, 34, 14, 44, 16), (3, 20, 11, 30, 16), (17, 18, 30, 30, 12), (3, 3, 14, 14, 20),
             (33, 3, 44, 12, 24), (34, 18, 44, 30, 16), (20, 36, 44, 44, 16))
    for (x0, y0, x1, y1, h) in roofs:
        m.floor(x0, y0, x1, y1, h, only_open=False)
        m.zone(x0, y0, x1, y1, 1, 0)
    def bridge(x0, y0, x1, y1, h):
        m.floor(x0, y0, x1, y1, h, only_open=False); m.zone(x0, y0, x1, y1, 2, 0)
    bridge(6, 31, 7, 33, 16)                 # start roof - west tower
    bridge(15, 39, 19, 40, 16)               # start roof - south-east roof
    bridge(38, 31, 39, 35, 16)               # south-east roof - east roof
    m.stairs(12, 24, 16, 24, "E", 16, 12)    # west tower - plaza
    m.zone(12, 24, 16, 24, 2, 0)
    m.stairs(6, 15, 7, 19, "N", 16, 20)      # west tower - north-west tower
    m.zone(6, 15, 7, 19, 2, 0)
    bridge(15, 8, 30, 8, 20)                 # the gantry...
    m.stairs(31, 8, 32, 8, "E", 22, 24)      # ...up to the high roof
    m.zone(31, 8, 32, 8, 2, 0)
    m.event(10, 15, 8, 30, 8, 100, 0)        # (the cutter sweeping it)
    m.lift(31, 23, 33, 24, 12, 16, mode=1, speed=4)   # plaza - east roof
    m.start_at = (8, 43)
    m.put(8, 43, "^")
    # the street's dark below; lamps and lit posts on the roofs
    for (x, y) in ((4, 35), (13, 43), (10, 21), (18, 19), (29, 29), (35, 19), (43, 29), (21, 43), (43, 37), (34, 4)):
        m.put(x, y, "i")
    for (x, y, a, c) in ((17, 24, "W", PINK), (30, 24, "E", CYAN), (23, 18, "N", AMBER), (23, 30, "S", AMBER)):
        m.post(x, y, a, at=4, w=2, d=2, wall=2, glow=c, fx=0)
    m.pool(24, 25, 26, 26, "w", sink=1, depth=1); m.pool(37, 40, 39, 41, "w", sink=1, depth=1)
    for (x, y, c) in ((8, 37, "M"), (12, 41, "a"), (10, 28, "e"), (25, 20, "s"), (40, 27, "s"), (21, 27, "g"), (28, 22, "g"),
                      (6, 26, "k"), (36, 40, "k"), (25, 27, "m"), (12, 12, "m"), (40, 11, "m"), (30, 42, "+"), (42, 20, "r"),
                      (19, 21, "u"), (28, 28, "a"), (5, 22, "e"), (43, 39, "*"), (37, 21, "f"), (5, 42, "x"), (6, 42, "x")):
        m.put(x, y, c)
    m.light(23.5, 24.5, 9, 140, 200, 220, 255, 0)
    # the north-west tower's shed (red door): the blue card
    m.room(4, 4, 9, 8, floor=20, ceil=30, zone=(4, 1))
    m.rect(4, 9, 9, 9, "C"); m.rect(10, 4, 10, 9, "C")
    m.put(7, 9, "R")
    for (x, y, c) in ((4, 4, "b"), (9, 4, "U"), (5, 7, "j")):
        m.put(x, y, c)
    m.light(6.5, 6.5, 4, 150, 255, 200, 120, 1)
    # the high roof's shed (blue door): the exit
    m.room(36, 4, 43, 8, floor=24, ceil=33, zone=(4, 1))
    m.rect(35, 4, 35, 9, "C"); m.rect(36, 9, 43, 9, "C")
    m.put(35, 6, "B"); m.put(44, 6, "E")
    m.post(43, 5, "E", at=7, w=2, d=2, wall=5, glow=GREEN); m.post(43, 7, "E", at=1, w=2, d=2, wall=5, glow=GREEN)
    m.put(39, 9, "$")
    for (x, y, c) in ((38, 5, "h"), (37, 8, "e"), (42, 4, "F")):
        m.put(x, y, c)
    m.light(39.5, 6.5, 5, 150, 200, 255, 220, 0)
    m.triggers.append("enter 3 34 14 44 : message THE STREET IS A LONG WAY DOWN - DON'T STEP OFF")
    m.loot_line("crate    = ammo:25, shells:25, medkit:20, armor:15")
    m.loot_line("tank     = ammo:20, -, -, -")
    finish(m, 8, dict(props=2, propchars="xo"))
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
