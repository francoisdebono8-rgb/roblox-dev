-- FILM10 (Minato vs Gaara), A9 « les pieds qui glissent », DEV part: the
-- ANIMATOR's clips wired into the pose engine. Minato's hop out of a string
-- (Brawler.disengage: Recovery, a blade thrown, 46 studs/s back) plays
-- Flashstep.Disengage on the legs; Gaara turning on the spot plays
-- Sand.Pivot.<R|L><90|180>.
local H=require("./Harness")
local V=H.V
local Motion=H.load("Client/VelmoraMotionEngine")
local Authored=Motion.Authored
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function marks(model) local m=Motion._marks and Motion._marks(model) return m end

test("the hop out of a string plays Flashstep.Disengage on the legs, the throw on the arms",function()
 assert(Authored.has("Flashstep.Disengage"),"no Flashstep.Disengage clip")
 local _,a=H.duel("Flashstep","Sand")
 local root=a.model.root
 root.CFrame=H.C.new(0,3,0)
 local actor={fighterId="Flashstep",state="Recovery",health=100,airborne=false,throwKind="Kunai",throwElapsed=0,throwRelease=.1,
  velocity=V.new(0,0,46),speed=46}
 local sampled=0
 local orig=Authored.sample
 Authored.sample=function(name,t,...) if name=="Flashstep.Disengage" then sampled+=1 end return orig(name,t,...) end
 local clip=Authored.clip("Flashstep.Disengage")
 local worst=0
 for i=1,24 do
  root.CFrame=root.CFrame*H.C.new(0,0,46/60*(if i<10 then 1 else .1))
  actor.throwElapsed+=1/60
  if i>=10 then actor.speed=4;actor.velocity=V.new(0,0,4) end
  Motion.tick(1/60)
  Motion.present(a.model,actor,{},1/60)
  -- once settled (the engine eases onto a clip), the legs are the clip's
  local hip=a.model.joints.RightHip
  local want=orig("Flashstep.Disengage",actor.throwElapsed).RightHip
  if i>=18 and hip and want then
   local _,d=(hip.Transform:Inverse()*want):ToAxisAngle()
   worst=math.max(worst,math.abs(d))
  end
 end
 Authored.sample=orig
 assert(sampled>=20,"the disengage clip was not played ("..sampled.." frames)")
 assert(worst<math.rad(20),"the right hip is not on the disengage clip ("..math.floor(math.deg(worst)).." deg off)")
 assert(clip.length>.3)
end)

test("a standing Gaara turning more than 60 degrees steps round (Sand.Pivot)",function()
 for _,turn in {{deg=-90,clip="Sand.Pivot.R90"},{deg=170,clip="Sand.Pivot.L180"}} do
  assert(Authored.has(turn.clip),"no "..turn.clip)
  local _,a=H.duel("Sand","Flashstep")
  local root=a.model.root
  root.CFrame=H.C.new(0,3,0)
  local actor={fighterId="Sand",state="Neutral",health=100,airborne=false,velocity=V.zero,speed=0}
  for i=1,5 do Motion.tick(1/60);Motion.present(a.model,actor,{},1/60) end
  root.CFrame=H.C.new(0,3,0)*H.C.Angles(0,math.rad(turn.deg),0)
  local modes={}
  for i=1,8 do Motion.tick(1/60);modes[Motion.present(a.model,actor,{},1/60)]=true end
  assert(modes.pivot,"a "..turn.deg.." degree turn on the spot did not step ("..turn.clip..")")
  -- a small turn does not
  local _,b=H.duel("Sand","Flashstep")
  local r2=b.model.root;r2.CFrame=H.C.new(0,3,0)
  for i=1,5 do Motion.tick(1/60);Motion.present(b.model,actor,{},1/60) end
  r2.CFrame=H.C.new(0,3,0)*H.C.Angles(0,math.rad(30),0)
  local small={}
  for i=1,8 do Motion.tick(1/60);small[Motion.present(b.model,actor,{},1/60)]=true end
  assert(not small.pivot,"a 30 degree turn stepped round")
 end
end)

