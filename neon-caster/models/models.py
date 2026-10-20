#!/usr/bin/env python3
"""NEON-CASTER's 3D props: decorations and pickups as models.

  python3 models.py            list the props, and which have a model
  python3 models.py --write    write every prop that has one
  python3 models.py --write barrel lamp    just those

Each prop's model is built from its MODERN painting (neon-caster/hd/NAME.png)
- SHAPES says how: extruded (its outline pushed out to a depth: boxes,
guns, cards), lathed (its outline spun round: barrels, tanks, jars), or -
the turret - built from parts (turret_kit), the painting on it. One clean, solid shape that matches its painting from the
front. A prop that's neither (the chair, the plant) is pixelmon's model
of its painting, kept in src/ (NAME_textured.gltf, .bin, _texture.png):

  pixelmon --mesh NAME.png --lowpoly 250 --texture --texture-size 512 --name NAME --server rtx --no-open

From either this writes, in neon-caster/models/:

  NAME.obj        the model OpenGL draws (RENDER/MODELS.BM): triangles in
                  cells (a wall is 1 high), in OBJ's usual axes (y up, its
                  front towards -z), so any 3D viewer shows it right. It's
                  sized to stand as tall as the painted prop does in its
                  sprite. A "# frame F" line says how big (in cells) the
                  8 pictures below are.
  NAME_tex.png    its texture, 64 px (CLASSIC art); hd/models/: 256 (MODERN)
  NAME_0..7.png   it from 8 ways round, 45 degrees apart, 64 px: 0 from in
                  front, 2 from its right, 4 from behind, 6 from its left.
                  The software renderer shows the nearest one, as DOOM did.

Needs numpy and Pillow - the Python pixelmon runs on has them
(~/ComfyUI/.venv/bin/python models.py --write).
"""
import json, math, os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, '..')
HD = os.path.join(ART, 'hd', 'models')
SRC = os.path.join(HERE, 'src')
PIC = 64  # the 8 pictures' size

# Each prop: its sprite's scale (how many cells tall its picture is drawn:
# DecoScale, ITEM_SCALE and the like in the game)
PROPS = {
    'barrel': 0.45, 'lamp': 0.85, 'plant': 0.6, 'terminal': 0.55, 'crate': 0.42, 'rack': 0.9,
    'vending': 0.8, 'tank': 0.55, 'spawner': 0.7, 'desk': 0.45, 'console': 0.5, 'screens': 0.85,
    'specimen': 0.85, 'labbench': 0.45, 'generator': 0.7, 'cryopod': 0.95, 'locker': 0.9,
    'bench': 0.35, 'chair': 0.5,
    'keycard': 0.3, 'medkit': 0.3, 'ammo': 0.3, 'shells': 0.3, 'pickup-scatter': 0.45,
    'pickup-repeater': 0.45, 'armor': 0.3, 'bigmed': 0.3, 'pickup-rail': 0.45, 'map': 0.3,
    'overcharge': 0.3, 'amp': 0.3, 'goggles': 0.3, 'suit': 0.3, 'pickup-rocket': 0.45, 'rockets': 0.3, 'rounds': 0.3, 'slugs': 0.3,
    'turret': 0.55,  # (a monster: its height, mtypeScale)
}
def read_gltf(path):
    """A glTF's triangles - (points, uvs) each - turned to the game's axes.
    glTF is y up, and a model faces +z; ours is x the way it faces, y its
    right, z up: (x, y, z) here is (z, -x, y) there. That turn is a mirror
    image as well (the map's y runs down), so each triangle's corners are
    taken the other way round, to keep its outside out."""
    j = json.load(open(path))
    buf = open(os.path.join(os.path.dirname(path), j['buffers'][0]['uri']), 'rb').read()

    def acc(i):
        a = j['accessors'][i]; bv = j['bufferViews'][a['bufferView']]
        n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3}[a['type']]
        dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a['componentType']]
        return np.frombuffer(buf, dt, count=a['count'] * n, offset=bv.get('byteOffset', 0) + a.get('byteOffset', 0)).reshape(a['count'], n)

    tris = []
    for mesh in j['meshes']:
        for prim in mesh['primitives']:
            P = acc(prim['attributes']['POSITION']).astype(float)
            UV = acc(prim['attributes']['TEXCOORD_0']).astype(float)
            I = acc(prim['indices']).reshape(-1, 3) if 'indices' in prim else np.arange(len(P)).reshape(-1, 3)
            G = np.stack([P[:, 2], -P[:, 0], P[:, 1]], axis=1)
            for a, b, c in I:
                tris.append((G[[a, c, b]], UV[[a, c, b]]))
    return tris


def subject_height(name):
    """How tall the painted prop is, as a share of its picture: what the
    model's height should be, times the sprite's scale."""
    im = np.array(Image.open(os.path.join(ART, 'hd', name + '.png')).convert('RGBA'))
    rows = np.where(im[..., 3].max(axis=1) > 128)[0]
    return (rows.max() - rows.min() + 1) / im.shape[0]


