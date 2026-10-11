"""NEON-CASTER's levels, built with lvlkit.

    python3 levels.py            build every level and check it
    python3 levels.py -show      ...and print the maps
    python3 levels.py --write    build, check, and (if all is well) replace
                                 the Level1: .. Level4: DATA in neon-caster.bas
    python3 levels.py --check    just check the levels already in
                                 neon-caster.bas (e.g. after editing them
                                 there by hand)

--write overwrites the level DATA in the game, so a map edited by hand in
neon-caster.bas should be copied back here first (or only edited here).
"""
import os, sys
from lvlkit import Map, validate, parse_bas, check_level, N

PROBLEMS = []
HERE = os.path.dirname(os.path.abspath(__file__))
BAS = os.path.join(HERE, "..", "..", "neon-caster.bas")
ASSETS = os.path.join(HERE, "..")


def place(m, spec, allowed="."):
    """spec: list of (x, y, ch); each target must currently be `allowed`."""
    for x, y, c in spec:
        if m.get(x, y) not in allowed:
            print("MISPLACED %s at %d,%d: it's %r" % (c, x, y, m.get(x, y)))
            PROBLEMS.append(1)
            continue
        m.put(x, y, c)


# ============================================================ LEVEL 1
LEVEL1 = [
    r"################################################",
    r"################################################",
    r"###/.......................................+\###",
    r"##/..........................................\##",
    r"##..CCCCHCCCCCCCCCCCCCC..KKKKKKKKKYKKKKKKKKK..##",
    r"##..C/....e\C.......a.C..K.................K..##",
    r"##..C.......C.........C..Y..KKK......KKK...K..##",
    r"##..C...m...H.........C..K.oo...g.......m..K..##",
    r"##..C.......C.....g...H..Ka................K..##",
    r"##..C.+.....C...2.....C..KKKDKKKKKKDKKKKKDKK..##",
    r"##..C\...../C.........C..K......K......K...K..##",
    r"##..CCCCHCCCCCCCCCCCCCC..K......K...g..K.+.K..##",
    r"##..C...........aCCCCCC..K.K..K.K..K...Ke..K..##",
    r"##..C.m.....o....CCCCCC..KtK..K.D..K...K...Y..##",
    r"##..C............CCCCCC..K..m...K..K...K...K..##",
    r"##..C...C....C...CCCCCC..K......K......K.m.K..##",
    r"##..H.....y......CCCCCC..K......K......K...K..##",
    r"##..C............CCCCCC..KKKKKKKKKKDKKKKKKKK..##",
    r"##..C...C....C...CNNNNNXNNNNNNK............K..##",
    r"##..C..e.........CNN/......\NNK.........b..K..##",
    r"##..C..........h.CN/..a...p.\NK..h...3.....K..##",
    r"##..C............CN..N....N..NK............K..##",
    r"##..CCCCCCHCCCCCCCN..........NKKKKKKKKYKKKKK..##",
    r"##................X..........X................##",
    r"##................N.>........N..............e.##",
    r"##..PPPPPPRPPPPPPPN..........NGGGGGGBGGGGGGG..##",
    r"##..PP/.........aPN..N....N..Na............G..##",
    r"##..P/...........PN\.p.....+/N.i..e........G..##",
    r"##..P..m.........PNN\....../NN.g...........G..##",
    r"##..P....P..P....PNNNNNXNNNNNN...G.....G...G..##",
    r"##..R............EP.........aG...........g.G..##",
    r"##..P.........g..PP..........G......s......G..##",
    r"##..P.........../PP..........G.............G..##",
    r"##..P........../PPP..........G.............G..##",
    r"##..PPPPHPPPPPPPPPP..........G...G..r..G...B..##",
    r"##..P............PP..........G.............G..##",
    r"##..P.+u.........PP..........B.............G..##",
    r"##..P............PP...m......G....../\.....G..##",
    r"##..P....P..P....PP..........G......\/.....G..##",
    r"##..P............PP..........G...G.....G...G..##",
    r"##..P.h...c.c....PP........g.G......h......G..##",
    r"##..P...e......m.PP..........G.m...........G..##",
    r"##..P............PP+.........G............+G..##",
    r"##..PPPPPPPPRPPPPPPPPPPPPHPPPGGGGGGGBGGGGGGG..##",
    r"##\........................................../##",
    r"###\a......................................a/###",
    r"################################################",
    r"################################################",
]


