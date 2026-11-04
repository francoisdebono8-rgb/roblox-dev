"""Kakashi's seal jutsu and the string's middle hit (04/11, user: « les
animations pour toutes les attaques en plus ne sont pas faites... fais-moi de
belles animations »; young Kakashi is the Doton expert).

Authored on his body (kakashi_p6.STANCE: a narrow three-quarter base, the
blade hand low on the right, the free left hand on the line). The bible
(docs/characters/KAKASHI.md): measure, then ONE precise commitment; the eye
and the hand cost a pose; little useless height; every strike gives its guard
back. The earth is the opposite of his light fencing: each Doton goes DOWN
into the floor and the floor answers - three different ways of using it, none
the TrackingFang's one-hand slam. Each jutsu opens with its two seals
(jutsu_sasuke.weave: the hands really pressed together), then the act; the
act after the channel is one timeline split on the Active frame
(jutsu_sasuke.act: what the game really shows of a Release):

  EarthWall          tiger - snake, then both hands dive to the floor: a deep
                     squat, the two palms flat in front of the lead foot, the
                     shoulders pressing the chakra in; the wall rises with
                     HIM - the hips first, the hands peeled off the floor
                     palm-up as if lifting the slab, carried up the chest and
                     turned out at shoulder height, palms pushing the wall's
                     face; held a beat (a close attacker is thrown off), then
                     the guard
  EarthHeadhunter    snake - ram, then the free hand cocks by the ear and
                     spears down into the earth beside the lead foot - he
                     drops onto the rear knee and the arm goes in to the
                     wrist (his hand travels under the floor to the target);
                     the grip closes (a jolt down the arm, the head snaps up
                     at him), then he wrenches the hand out of the ground to
                     the hip and rises
  EarthDragon        ram - rat, then the shiko: the lead knee lifts high, the
                     seal kept at the chest, and the foot is stamped down -
                     the body drops into a wide low base and the floor
                     answers; the hands part, the left palm rising open from
                     low in front (the dragon's head comes out of the floor),
                     then it is SENT: the hand cocks back by the shoulder and
                     is thrown open at him on a drive of the hips, held while
                     the dragon runs, the right hand still in the one-handed
                     seal (his copied Water Dragon is both arms up)
  WhiteChakraSabre   rat - tiger, then the right hand goes up over the shoulder
                     to his father's tanto and draws it out in an arc into the
                     forward grip, upright before his face; two fingers of the
                     left hand are laid at the guard and run up the blade to
                     the tip (the white light runs with them), then the blade
                     is flicked out and down to the side, the fingers back on
                     the line - the guard
  Light4             L1 stab, L2 forearm, L4, L3 backhand: the descending
                     diagonal cut to the body - the blade hand rises by the
                     right ear on a coil of the hips and comes down across
                     the body to the left hip on a half step, the free hand
                     clearing to the chest; it ends low on the left, which
                     sets up the backhand that opens outward (L3), and the
                     blade comes back up the inside line to the guard

Server timings (Shared/SealJutsu, Shared/Attacks):
  EarthWall ch .2 act .2 rec .3           EarthHeadhunter ch .26 act .06 rec .28
  EarthDragon ch .5 act .25 rec .34       WhiteChakraSabre ch .25 act .05 rec .2
  Light4 .09 / .12 / .28
"""
from nd_shot import Shot, merge
from kakashi_p6 import STANCE
from jutsu_sasuke import stance_fn, weave, seal, act

N = "Copycat."
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]
# The right hand alone in the tiger (two fingers up) at the sternum
# (jutsu_itachi.TIGER_R: the same rig, chest space).
TIGER_R = {"raise": 32.2, "out": -20.2, "twist": 58.6, "elbow": 102.7, "wrist": 0, "wroll": 0}


# ============================================================== EarthWall
# Both palms flat on the floor in front of the lead foot: a deep squat, the
# chest over the hands, the eyes on the spot where the wall will stand.
DOWN = {"root": {"y": -1.42, "z": -.26, "pitch": 40, "yaw": 6, "roll": 0}, "torso": {"pitch": 26, "yaw": -4, "roll": 0},
        "head": {"pitch": -30, "yaw": -4, "roll": 0},
        "ra": {"raise": 62, "out": -16, "twist": 0, "elbow": 6, "wrist": 56, "wroll": 0},
        "la": {"raise": 62, "out": -14, "twist": 0, "elbow": 6, "wrist": 56, "wroll": 0},
        "rf": {"toe": 0}, "lf": {"toe": 0}}


