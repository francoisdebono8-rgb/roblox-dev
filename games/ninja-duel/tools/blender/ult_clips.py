"""Stage 6 ultimates, authored (user 02/11: "globalement tous les memes ...
pas super fluide ... les coups sont mal faits ... meme effet meme sensation").

One clip per fighter for the caster ("<fighter>.Ultimate", from the press:
startup S then the sequence T) and one clip per ultimate for the held body
("Ult.<kind>.Victim", from the catch). Both are played whole by the motion
engine (VelmoraMotionEngine, the ultimate branch) while Server/Ultimates
moves the two roots along the same timeline (ULT below is the shared table:
keep it equal to Ultimates.DEFS). Every sequence has its own body language:

  Naruto    belly punch, leap back, the sign; the clones do the work (the
            server's real clone bodies), then he drops from the sky, heel first
  Sasuke    the Chidori formed low, a run that tears the floor, impaled and
            lifted, thrown up, the Lion Combo in the air, the heel into the floor
  Gaara     he barely moves: one hand opens (the sand floods), both lift (the
            cocoon rises), the hand closes slowly - Sabaku Soso
  Lee       the gates open (a roar), the rising kick, a pinball of blows in
            the air, the bandage pull, punch and kick together into the floor
  Neji      the trigram stance; palms that double in speed, a frozen beat,
            the last palm
  Itachi    stillness: the eye, then nothing - the body on the cross does it all
  Minato    the kunai fan, then poses that snap (he is everywhere), back turned
            at the end, the flick of the wrist
  Kakashi   the signs, the Raikiri held low, the run, one thrust, the pull
"""
import math
from nd_shot import Shot, merge
import kunai_lion, clips_flash2, itachi_p3, naruto_p5, kakashi_p6, gaara_p7, lee_p8, neji_p9

FPS = 60
# kind: (startup, time) - Server/Ultimates.DEFS
ULT = {"clones": (.24, 3.9), "lion": (.3, 3.6), "pyramid": (.42, 3.6), "lotus": (.2, 3.7),
       "palms": (.24, 3.6), "tsukuyomi": (.32, 4.0), "flash": (.16, 3.4), "raikiri": (.3, 3.4)}
TAIL = .5  # the caster's clip runs a little past the last blow (his settle)


# Every key is made ABSOLUTE (Shot merges keys cumulatively: a roll or a
# lifted foot left out of a key would otherwise carry over), and a body off
# the floor gives its legs in PELVIS space ("legs": (right, left), Roblox axes
# from the hip: -y down, -z forward) - the ankles then turn with the pelvis
# through the tumbles, spins and flips (kunai_lion.tuck, the salto rule).
ZERO = {"root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0, "tuck": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}, "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}
# Pelvis-space ankles (the leg is ~2 studs: keep |leg| under 1.95).
DOWN = (0, -1.9, .1)
BENT = (0, -1.4, .75)       # the shin folded back, the knee forward
TUCK = (0, -.55, -.35)      # knees to the chest
KNEE = (0, -.95, -.7)       # the knee up
KICK = (0, -.3, -1.9)       # straight out in front
KICK_HI = (0, .7, -1.75)
HEEL_UP = (0, 1.75, -.55)   # the axe kick raised over the head
AXE = (0, -.9, -1.65)       # the heel coming down through
DANGLE_R, DANGLE_L = (.05, -1.85, .3), (-.05, -1.9, .15)


def absolute(pose):
    out = merge(ZERO, {k: v for k, v in pose.items() if k in ZERO})
    legs = pose.get("legs")
    if legs:
        from kunai_lion import tuck
        out["root"]["tuck"] = 1
        out.update(tuck(0, out["root"], legs[0], legs[1]))
    return out


def clip(arm, name, keys):
    sh = Shot(arm, name)
    used = set()
    for t, pose, sp in keys:
        f = int(round(t * FPS))
        while f in used:
            f += 1
        used.add(f)
        sh.key(f, absolute(pose), sp)
    return sh.build()


def fly(base, legs, over=None):
    """A pose in the air: `base` with the legs given in pelvis space."""
    out = merge(base, over or {})
    out["legs"] = legs
    return out


def jitter(base, part, t0, t1, step, amp, keys, sp="pass", seed=1):
    """Small trembling keys (a struggle, a convulsion) between t0 and t1."""
    t, i = t0, 0
    while t < t1 - 1e-6:
        s = 1 if i % 2 == 0 else -1
        a = amp * (.6 + .4 * ((i * 7 + seed) % 5) / 4)
        keys.append((t, merge(base, {part: {"roll": s * a, "yaw": -s * a * .6}}), sp))
        t += step
        i += 1


def palm_times():
    """Neji's 2 → 128: the palms come faster and faster (shared by both clips)."""
    gaps = [(.3, .15), (.6, .1), (1.0, .07), (1.45, .06), (1.9, .05), (2.35, .05), (2.8, .05)]
    out = []
    for n, (t0, step) in enumerate(gaps):
        end = gaps[n + 1][0] if n + 1 < len(gaps) else 3.0
        t = t0
        while t < end - 1e-6:
            out.append(t)
            t += step
    return out


# =================================================================== victims
# A neutral body (every fighter plays these): feet apart, arms half up.
V = {"root": {"y": -.3, "pitch": 4}, "torso": {"pitch": 4}, "head": {},
     "ra": {"raise": 40, "out": 10, "twist": 10, "elbow": 70}, "la": {"raise": 40, "out": 10, "twist": 10, "elbow": 70},
     "rf": {"x": .2, "z": .3, "yaw": 10}, "lf": {"x": -.2, "z": -.3, "yaw": -10}}
VAIR = {"root": {"y": -.2}, "torso": {}, "head": {},
        "ra": {"raise": 60, "out": 40, "elbow": 40}, "la": {"raise": 60, "out": 40, "elbow": 40}, "legs": (BENT, DOWN)}
LIMP = {"root": {"y": -.2, "pitch": 30}, "torso": {"pitch": 20}, "head": {"pitch": 30},
        "ra": {"raise": -10, "out": 20, "elbow": 20}, "la": {"raise": -10, "out": 20, "elbow": 20}, "legs": (DANGLE_R, DANGLE_L)}
