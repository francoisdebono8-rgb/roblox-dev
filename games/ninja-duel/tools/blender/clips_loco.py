"""Locomotion for each fighter, authored in Blender (nd_cycle).

Clip set per fighter id F (the runtime looks them up by these names):
  F.Idle                          loop
  F.Walk.F / .B / .L / .R         loops, meta stride (studs per cycle)
  F.Run.F / .B / .L / .R          loops
  F.Sprint                        loop (the ninja run)
  F.Jump.Air                      standing jump, time = rise -> apex -> fall
  F.Jump.Leap                     running jump, same time axis
  F.Flip                          tuck through a flip, time = flip progress
  F.Land                          touch-down and recovery into the stance
Cycles start on the right foot's strike (phase 0) and the left's at .5, so
every direction and speed blends in step.
"""
import math
from nd_anim import merge
from nd_cycle import cycle, arc, bake, add, lerp_spec, reach_report

DIRS = {"F": 0, "R": 90, "B": 180, "L": -90}


def styles(fighter, stance):
    guard = {"ra": stance["ra"], "la": stance["la"]}
    if fighter == "Lion":
        # Sasuke: low, predatory, hands loose and low; the run hunts forward.
        walk = dict(S=3.3, duty=.62, y0=-.42, bob=.07, walk=True, lean=6, chest=5, lift=.32, heel=.3, width=.5,
                    hipYaw=9, twist=6, roll=3, arm=26, elbow=36, elbowSwing=10, armBase=4, armOut=12, face=66, counter=.62,
                    strafeRoll=3, guard=guard, guardOn=.85, headPitch=-4, accents=[
                        (.08, .07, {"root": {"y": -.05, "pitch": 2}, "torso": {"pitch": 2}})])
        # The run already leans into the ninja run: chest low, arms trailing
        # half back with a short swing; the sprint takes them all the way.
        run = dict(S=7.0, duty=.32, y0=-.56, bob=.17, lean=20, chest=15, lift=.98, heel=.42, width=.48,
                   hipYaw=12, twist=10, roll=4, arm=20, elbow=42, elbowSwing=12, armBase=-20, armOut=18, armTwist=-6,
                   face=70, counter=.6, strafeRoll=8, guard=guard, guardOn=.75, headPitch=-6, point=26, push=34,
                   pitchBob=4, accents=[(.06, .05, {"root": {"y": -.06, "pitch": 3}, "torso": {"pitch": 3}, "head": {"pitch": -2}})])
        sprint = dict(S=12.5, duty=.22, y0=-.74, bob=.18, lean=30, chest=22, lift=1.25, heel=.45, width=.46,
                      hipYaw=10, twist=4, roll=3, arm=7, elbow=10, elbowSwing=4, armBase=-38, armOut=18, armTwist=-12,
                      headPitch=-10, headComp=.9, point=30, push=40, pitchBob=5)
        idle = dict(period=2.6, breath=.035, chest=1.8, sway=.025, bounce=0)
    else:
        # Minato: light, long and fast, upright chest, arms sharp and economical.
        walk = dict(S=3.5, duty=.6, y0=-.36, bob=.06, walk=True, lean=5, chest=4, lift=.3, heel=.3, width=.52,
                    hipYaw=8, twist=6, roll=2.5, arm=30, elbow=30, elbowSwing=10, armBase=6, armOut=10, face=66, counter=.62,
                    strafeRoll=3, guard=guard, guardOn=.8, headPitch=-3)
        run = dict(S=7.6, duty=.3, y0=-.5, bob=.2, lean=22, chest=14, lift=.95, heel=.4, width=.5,
                   hipYaw=11, twist=8, roll=3, arm=16, elbow=30, elbowSwing=10, armBase=-26, armOut=22, armTwist=-10,
                   face=70, counter=.6, strafeRoll=7, guard=guard, guardOn=.7, headPitch=-5, point=24, push=32,
                   pitchBob=3, accents=[(.05, .05, {"root": {"y": -.05}, "torso": {"pitch": 2}})])
        sprint = dict(S=13.5, duty=.2, y0=-.7, bob=.2, lean=34, chest=24, lift=1.2, heel=.45, width=.46,
                      hipYaw=9, twist=4, roll=2, arm=6, elbow=8, elbowSwing=3, armBase=-42, armOut=22, armTwist=-14,
                      headPitch=-12, headComp=.95, point=32, push=42, pitchBob=4)
        idle = dict(period=1.0, breath=.02, chest=1.2, sway=.0, bounce=.07)
    return walk, run, sprint, idle


