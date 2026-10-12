-- Common anatomical vocabulary. Data is materialized into independent clips;
-- no character exceptions, mirroring at playback, physics, or gameplay hooks.
local M=require(script.Parent.Model)
local Solver=require(script.Parent.PoseSolver)
local B={Revision=1}
-- Seven phases: feet/load -> hips -> torso/limb -> contact -> carry -> recoil -> guard.
B.Variants={
 Standard={duration=1,load=1,reach=1,travel=.22,turn=1,guard=0,step=0,contact=.44,follow=.63},
 Compact={duration=.83,load=.55,reach=.8,travel=.08,turn=.65,guard=14,step=0,contact=.39,follow=.57},
 Fast={duration=.75,load=.65,reach=.95,travel=.16,turn=.8,guard=8,step=0,contact=.36,follow=.54},
 Heavy={duration=1.3,load=1.45,reach=1.1,travel=.4,turn=1.25,guard=-8,step=.12,contact=.5,follow=.73},
 Long={duration=1.16,load=1.05,reach=1.2,travel=.65,turn=.95,guard=-5,step=.38,contact=.47,follow=.66},
 Rotational={duration=1.24,load=1.25,reach=1.05,travel=.3,turn=1.55,guard=-14,step=.16,contact=.48,follow=.72},
 Stepping={duration=1.18,load=1,reach=1.05,travel=.8,turn=1.05,guard=4,step=.55,contact=.48,follow=.67},
}
-- Each family has a distinct chamber/contact/carry silhouette, not a common strike pulse.
B.Strikes={
 {id="jab",name="Jab",category="Punches",mode="straight",raise=86,out=-8,elbow=12,hip=14,torso=9,duration=.5,variants={"Standard","Compact","Long"},old="jab"},
 {id="cross",name="Cross",category="Punches",mode="straight",raise=98,out=-14,elbow=8,hip=43,torso=24,duration=.65,variants={"Standard","Heavy","Stepping"},old="cross"},
 {id="hook",name="Hook",category="Punches",mode="hook",raise=83,out=-68,elbow=88,hip=48,torso=36,duration=.7,variants={"Standard","Compact","Rotational"},old="hook"},
 {id="uppercut",name="Uppercut",category="Punches",mode="upper",raise=135,out=-12,elbow=66,hip=30,torso=18,duration=.72,variants={"Standard","Compact","Heavy"},old="uppercut"},
 {id="backfist",name="Backfist",category="Punches",mode="backfist",raise=93,out=65,elbow=18,hip=55,torso=28,duration=.66,variants={"Standard","Fast","Rotational"},old="hook"},
 {id="palm",name="Palm",category="Punches",mode="palm",raise=88,out=-12,elbow=24,hip=23,torso=15,duration=.62,variants={"Standard","Compact","Stepping"},old="palm"},
 {id="frontkick",name="Front kick",category="Kicks",mode="front",lift=87,out=4,knee=12,hip=6,torso=-5,duration=.78,variants={"Standard","Fast","Long"},old="frontkick"},
 {id="sidekick",name="Side kick",category="Kicks",mode="side",lift=48,out=83,knee=8,hip=68,torso=-24,duration=.9,variants={"Standard","Heavy","Long"},old="sidekick"},
 {id="roundhouse",name="Roundhouse",category="Kicks",mode="round",lift=80,out=43,knee=15,hip=78,torso=-34,duration=.88,variants={"Standard","Fast","Rotational"},old="roundhouse"},
 {id="lowkick",name="Low kick",category="Kicks",mode="round",lift=32,out=35,knee=23,hip=52,torso=-19,duration=.7,variants={"Standard","Compact","Heavy"},old="roundhouse"},
 {id="highkick",name="High kick",category="Kicks",mode="round",lift=123,out=28,knee=10,hip=84,torso=-43,duration=1,variants={"Standard","Fast","Long"},old="roundhouse"},
 {id="backkick",name="Back kick",category="Kicks",mode="back",lift=-57,out=8,knee=12,hip=142,torso=-22,duration=.98,variants={"Standard","Compact","Stepping"},old="sidekick"},
 {id="spinningkick",name="Spinning kick",category="Kicks",mode="spin",lift=55,out=78,knee=10,hip=255,torso=-30,duration=1.15,variants={"Standard","Fast","Rotational"},old="spinkick"},
 {id="axekick",name="Axe kick",category="Kicks",mode="axe",lift=64,out=5,knee=8,hip=12,torso=-9,duration=1.08,variants={"Standard","Heavy","Stepping"},old="frontkick"},
 {id="sweep",name="Sweep",category="Kicks",mode="sweep",lift=12,out=83,knee=8,hip=118,torso=-32,duration=1,variants={"Standard","Compact","Rotational"},old="sweep"},
 {id="frontknee",name="Front knee",category="Knees",mode="knee",lift=94,out=6,knee=142,hip=12,torso=9,duration=.72,variants={"Standard","Compact","Stepping"},old="knee"},
 {id="risingknee",name="Rising knee",category="Knees",mode="rising",lift=120,out=9,knee=146,hip=18,torso=-8,duration=.82,variants={"Standard","Fast","Heavy"},old="risingknee"},
 {id="jumpingknee",name="Jumping knee",category="Knees",mode="jumpknee",lift=116,out=12,knee=140,hip=24,torso=12,duration=1.1,variants={"Standard","Long","Stepping"},old="risingknee"},
 {id="horizontalelbow",name="Horizontal elbow",category="Elbows",mode="elbow",raise=92,out=-70,elbow=143,hip=44,torso=28,duration=.66,variants={"Standard","Compact","Stepping"},old="elbow"},
 {id="downwardelbow",name="Downward elbow",category="Elbows",mode="downelbow",raise=70,out=-18,elbow=142,hip=20,torso=12,duration=.8,variants={"Standard","Heavy","Long"},old="elbow"},
 {id="spinningelbow",name="Spinning elbow",category="Elbows",mode="spinelbow",raise=90,out=-65,elbow=145,hip=250,torso=-30,duration=1.02,variants={"Standard","Fast","Rotational"},old="spinelbow"},
}
local function arm(raise,out,elbow,twist)return {raise=raise,out=out,elbow=elbow,twist=twist or 0,wrist=0,wroll=0}end
function B.guard(lead)
 local left=lead=="LeftLead"
 return {root={x=0,y=-.32,z=0,pitch=4,yaw=if left then -12 else 12,roll=0},torso={pitch=2,yaw=if left then 8 else -8,roll=0},head={pitch=-3,yaw=if left then 4 else -4,roll=0},
  la=arm(if left then 63 else 49,12,if left then 103 else 124),ra=arm(if left then 49 else 63,12,if left then 124 else 103),
  lf={x=-.06,y=0,z=if left then -.38 else .38,yaw=if left then -5 else -20,toe=0},rf={x=.06,y=0,z=if left then .38 else -.38,yaw=if left then 20 else 5,toe=0}}