PINNED = {"ra": {"raise": -6, "out": -4, "twist": 10, "elbow": 10}, "la": {"raise": -6, "out": -4, "twist": 10, "elbow": 10}}


def v(over=None):
    return merge(V, over or {})


def va(over=None, legs=None):
    out = merge(VAIR, over or {})
    if legs:
        out["legs"] = legs
    return out


def limp(over=None):
    return merge(LIMP, over or {})


def hit(t, side, power=1.0):
    """A blow taken standing: the head snaps away, the chest folds a little."""
    return (t, v({"root": {"pitch": 10 * power, "roll": 8 * side * power}, "torso": {"pitch": 16 * power, "yaw": -18 * side * power},
                  "head": {"pitch": 14 * power, "yaw": -30 * side * power, "roll": 10 * side},
                  "ra": {"raise": 20, "out": 40, "elbow": 40}, "la": {"raise": 30, "out": 30, "elbow": 50},
                  "rf": {"z": .3 + .15 * power}, "lf": {"z": -.3 + .2 * power}}), "impact")


def victim_clones(arm):
    T = ULT["clones"][1]
    fold = v({"root": {"pitch": 34, "y": -.5}, "torso": {"pitch": 30}, "head": {"pitch": 20},
              "ra": {"raise": 20, "out": -20, "elbow": 90}, "la": {"raise": 20, "out": -20, "elbow": 90}, "lf": {"z": .1}})
    k = [(0, fold, "impact"),
         (.3, v({"root": {"pitch": 26, "y": -.55}, "torso": {"pitch": 24}, "head": {"pitch": 10}}), "ease"),
         (.55, v({"head": {"yaw": -40, "pitch": -6}}), "ease"),                     # where did he go
         (.75, v({"head": {"yaw": 40, "pitch": -6}, "root": {"yaw": 20}}), "ease")]  # clones everywhere
    t, side = .9, 1
    while t < 1.55:
        k.append(hit(t, side, .8 + .2 * side))
        t += .13
        side = -side
    # U-ZU-MA-KI: kicked up under the chin, each kick sends him higher, tumbling.
    k += [(1.6, va({"root": {"pitch": -40}, "torso": {"pitch": -20}, "head": {"pitch": -50}, "ra": {"raise": 140, "out": 30}, "la": {"raise": 140, "out": 30}}, (DOWN, BENT)), "impact"),
          (1.95, va({"root": {"pitch": -110}, "torso": {"pitch": -30}, "head": {"pitch": -40}}, (BENT, KNEE)), "impact"),
          (2.35, va({"root": {"pitch": -200}, "torso": {"pitch": -20}, "head": {"pitch": -30}, "ra": {"raise": 170, "out": 60}, "la": {"raise": 10, "out": 70}}, (DOWN, BENT)), "impact"),
          (2.75, va({"root": {"pitch": -290}, "torso": {"pitch": -30}, "head": {"pitch": -40}, "ra": {"raise": 60, "out": 80}, "la": {"raise": 150, "out": 50}}, (KNEE, DOWN)), "impact"),
          (3.25, va({"root": {"pitch": -340, "y": .2}, "torso": {"pitch": -10}, "head": {"pitch": -20}, "ra": {"raise": 150, "out": 80}, "la": {"raise": 150, "out": 80}}, (DOWN, DOWN)), "ease"),
          # NARUTO RENDAN: the heel in the stomach, folded in two, down.
          (3.35, va({"root": {"pitch": -330, "y": .1}, "torso": {"pitch": 50}, "head": {"pitch": 40}, "ra": {"raise": 170, "out": 20}, "la": {"raise": 170, "out": 20}}, (KNEE, KNEE)), "impact"),
          (T, limp({"root": {"pitch": -444, "y": -2.35, "z": .6}, "torso": {"pitch": -8}, "head": {"pitch": -14, "yaw": 20}}), "ease")]   # flat on his back
    return clip(arm, "Ult.clones.Victim", k)


def victim_lion(arm):
    T = ULT["lion"][1]
    braced = v({"root": {"pitch": -6}, "head": {"pitch": -10}, "ra": {"raise": 90, "out": -30, "elbow": 110}, "la": {"raise": 90, "out": -30, "elbow": 110}})
    impaled = {"root": {"y": -.2, "pitch": 40}, "torso": {"pitch": 40}, "head": {"pitch": -30},
               "ra": {"raise": 30, "out": 60, "elbow": 10}, "la": {"raise": 30, "out": 60, "elbow": 10}, "legs": ((.1, -1.6, .8), (-.1, -1.8, .5))}
    lifted = va({"root": {"pitch": -30}, "torso": {"pitch": -40}, "head": {"pitch": -50}, "ra": {"raise": -20, "out": 70, "elbow": 10}, "la": {"raise": -20, "out": 70, "elbow": 10}},
                (DANGLE_R, DANGLE_L))
    k = [(0, braced, "ease"), (.32, braced, "ease"), (.36, impaled, "impact")]
    jitter(impaled, "torso", .42, .75, .05, 6, k)        # the current runs through him
    k += [(.8, lifted, "ease"), (1.15, merge(lifted, {"root": {"pitch": -50}}), "ease"),
          (1.5, va({"root": {"pitch": -160}, "head": {"pitch": -30}}, (KNEE, BENT)), "pass"),
          (1.9, va({"root": {"pitch": -200, "roll": 40}, "torso": {"yaw": 40}, "head": {"yaw": 40}}, (BENT, DOWN)), "impact"),
          (2.2, va({"root": {"pitch": -240, "roll": -30}, "torso": {"pitch": 30}, "head": {"pitch": 30}}, (KNEE, KNEE)), "impact"),
          (2.5, va({"root": {"pitch": -180}, "torso": {"pitch": 40}, "head": {"pitch": 40}, "ra": {"raise": 170}, "la": {"raise": 170}}, (DOWN, BENT)), "impact"),
          (2.85, va({"root": {"pitch": -180, "y": .2}, "torso": {"pitch": 10}, "head": {"pitch": 10}, "ra": {"raise": 170, "out": 30}, "la": {"raise": 170, "out": 30}}, (DOWN, DOWN)), "ease"),
          # driven head first into the floor, then the body falls flat
          (3.25, limp({"root": {"pitch": -180, "y": -.6}, "torso": {"pitch": 50}}), "impact"),
          (T, limp({"root": {"pitch": -84, "y": -2.35, "z": .6}, "torso": {"pitch": -8}, "head": {"pitch": -14, "yaw": 20}}), "ease")]
    return clip(arm, "Ult.lion.Victim", k)


