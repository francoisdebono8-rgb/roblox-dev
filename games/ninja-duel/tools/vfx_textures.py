"""Ninja Duel VFX textures: drawn procedurally, our own art (no third-party
assets). Cel-shaded fire and smoke flipbooks, ground cracks, scorch streaks,
an impact star, a crescent slash, a shock ring, a spark streak and a
lightning flipbook. Run: python3 tools/vfx_textures.py <outdir>
The PNGs are uploaded once to Roblox; their asset ids live in
src/Client/VfxTextures.luau.
"""
import math, os, sys
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, zoom

RNG = np.random.default_rng(7)


def fbm(n, scales=(48, 20, 8), weights=(1, .5, .25), seed=None):
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n))
    for s, w in zip(scales, weights):
        g = gaussian_filter(rng.standard_normal((n, n)), s, mode="wrap")
        g /= g.std() + 1e-9
        out += g * w
    return out / sum(weights)


def grid(n):
    y, x = np.mgrid[0:n, 0:n]
    return (x - n / 2 + .5) / (n / 2), (y - n / 2 + .5) / (n / 2)


def save(rgba, path, size=None):
    img = Image.fromarray(np.clip(rgba * 255, 0, 255).astype(np.uint8), "RGBA")
    if size:
        img = img.resize((size, size) if isinstance(size, int) else size, Image.LANCZOS)
    img.save(path)


def blobs(n, t, seed, count=11, spread=.36, base=.6):
    """A puff: overlapping soft balls that swell with t."""
    x, y = grid(n)
    rng = np.random.default_rng(seed)
    f = np.full((n, n), -10.0)
    for i in range(count):
        a = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(0, spread) * (.55 + .7 * t)
        cx, cy = math.cos(a) * d, math.sin(a) * d * .9 - .08 * t
        r = base * rng.uniform(.55, 1.1) * (.7 + .45 * t)
        f = np.maximum(f, 1 - ((x - cx) ** 2 + (y - cy) ** 2) / (r * r))
    return f


def flipbook(frames, cell):
    side = int(math.sqrt(len(frames)))
    sheet = np.zeros((cell * side, cell * side, 4))
    for i, fr in enumerate(frames):
        r, c = divmod(i, side)
        sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = fr
    return sheet


def fire_frames(n=512, frames=16):
    noise = fbm(n, (40, 16, 6), (1, .6, .3), seed=11)
    erode = fbm(n, (22, 9), (1, .5), seed=12)
    x, y = grid(n)
    out = []
    pal = [  # (t, rim, outer, mid, core)
        (0.0, (.86, .20, .06), (1.0, .46, .10), (1.0, .78, .22), (1.0, .98, .82)),
        (0.35, (.70, .12, .05), (.98, .36, .08), (1.0, .64, .16), (1.0, .90, .50)),
        (0.7, (.30, .08, .06), (.62, .16, .06), (.90, .36, .08), (1.0, .66, .20)),
        (1.0, (.10, .06, .06), (.22, .10, .08), (.38, .16, .08), (.55, .22, .08)),
    ]

    def col(t, k):
        for (t0, *a), (t1, *b) in zip(pal, pal[1:]):
            if t <= t1:
                u = (t - t0) / (t1 - t0)
                return np.array(a[k]) * (1 - u) + np.array(b[k]) * u
        return np.array(pal[-1][k + 1])

    for i in range(frames):
        t = i / (frames - 1)
        f = blobs(n, t, 3) + noise * (.26 + .12 * t)
        th = .02 + .55 * max(0, t - .45) ** 1.2 + np.clip(erode, 0, None) * .5 * max(0, t - .3)
        f = f - th
        img = np.zeros((n, n, 4))
        bands = [(0, col(t, 0)), (.05, col(t, 1)), (.2 + .1 * t, col(t, 2)), (.42 + .2 * t, col(t, 3))]
        # the light comes from up-left: bands shift a little that way
        shade = f + (-x * .06 - y * .08)
        for lo, c in bands:
            m = shade > lo if lo > 0 else f > 0
            img[m, :3] = c
            img[m, 3] = 1
        fade = 1 if t < .8 else 1 - (t - .8) / .2 * .7
        img[..., 3] *= fade
        out.append(img)
    return out


