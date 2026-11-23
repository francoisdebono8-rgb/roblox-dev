from fx import *
from PIL import Image, ImageDraw, ImageFilter
import random

W, H = 1920, 1080
S = (W, H)
chars = grade(Image.open("cap/R.png").convert("RGBA"), 1.08, 1.22)

bg = vgradient(S, [(0, (20, 70, 170)), (0.55, (70, 160, 240)), (1, (170, 220, 255))])
bg.alpha_composite(radial(S, (960, 520), 1000, (255, 250, 220), power=1.8, alpha=200))
bg.alpha_composite(rays(S, (960, 520), 30, (255, 255, 255), alpha=45, spread=0.5, seed=4))
# soft clouds
random.seed(3)
cl = Image.new("RGBA", S, (0, 0, 0, 0))
d = ImageDraw.Draw(cl)
for _ in range(26):
    x, y = random.uniform(-100, W + 100), random.uniform(380, 760)
    r = random.uniform(60, 170)
    d.ellipse([x - r * 1.8, y - r, x + r * 1.8, y + r], fill=(255, 255, 255, 120))
bg.alpha_composite(cl.filter(ImageFilter.GaussianBlur(24)))
# arena wall silhouette with banners
wall = Image.new("RGBA", S, (0, 0, 0, 0))
wd = ImageDraw.Draw(wall)
wd.rectangle([0, 700, W, H], fill=(236, 226, 206, 255))
wd.rectangle([0, 700, W, 728], fill=(200, 60, 44, 255))
for i in range(9):
    x = 60 + i * 230
    wd.rectangle([x, 560, x + 70, 760], fill=(22, 18, 24, 255))
    wd.ellipse([x + 12, 600, x + 58, 646], fill=(200, 40, 40, 255))
bg.alpha_composite(wall.filter(ImageFilter.GaussianBlur(6)))
floor = vgradient((W, 300), [(0, (196, 160, 110)), (1, (120, 90, 60))])
bg.alpha_composite(floor, (0, 800))
bg.alpha_composite(ink_band(S, 930, 90, -6, VERMILION, 240, seed=5))

scale = 1.16
layer, bb, pos = place(bg, chars, scale, (W / 2, H - 18))
bg.alpha_composite(glow_of(layer, (255, 255, 255), grow=5, blur=14, strength=0.9))
bg.alpha_composite(outline_of(layer, INK, 5))
bg.alpha_composite(layer)
bg.alpha_composite(rim_light(layer, (255, 230, 170), (-1, -1), 8, 0.7))

bg.alpha_composite(text_layer(S, (W / 2, 118), "CHOOSE YOUR NINJA", font(LUCKY, 150), PAPER, stroke=15, stroke_fill=INK,
                              gradient=((255, 255, 255), (140, 220, 255)), shadow=(0, 12, INK, 0)))
bg.alpha_composite(badge(S, (1690, 960), "NINJA DUEL", font(LUCKY, 56), VERMILION, PAPER, angle=-6))
bg.alpha_composite(vignette(S, 0.35))
bg.convert("RGB").save("out/thumb2_roster.png")
print("ok")
