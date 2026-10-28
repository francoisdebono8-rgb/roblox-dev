"""Defence and hit reactions on the control rig (nd_ctrl / nd_shot), ANIM-005.

Re-authored pose to pose (the batch-2 clips of clips_react.py were made from
parameters on the FK rig, their feet slid with the body). Same runtime names:

  F.Guard, F.Guard.Impact
  F.Hit.Head / Body / Side / Back / Legs      (+ ".L": the other side, authored,
                                              not mirrored: the lead foot stays)
  F.Knockback (air, loops from "loop"), F.Knockback.Land
  F.Launched (air, loops), F.Knockdown, F.Down (loop), F.Getup (+ ".L")
  F.Dash.F, F.Cartwheel, F.Handspring, F.Chase (loop)

What every reaction answers (ANIMATION_CRAFT, exercise 5):
  contact   the part struck moves first, within 2-3 frames ("impact" spacing),
            the rest of the body follows late (the chest 3-4 frames, the arms
            fly out last: overlap);
  direction the body goes WITH the blow: away from the side struck, back from
            the front, forward from behind;
  force     the light/heavy amplitude is the runtime's (mix with frame 0);
  support   the feet are planted in the world: the server slides the body
            ~0.9 stud on a hit-stun, the planted foot stays and the other
            foot steps to catch the weight (a stagger, never a skate);
  recovery  the head comes back to the opponent first, then the guard, the
            stance is rebuilt with a step.
Sasuke takes a blow heavier and hangs in it (tempo 1.0); Minato gives less
and is back in his stance sooner (tempo .82, give .85).

Conventions (nd_ctrl): yaw + turns the body to its right, roll - leans it to
its left, x right, z back, feet are WORLD positions (planted = same value on
consecutive keys). The base Hit.Head: a blow from the attacker's right hand
(it lands on the left cheek): the head whips to the right. Hit.Side: struck
on the right side. ".L" variants are the other side.
"""
from nd_shot import Shot, merge, mirror


def add(base, delta, sgn=1):
    """base + delta on numeric channels; lateral channels (x, yaw, roll) are
    multiplied by sgn (the other side). Non-numeric/new keys are copied."""
    out = merge(base, {})
    for part, vals in delta.items():
        cur = dict(out.get(part, {}))
        for k, v in vals.items():
            d = v * sgn if k in ("x", "yaw", "roll") else v
            cur[k] = cur.get(k, 0) + d
        out[part] = cur
    return out


def setv(base, over, sgn=1):
    """Absolute values; the body's lateral channels (root/torso/head x, yaw,
    roll) mirrored by sgn. Feet are given already placed (Body.foot)."""
    out = {}
    for part, vals in over.items():
        lateral = part in ("root", "torso", "head")
        out[part] = {k: (v * sgn if lateral and k in ("x", "yaw", "roll") else v) for k, v in vals.items()}
    return merge(base, out)


class Body:
    def __init__(self, fighter, stance, tempo=1.0, give=1.0):
        self.F = fighter + "."
        self.stance = stance
        self.tempo = tempo
        self.give = give

    def f(self, n):
        return max(1, int(round(n * self.tempo)))

    def g(self, delta):
        """Scale the body's translation/rotation amplitude by give."""
        out = {}
        for part, vals in delta.items():
            out[part] = {k: v * self.give if part in ("root", "torso", "head") else v for k, v in vals.items()}
        return out

    def foot(self, side, dx=0.0, dz=0.0, y=0.0, sgn=1, **kw):
        st = self.stance["rf" if side == "R" else "lf"]
        out = {"x": st.get("x", 0) + dx * sgn, "z": st.get("z", 0) + dz, "y": y, "yaw": st.get("yaw", 0), "toe": 0}
        out.update(kw)
        return out


