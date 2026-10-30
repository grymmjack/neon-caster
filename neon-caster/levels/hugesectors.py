"""HUGE SECTORS: ten big sectors - 112 to 192 cells across - built from
districts. Each is a grid of blocks (BLOCK cells a side); some blocks
merge into great halls; a passage joins blocks next to each other, along a
spanning tree with some loops; three keycard doors split the way to the
exit into stretches (loops only inside a stretch, so no key is skipped);
every district gets a floor of its own (stairs between them, lifts up
towers) and a kind - plazas under the sky, office floors, warehouses,
flooded halls, labs, reactors, server farms, gardens, arenas that lock
round you, turret towers with held turrets that come out as you walk in.
Then the campaign's dressers add closets, windows, lasers, plates, a data
station, a hoard, teleporters and a secret stash.

    python3 hugesectors.py             build all ten and check them
    python3 hugesectors.py --write     ...and write levels/huge/levelN.txt
    python3 hugesectors.py 3 7         just those (with --write: write them)

Each sector is built in a process of its own (the kit's N is its size).
"""
import os, sys, random, subprocess
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "huge")
ASSETS = os.path.normpath(os.path.join(HERE, ".."))
BLOCK = 18          # a block's cells a side (its room 15 across, 3 of wall between)
SIZES = {1: 112, 2: 120, 3: 128, 4: 136, 5: 144, 6: 148, 7: 156, 8: 164, 9: 176, 10: 192}

# ------------------------------------------------------------------ themes
# kinds: how often each district kind comes up; liquid: the pools' kind
# (w water, p poison, s slime, l lava, a acid); mons: each stretch's monsters
# (from start to exit); weapons: its turrets' (TW_: 0 plasma 1 laser
# 2 lightning 3 flame 4 poison 5 acid 6 missiles)
THEMES = {
    1: dict(name="SECTOR 1: THE SPRAWL",
            walls=["wall-concrete.png", "wall-brick.png", "wall-adverts.png", "wall-graffiti.png", "wall-lightstrip.png", "wall-transit.png"],
            floors=["floor-concrete.png", "floor-cobbles.png", "floor-plates.png", "floor-deck.png"],
            ceils=["ceiling-lights.png", "sky-neon-night.png"], ambient=(150, 200, 210, 255), liquid="w",
            kinds=dict(plaza=4, office=3, store=3, pool=1, hall=3, arena=2, tower=1, garden=1),
            mons=["mmcg", "gmck", "gk5w", "g5hw"], weapons=[0, 1, 0], puzzles="hello", droids=8,
            light=(255, 120, 220), light2=(90, 230, 255)),
    2: dict(name="SECTOR 2: THE FOUNDRY",
            walls=["wall-furnace.png", "wall-rusty.png", "wall-girders.png", "wall-hazard.png", "wall-coils.png", "wall-pipes.png"],
            floors=["floor-rustgrate.png", "floor-scorched.png", "floor-molten.png", "floor-plates.png"],
            ceils=["ceiling-girders.png", "sky-dusk.png"], ambient=(150, 230, 190, 160), liquid="l",
            kinds=dict(reactor=4, store=3, pool=3, hall=3, arena=2, tower=2, plaza=1),
            mons=["mcgg", "gcwk", "w5gh", "h5w0"], weapons=[3, 3, 6], puzzles="multiply", droids=6,
            light=(255, 150, 60), light2=(255, 90, 40)),
    3: dict(name="SECTOR 3: TIDEWORKS",
            walls=["wall-greenpipes.png", "wall-grate.png", "wall-moss.png", "wall-pipes.png", "wall-slime.png", "wall-brick.png"],
            floors=["floor-concrete.png", "floor-rustgrate.png", "floor-murky.png", "floor-cobbles.png"],
            ceils=["ceiling-pipes.png", "sky-storm.png"], ambient=(140, 180, 220, 220), liquid="w",
            kinds=dict(pool=6, hall=3, store=2, reactor=1, arena=2, tower=1, plaza=2),
            mons=["mmcc", "ckmg", "wkg6", "w6h5"], weapons=[2, 0, 4], puzzles="countdown", droids=6,
            light=(90, 200, 255), light2=(120, 255, 200)),
    4: dict(name="SECTOR 4: THE ARCOLOGY",
            walls=["wall-white.png", "wall-tiles.png", "wall-viewport.png", "wall-lightstrip.png", "wall-control.png", "wall-hull.png"],
            floors=["floor-white.png", "floor-platform.png", "floor-deck.png", "floor-circuit.png"],
            ceils=["ceiling-lights.png", "sky-dusk.png"], ambient=(165, 220, 230, 255), liquid="w",
            kinds=dict(tower=5, office=3, plaza=3, garden=2, hall=2, arena=2, lab=1),
            mons=["mmgc", "gk1m", "5g1k", "5h17"], weapons=[1, 1, 2], puzzles="password", droids=10,
            light=(200, 230, 255), light2=(255, 200, 120)),
    5: dict(name="SECTOR 5: THE BIOME",
            walls=["wall-greenhouse.png", "wall-vines.png", "wall-moss.png", "wall-biolab.png", "wall-slime.png", "wall-lightstrip.png"],
            floors=["floor-soil.png", "floor-lab.png", "floor-murky.png", "floor-deck.png"],
            ceils=["ceiling-growlights.png", "sky-dusk.png"], ambient=(150, 200, 255, 170), liquid="s",
            kinds=dict(garden=6, lab=3, pool=3, plaza=2, arena=2, hall=1, tower=1),
            mons=["ccmk", "kcw6", "w6kc", "6wh5"], weapons=[4, 4, 5], puzzles="sum", droids=8,
            light=(160, 255, 120), light2=(255, 230, 120)),
    6: dict(name="SECTOR 6: CRYOVAULT",
            walls=["wall-ice.png", "wall-frost.png", "wall-cryo.png", "wall-vault.png", "wall-hull.png", "wall-white.png"],
            floors=["floor-ice.png", "floor-frostgrate.png", "floor-white.png", "floor-plates.png"],
            ceils=["ceiling-frost.png", "sky-storm.png"], ambient=(150, 200, 230, 255), liquid="w",
            kinds=dict(lab=4, store=3, hall=3, pool=2, arena=2, tower=2, plaza=1),
            mons=["mgsm", "gs1k", "s15g", "s15h"], weapons=[1, 2, 1], puzzles="pythagoras", droids=6,
            light=(150, 220, 255), light2=(230, 240, 255)),
    7: dict(name="SECTOR 7: THE DATA CENTRE",
            walls=["wall-servers.png", "wall-datastream.png", "wall-code.png", "wall-core.png", "wall-terminals.png", "wall-jack.png"],
            floors=["floor-circuit.png", "floor-core.png", "floor-glow.png", "floor-plates.png"],
            ceils=["ceiling-cables.png", "sky-neon-night.png"], ambient=(140, 170, 255, 210), liquid="p",
            kinds=dict(server=6, office=3, hall=2, arena=2, tower=2, lab=1, plaza=1),
            mons=["mmgk", "gk15", "51kh", "5h17"], weapons=[2, 1, 6], puzzles="select", droids=10,
            light=(80, 255, 160), light2=(120, 160, 255)),
    8: dict(name="SECTOR 8: THE BADLANDS",
            walls=["wall-rusty.png", "wall-hazard.png", "wall-concrete.png", "wall-slime.png", "wall-girders.png", "wall-stripes.png"],
            floors=["floor-scorched.png", "floor-hazard.png", "floor-soil.png", "floor-rustgrate.png"],
            ceils=["ceiling-warning.png", "sky-dusk.png"], ambient=(150, 255, 210, 150), liquid="a",
            kinds=dict(plaza=6, pool=3, store=2, reactor=2, arena=3, tower=1, hall=1),
            mons=["mcgw", "wgk6", "w65h", "h650"], weapons=[5, 6, 5], puzzles="function", droids=4,
            light=(255, 210, 90), light2=(200, 255, 80)),
    9: dict(name="SECTOR 9: THE ORBITAL RING",
            walls=["wall-hull.png", "wall-viewport.png", "wall-control.png", "wall-core.png", "wall-lightstrip.png", "wall-obsidian.png"],
            floors=["floor-platform.png", "floor-deck.png", "floor-circuit.png", "floor-core.png"],
            ceils=["ceiling-hull.png", "sky-orbit.png"], ambient=(150, 210, 220, 255), liquid="p",
            kinds=dict(hall=3, lab=3, server=2, plaza=3, arena=3, tower=2, office=1, reactor=1),
            mons=["mgk1", "g15k", "51h6", "5h76"], weapons=[6, 2, 1], puzzles="reverse", droids=8,
            light=(160, 200, 255), light2=(255, 120, 200)),
    10: dict(name="SECTOR 10: THE SPIRE",
             walls=["wall-obsidian.png", "wall-core.png", "wall-reactor.png", "wall-vault.png", "wall-lightstrip.png", "wall-turret.png"],
             floors=["floor-core.png", "floor-glow.png", "floor-platform.png", "floor-circuit.png"],
             ceils=["ceiling-core.png", "sky-neon-night.png"], ambient=(140, 200, 160, 255), liquid="l",
             kinds=dict(tower=4, arena=4, reactor=2, hall=2, plaza=2, server=1, lab=1),
             mons=["gmk5", "5k1h", "51h6", "h175"], weapons=[6, 2, 3], puzzles="wrap", droids=6,
             light=(255, 90, 160), light2=(140, 120, 255)),
}

