"""OLD SECTORS NEW: the first ten sectors, remade with everything the game
has grown since - built from the originals (level1.txt .. level10.txt,
which stay as they are) into remix/level1.txt .. remix/level10.txt, the
files GAME > OLD SECTORS NEW plays.

    python3 remaster.py            remake every sector and check it
    python3 remaster.py -show      ...and print the maps
    python3 remaster.py --write    remake, check, and (if all is well) write
                                   remix/level1.txt .. remix/level10.txt
    python3 remaster.py --check    just check the remix files as they are

Each sector keeps its layout, keys, doors, monsters and route, and gains:

  - alcoves cut into its walls - terminals, holograms, racks, generators,
    tanks glowing in them, as the sector's theme has it (an alcove only
    ever turns wall into a recess, so no way is ever blocked)
  - slim lit columns standing in its open floors (an eighth or two wide:
    there's always room to walk round them)
  - decorations moved back against the walls they stand by
  - its floor-picture hazards made real liquids: murky floors water,
    slime slime - and molten floors lava, where the sector can still be
    finished without wading through it (lava burns twice as hard)
  - a loot table to suit it
  - and touches of its own (remaster_N below): pools, light strips, posts
    flanking its exit, glass, lockdowns.
"""
import os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from lvlkit import N, validate, check_level, write_level_file, read_level_file
import newsectors as ns
import levels as original
from newsectors import Sector, hstr, LIT, CYAN, PINK, GREEN, AMBER, RED, VIOLET

ASSETS = os.path.dirname(HERE)
OUT = os.path.join(HERE, "remix")
STEPS = ((1, 0), (-1, 0), (0, 1), (0, -1))
SIDE_OF = {(1, 0): "W", (-1, 0): "E", (0, 1): "N", (0, -1): "S"}   # (front is +x of the wall: it opens east... see below)
OPEN_TO = {(1, 0): "E", (-1, 0): "W", (0, 1): "S", (0, -1): "N"}


def hval(c, dflt):
    return lvlkit.hval(c, dflt)  # (the kit's: heights past z too)


def load(n):
    """Original sector n as a Sector, everything in it."""
    lv = read_level_file(os.path.join(HERE, "level%d.txt" % n), "level%d" % n)
    m = Sector.from_rows(lv["rows"])
    m.ambient = tuple(lv["ambient"]) if lv["ambient"] else m.ambient
    m.zones = [tuple(z) for z in lv["zones"]]
    m.lights = [tuple(l) for l in lv["lights"]]
    m.events = [tuple(e) for e in lv["events"]]
    m.lifts = [tuple(l) for l in lv["lifts"]]
    m.triggers = list(lv["triggers"])
    for y in range(N):
        m.fh[y] = list((lv["floor"][y] if y < len(lv["floor"]) else "").ljust(N, ".")[:N])
        m.ch[y] = list((lv["ceiling"][y] if y < len(lv["ceiling"]) else "").ljust(N, ".")[:N])
        m.lq[y] = list((lv["liquid"][y] if y < len(lv.get("liquid", [])) else "").ljust(N, ".")[:N])
        m.ld[y] = list((lv["liquid_depth"][y] if y < len(lv.get("liquid_depth", [])) else "").ljust(N, ".")[:N])
    for f in lv["faces"]:
        p = [t.strip() for t in f.split(",")]
        m.faces[(int(p[0]), int(p[1]), p[2])] = (int(p[3]), p[4], p[5] if len(p) > 5 else "")
    m.pads = [tuple(p) for p in lv["pads"]]
    for t in lv["monsters"]:
        m.mons[(int(t[0]), int(t[1]))] = tuple(t[2:7])
    m.loot = list(lv["loot"])
    m.puzzles = lv.get("puzzles", "")
    m.blocks = [tuple(b) for b in lv.get("blocks", [])]
    m.nudges = [tuple(x) for x in lv.get("nudges", [])]
    return m, lv


