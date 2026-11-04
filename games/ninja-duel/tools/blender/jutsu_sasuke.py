"""Sasuke's seal jutsu, his running strike and the string's middle hit (04/11,
user: « les animations pour toutes les attaques en plus ne sont pas faites...
fais-moi de belles animations »).

Authored on his body (clips_lion2.STANCE: low, coiled, left lead, chest over
the front foot). The bible (docs/characters/SASUKE.md): the legs explain the
entry, the pivot foot stays down, the free hand keeps access to the wire, he
reads more aggressive than Itachi. Each jutsu opens with its two seals
(weave below: nd_seals.weave's timing, the hands really pressed together),
then the act:

  Soshuha            tiger - snake, the hands dive and cross low in front of
                     the hips (a shuriken in each), the body folded over them;
                     the throw flings both arms open forward-wide (the closed
                     X opens into a V) on a lunge; Recover: the wires hauled,
                     both elbows driven back past the ribs, the weight sitting
                     back against them - then a second, shorter tug
  WindmillBlades     snake - ram, the right hand goes to the back pouch, the
                     body turns side-on over the loaded rear leg, the left arm
                     aiming, the blades cocked by the ear; the hips unwind
                     first, the arm whips the three blades flat across with a
                     step in and follows through across the body; Recover:
                     the left hand holds the line out front, the right fist
                     yanks it taut to the hip
  SharinganCounter   ram - rat snapped, then the reading stance: lower, the
                     weight back so the front leg is light (the answer is a
                     kick), the lead hand open forward, the head still - held
                     through the window, then the stance
  SharinganCopy      rat - tiger, two fingers come up beside the right eye
                     (the Sharingan focuses: the head dips, then lifts), the
                     other hand gathers at the hip; the mirrored cast: a step
                     in and the open palm thrown at him, the fingers still at
                     the eye
  DashAttack         out of the run, the flying knee: he takes off from the
                     left foot, the right knee drives through the body (the
                     knee first, the body after it), lands on the left foot,
                     the right foot set down behind: the stance
  Light4             jab, cross, THEN the lead hook to the body: a level
                     change (the knees drop, the head slips outside), the
                     left elbow out and the hips turn it in - it winds the
                     hips the other way for the roundhouse that follows

Server timings (Shared/SealJutsu, Shared/Attacks):
  Soshuha ch .16 act .04 rec .24       WindmillBlades ch .24 act .06 rec .26
  SharinganCounter ch .04 act .04 rec .2 (stance .7)
  SharinganCopy ch .18 act .06 rec .26
  DashAttack .07 / .15 / .27           Light4 .09 / .12 / .28
"""
from nd_shot import Shot, merge
from clips_lion2 import STANCE
import nd_seals

N = "Lion."

