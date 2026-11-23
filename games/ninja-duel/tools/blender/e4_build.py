#!/usr/bin/env python3
"""Build the re-authored clips of Neji, Gaara, Kakashi, Itachi and Minato (étape 4), grade them
against the clips they replace, draw their contact sheets, and write them into the game.

    lune run tools/syphodev/clips_dump.luau work/clips.json
    python3 tools/blender/e4_build.py work/clips.json OUT_DIR [--write] [--only=NAME,...]

Same contract as e2_build: a clip whose grade does not beat the one it replaces is NOT
written; the clips go into src/Client/AuthoredJutsu15.. (the last layer, listed in
AuthoredJutsu.luau), so the originals stay and one line takes it all back. The guard steps
(Guard.Step.F/B/L/R) keep their legs and take the arms of the kit's new guard.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import e4_strikes as E4  # noqa: E402
import e2_build as B2  # noqa: E402
import syph_author as SA  # noqa: E402

GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
FIRST = 15
OUT = os.path.join(GAME, "src", "Client", "AuthoredJutsu%d.luau")
KITS = ("GentleFist", "Sand", "Copycat", "Mirage", "Flashstep")
# Written even a shade under the old grade: Neji's new Juken guard (9.8 against 10.0) is the
# pose his new palms start from and return to; keeping the old one would make every palm pop.
FORCE = {"GentleFist.Guard"}


def flat_to_rows(clip):
    return {**clip, "joints": {k: [v[i:i + (7 if k == "Root" else 4)] for i in range(0, len(v), 7 if k == "Root" else 4)]
                               for k, v in clip["joints"].items()}}


def step_with_guard_arms(kit, old_step, old_guard):
    guard, _ = SA.make_clip(E4.guard_loop4(kit, old_guard), old_guard)
    out = {k: v for k, v in old_step.items() if k != "joints"}
    w = {k: (7 if k == "Root" else 4) for k in old_step["joints"]}
    J = {k: [v[i:i + w[k]] for i in range(0, len(v), w[k])] for k, v in old_step["joints"].items()}
    for a in B2.ARMS:
        J[a] = [list(guard["joints"][a][0]) for _ in range(old_step["frames"])]
    out["joints"] = J
    out["meta"] = dict(old_step.get("meta") or {}, e4=1)
    return out


def main(clips_path, out_dir, write=False, only=None):
    old = json.load(open(clips_path))
    os.makedirs(out_dir, exist_ok=True)
    built, rows = {}, []
    for name, fn in E4.CLIPS.items():
        if (only and name not in only) or name not in old:
            continue
        before = old[name]
        spec = fn(before)
        clip, errs = SA.make_clip(spec, before)
        g_old = SA.grade(name, flat_to_rows(before))
        g_new = SA.grade(name, clip)
        times = sorted({round(k["t"], 4) for k in spec["keys"]})
        SA.sheet(clip, os.path.join(out_dir, "sheet_%s.png" % name), "%s  %.1f -> %.1f" % (name, g_old["score"], g_new["score"]), times)
        rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "why": g_new["why"]})
        print("%-28s %4.1f -> %4.1f  %s" % (name, g_old["score"], g_new["score"], " ; ".join(g_new["why"])[:140]), flush=True)
        if g_new["score"] > g_old["score"] or (name in FORCE and g_new["score"] >= g_old["score"] - .3):
            built[name] = clip
    for kit in KITS:
        for d in ("F", "B", "L", "R"):
            name = "%s.Guard.Step.%s" % (kit, d)
            if name not in old or (only and name not in only) or (kit + ".Guard") not in built:
                continue
            clip = step_with_guard_arms(kit, old[name], old[kit + ".Guard"])
            g_old = SA.grade(name, flat_to_rows(old[name]))
            g_new = SA.grade(name, clip)
            rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "why": g_new["why"]})
            print("%-28s %4.1f -> %4.1f" % (name, g_old["score"], g_new["score"]), flush=True)
            if g_new["score"] >= g_old["score"] - (.3 if kit + ".Guard" in FORCE else 0):
                built[name] = clip
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    if write:
        names = sorted(built)
        chunks, cur, size = [], {}, 0
        for n in names:
            text = SA.to_luau({n: built[n]}, "")
            if cur and size + len(text) > 170000:
                chunks.append(cur); cur, size = {}, 0
            cur[n] = built[n]; size += len(text)
        chunks.append(cur)
        for i, part in enumerate(chunks):
            open(OUT % (FIRST + i), "w").write(SA.to_luau(part, "étape 4: Neji, Gaara, Kakashi, Itachi, Minato re-authored, tools/blender/e4_strikes.py"))
        print("wrote %d clips -> AuthoredJutsu%d..%d" % (len(built), FIRST, FIRST + len(chunks) - 1))
    return rows


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    main(args[0], args[1], "--write" in sys.argv, only)