def floor_pics(m, lv):
    """Each cell's floor picture, as the game works it out: zones in order
    (later ones win), then the cell's own ([faces] F)."""
    pic = [[lv["floors"][0] if lv["floors"] else "" for _ in range(N)] for _ in range(N)]
    for z in m.zones:
        x0, y0, x1, y1, f = z[0], z[1], z[2], z[3], z[4]
        shape = z[6] if len(z) > 6 else 0
        if not f: continue
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if shape:   # (a triangle: leave the edge cases to the square)
                    u, v = x - x0, y - y0
                    s = x1 - x0
                    if shape == 1 and u + v > s: continue
                    if shape == 2 and u < v: continue
                    if shape == 3 and u + v < s: continue
                    if shape == 4 and u > v: continue
                pic[y][x] = lv["floors"][f - 1]
    for (x, y, f), (d, p1, p2) in m.faces.items():
        if f == "F" and p1:
            pic[y][x] = p1
    return pic


def busy(m):
    """Cells the passes leave alone: doors and the cells by them, stations,
    terminals, pads, glass, lifts, event rooms that are traps, lasers and
    the like, trigger boxes - and anything already on the floor."""
    out = set()
    for y in range(N):
        for x in range(N):
            c = m.g[y][x]
            if c in lvlkit.DOORS or c in "@$&=%E!":
                for dy in range(-2, 3):
                    for dx in range(-2, 3):
                        out.add((x + dx, y + dy))
    for (x0, y0, x1, y1, *_r) in m.lifts:
        for y in range(y0 - 1, y1 + 2):
            for x in range(x0 - 1, x1 + 2):
                out.add((x, y))
    for e in m.events:
        if e[0] in (3, 6, 7, 8, 9, 10, 12, 13):
            for y in range(e[2] - 1, e[4] + 2):
                for x in range(e[1] - 1, e[3] + 2):
                    out.add((x, y))
    for t in m.triggers:
        w = t.split(":")[0].split()
        if w and w[0] in ("enter", "clear") and len(w) >= 5:
            try:
                x0, y0, x1, y1 = (int(v) for v in w[1:5])
                for y in range(y0, y1 + 1):
                    for x in range(x0, x1 + 1):
                        out.add((x, y))
            except ValueError:
                pass
        if w and w[0] == "use" and len(w) >= 3:
            try:
                out.add((int(w[1]), int(w[2])))
            except ValueError:
                pass
    for (x, y, *_r) in m.blocks:
        out.add((x, y))
    return out


def auto_alcoves(m, rng, n, decos, glows, fx=2):
    """Up to n alcoves in long straight walls: a wall cell with open floor in
    front, wall behind and wall either side along the wall."""
    taken = busy(m)
    cand = []
    for y in range(2, N - 2):
        for x in range(2, N - 2):
            if m.g[y][x] not in lvlkit.WALLS or (x, y) in taken:
                continue
            for (dx, dy) in STEPS:
                fx_, fy_ = x + dx, y + dy
                bx, by = x - dx, y - dy
                if m.g[fy_][fx_] != "." or (fx_, fy_) in taken or m.lq[fy_][fx_] != ".":
                    continue
                if m.g[by][bx] not in lvlkit.WALLS:
                    continue
                sides = [(x + dy, y + dx), (x - dy, y - dx)]
                if not all(m.g[b][a] in lvlkit.WALLS for (a, b) in sides):
                    continue
                f = hval(m.fh[fy_][fx_], 0)
                c = hval(m.ch[fy_][fx_], 8)
                if c - f < 8:
                    continue
                cand.append((x, y, dx, dy, f, c))
    rng.shuffle(cand)
    made = []
    for (x, y, dx, dy, f, c) in cand:
        if len(made) >= n:
            break
        if (x, y) in RESERVED:  # (a secret wall goes there: not an alcove - the shuffle's the same, so the rest are where they were)
            continue
        if any(abs(x - a) + abs(y - b) < 7 for (a, b) in made):
            continue
        i = len(made)
        m.alcove(x, y, OPEN_TO[(dx, dy)], depth=4, floor=f + 3, ceil=min(f + 7, c - 1), deco=decos[i % len(decos)],
                 glow=glows[i % len(glows)], fx=fx)
        made.append((x, y))
    return len(made)


def open_patch(m, x, y, r, taken):
    f = m.fh[y][x]
    for b in range(y - r, y + r + 1):
        for a in range(x - r, x + r + 1):
            if not (0 < a < N - 1 and 0 < b < N - 1): return False
            if m.g[b][a] != "." or m.fh[b][a] != f or m.lq[b][a] != "." or (a, b) in taken:
                return False
    return True


