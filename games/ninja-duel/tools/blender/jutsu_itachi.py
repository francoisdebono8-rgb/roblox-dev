"""Itachi's seal jutsu and the string's middle hit (04/11, user: « les
animations pour toutes les attaques en plus ne sont pas faites... fais-moi de
belles animations »).

Authored on his body (itachi_p3.STANCE: upright, quiet, the left hand open in
front, the right low by the pouch). The bible (docs/characters/ITACHI.md):
economy of the torso, one hand always free, no full turn without reason, the
gaze moves before the body, a calm pose after the impact - a SMALLER gesture
than the opponent's. Each jutsu opens with its two seals (jutsu_sasuke.weave:
nd_seals.weave's timing, the hands really pressed together), then the act:

  CrowGenjutsu        tiger - snake, the right hand gathers to the left
                      shoulder (the sleeve closed over the chest), the chin
                      drops; then ONE sweep - the arm opens out wide at
                      shoulder height, the palm spread, the crows pour out of
                      the sleeve toward him - while the head does not move
                      (the genjutsu is in the eyes); the arm sinks, calm
  ExplodingClone      snake - ram, then the bait: he stands tall and drops
                      his guard, the left hand open low, the right keeping a
                      one-hand seal hidden at the hip (the clone is ready to
                      go off) - stillness through the window, then the stance
  SharinganParalysis  ram - rat, then the stare: the left hand rises open,
                      palm toward him, beside the face (the eyes stay
                      visible over it), the chin lowers - a hair of a push on
                      the release, then held, and the hand lowers slowly
  PhoenixSageFire     rat - tiger, the right hand keeps the tiger one-handed
                      at the sternum, the left falls away; the inhale lifts
                      the chest and the head turns to the far left; the fire
                      is ONE breath swept left to right, five pulses of the
                      chest in it (five fireballs fanned) - his Phoenix
                      Flower is three separate puffs, two-handed
  Light4              L1 jab, L2 low kick, L4, L3 hook: the left hand presses
                      the guard down while the right spear hand goes in under
                      it to the solar plexus on a half step - small, dry, then
                      the calm stance again

Server timings (Shared/SealJutsu, Shared/Attacks):
  CrowGenjutsu ch .14 act .1 rec .3     ExplodingClone ch .04 act .04 rec .2 (stance .9)
  SharinganParalysis ch .3 act .06 rec .24
  PhoenixSageFire ch .3 act .2 rec .3   Light4 .09 / .12 / .28
"""
from nd_shot import Shot, merge
from itachi_p3 import STANCE
from jutsu_sasuke import stance_fn, weave, seal

N = "Mirage."
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]
# The right hand alone in the tiger (two fingers up) at the sternum.
TIGER_R = {"raise": 32.2, "out": -20.2, "twist": 58.6, "elbow": 102.7, "wrist": 0}
# The left hand open at his side, relaxed.
LOW_L = {"raise": 6, "out": 12, "twist": 0, "elbow": 18, "wrist": 0}


# =========================================================== CrowGenjutsu
def crows(arm):
    out = []
    ch = Shot(arm, N + "CrowGenjutsu.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.34}, "head": {"pitch": -2}})
    last = weave(ch, 0, (1, 2), base, beat=4)
    # the sleeve closes over the chest: the right hand gathered to the left
    # shoulder, the left falls away; the chin drops (the eyes look up at him)
    gather = s({"root": {"y": -.38, "z": .04, "yaw": 20}, "torso": {"pitch": 4, "yaw": -14},
                "head": {"pitch": 6, "yaw": -6},
                "ra": {"raise": 53, "out": -56, "twist": 70, "elbow": 38, "wrist": 0},
                "la": LOW_L})
    ch.key(last + 6, gather, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 6) / 60}))

    re = Shot(arm, N + "CrowGenjutsu.Release")
    re.key(0, gather, "ease")
    # one sweep: the arm opens out to the side at shoulder height, the palm
    # spread toward him; the chest opens with it, the head stays put
    sweep = s({"root": {"y": -.34, "z": .02, "yaw": 30}, "torso": {"pitch": 0, "yaw": -4},
               "head": {"pitch": 4, "yaw": -24},
               "ra": {"raise": 92, "out": 64, "twist": -50, "elbow": 8, "wrist": -40},
               "la": LOW_L})
    re.key(2, merge(gather, {"ra": {"raise": 74, "out": -4, "twist": 20, "elbow": 40}, "torso": {"yaw": -10}}), "pass")
    re.key(4, sweep, "impact")
    re.key(8, merge(sweep, {"ra": {"out": 72, "raise": 94, "wrist": -46}, "torso": {"yaw": -2}}), "ease")
    held = merge(sweep, {"ra": {"out": 70, "raise": 90, "wrist": -40}})
    re.key(12, held, "ease")
    re.drag(["hand.R"], 2)
    out.append(re.build(markers={"release": 4 / 60}))

    rc = Shot(arm, N + "CrowGenjutsu.Recover")
    rc.key(0, held, "ease")
    rc.key(6, merge(held, {"ra": {"raise": 84, "out": 68}}), "ease")
    rc.key(12, merge(s({"head": {"pitch": 0}}), {"ra": {"raise": 30, "out": 30, "twist": -20, "elbow": 30, "wrist": -10}}), "pass")
    rc.key(18, s(), "ease")
    rc.drag(["hand.R"], 2).drag(["neck"], 1)
    out.append(rc.build())
    return out


