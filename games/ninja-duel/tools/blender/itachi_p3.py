"""Partie 3 (DEC-030): Itachi (Mirage), authored on the control rig.

His bible (docs/characters/ITACHI.md): invite an answer, read it, punish it
with a SMALLER gesture than the opponent's. Animation language: economy of
the torso, one hand always free, no full turn without reason, the gaze moves
before the body, a calm pose after the impact, the shuriken really leaves the
fingers. References: Itachi vs Sasuke (Shippuden 135-138) for the stillness
and the single-hand seals, Itachi vs Kakashi (ep. 82) for the economy of the
taijutsu, the Shonen Unleashed Itachi showcase for the techniques, Storm 4
for the read / counter timing.

Same vocabulary as clips_lion2 / sasuke_p1 (yaw + right, pitch + forward,
roll + right; feet WORLD, x right, z back, y lift; travel z - forward).

Server frame data the contacts sit on (startup with his AttackProfile):
  Light1 .086  Light2 .098  Light3 .122  Heavy .294  Launcher .17
  Sweep .12  FeintStep .10  CounterPalm .05  DashAttack .067
  Air1 .078  Air2 .09  AirDrive .08  AirSpike .09  AirSwitch .10
  Read ch .10 act 1.0 rec .20   NeedleFan ch .26 act .08 rec .26
  MirageCast ch .42 act .06 rec .20   FireBloom ch .30 act .42 rec .36
  PhoenixFlower ch .30 act .32 rec .30
Locomotion: Sasuke's gait mechanics (clips_lion2: plants, strides, duty)
re-acted on Itachi's body: upright, shoulders still, arms contained.
"""
import copy
import nd_shot
from nd_shot import Shot, merge, mirror
import clips_lion2 as L2

N = "Mirage."

# Upright, quiet: the chest almost vertical, left foot forward, weight a
# little back; the left hand open in front (it invites and it reads), the
# right low by the hip, near the shuriken pouch.
STANCE = {"root": {"y": -.3, "z": .04, "pitch": 4, "yaw": 26}, "torso": {"pitch": 2, "yaw": -10},
          "head": {"pitch": -4, "yaw": -14},
          "la": {"raise": 52, "out": 2, "twist": -6, "elbow": 38, "wrist": 8},
          "ra": {"raise": 4, "out": 16, "twist": -24, "elbow": 64, "wrist": -6},
          "rf": {"x": .24, "z": .62, "yaw": 32}, "lf": {"x": -.1, "z": -.56, "yaw": -4}}
GUARD = {"la": {"raise": 56, "out": 0, "twist": -4, "elbow": 44, "wrist": 6},
         "ra": {"raise": 8, "out": 14, "twist": -20, "elbow": 70, "wrist": -6}}
AIR = {"root": {"y": -.45, "pitch": 8, "yaw": 0}, "torso": {"pitch": 6, "yaw": 0}, "head": {"pitch": -14, "yaw": 0},
       "la": {"raise": 50, "out": 24, "elbow": 50}, "ra": {"raise": 20, "out": 28, "elbow": 60},
       "rf": {"x": .05, "z": -.5, "y": 1.0, "toe": -24, "yaw": 0, "knee": 6}, "lf": {"x": -.05, "z": -.35, "y": .9, "toe": -26, "yaw": 0, "knee": 6}}


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    """The stance moved T studs along z (feet with it)."""
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .62 + T}, "lf": {"z": -.56 + T}})
    return merge(base, over or {})


def air(over=None):
    return merge(AIR, over or {})


# ============================================================ locomotion
CALM = {"arms": 1.0}


def calm(spec):
    """Sasuke's gait re-acted by Itachi: the torso barely counter-rotates
    (shoulders stable), the lean is smaller, the head stays on the target,
    the arm swing is contained (CALM["arms"])."""
    out = copy.deepcopy(spec)
    t = out.get("torso")
    if t:
        if "yaw" in t: t["yaw"] *= .45
        if "pitch" in t: t["pitch"] *= .7
    r = out.get("root")
    if r and "pitch" in r: r["pitch"] *= .78
    h = out.get("head")
    if h and "yaw" in h: h["yaw"] *= .5
    k = CALM["arms"]
    if k != 1.0:
        for side in ("la", "ra"):
            a = out.get(side)
            if a and "raise" in a: a["raise"] *= k
    return out


