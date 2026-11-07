-- Locomotion on the floor (audit anim 07/11, lot 1). A planted foot holds the
-- ground: the run is not a body gliding over the arena. Measured on the drawn
-- legs (the Motor6D transforms after Motion.present), for the eight beta
-- fighters, at the run (19 studs/s) and the sprint (45).
local H=require("./Harness")
local V=H.V
local Motion=H.load("Client/VelmoraMotionEngine")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function deg(a,b) local _,ang=(a:Inverse()*b):ToAxisAngle() return math.deg(math.abs(ang)) end
local BETA={"Lion","Legion","Sand","Leaf","GentleFist","Mirage","Copycat","Flashstep"}
-- Run one fighter straight ahead for 2.5 s: the planted ankle's world speed
-- (as a share of the body's) and the share of leg frames at the joint cap.
local function run(fid,speed)
 local _,a=H.duel(fid,"Mirage")
 local root=a.model.root
 root.CFrame=H.C.new(0,3,0)
 local dt=1/60
 local actor={fighterId=fid,state="Neutral",health=100,attackElapsed=0,reactionElapsed=0,airborne=false,
  velocity=V.new(0,0,-speed),speed=speed,hitAngle=0,hitStrength=.5,landing=false}
 local prev,capped,legFrames={},0,0
 local glide,planted=0,0
 local last={}
 for i=1,150 do
  root.CFrame=root.CFrame*H.C.new(0,0,-speed*dt)
  Motion.tick(dt);Motion.present(a.model,actor,{},dt)
  local pose={}
  for k,j in a.model.joints do pose[k]=j.Transform end
  for _,j in {"RightKnee","LeftKnee","RightHip","LeftHip"} do
   local t=pose[j]
   if i>30 and prev[j] then legFrames+=1;if deg(prev[j],t)>=2200*dt*.97 then capped+=1 end end
   prev[j]=t
  end
  for _,side in {"R","L"} do
   local frame=Motion._ankleFrame(pose,side)
   local w=root.CFrame:PointToWorldSpace(frame.Position)
   local h=frame.Position.Y-Motion._ankleY
   local was=last[side]
   if i>30 and was and h<.2 and was.h<.2 then
    glide+=V.new(w.X-was.w.X,0,w.Z-was.w.Z).Magnitude/dt;planted+=1
   end
   last[side]={w=w,h=h}
  end
 end
 return glide/math.max(planted,1)/speed,capped/math.max(legFrames,1),planted
end
test("the run's planted foot holds the floor (it slid at ~46 % of the body's speed, Gaara 64 %)",function()
 local sum=0
 for _,fid in BETA do
  local ratio,_,planted=run(fid,19)
  assert(planted>20,fid..": the feet never touched the floor in a run ("..planted..")")
  assert(ratio<.38,string.format("%s: a planted foot slid at %.0f %% of the run's speed",fid,ratio*100))
  sum+=ratio
 end
 assert(sum/#BETA<.18,string.format("the run's planted feet slide at %.0f %% of the speed on average",sum/#BETA*100))
end)
test("the sprint's planted foot glides at most about a third of the body's speed (it was ~45 %)",function()
 for _,fid in BETA do
  local ratio,capped=run(fid,45)
  assert(ratio<.36,string.format("%s: a sprint stance foot glided at %.0f %% of the speed",fid,ratio*100))
  -- The legs are not played so fast that they live at the joint speed cap.
  assert(capped<.2,string.format("%s: %.0f %% of the sprint's leg frames at the joint cap",fid,capped*100))
 end
end)
test("a cycle is driven by the ground its foot really covers, not the capture's travel",function()
 local A=H.load("Client/AuthoredMotion")
 local ran=0
 for _,fid in BETA do
  for _,clip in {".Run.F",".Sprint",".Walk.F"} do
   local name=fid..clip
   if A.has(name) then
    ran+=1
    local contact=Motion._contactStrideOf(name)
    assert(contact>1 and contact<=A.clip(name).meta.stride*1.2,name..": contact stride "..tostring(contact))
   end
  end
 end
 assert(ran>=20,"few cycles measured ("..ran..")")
end)
print(string.format("NinjaDuel locomotion: %d PASS (headless; the look is a Studio check)",passed))
