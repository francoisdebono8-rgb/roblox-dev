"""Partie 4 (DEC-030): Minato (Flashstep) completed - every move he still
played procedurally, authored on his body (clips_flash2.STANCE: upright,
light, the kunai in reverse grip low in the right hand).

His bible (docs/characters/MINATO.md): decision speed. Angles from the feet
(a pivot on the ball, never a body swing), small exact steps, the kunai
always ready; arrives from a teleport already oriented. References: Minato
vs Obito (Shippuden 345-349) for the reverse-grip cuts and the arrivals,
Minato vs A (Kakashi Gaiden flashbacks), the Storm 4 Minato combo (kunai
cut - knee - Rasengan) for the timing.

Server frame data (startup with his AttackProfile):
  Sweep .12  AngleStep .08  KneeStrike .08  DashAttack .055
  AirDrive .08  AirSpike .09  AirSwitch .10  RasenganDrop (Slam) .117 / active .2
  Quickstep ch .11 act .08 rec .21   WindCut thrown on the run (release .1)
"""
from nd_shot import Shot, merge, mirror
from clips_flash2 import STANCE, s

N = "Flashstep."
AIR = {"root": {"y": -.45, "pitch": 10, "yaw": 0}, "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
       "la": {"raise": 52, "out": 30, "elbow": 60}, "ra": {"raise": 30, "out": 30, "twist": 24, "elbow": 90, "wrist": -20},
       "rf": {"x": .05, "z": -.55, "y": 1.05, "toe": -24, "yaw": 0, "knee": 6}, "lf": {"x": -.05, "z": -.35, "y": .95, "toe": -26, "yaw": 0, "knee": 6}}
# Reverse grip: the blade lies along the forearm, edge out; a cut is a
# backhand of the forearm, not a stab.
CUT_R = {"raise": 80, "out": -30, "twist": 40, "elbow": 20, "wrist": -30}


def air(over=None):
    return merge(AIR, over or {})


def at(T, over=None):
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .78 + T}, "lf": {"z": -.72 + T}})
    return merge(base, over or {})


