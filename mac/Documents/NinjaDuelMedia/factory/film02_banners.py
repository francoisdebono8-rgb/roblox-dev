"""Film 02 (Lee vs Itachi): move banners with PS5 buttons + hook/end, 1080x1920 transparent PNGs."""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ov
from ov import F, LUCKY, LILITA, INK, text_layer, canvas, center, fit, stamp, pill, GOLD, WHITE, RED

BTN = {"□": (236, 92, 168), "○": (232, 64, 64), "✕": (90, 150, 255), "△": (60, 200, 140)}
def button(sym, d=78):
    im = Image.new("RGBA", (d, d), (0, 0, 0, 0)); g = ImageDraw.Draw(im)
    g.ellipse((2, 2, d - 2, d - 2), fill=(24, 22, 30, 255), outline=(255, 255, 255, 230), width=4)
    c = BTN[sym]; m = d * 0.30; w = 7
    if sym == "□": g.rectangle((m, m, d - m, d - m), outline=c, width=w)
    elif sym == "○": g.ellipse((m - 2, m - 2, d - m + 2, d - m + 2), outline=c, width=w)
    elif sym == "✕": g.line((m, m, d - m, d - m), fill=c, width=w + 1); g.line((m, d - m, d - m, m), fill=c, width=w + 1)
    elif sym == "△": g.polygon([(d / 2, m - 3), (d - m + 3, d - m + 1), (m - 3, d - m + 1)], outline=c, width=w)
    return im
def r1(h=78):
    im = Image.new("RGBA", (112, h), (0, 0, 0, 0)); g = ImageDraw.Draw(im)
    g.rounded_rectangle((2, 10, 110, h - 10), 18, fill=(24, 22, 30, 255), outline=(255, 255, 255, 230), width=4)
    g.text((56, h / 2), "R1", font=F(LILITA, 40), fill=(255, 255, 255), anchor="mm"); return im
def plus():
    im = Image.new("RGBA", (40, 78), (0, 0, 0, 0)); ImageDraw.Draw(im).text((20, 39), "+", font=F(LILITA, 52), fill=(255, 255, 255), anchor="mm"); return im

def banner(who, color, keys, move, out, y=1470):
    c = canvas()
    w, h = 960, 260; x0 = (1080 - w) // 2; y0 = y - h // 2
    plate = Image.new("RGBA", (w, h), (0, 0, 0, 0)); g = ImageDraw.Draw(plate)
    g.rounded_rectangle((0, 0, w - 1, h - 1), 34, fill=(12, 10, 18, 215), outline=color + (255,), width=6)
    g.rounded_rectangle((0, 0, 26, h - 1), 13, fill=color + (255,))
    c.alpha_composite(plate, (x0, y0))
    # top row: name tag + buttons
    nm = F(LILITA, 50); tw = int(nm.getlength(who)) + 44
    tag = Image.new("RGBA", (tw, 64), (0, 0, 0, 0)); ImageDraw.Draw(tag).rounded_rectangle((0, 0, tw - 1, 63), 16, fill=color + (255,))
    ImageDraw.Draw(tag).text((tw / 2, 32), who, font=nm, fill=(255, 255, 255), anchor="mm", stroke_width=3, stroke_fill=INK)
    parts = []
    for k in keys:
        parts.append(r1() if k == "R1" else plus() if k == "+" else button(k))
    row_w = tw + 24 + sum(p.width + 10 for p in parts)
    x = x0 + (w - row_w) // 2; ty = y0 + 26
    c.alpha_composite(tag, (x, ty + 7)); x += tw + 24
    for p in parts: c.alpha_composite(p, (x, ty)); x += p.width + 10
    # move name
    center(c, fit(stamp(move, 92, grad=GOLD, stroke=12), 900), 540, y0 + 190)
    c.save(out); return out

def hook(lines, pilltext, out, y=300, grad=GOLD):
    c = canvas()
    for i, line in enumerate(lines):
        center(c, fit(stamp(line, 150 if i == 0 else 120, grad=grad, stroke=16), 1000), 540, y + i * 150)
    if pilltext: center(c, pill(pilltext, (255, 140, 40), 50), 540, y + len(lines) * 150 + 10)
    c.save(out); return out

if __name__ == "__main__":
    O = sys.argv[1]; os.makedirs(O, exist_ok=True)
    LEE, ITA = (50, 180, 70), (190, 30, 45)
    banner("ROCK LEE", LEE, ["R1", "+", "○"], "REMOVE THE WEIGHTS", os.path.join(O, "b1_weights.png"))
    banner("ITACHI", ITA, ["R1", "+", "□"], "SHADOW SHURIKEN", os.path.join(O, "b2_shuriken.png"))
    banner("ROCK LEE", LEE, ["□", "□", "✕"], "LEAF RISING", os.path.join(O, "b3_leafrising.png"))
    banner("ITACHI", ITA, ["R1", "+", "○"], "MIRAGE", os.path.join(O, "b4_mirage.png"))
    hook(["SPEED", "ISN'T ENOUGH"], "ROCK LEE vs ITACHI", os.path.join(O, "h_hook.png"))
    hook(["SPEED", "ISN'T ENOUGH"], None, os.path.join(O, "h_end.png"), y=330, grad=RED)
    print("ok")