def victim_pyramid(arm):
    T = ULT["pyramid"][1]
    sink = v({"root": {"y": -.5, "pitch": -4}, "head": {"pitch": 14}, "ra": {"raise": 120, "out": 50, "elbow": 40}, "la": {"raise": 110, "out": 60, "elbow": 50},
              "rf": {"z": .1, "toe": 20}, "lf": {"z": -.1, "toe": 20}})
    k = [(0, v({"head": {"pitch": 20}}), "ease"), (.25, sink, "ease")]
    jitter(sink, "torso", .3, .85, .09, 8, k, seed=3)     # wading, pulling the legs
    held = v(merge(PINNED, {"root": {"y": -.3, "pitch": -2}, "head": {"pitch": -24}, "rf": {"x": .1, "z": 0, "yaw": 0}, "lf": {"x": -.1, "z": 0, "yaw": 0}}))
    k += [(.95, merge(held, {"ra": {"raise": 60, "out": 30, "elbow": 30}, "la": {"raise": 50, "out": 30, "elbow": 30}}), "ease"),
          (1.45, held, "ease")]
    jitter(held, "head", 1.5, 2.85, .1, 7, k, seed=5)     # only the head moves now (the body is in the sand)
    crushed = merge(held, {"root": {"y": -.5, "pitch": 18}, "torso": {"pitch": 20}, "head": {"pitch": 30}})
    k += [(2.9, crushed, "impact"), (3.05, merge(crushed, {"head": {"pitch": 36}}), "ease"),
          (3.3, limp({"root": {"pitch": -20}}), "impact"),
          (T, limp({"root": {"pitch": -84, "y": -2.35, "z": .6}, "torso": {"pitch": -8}, "head": {"pitch": -14, "yaw": 20}}), "ease")]
    return clip(arm, "Ult.pyramid.Victim", k)


def victim_lotus(arm):
    T = ULT["lotus"][1]
    fear = v({"root": {"pitch": -10}, "head": {"pitch": -12}, "ra": {"raise": 80, "out": -20, "elbow": 100}, "la": {"raise": 80, "out": -20, "elbow": 100}})
    k = [(0, fear, "ease"), (.38, fear, "ease"),
         (.42, va({"root": {"pitch": -50}, "head": {"pitch": -60}, "torso": {"pitch": -20}, "ra": {"raise": 150}, "la": {"raise": 150}}, (DOWN, DOWN)), "impact"),
         (.95, va({"root": {"pitch": -80}, "head": {"pitch": -40}}, (DOWN, BENT)), "ease")]
    side = 1
    for t in [1.0 + .15 * i for i in range(9)]:
        k.append((t, va({"root": {"pitch": -60 + 30 * side, "roll": 45 * side, "yaw": 25 * side}, "torso": {"yaw": -30 * side}, "head": {"yaw": -40 * side, "pitch": 20},
                         "ra": {"raise": 90 + 60 * side, "out": 60}, "la": {"raise": 90 - 60 * side, "out": 60}}, (KNEE, DOWN) if side > 0 else (DOWN, KNEE)), "impact"))
        side = -side
    wrapped = va(merge(PINNED, {"head": {"pitch": -10}}), ((.08, -1.9, 0), (-.08, -1.9, 0)))   # bound by the bandages
    k += [(2.3, wrapped, "ease"), (2.6, merge(wrapped, {"root": {"pitch": 20}}), "ease"),
          (2.72, merge(wrapped, {"root": {"pitch": 160}, "torso": {"pitch": 30}, "head": {"pitch": 30}}), "impact"),
          (3.08, merge(wrapped, {"root": {"pitch": 180}, "head": {"pitch": 40}}), "ease"),
          (3.12, limp({"root": {"pitch": 180, "y": -.8}, "torso": {"pitch": 50}}), "impact"),
          (T, limp({"root": {"pitch": 276, "y": -2.35, "z": .6}, "torso": {"pitch": -8}, "head": {"pitch": -14, "yaw": 20}}), "ease")]
    return clip(arm, "Ult.lotus.Victim", k)


def victim_palms(arm):
    T = ULT["palms"][1]
    k = [(0, v({"root": {"pitch": -6}, "head": {"pitch": -14}}), "ease")]
    # Every palm a small jolt; as the points close the arms fall, the knees go.
    for i, t in enumerate(palm_times()):
        fall = min(1.0, t / 2.9)
        side = 1 if i % 2 == 0 else -1
        k.append((t, v({"root": {"y": -.3 - .5 * fall, "pitch": 6 + 8 * fall, "roll": 4 * side}, "torso": {"pitch": 10 * fall, "yaw": 8 * side},
                        "head": {"pitch": 10 + 14 * fall, "yaw": 10 * side},
                        "ra": {"raise": 40 - 50 * fall, "out": 10 + 10 * fall, "elbow": 70 - 50 * fall},
                        "la": {"raise": 40 - 50 * fall, "out": 10 + 10 * fall, "elbow": 70 - 50 * fall}}), "impact"))
    frozen = v({"root": {"y": -.85, "pitch": 14}, "torso": {"pitch": 10}, "head": {"pitch": 24}, "ra": {"raise": -10, "out": 20, "elbow": 20}, "la": {"raise": -10, "out": 20, "elbow": 20}})
    k += [(3.0, frozen, "ease"), (3.28, frozen, "ease"),
          (3.32, va({"root": {"pitch": -40}, "torso": {"pitch": -30}, "head": {"pitch": -40}, "ra": {"raise": 120, "out": 50}, "la": {"raise": 120, "out": 50}}, (KICK, BENT)), "impact"),
          (T, va({"root": {"pitch": -60}, "head": {"pitch": -30}}, (DOWN, BENT)), "ease")]
    return clip(arm, "Ult.palms.Victim", k)


