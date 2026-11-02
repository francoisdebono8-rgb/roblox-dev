"""Stage 6, the move list's remaining gaps (02/11).

Kakashi's tanto (the move list, "Sabre dégainé (B)"): with the blade out his
whole close game cuts - three tanto cuts (the third throws), a rising cut, a
low cut, a feinted step into a cut on the flank, a thrust charged with white
chakra (guard break), cuts in the air and a plunging cut. Until now he played
the shared Kunai.* clips (Sasuke's knife) on four moves and his own punches
and kicks, blade in hand, on the rest. Played as "Copycat.Blade.<move>" by
the motion engine whenever the blade is drawn (Motion.kunaiClip).

Reverse grip (the game's knife family, kakashi_p6): the cuts are carried by
the hips and the shoulder, the forearm leads and the blade trails it - a
backhand that opens, a hammer cut that drops, a thrust that punches the
point through.

Naruto's running heavy ("course + △ : plongée tête la première"): out of a
full run he throws himself head first, arms ahead, body flat like a missile,
into the stomach, rolls out of the landing and comes up.

Server frame data (startup with the profile): Light1 .083 Light2 .094
Light3 .12 Heavy .294 Launcher .163 Sweep .12 FeintStep .10 DashAttack .064
Air1 .075 Air2 .085 AirSpike .09; HeadDive .12 / .16 / .42.
"""
from nd_shot import merge
import kakashi_p6, naruto_p5, sasuke_p1, kunai_lion, itachi_p3, clips_flash2, neji_p9, lee_p8, gaara_p7
from ult_clips import clip, fly, DOWN, BENT, TUCK, KNEE, KICK, AXE, HEEL_UP

F = 60


def keys(spec):
    """(frame, pose, spacing) rows -> clip rows in seconds."""
    return [(f / F, p, sp) for f, p, sp in spec]


def mk(arm, name, rows, contact, recover):
    act = clip(arm, name, keys(rows))
    act["nd_markers"] = {"contact": contact / F, "recover": recover / F}
    return act


# ============================================================== Kakashi
K = kakashi_p6
s, AIR = K.s, K.AIR
# The blade hand's guard: the forearm across the centre line, point down the line.
GUARD_R = {"raise": 62, "out": -14, "twist": 20, "elbow": 70, "wrist": -34}


def ks(over=None):
    return s(merge({"ra": GUARD_R}, over or {}))


def blade_light1(arm):
    """Rising backhand: the hips coil away, the forearm drops to the left hip,
    then the hips and chest turn through and the blade rises across the body,
    low left -> high right, overshoots above the shoulder."""
    coil = ks({"root": {"y": -.62, "pitch": 14, "yaw": 50}, "torso": {"pitch": 12, "yaw": 26}, "head": {"yaw": -50},
               "ra": {"raise": 20, "out": -60, "twist": 40, "elbow": 70, "wrist": -20}, "la": {"raise": 70, "out": -10, "elbow": 60},
               "lf": {"z": -.7, "y": .15, "toe": 10}})
    hit = ks({"root": {"y": -.56, "z": -.45, "pitch": 12, "yaw": -6, "roll": -4}, "torso": {"pitch": 4, "yaw": -34, "roll": -8}, "head": {"yaw": 30},
              "ra": {"raise": 96, "out": 40, "twist": -30, "elbow": 6, "wrist": -30}, "la": {"raise": 10, "out": 60, "elbow": 30},
              "lf": {"z": -1.2}, "rf": {"y": .14, "toe": -30}})
    over = merge(hit, {"torso": {"yaw": -46}, "ra": {"raise": 140, "out": 50, "elbow": 14}, "head": {"yaw": 40}})
    return mk(arm, "Copycat.Blade.Light1", [(0, ks(), "ease"), (3, coil, "ease"), (6, hit, "impact"), (10, over, "ease"),
                                             (14, merge(over, {"ra": {"raise": 134}}), "ease"), (26, ks({"lf": {"z": -.8}}), "ease")], 6, 12)


