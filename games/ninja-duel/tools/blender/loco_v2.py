"""Locomotion v2 (anim lot 2, 07/11): each fighter runs his own way.

Audit anim 07/11: the runs, sprints and walks of Naruto, Kakashi, Minato,
Neji and Itachi were Sasuke's to 1-2 degrees (one Mixamo capture, a style
pass that barely touched a run). This pass starts from each fighter's baked
clips (src/Client/AuthoredClips*.luau: the capture plus his existing carriage,
Gaara's crossed arms, Lee's hand behind his back...) and gives every one his
own gait, in the joints' own space (a row = the Motor6D.Transform):
  legs    stride amplitude (hips), knee drive, cadence (cycle length)
  trunk   lean, bounce (hips' height through the cycle), counter-twist
  arms    swing amplitude, elbows held tighter or looser, head carriage
The feet are put back on the floor afterwards (the lower ankle reaches the
floor exactly where it did, never goes through it), and a contact-stride
report says what the engine will play (Client/VelmoraMotionEngine
contactStrideOf). Stick sheets (side view, before/after) are written for an
eye check.

  python3 loco_v2.py report|sheets|write [Fighter,...]
Runs in plain Python with `mathutils` (the bpy wheel ships it); no .blend,
no capture file needed.
"""
import glob, math, os, re, sys
try:
    from mathutils import Quaternion, Vector
except ImportError:          # the bpy wheel's mathutils loads with bpy
    import bpy  # noqa: F401
    from mathutils import Quaternion, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, "..", "..", "src", "Client"))
NAME = dict(Lion="Sasuke", Legion="Naruto", Sand="Gaara", Leaf="Lee", GentleFist="Neji",
            Mirage="Itachi", Copycat="Kakashi", Flashstep="Minato")
BETA = list(NAME)
ANKLE_Y = -2.6   # rest ankle height under the HumanoidRootPart (engine ANKLE_Y)

# Joint pivots (root space, Roblox axes) and parents: tools/blender/nd_rig.py.
PIVOT = {"Root": ((0, 0, 0), None), "Waist": ((0, .65, 0), "Root"), "Neck": ((0, 2.05, 0), "Waist")}
for side, s in (("Right", 1), ("Left", -1)):
    PIVOT[side] = ((s * 1.05, 1.6, 0), "Waist")
    PIVOT[side + "Elbow"] = ((s * 1.45, .55, 0), side)
    PIVOT[side + "Wrist"] = ((s * 1.45, -.38, 0), side + "Elbow")
    PIVOT[side + "Hip"] = ((s * .5, -.55, 0), "Root")
    PIVOT[side + "Knee"] = ((s * .5, -1.6, 0), side + "Hip")
    PIVOT[side + "Ankle"] = ((s * .5, -2.6, 0), side + "Knee")
ORDER = ["Root", "Waist", "Neck", "Right", "Left", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist",
         "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle"]


# ------------------------------------------------------------------ clips I/O
ENTRY = re.compile(r'\t\["([A-Za-z]+)\.([^"]+)"\]=\{fps=(\d+),frames=(\d+),length=([0-9.]+),loop=(true|false),'
                   r'markers=\{([^}]*)\},meta=\{([^}]*)\},joints=\{\n(.*?)\n\t\}\},?\n', re.S)


def load():
    clips = {}
    for path in sorted(glob.glob(os.path.join(SRC, "AuthoredClips*.luau"))):
        text = open(path).read()
        for m in ENTRY.finditer(text):
            fid, clip, fps, frames, length, loop, markers, meta, body = m.groups()
            joints = {}
            for jm in re.finditer(r'(\w+)=\{([^}]*)\}', body):
                vals = [float(x) for x in jm.group(2).split(",") if x.strip()]
                if jm.group(1) == "Root":
                    joints["Root"] = [(Vector(vals[i:i + 3]), Quaternion((vals[i + 6], vals[i + 3], vals[i + 4], vals[i + 5])))
                                      for i in range(0, len(vals), 7)]
                else:
                    joints[jm.group(1)] = [Quaternion((vals[i + 3], vals[i], vals[i + 1], vals[i + 2]))
                                           for i in range(0, len(vals), 4)]
            clips[(fid, clip)] = dict(path=path, fps=int(fps), frames=int(frames), length=float(length),
                                      loop=loop == "true", markers=markers, meta=meta, joints=joints)
    return clips