def smoke_frames(n=512, frames=16):
    noise = fbm(n, (36, 14, 6), (1, .6, .3), seed=21)
    erode = fbm(n, (20, 8), (1, .5), seed=22)
    x, y = grid(n)
    out = []
    for i in range(frames):
        t = i / (frames - 1)
        f = blobs(n, t, 5, count=12, spread=.34, base=.56) + noise * .24
        th = .02 + np.clip(erode, 0, None) * .7 * max(0, t - .4) + .4 * max(0, t - .6)
        f = f - th
        img = np.zeros((n, n, 4))
        light = f + (-x * .12 - y * .16)
        m = f > 0
        img[m, :3] = .62
        img[m, 3] = 1
        img[(light > .3) & m, :3] = .84
        img[(light > .62) & m, :3] = 1.0
        img[m & (light < .1), :3] = .42
        fade = 1 if t < .7 else 1 - (t - .7) / .3
        img[..., 3] *= fade
        out.append(img)
    return out


def crack(n=1024):
    img = np.zeros((n, n))
    rng = np.random.default_rng(31)
    from PIL import ImageDraw
    canvas = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(canvas)
    c = n / 2
    rays = 11
    pts = []
    for k in range(rays):
        a = k / rays * 2 * math.pi + rng.uniform(-.2, .2)
        r, px, py = 0, c, c
        line = [(px, py)]
        while r < n * .47:
            step = rng.uniform(18, 40)
            a += rng.uniform(-.35, .35)
            px += math.cos(a) * step
            py += math.sin(a) * step
            r = math.hypot(px - c, py - c)
            line.append((px, py))
            if rng.random() < .22:  # a branch
                ba = a + rng.choice([-1, 1]) * rng.uniform(.5, .9)
                bx, by = px, py
                bl = [(bx, by)]
                for _ in range(rng.integers(2, 5)):
                    ba += rng.uniform(-.3, .3)
                    bx += math.cos(ba) * rng.uniform(14, 28)
                    by += math.sin(ba) * rng.uniform(14, 28)
                    bl.append((bx, by))
                d.line(bl, fill=255, width=max(2, int(9 - r / n * 14)))
        pts.append(line)
        for j in range(len(line) - 1):
            r0 = math.hypot(line[j][0] - c, line[j][1] - c)
            d.line([line[j], line[j + 1]], fill=255, width=max(3, int(16 - r0 / n * 26)))
    # rings joining neighbouring rays (the web)
    for ring in (.12, .22, .33):
        for k in range(rays):
            A, B = pts[k], pts[(k + 1) % rays]
            ia = min(len(A) - 1, int(len(A) * ring / .47)); ib = min(len(B) - 1, int(len(B) * ring / .47))
            if rng.random() < .8:
                mid = ((A[ia][0] + B[ib][0]) / 2 + rng.uniform(-10, 10), (A[ia][1] + B[ib][1]) / 2 + rng.uniform(-10, 10))
                d.line([A[ia], mid, B[ib]], fill=255, width=max(2, int(8 - ring * 14)))
    d.ellipse([c - 30, c - 30, c + 30, c + 30], fill=255)
    a = np.asarray(canvas, float) / 255
    a = np.maximum(a, gaussian_filter(a, 6) * .5)  # a soft dark halo along the cracks
    x, y = grid(n)
    a *= np.clip(1.15 - np.hypot(x, y), 0, 1)
    rgba = np.zeros((n, n, 4))
    rgba[..., :3] = .08
    rgba[..., 3] = np.clip(a * 1.1, 0, 1)
    return rgba


def scorch(n=1024):
    x, y = grid(n)
    r = np.hypot(x, y)
    ang = np.arctan2(y, x)
    rng = np.random.default_rng(41)
    streak = np.zeros((n, n))
    for _ in range(46):
        a0 = rng.uniform(-math.pi, math.pi)
        w = rng.uniform(.012, .05)
        length = rng.uniform(.45, .98)
        da = np.angle(np.exp(1j * (ang - a0)))
        s = np.exp(-(da / w) ** 2) * (r < length) * np.clip((length - r) / .25, 0, 1)
        streak = np.maximum(streak, s)
    core = np.clip(1 - r / .2, 0, 1) ** .8 * .8
    a = np.clip(np.maximum(streak * np.clip(r / .15, 0, 1), core) * (r < 1), 0, 1)
    a = np.where(a > .35, .85, a * 1.2)
    rgba = np.zeros((n, n, 4))
    rgba[..., :3] = .06
    rgba[..., 3] = gaussian_filter(a, 1.2)
    return rgba