def blade_light2(arm):
    """Flat return cut, stepping through: the blade wound behind the right
    shoulder, the rear foot passes, and the arm sweeps flat right -> left at
    chest height, the chest whipping round after the hips."""
    wind = ks({"root": {"y": -.6, "pitch": 12, "yaw": -30}, "torso": {"pitch": 8, "yaw": -40}, "head": {"yaw": 30},
               "ra": {"raise": 80, "out": 70, "twist": -20, "elbow": 60, "wrist": 10}, "la": {"raise": 40, "out": 30, "elbow": 80}})
    hit = ks({"root": {"y": -.66, "z": -.55, "pitch": 14, "yaw": 26, "roll": 6}, "torso": {"pitch": 6, "yaw": 34, "roll": 8}, "head": {"yaw": -40},
              "ra": {"raise": 88, "out": -40, "twist": 30, "elbow": 4, "wrist": -10}, "la": {"raise": 50, "out": -20, "elbow": 100},
              "rf": {"x": .24, "z": -1.1, "y": 0, "toe": 0, "yaw": 20}, "lf": {"y": .1, "toe": -20}})
    over = merge(hit, {"torso": {"yaw": 50}, "ra": {"out": -70}})
    return mk(arm, "Copycat.Blade.Light2", [(0, ks(), "ease"), (4, wind, "ease"), (7, hit, "impact"), (11, over, "ease"),
                                             (15, merge(over, {"root": {"y": -.62}}), "ease"), (28, ks(), "ease")], 7, 14)


def blade_light3(arm):
    """Spinning cut that throws: a full turn on the front foot, the head
    spotting first, the arm long so the blade draws a flat circle; it crosses
    the body at the end of the turn, the weight thrown through."""
    st = ks()
    rows = [(0, st, "ease"),
            (3, merge(st, {"root": {"y": -.68, "yaw": -30, "pitch": 12}, "torso": {"yaw": -26}, "head": {"yaw": 40},
                           "ra": {"raise": 60, "out": -60, "elbow": 100}}), "ease"),
            (6, merge(st, {"root": {"y": -.56, "yaw": 90, "pitch": 8}, "torso": {"yaw": 14}, "head": {"yaw": 70},
                           "ra": {"raise": 84, "out": 40, "elbow": 30}, "rf": {"yaw": 90}, "lf": {"x": .3, "z": .2, "y": .4, "toe": -20, "yaw": 80}}), "pass"),
            (8, merge(st, {"root": {"y": -.52, "yaw": 200, "pitch": 6, "roll": 8}, "torso": {"yaw": 20}, "head": {"yaw": 80},
                           "ra": {"raise": 90, "out": 80, "elbow": 6}, "rf": {"yaw": 200}, "lf": {"x": .9, "z": -.3, "y": .5, "toe": -16, "yaw": 190}}), "pass")]
    hit = merge(st, {"root": {"y": -.62, "z": -.4, "yaw": 340, "pitch": 14, "roll": 12}, "torso": {"yaw": 8, "roll": 10, "pitch": 8}, "head": {"yaw": 10},
                     "ra": {"raise": 90, "out": 90, "twist": -10, "elbow": 0, "wrist": 10}, "la": {"raise": 26, "out": 70, "elbow": 30},
                     "rf": {"yaw": 340}, "lf": {"x": -.1, "z": -1.5, "y": 0, "toe": 0, "yaw": 330}})
    rows += [(10, hit, "impact"), (14, merge(hit, {"root": {"yaw": 368}, "ra": {"out": 110}}), "ease"),
             (24, merge(hit, {"root": {"yaw": 380, "y": -.7, "roll": 4}, "ra": {"raise": 70, "out": 40, "elbow": 70}}), "ease"),
             (38, ks({"root": {"yaw": 360 + K.STANCE["root"]["yaw"]}, "rf": {"yaw": 390}, "lf": {"yaw": 354}}), "ease")]
    return mk(arm, "Copycat.Blade.Light3", rows, 10, 18)