def earth_wall(arm):
    out = []
    ch = Shot(arm, N + "EarthWall.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.46}, "head": {"pitch": -4}})
    last = weave(ch, 0, (1, 2), base, beat=4)
    # the hands leave the seal going down, the knees fold under them
    ch.key(last + 4, s({"root": {"y": -.96, "z": -.12, "pitch": 24, "yaw": 10}, "torso": {"pitch": 16, "yaw": -6},
                        "head": {"pitch": -18, "yaw": -6},
                        "ra": {"raise": 44, "out": -14, "twist": 10, "elbow": 40, "wrist": 30},
                        "la": {"raise": 46, "out": -12, "twist": 10, "elbow": 40, "wrist": 30}}), "pass")
    slap = s(DOWN)
    ch.key(last + 7, slap, "impact")
    # the shoulders sink over the hands: the chakra goes into the ground
    press = merge(slap, {"root": {"y": -1.48}, "torso": {"pitch": 28}, "head": {"pitch": -26}})
    ch.key(last + 10, press, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 10) / 60}))

    # The wall rises with him (Active .2): the hips lead out of the squat, the
    # palms peel off the floor and turn up under the slab, the arms carry it
    # up past the chest to the height of his face - forearms upright, palms out,
    # holding up the slab as it stands - up on the toes;
    # then they come down forward onto its face and shove (a close attacker
    # is thrown off), and the guard.
    pry = merge(press, {"root": {"y": -1.24, "z": -.2, "pitch": 32}, "torso": {"pitch": 24}, "head": {"pitch": -22},
                        "ra": {"raise": 42, "out": -8, "twist": -40, "elbow": 40, "wrist": -10},
                        "la": {"raise": 42, "out": -8, "twist": -40, "elbow": 40, "wrist": -10}})
    heave = s({"root": {"y": -.8, "z": -.1, "pitch": 14, "yaw": 8}, "torso": {"pitch": 4, "yaw": -4},
               "head": {"pitch": -4, "yaw": -4},
               "ra": {"raise": 70, "out": -6, "twist": -70, "elbow": 100, "wrist": -24},
               "la": {"raise": 70, "out": -6, "twist": -70, "elbow": 100, "wrist": -24}})
    crest = s({"root": {"y": -.26, "z": .06, "pitch": -4, "yaw": 6}, "torso": {"pitch": -8, "yaw": -4},
               "head": {"pitch": 12, "yaw": -4},
               "ra": {"raise": 86, "out": 24, "twist": -14, "elbow": 100, "wrist": -44},
               "la": {"raise": 86, "out": 24, "twist": -14, "elbow": 100, "wrist": -44},
               "rf": {"toe": -14, "y": .04}})
    hold = merge(crest, {"root": {"y": -.32, "z": .04}, "torso": {"pitch": -5}, "head": {"pitch": 10},
                         "ra": {"raise": 84, "elbow": 94}, "la": {"raise": 84, "elbow": 94}, "rf": {"toe": -6, "y": 0}})
    # the palms come down onto the wall's face and shove it
    shove = s({"root": {"y": -.5, "z": -.12, "pitch": 10, "yaw": 6}, "torso": {"pitch": 6, "yaw": -4},
               "head": {"pitch": -6, "yaw": -4},
               "ra": {"raise": 88, "out": 4, "twist": -72, "elbow": 8, "wrist": -64},
               "la": {"raise": 88, "out": 4, "twist": -72, "elbow": 8, "wrist": -64},
               "rf": {"toe": -16, "y": .06}})
    after = merge(shove, {"root": {"y": -.48, "z": -.1}, "ra": {"elbow": 16}, "la": {"elbow": 16}, "rf": {"toe": -8, "y": .02}})
    lower = s({"root": {"y": -.42, "z": -.02}, "head": {"pitch": -2},
               "ra": {"raise": 50, "out": 10, "twist": -10, "elbow": 60, "wrist": -24},
               "la": {"raise": 64, "out": -10, "twist": -40, "elbow": 56, "wrist": -20}})
    keys = [(0, press, "ease"), (3, pry, "pass"), (7, heave, "pass"), (12, crest, "impact"), (16, hold, "ease"),
            (21, shove, "impact"), (23, after, "ease"), (27, lower, "pass"), (32, s(), "ease")]
    out += act(arm, N + "EarthWall", keys, .2, .3,
               drags=[(["neck"], 1), (["hand.R", "hand.L"], 1), (["shoulder.L", "forearm.L"], 1)], marker=0)
    return out