def level1():
    """NEON STATION: the first map (drawn by hand)."""
    m = Map()
    m.g = [list(r) for r in LEVEL1]
    m.zones = [(19, 19, 28, 28, 2, 1, 0), (5, 5, 21, 21, 3, 2, 0),
               (26, 5, 42, 21, 2, 2, 0), (30, 26, 42, 42, 4, 2, 0),
               (30, 30, 42, 42, 2, 0, 3)]  # lab: plates across its lower-right half
    return m


# ============================================================ LEVEL 2
def level2():
    """REACTOR CORE: octagonal reactor hall, diamond core; storage west,
    coolant wing east (red), control room north (yellow, exit), armoury
    south-east (blue)."""
    m = Map("#")
    # reactor hall: octagon x15..32, y15..32, corners cut 5; coil core
    m.octagon(15, 15, 32, 32, 5)
    m.pillar(24, 24, 3, "N")
    m.paint(13, 13, 34, 34, "N")
    # storage (west) x3..13, y3..33
    m.octagon(3, 3, 13, 33, 2)
    m.paint(2, 2, 13, 34, "C")
    # coolant wing (east) x34..45, y3..33, with pipe pillars
    m.octagon(34, 3, 45, 33, 2)
    m.paint(34, 2, 46, 34, "P")
    for y in (8, 14, 20, 26):
        m.pillar(38, y, 1, "P")
        m.pillar(42, y + 3, 1, "P")
    # control room (north) x15..32, y3..13
    m.octagon(15, 3, 32, 13, 3)
    m.paint(14, 2, 33, 14, "K")
    for x in (19, 28):
        m.rect(x, 7, x, 9, "K")
    # south hall x3..37, y35..45, and armoury x39..45, y35..45
    m.rect(3, 35, 37, 45)
    m.octagon(39, 35, 45, 45, 2)
    m.paint(2, 34, 46, 46, "G")
    for x in (10, 16, 22, 28, 34):
        m.rect(x, 39, x, 40, "G")
    m.rect(24, 34, 24, 34)                  # (the hall's south wall is 2 thick)
    # doors
    place(m, [(24, 33, "X"), (14, 24, "D"), (33, 24, "R"), (24, 14, "Y"),
              (8, 34, "H"), (38, 40, "B")], "#NCKPG")
    place(m, [(24, 2, "E")], "#NCKPG")
    # the start, things
    place(m, [(24, 43, "^")])
    place(m, [  # south hall: a gentle start
        (6, 37, "a"), (31, 37, "e"), (13, 43, "+"), (19, 37, "i"), (29, 37, "i"),
        (5, 44, "o"), (6, 44, "o"), (36, 44, "o"),
        (12, 37, "m"), (32, 42, "m"), (20, 43, "c"), (26, 43, "c"),
        # reactor hall: gunners around the core, hazard all over
        (20, 18, "g"), (28, 30, "g"), (18, 26, "m"), (30, 20, "m"),
        (24, 17, "a"), (24, 31, "+"), (17, 22, "o"), (31, 26, "o"),
        # storage: crates of barrels, crawler nest, red key
        (5, 6, "r"), (10, 5, "o"), (11, 5, "o"), (10, 6, "o"), (5, 12, "o"),
        (6, 12, "o"), (11, 20, "o"), (11, 21, "o"), (4, 28, "o"),
        (6, 18, "c"), (9, 18, "c"), (7, 24, "c"), (10, 28, "h"),
        (8, 9, "e"), (4, 31, "+"), (12, 31, "u"),
        # coolant wing: sentries guard the yellow and blue keys
        (40, 5, "y"), (43, 30, "b"), (36, 6, "s"), (44, 12, "s"), (36, 30, "s"),
        (40, 23, "g"), (43, 17, "m"), (36, 17, "o"), (36, 18, "o"), (44, 24, "o"),
        (37, 11, "a"), (44, 32, "e"),
        # control room: the exit, terminals, a heavy
        (17, 5, "t"), (30, 5, "t"), (21, 12, "t"), (27, 12, "t"),
        (24, 8, "h"), (18, 11, "g"), (30, 11, "g"), (24, 4, "+"),
        # armoury (blue): the railgun
        (42, 40, "4"), (40, 37, "u"), (44, 43, "*"), (41, 43, "a"),
    ])
    # floors: 1 glow grating, 2 scorched plates, 3 hazard tiles, 4 plates
    # ceilings: 1 vents, 2 warning lights
    m.zone(15, 15, 32, 32, 1, 2)            # reactor hall glows
    m.zone(15, 15, 22, 22, 3, 0, 1)         # hazard tiles in its four corners,
    m.zone(25, 15, 32, 22, 3, 0, 2)         # cut on the diagonal
    m.zone(25, 25, 32, 32, 3, 0, 3)
    m.zone(15, 25, 22, 32, 3, 0, 4)
    m.zone(3, 3, 13, 33, 2, 1)              # storage: scorched
    m.zone(34, 3, 45, 33, 4, 1)             # coolant: plates
    m.zone(34, 3, 45, 14, 1, 0, 2)          # ...glowing in its top-right corner
    m.zone(15, 3, 32, 13, 4, 2)             # control room
    m.zone(3, 35, 45, 45, 2, 1)             # south hall
    m.zone(39, 35, 45, 45, 3, 2)            # armoury
    return m


