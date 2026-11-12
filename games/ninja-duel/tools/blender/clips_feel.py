"""Feel audit 07/11, the animator's part (mission « finir l'audit feel »,
12/11), authored pose to pose on the control rig (nd_ctrl / nd_shot), like
clips_react2. Same conventions: yaw + turns the body to its right, roll -
leans it to its left, x right, z back, feet are WORLD positions (planted = the
same value on consecutive keys).

  F.Launched.Back / .Side       thrown up by a blow from behind / on the right
  F.Knockback.Back / .Side      thrown along the floor, same
  F.Grabbed / .Back / .Side     held (loops): by the collar from the front, an
                                arm round the throat from behind, by the
                                right arm from the right
     (Hit.Back / Hit.Side already exist, clips_react2.) The ".Side" clips are
     struck on the RIGHT, the body goes to its left (-x), as Hit.Side: the
     engine's mirror (side < 0) gives the left.
  F.Guard.Step.B / F / L / R    the guard moving: pas chassés, the feet never
                                cross, one foot always holds the floor
                                (nd_shot.cycle plants it), authored at STEP_SPEED
  F.Guard.Skid                  pushed back faster than any step (33 studs/s
                                measured): braced, the front heel digging in
  F.Pivot.R90 / R180 / L90 / L180   a strike started off the opponent: the
                                HumanoidRootPart turns at the engine's
                                1800 deg/s, the body follows late (head first,
                                then chest, hips last) and the feet step round
  Flashstep.LightningStrike.Arrive, Copycat.LightningCut.Arrive
                                the landing out of a one-frame relocation
"""
import math
from nd_shot import Shot, merge, cycle
from clips_react2 import Body, add, setv

STEP_SPEED = 6.0      # studs/s the guard steps are authored at (the engine scales the cadence)
STEP_PERIOD = 22      # frames at 60 fps for a full cycle (two steps)
STEP_STRIDE = STEP_SPEED * STEP_PERIOD / 60.0   # 2.2 studs: the feet never cross (stance 1.1+ apart)
TURN_SPEED = 1800.0   # deg/s, the engine's turn of the HumanoidRootPart


def guard_pose(b):
    S = b.stance
    g = add(S, {"root": {"y": -.14, "z": .1, "pitch": -2}, "torso": {"pitch": 6, "yaw": 4}, "head": {"pitch": 14, "yaw": 6}})
    return setv(g, b.guard_arms or {"ra": {"raise": 92, "out": -34, "twist": 42, "elbow": 114, "wrist": -10},
                                    "la": {"raise": 96, "out": -30, "twist": 40, "elbow": 110, "wrist": -10}})


