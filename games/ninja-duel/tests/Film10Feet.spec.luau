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

print(string.format("NinjaDuel FILM10 feet (A9): %d PASS",passed))