# ======================================================== EarthHeadhunter
def headhunter(arm):
    out = []
    ch = Shot(arm, N + "EarthHeadhunter.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.46}, "head": {"pitch": -4}})
    last = weave(ch, 0, (2, 3), base, beat=4)
    # the free hand leaves the seal and cocks high by the left ear, fingers
    # down (a spear hand); the blade hand drops to the right thigh; the
    # weight is already going down
    cock = s({"root": {"y": -.72, "z": -.02, "pitch": 10, "yaw": 36, "roll": 4}, "torso": {"pitch": 6, "yaw": -14, "roll": 2},
              "head": {"pitch": -10, "yaw": -18},
              "la": {"raise": 138, "out": 26, "twist": 10, "elbow": 128, "wrist": 30},
              "ra": {"raise": 14, "out": 22, "twist": 20, "elbow": 74, "wrist": -20}})
    ch.key(last + 4, cock, "ease")
    # down onto the rear knee, the spear hand driven into the floor beside
    # the lead foot - in to the wrist
    plunge = s({"root": {"y": -1.42, "z": -.08, "pitch": 32, "yaw": 34, "roll": -12}, "torso": {"pitch": 22, "yaw": -12, "roll": -10},
                "head": {"pitch": -24, "yaw": -12},
                "la": {"raise": 24, "out": 24, "twist": 0, "elbow": 40, "wrist": 10},
                "ra": {"raise": 26, "out": 24, "twist": 20, "elbow": 80, "wrist": -20},
                "rf": {"x": .3, "z": .76, "y": .3, "toe": -56, "yaw": 30}, "lf": {"x": -.2, "z": -.72, "yaw": -6}})
    ch.key(last + 8, plunge, "impact")
    # the arm sinks a little deeper, the shoulder following it down
    sink = merge(plunge, {"root": {"y": -1.48, "roll": -14}, "torso": {"pitch": 24, "roll": -12}, "head": {"pitch": -20},
                          "la": {"raise": 20, "elbow": 30}})
    ch.key(last + 12, sink, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 12) / 60}))

    # The grip (Active .06): the buried hand closes on the legs - a jolt down
    # the arm, the head snaps up at him; then he wrenches it out to the hip
    # and rises (the rear foot comes down flat as he gets up).
    grip = merge(sink, {"root": {"y": -1.52, "z": -.04, "roll": -16}, "torso": {"pitch": 26, "roll": -13},
                        "head": {"pitch": 18, "yaw": -16, "roll": 4}, "la": {"raise": 18, "elbow": 26, "wrist": 30}})
    strain = merge(grip, {"root": {"y": -1.5, "z": .0}, "torso": {"pitch": 22}, "head": {"pitch": 14},
                          "la": {"raise": 22, "elbow": 34}})
    wrench = s({"root": {"y": -1.12, "z": .14, "pitch": 14, "yaw": 34, "roll": -2}, "torso": {"pitch": 6, "yaw": -18, "roll": 0},
                "head": {"pitch": -8, "yaw": -16, "roll": 0},
                "la": {"raise": 34, "out": 40, "twist": 10, "elbow": 96, "wrist": -10},
                "ra": {"raise": 22, "out": 22, "twist": 20, "elbow": 80, "wrist": -20},
                "rf": {"x": .26, "z": .66, "y": .1, "toe": -24, "yaw": 30}, "lf": {"x": -.2, "z": -.72, "yaw": -6}})
    yank = s({"root": {"y": -.7, "z": .12, "pitch": 4, "yaw": 34}, "torso": {"pitch": 2, "yaw": -16},
              "head": {"pitch": -6, "yaw": -14},
              "la": {"raise": -14, "out": 26, "twist": 10, "elbow": 106, "wrist": -10},
              "ra": {"raise": 24, "out": 14, "twist": 20, "elbow": 80, "wrist": -20},
              "rf": {"x": .22, "z": .6, "yaw": 30}, "lf": {"x": -.12, "z": -.62, "yaw": -6}})
    keys = [(0, sink, "ease"), (2, grip, "impact"), (4, strain, "ease"), (8, wrench, "pass"), (11, yank, "impact"),
            (15, merge(yank, {"root": {"y": -.5, "z": .06}, "la": {"raise": 30, "out": 0, "twist": -20, "elbow": 84}}), "pass"),
            (21, s(), "ease")]
    out += act(arm, N + "EarthHeadhunter", keys, .06, .28, drags=[(["neck"], 1)], marker=2)
    return out


