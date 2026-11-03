"""WHO WINS? episode 1 — Naruto vs Sasuke."""
import sys, os, math, random, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from video import *
from thumb_rest_fx import sand_burst as SAND, impact_star

OUT = "vid/ep2"
os.makedirs(OUT, exist_ok=True)
A = dict(name="ROCK LEE", move="PRIMARY LOTUS", col=(60, 200, 80), dark=(10, 70, 20), cut="cap/solo_lee.png", bust="cap/solo_lee.png")
B = dict(name="GAARA", move="SAND COFFIN", col=(230, 150, 60), dark=(110, 40, 20), cut="cap/solo_gaara.png", bust="cap/solo_gaara.png")
LUCK = lambda s: font(LUCKY, s)

# ---------- shared pieces ----------
a_full = stylize(cut(A["cut"]), A["col"])
b_full = stylize(cut(B["cut"]), B["col"])
a_bust = stylize(cut(A["bust"]), A["col"])
b_bust = stylize(cut(B["bust"]), B["col"])


def title_stamp(text, size, grad, stroke=14):
    lay = text_layer((W, 400), (W / 2, 200), text, LUCK(size), PAPER, stroke=stroke, stroke_fill=INK, gradient=grad, shadow=(0, 12, INK, 0))
    bb = lay.getbbox()
    return lay.crop(bb)


WHO = title_stamp("WHO WINS?", 170, ((255, 255, 255), (255, 214, 80)), 16)
VS = title_stamp("VS", 230, ((255, 250, 220), (255, 90, 40)), 18)
NA = title_stamp(A["name"], 120, ((255, 240, 200), A["col"]))
NB = title_stamp(B["name"], 120, ((230, 240, 255), B["col"]))
MA = title_stamp(A["move"], 150, ((255, 255, 255), A["col"]))
MB = title_stamp(B["move"], 150, ((255, 255, 255), B["col"]))


def split_bg():
    top = vgradient(S, [(0, A["dark"]), (0.5, A["col"]), (1, A["col"])])
    bot = vgradient(S, [(0, B["col"]), (0.5, B["col"]), (1, B["dark"])])
    mask = Image.new("L", S, 0)
    ImageDraw.Draw(mask).polygon([(0, 0), (W, 0), (W, 860), (0, 1060)], fill=255)
    bg = Image.composite(top, bot, mask)
    bg.alpha_composite(rays(S, (W / 2, 960), 30, (255, 255, 255), alpha=40, spread=0.5, seed=2))
    slash = Image.new("RGBA", S, (0, 0, 0, 0))
    d = ImageDraw.Draw(slash)
    d.polygon([(0, 1040), (W, 840), (W, 880), (0, 1080)], fill=INK + (255,))
    d.polygon([(0, 1048), (W, 848), (W, 872), (0, 1072)], fill=PAPER + (255,))
    bg.alpha_composite(slash)
    return bg


SPLIT = split_bg()
SPEED_A = speed_lines(S, (W / 2, 960), 200, (255, 255, 255), inner=300, alpha=(60, 170), seed=4)


def scene_vs(path, dur=2.4):
    w = Writer(path)
    n = int(dur * FPS)
    a_img, _ = scaled(a_full, h=980)
    b_img, _ = scaled(b_full, h=980)
    for i in range(n):
        t = i / FPS
        f = SPLIT.copy()
        # fighters slide in
        ka = ease_out(t / 0.28)
        kb = ease_out((t - 0.12) / 0.28)
        za = 1 + 0.04 * t
        ai, _ = scaled(a_img, s=za)
        bi, _ = scaled(b_img, s=za)
        paste_center(f, ai, -500 + ka * 940, 600)
        paste_center(f, bi, W + 500 - kb * 790, 1330)
        # names
        if t > 0.35:
            k = ease_back((t - 0.35) / 0.2)
            ni, _ = scaled(NA, s=max(0.01, k))
            paste_center(f, ni, 800, 640)
        if t > 0.45:
            k = ease_back((t - 0.45) / 0.2)
            ni, _ = scaled(NB, s=max(0.01, k))
            paste_center(f, ni, 290, 1240)
        # VS slam
        if t > 0.55:
            k = (t - 0.55) / 0.18
            s = 2.6 - 1.6 * ease_out(k) if k < 1 else 1 + 0.03 * math.sin(t * 9)
            vi, _ = scaled(VS, s=s)
            dx, dy = shake(t, 14 * max(0, 1 - (t - 0.55) / 0.5))
            paste_center(f, vi, W / 2 + dx, 960 + dy)
        # hook title
        k = ease_back(t / 0.22)
        wi, _ = scaled(WHO, s=max(0.01, k))
        paste_center(f, wi, W / 2, 230)
        if t < 0.08:
            f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(255 * (1 - t / 0.08)))))
        w.add(f)
    w.close()