def star(n=512):
    x, y = grid(n)
    r = np.hypot(x, y)
    ang = np.arctan2(y, x)
    rng = np.random.default_rng(51)
    spikes = np.zeros((n, n))
    for k in range(16):
        a0 = k / 16 * 2 * math.pi + rng.uniform(-.15, .15)
        length = rng.uniform(.45, .98) if k % 2 else rng.uniform(.75, .98)
        da = np.abs(np.angle(np.exp(1j * (ang - a0))))
        width = .18 * np.clip(1 - r / length, 0, 1)
        spikes = np.maximum(spikes, (da < width).astype(float) * (r < length))
    core = (r < .2).astype(float)
    a = np.maximum(spikes, core)
    a = gaussian_filter(a, 1.0)
    glow = np.exp(-(r / .35) ** 2) * .5
    rgba = np.ones((n, n, 4))
    rgba[..., 3] = np.clip(np.maximum(a, glow), 0, 1)
    return rgba


def slash(w=1024, h=512):
    y, x = np.mgrid[0:h, 0:w]
    cx, cy, R = w / 2, h * 1.55, h * 1.35
    r = np.hypot(x - cx, y - cy)
    a = np.arctan2(x - cx, cy - y)  # 0 at top
    span = .62
    u = np.clip((a + span) / (2 * span), 0, 1)  # 0..1 along the arc
    thick = np.sin(np.pi * u) ** .8 * h * .16 + 1
    d = np.abs(r - R)
    m = (np.abs(a) < span) & (d < thick)
    edge = np.clip(1 - d / thick, 0, 1)
    alpha = m * np.where(edge > .55, 1, edge / .55) * np.clip(u * 3, 0, 1) ** .7
    rgba = np.ones((h, w, 4))
    inner = (r < R) & m
    rgba[..., :3] = np.where(inner[..., None], 1, .82)
    rgba[..., 3] = gaussian_filter(alpha, 1)
    return rgba


def ring(n=512):
    x, y = grid(n)
    r = np.hypot(x, y)
    a = np.exp(-((r - .86) / .05) ** 2) + .35 * np.exp(-((r - .8) / .12) ** 2) * (r < .86)
    rgba = np.ones((n, n, 4))
    rgba[..., 3] = np.clip(a, 0, 1)
    return rgba


def streak(w=128, h=512):
    y, x = np.mgrid[0:h, 0:w]
    u = (x - w / 2) / (w / 2)
    v = y / h
    width = np.clip(np.sin(np.pi * v), 0, 1) ** .6 * .5
    a = np.clip(1 - np.abs(u) / (width + 1e-6), 0, 1) ** 1.5 * (v < 1)
    rgba = np.ones((h, w, 4))
    rgba[..., 3] = a
    return rgba


def lightning_frames(n=512, frames=4):
    from PIL import ImageDraw
    out = []
    for i in range(frames):
        rng = np.random.default_rng(60 + i)
        canvas = Image.new("L", (n, n), 0)
        d = ImageDraw.Draw(canvas)

        def bolt(p, a, length, width, depth):
            pts = [p]
            x, y = p
            seg = length / 9
            for _ in range(9):
                a += rng.uniform(-.7, .7)
                x += math.cos(a) * seg
                y += math.sin(a) * seg
                pts.append((x, y))
                if depth > 0 and rng.random() < .3:
                    bolt((x, y), a + rng.choice([-1, 1]) * rng.uniform(.6, 1.2), length * .45, max(2, width * .6), depth - 1)
            d.line(pts, fill=255, width=int(width), joint="curve")

        for k in range(5):
            a = k / 5 * 2 * math.pi + rng.uniform(-.4, .4)
            bolt((n / 2, n / 2), a, n * .46, 10, 2)
        a = np.asarray(canvas, float) / 255
        glow = gaussian_filter(a, 10) * 1.6
        rgba = np.ones((n, n, 4))
        rgba[..., 3] = np.clip(np.maximum(a, glow), 0, 1)
        out.append(rgba)
    return out


def main(outdir):
    os.makedirs(outdir, exist_ok=True)
    save(flipbook([zoom(f, (.5, .5, 1), order=1) for f in fire_frames()], 256), f"{outdir}/nd_fire_flip.png")
    save(flipbook([zoom(f, (.5, .5, 1), order=1) for f in smoke_frames()], 256), f"{outdir}/nd_smoke_flip.png")
    save(crack(), f"{outdir}/nd_crack.png", 512)
    save(scorch(), f"{outdir}/nd_scorch.png", 512)
    save(star(), f"{outdir}/nd_star.png", 256)
    save(slash(), f"{outdir}/nd_slash.png", (512, 256))
    save(ring(), f"{outdir}/nd_ring.png", 256)
    save(streak(), f"{outdir}/nd_streak.png")
    save(flipbook(lightning_frames(), 512), f"{outdir}/nd_lightning_flip.png", 512)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "vfx_out")
