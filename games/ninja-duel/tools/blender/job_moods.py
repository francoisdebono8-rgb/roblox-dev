"""(14/11, DEV -> ANIMATEUR, DEC-041) The inspirations' moods at the gate of
Konoha: three loops played by Client/HubMoods on the masters' models
(Mood.<kit>, in place of its code poses). Read from 15-20 studs, at a glance:
the silhouette carries the mood, the details only colour it.

  Mood.Legion - Naruto shows off and can't keep still: hands behind his head,
    bouncing on his heels, swaying; every loop he steps out, jabs his thumb at
    his own chest (« the next Hokage, that's me »), and puts his hands back.
    (ep. 1-3: hands behind the head is his signature idle; the thumb to the
    chest his boast)
  Mood.Lion - Sasuke sulks apart: leaning back (on a wall or a post), arms
    crossed tight, one foot crossed over the other, head turned away; a glance
    at the newcomer, held a beat, then the chin goes up and away (« hmph »).
    (ep. 4-6, the Chunin exam waiting room)
  Mood.Leaf - Lee trains flat out: a one-two and a high kick, down into two
    push-ups, back up and the fist punched at the sky (« YOSH! »). (ep. 34-36,
    50: training to the limit, the fist raised)

Absolute poses (Motor6D.Transform from rest), not over a fighting stance:
they stand. Loops: the last key equals the first.
Run: python3 job_moods.py <out.json> [render_dir]"""
import bpy, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_ctrl, nd_shot
from nd_shot import Shot, merge

# A relaxed standing body (from the Win poses: Lion.Win "up", Leaf.Win "good")
STAND = {"root": {"x": 0, "y": -.08, "z": 0, "pitch": 0, "yaw": 0, "roll": 0}, "torso": {"pitch": -2, "yaw": 0, "roll": 0},
         "head": {"pitch": -4, "yaw": 0},
         "ra": {"raise": 6, "out": 12, "twist": -10, "elbow": 20, "wrist": 0},
         "la": {"raise": 6, "out": 12, "twist": -10, "elbow": 20, "wrist": 0},
         "rf": {"x": .12, "z": 0, "y": 0, "yaw": 8, "toe": 0, "knee": 0}, "lf": {"x": -.12, "z": 0, "y": 0, "yaw": -8, "toe": 0, "knee": 0}}


def s(over=None):
    return merge(STAND, over or {})


def naruto(arm):
    """Hands behind the head (elbows wide, out to the sides), bouncing on the
    heels; the swagger of the hips; then the boast: one step out, thumb to the
    chest, chin up, the grin to the side; back."""
    # (found by placing the hands: just above the neck and 0.45 behind it, the
    # elbows 1.4 out to the sides)
    behind = {"ra": {"raise": 0, "out": 160, "twist": -90, "elbow": 120, "wrist": 10},
              "la": {"raise": 0, "out": 160, "twist": -90, "elbow": 120, "wrist": 10}}
    up = s(merge(behind, {"root": {"y": -.02, "pitch": -4, "roll": 3}, "torso": {"pitch": -8, "yaw": 6, "roll": -3},
                          "head": {"pitch": -10, "yaw": 10}, "rf": {"toe": 18}, "lf": {"toe": 18}}))
    down = s(merge(behind, {"root": {"y": -.18, "pitch": -2, "roll": -3}, "torso": {"pitch": -6, "yaw": -6, "roll": 3},
                            "head": {"pitch": -6, "yaw": -8}}))
    sh = Shot(arm, "Mood.Legion")
    sh.key(0, down, "ease")
    for k, f in enumerate((10, 20, 30, 40, 50, 60, 70)):
        sh.key(f, up if k % 2 == 0 else down, "ease")
    # the boast: a step forward on the right foot, the right thumb to his chest
    boast = s({"root": {"y": -.14, "z": -.1, "pitch": -8, "yaw": -14}, "torso": {"pitch": -12, "yaw": -10},
               "head": {"pitch": -18, "yaw": 16},
               "ra": {"raise": 44, "out": -30, "twist": -40, "elbow": 132, "wrist": -20},
               "la": {"raise": -8, "out": 26, "twist": -30, "elbow": 74, "wrist": 0},      # the other hand on the hip
               "rf": {"x": .2, "z": -.42, "yaw": 0}, "lf": {"x": -.16, "z": .16, "yaw": -14}})
    sh.key(84, merge(boast, {"rf": {"y": .18}}), "pass")
    sh.key(92, boast, "impact")
    sh.key(98, merge(boast, {"torso": {"pitch": -16}, "head": {"pitch": -22, "yaw": 20}}), "ease")
    sh.key(130, merge(boast, {"torso": {"pitch": -14}, "head": {"pitch": -20, "yaw": 22}}), "ease")
    sh.key(142, merge(down, {"rf": {"z": -.2, "y": .14}}), "pass")
    sh.key(152, down, "ease")
    sh.key(162, up, "ease")
    sh.key(172, down, "ease")
    sh.drag(["neck"], 3).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(loop=True, meta={"mood": 1})