def blade_heavy(arm):
    """The white light: he draws the blade back along the hip (the chakra
    gathers, the body sinks and coils), then the whole body lunges behind
    the point - a thrust punched straight through the guard."""
    draw = ks({"root": {"y": -.95, "z": .25, "pitch": 18, "yaw": 60}, "torso": {"pitch": 10, "yaw": 20}, "head": {"pitch": -14, "yaw": -60},
               "ra": {"raise": 20, "out": 30, "twist": -40, "elbow": 110, "wrist": -60}, "la": {"raise": 84, "out": -30, "elbow": 10},
               "rf": {"z": .9, "toe": -20}, "lf": {"z": -.7}})
    hold = merge(draw, {"root": {"y": -1.0, "z": .3}, "ra": {"elbow": 116}})
    thrust = ks({"root": {"y": -.7, "z": -.9, "pitch": 24, "yaw": 4}, "torso": {"pitch": 12, "yaw": -18}, "head": {"pitch": -18, "yaw": 10},
                 "ra": {"raise": 90, "out": -4, "twist": 0, "elbow": 0, "wrist": -70}, "la": {"raise": -20, "out": 50, "elbow": 20},
                 "lf": {"z": -2.0, "yaw": 0}, "rf": {"z": .9, "y": .2, "toe": -40, "yaw": 10}})
    return mk(arm, "Copycat.Blade.Heavy", [(0, ks(), "ease"), (8, draw, "ease"), (16, hold, "ease"), (18, thrust, "impact"),
                                            (26, merge(thrust, {"root": {"z": -.95}}), "ease"), (32, merge(thrust, {"ra": {"raise": 70, "elbow": 40}}), "ease"),
                                            (46, ks(), "ease")], 18, 30)


def blade_launcher(arm):
    """Rising cut: down on one knee's worth, the blade low behind the right
    heel, then up - the legs extend, the body rises onto the toes and the
    blade goes straight up past the chin."""
    low = ks({"root": {"y": -1.15, "pitch": 26, "yaw": 20}, "torso": {"pitch": 20, "yaw": 10}, "head": {"pitch": -24},
              "ra": {"raise": -40, "out": 20, "twist": 10, "elbow": 20, "wrist": -40}, "la": {"raise": 60, "out": -10, "elbow": 70},
              "rf": {"z": .8, "toe": -30}})
    up = ks({"root": {"y": -.2, "z": -.4, "pitch": -12, "yaw": 0}, "torso": {"pitch": -14, "yaw": -10}, "head": {"pitch": -30},
             "ra": {"raise": 170, "out": 6, "twist": -10, "elbow": 6, "wrist": -20}, "la": {"raise": -20, "out": 50, "elbow": 20},
             "rf": {"z": .6, "y": .3, "toe": -50}, "lf": {"z": -.9, "toe": -20}})
    return mk(arm, "Copycat.Blade.Launcher", [(0, ks(), "ease"), (6, low, "ease"), (10, up, "impact"), (16, merge(up, {"ra": {"raise": 176}}), "ease"),
                                               (32, ks(), "ease")], 10, 20)


def blade_sweep(arm):
    """Low cut: he drops under the guard, the left hand on the floor, and
    the blade cuts flat at shin height across the front."""
    drop = ks({"root": {"y": -1.5, "pitch": 30, "yaw": -30}, "torso": {"pitch": 26, "yaw": -30}, "head": {"pitch": -30, "yaw": 20},
               "ra": {"raise": 30, "out": 70, "elbow": 40, "wrist": 0}, "la": {"raise": 40, "out": 10, "elbow": 10},
               "rf": {"z": .9, "x": .5}, "lf": {"z": -.9, "x": -.4}})
    hit = merge(drop, {"root": {"yaw": 30, "y": -1.55}, "torso": {"yaw": 30}, "head": {"yaw": -20},
                       "ra": {"raise": 30, "out": -50, "twist": 30, "elbow": 4, "wrist": -10}})
    return mk(arm, "Copycat.Blade.Sweep", [(0, ks(), "ease"), (5, drop, "ease"), (7, hit, "impact"), (12, merge(hit, {"ra": {"out": -70}}), "ease"),
                                            (30, ks(), "ease")], 7, 16)


