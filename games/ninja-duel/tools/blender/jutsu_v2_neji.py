"""Neji's jutsu, pass v2 (06/11, user: « refais-les toutes avec les nouveaux
outils », « des animations fluides comme un film »). Docstring rewritten at the
end of the pass; see the per-jutsu functions."""
import bpy, math
from mathutils import Vector, Quaternion
import nd_anim, nd_ctrl, nd_rig, nd_mocap
from nd_shot import Shot, merge
import jutsu_neji
import jutsu_lee as J
from jutsu_lee import aim, reach, face, RF, LF, hip_at, shoulder_at, body_rot, chest_rot, wdir
from jutsu_sasuke import ZERO, SEAL

N = "GentleFist."
F = 60.0

# ------------------------------------------------------------------ the body
# His stance (neji_p9 / jutsu_neji): deep and side-on (hips 50 deg to his
# right), the lead (left) palm forward and low, the rear (right) palm high by
# the ear; the feet planted wide (rear foot turned out).
FEET = {"rf": RF(.88, .8, yaw=64), "lf": LF(-.64, -.8, yaw=26)}
BASE = merge(ZERO, merge(jutsu_neji.STANCE, FEET))
GUARD_L = dict(BASE["la"])
GUARD_R = dict(BASE["ra"])
PALM_T, PALM_W = -56, -62          # a palm heel forward, the fingers up
FING_T, FING_W = -12, 0            # two fingers straight


def look(elev=-4, yaw=0):
    """The head on him (the Byakugan sees round, the face still points)."""
    return lambda p: face(p, yaw, elev=elev)


def P(over=None, **limbs):
    """A whole-body pose from his stance; limbs are aimed from the pose's own
    hips and chest (jutsu_lee helpers, exact on the control rig)."""
    if "head" not in limbs:
        limbs["head"] = look()
    return J.pose(over or {}, base=BASE, **limbs)


def S():
    return P()


def body_pt(p, x, y, z):
    """A world point in the hips' frame (x right, y up, z back) from the hips' centre."""
    return J.centre(p) + body_rot(p) @ Vector((x, y, z))


def chest_pt(p, x, y, z):
    """A world point in the chest's frame from the base of the neck."""
    neck = J.centre(p) + body_rot(p) @ (Vector((0, .65, 0)) + nd_anim.ori(p.get("torso", {})) @ Vector((0, 1.4, 0)))
    return neck + chest_rot(p) @ Vector((x, y, z))


def head_pt(p, x, y, z):
    """A world point in the head's frame (from the neck pivot)."""
    neck = J.centre(p) + body_rot(p) @ (Vector((0, .65, 0)) + nd_anim.ori(p.get("torso", {})) @ Vector((0, 1.4, 0)))
    return neck + chest_rot(p) @ nd_anim.ori(p.get("head", {})) @ Vector((x, y, z))


