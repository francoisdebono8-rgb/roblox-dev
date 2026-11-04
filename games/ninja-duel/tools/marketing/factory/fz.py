"""Ninja Duel content factory — the command line (runs on the Mac, in the Linux VM
of the Claude app, where ffmpeg + Pillow + numpy are installed).

A "job" is one video: Documents/NinjaDuelMedia/jobs/<job>/
    raw/          screen recordings (2940x1912 .mov from macOS)
    src_<n>.mp4   the recording cropped to 9:16 (1080x1920, 60 fps)
    sync_<n>.json where the white SYNC FLASH is in src_<n>.mp4
    log_<n>.json  what Studio logged during that take (ShotRunner)
    recipe.json   the edit: shots, overlays, sounds, end card (made by `plan`, editable)
    out/capcut/   the CapCut kit: real clips, overlays, sounds, voice, timeline.txt
                  (the edit itself is done by hand in CapCut — this tool never assembles a video)

Commands
    ingest <job> <recording.mov> [n]   crop to 9:16 and find the sync flash
    sheet  <video> [fps]               contact sheet with timestamps, to choose shots by eye
    plan   <job> <format> [opts.json]  proposed cut list from the Studio log (pick | devlog | showcase | duel | whowins | result)
    kit    <job>                       cut the real clips + overlays + sounds + timeline.txt for CapCut
    qc     <video> [hold]              freezes, length, loudness, sheet
"""
import json, os, re, subprocess, sys, shutil, glob
from concurrent.futures import ThreadPoolExecutor
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get("NDF_ROOT", os.path.join(os.path.expanduser("~"), "mnt", "Documents", "NinjaDuelMedia"))
CFG = json.load(open(os.path.join(HERE, "config.json")))
sys.path.insert(0, HERE)
import ov  # noqa: E402


def sh(cmd, quiet=True):
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(" ".join(map(str, cmd))[:300] + "\n" + r.stderr[-1500:])
    return r.stdout + r.stderr


def dur(path):
    return float(sh(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path]).strip())


def jdir(job):
    d = os.path.join(ROOT, "jobs", job)
    os.makedirs(os.path.join(d, "out"), exist_ok=True)
    return d


# ---------------------------------------------------------------- ingest / sync
def ingest(job, rec, n="1"):
    d = jdir(job)
    src = os.path.join(d, f"src_{n}.mp4")
    c = CFG["crop"]
    sh(["ffmpeg", "-v", "error", "-y", "-i", rec, "-vf", f"crop={c}," + "scale=1080:1920", "-r", "60",
        "-c:v", "libx264", "-preset", "ultrafast", "-crf", "16", "-pix_fmt", "yuv420p", "-an", src])
    flash = find_flash(src)
    json.dump({"src": os.path.basename(src), "flash": flash, "rec": os.path.basename(rec)}, open(os.path.join(d, f"sync_{n}.json"), "w"))
    print(json.dumps({"src": src, "duration": round(dur(src), 2), "flash": flash}))


def lumas(path, t=40, fps=60):
    w, h = 18, 32
    raw = subprocess.run(["ffmpeg", "-v", "error", "-t", str(t), "-i", path, "-vf", f"fps={fps},scale={w}:{h},format=gray",
                          "-f", "rawvideo", "-"], stdout=subprocess.PIPE).stdout
    a = np.frombuffer(raw, np.uint8).reshape(-1, h * w)
    return a.mean(1)


def find_flash(path):
    """Time (s) of the first frame of the white sync flash, or None."""
    m = lumas(path)
    base = np.median(m)
    hits = np.nonzero((m > 215) & (m > base + 60))[0]
    return round(float(hits[0]) / 60.0, 3) if len(hits) else None


# ---------------------------------------------------------------- sheets / qc
def sheet(video, fps="4", out=None, cols=10):
    out = out or os.path.splitext(video)[0] + "_sheet.png"
    font = os.path.join(HERE, "fonts", "LilitaOne-Regular.ttf")
    n = int(dur(video) * float(fps)) + 1
    rows = (n + cols - 1) // cols
    sh(["ffmpeg", "-v", "error", "-y", "-i", video, "-vf",
        f"fps={fps},scale=135:240,drawtext=fontfile={font}:text='%{{pts\\:flt}}':x=3:y=3:fontsize=16:fontcolor=yellow:box=1:boxcolor=black@0.7,tile={cols}x{rows}",
        "-frames:v", "1", out])
    return out


