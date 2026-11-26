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
 local x,z,y=Motion.swingTwist(cf)
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
-- (DEV review) a composed rotation (a fold that also twists and swings) moves
-- continuously through the limit: no pose jumps from one frame to the next.
test("the limit is continuous on composed rotations (knee and elbow folded, twisted and swung past their stops)",function()
 local function angle(a,b) local _,t=(a:Inverse()*b):ToAxisAngle() return math.abs(t) end
 for _,key in {"RightKnee","LeftElbow","Neck","RightAnkle"} do
  for _,twist in {-50,-25,0,25,50} do
   for _,sway in {-35,0,35} do
    local prev,prevIn
    for a=-175,175,1 do
     local cf=H.C.Angles(math.rad(a),0,0)*H.C.Angles(0,0,math.rad(sway))*H.C.Angles(0,math.rad(twist),0)
     local out=Motion.limit(key,cf)
     if prev then
      local d=math.deg(angle(prev,out))
      assert(d<4.5,string.format("%s jumped %.1f deg at bend %d (twist %d, sway %d)",key,d,a,twist,sway))
     end
     prev=out
    end
   end
  end
 end
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
-- (FILM10) turning on the spot and arriving from a teleport: the feet hold
-- the floor and step; they neither skate round with the body nor step across
-- the arena from where it was.
local function feet(fid,frames,setup)
 local _,a=H.duel(fid,"Mirage")
 local root=a.model.root
 root.CFrame=H.C.new(0,3,0)
 local actor={fighterId=fid,state="Neutral",health=100,attackElapsed=0,reactionElapsed=0,airborne=false,velocity=V.new(0,0,0),speed=0,hitAngle=0,hitStrength=.5,landing=false}
 local glide,planted,last,worst=0,0,{},0
 for i=1,frames do
  local warp=setup(i,actor,root)
  Motion.tick(1/60);Motion.present(a.model,actor,{},1/60)
  local pose={}
  for k,j in a.model.joints do pose[k]=j.Transform end
  for _,side in {"R","L"} do
   local frame=Motion._ankleFrame(pose,side)
   local w=root.CFrame:PointToWorldSpace(frame.Position)
   local h=frame.Position.Y-Motion._ankleY
   local was=last[side]
   if i>5 and not warp and was and h<.05 and was.h<.05 then
    local v=V.new(w.X-was.w.X,0,w.Z-was.w.Z).Magnitude*60
    glide+=v;planted+=1;worst=math.max(worst,v)
   end
   last[side]={w=w,h=h}
  end
 end
 return glide/math.max(planted,1),worst
end
test("a turn on the spot (180 deg in 0.3 s) steps: the planted feet do not skate round with the body",function()
 for _,fid in BETA do
  for _,state in {"Neutral","Guarding"} do
   local mean=feet(fid,60,function(i,a,root) a.state=state;if i>10 and i<=28 then root.CFrame=root.CFrame*H.C.Angles(0,math.pi/18,0) end end)
   assert(mean<1.5,string.format("%s %s: planted feet skated at %.1f studs/s through the turn",fid,state,mean))
  end
 end
end)
test("after a teleport the feet start on the new spot (no step across the arena from the old one)",function()
 for _,fid in BETA do
  local _,worst=feet(fid,40,function(i,a,root) if i==10 then root.CFrame=H.C.new(6,3,-6);return true end return false end)
  assert(worst<12,string.format("%s: a foot crossed %.0f studs/s after the warp",fid,worst))
 end
end)
-- (26/11, the OUTILLEUR's duel robot: the body drawn lying 1.1 to 1.7 stud
-- under the floor after a knockdown) lying, never under the floor
test("a body lying on the floor is lifted out of it at once, and given back gently as it rises",function()
 local dt=1/60
 local F=Motion.FLOOR
 assert(math.abs(Motion.liftStep(0,0,-1.5,dt)-1.5)<1e-6,"not lifted out at once")
 assert(Motion.liftStep(1.5,0,0,dt)==1.5,"a body on the floor moves")
 local back=Motion.liftStep(1.5,0,.5,dt)
 assert(back<1.5 and back>=1.5-F.down*dt-1e-6,"given back too fast or not at all: "..back)
 assert(Motion.liftStep(0,0,.3,dt)==0,"a standing body pushed down")
 assert(Motion.liftStep(0,0,-9,dt)==F.max,"no cap on the lift")
 local CF=require("@lune/roblox").CFrame
 assert(math.abs(Motion.boxLow(CF.new(0,1,0),V.new(2,2,1))-0)<1e-6,"an upright box")
 assert(math.abs(Motion.boxLow(CF.new(0,1,0)*CF.Angles(math.rad(90),0,0),V.new(2,2,1))-.5)<1e-4,"a box on its back")
end)
print("NinjaDuel body range and footwork: "..passed.." PASS")