def victim_tsukuyomi(arm):
    T = ULT["tsukuyomi"][1]
    stare = v({"head": {"pitch": -4}, "ra": {"raise": 30, "out": 10, "elbow": 40}, "la": {"raise": 30, "out": 10, "elbow": 40}})
    cross = {"root": {"y": 0}, "torso": {}, "head": {"pitch": 30, "roll": 10},
             "ra": {"raise": 0, "out": 88, "elbow": 4, "wrist": 10}, "la": {"raise": 0, "out": 88, "elbow": 4, "wrist": 10},
             "legs": ((.06, -1.92, 0), (-.06, -1.92, 0))}
    scream = merge(cross, {"root": {"pitch": -10}, "torso": {"pitch": -20}, "head": {"pitch": -40, "roll": 0}})
    k = [(0, stare, "ease"), (.4, stare, "ease"), (.7, cross, "ease")]
    for t in (1.0, 1.7, 2.4, 3.0):
        k += [(t, scream, "impact"), (t + .22, merge(cross, {"head": {"pitch": 34, "roll": -10}}), "ease")]
    kneel = v({"root": {"y": -1.3, "pitch": 30}, "torso": {"pitch": 30}, "head": {"pitch": 40}, "ra": {"raise": 0, "out": 10, "elbow": 10}, "la": {"raise": 0, "out": 10, "elbow": 10},
               "rf": {"z": -.4}, "lf": {"z": .6, "toe": -30}})
    k += [(3.35, cross, "ease"), (3.45, kneel, "impact"),
          (T, merge(kneel, {"root": {"y": -1.5, "pitch": 50}, "torso": {"pitch": 40}, "head": {"pitch": 50}, "ra": {"raise": -20}, "la": {"raise": -20}}), "ease")]
    return clip(arm, "Ult.tsukuyomi.Victim", k)


def victim_flash(arm):
    T = ULT["flash"][1]
    guard = v({"head": {"pitch": -10}, "ra": {"raise": 80, "out": -20, "elbow": 100}, "la": {"raise": 70, "out": -10, "elbow": 90}})
    k = [(0, v(), "ease"), (.15, v({"head": {"yaw": -50}}), "ease"), (.3, v({"head": {"yaw": 50}, "root": {"yaw": 10}}), "ease"),
         (.5, guard, "ease"), (2.9, guard, "hold")]
    # time starts again: every cut lands at once
    side = 1
    for t in (2.92, 2.96, 3.0, 3.04, 3.08):
        k.append((t, merge(guard, {"root": {"yaw": 40 * side, "pitch": 14, "roll": 10 * side}, "torso": {"yaw": -30 * side, "pitch": 20},
                                   "head": {"yaw": -40 * side, "pitch": 20}, "ra": {"raise": 30, "out": 70, "elbow": 20}, "la": {"raise": 30, "out": 70, "elbow": 20}}), "impact"))
        side = -side
    k += [(T, limp({"root": {"pitch": 60, "y": -.9}}), "ease")]
    return clip(arm, "Ult.flash.Victim", k)


def victim_raikiri(arm):
    T = ULT["raikiri"][1]
    held = v({"root": {"y": -.5, "pitch": -4}, "head": {"pitch": -10}, "ra": {"raise": -10, "out": 30, "elbow": 20}, "la": {"raise": -10, "out": 30, "elbow": 20},
              "rf": {"x": .3, "z": .2}, "lf": {"x": -.3, "z": -.2}})
    k = [(0, held, "ease")]
    jitter(held, "torso", .1, 2.3, .14, 10, k, seed=2)     # straining against the hounds
    impaled = {"root": {"y": -.3, "pitch": 46}, "torso": {"pitch": 36}, "head": {"pitch": -36},
               "ra": {"raise": 20, "out": 70, "elbow": 6}, "la": {"raise": 20, "out": 70, "elbow": 6}, "legs": ((.1, -1.5, .9), (-.1, -1.75, .6))}
    k += [(2.38, held, "ease"), (2.42, impaled, "impact")]
    jitter(impaled, "torso", 2.5, 2.88, .04, 9, k, seed=4)
    k += [(2.92, va({"root": {"pitch": -50}, "torso": {"pitch": -30}, "head": {"pitch": -40}, "ra": {"raise": 140, "out": 60}, "la": {"raise": 140, "out": 60}}, (KICK, BENT)), "impact"),
          (T, va({"root": {"pitch": -90}, "head": {"pitch": -30}}, (DOWN, BENT)), "ease")]
    return clip(arm, "Ult.raikiri.Victim", k)


VICTIMS = [victim_clones, victim_lion, victim_pyramid, victim_lotus, victim_palms, victim_tsukuyomi, victim_flash, victim_raikiri]


