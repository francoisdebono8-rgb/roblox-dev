"""Partie 5 (DEC-030): Naruto (Legion), authored on the control rig.

His bible (docs/characters/NARUTO.md): overwhelm from several origins of
blows while keeping a real, impulsive body with a readable wind-up. Fists a
little low, shoulders forward, a wide base, the weight hopping from foot to
foot; he advances with his whole body, recovers less cleanly, and his
clones carry the routes from real places (behind, under, beside the target).
References: Naruto vs Neji (Chunin finals, ep. 59-61) and vs Kiba (ep. 45)
for the brawling body and the clone combos, vs Sasuke at the Valley (ep.
132-134) for the Uzumaki Barrage / Rendan, Storm 4 for the timing.

Same vocabulary as clips_lion2. Server frame data (startup with his profile):
  Light1 .085  Light2 .096  Light3 .122  Heavy .30  Headbutt .10  Tackle .12
  CloneKick .15 (Naruto steps out, the clone kicks: CloneKickStrike)
  UzumakiKick .16 (the clone under him: UzumakiRise)  MirrorClone .11 (MirrorStrike)
  Launcher .17 (solo route)  DashAttack .067  Air1 .076 Air2 .085
  AirDrive .08 AirSpike .09 AirSwitch .10  NarutoRendan (Slam) .15 / .20
  Rasengan .10 / .12 / .48   ShadowClone ch .18  CloneRasengan ch .45
  MassShadowClone ch .30
"""
from nd_shot import Shot, merge, mirror
from gait_from_lion import gait, scaler

N = "Legion."
STANCE = {"root": {"y": -.46, "z": -.06, "pitch": 12, "yaw": 20}, "torso": {"pitch": 10, "yaw": -8},
          "head": {"pitch": -10, "yaw": -12},
          "la": {"raise": 40, "out": 10, "twist": 20, "elbow": 96, "wrist": 0},
          "ra": {"raise": 30, "out": 14, "twist": 26, "elbow": 112, "wrist": 0},
          "rf": {"x": .34, "z": .72, "yaw": 34}, "lf": {"x": -.18, "z": -.66, "yaw": -8}}
GUARD = {"la": {"raise": 46, "out": 10, "twist": 20, "elbow": 94}, "ra": {"raise": 36, "out": 14, "twist": 26, "elbow": 110}}
AIR = {"root": {"y": -.5, "pitch": 14, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
       "la": {"raise": 60, "out": 40, "elbow": 90}, "ra": {"raise": 56, "out": 42, "elbow": 94},
       "rf": {"x": .05, "z": -.6, "y": 1.1, "toe": -24, "yaw": 0, "knee": 8}, "lf": {"x": -.05, "z": -.4, "y": 1.0, "toe": -26, "yaw": 0, "knee": 6}}
CROSS = {"la": {"raise": 78, "out": -34, "twist": 40, "elbow": 110, "wrist": 0},
         "ra": {"raise": 82, "out": -30, "twist": 20, "elbow": 100, "wrist": 0}}  # the cross seal (index + middle fingers crossed)


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .72 + T}, "lf": {"z": -.66 + T}})
    return merge(base, over or {})


def air(over=None):
    return merge(AIR, over or {})


def locomotion(arm):
    """Sasuke's gait mechanics, Naruto's body: the shoulders thrown forward
    (+6 torso pitch), the chest swinging MORE with the legs (insistent),
    the arms pumping a little wider."""
    return gait(arm, N, STANCE, GUARD, scaler(torso_yaw=1.25, torso_pitch=1.1, root_pitch=1.05, add={"torso": {"pitch": 6}}),
                arms={"walk": 1.0, "run": 1.1, "jump": 1.1})


