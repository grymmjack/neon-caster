"""Showcase sectors for the level editor: YOUR SECTORS 11-16
(custom/custom1..6.txt here). Each uses the editor's level-file sections -
[faces] (pictures on single faces, divided ones), lights on faces (they
tint their face), [pads] (teleporters linked by hand), [monsters] (a
monster's own sight, hearing, health, speed, waking) - on top of the
usual. Built with the level kit, and checked by it.

    python3 showcase.py [OUTDIR]     (OUTDIR: custom/ unless you say)

This writes over custom1-6.txt: once you've changed one of them in the
game's editor, don't run it again (or give it another OUTDIR).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from lvlkit import Map, N

ASSETS = os.path.dirname(HERE)  # (neon-caster/: the pictures)
SIDES = {"E": 1, "S": 2, "W": 3, "N": 4}
WAKE = {"sees": 0, "near": 1, "hit": 2, "hunt": 3}


class Show(Map):
    """A kit Map plus the editor's sections."""

    def __init__(self, fill="#"):
        super().__init__(fill)
        self.faces = {}    # (x, y, face) -> (divided, pic1, pic2)
        self.pads = []     # (x1, y1, x2, y2)
        self.mons = {}     # (x, y) -> (sight, hearing, health, speed, wake)

    def face(self, x, y, f, pic, pic2="", div=0):
        """A picture on face f (E S W N, LE LS LW LN, F, C) of cell (x, y)."""
        self.faces[(x, y, f)] = (div, pic, pic2)

    def floor_pic(self, x0, y0, x1, y1, pic, checker=None):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.g[y][x] not in lvlkit.WALLS:
                    p = checker if checker and (x + y) % 2 else pic
                    self.face(x, y, "F", p)

    def wall_light(self, x, y, side, r, g, b, fx=0, rad=3, bright=150):
        """A light on side `side` of wall cell (x, y), where the editor's
        LIGHT puts it: 0.12 in front of the face's middle (it tints the face)."""
        ax, ay = x + 0.5, y + 0.5
        if side == "E": ax = x + 1.12
        if side == "S": ay = y + 1.12
        if side == "W": ax = x - 0.12
        if side == "N": ay = y - 0.12
        self.light(round(ax, 2), round(ay, 2), rad, bright, r, g, b, fx)

    def painting(self, x, y, side, pic, rgb, fx=0):
        """A wall face with a picture of its own, lit and tinted."""
        self.face(x, y, side, pic)
        self.wall_light(x, y, side, *rgb, fx=fx, rad=2.5, bright=170)

    def mon(self, x, y, c, sight=14, hear=0, health=100, speed=100, wake="sees"):
        self.g[y][x] = c
        if (sight, hear, health, speed, wake) != (14, 0, 100, 100, "sees"):
            self.mons[(x, y)] = (sight, hear, health, speed, WAKE[wake])

    def level(self, label, name, walls, floors, ceils):
        lv = dict(label=label, name=name, walls=walls, floors=floors, ceils=ceils,
                  ambient=self.ambient, zones=self.zones, lights=self.lights, events=self.events,
                  rows=self.rows(), lifts=self.lifts, floor=["".join(r) for r in self.fh],
                  ceiling=["".join(r) for r in self.ch], triggers=self.triggers)
        lv["faces"] = ["%d, %d, %s, %d, %s%s" % (x, y, f, d, p1, (", " + p2) if p2 else "")
                       for (x, y, f), (d, p1, p2) in sorted(self.faces.items(), key=lambda t: (t[0][1], t[0][0], t[0][2]))]
        lv["pads"] = list(self.pads)
        lv["monsters"] = [(x, y) + v for (x, y), v in sorted(self.mons.items(), key=lambda t: (t[0][1], t[0][0]))]
        return lv

    def slots(self):
        """How many of the sector's 24 slots its own pictures take: each
        picture on a face, and each tinted copy a wall light makes."""
        pics = set()
        for (d, p1, p2) in self.faces.values():
            pics.add(p1)
            if p2: pics.add(p2)
        glows = set()  # (as the game makes them: one per picture, colour, strength and effect)
        for (x, y, rad, br, r, g, b, fx) in self.lights:
            fx_, fy_ = x - int(x), y - int(y)
            wx = wy = None
            if abs(fy_ - 0.5) < 0.03 and abs(fx_ - 0.12) < 0.03: wx, wy, sd = int(x) - 1, int(y), "E"
            if abs(fy_ - 0.5) < 0.03 and abs(fx_ - 0.88) < 0.03: wx, wy, sd = int(x) + 1, int(y), "W"
            if abs(fx_ - 0.5) < 0.03 and abs(fy_ - 0.12) < 0.03: wx, wy, sd = int(x), int(y) - 1, "S"
            if abs(fx_ - 0.5) < 0.03 and abs(fy_ - 0.88) < 0.03: wx, wy, sd = int(x), int(y) + 1, "N"
            if wx is None:
                continue
            d, p1, p2 = self.faces.get((wx, wy, sd), (0, self.g[wy][wx], ""))
            amt = int((0.35 + 0.55 * br / 255) * 100)
            glows.add((p1, r, g, b, amt, fx))
            if d:
                glows.add((p2, r, g, b, amt, fx))
        return len(pics), len(glows)


