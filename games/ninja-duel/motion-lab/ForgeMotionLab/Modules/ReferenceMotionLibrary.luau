-- Coach-reference adaptations, not mocap or experimentally measured joint angles.
-- Immutable sources + copy-on-edit Motion Variants. No runtime combat integration.
local M=require(script.Parent.Model)
local E=require(script.Parent.MotionEdit)
local Solver=require(script.Parent.PoseSolver)
local R={Revision=1}
R.Sources={
 boxing="https://www.englandboxing.org/wp-content/uploads/2022/03/EB_Boxing-Coaching-Handbook-Part-1_v8-002.pdf",
 chain="https://www.mdpi.com/2076-3417/15/7/4008",
 combinations="https://clok.uclan.ac.uk/id/eprint/3757/1/piorkowski-et-al-2011-punch-kinematics.pdf",
 roundhouse="https://8limbsus.com/muay-thai-thailand/golden-kick-how-to-improve-your-thai-kick",
 knee="https://8limbsus.com/muay-thai-thailand/learning-the-details-of-the-vertical-knee-from-the-legend-chamuakpet-hapalang",
 teep="https://evolve-university.com/blog/5-effective-ways-to-use-the-teep-in-muay-thai-and-how-to-land-them/",
 backkick="https://research.kukkiwon.or.kr/homepage/boardMedia/11621",
 sidekick="https://elasticsteel.com/blogs/kicking-corrections-and-tips/what-does-your-side-kick-look-like",
 elbow="https://evolve-university.com/blog/beginners-guide-to-elbows-in-mma/",
 sweep="https://evolve-university.com/blog/heres-how-to-utilize-the-catch-and-sweep-in-muay-thai/",
}
local function arm(r,o,e,t)return {raise=r,out=o,elbow=e,twist=t or 0,wrist=0,wroll=0}end
local function other(s)return if s=="Left"then "Right"else "Left"end
local function sign(s)return if s=="Left"then -1 else 1 end
local function foot(s)return if s=="Left"then "lf"else "rf"end
local function leg(s)return if s=="Left"then "ll"else "rl"end
local function hand(s)return if s=="Left"then "la"else "ra"end
local function suffix(s)return if s=="Left"then "L"else "R"end
local function convert(p,s)if p[foot(s)]then p[leg(s)]=Solver.freeLeg(p,sign(s));p[foot(s)]=nil end end
function R.guard(lead)
 local left=lead=="Left";local yaw=if left then 12 else -12
 return {root={x=0,y=-.45,z=0,pitch=2,yaw=yaw,roll=0},torso={pitch=1,yaw=-yaw*.5,roll=0},head={pitch=-2,yaw=-yaw*.5,roll=0},
 la=arm(if left then 65 else 55,8,if left then 100 else 125),ra=arm(if left then 55 else 65,8,if left then 125 else 100),
 lf={x=-.02,y=0,z=if left then -.28 else .28,yaw=if left then 0 else -18,toe=0},rf={x=.02,y=0,z=if left then .28 else -.28,yaw=if left then 18 else 0,toe=0}}