# ============================================================ LEVEL 3
def level3():
    """UNDERCITY: a sewer tunnel running corner to corner at 45 degrees, with
    a channel of murky water down its middle; rooms off both sides."""
    m = Map("#")
    # the tunnel: |X - Y| <= 3
    m.carve(3, 3, 45, 45, d1=-3, d2=3)
    m.paint(1, 1, 46, 46, "C")
    # top-right rooms
    m.rect(12, 3, 22, 7)                      # R1 store (x12..22, y3..7)
    m.rect(8, 5, 11, 5)                       # its passage
    m.octagon(26, 3, 45, 14, 3)               # R2 pump hall
    m.rect(13, 10, 25, 10)                    # passage from the tunnel
    m.octagon(34, 18, 45, 28, 2)              # R3 cistern
    m.rect(40, 15, 40, 17)                    # R2 -> R3
    m.rect(27, 24, 33, 24)                    # tunnel -> R3
    # bottom-left rooms
    m.rect(3, 12, 7, 22)                      # L1 nest
    m.rect(8, 13, 10, 13)
    m.octagon(3, 26, 14, 45, 2)               # L2 flooded hall
    m.rect(15, 28, 25, 28)
    m.octagon(18, 34, 28, 45, 2)              # L3 outflow (exit)
    m.rect(29, 38, 35, 38)
    # walls per area
    m.paint(23, 1, 46, 15, "P")
    m.paint(33, 16, 46, 29, "G")
    m.paint(1, 25, 15, 46, "K")
    m.paint(17, 33, 29, 46, "N")
    m.paint(11, 1, 23, 8, "#")
    # pump hall machinery: pillars of pipes
    for x in (31, 36, 41):
        m.pillar(x, 8, 1, "P")
    # cistern: a big round sump in the middle
    m.pillar(40, 23, 2, "G")
    # flooded hall: two rows of brick piers
    for y in (31, 36, 41):
        m.rect(6, y, 6, y, "#")
        m.rect(11, y, 11, y, "#")
    # doors
    place(m, [(10, 5, "D"), (8, 13, "D"), (20, 10, "R"), (40, 16, "H"),
              (31, 24, "D"), (20, 28, "B"), (31, 38, "Y")], ".")
    place(m, [(23, 46, "E")], "#NCKPG")
    place(m, [(5, 5, ">")])
    place(m, [
        # the tunnel: crawlers and drones, lamps, a few barrels
        (9, 9, "c"), (14, 13, "c"), (17, 18, "c"), (22, 21, "m"), (27, 28, "c"),
        (30, 31, "m"), (35, 34, "c"), (38, 40, "c"), (41, 42, "m"), (43, 44, "c"),
        (9, 11, "i"), (18, 16, "i"), (24, 22, "i"), (31, 33, "i"), (40, 38, "i"),
        (13, 15, "o"), (25, 23, "o"), (36, 37, "o"), (43, 41, "+"), (19, 17, "a"),
        # R1 store
        (14, 4, "u"), (21, 6, "a"), (18, 5, "e"), (16, 6, "o"), (20, 4, "g"),
        # L1 nest: the red key, crawlers
        (5, 21, "r"), (4, 15, "c"), (6, 17, "c"), (4, 19, "c"), (6, 20, "c"), (5, 14, "+"),
        # R2 pump hall (red): the yellow key, gunners, a sentry, terminals
        (43, 5, "y"), (28, 6, "g"), (38, 12, "g"), (44, 10, "s"), (34, 5, "h"),
        (27, 12, "t"), (33, 12, "t"), (29, 5, "o"), (30, 5, "o"), (42, 12, "a"),
        # R3 cistern: the blue key, drones
        (44, 27, "b"), (35, 19, "m"), (44, 19, "m"), (36, 27, "g"), (35, 23, "e"),
        # L2 flooded hall (blue): armour, big medkit, heavies
        (4, 44, "*"), (13, 44, "u"), (8, 33, "h"), (9, 42, "h"), (4, 27, "a"),
        (13, 28, "e"), (8, 38, "p"),
        # L3 outflow (yellow): the exit, a last fight
        (20, 36, "h"), (27, 36, "g"), (24, 41, "s"), (19, 44, "+"), (28, 43, "a"),
    ])
    # floors: 1 cobbles, 2 murky water, 3 rusty grate, 4 concrete
    # ceilings: 1 dark stone, 2 pipes
    m.zone(2, 3, 44, 45, 2, 0, 2)    # murky water: X - Y > -1 ...
    m.zone(3, 2, 45, 44, 1, 0, 2)    # ...cobbles again past X - Y > 1
    m.zone(12, 3, 22, 7, 4, 2)       # R1
    m.zone(26, 3, 45, 14, 3, 2)      # R2
    m.zone(34, 18, 45, 28, 2, 1)     # R3: the sump room is all water
    m.zone(3, 12, 7, 22, 4, 1)       # L1
    m.zone(3, 26, 14, 45, 2, 1)      # L2: flooded...
    m.zone(3, 26, 14, 37, 4, 0, 1)   # ...except a dry corner, cut on the diagonal
    m.zone(18, 34, 28, 45, 3, 2)     # L3
    return m