# ============================================================ EarthDragon
def earth_dragon(arm):
    out = []
    ch = Shot(arm, N + "EarthDragon.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44}, "head": {"pitch": -4}})
    last = weave(ch, 0, (3, 4), base, beat=5)
    rat = merge(base, {"root": {"y": -.56}})
    rat = merge(rat, seal(4, rat))
    # the shiko: the weight onto the rear leg, the lead knee drawn high, the
    # seal kept at the chest (the head does not move)
    knee = merge(rat, {"root": {"x": .34, "y": -.3, "z": .32, "pitch": -4, "yaw": 22, "roll": 9}, "torso": {"pitch": 6, "roll": -6},
                       "head": {"pitch": -2, "roll": -4},
                       "lf": {"x": -.12, "y": 1.5, "z": -.3, "toe": 22, "yaw": -6}})
    ch.key(last + 5, merge(knee, {"root": {"x": .26, "y": -.4, "z": .24, "roll": 6}, "lf": {"y": .8, "z": -.42, "toe": 10}}), "pass")
    ch.key(last + 8, knee, "ease")
    # stamped: the foot drives down onto its spot, the body drops into a wide
    # low base, the seal jolts down with it - the floor answers
    stamp = merge(rat, {"root": {"x": 0, "y": -1.02, "z": -.02, "pitch": 8, "yaw": 24, "roll": 0}, "torso": {"pitch": 12, "roll": 0},
                        "head": {"pitch": -14, "roll": 0},
                        "rf": {"knee": 14}, "lf": {"y": 0, "z": LF["z"], "toe": 0, "knee": 14}})
    ch.key(last + 11, stamp, "impact")
    ch.key(last + 14, merge(stamp, {"root": {"y": -1.08}, "torso": {"pitch": 14}}), "ease")
    # the hands part: the right keeps the seal one-handed at the sternum, the
    # left opens palm-up low in front and rises - the dragon's head comes
    # out of the floor; the chest lifts with it, the eyes follow it up
    draw = s({"root": {"y": -.88, "z": .06, "pitch": 2, "yaw": 22}, "torso": {"pitch": -6, "yaw": -8},
              "head": {"pitch": 12, "yaw": -10},
              "ra": TIGER_R,
              "la": {"raise": 100, "out": 10, "twist": -76, "elbow": 48, "wrist": -26},
              "rf": stamp["rf"], "lf": stamp["lf"]})
    ch.key(last + 17, merge(draw, {"root": {"y": -1.04, "z": 0, "pitch": 8}, "torso": {"pitch": 8}, "head": {"pitch": -10},
                                   "la": {"raise": 26, "out": 14, "twist": -70, "elbow": 30, "wrist": -10}}), "pass")
    ch.key(last + 20, draw, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 20) / 60}))

    # It is sent (Active .25): the palm cocks back by the shoulder as the hips
    # load, then is thrown open at him on a drive of the hips over the lead
    # knee, the rear heel up, the head down behind the arm; held, guiding
    # it, then the guard (the knees come back in as he rises).
    cock = merge(draw, {"root": {"y": -.9, "z": .16, "pitch": -2, "yaw": 36}, "torso": {"pitch": -6, "yaw": 6},
                        "head": {"pitch": 2, "yaw": -20},
                        "la": {"raise": 44, "out": 50, "twist": -40, "elbow": 132, "wrist": -50}})
    send = s({"root": {"y": -.94, "z": -.4, "pitch": 22, "yaw": 10}, "torso": {"pitch": 12, "yaw": -22},
              "head": {"pitch": -14, "yaw": -4},
              "ra": TIGER_R,
              "la": {"raise": 88, "out": -4, "twist": -76, "elbow": 2, "wrist": -64},
              "rf": {"knee": 8, "y": .1, "toe": -32}, "lf": {"knee": 10}})
    drive = merge(send, {"root": {"y": -.96, "z": -.44, "pitch": 24}, "la": {"raise": 86, "elbow": 0, "wrist": -68}})
    guide = merge(send, {"root": {"y": -.88, "z": -.36, "pitch": 18}, "head": {"pitch": -10},
                         "la": {"raise": 92, "elbow": 8, "wrist": -58}, "rf": {"y": .06, "toe": -20}})
    ease_off = s({"root": {"y": -.62, "z": -.12, "pitch": 8, "yaw": 20}, "torso": {"pitch": 6, "yaw": -12},
                  "head": {"pitch": -4, "yaw": -12},
                  "ra": {"raise": 30, "out": 10, "twist": 20, "elbow": 84, "wrist": -14},
                  "la": {"raise": 70, "out": -8, "twist": -50, "elbow": 44, "wrist": -30}})
    keys = [(0, draw, "ease"), (2, cock, "ease"), (5, send, "impact"), (9, drive, "ease"), (15, guide, "ease"),
            (23, ease_off, "pass"), (35, s(), "ease")]
    out += act(arm, N + "EarthDragon", keys, .25, .34,
               drags=[(["neck"], 1), (["hand.L"], 1), (["shoulder.R", "forearm.R", "hand.R"], 2)], marker=5)
    return out


