return function(load,test,lib)
local M=load("Model");local B=load("BilateralLibrary");local S=load("Sampler");local A=load("NinjaDuelAdapter");local E=load("MotionEdit");local Store=load("Store");local Solver=load("PoseSolver")
local neutral=M.new("common_test","Common mechanics")
local function near(a,b)assert(math.abs(a-b)<1e-5,tostring(a).." != "..tostring(b))end
local function name(id,side,variant)return "common_"..id.."_"..side.."_"..(variant or "Standard")end
local function shape(asset,t)return S.mixedAnatomy(neutral,asset,t,lib)end
local function equalPose(a,b)
 for _,joint in {"Root","Waist","Neck","Right","Left","RightHip","LeftHip","RightKnee","LeftKnee","RightElbow","LeftElbow"}do
  if (a[joint].Position-b[joint].Position).Magnitude>1e-5 or (a[joint].UpVector-b[joint].UpVector).Magnitude>1e-5 or (a[joint].RightVector-b[joint].RightVector).Magnitude>1e-5 then return false end
 end;return true
end
test("182 independent common clips, bilateral families and complete mechanics metadata",function()
 local count=0
 for _,id in lib.assetOrder do local a=lib.assets[id];if not a.authoredClip or a.referenceBacked then continue end;count+=1
  assert(a.independentlyEditable and a.mirrorSource==false and a.family and a.variantName and a.side and a.attackingLimb and a.supportLimb and a.stance)
  assert(#a.bodyMechanics>0 and a.legacyAsset and lib.assets[a.legacyAsset]);if a.side~="Neutral"then assert(lib.assets[a.counterpart].counterpart==a.id)end
  local p=M.new("validate","Validate");p.clips[a.grammar]=M.copy(a.authoredClip);assert(M.validate(p))
 end
 assert(count==182,"Expected 126 strikes + 32 movement + 24 bridges, got "..count)
 for _,def in B.Strikes do for _,variant in def.variants do
  local left,right=lib.assets[name(def.id,"L",variant)],lib.assets[name(def.id,"R",variant)];assert(left and right and left.authoredClip~=right.authoredClip)
  local mirror=Solver.build(S.mirror(shape(left,left.contactMarkers[1].at)));local actual=Solver.build(shape(right,right.contactMarkers[1].at))
  assert(not equalPose(mirror,actual),"Blind mirror: "..def.id)
 end end
end)
test("variants have changed load/contact/carry silhouettes, not only duration",function()
 for _,def in B.Strikes do for _,side in {"L","R"}do
  local poses={};for _,variant in def.variants do
   local a=lib.assets[name(def.id,side,variant)];local at=a.contactMarkers[1].at;local p=Solver.build(shape(a,at));for _,old in poses do assert(not equalPose(old,p),"Repeated silhouette: "..a.id)end;table.insert(poses,p)
  end
 end end
end)
test("kick/knee support stays planted and kicking limb has continuous FK endpoints",function()
 local cross=shape(lib.assets.common_cross_R_Standard,.44);assert(cross.lf.toe==0 and cross.rf.toe>10,"Brace lifted instead of rear heel")
 for _,side in {"L","R"}do local round=shape(lib.assets[name("roundhouse",side)],.44);local f=if side=="L"then round.rf else round.lf;assert(math.abs(f.yaw-round.root.yaw)<90,"Foot pivots against pelvis")end
 for _,def in B.Strikes do if def.category=="Kicks"or def.category=="Knees"then for _,side in {"L","R"}do
  local a=lib.assets[name(def.id,side)];local l=if side=="L"then "ll"else "rl";local support=if side=="L"then "rf"else "lf"
  for _,k in a.authoredClip.keys do assert(k.pose[l] and not k.pose[if side=="L"then "lf"else "rf"])
   if def.mode~="jumpknee"then assert(k.pose[support] and k.pose[support].y==0,"Support floating: "..a.id)end
  end
  local raw=Solver.build(a.authoredClip.keys[1].pose);local guard=Solver.build(B.guard("LeftLead"));assert(equalPose(raw,guard),"FK entry pop")
 end end end
end)
test("all new R15 transforms stay finite and continuous across authored key boundaries",function()
 for _,id in lib.assetOrder do local a=lib.assets[id];if not a.authoredClip then continue end
  for i=0,32 do local pose=S.sample(neutral,a,i/32,lib)
   for joint,cf in pose do if typeof(cf)=="CFrame"then for _,n in {cf:GetComponents()}do assert(M.finite(n),id.." / "..joint)end end end
  end
  for _,key in a.authoredClip.keys do if key.at>0 and key.at<1 then
   local before=S.sample(neutral,a,key.at-1e-6,lib);local after=S.sample(neutral,a,key.at+1e-6,lib)
   for _,joint in {"RightHip","LeftHip","RightKnee","LeftKnee","RightAnkle","LeftAnkle","Right","Left","Root"}do
    assert((before[joint].UpVector-after[joint].UpVector).Magnitude<.004 and (before[joint].RightVector-after[joint].RightVector).Magnitude<.004,"Pose pop: "..id.." / "..joint)
   end
  end end
 end
end)
test("lateral gait leads with direction-side foot and keeps target-facing guard",function()
 for _,family in {"strafe","lateralrun","diagonal"}do for _,side in {"L","R"}do
  local a=lib.assets[name(family,side)];local p=shape(a,.125);local leading=if side=="L"then p.lf else p.rf;local planted=if side=="L"then p.rf else p.lf
  assert(leading.y>.1 and planted.y==0,"Wrong leading foot: "..a.id)
  near(p.root.yaw+p.torso.yaw+p.head.yaw,0);assert(p.la.elbow>90 and p.ra.elbow>90)
 end end
 local a=lib.assets.common_walkforward_N_Standard;local p=shape(a,.25);local q=shape(a,.375);near(p.lf.z,q.lf.z);assert(q.rf.y>.1)
 local back=shape(lib.assets.common_walkbackward_N_Standard,1);assert(back.root.z>0)
end)
test("bridges reference exact exit/entry poses and declare stance switches",function()
 for _,route in B.Routes do for _,side in {"L","R"}do
  local a=lib.assets["common_transition_"..route.id.."_"..side];local meta=a.metadata;assert(meta.fromAsset and meta.toAsset and type(meta.stanceSwitch)=="boolean")
  assert(table.find(lib.assets[meta.fromAsset].compatibleTransitions,a.id) and table.find(lib.assets[meta.toAsset].compatibleTransitions,a.id))
  local source=lib.assets[meta.fromAsset].authoredClip.keys[5].pose;local entry=a.authoredClip.keys[1].pose
  near(entry.root.yaw,source.root.yaw);near(entry.root.y,source.root.y);near(entry.ra.raise,source.ra.raise);near(entry.la.raise,source.la.raise)
  for _,limb in {"ll","rl"}do if entry[limb]then for _,key in a.authoredClip.keys do assert(key.pose[limb],"Mixed leg mode in bridge")end end end
 end end
end)
test("common edits survive settings/JSON and export the exact edited contact + timing",function()
 local settings={};local plugin={GetSetting=function(_,k)return settings[k]end,SetSetting=function(_,k,v)settings[k]=v end}
 local c=load("Controller").create(plugin);c:new(nil);c.clip=name("roundhouse","L","Rotational");local source=c:asset();local original=A.serialize(source)
 local id=c:createVariant();assert(c.selectedPart=="LeftLeg" and E.validate(c:variant()));c:setPose("lift",18);c:variantEdit(function(v)v.poseOverrides[3].parts.LeftFoot=nil;v.poseOverrides[3].parts.Head={yaw=10};v.timing.duration=1.6 end)
 local at=c:variant().poseOverrides[3].time;E.moveKeys(c:variant(),{Contact=true},.04);at+=.04
 c:save();local reopened=load("Controller").create(plugin);reopened:load(c.preset.id);reopened.clip=id;assert(reopened:variant().poseOverrides[3].parts.LeftLeg.lift==18)
 local bundle=A.bundle(c.preset,c.library,c.clip);local json=A.serialize(bundle);assert(#json<2000000 and M.safe(bundle) and not bundle.automaticApply)
 local imported=A.read({IsA=function(_,cls)return cls=="StringValue"end,FindFirstChild=function()end,Value=json},lib);assert(imported.motionVariants[id] and M.validateAssets(imported,lib.assets))
 local contact;for _,k in bundle.ninjaDuel.clips[id]do if math.abs(k.at-1)<1e-5 then contact=k.pose end end
 local expected=S.mixedAnatomy(c.preset,c:asset(),at,c.library);assert(contact);near(contact.ll.lift,expected.ll.lift);near(contact.head.yaw,expected.head.yaw);near(bundle.ninjaDuel.timings[id].startup,at*1.6)
 assert(A.serialize(source)==original,"Original mutated")
end)
test("legacy comparison and side switch use independent clips; common export is bounded",function()
 local c=load("Controller").create({GetSetting=function()end,SetSetting=function()end});c.clip=name("jab","L","Long");c:compareLegacy();assert(c.compareClip=="jab" and c.clip==name("jab","L","Long"))
 c:switchSide();assert(c.clip==name("jab","R","Long") and c.compareClip=="jab" and not c.mirror)
 local bundle=A.bundle(c.preset,c.library,c.clip);assert(bundle.assets[c.clip] and bundle.ninjaDuel.clips[c.clip]);assert(not bundle.assets[name("spinningkick","R","Rotational")])
 local source=c:asset();local t=source.contactMarkers[1].at;local contact;for _,k in bundle.ninjaDuel.clips[source.id]do if math.abs(k.at-1)<1e-6 then contact=k.pose end end
 assert(contact);near(contact.ra.raise,S.mixedAnatomy(c.preset,source,t,c.library).ra.raise)
 near(bundle.ninjaDuel.timings[source.id].startup,t*S.duration(c.preset,source,c.library));assert(#A.serialize(bundle)<2000000)
end)
end