# ------------------------------------------------------------- flights
def flights_dir(b, arm):
    """A blow from behind throws the hips FORWARD first (the body arches, the
    head goes back, the arms fly back), then the body is carried forward,
    leaning into the flight, the legs trailing behind toward the attacker.
    On the right: the ribs go in, the body is thrown to its left, rolled, the
    legs trail to the right (toward him), the struck arm clamps the ribs, the
    far arm flies up; the head turns back to find him."""
    S = b.stance
    out = []
    # Knockback.Back
    arch = setv(S, {"root": {"x": 0, "y": -.12, "z": -.3, "pitch": -14, "yaw": 0, "roll": 0}, "torso": {"pitch": -20, "yaw": 0, "roll": 0},
                    "head": {"pitch": -26, "yaw": 8, "roll": 0},
                    "ra": {"raise": -34, "out": 40, "twist": 0, "elbow": 30, "wrist": 0}, "la": {"raise": -30, "out": 38, "twist": 0, "elbow": 26, "wrist": 0},
                    "rf": {"x": .05, "z": .5, "y": .4, "toe": 30, "yaw": 0, "knee": 0}, "lf": {"x": -.05, "z": .2, "y": .2, "toe": 20, "yaw": 0, "knee": 0}})
    fly = setv(S, {"root": {"x": 0, "y": -.2, "z": 0, "pitch": 38, "yaw": 0, "roll": -6}, "torso": {"pitch": 12, "yaw": -8, "roll": 0},
                   "head": {"pitch": -24, "yaw": 0, "roll": 0},
                   "ra": {"raise": -40, "out": 44, "twist": 0, "elbow": 32, "wrist": 0}, "la": {"raise": -32, "out": 40, "twist": 0, "elbow": 28, "wrist": 0},
                   "rf": {"x": .05, "z": 1.25, "y": 1.1, "toe": 34, "yaw": 0, "knee": 0}, "lf": {"x": -.05, "z": .85, "y": .7, "toe": 26, "yaw": 0, "knee": 0}})
    drift = add(fly, {"root": {"pitch": 6}, "ra": {"raise": -8, "elbow": 8}, "la": {"raise": 10, "elbow": 10},
                      "rf": {"y": -.15, "z": -.2}, "lf": {"y": .25, "z": .25}})
    kb = Shot(arm, b.F + "Knockback.Back")
    kb.key(0, S, "ease").key(b.f(4), arch, "impact").key(12, fly, "pass").key(24, drift, "ease").key(36, fly, "ease")
    kb.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 2)
    out.append(kb.build(markers={"loop": 12 / 60}))
    # Knockback.Side
    bend = setv(S, {"root": {"x": -.2, "y": -.14, "z": 0, "pitch": 4, "yaw": -14, "roll": -16}, "torso": {"pitch": 8, "yaw": -18, "roll": -18},
                    "head": {"pitch": 0, "yaw": -14, "roll": -12},
                    "ra": {"raise": 30, "out": -6, "twist": 20, "elbow": 118, "wrist": 0}, "la": {"raise": 50, "out": 60, "twist": 0, "elbow": 36, "wrist": 0}})
    side = setv(S, {"root": {"x": 0, "y": -.25, "z": 0, "pitch": -4, "yaw": -10, "roll": -38}, "torso": {"pitch": 4, "yaw": -6, "roll": -12},
                    "head": {"pitch": -6, "yaw": 30, "roll": 16},
                    "ra": {"raise": 34, "out": -4, "twist": 20, "elbow": 116, "wrist": 0}, "la": {"raise": 86, "out": 66, "twist": 0, "elbow": 30, "wrist": 0},
                    "rf": {"x": 1.0, "z": .1, "y": .95, "toe": -10, "yaw": 0, "knee": 10}, "lf": {"x": .7, "z": -.15, "y": .55, "toe": -14, "yaw": 0, "knee": 10}})
    side2 = add(side, {"root": {"roll": 6}, "la": {"raise": -10, "elbow": 10}, "rf": {"y": -.15, "x": -.1}, "lf": {"y": .2, "x": .1}})
    ks = Shot(arm, b.F + "Knockback.Side")
    ks.key(0, S, "ease").key(b.f(4), bend, "impact").key(12, side, "pass").key(24, side2, "ease").key(36, side, "ease")
    ks.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 2)
    out.append(ks.build(markers={"loop": 12 / 60}))
    # Launched.Back
    whip = merge(arch, {"root": {"y": -.1, "pitch": -20}, "torso": {"pitch": -30}, "head": {"pitch": -40},
                        "rf": {"x": 0, "z": .2, "y": .3, "toe": 40}, "lf": {"x": 0, "z": -.05, "y": .1, "toe": 40}})
    up = setv(S, {"root": {"x": 0, "y": -.45, "z": 0, "pitch": 16, "yaw": 0, "roll": -6}, "torso": {"pitch": 18, "yaw": 10, "roll": 0},
                  "head": {"pitch": -22, "yaw": 0, "roll": 0},
                  "ra": {"raise": -14, "out": 52, "twist": 0, "elbow": 34, "wrist": 0}, "la": {"raise": -10, "out": 46, "twist": 0, "elbow": 30, "wrist": 0},
                  "rf": {"x": .05, "z": .8, "y": 1.3, "toe": 30, "yaw": 0, "knee": 6}, "lf": {"x": -.05, "z": .3, "y": .9, "toe": 30, "yaw": 0, "knee": 6}})
    trail = add(up, {"ra": {"raise": 12, "out": 6}, "la": {"raise": -8}, "torso": {"roll": 6}, "rf": {"y": -.2, "z": -.2}, "lf": {"y": .2, "z": .2}})
    la = Shot(arm, b.F + "Launched.Back")
    la.key(0, S, "ease").key(3, whip, "impact").key(12, up, "ease").key(30, trail, "ease").key(48, up, "ease")
    la.drag(["shoulder.L", "shoulder.R"], 2)
    out.append(la.build(markers={"loop": 12 / 60}))
    # Launched.Side
    whip_s = merge(bend, {"root": {"y": -.1, "roll": -22, "x": -.14}, "torso": {"roll": -24}, "head": {"roll": -20, "yaw": 16},
                          "rf": {"x": .3, "z": .1, "y": .3, "toe": -20}, "lf": {"x": .1, "z": -.1, "y": .1, "toe": -20}})
    up_s = setv(S, {"root": {"x": 0, "y": -.45, "z": 0, "pitch": -8, "yaw": -8, "roll": -30}, "torso": {"pitch": -6, "yaw": -6, "roll": -10},
                    "head": {"pitch": -10, "yaw": 26, "roll": 12},
                    "ra": {"raise": 30, "out": -2, "twist": 20, "elbow": 116, "wrist": 0}, "la": {"raise": 60, "out": 70, "twist": 0, "elbow": 34, "wrist": 0},
                    "rf": {"x": .8, "z": .1, "y": 1.2, "toe": -20, "yaw": 0, "knee": 8}, "lf": {"x": .5, "z": -.2, "y": .8, "toe": -24, "yaw": 0, "knee": 8}})
    trail_s = add(up_s, {"la": {"raise": -12}, "root": {"roll": 6}, "rf": {"y": -.2}, "lf": {"y": .2}})
    ls = Shot(arm, b.F + "Launched.Side")
    ls.key(0, S, "ease").key(3, whip_s, "impact").key(12, up_s, "ease").key(30, trail_s, "ease").key(48, up_s, "ease")
    ls.drag(["shoulder.L", "shoulder.R"], 2)
    out.append(ls.build(markers={"loop": 12 / 60}))
    return out


