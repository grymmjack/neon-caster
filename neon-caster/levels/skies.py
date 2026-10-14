"""Paint NEON-CASTER's skies: sky-*.png, MODERN (512, hd/) and CLASSIC (64,
pixel art). A sky is a panorama drawn by view angle: across, the whole way round (360
degrees: it must tile left to right); down, from 72 degrees up (top row) to
the horizon (bottom row). It's painted 2560 x 512 (square degrees: 1 pixel
is 0.14 degrees each way) and squeezed into the square picture the game
loads, which the game stretches back out round you. Most of what you see looking level is the bottom
40%: the moon, the sun and the skyline live there.

    python skies.py ASSETDIR      (writes ASSETDIR/sky-*.png and ASSETDIR/hd/sky-*.png;
                                   needs numpy and Pillow)
"""
import os, sys, math
import numpy as np
from PIL import Image, ImageFilter

N = 512                     # height (and the size of a noise "period")
W = N * 5                   # width: 360 degrees at the same scale as 72 up
rng = np.random.default_rng(14)
yy, xx = np.mgrid[0:N, 0:W].astype(np.float32)
V = yy / (N - 1)            # 0 top .. 1 horizon
EL = (1 - V) * 72.0         # degrees above the horizon


def vnoise(period, seed, aspect=1.0):
    """Value noise that tiles left to right: cells N/period pixels wide."""
    r = np.random.default_rng(seed)
    px = period * W // N        # cells right round
    gy = int(math.ceil(period * aspect)) + 2
    g = r.random((gy, px)).astype(np.float32)
    fx = xx / N * period
    fy = yy / N * period * aspect
    x0 = np.floor(fx).astype(int); y0 = np.floor(fy).astype(int)
    tx = fx - x0; ty = fy - y0
    tx = tx * tx * (3 - 2 * tx); ty = ty * ty * (3 - 2 * ty)
    x1 = (x0 + 1) % px; x0 = x0 % px; y1 = np.minimum(y0 + 1, gy - 1)
    a = g[y0, x0]; b = g[y0, x1]; c = g[y1, x0]; d = g[y1, x1]
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def fbm(period, seed, octaves=5, aspect=1.0):
    s = np.zeros((N, W), np.float32); amp = 1.0; tot = 0.0
    for o in range(octaves):
        s += vnoise(period * 2 ** o, seed + o * 17, aspect) * amp
        tot += amp; amp *= 0.5
    return s / tot


def grad(stops):
    """A colour per row from (v, (r, g, b)) stops."""
    vs = [s[0] for s in stops]
    out = np.zeros((N, W, 3), np.float32)
    for ch in range(3):
        col = np.interp(V[:, 0], vs, [s[1][ch] for s in stops])
        out[:, :, ch] = col[:, None]
    return out


def add_glow(img, cx, cy, radius, color, power=2.0, wrap=True):
    dx = np.abs(xx - cx)
    if wrap:
        dx = np.minimum(dx, W - dx)
    d = np.sqrt(dx ** 2 + (yy - cy) ** 2) / radius
    g = np.clip(1 - d, 0, 1) ** power
    img += g[:, :, None] * np.array(color, np.float32)


def disc(img, cx, cy, r, color, soft=1.5):
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    a = np.clip((r - d) / soft + 0.5, 0, 1)
    img[:] = img * (1 - a[:, :, None]) + a[:, :, None] * np.array(color, np.float32)
    return a


def stars(img, count, seed, vmax=0.8, bright=1.0, tint=((255, 255, 255),)):
    r = np.random.default_rng(seed)
    for _ in range(count * 5):
        x = r.integers(0, W); y = int(r.random() ** 1.6 * vmax * N)
        b = (0.3 + r.random() * 0.7) * bright
        c = np.array(tint[r.integers(0, len(tint))], np.float32) * b
        img[y, x] = np.maximum(img[y, x], c)
        if r.random() < 0.08:  # a bright one: a small cross
            for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                img[min(N - 1, max(0, y + ddy)), (x + ddx) % W] = np.maximum(img[min(N - 1, max(0, y + ddy)), (x + ddx) % W], c * 0.5)