# ----------------------------------------------------------------- hits
def hit_head(b, arm, sgn=1, suffix=""):
    """Face, from the attacker's right hand: the head is struck first and
    whips to the right and up (2 frames); the chest follows 4 frames later
    and the hips are pushed back; the arms fly open last. The weight goes onto
    the rear foot (the front toes come up), the rear foot steps back to catch
    it; the head returns to the opponent before anything else, then the guard
    and a step rebuild the stance."""
    S = b.stance
    sh = Shot(arm, b.F + "Hit.Head" + suffix)
    sh.key(0, S, "ease")
    k1 = add(S, b.g({"head": {"pitch": -30, "yaw": 44, "roll": 16}, "torso": {"pitch": -6, "yaw": 10}, "root": {"z": .12, "pitch": -4}}), sgn)
    k1 = setv(k1, {"la": {"raise": 46, "out": 40, "twist": 0, "elbow": 52}, "ra": {"raise": 44, "out": 22, "twist": 10, "elbow": 86}}, sgn)
    sh.key(b.f(3), k1, "impact")
    k2 = add(S, b.g({"head": {"pitch": -22, "yaw": 38, "roll": 10}, "torso": {"pitch": -16, "yaw": 20, "roll": -6},
                     "root": {"y": -.08, "z": .36, "pitch": -9, "yaw": 12, "roll": -6}}), sgn)
    k2 = setv(k2, {"la": {"raise": 22, "out": 66, "elbow": 30}, "ra": {"raise": 30, "out": 54, "elbow": 42},
                   "lf": b.foot("L", toe=18), "rf": b.foot("R", dz=.18, y=.32, toe=-10)}, sgn)
    sh.key(b.f(7), k2, "pass")
    k3 = add(S, b.g({"head": {"pitch": -10, "yaw": 22}, "torso": {"pitch": -8, "yaw": 12},
                     "root": {"y": -.2, "z": .46, "pitch": -2, "yaw": 8, "roll": -2}}), sgn)
    k3 = setv(k3, {"la": {"raise": 34, "out": 52, "elbow": 44}, "ra": {"raise": 38, "out": 40, "elbow": 60},
                   "lf": b.foot("L", toe=8), "rf": b.foot("R", dx=.06, dz=.42, sgn=sgn)}, sgn)
    sh.key(b.f(11), k3, "impact")
    k4 = add(S, {"head": {"pitch": -2}, "root": {"y": -.12, "z": .34}})
    k4 = setv(k4, {"lf": b.foot("L"), "rf": b.foot("R", dx=.06, dz=.42, sgn=sgn)}, sgn)
    sh.key(b.f(17), k4, "pass")
    sh.key(b.f(21), merge(k4, {"rf": b.foot("R", dx=.03, dz=.22, y=.22, sgn=sgn)}), "pass")
    sh.key(b.f(26), S, "ease")
    sh.drag(["shoulder.L", "shoulder.R", "forearm.L", "forearm.R"], 1)
    return sh.build()


def hit_body(b, arm, sgn=1, suffix=""):
    """Body, from the front: the hips are driven back first and the chest
    folds hard over the blow (it wraps around the fist), the head goes down
    with it, both arms close over the stomach. Knees give, the weight sinks
    onto the rear foot which slides back a step; the chest comes up last."""
    S = b.stance
    sh = Shot(arm, b.F + "Hit.Body" + suffix)
    sh.key(0, S, "ease")
    fold = add(S, b.g({"root": {"y": -.18, "z": .34, "pitch": 14, "yaw": 6}, "torso": {"pitch": 34, "yaw": 8}, "head": {"pitch": 26}}), sgn)
    fold = setv(fold, {"ra": {"raise": 50, "out": -16, "twist": 10, "elbow": 128, "wrist": 0}, "la": {"raise": 44, "out": -14, "twist": 10, "elbow": 124}}, sgn)
    sh.key(b.f(3), fold, "impact")
    deep = add(S, b.g({"root": {"y": -.42, "z": .5, "pitch": 22, "yaw": 8}, "torso": {"pitch": 42, "yaw": 10}, "head": {"pitch": 30}}), sgn)
    deep = setv(deep, {"ra": {"raise": 46, "out": -12, "elbow": 124}, "la": {"raise": 40, "out": -10, "elbow": 120},
                       "rf": b.foot("R", dz=.2, y=.26, toe=-12), "lf": b.foot("L", toe=-6)}, sgn)
    sh.key(b.f(7), deep, "ease")
    catch = merge(deep, {"rf": b.foot("R", dz=.44), "root": {"y": S["root"]["y"] - .4 * b.give}})
    sh.key(b.f(10), catch, "impact")
    rise = add(S, b.g({"root": {"y": -.2, "z": .3, "pitch": 8}, "torso": {"pitch": 16}, "head": {"pitch": 8}}), sgn)
    rise = setv(rise, {"ra": {"raise": 48, "out": -10, "elbow": 112}, "la": {"raise": 56, "out": 0, "elbow": 80}, "rf": b.foot("R", dz=.44)}, sgn)
    sh.key(b.f(18), rise, "pass")
    sh.key(b.f(23), merge(S, {"rf": b.foot("R", dz=.2, y=.2)}), "pass")
    sh.key(b.f(28), S, "ease")
    sh.drag(["neck"], 1)
    return sh.build()


