"""Partie 6 (DEC-030): Kakashi (Copycat), the young ANBU, authored.

His bible (docs/characters/KAKASHI.md): measure with the short blade and
the eye, then commit to ONE precise punishment that costs a real read. The
tanto in the right hand (reverse grip, as the game's kunai family holds it),
a narrow three-quarter base, the free hand on the line; the blade's point
precedes every half step; no acrobatics - short tactical displacements.
References: Kakashi Gaiden (ep. 119-120) and the ANBU arc (Shippuden 349-
361) for the young tanto fighter, Kakashi vs Zabuza (ep. 8-9 / 17-19) for
the Water Dragon and the copy, Kakashi vs Obito (ep. 375) for the Chidori
line, Storm 4 for the timing.

Server frame data (startup with his profile):
  Light1 .083  Light2 .094  Light3 .12  Heavy .294  KneeStrike .08
  Launcher .163  Sweep .12  FeintStep .10  DashAttack .064
  Air1 .075 Air2 .085 AirDrive .08 AirSpike .09 AirSwitch .10
  ChidoriThrust .04 / .26 / .62   LightningBlade ch .50
  TrackingFang ch .30 act .08 rec .30   WaterDragon ch .55 act .30 rec .36
"""
from nd_shot import Shot, merge, mirror
from gait_from_lion import gait, scaler

N = "Copycat."
STANCE = {"root": {"y": -.36, "z": .0, "pitch": 6, "yaw": 26}, "torso": {"pitch": 8, "yaw": -10},
          "head": {"pitch": -2, "yaw": -14},
          "ra": {"raise": 30, "out": 10, "twist": 20, "elbow": 80, "wrist": -20},
          "la": {"raise": 56, "out": -18, "twist": -30, "elbow": 74, "wrist": -10},
          "rf": {"x": .2, "z": .58, "yaw": 30}, "lf": {"x": -.08, "z": -.56, "yaw": -6}}
GUARD = {"ra": {"raise": 34, "out": 10, "twist": 20, "elbow": 84, "wrist": -20}, "la": {"raise": 56, "out": -16, "twist": -30, "elbow": 76}}
AIR = {"root": {"y": -.45, "pitch": 10, "yaw": 0}, "torso": {"pitch": 10, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
       "la": {"raise": 50, "out": 20, "elbow": 70}, "ra": {"raise": 36, "out": 20, "twist": 20, "elbow": 84, "wrist": -20},
       "rf": {"x": .05, "z": -.5, "y": 1.0, "toe": -24, "yaw": 0, "knee": 6}, "lf": {"x": -.05, "z": -.35, "y": .9, "toe": -26, "yaw": 0, "knee": 6}}
# Reverse grip: a stab is a hammer stab (the fist leads, the blade under it).
STAB = {"raise": 84, "out": -8, "twist": 30, "elbow": 14, "wrist": -40}


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .58 + T}, "lf": {"z": -.56 + T}})
    return merge(base, over or {})


def air(over=None):
    return merge(AIR, over or {})


def locomotion(arm):
    """Compact and economical: little counter-rotation, the arms close to the
    waist (the blade stays still), a slight forward lean."""
    return gait(arm, N, STANCE, GUARD, scaler(torso_yaw=.55, torso_pitch=.85, root_pitch=.9, head_yaw=.6),
                arms={"walk": 1.0, "run": .55, "jump": .7})