end
-- Per-technique pose stages: load, hip drive, acceleration, contact, carry,
-- rechamber, guard. Shoulder/hip/torso curves deliberately differ in shape.
-- Arm triples: shoulder elevation, lateral angle, elbow flexion.
-- Leg triples: hip flexion, lateral angle, knee flexion. No universal kick chamber.
R.Specs={
 {id="jab",name="Jab",category="Punches",role="opener",range="mid",duration=.52,contact=.40,follow=.53,lead="striker",hip={0,5,9,12,13,4},torso={0,0,3,7,8,2},arms={{64,8,105},{69,5,87},{83,1,48},{91,-3,12},{86,-1,22},{66,8,105}},weight="Small lead-foot pressure; rear hand stays on chin; no drawn-back fist",carry="Short extension then immediate lead-hand return",next={"cross","lowkick","hook"},tactic="StepIn",legacy="jab",refs={"boxing","chain"}},
 {id="cross",name="Cross",category="Punches",role="pressure",range="mid",duration=.65,contact=.43,follow=.59,lead="opposite",hip={-3,15,29,43,46,10},torso={0,2,8,16,19,4},arms={{54,7,125},{60,5,117},{80,-4,62},{97,-10,10},{94,-14,23},{60,8,124}},weight="Rear ball pivots; rear knee drives pelvis into a braced lead leg",carry="Shoulder follows pelvis; do not overthrow centre; rear fist returns to chin",next={"hook","roundhouse","frontkick"},tactic="ShortCounter",legacy="cross",refs={"boxing","chain"}},
 {id="hook",name="Hook",category="Punches",role="counter",range="close",duration=.67,contact=.43,follow=.56,lead="Left",hip={-5,12,26,38,44,8},torso={-2,0,8,22,26,4},arms={{65,8,104},{72,7,96},{82,-16,88},{87,-47,90},{80,-63,96},{65,8,109}},weight="Lead hook releases lead heel and settles towards rear leg; rear hook reverses the brace",carry="Compact transverse arc from guard; elbow near shoulder height; opposite hand guards",next={"cross","uppercut","frontkick"},tactic="ShortRange",legacy="hook",refs={"boxing","chain"}},
 {id="uppercut",name="Uppercut",category="Punches",role="launcher",range="close",duration=.73,contact=.46,follow=.60,lead="Left",hip={-4,8,20,29,30,8},torso={-2,0,5,12,13,2},arms={{44,7,126},{48,3,124},{78,-5,101},{116,-8,83},{121,-7,79},{63,8,122}},weight="Knees dip under guard; support-leg extension lifts hips before fist travels up the centre",carry="Short bent-arm upward path; no overhead windmill; knees soften on return",next={"hook","cross","aerial"},tactic="BodyCounter",legacy="uppercut",refs={"boxing","chain"}},
 {id="frontkick",name="Front kick / teep",category="Kicks",role="spacing",range="long",duration=.86,contact=.45,follow=.58,lead="Left",hip={0,2,4,8,8,2},torso={0,0,-1,-4,-5,0},legs={{44,4,104},{66,3,111},{80,2,60},{91,2,12},{86,3,27},{63,3,113}},weight="Weight settles over standing foot before knee lift; hip drives straight teep with upright guard",carry="Linear foot thrust; rechamber before replanting; no falling forward",next={"jab","cross","forwardknee"},tactic="StopTeep",legacy="frontkick",refs={"teep"}},
 {id="sidekick",name="Side kick",category="Kicks",role="knockback",range="long",duration=1.02,contact=.48,follow=.62,lead="striker",hip={8,38,66,86,89,42},torso={0,-6,-13,-18,-18,-8},legs={{31,12,108},{35,38,112},{30,66,58},{15,82,12},{13,85,23},{32,48,117}},weight="Standing heel turns towards target; chamber folds knee before lateral heel thrust",carry="Heel-led side extension; torso counterbalances; knee rechambers before returning to stance",next={"cross","jab","pursuit"},tactic="LongSpacing",legacy="sidekick",refs={"sidekick"}},
 {id="roundhouse",name="Roundhouse",category="Kicks",role="pressure",range="long",duration=.93,contact=.47,follow=.63,lead="opposite",hip={-4,19,53,91,108,38},torso={0,-2,-7,-16,-21,-7},legs={{13,5,32},{38,12,34},{59,39,25},{29,76,16},{17,87,27},{43,17,69}},weight="Rear shin rises on a compact forward path; support ball pivots with pelvis, then hip sends shin through arc",carry="Continuous shin swing, not side-kick chamber; counterbalancing arm and controlled recoil",next={"cross","hook","forwardknee"},tactic="QuickReturn",legacy="roundhouse",refs={"roundhouse"}},
 {id="lowkick",name="Low kick",category="Kicks",role="pressure",range="mid",duration=.76,contact=.44,follow=.60,lead="opposite",hip={-3,12,34,63,76,22},torso={0,-1,-4,-10,-13,-4},legs={{15,8,40},{35,12,35},{44,18,27},{50,20,16},{43,25,30},{35,6,88}},weight="Standing ball pivots; hip drives shin across thigh line while head remains guarded",carry="Low shin arc and short recoil; do not drop into a spinning crouch",next={"cross","hook","frontkick"},tactic="InsideLow",legacy="roundhouse",refs={"roundhouse","sweep"}},
 {id="backkick",name="Back kick",category="Kicks",role="counter",range="long",duration=1.12,contact=.52,follow=.64,lead="opposite",hip={32,92,146,174,179,85},torso={0,-12,-30,-43,-44,-15},legs={{17,5,107},{15,3,119},{-31,2,65},{-78,2,12},{-72,2,26},{-15,4,113}},weight="Guarded check over shoulder; half-turn puts standing heel towards target; heel thrusts behind hips",carry="Linear heel thrust, not circular spin; rechamber, unwind and recover front-facing guard",next={"jab","pursuit","frontkick"},tactic="CheckBack",legacy="sidekick",refs={"backkick","sidekick"}},
 {id="sweep",name="Sweep / ankle reap",category="Kicks",role="sweep",range="close",duration=.88,contact=.48,follow=.64,lead="opposite",hip={-3,9,22,38,48,13},torso={0,0,-3,-6,-9,-2},legs={{32,7,82},{28,22,70},{18,34,48},{3,48,14},{-3,60,19},{26,14,92}},weight="Frame/catch first off-balances opponent; planted leg braces as reaping foot crosses ankle line",carry="Low reap below knee after posture break; replant before pursuit",next={"pursuit","jab"},tactic="OutsideReap",legacy="sweep",refs={"sweep"}},
 {id="risingknee",name="Rising knee",category="Knees",role="pressure",range="close",duration=.77,contact=.45,follow=.58,lead="Left",hip={0,3,7,12,13,3},torso={0,0,0,-3,-3,0},legs={{43,3,134},{68,2,140},{92,2,145},{119,2,145},{116,2,141},{65,3,130}},weight="Standing leg drives upward; knee rises vertically through centre, heel folded towards seat",carry="Hip lifts before knee; upright frame keeps balance; compact vertical return",next={"horizontalelbow","cross","frontkick"},tactic="ShortClinch",legacy="risingknee",refs={"knee"}},
 {id="forwardknee",name="Forward knee",category="Knees",role="pressure",range="close",duration=.82,contact=.46,follow=.60,lead="Left",hip={-1,5,11,20,22,6},torso={0,0,-1,-6,-7,-2},legs={{34,4,130},{56,3,139},{76,3,144},{95,3,146},{90,3,140},{52,4,128}},weight="Standing foot braces; hip advances into folded knee, with guarded upper body rather than isolated leg lift",carry="Forward hip projection; rearward torso counterbalance; retract folded knee before planting",next={"horizontalelbow","hook","frontkick"},tactic="StepIn",legacy="knee",refs={"knee"}},
 {id="horizontalelbow",name="Horizontal elbow",category="Elbows",role="counter",range="close",duration=.66,contact=.43,follow=.57,lead="Left",hip={-3,11,24,36,43,9},torso={0,1,7,18,24,4},arms={{67,6,134},{74,2,143},{86,-17,145},{91,-51,146},{84,-70,146},{65,7,125}},weight="Ball pivot and hip rotation deliver short elbow arc; free hand protects chin/frames opponent",carry="Folded fist stays near shoulder; recover both hands without opening chin",next={"forwardknee","hook","cross"},tactic="ShortCounter",legacy="elbow",refs={"elbow","boxing"}},
}
local phases={"Ready","Anticipation","HipDrive","Acceleration","Contact","FollowThrough","Rechamber","Recovery"}
local function setFacing(p)
 p.head.yaw=math.clamp(-(p.root.yaw+p.torso.yaw),-75,75);p.head.pitch=-2-(p.root.pitch+p.torso.pitch)*.4