# ------------------------------------------------------------ shared helpers
# (jutsu_itachi / jutsu_kakashi import these.)
# Every key is a whole body: a channel a key leaves out would keep the value
# of an earlier key (Shot merges each key onto the previous one).
ZERO = {"travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0},
        "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}

# The four seals with the hands really together. nd_seals' poses put the
# hands at the face and leave a gap in two of them (snake 0.6 stud, rat 0.4
# between the hands); these are the same shapes solved so the hand blocks
# meet in front of the chin and chest (rig-measured, chest space): tiger
# side by side and tall, snake clasped and turned (one forearm rolled over),
# ram the right hand over the left, rat the right standing above the left.
SEAL = {
    1: {"ra": {"raise": 47.4, "out": -19.2, "twist": 44.1, "elbow": 105.8, "wrist": 14, "wroll": 0},
        "la": {"raise": 47.4, "out": -19.2, "twist": 44.1, "elbow": 105.8, "wrist": 14, "wroll": 0}},
    2: {"ra": {"raise": 22.1, "out": -53.2, "twist": 35.5, "elbow": 108.9, "wrist": -6, "wroll": 0},
        "la": {"raise": 42.5, "out": -16.3, "twist": 50.0, "elbow": 107.7, "wrist": 10, "wroll": 0}},
    3: {"ra": {"raise": 57.0, "out": -10.8, "twist": 57.6, "elbow": 97.8, "wrist": 10, "wroll": 0},
        "la": {"raise": 28.8, "out": -14.3, "twist": 48.5, "elbow": 109.5, "wrist": 10, "wroll": 0}},
    4: {"ra": {"raise": 54.9, "out": -35.6, "twist": 36.0, "elbow": 95.0, "wrist": 26, "wroll": 0},
        "la": {"raise": 36.6, "out": -19.7, "twist": 46.5, "elbow": 108.7, "wrist": 0, "wroll": 0}},
}


def seal(n, over=None):
    """Seal n's arms (+ the chin tucked over the hands) on top of `over`."""
    return merge(merge(over or {}, {"torso": {"pitch": (over or {}).get("torso", {}).get("pitch", 0) + 4},
                                    "head": {"pitch": (over or {}).get("head", {}).get("pitch", 0) + 6}}), SEAL[n])


def weave(shot, start, signs, base, beat=5, sink=.06):
    """nd_seals.weave (a seal every `beat` frames, snapped, the hips a little
    lower on each), re-keyed on the same frames with the hands pressed
    together. Returns the frame of the last seal."""
    last = nd_seals.weave(shot, start, signs, base, beat, sink)
    y = (base.get("root") or {}).get("y", 0)
    for i, n in enumerate(signs):
        pose = merge(base, {"root": {"y": y - sink * (i + 1)}})
        shot.key(start + beat * (i + 1), merge(pose, seal(n, pose)), "impact")
    return last


def stance_fn(stance):
    base = merge(ZERO, stance)

    def s(over=None):
        return merge(base, over or {})

    def at(T, over=None):
        """The stance T studs along z (the feet with it)."""
        return merge(s({"travel": {"z": T}, "rf": {"z": stance["rf"]["z"] + T}, "lf": {"z": stance["lf"]["z"] + T}}), over or {})
    return s, at


s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]


# ================================================================ Soshuha
CROSS_R = {"raise": 17.0, "out": -30.0, "twist": 74.0, "elbow": 45.7, "wrist": 20}
CROSS_L = {"raise": 20.9, "out": -32.0, "twist": 69.9, "elbow": 46.1, "wrist": 20}


