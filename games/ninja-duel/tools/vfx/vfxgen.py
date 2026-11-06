"""Ninja Duel — générateur de textures VFX, direction « animé » (06/11).

Révision après retour de François : le cartoon faisait « bébé ». L'animé domine :
- formes effilées, pointes vives, aucun contour noir épais (au plus un liseré fin) ;
- lumière et ombre tranchées : 2 ou 3 tons à bord net, jamais de dégradé mou ;
- fumées et flammes qui se DÉCHIRENT (seuil de bruit qui monte) au lieu de gonfler en bulles ;
- le cartoon ne garde que la vivacité des couleurs, portée par les émetteurs.

Textures en niveaux de gris « tintables » (blanc = cœur) sauf feu, feuilles, plumes,
sceau et décalques, cuits en couleur. Flipbooks en grille 4x4 de 1024 px.

Usage : python3 -I vfxgen.py OUTDIR [nom ...]
"""
from __future__ import annotations
import math, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

INK = np.array([0.07, 0.05, 0.07])

# ---------------------------------------------------------------- outils
def _value_noise(shape, scale, seed):
    rng = np.random.default_rng(seed)
    gh, gw = max(2, int(shape[0] / scale) + 2), max(2, int(shape[1] / scale) + 2)
    grid_ = rng.random((gh, gw))
    out = ndimage.zoom(grid_, (shape[0] / (gh - 1), shape[1] / (gw - 1)), order=3, mode="grid-wrap")
    return out[: shape[0], : shape[1]]

def fbm(shape, scale=32, octaves=4, seed=0):
    acc = np.zeros(shape); amp = 1.0; tot = 0.0
    for o in range(octaves):
        acc += amp * _value_noise(shape, scale / (2 ** o), seed + o * 101); tot += amp; amp *= 0.5
    acc /= tot
    return (acc - acc.min()) / (np.ptp(acc) + 1e-9)

def sampler(N):
    """Échantillonne une tuile de bruit périodique en coordonnées locales ([-1,1] = une tuile)."""
    n = N.shape[0]
    def sample(XX, YY):
        return ndimage.map_coordinates(N, [(YY + 1) * 0.5 * n, (XX + 1) * 0.5 * n], order=1, mode="grid-wrap")
    return sample

def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(float)
    c = (n - 1) / 2
    return (x - c) / c, (y - c) / c

def soft(mask, px=0.8):
    return np.clip(ndimage.gaussian_filter(mask.astype(float), px), 0, 1)

def outline(mask, width):
    m = mask > 0.5
    return ndimage.binary_dilation(m, iterations=width) & ~m

def compose(layers, n):
    rgb = np.zeros((n, n, 3)); a = np.zeros((n, n))
    for mask, col in layers:
        m = soft(mask)
        c = np.array(col if np.ndim(col) else (col, col, col), float)
        rgb = rgb * (1 - m[..., None]) + c * m[..., None]
        a = np.maximum(a, m)
    return np.dstack([rgb, a])

def to_img(rgba):
    return Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")