def place(tris, height):
    """Scaled to height cells tall, standing on z 0, centred over x 0, y 0."""
    allp = np.concatenate([p for p, _ in tris])
    lo, hi = allp.min(axis=0), allp.max(axis=0)
    s = height / (hi[2] - lo[2])
    mid = np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]])
    return [((p - mid) * s, uv) for p, uv in tris]


def render(tris, tex, frame, size, ss, span, top=False):
    """The prop from frame * 45 degrees round it (0: in front): a square span
    cells across, its foot on the bottom edge, as a sprite is drawn. Drawn
    ss times bigger, then shrunk; each face shaded by the way it faces, lit
    from over your left shoulder. top: from straight above it instead (its
    head towards you, its front down the picture), in the middle - a wall
    turret, seen from the room."""
    S = size * ss
    th = frame * math.pi / 4
    eye = np.array([math.cos(th), math.sin(th), 0.0])  # towards you, from the prop
    right = np.array([math.sin(th), -math.cos(th), 0.0])  # your right, as you look at it
    up = np.array([0.0, 0.0, 1.0])
    if top:
        eye = np.array([0.0, 0.0, 1.0]); right = np.array([0.0, 1.0, 0.0]); up = np.array([-1.0, 0.0, 0.0])
    light = eye * 0.55 + up * 0.8 - right * 0.35; light /= np.linalg.norm(light)
    col = np.zeros((S, S, 3)); depth = np.full((S, S), -1e9); cover = np.zeros((S, S), bool)
    th_, tw = tex.shape[:2]
    for P, U in tris:
        n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
        if ln < 1e-12: continue
        n /= ln
        sx = (P @ right / span + 0.5) * S; sy = ((0.5 if top else 1) - (P @ up) / span) * S; d = P @ eye
        x0 = max(int(math.floor(sx.min())), 0); x1 = min(int(math.ceil(sx.max())), S - 1)
        y0 = max(int(math.floor(sy.min())), 0); y1 = min(int(math.ceil(sy.max())), S - 1)
        if x0 > x1 or y0 > y1: continue
        den = (sy[1] - sy[2]) * (sx[0] - sx[2]) + (sx[2] - sx[1]) * (sy[0] - sy[2])
        if abs(den) < 1e-12: continue
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1] + 0.5
        w0 = ((sy[1] - sy[2]) * (gx - sx[2]) + (sx[2] - sx[1]) * (gy - sy[2])) / den
        w1 = ((sy[2] - sy[0]) * (gx - sx[2]) + (sx[0] - sx[2]) * (gy - sy[2])) / den
        w2 = 1 - w0 - w1
        z = w0 * d[0] + w1 * d[1] + w2 * d[2]
        win = depth[y0:y1 + 1, x0:x1 + 1]
        hit = (w0 >= 0) & (w1 >= 0) & (w2 >= 0) & (z > win)
        if not hit.any(): continue
        u = w0 * U[0, 0] + w1 * U[1, 0] + w2 * U[2, 0]; v = w0 * U[0, 1] + w1 * U[1, 1] + w2 * U[2, 1]
        texel = tex[np.clip((v * th_).astype(int), 0, th_ - 1), np.clip((u * tw).astype(int), 0, tw - 1), :3].astype(float)
        nn = n if np.dot(n, eye) >= 0 else -n  # (a face seen from inside - a thin part: lit as its other side)
        shade = 0.72 + 0.45 * max(0.0, float(np.dot(nn, light)))
        win[hit] = z[hit]
        col[y0:y1 + 1, x0:x1 + 1][hit] = texel[hit] * shade
        cover[y0:y1 + 1, x0:x1 + 1][hit] = True
    c = col.reshape(size, ss, size, ss, 3); k = cover.reshape(size, ss, size, ss)
    cnt = k.sum(axis=(1, 3))
    out = np.zeros((size, size, 4), np.uint8)
    out[..., :3] = np.clip((c * k[..., None]).sum(axis=(1, 3)) / np.maximum(cnt, 1)[..., None], 0, 255).astype(np.uint8)
    out[..., 3] = np.where(cnt * 2 > ss * ss, 255, 0)
    return out


def write_obj(tris, path, name, frame):
    """As OBJ files are everywhere else (Blender's own, kaleidotron): y up,
    its front towards -z, corners anticlockwise seen from outside - its x is
    our y, its y our z, its z our -x. RENDER/MODELS.BM's LoadObj turns it back."""
    lines = [f'# NEON-CASTER prop: {name} - made by models.py (edit that, not this)',
             '# OBJ axes: y up, its front towards -z (the game turns it to its own as it loads it).',
             f'# frame {frame:.4f}',
             '# (how many cells across its 8 pictures are)',
             f'mtllib {name}.mtl', f'usemtl {name}']
    for P, _ in tris:
        for p in P: lines.append('v %.4f %.4f %.4f' % (p[1], p[2], -p[0]))
    for _, U in tris:
        for u, v in U: lines.append('vt %.4f %.4f' % (u, 1 - v))  # (OBJ's v runs up from the bottom)
    for k in range(len(tris)):
        a = 3 * k + 1  # (the turn is a mirror image: corners the other way round)
        lines.append(f'f {a}/{a} {a + 2}/{a + 2} {a + 1}/{a + 1}')
    open(path, 'w').write('\n'.join(lines) + '\n')
    # its material, for other programs (the game reads only the .obj): the MODERN texture
    open(path[:-4] + '.mtl', 'w').write(f'# NEON-CASTER prop: {name} - its texture, for 3D viewers\nnewmtl {name}\nKd 1 1 1\nmap_Kd ../hd/models/{name}_tex.png\n')


