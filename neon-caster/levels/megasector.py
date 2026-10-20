"""SECTOR 24: THE NEON EXPO - one showcase sector with every feature the
game has: NEXUS's world's fair, eight pavilions round a grand atrium.

    python3 megasector.py            build it and check it
    python3 megasector.py -show      ...and print the map
    python3 megasector.py --write    build, check, and write custom/custom14.txt

(custom14.txt is YOUR SECTORS 24. Run --write only while it's this script's:
once you've changed it in the editor, copy the change in here first.)

THE TOUR - and what each part shows:

 PLAZA (south, the start)   outdoors under the night sky (a sky ceiling);
     rain puddles (water); a painted murky patch you wade through; stall
     kiosks of thin block walls under awnings, their signs lit; vending
     machines and screens standing flat in shopfront alcoves; street lamps;
     a two-tone triangle-zoned floor; thieves working the crowd; a teleport
     pad LINKed by hand to the arcade
 ATRIUM (the hub)           three walls high; a fountain pool stepping down
     in two rings round a lit spire; a ring of pink and cyan lit columns
     (one with a two-tone divided face); diagonal corners; paintings lit
     and tinted on its walls; a checkerboard aisle laid cell by cell; a
     painted ceiling; statues (heavies that wake only when shot); a
     mezzanine a wall up by elevator, with a gunner who hears every shot;
     glass windows into the hazard lab; a med station (a USE trigger)
 HAZARD LAB (west)          a spawner NEST among specimen tanks in alcoves;
     three vats - poison, slime, acid - to wade; an electric TRAP floor
     before the red card; pick it up and the trap floods with slime (a
     trigger's liquid command); a pad back to the mezzanine
 FOUNDRY (east, red door)   the power FAILS as you walk in (BLACKOUT); a
     river of lava with steps out of its ends, crossed on lifts that bob up
     and down; a FIRE TRAP floor guarding the railgun; generators roaring in
     alcoves; a molten-floored slag channel that burns; heavies round the
     blue card - kill them and a shortcut door unlocks (a CLEAR trigger)
 DATA CENTER (north, blue)  a LASER grid across its door; rows of server
     racks between thin partitions; a LASER CUTTER sweeping the sorter; a
     server vault that seals you in to SURVIVE with the yellow card; a code
     terminal ($: a QB64 puzzle); a data station (@) - jack in to unseal
     the arcade (!)
 ARCADE (north-west, !)     a SHOOTING GALLERY: smash everything in time
     for the damage amp; a pad LINKed back to the plaza
 SKYDECK (north-east, yellow) rooftops in the open over a street that
     kills (DEATH PIT); stairs between roofs; a lift that only moves when
     you call it from its consoles (USE triggers: liftgo); sentries; the
     overseer on the summit, and the exit
 CRYPT (south-west)         an AMBUSH lockdown (the scatter gun its prize);
     CLOSETS whose secret walls slide open on crawlers; cryo pods in
     alcoves, bodies, dying lights - which die for good as you walk in
 VAULT (south-east)         a PRESSURE PLATE in the corridor; the thieves'
     HOARD, sealed until every thief is dead; lockers standing flat

THE ARMOURY (all over)      wall turrets that slide out at chest height, one of
     every weapon - plasma, laser, lightning, flame, poison, acid, missiles;
     the rocket launcher, and rockets for it

Everything else: every map character (all nine monsters, all twenty-one
decorations, all fifteen pickups), all six light effects, light-tinted
wall and block faces, [loot] for its breakables, [monsters] settings
(sight, hearing, health, speed, waking), and triggers of every kind
(enter, use, clear, time) running message, sound, spawn, item, door, light,
liftgo, liquid and give.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from lvlkit import N, check_level, write_level_file, read_level_file
import newsectors as ns
from newsectors import Sector, hstr, stall, river, LIT, CYAN, PINK, GREEN, AMBER, RED, VIOLET

ASSETS = os.path.dirname(HERE)
OUT = os.path.join(HERE, "custom", "custom14.txt")
LABEL = "custom14"
NAME = "SECTOR 24: THE NEON EXPO"
WALLS = ["wall-concrete.png", "wall-white.png", "wall-servers.png", "wall-biolab.png", "wall-furnace.png", "wall-brick.png"]
FLOORS = ["floor-plates.png", "floor-circuit.png", "floor-cobbles.png", "floor-hazard.png"]
CEILS = ["ceiling-lights.png", "sky-neon-night.png"]
WHITE = (230, 240, 255)


def expo():
    m = Sector("#")
    m.ambient = (165, 215, 220, 255)
    m.puzzles = "function"
    lifts = []   # (their numbers, for liftgo: in the order they're made)

    def lift(*a, **k):
        m.lift(*a, **k)
        return len(m.lifts)

    # The pavilions' walls, each its own look (the fill round each)
    for (x0, y0, x1, y1, c) in ((1, 14, 12, 34, "K"), (35, 14, 46, 34, "P"), (13, 1, 34, 13, "C"),
                                (1, 35, 12, 46, "G"), (35, 35, 46, 46, "N"), (13, 14, 34, 34, "N")):
        m.rect(x0, y0, x1, y1, c)

    # ================================================== PLAZA (south): the start
    m.room(15, 36, 32, 46, ceil=16, zone=(3, 2))
    m.put(23, 45, "^")
    m.zone(19, 42, 22, 45, 4, 0, 1)            # (a two-tone triangle floor)
    m.zone(25, 42, 28, 45, 4, 0, 3)
    stall(m, 16, 37, "x", AMBER)
    stall(m, 29, 37, "n", PINK)
    m.nudge(30, 38, 0, -3, 2)
    for (x, y) in ((15, 36), (32, 36)):
        m.put(x, y, "i")
    m.pool(18, 41, 19, 42, "w", sink=1, depth=1)
    m.pool(28, 40, 29, 41, "w", sink=1, depth=1)
    for x in range(22, 26):                    # (a murky patch, painted: you wade)
        m.face(x, 39, "F", "floor-murky.png")
    m.alcove(14, 40, "E", depth=3, floor=0, ceil=8, deco="n", glow=PINK, fx=0)
    m.alcove(33, 40, "W", depth=3, floor=0, ceil=8, deco="n", glow=CYAN, fx=0)
    m.alcove(14, 44, "E", depth=3, floor=0, ceil=8, deco="F", glow=CYAN, fx=2)
    m.alcove(33, 44, "W", depth=3, floor=0, ceil=8, deco="A", glow=AMBER, fx=0)
    m.put(23, 37, "Q")                          # (the expo's sign: a hologram)
    for (x, y, c) in ((20, 45, "W"), (17, 45, "M"), (30, 43, "a"), (21, 40, "+"),
                      (16, 41, "T"), (31, 38, "T"), (32, 43, "m"), (19, 37, "p")):
        m.put(x, y, c)
    m.put(31, 45, "&")                          # (LINKed by hand to the arcade's)
    # the archway into the atrium: low, its lintels painted
    m.rect(21, 34, 26, 35)
    m.ceiling(21, 34, 26, 35, 12, only_raise=False)
    m.zone(21, 34, 26, 35, 1, 1)
    for x in range(21, 27):
        m.face(x, 36, "LN", "wall-adverts.png")
    m.post(20, 36, "N", at=6, w=2, d=2, wall=2, glow=PINK)
    m.post(27, 36, "N", at=2, w=2, d=2, wall=2, glow=CYAN)
    m.light(23.5, 41.5, 10, 140, 200, 120, 255, 0)
    m.light(23.5, 34.5, 5, 150, 255, 230, 200, 0)   # (the archway, lit so the hall shows through it)
    # the crypt's and the vault's doors
    m.rect(12, 41, 14, 41); m.put(13, 41, "H")   # (the crypt's: a shutter)
    m.rect(33, 41, 35, 41); m.put(34, 41, "D")

    # ================================================== ATRIUM (the hub)
    m.room(14, 15, 33, 33, ceil=24, zone=(1, 1))
    for (x, y, c) in ((14, 15, "/"), (33, 15, "\\"), (14, 33, "\\"), (33, 33, "/")):
        m.put(x, y, c)
    m.pool(19, 21, 28, 28, "w", sink=2, depth=1)  # (the fountain: two rings down)
    m.pool(20, 22, 27, 27, "w", sink=2, depth=3)
    m.column(23, 24, size=3, wall=2, pic=LIT, glow=CYAN, fx=2)
    m.put(24, 25, "Q")
    for i, (x, y) in enumerate(((17, 18), (17, 30), (29, 30), (25, 17))):
        m.column(x, y, size=2, wall=2, pic=LIT, glow=PINK if i % 2 else CYAN, fx=0)
    m.blk(16, 24, 3, 3, 5, 5, wall=2)
    m.face(16, 24, "BS", "wall-tiles.png", "wall-brick.png", div=2)   # (a two-tone face, divided top | bottom)
    m.face(16, 24, "BN", "wall-tiles.png", "wall-brick.png", div=2)
    # the mezzanine, a wall up, by elevator
    m.floor(29, 16, 33, 20, 8, only_open=False)
    m.zone(29, 16, 33, 20, 2, 0)
    lift(28, 20, 28, 20, 0, 8, mode=2, speed=6)
    for y in range(16, 21):
        m.face(29, y, "W", "wall-lightstrip.png")   # (the mezzanine's edge, from below)
    m.mon(31, 18, "g", hear=14)
    m.put(32, 16, "3"); m.put(30, 16, "q")
    m.put(33, 19, "&")                          # (LINKed by hand to the hazard lab's)
    # paintings, lit and tinted, on the north wall
    m.painting(18, 14, "S", "wall-adverts.png", PINK, fx=2)
    m.painting(28, 14, "S", "wall-graffiti.png", CYAN, fx=0)
    m.floor_pic(21, 29, 26, 33, "floor-white.png", checker="floor-plates.png")
    for (x, y) in ((22, 23), (23, 23), (24, 23), (25, 23), (22, 26), (25, 26)):
        m.face(x, y, "C", "ceiling-core.png")
    m.mon(15, 17, "h", wake="hit"); m.mon(15, 31, "h", wake="hit")   # (statues: they wake when shot)
    for (x, y, c) in ((19, 32, "W"), (15, 26, "p"), (32, 26, "p"), (31, 31, "k"), (20, 19, "w"),
                      (27, 31, "e"), (19, 29, "a")):
        m.put(x, y, c)
    m.light(23.5, 19.5, 9, 140, 255, 220, 255, 0)
    m.light(23.5, 30.5, 9, 130, 200, 220, 255, 0)
    for (x, y, g) in ((17, 22, PINK), (30, 22, CYAN), (17, 27, CYAN), (30, 27, PINK)):   # (the hall's glow, all round)
        m.light(x + 0.5, y + 0.5, 8, 120, *g, 0)
    # glass into the hazard lab; the doors out
    for y in (19, 20, 21):
        m.put(12, y, "="); m.put(13, y, "=")
    m.rect(12, 25, 12, 25); m.put(13, 25, "D")
    m.rect(35, 24, 35, 24); m.put(34, 24, "R")
    m.rect(23, 13, 23, 13); m.put(23, 14, "B")
    m.rect(35, 30, 35, 30); m.put(34, 30, "D")   # (the foundry's shortcut: locked until it's cleared)
    m.painting(13, 28, "E", "wall-terminals.png", GREEN, fx=2)
    m.triggers += ["time 0 : door 34 30 lock",
                   "time 1 : message WELCOME TO THE NEON EXPO - EIGHT PAVILIONS, EVERY WONDER OF NEXUS",
                   "use 13 28 : give health 25 ; sound health ; message MED STATION: +25 HEALTH"]

    # ================================================== HAZARD LAB (west)
    m.room(2, 15, 11, 33, ceil=12, zone=(4, 1))
    for x in (4, 9):
        m.alcove(x, 14, "S", depth=4, floor=0, ceil=7, deco="I", glow=GREEN, fx=2)
    m.put(3, 17, "S"); m.put(10, 17, "S")
    m.event(5, 2, 15, 11, 20, 4, 240)          # (the nest: crawlers while you're near)
    m.put(2, 20, "J"); m.put(11, 20, "J")
    for (x0, k, g) in ((3, "p", (120, 255, 60)), (6, "s", (90, 230, 40)), (9, "a", (220, 255, 60))):
        m.pool(x0, 22, x0 + 1, 25, k, sink=2, depth=1)
        m.light(x0 + 1.0, 23.5, 3, 130, *g, 2)
    m.event(3, 2, 27, 11, 29, 60, 90)          # (the electric floor)
    m.put(6, 32, "r"); m.put(3, 32, "+"); m.put(2, 31, "&")
    m.mon(8, 31, "k", sight=4, wake="near")
    for (x, y, c) in ((5, 19, "c"), (8, 21, "w"), (10, 26, "u")):
        m.put(x, y, c)
    m.light(6.5, 30.5, 6, 140, 130, 255, 160, 1)
    m.triggers += ["enter 11 23 11 26 : message HAZARD LAB - POISON HURTS, SLIME SLOWS, ACID EATS YOUR ARMOUR FIRST",
                   "enter 4 31 8 33 : liquid slime 2 27 11 29 2 ; sound bubble ; message THE FLOOR IS FLOODING"]

    # ================================================== FOUNDRY (east, red door)
    m.room(36, 15, 46, 33, ceil=20, zone=(4, 1))
    m.event(11, 36, 15, 46, 33, 15, 3)         # (the power fails as you walk in)
    river(m, 36, 46, 21, 23, "l")
    for x, sp in ((40, 4), (43, 6)):
        for y in (21, 22, 23):
            m.lq[y][x] = "."; m.ld[y][x] = "."
        lift(x, 21, x, 23, -6, 0, mode=1, speed=sp)
    m.event(12, 37, 27, 45, 30, 50, 110)       # (the fire floor)
    m.put(44, 32, "4")
    for x in (38, 44):
        m.alcove(x, 34, "N", depth=4, floor=0, ceil=7, deco="L", glow=AMBER, fx=4)
    for y in range(26, 31):                     # (a slag channel along the wall: it burns)
        m.face(46, y, "F", "floor-molten.png")
    m.put(45, 16, "b")
    m.put(37, 16, "f"); m.put(38, 16, "x")
    for (x, y, c) in ((41, 17, "h"), (44, 18, "h"), (38, 19, "g"), (42, 26, "m"), (37, 31, "e"), (46, 32, "a")):
        m.put(x, y, c)
    for (x, y) in ((41, 17), (41, 26), (41, 31)):
        m.light(x + 0.5, y + 0.5, 7, 140, 255, 150, 70, 4)
    m.triggers += ["enter 36 24 37 25 : message THE FOUNDRY - MIND THE LAVA, RIDE THE LIFTS",
                   "clear 36 15 46 20 : door 34 30 unlock ; door 34 30 open ; sound door ; message A SHORTCUT TO THE ATRIUM OPENS"]

    # ================================================== DATA CENTER (north, blue door)
    m.room(14, 2, 33, 12, ceil=12, zone=(2, 1))
    m.event(9, 14, 11, 33, 11, 75, 75)         # (lasers across its door)
    for y in (4, 7):
        m.thin_wall(15, y, 21, y, "N", t=1, wall=3)
        m.put(16, y, "l"); m.put(19, y, "l")
    m.event(10, 23, 2, 27, 6, 150, 0)          # (the sorter: a laser cutter)
    m.room(29, 2, 33, 5, ceil=12, zone=(2, 1))
    m.thin_wall(29, 6, 33, 6, "N", t=1, wall=3)
    m.blocks = [b for b in m.blocks if (b[0], b[1]) != (31, 6)]
    m.event(2, 29, 2, 33, 5, 20, 150, 9)       # (the server vault: survive for armour)
    m.put(33, 2, "y"); m.put(29, 2, "F"); m.nudge(29, 2, 0, -2, 2)
    m.put(20, 1, "$")
    m.put(13, 10, "@")
    m.rect(12, 7, 12, 7); m.put(13, 7, "!")
    for (x, y) in ((24, 8), (27, 8), (24, 10)):
        m.put(x, y, "d"); m.put(x, y + 1 if y < 10 else y - 1, "Z")
    m.put(31, 8, "t"); m.nudge(31, 8, 0, 0, 3)
    m.triggers.append("use 31 8 repeat : program invaders")  # (this terminal runs neon-caster/programs/invaders.bas: beat it, and it pays out)
    m.alcove(26, 1, "S", depth=3, floor=2, ceil=7, deco="F", glow=CYAN, fx=0)
    m.mon(28, 9, "s", sight=12)
    for (x, y, c) in ((17, 9, "g"), (22, 5, "g"), (32, 10, "w"), (15, 2, "e"), (30, 10, "+")):
        m.put(x, y, c)
    m.mon(18, 6, "k", sight=6, hear=8, health=150, speed=120)
    m.light(18.5, 5.5, 6, 130, 90, 200, 255, 1)
    m.light(25.5, 9.5, 6, 130, 200, 230, 255, 0)
    m.triggers += ["clear 14 2 22 10 : item medkit 18 9 ; message RACK ROWS CLEAR - A MEDKIT DROPS",
                   "enter 18 2 22 3 : message A CODE TERMINAL - FACE IT AND PRESS SPACE"]

    # ================================================== ARCADE (north-west, sealed)
    m.room(2, 2, 11, 12, ceil=12, zone=(1, 1))
    m.floor_pic(2, 2, 11, 12, "floor-white.png", checker="floor-circuit.png")
    m.event(4, 2, 2, 11, 12, 30, 0, 14)        # (a shooting gallery: the damage amp)
    for (x, y, c) in ((3, 3, "x"), (6, 3, "o"), (9, 3, "x"), (4, 6, "t"), (8, 6, "Z"), (3, 9, "x"),
                      (6, 9, "o"), (10, 9, "U"), (5, 11, "p")):
        m.put(x, y, c)
    m.nudge(4, 6, 0, 0, 2); m.nudge(10, 9, 2, 0, 3)
    m.put(2, 12, "&")                           # (LINKed by hand to the plaza's)
    m.light(6.5, 7.5, 8, 160, 255, 90, 220, 3)

    # ================================================== SKYDECK (north-east, yellow door)
    m.room(36, 1, 46, 12, floor=-6, ceil=16, zone=(3, 2))   # (the sky low over it: the walls round it end below your eyes on the summit)
    m.event(13, 36, 1, 46, 12, 0, 0)           # (the street: it kills)
    m.rect(35, 7, 35, 7); m.put(34, 7, "Y")
    m.floor(35, 7, 35, 7, 0, only_open=False)
    m.floor(36, 5, 38, 9, 0, only_open=False); m.zone(36, 5, 38, 9, 1, 0)       # roof A (by the door)
    m.stairs(39, 8, 40, 9, "E", 0, 2); m.zone(39, 8, 40, 9, 4, 0)
    m.floor(41, 8, 46, 12, 4, only_open=False); m.zone(41, 8, 46, 12, 1, 0)     # roof B
    up = lift(43, 6, 44, 7, 4, 8, mode=3, speed=5)                               # (called from its consoles)
    m.floor(40, 1, 46, 5, 8, only_open=False); m.zone(40, 1, 46, 5, 1, 0)       # the summit
    m.put(46, 2, "#"); m.put(46, 4, "#"); m.put(46, 3, "E")
    m.put(46, 1, "#"); m.put(46, 5, "#")
    m.post(45, 2, "E", at=6, w=2, d=2, wall=2, glow=GREEN); m.post(45, 4, "E", at=2, w=2, d=2, wall=2, glow=GREEN)
    m.put(46, 9, "A"); m.nudge(46, 9, 2, 0, 3)
    m.put(40, 4, "A"); m.nudge(40, 4, -2, 0, 1)
    m.triggers += ["use 46 9 repeat : liftgo %d up ; sound lift-start ; message THE LIFT RISES" % up,
                   "use 40 4 repeat : liftgo %d down ; sound lift-start ; message THE LIFT COMES DOWN" % up,
                   "enter 36 6 37 8 : message THE SKYDECK - THE STREET IS A LONG WAY DOWN. THE CONSOLES CALL THE LIFT",
                   "enter 41 1 45 5 : sound alarm ; message NEXUS: SO, YOU REACHED THE TOP. NOW FALL."]
    m.put(42, 3, "z")
    m.mon(44, 10, "s", sight=12); m.mon(37, 6, "s", sight=10)
    for (x, y, c) in ((42, 11, "m"), (44, 1, "m"), (45, 11, "*"), (37, 9, "a"), (41, 2, "j")):
        m.put(x, y, c)
    for (x, y) in ((36, 5), (46, 12)):
        m.put(x, y, "i")

    # ================================================== CRYPT (south-west)
    m.room(3, 37, 11, 45, ceil=10, zone=(1, 1))
    for (x, y, c) in ((3, 37, "/"), (3, 45, "\\")):
        m.put(x, y, c)
    m.event(1, 3, 37, 11, 45, 5, 0, 7)         # (an ambush: the scatter gun its prize)
    m.event(6, 3, 38, 6, 44, 0, 0)             # (closets: secret walls slide away)
    for y in (39, 43):
        m.put(2, y, "%"); m.put(1, y, "c")
    for x in (6, 9):
        m.alcove(x, 35, "S", depth=4, floor=0, ceil=7, deco="O", glow=CYAN, fx=5)
    for (x, y, c) in ((5, 41, "V"), (9, 44, "V"), (11, 37, "U"), (11, 45, "Z"), (8, 41, "W"), (10, 40, "e")):
        m.put(x, y, c)
    m.nudge(11, 37, 2, 0, 3)
    m.light(7.5, 41.5, 6, 140, 170, 200, 255, 5)
    crypt_light = len(m.lights)
    m.light(7.5, 38.5, 4, 120, 255, 60, 60, 3)
    m.triggers += ["enter 11 40 11 42 : light %d off ; sound power-down ; message THE CRYPT - SOMETHING ELSE IS DOWN HERE" % crypt_light,
                   "enter 15 40 16 42 : spawn stalker 17 44 1 ; message BEHIND YOU"]

    # ================================================== VAULT (south-east)
    m.event(8, 37, 41, 39, 41, 40, 120)        # (a pressure plate in the corridor)
    m.rect(36, 41, 40, 41)
    m.room(41, 41, 46, 46, ceil=10, zone=(1, 1))
    m.room(41, 36, 46, 39, ceil=10, zone=(2, 1))
    m.put(43, 40, "X")   # (the hoard's: a split door)
    m.event(7, 41, 36, 46, 39, 0, 0)           # (the hoard: sealed till every thief is dead)
    for (x, y, c) in ((42, 37, "q"), (44, 37, "u"), (46, 37, "*"), (43, 38, "j"), (45, 39, "a"), (42, 39, "e"), (46, 39, "2")):
        m.put(x, y, c)
    for (x, y, c) in ((46, 42, "U"), (46, 44, "U"), (41, 46, "f"), (42, 46, "o"), (44, 46, "x"), (43, 43, "g")):
        m.put(x, y, c)
    m.nudge(46, 42, 2, 0, 3); m.nudge(46, 44, 2, 0, 3)
    m.light(43.5, 43.5, 6, 140, 255, 220, 120, 0)
    m.light(43.5, 37.5, 5, 160, 255, 200, 60, 2)
    m.triggers.append("enter 36 41 36 41 : message THE VAULT - WATCH YOUR STEP")

    # ================================================== by hand, and the rest
    m.pads += [(31, 45, 2, 12), (33, 19, 2, 31)]
    m.loot_line("crate    = ammo:30, shells:25, medkit:20, armor:15")
    m.loot_line("barrel   = ammo:15, shells:15, -, -")
    m.loot_line("locker   = armor:40, medkit:30, overcharge:15, amp:10")
    m.loot_line("vending  = ammo:40, shells:30, medkit:15, overcharge:5")
    m.loot_line("desk     = ammo:15, shells:15, medkit:15, -")
    m.loot_line("cryopod  = overcharge:20, medkit:30, -, -")
    m.loot_line("rack     = ammo:30, overcharge:10, -, -")
    # A secret stash in the rock (?), and its way in a red button beside it
    # you shoot - a "shoot" trigger, "secret" in its commands
    sx, sy, dx, dy = lvlkit.carve_stash(m, "qu")
    bx, by = sx + dy, sy + dx  # (the wall along from it)
    m.face(bx, by, {(1, 0): "W", (-1, 0): "E", (0, 1): "N", (0, -1): "S"}[(dx, dy)], "wall-switch.png")
    m.triggers.append("shoot %d %d : secret %d %d" % (bx, by, sx, sy))
    # The armoury, all over: a wall turret of every weapon, the rocket
    # launcher, and rockets for it (newsectors' arm, placed by its rules)
    ns.ARMS[24] = dict(turrets=[0, 1, 2, 3, 4, 5, 6], launcher=1, rockets=3)
    ns.arm(m, 24)
    m.headroom(8)
    return m


def build(write=False, show=False):
    m = expo()
    lv = m.level(LABEL, NAME, WALLS, FLOORS, CEILS)
    if show:
        m.show()
    good = check_level(lv, ASSETS)
    errs, _ = ns.reach_with_blocks(lv)
    for e in errs: print("  BLOCKED:", e)
    herrs, _ = lvlkit.check_heights(lv)
    for e in herrs: print("  HEIGHTS ERROR", e)
    good = good and not errs and not herrs
    pics, glows = m.slots()
    c = ns.counts(m)
    kinds = sorted({e[0] for e in m.events})
    print("  slots %d+%d of 24; items %d, monsters %d, decorations %d, lights ~%d, events %d (kinds %s), lifts %d, triggers %d, blocks %d, nudges %d"
          % (pics, glows, c["items"], c["mons"], c["decos"], c["lights"], len(m.events), kinds, len(m.lifts), len(m.triggers), len(m.blocks), len(m.nudges)))
    for what, k, mx in (("slots", pics + glows, 24), ("items", c["items"], 64), ("monsters", c["mons"], 64), ("decorations", c["decos"], 64),
                        ("lights", c["lights"], 96), ("events", len(m.events), 16), ("lifts", len(m.lifts), 16),
                        ("triggers", len(m.triggers), 48), ("nudges", len(m.nudges), 64)):
        if k > mx:
            print("  TOO MANY %s: %d (max %d)" % (what, k, mx)); good = False
    rows = "".join(lv["rows"])
    missing = [ch for ch in "rbyM+*uae234qj)(mghcskwzT|oiptxlnfSdAFIJLOQUWZV/\\%?=@$&!DHXRBYE" if ch not in rows]
    if missing:
        print("  NOT USED YET:", " ".join(missing))
    if len(kinds) < 13:
        print("  EVENT KINDS MISSING:", [k for k in range(1, 14) if k not in kinds])
    good = good and not ns.PROBLEMS
    if write and good:
        doc = [l.strip() for l in __doc__.strip().splitlines()[:1]] + ["Built by megasector.py: every feature of the game in one sector."]
        write_level_file(OUT, lv, doc)
        print("wrote", OUT)
    print("ALL GOOD" if good else "PROBLEMS")
    return good


if __name__ == "__main__":
    args = sys.argv[1:]
    sys.exit(0 if build("--write" in args, "-show" in args) else 1)
