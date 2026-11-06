"""Kakashi's jutsu, pass v2 (05-06/11, user: « refais toutes les animations de
jutsus avec les nouveaux outils », « des animations fluides comme un film »).

Authored on his body (kakashi_p6.STANCE: a narrow three-quarter base, left
lead, the tanto low in the right hand in the reverse grip, the free left hand
on the line). His bible (docs/characters/KAKASHI.md): efficient and calm -
he measures, then commits to ONE precise act; little useless height; the eye
and the hand cost a pose; every act gives the guard back. Against that calm
the Lightning Blade is the one violent thing he does (it must read as a
lunging, charging thrust), and young Kakashi is the Doton expert: each earth
jutsu goes DOWN into the floor with the palms and the floor answers. Every
act is authored as one continuous timeline (anticipation, action,
follow-through, overshoot and settle; the hips lead, the shoulder follows,
the hand arrives last, `drag` keeps the head and the free hand a frame or two
behind) and cut the way the game plays it (split(): the Release is what the
server's TechniqueActive shows, the Recover starts on the Active frame's
pose). Captures (nd_mocap, Mixamo) bring the weight of the casts and throws
through layer(): their upper body and hips are laid over the key-posed
timeline, which keeps the feet planted (IK) and the overall shape.

  LightningBlade     the Chidori formed: a small rise as both hands meet at
    .Channel         the chest (the right palm in the left hand's grip, the
                     lightning born between them), then the right hand is
                     driven down and back past the hip, palm open to the
                     floor, while the rear foot steps back into a sprinter's
                     coil - the hips sink, the lead hand reaches out on the
                     line, the head comes up to fix it. The hold is never
                     still: the hand trembles with the current, the hips keep
                     sinking onto the front foot (a spring being wound).
  ChidoriThrust      the charge: the rear leg fires, the body launches long
                     and low, the right arm spears straight out at chest
                     height as the lead foot reaches for the floor two studs
                     ahead (contact in 3 frames); the arm overshoots on the
                     landing - the right shoulder drives past the left, the
                     free arm flung back - the rear foot drags up behind, and
                     the brake: the hips drop and come back over the feet,
                     the spent arm swings down past the thigh and back up to
                     the guard. Shared by the air version (the engine keeps
                     the legs of the air pose).
  TrackingFang       the summoning: the right thumb to the mask (bitten - a
                     small jerk of the head), the arm thrown up high on a
                     rise onto the toes, then the whole body drops onto the
                     rear knee and the palm is slapped flat on the floor by
                     the lead foot, the left hand braced on the knee. The
                     Release is the shock (the shoulders sink, the head snaps
                     up as the hounds burst); the Recover peels the palm off
                     and rises through a small overshoot into the guard.
  WaterDragon        the copy at speed: five seals snapped in a chain (snake,
                     ram, rat, snake, tiger: the hands pressed together, the
                     hips dipping and the chest swaying a hair on each), the
                     last pressed high under the chin, held with the
                     shoulders tight. Release (capture cast_forward): both
                     arms are swept up overhead - the dragon rises out of the
                     water - and thrown forward and down at him on a drive of
                     the hips, held, guiding it; Recover: the arms come down
                     and the guard.
  DashAttack         the Lightning Cut, also his dash attack: out of the run
                     the blade hand is cocked across to the left shoulder, the
                     body low; the hips unwind first and the reverse-grip
                     blade sweeps flat across through the body as the lead
                     foot lands long, the arm carries on out behind him to
                     the right, the head glances back over the shoulder, and
                     he rises from the long low base into the guard.
  Throw.Kunai        the free hand throws from under the blade arm: it is
                     pulled across to the right hip as the hips wind, then
                     the hips unwind and the arm whips out flat to the front
                     (a backhand flick), overshoots and comes back to the
                     line. The engine plays only the upper body over the run.
  Throw              (the grab's throw) from the hold: the hips sink and wind
                     to the right, then turn through; the shoulders follow,
                     the arms heave him across and away and over the lead
                     leg, the rear foot pivoting on its toes; follow-through
                     and settle.
  Awaken             the Sharingan uncovered: the head dips as the left hand
                     comes up to the headband, the hand pushes it up off the
                     eye and the head lifts - a beat with the eye open - then
                     the hand comes down onto the line and the stance drops
                     lower and wider (the rear foot steps out).
  EarthWall          tiger - snake, the hands lifted an instant on a rise,
                     then both palms slammed flat on the floor a shoulder's
                     width apart in front of the lead foot, a deep squat;
                     the wall rises with HIM - the hips first, the palms
                     peeled off the floor and carried up the chest, turned
                     out above the head on his toes as if lifting the slab;
                     then they come down onto its face and shove.
  EarthHeadhunter    snake - ram, then the free hand is cocked high by the
                     ear on a rise and speared down into the floor beside the
                     lead foot - he drops onto the rear knee and the arm goes
                     in to the wrist; the grip closes (a jolt down the arm,
                     the head snaps up), and he wrenches the hand out of the
                     ground to the hip and rises.
  EarthDragon        ram - rat, then the shiko: the joined hands are lifted
                     overhead as the lead knee comes up high (the tallest
                     silhouette he has), and everything comes down at once -
                     the foot stamped, the body dropped into a wide low base,
                     both palms hammered onto the floor side by side ahead.
                     Release: the hands rip up off the floor as the dragon's
                     head breaks out, the right hand snaps back to the
                     one-handed seal at the sternum and the left palm is
                     thrown open at him on a drive of the hips, held while it
                     runs (his copied Water Dragon is both arms).
  WhiteChakraSabre   rat - tiger, the right hand goes up over the shoulder to
                     his father's tanto, draws it in a wide arc over the head
                     into the forward grip, upright before his face; two
                     fingers of the left hand run up the blade to the tip
                     (the white light runs with them), then the blade is
                     flicked out and down to the side, overshoots, the
                     fingers back on the line.

Server timings (Shared/Fighters Copycat.Techniques, Shared/SealJutsu,
Shared/Attacks):
  LightningBlade ch .5 act .05 rec .12 (then ChidoriThrust .04/.26/.62)
  TrackingFang ch .3 act .08 rec .3      WaterDragon ch .55 act .3 rec .36
  LightningCut (DashAttack) ch .08 act .02 rec .16; DashAttack .07/.15/.27
  EarthWall ch .2 act .2 rec .3          EarthHeadhunter ch .26 act .06 rec .28
  EarthDragon ch .5 act .25 rec .34      WhiteChakraSabre ch .25 act .05 rec .2
  Throw .12/.1/.34
EarthWall.Channel is now .25 s (it was .3: the engine stretches a channel
onto the server's .2, 1.5x faster than authored; .25 keeps it at 1.25x).
"""
import bpy, math, os
from mathutils import Quaternion, Vector
import nd_anim, nd_ctrl, nd_mocap, nd_rig
from kakashi_p6 import STANCE
from jutsu_sasuke import ZERO, SEAL, stance_fn, weave, seal
from nd_shot import Shot, merge, POSE_BONES

N = "Copycat."
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]


# ====================================================== capture -> control rig
# nd_mocap bakes a capture on the DEFORM rig; the jutsu are authored on the
# CONTROL rig (nd_ctrl: IK feet in the world). layer() lays a capture's upper
# body and hips over a key-posed timeline: the timeline keeps the feet
# (planted where it has them, the IK legs follow the captured hips), the
# travel and the overall shape; the capture brings the weight shift, the
# order hips -> shoulder -> hand and the real timing of the throw or push.
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo/mixamo_%s.fbx"
CTRL = {"Root": "cog", "Waist": "spine", "Neck": "neck",
        "Right": "shoulder.R", "RightElbow": "forearm.R", "RightWrist": "hand.R",
        "Left": "shoulder.L", "LeftElbow": "forearm.L", "LeftWrist": "hand.L"}
