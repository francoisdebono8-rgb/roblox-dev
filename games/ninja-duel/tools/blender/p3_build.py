#!/usr/bin/env python3
"""Build the passe-3 clips (p3_kits: what the OUTILLEUR's kit bench showed), with p2_build's
gate and kit_distinct report, and write them into the game:

    lune run tools/syphodev/clips_dump.luau work/clips.json
    python3 tools/blender/p3_build.py work/clips.json OUT_DIR [--write] [--only=NAME,...]

Besides p3_kits.CLIPS, each kit's guard steps and skid (Guard.Step.F/B/L/R, Guard.Skid) keep
their legs and take the arms of its new guard (e2_build.step_with_guard_arms's rule), so the
cover holds while it moves. --write puts them into src/Client/AuthoredJutsu41.. (the last
layer AuthoredJutsu.luau lays, after passe 2's: one block of lines takes it all back).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import syph_author as SA  # noqa: E402
import p2_build as P2  # noqa: E402
import p3_kits as K  # noqa: E402

FIRST = 41
OUT = P2.OUT
INDEX = P2.INDEX
ARMS = ("Right", "Left", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist")
BEGIN, END = "-- BEGIN passe 3 (tools/blender/p3_build.py)", "-- END passe 3"


def with_arms(step, guard_clip):
    """The step's legs, hips and head; the guard's arms (its first frame, held)."""
    out = {k: v for k, v in step.items() if k != "joints"}
    J = P2.flat_rows(step)["joints"]
    for a in ARMS:
        J[a] = [list(guard_clip["joints"][a][0]) for _ in range(step["frames"])]
    out["joints"] = J
    out["meta"] = dict(step.get("meta") or {}, p3=1)
    return out


def write(built, header):
    names = sorted(built)
    chunks, cur, size = [], {}, 0
    for n in names:
        text = SA.to_luau({n: built[n]}, "")
        if cur and size + len(text) > 170000:
            chunks.append(cur); cur, size = {}, 0
        cur[n] = built[n]; size += len(text)
    chunks.append(cur)
    for i, part in enumerate(chunks):
        open(OUT % (FIRST + i), "w").write(SA.to_luau(part, header))
    src = open(INDEX).read()
    block = BEGIN + "\n" + "".join("for name,clip in require(script.Parent.AuthoredJutsu%d) do all[name]=clip end\n" % (FIRST + i)
                                   for i in range(len(chunks))) + END + "\n"
    if BEGIN in src:
        src = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n", block, src, flags=re.S)
    else:
        src = src.replace("return all", block + "return all")
    open(INDEX, "w").write(src)
    i = FIRST + len(chunks)
    while os.path.exists(OUT % i):
        os.remove(OUT % i); i += 1
    return len(chunks)


def main(clips_path, out_dir, do_write=False, only=None):
    P2.specs = lambda: dict(K.CLIPS)
    P2.FIRST = FIRST
    old = json.load(open(clips_path))
    rows = P2.main(clips_path, out_dir, False, only)
    after = json.load(open(os.path.join(out_dir, "clips_after.json")))
    built = {}
    for r in rows:
        if r["written"]:
            built[r["name"]] = P2.flat_rows(after[r["name"]])
    for kit in K.KITS:
        g = built.get(kit + ".Guard")
        if not g:
            continue
        for d in ("Step.F", "Step.B", "Step.L", "Step.R", "Skid"):
            name = "%s.Guard.%s" % (kit, d)
            if name not in old or (only and name not in only):
                continue
            clip = with_arms(old[name], g)
            g_old = SA.grade(name, P2.flat_rows(old[name]))
            g_new = SA.grade(name, clip)
            ok = g_new["score"] >= P2.MIN_GRADE and g_new["score"] >= g_old["score"] - P2.MAX_DROP
            print("%-26s %4.1f -> %4.1f %s  %s" % (name, g_old["score"], g_new["score"], "W" if ok else "-", " ; ".join(g_new["why"])[:110]))
            rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "written": ok, "why": g_new["why"]})
            if ok:
                built[name] = clip
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    if do_write and built:
        n = write(built, "passe commune 3: the kit bench's fixes (guards, dodges, Light1, Gaara), tools/blender/p3_build.py")
        print("wrote %d clips -> AuthoredJutsu%d..%d" % (len(built), FIRST, FIRST + n - 1))
    return rows


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    main(args[0], args[1], "--write" in sys.argv, only)