end
-- Place pelvis above the actual supporting ankle after rotation. This is
-- a balance trajectory, not moving the planted foot to chase the body.
local function balance(p,support)
 local s=sign(support);local f=p[foot(support)]
 local r=p.root
 -- Centre of the pelvis, not merely the lateral hip joint, is over the
 -- support. IK accommodates the hip offset while the torso counterbalances.
 r.x=.5*s+f.x-s*.08;r.z=f.z-.08
end
function R.strike(def,side,kind,forcedLead)
 local lead=forcedLead or(if def.lead=="striker"then side elseif def.lead=="opposite"then other(side)else def.lead)
 local rear=side~=lead;local turn=-sign(side);local support=other(side);local isLeg=def.legs~=nil
 local ready=R.guard(lead);local poses={M.copy(ready)}
 local times={0,.13,.25,.34,def.contact,def.follow,.82,1}
 for stage=1,6 do
  local p=M.copy(ready);p.root.yaw+=turn*def.hip[stage];p.torso.yaw+=turn*def.torso[stage]
  p.root.y-=if stage==1 then .035 elseif stage==2 then .065 elseif stage==3 then .03 else 0
  if isLeg then
   convert(p,side);local row=def.legs[stage];p[leg(side)]={lift=row[1],out=row[2],knee=row[3],twist=0,ankle=if def.id=="frontkick"or def.id=="sidekick"or def.id=="backkick"then -12 else 6}
   p[foot(support)].yaw=ready[foot(support)].yaw+turn*def.hip[stage];p[foot(support)].toe=if stage==2 or stage==3 then 4 else 0
   p.root.pitch=if def.id=="backkick"then (if stage>=3 and stage<=5 then 24 else 7)elseif def.id=="sidekick"then -3 else -2
   p.root.roll=if def.id=="sidekick"then -sign(side)*(if stage>=3 and stage<=5 then 12 else 4)else -sign(side)*3
   p[hand(support)]=arm(69,8,123);p[hand(side)]=arm(61,10,119)
   if def.id=="roundhouse"or def.id=="lowkick"then p[hand(side)]=arm(if stage>=3 and stage<=5 then 35 else 62,if stage>=3 and stage<=5 then 30 else 10,85)end
   if def.id=="sweep"then p[hand(support)]=arm(86,-10,60);p[hand(side)]=arm(73,4,85)end
   if def.category=="Knees"then p.la=arm(85,5,106);p.ra=arm(85,5,106)end
   -- A Thai shin kick first extends the standing leg as the free shin
   -- leaves the floor, then settles into the rotating strike. Staying in the
   -- deep boxing crouch while straightening that leg would pierce the floor.
   if def.id=="roundhouse"or def.id=="lowkick"then p.root.y=({-.06,-.12,-.22,-.28,-.32,-.45})[stage]end
   balance(p,support)
   if def.id=="frontkick"or def.id=="forwardknee"then p.root.z-=({0,0,.06,.20,.23,.025})[stage]end
  else
   local row=def.arms[stage];p[hand(side)]=arm(row[1],row[2],row[3],if stage>=3 and stage<=5 then 14 else 0)
   p[hand(support)]=arm(67,6,125)
   local loadSide=if def.id=="hook"and not rear then lead else other(lead)
   local destination=if def.id=="hook"and not rear then other(lead)else lead
   p.root.x=sign(if stage<=2 then loadSide else destination)*(if stage==1 then .09 elseif stage<=5 then .12 else .035)
   p.root.z=if stage<=2 then .025 elseif stage<=5 then -.085 else 0
   local pivot=if rear then side elseif def.id=="jab"then other(side)else side
   p[foot(pivot)].yaw=ready[foot(pivot)].yaw+turn*def.hip[stage]
   p[foot(pivot)].toe=if stage>=2 and stage<=5 then (if def.id=="jab"then 4 else 11)else 0
   if def.id=="uppercut"then p.root.y=({-.60,-.64,-.54,-.34,-.35,-.48})[stage];p.torso.pitch=({3,4,0,-7,-6,1})[stage]end
  end
  setFacing(p);table.insert(poses,p)
 end
 table.insert(poses,M.copy(ready))
 if isLeg then for _,p in poses do convert(p,side)end end
 -- Tactical variants change the load/trajectory/brace, rather than uniformly
 -- scaling every joint. Ninja is a restrained presentation adaptation only.
 local duration=def.duration
 if kind==def.tactic then
  if kind=="StepIn"or kind=="LongSpacing"then
   local travel=if kind=="LongSpacing"then .24 else .18
   for i,p in poses do
    if isLeg then
     local dz=if i==1 then 0 else -travel;p[foot(support)].z+=dz;p[foot(support)].y=if i==2 then .065 else 0
     if i>1 and i<8 then balance(p,support)else p.root.z+=dz end
    else
     local dz=-travel*math.min(1,times[i]/.34);p.root.z+=dz;p[foot(lead)].z+=if i==1 then 0 else -travel
     p[foot(lead)].y=if i==2 then .06 else 0
     p[foot(other(lead))].z+=if i>=7 then -travel else 0
    end
   end
   duration+=.08
  elseif kind=="InsideLow"then
   for i=2,7 do local p=poses[i];p.root.yaw=ready.root.yaw+turn*def.hip[i-1]*.58;p[leg(side)].out=-def.legs[i-1][2]*.48;if i>=5 then p[leg(side)].lift+=6 end;p[foot(support)].yaw=ready[foot(support)].yaw+turn*def.hip[i-1]*.58;balance(p,support);setFacing(p)end
  elseif kind=="OutsideReap"then
   for i=2,7 do local p=poses[i];p[leg(side)].out+=12;p[hand(support)]=arm(82,-24,76);p.torso.roll=-sign(side)*4;balance(p,support);setFacing(p)end
  elseif kind=="StopTeep"then
   for i=2,7 do local p=poses[i];p.root.pitch=-6;p[leg(side)].lift+=if i==5 or i==6 then -12 else 0;p[hand(side)]=arm(69,6,123);balance(p,support);setFacing(p)end
  elseif kind=="BodyCounter"then
   for i=2,7 do local p=poses[i];p.root.y-=.10;p[hand(side)].raise-=if i==5 or i==6 then 16 else 0;p[hand(support)].raise=73;setFacing(p)end
  elseif kind=="CheckBack"then
   poses[2].head.yaw=-turn*65;poses[2].root.yaw=ready.root.yaw+turn*48;balance(poses[2],support)
   poses[3][leg(side)].knee=133;poses[3][hand(support)]=arm(75,5,128)
  elseif kind=="ShortClinch"then
   for i=2,7 do local p=poses[i];p[leg(side)].lift-=12;p.la=arm(102,-8,92);p.ra=arm(102,-8,92);p.torso.pitch=4;balance(p,support);setFacing(p)end
  elseif kind=="ShortRange"or kind=="ShortCounter"then
   for i=2,7 do local p=poses[i];p.root.x*=.65;p.root.z*=.5;p.root.yaw=ready.root.yaw+turn*def.hip[i-1]*.8;p.torso.yaw=ready.torso.yaw+turn*def.torso[i-1]*.8
    p[hand(side)].elbow=math.min(148,p[hand(side)].elbow+12);p[hand(support)].raise=74;setFacing(p)
   end
  elseif kind=="QuickReturn"then
   poses[6][leg(side)].knee=53;poses[6][leg(side)].lift=40;poses[6][leg(side)].out=42;poses[6].root.yaw=ready.root.yaw+turn*82;poses[6][foot(support)].yaw=poses[6].root.yaw;balance(poses[6],support)
   times[6]=def.contact+.09;times[7]=.73;duration-=.07
  end
 elseif kind=="Ninja"then
  -- Preserve support foot/chamber. Increase readable striking silhouette,
  -- shoulder participation and carry, never add a purposeless full rotation.
  for _,i in {4,5,6}do local p=poses[i];p.torso.yaw+=turn*3
   if isLeg then p[leg(side)].lift+=if def.id=="lowkick"or def.id=="sweep"then 2 elseif def.id=="backkick"then -5 else 5
   else p[hand(side)].raise+=4;p[hand(side)].elbow=math.max(8,p[hand(side)].elbow-3)end
   setFacing(p)
  end
  duration*=.93
 end
 local plant=nil;local transfer=nil
 if isLeg and kind==def.tactic and(kind=="StepIn"or kind=="LongSpacing")then
  -- Step the future support foot while the striking foot still carries weight.
  local step=poses[2];step.root=M.copy(ready.root);step.root.x=sign(side)*.20
  step[leg(side)]=nil;step[foot(side)]=M.copy(ready[foot(side)]);convert(step,side)
  plant=M.copy(step);plant[foot(support)].y=0;balance(plant,support)
  plant[leg(side)]=nil;plant[foot(side)]=M.copy(ready[foot(side)]);convert(plant,side)
  transfer=M.copy(plant);transfer.root.x=(step.root.x+plant.root.x)*.5;transfer.root.z=(step.root.z+plant.root.z)*.5;transfer[foot(support)].y=step[foot(support)].y*.5
  transfer[leg(side)]=nil;transfer[foot(side)]=M.copy(ready[foot(side)]);convert(transfer,side)
 end
 local keys={};for i,p in poses do table.insert(keys,{at=times[i],phase=phases[i],pose=p,ease=if i==5 then "out"else "smooth"})end
 if plant then table.insert(keys,{at=.165,phase="WeightTransfer",pose=transfer,ease="smooth"});table.insert(keys,{at=.20,phase="PlantSupport",pose=plant,ease="smooth"});table.sort(keys,function(a,b)return a.at<b.at end)end
 local phaseTimes={Ready=0,Anticipation=times[2],Acceleration=times[4],Contact=times[5],FollowThrough=times[6],Recovery=1}
 return {duration=duration,keys=keys,timing={startup=duration*times[5],active=duration*(times[6]-times[5]),recovery=duration*(1-times[6])}},phaseTimes,lead
