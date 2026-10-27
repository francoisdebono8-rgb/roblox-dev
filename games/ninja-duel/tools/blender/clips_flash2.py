"""Minato (Flashstep), authored on the control rig (nd_ctrl / nd_shot), DEC-028.

Not a faster Sasuke. Sasuke is low, coiled and loads every blow from the
floor; Minato is light and economical: an upright chest, small precise steps
placed exactly, no movement that does not serve the next one, the kunai in
reverse grip low in the right hand, ready. He changes angle from the feet
(a pivot on the ball, not a body swing), arrives from a teleport already
oriented and balanced for the next decision, and drives the Rasengan with
the whole body behind the palm. Conventions as clips_lion2.
"""
from nd_shot import Shot, cycle, merge, mirror

STANCE = {"root": {"y": -.42, "z": -.04, "pitch": 8, "yaw": 22}, "torso": {"pitch": 4, "yaw": -12}, "head": {"pitch": -5, "yaw": -10},
          "ra": {"raise": 34, "out": 14, "twist": 24, "elbow": 98, "wrist": -22}, "la": {"raise": 58, "out": 2, "twist": 12, "elbow": 78},
          "rf": {"x": .22, "z": .78, "yaw": 32}, "lf": {"x": -.08, "z": -.72, "yaw": -4}}


def s(over=None):
    return merge(STANCE, over or {})


def idle(arm):
    """Weight shift, Minato: on the balls of the feet, a small quick rhythm
    (1 s), weight barely moving - a body that can leave in any direction.
    The heels lift a little in turn, the kunai hand turns the blade."""
    sh = Shot(arm, "Flashstep.Idle")
    sh.key(0, s(), "ease")
    sh.key(15, s({"root": {"y": -.47, "z": .02}, "rf": {"toe": -10, "y": .03}, "ra": {"wrist": -14}}), "ease")
    sh.key(30, s({"root": {"y": -.42}}), "ease")
    sh.key(45, s({"root": {"y": -.47, "z": -.08}, "lf": {"toe": -10, "y": .03}, "ra": {"wrist": -28}}), "ease")
    sh.key(60, s(), "ease")
    sh.drag(["neck"], 3).drag(["shoulder.R", "forearm.R", "hand.R"], 2)
    return sh.build(loop=True)


def run(arm):
    """Minato's run: long and level. Stride 11.5 (longer than Sasuke's), the
    hips stay high (less bob: the energy goes forward, not up), the chest
    only a little forward, the arms swing short and close (the kunai stays
    in the right hand, blade back along the forearm)."""
    keys = [
        (0.0, {"root": {"y": -.4, "pitch": 15, "yaw": -7}, "torso": {"pitch": 6, "yaw": 9}, "head": {"pitch": -18, "yaw": -3},
               "rf": {"x": .0, "z": -1.15, "toe": 6}, "lf": {"x": -.02, "z": 1.3, "y": .75, "toe": -48},
               "la": {"raise": 38, "out": 8, "elbow": 88}, "ra": {"raise": -34, "out": 12, "twist": 20, "elbow": 90, "wrist": -20}}, "impact"),
        (0.07, {"root": {"y": -.54, "pitch": 16, "yaw": -5}, "lf": {"z": .9, "y": 1.0, "toe": -58},
                "la": {"raise": 30}, "ra": {"raise": -28}}, "ease"),
        (0.15, {"root": {"y": -.44, "pitch": 16, "yaw": 0}, "torso": {"yaw": 2}, "lf": {"z": -.35, "y": 1.15, "toe": -30},
                "la": {"raise": 12}, "ra": {"raise": -6}}, "pass"),
        (0.21, {"root": {"y": -.34, "pitch": 15, "yaw": 5}, "torso": {"yaw": -4}, "lf": {"z": -1.1, "y": .85, "toe": -6},
                "la": {"raise": -10}, "ra": {"raise": 14}}, "launch"),
        (0.34, {"root": {"y": -.3, "pitch": 15, "yaw": 7}, "torso": {"yaw": -9}, "head": {"yaw": 3},
                "rf": {"z": 1.4, "y": .65, "toe": -48}, "lf": {"z": -1.4, "y": .3, "toe": 4},
                "la": {"raise": -32, "elbow": 80}, "ra": {"raise": 30, "elbow": 96}}, "pass"),
        (0.45, {"root": {"y": -.34, "pitch": 15, "yaw": 7}, "rf": {"z": 1.25, "y": .85, "toe": -48}, "lf": {"z": -1.18, "y": .06, "toe": 6},
                "la": {"raise": -36}, "ra": {"raise": 34}}, "ease"),
    ]
    sh = cycle(arm, "Flashstep.Run.F", 11.5, 48, keys, {"R": (0, .21)})
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"stride": 11.5})