def hit_side(b, arm, sgn=1, suffix=""):
    """Side, struck on the right: the ribs are pushed in, the body bends and
    turns away to the left, the struck-side arm clamps down over the ribs,
    the other is thrown out for balance. The weight is thrown onto the left
    foot, which steps out to catch it; the hips come back over the feet."""
    S = b.stance
    sh = Shot(arm, b.F + "Hit.Side" + suffix)
    sh.key(0, S, "ease")
    k1 = add(S, b.g({"root": {"x": -.14, "roll": -14, "yaw": -14}, "torso": {"roll": -18, "yaw": -20, "pitch": 8}, "head": {"roll": -12, "yaw": -16}}), sgn)
    k1 = setv(k1, {"ra": {"raise": 30, "out": -6, "twist": 20, "elbow": 118}, "la": {"raise": 40, "out": 52, "elbow": 40}}, sgn)
    k1 = setv(k1, {}, sgn)
    sh.key(b.f(3), k1, "impact")
    step_side = "L" if sgn > 0 else "R"
    other = "R" if sgn > 0 else "L"
    k2 = add(S, b.g({"root": {"x": -.32, "y": -.16, "roll": -16, "yaw": -22}, "torso": {"roll": -16, "yaw": -24, "pitch": 12}, "head": {"roll": -8, "yaw": -18}}), sgn)
    k2 = setv(k2, {"ra": {"raise": 26, "out": -4, "elbow": 120}, "la": {"raise": 30, "out": 70, "elbow": 30}}, sgn)
    k2 = merge(k2, {step_side.lower() + "f": b.foot(step_side, dx=-.2, y=.28, sgn=sgn), other.lower() + "f": b.foot(other, toe=-8)})
    sh.key(b.f(7), k2, "pass")
    k3 = add(S, b.g({"root": {"x": -.4, "y": -.26, "roll": -6, "yaw": -14}, "torso": {"roll": -8, "yaw": -14, "pitch": 8}, "head": {"yaw": -8}}), sgn)
    k3 = setv(k3, {"ra": {"raise": 36, "out": 0, "elbow": 112}, "la": {"raise": 40, "out": 50, "elbow": 46}}, sgn)
    k3 = merge(k3, {step_side.lower() + "f": b.foot(step_side, dx=-.42, sgn=sgn), other.lower() + "f": b.foot(other)})
    sh.key(b.f(10), k3, "impact")
    k4 = add(S, {"root": {"x": -.2 * sgn, "y": -.1}})
    k4 = merge(k4, {step_side.lower() + "f": b.foot(step_side, dx=-.42, sgn=sgn)})
    sh.key(b.f(18), k4, "pass")
    sh.key(b.f(22), merge(k4, {step_side.lower() + "f": b.foot(step_side, dx=-.2, y=.2, sgn=sgn)}), "pass")
    sh.key(b.f(26), S, "ease")
    sh.drag(["shoulder.L", "shoulder.R"], 1)
    return sh.build()