def freeze_gaps(video, start=0.0, end=None, limit=0.12):
    """Near-duplicate-frame gaps longer than `limit` seconds (recording stutters)."""
    args = ["ffmpeg", "-hide_banner", "-ss", str(start), "-i", video]
    if end: args += ["-t", str(end - start)]
    out = subprocess.run(args + ["-vf", "mpdecimate=hi=200:lo=100:frac=0.1,showinfo", "-f", "null", "-"],
                         stderr=subprocess.PIPE, text=True).stderr
    ts = [float(x.split(":")[1]) + start for x in out.split() if x.startswith("pts_time:")]
    return [(round(a, 2), round(b - a, 2)) for a, b in zip(ts, ts[1:]) if b - a > limit]


def qc(video, hold="0"):
    d = dur(video); hold = float(hold)
    gaps = freeze_gaps(video, 0, d - hold if hold else None)
    vol = sh(["ffmpeg", "-i", video, "-af", "volumedetect", "-vn", "-f", "null", "-"])
    mx = [l.split(":")[1].strip() for l in vol.splitlines() if "max_volume" in l]
    mean = [l.split(":")[1].strip() for l in vol.splitlines() if "mean_volume" in l]
    rep = {"video": video, "duration": round(d, 2), "freezes": gaps, "max_volume": mx[:1], "mean_volume": mean[:1],
           "sheet": sheet(video, "4")}
    print(json.dumps(rep, indent=1))
    return rep


# ---------------------------------------------------------------- planning
def latest_build():
    """Highest vNN among the delivered game builds (Documents/Roblox/ND-Jeu-vNN.rbxlx)."""
    vs = [int(m.group(1)) for f in glob.glob(os.path.join(ROOT, CFG.get("builds_dir", "../Roblox"), "ND-*-v*.rbxlx"))
          for m in [re.search(r"-v(\d+)\.rbxlx$", f)] if m]
    return max(vs) if vs else None


def check_build(log, where):
    """Refuse a take filmed on an old build of the game (04/11: every clip so far
    came from a pre-v25 copy, without the hand seals)."""
    b = log.get("build") or {}
    miss = [f for f in CFG.get("required_features", []) if f not in b.get("features", [])]
    if miss:
        raise RuntimeError(f"{where}: filmed on a build without {', '.join(miss)} (place {b.get('place', '?')}). "
                           "Rebuild the clip place (make_clip_place.py, then Sets.all() in Studio) and film again.")
    m = re.search(r"v(\d+)", b.get("place", ""))
    last = latest_build()
    if m and last and int(m.group(1)) < last:
        raise RuntimeError(f"{where}: filmed in {b['place']} but v{last} is delivered. Rebuild the clip place from ND-Test-v{last} (make_clip_place.py).")
    return b


_BUILDS = []  # the builds of the takes a plan used (written into recipe.json)


def load_take(d, n):
    sync = json.load(open(os.path.join(d, f"sync_{n}.json")))
    log = json.load(open(os.path.join(d, f"log_{n}.json")))
    _BUILDS.append(check_build(log, f"take {n}"))
    if sync["flash"] is None or not log.get("flash"):
        raise RuntimeError(f"take {n}: no sync flash found")
    off = sync["flash"] - log["flash"]["now"]
    ev = [dict(e, v=round(e["t"] + off, 3)) for e in log["events"]]
    ev.sort(key=lambda e: e["v"])
    return sync["src"], log, ev


def combos(hits, gap=0.8):
    out, cur = [], []
    for h in hits:
        if cur and h["v"] - cur[-1]["v"] > gap:
            out.append(cur); cur = []
        cur.append(h)
    if cur: out.append(cur)
    return [{"a": c[0]["v"], "b": c[-1]["v"], "hits": c, "score": sum(x.get("amount", 0) for x in c) + 6 * len(c)} for c in out]