end
local function key(at,pose,ease,phase)return {at=at,pose=pose,ease=ease or "smooth",phase=phase}end
local function footKey(side)return if side=="Left"then "lf"else "rf"end
local function legKey(side)return if side=="Left"then "ll"else "rl"end
local function armKey(side)return if side=="Left"then "la"else "ra"end
local function other(side)return if side=="Left"then "Right"else "Left"end
local function direction(side)return if side=="Left"then -1 else 1 end
local function fk(p,side)
 local f=footKey(side);local l=legKey(side);p[l]=Solver.freeLeg(p,direction(side));p[f]=nil
end
local function rotate(p,sign,hip,torso)
 p.root.yaw+=sign*hip;p.torso.yaw+=sign*torso
 -- Counter-rotate neck to preserve the target, instead of turning head with the pelvis.
 p.head.yaw=math.clamp(-(p.root.yaw+p.torso.yaw),-75,75);p.head.pitch=-(p.root.pitch+p.torso.pitch)*.5
end
function B.strike(def,side,variantName)
 local v=B.Variants[variantName];local sign=direction(side);local a=armKey(side);local guard=armKey(other(side));local f=footKey(side);local support=footKey(other(side));local l=legKey(side)
 local isLeg=def.category=="Kicks"or def.category=="Knees"
 -- Both versions work from the same target-facing lead, so rear-side actions
 -- must load/brace differently from lead-side actions. No mirrored source.
 local lead="LeftLead";local rear=side=="Right";local start=B.guard(lead)
 local load=M.copy(start);local drive=M.copy(start);local contact=M.copy(start);local carry=M.copy(start);local recoil=M.copy(start);local finish=M.copy(start)
 load.root.y-=.09*v.load;load.root.x=sign*(if rear then .12 else .2)*v.load;load.root.z=.1*v.load
 rotate(load,sign,-def.hip*.4*v.load,def.torso*.2)
 load[a].raise=if isLeg then 65 else 38;load[a].elbow=if isLeg then 118 else 138;load[a].out=20+v.load*10
 load[guard].raise=66+v.guard;load[guard].elbow=126
 drive.root.y-=.12*v.load;drive.root.x=-sign*.12;drive.root.z=-v.travel*.45
 rotate(drive,sign,def.hip*.52*v.turn,def.torso*.12)
 drive[support].yaw=start[support].yaw+sign*(def.hip*.42*v.turn);drive[support].toe=if isLeg or rear then 0 else 6;if not isLeg then drive[f].toe=if rear then 12 else 0 end
 drive[a].raise=if isLeg then 72 else 62;drive[a].elbow=120
 contact.root.x=-sign*(if isLeg then .25 else .1);contact.root.z=-v.travel;contact.root.pitch=if isLeg then -5 else 10*v.reach
 rotate(contact,sign,if def.mode=="spin"or def.mode=="spinelbow"then math.min(275,def.hip*v.turn)else def.hip*v.turn,def.torso*v.turn)
 contact[support].yaw=start[support].yaw+sign*math.min(105,def.hip*.65*v.turn);contact[support].toe=if isLeg or rear then 0 else 10;if not isLeg then contact[f].toe=if rear then 19 else 0 end
 contact[guard]=arm(72+v.guard,9,126,-8);contact.head.roll=-sign*3
 -- Stepping/long actions move the lead foot before committing weight. Rear
 -- strikes retain the brace and release the rear heel, lead strikes widen it.
 for _,p in {drive,contact,carry,recoil,finish}do
  p.lf.z-=v.step;p.lf.x-=v.step*.15
  if variantName=="Rotational"then p.rf.x+=.12;p.lf.x-=.08 end
 end
 if not isLeg then
  contact[a]=arm(def.raise*v.reach,def.out,def.elbow,if def.mode=="backfist"then -65 else 18)
  if def.mode=="palm"then contact[a].wrist=-42;contact[a].wroll=-12 end
  if def.mode=="hook"then load[a]=arm(67,66,103,-20);drive[a]=arm(82,18,96,15)end
  if def.mode=="upper"then load.root.y-=.22*v.load;load[a]=arm(10,4,113);drive.root.y=-.43;drive[a]=arm(60,-5,84);contact.root.y=-.12;contact.torso.pitch=-14;contact.head.pitch=5 end
  if def.mode=="backfist"then load[a]=arm(77,-55,123,70);drive[a]=arm(92,-22,78,10);contact[a].wroll=45 end
  if def.mode=="elbow"or def.mode=="spinelbow"then load[a]=arm(85,50,144,-30);drive[a]=arm(90,10,146,20)end
  if def.mode=="downelbow"then load[a]=arm(155,16,140,-12);drive[a]=arm(141,-8,146);contact.root.y=-.57;contact.root.pitch=20;contact.torso.pitch=16;contact.head.pitch=-15 end
 else
  -- Stable IK on support side; continuous FK on kicking side. Initial FK is
  -- converted from the exact guard IK to avoid a mode-switch pose pop.
  for _,p in {start,load,drive,contact,carry,recoil,finish}do fk(p,side)end
  load[l]={lift=if def.mode=="back"then 28 else 42,out=14,knee=119,twist=0,ankle=-12}
  drive[l]={lift=if def.mode=="axe"then 153 elseif def.mode=="back"then 68 else 78,out=if def.mode=="side"or def.mode=="spin"then 52 else 18,knee=if def.mode=="axe"then 16 else 108,twist=10,ankle=-12}
  contact[l]={lift=def.lift*v.reach,out=def.out,knee=def.knee,twist=if def.mode=="round"then 30 elseif def.mode=="side"then 65 else 0,ankle=if def.mode=="front"or def.mode=="back"then -15 else 8}
  contact.root.roll=sign*(if def.mode=="side"then 20 elseif def.mode=="round"then 16 else 5)
  contact[guard]=arm(72,22,122);contact[a]=arm(if def.category=="Knees"then 95 else 44,if def.category=="Knees"then 14 else 45,if def.category=="Knees"then 128 else 82)
  contact.root.y=if def.mode=="sweep"then -.98 elseif def.mode=="rising"then -.1 elseif def.mode=="jumpknee"then .8 else -.27
  if def.mode=="sweep"then load.root.y=-.75;drive.root.y=-.94;contact.torso.pitch=21;contact[a]=arm(60,55,55);contact[guard]=arm(90,10,126)end
  if def.mode=="back"then contact.root.pitch=38;contact.torso.pitch=10;contact.head.yaw=sign*65;contact[support].yaw=contact.root.yaw end
  if def.mode=="jumpknee"then
   -- Takeoff brace -> both legs airborne -> landing brace before recovery.
   fk(drive,other(side));drive[legKey(other(side))]={lift=18,out=6,knee=45,ankle=-20}
   fk(contact,other(side));contact[legKey(other(side))]={lift=-18,out=8,knee=90,ankle=-10};drive.root.y=.32
  end
 end
 -- Variant mechanics alter silhouettes, not just playback speed.
 if variantName=="Compact"then contact.torso.pitch+=5;contact.root.y-=.08;contact[guard].out=-4;load[a].out=5 end
 if variantName=="Heavy"then load.root.pitch=-8;drive.torso.pitch=4;contact.torso.pitch+=9;contact[guard].out=28 end
 if variantName=="Long"then contact.root.pitch+=12;contact[guard].raise-=12;contact[guard].out=25 end
 if variantName=="Rotational"then drive[guard].out=48;contact[guard].out=68;contact[guard].raise=48;load.root.y-=.13 end
 carry=M.copy(contact);carry.root.z-=.08*v.reach;carry.root.yaw+=sign*(if def.mode=="spin"or def.mode=="spinelbow"then 65 else def.hip*.18*v.turn);carry.torso.yaw+=sign*def.torso*.3;carry.head.yaw=math.clamp(-(carry.root.yaw+carry.torso.yaw),-75,75)
 if isLeg then
  carry[l].knee=if def.category=="Knees"then 140 else 32;carry[l].out+=if def.mode=="round"or def.mode=="sweep"then 18 else -4
  carry[l].lift+=if def.mode=="axe"then -46 else -9
  recoil[l]={lift=if def.mode=="sweep"then 22 else 55,out=12,knee=115,twist=0,ankle=-8};recoil.root.x=-sign*.12;recoil.root.z=-v.travel*.7;recoil.root.y=-.43
 else carry[a].out+=if def.mode=="hook"or def.mode=="elbow"then -24 else 10;carry[a].raise+=if def.mode=="upper"then 12 else -8;recoil[a]=arm(63,14,130)end
 -- End after the actual travelled step, rather than snapping root to origin.
 finish.root.z=-v.step;recoil.root.z=-math.max(v.step,v.travel*.65)
 if v.step>0 then if finish.rf then finish.rf.z-=v.step end;if recoil.rf then recoil.rf.z-=v.step*.7 end end
 if isLeg then
  local endIK=B.guard(lead);endIK.root.z=finish.root.z;endIK.lf.z-=v.step;endIK.rf.z-=v.step;fk(endIK,side);finish[l]=endIK[l]
 end
 if def.mode=="spin"or def.mode=="spinelbow"then
  -- Unwrapped yaw through the turn; keep 360 at the end (same orientation).
  recoil.root.yaw=start.root.yaw+sign*340;finish.root.yaw=start.root.yaw+sign*360;recoil.head.yaw=-sign*12
  for _,p in {load,drive,contact,carry,recoil,finish}do
   p[support].yaw=p.root.yaw
   p.head.yaw=if p==finish then start.head.yaw else math.clamp(p.head.yaw,-70,70)
  end
 end
 if def.mode=="jumpknee"then for _,p in {start,load,recoil,finish}do if not p[legKey(other(side))]then fk(p,other(side))end end end
 local times={0,v.contact*.42,v.contact*.78,v.contact,v.follow,.85,1}
 local poses={start,load,drive,contact,carry,recoil,finish};local phases={"Start","Anticipation","HipDrive","Contact","FollowThrough","Rechamber","Recovery"};local keys={}
 for i,p in poses do table.insert(keys,key(times[i],p,if i==4 then "out"else "smooth",phases[i]))end
 return {duration=def.duration*v.duration,keys=keys,timing={startup=def.duration*v.duration*v.contact,active=def.duration*v.duration*(v.follow-v.contact),recovery=def.duration*v.duration*(1-v.follow)}}