def split(arm, prefix, keys, cut, rel_end, marker=None, drags=(), rel_markers=None):
    """One continuous act cut the way the game plays it (jutsu_sasuke.act,
    with the Release's end given exactly so each clip keeps its length):
    Release = keys 0..rel_end, Recover = keys from `cut` on (from its frame 0).
    Both clips meet on the same pose at `cut`."""
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    for need in (cut, rel_end):
        if need not in frames:
            raise ValueError("%s: no key on frame %d (%s)" % (prefix, need, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    re, rc = Shot(arm, prefix + ".Release"), Shot(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= rel_end:
            re.key(f, p, sp)
        if f == cut:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > cut:
            rc.key(f - cut, p, sp)
    for bones, n in drags:
        re.drag(bones, n)
        rc.drag(bones, n)
    m = rel_markers if rel_markers is not None else ({"release": marker / F} if marker is not None else None)
    return re.build(markers=m), rc.build()


# ------------------------------------------------------------ the captures
# A Mixamo capture (nd_mocap.track) brings what key poses lack: the small
# arcs, the overshoot and the settle of a real body between the extremes.
# layer() keeps every key pose exact on its frame and adds, between them,
# the capture's own deviation from a straight blend of ITS poses at the
# matching moments (time-warped piecewise onto our keys) - the residual:
# the hips' bob and the late swing of the chest and head of a real push or
# throw, on Neji's own poses.
MIX = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo/mixamo_%s.fbx"
_CAP = {}
CTRL = {"Root": "cog", "Waist": "spine", "Neck": "neck", "Right": "shoulder.R", "RightElbow": "forearm.R",
        "RightWrist": "hand.R", "Left": "shoulder.L", "LeftElbow": "forearm.L", "LeftWrist": "hand.L"}
SWAP = {"Right": "Left", "Left": "Right", "RightElbow": "LeftElbow", "LeftElbow": "RightElbow",
        "RightWrist": "LeftWrist", "LeftWrist": "RightWrist"}


def capture(key):
    if key not in _CAP:
        scene = bpy.context.scene
        fps, frame = scene.render.fps, scene.frame_current
        objs, acts = set(bpy.data.objects), set(bpy.data.actions)
        active = bpy.context.view_layer.objects.active
        src, s0, s1, _ = nd_mocap.import_fbx(MIX % key)
        tr = nd_mocap.track(src, s0, s1, "inplace")
        for o in set(bpy.data.objects) - objs:
            bpy.data.objects.remove(o, do_unlink=True)
        for a in set(bpy.data.actions) - acts:
            bpy.data.actions.remove(a)
        scene.render.fps = fps
        scene.frame_set(frame)
        if active and active.name in bpy.data.objects:
            bpy.context.view_layer.objects.active = active
        _CAP[key] = tr
    return _CAP[key]


def _cq(tr, joint, x, mirror):
    j = SWAP.get(joint, joint) if mirror else joint
    qs = tr["q"][j]
    x = min(max(x, 0.0), len(qs) - 1.0)
    a = int(math.floor(x))
    b = min(len(qs) - 1, a + 1)
    qa, qb = qs[a], qs[b]
    if qa.dot(qb) < 0:
        qb = -qb
    q = qa.slerp(qb, x - a)
    if mirror:   # reflected through the body's mid plane (Roblox x -> -x)
        q = Quaternion((q.w, q.x, -q.y, -q.z))
    return q


def _cy(tr, x):
    ls = tr["loc"]
    x = min(max(x, 0.0), len(ls) - 1.0)
    a = int(math.floor(x))
    b = min(len(ls) - 1, a + 1)
    return ls[a].y + (ls[b].y - ls[a].y) * (x - a)


def layer(arm, act, key, src_marks, dst_marks, weights, mirror=False, bob=1.0):
    """Adds the capture's residual (see above) to `act`, joints -> weight.
    src_marks (capture frames, 30 fps) are matched to dst_marks (our frames)."""
    tr = capture(key)
    s = 60.0 / tr.get("fps", 30)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])

    def seg(f):
        for i in range(len(dst_marks) - 1):
            if dst_marks[i] <= f <= dst_marks[i + 1]:
                return i
        return 0 if f < dst_marks[0] else len(dst_marks) - 2

    def tmap(f):
        i = seg(f)
        d0, d1 = dst_marks[i], dst_marks[i + 1]
        u = min(1.0, max(0.0, (f - d0) / max(d1 - d0, 1e-6)))
        return src_marks[i] + (src_marks[i + 1] - src_marks[i]) * u, i, u

    curves = nd_anim.fcurves(act)
    by = {}
    for fc in curves:
        by[(fc.data_path, fc.array_index)] = fc
    for joint, w in weights.items():
        bone = CTRL[joint]
        path = 'pose.bones["%s"].rotation_quaternion' % bone
        fcs = [by.get((path, i)) for i in range(4)]
        if None in fcs:
            continue
        rows = []
        for f in range(start, end + 1):
            qk = Quaternion([fc.evaluate(f) for fc in fcs]).normalized()
            x, i, u = tmap(f)
            qa, qb = _cq(tr, joint, src_marks[i], mirror), _cq(tr, joint, src_marks[i + 1], mirror)
            if qa.dot(qb) < 0:
                qb = -qb
            lin = qa.slerp(qb, u)
            d = lin.inverted() @ _cq(tr, joint, x, mirror)
            dl = nd_ctrl.local_rot(arm, bone, d.to_matrix())
            q = qk @ Quaternion().slerp(dl, w)
            if rows and rows[-1][1].dot(q) < 0:
                q = -q
            rows.append((f, q))
        for i, fc in enumerate(fcs):
            fc.keyframe_points.clear()
            for f, q in rows:
                kp = fc.keyframe_points.insert(f, q[i], options={"FAST"})
                kp.interpolation = "LINEAR"
            fc.update()
    if bob:
        path = 'pose.bones["cog"].location'
        fcs = [by.get((path, i)) for i in range(3)]
        if None not in fcs:
            rest = arm.data.bones["cog"].matrix_local.to_3x3().transposed()
            rows = []
            for f in range(start, end + 1):
                x, i, u = tmap(f)
                ya, yb = _cy(tr, src_marks[i]), _cy(tr, src_marks[i + 1])
                dy = (_cy(tr, x) - (ya + (yb - ya) * u)) * bob
                v = Vector([fc.evaluate(f) for fc in fcs]) + rest @ nd_rig.rb((0, dy, 0))
                rows.append((f, v))
            for i, fc in enumerate(fcs):
                fc.keyframe_points.clear()
                for f, v in rows:
                    kp = fc.keyframe_points.insert(f, v[i], options={"FAST"})
                    kp.interpolation = "LINEAR"
                fc.update()
    meta = dict(act.get("nd_meta", {}))
    meta["capture"] = key
    act["nd_meta"] = meta
    return act


# ============================================================ VACUUM PALM
def _vp_coil():
    """The rear palm drawn down and back to the hip (palm forward), the hips
    wound back onto the rear leg, the lead palm out at him like a sight."""
    return P({"root": {"y": -.86, "z": .16, "pitch": 4, "yaw": 74}, "torso": {"pitch": 2, "yaw": -34},
              "rf": RF(.88, .8, yaw=64), "lf": LF(-.64, -.8, yaw=26)},
             ra=lambda p: reach(p, "R", body_pt(p, .62, .05, .55), start={"raise": 10, "out": 16, "twist": -50, "elbow": 110}, wrist=-60),
             la=lambda p: aim(p, "L", -2, 6, twist=-46, elbow=14, wrist=-46),
             head=look(-3))


def _vp_hit():
    """The hips snapped through, the weight forward on the lead leg, the rear
    heel off the floor: the rear palm out at full reach (elbow soft), the lead
    palm pulled back to the chest."""
    return P({"root": {"y": -.82, "z": -.34, "pitch": 9, "yaw": 26}, "torso": {"pitch": 4, "yaw": -18},
              "rf": RF(.88, .8, toe=-26, yaw=50), "lf": LF(-.64, -.8, yaw=24)},
             ra=lambda p: aim(p, "R", -8, 0, twist=PALM_T, elbow=8, wrist=PALM_W),
             la=lambda p: reach(p, "L", chest_pt(p, -.55, -.55, -.75), start={"raise": 40, "out": -20, "twist": -40, "elbow": 120}, wrist=-50),
             head=look(-4))


def vacuum_palm(arm):
    out = []
    ch = Shot(arm, N + "VacuumPalm.Channel")
    ch.key(0, S(), "ease")
    # the rear hand drops in an arc past the shoulder as the hips start to wind
    mid = P({"root": {"y": -.78, "z": .08, "pitch": 5, "yaw": 64}, "torso": {"pitch": 3, "yaw": -30}},
            ra=lambda p: reach(p, "R", body_pt(p, 1.15, .9, .45), start={"raise": 40, "out": 30, "twist": -40, "elbow": 100}, wrist=-40),
            la=lambda p: aim(p, "L", -4, 2, twist=-44, elbow=18, wrist=-40))
    ch.key(5, mid, "pass")
    coil = _vp_coil()
    ch.key(9, coil, "ease")
    gather = merge(coil, {"root": {"y": -.88, "z": .18}})
    ch.key(11, gather, "ease")
    ch.drag(["hand.R"], 1)
    out.append(ch.build(markers={"release": 11 / F}))
    hit = _vp_hit()
    push = merge(hit, {"root": {"z": -.37, "y": -.83}, "ra": {"elbow": 5}})
    back = P({"root": {"y": -.74, "z": -.12, "pitch": 6, "yaw": 42}, "torso": {"pitch": 4, "yaw": -24},
              "rf": RF(.88, .8, toe=-6, yaw=60)},
             ra=lambda p: reach(p, "R", body_pt(p, 1.3, 1.6, -.2), start={"raise": 80, "out": 10, "twist": -40, "elbow": 80}, wrist=-36),
             la=lambda p: aim(p, "L", -6, 0, twist=-40, elbow=22, wrist=-32))
    keys = [(0, gather, "launch"), (3, hit, "impact"), (6, push, "ease"), (9, merge(push, {"root": {"z": -.35}}), "ease"),
            (14, back, "pass"), (19, merge(S(), {"root": {"y": -.67}}), "ease")]
    re, rc = split(arm, N + "VacuumPalm", keys, 3, 3, drags=[(["neck"], 1)])
    re["nd_markers"] = {}
    out += [re, rc]
    return out


# ============================================================== PALM THRUST
def palm_thrust(arm):
    """(strike, also the Gentle Counter's answer) contact 7, recover 13, end
    24: a half step in on the lead foot; the lead palm rolls his guard aside
    while the rear palm heel drives up into the heart; held a beat (the
    chakra goes in), then the rear foot steps up and he is back in stance."""
    sh = Shot(arm, N + "PalmThrust")
    T = -.55
    sh.key(0, S(), "ease")
    load = P({"root": {"y": -.8, "z": .1, "pitch": 5, "yaw": 66}, "torso": {"pitch": 3, "yaw": -30}},
             ra=lambda p: reach(p, "R", body_pt(p, .75, .45, .4), start={"raise": 20, "out": 14, "twist": -50, "elbow": 110}, wrist=-58),
             la=lambda p: aim(p, "L", -10, 14, twist=-70, elbow=30, wrist=-36))
    sh.key(4, load, "ease")
    # the lead foot in the air on its half step
    step = merge(load, {"travel": {"z": T * .55}, "root": {"z": -.06, "y": -.78},
                        "lf": LF(-.64, -.8 + T * .7, y=.16, toe=6, yaw=24), "rf": RF(.88, .8, yaw=62)})
    sh.key(5, step, "pass")
    hit = P({"travel": {"z": T}, "root": {"y": -.84, "z": -.3, "pitch": 9, "yaw": 22}, "torso": {"pitch": 3, "yaw": -18},
             "lf": LF(-.64, -.8 + T * 1.1, yaw=22), "rf": RF(.88, .8, toe=-24, yaw=48)},
            ra=lambda p: aim(p, "R", -10, 8, twist=PALM_T, elbow=10, wrist=PALM_W),
            la=lambda p: aim(p, "L", -46, 24, twist=-80, elbow=34, wrist=-40))
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"z": -.34, "y": -.86}, "ra": {"elbow": 6}}), "ease")
    sh.key(13, merge(hit, {"root": {"z": -.32, "y": -.85}}), "ease")
    # the rear foot steps up behind him, the hands back into the guard
    up = P({"travel": {"z": T}, "root": {"y": -.72, "z": -.58, "pitch": 6, "yaw": 44}, "torso": {"pitch": 4, "yaw": -24},
            "lf": LF(-.64, -.8 + T * 1.1, yaw=24), "rf": RF(.88, .8 + T * .5, y=.14, toe=-12, yaw=58)},
           ra=lambda p: reach(p, "R", body_pt(p, 1.3, 1.65, -.15), start={"raise": 90, "out": 0, "twist": -40, "elbow": 100}, wrist=-34),
           la=lambda p: aim(p, "L", -8, 2, twist=-44, elbow=24, wrist=-32))
    sh.key(18, up, "pass")
    end = P({"travel": {"z": T}, "root": {"y": -.67, "z": -.02 + T * .1},
             "lf": LF(-.64, -.8 + T * 1.1, yaw=26), "rf": RF(.88, .8 + T * .9, yaw=64)})
    sh.key(24, end, "ease")
    sh.drag(["neck"], 1)
    sh.drag(["hand.L"], 1)
    act = sh.build(markers={"contact": 7 / F, "recover": 13 / F})
    return layer(arm, act, "hadouken", [41, 50, 61, 79, 101], [0, 4, 7, 13, 24], {"Root": .8, "Waist": .8, "Neck": .5})


