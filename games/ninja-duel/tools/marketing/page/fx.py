"""Compositing helpers for Ninja Duel page art (thumbnails, icon, video cards)."""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

FONTS = "/home/claude/media/fonts/"
BANGERS = FONTS + "Bangers-Regular.ttf"
LUCKY = FONTS + "LuckiestGuy-Regular.ttf"
CJK = "/usr/share/fonts/opentype/noto/NotoSerifCJK-Black.ttc"
INK = (14, 10, 18)
PAPER = (247, 240, 225)
VERMILION = (226, 58, 38)
GOLD = (255, 196, 54)


def font(path, size, index=0):
    return ImageFont.truetype(path, size, index=index)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vgradient(size, stops):
    """stops: list of (t, rgb)."""
    W, H = size
    y = np.linspace(0, 1, H)[:, None]
    out = np.zeros((H, 1, 3), np.float32)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        m = (y >= t0) & (y <= t1)
        k = np.clip((y - t0) / max(t1 - t0, 1e-6), 0, 1)
        col = np.array(c0)[None, None, :] * (1 - k[..., None]) + np.array(c1)[None, None, :] * k[..., None]
        out = np.where(m[..., None], col, out)
    return Image.fromarray(np.repeat(out, W, 1).astype(np.uint8), "RGB").convert("RGBA")


def radial(size, center, radius, color, power=1.6, alpha=255):
    W, H = size
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** power * alpha
    img = np.zeros((H, W, 4), np.uint8)
    img[..., :3] = color
    img[..., 3] = a.astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def rays(size, center, n, color, alpha=90, spread=0.5, seed=1, length=3000):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(n):
        a = (i / n) * 2 * math.pi + random.uniform(-0.1, 0.1)
        w = random.uniform(0.3, 1.0) * spread / n * 2 * math.pi
        p1 = (center[0] + math.cos(a - w) * length, center[1] + math.sin(a - w) * length)
        p2 = (center[0] + math.cos(a + w) * length, center[1] + math.sin(a + w) * length)
        d.polygon([center, p1, p2], fill=color + (int(alpha * random.uniform(0.4, 1)),))
    return layer


def speed_lines(size, center, n, color, inner, seed=3, width=(2, 7), alpha=(90, 200)):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(n):
        a = random.uniform(0, 2 * math.pi)
        r0 = inner * random.uniform(1, 1.6)
        r1 = r0 + random.uniform(300, 1400)
        p0 = (center[0] + math.cos(a) * r0, center[1] + math.sin(a) * r0)
        p1 = (center[0] + math.cos(a) * r1, center[1] + math.sin(a) * r1)
        d.line([p0, p1], fill=color + (random.randint(*alpha),), width=random.randint(*width))
    return layer


def glow_of(rgba, color, grow=8, blur=18, strength=1.0):
    a = rgba.getchannel("A")
    a = a.filter(ImageFilter.MaxFilter(grow * 2 + 1)) if grow > 0 else a
    a = a.filter(ImageFilter.GaussianBlur(blur))
    a = a.point(lambda v: min(255, int(v * strength)))
    g = Image.new("RGBA", rgba.size, color + (0,))
    g.putalpha(a)
    return g


def outline_of(rgba, color, width=6):
    a = rgba.getchannel("A").point(lambda v: 255 if v > 100 else 0)
    a = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    o = Image.new("RGBA", rgba.size, color + (0,))
    o.putalpha(a)
    return o