def fmt(v):
    s = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def entry_text(fid, clip, c):
    rows = []
    for j in ORDER:
        if j not in c["joints"]:
            continue
        vals = []
        for item in c["joints"][j]:
            if j == "Root":
                p, q = item
                vals += [p.x, p.y, p.z, q.x, q.y, q.z, q.w]
            else:
                q = item
                vals += [q.x, q.y, q.z, q.w]
        rows.append("\t\t%s={%s}," % (j, ",".join(fmt(v) for v in vals)))
    return ('\t["%s.%s"]={fps=%d,frames=%d,length=%s,loop=%s,markers={%s},meta={%s},joints={\n%s\n\t}},\n'
            % (fid, clip, c["fps"], c["frames"], fmt(c["length"]), "true" if c["loop"] else "false",
               c["markers"], c["meta"], "\n".join(rows)))


def write(clips, names):
    by_path = {}
    for key in names:
        by_path.setdefault(clips[key]["path"], []).append(key)
    for path, keys in by_path.items():
        text = open(path).read()
        for fid, clip in keys:
            m = re.search(r'\t\["%s\.%s"\]=\{fps=.*?\n\t\}\},?\n' % (re.escape(fid), re.escape(clip)), text, re.S)
            assert m, (fid, clip)
            text = text[:m.start()] + entry_text(fid, clip, clips[(fid, clip)]) + text[m.end():]
        open(path, "w").write(text)


# ------------------------------------------------------------- kinematics
def pose_at(c, i):
    return {j: c["joints"][j][i] for j in c["joints"]}


def fk(pose):
    """World (HumanoidRootPart space) position of every joint pivot, plus hands
    and feet ends, for one frame."""
    world = {}
    out = {}
    for j in ORDER:
        pivot, parent = PIVOT[j]
        pivot = Vector(pivot)
        if j == "Root":
            p, q = pose.get("Root", (Vector(), Quaternion()))
            world[j] = (p.copy(), q.copy())
        else:
            pp, pq = world[parent]
            rel = pivot - Vector(PIVOT[parent][0])
            world[j] = (pp + pq @ rel, pq @ pose.get(j, Quaternion()))
        out[j] = world[j][0]
    for side, s in (("Right", 1), ("Left", -1)):
        p, q = world[side + "Wrist"]
        out[side + "Hand"] = p + q @ Vector((0, -.6, 0))
        p, q = world[side + "Ankle"]
        out[side + "Toe"] = p + q @ Vector((0, -.2, -.7))
    out["Head"] = world["Neck"][0] + world["Neck"][1] @ Vector((0, 1.3, 0))
    return out


def ankles(c):
    return [(fk(pose_at(c, i))["RightAnkle"], fk(pose_at(c, i))["LeftAnkle"]) for i in range(c["frames"])]


def contact_stride(c, axis="z", back=False):
    """Python twin of VelmoraMotionEngine contactStrideOf (studs a planted foot
    holds per cycle)."""
    pts = ankles(c)
    n, sweep = 0, 0.0
    N = len(pts)
    for k in range(N):
        for side in (0, 1):
            a, b = pts[k][side], pts[(k + 1) % N][side]
            if not c["loop"] and k == N - 1:
                continue
            if a.y - ANKLE_Y < .2 and b.y - ANKLE_Y < .2:
                d = abs(b.x - a.x) if axis == "x" else ((a.z - b.z) if back else (b.z - a.z))
                if d > 0:
                    sweep += d
                    n += 1
    if n == 0:
        return 0.0
    per_frame = sweep / n
    return per_frame * N