def soshuha(arm):
    out = []
    ch = Shot(arm, N + "Soshuha.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.56, "pitch": 8}, "head": {"pitch": -2}})
    last = weave(ch, 0, (1, 2), base, beat=4)
    # The hands leave the seal for the pouches and cross low in front of the
    # hips, a shuriken in each: the body folds over them (the coil). The
    # crossed X is the closed shape the throw will open.
    cross = s({"root": {"y": -.86, "z": .06, "pitch": 22, "yaw": 24}, "torso": {"pitch": 18, "yaw": -8},
               "head": {"pitch": -24, "yaw": -14}, "ra": CROSS_R, "la": CROSS_L})
    ch.key(last + 5, cross, "ease")
    coil = merge(cross, {"root": {"y": -.92, "z": .08}, "torso": {"pitch": 20}, "head": {"pitch": -26}})
    ch.key(last + 9, coil, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 9) / 60}))

    re = Shot(arm, N + "Soshuha.Release")
    re.key(0, coil, "ease")
    # The X opens into a V, forward-wide, on a lunge over the front foot: the
    # hips rise and go first, the hands arrive last (the wrists snap).
    re.key(2, merge(coil, {"root": {"y": -.72, "z": -.08, "pitch": 18}, "torso": {"pitch": 10},
                           "ra": {"raise": 50, "out": 10, "twist": 30, "elbow": 60}, "la": {"raise": 54, "out": 10, "twist": 30, "elbow": 60}}), "pass")
    fling = s({"root": {"y": -.62, "z": -.3, "pitch": 16, "yaw": 22}, "torso": {"pitch": 2, "yaw": -6},
               "head": {"pitch": -14, "yaw": -14},
               "ra": {"raise": 92, "out": 52, "twist": -16, "elbow": 6, "wrist": -30},
               "la": {"raise": 80, "out": 46, "twist": -16, "elbow": 6, "wrist": -30},
               "rf": {"y": .08, "toe": -26}})
    re.key(4, fling, "impact")
    over = merge(fling, {"root": {"z": -.34, "pitch": 14}, "torso": {"pitch": -4}, "head": {"pitch": -16},
                         "ra": {"raise": 98, "out": 62, "wrist": -36}, "la": {"raise": 86, "out": 58, "wrist": -36}})
    re.key(7, over, "ease")
    held = merge(over, {"root": {"y": -.6, "z": -.32}, "ra": {"raise": 94, "elbow": 12}, "la": {"raise": 82, "elbow": 12}})
    re.key(10, held, "ease")
    re.drag(["hand.R", "hand.L"], 1)
    out.append(re.build(markers={"release": 4 / 60}))

    rc = Shot(arm, N + "Soshuha.Recover")
    rc.key(0, held, "ease")
    # the wires go taut (the fists close, the arms give an inch), then the
    # haul: both elbows driven back past the ribs, the weight sits back
    rc.key(3, merge(held, {"root": {"z": -.3}, "ra": {"raise": 90, "out": 56, "elbow": 20, "wrist": 0}, "la": {"raise": 80, "out": 52, "elbow": 20, "wrist": 0}}), "ease")
    pull = s({"root": {"y": -.7, "z": .2, "pitch": 0, "yaw": 30}, "torso": {"pitch": -6, "yaw": -14},
              "head": {"pitch": -6, "yaw": -16},
              "ra": {"raise": -24, "out": 22, "twist": 10, "elbow": 104},
              "la": {"raise": -18, "out": 22, "twist": 10, "elbow": 104},
              "rf": {"y": 0, "toe": 0}, "lf": {"toe": 16}})
    rc.key(7, pull, "impact")
    rc.key(10, merge(pull, {"root": {"y": -.66, "z": .12}, "torso": {"pitch": 0}, "ra": {"raise": -6}, "la": {"raise": 0}, "lf": {"toe": 4}}), "ease")
    # the second tug, shorter (the blades come round behind him)
    rc.key(12, merge(pull, {"root": {"z": .18}, "ra": {"raise": -20}, "la": {"raise": -14}, "lf": {"toe": 10}}), "impact")
    rc.key(18, s(), "ease")
    rc.drag(["neck"], 1).drag(["spine"], 1)
    out.append(rc.build())
    return out


