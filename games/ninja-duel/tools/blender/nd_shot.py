"""Authoring on the control rig (nd_ctrl): poses, breakdowns, spacing, overlap,
then checks, export and films (DEC-028).

The method an animator uses, kept explicit:

  1. key poses (extremes) and breakdowns, each a full body pose: pose-to-pose,
     every key merges onto the previous one;
  2. spacing is chosen per key, not left to default interpolation:
       "ease"    slow in / slow out (flat tangents): extremes, holds, settles
       "pass"    passes through (auto-clamped): breakdowns
       "impact"  arrives at full speed and leaves slowly: the contact of a
                 blow, a foot strike, a landing (the previous key eases out,
                 so the action accelerates all the way into it)
       "launch"  leaves at full speed: a push-off, a release
       "linear", "hold" (constant until the next key)
  3. overlap: drag(bones, frames) shifts some channels later (head, free
     arm), so the body does not arrive everywhere at once;
  4. checks on the evaluated body: feet that slide while on the floor, the
     centre of mass against the base of support, extremity speeds (the
     spacing chart) and arcs (paths of the hips, hands and feet);
  5. export through nd_ctrl.retarget: the Motor6D rows the game plays.
"""
import bpy, json, math, os
from mathutils import Vector, Quaternion
import nd_anim, nd_ctrl
from nd_rig import PARTS

FPS = 60
# Exported at the authoring rate: a sprint cycle is 20 frames and a kick's
# contact 2 frames; at 30 fps the fastest arcs were cut into chords.
SAMPLE = 60
POSE_BONES = ["root", "cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L",
              "foot_ik.R", "foot_ik.L", "knee_pole.R", "knee_pole.L"]


def merge(a, b):
    return nd_anim.merge(a, b)


class Shot:
    def __init__(self, arm, name):
        self.arm, self.name = arm, name
        self.keys = []
        self.drags = []

    def key(self, frame, spec, spacing="ease"):
        self.keys.append((frame, spec, spacing))
        return self

    def drag(self, bones, frames):
        """Overlap: these control bones follow `frames` later (after the first key)."""
        self.drags.append((bones, frames))
        return self

    # ------------------------------------------------------------ build
    def build(self, markers=None, loop=False, meta=None):
        arm = self.arm
        act = nd_anim.new_action(arm, self.name)
        keys = sorted(self.keys, key=lambda k: k[0])
        full = {}
        last_q = {}
        spacing_at = {}
        for frame, spec, spacing in keys:
            full = merge(full, spec)
            spacing_at[frame] = spacing
            pose = nd_ctrl.pose_bones(arm, full)
            for bone in POSE_BONES:
                q, loc = pose[bone]
                pb = arm.pose.bones[bone]
                if q is not None:
                    prev = last_q.get(bone)
                    if prev is not None and prev.dot(q) < 0:
                        q = -q
                    last_q[bone] = q
                    pb.rotation_quaternion = q
                    pb.keyframe_insert("rotation_quaternion", frame=frame, group=bone)
                if loc is not None:
                    pb.location = loc
                    pb.keyframe_insert("location", frame=frame, group=bone)
        curves = nd_anim.fcurves(act)
        for bones, frames in self.drags:
            for fc in curves:
                if any('"%s"' % b in fc.data_path for b in bones):
                    pts = sorted(fc.keyframe_points, key=lambda k: k.co.x)
                    for kp in pts[1:]:
                        kp.co.x += frames
                        kp.handle_left.x += frames
                        kp.handle_right.x += frames
        for fc in curves:
            shape(fc, spacing_at, max(f for f, _, _ in keys), loop)
        act["nd_markers"] = markers or {}
        act["nd_loop"] = bool(loop)
        act["nd_meta"] = meta or {}
        act["nd_rig"] = "ctrl"
        act.frame_range = (keys[0][0], keys[-1][0])
        return act