def auto_columns(m, rng, n, glows, pic=LIT, size=2, wall=3):
    """Up to n slim columns, each in the middle of a 5 x 5 patch of open,
    level, dry floor - lit, every other one."""
    taken = busy(m)
    cand = [(x, y) for y in range(3, N - 3) for x in range(3, N - 3) if open_patch(m, x, y, 2, taken)]
    rng.shuffle(cand)
    made = []
    for (x, y) in cand:
        if len(made) >= n:
            break
        if any(abs(x - a) + abs(y - b) < 6 for (a, b) in made):
            continue
        i = len(made)
        lit = i % 2 == 0
        m.column(x, y, size=size, wall=wall, pic=pic if lit else None, glow=glows[i % len(glows)] if lit else None, fx=0)
        made.append((x, y))
    return len(made)


def nudge_decos(m):
    """Decorations standing by one wall: moved back against it."""
    have = {(a, b) for (a, b, *_r) in m.nudges}
    n = 0
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if m.g[y][x] not in ns.DECO or (x, y) in have or m.g[y][x] in "oSV":
                continue
            walls = [(dx, dy) for (dx, dy) in STEPS if m.g[y + dy][x + dx] in lvlkit.WALLS]
            if len(walls) == 1:
                dx, dy = walls[0]
                face = ns.FACE_CODE[OPEN_TO[(-dx, -dy)]] if m.g[y][x] in ns.FLAT else 0   # (box-like things stand flat, facing away from the wall)
                m.nudge(x, y, dx * 2, dy * 2, face)
                n += 1
    return n


def real_liquids(m, lv):
    """Floor pictures that act like liquids become them: murky -> water,
    slime -> slime; molten / lava -> lava, but only where the sector can
    still be finished without crossing it."""
    pics = floor_pics(m, lv)
    taken = {(x, y) for (x0, y0, x1, y1, *_r) in m.lifts for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}
    made = {"w": 0, "s": 0, "l": 0}
    lava = []
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if m.g[y][x] in lvlkit.WALLS or m.g[y][x] in lvlkit.DOORS or m.lq[y][x] != "." or (x, y) in taken:
                continue
            p = pics[y][x]
            if "murky" in p: kind = "w"
            elif "slime" in p: kind = "s"
            elif "molten" in p or "lava" in p: kind = "l"
            else: continue
            if kind == "l":
                lava.append((x, y))
                continue
            m.liquid(x, y, kind, 2)
            made[kind] += 1
    if lava:
        rows = [list(r) for r in m.rows()]
        for (x, y) in lava:
            if rows[y][x] == ".": rows[y][x] = "#"
        errs, _ = validate(["".join(r) for r in rows], "lava-check", pairs=m.pads)
        if not errs:
            for (x, y) in lava:
                if m.g[y][x] == ".":
                    m.liquid(x, y, "l", 1)
                    made["l"] += 1
        else:
            print("   (molten floors stay floors: crossing them is the way)")
    return made


def exit_posts(m, glow=GREEN, wall=5):
    """Lit posts either side of the exit, against its wall."""
    for y in range(N):
        for x in range(N):
            if m.g[y][x] != "E":
                continue
            for (dx, dy) in STEPS:
                fx, fy = x + dx, y + dy
                if not (0 < fx < N - 1 and 0 < fy < N - 1) or m.g[fy][fx] != ".":
                    continue
                against = OPEN_TO[(-dx, -dy)]
                for s in (-1, 1):
                    px, py = fx + s * (1 if dy else 0), fy + s * (1 if dx else 0)
                    if m.g[py][px] == "." and not any((b[0], b[1]) == (px, py) for b in m.blocks):
                        at = 7 if s < 0 else 1
                        if against in "EW":
                            at = 7 if s < 0 else 1
                        m.post(px, py, against, at=at, w=2, d=2, wall=wall, glow=glow)
                return


REMASTER = {}


def remaster(n):
    def wrap(fn):
        REMASTER[n] = fn
        return fn
    return wrap