def smooth(video, a, b, cache):
    key = f"{a:.2f}-{b:.2f}"
    if key not in cache: cache[key] = not freeze_gaps(video, a, b)
    return cache[key]


def sfx_for(hits, shot_a, shot_b, t0, speed):
    """One game sound per hit in the shot: 'heavy' for heavies, techniques and big
    blows, 'hit' for the light chain. Hits closer than 80 ms share one sound."""
    out, lastv = [], -9
    for h in hits:
        if not (shot_a <= h["v"] <= shot_b) or h["v"] - lastv < 0.08:
            continue
        tag = str(h.get("tag", ""))
        big = tag == "Heavy" or (not tag.startswith("Light") and h.get("amount", 0) >= CFG["heavy_from"])
        if h.get("amount", 0) < 1.0:
            continue
        out.append({"t": round(t0 + (h["v"] - shot_a) / speed, 3), "name": "heavy" if big else "hit"})
        lastv = h["v"]
    return out


def plan(job, fmt, opts_path=None):
    d = jdir(job)
    opts = json.load(open(opts_path)) if opts_path else {}
    if fmt == "pick": return plan_pick(job, opts)
    if fmt == "devlog": return plan_devlog(job, opts)
    src, log, ev = load_take(d, opts.get("take", "1"))
    video = os.path.join(d, src)
    cache = {}
    A, B = ov_name(log.get("a")), ov_name(log.get("b"))
    shots, overlays, sfx = [], [], []
    t = 0.0

    def add(a, b, speed=1.0, label=""):
        nonlocal t
        shots.append({"src": src, "in": round(a, 3), "out": round(b, 3), "speed": speed, "label": label})
        start = t; t += (b - a) / speed
        if len(shots) > 1: sfx.append({"t": round(start, 3), "name": "whoosh", "vol": 0.45})
        return start

    if fmt in ("duel", "whowins", "result"):
        hits = [e for e in ev if e["kind"] == "hit"]
        ko = next((e["v"] for e in ev if e["kind"] == "ko"), None)
        cands = [c for c in combos(hits) if ko is None or c["b"] < ko - 1.4]
        cands.sort(key=lambda c: -c["score"])
        picked = []
        for c in cands:
            a, b = c["a"] - 0.35, min(c["b"] + 0.35, c["a"] + 1.6)
            if any(not (b < p[0] or a > p[1]) for p in picked): continue
            if not smooth(video, a, b, cache): continue
            picked.append((a, b))
            if len(picked) >= opts.get("combos", 2): break
        picked.sort()
        stage = opts.get("stage", "WHO WINS?")
        card_from = t
        for a, b in picked:
            s0 = add(a, b, 1.0, "combo")
            sfx += sfx_for(hits, a, b, s0, 1.0)
        if ko and fmt != "whowins":
            a, b = ko - 1.1, ko + 0.6
            s0 = add(a, b, 1.0, "ko")
            sfx += sfx_for(hits, a, b, s0, 1.0)
            overlays.append({"spec": {"type": "card", "stage": stage, "a": A, "b": B}, "from": card_from, "to": s0 + 1.0})
            loser = B if log.get("winner") == log.get("a") else A
            winner = A if loser == B else B
            if fmt == "result":
                overlays.append({"spec": {"type": "stamp", "lines": [winner, "WINS!"], "color": "gold", "y": 900}, "from": s0 + 1.05, "to": t})
            else:
                overlays.append({"spec": {"type": "stamp", "lines": [loser, "ELIMINATED"], "color": "red"}, "from": s0 + 1.05, "to": t})
        else:
            overlays.append({"spec": {"type": "card", "stage": stage, "a": A, "b": B}, "from": card_from, "to": t})
        end = {"hold": 2.9, "spec": {"type": "cta", "lines": opts.get("cta", ["WHO WINS?"]), "picks": [A, B] if fmt == "whowins" else None,
                                    "ask": opts.get("ask", "COMMENT YOUR PICK")}}
    elif fmt == "showcase":
        moves = [e for e in ev if e["kind"] == "move" and e.get("ok", True) is not False]  # a broken weave is left out
        endt = next((e["v"] for e in ev if e["kind"] == "end"), None)
        hits = [e for e in ev if e["kind"] == "hit"]
        title = opts.get("title", f"{A} • MOVESET")
        first = moves[0]["v"] if moves else 0
        intro_a = max(0.0, first - 1.0)
        s0 = add(intro_a, first - 0.1, 1.0, "intro")
        overlays.append({"spec": {"type": "title", "text": A, "size": 170, "sub": log.get("title") or "MOVESET", "y": 330}, "from": s0, "to": t})
        for i, m in enumerate(moves):
            nxt = moves[i + 1]["v"] if i + 1 < len(moves) else (endt or m["v"] + 2.4)
            a, b = m["v"] - 0.1, min(nxt - 0.2, m["v"] + opts.get("max_move", 2.2))
            s = add(a, b, opts.get("speed", 1.0), m.get("name", ""))
            cap = {"type": "caption", "text": m.get("name", ""), "y": 1480}
            if m.get("signs"):  # a hand-seal jutsu (v29+): show the two seals under the name
                cap["sub"] = "HAND SEALS  " + m["signs"]
            overlays.append({"spec": cap, "from": s, "to": t})
            sfx += sfx_for(hits, a, b, s, opts.get("speed", 1.0))
        overlays.append({"spec": {"type": "title", "text": title, "size": 80, "y": 200}, "from": 0, "to": t})
        end = {"hold": 2.6, "spec": {"type": "cta", "lines": [opts.get("cta1", "WHO SHOULD"), opts.get("cta2", "I SHOWCASE NEXT?")],
                                    "ask": "COMMENT A NINJA"}}
    else:
        raise ValueError("format must be duel | whowins | result | showcase")

    recipe = {"job": job, "format": fmt, "fps": 60, "builds": _BUILDS, "shots": shots, "overlays": overlays, "sfx": sfx, "end": end,
              "music": opts.get("music"), "length": round(t + end["hold"], 2)}
    json.dump(recipe, open(os.path.join(d, "recipe.json"), "w"), indent=1)
    print(json.dumps({"recipe": os.path.join(d, "recipe.json"), "shots": len(shots), "length": recipe["length"]}))