# ================================================================ ROTATION
SPIN0 = 185.0          # the spin loop's first yaw (its Recover winds down to the stance's 410 = 50)
PIVOT = (-.6, -.72)    # the lead foot, the pivot of the turn


def _spin(yaw, k=1.0, lean=6):
    """The body at hip yaw `yaw` in the turn: upright on the lead foot (the
    hips over it), the rear foot off the floor sweeping round behind, the
    arms wide and soft, palms out - the leading arm high, the trailing one
    low (the dome is the spin's own)."""
    th = math.radians(yaw)
    right = Vector((math.cos(th), 0, math.sin(th)))
    fwd = Vector((math.sin(th), 0, -math.cos(th)))
    piv = Vector((PIVOT[0], 0, PIVOT[1]))
    c = piv + right * .18
    free = piv + right * 1.0 + fwd * -.35
    return merge(BASE, {
        "travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": c.x * k, "y": -.62, "z": c.z * k - .02 * (1 - k), "pitch": 2, "yaw": yaw, "roll": -lean},
        "torso": {"pitch": -2, "yaw": 8, "roll": -2}, "head": {"pitch": -4, "yaw": 12, "roll": 0},
        "la": {"raise": 84, "out": 72, "twist": -50, "elbow": 22, "wrist": -54, "wroll": 0},
        "ra": {"raise": 64, "out": 84, "twist": -40, "elbow": 26, "wrist": -50, "wroll": 0},
        "lf": LF(PIVOT[0], PIVOT[1], yaw=yaw - 24, toe=-4),
        "rf": RF(free.x, free.z, y=.34, yaw=yaw + 10, toe=-30)})


