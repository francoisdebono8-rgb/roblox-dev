"""Partie 8 (DEC-030): Rock Lee (Leaf), authored.

His bible (docs/characters/ROCK_LEE.md): taijutsu only - the fastest legs,
kicks that never stop, a lotus paid with his own body. The Strong Fist
stance: side-on, low and springy, the lead hand open and held out at the
opponent, the rear hand folded behind the small of the back. Everything is
a kick; the hands balance. References: Lee vs Gaara (Chunin prelims, ep.
48-50): the stance, Leaf Hurricane, the Primary Lotus, the gates; Lee vs
Kimimaro (ep. 124-126) for the Drunken-free young kicking; Storm 4 Lee.

Server frame data (startup with his profile):
  Light1 .077  Light2 .086  Light3 .108  Heavy .27  KneeStrike .08
  FlyingKick .10  LeafRising .13  LeafHurricane .11  LeafWhirlwind .12
  DashAttack .063  Air1 .069  Air2 .077  AirDrive .08  AirSpike .09  AirSwitch .10
  PrimaryLotus / LeafHeel / HiddenLotus (Slam) .15 / .20
  LeafGreatWhirlwind ch .08 act .05 rec .10
"""
from nd_shot import Shot, merge, mirror
from gait_from_lion import gait, scaler

N = "Leaf."
BACK = {"raise": -48, "out": -4, "twist": 96, "elbow": 68, "wrist": 0}   # the hand folded behind the back
STANCE = {"root": {"y": -.52, "z": -.04, "pitch": 8, "yaw": 48}, "torso": {"pitch": 4, "yaw": -18},
          "head": {"pitch": -6, "yaw": -30},
          "la": {"raise": 80, "out": 4, "twist": -10, "elbow": 20, "wrist": -20}, "ra": BACK,
          "rf": {"x": .32, "z": .7, "yaw": 58}, "lf": {"x": -.1, "z": -.7, "yaw": 20}}
GUARD = {"la": {"raise": 70, "out": 4, "twist": -10, "elbow": 30}, "ra": BACK}
AIR = {"root": {"y": -.5, "pitch": 14, "yaw": 0}, "torso": {"pitch": 10, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
       "la": {"raise": 60, "out": 40, "elbow": 40}, "ra": {"raise": 40, "out": 40, "elbow": 40},
       "rf": {"x": .05, "z": -.6, "y": 1.1, "toe": -24, "yaw": 0, "knee": 8}, "lf": {"x": -.05, "z": -.4, "y": 1.0, "toe": -26, "yaw": 0, "knee": 6}}


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .7 + T}, "lf": {"z": -.7 + T}})
    return merge(base, over or {})


def air(over=None):
    return merge(AIR, over or {})


def locomotion(arm):
    """Sasuke's gait, Lee's spring: a bigger bob, the chest drives forward,
    the arms pump hard (Gai's student runs flat out)."""
    return gait(arm, N, STANCE, GUARD, scaler(torso_yaw=1.1, torso_pitch=1.15, root_pitch=1.1, add={"torso": {"pitch": 4}}),
                arms={"walk": 1.0, "run": 1.2, "jump": 1.1})