class Edit:
    """Accumulates shots / overlays / sounds on the output timeline."""
    def __init__(self): self.shots, self.overlays, self.sfx, self.t = [], [], [], 0.0
    def add(self, src, a, b, speed=1.0, label="", whoosh=True):
        self.shots.append({"src": src, "in": round(a, 3), "out": round(b, 3), "speed": speed, "label": label})
        start = self.t; self.t += (b - a) / speed
        if whoosh and len(self.shots) > 1: self.sfx.append({"t": round(start, 3), "name": "whoosh", "vol": 0.45})
        return start
    def ov(self, spec, a, b): self.overlays.append({"spec": spec, "from": round(a, 3), "to": round(b, 3)})
    def save(self, d, job, fmt, end, extra=None):
        r = {"job": job, "format": fmt, "fps": 60, "builds": _BUILDS, "shots": self.shots, "overlays": self.overlays, "sfx": self.sfx,
             "end": end, "length": round(self.t + end.get("hold", 0), 2)}
        r.update(extra or {})
        json.dump(r, open(os.path.join(d, "recipe.json"), "w"), indent=1)
        print(json.dumps({"recipe": os.path.join(d, "recipe.json"), "shots": len(self.shots), "length": r["length"]}))


STAGE_LABEL = {"QF1": "QUARTER-FINAL 1/4", "QF2": "QUARTER-FINAL 2/4", "QF3": "QUARTER-FINAL 3/4", "QF4": "QUARTER-FINAL 4/4",
               "SF1": "SEMI-FINAL 1/2", "SF2": "SEMI-FINAL 2/2", "F": "FINAL"}