# ========================================================= WindmillBlades
def windmill(arm):
    out = []
    ch = Shot(arm, N + "WindmillBlades.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.54}, "head": {"pitch": -2}})
    last = weave(ch, 0, (2, 3), base, beat=5)
    # the right hand goes back to the pouch, the hips start to turn away
    draw = s({"root": {"y": -.64, "z": .08, "pitch": 8, "yaw": 50}, "torso": {"pitch": 4, "yaw": 0},
              "head": {"pitch": -6, "yaw": -40},
              "ra": {"raise": -36, "out": 24, "twist": -20, "elbow": 60, "wrist": 20},
              "la": {"raise": 66, "out": 24, "twist": 0, "elbow": 40},
              "rf": {"yaw": 50}, "lf": {"yaw": 6}})
    ch.key(last + 5, draw, "pass")
    # side-on, the weight back on the loaded rear leg, the left arm aiming at
    # him, three blades fanned in the right hand cocked by the ear
    coil = s({"root": {"y": -.82, "z": .26, "pitch": 4, "yaw": 78, "roll": 8}, "torso": {"pitch": 0, "yaw": 14},
              "head": {"pitch": -6, "yaw": -88},
              "ra": {"raise": 40, "out": 76, "twist": -20, "elbow": 104, "wrist": 40},
              "la": {"raise": 14, "out": 80, "twist": 0, "elbow": 8, "wrist": -10},
              "rf": {"yaw": 68}, "lf": {"yaw": 24}})
    ch.key(last + 11, coil, "ease")
    ch.key(last + 13, merge(coil, {"root": {"y": -.84}, "ra": {"out": 80, "wrist": 44}}), "ease")
    ch.drag(["neck"], 1).drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 13) / 60}))
    coil = merge(coil, {"root": {"y": -.84}, "ra": {"out": 80, "wrist": 44}})

    re = Shot(arm, N + "WindmillBlades.Release")
    re.key(0, coil, "ease")
    # the hips lead, the arm stays back (it is the last link); the front foot
    # is already stepping
    re.key(2, merge(coil, {"root": {"yaw": 46, "z": .08, "roll": 2}, "torso": {"yaw": 24}, "head": {"yaw": -62},
                           "ra": {"out": 84}, "lf": {"y": .2, "z": -.96}}), "pass")
    throw = s({"root": {"y": -.66, "z": -.34, "pitch": 18, "yaw": -12, "roll": -4}, "torso": {"pitch": 10, "yaw": -30},
               "head": {"pitch": -12, "yaw": 22},
               "ra": {"raise": 86, "out": 14, "twist": -30, "elbow": 6, "wrist": -34},
               "la": {"raise": 26, "out": 44, "twist": 0, "elbow": 90},
               "rf": {"y": .1, "toe": -36, "yaw": 14}, "lf": {"z": -1.16, "yaw": -10}})
    re.key(4, throw, "impact")
    follow = merge(throw, {"root": {"yaw": -26}, "torso": {"yaw": -42}, "head": {"yaw": 30},
                           "ra": {"raise": 60, "out": -36, "twist": -10, "elbow": 24, "wrist": -10}})
    re.key(7, follow, "ease")
    rest = merge(follow, {"root": {"y": -.62}, "ra": {"raise": 62}})
    re.key(11, rest, "ease")
    re.drag(["hand.R"], 1)
    out.append(re.build(markers={"release": 4 / 60}))

    rc = Shot(arm, N + "WindmillBlades.Recover")
    rc.key(0, rest, "ease")
    # the left hand takes the line out in front, the right fist yanks it taut
    # back to the hip: the blades turn on it
    yank = s({"root": {"y": -.7, "z": .08, "pitch": 10, "yaw": 32}, "torso": {"pitch": 4, "yaw": -20},
              "head": {"pitch": -8, "yaw": -14},
              "ra": {"raise": -26, "out": 26, "twist": -10, "elbow": 96},
              "la": {"raise": 76, "out": 8, "twist": -10, "elbow": 22, "wrist": -14},
              "rf": {"y": 0, "toe": 0}, "lf": {"z": -1.16}})
    rc.key(5, yank, "impact")
    rc.key(9, merge(yank, {"root": {"y": -.72}, "ra": {"raise": -30}, "la": {"raise": 78}}), "ease")
    rc.key(16, s({"lf": {"z": -1.16}}), "ease")
    rc.drag(["neck"], 1)
    out.append(rc.build())
    return out


# ======================================================= SharinganCounter
READ = {"root": {"y": -.8, "z": .14, "pitch": 6, "yaw": 26}, "torso": {"pitch": 10, "yaw": -10},
        "head": {"pitch": -14, "yaw": -14, "roll": -4},
        "la": {"raise": 80, "out": 10, "twist": -30, "elbow": 36, "wrist": -20},
        "ra": {"raise": 64, "out": -24, "twist": 30, "elbow": 120},
        "lf": {"toe": -10}}