# Built from the painting itself, not guessed by pixelmon: ('extrude', D) -
# its outline pushed out D times its width deep, the painting on front and
# back; ('lathe',) - its outline spun round its middle, a round thing.
# Either is one clean, solid shape that matches its painting from the
# front. The rest are pixelmon's models (src/).
SHAPES = {
    'barrel': ('lathe',), 'lamp': ('lathe',), 'tank': ('lathe',), 'specimen': ('lathe',), 'cryopod': ('lathe',),
    'amp': ('lathe',),
    'crate': ('extrude', 0.8), 'rack': ('extrude', 0.6), 'vending': ('extrude', 0.7), 'terminal': ('extrude', 0.6),
    'desk': ('extrude', 0.55, [(0.42, 0.18)]), 'console': ('extrude', 0.6), 'screens': ('extrude', 0.12), 'labbench': ('extrude', 0.5, [(0.45, 0.14)]),
    'generator': ('extrude', 0.7, [(0.22, 0.14)]), 'locker': ('extrude', 0.55), 'bench': ('extrude', 0.4, [(0.5, 0.22)]), 'spawner': ('extrude', 0.15),
    'medkit': ('extrude', 0.45), 'bigmed': ('extrude', 0.6), 'ammo': ('lathe', 2), 'shells': ('extrude', 0.5),
    'pickup-scatter': ('extrude', 0.1), 'pickup-repeater': ('extrude', 0.1), 'pickup-rail': ('extrude', 0.08), 'pickup-rocket': ('extrude', 0.22), 'rockets': ('extrude', 0.55), 'rounds': ('extrude', 0.6), 'slugs': ('extrude', 0.25),
    'armor': ('extrude', 0.35), 'map': ('extrude', 0.04), 'overcharge': ('extrude', 0.15), 'goggles': ('extrude', 0.35),
    'keycard': ('extrude', 0.06), 'suit': ('extrude', 0.3), 'turret': ('kit',),
}
GRID = 64  # the outline's grid: the painting's alpha, this many cells across


def outline(name):
    """The painting (RGBA, square) and which of a GRID x GRID grid over it is
    solid - its alpha, holes of a cell or two filled."""
    im = Image.open(os.path.join(ART, 'hd', name + '.png')).convert('RGBA')
    a = np.array(im.resize((GRID, GRID), Image.BOX))[..., 3] > 110
    return np.array(im), a


def _quad(tris, p, uv, want):
    """Two triangles for corners p (4, in order round), outside towards want."""
    p = np.array(p, float); uv = np.array(uv, float)
    for i in ((0, 1, 2), (0, 2, 3)):
        P, U = p[list(i)], uv[list(i)]
        if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), want) < 0: P, U = P[[0, 2, 1]], U[[0, 2, 1]]
        tris.append((P, U))