# ==================================================================== casters
def naruto(arm):
    s, AIR = naruto_p5.s, naruto_p5.AIR
    S, T = ULT["clones"]
    sign = s({"root": {"y": -.7, "pitch": 6, "yaw": 0}, "torso": {"pitch": 4, "yaw": 0}, "head": {"pitch": -6, "yaw": 0},
              "ra": {"raise": 72, "out": -38, "twist": 30, "elbow": 100, "wrist": 10}, "la": {"raise": 68, "out": -40, "twist": 34, "elbow": 104, "wrist": 0},
              "rf": {"x": .4, "z": .3, "yaw": 10}, "lf": {"x": -.4, "z": -.2, "yaw": -10}})
    k = [(0, s(), "ease"),
         (S * .6, s({"root": {"y": -.7, "pitch": 24}, "ra": {"raise": 20, "out": 10, "elbow": 120}, "rf": {"z": .9}}), "ease"),
         # the opener: a straight punch in the stomach
         (S, s({"root": {"y": -.6, "z": -.4, "pitch": 30, "yaw": 0}, "torso": {"pitch": 14, "yaw": -30}, "ra": {"raise": 90, "out": -6, "elbow": 6},
                "la": {"raise": 20, "out": 30, "elbow": 60}, "lf": {"z": -1.4}, "rf": {"z": 1.0, "toe": -30}}), "impact"),
         # leap back: tuck in the air, land crouched
         (S + .15, fly(AIR, (TUCK, KNEE), {"root": {"pitch": -20}}), "pass"),
         (S + .38, s({"root": {"y": -1.1, "pitch": 26}, "torso": {"pitch": 14}, "la": {"raise": -20, "out": 40}}), "impact"),
         (S + .55, sign, "ease")]
    # holding the sign, a grin and a bob while the clones work
    for i, t in enumerate((.85, 1.2, 1.55, 1.9, 2.25)):
        k.append((S + t, merge(sign, {"root": {"y": -.66 - .06 * (i % 2)}, "head": {"pitch": -10 + 6 * (i % 2), "yaw": 6 * (1 - 2 * (i % 2))}}), "ease"))
    # the jump: crouch, launch, a somersault at the top, the heel raised, NARUTO RENDAN
    k += [(S + 2.55, s({"root": {"y": -1.2, "pitch": 30}, "torso": {"pitch": 20}, "ra": {"raise": -40, "out": 20}, "la": {"raise": -40, "out": 20}}), "ease"),
          (S + 2.7, fly(AIR, (DOWN, BENT), {"root": {"pitch": -10}, "ra": {"raise": 160, "out": 20}, "la": {"raise": 150, "out": 30}}), "launch"),
          (S + 2.85, fly(AIR, (TUCK, TUCK), {"root": {"pitch": 150}, "ra": {"raise": 70, "out": -6, "elbow": 96}, "la": {"raise": 70, "out": -6, "elbow": 96}}), "pass"),
          (S + 3.0, fly(AIR, (TUCK, TUCK), {"root": {"pitch": 300}, "ra": {"raise": 70, "out": -6, "elbow": 96}, "la": {"raise": 70, "out": -6, "elbow": 96}}), "pass"),
          (S + 3.22, fly(AIR, (HEEL_UP, BENT), {"root": {"pitch": 336}, "torso": {"pitch": -10}, "head": {"pitch": 20},
                                                 "ra": {"raise": 30, "out": 60, "elbow": 20}, "la": {"raise": 30, "out": 60, "elbow": 20}}), "ease"),
          (S + 3.35, fly(AIR, (AXE, BENT), {"root": {"pitch": 380}, "torso": {"pitch": 20}, "head": {"pitch": 30},
                                             "ra": {"raise": -20, "out": 50, "elbow": 20}, "la": {"raise": -20, "out": 50, "elbow": 20}}), "impact"),
          (S + 3.6, s({"root": {"y": -1.2, "pitch": 390}, "torso": {"pitch": 20}, "rf": {"z": -.6, "toe": -10}, "lf": {"z": .7}, "la": {"raise": -30, "out": 40}}), "impact"),
          (S + T + TAIL, s({"root": {"pitch": 360 + naruto_p5.STANCE["root"]["pitch"]}}), "ease")]
    return clip(arm, "Legion.Ultimate", k)


def sasuke(arm):
    import sasuke_p1
    s, AIR = kunai_lion.s, sasuke_p1.AIR
    S, T = ULT["lion"]
    crouch = s({"root": {"y": -.95, "z": -.1, "pitch": 24, "yaw": 30}, "torso": {"pitch": 16, "yaw": -6}, "head": {"pitch": -24},
                "ra": {"raise": -24, "out": 24, "twist": 0, "elbow": 36, "wrist": 30}, "la": {"raise": 12, "out": -10, "twist": 30, "elbow": 82},
                "rf": {"x": .3, "z": .95, "toe": -20}, "lf": {"z": -.85}})
    run_a = s({"root": {"y": -.8, "pitch": 42, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0}, "head": {"pitch": -40},
               "ra": {"raise": -50, "out": 30, "elbow": 20, "wrist": 30}, "la": {"raise": 30, "out": 10, "elbow": 90},
               "rf": {"x": .2, "y": .8, "z": .9, "toe": -30, "yaw": 0}, "lf": {"x": -.2, "y": 0, "z": -1.2, "toe": 0, "yaw": 0}})
    run_b = merge(run_a, {"rf": {"y": 0, "z": -1.2, "toe": 0}, "lf": {"y": .9, "z": .9, "toe": -30}})
    thrust = s({"root": {"y": -.75, "z": -.5, "pitch": 28, "yaw": 0}, "torso": {"pitch": 14, "yaw": -10}, "head": {"pitch": -20},
                "ra": {"raise": 88, "out": -6, "twist": 0, "elbow": 4, "wrist": 30}, "la": {"raise": -20, "out": 30, "elbow": 20},
                "lf": {"z": -1.8, "yaw": 0}, "rf": {"z": 1.0, "toe": -40, "yaw": 0}})
    lift = s({"root": {"y": -.4, "pitch": -6, "yaw": 0}, "torso": {"pitch": -14, "yaw": 0}, "head": {"pitch": -30},
              "ra": {"raise": 160, "out": 0, "elbow": 10, "wrist": 0}, "la": {"raise": 20, "out": 40, "elbow": 30}, "lf": {"z": -.9, "yaw": 0}, "rf": {"z": .9, "yaw": 0}})
    k = [(0, s(), "ease"), (S, crouch, "ease"),
         (S + .08, run_a, "launch"), (S + .2, run_b, "pass"), (S + .3, run_a, "pass"),
         (S + .36, thrust, "impact"), (S + .74, merge(thrust, {"root": {"z": -.55}}), "ease"),
         (S + 1.1, lift, "ease"),
         (S + 1.25, merge(lift, {"ra": {"raise": 175, "elbow": 0}, "root": {"y": -.2}}), "launch"),
         (S + 1.45, s({"root": {"y": -1.1, "pitch": 30, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0}, "ra": {"raise": -30, "out": 20}, "la": {"raise": -30, "out": 20}}), "ease"),
         (S + 1.65, fly(AIR, (DOWN, BENT), {"root": {"pitch": -10}, "ra": {"raise": 150, "out": 20, "elbow": 10}, "la": {"raise": 140, "out": 30, "elbow": 10}}), "launch"),
         # the Lion Combo: a turning kick, a fist, the heel lifted, the heel down
         # (the spin: a full turn, the leg opens on the way round and lands facing him)
         (S + 1.76, fly(AIR, (KNEE, TUCK), {"root": {"yaw": 120, "pitch": 10}}), "pass"),
         (S + 1.84, fly(AIR, (KNEE, TUCK), {"root": {"yaw": 250, "pitch": 6}}), "pass"),
         (S + 1.9, fly(AIR, (KICK, TUCK), {"root": {"yaw": 345, "roll": -24, "pitch": 0}, "torso": {"yaw": -16}}), "impact"),
         (S + 2.1, fly(AIR, (BENT, KNEE), {"root": {"yaw": 345, "pitch": 10}, "ra": {"raise": 60, "out": -20, "elbow": 110}}), "pass"),
         (S + 2.2, fly(AIR, (BENT, KNEE), {"root": {"yaw": 360, "pitch": 24}, "torso": {"pitch": 10, "yaw": -24},
                                           "ra": {"raise": 90, "out": -10, "elbow": 0}, "la": {"raise": 10, "out": 40, "elbow": 80}}), "impact"),
         (S + 2.42, fly(AIR, (HEEL_UP, BENT), {"root": {"yaw": 360, "pitch": -26}, "ra": {"raise": 30, "out": 60, "elbow": 20}, "la": {"raise": 30, "out": 60, "elbow": 20}}), "ease"),
         (S + 2.5, fly(AIR, (AXE, BENT), {"root": {"yaw": 360, "pitch": 14}}), "impact"),
         (S + 2.85, fly(AIR, ((0, -1.4, -1.1), BENT), {"root": {"yaw": 360, "pitch": 20}, "torso": {"pitch": 10}}), "ease"),
         (S + 3.25, s({"root": {"y": -1.0, "pitch": 26, "yaw": 360}, "torso": {"pitch": 16, "yaw": 0}, "rf": {"z": -.5, "toe": 20, "yaw": 0}, "lf": {"z": .9, "toe": -40, "yaw": 0},
                       "ra": {"raise": -30, "out": 40}, "la": {"raise": -30, "out": 40}}), "impact"),
         (S + T + TAIL, s({"root": {"yaw": 360 + kunai_lion.STANCE["root"]["yaw"]}}), "ease")]
    return clip(arm, "Lion.Ultimate", k)