end
local function publish(lib,id,name,category,family,side,kind,clip,phaseTimes,metadata,legacy)
 -- Report authored joint deltas, including tactical adjustments. Never label
 -- these as experimentally measured human biomechanics.
 local first=clip.keys[1].pose
 metadata.hipRotation={description="Support → pelvis; see editable keys",reference="Authored R15 degrees relative to Ready, not human measurements"}
 metadata.torsoRotation={description="Torso follows pelvis; target-aware guarded head"}
 for _,key in clip.keys do
  if key.phase=="HipDrive"or key.phase=="HipDrive1"then
   metadata.hipRotation.driveDegrees=key.pose.root.yaw-first.root.yaw
   metadata.torsoRotation.driveDegrees=key.pose.torso.yaw-first.torso.yaw
  elseif key.phase=="Contact"or key.phase=="Contact1"then
   metadata.hipRotation.contactDegrees=key.pose.root.yaw-first.root.yaw
   metadata.torsoRotation.contactDegrees=key.pose.torso.yaw-first.torso.yaw
  end
 end
 local sourceId=id.."_source"
 local a={id=sourceId,name=name,grammar=sourceId,category=category,family=family,side=side,variantName=kind,attackingLimb=metadata.attackingLimb,supportLimb=metadata.supportFoot,stance=metadata.leadSide.."Lead",bodyMechanics={"stance","support","weight-transfer","hips","torso","striking-limb","contact","follow-through","recovery"},compatibleTransitions={},independentlyEditable=true,mirrorSource=false,sourceType="reference",referenceBacked=true,hidden=true,tags={"Reference",family,side,kind,metadata.combatRole},compatibleBodyLayers=M.copy(M.Layers),duration=clip.duration,contactMarkers=metadata.contacts or {{at=phaseTimes.Contact,name="contact"}},rootPolicy="presentation",styleTags={kind},authoredClip=clip,combatPhases=phaseTimes,legacyAsset=legacy,metadata=metadata}
 lib.assets[sourceId]=a
 local visible=M.copy(a);visible.id=id;visible.grammar=id;visible.hidden=false;visible.variant=true
 visible.variantDefinition=E.create(id,name,a,clip.duration,phaseTimes.Contact,phaseTimes.FollowThrough)
 visible.variantDefinition.metadata=M.copy(metadata)
 -- Non-boundary source keys remain selectable for hip drive and rechamber,
 -- as do subsequent contacts within complete combination phrases.
 local v=visible.variantDefinition
 for i,k in clip.keys do local exists=false;for _,key in v.poseOverrides do if math.abs(key.time-k.at)<.002 then exists=true end end
  if not exists then table.insert(v.poseOverrides,{id=(k.phase or "Pose").."_"..i,time=k.at,sourceTime=k.at,parts={}})end
 end
 table.sort(v.poseOverrides,function(x,y)return x.time<y.time end)
 lib.assets[id]=visible;table.insert(lib.assetOrder,id);return visible
