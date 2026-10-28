"""Partie 9 (DEC-030): Neji (GentleFist), authored.

His bible (docs/characters/NEJI.md): the Byakugan and the Gentle Fist -
palms and two fingers that close chakra points, a perfect Rotation. The
Hyuga stance: deep and wide, side-on, the lead palm forward low and open,
the rear palm high by the ear; strikes are short, straight and exact (the
fingers, not the fist), the body moves as one block on the feet.
References: Neji vs Hinata (Chunin prelims, ep. 39-41) and vs Naruto
(finals, ep. 59-61): the stance, the 64 Palms ('you are within my field of
divination'), the Rotation; Neji vs Kidomaru (ep. 117-119) for the
Vacuum Palm; Storm 4 Neji.

Server frame data (startup with his profile):
  Light1 .083  Light2 .094  Light3 .12  Heavy .306  PalmThrust .11
  Launcher .167  Sweep .12  CircleStep .09  DashAttack .066
  Air1 .077 Air2 .088 AirDrive .08 AirSpike .09 AirSwitch .10  Slam .15
  Rotation ch .04 act .55 rec .24   VacuumPalm ch .18 act .06 rec .26
  SixtyFourPalms ch .22 act .12 rec .40
"""
from nd_shot import Shot, merge, mirror
from gait_from_lion import gait, scaler

N = "GentleFist."
STANCE = {"root": {"y": -.66, "z": -.02, "pitch": 6, "yaw": 50}, "torso": {"pitch": 4, "yaw": -24},
          "head": {"pitch": -4, "yaw": -26},
          "la": {"raise": 70, "out": 6, "twist": -40, "elbow": 20, "wrist": -30},      # lead palm forward, low
          "ra": {"raise": 110, "out": -10, "twist": -40, "elbow": 110, "wrist": -30},  # rear palm high by the ear
          "rf": {"x": .38, "z": .8, "yaw": 64}, "lf": {"x": -.14, "z": -.8, "yaw": 26}}
GUARD = {"la": {"raise": 66, "out": 6, "twist": -40, "elbow": 26, "wrist": -30}, "ra": {"raise": 100, "out": -10, "twist": -40, "elbow": 110, "wrist": -30}}
AIR = {"root": {"y": -.45, "pitch": 10, "yaw": 0}, "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
       "la": {"raise": 60, "out": 20, "twist": -40, "elbow": 30, "wrist": -30}, "ra": {"raise": 80, "out": 20, "twist": -40, "elbow": 80, "wrist": -30},
       "rf": {"x": .05, "z": -.5, "y": 1.0, "toe": -24, "yaw": 0, "knee": 6}, "lf": {"x": -.05, "z": -.35, "y": .9, "toe": -26, "yaw": 0, "knee": 6}}
PALM = {"raise": 86, "out": -4, "twist": -50, "elbow": 6, "wrist": -50}     # palm heel forward
FINGERS = {"raise": 84, "out": -6, "twist": -10, "elbow": 6, "wrist": 0}     # two fingers straight


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .8 + T}, "lf": {"z": -.8 + T}})
    return merge(base, over or {})


def air(over=None):
    return merge(AIR, over or {})


def locomotion(arm):
    """Composed: the torso turns little, the head never bobs, the arms stay
    in the Gentle Fist guard (a smaller swing)."""
    return gait(arm, N, STANCE, GUARD, scaler(torso_yaw=.5, torso_pitch=.8, root_pitch=.85, head_yaw=.5),
                arms={"walk": 1.0, "run": .6, "jump": .8})