# --------------------------------------------------------------- operations
def _log(q):
    axis, angle = q.to_axis_angle()
    if angle > math.pi:
        angle -= 2 * math.pi
    return Vector(axis) * angle


def _exp(v):
    a = v.length
    return Quaternion() if a < 1e-9 else Quaternion(v / a, a)


def _mean(qs):
    ref = qs[0]
    acc = Vector((0, 0, 0))
    for q in qs:
        acc += _log(ref.rotation_difference(q))
    return (ref @ _exp(acc / len(qs))).normalized()


def _rot(c, j):
    return [x[1] for x in c["joints"][j]] if j == "Root" else c["joints"][j]


def _set(c, j, qs):
    if j == "Root":
        c["joints"]["Root"] = [(p, q) for (p, _), q in zip(c["joints"]["Root"], qs)]
    else:
        c["joints"][j] = qs


def amp(c, j, k):
    """More (k>1) or less (k<1) of the clip's own motion on a joint."""
    qs = _rot(c, j)
    m = _mean(qs)
    _set(c, j, [(m @ _exp(_log(m.rotation_difference(a)) * k)).normalized() for a in qs])


def turn(c, j, pitch=0.0, yaw=0.0, roll=0.0):
    """A constant turn of a segment in its parent's frame (degrees).
    pitch > 0 bends the segment forward (the body faces -Z), yaw > 0 turns it
    left (+Y), roll > 0 tilts its top to the right... (Roblox axes)."""
    q = Quaternion((1, 0, 0), math.radians(-pitch)) @ Quaternion((0, 1, 0), math.radians(yaw)) @ Quaternion((0, 0, 1), math.radians(-roll))
    _set(c, j, [(q @ a).normalized() for a in _rot(c, j)])


def bounce(c, k):
    """The hips' rise and fall through the cycle, scaled around its mean."""
    ys = [p.y for p, _ in c["joints"]["Root"]]
    m = sum(ys) / len(ys)
    c["joints"]["Root"] = [(Vector((p.x, m + (p.y - m) * k, p.z)), q) for p, q in c["joints"]["Root"]]


def upsample(c, fps=60):
    """The same cycle drawn at `fps` (a bound's short stance needs the frames)."""
    if c["fps"] >= fps:
        return c
    k = fps / c["fps"]
    length = c["length"]
    retime(c, k)
    c["fps"] = fps
    c["length"] = round(c["frames"] / fps, 4) if c["loop"] else round((c["frames"] - 1) / fps, 4)
    return c


def retime(c, k):
    """Cycle k times as long (k<1: quicker steps). Resampled by slerp."""
    old = c["frames"]
    new = max(6, int(round(old * k)))
    loop = c["loop"]
    span = old if loop else old - 1

    def sample(lst, t, is_root):
        a = int(math.floor(t)) % old if loop else min(int(math.floor(t)), old - 1)
        b = (a + 1) % old if loop else min(a + 1, old - 1)
        u = t - math.floor(t)
        if is_root:
            (pa, qa), (pb, qb) = lst[a], lst[b]
            return (pa.lerp(pb, u), qa.slerp(qb, u))
        return lst[a].slerp(lst[b], u)

    for j in list(c["joints"]):
        lst = c["joints"][j]
        c["joints"][j] = [sample(lst, i * span / (new if loop else max(new - 1, 1)), j == "Root") for i in range(new)]
    c["frames"] = new
    c["length"] = round(new / c["fps"], 4) if loop else round((new - 1) / c["fps"], 4)


def ground(c, ref_min):
    """The lower ankle reaches the floor where the source did (its lowest
    point over the cycle), and never goes through it."""
    pts = ankles(c)
    low = [min(a.y, b.y) for a, b in pts]
    shift = ref_min - min(low)
    root = []
    for i, (p, q) in enumerate(c["joints"]["Root"]):
        lift = shift + max(0.0, (ref_min - .03) - (low[i] + shift))
        root.append((Vector((p.x, p.y + lift, p.z)), q))
    c["joints"]["Root"] = root


