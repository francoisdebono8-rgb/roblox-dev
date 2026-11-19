"""One box GLB per body part of the fighter's skeleton, at its real size and rest centre.

SyphoDev's joint-space route renders the real parts through the exact Motor6D chain
(r6_clip.py). For a standard avatar he builds "box GLBs at the real part sizes at the
chain's rest centres" (roblox-animation SKILL.md, R15 vs R6). The Ninja Duel fighter IS
boxes (Server/World.rig), so these boxes are the body the game draws, not a stand-in.

    blender --background --python-exit-code 1 --python make_parts.py -- rig.json parts/

r6_clip.py reads Blender = Q * Roblox with Q:(X,Y,Z)->(-X,Z,Y) and asserts every part's
mesh bbox centre lands on its C0/C1 chain rest position, so this writes each box there.
"""
import bpy
import json
import os
import sys

from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
rig = json.load(open(args[0]))
out = os.path.abspath(args[1])
os.makedirs(out, exist_ok=True)


def cf(d):
    m = Matrix([list(r) for r in d["rows"]]).to_4x4()
    m.translation = Vector(d["pos"])
    return m


rest = {"HumanoidRootPart": Matrix.Translation(Vector(rig["hrp"]))}
pending = list(rig["joints"])
while pending:
    for j in list(pending):
        if j["part0"] in rest:
            rest[j["part1"]] = rest[j["part0"]] @ cf(j["c0"]) @ cf(j["c1"]).inverted()
            pending.remove(j)
            break
    else:
        raise SystemExit("joint chain does not connect to HumanoidRootPart")

Q = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))
for name, size in rig["sizes"].items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    c = rest[name].translation
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=Q @ Vector(c))
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0], size[2], size[1])  # Roblox X,Y,Z sizes -> Blender X, Z(depth)->Y, Y(up)->Z
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(out, name + ".glb"), export_format="GLB", use_selection=True)
    print(f"{name}: size {size} centre {[round(x, 3) for x in c]}")
print(f"wrote {len(rig['sizes'])} parts to {out}")