def sheet(frames, cols=4):
    n = frames[0].size[0]; rows = math.ceil(len(frames) / cols)
    out = Image.new("RGBA", (n * cols, n * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, ((i % cols) * n, (i // cols) * n))
    return out

def disc(X, Y, cx, cy, r):
    return (X - cx) ** 2 + (Y - cy) ** 2 < r * r

def ease_out(t):
    return 1 - (1 - t) ** 3

def rot(X, Y, a):
    return X * math.cos(a) + Y * math.sin(a), -X * math.sin(a) + Y * math.cos(a)

# ---------------------------------------------------------------- éclats
def star(n=512, spikes=15, seed=3):
    """Étoile d'impact : pointes fines de longueurs inégales, ombre portée sombre derrière, liseré fin."""
    X, Y = grid(n); r = np.sqrt(X ** 2 + Y ** 2); ang = np.arctan2(Y, X)
    rng = np.random.default_rng(seed)
    lens = rng.uniform(0.42, 1.0, spikes); ph = rng.uniform(0, 2 * np.pi)
    a = (ang + ph) % (2 * np.pi) / (2 * np.pi) * spikes
    i = np.floor(a).astype(int) % spikes; f = a - np.floor(a)
    tri = 1 - np.abs(f - 0.5) * 2
    body = r < 0.16 + (lens[i] * 0.9 - 0.16) * tri ** 3.2
    back = r < 0.24 + (np.roll(lens, 3)[i] * 0.98 - 0.24) * tri ** 2.2
    core = r < 0.1 + 0.08 * tri ** 3
    return to_img(compose([(back | outline(body, 3), INK), (body, 1.0), (core, 1.0)], n))

def impact_lines(n=512, count=26, seed=8):
    """Traits d'impact autour du point touché (pas au bord de l'écran) : coins effilés vers le centre."""
    rng = np.random.default_rng(seed)
    img = Image.new("L", (n, n), 0); d = ImageDraw.Draw(img); c = n / 2
    for k in range(count):
        a = (k + rng.uniform(-0.35, 0.35)) * 2 * math.pi / count
        r0 = rng.uniform(0.34, 0.55); r1 = rng.uniform(0.82, 0.98); w = rng.uniform(0.012, 0.03)
        tip = (c + math.cos(a) * r0 * c, c + math.sin(a) * r0 * c)
        b1 = (c + math.cos(a - w) * r1 * c, c + math.sin(a - w) * r1 * c)
        b2 = (c + math.cos(a + w) * r1 * c, c + math.sin(a + w) * r1 * c)
        d.polygon([tip, b1, b2], fill=255)
    g = np.asarray(img.resize((n * 2, n * 2), Image.BICUBIC).resize((n, n), Image.LANCZOS), float) / 255
    return to_img(np.dstack([np.ones_like(g)] * 3 + [g]))

def spark(n=256):
    """Étincelle-aiguille (VelocityParallel) : tête en haut, queue très fine."""
    X, Y = grid(n)
    v = np.clip((Y + 0.95) / 1.9, 0, 1)                      # 0 tête, 1 queue
    w = 0.11 * np.minimum(1, v / 0.12) ** 0.7 * (1 - v) ** 1.3
    m = np.abs(X) < w
    hot = np.abs(X) < w * 0.45
    return to_img(compose([(m, 0.75), (hot, 1.0)], n))

def ring(n=512, gaps=3, seed=2):
    """Onde de choc : trait fin qui s'effile en pointes à chaque brèche, écho intérieur plus pâle."""
    X, Y = grid(n); r = np.sqrt(X ** 2 + Y ** 2); ang = np.arctan2(Y, X)
    rng = np.random.default_rng(seed)
    u = ((ang + rng.uniform(0, 6)) * gaps / (2 * np.pi)) % 1
    seg = np.clip((u - 0.06) / 0.88, 0, 1) * ((u > 0.06) & (u < 0.94))
    w = 0.04 * np.sin(np.pi * seg) ** 0.7
    outer = np.abs(r - 0.86) < w
    u2 = ((ang + 1.1) * gaps / (2 * np.pi)) % 1
    seg2 = np.clip((u2 - 0.2) / 0.6, 0, 1) * ((u2 > 0.2) & (u2 < 0.8))
    inner = np.abs(r - 0.74) < 0.016 * np.sin(np.pi * seg2) ** 0.7
    return to_img(compose([(inner, 0.6), (outer, 1.0)], n))

# ---------------------------------------------------------------- fumée qui se déchire
def smoke_frames(n=256, frames=16, seed=11, flat=1.0, stretch=1.0, rise=0.3):
    """Fumée d'animé : masse découpée par un bruit, 2 tons à bord net (éclairée en haut à
    gauche), qui se déchire en lambeaux quand le seuil monte. Aucun contour."""
    X, Y = grid(n)
    s1 = sampler(fbm((n, n), 72, 3, seed)); s2 = sampler(fbm((n, n), 34, 2, seed + 7))
    edge = np.clip((0.97 - np.maximum(np.abs(X), np.abs(Y))) / 0.06, 0, 1)   # jamais coupé par le bord de case
    rng = np.random.default_rng(seed)
    lobes = [(0.0, 0.08, 0.62)] + [(math.cos(a) * 0.42, math.sin(a) * 0.36, rng.uniform(0.38, 0.52))
                                    for a in np.linspace(0, 2 * np.pi, 5, endpoint=False) + rng.uniform(0, 1)]
    out = []
    for f in range(frames):
        t = f / (frames - 1)
        g = 0.72 * (0.3 + 0.7 * ease_out(min(1, t * 2.4)))
        def field(XX, YY):
            u = XX / (g * stretch); v = (YY + rise * t) / (g * flat)
            base = np.full(u.shape, -1.0)                     # volutes : max de plusieurs lobes
            for cx, cy, rr in lobes:
                sp = 1 + 0.35 * t
                base = np.maximum(base, 1 - np.sqrt((u - cx * sp) ** 2 + (v - cy * sp) ** 2) / rr)
            nz = s1(u * 0.8 + 0.1 * t, v * 0.8 - 0.25 * t) * 0.72 + s2(u * 1.5, v * 1.5 - 0.5 * t) * 0.28
            return base * (0.95 - 0.35 * t) + (nz - 0.45) * (0.55 + 0.45 * t)
        thr = 0.12 + 0.6 * max(0.0, (t - 0.22) / 0.78) ** 1.2
        F = field(X, Y) * edge
        body = F > thr
        lit = body & (field(X + 0.08 * g, Y + 0.08 * g) > thr + 0.05)
        out.append(to_img(compose([(body, 0.5), (lit, 0.92)], n)))
    return out

# ---------------------------------------------------------------- feu (couleurs cuites)
FIRE = {"core": (1.0, 0.98, 0.9), "yellow": (1.0, 0.86, 0.32), "orange": (1.0, 0.52, 0.12),
        "red": (0.9, 0.22, 0.1), "smoke": (0.24, 0.19, 0.2)}

def _mix(a, b, k):
    return tuple(x + (y - x) * k for x, y in zip(a, b))

def fire_burst_frames(n=256, frames=16, seed=1):
    """Gerbe de feu : langues pointues irrégulières, bandes de chaleur nettes, puis la masse
    refroidit en fumée sombre et se déchire."""
    X, Y = grid(n)
    rng = np.random.default_rng(seed)
    harm = [(k, rng.uniform(0.4, 1.0), rng.uniform(0, 2 * np.pi)) for k in (5, 7, 9, 12)]
    s = sampler(fbm((n, n), 40, 3, seed))
    out = []
    for f in range(frames):
        t = f / (frames - 1)
        g = 0.28 + 0.72 * ease_out(min(1, t * 2.6))
        u = X / g; v = (Y + 0.3 * t * t) / g
        r = np.sqrt(u * u + v * v); ang = np.arctan2(v, u)
        P = sum(a * np.cos(k * (ang + 0.12 * t) + ph) for k, a, ph in harm)
        P = (P - P.min()) / (np.ptp(P) + 1e-9)
        reach = 0.42 + 0.56 * P ** 2.4                          # pointes, pas de rondeurs
        F = 1 - r / reach + (s(u * 0.9, v * 0.9 - 0.6 * t) - 0.5) * 0.55
        thr = 0.04 + 0.86 * max(0.0, (t - 0.3) / 0.7) ** 1.15
        body = F > thr
        cool = min(1.0, max(0.0, (t - 0.4) / 0.35))
        heat = 1 - t
        layers = [(body, _mix(FIRE["red"], FIRE["smoke"], cool)),
                  (F > thr + 0.1 + 0.25 * (1 - heat), _mix(FIRE["orange"], FIRE["smoke"], cool ** 0.6)),
                  (F > thr + 0.26 + 0.5 * (1 - heat), FIRE["yellow"]),
                  (F > thr + 0.46 + 0.7 * (1 - heat), FIRE["core"])]
        out.append(to_img(compose(layers, n)))
    return out

def flame_loop_frames(n=256, frames=16, seed=4):
    """Flamme qui dure (boucle parfaite) : langues qui montent et se détachent en flammèches."""
    X, Y = grid(n)
    s = sampler(fbm((n, n), 36, 3, seed))
    h = np.clip((0.95 - Y) / 1.9, 0, 1)                       # 0 base, 1 sommet
    out = []
    for f in range(frames):
        ph = f / frames
        sway = 0.06 * np.sin(2 * np.pi * ph + h * 4) * h
        w = 0.5 * (1 - h * 0.55)
        base = 1 - np.abs(X - sway) / w - h * 0.95
        nz = s(X * 1.3, Y * 0.7 + 2 * ph)                    # défilement d'une tuile entière : boucle
        F = base + (nz - 0.5) * (0.35 + 0.75 * h)
        body = (F > 0.06) & (Y < 0.93)
        layers = [(body, FIRE["red"]), (F > 0.22, FIRE["orange"]), (F > 0.4, FIRE["yellow"]), (F > 0.6, FIRE["core"])]
        out.append(to_img(compose(layers, n)))
    return out

# ---------------------------------------------------------------- foudre (additif, gris)
def lightning_frames(n=256, frames=8, seed=21):
    """Arc électrique : zigzag à segments droits d'un bord à l'autre, micro-dents, cœur blanc
    fin, halo doux teinté par l'émetteur. Additif."""
    out = []
    for f in range(frames):
        rng = np.random.default_rng(seed + f)
        img = Image.new("L", (n, n), 0); d = ImageDraw.Draw(img)
        def bolt(x0, y0, x1, y1, width, depth):
            seg = int(rng.integers(6, 9)); pts = [(x0, y0)]
            L = math.hypot(x1 - x0, y1 - y0) + 1e-6
            px, py = -(y1 - y0) / L, (x1 - x0) / L          # perpendiculaire : vrai zigzag
            sign = rng.choice([-1, 1])
            for k in range(1, seg):
                u = (k + rng.uniform(-0.25, 0.25)) / seg
                j = sign * rng.uniform(0.3, 1.0) * L * 0.09; sign = -sign
                pts.append((x0 + (x1 - x0) * u + px * j, y0 + (y1 - y0) * u + py * j))
            pts.append((x1, y1))
            fine = [pts[0]]                                  # micro-dents : le trait reste nerveux
            for a, b in zip(pts, pts[1:]):
                for q in (1 / 3, 2 / 3):
                    j = rng.normal(0, L * 0.012)
                    fine.append((a[0] + (b[0] - a[0]) * q + px * j, a[1] + (b[1] - a[1]) * q + py * j))
                fine.append(b)
            pts = fine
            for a, b in zip(pts, pts[1:]):
                d.line([a, b], fill=255, width=width)
                d.ellipse([a[0] - width / 2, a[1] - width / 2, a[0] + width / 2, a[1] + width / 2], fill=255)
            if depth < 1:
                main = math.atan2(y1 - y0, x1 - x0)
                for _ in range(int(rng.integers(1, 3))):
                    a = pts[int(rng.integers(2, len(pts) - 1))]
                    ang = main + rng.choice([-1, 1]) * rng.uniform(0.5, 1.0); Lb = n * rng.uniform(0.15, 0.28)
                    bolt(a[0], a[1], a[0] + math.cos(ang) * Lb, a[1] + math.sin(ang) * Lb, max(3, width // 2), depth + 1)
        m = n * 0.1
        a0 = rng.uniform(0, 2 * np.pi)
        x0, y0 = n / 2 + math.cos(a0) * (n / 2 - m), n / 2 + math.sin(a0) * (n / 2 - m)
        a1 = a0 + np.pi + rng.normal(0, 0.5)
        x1, y1 = n / 2 + math.cos(a1) * (n / 2 - m), n / 2 + math.sin(a1) * (n / 2 - m)
        bolt(x0, y0, x1, y1, 6, 0)
        core = np.asarray(img, float) / 255
        halo = np.asarray(img.filter(ImageFilter.MaxFilter(11)).filter(ImageFilter.GaussianBlur(5)), float) / 255
        g = np.clip(np.maximum(core, halo * 0.5), 0, 1)
        out.append(to_img(np.dstack([g, g, g, g])))
    return out

# ---------------------------------------------------------------- vent, tourbillon, débris
def crescent(n=512):
    """Lame de vent : croissant très effilé, arête blanche, corps pâle, traînée fine derrière."""
    X, Y = grid(n)
    cy = 0.9; R = 1.25
    r = np.sqrt(X ** 2 + (Y - cy) ** 2); ang = np.arctan2(Y - cy, X)
    a0, a1 = -np.pi * 0.88, -np.pi * 0.12
    u = np.clip((ang - a0) / (a1 - a0), 0, 1); inarc = (ang > a0) & (ang < a1)
    w = 0.16 * np.sin(np.pi * u) ** 2.2
    body = inarc & (r > R - w) & (r < R)
    edge = inarc & (r > R - w * 0.32) & (r < R)
    trail = inarc & (np.abs(r - (R - 0.24)) < 0.012 * np.sin(np.pi * u) ** 3)
    return to_img(compose([(trail, 0.45), (body, 0.55), (edge, 1.0)], n))

def swirl(n=512, arms=4):
    """Tourbillon (Rasengan, Kaiten) : virgules effilées aux deux bouts, cœur blanc."""
    X, Y = grid(n); ang = np.arctan2(Y, X); r = np.sqrt(X ** 2 + Y ** 2)
    ph = ((ang + r * 2.4) * arms / (2 * np.pi)) % 1
    k = np.clip((r - 0.1) / 0.86, 0, 1)
    w = 0.3 * np.sin(np.pi * k) ** 0.9
    stroke = (ph < w) & (r < 0.97)
    hot = (ph < w * 0.38) & (r < 0.97)
    return to_img(compose([(stroke, 0.55), (hot, 1.0)], n))

def debris_frames(n=256, seed=31):
    """Éclats de roche anguleux : 3 facettes nettes, liseré fin."""
    out = []
    for f in range(4):
        rng = np.random.default_rng(seed + f)
        k = int(rng.integers(5, 7))
        angs = np.sort(rng.uniform(0, 2 * np.pi, k)); rads = rng.uniform(0.5, 0.85, k)
        c = n / 2
        pts = [(c + math.cos(a) * r * c * 0.95, c + math.sin(a) * r * c * 0.95) for a, r in zip(angs, rads)]
        def poly(ps):
            im = Image.new("L", (n, n), 0); ImageDraw.Draw(im).polygon(ps, fill=255); return np.asarray(im) > 0
        m = poly(pts)
        lit = poly([(c - c * 0.1, c - c * 0.15)] + pts[: max(2, k // 2)]) & m
        dark = poly([(c + c * 0.1, c + c * 0.1)] + pts[k // 2 + 1:] + [pts[0]]) & m & ~lit
        out.append(to_img(compose([(outline(m, 2), INK), (m, 0.6), (lit, 0.92), (dark, 0.32)], n)))
    return out

# ---------------------------------------------------------------- détails (avec mesure)
def leaf_frames(n=256):
    """Feuilles de Konoha : forme en amande pointue aux deux bouts, 2 verts, nervure, liseré fin."""
    out = []
    for f in range(4):
        X, Y = grid(n)
        xr, yr = rot(X, Y, f * 0.75 + 0.35)
        m = disc(xr, yr, 0, 0.55, 1.0) & disc(xr, yr, 0, -0.55, 1.0) & (np.abs(xr) < 0.86)
        lit = m & (yr < -0.02)
        rib = m & (np.abs(yr) < 0.018)
        out.append(to_img(compose([(outline(m, 2), (0.07, 0.17, 0.1)), (m, (0.17, 0.43, 0.23)),
                                   (lit, (0.38, 0.7, 0.32)), (rib, (0.11, 0.3, 0.16))], n)))
    return out

def feather_frames(n=256):
    """Plumes de corbeau (Itachi) : noir bleuté, reflet froid, pointe effilée."""
    out = []
    for f in range(4):
        X, Y = grid(n)
        xr, yr = rot(X, Y, f * 0.7 - 0.6)
        w = 0.2 * np.clip(1 - np.abs(xr) / 0.9, 0, 1) ** 0.9
        m = (np.abs(yr) < w) & (np.abs(xr) < 0.9)
        lit = m & (yr < -w * 0.25)
        out.append(to_img(compose([(m, (0.06, 0.06, 0.1)), (lit, (0.3, 0.33, 0.44))], n)))
    return out

def glyph_ring(n=1024, text="飛雷神"):
    """Formule de Minato pour le sol : trois caractères à l'encre sur un cercle tracé au pinceau."""
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    font = None
    for p in ["/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc", "/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc"]:
        try:
            font = ImageFont.truetype(p, int(n * 0.16)); break
        except OSError:
            pass
    c = n / 2
    d.ellipse([c - n * 0.46, c - n * 0.46, c + n * 0.46, c + n * 0.46], outline=(17, 17, 17, 255), width=int(n * 0.012))
    d.ellipse([c - n * 0.18, c - n * 0.18, c + n * 0.18, c + n * 0.18], outline=(17, 17, 17, 255), width=int(n * 0.008))
    for i, ch in enumerate(text):
        a = -math.pi / 2 + i * 2 * math.pi / len(text)
        x = c + math.cos(a) * n * 0.31; y = c + math.sin(a) * n * 0.31
        tile = Image.new("RGBA", (int(n * 0.22), int(n * 0.22)), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile)
        td.text((tile.size[0] / 2, tile.size[1] / 2), ch, font=font, fill=(17, 17, 17, 255), anchor="mm")
        tile = tile.rotate(-math.degrees(a) - 90, resample=Image.BICUBIC)
        img.alpha_composite(tile, (int(x - tile.size[0] / 2), int(y - tile.size[1] / 2)))
    # bord légèrement rongé façon pinceau
    a = np.asarray(img, float) / 255
    nz = fbm((n, n), 6, 2, 9)
    a[..., 3] *= np.clip((nz - 0.12) * 6, 0, 1)
    return to_img(a)

def crack_decal(n=1024, seed=61):
    """Impact au sol : cratère anguleux, fissures épaisses qui s'affinent, bord clair soulevé,
    cuvette plus sombre autour (le sol a cédé). Pensé pour peser lourd sans tout couvrir."""
    rng = np.random.default_rng(seed)
    X, Y = grid(n)
    dark = Image.new("L", (n, n), 0); d = ImageDraw.Draw(dark)
    c = n / 2
    def crack(x, y, ang, length, width, depth):
        seg = int(rng.integers(4, 6))
        for k in range(seg):
            ang += rng.normal(0, 0.2)
            L = length / seg * rng.uniform(0.75, 1.25)
            nx, ny = x + math.cos(ang) * L, y + math.sin(ang) * L
            w = max(3, int(width * (1 - k / seg) ** 0.75))
            d.line([(x, y), (nx, ny)], fill=255, width=w)
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=255)
            if depth < 1 and k in (1, 2) and rng.random() < 0.4:
                crack(nx, ny, ang + rng.choice([-1, 1]) * rng.uniform(0.5, 0.85), length * 0.32, w * 0.55, depth + 1)
            x, y = nx, ny
    for k in range(6):
        crack(c, c, k * 2 * math.pi / 6 + rng.normal(0, 0.28), n * rng.uniform(0.3, 0.44), 46, 0)
    crater = [(c + math.cos(a) * n * r, c + math.sin(a) * n * r) for a, r in
              zip(np.linspace(0, 2 * np.pi, 11, endpoint=False) + rng.uniform(0, 0.4), rng.uniform(0.11, 0.16, 11))]
    d.polygon(crater, fill=255)
    m = np.asarray(dark) > 0
    cim = Image.new("L", (n, n), 0); ImageDraw.Draw(cim).polygon(crater, fill=255)
    cm = np.asarray(cim) > 0
    lit = cm & ~np.roll(np.roll(cm, 22, 0), 22, 1)            # pan éclairé du cratère, en haut à gauche
    rim = outline(m, 9)
    basin = np.sqrt(X ** 2 + Y ** 2) < 0.24 + (fbm((n, n), 60, 2, seed) - 0.5) * 0.08
    img = compose([(basin, (0.42, 0.33, 0.24)), (rim, (0.9, 0.82, 0.68)), (m, (0.28, 0.2, 0.15)),
                   (ndimage.binary_erosion(m, iterations=7), (0.15, 0.1, 0.09)), (lit, (0.55, 0.43, 0.32))], n)
    a = img[..., 3]
    a[basin & ~(m | rim)] *= 0.35                             # cuvette : simple assombrissement
    return to_img(img)

def scorch_decal(n=1024, seed=71):
    """Brûlure : tache irrégulière en 2 tons, quelques braises (feu)."""
    X, Y = grid(n); r = np.sqrt(X ** 2 + Y ** 2)
    nz = fbm((n, n), 90, 4, seed)
    m = r < 0.55 + (nz - 0.5) * 0.7
    inner = r < 0.3 + (nz - 0.5) * 0.5
    rng = np.random.default_rng(seed)
    emb = np.zeros((n, n), bool)
    for _ in range(14):
        cx, cy = rng.uniform(-0.4, 0.4, 2)
        emb |= disc(X, Y, cx, cy, rng.uniform(0.01, 0.025))
    emb &= m
    return to_img(compose([(m, (0.27, 0.2, 0.17)), (inner, (0.16, 0.11, 0.1)), (emb, (1.0, 0.55, 0.15))], n))

RECIPES = {
    "fx_star": lambda: star(),
    "fx_impact_lines": lambda: impact_lines(),
    "fx_spark": lambda: spark(),
    "fx_ring": lambda: ring(),
    "fx_smoke_4x4": lambda: sheet(smoke_frames()),
    "fx_dust_4x4": lambda: sheet(smoke_frames(seed=19, flat=0.5, stretch=1.3, rise=0.04)),
    "fx_fire_burst_4x4": lambda: sheet(fire_burst_frames()),
    "fx_flame_loop_4x4": lambda: sheet(flame_loop_frames()),
    "fx_lightning_4x4": lambda: sheet(lightning_frames(frames=16)),
    "fx_crescent": lambda: crescent(),
    "fx_swirl": lambda: swirl(),
    "fx_debris_2x2": lambda: sheet(debris_frames(), 2),
    "fx_leaf_2x2": lambda: sheet(leaf_frames(), 2),
    "fx_feather_2x2": lambda: sheet(feather_frames(), 2),
    "fx_glyph_hiraishin": lambda: glyph_ring(),
    "fx_crack_decal": lambda: crack_decal(),
    "fx_scorch_decal": lambda: scorch_decal(),
}

if __name__ == "__main__":
    outdir = Path(sys.argv[1]); outdir.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[2:] or list(RECIPES):
        img = RECIPES[name]()
        img.save(outdir / f"{name}.png", optimize=True)
        print(name, img.size)
