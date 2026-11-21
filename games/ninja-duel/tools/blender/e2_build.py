#!/usr/bin/env python3
"""Build the re-authored clips of Naruto, Sasuke and Lee (étape 2), grade them against the
clips they replace, draw their contact sheets, and write them into the game.

    lune run tools/syphodev/clips_dump.luau work/clips.json        (the clips in the game now)
    python3 tools/blender/e2_build.py work/clips.json OUT_DIR [--write] [--only NAME,...]

OUT_DIR gets one sheet per clip (sheet_<name>.png: side, front, three-quarter at the key
times) and grades.json / grades.md (before -> after). --write puts the clips into
src/Client/AuthoredJutsu6.luau, the last layer AuthoredMotion lays over the others (a clip of
the same name wins), so the originals stay in their chunks and one line takes it all back.
A clip whose grade does not beat the one it replaces is NOT written.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import e2_strikes as E  # noqa: E402
import syph_author as SA  # noqa: E402

GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT_LUAU = os.path.join(GAME, "src", "Client", "AuthoredJutsu6.luau")

CLIPS = {
    "Leaf.Guard": lambda o: E.guard_loop("Leaf", o),
    "Lion.Guard": lambda o: E.guard_loop("Lion", o),
    "Legion.Guard": lambda o: E.guard_loop("Legion", o),
    "Leaf.Light1": E.leaf_light1,
    "Leaf.Light2": E.leaf_light2,
    "Leaf.Light3": E.leaf_light3,
    "Leaf.Heavy": E.leaf_heavy,
    "Leaf.LeafWhirlwind": E.leaf_whirlwind,
    "Leaf.LeafHurricane": E.leaf_hurricane,
    "Leaf.LeafRising": E.leaf_rising,
    "Leaf.LeafHeel": E.leaf_heel,
    "Leaf.AirFlip": E.leaf_airflip,
}
for _name in ("lion_light1", "lion_light2", "lion_light3", "lion_vaultkick", "lion_sweep", "lion_lionkick", "lion_airflip",
              "legion_light1", "legion_light3", "legion_heavy", "legion_airflip"):
    if hasattr(E, _name):
        kit, move = _name.split("_", 1)
        nice = {"lion": "Lion", "legion": "Legion", "leaf": "Leaf"}[kit]
        mv = {"light1": "Light1", "light2": "Light2", "light3": "Light3", "light5": "Light5", "vaultkick": "VaultKick",
              "sweep": "Sweep", "lionkick": "LionKick", "airflip": "AirFlip", "heavy": "Heavy", "launcher": "Launcher"}[move]
        CLIPS[nice + "." + mv] = getattr(E, _name)


ARMS = ("Right", "Left", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist")


def step_with_guard_arms(kit, old_step, old_guard):
    """A guard step (Guard.Step.F/B/L/R) keeps its legs, hips and head, and takes the arms of
    the kit's new guard (relative to the chest, so they read the same while it steps): the
    old steps all carried the shared boxer guard with the fists in the face."""
    guard, _ = SA.make_clip(E.guard_loop(kit, old_guard), old_guard)
    n, fps = old_step["frames"], old_step["fps"]
    out = {k: v for k, v in old_step.items() if k != "joints"}
    w = {k: (7 if k == "Root" else 4) for k in old_step["joints"]}
    J = {k: [v[i:i + w[k]] for i in range(0, len(v), w[k])] for k, v in old_step["joints"].items()}
    gn = guard["frames"]
    for a in ARMS:
        rows = []
        for i in range(n):
            gi = 0   # the guard's arms held (a loop of another length would not close)
            rows.append(list(guard["joints"][a][gi]))
        J[a] = rows
    out["joints"] = J
    out["meta"] = dict(old_step.get("meta") or {}, e2=1)
    return out


def main(clips_path, out_dir, write=False, only=None):
    old = json.load(open(clips_path))
    os.makedirs(out_dir, exist_ok=True)
    built, rows = {}, []
    for name, fn in CLIPS.items():
        if only and name not in only:
            continue
        before = old[name]
        spec = fn(before)
        clip, errs = SA.make_clip(spec, before)
        g_old = SA.grade(name, {**before, "joints": {k: [v[i:i + (7 if k == "Root" else 4)] for i in range(0, len(v), 7 if k == "Root" else 4)]
                                                        for k, v in before["joints"].items()}})
        g_new = SA.grade(name, clip)
        times = sorted({round(k["t"], 4) for k in spec["keys"]})
        SA.sheet(clip, os.path.join(out_dir, "sheet_%s.png" % name), "%s  %.1f -> %.1f" % (name, g_old["score"], g_new["score"]), times)
        rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "why": g_new["why"],
                     "blow": g_new["blow"], "ik": {str(k): {a: round(b, 3) for a, b in v.items()} for k, v in errs.items()}})
        print("%-22s %4.1f -> %4.1f  %s  %s" % (name, g_old["score"], g_new["score"], " ; ".join(g_new["why"])[:150],
                                            json.dumps(g_new["blow"]) if g_new["blow"] else ""))
        if g_new["score"] > g_old["score"]:
            built[name] = clip
    for kit in ("Legion", "Lion", "Leaf"):
        for d in ("F", "B", "L", "R"):
            name = "%s.Guard.Step.%s" % (kit, d)
            if name not in old or (only and name not in only):
                continue
            before = old[name]
            clip = step_with_guard_arms(kit, before, old[kit + ".Guard"])
            g_old = SA.grade(name, {**before, "joints": {k: [v[i:i + (7 if k == "Root" else 4)] for i in range(0, len(v), 7 if k == "Root" else 4)]
                                                            for k, v in before["joints"].items()}})
            g_new = SA.grade(name, clip)
            rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "why": g_new["why"]})
            print("%-22s %4.1f -> %4.1f  %s" % (name, g_old["score"], g_new["score"], " ; ".join(g_new["why"])[:150]))
            if g_new["score"] > g_old["score"]:
                built[name] = clip
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    if write:
        prev = {}
        if os.path.exists(OUT_LUAU) and only:
            prev = load_existing()
        prev.update(built)
        # two modules of at most ~180k characters (the size clips_to_luau.py keeps to)
        names = sorted(prev)
        chunks, cur, size = [], {}, 0
        for n in names:
            text = SA.to_luau({n: prev[n]}, "")
            if cur and size + len(text) > 170000:
                chunks.append(cur); cur, size = {}, 0
            cur[n] = prev[n]; size += len(text)
        chunks.append(cur)
        paths = [OUT_LUAU] + [OUT_LUAU.replace("AuthoredJutsu6", "AuthoredJutsu%d" % (6 + i)) for i in range(1, len(chunks))]
        for path, part in zip(paths, chunks):
            open(path, "w").write(SA.to_luau(part, "étape 2: Naruto, Sasuke and Lee re-authored, tools/blender/e2_strikes.py"))
        print("wrote %d clips -> %s" % (len(prev), ", ".join(os.path.basename(p) for p in paths)))
    return rows


def load_existing():
    """The clips already in AuthoredJutsu6 (when only some are rebuilt)."""
    import re
    text = "".join(open(p).read() for p in [OUT_LUAU] + [OUT_LUAU.replace("AuthoredJutsu6", "AuthoredJutsu%d" % i) for i in (7, 8, 9)]
                   if os.path.exists(p))
    out = {}
    for m in re.finditer(r'\["([^"]+)"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\},meta=\{([^}]*)\},joints=\{(.*?)\n\t\}\},', text, re.S):
        name, fps, frames, length, loop, mk, meta, body = m.groups()
        markers = {a: float(b) for a, b in (x.split("=") for x in mk.split(",") if x)}
        joints = {}
        for jm in re.finditer(r"(\w+)=\{([^}]*)\}", body):
            vals = [float(v) for v in jm.group(2).split(",")]
            w = 7 if jm.group(1) == "Root" else 4
            joints[jm.group(1)] = [vals[i:i + w] for i in range(0, len(vals), w)]
        out[name] = {"fps": int(fps), "frames": int(frames), "length": float(length), "loop": loop == "true",
                     "markers": markers, "meta": {"source": "syph_author", "e2": 1}, "joints": joints}
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    main(args[0], args[1], "--write" in sys.argv, only)