# ---------------------------------------------------------------- 11
def gallery():
    """SECTOR 11: THE GALLERY. A museum after hours: a hall three walls
    high, its floor a checkerboard laid cell by cell, its pillars two-tone
    (divided top | bottom), eight paintings each lit and tinted by a light
    of its own colour. The statues are heavies that wake only when shot -
    and the gunners on the mezzanine hear every shot. The red card is up
    there (the lift); the blue in the vault behind the red door, where
    crawlers spring when you come near; the exit behind the blue door."""
    m = Show("#")
    m.ambient = (150, 235, 230, 255)
    # The foyer (south), you facing north
    m.rect(19, 37, 28, 44)
    m.put(23, 43, "^")
    m.rect(23, 36, 24, 36)  # (an arch into the hall)
    for x, c in ((19, "W"), (28, "W"), (20, "p"), (27, "p")):
        m.put(x, 41 if c == "W" else 37, c)
    m.put(19, 44, "U"); m.put(28, 44, "U")
    m.put(21, 39, "+"); m.put(26, 39, "M"); m.put(22, 44, "a"); m.put(25, 44, "a")
    # The hall: three walls high
    m.rect(9, 15, 38, 35)
    m.ceiling(9, 15, 38, 35, 24)
    for px in (12, 18, 29, 35):  # pillars, 2 x 2, in two rows
        for py in (19, 30):
            m.rect(px, py, px + 1, py + 1, "N")
            for (x, y) in ((px, py), (px + 1, py), (px, py + 1), (px + 1, py + 1)):
                for s in "ESWN":
                    m.face(x, y, s, "wall-tiles.png", "wall-brick.png", div=2)
    m.floor_pic(21, 15, 26, 35, "floor-white.png", checker="floor-plates.png")  # the checkerboard aisle
    # Eight paintings: the north wall and both ends
    art = [(12, 14, "S", "wall-adverts.png", (255, 60, 200), 2), (16, 14, "S", "wall-graffiti.png", (255, 150, 60), 0),
           (31, 14, "S", "wall-datastream.png", (60, 220, 255), 2), (35, 14, "S", "wall-greenhouse.png", (90, 255, 120), 0),
           (8, 19, "E", "wall-viewport.png", (60, 110, 255), 0), (8, 31, "E", "wall-vines.png", (90, 255, 120), 1),
           (39, 16, "W", "wall-reactor.png", (255, 40, 40), 2), (39, 20, "W", "wall-cryo.png", (40, 255, 210), 0)]
    for (x, y, s, pic, rgb, fx) in art:
        m.painting(x, y, s, pic, rgb, fx)
    # The statues: heavies before the north paintings - they wake only when shot
    for x in (12, 16, 31, 35):
        m.mon(x, 16, "h", wake="hit", health=150)
    m.put(24, 25, "2")  # a scatter gun on the aisle
    m.put(10, 34, "e"); m.put(37, 34, "e")
    m.put(15, 25, "Q"); m.put(32, 25, "Q")  # holograms
    # The mezzanine (east, two walls up) - the lift in the hall's corner
    m.rect(39, 22, 45, 35)
    m.floor(39, 22, 45, 35, 16)
    m.ceiling(39, 22, 45, 35, 24)
    for y in range(22, 36):
        m.face(39, y, "W", "wall-hazard.png", "wall-girders.png", div=2)  # its edge: girders over hazard stripes
    m.lift(38, 34, 38, 35, 0, 16, mode=2, speed=8)
    m.put(44, 24, "r")
    m.put(43, 33, "u")
    m.mon(42, 27, "g", hear=18, sight=20)  # the guards: they hear every shot in the hall
    m.mon(42, 31, "g", hear=18, sight=20)
    # The vault (west), behind the red door
    m.rect(2, 21, 7, 29)
    m.put(8, 25, "R")
    m.put(4, 25, "b")
    m.put(3, 22, "&")  # a teleporter: to the exit room - the way out once the blue card's yours
    for (x, y) in ((2, 21), (2, 29), (7, 21), (7, 29)):
        m.mon(x, y, "c", sight=3, wake="near", speed=130)  # crawlers in the corners: they spring when you're near
    m.floor_pic(2, 21, 7, 29, "floor-hazard.png")
    # The exit room (north), behind the blue door
    m.rect(19, 4, 28, 12)
    m.rect(23, 13, 24, 13)
    m.put(23, 14, "B"); m.put(24, 14, "#")
    m.put(23, 13, "."); m.put(24, 13, ".")
    m.put(24, 3, "E")
    m.mon(19, 4, "k", sight=5, wake="near")
    m.mon(28, 4, "k", sight=5, wake="near")
    m.put(20, 11, "*"); m.put(27, 11, "a")
    m.put(26, 6, "&")
    m.put(19, 8, "F"); m.put(28, 8, "F")
    # Light
    for x in (14, 24, 33):
        for y in (17, 25, 33):
            m.light(x + 0.5, y + 0.5, 8, 150, 230, 235, 255, 0)
    m.light(23.5, 40.5, 6, 150, 255, 220, 170, 0)
    m.light(42.5, 28.5, 6, 120, 220, 230, 255, 1)
    m.light(4.5, 25.5, 5, 140, 255, 40, 40, 2)
    m.light(23.5, 8.5, 6, 130, 60, 220, 255, 0)
    m.zone(9, 15, 38, 35, 3, 1)
    m.zone(19, 37, 28, 44, 4, 1)
    m.zone(39, 22, 45, 35, 4, 2)
    m.zone(19, 4, 28, 12, 2, 2)
    m.triggers.append("enter 9 15 38 17 : message THE STATUES SLEEP - UNLESS YOU SHOOT THEM")
    return m, "custom1", "SECTOR 11: THE GALLERY", \
        ["wall-white.png", "wall-tiles.png", "wall-vault.png", "wall-control.png", "wall-viewport.png", "wall-graffiti.png"], \
        ["floor-white.png", "floor-lab.png", "floor-plates.png", "floor-deck.png"], \
        ["ceiling-lights.png", "ceiling-vents.png"], gallery.__doc__