def scene_bust(path, who, dur=1.1):
    P = A if who == "a" else B
    img = a_bust if who == "a" else b_bust
    base = vgradient(S, [(0, P["dark"]), (0.55, P["col"]), (1, P["dark"])])
    base.alpha_composite(radial(S, (W / 2, 900), 900, (255, 255, 255), power=2, alpha=120))
    lines = speed_lines(S, (W / 2, 880), 220, (255, 255, 255), inner=380, alpha=(70, 200), seed=7 if who == "a" else 9)
    mv = MA if who == "a" else MB
    w = Writer(path)
    n = int(dur * FPS)
    big, _ = scaled(img, h=1500)
    for i in range(n):
        t = i / FPS
        f = base.copy()
        f.alpha_composite(lines.rotate(t * (25 if who == "a" else -25), center=(W / 2, 880)))
        z = 1.12 - 0.12 * ease_out(t / 0.25) + 0.05 * t
        bi, _ = scaled(big, s=z)
        dx, dy = shake(t, 10 * max(0, 1 - t / 0.35), seed=3)
        cx = W / 2 + (-40 if who == "a" else 40)
        paste_center(f, bi, cx + dx, 1050 + dy)
        if who == "a":
            loc(f, sparks, (W / 2 + dx, 1000 + dy), 900, 50, (200, 255, 200), rmin=300, rmax=700, seed=i, length=(40, 140), width=(3, 8))
        else:
            loc(f, SAND, (W / 2 + dx, 1150 + dy), 760, 620 + 40 * math.sin(t * 8), seed=i)
        k = ease_back((t - 0.12) / 0.2)
        if t > 0.12:
            mi, _ = scaled(mv, s=max(0.01, k))
            paste_center(f, mi, W / 2, 300)
        if t < 0.06:
            f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(220 * (1 - t / 0.06)))))
        w.add(f)
    w.close()


def clash_base():
    chars = grade(Image.open("cap/L.png").convert("RGBA"), 1.08, 1.2)
    bg = vgradient(S, [(0, (255, 170, 60)), (0.5, (250, 210, 120)), (1, (160, 104, 52))])
    cy = 980
    bg.alpha_composite(ink_band(S, 1380, 110, -9, VERMILION, 235))
    scale = 1.38
    layer, bb, pos = place(bg, chars, scale, (W / 2, cy), ref="center")
    fg = Image.new("RGBA", S, (0, 0, 0, 0))
    fg.alpha_composite(glow_of(layer, (255, 255, 255), grow=5, blur=14, strength=1.0))
    fg.alpha_composite(outline_of(layer, INK, 6))
    fg.alpha_composite(layer)
    hit = map_point((975, 360), bb, scale, pos)
    return bg, fg, hit, hit


def zoom_frame(img, z, cx, cy):
    """Zoom about (cx, cy) by z (>=1)."""
    w2, h2 = W / z, H / z
    box = (cx - w2 / 2, cy - h2 / 2, cx + w2 / 2, cy + h2 / 2)
    return img.transform(S, Image.EXTENT, box, Image.BILINEAR)


