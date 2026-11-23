"""Overlay templates for the Ninja Duel content factory (1080x1920 transparent PNGs).

Every overlay is described by a small JSON spec, so recipes stay data:
  {"type": "hook",    "lines": ["WHO WINS", "THE TOURNAMENT?"], "pill": "8 NINJAS • 1 CHAMPION"}
  {"type": "card",    "stage": "QUARTER-FINAL", "a": "NARUTO", "b": "NEJI", "big": false}
  {"type": "stamp",   "lines": ["NARUTO", "ELIMINATED"], "color": "red", "y": 1615}
  {"type": "caption", "text": "RASENGAN", "y": 1480, "sub": "TECHNIQUE 2"}
  {"type": "title",   "text": "ITACHI • FULL MOVESET"}
  {"type": "cta",     "lines": ["WHO WINS", "THE FINAL?"], "picks": ["GAARA", "ITACHI"], "page": "assets/rbx_page.jpg"}
  {"type": "thumb",   "bg": "frame.png", "lines": ["WHO WINS", "THE TOURNAMENT?"], "pill": "8 NINJAS • 1 CHAMPION"}
"""
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops, ImageEnhance

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, "fonts")
LUCKY = os.path.join(FONTS, "LuckiestGuy-Regular.ttf")
LILITA = os.path.join(FONTS, "LilitaOne-Regular.ttf")
W, H = 1080, 1920
INK, PAPER = (14, 10, 18), (247, 240, 225)
GOLD = ((255, 255, 255), (255, 196, 40))
RED = ((255, 235, 225), (235, 50, 30))
WHITE = ((255, 255, 255), (228, 228, 228))
FINALG = ((255, 250, 220), (255, 170, 20))
GRADS = {"gold": GOLD, "red": RED, "white": WHITE, "final": FINALG}
COL = {"NARUTO": (255, 130, 20), "NEJI": (190, 190, 210), "ROCK LEE": (50, 180, 70), "GAARA": (200, 60, 40),
       "SASUKE": (60, 110, 240), "KAKASHI": (150, 160, 175), "ITACHI": (180, 30, 40), "MINATO": (250, 215, 60)}


def F(path, size): return ImageFont.truetype(path, size)


def vgradient(size, top, bottom):
    w, h = size
    y = np.linspace(0, 1, h)[:, None, None]
    col = np.array(top)[None, None, :] * (1 - y) + np.array(bottom)[None, None, :] * y
    return Image.fromarray(np.repeat(col, w, 1).astype(np.uint8), "RGB").convert("RGBA")


def text_layer(size, xy, text, fnt, stroke=0, gradient=GOLD, shadow=(0, 10, INK, 0)):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    mask = Image.new("L", size, 0); ImageDraw.Draw(mask).text(xy, text, font=fnt, fill=255, anchor="mm")
    smask = Image.new("L", size, 0); ImageDraw.Draw(smask).text(xy, text, font=fnt, fill=255, anchor="mm", stroke_width=stroke)
    if shadow:
        dx, dy, col, bl = shadow
        sh = Image.new("RGBA", size, col + (0,))
        off = ImageChops.offset(smask, dx, dy)
        sh.putalpha(off.filter(ImageFilter.GaussianBlur(bl)) if bl else off)
        layer.alpha_composite(sh)
    if stroke:
        st = Image.new("RGBA", size, INK + (0,)); st.putalpha(smask); layer.alpha_composite(st)
    bb = mask.getbbox() or (0, 0, size[0], size[1])
    g = vgradient((size[0], bb[3] - bb[1] + 2), *gradient)
    full = Image.new("RGBA", size, (0, 0, 0, 0)); full.paste(g, (0, bb[1])); full.putalpha(mask)
    layer.alpha_composite(full)
    return layer


def stamp(text, size, grad=GOLD, stroke=14, w=1500):
    lay = text_layer((w, 460), (w / 2, 230), text, F(LUCKY, size), stroke=stroke, gradient=grad)
    return lay.crop(lay.getbbox())


