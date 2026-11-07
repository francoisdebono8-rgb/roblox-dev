"""Native Blender authoring: original stylized R15 study, baked motion + Chidori.
Run with Blender --background --factory-startup --python this_file.py.
"""
import bpy, math, random, os, sys, json
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
OUT=Path(__file__).resolve().parent
random.seed(26)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=960; scene.render.resolution_y=640; scene.render.resolution_percentage=100
scene.render.fps=24; scene.frame_start=1; scene.frame_end=168
scene.render.image_settings.file_format='PNG'
scene.world.color=(.035,.045,.065)
scene.view_settings.view_transform='AgX'
try: scene.view_settings.look='AgX - Medium High Contrast'
except: pass
scene.render.film_transparent=False

def mat(name,color,metal=0,rough=.45,emission=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m
navy=mat('Indigo cotton',(.035,.065,.20)); blue=mat('Collar blue',(.07,.12,.32));white=mat('Warm ivory cloth',(.78,.81,.79));skin=mat('Skin',(.72,.47,.33));hair=mat('Blue black hair',(.009,.015,.035));shoe=mat('Sandals',(.022,.035,.07));steel=mat('Headband steel',(.39,.47,.52),.75,.28);eye=mat('Eye white',(.82,.86,.87));iris=mat('Graphite iris',(.015,.02,.034));stone=mat('Arena stone',(.12,.15,.19),.1,.7);rim=mat('Edge trim',(.22,.27,.32),.55,.4);cyan=mat('Chidori filaments',(.09,.65,1),.1,.3,9);core=mat('Chidori white core',(.7,.93,1),.1,.3,18);crackmat=mat('Discharge',(.23,.75,1),0,.3,8)
hair.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.8
hair.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.2
rigparts=[]
def cube(name,loc,scale,material,bevel=.035,bone=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Soft machined edges','BEVEL');mod.width=bevel;mod.segments=2
  o.modifiers.new('Weighted corners','WEIGHTED_NORMAL')
 o.data.materials.append(material)
 if bone: rigparts.append((o,bone))
 return o
bones={
 'Root':((0,0,0),(0,0,.3),None),
 'LowerTorso':((0,0,1.72),(0,0,2.12),'Root'),
 'UpperTorso':((0,0,2.12),(0,0,2.78),'LowerTorso'),
 'Head':((0,0,2.78),(0,0,3.44),'UpperTorso')}
for side,sign in [('Left',-1),('Right',1)]:
 bones[side+'UpperArm']=((sign*.63,0,2.65),(sign*.73,0,2.03),'UpperTorso')
 bones[side+'LowerArm']=((sign*.73,0,2.03),(sign*.77,0,1.48),side+'UpperArm')
 bones[side+'Hand']=((sign*.77,0,1.48),(sign*.77,0,1.23),side+'LowerArm')
 bones[side+'UpperLeg']=((sign*.28,0,1.72),(sign*.28,0,.91),'LowerTorso')
 bones[side+'LowerLeg']=((sign*.28,0,.91),(sign*.28,0,.16),side+'UpperLeg')
 bones[side+'Foot']=((sign*.28,0,.16),(sign*.28,-.36,.16),side+'LowerLeg')
arm=bpy.data.armatures.new('R15 study skeleton');rig=bpy.data.objects.new('Sasuke_Chidori_R15',arm);scene.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in bones.items():
 eb=arm.edit_bones.new(name);eb.head=a;eb.tail=b
 if parent:eb.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True

def segment(name,bone,width,depth,material,fraction=.9):
 a,b,_=bones[bone];a,b=Vector(a),Vector(b)
 o=cube(name,(a+b)*.5,(width,depth,(b-a).length*fraction),material,bone=bone)
 o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(b-a)
 return o
segment('LowerTorso','LowerTorso',.80,.48,navy)
segment('UpperTorso','UpperTorso',1.02,.54,navy)
# High open collar, faceted head, white exam shorts and wrapped shins.
cube('Collar back',(0,.13,2.80),(.79,.20,.30),blue,bone='UpperTorso')
for sign in [-1,1]:cube('Collar side',(.37*sign,-.03,2.80),(.15,.34,.29),blue,bone='UpperTorso')
cube('Head',(0,-.015,3.16),(.68,.57,.65),skin,.11,'Head')
for side,sign in [('Left',-1),('Right',1)]:
 segment(side+' upper arm skin',side+'UpperArm',.28,.29,skin,.94)
 segment(side+' thigh',side+'UpperLeg',.30,.32,skin,.94)
 segment(side+' sleeve',side+'UpperArm',.38,.40,navy,.68)
 segment(side+' forearm',side+'LowerArm',.27,.28,skin)
 segment(side+' hand',side+'Hand',.26,.26,skin)
 segment(side+' shorts',side+'UpperLeg',.43,.44,white,.72)
 segment(side+' shin',side+'LowerLeg',.30,.31,white,.88)
 cube(side+' sandal',(sign*.28,-.15,.15),(.34,.56,.23),shoe,.04,side+'Foot')
 cube(side+' toes',(sign*.28,-.39,.20),(.28,.10,.13),skin,.025,side+'Foot')
 for z in [.32,.45,.58,.71]:cube(side+' wrap seam',(sign*.28,-.163,z),(.29,.015,.022),rim,.003,side+'LowerLeg')
# Headband and readable, restrained face.
cube('Headband cloth',(0,-.284,3.34),(.70,.045,.15),shoe,.015,'Head')
cube('Headband plate',(0,-.314,3.34),(.40,.025,.12),steel,.02,'Head')
for sign in [-1,1]:
 cube('Eye',(.155*sign,-.305,3.17),(.19,.027,.07),eye,.015,'Head')
 cube('Iris',(.145*sign,-.322,3.165),(.061,.014,.067),iris,.012,'Head')
 brow=cube('Brow',(.15*sign,-.326,3.22),(.21,.015,.026),hair,.005,'Head');brow.rotation_euler.y=sign*.13
cube('Mouth',(0,-.31,3.02),(.13,.014,.017),hair,.003,'Head')
# A sculpted hair cap with individually authored spikes, not a sphere wig.
cube('Hair crown',(0,.035,3.47),(.73,.57,.26),hair,.1,'Head')
def spike(name,base,tip,radius,bone='Head'):
 base,tip=Vector(base),Vector(tip);axis=(tip-base).normalized();u=axis.cross(Vector((0,1,0)))
 if u.length<.01:u=axis.cross(Vector((1,0,0)))
 u.normalize();v=axis.cross(u)
 verts=[base+radius*(math.cos(i*math.pi/2)*u+math.sin(i*math.pi/2)*v) for i in range(4)]+[tip]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(0,1,2,3),(0,4,1),(1,4,2),(2,4,3),(3,4,0)]);mesh.update()
 o=bpy.data.objects.new(name,mesh);scene.collection.objects.link(o);o.data.materials.append(hair);rigparts.append((o,bone))