ARM_R = ("Right", "RightElbow", "RightWrist")
ARM_L = ("Left", "LeftElbow", "LeftWrist")
_CAPS = {}


def capture(name, mirror=False):
    """A Mixamo capture as a pose track (nd_mocap.track, place 'full'),
    mirrored left<->right when asked. Cached per process."""
    if name not in _CAPS:
        scene = bpy.context.scene
        fps, frame = scene.render.fps, scene.frame_current
        active = bpy.context.view_layer.objects.active
        before = set(bpy.data.objects)
        src, a, b, _ = nd_mocap.import_fbx(MIXAMO % name)
        tr = nd_mocap.track(src, a, b, place="full")
        for o in set(bpy.data.objects) - before:
            bpy.data.objects.remove(o, do_unlink=True)
        scene.render.fps = fps
        scene.frame_set(frame)
        if active is not None:
            bpy.context.view_layer.objects.active = active
        _CAPS[name] = tr
    tr = _CAPS[name]
    out = {"q": {j: [q.copy() for q in v] for j, v in tr["q"].items()}, "loc": [v.copy() for v in tr["loc"]],
           "fps": 30, "name": name}
    if mirror:
        swap = {}
        for j in out["q"]:
            m = j.replace("Right", "#").replace("Left", "Right").replace("#", "Left")
            swap[m] = [Quaternion((q.w, q.x, -q.y, -q.z)) for q in out["q"][j]]
        out["q"] = swap
        out["loc"] = [Vector((-v.x, v.y, v.z)) for v in out["loc"]]
    return out


def sample_track(tr, x):
    """The track at (fractional) capture frame x: {joint: Quaternion}, loc."""
    n = len(tr["loc"])
    x = min(max(x, 0.0), n - 1.0)
    a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
    q = {}
    for j, qs in tr["q"].items():
        qa, qb = qs[a], qs[b]
        if qa.dot(qb) < 0:
            qb = -qb
        q[j] = qa.slerp(qb, u).normalized()
    return q, tr["loc"][a].lerp(tr["loc"][b], u)


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def warp_fn(src_marks, dst_marks):
    """Output frame -> capture frame: piecewise between the marks, each piece
    eased so the speed is continuous across a mark (no kink in the motion)."""
    def f(t):
        if t <= dst_marks[0]:
            return src_marks[0]
        for (a0, a1), (b0, b1) in zip(zip(src_marks, src_marks[1:]), zip(dst_marks, dst_marks[1:])):
            if b0 <= t <= b1:
                u = (t - b0) / max(b1 - b0, 1e-6)
                # (half linear, half eased: keeps the capture's own accents)
                u = .5 * u + .5 * smooth(u)
                return a0 + (a1 - a0) * u
        return src_marks[-1]
    return f


def envelope(start, end, fade_in, fade_out, peak=1.0):
    def w(f):
        a = smooth((f - start) / fade_in) if fade_in > 0 else 1.0
        b = smooth((end - f) / fade_out) if fade_out > 0 else 1.0
        return peak * min(a, b)
    return w


def _ctrl_to_rbx(arm, bone, q):
    rest = arm.data.bones[bone].matrix_local.to_3x3()
    return (nd_rig.B.transposed() @ (rest @ q.to_matrix() @ rest.transposed()) @ nd_rig.B).to_quaternion()


def layer(arm, base, tr, timemap, weights, hips=None, delta=("Root",), yaw=0.0):
    """Rewrites action `base` (built with Shot) frame by frame: every control
    bone keeps the timeline's value, the captured joints in `weights`
    ({joint: w(frame) -> 0..1}) turn toward the capture. `delta` joints take
    the capture's motion since its first mapped frame on top of the
    timeline's own rotation (the hips: our stance's facing, the capture's
    weight shift); the others take the capture's own rotation (the arm
    shapes). hips: (w(frame), (gx, gy, gz)) the captured displacement of the
    hips since the first mapped frame, added to the cog."""
    nd_anim.use(arm, base)
    scene = bpy.context.scene
    start, end = int(base.frame_range[0]), int(base.frame_range[1])
    q0, loc0 = sample_track(tr, timemap(start))
    yawq = nd_anim.R(0, -yaw, 0).to_quaternion()
    rows = []
    for f in range(start, end + 1):
        scene.frame_set(f)
        row = {b: (arm.pose.bones[b].rotation_quaternion.copy(), arm.pose.bones[b].location.copy()) for b in POSE_BONES}
        q, loc = sample_track(tr, timemap(f))
        for j, wfn in weights.items():
            w = wfn(f)
            if w <= 0:
                continue
            bone = CTRL[j]
            if j in delta:
                d = yawq @ (q[j] @ q0[j].inverted()) @ yawq.inverted()
                capq = nd_ctrl.local_rot(arm, bone, (d @ _ctrl_to_rbx(arm, bone, row[bone][0])).to_matrix())
            elif j == "Root":
                capq = nd_ctrl.local_rot(arm, bone, (yawq @ q[j]).to_matrix())
            else:
                capq = nd_ctrl.local_rot(arm, bone, q[j].to_matrix())
            bq = row[bone][0]
            if bq.dot(capq) < 0:
                capq = -capq
            row[bone] = (bq.slerp(capq, w), row[bone][1])
        if hips:
            wfn, gain = hips
            w = wfn(f)
            if w > 0:
                dl = loc - loc0
                dl = yawq.to_matrix() @ Vector((dl.x * gain[0], dl.y * gain[1], dl.z * gain[2]))
                add = arm.data.bones["cog"].matrix_local.to_3x3().transposed() @ nd_rig.rb(dl)
                row["cog"] = (row["cog"][0], row["cog"][1] + add * w)
        rows.append((f, row))
    markers = dict(base.get("nd_markers", {}))
    loop, meta = bool(base.get("nd_loop", False)), dict(base.get("nd_meta", {}))
    act_ = nd_anim.new_action(arm, base.name)
    last = {}
    for f, row in rows:
        for b in POSE_BONES:
            q, l = row[b]
            p = last.get(b)
            if p is not None and p.dot(q) < 0:
                q = -q
            last[b] = q
            pb = arm.pose.bones[b]
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=b)
            pb.location = l
            pb.keyframe_insert("location", frame=f, group=b)
    for fc in nd_anim.fcurves(act_):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
        fc.update()
    act_["nd_markers"] = markers
    act_["nd_loop"] = loop
    meta["capture"] = tr.get("name", "")
    act_["nd_meta"] = meta
    act_["nd_rig"] = "ctrl"
    act_.frame_range = (start, end)
    return act_


