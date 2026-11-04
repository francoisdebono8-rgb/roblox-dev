"""Gaara's seal jutsu and his own string hits (04/11, user: the new jutsu had
no animations of their own, « fais-moi de belles animations, applique-toi
bien »).

Authored on his body (gaara_p7.STANCE: upright, arms folded high, feet
close). His bible: he does not fight with his body - the sand moves, he
barely does. Every gesture is a small, exact command of a hand (an arm
unfolds, a palm opens or presses, the fingers close), the head stays level,
the eyes do not leave the opponent, the hips almost never turn, the feet
never move; the weight of the gourd keeps him planted. Each seal is made at
the chin with no sink of the knees (he does not gather himself: the sand
does), and every gesture shows the gathering and the return to the fold.
The hands share the work so no two jutsu look alike:

  ShukakuArm     tiger - snake, the right arm unfolds and rises high out to
                 his right side, clawed (the giant arm grows from that
                 shoulder); the release brings it down to shoulder height
                 and sweeps it flat across the field, right to left, the
                 chest turning with it a little; it carries on across and
                 folds back slowly
  SandSpikes     snake - ram, the right hand drops open, palm to the floor
                 ahead; it presses once, then the palm flips and the hand
                 snaps up: three lines of spikes burst
  Quicksand      ram - rat, the left hand reaches low at the target, palm
                 down, fingers spread, and stirs a slow circle; the release
                 is a heavy press down, the fingers closing, held - the
                 floor gives way under him
  ThirdEye       rat - tiger, two fingers of the right hand raised to his
                 right eye (the left arm folds back); the eye of sand floats
                 up as the fingers press and his chin lifts
  SandClone      the tiger snapped at the chin (a .04 s channel: the ram was
                 shown as it was pressed), then the hands open down by his
                 sides, palms back: the sand pours down over him (the clone
                 that will take the blow), and the arms fold again
  SandHand       heavy: the left arm rises out of the fold, high, the hand
                 open like a claw over him; the fingers close and the fist is
                 pulled down to his hip: the hand of sand slams him into the
                 floor and holds him there; then it opens and folds back
  SandFist       launcher: the right fist set into the left palm at the
                 chest (the sand gathers into a fist), drawn back a hair,
                 then both arms drive straight out: the fist of sand throws
                 him away
  SandLowWave    away route: both palms brought up flat, then pushed down
                 and out low, the knees giving a little: the wave rolls
                 along the floor at his ankles
  Light4         the string's third lash: a backhand - the right hand comes
                 across to his left shoulder and snaps out to the right,
                 back of the hand leading (L1 is a forehand reach inward)

Server timings (Shared/SealJutsu.Sand; Shared/Attacks with his profile):
  ShukakuArm  .3 / .12 / .34    SandSpikes .24 / .06 / .28   Quicksand .4 / .15 / .3
  ThirdEye .2 / .04 / .12       SandClone .04 / .04 / .2 (window .9)
  SandHand .24 / .16 / .48      SandFist (Light3 profile) .342 / .14 / .6
  SandLowWave .16 / .16 / .4    Light4 (Light1 profile) .162 / .12 / .406
The engine stretches a Channel linearly over the server's channel time
(authored length / Channel stays within 1.0-1.3x), plays the Release only
while the server holds TechniqueActive (spec.Active) and then the Recover
from its frame 0: each act is one timeline cut on the Active frame (act()),
so the blow lands inside Active and the Recover goes on from that very pose.
"""
import nd_anim
from nd_shot import Shot, merge, shape
from gaara_p7 import STANCE, FOLD_R, FOLD_L

N = "Sand."
F = 60.0