def idle(arm):
    """The stance held, breathing; the lead palm turns a few degrees - the
    Byakugan sees all round, the head does not need to move."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(60, s({"root": {"y": -.69}, "la": {"twist": -30, "wrist": -24}}), "ease")
    sh.key(120, s(), "ease")
    sh.drag(["hand.L"], 4)
    return sh.build(loop=True)


def strike(name, contact, side, pose, travel, recover, root=None, extra=None):
    """A Gentle Fist strike: the whole body slides on the feet (no wind-up
    of the arm), the hand arrives straight; the other hand stays ready."""
    def build(arm):
        sh = Shot(arm, N + name)
        sh.key(0, s(), "ease")
        hand = "la" if side == "L" else "ra"
        other = "ra" if side == "L" else "la"
        sh.key(max(1, contact - 3), s({"root": {"y": -.7, "z": .06}, hand: merge(pose, {"elbow": 70, "raise": 70})}), "ease")
        hit = s(merge({"travel": {"z": travel}, "root": merge({"y": -.7, "z": -.24, "pitch": 8, "yaw": 40 if side == "L" else 20}, root or {}),
                       "torso": {"pitch": 6, "yaw": -14 if side == "L" else -30}, hand: pose,
                       other: {"raise": 80, "out": -10, "twist": -40, "elbow": 100, "wrist": -30},
                       "lf": {"z": -.8 + travel}}, extra or {}))
        sh.key(contact, hit, "impact")
        sh.key(contact + 3, merge(hit, {"root": {"z": -.27}}), "ease")
        sh.key(recover, at(travel), "ease")
        return sh.build(markers={"contact": contact / 60, "recover": (contact + 6) / 60})
    return build


light1 = strike("Light1", 5, "L", FINGERS, -.35, 18)
light2 = strike("Light2", 6, "R", FINGERS, -.3, 20)
light3 = strike("Light3", 7, "L", PALM, -.45, 22)
palm_thrust = strike("PalmThrust", 7, "R", PALM, -.5, 24, extra={"la": PALM})


def heavy(arm):
    """Heavy: the twin palms from the hips - both hands draw back to the
    hips while the body sinks, then drive out together as he slides in."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    hip = {"raise": -10, "out": 10, "twist": -50, "elbow": 110, "wrist": -50}
    sh.key(12, s({"root": {"y": -.8, "z": .12, "yaw": 30}, "la": hip, "ra": hip}), "ease")
    hit = s({"travel": {"z": -.6}, "root": {"y": -.76, "z": -.3, "pitch": 10, "yaw": 20}, "torso": {"pitch": 6, "yaw": -14},
             "la": PALM, "ra": PALM, "lf": {"z": -1.4}})
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"root": {"z": -.34}}), "ease")
    sh.key(38, at(-.6), "ease")
    return sh.build(markers={"contact": 18 / 60, "recover": 26 / 60})


def launcher(arm):
    """Palm heel under the chin: he sinks, the rear palm rises straight up."""
    sh = Shot(arm, N + "Launcher")
    sh.key(0, s(), "ease")
    sh.key(6, s({"root": {"y": -.9, "pitch": 12}, "ra": {"raise": 0, "out": 10, "twist": -50, "elbow": 90, "wrist": -60}}), "ease")
    hit = s({"root": {"y": -.4, "pitch": -6, "yaw": 30}, "ra": {"raise": 150, "out": -10, "twist": -50, "elbow": 14, "wrist": -60}, "rf": {"toe": -20}})
    sh.key(10, hit, "impact")
    sh.key(14, merge(hit, {"ra": {"raise": 156}}), "ease")
    sh.key(26, s(), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def sweep(arm):
    """Low rotation sweep: a half spin at floor level, the lead leg reaps
    while the hands strike two points on the way."""
    sh = Shot(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -1.1, "pitch": 18, "yaw": 100}}), "ease")
    hit = s({"root": {"y": -1.1, "pitch": 18, "yaw": -10}, "la": {"raise": 30, "out": 50, "elbow": 10}, "ra": PALM,
             "rf": {"x": -.2, "z": -1.0, "y": .05, "yaw": -40}})
    sh.key(7, hit, "impact")
    sh.key(12, merge(hit, {"root": {"yaw": -40}, "rf": {"x": -.7, "z": -.5}}), "ease")
    sh.key(26, s(), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def circle_step(arm):
    """Side route: a circular step round the guard onto a chakra point - the
    feet trace the circle, the two fingers go in from the flank."""
    sh = Shot(arm, N + "CircleStep")
    sh.key(0, s(), "ease")
    sh.key(3, s({"rf": {"x": .9, "z": .2, "y": .2}, "root": {"yaw": 20}}), "pass")
    hit = s({"root": {"y": -.7, "z": -.1, "yaw": 0}, "ra": FINGERS, "rf": {"x": 1.0, "z": -.2, "y": 0, "yaw": 20}, "lf": {"yaw": 10}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.14}}), "ease")
    sh.key(20, s({"rf": {"x": 1.0, "z": -.2}}), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 10 / 60})


dash_attack = strike("DashAttack", 4, "R", PALM, -.6, 20, root={"pitch": 16})


