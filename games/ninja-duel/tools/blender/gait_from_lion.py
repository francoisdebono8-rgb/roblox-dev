"""Sasuke's authored gait mechanics (clips_lion2: planted feet, strides,
duty factors, the weight over the support foot) re-acted on another body
(DEC-030). The legs keep the mechanics that already pass the slide and
balance checks; the upper body, the stance and the spacing of the torso are
the fighter's own, through `act(spec)` and his STANCE / guard arms.

Usage: gait(arm, "Legion.", STANCE, GUARD, act, arms={"walk": 1, "run": .9, "jump": 1})
returns the actions Walk.F/B/L/R, Run.F/B/L/R, Sprint, Start, Brake, Land,
Jump.Air, Jump.Leap named for the fighter.
"""
import copy
import nd_shot
import clips_lion2 as L2


def gait(arm, prefix, stance, guard, act, arms=None):
    arms = arms or {}
    saved = (L2.STANCE, L2.GUARD_WALK, nd_shot.Shot.key)
    orig = nd_shot.Shot.key
    scale = {"arms": 1.0}

    def filt(spec):
        out = act(copy.deepcopy(spec))
        k = scale["arms"]
        if k != 1.0:
            for side in ("la", "ra"):
                a = out.get(side)
                if a and "raise" in a:
                    a["raise"] *= k
        return out

    def key(self, frame, spec, spacing="ease"):
        return orig(self, frame, filt(spec), spacing)
    L2.STANCE, L2.GUARD_WALK = stance, guard
    nd_shot.Shot.key = key
    acts = []
    try:
        scale["arms"] = arms.get("walk", 1.0)
        acts += [L2.walk(arm), L2.walk_back(arm), L2.walk_side(arm, "L"), L2.walk_side(arm, "R"),
                 L2.start(arm), L2.brake(arm), L2.land(arm)]
        scale["arms"] = arms.get("run", 1.0)
        acts += [L2.run(arm), L2.run_back(arm), L2.run_side(arm, "L"), L2.run_side(arm, "R"), L2.sprint(arm)]
        scale["arms"] = arms.get("jump", 1.0)
        acts += [L2.jump_air(arm), L2.jump_leap(arm)]
    finally:
        L2.STANCE, L2.GUARD_WALK, nd_shot.Shot.key = saved
    for a in acts:
        a.name = a.name.replace("Lion.", prefix)
    return acts


def scaler(torso_yaw=1.0, torso_pitch=1.0, root_pitch=1.0, head_yaw=1.0, add=None):
    """A simple act(): scale the counter-rotation and the leans, then add
    fixed offsets (e.g. {"torso": {"pitch": 6}} for shoulders thrown forward)."""
    def act(spec):
        t = spec.get("torso")
        if t:
            if "yaw" in t: t["yaw"] *= torso_yaw
            if "pitch" in t: t["pitch"] *= torso_pitch
        r = spec.get("root")
        if r and "pitch" in r: r["pitch"] *= root_pitch
        h = spec.get("head")
        if h and "yaw" in h: h["yaw"] *= head_yaw
        for part, over in (add or {}).items():
            if part in spec:
                for k, v in over.items():
                    if k in spec[part]:
                        spec[part][k] += v
        return spec
    return act
