"""Locomotion of the 8 prodigies from Mixamo captures + their own carriage
(nd_style). Runs in a plain bpy (pip wheel) or a Blender background process:
  python job_mocap_loco.py -- <folder of mixamo_*.fbx> <out folder>
Writes clips_<Fighter>_mocap.json (tools/blender/clips_to_luau.py input) and
stick sheets (<out>/sticks/<clip>.png) for a headless check."""
import bpy, sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nd_rig, nd_anim, nd_mocap, nd_style, nd_io, nd_sticks

SRC, OUT = sys.argv[-2], sys.argv[-1]
FIGHTERS = ["Lion", "Legion", "Sand", "Leaf", "GentleFist", "Mirage", "Copycat", "Flashstep"]
ONLY = [f for f in os.environ.get("ND_ONLY", "").split(",") if f]
# clip -> (capture, kind, loop, axis of the stride)
CYCLES = {
    "Walk.F": ("walk", "Walk", "z"), "Walk.B": ("walk_back", "Walk", "z"),
    "Walk.L": ("strafe_walk_L", "Walk", "x"), "Walk.R": ("strafe_walk_R", "Walk", "x"),
    "Run.F": ("run", "Run", "z"), "Run.B": ("run_back", "Run", "z"),
    "Run.L": ("strafe_run_L", "Run", "x"), "Run.R": ("strafe_run_R", "Run", "x"),
    "Sprint": ("sprint", "Sprint", "z"),
}
os.makedirs(os.path.join(OUT, "sticks"), exist_ok=True)
cache = {}


def capture(key):
    """The raw track of a capture (cached; None when not downloaded)."""
    if key in cache:
        return cache[key]
    path = os.path.join(SRC, "mixamo_%s.fbx" % key)
    if not os.path.exists(path):
        cache[key] = None
        return None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    src, start, end, _ = nd_mocap.import_fbx(path)
    cache[key] = nd_mocap.track(src, start, end, "inplace")
    return cache[key]


def tracks():
    """(clip suffix, kind, track, loop, meta) for every clip a capture can make."""
    out = []
    idle = capture("fight_idle")
    if idle:
        out.append(("Idle", "Idle", nd_style.trim_loop(nd_style.copy(idle)), True, {}))
    for clip, (key, kind, axis) in CYCLES.items():
        t = capture(key)
        if not t:
            continue
        stride = abs(t["travel"][1] if axis == "z" else t["travel"][0])
        out.append((clip, kind, nd_style.trim_loop(nd_style.copy(t)), True, {"stride": round(max(stride, .5), 3)}))
    # (Jump.Air stays key-posed: the captured big jump is a dive into a roll,
    # its body goes flat; checked on the 8, 03/11)
    for clip, key, kind in (("Jump.Leap", "jump_run_forward", "Leap"), ("Flip", "front_flip", "Flip")):
        t = capture(key)
        if not t:
            continue
        t = nd_style.copy(t)
        span = nd_style.airborne(t)
        if span:
            nd_style.window(t, *span)
        nd_style.still_root(t, keep_rotation=(kind != "Flip"))
        out.append((clip, kind, t, False, {}))
    land = capture("land")
    if land:
        # the capture falls in from above: the clip starts at touch-down (the
        # hips back at standing height), takes the crouch and the recovery
        t = nd_style.copy(land)
        ys = [v.y for v in t["loc"]]
        stand = ys[-1]
        first = next((i for i, y in enumerate(ys) if y <= stand + .15), 0)
        nd_style.window(t, first, min(len(ys) - 1, first + 36))
        t["loc"] = [v - nd_mocap.Vector((0, stand, 0)) for v in t["loc"]]
        nd_style.retime(t, 2.6)     # a ninja's landing: absorbed and gone in ~0.45 s
        out.append(("Land", "Land", t, False, {}))
    return out


raw = tracks()
# The key-posed idle each fighter's strikes start from (the earlier exports):
# the captured idle keeps its upper body breathing but stands on the same
# feet, so the first frame of a blow does not snap the legs (Naruto.spec).
OLD = {}
old_dir = os.environ.get("ND_OLD", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/out")
if os.path.isdir(old_dir):
    import glob
    for path in sorted(glob.glob(os.path.join(old_dir, "clips_*.json"))):
        if "_mocap" in path:
            continue
        try:
            d = json.load(open(path))
        except Exception:
            continue
        for name, clip in d.items():
            if name.endswith(".Idle"):
                OLD[name.split(".")[0]] = clip["joints"]
LEGS = ("RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle")


def stand_like_before(fighter, t):
    joints = OLD.get(fighter)
    if not joints:
        return t
    held = {}
    for j in LEGS + ("Root",):
        row = joints[j][0][3:] if j == "Root" else joints[j][0]
        held[j] = nd_mocap.Quaternion((row[3], row[0], row[1], row[2]))
    nd_style.pose(t, held, .8)
    base_y = joints["Root"][0][1]
    t["loc"] = [nd_mocap.Vector((0, v.y * .3 + base_y * .7, 0)) for v in t["loc"]]
    return t
for fighter in FIGHTERS:
    if ONLY and fighter not in ONLY:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(fighter, fighter if fighter in nd_rig.FIGHTERS else "Lion")
    acts = []
    for clip, kind, t, loop, meta in raw:
        styled = nd_style.style(fighter, kind, nd_style.copy(t))
        if kind == "Idle":
            stand_like_before(fighter, styled)
        act = nd_mocap.bake(arm, styled, "%s.%s" % (fighter, clip), loop, meta)
        acts.append(act)
        nd_sticks.sheet(arm, act, os.path.join(OUT, "sticks", act.name + ".png"), count=8)
    data = nd_io.export(arm, acts, os.path.join(OUT, "clips_%s_mocap.json" % fighter))
    print("OK", fighter, {k: v["frames"] for k, v in data.items()})