# ---------------------------------------------------------------- 12
def depot():
    """SECTOR 12: THE SUNKEN DEPOT. A cargo depot four walls high, built
    round a shaft with no bottom. A walkway rings it a wall up (its edge
    hazard-striped over concrete: faces divided top | bottom); beams hang
    from the dark; the furnace wall flickers with firelight (lights on its
    faces). A causeway winds across the shaft to the island where the
    yellow card is - and the stalker there is already hunting you. Crawlers
    wait in the closets off the west walkway; the sentry in the north-east
    corner sees the whole depot. The exit is through the yellow door, up
    off the north walkway."""
    m = Show("#")
    m.ambient = (150, 255, 205, 165)
    m.rect(4, 9, 43, 43)                 # the depot
    m.ceiling(4, 9, 43, 43, 32)
    m.floor(4, 9, 43, 12, 8); m.floor(4, 40, 43, 43, 8)      # the walkway: north, south...
    m.floor(4, 9, 7, 43, 8); m.floor(40, 9, 43, 43, 8)       # ...west, east
    m.put(5, 42, ">")
    m.floor(15, 18, 32, 34, -8)          # the shaft
    path = [(23, 34), (23, 33), (23, 32), (22, 32), (21, 32), (20, 32), (20, 31), (20, 30), (20, 29), (21, 29),
            (22, 29), (23, 29), (24, 29), (25, 29), (26, 29), (27, 29), (27, 28), (27, 27), (26, 27)]
    for (x, y) in path:
        m.fh[y][x] = "."                   # the causeway: back up to the floor
    m.floor(22, 22, 26, 26, 4)           # the island, half a wall up...
    m.floor(22, 22, 26, 22, 2); m.floor(22, 26, 26, 26, 2); m.floor(22, 22, 22, 26, 2); m.floor(26, 22, 26, 26, 2)  # ...its rim a step
    m.fh[27][26] = "."; m.fh[26][26] = "2"  # (the causeway reaches its rim)
    m.put(24, 24, "y")
    m.mon(24, 23, "k", wake="hunt")      # hunting you from the start
    m.put(23, 25, "*")
    # The walkway's edge: hazard stripes over concrete (each face divided)
    for y in range(13, 40):
        m.face(7, y, "E", "wall-hazard.png", "wall-concrete.png", div=2)
        m.face(40, y, "W", "wall-hazard.png", "wall-concrete.png", div=2)
    for x in range(8, 40):
        m.face(x, 12, "S", "wall-hazard.png", "wall-concrete.png", div=2)
        m.face(x, 40, "N", "wall-hazard.png", "wall-concrete.png", div=2)
    # Down: two elevators and the south stairs
    m.lift(8, 30, 8, 30, 0, 8, mode=2, speed=8)
    m.lift(39, 13, 39, 13, 0, 8, mode=2, speed=8)
    m.stairs(23, 36, 25, 39, "S", 2, 8)
    for x in (23, 24, 25):
        m.face(x, 40, "N", "wall-concrete.png")  # (behind the stairs: plain)
    # Beams hanging from the dark, over the lower floor
    for y in (16, 37):
        m.ceiling(8, y, 39, y, 12, only_raise=False)
    # Blocks standing on the lower floor - and a stack you can climb to the walkway
    for (x, y) in ((11, 15), (36, 15), (11, 37), (36, 37), (12, 24), (35, 24)):
        m.fh[y][x] = "6"
    for i, e in enumerate((2, 4, 6)):
        m.fh[13][37 - i] = str(e)
    # The furnace wall: firelight on its faces
    m.paint(4, 8, 43, 8, "C")
    for x in (8, 14, 20, 28, 34, 40):
        m.wall_light(x, 8, "S", 255, 140, 50, fx=4, rad=5, bright=230)
    # The exit: through the yellow door, up off the north walkway
    m.rect(20, 2, 28, 6)
    m.floor(20, 2, 28, 7, 8)
    m.ceiling(20, 2, 28, 7, 16)
    m.put(24, 7, "."); m.put(24, 8, "Y")
    m.fh[7][24] = "8"; m.fh[8][24] = "8"     # (the door, and the way through, a wall up like the walkway)
    m.ch[8][24] = m.ch[7][24] = lvlkit.hchar(16, ceiling=True)
    m.put(24, 1, "E")
    m.put(21, 3, "u"); m.put(27, 3, "+")
    # Closets off the west walkway: crawlers that spring when you pass
    for y in (14, 20, 26, 34):
        m.put(3, y, ".")
        m.fh[y][3] = "8"
        m.mon(3, y, "c", sight=2, wake="near", speed=120)
    m.ceiling(3, 9, 3, 43, 32)
    # The sentry sees the whole depot; the gunners hear the shots
    m.mon(42, 10, "s", sight=30)
    m.mon(30, 41, "g", hear=14); m.mon(16, 41, "g", hear=14)
    m.mon(10, 20, "m"); m.mon(37, 33, "m")
    m.put(20, 42, "3"); m.put(6, 11, "M"); m.put(41, 42, "a"); m.put(9, 38, "e"); m.put(38, 18, "+"); m.put(10, 32, "a")
    m.put(13, 14, "o"); m.put(34, 38, "o"); m.put(9, 14, "x"); m.put(38, 38, "x"); m.put(42, 30, "L")
    # Light
    for x in (12, 24, 35):
        for y in (14, 24, 36):
            if not (x == 24 and y == 24):
                m.light(x + 0.5, y + 0.5, 9, 170, 255, 215, 170, 0)
    m.light(24.5, 24.5, 6, 160, 255, 60, 40, 2)    # the island: red, pulsing
    for (x, y) in ((6, 10), (6, 41), (41, 10), (41, 41), (24, 10), (24, 41), (6, 26), (41, 26)):
        m.light(x + 0.5, y + 0.5, 7, 150, 200, 220, 255, 0)
    m.light(24.5, 4.5, 6, 160, 90, 255, 120, 0)
    m.zone(4, 9, 43, 43, 1, 1)
    m.zone(8, 13, 39, 39, 2, 2)
    m.zone(20, 2, 28, 7, 4, 2)
    m.zone(22, 22, 26, 26, 3, 0)
    m.triggers.append("enter 4 38 9 43 : message THE STALKER ON THE ISLAND IS ALREADY HUNTING YOU")
    return m, "custom2", "SECTOR 12: THE SUNKEN DEPOT", \
        ["wall-girders.png", "wall-rusty.png", "wall-furnace.png", "wall-hazard.png", "wall-pipes.png", "wall-concrete.png"], \
        ["floor-platform.png", "floor-concrete.png", "floor-hazard.png", "floor-rustgrate.png"], \
        ["ceiling-girders.png", "ceiling-pipes.png"], depot.__doc__