def run_back(arm):
    keys = [
        (0.0, {"root": {"y": -.44, "pitch": -2, "yaw": 4}, "torso": {"pitch": 6}, "head": {"pitch": -2},
               "la": {"raise": 62, "out": -6, "twist": 16, "elbow": 88}, "ra": {"raise": 40, "out": 10, "twist": 24, "elbow": 100, "wrist": -22},
               "rf": {"x": .02, "z": 1.0, "toe": -12}, "lf": {"x": -.02, "z": -.75, "y": .25, "toe": -20}}, "impact"),
        (0.12, {"root": {"y": -.54}, "lf": {"z": -.1, "y": .48, "toe": -28}}, "ease"),
        (0.26, {"root": {"y": -.44}, "lf": {"z": .6, "y": .34, "toe": -20}}, "pass"),
        (0.34, {"root": {"y": -.4}, "lf": {"z": 1.0, "y": .12, "toe": -14}}, "launch"),
        (0.45, {"root": {"y": -.42}, "rf": {"z": -.72, "y": .25, "toe": -22}, "lf": {"z": 1.0, "y": .03, "toe": -12}}, "ease"),
    ]
    sh = cycle(arm, "Flashstep.Run.B", 6.6, 28, keys, {"R": (0, .32)}, direction=(0.0, 1.0))
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"stride": 6.6})


def run_side(arm, side):
    """Minato circles with the hips turned less than Sasuke (40 deg): his
    sideways run is a fast crossing step that keeps the chest square on the
    opponent - the body ready to cut back the other way."""
    sgn = 1 if side == "R" else -1
    hip = 40 * sgn
    base = {"root": {"y": -.4, "pitch": 10, "yaw": hip, "roll": 3 * sgn}, "torso": {"pitch": 4, "yaw": -hip * .8}, "head": {"pitch": -10, "yaw": -hip * .2},
            "la": {"raise": 46, "out": 8, "elbow": 84}, "ra": {"raise": 30, "out": 16, "twist": 24, "elbow": 96, "wrist": -22}}
    a, b = ("rf", "lf") if side == "R" else ("lf", "rf")

    def f(x, z, y=0.0, toe=0.0):
        return {"x": x * sgn, "z": z, "y": y, "toe": toe, "yaw": hip}
    keys = [
        (0.0, merge(base, {a: f(1.05, -.05, 0, 6), b: f(-1.2, .15, .7, -44)}), "impact"),
        (0.08, merge(base, {"root": {"y": -.52}, b: f(-.45, .1, 1.0, -50)}), "ease"),
        (0.18, merge(base, {"root": {"y": -.42}, b: f(.6, 0, .85, -16)}), "pass"),
        (0.25, merge(base, {"root": {"y": -.34}, b: f(1.05, -.05, .4, 0)}), "launch"),
        (0.38, merge(base, {"root": {"y": -.3}, a: f(-1.25, -.05, .6, -44), b: f(1.1, -.05, .08, 4)}), "pass"),
        (0.5, merge(base, {b: f(1.05, -.05, 0, 6), a: f(-1.2, -.05, .7, -44)}), "impact"),
        (0.58, merge(base, {"root": {"y": -.52}, a: f(-.45, -.05, 1.0, -50)}), "ease"),
        (0.68, merge(base, {"root": {"y": -.42}, a: f(.6, -.05, .85, -16)}), "pass"),
        (0.75, merge(base, {"root": {"y": -.34}, a: f(1.05, -.05, .4, 0)}), "launch"),
        (0.88, merge(base, {"root": {"y": -.3}, b: f(-1.25, -.05, .6, -44), a: f(1.1, -.05, .08, 4)}), "pass"),
    ]
    lead, trail = ("R", "L") if side == "R" else ("L", "R")
    sh = cycle(arm, "Flashstep.Run." + side, 8.4, 28, keys, {lead: (0, .25), trail: (.5, .75)},
               direction=(float(sgn), 0.0), mirror_half=False)
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"stride": 8.4})


GUARD = {"la": {"raise": 58, "out": 2, "twist": 12, "elbow": 78}, "ra": {"raise": 36, "out": 14, "twist": 24, "elbow": 98, "wrist": -22}}


def walk(arm):
    keys = [
        (0.0, merge(GUARD, {"root": {"y": -.38, "pitch": 6, "yaw": -3}, "torso": {"pitch": 4, "yaw": 3}, "head": {"pitch": -6},
                            "rf": {"x": .03, "z": -.86, "toe": 8}, "lf": {"x": -.03, "z": .86, "y": .02, "toe": -16}}), "ease"),
        (0.1, {"root": {"y": -.46}, "lf": {"z": .58, "y": .1, "toe": -24}}, "ease"),
        (0.25, {"root": {"y": -.36, "yaw": 0}, "torso": {"yaw": 0}, "lf": {"z": 0, "y": .34, "toe": -10}}, "pass"),
        (0.4, {"root": {"y": -.34, "yaw": 3}, "torso": {"yaw": -3}, "lf": {"z": -.62, "y": .12, "toe": 6}}, "pass"),
    ]
    sh = cycle(arm, "Flashstep.Walk.F", 3.6, 40, keys, {"R": (0, .58)})
    sh.drag(["neck"], 3)
    return sh.build(loop=True, meta={"stride": 3.6})


