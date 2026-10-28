"""Sasuke's kunai string (ANIM-005, user reference 28/10): the ground combo
re-animated as a ninja's, with a kunai in the right hand, amplified poses.

Animator's notes (what the reference does and the old string did not):
  * every blow is a WHOLE-BODY arc: the hips turn 60-90 deg, the chest snaps
    past them, the arm is the last link and travels a wide arc (the blade
    draws a half circle, not a straight punch line);
  * contrast of spacing: a slow, deep anticipation (coil), 2-3 frames of
    whip into the contact, a held overshoot that reads as a pose, then a
    relaxed recovery;
  * the body travels: each blow steps in (1-1.6 studs);
  * Heavy is a front somersault into a downward axe slash (the salto).

Same vocabulary as clips_lion2 (yaw + turns right, pitch + leans forward,
roll + leans right; feet are WORLD positions, x right, z back, y lift).
Markers (contact/recover) keep the server's frame data of the old clips.
"""
import math
from mathutils import Vector, Matrix
from nd_shot import Shot, merge, mirror
import nd_anim

STANCE = {"root": {"y": -.5, "z": -.08, "pitch": 10, "yaw": 30}, "torso": {"pitch": 6, "yaw": -14},
          "head": {"pitch": -6, "yaw": -16},
          "la": {"raise": 66, "out": 6, "twist": 10, "elbow": 64}, "ra": {"raise": 52, "out": -16, "twist": 24, "elbow": 118},
          "rf": {"x": .26, "z": .84, "yaw": 38}, "lf": {"x": -.1, "z": -.76, "yaw": -6}}
STANCE_R = mirror(STANCE)
H = 3.0


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    """The stance moved T studs along z (feet with it)."""
    base = merge(STANCE, {"travel": {"z": T}, "rf": {"z": .84 + T}, "lf": {"z": -.76 + T}})
    return merge(base, over or {})


