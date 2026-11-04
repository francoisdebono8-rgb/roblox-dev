"""Naruto's seal jutsu, his string's middle hits and his awakening (04/11,
user: the new jutsu had no animations of their own, « fais-moi de belles
animations, applique-toi bien »; the awakening was « un peu léger »).

Authored on his body (naruto_p5.STANCE: low, wide, fists a little low, the
shoulders forward, left foot ahead). His bible: an impulsive, expressive body
(more than Minato's), real feet, weight in the fists, the whole body behind
every intention. Every jutsu opens with its two seals, snapped, the knees
dropping on each and the shoulders turning into them (the hands really
meet: the seal shapes are the rig-measured ones, see SEAL); then the act:

  CloneAmbush        tiger - snake, then the cross seal (Kage Bunshin): the
                     right fist is cocked by his ear and driven into the floor
                     in front of him, down on the rear knee - the clone dives
                     in there; he comes up following it along the floor with
                     his eyes and throws an uppercut at the sky as it bursts
                     out under his opponent (the way he beat Neji)
  HiddenFuma         snake - ram, the right hand reaches over his shoulder for
                     the folded Fuma and pulls it out round to a sidearm coil
                     (hips and chest wound far round, weight on the back leg,
                     the left hand aiming); the throw unwinds hips -> chest ->
                     arm, each later than the last, the arm wraps across and
                     the back heel is torn up; he rocks back into his stance
  SummonGamakichi    ram - rat, the thumb bitten (the head ducks into the
                     hand), the hand torn away and thrown high, up on his
                     toes; KUCHIYOSE: slammed flat on the floor in a deep
                     crouch; the smoke puff pushes him back up, grinning
  CloneThrow         rat - tiger, then down into a sprinter's crouch, arms
                     swept back for the clone behind him: the flight is his
                     running heavy (Legion.HeadDive, gaps_e6), whose first
                     pose this crouch is
  Light4             (body) the dip and dig: he drops under, both knees, and
                     the right fist shovels up into the stomach from below,
                     the shoulder driving through it, his head tucked
                     outside - L1 is the right hook high, L2 the left
                     straight; this one comes from the floor up
  Light5             (head) the clinch knee: both hands shoot out and hook
                     behind the head, yank it down onto a rising right knee,
                     then shove off
  Awaken             the Nine-Tails: the seal burns - a flinch, then folded
                     over it, both hands clutching his stomach, shaking; the
                     chakra bursts out of him and throws him up and back
                     (arms flung open behind, the roar to the sky, up on his
                     toes); then it pitches him forward, down onto his claws,
                     low, the eyes up on the opponent

Server timings (Shared/SealJutsu.Legion, Shared/Attacks with his profile):
  CloneAmbush  channel .2  act .06 rec .24     HiddenFuma  .26 / .06 / .28
  SummonGamakichi .34 / .08 / .3               CloneThrow channel .12
  Light4 (Light1 profile) .081 / .12 / .27     Light5 (Light2) .095 / .12 / .26
  Awaken: the same 46 frames (0.767 s) as the clip it replaces, no markers.
The engine stretches a Channel linearly over the server's channel time
(authored length / Channel stays within 1.0-1.3x), plays the Release only
while the server holds TechniqueActive (spec.Active) and then the Recover
from its frame 0: each act is one timeline cut on the Active frame (act()),
so the blow lands inside Active and the Recover goes on from that very pose.
"""
import math
import nd_anim
from nd_shot import Shot, merge, shape
from naruto_p5 import STANCE

N = "Legion."
F = 60.0