def back_variant(G):
    """Backpedal: shorter steps, sitting back behind the guard."""
    g = dict(G)
    g["S"] = G["S"] * .72
    g["lift"] = G["lift"] * .7
    g["accents"] = []
    return g


def idle_spec(stance, I, u):
    """The idle is the fighting stance breathing (Sasuke) or bouncing on the
    balls of the feet (Minato)."""
    s = merge(stance, {})
    ph = math.tau * u
    b = math.sin(ph)
    s = add(s, {"root": {"y": I["breath"] * b},
                "torso": {"pitch": I["chest"] * b}, "head": {"pitch": -I["chest"] * .5 * b},
                "ra": {"raise": -1.5 * b, "elbow": 2 * b}, "la": {"raise": -1.5 * b, "elbow": -2 * b}})
    if I["bounce"]:
        h = abs(math.sin(2 * ph))
        s = add(s, {"root": {"y": I["bounce"] * (h - .5) * 1.4}, "rf": {"y": .1 * h, "toe": -14 * h},
                    "lf": {"y": .1 * h, "toe": -14 * h}, "ra": {"raise": 3 * h}, "la": {"raise": 3 * h}})
    return s


def jump_keys(stance, fighter):
    """Standing jump on the arc's time axis (0 = take-off, .5 = apex, 1 = about
    to land). Free legs throughout: the knee drives, both legs tuck high at
    the top, then open and reach for the floor with the arms up and out."""
    m = 1.0 if fighter == "Lion" else 1.12
    take = {"root": {"pitch": -2}, "torso": {"pitch": -6}, "head": {"pitch": -14},
            "ra": {"raise": 120, "out": 20, "elbow": 30}, "la": {"raise": 132, "out": 14, "elbow": 26},
            "rl": {"lift": 70, "knee": 104, "ankle": -16}, "ll": {"lift": -12, "knee": 18, "ankle": -40}}
    rise = {"root": {"pitch": 6}, "torso": {"pitch": 6}, "head": {"pitch": -8},
            "ra": {"raise": 74, "out": 40 * m, "elbow": 60}, "la": {"raise": 84, "out": 34 * m, "elbow": 64},
            "rl": {"lift": 104, "knee": 128, "ankle": -14}, "ll": {"lift": 64, "knee": 118, "ankle": -20}}
    apex = {"root": {"pitch": 16}, "torso": {"pitch": 18}, "head": {"pitch": -18},
            "ra": {"raise": 58, "out": 46 * m, "elbow": 96}, "la": {"raise": 62, "out": 42 * m, "elbow": 100},
            "rl": {"lift": 118, "knee": 142, "ankle": -16}, "ll": {"lift": 108, "knee": 140, "ankle": -18}}
    fall = {"root": {"pitch": 6}, "torso": {"pitch": 4}, "head": {"pitch": -16},
            "ra": {"raise": 70, "out": 66 * m, "elbow": 30}, "la": {"raise": 66, "out": 62 * m, "elbow": 34},
            "rl": {"lift": 60, "knee": 76, "ankle": -8}, "ll": {"lift": 34, "knee": 56, "ankle": -10}}
    reach = {"root": {"pitch": 4}, "torso": {"pitch": 6}, "head": {"pitch": -14},
             "ra": {"raise": 44, "out": 70 * m, "elbow": 22}, "la": {"raise": 40, "out": 66 * m, "elbow": 26},
             "rl": {"lift": 36, "knee": 40, "ankle": 4}, "ll": {"lift": 14, "knee": 30, "ankle": 0}}
    return [(0, take), (.18, rise), (.48, apex), (.76, fall), (1, reach)]


def leap_keys(stance, fighter):
    """Running jump: a split stride through the air, arms swept back."""
    lean = 20 if fighter == "Lion" else 24
    take = {"root": {"pitch": lean}, "torso": {"pitch": 14}, "head": {"pitch": -30},
            "ra": {"raise": -50, "out": 14, "elbow": 18}, "la": {"raise": -50, "out": 14, "elbow": 18},
            "rl": {"lift": 80, "knee": 104, "ankle": -14}, "ll": {"lift": -34, "knee": 26, "ankle": -36}}
    split = {"root": {"pitch": lean - 2}, "torso": {"pitch": 12}, "head": {"pitch": -28},
             "ra": {"raise": -60, "out": 20, "elbow": 10}, "la": {"raise": -60, "out": 20, "elbow": 10},
             "rl": {"lift": 78, "knee": 44, "ankle": -18}, "ll": {"lift": -42, "knee": 70, "ankle": -30}}
    gather = {"root": {"pitch": lean - 8}, "torso": {"pitch": 10}, "head": {"pitch": -22},
              "ra": {"raise": -40, "out": 26, "elbow": 24}, "la": {"raise": -40, "out": 26, "elbow": 24},
              "rl": {"lift": 70, "knee": 76, "ankle": -10}, "ll": {"lift": -8, "knee": 84, "ankle": -16}}
    reach = {"root": {"pitch": 6}, "torso": {"pitch": 6}, "head": {"pitch": -14},
             "ra": {"raise": 10, "out": 40, "elbow": 30}, "la": {"raise": 10, "out": 40, "elbow": 30},
             "rl": {"lift": 46, "knee": 34, "ankle": -2}, "ll": {"lift": 6, "knee": 46, "ankle": -10}}
    return [(0, take), (.3, split), (.62, gather), (1, reach)]