def plan_pick(job, opts):
    """'Pick your ninja' tournament: the 8 at the start, every match (combo + KO)
    with the bracket always on screen, the champion at the end. Take 1 = the
    tournament (ShotRunner.tournament), take 2 = the bracket (ClipKit B.pickTake)."""
    d = jdir(job)
    srcT, logT, evT = load_take(d, opts.get("take", "1"))
    srcB, logB, evB = load_take(d, opts.get("bracket_take", "2"))
    video = os.path.join(d, srcT); cache = {}
    names = [ov_name(x) for x in logT["entrants"]]
    R = {k: ov_name(v) for k, v in logT["results"].items()}
    E = Edit()
    mark = {e["kind"]: e["v"] for e in evB}
    h0, h1 = mark["hook"], mark["hook_end"]
    s0 = E.add(srcB, h0, h0 + 1.8, 1.25, "hook-rush")
    E.add(srcB, h0 + 1.8, h1, 2.0, "hook-pan")
    E.ov({"type": "pickgrid", "names": names, "sub": opts.get("sub", "ONLY ONE WINS")}, s0, E.t)
    known = {}
    for key in ["QF1", "QF2", "QF3", "QF4", "SF1", "SF2", "F"]:
        m = next(e for e in evT if e["kind"] == "match" and e.get("key") == key)
        ko = next(e for e in evT if e["kind"] == "ko" and e.get("key") == key)
        hits = [e for e in evT if e["kind"] == "hit" and e.get("key") == key]
        start = E.t
        best = None
        for c in sorted(combos(hits), key=lambda c: -c["score"]):
            a, b = c["a"] - 0.3, min(c["b"] + 0.3, c["a"] + 1.3)
            if a < m["v"] or b > ko["v"] - 1.2: continue
            if smooth(video, a, b, cache): best = (a, b); break
        if best:
            sa = E.add(srcT, best[0], best[1], 1.0, key + "-combo")
            E.sfx += sfx_for(hits, best[0], best[1], sa, 1.0)
        kv = ko["v"]
        if key == "F":
            k1 = E.add(srcT, kv - 1.0, kv - 0.25, 1.0, key + "-ko")
            E.sfx += sfx_for(hits, kv - 1.0, kv - 0.25, k1, 1.0)
            k2 = E.add(srcT, kv - 0.25, kv + 0.45, 0.5, key + "-ko-slow", whoosh=False)
            E.sfx += sfx_for(hits, kv - 0.25, kv + 0.45, k2, 0.5)
            ko_t = k2 + 0.5
        else:
            k1 = E.add(srcT, kv - 1.0, kv + 0.5, 1.0, key + "-ko")
            E.sfx += sfx_for(hits, kv - 1.0, kv + 0.5, k1, 1.0)
            ko_t = k1 + 1.0
        E.sfx.append({"t": round(ko_t, 3), "name": "heavy", "vol": 0.9})
        E.ov({"type": "bracket2d", "names": names, "results": dict(known), "current": key, "stage": STAGE_LABEL[key]}, start, ko_t)
        known[key] = R[key]
        E.ov({"type": "bracket2d", "names": names, "results": dict(known), "current": key, "stage": STAGE_LABEL[key]}, ko_t, E.t)
        loser = ov_name(ko["a"]) if R[key] == ov_name(ko["b"]) else ov_name(ko["b"])
        if key != "F":
            E.ov({"type": "stamp", "lines": [loser, "ELIMINATED"], "color": "red"}, ko_t, E.t)
    c0 = E.add(srcB, mark["crown"], mark["crown_end"], 1.2, "crown")
    E.ov({"type": "bracket2d", "names": names, "results": dict(known), "current": "F", "stage": "CHAMPION"}, c0, E.t)
    E.ov({"type": "stamp", "lines": [R["F"], "IS THE CHAMPION"], "color": "gold", "y": 1580}, c0 + 0.6, E.t)
    end = {"hold": 2.6, "spec": {"type": "cta", "lines": ["DID YOUR", "PICK WIN?"], "ask": opts.get("ask", "COMMENT YOUR NUMBER")}}
    E.save(d, job, "pick", end, {"results": R, "entrants": names})


