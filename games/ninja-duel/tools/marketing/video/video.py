"""Vertical 9:16 'WHO WINS?' episode renderer for Ninja Duel (TikTok / Shorts)."""
import math, random, subprocess, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from fx import *

W, H = 1080, 1920
FPS = 30
S = (W, H)


def ease_out(t):
    t = max(0.0, min(1.0, t))
    return 1 - (1 - t) ** 3


def ease_back(t, s=1.7):
    t = max(0.0, min(1.0, t))
    t -= 1
    return t * t * ((s + 1) * t + s) + 1


def cut(path):
    im = Image.open(path).convert("RGBA")
    bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    return im.crop(bb)


def scaled(im, h=None, w=None, s=None):
    if s is None:
        s = h / im.height if h else w / im.width
    return im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS), s


def paste_center(canvas, im, cx, cy):
    canvas.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))


def stylize(cutout, glow_col, outline=6, glow=18):
    """Cut-out with ink outline + coloured glow, on a padded transparent canvas."""
    pad = glow * 3
    big = Image.new("RGBA", (cutout.width + pad * 2, cutout.height + pad * 2), (0, 0, 0, 0))
    big.paste(cutout, (pad, pad))
    out = Image.new("RGBA", big.size, (0, 0, 0, 0))
    out.alpha_composite(glow_of(big, glow_col, grow=5, blur=glow, strength=1.3))
    out.alpha_composite(outline_of(big, INK, outline))
    out.alpha_composite(big)
    return out


def shake(t, amp, seed=0):
    return (amp * math.sin(t * 91 + seed) * math.cos(t * 37), amp * math.sin(t * 73 + seed * 2))


class Writer:
    def __init__(self, path):
        self.i = 0
        self.prev = [int(x) for x in os.environ.get("PREVIEW", "").split(",") if x]
        self.path = path
        if self.prev:
            self.p = None
            return
        self.tmp = path[:-4] + ".tmp.mp4"
        self.path = path
        self.p = subprocess.Popen(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                                   "-c:v", "libx264", "-preset", "veryfast", "-crf", "18", "-pix_fmt", "yuv420p", self.tmp], stdin=subprocess.PIPE)

    def add(self, frame):
        if self.prev:
            if self.i in self.prev:
                frame.convert("RGB").save(self.path[:-4] + f"_f{self.i}.jpg", quality=88)
            self.i += 1
            return
        self.p.stdin.write(frame.convert("RGB").tobytes())
        self.i += 1

    def close(self):
        if self.p is None:
            return
        self.p.stdin.close()
        if self.p.wait() == 0:
            os.replace(self.tmp, self.path)


# ---------------- audio ----------------
SR = 44100


def env(n, a=0.002, d=0.3):
    t = np.arange(n) / SR
    return np.minimum(1, t / a) * np.exp(-t / d)


def taiko(dur=0.6, f=70):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f_t = f * (1 + 1.2 * np.exp(-t * 30))
    s = np.sin(2 * np.pi * np.cumsum(f_t) / SR) * env(n, 0.001, 0.18)
    s += np.random.randn(n) * env(n, 0.001, 0.02) * 0.4
    return s


def impact(dur=1.2):
    n = int(SR * dur)
    t = np.arange(n) / SR
    boom = np.sin(2 * np.pi * np.cumsum(45 * (1 + 2 * np.exp(-t * 18))) / SR) * env(n, 0.001, 0.4)
    noise = np.random.randn(n)
    noise = np.convolve(noise, np.ones(8) / 8, "same") * env(n, 0.001, 0.12)
    return boom * 0.9 + noise * 0.7


def whoosh(dur=0.45, up=True):
    n = int(SR * dur)
    noise = np.random.randn(n)
    out = np.zeros(n)
    k = 1
    for i in range(0, n, 512):
        frac = i / n
        k = int(2 + (30 * (1 - frac) if up else 30 * frac))
        seg = noise[i:i + 512]
        out[i:i + 512] = np.convolve(seg, np.ones(k) / k, "same")
    shape = np.sin(np.linspace(0, np.pi, n)) ** 2
    return out * shape * 1.4


def zap(dur=0.5):
    n = int(SR * dur)
    t = np.arange(n) / SR
    s = np.sign(np.sin(2 * np.pi * (900 + 400 * np.sin(t * 80)) * t)) * 0.3 + np.random.randn(n) * 0.5
    return s * env(n, 0.002, 0.15) * (0.6 + 0.4 * (np.random.rand(n) > 0.5))


def riser(dur=2.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = 200 + 1600 * (t / dur) ** 2
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.25 + np.random.randn(n) * 0.25 * (t / dur)
    return s * (t / dur) ** 1.5


def beat_track(total, bpm=140, start=0.0, stop=None, seed=1):
    """Simple driving taiko/hat pattern."""
    n = int(SR * total)
    out = np.zeros(n)
    stop = stop or total
    step = 60 / bpm / 2
    i = 0
    tt = start
    while tt < stop:
        pos = int(tt * SR)
        if i % 4 == 0:
            add(out, taiko(0.5, 62) * 0.9, pos)
        elif i % 4 == 2:
            add(out, taiko(0.35, 95) * 0.55, pos)
        if i % 2 == 1:
            hn = int(SR * 0.05)
            add(out, np.random.randn(hn) * env(hn, 0.001, 0.015) * 0.18, pos)
        i += 1
        tt += step
    return out


def add(buf, snd, pos):
    if pos >= len(buf):
        return
    end = min(len(buf), pos + len(snd))
    buf[pos:end] += snd[:end - pos]


def write_wav(path, buf):
    import wave
    buf = buf / max(1e-6, np.max(np.abs(buf))) * 0.89
    data = (buf * 32767).astype(np.int16)
    st = np.stack([data, data], 1)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(st.tobytes())


def comp(canvas, layer, x, y):
    """alpha_composite allowing negative / overflowing offsets."""
    x, y = int(x), int(y)
    sx, sy = max(0, -x), max(0, -y)
    dx, dy = max(0, x), max(0, y)
    w = min(layer.width - sx, canvas.width - dx)
    h = min(layer.height - sy, canvas.height - dy)
    if w <= 0 or h <= 0:
        return
    canvas.alpha_composite(layer.crop((sx, sy, sx + w, sy + h)), (dx, dy))


def loc(canvas, fn, c, ext, *a, **k):
    """Run a full-canvas FX function on a local square of half-size ext around c."""
    ext = int(ext)
    layer = fn((2 * ext, 2 * ext), (ext, ext), *a, **k)
    comp(canvas, layer, c[0] - ext, c[1] - ext)


def loc_bolt(canvas, p0, p1, *a, **k):
    x0, y0 = min(p0[0], p1[0]) - 80, min(p0[1], p1[1]) - 80
    x1, y1 = max(p0[0], p1[0]) + 80, max(p0[1], p1[1]) + 80
    layer = lightning((int(x1 - x0), int(y1 - y0)), (p0[0] - x0, p0[1] - y0), (p1[0] - x0, p1[1] - y0), *a, **k)
    comp(canvas, layer, x0, y0)
