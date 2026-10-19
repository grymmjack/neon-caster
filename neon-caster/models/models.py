#!/usr/bin/env python3
"""NEON-CASTER's 3D props: each one built here, then written out three ways.

  python3 models.py          build them and show what would be written
  python3 models.py --write  write them (the files below, for every prop)

For a prop NAME (just "chair" so far) it writes, in neon-caster/models/:

  NAME.obj        the model: triangles, in cells (a wall is 1 high).
                  x is the way it faces, y its right-hand side (as the map's
                  y runs south: facing east, your right is south), z up from
                  the floor it stands on. OpenGL draws this (RENDER/MODELS.BM).
  NAME_tex.png    its texture (CLASSIC art, 64 px; hd/models/: MODERN, 256)
  NAME_0..7.png   the prop seen from 8 ways round it, 45 degrees apart:
                  0 from in front, 2 from its right, 4 from behind, 6 from
                  its left. The software renderer shows the nearest one, as
                  DOOM and Duke Nukem 3D did (CLASSIC 64 px; hd/models/ 256).

Needs numpy and Pillow (ComfyUI's Python has both:
~/ComfyUI/.venv/bin/python models.py --write).
"""
import math, os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
HD = os.path.join(HERE, '..', 'hd', 'models')

# Texture tiles: the texture is cut in four, one material in each quarter
FABRIC, SHELL, METAL, WHEEL = 0, 1, 2, 3
TILE_AT = {FABRIC: (0.0, 0.0), SHELL: (0.5, 0.0), METAL: (0.0, 0.5), WHEEL: (0.5, 0.5)}  # (u, v) of its top left


class Mesh:
    def __init__(self):
        self.tris = []  # each: ([p0, p1, p2], [uv0, uv1, uv2]) - points (x, y, z), uv from the texture's top left

    def add(self, pts, uvs, inside):
        """A triangle, wound so its normal points away from the point inside."""
        a, b, c = (np.array(p, float) for p in pts)
        n = np.cross(b - a, c - a)
        if np.dot(n, (a + b + c) / 3 - np.array(inside, float)) < 0:
            pts = [pts[0], pts[2], pts[1]]; uvs = [uvs[0], uvs[2], uvs[1]]
        self.tris.append(([tuple(map(float, p)) for p in pts], uvs))

    def quad(self, pts, uvs, inside):
        self.add([pts[0], pts[1], pts[2]], [uvs[0], uvs[1], uvs[2]], inside)
        self.add([pts[0], pts[2], pts[3]], [uvs[0], uvs[2], uvs[3]], inside)


def tile_uv(tile, s, t):
    """(s, t) 0..1 across a tile, inset half a texel's worth so tiles don't bleed."""
    u0, v0 = TILE_AT[tile]
    s = 0.03 + 0.94 * s; t = 0.03 + 0.94 * t
    return (u0 + s * 0.5, v0 + t * 0.5)


def box(m, x0, x1, y0, y1, z0, z1, tiles, move=lambda p: p):
    """A box, its faces' materials from tiles (one, or a dict by face: 'top',
    'bottom', 'front' (+x), 'back', 'right' (+y), 'left'), moved by move."""
    if not isinstance(tiles, dict):
        tiles = dict.fromkeys(('top', 'bottom', 'front', 'back', 'right', 'left'), tiles)
    P = lambda x, y, z: move((x, y, z))
    inside = move(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    faces = {  # corners going round, and the (s, t) of each: s across, t down (t 0 at the top)
        'top':    [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
        'bottom': [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)],
        'front':  [(x1, y0, z1), (x1, y1, z1), (x1, y1, z0), (x1, y0, z0)],
        'back':   [(x0, y1, z1), (x0, y0, z1), (x0, y0, z0), (x0, y1, z0)],
        'right':  [(x1, y1, z1), (x0, y1, z1), (x0, y1, z0), (x1, y1, z0)],
        'left':   [(x0, y0, z1), (x1, y0, z1), (x1, y0, z0), (x0, y0, z0)],
    }
    st = [(0, 0), (1, 0), (1, 1), (0, 1)]
    for f, corners in faces.items():
        m.quad([P(*c) for c in corners], [tile_uv(tiles[f], *s) for s in st], inside)


def prism(m, r, z0, z1, sides, tile, at=(0.0, 0.0)):
    """An upright prism round (at), radius r: the chair's gas lift."""
    cx, cy = at
    for k in range(sides):
        a0 = 2 * math.pi * k / sides; a1 = 2 * math.pi * (k + 1) / sides
        p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0)); p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
        m.quad([(*p0, z1), (*p1, z1), (*p1, z0), (*p0, z0)],
               [tile_uv(tile, k / sides, 0), tile_uv(tile, (k + 1) / sides, 0), tile_uv(tile, (k + 1) / sides, 1), tile_uv(tile, k / sides, 1)],
               (cx, cy, (z0 + z1) / 2))