def blade_feint(arm):
    """Feinted step: the shoulders show one side, the feet go the other
    (the step), and from the flank the blade comes round in a short cut."""
    show = ks({"root": {"y": -.6, "x": .3, "yaw": -30, "roll": 8}, "torso": {"yaw": -20}, "head": {"yaw": 20},
               "ra": {"raise": 70, "out": 50, "elbow": 50}})
    step = ks({"root": {"y": -.7, "x": -.5, "yaw": 40, "roll": -8}, "torso": {"yaw": 10}, "head": {"yaw": -30},
               "ra": {"raise": 60, "out": -60, "twist": 40, "elbow": 90}, "lf": {"x": -.9, "z": -.4}, "rf": {"x": -.2, "z": .5}})
    hit = ks({"root": {"y": -.62, "x": -.6, "z": -.3, "yaw": -10, "roll": -4}, "torso": {"yaw": -36}, "head": {"yaw": 30},
              "ra": {"raise": 88, "out": 50, "twist": -30, "elbow": 4, "wrist": -20}, "lf": {"x": -.9, "z": -.6}, "rf": {"x": -.1, "z": .4}})
    return mk(arm, "Copycat.Blade.FeintStep", [(0, ks(), "ease"), (2, show, "ease"), (4, step, "pass"), (7, hit, "impact"),
                                                (12, merge(hit, {"ra": {"out": 70}}), "ease"), (27, ks(), "ease")], 7, 15)


def blade_dash(arm):
    """Running thrust: the run carries straight into a low lunge, the point first."""
    hit = ks({"root": {"y": -.75, "z": -.6, "pitch": 30, "yaw": 0}, "torso": {"pitch": 14, "yaw": -14}, "head": {"pitch": -24},
              "ra": {"raise": 86, "out": -6, "elbow": 2, "wrist": -70}, "la": {"raise": -20, "out": 40, "elbow": 20},
              "lf": {"z": -1.8, "yaw": 0}, "rf": {"z": 1.0, "y": .3, "toe": -40, "yaw": 0}})
    return mk(arm, "Copycat.Blade.DashAttack", [(0, ks({"root": {"pitch": 24, "y": -.6}}), "ease"), (4, hit, "impact"),
                                                 (9, merge(hit, {"root": {"z": -.7}}), "ease"), (22, ks(), "ease")], 4, 10)


def blade_air(arm, name, side):
    """An air cut: the knees tucked, the hips turn the cut through."""
    wind = fly(AIR, (KNEE, TUCK), {"root": {"yaw": -30 * side, "pitch": 6}, "torso": {"yaw": -20 * side},
                                   "ra": {"raise": 90, "out": 60 * side, "elbow": 60}})
    hit = fly(AIR, (BENT, KNEE), {"root": {"yaw": 24 * side, "pitch": 14, "roll": -8 * side}, "torso": {"yaw": 30 * side},
                                  "ra": {"raise": 92, "out": -50 * side, "twist": 20, "elbow": 4, "wrist": -20}})
    return mk(arm, "Copycat.Blade." + name, [(0, fly(AIR, (BENT, DOWN)), "ease"), (3, wind, "ease"), (5, hit, "impact"),
                                              (9, merge(hit, {"ra": {"out": -70 * side}}), "ease"), (20, fly(AIR, (BENT, DOWN)), "ease")], 5, 11)


