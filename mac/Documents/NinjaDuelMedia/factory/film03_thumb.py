"""Thumbnail 1080x1920 Naruto vs Minato WHO WINS? (top: Kyubi Naruto, bottom: Minato)."""
import os, sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ov import stamp, pill, center, fit, GOLD, RED, W, H

D = os.path.expanduser("~/mnt/Documents/NinjaDuelMedia/FILM03_NARUTO_MINATO/thumb")
if not os.path.isdir(D):
    D = os.path.expanduser("~/Documents/NinjaDuelMedia/FILM03_NARUTO_MINATO/thumb")

def half(src, cx, cy, fy, s=1.35, out=(1080, 1010)):
    """crop raw frame so that face (cx,cy) lands at (540, fy) in the output, scale s."""
    w, h = out[0] / s, out[1] / s; x0, y0 = cx - w / 2, cy - fy / s
    im = Image.open(os.path.join(D, src)).convert("RGB").crop((int(x0), int(y0), int(x0 + w), int(y0 + h)))
    im = im.resize(out, Image.LANCZOS).filter(ImageFilter.UnsharpMask(2.2, 90, 2))
    im = ImageEnhance.Contrast(im).enhance(1.08); im = ImageEnhance.Color(im).enhance(1.12)
    return im.convert("RGBA")

def vignette(size, col, strength=170, inner=0.55):
    w, h = size; m = Image.new("L", size, 0); dr = ImageDraw.Draw(m)
    for i in range(40):
        t = i / 39; a = int(strength * (1 - t) ** 2)
        pad = int(min(w, h) * inner * t * 0.5)
        dr.rectangle([pad, pad, w - pad, h - pad], outline=a, width=max(1, int(min(w, h) * inner * 0.5 / 39) + 1))
    m = m.filter(ImageFilter.GaussianBlur(40))
    lay = Image.new("RGBA", size, col + (0,)); lay.putalpha(m); return lay

def build(out):
    c = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    top = half("full_naruto.png", 1020, 592, 430)
    top.alpha_composite(vignette(top.size, (190, 20, 0), 150))
    bot = half("full_minato.png", 1060, 680, 560)
    bot.alpha_composite(vignette(bot.size, (10, 20, 60), 150))
    # zigzag seam (yellow flash)
    pts = [(-20, 900), (300, 930), (420, 885), (640, 1000), (760, 955), (1100, 1010)]
    mtop = Image.new("L", (W, H), 0); ImageDraw.Draw(mtop).polygon([(-20, -20), (1100, -20)] + pts[::-1], fill=255)
    c.paste(bot, (0, H - bot.height))
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0)); layer.paste(top, (0, 0)); layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", (W, H), 0), mtop))
    c.alpha_composite(layer)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0)); g = ImageDraw.Draw(glow)
    g.line(pts, fill=(255, 220, 60, 255), width=46, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(18)); c.alpha_composite(glow)
    s = ImageDraw.Draw(c)
    s.line(pts, fill=(14, 10, 18, 255), width=22, joint="curve")
    s.line(pts, fill=(255, 250, 215, 255), width=10, joint="curve")
    # title across the seam
    t1 = stamp("WHO", 250, grad=GOLD, stroke=18); t2 = stamp("WINS?", 250, grad=GOLD, stroke=18)
    t1 = t1.rotate(4, expand=True, resample=Image.BICUBIC); t2 = t2.rotate(4, expand=True, resample=Image.BICUBIC)
    center(c, fit(t1, 760), 540, 840); center(c, fit(t2, 980), 540, 1060)
    # name tags
    pn = pill("NARUTO · NINE-TAILS", (255, 130, 20), 56); c.alpha_composite(pn, (40, 70))
    pm = pill("MINATO · YELLOW FLASH", (250, 215, 60), 56); c.alpha_composite(pm, (W - pm.width - 40, 1770))
    fs = stamp("FATHER vs SON", 110, grad=RED, stroke=12).rotate(4, expand=True, resample=Image.BICUBIC)
    center(c, fit(fs, 700), 540, 1235)
    c.convert("RGB").save(out, quality=93)
    return out

if __name__ == "__main__":
    print(build(os.path.join(D, "Minia_NarutoMinato_WhoWins.jpg")))