def scene_clash(path, dur=3.2, end_flash=True):
    bg, fg, na, sa = clash_base()
    clash = ((na[0] + sa[0]) / 2, na[1])
    lines = speed_lines(S, clash, 220, (255, 250, 235), inner=330, alpha=(40, 160), seed=12)
    w = Writer(path)
    n = int(dur * FPS)
    for i in range(n):
        t = i / FPS
        p = t / dur
        f = bg.copy()
        f.alpha_composite(rays(S, clash, 30, (255, 236, 200), alpha=int(40 + 60 * p), spread=0.45, seed=1).rotate(t * 8, center=clash))
        f.alpha_composite(lines.rotate(-t * 30, center=clash))
        # fighters push towards each other a little
        push = 10 * math.sin(t * 25) * p
        f.alpha_composite(fg, (int(push), 0))
        r = 1 + 0.6 * p
        f.alpha_composite(radial(S, clash, 400 + 300 * p, (255, 255, 255), power=2.4, alpha=int(160 + 80 * p)))
        loc(f, SAND, (clash[0] + 90, clash[1] + 60), int(330 * r) * 1.2, int(330 * r), seed=i)
        loc(f, impact_star, clash, 260, int(110 * r * (1 + 0.15 * math.sin(t * 30))), (255, 244, 170), seed=i % 5)
        loc(f, sparks, clash, 600, int(30 + 60 * p), (255, 236, 170), rmin=60, rmax=int(200 + 300 * p), seed=i, length=(15, 60))
        f.alpha_composite(radial(S, clash, int(150 + 120 * p), (235, 245, 255), power=0.8, alpha=255))
        dx, dy = shake(t, 4 + 22 * p ** 2, seed=5)
        z = 1.0 + 0.25 * ease_out(p)
        f = zoom_frame(f, z, clash[0] + dx, clash[1] + dy)
        if end_flash and t > dur - 0.25:
            k = (t - (dur - 0.25)) / 0.25
            f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(255 * k))))
        w.add(f)
    w.close()
    return bg, fg, na, sa


def scene_vote(path, dur=2.8):
    bg, fg, na, sa = clash_base()
    clash = ((na[0] + sa[0]) / 2, na[1])
    still = bg.copy()
    still.alpha_composite(fg)
    still.alpha_composite(radial(S, clash, 700, (255, 255, 255), power=2.2, alpha=200))
    loc(still, SAND, (clash[0] + 90, clash[1] + 60), 620, 520, seed=3)
    loc(still, impact_star, clash, 240, 180, (255, 244, 170))
    still.alpha_composite(radial(S, clash, 260, (235, 245, 255), power=0.8, alpha=255))
    still = still.filter(ImageFilter.GaussianBlur(3))
    still.alpha_composite(Image.new("RGBA", S, (0, 0, 0, 110)))
    q1 = title_stamp("COMMENT", 150, ((255, 255, 255), (255, 214, 80)))
    q2 = title_stamp("WHO WINS", 170, ((255, 255, 255), (255, 214, 80)), 16)
    p2 = title_stamp("PART 2: THEY FIGHT IN-GAME", 64, ((255, 255, 255), (200, 220, 255)), 9)
    w = Writer(path)
    n = int(dur * FPS)
    for i in range(n):
        t = i / FPS
        f = still.copy()
        k1 = ease_back(t / 0.2)
        k2 = ease_back((t - 0.12) / 0.2)
        if k1 > 0:
            im, _ = scaled(q1, s=max(0.01, k1))
            paste_center(f, im, W / 2, 330)
        if t > 0.12:
            im, _ = scaled(q2, s=max(0.01, k2))
            paste_center(f, im, W / 2, 500)
        # two answer chips that pulse alternately
        for j, (P, NM, x) in enumerate([(A, NA, 290), (B, NB, 790)]):
            if t > 0.35 + j * 0.12:
                k = ease_back((t - 0.35 - j * 0.12) / 0.2)
                pulse = 1 + 0.06 * max(0, math.sin(t * 6 + j * math.pi))
                chip = Image.new("RGBA", (440, 170), (0, 0, 0, 0))
                d = ImageDraw.Draw(chip)
                d.rounded_rectangle([0, 0, 439, 169], 36, fill=INK + (255,))
                d.rounded_rectangle([8, 8, 431, 161], 30, fill=P["col"] + (255,))
                nm, _ = scaled(NM, w=380) if NM.width / NM.height > 3.4 else scaled(NM, h=110)
                chip.alpha_composite(nm, (int(220 - nm.width / 2), int(85 - nm.height / 2)))
                ci, _ = scaled(chip, s=max(0.01, k * pulse))
                paste_center(f, ci, x, 1260)
        if t > 0.8:
            k = ease_out((t - 0.8) / 0.25)
            im, _ = scaled(p2, s=max(0.01, k))
            paste_center(f, im, W / 2, 1430)
        if t < 0.1:
            f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(255 * (1 - t / 0.1)))))
        w.add(f)
    w.close()