# --------------------------------------------------------------- grabs
def grabs(b, arm):
    """Held. Front: by the collar, lifted onto his toes and leaned back, both
    hands on the wrist that holds him, he pulls at it and kicks. Back: an arm
    round the throat, pulled back onto his heels (toes up), the hands claw at
    the forearm over his shoulder, the head twists to see him. Side: held by
    the right arm from the right, turned toward the grip; he leans away, the
    other hand pushes at the grip across his body."""
    S = b.stance
    out = []
    lf0, rf0 = b.foot("L"), b.foot("R")
    front = setv(S, {"root": {"x": 0, "y": -.04, "z": .18, "pitch": -12, "yaw": 0, "roll": 0}, "torso": {"pitch": -8, "yaw": 0, "roll": 0},
                     "head": {"pitch": -18, "yaw": 0, "roll": 0},
                     "ra": {"raise": 84, "out": -30, "twist": 20, "elbow": 100, "wrist": -10}, "la": {"raise": 80, "out": -28, "twist": 20, "elbow": 104, "wrist": -10},
                     "lf": dict(lf0, toe=-16), "rf": dict(rf0, toe=-12)})
    pull = add(front, {"torso": {"yaw": 10, "pitch": 4}, "root": {"yaw": 6}, "ra": {"elbow": 18, "raise": -6}, "la": {"elbow": -8}})
    pull = merge(pull, {"rf": dict(rf0, y=.18, toe=10)})
    pull2 = add(front, {"torso": {"yaw": -10, "pitch": 4}, "root": {"yaw": -6}, "la": {"elbow": 18, "raise": -6}, "ra": {"elbow": -8}})
    g = Shot(arm, b.F + "Grabbed")
    g.key(0, front, "ease").key(14, pull, "ease").key(27, front, "ease").key(41, pull2, "ease").key(54, front, "ease")
    g.drag(["neck"], 2)
    out.append(g.build(loop=True))

    back = setv(S, {"root": {"x": 0, "y": -.1, "z": .24, "pitch": -16, "yaw": 0, "roll": 0}, "torso": {"pitch": -12, "yaw": 0, "roll": 0},
                    "head": {"pitch": -24, "yaw": 18, "roll": 0},
                    "ra": {"raise": 128, "out": -10, "twist": 30, "elbow": 140, "wrist": -10}, "la": {"raise": 124, "out": -6, "twist": 30, "elbow": 136, "wrist": -10},
                    "lf": dict(lf0, toe=-26), "rf": dict(rf0, toe=-20)})
    twist = add(back, {"head": {"yaw": -32}, "torso": {"yaw": -10}, "ra": {"elbow": -14}, "la": {"elbow": 10}})
    twist = merge(twist, {"lf": dict(lf0, y=.12, toe=-10)})
    twist2 = add(back, {"head": {"yaw": 6}, "torso": {"yaw": 8}, "la": {"elbow": -14}, "ra": {"elbow": 10}})
    gb = Shot(arm, b.F + "Grabbed.Back")
    gb.key(0, back, "ease").key(14, twist, "ease").key(27, back, "ease").key(41, twist2, "ease").key(54, back, "ease")
    gb.drag(["shoulder.L", "shoulder.R"], 2)
    out.append(gb.build(loop=True))

    side = setv(S, {"root": {"x": .12, "y": -.12, "z": 0, "pitch": 2, "yaw": 20, "roll": 10}, "torso": {"pitch": 4, "yaw": 16, "roll": 6},
                    "head": {"pitch": -4, "yaw": 34, "roll": 0},
                    "ra": {"raise": 56, "out": 46, "twist": 0, "elbow": 36, "wrist": 0}, "la": {"raise": 70, "out": -40, "twist": 20, "elbow": 96, "wrist": -10},
                    "lf": b.foot("L", dx=-.12, toe=6), "rf": dict(rf0, toe=-8)})
    lean = add(side, {"root": {"x": -.08, "roll": -6, "yaw": -8}, "torso": {"roll": -8, "yaw": -6}, "la": {"elbow": -20, "raise": 8}, "ra": {"elbow": 10}})
    lean2 = add(side, {"root": {"x": .04, "yaw": 4}, "head": {"yaw": 8}, "la": {"elbow": 10}})
    gs = Shot(arm, b.F + "Grabbed.Side")
    gs.key(0, side, "ease").key(14, lean, "ease").key(27, side, "ease").key(41, lean2, "ease").key(54, side, "ease")
    gs.drag(["shoulder.L", "shoulder.R"], 2)
    out.append(gs.build(loop=True))
    return out


