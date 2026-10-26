"""Preview sheets (nd_preview: every rendered frame tiled + a JSON manifest)
-> looping MP4 clips for review pages.
Usage: python3 films_to_video.py <films_dir> <out_dir> [loops]"""
import json, os, subprocess, sys, tempfile
from PIL import Image


def convert(png, out_dir, loops=3):
    meta = json.load(open(png[:-4] + ".json"))
    sheet = Image.open(png).convert("RGB")
    cell, cols, n = meta["cell"], meta["columns"], meta["frames"]
    fps = max(1.0, float(meta["fps"]))
    name = os.path.basename(png)[:-4]
    with tempfile.TemporaryDirectory() as tmp:
        k = 0
        for _ in range(loops):
            for i in range(n):
                r, c = divmod(i, cols)
                sheet.crop((c * cell, r * cell, (c + 1) * cell, (r + 1) * cell)).save(os.path.join(tmp, "f%04d.png" % k))
                k += 1
        out = os.path.join(out_dir, name + ".mp4")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "%.3f" % fps, "-i", os.path.join(tmp, "f%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-crf", "23", "-r", "30", out], check=True)
    return out


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    loops = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    os.makedirs(dst, exist_ok=True)
    for f in sorted(os.listdir(src)):
        if f.endswith(".png") and os.path.exists(os.path.join(src, f[:-4] + ".json")):
            out = os.path.join(dst, f[:-4] + ".mp4")
            if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(os.path.join(src, f)):
                continue  # up to date
            print(convert(os.path.join(src, f), dst, loops))
