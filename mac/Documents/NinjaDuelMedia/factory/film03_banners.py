"""Film 03 (Naruto vs Minato, WHO WINS?): move banners (PS5) + hook/twist/end, 1080x1920 transparent PNGs."""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import film02_banners as fb
from ov import F, LILITA, INK, canvas, center, fit, stamp, pill, GOLD, RED
def dpad(d, sz=78):
    im = Image.new("RGBA", (sz, sz), (0, 0, 0, 0)); g = ImageDraw.Draw(im)
    g.rounded_rectangle((2, 2, sz - 2, sz - 2), 16, fill=(24, 22, 30, 255), outline=(255, 255, 255, 230), width=4)
    c = sz / 2; a = sz * 0.26
    pts = {"down": [(c - a, c - a * 0.5), (c + a, c - a * 0.5), (c, c + a * 0.8)], "right": [(c - a * 0.5, c - a), (c - a * 0.5, c + a), (c + a * 0.8, c)]}[d]
    g.polygon(pts, fill=(255, 255, 255)); return im
def sign(n, sz=78):
    im = Image.new("RGBA", (sz, sz), (0, 0, 0, 0)); g = ImageDraw.Draw(im)
    g.ellipse((2, 2, sz - 2, sz - 2), fill=(250, 214, 80, 255), outline=(255, 255, 255, 230), width=4)
    g.text((sz / 2, sz / 2 + 2), str(n), font=F(LILITA, 46), fill=INK, anchor="mm"); return im
_orig = fb.button
def part(k):
    if k == "R1": return fb.r1()
    if k == "+": return fb.plus()
    if k in ("down", "right"): return dpad(k)
    if k in ("1", "2", "3", "4"): return sign(k)
    if k == "SEALS":
        im = Image.new("RGBA", (150, 78), (0, 0, 0, 0)); g = ImageDraw.Draw(im)
        g.rounded_rectangle((2, 10, 148, 68), 18, fill=(24, 22, 30, 255), outline=(255, 255, 255, 230), width=4)
        g.text((75, 39), "SEALS", font=F(LILITA, 36), fill=(255, 255, 255), anchor="mm"); return im
    return _orig(k)
def banner(who, color, keys, move, out, y=1470):
    c = canvas(); w, h = 960, 260; x0 = (1080 - w) // 2; y0 = y - h // 2
    plate = Image.new("RGBA", (w, h), (0, 0, 0, 0)); g = ImageDraw.Draw(plate)
    g.rounded_rectangle((0, 0, w - 1, h - 1), 34, fill=(12, 10, 18, 215), outline=color + (255,), width=6)
    g.rounded_rectangle((0, 0, 26, h - 1), 13, fill=color + (255,)); c.alpha_composite(plate, (x0, y0))
    nm = F(LILITA, 50); tw = int(nm.getlength(who)) + 44
    tag = Image.new("RGBA", (tw, 64), (0, 0, 0, 0)); tg = ImageDraw.Draw(tag); tg.rounded_rectangle((0, 0, tw - 1, 63), 16, fill=color + (255,))
    tg.text((tw / 2, 32), who, font=nm, fill=(255, 255, 255), anchor="mm", stroke_width=3, stroke_fill=INK)
    parts = [part(k) for k in keys]
    row_w = tw + 24 + sum(p.width + 10 for p in parts); x = x0 + (w - row_w) // 2; ty = y0 + 26
    c.alpha_composite(tag, (x, ty + 7)); x += tw + 24
    for p in parts: c.alpha_composite(p, (x, ty)); x += p.width + 10
    center(c, fit(stamp(move, 92, grad=GOLD, stroke=12), 900), 540, y0 + 190); c.save(out)
def big(lines, out, y=900, grad=GOLD, pilltext=None, sizes=(170, 130)):
    c = canvas()
    for i, line in enumerate(lines): center(c, fit(stamp(line, sizes[min(i, 1)], grad=grad, stroke=16), 1000), 540, y + i * 150)
    if pilltext: center(c, pill(pilltext, (255, 140, 40), 50), 540, y + len(lines) * 150 + 10)
    c.save(out)
if __name__ == "__main__":
    O = sys.argv[1]; os.makedirs(O, exist_ok=True)
    NAR, MIN = (245, 130, 30), (70, 150, 235)
    big(["WHO WINS?"], os.path.join(O, "n0_hook.png"), y=300, pilltext="NARUTO vs MINATO · FATHER vs SON", sizes=(190, 130))
    banner("MINATO", MIN, ["R1", "+", "□"], "MARKED KUNAI", os.path.join(O, "n1_kunai.png"))
    banner("MINATO", MIN, ["R1", "+", "△"], "LIGHTNING STRIKE", os.path.join(O, "n2_lightning.png"))
    big(["IT WAS", "A CLONE!"], os.path.join(O, "n3_clone.png"), y=380)
    banner("NARUTO", NAR, ["R1", "+", "△"], "RASENGAN", os.path.join(O, "n4_rasengan.png"))
    banner("NARUTO", NAR, ["down"], "NINE-TAILS CHAKRA", os.path.join(O, "n5_ninetails.png"))
    banner("MINATO", MIN, ["SEALS", "2", "3"], "SEALING TRAP", os.path.join(O, "n6_trap.png"))
    big(["DIDN'T SEE", "THAT COMING?"], os.path.join(O, "n7_end.png"), y=330, grad=RED, sizes=(150, 150))
    print("ok")