# ---------------------------------------------------------- guard steps
def guard_steps(b, arm):
    """Pas chassés in guard. The foot on the side he goes to leads (the rear
    foot going back, the front one going forward, the left one going left),
    the other follows and closes; one foot always holds the floor, the feet
    never cross (STEP_STRIDE < the stance's spread). The body bobs a little
    as each foot lands; the guard itself does not move."""
    g = guard_pose(b)
    S = b.stance
    rear = "rf" if S["rf"].get("z", 0) > S["lf"].get("z", 0) else "lf"
    front = "lf" if rear == "rf" else "rf"
    q = STEP_STRIDE / 4
    out = []
    for suffix, d, lead in (("B", (0.0, 1.0), rear), ("F", (0.0, -1.0), front), ("L", (-1.0, 0.0), "lf"), ("R", (1.0, 0.0), "rf")):
        trail = "rf" if lead == "lf" else "lf"

        def at(foot, k, y=0.0):
            st = S[foot]
            return {"x": st.get("x", 0) + k * q * d[0], "z": st.get("z", 0) + k * q * d[1], "y": y, "yaw": st.get("yaw", 0), "toe": 8 if y else 0, "knee": 0}
        bob = {"root": {"y": g["root"]["y"] - .05}}
        # the swinging foot leaves the floor on the frame after its plant ends
        # and is on it again only at its next plant (a low chassé, not a slide)
        keys = [
            (0.0, merge(g, {lead: at(lead, -1), trail: at(trail, 1)}), "ease"),
            (0.06, merge(g, {lead: at(lead, -.8, .1), trail: at(trail, .8)}), "ease"),
            (0.25, merge(g, {lead: at(lead, 0, .16), trail: at(trail, 0)}), "ease"),
            (0.44, merge(g, {lead: at(lead, .8, .09), trail: at(trail, -.8)}), "ease"),
            (0.5, merge(merge(g, bob), {lead: at(lead, 1), trail: at(trail, -1)}), "ease"),
            (0.56, merge(g, {lead: at(lead, .8), trail: at(trail, -.8, .1)}), "ease"),
            (0.75, merge(g, {lead: at(lead, 0), trail: at(trail, 0, .14)}), "ease"),
            (0.94, merge(g, {lead: at(lead, -.8), trail: at(trail, .8, .09)}), "ease"),
        ]
        plant = {lead[0].upper(): (.5, 1.0), trail[0].upper(): (0.0, .5)}
        sh = cycle(arm, b.F + "Guard.Step." + suffix, STEP_STRIDE, STEP_PERIOD, keys, plant, direction=d, mirror_half=False)
        sh.drag(["shoulder.L", "shoulder.R"], 1)
        out.append(sh.build(loop=True, meta={"speed": STEP_SPEED}))
    # Guard.Skid: braced, leaning into the push, the front heel digging in,
    # the rear leg bent under the weight; a tremor (the floor under the heel).
    skid = add(g, {"root": {"y": -.32, "z": .08, "pitch": 10}, "torso": {"pitch": 10}, "head": {"pitch": 6}})
    skid = merge(skid, {rear: b.foot(rear[0].upper(), dz=.32), front: b.foot(front[0].upper(), dz=-.18, toe=-22)})
    shake = add(skid, {"root": {"y": .025, "roll": 1.5}, "torso": {"pitch": -1.5}})
    sk = Shot(arm, b.F + "Guard.Skid")
    sk.key(0, skid, "ease").key(4, shake, "ease").key(9, skid, "ease").key(13, add(skid, {"root": {"roll": -1.5}}), "ease").key(18, skid, "ease")
    out.append(sk.build(loop=True, meta={"skid": 1}))
    return out