end
local function meta(def,side,lead,kind)
 local refs={};for _,id in def.refs do table.insert(refs,R.Sources[id])end
 return {combatRole=def.role,range=def.range,leadSide=lead,supportFoot=other(side).."Foot",weightShift=def.weight,
 hipRotation={description="Support pivot drives pelvis",driveDegrees=-sign(side)*def.hip[2],contactDegrees=-sign(side)*def.hip[4],reference="Authored R15 deltas, not measured human angles"},torsoRotation={description="Torso follows hip drive; head tracks target",driveDegrees=-sign(side)*def.torso[2],contactDegrees=-sign(side)*def.torso[4]},
 contactPhase="Contact",followThrough=def.carry,recovery="Rechamber / hand return, settle feet, recover usable guard",validFollowups=M.copy(def.next),
 contactSurface=if def.id=="roundhouse"or def.id=="lowkick"then "shin"elseif def.id=="sidekick"or def.id=="backkick"then "heel"elseif def.id=="sweep"then "ankle/calf reap"elseif def.category=="Knees"then "knee"elseif def.category=="Elbows"then "elbow"elseif def.id=="frontkick"then "ball/sole"else "knuckles",
 attackingLimb=side..(if def.legs then "Leg"else "Arm"),stance=lead.."Lead",references=refs,referenceStatus="Coach-text informed R15 adaptation; not mocap",variantMechanic=kind,
 constraints=if def.id=="sweep"then "Requires caught/off-balanced opponent; preview shows frame and reap only"else "Presentation only; author must validate target contact and rig proportions"}
