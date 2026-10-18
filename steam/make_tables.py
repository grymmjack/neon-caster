"""Write steam/achievements.csv and steam/stats.csv from the game's AchDef
lines (ACH/ACHIEVEMENTS.BM) - what to enter in the Steamworks admin (Stats & Achievements),
in the game's own words, so the two can't drift apart.

    python3 steam/make_tables.py
"""
import re, os, csv
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "..", "ACH", "ACHIEVEMENTS.BM")).read()
rows, stats = [], []
for m in re.finditer(r'AchDef "(\w+)", "([^"]*)", "([^"]*)", (-?\d+), "(\w*)", (\d+)', src):
    api, title, desc, hidden, stat, goal = m.groups()
    rows.append((api, title, desc, "yes" if hidden != "0" else "no", stat, goal if stat else "",
                 "achievements/%s.jpg" % api, "achievements/%s_locked.jpg" % api))
    if stat and stat not in stats:
        stats.append(stat)
with open(os.path.join(HERE, "achievements.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["API name", "Display name", "Description", "Hidden", "Progress stat", "Goal", "Achieved icon", "Unachieved icon"])
    w.writerows(rows)
with open(os.path.join(HERE, "stats.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["API name", "Type", "Set by", "Increment only", "Notes"])
    for s in stats:
        note = "a set of things, one bit each (count the bits)" if s in ("SetsDone", "Showcases", "KillKinds") else "a count"
        w.writerow([s, "INT", "Client", "yes", note])
print("%d achievements, %d stats" % (len(rows), len(stats)))