end
local function asset(lib,id,name,category,family,side,variant,clip,metadata,legacy)
 local a={id=id,name=name,grammar=id,category=category,family=family,side=side,variantName=variant,attackingLimb=metadata.attackingLimb or "None",supportLimb=metadata.supportLimb or "BothFeet",stance=metadata.stance or "LeftLead",bodyMechanics=metadata.bodyMechanics or {"weight-transfer","target-aware","guard-recovery"},compatibleTransitions={},independentlyEditable=true,mirrorSource=false,sourceType="common-authored",tags={"Common",family,side,variant},compatibleBodyLayers=M.copy(M.Layers),defaultSpeed=1,duration=clip.duration,contactMarkers={{at=clip.timing.startup/clip.duration,name="contact"}},rootPolicy="presentation",styleTags={variant},authoredClip=clip,legacyAsset=legacy,metadata=metadata}
 a.metadata.variant=variant
 lib.assets[id]=a;table.insert(lib.assetOrder,id);return a
end
B.Movement={
 {id="idleneutral",name="Idle neutral",mode="idle",neutral=true,duration=2},
 {id="idlecombat",name="Idle combat",mode="idlecombat",neutral=true,duration=1.8},
 {id="walkforward",name="Walk forward",mode="gait",neutral=true,duration=1.2,travel=.8},
 {id="walkbackward",name="Walk backward",mode="gait",neutral=true,duration=1.35,travel=-.55},
 {id="runforward",name="Run forward",mode="gait",neutral=true,duration=.8,travel=1.8},
 {id="sprint",name="Sprint",mode="gait",neutral=true,duration=.65,travel=2.3},
 {id="strafe",name="Strafe",mode="lateral",duration=1.1,travel=.8},
 {id="lateralrun",name="Lateral run",mode="lateral",duration=.8,travel=1.5},
 {id="diagonal",name="Diagonal step",mode="diagonal",duration=1.15,travel=.85},
 {id="pivot",name="Pivot",mode="pivot",duration=.65},
 {id="stop",name="Stop / brace",mode="stop",duration=.6},
 {id="dodge",name="Short dodge",mode="dodge",duration=.56},
 {id="pursuit",name="Pursuit step",mode="pursuit",duration=.65},
 {id="recovery",name="Recovery step",mode="recovery",duration=.7},
 {id="step",name="Lateral step",mode="step",duration=.6},
 {id="sidecounter",name="Side counter",mode="counter",duration=.78},
 {id="wallexit",name="Wall exit",mode="wall",duration=.95},
 {id="launcher",name="Launcher drive",mode="launcher",duration=.8},
 {id="landing",name="Landing brace",mode="landing",duration=.65},
}
local function movement(def,side)
 local s=direction(side);local lead=if side=="Right"then "RightLead"else "LeftLead";local guard=B.guard(lead);local keys={};local duration=def.duration
 if def.mode=="gait"or def.mode=="lateral"or def.mode=="diagonal"then
  local lateral=def.mode~="gait";local travel=def.travel;local dx=if lateral then s*travel else 0;local dz=if def.mode=="lateral"then 0 else -travel
  local points={{0,0,0},{.125,.5,0},{.25,1,0},{.375,1,.5},{.5,1,1},{.625,1.5,1},{.75,2,1},{.875,2,1.5},{1,2,2}}
  -- Feet remain fixed during stance, then swing with clearance. Root advances
  -- one stride each half-cycle. Backward gait reverses travel, not knee lift.
  for _,q in points do local t,lp,rp=table.unpack(q);if lateral and side=="Right"then lp,rp=rp,lp end;local p=M.copy(guard)
   p.root.x=dx*t;p.root.z=dz*t;p.root.y=-.32-math.cos(t*math.pi*4)*.035
   p.root.pitch=if def.id=="sprint"then 22 elseif def.id=="runforward"then 13 elseif def.id=="walkbackward"then -4 else 5
   p.root.roll=if lateral then -s*math.sin(t*math.pi*2)*5 else math.sin(t*math.pi*2)*3
   p.root.yaw+=math.sin(t*math.pi*2)*(if lateral then 3 else 7);p.torso.yaw=-math.sin(t*math.pi*2)*(if lateral then 6 else 12)
   p.lf.x+=dx*lp*.5;p.rf.x+=dx*rp*.5;p.lf.z+=dz*lp*.5;p.rf.z+=dz*rp*.5
   p.lf.y=if t==.125 or t==.625 then .16 else 0;p.rf.y=if t==.375 or t==.875 then .16 else 0
   if lateral and side=="Right"then p.lf.y,p.rf.y=p.rf.y,p.lf.y end
   if not lateral then p.la=arm(20+math.sin(t*math.pi*2)*28,8,65);p.ra=arm(20-math.sin(t*math.pi*2)*28,8,65)
   else p.la=arm(61+math.sin(t*math.pi*2)*8,12,108);p.ra=arm(64-math.sin(t*math.pi*2)*8,12,117)end
   p.head.yaw=-(p.root.yaw+p.torso.yaw);table.insert(keys,key(t,p,"linear","Gait"))
  end
 elseif def.mode=="idle"or def.mode=="idlecombat"then
  for i=0,4 do local p=M.copy(guard);local t=i/4
   p.root.y+=math.sin(t*math.pi*2)*.02;p.root.x=math.sin(t*math.pi*2)*.03;p.torso.pitch+=math.sin(t*math.pi*2)*1.4;p.head.pitch=-p.torso.pitch
   if def.mode=="idle"then p.la=arm(7,3,16);p.ra=arm(9,3,20);p.root.yaw=0;p.torso.yaw=0;p.head.yaw=0 else p.la.raise+=math.sin(t*math.pi*2)*2;p.ra.elbow+=math.sin(t*math.pi*2)*3 end
   table.insert(keys,key(t,p,"smooth","Breath"))
  end
 else
  local start=M.copy(guard);local load=M.copy(guard);local drive=M.copy(guard);local contact=M.copy(guard);local recovery=M.copy(guard)
  load.root.y-=.1;load.root.x=-s*.12;load.head.yaw=0
  drive.root.x=s*.3;drive.root.y-=.2;drive[footKey(side)].x+=s*.4;drive[footKey(side)].y=.12
  contact.root.x=s*.65;contact[footKey(side)].x+=s*.55;recovery.root.x=s*.65;recovery.lf.x+=s*.65;recovery.rf.x+=s*.65
  if def.mode=="pivot"then
   for i,p in {load,drive,contact,recovery}do p.root.yaw=guard.root.yaw+s*({-8,25,55,55})[i];p.torso.yaw=-s*({0,12,18,8})[i];p.lf.yaw=p.root.yaw;p.rf.yaw=p.root.yaw;p.head.yaw=-(p.root.yaw+p.torso.yaw)end
  elseif def.mode=="stop"then
   start.root.z=-.2;start.root.pitch=15;load.root.z=-.35;drive.root.z=-.42;contact.root.z=-.48;recovery.root.z=-.48
   drive.root.pitch=-10;contact.root.pitch=-5;contact.root.y=-.57;contact[footKey(side)].z-=.55;recovery.lf.z-=.48;recovery.rf.z-=.48
  elseif def.mode=="dodge"or def.mode=="counter"then
   drive.root.roll=-s*15;drive.torso.roll=s*6;drive.root.y=-.75;contact.root.y=-.58;contact.root.x=s*.9;contact.root.roll=-s*7;recovery.root.x=s*.9;recovery.lf.x+=s*.25;recovery.rf.x+=s*.25
   if def.mode=="counter"then contact[armKey(other(side))]=arm(96,-14,12,20);contact.root.yaw+=s*35;contact.torso.yaw+=s*20;contact.head.yaw=-(contact.root.yaw+contact.torso.yaw)end
  elseif def.mode=="pursuit"or def.mode=="recovery"then
   local z=if def.mode=="pursuit"then -1 else .6
   drive.root.z=z*.45;drive.root.pitch=if z<0 then 18 else -6;drive[footKey(side)].z+=z*.65
   contact.root.z=z;contact.lf.z+=z;contact.rf.z+=z*.6;recovery.root.z=z;recovery.lf.z+=z;recovery.rf.z+=z
  elseif def.mode=="wall"then
   start.root.y=.8;start.root.roll=s*42;fk(start,side);start[legKey(side)]={lift=55,out=25,knee=110,ankle=-15}
   load.root.y=1;drive.root.y=1.25;contact.root.y=.65;drive.root.x=s*.8;contact.root.x=s*1.1;recovery.root.x=s*1.1;recovery.lf.x+=s*.45;recovery.rf.x+=s*.45
   for _,p in {load,drive,contact}do fk(p,"Left");fk(p,"Right");p.ll={lift=35,out=15,knee=95,ankle=-10};p.rl={lift=55,out=15,knee=110,ankle=-10}end
  elseif def.mode=="launcher"then
   load.root.y=-.68;load[armKey(side)]=arm(15,8,118);drive.root.y=-.47;drive.root.z=-.2;contact.root.y=.05;contact.root.z=-.35;contact[armKey(side)]=arm(151,-12,42,20);contact.torso.pitch=-14;recovery.root.z=-.35;recovery.lf.z-=.35;recovery.rf.z-=.35
  elseif def.mode=="landing"then
   start.root.y=.55;start.root.pitch=8;load.root.y=-.68;drive.root.y=-.75;contact.root.y=-.52;load.ra=arm(60,42,80);load.la=arm(60,42,80);contact.root.x=s*.2;recovery.root.x=s*.2;recovery.lf.x+=s*.2;recovery.rf.x+=s*.2
  end
  -- Use one representation throughout wall/air intervals; convert planted
  -- endpoints to exact FK before interpolation, not at the first airborne key.
  if def.mode=="wall"then for _,p in {start,recovery}do for _,limb in {"Left","Right"}do if not p[legKey(limb)]then fk(p,limb)end end end end
  keys={key(0,start,"smooth","Start"),key(.18,load,"smooth","Anticipation"),key(.34,drive,"out","HipDrive"),key(.5,contact,"smooth","Contact"),key(1,recovery,"smooth","Recovery")}
 end
 return {duration=duration,keys=keys,timing={startup=duration*.5,active=duration*.2,recovery=duration*.3}}