def hit_back(b, arm, sgn=1, suffix=""):
    """From behind: the spine is struck, the hips are thrown forward under
    the chest (the body arches, the head is thrown back, the arms fly back),
    then the body falls forward over its front foot, which steps on to catch
    it; he turns his head to find the attacker as he rebuilds his stance."""
    S = b.stance
    sh = Shot(arm, b.F + "Hit.Back" + suffix)
    sh.key(0, S, "ease")
    k1 = add(S, b.g({"root": {"z": -.24, "pitch": -14}, "torso": {"pitch": -24}, "head": {"pitch": -26, "yaw": 8}}), sgn)
    k1 = setv(k1, {"ra": {"raise": -30, "out": 38, "twist": 0, "elbow": 34}, "la": {"raise": -26, "out": 36, "twist": 0, "elbow": 30}}, sgn)
    sh.key(b.f(3), k1, "impact")
    k2 = add(S, b.g({"root": {"y": -.1, "z": -.46, "pitch": 6}, "torso": {"pitch": 2}, "head": {"pitch": -10, "yaw": 14}}), sgn)
    k2 = setv(k2, {"ra": {"raise": 10, "out": 50, "elbow": 40}, "la": {"raise": 20, "out": 50, "elbow": 40},
                   "lf": b.foot("L", dz=-.3, y=.3, toe=10), "rf": b.foot("R", toe=-20)}, sgn)
    sh.key(b.f(7), k2, "pass")
    k3 = add(S, b.g({"root": {"y": -.3, "z": -.62, "pitch": 12}, "torso": {"pitch": 8}, "head": {"pitch": -6, "yaw": 30}}), sgn)
    k3 = setv(k3, {"ra": {"raise": 36, "out": 36, "elbow": 60}, "la": {"raise": 46, "out": 30, "elbow": 56},
                   "lf": b.foot("L", dz=-.56), "rf": b.foot("R", toe=-14)}, sgn)
    sh.key(b.f(10), k3, "impact")
    k4 = add(S, {"root": {"y": -.1, "z": -.36}, "head": {"yaw": 14 * sgn}})
    k4 = merge(k4, {"lf": b.foot("L", dz=-.56)})
    sh.key(b.f(18), k4, "pass")
    sh.key(b.f(22), merge(k4, {"rf": b.foot("R", dz=-.28, y=.24)}), "pass")
    end = merge(S, {"rf": b.foot("R", dz=-.56), "lf": b.foot("L", dz=-.56)})
    sh.key(b.f(27), end, "ease")
    sh.drag(["neck"], 2)
    return sh.build()


def hit_legs(b, arm, sgn=1, suffix=""):
    """Low blow: the struck knee buckles in (the front knee; the rear one for
    the other side), the hips drop over it and lean toward it, the chest
    pitches forward and the arms go out for balance; the knee is pushed back
    straight and the stance comes up again."""
    S = b.stance
    side = "L" if sgn > 0 else "R"
    sh = Shot(arm, b.F + "Hit.Legs" + suffix)
    sh.key(0, S, "ease")
    roll = -14 if side == "L" else 14
    k1 = add(S, b.g({"root": {"y": -.36, "pitch": 10, "roll": roll * .6}, "torso": {"pitch": 10}, "head": {"pitch": 10}}))
    k1 = merge(k1, {side.lower() + "f": b.foot(side, knee=-24, toe=-12)})
    k1 = setv(k1, {"ra": {"raise": 40, "out": 40, "elbow": 50}, "la": {"raise": 40, "out": 42, "elbow": 48}})
    sh.key(b.f(3), k1, "impact")
    k2 = add(S, b.g({"root": {"y": -.62, "pitch": 16, "roll": roll, "z": .05}, "torso": {"pitch": 14, "roll": -roll * .5}, "head": {"pitch": 12, "yaw": 10 * (1 if side == "L" else -1)}}))
    k2 = merge(k2, {side.lower() + "f": b.foot(side, knee=-30, toe=-20)})
    k2 = setv(k2, {"ra": {"raise": 54, "out": 60, "elbow": 36}, "la": {"raise": 50, "out": 62, "elbow": 34}})
    sh.key(b.f(8), k2, "ease")
    k3 = add(S, b.g({"root": {"y": -.3, "pitch": 8, "roll": roll * .3}, "torso": {"pitch": 6}}))
    k3 = setv(k3, {"ra": {"raise": 46, "out": 30, "elbow": 70}, "la": {"raise": 56, "out": 20, "elbow": 60}})
    sh.key(b.f(18), k3, "pass")
    sh.key(b.f(30), S, "ease")
    sh.drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build()