# ---------------------------------------------------------------- 13
def relay():
    """SECTOR 13: THE RELAY. Four chambers sealed in the rock, and only one
    way into each: a teleporter in the hub, LINKed to it by hand (in
    reading order the hub's pads would only go to each other - [pads]).
    Each chamber is dressed in pictures of its own ([faces]: walls, floor
    and ceiling) and lit in its colour on its walls. The ice holds the red
    card and crawlers that spring when you're near; the biolab the blue,
    and gunners that hear every shot; the reactor the yellow, a sentry that
    sees it all and a heavy twice as tough; the vault the guns, and a heavy
    already hunting. The three cards open the corridor north to the exit."""
    m = Show("#")
    m.ambient = (140, 220, 225, 255)

    def chamber(x0, y0, x1, y1, wall, floor, ceil, rgb, fx):
        m.rect(x0, y0, x1, y1)
        m.ceiling(x0, y0, x1, y1, 12)
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                m.face(x, y, "F", floor); m.face(x, y, "C", ceil)
        for y in range(y0, y1 + 1):
            m.face(x0 - 1, y, "E", wall); m.face(x1 + 1, y, "W", wall)
        for x in range(x0, x1 + 1):
            m.face(x, y0 - 1, "S", wall); m.face(x, y1 + 1, "N", wall)
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        for (x, y, sd) in ((x0 - 1, cy, "E"), (x1 + 1, cy, "W"), (cx, y0 - 1, "S"), (cx, y1 + 1, "N")):
            m.wall_light(x, y, sd, *rgb, fx=fx, rad=4, bright=190)
        m.light(cx + 0.5, cy + 0.5, 6, 110, *rgb, 0)
        return cx, cy

    # The hub, you in the middle; its four pads N E S W
    m.octagon(18, 18, 29, 29, 3)
    m.ceiling(18, 18, 29, 29, 16)
    m.put(23, 25, "^")
    hub = {"N": (23, 20), "E": (27, 23), "S": (24, 27), "W": (20, 24)}
    for (x, y) in hub.values():
        m.put(x, y, "&")
    m.mon(19, 21, "m"); m.mon(28, 26, "m")
    m.put(21, 27, "+"); m.put(26, 20, "a"); m.put(22, 22, "Q"); m.put(25, 25, "Q")
    # The chambers - and which hub pad goes to which (by hand: LINK)
    a = chamber(4, 4, 12, 12, "wall-frost.png", "floor-ice.png", "ceiling-frost.png", (60, 220, 255), 0)
    b = chamber(35, 4, 43, 12, "wall-biolab.png", "floor-lab.png", "ceiling-growlights.png", (90, 255, 120), 2)
    c = chamber(4, 35, 12, 43, "wall-reactor.png", "floor-scorched.png", "ceiling-warning.png", (255, 50, 40), 3)
    d = chamber(35, 35, 43, 43, "wall-vault.png", "floor-platform.png", "ceiling-core.png", (255, 200, 80), 4)
    for (hk, (cx, cy)) in (("N", a), ("E", b), ("W", c), ("S", d)):
        m.put(cx, cy, "&")
        m.pads.append(hub[hk] + (cx, cy))
    # The ice: the red card; crawlers in the corners, springing when you're near
    m.put(8, 5, "r")
    for (x, y) in ((4, 4), (12, 4), (4, 12), (12, 12)):
        m.mon(x, y, "c", sight=3, wake="near", speed=140)
    m.put(5, 8, "e")
    # The biolab: the blue card; gunners that hear every shot in it
    m.put(39, 5, "b")
    for (x, y) in ((36, 6), (42, 6), (36, 11), (42, 11)):
        m.mon(x, y, "g", hear=20, sight=6)
    m.put(39, 11, "w"); m.put(43, 8, "J"); m.put(35, 8, "I")
    # The reactor: the yellow card; a sentry that sees it all, a heavy twice as tough
    m.put(8, 42, "y")
    m.mon(4, 35, "s", sight=30); m.mon(12, 43, "s", sight=30)
    m.mon(11, 38, "h", health=200, speed=80)
    m.put(5, 39, "L"); m.put(12, 39, "L"); m.put(8, 36, "a")
    # The vault: the guns - and a heavy already hunting
    m.mon(42, 42, "h", wake="hunt")
    m.put(36, 36, "4"); m.put(42, 36, "*"); m.put(36, 42, "u"); m.put(39, 42, "3"); m.put(37, 39, "M")
    m.put(43, 39, "U"); m.put(35, 39, "U")
    # North: the corridor of three doors, then the exit
    m.rect(23, 6, 24, 17)
    m.ceiling(23, 6, 24, 17, 12)
    for (y, door) in ((16, "R"), (13, "B"), (10, "Y")):
        m.put(23, y, door); m.put(24, y, "#")
    m.rect(19, 2, 28, 5)
    m.ceiling(19, 2, 28, 5, 12)
    m.put(24, 1, "E")
    m.mon(20, 3, "k", sight=6); m.mon(27, 3, "k", sight=6)
    for y in (7, 12, 15):
        m.light(23.5, y + 0.5, 4, 120, 220, 230, 255, 1)
    m.light(23.5, 3.5, 6, 150, 255, 255, 255, 0)
    m.light(23.5, 23.5, 7, 160, 200, 180, 255, 2)
    m.light(20.5, 20.5, 4, 120, 60, 220, 255, 0); m.light(27.5, 27.5, 4, 120, 255, 60, 220, 0)
    m.zone(18, 18, 29, 29, 1, 1)
    m.zone(23, 6, 24, 17, 2, 2)
    m.zone(19, 2, 28, 5, 2, 2)
    m.triggers.append("enter 22 19 24 21 : message NORTH PAD: THE ICE")
    m.triggers.append("enter 26 22 28 24 : message EAST PAD: THE BIOLAB")
    m.triggers.append("enter 19 23 21 25 : message WEST PAD: THE REACTOR")
    m.triggers.append("enter 23 26 25 28 : message SOUTH PAD: THE VAULT")
    return m, "custom3", "SECTOR 13: THE RELAY", \
        ["wall-transit.png", "wall-hull.png", "wall-control.png", "wall-servers.png", "wall-terminals.png", "wall-obsidian.png"], \
        ["floor-circuit.png", "floor-deck.png", "floor-plates.png", "floor-core.png"], \
        ["ceiling-tunnel.png", "ceiling-cables.png"], relay.__doc__