# ============================================================ LEVEL 4
def level4():
    """CRYO LAB: a diamond atrium, four octagonal labs in the corners, and a
    ring of halls. SW lab (open) has red, NW (red) blue, SE (blue) yellow,
    NE (yellow) the exit."""
    m = Map("#")
    m.diamond(24, 24, 12)                     # atrium
    m.pillar(24, 24, 2, "N")                  # terminal core
    m.paint(10, 10, 38, 38, "K")
    for (x0, y0) in ((3, 3), (33, 3), (3, 33), (33, 33)):
        m.octagon(x0, y0, x0 + 12, y0 + 12, 3)
    m.rect(18, 3, 30, 7)                      # north hall
    m.rect(18, 41, 30, 45)                    # south hall
    m.rect(3, 18, 7, 30)                      # west hall
    m.rect(41, 18, 45, 30)                    # east hall
    # corridors: hall <-> atrium vertices, hall <-> labs
    m.rect(24, 8, 24, 12)
    m.rect(24, 36, 24, 40)
    m.rect(8, 24, 12, 24)
    m.rect(36, 24, 40, 24)
    m.rect(16, 7, 17, 7); m.rect(31, 7, 32, 7)
    m.rect(16, 41, 17, 41); m.rect(31, 41, 32, 41)
    m.rect(7, 16, 7, 17); m.rect(7, 31, 7, 32)
    m.rect(41, 16, 41, 17); m.rect(41, 31, 41, 32)
    # walls per area: labs white, NE lab cryo glass, SE lab ice, halls tiles
    m.paint(0, 0, 47, 47, "#")
    m.paint(15, 1, 33, 9, "K"); m.paint(15, 39, 33, 47, "K")
    m.paint(1, 15, 9, 33, "K"); m.paint(39, 15, 47, 33, "K")
    m.paint(11, 11, 37, 37, "C")
    m.paint(22, 22, 26, 26, "N")
    m.paint(32, 1, 47, 16, "P")
    m.paint(32, 32, 47, 47, "G")
    # NE lab: rows of cryo pods; SE lab: ice blocks
    for x in (37, 41):
        for y in (7, 11):
            m.rect(x, y, x, y, "P")
    m.pillar(39, 39, 2, "G")
    # doors
    place(m, [(24, 10, "X"), (24, 38, "X"), (10, 24, "X"), (38, 24, "X"),
              (17, 7, "R"), (7, 17, "R"),      # NW lab
              (31, 7, "Y"), (41, 17, "Y"),     # NE lab
              (31, 41, "B"), (41, 31, "B"),    # SE lab
              (17, 41, "D"), (7, 31, "D")], ".")  # SW lab
    place(m, [(39, 2, "E")], "#NCKPG")
    place(m, [(24, 43, "^")])
    place(m, [
        # south hall
        (20, 42, "i"), (28, 42, "i"), (19, 44, "a"), (29, 44, "e"), (22, 42, "m"),
        # atrium: plants, a big fight round the core
        (24, 15, "p"), (15, 24, "p"), (33, 24, "p"), (24, 33, "p"),
        (20, 20, "g"), (28, 28, "g"), (28, 20, "h"), (20, 28, "s"), (24, 30, "m"),
        (18, 24, "c"), (30, 24, "c"), (24, 18, "+"), (25, 31, "a"),
        # SW lab (open): red key
        (6, 42, "r"), (5, 36, "g"), (12, 39, "m"), (9, 44, "c"), (13, 44, "c"),
        (4, 40, "t"), (11, 35, "t"), (13, 41, "+"), (8, 36, "e"),
        # west hall
        (4, 20, "i"), (6, 28, "i"), (4, 24, "g"), (5, 29, "a"),
        # NW lab (red): blue key
        (5, 5, "b"), (9, 8, "h"), (12, 5, "s"), (6, 12, "g"), (4, 9, "t"), (13, 13, "t"),
        (12, 11, "u"), (8, 13, "a"),
        # north hall
        (20, 4, "i"), (28, 6, "i"), (22, 6, "m"), (27, 4, "c"), (19, 6, "e"),
        # SE lab (blue): yellow key, ice
        (43, 42, "y"), (36, 35, "h"), (44, 36, "s"), (35, 44, "g"), (37, 42, "c"),
        (43, 40, "*"), (35, 37, "a"),
        # east hall
        (44, 20, "i"), (42, 28, "i"), (44, 25, "g"), (42, 21, "+"),
        # NE lab (yellow): the exit, cryo pods, the last guard
        (39, 5, "h"), (35, 9, "s"), (44, 9, "s"), (39, 13, "g"), (34, 13, "t"),
        (44, 13, "t"), (36, 4, "+"), (42, 4, "a"),
    ])
    # floors: 1 white tiles, 2 frosted grate, 3 cracked ice, 4 lab tiles
    # ceilings: 1 light panels, 2 frosty vents
    m.zone(2, 2, 45, 45, 2, 2)                # halls: grate, vents
    m.zone(12, 12, 36, 36, 1, 1)              # atrium: white tiles...
    m.zone(16, 16, 32, 32, 4, 0)              # ...a diamond of lab tiles inside
    m.zone(16, 16, 23, 23, 1, 0, 1)           #    (white again in the corners,
    m.zone(25, 16, 32, 23, 1, 0, 2)           #     cut on the diagonal)
    m.zone(25, 25, 32, 32, 1, 0, 3)
    m.zone(16, 25, 23, 32, 1, 0, 4)
    m.zone(3, 3, 15, 15, 4, 1)                # NW lab
    m.zone(33, 3, 45, 15, 1, 1)               # NE lab
    m.zone(3, 33, 15, 45, 4, 1)               # SW lab
    m.zone(33, 33, 45, 45, 3, 2)              # SE lab: ice
    return m