THEME = {
    1: ("tA", (CYAN, GREEN), "crate    = ammo:25, shells:20, medkit:20, armor:10"),
    2: ("LA", (AMBER, RED), "barrel   = ammo:15, shells:15, -, -"),
    3: ("tL", (GREEN, AMBER), "crate    = ammo:20, shells:25, medkit:20, armor:10"),
    4: ("IO", (CYAN, GREEN), "cryopod  = overcharge:15, medkit:30, -, -"),
    5: ("Lf", (AMBER, RED), "crate    = ammo:20, shells:30, medkit:20, armor:10"),
    6: ("Ip", (GREEN, PINK), "plant    = medkit:15, -, -, -"),
    7: ("lF", (CYAN, VIOLET), "rack     = ammo:30, overcharge:10, -, -"),
    8: ("nF", (PINK, AMBER), "vending  = ammo:40, shells:30, medkit:15, overcharge:5"),
    9: ("OA", (CYAN, PINK), "locker   = armor:40, medkit:30, overcharge:15, amp:10"),
    10: ("LA", (RED, AMBER), "console  = ammo:30, shells:30, -, -"),
}


RESERVED = set()  # (cells the remake mustn't carve: the original's secret walls)


def original_edits(n, m):
    """The cells of original n that differ from what its builder and
    dressing alone make (levels.py's fixes after them): x, y, before, after."""
    import contextlib, io
    fn = original.LEVELS[n - 1][0]
    with contextlib.redirect_stdout(io.StringIO()):
        m0 = fn()
        original.dress(m0, n)
    pre = m0.rows()
    return [(x, y, pre[y][x], m.g[y][x]) for y in range(N) for x in range(N) if pre[y][x] != m.g[y][x]]


# The remakes' armaments (newsectors' ARMS - turrets' weapons: 0 plasma, 1
# laser, 2 lightning, 3 flame, 4 poison, 5 acid, 6 missiles)
REMIX_ARMS = {
    2: dict(turrets=[0]),
    3: dict(turrets=[0, 3], rockets=1),
    4: dict(turrets=[1, 4], launcher=1, rockets=2),
    5: dict(turrets=[5, 3], rockets=2),
    6: dict(turrets=[2, 6], rockets=2),
    7: dict(turrets=[4, 1], rockets=2),
    8: dict(turrets=[6, 2, 0], rockets=3),
    9: dict(turrets=[3, 5, 1], rockets=3),
    10: dict(turrets=[6, 2, 4, 1], rockets=3),
}


def build(n):
    m, lv = load(n)
    # The original's fixes since it was first remade - monsters moved off
    # its start, sealed tips opened, secret ways into its sealed rooms
    # (levels.py's START_MOVES, OPEN_TIPS, HALLWAYS, open_sealed): taken out
    # while remaking, so the random picks stay as they were, then put back
    edits = original_edits(n, m)
    RESERVED.clear(); RESERVED.update((x, y) for (x, y, _, after) in edits if after == "?")
    for (x, y, before, after) in edits:
        m.g[y][x] = before
    rng = random.Random(9000 + n)
    decos, glows, loot = THEME[n]
    if n in REMASTER:
        REMASTER[n](m, rng)
    liq = real_liquids(m, lv)
    na = auto_alcoves(m, rng, 6, decos, glows)
    nc = auto_columns(m, rng, 6, glows)
    exit_posts(m)
    nn = nudge_decos(m)
    if not any(l.split("=")[0].strip() == loot.split("=")[0].strip() for l in m.loot):
        m.loot.append(loot)
    m.headroom(8)
    for (x, y, before, after) in edits:
        if m.g[y][x] == before:
            m.g[y][x] = after
        elif after == "?":
            lost = True  # (the remake made something there - an alcove: its sealed room gets another way, below)
        else:
            print("  EDIT LOST at %d,%d: the remake changed %r there" % (x, y, before)); ns.PROBLEMS.append(1)
    for (x, y, before, after) in edits:  # (a two-cell way with one cell lost: its other cell back to wall)
        if after == "?" and m.g[y][x] == "?" and not any(m.g[y + dy][x + dx] == "?" for dx, dy in STEPS) \
                and sum(1 for (a, b, _, t) in edits if t == "?" and abs(a - x) + abs(b - y) == 1) > 0:
            m.g[y][x] = before
    original.open_sealed(m, n)  # (any room still sealed: a way in)
    if n in REMIX_ARMS:  # (wall turrets, the rocket launcher and rockets - newsectors' arm)
        ns.ARMS[100 + n] = REMIX_ARMS[n]
        ns.arm(m, 100 + n)
    print("   remastered L%d: %d alcoves, %d columns, %d decorations moved, liquids %s, %d blocks in all"
          % (n, na, nc, nn, liq, len(m.blocks)))
    out = m.level("level%d" % n, lv["name"], lv["walls"], lv["floors"], lv["ceils"])
    return m, out, lv