# ======================================================= WhiteChakraSabre
# The tanto upright before his face in the forward grip (rig-solved for the
# drawn blade of Client/VelmoraMotionEngine: LION_KUNAI_C0 on the right hand,
# Effects.buildTanto): the guard in front of the chest, the point above the
# head; the left hand's two fingers at the guard, half-way, at the tip.
PRESENT_R = {"raise": 33.1, "out": -33.0, "twist": 16.1, "elbow": 59.1, "wrist": 43.6, "wroll": -28.5}
FINGERS_L = [{"raise": 35.1, "out": -18.9, "twist": 43.3, "elbow": 82.4, "wrist": 0, "wroll": 0},
             {"raise": 61.1, "out": -36.9, "twist": 27.5, "elbow": 81.9, "wrist": 0, "wroll": 0},
             {"raise": 118.5, "out": -30.9, "twist": 17.5, "elbow": 36.9, "wrist": 0, "wroll": 0}]
PRESENT = {"root": {"y": -.42, "z": .02, "pitch": 2, "yaw": 20}, "torso": {"pitch": 2, "yaw": -12}, "head": {"pitch": 6, "yaw": -8}}


def sabre(arm):
    out = []
    ch = Shot(arm, N + "WhiteChakraSabre.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.44}, "head": {"pitch": -4}})
    last = weave(ch, 0, (4, 1), base, beat=4)
    # the right hand goes straight up from the seal over the right shoulder
    # to the hilt; the left keeps the tiger one-handed at the chest
    reach = s({"root": {"y": -.46, "z": .04, "pitch": 2, "yaw": 22}, "torso": {"pitch": 0, "yaw": -12, "roll": -3},
               "head": {"pitch": 0, "yaw": -14},
               "ra": {"raise": 160, "out": -18, "twist": 0, "elbow": 150, "wrist": 0},
               "la": {"raise": 40, "out": -22, "twist": 50, "elbow": 104, "wrist": 0}})
    ch.key(last + 4, reach, "ease")
    # drawn: the blade comes out over the shoulder in an arc and down in
    # front into the upright guard
    ch.key(last + 7, merge(reach, {"torso": {"roll": 0}, "ra": {"raise": 128, "out": 10, "twist": 10, "elbow": 70, "wrist": 20}}), "pass")
    present = s(merge(PRESENT, {"ra": PRESENT_R, "la": FINGERS_L[0]}))
    ch.key(last + 11, present, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 11) / 60}))

    # The fingers run up the blade (Active .05: the light runs with them),
    # leave the tip upward, then the blade is flicked out and down to the
    # right side - the left hand back on the line - and the guard.
    run = s(merge(PRESENT, {"head": {"pitch": 10}, "ra": PRESENT_R, "la": FINGERS_L[1]}))
    tip = s(merge(PRESENT, {"root": {"y": -.4}, "head": {"pitch": 14}, "ra": PRESENT_R,
                            "la": merge(FINGERS_L[2], {"raise": 128, "out": -20, "elbow": 30})}))
    flick = s({"root": {"y": -.5, "z": .02, "pitch": 6, "yaw": 38}, "torso": {"pitch": 6, "yaw": -6},
               "head": {"pitch": -2, "yaw": -22},
               "ra": {"raise": 22, "out": 44, "twist": 30, "elbow": 20, "wrist": -30},
               "la": {"raise": 60, "out": -16, "twist": -30, "elbow": 70, "wrist": -10}})
    keys = [(0, present, "ease"), (3, run, "pass"), (6, tip, "ease"), (9, flick, "impact"),
            (11, merge(flick, {"root": {"y": -.48}, "ra": {"out": 40, "elbow": 26}}), "ease"), (15, s(), "ease")]
    out += act(arm, N + "WhiteChakraSabre", keys, .05, .2, drags=[(["neck"], 1), (["hand.R"], 1)], marker=3)
    return out