LEVELS = [
    (level1, "SECTOR 1: NEON STATION",
     ["wall.png", "wall2.png", "wall-concrete.png", "wall-servers.png", "wall-pipes.png", "wall-biolab.png"],
     ["floor.png", "floor-plates.png", "floor-concrete.png", "floor-lab.png"],
     ["ceiling.png", "ceiling-lights.png"],
     ["Level 1: the station. Exit: behind the red doors, in the pipe room."]),
    (level2, "SECTOR 2: REACTOR CORE",
     ["wall-reactor.png", "wall-coils.png", "wall-rusty.png", "wall-control.png", "wall-hazard.png", "wall-stripes.png"],
     ["floor-glow.png", "floor-scorched.png", "floor-hazard.png", "floor-plates.png"],
     ["ceiling-vents.png", "ceiling-warning.png"],
     ["Level 2: the reactor. Red key in the storage bay (west), yellow and",
      "blue in the coolant wing (east, red door); the exit is in the control",
      "room (north, yellow door); the armoury (south-east, blue) has the railgun."]),
    (level3, "SECTOR 3: UNDERCITY",
     ["wall-brick.png", "wall-graffiti.png", "wall-moss.png", "wall-grate.png", "wall-greenpipes.png", "wall-slime.png"],
     ["floor-cobbles.png", "floor-murky.png", "floor-rustgrate.png", "floor-concrete.png"],
     ["ceiling-stone.png", "ceiling-pipes.png"],
     ["Level 3: the sewers - one long tunnel at 45 degrees with water down its",
      "middle. Red key in the nest (left), yellow in the pump hall (red door),",
      "blue in the cistern; the exit is in the outflow (yellow door)."]),
    (level4, "SECTOR 4: CRYO LAB",
     ["wall-white.png", "wall-terminals.png", "wall-frost.png", "wall-tiles.png", "wall-cryo.png", "wall-ice.png"],
     ["floor-white.png", "floor-frostgrate.png", "floor-ice.png", "floor-lab.png"],
     ["ceiling-lights.png", "ceiling-frost.png"],
     ["Level 4: the lab. A diamond atrium and four labs: SW (open) has the",
      "red key, NW (red) blue, SE (blue) yellow, and NE (yellow) the exit."]),
]