def copy(c):
    d = dict(c)
    d["joints"] = {j: ([(p.copy(), q.copy()) for p, q in v] if j == "Root" else [q.copy() for q in v])
                   for j, v in c["joints"].items()}
    return d


# ------------------------------------------------------------------ recipes
# The character sheet (owner brief 07/11): Naruto energetic, ample; Kakashi
# precise, economical; Minato short, extremely fast steps; Itachi economy of
# gesture, mastery; Lee engaged, explosive; Sasuke technical, controlled
# aggression, footwork. Neji upright and smooth; Gaara heavy, the sand moves.
LEGS = ("RightHip", "LeftHip")
KNEES = ("RightKnee", "LeftKnee")
ARMS = ("Right", "Left")
ELBOWS = ("RightElbow", "LeftElbow")

GAIT = {
    #             stride knee  cadence bounce twist  arms  lean  head  elbow
    "Lion":       (1.08, 1.05, 1.00,   .90,   .90,   .85,   3,   -2,    6),
    "Legion":     (1.15, 1.10, 1.00,   1.10,  1.45,  1.35,  6,   -4,   -6),
    "Copycat":    (.92,  .92,  1.06,   .70,   .55,   .50,   5,    4,   18),
    "Flashstep":  (.90,  .95,  .92,    .90,   .70,   .70,   10,  -3,   10),
    "Mirage":     (.95,  .95,  1.04,   .90,   .40,   .40,  -2,    1,   14),
    "Leaf":       (1.15, 1.15, 1.08,   1.00,  1.10,  1.15,  8,   -5,    0),
    "GentleFist": (.98,  .95,  1.02,   .60,   .50,   1.00, -2,    0,    0),
    "Sand":       (1.00, 1.00, 1.00,   1.00,  1.00,  1.00,  0,    0,    0),
}
# The sprint: a ninja's run at 45 studs/s, long strides (more hip and knee),
# chest down, arms back (already in the clip, Gaara's crossed).
SPRINT = {
    #             stride knee  lean
    "Lion":       (1.30, 1.15,  4),
    "Legion":     (1.35, 1.20,  6),
    "Copycat":    (1.25, 1.10,  4),
    "Flashstep":  (1.22, 1.10,  8),
    "Mirage":     (1.25, 1.10,  2),
    "Leaf":       (1.42, 1.30,  6),
    "GentleFist": (1.25, 1.10,  2),
    "Sand":       (1.10, 1.05,  0),
}
RUNS = ("Run.F", "Run.B", "Run.L", "Run.R")
WALKS = ("Walk.F", "Walk.B", "Walk.L", "Walk.R")


STANCE = .06   # ankle this close to its rest height: the foot bears weight


def contact_frames(c, limit=STANCE):
    """Per frame: is a foot bearing weight (ankle within `limit` studs of the
    rest height)? The engine's own floor test is looser (.2): the capture's
    feet skim that low for most of the cycle."""
    pts = ankles(c)
    # (each foot against its own lowest point: Minato runs on the balls of
    # his feet, and one foot of a capture often lands a little lower than
    # the other - its partner's stance went unseen and was lifted off)
    r0 = min(a.y for a, _ in pts)
    l0 = min(b.y for _, b in pts)
    return [a.y - r0 < limit or b.y - l0 < limit for a, b in pts]