def walk_back(arm):
    keys = [
        (0.0, merge(GUARD, {"root": {"y": -.42, "pitch": 3, "yaw": 3}, "torso": {"pitch": 6}, "head": {"pitch": -4},
                            "rf": {"x": .03, "z": .72, "toe": -8}, "lf": {"x": -.03, "z": -.72, "y": .02, "toe": -6}}), "ease"),
        (0.15, {"root": {"y": -.48}, "lf": {"z": -.4, "y": .12, "toe": -14}}, "ease"),
        (0.3, {"root": {"y": -.4, "yaw": 0}, "lf": {"z": .1, "y": .26, "toe": -12}}, "pass"),
        (0.42, {"root": {"y": -.38, "yaw": -2}, "lf": {"z": .56, "y": .1, "toe": -8}}, "pass"),
    ]
    sh = cycle(arm, "Flashstep.Walk.B", 3.0, 40, keys, {"R": (0, .62)}, direction=(0.0, 1.0))
    sh.drag(["neck"], 3)
    return sh.build(loop=True, meta={"stride": 3.0})


def walk_side(arm, side):
    sgn = 1 if side == "R" else -1
    lead, trail = ("rf", "lf") if side == "R" else ("lf", "rf")
    LS, TS = ("R", "L") if side == "R" else ("L", "R")
    g = merge(GUARD, {"root": {"y": -.42, "pitch": 6, "yaw": 16}, "torso": {"pitch": 4, "yaw": -8}, "head": {"pitch": -5, "yaw": -8}})
    zl, zt = (.1, -.2) if side == "R" else (-.2, .1)

    def f(x, z, y=0.0, toe=0.0):
        return {"x": x * sgn, "z": z, "y": y, "toe": toe, "yaw": 14}
    keys = [
        (0.0, merge(g, {lead: f(0, zl), trail: f(0, zt)}), "ease"),
        (0.15, merge(g, {"root": {"y": -.48, "roll": -2 * sgn}, lead: f(.5, zl, .18, -8)}), "pass"),
        (0.32, merge(g, {"root": {"y": -.44, "roll": 2 * sgn}, lead: f(1.18, zl)}), "impact"),
        (0.5, merge(g, {"root": {"y": -.4}, trail: f(-.9, zt)}), "ease"),
        (0.65, merge(g, {"root": {"y": -.38}, trail: f(-.3, zt, .16, -8)}), "pass"),
        (0.8, merge(g, {"root": {"y": -.42}, trail: f(.36, zt)}), "impact"),
    ]
    sh = cycle(arm, "Flashstep.Walk." + side, 1.8, 32, keys, {LS: (.32, 1.0), TS: (.8, 1.5)},
               direction=(float(sgn), 0.0), mirror_half=False)
    return sh.build(loop=True, meta={"stride": 1.8})


def sprint(arm):
    """Minato's ninja run: even flatter and longer than Sasuke's (stride 15),
    the arms low and close behind (no wide sweep), the head level: the
    fastest body in the roster spends nothing on show."""
    arms = {"la": {"raise": -40, "out": 8, "twist": -8, "elbow": 30}, "ra": {"raise": -40, "out": 10, "twist": 10, "elbow": 40, "wrist": -20}}
    keys = [
        (0.0, merge(arms, {"root": {"y": -.66, "pitch": 30, "yaw": -5}, "torso": {"pitch": 18, "yaw": 6}, "head": {"pitch": -40, "yaw": -2},
                           "rf": {"x": .03, "z": -1.05, "toe": 4}, "lf": {"x": -.03, "z": 1.35, "y": .85, "toe": -54}}), "impact"),
        (0.06, merge(arms, {"root": {"y": -.76}, "lf": {"z": 1.0, "y": 1.05, "toe": -58}}), "ease"),
        (0.11, merge(arms, {"root": {"y": -.7, "yaw": 0}, "lf": {"z": -.4, "y": 1.15, "toe": -40}}), "pass"),
        (0.17, merge(arms, {"root": {"y": -.62, "yaw": 3}, "torso": {"yaw": -2}, "lf": {"z": -1.05, "y": 1.0, "toe": -18}}), "launch"),
        (0.32, merge(arms, {"root": {"y": -.56, "yaw": 5}, "torso": {"yaw": -5},
                            "rf": {"z": 1.55, "y": .65, "toe": -50}, "lf": {"z": -1.35, "y": .4, "toe": -4}}), "pass"),
        (0.45, merge(arms, {"root": {"y": -.6, "yaw": 5}, "rf": {"z": 1.35, "y": .9, "toe": -54}, "lf": {"z": -1.1, "y": .06, "toe": 4}}), "ease"),
    ]
    sh = cycle(arm, "Flashstep.Sprint", 15.0, 40, keys, {"R": (0, .17)})
    sh.drag(["neck"], 1)
    return sh.build(loop=True, meta={"stride": 15.0})