def blade_spike(arm):
    """Plunging cut: the blade raised over the head, the body folds and the
    arm chops straight down through the body below."""
    up = fly(AIR, (TUCK, KNEE), {"root": {"pitch": -14}, "torso": {"pitch": -10}, "head": {"pitch": 10},
                                 "ra": {"raise": 176, "out": 0, "elbow": 20, "wrist": -30}, "la": {"raise": 120, "out": 30, "elbow": 40}})
    down = fly(AIR, (BENT, KICK), {"root": {"pitch": 34}, "torso": {"pitch": 24}, "head": {"pitch": 26},
                                   "ra": {"raise": 40, "out": 0, "elbow": 0, "wrist": 20}, "la": {"raise": -20, "out": 50}})
    return mk(arm, "Copycat.Blade.AirSpike", [(0, fly(AIR, (BENT, DOWN)), "ease"), (3, up, "ease"), (5, down, "impact"),
                                               (10, merge(down, {"ra": {"raise": 26}}), "ease"), (24, fly(AIR, (BENT, DOWN)), "ease")], 5, 12)


def blade_slam(arm):
    """The air string's heavy, blade out: the plunging cut (move list)."""
    act = blade_spike(arm)
    act.name = "Copycat.Blade.Slam"
    return act


def kakashi(arm):
    return [blade_slam(arm), slam(arm, "Copycat", K.AIR, K.s, "heel"), blade_light1(arm), blade_light2(arm), blade_light3(arm), blade_heavy(arm), blade_launcher(arm), blade_sweep(arm),
            blade_feint(arm), blade_dash(arm), blade_air(arm, "Air1", 1), blade_air(arm, "Air2", -1), blade_spike(arm)]


# =============================================================== Naruto
def naruto(arm):
    s_ = naruto_p5.s
    arms = {"ra": {"raise": 170, "out": 6, "twist": 0, "elbow": 6, "wrist": 0}, "la": {"raise": 170, "out": 6, "twist": 0, "elbow": 6, "wrist": 0}}
    # (out of the run: the legs already in pelvis space, so the take-off turns smoothly)
    load = fly(naruto_p5.AIR, ((.1, -1.55, .6), (-.1, -1.3, -.7)), {"root": {"y": -1.0, "pitch": 34, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0},
               "head": {"pitch": -30, "yaw": 0}, "ra": {"raise": -40, "out": 20, "elbow": 30}, "la": {"raise": -40, "out": 20, "elbow": 30}})
    flight = fly(naruto_p5.AIR, ((.1, -.3, 1.9), (-.1, -.2, 1.85)), merge(arms, {"root": {"y": -.9, "z": -.6, "pitch": 84}, "torso": {"pitch": 4}, "head": {"pitch": -50}}))
    hit = merge(flight, {"root": {"z": -.9, "pitch": 80}, "head": {"pitch": -40}})
    # the landing: on the hands, a forward roll, up on one knee, up
    roll1 = fly(naruto_p5.AIR, (TUCK, TUCK), {"root": {"y": -1.6, "z": -1.2, "pitch": 170}, "torso": {"pitch": 30}, "head": {"pitch": 40},
                                             "ra": {"raise": 90, "out": 20, "elbow": 80}, "la": {"raise": 90, "out": 20, "elbow": 80}})
    roll2 = fly(naruto_p5.AIR, (TUCK, KNEE), {"root": {"y": -1.5, "z": -1.4, "pitch": 290}, "torso": {"pitch": 30}, "head": {"pitch": 30},
                                             "ra": {"raise": 40, "out": 40, "elbow": 60}, "la": {"raise": 40, "out": 40, "elbow": 60}})
    kneel = s_({"root": {"y": -1.3, "z": -1.4, "pitch": 380}, "torso": {"pitch": 16}, "rf": {"z": -.6}, "lf": {"z": -2.0, "toe": -40},
                "la": {"raise": -20, "out": 40}})
    rows = [(0, load, "ease"), (4, flight, "launch"), (7, hit, "impact"), (16, merge(hit, {"root": {"y": -1.3}}), "ease"),
            (20, roll1, "pass"), (26, roll2, "pass"), (31, kneel, "impact"),
            (42, s_({"root": {"pitch": 360 + naruto_p5.STANCE["root"]["pitch"]}}), "ease")]
    return [mk(arm, "Legion.HeadDive", rows, 7, 20), slam(arm, "Legion", naruto_p5.AIR, naruto_p5.s, "hammer")]