def idle(arm):
    """Springy, never still (0.7 s): a bounce on the balls of the feet, the
    lead hand beckoning a little ('come on')."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(10, s({"root": {"y": -.6}, "rf": {"toe": -10}, "lf": {"toe": -10}, "la": {"wrist": 0, "elbow": 30}}), "ease")
    sh.key(21, s({"root": {"y": -.48}}), "ease")
    sh.key(31, s({"root": {"y": -.58}, "la": {"wrist": -30}}), "ease")
    sh.key(42, s(), "ease")
    sh.drag(["neck"], 2)
    return sh.build(loop=True)


def kick(name, contact, leg, target, chamber, recover, travel=0.0, turn=0, lean=0, extra=None):
    """A kick, the Strong Fist way: the knee chambers (the hip opens), the
    leg snaps out to the target, the support heel pivots; the lead hand
    balances forward, the rear hand stays behind the back."""
    def build(arm):
        sh = Shot(arm, N + name)
        foot = "rf" if leg == "R" else "lf"
        sh.key(0, s(), "ease")
        sh.key(contact - 3, s(merge({"root": {"y": -.46, "yaw": 48 + turn * .5}, foot: chamber}, extra or {})), "pass")
        hit = s(merge({"travel": {"z": travel}, "root": {"y": -.42, "z": -.1, "pitch": lean, "yaw": 48 + turn},
                       "torso": {"pitch": lean * .5, "yaw": -24}, "la": {"raise": 60, "out": 40, "elbow": 20},
                       foot: target}, extra or {}))
        sh.key(contact, hit, "impact")
        sh.key(contact + 4, merge(hit, {foot: {"y": target.get("y", 1) + .06}}), "ease")
        sh.key(contact + 9, s({foot: merge(chamber, {"y": chamber.get("y", .8) * .7})}), "pass")
        sh.key(recover, at(travel), "ease")
        sh.drag(["neck"], 1)
        return sh.build(markers={"contact": contact / 60, "recover": (contact + 6) / 60})
    return build


light1 = kick("Light1", 5, "L", {"x": -.1, "z": -1.6, "y": 1.2, "toe": 10, "knee": 0, "yaw": 20},
              {"x": -.1, "z": -.6, "y": 1.1, "toe": -10, "knee": 10}, 20, travel=-.4, lean=-6)
light2 = kick("Light2", 5, "R", {"x": .1, "z": -1.3, "y": 1.6, "toe": 10, "knee": 0, "yaw": -40},
              {"x": .4, "z": .1, "y": 1.2, "toe": -10, "knee": 10}, 20, travel=-.3, turn=-60, lean=-8)
light3 = kick("Light3", 6, "L", {"x": -.2, "z": -1.7, "y": 1.9, "toe": 20, "knee": 0, "yaw": 40},
              {"x": -.2, "z": -.4, "y": 1.4, "toe": -10, "knee": 10}, 24, travel=-.5, turn=20, lean=-12)
knee_strike = kick("KneeStrike", 5, "R", {"x": .1, "z": -.5, "y": 1.3, "toe": -30, "knee": 12},
                   {"x": .2, "z": .2, "y": .6, "toe": -20, "knee": 10}, 20, travel=-.3)
leaf_whirlwind = kick("LeafWhirlwind", 7, "R", {"x": .2, "z": -1.4, "y": 1.7, "toe": 10, "knee": 0, "yaw": -80},
                      {"x": .6, "z": .3, "y": 1.2, "toe": -10, "knee": 10}, 24, travel=-.2, turn=-110, lean=-10)


def heavy(arm):
    """Heavy, the Leaf Whirlwind's big brother: a full spinning back kick -
    he turns his back (360 deg through), the heel arrives last at head
    height; the commitment reads from the first frames."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    sh.key(8, s({"root": {"y": -.6, "yaw": 100}, "torso": {"yaw": 10}, "head": {"yaw": -70}, "lf": {"y": .1}}), "ease")
    sh.key(13, s({"root": {"y": -.5, "yaw": 190}, "head": {"yaw": -150}, "rf": {"x": .3, "z": .2, "y": 1.0, "knee": 10, "yaw": 190}}), "pass")
    hit = s({"travel": {"z": -.4}, "root": {"y": -.44, "z": -.1, "pitch": -14, "yaw": 250}, "torso": {"pitch": -10, "yaw": -20},
             "head": {"yaw": -170}, "la": {"raise": 30, "out": 60}, "rf": {"x": .1, "z": -1.6, "y": 1.9, "toe": 20, "knee": 0, "yaw": 250}})
    sh.key(16, hit, "impact")
    sh.key(20, merge(hit, {"rf": {"y": 1.95}}), "ease")
    sh.key(28, s({"root": {"yaw": 300}, "rf": {"x": .2, "z": .2, "y": .8, "knee": 10, "yaw": 300}}), "pass")
    sh.key(40, at(-.4, {"root": {"yaw": 408}, "rf": {"yaw": 418}, "lf": {"yaw": 380}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 16 / 60, "recover": 24 / 60})


def leaf_rising(arm):
    """Leaf Rising Wind (up route): a rising kick straight up under the chin
    from a crouch - he follows the body into the air (the Shadow of the
    Dancing Leaf)."""
    sh = Shot(arm, N + "LeafRising")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.95, "pitch": 20}, "la": {"raise": 0, "out": 40}}), "ease")
    hit = s({"root": {"y": -.2, "pitch": -26}, "torso": {"pitch": -16}, "head": {"pitch": -30},
             "rf": {"x": .1, "z": -.4, "y": 2.0, "toe": 10, "knee": 0}, "la": {"raise": -20, "out": 50}})
    sh.key(8, hit, "impact")
    sh.key(12, merge(hit, {"rf": {"y": 2.1}}), "ease")
    sh.key(18, s({"root": {"y": -.3}, "rf": {"x": .1, "z": -.1, "y": .9, "knee": 12}}), "pass")
    sh.key(26, s(), "ease")
    return sh.build(markers={"contact": 8 / 60, "recover": 14 / 60})