def start(arm):
    """No wind-up: he just goes - one short low step and he is at speed (the
    first step lands under the hips, the second already full length)."""
    sh = Shot(arm, "Flashstep.Start")
    sh.key(0, s(), "ease")
    sh.key(3, s({"travel": {"z": -.5}, "root": {"y": -.62, "z": -.45, "pitch": 26}, "torso": {"pitch": 12}, "head": {"pitch": -24},
                 "rf": {"y": .08, "toe": -34}}), "launch")
    sh.key(6, s({"travel": {"z": -1.4}, "root": {"y": -.58, "z": -.3, "pitch": 24, "yaw": 0}, "rf": {"x": .05, "z": -.4, "y": .55, "toe": -16, "yaw": 0}}), "pass")
    sh.key(8, s({"travel": {"z": -2.1}, "root": {"y": -.56, "z": -.2, "pitch": 22, "yaw": -6}, "torso": {"yaw": 8},
                 "rf": {"x": .02, "z": -2.3, "y": 0, "toe": 4, "yaw": 0}, "lf": {"y": .2, "toe": -40},
                 "la": {"raise": -26}, "ra": {"raise": 30}}), "impact")
    sh.key(13, s({"travel": {"z": -4.2}, "root": {"y": -.46, "z": -.05, "pitch": 18, "yaw": 5}, "torso": {"yaw": -6},
                  "rf": {"x": .02, "z": -2.3, "y": 0, "toe": -26, "yaw": 0}, "lf": {"x": -.02, "z": -5.4, "y": 0, "toe": 6, "yaw": 0},
                  "la": {"raise": 30}, "ra": {"raise": -26}}), "impact")
    sh.key(11, s({"travel": {"z": -3.4}, "rf": {"x": .02, "z": -2.3, "y": 0, "toe": -10, "yaw": 0}, "lf": {"x": -.02, "z": -3.8, "y": .7, "toe": -20, "yaw": 0}}), "pass")
    sh.drag(["neck"], 2)
    return sh.build(meta={"ready": 8 / 60})


