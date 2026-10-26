# Defence, reactions and pursuit: author, export and film for Sasuke (Lion)
# and Minato (Flashstep).
import bpy, importlib, os, sys, math, json
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_io, nd_preview, clips_react, clips_sasuke, clips_minato
films = os.path.join(OUT, "films"); os.makedirs(films, exist_ok=True)
index = {}
for name, fighter, stance in (("Sasuke", "Lion", clips_sasuke.STANCE), ("Minato", "Flashstep", clips_minato.STANCE)):
    nd_rig.clear_scene()
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(name, fighter)
    acts = clips_react.author(arm, fighter, stance)
    data = nd_io.export(arm, acts, os.path.join(OUT, "clips_%s_react.json" % fighter))
    print(fighter, {k: v["frames"] for k, v in data.items()})
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "NinjaDuel_%s_React.blend" % name))
    cam = nd_preview.setup(300)
    for act in acts:
        dur = (act.frame_range[1] - act.frame_range[0]) / 60.0
        spin = None
        if act.name.endswith("Cartwheel"):
            spin = None
        paths = nd_preview.film(arm, act, os.path.join(OUT, "frames_react"), "front34", (0.0, 0.0), 2, None, cam, spin)
        fps = len(paths) / max(dur, .05)
        nd_preview.sheet_with_manifest(paths, os.path.join(films, act.name + ".png"), fps, 256, 8)
        index[act.name] = {"frames": len(paths), "fps": round(fps, 2)}
json.dump(index, open(os.path.join(films, "index_react.json"), "w"), indent=1)
print("done", len(index))
