"""SECTOR 29: THE STOCKPILE (custom/custom19.txt) - a showcase for the
barrels of liquid (one map character, :, its liquid and stack in
[barrels]), treasure chests ([), mimics (]) and the jetpack (` and its
fuel ,). Built with the level kit, and checked by it.

    python3 stockpile.py [OUTDIR]     (OUTDIR: custom/ unless you say)

This writes over custom19.txt: once you've changed it in the game's
editor, don't run it again (or give it another OUTDIR).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from showcase import Show, build

WATER, POISON, SLIME, LAVA, ACID = 1, 2, 3, 4, 5


def stockpile():
    """SECTOR 29: THE STOCKPILE. A storehouse three walls high round an
    atrium twelve high. West: the barrel yard - drums of water, poison,
    slime, lava and acid, stacked up to three high, with gunners and
    crawlers among them (a shot drum leaks, hisses, then bursts: its
    blast, a pool of what was in it, and its own harm - lava sets them
    alight, poison leaves a cloud). East: the vault - treasure chests to
    open with Space, and two that aren't (look at their locks). In the
    atrium: a jetpack and fuel, and up on the ledge six walls high, the
    red card - fly up (E, C down), or take the lift. The exit is through
    the red door off the ledge."""
    m = Show("#")
    m.ambient = (130, 255, 225, 190)
    m.barrels = []
    # The start, behind a door
    m.rect(20, 38, 28, 44)
    m.put(24, 43, "^")
    m.put(24, 37, "D")
    m.ceiling(20, 37, 28, 44, 16)
    # The storehouse, three walls high; the atrium twelve
    m.rect(6, 14, 42, 36)
    m.ceiling(6, 14, 42, 36, 24)
    m.ceiling(18, 14, 30, 30, 96, only_raise=False)
    # The ledge, six walls up, across the atrium's north end - and a lift up to it
    m.floor(18, 14, 30, 17, 48)
    m.lift(29, 18, 29, 18, 0, 48, mode=2, speed=8)
    m.put(24, 15, "r")
    m.put(19, 15, "+"); m.put(29, 15, "a")
    # Off the ledge: the red door, the way out
    m.rect(23, 8, 25, 12)
    m.floor(23, 8, 25, 12, 48)
    m.ceiling(23, 8, 25, 13, 64, only_raise=False)
    m.put(24, 13, "R"); m.fh[13][24] = lvlkit.hchar(48); m.ch[13][24] = lvlkit.hchar(64, ceiling=True)
    m.put(24, 7, "E"); m.fh[7][24] = lvlkit.hchar(48); m.ch[7][24] = lvlkit.hchar(64, ceiling=True)  # (the exit, as high as the way to it)
    # The jetpack and its fuel, on the atrium floor
    m.put(24, 28, "`")
    for (x, y) in ((20, 26), (28, 26), (22, 22), (26, 22)):
        m.put(x, y, ",")
    # The barrel yard (west): every liquid, stacked 1-3, and plain ones
    yard = [(8, 17, WATER, 1), (11, 17, POISON, 2), (14, 17, LAVA, 3),
            (8, 21, SLIME, 2), (11, 21, ACID, 1), (14, 21, POISON, 3),
            (8, 25, LAVA, 1), (11, 25, WATER, 3), (14, 25, SLIME, 1),
            (8, 29, ACID, 3), (11, 29, LAVA, 2), (14, 29, WATER, 2),
            (8, 33, POISON, 1), (11, 33, SLIME, 3), (14, 33, ACID, 2)]
    for (x, y, lq, st) in yard:
        m.put(x, y, ":")
        m.barrels.append((x, y, lq, st))
    for (x, y, st) in ((16, 19, 3), (16, 27, 2), (7, 35, 3)):
        m.put(x, y, "o"); m.barrels.append((x, y, 0, st))
    for (x, y) in ((10, 19), (13, 23), (9, 27), (12, 31)):
        m.mon(x, y, "g")
    for (x, y) in ((15, 23), (10, 35)):
        m.mon(x, y, "c")
    # The vault (east): chests - and two mimics
    for (x, y) in ((35, 16), (39, 16), (35, 22), (39, 28), (41, 34)):
        m.put(x, y, "[")
    for (x, y) in ((39, 22), (35, 28)):
        m.mon(x, y, "]")
    m.mon(37, 33, "k")
    # Pickups about the place
    m.put(21, 35, "3"); m.put(27, 35, "{"); m.put(33, 35, "M"); m.put(17, 35, "+"); m.put(31, 25, "e")
    # Light
    for x in (10, 24, 38):
        for y in (18, 26, 33):
            m.light(x + 0.5, y + 0.5, 8, 160, 255, 220, 180, 0)
    m.light(24.5, 15.5, 6, 170, 255, 70, 70, 2)      # the red card on the ledge: red, pulsing
    m.light(24.5, 10.5, 5, 150, 120, 255, 160, 0)
    m.light(24.5, 41.5, 6, 150, 200, 220, 255, 0)
    m.light(24.5, 28.5, 5, 200, 255, 160, 60, 4)     # the jetpack: firelight
    m.zone(6, 14, 42, 36, 1, 1)
    m.zone(18, 14, 30, 30, 2, 2)
    m.zone(18, 14, 30, 17, 3, 0)
    m.zone(32, 14, 42, 36, 4, 0)
    m.triggers.append("enter 6 14 17 36 : message THE BARREL YARD - a shot drum leaks, hisses, then bursts. Stand back.")
    m.triggers.append("enter 32 14 42 36 : message THE VAULT - Space opens a chest. Look at the locks before you do.")
    m.triggers.append("enter 18 18 30 30 : message THE ATRIUM - a jetpack: E flies you up, C down, while the fuel lasts")
    return m, "custom19", "SECTOR 29: THE STOCKPILE", \
        ["wall-girders.png", "wall-rusty.png", "wall-hazard.png", "wall-concrete.png", "wall-pipes.png", "wall-servers.png"], \
        ["floor-concrete.png", "floor-platform.png", "floor-hazard.png", "floor-rustgrate.png"], \
        ["ceiling-girders.png", "ceiling-pipes.png"], stockpile.__doc__


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else os.path.join(HERE, "custom")
    os.makedirs(out, exist_ok=True)
    import showcase
    orig = Show.level

    def level(self, *a):  # (the [barrels] lines as well)
        lv = orig(self, *a)
        lv["barrels"] = list(getattr(self, "barrels", []))
        return lv
    Show.level = level
    print("stockpile")
    print("ALL GOOD" if build(stockpile, out) else "PROBLEMS")