def rim_light(rgba, color, direction=(1, 0), width=10, strength=0.85):
    """Coloured edge light on the side of `direction` (screen space)."""
    a = np.asarray(rgba.getchannel("A")).astype(np.float32) / 255
    dx, dy = direction
    sh = np.roll(np.roll(a, -int(dy * width), 0), -int(dx * width), 1)
    edge = np.clip(a - sh, 0, 1)
    edge = Image.fromarray((edge * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(width / 3))
    edge = edge.point(lambda v: min(255, int(v * strength * 1.6)))
    layer = Image.new("RGBA", rgba.size, color + (0,))
    layer.putalpha(ImageChops.multiply(edge, rgba.getchannel("A")))
    return layer


def grade(rgba, contrast=1.12, sat=1.18, lift=0):
    from PIL import ImageEnhance
    rgb = rgba.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(sat)
    out = rgb.convert("RGBA")
    out.putalpha(rgba.getchannel("A"))
    return out


def text_layer(size, xy, text, fnt, fill, stroke=0, stroke_fill=INK, anchor="mm", gradient=None, shadow=None, angle=0, spacing=0):
    """Big display text. gradient=(top_rgb,bottom_rgb). shadow=(dx,dy,rgb,blur)."""
    W, H = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    md.text(xy, text, font=fnt, fill=255, anchor=anchor, stroke_width=0)
    smask = Image.new("L", size, 0)
    ImageDraw.Draw(smask).text(xy, text, font=fnt, fill=255, anchor=anchor, stroke_width=stroke)
    if shadow:
        dx, dy, col, bl = shadow
        sh = Image.new("RGBA", size, col + (0,))
        sh.putalpha(ImageChops.offset(smask, dx, dy).filter(ImageFilter.GaussianBlur(bl)) if bl else ImageChops.offset(smask, dx, dy))
        layer.alpha_composite(sh)
    if stroke:
        st = Image.new("RGBA", size, stroke_fill + (0,))
        st.putalpha(smask)
        layer.alpha_composite(st)
    if gradient:
        bb = mask.getbbox() or (0, 0, W, H)
        g = vgradient((W, bb[3] - bb[1] + 2), [(0, gradient[0]), (1, gradient[1])])
        full = Image.new("RGBA", size, (0, 0, 0, 0))
        full.paste(g, (0, bb[1]))
        full.putalpha(mask)
        layer.alpha_composite(full)
    else:
        f = Image.new("RGBA", size, fill + (0,))
        f.putalpha(mask)
        layer.alpha_composite(f)
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC, center=xy)
    return layer