def plan_devlog(job, opts):
    """Devlog: the robot host talks (take 1, ClipKit B.devlogTake, voice from
    tts.py in voice.json/voice.wav), cut with b-roll from other jobs, word
    captions, end card."""
    d = jdir(job)
    vj = json.load(open(os.path.join(d, "voice.json")))
    srcR = vo = None
    if any(L.get("show", "robot") == "robot" for L in vj["lines"]):
        srcR, logR, evR = load_take(d, opts.get("take", "1"))
        vo = next(e["v"] for e in evR if e["kind"] == "voice")
    E = Edit()
    lines = vj["lines"]
    for i, L in enumerate(lines):
        a = 0.0 if i == 0 else L["start"]
        b = lines[i + 1]["start"] if i + 1 < len(lines) else vj["dur"] + 0.3
        show = L.get("show", "robot")
        if show == "robot":
            E.add(srcR, vo + a, vo + b, 1.0, "robot", whoosh=False)
        else:
            # b-roll: one or more clips ("broll:a.mp4|b.mp4") filling the line
            files = show.split(":", 1)[1].split("|")
            durs = [dur(f if os.path.isabs(f) else os.path.join(ROOT, f)) for f in files]
            seg = b - a; total = sum(durs)
            speed = 1.0 if total >= seg else max(0.6, total / seg)
            left = seg
            for f, cd in zip(files, durs):
                if left <= 0.05: break
                use = min(cd, left * speed)
                E.add(f, 0.0, use, speed, "broll", whoosh=False)
                left -= use / speed
        # word captions, 3 words a chunk, the spoken word in gold
        ws = L.get("words", [])
        for j in range(0, len(ws), 3):
            chunk = ws[j:j + 3]
            for k, w in enumerate(chunk):
                wa = w["a"]; wb = chunk[k + 1]["a"] if k + 1 < len(chunk) else (ws[j + 3]["a"] if j + 3 < len(ws) else L["end"])
                E.ov({"type": "words", "words": [x["w"].upper() for x in chunk], "hi": k, "y": 1450}, wa, wb)
    E.ov({"type": "title", "text": opts.get("title", vj.get("title") or "DEVLOG #1"), "size": 72, "y": 200}, 0, E.t)
    end = {"hold": 2.4, "spec": {"type": "cta", "lines": ["NINJA DUEL", "IS LIVE!"], "ask": opts.get("ask", "FOLLOW FOR DAY 2")}}
    E.save(d, job, "devlog", end, {"voice": {"file": "voice.wav", "at": 0.0}})


def ov_name(fid):
    return CFG["names"].get(fid, (fid or "?").upper())


# ---------------------------------------------------------------- kit (CapCut prep only)
def cut(src, a, b, speed, out):
    sh(["ffmpeg", "-v", "error", "-y", "-ss", f"{a:.3f}", "-to", f"{b:.3f}", "-i", src, "-vf",
        f"setpts=(PTS-STARTPTS)/{speed},fps=60,setsar=1", "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "16",
        "-pix_fmt", "yuv420p", out])
    return out


def srcpath(d, src):
    if os.path.isabs(src): return src
    p = os.path.join(d, src)
    return p if os.path.exists(p) else os.path.join(ROOT, src)


def safe(s):
    return "".join(ch if ch.isalnum() else "_" for ch in (s or "").lower()).strip("_")[:24] or "plan"


def fmt_t(x):
    return f"{x:6.2f}s"