def idle(arm):
    """Measured stillness (1.6 s): the weight settles back and forth by a
    finger's width, the blade's point drifts on the opponent's line, the head
    tilts a little (the covered eye)."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(48, s({"root": {"y": -.39, "z": .04}, "head": {"roll": 4, "pitch": 0}, "ra": {"wrist": -14}}), "ease")
    sh.key(96, s(), "ease")
    sh.drag(["neck"], 5).drag(["hand.R"], 3)
    return sh.build(loop=True)


# ================================================================ strikes
def light1(arm):
    """L1, the probing stab: a 0.35 glide, the reverse-grip blade goes in
    obliquely at the shoulder, the elbow keeps margin (he does not overreach),
    the free hand stays on the line."""
    sh = Shot(arm, N + "Light1")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.4, "yaw": 34}, "ra": {"raise": 50, "out": 20, "elbow": 110, "wrist": -30}}), "ease")
    hit = s({"travel": {"z": -.35}, "root": {"y": -.4, "z": -.14, "pitch": 10, "yaw": 16}, "torso": {"pitch": 8, "yaw": -14},
             "ra": STAB, "la": {"raise": 50, "out": -10, "elbow": 80}, "lf": {"z": -.91}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"ra": {"raise": 82, "elbow": 20}}), "ease")
    sh.key(18, at(-.35), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 10 / 60})


def light2(arm):
    """L2, the forearm: the LEFT forearm knocks the guarding arm aside from
    outside, the rear foot passes 0.3, the blade withdraws to the hip -
    short, it opens the body for the punishment."""
    sh = Shot(arm, N + "Light2")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"yaw": 34}, "la": {"raise": 70, "out": 40, "twist": -10, "elbow": 90}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.42, "z": -.1, "pitch": 8, "yaw": 6}, "torso": {"pitch": 6, "yaw": -18},
             "la": {"raise": 76, "out": -30, "twist": 10, "elbow": 70, "wrist": 0},
             "ra": {"raise": 0, "out": 20, "twist": 10, "elbow": 90, "wrist": -20}, "rf": {"z": .28}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"la": {"out": -40}}), "ease")
    sh.key(20, at(-.3), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 11 / 60})


def light3(arm):
    """L3, the low backhand while withdrawing: a small pivot, the blade
    opens from the ribs outward, and the body retreats 0.5 - the distance is
    given back, the eye stays on him."""
    sh = Shot(arm, N + "Light3")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.5, "yaw": 0}, "ra": {"raise": 40, "out": -40, "twist": 40, "elbow": 110, "wrist": -20}}), "ease")
    hit = s({"root": {"y": -.56, "z": .2, "pitch": 10, "yaw": 40}, "torso": {"pitch": 8, "yaw": -4},
             "ra": {"raise": 60, "out": 50, "twist": 30, "elbow": 14, "wrist": -30},
             "la": {"raise": 40, "out": -20, "elbow": 90}, "rf": {"z": 1.08}})
    sh.key(7, hit, "impact")
    sh.key(11, merge(hit, {"ra": {"out": 60}}), "ease")
    sh.key(24, s({"rf": {"z": 1.08}, "lf": {"z": -.3}, "root": {"z": .25}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def heavy(arm):
    """Heavy, the full-body thrust: a readable shoulder wind-up (the blade
    drawn back past the hip, the free hand out on the line), then everything
    goes in on a long step - a whiff leaves the flank open."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.5, "z": .14, "yaw": 50}, "torso": {"yaw": 10, "pitch": 4},
              "ra": {"raise": -10, "out": 30, "twist": 20, "elbow": 80, "wrist": -30}, "la": {"raise": 80, "out": 0, "elbow": 20, "wrist": 0}})
    sh.key(12, load, "ease")
    sh.key(15, merge(load, {"travel": {"z": -.4}, "root": {"z": -.1}, "lf": {"z": -1.0, "y": .14}}), "pass")
    hit = s({"travel": {"z": -.8}, "root": {"y": -.62, "z": -.4, "pitch": 16, "yaw": 6}, "torso": {"pitch": 10, "yaw": -18},
             "ra": merge(STAB, {"raise": 86, "elbow": 6}), "la": {"raise": 20, "out": 30, "elbow": 60},
             "lf": {"z": -1.36, "y": 0}, "rf": {"toe": -30}})
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"root": {"z": -.44}}), "ease")
    sh.key(38, at(-.8), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 18 / 60, "recover": 26 / 60})


def knee_strike(arm):
    """Forward route / heavy after one: the forearm lifts the guard, then a
    short knee under it."""
    sh = Shot(arm, N + "KneeStrike")
    sh.key(0, s(), "ease")
    sh.key(3, s({"la": {"raise": 110, "out": 0, "elbow": 60}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.22, "z": -.2, "pitch": 4}, "torso": {"pitch": 8},
             "la": {"raise": 120, "out": 0, "elbow": 50}, "rf": {"x": .1, "z": -.4, "y": 1.2, "toe": -30, "knee": 10}, "lf": {"z": -.86}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"rf": {"y": 1.26}}), "ease")
    sh.key(20, at(-.3), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 10 / 60})