def flip_keys():
    """Through a flip: open, tight tuck (shins hugged), open for the landing."""
    open_ = {"root": {"pitch": 4}, "torso": {"pitch": 6}, "head": {"pitch": -10},
             "ra": {"raise": 60, "out": 30, "elbow": 40}, "la": {"raise": 60, "out": 30, "elbow": 40},
             "rl": {"lift": 60, "knee": 90}, "ll": {"lift": 40, "knee": 80}}
    tuck = {"root": {"pitch": 10}, "torso": {"pitch": 30}, "head": {"pitch": 24},
            "ra": {"raise": 78, "out": 10, "twist": 10, "elbow": 112}, "la": {"raise": 76, "out": 10, "twist": 10, "elbow": 116},
            "rl": {"lift": 126, "knee": 146, "ankle": -20}, "ll": {"lift": 118, "knee": 148, "ankle": -20}}
    land = {"root": {"pitch": 6}, "torso": {"pitch": 6}, "head": {"pitch": -14},
            "ra": {"raise": 30, "out": 64, "elbow": 24}, "la": {"raise": 30, "out": 62, "elbow": 26},
            "rl": {"lift": 40, "knee": 44}, "ll": {"lift": 26, "knee": 38}}
    return [(0, open_), (.25, tuck), (.7, tuck), (1, land)]


def land_keys(stance):
    """Touch-down: the knees take it in two or three frames, the arms open for
    balance, then the body rises back into the fighting stance."""
    impact = merge(stance, {"root": {"y": stance["root"]["y"] - .95, "pitch": stance["root"].get("pitch", 0) + 20},
                            "torso": {"pitch": 18}, "head": {"pitch": -14},
                            "ra": {"raise": 30, "out": 58, "twist": 0, "elbow": 30}, "la": {"raise": 34, "out": 54, "twist": 0, "elbow": 34},
                            "rf": {"x": stance["rf"]["x"] + .3}, "lf": {"x": stance["lf"]["x"] - .3}})
    touch = merge(stance, {"root": {"y": stance["root"]["y"] - .3, "pitch": 6}, "torso": {"pitch": 4},
                           "ra": {"raise": 26, "out": 56, "elbow": 26}, "la": {"raise": 28, "out": 52, "elbow": 30},
                           "rf": {"x": stance["rf"]["x"] + .3}, "lf": {"x": stance["lf"]["x"] - .3}})
    settle = merge(stance, {"root": {"y": stance["root"]["y"] - .5}, "torso": {"pitch": stance["torso"]["pitch"] + 8}})
    return [(0, touch), (.12, impact, "snap"), (.42, settle), (1, stance)]


def author(arm, fighter, stance):
    acts, report = [], {}
    walk, run, sprint, I = styles(fighter, stance)
    acts.append(bake(arm, fighter + ".Idle", lambda u: idle_spec(stance, I, u), int(I["period"] * 60),
                     2, True, None, {"period": I["period"]}))
    for gname, G in (("Walk", walk), ("Run", run)):
        for d, theta in DIRS.items():
            g = back_variant(G) if d == "B" else G
            acts.append(cycle(arm, "%s.%s.%s" % (fighter, gname, d), g, theta))
            report["%s.%s" % (gname, d)] = reach_report(g, theta)
    acts.append(cycle(arm, fighter + ".Sprint", sprint, 0, 40))
    report["Sprint"] = reach_report(sprint, 0)
    acts.append(arc(arm, fighter + ".Jump.Air", jump_keys(stance, fighter), 60))
    acts.append(arc(arm, fighter + ".Jump.Leap", leap_keys(stance, fighter), 60))
    acts.append(arc(arm, fighter + ".Flip", flip_keys(), 36))
    acts.append(arc(arm, fighter + ".Land", land_keys(stance), 30))
    print("reach", fighter, report)
    return acts