end
B.Routes={
 {id="jab_cross",name="Jab → cross",from="jab",to="cross"},
 {id="jab_hook",name="Jab → hook",from="jab",to="hook"},
 {id="cross_kick",name="Cross → front kick",from="cross",to="frontkick"},
 {id="punch_knee",name="Punch → knee",from="cross",to="frontknee"},
 {id="kick_punch",name="Kick → punch",from="roundhouse",to="cross"},
 {id="kick_knee",name="Kick → knee",from="frontkick",to="frontknee"},
 {id="sweep_follow",name="Sweep → palm",from="sweep",to="palm"},
 {id="dodge_counter",name="Dodge → counter",from="dodge",to="sidecounter",sameSide=true},
 {id="pivot_strike",name="Pivot → strike",from="pivot",to="cross",sameSide=true},
 {id="launcher_pursue",name="Launcher → aerial pursuit",from="launcher",to="pursuit",sameSide=true,air=true},
 {id="landing_attack",name="Landing → jab",from="landing",to="jab",sameSide=true},
 {id="attack_guard",name="Attack → guard recovery",from="hook",to="recovery",sameSide=true},
}
local function recenter(p)
 local dx=p.root.x or 0;local dz=p.root.z or 0;p.root.x=0;p.root.z=0
 for _,f in {"rf","lf"}do if p[f]then p[f].x=(p[f].x or 0)-dx;p[f].z=(p[f].z or 0)-dz end end
 return p