def brake(arm):
    """Minato stops in one placed step: the lead foot plants already turned to
    the opponent, the hips sink once and he is set - no skid."""
    sh = Shot(arm, "Flashstep.Brake")
    T = -1.3
    sh.key(0, {"root": {"y": -.36, "pitch": 15, "yaw": 7}, "torso": {"pitch": 6, "yaw": -8}, "head": {"pitch": -18},
               "ra": {"raise": 30, "out": 12, "twist": 20, "elbow": 96, "wrist": -20}, "la": {"raise": -30, "out": 8, "elbow": 80},
               "lf": {"x": -.02, "z": -1.2, "y": .2, "toe": 10, "yaw": 0}, "rf": {"x": .02, "z": 1.0, "y": .3, "toe": -40, "yaw": 0}}, "pass")
    sh.key(4, {"travel": {"z": -1.0}, "root": {"y": -.6, "pitch": 0, "yaw": 14}, "torso": {"pitch": 0, "yaw": -10}, "head": {"pitch": -4},
               "ra": {"raise": 40, "out": 14, "twist": 24, "elbow": 96, "wrist": -22}, "la": {"raise": 40, "out": 14, "elbow": 80},
               "lf": {"x": -.08, "z": -2.02, "y": 0, "toe": 12, "yaw": -4}, "rf": {"x": .1, "z": -.2, "y": .25, "toe": -26, "yaw": 20}}, "impact")
    sh.key(8, s({"travel": {"z": T}, "root": {"y": -.56}, "lf": {"z": -2.02}, "rf": {"z": .78 + T}}), "impact")
    sh.key(18, s({"travel": {"z": T}, "lf": {"z": -2.02}, "rf": {"z": .78 + T}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(meta={"ready": 8 / 60})


def jump_air(arm):
    """Minato's jump is clean: a straight, extended take-off, a quick neat
    tuck (knees together), and the legs already set for the landing well
    before the floor - he lands where he chose to."""
    sh = Shot(arm, "Flashstep.Jump.Air")
    take = {"root": {"y": -.05, "pitch": 2, "yaw": 0}, "torso": {"pitch": -4, "yaw": 0}, "head": {"pitch": -12, "yaw": 0},
            "la": {"raise": 100, "out": 16, "elbow": 40}, "ra": {"raise": 90, "out": 18, "twist": 20, "elbow": 60, "wrist": -20},
            "rf": {"x": 0, "z": .05, "y": -.25, "toe": -55, "yaw": 0}, "lf": {"x": 0, "z": .15, "y": -.2, "toe": -50, "yaw": 0}}
    tuck = merge(take, {"root": {"y": -.45, "pitch": 12}, "torso": {"pitch": 10}, "head": {"pitch": -18},
                        "la": {"raise": 50, "out": 30, "elbow": 90}, "ra": {"raise": 44, "out": 30, "elbow": 100},
                        "rf": {"z": -.6, "y": 1.2, "toe": -22}, "lf": {"z": -.5, "y": 1.15, "toe": -24}})
    set_ = merge(take, {"root": {"y": -.15, "pitch": 6}, "torso": {"pitch": 4}, "head": {"pitch": -16},
                        "la": {"raise": 44, "out": 46, "elbow": 40}, "ra": {"raise": 30, "out": 40, "twist": 24, "elbow": 80, "wrist": -20},
                        "rf": {"x": .1, "z": .5, "y": .05, "toe": -12}, "lf": {"x": -.06, "z": -.55, "y": .02, "toe": -6}})
    sh.key(0, take, "launch").key(16, tuck, "pass").key(30, tuck, "ease").key(48, set_, "pass").key(60, set_, "ease")
    sh.drag(["neck"], 2)
    return sh.build(meta={"axis": "arc"})


def jump_leap(arm):
    sh = Shot(arm, "Flashstep.Jump.Leap")
    take = {"root": {"y": -.15, "pitch": 20, "yaw": 0}, "torso": {"pitch": 10, "yaw": 0}, "head": {"pitch": -26, "yaw": 0},
            "la": {"raise": -36, "out": 8, "elbow": 30}, "ra": {"raise": -36, "out": 10, "twist": 10, "elbow": 40, "wrist": -20},
            "rf": {"x": 0, "z": -1.1, "y": .85, "toe": -18, "yaw": 0}, "lf": {"x": 0, "z": 1.25, "y": .2, "toe": -50, "yaw": 0}}
    split = merge(take, {"root": {"y": -.25}, "rf": {"z": -1.55, "y": .8, "toe": 0}, "lf": {"z": 1.5, "y": .6, "toe": -44}})
    reach = merge(take, {"root": {"y": -.15, "pitch": 6}, "torso": {"pitch": 4}, "head": {"pitch": -14},
                         "rf": {"z": -1.0, "y": .12, "toe": 6}, "lf": {"z": .5, "y": .45, "toe": -30},
                         "la": {"raise": 20, "out": 30, "elbow": 40}, "ra": {"raise": 10, "out": 30, "elbow": 70, "wrist": -20}})
    sh.key(0, take, "launch").key(22, split, "pass").key(60, reach, "ease")
    sh.drag(["neck"], 2)
    return sh.build(meta={"axis": "arc"})


def land(arm):
    """A quiet landing: he lands on the balls of the feet already in his
    stance, the knees take a small dip (not a crouch) and he is ready at
    frame 6."""
    sh = Shot(arm, "Flashstep.Land")
    touch = s({"root": {"y": -.25, "pitch": 6}, "rf": {"toe": -10}, "lf": {"toe": -8}})
    dip = s({"root": {"y": -.7, "z": -.05, "pitch": 14}, "torso": {"pitch": 8}, "head": {"pitch": -14},
             "la": {"raise": 52, "out": 12}, "ra": {"raise": 30, "out": 20}})
    sh.key(0, touch, "impact").key(4, dip, "ease").key(16, s(), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"ready": 6 / 60})


def light1(arm):
    """Reverse-grip kunai slash: the cut is made by the body turning, not
    the arm swinging: a short step in, the hips and chest turn left and the
    right forearm - blade along it - is carried across the target at the
    end of the turn (frame 8). A small motion, very fast; the guard hand
    stays on the centre line."""
    sh = Shot(arm, "Flashstep.Light1")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.5, "yaw": 34}, "torso": {"yaw": -26}, "ra": {"raise": 70, "out": -40, "twist": 40, "elbow": 112, "wrist": -30},
              "lf": {"y": .1, "z": -.85}})
    sh.key(4, load, "ease")
    hit = s({"travel": {"z": -.25}, "root": {"y": -.5, "z": -.36, "yaw": 2, "pitch": 12}, "torso": {"pitch": 6, "yaw": 22}, "head": {"yaw": -20},
             "ra": {"raise": 86, "out": 36, "twist": -10, "elbow": 22, "wrist": 10}, "la": {"raise": 50, "out": -10, "elbow": 70},
             "lf": {"z": -1.22, "y": 0}, "rf": {"y": .08, "toe": -22}})
    sh.key(8, hit, "impact")
    sh.key(10, merge(hit, {"torso": {"yaw": 26}, "ra": {"out": 46}}), "ease")
    sh.key(14, merge(s({"travel": {"z": -.45}}), {"lf": {"z": -1.22}, "rf": {"z": .4, "y": .1}, "root": {"z": -.2}}), "pass")
    sh.key(24, merge(s({"travel": {"z": -.5}}), {"lf": {"z": -1.22}, "rf": {"z": .28}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 8 / 60, "recover": 13 / 60})


def light2(arm):
    """Palm strike with the lead hand: the hips pivot on the ball of the
    front foot (an angle change, he steps off the line), the palm goes out
    straight from the centre at the end of the pivot."""
    sh = Shot(arm, "Flashstep.Light2")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.5, "yaw": 40}, "torso": {"yaw": 14}, "la": {"raise": 46, "out": 30, "twist": -20, "elbow": 104}, "lf": {"yaw": -26}}), "ease")
    hit = s({"travel": {"z": -.2, "x": -.2}, "root": {"y": -.46, "z": -.4, "yaw": -12, "pitch": 12}, "torso": {"pitch": 6, "yaw": -26}, "head": {"yaw": 8},
             "la": {"raise": 90, "out": -12, "twist": 24, "elbow": 6, "wrist": 34}, "ra": {"raise": 24, "out": 22, "twist": 24, "elbow": 92, "wrist": -22},
             "lf": {"yaw": -40}, "rf": {"x": .5, "z": .2, "y": 0, "yaw": 10}})
    sh.key(8, hit, "impact")
    sh.key(6, s({"travel": {"z": -.1, "x": -.1}, "root": {"y": -.48, "yaw": 14}, "rf": {"x": .4, "z": .5, "y": .2, "toe": -12, "yaw": 20}, "lf": {"yaw": -34}}), "pass")
    sh.key(10, merge(hit, {"root": {"z": -.44}, "la": {"raise": 91}}), "ease")
    sh.key(22, s({"travel": {"z": -.2, "x": -.2}, "rf": {"x": .5, "z": .2}, "lf": {"yaw": -10}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 8 / 60, "recover": 13 / 60})


def light3(arm):
    """Spinning roundhouse with the right leg: a precise pivot on the front
    foot, the head spots first, the leg whips through flat at head height."""
    sh = Shot(arm, "Flashstep.Light3")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.56, "yaw": -30}, "torso": {"yaw": -10}, "head": {"yaw": 20}, "lf": {"yaw": -50}, "rf": {"y": .1, "toe": -24}}), "ease")
    sh.key(8, s({"root": {"y": -.4, "yaw": -110}, "torso": {"yaw": 0}, "head": {"yaw": 80}, "lf": {"yaw": -130},
                 "rf": {"x": -.5, "z": .3, "y": .9, "toe": -20, "knee": 30, "yaw": -110},
                 "ra": {"raise": 20, "out": 50, "elbow": 60, "wrist": -20}, "la": {"raise": 70, "out": -20, "elbow": 100}}), "pass")
    hit = s({"root": {"y": -.28, "z": -.2, "yaw": -210, "pitch": -4, "roll": 18}, "torso": {"yaw": 10, "roll": 8}, "head": {"yaw": 60},
             "lf": {"yaw": -210}, "rf": {"x": -1.4, "z": -2.4, "y": 1.9, "toe": -30, "knee": 60, "yaw": -200},
             "ra": {"raise": -20, "out": 60, "elbow": 20, "wrist": -20}, "la": {"raise": 74, "out": -20, "elbow": 104}})
    sh.key(10, s({"root": {"y": -.32, "z": -.1, "yaw": -170, "roll": 10}, "torso": {"yaw": 6}, "head": {"yaw": 70}, "lf": {"yaw": -170},
                  "rf": {"x": -1.1, "z": -1.3, "y": 1.6, "toe": -26, "knee": 50, "yaw": -165},
                  "ra": {"raise": 0, "out": 56, "elbow": 40, "wrist": -20}, "la": {"raise": 72, "out": -20, "elbow": 102}}), "pass")
    sh.key(11, hit, "impact")
    sh.key(14, merge(hit, {"root": {"yaw": -250}, "lf": {"yaw": -250}, "rf": {"x": -2.0, "z": -1.4, "y": 1.7, "yaw": -240}}), "ease")
    sh.key(20, s({"root": {"y": -.46, "yaw": -300}, "lf": {"yaw": -300}, "rf": {"x": -.6, "z": -1.0, "y": .6, "toe": -10, "yaw": -300}}), "pass")
    T = -.6
    end = s({"travel": {"z": T}, "root": {"yaw": 22 - 360}, "lf": {"z": -.72, "yaw": -364}, "rf": {"z": .78 + T, "yaw": 32 - 360}})
    sh.key(26, merge(end, {"root": {"y": -.58}}), "impact")
    sh.key(36, end, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 11 / 60, "recover": 17 / 60})