def bound(c, squeeze, arc):
    """A ninja's bound out of a jog. The capture's foot stays on the floor most
    of the cycle (a human jog): played at 19 studs/s the engine has to run it
    2-3 times faster than drawn. The stance part of the cycle is played
    `squeeze` times as long (the planted foot sweeps back faster, the push is
    quicker), the flight part takes the time it gave back (same cycle length),
    and the hips ride a ballistic arc through each flight (`arc` = studs/s^2,
    the arc's own gravity). Speed changes are eased over the frames around a
    touch-down, so nothing pops."""
    n = c["frames"]
    if n < 6 or not c["loop"]:
        return c
    on = contact_frames(c)
    stance = sum(on)
    flight = n - stance
    if stance == 0 or flight == 0:
        # all stance (a jog with double support): the frames with the lower
        # foot highest count as flight
        low = [min(a.y, b.y) for a, b in ankles(c)]
        cut = sorted(low)[int(n * .6)]
        on = [y <= cut for y in low]
        stance = sum(on)
        flight = n - stance
    stretch = (n - squeeze * stance) / max(flight, 1)
    if stretch <= 0:
        return c
    raw = [squeeze if s else stretch for s in on]
    # ease the speed change: 3-tap circular smoothing, renormalised
    speed = [(raw[(i - 1) % n] + 2 * raw[i] + raw[(i + 1) % n]) / 4 for i in range(n)]
    total = sum(speed)
    speed = [s * n / total for s in speed]
    # new time of every source frame
    t_new = [0.0]
    for i in range(n - 1):
        t_new.append(t_new[-1] + speed[i])
    span = sum(speed)
    # flight intervals in the new time: hips' arc
    src = {j: list(v) for j, v in c["joints"].items()}

    def src_at(u):
        """Source frame (fractional) at new time u (0..n)."""
        u %= span
        k = 0
        while k + 1 < n and t_new[k + 1] <= u:
            k += 1
        nxt = t_new[k + 1] if k + 1 < n else span
        return k + (u - t_new[k]) / max(nxt - t_new[k], 1e-6)

    def sample(lst, f, is_root):
        a = int(math.floor(f)) % n
        b = (a + 1) % n
        w = f - math.floor(f)
        if is_root:
            (pa, qa), (pb, qb) = lst[a], lst[b]
            return (pa.lerp(pb, w), qa.slerp(qb, w))
        return lst[a].slerp(lst[b], w)

    frames = [src_at(i) for i in range(n)]
    for j, lst in src.items():
        c["joints"][j] = [sample(lst, f, j == "Root") for f in frames]
    # hips: a ballistic arc over each run of flight frames (new timing)
    on_new = [on[int(math.floor(f)) % n] and on[(int(math.floor(f)) + 1) % n] for f in frames]
    dt = 1.0 / c["fps"]
    i = 0
    while i < n and not on_new[i]:
        i += 1
    if i == n:
        return c
    k = 0
    while k < n:
        idx = (i + k) % n
        if on_new[idx]:
            k += 1
            continue
        run = []
        while k < n and not on_new[(i + k) % n]:
            run.append((i + k) % n)
            k += 1
        T = (len(run) + 1) * dt
        for m, fidx in enumerate(run):
            t = (m + 1) * dt
            lift = .5 * arc * t * (T - t)
            p, q = c["joints"]["Root"][fidx]
            c["joints"]["Root"][fidx] = (Vector((p.x, p.y + lift, p.z)), q)
    return c


LEG_LIMIT = 2000      # deg/s, under the engine's AUTHORED_SPEED (2200)
GLIDE_LIMIT = .15     # share of the body speed a counted floor foot may slide
MIN_STANCE_S = .05    # seconds a foot bears weight, at least, per step


def stance_runs(c):
    on = contact_frames(c)
    n = len(on)
    runs, k = [], 0
    if all(on) or not any(on):
        return [n] if all(on) else []
    start = on.index(False)
    cur = 0
    for i in range(n):
        if on[(start + i) % n]:
            cur += 1
        elif cur:
            runs.append(cur)
            cur = 0
    if cur:
        runs.append(cur)
    return runs


CADENCE_MAX = 1.8    # engine cap on the playback rate