# ------------------------------------------------------------------ helpers
# Every key is a whole body (Shot merges each key onto the previous one).
ZERO = {"travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0},
        "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}
BASE = merge(ZERO, STANCE)
FR = merge(ZERO["ra"], FOLD_R)
FL = merge(ZERO["la"], FOLD_L)


def s(over=None):
    return merge(BASE, over or {})


# The four seals with the hands really together (rig-solved: the hand blocks
# meet in front of the chin, chest space; the same numbers as
# jutsu_sasuke.SEAL), made at his folded arms' height.
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


def seal_pose(n, i):
    """Seal n made i-th: no sink, no turn; only the chin dips a hair on the
    hands, the eyes stay on him."""
    return s(merge({"root": {"y": BASE["root"]["y"] - .01 * i}, "torso": {"pitch": -1},
                    "head": {"pitch": BASE["head"]["pitch"] + 2 + i, "yaw": -3}}, SEAL[n]))


def weave(sh, signs, beat, start=0):
    f = start
    for i, n in enumerate(signs, 1):
        f = start + beat * i
        sh.key(f, seal_pose(n, i), "impact")
    return f


class Take(Shot):
    """A Shot whose overlap (drag) shifts the inner keys only: the dragged
    parts still arrive on the last key, so the clip that follows starts
    exactly where this one ends (Channel -> Release -> Recover)."""

    def build(self, markers=None, loop=False, meta=None):
        drags, self.drags = self.drags, []
        act = Shot.build(self, markers, loop, meta)
        self.drags = drags
        if not drags:
            return act
        spacing = {f: sp for f, _, sp in self.keys}
        last = max(spacing)
        for bones, frames in drags:
            for fc in nd_anim.fcurves(act):
                if not any('"%s"' % b in fc.data_path for b in bones):
                    continue
                pts = sorted(fc.keyframe_points, key=lambda k: k.co.x)
                moved = {}
                nxt = pts[-1].co.x
                for kp in reversed(pts[1:-1]):
                    x0 = kp.co.x
                    x1 = min(x0 + frames, nxt - 1)
                    d = x1 - x0
                    kp.co.x += d
                    kp.handle_left.x += d
                    kp.handle_right.x += d
                    moved[x1] = spacing.get(int(round(x0)), "ease")
                    nxt = x1
                local = {pts[0].co.x: spacing.get(int(round(pts[0].co.x)), "ease"), pts[-1].co.x: spacing.get(int(round(pts[-1].co.x)), "ease")}
                local.update(moved)
                shape(fc, local, last, loop)
        return act


def act(arm, prefix, keys, active, recovery, drags=(), tail=6):
    """One continuous act after the channel, split the way the game plays it
    (as jutsu_sasuke.act): the server holds TechniqueActive for exactly
    spec.Active seconds and the client shows `.Release` only then, then
    starts `.Recover` from ITS frame 0 (0.1 s blend). The act is authored
    once, from the channel's last pose (frame 0), with a key on the Active
    frame: the Release is the timeline up to it (+ about `tail` frames of the
    same motion, for a late state change), the Recover the timeline from it
    on - the two meet on the same pose, and the blow is seen."""
    fa = int(round(active * F))
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    if fa not in frames:
        raise ValueError("%s: no key on the Active frame %d (keys %s)" % (prefix, fa, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    later = [f for f in frames if f > fa]
    end = min(later, key=lambda f: abs(f - fa - tail)) if later else fa
    re, rc = Take(arm, prefix + ".Release"), Take(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > fa:
            rc.key(f - fa, p, sp)
    # (the overlap only on the Recover: on the Release the Active key is an
    # inner key, a dragged part would still be on its way there and the
    # Recover, which starts exactly on it, would jump)
    for bones, n in drags:
        rc.drag(bones, n)
    if abs((frames[-1] - fa) - recovery * F) > 3:
        print("WARN %s.Recover %d frames for a %.2f s recovery" % (prefix, frames[-1] - fa, recovery))
    return [re.build(markers={"release": fa / F}), rc.build()]


# ================================================================ ShukakuArm
def shukaku_arm(arm):
    out = []
    ch = Take(arm, N + "ShukakuArm.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (1, 2), 5)                                   # 5, 10
    # the right hand leaves the seal, the elbow lifting out first, the left
    # forearm back across the chest ...
    ch.key(last + 4, s({"ra": {"raise": 66, "out": 70, "twist": 0, "elbow": 100, "wrist": 0},
                        "torso": {"yaw": 3, "roll": -2}, "head": {"yaw": -6}}), "pass")
    # ... and the arm opens high out to his right side, clawed
    raised = s({"root": {"yaw": 10}, "torso": {"pitch": -3, "yaw": 12, "roll": -5},
                "head": {"pitch": 4, "yaw": -16, "roll": 3},
                "ra": {"raise": 36, "out": 148, "twist": -30, "elbow": 22, "wrist": -38}})
    ch.key(last + 8, raised, "ease")                              # 18
    ch.drag(["neck"], 2)
    ch.drag(["hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 8) / F}))

    # the act (Active .12: the sweep is half way across on frame 7; recovery .34)
    # it comes down to shoulder height on his right (the arm of sand landing
    # on the field) ...
    right = s({"root": {"yaw": 10}, "torso": {"pitch": 0, "yaw": 14, "roll": -2},
               "head": {"pitch": 6, "yaw": -16},
               "ra": {"raise": 96, "out": 84, "twist": -20, "elbow": 12, "wrist": -28}})
    # ... and sweeps flat across, right to left, the chest turning with it
    mid = s({"root": {"yaw": 5}, "torso": {"yaw": 0, "roll": 0}, "head": {"pitch": 6, "yaw": -6},
             "ra": {"raise": 98, "out": 4, "twist": -10, "elbow": 8, "wrist": -14}})
    left = s({"root": {"yaw": 0}, "torso": {"yaw": -16, "roll": 2}, "head": {"pitch": 6, "yaw": 2},
              "ra": {"raise": 96, "out": -48, "twist": 0, "elbow": 12, "wrist": -6}})
    # it carries on across, slowing, then folds back (no hurry)
    carry = merge(left, {"torso": {"yaw": -20}, "ra": {"raise": 92, "out": -62, "elbow": 22, "wrist": 0}})
    fold = s({"torso": {"yaw": -6}, "ra": {"raise": 72, "out": -36, "twist": 30, "elbow": 86, "wrist": 0}})
    out += act(arm, N + "ShukakuArm", [(0, raised, "ease"), (3, right, "impact"), (7, mid, "pass"), (12, left, "ease"),
                                       (18, carry, "ease"), (22, fold, "pass"), (27, s(), "ease")],
               .12, .34, drags=((["neck"], 2), (["hand.R"], 1)))
    return out


# ================================================================ SandSpikes
def sand_spikes(arm):
    out = []
    ch = Take(arm, N + "SandSpikes.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (2, 3), 4)                                   # 4, 8
    # the right hand drops open, palm to the floor ahead of him; the left
    # arm back to the fold
    ch.key(last + 3, s({"head": {"pitch": 8}, "ra": {"raise": 50, "out": 6, "twist": 10, "elbow": 72, "wrist": 10}}), "pass")
    ready = s({"head": {"pitch": 10, "yaw": -2}, "torso": {"roll": 2},
               "ra": {"raise": 36, "out": 16, "twist": -10, "elbow": 8, "wrist": 26}})
    ch.key(last + 6, ready, "ease")                               # 14
    ch.drag(["neck"], 2)
    ch.drag(["hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 6) / F}))

    # the act (Active .06: the hand snaps up on frame 4; recovery .28)
    # one press ...
    press = merge(ready, {"root": {"y": BASE["root"]["y"] - .03}, "torso": {"roll": 3}, "ra": {"raise": 28, "wrist": 40}})
    # ... and the palm flips, the hand snapped up: the spikes burst
    snap = s({"root": {"y": BASE["root"]["y"] - .02}, "head": {"pitch": 4, "yaw": -2}, "torso": {"roll": 0},
              "ra": {"raise": 62, "out": 18, "twist": -40, "elbow": 26, "wrist": -50}})
    held = merge(snap, {"ra": {"raise": 66, "wrist": -56}})
    fold = s({"ra": {"raise": 52, "out": -14, "twist": 24, "elbow": 80, "wrist": 0}})
    out += act(arm, N + "SandSpikes", [(0, ready, "ease"), (2, press, "impact"), (4, snap, "impact"), (10, held, "ease"),
                                       (14, fold, "pass"), (21, s(), "ease")],
               .06, .28, drags=((["neck"], 1),))
    return out


# ================================================================= Quicksand
def quicksand(arm):
    out = []
    ch = Take(arm, N + "Quicksand.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (3, 4), 5)                                   # 5, 10
    # the left hand reaches low toward him, palm down, fingers spread ...
    reach = s({"head": {"pitch": 10, "yaw": -2}, "torso": {"roll": -1},
               "la": {"raise": 50, "out": 10, "twist": -20, "elbow": 12, "wrist": -14}})
    ch.key(last + 5, reach, "ease")                               # 15
    # ... and stirs a slow circle over the place
    ch.key(last + 9, merge(reach, {"torso": {"yaw": 3}, "la": {"raise": 44, "out": -6, "wrist": -8}}), "pass")
    stir = merge(reach, {"torso": {"yaw": -2}, "la": {"raise": 48, "out": 14, "wrist": -18}})
    ch.key(last + 14, stir, "ease")                               # 24
    ch.drag(["neck"], 2)
    ch.drag(["hand.L"], 2)
    out.append(ch.build(markers={"release": (last + 14) / F}))

    # the act (Active .15: frame 9; recovery .3)
    # the press: slow and heavy, the palm flat, the fingers closing, the
    # shoulders give a hair; held while the floor gives way
    press = s({"root": {"y": BASE["root"]["y"] - .05}, "torso": {"pitch": 3, "yaw": -1}, "head": {"pitch": 12, "yaw": -4},
               "la": {"raise": 30, "out": 8, "twist": -20, "elbow": 6, "wrist": 24}})
    deeper = merge(press, {"root": {"y": BASE["root"]["y"] - .06}, "la": {"raise": 27, "wrist": 30}})
    held = merge(deeper, {"la": {"raise": 26}})
    rise = merge(held, {"root": {"y": BASE["root"]["y"] - .03}, "la": {"raise": 36, "elbow": 30, "wrist": 0}})
    out += act(arm, N + "Quicksand", [(0, stir, "ease"), (6, press, "ease"), (9, deeper, "ease"), (15, held, "ease"),
                                      (20, rise, "ease"), (27, s(), "ease")],
               .15, .3, drags=((["hand.L"], 1), (["neck"], 2)))
    return out


# ================================================================== ThirdEye
# Two fingers raised to the right eye (rig-solved: the fingertips just in
# front of the eye, the fingers up, the hand clear of the face, the elbow
# out in front of the right shoulder, the forearm standing up to the eye).
TWO_FINGERS = {"raise": 71.2, "out": -26.9, "twist": 35, "elbow": 91.2, "wrist": 5}


def third_eye(arm):
    out = []
    ch = Take(arm, N + "ThirdEye.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (4, 1), 4)                                   # 4, 8
    # the left arm folds back, two fingers of the right raised to the eye
    eye = s({"head": {"pitch": 0, "yaw": -4, "roll": -3}, "torso": {"roll": -1}, "ra": TWO_FINGERS})
    ch.key(last + 4, eye, "ease")                                 # 12
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 4) / F}))

    # the act (Active .04: frame 2; recovery .12)
    # focus: the fingers press to the eye, the chin lifts, he stands taller
    focus = s({"root": {"y": BASE["root"]["y"] + .03}, "head": {"pitch": -6, "yaw": -4, "roll": -2},
               "ra": merge(TWO_FINGERS, {"raise": 76, "elbow": 94, "wrist": 8})})
    lift = merge(focus, {"head": {"pitch": -9}, "ra": {"raise": 77}})
    out += act(arm, N + "ThirdEye", [(0, eye, "ease"), (2, focus, "impact"), (5, lift, "ease"), (9, s(), "ease")],
               .04, .12, drags=((["neck"], 1),))
    return out


# ================================================================= SandClone
def sand_clone(arm):
    out = []
    ch = Take(arm, N + "SandClone.Channel")
    ch.key(0, s(), "ease")
    # (a .04 s channel: the ram was already shown as it was pressed; the
    # tiger is snapped in 3 frames, played 1.25x)
    tiger = seal_pose(1, 2)
    ch.key(3, tiger, "impact")
    out.append(ch.build(markers={"release": 3 / F}))
    # the act (Active .04: frame 2; recovery .2, the stance's window .9 s)
    # the hands open down by his sides, palms back: the sand pours over him
    pour = s({"root": {"y": BASE["root"]["y"] - .04}, "head": {"pitch": 12, "yaw": -4},
              "ra": {"raise": 10, "out": 24, "twist": -40, "elbow": 12, "wrist": -26},
              "la": {"raise": 10, "out": 24, "twist": -40, "elbow": 12, "wrist": -26}})
    held = merge(pour, {"root": {"y": BASE["root"]["y"] - .05}, "ra": {"out": 28}, "la": {"out": 28}})
    out += act(arm, N + "SandClone", [(0, tiger, "ease"), (2, pour, "impact"), (7, held, "ease"),
                                      (10, merge(held, {"head": {"pitch": 8}}), "ease"), (14, s(), "ease")],
               .04, .2, drags=((["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)))
    return out


# ================================================================= strikes
def sand_hand(arm):
    """Heavy (.24 / .16 / .48): the left arm rises out of the fold, high over
    him, the hand open like a claw; the fingers close and the fist is pulled
    down to his hip - the hand of sand slams him into the floor and holds
    him; then the fist opens and the arm folds back."""
    sh = Take(arm, N + "SandHand")
    sh.key(0, s(), "ease")
    sh.key(5, s({"la": {"raise": 100, "out": 20, "twist": -10, "elbow": 90, "wrist": -10}, "head": {"pitch": 4}}), "pass")
    claw = s({"torso": {"pitch": -3, "roll": 2}, "head": {"pitch": 2, "yaw": -4},
              "la": {"raise": 162, "out": 14, "twist": -20, "elbow": 16, "wrist": -44}})
    sh.key(10, claw, "ease")
    # the seize: the fingers close
    sh.key(12, merge(claw, {"la": {"raise": 156, "elbow": 26, "wrist": 30}}), "ease")
    slam = s({"root": {"y": BASE["root"]["y"] - .06}, "torso": {"pitch": 6, "roll": -1}, "head": {"pitch": 12, "yaw": -4},
              "la": {"raise": 30, "out": 14, "twist": 0, "elbow": 40, "wrist": 30}})
    sh.key(14, slam, "impact")
    sh.key(19, merge(slam, {"root": {"y": BASE["root"]["y"] - .07}, "la": {"raise": 26}}), "ease")
    sh.key(24, merge(slam, {"root": {"y": BASE["root"]["y"] - .07}, "la": {"raise": 27}}), "ease")
    # the hand opens, rises, and folds
    sh.key(36, s({"root": {"y": BASE["root"]["y"] - .03}, "head": {"pitch": 8},
                  "la": {"raise": 46, "out": -14, "twist": 20, "elbow": 84, "wrist": -10}}), "pass")
    sh.key(53, s(), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 14 / F, "recover": 24 / F})


def sand_fist(arm):
    """Launcher (.342 / .14 / .6): the right fist set into the left palm at
    the chest - the sand gathers into one great fist - drawn back a hair,
    then both arms drive straight out together; held while it carries him,
    then they part and fold."""
    sh = Take(arm, N + "SandFist")
    sh.key(0, s(), "ease")
    gather = s({"torso": {"pitch": -2, "yaw": 6}, "head": {"pitch": 6, "yaw": -8},
                "ra": {"raise": 44, "out": -44, "twist": 30, "elbow": 104, "wrist": 10},
                "la": {"raise": 46, "out": -40, "twist": 30, "elbow": 96, "wrist": -24}})
    sh.key(10, gather, "ease")
    sh.key(16, merge(gather, {"root": {"y": BASE["root"]["y"] - .04, "z": .04}, "torso": {"pitch": -4, "yaw": 9},
                              "ra": {"raise": 38, "elbow": 112}, "la": {"raise": 40, "elbow": 104}}), "ease")
    drive = s({"root": {"y": BASE["root"]["y"] - .04, "z": -.06}, "torso": {"pitch": 6, "yaw": -4}, "head": {"pitch": 4, "yaw": -2},
               "ra": {"raise": 90, "out": -12, "twist": 0, "elbow": 6, "wrist": 0},
               "la": {"raise": 88, "out": -14, "twist": 10, "elbow": 14, "wrist": -24}})
    sh.key(20, drive, "impact")
    sh.key(25, merge(drive, {"ra": {"raise": 92}, "la": {"raise": 90}}), "ease")
    sh.key(29, merge(drive, {"ra": {"raise": 91}, "la": {"raise": 89}}), "ease")
    sh.key(44, s({"root": {"y": BASE["root"]["y"] - .02}, "ra": {"raise": 66, "out": 0, "twist": 10, "elbow": 60},
                  "la": {"raise": 60, "out": 4, "twist": 10, "elbow": 66}}), "pass")
    sh.key(65, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 20 / F, "recover": 29 / F})


def sand_low_wave(arm):
    """Away route (.16 / .16 / .4): both palms brought up flat at the chest,
    then pushed down and out low, the knees giving a little - the wave
    rolls along the floor at his ankles."""
    sh = Take(arm, N + "SandLowWave")
    sh.key(0, s(), "ease")
    up = s({"root": {"y": BASE["root"]["y"] + .02}, "torso": {"pitch": -2}, "head": {"pitch": 6},
            "ra": {"raise": 70, "out": 8, "twist": -30, "elbow": 96, "wrist": -24},
            "la": {"raise": 70, "out": 8, "twist": -30, "elbow": 96, "wrist": -24}})
    sh.key(6, up, "ease")
    push = s({"root": {"y": BASE["root"]["y"] - .14}, "torso": {"pitch": 12}, "head": {"pitch": 12},
              "ra": {"raise": 36, "out": 16, "twist": -20, "elbow": 8, "wrist": -44},
              "la": {"raise": 36, "out": 16, "twist": -20, "elbow": 8, "wrist": -44}})
    sh.key(10, push, "impact")
    sh.key(15, merge(push, {"root": {"y": BASE["root"]["y"] - .16}, "ra": {"raise": 40, "wrist": -50}, "la": {"raise": 40, "wrist": -50}}), "ease")
    sh.key(19, merge(push, {"root": {"y": BASE["root"]["y"] - .15}, "ra": {"raise": 40, "wrist": -48}, "la": {"raise": 40, "wrist": -48}}), "ease")
    sh.key(30, s({"root": {"y": BASE["root"]["y"] - .04}, "torso": {"pitch": 3},
                  "ra": {"raise": 50, "out": -16, "twist": 20, "elbow": 80, "wrist": -10},
                  "la": {"raise": 48, "out": -18, "twist": 20, "elbow": 80, "wrist": -10}}), "pass")
    sh.key(43, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 10 / F, "recover": 19 / F})


def light4(arm):
    """L4 (.162 / .12 / .406), the backhand lash: the right hand comes across
    to his left shoulder (back of the hand out) and snaps out to his right,
    the wrist cracking last; the stream curls out that side. The head never
    leaves the opponent."""
    sh = Take(arm, N + "Light4")
    sh.key(0, s(), "ease")
    across = s({"torso": {"yaw": -6}, "head": {"yaw": -2},
                "ra": {"raise": 72, "out": -56, "twist": 30, "elbow": 118, "wrist": 34}})
    sh.key(6, across, "ease")
    out_ = s({"torso": {"yaw": 6}, "head": {"yaw": -8},
              "ra": {"raise": 86, "out": 46, "twist": -20, "elbow": 14, "wrist": -32}})
    sh.key(9, merge(out_, {"ra": {"out": 18, "elbow": 40, "wrist": 10}}), "pass")
    sh.key(10, out_, "impact")
    sh.key(14, merge(out_, {"ra": {"out": 54, "wrist": -44}}), "ease")
    sh.key(17, merge(out_, {"ra": {"out": 52, "wrist": -40}}), "ease")
    sh.key(28, s({"ra": {"raise": 70, "out": 10, "twist": 20, "elbow": 82, "wrist": -10}}), "pass")
    sh.key(41, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["hand.R"], 1)
    return sh.build(markers={"contact": 10 / F, "recover": 17 / F})


def author(arm):
    acts = shukaku_arm(arm)
    acts += sand_spikes(arm)
    acts += quicksand(arm)
    acts += third_eye(arm)
    acts += sand_clone(arm)
    acts += [sand_hand(arm), sand_fist(arm), sand_low_wave(arm), light4(arm)]
    return acts