# ---------------------------------------------------------------- guard
def guards(b, arm):
    """Guard: the forearms cross in front of the face, the chin tucks
    behind them, the weight drops and goes a little onto the rear foot
    (braced to take, not to strike). Impact: the guard is driven into the
    face, the hips are pushed back over the rear heel, the knees take it,
    then the arms push back out."""
    S = b.stance
    g = add(S, {"root": {"y": -.14, "z": .1, "pitch": -2}, "torso": {"pitch": 6, "yaw": 4}, "head": {"pitch": 14, "yaw": 6}})
    g = setv(g, {"ra": {"raise": 92, "out": -34, "twist": 42, "elbow": 114, "wrist": -10},
                 "la": {"raise": 96, "out": -30, "twist": 40, "elbow": 110, "wrist": -10}})
    breathe = add(g, {"root": {"y": -.03}, "torso": {"pitch": 1.5}, "ra": {"elbow": 2}, "la": {"elbow": 2}})
    out = []
    gu = Shot(arm, b.F + "Guard")
    gu.key(0, g, "ease").key(36, breathe, "ease").key(72, g, "ease")
    gu.drag(["shoulder.L", "shoulder.R"], 3)
    out.append(gu.build(loop=True))
    im = Shot(arm, b.F + "Guard.Impact")
    im.key(0, g, "ease")
    hit = add(g, {"root": {"y": -.22, "z": .3, "pitch": -4}, "torso": {"pitch": -6}, "head": {"pitch": 6},
                  "ra": {"raise": -8, "elbow": 10}, "la": {"raise": -8, "elbow": 10}})
    hit = merge(hit, {"lf": b.foot("L", toe=14), "rf": b.foot("R", toe=0)})
    im.key(b.f(2), hit, "impact")
    im.key(b.f(7), add(g, {"root": {"y": -.26, "z": .22}, "torso": {"pitch": 2}}), "ease")
    im.key(b.f(22), g, "ease")
    im.drag(["neck"], 1)
    out.append(im.build())
    return out