def sasuke(arm):
    """Leaning back, arms crossed tight, the weight on the left leg, the right
    foot crossed over in front; head away. The glance: the head turns to the
    front, the eyes low (pitch down), held; then the chin up and away."""
    # forearms level across the ribs, the hands tucked under the upper arms (the
    # fold measured for Gaara, job_gaara_film10), the right arm over
    cross_r = {"raise": 24, "out": -10, "twist": 96, "elbow": 96, "wrist": 0}
    cross_l = {"raise": 18, "out": -6, "twist": 100, "elbow": 90, "wrist": 0}
    lean = s({"root": {"y": -.12, "z": .18, "pitch": -8, "yaw": 0, "roll": -4}, "torso": {"pitch": -6, "yaw": 4, "roll": 2},
              "head": {"pitch": 6, "yaw": -50},
              "ra": cross_r, "la": cross_l,
              "lf": {"x": -.16, "z": -.12, "yaw": -14},
              "rf": {"x": -.14, "z": -.34, "yaw": 22, "toe": 34}})       # crossed over, resting on the toes
    breathe = merge(lean, {"root": {"y": -.1}, "torso": {"pitch": -8}})
    glance = merge(lean, {"head": {"pitch": 12, "yaw": -6}, "torso": {"yaw": 0}})
    away = merge(lean, {"head": {"pitch": -10, "yaw": -62}, "root": {"roll": -5}})
    sh = Shot(arm, "Mood.Lion")
    sh.key(0, lean, "ease")
    sh.key(60, breathe, "ease")
    sh.key(120, lean, "ease")
    sh.key(150, breathe, "ease")
    sh.key(170, glance, "ease")          # he looks...
    sh.key(225, merge(glance, {"head": {"pitch": 14}}), "ease")   # ...held a beat
    sh.key(236, away, "impact")          # « hmph »: the chin up and away, quick
    sh.key(290, merge(away, {"head": {"pitch": -6, "yaw": -56}}), "ease")
    sh.key(340, lean, "ease")
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"mood": 1})