def main():
    args = sys.argv[1:]
    ok = True
    if "--check" in args:
        for lv in parse_bas(BAS):
            if "-show" in args:
                print("\n=== %s" % lv["name"])
                Map.from_rows(lv["rows"]).show()
            ok &= check_level(lv, ASSETS)
        return 0 if ok else 1

    out = []
    for i, (fn, name, walls, floors, ceils, comment) in enumerate(LEVELS, 1):
        m = fn()
        if "-show" in args:
            print("\n=== LEVEL %d: %s" % (i, name))
            m.show()
        lv = dict(label="Level%d" % i, name=name, walls=walls, floors=floors,
                  ceils=ceils, zones=m.zones, rows=m.rows())
        ok &= check_level(lv, ASSETS)
        out.append("Level%d:" % i)
        out += m.data(name, walls, floors, ceils, comment)
        out.append("")
    ok &= not PROBLEMS
    if "--write" in args:
        if not ok:
            print("not writing: fix the problems above first")
            return 1
        src = open(BAS).read()
        a, b = src.index("\nLevel1:") + 1, src.index("\nSUB LoadTex") + 1
        open(BAS, "w").write(src[:a] + "\n".join(out) + "\n" + src[b:])
        print("wrote %d levels into %s" % (len(LEVELS), os.path.normpath(BAS)))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