# ---------------------------------------------------------------- 14
def conservatory():
    """SECTOR 14: THE CONSERVATORY. A glasshouse gone wild. Its courtyard
    floor is woven - every cell divided, soil against white stone, one way then
    the other ([faces], divided). The pond has no bottom: cross it on the
    stepping lifts, rising and falling each at its own pace, for the red
    card. Through the glass wall the specimen garden sleeps - the heavy in
    it wakes only if you hit it - and the blue card is in there, behind the
    red door. The corridor from the gate is the light lab: the six ways a
    light can go, side by side, each on its own wall. Crawlers hide in the
    planters; spitters in the courtyard hear every shot."""
    m = Show("#")
    m.ambient = (150, 215, 255, 200)
    # The gate (south), and the light lab up to the courtyard
    m.rect(19, 40, 28, 44); m.put(23, 43, "^")
    m.put(20, 44, "+"); m.put(27, 44, "a"); m.put(19, 41, "p"); m.put(28, 41, "p")
    m.rect(21, 32, 26, 39)
    lab = [(20, 34, "E", (230, 235, 255), 0), (20, 36, "E", (60, 220, 255), 1), (20, 38, "E", (255, 60, 220), 2),
           (27, 34, "W", (255, 40, 40), 3), (27, 36, "W", (255, 150, 60), 4), (27, 38, "W", (90, 255, 120), 5)]
    for (x, y, sd, rgb, fx) in lab:
        m.face(x, y, sd, "wall-white.png")
        m.wall_light(x, y, sd, *rgb, fx=fx, rad=2.5, bright=210)
    m.triggers.append("enter 21 37 26 39 : message THE LIGHT LAB - STEADY, FLICKER, PULSE / STROBE, FIRE, DYING")
    # The courtyard: woven floor, planters, a glass roof two walls up
    m.rect(14, 18, 33, 31)
    m.ceiling(14, 18, 33, 31, 16)
    for y in range(18, 32):
        for x in range(14, 34):
            if (x + y) % 2:
                m.face(x, y, "F", "floor-soil.png", "floor-white.png", div=1)
            else:
                m.face(x, y, "F", "floor-white.png", "floor-soil.png", div=2)
    for (x0, y0) in ((16, 20), (29, 20), (16, 27), (29, 27)):  # planters: raised beds, a step up
        m.floor(x0, y0, x0 + 2, y0 + 2, 2)
        for y in range(y0, y0 + 3):
            for x in range(x0, x0 + 3):
                m.face(x, y, "F", "floor-soil.png")
        m.put(x0 + 1, y0 + 1, "p")
    m.mon(16, 22, "c", sight=2, wake="near"); m.mon(31, 27, "c", sight=2, wake="near")
    m.mon(22, 19, "w", hear=16); m.mon(26, 19, "w", hear=16)
    m.put(23, 25, "W"); m.put(24, 25, "W"); m.put(20, 24, "e"); m.put(27, 24, "M")
    # The pond (west): no bottom - six lifts to step across, each at its own pace
    m.rect(3, 18, 12, 31)
    m.ceiling(3, 18, 12, 31, 16)
    m.rect(13, 24, 13, 25)
    m.floor(5, 19, 10, 30, -8)
    for i, x in enumerate(range(5, 11)):
        m.lift(x, 24, x, 24, 0, 6, mode=1, speed=(3, 5, 4, 6, 3, 5)[i])
    m.put(3, 24, "r"); m.put(4, 29, "+")
    m.mon(11, 20, "m"); m.mon(11, 29, "m")
    # The specimen garden (east), seen through the glass - in by the red door
    m.rect(35, 18, 44, 31)
    m.ceiling(35, 18, 44, 31, 16)
    for y in list(range(20, 24)) + list(range(27, 30)):
        m.put(34, y, "=")
    m.put(34, 25, "R")
    m.floor_pic(35, 18, 44, 31, "floor-soil.png")
    m.mon(40, 24, "h", wake="hit", health=200)
    m.put(43, 20, "b"); m.mon(43, 29, "c", sight=3, wake="near")
    for (x, y) in ((37, 20), (41, 21), (36, 28), (42, 27), (38, 30)):
        m.put(x, y, "p")
    m.put(44, 25, "I")
    # North: the blue door, and the exit
    m.put(23, 17, "B"); m.rect(23, 10, 23, 16)
    m.rect(19, 4, 28, 9); m.put(24, 3, "E")
    m.mon(19, 4, "w", sight=4, wake="near"); m.mon(28, 4, "w", sight=4, wake="near")
    m.put(20, 9, "*"); m.put(27, 9, "a")
    # Light
    m.light(23.5, 42.5, 6, 150, 255, 235, 200, 0)
    for (x, y) in ((18, 24), (24, 21), (24, 28), (30, 24)):
        m.light(x + 0.5, y + 0.5, 7, 140, 160, 255, 140, 2)
    m.light(7.5, 24.5, 7, 150, 90, 160, 255, 0)
    m.light(3.5, 24.5, 4, 150, 255, 60, 60, 2)
    m.light(39.5, 24.5, 7, 140, 200, 120, 255, 0)
    m.light(23.5, 6.5, 6, 150, 230, 255, 230, 0)
    m.light(23.5, 13.5, 4, 110, 200, 255, 200, 1)
    m.zone(19, 40, 28, 44, 2, 1)
    m.zone(21, 32, 26, 39, 3, 1)
    m.zone(3, 18, 12, 31, 2, 2)
    m.zone(19, 4, 28, 9, 2, 1)
    return m, "custom4", "SECTOR 14: THE CONSERVATORY", \
        ["wall-greenhouse.png", "wall-vines.png", "wall-moss.png", "wall-pipes.png", "wall-white.png", "wall-biolab.png"], \
        ["floor-deck.png", "floor-platform.png", "floor-concrete.png", "floor-soil.png"], \
        ["ceiling-growlights.png", "ceiling-pipes.png"], conservatory.__doc__