def skyline(img, seed, top, base_col, window_cols, haze_col=None, density=0.55):
    """Buildings along the bottom: tiling, their tops up to `top` (rows from the bottom), lit windows."""
    r = np.random.default_rng(seed)
    hts = np.zeros(W, int)
    x = 0
    while x < W:
        w = int(r.integers(10, 34)); h = int(top * (0.35 + 0.65 * r.random()))
        hts[x:min(W, x + w)] = h
        if r.random() < 0.25:  # an antenna
            ax = x + w // 2
            if ax < W:
                hts[ax] = max(hts[ax], h + int(r.integers(6, 18)))
        x += w + int(r.integers(0, 4))
    hts[W - 6:] = hts[:6]  # (the seam)
    if haze_col is not None:
        for x in range(W):
            for y in range(N - hts[x] - 18, N - hts[x]):
                if 0 <= y < N:
                    t = 1 - (N - hts[x] - y) / 18
                    img[y, x] = img[y, x] * (1 - 0.35 * t) + np.array(haze_col, np.float32) * 0.35 * t
    for x in range(W):
        img[N - hts[x]:, x] = base_col
    for x in range(1, W - 1, 3):
        for y in range(N - hts[x] + 4, N - 2, 4):
            if r.random() < density * 0.35:
                c = np.array(window_cols[r.integers(0, len(window_cols))], np.float32) * (0.6 + 0.4 * r.random())
                img[y, x] = c
                img[y, x + 1] = c * 0.8


def save(img, name, outdir):
    a = np.clip(img, 0, 255).astype(np.uint8)
    hd = Image.fromarray(a, "RGB").resize((N, N), Image.LANCZOS)  # (squeezed: the game stretches it back round you)
    os.makedirs(os.path.join(outdir, "hd"), exist_ok=True)
    hd.save(os.path.join(outdir, "hd", name))
    # CLASSIC: 64 across, few colours, like the rest of the pixel art
    small = hd.resize((64, 64), Image.BOX).quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    small.save(os.path.join(outdir, name))
    print("wrote", name)


def neon_night():
    img = grad([(0.0, (4, 3, 14)), (0.55, (14, 8, 38)), (0.85, (48, 14, 72)), (1.0, (120, 30, 110))])
    stars(img, 900, 3, vmax=0.82, tint=((255, 255, 255), (180, 220, 255), (255, 200, 240)))
    cl = fbm(6, 40, 5, aspect=0.5)
    cl = np.clip((cl - 0.52) * 3.0, 0, 1) * np.clip((V - 0.35) * 2.5, 0, 1)
    img = img * (1 - cl[:, :, None] * 0.6) + cl[:, :, None] * np.array((70, 30, 100), np.float32) * 0.6
    add_glow(img, 900, 300, 120, (60, 90, 130), 2.0)
    disc(img, 900, 300, 26, (215, 235, 255))
    for (mx, my, mr) in ((892, 292, 6), (910, 308, 4), (904, 290, 3)):  # its craters
        disc(img, mx, my, mr, (180, 200, 230), 1.0)
    for cx in (300, 1500, 2200):
        add_glow(img, cx, N + 40, 420, (110, 20, 90), 1.6)  # the city's glow on the haze
    skyline(img, 7, 90, (8, 6, 18), ((255, 70, 210), (70, 230, 255), (255, 200, 90)), (90, 30, 110))
    return img


def dusk():
    img = grad([(0.0, (22, 16, 60)), (0.45, (90, 30, 110)), (0.72, (210, 70, 110)), (0.9, (255, 150, 90)), (1.0, (255, 210, 130))])
    add_glow(img, 1400, 455, 600, (255, 120, 70), 2.0)  # the west: the glow the sun's going down into
    add_glow(img, 1400, 455, 170, (255, 170, 80), 2.2)
    disc(img, 1400, 455, 30, (255, 236, 190), 2.5)
    st = fbm(3, 9, 6, aspect=5.0)  # streaks: stretched across
    st = np.clip((st - 0.5) * 3.2, 0, 1) * np.clip((V - 0.25) * 2.0, 0, 1)
    lit = np.clip((V - 0.55) * 2.0, 0, 1)
    cloud = np.array((70, 30, 80), np.float32)[None, None, :] * (1 - lit[:, :, None]) + np.array((255, 120, 110), np.float32)[None, None, :] * lit[:, :, None]
    img = img * (1 - st[:, :, None] * 0.75) + cloud * st[:, :, None] * 0.75
    stars(img, 160, 5, vmax=0.3, bright=0.6)
    skyline(img, 21, 70, (24, 10, 34), ((255, 200, 120), (255, 120, 80)), None, density=0.35)
    return img