def pill(text, col, fs=52, pad=(34, 16)):
    f = F(LILITA, fs)
    tw = int(f.getlength(text)); w, h = tw + pad[0] * 2 + 20, fs + pad[1] * 2
    img = Image.new("RGBA", (w + 12, h + 14), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.rounded_rectangle([6, 12, w + 6, h + 12], 24, fill=(0, 0, 0, 120))
    d.rounded_rectangle([0, 0, w, h], 24, fill=(24, 26, 32, 238))
    d.rounded_rectangle([0, 0, 16, h], 8, fill=tuple(col) + (255,))
    d.text((20 + pad[0], h / 2 + 2), text, font=f, fill=(255, 255, 255, 255), anchor="lm")
    return img


def canvas(): return Image.new("RGBA", (W, H), (0, 0, 0, 0))
def center(c, im, cx, cy): c.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))
def fit(im, maxw):
    if im.width <= maxw: return im
    s = maxw / im.width
    return im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
def rounded(im, r):
    m = Image.new("L", im.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, im.width - 1, im.height - 1], r, fill=255)
    im = im.convert("RGBA"); im.putalpha(m); return im
def asset(p): return p if os.path.isabs(p) else os.path.join(HERE, p)


def vs_row(c, a, b, y):
    pa, pb = pill(a, COL.get(a, (255, 196, 40)), 58), pill(b, COL.get(b, (255, 196, 40)), 58)
    vs = stamp("VS", 110, grad=RED, stroke=12); gap = 26
    total = pa.width + vs.width + pb.width + gap * 2; x = (W - total) / 2
    c.alpha_composite(pa, (int(x), int(y - pa.height / 2)))
    center(c, vs, x + pa.width + gap + vs.width / 2, y)
    c.alpha_composite(pb, (int(x + pa.width + gap * 2 + vs.width), int(y - pb.height / 2)))


def card_box(c, x, y, w, h, top, bot, win=None, current=False, label=None):
    """One match of the mini bracket: two names, winner gold, loser struck."""
    d = ImageDraw.Draw(c)
    d.rounded_rectangle([x, y, x + w, y + h], 14, fill=(16, 18, 26, 225), outline=(0, 225, 255, 255) if current else (255, 255, 255, 40), width=5 if current else 2)
    f = F(LILITA, 30 if w < 280 else 34)
    for i, name in enumerate((top, bot)):
        ty = y + h * (0.3 if i == 0 else 0.72)
        if win and name == win: col = (255, 200, 50, 255)
        elif win and name != "?": col = (130, 130, 140, 255)
        else: col = (255, 255, 255, 255)
        d.text((x + 16, ty), name, font=f, fill=col, anchor="lm")
        if win and name != win and name != "?":
            tw = f.getlength(name); d.line([x + 12, ty + 2, x + 20 + tw, ty + 2], fill=(235, 50, 30, 255), width=4)
    if label:
        d.text((x + w - 12, y + 8), label, font=F(LILITA, 20), fill=(0, 225, 255, 255) if current else (160, 160, 170, 255), anchor="ra")


