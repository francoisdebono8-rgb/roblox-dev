-- Body and physics, QA combats 14/11 (A8, A9). A8: no drawn joint leaves a
-- body's range (head 80 deg, elbow and knee one way, ankle 50 deg). A9: a
-- guard carried by the body steps; its planted feet do not ride it.
local H=require("./Harness")
local V=H.V
local Motion=H.load("Client/VelmoraMotionEngine")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local BETA={"Lion","Legion","Sand","Leaf","GentleFist","Mirage","Copycat","Flashstep"}
local EPS=math.rad(.5)
local function inside(key,cf)
 local l=Motion.LIMITS[key]
 local x,y,z=cf:ToEulerAnglesXYZ()
 return x>=l.x[1]-EPS and x<=l.x[2]+EPS and y>=l.y[1]-EPS and y<=l.y[2]+EPS and z>=l.z[1]-EPS and z<=l.z[2]+EPS,
  string.format("%s x=%.0f y=%.0f z=%.0f",key,math.deg(x),math.deg(y),math.deg(z))
end
test("the limit folds an impossible joint back into the body's range",function()
 local bad={Neck=H.C.Angles(0,math.rad(119),0),RightElbow=H.C.Angles(math.rad(-40),0,0),LeftKnee=H.C.Angles(math.rad(69),0,0),RightAnkle=H.C.Angles(math.rad(160),0,0)}
 for key,cf in bad do local ok,msg=inside(key,Motion.limit(key,cf));assert(ok,msg) end
 -- a joint inside its range is untouched
 local fine=H.C.Angles(math.rad(-40),0,0)
 assert(Motion.limit("LeftKnee",fine)==fine,"a bent knee was changed")
end)
-- Every fighter through a run, a guard pushed back, a hit, a dodge and his strikes.
test("no drawn elbow, knee, ankle or neck leaves the body's range (8 fighters, run, guard, hits, dodge, strikes)",function()
 local states={{state="Neutral",v=19},{state="Guarding",v=8},{state="Recovery",v=6,reaction="Hit"},{state="Stunned",v=10,reaction="Knockback"},{state="Dodging",v=30},
  {state="Startup",v=6,attackName="Light1"},{state="Active",v=6,attackName="Heavy"},{state="Startup",v=20,attackName="DashAttack"}}
 for _,fid in BETA do
  for _,c in states do
   local _,a=H.duel(fid,"Mirage")
   local root=a.model.root
   root.CFrame=H.C.new(0,3,0)
   local actor={fighterId=fid,state=c.state,health=100,attackElapsed=0,reactionElapsed=0,airborne=false,reaction=c.reaction,attackName=c.attackName,
    velocity=V.new(0,0,-c.v),speed=c.v,hitAngle=0,hitStrength=.5,landing=false}
   for i=1,40 do
    root.CFrame=root.CFrame*H.C.new(0,0,-c.v/60)
    actor.attackElapsed+=1/60;actor.reactionElapsed+=1/60
    Motion.tick(1/60);Motion.present(a.model,actor,{attackElapsed=actor.attackElapsed,reactionElapsed=actor.reactionElapsed},1/60)
    for key in Motion.LIMITS do
     local j=a.model.joints[key]
     if j then local ok,msg=inside(key,j.Transform);assert(ok,fid.." "..c.state..": "..msg) end
    end
   end
  end
 end
end)
test("a guard carried at 10 studs/s steps: its planted feet hold the floor (they rode the body at 100 %)",function()
 for _,fid in BETA do
  local _,a=H.duel(fid,"Mirage")
  local root=a.model.root
  root.CFrame=H.C.new(0,3,0)
  local speed=10
  local actor={fighterId=fid,state="Guarding",health=100,attackElapsed=0,reactionElapsed=0,airborne=false,
   velocity=V.new(0,0,-speed),speed=speed,hitAngle=0,hitStrength=.5,landing=false}
  local glide,planted,last=0,0,{}
  for i=1,90 do
   root.CFrame=root.CFrame*H.C.new(0,0,-speed/60)
   Motion.tick(1/60);Motion.present(a.model,actor,{},1/60)
   local pose={}
   for k,j in a.model.joints do pose[k]=j.Transform end
   for _,side in {"R","L"} do
    local frame=Motion._ankleFrame(pose,side)
    local w=root.CFrame:PointToWorldSpace(frame.Position)
    local h=frame.Position.Y-Motion._ankleY
    local was=last[side]
    if i>20 and was and h<.12 and was.h<.12 then glide+=V.new(w.X-was.w.X,0,w.Z-was.w.Z).Magnitude*60;planted+=1 end
    last[side]={w=w,h=h}
   end
  end
  local share=glide/math.max(planted,1)/speed
  assert(share<.35,string.format("%s: a planted foot rode the guard at %.0f %% of its speed",fid,share*100))
 end
end)
print("NinjaDuel body range and footwork: "..passed.." PASS")