# ================================================================ helpers
def split(arm, prefix, keys, fa, rel_end, rec_end, drags=(), marker=None):
    """One continuous act cut the way the game plays it (jutsu_sasuke.act,
    with the lengths given): <prefix>.Release = frames 0..rel_end (the server
    shows it for its Active time, fa frames), <prefix>.Recover = frames
    fa..rec_end re-based to 0 (it starts on the Active frame's pose). Keys
    are needed on fa, rel_end and rec_end. Returns (release, recover, full
    poses by frame)."""
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    for need in (fa, rel_end, rec_end):
        if need not in frames:
            raise ValueError("%s: no key on frame %d (keys %s)" % (prefix, need, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    re = Shot(arm, prefix + ".Release")
    rc = Shot(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= rel_end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif fa < f <= rec_end:
            rc.key(f - fa, p, sp)
    for bones, n in drags:
        re.drag(bones, n)
        rc.drag(bones, n)
    mk = None if marker is None else {"release": marker / 60}
    return re.build(markers=mk), rc.build()


def low(T=0.0, over=None):
    return at(T, over)


# ======================================================== Lightning Blade
# The coil the charge leaves from: deep, the rear foot stepped back onto its
# toes, the right hand low and back past the hip (palm to the floor, the
# lightning in it), the lead hand out on the line, the head up on him.
COIL = {"root": {"y": -.86, "z": -.12, "pitch": 26, "yaw": 32, "roll": 0}, "torso": {"pitch": 12, "yaw": -12, "roll": 0},
        "head": {"pitch": -28, "yaw": -14, "roll": 0},
        "ra": {"raise": -34, "out": 24, "twist": -10, "elbow": 34, "wrist": 44, "wroll": 0},
        "la": {"raise": 62, "out": -8, "twist": -24, "elbow": 46, "wrist": -12, "wroll": 0},
        "rf": {"x": .26, "z": 1.02, "y": .04, "toe": -28, "yaw": 26}, "lf": {"x": -.1, "z": -.6, "toe": 0}}
# the right palm in the left hand's grip at the chest: the ram seal's hands
GATHER = merge(SEAL[3], {"ra": {"wrist": 30}})


def lightning_blade(arm):
    out = []
    ch = Shot(arm, N + "LightningBlade.Channel")
    ch.key(0, s(), "ease")
    # a small rise as the hands meet at the chest (the anticipation of the
    # drop), the head down on them
    gather = s(merge({"root": {"y": -.28, "z": .04, "pitch": 2, "yaw": 22}, "torso": {"pitch": 6, "yaw": -6},
                      "head": {"pitch": 14, "yaw": -6}}, GATHER))
    ch.key(5, gather, "ease")
    ch.key(8, merge(gather, {"root": {"y": -.32}, "head": {"pitch": 18}, "ra": {"wrist": 36}}), "ease")
    # the right hand is driven down and back past the hip; the rear foot
    # lifts to step back (a step, not a slide)
    ch.key(11, s({"root": {"y": -.6, "z": -.02, "pitch": 16, "yaw": 28}, "torso": {"pitch": 10, "yaw": -10},
                  "head": {"pitch": -6, "yaw": -10},
                  "ra": {"raise": 10, "out": 16, "twist": 0, "elbow": 60, "wrist": 30},
                  "la": {"raise": 44, "out": -14, "twist": -24, "elbow": 70, "wrist": -10},
                  "rf": {"x": .24, "z": .84, "y": .22, "toe": -10, "yaw": 28}}), "pass")
    ch.key(15, s(COIL), "impact")
    # the sink overshoots, then the hold keeps winding: the hips settle onto
    # the front foot, the hand trembles with the current
    ch.key(19, s(merge(COIL, {"root": {"y": -.92, "z": -.14}, "torso": {"pitch": 14}, "ra": {"wrist": 52, "twist": -4}})), "ease")
    ch.key(22, s(merge(COIL, {"root": {"y": -.88, "z": -.15}, "ra": {"wrist": 38, "twist": -16, "raise": -30}})), "pass")
    ch.key(25, s(merge(COIL, {"root": {"y": -.9, "z": -.17}, "ra": {"wrist": 50, "twist": -2, "raise": -36}, "head": {"pitch": -30}})), "pass")
    ch.key(28, s(merge(COIL, {"root": {"y": -.9, "z": -.19}, "ra": {"wrist": 40, "twist": -14}, "la": {"raise": 66}})), "pass")
    hold = s(merge(COIL, {"root": {"y": -.92, "z": -.2, "pitch": 28}, "ra": {"wrist": 48, "twist": -6, "raise": -36},
                          "la": {"raise": 66}, "head": {"pitch": -30}}))
    ch.key(30, hold, "ease")
    ch.drag(["neck"], 2).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": 30 / 60}))

    # The thrust (.04 / .26 / .62): launched on frame 3, the drive to 18,
    # the brake and the guard.
    th = Shot(arm, N + "ChidoriThrust")
    th.key(0, hold, "launch")
    T1 = -.9
    launch = s({"travel": {"z": T1}, "root": {"y": -.66, "z": -.42, "pitch": 30, "yaw": 4, "roll": 0},
                "torso": {"pitch": 14, "yaw": -18, "roll": 0}, "head": {"pitch": -30, "yaw": 2},
                "ra": {"raise": 86, "out": -6, "twist": 0, "elbow": 4, "wrist": -14},
                "la": {"raise": -36, "out": 26, "twist": 0, "elbow": 22, "wrist": 0},
                "rf": {"x": .26, "z": 1.02, "y": .1, "toe": -52, "yaw": 20},
                "lf": {"x": -.08, "z": -.56 + T1 - .7, "y": .34, "toe": -6}})
    th.key(3, launch, "impact")
    T2 = -1.6
    land = s({"travel": {"z": T2}, "root": {"y": -.74, "z": -.52, "pitch": 32, "yaw": -6},
              "torso": {"pitch": 14, "yaw": -24}, "head": {"pitch": -30, "yaw": 8},
              "ra": {"raise": 90, "out": -10, "twist": 0, "elbow": 0, "wrist": -18},
              "la": {"raise": -50, "out": 30, "elbow": 14},
              "rf": {"x": .24, "z": .72, "y": .16, "toe": -48, "yaw": 16},
              "lf": {"x": -.1, "z": -.56 + T2 - .5, "y": 0, "toe": 0}})
    th.key(8, land, "impact")
    T3 = -2.0
    drive = merge(land, {"travel": {"z": T3}, "root": {"y": -.7, "z": -.48, "pitch": 30, "yaw": -8},
                         "torso": {"yaw": -22}, "ra": {"raise": 88, "elbow": 2},
                         "rf": {"z": -.1, "y": .3, "toe": -36}})
    th.key(13, drive, "pass")
    T4 = -2.2
    brake = s({"travel": {"z": T4}, "root": {"y": -.66, "z": -.22, "pitch": 18, "yaw": 6},
               "torso": {"pitch": 10, "yaw": -18}, "head": {"pitch": -18, "yaw": -2},
               "ra": {"raise": 78, "out": -2, "twist": 0, "elbow": 10, "wrist": -20},
               "la": {"raise": -20, "out": 24, "elbow": 30},
               "rf": {"x": .22, "z": RF["z"] + T4 + .1, "y": 0, "toe": -10, "yaw": 26},
               "lf": {"x": -.1, "z": -.56 + T2 - .5, "y": 0, "toe": 0}})
    th.key(18, brake, "ease")
    # the spent arm swings down past the thigh and back up into the guard;
    # the lead foot is drawn back under him
    th.key(25, s({"travel": {"z": T4}, "root": {"y": -.56, "z": .06, "pitch": 8, "yaw": 22},
                  "torso": {"pitch": 6, "yaw": -12}, "head": {"pitch": -6, "yaw": -12},
                  "ra": {"raise": 6, "out": 18, "twist": 10, "elbow": 40, "wrist": -10},
                  "la": {"raise": 30, "out": -6, "twist": -20, "elbow": 60},
                  "rf": brake["rf"], "lf": {"x": -.08, "z": LF["z"] + T4 - .3, "y": .2, "toe": 0}}), "pass")
    th.key(31, at(T4, {"root": {"y": -.42, "z": .04}, "ra": {"raise": 34, "elbow": 86}, "la": {"raise": 58}}), "ease")
    th.key(40, at(T4), "ease")
    th.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(th.build(markers={"contact": 3 / 60, "recover": 18 / 60}))
    return out


# ========================================================== Tracking Fang
KNEEL_RF = {"x": .3, "z": .86, "y": .32, "toe": -62, "yaw": 26}
SLAP = {"root": {"y": -1.36, "z": -.12, "pitch": 40, "yaw": 22, "roll": -4}, "torso": {"pitch": 22, "yaw": -10, "roll": -4},
        "head": {"pitch": -30, "yaw": -8, "roll": 0},
        "ra": {"raise": 54, "out": -4, "twist": 0, "elbow": 4, "wrist": 66, "wroll": 0},
        "la": {"raise": 24, "out": -16, "twist": -10, "elbow": 74, "wrist": 0, "wroll": 0},
        "rf": KNEEL_RF, "lf": {"x": -.1, "z": -.56, "toe": 0}}


def tracking_fang(arm):
    out = []
    ch = Shot(arm, N + "TrackingFang.Channel")
    ch.key(0, s(), "ease")
    # the thumb to the mask, the head dipping to it
    bite = s({"root": {"y": -.3, "z": .04, "yaw": 22}, "torso": {"pitch": 4, "yaw": -8}, "head": {"pitch": 10, "yaw": -6},
              "ra": {"raise": 100, "out": -40, "twist": 40, "elbow": 142, "wrist": 0},
              "la": {"raise": 40, "out": -10, "twist": -30, "elbow": 70}})
    ch.key(5, bite, "ease")
    ch.key(7, merge(bite, {"head": {"pitch": 4, "yaw": -14, "roll": 4}, "ra": {"raise": 96, "elbow": 136}}), "impact")
    # the arm is thrown up high, the body rising onto the toes (the wind-up)
    up = s({"root": {"y": -.2, "z": .08, "pitch": -4, "yaw": 14}, "torso": {"pitch": -6, "yaw": -6, "roll": 4},
            "head": {"pitch": 2, "yaw": -8, "roll": 0},
            "ra": {"raise": 158, "out": 16, "twist": 10, "elbow": 40, "wrist": -20},
            "la": {"raise": 30, "out": 20, "twist": -10, "elbow": 50},
            "rf": {"toe": -16, "y": .04}})
    ch.key(11, up, "ease")
    # down: the hips drop first, the arm comes over in an arc
    ch.key(15, s({"root": {"y": -.95, "z": -.08, "pitch": 26, "yaw": 20}, "torso": {"pitch": 16, "yaw": -8, "roll": 0},
                  "head": {"pitch": -14, "yaw": -8},
                  "ra": {"raise": 120, "out": 0, "twist": 0, "elbow": 20, "wrist": 30},
                  "la": {"raise": 26, "out": -10, "twist": -10, "elbow": 70},
                  "rf": {"x": .28, "z": .78, "y": .14, "toe": -40, "yaw": 26}}), "pass")
    slap = s(SLAP)
    ch.key(18, slap, "impact")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": 18 / 60}))

    # Release (Active .08 = 5 frames): the shock, the head snaps up as the
    # hounds burst. Recover (.3): the palm peels off, he rises, overshoot.
    press = merge(slap, {"root": {"y": -1.42, "z": -.14}, "torso": {"pitch": 25}, "head": {"pitch": -22},
                         "ra": {"elbow": 10, "raise": 52}})
    burst = merge(slap, {"root": {"y": -1.36, "z": -.1}, "torso": {"pitch": 20}, "head": {"pitch": -38, "yaw": -12}})
    peel = s({"root": {"y": -1.0, "z": .02, "pitch": 24, "yaw": 22}, "torso": {"pitch": 12, "yaw": -10},
              "head": {"pitch": -14, "yaw": -12},
              "ra": {"raise": 44, "out": 6, "twist": 10, "elbow": 50, "wrist": 10},
              "la": {"raise": 40, "out": -14, "twist": -24, "elbow": 70},
              "rf": {"x": .26, "z": .72, "y": .12, "toe": -30, "yaw": 28}})
    rise = s({"root": {"y": -.3, "z": .02, "pitch": 3}, "torso": {"pitch": 5}, "head": {"pitch": -4},
              "ra": {"raise": 34, "elbow": 84}})
    keys = [(0, slap, "ease"), (2, press, "impact"), (5, burst, "ease"),
            (11, peel, "pass"), (17, rise, "ease"), (23, s(), "ease")]
    out += split(arm, N + "TrackingFang", keys, 5, 5, 23, drags=[(["neck"], 1)])
    return out


# ============================================================ Water Dragon
def water_dragon(arm):
    out = []
    ch = Shot(arm, N + "WaterDragon.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44, "pitch": 4}, "head": {"pitch": -4}})
    # five seals snapped (snake, ram, rat, snake, tiger), the hips dipping,
    # the chest swaying a hair on each
    signs = (2, 3, 4, 2, 1)
    for i, n in enumerate(signs):
        f = 5 + 5 * i
        pose = merge(base, {"root": {"y": -.44 - .025 * (i + 1), "yaw": 26 + (3 if i % 2 else -3)},
                            "torso": {"yaw": -10 + (-3 if i % 2 else 3)}})
        ch.key(f, merge(pose, seal(n, pose)), "impact")
        if i < len(signs) - 1:
            # (between two seals the hands part a little: the change reads)
            mid = merge(pose, seal(n, pose))
            mid = merge(mid, {"ra": {"raise": mid["ra"]["raise"] - 8, "out": mid["ra"]["out"] + 6},
                              "la": {"raise": mid["la"]["raise"] - 6, "out": mid["la"]["out"] + 6}})
            ch.key(f + 3, mid, "pass")
    # the last seal pressed high under the chin, the shoulders tight
    top = merge(base, {"root": {"y": -.5, "z": .04, "pitch": 0}, "torso": {"pitch": 0}, "head": {"pitch": 4}})
    top = merge(top, seal(1, top))
    top = merge(top, {"ra": {"raise": 62, "elbow": 112}, "la": {"raise": 62, "elbow": 112}})
    ch.key(29, top, "ease")
    ch.key(33, merge(top, {"root": {"y": -.53}, "ra": {"raise": 64}, "la": {"raise": 64}}), "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 33 / 60}))
    end_ch = merge(top, {"root": {"y": -.53}, "ra": {"raise": 64}, "la": {"raise": 64}})

    # Release (Active .3) + Recover (.36): one timeline (38 frames), the
    # arms from the capture cast_forward (rise overhead 12->26, thrown
    # forward-down 26->38, held 38->46, back 46->66).
    T = -.3
    lift = s({"root": {"y": -.3, "z": .1, "pitch": -4, "yaw": 12}, "torso": {"pitch": -10, "yaw": -4},
              "head": {"pitch": -14, "yaw": -6},
              "ra": {"raise": 160, "out": 10, "twist": 0, "elbow": 30, "wrist": 0},
              "la": {"raise": 160, "out": 10, "twist": 0, "elbow": 30, "wrist": 0},
              "rf": {"toe": -14, "y": .04}})
    thrust = s({"travel": {"z": T}, "root": {"y": -.66, "z": -.3, "pitch": 18, "yaw": 8}, "torso": {"pitch": 10, "yaw": -6},
                "head": {"pitch": -16, "yaw": -6},
                "ra": {"raise": 96, "out": 6, "twist": 0, "elbow": 6, "wrist": -30},
                "la": {"raise": 96, "out": 6, "twist": 0, "elbow": 6, "wrist": -30},
                "rf": {"z": RF["z"], "toe": -26, "y": .08}, "lf": {"z": LF["z"] + T - .3}})
    guide = merge(thrust, {"root": {"y": -.62, "z": -.26, "pitch": 15}, "ra": {"raise": 100}, "la": {"raise": 100},
                           "rf": {"toe": -18, "y": .05}})
    settle = s({"travel": {"z": T}, "root": {"y": -.48, "z": -.04, "pitch": 8, "yaw": 20}, "torso": {"pitch": 6, "yaw": -8},
                "head": {"pitch": -4, "yaw": -12},
                "ra": {"raise": 40, "out": 12, "twist": 14, "elbow": 70, "wrist": -16},
                "la": {"raise": 60, "out": -12, "twist": -26, "elbow": 66},
                "rf": {"z": RF["z"] + T, "toe": 0, "y": .14}, "lf": {"z": LF["z"] + T - .3}})
    keys = [(0, end_ch, "ease"), (6, lift, "ease"), (10, thrust, "impact"), (18, guide, "ease"),
            (24, merge(guide, {"root": {"y": -.6}, "ra": {"raise": 96, "elbow": 14}, "la": {"raise": 94, "elbow": 16}}), "ease"),
            (31, settle, "pass"), (38, at(T, {"lf": {"z": LF["z"] + T - .3}}), "ease")]
    re, rc = split(arm, N + "WaterDragon", keys, 18, 18, 38, drags=[(["neck"], 1)])
    tr = capture("cast_forward")
    w_arms = envelope(0, 18, 3, 0, .85)
    re = layer(arm, re, tr, warp_fn([12, 26, 38, 44], [0, 6, 10, 18]),
               {"Right": w_arms, "RightElbow": w_arms, "RightWrist": envelope(0, 18, 3, 0, .5),
                "Left": w_arms, "LeftElbow": w_arms, "LeftWrist": envelope(0, 18, 3, 0, .5),
                "Waist": envelope(0, 18, 3, 0, .5)},
               hips=(envelope(0, 18, 3, 0, 1.0), (0, .5, .6)), delta=("Root", "Waist"))
    w_rc = envelope(-20, 20, 0, 12, .85)
    rc = layer(arm, rc, tr, warp_fn([44, 52, 66], [0, 7, 20]),
               {"Right": w_rc, "RightElbow": w_rc, "Left": w_rc, "LeftElbow": w_rc,
                "RightWrist": envelope(-20, 20, 0, 12, .5), "LeftWrist": envelope(-20, 20, 0, 12, .5),
                "Waist": envelope(-20, 20, 0, 12, .5)},
               hips=(envelope(-20, 20, 0, 12, 1.0), (0, .5, .6)), delta=("Root", "Waist"))
    out += [re, rc]
    return out


# ===================================================== Dash attack / Lightning Cut
def dash_attack(arm):
    sh = Shot(arm, N + "DashAttack")
    # out of the run: low, the blade hand cocked across to the left shoulder
    entry = s({"root": {"y": -.62, "z": -.18, "pitch": 22, "yaw": 2, "roll": 0}, "torso": {"pitch": 12, "yaw": 22},
               "head": {"pitch": -16, "yaw": -6},
               "ra": {"raise": 74, "out": -54, "twist": 30, "elbow": 118, "wrist": -30},
               "la": {"raise": 44, "out": 6, "twist": -20, "elbow": 56, "wrist": -10},
               "rf": {"x": .2, "z": .62, "y": .04, "toe": -30, "yaw": 22},
               "lf": {"x": -.08, "z": -.86, "y": .22, "toe": -10, "yaw": -6}})
    sh.key(0, entry, "ease")
    T1 = -.5
    sh.key(2, merge(entry, {"travel": {"z": T1 * .5}, "root": {"yaw": 10, "z": -.24}, "torso": {"yaw": 14},
                            "ra": {"out": -46, "elbow": 104}, "lf": {"z": -.86 + T1 * .5 - .3, "y": .14}}), "pass")
    T = -.9
    # the hips unwind, the blade sweeps flat through the body (contact)
    cut = s({"travel": {"z": T}, "root": {"y": -.78, "z": -.3, "pitch": 24, "yaw": 26}, "torso": {"pitch": 12, "yaw": -6},
             "head": {"pitch": -18, "yaw": -10},
             "ra": {"raise": 86, "out": 20, "twist": 20, "elbow": 16, "wrist": -40},
             "la": {"raise": 24, "out": 26, "twist": -10, "elbow": 36, "wrist": 0},
             "rf": {"x": .2, "z": .62, "y": .1, "toe": -44, "yaw": 22},
             "lf": {"x": -.12, "z": -1.7, "y": 0, "toe": 0, "yaw": -6}})
    sh.key(4, cut, "impact")
    # the arm carries on out behind him; the head glances back
    through = merge(cut, {"root": {"y": -.84, "z": -.36, "pitch": 24, "yaw": 40}, "torso": {"yaw": 4},
                          "head": {"pitch": -12, "yaw": -26},
                          "ra": {"raise": 56, "out": 82, "twist": 10, "elbow": 8, "wrist": -44},
                          "la": {"raise": 30, "out": 20, "elbow": 50}, "rf": {"y": .14, "toe": -40}})
    sh.key(7, through, "ease")
    sh.key(10, merge(through, {"root": {"y": -.82, "yaw": 42}, "head": {"yaw": -32}, "ra": {"out": 86, "raise": 50}}), "ease")
    # he rises out of the long base, the rear foot drawn up, the blade back in
    sh.key(15, s({"travel": {"z": T}, "root": {"y": -.5, "z": -.06, "pitch": 10, "yaw": 30}, "torso": {"pitch": 8, "yaw": -8},
                  "head": {"pitch": -4, "yaw": -18},
                  "ra": {"raise": 40, "out": 30, "twist": 20, "elbow": 60, "wrist": -24},
                  "la": {"raise": 50, "out": -10, "twist": -26, "elbow": 70},
                  "rf": {"x": .2, "z": RF["z"] + T + .1, "y": .2, "toe": -10, "yaw": 28},
                  "lf": {"x": -.1, "z": -1.7, "y": 0}}), "pass")
    sh.key(20, at(T, {"lf": {"z": -1.7}, "root": {"z": -.04}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1)
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


# ============================================================== throws
def throw_kunai(arm):
    sh = Shot(arm, N + "Throw.Kunai")
    sh.key(0, s(), "ease")
    # the free hand pulled across under the blade arm to the right hip, the
    # hips winding; the blade arm lifts out of its way
    cock = s({"root": {"y": -.42, "yaw": 38}, "torso": {"pitch": 10, "yaw": 2}, "head": {"yaw": -26},
              "ra": {"raise": 46, "out": 16, "elbow": 92},
              "la": {"raise": 22, "out": -54, "twist": 30, "elbow": 112, "wrist": 36}})
    sh.key(4, cock, "ease")
    # the hips unwind, the arm whips out flat (release)
    rel = s({"root": {"y": -.4, "yaw": 14}, "torso": {"pitch": 6, "yaw": -18}, "head": {"yaw": -10},
             "la": {"raise": 82, "out": 22, "twist": -14, "elbow": 6, "wrist": -24}})
    sh.key(7, rel, "launch")
    sh.key(10, merge(rel, {"root": {"yaw": 10}, "torso": {"yaw": -22}, "la": {"raise": 78, "out": 40, "elbow": 2, "wrist": -36}}), "ease")
    sh.key(16, s(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build(markers={"release": 7 / 60})


def grab_throw(arm):
    """Copycat.Throw (Attacks: .12 / .1 / .34): from common_e9's hold."""
    S = merge(ZERO, STANCE)
    y = S["root"]["y"]
    yaw = S["root"]["yaw"] * .4
    hold = merge(S, {"root": {"y": y - .08, "z": -.14, "pitch": 10, "yaw": yaw}, "torso": {"pitch": 6, "yaw": 0},
                     "head": {"pitch": -8, "yaw": 0},
                     "ra": {"raise": 80, "out": -12, "twist": 0, "elbow": 72, "wrist": 0},
                     "la": {"raise": 80, "out": -12, "twist": 0, "elbow": 72, "wrist": 0}})
    sh = Shot(arm, N + "Throw")
    sh.key(0, hold, "ease")
    # the hips sink and wind to the right, pulling him in to the right hip
    wind = merge(hold, {"root": {"y": y - .26, "z": -.04, "pitch": 8, "yaw": yaw + 28}, "torso": {"pitch": 8, "yaw": 16},
                        "head": {"yaw": -10},
                        "ra": {"raise": 56, "out": 22, "elbow": 100}, "la": {"raise": 78, "out": -34, "elbow": 74},
                        "rf": {"toe": 8}})
    sh.key(5, wind, "ease")
    # the hips turn through first, the arms heave him across and over the
    # lead leg; the rear foot pivots on its toes
    heave = merge(hold, {"root": {"y": y - .18, "z": -.32, "pitch": 16, "yaw": yaw - 40}, "torso": {"pitch": 12, "yaw": -26},
                         "head": {"pitch": -2, "yaw": 22},
                         "ra": {"raise": 92, "out": -40, "twist": 20, "elbow": 22}, "la": {"raise": 46, "out": 44, "elbow": 30},
                         "rf": {"toe": -32, "y": .1, "yaw": S["rf"]["yaw"] - 34}})
    sh.key(7, heave, "impact")
    follow = merge(heave, {"root": {"y": y - .24, "z": -.36, "pitch": 18, "yaw": yaw - 54}, "torso": {"yaw": -32},
                           "head": {"yaw": 26},
                           "ra": {"raise": 66, "out": -50}, "la": {"raise": 28, "out": 54}})
    sh.key(13, follow, "ease")
    sh.key(20, merge(follow, {"root": {"y": y - .16, "z": -.2, "pitch": 10, "yaw": yaw - 30}, "torso": {"yaw": -18},
                              "head": {"yaw": 8}, "ra": {"raise": 40, "out": -10, "elbow": 70},
                              "la": {"raise": 44, "out": 6, "elbow": 66}, "rf": {"toe": -8, "y": .04}}), "pass")
    sh.key(28, merge(S, {"root": {"y": y - .05}}), "ease")
    sh.key(34, S, "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 1)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


# ================================================================ Awaken
def awaken(arm):
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    # the head dips as the left hand comes up to the headband
    sh.key(8, s({"root": {"y": -.3}, "head": {"pitch": 14, "yaw": -8, "roll": -4},
                 "la": {"raise": 134, "out": -34, "twist": 0, "elbow": 150, "wrist": 0},
                 "ra": {"raise": 20, "elbow": 70}}), "ease")
    sh.key(13, s({"root": {"y": -.3}, "head": {"pitch": 12, "yaw": -10, "roll": -6},
                  "la": {"raise": 150, "out": -26, "twist": 0, "elbow": 150, "wrist": 0},
                  "ra": {"raise": 20, "elbow": 70}}), "ease")
    # the hand pushes the headband up off the eye, the head lifts: the eye open
    up = s({"root": {"y": -.32, "pitch": 2}, "torso": {"pitch": 2}, "head": {"pitch": -10, "yaw": -14, "roll": 0},
            "la": {"raise": 172, "out": -8, "twist": 0, "elbow": 104, "wrist": 0},
            "ra": {"raise": 22, "elbow": 74}})
    sh.key(20, up, "impact")
    sh.key(27, merge(up, {"head": {"pitch": -12, "yaw": -16}, "la": {"raise": 168, "elbow": 110}}), "ease")
    # the hand comes down onto the line, the stance drops lower and wider
    sh.key(32, s({"root": {"y": -.46, "z": .02, "pitch": 6}, "head": {"pitch": -6, "yaw": -14},
                  "la": {"raise": 80, "out": -14, "twist": -24, "elbow": 62, "wrist": -10},
                  "rf": {"x": .34, "z": .7, "y": .2, "toe": -8}}), "pass")
    wide = s({"root": {"y": -.58, "z": .04, "pitch": 8}, "torso": {"pitch": 9}, "head": {"pitch": -4, "yaw": -14},
              "la": {"raise": 60, "out": -16, "twist": -28, "elbow": 70, "wrist": -10},
              "rf": {"x": .44, "z": .76, "y": 0, "toe": 0}})
    sh.key(37, wide, "impact")
    sh.key(41, merge(wide, {"root": {"y": -.62}}), "ease")
    sh.key(46, merge(wide, {"root": {"y": -.56}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build()


# ============================================================== Earth Wall
# both palms flat on the floor a shoulder's width apart before the lead
# foot: a deep squat, the chest over the hands, the eyes on the spot
DOWN = {"root": {"y": -1.42, "z": -.26, "pitch": 40, "yaw": 6, "roll": 0}, "torso": {"pitch": 26, "yaw": -4, "roll": 0},
        "head": {"pitch": -30, "yaw": -4, "roll": 0},
        "ra": {"raise": 62, "out": -10, "twist": 0, "elbow": 6, "wrist": 56, "wroll": 0},
        "la": {"raise": 62, "out": -8, "twist": 0, "elbow": 6, "wrist": 56, "wroll": 0},
        "rf": {"toe": -6}, "lf": {"toe": 0}}


def earth_wall(arm):
    out = []
    ch = Shot(arm, N + "EarthWall.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44}, "head": {"pitch": -4}})
    last = weave(ch, 0, (1, 2), base, beat=4)
    # the hands lifted an instant, the body up on a rise ...
    lift = s({"root": {"y": -.34, "z": .04, "pitch": 0, "yaw": 12}, "torso": {"pitch": -2, "yaw": -4}, "head": {"pitch": -2, "yaw": -6},
              "ra": {"raise": 96, "out": -8, "twist": 0, "elbow": 70, "wrist": 30},
              "la": {"raise": 96, "out": -8, "twist": 0, "elbow": 70, "wrist": 30}})
    ch.key(last + 3, lift, "ease")
    # ... and slammed down: the knees fold under the palms
    slap = s(DOWN)
    ch.key(last + 7, slap, "impact")
    out.append(None)
    ch.drag(["neck"], 1)
    out[-1] = ch.build(markers={"release": (last + 7) / 60})

    # One timeline (32 frames): Release 0..16 (Active .2 = 12), Recover 12..32.
    press = merge(slap, {"root": {"y": -1.5}, "torso": {"pitch": 29}, "head": {"pitch": -24},
                         "ra": {"elbow": 12}, "la": {"elbow": 12}})
    pry = merge(press, {"root": {"y": -1.3, "z": -.2, "pitch": 34}, "torso": {"pitch": 26}, "head": {"pitch": -24},
                        "ra": {"raise": 46, "out": -8, "twist": -40, "elbow": 36, "wrist": -6},
                        "la": {"raise": 46, "out": -8, "twist": -40, "elbow": 36, "wrist": -6}})
    heave = s({"root": {"y": -.82, "z": -.1, "pitch": 14, "yaw": 8}, "torso": {"pitch": 8, "yaw": -4},
               "head": {"pitch": -6, "yaw": -4},
               "ra": {"raise": 64, "out": -6, "twist": -70, "elbow": 104, "wrist": -24},
               "la": {"raise": 64, "out": -6, "twist": -70, "elbow": 104, "wrist": -24}})
    crest = s({"root": {"y": -.2, "z": .06, "pitch": -6, "yaw": 6}, "torso": {"pitch": -10, "yaw": -4},
               "head": {"pitch": 12, "yaw": -4},
               "ra": {"raise": 140, "out": 30, "twist": -14, "elbow": 40, "wrist": -50},
               "la": {"raise": 140, "out": 30, "twist": -14, "elbow": 40, "wrist": -50},
               "rf": {"toe": -18, "y": .06}, "lf": {"toe": -8, "y": .02}})
    hold = merge(crest, {"root": {"y": -.3, "z": .04}, "torso": {"pitch": -6}, "head": {"pitch": 8},
                         "ra": {"raise": 136, "elbow": 46}, "la": {"raise": 136, "elbow": 46},
                         "rf": {"toe": -6, "y": 0}, "lf": {"toe": 0, "y": 0}})
    shove = s({"root": {"y": -.5, "z": -.14, "pitch": 10, "yaw": 6}, "torso": {"pitch": 6, "yaw": -4},
               "head": {"pitch": -6, "yaw": -4},
               "ra": {"raise": 88, "out": 4, "twist": -72, "elbow": 8, "wrist": -64},
               "la": {"raise": 88, "out": 4, "twist": -72, "elbow": 8, "wrist": -64},
               "rf": {"toe": -16, "y": .06}})
    after = merge(shove, {"root": {"y": -.48, "z": -.12}, "ra": {"elbow": 16}, "la": {"elbow": 16}, "rf": {"toe": -8, "y": .02}})
    lower = s({"root": {"y": -.42, "z": -.02}, "head": {"pitch": -2},
               "ra": {"raise": 50, "out": 10, "twist": -10, "elbow": 60, "wrist": -24},
               "la": {"raise": 64, "out": -10, "twist": -40, "elbow": 56, "wrist": -20}})
    keys = [(0, slap, "ease"), (2, press, "impact"), (5, pry, "pass"), (9, heave, "pass"), (12, crest, "impact"),
            (16, hold, "ease"), (21, shove, "impact"), (23, after, "ease"), (27, lower, "pass"), (32, s(), "ease")]
    out += split(arm, N + "EarthWall", keys, 12, 16, 32,
                 drags=[(["neck"], 1), (["hand.R", "hand.L"], 1), (["shoulder.L", "forearm.L"], 1)], marker=0)
    return out


# ======================================================== Earth Headhunter
def headhunter(arm):
    out = []
    ch = Shot(arm, N + "EarthHeadhunter.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.46}, "head": {"pitch": -4}})
    last = weave(ch, 0, (2, 3), base, beat=4)
    # the free hand leaves the seal and cocks high by the left ear (a spear
    # hand), the body rising to it
    cock = s({"root": {"y": -.4, "z": .04, "pitch": 4, "yaw": 38, "roll": 6}, "torso": {"pitch": 0, "yaw": -14, "roll": 4},
              "head": {"pitch": -6, "yaw": -18},
              "la": {"raise": 150, "out": 30, "twist": 10, "elbow": 128, "wrist": 30},
              "ra": {"raise": 14, "out": 22, "twist": 20, "elbow": 74, "wrist": -20}})
    ch.key(last + 4, cock, "ease")
    # down onto the rear knee, the spear hand driven into the floor beside
    # the lead foot - in to the wrist
    plunge = s({"root": {"y": -1.42, "z": -.08, "pitch": 32, "yaw": 34, "roll": -12}, "torso": {"pitch": 22, "yaw": -12, "roll": -10},
                "head": {"pitch": -24, "yaw": -12},
                "la": {"raise": 22, "out": 24, "twist": 0, "elbow": 36, "wrist": 10},
                "ra": {"raise": 26, "out": 24, "twist": 20, "elbow": 80, "wrist": -20},
                "rf": {"x": .3, "z": .76, "y": .3, "toe": -56, "yaw": 30}, "lf": {"x": -.2, "z": -.72, "yaw": -6}})
    ch.key(last + 7, merge(cock, {"root": {"y": -.9, "pitch": 18, "roll": -4}, "torso": {"pitch": 10, "roll": -4},
                                  "la": {"raise": 90, "out": 30, "elbow": 70},
                                  "rf": {"x": .3, "z": .72, "y": .14, "toe": -30, "yaw": 30}, "lf": {"x": -.2, "z": -.72, "yaw": -6}}), "pass")
    ch.key(last + 10, plunge, "impact")
    sink = merge(plunge, {"root": {"y": -1.48, "roll": -14}, "torso": {"pitch": 24, "roll": -12}, "head": {"pitch": -20},
                          "la": {"raise": 18, "elbow": 28}})
    ch.key(last + 12, sink, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 12) / 60}))

    grip = merge(sink, {"root": {"y": -1.54, "z": -.04, "roll": -16}, "torso": {"pitch": 27, "roll": -13},
                        "head": {"pitch": 18, "yaw": -16, "roll": 4}, "la": {"raise": 16, "elbow": 24, "wrist": 30}})
    strain = merge(grip, {"root": {"y": -1.5, "z": .0}, "torso": {"pitch": 22}, "head": {"pitch": 12},
                          "la": {"raise": 22, "elbow": 34}})
    wrench = s({"root": {"y": -1.12, "z": .14, "pitch": 14, "yaw": 34, "roll": -2}, "torso": {"pitch": 6, "yaw": -18, "roll": 0},
                "head": {"pitch": -8, "yaw": -16, "roll": 0},
                "la": {"raise": 34, "out": 40, "twist": 10, "elbow": 96, "wrist": -10},
                "ra": {"raise": 22, "out": 22, "twist": 20, "elbow": 80, "wrist": -20},
                "rf": {"x": .26, "z": .66, "y": .1, "toe": -24, "yaw": 30}, "lf": {"x": -.2, "z": -.72, "yaw": -6}})
    yank = s({"root": {"y": -.66, "z": .14, "pitch": 2, "yaw": 34}, "torso": {"pitch": 0, "yaw": -16},
              "head": {"pitch": -6, "yaw": -14},
              "la": {"raise": -18, "out": 28, "twist": 10, "elbow": 110, "wrist": -10},
              "ra": {"raise": 24, "out": 14, "twist": 20, "elbow": 80, "wrist": -20},
              "rf": {"x": .22, "z": .6, "yaw": 30}, "lf": {"x": -.12, "z": -.62, "yaw": -6}})
    keys = [(0, sink, "ease"), (2, grip, "impact"), (4, strain, "ease"), (8, wrench, "pass"), (11, yank, "impact"),
            (15, merge(yank, {"root": {"y": -.5, "z": .06}, "la": {"raise": 30, "out": 0, "twist": -20, "elbow": 84}}), "pass"),
            (21, s(), "ease")]
    out += split(arm, N + "EarthHeadhunter", keys, 4, 11, 21, drags=[(["neck"], 1)], marker=2)
    return out


# ============================================================ Earth Dragon
def earth_dragon(arm):
    out = []
    ch = Shot(arm, N + "EarthDragon.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44}, "head": {"pitch": -4}})
    last = weave(ch, 0, (3, 4), base, beat=5)
    # the shiko: the weight onto the rear leg, the lead knee drawn high, the
    # joined hands lifted overhead (his tallest silhouette)
    over = {"ra": {"raise": 160, "out": -18, "twist": 30, "elbow": 40, "wrist": 10},
            "la": {"raise": 160, "out": -18, "twist": 30, "elbow": 40, "wrist": 10}}
    knee = s(merge({"root": {"x": .3, "y": -.3, "z": .3, "pitch": -6, "yaw": 22, "roll": 8}, "torso": {"pitch": -6, "roll": -5},
                    "head": {"pitch": 2, "roll": -4},
                    "lf": {"x": -.12, "y": 1.4, "z": -.32, "toe": 20, "yaw": -6}}, over))
    ch.key(last + 4, s(merge({"root": {"x": .2, "y": -.38, "z": .2, "roll": 5}, "torso": {"pitch": 0},
                              "lf": {"x": -.1, "y": .6, "z": -.44, "toe": 8}},
                             {"ra": {"raise": 120, "out": -22, "twist": 36, "elbow": 70, "wrist": 10},
                              "la": {"raise": 120, "out": -22, "twist": 36, "elbow": 70, "wrist": 10}})), "pass")
    ch.key(last + 8, knee, "ease")
    ch.key(last + 10, merge(knee, {"root": {"y": -.27}, "ra": {"raise": 164}, "la": {"raise": 164}}), "ease")
    # everything comes down: the foot stamped, the body dropped wide and low,
    # both palms hammered onto the floor side by side ahead
    hammer = s({"root": {"x": 0, "y": -1.4, "z": -.3, "pitch": 42, "yaw": 16, "roll": 0}, "torso": {"pitch": 26, "yaw": -6, "roll": 0},
                "head": {"pitch": -32, "yaw": -6, "roll": 0},
                "ra": {"raise": 72, "out": -22, "twist": 0, "elbow": 4, "wrist": 60},
                "la": {"raise": 72, "out": -22, "twist": 0, "elbow": 4, "wrist": 60},
                "rf": {"x": .34, "z": .62, "toe": -10, "knee": 10}, "lf": {"x": -.3, "y": 0, "z": -.62, "toe": 0, "knee": 10}})
    ch.key(last + 14, hammer, "impact")
    ch.key(last + 17, merge(hammer, {"root": {"y": -1.48}, "torso": {"pitch": 28}, "ra": {"elbow": 12}, "la": {"elbow": 12}}), "ease")
    ch.key(last + 20, merge(hammer, {"root": {"y": -1.44}, "head": {"pitch": -38}}), "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 20) / 60}))
    floor = merge(hammer, {"root": {"y": -1.44}, "head": {"pitch": -38}})

    # Release 0..23 (Active .25 = 15), Recover 15..35.
    rip = s({"root": {"y": -1.0, "z": -.06, "pitch": 18, "yaw": 22}, "torso": {"pitch": 4, "yaw": -6},
             "head": {"pitch": -6, "yaw": -8},
             "ra": {"raise": 60, "out": -14, "twist": 40, "elbow": 90, "wrist": 0},
             "la": {"raise": 44, "out": 40, "twist": -40, "elbow": 120, "wrist": -40},
             "rf": hammer["rf"], "lf": hammer["lf"]})
    send = s({"root": {"y": -1.0, "z": -.42, "pitch": 24, "yaw": 8}, "torso": {"pitch": 12, "yaw": -22},
              "head": {"pitch": -14, "yaw": -4},
              "ra": {"raise": 32.2, "out": -20.2, "twist": 58.6, "elbow": 102.7, "wrist": 0},
              "la": {"raise": 88, "out": -4, "twist": -76, "elbow": 2, "wrist": -64},
              "rf": {"x": .34, "z": .62, "knee": 8, "y": .1, "toe": -32}, "lf": hammer["lf"]})
    drive = merge(send, {"root": {"y": -1.02, "z": -.46, "pitch": 26}, "la": {"raise": 86, "elbow": 0, "wrist": -70}})
    guide = merge(send, {"root": {"y": -.94, "z": -.38, "pitch": 20}, "head": {"pitch": -10},
                         "la": {"raise": 92, "elbow": 8, "wrist": -58}, "rf": {"y": .06, "toe": -20}})
    ease_off = s({"root": {"y": -.64, "z": -.12, "pitch": 8, "yaw": 20}, "torso": {"pitch": 6, "yaw": -12},
                  "head": {"pitch": -4, "yaw": -12},
                  "ra": {"raise": 30, "out": 10, "twist": 20, "elbow": 84, "wrist": -14},
                  "la": {"raise": 70, "out": -8, "twist": -50, "elbow": 44, "wrist": -30},
                  "rf": {"x": .26, "z": .6, "y": .16, "toe": -10, "knee": 0}, "lf": {"x": -.2, "z": -.6, "knee": 0}})
    keys = [(0, floor, "ease"), (3, rip, "pass"), (5, send, "impact"), (9, drive, "ease"), (15, guide, "ease"),
            (23, ease_off, "pass"), (29, s({"root": {"y": -.4}}), "ease"), (35, s(), "ease")]
    out += split(arm, N + "EarthDragon", keys, 15, 23, 35,
                 drags=[(["neck"], 1), (["hand.L"], 1), (["shoulder.R", "forearm.R", "hand.R"], 1)], marker=5)
    return out


# ====================================================== White Chakra Sabre
# The tanto upright before his face in the forward grip (jutsu_kakashi:
# rig-solved for the engine's drawn blade), the fingers' path up the blade.
PRESENT_R = {"raise": 33.1, "out": -33.0, "twist": 16.1, "elbow": 59.1, "wrist": 43.6, "wroll": -28.5}
FINGERS_L = [{"raise": 35.1, "out": -18.9, "twist": 43.3, "elbow": 82.4, "wrist": 0, "wroll": 0},
             {"raise": 61.1, "out": -36.9, "twist": 27.5, "elbow": 81.9, "wrist": 0, "wroll": 0},
             {"raise": 118.5, "out": -30.9, "twist": 17.5, "elbow": 36.9, "wrist": 0, "wroll": 0}]
PRESENT = {"root": {"y": -.42, "z": .02, "pitch": 2, "yaw": 20}, "torso": {"pitch": 2, "yaw": -12}, "head": {"pitch": 6, "yaw": -8}}


def sabre(arm):
    out = []
    ch = Shot(arm, N + "WhiteChakraSabre.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44}, "head": {"pitch": -4}})
    last = weave(ch, 0, (4, 1), base, beat=4)
    # the right hand goes up over the right shoulder to the hilt, the chest
    # turning to it; the left keeps the tiger one-handed
    reach = s({"root": {"y": -.4, "z": .04, "pitch": 0, "yaw": 30}, "torso": {"pitch": -2, "yaw": -4, "roll": -5},
               "head": {"pitch": 0, "yaw": -18},
               "ra": {"raise": 162, "out": -16, "twist": 0, "elbow": 152, "wrist": 0},
               "la": {"raise": 40, "out": -22, "twist": 50, "elbow": 104, "wrist": 0}})
    ch.key(last + 4, reach, "ease")
    # drawn: out over the shoulder in a wide arc over the head ...
    ch.key(last + 7, merge(reach, {"root": {"yaw": 22}, "torso": {"roll": 2, "yaw": -8},
                                   "ra": {"raise": 150, "out": 30, "twist": 10, "elbow": 40, "wrist": 20}}), "pass")
    # ... and down in front into the upright guard (a small overshoot)
    present = s(merge(PRESENT, {"ra": PRESENT_R, "la": FINGERS_L[0]}))
    ch.key(last + 10, merge(present, {"root": {"y": -.46}, "ra": {"raise": 28, "elbow": 54}}), "ease")
    ch.key(last + 11, present, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 11) / 60}))

    run = s(merge(PRESENT, {"head": {"pitch": 10}, "ra": PRESENT_R, "la": FINGERS_L[1]}))
    tip = s(merge(PRESENT, {"root": {"y": -.38}, "head": {"pitch": 14}, "ra": PRESENT_R,
                            "la": merge(FINGERS_L[2], {"raise": 130, "out": -20, "elbow": 28})}))
    flick = s({"root": {"y": -.52, "z": .02, "pitch": 6, "yaw": 40}, "torso": {"pitch": 6, "yaw": -6},
               "head": {"pitch": -2, "yaw": -22},
               "ra": {"raise": 18, "out": 50, "twist": 30, "elbow": 14, "wrist": -34},
               "la": {"raise": 60, "out": -16, "twist": -30, "elbow": 70, "wrist": -10}})
    keys = [(0, present, "ease"), (3, run, "pass"), (6, tip, "ease"), (9, flick, "impact"),
            (11, merge(flick, {"root": {"y": -.5}, "ra": {"out": 44, "elbow": 22}}), "ease"), (15, s(), "ease")]
    out += split(arm, N + "WhiteChakraSabre", keys, 3, 9, 15, drags=[(["neck"], 1), (["hand.R"], 1)], marker=3)
    return out


# ================================================================== author
def author(arm):
    acts = []
    acts += lightning_blade(arm)
    acts += tracking_fang(arm)
    acts += water_dragon(arm)
    acts.append(dash_attack(arm))
    acts.append(throw_kunai(arm))
    acts.append(awaken(arm))
    acts += earth_wall(arm)
    acts += headhunter(arm)
    acts += earth_dragon(arm)
    acts += sabre(arm)
    acts.append(grab_throw(arm))
    return acts