def glide(c, speed, axis="z", back=False):
    """Python twin of tests/Locomotion.spec: how fast a foot that the engine
    counts as on the floor (both ends under ANKLE_Y+.2) moves in the world, as
    a share of the body's speed, at the playback rate the engine picks."""
    stride = contact_stride(c, axis, back)
    if stride <= 0:
        return 9.0
    f = c["length"] * speed / stride
    if f > CADENCE_MAX * 1.03:   # the engine holds the feet itself then
        return 0.0
    # Uncapped, the engine plays the drawn foot as is: measured in the engine
    # harness (Locomotion.spec) that slid 20-95 % on bounded runs, so the fit
    # keeps the cadence at the cap (the twin below is only a lower bound).
    return 9.0
    pts = ankles(c)
    N = len(pts)
    body = speed / (c["fps"] * f)
    tot, n = 0.0, 0
    for k in range(N if c["loop"] else N - 1):
        for side in (0, 1):
            a, b = pts[k][side], pts[(k + 1) % N][side]
            if a.y - ANKLE_Y < .2 and b.y - ANKLE_Y < .2:
                d = (b.x - a.x) if axis == "x" else ((a.z - b.z) if back else (b.z - a.z))
                tot += abs(d - body) / body
                n += 1
    return tot / max(n, 1)


def bound_fitted(c, want, arc, speed, axis="z", back=False):
    """bound() with the strongest squeeze down to `want` that keeps the legs
    under LEG_LIMIT at `speed` and every stance at MIN_STANCE frames."""
    best = None
    sq = 1.0
    # the legs may not get faster than the clip's own (or LEG_LIMIT)
    limit = max(LEG_LIMIT, peak_leg_speed(c, speed, contact_stride(c, axis, back)))
    slide = GLIDE_LIMIT
    while sq >= want - 1e-6:
        trial = bound(copy(c), sq, arc)
        stride = contact_stride(trial, axis, back)
        runs = stance_runs(trial)
        if not (stride <= .5 or not runs or min(runs) / trial["fps"] < MIN_STANCE_S - 1e-6 or peak_leg_speed(trial, speed, stride) > limit
                or glide(trial, speed, axis, back) > slide):
            best = (sq, trial)
        sq = round(sq - .05, 3)
    if best is None:
        return c, 1.0
    c["joints"], c["frames"], c["length"] = best[1]["joints"], best[1]["frames"], best[1]["length"]
    return c, best[0]


# How each fighter bounds (anim lot 2): stance squeeze (smaller = shorter,
# quicker contact, longer flight) and the arc's gravity (bigger = a lower,
# snappier bound for the same flight time).
BOUND = {
    #             run  (squeeze, arc)   sprint (squeeze, arc)
    "Lion":       ((.55, 110),           (.40, 120)),
    "Legion":     ((.45, 50),            (.35, 90)),     # big airy bounds
    "Copycat":    ((.62, 140),           (.45, 150)),    # low, economical
    "Flashstep":  ((.85, 60),            (.50, 190)),    # short quick steps, flat
    "Mirage":     ((.60, 150),           (.45, 160)),    # smooth, little rise
    "Leaf":       ((.42, 50),            (.32, 100)),    # explosive push
    "GentleFist": ((.60, 140),           (.45, 150)),
    "Sand":       ((.85, 170),           (.80, 160)),    # heavy, low; the sand moves him
}


def gait(fid, clip, c):
    stride, knee, cadence, bnc, twist, arms, lean, head, elbow = GAIT[fid]
    forward = clip.endswith(".F")
    soft = 1.0 if forward else .5          # the other directions take half of it
    walk = clip.startswith("Walk")
    w = .6 if walk else 1.0
    ref = min(min(a.y, b.y) for a, b in ankles(c))
    for j in LEGS:
        amp(c, j, 1 + (stride - 1) * soft * w)
    for j in KNEES:
        amp(c, j, 1 + (knee - 1) * soft * w)
    amp(c, "Waist", 1 + (twist - 1) * w)
    for j in ARMS:
        amp(c, j, 1 + (arms - 1) * w)
    if elbow:
        # elbows a little more (+) or less (-) bent, the same on both sides
        turn(c, "RightElbow", pitch=elbow * w)
        turn(c, "LeftElbow", pitch=elbow * w)
    if lean and forward:
        turn(c, "Waist", pitch=lean * w)
    if head:
        turn(c, "Neck", pitch=head * w)
    bounce(c, 1 + (bnc - 1) * w)
    if cadence != 1.0 and not walk:
        retime(c, cadence)
    if not walk:
        squeeze, arc = BOUND[fid][0]
        if squeeze < 1:
            axis, back = axis_of(clip)
            upsample(c)
            c, used = bound_fitted(c, 1 - (1 - squeeze) * (1 if forward else .7), arc, 19, axis, back)
            c["_squeeze"] = used
    ground(c, ref)
    return c


