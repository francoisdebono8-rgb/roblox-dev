-- Called by the existing harness; all changes exercised through production modules.
return function(load,test,lib)
local M=load("Model");local E=load("MotionEdit");local S=load("Sampler");local A=load("NinjaDuelAdapter");local Store=load("Store");local L=load("Library")
local function fixture()
 local p=M.copy(lib.presets.Flashstep);p.id="variant_test";local v=E.create("roundhouse_wide","Roundhouse_Wide",lib.assets.roundhouse,.8)
 p.motionVariants={[v.id]=v};return p,v,E.asset(p,v.id,lib)
end
local function near(a,b)assert(math.abs(a-b)<.00001,tostring(a).." != "..tostring(b))end
local function same(a,b)return (a.Position-b.Position).Magnitude<.00001 and (a.UpVector-b.UpVector).Magnitude<.00001 end
test("neutral variant preserves anatomy and immutable source",function()
 local p,v,asset=fixture();local original=A.serialize(lib.presets.Flashstep);assert(E.validate(v) and M.validate(p) and M.validateAssets(p,lib.assets))
 for _,t in {0,.1,.18,.42,.64,.9,1}do near(E.warp(v,t),t);local before=S.mixedAnatomy(p,lib.assets.roundhouse,t,lib);local after=S.mixedAnatomy(p,asset,t,lib);near(before.root.yaw,after.root.yaw);near(before.rl.lift,after.rl.lift)end
 v.poseOverrides[3].parts={RightLeg={lift=35,knee=-30},Hips={yaw=40},Torso={roll=-20},Root={z=-.6}};local pose=S.sample(p,asset,.42,lib);assert(pose.RightHip and pose.motion.Z<-.5);assert(A.serialize(lib.presets.Flashstep)==original)
end)
test("per-part interpolation, mute and recovery restore base",function()
 local p,v,asset=fixture();v.poseOverrides[3].parts.RightArm={raise=30,elbow=-25,elbowTwist=35}
 local base=S.mixedAnatomy(p,lib.assets.roundhouse,.42,lib);near(S.mixedAnatomy(p,asset,.42,lib).ra.raise-base.ra.raise,30)
 assert(not same(S.sample(p,asset,.42,lib).RightElbow,S.sample(p,lib.assets.roundhouse,.42,lib).RightElbow))
 v.channels.RightArm={muted=true,locked=false};near(S.mixedAnatomy(p,asset,.42,lib).ra.raise,base.ra.raise)
 v.channels.RightArm.muted=false;near(S.mixedAnatomy(p,asset,1,lib).ra.raise,S.mixedAnatomy(p,lib.assets.roundhouse,1,lib).ra.raise)
end)
test("timing warp, contact hold, speed and grouped drags",function()
 local p,v,asset=fixture();E.moveKeys(v,{Contact=true},.12);near(v.poseOverrides[3].time,.54);near(E.warp(v,.54),.42)
 v.timing.hold=.08;near(E.warp(v,.58),.42);v.timing.duration=1.2;v.timing.playbackSpeed=2;near(S.duration(p,asset,lib),.6)
 local before=v.poseOverrides[2].time;near(E.moveKeys(v,{Anticipation=true,Contact=true},-.03),-.03);near(v.poseOverrides[2].time,before-.03);assert(E.validate(v))
 E.moveKeys(v,{Contact=true},100);assert(v.poseOverrides[3].time<v.poseOverrides[4].time and E.moveKeys(v,{Start=true},.1)==0)
end)
test("extra keys inherit corrections without insertion pops",function()
 local p,v,asset=fixture();v.poseOverrides[3].parts.RightArm={raise=30};local before=S.mixedAnatomy(p,asset,.32,lib).ra.raise
 E.addKey(v,"extra",.32);near(S.mixedAnatomy(p,asset,.32,lib).ra.raise,before);assert(E.validate(v));local k,i=E.key(v,"extra");assert(k.parts.RightArm.raise>0);table.remove(v.poseOverrides,i);near(S.mixedAnatomy(p,asset,.32,lib).ra.raise,before)
end)
test("exaggeration and root path change sampled transforms",function()
 local p,v,asset=fixture();local before=S.sample(p,asset,.42,lib);v.motionModifiers.amplitude=1.4;v.motionModifiers.hipRotation=1.6;v.motionModifiers.limbExtension=1.3;v.motionModifiers.impactLean=1.5
 v.rootPath={forward=2,lateral=1,lift=.8,turn=60,startX=.5,startY=.2,startZ=0,endX=-.5,endY=1,endZ=-2}
 local after=S.sample(p,asset,.42,lib);assert(not same(before.RightHip,after.RightHip) and (after.motion-before.motion).Magnitude>1)
 near(S.mixedAnatomy(p,asset,0,lib).root.x,.5);near(S.mixedAnatomy(p,asset,1,lib).root.x,-.5)
end)
test("settings restart and JSON retain variants, assignments and sequences",function()
 local p,v=fixture();v.poseOverrides[3].parts.Torso={yaw=36};p.locomotionSet.roundhouse=v.id;p.sequences={{id="route",name="Variant route",orderedClips={{asset=v.id,duration=.8,blend=.1,transition="blend"}}}}
 local settings={};local plugin={GetSetting=function(_,k)return settings[k]end,SetSetting=function(_,k,val)settings[k]=val end};Store.new(plugin,lib):save(p)
 local fresh=L.new();A.import(load("NinjaSources"),fresh);local reopened=Store.new(plugin,fresh);assert(reopened.custom[p.id].motionVariants[v.id].poseOverrides[3].parts.Torso.yaw==36)
 local json=A.serialize(A.bundle(p,lib));local imported=A.read({IsA=function(_,cls)return cls=="StringValue"end,FindFirstChild=function()return nil end,Value=json},fresh);assert(imported.motionVariants[v.id].name==v.name and M.validateAssets(imported,fresh.assets));assert(S.sequence(imported,imported.sequences[1],.336,fresh).Waist)
end)
test("adapter bakes actual edited contact poses and timing",function()
 local p,v,asset=fixture();v.poseOverrides[3].parts={Torso={yaw=50},Root={z=-1}};E.moveKeys(v,{Contact=true},.1);v.timing.duration=1.4;v.timing.playbackSpeed=2;p.locomotionSet.roundhouse=v.id
 local defs=A.ninjaDefinitions(p,lib);near(defs.timings[v.id].startup,.52*.7);near(defs.timings.Roundhouse.startup,.52*.7)
 local contact=nil;for _,key in defs.clips[v.id]do if math.abs(key.at-1)<.000001 then contact=key.pose end end;assert(contact,"Export must sample semantic contact")
 local preview=S.mixedAnatomy(p,asset,.52,lib);near(contact.torso.yaw,preview.torso.yaw);near(contact.root.z,preview.root.z);assert(not defs.automaticApply and defs.clips.Roundhouse)
end)
test("variant undo redo, lock, A/B and sequence integration",function()
 local c=load("Controller").create({GetSetting=function()return nil end,SetSetting=function()end});c.clip="roundhouse";local id=c:createVariant();assert(c.compareClip=="roundhouse" and c.clip==id)
 c:setPose("raise",40);assert(E.key(c:variant(),"Contact").parts.RightArm.raise==40);c:undo();assert(not E.key(c:variant(),"Contact").parts.RightArm);c:redo();assert(E.key(c:variant(),"Contact").parts.RightArm.raise==40)
 c:variantEdit(function(v)v.channels.RightArm={muted=false,locked=true}end);assert(not pcall(c.setPose,c,"raise",20));c:assignVariant();assert(c.preset.locomotionSet.roundhouse==id);c:addClip(id);assert(c:sequence().orderedClips[1].asset==id)
end)
test("invalid edit data rejected before persistence",function()
 for _,mutate in {function(v)v.poseOverrides[3].time=-1 end,function(v)v.poseOverrides[3].parts.RightArm={raise=0/0}end,function(v)v.timing.easing="execute"end,function(v)v.rootPath.turn=math.huge end,function(v)v.poseOverrides[3].semantic="Start"end,function(v)v.timing.duration=0 end,function(v)v.sourceAsset=v.id end}do
  local p,v=fixture();mutate(v);assert(not (M.validate(p) and M.validateAssets(p,lib.assets)))
 end
end)
end