def turn_z(a, about=(0.0, 0.0)):
    c, s = math.cos(a), math.sin(a)
    return lambda p: (about[0] + (p[0] - about[0]) * c - (p[1] - about[1]) * s, about[1] + (p[0] - about[0]) * s + (p[1] - about[1]) * c, p[2])


def tilt_back(a, px, pz):
    """Lean back by a (radians) about the line x = px, z = pz: the top goes to -x."""
    c, s = math.cos(a), math.sin(a)
    return lambda p: (px + (p[0] - px) * c - (p[2] - pz) * s, p[1], pz + (p[0] - px) * s + (p[2] - pz) * c)


def chair():
    """An office chair, as the chair sprite was: a tall back, a seat, arms,
    a gas lift, and five legs on castors. Half a wall high."""
    m = Mesh()
    for k in range(5):  # the five legs, and a castor under the end of each
        turn = turn_z(math.pi / 2 + k * 2 * math.pi / 5)
        box(m, 0.015, 0.165, -0.012, 0.012, 0.032, 0.052, METAL, turn)
        box(m, 0.150, 0.180, -0.014, 0.014, 0.000, 0.032, WHEEL, turn)
    box(m, -0.028, 0.028, -0.028, 0.028, 0.030, 0.060, METAL)  # the hub
    prism(m, 0.017, 0.060, 0.205, 8, METAL)  # the gas lift
    box(m, -0.050, 0.050, -0.040, 0.040, 0.195, 0.215, SHELL)  # the seat's mount
    box(m, -0.135, 0.135, -0.130, 0.130, 0.215, 0.250, {'top': FABRIC, 'bottom': SHELL, 'front': FABRIC, 'back': SHELL, 'right': SHELL, 'left': SHELL})
    box(m, -0.150, -0.124, -0.030, 0.030, 0.205, 0.300, SHELL)  # the bar up to the back
    lean = tilt_back(math.radians(9), -0.125, 0.26)
    box(m, -0.160, -0.120, -0.125, 0.125, 0.265, 0.480, {'top': SHELL, 'bottom': SHELL, 'front': FABRIC, 'back': FABRIC, 'right': SHELL, 'left': SHELL}, lean)
    for side in (-1, 1):  # the arms: a post, and a pad on it
        y0, y1 = sorted((side * 0.134, side * 0.150))
        box(m, -0.020, 0.012, y0, y1, 0.235, 0.315, SHELL)
        y0, y1 = sorted((side * 0.128, side * 0.160))
        box(m, -0.080, 0.065, y0, y1, 0.315, 0.333, SHELL)
    return m


PROPS = {'chair': chair}


# --- Textures -----------------------------------------------------------------