def idle(arm):
    """Can't keep still: the weight hops from one foot to the other (0.9 s),
    the fists bounce, the head bobs; every second beat he rolls a shoulder."""
    sh = Shot(arm, N + "Idle")
    sh.key(0, s(), "ease")
    sh.key(14, s({"root": {"y": -.52, "z": .04, "roll": 3}, "rf": {"toe": -6}, "lf": {"y": .06, "toe": -14},
                  "la": {"raise": 36}, "ra": {"raise": 26}}), "ease")
    sh.key(27, s({"root": {"y": -.42}}), "ease")
    sh.key(41, s({"root": {"y": -.52, "z": -.1, "roll": -3}, "lf": {"toe": -6}, "rf": {"y": .06, "toe": -14},
                  "torso": {"roll": 4}, "ra": {"raise": 40, "twist": 40}}), "ease")
    sh.key(54, s(), "ease")
    sh.drag(["neck"], 3).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(loop=True)


# ================================================================ strikes
def light1(arm):
    """L1, a compact right hook: half a step in (0.5) with the shoulder's
    weight behind it, the hips turn, the elbow stays bent - frank, no
    finesse, the left fist stays up."""
    sh = Shot(arm, N + "Light1")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.5, "yaw": 34}, "torso": {"yaw": 6}, "ra": {"raise": 60, "out": 40, "twist": 0, "elbow": 100}, "lf": {"y": .1}}), "ease")
    hit = s({"travel": {"z": -.5}, "root": {"y": -.5, "z": -.2, "pitch": 14, "yaw": -6}, "torso": {"pitch": 12, "yaw": -24},
             "ra": {"raise": 86, "out": -30, "twist": -10, "elbow": 70, "wrist": 0}, "la": {"raise": 50, "out": 0, "elbow": 110},
             "lf": {"z": -1.16, "y": 0}, "rf": {"toe": -26}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"torso": {"yaw": -32}, "ra": {"out": -40}}), "ease")
    sh.key(20, at(-.5, {"rf": {"z": .4}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def light2(arm):
    """L2, a left straight to the stomach: he dips, the rear foot rejoins
    0.4 behind, the left fist drives straight into the gut - pressing."""
    sh = Shot(arm, N + "Light2")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.6, "yaw": 10}, "la": {"raise": 20, "elbow": 120}}), "ease")
    hit = s({"travel": {"z": -.4}, "root": {"y": -.66, "z": -.22, "pitch": 18, "yaw": 34}, "torso": {"pitch": 14, "yaw": 0},
             "la": {"raise": 72, "out": -6, "twist": 0, "elbow": 6, "wrist": 0}, "ra": {"raise": 40, "elbow": 120},
             "rf": {"z": .32}, "lf": {"z": -1.06}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"z": -.26}}), "ease")
    sh.key(20, at(-.4), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def light3(arm):
    """L3 solo (no clone): a two-handed shove - he steps out 0.4 to the side
    and pushes with both palms; with a clone it is CloneKick."""
    sh = Shot(arm, N + "Light3")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.58}, "la": {"raise": 50, "elbow": 120}, "ra": {"raise": 50, "elbow": 120}}), "ease")
    push = {"raise": 84, "out": -4, "twist": 0, "elbow": 8, "wrist": 50}
    hit = s({"travel": {"z": -.4}, "root": {"y": -.5, "z": -.3, "pitch": 16, "yaw": 6}, "torso": {"pitch": 10, "yaw": -4},
             "la": push, "ra": push, "lf": {"z": -1.06}})
    sh.key(7, hit, "impact")
    sh.key(11, merge(hit, {"root": {"z": -.34}}), "ease")
    sh.key(24, at(-.4), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 14 / 60})