# ------------------------------------------------------------------ helpers
# Every key is a whole body: a channel a key leaves out would keep the value
# of an earlier key (Shot merges each key onto the previous one).
ZERO = {"travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0},
        "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}
BASE = merge(ZERO, STANCE)
RF, LF = dict(BASE["rf"]), dict(BASE["lf"])


def s(over=None):
    return merge(BASE, over or {})


def at(T, over=None):
    """The stance T studs along z (the feet with it)."""
    return merge(s({"travel": {"z": T}, "rf": {"z": RF["z"] + T}, "lf": {"z": LF["z"] + T}}), over or {})


def heel(foot, toe, ball=-.5):
    """A planted foot rolled up onto its ball (toe < 0: the heel lifts): the
    ankle rises and comes forward so the ball stays where it was."""
    t = math.radians(toe)
    by, bz = -.41, ball
    dy = by - (by * math.cos(t) - bz * math.sin(t))
    dz = bz - (by * math.sin(t) + bz * math.cos(t))
    a = math.radians(-foot.get("yaw", 0))
    out = dict(foot)
    out["x"] = foot.get("x", 0) + dz * math.sin(a)
    out["y"] = foot.get("y", 0) + dy
    out["z"] = foot.get("z", 0) + dz * math.cos(a)
    out["toe"] = toe
    return out


# The four seals with the hands really together (the shapes of nd_seals,
# solved on the rig so the hand blocks meet in front of the chin and chest,
# in chest space: the same numbers as jutsu_sasuke.SEAL).
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
# Kage Bunshin's cross: the tiger's hands crossed, the right over the left
# (solved on his seal body, right hand a little higher and across).
CROSS = {"ra": {"raise": 49.4, "out": -39.1, "twist": 44.4, "elbow": 85.3, "wrist": 12, "wroll": 0},
         "la": {"raise": 51.2, "out": -20.0, "twist": 60.0, "elbow": 90.0, "wrist": 12, "wroll": 0}}
# He squares up to the front for the seals, chin over the hands.
SEAL_BODY = {"root": {"y": -.52, "z": 0, "pitch": 10, "yaw": 8, "roll": 0}, "torso": {"pitch": 8, "yaw": -2, "roll": 0},
             "head": {"pitch": 0, "yaw": -6, "roll": 0}}


def seal_pose(n, i, sink=.07, over=None):
    """Seal n made i-th (1, 2): the knees a little lower each time and the
    shoulders turning into it (alternately), the chin dipping on the hands."""
    turn = 5 if i % 2 else -4
    body = merge(SEAL_BODY, {"root": {"y": SEAL_BODY["root"]["y"] - sink * i, "yaw": SEAL_BODY["root"]["yaw"] + turn * .5},
                             "torso": {"yaw": SEAL_BODY["torso"]["yaw"] - turn, "roll": -turn * .4},
                             "head": {"pitch": 4 + 2 * i, "yaw": -6 + turn * .6}})
    return s(merge(merge(body, over or {}), SEAL[n]))


def weave(sh, signs, beat, sink=.07, over=None, start=0):
    """The two seals, one every `beat` frames, each snapped (it arrives at
    speed and stops dead). Returns the frame of the last one."""
    f = start
    for i, n in enumerate(signs, 1):
        f = start + beat * i
        sh.key(f, seal_pose(n, i, sink, over), "impact")
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


# ================================================================ CloneAmbush
# The fist in the floor (rig-solved: the hand on the floor a stud and a half
# in front of him, the arm straight down the punch).
FLOOR_PUNCH = {"root": {"y": -1.62, "z": -.14, "pitch": 30, "yaw": 10, "roll": -10}, "torso": {"pitch": 22, "yaw": -14, "roll": -8},
               "head": {"pitch": -14, "yaw": 4, "roll": 4},
               "ra": {"raise": 49.7, "out": -22.2, "twist": 20, "elbow": 6.9, "wrist": 6},
               "la": {"raise": -34, "out": 56, "twist": -10, "elbow": 40, "wrist": -20},
               "rf": heel(RF, -40), "lf": dict(LF, knee=8)}


def clone_ambush(arm):
    out = []
    ch = Take(arm, N + "CloneAmbush.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (1, 2), 4)                                   # 4, 8
    # the hands come apart a hair, the chest lifting (the chakra kneaded) ...
    ch.key(last + 2, s(merge(SEAL_BODY, {"root": {"y": -.6, "yaw": 6}, "head": {"pitch": -2},
                                         "ra": {"raise": 54, "out": -6, "twist": 40, "elbow": 96, "wrist": 0},
                                         "la": {"raise": 52, "out": -4, "twist": 44, "elbow": 98, "wrist": 0}})), "pass")
    # ... and snap into the cross seal, the knees dropping with it: KAGE BUNSHIN
    cross = s(merge({"root": {"y": -.76, "z": .02, "pitch": 12, "yaw": 6}, "torso": {"pitch": 10, "yaw": 0},
                     "head": {"pitch": 6, "yaw": -4}}, CROSS))
    ch.key(last + 5, cross, "impact")                             # 13
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 5) / F}))

    # the act (Active .06: the fist is in the floor on frame 4; recovery .24)
    # the right fist leaves the seal, cocked high by the ear, the chest rising
    # and turning into it ...
    cock = s({"root": {"y": -1.1, "z": .0, "pitch": 16, "yaw": 22}, "torso": {"pitch": 0, "yaw": 10, "roll": 4},
              "head": {"pitch": 10, "yaw": -10},
              "ra": {"raise": 150, "out": 36, "twist": 20, "elbow": 118, "wrist": 0},
              "la": {"raise": 56, "out": -10, "twist": 40, "elbow": 96},
              "rf": RF, "lf": LF})
    # ... and driven into the floor in front of him, down on the rear knee
    punch = s(FLOOR_PUNCH)
    # the shoulders give with it, the head comes up along the floor
    sink = merge(punch, {"root": {"y": -1.66, "pitch": 31}, "torso": {"pitch": 23}, "head": {"pitch": -26, "yaw": 0},
                         "ra": {"raise": 48, "elbow": 9}, "la": {"raise": -26, "out": 50}})
    # up off the floor, the fist pulled back low, the eyes running along the
    # floor to him (the clone is under there) ...
    follow = s({"root": {"y": -1.0, "z": -.1, "pitch": 24, "yaw": 2, "roll": 0}, "torso": {"pitch": 14, "yaw": -6},
                "head": {"pitch": -26, "yaw": -2},
                "ra": {"raise": -14, "out": 20, "twist": 30, "elbow": 104, "wrist": 0},
                "la": {"raise": 34, "out": 18, "twist": 20, "elbow": 90},
                "rf": heel(RF, -18), "lf": LF})
    # ... it bursts out under him (0.2 s after the channel): the fist thrown
    # up at the sky with it
    sky = s({"root": {"y": -.4, "z": .04, "pitch": -2, "yaw": 26}, "torso": {"pitch": -8, "yaw": -14, "roll": -4},
             "head": {"pitch": -24, "yaw": -14},
             "ra": {"raise": 150, "out": 4, "twist": 10, "elbow": 36, "wrist": 0},
             "la": {"raise": 20, "out": 26, "twist": 20, "elbow": 100},
             "rf": heel(RF, -10), "lf": LF})
    out += act(arm, N + "CloneAmbush", [(0, cross, "ease"), (2, cock, "pass"), (4, punch, "impact"), (8, sink, "ease"),
                                        (11, follow, "pass"), (14, sky, "impact"), (18, s(), "ease")],
               .06, .24, drags=((["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)))
    return out


# ================================================================ HiddenFuma
def hidden_fuma(arm):
    out = []
    ch = Take(arm, N + "HiddenFuma.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (2, 3), 4)                                   # 4, 8
    # the right hand reaches over the shoulder for the folded Fuma
    reach = s({"root": {"y": -.56, "pitch": 8, "yaw": 28}, "torso": {"pitch": 2, "yaw": 14, "roll": 4},
               "head": {"pitch": -4, "yaw": -30},
               "ra": {"raise": 158, "out": 30, "twist": -10, "elbow": 132, "wrist": 0},
               "la": {"raise": 56, "out": -14, "twist": 30, "elbow": 84, "wrist": 0}})
    ch.key(last + 3, reach, "pass")                               # 11
    # pulled out and round: coiled, hips and chest wound far round, the blade
    # held out behind him at shoulder height, the weight on the back leg, the
    # left hand aiming at him
    coil = s({"root": {"y": -.66, "z": .16, "pitch": 2, "yaw": 54, "roll": -4}, "torso": {"pitch": -2, "yaw": 32, "roll": -5},
              "head": {"pitch": -8, "yaw": -70},
              "ra": {"raise": 10, "out": 86, "twist": 10, "elbow": 22, "wrist": -12},
              "la": {"raise": 84, "out": -64, "twist": 0, "elbow": 12, "wrist": 0},
              "rf": dict(RF, knee=4), "lf": heel(LF, -12)})
    ch.key(last + 8, coil, "ease")                                # 16
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 8) / F}))

    # the act (Active .06: the blade leaves on frame 4; recovery .28)
    # the hips unwind first, the chest after, the arm trails (the whip)
    unwind = merge(coil, {"root": {"z": .04, "pitch": 8, "yaw": 20, "roll": 0}, "torso": {"pitch": 2, "yaw": 34, "roll": 0},
                          "head": {"yaw": -48},
                          "ra": {"raise": 22, "out": 98, "elbow": 36},
                          "la": {"raise": 56, "out": -16, "elbow": 44}, "lf": LF})
    rel = s({"root": {"y": -.6, "z": -.22, "pitch": 18, "yaw": -8}, "torso": {"pitch": 12, "yaw": -18},
             "head": {"pitch": -16, "yaw": 18},
             "ra": {"raise": 106, "out": 8, "twist": 0, "elbow": 4, "wrist": -16},
             "la": {"raise": 8, "out": 36, "twist": 0, "elbow": 44},
             "rf": heel(RF, -28)})
    # follow-through: the arm wraps across, the back heel torn up
    follow = s({"root": {"y": -.6, "z": -.3, "pitch": 26, "yaw": -32, "roll": 4}, "torso": {"pitch": 16, "yaw": -40},
                "head": {"pitch": -14, "yaw": 34},
                "ra": {"raise": 82, "out": -62, "twist": 10, "elbow": 42, "wrist": 0},
                "la": {"raise": -16, "out": 40, "twist": -10, "elbow": 36},
                "rf": merge(heel(RF, -44), {"y": heel(RF, -44)["y"] + .18})})
    # the back heel comes down, he rocks back over it into his stance
    land = s({"root": {"y": -.62, "z": -.12, "pitch": 16, "yaw": -6}, "torso": {"pitch": 12, "yaw": -22},
              "head": {"pitch": -14, "yaw": 14},
              "ra": {"raise": 46, "out": -14, "twist": 20, "elbow": 80},
              "la": {"raise": 20, "out": 24, "twist": 10, "elbow": 80}})
    out += act(arm, N + "HiddenFuma", [(0, coil, "ease"), (2, unwind, "pass"), (4, rel, "impact"), (9, follow, "ease"),
                                       (14, land, "impact"), (18, s({"root": {"y": -.5, "z": .0}, "torso": {"yaw": -12}, "head": {"yaw": -6}}), "ease"),
                                       (21, s(), "ease")],
               .06, .28, drags=((["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)))
    return out


# =========================================================== SummonGamakichi
# The slam lands in a wide squat (he hops into it off his toes): square to the
# front, both knees out, the palm far in front, the head up on where the toad
# will be (rig-solved hand).
WIDE_R = {"x": .82, "z": .34, "yaw": 42, "knee": 10}
WIDE_L = {"x": -.66, "z": -.44, "yaw": -26, "knee": 10}
SLAM = {"root": {"y": -1.6, "z": -.16, "pitch": 34, "yaw": 2, "roll": -6}, "torso": {"pitch": 18, "yaw": -2, "roll": -4},
        "head": {"pitch": -44, "yaw": -4},
        "ra": {"raise": 59.1, "out": -25, "twist": 20, "elbow": 12.5, "wrist": -50},
        "la": {"raise": 4, "out": 62, "twist": -10, "elbow": 34, "wrist": -20},
        "rf": WIDE_R, "lf": WIDE_L}


def summon(arm):
    out = []
    ch = Take(arm, N + "SummonGamakichi.Channel")
    ch.key(0, s(), "ease")
    last = weave(ch, (3, 4), 5)                                   # 5, 10
    # the thumb bitten: the hand to the mouth, the head ducking into it
    bite = s({"root": {"y": -.6, "pitch": 10, "yaw": 16}, "torso": {"pitch": 8, "yaw": -6},
              "head": {"pitch": 14, "yaw": 6, "roll": -6},
              "ra": {"raise": 34.4, "out": -6.9, "twist": 60.3, "elbow": 113.4, "wrist": 10},
              "la": {"raise": 20, "out": 20, "twist": 10, "elbow": 80}})
    ch.key(last + 4, bite, "ease")                                # 14
    # torn away (a flick of the head the other way) ...
    ch.key(last + 7, s({"root": {"y": -.5, "pitch": 6, "yaw": 12}, "torso": {"pitch": 2, "yaw": -2},
                        "head": {"pitch": -4, "yaw": -14, "roll": 4},
                        "ra": {"raise": 120, "out": 40, "twist": 10, "elbow": 60, "wrist": -10},
                        "la": {"raise": 24, "out": 28, "twist": 0, "elbow": 56}}), "pass")
    # ... and the open palm thrown high: up on his toes
    high = s({"root": {"y": -.2, "z": .06, "pitch": -4, "yaw": 10}, "torso": {"pitch": -10, "yaw": -4},
              "head": {"pitch": -18, "yaw": -8},
              "ra": {"raise": 168, "out": 16, "twist": 0, "elbow": 18, "wrist": -24},
              "la": {"raise": 30, "out": 34, "twist": 0, "elbow": 40},
              "rf": heel(RF, -24), "lf": heel(LF, -16)})
    ch.key(last + 10, high, "ease")                               # 20
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": (last + 10) / F}))

    # the act (Active .08: the palm is on the floor on frame 5; recovery .3)
    # KUCHIYOSE: the palm comes down through a big arc, flat on the floor in
    # front of him, the body dropped into a deep crouch behind it (off his
    # toes: a little hop, the feet thrown out wide under him)
    air = s({"root": {"y": -.8, "z": -.08, "pitch": 20, "yaw": 6}, "torso": {"pitch": 10, "yaw": -4},
             "head": {"pitch": -20, "yaw": -6},
             "ra": {"raise": 118, "out": 4, "twist": 10, "elbow": 12, "wrist": -30},
             "la": {"raise": 8, "out": 50, "twist": 0, "elbow": 40},
             "rf": {"x": .62, "y": .42, "z": .5, "yaw": 38, "toe": -24}, "lf": {"x": -.46, "y": .36, "z": -.56, "yaw": -18, "toe": -14}})
    slam = s(SLAM)
    # the shoulders give with the slap, then press
    held = merge(slam, {"root": {"y": -1.66, "pitch": 35}, "torso": {"pitch": 20}, "ra": {"raise": 56, "elbow": 16}})
    # the smoke bursts in front of him: it pushes him back up off the floor, a
    # hop back, the feet gathered under him ...
    hop = s({"root": {"y": -.92, "z": .16, "pitch": 10, "yaw": 8}, "torso": {"pitch": 0, "yaw": -6},
             "head": {"pitch": -24, "yaw": -10},
             "ra": {"raise": 70, "out": 20, "twist": 10, "elbow": 40, "wrist": -10},
             "la": {"raise": 14, "out": 44, "twist": 0, "elbow": 56},
             "rf": {"x": .56, "y": .3, "z": .6, "yaw": 36, "toe": -18}, "lf": {"x": -.4, "y": .26, "z": -.58, "yaw": -14, "toe": -10}})
    # ... down in his stance, knees giving
    land = s({"root": {"y": -.74, "z": .06, "pitch": 12, "yaw": 14}, "torso": {"pitch": 6, "yaw": -6},
              "head": {"pitch": -18, "yaw": -12},
              "ra": {"raise": 46, "out": 10, "twist": 30, "elbow": 90},
              "la": {"raise": 26, "out": 24, "twist": 20, "elbow": 80}})
    # up, the chin up, the grin: the thumb rubbed under his nose (heh)
    grin = s({"root": {"y": -.5, "z": .02, "pitch": 4, "yaw": 16}, "torso": {"pitch": 0, "yaw": -6},
              "head": {"pitch": -16, "yaw": -12, "roll": 4},
              "ra": {"raise": 60, "out": -20, "twist": 50, "elbow": 128, "wrist": 0},
              "la": {"raise": 30, "out": 16, "twist": 20, "elbow": 90}})
    out += act(arm, N + "SummonGamakichi", [(0, high, "ease"), (2, air, "pass"), (5, slam, "impact"), (9, held, "ease"),
                                            (13, hop, "pass"), (16, land, "impact"), (19, grin, "pass"), (23, s(), "ease")],
               .08, .3, drags=((["neck"], 1), (["shoulder.R", "forearm.R", "hand.R"], 1)))
    return out


# ================================================================ CloneThrow
def clone_throw(arm):
    ch = Take(arm, N + "CloneThrow.Channel")
    ch.key(0, s(), "ease")
    # (a .12 s channel: 9 frames, played 1.25x)
    ch.key(3, seal_pose(4, 1), "impact")
    ch.key(5, seal_pose(1, 2), "impact")
    last = 5
    # a sprinter's crouch, arms swept back for the clone behind him; the head
    # up on the target: Legion.HeadDive's first pose (gaps_e6: root y -1,
    # pitch 34, torso 20, head -30, arms raise -40 out 20 elbow 30, the right
    # foot far back on its toes)
    crouch = s({"root": {"y": -1.0, "z": .04, "pitch": 34, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0},
                "head": {"pitch": -30, "yaw": 0},
                "ra": {"raise": -40, "out": 20, "twist": 0, "elbow": 30, "wrist": 0},
                "la": {"raise": -40, "out": 20, "twist": 0, "elbow": 30, "wrist": 0},
                "rf": heel({"x": .1, "z": 1.3, "yaw": 0}, -34), "lf": {"x": -.1, "z": .1, "yaw": 0, "knee": 4}})
    ch.key(last + 2, merge(crouch, {"root": {"y": -.84, "pitch": 24}, "torso": {"pitch": 14},
                                    "ra": {"raise": 4, "out": 26, "elbow": 50}, "la": {"raise": 4, "out": 26, "elbow": 50},
                                    "rf": merge(heel({"x": .2, "z": 1.0, "yaw": 10}, -20), {"y": .34}),
                                    "lf": {"x": -.14, "y": .16, "z": -.2, "yaw": -4}}), "pass")
    ch.key(last + 4, crouch, "ease")                              # 9
    ch.drag(["neck"], 1)
    return ch.build(markers={"release": (last + 4) / F})


# ================================================================ string
def light4(arm):
    """L4 (body), the dip and dig: from L2's left straight he drops under -
    both knees, the head slipping outside to his left - and the right fist
    shovels up into the stomach from below, the right shoulder and hip
    driving up through it; it carries on up a little, and he comes back up
    to his guard. Light4 (Light1 profile) .081 / .12 / .27."""
    sh = Take(arm, N + "Light4")
    sh.key(0, s(), "ease")
    # the drop: knees, the right fist low by the hip, the head outside
    dip = s({"root": {"y": -.96, "z": .0, "pitch": 18, "yaw": 34, "roll": -6}, "torso": {"pitch": 14, "yaw": 8, "roll": -6},
             "head": {"pitch": -18, "yaw": -18, "roll": -4},
             "ra": {"raise": -6, "out": 26, "twist": 40, "elbow": 112, "wrist": 0},
             "la": {"raise": 56, "out": -6, "twist": 30, "elbow": 104},
             "lf": dict(LF, z=LF["z"] - .18, y=.12, toe=6), "rf": heel(RF, -14)})
    sh.key(3, dip, "ease")
    # the dig: the fist rises into the stomach, the hips and shoulder behind it
    hit = s({"travel": {"z": -.4}, "root": {"y": -.82, "z": -.12, "pitch": 16, "yaw": -10, "roll": 2}, "torso": {"pitch": 6, "yaw": -18, "roll": 4},
             "head": {"pitch": -16, "yaw": 8},
             "ra": {"raise": 22.8, "out": -2.5, "twist": 30, "elbow": 116, "wrist": 0},
             "la": {"raise": 60, "out": -4, "twist": 30, "elbow": 104},
             "lf": dict(LF, z=LF["z"] - .4), "rf": heel(dict(RF, z=RF["z"] - .1), -26)})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"root": {"y": -.74, "yaw": -16}, "torso": {"pitch": 2, "yaw": -24},
                          "ra": {"raise": 38, "elbow": 110}}), "ease")
    # the rear foot follows the step, the fists back up
    sh.key(17, s({"travel": {"z": -.4}, "root": {"y": -.54, "z": -.1, "pitch": 14, "yaw": 8}, "torso": {"pitch": 10, "yaw": -12},
                  "ra": {"raise": 40, "out": 10, "twist": 26, "elbow": 108},
                  "lf": dict(LF, z=LF["z"] - .4), "rf": merge(heel(dict(RF, z=RF["z"] - .2), -16), {"y": heel(RF, -16)["y"] + .1})}), "pass")
    sh.key(29, at(-.4), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 5 / F, "recover": 12 / F})


def light5(arm):
    """L5 (head), the clinch knee: both hands shoot out and hook behind the
    head, yank it down onto the right knee driving up, then a shove off to
    make room for the last blow. Light5 (Light2 profile) .095 / .12 / .26."""
    sh = Take(arm, N + "Light5")
    sh.key(0, s(), "ease")
    hook = {"raise": 104, "out": -4, "twist": 10, "elbow": 40, "wrist": 34}
    grab = s({"travel": {"z": -.24}, "root": {"x": -.16, "y": -.42, "z": -.12, "pitch": 8, "yaw": 10}, "torso": {"pitch": 4, "yaw": -6},
              "head": {"pitch": -12, "yaw": -8},
              "la": hook, "ra": merge(hook, {"out": -2}),
              "lf": dict(LF, z=LF["z"] - .14, y=.12, toe=6), "rf": heel(RF, -16)})
    sh.key(3, grab, "ease")
    # the yank and the knee: the hands pull down to the knee coming up
    knee = s({"travel": {"z": -.24}, "root": {"x": -.32, "y": -.32, "z": -.28, "pitch": -6, "yaw": 2, "roll": -4}, "torso": {"pitch": 24, "yaw": 0},
              "head": {"pitch": 4, "yaw": -2},
              "la": merge(hook, {"raise": 62, "elbow": 76, "wrist": 44}), "ra": merge(hook, {"raise": 60, "elbow": 78, "wrist": 44}),
              "lf": dict(LF, z=LF["z"] - .24),
              "rf": {"x": .02, "y": 1.46, "z": -.36, "toe": 14, "yaw": 0, "knee": 0}})
    sh.key(6, knee, "impact")
    sh.key(10, merge(knee, {"root": {"y": -.3}, "torso": {"pitch": 26}, "rf": {"y": 1.54, "z": -.42}}), "ease")
    # the foot comes back down behind, the hands shove him off
    sh.key(17, s({"travel": {"z": -.24}, "root": {"x": -.12, "y": -.52, "z": -.02, "pitch": 14, "yaw": 14}, "torso": {"pitch": 8, "yaw": -6},
                  "head": {"pitch": -10, "yaw": -10},
                  "la": {"raise": 82, "out": -4, "twist": 0, "elbow": 20, "wrist": 30},
                  "ra": {"raise": 76, "out": 0, "twist": 0, "elbow": 28, "wrist": 30},
                  "lf": dict(LF, z=LF["z"] - .24),
                  "rf": {"x": RF["x"] - .04, "y": .14, "z": RF["z"] - .3, "toe": -10, "yaw": 26, "knee": 0}}), "pass")
    sh.key(29, at(-.24), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / F, "recover": 13 / F})