def locomotion(arm):
    saved = (L2.STANCE, L2.GUARD_WALK, nd_shot.Shot.key)
    orig = nd_shot.Shot.key

    def key(self, frame, spec, spacing="ease"):
        return orig(self, frame, calm(spec), spacing)
    L2.STANCE, L2.GUARD_WALK = STANCE, GUARD
    nd_shot.Shot.key = key
    acts = []
    try:
        CALM["arms"] = 1.0
        acts += [L2.walk(arm), L2.walk_back(arm), L2.walk_side(arm, "L"), L2.walk_side(arm, "R"),
                 L2.start(arm), L2.brake(arm), L2.land(arm)]
        CALM["arms"] = .6
        acts += [L2.run(arm), L2.run_back(arm), L2.run_side(arm, "L"), L2.run_side(arm, "R"), L2.sprint(arm)]
        CALM["arms"] = .75
        acts += [L2.jump_air(arm), L2.jump_leap(arm)]
    finally:
        L2.STANCE, L2.GUARD_WALK, nd_shot.Shot.key = saved
        CALM["arms"] = 1.0
    for a in acts:
        a.name = a.name.replace("Lion.", N)
    return acts


def idle(arm):
    """Perfectly still - the breath is the only motion (2 s): the chest rises
    a few millimetres, the open left hand drifts by a degree. Sasuke bounces,
    Itachi waits."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(60, s({"root": {"y": -.32}, "torso": {"pitch": 1}, "head": {"pitch": -3}, "la": {"raise": 54, "elbow": 36}}), "ease")
    sh.key(120, s(), "ease")
    sh.drag(["neck", "shoulder.L"], 6)
    return sh.build(loop=True)


# ================================================================ strikes
def light1(arm):
    """L1, deflection: the LEFT knife-hand from outside to inside on the
    wrist/shoulder. The front foot slides 0.3, the hips barely turn (8 deg):
    all the work is in the forearm, which whips; the right hand stays armed
    at the pouch. Overshoot inside, then the hand returns to the line."""
    sh = Shot(arm, N + "Light1")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.34, "yaw": 32}, "torso": {"yaw": -4}, "head": {"yaw": -20},
                 "la": {"raise": 74, "out": 42, "twist": -34, "elbow": 82, "wrist": 10},
                 "lf": {"y": .08, "toe": 8}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.36, "z": -.12, "pitch": 6, "yaw": 20}, "torso": {"pitch": 4, "yaw": -14},
             "head": {"yaw": -10}, "la": {"raise": 80, "out": -24, "twist": 12, "elbow": 12, "wrist": -12},
             "lf": {"z": -.86, "y": 0, "toe": 0}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"la": {"out": -36, "elbow": 18}, "torso": {"yaw": -18}}), "ease")
    sh.key(16, merge(hit, {"la": {"raise": 62, "out": -4, "twist": -4, "elbow": 36}, "torso": {"yaw": -10}, "root": {"yaw": 24}}), "pass")
    sh.key(24, at(-.3, {"lf": {"z": -.86}, "rf": {"z": .62 - .15}}), "ease")
    sh.drag(["hand.L"], 1).drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def light2(arm):
    """L2, the palm: the RIGHT palm heel from the centre to the sternum,
    under the left hand that presses the guard down. The rear foot pivots
    (heel out) and slides 0.4; no full turn: the hips square by 22 deg.
    Short delay, then dry."""
    sh = Shot(arm, N + "Light2")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.38, "yaw": 34}, "torso": {"yaw": -6},
                 "ra": {"raise": -8, "out": 10, "twist": -10, "elbow": 104, "wrist": 40},
                 "la": {"raise": 42, "out": -12, "twist": 10, "elbow": 52, "wrist": 20}, "rf": {"toe": -12}}), "ease")
    hit = s({"travel": {"z": -.25}, "root": {"y": -.36, "z": -.16, "pitch": 7, "yaw": 6}, "torso": {"pitch": 4, "yaw": -6},
             "head": {"yaw": -6},
             "ra": {"raise": 84, "out": -6, "twist": -40, "elbow": 6, "wrist": 52},
             "la": {"raise": 34, "out": -20, "twist": 14, "elbow": 70, "wrist": 24},
             "rf": {"z": .22, "y": 0, "yaw": 8, "toe": -20}})
    sh.key(5, merge(hit, {"ra": {"raise": 40, "elbow": 60}, "rf": {"z": .42, "y": .12}}), "pass")
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"z": -.2}, "ra": {"raise": 88}}), "ease")
    sh.key(22, s({"travel": {"z": -.25}, "rf": {"z": .22, "toe": 0}, "lf": {"z": -.56}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def light3(arm):
    """L3, the covered withdrawal: the LEFT palm comes down obliquely on the
    shoulder (high to low) while the rear foot WITHDRAWS 0.6: the push and
    the retreat are one motion, it makes the space for the shuriken. Ends
    facing him, the right hand already at the pouch."""
    sh = Shot(arm, N + "Light3")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.22, "yaw": 30, "pitch": 0}, "torso": {"pitch": -4, "yaw": -8},
                 "la": {"raise": 128, "out": 12, "twist": -10, "elbow": 74, "wrist": 0}, "lf": {"toe": 6}}), "ease")
    sh.key(7, s({"root": {"y": -.3, "z": .02}, "la": {"raise": 104, "elbow": 40}, "rf": {"z": .9, "y": .16, "toe": -10}}), "pass")
    hit = s({"root": {"y": -.4, "z": .1, "pitch": 10, "yaw": 22}, "torso": {"pitch": 10, "yaw": -12},
             "la": {"raise": 68, "out": -8, "twist": 6, "elbow": 4, "wrist": 58},
             "ra": {"raise": -6, "out": 18, "twist": -20, "elbow": 84, "wrist": 0},
             "rf": {"z": 1.22, "y": 0, "toe": 0}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"la": {"raise": 62}, "root": {"z": .16}}), "ease")
    sh.key(26, s({"rf": {"z": 1.22}, "lf": {"z": -.3}, "root": {"z": .3}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 2)
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def heavy(arm):
    """Heavy, the crossing palm: the left hand meets and opens the guard (an
    interception, visible: the commitment can be read), pulls it aside while
    the hips sit back; then the pelvis drives 0.5 forward on a short step and
    the RIGHT palm crosses to the shoulder; the pelvis withdraws after."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    sh.key(6, s({"root": {"y": -.4, "yaw": 36}, "torso": {"yaw": -6},
                 "la": {"raise": 86, "out": 30, "twist": -20, "elbow": 38, "wrist": 0},
                 "ra": {"raise": -6, "out": 14, "twist": -10, "elbow": 110, "wrist": 40}}), "ease")
    sh.key(12, s({"root": {"y": -.46, "z": .12, "yaw": 34}, "torso": {"pitch": 0, "yaw": -4},
                  "la": {"raise": 70, "out": -30, "twist": 10, "elbow": 62, "wrist": 10},
                  "ra": {"raise": -4, "out": 12, "elbow": 112, "wrist": 44}, "lf": {"y": .1, "toe": 10}}), "ease")
    sh.key(15, s({"travel": {"z": -.3}, "root": {"y": -.44, "z": -.2, "yaw": 22},
                  "lf": {"z": -.9, "y": .14}, "ra": {"raise": 40, "elbow": 70}}), "pass")
    hit = s({"travel": {"z": -.5}, "root": {"y": -.46, "z": -.46, "pitch": 10, "yaw": 8}, "torso": {"pitch": 6, "yaw": -10},
             "head": {"yaw": -8},
             "ra": {"raise": 86, "out": -12, "twist": -40, "elbow": 4, "wrist": 56},
             "la": {"raise": 40, "out": -30, "twist": 14, "elbow": 110, "wrist": 10},
             "lf": {"z": -1.06, "y": 0, "toe": 0}, "rf": {"toe": -24}})
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"root": {"z": -.5}, "ra": {"raise": 90}}), "ease")
    sh.key(32, merge(hit, {"root": {"z": .02, "pitch": 4}, "ra": {"raise": 30, "elbow": 70}, "la": {"raise": 52, "out": 0, "elbow": 40}}), "pass")
    sh.key(40, at(-.5, {"lf": {"z": -1.06}, "rf": {"z": .12}}), "ease")
    sh.drag(["neck"], 2).drag(["hand.L"], 1)
    return sh.build(markers={"contact": 18 / 60, "recover": 26 / 60})


