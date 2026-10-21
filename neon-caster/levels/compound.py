"""SECTOR 30: THE COMPOUND (custom/custom20.txt) - a showcase for the
security pieces: stronghold doors (kick them down), keypad doors and safes
(their codes made up each time - notes tell them), barred windows,
searchable desks and bookshelves, a broken computer and the repair kit that
fixes it (then hack it), security cameras and their monitor, invulnerability,
robot guard dogs, tables on their sides for cover, blood and oil. Built with
the level kit, and checked by it.

    python3 compound.py [OUTDIR]     (OUTDIR: custom/ unless you say)

This writes over custom20.txt: once you've changed it in the game's
editor, don't run it again (or give it another OUTDIR).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lvlkit
from showcase import Show, build


def compound():
    """SECTOR 30: THE COMPOUND. A security compound gone quiet. From the
    guard post (a monitor shows its cameras), out into the yard - tables
    on their sides for cover, troopers, guards who run for the alarm
    switches (the guard post's console turns them off), and the robot dogs
    that bark the place awake. West, the cell block behind a stronghold door: kick it
    in (there's a repair kit in there). North, the server office: search
    its shelves, open its safe (a desk in the guard post knows the code),
    fix the broken computer and hack it - it opens the vault, and the red
    card in it. The armory's code is on a note in the guard post. The exit
    is behind the red door, east of the yard."""
    m = Show("#")
    m.ambient = (120, 235, 230, 220)
    m.doors, m.things, m.notes, m.smears = [], [], [], []

    def thing(x, y, kind, *more):
        m.put(x, y, '"')
        m.things.append(", ".join([str(x), str(y), kind] + [str(v) for v in more]))

    # The guard post (the start): a desk, a note, the cameras' monitor
    m.rect(19, 37, 28, 44)
    m.put(23, 43, "^")
    m.put(26, 38, "d")
    m.notes.append("26, 38, -, Office safe: {code 25 11}|The vault's on the server room computer - if anyone ever fixes it.")
    m.put(25, 42, "M")
    m.put(22, 40, "'")
    m.notes.append("22, 40, robodog.png, Armory code changed again: {code 34 21}.|Keep the dogs fed. Don't go in the yard after dark.|- Sgt. Ivers")
    thing(20, 38, "secmon")
    thing(28, 43, "camera", "GUARD POST")
    m.put(24, 36, "D")
    m.smears.append("24, 39, F, oil2")
    # The yard: tables on their sides, troopers, dogs, bodies, blood
    m.rect(2, 22, 38, 35)
    for (x, y) in ((16, 30), (22, 28), (30, 30), (26, 25), (13, 26), (35, 27)):
        thing(x, y, "table")
    for (x, y, c) in ((14, 24, "5"), (34, 24, "5"), (20, 23, "g"), (29, 33, "g")):
        m.mon(x, y, c)
    thing(12, 33, "robodog"); thing(36, 33, "robodog"); thing(24, 31, "robodog")
    thing(18, 26, "deadguard"); thing(33, 29, "deadscientist"); thing(27, 34, "brokenmonitor")
    thing(2, 23, "camera", "YARD WEST"); thing(38, 23, "camera", "YARD EAST")
    # Alarms: a switch on the yard's north wall and one by the armory; guards run for them.
    # The guard post's console switches them off (and on)
    thing(16, 22, "alarm"); thing(30, 22, "alarm")
    thing(21, 23, "guard"); thing(31, 31, "guard"); thing(9, 28, "guard")
    thing(27, 38, "alarmpc")
    m.triggers.append("alarm : message ALARM - the compound's waking up. The guard post's console shuts it off.")
    m.smears += ["20, 32, F, blood1", "31, 27, F, blood2", "26, 33, F, oil1", "18, 27, F, blood3", "1, 30, E, blood2", "39, 31, W, oil1"]
    m.put(11, 34, "+"); m.put(37, 34, "e"); m.put(25, 34, "a")
    # The cell block (west): a stronghold door, and bars to look in through
    m.rect(2, 10, 9, 20)
    m.put(6, 21, "D"); m.doors.append("6, 21, 6,")
    m.put(4, 21, "-"); m.put(8, 21, "-")
    for x in (4, 7):
        m.put(x, 15, "#")
        m.put(x, 16, "#")
    thing(3, 12, "repairkit"); thing(8, 12, "deadcyborg"); thing(5, 18, "table")
    m.put(3, 18, "+"); m.put(8, 18, "u")
    m.smears += ["6, 9, S, blood1", "9, 11, F, blood3", "1, 12, E, blood2"]
    # The armory (north-east): a keypad door - its code on the guard post's note
    m.rect(30, 10, 38, 20)
    m.put(34, 21, "D"); m.doors.append("34, 21, 0, ?")
    m.put(32, 12, ")"); m.put(33, 12, "("); m.put(35, 12, "("); m.put(37, 15, "u")
    thing(36, 18, "invuln")
    thing(30, 19, "camera", "ARMORY")
    # The server office (north): shelves to search, a safe, the broken computer
    m.rect(14, 10, 26, 20)
    m.put(20, 21, "D")
    thing(14, 11, "bookshelf"); thing(14, 14, "bookshelf"); thing(14, 17, "bookshelf")
    m.notes.append("14, 14, -, Repair kits went to the cell block. Don't ask why.")
    thing(20, 11, "brokenpc", 20, 9)
    thing(25, 11, "safe", "?")
    m.put(17, 16, "d"); thing(23, 16, "brokenmonitor"); thing(25, 20, "camera", "SERVERS")
    m.smears += ["22, 18, F, oil2"]
    # The vault (behind the office): only the computer opens it - or 10 good kicks
    m.rect(17, 4, 23, 8)
    m.put(20, 9, "D"); m.doors.append("20, 9, 10, ?")
    m.put(20, 5, "r"); m.put(18, 5, "q"); m.put(22, 5, "*")
    # The way out (east of the yard): the red door
    m.rect(40, 26, 44, 30)
    m.put(39, 28, "R")
    m.put(45, 28, "E")
    # Light
    for (x, y) in ((23, 40), (15, 25), (24, 25), (33, 25), (15, 32), (24, 32), (33, 32)):
        m.light(x + 0.5, y + 0.5, 7, 150, 230, 235, 255, 0)
    m.light(5.5, 13.5, 6, 140, 255, 120, 90, 1)        # the cells: a failing tube
    m.light(34.5, 15.5, 6, 160, 255, 200, 120, 0)
    m.light(20.5, 15.5, 7, 150, 120, 220, 255, 0)
    m.light(20.5, 6.5, 5, 170, 255, 70, 70, 2)        # the vault: the red card, pulsing
    m.light(42.5, 28.5, 5, 160, 120, 255, 160, 0)
    m.triggers.append("enter 2 22 38 35 : message THE YARD - the dogs bark the place awake. Tables make good cover.")
    m.triggers.append("enter 2 10 9 20 : message THE CELL BLOCK")
    m.triggers.append("hack 20 11 : message SERVER ROOM: VAULT UNLOCKED")
    m.zone(19, 37, 28, 44, 1, 1)
    m.zone(2, 22, 38, 35, 2, 0)
    m.zone(2, 10, 9, 20, 3, 1)
    m.zone(14, 10, 26, 20, 4, 1)
    return m, "custom20", "SECTOR 30: THE COMPOUND", \
        ["wall-concrete.png", "wall-hazard.png", "wall-servers.png", "wall-girders.png", "wall-pipes.png", "wall-grate.png"], \
        ["floor-concrete.png", "floor-plates.png", "floor-hazard.png", "floor-deck.png"], \
        ["ceiling-pipes.png", "ceiling-girders.png"], compound.__doc__


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else os.path.join(HERE, "custom")
    os.makedirs(out, exist_ok=True)
    orig = Show.level

    def level(self, *a):  # (its [doors], [things], [notes], [smears] as well)
        lv = orig(self, *a)
        for s in lvlkit.XTRA:
            lv[s] = list(getattr(self, s, []))
        return lv
    Show.level = level
    print("compound")
    print("ALL GOOD" if build(compound, out) else "PROBLEMS")