# ======================================================== air heavies
# The heavy that ends an air string (the server's Slam, .15 / .20 / .38):
# each fighter's own, from the move list's "air □ □ △". The body comes down
# with the blow (the server carries it); the clip ends crouched on the floor.
def slam(arm, fid, AIRP, s_, kind):
    neutral = fly(AIRP, (BENT, DOWN))
    if kind == "heel":            # Talon écrasant / Talon: the heel raised over the head, then down through
        wind = fly(AIRP, (HEEL_UP, BENT), {"root": {"pitch": -22}, "torso": {"pitch": -12}, "head": {"pitch": 6},
                                           "ra": {"raise": 30, "out": 70, "elbow": 20}, "la": {"raise": 30, "out": 70, "elbow": 20}})
        hit = fly(AIRP, (AXE, BENT), {"root": {"pitch": 18}, "torso": {"pitch": 16}, "head": {"pitch": 20},
                                      "ra": {"raise": -10, "out": 50, "elbow": 20}, "la": {"raise": -10, "out": 50, "elbow": 20}})
        follow = fly(AIRP, ((0, -1.5, -.9), BENT), {"root": {"pitch": 24}, "torso": {"pitch": 18}})
    elif kind == "hammer":        # Naruto: both fists clasped over the head, brought down with the clones
        clasp = {"raise": 170, "out": -14, "twist": 0, "elbow": 36, "wrist": 0}
        down = {"raise": 60, "out": -12, "twist": 0, "elbow": 8, "wrist": 10}
        wind = fly(AIRP, (TUCK, KNEE), {"root": {"pitch": -14}, "torso": {"pitch": -18}, "head": {"pitch": -10}, "ra": clasp, "la": clasp})
        hit = fly(AIRP, (BENT, BENT), {"root": {"pitch": 40}, "torso": {"pitch": 30}, "head": {"pitch": -20}, "ra": down, "la": down})
        follow = merge(hit, {"root": {"pitch": 46}})
    elif kind == "dive":          # Itachi's piqué: head down, one heel driven ahead like a spear
        wind = fly(AIRP, (TUCK, TUCK), {"root": {"pitch": 60}, "torso": {"pitch": 20}, "head": {"pitch": -20},
                                        "ra": {"raise": 60, "out": 40, "elbow": 60}, "la": {"raise": 60, "out": 40, "elbow": 60}})
        hit = fly(AIRP, ((0, -1.9, -.4), KNEE), {"root": {"pitch": 20}, "torso": {"pitch": 6}, "head": {"pitch": 16},
                                                 "ra": {"raise": 20, "out": 70, "elbow": 10}, "la": {"raise": 30, "out": 60, "elbow": 20}})
        follow = merge(hit, {"root": {"pitch": 24}})
    elif kind == "stab":          # Minato's piqué au kunai: the blade driven straight down with the body behind it
        wind = fly(AIRP, (KNEE, TUCK), {"root": {"pitch": -10}, "torso": {"pitch": -12},
                                        "ra": {"raise": 176, "out": 0, "elbow": 30, "wrist": -40}, "la": {"raise": 100, "out": 40, "elbow": 40}})
        hit = fly(AIRP, (BENT, KICK), {"root": {"pitch": 50}, "torso": {"pitch": 30}, "head": {"pitch": -24},
                                       "ra": {"raise": 70, "out": -4, "elbow": 0, "wrist": -60}, "la": {"raise": -10, "out": 60, "elbow": 20}})
        follow = merge(hit, {"root": {"pitch": 56}})
    else:                         # Neji's paume plongeante: both palms open, pressed down from above
        wind = fly(AIRP, (TUCK, KNEE), {"root": {"pitch": -12}, "torso": {"pitch": -10}, "head": {"pitch": 10},
                                        "ra": {"raise": 150, "out": 30, "elbow": 40, "wrist": -70}, "la": {"raise": 150, "out": 30, "elbow": 40, "wrist": -70}})
        hit = fly(AIRP, (BENT, BENT), {"root": {"pitch": 34}, "torso": {"pitch": 24}, "head": {"pitch": 20},
                                       "ra": {"raise": 60, "out": 10, "elbow": 0, "wrist": -80}, "la": {"raise": 60, "out": 10, "elbow": 0, "wrist": -80}})
        follow = merge(hit, {"root": {"pitch": 38}})
    land = s_({"root": {"y": -1.15, "pitch": 30}, "torso": {"pitch": 20}, "rf": {"z": -.6}, "lf": {"z": .7, "toe": -30},
               "ra": {"raise": -20, "out": 40}, "la": {"raise": -20, "out": 40}})
    rows = [(0, neutral, "ease"), (5, wind, "ease"), (9, hit, "impact"), (16, follow, "ease"), (24, land, "impact"), (44, s_(), "ease")]
    return mk(arm, fid + ".Slam", rows, 9, 22)