def kit(job):
    """Prepare the CapCut kit. NO edited video comes out of here: the edit is
    done by hand in CapCut, with these pieces.

    out/capcut/
        clips/cNN_<label>.mp4   real extracts from the recordings, at speed 1 (speed to apply in CapCut)
        overlays/oNN_<type>.png transparent 1080x1920 overlays
        audio/sfx_bed.wav       the game's own sounds at their frames, to drop at 0 s
        audio/voice.wav         the synthetic voice (devlog), if there is one
        audio/sons/             the game sounds one by one, to place by hand if needed
        timeline.txt            the edit sheet: track, file, start -> end, speed, what to do
        kit.json                the same thing for the machine
        planche.png             one frame per clip, to check the content at a glance
        qc_clips.json           freezes found clip by clip (stutters in the recording)
    """
    d = jdir(job); o = os.path.join(d, "out"); cc = os.path.join(o, "capcut")
    for f in ("final.mp4", "base.mp4", "concat.txt", "qc.json", "final_sheet.png", "last.png"):
        p = os.path.join(o, f)
        if os.path.exists(p): os.remove(p)
    shutil.rmtree(cc, ignore_errors=True)
    for sub in ("clips", "overlays", "audio/sons"): os.makedirs(os.path.join(cc, sub))
    r = json.load(open(os.path.join(d, "recipe.json")))
    for b in r.get("builds") or [None]:
        check_build({"build": b} if b else {}, "recipe.json")

    # 1. real extracts, cut at speed 1
    clips, t = [], 0.0
    for i, s in enumerate(r["shots"]):
        sp = s.get("speed", 1.0)
        name = f"c{i+1:02d}_{safe(s.get('label'))}.mp4"
        clips.append({"file": "clips/" + name, "src": s["src"], "in": s["in"], "out": s["out"], "speed": sp,
                      "start": round(t, 3), "end": round(t + (s["out"] - s["in"]) / sp, 3), "label": s.get("label", "")})
        t = clips[-1]["end"]
    with ThreadPoolExecutor(4) as ex:
        list(ex.map(lambda c: cut(srcpath(d, c["src"]), c["in"], c["out"], 1.0, os.path.join(cc, c["file"])), clips))
    shots_end = t
    hold = r.get("end", {}).get("hold", 0)
    total = shots_end + hold

    # 2. overlays
    ovs = list(r["overlays"])
    if hold and r["end"].get("spec"):
        ovs.append({"spec": r["end"]["spec"], "from": shots_end + 0.25, "to": total, "end_card": True})
    overlays = []
    for i, x in enumerate(ovs):
        name = f"o{i+1:02d}_{x['spec']['type']}.png"
        p = x.get("png") or ov.render(x["spec"], os.path.join(cc, "overlays", name))
        overlays.append({"file": "overlays/" + os.path.basename(p), "start": round(x["from"], 3), "end": round(min(x["to"], total), 3),
                         "type": x["spec"]["type"], "text": " / ".join(map(str, x["spec"].get("lines") or [x["spec"].get("text", "")]))})

    # 3. sounds: the bed (one file at 0 s) + the sounds one by one
    build_bed(r["sfx"], total, os.path.join(cc, "audio", "sfx_bed.wav"))
    for e in {e["name"] for e in r["sfx"]}:
        p = os.path.join(HERE, "sfx", e + ".wav")
        if os.path.exists(p): shutil.copy(p, os.path.join(cc, "audio", "sons", e + ".wav"))
    voice = None
    if r.get("voice"):
        shutil.copy(os.path.join(d, r["voice"]["file"]), os.path.join(cc, "audio", "voice.wav"))
        voice = {"file": "audio/voice.wav", "start": r["voice"].get("at", 0.0)}

    # 4. per-clip check: stutters in the recording
    qcs = {}
    for c in clips:
        g = freeze_gaps(os.path.join(cc, c["file"]), limit=0.15)
        if g: qcs[c["file"]] = g
    json.dump(qcs, open(os.path.join(cc, "qc_clips.json"), "w"), indent=1)

    # 5. one frame per clip
    planche(cc, clips)

    # 6. the edit sheet
    music = r.get("music") or {}
    k = {"job": job, "format": r.get("format"), "length": round(total, 2), "clips": clips, "overlays": overlays,
         "sfx": r["sfx"], "voice": voice, "end_hold": hold, "music": music}
    json.dump(k, open(os.path.join(cc, "kit.json"), "w"), indent=1)
    L = [f"KIT CAPCUT — {job} ({r.get('format')}) — durée totale {total:.2f} s",
         "Projet CapCut : 9:16, 1080x1920, 60 i/s. Le montage se fait à la main ; ces temps sont le point de départ.", ""]
    L.append("PISTE PRINCIPALE (clips, bout à bout)")
    for c in clips:
        note = f"  vitesse {c['speed']:g}x dans CapCut" if c["speed"] != 1.0 else ""
        warn = "  ⚠ saccade dans l'enregistrement" if c["file"] in qcs else ""
        L.append(f"  {fmt_t(c['start'])} -> {fmt_t(c['end'])}  {c['file']:<32} {c['label']}{note}{warn}")
    if hold:
        L.append(f"  {fmt_t(shots_end)} -> {fmt_t(total)}  FIN : figer la dernière image du dernier clip ({hold:g} s), effet Flou")
    L += ["", "INCRUSTATIONS (pistes au-dessus)"]
    for x in overlays:
        L.append(f"  {fmt_t(x['start'])} -> {fmt_t(x['end'])}  {x['file']:<32} {x['text'][:40]}")
    L += ["", "AUDIO",
          f"  {fmt_t(0)} -> {fmt_t(total)}  audio/sfx_bed.wav  (les vrais sons du jeu, calés sur les coups)"]
    if voice:
        L.append(f"  {fmt_t(voice['start'])}           audio/voice.wav  (voix du robot)")
    L.append("  musique : CapCut > Son, filtre « Usage commercial », " +
             (f"{music.get('name')}, " if music.get("name") else "") + f"{music.get('vol_db', -10)} dB, fondu final 1,2 s")
    L += ["", "SONS UN PAR UN (si on préfère les placer à la main, fichiers dans audio/sons/)"]
    for e in r["sfx"]:
        L.append(f"  {fmt_t(e['t'])}  {e['name']}")
    if qcs:
        L += ["", "À VÉRIFIER : saccades trouvées (début dans le clip, durée)"]
        for f, g in qcs.items(): L.append(f"  {f}: {g}")
    open(os.path.join(cc, "timeline.txt"), "w").write("\n".join(L) + "\n")
    print(json.dumps({"kit": cc, "clips": len(clips), "overlays": len(overlays), "length": round(total, 2), "stutters": qcs}))