def counter(arm):
    out = []
    ch = Shot(arm, N + "SharinganCounter.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.56}, "head": {"pitch": -2}})
    last = weave(ch, 0, (3, 4), base, beat=3)
    out.append(ch.build(markers={"release": last / 60}))

    pose = merge(base, {"root": {"y": -.68}})
    sealed = merge(pose, seal(4, pose))
    read = s(READ)
    re = Shot(arm, N + "SharinganCounter.Release")
    re.key(0, sealed, "ease")
    re.key(3, merge(read, {"root": {"y": -.84}}), "impact")
    re.key(8, read, "ease")
    re.drag(["neck"], 1)
    out.append(re.build(markers={"release": 3 / 60}))

    rc = Shot(arm, N + "SharinganCounter.Recover")
    rc.key(0, read, "ease")
    rc.key(5, merge(read, {"root": {"y": -.84, "z": .16}, "head": {"roll": -2, "yaw": -12}, "la": {"raise": 82}}), "ease")
    rc.key(9, merge(read, {"root": {"y": -.78}}), "ease")
    rc.key(14, s(), "ease")
    out.append(rc.build())
    return out


# ========================================================== SharinganCopy
EYE_R = {"raise": 85.5, "out": 4.2, "twist": 56.9, "elbow": 89.2, "wrist": 0}


def copy(arm):
    out = []
    ch = Shot(arm, N + "SharinganCopy.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.54}, "head": {"pitch": 0}})
    last = weave(ch, 0, (4, 1), base, beat=4)
    focus = s({"root": {"y": -.66, "z": .06, "pitch": 6, "yaw": 34}, "torso": {"pitch": 4, "yaw": -18},
               "head": {"pitch": 10, "yaw": -14},
               "ra": EYE_R, "la": {"raise": 44, "out": -20, "twist": 40, "elbow": 100, "wrist": 10}})
    ch.key(last + 5, focus, "ease")
    gather = merge(focus, {"root": {"y": -.72, "z": .18, "pitch": 2}, "head": {"pitch": -12},
                           "la": {"raise": -10, "out": 22, "twist": -60, "elbow": 100, "wrist": -20}})
    ch.key(last + 10, gather, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 10) / 60}))

    re = Shot(arm, N + "SharinganCopy.Release")
    re.key(0, gather, "ease")
    cast = s({"root": {"y": -.62, "z": -.34, "pitch": 14, "yaw": 22}, "torso": {"pitch": 8, "yaw": -6},
              "head": {"pitch": -10, "yaw": -14},
              "la": {"raise": 92, "out": 0, "twist": -72, "elbow": 4, "wrist": -62},
              "ra": EYE_R, "rf": {"y": .08, "toe": -24}})
    re.key(3, cast, "impact")
    re.key(6, merge(cast, {"root": {"z": -.38}, "la": {"raise": 94, "elbow": 0}}), "ease")
    re.key(9, merge(cast, {"root": {"z": -.36}}), "ease")
    out.append(re.build(markers={"release": 3 / 60}))

    rc = Shot(arm, N + "SharinganCopy.Recover")
    rc.key(0, merge(cast, {"root": {"z": -.36}}), "ease")
    rc.key(7, s({"root": {"y": -.58, "z": -.16}, "la": {"raise": 70, "elbow": 50},
                 "ra": {"raise": 70, "out": -16, "twist": 30, "elbow": 110}}), "pass")
    rc.key(15, s(), "ease")
    rc.drag(["neck"], 1)
    out.append(rc.build())
    return out


