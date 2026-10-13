"""NEON-CASTER's levels, built with lvlkit.

    python3 levels.py            build every level and check it
    python3 levels.py -show      ...and print the maps
    python3 levels.py --write    build, check, and (if all is well) write
                                 level1.txt .. level10.txt here - the files
                                 the game loads
    python3 levels.py --check    just check the level files as they are
                                 (e.g. after editing one by hand, or in the
                                 game's editor)

--write overwrites the level files, so a level edited by hand or in the
editor is lost - copy what you changed back into its builder here first
(or stop using --write for that level).
"""
import os, sys
from lvlkit import Map, validate, parse_bas, check_level, N, write_level_file, level_files
from collections import deque

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


def near(m, spec, radius=3):
    """Like place, but each thing goes on the nearest free floor cell to
    (x, y) - for scattering props and monsters without counting cells."""
    for x, y, c in spec:
        best = None
        for r in range(radius + 1):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if max(abs(dx), abs(dy)) != r:
                        continue
                    a, b = x + dx, y + dy
                    if 0 < a < N - 1 and 0 < b < N - 1 and m.get(a, b) == ".":
                        best = (a, b)
                        break
                if best: break
            if best: break
        if best:
            m.put(best[0], best[1], c)
        else:
            print("NO ROOM for %s near %d,%d" % (c, x, y))
            PROBLEMS.append(1)


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
    place(m, [(19, 5, "M")])                    # the map: in the concrete room
    m.event(1, 5, 5, 11, 10, 5, 1, 9)           # ambush: 5 drones in the little room, armour
    # light: a cool station, purple in the hub, flickering corridors
    m.ambient = (165, 225, 220, 255)
    m.light(23.5, 23.5, 6, 130, 210, 120, 255)        # the hub: neon purple
    m.light(10.5, 2.5, 5, 150, 220, 230, 255, 1)      # outer corridor tubes,
    m.light(35.5, 2.5, 5, 150, 220, 230, 255, 1)      #   flickering
    m.light(2.5, 24.5, 5, 140, 220, 230, 255, 1)
    m.light(24.5, 45.5, 5, 160, 220, 230, 255, 5)     #   one nearly dead
    m.light(44.5, 24.5, 5, 140, 220, 230, 255, 0)
    m.light(8.5, 7.5, 5, 130, 255, 215, 170)          # concrete room: warm
    m.light(10.5, 16.5, 5, 110, 230, 230, 255, 1)
    m.light(34.5, 5.5, 6, 140, 110, 220, 255, 2)      # server hall: pulsing cyan
    m.light(30.5, 14.5, 5, 110, 110, 220, 255, 2)
    m.light(36.5, 30.5, 7, 150, 130, 255, 160)        # biolab: green
    m.light(36.5, 33.5, 4, 170, 255, 50, 50, 3)       #   red alarm by the red key
    m.light(10.5, 30.5, 5, 150, 255, 160, 80, 4)      # pipe rooms: firelight
    m.light(10.5, 39.5, 5, 130, 255, 160, 80, 4)
    # heights: the hub is a sunken atrium - terraces two eighths a step,
    # down to the middle, half a wall below the doors, under a ceiling two
    # and a half walls up
    m.floor(21, 21, 26, 26, -2)
    m.floor(22, 22, 25, 25, -4)
    m.ceiling(19, 19, 28, 28, 20)
    m.light(23.5, 23.5, 4, 120, 120, 255, 230, 2)     #   cyan in the pit
    # ...and the bio-lab has a mezzanine: a walkway a wall up along its east
    # wall, past the windows, an elevator up to it; loot and a sniper on it
    m.floor(41, 26, 42, 33, 8)
    m.lift(40, 26, 40, 26, 0, 8)
    m.ceiling(30, 26, 42, 42, 24)
    place(m, [(42, 26, "q"), (42, 32, "e"), (41, 27, "g")])
    m.light(41.5, 29.5, 5, 140, 120, 255, 200)
    m.headroom()
    m.heights_done = True
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
        (12, 37, "m"), (32, 42, "m"), (9, 43, "c"), (36, 41, "c"),
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
    place(m, [(6, 9, "M")])                 # the map: in the storage bay
    m.event(3, 15, 25, 21, 31, 90, 90)      # the hazard corner (SW) is live: on 1.5 s, off 1.5 s
    m.event(4, 15, 3, 32, 13, 25, 0, 13)    # control room: smash its terminals in 25 s, overcharge
    # light: dim and orange, the core throbbing, alarms in the hall
    m.ambient = (115, 255, 190, 150)
    for (lx, ly) in ((24, 19.5), (24, 28.5), (19.5, 24), (28.5, 24)):
        m.light(lx, ly, 7, 190, 255, 140, 50, 2)      # the reactor core's glow, all round it
    m.light(24.5, 8.5, 6, 150, 255, 230, 150)         # control room
    m.light(17.5, 11.5, 3, 180, 255, 50, 40, 3)       #   an alarm
    m.light(40.5, 10.5, 6, 130, 120, 220, 255)        # coolant wing: cyan
    m.light(40.5, 25.5, 6, 130, 120, 220, 255, 1)
    m.light(8.5, 15.5, 6, 120, 230, 230, 255, 5)      # storage: a dying tube
    m.light(8.5, 28.5, 5, 120, 255, 220, 170)
    m.light(6.5, 37.5, 4, 200, 255, 40, 30, 3)        # south hall alarms
    m.light(33.5, 37.5, 4, 200, 255, 40, 30, 3)
    m.light(20.5, 42.5, 8, 110, 255, 150, 70, 4)
    m.light(42.5, 40.5, 5, 170, 240, 240, 255)        # armoury
    # heights: the control room is a raised deck - its back half half a
    # wall up, a step across the room - the exit at the back of the deck
    m.floor(15, 3, 32, 8, 4)
    m.floor(24, 2, 24, 2, 4)  # (the exit door, at the deck's height)
    m.floor(15, 9, 32, 9, 2)
    m.ceiling(15, 3, 32, 13, 16)
    # ...the reactor hall sinks round the core in a bowl, two steps down,
    # under a ceiling three walls up
    for y in range(15, 33):
        for x in range(15, 33):
            d = abs(x - 24) + abs(y - 24)
            if d <= 7: m.floor(x, y, x, y, -4)
            elif d <= 9: m.floor(x, y, x, y, -2)
    m.ceiling(15, 15, 32, 32, 24)
    # ...and a walkway a wall up runs the length of the south hall's south
    # wall, stairs at its west end: loot along it, a sniper at the far end
    m.stairs(3, 44, 37, 45, "E", 2, 8)
    m.ceiling(3, 35, 37, 45, 20)
    place(m, [(20, 45, "a"), (30, 45, "e"), (35, 45, "g")])
    m.light(18.5, 44.5, 5, 130, 255, 150, 70, 4)
    m.headroom()
    m.heights_done = True
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
    place(m, [(13, 6, "M")])         # the map: in the store
    near(m, [(4, 13, "S"), (6, 22, "S")])
    m.event(5, 3, 12, 7, 22, 4, 150, 14)   # the nest: crawlers from two spawners, damage amp
    # light: murky green; the lamps along the tunnel glow by themselves
    m.ambient = (80, 170, 230, 190)
    m.light(12.5, 12.5, 5, 120, 120, 255, 140, 2)     # slime glow in the channel
    m.light(36.5, 36.5, 5, 120, 120, 255, 140, 2)
    m.light(17.5, 5.5, 5, 140, 255, 210, 150, 1)      # store
    m.light(35.5, 10.5, 8, 140, 200, 255, 200)        # pump hall
    m.light(43.5, 6.5, 3, 190, 255, 50, 40, 3)        #   an alarm by the yellow key
    m.light(37.5, 26.5, 6, 130, 120, 230, 255, 2)     # cistern
    m.light(5.5, 17.5, 4, 110, 255, 80, 60, 4)        # the nest: red, creepy
    m.light(8.5, 35.5, 7, 120, 140, 220, 255, 5)      # flooded hall: a dying light
    m.light(23.5, 40.5, 6, 160, 230, 230, 255, 1)     # outflow
    # heights: the tunnel is low (seven eighths), the water channel down
    # its middle two eighths down - you wade in it, and climb out anywhere
    rooms = [(12, 3, 22, 7), (26, 3, 45, 14), (34, 18, 45, 28), (3, 12, 7, 22), (3, 26, 14, 45), (18, 34, 28, 45)]
    inroom = lambda x, y: any(a <= x <= c and b <= y <= d for a, b, c, d in rooms)
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if abs(x - y) <= 3 and not inroom(x, y) and m.g[y][x] not in "#NCKPG":
                m.ceiling(x, y, x, y, 7, only_raise=False)
                if x - y in (0, 1):
                    m.floor(x, y, x, y, -2)
    # ...the pump hall's north end is a raised gantry, a step up from the
    # pillars, under a high roof
    m.floor(26, 3, 45, 5, 4)
    m.floor(26, 6, 45, 6, 2)
    m.ceiling(26, 3, 45, 14, 18)
    # ...the cistern is a flooded pit half a wall deep, a step down inside
    # each of its doors
    m.floor(34, 18, 45, 28, -4)
    m.floor(40, 18, 40, 18, -2)
    m.floor(34, 24, 34, 24, -2)
    m.ceiling(34, 18, 45, 28, 16)
    # ...and the flooded hall sinks from its dry corner, terrace by terrace
    for y in range(26, 46):
        for x in range(3, 14 if y < 30 else 15):  # (its east column stays dry by the way out, along row 28)
            k = (x - 3) + (y - 26)
            if k >= 13: m.floor(x, y, x, y, -4)
            elif k >= 12: m.floor(x, y, x, y, -2)
    m.ceiling(3, 26, 14, 45, 16)
    m.light(36.5, 21.5, 5, 140, 120, 255, 160, 2)     # the cistern glows under water
    m.headroom(7)
    m.min_room = 7  # (the tunnels stay low)
    m.heights_done = True
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
    place(m, [(6, 38, "M")])                  # the map: in the SW lab
    m.event(1, 33, 33, 45, 45, 8, 0, 13)      # SE lab: an ambush, 8 of a mix, overcharge
    # light: cold and bright, the atrium's core pulsing
    m.ambient = (175, 200, 225, 255)
    m.light(24, 28.5, 7, 160, 120, 230, 255, 2)       # atrium, round the core
    m.light(24, 19.5, 7, 160, 120, 230, 255, 2)
    m.light(9.5, 9.5, 6, 150, 240, 240, 255)          # NW lab
    m.light(39.5, 9.5, 6, 150, 120, 230, 255)         # NE lab: cryo cyan
    m.light(9.5, 39.5, 6, 150, 240, 240, 255, 1)      # SW lab: flickering
    m.light(36.5, 42.5, 6, 150, 140, 180, 255, 2)     # SE lab: icy blue
    m.light(24.5, 5.5, 5, 140, 230, 240, 255, 1)      # halls
    m.light(24.5, 43.5, 5, 140, 230, 240, 255)
    m.light(5.5, 24.5, 4, 180, 255, 50, 40, 3)        #   an alarm in the west hall
    m.light(43.5, 24.5, 5, 140, 230, 240, 255, 5)
    # heights: an observation deck rings the atrium's terminal core a wall
    # up (an elevator on its north side), under a ceiling three walls high
    for y in range(12, 37):
        for x in range(12, 37):
            if abs(x - 24) + abs(y - 24) <= 6:
                m.floor(x, y, x, y, 8)
    m.lift(24, 17, 24, 17, 0, 8)
    m.ceiling(12, 12, 36, 36, 24)
    m.light(24.5, 19.5, 4, 150, 200, 240, 255)
    # ...and each lab is split-level: a raised end half a wall up, a step
    # between (NW: its north end, the blue key up there; NE: its north-east
    # corner by the exit; SW: its south-west corner, the map up there), and
    # the SE ice lab sunk in two terraces
    m.floor(3, 3, 15, 5, 4); m.floor(3, 6, 15, 6, 2)
    m.floor(40, 3, 45, 9, 4); m.floor(39, 3, 39, 10, 2); m.floor(40, 10, 45, 10, 2)
    m.floor(3, 37, 8, 45, 4); m.floor(9, 36, 9, 45, 2); m.floor(3, 36, 8, 36, 2)
    m.floor(33, 33, 45, 45, -2); m.floor(35, 35, 43, 43, -4)
    for (a, b) in ((3, 3), (32, 3), (3, 33), (32, 33)):
        m.ceiling(a, b, a + 13, b + 12, 16)
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 5
def level5():
    """FOUNDRY: one long smelting hall, a channel of molten metal down its
    middle and furnaces standing in it; three workshops north, three
    south. Casting room (NW) has red; ore store (NE, red) yellow; crusher
    (S, yellow) blue; the exit is in the loading bay (SE, blue)."""
    m = Map("#")
    m.rect(6, 19, 41, 28)                       # the smelting hall
    for x in (12, 20, 28, 36):                  # furnaces standing in it
        m.rect(x, 20, x + 1, 21, "#")
        m.rect(x, 26, x + 1, 27, "#")
    for i, x0 in enumerate((3, 18, 33)):        # workshops north and south
        m.octagon(x0, 3, x0 + 11, 14, 3)
        m.octagon(x0, 33, x0 + 11, 44, 3)
    for x in (9, 24, 39):                       # corridors to them
        m.rect(x, 15, x, 18)
        m.rect(x, 29, x, 32)
    m.paint(0, 0, 47, 47, "N")                  # girders round the outside
    m.paint(5, 18, 42, 29, "#")                 # furnace brick round the hall
    m.paint(2, 2, 15, 15, "P"); m.paint(32, 2, 45, 15, "C")
    m.paint(17, 32, 30, 45, "K"); m.paint(32, 32, 45, 45, "G")
    m.pillar(24, 9, 2, "C")                     # pattern shop: a casting mould
    for (x, y) in ((22, 37), (26, 37), (22, 41), (26, 41)):
        m.rect(x, y, x, y, "K")                 # crusher: its rams
    place(m, [(9, 16, "D"), (24, 16, "D"), (39, 16, "R"),
              (9, 31, "D"), (24, 31, "Y"), (39, 31, "B")], ".")
    place(m, [(45, 38, "E")], "#NCKPG")
    place(m, [(9, 41, "^")])
    place(m, [
        # loading start (SW)
        (5, 36, "a"), (13, 36, "e"), (12, 42, "+"), (4, 41, "o"), (5, 42, "o"), (11, 38, "m"),
        # the hall: gunners on the far side of the channel, crawlers in the heat
        (8, 22, "g"), (17, 25, "c"), (24, 22, "h"), (31, 25, "c"), (39, 22, "g"), (33, 27, "m"),
        (16, 21, "o"), (32, 21, "o"), (17, 27, "o"), (25, 27, "o"), (40, 26, "i"), (7, 26, "i"),
        (10, 27, "+"), (38, 20, "a"), (24, 25, "e"),
        # casting room (NW): the red key
        (6, 6, "r"), (12, 5, "g"), (5, 12, "c"), (13, 12, "c"), (8, 9, "t"), (12, 9, "e"), (9, 6, "M"),
        # pattern shop (N): the scatter gun, a heavy
        (24, 5, "2"), (20, 12, "h"), (28, 12, "m"), (19, 6, "a"), (29, 6, "+"), (21, 9, "o"), (27, 9, "o"),
        # ore store (NE, red): the yellow key, sentries
        (42, 5, "y"), (35, 5, "s"), (43, 12, "s"), (36, 12, "g"), (39, 9, "o"), (40, 9, "o"), (35, 9, "u"),
        # crusher (S, yellow): the blue key, a pack
        (24, 43, "b"), (20, 35, "c"), (28, 35, "c"), (21, 42, "m"), (27, 42, "m"), (24, 39, "h"), (19, 39, "a"),
        # loading bay (SE, blue): the exit, the last guard
        (42, 35, "*"), (36, 40, "h"), (42, 42, "g"), (35, 35, "s"), (37, 43, "+"), (43, 40, "t"),
    ])
    near(m, [(5, 4, "x"), (6, 4, "x"), (30, 4, "x"), (43, 13, "f"), (35, 13, "f"),
             (13, 20, "f"), (33, 22, "x"), (41, 44, "x"), (34, 44, "x"), (19, 44, "f"),
             (14, 24, "k"), (30, 24, "k"), (21, 6, "k"), (40, 37, "k"), (6, 39, "x")])
    # floors: 1 molten grate, 2 scorched, 3 hazard, 4 plates; ceilings: 1 girders, 2 vents
    m.zone(2, 2, 45, 45, 4, 1)
    m.zone(6, 19, 41, 28, 2, 1)
    m.zone(8, 23, 39, 24, 1, 2)                 # the molten channel
    m.event(3, 8, 23, 39, 24, 60, 120)          # ...live: cross while it's off
    m.event(4, 18, 3, 29, 14, 20, 0, 10)        # pattern shop: smash it all in 20 s, big medkit
    m.zone(3, 3, 14, 14, 3, 2); m.zone(33, 3, 44, 14, 3, 2)
    m.zone(18, 33, 29, 44, 3, 1)
    # light: hot and orange, the channel glowing, furnaces flickering
    m.ambient = (120, 255, 190, 150)
    for x in (10.5, 18.5, 26.5, 34.5):
        m.light(x, 23.5, 6, 200, 255, 120, 40, 4)
    m.light(9.5, 9.5, 6, 140, 255, 170, 90, 4)
    m.light(24.5, 4.5, 6, 140, 255, 230, 170)
    m.light(39.5, 9.5, 6, 140, 230, 230, 255, 1)
    m.light(24.5, 39.5, 6, 150, 255, 220, 120, 2)
    m.light(39.5, 39.5, 6, 140, 255, 230, 170)
    m.light(43.5, 36.5, 3, 190, 255, 50, 40, 3)
    m.light(9.5, 38.5, 6, 140, 255, 220, 170, 1)
    # heights: the smelting hall is tall (four walls), and its molten
    # metal runs in a trough two eighths down - it burns (FloorHazard) -
    # with three plate bridges across it; the hall's east end is a pouring
    # floor a wall up: stairs at its west edge, lifts by the north and south
    # doors, and the loot alcove behind the east door up there with it
    m.ceiling(6, 19, 41, 28, 32)
    m.floor(8, 23, 32, 24, -2)
    for bx in (14, 24):
        m.floor(bx, 23, bx, 24, 0)
        m.zone(bx, 23, bx, 24, 4, 0)
    m.floor(33, 19, 41, 28, 8)
    m.zone(33, 23, 41, 24, 4, 0)
    m.floor(42, 20, 45, 21, 8); m.floor(43, 19, 45, 19, 8)
    m.ceiling(42, 19, 45, 21, 16)
    m.stairs(29, 19, 32, 19, "E", 2, 8)
    m.stairs(29, 25, 32, 25, "E", 2, 8)
    m.lift(39, 19, 39, 19, 0, 8)
    m.lift(39, 28, 39, 28, 0, 8)
    for (a, b, c, d) in ((2, 2, 15, 15), (32, 2, 45, 15), (2, 32, 15, 45), (17, 32, 30, 45), (32, 32, 45, 45), (17, 2, 30, 15)):
        m.ceiling(a, b, c, d, 16)
    m.light(20.5, 23.5, 6, 170, 255, 120, 40, 4)      # the trough glows
    m.light(37.5, 25.5, 5, 140, 255, 200, 140)        # the pouring floor
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 6
def level6():
    """HYDROPONICS: a three by three grid of greenhouse bays, rows of plants
    in each, a dome in the middle. Red key in the NW bay; the dome (red)
    has yellow; NE (yellow, by way of N) blue; the exit is in the E bay
    (blue)."""
    m = Map("#")
    xs = (3, 19, 35)
    for cx, x0 in enumerate(xs):
        for cy, y0 in enumerate(xs):
            if (cx, cy) == (1, 1):
                m.octagon(x0, y0, x0 + 9, y0 + 9, 3)      # the dome
            else:
                m.rect(x0, y0, x0 + 9, y0 + 9)
    def hlink(cx, cy):      # bay (cx, cy) to the one east of it
        x0 = xs[cx] + 10; y = xs[cy] + 4
        m.rect(x0, y, x0 + 8, y)
        return x0 + 4, y
    def vlink(cx, cy):      # bay (cx, cy) to the one south of it
        y0 = xs[cy] + 10; x = xs[cx] + 4
        m.rect(x, y0, x, y0 + 8)
        return x, y0 + 4
    doors = []
    for (a, b, d) in (((0, 0), "v", "D"), ((0, 1), "v", "D"), ((0, 2), "h", "D"),
                      ((1, 2), "h", "D"), ((1, 1), "v", "R"), ((0, 1), "h", "R"),
                      ((0, 0), "h", "Y"), ((1, 0), "h", "D"), ((2, 1), "v", "B"),
                      ((2, 0), "v", "D")):
        x, y = hlink(*a) if b == "h" else vlink(*a)
        doors.append((x, y, d))
    m.paint(0, 0, 47, 47, "N")                  # vines outside
    for x0 in xs:
        for y0 in xs:
            m.paint(x0 - 1, y0 - 1, x0 + 10, y0 + 10, "#")   # greenhouse glass round the bays
    m.paint(18, 18, 29, 29, "C")                # the dome: biolab
    m.paint(34, 18, 45, 29, "K")                # the E bay: white lab
    place(m, doors, ".")
    place(m, [(45, 23, "E")], "#NCKPG")
    place(m, [(5, 42, ">")])
    # rows of plants in the outer bays (every other row, gaps to walk)
    for x0 in xs:
        for y0 in xs:
            if (x0, y0) in ((19, 19), (35, 19)):
                continue
            for y in (y0 + 2, y0 + 7):
                for x in (x0 + 2, x0 + 7):
                    if m.get(x, y) == "." and (x, y) != (5, 42):
                        m.put(x, y, "p")
    place(m, [
        (8, 39, "a"), (11, 44, "+"), (7, 44, "m"),                  # SW: start
        (5, 27, "c"), (11, 24, "c"), (8, 27, "g"), (4, 24, "e"),    # W
        (11, 4, "r"), (4, 7, "g"), (11, 11, "m"), (7, 5, "a"), (8, 10, "M"),   # NW: red key
        (24, 37, "h"), (23, 42, "c"), (27, 42, "c"), (23, 37, "+"), (27, 37, "3"),  # S
        (24, 21, "y"), (21, 25, "g"), (27, 25, "g"), (24, 27, "h"), (22, 21, "u"), (20, 23, "t"), (28, 23, "t"),  # dome
        (24, 4, "a"), (20, 9, "m"), (28, 4, "m"), (25, 11, "c"), (22, 8, "e"),   # N
        (42, 4, "b"), (36, 9, "s"), (43, 11, "h"), (40, 7, "+"),    # NE: blue key
        (40, 37, "g"), (39, 42, "c"), (43, 42, "m"), (44, 38, "e"), (36, 37, "a"),   # SE
        (44, 22, "h"), (36, 21, "s"), (42, 27, "g"), (37, 27, "*"), (38, 22, "t"), (43, 26, "t"),  # E: the exit
    ], ".")
    near(m, [(9, 24, "w"), (24, 9, "w"), (27, 36, "w"), (40, 40, "w"), (41, 24, "w"),
             (24, 23, "q"), (39, 5, "n"), (4, 11, "x"), (44, 19, "x"), (5, 36, "k")])
    near(m, [(37, 4, "S"), (43, 9, "S")])
    m.event(5, 35, 3, 44, 12, 7, 200, 13)       # NE bay: a spitter nest, overcharge
    m.event(2, 19, 19, 28, 28, 30, 90, 14)      # the dome: survive 30 s, damage amp
    # floors: 1 soil, 2 lab, 3 murky, 4 white; ceilings: 1 grow lights, 2 lights
    m.zone(2, 2, 45, 45, 2, 2)
    for x0 in xs:
        for y0 in xs:
            m.zone(x0, y0, x0 + 9, y0 + 9, 1, 1)
    m.zone(19, 19, 28, 28, 3, 1)                # the dome: a pond
    m.zone(35, 19, 44, 28, 4, 2)                # the E bay: a lab
    m.ambient = (125, 200, 255, 190)
    for x0 in xs:
        for y0 in xs:
            fx = 0 if (x0 + y0) % 3 else 2
            m.light(x0 + 5, y0 + 5, 7, 140, 210, 120, 255, fx)       # grow lights: purple
    m.light(24, 24, 6, 150, 120, 255, 150, 2)                       # the dome: green
    m.light(40, 24, 6, 150, 230, 240, 255, 1)
    # heights: each greenhouse bay's beds rise in terraces to its middle, a
    # step at a time (a stepped pyramid of planters you can climb), under a
    # high glass roof; the dome in the middle is a pool, sunk in two steps
    for bx in (3, 19, 35):
        for by in (3, 19, 35):
            if (bx, by) == (19, 19):
                continue
            for y in range(by, by + 10):
                for x in range(bx, bx + 10):
                    d = min(x - bx, bx + 9 - x, y - by, by + 9 - y)
                    if d >= 2:
                        m.floor(x, y, x, y, (d - 1) * 2)
            m.ceiling(bx, by, bx + 9, by + 9, 20)
    for y in range(19, 29):
        for x in range(19, 29):
            d = min(x - 19, 28 - x, y - 19, 28 - y)
            if d >= 1:
                m.floor(x, y, x, y, -2 if d < 3 else -4)
    m.ceiling(18, 18, 29, 29, 20)
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 7
def level7():
    """DATA VAULT: a great hall of server racks in rows, offices round its
    edge, the vault itself in the middle. Red key in the west offices;
    the north offices (red) have yellow; the east (yellow) blue; the vault
    (blue) has the exit."""
    m = Map("#")
    m.rect(9, 9, 38, 38)                        # the hall
    for y in range(11, 37, 4):                  # rows of racks, gaps to cross
        for x0 in (11, 26):
            m.rect(x0, y, x0 + 10, y, "C")
            m.put(x0 + 5, y, ".")
    m.rect(19, 19, 28, 28, "N")                 # the vault: a block in the middle...
    m.rect(20, 20, 27, 27)                      # ...hollow
    m.octagon(2, 12, 6, 35, 1)                  # offices: west,
    m.octagon(12, 2, 35, 6, 1)                  #   north,
    m.octagon(41, 12, 45, 35, 1)                #   east,
    m.octagon(12, 41, 35, 45, 1)                #   south
    for y in (14, 33):
        m.rect(7, y, 8, y); m.rect(39, y, 40, y)
    for x in (14, 33):
        m.rect(x, 7, x, 8); m.rect(x, 39, x, 40)
    m.rect(7, 24, 8, 24); m.rect(39, 24, 40, 24)
    m.rect(24, 7, 24, 8); m.rect(24, 39, 24, 40)
    m.paint(0, 0, 47, 47, "#")
    m.paint(8, 8, 39, 39, "G")                  # the hall: stripes
    m.paint(19, 19, 28, 28, "N")                # the vault: chrome
    m.paint(1, 11, 7, 36, "K"); m.paint(40, 11, 46, 36, "K")
    place(m, [(24, 19, "B")], "N")              # the vault's door
    place(m, [(7, 24, "D"), (8, 14, "D"), (8, 33, "D"),        # west offices: open
              (14, 8, "R"), (33, 8, "R"), (24, 8, "R"),        # north (red)
              (39, 14, "Y"), (39, 33, "Y"), (40, 24, "Y"),     # east (yellow)
              (14, 39, "D"), (33, 39, "D"), (24, 40, "D")], ".")  # south: open
    place(m, [(24, 27, "E")], ".")
    place(m, [(24, 43, "^")])
    place(m, [
        (16, 43, "a"), (31, 43, "+"), (19, 42, "m"), (29, 44, "m"), (13, 42, "e"),   # south offices
        # the hall: drones over the racks, gunners in the aisles
        (16, 13, "m"), (31, 17, "m"), (16, 25, "g"), (31, 29, "g"), (13, 33, "c"), (34, 21, "c"),
        (10, 21, "h"), (37, 33, "g"), (22, 35, "c"), (25, 17, "m"), (10, 36, "+"), (37, 10, "a"),
        (10, 10, "o"), (37, 37, "o"),
        # west offices: the red key
        (4, 30, "r"), (4, 14, "g"), (5, 20, "t"), (5, 27, "t"), (3, 24, "M"), (4, 33, "e"),
        # north offices (red): the yellow key, sentries
        (31, 4, "y"), (14, 4, "s"), (20, 3, "g"), (27, 5, "h"), (17, 5, "t"), (24, 3, "u"), (34, 5, "3"),
        # east offices (yellow): the blue key
        (43, 16, "b"), (43, 31, "s"), (42, 22, "h"), (44, 27, "g"), (42, 34, "*"), (43, 13, "a"),
        # the vault (blue): the exit, its guards
        (21, 22, "h"), (26, 22, "h"), (22, 26, "s"), (21, 25, "+"), (26, 26, "e"),
    ])
    near(m, [(10, 13, "l"), (37, 13, "l"), (10, 29, "l"), (37, 29, "l"), (23, 34, "l"),
             (25, 13, "l"), (12, 22, "k"), (35, 26, "k"), (24, 31, "k"), (17, 4, "k"),
             (3, 18, "j"), (44, 18, "n"), (20, 44, "x"), (28, 44, "x"), (4, 17, "x")])
    m.event(1, 20, 20, 27, 27, 6, 6, 13)        # the vault: 6 stalkers, overcharge
    # floors: 1 circuit, 2 glow, 3 plates, 4 lab; ceilings: 1 cables, 2 vents
    m.zone(2, 2, 45, 45, 4, 2)
    m.zone(9, 9, 38, 38, 1, 1)
    m.zone(20, 20, 27, 27, 2, 2)
    m.zone(12, 2, 35, 6, 3, 2); m.zone(12, 41, 35, 45, 3, 2)
    m.ambient = (90, 150, 200, 255)
    for (x, y) in ((16.5, 15.5), (31.5, 15.5), (16.5, 31.5), (31.5, 31.5)):
        m.light(x, y, 7, 150, 100, 220, 255, 2)                     # racks: cyan, pulsing
    m.light(23.5, 23.5, 5, 170, 255, 60, 200)                       # the vault: magenta
    m.light(4.5, 24.5, 6, 140, 230, 240, 255, 1)
    m.light(24.5, 4.5, 6, 140, 230, 240, 255)
    m.light(43.5, 24.5, 6, 140, 230, 240, 255, 5)
    m.light(24.5, 43.5, 6, 140, 230, 240, 255)
    m.light(14.5, 4.5, 3, 190, 255, 50, 40, 3)
    # heights: the server hall is a canyon - its aisles between the racks
    # three quarters of a wall down, the racks towering five walls up -
    # with a catwalk round its edge at the doors' height, and a flight of
    # stairs down from the middle of each side; the vault is down there too
    m.floor(11, 11, 36, 36, -6)
    m.stairs(11, 12, 13, 12, "W", -6, -2)
    m.stairs(34, 30, 36, 30, "E", -6, -2)
    m.stairs(23, 11, 23, 13, "N", -6, -2)
    m.stairs(24, 34, 24, 36, "S", -6, -2)
    m.ceiling(9, 9, 38, 38, 40)
    for (a, b, c, d) in ((9, 9, 38, 10), (9, 37, 38, 38), (9, 11, 10, 36), (37, 11, 38, 36)):
        m.zone(a, b, c, d, 3, 0)  # (the catwalk: plates)
    m.light(23.5, 12.5, 5, 140, 120, 220, 255, 2)
    m.light(12.5, 24.5, 5, 140, 120, 220, 255, 2)
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 8
def level8():
    """MAGLEV DEPOT: three long platforms one above the other, the track hall
    between them full of train cars, stairs at the ends. Red key at the far
    end of the north platform; the ticket hall (red) has yellow; the
    maintenance shed (yellow) blue; the control tower (blue) the exit."""
    m = Map("#")
    m.rect(3, 3, 44, 9)                         # north platform
    m.rect(3, 19, 44, 28)                       # the track hall
    m.rect(3, 38, 44, 44)                       # south platform
    for y in (21, 26):                          # train cars on the tracks
        for x0 in (8, 22, 35):
            m.rect(x0, y, x0 + 8, y + 1, "P")
    for x in (5, 42):                           # stairs between them
        m.rect(x, 10, x, 18); m.rect(x, 29, x, 37)
    m.rect(24, 10, 24, 18); m.rect(24, 29, 24, 37)
    m.octagon(13, 12, 20, 16, 1)                # ticket hall
    m.octagon(29, 31, 36, 35, 1)                # maintenance shed
    m.octagon(29, 12, 36, 16, 1)                # control tower
    m.rect(21, 14, 23, 14); m.rect(25, 14, 28, 14)
    m.rect(32, 29, 32, 30)                      # the shed opens off the track hall
    m.paint(0, 0, 47, 47, "#")
    m.paint(2, 2, 45, 10, "N"); m.paint(2, 37, 45, 45, "N")   # platforms: adverts
    m.paint(2, 18, 45, 29, "C"); m.paint(12, 11, 21, 17, "K"); m.paint(28, 30, 37, 36, "G")
    m.paint(28, 11, 37, 17, "#")
    place(m, [(5, 14, "D"), (42, 14, "D"), (24, 12, "D"), (5, 33, "D"), (42, 33, "D"),
              (24, 33, "D"), (21, 14, "R"), (32, 30, "Y"), (27, 14, "B")], ".")
    place(m, [(32, 11, "E")], "#NCKPG")
    place(m, [(4, 41, ">")])
    place(m, [
        # south platform: the start
        (10, 41, "a"), (18, 39, "m"), (30, 43, "g"), (38, 40, "c"), (44, 43, "+"), (14, 43, "e"),
        (8, 39, "i"), (20, 39, "i"), (32, 39, "i"), (40, 43, "i"),
        # the track hall: between the cars
        (6, 24, "g"), (18, 23, "c"), (30, 24, "h"), (44, 23, "m"), (12, 19, "m"), (40, 28, "c"),
        (20, 28, "o"), (33, 19, "o"), (4, 28, "+"), (44, 19, "a"), (26, 24, "3"),
        # north platform: the red key at its far end
        (43, 5, "r"), (12, 6, "g"), (20, 4, "c"), (31, 8, "m"), (38, 4, "h"), (8, 8, "e"),
        (10, 4, "i"), (22, 8, "i"), (34, 4, "i"), (3, 3, "M"),
        # ticket hall (red): the yellow key
        (17, 13, "y"), (14, 15, "s"), (19, 15, "g"), (16, 16, "u"), (14, 12, "t"),
        # maintenance shed (yellow): the blue key
        (33, 32, "b"), (35, 34, "h"), (30, 33, "s"), (34, 34, "*"), (31, 35, "o"), (32, 35, "o"),
        # control tower (blue): the exit
        (31, 14, "h"), (35, 15, "g"), (34, 12, "t"), (30, 16, "+"),
    ])
    near(m, [(13, 9, "n"), (30, 9, "n"), (13, 38, "n"), (36, 38, "n"), (44, 9, "x"),
             (3, 9, "x"), (44, 38, "x"), (16, 24, "k"), (32, 23, "k"), (28, 6, "w"),
             (16, 43, "w"), (36, 40, "k"), (35, 33, "q"), (31, 13, "j")])
    m.event(3, 3, 20, 44, 22, 45, 75)           # the north track's third rail is live
    m.event(1, 13, 12, 20, 16, 6, 0, 9)         # ticket hall: an ambush, armour
    # floors: 1 platform, 2 rust grate, 3 concrete, 4 cobbles; ceilings: 1 tunnel, 2 pipes
    m.zone(2, 2, 45, 45, 3, 2)
    m.zone(3, 3, 44, 9, 1, 1); m.zone(3, 38, 44, 44, 1, 1)
    m.zone(3, 19, 44, 28, 4, 1)
    m.zone(3, 20, 44, 22, 2, 1); m.zone(3, 25, 44, 27, 2, 1)   # the tracks
    m.ambient = (110, 220, 230, 255)
    for x in (9.5, 21.5, 33.5, 43.5):
        m.light(x, 6.5, 5, 140, 255, 240, 200, 1)
        m.light(x, 41.5, 5, 140, 255, 240, 200)
    for x in (6.5, 20.5, 33.5):
        m.light(x, 23.5, 6, 160, 255, 210, 60, 2)                   # the tracks: yellow
    m.light(16.5, 14.5, 4, 150, 255, 100, 200)
    m.light(32.5, 33.5, 4, 140, 255, 160, 80, 4)
    m.light(32.5, 14.5, 4, 170, 120, 220, 255, 2)
    # heights: both platforms have a gallery a wall up along their back
    # wall, stairs at each end - the gunners and spitters up there have the
    # drop on you - and the track beds in the hall are sunk a step, a
    # trench to duck into
    m.floor(3, 3, 44, 5, 8)
    m.stairs(3, 6, 4, 9, "N", 2, 8)
    m.stairs(43, 6, 44, 9, "N", 2, 8)
    m.floor(3, 42, 44, 44, 8)
    m.stairs(6, 38, 6, 41, "S", 2, 8)
    m.stairs(42, 38, 42, 41, "S", 2, 8)
    m.ceiling(3, 3, 44, 9, 22)
    m.ceiling(3, 38, 44, 44, 22)
    m.floor(3, 20, 44, 22, -2)
    m.floor(3, 25, 44, 27, -2)
    m.ceiling(3, 19, 44, 28, 16)
    place(m, [(20, 3, "w"), (30, 44, "g")])
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 9
def level9():
    """ORBITAL SPIRE: a ring round the station's core, windows onto space all
    round its outside; four pods off it, and the core in the middle. Red
    key in the south pod; the west pod (red) has yellow; the north pod
    (yellow) blue; the core (blue) has the exit."""
    m = Map("#")
    m.octagon(6, 6, 41, 41, 10)                 # the ring...
    m.solid(15, 15, 33, 33, s1=15 + 15 + 6, s2=33 + 33 - 6, d1=15 - 33 + 6, d2=33 - 15 - 6, wall="C")   # ...round the core
    m.octagon(19, 19, 28, 28, 3)                # the core room
    for (x0, y0, x1, y1) in ((20, 1, 27, 3), (20, 44, 27, 46), (1, 20, 3, 27), (44, 20, 46, 27)):
        m.rect(x0, y0, x1, y1)                  # pods N S W E
    m.paint(0, 0, 47, 47, "N")                  # windows onto space
    m.paint(14, 14, 33, 33, "#")                # the core's hull
    m.paint(18, 0, 29, 5, "K"); m.paint(18, 42, 29, 47, "K")
    m.paint(0, 18, 5, 29, "P"); m.paint(42, 18, 47, 29, "G")
    for (x, y) in ((24, 4), (24, 5), (24, 42), (24, 43), (4, 24), (5, 24), (42, 24), (43, 24)):
        m.put(x, y, ".")
    for (x, y) in ((24, 15), (24, 16), (24, 17), (24, 18)):
        m.put(x, y, ".")
    place(m, [(24, 5, "Y"), (24, 42, "D"), (5, 24, "R"), (42, 24, "D"), (24, 17, "B")], ".")
    place(m, [(24, 23, "E")], "N#CKPG.")
    m.rect(23, 23, 23, 23, "#"); m.rect(25, 23, 25, 23, "#")
    place(m, [(45, 24, "<")])                   # in the east pod, its door shut
    place(m, [
        # the ring: patrols all the way round
        (34, 36, "g"), (24, 40, "c"), (12, 35, "m"), (8, 24, "g"), (12, 12, "h"), (24, 8, "m"),
        (36, 11, "c"), (40, 18, "g"), (30, 40, "m"), (17, 40, "c"), (8, 30, "s"), (30, 9, "s"),
        (39, 33, "a"), (11, 33, "+"), (11, 15, "e"), (33, 11, "a"), (24, 39, "3"), (16, 8, "4"),
        (14, 37, "i"), (34, 37, "i"), (10, 14, "i"), (37, 14, "i"),
        # east pod: armour, the map
        (45, 21, "*"), (45, 26, "M"),
        # south pod: the red key
        (21, 45, "r"), (26, 45, "g"), (23, 44, "+"),
        # west pod (red): the yellow key
        (2, 21, "y"), (2, 26, "h"),
        # north pod (yellow): the blue key
        (26, 2, "b"), (21, 2, "s"), (23, 1, "u"),
        # the core (blue): the exit, its guardians
        (20, 25, "h"), (28, 25, "h"), (24, 27, "s"), (21, 21, "g"), (27, 21, "g"), (24, 26, "+"),
    ])
    near(m, [(20, 9, "f"), (28, 38, "f"), (9, 20, "f"), (38, 28, "f"), (13, 22, "k"),
             (34, 25, "k"), (24, 36, "w"), (14, 31, "w"), (33, 15, "k"), (26, 45, "x"),
             (2, 25, "j"), (45, 23, "x"), (22, 2, "q")])
    near(m, [(9, 18, "S"), (9, 29, "S")])
    m.event(5, 6, 15, 14, 32, 6, 180, 13)       # the west ring: a stalker nest, overcharge
    # floors: 1 deck, 2 white, 3 glow, 4 lab; ceilings: 1 hull, 2 lights
    m.zone(2, 2, 45, 45, 1, 1)
    m.zone(19, 19, 28, 28, 3, 2)
    for (x0, y0, x1, y1) in ((20, 1, 27, 3), (20, 44, 27, 46), (1, 20, 3, 27), (44, 20, 46, 27)):
        m.zone(x0, y0, x1, y1, 2, 2)
    m.ambient = (95, 180, 210, 255)
    for (x, y) in ((24.5, 9.5), (38.5, 24.5), (24.5, 38.5), (9.5, 24.5), (14.5, 14.5), (33.5, 14.5), (14.5, 33.5), (33.5, 33.5)):
        m.light(x, y, 6, 140, 170, 210, 255)                        # the ring: cold blue
    m.light(24.5, 24.5, 6, 180, 255, 255, 255, 2)                   # the core
    m.light(24.5, 2.5, 3, 150, 255, 220, 120)
    m.light(24.5, 45.5, 3, 150, 255, 220, 120, 1)
    m.light(2.5, 24.5, 3, 190, 255, 50, 40, 3)
    m.light(45.5, 24.5, 3, 150, 255, 220, 120)
    # heights: the ring round the core is an amphitheatre, stepping down in
    # tiers from its outer wall (where the pods' doors are) to the core,
    # which sits three quarters of a wall down at the bottom; and in two of
    # the ring's corners a sniper's ledge a wall up, each with an elevator
    oct_r = lambda x, y: max(abs(x - 23.5), abs(y - 23.5), (abs(x - 23.5) + abs(y - 23.5)) * 0.75)
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if 6 <= x <= 41 and 6 <= y <= 41:
                r = oct_r(x, y)
                m.floor(x, y, x, y, 0 if r >= 15 else -2 if r >= 13 else -4 if r >= 11 else -6)
    m.ceiling(6, 6, 41, 41, 24)
    for (bx0, by0, bx1, by1) in ((29, 6, 41, 14), (6, 33, 18, 41)):
        ledge = [(x, y) for y in range(by0, by1 + 1) for x in range(bx0, bx1 + 1)
                 if m.g[y][x] not in "#NCKPG/\\" and oct_r(x, y) >= 16.2]
        for (x, y) in ledge:
            m.floor(x, y, x, y, 8)
        ls = set(ledge)
        lift = next((x + dx, y + dy) for (x, y) in sorted(ledge) for dx, dy in STEPS
                    if (x + dx, y + dy) not in ls and m.g[y + dy][x + dx] == "." and m.floor_at(x + dx, y + dy) == 0)
        m.lift(lift[0], lift[1], lift[0], lift[1], 0, 8)
        near(m, [(ledge[len(ledge) // 2][0], ledge[len(ledge) // 2][1], "g")], 2)
    m.light(23.5, 21.5, 5, 160, 140, 220, 255, 2)
    m.headroom()
    m.heights_done = True
    return m


# ============================================================ LEVEL 10
def level10():
    """THE CORE: a square spiral winding in to the AI core - every turn
    tighter, every turn guarded. Red key on the second turn; blue on the
    third (red); the core (blue) is an arena where the overseer waits, and
    the way out is in its far wall."""
    m = Map("#")
    # rings of corridor, three wide, joined at one corner each so you spiral in
    rings = [(3, 44), (9, 38), (15, 32)]
    for (a, b) in rings:
        m.rect(a, a, b, a + 2); m.rect(a, b - 2, b, b)
        m.rect(a, a, a + 2, b); m.rect(b - 2, a, b, b)
    m.rect(20, 20, 27, 27)                      # the core room: an arena
    # the joins, through the walls between the rings (a door in each): ring
    # 1 to 2 bottom left, 2 to 3 on the right, 3 to the core on the left,
    # and from the core up to the way out
    m.rect(6, 38, 8, 38)
    m.rect(33, 24, 35, 24)
    m.rect(18, 24, 19, 24)
    m.paint(0, 0, 47, 47, "N")                  # obsidian outside
    m.paint(8, 8, 39, 39, "#")                  # glowing circuits further in
    m.paint(14, 14, 33, 33, "C")
    m.paint(19, 19, 28, 28, "K")
    place(m, [(7, 38, "D"), (34, 24, "R"), (19, 24, "B")], ".")
    place(m, [(24, 19, "E")], "#NCKPG")         # the way out: in the core's far wall
    place(m, [(40, 42, "<")])
    place(m, [
        # ring 1 (outer): the long way round
        (30, 42, "c"), (18, 43, "m"), (6, 42, "c"), (4, 30, "h"), (5, 15, "g"), (6, 5, "m"),
        (20, 4, "c"), (32, 5, "g"), (43, 6, "s"), (42, 20, "h"), (43, 32, "m"), (36, 43, "+"),
        (4, 40, "a"), (12, 4, "e"), (43, 12, "+"), (24, 43, "i"), (4, 24, "i"), (24, 4, "i"), (43, 24, "i"),
        (11, 43, "2"),
        # ring 2: the red key at its far corner, a pack on the way
        (10, 36, "c"), (10, 25, "g"), (11, 12, "h"), (24, 10, "m"), (36, 10, "r"), (37, 20, "g"),
        (36, 36, "c"), (24, 37, "s"), (10, 10, "u"), (37, 30, "a"), (10, 34, "M"),
        # ring 3 (red): the yellow key
        (16, 30, "h"), (17, 17, "g"), (30, 16, "s"), (30, 30, "b"), (24, 31, "m"), (16, 22, "c"),
        (31, 22, "*"), (17, 31, "+"),
        # the core (blue... reached by yellow first): blue key, the last stand
        (20, 27, "+"), (27, 27, "a"), (20, 20, "c"), (27, 20, "c"),  # (in the corners: the ring between is a pit)
    ])
    # the overseer, the last sector's boss, holds the core (its guards make room)
    place(m, [(24, 23, "z")])
    near(m, [(35, 42, "q"), (10, 40, "j"), (16, 26, "j"), (31, 25, "q"), (20, 42, "k"),
             (4, 10, "k"), (36, 4, "w"), (10, 30, "k"), (37, 16, "w"), (30, 31, "k"),
             (16, 16, "w"), (6, 43, "f"), (42, 4, "f"), (11, 37, "f")])
    m.event(1, 20, 20, 27, 27, 6, 0, 13)        # the arena seals: the overseer's guard teleports in
    m.zone(2, 2, 45, 45, 2, 2)
    m.zone(9, 9, 38, 38, 4, 2)
    m.zone(15, 15, 32, 32, 3, 1)
    m.zone(20, 20, 27, 27, 1, 1)
    m.ambient = (85, 255, 120, 120)
    for (x, y) in ((24.5, 43.5), (4.5, 24.5), (24.5, 4.5), (43.5, 24.5)):
        m.light(x, y, 7, 150, 255, 60, 60, 2)                       # red, throbbing
    for (x, y) in ((10.5, 24.5), (24.5, 10.5), (37.5, 24.5), (24.5, 37.5)):
        m.light(x, y, 6, 150, 255, 80, 120, 1)
    m.light(16.5, 16.5, 5, 170, 255, 40, 40, 3)
    m.light(31.5, 31.5, 5, 170, 255, 40, 40, 3)
    m.light(23.5, 23.5, 5, 220, 255, 120, 80, 2)                    # the core
    # heights: the spiral climbs as it winds in - each ring a step up from
    # the one outside it - to the core: an arena with a walkway round its
    # wall, then a ring of pit with no bottom (kick them in), four bridges
    # across, and the overseer's dais in the middle, half a wall up
    m.floor(9, 9, 38, 38, 2)
    m.floor(15, 15, 32, 32, 4)
    for y in range(20, 28):
        for x in range(20, 28):
            c = max(abs(x - 23.5), abs(y - 23.5))
            if c >= 3.5: m.floor(x, y, x, y, 4)
            elif c >= 2.5: m.floor(x, y, x, y, 6 if (x in (23, 24) or y in (23, 24)) else -8)
            else: m.floor(x, y, x, y, 8)
    m.ceiling(9, 9, 38, 38, 16)
    m.ceiling(15, 15, 32, 32, 22)
    m.ceiling(20, 20, 27, 27, 32)
    m.light(23.5, 23.5, 3, 200, 255, 60, 40, 2)       # the dais: red, throbbing
    m.headroom()
    m.heights_done = True
    return m

# ============================================================ DRESSING
# Every level gets dressed after it's built (dress, from LEVELS' table):
# set pieces against the walls of its rooms, monster closets (secret walls,
# %, that open as you walk past), traps (pressure plates on the way you
# must go, laser beams across corridors, a laser cutter sweeping a room),
# thief bots with a hoard vault carved into the rock, and power failures.
# Everything is placed by looking at the map - and after each change the
# level is checked again (every key and the exit still reachable), and
# the change taken back if it blocks the way.
import random
from lvlkit import WALLS, DOORS, DIAG, ITEMS, MONS, DECO, START, GLASS, STATION, PAD

STEPS = [(1, 0), (-1, 0), (0, 1), (0, -1)]
PASS = set(".~") | ITEMS | MONS | START | set("DHX") | PAD


def _ok(m):
    errs, _ = validate(m.rows(), "x")
    return not errs


def _reach(m):
    """Steps from the start to every cell you can walk to (keys and all)."""
    g = m.g
    st = [(x, y) for y in range(N) for x in range(N) if g[y][x] in START][0]
    dist = {st: 0}
    q = deque([st])
    while q:
        x, y = q.popleft()
        for dx, dy in STEPS:
            a, b = x + dx, y + dy
            if (a, b) not in dist and (g[b][a] in PASS or g[b][a] in "RBY"):
                dist[(a, b)] = dist[(x, y)] + 1
                q.append((a, b))
    return st, dist


def _count(m, chars):
    return sum(1 for r in m.g for c in r if c in chars)


def _near_door(m, x, y, r=1):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if 0 <= x + dx < N and 0 <= y + dy < N and m.g[y + dy][x + dx] in DOORS:
                return True
    return False


def _open_around(m, x, y):
    return sum(1 for dx, dy in STEPS if m.g[y + dy][x + dx] == ".")


def dress_props(m, rng, chars, n, dist):
    """Set pieces against the walls of rooms (a floor cell with a wall
    beside it, not in a corridor, not by a door), spread out."""
    cand = []
    for (x, y), d in dist.items():
        if m.g[y][x] != "." or _near_door(m, x, y, 1) or d < 4:
            continue
        walls = sum(1 for dx, dy in STEPS if m.g[y + dy][x + dx] in WALLS)
        # room edge: one wall beside it, open floor round the rest
        if walls == 1 and _open_around(m, x, y) == 3:
            cand.append((x, y))
    rng.shuffle(cand)
    placed = []
    for x, y in cand:
        if len(placed) >= n or _count(m, DECO) >= 62:
            break
        if any(abs(x - a) + abs(y - b) < 3 for a, b in placed):
            continue
        m.g[y][x] = rng.choice(chars)
        if _ok(m):
            placed.append((x, y))
        else:
            m.g[y][x] = "."
    return len(placed)


def _rock(m, x, y):
    return 0 < x < N - 1 and 0 < y < N - 1 and m.g[y][x] in WALLS


def dress_closets(m, rng, n, dist, mons):
    """Monster closets: a wall cell beside the floor with solid rock behind
    it (two cells deep, rock on both sides): the wall becomes %, the pocket
    a monster or two, and an event (6) in front of it springs it."""
    cand = []
    for (x, y), d in dist.items():
        if m.g[y][x] != "." or d < 8 or _near_door(m, x, y, 2):
            continue
        for dx, dy in STEPS:
            wx, wy = x + dx, y + dy
            px, py = dx and 1 or 0, dy and 1 or 0  # (the sideways direction)
            sx, sy = (0, 1) if dx else (1, 0)
            cells = [(wx + dx * k + sx * j, wy + dy * k + sy * j) for k in range(0, 4) for j in (-1, 0, 1)]
            if all(_rock(m, a, b) for a, b in cells) and m.g[wy][wx] in WALLS:
                cand.append((x, y, dx, dy))
    rng.shuffle(cand)
    made = []
    for x, y, dx, dy in cand:
        if len(made) >= n or len(m.events) >= 14 or _count(m, MONS) >= 60:
            break
        if any(abs(x - a) + abs(y - b) < 8 for a, b in made):
            continue
        wx, wy = x + dx, y + dy
        old = [(wx, wy, m.g[wy][wx]), (wx + dx, wy + dy, m.g[wy + dy][wx + dx]), (wx + 2 * dx, wy + 2 * dy, m.g[wy + 2 * dy][wx + 2 * dx])]
        m.g[wy][wx] = "%"
        m.g[wy + dy][wx + dx] = rng.choice(mons)
        m.g[wy + 2 * dy][wx + 2 * dx] = rng.choice(mons + ".")
        # the trigger: the floor in front of it, 4 deep and 5 wide
        if dx:
            x0, x1 = sorted((x, x - dx * 3)); y0, y1 = y - 2, y + 2
        else:
            y0, y1 = sorted((y, y - dy * 3)); x0, x1 = x - 2, x + 2
        x0, y0, x1, y1 = max(1, x0), max(1, y0), min(N - 2, x1), min(N - 2, y1)
        if _ok(m):
            m.event(6, x0, y0, x1, y1, 0, 0)
            made.append((x, y))
        else:
            for a, b, c in old:
                m.g[b][a] = c
    return len(made)


# What an observation room can hold: (its props along the back, what's
# in the middle, its light colour). Bodies (V) and chairs (Z) everywhere.
OBS_KINDS = {
    "control": ("FAF", "ZVZ", (90, 200, 255)),
    "office":  ("dFd", "ZV.", (230, 220, 190)),
    "lab":     ("IJI", "V.Z", (120, 255, 170)),
    "cell":    ("UVU", ".h.", (255, 90, 80)),
    "nest":    ("ISI", "c.c", (200, 120, 255)),
    "vault":   ("qaj", ".u.", (255, 210, 90)),
}


def dress_observation(m, rng, n, dist, kinds):
    """Observation rooms: a window of three panes of glass in a corridor's
    wall, looking into a small room carved out of solid rock behind it -
    sealed: furnished, dimly lit, with whoever didn't get out (or
    something that wants to). Shoot the glass to get in. The room is 5
    wide and 3 deep if the rock allows, else smaller."""
    cand = []
    for (x, y), d in dist.items():
        if m.g[y][x] != "." or d < 5 or _near_door(m, x, y, 2): continue
        for dx, dy in STEPS:
            sx, sy = (0, 1) if dx else (1, 0)
            stand = [(x + sx * j, y + sy * j) for j in (-1, 0, 1)]
            if not all(m.g[b][a] == "." for a, b in stand): continue
            for depth, half in ((3, 2), (2, 2), (2, 1)):
                # the window at k=1, the room at k=2..depth+1, rock all round
                rock = [(x + dx * k + sx * j, y + dy * k + sy * j) for k in range(1, depth + 3) for j in range(-half - 1, half + 2)]
                if all(_rock(m, a, b) for a, b in rock):
                    cand.append((-depth * half, rng.random(), x, y, dx, dy, depth, half))
                    break
    cand.sort()  # (the biggest rooms first)
    made = []
    for _, _, x, y, dx, dy, depth, half in cand:
        if len(made) >= n: break
        if any(abs(x - a) + abs(y - b) < 10 for a, b in made): continue
        sx, sy = (0, 1) if dx else (1, 0)
        kind = rng.choice(kinds)
        if _count(m, MONS) >= 60 and kind in ("cell", "nest"): kind = "office"
        back, mid, col = OBS_KINDS[kind]
        cell = lambda k, j: (x + dx * k + sx * j, y + dy * k + sy * j)
        old = {}
        for k in range(1, depth + 2):
            for j in range(-half, half + 1):
                a, b = cell(k, j)
                old[(a, b)] = m.g[b][a]
        for j in (-1, 0, 1):
            a, b = cell(1, j); m.g[b][a] = "="
        for k in range(2, depth + 2):
            for j in range(-half, half + 1):
                a, b = cell(k, j); m.g[b][a] = "."
        for j, c in zip((-1, 0, 1), back):  # along the back wall
            if c != ".":
                a, b = cell(depth + 1, j); m.g[b][a] = c
        if depth >= 3:  # and in the middle, if there's room
            for j, c in zip((-1, 0, 1), mid):
                if c != ".":
                    a, b = cell(3, j); m.g[b][a] = c
        else:  # (a small room: just its one main thing, beside the back)
            c = mid[1] if mid[1] != "." else mid[0]
            if c != "." and half >= 2:
                a, b = cell(depth + 1, 2); m.g[b][a] = c
        if _ok(m):
            lx, ly = cell(2, 0)
            m.light(lx + 0.5, ly + 0.5, 4, 110, col[0], col[1], col[2], rng.choice((0, 1, 5)))
            made.append((x, y))
        else:
            for (a, b), c in old.items():
                m.g[b][a] = c
    return len(made)


def dress_windows(m, rng, n, dist):
    """Windows between rooms: three panes of glass let into a wall one cell
    thick with floor on both sides - you see into the next room (and what's
    in it) before you find the way in. A chair or a body by it, sometimes."""
    cand = []
    for y in range(2, N - 2):
        for x in range(2, N - 2):
            for dx, dy in ((1, 0), (0, 1)):  # the wall runs along (dx, dy)
                nx, ny = dy, dx  # (across it)
                run = [(x + dx * j, y + dy * j) for j in (-2, -1, 0, 1, 2)]
                if not all(_rock(m, a, b) and m.g[b][a] in WALLS for a, b in run): continue
                mid = run[1:4]
                if not all(m.g[b + ny][a + nx] == "." and m.g[b - ny][a - nx] == "." for a, b in mid): continue
                if not all((a + nx, b + ny) in dist and (a - nx, b - ny) in dist for a, b in mid): continue
                if _near_door(m, x, y, 2): continue
                cand.append((x, y, dx, dy, nx, ny))
    rng.shuffle(cand)
    made = []
    for x, y, dx, dy, nx, ny in cand:
        if len(made) >= n: break
        if any(abs(x - a) + abs(y - b) < 9 for a, b in made): continue
        if any(e[1] - 1 <= x <= e[3] + 1 and e[2] - 1 <= y <= e[4] + 1 for e in m.events): continue
        old = [(x + dx * j, y + dy * j, m.g[y + dy * j][x + dx * j]) for j in (-1, 0, 1)]
        for a, b, _ in old: m.g[b][a] = "="
        extra = None
        if rng.random() < 0.7:  # a chair or a body, a step back from the glass on the far side
            side = rng.choice((1, -1))
            a, b = x + nx * 2 * side + dx * rng.choice((-1, 1)), y + ny * 2 * side + dy * rng.choice((-1, 1))
            if m.g[b][a] == "." and _count(m, DECO) < 62:
                extra = (a, b); m.g[b][a] = rng.choice("ZZV")
        if _ok(m):
            made.append((x, y))
        else:
            for a, b, c in old: m.g[b][a] = c
            if extra: m.g[extra[1]][extra[0]] = "."
    return len(made)


def dress_station(m, rng, dist):
    """A data station: a door on the way to the exit (seal it, and the
    exit can't be reached) - or else one that shuts off a good part of the
    level, loot behind it - becomes a sealed door (!), and a wall a few
    steps before it, on your side, becomes the station (@) that opens it."""
    doors = [(d, x, y) for (x, y), d in dist.items() if m.g[y][x] in "DHX" and d >= 6]
    rng.shuffle(doors)
    for want_critical in (True, False):
        for d, x, y in doors:
            was = m.g[y][x]
            m.g[y][x] = "#"
            critical = not _ok(m)
            _, before = _reach(m)  # (with the door shut: your side of it)
            m.g[y][x] = was
            if want_critical and not critical:
                continue
            if not want_critical and (critical or len(dist) - len(before) < 10):
                continue
            spots = []
            for (a, b), dd in before.items():
                if m.g[b][a] != "." or not (2 <= abs(a - x) + abs(b - y) <= 7) or _near_door(m, a, b, 1):
                    continue
                for dx, dy in STEPS:
                    wa, wb = a + dx, b + dy
                    if _rock(m, wa, wb) and not _near_door(m, wa, wb, 1):
                        spots.append((wa, wb))
            if not spots:
                continue
            wa, wb = rng.choice(spots)
            wall_was = m.g[wb][wa]
            m.g[y][x] = "!"
            m.g[wb][wa] = "@"
            if _ok(m):
                return 1
            m.g[y][x] = was
            m.g[wb][wa] = wall_was
    return 0


HUP = "0123456789abcdefghijklmnopqrstuvwxyz"


def dress_heights(m, rng, n_dais, n_ledge):
    """Heights: a raised dais in the middle of a big room (a ring of steps
    two eighths up, the middle four), its ceiling lifted; and a loot ledge -
    a block a whole wall high against a room's wall, too high to step onto,
    loot on top, an elevator beside it (and the room's ceiling raised
    over it all)."""
    made = 0
    rooms = []
    for y in range(2, N - 9):
        for x in range(2, N - 9):
            for w, h in ((7, 7), (6, 6), (7, 5), (5, 7), (5, 5)):
                cells = [(a, b) for b in range(y, y + h) for a in range(x, x + w)]
                if all(m.g[b][a] in ".mghcskwzr" + "b" + "y+ae23u*4Mqj" + "oiptxlnfdAFIJLOQUWZV" for a, b in cells):
                    if all(m.fh[b][a] == "." for a, b in cells) and not _near_door(m, x + w // 2, y + h // 2, 3):
                        if not any(e[1] <= x + w and x <= e[3] and e[2] <= y + h and y <= e[4] for e in m.events):
                            rooms.append((x, y, w, h)); break
    rng.shuffle(rooms)
    used = []
    for x, y, w, h in rooms:
        if made >= n_dais: break
        if any(abs(x - a) < 10 and abs(y - b) < 10 for a, b in used): continue
        for b in range(y, y + h):
            for a in range(x, x + w):
                ring = a in (x, x + w - 1) or b in (y, y + h - 1)
                m.fh[b][a] = "2" if ring else "4"
        for b in range(y - 1, y + h + 1):
            for a in range(x - 1, x + w + 1):
                if 0 < a < N - 1 and 0 < b < N - 1 and m.g[b][a] not in WALLS: m.ch[b][a] = "c"  # (1.5)
        used.append((x, y)); made += 1
    ledges = 0
    for x, y, w, h in rooms:
        if ledges >= n_ledge: break
        if any(abs(x - a) < 10 and abs(y - b) < 10 for a, b in used): continue
        # the ledge: the room's top-left 3 x 2, a wall high; the lift beside it
        lx, ly = x, y
        if any(m.g[b][a] != "." for b in range(ly, ly + 2) for a in range(lx, lx + 4)): continue
        for b in range(ly, ly + 2):
            for a in range(lx, lx + 3):
                m.fh[b][a] = "8"
        loot = rng.choice(("q*", "ju", "a4", "e3", "*u"))
        m.g[ly][lx] = loot[0]; m.g[ly][lx + 1] = loot[1]
        m.lifts.append((lx + 3, ly, lx + 3, ly, 0, 8, 2, 6))
        for b in range(y - 1, y + h + 1):
            for a in range(x - 1, x + w + 1):
                if 0 < a < N - 1 and 0 < b < N - 1 and m.g[b][a] not in WALLS: m.ch[b][a] = "k"  # (2.25)
        used.append((x, y)); ledges += 1
    return made, ledges


def dress_teleport(m, rng):
    """A pair of teleporter pads: two floor cells you can reach without a
    key, as far apart (in steps) as a few tries find - a shortcut, never
    round a locked door."""
    g = m.g
    st = [(x, y) for y in range(N) for x in range(N) if g[y][x] in START][0]
    dist = {st: 0}
    q = deque([st])
    while q:  # (no keys: only plain floor and plain doors)
        x, y = q.popleft()
        for dx, dy in STEPS:
            a, b = x + dx, y + dy
            if (a, b) not in dist and g[b][a] in (set(".") | ITEMS | MONS | START | set("DHX")):
                dist[(a, b)] = dist[(x, y)] + 1
                q.append((a, b))
    spots = [(x, y) for (x, y), d in dist.items() if g[y][x] == "." and d >= 4 and not _near_door(m, x, y, 2)
             and _open_around(m, x, y) == 4 and m.fh[y][x] == "."]
    if len(spots) < 2: return 0
    best = None
    for _ in range(60):
        a, b = rng.sample(spots, 2)
        d = abs(dist[a] - dist[b]) + abs(a[0] - b[0]) + abs(a[1] - b[1])
        if best is None or d > best[0]: best = (d, a, b)
    _, a, b = best
    g[a[1]][a[0]] = "&"; g[b[1]][b[0]] = "&"
    if _ok(m):
        return 1
    g[a[1]][a[0]] = "."; g[b[1]][b[0]] = "."
    return 0


def dress_hints(m):
    """A few triggers that tell you what you're looking at, the first time
    you're near: a data station, an elevator, a teleporter"""
    for y in range(1, N - 1):
        for x in range(1, N - 1):
            if m.g[y][x] == "@":
                for dx, dy in STEPS:
                    if m.g[y + dy][x + dx] == ".":
                        m.triggers.append("enter %d %d %d %d : message A DATA STATION - face it and press SPACE to jack in" % (x + dx - 1, y + dy - 1, x + dx + 1, y + dy + 1))
                        break
    for l in m.lifts:
        m.triggers.append("enter %d %d %d %d : message AN ELEVATOR - stand on it" % (l[0] - 1, l[1] - 1, l[2] + 1, l[3] + 1))
    pads = [(x, y) for y in range(N) for x in range(N) if m.g[y][x] == "&"]
    if pads:
        x, y = pads[0]
        m.triggers.append("enter %d %d %d %d : message A TELEPORTER - step on it" % (x - 1, y - 1, x + 1, y + 1))


PUZZLES = {1: "hello", 2: "multiply", 3: "countdown", 4: "password", 5: "sum",
           6: "pythagoras", 7: "select", 8: "function", 9: "reverse", 10: "wrap"}


def dress_terminal(m, rng, dist, lev):
    """A code terminal ($): a wall beside the floor of a room with a plain
    door within a few steps (its lockdown has something to lock), well into
    the level - and the puzzle it asks (PUZZLES, easy to hard)."""
    cand = []
    for (x, y), d in dist.items():
        if m.g[y][x] != "." or d < 6 or _near_door(m, x, y, 1): continue
        if not any(m.g[b][a] in "DHX" for b in range(max(0, y - 5), min(N, y + 6)) for a in range(max(0, x - 5), min(N, x + 6))): continue
        for dx, dy in STEPS:
            wx, wy = x + dx, y + dy
            if _rock(m, wx, wy) and not _near_door(m, wx, wy, 1) and not any(m.g[wy + b][wx + a] in "@$" for a in (-2, -1, 0, 1, 2) for b in (-2, -1, 0, 1, 2) if 0 <= wx + a < N and 0 <= wy + b < N):
                cand.append((wx, wy))
    rng.shuffle(cand)
    for wx, wy in cand:
        was = m.g[wy][wx]
        m.g[wy][wx] = "$"
        if _ok(m):
            m.puzzles = PUZZLES.get(lev, "hello")
            m.triggers.append("enter %d %d %d %d : message A CODE TERMINAL - face it and press SPACE" % (wx - 1, wy - 1, wx + 1, wy + 1))
            return 1
        m.g[wy][wx] = was
    return 0


def _runs(m, dist):
    """Corridor crossings: (x, y0, y1, "v") is a line of floor across a
    corridor running east-west (walls above and below it), 1-3 cells wide;
    and the same turned ("h")."""
    out = []
    for (x, y), d in dist.items():
        if m.g[y][x] not in ".": continue
        if m.g[y - 1][x] in WALLS:  # top of a vertical run
            y1 = y
            while m.g[y1 + 1][x] in "." and y1 - y < 4: y1 += 1
            if m.g[y1 + 1][x] in WALLS and y1 - y <= 2:
                # a corridor running east-west: floor either side along x
                if all(m.g[k][x - 1] in "." and m.g[k][x + 1] in "." for k in range(y, y1 + 1)):
                    out.append((x, y, x, y1, d))
        if m.g[y][x - 1] in WALLS:
            x1 = x
            while m.g[y][x1 + 1] in "." and x1 - x < 4: x1 += 1
            if m.g[y][x1 + 1] in WALLS and x1 - x <= 2:
                if all(m.g[y - 1][k] in "." and m.g[y + 1][k] in "." for k in range(x, x1 + 1)):
                    out.append((x, y, x1, y, d))
    return out


def dress_lasers(m, rng, n, dist):
    runs = [r for r in _runs(m, dist) if r[4] > 10 and not _near_door(m, r[0], r[1], 2)]
    rng.shuffle(runs)
    made = []
    for x0, y0, x1, y1, d in runs:
        if len(made) >= n or len(m.events) >= 15: break
        if any(abs(x0 - a) + abs(y0 - b) < 10 for a, b in made): continue
        on = rng.choice((60, 75, 90)); off = rng.choice((60, 75, 90))
        m.event(9, x0, y0, x1, y1, on, off)
        made.append((x0, y0))
    return len(made)


def dress_plates(m, rng, n, dist):
    """Pressure plates: on corridor floor, in the middle of a run"""
    runs = [r for r in _runs(m, dist) if r[4] > 6 and not _near_door(m, r[0], r[1], 2)]
    rng.shuffle(runs)
    made = []
    for x0, y0, x1, y1, d in runs:
        if len(made) >= n or len(m.events) >= 15: break
        x, y = (x0 + x1) // 2, (y0 + y1) // 2
        if any(abs(x - a) + abs(y - b) < 7 for a, b in made): continue
        if any(e[0] in (8, 9) and e[1] - 2 <= x <= e[3] + 2 and e[2] - 2 <= y <= e[4] + 2 for e in m.events): continue
        m.event(8, x, y, x, y, 45, 300)
        made.append((x, y))
    return len(made)


def dress_cutter(m, rng, dist):
    """A laser cutter: in an open rectangle of floor, 6 x 3 or more"""
    best = None
    for (x, y), d in dist.items():
        if d < 12: continue
        for w, h in ((7, 3), (3, 7), (6, 4), (4, 6), (6, 3), (3, 6)):
            if x + w >= N - 1 or y + h >= N - 1: continue
            cells = [m.g[b][a] for b in range(y, y + h) for a in range(x, x + w)]
            if all(c == "." for c in cells) and not _near_door(m, x + w // 2, y + h // 2, 3):
                best = (x, y, x + w - 1, y + h - 1); break
        if best and rng.random() < 0.15: break
    if best and len(m.events) < 15:
        m.event(10, best[0], best[1], best[2], best[3], rng.choice((150, 180, 220)), 0)
        return 1
    return 0


def dress_hoard(m, rng, dist, thieves):
    """A thieves' hoard: a vault carved into solid rock behind a door off
    a floor cell (as far from the start as can be found), stacked with
    loot; and thief bots out in the level."""
    cand = []
    for (x, y), d in dist.items():
        if m.g[y][x] != "." or d < 15 or _near_door(m, x, y, 2): continue
        for dx, dy in STEPS:
            sx, sy = (0, 1) if dx else (1, 0)
            # door at +1, vault 3 wide and 3 deep at +2..+4, rock round it all
            cells = [(x + dx * k + sx * j, y + dy * k + sy * j) for k in range(1, 6) for j in (-2, -1, 0, 1, 2)]
            if all(_rock(m, a, b) for a, b in cells):
                cand.append((d, x, y, dx, dy))
    if not cand: return 0
    cand.sort(reverse=True)
    d, x, y, dx, dy = cand[min(len(cand) - 1, rng.randrange(3))]
    sx, sy = (0, 1) if dx else (1, 0)
    m.g[y + dy][x + dx] = "D"
    vault = [(x + dx * k + sx * j, y + dy * k + sy * j) for k in (2, 3, 4) for j in (-1, 0, 1)]
    loot = list("qj*uaaee+") ; rng.shuffle(loot)
    for (a, b), c in zip(vault, loot):
        m.g[b][a] = c
    xs = [a for a, b in vault]; ys = [b for a, b in vault]
    m.event(7, min(xs), min(ys), max(xs), max(ys), 0, 0)
    # the thieves: out on the floor, well away from the start
    spots = [(a, b) for (a, b), dd in dist.items() if m.g[b][a] == "." and 10 < dd and not _near_door(m, a, b, 1)]
    rng.shuffle(spots)
    for a, b in spots[:thieves]:
        m.g[b][a] = "T"
    return 1


def dress_blackout(m, rng, dist, monsters):
    """A power failure: set off in a big open room, far from the start"""
    best = None
    for (x, y), d in sorted(dist.items(), key=lambda kv: -kv[1]):
        if d < 15: continue
        if all(m.g[b][a] == "." for b in range(y, y + 4) for a in range(x, x + 4) if 0 < a < N - 1 and 0 < b < N - 1):
            best = (x, y); break
    if best and len(m.events) < 16:
        m.event(11, best[0], best[1], best[0] + 3, best[1] + 3, 20, monsters)
        return 1
    return 0


# per level: set pieces (and how many), closets (and what's in them),
# lasers, plates, a cutter, thieves (0: no hoard), a power failure's
# monsters (0: none)
DRESS = {
    1:  ("dAUWFZ", 12, 2, "mc",  1, 2, 0, 1, 0, 3, ("control", "office", "office", "vault")),
    2:  ("LAFUZ",  12, 3, "gc",  2, 2, 1, 1, 0, 3, ("control", "cell", "vault")),
    3:  ("WULx",   10, 3, "cch", 2, 2, 0, 2, 5, 2, ("cell", "nest")),
    4:  ("OIJFQZ", 12, 3, "gk",  2, 2, 1, 2, 0, 4, ("lab", "lab", "nest", "control")),
    5:  ("LUxA",   10, 3, "hk",  2, 3, 1, 2, 0, 2, ("control", "cell")),
    6:  ("IJWQ",   10, 2, "wk",  1, 2, 0, 2, 6, 3, ("lab", "nest", "vault")),
    7:  ("FAdQZ",  12, 3, "kg",  2, 2, 1, 2, 0, 4, ("office", "control", "cell", "vault")),
    8:  ("WUnFdZ", 12, 3, "kwg", 2, 3, 0, 2, 6, 3, ("office", "cell", "vault")),
    9:  ("QAOdFZ", 12, 3, "kw",  2, 2, 1, 2, 0, 3, ("control", "lab", "cell")),
    10: ("LFAI",   10, 3, "kwh", 3, 3, 1, 2, 8, 3, ("control", "nest", "cell")),
}


def dress(m, lev):
    if lev not in DRESS: return
    props, nprops, nclos, cmons, nlas, nplate, ncut, nthief, nblack, nobs, obskinds = DRESS[lev]
    rng = random.Random(1000 + lev)
    keep = [(x, y) for (x0, y0, x1, y1, *_r) in m.lifts for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]
    for x, y in keep: m.g[y][x] = "~"  # (a lift: nothing goes on it - put back below)
    st, dist = _reach(m)
    got = [dress_hoard(m, rng, dist, nthief) if nthief else 0]
    st, dist = _reach(m)
    nobs_made = dress_observation(m, rng, nobs, dist, obskinds)
    st, dist = _reach(m)
    nobs_made += dress_windows(m, rng, 2 + max(0, nobs - nobs_made), dist)
    st, dist = _reach(m)
    got.append(dress_closets(m, rng, nclos, dist, cmons))
    st, dist = _reach(m)
    got.append(dress_props(m, rng, props, nprops, dist))
    st, dist = _reach(m)
    got.append(dress_lasers(m, rng, nlas, dist))
    got.append(dress_plates(m, rng, nplate, dist))
    got.append(dress_cutter(m, rng, dist) if ncut else 0)
    got.append(dress_blackout(m, rng, dist, nblack) if nblack else 0)
    st, dist = _reach(m)
    nst = dress_station(m, rng, dist)
    nda, nle = (0, 0) if getattr(m, "heights_done", False) else dress_heights(m, rng, 1 if lev >= 2 else 0, 1)
    ntp = dress_teleport(m, rng)
    st, dist = _reach(m)
    nterm = dress_terminal(m, rng, dist, lev)
    dress_hints(m)
    for x, y in keep: m.g[y][x] = "."
    level_rooms(m)
    m.headroom(getattr(m, "min_room", 8))
    print("   dressed L%d: hoard %d, closets %d, props %d, lasers %d, plates %d, cutter %d, blackout %d, windows %d, station %d, dais %d, ledge %d, teleport %d, terminal %d" % tuple([lev] + got + [nobs_made, nst, nda, nle, ntp, nterm]))


def level_rooms(m):
    """Rooms the dressing cut into the walls (a hoard, a closet) take the
    height of the floor outside their door - so one opening off a raised
    floor isn't a pit you can't climb out of."""
    for e in m.events:
        if e[0] not in (6, 7):
            continue
        kind, x0, y0, x1, y1 = e[:5]
        room = [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1) if m.g[y][x] not in WALLS]
        doors = {(x + dx, y + dy) for (x, y) in room for dx, dy in STEPS
                 if 0 < x + dx < N - 1 and 0 < y + dy < N - 1 and m.g[y + dy][x + dx] in "DHX" and not (x0 <= x + dx <= x1 and y0 <= y + dy <= y1)}
        for (dx_, dy_) in doors:
            outside = [(dx_ + a, dy_ + b) for a, b in STEPS if m.g[dy_ + b][dx_ + a] not in WALLS and not (x0 <= dx_ + a <= x1 and y0 <= dy_ + b <= y1)]
            if outside:
                e_out = m.floor_at(*outside[0])
                for (x, y) in room + [(dx_, dy_)]:
                    m.fh[y][x] = m.fh[outside[0][1]][outside[0][0]]
                break


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
    (level5, "SECTOR 5: FOUNDRY",
     ["wall-furnace.png", "wall-girders.png", "wall-rusty.png", "wall-hazard.png", "wall-pipes.png", "wall-stripes.png"],
     ["floor-molten.png", "floor-scorched.png", "floor-hazard.png", "floor-plates.png"],
     ["ceiling-girders.png", "ceiling-vents.png"],
     ["Level 5: the foundry. One long smelting hall with molten metal down its",
      "middle; red key in the casting room (NW), yellow in the ore store (NE,",
      "red door), blue in the crusher (S, yellow); the exit is in the loading",
      "bay (SE, blue)."]),
    (level6, "SECTOR 6: HYDROPONICS",
     ["wall-greenhouse.png", "wall-vines.png", "wall-biolab.png", "wall-white.png", "wall-moss.png", "wall-tiles.png"],
     ["floor-soil.png", "floor-lab.png", "floor-murky.png", "floor-white.png"],
     ["ceiling-growlights.png", "ceiling-lights.png"],
     ["Level 6: a grid of greenhouse bays. Red key in the NW bay; yellow in",
      "the dome (red doors); blue in the NE bay (yellow); exit in the E bay (blue)."]),
    (level7, "SECTOR 7: DATA VAULT",
     ["wall-datastream.png", "wall-vault.png", "wall-servers.png", "wall-terminals.png", "wall-control.png", "wall-stripes.png"],
     ["floor-circuit.png", "floor-glow.png", "floor-plates.png", "floor-lab.png"],
     ["ceiling-cables.png", "ceiling-vents.png"],
     ["Level 7: a hall of server racks, offices round it, the vault in the",
      "middle. Red key in the west offices; yellow north (red); blue east",
      "(yellow); the exit in the vault (blue)."]),
    (level8, "SECTOR 8: MAGLEV DEPOT",
     ["wall-transit.png", "wall-adverts.png", "wall-graffiti.png", "wall-concrete.png", "wall-brick.png", "wall-grate.png"],
     ["floor-platform.png", "floor-rustgrate.png", "floor-concrete.png", "floor-cobbles.png"],
     ["ceiling-tunnel.png", "ceiling-pipes.png"],
     ["Level 8: three platforms and the track hall between them. Red key at",
      "the far end of the north platform; yellow in the ticket hall (red);",
      "blue in the maintenance shed (yellow); exit in the control tower (blue)."]),
    (level9, "SECTOR 9: ORBITAL SPIRE",
     ["wall-hull.png", "wall-viewport.png", "wall-white.png", "wall-cryo.png", "wall-control.png", "wall-terminals.png"],
     ["floor-deck.png", "floor-white.png", "floor-glow.png", "floor-lab.png"],
     ["ceiling-hull.png", "ceiling-lights.png"],
     ["Level 9: a ring round the station's core, windows onto space. Red key",
      "in the south pod; yellow in the west pod (red); blue in the north pod",
      "(yellow); the exit in the core (blue)."]),
    (level10, "SECTOR 10: THE CORE",
     ["wall-core.png", "wall-obsidian.png", "wall-reactor.png", "wall-coils.png", "wall-servers.png", "wall-hazard.png"],
     ["floor-core.png", "floor-scorched.png", "floor-glow.png", "floor-hazard.png"],
     ["ceiling-core.png", "ceiling-warning.png"],
     ["Level 10: a square spiral in to the AI core. Red key on the second",
      "turn; blue on the third (red); the core (blue) is the overseer's arena,",
      "the exit in its far wall."]),
]

def main():
    args = sys.argv[1:]
    ok = True
    if "--check" in args:
        for lv in level_files(HERE):
            if "-show" in args:
                print("\n=== %s" % lv["name"])
                Map.from_rows(lv["rows"]).show()
            ok &= check_level(lv, ASSETS)
        return 0 if ok else 1

    out = []
    for i, (fn, name, walls, floors, ceils, comment) in enumerate(LEVELS, 1):
        m = fn()
        dress(m, i)
        if "-show" in args:
            print("\n=== LEVEL %d: %s" % (i, name))
            m.show()
        lv = dict(label="level%d" % i, name=name, walls=walls, floors=floors,
                  ceils=ceils, ambient=m.ambient, zones=m.zones, lights=m.lights,
                  events=m.events, rows=m.rows(), lifts=m.lifts,
                  floor=["".join(r) for r in m.fh], ceiling=["".join(r) for r in m.ch], triggers=m.triggers,
                  puzzles=getattr(m, "puzzles", ""))
        ok &= check_level(lv, ASSETS)
        out.append((lv, comment))
    ok &= not PROBLEMS
    if "--write" in args:
        if not ok:
            print("not writing: fix the problems above first")
            return 1
        for i, (lv, comment) in enumerate(out, 1):
            write_level_file(os.path.join(HERE, "level%d.txt" % i), lv, comment)
        print("wrote %d level files into %s" % (len(out), os.path.normpath(HERE)))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
