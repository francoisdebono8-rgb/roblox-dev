"""É9 (03/11): the shared moves the eight drew only procedurally.

Measured: no fighter had its own Grab, Throw or ThrowUp, and only Sasuke had
the jump heavy (AirFlip, the salto heel kick). Each is authored here on the
fighter's own stance (and its own air pose for the salto), so the eight grab,
throw and flip from their own bodies:

  F.Grab      both hands shoot out at the collar as the front foot steps in,
              then clutch and pull him close (contact: the hands close)
  F.Throw     from the hold: a short wind to the right, then the hips turn
              through and the arms heave him across and away (knockdown)
  F.ThrowUp   from the hold: sink under him, then the legs drive up and the
              arms lift him overhead (launched)
  F.AirFlip   Sasuke's salto (sasuke_p1.air_flip) on the fighter's air pose

Conventions (nd_ctrl): travel z < 0 is forward, the front foot is lf (every
stance leads with it), feet are planted world positions shifted by travel.
Riposte and WallDive borrow each fighter's own Light1 and AirDrive in the
engine (Motion.DRAWN_AS): no clip here.
"""
from nd_shot import Shot, merge


def at(S, T, over=None):
    """The stance moved by travel T along z, feet planted with it."""
    base = merge(S, {"travel": {"z": T}, "rf": {"z": S["rf"].get("z", 0) + T}, "lf": {"z": S["lf"].get("z", 0) + T}})
    return merge(base, over or {})


def arms(raise_, out, elbow, twist=0, wrist=0):
    one = {"raise": raise_, "out": out, "twist": twist, "elbow": elbow, "wrist": wrist}
    return {"ra": dict(one), "la": dict(one)}