def rotation(arm):
    """Eight Trigrams Rotation: Channel .04 (3 frames) - the arms fling wide
    as the hips start the turn on the lead foot; Release, one full turn per
    16 frames (loops through Active .55: two turns), on the ball of the lead
    foot, the rear foot swept round off the floor; Recover .24 - the turn
    winds down through the last quarter, the rear foot lands back in its
    place and the palms fold into the guard."""
    out = []
    ch = Shot(arm, N + "Rotation.Channel")
    ch.key(0, S(), "ease")
    first = _spin(125, k=.7, lean=3)
    first = merge(first, {"rf": RF(1.0, .5, y=.2, yaw=120, toe=-20)})
    ch.key(3, first, "impact")
    out.append(ch.build(markers={"release": 3 / F}))
    re = Shot(arm, N + "Rotation.Release")
    for i in range(9):
        re.key(i * 2, _spin(SPIN0 + 45 * i), "linear")
    out.append(re.build(loop=True))
    rc = Shot(arm, N + "Rotation.Recover")
    rc.key(0, _spin(SPIN0), "launch")
    rc.key(4, _spin(SPIN0 + 82, lean=4), "pass")
    rc.key(8, merge(_spin(SPIN0 + 150, k=.6, lean=2), {"rf": RF(1.0, .7, y=.12, yaw=330, toe=-10),
                                                        "la": {"raise": 76, "out": 40, "elbow": 30}, "ra": {"raise": 90, "out": 30, "elbow": 70}}), "pass")
    land = P({"root": {"y": -.72, "yaw": 412 - 360 + 360, "z": -.02}, "torso": {"yaw": -26}},
             la=lambda p: dict(GUARD_L, raise=72), ra=lambda p: dict(GUARD_R, raise=104))
    land["root"]["yaw"] = 414
    land["lf"] = LF(PIVOT[0], PIVOT[1], yaw=386)
    land["rf"] = RF(.88, .8, yaw=424)
    rc.key(11, land, "impact")
    fin = merge(land, {"root": {"yaw": 410, "y": -.68}, "lf": LF(PIVOT[0], PIVOT[1], yaw=386), "rf": RF(.88, .8, yaw=424)})
    rc.key(14, fin, "ease")
    out.append(rc.build())
    return out


# ============================================================== 64 PALMS
def _field():
    """Eight Trigrams 64 Palms stance: the deepest and widest, square to him
    from the side, the lead palm straight out at him, the rear palm back and
    high behind, both open; the head on him."""
    return P({"root": {"y": -1.16, "z": -.1, "pitch": 4, "yaw": 78}, "torso": {"pitch": 0, "yaw": -40},
              "lf": LF(-.75, -1.55, yaw=14), "rf": RF(1.05, 1.0, yaw=84)},
             la=lambda p: aim(p, "L", -2, 4, twist=-60, elbow=10, wrist=-50),
             ra=lambda p: aim(p, "R", 150, 34, twist=-40, elbow=26, wrist=-40),
             head=look(-4))


def sixty_four(arm):
    out = []
    ch = Shot(arm, N + "SixtyFourPalms.Channel")
    ch.key(0, S(), "ease")
    # "You are within my field of divination": the stance steps in (the
    # server glides him up to 11 studs): the lead foot reaches out low and
    # long, the rear one drives back, the arms open front and back.
    reach_ = P({"root": {"y": -.88, "z": -.18, "pitch": 6, "yaw": 66}, "torso": {"pitch": 2, "yaw": -34},
                "lf": LF(-.7, -1.25, y=.2, toe=8, yaw=18), "rf": RF(.96, .9, toe=-14, yaw=74)},
               la=lambda p: aim(p, "L", -4, 14, twist=-50, elbow=24, wrist=-40),
               ra=lambda p: aim(p, "R", 110, 46, twist=-40, elbow=50, wrist=-40))
    ch.key(5, reach_, "pass")
    fld = _field()
    land = merge(fld, {"root": {"y": -1.22, "z": -.16}})
    ch.key(10, land, "impact")
    ch.key(13, merge(fld, {"root": {"y": -1.18}}), "ease")
    ch.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": 13 / F}))

    # The flurry: eight palms a loop (3 frames each), alternating, each to a
    # different point (high, low, in, out), the hips turning a few degrees
    # into each one and the striking shoulder driving in; the other hand comes
    # back to the chest, chambered, ready.
    re = Shot(arm, N + "SixtyFourPalms.Release")
    pts = [(-4, 8), (-10, -6), (2, 16), (-14, 2), (0, -10), (-8, 12), (4, 0), (-12, -2)]
    for i, (yw, el) in enumerate(pts):
        lead = i % 2 == 0
        f = i * 3
        hips = 70 if lead else 52
        body = P({"root": {"y": -1.16 - .03 * (i % 2), "z": -.12 - (.04 if lead else .08), "pitch": 5, "yaw": hips},
                  "torso": {"pitch": 2, "yaw": -38 if lead else -30},
                  "lf": LF(-.75, -1.55, yaw=14), "rf": RF(1.05, 1.0, yaw=84)})
        if lead:
            body["la"] = aim(body, "L", yw, el, twist=-58 if i % 4 == 0 else FING_T, elbow=6, wrist=-56 if i % 4 == 0 else FING_W)
            body["ra"] = reach(body, "R", chest_pt(body, .5, -.6, -.6), start={"raise": 60, "out": -10, "twist": -40, "elbow": 120}, wrist=-50)
        else:
            body["ra"] = aim(body, "R", yw, el, twist=-58 if i % 4 == 1 else FING_T, elbow=6, wrist=-56 if i % 4 == 1 else FING_W)
            body["la"] = reach(body, "L", chest_pt(body, -.45, -.55, -.7), start={"raise": 60, "out": -10, "twist": -40, "elbow": 120}, wrist=-50)
        body["head"] = face(body, 0, elev=-4)
        re.key(f, body, "impact")
    first = re.keys[0][1]
    re.key(24, first, "impact")
    out.append(re.build(loop=True))

    # Recover .40: the last two palms - both driven into him, the body
    # dropped, the rear leg long - held, still; then he rises into his stance.
    rc = Shot(arm, N + "SixtyFourPalms.Recover")
    rc.key(0, first, "ease")
    fin = P({"root": {"y": -1.2, "z": -.3, "pitch": 8, "yaw": 40}, "torso": {"pitch": 2, "yaw": -22},
             "lf": LF(-.75, -1.55, yaw=14), "rf": RF(1.05, 1.0, toe=-20, yaw=70)},
            la=lambda p: aim(p, "L", 8, 6, twist=PALM_T, elbow=8, wrist=PALM_W),
            ra=lambda p: aim(p, "R", -14, 0, twist=PALM_T, elbow=8, wrist=PALM_W))
    rc.key(4, fin, "impact")
    rc.key(12, merge(fin, {"root": {"y": -1.22, "z": -.33}}), "ease")
    rise = P({"root": {"y": -.86, "z": -.12, "pitch": 6, "yaw": 48}, "torso": {"pitch": 4, "yaw": -24},
              "lf": LF(-.75, -1.55, yaw=20), "rf": RF(1.0, .7, y=.14, toe=-10, yaw=66)},
             la=lambda p: dict(GUARD_L, raise=64), ra=lambda p: dict(GUARD_R, raise=94))
    rc.key(18, rise, "pass")
    rc.key(24, P({"root": {"z": -.2}, "lf": LF(-.75, -1.55, yaw=26), "rf": RF(.95, .55, yaw=64)}), "ease")
    rc.drag(["neck"], 1)
    out.append(rc.build())
    return out