def extrude(name, depth, bands=(), part=None):
    """The outline as a slab: front and back (each row's runs of solid
    cells, rows alike one quad), and its edges as sides - each showing the
    painting's colour a little in from that edge. depth is its depth, times
    its width; bands - (share of its height, from its top, depth) - are its
    parts above that line at a depth of their own (a monitor on a desk),
    with a step between. part - (row0, row1, col0, col1) - is just that
    box of the outline (a turret's body, its head), where it is."""
    _, a = outline(name)
    if part:
        m = np.zeros_like(a); m[part[0]:part[1] + 1, part[2]:part[3] + 1] = a[part[0]:part[1] + 1, part[2]:part[3] + 1]; a = m
    R = GRID; cols = np.where(a.any(axis=0))[0]; rows = np.where(a.any(axis=1))[0]
    wide = (cols.max() - cols.min() + 1) / 2
    dz = np.full(R, depth * wide)  # each row's half-depth
    for share, dd in sorted(bands, reverse=True):
        dz[:rows.min() + int(round(share * (rows.max() - rows.min() + 1)))] = dd * wide
    Y = lambda c: -(c - R / 2); Z = lambda r: R - r
    tris = []
    def runs(row):
        out, c = [], 0
        while c < R:
            if row[c]:
                c0 = c
                while c < R and row[c]: c += 1
                out.append((c0, c))
            else: c += 1
        return out
    # A side takes its colour from a little inside the edge: the painting's
    # outline is dark, and a side all outline would be black
    INSET = 3
    def in_r(r, c, dr):
        for _ in range(INSET):
            if 0 <= r + dr < R and a[r + dr, c]: r += dr
        return r
    def in_c(r, c, dc):
        for _ in range(INSET):
            if 0 <= c + dc < R and a[r, c + dc]: c += dc
        return c
    # front and back: a run carries on down while the rows below have it, as deep
    open_ = {}
    def close(key, r1):
        r0 = open_.pop(key); c0, c1, d = key
        for x, w in ((d, 1), (-d, -1)):
            _quad(tris, [(x, Y(c0), Z(r0)), (x, Y(c1), Z(r0)), (x, Y(c1), Z(r1)), (x, Y(c0), Z(r1))],
                  [(c0 / R, r0 / R), (c1 / R, r0 / R), (c1 / R, r1 / R), (c0 / R, r1 / R)], (w, 0, 0))
    for r in range(R + 1):
        now = set((c0, c1, dz[r]) for c0, c1 in runs(a[r])) if r < R else set()
        for key in [k for k in open_ if k not in now]: close(key, r)
        for key in now:
            if key not in open_: open_[key] = r
    # top and bottom edges: runs of cells open above (below)
    for r in range(R):
        for up in (True, False):
            nb = a[r - 1] if (up and r > 0) else (a[r + 1] if (not up and r < R - 1) else np.zeros(R, bool))
            z = Z(r) if up else Z(r + 1); d = dz[r]
            for c0, c1 in runs(a[r] & ~nb):
                v = (in_r(r, (c0 + c1) // 2, 1 if up else -1) + 0.5) / R
                _quad(tris, [(d, Y(c0), z), (d, Y(c1), z), (-d, Y(c1), z), (-d, Y(c0), z)],
                      [((c0 + 0.5) / R, v), ((c1 - 0.5) / R, v), ((c1 - 0.5) / R, v), ((c0 + 0.5) / R, v)], (0, 0, 1 if up else -1))
            # a step, where the row next to it is solid but less deep
            if up and r > 0 and dz[r - 1] < d:
                v = (in_r(r, 0, 0) + 0.5) / R
                for c0, c1 in runs(a[r] & a[r - 1]):
                    for s in (1, -1):
                        _quad(tris, [(s * dz[r - 1], Y(c0), z), (s * dz[r - 1], Y(c1), z), (s * d, Y(c1), z), (s * d, Y(c0), z)],
                              [((c0 + 0.5) / R, v), ((c1 - 0.5) / R, v), ((c1 - 0.5) / R, v), ((c0 + 0.5) / R, v)], (0, 0, 1))
    # left and right edges: runs of cells open to that side (and as deep), down a column
    for c in range(R):
        for left in (True, False):
            nb = a[:, c - 1] if (left and c > 0) else (a[:, c + 1] if (not left and c < R - 1) else np.zeros(R, bool))
            edge = a[:, c] & ~nb
            y = Y(c) if left else Y(c + 1)
            r = 0
            while r < R:
                if not edge[r]: r += 1; continue
                r0 = r
                while r < R and edge[r] and dz[r] == dz[r0]: r += 1
                d = dz[r0]; u = (in_c((r0 + r) // 2, c, 1 if left else -1) + 0.5) / R
                _quad(tris, [(d, y, Z(r0)), (d, y, Z(r)), (-d, y, Z(r)), (-d, y, Z(r0))],
                      [(u, (r0 + 0.5) / R), (u, (r - 0.5) / R), (u, (r - 0.5) / R), (u, (r0 + 0.5) / R)], (0, 1 if left else -1, 0))
    return tris


# A turret's muzzles are textured from the texture's bottom right corner,
# painted white (MUZZLE_BOX of it, each way): the game draws any triangle
# textured from there in the colour of the turret's weapon, lit or not
MUZZLE_BOX, MUZZLE_UV = 1 / 16, 0.97


def cylinder(y, z, r, x0, x1, u0, u1, v0, v1, seg=12, muzzle=False):
    """A tube along x from x0 to x1 round (y, z), r across, capped - its
    sides the painting from (u0, v0) to (u1, v1): along it u, round it v
    (a barrel's picture, its length one way and its width the other)."""
    tris = []
    for k in range(seg):
        t0, t1 = 2 * math.pi * k / seg, 2 * math.pi * (k + 1) / seg
        p = lambda x, t: (x, y + r * math.cos(t), z + r * math.sin(t))
        vv = lambda t: v0 + (v1 - v0) * (0.5 + 0.5 * math.sin(t))
        tm = (t0 + t1) / 2
        _quad(tris, [p(x0, t0), p(x1, t0), p(x1, t1), p(x0, t1)], [(u0, vv(t0)), (u1, vv(t0)), (u1, vv(t1)), (u0, vv(t1))], (0, math.cos(tm), math.sin(tm)))
        for x, w, u in ((x1, 1, u1 - 0.04), (x0, -1, u0)):  # (the caps: its muzzle - the barrel's dark end - and its back)
            P = np.array([(x, y, z), p(x, t0), p(x, t1)], float); U = np.array([(u, (v0 + v1) / 2)] * 3)
            if w == 1 and muzzle: U = np.array([(MUZZLE_UV, MUZZLE_UV)] * 3)  # (a turret's muzzle: the white corner - the game colours it, by the turret's weapon)
            if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), (w, 0, 0)) < 0: P = P[[0, 2, 1]]
            tris.append((P, U))
    return tris


KIT_BASE = [0, 0]  # (turret_kit: its base's triangles, first and past the last)


def turret_kit(name):
    """The turret, from its parts - its painting shows it side on, barrels
    pointing right, so pushed out whole it would be a slab: its body and its
    sensor head pushed out from just their rows of the painting, its tripod
    spun round into a pedestal, and two barrels - tubes in its barrel's
    picture - pointing forward, the way it faces: at you."""
    R = GRID; Y = lambda c: -(c - R / 2); Z = lambda r: R - r
    tris = extrude(name, 0.42, part=(20, 43, 0, 48)) + extrude(name, 0.7, part=(2, 19, 20, 36))
    _, a = outline(name)
    m = np.zeros_like(a); m[44:, :] = a[44:, :]
    base = _lathe_piece(m, 14)
    KIT_BASE[:] = [len(tris), len(tris) + len(base)]  # (which of its triangles are the base: for the two parts - build)
    tris += base
    d = 0.42 * 45 / 2  # (the body's half-depth: its front)
    for c, r in ((13, 31.5), (39, 31.5)):  # (the barrels: either side of its eye, half way up)
        tris += cylinder(Y(c), Z(r), 3.2, d - 2, d + 20, 40 / R, 56 / R, 12 / R, 19 / R, muzzle=True)
    return tris


def lathe(name, pieces=1, seg=16):
    """The outline spun round its middle: each row's half-width a ring,
    the profile cut to the rings that matter (within half a cell), capped
    top and bottom. The painting wraps round from the front - as it's
    painted from in front, and mirrored behind. pieces: it's that many
    round things side by side (two energy cells) - its outline cut into
    that many, left to right, each spun round its own middle."""
    _, whole = outline(name)
    R = GRID; wc = np.where(whole.any(axis=0))[0]
    cuts = [int(round(wc.min() + (wc.max() + 1 - wc.min()) * k / pieces)) for k in range(pieces + 1)]
    tris = []
    for p0, p1 in zip(cuts, cuts[1:]):
        a = np.zeros_like(whole); a[:, p0:p1] = whole[:, p0:p1]
        tris += _lathe_piece(a, seg)
    return tris


def _lathe_piece(a, seg):
    """One round thing: outline a (the solid cells of it alone) spun round
    its own middle, where it is across the picture."""
    R = GRID; cols = np.where(a.any(axis=0))[0]; rows = np.where(a.any(axis=1))[0]
    cc = (cols.min() + cols.max() + 1) / 2
    rad = np.zeros(R)
    for r in rows:
        cs = np.where(a[r])[0]
        rad[r] = max(cc - cs.min(), cs.max() + 1 - cc)
    # the profile: (row edge, radius), steps where the radius jumps
    prof = [(rows.min(), rad[rows.min()])]
    for r in range(rows.min(), rows.max() + 1):
        nxt = rad[r + 1] if r + 1 <= rows.max() else None
        if nxt is not None and abs(nxt - rad[r]) > 1.5:
            prof += [(r + 1, rad[r]), (r + 1, nxt)]
        else:
            prof.append((r + 1, rad[r] if nxt is None else (rad[r] + nxt) / 2))
    # fewer rings: drop those on a straight line between their neighbours
    keep = [prof[0]]
    for i in range(1, len(prof) - 1):
        (r0, a0), (r1, a1), (r2, a2) = keep[-1], prof[i], prof[i + 1]
        if r2 == r0 or abs(a0 + (a2 - a0) * (r1 - r0) / (r2 - r0) - a1) > 0.5 or r1 == r2 or r1 == r0: keep.append(prof[i])
    keep.append(prof[-1])
    Z = lambda r: R - r
    ang = [2 * math.pi * k / seg for k in range(seg + 1)]
    def pt(r, rr, t): return (rr * math.cos(t), -rr * math.sin(t) - (cc - R / 2), Z(r))
    def uv(r, rr, t): return (min(max((cc + 0.85 * rr * math.sin(t)) / R, 0), 1), min(max(r / R, 0), 1))  # (0.85: inside its dark outline)
    tris = []
    for (r0, a0), (r1, a1) in zip(keep, keep[1:]):
        if a0 < 1e-6 and a1 < 1e-6: continue
        for k in range(seg):
            t0, t1, tm = ang[k], ang[k + 1], (ang[k] + ang[k + 1]) / 2
            want = (math.cos(tm), -math.sin(tm), (a0 - a1) / max(abs(r1 - r0), 1e-6) * 0.0)
            if r0 == r1: want = (0, 0, 1 if a1 < a0 else -1)
            _quad(tris, [pt(r0, a0, t0), pt(r0, a0, t1), pt(r1, a1, t1), pt(r1, a1, t0)],
                  [uv(r0, a0, t0), uv(r0, a0, t1), uv(r1, a1, t1), uv(r1, a1, t0)], want)
    for (r, rr), up in ((keep[0], 1), (keep[-1], -1)):  # the caps
        for k in range(seg):
            P = np.array([(0, -(cc - R / 2), Z(r)), pt(r, rr, ang[k]), pt(r, rr, ang[k + 1])], float)
            U = np.array([(cc / R, (r + 0.5 * up) / R), uv(r, rr, ang[k]), uv(r, rr, ang[k + 1])])
            if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), (0, 0, up)) < 0: P, U = P[[0, 2, 1]], U[[0, 2, 1]]
            tris.append((P, U))
    return [(P, U) for P, U in tris if np.linalg.norm(np.cross(P[1] - P[0], P[2] - P[0])) > 1e-9]