def grab(arm, F, S):
    y = S["root"]["y"]
    sh = Shot(arm, F + "Grab")
    sh.key(0, S, "ease")
    load = at(S, 0, merge({"root": {"y": y - .12, "z": .06, "pitch": S["root"].get("pitch", 0) + 2}}, arms(48, 8, 84)))
    sh.key(6, load, "ease")
    # The front foot steps in (the rear one stays planted: a lunge, not a
    # glide), then the rear foot steps up behind it as he pulls him close.
    T = -.55
    lunge = {"lf": {"z": S["lf"].get("z", 0) + T}, "rf": {"z": S["rf"].get("z", 0)}}
    reach = merge(at(S, T, merge({"root": {"y": y - .06, "z": -.22, "pitch": 16, "yaw": S["root"].get("yaw", 0) * .4},
                                  "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -8, "yaw": 0}}, arms(88, -14, 22))), lunge)
    # (the front foot leaves the floor on its way: a step, not a slide)
    sh.key(8, merge(load, {"travel": {"z": T * .5}, "root": {"z": -.08, "pitch": 10},
                           "lf": {"z": S["lf"].get("z", 0) + T * .55, "y": .28, "toe": -10}}), "pass")
    sh.key(11, reach, "impact")
    clutch = merge(reach, merge({"root": {"z": -.16, "pitch": 10}}, arms(80, -12, 72)))
    sh.key(16, clutch, "ease")
    sh.key(34, merge(clutch, {"root": {"z": -.1, "pitch": 8}}), "ease")
    sh.key(42, merge(clutch, {"root": {"z": -.06, "pitch": 6}, "rf": {"z": S["rf"].get("z", 0) + T * .5, "y": .22}}), "ease")
    sh.key(50, at(S, T), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 1)
    return sh.build(markers={"contact": 11 / 60, "recover": 19 / 60})


def _hold(S):
    y = S["root"]["y"]
    return at(S, 0, merge({"root": {"y": y - .08, "z": -.14, "pitch": 10, "yaw": S["root"].get("yaw", 0) * .4},
                           "torso": {"pitch": 6, "yaw": 0}, "head": {"pitch": -8, "yaw": 0}}, arms(80, -12, 72)))


def throw(arm, F, S):
    y = S["root"]["y"]
    yaw = S["root"].get("yaw", 0) * .4
    hold = _hold(S)
    sh = Shot(arm, F + "Throw")
    sh.key(0, hold, "ease")
    wind = merge(hold, {"root": {"y": y - .2, "yaw": yaw + 24}, "torso": {"yaw": 16},
                        "ra": {"raise": 62, "out": 18, "elbow": 92}, "la": {"raise": 84, "out": -30, "elbow": 60},
                        "rf": {"toe": 12}})
    sh.key(5, wind, "ease")
    heave = merge(hold, {"root": {"y": y - .14, "z": -.3, "pitch": 14, "yaw": yaw - 42}, "torso": {"pitch": 10, "yaw": -24},
                         "head": {"yaw": 24}, "ra": {"raise": 86, "out": -38, "twist": 20, "elbow": 20},
                         "la": {"raise": 40, "out": 40, "elbow": 30}, "rf": {"toe": 30, "yaw": S["rf"].get("yaw", 0) - 30}})
    sh.key(7, heave, "impact")
    follow = merge(heave, {"root": {"yaw": yaw - 52}, "torso": {"yaw": -30}, "ra": {"raise": 64, "out": -46}, "la": {"raise": 30, "out": 50}})
    sh.key(13, follow, "ease")
    sh.key(34, S, "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def throw_up(arm, F, S):
    y = S["root"]["y"]
    hold = _hold(S)
    sh = Shot(arm, F + "ThrowUp")
    sh.key(0, hold, "ease")
    scoop = merge(hold, merge({"root": {"y": y - .38, "z": -.08, "pitch": 18}, "torso": {"pitch": 14}, "head": {"pitch": -12}},
                              arms(28, 4, 44)))
    sh.key(5, scoop, "ease")
    top = max(y + .4, -.12)
    lift = merge(hold, merge({"root": {"y": top, "z": .02, "pitch": -8}, "torso": {"pitch": -12}, "head": {"pitch": -26},
                              "rf": {"toe": 34}, "lf": {"toe": 18}}, arms(150, 6, 20)))
    sh.key(7, lift, "impact")
    sh.key(12, merge(lift, merge({"root": {"y": top - .04}}, arms(164, 8, 14))), "ease")
    sh.key(31, S, "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def air_flip(arm, F, AIR):
    """Sasuke's salto heel kick (sasuke_p1.air_flip) on this fighter's air
    pose: the tuck turns fast, the heel opens late and comes over and down,
    the body opens exposed for the landing."""
    from kunai_lion import tuck
    sh = Shot(arm, F + "AirFlip")
    sh.key(0, AIR, "ease")
    TUCK = (0, -.55, -.35)

    def fly(root, leg_r=TUCK, leg_l=TUCK, arms_=None, torso=None, head=None):
        spec = {"root": dict(root, tuck=1, roll=0)}
        spec.update(tuck(0, spec["root"], leg_r, leg_l))
        spec["torso"] = torso or {"pitch": 20, "yaw": 0, "roll": 0}
        spec["head"] = head or {"pitch": 20, "yaw": 0}
        spec.update(arms_ or {})
        return merge(AIR, spec)
    hug = {"ra": {"raise": 70, "out": -6, "twist": 0, "elbow": 96, "wrist": 0}, "la": {"raise": 70, "out": -6, "twist": 0, "elbow": 96, "wrist": 0}}
    sh.key(3, fly({"y": -.4, "z": 0, "pitch": 70, "yaw": 0}, arms_=hug), "pass")
    sh.key(6, fly({"y": -.3, "z": 0, "pitch": 170, "yaw": 0}, arms_=hug), "pass")
    sh.key(8, fly({"y": -.35, "z": 0, "pitch": 255, "yaw": 0}, leg_r=(0, -.9, -.7),
                  arms_={"ra": {"raise": -30, "out": 50, "elbow": 20}, "la": {"raise": -30, "out": 50, "elbow": 20}}), "pass")
    kick = fly({"y": -.4, "z": 0, "pitch": 320, "yaw": 0}, leg_r=(0, -.35, -1.45), leg_l=(0, -.9, .1),
               arms_={"ra": {"raise": -40, "out": 60, "elbow": 10}, "la": {"raise": -40, "out": 60, "elbow": 10}},
               torso={"pitch": -10, "yaw": 0, "roll": 0}, head={"pitch": -14, "yaw": 0})
    sh.key(10, kick, "impact")
    sh.key(13, fly({"y": -.45, "z": 0, "pitch": 340, "yaw": 0}, leg_r=(0, -1.0, -1.0), leg_l=(0, -.9, .1),
                   arms_={"ra": {"raise": 20, "out": 60, "elbow": 20}, "la": {"raise": 20, "out": 60, "elbow": 20}},
                   torso={"pitch": 0, "yaw": 0, "roll": 0}, head={"pitch": -16, "yaw": 0}), "ease")
    sh.key(24, fly({"y": -.45, "z": 0, "pitch": 374, "yaw": 0}, leg_r=(0, -1.1, -.3), leg_l=(0, -1.0, -.1),
                   arms_={"ra": {"raise": 56, "out": 42, "elbow": 94}, "la": {"raise": 60, "out": 40, "elbow": 90}},
                   torso={"pitch": 12, "yaw": 0, "roll": 0}, head={"pitch": -20, "yaw": 0}), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def author(arm, F, S, AIR=None, flip=True):
    F = F if F.endswith(".") else F + "."
    acts = [grab(arm, F, S), throw(arm, F, S), throw_up(arm, F, S)]
    if flip and AIR is not None:
        acts.append(air_flip(arm, F, AIR))
    return acts