def storm():
    img = grad([(0.0, (18, 22, 24)), (0.6, (40, 52, 52)), (1.0, (70, 86, 80))])
    c1 = fbm(4, 77, 6, aspect=1.8)  # billows: wider than tall
    c2 = fbm(8, 91, 5, aspect=1.8)
    dark = np.clip((c1 - 0.3) * 1.8, 0, 1)
    img = img * (1 - dark[:, :, None] * 0.6)
    lit = np.clip((c2 - 0.55) * 3.0, 0, 1) * (1 - dark) * 0.5  # the tops of the billows, catching light
    img += lit[:, :, None] * np.array((110, 130, 125), np.float32)
    add_glow(img, 400, 380, 140, (120, 170, 255), 2.4)  # lightning inside the clouds
    add_glow(img, 1290, 330, 90, (90, 140, 230), 2.4)
    add_glow(img, 2050, 360, 110, (110, 160, 240), 2.4)
    # a bolt
    r = np.random.default_rng(3); x = 404.0; y = 380
    while y < N - 40:
        nx = x + r.normal(0, 3.5); ny = y + int(r.integers(4, 9))
        for t in np.linspace(0, 1, 12):
            px = int(x + (nx - x) * t) % W; py = int(y + (ny - y) * t)
            for w in (-1, 0, 1):
                img[py, (px + w) % W] = np.maximum(img[py, (px + w) % W], (200, 220, 255) if w == 0 else (110, 150, 230))
        x, y = nx, ny
    skyline(img, 5, 60, (14, 18, 18), ((160, 255, 180), (255, 220, 120)), None, density=0.25)
    return img


def orbit():
    img = grad([(0.0, (2, 2, 6)), (1.0, (6, 4, 16))])
    neb = fbm(5, 300, 6)
    neb2 = fbm(7, 333, 6)
    m = np.clip((neb - 0.45) * 2.4, 0, 1) ** 1.5
    img += m[:, :, None] * np.array((40, 160, 170), np.float32) * 0.7
    m2 = np.clip((neb2 - 0.5) * 2.4, 0, 1) ** 1.5
    img += m2[:, :, None] * np.array((190, 40, 150), np.float32) * 0.6
    stars(img, 2200, 8, vmax=1.0, tint=((255, 255, 255), (170, 210, 255), (255, 220, 200)))
    # a ringed gas giant, low in the sky
    cx, cy, R = 1280, 360, 80
    ring_back = np.abs(((xx - cx) / 1.7) ** 2 + ((yy - cy) * 2.6) ** 2 - (R * 1.35) ** 2) < R * 22
    ring_back &= yy < cy
    img[ring_back] = img[ring_back] * 0.3 + np.array((210, 180, 140), np.float32) * 0.7
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    planet = d < R
    band = 0.5 + 0.5 * np.sin((yy - cy) / R * 9 + vnoise(8, 5) * 2)
    shade = np.clip(1 - ((xx - cx) + (yy - cy) * 0.4) / (R * 1.6), 0.15, 1)
    pc = (np.array((200, 120, 90), np.float32)[None, None, :] * band[:, :, None] + np.array((120, 70, 120), np.float32)[None, None, :] * (1 - band[:, :, None])) * shade[:, :, None]
    img[planet] = pc[planet]
    ring_front = np.abs(((xx - cx) / 1.7) ** 2 + ((yy - cy) * 2.6) ** 2 - (R * 1.35) ** 2) < R * 22
    ring_front &= yy >= cy
    img[ring_front] = img[ring_front] * 0.25 + np.array((230, 200, 160), np.float32) * 0.75
    add_glow(img, cx, cy, R * 1.5, (60, 40, 50), 2.0)
    return img


if __name__ == "__main__":
    out = sys.argv[1]
    for name, fn in (("sky-neon-night.png", neon_night), ("sky-dusk.png", dusk), ("sky-storm.png", storm), ("sky-orbit.png", orbit)):
        save(fn(), name, out)
