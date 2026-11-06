"""Ninja Duel — générateur de textures VFX (style « encre et chakra »).

Produit des planches flipbook et des textures fixes en niveaux de gris
ou en couleur, à bords nets (cel-shading) avec un liseré d'encre.
La couleur finale vient en général du ColorSequence de l'émetteur :
les textures « tintables » sont donc en gris (blanc = cœur).

Usage : python3 -I vfxgen.py OUTDIR [nom ...]
"""
from __future__ import annotations
import math, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

RNG = np.random.default_rng(7)

# ---------------------------------------------------------------- bruit
def _value_noise(shape, scale, seed):
    rng = np.random.default_rng(seed)
    gh, gw = max(2, int(shape[0] / scale) + 2), max(2, int(shape[1] / scale) + 2)
    grid = rng.random((gh, gw))
    zoom = (shape[0] / (gh - 1), shape[1] / (gw - 1))
    out = ndimage.zoom(grid, zoom, order=3, mode="grid-wrap")
    return out[: shape[0], : shape[1]]

def fbm(shape, scale=32, octaves=4, seed=0):
    acc = np.zeros(shape); amp = 1.0; tot = 0.0
    for o in range(octaves):
        acc += amp * _value_noise(shape, scale / (2 ** o), seed + o * 101)
        tot += amp; amp *= 0.5
    acc /= tot
    return (acc - acc.min()) / (np.ptp(acc) + 1e-9)

def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(float)
    c = (n - 1) / 2
    return (x - c) / c, (y - c) / c   # -1..1

def smooth_band(v, lo, soft=0.02):
    return np.clip((v - lo) / soft + 0.5, 0, 1)

def ink_outline(mask, width=2):
    """Liseré d'encre autour d'un masque binaire (0..1)."""
    m = mask > 0.5
    dil = ndimage.binary_dilation(m, iterations=width)
    return (dil & ~m).astype(float)

def to_img(rgba):
    return Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")