# ---------------------------------------------------------------- pivot
def _rot(x, z, psi):
    c, s = math.cos(math.radians(psi)), math.sin(math.radians(psi))
    return x * c - z * s, x * s + z * c


def _foot_world(S, foot, psi, y=0.0, toe=0):
    st = S[foot]
    off = .5 if foot == "rf" else -.5
    X, Z = _rot(off + st.get("x", 0), st.get("z", 0), psi)
    return {"x": X - off, "z": Z, "y": y, "yaw": st.get("yaw", 0) + psi, "toe": toe, "knee": 0}


def pivots(b, arm):
    """The HumanoidRootPart turns at the engine's speed; the body is late:
    the head finds the opponent first, the chest follows, the hips last (they
    overshoot a little and settle); the front foot turns on its ball and
    re-plants, the rear foot swings round wide. The strike that follows
    starts from the stance, turned."""
    S = b.stance
    out = []
    for name, ang in (("R90", 90), ("R180", 180), ("L90", -90), ("L180", -180)):
        sgn = 1 if ang > 0 else -1
        a = abs(ang)
        turn_f = max(2, int(round(a / TURN_SPEED * 60)))   # frames the root needs
        sh = Shot(arm, b.F + "Pivot." + name)
        lf0, rf0 = _foot_world(S, "lf", 0), _foot_world(S, "rf", 0)
        lf1, rf1 = _foot_world(S, "lf", ang), _foot_world(S, "rf", ang)

        def mid(f0, f1, k, y):
            # round the body on an arc (a straight line from a foot to its
            # turned place goes through the other leg on a half turn)
            foot = "lf" if f0 is lf0 else "rf"
            return _foot_world(S, foot, ang * k, y=y, toe=10 if y else 0)

        def body(lag, chest, head, extra=None):
            spec = add(S, {"root": {"yaw": -lag * sgn, "y": -.08}, "torso": {"yaw": chest * sgn}, "head": {"yaw": head * sgn}})
            return merge(spec, extra or {})
        # the pivot foot turns on its ball (same spot, yaw follows the body)
        ball = dict(lf0, yaw=lf0["yaw"] + ang * .5, toe=-10)
        sh.key(0, merge(S, {"travel": {"yaw": 0}, "lf": lf0, "rf": rf0}), "ease")
        sh.key(1, merge(S, {"travel": {"yaw": ang / turn_f}, "lf": lf0, "rf": mid(rf0, rf1, .04, .12)}), "ease")
        sh.key(turn_f, merge(body(a * .72, a * .2, min(60, a * .45), {"ra": {"raise": S["ra"].get("raise", 30) + 10, "out": S["ra"].get("out", 0) + 22}}),
                             {"travel": {"yaw": ang}, "lf": ball, "rf": mid(rf0, rf1, .35, .3)}), "impact")
        sh.key(turn_f + 1, merge(body(a * .62, a * .17, min(50, a * .38)), {"travel": {"yaw": ang}, "lf": mid(lf0, lf1, .08, .1), "rf": mid(rf0, rf1, .45, .3)}), "pass")
        sh.key(turn_f + 4, merge(body(a * .3, a * .08, 6), {"travel": {"yaw": ang}, "lf": mid(lf0, lf1, .5, .14), "rf": mid(rf0, rf1, .8, .22)}), "pass")
        sh.key(turn_f + 7, merge(body(-3, -2, 0), {"travel": {"yaw": ang}, "lf": mid(lf0, lf1, .92, .06), "rf": mid(rf0, rf1, .96, .06)}), "pass")
        sh.key(turn_f + 8, merge(body(-6, -3, 0), {"travel": {"yaw": ang}, "lf": lf1, "rf": rf1}), "impact")
        sh.key(turn_f + 12, merge(S, {"travel": {"yaw": ang}, "lf": lf1, "rf": rf1}), "ease")
        sh.drag(["shoulder.L", "shoulder.R"], 1)
        out.append(sh.build(meta={"turn": ang, "rootFrames": turn_f}))
    return out