def lee(arm):
    """Training flat out: a one-two from his guard and a high kick, down into
    two push-ups, springing back up, the fist punched at the sky (« YOSH! »),
    back to the guard."""
    guard = s({"root": {"y": -.42, "pitch": 6, "yaw": 30}, "torso": {"pitch": 4, "yaw": -16}, "head": {"pitch": -6, "yaw": -14},
               "ra": {"raise": 44, "out": 10, "twist": 20, "elbow": 112}, "la": {"raise": 58, "out": 6, "twist": 14, "elbow": 92},
               "rf": {"x": .26, "z": .6, "yaw": 32}, "lf": {"x": -.12, "z": -.56, "yaw": -4}})
    jab = merge(guard, {"root": {"yaw": 22, "z": -.08}, "torso": {"yaw": -26}, "la": {"raise": 88, "out": 2, "elbow": 6}})
    cross = merge(guard, {"root": {"yaw": -14, "z": -.12, "pitch": 10}, "torso": {"yaw": 10},
                          "ra": {"raise": 90, "out": -6, "twist": 0, "elbow": 6}, "la": {"raise": 52, "elbow": 110},
                          "rf": {"toe": 30}})
    kick = merge(guard, {"root": {"y": -.2, "pitch": -12, "yaw": 50}, "torso": {"pitch": -10, "yaw": -30},
                         "ra": {"raise": 30, "out": 40, "elbow": 60}, "la": {"raise": 40, "out": 30, "elbow": 80},
                         "rf": {"x": .3, "z": -1.3, "y": 2.0, "yaw": 80, "toe": -20, "knee": 0}})
    # push-ups: the body straight and level, on the hands and the toes
    plank_up = {"root": {"x": 0, "y": -1.86, "z": .2, "pitch": 74, "yaw": 0, "roll": 0}, "torso": {"pitch": 6, "yaw": 0, "roll": 0},
                "head": {"pitch": -40, "yaw": 0},
                "ra": {"raise": 82, "out": 18, "twist": 0, "elbow": 6, "wrist": 0}, "la": {"raise": 82, "out": 18, "twist": 0, "elbow": 6, "wrist": 0},
                "rf": {"x": .1, "z": 2.0, "y": 0, "yaw": 0, "toe": -60, "knee": 0}, "lf": {"x": -.1, "z": 2.0, "y": 0, "yaw": 0, "toe": -60, "knee": 0}}
    plank_down = merge(plank_up, {"root": {"y": -2.28, "pitch": 80}, "head": {"pitch": -46},
                                  "ra": {"raise": 40, "out": 56, "elbow": 96}, "la": {"raise": 40, "out": 56, "elbow": 96}})
    yosh = s({"root": {"y": -.3, "pitch": -4, "yaw": 6}, "torso": {"pitch": -14, "yaw": 0}, "head": {"pitch": -24, "yaw": 0},
              "ra": {"raise": 168, "out": 8, "twist": 0, "elbow": 8}, "la": {"raise": 10, "out": 30, "twist": -30, "elbow": 110},
              "rf": {"x": .3, "z": .12, "yaw": 14}, "lf": {"x": -.3, "z": -.12, "yaw": -14}})
    sh = Shot(arm, "Mood.Leaf")
    f = 0
    sh.key(f, guard, "ease")
    for _ in range(2):                    # the one-two, twice
        sh.key(f + 5, jab, "impact"); sh.key(f + 10, guard, "ease")
        sh.key(f + 15, cross, "impact"); sh.key(f + 22, guard, "ease")
        f += 22
    sh.key(f + 8, merge(guard, {"root": {"y": -.5, "pitch": 4}, "rf": {"y": .5, "z": .1, "knee": 40}}), "pass")
    sh.key(f + 14, kick, "impact"); sh.key(f + 24, merge(kick, {"rf": {"y": 1.9}}), "ease")
    sh.key(f + 34, guard, "ease")
    f += 34
    # down: crouch, hands to the floor, feet thrown back
    crouch = {"root": {"y": -1.5, "z": -.1, "pitch": 40, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
              "ra": {"raise": 60, "out": 18, "elbow": 20}, "la": {"raise": 60, "out": 18, "elbow": 20},
              "rf": {"x": .2, "z": .2, "yaw": 0, "toe": 0}, "lf": {"x": -.2, "z": .2, "yaw": 0, "toe": 0}}
    sh.key(f + 10, s(crouch), "ease")
    sh.key(f + 18, s(plank_up), "impact")
    f += 18
    for _ in range(2):
        sh.key(f + 12, s(plank_down), "ease")
        sh.key(f + 22, s(plank_up), "ease")
        f += 22
    sh.key(f + 8, s(crouch), "ease")
    sh.key(f + 18, merge(yosh, {"root": {"y": -.5}, "ra": {"raise": 90, "elbow": 120}}), "pass")
    sh.key(f + 24, yosh, "impact")
    sh.key(f + 64, merge(yosh, {"ra": {"raise": 164}, "head": {"pitch": -22}}), "ease")
    sh.key(f + 80, guard, "ease")
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"mood": 1})


MOODS = (("Naruto", "Legion", naruto), ("Sasuke", "Lion", sasuke), ("Lee", "Leaf", lee))


def contact_sheet(arm, act, out_dir, frames, tag):
    from mathutils import Vector
    import nd_anim
    S = bpy.context.scene
    nd_anim.use(arm, act)
    paths = []
    for f in frames:
        S.frame_set(f)
        for view, loc in (("front", Vector((-3.0, 15, 4))), ("side", Vector((15, 1.5, 4)))):
            c = bpy.data.objects["PreviewCam"]
            c.location = loc
            tgt = Vector((0, 0, 1.8))
            c.rotation_euler = (tgt - c.location).to_track_quat("-Z", "Y").to_euler()
            p = os.path.join(out_dir, "%s_%03d_%s.png" % (tag, f, view))
            S.render.filepath = p
            bpy.ops.render.render(write_still=True)
            paths.append(p)
    return paths


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[1]
    rdir = (sys.argv[sys.argv.index("--") + 2] if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 2
            else (sys.argv[2] if len(sys.argv) > 2 and "--" not in sys.argv else None))
    S = bpy.context.scene
    data = {}
    for name, fighter, fn in MOODS:
        nd_rig.clear_scene(); S.render.fps = 60
        arm = nd_ctrl.build(name, fighter)
        act = fn(arm)
        data.update(nd_shot.export(arm, [act], out + "." + fighter + ".json"))
        if rdir:
            nd_shot.stage(300)
            S.render.resolution_x, S.render.resolution_y = 260, 330
            last = int(act.frame_range[1])
            contact_sheet(arm, act, rdir, list(range(0, last + 1, max(1, last // 9))), fighter)
        print("OK", act.name, act.frame_range[:], flush=True)
    json.dump(data, open(out, "w"))
    print("exported", sorted(data))
