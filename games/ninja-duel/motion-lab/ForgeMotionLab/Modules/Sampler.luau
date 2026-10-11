local M=require(script.Parent.Model)
local Solver=require(script.Parent.PoseSolver)
local S={}
S.Joints={Root={"Root"},Legs={"RightHip","RightKnee","RightAnkle","LeftHip","LeftKnee","LeftAnkle"},Hips={"Root"},Torso={"Waist"},LeftArm={"Left","LeftElbow","LeftWrist"},RightArm={"Right","RightElbow","RightWrist"},Head={"Neck"},Weapon={"Weapon"}}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function mix(a,b,t)
 local out={};for k,v in a or {} do out[k]=M.copy(v) end
 for k,v in b or {} do if type(v)=="table" then out[k]=mix((a or {})[k] or {},v,t) elseif type(v)=="number" then out[k]=((a or {})[k] or 0)+(v-((a or {})[k] or 0))*t end end
 for k,v in a or {} do if (b or {})[k]==nil and type(v)=="number" then out[k]=v*(1-t) end end
 return out
end
local function merge(a,b) local out=M.copy(a);for k,v in b do out[k]=if type(v)=="table" then merge(out[k] or {},v) else v end;return out end
local function keysAt(keys,t)
 if t<=keys[1].at then return M.copy(keys[1].pose) end
 for i=1,#keys-1 do local a,b=keys[i],keys[i+1]
  if t<=b.at then local u=math.clamp((t-a.at)/math.max(.0001,b.at-a.at),0,1);u=if b.ease=="linear" then u elseif b.ease=="out" then 1-(1-u)^3 elseif b.ease=="in" then u^3 else smooth(u)
   local pose=mix(a.pose,b.pose,u)
   -- A kicking leg uses FK throughout that interval, rather than competing IK.
   if a.pose.rl or b.pose.rl then pose.rf=nil end;if a.pose.ll or b.pose.ll then pose.lf=nil end
   return pose
  end
 end
 return M.copy(keys[#keys].pose)
end
local base={root={y=-.3,pitch=5},torso={pitch=3},head={pitch=-3},ra={raise=45,out=10,elbow=90},la={raise=50,out=10,elbow=80},rf={x=.1,z=.4},lf={x=-.1,z=-.4}}
local function procedural(p,asset,t)
 local stance=merge(base,p.stance);local kind=asset.grammar;local cycle=t*math.pi*2*p.motionDNA.cadence*p.motionDNA.strideFrequency
 local pulse=math.sin(math.pi*t)^2;local strike=math.sin(math.pi*math.clamp(t/.7,0,1))^2
 if asset.category=="Locomotion" then
  if kind=="Idle" then return merge(stance,{root={y=(stance.root.y or 0)+math.sin(cycle)*.03},torso={pitch=(stance.torso.pitch or 0)+math.sin(cycle)*1.4}}) end
  local scale=if kind=="Sprint" then 1.4 elseif kind=="Walk" then .6 else 1
  local gait=p.gait;local stride=math.sin(cycle)*(gait.stride or 1)*p.motionDNA.stepLength*.75*scale
  local liftR=math.max(0,math.cos(cycle))*.35;local liftL=math.max(0,-math.cos(cycle))*.35
  return merge(stance,{root={pitch=(if kind=="Sprint" then 28 else 12),y=-.32+math.cos(cycle*2)*.08,roll=if kind=="Strafe" then 12 else 0},torso={yaw=math.sin(cycle)*-10},rf={z=stride,y=liftR},lf={z=-stride,y=liftL},ra={raise=15+math.sin(cycle)*(gait.arm or 35)},la={raise=15-math.sin(cycle)*(gait.arm or 35)}})
 end
 if asset.category=="Reactions" then return merge(stance,{root={y=-.3-pulse*.25,pitch=-pulse*20,roll=pulse*8},torso={pitch=-pulse*20,yaw=pulse*22},head={pitch=pulse*18},ra={raise=40+pulse*30},la={raise=45+pulse*20}}) end
 if asset.category=="Dodges" then return merge(stance,{root={x=-pulse*.65,y=-.3-pulse*.4,pitch=pulse*24,roll=-pulse*18},torso={roll=pulse*8},rf={x=.1+pulse*.5},lf={x=-.1-pulse*.4}}) end
 if asset.category=="Aerial" or asset.category=="Wall" then
  return merge(stance,{root={y=-.15+math.sin(math.pi*t)*.5,pitch=if kind=="Slam" then pulse*45 else -pulse*12,roll=if asset.category=="Wall" then pulse*30 else 0},ra={raise=40+pulse*60},la={raise=40+pulse*65},rl={lift=35+pulse*40,knee=70},ll={lift=20+pulse*20,knee=95}})
 end
 if asset.category=="Kicks" then
  local spin=if kind=="Light3" then pulse*150 elseif kind=="Sweep" then pulse*80 else pulse*25
  return merge(stance,{root={y=-.3-pulse*(if kind=="Sweep" then .55 else .12),yaw=spin,roll=pulse*-15},torso={yaw=pulse*20},rl={lift=strike*90,out=if kind=="SideKick" then strike*65 else strike*25,knee=100*(1-strike)+8},ra={raise=35,out=30+strike*35},la={raise=45,out=30+strike*35}})
 end
 if asset.category=="Knees" then return merge(stance,{root={pitch=pulse*16,z=-pulse*.4},rl={lift=strike*105,knee=120},ra={raise=75,elbow=115},la={raise=80,elbow=110}}) end
 if asset.category=="Launchers" then return merge(stance,{root={y=-.35-pulse*.3,z=-pulse*.4},torso={pitch=-strike*12},ra={raise=20+strike*140,out=15,elbow=100-strike*65}}) end
 local left=kind=="Light2" or kind=="PalmThrust";local arm=if left then "la" else "ra";local hand={raise=30+strike*65,out=if asset.category=="Elbows" then -strike*45 else -strike*15,elbow=if asset.category=="Elbows" then 110 else 110-strike*100,wrist=if kind=="PalmThrust" then -35 else 0}
 return merge(stance,{root={z=-pulse*.45,pitch=pulse*8,yaw=(if left then 1 else -1)*pulse*30},torso={yaw=(if left then 1 else -1)*pulse*28},[arm]=hand})
end
local function dnaPose(p,pose,t,asset)
 local d=p.motionDNA;pose=M.copy(pose);pose.root=pose.root or {};pose.torso=pose.torso or {};pose.head=pose.head or {}
 pose.root.y=(pose.root.y or 0)+d.centerHeight-(d.groundedness-.7)*.18-(d.apparentWeight-.5)*.15
 pose.root.pitch=(pose.root.pitch or 0)*d.amplitude+(d.forwardPressure-.5)*8
 pose.root.yaw=(pose.root.yaw or 0)*d.rotationAmount*d.hipInvolvement
 pose.root.roll=(pose.root.roll or 0)+(d.lateralBias)*8
 pose.root.x=(pose.root.x or 0)*d.rootIntensity;pose.root.z=(pose.root.z or 0)*d.rootIntensity
 pose.torso.yaw=(pose.torso.yaw or 0)*d.rotationAmount;pose.torso.pitch=(pose.torso.pitch or 0)*d.upperActivity
 pose.head.yaw=(pose.head.yaw or 0)*(.4+d.headTracking);pose.head.pitch=(pose.head.pitch or 0)*(.6+d.precision*.4)
 for _,arm in {"ra","la"} do local a=pose[arm] or {};pose[arm]=a
  a.raise=(a.raise or 0)*d.upperActivity*d.amplitude+(if arm=="ra" then 1 else -1)*d.asymmetry*20
  a.out=(a.out or 0)+(d.guardOpenness-.5)*18;a.elbow=math.clamp((a.elbow or 0)+(d.looseness-.5)*-15,0,160)
 end
 for _,leg in {"rl","ll"} do if pose[leg] then pose[leg].lift=(pose[leg].lift or 0)*d.lowerActivity*(.7+d.acrobatics*.75) end end
 for _,foot in {"rf","lf"} do if pose[foot] then pose[foot].z=(pose[foot].z or 0)*d.lowerActivity*d.stepLength end end
 if asset.category~="Locomotion" then pose.root.z=(pose.root.z or 0)*(1+(d.aggression-.5)*.5) end
 local overrides=p.characterRules.grammarOverrides and p.characterRules.grammarOverrides[asset.grammar]
 if overrides then
  for _,arm in {"ra","la"} do pose[arm].raise*=overrides.bodyScale or 1 end
  pose.root.y+=(overrides.rootLift or 0)*math.sin(math.pi*t);pose.root.z-=(overrides.rootTravel or 0)*math.sin(math.pi*t)
 end
 return pose
end
function S.mirror(pose)
 local p=M.copy(pose);p.ra,p.la=p.la,p.ra;p.rl,p.ll=p.ll,p.rl;p.rf,p.lf=p.lf,p.rf
 for _,key in {"root","torso","head"} do if p[key] then for _,field in {"x","yaw","roll"} do if p[key][field] then p[key][field]=-p[key][field] end end end end
 for _,key in {"rf","lf"} do if p[key] then p[key].x=-(p[key].x or 0);p[key].yaw=-(p[key].yaw or 0) end end
 return p
end
function S.anatomy(preset,asset,t,mirror)
 local clip=preset.clips[asset.grammar];local pose=if clip then keysAt(clip.keys,t) else procedural(preset,asset,t)
 pose=dnaPose(preset,pose,t,asset);return if mirror then S.mirror(pose) else pose
end
local function own(preset,asset,t,mirror) return Solver.build(S.anatomy(preset,asset,t,mirror)) end
function S.sample(preset,asset,t,lib,mirror)
 t=math.clamp(t,0,1);local output=own(preset,asset,t,mirror)
 local function sourcePose(id,layer,seen,depth)
  assert(depth<9 and not seen[id],"Body source cycle");seen[id]=true
  local p=assert(lib.presets[id],"Missing motion source");local poses=own(p,asset,t,mirror);local spec=p.bodyLayers[layer]
  if spec.enabled and spec.source~="base" then
   local target=sourcePose(spec.source,layer,seen,depth+1)
   for _,joint in S.Joints[layer] do if target[joint] then poses[joint]=(poses[joint] or CFrame.identity):Lerp(target[joint],spec.strength) end end
  end
  seen[id]=nil;return poses
 end
 local rootSample=output.Root
 for _,layer in M.Layers do
  local spec=preset.bodyLayers[layer]
  if spec.enabled and spec.source~="base" then
   local target=sourcePose(spec.source,layer,{},0)
   if layer=="Root" then rootSample=rootSample:Lerp(target.Root,spec.strength)
   else for _,joint in S.Joints[layer] do if target[joint] then output[joint]=(output[joint] or CFrame.identity):Lerp(target[joint],spec.strength) end end end
  end
 end
 output.motion=Vector3.new(rootSample.Position.X,0,rootSample.Position.Z)
 output.Root=CFrame.new(0,output.Root.Position.Y,0)*output.Root.Rotation
 return output
end
function S.sequence(preset,sequence,time,lib,mirror)
 if #sequence.orderedClips==0 then return S.sample(preset,lib.assets.idle,0,lib,mirror),nil,0 end
 local cursor=0
 for index,block in sequence.orderedClips do
  local duration=block.duration/preset.motionDNA.recoverySpeed
  if time<cursor+duration or index==#sequence.orderedClips then
   local t=math.clamp((time-cursor)/duration,0,1);local asset=assert(lib.assets[block.asset],"Missing clip")
   local pose=S.sample(preset,asset,t,lib,mirror)
   if index>1 and block.transition=="blend" and block.blend>0 and time-cursor<block.blend then
    local prev=sequence.orderedClips[index-1];local from=S.sample(preset,lib.assets[prev.asset],1,lib,mirror);local u=smooth((time-cursor)/block.blend)
    for key,value in pose do if typeof(value)=="CFrame" and from[key] then pose[key]=from[key]:Lerp(value,u) elseif key=="motion" then pose.motion=from.motion:Lerp(value,u) end end
   end
   return pose,index,t
  end
  cursor+=duration
 end
 error("Sequence unreachable")
end
return S