end
R.Routes={
 {id="jab_cross",name="Jab → Cross",from="jab",to="cross",flow="Lead jab returns as rear ball drives cross; lead brace remains planted"},
 {id="cross_hook",name="Cross → Hook",from="cross",to="hook",flow="Rear cross loads lead brace; lead hook releases that heel and returns weight rearward"},
 {id="jab_lowkick",name="Jab → Low kick",from="jab",to="lowkick",flow="Jab retracts under guard; settle onto lead support before rear shin swings"},
 {id="cross_roundhouse",name="Cross → Roundhouse",from="cross",to="roundhouse",flow="Cross finishes on lead brace; shift back over rear support before lead-leg kick"},
 {id="dodge_cross",name="Dodge left → Cross",from="dodge",to="cross",flow="Guarded lateral knee bend loads rear leg; push into cross without standing upright first"},
 {id="dodge_hook",name="Dodge right → Hook",from="dodge",to="hook",reverse=true,flow="Outside slip stays behind guard; inside foot pressure feeds compact lead hook"},
 {id="sweep_pursuit",name="Sweep → Pursuit",from="sweep",to="pursuit",flow="Reaping foot replants; pelvis settles before alternating chase steps"},
 {id="launcher_aerial",name="Launcher → Aerial follow-up",from="launcher",to="aerial",flow="Uppercut settles into knee load; support push-off precedes airborne strike",gameAdaptation=true},
}
function R.aux(kind,side,lead)
 local d=R.Specs[if kind=="launcher"then 4 else 2];local clip,pt=R.strike(d,side,"Base",lead)
 if kind=="launcher"then
  clip.keys[3].pose.root.y=-.69;clip.keys[5].pose[hand(side)].raise=127
 elseif kind=="dodge"then
  local g=R.guard(lead);for i,k in clip.keys do local p=M.copy(g);local q=({0,.3,.65,1,1,.7,.25,0})[i]
   p.root.x=sign(side)*.21*q;p.root.y-=.22*q;p.root.roll=-sign(side)*8*q;p.torso.roll=sign(side)*4*q;p.head.yaw=-p.root.yaw-p.torso.yaw;k.pose=p
  end;clip.duration=.58
 elseif kind=="pursuit"then
  local g=R.guard(lead);for i,k in clip.keys do local p=M.copy(g);local t=k.at
   p.root.z=-.65*t;p.root.pitch=8
   p[foot(side)].z-=.65*math.min(1,t/.43);p[foot(other(side))].z-=.65*math.clamp((t-.43)/.57,0,1)
   p[foot(side)].y=if i==2 or i==3 then .09 else 0;p[foot(other(side))].y=if i==6 or i==7 then .09 else 0;k.pose=p
  end;clip.duration=.74
 elseif kind=="aerial"then
  -- Ground load -> push-off -> tucked airborne strike -> landing guard.
  for i,k in clip.keys do local p=k.pose;convert(p,"Left");convert(p,"Right")
   if i>=3 and i<=6 then p.root.y=({.12,.65,.95,.72})[i-2];p.ll={lift=30,out=5,knee=73,ankle=-12};p.rl={lift=48,out=5,knee=99,ankle=-12}end
   if i==2 then p.root.y=-.66 end;if i==7 then p.root.y=-.65 end
  end;clip.duration=1.12
 end
 clip.timing={startup=clip.duration*pt.Contact,active=clip.duration*(pt.FollowThrough-pt.Contact),recovery=clip.duration*(1-pt.FollowThrough)}
 return clip,pt