for i in range(9):
 a=i*math.tau/9
 spike('Hair spike %02d'%i,(.26*math.cos(a),.18+.18*math.sin(a),3.47),(.53*math.cos(a),.22+.45*math.sin(a),3.67+.10*math.cos(i*2)),.17)
for sign in [-1,1]:
 spike('Face framing lock',(.28*sign,-.20,3.47),(.35*sign,-.30,2.91),.15)
 spike('Front bang',(.12*sign,-.21,3.52),(.16*sign,-.36,3.27),.14)
# Rigid skinning to actual named bones; editable armature, no constraints to bake later.
for o,bone in rigparts:
 vg=o.vertex_groups.new(name=bone);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('R15 skin','ARMATURE');mod.object=rig
 o.parent=rig

# Stage: understated stone floor and one contact target.
cube('Arena platform',(0,-1,-.22),(17,21,.38),stone,.15)
for x in range(-8,9,2):cube('Floor seam X',(x,-1,-.025),(.015,20,.008),rim,.002)
for y in range(-10,10,2):cube('Floor seam Y',(0,y,-.025),(16,.015,.008),rim,.002)
for x in [-8,8]:cube('Platform rim',(x,-1,-.08),(.12,21,.18),rim,.025)
for y in [-11,9]:cube('Platform rim',(0,y,-.08),(16,.12,.18),rim,.025)
target=cube('Training stone',(-.46,-6.60,1.38),(.95,.70,2.70),mat('Training stone',(.22,.26,.29),.08,.8),.07)
cube('Target base',(-.46,-6.60,.10),(1.5,1.2,.2),rim,.04)