def heavy(arm):
    """The coiled lunge: he sinks and turns away (the only real wind-up he
    shows: it is his heavy), then everything releases in a straight line -
    long step, hips square, right fist driven straight; he holds the line."""
    sh = Shot(arm, "Flashstep.Heavy")
    sh.key(0, s(), "ease")
    coil = s({"root": {"y": -.8, "z": .25, "pitch": 12, "yaw": 50}, "torso": {"pitch": 8, "yaw": 26},
              "ra": {"raise": -20, "out": 22, "twist": 22, "elbow": 126, "wrist": 0}, "la": {"raise": 76, "out": -6, "elbow": 54}, "rf": {"toe": -6}})
    sh.key(15, coil, "ease")
    sh.key(17, merge(coil, {"lf": {"y": .2, "z": -1.1}}), "pass")
    hit = s({"travel": {"z": -1.1}, "root": {"y": -.5, "z": -.95, "pitch": 22, "yaw": -28}, "torso": {"pitch": 10, "yaw": -24}, "head": {"yaw": 16},
             "ra": {"raise": 90, "out": -4, "twist": -10, "elbow": 2, "wrist": 0}, "la": {"raise": -14, "out": 18, "elbow": 112},
             "lf": {"z": -2.7, "y": 0, "yaw": 0}, "rf": {"y": .14, "toe": -36, "yaw": 20}})
    sh.key(19, hit, "impact")
    sh.key(26, merge(hit, {"root": {"z": -.98}, "ra": {"raise": 88}}), "ease")
    sh.key(34, merge(hit, {"travel": {"z": -1.6}, "root": {"z": -.5, "yaw": 0}, "ra": {"raise": 50, "elbow": 90}, "rf": {"z": -.5, "y": .2, "toe": -16}}), "pass")
    sh.key(42, s({"travel": {"z": -1.98}, "lf": {"z": -2.7}, "rf": {"z": -1.2}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L"], 1)
    return sh.build(markers={"contact": 19 / 60, "recover": 26 / 60})


AIR = {"root": {"y": -.45, "pitch": 12, "yaw": 0}, "torso": {"pitch": 10, "yaw": 0}, "head": {"pitch": -18, "yaw": 0},
       "la": {"raise": 50, "out": 30, "elbow": 90}, "ra": {"raise": 44, "out": 30, "twist": 20, "elbow": 100, "wrist": -20},
       "rf": {"x": 0, "z": -.6, "y": 1.2, "toe": -22, "yaw": 0}, "lf": {"x": 0, "z": -.5, "y": 1.15, "toe": -24, "yaw": 0}}


def air1(arm):
    """Air knee into a kunai cut: compact, the knee rises into the target
    while the reverse-grip blade cuts across - two hits from one fold."""
    sh = Shot(arm, "Flashstep.Air1")
    sh.key(0, AIR, "ease")
    hit = merge(AIR, {"root": {"pitch": 4}, "torso": {"yaw": 20}, "rf": {"z": -1.3, "y": 1.9, "toe": -30},
                      "ra": {"raise": 90, "out": 36, "twist": -10, "elbow": 22, "wrist": 10}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"torso": {"yaw": 26}}), "ease")
    sh.key(20, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def air2(arm):
    """Air straight kick: he opens from the tuck into one straight line,
    heel first, the arms back - a placed blow, no flourish."""
    sh = Shot(arm, "Flashstep.Air2")
    sh.key(0, AIR, "ease")
    sh.key(4, merge(AIR, {"rf": {"z": -.2, "y": 1.6}}), "ease")
    hit = merge(AIR, {"root": {"pitch": -14, "y": -.3}, "torso": {"pitch": -8}, "head": {"pitch": 4},
                      "rf": {"z": -2.4, "y": .9, "toe": 30}, "lf": {"z": .5, "y": .7, "toe": -40},
                      "la": {"raise": 0, "out": 50, "elbow": 30}, "ra": {"raise": -10, "out": 40, "elbow": 60}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"rf": {"z": -2.5}}), "ease")
    sh.key(22, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 8 / 60, "recover": 14 / 60})


def launcher(arm):
    """A rising knee-to-front-kick under the chin, the support foot on its
    toes - he goes up with it."""
    sh = Shot(arm, "Flashstep.Launcher")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.72, "pitch": 14}, "rf": {"y": .1, "toe": -26}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.05, "z": -.3, "pitch": -12, "yaw": 6}, "torso": {"pitch": -8}, "head": {"pitch": 6},
             "rf": {"x": -.2, "z": -1.6, "y": 2.6, "toe": 10, "yaw": 0}, "lf": {"y": .16, "toe": -46},
             "la": {"raise": 110, "out": 20, "elbow": 40}, "ra": {"raise": 60, "out": 30, "elbow": 80, "wrist": -20}})
    sh.key(10, hit, "impact")
    sh.key(13, merge(hit, {"rf": {"y": 2.8}}), "ease")
    sh.key(22, merge(s({"travel": {"z": -.3}}), {"root": {"y": -.56}, "rf": {"z": .48}}), "impact")
    sh.key(30, s({"travel": {"z": -.3}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def rasengan(arm):
    """Rasengan. Form (BurstStrike.Channel, 0.3 s): the right palm opens up
    at the hip, the left hand shapes the sphere over it (the body is still,
    low, square - all the motion is in the hands). Strike (attack variant
    Rasengan): the whole body drives the palm - a long low step, hips
    behind the hand, the palm lands at the end of the reach; the sphere
    grinds, the body keeps pressing (contact hold)."""
    out = []
    form = s({"root": {"y": -.72, "z": .1, "pitch": 18, "yaw": 18}, "torso": {"pitch": 10, "yaw": 4}, "head": {"pitch": -12},
              "ra": {"raise": 58, "out": 8, "twist": -70, "elbow": 76, "wrist": 10}, "la": {"raise": 74, "out": -32, "twist": 44, "elbow": 86, "wrist": -10}})
    ch = Shot(arm, "Flashstep.BurstStrike.Channel")
    ch.key(0, s(), "ease")
    ch.key(8, merge(form, {"la": {"raise": 82, "elbow": 70}}), "ease")
    ch.key(13, merge(form, {"la": {"raise": 70, "out": -28, "elbow": 92}, "ra": {"elbow": 70}}), "pass")
    ch.key(18, form, "ease")
    out.append(ch.build(markers={"release": 18 / 60}))
    st = Shot(arm, "Flashstep.Rasengan")
    st.key(0, form, "ease")
    st.key(3, merge(form, {"root": {"y": -.8, "z": .2, "pitch": 24}, "lf": {"y": .2, "z": -1.0}}), "pass")
    hit = s({"travel": {"z": -1.2}, "root": {"y": -.66, "z": -.95, "pitch": 26, "yaw": -14}, "torso": {"pitch": 10, "yaw": -16}, "head": {"pitch": -12},
             "ra": {"raise": 94, "out": -2, "twist": -40, "elbow": 0, "wrist": -20}, "la": {"raise": 36, "out": 34, "elbow": 48},
             "lf": {"z": -2.8, "y": 0}, "rf": {"y": .18, "toe": -36, "yaw": 20}})
    st.key(7, hit, "impact")
    st.key(16, merge(hit, {"root": {"z": -1.02, "pitch": 24}, "ra": {"raise": 92}}), "ease")
    st.key(24, merge(hit, {"travel": {"z": -1.6}, "root": {"z": -.5, "yaw": 0}, "ra": {"raise": 60, "elbow": 70}, "rf": {"z": -.5, "y": .2, "toe": -16}}), "pass")
    st.key(34, s({"travel": {"z": -2.08}, "lf": {"z": -2.8}, "rf": {"z": -1.3}}), "ease")
    st.drag(["neck"], 2)
    out.append(st.build(markers={"contact": 7 / 60, "recover": 16 / 60}))
    return out


def ftg(arm):
    """Flying Thunder God. Intent (Channel, 0.06 s): the weight drops a
    little and the kunai hand closes - nothing more, he does not announce it.
    Arrival (Release): he appears already in his stance, low, turned to the
    opponent, the blade ready, the weight centred: the momentum of a body
    that chose where to land. Recover: he rises just enough to choose."""
    out = []
    ch = Shot(arm, "Flashstep.Flashstep.Channel")
    ch.key(0, s(), "ease")
    ch.key(4, s({"root": {"y": -.52}, "ra": {"raise": 44, "wrist": -30}, "la": {"raise": 62, "out": -10, "twist": 20, "elbow": 96}}), "ease")
    out.append(ch.build(markers={"release": 4 / 60}))
    arrive = s({"root": {"y": -.95, "z": .1, "pitch": 18, "yaw": 26}, "torso": {"pitch": 10, "yaw": -10}, "head": {"pitch": -16, "yaw": -10},
                "ra": {"raise": 50, "out": 20, "twist": 24, "elbow": 80, "wrist": -24}, "la": {"raise": 10, "out": 30, "elbow": 30},
                "lf": {"z": -.9}, "rf": {"z": .95, "yaw": 40}})
    re = Shot(arm, "Flashstep.Flashstep.Release")
    re.key(0, arrive, "impact")
    re.key(3, merge(arrive, {"root": {"y": -1.0}}), "ease")
    out.append(re.build(markers={"release": 0.0}))
    rc = Shot(arm, "Flashstep.Flashstep.Recover")
    rc.key(0, merge(arrive, {"root": {"y": -1.0}}), "ease")
    rc.key(8, merge(arrive, {"root": {"y": -.66}, "la": {"raise": 48, "out": 4, "elbow": 74}}), "pass")
    rc.key(14, merge(s(), {"lf": {"z": -.9}, "rf": {"z": .95}}), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


def throws(arm):
    """Kunai throws on the move (upper body over his run): a flat flick from
    the reverse grip - the forearm turns over and the wrist snaps at the
    release, the chest only a quarter turn. The marked kunai: the same flick
    from the left hand while the right keeps its blade."""
    out = []
    k = Shot(arm, "Flashstep.Throw.Kunai")
    k.key(0, s(), "ease")
    k.key(4, s({"torso": {"yaw": 14}, "ra": {"raise": 120, "out": 30, "twist": -30, "elbow": 112, "wrist": -24}}), "ease")
    rel = s({"torso": {"yaw": -16, "pitch": 6}, "ra": {"raise": 92, "out": 4, "twist": 20, "elbow": 8, "wrist": 36}})
    k.key(7, rel, "impact")
    k.key(11, merge(rel, {"ra": {"raise": 70, "out": -16, "wrist": 26}}), "ease")
    k.key(22, s(), "ease")
    out.append(k.build(markers={"release": 7 / 60}))
    m = Shot(arm, "Flashstep.Throw.MarkedKunai")
    m.key(0, s(), "ease")
    m.key(4, s({"torso": {"yaw": -14}, "la": {"raise": 120, "out": 30, "twist": -30, "elbow": 112, "wrist": -20}}), "ease")
    rel = s({"torso": {"yaw": 16, "pitch": 6}, "la": {"raise": 94, "out": 4, "twist": 20, "elbow": 6, "wrist": 36}})
    m.key(7, rel, "impact")
    m.key(11, merge(rel, {"la": {"raise": 72, "out": -14}}), "ease")
    m.key(22, s(), "ease")
    out.append(m.build(markers={"release": 7 / 60}))
    return out


def author(arm):
    acts = [idle(arm), run(arm), run_back(arm), run_side(arm, "R"), run_side(arm, "L"), walk(arm), walk_back(arm),
            walk_side(arm, "R"), walk_side(arm, "L"), sprint(arm), start(arm), brake(arm),
            jump_air(arm), jump_leap(arm), land(arm),
            light1(arm), light2(arm), light3(arm), heavy(arm), air1(arm), air2(arm), launcher(arm)]
    acts += rasengan(arm)
    acts += ftg(arm)
    acts += throws(arm)
    return acts