end
local function composite(clips)
 local out={duration=0,keys={}};local contacts={};local offset=0;local previous=nil
 for index,clip in clips do
  local first=if index==1 then 1 else 2;local last=if index==#clips then #clip.keys else 6
  local startTime=clip.keys[first].at;local shifted=M.copy(clip.keys)
  if previous then
   -- Time to transfer between outgoing carry and receiving load.
   -- Grounded punch phrases keep IK; only legs actually lifted use FK.
   offset+=.20
  end
  for i=first,last do local k=shifted[i];local seconds=offset+(k.at-startTime)*clip.duration
   table.insert(out.keys,{at=seconds,pose=k.pose,ease=k.ease,phase=k.phase..index})
   if k.phase=="Contact"then table.insert(contacts,{at=seconds,name="contact"..index})end
  end
  previous=out.keys[#out.keys].pose;offset=out.keys[#out.keys].at
 end
 out.duration=offset;local pt={Ready=0,Anticipation=out.keys[2].at/offset,Acceleration=out.keys[4].at/offset,Contact=contacts[1].at/offset,FollowThrough=0,Recovery=1}
 local free={};for _,k in out.keys do for _,s in {"Left","Right"}do if k.pose[leg(s)]then free[s]=true end end end
 for _,k in out.keys do k.at/=offset;for s in free do convert(k.pose,s)end;if k.phase=="FollowThrough"..#clips then pt.FollowThrough=k.at end end
 for _,c in contacts do c.at/=offset end
 out.timing={startup=offset*pt.Contact,active=offset*(pt.FollowThrough-pt.Contact),recovery=offset*(1-pt.FollowThrough)}
 return out,pt,contacts
end
function R.populate(lib)
 local definitions={};for _,def in R.Specs do definitions[def.id]=def
  for _,kind in {"Base",def.tactic,"Ninja"}do for _,s in {"Left","Right"}do
   local clip,pt,lead=R.strike(def,s,kind);local id="ref_"..def.id.."_"..suffix(s).."_"..kind
   local previous="common_"..def.id.."_"..suffix(s).."_Standard"
   local a=publish(lib,id,def.name.." · "..suffix(s).." · "..kind,def.category,def.name,s,kind,clip,pt,meta(def,s,lead,kind),if lib.assets[previous]then previous else def.legacy)
   a.counterpart="ref_"..def.id.."_"..suffix(other(s)).."_"..kind
  end end
 end
 for _,kind in {"dodge","pursuit","launcher","aerial"}do for _,s in {"Left","Right"}do
  local lead=if kind=="launcher"then "Left"else s;local clip,pt=R.aux(kind,s,lead);local md=meta(definitions.uppercut,s,lead,"Game adaptation")
  md.combatRole=if kind=="dodge"then "counter"elseif kind=="launcher"then "launcher"else "pursuit"
  md.weightShift=if kind=="dodge"then "Knee-supported outside slip with hands protecting chin"elseif kind=="pursuit"then "Replant then alternating guarded forward steps"else "Guarded knee load and support extension; game-directed trajectory"
  md.constraints=if kind=="launcher"or kind=="aerial"then "Game presentation adaptation, not a claim that a real strike launches bodies"else "Solo presentation, no opponent simulation"
  md.supportFoot=if kind=="aerial"then "BothFeet → Airborne → BothFeet"elseif kind=="pursuit"then "AlternatingFeet"else "BothFeet"
  local a=publish(lib,"ref_"..kind.."_"..suffix(s).."_Base",kind.." · "..suffix(s),if kind=="dodge"then "Dodges"elseif kind=="aerial"then "Aerial"elseif kind=="launcher"then "Launchers"else "Transitions",kind,s,"Base",clip,pt,md,if kind=="aerial"then "air1"elseif kind=="pursuit"then "pursue"else kind)
  a.counterpart="ref_"..kind.."_"..suffix(other(s)).."_Base"
 end end
 for _,route in R.Routes do for _,s in {"Left","Right"}do
  local lead=s;local fromSide=if route.from=="cross"or route.from=="sweep"then other(s)elseif route.reverse then other(s)else s
  local toSide=if route.to=="cross"or route.to=="lowkick"then other(s)else s
  local from,fp;if definitions[route.from]then from,fp=R.strike(definitions[route.from],fromSide,"Base",lead)else from,fp=R.aux(route.from,fromSide,lead)end
  local to,tp;if definitions[route.to]then to,tp=R.strike(definitions[route.to],toSide,"Base",lead)else to,tp=R.aux(route.to,toSide,lead)end
  -- Bridge alone exposes the carry → receiving load, without a neutral reset.
  local a,b=M.copy(from.keys[6].pose),M.copy(to.keys[2].pose)
  for _,s in {"Left","Right"}do if a[leg(s)]or b[leg(s)]then convert(a,s);convert(b,s)end end
  local bridge={duration=.20,keys={{at=0,pose=a,phase="Ready",ease="smooth"},{at=1,pose=b,phase="Recovery",ease="smooth"}},timing={startup=.09,active=.03,recovery=.08}}
  local bp={Ready=0,Anticipation=.12,Acceleration=.28,Contact=.45,FollowThrough=.65,Recovery=1}
  local md=meta(definitions[route.from]or definitions.uppercut,fromSide,lead,"Weight bridge");md.combatRole=if route.gameAdaptation then "pursuit"else "pressure";md.weightShift=route.flow;md.validFollowups={route.to};md.transition={from=route.from,to=route.to,receivingSide=toSide,gameAdaptation=route.gameAdaptation or false};md.references={R.Sources.combinations,R.Sources.boxing};md.supportFoot="Transfer: "..other(fromSide).."Foot → "..other(toSide).."Foot";md.followThrough="Retract outgoing limb while transferring pressure";md.recovery="Receiving load for "..route.to
  local name=if route.from=="dodge"then "Dodge "..fromSide:lower().." → "..(if route.to=="cross"then "Cross "else "Hook ")..suffix(toSide)elseif s=="Left"then route.name else route.name.." · opposite stance";local id="ref_bridge_"..route.id.."_"..suffix(s)
  local published=publish(lib,id,name.." · transfer","Transitions",route.name,s,"Bridge",bridge,bp,md,"land");published.counterpart="ref_bridge_"..route.id.."_"..suffix(other(s))
  local phrase,pp,contacts=composite({from,to});local pm=M.copy(md);pm.contacts=contacts;pm.variantMechanic="Connected phrase";pm.followThrough=route.flow;pm.recovery="Final strike recovers guard; no idle reset between strikes"
  local phraseId="ref_phrase_"..route.id.."_"..suffix(s)
  local ph=publish(lib,phraseId,name.." · full route","Transitions",route.name,s,"Phrase",phrase,pp,pm,"jab");ph.counterpart="ref_phrase_"..route.id.."_"..suffix(other(s))
 end end
 for _,s in {"Left","Right"}do
  local jab=R.strike(definitions.jab,s,"Base",s);local cross=R.strike(definitions.cross,other(s),"Base",s);local hook=R.strike(definitions.hook,s,"Base",s)
  local clip,pt,contacts=composite({jab,cross,hook});local md=meta(definitions.jab,s,s,"Connected phrase");md.contacts=contacts;md.weightShift="Lead jab pressure → rear cross drive/front brace → lead hook release/rear load";md.references={R.Sources.boxing,R.Sources.combinations};md.validFollowups={"cross","uppercut"}
  local id="ref_phrase_jab_cross_hook_"..suffix(s);local a=publish(lib,id,"Jab → Cross → Hook · "..suffix(s),"Transitions","Jab → Cross → Hook",s,"Phrase",clip,pt,md,"jab");a.counterpart="ref_phrase_jab_cross_hook_"..suffix(other(s))
 end
 for _,id in lib.assetOrder do local a=lib.assets[id];if a.referenceBacked then lib.assets[a.variantDefinition.sourceAsset].counterpart=a.counterpart end end
end
return R