def shape(fc, spacing_at, last_frame, loop):
    """Set interpolation and handles of one F-curve from the keys' spacing."""
    pts = sorted(fc.keyframe_points, key=lambda k: k.co.x)
    n = len(pts)
    for i, kp in enumerate(pts):
        # (a dragged channel keeps the spacing of the key it was shifted from)
        frame = min(spacing_at, key=lambda f: abs(f - kp.co.x))
        sp = spacing_at[frame]
        prev = pts[i - 1] if i > 0 else None
        nxt = pts[i + 1] if i + 1 < n else None
        gl = (kp.co.x - prev.co.x) if prev else 4.0
        gr = (nxt.co.x - kp.co.x) if nxt else 4.0
        kp.interpolation = "BEZIER"
        kp.handle_left_type = "FREE"
        kp.handle_right_type = "FREE"
        y = kp.co.y
        if sp == "hold":
            kp.interpolation = "CONSTANT"
        elif sp == "linear":
            kp.interpolation = "LINEAR"
        if sp in ("ease", "hold", "linear"):
            kp.handle_left = (kp.co.x - gl / 3, y)
            kp.handle_right = (kp.co.x + gr / 3, y)
        elif sp == "pass":
            if prev and nxt:
                slope = (nxt.co.y - prev.co.y) / max(nxt.co.x - prev.co.x, 1e-6)
                # (clamped: no overshoot past a neighbour that is an extreme)
                if (y - prev.co.y) * (nxt.co.y - y) <= 0:
                    slope = 0.0
            else:
                slope = 0.0
            kp.handle_left = (kp.co.x - gl / 3, y - slope * gl / 3)
            kp.handle_right = (kp.co.x + gr / 3, y + slope * gr / 3)
        elif sp == "impact":
            slope = (y - prev.co.y) / max(gl, 1e-6) if prev else 0.0
            # Arrives at speed: the left handle continues the approach (x1.6:
            # the motion is still accelerating), short so the curve stays fast.
            kp.handle_left = (kp.co.x - gl * .2, y - slope * 1.6 * gl * .2)
            kp.handle_right = (kp.co.x + gr / 3, y)
            if prev and prev.interpolation == "BEZIER":
                # ... and the key before eases out: slow start, fast finish.
                prev.handle_right = (prev.co.x + gl * .45, prev.co.y)
        elif sp == "launch":
            slope = (nxt.co.y - y) / max(gr, 1e-6) if nxt else 0.0
            kp.handle_left = (kp.co.x - gl / 3, y)
            kp.handle_right = (kp.co.x + gr * .2, y + slope * 1.6 * gr * .2)
    fc.update()


# ------------------------------------------------------------------ checks
VOLUME = {p: v[1][0] * v[1][1] * v[1][2] for p, v in PARTS.items() if p not in ("Eyes", "HairBack", "Hair", "Sash")}


def evaluate(arm, act):
    """Per frame (60 fps): COM, ankles, wrists, hips in Roblox world axes."""
    scene = bpy.context.scene
    nd_anim.use(arm, act)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    rows = []
    for f in range(start, end + 1):
        scene.frame_set(f)
        frames = nd_ctrl.part_frames(arm)
        total = sum(VOLUME.values())
        com = sum((frames[p].translation * v for p, v in VOLUME.items()), Vector()) / total
        row = {"f": f, "com": com.copy(), "hrp": frames["HRP"].translation.copy()}
        for side, n in (("R", "Right"), ("L", "Left")):
            row["foot" + side] = frames[n + "Foot"].copy()
            row["hand" + side] = frames[n + "Hand"].translation.copy()
        rows.append(row)
    return rows


def footprint(m):
    """Corners of a foot's sole on the floor (Roblox axes, x/z)."""
    pts = []
    for dx, dz in ((-.4, -.575), (.4, -.575), (.4, .575), (-.4, .575)):
        p = m @ Vector((dx, -.21, dz))
        pts.append((p.x, p.z))
    return pts


