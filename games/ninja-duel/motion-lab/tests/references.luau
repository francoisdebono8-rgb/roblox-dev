return function(load,test,lib)
local Vector3=require("@lune/roblox").Vector3
local R=load("ReferenceMotionLibrary");local E=load("MotionEdit");local M=load("Model");local S=load("Sampler");local Solver=load("PoseSolver");local A=load("NinjaDuelAdapter")
local neutral=M.new("reference_test","Reference mechanics")
local function near(a,b)assert(math.abs(a-b)<1e-5,tostring(a).." != "..tostring(b))end
local function sf(side)return if side=="Left"then "L"else "R"end
local function opposite(side)return if side=="Left"then "Right"else "Left"end
local function shape(a,t)return S.mixedAnatomy(neutral,a,t,lib)end
local required={"combatRole","range","leadSide","supportFoot","weightShift","hipRotation","torsoRotation","contactPhase","followThrough","recovery","validFollowups"}
test("120 reference Motion Variants have provenance, editable six phases and immutable sources",function()
 local count=0
 for _,id in lib.assetOrder do local a=lib.assets[id];if not a.referenceBacked then continue end;count+=1
  local v=assert(a.variantDefinition);assert(E.validate(v));assert(a.variant and not a.hidden and lib.assets[v.sourceAsset].hidden)
  assert(v.phaseSchema=="combat-six" and #E.markers(v)==6)
  for _,field in required do assert(a.metadata[field]~=nil,id..": "..field)end
  assert(#a.metadata.references>0 and lib.assets[a.counterpart].counterpart==a.id)
  for _,semantic in E.CombatSemantics do assert(E.phase(v,semantic).sourceTime==a.combatPhases[semantic])end
  local p=M.new("validation","Validation");p.clips[a.grammar]=a.authoredClip;assert(M.validate(p),id)
 end
 assert(count==120,"Expected 78 attacks + 8 auxiliaries + 16 bridges + 18 phrases: "..count)
end)
test("jab is genuinely lead and cross rear in orthodox and southpaw; hook has no grand arm windup",function()
 for _,s in {"Left","Right"}do
  local jab=lib.assets["ref_jab_"..sf(s).."_Base"];local cross=lib.assets["ref_cross_"..sf(s).."_Base"]
  assert(jab.metadata.leadSide==s and cross.metadata.leadSide==opposite(s))
  local j=shape(jab,jab.combatPhases.Contact);local c=shape(cross,cross.combatPhases.Contact)
  assert(math.abs(c.root.yaw-cross.authoredClip.keys[1].pose.root.yaw)>math.abs(j.root.yaw-jab.authoredClip.keys[1].pose.root.yaw)*2)
  local strikingFoot=if s=="Left"then c.lf else c.rf;local brace=if s=="Left"then c.rf else c.lf;assert(strikingFoot.toe>0 and brace.toe==0)
  local hook=lib.assets["ref_hook_"..sf(s).."_Base"];local load=shape(hook,hook.combatPhases.Anticipation);local arm=if s=="Left"then load.la else load.ra
  assert(arm.raise>=60 and math.abs(arm.out)<=12 and arm.elbow>=90,"Hook is wound behind guard")
 end
end)
test("planted ankles remain reachable across actual R15 support trajectories, without IK clamping",function()
 for _,id in lib.assetOrder do local a=lib.assets[id];if not a.referenceBacked then continue end
  for i=0,80 do local p=shape(a,i/80);local pose=Solver.build(p)
   for _,s in {1,-1}do local f=if s==1 then p.rf else p.lf
    if f then local hip=pose.Root*Vector3.new(s*.5,-.55,0);local ankle=Vector3.new(s*.5+(f.x or 0),-2.6+(f.y or 0),f.z or 0)
     assert((ankle-hip).Magnitude<=2.049,id.." unreachable support at "..i..": "..(ankle-hip).Magnitude)
    end
   end
  end
 end
end)
test("kicks pivot towards hip rotation, transfer onto support, rechamber and strike towards target",function()
 for _,def in R.Specs do if not def.legs then continue end
  for _,s in {"Left","Right"}do local a=lib.assets["ref_"..def.id.."_"..sf(s).."_Base"]
   local ready=shape(a,0);local p=shape(a,a.combatPhases.Contact);local support=if s=="Left"then p.rf else p.lf
   local f0=if s=="Left"then ready.rf else ready.lf;near(support.x,f0.x);near(support.z,f0.z);near(support.y,0)
   local footRotation=support.yaw-f0.yaw;local hipRotation=p.root.yaw-ready.root.yaw;assert(footRotation*hipRotation>=0)
   local loaded=shape(a,a.combatPhases.Anticipation);local f=if s=="Left"then loaded.rf else loaded.lf
   assert(math.abs(loaded.root.x-(if s=="Left"then .5+f.x else -.5+f.x))<.8,"No load over support")
   local leg=if s=="Left"then "ll"else "rl";local planted=if s=="Left"then "lf"else "rf"
   for _,k in a.authoredClip.keys do assert(k.pose[leg] and not k.pose[planted])end
   if def.category=="Kicks"and def.id~="sweep"then
    local heel=Solver.footTarget(p,if s=="Left"then -1 else 1)
    assert(heel.z<-.45,"Kick does not reach forward: "..a.id.." z="..heel.z)
    assert(shape(a,.82)[leg].knee>50,"Missing rechamber: "..a.id)
   end
   if def.id=="roundhouse"then assert(loaded[leg].knee<50,"Thai kick replaced by deep chamber")end
  end
 end
end)
test("free striking feet do not pass through the floor during load, arc or recovery",function()
 for _,def in R.Specs do if not def.legs then continue end
  for _,s in {"Left","Right"}do for _,kind in {"Base",def.tactic,"Ninja"}do
   local a=lib.assets["ref_"..def.id.."_"..sf(s).."_"..kind]
   if kind=="StepIn"or kind=="LongSpacing"then
    local p=shape(a,a.combatPhases.Anticipation);local strikeFoot=Solver.footTarget(p,if s=="Left"then -1 else 1);near(strikeFoot.y,0)
    local plant=false;for _,key in a.authoredClip.keys do if key.phase=="PlantSupport"then plant=true;assert((if s=="Left"then key.pose.rf else key.pose.lf).y==0)end end;assert(plant)
   end
   for i=0,100 do local p=shape(a,i/100);local ankle=Solver.footTarget(p,if s=="Left"then -1 else 1)
    assert(ankle.y>=-.025,a.id.." penetrates floor at "..i..": "..ankle.y)
   end
  end end
 end
end)
test("tactical variants change mechanics; modest Ninja carry leaves support intact",function()
 for _,def in R.Specs do for _,s in {"L","R"}do
  local base=lib.assets["ref_"..def.id.."_"..s.."_Base"];local tactical=lib.assets["ref_"..def.id.."_"..s.."_"..def.tactic];local ninja=lib.assets["ref_"..def.id.."_"..s.."_Ninja"]
  assert(A.serialize(base.authoredClip.keys)~=A.serialize(tactical.authoredClip.keys),def.id)
  local p=shape(base,base.combatPhases.Contact);local q=shape(ninja,ninja.combatPhases.Contact)
  for _,key in {"lf","rf"}do if p[key]then assert(q[key]);near(p[key].x,q[key].x);near(p[key].z,q[key].z);near(p[key].yaw,q[key].yaw)end end
  near(p.root.x,q.root.x);near(p.root.z,q.root.z)
 end end
end)
test("all eight routes and jab-cross-hook expose multiple contacts with planted punch bridges",function()
 for _,route in R.Routes do for _,s in {"L","R"}do
  local phrase=lib.assets["ref_phrase_"..route.id.."_"..s];local bridge=lib.assets["ref_bridge_"..route.id.."_"..s]
  assert(phrase and bridge and #phrase.contactMarkers==2 and phrase.contactMarkers[1].at<phrase.contactMarkers[2].at)
  assert(phrase.metadata.weightShift==route.flow and phrase.metadata.transition.receivingSide)
  if route.id=="jab_cross"or route.id=="cross_hook"then
   local a=shape(bridge,0);local b=shape(bridge,1)
   for _,f in {"lf","rf"}do near(a[f].x,b[f].x);near(a[f].z,b[f].z);assert(a[f].y==0 and b[f].y==0)end
  end
  for _,k in phrase.authoredClip.keys do if k.at>0 and k.at<1 then
   local a=S.sample(neutral,phrase,k.at-1e-6,lib);local b=S.sample(neutral,phrase,k.at+1e-6,lib)
   for _,j in {"Root","Waist","RightHip","LeftHip","Right","Left"}do assert((a[j].UpVector-b[j].UpVector).Magnitude<.005,phrase.id.." pose pop")end
  end end
 end end
 for _,s in {"L","R"}do assert(#lib.assets["ref_phrase_jab_cross_hook_"..s].contactMarkers==3)end
end)
test("built-in variants copy on edit, retain six-phase edits after restart and export edited pose",function()
 local settings={};local plugin={GetSetting=function(_,k)return settings[k]end,SetSetting=function(_,k,v)settings[k]=v end}
 local c=load("Controller").create(plugin);c:new(nil);c.clip="ref_roundhouse_L_Base";local original=A.serialize(c:asset())
 c:selectKey("Acceleration","Torso");c:setPose("yaw",7);c:selectKey("Contact","LeftLeg");c:setPose("lift",9)
 c:variantEdit(function(v)E.moveKeys(v,{Contact=true},.015);v.timing.hold=.02 end)
 assert(E.validate(c:variant()) and M.validateAssets(c.preset,c.library.assets));assert(A.serialize(c.library.assets[c.clip])==original)
 c:assignVariant("run");c:save();local id=c.preset.id
 local reopened=load("Controller").create(plugin);reopened:load(id);reopened.clip=c.clip
 assert(E.phase(reopened:variant(),"Acceleration").parts.Torso.yaw==7 and E.phase(reopened:variant(),"Contact").parts.LeftLeg.lift==9)
 local bundle=A.bundle(c.preset,c.library,c.clip);local json=A.serialize(bundle);assert(#json<2000000)
 local decoded=A.read({FindFirstChild=function()end,IsA=function(_,cls)return cls=="StringValue"end,Value=json},lib);assert(decoded.motionVariants[c.clip].phaseSchema=="combat-six")
 local at=E.phase(c:variant(),"Contact").time;local contact
 for _,key in bundle.ninjaDuel.clips[c.clip]do if math.abs(key.at-1)<1e-5 then contact=key.pose end end
 assert(contact);near(contact.ll.lift,S.mixedAnatomy(c.preset,c:asset(),at,c.library).ll.lift)
 local copy=c:createVariant();assert(copy~=c.clip.."_source" and c:variant().sourceAsset=="ref_roundhouse_L_Base_source")
end)
test("six-phase markers allow hold/retime while old five-phase presets stay compatible",function()
 local v=M.copy(lib.assets.ref_cross_R_Base.variantDefinition);E.phase(v,"Contact").time+=.01
 near(E.warp(v,E.phase(v,"Contact").time),E.phase(v,"Contact").sourceTime)
 local drive=E.key(v,"HipDrive_3");assert(drive);E.moveKeys(v,{[drive.id]=true},.01);near(E.warp(v,drive.time),drive.sourceTime)
 v.timing.hold=.03;near(E.warp(v,E.phase(v,"Contact").time+.015),E.phase(v,"Contact").sourceTime)
 assert(E.moveKeys(v,{Ready=true},.1)==0 and E.moveKeys(v,{Recovery=true},-.1)==0)
 local old=E.create("legacy","Legacy",lib.assets.cross,.6,.4,.7);assert(old.phaseSchema==nil and #E.markers(old)==5 and E.validate(old))
 local bad=M.copy(v);bad.poseOverrides[1].semantic="Start";assert(not E.validate(bad))
end)
end