def bracket2d(spec, c):
    """Mini bracket always on screen: 4 quarter-finals, 2 semis, the final.
    spec = {names: [8 display names in bracket order], results: {QF1: name, ...}, current: "QF2"}"""
    N, R, cur = spec["names"], spec.get("results", {}), spec.get("current")
    y0 = spec.get("y", 40)
    def w(key): return R.get(key)
    qf = [(N[0], N[1]), (N[2], N[3]), (N[4], N[5]), (N[6], N[7])]
    sf = [(w("QF1") or "?", w("QF2") or "?"), (w("QF3") or "?", w("QF4") or "?")]
    fi = (w("SF1") or "?", w("SF2") or "?")
    bw, bh, gap = 246, 92, 12
    x = (W - (bw * 4 + gap * 3)) / 2
    for i, (a, b) in enumerate(qf):
        card_box(c, x + i * (bw + gap), y0, bw, bh, a, b, w(f"QF{i+1}"), cur == f"QF{i+1}", f"QF{i+1}")
    sw = 300
    for i, (a, b) in enumerate(sf):
        cx = W / 2 + (-1 if i == 0 else 1) * 262
        card_box(c, cx - sw / 2, y0 + bh + 14, sw, bh, a, b, w(f"SF{i+1}"), cur == f"SF{i+1}", f"SEMI {i+1}")
    fw = 340
    card_box(c, W / 2 - fw / 2, y0 + 2 * (bh + 14), fw, bh, fi[0], fi[1], w("F"), cur == "F", "FINAL")
    if spec.get("stage"):
        center(c, pill(spec["stage"], (0, 225, 255), 40), W / 2, y0 + 3 * (bh + 14) + 40)


def pickgrid(spec, c):
    names = spec["names"]
    center(c, fit(stamp(spec.get("title", "PICK YOUR NINJA"), 150, stroke=15), 1000), W / 2, 300)
    if spec.get("sub"): center(c, pill(spec["sub"], (255, 140, 40), 50), W / 2, 450)
    y0, rowh, colx = spec.get("y", 1190), 132, (W / 2 - 250, W / 2 + 250)
    for i, n in enumerate(names):
        col, row = i // 4, i % 4
        p = pill(f"{i+1}  {n}", COL.get(n, (255, 196, 40)), 54, pad=(30, 18))
        c.alpha_composite(p, (int(colx[col] - 215), int(y0 + row * rowh - p.height / 2)))


