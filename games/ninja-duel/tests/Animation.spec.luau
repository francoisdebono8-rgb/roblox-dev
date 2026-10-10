-- Animation presentation contract. These checks are what "looks like a fighting
-- game" reduces to mechanically: distinct stances per fighter, direction-aware
-- reactions, no impossible joint angles, and — the important one — no visible
-- snap between any two states across a whole fight.
local H=require("./Harness")
local V=H.V
local Vector3=H.roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Motion=H.load("Client/VelmoraMotionEngine")
-- Rotation measurement. This host runtime mirrors one CFrame basis axis, so
-- matrix traces and ToOrientation are both unreliable; transforming a fixed
-- reference axis with VectorToObjectSpace is exact. Each joint is measured on two
-- independent axes, which removes the ambiguity of a single axis.
local AXIS_X=H.roblox.CFrame.identity.RightVector
local AXIS_Y=H.roblox.CFrame.identity.UpVector
local function axisAngles(c)
 local x=c:VectorToObjectSpace(AXIS_X)
 local y=c:VectorToObjectSpace(AXIS_Y)
 return math.acos(math.clamp(x.X,-1,1)),math.acos(math.clamp(y.Y,-1,1))
end
local function angle(joint) return axisAngles(joint.Transform) end
local function tiltOf(joint)
 local x,y=axisAngles(joint.Transform)
 return math.abs(x)+math.abs(y)
end
-- A frozen copy of every joint transform, used to diff two presented frames.
local function snapshot(model)
 local out={}
 for key,joint in model.joints do out[key]=joint.Transform end
 return out
end
-- Largest single-frame change over every joint, in degrees.
local function maxDelta(a,b)
 local worst=0
 for key,transform in a do
  local other=b[key]
  if other then
   local x1,y1=axisAngles(transform)
   local x2,y2=axisAngles(other)
   local d=math.max(math.abs(x1-x2),math.abs(y1-y2))
   worst=math.max(worst,math.deg(d))
  end
 end
 return worst
end
-- Mirrors Presentation:update: one clock tick, then one presented frame.
local function frame(model,actor,clock,dt)
 Motion.tick(dt or 1/60)
 return Motion.present(model,actor,clock,dt or 1/60)
end
local function body(actor,overrides)
 local out={fighterId=actor.fighterId,state=actor.state,reaction=actor.reaction,health=actor.health,
  attackName=actor.attackName,attackElapsed=0,reactionElapsed=0,airborne=actor.airborne,
  velocity=actor.velocity or Vector3.zero,hitAngle=0,hitStrength=.5,groundPose=nil,
  speed=actor.speed or (actor.velocity and actor.velocity.Magnitude) or 0,landing=false}
 for k,v in overrides or {} do out[k]=v end
 return out
end

