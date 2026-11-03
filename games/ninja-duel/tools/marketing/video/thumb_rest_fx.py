from fx import *
from PIL import Image, ImageDraw, ImageFilter
import random, math

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