# ================================================================ strikes
def light4(arm):
    """The string's middle hit (L1 stab, L2 forearm, L4, L3 backhand): the
    descending diagonal cut to the body (.09 / .12 / .28)."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    # the blade hand rises by the right ear on a coil of the hips; the free
    # hand stays on the line, lower; the lead heel lightens for the step
    load = s({"root": {"y": -.42, "z": .04, "pitch": 4, "yaw": 42}, "torso": {"pitch": 4, "yaw": 2},
              "head": {"pitch": -4, "yaw": -26},
              "ra": {"raise": 124, "out": 42, "twist": 20, "elbow": 118, "wrist": -24},
              "la": {"raise": 50, "out": -14, "twist": -30, "elbow": 84, "wrist": -10},
              "lf": {"y": .2, "z": LF["z"] - .1, "toe": 12}})
    sh.key(3, load, "ease")
    T = -.3
    hit = s({"travel": {"z": T}, "root": {"y": -.5, "z": -.14, "pitch": 12, "yaw": 2}, "torso": {"pitch": 10, "yaw": -24},
             "head": {"pitch": -8, "yaw": -8},
             "ra": {"raise": 52, "out": -28, "twist": 40, "elbow": 26, "wrist": -34},
             "la": {"raise": 40, "out": -32, "twist": -10, "elbow": 112, "wrist": 0},
             "lf": {"z": LF["z"] + T, "y": 0, "toe": 0}, "rf": {"y": .06, "toe": -18, "yaw": 26}})
    sh.key(5, hit, "impact")
    follow = merge(hit, {"root": {"y": -.52, "yaw": -6}, "torso": {"yaw": -30},
                         "ra": {"raise": 38, "out": -40, "elbow": 22, "wrist": -40}})
    sh.key(8, follow, "ease")
    # the blade comes back up the inside line: the guard is given back
    sh.key(13, merge(hit, {"root": {"y": -.44, "z": -.06, "yaw": 16}, "torso": {"yaw": -14},
                           "ra": {"raise": 36, "out": 0, "twist": 20, "elbow": 70, "wrist": -22},
                           "la": {"raise": 52, "out": -18, "twist": -30, "elbow": 78, "wrist": -10},
                           "rf": {"z": RF["z"] + T + .08, "y": .2, "toe": -8, "yaw": 30}}), "pass")
    sh.key(19, at(T, {"root": {"y": -.4}}), "ease")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1).drag(["shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 13 / 60})


def author(arm):
    acts = earth_wall(arm)
    acts += headhunter(arm)
    acts += earth_dragon(arm)
    acts += sabre(arm)
    acts.append(light4(arm))
    return acts