# ================================================================ awakening
def awaken(arm):
    """The Nine-Tails chakra (46 frames, as the clip it replaces). The seal
    on his stomach burns: a flinch, then he folds over it, both hands
    clutching it, shaking, lower and lower; the chakra bursts out of him and
    throws him up and back - arms flung open behind, up on his toes, the
    roar to the sky; it holds him there a beat, trembling; then it pitches
    him forward, down onto his claws, low, the eyes up on the opponent: the
    feral crouch he fights from."""
    sh = Take(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    clutch_r = {"raise": -18.4, "out": -60, "twist": 15, "elbow": 89.4, "wrist": 30}
    clutch_l = {"raise": -6.2, "out": -16.9, "twist": 46.2, "elbow": 84.7, "wrist": 30}
    # the flinch: the seal burns, the hips buckle back, the hands slap onto it
    flinch = s({"root": {"y": -.74, "z": .1, "pitch": 24, "yaw": 10, "roll": 3}, "torso": {"pitch": 26, "yaw": -4, "roll": 4},
                "head": {"pitch": 18, "yaw": -6, "roll": -4}, "ra": clutch_r, "la": clutch_l})
    sh.key(4, flinch, "impact")
    clutch = s({"root": {"y": -.86, "z": .08, "pitch": 30, "yaw": 8}, "torso": {"pitch": 32, "yaw": -2, "roll": 4},
                "head": {"pitch": 26, "yaw": -4}, "ra": clutch_r, "la": clutch_l})
    # shaking, lower and lower: the chakra boiling up
    sh.key(7, merge(clutch, {"root": {"roll": -3}, "torso": {"roll": -4}, "head": {"roll": 6}}), "pass")
    sh.key(10, merge(clutch, {"root": {"y": -.96, "pitch": 33, "roll": 3}, "torso": {"pitch": 36, "roll": 5}, "head": {"pitch": 30, "roll": -5}}), "pass")
    gather = merge(clutch, {"root": {"y": -1.06, "pitch": 36, "roll": -1}, "torso": {"pitch": 40, "roll": -2}, "head": {"pitch": 34, "roll": 3},
                            "ra": {"elbow": 98}, "la": {"elbow": 94}, "rf": heel(RF, -6)})
    sh.key(13, gather, "ease")
    sh.key(15, merge(gather, {"root": {"y": -1.1, "roll": 2}, "torso": {"roll": 3}, "head": {"roll": -3}}), "pass")
    # BURST: thrown up and back, arms flung open behind him, the roar to the sky
    back = s({"root": {"y": -.28, "z": .26, "pitch": -16, "yaw": 0, "roll": 0}, "torso": {"pitch": -26, "yaw": 0, "roll": 0},
              "head": {"pitch": -36, "yaw": 0, "roll": 0},
              "ra": {"raise": -24, "out": 84, "twist": -40, "elbow": 26, "wrist": -44},
              "la": {"raise": -24, "out": 84, "twist": -40, "elbow": 26, "wrist": -44},
              "rf": heel(RF, -22), "lf": heel(LF, -26)})
    sh.key(19, back, "impact")
    # held there, roaring, trembling
    roar = merge(back, {"root": {"y": -.24, "z": .3}, "torso": {"pitch": -30}, "head": {"pitch": -42},
                        "ra": {"raise": -30, "out": 90, "elbow": 20}, "la": {"raise": -30, "out": 90, "elbow": 20}})
    sh.key(24, roar, "ease")
    sh.key(27, merge(roar, {"root": {"y": -.28, "roll": 3}, "torso": {"pitch": -28, "roll": -4}, "head": {"pitch": -40, "roll": 4},
                            "ra": {"raise": -27, "out": 87}, "la": {"raise": -26, "out": 86}}), "pass")
    # the chakra pitches him forward: the claws drawn up by his shoulders ...
    sh.key(31, s({"root": {"y": -.86, "z": -.06, "pitch": 32, "roll": 0}, "torso": {"pitch": 18},
                  "head": {"pitch": -42},
                  "ra": {"raise": 120, "out": 44, "twist": -10, "elbow": 70, "wrist": 30},
                  "la": {"raise": 120, "out": 44, "twist": -10, "elbow": 70, "wrist": 30},
                  "rf": heel(RF, -16), "lf": LF}), "pass")
    # ... and down onto them: low, the hands on the floor, the eyes up
    down = s({"root": {"y": -1.45, "z": -.35, "pitch": 46, "yaw": 4}, "torso": {"pitch": 14, "yaw": -2},
              "head": {"pitch": -58, "yaw": -6},
              "ra": {"raise": 64.4, "out": -20, "twist": 0, "elbow": 2, "wrist": 50},
              "la": {"raise": 60.3, "out": -10.9, "twist": 25.6, "elbow": 2, "wrist": 50},
              "rf": heel(RF, -36), "lf": dict(LF, knee=6)})
    sh.key(35, down, "impact")
    sh.key(39, merge(down, {"root": {"y": -1.5, "pitch": 47}, "torso": {"pitch": 16}, "head": {"pitch": -60},
                            "ra": {"elbow": 10}, "la": {"elbow": 10}}), "ease")
    # the predator: the shoulders rise between the arms, the hands lift off
    feral = s({"root": {"y": -1.22, "z": -.16, "pitch": 38, "yaw": 6}, "torso": {"pitch": 18, "yaw": -4},
               "head": {"pitch": -52, "yaw": -8},
               "ra": {"raise": 62, "out": 22, "twist": 0, "elbow": 46, "wrist": 44},
               "la": {"raise": 66, "out": 22, "twist": 0, "elbow": 44, "wrist": 44},
               "rf": heel(RF, -24), "lf": LF})
    sh.key(46, feral, "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    return sh.build()


def author(arm):
    acts = clone_ambush(arm)
    acts += hidden_fuma(arm)
    acts += summon(arm)
    acts.append(clone_throw(arm))
    acts += [light4(arm), light5(arm), awaken(arm)]
    return acts