def lightning(size, p0, p1, color=(150, 200, 255), width=5, seed=7, branches=4, jag=28):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def bolt(a, b, w, depth):
        pts = [a]
        n = 9
        for i in range(1, n):
            t = i / n
            x = a[0] + (b[0] - a[0]) * t + random.uniform(-jag, jag)
            y = a[1] + (b[1] - a[1]) * t + random.uniform(-jag, jag)
            pts.append((x, y))
        pts.append(b)
        d.line(pts, fill=color + (255,), width=w, joint="curve")
        d.line(pts, fill=(255, 255, 255, 255), width=max(1, w // 3), joint="curve")
        if depth > 0:
            for _ in range(1):
                k = random.randint(2, n - 2)
                s = pts[k]
                ang = math.atan2(b[1] - a[1], b[0] - a[0]) + random.uniform(-1.2, 1.2)
                ln = math.dist(a, b) * random.uniform(0.25, 0.5)
                bolt(s, (s[0] + math.cos(ang) * ln, s[1] + math.sin(ang) * ln), max(1, w - 2), depth - 1)

    for i in range(branches):
        bolt(p0, (p1[0] + random.uniform(-40, 40), p1[1] + random.uniform(-40, 40)), width, 1)
    glow = layer.filter(ImageFilter.GaussianBlur(10))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(glow)
    out.alpha_composite(layer)
    return out


def orb(size, c, r, core=(255, 255, 255), mid=(120, 200, 255), outer=(30, 110, 255), swirl=True, seed=5):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.alpha_composite(radial(size, c, r * 2.6, outer, power=2.2, alpha=200))
    layer.alpha_composite(radial(size, c, r * 1.25, mid, power=1.1, alpha=255))
    if swirl:
        d = ImageDraw.Draw(layer)
        for i in range(16):
            a0 = random.uniform(0, 360)
            rr = r * random.uniform(0.35, 1.2)
            sq = random.uniform(0.55, 1.0)
            tilt = Image.new("RGBA", size, (0, 0, 0, 0))
            ImageDraw.Draw(tilt).arc([c[0] - rr, c[1] - rr * sq, c[0] + rr, c[1] + rr * sq], a0, a0 + random.uniform(60, 150), fill=(225, 242, 255, random.randint(150, 240)), width=random.randint(3, 8))
            layer.alpha_composite(tilt.rotate(random.uniform(-40, 40), center=c, resample=Image.BICUBIC))
    layer.alpha_composite(radial(size, c, r * 0.7, core, power=0.8, alpha=255))
    return layer


def sparks(size, c, n, color, seed=9, rmin=40, rmax=420, length=(20, 70), width=(2, 5)):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(n):
        a = random.uniform(0, 2 * math.pi)
        r0 = random.uniform(rmin, rmax)
        ln = random.uniform(*length)
        p0 = (c[0] + math.cos(a) * r0, c[1] + math.sin(a) * r0)
        p1 = (c[0] + math.cos(a) * (r0 + ln), c[1] + math.sin(a) * (r0 + ln))
        d.line([p0, p1], fill=color + (random.randint(150, 255),), width=random.randint(*width))
    g = layer.filter(ImageFilter.GaussianBlur(4))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(g)
    out.alpha_composite(layer)
    return out


def place(canvas, rgba, scale, anchor_xy, ref="bottom"):
    """Scale a cut-out and paste it so its alpha bbox bottom-centre (or centre) lands on anchor_xy."""
    bb = rgba.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    cut = rgba.crop(bb)
    cut = cut.resize((int(cut.width * scale), int(cut.height * scale)), Image.LANCZOS)
    if ref == "bottom":
        pos = (int(anchor_xy[0] - cut.width / 2), int(anchor_xy[1] - cut.height))
    else:
        pos = (int(anchor_xy[0] - cut.width / 2), int(anchor_xy[1] - cut.height / 2))
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(cut, pos)
    return layer, bb, pos


def map_point(p, bb, scale, pos):
    return (pos[0] + (p[0] - bb[0]) * scale, pos[1] + (p[1] - bb[1]) * scale)


def ink_band(size, y, height, angle, color=VERMILION, alpha=255, rough=True, seed=2):
    W, H = size
    band = Image.new("RGBA", (W * 2, height * 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(band)
    random.seed(seed)
    top = height
    pts_top = [(x, top + random.uniform(-height * 0.08, height * 0.08)) for x in range(0, W * 2 + 40, 40)]
    pts_bot = [(x, top + height + random.uniform(-height * 0.1, height * 0.1)) for x in range(W * 2, -40, -40)]
    d.polygon(pts_top + pts_bot, fill=color + (alpha,))
    band = band.rotate(angle, resample=Image.BICUBIC, expand=False)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.paste(band, (-W // 2, int(y - height * 1.5)), band)
    return layer


def vignette(size, strength=0.55, color=(0, 0, 0)):
    W, H = size
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2) / math.sqrt(2)
    a = np.clip((d - 0.45) / 0.55, 0, 1) ** 1.5 * 255 * strength
    img = np.zeros((H, W, 4), np.uint8)
    img[..., :3] = color
    img[..., 3] = a.astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def badge(size, xy, text, fnt, fill=VERMILION, fg=PAPER, pad=(28, 14), angle=-6):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    bb = d.textbbox((0, 0), text, font=fnt, anchor="lt")
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    x, y = xy
    rect = [x - w / 2 - pad[0], y - h / 2 - pad[1], x + w / 2 + pad[0], y + h / 2 + pad[1]]
    d.rounded_rectangle([rect[0] - 6, rect[1] - 6, rect[2] + 6, rect[3] + 6], radius=14, fill=INK + (255,))
    d.rounded_rectangle(rect, radius=10, fill=fill + (255,))
    d.text((x, y), text, font=fnt, fill=fg + (255,), anchor="mm")
    return layer.rotate(angle, resample=Image.BICUBIC, center=xy)


def chidori(size, c, r, seed=21, n=14, color=(120, 180, 255)):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.alpha_composite(radial(size, c, r * 2.4, (60, 120, 255), power=2.0, alpha=210))
    layer.alpha_composite(radial(size, c, r * 1.1, (170, 215, 255), power=1.2, alpha=255))
    for i in range(n):
        a = random.uniform(-0.6, math.pi + 0.6)
        ln = r * random.uniform(1.0, 2.4)
        p1 = (c[0] + math.cos(a) * ln, c[1] + math.sin(a) * ln)
        layer.alpha_composite(lightning(size, c, p1, color, random.randint(3, 6), seed=seed + i, branches=1, jag=r * 0.18))
    layer.alpha_composite(radial(size, c, r * 0.6, (255, 255, 255), power=0.8, alpha=255))
    return layer