end
function B.populate(lib)
 for _,def in B.Strikes do for _,variant in def.variants do for _,side in {"Left","Right"}do
  local suffix=if side=="Left"then "L"else "R";local id="common_"..def.id.."_"..suffix.."_"..variant
  local leg=def.category=="Kicks"or def.category=="Knees"
  local a=asset(lib,id,def.name.." · "..suffix.." · "..variant,def.category,def.name,side,variant,B.strike(def,side,variant),{attackingLimb=side..(if leg then "Leg"else "Arm"),supportLimb=other(side).."Foot",stance="LeftLead",bodyMechanics={"load-support","hip-before-torso","shoulder-drive","target-head","active-guard","re-chamber","independent-side"},supportPolicy=if def.mode=="jumpknee"then "brace → airborne → landing"else "planted IK / pivot",centerShift=if leg then "over support foot"else "rear load → front brace",variantMechanic=variant,stanceSwitch=false},def.old)
  a.counterpart="common_"..def.id.."_"..(if side=="Left"then "R"else "L").."_"..variant
 end end end
 for _,def in B.Movement do for _,side in (if def.neutral then {"Neutral"}else {"Left","Right"})do
  local suffix=if side=="Left"then "L"elseif side=="Right"then "R"else "N";local id="common_"..def.id.."_"..suffix.."_Standard"
  local category=if def.mode=="dodge"then "Dodges"elseif def.mode=="counter"then "Counters"elseif def.mode=="wall"then "Wall"elseif def.mode=="launcher"then "Launchers"elseif def.mode=="landing"then "Transitions"else "Locomotion"
  local old=if def.id=="walkforward"or def.id=="walkbackward"then "walk"elseif def.id=="runforward"or def.id=="lateralrun"then "run"elseif def.id=="idleneutral"or def.id=="idlecombat"then "idle"elseif def.id=="pivot"then "turn"elseif def.id=="landing"then "land"elseif def.id=="pursuit"then "pursue"elseif def.id=="wallexit"then "wallentry"else def.id
  local a=asset(lib,id,def.name.." · "..suffix,category,def.name,side,"Standard",movement(def,side),{stance=if side=="Right"then "RightLead"else "LeftLead",supportLimb="AlternatingFeet",bodyMechanics={"stance-swing","target-aware","foot-clearance","counterbalance"},loopDisplacement=def.travel~=nil,stanceSwitch=false},if lib.assets[old]then old else "dash")
  if side~="Neutral"then a.counterpart="common_"..def.id.."_"..(if side=="Left"then "R"else "L").."_Standard"end
 end end
 for _,route in B.Routes do for _,side in {"Left","Right"}do
  local suffix=if side=="Left"then "L"else "R";local targetSide=if route.sameSide then side else other(side);local targetSuffix=if targetSide=="Left"then "L"else "R"
  local from=lib.assets["common_"..route.from.."_"..suffix.."_Standard"];local to=lib.assets["common_"..route.to.."_"..targetSuffix.."_Standard"]
  local start=recenter(M.copy(from.authoredClip.keys[5].pose));local finish=M.copy(to.authoredClip.keys[2].pose);local middle=B.guard(to.stance)
  -- Keep exit mechanics, retract the striking limb, settle weight, then load
  -- the new limb. Changing FK/IK uses exact equivalent poses at both ends.
  middle.root.y=if route.air then .8 elseif route.from=="sweep"then -.6 else -.43;middle.root.z=-.12;finish.root.z-=.12;if finish.lf then finish.lf.z-=.12 end;if finish.rf then finish.rf.z-=.12 end
  if route.air then finish.root.y=.85;for _,p in {middle,finish}do fk(p,"Left");fk(p,"Right");p.ll={lift=48,out=8,knee=90,ankle=-10};p.rl={lift=32,out=8,knee=102,ankle=-10}end end
  for _,limb in {"Left","Right"}do if start[legKey(limb)]or finish[legKey(limb)]then for _,p in {start,middle,finish}do if not p[legKey(limb)]then fk(p,limb)end end end end
  local clip={duration=if route.air then .56 else .38,keys={key(0,start,"smooth","Start"),key(.5,middle,"smooth","WeightTransfer"),key(1,finish,"smooth","Recovery")},timing={startup=.16,active=.08,recovery=if route.air then .32 else .14}}
  local id="common_transition_"..route.id.."_"..suffix
  local a=asset(lib,id,route.name.." · "..suffix,"Transitions",route.name,side,"Bridge",clip,{stance=from.stance,attackingLimb=to.attackingLimb,supportLimb=to.supportLimb,fromAsset=from.id,toAsset=to.id,entryPhase="FollowThrough",exitPhase="Anticipation",entryRoot="recenter outgoing travel",stanceSwitch=from.stance~=to.stance,exitStance=to.stance,bodyMechanics={"re-chamber","transfer-support","continuous-leg-mode","explicit-stance"}},"land")
  a.counterpart="common_transition_"..route.id.."_"..(if side=="Left"then "R"else "L")
  table.insert(from.compatibleTransitions,id);table.insert(to.compatibleTransitions,id)
 end end
end
return B