def build(name):
    shape = SHAPES.get(name)
    if shape:
        raw = extrude(name, *shape[1:]) if shape[0] == 'extrude' else turret_kit(name) if shape[0] == 'kit' else lathe(name, *shape[1:])
        tris = place(raw, PROPS[name] * subject_height(name))
        tex = outline(name)[0]
        if shape[0] == 'kit':  # (the muzzles' white corner)
            tex = tex.copy(); h, w = tex.shape[:2]
            tex[int(h * (1 - MUZZLE_BOX)):, int(w * (1 - MUZZLE_BOX)):] = (255, 255, 255, 255)
    else:
        gltf = os.path.join(SRC, name + '_textured.gltf')
        tris = place(read_gltf(gltf), PROPS[name] * subject_height(name))
        tex = np.array(Image.open(os.path.join(SRC, name + '_textured_texture.png')).convert('RGBA'))
    allp = np.concatenate([p for p, _ in tris])
    reach = np.sqrt(allp[:, 0] ** 2 + allp[:, 1] ** 2).max()  # how far it reaches from its middle, any way round
    frame = max(PROPS[name], 2 * reach * 1.04, allp[:, 2].max() * 1.04)
    write_obj(tris, os.path.join(HERE, name + '.obj'), name, frame)
    t = Image.fromarray(tex, 'RGBA')
    t.resize((64, 64), Image.LANCZOS).save(os.path.join(HERE, name + '_tex.png'))
    os.makedirs(HD, exist_ok=True)
    t.resize((256, 256), Image.LANCZOS).save(os.path.join(HD, name + '_tex.png'))
    for f in range(8):
        Image.fromarray(render(tris, tex, f, PIC, 4, frame), 'RGBA').save(os.path.join(HERE, f'{name}_{f}.png'))
    if shape and shape[0] == 'kit':  # (a turret in two parts too - its base, and its head (body, eye, barrels) turning on it: the game aims the head at you)
        b0, b1 = KIT_BASE
        base = tris[b0:b1]; head = tris[:b0] + tris[b1:]
        pivot = max(float(P[:, 2].max()) for P, _ in base)
        head = [(P - np.array([0, 0, pivot]), U) for P, U in head]  # (the head turns about the top of its base)
        for part, pt in (('base', base), ('head', head)):
            nm = name + '-' + part
            write_obj(pt, os.path.join(HERE, nm + '.obj'), nm, frame)
            t.resize((64, 64), Image.LANCZOS).save(os.path.join(HERE, nm + '_tex.png'))
            t.resize((256, 256), Image.LANCZOS).save(os.path.join(HD, nm + '_tex.png'))
            for f in range(8):
                Image.fromarray(render(tris, tex, f, PIC, 4, frame), 'RGBA').save(os.path.join(HERE, f'{nm}_{f}.png'))  # (its pictures: the whole turret's - only OpenGL, near, draws the parts)
    if shape and shape[0] == 'kit':  # (a turret: from above too - a wall turret's picture, seen from the room - 64 and 256)
        Image.fromarray(render(tris, tex, 0, PIC, 4, frame, top=True), 'RGBA').save(os.path.join(ART, name + '-top.png'))
        Image.fromarray(render(tris, tex, 0, 256, 2, frame, top=True), 'RGBA').save(os.path.join(ART, 'hd', name + '-top.png'))
    return len(tris), frame


