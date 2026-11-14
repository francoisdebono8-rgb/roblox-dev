"""(14/11, DEV: « les modèles du village sont construits sur l'ordinateur du
joueur au lancement : 7 à 12 s, et le village change de forme pendant ce
temps ») Konoha's models as ordinary Roblox meshes, like the outfits
(nd_look -> FBX -> Studio import -> looks_to_luau.py):

  1. python3 hub_fbx.py <out_dir>          one FBX per model of konoha_models
     (objects <Model>__<Piece>, each centred on its own centre, vertex colours
     kept) + imports/hub/Hub.manifest.json (model, piece, centre, size,
     material);
  2. Studio (the published ND place, signed in with upload rights): 3D Importer
     -> all the FBX of <out_dir> -> Insert; then run tools/blender/hub_studio_dump.luau
     in the command bar: it prints imports/hub/Hub.studio.json (name, mesh id,
     size) - save it there;
  3. python3 hub_to_luau.py                 writes src/Client/HubMeshAssets.luau.

Client/MeshKit then loads a piece listed there as a mesh asset
(AssetService:CreateMeshPartAsync on its id: streamed like any mesh, nothing
built on the player's computer) and builds the others as before."""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import bpy
from mathutils import Vector
import konoha_models
from nd_mesh import to_blender, to_roblox, outward


def piece_frame(pc):
    """The piece's centre and half extents in the Roblox frame (as piece_luau)."""
    vs = [to_roblox(v) for v in pc.v]
    lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return (lo + hi) / 2, (hi - lo) / 2


def export(out_dir, names=None):
    os.makedirs(out_dir, exist_ok=True)
    manifest = {}
    for name, fn in konoha_models.MODELS.items():
        if names and name not in names:
            continue
        for o in list(bpy.data.objects):
            bpy.data.objects.remove(o, do_unlink=True)
        for pc in konoha_models.blender(fn()):   # modelled in the Roblox frame (as write())
            outward(pc)
            ctr, half = piece_frame(pc)
            # back to Blender's frame (x, -z, y) for the move to the centre
            c_bl = Vector((ctr.x, -ctr.z, ctr.y))
            ob = to_blender(pc)
            for v in ob.data.vertices:
                v.co -= c_bl
            ob.name = "%s__%s" % (name, pc.name)
            ob.data.name = ob.name
            manifest[ob.name] = {"model": name, "piece": pc.name, "mat": pc.mat, "flat": bool(pc.flat),
                                 "o": [round(ctr.x, 4), round(ctr.y, 4), round(ctr.z, 4)],
                                 "size": [round(half.x * 2, 4), round(half.y * 2, 4), round(half.z * 2, 4)],
                                 "alpha": pc.alpha or 0, "reflect": pc.reflect or 0}
        bpy.ops.object.select_all(action="SELECT")
        path = os.path.join(out_dir, name + ".fbx")
        bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                                 axis_forward="-Z", axis_up="Y", mesh_smooth_type="OFF", use_mesh_modifiers=True,
                                 add_leaf_bones=False, colors_type="SRGB")
        print("exported", path, flush=True)
    imp = os.path.join(HERE, "imports", "hub")
    os.makedirs(imp, exist_ok=True)
    with open(os.path.join(imp, "Hub.manifest.json"), "w") as f:
        json.dump({"pieces": manifest}, f, indent=1, sort_keys=True)
    print(len(manifest), "pieces in", len({m["model"] for m in manifest.values()}), "models")


if __name__ == "__main__":
    export(sys.argv[1], sys.argv[2:] or None)
