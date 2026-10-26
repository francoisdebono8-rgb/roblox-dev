# Locomotion batch: author, export and film every locomotion clip of Sasuke
# (Lion) and Minato (Flashstep).
import bpy, importlib, os, sys, math, json
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
for m in ("nd_rig", "nd_anim", "nd_io", "nd_cycle", "nd_preview", "clips_loco", "clips_sasuke", "clips_minato"):
    if m in sys.modules: importlib.reload(sys.modules[m])
import nd_rig, nd_anim, nd_io, nd_preview, clips_loco, clips_sasuke, clips_minato
ONLY = os.environ.get("ND_ONLY", "")
SPEED = {"Walk": 7.0, "Run": 20.0, "Sprint": 45.0}
films = os.path.join(OUT, "films"); os.makedirs(films, exist_ok=True)
index = {}
for name, fighter, stance in (("Sasuke", "Lion", clips_sasuke.STANCE), ("Minato", "Flashstep", clips_minato.STANCE)):
    if ONLY and ONLY != fighter:
        continue
    nd_rig.clear_scene()
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(name, fighter)
    print("frames check", nd_rig.check_frames(arm))
    acts = clips_loco.author(arm, fighter, stance)
    data = nd_io.export(arm, acts, os.path.join(OUT, "clips_%s_loco.json" % fighter))
    print(fighter, {k: v["frames"] for k, v in data.items()})
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "NinjaDuel_%s_Loco.blend" % name))
    cam = nd_preview.setup(300)
    for act in acts:
        parts = act.name.split(".")
        meta = dict(act.get("nd_meta", {}))
        travel, rise, spin = (0.0, 0.0), None, None
        dur = (act.frame_range[1] - act.frame_range[0]) / 60.0
        if parts[1] in ("Walk", "Run", "Sprint"):
            S = meta.get("stride", 7)
            theta = {"F": 0, "R": 90, "B": 180, "L": -90}.get(parts[2] if len(parts) > 2 else "F", 0)
            travel = (S * math.sin(math.radians(theta)), S * math.cos(math.radians(theta)))
            dur = S / SPEED[parts[1]]
        elif parts[1] == "Jump":
            rise = lambda u: 4 * 5.0 * u * (1 - u)
            dur = .83
            if parts[2] == "Leap":
                travel = (0.0, 16.0)
        elif parts[1] == "Flip":
            spin = lambda u: -2 * math.pi * (u * u * (3 - 2 * u))
            rise = lambda u: 4 * 2.5 * u * (1 - u)
            dur = .5
        elif parts[1] == "Land":
            dur = .45
        paths = nd_preview.film(arm, act, os.path.join(OUT, "frames_loco"), "front34", travel, 2, rise, cam, spin)
        fps = len(paths) / max(dur, .05)
        nd_preview.sheet_with_manifest(paths, os.path.join(films, act.name + ".png"), fps, 256, 8)
        index[act.name] = {"frames": len(paths), "fps": round(fps, 2), "meta": meta}
json.dump(index, open(os.path.join(films, "index_%s.json" % (ONLY or "all")), "w"), indent=1)
print("done")
