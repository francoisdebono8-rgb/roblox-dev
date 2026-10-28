"""Partie 1 (DEC-030): Sasuke complete. Every move the game asks of him that
was still procedural, authored pose by pose and amplified, plus the jutsu
acted by the body (seals, inhale, projection) - same vocabulary as
clips_lion2 / kunai_lion (yaw + right, pitch + forward, roll + right; feet
WORLD, x right, z back, y lift).

Server frame data (startup / active / recovery, s) the contacts sit on:
  KneeStrike .080/.12/.30   LionKick .150/.14/.28   Sweep .120/.14/.34
  VaultKick  .120/.12/.24   FlyingKick .100/.16/.32
  AirDrive   .080/.13/.22   AirSpike  .090/.12/.24  AirSwitch .100/.14/.20
  PhoenixFlower channel .28 active .32 recovery .30
  WireTrap   channel .18 active .08 recovery .30
"""
from nd_shot import Shot, merge, mirror
from kunai_lion import STANCE, s, at

STANCE_R = mirror(STANCE)
AIR = {"root": {"y": -.5, "pitch": 14, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
       "la": {"raise": 60, "out": 40, "elbow": 90}, "ra": {"raise": 56, "out": 42, "elbow": 94},
       "rf": {"x": 0, "z": -.7, "y": 1.2, "toe": -24, "yaw": 0, "knee": 8}, "lf": {"x": 0, "z": -.45, "y": 1.05, "toe": -26, "yaw": 0, "knee": 6}}


# Air clips with the somersault knee rule (the legs swing through every axis).
AIR_T = merge(AIR, {})


# ------------------------------------------------------------------ idle
def idle(arm):
    """A ninja's guard is never still: a short bounce on the balls of the
    feet (0.8 s), the knees giving, the shoulders loose, the lead hand
    measuring the distance; every third beat the head checks the target."""
    sh = Shot(arm, "Lion.Idle")
    sh.key(0, s(), "ease")
    sh.key(12, s({"root": {"y": -.62, "z": -.04, "pitch": 12, "yaw": 31}, "torso": {"pitch": 8, "yaw": -13},
                  "la": {"raise": 62, "elbow": 70}, "ra": {"raise": 49, "elbow": 122},
                  "rf": {"toe": -8}, "lf": {"toe": -6}}), "ease")
    sh.key(24, s({"root": {"y": -.48}}), "ease")
    sh.key(36, s({"root": {"y": -.6, "z": .04, "pitch": 9, "yaw": 33}, "torso": {"pitch": 5, "yaw": -15}, "head": {"yaw": -20},
                  "la": {"raise": 68, "out": 2, "elbow": 60}, "ra": {"raise": 54, "elbow": 116}, "rf": {"toe": -6}}), "ease")
    sh.key(48, s(), "ease")
    sh.drag(["spine"], 2).drag(["neck", "shoulder.L", "shoulder.R"], 4)
    return sh.build(loop=True)


# ---------------------------------------------------------------- routes
def knee_strike(arm):
    """Heavy after one hit: the clinch knee. Both hands shoot out and catch
    the opponent's head (the grab is the wind-up), the rear knee drives up
    into the belly as the hands pull down, the support heel rises (a small
    hop forward). Knee back down behind, then the stance."""
    sh = Shot(arm, "Lion.KneeStrike")
    sh.key(0, s(), "ease")
    grab = s({"travel": {"z": -.2}, "root": {"y": -.56, "z": -.3, "pitch": 14, "yaw": 14}, "torso": {"pitch": 10, "yaw": -6}, "head": {"pitch": -10, "yaw": -8},
              "la": {"raise": 100, "out": -6, "twist": 0, "elbow": 30}, "ra": {"raise": 98, "out": -14, "twist": 0, "elbow": 34},
              "rf": {"y": .1, "toe": -30}})
    sh.key(3, grab, "ease")
    hit = s({"travel": {"z": -.45}, "root": {"y": -.3, "z": -.5, "pitch": -8, "yaw": 4}, "torso": {"pitch": 18, "yaw": -2}, "head": {"pitch": 4, "yaw": -4},
             "la": {"raise": 62, "out": -10, "elbow": 96, "wrist": 20}, "ra": {"raise": 60, "out": -16, "elbow": 100, "wrist": 20},
             "rf": {"x": .05, "z": -1.25, "y": 1.55, "toe": -40, "knee": 0, "yaw": 0}, "lf": {"y": .1, "toe": -40, "yaw": -10}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"y": -.26, "pitch": -10}, "rf": {"y": 1.65, "z": -1.3}}), "ease")
    sh.key(15, s({"travel": {"z": -.45}, "root": {"y": -.6, "z": -.2, "pitch": 12, "yaw": 22}, "rf": {"z": .4, "y": .3, "toe": -20},
                  "lf": {"z": -1.21}, "la": {"raise": 70, "elbow": 70}, "ra": {"raise": 56, "elbow": 110}}), "pass")
    sh.key(24, at(-.45), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def lion_kick(arm):
    """Up route (launcher of the Lion Combo): he dips almost to the floor,
    the lead hand brushing it, then the rear leg whips straight up past the
    opponent's chin while the support leg extends onto its toes and the
    whole body leans back under the kick - he will follow it up."""
    sh = Shot(arm, "Lion.LionKick")
    sh.key(0, s(), "ease")
    dip = s({"root": {"y": -1.15, "z": -.15, "pitch": 30, "yaw": 22}, "torso": {"pitch": 20, "yaw": -4}, "head": {"pitch": -34, "yaw": -10},
             "la": {"raise": 10, "out": 20, "elbow": 20, "wrist": 30}, "ra": {"raise": -30, "out": 24, "elbow": 40},
             "rf": {"y": .1, "toe": -34}})
    sh.key(5, dip, "ease")
    sh.key(7, s({"travel": {"z": -.15}, "root": {"y": -.6, "z": -.25, "pitch": 4, "yaw": 12}, "torso": {"pitch": 0},
                 "rf": {"x": -.15, "z": -1.0, "y": 1.3, "toe": -10, "knee": 0, "yaw": 0}, "lf": {"y": .12, "toe": -40},
                 "la": {"raise": 80, "out": 30, "elbow": 40}, "ra": {"raise": 60, "out": 40, "elbow": 50}}), "pass")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.05, "z": -.25, "pitch": -26, "yaw": 4}, "torso": {"pitch": -16, "yaw": -4}, "head": {"pitch": 14},
             "rf": {"x": -.25, "z": -1.3, "y": 3.5, "toe": 20, "knee": 0, "yaw": 0}, "lf": {"y": .22, "toe": -60, "yaw": -8},
             "la": {"raise": 160, "out": 26, "elbow": 20}, "ra": {"raise": 130, "out": 40, "elbow": 30}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"root": {"y": .05, "pitch": -30}, "rf": {"y": 3.7, "z": -1.0}}), "ease")
    sh.key(18, merge(hit, {"root": {"y": -.4, "pitch": -6}, "torso": {"pitch": -2}, "rf": {"y": 1.3, "z": -1.0, "toe": -10},
                           "la": {"raise": 90, "elbow": 50}, "ra": {"raise": 70, "elbow": 60}}), "pass")
    sh.key(24, merge(at(-.3), {"root": {"y": -.66}, "rf": {"z": .54 - .3, "y": 0}}), "impact")
    sh.key(34, at(-.3, {"rf": {"z": .24}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def sweep(arm):
    """Down route: the low spinning sweep. He drops on the lead leg until
    his hand touches the floor, the rear leg straight, and turns on the
    ball of the lead foot: the rear leg sweeps a half circle at ankle height
    under the opponent. Then back up into the stance, the free hand already
    at the pouch (a shuriken comes next)."""
    sh = Shot(arm, "Lion.Sweep")
    sh.key(0, s(), "ease")
    drop = s({"root": {"y": -1.55, "z": -.2, "pitch": 34, "yaw": 10}, "torso": {"pitch": 24, "yaw": 0}, "head": {"pitch": -40, "yaw": -6},
              "la": {"raise": -10, "out": 34, "elbow": 10, "wrist": 40}, "ra": {"raise": 40, "out": 20, "elbow": 80},
              "rf": {"x": .5, "z": 1.0, "y": .1, "toe": -20, "yaw": 50}, "lf": {"yaw": -30, "toe": -10}})
    sh.key(4, drop, "ease")
    hit = merge(drop, {"root": {"y": -1.6, "pitch": 28, "yaw": -60, "roll": -8}, "torso": {"pitch": 20, "yaw": 20}, "head": {"yaw": 40},
                       "rf": {"x": -.6, "z": -1.9, "y": .15, "toe": 0, "yaw": -60, "knee": 0}, "lf": {"yaw": -90, "toe": -16},
                       "ra": {"raise": 10, "out": 60, "elbow": 30}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": -110}, "rf": {"x": -1.9, "z": -.9, "yaw": -110}, "lf": {"yaw": -130}}), "ease")
    # The leg keeps going round behind him and plants where it started: a
    # full turn (yaw -330 is the stance's 30).
    sh.key(16, merge(drop, {"root": {"y": -1.35, "yaw": -230}, "torso": {"yaw": 14}, "head": {"yaw": 200},
                            "rf": {"x": -.4, "z": 1.3, "y": .15, "yaw": -230}, "lf": {"yaw": -250}}), "pass")
    sh.key(22, merge(drop, {"root": {"y": -.95, "yaw": -320, "pitch": 20}, "torso": {"yaw": -6, "pitch": 12}, "head": {"yaw": 10, "pitch": -20},
                            "rf": {"x": .26, "z": .84, "y": 0, "yaw": -322, "toe": 0}, "lf": {"yaw": -366, "toe": 0}}), "impact")
    sh.key(34, s({"root": {"yaw": -330}, "rf": {"yaw": -322}, "lf": {"yaw": -366}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def vault_kick(arm):
    """Side route: a short vault to the side - he plants and springs off the
    lead foot, the body turning in the air, and the left heel hooks round
    into the opponent's back; lands a step to the side."""
    sh = Shot(arm, "Lion.VaultKick")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.95, "z": -.1, "pitch": 18, "yaw": 50, "roll": 12}, "torso": {"pitch": 14, "yaw": -10, "roll": 6},
                 "head": {"pitch": -24, "yaw": -40}, "rf": {"y": .1, "toe": -30},
                 "la": {"raise": 30, "out": 40, "elbow": 60}, "ra": {"raise": 20, "out": 50, "elbow": 60}}), "ease")
    air = {"travel": {"x": .8, "z": -.2}, "root": {"y": .35, "z": -.2, "pitch": 4, "yaw": 150, "roll": 20}, "torso": {"pitch": 6, "yaw": -40, "roll": 10},
           "head": {"pitch": -10, "yaw": -100},
           "lf": {"x": .2, "z": -2.4, "y": 1.9, "toe": 10, "knee": 0, "yaw": 160}, "rf": {"x": 1.1, "z": .3, "y": 1.0, "toe": -40, "yaw": 150},
           "la": {"raise": 20, "out": 70, "elbow": 20}, "ra": {"raise": 60, "out": 60, "elbow": 40}}
    sh.key(7, s(air), "impact")
    sh.key(10, s(merge(air, {"root": {"yaw": 190}, "lf": {"x": -.4, "z": -2.2, "yaw": 190}, "head": {"yaw": -130}})), "ease")
    sh.key(16, s({"travel": {"x": 1.5, "z": -.3}, "root": {"y": -.75, "yaw": 300}, "torso": {"yaw": -6}, "head": {"yaw": 50},
                  "rf": {"x": 1.76, "z": .54, "yaw": 300}, "lf": {"x": 1.4, "z": -1.06, "yaw": 290}}), "impact")
    sh.key(26, s({"travel": {"x": 1.5, "z": -.3}, "root": {"yaw": 390}, "rf": {"x": 1.76, "z": .54, "yaw": 398}, "lf": {"x": 1.4, "z": -1.06, "yaw": 354}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def flying_kick(arm):
    """Run strike: out of the sprint he leaps, the body flat, the lead leg
    driving a side kick through the opponent, the other leg tucked under,
    the arms thrown back for the flight; lands on the kicking leg."""
    sh = Shot(arm, "Lion.FlyingKick")
    run = {"root": {"y": -.72, "pitch": 34, "yaw": 0}, "torso": {"pitch": 22, "yaw": 0}, "head": {"pitch": -48, "yaw": 0},
           "la": {"raise": -62, "out": 16, "twist": -12, "elbow": 12}, "ra": {"raise": -62, "out": 16, "twist": -12, "elbow": 12},
           "rf": {"x": .04, "z": -.6, "y": 0, "toe": 4, "yaw": 0}, "lf": {"x": -.04, "z": .9, "y": .6, "toe": -50, "yaw": 0}}
    sh.key(0, run, "ease")
    sh.key(3, merge(run, {"travel": {"z": -.8}, "root": {"y": -.2, "pitch": 10, "yaw": 30}, "rf": {"z": -1.2, "y": .2, "toe": -60},
                          "lf": {"z": -1.5, "y": 1.3, "toe": -20, "knee": 0}}), "launch")
    hit = {"travel": {"z": -1.8}, "root": {"y": .5, "z": -.3, "pitch": -12, "yaw": 72, "roll": -6}, "torso": {"pitch": -4, "yaw": -26}, "head": {"pitch": -6, "yaw": -66},
           "lf": {"x": -.2, "z": -4.3, "y": 2.2, "toe": 30, "knee": 0, "yaw": 80}, "rf": {"x": .2, "z": -1.6, "y": 1.4, "toe": -50, "yaw": 70, "knee": 30},
           "la": {"raise": 60, "out": 20, "elbow": 90}, "ra": {"raise": -30, "out": 50, "elbow": 20}}
    sh.key(6, merge(run, hit), "impact")
    sh.key(10, merge(run, merge(hit, {"travel": {"z": -2.4}, "root": {"y": .35}, "lf": {"z": -4.8, "y": 1.9}, "rf": {"z": -2.3, "y": 1.2}})), "ease")
    T = -3.2
    sh.key(16, merge(at(T), {"root": {"y": -.95, "pitch": 18, "yaw": 40}, "lf": {"x": -.1, "z": -.76 + T},
                             "rf": {"x": .3, "z": .4 + T, "y": .25, "toe": -30}, "la": {"raise": 60, "out": 40}, "ra": {"raise": 30, "out": 50}}), "impact")
    sh.key(28, at(T), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 13 / 60})


# ------------------------------------------------------------ air routes
def air_drive(arm):
    """Air forward: the dropkick - both knees to the chest, then both legs
    drive out together while the back arches away (action / reaction)."""
    AIR = merge(AIR_T, {})
    sh = Shot(arm, "Lion.AirDrive")
    sh.key(0, AIR, "ease")
    sh.key(3, merge(AIR, {"root": {"pitch": 26}, "torso": {"pitch": 24}, "rf": {"z": -.6, "y": 1.45, "toe": -10}, "lf": {"z": -.5, "y": 1.4, "toe": -10},
                          "la": {"raise": 80, "out": 40, "elbow": 100}, "ra": {"raise": 80, "out": 40, "elbow": 100}}), "ease")
    hit = merge(AIR, {"root": {"y": -.15, "pitch": -40}, "torso": {"pitch": -14}, "head": {"pitch": 16},
                      "rf": {"x": .25, "z": -2.4, "y": .55, "toe": 30, "knee": 0}, "lf": {"x": -.25, "z": -2.3, "y": .65, "toe": 30, "knee": 0},
                      "la": {"raise": -20, "out": 60, "elbow": 20}, "ra": {"raise": -20, "out": 60, "elbow": 20}})
    sh.key(4, merge(AIR, {"root": {"pitch": -6}, "torso": {"pitch": 6}, "rf": {"x": .15, "z": -1.5, "y": 1.0, "toe": 10}, "lf": {"x": -.15, "z": -1.4, "y": 1.05, "toe": 10},
                          "la": {"raise": 20, "out": 60, "elbow": 50}, "ra": {"raise": 20, "out": 60, "elbow": 50}}), "pass")
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"root": {"pitch": -46}, "rf": {"z": -2.5}, "lf": {"z": -2.4}}), "ease")
    sh.key(22, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def air_spike(arm):
    """Air down: the falling heel. The straight leg swings up past the face,
    the body rolls forward over it, and the heel comes down like an axe."""
    AIR = merge(AIR_T, {})
    sh = Shot(arm, "Lion.AirSpike")
    sh.key(0, AIR, "ease")
    up = merge(AIR, {"root": {"y": -.2, "pitch": -24}, "torso": {"pitch": -12}, "head": {"pitch": 10},
                     "rf": {"x": -.1, "z": -1.2, "y": 3.4, "toe": 10, "knee": 0}, "lf": {"z": .5, "y": .4, "toe": -40},
                     "la": {"raise": 30, "out": 70, "elbow": 20}, "ra": {"raise": 20, "out": 74, "elbow": 20}})
    sh.key(3, up, "launch")
    hit = merge(AIR, {"root": {"y": -.55, "pitch": 52}, "torso": {"pitch": 30}, "head": {"pitch": -10},
                      "rf": {"x": -.1, "z": -1.9, "y": .1, "toe": 30, "knee": 0}, "lf": {"z": .8, "y": 1.2, "toe": -40},
                      "la": {"raise": 40, "out": 30, "elbow": 50}, "ra": {"raise": 30, "out": 30, "elbow": 50}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"pitch": 58}, "rf": {"y": -.05}}), "ease")
    sh.key(22, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def air_switch(arm):
    """Air side: a full turn in the air - the body spins round its own axis,
    the left heel opens on the way and hooks through the target, and he
    comes out of the turn facing it again on the other side."""
    AIR = merge(AIR_T, {})
    sh = Shot(arm, "Lion.AirSwitch")
    sh.key(0, AIR, "ease")
    sh.key(1, merge(AIR, {"root": {"yaw": 30}, "rf": {"yaw": 30}, "lf": {"yaw": 30}, "head": {"yaw": -25}}), "pass")
    sh.key(3, merge(AIR, {"root": {"yaw": 110, "roll": 6}, "torso": {"yaw": -10}, "head": {"yaw": -80},
                          "rf": {"yaw": 110}, "lf": {"yaw": 110},
                          "la": {"raise": 40, "out": -20, "elbow": 110}, "ra": {"raise": 40, "out": -20, "elbow": 110}}), "pass")
    hit = merge(AIR, {"root": {"yaw": 215, "roll": 18, "pitch": 2}, "torso": {"yaw": -16, "roll": 8}, "head": {"yaw": -170},
                      "lf": {"x": 1.6, "z": -1.4, "y": 1.9, "toe": 10, "knee": 0, "yaw": 215}, "rf": {"yaw": 215, "z": .2, "y": 1.2},
                      "la": {"raise": 10, "out": 70, "elbow": 20}, "ra": {"raise": 30, "out": 70, "elbow": 30}})
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": 290, "roll": 10}, "head": {"yaw": -260}, "lf": {"x": .4, "z": -1.6, "yaw": 290}}), "ease")
    sh.key(20, merge(AIR, {"root": {"yaw": 360}, "rf": {"yaw": 360}, "lf": {"yaw": 360}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def lion_barrage(arm):
    """Lion Combo finisher (Slam timing .15/.20/.38): above the launched body
    he rolls back with the right leg thrown straight up over his head, hangs
    a beat, then crunches forward and drives the heel down through the body
    toward the floor - the whole body follows the leg."""
    AIR = merge(AIR_T, {})
    sh = Shot(arm, "Lion.LionBarrage")
    sh.key(0, AIR, "ease")
    up = merge(AIR, {"root": {"y": -.1, "pitch": -34}, "torso": {"pitch": -16}, "head": {"pitch": 18},
                     "rf": {"x": -.1, "z": -1.3, "y": 3.4, "toe": 10, "knee": 0}, "lf": {"z": .5, "y": .3, "toe": -40},
                     "la": {"raise": 150, "out": 40, "elbow": 20}, "ra": {"raise": 140, "out": 44, "elbow": 20}})
    sh.key(5, up, "launch")
    sh.key(7, merge(up, {"root": {"pitch": -30}, "rf": {"z": -1.5, "y": 3.4}}), "ease")
    hit = merge(AIR, {"root": {"y": -.7, "pitch": 62}, "torso": {"pitch": 34}, "head": {"pitch": -16},
                      "rf": {"x": -.1, "z": -2.1, "y": .4, "toe": 20, "knee": 0}, "lf": {"z": .7, "y": 1.0, "toe": -40},
                      "la": {"raise": 20, "out": 50, "elbow": 40}, "ra": {"raise": 10, "out": 50, "elbow": 40}})
    sh.key(9, hit, "impact")
    sh.key(13, merge(hit, {"root": {"pitch": 68, "y": -.8}, "rf": {"y": .2}}), "ease")
    sh.key(28, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 9 / 60, "recover": 18 / 60})


# ------------------------------------------------------------- the jutsu
WIDE = {"root": {"y": -.74, "z": 0, "pitch": 6, "yaw": 34}, "torso": {"pitch": 2, "yaw": -18}, "head": {"pitch": -4, "yaw": -14},
        "rf": {"x": .45, "z": .95, "yaw": 45}, "lf": {"x": -.25, "z": -.85, "yaw": -8}}


def seal(name):
    """Hand seals at the chest (both hands together, the fingers in the shape
    of the seal): the arms differ enough per seal to read as a sequence."""
    base = {"la": {"raise": 64, "out": -36, "twist": 34, "elbow": 112, "wrist": 10}, "ra": {"raise": 64, "out": -36, "twist": 34, "elbow": 112, "wrist": 10}}
    var = {"tiger": {"la": {"raise": 72, "elbow": 104}, "ra": {"raise": 72, "elbow": 104}},
           "snake": {"la": {"twist": 60, "elbow": 118}, "ra": {"twist": 10, "raise": 58, "elbow": 118}},
           "ram": {"la": {"raise": 56, "elbow": 120}, "ra": {"raise": 76, "elbow": 98, "twist": 50}},
           "horse": {"la": {"raise": 80, "out": -26, "elbow": 96, "wrist": 30}, "ra": {"raise": 80, "out": -26, "elbow": 96, "wrist": 30}},
           "boar": {"la": {"raise": 54, "twist": 70, "elbow": 124}, "ra": {"raise": 54, "twist": 0, "elbow": 124}}}
    return merge(base, var[name])


def katon(arm):
    """Great Fireball, acted: ram - horse - tiger snapped in
    0.2 s, the stance widening; the big inhale (chest up and back,
    head back, the body sits over the rear foot); the ringed hand comes to
    the mouth; then everything goes forward over the front foot at once and
    stays there while the fire pours out."""
    out = []
    ch = Shot(arm, "Lion.FireBloom.Channel")
    ch.key(0, s(), "ease")
    # (Partie 1 feedback: five seals were too long to ever land it.) Three
    # snapped seals, ram - horse - tiger, like the Storm games' quick cast;
    # the full sequence is for the held (charged) version.
    for f, n in ((4, "ram"), (8, "horse"), (12, "tiger")):
        ch.key(f, s(merge(WIDE, seal(n))), "pass")
    inhale = s(merge(WIDE, {"root": {"y": -.62, "z": .25, "pitch": -12}, "torso": {"pitch": -22}, "head": {"pitch": 26},
                            "ra": {"raise": 100, "out": -42, "twist": 60, "elbow": 132, "wrist": 0},
                            "la": {"raise": 40, "out": 20, "twist": 20, "elbow": 80}}))
    ch.key(19, inhale, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 19 / 60}))
    ho = Shot(arm, "Lion.FireBloom.Hold")
    ho.key(0, inhale, "ease")
    ho.key(20, merge(inhale, {"root": {"y": -.66, "z": .3}, "torso": {"pitch": -25}, "head": {"pitch": 28}}), "ease")
    ho.key(40, inhale, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))
    re = Shot(arm, "Lion.FireBloom.Release")
    blow = s(merge(WIDE, {"root": {"y": -.86, "z": -.5, "pitch": 28}, "torso": {"pitch": 24}, "head": {"pitch": -14},
                          "ra": {"raise": 104, "out": -38, "twist": 60, "elbow": 132},
                          "la": {"raise": -10, "out": 40, "twist": 0, "elbow": 30}, "rf": {"y": .12, "toe": -30}}))
    re.key(0, inhale, "launch")
    re.key(4, blow, "impact")
    re.key(14, merge(blow, {"root": {"z": -.56, "pitch": 31}, "torso": {"pitch": 26}}), "ease")
    re.key(24, merge(blow, {"root": {"z": -.52, "pitch": 29}}), "ease")
    out.append(re.build(markers={"release": 4 / 60}))
    rc = Shot(arm, "Lion.FireBloom.Recover")
    rc.key(0, merge(blow, {"root": {"z": -.52, "pitch": 29}}), "ease")
    rc.key(10, s(merge(WIDE, {"root": {"y": -.66, "pitch": 10}, "rf": {"y": 0, "toe": 0}, "head": {"pitch": -8}})), "pass")
    rc.key(22, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


def phoenix(arm):
    """Phoenix Flower: two quick seals, a short inhale, then the head and
    chest pump three times - one burst of small fireballs each, spread left,
    centre, right - with the hand ring at the mouth."""
    out = []
    ch = Shot(arm, "Lion.PhoenixFlower.Channel")
    ch.key(0, s(), "ease")
    ch.key(5, s(merge(WIDE, seal("snake"))), "pass")
    ch.key(10, s(merge(WIDE, seal("tiger"))), "pass")
    inhale = s(merge(WIDE, {"root": {"y": -.66, "z": .18, "pitch": -8}, "torso": {"pitch": -16}, "head": {"pitch": 20},
                            "ra": {"raise": 100, "out": -42, "twist": 60, "elbow": 132}, "la": {"raise": 50, "out": 10, "elbow": 90}}))
    ch.key(17, inhale, "ease")
    out.append(ch.build(markers={"release": 17 / 60}))
    re = Shot(arm, "Lion.PhoenixFlower.Release")

    def puff(yaw, lean):
        return s(merge(WIDE, {"root": {"y": -.8, "z": -.3, "pitch": 18 + lean, "yaw": 34 + yaw}, "torso": {"pitch": 16 + lean, "yaw": -18 + yaw}, "head": {"pitch": -10, "yaw": -14 + yaw},
                              "ra": {"raise": 102, "out": -40, "twist": 60, "elbow": 132}, "la": {"raise": 20, "out": 30, "elbow": 60}}))
    re.key(0, inhale, "launch")
    re.key(3, puff(-16, 4), "impact")
    re.key(7, puff(-12, -4), "ease")
    re.key(10, puff(0, 6), "impact")
    re.key(14, puff(2, -4), "ease")
    re.key(17, puff(16, 6), "impact")
    re.key(24, puff(14, 0), "ease")
    out.append(re.build(markers={"release": 3 / 60}))
    rc = Shot(arm, "Lion.PhoenixFlower.Recover")
    rc.key(0, puff(14, 0), "ease")
    rc.key(10, s(merge(WIDE, {"root": {"y": -.64}})), "pass")
    rc.key(20, s(), "ease")
    out.append(rc.build())
    return out


def wire_trap(arm):
    """Wire Trap: a wired shuriken thrown hard from the hip, the wire paid
    out by the other hand; then both hands haul the wire taut across the
    body, the rear foot braced - and the wire comes up to the teeth (the
    Dragon Flame is ready)."""
    out = []
    ch = Shot(arm, "Lion.WireTrap.Channel")
    ch.key(0, s(), "ease")
    wind = s({"root": {"y": -.7, "pitch": 12, "yaw": 60}, "torso": {"pitch": 6, "yaw": 30}, "head": {"yaw": -70, "pitch": -8},
              "ra": {"raise": 20, "out": -40, "twist": 40, "elbow": 110, "wrist": 30}, "la": {"raise": 50, "out": 20, "elbow": 60},
              "rf": {"y": .08, "toe": -24}})
    ch.key(10, wind, "ease")
    out.append(ch.build(markers={"release": 10 / 60}))
    re = Shot(arm, "Lion.WireTrap.Release")
    throw = s({"travel": {"z": -.2}, "root": {"y": -.66, "z": -.35, "pitch": 18, "yaw": -10}, "torso": {"pitch": 10, "yaw": -40}, "head": {"yaw": 30, "pitch": -10},
               "ra": {"raise": 90, "out": 30, "twist": -30, "elbow": 4, "wrist": -30}, "la": {"raise": 30, "out": 40, "elbow": 40},
               "rf": {"y": .12, "toe": -34}, "lf": {"z": -1.0}})
    re.key(0, wind, "launch")
    re.key(4, throw, "impact")
    re.key(10, merge(throw, {"torso": {"yaw": -46}, "ra": {"out": 40}}), "ease")
    out.append(re.build(markers={"release": 4 / 60}))
    rc = Shot(arm, "Lion.WireTrap.Recover")
    haul = s({"travel": {"z": -.2}, "root": {"y": -.8, "z": .1, "pitch": -2, "yaw": 40}, "torso": {"pitch": -6, "yaw": -10}, "head": {"pitch": -6, "yaw": -30},
              "ra": {"raise": 40, "out": -20, "twist": 0, "elbow": 100, "wrist": 0}, "la": {"raise": 10, "out": 40, "elbow": 50},
              "rf": {"z": .84 - .2 + .2, "toe": 0}, "lf": {"z": -1.0}})
    rc.key(0, throw, "ease")
    rc.key(6, haul, "impact")
    rc.key(14, merge(haul, {"ra": {"raise": 100, "out": -40, "twist": 60, "elbow": 132}, "head": {"pitch": -2}}), "ease")
    rc.key(22, merge(haul, {"ra": {"raise": 100, "out": -40, "twist": 60, "elbow": 132}, "root": {"y": -.76}}), "ease")
    out.append(rc.build())
    return out


# --------------------------------------------------------- intro / awaken
def intro(arm):
    """Match intro (2.6 s): hands in his pockets, chin up, bored. The head
    turns to the opponent, the hands come out, a step back, and he drops
    into his guard drawing the kunai from the thigh and back - ready."""
    sh = Shot(arm, "Lion.Intro")
    cool = {"root": {"y": -.08, "pitch": -2, "yaw": 10}, "torso": {"pitch": -4, "yaw": -6}, "head": {"pitch": -8, "yaw": 30},
            "ra": {"raise": -6, "out": 14, "twist": -30, "elbow": 60, "wrist": 0}, "la": {"raise": -6, "out": 14, "twist": -30, "elbow": 60, "wrist": 0},
            "rf": {"x": .1, "z": .2, "yaw": 10}, "lf": {"x": -.1, "z": -.2, "yaw": 0}}
    sh.key(0, cool, "ease")
    sh.key(40, merge(cool, {"head": {"yaw": -14, "pitch": -12}}), "ease")
    sh.key(70, merge(cool, {"head": {"yaw": -14, "pitch": -12}, "root": {"y": -.12}}), "ease")
    sh.key(84, merge(cool, {"root": {"y": -.3, "yaw": 20}, "head": {"yaw": -20}, "ra": {"raise": 10, "out": 20, "elbow": 20}, "la": {"raise": 30, "out": 10, "elbow": 40},
                            "rf": {"x": .2, "z": .7, "y": .3, "toe": -20}}), "pass")
    draw = s({"root": {"y": -.8, "pitch": 14, "yaw": 40}, "torso": {"pitch": 8, "yaw": -10}, "head": {"yaw": -26, "pitch": -12},
              "ra": {"raise": -20, "out": 24, "twist": 30, "elbow": 30, "wrist": -20}, "la": {"raise": 70, "out": -20, "elbow": 50}})
    sh.key(94, draw, "impact")
    sh.key(104, s({"root": {"y": -.66}, "ra": {"raise": 70, "out": 10, "twist": 0, "elbow": 80, "wrist": -30}}), "pass")
    sh.key(118, s(), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def awaken(arm):
    """Curse Mark: the seal burns - the right hand clutches the left side of
    the neck, the body folds over the pain, then the back arches and the
    head goes back (the marks spread), and he drops into the low, hungry
    curse guard."""
    sh = Shot(arm, "Lion.Awaken")
    sh.key(0, s(), "ease")
    clutch = s({"root": {"y": -.9, "pitch": 30, "yaw": 20}, "torso": {"pitch": 26, "yaw": -6, "roll": -10}, "head": {"pitch": 20, "yaw": -10},
                "ra": {"raise": 110, "out": -60, "twist": 40, "elbow": 140, "wrist": 20}, "la": {"raise": -20, "out": 30, "elbow": 60}})
    sh.key(6, clutch, "impact")
    sh.key(14, merge(clutch, {"root": {"y": -.95}, "torso": {"roll": -14}}), "ease")
    arch = s({"root": {"y": -.4, "pitch": -12, "yaw": 20}, "torso": {"pitch": -26}, "head": {"pitch": 36, "yaw": 0},
              "ra": {"raise": -30, "out": 50, "elbow": 40}, "la": {"raise": -30, "out": 50, "elbow": 40}})
    sh.key(22, arch, "impact")
    sh.key(30, merge(arch, {"torso": {"pitch": -30}, "head": {"pitch": 40}}), "ease")
    curse = s({"root": {"y": -1.0, "z": -.15, "pitch": 30, "yaw": 26}, "torso": {"pitch": 22, "yaw": -8}, "head": {"pitch": -34, "yaw": -18},
               "la": {"raise": 50, "out": 30, "elbow": 40, "wrist": 20}, "ra": {"raise": 30, "out": 40, "elbow": 60, "wrist": 20},
               "rf": {"x": .4, "z": .95}, "lf": {"x": -.2, "z": -.85}})
    sh.key(38, curse, "impact")
    sh.key(48, curse, "ease")
    sh.drag(["neck"], 1)
    return sh.build()


def win(arm):
    """Victory (Partie 2): the anime's "Hmph". He comes out of the guard
    (straightens, 0.25 s), turns his back on the beaten opponent with one
    step (the rear foot crosses, the body pivots right), the hands go into
    the pockets, and the head turns back over the shoulder for a last look;
    held. Reference: Sasuke's exits in Naruto ep. 18-19 (vs Haku's mirrors
    aftermath) and his Storm 4 win pose (back turned, glance)."""
    sh = Shot(arm, "Lion.Win")
    sh.key(0, s(), "ease")
    up = {"root": {"y": -.16, "pitch": 0, "yaw": 26}, "torso": {"pitch": -2, "yaw": -8}, "head": {"pitch": -8, "yaw": -20},
          "ra": {"raise": 10, "out": 14, "twist": -10, "elbow": 30, "wrist": 0}, "la": {"raise": 10, "out": 14, "twist": -10, "elbow": 30, "wrist": 0},
          "rf": {"x": .26, "z": .6, "yaw": 30}, "lf": {"x": -.1, "z": -.6, "yaw": 0}}
    sh.key(14, up, "ease")
    step = merge(up, {"root": {"y": -.22, "yaw": 70}, "torso": {"yaw": -14}, "head": {"yaw": -50},
                      "rf": {"x": .1, "z": .1, "y": .25, "yaw": 70}})
    sh.key(24, step, "pass")
    cool = {"root": {"y": -.08, "pitch": -3, "yaw": 112}, "torso": {"pitch": -5, "yaw": -12}, "head": {"pitch": -10, "yaw": -62},
            "ra": {"raise": -6, "out": 14, "twist": -30, "elbow": 60, "wrist": 0}, "la": {"raise": -6, "out": 14, "twist": -30, "elbow": 60, "wrist": 0},
            "rf": {"x": .22, "z": -.18, "yaw": 112}, "lf": {"x": -.14, "z": -.42, "yaw": 96}}
    sh.key(36, merge(cool, {"head": {"yaw": -30}}), "ease")
    sh.key(60, cool, "ease")
    sh.key(110, merge(cool, {"root": {"y": -.1}, "head": {"yaw": -66, "pitch": -12}}), "ease")
    sh.key(150, cool, "ease")
    sh.drag(["neck"], 4).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(markers={"hold": 60 / 60})


def author(arm):
    acts = [idle(arm), knee_strike(arm), lion_kick(arm), sweep(arm), vault_kick(arm), flying_kick(arm),
            air_drive(arm), air_spike(arm), air_switch(arm), lion_barrage(arm), intro(arm), awaken(arm), win(arm)]
    acts += katon(arm)
    acts += phoenix(arm)
    acts += wire_trap(arm)
    return acts
