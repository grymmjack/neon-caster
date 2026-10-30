"""SECTOR 31: THE LAUNCH BAY (custom/custom21.txt) - a showcase for getting
about in the air: jump pads (two set as they're built, one set from its
launch control - work its numbers out from the note), the sector's own
gravity (60%), jumping, the jetpack and its fuel cans, a pool that goes
from clear to solid across, floors from dry to soaked. Built with the
level kit, and checked by it.

    python3 launchbay.py [OUTDIR]     (OUTDIR: custom/ unless you say)

This writes over custom21.txt: once you've changed it in the game's
editor, don't run it again (or give it another OUTDIR).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from showcase import Show, build

GRAVITY = 60  # percent: the bay's own - every other sector is 100
WETNESS = 3   # the bay's floors, 0 dry - 9 soaked (cells of their own below)


def launchbay():
    """SECTOR 31: THE LAUNCH BAY. A cargo bay under 60% gravity, eight
    walls high, a lava channel across it. Jump pads throw you over: the
    west one as it's set, the east one high - into the water pool, the
    soft way down - and the middle one wherever its launch control says.
    The note by the start has the cargo platform's place and the sum; set
    the pad and ride it up there. The jetpack (fuel cans by the start)
    gets you onto the ledge in the north-west. A walker that steps on a
    pad comes after you; eyebots wait over the far side - shoot them
    before they dive at you. The pool's water goes from clear to solid across;
    the floors from dry by the start to soaked by the pool. The exit's in
    the east wall, past the lava."""
    m = Show("#")
    m.ambient = (120, 220, 235, 255)
    m.doors, m.things, m.notes, m.smears, m.fuel = [], [], [], [], []

    def thing(x, y, kind, *more):
        m.put(x, y, '"')
        m.things.append(", ".join([str(x), str(y), kind] + [str(v) for v in more]))

    # The start: the launch control's room, the note, the jetpack and fuel
    m.rect(18, 38, 30, 44)
    m.put(24, 43, "^")
    m.rect(23, 36, 25, 37)  # (the way into the bay)
    m.put(22, 40, "'")
    m.notes.append("22, 40, -, LAUNCH CONTROL - cargo platform.|The platform's due north of the middle pad, 22 cells on.|"
                   "Bay gravity: %d%%.|How far a pad throws you: POWER x POWER x SIN(2 x ANGLE) / (100 x GRAVITY%%).|"
                   "DIR 270 is north. ANGLE 45 goes furthest." % GRAVITY)
    m.put(20, 42, "`")  # the jetpack
    m.put(19, 39, ","); m.put(29, 42, ","); m.put(29, 39, ",")
    m.fuel += ["19, 39, 25", "29, 42, 60"]  # (and 29, 39: a can as made, 40)
    m.put(27, 42, "+"); m.put(21, 44, "a")
    # The bay: eight walls high, the lava channel across it
    m.rect(3, 6, 44, 35)
    m.ceiling(3, 6, 44, 35, 64)
    for x in range(3, 45):
        for y in range(18, 22):
            m.liquid(x, y, "l", 2)
    # The pads, south of the lava: west as it's set; middle - its launch
    # control's (set wrong at first); east, high, into the pool
    thing(10, 30, "jumppad", 270, 45, 30)
    thing(24, 30, "jumppad", 0, 45, 20)
    thing(26, 33, "padpc", 24, 30)
    thing(38, 30, "jumppad", 270, 60, 32)
    # The cargo platform (north, a wall up): only the middle pad gets you there
    m.floor(21, 6, 27, 11, 8)
    m.put(24, 7, "q"); m.put(22, 7, "5"); m.put(26, 7, "("); m.put(23, 8, "u")
    # The ledge (north-west, four walls up): the jetpack's
    m.floor(3, 6, 8, 10, 32)
    m.put(5, 8, "j"); m.put(6, 7, "M")
    # The pool (north-east), where the east pad lands you: clear - murky - solid, west to east
    for y in range(11, 17):
        for x in range(34, 43):
            m.liquid(x, y, "w", 4)
    m.opacity = {(x, y): ("." if x < 37 else ("5" if x < 40 else "x")) for x in range(34, 43) for y in range(11, 17)}
    m.wet = {}
    for y in range(38, 45):  # the start room: dry
        for x in range(18, 31):
            m.wet[(x, y)] = "0"
    for y in range(9, 18):  # round the pool: soaked
        for x in range(32, 45):
            if (x, y) not in m.opacity:
                m.wet[(x, y)] = "9"
    for x in range(3, 45):  # the lava's banks: steaming dry
        m.wet[(x, 17)] = m.wet.get((x, 17), "1"); m.wet[(x, 22)] = "1"
    # Who's here: gunners up north to shoot you in the air; walkers that follow you over
    for (x, y, c) in ((12, 12, "g"), (36, 8, "g"), (18, 14, "g"), (8, 32, "m"), (40, 33, "m"), (30, 12, "c")):
        m.mon(x, y, c)
    m.put(15, 25, "+"); m.put(33, 26, "a"); m.put(10, 14, "e")
    # Eyebots: flying eyes over the far side - they zap you in the air, then dive at you and blow up
    thing(16, 11, "eyebot"); thing(31, 14, "eyebot"); thing(40, 8, "eyebot")
    # The way out: the exit in the east wall, past the lava
    m.put(45, 12, "E")
    # Light
    for (x, y) in ((10, 27), (24, 27), (38, 27), (10, 12), (24, 12), (38, 12)):
        m.light(x + 0.5, y + 0.5, 8, 150, 200, 235, 255, 0)
    for x in (8, 18, 30, 40):
        m.light(x + 0.5, 19.5, 4, 170, 255, 120, 40, 4)  # the lava's glow
    m.light(24.5, 41.5, 6, 150, 230, 230, 255, 0)
    m.light(39.5, 14.5, 5, 140, 80, 180, 255, 2)  # the pool, pulsing blue
    m.triggers.append("enter 3 23 44 35 : message THE BAY - step on a pad. The middle one goes where its launch control says.")
    m.triggers.append("enter 21 6 27 11 : message THE CARGO PLATFORM - you did the sums.")
    m.zone(18, 38, 30, 44, 1, 1)
    m.zone(3, 6, 44, 35, 2, 0)
    return m, "custom21", "SECTOR 31: THE LAUNCH BAY", \
        ["wall-girders.png", "wall-hazard.png", "wall-pipes.png", "wall-concrete.png", "wall-servers.png", "wall-grate.png"], \
        ["floor-platform.png", "floor-plates.png", "floor-hazard.png", "floor-deck.png"], \
        ["ceiling-girders.png", "ceiling-pipes.png"], launchbay.__doc__


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else os.path.join(HERE, "custom")
    os.makedirs(out, exist_ok=True)
    orig = Show.level

    def level(self, *a):  # (its [doors], [things], [notes], [smears], [fuel]; the pools, how see-through; the sector's gravity and wetness)
        lv = orig(self, *a)
        for s in lvlkit.XTRA:
            lv[s] = list(getattr(self, s, []))
        N = lvlkit.N
        lv["liquid"] = ["".join(r) for r in self.lq]
        lv["liquid_depth"] = ["".join(r) for r in self.ld]
        op = getattr(self, "opacity", {})
        lv["liquid_opacity_rows"] = ["".join(op.get((x, y), ".") for x in range(N)) for y in range(N)]
        wet = getattr(self, "wet", {})
        lv["wetness_rows"] = ["".join(wet.get((x, y), ".") if self.g[y][x] not in lvlkit.WALLS else "." for x in range(N)) for y in range(N)]
        lv["gravity"] = GRAVITY
        lv["wetness"] = WETNESS
        return lv
    Show.level = level
    print("launchbay")
    print("ALL GOOD" if build(launchbay, out) else "PROBLEMS")