def clone_kick(arm):
    """L3 with a clone: Naruto himself steps OUT (0.4, to his left) and
    points the way - the clone that comes from behind the target lands the
    kick (CloneKickStrike)."""
    sh = Shot(arm, N + "CloneKick")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.5, "yaw": 0}, "lf": {"x": -.6, "z": -.5, "y": .2}}), "pass")
    point = s({"travel": {"z": 0}, "root": {"y": -.48, "yaw": -10}, "head": {"yaw": 10},
               "la": {"raise": 90, "out": 30, "elbow": 6, "wrist": 0}, "ra": {"raise": 30, "out": 30, "elbow": 110},
               "lf": {"x": -.7, "z": -.5, "y": 0}})
    sh.key(9, point, "impact")
    sh.key(24, s({"lf": {"x": -.7, "z": -.5}}), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def clone_kick_strike(arm):
    """The clone's kick from behind the target: a jumping roundhouse - it
    arrives in the air, the hips whip round and the shin lands on the ribs."""
    sh = Shot(arm, N + "CloneKickStrike")
    sh.key(0, s({"root": {"y": -.7, "yaw": 40}}), "ease")
    sh.key(5, s({"root": {"y": -.2, "yaw": 80}, "rf": {"x": .5, "z": .5, "y": .8, "toe": -20}, "la": {"raise": 60, "out": 50}}), "pass")
    hit = s({"root": {"y": -.2, "pitch": -6, "yaw": -40, "roll": -16}, "torso": {"yaw": -20},
             "rf": {"x": .2, "z": -1.3, "y": 1.5, "toe": 10, "yaw": -60}, "la": {"raise": 40, "out": 70}, "ra": {"raise": 30, "out": 60}})
    sh.key(9, hit, "impact")
    sh.key(13, merge(hit, {"root": {"yaw": -60}}), "ease")
    sh.key(26, s({"root": {"yaw": -20}, "rf": {"x": .2, "z": .2}}), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 15 / 60})