def build_all(write=False, show=False):
    ok = True
    outs = []
    have = [False, False]  # (the repeater, the railgun: lying in a sector so far)
    for n in range(1, 11):
        print("OLD NEW %d" % n)
        m, lv, orig = build(n)
        if show:
            m.show()
        have = [a or b for a, b in zip(have, lvlkit.guns_in(lv["rows"]))]  # (each gun its own ammo: from the sector you can have the repeater, rounds - the railgun, slugs)
        lv["rows"] = lvlkit.split_ammo(lv["rows"], *have)
        good = check_level(lv, ASSETS)
        errs, _ = ns.reach_with_blocks(lv)
        for e in errs: print("  BLOCKED:", e)
        herrs, _ = lvlkit.check_heights(lv)
        for e in herrs: print("  HEIGHTS ERROR", e)
        good = good and not errs and not herrs
        pics, glows = m.slots()
        c = ns.counts(m)
        print("  slots %d+%d of 24; items %d, monsters %d, decorations %d, lights ~%d, events %d, blocks %d, nudges %d"
              % (pics, glows, c["items"], c["mons"], c["decos"], c["lights"], len(m.events), len(m.blocks), len(m.nudges)))
        for what, k, mx in (("slots", pics + glows, 24), ("items", c["items"], 64), ("monsters", c["mons"], 64),
                            ("decorations", c["decos"], 64), ("lights", c["lights"], 96), ("events", len(m.events), 16),
                            ("nudges", len(m.nudges), 64)):
            if k > mx:
                print("  TOO MANY %s: %d (max %d)" % (what, k, mx))
                good = False
        ok = ok and good
        doc = ["OLD SECTORS NEW: %s, remade by remaster.py from level%d.txt" % (orig["name"], n)]
        outs.append((lv, doc))
    ok = ok and not ns.PROBLEMS
    if write:
        if not ok:
            print("not writing: fix the problems above first")
            return False
        os.makedirs(OUT, exist_ok=True)
        for lv, doc in outs:
            write_level_file(os.path.join(OUT, lv["label"] + ".txt"), lv, doc)
        print("wrote %d sectors into %s" % (len(outs), os.path.normpath(OUT)))
    print("ALL GOOD" if ok else "PROBLEMS")
    return ok


# =====================================================================
# Each sector's own touches (before the passes above)
# =====================================================================


def lit_pillar(m, x, y, glow, pic=LIT, fx=0, lit="NSEW"):
    """A wall cell standing alone (a pillar): its open sides in `pic`, those
    in `lit` lit and tinted `glow`."""
    for side, (dx, dy) in (("E", (1, 0)), ("W", (-1, 0)), ("S", (0, 1)), ("N", (0, -1))):
        if m.g[y + dy][x + dx] == ".":
            m.face(x, y, side, pic)
            if side in lit:
                m.wall_light(x, y, side, *glow, fx=fx, rad=2.5, bright=150)


def neon_sign(m, x, y, side, glow, pic="wall-adverts.png", fx=0):
    """A lit sign on one face of a wall."""
    m.face(x, y, side, pic)
    m.wall_light(x, y, side, *glow, fx=fx, rad=3, bright=170)


@remaster(1)
def r1(m, rng):
    """NEON STATION: a fountain in the hub, the hall's pillars wrapped in
    light, neon signs and posts round the ring."""
    for (x, y) in ((33, 29), (39, 29), (33, 34), (39, 34), (33, 39), (39, 39)):
        if m.g[y][x] in lvlkit.WALLS:
            lit_pillar(m, x, y, CYAN)
    m.pool(22, 21, 25, 22, "w", sink=2, depth=2)
    m.light(23.5, 21.5, 4, 140, 60, 170, 255, 2)
    for (x, y, side, g) in ((1, 12, "E", PINK), (1, 36, "E", AMBER), (46, 12, "W", CYAN), (46, 36, "W", PINK)):
        if m.g[y][x] in lvlkit.WALLS and m.g[y][x + (1 if side == "E" else -1)] == ".":
            neon_sign(m, x, y, side, g)
    for (x, y, a) in ((2, 20, "W"), (2, 32, "W"), (45, 16, "E"), (45, 30, "E")):
        if m.g[y][x] == ".":
            m.post(x, y, a, at=4, w=2, d=2, wall=5, glow=VIOLET)


