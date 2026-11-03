from fx import *
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import random, math

W, H = 1920, 1080
S = (W, H)


def sand_burst(size, c, r, seed=31):
    random.seed(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(900):
        a = random.uniform(-math.pi * 0.95, math.pi * 0.95)
        rr = r * (0.55 + random.random() ** 0.6 * 0.6)
        x = c[0] + math.cos(a) * rr * 0.55 + random.gauss(0, 10)
        y = c[1] + math.sin(a) * rr + random.gauss(0, 10)
        s = random.uniform(2, 7)
        col = random.choice([(214, 170, 96), (236, 196, 120), (180, 136, 70), (250, 220, 150)])
        d.ellipse([x - s, y - s, x + s, y + s], fill=col + (random.randint(150, 255),))
    wall = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(wall).ellipse([c[0] - r * 0.5, c[1] - r, c[0] + r * 0.5, c[1] + r], fill=(214, 172, 100, 150))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(wall.filter(ImageFilter.GaussianBlur(30)))
    out.alpha_composite(layer.filter(ImageFilter.GaussianBlur(1)))
    return out


def impact_star(size, c, r, color=(255, 255, 255), n=14, seed=2):
    random.seed(seed)
    pts = []
    for i in range(n * 2):
        a = i / (n * 2) * 2 * math.pi
        rr = r * (1 if i % 2 == 0 else random.uniform(0.35, 0.5)) * (random.uniform(0.75, 1.15) if i % 2 == 0 else 1)
        pts.append((c[0] + math.cos(a) * rr, c[1] + math.sin(a) * rr))
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.polygon(pts, fill=INK + (255,))
    inner = [(c[0] + (p[0] - c[0]) * 0.86, c[1] + (p[1] - c[1]) * 0.86) for p in pts]
    d.polygon(inner, fill=color + (255,))
    return layer


# ---------- Thumb 3: Lee vs Gaara ----------
chars = grade(Image.open("cap/L.png").convert("RGBA"), 1.08, 1.2)
bg = vgradient(S, [(0, (255, 170, 60)), (0.5, (250, 210, 120)), (1, (200, 140, 70))])
bg.alpha_composite(rays(S, (960, 430), 34, (255, 250, 220), alpha=70, spread=0.5, seed=8))
dunes = Image.new("RGBA", S, (0, 0, 0, 0))
dd = ImageDraw.Draw(dunes)
dd.polygon([(0, 780), (400, 700), (900, 760), (1400, 690), (1920, 760), (1920, 1080), (0, 1080)], fill=(196, 140, 74, 255))
dd.polygon([(0, 880), (600, 820), (1200, 880), (1920, 820), (1920, 1080), (0, 1080)], fill=(160, 104, 52, 255))
bg.alpha_composite(dunes.filter(ImageFilter.GaussianBlur(5)))
bg.alpha_composite(speed_lines(S, (960, 430), 140, (255, 255, 255), inner=360, alpha=(50, 150), seed=12))
scale = 1.36
layer, bb, pos = place(bg, chars, scale, (W / 2 - 10, H + 10))
hit = map_point((975, 360), bb, scale, pos)
bg.alpha_composite(sand_burst(S, (hit[0] + 70, hit[1] + 40), 330))
bg.alpha_composite(glow_of(layer, (255, 255, 255), grow=5, blur=14, strength=1.0))
bg.alpha_composite(outline_of(layer, INK, 5))
bg.alpha_composite(layer)
bg.alpha_composite(impact_star(S, (hit[0] + 8, hit[1] - 4), 120, (255, 244, 170)))
bg.alpha_composite(radial(S, hit, 160, (255, 255, 255), power=1.2, alpha=230))
bg.alpha_composite(sparks(S, hit, 40, (255, 255, 255), rmin=80, rmax=260, seed=5))
bg.alpha_composite(text_layer(S, (W / 2, 120), "1v1 NINJA DUELS", font(LUCKY, 150), PAPER, stroke=15, stroke_fill=INK,
                              gradient=((255, 255, 255), (255, 214, 90)), shadow=(0, 12, INK, 0)))
bg.alpha_composite(badge(S, (W / 2, 990), "VS AI  •  FRIENDS  •  ONLINE", font(LUCKY, 54), INK, PAPER, angle=-2))
bg.alpha_composite(vignette(S, 0.4))
bg.convert("RGB").save("out/thumb3_duels.png")

# ---------- Thumb 4: Itachi ----------
it = grade(Image.open("cap/I.png").convert("RGBA"), 1.12, 1.1)
bg = vgradient(S, [(0, (10, 4, 8)), (0.6, (70, 6, 14)), (1, (20, 2, 6))])
moon_c = (1180, 430)
bg.alpha_composite(radial(S, moon_c, 640, (200, 20, 30), power=2.0, alpha=200))
moon = Image.new("RGBA", S, (0, 0, 0, 0))
ImageDraw.Draw(moon).ellipse([moon_c[0] - 330, moon_c[1] - 330, moon_c[0] + 330, moon_c[1] + 330], fill=(214, 30, 36, 255))
bg.alpha_composite(moon)
bg.alpha_composite(radial(S, (moon_c[0] - 90, moon_c[1] - 110), 330, (255, 90, 70), power=1.6, alpha=120))
# crows
random.seed(4)
cr = Image.new("RGBA", S, (0, 0, 0, 0))
cd = ImageDraw.Draw(cr)
for _ in range(16):
    x, y = random.uniform(150, 1800), random.uniform(120, 700)
    s = random.uniform(18, 46)
    cd.polygon([(x - s * 1.6, y - s * 0.3), (x - s * 0.4, y), (x, y + s * 0.25), (x + s * 0.4, y), (x + s * 1.6, y - s * 0.3), (x + s * 0.3, y + s * 0.35), (x, y + s * 0.6), (x - s * 0.3, y + s * 0.35)], fill=(8, 2, 6, 255))
bg.alpha_composite(cr)
# black flames at the bottom
random.seed(9)
fl = Image.new("RGBA", S, (0, 0, 0, 0))
fd = ImageDraw.Draw(fl)
for _ in range(60):
    x = random.uniform(-50, W + 50)
    h = random.uniform(120, 360)
    w = random.uniform(40, 110)
    fd.polygon([(x - w, H), (x + random.uniform(-30, 30), H - h), (x + w, H)], fill=(4, 0, 4, 255))
bg.alpha_composite(fl.filter(ImageFilter.GaussianBlur(3)))
scale = 1.08
layer, bb, pos = place(bg, it, scale, (760, H + 40))
bg.alpha_composite(glow_of(layer, (255, 30, 40), grow=6, blur=26, strength=1.5))
bg.alpha_composite(outline_of(layer, INK, 5))
bg.alpha_composite(layer)
bg.alpha_composite(rim_light(layer, (255, 60, 60), (1, 0), 10, 1.0))
eye = map_point((980, 240), bb, scale, pos)
bg.alpha_composite(radial(S, eye, 46, (255, 40, 40), power=1.6, alpha=170))
bg.alpha_composite(radial(S, eye, 12, (255, 230, 230), power=0.9, alpha=230))
bg.alpha_composite(text_layer(S, (1420, 760), "UNLEASH", font(LUCKY, 150), PAPER, stroke=14, stroke_fill=INK,
                              gradient=((255, 255, 255), (255, 120, 110)), shadow=(0, 12, INK, 0), angle=4))
bg.alpha_composite(text_layer(S, (1420, 900), "YOUR ULTIMATE", font(LUCKY, 104), PAPER, stroke=12, stroke_fill=INK,
                              gradient=((255, 220, 120), (255, 120, 40)), shadow=(0, 10, INK, 0), angle=4))
bg.alpha_composite(badge(S, (230, 90), "NINJA DUEL", font(LUCKY, 50), VERMILION, PAPER, angle=-4))
bg.alpha_composite(vignette(S, 0.5))
bg.convert("RGB").save("out/thumb4_ultimate.png")

# ---------- Icon 512 (drawn at 1024) ----------
IS = 1024
SI = (IS, IS)
nar = grade(Image.open("cap/N.png").convert("RGBA"), 1.1, 1.22)
bg = vgradient(SI, [(0, (255, 120, 30)), (1, (200, 40, 30))])
bg.alpha_composite(rays(SI, (IS / 2, IS * 0.45), 26, (255, 230, 150), alpha=90, spread=0.5, seed=3))
bg.alpha_composite(radial(SI, (IS / 2, IS * 0.42), 600, (255, 240, 170), power=1.8, alpha=200))
k = text_layer(SI, (IS * 0.78, IS * 0.3), "忍", font(CJK, 520), (0, 0, 0))
k.putalpha(k.getchannel("A").point(lambda v: v * 0.16))
bg.alpha_composite(k)
bg.alpha_composite(ink_band(SI, IS * 0.86, 110, -9, INK, 255, seed=6))
scale = 1.12
layer, bb, pos = place(bg, nar, scale, (IS * 0.52, IS * 1.12))
bg.alpha_composite(glow_of(layer, (255, 255, 255), grow=8, blur=16, strength=1.2))
bg.alpha_composite(outline_of(layer, INK, 9))
bg.alpha_composite(layer)
bg.alpha_composite(rim_light(layer, (120, 180, 255), (1, 0), 12, 0.8))
fist = map_point((745, 460), bb, scale, pos)
bg.alpha_composite(orb(SI, fist, 92))
bg.alpha_composite(text_layer(SI, (IS / 2, IS * 0.9), "NINJA DUEL", font(LUCKY, 132), PAPER, stroke=14, stroke_fill=INK,
                              gradient=((255, 246, 170), (255, 150, 40)), shadow=(0, 10, INK, 0), angle=-4))
ic = bg.convert("RGB")
ic.save("out/icon_1024.png")
ic.resize((512, 512), Image.LANCZOS).save("out/icon_512.png")
print("ok")