def sasuke(arm):
    return [slam(arm, "Lion", sasuke_p1.AIR, kunai_lion.s, "heel")]


def itachi(arm):
    return [slam(arm, "Mirage", itachi_p3.AIR, itachi_p3.s, "dive")]


def minato(arm):
    return [slam(arm, "Flashstep", clips_flash2.AIR, clips_flash2.s, "stab")]


def neji(arm):
    return [slam(arm, "GentleFist", neji_p9.AIR, neji_p9.s, "palms")] + byakugan(arm)


# ============================================== the buffs and Gaara's glide
# A technique plays "<fighter>.<id>.Channel" / ".Release" / ".Recover".
def cast(arm, fid, tid, channel, release, recover):
    out = []
    for part, rows, contact in (("Channel", channel, None), ("Release", release, 2), ("Recover", recover, None)):
        act = clip(arm, "%s.%s.%s" % (fid, tid, part), keys(rows))
        if contact is not None:
            act["nd_markers"] = {"contact": contact / F}
        out.append(act)
    return out


def byakugan(arm):
    """Byakugan: two fingers raised before the face (the sign), the head
    dips; then it snaps up, the eyes open, the veins stand out."""
    s_ = neji_p9.s
    sign = s_({"root": {"y": -.5, "pitch": 4}, "head": {"pitch": 14, "yaw": 0},
               "ra": {"raise": 100, "out": -46, "twist": 60, "elbow": 130, "wrist": 0}, "la": {"raise": 20, "out": 20, "elbow": 40}})
    up = merge(sign, {"head": {"pitch": -10}, "torso": {"pitch": -6}, "ra": {"raise": 90, "out": -40, "elbow": 120}})
    return cast(arm, "GentleFist", "ByakuganSight",
                [(0, s_(), "ease"), (7, sign, "ease")],
                [(0, sign, "ease"), (2, up, "impact"), (5, merge(up, {"head": {"pitch": -6}}), "ease")],
                [(0, up, "ease"), (12, s_(), "ease")])