# ------------------------------------------------------------- Light1
def light1(arm):
    """Draw-slash. Coil: the hips turn away (yaw 52), the body drops, the
    right hand reaches the thigh holster, the lead foot unweights. Whip: the
    lead foot steps a full stud, the hips turn back through, the chest snaps
    past them and the arm unrolls LAST: the blade rises across the body
    (low right -> high left). It overshoots above the head and holds there
    (the pose that reads), then folds back to guard while the rear foot drags
    up."""
    sh = Shot(arm, "Lion.Light1")
    T = -1.0
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.76, "z": .06, "pitch": 18, "yaw": 54, "roll": 6}, "torso": {"pitch": 14, "yaw": 18, "roll": 10},
                 "head": {"pitch": -14, "yaw": -62},
                 "ra": {"raise": -26, "out": 24, "twist": 30, "elbow": 36, "wrist": -20},
                 "la": {"raise": 84, "out": -26, "twist": 10, "elbow": 44},
                 "lf": {"x": -.12, "z": -.98, "y": .2, "toe": 12}, "rf": {"toe": -6}}), "ease")
    hit = s({"travel": {"z": -.55}, "root": {"y": -.66, "z": -.52, "pitch": 16, "yaw": -2, "roll": -6},
             "torso": {"pitch": 4, "yaw": -38, "roll": -12}, "head": {"pitch": -8, "yaw": 36},
             "ra": {"raise": 84, "out": 26, "twist": -30, "elbow": 8, "wrist": -24},
             "la": {"raise": 8, "out": 62, "twist": 0, "elbow": 30},
             "lf": {"x": -.14, "z": -.76 + T, "y": 0, "toe": 0, "yaw": -10}, "rf": {"y": .16, "toe": -34, "yaw": 8}})
    sh.key(6, hit, "impact")
    over = merge(hit, {"root": {"y": -.56, "z": -.58, "pitch": 8, "yaw": -14, "roll": -8},
                       "torso": {"pitch": -8, "yaw": -56, "roll": -16}, "head": {"pitch": -12, "yaw": 48},
                       "ra": {"raise": 152, "out": -30, "twist": -40, "elbow": 10, "wrist": -26},
                       "la": {"raise": -8, "out": 72, "elbow": 18}})
    sh.key(9, over, "ease")
    sh.key(13, merge(over, {"root": {"y": -.6}, "ra": {"raise": 146}, "torso": {"yaw": -52}}), "ease")
    sh.key(19, s({"travel": {"z": -.8}, "root": {"y": -.54, "z": -.24, "pitch": 10, "yaw": 16}, "torso": {"pitch": 6, "yaw": -10, "roll": -4},
                  "head": {"yaw": -8}, "ra": {"raise": 62, "out": -12, "twist": 20, "elbow": 100},
                  "la": {"raise": 60, "out": 4, "elbow": 66},
                  "lf": {"x": -.14, "z": -.76 + T}, "rf": {"z": .3 + T * .2, "y": .12, "toe": -14}}), "pass")
    sh.key(28, at(T, {"lf": {"x": -.14}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1).drag(["shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


# ------------------------------------------------------------- Light2
def light2(arm):
    """Backhand return, stepping through. The blade is wound to the LEFT
    shoulder (the chest turned away the other way: opposite coil), the rear
    foot passes the lead one in the air, and as it lands a full step ahead
    the hips and chest whip right and the straight arm sweeps flat from left
    to right. Overshoot: the arm swings out behind the right shoulder, the
    left hand guards. Ends right-lead, ready for the spin."""
    sh = Shot(arm, "Lion.Light2")
    sh.key(0, s(), "ease")
    sh.key(4, s({"root": {"y": -.68, "z": -.3, "pitch": 14, "yaw": 4, "roll": -4}, "torso": {"pitch": 10, "yaw": -42, "roll": -8},
                 "head": {"pitch": -8, "yaw": 22},
                 "ra": {"raise": 72, "out": -72, "twist": 40, "elbow": 122, "wrist": 22},
                 "la": {"raise": 40, "out": 34, "elbow": 92},
                 "rf": {"y": .14, "toe": -32}, "lf": {"yaw": -20}}), "ease")
    sh.key(8, s({"travel": {"z": -.55}, "root": {"y": -.5, "z": -.42, "pitch": 10, "yaw": -12}, "torso": {"pitch": 8, "yaw": -50, "roll": -6},
                 "head": {"yaw": 40}, "ra": {"raise": 76, "out": -78, "twist": 40, "elbow": 118, "wrist": 22},
                 "la": {"raise": 36, "out": 40, "elbow": 88},
                 "rf": {"x": .22, "z": -.7, "y": .5, "toe": -10, "yaw": 10}, "lf": {"yaw": -26}}), "pass")
    hit = s({"travel": {"z": -1.0}, "root": {"y": -.72, "z": -.46, "pitch": 16, "yaw": 30, "roll": 8},
             "torso": {"pitch": 6, "yaw": 40, "roll": 10}, "head": {"pitch": -6, "yaw": -56},
             "ra": {"raise": 88, "out": 62, "twist": -10, "elbow": 2, "wrist": 10},
             "la": {"raise": 52, "out": -22, "twist": 20, "elbow": 104},
             "rf": {"x": .24, "z": -2.3, "y": 0, "toe": 0, "yaw": 30}, "lf": {"x": -.1, "z": -.76, "y": .1, "toe": -22, "yaw": -40}})
    sh.key(11, hit, "impact")
    over = merge(hit, {"root": {"yaw": 42, "roll": 10}, "torso": {"yaw": 58, "roll": 12}, "head": {"yaw": -70},
                       "ra": {"raise": 82, "out": 98, "twist": -16, "elbow": 6}})
    sh.key(14, over, "ease")
    sh.key(17, merge(over, {"root": {"y": -.7}, "ra": {"out": 94}}), "ease")
    T = -1.54
    end = merge(STANCE_R, {"travel": {"z": T}, "rf": {"x": .24, "z": -2.3}, "lf": {"x": -.26, "z": .84 + T}})
    sh.key(24, merge(end, {"root": {"y": -.6, "yaw": -12}, "torso": {"yaw": 20}, "ra": {"raise": 60, "out": 20, "elbow": 90},
                           "lf": {"x": -.2, "z": .2 + T * .5, "y": .1, "toe": -12, "yaw": -30}}), "pass")
    sh.key(32, end, "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1).drag(["shoulder.L", "forearm.L"], 2)
    return sh.build(markers={"contact": 11 / 60, "recover": 20 / 60})


# ------------------------------------------------------------- Light3
def light3(arm):
    """Spinning slash (finisher), from the right-lead stance. Counter-coil
    left, then a full turn to the right pivoting on the ball of the front
    foot: the head whips round first (spotting), the arm opens straight out
    so the blade draws a flat circle at chest height; it crosses the target
    at frame 14 with the body leaning into the turn. The left leg sweeps
    round low and lands ahead: left lead again, square."""
    sh = Shot(arm, "Lion.Light3")
    st = merge(STANCE_R, {"rf": {"x": .1, "z": -.76, "yaw": 6}, "lf": {"x": -.26, "z": .84, "yaw": -38}})
    sh.key(0, st, "ease")
    sh.key(4, merge(st, {"root": {"y": -.72, "yaw": -34, "z": -.22, "pitch": 14}, "torso": {"yaw": -30, "pitch": 10}, "head": {"yaw": 50},
                         "ra": {"raise": 62, "out": -62, "twist": 30, "elbow": 104},
                         "la": {"raise": 56, "out": 40, "elbow": 64},
                         "rf": {"yaw": -10}, "lf": {"y": .1, "toe": -28}}), "ease")
    sh.key(7, merge(st, {"root": {"y": -.56, "yaw": 72, "z": -.26, "pitch": 8}, "torso": {"yaw": 14}, "head": {"yaw": 60},
                         "ra": {"raise": 84, "out": 30, "twist": 0, "elbow": 40},
                         "la": {"raise": 30, "out": 50, "elbow": 60},
                         "rf": {"yaw": 88}, "lf": {"x": .2, "z": .3, "y": .45, "toe": -20, "yaw": 70}}), "pass")
    sh.key(10, merge(st, {"root": {"y": -.5, "yaw": 168, "z": -.3, "pitch": 6, "roll": 8}, "torso": {"yaw": 20, "roll": 6}, "head": {"yaw": 70},
                          "ra": {"raise": 90, "out": 74, "twist": -6, "elbow": 8},
                          "la": {"raise": 20, "out": 64, "elbow": 40},
                          "rf": {"yaw": 175}, "lf": {"x": 1.0, "z": -.2, "y": .5, "toe": -16, "yaw": 160}}), "pass")
    hit = merge(st, {"root": {"y": -.6, "yaw": 262, "z": -.36, "pitch": 12, "roll": 14}, "torso": {"yaw": 6, "roll": 10, "pitch": 6},
                     "head": {"yaw": 92, "pitch": -6},
                     "ra": {"raise": 90, "out": 90, "twist": -10, "elbow": 0, "wrist": 10},
                     "la": {"raise": 26, "out": 72, "elbow": 30},
                     "rf": {"yaw": 262}, "lf": {"x": 1.1, "z": -1.1, "y": .3, "toe": -10, "yaw": 250}})
    sh.key(14, hit, "impact")
    sh.key(17, merge(hit, {"root": {"yaw": 300, "roll": 10}, "torso": {"yaw": 14}, "head": {"yaw": 66},
                           "ra": {"raise": 86, "out": 104}, "rf": {"yaw": 300}, "lf": {"x": .5, "z": -1.7, "y": .2, "yaw": 296}}), "ease")
    T = -1.6
    sh.key(21, merge(st, {"travel": {"z": T * .7}, "root": {"y": -.66, "yaw": 344, "z": -.3, "roll": 4}, "torso": {"yaw": -6}, "head": {"yaw": 20},
                          "ra": {"raise": 70, "out": 30, "elbow": 70}, "la": {"raise": 50, "out": 20, "elbow": 70},
                          "rf": {"yaw": 344}, "lf": {"x": -.2, "z": -.76 + T, "y": .12, "toe": -6, "yaw": 344}}), "pass")
    fin = s({"travel": {"z": T}, "root": {"yaw": 390}, "rf": {"x": .1, "z": -.76, "yaw": 398}, "lf": {"x": -.1, "z": -.76 + T, "yaw": 354}})
    sh.key(25, merge(fin, {"root": {"y": -.7}}), "impact")
    sh.key(38, fin, "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1)
    return sh.build(markers={"contact": 14 / 60, "recover": 22 / 60})


# ------------------------------------------------------------- Heavy
def tuck(T, root, leg_r, leg_l, spin=0.0):
    """World feet for a body in the air: each ankle sits at `leg` (pelvis
    space, Roblox axes, from the hip) and turns with the pelvis."""
    Rp = nd_anim.ori(root)
    hrp = Vector((0, H, T))
    out = {}
    for key, s_, leg in (("rf", 1, leg_r), ("lf", -1, leg_l)):
        p = hrp + Vector((root.get("x", 0), root.get("y", 0), root.get("z", 0))) + Rp @ (Vector((.5 * s_, -.55, 0)) + Vector(leg))
        out[key] = {"x": round(p.x - .5 * s_, 3), "y": round(p.y - (H - 2.6), 3), "z": round(p.z, 3),
                    "toe": -root.get("pitch", 0) + spin, "yaw": 0, "knee": 0}
    return out


def heavy(arm):
    """Front somersault into an axe slash (the salto). Load: deep crouch,
    arms thrown back. Take-off: the legs extend and the arms swing up and
    over (they start the rotation). In the air the knees tuck to the chest (a
    small radius turns fast), the body turns one full circle forward, opens
    on the way down with the kunai raised over the head, and lands in a deep
    crouch as the arm chops straight down through the target. Then it rises
    back into the stance."""
    sh = Shot(arm, "Lion.Heavy")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -1.05, "z": .1, "pitch": 34, "yaw": 10}, "torso": {"pitch": 18, "yaw": -4}, "head": {"pitch": -32, "yaw": -6},
              "ra": {"raise": -54, "out": 22, "twist": 0, "elbow": 26}, "la": {"raise": -54, "out": 22, "twist": 0, "elbow": 26},
              "rf": {"toe": -8}})
    sh.key(5, load, "ease")
    off = s({"travel": {"z": -.3}, "root": {"y": .25, "z": -.35, "pitch": 6, "yaw": 0}, "torso": {"pitch": -8, "yaw": 0}, "head": {"pitch": -14, "yaw": 0},
             "ra": {"raise": 160, "out": 12, "elbow": 8}, "la": {"raise": 160, "out": 12, "elbow": 8},
             "rf": {"x": .2, "z": .6, "y": .55, "toe": -50}, "lf": {"x": -.1, "z": -.7, "y": .3, "toe": -40}})
    sh.key(8, off, "launch")
    TUCK = (0, -.55, -.35)
    def air(T, root, legs=(TUCK, TUCK), arms=None, torso=None, head=None):
        spec = {"travel": {"z": T}, "root": dict(root, tuck=1, roll=0)}
        spec.update(tuck(T, spec["root"], legs[0], legs[1]))
        spec["torso"] = torso or {"pitch": 24, "yaw": 0, "roll": 0}
        spec["head"] = head or {"pitch": 26, "yaw": 0}
        spec.update(arms or {})
        return merge(STANCE, spec)
    hug = {"ra": {"raise": 70, "out": -6, "twist": 0, "elbow": 96, "wrist": 0}, "la": {"raise": 70, "out": -6, "twist": 0, "elbow": 96}}
    sh.key(11, air(-.8, {"y": 1.3, "z": -.4, "pitch": 92, "yaw": 0}, legs=((0, -1.0, -.5), (0, -.8, -.6)), arms=hug), "pass")
    sh.key(13, air(-1.2, {"y": 1.9, "z": -.45, "pitch": 190, "yaw": 0}, arms=hug), "pass")
    sh.key(15, air(-1.5, {"y": 1.4, "z": -.5, "pitch": 280, "yaw": 0}, legs=((.05, -1.15, -.75), (-.05, -1.05, -.55)),
                   arms={"ra": {"raise": 168, "out": 4, "elbow": 30, "wrist": -30}, "la": {"raise": 120, "out": 20, "elbow": 40}},
                   torso={"pitch": 10, "yaw": 0, "roll": 0}, head={"pitch": 6, "yaw": 0}), "pass")
    T = -1.84
    # Opening: the legs reach for the floor, the feet already over the spots
    # they land on (a landing that is aimed, not a fall).
    f16 = air(-1.75, {"y": .6, "z": -.3, "pitch": 330, "yaw": 0}, legs=((.05, -1.55, -.45), (-.05, -1.3, -.85)),
              arms={"ra": {"raise": 178, "out": 0, "elbow": 12, "wrist": -34}, "la": {"raise": 130, "out": 30, "elbow": 30}},
              torso={"pitch": -6, "yaw": 0, "roll": 0}, head={"pitch": -8, "yaw": 0})
    sh.key(16, f16, "pass")
    # Touch-down: the feet take the floor with the legs still long, the
    # knees absorb over the next four frames while the blade comes down.
    sh.key(17, s({"travel": {"z": T}, "root": {"y": -.52, "z": -.45, "pitch": 12, "yaw": 4, "tuck": 0, "roll": 0},
                  "torso": {"pitch": 0, "yaw": -4, "roll": 0}, "head": {"pitch": -16, "yaw": -2},
                  "ra": {"raise": 172, "out": 2, "twist": -10, "elbow": 6, "wrist": -24},
                  "la": {"raise": 60, "out": 50, "twist": 0, "elbow": 20},
                  "rf": {"x": .26, "z": -1.3, "y": 0, "toe": -10, "yaw": 0, "knee": 0}, "lf": {"x": -.1, "z": -2.6, "y": 0, "toe": 0, "yaw": 0, "knee": 0}}), "pass")
    hit = s({"travel": {"z": T}, "root": {"y": -.74, "z": -.5, "pitch": 20, "yaw": 8, "tuck": 0, "roll": 0},
             "torso": {"pitch": 18, "yaw": -8, "roll": 0}, "head": {"pitch": -24, "yaw": -4},
             "ra": {"raise": 112, "out": 2, "twist": -20, "elbow": 0, "wrist": 10},
             "la": {"raise": -24, "out": 56, "twist": 0, "elbow": 20},
             "rf": {"x": .26, "z": -1.3, "y": 0, "toe": -20, "yaw": 6, "knee": 0}, "lf": {"x": -.1, "z": -2.6, "y": 0, "toe": 0, "yaw": -4, "knee": 0}})
    sh.key(18, hit, "impact")
    sh.key(21, merge(hit, {"root": {"y": -.92, "pitch": 30}, "ra": {"raise": 52, "wrist": 30}, "torso": {"pitch": 30}}), "ease")
    sh.key(24, merge(hit, {"root": {"y": -.9, "pitch": 28}, "ra": {"raise": 50, "wrist": 28}, "torso": {"pitch": 28}}), "ease")
    sh.key(31, merge(at(T), {"root": {"y": -.66, "pitch": 12}, "ra": {"raise": 62, "out": -8, "elbow": 96}, "rf": {"z": -1.15, "y": .12, "toe": -6, "yaw": 24}}), "pass")
    sh.key(40, merge(at(T), {"rf": {"z": -1.0}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.R"], 1).drag(["shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": 18 / 60, "recover": 28 / 60})


def author(arm):
    return [light1(arm), light2(arm), light3(arm), heavy(arm)]


# ------------------------------------------------------------- the kunai
# Forward grip: the handle in the fist, the blade out of the thumb side,
# 40 deg off the line of the arm. KUNAI_C0 is the weld in RightHand space
# (Roblox axes); the game uses the very same numbers (VelmoraMotionEngine,
# LION_KUNAI_C0).
KUNAI_POS = Vector((0, -.12, -.12))
KUNAI_DIR = Vector((0, -.77, -.64)).normalized()


def kunai_rot():
    look = KUNAI_DIR
    right = look.cross(Vector((0, 1, 0))).normalized()
    up = right.cross(look)
    m = Matrix.Identity(3)
    for i in range(3):
        m[i][0], m[i][1], m[i][2] = right[i], up[i], -look[i]
    return m


def add_kunai(arm, name="Sasuke"):
    """The game's kunai (Effects.buildKunai: blade toward -Z, handle +Z) as
    one mesh, welded to the right hand box exactly like the game's C0."""
    import bpy, bmesh
    from nd_rig import B, rb
    hand = bpy.data.objects[name + "_RightHand"]
    old = bpy.data.objects.get(name + "_Kunai")
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    bm = bmesh.new()

    def box(c, size):
        cx, cy, cz = c
        sx, sy, sz = size[0] / 2, size[1] / 2, size[2] / 2
        vs = [bm.verts.new(rb((cx + dx * sx, cy + dy * sy, cz + dz * sz))) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
        for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            bm.faces.new([vs[i] for i in f])
    box((0, 0, .1), (.13, .13, .62))      # wrapped handle
    box((0, 0, .55), (.26, .05, .26))     # ring
    box((0, 0, -.22), (.24, .07, .08))    # guard
    # leaf blade: a flat diamond prism
    pts = [(0, -.26), (.12, -.44), (0, -.98), (-.12, -.44)]
    top = [bm.verts.new(rb((x, .03, z))) for x, z in pts]
    bot = [bm.verts.new(rb((x, -.03, z))) for x, z in pts]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new([top[i], bot[i], bot[j], top[j]])
    me = bpy.data.meshes.new(name + "_Kunai")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name + "_Kunai", me)
    bpy.context.scene.collection.objects.link(ob)
    steel = bpy.data.materials.get("KunaiSteel") or bpy.data.materials.new("KunaiSteel")
    steel.diffuse_color = (.82, .84, .9, 1)
    me.materials.append(steel)
    ob.parent = hand
    ob.matrix_parent_inverse = Matrix.Identity(4)
    rot = (B @ kunai_rot() @ B.transposed()).to_4x4()
    ob.matrix_basis = Matrix.Translation(rb(KUNAI_POS)) @ rot
    return ob


def lua_c0():
    """KUNAI_C0 as a Luau CFrame literal (the same weld in the game)."""
    m = kunai_rot()
    p = KUNAI_POS
    vals = [p.x, p.y, p.z] + [m[i][j] for i in range(3) for j in range(3)]
    return "CFrame.new(%s)" % ",".join("%.4f" % v for v in vals)