def _inside(pt, poly):
    """Point in convex polygon (any winding); distance outside if not."""
    import itertools
    hull = convex_hull(poly)
    if len(hull) < 3:
        return False, min(math.dist(pt, q) for q in hull) if hull else 9
    sign = None
    out = 0.0
    for a, b in zip(hull, hull[1:] + hull[:1]):
        cross = (b[0] - a[0]) * (pt[1] - a[1]) - (b[1] - a[1]) * (pt[0] - a[0])
        if cross < 0:
            edge = math.dist(a, b) or 1
            out = max(out, -cross / edge)
    return out == 0.0, out


def convex_hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def check(arm, act, airborne=None):
    """Foot skate, balance and spacing report for one clip.

    airborne: optional set of frames where the body is meant to be in the air
    (the floor test does not apply)."""
    rows = evaluate(arm, act)
    report = {"clip": act.name, "frames": len(rows), "skate_max": 0.0, "skate_total": 0.0, "skates": [],
              "off_balance": [], "contacts": {"R": [], "L": []}}
    prev = {}
    for i, r in enumerate(rows):
        support = []
        for side in ("R", "L"):
            m = r["foot" + side]
            sole = m.translation.y - .21
            on = sole < .06
            report["contacts"][side].append(1 if on else 0)
            if on:
                support += footprint(m)
                if side in prev and prev[side] is not None:
                    d = math.hypot(m.translation.x - prev[side].x, m.translation.z - prev[side].z)
                    if d > .012:
                        report["skate_total"] += d
                        report["skate_max"] = max(report["skate_max"], d)
                        report["skates"].append((r["f"], side, round(d, 3)))
                prev[side] = m.translation.copy()
            else:
                prev[side] = None
        # Balance: on the floor and not moving fast, the centre of mass sits
        # over the feet (dynamic phases may lean outside: a fall or a lunge).
        if support and 0 < i < len(rows) - 1:
            v = (rows[i + 1]["com"] - rows[i - 1]["com"]) * (FPS / 2)
            if math.hypot(v.x, v.z) < 1.5:
                ok, dist = _inside((r["com"].x, r["com"].z), support)
                if not ok and dist > .2:
                    report["off_balance"].append((r["f"], round(dist, 2)))
    speeds = {"handR": [], "handL": [], "footR": [], "footL": [], "com": []}
    for i in range(1, len(rows)):
        for k in ("handR", "handL"):
            speeds[k].append(round((rows[i][k] - rows[i - 1][k]).length * FPS, 2))
        for side in ("R", "L"):
            speeds["foot" + side].append(round((rows[i]["foot" + side].translation - rows[i - 1]["foot" + side].translation).length * FPS, 2))
        speeds["com"].append(round((rows[i]["com"] - rows[i - 1]["com"]).length * FPS, 2))
    report["speeds"] = speeds
    report["paths"] = {"com": [tuple(round(c, 3) for c in r["com"]) for r in rows],
                       "handR": [tuple(round(c, 3) for c in r["handR"]) for r in rows],
                       "handL": [tuple(round(c, 3) for c in r["handL"]) for r in rows],
                       "footR": [tuple(round(c, 3) for c in r["footR"].translation) for r in rows],
                       "footL": [tuple(round(c, 3) for c in r["footL"].translation) for r in rows]}
    report["skate_total"] = round(report["skate_total"], 3)
    return report


