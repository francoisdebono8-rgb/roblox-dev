"""Cut an OBS recording of the jutsu reel into shots and draw a contact sheet per shot.

The reel (probes/jutsu_reel_server.luau + jutsu_reel_client.luau) opens every
shot on a black title card inside the game viewport; blackdetect on the cropped
viewport finds the cards, the order of the cards is the order of the reel.

  python3 reel_sheets.py REC.mov OUT_DIR LABELS.json [crop x:y:w:h]

LABELS.json: the reel's NDReelLog (list of {i, fighter, label, action}); the
duel-start cards ("start") are recognised as the cards not followed by a cast
(the reel puts one before each fighter's first shot).
Writes OUT_DIR/shot_NN.png (frames every STEP s from the card's end) and
OUT_DIR/shots.json (start/end per shot in the recording).
"""
import json, os, re, subprocess, sys

STEP = float(os.environ.get("STEP", ".125"))
COUNT = int(os.environ.get("COUNT", "12"))
COLS = int(os.environ.get("COLS", "6"))
TILE = int(os.environ.get("TILE", "240"))
# The fighters' part of the viewport (the reel's camera keeps them central).
INNER = os.environ.get("INNER", "")


def blacks(src, crop):
    vf = (f"crop={crop}," if crop else "") + "scale=320:-2,blackdetect=d=0.12:pix_th=0.10:pic_th=0.90"
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", src, "-vf", vf, "-an", "-f", "null", "-"],
                       capture_output=True, text=True)
    return [(float(a), float(b)) for a, b in re.findall(r"black_start:([\d.]+) black_end:([\d.]+)", p.stderr)]


def sheet(src, crop, t0, t1, out, title, step=None):
    step = step or STEP
    n = max(2, min(COUNT, int((t1 - t0) / step) + 1))
    vf = (f"crop={crop}," if crop else "") + (f"crop={INNER}," if INNER else "") + f"fps={1/step:.4f},scale={TILE}:-2,tile={COLS}x{(n + COLS - 1)//COLS}:padding=2:color=white"
    vf += f",drawtext=text='{title}':x=8:y=8:fontsize=20:fontcolor=yellow:box=1:boxcolor=black@0.6"
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", f"{t0:.3f}", "-t", f"{step*n:.3f}", "-i", src,
                    "-vf", vf, "-frames:v", "1", out], check=True)


def main():
    src, out, labels = sys.argv[1], sys.argv[2], json.load(open(sys.argv[3]))
    crop = sys.argv[4] if len(sys.argv) > 4 else ""
    os.makedirs(out, exist_ok=True)
    cards = blacks(src, crop)
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", src],
                               capture_output=True, text=True).stdout.strip())
    # The reel: one start card per fighter, then its shots.
    seq, last = [], None
    for rec in labels:
        if rec["fighter"] != last:
            seq.append({"start": True, "fighter": rec["fighter"]})
            last = rec["fighter"]
        seq.append(rec)
    print("cards found", len(cards), "expected", len(seq))
    shots = []
    for k, rec in enumerate(seq):
        if k >= len(cards):
            break
        if rec.get("start"):
            continue
        t0 = cards[k][1]
        t1 = cards[k + 1][0] if k + 1 < len(cards) else dur
        name = "shot_%02d" % rec["i"]
        title = "%02d %s %s" % (rec["i"], rec["fighter"], rec["label"].replace(":", "").replace("'", ""))
        long = rec["label"] == "Ultimate"
        sheet(src, crop, t0, t1, os.path.join(out, name + ".png"), title, step=(t1 - t0) / COUNT if long else None)
        shots.append({"i": rec["i"], "fighter": rec["fighter"], "label": rec["label"], "t0": t0, "t1": t1})
    json.dump(shots, open(os.path.join(out, "shots.json"), "w"), indent=1)
    print("sheets", len(shots))


if __name__ == "__main__":
    main()