# Light, camera and bloom; electricity remains small enough to read the hand.
def light(name,typ,loc,energy,color,size=5):
 d=bpy.data.lights.new(name,typ);d.energy=energy;d.color=color
 if typ=='AREA':d.shape='DISK';d.size=size
 o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc
 if typ=='AREA':o.rotation_euler=(Vector((0,-1,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
 return o
light('Soft key','AREA',(-4,-5,8),1550,(.77,.86,1),7)
light('Warm rim','AREA',(4,3,7),2000,(1,.68,.41),6)
light('Front fill','AREA',(1,-8,4),650,(.45,.64,1),5)
handlight=light('Hand lightning bounce','POINT',(0,0,0),0,(.08,.48,1));handlight.data.shadow_soft_size=.5
camdata=bpy.data.cameras.new('Combat camera');cam=bpy.data.objects.new('Combat camera',camdata);scene.collection.objects.link(cam);scene.camera=cam;camdata.lens=47
tree=bpy.data.node_groups.new('Chidori compositing','CompositorNodeTree');scene.compositing_node_group=tree
tree.interface.new_socket(name='Image',in_out='OUTPUT',socket_type='NodeSocketColor')
rl=tree.nodes.new('CompositorNodeRLayers');gl=tree.nodes.new('CompositorNodeGlare')
gl.inputs['Type'].default_value='Fog Glow';gl.inputs['Quality'].default_value='High';gl.inputs['Threshold'].default_value=1.5;gl.inputs['Size'].default_value=.35;gl.inputs['Strength'].default_value=.65
out=tree.nodes.new('NodeGroupOutput');tree.links.new(rl.outputs['Image'],gl.inputs['Image']);tree.links.new(gl.outputs['Image'],out.inputs['Image'])
# Arc geometry is animated on the same hand transform as the body.
fx=bpy.data.objects.new('CHIDORI • left palm',None);scene.collection.objects.link(fx)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.12);orb=bpy.context.object;orb.name='Chidori core';orb.data.materials.append(core);orb.parent=fx
arcs=[]
for j in range(11):
 cu=bpy.data.curves.new('Electrical arc %02d'%j,'CURVE');cu.dimensions='3D';cu.bevel_depth=.009 if j<7 else .005;cu.bevel_resolution=1
 sp=cu.splines.new('POLY');sp.points.add(6)
 angle=j*math.tau/11
 direction=Vector((math.cos(angle),.35*math.sin(j*2.1),math.sin(angle))).normalized()
 for i,p in enumerate(sp.points):
  frac=i/6;pos=direction*(.10+frac*(.40+.09*math.sin(j)))+Vector((random.uniform(-.08,.08),random.uniform(-.08,.08),random.uniform(-.08,.08)))*(frac if i else 0)
  p.co=(*pos,1)
 o=bpy.data.objects.new('Chidori arc %02d'%j,cu);scene.collection.objects.link(o);o.parent=fx;cu.materials.append(cyan if j%3 else core);arcs.append(o)
# Floor discharge and stone chips occur only on physical contact.
chips=[]
for i in range(9):
 o=cube('Contact chip %02d'%i,(-.46,-6.18,2.05),(.05+.015*i,.05,.07),target.data.materials[0],.008);chips.append(o)

def smooth(t):t=max(0,min(1,t));return t*t*(3-2*t)
def mix(a,b,t):return a+(b-a)*t
def track(f,keys):
 for i in range(len(keys)-1):
  a,v=keys[i];b,w=keys[i+1]
  if f<=b:return mix(v,w,smooth((f-a)/(b-a)))
 return keys[-1][1]
def origin_y(f):
 if f<60:return track(f,[(1,3),(52,3),(60,2.8)])
 if f<=108:return 2.8-(f-60)*5.6/48
 return track(f,[(108,-2.8),(119,-4.32),(128,-4.48),(153,-4.90),(168,-4.90)])
def solve(a,b,l1,l2,pole):
 d=b-a;length=max(.001,min(d.length,l1+l2-.002));direction=d.normalized();end=a+direction*length
 p=Vector(pole);perp=p-direction*p.dot(direction)
 if perp.length<.001:perp=Vector((1,0,0))
 perp.normalize();along=(l1*l1-l2*l2+length*length)/(2*length);height=math.sqrt(max(0,l1*l1-along*along))
 return a+direction*along+perp*height,end
rest={n:(Vector(a),Vector(b),rig.data.bones[n].matrix_local.to_quaternion()) for n,(a,b,_) in bones.items()}
def pose_bone(n,a,b):
 ra,rb,rq=rest[n];delta=Vector(b)-Vector(a);q=(rb-ra).rotation_difference(delta)@rq
 pb=rig.pose.bones[n];pb.rotation_mode='QUATERNION';pb.matrix=Matrix.Translation(Vector(a))@q.to_matrix().to_4x4()@Matrix.Diagonal((1,delta.length/(rb-ra).length,1,1))
 bpy.context.view_layer.update()
 for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(data_path=prop)

def run_foot(f,sign):
 # Contact phase holds its world position while the pelvis passes over it.
 offset=0 if sign<0 else 6
 q=(f-60+offset)/12;cycle=math.floor(q);phase=q-cycle;contact=60+cycle*12-offset
 stance=.58
 start=origin_y(contact)-.38
 if phase<stance:return Vector((sign*.34,start,.16))
 t=(phase-stance)/(1-stance);dest=origin_y(contact+12)-.38
 return Vector((sign*(.34+.10*math.sin(math.pi*t)),mix(start,dest,smooth(t)),.16+.46*math.sin(math.pi*t)))
for f in range(1,169):
 scene.frame_set(f);y=origin_y(f)
 seal=smooth((f-5)/10)*(1-smooth((f-25)/12))
 charge=smooth((f-14)/24)*(1-smooth((f-52)/10))
 run=smooth((f-55)/9)*(1-smooth((f-106)/10))
 strike=smooth((f-107)/12)*(1-smooth((f-126)/25))
 hips=track(f,[(1,1.72),(28,1.49),(52,1.44),(62,1.43),(108,1.43),(119,1.26),(128,1.30),(153,1.66),(168,1.70)])
 hips+=run*.045*math.cos((f-60)*math.tau/6)
 pelvis=Vector((.045*run*math.sin((f-60)*math.tau/12),y,hips))
 lean=math.radians(8+10*charge+29*run+30*strike);yaw=math.radians(12*strike+run*4*math.sin((f-60)*math.tau/12))
 rot=Matrix.Rotation(yaw,3,'Z')@Matrix.Rotation(lean,3,'X');waist=pelvis+rot@Vector((0,0,.40));neck=waist+rot@Vector((0,0,.66));headend=neck+Vector((0,-.04,.66))
 pose_bone('Root',(0,y,0),(0,y,.3));pose_bone('LowerTorso',pelvis,waist);pose_bone('UpperTorso',waist,neck);pose_bone('Head',neck,headend)
 for side,sign in [('Left',-1),('Right',1)]:
  hip=pelvis+Vector((sign*.28,0,0))
  restfoot=Vector((sign*mix(.32,.48,charge),y+sign*.17*charge,.16))
  if 60<=f<=108:
   foot=run_foot(f,sign);entry=smooth((f-60)/5);foot=restfoot.lerp(foot,entry)
  elif f>108:
   begin=run_foot(108,sign);lunge=Vector((sign*.43,-4.32+(-.72 if sign<0 else .78),.16))
   finish=Vector((sign*.36,-4.9+(-.20 if sign<0 else .20),.16))
   foot=begin.lerp(lunge,smooth((f-108)/11)) if f<125 else lunge.lerp(finish,smooth((f-125-(0 if sign>0 else 9))/23))
   if f>=125:foot.z+=.20*math.sin(math.pi*smooth((f-125-(0 if sign>0 else 9))/23))
  else:foot=restfoot
  knee,ankle=solve(hip,foot,.81,.75,(sign*.10,-1,.08))
  pose_bone(side+'UpperLeg',hip,knee);pose_bone(side+'LowerLeg',knee,ankle);pose_bone(side+'Foot',ankle,ankle+Vector((0,-.36,0)))
  shoulder=waist+rot@Vector((sign*.63,0,.53))
  neutral=Vector((sign*.78,y-.13,hips+.03))
  charged=Vector((-.46,y-.46,hips+.40)) if sign<0 else Vector((-.22,y-.40,hips+.50))
  running=Vector((-.66,y+.43,hips+.12)) if sign<0 else Vector((.80,y+.33,hips+.27+.13*math.sin(f*math.tau/12)))
  hit=Vector((-.46,y-1.65,2.05)) if sign<0 else Vector((.78,y+.54,hips+.36))
  hand=neutral.lerp(charged,charge).lerp(running,run).lerp(hit,strike)
  hand=hand.lerp(Vector((sign*.14,y-.65,hips+.73)),seal)
  elbow,wrist=solve(shoulder,hand,(Vector(bones[side+'UpperArm'][1])-Vector(bones[side+'UpperArm'][0])).length,(Vector(bones[side+'LowerArm'][1])-Vector(bones[side+'LowerArm'][0])).length,(sign*.7,.8,-.15))
  finger=Vector((0,-1,-.05)).normalized() if sign<0 else Vector((0,-.3,-1)).normalized()
  if seal>.5:finger=Vector((0,0,1))
  if run>.5:finger=Vector((0,.5,-.5)).normalized()
  end=wrist+finger*.25
  pose_bone(side+'UpperArm',shoulder,elbow);pose_bone(side+'LowerArm',elbow,wrist);pose_bone(side+'Hand',wrist,end)
  if sign<0:palm=wrist+finger*.20
 strength=track(f,[(1,0),(19,0),(28,.35),(45,.9),(61,1),(108,1),(118,1.3),(122,1.1),(133,.1),(139,0),(168,0)])
 flicker=1+.10*math.sin(f*2.9)+.07*math.sin(f*7.1)
 fx.location=palm;fx.scale=(strength*flicker,)*3;fx.rotation_euler=(f*.63,f*.23,f*.39)
 for prop in ['location','scale','rotation_euler']:fx.keyframe_insert(data_path=prop)
 for j,o in enumerate(arcs):
  o.scale=(1+.15*math.sin(f*1.7+j),)*3;o.rotation_euler.y=.25*math.sin(f*2.2+j);o.keyframe_insert(data_path='scale');o.keyframe_insert(data_path='rotation_euler')
 handlight.location=palm;handlight.keyframe_insert(data_path='location');handlight.data.energy=150*strength*flicker;handlight.data.keyframe_insert(data_path='energy')
 for i,o in enumerate(chips):
  t=max(0,(f-119)/24);active=119<=f<=146
  o.scale=(1 if active else 0,)*3;o.location=Vector((-.46,-6.18,2.05))+Vector((math.cos(i*2.4)*(1+i*.09)*t,(.8+i*.08)*t,1.3*t-3.5*t*t));o.rotation_euler=(t*i,t*(i+2),t);o.keyframe_insert(data_path='location');o.keyframe_insert(data_path='scale');o.keyframe_insert(data_path='rotation_euler')
 look=Vector((-.05,y-.45,1.7));cam.location=Vector((-8.6,y-4.2,4.6));cam.rotation_euler=(look-cam.location).to_track_quat('-Z','Y').to_euler();cam.keyframe_insert(data_path='location');cam.keyframe_insert(data_path='rotation_euler')
# Named beats for hand editing.
for name,f in [('01 • stance',1),('02 • gather / left palm',20),('03 • charge',40),('04 • push off',58),('05 • alternating sprint',72),('06 • plant / thrust',109),('07 • contact',119),('08 • absorb / recovery',130),('09 • ready',157)]:scene.timeline_markers.new(name,frame=f)
if rig.animation_data and rig.animation_data.action:rig.animation_data.action.name='CHIDORI__charge_run_thrust_recover__24fps'
# Baked samples interpolate linearly (no spline overshoot between authored frames).
for action in bpy.data.actions:
 try:
  for layer in action.layers:
   for strip in layer.strips:
    for bag in strip.channelbags:
     for fc in bag.fcurves:
      for key in fc.keyframe_points:key.interpolation='LINEAR'
 except AttributeError:pass
scene.frame_set(42)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
scene['AnimationNotes']='Original stylized R15 study. Left-hand Chidori. 24fps, 168 frames. Not a retargeted/exported Ninja Duel avatar. Root motion and 15 body bones baked. FX separate.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Chidori_R15.blend'))
for o,bone in rigparts:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Chidori_R15.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,axis_forward='-Z',axis_up='Y')
(OUT/'frames').mkdir(exist_ok=True)
for f in [1,20,42,75,81,100,119,150]:
 scene.frame_set(f);scene.render.filepath=str(OUT/'frames'/('pose_%03d.png'%f));bpy.ops.render.render(write_still=True)
print('CHIDORI_READY',str(OUT/'Chidori_R15.blend'))
