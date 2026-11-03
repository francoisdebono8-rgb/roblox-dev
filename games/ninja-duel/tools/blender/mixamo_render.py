import bpy, sys, os, json
sys.path.insert(0, "/home/claude/roblox-dev/games/ninja-duel/tools/blender")
import nd_rig, nd_anim, nd_preview
from mathutils import Quaternion, Vector
from PIL import Image
OUT=sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
want=sys.argv[-2].split(",")
sheets=[]
for name in want:
    F=name.split(".")[0]
    data=json.load(open(os.path.join(os.path.dirname(OUT), "clips_%s_mocap.json"%F)))[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = nd_anim.FPS
    arm=nd_rig.build_rig(F, "Lion")
    act=nd_anim.new_action(arm, name)
    for i in range(data["frames"]):
        for j,rows in data["joints"].items():
            r=rows[i]; pb=arm.pose.bones[j]
            if j=="Root":
                pb.location=Vector(r[:3]); pb.keyframe_insert("location",frame=i*2); r=r[3:]
            pb.rotation_quaternion=Quaternion((r[3],r[0],r[1],r[2])); pb.keyframe_insert("rotation_quaternion",frame=i*2)
    act["nd_loop"]=data["loop"]
    cam=nd_preview.setup(220)
    every=max(2, (data["frames"]*2)//8)
    paths=nd_preview.film(arm, act, os.path.join(OUT,"frames"), "front34", every=every, cam=cam)[:8]
    ims=[Image.open(p) for p in paths]; w,h=ims[0].size
    row=Image.new("RGB",(w*len(ims),h),"white")
    for k,im in enumerate(ims): row.paste(im,(k*w,0))
    p=os.path.join(OUT,name+".png"); row.save(p); sheets.append(p); print("R",name,len(ims))
ims=[Image.open(p) for p in sheets]; W=max(i.width for i in ims); H=sum(i.height for i in ims)
o=Image.new("RGB",(W,H),"white"); y=0
for im in ims: o.paste(im,(0,y)); y+=im.height
o.save(os.path.join(OUT,"_board.png"))