def sprint(fid, c):
    stride, knee, lean = SPRINT[fid]
    _, _, _, bnc, twist, arms, _, head, elbow = GAIT[fid]
    ref = min(min(a.y, b.y) for a, b in ankles(c))
    for j in LEGS:
        amp(c, j, stride)
    for j in KNEES:
        amp(c, j, knee)
    # the fighter's own carriage, as in his run (the arms stay swept back)
    amp(c, "Waist", twist)
    for j in ARMS:
        amp(c, j, arms)
    if elbow:
        turn(c, "RightElbow", pitch=elbow * .6)
        turn(c, "LeftElbow", pitch=elbow * .6)
    bounce(c, bnc)
    if lean:
        turn(c, "Waist", pitch=lean)
    # (the extra lean of the chest is carried by the head looking up again)
    turn(c, "Neck", pitch=-lean * .6 + head)
    squeeze, arc = BOUND[fid][1]
    upsample(c)
    c, used = bound_fitted(c, squeeze, arc, 45)
    c["_squeeze"] = used
    ground(c, ref)
    return c


def build(clips, fighters):
    out = {}
    for fid in fighters:
        for clip in RUNS + WALKS:
            if (fid, clip) in clips:
                out[(fid, clip)] = gait(fid, clip, copy(clips[(fid, clip)]))
        if (fid, "Sprint") in clips:
            out[(fid, "Sprint")] = sprint(fid, copy(clips[(fid, "Sprint")]))
    return out


# ---------------------------------------------------------------- reports
def axis_of(clip):
    return ("x", False) if clip.endswith((".L", ".R")) else ("z", clip.endswith(".B"))


def angle_between(a, b):
    return math.degrees(abs(_log(a.rotation_difference(b)).length))


def similarity(c1, c2, N=24):
    tot = n = 0
    for j in c1["joints"]:
        if j not in c2["joints"]:
            continue
        q1, q2 = _rot(c1, j), _rot(c2, j)
        for k in range(N):
            t = k / (N - 1)
            tot += angle_between(q1[min(len(q1) - 1, int(t * (len(q1) - 1)))], q2[min(len(q2) - 1, int(t * (len(q2) - 1)))])
            n += 1
    return tot / max(n, 1)


def peak_leg_speed(c, speed, stride):
    """deg/s of the fastest leg joint when the engine plays the cycle at `speed`
    (cadence = speed / stride, capped at 1.8x the drawn rate)."""
    rate = min(speed / max(stride, .5), 1.8 / max(c["length"], .2))
    scale = rate * c["length"]           # how much faster than drawn
    peak = 0
    for j in LEGS + KNEES:
        qs = c["joints"][j]
        for i in range(len(qs)):
            peak = max(peak, angle_between(qs[i], qs[(i + 1) % len(qs)]) * c["fps"] * scale)
    return peak