# ============================================================ BYAKUGAN SIGHT
def _temple(p):
    """The rear hand's two fingers at his right temple, the elbow out high."""
    return reach(p, "R", head_pt(p, .7, .62, -.35), start={"raise": 110, "out": 30, "twist": 40, "elbow": 140}, wrist=-6)


def byakugan(arm):
    """Byakugan: Channel .12 - the rear hand comes up from the ear to the
    temple, two fingers on it, the elbow out high; the head bows a little,
    the eyes closing, the lead palm draws in; Release (contact at 2) - the
    head comes up sharp, the chest opens and the lead palm opens out at him:
    the veins stand out; Recover - the hand comes down to the ear guard."""
    out = []
    ch = Shot(arm, N + "ByakuganSight.Channel")
    ch.key(0, S(), "ease")
    sign = P({"root": {"y": -.6, "z": .04, "pitch": 2, "yaw": 46}, "torso": {"pitch": 6, "yaw": -22}},
             la=lambda p: aim(p, "L", -10, -6, twist=-40, elbow=44, wrist=-30))
    sign["head"] = face(sign, 0, elev=-16)
    sign["ra"] = _temple(sign)
    ch.key(7, sign, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build())
    see = P({"root": {"y": -.52, "z": -.02, "pitch": -2, "yaw": 44}, "torso": {"pitch": -6, "yaw": -22}},
            la=lambda p: aim(p, "L", -14, 14, twist=-60, elbow=16, wrist=-56))
    see["head"] = face(see, 0, elev=4)
    see["ra"] = _temple(see)
    keys = [(0, sign, "ease"), (2, see, "impact"), (5, merge(see, {"root": {"y": -.54}, "head": {"pitch": see["head"]["pitch"] + 2}}), "ease"),
            (12, S(), "ease")]
    # Release = 0..5, Recover from 0 (the engine starts it once Active ends)
    re = Shot(arm, N + "ByakuganSight.Release")
    for f, p, sp in keys[:3]:
        re.key(f, p, sp)
    re.drag(["neck"], 1)
    out.append(re.build(markers={"contact": 2 / F}))
    rc = Shot(arm, N + "ByakuganSight.Recover")
    rc.key(0, see, "ease")
    rc.key(5, merge(see, {"root": {"y": -.56}, "ra": dict(GUARD_R, raise=118, elbow=120)}), "pass")
    rc.key(12, S(), "ease")
    rc.drag(["hand.L"], 1)
    out.append(rc.build())
    return out


# ================================================================ HASANGEKI
def hasangeki(arm):
    """Eight Trigrams Mountain Crusher. Channel .30: the snake (the player
    wove tiger - snake: the channel picks up from the snake, snapped); then
    both arms draw one big circle up, out and round, and the two palms land
    heel to heel at the right hip, the hips wound back low on the rear leg.
    Release (Active .08): one lunge over the lead knee, both palms driven out
    together at full reach, heels first - the wave; held, still, then the
    palms come down and back into the guard."""
    out = []
    ch = Shot(arm, N + "Hasangeki.Channel")
    ch.key(0, S(), "ease")
    sn = P({"root": {"y": -.74, "z": .02, "pitch": 4, "yaw": 44}, "torso": {"pitch": 6, "yaw": -20}})
    sn = merge(sn, SEAL[2])
    sn["head"] = face(sn, 0, elev=-6)
    ch.key(3, sn, "impact")
    up = P({"root": {"y": -.6, "z": .02, "pitch": -2, "yaw": 34}, "torso": {"pitch": -8, "yaw": -12}},
           la=lambda p: aim(p, "L", -60, 62, twist=-30, elbow=18, wrist=-30),
           ra=lambda p: aim(p, "R", 60, 66, twist=-30, elbow=18, wrist=-30),
           head=look(0))
    ch.key(8, up, "pass")
    roundr = P({"root": {"y": -.86, "z": .1, "pitch": 4, "yaw": 62}, "torso": {"pitch": 2, "yaw": -16},
                "lf": LF(-.64, -1.0, yaw=26)},
               la=lambda p: aim(p, "L", 40, 14, twist=-50, elbow=40, wrist=-40),
               ra=lambda p: aim(p, "R", 140, 6, twist=-50, elbow=40, wrist=-40))
    ch.key(13, roundr, "pass")
    load = P({"root": {"y": -1.02, "z": .18, "pitch": 6, "yaw": 78}, "torso": {"pitch": 4, "yaw": -18},
              "lf": LF(-.64, -1.1, yaw=28), "rf": RF(.88, .8, yaw=70)}, head=look(-4))
    h = body_pt(load, .72, .02, .62)
    load["ra"] = reach(load, "R", h, start={"raise": 20, "out": 20, "twist": -60, "elbow": 100}, wrist=-60)
    load["la"] = reach(load, "L", h + body_rot(load) @ Vector((-.08, .44, -.1)), start={"raise": 40, "out": -40, "twist": -40, "elbow": 110}, wrist=-60)
    ch.key(17, load, "ease")
    gath = merge(load, {"root": {"y": -1.06, "z": .2}})
    ch.key(20, gath, "ease")
    ch.drag(["hand.L", "hand.R"], 1)
    out.append(ch.build(markers={"release": 20 / F}))

    th = P({"root": {"y": -1.04, "z": -.66, "pitch": 12, "yaw": 20}, "torso": {"pitch": 6, "yaw": -12},
            "lf": LF(-.64, -1.1, yaw=24), "rf": RF(.88, .8, toe=-24, yaw=44)},
           la=lambda p: aim(p, "L", 9, 4, twist=-62, elbow=6, wrist=-64),
           ra=lambda p: aim(p, "R", -10, 0, twist=-62, elbow=6, wrist=-64),
           head=look(-4))
    push = merge(th, {"root": {"z": -.7, "y": -1.06}, "la": {"elbow": 4}, "ra": {"elbow": 4}})
    held = merge(th, {"root": {"z": -.68, "y": -1.04}})
    back = P({"root": {"y": -.82, "z": -.1, "pitch": 8, "yaw": 40}, "torso": {"pitch": 4, "yaw": -22},
              "lf": LF(-.64, -.95, y=.12, yaw=26), "rf": RF(.88, .8, yaw=60)},
             la=lambda p: dict(GUARD_L, raise=60), ra=lambda p: dict(GUARD_R, raise=90))
    keys = [(0, gath, "launch"), (3, th, "impact"), (5, push, "ease"), (11, held, "ease"),
            (17, merge(held, {"root": {"z": -.64}}), "ease"), (24, back, "pass"), (30, P({"root": {"y": -.69}}), "ease")]
    re, rc = split(arm, N + "Hasangeki", keys, 5, 11, marker=3, drags=[(["neck"], 1), (["hand.L", "hand.R"], 1)])
    layer(arm, rc, "hadouken", [61, 71, 85, 101], [0, 6, 19, 25], {"Root": .7, "Waist": .7, "Neck": .4})
    out += [re, rc]
    return out


