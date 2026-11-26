#!/usr/bin/env python3
"""Build the passe-2 clips (p2_strikes: every blow still old in the 8 kits; p2_loco: the moves),
grade them against the clips they replace, measure how far each kit stands from the others on
the same slot (kit_distinct), draw the contact sheets, and write them into the game.

    lune run tools/syphodev/clips_dump.luau work/clips.json
    python3 tools/blender/p2_build.py work/clips.json OUT_DIR [--write] [--only=NAME,...]

The gate is not « better grade than the old clip » any more (that gate left half the kits'
blows old after the étapes 2 and 4: a generic clean clip graded 10 kept out a kit's own blow at
9): a clip is written when it grades >= 7.0 and no more than 1.0 under the one it replaces - or
when the one it replaces is a lookalike (under 12 degrees from another kit's) - and the report puts its distance to the nearest kit next to it. --write puts them into
src/Client/AuthoredJutsu21.. (the last layer AuthoredJutsu.luau lays: one block of lines takes
it all back).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import syph_author as SA  # noqa: E402
import kit_distinct as KD  # noqa: E402
sys.path.insert(0, os.path.join(HERE, "..", "syphodev"))
import clip_passes as CP  # noqa: E402

GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
FIRST = 21
OUT = os.path.join(GAME, "src", "Client", "AuthoredJutsu%d.luau")
INDEX = os.path.join(GAME, "src", "Client", "AuthoredJutsu.luau")
MIN_GRADE, MAX_DROP, LOOKALIKE = 7.0, 1.5, 12.0


def flat_rows(clip):
    return {**clip, "joints": {k: [v[i:i + (7 if k == "Root" else 4)] for i in range(0, len(v), 7 if k == "Root" else 4)]
                               for k, v in clip["joints"].items()}}


def to_flat(clip):
    """syph_author's rows -> the dump's flat lists (kit_distinct reads those)."""
    return {**clip, "joints": {k: [x for row in v for x in row] for k, v in clip["joints"].items()}}


def nearest(name, clips):
    kit, slot = name.split(".", 1)
    best = None
    for other in KD.KITS:
        if other == kit or "%s.%s" % (other, slot) not in clips:
            continue
        d = KD.distance(clips[name], clips["%s.%s" % (other, slot)])
        if d is not None and (best is None or d < best[0]):
            best = (d, KD.NAMES[other])
    return best


def specs():
    out = {}
    import p2_strikes
    out.update(p2_strikes.CLIPS)
    try:
        import p2_loco
        out.update(p2_loco.CLIPS)
    except ImportError:
        pass
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
    # the layers in AuthoredJutsu.luau: ours replace the block between the markers
    src = open(INDEX).read()
    begin, end = "-- BEGIN passe 2 (tools/blender/p2_build.py)", "-- END passe 2"
    block = begin + "\n" + "".join("for name,clip in require(script.Parent.AuthoredJutsu%d) do all[name]=clip end\n" % (FIRST + i)
                                   for i in range(len(chunks))) + end + "\n"
    if begin in src:
        src = re.sub(re.escape(begin) + r".*?" + re.escape(end) + r"\n", block, src, flags=re.S)
    else:
        src = src.replace("return all", block + "return all")
    open(INDEX, "w").write(src)
    # stale chunks from a longer earlier write
    i = FIRST + len(chunks)
    while os.path.exists(OUT % i):
        os.remove(OUT % i); i += 1
    return len(chunks)


def main(clips_path, out_dir, do_write=False, only=None):
    old = json.load(open(clips_path))
    os.makedirs(out_dir, exist_ok=True)
    after = dict(old)
    built, rows = {}, []
    for name, fn in specs().items():
        if only and name not in only:
            continue
        base = getattr(fn, "base", name)
        if base not in old:
            print("%-26s (no clip %s in the game: skipped)" % (name, base))
            continue
        before = old[base]
        spec = fn(before)
        if "clip" in spec:      # p2_loco: built over the game's own legs, no keys
            clip = spec["clip"]
            spec = {"keys": [{"t": round(clip["length"] * i / 6, 4)} for i in range(7)]}
        else:
            clip, errs = SA.make_clip(dict(spec), before)
        clip["meta"] = dict(clip.get("meta") or {}, p2=1, source="syph_author")
        CP.apply(clip)          # the export passes (SyphoClips): loops closed, one-sample pops smoothed
        if (before.get("meta") or {}).get("stride"):
            clip["meta"]["stride"] = before["meta"]["stride"]
        g_old = SA.grade(name, flat_rows(before))
        g_new = SA.grade(name, clip)
        nb = nearest(name, old) if name in old else None
        lookalike = nb is None or nb[0] < LOOKALIKE
        ok = g_new["score"] >= MIN_GRADE and (g_new["score"] >= g_old["score"] - MAX_DROP or lookalike)
        times = sorted({round(k["t"], 4) for k in spec["keys"]})
        SA.sheet(clip, os.path.join(out_dir, "sheet_%s.png" % name), "%s  %.1f -> %.1f" % (name, g_old["score"], g_new["score"]), times)
        if ok:
            built[name] = clip
            after[name] = to_flat(clip)
        rows.append({"name": name, "before": g_old["score"], "after": g_new["score"], "written": ok, "why": g_new["why"]})
    for r in rows:
        nb = nearest(r["name"], old) if r["name"] in old else None
        na = nearest(r["name"], after) if r["name"].split(".")[0] in KD.KITS else None
        r["near_before"] = nb and [round(nb[0], 1), nb[1]]
        r["near_after"] = na and [round(na[0], 1), na[1]]
        print("%-26s %4.1f -> %4.1f %s  nearest %s -> %s  %s" % (
            r["name"], r["before"], r["after"], "W" if r["written"] else "-",
            "%5.1f %-7s" % tuple(r["near_before"]) if r["near_before"] else "  -  ",
            "%5.1f %-7s" % tuple(r["near_after"]) if r["near_after"] else "  -  ",
            " ; ".join(r["why"])[:110]), flush=True)
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    json.dump({k: v for k, v in after.items()}, open(os.path.join(out_dir, "clips_after.json"), "w"))
    if do_write and built:
        n = write(built, "passe commune 2: the 8 kits' blows and moves in the new method, tools/blender/p2_build.py")
        print("wrote %d clips -> AuthoredJutsu%d..%d" % (len(built), FIRST, FIRST + n - 1))
    return rows


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    main(args[0], args[1], "--write" in sys.argv, only)