def scene_end(path, dur=1.8):
    bg = vgradient(S, [(0, (14, 10, 18)), (1, (40, 16, 22))])
    bg.alpha_composite(ink_band(S, 1000, 260, -9, VERMILION, 255, seed=8))
    k1 = text_layer(S, (W / 2, 640), "忍", font(CJK, 700), (0, 0, 0))
    k1.putalpha(k1.getchannel("A").point(lambda v: v * 0.25))
    bg.alpha_composite(k1)
    logo = title_stamp("NINJA DUEL", 190, ((255, 242, 160), (255, 138, 30)), 16)
    sub = title_stamp("FREE ON ROBLOX", 96, ((255, 255, 255), (230, 230, 230)), 11)
    beta = badge((600, 200), (300, 100), "BETA", LUCK(80), VERMILION, PAPER, angle=-8)
    srch = title_stamp("SEARCH: NINJA DUEL", 64, ((255, 255, 255), (255, 220, 160)), 9)
    icon = Image.open("out/icon_1024.png").convert("RGBA").resize((330, 330), Image.LANCZOS)
    m = Image.new("L", icon.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, 329, 329], 60, fill=255)
    icon.putalpha(m)
    ib = Image.new("RGBA", (350, 350), (0, 0, 0, 0))
    ImageDraw.Draw(ib).rounded_rectangle([0, 0, 349, 349], 70, fill=PAPER + (255,))
    ib.alpha_composite(icon, (10, 10))
    w = Writer(path)
    n = int(dur * FPS)
    for i in range(n):
        t = i / FPS
        f = bg.copy()
        k = ease_back(t / 0.25)
        ii, _ = scaled(ib, s=max(0.01, k))
        paste_center(f, ii, W / 2, 560)
        if t > 0.12:
            li, _ = scaled(logo, s=max(0.01, ease_back((t - 0.12) / 0.22)))
            paste_center(f, li, W / 2, 900)
        if t > 0.3:
            f.alpha_composite(beta, (int(W / 2 + 60), 930))
            si, _ = scaled(sub, s=max(0.01, ease_out((t - 0.3) / 0.2)))
            paste_center(f, si, W / 2, 1090)
        if t > 0.5:
            si, _ = scaled(srch, s=max(0.01, ease_out((t - 0.5) / 0.2)))
            paste_center(f, si, W / 2, 1230)
        w.add(f)
    w.close()


if __name__ == "__main__":
    which = sys.argv[1:] or ["vs", "a", "b", "clash", "vote", "end"]
    if "vs" in which: scene_vs(f"{OUT}/s1.mp4")
    if "a" in which: scene_bust(f"{OUT}/s2.mp4", "a")
    if "b" in which: scene_bust(f"{OUT}/s3.mp4", "b")
    if "clash" in which: scene_clash(f"{OUT}/s4.mp4")
    if "vote" in which: scene_vote(f"{OUT}/s5.mp4")
    if "end" in which: scene_end(f"{OUT}/s6.mp4")
    print("done")
