"""Partie 7 (DEC-030): Gaara (Sand), authored.

His bible (docs/characters/GAARA.md): he does not fight with his body - the
sand moves, he barely does. Upright, arms folded, feet close; every attack
is a small, exact gesture of a hand that DIRECTS the sand (an arm unfolds,
the palm opens, the fingers close), never a punch. The weight never shifts
much; the head stays level, the eyes do not blink. References: Gaara vs Lee
(Chunin prelims, ep. 48-50) and vs Naruto (ep. 75-79): the folded arms,
the single extended hand for Sand Coffin, the clench for Sand Burial; Storm
4's young Gaara for the timing of the gestures.

Server frame data (startup with his profile):
  Light1 .162  Light2 .18  Light3 .228  SandPillar (heavy, launcher) .27
  Sweep .12  DashAttack .077  Air1 .088  Air2 .099  Slam .165
  SandCoffin ch .35 act .10 rec .35   SandShuriken ch .25 act .08 rec .25
  DesertWave ch .26 act .20 rec .30   Sand bullet (tool) release .12
"""
from nd_shot import Shot, merge, mirror
from gait_from_lion import gait

N = "Sand."
FOLD_R = {"raise": 62, "out": -42, "twist": 44, "elbow": 122, "wrist": 0}
FOLD_L = {"raise": 58, "out": -46, "twist": 40, "elbow": 118, "wrist": 0}
STANCE = {"root": {"y": -.06, "z": 0, "pitch": 0, "yaw": 6}, "torso": {"pitch": -2, "yaw": -2},
          "head": {"pitch": 6, "yaw": -4}, "ra": FOLD_R, "la": FOLD_L,
          "rf": {"x": .1, "z": .24, "yaw": 8}, "lf": {"x": -.08, "z": -.22, "yaw": -4}}
GUARD = {"ra": FOLD_R, "la": FOLD_L}
AIR = {"root": {"y": -.2, "pitch": 0, "yaw": 0}, "torso": {"pitch": 0, "yaw": 0}, "head": {"pitch": 4, "yaw": 0},
       "ra": FOLD_R, "la": FOLD_L,
       "rf": {"x": .06, "z": -.1, "y": .5, "toe": -30, "yaw": 0, "knee": 4}, "lf": {"x": -.06, "z": .05, "y": .45, "toe": -30, "yaw": 0, "knee": 4}}
OPEN = {"raise": 86, "out": 0, "twist": -10, "elbow": 6, "wrist": -10}  # the arm out, palm open at the target


def s(over=None):
    return merge(STANCE, over or {})


def air(over=None):
    return merge(AIR, over or {})


def act(spec):
    """Gaara walks: the arms never leave the fold, the chest does not turn,
    no lean - the legs carry a still statue."""
    spec["la"], spec["ra"] = dict(FOLD_L), dict(FOLD_R)
    t = spec.get("torso")
    if t:
        if "yaw" in t: t["yaw"] *= .15
        if "pitch" in t: t["pitch"] *= .3
    r = spec.get("root")
    if r:
        if "pitch" in r: r["pitch"] *= .35
        if "y" in r: r["y"] = r["y"] * .55
    h = spec.get("head")
    if h:
        if "yaw" in h: h["yaw"] *= .2
        if "pitch" in h: h["pitch"] = 4
    return spec


def locomotion(arm):
    return gait(arm, N, STANCE, GUARD, act)