# ================================================================ ground
def sweep(arm):
    """Spinning leg sweep (down route): he drops onto the left hand, pivots on
    the ball of the left foot and the right leg reaps a full half circle flat
    on the floor; a marked kunai is planted where the opponent falls (the
    right hand does it on the way up)."""
    sh = Shot(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -1.0, "z": -.1, "pitch": 26, "yaw": 50}, "torso": {"pitch": 16, "yaw": -6},
                 "la": {"raise": -6, "out": 30, "elbow": 10}, "rf": {"x": .7, "z": .4, "y": .06}}), "ease")
    hit = s({"root": {"y": -1.1, "z": -.1, "pitch": 26, "yaw": -40}, "torso": {"pitch": 16, "yaw": 10},
             "la": {"raise": -10, "out": 34, "elbow": 6}, "ra": {"raise": 30, "out": 40, "elbow": 60},
             "rf": {"x": -.2, "z": -1.0, "y": .05, "yaw": -60, "toe": 0}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": -70}, "rf": {"x": -.8, "z": -.3}}), "ease")
    sh.key(16, s({"root": {"y": -.8, "pitch": 20, "yaw": -30}, "ra": {"raise": -40, "out": 20, "elbow": 20, "wrist": 0},
                  "rf": {"x": -.5, "z": .5, "y": .1}}), "pass")
    sh.key(26, s({"rf": {"x": -.2, "z": .8}, "lf": {"x": -.1, "z": -.6}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def angle_step(arm):
    """Side route: a pivot on the ball of the left foot puts him 40 deg off
    the line; the reverse-grip blade cuts across the ribs on the way past.
    The chest stays square to the opponent (only the feet travel)."""
    sh = Shot(arm, N + "AngleStep")
    sh.key(0, s(), "ease")
    sh.key(2, s({"rf": {"y": .2, "x": .5, "z": .5}, "root": {"y": -.46}}), "launch")
    hit = s({"root": {"y": -.5, "z": -.12, "pitch": 10, "yaw": -28}, "torso": {"pitch": 6, "yaw": -6}, "head": {"yaw": 22},
             "ra": CUT_R, "la": {"raise": 50, "out": 20, "elbow": 70},
             "rf": {"x": 1.0, "z": -.3, "y": 0, "yaw": -30}, "lf": {"yaw": -30}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"ra": {"out": -44}}), "ease")
    sh.key(18, s({"root": {"yaw": -6}, "rf": {"x": 1.0, "z": -.3, "yaw": -6}, "lf": {"yaw": -10}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 10 / 60})


def knee_strike(arm):
    """Heavy after one cut: the left hand grabs the collar and pulls down,
    the right knee drives up under the ribs, the support heel rises (a small
    hop forward); the blade hand stays out of the way, ready."""
    sh = Shot(arm, N + "KneeStrike")
    sh.key(0, s(), "ease")
    grab = s({"root": {"y": -.46, "z": -.2, "pitch": 12}, "la": {"raise": 90, "out": -6, "elbow": 20, "wrist": 0}})
    sh.key(3, grab, "ease")
    hit = s({"travel": {"z": -.4}, "root": {"y": -.2, "z": -.3, "pitch": 6, "yaw": 10}, "torso": {"pitch": 10, "yaw": -6},
             "la": {"raise": 60, "out": -10, "elbow": 80}, "ra": {"raise": 10, "out": 30, "elbow": 80},
             "rf": {"x": .1, "z": -.5, "y": 1.3, "toe": -30, "knee": 10}, "lf": {"z": -.9, "toe": -20}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"rf": {"y": 1.36}}), "ease")
    sh.key(20, at(-.4, {"rf": {"z": .5}}), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 10 / 60})


def dash_attack(arm):
    """Arrival cut: the body arrives low and level, the blade hand already
    across the chest; the forearm opens through the target at the end of the
    glide (the hand arrives a frame before the body)."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s({"root": {"y": -.6, "pitch": 18}, "ra": {"raise": 60, "out": -50, "twist": 40, "elbow": 120}}), "ease")
    hit = s({"root": {"y": -.66, "z": -.3, "pitch": 20, "yaw": 0}, "torso": {"pitch": 10, "yaw": -14},
             "ra": merge(CUT_R, {"out": 30}), "la": {"raise": -20, "out": 30, "elbow": 20},
             "lf": {"z": -1.2}, "rf": {"z": 1.0, "y": .2, "toe": -30}})
    sh.key(3, hit, "impact")
    sh.key(7, merge(hit, {"ra": {"out": 40}}), "ease")
    sh.key(18, s({"lf": {"z": -.9}, "rf": {"z": .7}}), "ease")
    return sh.build(markers={"contact": 3 / 60, "recover": 9 / 60})


# ================================================================== air
def air_drive(arm):
    """Air push kick: the left knee chambers, the sole drives out straight -
    a push, not a swing (it sends him away)."""
    sh = Shot(arm, N + "AirDrive")
    sh.key(0, air(), "ease")
    sh.key(4, air({"lf": {"z": -.3, "y": 1.3, "toe": -10, "knee": 10}, "root": {"pitch": 0}}), "ease")
    hit = air({"root": {"pitch": -10}, "torso": {"pitch": -6}, "lf": {"z": -1.4, "y": 1.0, "toe": 10, "knee": 0},
               "la": {"raise": 30, "out": 50}, "ra": {"raise": 20, "out": 40}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"lf": {"z": -1.45}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def air_spike(arm):
    """Axe kick down: the right leg swings up straight past the head, then
    the heel falls on the collarbone; the arms open for balance."""
    sh = Shot(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    sh.key(5, air({"root": {"pitch": -14}, "torso": {"pitch": -10}, "rf": {"z": -1.0, "y": 2.0, "toe": 10, "knee": 0},
                   "la": {"raise": 40, "out": 60}, "ra": {"raise": 30, "out": 60}}), "ease")
    hit = air({"root": {"pitch": 18}, "torso": {"pitch": 16}, "rf": {"z": -1.1, "y": .6, "toe": 20, "knee": 0},
               "la": {"raise": 30, "out": 60}, "ra": {"raise": 20, "out": 60}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"rf": {"y": .5}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def air_switch(arm):
    """Flash switch: a flicker to the other side, arriving already turned
    back - the blade cuts across as he reappears."""
    sh = Shot(arm, N + "AirSwitch")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": -40}, "ra": {"raise": 60, "out": -50, "elbow": 120}}), "ease")
    hit = air({"root": {"yaw": 50}, "torso": {"yaw": -10}, "head": {"yaw": -30}, "ra": merge(CUT_R, {"out": 30})})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"ra": {"out": 40}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def rasengan_drop(arm):
    """Airborne Rasengan: the orb raised above the head in the right palm,
    the body tucks over it and drives it straight down into the floor (the
    left hand guides the wrist)."""
    sh = Shot(arm, N + "RasenganDrop")
    sh.key(0, air({"ra": {"raise": 150, "out": 10, "twist": 0, "elbow": 40, "wrist": 0}, "la": {"raise": 120, "out": -20, "elbow": 60}}), "ease")
    sh.key(4, air({"root": {"pitch": -12}, "ra": {"raise": 170, "elbow": 20}, "la": {"raise": 140, "elbow": 50}}), "ease")
    hit = air({"root": {"pitch": 40}, "torso": {"pitch": 30}, "head": {"pitch": -30},
               "ra": {"raise": 80, "out": 0, "twist": 0, "elbow": 6, "wrist": 40}, "la": {"raise": 70, "out": -20, "elbow": 40},
               "rf": {"z": .4, "y": 1.0}, "lf": {"z": .2, "y": .9}})
    sh.key(7, hit, "impact")
    sh.key(16, merge(hit, {"root": {"pitch": 44}}), "ease")
    sh.key(34, s({"root": {"y": -.7}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 19 / 60})


# ============================================================ techniques
def quickstep(arm):
    """Quickstep: a two-frame flicker - the knees dip, the body is gone and
    arrives off the line already in stance (the afterimage does the rest)."""
    out = []
    ch = Shot(arm, N + "Quickstep.Channel")
    ch.key(0, s(), "ease")
    ch.key(7, s({"root": {"y": -.64, "pitch": 14}, "rf": {"toe": -20}, "lf": {"toe": -20}}), "ease")
    out.append(ch.build(markers={"release": 7 / 60}))
    re = Shot(arm, N + "Quickstep.Release")
    re.key(0, s({"root": {"y": -.64, "pitch": 14}}), "launch")
    re.key(5, s({"root": {"y": -.36, "pitch": 4, "yaw": 10}, "la": {"raise": 40, "out": 40}}), "ease")
    out.append(re.build())
    rc = Shot(arm, N + "Quickstep.Recover")
    rc.key(0, s({"root": {"y": -.36, "pitch": 4, "yaw": 10}, "la": {"raise": 40, "out": 40}}), "ease")
    rc.key(12, s(), "ease")
    out.append(rc.build())
    return out


def wind_cut(arm):
    """Wind Cut, thrown on the run: the blade hand winds behind the right
    hip and slings the kunai flat and low across the body, the wrist
    snapping (wind chakra on the edge) - only the upper body; the legs keep
    running."""
    sh = Shot(arm, N + "Throw.WindCut")
    sh.key(0, s(), "ease")
    sh.key(4, s({"torso": {"yaw": 20}, "ra": {"raise": -20, "out": 40, "twist": -20, "elbow": 40, "wrist": 30}}), "ease")
    rel = s({"torso": {"yaw": -26}, "ra": {"raise": 80, "out": -40, "twist": 10, "elbow": 8, "wrist": -40}, "la": {"raise": 30, "out": 30}})
    sh.key(7, rel, "launch")
    sh.key(10, merge(rel, {"ra": {"out": -50}}), "ease")
    sh.key(18, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ================================================================= states
def intro(arm):
    """Match intro: he arrives by Flying Thunder God - crouched on one knee
    where the seal was, the kunai in the floor; he stands, pulls it free,
    spins it once round the finger and drops into his stance."""
    sh = Shot(arm, N + "Intro")
    kneel = s({"root": {"y": -1.3, "z": .1, "pitch": 24, "yaw": 20}, "torso": {"pitch": 14}, "head": {"pitch": -10},
               "ra": {"raise": -40, "out": 16, "twist": 0, "elbow": 20, "wrist": 0}, "la": {"raise": 20, "out": 30, "elbow": 60},
               "rf": {"x": .3, "z": .8, "y": .0, "toe": -40}, "lf": {"x": -.1, "z": -.6}})
    sh.key(0, kneel, "ease")
    sh.key(50, kneel, "ease")
    sh.key(70, s({"root": {"y": -.3, "pitch": 4}, "ra": {"raise": 40, "out": 30, "elbow": 80, "wrist": 0}}), "ease")
    sh.key(84, s({"root": {"y": -.32}, "ra": {"raise": 70, "out": 20, "twist": 80, "elbow": 90, "wrist": 30}}), "pass")
    sh.key(96, s({"root": {"y": -.32}, "ra": {"raise": 70, "out": 20, "twist": -60, "elbow": 90, "wrist": -30}}), "pass")
    sh.key(120, s(), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def win(arm):
    """Victory: he straightens, the kunai spins once and goes back into the
    holster, a short nod - and a flicker: gone (the next frame he is a few
    steps away, already turning)."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    up = s({"root": {"y": -.1, "pitch": 0}, "torso": {"pitch": 0}, "head": {"pitch": -2},
           "ra": {"raise": 60, "out": 20, "twist": 60, "elbow": 90}, "la": {"raise": 6, "out": 10, "elbow": 20}})
    sh.key(16, up, "ease")
    sh.key(30, merge(up, {"ra": {"twist": -60}}), "pass")
    sh.key(44, merge(up, {"ra": {"raise": -10, "out": 20, "twist": 0, "elbow": 40, "wrist": 0}}), "ease")
    sh.key(60, merge(up, {"head": {"pitch": 12}, "ra": {"raise": -6, "out": 14, "elbow": 20}}), "ease")
    sh.key(76, merge(up, {"head": {"pitch": -2}, "ra": {"raise": -6, "out": 14, "elbow": 20}}), "ease")
    sh.key(150, merge(up, {"head": {"pitch": -2}, "ra": {"raise": -6, "out": 14, "elbow": 20}}), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def awaken(arm):
    """Yellow Flash: he plants the kunai in the floor in front of him, both
    hands form the seal, and he rises lighter - the stance a little higher,
    the weight already on the balls of the feet."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    sh.key(8, s({"root": {"y": -.9, "pitch": 26}, "ra": {"raise": 40, "out": 0, "elbow": 10, "wrist": 0}}), "impact")
    seal = {"raise": 70, "out": -36, "twist": 34, "elbow": 104, "wrist": 10}
    sh.key(20, s({"root": {"y": -.4, "pitch": 4}, "la": seal, "ra": seal}), "ease")
    sh.key(32, s({"root": {"y": -.34}, "rf": {"toe": -10}, "lf": {"toe": -10}}), "ease")
    sh.key(44, s({"root": {"y": -.36}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build()


def author(arm):
    acts = [sweep(arm), angle_step(arm), knee_strike(arm), dash_attack(arm), air_drive(arm), air_spike(arm), air_switch(arm),
            rasengan_drop(arm), wind_cut(arm), intro(arm), win(arm), awaken(arm)]
    acts += quickstep(arm)
    return acts