def rocket():
    """A rocket in flight (yours, and a missile turret's), made from scratch -
    it has no painting: a tube (grey, an orange band), a red nose cone, four
    fins and a dark nozzle, 0.36 cells long, its middle at (0, 0, 0) and its
    nose the way it faces. Its own little texture, in quarters: body, nose,
    fins, nozzle."""
    T = 64; tex = np.zeros((T, T, 4), np.uint8); tex[..., 3] = 255
    tex[:32, :32, :3] = (150, 154, 165); tex[:32, 18:24, :3] = (255, 140, 30)  # body, its band
    tex[4:8, :32, :3] = (110, 112, 122); tex[24:28, :32, :3] = (110, 112, 122)  # (seams)
    tex[:32, 32:, :3] = (225, 40, 40)  # nose
    tex[32:, :32, :3] = (60, 62, 72)  # fins
    tex[32:, 32:, :3] = (30, 28, 30); tex[44:52, 40:56, :3] = (255, 150, 40)  # nozzle, glowing
    r, x0, x1, xn = 0.032, -0.15, 0.1, 0.2
    tris = cylinder(0, 0, r, x0, x1, 0.02, 0.48, 0.02, 0.48, seg=10)
    seg = 10
    for k in range(seg):  # the nose: a cone
        t0, t1 = 2 * math.pi * k / seg, 2 * math.pi * (k + 1) / seg
        P = np.array([(xn, 0, 0), (x1, r * math.cos(t0), r * math.sin(t0)), (x1, r * math.cos(t1), r * math.sin(t1))], float)
        U = np.array([(0.75, 0.05), (0.55, 0.45), (0.95, 0.45)])
        if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), (1, 0, 0)) < 0: P = P[[0, 2, 1]]
        tris.append((P, U))
    for a in range(4):  # the fins: thin plates out the back, each way round
        c, s_ = math.cos(a * math.pi / 2 + math.pi / 4), math.sin(a * math.pi / 2 + math.pi / 4)
        q = lambda x, d: (x, c * d, s_ * d)
        quad = [q(x0, r), q(x0 + 0.08, r), q(x0 - 0.01, r + 0.05), q(x0 - 0.03, r + 0.05)]
        uv = [(0.05, 0.55), (0.45, 0.55), (0.4, 0.95), (0.05, 0.95)]
        _quad(tris, quad, uv, (0, -s_, c)); _quad(tris, quad, uv, (0, s_, -c))
    for k in range(seg):  # the nozzle's mouth, glowing
        t0, t1 = 2 * math.pi * k / seg, 2 * math.pi * (k + 1) / seg
        P = np.array([(x0 - 0.001, 0, 0), (x0 - 0.001, r * 0.8 * math.cos(t0), r * 0.8 * math.sin(t0)), (x0 - 0.001, r * 0.8 * math.cos(t1), r * 0.8 * math.sin(t1))], float)
        U = np.array([(0.75, 0.75)] * 3)
        if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), (-1, 0, 0)) < 0: P = P[[0, 2, 1]]
        tris.append((P, U))
    return tris, tex