# ---------------------------------------------------------------- 15
def listening():
    """SECTOR 15: THE LISTENING POST. A station that hears everything. The
    guards in the server hall see four cells in the gloom - but hear a
    shot from fourteen: kick, or creep. Crawlers wait in the closets off
    the west corridor; the blue card is in the relay room, and you have to
    last thirty seconds in there to get out with it (a survive room). The
    red card is at the statue's feet - and the statue wakes if you hit it.
    A terminal on the hall's north wall unlocks the archive (a USE
    trigger); a timed one locks it as you arrive."""
    m = Show("#")
    m.ambient = (95, 170, 210, 255)
    # The gate, and the corridor north
    m.rect(20, 40, 27, 44); m.put(23, 43, "^")
    m.put(21, 44, "M"); m.put(26, 44, "+"); m.put(20, 41, "U"); m.put(27, 41, "U")
    m.rect(23, 34, 24, 39)
    m.triggers.append("enter 22 34 25 36 : message THEY HEAR EVERY SHOT - KICK (F), AND THEY MIGHT NOT")
    # The server hall: racks in rows, guards that hear
    m.rect(8, 20, 39, 33)
    m.ceiling(8, 20, 39, 33, 12)
    for x in range(11, 37, 5):
        for y in (23, 26, 29):
            if (x, y) != (36, 26):
                m.put(x, y, "l")
    for (x, y) in ((12, 21), (25, 21), (35, 21), (12, 32), (35, 32)):
        m.mon(x, y, "g", sight=4, hear=14)
    m.mon(37, 27, "h", wake="hit", health=150)      # the statue
    m.put(38, 27, "r")
    m.put(20, 31, "e"); m.put(30, 22, "a")
    for x in (14, 22, 34):                          # the hall's north wall: screens, flickering green
        m.face(x, 19, "S", "wall-terminals.png")
        m.wall_light(x, 19, "S", 90, 255, 120, fx=1, rad=3, bright=170)
    m.face(30, 19, "S", "wall-control.png")         # the archive's terminal: USE it
    m.wall_light(30, 19, "S", 60, 220, 255, fx=2, rad=3, bright=190)
    m.triggers.append("time 0 : door 40 24 lock")
    m.triggers.append("use 30 19 : door 40 24 unlock ; message THE ARCHIVE IS OPEN ; sound door")
    for x in (10, 18, 26, 34):                      # its south wall: servers, steady cyan
        m.face(x, 34, "N", "wall-servers.png")
    # The archive (east), locked till the terminal's used
    m.rect(41, 18, 45, 30); m.put(40, 24, "H")
    m.put(43, 20, "3"); m.put(44, 28, "u"); m.put(42, 28, "*"); m.put(45, 24, "F")
    # The west corridor, closets off it - crawlers that spring
    m.put(7, 27, "D"); m.put(6, 27, "."); m.rect(2, 12, 5, 38)
    for y in (16, 22, 30, 36):
        m.put(1, y, "."); m.mon(1, y, "c", sight=2, wake="near", speed=130)
    m.put(4, 26, "a"); m.put(3, 34, "+")
    # The relay room (north-west): the blue card - survive thirty seconds for it
    m.rect(2, 3, 12, 10); m.put(4, 11, "D")
    m.put(7, 5, "b")
    m.event(2, 2, 3, 12, 10, 30, 120, 9)
    for x in (3, 11):
        m.put(x, 3, "A")
    # North: the red door, the blue door, the exit
    m.put(23, 19, "R"); m.rect(23, 13, 24, 18)
    m.put(23, 12, "B"); m.put(24, 12, "#")
    m.rect(18, 2, 29, 11); m.put(24, 1, "E")
    m.mon(18, 2, "k", sight=3, wake="near"); m.mon(29, 2, "k", sight=3, wake="near")
    m.put(20, 10, "*"); m.put(27, 10, "e")
    m.triggers.append("enter 21 13 26 18 : message THE LAST DOOR - SOMETHING'S BREATHING BEHIND IT")
    # Light: low, cold; the relay room red
    for x in (12, 24, 35):
        m.light(x + 0.5, 27.5, 6, 90, 120, 160, 255, 0)
    m.light(23.5, 42.5, 5, 120, 200, 220, 255, 0)
    m.light(3.5, 24.5, 5, 80, 140, 160, 255, 5)
    m.light(7.5, 6.5, 6, 150, 255, 40, 40, 3)
    m.light(43.5, 24.5, 5, 130, 255, 200, 120, 0)
    m.light(23.5, 6.5, 6, 130, 230, 235, 255, 0)
    m.light(23.5, 15.5, 3, 100, 255, 60, 60, 2)
    m.zone(8, 20, 39, 33, 1, 1)
    m.zone(2, 3, 12, 10, 3, 2)
    m.zone(18, 2, 29, 11, 2, 2)
    return m, "custom5", "SECTOR 15: THE LISTENING POST", \
        ["wall-servers.png", "wall-terminals.png", "wall-control.png", "wall-hull.png", "wall-vault.png", "wall-transit.png"], \
        ["floor-circuit.png", "floor-deck.png", "floor-hazard.png", "floor-plates.png"], \
        ["ceiling-cables.png", "ceiling-vents.png"], listening.__doc__