def idle(arm):
    """Stillness (3.6 s, the breath only); every cycle the head turns a few
    degrees on the opponent, as if listening to the sand."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(110, s({"head": {"yaw": -10, "pitch": 4}, "root": {"y": -.08}}), "ease")
    sh.key(216, s(), "ease")
    sh.drag(["neck"], 10)
    return sh.build(loop=True)


# ================================================================ strikes
def lash(name, contact, arm_side, sweep_out, recover_f):
    """A sand lash: one arm unfolds and points, the palm opens; at the
    contact the fingers snap (the lash cracks) and the arm folds back."""
    def build(arm):
        sh = Shot(arm, N + name)
        side = "ra" if arm_side == "R" else "la"
        sh.key(0, s(), "ease")
        reach = merge(OPEN, {"out": sweep_out, "elbow": 30, "raise": 70})
        sh.key(contact - 4, s({side: reach, "head": {"yaw": -6}}), "ease")
        hit = s({side: merge(OPEN, {"out": -sweep_out * .4}), "head": {"yaw": -8}, "root": {"yaw": 2 if arm_side == "R" else 10}})
        sh.key(contact, hit, "impact")
        sh.key(contact + 4, merge(hit, {side: {"wrist": 20}}), "ease")
        sh.key(recover_f, s(), "ease")
        return sh.build(markers={"contact": contact / 60, "recover": (contact + 6) / 60})
    return build


def light3(arm):
    """L3: both arms unfold and sweep together - the sand wave throws him."""
    sh = Shot(arm, N + "Light3")
    sh.key(0, s(), "ease")
    sh.key(10, s({"ra": merge(OPEN, {"out": -40, "elbow": 40}), "la": merge(OPEN, {"out": -40, "elbow": 40}), "root": {"y": -.1}}), "ease")
    hit = s({"ra": merge(OPEN, {"out": 50}), "la": merge(OPEN, {"out": 50}), "root": {"y": -.12}, "torso": {"pitch": 2}})
    sh.key(14, hit, "impact")
    sh.key(18, merge(hit, {"ra": {"out": 56}, "la": {"out": 56}}), "ease")
    sh.key(34, s(), "ease")
    return sh.build(markers={"contact": 14 / 60, "recover": 20 / 60})


def sand_pillar(arm):
    """Heavy / launcher: the right hand lifts, palm up, and rises past the
    face - the sand erupts under the opponent."""
    sh = Shot(arm, N + "SandPillar")
    sh.key(0, s(), "ease")
    sh.key(10, s({"ra": {"raise": 30, "out": 10, "twist": -60, "elbow": 40, "wrist": 0}, "head": {"pitch": 10}}), "ease")
    hit = s({"ra": {"raise": 150, "out": 10, "twist": -60, "elbow": 20, "wrist": 0}, "head": {"pitch": -6}, "root": {"y": -.02}})
    sh.key(16, hit, "impact")
    sh.key(24, merge(hit, {"ra": {"raise": 156}}), "ease")
    sh.key(42, s(), "ease")
    return sh.build(markers={"contact": 16 / 60, "recover": 24 / 60})


def sweep(arm):
    """Down route: the left hand sweeps low, palm down - the sand rolls
    along the floor under his feet."""
    sh = Shot(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(3, s({"la": {"raise": 30, "out": 40, "twist": 60, "elbow": 20, "wrist": 0}}), "ease")
    hit = s({"la": {"raise": 20, "out": -40, "twist": 60, "elbow": 10, "wrist": 0}, "root": {"yaw": 14}})
    sh.key(7, hit, "impact")
    sh.key(24, s(), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def dash_attack(arm):
    """Arrival on the sand glide: one hand out, the lash at the end."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s(), "ease")
    hit = s({"ra": OPEN, "head": {"yaw": -6}})
    sh.key(5, hit, "impact")
    sh.key(22, s(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air1(arm):
    sh = Shot(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(5, air({"ra": OPEN}), "impact")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air2(arm):
    sh = Shot(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(6, air({"la": OPEN}), "impact")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def slam(arm):
    """Down from the air: both hands press down, the sand hammers."""
    sh = Shot(arm, N + "Slam")
    sh.key(0, air({"ra": {"raise": 120, "out": 10, "elbow": 30}, "la": {"raise": 120, "out": 10, "elbow": 30}}), "ease")
    hit = air({"ra": {"raise": 40, "out": 10, "elbow": 10, "wrist": 40}, "la": {"raise": 40, "out": 10, "elbow": 10, "wrist": 40}, "head": {"pitch": 14}})
    sh.key(10, hit, "impact")
    sh.key(30, s(), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 22 / 60})


def throw_sand(arm):
    """Sand bullet (tool): a two-finger point from the fold - the bullet
    leaves the gourd past his shoulder."""
    sh = Shot(arm, N + "Throw.Sand")
    sh.key(0, s(), "ease")
    sh.key(7, s({"ra": merge(OPEN, {"elbow": 10})}), "launch")
    sh.key(20, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ============================================================ techniques
def sand_coffin(arm):
    """Sand Coffin / Burial: the right arm extends, palm OPEN at him (the
    sand wraps him) - then the fingers close into a fist: 'Sabaku Kyu'."""
    out = []
    ch = Shot(arm, N + "SandCoffin.Channel")
    ch.key(0, s(), "ease")
    reach = s({"ra": OPEN, "head": {"pitch": 2, "yaw": -6}})
    ch.key(14, reach, "ease")
    ch.key(21, merge(reach, {"ra": {"raise": 90}}), "ease")
    out.append(ch.build(markers={"release": 21 / 60}))
    re = Shot(arm, N + "SandCoffin.Release")
    re.key(0, reach, "ease")
    clench = merge(reach, {"ra": {"wrist": 30, "elbow": 14, "twist": -40}})
    re.key(4, clench, "impact")
    re.key(6, clench, "ease")
    out.append(re.build())
    rc = Shot(arm, N + "SandCoffin.Recover")
    rc.key(0, clench, "ease")
    rc.key(20, s(), "ease")
    out.append(rc.build())
    return out


def sand_shuriken(arm):
    """Sand Shuriken: the arms unfold crossing in front, then flick outward
    - six hardened blades fan off the gourd."""
    out = []
    ch = Shot(arm, N + "SandShuriken.Channel")
    ch.key(0, s(), "ease")
    cross = s({"ra": {"raise": 80, "out": -50, "twist": 20, "elbow": 60}, "la": {"raise": 80, "out": -50, "twist": 20, "elbow": 60}})
    ch.key(15, cross, "ease")
    out.append(ch.build(markers={"release": 15 / 60}))
    re = Shot(arm, N + "SandShuriken.Release")
    re.key(0, cross, "launch")
    fan = s({"ra": {"raise": 84, "out": 50, "twist": 0, "elbow": 10}, "la": {"raise": 84, "out": 50, "twist": 0, "elbow": 10}})
    re.key(4, fan, "impact")
    out.append(re.build())
    rc = Shot(arm, N + "SandShuriken.Recover")
    rc.key(0, fan, "ease")
    rc.key(16, s(), "ease")
    out.append(rc.build())
    return out


def desert_wave(arm):
    """Desert Wave: both palms turn up and rise - a wall of sand lifts and
    throws close attackers away; his body does not move."""
    out = []
    ch = Shot(arm, N + "DesertWave.Channel")
    ch.key(0, s(), "ease")
    low = s({"ra": {"raise": 20, "out": 30, "twist": -60, "elbow": 30}, "la": {"raise": 20, "out": 30, "twist": -60, "elbow": 30}})
    ch.key(16, low, "ease")
    out.append(ch.build(markers={"release": 16 / 60}))
    re = Shot(arm, N + "DesertWave.Release")
    re.key(0, low, "launch")
    up = s({"ra": {"raise": 120, "out": 40, "twist": -60, "elbow": 20}, "la": {"raise": 120, "out": 40, "twist": -60, "elbow": 20}, "head": {"pitch": -4}})
    re.key(6, up, "impact")
    re.key(12, up, "ease")
    out.append(re.build())
    rc = Shot(arm, N + "DesertWave.Recover")
    rc.key(0, up, "ease")
    rc.key(18, s(), "ease")
    out.append(rc.build())
    return out


# ================================================================= states
def intro(arm):
    """Match intro: arms folded, eyes on the floor; the sand pours out of
    the gourd around him; the head lifts - the eyes, nothing else."""
    sh = Shot(arm, N + "Intro")
    sh.key(0, s({"head": {"pitch": 24}}), "ease")
    sh.key(80, s({"head": {"pitch": 24}}), "ease")
    sh.key(110, s({"head": {"pitch": 2, "yaw": -6}}), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 4)
    return sh.build()


def win(arm):
    """Victory: he turns away without unfolding his arms; the sand slides
    back into the gourd."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    sh.key(30, s({"head": {"yaw": -30}}), "ease")
    sh.key(50, s({"root": {"yaw": 60}, "head": {"yaw": -40}, "rf": {"x": .1, "z": .1, "y": .15, "yaw": 60}}), "pass")
    away = s({"root": {"yaw": 110}, "head": {"yaw": -20, "pitch": 10}, "rf": {"x": .14, "z": -.05, "yaw": 110}, "lf": {"x": -.1, "z": -.2, "yaw": 100}})
    sh.key(66, away, "ease")
    sh.key(150, away, "ease")
    return sh.build()


def awaken(arm):
    """Shukaku's sand: the hands come up to the face, clawing - the body
    hunches, the head jerks; then the arms open wide, the sand roars."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    claw = {"raise": 140, "out": -30, "twist": 0, "elbow": 140, "wrist": 30}
    sh.key(12, s({"root": {"y": -.4, "pitch": 20}, "torso": {"pitch": 20}, "head": {"pitch": 20}, "ra": claw, "la": claw}), "ease")
    sh.key(18, s({"root": {"y": -.4, "pitch": 20}, "torso": {"pitch": 20, "roll": 8}, "head": {"pitch": 10, "roll": -10}, "ra": claw, "la": claw}), "pass")
    wide = s({"root": {"y": -.2, "pitch": -6}, "torso": {"pitch": -10}, "head": {"pitch": -20},
              "ra": {"raise": 100, "out": 70, "elbow": 20}, "la": {"raise": 100, "out": 70, "elbow": 20}})
    sh.key(30, wide, "impact")
    sh.key(44, s(), "ease")
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), lash("Light1", 10, "R", 40, 30)(arm), lash("Light2", 11, "L", 40, 32)(arm), light3(arm), sand_pillar(arm),
             sweep(arm), dash_attack(arm), air1(arm), air2(arm), slam(arm), throw_sand(arm), intro(arm), win(arm), awaken(arm)]
    acts += sand_coffin(arm)
    acts += sand_shuriken(arm)
    acts += desert_wave(arm)
    return acts