# ========================================================= ExplodingClone
BAIT = {"root": {"y": -.16, "z": .02, "pitch": 0, "yaw": 22}, "torso": {"pitch": 0, "yaw": -8},
        "head": {"pitch": 4, "yaw": -14},
        "ra": {"raise": -7.6, "out": 4.5, "twist": 46.6, "elbow": 91.4, "wrist": 0},
        "la": {"raise": 10, "out": 14, "twist": -10, "elbow": 22, "wrist": -6}}


def clone(arm):
    out = []
    ch = Shot(arm, N + "ExplodingClone.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.32}, "head": {"pitch": -2}})
    last = weave(ch, 0, (2, 3), base, beat=3)
    out.append(ch.build(markers={"release": last / 60}))

    pose = merge(base, {"root": {"y": -.44}})
    sealed = merge(pose, seal(3, pose))
    bait = s(BAIT)
    re = Shot(arm, N + "ExplodingClone.Release")
    re.key(0, sealed, "ease")
    # the guard drops: he straightens, the hands come apart and down
    re.key(4, merge(bait, {"root": {"y": -.2}, "la": {"raise": 18, "elbow": 30}}), "impact")
    re.key(8, bait, "ease")
    re.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(re.build(markers={"release": 4 / 60}))

    rc = Shot(arm, N + "ExplodingClone.Recover")
    rc.key(0, bait, "ease")
    rc.key(7, merge(bait, {"root": {"y": -.18}, "head": {"pitch": 6}}), "ease")
    rc.key(14, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# ===================================================== SharinganParalysis
STOP_L = {"raise": 100, "out": 4, "twist": -70, "elbow": 24, "wrist": -56}


def paralysis(arm):
    out = []
    ch = Shot(arm, N + "SharinganParalysis.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.34}, "head": {"pitch": -2}})
    last = weave(ch, 0, (3, 4), base, beat=5)
    # the left hand leaves the seal and rises open toward him, the right
    # falls to the pouch; the chin lowers: he looks at him from under the brow
    ch.key(last + 5, s({"root": {"y": -.4, "yaw": 24}, "head": {"pitch": 2, "yaw": -12},
                        "la": {"raise": 80, "out": -10, "twist": -40, "elbow": 60, "wrist": -20},
                        "ra": {"raise": 10, "out": 14, "twist": -24, "elbow": 60}}), "pass")
    stare = s({"root": {"y": -.4, "z": .04, "pitch": 2, "yaw": 22}, "torso": {"pitch": 2, "yaw": -6},
               "head": {"pitch": 8, "yaw": -14},
               "la": STOP_L, "ra": {"raise": 2, "out": 16, "twist": -24, "elbow": 56, "wrist": -6}})
    ch.key(last + 10, stare, "ease")
    ch.drag(["neck"], 2)
    out.append(ch.build(markers={"release": (last + 10) / 60}))

    re = Shot(arm, N + "SharinganParalysis.Release")
    re.key(0, stare, "ease")
    held = merge(stare, {"root": {"z": -.02}, "head": {"pitch": 10}, "la": {"raise": 98, "elbow": 14, "wrist": -60}})
    re.key(3, merge(held, {"root": {"z": -.04}, "la": {"elbow": 10}}), "impact")
    re.key(10, held, "ease")
    out.append(re.build(markers={"release": 3 / 60}))

    rc = Shot(arm, N + "SharinganParalysis.Recover")
    rc.key(0, held, "ease")
    rc.key(6, merge(held, {"head": {"pitch": 9}}), "ease")
    rc.key(15, s(), "ease")
    rc.drag(["neck"], 3)
    out.append(rc.build())
    return out


# ======================================================= PhoenixSageFire
ANCHOR = {"rf": {"x": .3, "z": .74, "yaw": 34}, "lf": {"x": -.12, "z": -.62, "yaw": -4}}


def breath(yaw, pump):
    """The body during the breath: `yaw` across the fan (degrees, the head
    leads, the chest and hips follow less), `pump` 0..1 the push of a puff."""
    return s(merge(ANCHOR, {"root": {"y": -.42, "z": -.08 - .04 * pump, "pitch": 5 + 3 * pump, "yaw": 26 + yaw * .25},
                            "torso": {"pitch": 4 + 5 * pump, "yaw": -10 + yaw * .35}, "head": {"pitch": -6 - 6 * pump, "yaw": -14 + yaw * .5},
                            "ra": TIGER_R, "la": LOW_L}))


def phoenix(arm):
    out = []
    ch = Shot(arm, N + "PhoenixSageFire.Channel")
    ch.key(0, s(), "ease")
    base = s(merge(ANCHOR, {"root": {"y": -.34}, "head": {"pitch": -2}}))
    last = weave(ch, 0, (4, 1), base, beat=5)
    # the left hand falls away, the right keeps the tiger at the sternum;
    # the inhale: the chest fills, the chin lifts, the head turns to the left
    inhale = s(merge(ANCHOR, {"root": {"y": -.38, "z": .1, "pitch": -2, "yaw": 20}, "torso": {"pitch": -10, "yaw": -18},
                              "head": {"pitch": 12, "yaw": -26}, "ra": TIGER_R, "la": LOW_L}))
    ch.key(last + 5, merge(inhale, {"torso": {"pitch": -4}, "head": {"pitch": 4}}), "pass")
    ch.key(last + 11, inhale, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": (last + 11) / 60}))

    re = Shot(arm, N + "PhoenixSageFire.Release")
    re.key(0, inhale, "ease")
    # one breath swept left to right; five pulses ride on it
    for i, f in enumerate((2, 5, 8, 11, 14)):
        yaw = -32 + 16 * i
        re.key(f, breath(yaw, 1.0), "impact")
        re.key(f + 2, breath(yaw + 6, .25), "ease")
    re.key(18, breath(36, 0), "ease")
    re.drag(["neck"], 1)
    out.append(re.build(markers={"release": 2 / 60}))

    rc = Shot(arm, N + "PhoenixSageFire.Recover")
    rc.key(0, breath(36, 0), "ease")
    rc.key(9, s(merge(ANCHOR, {"root": {"y": -.36}, "head": {"pitch": -2, "yaw": -8},
                               "ra": {"raise": 20, "out": 6, "twist": 10, "elbow": 80, "wrist": 0}})), "pass")
    rc.key(18, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# ================================================================ strikes
def light4(arm):
    """The string's middle hit (L1 jab, L2 low kick, L4, L3 hook): the left
    hand presses the guard down, the right spear hand goes in under it to
    the solar plexus (.09 / .12 / .28)."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.36, "yaw": 34}, "torso": {"yaw": -6}, "head": {"yaw": -20},
              "la": {"raise": 66, "out": -6, "twist": 10, "elbow": 30, "wrist": 30},
              "ra": {"raise": -14, "out": 12, "twist": -10, "elbow": 96, "wrist": 0},
              "lf": {"y": .08, "z": -.66}})
    sh.key(3, load, "ease")
    T = -.25
    hit = s({"travel": {"z": T}, "root": {"y": -.42, "z": -.18, "pitch": 8, "yaw": 10}, "torso": {"pitch": 6, "yaw": -8},
             "head": {"pitch": -2, "yaw": -8},
             "ra": {"raise": 80, "out": -10, "twist": -4, "elbow": 4, "wrist": 0},
             "la": {"raise": 34, "out": -14, "twist": 10, "elbow": 36, "wrist": 44},
             "lf": {"z": LF["z"] + T}, "rf": {"y": .04, "toe": -16, "yaw": 20}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.22}, "ra": {"raise": 82, "elbow": 0}}), "ease")
    sh.key(13, merge(hit, {"root": {"z": -.06, "yaw": 20}, "torso": {"yaw": -10},
                           "ra": {"raise": 30, "out": 8, "twist": -20, "elbow": 70, "wrist": -6},
                           "la": {"raise": 48, "out": 0, "twist": -6, "elbow": 40, "wrist": 8},
                           "rf": {"z": RF["z"] + T + .1, "y": .1, "toe": -8, "yaw": 30}}), "pass")
    sh.key(19, at(T), "ease")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 13 / 60})


def author(arm):
    acts = crows(arm)
    acts += clone(arm)
    acts += paralysis(arm)
    acts += phoenix(arm)
    acts.append(light4(arm))
    return acts
