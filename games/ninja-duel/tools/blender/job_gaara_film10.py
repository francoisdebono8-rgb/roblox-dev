"""(14/11, CM FILM10 F10-1) Gaara's folded arms.

What was drawn as "arms folded" (FOLD_R/L: raise 62, twist 44, elbow 122)
put both forearms upright and the fists against his mouth: in close-up he
looked like he was coughing. His reference (Chunin prelims vs Lee, ep. 48-50;
vs Naruto, ep. 75-79): standing still, the arms folded across the chest,
forearms level, the hands tucked under the upper arms - he does not move,
the sand does.

This job re-folds the arms (upper arms down along the ribs, twisted in, the
forearms across the lower chest) and re-authors what he does while still or
moving with them folded: Idle, the gait (Walk/Run/...), Guard (still folded:
the sand guards, not his arms) and the guard steps. Guard.Impact is new: when
a blow actually arrives, ONE hand comes up open toward it (the gesture that
sends the sand) and folds back - the raised guard is only that moment.

Output: AuthoredClips59-60 (merged last: they replace the older Sand clips of
the same names). Idle, Guard, the guard steps and Guard.Impact are these new
clips; the gait clips keep their committed legs and body (they pass the slide
checks: Locomotion.spec) and only take the folded arms (frame 0 of the new
Idle), so walking or running he keeps his arms folded.
Run: python3 job_gaara_film10.py <out.json>   (bpy in the container)
     python3 job_gaara_film10.py luau <out.json>   (writes the modules)"""
import bpy, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_ctrl, nd_shot, nd_anim, gaara_p7, clips_feel, clips_react2

FOLD_R = {"raise": 18, "out": -8, "twist": 95, "elbow": 95, "wrist": 0}
FOLD_L = {"raise": 22, "out": -8, "twist": 100, "elbow": 90, "wrist": 0}
# in place: STANCE, GUARD and AIR hold these very dicts
gaara_p7.FOLD_R.clear(); gaara_p7.FOLD_R.update(FOLD_R)
gaara_p7.FOLD_L.clear(); gaara_p7.FOLD_L.update(FOLD_L)
BLOCK = {"ra": gaara_p7.FOLD_R, "la": gaara_p7.FOLD_L}
# the hand that answers the blow: forward and up, palm open toward it
ANSWER = {"raise": 96, "out": -6, "twist": -12, "elbow": 34, "wrist": -26}

KEEP_FEEL = ("Guard.Step.F", "Guard.Step.B", "Guard.Step.L", "Guard.Step.R", "Guard.Skid")


def guard_impact(arm):
    s = gaara_p7.s
    sh = nd_shot.Shot(arm, "Sand.Guard.Impact")
    sh.key(0, s(), "ease")
    up = s({"ra": ANSWER, "head": {"pitch": 2, "yaw": -4}, "root": {"y": -.08}})
    sh.key(4, up, "impact")                      # the hand is there as the blow lands
    sh.key(10, s({"ra": nd_anim.merge(ANSWER, {"wrist": -10, "elbow": 40}), "root": {"y": -.1}}), "ease")
    sh.key(16, up, "ease")                        # held while the sand takes it
    sh.key(34, s(), "ease")                       # folds back
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 4 / 60})


def author(arm):
    acts = gaara_p7.locomotion(arm)
    acts.append(gaara_p7.idle(arm))
    react = clips_react2.author.__globals__["Body"]("Sand", gaara_p7.STANCE, 1.1, 1.0, BLOCK)
    acts += [a for a in clips_react2.guards(react, arm) if a.name == "Sand.Guard"]
    feel = clips_feel.Body("Sand", gaara_p7.STANCE, 1.1, 1.0, BLOCK)
    acts += [a for a in clips_feel.guard_steps(feel, arm) if any(a.name.endswith(k) for k in KEEP_FEEL)]
    acts.append(guard_impact(arm))
    return acts


KEEP_NEW = {"Sand.Idle", "Sand.Guard", "Sand.Guard.Impact", "Sand.Guard.Skid",
            "Sand.Guard.Step.B", "Sand.Guard.Step.F", "Sand.Guard.Step.L", "Sand.Guard.Step.R"}
ARMS = ["Right", "RightElbow", "RightWrist", "Left", "LeftElbow", "LeftWrist"]


def write_luau(json_path, client_dir, first=59):
    """New clips + the committed gait (AuthoredClips1..first-1) with folded arms."""
    import re, clips_to_luau as C
    new = json.load(open(json_path))
    for c in new.values():
        C.ankle_jitter(c); C.moving_holds(c); C.destep(c)
    fold = {j: new["Sand.Idle"]["joints"][j][0] for j in ARMS}
    old = {}
    for i in range(1, first):
        path = os.path.join(client_dir, "AuthoredClips%d.luau" % i)
        if not os.path.exists(path):
            continue
        src = open(path).read()
        for m in re.finditer(r'\t\["(Sand\.[^"]+)"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(true|false),markers=\{([^}]*)\},meta=\{([^}]*)\},joints=\{\n(.*?)\n\t\}\},', src, re.S):
            name = m.group(1)
            if name in KEEP_NEW or name in old:
                continue
            joints = {}
            for line in m.group(8).split("\n"):
                jm = re.match(r"\t\t(\w+)=\{([^}]*)\},", line)
                vals = [float(v) for v in jm.group(2).split(",")]
                w = 7 if jm.group(1) == "Root" else 4
                joints[jm.group(1)] = [vals[k:k + w] for k in range(0, len(vals), w)]
            kv = lambda t: {a: float(b) for a, b in (x.split("=") for x in t.split(",") if x)}
            old[name] = dict(fps=int(m.group(2)), frames=int(m.group(3)), length=float(m.group(4)), loop=m.group(5) == "true",
                             markers=kv(m.group(6)), meta=kv(m.group(7)), joints=joints)
    out = {n: new[n] for n in KEEP_NEW}
    for n in new:
        if n in KEEP_NEW or n not in old:
            continue
        c = old[n]
        for j in ARMS:
            if j in c["joints"]:
                c["joints"][j] = [list(fold[j]) for _ in c["joints"][j]]
        out[n] = c
    hdr = C.HEADER + ["-- (14/11, FILM10 F10-1) tools/blender/job_gaara_film10.py: Gaara's arms folded."]
    chunks, cur, size = [], [], 0
    for n in sorted(out):
        lines = C.clip_lines(n, out[n]); k = sum(len(x) + 1 for x in lines)
        if cur and size + k > C.CHUNK:
            chunks.append(cur); cur, size = [], 0
        cur += lines; size += k
    chunks.append(cur)
    for i, body in enumerate(chunks):
        open(os.path.join(client_dir, "AuthoredClips%d.luau" % (first + i)), "w").write("\n".join(hdr + ["return {"] + body + ["}"]) + "\n")
    print(len(out), "clips in", len(chunks), "modules")


if __name__ == "__main__" and sys.argv[1] == "luau":
    write_luau(sys.argv[2], os.path.join(HERE, "..", "..", "src", "Client"))
elif __name__ == "__main__":
    out = sys.argv[-1]
    S = bpy.context.scene
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build("Gaara", "Sand")
    acts = author(arm)
    for act in acts:
        rep = nd_shot.check(arm, act)
        print("CHECK %-24s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data = nd_shot.export(arm, acts, out)
    print("exported", len(data), sorted(data))