# -------------------------------------------------------------- arrivals
def arrivals(b, arm, fighter):
    """Out of a one-frame relocation, the body lands where the momentum
    still is: low, wide, the blade arm carried through behind him (the cut is
    already done), then he comes up into his stance facing the body he went
    through. Minato: the kunai low behind, the free hand near the floor.
    Kakashi: the Lightning Cut's arm held out level behind (the blade drawn
    out of the body), the left forearm in guard."""
    S = b.stance
    out = []
    if fighter == "Flashstep":
        name = "Flashstep.LightningStrike.Arrive"
        land = setv(S, {"root": {"x": 0, "y": -1.0, "z": .1, "pitch": 18, "yaw": 10, "roll": 0}, "torso": {"pitch": 10, "yaw": 8, "roll": 0},
                        "head": {"pitch": -16, "yaw": -8, "roll": 0},
                        "ra": {"raise": 34, "out": 64, "twist": 0, "elbow": 10, "wrist": -20}, "la": {"raise": 20, "out": 34, "twist": 0, "elbow": 22, "wrist": 0},
                        "lf": b.foot("L", dz=-.4, dx=-.1), "rf": b.foot("R", dz=.4, dx=.12, toe=-20)})
    elif fighter == "Copycat":
        name = "Copycat.LightningCut.Arrive"
        land = setv(S, {"root": {"x": 0, "y": -.9, "z": .1, "pitch": 14, "yaw": -18, "roll": 0}, "torso": {"pitch": 8, "yaw": -16, "roll": 0},
                        "head": {"pitch": -12, "yaw": 18, "roll": 0},
                        "ra": {"raise": 72, "out": 84, "twist": -20, "elbow": 8, "wrist": 0}, "la": {"raise": 60, "out": -16, "twist": -20, "elbow": 96, "wrist": -10},
                        "lf": b.foot("L", dz=-.38, dx=-.1), "rf": b.foot("R", dz=.38, dx=.1, toe=-18)})
    else:
        return out
    deep = add(land, {"root": {"y": -.12, "pitch": 4}, "torso": {"pitch": 3}})
    hold = add(land, {"root": {"y": -.05}, "ra": {"raise": -6, "out": -8}})
    rise = merge(add(S, {"root": {"y": -.3}}), {"lf": land["lf"], "rf": land["rf"]})
    lift = merge(add(S, {"root": {"y": -.24}}), {"lf": land["lf"], "rf": dict(land["rf"], y=.16, toe=0)})
    step = merge(S, {"lf": land["lf"], "rf": b.foot("R", dz=.2, y=.22)})
    sh = Shot(arm, name)
    sh.key(0, land, "impact").key(4, deep, "impact").key(11, hold, "ease").key(15, rise, "pass").key(18, lift, "pass").key(21, step, "pass").key(24, merge(S, {"lf": land["lf"]}), "ease")
    sh.drag(["shoulder.L", "shoulder.R"], 2).drag(["neck"], 1)
    out.append(sh.build(markers={"land": 0.0, "up": 15 / 60}))
    return out


def author(arm, fighter, stance, tempo=1.0, give=1.0, guard_arms=None):
    b = Body(fighter, stance, tempo, give, guard_arms)
    acts = []
    acts += flights_dir(b, arm)
    acts += grabs(b, arm)
    acts += guard_steps(b, arm)
    acts += pivots(b, arm)
    acts += arrivals(b, arm, fighter)
    return acts