def launcher(arm):
    """Launcher: the knee after the guard is open, small scale (he does not
    do the full copy of a launcher)."""
    sh = Shot(arm, N + "Launcher")
    sh.key(0, s(), "ease")
    sh.key(6, s({"root": {"y": -.6, "pitch": 14}, "la": {"raise": 100, "elbow": 60}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.1, "z": -.2, "pitch": -6}, "torso": {"pitch": -4},
             "la": {"raise": 130, "out": 0, "elbow": 40}, "rf": {"x": .1, "z": -.5, "y": 1.6, "toe": -20, "knee": 10}, "lf": {"z": -.86, "toe": -30}})
    sh.key(10, hit, "impact")
    sh.key(14, merge(hit, {"rf": {"y": 1.7}}), "ease")
    sh.key(26, at(-.3), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def sweep(arm):
    """Away route: a low heel sweep, then the blade drawn back as a barrier
    while he withdraws."""
    sh = Shot(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.9, "pitch": 16, "yaw": 40}, "la": {"raise": 0, "out": 40}}), "ease")
    hit = s({"root": {"y": -.96, "pitch": 18, "yaw": -10}, "rf": {"x": -.1, "z": -.9, "y": .05, "yaw": -40},
             "la": {"raise": 0, "out": 40}, "ra": {"raise": 60, "out": 30, "elbow": 60}})
    sh.key(7, hit, "impact")
    sh.key(16, s({"root": {"y": -.6, "z": .3}, "ra": {"raise": 70, "out": 0, "elbow": 40}, "rf": {"z": .9}}), "pass")
    sh.key(26, s({"rf": {"z": .9}, "lf": {"z": -.4}, "root": {"z": .2}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def feint_step(arm):
    """Side route: a step to the flank and a stab there, the gaze staying
    on the shoulder (not on the blade)."""
    sh = Shot(arm, N + "FeintStep")
    sh.key(0, s(), "ease")
    sh.key(3, s({"rf": {"x": .7, "z": .2, "y": .2}, "root": {"yaw": -10}}), "pass")
    hit = s({"root": {"y": -.44, "z": -.1, "pitch": 8, "yaw": -30}, "head": {"yaw": 20}, "ra": STAB, "rf": {"x": .9, "z": -.1, "y": 0, "yaw": -30}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"ra": {"raise": 82}}), "ease")
    sh.key(20, s({"root": {"yaw": -10}, "rf": {"x": .9, "z": -.1, "yaw": -10}}), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def dash_attack(arm):
    """Entry thrust: committed, the body behind the point (not a flicker)."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s({"root": {"pitch": 18, "y": -.5}}), "ease")
    hit = s({"root": {"y": -.6, "z": -.3, "pitch": 18}, "torso": {"pitch": 10, "yaw": -14}, "ra": merge(STAB, {"elbow": 6}),
             "la": {"raise": 0, "out": 30}, "lf": {"z": -1.2}, "rf": {"z": .9, "y": .2, "toe": -30}})
    sh.key(4, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.34}}), "ease")
    sh.key(20, s(), "ease")
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


# ===================================================================== air
def air1(arm):
    """A brief cut that holds him."""
    sh = Shot(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(3, air({"ra": {"raise": 50, "out": -40, "elbow": 110}}), "ease")
    hit = air({"root": {"yaw": -16}, "ra": {"raise": 80, "out": 40, "twist": 30, "elbow": 14, "wrist": -30}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"ra": {"out": 50}}), "ease")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air2(arm):
    """Second air contact: the forearm."""
    sh = Shot(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(3, air({"la": {"raise": 70, "out": 40, "elbow": 90}}), "ease")
    hit = air({"root": {"yaw": 16}, "la": {"raise": 80, "out": -30, "elbow": 70}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"la": {"out": -40}}), "ease")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_drive(arm):
    sh = Shot(arm, N + "AirDrive")
    sh.key(0, air(), "ease")
    sh.key(3, air({"rf": {"z": -.3, "y": 1.3, "knee": 10}}), "ease")
    hit = air({"root": {"pitch": -8}, "rf": {"z": -1.3, "y": 1.1, "toe": 10, "knee": 0}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"rf": {"z": -1.35}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_spike(arm):
    """Down: the stab driven down (both hands on the hilt)."""
    sh = Shot(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    hi = {"raise": 160, "out": -10, "twist": 30, "elbow": 40, "wrist": -40}
    sh.key(3, air({"root": {"pitch": -10}, "ra": hi, "la": merge(hi, {"twist": -10})}), "ease")
    lo = {"raise": 60, "out": -10, "twist": 30, "elbow": 10, "wrist": -40}
    hit = air({"root": {"pitch": 26}, "torso": {"pitch": 20}, "ra": lo, "la": merge(lo, {"twist": -10})})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"root": {"pitch": 30}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_switch(arm):
    sh = Shot(arm, N + "AirSwitch")
    sh.key(0, air(), "ease")
    sh.key(3, air({"root": {"yaw": 40}}), "ease")
    hit = air({"root": {"yaw": -40}, "ra": {"raise": 80, "out": 40, "twist": 30, "elbow": 14, "wrist": -30}})
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": -46}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def throw_kunai(arm):
    """The free hand throws from under the blade arm."""
    sh = Shot(arm, N + "Throw.Kunai")
    sh.key(0, s(), "ease")
    sh.key(4, s({"la": {"raise": 30, "out": -40, "twist": 0, "elbow": 110, "wrist": 30}, "root": {"yaw": 10}}), "ease")
    rel = s({"la": {"raise": 84, "out": 20, "elbow": 6, "wrist": -20}, "root": {"yaw": 34}, "torso": {"yaw": -6}})
    sh.key(7, rel, "launch")
    sh.key(16, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ============================================================ techniques
def lightning_blade(arm):
    """Chidori, young: the left hand grips the right wrist, the right hand
    held low, palm down, crackling; the knees bend, the weight goes onto the
    front foot - the line of the run is fixed before he goes."""
    out = []
    ch = Shot(arm, N + "LightningBlade.Channel")
    ch.key(0, s(), "ease")
    hold = s({"root": {"y": -.8, "z": -.1, "pitch": 22, "yaw": 30}, "torso": {"pitch": 14, "yaw": -4}, "head": {"pitch": -24},
              "ra": {"raise": -24, "out": 20, "twist": 0, "elbow": 40, "wrist": 30},
              "la": {"raise": 10, "out": -10, "twist": 30, "elbow": 80, "wrist": 0},
              "rf": {"x": .3, "z": .9, "toe": -20}, "lf": {"z": -.8}})
    ch.key(10, hold, "ease")
    ch.key(30, merge(hold, {"root": {"y": -.84}, "ra": {"wrist": 36}}), "ease")
    out.append(ch.build(markers={"release": 30 / 60}))
    th = Shot(arm, N + "ChidoriThrust")
    th.key(0, hold, "launch")
    hit = s({"travel": {"z": -1.2}, "root": {"y": -.7, "z": -.5, "pitch": 26}, "torso": {"pitch": 14, "yaw": -10}, "head": {"pitch": -20},
             "ra": {"raise": 86, "out": -6, "twist": 0, "elbow": 4, "wrist": 30}, "la": {"raise": -20, "out": 30, "elbow": 20},
             "lf": {"z": -1.76}, "rf": {"z": 1.0, "toe": -40}})
    th.key(3, hit, "impact")
    th.key(16, merge(hit, {"root": {"z": -.56}}), "ease")
    th.key(40, at(-1.2, {"root": {"y": -.5}}), "ease")
    out.append(th.build(markers={"contact": 3 / 60, "recover": 18 / 60}))
    return out


def tracking_fang(arm):
    """Summoning: Tracking Fang - the thumb to the mouth (blood), then the
    palm slammed flat on the ground; the hounds burst from it."""
    out = []
    ch = Shot(arm, N + "TrackingFang.Channel")
    ch.key(0, s(), "ease")
    ch.key(6, s({"ra": {"raise": 100, "out": -40, "twist": 40, "elbow": 140}, "head": {"pitch": 4}}), "ease")
    slam = s({"root": {"y": -1.1, "z": -.1, "pitch": 34}, "torso": {"pitch": 24}, "head": {"pitch": -20},
              "ra": {"raise": 40, "out": 0, "twist": 0, "elbow": 6, "wrist": 60}, "la": {"raise": 0, "out": 30},
              "rf": {"z": .9, "toe": -30}, "lf": {"z": -.8}})
    ch.key(18, slam, "impact")
    out.append(ch.build(markers={"release": 18 / 60}))
    re = Shot(arm, N + "TrackingFang.Release")
    re.key(0, slam, "ease")
    re.key(5, merge(slam, {"root": {"y": -1.12}}), "ease")
    out.append(re.build())
    rc = Shot(arm, N + "TrackingFang.Recover")
    rc.key(0, slam, "ease")
    rc.key(18, s(), "ease")
    out.append(rc.build())
    return out


def water_dragon(arm):
    """Water Dragon (copied): the seals at speed - ox, monkey, hare, rat,
    boar, bird... (six snapped, the Sharingan reading his own hands), then
    the arms thrust forward and up, guiding the dragon."""
    out = []
    ch = Shot(arm, N + "WaterDragon.Channel")
    ch.key(0, s(), "ease")
    base = {"raise": 66, "out": -36, "twist": 34, "elbow": 110, "wrist": 10}
    for i, f in enumerate((4, 8, 12, 16, 20, 24)):
        d = 8 if i % 2 else -8
        ch.key(f, s({"root": {"y": -.5}, "la": merge(base, {"raise": 66 + d, "twist": 34 - d * 2}),
                     "ra": merge(base, {"raise": 66 - d, "twist": 34 + d * 3})}), "pass")
    ch.key(33, s({"root": {"y": -.56}, "la": merge(base, {"raise": 74}), "ra": merge(base, {"raise": 74})}), "ease")
    out.append(ch.build(markers={"release": 33 / 60}))
    re = Shot(arm, N + "WaterDragon.Release")
    thrust = s({"root": {"y": -.5, "z": -.2, "pitch": 6}, "torso": {"pitch": -4},
                "la": {"raise": 110, "out": 4, "twist": 0, "elbow": 10, "wrist": 30}, "ra": {"raise": 110, "out": 4, "twist": 0, "elbow": 10, "wrist": 30}})
    re.key(0, s({"root": {"y": -.56}}), "launch")
    re.key(5, thrust, "impact")
    re.key(18, merge(thrust, {"la": {"raise": 120}, "ra": {"raise": 120}}), "ease")
    out.append(re.build())
    rc = Shot(arm, N + "WaterDragon.Recover")
    rc.key(0, thrust, "ease")
    rc.key(20, s(), "ease")
    out.append(rc.build())
    return out


# ================================================================= states
def intro(arm):
    """Match intro: the ANBU draw - the hand goes over the shoulder to the
    tanto's hilt, a beat, the blade comes out and down into the reverse
    grip; the eye measures the distance."""
    sh = Shot(arm, N + "Intro")
    calm = s({"root": {"y": -.1, "pitch": 0}, "torso": {"pitch": 0}, "head": {"pitch": 4},
              "ra": {"raise": 4, "out": 10, "elbow": 20, "wrist": 0}, "la": {"raise": 4, "out": 10, "elbow": 20}})
    sh.key(0, calm, "ease")
    sh.key(50, calm, "ease")
    hilt = merge(calm, {"ra": {"raise": 160, "out": -20, "twist": 0, "elbow": 150, "wrist": 0}, "head": {"pitch": -2}})
    sh.key(70, hilt, "ease")
    sh.key(80, hilt, "ease")
    sh.key(92, s({"root": {"y": -.3}, "ra": {"raise": 90, "out": 20, "twist": 40, "elbow": 40, "wrist": -30}}), "launch")
    sh.key(110, s(), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def win(arm):
    """Victory: the blade goes back over the shoulder, the hand comes up -
    a lazy little wave, the eye closing in a smile behind the mask."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    sh.key(18, s({"root": {"y": -.1, "pitch": 0}, "ra": {"raise": 160, "out": -20, "twist": 0, "elbow": 150, "wrist": 0}}), "ease")
    wave = s({"root": {"y": -.1, "pitch": 0}, "torso": {"pitch": 0}, "head": {"pitch": 4, "roll": 6},
              "ra": {"raise": 110, "out": 20, "twist": 0, "elbow": 80, "wrist": 0}, "la": {"raise": 4, "out": 10, "elbow": 20}})
    sh.key(36, wave, "ease")
    sh.key(46, merge(wave, {"ra": {"out": 10}}), "ease")
    sh.key(56, merge(wave, {"ra": {"out": 26}}), "ease")
    sh.key(150, wave, "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def awaken(arm):
    """Sharingan uncovered: the free hand lifts the headband off the left
    eye, the head comes up slowly; the stance drops lower and wider."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    sh.key(12, s({"head": {"pitch": 10}, "la": {"raise": 140, "out": -30, "twist": 0, "elbow": 150, "wrist": 0}}), "ease")
    sh.key(24, s({"head": {"pitch": -6}, "la": {"raise": 150, "out": -10, "twist": 0, "elbow": 120, "wrist": 0}}), "ease")
    sh.key(36, s({"root": {"y": -.5}, "rf": {"x": .3, "z": .7}}), "ease")
    sh.key(46, s({"root": {"y": -.5}, "rf": {"x": .3, "z": .7}}), "ease")
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), light1(arm), light2(arm), light3(arm), heavy(arm), knee_strike(arm), launcher(arm), sweep(arm),
             feint_step(arm), dash_attack(arm), air1(arm), air2(arm), air_drive(arm), air_spike(arm), air_switch(arm),
             throw_kunai(arm), intro(arm), win(arm), awaken(arm)]
    acts += lightning_blade(arm)
    acts += tracking_fang(arm)
    acts += water_dragon(arm)
    return acts