def render(spec, out):
    t = spec["type"]; c = canvas()
    if t == "hook":
        ys = [360, 540, 700]
        for i, line in enumerate(spec["lines"]):
            center(c, fit(stamp(line, 190 if i == 0 else 150, stroke=16 if i == 0 else 15), 1000), W / 2, ys[i])
        if spec.get("pill"): center(c, pill(spec["pill"], (255, 140, 40), 50), W / 2, 700 if len(spec["lines"]) < 3 else 840)
    elif t == "card":
        big = spec.get("big")
        center(c, fit(stamp(spec["stage"], 210 if big else 140, grad=FINALG if big else GOLD, stroke=15), 980), W / 2, 300)
        vs_row(c, spec["a"], spec["b"], spec.get("y", 1590))
    elif t == "stamp":
        grad = GRADS.get(spec.get("color", "gold"), GOLD); y = spec.get("y", 1615)
        for i, line in enumerate(spec["lines"]):
            center(c, fit(stamp(line, 130 if i == 0 else 110, grad=grad, stroke=14 if i == 0 else 12), 980), W / 2, y - 75 + i * 150)
    elif t == "caption":
        y = spec.get("y", 1480)
        center(c, fit(stamp(spec["text"], spec.get("size", 120), grad=GRADS.get(spec.get("color", "white"), WHITE), stroke=13), 1000), W / 2, y)
        if spec.get("sub"): center(c, pill(spec["sub"], tuple(spec.get("subColor", (255, 196, 40))), 44), W / 2, y + 120)
    elif t == "title":
        center(c, fit(stamp(spec["text"], spec.get("size", 96), grad=GRADS.get(spec.get("color", "gold"), GOLD), stroke=11), 1000), W / 2, spec.get("y", 250))
        if spec.get("sub"): center(c, pill(spec["sub"], tuple(spec.get("subColor", (255, 140, 40))), 46), W / 2, spec.get("y", 250) + 120)
    elif t == "cta":
        lines = spec.get("lines", ["WHO WINS?"])
        center(c, fit(stamp(lines[0], 170, stroke=16), 1000), W / 2, 230)
        if len(lines) > 1: center(c, fit(stamp(lines[1], 150, stroke=15), 1000), W / 2, 395)
        y_pick = 575
        if spec.get("picks"):
            a, b = spec["picks"]
            center(c, pill(a, COL.get(a, (255, 196, 40)), 64, pad=(40, 20)), W / 2 - 250, y_pick)
            center(c, pill(b, COL.get(b, (255, 196, 40)), 64, pad=(40, 20)), W / 2 + 250, y_pick)
            center(c, stamp("OR", 70, grad=WHITE, stroke=9), W / 2, y_pick)
        center(c, pill(spec.get("ask", "COMMENT YOUR PICK"), (255, 196, 40), 54), W / 2, 700)
        page = spec.get("page", "assets/rbx_page.jpg")
        if page and os.path.exists(asset(page)):
            pg = Image.open(asset(page)).convert("RGB")
            pg = pg.crop((0, 0, pg.width, min(pg.height, int(pg.width * 1.32))))
            pg = pg.resize((560, int(pg.height * 560 / pg.width)), Image.LANCZOS)
            frame = rounded(Image.new("RGBA", (pg.width + 20, pg.height + 20), (255, 255, 255, 255)), 34)
            frame.alpha_composite(rounded(pg, 26), (10, 10))
            sh = Image.new("RGBA", (frame.width + 80, frame.height + 80), (0, 0, 0, 0))
            sh.paste((0, 0, 0, 150), (40, 52, 40 + frame.width, 52 + frame.height), frame.split()[3])
            sh = sh.filter(ImageFilter.GaussianBlur(18)); y0 = 800
            c.alpha_composite(sh, (int(W / 2 - sh.width / 2), y0 - 40)); c.alpha_composite(frame, (int(W / 2 - frame.width / 2), y0))
            center(c, pill(spec.get("tag", "PLAY FREE ON ROBLOX"), (0, 176, 111), 50), W / 2, y0 + frame.height + 70)
    elif t == "bracket2d":
        bracket2d(spec, c)
    elif t == "pickgrid":
        pickgrid(spec, c)
    elif t == "words":
        # devlog captions: a few words, the spoken one in gold
        words, hi = spec["words"], spec.get("hi", -1)
        f = F(LUCKY, spec.get("size", 96)); y = spec.get("y", 1450)
        widths = [f.getlength(w + " ") for w in words]; x = (W - sum(widths)) / 2
        for i, wd in enumerate(words):
            lay = text_layer((int(widths[i]) + 60, 220), ((widths[i] + 60) / 2, 110), wd, f, stroke=12, gradient=GOLD if i == hi else WHITE)
            c.alpha_composite(lay, (int(x - 30), int(y - 110))); x += widths[i]
    elif t == "thumb":
        bg = Image.open(asset(spec["bg"])).convert("RGB"); z = spec.get("zoom", 1.18)
        bg = bg.resize((int(W * z), int(H * z)), Image.LANCZOS); x0 = (bg.width - W) // 2; y0 = int((bg.height - H) * spec.get("ypos", 0.62))
        c = ImageEnhance.Color(bg.crop((x0, y0, x0 + W, y0 + H))).enhance(1.15).convert("RGBA")
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(sh)
        for y in range(0, 820): d.line([(0, y), (W, y)], fill=(0, 0, 0, int(185 * (1 - y / 820))))
        for y in range(1450, H): d.line([(0, y), (W, y)], fill=(0, 0, 0, int(150 * (y - 1450) / (H - 1450))))
        c.alpha_composite(sh)
        for i, line in enumerate(spec["lines"]):
            center(c, fit(stamp(line, 210 if i == 0 else 150, stroke=17 if i == 0 else 15), 1010), W / 2, 260 + i * 195)
        if spec.get("pill"): center(c, pill(spec["pill"], (255, 140, 40), 60), W / 2, 1680)
        c.convert("RGB").save(out, quality=92); return out
    else:
        raise ValueError("unknown overlay type " + t)
    c.save(out); return out


if __name__ == "__main__":
    # python3 ov.py '{"type":"caption","text":"RASENGAN"}' out.png
    print(render(json.loads(sys.argv[1]), sys.argv[2]))