# ------------------------------------------------------------ air / down
def flights(b, arm):
    """Knockback: the blow takes the hips first - they are thrown back off
    the feet, the chest and head follow (the chin stays tucked, the eyes on
    the attacker), arms and legs trail toward him. Held in the air (loops),
    the limbs drift. Land: the feet find the floor first, the body skids
    back low over them, both hands out, and pushes back up into the stance.
    Launched: the chin takes it, the body whips back then folds around the
    blow and is carried up, legs tucked, arms trailing below. Knockdown:
    thrown back and down, onto the back. Down: lying, the chest breathes.
    Getup: rolls to the side, a hand and knee under him, up into stance."""
    S = b.stance
    out = []
    fly = {"root": {"x": 0, "y": -.2, "z": 0, "pitch": -44, "yaw": 0, "roll": 6}, "torso": {"pitch": -16, "yaw": 8, "roll": 0}, "head": {"pitch": 14, "yaw": 0, "roll": 0},
           "ra": {"raise": 104, "out": 48, "twist": 0, "elbow": 30, "wrist": 0}, "la": {"raise": 94, "out": 44, "twist": 0, "elbow": 28, "wrist": 0},
           "rf": {"x": .05, "z": -1.3, "y": 1.15, "toe": -20, "yaw": 0, "knee": 0}, "lf": {"x": -.05, "z": -.9, "y": .7, "toe": -30, "yaw": 0, "knee": 0}}
    fly2 = add(fly, {"root": {"pitch": -6}, "ra": {"raise": 10, "elbow": 6}, "la": {"raise": -8, "elbow": 12},
                     "rf": {"y": -.15, "z": .2}, "lf": {"y": .25, "z": -.25}})
    kb = Shot(arm, b.F + "Knockback")
    kb.key(0, S, "ease")
    kb.key(b.f(4), merge(fly, {"root": {"pitch": -30}, "rf": {"z": -.6, "y": .5}, "lf": {"z": -.2, "y": .2}}), "impact")
    kb.key(12, fly, "pass").key(24, fly2, "ease").key(36, fly, "ease")
    kb.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 2)
    out.append(kb.build(markers={"loop": 12 / 60}))

    skid = add(S, {"root": {"y": -.62, "z": .24, "pitch": 16}, "torso": {"pitch": 12}, "head": {"pitch": -14}})
    skid = setv(skid, {"ra": {"raise": 46, "out": 58, "elbow": 30}, "la": {"raise": 40, "out": 60, "elbow": 30},
                       "rf": b.foot("R", dz=.12), "lf": b.foot("L", dz=-.3)})
    ld = Shot(arm, b.F + "Knockback.Land")
    ld.key(0, merge(skid, {"root": {"y": S["root"]["y"] - .3}}), "impact")
    ld.key(b.f(5), add(skid, {"root": {"y": -.12}}), "ease")
    ld.key(b.f(14), merge(add(S, {"root": {"y": -.2}}), {"rf": b.foot("R", dz=.12), "lf": b.foot("L", dz=-.3)}), "pass")
    ld.key(b.f(18), merge(S, {"lf": b.foot("L", dz=-.15, y=.2), "rf": b.foot("R", dz=.12)}), "pass")
    ld.key(b.f(24), S, "ease")
    ld.drag(["neck"], 2)
    out.append(ld.build())

    whip = {"root": {"x": 0, "y": -.1, "z": 0, "pitch": -26, "yaw": 0, "roll": 0}, "torso": {"pitch": -34, "yaw": 0, "roll": 0}, "head": {"pitch": -46, "yaw": 0, "roll": 0},
            "ra": {"raise": -20, "out": 40, "twist": 0, "elbow": 30, "wrist": 0}, "la": {"raise": -20, "out": 38, "twist": 0, "elbow": 26, "wrist": 0},
            "rf": {"x": 0, "z": .1, "y": .3, "toe": -40, "yaw": 0, "knee": 0}, "lf": {"x": 0, "z": .3, "y": .1, "toe": -40, "yaw": 0, "knee": 0}}
    folded = merge(whip, {"root": {"y": -.5, "pitch": -10, "roll": 8}, "torso": {"pitch": -14, "yaw": 14}, "head": {"pitch": -18},
                          "ra": {"raise": -40, "out": 44, "elbow": 32}, "la": {"raise": -36, "out": 40, "elbow": 26},
                          "rf": {"z": -.7, "y": 1.3, "toe": -30, "knee": 6}, "lf": {"z": -.2, "y": .9, "toe": -36}})
    trail = add(folded, {"ra": {"raise": 14, "out": 6}, "la": {"raise": -10}, "torso": {"roll": 6},
                         "rf": {"y": -.2, "z": .2}, "lf": {"y": .2, "z": -.2}})
    la = Shot(arm, b.F + "Launched")
    la.key(0, S, "ease")
    la.key(3, whip, "impact").key(12, folded, "ease").key(30, trail, "ease").key(48, folded, "ease")
    la.drag(["shoulder.L", "shoulder.R"], 2)
    out.append(la.build(markers={"loop": 12 / 60}))

    LYING = {"root": {"x": 0, "y": -2.3, "z": .7, "pitch": -84, "yaw": 0, "roll": 12}, "torso": {"pitch": -6, "yaw": 0, "roll": 6}, "head": {"pitch": -12, "yaw": 22, "roll": 0},
             "ra": {"raise": 20, "out": 62, "twist": 0, "elbow": 24, "wrist": 0}, "la": {"raise": 14, "out": 56, "twist": 0, "elbow": 30, "wrist": 0},
             "rf": {"x": .15, "z": -1.25, "y": 0, "toe": 50, "yaw": 20, "knee": 10}, "lf": {"x": -.1, "z": -.9, "y": 0, "toe": 30, "yaw": -10, "knee": 40}}
    kd = Shot(arm, b.F + "Knockdown")
    kd.key(0, merge(fly, {"root": {"pitch": -20}}), "ease")
    mid = merge(fly, {"root": {"y": -1.1, "z": .4, "pitch": -56, "roll": 10}, "rf": {"z": -1.2, "y": .9}, "lf": {"z": -.8, "y": .5}})
    kd.key(9, mid, "pass")
    kd.key(14, merge(LYING, {"root": {"y": -2.15}}), "impact")
    kd.key(20, LYING, "ease")
    out.append(kd.build())
    dn = Shot(arm, b.F + "Down")
    dn.key(0, LYING, "ease").key(45, add(LYING, {"torso": {"pitch": -3}, "head": {"pitch": -3}, "ra": {"elbow": 4}}), "ease").key(90, LYING, "ease")
    out.append(dn.build(loop=True))

    for sgn, suffix in ((1, ""), (-1, ".L")):
        lying = add(LYING, {}, 1) if sgn > 0 else mirror(LYING)
        roll = setv(lying, {"root": {"y": -2.0, "z": .5, "pitch": -50, "roll": 40}, "torso": {"pitch": 10, "roll": 10}, "head": {"pitch": 0, "yaw": -10},
                            "ra": {"raise": 30, "out": 40, "elbow": 40}, "la": {"raise": 60, "out": -10, "elbow": 90},
                            "rf": {"x": .3, "z": -.9, "y": 0, "toe": 20, "yaw": 10, "knee": 30}, "lf": {"x": -.2, "z": -.4, "y": 0, "toe": 0, "yaw": 0, "knee": 60}}, sgn)
        kneel = setv(S, {"root": {"x": 0, "y": -1.45, "z": .2, "pitch": 28, "yaw": 20, "roll": 0}, "torso": {"pitch": 18, "yaw": -6, "roll": 0}, "head": {"pitch": -14, "yaw": -12, "roll": 0},
                         "ra": {"raise": 40, "out": 24, "elbow": 60}, "la": {"raise": 40, "out": 20, "elbow": 70},
                         "lf": b.foot("L", dz=-.1), "rf": b.foot("R", dz=.1, toe=-40)})
        gu = Shot(arm, b.F + "Getup" + suffix)
        gu.key(0, lying, "ease").key(6, roll, "pass").key(12, kneel, "pass").key(20, add(S, {"root": {"y": -.2}}), "ease").key(24, S, "ease")
        gu.drag(["neck"], 2)
        out.append(gu.build())
    return out