def texture(size, hd):
    """The four materials, a quarter each. CLASSIC: the pixel art's navy
    with lighter bands across the fabric. MODERN: black leather, chrome."""
    t = np.zeros((size, size, 4), np.uint8); t[..., 3] = 255
    h = size // 2
    rng = np.random.default_rng(7)
    yy, xx = np.mgrid[0:h, 0:h]
    if not hd:
        fab = np.where((yy % 4) == 0, 1.0, 0.0)[..., None] * np.array([22, 28, 45]) + np.array([38, 48, 92])
        shell = np.zeros((h, h, 3)) + np.array([52, 58, 96])
        metal = np.zeros((h, h, 3)) + np.array([108, 112, 128]) + (np.abs(xx - h / 2) < h / 6)[..., None] * 30
        wheel = np.zeros((h, h, 3)) + np.array([22, 22, 30])
    else:
        seam = ((yy % (h // 4)) < 2)[..., None] * -10
        fab = np.zeros((h, h, 3)) + np.array([48, 48, 56]) + rng.normal(0, 3, (h, h, 1)) + seam + (1 - yy / h)[..., None] * 10
        shell = np.zeros((h, h, 3)) + np.array([36, 36, 42]) + rng.normal(0, 2, (h, h, 1))
        metal = np.zeros((h, h, 3)) + np.array([118, 120, 130]) + np.cos((xx / h - 0.5) * math.pi * 2)[..., None] * 45
        wheel = np.zeros((h, h, 3)) + np.array([16, 16, 18])
    for tile, pic in ((FABRIC, fab), (SHELL, shell), (METAL, metal), (WHEEL, wheel)):
        u0, v0 = TILE_AT[tile]
        x0, y0 = int(u0 * size), int(v0 * size)
        t[y0:y0 + h, x0:x0 + h, :3] = np.clip(pic, 0, 255).astype(np.uint8)
    return t


# --- The 8 pictures --------------------------------------------------------------

def render(mesh, tex, frame, size, ss):
    """The prop from frame * 45 degrees round it (0: in front), square, one
    half wall across and one half wall high, its foot on the bottom edge -
    as a sprite of scale 0.5 is. Drawn ss times bigger, then shrunk."""
    S = size * ss
    th = frame * math.pi / 4
    eye = np.array([math.cos(th), math.sin(th), 0.0])  # towards you, from the prop
    right = np.array([math.sin(th), -math.cos(th), 0.0])  # your right, as you look at it
    up = np.array([0.0, 0.0, 1.0])
    light = eye * 0.55 + up * 0.8 - right * 0.35; light /= np.linalg.norm(light)  # from over your left shoulder
    col = np.zeros((S, S, 3)); depth = np.full((S, S), -1e9); cover = np.zeros((S, S), bool)
    th_, tw = tex.shape[:2]
    for pts, uvs in mesh.tris:
        P = np.array(pts); U = np.array(uvs)
        n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
        if ln < 1e-12: continue
        n /= ln
        if np.dot(n, eye) <= 0: continue  # facing away
        sx = (P @ right + 0.25) / 0.5 * S; sy = (1 - (P @ up) / 0.5) * S; d = P @ eye
        x0 = max(int(math.floor(sx.min())), 0); x1 = min(int(math.ceil(sx.max())), S - 1)
        y0 = max(int(math.floor(sy.min())), 0); y1 = min(int(math.ceil(sy.max())), S - 1)
        if x0 > x1 or y0 > y1: continue
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1] + 0.5
        den = (sy[1] - sy[2]) * (sx[0] - sx[2]) + (sx[2] - sx[1]) * (sy[0] - sy[2])
        if abs(den) < 1e-12: continue
        w0 = ((sy[1] - sy[2]) * (gx - sx[2]) + (sx[2] - sx[1]) * (gy - sy[2])) / den
        w1 = ((sy[2] - sy[0]) * (gx - sx[2]) + (sx[0] - sx[2]) * (gy - sy[2])) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        z = w0 * d[0] + w1 * d[1] + w2 * d[2]
        win = depth[y0:y1 + 1, x0:x1 + 1]
        hit = inside & (z > win)
        if not hit.any(): continue
        u = w0 * U[0, 0] + w1 * U[1, 0] + w2 * U[2, 0]; v = w0 * U[0, 1] + w1 * U[1, 1] + w2 * U[2, 1]
        texel = tex[np.clip((v * th_).astype(int), 0, th_ - 1), np.clip((u * tw).astype(int), 0, tw - 1), :3].astype(float)
        shade = 0.6 + 0.7 * max(0.0, float(np.dot(n, light)))
        win[hit] = z[hit]
        col[y0:y1 + 1, x0:x1 + 1][hit] = texel[hit] * shade
        cover[y0:y1 + 1, x0:x1 + 1][hit] = True
    # Shrink: each pixel the average of what's covered of its ss x ss, there
    # if over half of it is
    c = col.reshape(size, ss, size, ss, 3); k = cover.reshape(size, ss, size, ss)
    n = k.sum(axis=(1, 3))
    out = np.zeros((size, size, 4), np.uint8)
    rgb = (c * k[..., None]).sum(axis=(1, 3)) / np.maximum(n, 1)[..., None]
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[..., 3] = np.where(n * 2 > ss * ss, 255, 0)
    return out


def write_obj(mesh, path, name):
    lines = [f'# NEON-CASTER prop: {name} - made by models.py (edit that, not this)',
             '# Cells: a wall is 1 high. x the way it faces, y its right-hand side, z up from its floor.',
             '# Every triangle has its own three corners, wound so its normal points out (right hand).']
    for pts, uvs in mesh.tris:
        for p in pts: lines.append('v %.4f %.4f %.4f' % p)
    for pts, uvs in mesh.tris:
        for u, v in uvs: lines.append('vt %.4f %.4f' % (u, 1 - v))  # (OBJ's v runs up from the bottom)
    for k in range(len(mesh.tris)):
        a = 3 * k + 1
        lines.append(f'f {a}/{a} {a + 1}/{a + 1} {a + 2}/{a + 2}')
    open(path, 'w').write('\n'.join(lines) + '\n')


def main():
    write = '--write' in sys.argv
    for name, build in PROPS.items():
        mesh = build()
        print(f'{name}: {len(mesh.tris)} triangles')
        if not write: continue
        os.makedirs(HD, exist_ok=True)
        write_obj(mesh, os.path.join(HERE, name + '.obj'), name)
        for hd, size, ss, folder in ((False, 64, 4, HERE), (True, 256, 2, HD)):
            tex = texture(size, hd)
            Image.fromarray(tex, 'RGBA').save(os.path.join(folder, name + '_tex.png'))
            for f in range(8):
                Image.fromarray(render(mesh, tex, f, size, ss), 'RGBA').save(os.path.join(folder, f'{name}_{f}.png'))
        print(f'  wrote {name}.obj, {name}_tex.png and {name}_0..7.png (and hd/models/)')


if __name__ == '__main__':
    main()
