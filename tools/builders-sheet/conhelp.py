# conhelp.py: the console's own help (MENU/CONSOLE.BM's ConHelp) read into
# groups and commands, for the builder's sheet.
import re

import os
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "MENU", "CONSOLE.BM")
# What the help's numbers come from, as the game has them
KNOWN = {
    "NUM_LEVELS": "10", "MAP_SIZE": "256", "MAX_ALIAS": "64", "NUM_LEVELS + 1": "11",
    "CHR$(34)": '"', "DRAIN_SPEED": "4", "MAX_CUSTOM": "30", "NUM_LEVELS + MAX_CUSTOM": "40",
    "NUM_SLOTS": "3", "MAX_DROIDS": "12",
    "KeyName$(keyBind&(BIND_FLASH))": "L (as made)",
    "GlassStyleList$": "0 streaks, 1 clear, 2 sheer, 3 panes, 4 grid, 5 bricks, 6 leaded, 7 privacy",
    "RTRIM$(t$)": "^81 ^7drone  ^82 ^7gunner  ^83 ^7heavy  ^84 ^7crawler  ^85 ^7sentry  ^86 ^7stalker  ^87 ^7spitter  ^88 ^7overseer  ^89 ^7thief  ^810 ^7ice  ^811 ^7sniper  ^812 ^7trooper  ^813 ^7ripper  ^814 ^7warden  ^815 ^7colossus  ^816 ^7turret  ^817 ^7mimic  ^818 ^7robodog  ^819 ^7guard  ^820 ^7eyebot",
}

def split_plus(e):
    """Top-level + pieces of a QB64 string expression."""
    out, cur, q, d = [], "", False, 0
    for ch in e:
        if ch == '"':
            q = not q
        elif not q and ch == "(":
            d += 1
        elif not q and ch == ")":
            d -= 1
        if ch == "+" and not q and d == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out

def value(piece):
    if piece.startswith('"') and piece.endswith('"') and piece.count('"') == 2:
        return piece[1:-1]
    m = re.fullmatch(r'(?:LTRIM\$\()?STR\$\((.+?)\)\)?', piece)
    if m:
        k = m.group(1).strip()
        v = KNOWN.get(k)
        if v is not None:
            return v if piece.startswith("LTRIM") else " " + v
    if piece in KNOWN:
        return KNOWN[piece]
    return None  # worked out as the game runs

def conprints(stmt):
    """The text of every ConPrint in one line of code (statements joined by : outside quotes)."""
    parts, cur, q = [], "", False
    for ch in stmt:
        if ch == '"':
            q = not q
        if ch == ":" and not q:
            parts.append(cur); cur = ""
        else:
            cur += ch
    parts.append(cur)
    out = []
    for p in parts:
        p = p.strip()
        m = re.search(r"\bConPrint\s+(.*)$", p)
        if not m:
            continue
        e = m.group(1)
        # a trailing comment (outside quotes)
        q, cut = False, None
        for i, ch in enumerate(e):
            if ch == '"':
                q = not q
            if ch == "'" and not q:
                cut = i; break
        if cut is not None:
            e = e[:cut]
        vals = [value(x) for x in split_plus(e.strip())]
        if all(v is None for v in vals):
            continue
        out.append("".join("…" if v is None else v for v in vals))
    return out

def read():
    lines = open(SRC, encoding="utf-8", errors="replace").read().split("\n")
    s = next(i for i, l in enumerate(lines) if l.startswith("SUB ConHelp"))
    e = next(i for i in range(s, len(lines)) if lines[i].startswith("END SUB"))
    overview, cmds, cur, group = [], [], None, None
    for l in lines[s + 1:e]:
        st = l.strip()
        if st.startswith("' ---"):
            group = st[5:].strip()
            continue
        m = re.match(r'CASE\s+((?:"[^"]*"\s*,?\s*)+)(?::\s*(.*))?$', st)
        if m and l.startswith("        CASE"):
            names = re.findall(r'"([^"]*)"', m.group(1))
            if names == [""]:
                cur = dict(names=[""], lines=overview, group="")
            else:
                cur = dict(names=names, lines=[], group=group or "")
                cmds.append(cur)
            if m.group(2):
                cur["lines"] += conprints(m.group(2))
            continue
        if st.startswith("CASE ELSE") or st.startswith("END SELECT"):
            cur = None
            continue
        if cur is not None:
            cur["lines"] += conprints(st)
    return overview, [c for c in cmds if c["lines"]]

if __name__ == "__main__":
    ov, cmds = read()
    print(len(ov), "overview lines,", len(cmds), "commands")
    for c in cmds:
        for t in c["lines"]:
            if "…" in t:
                print("DYN", c["names"][0], t[:120])
