"""SECTOR 28: THE MONOLITH - the biggest sector the game holds: 256 x 256
cells, the ceiling at its highest (240 eighths: 30 walls) over a hall 240
cells across, and in its middle a stepped pyramid climbing in 2-eighth
steps (you can walk all the way up) to 200 eighths, and on its top a lift
up to 228 - 28 1/2 walls - with a reward by it. Round it, four sunken
pools of each depth down to a bottomless pit, rows of lamps, and the exit
in the north wall.

    python3 giant.py            build it and check it
    python3 giant.py --write    ...and write custom/custom18.txt (YOUR SECTORS 28)
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit

N = 256
C = N // 2          # (the middle)
TOP = 240           # (the ceiling: as high as the game goes, H_MAX)
RINGS = 100         # (the pyramid's steps out from its top)
OUT = os.path.join(HERE, "custom", "custom18.txt")
H_UP = lvlkit.H_UP


def code(e):
    """A height (eighths) as the file has it: its [floor] / [ceiling]
    character, and its [... high] digit (how many 36s more)."""
    if e < 0:
        return "ABCDEFGH"[-e - 1], "0"
    return H_UP[e % 36], str(e // 36)


def build():
    g = [["#"] * N for _ in range(N)]
    fl = [[0] * N for _ in range(N)]
    ce = [[8] * N for _ in range(N)]
    # The hall: cells 8 to N - 9 each way, its ceiling 30 walls up
    for y in range(8, N - 8):
        for x in range(8, N - 8):
            g[y][x] = "."
            ce[y][x] = TOP
    # The pyramid: ring by ring up from its foot (RINGS cells out) to its top, 2 eighths a step
    cx = cy = C
    for y in range(N):
        for x in range(N):
            r = max(abs(x - cx), abs(y - cy))
            if r <= RINGS and g[y][x] == ".":
                fl[y][x] = 2 * (RINGS - r)
    # Sunken pools in three corners, stepping down 2 eighths a ring (so you
    # can climb out) to -2, -4 and -7 - and in the fourth, a bottomless pit
    a, b = 13, N - 14
    for (px, py, d) in ((a, a, -2), (b, a, -4), (a, b, -7)):
        for y in range(py - 3, py + 4):
            for x in range(px - 3, px + 4):
                r = max(abs(x - px), abs(y - py))
                fl[y][x] = max(d, -2 * (4 - r))
    for y in range(b - 3, b + 3):
        for x in range(b - 3, b + 3):
            fl[y][x] = -8
    # You, at the south wall facing north; the exit in the north wall
    g[N - 10][C] = "^"
    g[7][C] = "E"
    # On top: the reward - and on the way up, things to fight
    g[C - 2][C] = "q"; g[C - 2][C - 1] = "("; g[C - 2][C + 1] = ")"  # (by the lift, on the pyramid's top)
    k = N / 128.0
    for (x, y, c) in ((40, 90, "g"), (88, 90, "g"), (64, 100, "h"), (30, 64, "s"), (98, 64, "s"), (64, 40, "w"), (50, 50, "m"), (78, 78, "m"),
                      (64, 110, "g"), (20, 64, "h"), (108, 64, "h"), (45, 30, "m"), (83, 30, "m"), (64, 75, "s"), (75, 64, "w"), (53, 64, "w"),
                      (20, 100, "+"), (108, 100, "+"), (20, 28, "a"), (108, 28, "e"), (64, 20, "u"), (64, 88, "+"), (40, 64, "a"), (88, 64, "e"), (60, 118, "M")):
        g[int(y * k)][int(x * k)] = c
    # Lamps round the hall, and down the pyramid's four faces
    lights = []
    for p in range(12, N - 11, 20):
        for (lx, ly) in ((p, 11), (p, N - 12), (11, p), (N - 12, p)):
            lights.append((lx + 0.5, ly + 0.5, 10, 170, 220, 230, 255, 0))
    for r in range(RINGS - 4, 5, -10):
        for (lx, ly) in ((cx, cy - r), (cx, cy + r), (cx - r, cy), (cx + r, cy), (cx - r, cy - r), (cx + r, cy + r), (cx - r, cy + r), (cx + r, cy - r)):
            lights.append((lx + 0.5, ly + 0.5, 8, 160, 255, 120, 220, 2))
    lights.append((cx + 0.5, cy + 0.5, 8, 200, 255, 230, 120, 2))
    # On the top (2 * RINGS eighths, 25 walls), a lift: step on and it takes
    # you up near the ceiling, 28 1/2 walls up
    lo = 2 * (RINGS - 2)
    lifts = [(C - 1, C - 1, C + 1, C + 1, lo, TOP - 12, 2, 8)]  # (from the step round it to under the ceiling)
    return g, fl, ce, lights, lifts


def text(g, fl, ce, lights, lifts):
    o = []
    o.append("' NEON-CASTER level file - made by levels/giant.py: the biggest sector the game holds")
    o.append("' (%d x %d, ceiling %d eighths - %d walls - and a pyramid you climb, and a lift to %d)." % (N, N, TOP, TOP // 8, TOP - 12))
    o.append("")
    o.append("name     = SECTOR 28: THE MONOLITH")
    o.append("walls    = wall-obsidian.png, wall-concrete.png, wall-core.png, wall-servers.png, wall-tiles.png, wall-white.png")
    o.append("floors   = floor-plates.png, floor-circuit.png, floor-glow.png, floor-concrete.png")
    o.append("ceilings = ceiling-lights.png, ceiling-core.png")
    o.append("ambient  = 150, 200, 210, 255")
    o.append("")
    o.append("[lights]")
    o.append("' x, y, radius, brightness, red, green, blue, effect")
    for l in lights:
        o.append(", ".join(("%g" % v) for v in l))
    o.append("")
    o.append("[lifts]")
    o.append("' x0, y0, x1, y1, low, high (eighths), mode (2 an elevator), speed")
    for l in lifts:
        o.append(", ".join(str(v) for v in l))
    o.append("")
    o.append("[map]")
    o += ["".join(r) for r in g]
    o.append("")
    lo = lambda rows, dflt: ["".join("." if v == dflt else code(v)[0] for v in r) for r in rows]
    hi = lambda rows: ["".join(code(v)[1] if v >= 0 else "0" for v in r) for r in rows]
    o.append("[floor]")
    o += lo(fl, 0)
    o.append("")
    o.append("[floor high]")
    o += hi(fl)
    o.append("")
    o.append("[ceiling]")
    o += lo(ce, 8)
    o.append("")
    o.append("[ceiling high]")
    o += hi(ce)
    return "\n".join(o) + "\n"


if __name__ == "__main__":
    g, fl, ce, lights, lifts = build()
    t = text(g, fl, ce, lights, lifts)
    tmp = OUT + ".check"
    open(tmp, "w").write(t)
    lv = lvlkit.read_level_file(tmp, "monolith")
    ok = lvlkit.check_level(lv, os.path.dirname(HERE))
    os.remove(tmp)
    print("size", lvlkit.N, "- top of the pyramid:", lvlkit.hval(lv["floor"][C - 2][C], 0), "eighths, ceiling", lvlkit.hval(lv["ceiling"][C][C], 8))
    if "--write" in sys.argv:
        open(OUT, "w").write(t)
        print("wrote", OUT)
    print("ALL GOOD" if ok else "PROBLEMS")