def gaara(arm):
    s = gaara_p7.s
    S, T = ULT["pyramid"]
    OPEN = gaara_p7.OPEN
    reach = s({"ra": merge(OPEN, {"raise": 88, "wrist": -20}), "head": {"pitch": 2, "yaw": -6}, "root": {"y": -.08}})
    both = s({"ra": merge(OPEN, {"raise": 92, "out": 14, "wrist": -24}), "la": merge(OPEN, {"raise": 80, "out": 26, "wrist": -20}), "head": {"pitch": 0},
              "root": {"y": -.12}, "rf": {"x": .2, "z": .34}, "lf": {"x": -.18, "z": -.3}})
    up = merge(both, {"ra": {"raise": 128, "out": 10, "twist": -50, "elbow": 20}, "la": {"raise": 118, "out": 24, "twist": -50, "elbow": 24}, "head": {"pitch": -14}})
    close = merge(up, {"ra": {"raise": 112, "out": 6, "twist": -20, "elbow": 40, "wrist": 30}, "la": {"raise": 60, "out": 30, "twist": -20, "elbow": 40},
                       "root": {"y": -.2, "pitch": 4}, "torso": {"pitch": 4}, "head": {"pitch": -4}})
    fist = merge(close, {"ra": {"raise": 100, "elbow": 70, "twist": 0, "wrist": 40}, "root": {"y": -.26, "pitch": 8}, "torso": {"pitch": 8}, "head": {"pitch": 6}})
    k = [(0, s(), "ease"), (S * .7, s({"ra": merge(OPEN, {"raise": 60, "elbow": 40})}), "ease"), (S, reach, "ease"),
         (S + .6, merge(reach, {"ra": {"wrist": -30, "out": 6}}), "ease"),   # the sand floods, the fingers spread
         (S + 1.0, both, "ease"),
         (S + 1.55, merge(both, {"ra": {"raise": 100}, "la": {"raise": 88}}), "ease"),
         (S + 2.2, up, "ease"),                                                # lifted
         (S + 2.6, close, "ease"), (S + 2.85, merge(close, {"ra": {"elbow": 56, "wrist": 36}}), "ease"),
         (S + 2.92, fist, "impact"),                                            # Sabaku Soso
         (S + 3.2, merge(fist, {"ra": {"wrist": 44}}), "ease"),
         (S + 3.3, merge(fist, {"root": {"y": -.3}}), "impact"),
         (S + T + TAIL, s(), "ease")]
    return clip(arm, "Sand.Ultimate", k)