def sand_armor(arm):
    """Sand armour: the arms cross over the chest and the head bows (the
    sand climbs him), then the arms open out as the shell sets."""
    s_ = gaara_p7.s
    cross = s_({"root": {"y": -.2, "pitch": 6}, "head": {"pitch": 16},
                "ra": {"raise": 70, "out": -60, "twist": 30, "elbow": 110}, "la": {"raise": 66, "out": -62, "twist": 30, "elbow": 112}})
    open_ = s_({"root": {"y": -.1, "pitch": -4}, "torso": {"pitch": -6}, "head": {"pitch": -6},
                "ra": {"raise": 40, "out": 50, "elbow": 30}, "la": {"raise": 40, "out": 50, "elbow": 30}})
    return cast(arm, "Sand", "SandArmor",
                [(0, s_(), "ease"), (12, cross, "ease")],
                [(0, cross, "ease"), (2, open_, "impact"), (6, merge(open_, {"ra": {"raise": 36}, "la": {"raise": 36}}), "ease")],
                [(0, open_, "ease"), (12, s_(), "ease")])


def sand_glide(arm):
    """Side route: the sand carries him round on the flank, leaning into the
    curve, and the hand lashes across as he passes."""
    s_ = gaara_p7.s
    lean = s_({"root": {"y": -.3, "roll": -16, "yaw": -30}, "torso": {"roll": -8, "yaw": -20}, "head": {"yaw": 30},
               "ra": {"raise": 60, "out": 60, "elbow": 40}, "la": {"raise": 30, "out": 40, "elbow": 40}})
    lash = s_({"root": {"y": -.32, "roll": -10, "yaw": 20}, "torso": {"roll": -4, "yaw": 30}, "head": {"yaw": -10},
               "ra": merge(gaara_p7.OPEN, {"raise": 88, "out": -30, "wrist": -20}), "la": {"raise": 30, "out": 40, "elbow": 40}})
    return [mk(arm, "Sand.SandGlide", [(0, s_(), "ease"), (4, lean, "ease"), (7, lash, "impact"), (14, merge(lash, {"ra": {"out": -50}}), "ease"),
                                        (30, s_(), "ease")], 7, 16)]


def gaara(arm):
    return sand_armor(arm) + sand_glide(arm)


def remove_weights(arm):
    """Remove the weights: down to the shins, the straps undone, then he
    stands and drops them - they hit the floor like boulders."""
    s_ = lee_p8.s
    down = s_({"root": {"y": -1.3, "pitch": 46, "yaw": 0}, "torso": {"pitch": 34, "yaw": 0}, "head": {"pitch": 10, "yaw": 0},
               "ra": {"raise": 20, "out": 10, "elbow": 40}, "la": {"raise": 20, "out": 10, "elbow": 40},
               "rf": {"x": .3, "z": .3}, "lf": {"x": -.3, "z": -.2}})
    tug = merge(down, {"ra": {"raise": 10, "elbow": 60}, "la": {"raise": 10, "elbow": 60}, "root": {"y": -1.35}})
    drop = s_({"root": {"y": -.4, "pitch": -4, "yaw": 0}, "torso": {"pitch": -6, "yaw": 0}, "head": {"pitch": -14, "yaw": 0},
               "ra": {"raise": -20, "out": 40, "elbow": 10}, "la": {"raise": -20, "out": 40, "elbow": 10}})
    return cast(arm, "Leaf", "RemoveWeights",
                [(0, s_(), "ease"), (8, down, "ease"), (13, tug, "ease"), (18, down, "ease")],
                [(0, down, "ease"), (2, drop, "impact"), (6, merge(drop, {"root": {"y": -.5}}), "ease")],
                [(0, drop, "ease"), (12, s_(), "ease")])


def lee(arm):
    """Lee's is the leaf's heel he already has (lee_p8 LeafHeel), as his Slam."""
    act = lee_p8.lotus("LeafHeel", False)(arm)
    act.name = "Leaf.Slam"
    return [act] + remove_weights(arm)


JOBS = {"Copycat": ("Kakashi", kakashi), "Legion": ("Naruto", naruto), "Lion": ("Sasuke", sasuke), "Mirage": ("Itachi", itachi),
        "Flashstep": ("Minato", minato), "GentleFist": ("Neji", neji), "Leaf": ("Lee", lee), "Sand": ("Gaara", gaara)}