# ------------------------------------------------------------------ export
def export(arm, actions, path, in_place=True):
    """Motor6D rows at 30 fps (same format as nd_io.export). With in_place,
    the HumanoidRootPart follows the root bone (travel is the game's)."""
    scene = bpy.context.scene
    data = {}
    step = FPS // SAMPLE
    for act in actions:
        nd_anim.use(arm, act)
        start, end = int(act.frame_range[0]), int(act.frame_range[1])
        rows = {j: [] for j in nd_ctrl.MOTORS}
        f = start
        while True:
            scene.frame_set(f)
            T = nd_ctrl.retarget(arm)
            for j, m in T.items():
                q = m.to_quaternion().normalized()
                quat = [round(q.x, 4), round(q.y, 4), round(q.z, 4), round(q.w, 4)]
                if j == "Root":
                    t = m.translation
                    rows[j].append([round(t.x, 3), round(t.y, 3), round(t.z, 3)] + quat)
                else:
                    rows[j].append(quat)
            if f >= end:
                break
            f = min(end, f + step)
        # Markers are authored in SECONDS from the first key (contact: 11 / 60).
        markers = {k: round(v - start / FPS, 4) for k, v in dict(act.get("nd_markers", {})).items()}
        length = (end - start) / FPS
        for k, v in markers.items():
            if not (0 <= v <= length + 1e-3):
                raise ValueError("marker %s=%.4f outside %s (0..%.3f)" % (k, v, act.name, length))
        data[act.name] = {"fps": SAMPLE, "frames": len(rows["Root"]), "length": round((end - start) / FPS, 4),
                          "loop": bool(act.get("nd_loop", False)), "markers": markers, "meta": dict(act.get("nd_meta", {})),
                          "joints": rows}
    with open(path, "w") as fh:
        json.dump(data, fh, separators=(",", ":"))
    # A joint turning more than 115 deg in one sample is a flip (IK or
    # quaternion), not motion: report it.
    for name, c in data.items():
        for j, rows in c["joints"].items():
            for i in range(1, len(rows)):
                a, b = rows[i - 1][-4:], rows[i][-4:]
                dot = min(1.0, abs(sum(x * y for x, y in zip(a, b))))
                ang = math.degrees(2 * math.acos(dot))
                if ang > 115:
                    print("FLIP", name, j, i, round(ang))
                elif ang > 45 and ("Hip" in j or "Knee" in j or "Ankle" in j):
                    print("FAST", name, j, i, round(ang))
    return data


# ------------------------------------------------------------------- films
def stage(res=360, silhouette=False):
    import nd_preview
    cam = nd_preview.setup(res)
    shading = bpy.context.scene.display.shading
    if silhouette:
        # The silhouette test: flat dark body on a light ground, nothing else.
        shading.light = "FLAT"
        shading.color_type = "SINGLE"
        shading.single_color = (.06, .06, .08)
        shading.show_shadows = False
        shading.show_object_outline = False
        bpy.context.scene.world.color = (.93, .93, .9)
        for name in ("Checker",):
            ob = bpy.data.objects.get(name)
            if ob:
                ob.hide_render = True
    else:
        shading.light = "STUDIO"
        shading.color_type = "MATERIAL"
        shading.show_shadows = True
        shading.show_object_outline = True
        ob = bpy.data.objects.get("Checker")
        if ob:
            ob.hide_render = False
    return cam


VIEWS = {"front34": Vector((-7.8, 7.2, 1.4)), "side": Vector((11.5, .6, .9)), "back34": Vector((7, -7.5, 2.0)),
         "front": Vector((0, 11.5, .9)), "side_far": Vector((16, 1, 2.0))}


def film(arm, act, folder, view="side", every=2, follow=True):
    """Render the clip; the camera rides with the root bone (smoothed)."""
    scene = bpy.context.scene
    cam = bpy.data.objects["PreviewCam"]
    nd_anim.use(arm, act)
    os.makedirs(folder, exist_ok=True)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    paths = []
    last = end - (every if act.get("nd_loop") else 0)
    anchor = None
    f, i = start, 0
    while f <= max(start, last):
        scene.frame_set(f)
        root = arm.matrix_world @ arm.pose.bones["root"].matrix.translation
        target = Vector((root.x, root.y, 2.7)) if follow else Vector((0, 0, 2.7))
        anchor = target
        cam.location = anchor + VIEWS[view]
        cam.rotation_euler = (anchor - cam.location).to_track_quat("-Z", "Y").to_euler()
        path = os.path.join(folder, "%s_%s_%03d.png" % (act.name, view, i))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
        f += every
        i += 1
    return paths