def mount(broken):
    """A turret's mounting plate (turret-mount, and turret-mount-broken once
    it's been destroyed): a hex of armour plate bolted flat to the ceiling,
    floor or wall, 0.36 across, its face up (z) - broken, a hole blown
    through it, charred inside, torn wires sticking out. Its own texture in
    quarters: plate, its edge, the hole's charred inside, wires."""
    T = 64; tex = np.zeros((T, T, 4), np.uint8); tex[..., 3] = 255
    tex[:32, :32, :3] = (88, 92, 104)
    for k in range(6):  # (bolts round the plate, in its picture)
        a = k * math.pi / 3 + math.pi / 6; bx, by = int(16 + 12 * math.cos(a)), int(16 + 12 * math.sin(a))
        tex[by - 1:by + 2, bx - 1:bx + 2, :3] = (170, 175, 185)
    tex[14:18, :32, :3] = (230, 180, 30); tex[14:18, ::6, :3] = (30, 30, 30)  # (a hazard stripe)
    tex[:32, 32:, :3] = (55, 58, 66)  # edge
    tex[32:, :32, :3] = (24, 18, 16); tex[40:56, 8:24, :3] = (70, 30, 10)  # charred inside
    tex[32:40, 32:, :3] = (220, 40, 40); tex[40:48, 32:, :3] = (240, 210, 40); tex[48:56, 32:, :3] = (50, 120, 255); tex[56:, 32:, :3] = (30, 30, 30)  # wires
    R, t = 0.18, 0.03
    hexp = [(R * math.cos(k * math.pi / 3), R * math.sin(k * math.pi / 3)) for k in range(6)]
    uvp = lambda x, y: (0.25 + x / R * 0.22, 0.25 + y / R * 0.22)
    tris = []
    rng = np.random.default_rng(7)
    if broken:
        n = 12
        hole = [(r * math.cos(k * 2 * math.pi / n), r * math.sin(k * 2 * math.pi / n)) for k, r in enumerate(0.07 + rng.random(n) * 0.045)]
        for k in range(n):  # the plate's face: from the hole's ragged edge out to the hex
            a0, a1 = k * 2 * math.pi / n, (k + 1) * 2 * math.pi / n
            def onhex(a):
                kk = int(a // (math.pi / 3)) % 6; p0, p1 = np.array(hexp[kk]), np.array(hexp[(kk + 1) % 6])
                d = np.array([math.cos(a), math.sin(a)]); m = np.array([d, p0 - p1]).T
                tt = np.linalg.solve(m, p0)[0]; return tuple(d * tt)
            o0, o1, i0, i1 = onhex(a0), onhex(a1), hole[k], hole[(k + 1) % n]
            _quad(tris, [(*i0, t), (*o0, t), (*o1, t), (*i1, t)], [uvp(*i0), uvp(*o0), uvp(*o1), uvp(*i1)], (0, 0, 1))
            _quad(tris, [(*i0, t), (*i1, t), (*i1, -0.05), (*i0, -0.05)], [(0.1, 0.6), (0.4, 0.6), (0.4, 0.9), (0.1, 0.9)], (-(i0[0] + i1[0]), -(i0[1] + i1[1]), 0))  # (the hole's charred side)
        P = [(0, 0, -0.05)] + [(*h, -0.05) for h in hole]
        for k in range(n):
            _quad(tris, [P[0], P[1 + k], P[1 + (k + 1) % n], P[0]], [(0.25, 0.75)] * 4, (0, 0, 1))  # (its dark bottom)
        for w in range(4):  # torn wires, curling out of it
            a = rng.random() * 2 * math.pi; x, y = 0.03 * math.cos(a), 0.03 * math.sin(a)
            dx, dy, h = math.cos(a + 0.6) * 0.06, math.sin(a + 0.6) * 0.06, 0.05 + rng.random() * 0.06
            v = 0.53 + w * 0.125
            for side in (0, 1):
                ox, oy = (-math.sin(a) * 0.006, math.cos(a) * 0.006) if side else (0.006, 0.0)
                _quad(tris, [(x - ox, y - oy, -0.04), (x + ox, y + oy, -0.04), (x + dx + ox, y + dy + oy, h), (x + dx - ox, y + dy - oy, h)],
                      [(0.55, v), (0.95, v), (0.95, v + 0.08), (0.55, v + 0.08)], (math.sin(a), -math.cos(a), 0.2))
                _quad(tris, [(x - ox, y - oy, -0.04), (x + ox, y + oy, -0.04), (x + dx + ox, y + dy + oy, h), (x + dx - ox, y + dy - oy, h)],
                      [(0.55, v), (0.95, v), (0.95, v + 0.08), (0.55, v + 0.08)], (-math.sin(a), math.cos(a), -0.2))
    else:
        for k in range(6):
            p0, p1 = hexp[k], hexp[(k + 1) % 6]
            _quad(tris, [(0, 0, t), (*p0, t), (*p1, t), (0, 0, t)], [uvp(0, 0), uvp(*p0), uvp(*p1), uvp(0, 0)], (0, 0, 1))
    for k in range(6):  # its edge, all round
        p0, p1 = hexp[k], hexp[(k + 1) % 6]
        _quad(tris, [(*p0, 0), (*p1, 0), (*p1, t), (*p0, t)], [(0.55, 0.1), (0.95, 0.1), (0.95, 0.4), (0.55, 0.4)], ((p0[0] + p1[0]), (p0[1] + p1[1]), 0))
    return tris, tex


def build_mount():
    for broken in (False, True):
        nm = 'turret-mount' + ('-broken' if broken else '')
        tris, tex = mount(broken)
        write_obj(tris, os.path.join(HERE, nm + '.obj'), nm, 0.4)
        t = Image.fromarray(tex, 'RGBA')
        t.resize((64, 64), Image.NEAREST).save(os.path.join(HERE, nm + '_tex.png'))
        t.resize((256, 256), Image.NEAREST).save(os.path.join(HD, nm + '_tex.png'))
        for f in range(8):  # (pictures - only OpenGL draws it, near)
            Image.fromarray(render(tris, tex, f, PIC, 4, 0.4), 'RGBA').save(os.path.join(HERE, f'{nm}_{f}.png'))


def build_rocket():
    tris, tex = rocket()
    frame = 0.42
    write_obj(tris, os.path.join(HERE, 'rocket.obj'), 'rocket', frame)
    t = Image.fromarray(tex, 'RGBA')
    t.resize((64, 64), Image.NEAREST).save(os.path.join(HERE, 'rocket_tex.png'))
    os.makedirs(HD, exist_ok=True)
    t.resize((256, 256), Image.NEAREST).save(os.path.join(HD, 'rocket_tex.png'))
    up = [(P + np.array([0, 0, frame / 2]), U) for P, U in tris]  # (its pictures: its middle half way up, as a sprite's drawn from its foot)
    for f in range(8):
        Image.fromarray(render(up, tex, f, PIC, 4, frame), 'RGBA').save(os.path.join(HERE, f'rocket_{f}.png'))
    return len(tris), frame


def main():
    write = '--write' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    if write and (not only or 'turret-mount' in only):
        build_mount(); print('turret-mount     its plate, whole and broken')
    if write and (not only or 'rocket' in only):
        n, frame = build_rocket()
        print(f'{"rocket":16s} {n} triangles, its pictures {frame:.2f} cells across')
    for name in PROPS:
        if only and name not in only: continue
        have = name in SHAPES or os.path.exists(os.path.join(SRC, name + '_textured.gltf'))
        if not write or not have:
            print(f'{name:16s} {"model" if have else "-"}')
            continue
        n, frame = build(name)
        print(f'{name:16s} {n} triangles, its pictures {frame:.2f} cells across')


if __name__ == '__main__':
    main()