@remaster(2)
def r2(m, rng):
    """REACTOR CORE: coolant round the reactor, the south hall's pillars
    lit amber, alarm lights strobing over the coolant."""
    for y in range(15, 33):   # (the hall's a bowl: coolant in its lowest ring)
        for x in range(14, 34):
            if m.g[y][x] == "." and m.fh[y][x] == "D":
                m.liquid(x, y, "w", 2)
    for x in (10, 16, 22, 28, 34):
        for y in (39, 40):
            if m.g[y][x] in lvlkit.WALLS:
                lit_pillar(m, x, y, AMBER)
    for (x, y) in ((17, 23), (28, 23), (22, 18), (22, 29)):
        m.light(x + 0.5, y + 0.5, 4, 150, 255, 50, 40, 3)


@remaster(3)
def r3(m, rng):
    """UNDERCITY: slime in the nest, the cistern's pillars glowing green
    round a pool, graffiti lit on the tunnel walls."""
    for (x0, y0, x1, y1) in ((4, 15, 5, 16), (4, 19, 6, 20)):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if m.g[y][x] == "." and m.lq[y][x] == ".":
                    m.pool(x, y, x, y, "s", sink=1, depth=1)
    for (x, y) in ((6, 31), (11, 31), (6, 36), (11, 36), (6, 41), (11, 41)):
        if m.g[y][x] in lvlkit.WALLS:
            lit_pillar(m, x, y, GREEN)
    for y in range(32, 35):
        for x in range(7, 11):
            if m.g[y][x] == "." and m.lq[y][x] == ".":
                m.pool(x, y, x, y, "w", sink=2, depth=2)
    for (x, y, side, g) in ((12, 3, "S", PINK), (22, 21, "S", CYAN), (26, 28, "N", PINK), (31, 33, "W", AMBER)):
        dx, dy = {"E": (1, 0), "W": (-1, 0), "S": (0, 1), "N": (0, -1)}[side]
        if m.g[y][x] in lvlkit.WALLS and m.g[y + dy][x + dx] == ".":
            neon_sign(m, x, y, side, g, pic="wall-graffiti.png")


@remaster(4)
def r4(m, rng):
    """CRYO LAB: chilled water round the atrium's core, four cyan columns
    at its points."""
    cx, cy = 23.5, 23.5
    for y in range(14, 34):
        for x in range(14, 34):
            d = abs(x + 0.5 - cx) + abs(y + 0.5 - cy)
            if m.g[y][x] == "." and 3.5 <= d <= 5.0 and m.fh[y][x] == "." and m.lq[y][x] == ".":
                m.pool(x, y, x, y, "w", sink=2, depth=2)
    for (x, y) in ((17, 23), (30, 23), (23, 17), (23, 30)):
        if m.g[y][x] == ".":
            m.column(x, y, size=2, wall=5, pic=LIT, glow=CYAN, fx=1)


@remaster(5)
def r5(m, rng):
    """FOUNDRY: the smelting hall's paired pillars wrapped in amber light,
    flickering like the fire."""
    for x0 in (12, 20, 28, 36):
        for y0 in (20, 26):
            for (x, y) in ((x0, y0), (x0 + 1, y0), (x0, y0 + 1), (x0 + 1, y0 + 1)):
                if m.g[y][x] in lvlkit.WALLS:
                    lit_pillar(m, x, y, AMBER, fx=4, lit="S" if y0 == 20 else "N")   # (lit toward the hall's middle)


@remaster(6)
def r6(m, rng):
    """HYDROPONICS: grow-light posts in every bay, a poison spill in the
    dome."""
    for bx in (3, 19, 35):
        for by in (3, 19, 35):
            for (x, y, a) in ((bx, by, "N"), (bx + 9, by + 9, "S")):
                if m.g[y][x] == "." and not any((b[0], b[1]) == (x, y) for b in m.blocks):
                    m.post(x, y, a, at=4, w=2, d=2, wall=2, glow=GREEN, fx=2)
    for (x, y) in ((26, 22), (27, 22), (26, 23), (27, 23)):
        if m.g[y][x] == "." and m.lq[y][x] == ".":
            m.pool(x, y, x, y, "p", sink=1, depth=1)