def planche(cc, clips, w=216, h=384, cols=6):
    from PIL import Image, ImageDraw, ImageFont
    font = ImageFont.truetype(os.path.join(HERE, "fonts", "LilitaOne-Regular.ttf"), 22)
    rows = (len(clips) + cols - 1) // cols
    img = Image.new("RGB", (cols * w, rows * h), (12, 12, 16))
    tmp = os.path.join(cc, "_f.png")
    for i, c in enumerate(clips):
        p = os.path.join(cc, c["file"])
        sh(["ffmpeg", "-v", "error", "-y", "-ss", f"{(c['out'] - c['in']) / 2:.3f}", "-i", p, "-frames:v", "1",
            "-vf", f"scale={w}:{h}", tmp])
        im = Image.open(tmp).convert("RGB")
        dr = ImageDraw.Draw(im)
        lab = os.path.basename(c["file"])[:-4]
        dr.rectangle([0, 0, w, 30], fill=(0, 0, 0))
        dr.text((6, 3), lab, font=font, fill=(255, 210, 60))
        img.paste(im, ((i % cols) * w, (i // cols) * h))
    if os.path.exists(tmp): os.remove(tmp)
    img.save(os.path.join(cc, "planche.png"))


def build_bed(events, total, out):
    lib = os.path.join(HERE, "sfx")
    vol = CFG["sfx_vol"]
    ins, fl = [], []
    events = [e for e in events if os.path.exists(os.path.join(lib, e["name"] + ".wav"))]
    if not events:
        sh(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{total:.3f}", out]); return
    for i, e in enumerate(events):
        ins += ["-i", os.path.join(lib, e["name"] + ".wav")]
        ms = int(max(0, e["t"]) * 1000)
        fl.append(f"[{i}:a]volume={e.get('vol', vol.get(e['name'], 0.8))},adelay={ms}|{ms}[a{i}]")
    mix = "".join(f"[a{i}]" for i in range(len(events)))
    fl.append(f"{mix}amix=inputs={len(events)}:normalize=0,apad=whole_dur={total:.3f},atrim=0:{total:.3f},alimiter=limit=0.95[o]")
    sh(["ffmpeg", "-v", "error", "-y"] + ins + ["-filter_complex", ";".join(fl), "-map", "[o]", "-ar", "48000", "-ac", "2", out])


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"ingest": ingest, "sheet": sheet, "plan": plan, "kit": kit, "qc": qc}[cmd](*args)