def lee(arm):
    s, AIR = lee_p8.s, lee_p8.AIR
    S, T = ULT["lotus"]
    roar = s({"root": {"y": -.9, "pitch": -8, "yaw": 0}, "torso": {"pitch": -14, "yaw": 0}, "head": {"pitch": -30, "yaw": 0},
              "ra": {"raise": 30, "out": 70, "twist": -30, "elbow": 60, "wrist": 0}, "la": {"raise": 30, "out": 70, "twist": -30, "elbow": 60, "wrist": 0},
              "rf": {"x": .5, "z": .4, "yaw": 20}, "lf": {"x": -.5, "z": -.3, "yaw": -20}})
    gather = s({"root": {"y": -1.0, "pitch": 30, "yaw": 0}, "torso": {"pitch": 24, "yaw": 0}, "head": {"pitch": 10},
                "ra": {"raise": 60, "out": -50, "twist": 30, "elbow": 120}, "la": {"raise": 60, "out": -50, "twist": 30, "elbow": 120},
                "rf": {"x": .4, "z": .3, "yaw": 10}, "lf": {"x": -.4, "z": -.3, "yaw": -10}})
    k = [(0, s(), "ease"), (S, gather, "ease"), (S + .2, gather, "ease"), (S + .32, roar, "impact"),
         (S + .38, merge(roar, {"root": {"y": -1.0, "pitch": 20}, "torso": {"pitch": 10}, "head": {"pitch": -10}, "rf": {"z": .8}}), "ease"),
         # the rising kick (Konoha Shofu): the right foot straight up through the chin
         (S + .42, fly(AIR, (KICK_HI, DOWN), {"root": {"y": -.2, "pitch": -30, "yaw": 0}, "torso": {"pitch": -10}, "head": {"pitch": -30},
                                              "la": {"raise": 0, "out": 50, "elbow": 10}, "ra": {"raise": 0, "out": 50, "elbow": 10}}), "impact"),
         (S + .9, fly(AIR, (BENT, DOWN), {"root": {"pitch": 0}}), "ease")]
    # the pinball: he bounces round the body, a kick, a fist, a kick, a fist
    for i, t in enumerate([1.0 + .15 * n for n in range(9)]):
        yaw = 24 if i % 2 == 0 else -24   # he orbits the body (the server's path): the body faces it, twisted into each blow
        kick = i % 2 == 0
        k.append((S + t - .06, fly(AIR, (TUCK, KNEE), {"root": {"yaw": yaw - 40, "pitch": 10}}), "pass"))
        if kick:
            k.append((S + t, fly(AIR, (KICK, TUCK) if i % 4 == 0 else (TUCK, KICK), {"root": {"yaw": yaw, "pitch": 6, "roll": 20 if i % 4 == 0 else -20}}), "impact"))
        else:
            arm_ = "ra" if i % 4 == 1 else "la"
            k.append((S + t, fly(AIR, (BENT, KNEE), {"root": {"yaw": yaw, "pitch": 20}, arm_: {"raise": 90, "out": -10, "elbow": 0}}), "impact"))
    pull = fly(AIR, (BENT, KNEE), {"root": {"yaw": 0, "pitch": -10}, "ra": {"raise": 60, "out": 10, "elbow": 120, "wrist": 0}, "la": {"raise": 30, "out": 40, "elbow": 60}})
    k += [(S + 2.3, fly(AIR, (BENT, DOWN), {"root": {"yaw": 0}, "ra": {"raise": 100, "out": 0, "elbow": 0}}), "launch"),   # the bandage thrown
          (S + 2.55, pull, "ease"),                                                                               # pulled in
          (S + 2.72, fly(AIR, ((0, -1.0, -1.65), BENT), {"root": {"pitch": 60, "yaw": 0}, "torso": {"pitch": 30}, "head": {"pitch": 20},
                                                          "ra": {"raise": 60, "out": -10, "elbow": 0}}), "impact"),
          (S + 3.08, fly(AIR, ((0, -1.1, -1.6), BENT), {"root": {"pitch": 80}, "torso": {"pitch": 30}, "ra": {"raise": 50, "elbow": 0}}), "ease"),
          (S + 3.12, s({"root": {"y": -1.2, "pitch": 34}, "torso": {"pitch": 24}, "ra": {"raise": 20, "out": 20, "elbow": 10}, "rf": {"z": -.4}, "lf": {"z": .9, "toe": -40}}), "impact"),
          (S + T + TAIL, s(), "ease")]
    return clip(arm, "Leaf.Ultimate", k)


def neji(arm):
    s = neji_p9.s
    S, T = ULT["palms"]
    stance = s({"root": {"y": -.95, "pitch": 6, "yaw": 50}, "torso": {"pitch": 4, "yaw": -24}, "head": {"yaw": -26},
                "ra": {"raise": 80, "out": -6, "twist": 0, "elbow": 10, "wrist": -70}, "la": {"raise": 30, "out": 10, "twist": 0, "elbow": 80, "wrist": -60},
                "rf": {"x": .4, "z": 1.1, "yaw": 50}, "lf": {"x": -.2, "z": -1.1, "yaw": 0}})
    palm_r = merge(stance, {"root": {"yaw": 34}, "torso": {"yaw": -34}, "ra": {"raise": 86, "out": -16, "elbow": 2}, "la": {"raise": 20, "out": 20, "elbow": 90}})
    palm_l = merge(stance, {"root": {"yaw": 62}, "torso": {"yaw": -10}, "la": {"raise": 86, "out": -16, "elbow": 2, "wrist": -70}, "ra": {"raise": 40, "out": 20, "elbow": 80}})
    k = [(0, s(), "ease"), (S, stance, "ease"), (S + .2, stance, "ease")]
    for i, t in enumerate(palm_times()):
        k.append((S + t, palm_r if i % 2 == 0 else palm_l, "impact"))
    still = merge(stance, {"ra": {"raise": 70, "out": 20, "elbow": 40}, "la": {"raise": 70, "out": 20, "elbow": 40}, "root": {"y": -1.0, "yaw": 50}})
    k += [(S + 3.0, still, "ease"), (S + 3.22, merge(still, {"root": {"y": -1.05}}), "ease"),
          (S + 3.3, merge(stance, {"root": {"y": -.8, "z": -.3, "yaw": 20, "pitch": 14}, "torso": {"yaw": 0, "pitch": 10},
                                   "ra": {"raise": 90, "out": 6, "elbow": 0, "wrist": -70}, "la": {"raise": 86, "out": 10, "elbow": 0, "wrist": -70},
                                   "lf": {"z": -1.5}}), "impact"),
          (S + T + TAIL, s(), "ease")]
    return clip(arm, "GentleFist.Ultimate", k)


def itachi(arm):
    s = itachi_p3.s
    S, T = ULT["tsukuyomi"]
    still = s({"root": {"y": -.1, "pitch": 0, "yaw": 0}, "torso": {"pitch": 0, "yaw": 0}, "head": {"pitch": 4, "yaw": 0},
               "ra": {"raise": -4, "out": 6, "twist": 0, "elbow": 6}, "la": {"raise": -4, "out": 6, "twist": 0, "elbow": 6},
               "rf": {"x": .12, "z": .1, "yaw": 4}, "lf": {"x": -.12, "z": -.1, "yaw": -4}})
    k = [(0, s(), "ease"), (S * .5, merge(still, {"head": {"pitch": 12}}), "ease"),
         (S, merge(still, {"head": {"pitch": -2}}), "impact"),              # the eyes come up: Mangekyo
         (S + .6, still, "ease"), (S + 2.0, merge(still, {"head": {"pitch": 2, "roll": 4}}), "ease"),
         (S + 3.3, still, "ease"), (S + 3.45, merge(still, {"head": {"pitch": 10, "yaw": -20}}), "ease"),
         (S + T + TAIL, merge(still, {"root": {"yaw": -40}, "head": {"yaw": -10, "pitch": 6}}), "ease")]
    return clip(arm, "Mirage.Ultimate", k)