DECOR = dict(  # what stands in each kind of district
    plaza="ppWWi", office="dZtpU", store="xxxoU", pool="io", hall="iWp", arena="xo", tower="tA",
    garden="pppWi", lab="JIOAQ", reactor="LfLo", server="llFA")
LOOT = ["crate    = cells:30, shells:25, medkit:20, armor:10",
        "locker   = armor:40, medkit:30, overcharge:10, -",
        "barrel   = cells:20, -, -, -"]


def safe_floors(th):
    """The theme's floors you can stand on (FloorHazard: molten and lava burn, murky and slime wade): their numbers, 1-4"""
    return [i + 1 for i, f in enumerate(th["floors"]) if not any(w in f for w in ("molten", "lava", "murky", "slime"))]


def build(k, seed):
    """Sector k, by seed: (the map, its level dict) - or None if it can't be laid out."""
    import lvlkit
    import newsectors as ns
    camp = ns.camp
    N = lvlkit.N
    th = THEMES[k]
    rng = random.Random(seed)
    m = ns.Sector("#")
    m.ambient = th["ambient"]
    m.puzzles = th["puzzles"]
    G = (N - 4) // BLOCK
    ox = lambda i: 2 + i * BLOCK
    # ---- regions: blocks, some merged into great halls (2x2, or 2x1)
    reg = {}
    regions = []  # (i0, j0, i1, j1)
    start_b, exit_hint = (0, G - 1), (G - 1, 0)
    order = [(i, j) for j in range(G) for i in range(G)]
    rng.shuffle(order)
    for (i, j) in order:
        if (i, j) in reg or (i, j) == start_b:
            continue
        w, h = rng.choice(((2, 2), (2, 2), (2, 1), (1, 2), (3, 2)))
        if rng.random() < 0.7 or i + w > G or j + h > G:
            continue
        cells = [(a, b) for a in range(i, i + w) for b in range(j, j + h)]
        if any(c in reg or c == start_b for c in cells):
            continue
        if sum(1 for r in regions if (r[2] - r[0] + 1) * (r[3] - r[1] + 1) > 1) >= max(2, G * G // 9):
            continue
        for c in cells:
            reg[c] = len(regions)
        regions.append((i, j, i + w - 1, j + h - 1))
    for j in range(G):
        for i in range(G):
            if (i, j) not in reg:
                reg[(i, j)] = len(regions)
                regions.append((i, j, i, j))
    R = len(regions)
    # ---- the passages a region could have: (region a, region b, block a, block b)
    cand = {}
    for (i, j), a in reg.items():
        for di, dj in ((1, 0), (0, 1)):
            nb = (i + di, j + dj)
            if nb in reg and reg[nb] != a:
                key = tuple(sorted((a, reg[nb])))
                cand.setdefault(key, []).append(((i, j), nb))
    adj = {r: set() for r in range(R)}
    for (a, b) in cand:
        adj[a].add(b); adj[b].add(a)
    # ---- a spanning tree from the start (randomised depth first: long ways)
    s0 = reg[start_b]
    parent = {s0: None}
    stack = [s0]
    while stack:
        r = stack[-1]
        nxt = [n for n in adj[r] if n not in parent]
        if not nxt:
            stack.pop(); continue
        n = rng.choice(nxt)
        parent[n] = r
        stack.append(n)
    if len(parent) < R:
        return None
    depth = {s0: 0}
    for r in sorted(parent, key=lambda r: 0):
        pass
    q = deque([s0])
    kids = {r: [] for r in range(R)}
    for r, p in parent.items():
        if p is not None:
            kids[p].append(r)
    while q:
        r = q.popleft()
        for c in kids[r]:
            depth[c] = depth[r] + 1
            q.append(c)
    exit_r = max(range(R), key=lambda r: (depth[r], -abs(regions[r][0] - exit_hint[0]) - abs(regions[r][1] - exit_hint[1])))
    path = [exit_r]
    while parent[path[-1]] is not None:
        path.append(parent[path[-1]])
    path.reverse()
    if len(path) < 8:
        return None
    # ---- three keycard doors on the way, splitting it into stretches
    gates = {}  # (parent, child) -> "R" / "B" / "Y"
    for f, c in ((0.28, "R"), (0.55, "B"), (0.8, "Y")):
        idx = max(1, int(len(path) * f))
        gates[(path[idx - 1], path[idx])] = c
    zone = {s0: 0}
    q = deque([s0])
    while q:
        r = q.popleft()
        for c in kids[r]:
            zone[c] = zone[r] + (1 if (r, c) in gates else 0)
            q.append(c)
    # ---- floors: down the tree, a step or a flight of stairs from the last
    floor = {s0: 0}
    q = deque([s0])
    while q:
        r = q.popleft()
        for c in kids[r]:
            d = rng.choice((0, 0, 4, 8, 8, 12, -4, -8))
            floor[c] = max(0, min(96, floor[r] + d))
            q.append(c)
    edges = [(p, c) for c, p in parent.items() if p is not None]
    for (a, b), spots in cand.items():  # loops - inside a stretch, close enough in height
        if (a, b) in edges or (b, a) in edges:
            continue
        if zone[a] == zone[b] and abs(floor[a] - floor[b]) <= 12 and rng.random() < 0.35:
            edges.append((a, b))
    # ---- what each region is
    kinds = list(th["kinds"])
    weights = [th["kinds"][x] for x in kinds]
    kind = {}
    for r in range(R):
        i0, j0, i1, j1 = regions[r]
        big = (i1 - i0 + 1) * (j1 - j0 + 1) > 1
        if r == s0:
            kind[r] = "hall"
        elif r == exit_r:
            kind[r] = "arena" if k >= 5 else "hall"
        elif big:
            kind[r] = rng.choice(("plaza", "plaza", "arena", "pool", "garden" if "garden" in kinds else "plaza"))
        else:
            kind[r] = rng.choices(kinds, weights)[0]
    # ---- carve the rooms
    box = {}
    for r, (i0, j0, i1, j1) in enumerate(regions):
        ins = lambda: rng.choice((1, 2, 2, 3, 4))  # (each side set back its own way: rooms of every size, off the grid)
        x0, y0, x1, y1 = ox(i0) + ins(), ox(j0) + ins(), ox(i1) + BLOCK - 1 - ins(), ox(j1) + BLOCK - 1 - ins()
        if r == s0:
            x0, y0, x1, y1 = ox(i0) + 2, ox(j0) + 2, ox(i1) + BLOCK - 3, ox(j1) + BLOCK - 3
        box[r] = (x0, y0, x1, y1)
        f = floor[r]
        tall = {"plaza": 40, "tower": 48, "garden": 32, "arena": 28, "hall": 24, "pool": 24, "reactor": 32}.get(kind[r], 16)
        if (i1 - i0 + 1) * (j1 - j0 + 1) > 1:
            tall += 16
        m.room(x0, y0, x1, y1, floor=f, ceil=min(f + tall, 232))
        fz = rng.choice(safe_floors(th))
        cz = 2 if kind[r] in ("plaza", "garden") else 1
        m.zone(x0, y0, x1, y1, fz, cz)
    # ---- the passages: through the wall between two blocks, stairs where the floors differ
    doors_at = []
    for (a, b) in edges:
        spots = cand.get(tuple(sorted((a, b))))
        (ba, bb) = rng.choice(spots)
        if reg[ba] != a:
            ba, bb = bb, ba
        gate = gates.get((a, b)) or gates.get((b, a))
        style = gate or rng.choice(("arch", "arch", "D", "H", "X", "arch"))
        if a == s0 or b == s0 or "arena" in (kind[a], kind[b]):
            style = gate or rng.choice("DHX")  # (the start's own room - shut doors, nothing sees you at once - and an arena's: its lockdown has doors to lock)
        carve_passage(m, rng, ba, bb, box[a], box[b], floor[a], floor[b], style, ox)
        doors_at.append((ba, bb))
    # ---- the start and the exit
    x0, y0, x1, y1 = box[s0]
    m.put((x0 + x1) // 2, (y0 + y1) // 2, "^")
    ex0, ey0, ex1, ey1 = box[exit_r]
    placed = False
    for (x, y) in [((ex0 + ex1) // 2, ey0 - 1), (ex0 - 1, (ey0 + ey1) // 2), (ex1 + 1, (ey0 + ey1) // 2), ((ex0 + ex1) // 2, ey1 + 1)]:
        if m.g[y][x] == "#" and all(m.g[y + dy][x + dx] == "#" for dx, dy in ((-1, 0), (1, 0)) if y in (ey0 - 1, ey1 + 1)) \
                and all(m.g[y + dy][x + dx] == "#" for dx, dy in ((0, -1), (0, 1)) if x in (ex0 - 1, ex1 + 1)):
            m.put(x, y, "E")
            m.light(x + 0.5, y + (1.5 if y == ey0 - 1 else -0.5 if y == ey1 + 1 else 0.5), 5, 150, 120, 255, 160, 2)
            placed = True
            break
    if not placed:
        return None
    # ---- each district's shape: notched, a cross, an octagon, a dais, buildings in a plaza, a mezzanine
    for r in range(R):
        if r != s0:
            shape_region(m, rng, kind[r], box[r], floor[r], (regions[r][2] - regions[r][0] + 1) * (regions[r][3] - regions[r][1] + 1) > 1)
    # ---- each district's dressing, lights, monsters and pickups
    pick = lambda r: open_cells(m, box[r])
    weapons_by_zone = {0: "2", 1: "3", 2: "4)", 3: "("}
    for r in range(R):
        dress_region(m, rng, k, th, r, kind[r], box[r], floor[r], zone[r], r == s0, r == exit_r)
    # guns along the way: the scatter gun near the start, the repeater, the railgun and launcher later
    by_zone = {}
    for r in range(R):
        by_zone.setdefault(zone[r], []).append(r)
    for z, chars in weapons_by_zone.items():
        rs = [r for r in by_zone.get(z, []) if r != s0] or by_zone.get(z, [])
        if not rs:
            continue
        rs.sort(key=lambda r: depth[r])
        for n, ch in enumerate(chars):
            r = rs[min(len(rs) - 1, 1 + n * 2)]
            put_free(m, rng, box[r], ch)
    # the keys: each in its stretch, as far into it as can be (a branch off the way, if there is one)
    for (p, c), col in gates.items():
        z = zone[p]
        rs = [r for r in by_zone.get(z, []) if r not in path] or [r for r in by_zone.get(z, [])]
        r = max(rs, key=lambda r: depth[r])
        put_free(m, rng, box[r], col.lower())
    put_free(m, rng, box[path[min(2, len(path) - 1)]], "M")
    put_free(m, rng, box[rng.choice(by_zone.get(1, [s0]))], "8")
    if th["liquid"] in "psa":
        put_free(m, rng, box[path[min(3, len(path) - 1)]], "9")
    # the way out: something to fight for it
    if k >= 4:
        boss = "7" if k < 8 else "0"
        put_free(m, rng, box[exit_r], boss, far_from_doors=True)
    trim(m, rng)
    m.loot = list(LOOT)
    return m, dict(regions=regions, kind=kind, zone=zone, path=path, floor=floor, box=box, start=s0, exit=exit_r, gates=gates)


def trim(m, rng, mons=104, deco=136, items=140):
    """Down to the game's budget, leaving room for what the dressers add:
    monsters (not turrets, bosses or thieves), decorations (not the spawner
    nests use), pickups (not keys, guns, the map or the gear) picked out at
    random until there are few enough"""
    import lvlkit
    for chars, most, keep in ((lvlkit.MONS, mons, "~_|70zT"), (lvlkit.DECO, deco, "S"), (lvlkit.ITEMS, items, "rby234M89)q")):
        cells = [(x, y) for y, r in enumerate(m.g) for x, c in enumerate(r) if c in chars]
        spare = [c for c in cells if m.g[c[1]][c[0]] not in keep]
        rng.shuffle(spare)
        while len(cells) > most and spare:
            x, y = spare.pop()
            m.g[y][x] = "."
            m.mons.pop((x, y), None)
            cells.remove((x, y))


def carve_passage(m, rng, ba, bb, A, B, fa, fb, style, ox):
    """The way between block ba (region with room A, floor fa) and the block
    next to it, bb (room B, floor fb): through the wall between them, one
    cell wide with a door in it (style a door's character) or three wide
    (an arch); stairs climb any difference, out into the lower room."""
    (ia, ja), (ib, jb) = ba, bb
    horiz = ja == jb
    if horiz:
        lo, hi = (A, B) if ia < ib else (B, A)
        flo, fhi = (fa, fb) if ia < ib else (fb, fa)
        x_from, x_to = lo[2] + 1, hi[0] - 1  # the wall's cells
        mid = ox(ja) + BLOCK // 2
        mid = max(max(lo[1], hi[1]) + 2, min(min(lo[3], hi[3]) - 2, mid))
        cells = [(x, mid) for x in range(x_from, x_to + 1)]
        side = lambda c, t: [(c[0], c[1] + t)]
    else:
        lo, hi = (A, B) if ja < jb else (B, A)
        flo, fhi = (fa, fb) if ja < jb else (fb, fa)
        y_from, y_to = lo[3] + 1, hi[1] - 1
        mid = ox(ia) + BLOCK // 2
        mid = max(max(lo[0], hi[0]) + 2, min(min(lo[2], hi[2]) - 2, mid))
        cells = [(mid, y) for y in range(y_from, y_to + 1)]
        side = lambda c, t: [(c[0] + t, c[1])]
    wide = style == "arch"
    # heights along the way: from flo (the first room's side) to fhi, 2 eighths a cell at most,
    # with any more cells it needs taken from the lower room
    d = fhi - flo
    steps = max(0, (abs(d) + 1) // 2 - 1)  # (the cells between the two floors)
    ramp = list(cells)
    extra = max(0, steps - len(cells))
    if extra:
        if d > 0:  # the first room is lower: the stairs come out into it
            first = cells[0]
            back = [(first[0] - (n + 1), first[1]) if horiz else (first[0], first[1] - (n + 1)) for n in range(extra)]
            ramp = list(reversed(back)) + ramp
        else:
            last = cells[-1]
            fwd = [(last[0] + n + 1, last[1]) if horiz else (last[0], last[1] + n + 1) for n in range(extra)]
            ramp = ramp + fwd
    n = len(ramp)
    import lvlkit
    for t, c in enumerate(ramp):
        e = flo + round(d * (t + 1) / (n + 1) / 2) * 2 if d else flo
        for cc in [c] + ((side(c, -1) + side(c, 1)) if wide or c not in cells else []):
            x, y = cc
            if c in cells and not wide and cc != c:
                continue
            m.g[y][x] = "."
            m.fh[y][x] = lvlkit.hchar(e)
            m.ch[y][x] = lvlkit.hchar(min(e + 14, 238), ceiling=True)
    if not wide:
        c = cells[len(cells) // 2]
        m.g[c[1]][c[0]] = style


def clear_of_ways(m, b, x0, y0, x1, y1, r=3):
    """Is every cell of the rectangle open floor, and clear of the room's ways in?"""
    return all(m.g[y][x] == "." and not near_way(m, (x, y), b, r) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1))


def shape_region(m, rng, kind, b, f, big):
    """A district's shape and its floors: rock taken back into a corner (or
    all four - a cross), the corners cut off on the slant, a dais stepped up
    in the middle of a big hall, little buildings standing in a plaza, a
    mezzanine along a tall room's wall with stairs up to it"""
    import lvlkit
    x0, y0, x1, y1 = b
    W, H = x1 - x0 + 1, y1 - y0 + 1
    shape = rng.choice(("box", "notch", "notch", "cross", "octagon", "octagon", "mezzanine", "mezzanine"))
    if big and kind in ("plaza", "garden", "arena", "hall"):
        shape = rng.choice(("dais", "buildings", "buildings", "dais", "octagon"))
        if kind == "arena":  # (an arena locks down: a building in it, its door sealed too, could shut the ambush's monsters away for good)
            shape = rng.choice(("dais", "octagon"))
    if W < 10 or H < 10:
        shape = "octagon" if W >= 7 and H >= 7 else "box"
    if shape in ("notch", "cross"):
        nw, nh = max(2, W * (35 if shape == "notch" else 25) // 100), max(2, H * (35 if shape == "notch" else 25) // 100)
        corners = [(x0, y0), (x1 - nw + 1, y0), (x0, y1 - nh + 1), (x1 - nw + 1, y1 - nh + 1)]
        for (cx, cy) in (corners if shape == "cross" else [rng.choice(corners)]):
            if clear_of_ways(m, b, cx, cy, cx + nw - 1, cy + nh - 1, 2):
                for y in range(cy, cy + nh):
                    for x in range(cx, cx + nw):
                        m.g[y][x] = "#"
    if shape == "octagon":
        s = 2 if min(W, H) >= 12 else 1
        for (cx, cy, dx, dy, ch) in ((x0, y0, 1, 1, "/"), (x1, y0, -1, 1, "\\"), (x0, y1, 1, -1, "\\"), (x1, y1, -1, -1, "/")):
            cells = [(cx + dx * i, cy + dy * j) for i in range(s + 1) for j in range(s + 1) if i + j <= s]
            if all(m.g[y][x] == "." and not near_way(m, (x, y), b, 2) for (x, y) in cells):
                for (x, y) in cells:
                    i, j = abs(x - cx), abs(y - cy)
                    m.g[y][x] = "#" if i + j < s else ch
    if shape == "mezzanine" and H >= 11 and W >= 12 and lvlkit.hval(m.ch[y0][x0], 8) - f >= 22:
        # along the north wall: three deep, twelve eighths up, stairs up from the west end
        if clear_of_ways(m, b, x0, y0, x1, y0 + 3, 1):
            for x in range(x0, x1 + 1):
                for y in range(y0, y0 + 3):
                    i = x - x0
                    m.fh[y][x] = lvlkit.hchar(f + min(12, 2 * (i + 1)))
            m.light(x1 - 2.5, y0 + 1.5, 5, 120, 255, 220, 140, 0)
    if shape == "dais" and W >= 14 and H >= 14:
        # stepped up to the middle: rings of 2, 4, 6 eighths, the top three walls of floor across
        cx0, cy0, cx1, cy1 = x0 + W // 2 - 4, y0 + H // 2 - 4, x0 + W // 2 + 3, y0 + H // 2 + 3
        if clear_of_ways(m, b, cx0, cy0, cx1, cy1, 2):
            for ring in range(4):
                for y in range(cy0 + ring, cy1 - ring + 1):
                    for x in range(cx0 + ring, cx1 - ring + 1):
                        m.fh[y][x] = lvlkit.hchar(f + 2 * (ring + 1))
            m.light(x0 + W / 2, y0 + H / 2, 6, 160, 255, 200, 255, 2)
    if shape == "buildings" and W >= 22 and H >= 22:
        # one or two blocks of building standing in the open, a door into each
        for _ in range(rng.choice((1, 2, 2))):
            bw, bh = rng.choice((7, 8, 9)), rng.choice((7, 8, 9))
            for _try in range(12):
                bx = rng.randint(x0 + 3, x1 - 3 - bw); by = rng.randint(y0 + 3, y1 - 3 - bh)
                if clear_of_ways(m, b, bx - 1, by - 1, bx + bw, by + bh, 3):
                    for y in range(by, by + bh):
                        for x in range(bx, bx + bw):
                            edge = x in (bx, bx + bw - 1) or y in (by, by + bh - 1)
                            m.g[y][x] = "#" if edge else "."
                            if not edge:
                                m.ch[y][x] = lvlkit.hchar(f + 12, ceiling=True)
                    side = rng.choice("NSWE")
                    dx, dy = {"N": (bx + bw // 2, by), "S": (bx + bw // 2, by + bh - 1), "W": (bx, by + bh // 2), "E": (bx + bw - 1, by + bh // 2)}[side]
                    m.g[dy][dx] = rng.choice("DH")
                    m.zone(bx + 1, by + 1, bx + bw - 2, by + bh - 2, 1, 1)
                    m.light(bx + bw / 2, by + bh / 2, 4, 130, 255, 230, 200, rng.choice((0, 1)))
                    break


def dry_pool(m, b, x0, y0, x1, y1, kind, sink, depth):
    """A pool in the rectangle - but only on cells with open floor two cells
    round them every way, so a dry walkway always goes round it (a cross's
    notched corners, a building, a column don't leave it the only way)"""
    import lvlkit
    ok = lambda x, y: all(m.g[y + dy][x + dx] not in lvlkit.WALLS and m.g[y + dy][x + dx] not in "/\\DHXRBYE!=|" and not near_way(m, (x, y), b, 2)
                          for dy in range(-2, 3) for dx in range(-2, 3))
    for y in range(y0, y1 + 1):
        x = x0
        while x <= x1:
            if not ok(x, y):
                x += 1
                continue
            xa = x
            while x <= x1 and ok(x, y):
                x += 1
            m.pool(xa, y, x - 1, y, kind, sink=sink, depth=depth)


def dry_reach(lv):
    """Can you get to every keycard and the exit without wading through
    anything that hurts (lava, acid, poison, a burning floor) - by the
    heights' rules, every door open? The keycards and exit you can't, as a list"""
    import lvlkit
    rows = lv["rows"]; N = len(rows)
    fl = [[lvlkit.hval(c, 0) / 8 for c in r] for r in lv["floor"]]
    ce = [[lvlkit.hval(c, 8) / 8 for c in r] for r in lv["ceiling"]]
    lq = lv.get("liquid") or ["." * N] * N
    ftex = [[1] * N for _ in range(N)]
    for (x0, y0, x1, y1, f, c, sh) in lv["zones"]:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                ftex[y][x] = f
    lifts = {(x, y) for (x0, y0, x1, y1, *_r) in lv.get("lifts", []) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}
    solid = set("#NCKPG/\\%?=@$;|E") | lvlkit.DECO
    hot = lambda x, y: any(w in lv["floors"][ftex[y][x] - 1] for w in ("molten", "lava")) or lq[y][x] in "lap"
    st = [(x, y) for y, r in enumerate(rows) for x, c in enumerate(r) if c in "<>^v"][0]
    pads = [(x, y) for y, r in enumerate(rows) for x, c in enumerate(r) if c == "&"]
    seen = {st}
    q = deque([st])
    while q:
        x, y = q.popleft()
        nb = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if (x, y) in pads:  # (pads pair in reading order)
            i = pads.index((x, y)); nb.append(pads[i ^ 1] if (i ^ 1) < len(pads) else (x, y))
        for (a, b) in nb:
            if (a, b) in seen or rows[b][a] in solid or hot(a, b) or fl[b][a] <= -0.99:
                continue
            if (x, y) not in lifts and (a, b) not in lifts and fl[b][a] > fl[y][x] + 0.32 and (a, b) not in pads:
                continue
            if ce[b][a] - max(fl[b][a], fl[y][x]) < 0.7:
                continue
            seen.add((a, b)); q.append((a, b))
    want = [(c, x, y) for y, r in enumerate(rows) for x, c in enumerate(r) if c in "rbyE"]
    bad = []
    for (c, x, y) in want:
        if c == "E":
            if not any((x + dx, y + dy) in seen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                bad.append("exit")
        elif (x, y) not in seen:
            bad.append(c)
    return bad


def open_cells(m, b):
    x0, y0, x1, y1 = b
    return [(x, y) for y in range(y0 + 1, y1) for x in range(x0 + 1, x1) if m.g[y][x] == "."]


def put_free(m, rng, b, ch, far_from_doors=True, mons=None):
    """ch in an open cell of room b, clear of its doorways (and its stairs)"""
    x0, y0, x1, y1 = b
    cells = [(x, y) for y in range(y0 + 1, y1) for x in range(x0 + 1, x1)
             if m.g[y][x] == "." and m.lq[y][x] == "." and m.fh[y][x] == m.fh[(y0 + y1) // 2][(x0 + x1) // 2]]
    if far_from_doors:
        cells = [c for c in cells if not near_way(m, c, b)]
    if not cells:
        return None
    c = rng.choice(cells)
    m.g[c[1]][c[0]] = ch
    if mons:
        m.mons[c] = mons
    return c


def near_way(m, c, b, r=2):
    """Is cell c within r of a way into its room (a gap in the room's wall)?"""
    x0, y0, x1, y1 = b
    x, y = c
    for xx in range(x - r, x + r + 1):
        for yy in (y0 - 1, y1 + 1):
            if x0 <= xx <= x1 and abs(yy - y) <= r + 1 and m.g[yy][xx] != "#":
                return True
    for yy in range(y - r, y + r + 1):
        for xx in (x0 - 1, x1 + 1):
            if y0 <= yy <= y1 and abs(xx - x) <= r + 1 and m.g[yy][xx] != "#":
                return True
    return False


def dress_region(m, rng, k, th, r, kind, b, f, z, is_start, is_exit):
    """One district: what's in it, by its kind"""
    import lvlkit
    x0, y0, x1, y1 = b
    W, H = x1 - x0 + 1, y1 - y0 + 1
    cx, cy = (x0 + x1) / 2 + 0.5, (y0 + y1) / 2 + 0.5
    L1, L2 = th["light"], th["light2"]
    rad = max(6, min(10, max(W, H) // 2))
    # light: one in the middle, more in a big room
    m.light(cx, cy, rad, 150 if kind not in ("server", "reactor") else 120, *L1, 0)
    if W * H > 300:
        for (lx, ly) in ((x0 + 3.5, y0 + 3.5), (x1 - 2.5, y1 - 2.5), (x0 + 3.5, y1 - 2.5), (x1 - 2.5, y0 + 3.5)):
            m.light(lx, ly, 7, 130, *L2, rng.choice((0, 0, 1, 2)))
    deco = DECOR.get(kind, "x")
    nd = {"plaza": 6, "office": 8, "store": 9, "pool": 2, "hall": 3, "arena": 3, "tower": 2, "garden": 9, "lab": 6, "reactor": 5, "server": 10}.get(kind, 3)
    if W * H > 300:
        nd = nd * 3 // 2
    if is_start:
        nd = 2
    for _ in range(nd):
        put_free(m, rng, b, rng.choice(deco))
    if kind == "hall":
        for x in range(x0 + 3, x1 - 2, 5):
            for y in (y0 + 3, y1 - 3):
                if m.g[y][x] == "." and not near_way(m, (x, y), b, 3):
                    m.column(x, y, size=2, wall=3)
    if kind == "pool" and W >= 9 and H >= 9:
        dry_pool(m, b, x0 + 3, y0 + 3, x1 - 3, y1 - 3, th["liquid"], sink=2, depth=2)
    if kind == "garden" and W >= 9:
        dry_pool(m, b, x0 + 4, y0 + 4, x0 + 6, y0 + 6, "w", sink=1, depth=1)
    if kind == "office":
        for y in range(y0 + 4, y1 - 2, 5):
            if all(m.g[y][x] == "." for x in range(x0 + 2, x0 + 7)) and not near_way(m, (x0 + 4, y), b, 3):
                m.thin_wall(x0 + 2, y, x0 + 6, y, "S", t=1, wall=3)
    if kind == "store":
        for y in range(y0 + 3, y1 - 2, 4):
            if not near_way(m, (x1 - 4, y), b, 3) and all(m.g[y][x] == "." for x in range(x1 - 6, x1 - 1)):
                m.thin_wall(x1 - 6, y, x1 - 2, y, "S", t=2, wall=4)
    hot = [i + 1 for i, fl in enumerate(th["floors"]) if "molten" in fl]
    if kind == "reactor" and hot and W >= 12 and H >= 10:  # (a channel of molten metal across part of it: walk round it)
        y = y0 + H // 2
        if clear_of_ways(m, b, x0 + 3, y, x1 - 4, y + 1, 3):
            m.zone(x0 + 3, y, x1 - 4, y + 1, hot[0], 1)
            m.light((x0 + x1) / 2 + 0.5, y + 1, 6, 130, 255, 120, 30, 4)
    if kind == "server":
        for y in range(y0 + 3, y1 - 2, 3):
            for x in range(x0 + 3, x1 - 2, 4):
                if m.g[y][x] == "." and not near_way(m, (x, y), b, 2):
                    m.g[y][x] = "l"
    if kind == "tower" and W >= 9 and H >= 9:
        # a raised platform two walls up, a lift beside it, something worth the climb on it - and a turret
        px0, py0, px1, py1 = x0 + 3, y0 + 3, x0 + 6, y0 + 6
        if all(m.g[y][x] == "." for y in range(py0, py1 + 2) for x in range(px0, px1 + 2)):
            m.floor(px0, py0, px1, py1, f + 16, only_open=False)
            m.lift(px1 + 1, py0, px1 + 1, py0, f, f + 16, 2, 8)
            for (x, y) in ((px0, py0), (px0 + 1, py0 + 1)):
                m.g[y][x] = rng.choice("uq*j") if (x, y) == (px0, py0) else "("
            m.light(px0 + 2, py0 + 2, 5, 140, *L2, 2)
    # monsters: the stretch's kinds, more in a bigger room; turrets in arenas and towers
    if not is_start:
        n = 1 + (W * H) // 110 + (1 if kind in ("arena", "tower") else 0)
        for _ in range(n):
            put_free(m, rng, b, rng.choice(th["mons"][min(z, 3)]))
        if kind in ("arena", "tower") or (is_exit and k >= 3):
            w = th["weapons"][min(z, 2)]
            held = kind == "arena"
            turrets = []
            for _ in range(2 if W * H > 300 else 1):
                c = put_wall_turret(m, rng, b, (14, 0, 100, 100, 0, w, rng.choice((0, 90, 240)), rng.choice((0, 12, 60)), 1 if held else 0))
                if c:
                    turrets.append(c)
            if held and turrets:  # (they come out when you walk in)
                m.triggers.append("enter %d %d %d %d : turret at %d %d %d eject" % (x0, y0, x1, y1, int(cx), int(cy), max(W, H)))
        if kind == "arena" and k >= 2:
            m.event(1, x0, y0, x1, y1, 3 + z, 0, rng.choice((9, 10, 13)))  # (an ambush: it locks round you)
    # pickups: a little of what you need
    for ch in rng.sample("+aae{u", 2 if W * H < 300 else 4):
        put_free(m, rng, b, ch)


def put_wall_turret(m, rng, b, mons):
    x0, y0, x1, y1 = b
    cells = [(x, y0) for x in range(x0 + 2, x1 - 1)] + [(x, y1) for x in range(x0 + 2, x1 - 1)] \
        + [(x0, y) for y in range(y0 + 2, y1 - 1)] + [(x1, y) for y in range(y0 + 2, y1 - 1)]
    cells = [c for c in cells if m.g[c[1]][c[0]] == "." and not near_way(m, c, b, 3)]
    if not cells:
        return None
    c = rng.choice(cells)
    m.g[c[1]][c[0]] = "|"
    m.mons[c] = mons
    return c


def finish_sector(m, rng, k, info):
    """The campaign's dressers - closets, windows, lasers, plates, a hoard, a
    data station, teleporters - a stash, and the ammo split"""
    import lvlkit
    import newsectors as ns
    camp = ns.camp
    st, dist = camp._reach(m)
    for fn, args in ((camp.dress_closets, (3, "cmk")), (camp.dress_windows, (6,)), (camp.dress_lasers, (2,)),
                     (camp.dress_plates, (2,))):
        try:
            fn(m, rng, args[0], dist, *args[1:])
        except Exception as e:
            print("  (dresser %s: %s)" % (fn.__name__, e))
        st, dist = camp._reach(m)
    if k >= 3:
        try:
            camp.dress_hoard(m, rng, dist, 2)
        except Exception as e:
            print("  (hoard: %s)" % e)
        st, dist = camp._reach(m)
    try:
        camp.dress_station(m, rng, dist)
    except Exception as e:
        print("  (station: %s)" % e)
    for _ in range(2):
        camp.dress_teleport(m, rng)
    st, dist = camp._reach(m)
    try:
        camp.dress_terminal(m, rng, dist, k)
    except Exception as e:
        print("  (terminal: %s)" % e)
    camp.dress_hints(m)
    if not lvlkit.carve_stash(m, rng.choice(("ua", "q+", "je", "u*", "qa"))):
        print("  (no room for a stash)")
    fix_pockets(m)
    m.headroom(8)


def fix_pockets(m, most=40):
    """What the dressers dig out of the rock - a stash behind a secret wall,
    a monster closet - is at floor 0: raised to the floor of the room it
    opens onto (past its secret or closet wall, or its door)"""
    import lvlkit
    N = len(m.g)
    solid = lambda x, y: m.g[y][x] in lvlkit.WALLS or m.g[y][x] in "?%/\\@$;="
    seen = set()
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if (x, y) in seen or solid(x, y) or m.fh[y][x] != "." or m.g[y][x] in "<>^v":
                continue
            comp, q = [], [(x, y)]
            seen.add((x, y))
            while q and len(comp) <= most:
                c = q.pop()
                comp.append(c)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    a, b = c[0] + dx, c[1] + dy
                    if (a, b) not in seen and not solid(a, b) and m.fh[b][a] == ".":
                        seen.add((a, b)); q.append((a, b))
            if len(comp) > most or any(m.g[b][a] in "<>^v" for a, b in comp):
                continue
            outside = {}
            for (a, b) in comp:  # (the floors just past its walls: the room it opens onto)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    for reach in (1, 2):
                        u, v = a + dx * reach, b + dy * reach
                        if not (0 <= u < N and 0 <= v < N) or (u, v) in comp:
                            break
                        if reach == 1 and m.g[v][u] not in "?%DHX" and solid(u, v):
                            break
                        if not solid(u, v) and m.fh[v][u] != ".":
                            e = lvlkit.hval(m.fh[v][u], 0)
                            outside[e] = outside.get(e, 0) + 1
                            break
            if outside:
                e = max(outside, key=outside.get)
                for (a, b) in comp:
                    m.fh[b][a] = lvlkit.hchar(e)
                    if lvlkit.hval(m.ch[b][a], 8) < e + 8:
                        m.ch[b][a] = lvlkit.hchar(e + 8, ceiling=True)


def one(k, write):
    import lvlkit
    lvlkit.N = SIZES[k]
    import newsectors as ns
    th = THEMES[k]
    for seed in range(1000 * k, 1000 * k + 40):
        got = build(k, seed)
        if not got:
            continue
        m, info = got
        rng = random.Random(seed + 7)
        finish_sector(m, rng, k, info)
        lv = m.level("level%d" % k, th["name"], th["walls"], th["floors"], th["ceils"])
        lv["droids"] = th["droids"]
        lv["cell_lights"] = list(m.cell_lights)
        lv["rows"] = lvlkit.split_ammo(lv["rows"], True, True)  # (each gun its own ammo: you may have them all by now)
        print("HUGE %d: %s - %d x %d, seed %d, %d districts" % (k, th["name"], lvlkit.N, lvlkit.N, seed, len(info["regions"])))
        good = lvlkit.check_level(lv, ASSETS)
        errs, warns = ns.reach_with_blocks(lv)
        for e in errs:
            print("  BLOCKED:", e)
        herrs, hwarns = lvlkit.check_heights(lv)
        for e in herrs:
            print("  HEIGHTS ERROR", e)
        if len(lv["lights"]) > 256 or len(lv["triggers"]) > 96 or len(lv["lifts"]) > 32:
            print("  TOO MANY lights/triggers/lifts", len(lv["lights"]), len(lv["triggers"]), len(lv["lifts"]))
            good = False
        for e in lv["events"]:  # (an ambush seals the doors in its room till it's clear: none inside it, or what it spawns there is shut away for good)
            if e[0] == 1 and any(lv["rows"][y][x] in "DHXRBY" for y in range(e[2] + 1, e[4]) for x in range(e[1] + 1, e[3])):
                print("  SEALED: a door inside the ambush room", e[1:5]); good = False
        dry = dry_reach(lv)
        if dry:
            print("  WET: only through lava, acid, poison or fire to:", " ".join(dry))
        good = good and not errs and not herrs and not dry
        if not good:
            print("  (seed %d no good - the next)" % seed)
            continue
        if write:
            os.makedirs(OUT, exist_ok=True)
            doc = ["HUGE SECTORS: %s, built by hugesectors.py (seed %d): %d districts, %d x %d cells." % (th["name"], seed, len(info["regions"]), lvlkit.N, lvlkit.N)]
            import lvldress
            lvldress.dress(lv)   # (the looks pass - lvldress.py)
            lvldress.write_dressed(os.path.join(OUT, "level%d.txt" % k), lv, doc)
            print("  wrote", os.path.join(OUT, "level%d.txt" % k))
        print("  GOOD")
        return True
    print("  PROBLEM: no seed worked")
    return False


if __name__ == "__main__":
    args = sys.argv[1:]
    write = "--write" in args
    if "--one" in args:
        k = int(args[args.index("--one") + 1])
        sys.exit(0 if one(k, write) else 1)
    which = [int(a) for a in args if a.isdigit()] or list(range(1, 11))
    ok = True
    for k in which:
        r = subprocess.run([sys.executable, os.path.abspath(__file__), "--one", str(k)] + (["--write"] if write else []), cwd=HERE)
        ok = ok and r.returncode == 0
    print("ALL GOOD" if ok else "PROBLEMS")
    sys.exit(0 if ok else 1)