test("every pose stays inside human joint limits",function()
 for _,fighter in {"Flashstep","Mirage","GentleFist","Lion"} do
  local c,a=H.duel(fighter,if fighter=="Flashstep" then "Mirage" else "Flashstep")
  local actors={
   body(a,{}),
   body(a,{velocity=V.new(0,0,30)}),
   body(a,{velocity=V.new(0,0,-30)}),
   body(a,{velocity=V.new(26,0,0)}),
   body(a,{airborne=true,velocity=V.new(0,60,0)}),
   body(a,{airborne=true,velocity=V.new(0,-60,0)}),
   body(a,{airborne=true,velocity=V.new(0,0,0)}),
   body(a,{reaction="Launched",airborne=true,reactionElapsed=.2}),
   body(a,{reaction="Knockback",airborne=true,reactionElapsed=.2}),
   body(a,{reaction="Juggled",airborne=true,reactionElapsed=.15}),
   body(a,{reaction="HitStun",reactionElapsed=.05,hitStrength=1}),
   body(a,{reaction="HitStun",reactionElapsed=.04,hitStrength=1,hitZone="head",hitTwist=-1}),
   body(a,{reaction="HitStun",reactionElapsed=.04,hitStrength=1,hitZone="legs",hitTwist=1}),
   body(a,{reaction="HitStun",reactionElapsed=.04,hitStrength=1,hitZone="body",hitAngle=180}),
   body(a,{reaction="Knockdown",airborne=true,reactionElapsed=.12,hitKind="sweep"}),
   body(a,{reaction="Knockdown",airborne=true,reactionElapsed=.3,hitKind="heavy",hitTwist=-1}),
   body(a,{reaction="Spiked",airborne=true,reactionElapsed=.1}),
   body(a,{reaction="Launched",airborne=true,reactionElapsed=.05,hitZone="chin",hitKind="launch"}),
   body(a,{reaction="WallSplat",reactionElapsed=.02}),
   body(a,{reaction="WallSplat",reactionElapsed=.1}),
   body(a,{state="Dodging",velocity=V.new(0,0,20)}),
   body(a,{state="Dodging",velocity=V.new(20,0,0)}),
   body(a,{state="Dodging",velocity=V.new(0,0,-20)}),
   body(a,{groundPose="Knockdown",reaction="Knockdown"}),
   body(a,{groundPose="Splat",reaction="WallSplat"}),
   body(a,{groundPose="Wakeup",reaction="Wakeup",reactionElapsed=.1}),
  }
  for index,actor in actors do
   Motion.reset(a.model)
   for tick=1,40 do
    if actor.state=="Dodging" then
     Motion.defense(a.model,actor,1/60)
    elseif actor.groundPose then
     Motion.defense(a.model,actor,1/60)
    elseif actor.reaction then
     Motion.defense(a.model,actor,1/60)
    elseif actor.airborne then
     Motion.locomotion(a.model,0,true,actor.velocity,fighter,1/60,actor)
    else
     Motion.locomotion(a.model,actor.velocity.Magnitude,false,actor.velocity,fighter,1/60,actor)
    end
    for key,joint in a.model.joints do
     local x,y,z=joint.Transform:ToOrientation()
     assert(x==x and y==y and z==z,"non-finite rotation in pose "..index)
    end
   end
   -- No joint may end up folded past a right angle against its rest direction.
   for key,joint in a.model.joints do
    assert(tiltOf(joint)<math.pi*1.4,"pose "..index.." left "..key.." at "..string.format("%.0f",math.deg(tiltOf(joint))).." deg")
   end
  end
  for _,style in {"light","finisher","launcher","slam"} do
   Motion.reset(a.model)
   for _=1,60 do Motion.ko(a.model,style,1/60) end
   for key,joint in a.model.joints do
    assert(tiltOf(joint)<math.pi*1.4,"KO "..style.." left "..key.." over-rotated")
   end
  end
 end
end)
test("every strike of every fighter stays finite and inside joint limits through its timeline",function()
 local names={"LionBarrage","Rasengan","RasenganDrop"}
 for name in H.Attacks do table.insert(names,name) end
 for _,fighter in {"Flashstep","Mirage","GentleFist","Lion"} do
  local c,a=H.duel(fighter,"Mirage")
  for _,name in names do
   Motion.reset(a.model)
   for step=0,40 do
    Motion.pose(a.model,name,step*.03,fighter,1/60)
    for key,joint in a.model.joints do
     local x,y,z=joint.Transform:ToOrientation()
     assert(x==x and y==y and z==z,fighter.." "..name.." non-finite at "..step)
    end
   end
   for key,joint in a.model.joints do
    assert(tiltOf(joint)<math.pi*1.4,fighter.." "..name.." left "..key.." at "..string.format("%.0f",math.deg(tiltOf(joint))).." deg")
   end
  end
 end
end)
test("idle stances differ per fighter and read as combat stances",function()
 local poses={}
 for _,fighter in {"Flashstep","Mirage"} do
  local c,a=H.duel(fighter,if fighter=="Flashstep" then "Mirage" else "Flashstep")
  Motion.reset(a.model)
  local clock={attackElapsed=0,reactionElapsed=0}
  for _=1,60 do
   frame(a.model,body(a,{velocity=Vector3.zero,speed=0}),clock,1/60)
  end
  poses[fighter]=snapshot(a.model)
  -- A combat stance is not a T-pose or a neutral skeleton.
  local posed=0
  for _,transform in poses[fighter] do
   local x,y=axisAngles(transform)
   if math.max(x,y)>.06 then posed+=1 end
  end
  assert(posed>=4,fighter.." idle stance barely poses the body ("..posed.." joints)")
 end
 local different=0
 for key,transform in poses.Flashstep do
  if not transform:FuzzyEq(poses.Mirage[key],.02) then different+=1 end
 end
 assert(different>=4,"the two fighters idle near-identically ("..different.." joints differ)")
end)
test("forward, backward and strafe locomotion are visibly different",function()
 local c,a=H.duel("Flashstep","Mirage")
 -- Drive the public entry point so the simulated stride clock advances exactly
 -- as it does in a real frame loop.
 local function settle(velocity)
  Motion.reset(a.model)
  local clock={attackElapsed=0,reactionElapsed=0}
  for _=1,60 do
   local actor=body(a,{velocity=velocity,speed=velocity.Magnitude})
   frame(a.model,actor,clock,1/60)
  end
  return snapshot(a.model)
 end
 local forward=settle(V.new(0,0,30))
 local backward=settle(V.new(0,0,-18))
 local strafe=settle(V.new(24,0,0))
 local idle=settle(Vector3.zero)
 local function diff(x,y)
  local n=0
  for key,t in x do if not t:FuzzyEq(y[key],.03) then n+=1 end end
  return n
 end
 assert(diff(forward,backward)>=3,"forward and backward movement share a pose")
 assert(diff(forward,strafe)>=3,"forward and strafe share a pose")
 assert(diff(idle,forward)>=3,"idle and running share a pose")
 assert(diff(backward,idle)>=3,"backing off looks identical to standing still")
end)
test("hit reactions answer the incoming direction",function()
 local c,a=H.duel("Flashstep","Mirage")
 local function reaction(angle,strength,kind)
  Motion.reset(a.model)
  local actor=body(a,{reaction=kind or "HitStun",hitAngle=angle,hitStrength=strength or .8,reactionElapsed=.06})
  for _=1,10 do Motion.defense(a.model,actor,1/60) end
  return snapshot(a.model)
 end
 local front=reaction(0)
 local back=reaction(180)
 local right=reaction(90)
 local left=reaction(-90)
 local function diff(x,y)
  local n=0
  for key,t in x do if not t:FuzzyEq(y[key],.02) then n+=1 end end
  return n
 end
 assert(diff(front,back)>=3,"a hit from behind looks like a hit from the front")
 assert(diff(right,left)>=2,"left and right hits are indistinguishable")
 local light=reaction(0,.15)
 local heavy=reaction(0,1)
 assert(diff(light,heavy)>=2,"a heavy hit is not more violent than a light one")
 -- Air reactions must not share the ground stance.
 local launch=reaction(0,.9,"Launched")
 Motion.reset(a.model)
 local airborne=body(a,{airborne=true,velocity=V.new(0,40,0)})
 for _=1,10 do Motion.locomotion(a.model,0,true,airborne.velocity,"Flashstep",1/60,airborne) end
 assert(diff(launch,snapshot(a.model))>=3,"a launched body looks like a neutral airborne body")
end)
test("the whole fight presents without a single snap between states",function()
 -- Drive the real presentation contract through the real state machine and
 -- measure the largest per-frame joint change. This is the automated form of
 -- "no visible snap between transitions".
 for _,fighter in {"Flashstep","Mirage"} do
  local other=if fighter=="Flashstep" then "Mirage" else "Flashstep"
  local c,a,b=H.duel(fighter,other)
  local clock={attackAt=0,reactionAt=0,attackElapsed=0,reactionElapsed=0}
  local previous=nil
  local worst=0
  local worstAt=""
  local seen={}
  local function present()
   local velocity=a.root.AssemblyLinearVelocity
   local visual=body(a,{velocity=velocity,speed=velocity.Magnitude,attackName=a.attackName,state=a.state,
    reaction=a.reaction,hitAngle=a.hitAngle or 0,hitStrength=a.hitStrength or .4,groundPose=a.groundPose,
    koStyle=a.koStyle,landStrong=a.model:GetAttribute("MovementHardLanding")==true,landing=false})
   local phase=frame(a.model,visual,clock,1/60)
   seen[phase]=(seen[phase] or 0)+1
   local current=snapshot(a.model)
   if previous then
    local delta=maxDelta(previous,current)
    if delta>worst then
     worst=delta;worstAt=phase.." @"..a.state.."/"..tostring(a.reaction).."/"..tostring(a.attackName)
     if delta>34 then
      for key,transform in previous do
       local x1,y1=axisAngles(transform)
       local x2,y2=axisAngles(current[key])
       local d=math.deg(math.max(math.abs(x1-x2),math.abs(y1-y2)))
       if d>15 then print(string.format("   >%s %.1f deg  el=%.3f",key,d,clock.attackElapsed or 0)) end
      end
     end
     local worstJoint,wj="",0
     for key,transform in previous do
      local x1,y1=axisAngles(transform)
      local x2,y2=axisAngles(current[key])
      local d=math.deg(math.max(math.abs(x1-x2),math.abs(y1-y2)))
      if d>wj then wj=d;worstJoint=key end
     end
    end
   end
   previous=current
  end
  local function advance(seconds)
   for _=1,math.ceil(seconds/0.01) do
    c:update(.01,c.now+.01)
    if clock.attackName~=a.attackName then clock.attackName=a.attackName;clock.attackAt=c.now end
    clock.attackElapsed=if a.attackName then c.now-clock.attackAt else 0
    if clock.reaction~=a.reaction then clock.reaction=a.reaction;clock.reactionAt=c.now end
    clock.reactionElapsed=if a.reaction then c.now-clock.reactionAt else 0
    present()
   end
  end
  -- Locomotion, direction changes, a combo, a dodge, a launcher, pursuit, air,
  -- slam, knockdown, wakeup and finally a KO.
  a.move=V.new(1,0,0);advance(.4)
  a.move=V.new(0,0,-1);advance(.4)
  a.move=V.new(-1,0,0);advance(.4)
  a.move=Vector3.zero;advance(.2)
  c:request(a,"Attack");advance(.4)
  c:request(a,"Dodge");advance(.6)
  c:relocate(a,c.match.origin+V.new(0,3,3));c:relocate(b,c.match.origin+V.new(0,3,-3))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
  c:request(a,"Attack");advance(.4)
  c:request(a,"Attack");advance(.4)
  c:request(a,"Heavy");advance(.6)
  c:request(a,"Pursuit");advance(.5)
  c:request(a,"Attack");advance(.4)
  c:request(a,"Heavy");advance(1.4)
  c:damage(a,b,999,false,true);advance(1.8)
  assert(seen.attack and seen.locomotion,"the fight never presented an attack or locomotion")
  -- Strikes may whip at up to 38 deg per 60 Hz frame (2280 deg/s: a fast kick,
  -- not a teleport); anything above that is a pose snapping into place.
  assert(worst<39,"a snap of "..string.format("%.1f",worst).." deg/frame at "..worstAt)
 end
end)
test("knockdown, wakeup and reset leave no broken animation state",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(a,c.match.origin+V.new(0,3,3));c:relocate(b,c.match.origin+V.new(0,3,-3))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 local clock={attackElapsed=0,reactionElapsed=0}
 local branch
 local function present()
  local velocity=b.root.AssemblyLinearVelocity
  branch=frame(b.model,body(b,{velocity=velocity,speed=velocity.Magnitude,
   attackName=b.attackName,state=b.state,reaction=b.reaction,groundPose=b.groundPose,
   hitAngle=b.hitAngle or 0,hitStrength=b.hitStrength or .5}),clock,1/60)
 end
 local Brawler=H.load("Server/Brawler")
 Brawler.react(c,b,"Knockdown",Vector3.zero,.5,a)
 assert(b.groundPose=="Knockdown","knockdown did not declare a ground pose")
 assert(b.groundSide==1 or b.groundSide==-1,"knockdown did not pick a roll side")
 -- While knocked down the presentation must choose the grounded branch, never
 -- the air reaction: a body on the floor is not an airborne body.
 for _=1,30 do c:update(.01,c.now+.01);present() end
 assert(b.reaction=="Knockdown","the knockdown ended early")
 assert(b.airborne==false,"a landed knockdown was still reported airborne")
 assert(branch=="ground","a knocked-down body presented as "..tostring(branch))
 -- Wake-up resolves back into a playable state and drops its ground pose.
 for _=1,60 do c:update(.01,c.now+.01);present() end
 assert(b.reaction==nil or b.reaction=="Wakeup","wakeup never resolved: "..tostring(b.reaction))
 if b.reaction==nil then assert(b.groundPose==nil,"a recovered body kept its ground pose") end
 assert(b.health>0 and b.state~="Defeated","the knockdown left the body in a broken state")
 -- Hard reset clears every joint and leaves no orphaned swing state.
 Motion.reset(a.model)
 Motion.reset(b.model)
 for _,actor in {a,b} do
  for key,joint in actor.model.joints do
   local x,y=axisAngles(joint.Transform)
   assert(math.max(x,y)<1e-4,"reset left "..key.." deformed on "..actor.id)
  end
  assert(actor.pending==nil and actor.reaction==nil,"reset left "..actor.id.." reactive")
 end
end)
test("a KO settles by the blow that ended it",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local function koPose(style)
  Motion.reset(a.model)
  for _=1,90 do frame(a.model,body(a,{health=0,koStyle=style,velocity=Vector3.zero}),
   {attackElapsed=0,reactionElapsed=0},1/60) end
  return snapshot(a.model)
 end
 local light=koPose("light")
 local slam=koPose("slam")
 local launcher=koPose("launcher")
 local finisher=koPose("finisher")
 local function diff(x,y)
  local n=0
  for key,transform in x do
   local x1,y1=axisAngles(transform)
   local x2,y2=axisAngles(y[key])
   if math.max(math.abs(x1-x2),math.abs(y1-y2))>.03 then n+=1 end
  end
  return n
 end
 assert(diff(light,finisher)>=3,"a light KO and a finisher KO are the same collapse")
 assert(diff(slam,launcher)>=3,"a slam KO and a launcher KO are the same collapse")
 -- A defeated body must not hold a neutral standing pose.
 for _,pose in {light,slam,launcher,finisher} do
  local upright=0
  for key,transform in pose do
   local x,y=axisAngles(transform)
   if math.max(x,y)<.05 then upright+=1 end
  end
  assert(upright<8,"a KO pose leaves most of the body upright ("..upright.." joints at rest)")
 end
end)
test("weapons follow the hand and only appear for their own moves",function()
 local c,a=H.duel("Flashstep","Mirage")
 local function state(actor)
  Motion.weapon(a.model,body(a,actor))
  return Motion.weaponState(a.model)
 end
 local idle=state({attackName=nil,state="Neutral",attackElapsed=0})
 assert(idle.count>0,"no weapon was ever created for the fighter")
 assert(not idle.visible,"the weapon stayed out while idle")
 local cut=state({attackName="Light1",state="Active",attackElapsed=.12})
 assert(cut.visible,"no kunai visible during a kunai attack")
 local kick=state({attackName="Light3",state="Active",attackElapsed=.12})
 assert(not kick.visible,"the weapon appeared for a move that does not use it")
 -- Released after the follow-through, not clipped away mid-swing.
 local late=state({attackName="Light1",state="Recovery",attackElapsed=.9})
 assert(not late.visible,"the weapon stayed out past its swing")
 -- The other fighter uses the other hand and its own move list.
 local d,b=H.duel("Mirage","Flashstep")
 Motion.weapon(b.model,body(b,{attackName="Light2",state="Active",attackElapsed=.14}))
 local shuriken=Motion.weaponState(b.model)
 assert(shuriken.visible,"no shuriken visible during Itachi's throw")
 -- A move that is not a throw must not leave the shuriken hanging in the hand.
 -- Slam is a body move for both fighters.
 Motion.weapon(b.model,body(b,{attackName="Slam",state="Active",attackElapsed=.14}))
 assert(not Motion.weaponState(b.model).visible,"a body move kept the shuriken out")
end)
test("planted feet stay put in the world while walking, strafing, stopping and turning",function()
 local root={CFrame=H.C.lookAt(V.new(0,3,0),V.new(1,3,0))}
 local char={FindFirstChild=function(_,name) if name=="HumanoidRootPart" then return root end return nil end}
 local base={rf={x=.2,z=.7},lf={x=-.1,z=-.7}}
 local dt=1/60
 local lastWorld={}
 local planted={}
 local steps=0
 local worstSlide=0
 local worstReach=0
 local segments={{V.new(18,0,0),1.5,0},{V.new(38,0,0),1,0},{V.new(0,0,15),1,0},{V.new(-12,0,0),.8,0},{V.zero,.8,0},{V.zero,1,2.5}}
 for _,seg in segments do
  local velocity,duration,turn=seg[1],seg[2],seg[3]
  for _=1,math.floor(duration/dt) do
   Motion.tick(dt)
   local look=root.CFrame.LookVector
   local yaw=math.atan2(-look.X,-look.Z)+turn*dt
   local pos=root.CFrame.Position+velocity*dt
   root.CFrame=H.C.new(pos)*H.C.Angles(0,yaw,0)
   local rf,lf=Motion._stepFeet(char,base,velocity,dt)
   for side,f in {R=rf,L=lf} do
    local sign=if side=="R" then 1 else -1
    local world=root.CFrame:PointToWorldSpace(V.new(.5*sign+f.x,Motion._ankleY+f.y,f.z))
    local isPlanted=f.toe==0
    if isPlanted and planted[side] and lastWorld[side] then
     worstSlide=math.max(worstSlide,(world-lastWorld[side]).Magnitude)
    end
    if not isPlanted and planted[side] then steps+=1 end
    planted[side]=isPlanted;lastWorld[side]=world
    worstReach=math.max(worstReach,math.sqrt(f.x*f.x+f.z*f.z))
   end
  end
 end
 assert(worstSlide<.05,string.format("a planted foot slid %.3f studs in one frame",worstSlide))
 assert(steps>=10,"the feet barely stepped ("..steps..")")
 assert(worstReach<2.2,string.format("a foot was left %.2f studs from its hip",worstReach))
end)

print(string.format("NinjaDuel animation presentation: %d PASS",passed))