@remaster(7)
def r7(m, rng):
    """DATA VAULT: the rack rows' ends in light strips, the vault's outer
    faces lit violet."""
    for y in (11, 15, 19, 23, 27, 31, 35):
        x = 9
        while x < 39:
            if m.g[y][x] in lvlkit.WALLS and m.g[y][x - 1] == ".":
                m.face(x, y, "W", LIT)
            if m.g[y][x] in lvlkit.WALLS and m.g[y][x + 1] == ".":
                m.face(x, y, "E", LIT)
            x += 1
    for (x, y, side) in ((19, 21, "W"), (19, 26, "W"), (28, 21, "E"), (28, 26, "E"), (22, 19, "N"), (26, 19, "N")):
        dx, dy = {"E": (1, 0), "W": (-1, 0), "S": (0, 1), "N": (0, -1)}[side]
        if m.g[y][x] in lvlkit.WALLS and m.g[y + dy][x + dx] == ".":
            m.face(x, y, side, LIT)
            m.wall_light(x, y, side, *VIOLET, fx=2, rad=2.5, bright=160)


@remaster(8)
def r8(m, rng):
    """MAGLEV DEPOT: neon adverts along both platforms' back walls, rain
    puddles on the platforms."""
    cols = (PINK, CYAN, AMBER)
    i = 0
    for x in range(6, 44, 8):
        for (y, side) in ((2, "S"), (45, "N")):
            fy = y + (1 if side == "S" else -1)
            if m.g[y][x] in lvlkit.WALLS and m.g[fy][x] == ".":
                neon_sign(m, x, y, side, cols[i % 3])
                i += 1
    for (x0, y0, x1, y1) in ((16, 5, 18, 6), (32, 7, 34, 8), (8, 41, 10, 42), (25, 40, 27, 41)):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if m.g[y][x] == "." and m.lq[y][x] == ".":
                    m.pool(x, y, x, y, "w", sink=1, depth=1)


@remaster(9)
def r9(m, rng):
    """ORBITAL SPIRE: eight lit columns round the ring, alternately cyan
    and pink."""
    for i, (x, y) in enumerate(((20, 11), (28, 11), (10, 20), (38, 20), (10, 30), (37, 30), (20, 36), (28, 36))):
        if m.g[y][x] == "." and m.lq[y][x] == ".":
            m.column(x, y, size=2, wall=5, pic=LIT, glow=CYAN if i % 2 else PINK, fx=0)


def safe_pool(m, x0, y0, x1, y1, kind, sink=2, depth=1):
    """A pool over the rectangle's open, dry, empty floor - only if the
    sector can still be finished treating it as solid (so it's never the
    only way)."""
    cells = [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)
             if m.g[y][x] == "." and m.lq[y][x] == "." and not any((b[0], b[1]) == (x, y) for b in m.blocks)]
    if not cells:
        return 0
    rows = [list(r) for r in m.rows()]
    for (x, y) in cells:
        rows[y][x] = "#"
    errs, _ = validate(["".join(r) for r in rows], "pool-check", pairs=m.pads)
    if errs:
        return 0
    for (x, y) in cells:
        m.pool(x, y, x, y, kind, sink=sink, depth=depth)
    return len(cells)


@remaster(10)
def r10(m, rng):
    """THE CORE: red-lit columns in the overseer's arena, lava pooled in
    corners the way doesn't need."""
    for (x, y) in ((22, 22), (25, 22), (22, 25), (25, 25)):
        if m.g[y][x] == ".":
            m.column(x, y, size=2, wall=3, pic=LIT, glow=RED, fx=2)
    n = 0
    for (x0, y0, x1, y1) in ((3, 3, 4, 4), (43, 3, 44, 4), (9, 9, 10, 10), (37, 9, 38, 10), (37, 36, 38, 38), (15, 31, 16, 32), (31, 15, 32, 16)):
        n += safe_pool(m, x0, y0, x1, y1, "l", sink=2, depth=1)
    print("   (lava: %d cells)" % n)


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--check" in args:
        good = True
        for n in range(1, 11):
            f = os.path.join(OUT, "level%d.txt" % n)
            if not os.path.exists(f): continue
            lv = read_level_file(f, "remix%d" % n)
            good = check_level(lv, ASSETS) and good
            errs, _ = ns.reach_with_blocks(lv)
            for e in errs: print("  BLOCKED:", e)
            good = good and not errs
        sys.exit(0 if good else 1)
    sys.exit(0 if build_all("--write" in args, "-show" in args) else 1)