# ---------------------------------------------------------------- 16
def observatory():
    """SECTOR 16: THE OBSERVATORY. A tower four walls high in a moonlit
    garden, windows of glass in its wall. Climb it: the stairs to the first
    ledge, a wall up; the elevator to the second; the lift that rises and
    falls by itself to the third - each ledge's edge in pictures of its own
    and lit its own colour. The yellow card is at the summit, and the pad
    there is LINKed to the vestibule behind the yellow door, where the exit
    is. Two more pads cross the garden. (In reading order the four would
    pair the wrong way: [pads] says which goes where.)"""
    m = Show("#")
    m.ambient = (110, 150, 180, 255)
    # The garden, round the tower; you in the south
    m.rect(4, 4, 43, 43); m.ceiling(4, 4, 43, 43, 24)
    m.rect(13, 13, 34, 34, "N")                  # the tower: a wall one cell thick...
    m.rect(14, 14, 33, 33)                       # ...round its insides
    m.ceiling(14, 14, 33, 33, 32)
    m.put(23, 41, "^")
    m.put(24, 34, "D")                           # its door
    for x in list(range(17, 21)) + list(range(28, 32)):
        m.put(x, 34, "=")                        # windows
    for y in list(range(18, 22)) + list(range(26, 30)):
        m.put(13, y, "="); m.put(34, y, "=")
    m.put(5, 24, "&"); m.put(42, 24, "&")        # across the garden
    m.mon(8, 8, "g", hear=10); m.mon(39, 8, "g", hear=10); m.mon(39, 39, "k", wake="hunt")
    m.put(6, 40, "+"); m.put(41, 40, "a"); m.put(24, 39, "M")
    for (x, y) in ((8, 30), (39, 16), (10, 12), (37, 35), (6, 18)):
        m.put(x, y, "p")
    # Inside: the ground, and the ledges up the walls
    m.floor(31, 14, 33, 33, 8)                   # ledge 1 (east), a wall up
    m.floor(14, 14, 33, 16, 16)                  # ledge 2 (north), two walls up
    m.floor(14, 17, 16, 33, 24)                  # ledge 3 (west), three
    m.stairs(27, 30, 30, 32, "E", 2, 8)          # up to ledge 1
    m.lift(32, 17, 32, 17, 8, 16, mode=2, speed=8)     # ledge 1 to 2: an elevator
    m.lift(15, 17, 15, 17, 16, 24, mode=1, speed=4)    # 2 to 3: rising and falling by itself
    for y in range(17, 34):                       # ledge 1's edge
        if not 30 <= y <= 32:
            m.face(31, y, "W", "wall-girders.png")
            if y % 4 == 1:
                m.wall_light(31, y, "W", 60, 220, 255, fx=0, rad=2.5, bright=160)
    for x in range(17, 31):                       # ledge 2's edge: viewports over hull plates
        m.face(x, 16, "S", "wall-viewport.png", "wall-hull.png", div=2)
        if x % 4 == 1:
            m.wall_light(x, 16, "S", 255, 60, 220, fx=2, rad=3, bright=170)
    for y in range(18, 34):                       # ledge 3's edge
        m.face(16, y, "E", "wall-vault.png")
        if y % 4 == 2:
            m.wall_light(16, y, "E", 255, 160, 50, fx=4, rad=3, bright=180)
    m.put(15, 32, "y"); m.put(14, 33, "&"); m.put(16, 30, "*")   # the summit
    m.mon(24, 15, "s", sight=20); m.mon(15, 24, "w", sight=10)
    for (x, y) in ((20, 22), (27, 25), (22, 28)):
        m.mon(x, y, "m")
    m.put(24, 24, "Q"); m.put(32, 25, "a"); m.put(20, 15, "e")
    # North: the yellow door, the vestibule, the exit
    m.rect(21, 1, 25, 2); m.put(23, 3, "Y"); m.put(26, 1, "E"); m.put(21, 1, "&")
    m.pads.append((14, 33, 21, 1))               # the summit's pad: to the vestibule
    m.pads.append((5, 24, 42, 24))               # and across the garden
    # Light: moonlight outside; inside, a beam from the dome
    for (x, y) in ((8, 8), (39, 8), (8, 39), (39, 39), (24, 8), (24, 40), (8, 24), (39, 24)):
        m.light(x + 0.5, y + 0.5, 7, 110, 150, 190, 255, 0)
    m.light(23.5, 23.5, 8, 170, 200, 220, 255, 2)
    m.light(24.5, 15.5, 5, 120, 255, 120, 220, 0)
    m.light(15.5, 31.5, 4, 160, 255, 220, 120, 2)
    m.light(23.5, 1.5, 3, 140, 90, 255, 120, 0)
    m.zone(4, 4, 43, 43, 1, 1)
    m.zone(14, 14, 33, 33, 2, 2)
    m.triggers.append("enter 22 35 26 37 : message THE OBSERVATORY - THE YELLOW CARD IS AT THE TOP")
    m.triggers.append("enter 14 30 16 33 : message THE PAD HERE GOES TO THE VESTIBULE")
    return m, "custom6", "SECTOR 16: THE OBSERVATORY", \
        ["wall-hull.png", "wall-obsidian.png", "wall-girders.png", "wall-viewport.png", "wall-vault.png", "wall-moss.png"], \
        ["floor-soil.png", "floor-platform.png", "floor-deck.png", "floor-plates.png"], \
        ["ceiling-stone.png", "ceiling-girders.png"], observatory.__doc__


def build(fn, outdir):
    m, label, name, walls, floors, ceils, doc = fn()
    lv = m.level(label, name, walls, floors, ceils)
    path = os.path.join(outdir, label + ".txt")
    comment = [l.strip() for l in doc.strip().splitlines()]
    lvlkit.write_level_file(path, lv, comment)
    back = lvlkit.read_level_file(path, label)
    ok = lvlkit.check_level(back, ASSETS)
    errs, warns = lvlkit.check_heights(back)
    for e in errs: print("  HEIGHTS ERROR", e)
    for w in warns: print("  ", w)
    pics, glows = m.slots()
    print("  slots: %d pictures + %d tinted = %d of 24" % (pics, glows, pics + glows))
    for (x, y, f), (d, p1, p2) in m.faces.items():
        for p in (p1, p2):
            if p and not os.path.exists(os.path.join(ASSETS, p)):
                print("  MISSING picture", p)
    return ok and not errs and pics + glows <= 24


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "custom")
    os.makedirs(out, exist_ok=True)
    good = True
    for fn in (gallery, depot, relay, conservatory, listening, observatory):
        print(fn.__name__)
        good = build(fn, out) and good
    print("ALL GOOD" if good else "PROBLEMS")
