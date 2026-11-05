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


def act(arm, prefix, keys, active, recovery=None, drags=(), marker=None, tail=6):
    """One continuous act after the channel, split the way the game plays it.

    The game shows `<prefix>.Release` only while the server is in
    TechniqueActive (spec.Active seconds: Combat sets the state for exactly
    that long), then starts `<prefix>.Recover` from ITS frame 0 (spec.Recovery
    seconds), with a 0.1 s inertial blend at each switch. So a Release whose
    blow lands after Active is never seen, and a Recover that starts from the
    Release's END pose skips the follow-through. Here the act is authored once,
    as one timeline from the channel's last pose (frame 0); a key must sit on
    the Active frame: the Release is the timeline up to it (+ `tail` frames of
    the same motion, for a late state change) and the Recover is the timeline
    from it on - the two clips meet on the same pose and the same velocity (a
    key passed through there leaves the Recover at speed, "launch")."""
    fa = round(active * 60)
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    if fa not in frames:
        raise ValueError("%s: no key on the Active frame %d (keys %s)" % (prefix, fa, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    # (the Release ends on the key nearest Active + `tail`: ~ Active + .1 s)
    end = min((f for f in frames if f > fa), key=lambda f: abs(f - fa - tail), default=fa)
    re = Shot(arm, prefix + ".Release")
    rc = Shot(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > fa:
            rc.key(f - fa, p, sp)
    for bones, n in drags:
        re.drag(bones, n)
        rc.drag(bones, n)
    if recovery is not None and abs((frames[-1] - fa) - recovery * 60) > 3:
        print("WARN %s.Recover %d frames for a %.2f s recovery" % (prefix, frames[-1] - fa, recovery))
    return [re.build(markers={"release": (fa if marker is None else marker) / 60}), rc.build()]


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

    # The throw (Active .04: the shuriken leave as the state opens, so the X
    # snaps open in two frames): it opens into a V, forward-wide, on a lunge
    # over the front foot; the hands arrive a frame after the arms (the
    # wrists snap). The Recover carries the follow-through - the arms keep
    # opening - then the wires go taut and he hauls them: both elbows driven
    # back past the ribs, the weight sitting back against them.
    fling = s({"root": {"y": -.62, "z": -.3, "pitch": 16, "yaw": 22}, "torso": {"pitch": 2, "yaw": -6},
               "head": {"pitch": -14, "yaw": -14},
               "ra": {"raise": 104, "out": 54, "twist": -16, "elbow": 6, "wrist": -30},
               "la": {"raise": 70, "out": 48, "twist": -16, "elbow": 6, "wrist": -30},
               "rf": {"y": .08, "toe": -26}})
    over = merge(fling, {"root": {"z": -.34, "pitch": 14}, "torso": {"pitch": -4}, "head": {"pitch": -16},
                         "ra": {"raise": 110, "out": 64, "wrist": -36}, "la": {"raise": 74, "out": 60, "wrist": -36}})
    taut = merge(over, {"root": {"y": -.6, "z": -.3}, "ra": {"raise": 100, "out": 58, "elbow": 20, "wrist": 0},
                        "la": {"raise": 72, "out": 54, "elbow": 20, "wrist": 0}})
    pull = s({"root": {"y": -.7, "z": .2, "pitch": 0, "yaw": 30}, "torso": {"pitch": -6, "yaw": -14},
              "head": {"pitch": -6, "yaw": -16},
              "ra": {"raise": -24, "out": 22, "twist": 10, "elbow": 104},
              "la": {"raise": -18, "out": 22, "twist": 10, "elbow": 104},
              "rf": {"y": 0, "toe": 0}, "lf": {"toe": 16}})
    give = merge(pull, {"root": {"y": -.64, "z": .12}, "torso": {"pitch": -2}, "ra": {"raise": -6, "elbow": 96}, "la": {"raise": 0, "elbow": 96}, "lf": {"toe": 4}})
    out += act(arm, N + "Soshuha", [(0, coil, "ease"), (2, fling, "impact"), (5, over, "ease"), (8, taut, "ease"),
                                    (11, pull, "impact"), (13, give, "ease"), (17, s(), "ease")],
               .04, .24, drags=[(["hand.R", "hand.L"], 1), (["neck"], 1)])
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

    # The throw lands on the Active frame (.06): the hips lead, the arm stays
    # back (it is the last link) while the front foot steps in, then the arm
    # whips the blades flat across and follows through across the body (the
    # Recover's opening). Then the left hand takes the line out in front and
    # the right fist yanks it taut back to the hip - the yank steps him back
    # onto his stance (a jutsu does not travel: the game keeps the body put).
    hips = merge(coil, {"root": {"yaw": 46, "z": .08, "roll": 2}, "torso": {"yaw": 24}, "head": {"yaw": -62},
                        "ra": {"out": 84}, "lf": {"y": .2, "z": -.96}})
    throw = s({"root": {"y": -.66, "z": -.34, "pitch": 18, "yaw": -12, "roll": -4}, "torso": {"pitch": 10, "yaw": -30},
               "head": {"pitch": -12, "yaw": 22},
               "ra": {"raise": 86, "out": 14, "twist": -30, "elbow": 6, "wrist": -34},
               "la": {"raise": 26, "out": 44, "twist": 0, "elbow": 90},
               "rf": {"y": .1, "toe": -36, "yaw": 14}, "lf": {"z": -1.16, "yaw": -10}})
    follow = merge(throw, {"root": {"yaw": -26}, "torso": {"yaw": -42}, "head": {"yaw": 30},
                           "ra": {"raise": 60, "out": -36, "twist": -10, "elbow": 24, "wrist": -10}})
    rest = merge(follow, {"root": {"y": -.62, "z": -.28}, "ra": {"raise": 62}})
    lift = merge(rest, {"root": {"y": -.6, "z": -.1, "yaw": 0}, "torso": {"yaw": -28},
                        "la": {"raise": 60, "out": 20, "elbow": 40},
                        "lf": {"y": .22, "z": -.86, "yaw": -8}, "rf": {"y": 0, "toe": 0}})
    yank = s({"root": {"y": -.72, "z": .1, "pitch": 10, "yaw": 32}, "torso": {"pitch": 4, "yaw": -20},
              "head": {"pitch": -8, "yaw": -14},
              "ra": {"raise": -26, "out": 26, "twist": -10, "elbow": 96},
              "la": {"raise": 76, "out": 8, "twist": -10, "elbow": 22, "wrist": -14}})
    taut = merge(yank, {"root": {"y": -.72, "z": .06}, "ra": {"raise": -30}, "la": {"raise": 78}})
    out += act(arm, N + "WindmillBlades", [(0, coil, "ease"), (2, hips, "pass"), (4, throw, "impact"), (7, follow, "ease"),
                                           (10, rest, "ease"), (12, lift, "pass"), (14, yank, "impact"), (17, taut, "ease"),
                                           (21, s(), "ease")],
               .06, .26, drags=[(["hand.R"], 1), (["neck"], 1)])
    return out


# ======================================================= SharinganCounter
# The cat stance: the weight sunk on the rear leg, the front foot drawn in on
# its ball (light: the answer is a kick), side-on; the lead hand open at face
# height on the line of the blow, the rear hand open low across the belly.
READ = {"root": {"y": -.94, "z": .3, "pitch": 4, "yaw": 42}, "torso": {"pitch": 8, "yaw": -16},
        "head": {"pitch": -12, "yaw": -24, "roll": -4},
        "la": {"raise": 96, "out": 8, "twist": -60, "elbow": 30, "wrist": -30},
        "ra": {"raise": 40, "out": -10, "twist": 40, "elbow": 92, "wrist": -10},
        "rf": {"yaw": 48}, "lf": {"z": -.5, "y": .08, "toe": -34, "yaw": 0}}


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
    # The seal parts as the window opens (Active .04): the weight is already
    # going back and the front foot drawing in on the Active frame; the cat
    # stance lands just after (the Recover), the eyes follow the blow, the
    # rear leg loads, then the stance.
    keys = [(0, sealed, "ease"),
            (2, merge(sealed, {"root": {"y": -.76, "z": .12}, "head": {"pitch": -6},
                               "la": {"raise": 70, "out": -6, "twist": -10, "elbow": 70}, "ra": {"raise": 46, "elbow": 100},
                               "lf": {"z": -.64, "y": .16, "toe": -20}}), "pass"),
            (5, merge(read, {"root": {"y": -.98}}), "impact"),
            (8, read, "ease"),
            (10, merge(read, {"root": {"y": -.97, "z": .32}, "head": {"roll": -1, "yaw": -20}, "la": {"raise": 98}}), "ease"),
            # the light front foot lifts back out to its place
            (12, merge(read, {"root": {"y": -.78, "z": .16}, "la": {"raise": 80, "elbow": 50},
                              "lf": {"z": -.66, "y": .2, "toe": -16}}), "pass"),
            (15, s(), "ease")]
    out += act(arm, N + "SharinganCounter", keys, .04, .2, drags=[(["neck"], 1)], marker=2)
    return out


# ========================================================== SharinganCopy
EYE_R = {"raise": 87.5, "out": 18.6, "twist": 40.5, "elbow": 109.7, "wrist": 0}


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

    # The mirrored cast on the Active frame (.06): the hips go in, the open
    # palm is thrown at him, the fingers still at the eye; the palm presses
    # on a beat, then the hand comes back and the fingers leave the eye last.
    cast = s({"root": {"y": -.62, "z": -.34, "pitch": 14, "yaw": 22}, "torso": {"pitch": 8, "yaw": -6},
              "head": {"pitch": -10, "yaw": -14},
              "la": {"raise": 92, "out": 0, "twist": -72, "elbow": 4, "wrist": -62},
              "ra": EYE_R, "rf": {"y": .08, "toe": -24}})
    keys = [(0, gather, "ease"),
            (2, merge(gather, {"root": {"y": -.68, "z": .02, "pitch": 8}, "torso": {"pitch": 6},
                               "la": {"raise": 40, "out": 10, "twist": -50, "elbow": 70, "wrist": -30}}), "pass"),
            (4, cast, "impact"),
            (7, merge(cast, {"root": {"z": -.38}, "la": {"raise": 94, "elbow": 0}}), "ease"),
            (10, merge(cast, {"root": {"z": -.36}}), "ease"),
            (14, s({"root": {"y": -.58, "z": -.16}, "la": {"raise": 70, "elbow": 50},
                    "ra": {"raise": 76, "out": 4, "twist": 34, "elbow": 112}}), "pass"),
            (20, s(), "ease")]
    out += act(arm, N + "SharinganCopy", keys, .06, .26, drags=[(["neck"], 1), (["shoulder.R", "forearm.R", "hand.R"], 1)])
    return out


# ================================================================ strikes
def dash_attack(arm):
    """Out of the run (DashAttack .07 / .15 / .27): the flying knee. The
    left foot drives off, the right knee goes first and the body follows it
    (the bible: « genou haut puis corps suit »), the hips thrust through the
    body at contact, the left arm thrown forward over the face and the right
    swept back; he lands on the left foot, the right set down behind."""
    sh = Shot(arm, N + "DashAttack")
    run = s({"root": {"y": -.66, "z": -.1, "pitch": 26, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0},
             "head": {"pitch": -28, "yaw": 0},
             "la": {"raise": 40, "out": 10, "twist": 0, "elbow": 90}, "ra": {"raise": -40, "out": 14, "twist": 0, "elbow": 70},
             "lf": {"x": -.04, "z": -.9, "yaw": 0}, "rf": {"x": .04, "z": .6, "y": .3, "toe": -40, "yaw": 0}})
    sh.key(0, run, "ease")
    take = merge(run, {"travel": {"z": -.5}, "root": {"y": -.4, "z": -.24, "pitch": 10, "yaw": 6}, "torso": {"pitch": 6},
                       "head": {"pitch": -16},
                       "rf": {"x": .1, "z": -.9, "y": 1.1, "toe": -40, "knee": 4},
                       "lf": {"y": .06, "toe": -44},
                       "la": {"raise": 96, "elbow": 70}, "ra": {"raise": -50, "elbow": 40}})
    sh.key(2, take, "launch")
    hit = s({"travel": {"z": -1.2}, "root": {"y": .14, "z": -.42, "pitch": -10, "yaw": 8}, "torso": {"pitch": 14, "yaw": -4},
             "head": {"pitch": -6, "yaw": -6},
             "rf": {"x": .1, "z": -2.25, "y": 1.45, "toe": -46, "knee": 0, "yaw": 0},
             "lf": {"x": -.1, "z": -1.15, "y": .65, "toe": -50, "yaw": 0},
             "la": {"raise": 112, "out": 6, "twist": 0, "elbow": 64}, "ra": {"raise": -62, "out": 20, "twist": 0, "elbow": 20}})
    sh.key(4, hit, "impact")
    sh.key(8, merge(hit, {"travel": {"z": -1.9}, "root": {"y": .1, "z": -.46, "pitch": -14}, "rf": {"z": -3.0, "y": 1.5},
                          "lf": {"z": -1.9, "y": .7}}), "ease")
    T = -2.7
    sh.key(11, s({"travel": {"z": -2.3}, "root": {"y": -.24, "z": -.3, "pitch": 6, "yaw": 12}, "torso": {"pitch": 12, "yaw": -6},
                  "head": {"pitch": -14, "yaw": -8},
                  "lf": {"x": -.1, "z": LF["z"] + T + .05, "y": .3, "toe": 10, "yaw": -6},
                  "rf": {"x": .14, "z": -2.9, "y": 1.2, "toe": -40, "knee": 8, "yaw": 10},
                  "la": {"raise": 86, "out": 24, "elbow": 60}, "ra": {"raise": 0, "out": 34, "elbow": 60}}), "pass")
    land = s({"travel": {"z": T}, "root": {"y": -.9, "z": -.36, "pitch": 26, "yaw": 20}, "torso": {"pitch": 16, "yaw": -10},
              "head": {"pitch": -20, "yaw": -10},
              "lf": {"z": LF["z"] + T, "yaw": -6}, "rf": {"x": .2, "z": T - .3, "y": .8, "toe": -30, "knee": 10, "yaw": 20},
              "la": {"raise": 70, "out": 34, "elbow": 56}, "ra": {"raise": 30, "out": 36, "elbow": 76}})
    sh.key(14, land, "impact")
    sh.key(19, merge(land, {"root": {"y": -.7, "z": -.16, "pitch": 14, "yaw": 28}, "torso": {"pitch": 10, "yaw": -12},
                            "rf": {"x": .26, "z": RF["z"] + T, "y": 0, "toe": 0, "knee": 0, "yaw": 38}}), "impact")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": .07, "recover": .22})


def light4(arm):
    """The string's middle hit (L1 jab, L2 cross, L4, L3 roundhouse): the
    lead hook to the body (.09 / .12 / .28). A level change - the knees
    drop, the torso tips toward the lead side, the head slips outside the
    line - the left elbow comes out level and the hips turn it in under the
    ribs; the turn winds the hips the other way for the kick that follows."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.8, "z": -.12, "pitch": 16, "yaw": 12, "roll": -8}, "torso": {"pitch": 12, "yaw": -24, "roll": -4},
              "head": {"pitch": -14, "yaw": 4},
              "la": {"raise": 34, "out": 50, "twist": 30, "elbow": 100},
              "ra": {"raise": 62, "out": -20, "twist": 26, "elbow": 124},
              "lf": {"y": .12, "z": -.92}})
    sh.key(3, load, "ease")
    T = -.3
    hit = s({"travel": {"z": T}, "root": {"y": -.94, "z": -.32, "pitch": 20, "yaw": 50, "roll": -6}, "torso": {"pitch": 14, "yaw": 10, "roll": -4},
             "head": {"pitch": -8, "yaw": -44},
             "la": {"raise": 62, "out": 36, "twist": 76, "elbow": 94},
             "ra": {"raise": 64, "out": -24, "twist": 30, "elbow": 128},
             "lf": {"z": LF["z"] + T, "yaw": 30}, "rf": {"y": .1, "toe": -30, "yaw": 50}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"yaw": 56, "y": -.96}, "torso": {"yaw": 16}, "la": {"out": 24}}), "ease")
    sh.key(13, merge(hit, {"root": {"y": -.72, "z": -.2, "yaw": 34, "roll": 0}, "torso": {"yaw": -8, "roll": 0},
                           "la": {"raise": 62, "out": 10, "twist": 20, "elbow": 70},
                           "rf": {"z": RF["z"] + T + .1, "y": .14, "toe": -12, "yaw": 40}}), "pass")
    sh.key(18, at(T, {"root": {"y": -.56}}), "ease")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 13 / 60})


def chidori_dive(arm):
    """(05/11, B1 lot 3: the signature is verticality) The Chidori out of a
    jump or off a wall: the dive, on the wall dive's timing (.1 / .3 / .32;
    the lunge itself lasts as long as the flight, 0.16-0.5 s). Out of the
    carry (the lightning hand low and back) he coils in the air - knees up,
    the hand drawn behind the hip, the left hand pointing him out - then
    opens head first along the line to him: the lightning arm leading, the
    body behind it in one line, the legs trailing. The floor takes the hand:
    he lands split, the front foot down, the rear knee low, the arm driven
    straight into the ground; then he pulls it out and rises into the stance."""
    sh = Shot(arm, N + "ChidoriDive")
    carry = s({"root": {"y": -.4, "z": 0, "pitch": 14, "yaw": 0, "roll": 0}, "torso": {"pitch": 10, "yaw": 0, "roll": 0},
               "head": {"pitch": -20, "yaw": 0},
               "ra": {"raise": -40, "out": 30, "twist": -20, "elbow": 22, "wrist": -10},
               "la": {"raise": 50, "out": 6, "twist": 0, "elbow": 80},
               "rf": {"x": .1, "z": -.4, "y": .8, "toe": -24, "knee": 8, "yaw": 0},
               "lf": {"x": -.1, "z": .1, "y": .5, "toe": -26, "knee": 0, "yaw": 0}})
    sh.key(0, carry, "ease")
    coil = merge(carry, {"root": {"y": -.62, "pitch": 26, "yaw": 10}, "torso": {"pitch": 18, "yaw": -10}, "head": {"pitch": -34, "yaw": -8},
                         "ra": {"raise": -64, "out": 34, "twist": -30, "elbow": 30, "wrist": -20},
                         "la": {"raise": 96, "out": 0, "twist": 0, "elbow": 6},
                         "rf": {"z": -.8, "y": 1.3, "toe": -30, "knee": 12}, "lf": {"z": -.5, "y": 1.15, "toe": -30, "knee": 10}})
    sh.key(5, coil, "ease")
    # The legs trail up and back along the line (in the air nothing plants them).
    dive = merge(carry, {"root": {"y": -.2, "pitch": 78, "yaw": -6}, "torso": {"pitch": 24, "yaw": 4}, "head": {"pitch": 30, "yaw": 0},
                         "ra": {"raise": 160, "out": -4, "twist": -10, "elbow": 0, "wrist": 10},
                         "la": {"raise": -30, "out": 20, "twist": 0, "elbow": 10},
                         "rf": {"z": 1.9, "y": 1.6, "toe": -60, "knee": 4}, "lf": {"z": 1.5, "y": 1.95, "toe": -50, "knee": 30}})
    sh.key(8, dive, "launch")
    sh.key(15, merge(dive, {"root": {"pitch": 82}, "ra": {"wrist": 16}, "la": {"out": 26}, "lf": {"knee": 36}}), "ease")
    sh.key(21, merge(dive, {"root": {"pitch": 70, "y": -.4}, "ra": {"raise": 150}, "rf": {"z": 1.4, "y": 1.0}, "lf": {"z": 1.0, "y": 1.2}}), "pass")
    land = s({"root": {"y": -1.2, "z": -.1, "pitch": 44, "yaw": 10}, "torso": {"pitch": 24, "yaw": -6}, "head": {"pitch": -10, "yaw": -6},
              "ra": {"raise": 80, "out": 6, "twist": 0, "elbow": 0, "wrist": 30},
              "la": {"raise": 30, "out": 40, "twist": 0, "elbow": 40},
              "lf": {"x": -.12, "z": -.9, "y": 0, "toe": 0, "knee": 0, "yaw": -6},
              "rf": {"x": .2, "z": 1.1, "y": .3, "toe": -30, "knee": 30, "yaw": 30}})
    sh.key(24, land, "impact")
    sh.key(30, merge(land, {"root": {"y": -1.26}, "ra": {"wrist": 36}}), "ease")
    sh.key(36, merge(land, {"root": {"y": -.8, "pitch": 22, "yaw": 20}, "torso": {"pitch": 12},
                            "ra": {"raise": 30, "out": 20, "elbow": 60, "wrist": 0}, "la": {"raise": 56, "out": 10, "elbow": 70},
                            "rf": {"z": .9, "y": .1, "toe": -10, "knee": 10}}), "pass")
    sh.key(43, s(), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 24 / 60})


def author(arm):
    acts = soshuha(arm)
    acts += windmill(arm)
    acts += counter(arm)
    acts += copy(arm)
    acts.append(dash_attack(arm))
    acts.append(light4(arm))
    acts.append(chidori_dive(arm))
    return acts