# ================================================================ strikes
def dash_attack(arm):
    """Out of the run (DashAttack .07 / .15 / .27): the flying knee."""
    sh = Shot(arm, N + "DashAttack")
    run = s({"root": {"y": -.66, "z": -.1, "pitch": 26, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0},
             "head": {"pitch": -28, "yaw": 0},
             "la": {"raise": 40, "out": 10, "twist": 0, "elbow": 90}, "ra": {"raise": -40, "out": 14, "twist": 0, "elbow": 70},
             "lf": {"x": -.04, "z": -.9, "yaw": 0}, "rf": {"x": .04, "z": .6, "y": .3, "toe": -40, "yaw": 0}})
    sh.key(0, run, "ease")
    take = merge(run, {"travel": {"z": -.5}, "root": {"y": -.42, "z": -.2, "pitch": 8, "yaw": 6}, "torso": {"pitch": 4},
                       "head": {"pitch": -14},
                       "rf": {"x": .1, "z": -.6, "y": 1.1, "toe": -40, "knee": 10},
                       "lf": {"y": .06, "toe": -44},
                       "la": {"raise": 90, "elbow": 80}, "ra": {"raise": -50, "elbow": 40}})
    sh.key(2, take, "launch")
    hit = s({"travel": {"z": -1.2}, "root": {"y": .1, "z": -.3, "pitch": -12, "yaw": 10}, "torso": {"pitch": 6, "yaw": -4},
             "head": {"pitch": -4, "yaw": -6},
             "rf": {"x": .1, "z": -2.0, "y": 1.75, "toe": -40, "knee": 10, "yaw": 0},
             "lf": {"x": -.1, "z": -.7, "y": .9, "toe": -50, "yaw": 0},
             "la": {"raise": 124, "out": 8, "twist": 0, "elbow": 76}, "ra": {"raise": -54, "out": 22, "twist": 0, "elbow": 30}})
    sh.key(4, hit, "impact")
    sh.key(8, merge(hit, {"travel": {"z": -1.9}, "root": {"y": .06, "pitch": -16}, "rf": {"z": -2.8, "y": 1.8},
                          "lf": {"z": -1.6, "y": .9}}), "ease")
    T = -2.7
    land = s({"travel": {"z": T}, "root": {"y": -.86, "z": -.2, "pitch": 20, "yaw": 20}, "torso": {"pitch": 14, "yaw": -10},
              "head": {"pitch": -18, "yaw": -10},
              "lf": {"z": LF["z"] + T, "yaw": -6}, "rf": {"x": .2, "z": T - .2, "y": .9, "toe": -30, "knee": 10, "yaw": 20},
              "la": {"raise": 70, "out": 30, "elbow": 60}, "ra": {"raise": 30, "out": 30, "elbow": 80}})
    sh.key(13, land, "impact")
    sh.key(18, merge(land, {"root": {"y": -.66, "yaw": 28}, "rf": {"x": .26, "z": RF["z"] + T, "y": 0, "toe": 0, "knee": 0, "yaw": 38}}), "impact")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": .07, "recover": .22})


def light4(arm):
    """The string's middle hit (L1 jab, L2 cross, L4, L3 roundhouse):
    the lead hook to the body (.09 / .12 / .28)."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.72, "z": -.14, "pitch": 16, "yaw": 16, "roll": -6}, "torso": {"pitch": 12, "yaw": -26},
              "head": {"pitch": -16, "yaw": 0},
              "la": {"raise": 40, "out": 46, "twist": 20, "elbow": 96},
              "ra": {"raise": 62, "out": -20, "twist": 26, "elbow": 124},
              "lf": {"y": .12, "z": -.9}})
    sh.key(3, load, "ease")
    T = -.3
    hit = s({"travel": {"z": T}, "root": {"y": -.8, "z": -.3, "pitch": 18, "yaw": 46, "roll": 4}, "torso": {"pitch": 14, "yaw": 8},
             "head": {"pitch": -10, "yaw": -40},
             "la": {"raise": 70, "out": 30, "twist": 70, "elbow": 92},
             "ra": {"raise": 64, "out": -24, "twist": 30, "elbow": 128},
             "lf": {"z": LF["z"] + T, "yaw": 30}, "rf": {"y": .1, "toe": -30}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"yaw": 50}, "torso": {"yaw": 14}, "la": {"out": 20}}), "ease")
    sh.key(13, merge(hit, {"root": {"y": -.66, "z": -.2, "yaw": 34, "roll": 0}, "torso": {"yaw": -6},
                           "la": {"raise": 62, "out": 10, "twist": 20, "elbow": 70},
                           "rf": {"z": RF["z"] + T + .1, "y": .14, "toe": -12}}), "pass")
    sh.key(18, at(T, {"root": {"y": -.56}}), "ease")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 13 / 60})


def author(arm):
    acts = soshuha(arm)
    acts += windmill(arm)
    acts += counter(arm)
    acts += copy(arm)
    acts.append(dash_attack(arm))
    acts.append(light4(arm))
    return acts