def launcher(arm):
    """Rising palm: he dips under the open guard (left hand presses it down),
    then the RIGHT palm rises under the chin, the body unfolding with it -
    short elevation, enough for the chase. Two shuriken cover the climb."""
    sh = Shot(arm, N + "Launcher")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.66, "z": -.1, "pitch": 14, "yaw": 20}, "torso": {"pitch": 8, "yaw": -6},
                 "ra": {"raise": -20, "out": 10, "twist": -10, "elbow": 40, "wrist": 52},
                 "la": {"raise": 30, "out": -18, "twist": 10, "elbow": 70, "wrist": 20}}), "ease")
    hit = s({"travel": {"z": -.2}, "root": {"y": -.16, "z": -.2, "pitch": -4, "yaw": 12}, "torso": {"pitch": -8, "yaw": -6},
             "head": {"pitch": -14},
             "ra": {"raise": 140, "out": -6, "twist": -30, "elbow": 12, "wrist": 60},
             "la": {"raise": 20, "out": 10, "elbow": 60}, "rf": {"y": .1, "toe": -26}, "lf": {"z": -.7}})
    sh.key(10, hit, "impact")
    sh.key(14, merge(hit, {"ra": {"raise": 154}, "root": {"y": -.12}}), "ease")
    sh.key(26, at(-.2, {"lf": {"z": -.7}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def sweep(arm):
    """Reaping sweep: he drops (the hands go down for balance) and the RIGHT
    foot reaps low from outside to inside across the opponent's ankles, flat
    on the floor; then the hips withdraw and he stands back up out of reach."""
    sh = Shot(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.92, "z": -.1, "pitch": 18, "yaw": 34}, "torso": {"pitch": 12, "yaw": -10},
                 "la": {"raise": 20, "out": 34, "elbow": 30}, "ra": {"raise": 10, "out": 40, "elbow": 30},
                 "rf": {"x": .5, "z": .2, "y": .08, "toe": -10}}), "ease")
    hit = s({"root": {"y": -1.0, "z": -.1, "pitch": 20, "yaw": -6}, "torso": {"pitch": 12, "yaw": 4},
             "la": {"raise": 30, "out": 50, "elbow": 20}, "ra": {"raise": 6, "out": 30, "elbow": 40},
             "rf": {"x": -.1, "z": -.9, "y": .05, "toe": 0, "yaw": -40}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"rf": {"x": -.45, "z": -.6}, "root": {"yaw": -16}}), "ease")
    sh.key(18, s({"root": {"y": -.6, "z": .2, "pitch": 8}, "rf": {"x": .24, "z": .8, "y": .1}}), "pass")
    sh.key(28, s({"rf": {"z": .8}, "lf": {"z": -.4}, "root": {"z": .18}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def feint_step(arm):
    """Side route after one hit: the left hand fakes a strike (the eye
    follows it), the rear foot passes 30 deg to the flank, the right hand
    touches the arm from there. An afterimage stays where he stood."""
    sh = Shot(arm, N + "FeintStep")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"yaw": 38, "y": -.34}, "la": {"raise": 84, "out": 8, "elbow": 16, "wrist": -10}, "head": {"yaw": -24}}), "launch")
    hit = s({"root": {"y": -.38, "z": -.1, "pitch": 6, "yaw": -24}, "torso": {"pitch": 4, "yaw": -6}, "head": {"yaw": 20},
             "ra": {"raise": 82, "out": -22, "twist": -30, "elbow": 10, "wrist": 30},
             "la": {"raise": 40, "out": 6, "elbow": 92},
             "rf": {"x": .9, "z": -.2, "yaw": -30}})
    sh.key(5, merge(hit, {"ra": {"raise": 40, "elbow": 60}, "rf": {"x": .7, "z": .2, "y": .2}}), "pass")
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"ra": {"raise": 86}}), "ease")
    sh.key(20, s({"root": {"yaw": -10}, "rf": {"x": .9, "z": -.2, "yaw": -10}, "lf": {"x": -.3, "z": -.5}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def counter_palm(arm):
    """The answer to a Read (and the heavy after one hit): the palm is
    already loaded - one frame of settle, then the RIGHT palm drives straight
    through with a half step. Smaller than the blow it punishes."""
    sh = Shot(arm, N + "CounterPalm")
    sh.key(0, s({"ra": {"raise": 10, "elbow": 100, "wrist": 40}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.38, "z": -.3, "pitch": 8, "yaw": 8}, "torso": {"pitch": 4, "yaw": -8},
             "ra": {"raise": 86, "out": -8, "twist": -40, "elbow": 4, "wrist": 56},
             "la": {"raise": 40, "out": -10, "elbow": 80}, "lf": {"z": -.86}})
    sh.key(3, hit, "impact")
    sh.key(6, merge(hit, {"ra": {"raise": 90}, "root": {"z": -.34}}), "ease")
    sh.key(20, at(-.3, {"lf": {"z": -.86}}), "ease")
    return sh.build(markers={"contact": 3 / 60, "recover": 9 / 60})


def dash_attack(arm):
    """Arrival strike: a low glide, the left arm trailing, the right palm
    reaching first - the body arrives after the hand."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s({"root": {"y": -.5, "pitch": 14}}), "ease")
    hit = s({"root": {"y": -.62, "z": -.3, "pitch": 18, "yaw": 10}, "torso": {"pitch": 10, "yaw": -8},
             "ra": {"raise": 88, "out": -10, "twist": -40, "elbow": 8, "wrist": 52},
             "la": {"raise": -30, "out": 22, "elbow": 20},
             "lf": {"z": -1.2}, "rf": {"z": .9, "y": .16, "toe": -30}})
    sh.key(4, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.34}}), "ease")
    sh.key(20, s({"lf": {"z": -.9}, "rf": {"z": .5}}), "ease")
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


# ===================================================================== air
def air1(arm):
    """Short side palm in the air: the hips turn a quarter, the LEFT palm
    goes out to the side; knees stay gathered (no flailing)."""
    sh = Shot(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": 20}, "la": {"raise": 60, "out": -20, "elbow": 100}}), "ease")
    hit = air({"root": {"yaw": -22}, "torso": {"yaw": -10}, "la": {"raise": 86, "out": 30, "twist": -10, "elbow": 6, "wrist": 52}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"la": {"raise": 90}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 8 / 60, "recover": 14 / 60})


def air2(arm):
    """Descending knife-hand: the RIGHT hand rises above the head, the body
    folds over it and it falls on the collarbone."""
    sh = Shot(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(5, air({"root": {"pitch": -4}, "torso": {"pitch": -8}, "ra": {"raise": 162, "out": 6, "elbow": 60}}), "ease")
    hit = air({"root": {"pitch": 22}, "torso": {"pitch": 18}, "head": {"pitch": -24},
               "ra": {"raise": 70, "out": -10, "twist": 10, "elbow": 6, "wrist": -10}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"ra": {"raise": 60}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def air_drive(arm):
    """Air route toward him: a side kick. The knee chambers to the chest,
    the hips turn side-on and the RIGHT heel drives out - the body leans back
    over it (a line from head to heel)."""
    sh = Shot(arm, N + "AirDrive")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": 30}, "torso": {"pitch": 0}, "rf": {"x": .05, "z": -.4, "y": 1.3, "toe": -10, "knee": 10}}), "ease")
    hit = air({"root": {"yaw": 64, "pitch": -6, "roll": -8}, "torso": {"pitch": -8, "yaw": -20}, "head": {"yaw": -50},
               "la": {"raise": 40, "out": 50, "elbow": 40}, "ra": {"raise": 30, "out": 40, "elbow": 50},
               "rf": {"x": .1, "z": -1.3, "y": 1.1, "toe": 10, "knee": 0}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"rf": {"z": -1.4}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def air_spike(arm):
    """Air route down: the hammer drop. Both hands clasp above the head, the
    back arches, then the whole body closes over them and they fall."""
    sh = Shot(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    clasp = {"raise": 168, "out": -18, "twist": 0, "elbow": 40, "wrist": 0}
    sh.key(5, air({"root": {"pitch": -8}, "torso": {"pitch": -14}, "head": {"pitch": -24}, "la": clasp, "ra": clasp}), "ease")
    down = {"raise": 62, "out": -14, "twist": 0, "elbow": 10, "wrist": 10}
    hit = air({"root": {"pitch": 26}, "torso": {"pitch": 26}, "head": {"pitch": -30}, "la": down, "ra": down})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"root": {"pitch": 30}}), "ease")
    sh.key(24, air(), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def air_switch(arm):
    """Air route aside: the hook switch. The body winds one way and swings
    round the other, the LEFT forearm hooking at head height."""
    sh = Shot(arm, N + "AirSwitch")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": 36}, "torso": {"yaw": 10}, "la": {"raise": 70, "out": 50, "elbow": 80}}), "ease")
    hit = air({"root": {"yaw": -34}, "torso": {"yaw": -16}, "head": {"yaw": 10},
               "la": {"raise": 88, "out": -10, "twist": 40, "elbow": 88, "wrist": 0}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"root": {"yaw": -40}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 8 / 60, "recover": 13 / 60})


# ================================================================= throws
def throw_shuriken(arm):
    """The shuriken really leaves the fingers: the RIGHT hand takes them from
    the pouch across the body to the left shoulder, then a flat backhand
    flick opens the arm toward the target (release at the snap); the left
    hand points the line."""
    sh = Shot(arm, N + "Throw.Shuriken")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"yaw": 34}, "torso": {"yaw": -2},
                 "ra": {"raise": 46, "out": -44, "twist": -10, "elbow": 118, "wrist": 30},
                 "la": {"raise": 60, "out": 10, "elbow": 26}}), "ease")
    rel = s({"root": {"yaw": 18}, "torso": {"yaw": -16},
             "ra": {"raise": 86, "out": 28, "twist": 10, "elbow": 6, "wrist": -30},
             "la": {"raise": 52, "out": -6, "elbow": 40}})
    sh.key(7, rel, "launch")
    sh.key(10, merge(rel, {"ra": {"out": 34}}), "ease")
    sh.key(18, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ============================================================== techniques
def tiger():
    """The tiger seal at the chest (both hands, index and middle fingers up)."""
    return {"la": {"raise": 72, "out": -36, "twist": 34, "elbow": 104, "wrist": 10},
            "ra": {"raise": 72, "out": -36, "twist": 34, "elbow": 104, "wrist": 10}}


ANCHOR = {"rf": {"x": .3, "z": .78, "yaw": 34}, "lf": {"x": -.12, "z": -.66, "yaw": -4}, "root": {"y": -.4}}


def read(arm):
    """Sharingan Read: the left hand opens palm up toward the opponent (an
    invitation), the head barely moves - the eyes do the work. Held through
    the read (Active 1 s), then back to the stance."""
    out = []
    ch = Shot(arm, N + "Read.Channel")
    ch.key(0, s(), "ease")
    invite = s({"root": {"y": -.34, "z": .08}, "head": {"pitch": 2, "yaw": -12},
                "la": {"raise": 62, "out": 14, "twist": 60, "elbow": 22, "wrist": -24},
                "ra": {"raise": 0, "out": 16, "elbow": 80, "wrist": 0}})
    ch.key(6, invite, "ease")
    out.append(ch.build(markers={"release": 6 / 60}))
    re = Shot(arm, N + "Read.Release")
    re.key(0, invite, "ease")
    re.key(30, merge(invite, {"head": {"pitch": 0}, "la": {"raise": 64}}), "ease")
    re.key(60, invite, "ease")
    out.append(re.build())
    rc = Shot(arm, N + "Read.Recover")
    rc.key(0, invite, "ease")
    rc.key(12, s(), "ease")
    out.append(rc.build())
    return out


def needle_fan(arm):
    """Shadow Shuriken (five blades): both hands go to the pouches and cross
    at the chest (the blades fanned between the fingers), the knees sink;
    then both arms snap open and five blades leave in a fan."""
    out = []
    ch = Shot(arm, N + "NeedleFan.Channel")
    ch.key(0, s(), "ease")
    cross = {"raise": 44, "out": -46, "twist": 10, "elbow": 122, "wrist": 20}
    load = s({"root": {"y": -.5, "yaw": 10}, "torso": {"pitch": 6, "yaw": -4}, "head": {"pitch": -2},
              "la": cross, "ra": cross})
    ch.key(10, load, "ease")
    ch.key(15, merge(load, {"root": {"y": -.52}}), "ease")
    out.append(ch.build(markers={"release": 15 / 60}))
    re = Shot(arm, N + "NeedleFan.Release")
    re.key(0, load, "launch")
    fan = {"raise": 84, "out": 62, "twist": 0, "elbow": 8, "wrist": -20}
    opened = s({"root": {"y": -.44, "yaw": 6}, "torso": {"pitch": 2, "yaw": -4}, "la": fan, "ra": fan})
    re.key(4, opened, "impact")
    re.key(10, merge(opened, {"la": {"raise": 80}, "ra": {"raise": 80}}), "ease")
    out.append(re.build(markers={"release": 4 / 60}))
    rc = Shot(arm, N + "NeedleFan.Recover")
    rc.key(0, opened, "ease")
    rc.key(16, s(), "ease")
    out.append(rc.build())
    return out


def mirage_cast(arm):
    """Genjutsu: Mirage. One single-hand seal - the right hand rises in front
    of the face, two fingers up - and stillness: the eyes hold him. On the
    release the hand lowers slowly; nothing else moves."""
    out = []
    ch = Shot(arm, N + "MirageCast.Channel")
    ch.key(0, s(), "ease")
    seal = s({"root": {"y": -.28}, "head": {"pitch": 2, "yaw": -10},
              "ra": {"raise": 100, "out": -40, "twist": 30, "elbow": 128, "wrist": 0},
              "la": {"raise": 6, "out": 14, "elbow": 20}})
    ch.key(12, seal, "ease")
    ch.key(25, merge(seal, {"head": {"pitch": 4}}), "ease")
    out.append(ch.build(markers={"release": 25 / 60}))
    re = Shot(arm, N + "MirageCast.Release")
    re.key(0, seal, "ease")
    re.key(8, merge(seal, {"ra": {"raise": 90, "elbow": 120}}), "ease")
    out.append(re.build())
    rc = Shot(arm, N + "MirageCast.Recover")
    rc.key(0, seal, "ease")
    rc.key(14, s(), "ease")
    out.append(rc.build())
    return out


def fire_seal_inhale(sh, n):
    """Shared by the two fire jutsu, Itachi's way (user 28/10: "les Katon,
    c'est toutes les mêmes"): unlike Sasuke he never brings a ringed hand to
    the mouth. The tiger seal snaps at the chest and STAYS there; the body
    stays upright over an anchored rear foot, only the chest fills and the
    chin lifts."""
    sh.key(0, s(), "ease")
    sh.key(6, s(merge(ANCHOR, tiger())), "pass")
    seal = tiger()
    inhale = s(merge(ANCHOR, merge({"root": {"y": -.36, "z": .1, "pitch": -4}, "torso": {"pitch": -12}, "head": {"pitch": 16}},
                                   merge(seal, {"la": {"raise": 80, "elbow": 98}, "ra": {"raise": 80, "elbow": 98}}))))
    sh.key(n, inhale, "ease")
    return inhale


def fire_seal_blow(lean=0, yaw=0):
    """The release: the seal held still at the chest (it is the trigger), the
    chin drops and the chest goes forward a little - no flourish."""
    seal = tiger()
    return s(merge(ANCHOR, merge({"root": {"y": -.46, "z": -.2, "pitch": 9 + lean, "yaw": yaw * .4}, "torso": {"pitch": 7 + lean, "yaw": yaw * .3},
                                  "head": {"pitch": -14, "yaw": yaw}},
                                 merge(seal, {"la": {"raise": 66, "elbow": 110}, "ra": {"raise": 66, "elbow": 110}}))))


def fire_bloom(arm):
    """Katon: Great Fireball, Itachi's way: ONE brief seal kept at the chest,
    upright, a short inhale; the fire pours while he barely moves."""
    out = []
    ch = Shot(arm, N + "FireBloom.Channel")
    inhale = fire_seal_inhale(ch, 18)
    out.append(ch.build(markers={"release": 18 / 60}))
    ho = Shot(arm, N + "FireBloom.Hold")
    ho.key(0, inhale, "ease")
    ho.key(20, merge(inhale, {"root": {"y": -.4}, "torso": {"pitch": -14}}), "ease")
    ho.key(40, inhale, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))
    re = Shot(arm, N + "FireBloom.Release")
    blow = fire_seal_blow()
    re.key(0, inhale, "launch")
    re.key(4, blow, "impact")
    re.key(24, merge(blow, {"root": {"z": -.22}, "head": {"pitch": -16}}), "ease")
    out.append(re.build(markers={"release": 4 / 60}))
    rc = Shot(arm, N + "FireBloom.Recover")
    rc.key(0, merge(blow, {"root": {"z": -.22}, "head": {"pitch": -16}}), "ease")
    rc.key(10, s(merge(ANCHOR, tiger())), "pass")
    rc.key(22, s(), "ease")
    out.append(rc.build())
    return out


def phoenix_flower(arm):
    """Phoenix Flower: the same seal and inhale, then three short breaths, the
    seal still held at the chest while only the head turns left - centre -
    right (each puff a fireball, the shuriken hidden inside)."""
    out = []
    ch = Shot(arm, N + "PhoenixFlower.Channel")
    inhale = fire_seal_inhale(ch, 18)
    out.append(ch.build(markers={"release": 18 / 60}))
    re = Shot(arm, N + "PhoenixFlower.Release")
    re.key(0, inhale, "launch")
    re.key(3, fire_seal_blow(2, -30), "impact")
    re.key(8, fire_seal_blow(-2, -6), "impact")
    re.key(13, fire_seal_blow(2, 22), "impact")
    re.key(19, fire_seal_blow(0, 16), "ease")
    out.append(re.build(markers={"release": 3 / 60}))
    rc = Shot(arm, N + "PhoenixFlower.Recover")
    rc.key(0, fire_seal_blow(0, 16), "ease")
    rc.key(18, s(), "ease")
    out.append(rc.build())
    return out


# ================================================================== states
def intro(arm):
    """Match intro (2.6 s): standing, perfectly still, eyes closed, the arms
    hanging. Nothing for a full second. The head lifts (the Sharingan
    opens), then - only then - the left hand rises into the invitation."""
    sh = Shot(arm, N + "Intro")
    still = {"root": {"y": -.06, "pitch": 0, "yaw": 16}, "torso": {"pitch": 0, "yaw": -6}, "head": {"pitch": 16, "yaw": -10},
             "la": {"raise": 2, "out": 8, "twist": 0, "elbow": 10, "wrist": 0}, "ra": {"raise": 2, "out": 8, "twist": 0, "elbow": 10, "wrist": 0},
             "rf": {"x": .16, "z": .3, "yaw": 16}, "lf": {"x": -.12, "z": -.3, "yaw": 0}}
    sh.key(0, still, "ease")
    sh.key(64, still, "ease")
    sh.key(84, merge(still, {"head": {"pitch": -6, "yaw": -14}}), "ease")
    sh.key(104, merge(still, {"head": {"pitch": -6, "yaw": -14}, "la": {"raise": 30, "out": 4, "elbow": 30}}), "pass")
    sh.key(128, s({"rf": {"x": .2, "z": .5}, "lf": {"x": -.1, "z": -.5}}), "ease")
    sh.key(156, s({"rf": {"x": .2, "z": .5}, "lf": {"x": -.1, "z": -.5}}), "ease")
    sh.drag(["neck"], 4)
    return sh.build()


def win(arm):
    """Victory: no triumph. He straightens, lowers the guard, closes his eyes
    and turns three-quarters away; one last glance back over the shoulder."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    up = {"root": {"y": -.08, "pitch": 0, "yaw": 22}, "torso": {"pitch": 0, "yaw": -6}, "head": {"pitch": 10, "yaw": -12},
          "la": {"raise": 4, "out": 8, "twist": 0, "elbow": 12, "wrist": 0}, "ra": {"raise": 2, "out": 8, "twist": 0, "elbow": 12, "wrist": 0},
          "rf": {"x": .24, "z": .62, "yaw": 30}, "lf": {"x": -.1, "z": -.56, "yaw": 0}}
    sh.key(20, up, "ease")
    sh.key(34, merge(up, {"root": {"yaw": 60}, "rf": {"x": .1, "z": .2, "y": .2, "yaw": 60}}), "pass")
    away = merge(up, {"root": {"yaw": 96}, "head": {"pitch": 8, "yaw": -40}, "rf": {"x": .2, "z": -.1, "y": 0, "yaw": 96}, "lf": {"x": -.16, "z": -.4, "yaw": 86}})
    sh.key(48, away, "ease")
    sh.key(100, merge(away, {"head": {"yaw": -58, "pitch": 4}}), "ease")
    sh.key(150, merge(away, {"head": {"yaw": -50, "pitch": 10}}), "ease")
    sh.drag(["neck"], 4)
    return sh.build()


def awaken(arm):
    """Sharingan focus: the head drops and the left hand passes slowly in
    front of the eyes; when it moves aside the head is up and the eyes are
    open - he settles lower, more still than before."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    sh.key(10, s({"head": {"pitch": 16}, "la": {"raise": 118, "out": -44, "twist": 20, "elbow": 140, "wrist": 0}}), "ease")
    sh.key(24, s({"head": {"pitch": -8}, "la": {"raise": 72, "out": 44, "twist": -20, "elbow": 20, "wrist": 0}}), "pass")
    sh.key(38, s({"root": {"y": -.4}, "head": {"pitch": -6}}), "ease")
    sh.key(48, s({"root": {"y": -.4}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), light1(arm), light2(arm), light3(arm), heavy(arm), launcher(arm), sweep(arm), feint_step(arm),
             counter_palm(arm), dash_attack(arm), air1(arm), air2(arm), air_drive(arm), air_spike(arm), air_switch(arm),
             throw_shuriken(arm), intro(arm), win(arm), awaken(arm)]
    acts += read(arm)
    acts += needle_fan(arm)
    acts += mirage_cast(arm)
    acts += fire_bloom(arm)
    acts += phoenix_flower(arm)
    return acts