def heavy(arm):
    """Heavy, the headbutt: he grabs the collar with both hands, pulls the
    body in, rears back (forehead loaded, chin down) and drives the forehead
    in - short and risky."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    grab = {"raise": 90, "out": -6, "twist": 0, "elbow": 30, "wrist": 0}
    sh.key(8, s({"travel": {"z": -.3}, "root": {"y": -.44, "z": -.1}, "la": grab, "ra": grab, "lf": {"z": -.96}}), "ease")
    rear = s({"travel": {"z": -.3}, "root": {"y": -.3, "z": .24, "pitch": -12}, "torso": {"pitch": -18}, "head": {"pitch": 10},
              "la": merge(grab, {"elbow": 60}), "ra": merge(grab, {"elbow": 60}), "lf": {"z": -.96}})
    sh.key(15, rear, "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.52, "z": -.4, "pitch": 26}, "torso": {"pitch": 22}, "head": {"pitch": 24},
             "la": merge(grab, {"elbow": 90, "raise": 70}), "ra": merge(grab, {"elbow": 90, "raise": 70}), "lf": {"z": -.96}, "rf": {"toe": -24}})
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"head": {"pitch": 28}}), "ease")
    sh.key(36, at(-.3), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 18 / 60, "recover": 26 / 60})


def headbutt(arm):
    """Heavy after one hit: the same headbutt, already holding him - no grab."""
    sh = Shot(arm, N + "Headbutt")
    grab = {"raise": 88, "out": -6, "twist": 0, "elbow": 50, "wrist": 0}
    sh.key(0, s({"la": grab, "ra": grab}), "ease")
    sh.key(3, s({"root": {"y": -.32, "z": .2, "pitch": -10}, "torso": {"pitch": -14}, "head": {"pitch": 8}, "la": grab, "ra": grab}), "ease")
    hit = s({"root": {"y": -.52, "z": -.36, "pitch": 24}, "torso": {"pitch": 20}, "head": {"pitch": 24},
             "la": merge(grab, {"raise": 70, "elbow": 90}), "ra": merge(grab, {"raise": 70, "elbow": 90})})
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"head": {"pitch": 28}}), "ease")
    sh.key(22, s(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def tackle(arm):
    """Down route: a low tackle into the legs - he dives shoulder first, the
    arms wrap the knees, the clone covers the exit."""
    sh = Shot(arm, N + "Tackle")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.9, "pitch": 30}, "torso": {"pitch": 20}, "la": {"raise": 30, "out": 30}, "ra": {"raise": 30, "out": 30}}), "ease")
    wrap = {"raise": 70, "out": 10, "twist": 0, "elbow": 80, "wrist": 0}
    hit = s({"travel": {"z": -1.0}, "root": {"y": -1.0, "z": -.4, "pitch": 48}, "torso": {"pitch": 30}, "head": {"pitch": -30},
             "la": wrap, "ra": wrap, "lf": {"z": -1.6}, "rf": {"z": .9, "y": .3, "toe": -40}})
    sh.key(7, hit, "impact")
    sh.key(12, merge(hit, {"root": {"z": -.5}}), "ease")
    sh.key(28, at(-1.0, {"root": {"y": -.6}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 15 / 60})


def uzumaki_kick(arm):
    """Up route, Naruto's own body: 'U-zu-ma-ki!' - he crouches low, ready
    to jump after the body the clone kicks up (the chase is his choice)."""
    sh = Shot(arm, N + "UzumakiKick")
    sh.key(0, s(), "ease")
    sh.key(6, s({"root": {"y": -.9, "pitch": 18}, "head": {"pitch": -30}, "la": {"raise": 20, "out": 40}, "ra": {"raise": 20, "out": 40}}), "ease")
    sh.key(10, s({"root": {"y": -.94, "pitch": 18}, "head": {"pitch": -36}, "la": {"raise": 10, "out": 50}, "ra": {"raise": 10, "out": 50}}), "impact")
    sh.key(22, s({"root": {"y": -.6}}), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def uzumaki_rise(arm):
    """The clone under the target: crouched, it springs and kicks straight
    up under the chin with both feet driving (a rising kick)."""
    sh = Shot(arm, N + "UzumakiRise")
    sh.key(0, s({"root": {"y": -1.1, "pitch": 24}}), "ease")
    sh.key(6, s({"root": {"y": -1.15, "pitch": 30}, "la": {"raise": -20, "out": 30}, "ra": {"raise": -20, "out": 30}}), "ease")
    hit = s({"root": {"y": -.1, "pitch": -24}, "torso": {"pitch": -16}, "head": {"pitch": -30},
             "rf": {"x": .1, "z": -.4, "y": 2.0, "toe": 10, "knee": 0}, "la": {"raise": -30, "out": 50}, "ra": {"raise": -30, "out": 50}})
    sh.key(10, hit, "impact")
    sh.key(14, merge(hit, {"rf": {"y": 2.1}}), "ease")
    # The leg comes down bent (knee first), never swinging straight through.
    sh.key(19, s({"root": {"y": -.3, "pitch": -4}, "rf": {"x": .1, "z": -.1, "y": .9, "toe": -20, "knee": 12}}), "pass")
    sh.key(28, s(), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def launcher(arm):
    """Up route without a clone: a jumping uppercut from a deep crouch."""
    sh = Shot(arm, N + "Launcher")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.9, "pitch": 20, "yaw": 30}, "ra": {"raise": -10, "out": 20, "elbow": 100}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.1, "pitch": -8, "yaw": 0}, "torso": {"pitch": -10, "yaw": -14},
             "ra": {"raise": 160, "out": -10, "twist": 0, "elbow": 40, "wrist": 0}, "la": {"raise": 20, "out": 40},
             "rf": {"y": .2, "toe": -40}, "lf": {"z": -.96}})
    sh.key(10, hit, "impact")
    sh.key(14, merge(hit, {"ra": {"raise": 170}}), "ease")
    sh.key(26, at(-.3), "ease")
    return sh.build(markers={"contact": 10 / 60, "recover": 16 / 60})


def mirror_clone(arm):
    """Side route, Naruto's own body: he slides to the other side to open
    the flank the clone arrives from (MirrorStrike)."""
    sh = Shot(arm, N + "MirrorClone")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.56, "yaw": 0}, "rf": {"x": .9, "z": .4, "y": .2}}), "pass")
    hit = s({"root": {"y": -.5, "yaw": -24}, "rf": {"x": 1.0, "z": .3, "y": 0}, "la": {"raise": 60, "out": 30, "elbow": 40}})
    sh.key(7, hit, "impact")
    sh.key(20, s({"rf": {"x": 1.0, "z": .3}}), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def mirror_strike(arm):
    """The clone from the flank: a running straight punch, the whole body
    behind it."""
    sh = Shot(arm, N + "MirrorStrike")
    sh.key(0, s({"root": {"pitch": 20}}), "ease")
    sh.key(4, s({"root": {"y": -.6, "yaw": 40}, "ra": {"raise": 30, "out": 30, "elbow": 120}}), "ease")
    hit = s({"travel": {"z": -.5}, "root": {"y": -.56, "z": -.3, "pitch": 18, "yaw": -10}, "torso": {"pitch": 12, "yaw": -20},
             "ra": {"raise": 86, "out": -6, "elbow": 6}, "la": {"raise": 30, "elbow": 110}, "lf": {"z": -1.16}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"ra": {"raise": 88}}), "ease")
    sh.key(22, at(-.5), "ease")
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def dash_attack(arm):
    """Arrival: he comes in running and throws the whole body behind a big
    right swing (impulsive - the body arrives with the fist)."""
    sh = Shot(arm, N + "DashAttack")
    sh.key(0, s({"root": {"pitch": 24, "y": -.6}, "ra": {"raise": 20, "out": 50, "elbow": 100}}), "ease")
    hit = s({"root": {"y": -.6, "z": -.3, "pitch": 22, "yaw": -14}, "torso": {"pitch": 14, "yaw": -26},
             "ra": {"raise": 88, "out": -20, "elbow": 40}, "la": {"raise": -20, "out": 30}, "lf": {"z": -1.3}, "rf": {"z": 1.0, "y": .2, "toe": -30}})
    sh.key(4, hit, "impact")
    sh.key(8, merge(hit, {"torso": {"yaw": -32}}), "ease")
    sh.key(20, s(), "ease")
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


def rasengan(arm):
    """Rasengan release: the orb in the right palm, he charges with the arm
    straight out and the left hand bracing the wrist - the body behind it,
    the rear foot driving."""
    sh = Shot(arm, N + "Rasengan")
    palm = {"raise": 86, "out": -6, "twist": 0, "elbow": 6, "wrist": 40}
    sh.key(0, s({"ra": merge(palm, {"raise": 60, "elbow": 60}), "la": {"raise": 70, "out": -30, "elbow": 80}}), "ease")
    hit = s({"travel": {"z": -.6}, "root": {"y": -.66, "z": -.4, "pitch": 24, "yaw": 0}, "torso": {"pitch": 14, "yaw": -6},
             "ra": palm, "la": {"raise": 80, "out": -30, "elbow": 40}, "lf": {"z": -1.26}, "rf": {"z": 1.0, "toe": -30}})
    sh.key(6, hit, "impact")
    sh.key(14, merge(hit, {"root": {"z": -.44}}), "ease")
    sh.key(34, at(-.6), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 13 / 60})


# ===================================================================== air
def air1(arm):
    sh = Shot(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(3, air({"ra": {"raise": 50, "out": 40, "elbow": 110}, "root": {"yaw": 20}}), "ease")
    hit = air({"root": {"yaw": -16}, "torso": {"yaw": -20}, "ra": {"raise": 88, "out": -20, "elbow": 60}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"torso": {"yaw": -26}}), "ease")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air2(arm):
    sh = Shot(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(3, air({"la": {"raise": 50, "out": 40, "elbow": 110}, "root": {"yaw": -20}}), "ease")
    hit = air({"root": {"yaw": 16}, "torso": {"yaw": 20}, "la": {"raise": 88, "out": -20, "elbow": 60}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"torso": {"yaw": 26}}), "ease")
    sh.key(18, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_drive(arm):
    """Drive: a flying front kick that sends him away."""
    sh = Shot(arm, N + "AirDrive")
    sh.key(0, air(), "ease")
    sh.key(3, air({"rf": {"z": -.3, "y": 1.3, "knee": 10}}), "ease")
    hit = air({"root": {"pitch": -10}, "rf": {"z": -1.4, "y": 1.1, "toe": 10, "knee": 0}, "la": {"raise": 40, "out": 60}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"rf": {"z": -1.45}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_spike(arm):
    """Axe kick down."""
    sh = Shot(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    sh.key(3, air({"root": {"pitch": -12}, "rf": {"z": -1.0, "y": 2.0, "toe": 10, "knee": 0}}), "ease")
    hit = air({"root": {"pitch": 20}, "torso": {"pitch": 16}, "rf": {"z": -1.1, "y": .6, "toe": 20, "knee": 0}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"rf": {"y": .5}}), "ease")
    sh.key(22, air(), "ease")
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


def air_switch(arm):
    """Switch: he twists round in the air behind a spinning back fist."""
    sh = Shot(arm, N + "AirSwitch")
    sh.key(0, air(), "ease")
    sh.key(3, air({"root": {"yaw": 50}, "ra": {"raise": 60, "out": -40, "elbow": 110}}), "ease")
    hit = air({"root": {"yaw": -60}, "torso": {"yaw": -20}, "ra": {"raise": 86, "out": 50, "elbow": 20}})
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": -70}}), "ease")
    sh.key(20, air(), "ease")
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def rendan(arm):
    """NARUTO UZUMAKI RENDAN: from above the body the clones threw up, a
    heel drop with everything - the leg swings up past the head, the body
    folds over it and he drives the body into the floor."""
    sh = Shot(arm, N + "NarutoRendan")
    sh.key(0, air(), "ease")
    sh.key(5, air({"root": {"pitch": -20}, "torso": {"pitch": -14}, "rf": {"z": -1.0, "y": 2.2, "toe": 10, "knee": 0},
                   "la": {"raise": 140, "out": 30}, "ra": {"raise": 140, "out": 30}}), "ease")
    hit = air({"root": {"pitch": 30}, "torso": {"pitch": 24}, "head": {"pitch": -36}, "rf": {"z": -1.2, "y": .5, "toe": 20, "knee": 0},
               "la": {"raise": 40, "out": 70}, "ra": {"raise": 40, "out": 70}})
    sh.key(9, hit, "impact")
    sh.key(16, merge(hit, {"rf": {"y": .4}}), "ease")
    sh.key(34, s({"root": {"y": -.7}}), "ease")
    return sh.build(markers={"contact": 9 / 60, "recover": 21 / 60})


def throw_kunai(arm):
    """The kunai: a big overhand throw, the whole arm (not a flick)."""
    sh = Shot(arm, N + "Throw.Kunai")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"yaw": 36}, "torso": {"pitch": -6}, "ra": {"raise": 150, "out": 30, "elbow": 90, "wrist": 30}, "la": {"raise": 60, "out": 30}}), "ease")
    rel = s({"root": {"yaw": 6}, "torso": {"pitch": 14, "yaw": -20}, "ra": {"raise": 70, "out": -10, "elbow": 10, "wrist": -30}, "la": {"raise": 10, "out": 30}})
    sh.key(7, rel, "launch")
    sh.key(12, merge(rel, {"ra": {"raise": 50}}), "ease")
    sh.key(22, s(), "ease")
    return sh.build(markers={"release": 7 / 60})


# ============================================================ techniques
def shadow_clone(arm):
    """Kage Bunshin: the cross seal snapped at the chest, the knees sink -
    'Kage Bunshin no Jutsu!' - then the hands burst apart as the smoke
    goes."""
    out = []
    ch = Shot(arm, N + "ShadowClone.Channel")
    ch.key(0, s(), "ease")
    seal = s(merge(CROSS, {"root": {"y": -.6, "yaw": 6}, "torso": {"pitch": 6, "yaw": 0}, "head": {"pitch": -14}}))
    ch.key(6, seal, "impact")
    ch.key(11, merge(seal, {"root": {"y": -.64}}), "ease")
    out.append(ch.build(markers={"release": 11 / 60}))
    re = Shot(arm, N + "ShadowClone.Release")
    re.key(0, seal, "launch")
    burst = s({"root": {"y": -.5}, "la": {"raise": 40, "out": 60, "elbow": 40}, "ra": {"raise": 40, "out": 60, "elbow": 40}})
    re.key(4, burst, "impact")
    out.append(re.build())
    rc = Shot(arm, N + "ShadowClone.Recover")
    rc.key(0, burst, "ease")
    rc.key(8, s(), "ease")
    out.append(rc.build())
    return out


def mass_clone(arm):
    """Multi Shadow Clone: the same seal, bigger - the stance widens, the
    chest swells, the elbows lift; the burst throws the arms wide."""
    out = []
    ch = Shot(arm, N + "MassShadowClone.Channel")
    ch.key(0, s(), "ease")
    seal = s(merge(CROSS, {"root": {"y": -.76, "pitch": 6}, "torso": {"pitch": -4}, "head": {"pitch": -20},
                           "rf": {"x": .5, "z": .7}, "lf": {"x": -.4, "z": -.6}}))
    ch.key(8, seal, "impact")
    ch.key(18, merge(seal, {"root": {"y": -.8}, "la": {"out": -30}, "ra": {"out": -26}}), "ease")
    out.append(ch.build(markers={"release": 18 / 60}))
    re = Shot(arm, N + "MassShadowClone.Release")
    re.key(0, seal, "launch")
    burst = s({"root": {"y": -.5, "pitch": -4}, "torso": {"pitch": -8}, "la": {"raise": 90, "out": 80, "elbow": 20}, "ra": {"raise": 90, "out": 80, "elbow": 20},
               "rf": {"x": .5, "z": .7}, "lf": {"x": -.4, "z": -.6}})
    re.key(4, burst, "impact")
    out.append(re.build())
    rc = Shot(arm, N + "MassShadowClone.Recover")
    rc.key(0, burst, "ease")
    rc.key(12, s(), "ease")
    out.append(rc.build())
    return out


def clone_rasengan(arm):
    """Rasengan shaped with a clone: his right palm held out, the left hand
    hovering over it, stirring (the clone's hands do the shaping beside him)
    - the orb grows; the release is the Rasengan strike."""
    out = []
    ch = Shot(arm, N + "CloneRasengan.Channel")
    ch.key(0, s(), "ease")
    hold = s({"root": {"y": -.6, "yaw": 10}, "torso": {"pitch": 10}, "head": {"pitch": -2},
              "ra": {"raise": 60, "out": 10, "twist": 60, "elbow": 70, "wrist": 0},
              "la": {"raise": 70, "out": -20, "twist": 20, "elbow": 100, "wrist": 0}})
    ch.key(8, hold, "ease")
    ch.key(16, merge(hold, {"la": {"out": -10, "twist": 40}}), "ease")
    ch.key(24, merge(hold, {"la": {"out": -26, "twist": 0}}), "ease")
    out.append(ch.build(markers={"release": 24 / 60}))
    return out


# ================================================================= states
def intro(arm):
    """Match intro: the grin and the thumb up at the opponent - 'I'm gonna
    be Hokage, believe it!' - then he slaps his fist into his palm and drops
    into his stance, bouncing."""
    sh = Shot(arm, N + "Intro")
    pose = s({"root": {"y": -.12, "pitch": -2, "yaw": 14}, "torso": {"pitch": -6, "yaw": -6}, "head": {"pitch": -8, "yaw": -10},
              "ra": {"raise": 96, "out": 10, "twist": -20, "elbow": 40, "wrist": 0}, "la": {"raise": -10, "out": 40, "twist": -40, "elbow": 100, "wrist": 0},
              "rf": {"x": .2, "z": .4}, "lf": {"x": -.1, "z": -.4}})
    sh.key(0, pose, "ease")
    sh.key(70, merge(pose, {"ra": {"raise": 100}}), "ease")
    slap = s({"root": {"y": -.3}, "ra": {"raise": 70, "out": -30, "elbow": 90}, "la": {"raise": 70, "out": -30, "twist": 40, "elbow": 80},
              "rf": {"x": .2, "z": .4}, "lf": {"x": -.1, "z": -.4}})
    sh.key(86, slap, "ease")
    sh.key(92, merge(slap, {"ra": {"raise": 66}}), "impact")
    sh.key(110, s({"root": {"y": -.52}}), "ease")
    sh.key(126, s({"root": {"y": -.42}}), "ease")
    sh.key(156, s(), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def win(arm):
    """Victory: both fists punched into the sky, a jump of joy - 'Dattebayo!'
    - then the thumb and the grin."""
    sh = Shot(arm, N + "Win")
    sh.key(0, s(), "ease")
    sh.key(10, s({"root": {"y": -.8, "pitch": 14}}), "ease")
    up = s({"root": {"y": .1, "pitch": -6}, "torso": {"pitch": -10}, "head": {"pitch": -24},
           "la": {"raise": 170, "out": 30, "elbow": 10}, "ra": {"raise": 170, "out": 30, "elbow": 10},
           "rf": {"y": .5, "toe": -40}, "lf": {"y": .5, "toe": -40}})
    sh.key(20, up, "launch")
    sh.key(34, merge(up, {"rf": {"y": 0}, "lf": {"y": 0}, "root": {"y": -.3}}), "impact")
    thumb = s({"root": {"y": -.12, "pitch": -2}, "head": {"pitch": -8}, "ra": {"raise": 96, "out": 10, "twist": -20, "elbow": 40},
               "la": {"raise": -10, "out": 40, "twist": -40, "elbow": 100}})
    sh.key(54, thumb, "ease")
    sh.key(150, merge(thumb, {"ra": {"raise": 100}}), "ease")
    sh.drag(["neck"], 3)
    return sh.build()


def awaken(arm):
    """Nine-Tails chakra: he folds over, the hands claw at the floor, the
    back arches and the head comes up - then the feral stance, low, almost
    on all fours."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    claw = {"raise": 20, "out": 20, "twist": 0, "elbow": 30, "wrist": 40}
    sh.key(10, s({"root": {"y": -1.1, "pitch": 40}, "torso": {"pitch": 30}, "head": {"pitch": 20}, "la": claw, "ra": claw}), "ease")
    sh.key(22, s({"root": {"y": -.7, "pitch": 6}, "torso": {"pitch": -24}, "head": {"pitch": -40},
                  "la": {"raise": 10, "out": 60, "elbow": 40}, "ra": {"raise": 10, "out": 60, "elbow": 40}}), "impact")
    feral = s({"root": {"y": -1.0, "pitch": 34}, "torso": {"pitch": 20}, "head": {"pitch": -40},
               "la": {"raise": 30, "out": 30, "elbow": 40, "wrist": 40}, "ra": {"raise": 30, "out": 30, "elbow": 40, "wrist": 40},
               "rf": {"x": .5, "z": .9}, "lf": {"x": -.3, "z": -.8}})
    sh.key(34, feral, "ease")
    sh.key(46, feral, "ease")
    return sh.build()


def author(arm):
    acts = locomotion(arm)
    acts += [idle(arm), light1(arm), light2(arm), light3(arm), clone_kick(arm), clone_kick_strike(arm), heavy(arm), headbutt(arm),
             tackle(arm), uzumaki_kick(arm), uzumaki_rise(arm), launcher(arm), mirror_clone(arm), mirror_strike(arm), dash_attack(arm),
             rasengan(arm), air1(arm), air2(arm), air_drive(arm), air_spike(arm), air_switch(arm), rendan(arm), throw_kunai(arm),
             intro(arm), win(arm), awaken(arm)]
    acts += shadow_clone(arm)
    acts += mass_clone(arm)
    acts += clone_rasengan(arm)
    return acts
