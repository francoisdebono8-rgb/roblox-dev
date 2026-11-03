"""WHO WINS? episodes built from real gameplay (Studio AI vs AI recordings)."""
import sys, os, json, math, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from video import *

GW, GH = 1920, 944          # wide gameplay mezzanine
PANEL_Y, PANEL_H = 430, 1350
CW, CH = 720, 900            # crop from the wide frame (4:5)
LUCK = lambda s: font(LUCKY, s)


def stamp(text, size, grad, stroke=14, w=1400):
    lay = text_layer((w, 420), (w / 2, 210), text, LUCK(size), PAPER, stroke=stroke, stroke_fill=INK, gradient=grad, shadow=(0, 12, INK, 0))
    return lay.crop(lay.getbbox())


def read_frames(src, t0, t1):
    n = int(round((t1 - t0) * FPS))
    p = subprocess.Popen(["ffmpeg", "-v", "error", "-ss", f"{t0:.3f}", "-i", src, "-frames:v", str(n), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    for _ in range(n):
        b = p.stdout.read(GW * GH * 3)
        if len(b) < GW * GH * 3:
            break
        yield Image.frombytes("RGB", (GW, GH), b)
    p.stdout.close()
    p.wait()


class Episode:
    def __init__(self, src, track, A, B, out):
        self.src, self.A, self.B, self.out = src, A, B, out
        self.track = json.load(open(track))
        os.makedirs(out, exist_ok=True)
        self.bg = self.make_bg()
        self.cache = {}

    def make_bg(self):
        bg = vgradient(S, [(0, (16, 10, 20)), (0.22, (40, 14, 22)), (0.8, (24, 10, 16)), (1, (8, 6, 10))])
        bg.alpha_composite(ink_band(S, 395, 26, -2, VERMILION, 255, seed=3))
        bg.alpha_composite(ink_band(S, PANEL_Y + PANEL_H + 18, 26, 2, VERMILION, 255, seed=4))
        return bg

    def centre(self, i, prev):
        tr = self.track[min(i, len(self.track) - 1)]
        pts = [c for c in tr if c]
        if not pts:
            return prev
        x = sum(c[0] for c in pts) / len(pts) * GW
        y = sum(c[1] for c in pts) / len(pts) * GH
        return (x, y)

    def header(self, f, hud_frame, title="WHO WINS?"):
        if title not in self.cache:
            self.cache[title] = stamp(title, 120, ((255, 255, 255), (255, 214, 80)), 13)
        t = self.cache[title]
        f.alpha_composite(t, (int(W / 2 - t.width / 2), 118))
        # the game's own health bars, both fighters
        left = hud_frame.crop((120, 15, 650, 140)).resize((520, 123), Image.LANCZOS)
        right = hud_frame.crop((1275, 15, 1805, 140)).resize((520, 123), Image.LANCZOS)
        f.paste(left, (14, 266))
        f.paste(right, (W - 534, 266))

    def panel(self, f, frame, c, zoom=1.0):
        cw, ch = CW / zoom, CH / zoom
        cx = min(max(c[0], cw / 2), GW - cw / 2)
        cy = min(max(c[1] - 40, ch / 2 + 40), GH - ch / 2 - 30)
        crop = frame.crop((int(cx - cw / 2), int(cy - ch / 2), int(cx + cw / 2), int(cy + ch / 2))).resize((W, PANEL_H), Image.BICUBIC)
        f.paste(crop, (0, PANEL_Y))

    def segment(self, w, t0, t1, caption=None, cap_col=(255, 214, 80), title="WHO WINS?", zoom_to=1.08, hook=False, flash_at=None, freeze_hold=0.0):
        i0 = int(t0 * FPS)
        c = None
        last = None
        frames = list(read_frames(self.src, t0, t1))
        n = len(frames)
        for k, fr in enumerate(frames):
            t = k / FPS
            nc = self.centre(i0 + k, c or (GW / 2, GH / 2))
            c = nc if c is None else (c[0] * 0.88 + nc[0] * 0.12, c[1] * 0.88 + nc[1] * 0.12)
            f = self.bg.copy()
            z = 1.0 + (zoom_to - 1.0) * (k / max(1, n - 1))
            self.panel(f, fr, c, z)
            self.header(f, fr, title)
            if hook:
                if "hook" not in self.cache:
                    self.cache["hook"] = stamp("WHO WINS?", 200, ((255, 255, 255), (255, 214, 80)), 18, w=1600)
                    self.cache["names"] = stamp(f"{self.A['name']}  VS  {self.B['name']}", 92, ((255, 240, 200), (255, 140, 40)), 11, w=1600)
                s = ease_back(t / 0.22) * (1 + 0.02 * math.sin(t * 10))
                hi, _ = scaled(self.cache["hook"], s=max(0.01, s * 0.62))
                dx, dy = shake(t, 10 * max(0, 1 - t / 0.4))
                paste_center(f, hi, W / 2 + dx, PANEL_Y + 300 + dy)
                if t > 0.15:
                    ni, _ = scaled(self.cache["names"], s=max(0.01, ease_out((t - 0.15) / 0.2) * 0.8))
                    paste_center(f, ni, W / 2, PANEL_Y + 470)
            if caption:
                key = "cap:" + caption
                if key not in self.cache:
                    self.cache[key] = stamp(caption, 130, ((255, 255, 255), cap_col), 13)
                if t > 0.08:
                    ci, _ = scaled(self.cache[key], s=max(0.01, ease_back((t - 0.08) / 0.2)))
                    paste_center(f, ci, W / 2, PANEL_Y + 150)
            if k < 2:
                f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, 150 if k == 0 else 60)))
            if flash_at is not None and abs(t - flash_at) < 0.1:
                f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(200 * (1 - abs(t - flash_at) / 0.1)))))
            w.add(f)
            last = (fr, c)
        return last

    def cliffhanger(self, w, last, dur=2.6):
        fr, c = last
        still = self.bg.copy()
        self.panel(still, fr, c, 1.08)
        self.header(still, fr, "WHO WINS?")
        still = still.filter(ImageFilter.GaussianBlur(4))
        still.alpha_composite(Image.new("RGBA", S, (0, 0, 0, 120)))
        q1 = stamp("WHO WINS?", 190, ((255, 255, 255), (255, 214, 80)), 17)
        q2 = stamp("COMMENT YOUR PICK", 88, ((255, 255, 255), (230, 230, 230)), 10)
        p2 = stamp("RESULT IN PART 2", 80, ((255, 240, 200), (255, 140, 40)), 10)
        NA = stamp(self.A["name"], 96, ((255, 255, 255), (255, 255, 255)), 10)
        NB = stamp(self.B["name"], 96, ((255, 255, 255), (255, 255, 255)), 10)
        n = int(dur * FPS)
        for i in range(n):
            t = i / FPS
            f = still.copy()
            if t < 0.12:
                f.alpha_composite(Image.new("RGBA", S, (255, 255, 255, int(255 * (1 - t / 0.12)))))
            im, _ = scaled(q1, s=max(0.01, ease_back(t / 0.22)))
            paste_center(f, im, W / 2, 640)
            if t > 0.15:
                im, _ = scaled(q2, s=max(0.01, ease_out((t - 0.15) / 0.2)))
                paste_center(f, im, W / 2, 800)
            for j, (P, NM, x) in enumerate([(self.A, NA, 285), (self.B, NB, 795)]):
                if t > 0.3 + j * 0.1:
                    k = ease_back((t - 0.3 - j * 0.1) / 0.2)
                    pulse = 1 + 0.06 * max(0, math.sin(t * 6 + j * math.pi))
                    chip = Image.new("RGBA", (460, 170), (0, 0, 0, 0))
                    d = ImageDraw.Draw(chip)
                    d.rounded_rectangle([0, 0, 459, 169], 36, fill=INK + (255,))
                    d.rounded_rectangle([8, 8, 451, 161], 30, fill=P["col"] + (255,))
                    nm, _ = scaled(NM, w=400) if NM.width > 400 else (NM, 1)
                    chip.alpha_composite(nm, (int(230 - nm.width / 2), int(85 - nm.height / 2)))
                    ci, _ = scaled(chip, s=max(0.01, k * pulse))
                    paste_center(f, ci, x, 1020)
            if t > 0.7:
                im, _ = scaled(p2, s=max(0.01, ease_out((t - 0.7) / 0.2)))
                paste_center(f, im, W / 2, 1200)
            w.add(f)

    def passthrough(self, w, path, t0, t1):
        n = int(round((t1 - t0) * FPS))
        p = subprocess.Popen(["ffmpeg", "-v", "error", "-ss", f"{t0:.3f}", "-i", path, "-frames:v", str(n), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
        for _ in range(n):
            b = p.stdout.read(W * H * 3)
            if len(b) < W * H * 3:
                break
            w.add(Image.frombytes("RGB", (W, H), b).convert("RGBA"))
        p.wait()