def air_palms(name, contact, pose_l, pose_r, root=None):
    def build(arm):
        sh = Shot(arm, N + name)
        sh.key(0, air(), "ease")
        sh.key(max(1, contact - 3), air({"la": {"raise": 30, "elbow": 100}, "ra": {"raise": 30, "elbow": 100}}), "ease")
        hit = air({"la": pose_l, "ra": pose_r, "root": root or {}})
        sh.key(contact, hit, "impact")
        sh.key(contact + 4, hit, "ease")
        sh.key(contact + 14, air(), "ease")
        return sh.build(markers={"contact": contact / 60, "recover": (contact + 6) / 60})
    return build


air1 = air_palms("Air1", 5, PALM, PALM)
air2 = air_palms("Air2", 5, AIR["la"], merge(PALM, {"raise": 50}), {"pitch": 24})
air_drive = air_palms("AirDrive", 5, PALM, PALM, {"pitch": -6})
air_spike = air_palms("AirSpike", 5, AIR["la"], merge(PALM, {"raise": 40}), {"pitch": 30})
air_switch = air_palms("AirSwitch", 6, merge(PALM, {"out": 50}), AIR["ra"], {"yaw": 120})


def throw_kunai(arm):
    sh = Shot(arm, N + "Throw.Kunai")
    sh.key(0, s(), "ease")
    sh.key(4, s({"ra": {"raise": 120, "out": 10, "elbow": 110, "wrist": 0}}), "ease")
    rel = s({"ra": {"raise": 80, "out": -10, "elbow": 10, "wrist": -20}, "root": {"yaw": 30}})
    sh.key(7, rel, "launch")
    sh.key(16, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ============================================================ techniques
def rotation(arm):
    """Eight Trigrams Rotation: the arms open, palms out, and the whole body
    spins on the lead foot - two full turns in the active window; the
    chakra dome is the spin's own."""
    out = []
    ch = Shot(arm, N + "Rotation.Channel")
    ch.key(0, s(), "ease")
    opened = {"root": {"y": -.5, "pitch": 0, "yaw": 0}, "torso": {"pitch": 0, "yaw": 0}, "head": {"pitch": 0, "yaw": 0},
              "la": {"raise": 80, "out": 70, "twist": -40, "elbow": 10, "wrist": -40}, "ra": {"raise": 80, "out": 70, "twist": -40, "elbow": 10, "wrist": -40},
              "rf": {"x": .3, "z": .3, "yaw": 0}, "lf": {"x": -.3, "z": -.3, "yaw": 0}}
    ch.key(3, opened, "ease")
    out.append(ch.build(markers={"release": 3 / 60}))
    re = Shot(arm, N + "Rotation.Release")
    # One full turn per 16 frames (loops through the active window). The feet
    # turn with the body (on the balls), so nothing twists.
    for i, f in enumerate((0, 4, 8, 12, 16)):
        yaw = 90 * i
        re.key(f, merge(opened, {"root": {"yaw": yaw}, "rf": {"x": .3, "z": .3, "y": .02, "yaw": yaw}, "lf": {"x": -.3, "z": -.3, "y": .02, "yaw": yaw}}), "linear")
    out.append(re.build(loop=True))
    rc = Shot(arm, N + "Rotation.Recover")
    rc.key(0, opened, "ease")
    rc.key(14, s(), "ease")
    out.append(rc.build())
    return out


def vacuum_palm(arm):
    """Vacuum Palm: the rear palm drawn to the hip, then thrust out flat - the
    air pressure leaves the palm."""
    out = []
    ch = Shot(arm, N + "VacuumPalm.Channel")
    ch.key(0, s(), "ease")
    load = s({"root": {"y": -.76, "z": .1}, "ra": {"raise": -10, "out": 10, "twist": -50, "elbow": 110, "wrist": -50}})
    ch.key(11, load, "ease")
    out.append(ch.build(markers={"release": 11 / 60}))
    re = Shot(arm, N + "VacuumPalm.Release")
    re.key(0, load, "launch")
    hit = s({"root": {"y": -.72, "z": -.24, "yaw": 24}, "torso": {"yaw": -30}, "ra": PALM})
    re.key(3, hit, "impact")
    out.append(re.build())
    rc = Shot(arm, N + "VacuumPalm.Recover")
    rc.key(0, hit, "ease")
    rc.key(16, s(), "ease")
    out.append(rc.build())
    return out


def sixty_four(arm):
    """Eight Trigrams 64 Palms: 'you are within my field of divination' -
    the deepest stance, the lead palm out, the rear high; then the strikes
    in doubling series, alternating hands faster and faster."""
    out = []
    ch = Shot(arm, N + "SixtyFourPalms.Channel")
    ch.key(0, s(), "ease")
    field = s({"root": {"y": -.95, "pitch": 4}, "la": {"raise": 80, "out": 20, "twist": -40, "elbow": 10, "wrist": -30},
               "ra": {"raise": 120, "out": -10, "twist": -40, "elbow": 100, "wrist": -30}, "rf": {"x": .5, "z": .9}, "lf": {"x": -.2, "z": -.9}})
    ch.key(13, field, "ease")
    out.append(ch.build(markers={"release": 13 / 60}))
    re = Shot(arm, N + "SixtyFourPalms.Release")
    re.key(0, field, "ease")
    f = 2
    for i in range(10):
        side = "la" if i % 2 == 0 else "ra"
        re.key(f, merge(field, {side: FINGERS, "root": {"yaw": 40 if side == "la" else 60}}), "impact")
        f += 3 if i < 4 else 2
    out.append(re.build(loop=True))
    rc = Shot(arm, N + "SixtyFourPalms.Recover")
    rc.key(0, field, "ease")
    rc.key(24, s(), "ease")
    out.append(rc.build())
    return out


# ================================================================= states
def intro(arm):
    """Match intro: Byakugan - the hand comes up in the seal before the
    face, the veins around the eyes swell; he slides into the stance."""
    sh = Shot(arm, N + "Intro")
    calm = s({"root": {"y": -.1, "pitch": 0, "yaw": 20}, "torso": {"pitch": 0, "yaw": -6}, "head": {"pitch": 6, "yaw": -10},
              "la": {"raise": 4, "out": 10, "elbow": 10}, "ra": {"raise": 4, "out": 10, "elbow": 10},
              "rf": {"x": .2, "z": .3, "yaw": 20}, "lf": {"x": -.1, "z": -.3, "yaw": 0}})
    sh.key(0, calm, "ease")
    sh.key(40, calm, "ease")
    sh.key(60, merge(calm, {"head": {"pitch": -4}, "ra": {"raise": 110, "out": -40, "twist": 30, "elbow": 128}}), "ease")
    sh.key(90, merge(calm, {"head": {"pitch": -4}, "ra": {"raise": 110, "out": -40, "twist": 30, "elbow": 128}}), "ease")
    sh.key(118, s(), "ease")
    sh.key(156, s(), "ease")
    return sh.build()


def win(arm):
    """Victory: he straightens and lowers the hands, the eyes still veined
    - 'fate' - and turns his back."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    up = {"root": {"y": -.08, "pitch": 0, "yaw": 20}, "torso": {"pitch": 0, "yaw": -4}, "head": {"pitch": 2, "yaw": -10},
          "la": {"raise": 4, "out": 10, "elbow": 10}, "ra": {"raise": 4, "out": 10, "elbow": 10},
          "rf": {"x": .38, "z": .8, "yaw": 64}, "lf": {"x": -.14, "z": -.8, "yaw": 26}}
    sh.key(24, up, "ease")
    sh.key(44, merge(up, {"rf": {"x": .1, "z": .2, "y": .2}}), "pass")
    away = merge(up, {"root": {"yaw": 120}, "head": {"yaw": -30}, "rf": {"x": .14, "z": -.1, "y": 0, "yaw": 120}, "lf": {"x": -.14, "z": -.3, "yaw": 110}})
    sh.key(60, away, "ease")
    sh.key(150, away, "ease")
    return sh.build()


def awaken(arm):
    """Byakugan full field: the seal before the face again, then both palms
    sweep out wide - the blind spot closes."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    sh.key(12, s({"ra": {"raise": 110, "out": -40, "twist": 30, "elbow": 128}, "head": {"pitch": -2}}), "ease")
    sh.key(26, s({"root": {"y": -.8}, "la": {"raise": 80, "out": 70, "elbow": 10}, "ra": {"raise": 80, "out": 70, "elbow": 10}}), "impact")
    sh.key(40, s({"root": {"y": -.74}}), "ease")
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), light1(arm), light2(arm), light3(arm), palm_thrust(arm), heavy(arm), launcher(arm), sweep(arm),
             circle_step(arm), dash_attack(arm), air1(arm), air2(arm), air_drive(arm), air_spike(arm), air_switch(arm),
             throw_kunai(arm), intro(arm), win(arm), awaken(arm)]
    acts += rotation(arm)
    acts += vacuum_palm(arm)
    acts += sixty_four(arm)
    return acts