def sheet(path, rows, title):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    cols = 8
    fig, axes = plt.subplots(len(rows), cols, figsize=(cols * 1.6, len(rows) * 2.6))
    if len(rows) == 1:
        axes = [axes]
    segs = [("Root", "Waist"), ("Waist", "Neck"), ("Neck", "Head"),
            ("Right", "RightElbow"), ("RightElbow", "RightWrist"), ("RightWrist", "RightHand"),
            ("Left", "LeftElbow"), ("LeftElbow", "LeftWrist"), ("LeftWrist", "LeftHand"),
            ("RightHip", "RightKnee"), ("RightKnee", "RightAnkle"), ("RightAnkle", "RightToe"),
            ("LeftHip", "LeftKnee"), ("LeftKnee", "LeftAnkle"), ("LeftAnkle", "LeftToe"),
            ("RightHip", "LeftHip"), ("Right", "Left")]
    for r, (label, c) in enumerate(rows):
        for k in range(cols):
            ax = axes[r][k]
            i = int(k * c["frames"] / cols)
            p = fk(pose_at(c, i))
            for a, b in segs:
                col = "#c0392b" if a.startswith("Right") or b.startswith("Right") else ("#2c3e50" if "Left" in a + b else "#7f8c8d")
                ax.plot([-p[a].z, -p[b].z], [p[a].y, p[b].y], color=col, lw=2.2, solid_capstyle="round")
            ax.axhline(ANKLE_Y - .2, color="#bbb", lw=1)
            ax.set_xlim(-3, 3)
            ax.set_ylim(-3.3, 4.6)
            ax.set_aspect("equal")
            ax.axis("off")
            if k == 0:
                ax.set_title(label, fontsize=8, loc="left")
    fig.suptitle(title, fontsize=10)
    fig.tight_layout()
    fig.savefig(path, dpi=70)
    plt.close(fig)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "report"
    fighters = sys.argv[2].split(",") if len(sys.argv) > 2 else BETA
    clips = load()
    new = build(clips, fighters)
    if mode == "report":
        print("clip                   stride avant->après (studs)  cadence x à 19/45   pic jambe °/s")
        for (fid, clip), c in sorted(new.items()):
            if clip not in ("Run.F", "Sprint", "Run.L", "Run.B"):
                continue
            axis, back = axis_of(clip)
            o = clips[(fid, clip)]
            s0, s1 = contact_stride(o, axis, back), contact_stride(c, axis, back)
            v = 45 if clip == "Sprint" else 19
            print("%-8s %-7s sq %.2f %5.2f -> %5.2f   len %.2f->%.2f   glisse %3.0f%% -> %3.0f%%   x%.2f -> x%.2f   %5.0f -> %5.0f" % (
                NAME[fid], clip, c.get("_squeeze", 1), s0, s1, o["length"], c["length"],
                glide(o, v, axis, back) * 100, glide(c, v, axis, back) * 100,
                (v / max(s0, .5)) * o["length"], (v / max(s1, .5)) * c["length"],
                peak_leg_speed(o, v, s0), peak_leg_speed(c, v, s1)))
        print()
        print("ressemblance avec Sasuke (écart moyen, degrés) : avant -> après")
        for clip in ("Run.F", "Sprint", "Walk.F"):
            row = []
            for fid in BETA:
                if fid == "Lion" or (fid, clip) not in clips:
                    continue
                before = similarity(clips[("Lion", clip)], clips[(fid, clip)])
                after = similarity(new.get(("Lion", clip), clips[("Lion", clip)]), new.get((fid, clip), clips[(fid, clip)]))
                row.append("%s %.0f->%.0f" % (NAME[fid], before, after))
            print("%-7s %s" % (clip, "  ".join(row)))
    elif mode == "sheets":
        out = os.environ.get("ND_SHEETS", "/tmp/loco_v2")
        os.makedirs(out, exist_ok=True)
        for fid in fighters:
            rows = []
            for clip in ("Run.F", "Sprint"):
                if (fid, clip) in new:
                    rows.append(("%s %s avant" % (NAME[fid], clip), clips[(fid, clip)]))
                    rows.append(("%s %s après" % (NAME[fid], clip), new[(fid, clip)]))
            sheet(os.path.join(out, "%s.png" % NAME[fid]), rows, "Locomotion v2 — %s (vue de profil, 8 images par cycle)" % NAME[fid])
        print("sheets in", out)
    elif mode == "write":
        for key, c in new.items():
            clips[key] = c
        write(clips, list(new))
        print("written", len(new), "clips")


if __name__ == "__main__":
    main()
