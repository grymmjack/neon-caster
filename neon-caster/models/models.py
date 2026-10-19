#!/usr/bin/env python3
"""NEON-CASTER's 3D props: decorations and pickups as models.

  python3 models.py            list the props, and which have a model
  python3 models.py --write    write every prop that has one
  python3 models.py --write barrel lamp    just those

Each prop's model is built from its MODERN painting (neon-caster/hd/NAME.png)
- SHAPES says how: extruded (its outline pushed out to a depth: boxes,
guns, cards) or lathed (its outline spun round: barrels, tanks, jars), the
painting on it. One clean, solid shape that matches its painting from the
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
    'overcharge': 0.3, 'amp': 0.3, 'goggles': 0.3,
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


def render(tris, tex, frame, size, ss, span):
    """The prop from frame * 45 degrees round it (0: in front): a square span
    cells across, its foot on the bottom edge, as a sprite is drawn. Drawn
    ss times bigger, then shrunk; each face shaded by the way it faces, lit
    from over your left shoulder."""
    S = size * ss
    th = frame * math.pi / 4
    eye = np.array([math.cos(th), math.sin(th), 0.0])  # towards you, from the prop
    right = np.array([math.sin(th), -math.cos(th), 0.0])  # your right, as you look at it
    up = np.array([0.0, 0.0, 1.0])
    light = eye * 0.55 + up * 0.8 - right * 0.35; light /= np.linalg.norm(light)
    col = np.zeros((S, S, 3)); depth = np.full((S, S), -1e9); cover = np.zeros((S, S), bool)
    th_, tw = tex.shape[:2]
    for P, U in tris:
        n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
        if ln < 1e-12: continue
        n /= ln
        sx = (P @ right / span + 0.5) * S; sy = (1 - (P @ up) / span) * S; d = P @ eye
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
    'medkit': ('extrude', 0.45), 'bigmed': ('extrude', 0.6), 'ammo': ('extrude', 0.4), 'shells': ('extrude', 0.5),
    'pickup-scatter': ('extrude', 0.1), 'pickup-repeater': ('extrude', 0.1), 'pickup-rail': ('extrude', 0.08),
    'armor': ('extrude', 0.35), 'map': ('extrude', 0.04), 'overcharge': ('extrude', 0.15), 'goggles': ('extrude', 0.35),
    'keycard': ('extrude', 0.06),
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


def extrude(name, depth, bands=()):
    """The outline as a slab: front and back (each row's runs of solid
    cells, rows alike one quad), and its edges as sides - each showing the
    painting's colour a little in from that edge. depth is its depth, times
    its width; bands - (share of its height, from its top, depth) - are its
    parts above that line at a depth of their own (a monitor on a desk),
    with a step between."""
    _, a = outline(name)
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


def lathe(name, seg=16):
    """The outline spun round its middle: each row's half-width a ring,
    the profile cut to the rings that matter (within half a cell), capped
    top and bottom. The painting wraps round from the front - as it's
    painted from in front, and mirrored behind."""
    _, a = outline(name)
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
    def pt(r, rr, t): return (rr * math.cos(t), -rr * math.sin(t), Z(r))
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
            P = np.array([(0, 0, Z(r)), pt(r, rr, ang[k]), pt(r, rr, ang[k + 1])], float)
            U = np.array([(cc / R, (r + 0.5 * up) / R), uv(r, rr, ang[k]), uv(r, rr, ang[k + 1])])
            if np.dot(np.cross(P[1] - P[0], P[2] - P[0]), (0, 0, up)) < 0: P, U = P[[0, 2, 1]], U[[0, 2, 1]]
            tris.append((P, U))
    return [(P, U) for P, U in tris if np.linalg.norm(np.cross(P[1] - P[0], P[2] - P[0])) > 1e-9]


def build(name):
    shape = SHAPES.get(name)
    if shape:
        raw = extrude(name, *shape[1:]) if shape[0] == 'extrude' else lathe(name)
        tris = place(raw, PROPS[name] * subject_height(name))
        tex = outline(name)[0]
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
    return len(tris), frame


def main():
    write = '--write' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
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