def minato(arm):
    s = clips_flash2.s
    S, T = ULT["flash"]
    fan = s({"root": {"y": -.6, "pitch": 10, "yaw": 70}, "torso": {"yaw": -40}, "ra": {"raise": 90, "out": 60, "elbow": 6, "wrist": 10},
             "la": {"raise": 90, "out": 60, "elbow": 6}})
    k = [(0, s(), "ease"), (S, s({"ra": {"raise": 60, "out": -40, "elbow": 110}, "la": {"raise": 60, "out": -40, "elbow": 110}, "root": {"yaw": -40}}), "ease"),
         (S + .15, fan, "launch"), (S + .3, merge(fan, {"root": {"yaw": 160}}), "pass"), (S + .45, merge(fan, {"root": {"yaw": 250}}), "ease")]
    # a different cut each time he appears: the poses snap (hold), no in-between
    cuts = [
        {"root": {"y": -.9, "pitch": 30, "yaw": 0}, "torso": {"pitch": 20, "yaw": -30}, "ra": {"raise": 60, "out": 70, "elbow": 10, "wrist": -20}, "la": {"raise": -20, "out": 30}, "lf": {"z": -1.4}, "rf": {"z": 1.1}},
        {"root": {"y": -1.1, "pitch": 40, "yaw": 90}, "torso": {"pitch": 20, "yaw": 30}, "ra": {"raise": -40, "out": 60, "elbow": 6, "wrist": -30}, "la": {"raise": 60, "out": -20, "elbow": 60}, "lf": {"z": -1.2}, "rf": {"z": 1.2}},
        {"root": {"y": -.5, "pitch": 10, "yaw": -60}, "torso": {"pitch": 6, "yaw": -50}, "ra": {"raise": 120, "out": -30, "elbow": 10}, "la": {"raise": 0, "out": 50}, "lf": {"z": -.9}, "rf": {"z": .9}},
        {"root": {"y": -1.2, "pitch": 46, "yaw": 160}, "torso": {"pitch": 24, "yaw": 20}, "ra": {"raise": 20, "out": 90, "elbow": 0, "wrist": -40}, "la": {"raise": -30, "out": 20}, "lf": {"z": -1.5}, "rf": {"z": 1.3}},
    ]
    for i in range(8):
        k.append((S + .5 + i * .24, s(cuts[i % 4]), "hold"))
    back = s({"root": {"y": -.45, "pitch": 4, "yaw": 0}, "torso": {"pitch": 2, "yaw": 0}, "head": {"pitch": 0, "yaw": 0},
              "ra": {"raise": -10, "out": 30, "twist": 0, "elbow": 20, "wrist": -40}, "la": {"raise": -6, "out": 8, "elbow": 10}})
    k += [(S + 2.42, back, "hold"), (S + 2.86, back, "ease"),
          (S + 2.92, merge(back, {"ra": {"wrist": 20, "out": 40}}), "impact"),       # the flick: time starts again
          (S + T + TAIL, merge(back, {"head": {"yaw": -30}}), "ease")]
    return clip(arm, "Flashstep.Ultimate", k)


def kakashi(arm):
    s = kakashi_p6.s
    S, T = ULT["raikiri"]
    hold = s({"root": {"y": -.85, "z": -.1, "pitch": 24, "yaw": 30}, "torso": {"pitch": 14, "yaw": -4}, "head": {"pitch": -24},
              "ra": {"raise": -24, "out": 20, "twist": 0, "elbow": 40, "wrist": 30}, "la": {"raise": 10, "out": -10, "twist": 30, "elbow": 80},
              "rf": {"x": .3, "z": .9, "toe": -20}, "lf": {"z": -.8}})
    signs = [{"ra": {"raise": 70, "out": -40, "twist": 30, "elbow": 110}, "la": {"raise": 70, "out": -40, "twist": 30, "elbow": 110}},
             {"ra": {"raise": 80, "out": -30, "twist": 60, "elbow": 100}, "la": {"raise": 60, "out": -40, "twist": 0, "elbow": 120}},
             {"ra": {"raise": 60, "out": -36, "twist": 10, "elbow": 120}, "la": {"raise": 80, "out": -36, "twist": 50, "elbow": 100}}]
    run_a = s({"root": {"y": -.8, "pitch": 44, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0}, "head": {"pitch": -44},
               "ra": {"raise": -60, "out": 30, "elbow": 10, "wrist": 30}, "la": {"raise": 30, "out": 10, "elbow": 90},
               "rf": {"x": .2, "y": .9, "z": .9, "toe": -30, "yaw": 0}, "lf": {"x": -.2, "y": 0, "z": -1.3, "toe": 0, "yaw": 0}})
    run_b = merge(run_a, {"rf": {"y": 0, "z": -1.3, "toe": 0}, "lf": {"y": 1.0, "z": .9, "toe": -30}})
    thrust = s({"root": {"y": -.75, "z": -.5, "pitch": 28, "yaw": 0}, "torso": {"pitch": 14, "yaw": -10}, "head": {"pitch": -20},
                "ra": {"raise": 88, "out": -6, "twist": 0, "elbow": 4, "wrist": 30}, "la": {"raise": -20, "out": 30, "elbow": 20},
                "lf": {"z": -1.8, "yaw": 0}, "rf": {"z": 1.0, "toe": -40, "yaw": 0}})
    k = [(0, s(), "ease")]
    for i, sg in enumerate(signs):
        k.append((S * (i + 1) / 3, s(sg), "impact"))
    k += [(S + .4, hold, "ease"), (S + .9, merge(hold, {"root": {"y": -.95}, "ra": {"wrist": 40}}), "ease"), (S + 1.2, merge(hold, {"root": {"y": -1.0}}), "ease")]
    t, i = 1.25, 0
    while t < 2.35:          # the run: slow at first (the camera is in front of him), then flat out
        k.append((S + t, run_a if i % 2 == 0 else run_b, "pass"))
        t += .2 if t < 1.9 else .1
        i += 1
    k += [(S + 2.42, thrust, "impact"), (S + 2.86, merge(thrust, {"root": {"z": -.55}}), "ease"),
          (S + 2.92, merge(thrust, {"ra": {"raise": 60, "elbow": 40}, "root": {"z": -.2, "pitch": 10}}), "launch"),
          (S + T + TAIL, s(), "ease")]
    return clip(arm, "Copycat.Ultimate", k)


CASTERS = {"Legion": ("Naruto", naruto), "Lion": ("Sasuke", sasuke), "Sand": ("Gaara", gaara), "Leaf": ("Lee", lee),
           "GentleFist": ("Neji", neji), "Mirage": ("Itachi", itachi), "Flashstep": ("Minato", minato), "Copycat": ("Kakashi", kakashi)}
VICTIM_RIG = ("Naruto", "Legion")
