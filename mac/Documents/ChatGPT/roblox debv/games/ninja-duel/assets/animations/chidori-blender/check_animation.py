import bpy,math,json
from pathlib import Path
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out/'Chidori_R15.blend'))
s=bpy.context.scene;rig=bpy.data.objects['Sasuke_Chidori_R15'];fx=bpy.data.objects['CHIDORI • left palm']
assert len(rig.pose.bones)==16
max_hand_error=0;max_root_step=0;last=None;feet={}
for f in range(1,169):
 s.frame_set(f);bpy.context.view_layer.update()
 hand=rig.pose.bones['LeftHand'];expected=hand.head.lerp(hand.tail,.8)
 max_hand_error=max(max_hand_error,(fx.location-expected).length)
 root=rig.pose.bones['Root'].head.copy()
 if last is not None:max_root_step=max(max_root_step,(root-last).length)
 last=root
 if f in [75,81]:feet[f]={side:list(rig.pose.bones[side+'Foot'].head) for side in ['Left','Right']}
 for bone in rig.pose.bones:
  assert all(math.isfinite(v) for row in bone.matrix for v in row),(f,bone.name)
assert max_hand_error<.001,max_hand_error
assert max_root_step<.25,max_root_step
assert feet[75]['Left'][2]<feet[75]['Right'][2]
assert feet[81]['Right'][2]<feet[81]['Left'][2]
report={'frames':168,'fps':24,'duration_seconds':7,'body_bones':15,'root_bones':1,'max_effect_hand_error':max_hand_error,'max_root_step':max_root_step,'alternating_support':'PASS','finite_bone_matrices':'PASS','notes':'Original R15 study; not retargeted to the game avatar. Key rendered poses inspected.'}
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