def sheet(frames, cols):
    n = frames[0].size[0]
    rows = math.ceil(len(frames) / cols)
    out = Image.new("RGBA", (n * cols, n * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, ((i % cols) * n, (i // cols) * n))
    return out

def pad_frame(img, pad=0.06):
    """Laisse une marge transparente (évite les fuites entre cases)."""
    n = img.size[0]; k = int(n * (1 - 2 * pad))
    small = img.resize((k, k), Image.LANCZOS)
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0)); out.paste(small, ((n - k) // 2, (n - k) // 2))
    return out

# ---------------------------------------------------------------- textures
def cel_burst(n=256, frames=16, seed=1, tongues=7, smoke_from=0.55, rise=0.25, fill=0.95):
    """Explosion / flamme en aplats : langues de feu, cœur blanc, corps, bord, puis fumée.
    Sortie en gris à 3 tons + liseré d'encre ; la couleur vient de l'émetteur."""
    X, Y = grid(n)
    out = []
    for f in range(frames):
        t = f / (frames - 1)
        grow = fill * (0.25 + 0.75 * (1 - (1 - min(1, t * 1.8)) ** 3))
        cy = Y + rise * t
        r = np.sqrt(X ** 2 + cy ** 2)
        ang = np.arctan2(cy, X)
        nz_ang = fbm((n, n), 22, 3, seed + f) 
        tongue = 0.5 + 0.5 * np.cos(ang * tongues + nz_ang * 5 + t * 2)
        edge = grow * (0.62 + 0.38 * tongue ** 1.5)
        holes = fbm((n, n), 26, 3, seed + 400 + f)
        shape = (r < edge) & (holes > t ** 1.4 * 0.95)
        shape = ndimage.binary_opening(shape, iterations=1)
        if shape.sum() < 10:
            out.append(Image.new("RGBA", (n, n), (0, 0, 0, 0))); continue
        k_core = max(0.0, 0.5 - t * 0.6)
        k_mid = max(0.0, 0.78 - t * 0.5)
        tone = np.full((n, n), 0.42)
        tone = np.where(r < edge * k_mid, 0.72, tone)
        tone = np.where(r < edge * k_core, 1.0, tone)
        if t > smoke_from:
            k = (t - smoke_from) / (1 - smoke_from)
            tone = tone * (1 - 0.6 * k)
        sh = shape.astype(float)
        ink = ink_outline(sh, 3)
        g = np.where(ink > 0, 0.0, tone)
        fade = 1 - max(0, t - 0.82) / 0.18
        a = np.clip(sh + ink, 0, 1) * fade
        out.append(pad_frame(to_img(np.dstack([g, g, g, a])), 0.03))
    return out

def cel_smoke(n=256, frames=16, seed=11):
    return cel_burst(n, frames, seed, tongues=4, smoke_from=0.0, rise=0.45, fill=0.9)

def impact_star(n=512, spikes=11, seed=3, ink=True):
    """Étoile d'impact : pointes inégales, cœur blanc, contre-forme d'encre derrière."""
    X, Y = grid(n)
    ang = np.arctan2(Y, X); r = np.sqrt(X ** 2 + Y ** 2)
    rng = np.random.default_rng(seed)
    lens = rng.uniform(0.45, 1.0, spikes); phase = rng.uniform(0, 2 * np.pi)
    a = (ang + phase) % (2 * np.pi) / (2 * np.pi) * spikes
    i = np.floor(a).astype(int) % spikes; frac = a - np.floor(a)
    tri = 1 - np.abs(frac - 0.5) * 2          # 0 aux creux, 1 aux pointes
    reach = 0.22 + (lens[i] * 0.95 - 0.22) * tri ** 2.2
    white = smooth_band(reach - r, 0.0, 0.01)
    core = smooth_band(0.2 - r, 0.0, 0.01)
    if ink:
        reach2 = 0.3 + (np.roll(lens, 1)[i] * 1.0 - 0.3) * tri ** 1.6
        black = smooth_band(reach2 - r, 0.0, 0.01) * (1 - white)
    else:
        black = np.zeros_like(white)
    g = np.clip(white, 0, 1)
    alpha = np.clip(white + black + core, 0, 1)
    return to_img(np.dstack([g, g, g, alpha]))

def shock_ring(n=512, seed=4):
    """Anneau d'onde de choc net, épaisseur variable et deux brèches."""
    X, Y = grid(n); r = np.sqrt(X ** 2 + Y ** 2); ang = np.arctan2(Y, X)
    w = 0.025 + 0.05 * (0.5 + 0.5 * np.cos(ang * 2 + 0.7)) ** 2
    ring = smooth_band(w - np.abs(r - 0.84), 0, 0.006)
    gaps = 0.5 + 0.5 * np.cos(ang * 2 - 1.9)
    ring *= smooth_band(gaps, 0.12, 0.05)
    g = np.ones_like(ring)
    return to_img(np.dstack([g, g, g, ring]))

def lightning_arcs(n=256, frames=8, seed=21):
    """Arcs ramifiés, cœur blanc + halo (additif, à teinter)."""
    out = []
    for f in range(frames):
        rng = np.random.default_rng(seed + f)
        img = Image.new("L", (n, n), 0); d = ImageDraw.Draw(img)
        def bolt(x, y, ang, length, width, depth):
            pts = [(x, y)]
            seg = max(3, int(length / 10))
            for _ in range(seg):
                ang += rng.normal(0, 0.55)
                x += math.cos(ang) * length / seg; y += math.sin(ang) * length / seg
                pts.append((x, y))
                if depth < 2 and rng.random() < 0.28:
                    bolt(x, y, ang + rng.choice([-1, 1]) * rng.uniform(0.5, 1.2), length * 0.45, max(1, width - 1), depth + 1)
            d.line(pts, fill=255, width=width, joint="curve")
        c = n / 2
        for k in range(rng.integers(2, 4)):
            a0 = rng.uniform(0, 2 * np.pi)
            bolt(c, c, a0, n * rng.uniform(0.35, 0.48), 3, 0)
        core = np.asarray(img, float) / 255
        halo = np.asarray(img.filter(ImageFilter.GaussianBlur(5)), float) / 255
        g = np.clip(core + halo * 1.6, 0, 1)
        out.append(pad_frame(to_img(np.dstack([g, g, g, g])), 0.03))
    return out

def wind_crescent(n=512):
    """Lame de vent : croissant effilé (haut de l'image), arête blanche, corps translucide."""
    X, Y = grid(n)
    cy = 0.75
    r = np.sqrt(X ** 2 + (Y - cy) ** 2); ang = np.arctan2(Y - cy, X)
    a0, a1 = -np.pi * 0.92, -np.pi * 0.08          # arc supérieur
    u = np.clip((ang - a0) / (a1 - a0), 0, 1)
    inarc = (ang > a0) & (ang < a1)
    w = 0.2 * np.sin(np.pi * u) ** 1.3
    body = inarc & (r > 1.2 - w) & (r < 1.2)
    edge = inarc & (r > 1.2 - 0.025) & (r < 1.2) & (w > 0.03)
    b = body.astype(float); e = edge.astype(float)
    ink = ink_outline(b, 2) * 0.0
    g = np.clip(0.62 + e * 0.38, 0, 1)
    a = np.clip(b * 0.6 + e * 0.4, 0, 1)
    return to_img(np.dstack([g, g, g, a]))

def swirl_tile(n=512, arms=3, seed=5):
    """Tuile de tourbillon (Rasengan, Kaiten) : bandes spirales à bords nets."""
    X, Y = grid(n); ang = np.arctan2(Y, X); r = np.sqrt(X ** 2 + Y ** 2)
    nz = fbm((n, n), 40, 3, seed)
    s = np.sin(ang * arms + r * 9 + nz * 2.5)
    band = smooth_band(s, 0.35, 0.06)
    hi = smooth_band(s, 0.8, 0.04)
    g = np.clip(0.6 + hi * 0.4, 0, 1)
    a = np.clip(band * smooth_band(1.0 - r, 0, 0.05), 0, 1)
    return to_img(np.dstack([g, g, g, a]))

def dust_debris(n=256, frames=4, seed=31):
    """Silhouettes de cailloux anguleux (2x2), tintés couleur du sol."""
    out = []
    for f in range(frames):
        rng = np.random.default_rng(seed + f)
        img = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
        k = rng.integers(5, 8); c = n / 2
        pts = [(c + math.cos(a) * n * rng.uniform(0.25, 0.42), c + math.sin(a) * n * rng.uniform(0.25, 0.42))
               for a in sorted(rng.uniform(0, 2 * math.pi, k))]
        d.polygon(pts, fill=(170, 170, 170, 255), outline=(0, 0, 0, 255), width=4)
        hi = [(x * 0.6 + c * 0.4 - n * 0.04, y * 0.6 + c * 0.4 - n * 0.05) for x, y in pts[: max(3, k // 2)]]
        d.polygon(hi, fill=(235, 235, 235, 255))
        out.append(img)
    return out

RECIPES = {
    "fx_burst_cel_4x4": lambda: sheet(cel_burst(), 4),
    "fx_smoke_cel_4x4": lambda: sheet(cel_smoke(), 4),
    "fx_impact_star_ink": lambda: impact_star(),
    "fx_impact_star_clean": lambda: impact_star(ink=False, seed=9, spikes=9),
    "fx_shock_ring": lambda: shock_ring(),
    "fx_lightning_4x2": lambda: sheet(lightning_arcs(), 4),
    "fx_wind_crescent": lambda: wind_crescent(),
    "fx_swirl_tile": lambda: swirl_tile(),
    "fx_debris_2x2": lambda: sheet(dust_debris(), 2),
}

if __name__ == "__main__":
    outdir = Path(sys.argv[1]); outdir.mkdir(parents=True, exist_ok=True)
    names = sys.argv[2:] or list(RECIPES)
    for name in names:
        img = RECIPES[name]()
        img.save(outdir / f"{name}.png", optimize=True)
        print(name, img.size)