def leaf_hurricane(arm):
    """Leaf Hurricane (down route): a low spinning sweep at shin height, the
    hands on the floor - the string goes on (juggled)."""
    sh = Shot(arm, N + "LeafHurricane")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -1.05, "pitch": 26, "yaw": 90}, "la": {"raise": -10, "out": 30, "elbow": 10}, "ra": {"raise": -10, "out": 30, "elbow": 10}}), "ease")
    hit = s({"root": {"y": -1.1, "pitch": 26, "yaw": 0}, "la": {"raise": -10, "out": 30, "elbow": 10}, "ra": {"raise": -10, "out": 30, "elbow": 10},
             "rf": {"x": -.1, "z": -1.1, "y": .3, "yaw": -40}})
    sh.key(7, hit, "impact")
    sh.key(11, merge(hit, {"root": {"yaw": -40}, "rf": {"x": -.7, "z": -.6}}), "ease")
    sh.key(24, s({"root": {"yaw": 48}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def flying_kick(arm):
    """Run strike: the flying side kick out of the sprint - the body
    horizontal behind the heel, the arms swept back."""
    sh = Shot(arm, N + "FlyingKick")
    sh.key(0, s({"root": {"pitch": 24}}), "ease")
    sh.key(3, s({"root": {"y": -.2, "pitch": 4, "yaw": 70}, "lf": {"x": -.1, "z": -.4, "y": 1.3, "knee": 10}}), "pass")
    hit = s({"root": {"y": -.1, "pitch": -20, "yaw": 80}, "torso": {"pitch": -14, "yaw": -10}, "la": {"raise": -40, "out": 30}, "ra": {"raise": -40, "out": 30},
             "lf": {"x": -.1, "z": -1.7, "y": 1.3, "toe": 10, "knee": 0}, "rf": {"z": .4, "y": .8, "knee": 10}})
    sh.key(6, hit, "impact")
    sh.key(12, merge(hit, {"lf": {"z": -1.75}}), "ease")
    sh.key(28, s(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 14 / 60})


def dash_attack(arm):
    """Dynamic Entry: the flying kick at full speed, both feet off the floor."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s({"root": {"pitch": 24}}), "ease")
    hit = s({"root": {"y": -.2, "pitch": -16, "yaw": 70}, "la": {"raise": -40, "out": 30}, "ra": {"raise": -40, "out": 30},
             "lf": {"x": -.1, "z": -1.7, "y": 1.2, "toe": 10, "knee": 0}, "rf": {"z": .4, "y": .9, "knee": 10}})
    sh.key(4, hit, "impact")
    sh.key(10, merge(hit, {"lf": {"z": -1.75}}), "ease")
    sh.key(26, s(), "ease")
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


# ===================================================================== air
def air_kick(name, contact, foot, target, root=None):
    def build(arm):
        sh = Shot(arm, N + name)
        sh.key(0, air(), "ease")
        sh.key(max(1, contact - 2), air({foot: {"z": -.3, "y": 1.3, "knee": 12}}), "ease")
        hit = air(merge({foot: target, "la": {"raise": 30, "out": 60}, "ra": {"raise": 30, "out": 60}}, {"root": root or {}}))
        sh.key(contact, hit, "impact")
        sh.key(contact + 4, merge(hit, {foot: {"z": target["z"] - .05}}), "ease")
        sh.key(contact + 14, air(), "ease")
        return sh.build(markers={"contact": contact / 60, "recover": (contact + 6) / 60})
    return build


air1 = air_kick("Air1", 4, "lf", {"x": 0, "z": -1.4, "y": 1.3, "toe": 10, "knee": 0}, {"pitch": -8})
air2 = air_kick("Air2", 5, "rf", {"x": 0, "z": -1.4, "y": 1.5, "toe": 10, "knee": 0, "yaw": -40}, {"pitch": -10, "yaw": -60})
air_drive = air_kick("AirDrive", 5, "rf", {"x": 0, "z": -1.5, "y": 1.1, "toe": 10, "knee": 0}, {"pitch": -12})
air_switch = air_kick("AirSwitch", 6, "lf", {"x": -.2, "z": -1.3, "y": 1.6, "toe": 10, "knee": 0}, {"yaw": 80})


def air_spike(arm):
    """Axe kick down."""
    sh = Shot(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    sh.key(3, air({"root": {"pitch": -14}, "rf": {"z": -1.0, "y": 2.1, "toe": 10, "knee": 0}}), "ease")
    hit = air({"root": {"pitch": 22}, "torso": {"pitch": 16}, "rf": {"z": -1.1, "y": .6, "toe": 20, "knee": 0}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"rf": {"y": .5}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def lotus(name, hug):
    """Primary / Hidden Lotus (and the Leaf Heel when he has no strength
    left): from above the body, he wraps it (Primary) and they drive head
    first into the floor spinning - or the heel falls alone."""
    def build(arm):
        sh = Shot(arm, N + name)
        sh.key(0, air(), "ease")
        if hug:
            wrap = {"raise": 70, "out": -20, "twist": 0, "elbow": 110, "wrist": 0}
            sh.key(4, air({"root": {"pitch": 60}, "torso": {"pitch": 30}, "la": wrap, "ra": wrap}), "ease")
            hit = air({"root": {"pitch": 170}, "torso": {"pitch": 20}, "la": wrap, "ra": wrap,
                       "rf": {"z": .3, "y": .6}, "lf": {"z": .2, "y": .5}})
        else:
            sh.key(4, air({"root": {"pitch": -16}, "rf": {"z": -1.0, "y": 2.2, "toe": 10, "knee": 0}}), "ease")
            hit = air({"root": {"pitch": 26}, "torso": {"pitch": 20}, "rf": {"z": -1.1, "y": .5, "toe": 20, "knee": 0}})
        sh.key(9, hit, "impact")
        sh.key(16, hit, "ease")
        sh.key(34, s({"root": {"y": -.8}}), "ease")
        return sh.build(markers={"contact": 9 / 60, "recover": 21 / 60})
    return build


# ============================================================ techniques
def great_whirlwind(arm):
    """Leaf Great Whirlwind: across the gap in one spinning kick (the
    channel is almost nothing - a dip; the release is the spin)."""
    out = []
    ch = Shot(arm, N + "LeafGreatWhirlwind.Channel")
    ch.key(0, s(), "ease")
    ch.key(5, s({"root": {"y": -.7, "yaw": 80}}), "ease")
    out.append(ch.build(markers={"release": 5 / 60}))
    re = Shot(arm, N + "LeafGreatWhirlwind.Release")
    re.key(0, s({"root": {"y": -.7, "yaw": 80}}), "launch")
    spin = s({"root": {"y": -.3, "pitch": -10, "yaw": 200}, "la": {"raise": 30, "out": 60}, "ra": {"raise": 30, "out": 60},
              "rf": {"x": .2, "z": -1.5, "y": 1.6, "toe": 10, "knee": 0, "yaw": 200}})
    re.key(3, spin, "impact")
    out.append(re.build())
    rc = Shot(arm, N + "LeafGreatWhirlwind.Recover")
    rc.key(0, spin, "ease")
    rc.key(10, s({"root": {"yaw": 300}, "rf": {"x": .3, "z": .3, "y": .5, "knee": 10, "yaw": 300}}), "pass")
    rc.key(18, s({"root": {"yaw": 408}, "rf": {"yaw": 418}, "lf": {"yaw": 380}}), "ease")
    out.append(rc.build())
    return out


# ================================================================= states
def intro(arm):
    """Match intro: the nice-guy pose - thumbs up, the grin, a sparkle - then
    he drops into the Strong Fist stance, the lead hand out: 'come on'."""
    sh = Shot(arm, N + "Intro")
    nice = s({"root": {"y": -.1, "pitch": -2, "yaw": 20}, "torso": {"pitch": -8, "yaw": -4}, "head": {"pitch": -10, "yaw": -14},
              "la": {"raise": 70, "out": 30, "twist": -60, "elbow": 128, "wrist": 0}, "ra": {"raise": 96, "out": 10, "twist": -20, "elbow": 20, "wrist": 0},
              "rf": {"x": .2, "z": .5, "yaw": 20}, "lf": {"x": -.1, "z": -.5, "yaw": 0}})
    sh.key(0, nice, "ease")
    sh.key(80, merge(nice, {"ra": {"raise": 100}}), "ease")
    sh.key(100, s({"root": {"y": -.7}}), "ease")
    sh.key(112, s(), "ease")
    sh.key(124, s({"la": {"elbow": 40, "wrist": 0}}), "ease")
    sh.key(136, s({"la": {"elbow": 20, "wrist": -30}}), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 2)
    return sh.build()


def win(arm):
    """Victory: the Good Guy pose - thumb up, the other hand on the hip, the
    teeth flashing; then a fist pumped at the sky ('Youth!')."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    good = s({"root": {"y": -.08, "pitch": -2, "yaw": 10}, "torso": {"pitch": -8, "yaw": 0}, "head": {"pitch": -8, "yaw": -6},
              "ra": {"raise": 96, "out": 10, "twist": -20, "elbow": 10, "wrist": 0}, "la": {"raise": -10, "out": 40, "twist": -40, "elbow": 100, "wrist": 0},
              "rf": {"x": .24, "z": .2, "yaw": 10}, "lf": {"x": -.2, "z": -.2, "yaw": 0}})
    sh.key(20, good, "ease")
    sh.key(80, good, "ease")
    sh.key(94, merge(good, {"ra": {"raise": 170, "elbow": 10}, "head": {"pitch": -20}}), "impact")
    sh.key(150, merge(good, {"ra": {"raise": 166, "elbow": 14}, "head": {"pitch": -18}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build()


def awaken(arm):
    """Fifth Gate: he crosses his arms, the muscles lock, he roars - the
    skin reddens; the stance comes back lower and wider."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    cross = {"raise": 80, "out": -40, "twist": 30, "elbow": 110, "wrist": 0}
    sh.key(10, s({"root": {"y": -.7, "pitch": 14}, "torso": {"pitch": 14}, "head": {"pitch": 10}, "la": cross, "ra": cross}), "ease")
    sh.key(22, s({"root": {"y": -.5, "pitch": -6}, "torso": {"pitch": -14}, "head": {"pitch": -30},
                  "la": {"raise": 60, "out": 60, "elbow": 80}, "ra": {"raise": 60, "out": 60, "elbow": 80}}), "impact")
    sh.key(34, s({"root": {"y": -.64}, "rf": {"x": .4, "z": .8}}), "ease")
    sh.key(44, s({"root": {"y": -.64}, "rf": {"x": .4, "z": .8}}), "ease")
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), light1(arm), light2(arm), light3(arm), heavy(arm), knee_strike(arm), leaf_rising(arm), leaf_hurricane(arm),
             leaf_whirlwind(arm), flying_kick(arm), dash_attack(arm), air1(arm), air2(arm), air_drive(arm), air_spike(arm), air_switch(arm),
             lotus("PrimaryLotus", True)(arm), lotus("HiddenLotus", True)(arm), lotus("LeafHeel", False)(arm),
             intro(arm), win(arm), awaken(arm)]
    acts += great_whirlwind(arm)
    return acts