# --------------------------------------------------------------- dodges
def dodges(b, arm):
    """Dash.F: he loads low over the front foot and pushes off the rear one
    (the push is in the leg, the body falls forward), glides low with the
    arms swept back, brakes on the front foot. Cartwheel/Handspring: the body
    shape only, the engine turns it over (feet relative to the hips)."""
    S = b.stance
    out = []
    load = setv(S, {"root": {"x": 0, "y": -.95, "z": -.1, "pitch": 24, "yaw": 0, "roll": 0}, "torso": {"pitch": 12, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
                    "ra": {"raise": 20, "out": 24, "elbow": 60}, "la": {"raise": 30, "out": 24, "elbow": 70},
                    "lf": {"x": -.1, "z": -.6, "y": 0, "yaw": 0, "toe": 0}, "rf": {"x": .1, "z": 1.1, "y": 0, "yaw": 0, "toe": -30}})
    glide = merge(load, {"root": {"y": -.8, "pitch": 38}, "torso": {"pitch": 12}, "head": {"pitch": -34},
                         "ra": {"raise": -50, "out": 20, "elbow": 14}, "la": {"raise": -50, "out": 20, "elbow": 14},
                         "lf": {"z": -1.0, "y": .35, "toe": -10}, "rf": {"z": 1.3, "y": .5, "toe": -40}})
    brake = setv(S, {"root": {"x": 0, "y": -.85, "z": .05, "pitch": 4, "yaw": 10, "roll": 0}, "torso": {"pitch": 4},
                     "ra": {"raise": 46, "out": 40, "elbow": 40}, "la": {"raise": 52, "out": 36, "elbow": 50},
                     "lf": {"x": -.1, "z": -.9, "y": 0, "yaw": 0, "toe": 10}, "rf": {"x": .2, "z": .9, "y": 0, "yaw": 20, "toe": 0}})
    d = Shot(arm, b.F + "Dash.F")
    d.key(0, load, "ease").key(5, glide, "launch").key(15, add(glide, {"root": {"y": .05}}), "ease").key(20, brake, "impact")
    d.drag(["neck"], 1)
    out.append(d.build())
    base = {"x": 0, "z": 0, "yaw": 0}
    cart = [(0, {"root": {"x": 0, "y": -.5, "z": 0, "pitch": 0, "yaw": 0, "roll": 0}, "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
                 "ra": {"raise": 60, "out": 60, "twist": 0, "elbow": 20, "wrist": 0}, "la": {"raise": 60, "out": 60, "twist": 0, "elbow": 20, "wrist": 0},
                 "rf": dict(base, x=.4, y=.3, toe=-20), "lf": dict(base, x=-.3, y=0, toe=0)}, "launch"),
            (7, {"root": {"y": -.3}, "torso": {"pitch": 4}, "ra": {"raise": 170, "out": 30, "elbow": 6}, "la": {"raise": 170, "out": 30, "elbow": 6},
                 "rf": dict(base, x=1.6, y=1.8, toe=-30), "lf": dict(base, x=-1.6, y=1.8, toe=-30)}, "pass"),
            (14, {"root": {"y": -.3}, "ra": {"raise": 160, "out": 40, "elbow": 10}, "la": {"raise": 160, "out": 40, "elbow": 10},
                  "rf": dict(base, x=1.4, y=1.6, toe=-30), "lf": dict(base, x=-1.5, y=1.7, toe=-30)}, "pass"),
            (20, {"root": {"y": -.75, "pitch": 10}, "torso": {"pitch": 6}, "ra": {"raise": 50, "out": 50, "elbow": 40}, "la": {"raise": 50, "out": 50, "elbow": 40},
                  "rf": dict(base, x=.3, y=0, toe=0), "lf": dict(base, x=-.2, y=.3, toe=-20)}, "impact")]
    c = Shot(arm, b.F + "Cartwheel")
    for fr, spec, sp in cart:
        c.key(fr, spec, sp)
    out.append(c.build())
    hand = [(0, {"root": {"x": 0, "y": -.6, "z": 0, "pitch": -6, "yaw": 0, "roll": 0}, "torso": {"pitch": -8, "yaw": 0, "roll": 0}, "head": {"pitch": 14, "yaw": 0, "roll": 0},
                 "ra": {"raise": 120, "out": 20, "twist": 0, "elbow": 30, "wrist": 0}, "la": {"raise": 120, "out": 20, "twist": 0, "elbow": 30, "wrist": 0},
                 "rf": dict(base, z=-.2, y=0, toe=-20), "lf": dict(base, z=.2, y=0, toe=-20)}, "launch"),
            (7, {"root": {"y": -.4}, "torso": {"pitch": -18}, "head": {"pitch": 30}, "ra": {"raise": 172, "out": 22, "elbow": 6}, "la": {"raise": 172, "out": 22, "elbow": 6},
                 "rf": dict(base, z=.3, y=.6, toe=-40), "lf": dict(base, z=.6, y=.3, toe=-40)}, "pass"),
            (14, {"root": {"y": -.4}, "torso": {"pitch": -6}, "head": {"pitch": 16}, "ra": {"raise": 160, "out": 26, "elbow": 14}, "la": {"raise": 160, "out": 26, "elbow": 14},
                  "rf": dict(base, z=-.6, y=1.4, toe=-30), "lf": dict(base, z=-.8, y=1.5, toe=-30)}, "pass"),
            (20, {"root": {"y": -.8, "pitch": 14}, "torso": {"pitch": 10}, "head": {"pitch": -10}, "ra": {"raise": 60, "out": 40, "elbow": 50}, "la": {"raise": 60, "out": 40, "elbow": 50},
                  "rf": dict(base, z=.4, y=0, toe=0), "lf": dict(base, z=-.4, y=0, toe=0)}, "impact")]
    h = Shot(arm, b.F + "Handspring")
    for fr, spec, sp in hand:
        h.key(fr, spec, sp)
    out.append(h.build())
    # The chase: a flat ninja dash after a launched body, legs cycling under,
    # arms swept back (a cycle; the feet are relative to the hips, in the air).
    ch = Shot(arm, b.F + "Chase")
    pose = {"root": {"x": 0, "y": -.2, "z": 0, "pitch": 48, "yaw": 0, "roll": 0}, "torso": {"pitch": 14, "yaw": 0, "roll": 0}, "head": {"pitch": -48, "yaw": 0, "roll": 0},
            "ra": {"raise": -72, "out": 18, "twist": -10, "elbow": 10, "wrist": 0}, "la": {"raise": -72, "out": 18, "twist": -10, "elbow": 10, "wrist": 0}}
    a = merge(pose, {"rf": {"x": .05, "z": -1.0, "y": 1.2, "toe": -20, "yaw": 0, "knee": 0}, "lf": {"x": -.05, "z": .9, "y": 1.3, "toe": -50, "yaw": 0, "knee": 0}})
    bb = merge(pose, {"root": {"y": -.14}, "lf": {"x": -.05, "z": -1.0, "y": 1.2, "toe": -20}, "rf": {"x": .05, "z": .9, "y": 1.3, "toe": -50}})
    ch.key(0, a, "pass").key(12, bb, "pass").key(24, a, "pass")
    out.append(ch.build(loop=True))
    return out


def author(arm, fighter, stance, tempo=1.0, give=1.0):
    b = Body(fighter, stance, tempo, give)
    acts = []
    acts += guards(b, arm)
    for fn, name in ((hit_head, "Head"), (hit_body, "Body"), (hit_side, "Side"), (hit_back, "Back"), (hit_legs, "Legs")):
        acts.append(fn(b, arm, 1, ""))
        acts.append(fn(b, arm, -1, ".L"))
    acts += flights(b, arm)
    acts += dodges(b, arm)
    return acts