# ------------------------------------------------------------- cycles
def mirror(spec):
    """The same pose seen in a mirror: left and right swapped (x, yaw, roll,
    out-of-plane twists negated). Arm/leg controls are already side-relative."""
    out = {}
    for part, v in spec.items():
        if not isinstance(v, dict):
            out[part] = v
            continue
        v = dict(v)
        name = {"ra": "la", "la": "ra", "rf": "lf", "lf": "rf", "rl": "ll", "ll": "rl"}.get(part, part)
        if part in ("root", "torso", "head", "travel"):
            for k in ("x", "yaw", "roll"):
                if k in v:
                    v[k] = -v[k]
        if part in ("rf", "lf"):
            for k in ("x", "yaw"):
                if k in v:
                    v[k] = -v[k]
        out[name] = v
    return out


def cycle(arm, name, stride, frames, keys, plant, direction=(0.0, -1.0), mirror_half=True, base=None):
    """A locomotion cycle authored pose-to-pose, as an animator blocks it.

    keys: [(u, spec, spacing)]. With mirror_half, only the first half
      (u in [0, .5)) is given and the second half is its mirror (a forward or
      backward run); otherwise the whole cycle is given (a sideways run is not
      symmetric). Feet in the specs are in BODY space (relative to the
      HumanoidRootPart at that instant); the root travels `stride` studs along
      `direction` (x right, z back) over the cycle.
    plant: {"R": (u0, u1)} (and "L" for a whole cycle): a planted foot is not
      keyed by hand: its world spot is where it was at u0 and it is held
      there exactly until u1 (it cannot slide).
    """
    shot = Shot(arm, name)
    base = base or {}
    dx, dz = direction

    def travel(u):
        return stride * dx * u, stride * dz * u

    full = []
    for u, spec, spacing in keys:
        full.append((u, merge(base, spec), spacing))
    plants = dict(plant)
    if mirror_half:
        for u, spec, spacing in keys:
            full.append((u + .5, mirror(merge(base, spec)), spacing))
        if "R" in plants and "L" not in plants:
            plants["L"] = (plants["R"][0] + .5, plants["R"][1] + .5)
    full.sort(key=lambda k: k[0])
    full.append((1.0, full[0][1], full[0][2]))
    # Body-space pose of each foot at the start of its plant.
    spots = {}
    for side, (u0, u1) in plants.items():
        foot = "rf" if side == "R" else "lf"
        at = min(full, key=lambda k: abs(k[0] - u0))
        f = dict(at[1].get(foot, {}))
        tx, tz = travel(u0)
        spots[side] = dict(f, x=f.get("x", 0) + tx, z=f.get("z", 0) + tz, y=0)

    def planted(side, u):
        u0, u1 = plants[side]
        for k in (0, -1, 1):
            if u0 + k - 1e-6 <= u <= u1 + k + 1e-6:
                return k
        return None

    for u, spec, spacing in full:
        spec = merge(spec, {"travel": {"x": travel(u)[0], "z": travel(u)[1], "yaw": 0}})
        for side, foot in (("R", "rf"), ("L", "lf")):
            k = planted(side, u) if side in plants else None
            if k is not None:
                f = dict(spots[side])
                f["x"] += stride * dx * k
                f["z"] += stride * dz * k
            else:
                f = dict(spec.get(foot, {}))
                tx, tz = travel(u)
                f["x"] = f.get("x", 0) + tx
                f["z"] = f.get("z", 0) + tz
            spec[foot] = f
        shot.key(int(round(u * frames)), spec, spacing)
    return shot