# ======================================================== LEG POINTS / LOW PALM
def leg_points(arm):
    """LegPoints.Channel (.06, 4 frames): the Byakugan drops to his legs - the
    head and chest dip, the lead hand's two fingers turn down at them, the
    rear hand drops to the hip, chambered. LowPalm (strike: contact 5,
    recover 11, end 28): a long low step in on the lead foot, the body
    dropped almost onto the rear knee: the lead fingers into the front thigh
    (contact), the rear hand's into the other leg as the hips turn in behind
    it; then he rises in one block and the rear foot steps up."""
    ch = Shot(arm, N + "LegPoints.Channel")
    ch.key(0, S(), "ease")
    lk = P({"root": {"y": -.86, "z": .06, "pitch": 12, "yaw": 50}, "torso": {"pitch": 12, "yaw": -22}},
           la=lambda p: aim(p, "L", -4, -36, twist=FING_T, elbow=30, wrist=FING_W),
           ra=lambda p: reach(p, "R", body_pt(p, .7, .3, .35), start={"raise": 10, "out": 14, "twist": -40, "elbow": 110}, wrist=-30),
           head=look(-26))
    ch.key(4, lk, "ease")
    out = [ch.build(markers={"release": 4 / F})]

    sh = Shot(arm, N + "LowPalm")
    T = -.7
    sh.key(0, lk, "ease")
    stp = P({"travel": {"z": T * .5}, "root": {"y": -1.0, "z": -.04, "pitch": 14, "yaw": 50}, "torso": {"pitch": 12, "yaw": -22},
             "lf": LF(-.64, -.8 + T * .9, y=.16, toe=8, yaw=24), "rf": RF(.88, .8, yaw=64)},
            la=lambda p: aim(p, "L", -4, -30, twist=FING_T, elbow=46, wrist=FING_W),
            ra=lambda p: reach(p, "R", body_pt(p, .7, .3, .4), start={"raise": 10, "out": 14, "twist": -40, "elbow": 110}, wrist=-30),
            head=look(-28))
    sh.key(3, stp, "pass")
    hit = P({"travel": {"z": T}, "root": {"y": -1.42, "z": -.28, "pitch": 16, "yaw": 46}, "torso": {"pitch": 14, "yaw": -18},
             "lf": LF(-.64, -.8 + T * 1.35, yaw=24), "rf": RF(.88, .8, toe=-46, yaw=64)},
            la=lambda p: aim(p, "L", -2, -34, twist=FING_T, elbow=4, wrist=FING_W),
            ra=lambda p: reach(p, "R", body_pt(p, .75, .35, .3), start={"raise": 10, "out": 14, "twist": -40, "elbow": 110}, wrist=-30),
            head=look(-30))
    sh.key(5, hit, "impact")
    two = P({"travel": {"z": T}, "root": {"y": -1.46, "z": -.34, "pitch": 16, "yaw": 22}, "torso": {"pitch": 14, "yaw": -14},
             "lf": LF(-.64, -.8 + T * 1.35, yaw=22), "rf": RF(.88, .8, toe=-50, yaw=46)},
            la=lambda p: reach(p, "L", chest_pt(p, -.6, -.7, -.6), start={"raise": 50, "out": -10, "twist": -40, "elbow": 110}, wrist=-30),
            ra=lambda p: aim(p, "R", -2, -34, twist=FING_T, elbow=4, wrist=FING_W),
            head=look(-30))
    sh.key(9, two, "impact")
    sh.key(12, merge(two, {"root": {"z": -.37, "y": -1.48}}), "ease")
    up = P({"travel": {"z": T}, "root": {"y": -.9, "z": -.66, "pitch": 9, "yaw": 42}, "torso": {"pitch": 6, "yaw": -22},
            "lf": LF(-.64, -.8 + T * 1.35, yaw=24), "rf": RF(.88, .8 + T * .6, y=.16, toe=-14, yaw=60)},
           la=lambda p: dict(GUARD_L, raise=62), ra=lambda p: dict(GUARD_R, raise=92),
           head=look(-8))
    sh.key(19, up, "pass")
    sh.key(28, P({"travel": {"z": T}, "root": {"y": -.67, "z": -.02 + T * .35},
                  "lf": LF(-.64, -.8 + T * 1.35, yaw=26), "rf": RF(.88, .8 + T * 1.05, yaw=64)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["hand.R", "forearm.R"], 1)
    out.append(sh.build(markers={"contact": 5 / F, "recover": 11 / F}))
    return out


# =========================================================== GENTLE COUNTER
def _reading(sink=0.0):
    """The reading guard: the weight sunk back on the rear foot, the lead foot
    drawn in light, both palms open on the centre line (the lead one high
    before the chin, the rear crossing under it): they turn a blow aside."""
    p = P({"root": {"y": -.94 - sink, "z": .2, "pitch": 2, "yaw": 42}, "torso": {"pitch": 0, "yaw": -18},
           "lf": LF(-.5, -.5, yaw=20, toe=-10), "rf": RF(.88, .8, yaw=64)},
          head=look(0))
    p["la"] = reach(p, "L", shoulder_at(p, "L") + chest_rot(p) @ Vector((.75, -.1, -1.55)),
                    start={"raise": 80, "out": -10, "twist": -74, "elbow": 60}, wrist=-52)
    p["ra"] = reach(p, "R", shoulder_at(p, "R") + chest_rot(p) @ Vector((-1.15, -.75, -1.25)),
                    start={"raise": 60, "out": -30, "twist": -66, "elbow": 86}, wrist=-48)
    return p


def gentle_counter(arm):
    """Gentle Step: Counter Palm. Channel .04: the rat, snapped at the chin
    (the player wove ram - rat). Release (Active .04): the lead foot draws its
    half circle in off the floor, the weight drops back, the palms open out
    of the seal into the reading guard; Recover: held, the palms turning a
    little with the breath, the eyes on him (the stance window: the answer is
    PalmThrust), and he eases up into his stance."""
    out = []
    ch = Shot(arm, N + "GentleCounter.Channel")
    ch.key(0, S(), "ease")
    rat = P({"root": {"y": -.74, "z": .04, "pitch": 3, "yaw": 44}, "torso": {"pitch": 6, "yaw": -20}})
    rat = merge(rat, SEAL[4])
    rat["head"] = face(rat, 0, elev=-6)
    ch.key(3, rat, "impact")
    out.append(ch.build(markers={"release": 3 / F}))
    mid = P({"root": {"y": -.86, "z": .1, "pitch": 3, "yaw": 46}, "torso": {"pitch": 2, "yaw": -20},
             "lf": LF(-.86, -.68, y=.2, toe=-6, yaw=22)},
            la=lambda p: aim(p, "L", -14, 14, twist=-60, elbow=70, wrist=-40),
            ra=lambda p: aim(p, "R", -26, 2, twist=-60, elbow=96, wrist=-40),
            head=look(0))
    rd = _reading()
    keys = [(0, rat, "ease"), (2, mid, "pass"), (5, merge(_reading(.04), {"lf": LF(-.5, -.5, yaw=20, toe=-10)}), "impact"),
            (7, rd, "ease"), (11, merge(_reading(.02), {"la": {"twist": -68, "wrist": -46}}), "ease"),
            (17, P({"root": {"y": -.72, "z": .04}}), "ease")]
    re, rc = split(arm, N + "GentleCounter", keys, 2, 7, marker=2, drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    out += [re, rc]
    return out


# ============================================================ TRIGRAM FIELD
def trigram_field(arm):
    """Eight Trigrams Field. Channel .30: the tiger, snapped; the lead foot
    sweeps a wide half circle on the floor round to his left side while the
    arms open and rise overhead, palms up (the field is gathered).
    Release (Active .12): he drops into a wide square stance and presses both
    palms down and out by the hips - the trigrams spread under him; held a
    beat, then he rises and the lead foot slides round back to the front."""
    out = []
    ch = Shot(arm, N + "TrigramField.Channel")
    ch.key(0, S(), "ease")
    tg = P({"root": {"y": -.74, "z": .02, "pitch": 4, "yaw": 44}, "torso": {"pitch": 6, "yaw": -20}})
    tg = merge(tg, SEAL[1])
    tg["head"] = face(tg, 0, elev=-6)
    ch.key(3, tg, "impact")
    sweep = P({"root": {"y": -.9, "z": 0, "pitch": 4, "yaw": 34}, "torso": {"pitch": 2, "yaw": -16},
               "lf": LF(-1.3, -.7, y=.1, toe=-8, yaw=10)},
              la=lambda p: aim(p, "L", -70, -16, twist=-30, elbow=16, wrist=-30),
              ra=lambda p: aim(p, "R", 50, 4, twist=-30, elbow=30, wrist=-30),
              head=look(-8))
    ch.key(9, sweep, "pass")
    plant = P({"root": {"y": -.84, "z": .06, "pitch": 0, "yaw": 22}, "torso": {"pitch": -2, "yaw": -10},
               "lf": LF(-1.55, -.1, yaw=4)},
              la=lambda p: aim(p, "L", -84, 36, twist=20, elbow=16, wrist=-20),
              ra=lambda p: aim(p, "R", 70, 40, twist=20, elbow=20, wrist=-20),
              head=look(-2))
    ch.key(14, plant, "pass")
    g = P({"root": {"y": -.66, "z": .06, "pitch": -3, "yaw": 22}, "torso": {"pitch": -6, "yaw": -10},
           "lf": LF(-1.55, -.1, yaw=4)},
          la=lambda p: aim(p, "L", -36, 70, twist=40, elbow=16, wrist=-20),
          ra=lambda p: aim(p, "R", 36, 70, twist=40, elbow=16, wrist=-20),
          head=look(2))
    ch.key(18, g, "ease")
    ch.key(20, merge(g, {"root": {"y": -.63}}), "ease")
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": 20 / F}))
    g2 = merge(g, {"root": {"y": -.63}})
    pr = P({"root": {"y": -1.3, "z": .08, "pitch": 4, "yaw": 22}, "torso": {"pitch": 2, "yaw": -10},
            "lf": LF(-1.55, -.1, yaw=4), "rf": RF(.88, .8, yaw=50)},
           la=lambda p: aim(p, "L", -70, -40, twist=-20, elbow=20, wrist=-84),
           ra=lambda p: aim(p, "R", 70, -40, twist=-20, elbow=20, wrist=-84),
           head=look(-2))
    rise = P({"root": {"y": -.86, "z": .04, "pitch": 4, "yaw": 38}, "torso": {"pitch": 2, "yaw": -20},
              "lf": LF(-1.15, -.6, y=.12, toe=-4, yaw=18)},
             la=lambda p: dict(GUARD_L, raise=50, out=20), ra=lambda p: dict(GUARD_R, raise=86),
             head=look(-4))
    keys = [(0, g2, "launch"), (4, pr, "impact"), (7, merge(pr, {"root": {"y": -1.34}}), "ease"),
            (13, merge(pr, {"root": {"y": -1.32}}), "ease"), (20, rise, "pass"), (28, S(), "ease")]
    re, rc = split(arm, N + "TrigramField", keys, 7, 13, marker=4, drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    out += [re, rc]
    return out


# ================================================================== AWAKEN
def awaken(arm):
    """Byakugan full field (40 frames): the rear hand's two fingers up before
    his face, the head bowed, the knees giving; the veins - the head comes
    up, and both arms sweep out wide and round, palms open, the chest opening
    (no blind spot left); the arms come back in a slow circle into the guard,
    a breath deeper than before."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, S(), "ease")
    sign = P({"root": {"y": -.78, "z": .06, "pitch": 4, "yaw": 44}, "torso": {"pitch": 8, "yaw": -18}},
             la=lambda p: aim(p, "L", -10, -10, twist=-40, elbow=50, wrist=-30))
    sign["head"] = face(sign, 0, elev=-18)
    sign["ra"] = reach(sign, "R", head_pt(sign, .05, .5, -1.0), start={"raise": 100, "out": -40, "twist": 60, "elbow": 130}, wrist=0)
    sh.key(10, sign, "ease")
    sh.key(14, merge(sign, {"root": {"y": -.8}}), "ease")
    wide = P({"root": {"y": -.62, "z": 0, "pitch": -4, "yaw": 30}, "torso": {"pitch": -10, "yaw": -8},
              "lf": LF(-.64, -.8, yaw=26)},
             la=lambda p: aim(p, "L", -80, 12, twist=-60, elbow=14, wrist=-56),
             ra=lambda p: aim(p, "R", 86, 16, twist=-60, elbow=14, wrist=-56),
             head=look(6))
    sh.key(20, wide, "impact")
    sh.key(25, merge(wide, {"root": {"y": -.64}, "torso": {"pitch": -12}}), "ease")
    fold = P({"root": {"y": -.8, "z": .02, "pitch": 4, "yaw": 46}, "torso": {"pitch": 2, "yaw": -22}},
             la=lambda p: aim(p, "L", -30, 4, twist=-40, elbow=30, wrist=-30),
             ra=lambda p: aim(p, "R", 70, 30, twist=-40, elbow=80, wrist=-30))
    sh.key(32, fold, "pass")
    sh.key(40, P({"root": {"y": -.76}}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["forearm.L", "hand.L", "forearm.R", "hand.R"], 1)
    return sh.build()


# ================================================================== THROWS
def _hold():
    """The grab's hold (common_e9): both hands at his collar, square to him."""
    return P({"root": {"y": -.72, "z": -.14, "pitch": 10, "yaw": 22}, "torso": {"pitch": 6, "yaw": -6},
              "ra": {"raise": 80, "out": -12, "twist": 0, "elbow": 72, "wrist": 0},
              "la": {"raise": 80, "out": -12, "twist": 0, "elbow": 72, "wrist": 0}},
             head=look(-6))


def throw(arm):
    """The grab's throw (contact 7, recover 13, end 34): a short wind to the
    right on the rear leg, then the hips turn through hard on the lead foot
    and both palms heave him across and away to the left, the rear heel up;
    the arms follow through wide and come back round into the guard."""
    sh = Shot(arm, N + "Throw")
    h = _hold()
    sh.key(0, h, "ease")
    wind = P({"root": {"y": -.84, "z": .04, "pitch": 6, "yaw": 58}, "torso": {"pitch": 4, "yaw": 10},
              "ra": {"raise": 66, "out": 18, "twist": 0, "elbow": 96, "wrist": 0},
              "la": {"raise": 84, "out": -30, "twist": 0, "elbow": 62, "wrist": 0}},
             head=look(-6))
    sh.key(5, wind, "ease")
    heave = P({"root": {"y": -.8, "z": -.32, "pitch": 12, "yaw": -18}, "torso": {"pitch": 8, "yaw": -26},
               "rf": RF(.88, .8, toe=-30, yaw=30), "lf": LF(-.64, -.8, yaw=0)},
              ra=lambda p: aim(p, "R", -52, 10, twist=PALM_T, elbow=12, wrist=PALM_W),
              la=lambda p: aim(p, "L", -92, 6, twist=-30, elbow=30, wrist=-40),
              head=look(-6, yaw=-20))
    sh.key(7, heave, "impact")
    follow = merge(heave, {"root": {"yaw": -28, "z": -.34}, "torso": {"yaw": -30}})
    follow["ra"] = aim(follow, "R", -80, 4, twist=PALM_T, elbow=14, wrist=PALM_W)
    follow["la"] = aim(follow, "L", -128, 0, twist=-30, elbow=30, wrist=-40)
    sh.key(13, follow, "ease")
    back = P({"root": {"y": -.74, "z": -.1, "pitch": 6, "yaw": 30}, "torso": {"pitch": 4, "yaw": -22},
              "rf": RF(.88, .8, toe=-6, yaw=56), "lf": LF(-.64, -.8, yaw=16)},
             la=lambda p: dict(GUARD_L, raise=58, out=20), ra=lambda p: dict(GUARD_R, raise=80, out=10))
    sh.key(22, back, "pass")
    sh.key(34, S(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "shoulder.R"], 1)
    act = sh.build(markers={"contact": 7 / F, "recover": 13 / F})
    return layer(arm, act, "throw", [20, 41, 50, 62, 101], [0, 5, 7, 13, 34], {"Root": .6, "Waist": .7, "Neck": .4})


def throw_kunai(arm):
    """Throw.Kunai (upper body over the gait; release 7, end 16): the rear
    hand, already by the ear, draws back a hand's breadth with the shoulder;
    then the hips and chest turn in and the kunai leaves in a straight line
    off the fingers, the arm long, the wrist snapped; the hand comes back to
    the ear guard."""
    sh = Shot(arm, N + "Throw.Kunai")
    sh.key(0, S(), "ease")
    cock = P({"root": {"y": -.7, "z": .06, "pitch": 4, "yaw": 60}, "torso": {"pitch": 2, "yaw": -18}},
             ra=lambda p: reach(p, "R", head_pt(p, 1.0, .5, .55), start={"raise": 120, "out": 20, "twist": -20, "elbow": 130}, wrist=20),
             la=lambda p: aim(p, "L", -8, 6, twist=-40, elbow=18, wrist=-30))
    sh.key(5, cock, "ease")
    rel = P({"root": {"y": -.72, "z": -.12, "pitch": 7, "yaw": 34}, "torso": {"pitch": 4, "yaw": -26},
             "rf": RF(.88, .8, toe=-14, yaw=56)},
            ra=lambda p: aim(p, "R", -8, 6, twist=-10, elbow=8, wrist=-30),
            la=lambda p: reach(p, "L", chest_pt(p, -.6, -.6, -.6), start={"raise": 50, "out": -10, "twist": -40, "elbow": 110}, wrist=-40))
    sh.key(7, rel, "impact")
    sh.key(10, merge(rel, {"ra": {"raise": rel["ra"]["raise"] - 8, "wrist": -40}, "root": {"z": -.14}}), "ease")
    sh.key(16, S(), "ease")
    sh.drag(["neck"], 1)
    act = sh.build(markers={"release": 7 / F})
    return layer(arm, act, "flick_throw", [0, 0, 0], [0, 7, 16], {}, bob=0) if False else act


def author(arm):
    acts = [awaken(arm), palm_thrust(arm), throw_kunai(arm)]
    acts += rotation(arm)
    acts += vacuum_palm(arm)
    acts += sixty_four(arm)
    acts += byakugan(arm)
    acts += leg_points(arm)
    acts += hasangeki(arm)
    acts += gentle_counter(arm)
    acts += trigram_field(arm)
    acts.append(throw(arm))
    return acts