-- (14/11, A9 « still ») How far the feet travel along the floor: a foot's
-- horizontal motion while it is within .12 stud of the lowest the feet go in
-- that run (on both frames). A planted foot adds nothing; a step only its
-- first and last few centimetres.
local function slide(fighter,state,seconds,move,setup)
 local _,a=H.duel(fighter,"Flashstep")
 local root=a.model.root
 root.CFrame=H.C.new(0,3,0)
 local actor={fighterId=fighter,state=state,health=100,airborne=false,velocity=V.zero,speed=0}
 if setup then setup(actor) end
 local function ankles()
  local p={}
  for name,j in a.model.joints do p[name]=j.Transform end
  return {root.CFrame*Motion._ankleFrame(p,"R").Position,root.CFrame*Motion._ankleFrame(p,"L").Position}
 end
 for i=1,30 do Motion.tick(1/60);Motion.present(a.model,actor,{},1/60) end
 local frames={ankles()}
 for i=1,math.floor(seconds*60) do
  move(actor,root,i/60)
  Motion.tick(1/60);Motion.present(a.model,actor,{},1/60)
  table.insert(frames,ankles())
 end
 local floor=math.huge
 for _,f in frames do floor=math.min(floor,f[1].Y,f[2].Y) end
 local total=0
 for i=2,#frames do for k=1,2 do
  local p,q=frames[i-1][k],frames[i][k]
  if p.Y-floor<.12 and q.Y-floor<.12 then total+=V.new(q.X-p.X,0,q.Z-p.Z).Magnitude end
 end end
 return total
end
local circling=function(_,r,t) r.CFrame=H.C.new(r.Position)*H.C.Angles(0,math.rad(20*t),0) end

test("a standing body keeps its feet: facing a foe who circles, nudged, drifting, guard on and off",function()
 -- Measured 14/11 for Gaara and Minato (the FILM10 pair), these five runs
 -- (50 s each): 7.3 and 5.7 studs along the floor before (a turn's or a
 -- nudge's step slid in at its start and out along its tail), 2.1 and 1.0
 -- after. Lee 5.4 -> 0.6, Sasuke 5.5 -> 1.0.
 local total=0
 for _,F in {"Sand","Flashstep"} do
  local n=0
  total+=slide(F,"Neutral",10,circling)
  total+=slide(F,"Guarding",10,circling)
  total+=slide(F,"Neutral",10,function(_,r) n+=1;if n%30==0 then r.CFrame=r.CFrame+V.new(if n%60==0 then .25 else -.2,0,if n%90==0 then .2 else -.1) end end)
  total+=slide(F,"Neutral",10,function(_,r) r.CFrame=r.CFrame+V.new(.8/60,0,0) end,function(a) a.speed=.8;a.velocity=V.new(.8,0,0) end)
  total+=slide(F,"Neutral",10,function(a,_,t) a.state=if math.floor(t*2)%2==0 then "Guarding" else "Neutral" end)
 end
 assert(total<6,string.format("standing feet slid %.2f studs along the floor (13.6 before the fix)",total))
end)

test("walking, strafing, stop and go: the steps lift before they travel",function()
 -- 14/11, Gaara and Minato, six 6-8 s runs each: 49.7 -> 38.7 studs.
 local total=0
 for _,F in {"Sand","Flashstep"} do
  for _,sp in {3,6,12,20} do
   total+=slide(F,"Neutral",6,function(_,r) r.CFrame=r.CFrame*H.C.new(0,0,-sp/60) end,function(a) a.speed=sp;a.velocity=V.new(0,0,-sp) end)
  end
  total+=slide(F,"Neutral",6,function(_,r) r.CFrame=r.CFrame+V.new(8/60,0,0) end,function(a) a.speed=8;a.velocity=V.new(8,0,0) end)
  total+=slide(F,"Neutral",8,function(a,r,t) local on=math.floor(t*2)%2==0 a.speed=if on then 6 else 0;a.velocity=if on then V.new(0,0,-6) else V.zero;if on then r.CFrame=r.CFrame*H.C.new(0,0,-6/60) end end)
 end
 assert(total<44,string.format("moving feet slid %.2f studs along the floor (49.7 before the fix)",total))
end)

print(string.format("NinjaDuel FILM10 feet (A9): %d PASS",passed))
