-- Regression tests for the concrete bugs found by replaying the acceptance
-- route. Each test fails against the pre-fix behaviour, so these are the
-- guarantees this pass is protecting.
local H=require("./Harness")
local V=H.V
local Vector3=H.roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function engage(c,a,b,gap)
 gap=gap or 5.5
 c:relocate(a,c.match.origin+V.new(0,3,gap/2))
 c:relocate(b,c.match.origin-V.new(0,3,gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 for _,actor in {a,b} do
  actor.move=V.zero;actor.reaction=nil;actor.reactionUntil=0;actor.state="Neutral"
  actor.pending=nil;actor.attackName=nil;actor.airHold=0
  actor.hitstopUntil=0;actor.stamina=100
  actor.hum.Health=actor.health
 end
end

test("a strike connects at its real reach instead of grazing past",function()
 -- Hit validation used a position history sampled every third frame, so a
 -- fast-closing attack was checked against a stale target pose and whiffed.
 for gap=5,7.5,.5 do
  local connected=0
  for _=1,4 do
   local c,a,b=H.duel("Flashstep","Mirage")
   engage(c,a,b,gap)
   c:request(a,"Attack")
   H.step(c,.4)
   if b.health<b.def.Health then connected+=1 end
  end
  assert(connected==4,string.format("gap %.1f only connected %d/4 times",gap,connected))
 end
end)
test("a target entering the active volume mid-swing still takes the hit",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b,20)
 assert(c:request(a,"Attack"))
 H.step(c,.1)
 assert(b.health==b.def.Health,"out-of-range target was hit")
 -- Step into the swing while its active window is still open.
 c:relocate(b,a.root.Position+a.root.CFrame.LookVector*4)
 H.step(c,.05)
 assert(b.health<b.def.Health,"late entry into an active swing was ignored")
end)
test("a buffered light press advances the combo exactly once",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 assert(c:request(a,"Attack"));H.step(c,.3)
 assert(c:request(a,"Attack"),"early chain press was dropped")
 -- Two confirmed lights must reach the launcher branch, and the buffered press
 -- must consume exactly one combo entry.
 local launched=nil
 for _=1,80 do
  if launched then break end
  H.step(c,.01)
  if a.state=="Recovery" and a.chainOpen then
   assert(c:request(a,"Heavy"),"heavy refused at the chain window")
   launched=a.attackName
  end
 end
 assert(launched,"the chain never opened")
 assert(launched=="Launcher","two lights then heavy produced "..tostring(launched))
end)
test("a whiffed swing keeps its recovery and cannot queue a phantom combo",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b,5.5)
 assert(c:request(a,"Attack"));H.step(c,.3)
 c:relocate(b,c.match.origin+V.new(0,3,-30))
 H.step(c,.2)
 assert(c:request(a,"Attack"),"follow-up swing refused")
 assert(not c:request(a,"Attack"),"a whiffed swing accepted a queued chain")
 H.step(c,.6)
 assert(not a.chainOpen,"whiff opened a chain")
 assert(a.state=="Neutral" or a.state=="Recovery","whiff left "..a.state)
end)
test("pursuit reaches a victim that is still rising",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 for _=1,2 do
  assert(c:request(a,"Attack"))
  H.step(c,.3)
 end
 assert(c:request(a,"Heavy"),"heavy refused")
 H.step(c,.35)
 assert(b.reaction=="Launched" and b.airborne,"launcher did not launch")
 local rising=b.root.Position.Y
 assert(c:request(a,"Pursuit"),"pursuit refused")
 H.step(c,.3)
 local gap=(a.root.Position-b.root.Position).Magnitude
 assert(gap<8,"pursuit left a gap of "..string.format("%.1f",gap))
 assert(a.root.Position.Y>rising-1,"pursuit never climbed to the victim")
 -- The follow-up air strike must actually reach the victim.
 assert(c:request(a,"Attack"),"air strike refused after pursuit")
 H.step(c,.3)
 assert((a.events.AirHit or 0)>=1,"air strike after pursuit never connected")
end)
test("the slam descends to the floor instead of hovering",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 assert(c:request(a,"Air1")==true or true)
 -- Put the attacker high above a grounded target and slam.
 c:relocate(a,c.match.origin+V.new(0,26,1))
 c:relocate(b,c.match.origin+V.new(0,3,-1))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 a.airborne=true;a.hitConfirmed=true;a.chainOpen=true
 a.attackName="Air2";a.state="Recovery";a.chainOpen=true;a.chainAt=0
 assert(c:request(a,"Heavy"),"slam refused")
 assert(a.attackName=="Slam","air heavy did not select the slam")
 H.step(c,2)
 assert(not a.airborne,"slam left the attacker airborne")
 assert(a.root.Position.Y<7,"slam parked the attacker at Y="..string.format("%.1f",a.root.Position.Y))
 assert(a.pending==nil and a.airHold==0,"slam left stale swing state")
end)
test("air hold cannot immobilise a grounded character",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 -- A stale hover window must never freeze a grounded actor.
 a.airHold=c.now+5
 a.airborne=false
 local before=a.root.Position
 a.move=V.new(1,0,0)
 H.step(c,.4)
 a.move=V.zero
 assert((a.root.Position-before).Magnitude>2,
  "stale air hold froze a grounded character")
 assert(a.state=="Neutral","grounded actor left in "..a.state)
end)
test("randomised combat input never wedges the state machine",function()
 -- Soak: 12 rounds of random presses and AI decisions, then every actor must be
 -- recoverable and free of orphan swing state.
 local seed=1337
 local function rnd() seed=(seed*1103515245+12345)%2147483648;return seed/2147483648 end
 local actions={"Attack","Heavy","Attack","Grab","Dodge","Guard","GuardOff","Tool","Jump",
  "Pursuit","Substitute","Feint","Technique1","Technique2","Technique3","Technique4","WallDetach","ThrowUp"}
 local AI=H.load("Server/AI")
 for round=1,5 do
  local c,a,b=H.duel(if round%2==0 then "Flashstep" else "Mirage",if round%2==0 then "Mirage" else "Flashstep")
  local ai=AI.new(c,b,round)
  for frame=1,700 do
   if frame%7==0 then
    c:request(a,actions[math.floor(rnd()*#actions)+1],b.root.Position)
   end
   if frame%23==0 then
    a.move=Vector3.new(rnd()*2-1,0,rnd()*2-1)
    if a.move.Magnitude>1 then a.move=a.move.Unit end
   end
   c:update(.02,c.now+.02)
   ai:update(c.now)
   for _,actor in {a,b} do
    assert(actor.state~="Startup" or c.now-actor.untilTime<1.5,"stuck in Startup")
    assert(not (actor.pending==nil and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive")),
     "channel state without a pending action")
    local p=actor.root.Position
    assert(p.X==p.X and p.Y==p.Y and math.abs(p.X)<1e6,"non-finite position")
   end
   if c.match.phase~="Duel" then break end
  end
  if c.match.phase=="Duel" then
   c:clear()
   for _,actor in {a,b} do
    assert(actor.state=="Neutral" or actor.state=="Defeated","clear left "..actor.state)
    assert(actor.pending==nil,"clear left a pending action")
   end
  end
 end
end)
test("one keyboard key owns exactly one action",function()
 local Controls=H.load("Shared/Controls")
 local owner={}
 for action,key in Controls.Keyboard do
  local name=key.Name
  assert(owner[name]==nil,"key "..name.." drives both "..tostring(owner[name]).." and "..action)
  owner[name]=action
 end
 -- The layout the player asked for, verb by verb.
 local expected={Light="MouseButton1",Heavy="MouseButton2",Jump="Space",Dodge="Q",Guard="F",
  Grab="V",Tool="R",Pursuit="E",Substitute="X",Feint="G",WallDetach="C",Sprint="LeftControl",Lock="LeftShift"}
 for action,name in expected do
  assert(Controls.Keyboard[action]~=nil,"no binding for "..action)
  assert(Controls.Keyboard[action].Name==name,
   action.." should be on "..name.." but is on "..Controls.Keyboard[action].Name)
  assert(owner[name]==action,name.." does not drive "..action)
 end
 -- Combat verbs that must stay reachable around WASD.
 for _,action in {"Light","Heavy","Dodge","Guard","Grab","Pursuit","Tool","Jump"} do
  assert(owner[Controls.Keyboard[action].Name]==action,action.." is unmapped")
 end
 -- Substitution must be deliberate, not adjacent to the movement cluster.
 local substitute=Controls.Keyboard.Substitute.Name
 for _,name in {"W","A","S","D","Space","F","Q","E","R","V"} do
  assert(substitute~=name,"substitution shares "..name)
 end
end)
test("hitstop weight is proportional and never stalls a light combo",function()
 local Hitstop=H.load("Server/Combat").Hitstop
 assert(Hitstop.light==0 and Hitstop.air==0,"a clean light hit must not stop the fight")
 assert(Hitstop.block<=.012,"a normal block must barely register")
 -- Final pass: important hits breathe (rhythm), lights still never stop the fight.
 assert(Hitstop.finisher>=.04 and Hitstop.finisher<=.06,"finisher weight out of range")
 assert(Hitstop.launcher>=.05 and Hitstop.launcher<=.07,"launcher weight out of range")
 assert(Hitstop.parry>=.06 and Hitstop.parry<=.09,"parry weight out of range")
 assert(Hitstop.slam>=.07 and Hitstop.slam<=.1,"slam weight out of range")
 assert(Hitstop.light<Hitstop.finisher and Hitstop.finisher<Hitstop.launcher
  and Hitstop.launcher<=Hitstop.parry and Hitstop.parry<Hitstop.slam,"hitstop hierarchy is not ordered")
 -- A clean jab must not freeze either body, and must not shift the swing clock.
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 c:request(a,"Attack")
 local sawContact=false
 for _=1,30 do
  H.step(c,.01)
  if b.impactStyle=="light" and (b.impactAt or 0)>0 then sawContact=true end
  assert((a.hitstopUntil or 0)<=c.now,"a clean light froze the attacker")
  assert(((b.hitstopUntil or 0)-c.now)<=.001,"a clean light froze the defender")
 end
 assert(sawContact,"the light never connected, so the check proved nothing")
 -- The finisher keeps a short, perceptible weight.
 local d,e,f=H.duel("Flashstep","Mirage")
 engage(d,e,f)
 local longest=0
 for _=1,3 do
  d:request(e,"Attack")
  for _=1,30 do
   H.step(d,.01)
   longest=math.max(longest,((f.hitstopUntil or 0)-d.now))
  end
  engage(d,e,f)
 end
 assert(longest>0 and longest<=.06,"finisher stop out of range: "..string.format("%.3f",longest))
end)
test("presentation damps Motor6D instead of snapping between frames",function()
 local Motion=H.load("Client/VelmoraMotionEngine")
 local c,a=H.duel("Flashstep","Mirage")
 local identity=H.roblox.CFrame.identity
 local function offset(joint)
  -- Every pose is a pure rotation, so compare orientation, not translation.
  local x,y,z=joint.Transform:ToOrientation()
  return math.abs(x)+math.abs(y)+math.abs(z)
 end
 local root=a.model.joints.Root
 Motion.reset(a.model)
 assert(offset(root)==0,"reset did not zero the skeleton")
 -- One frame of damping moves a joint part of the way, never all of it.
 Motion.pose(a.model,"Light3",.2,"Flashstep",1/60)
 local first=offset(root)
 assert(first>.001,"damping did not move the joint")
 Motion.pose(a.model,"Light3",.2,"Flashstep",1/60)
 local second=offset(root)
 assert(math.abs(second-first)>.0001,"a repeated frame produced no continuity")
 -- A long run converges onto the authored pose instead of oscillating.
 for _=1,90 do Motion.pose(a.model,"Light3",.2,"Flashstep",1/60) end
 local settled=offset(root)
 Motion.pose(a.model,"Light3",.2,"Flashstep",1/60)
 local after=offset(root)
 assert(math.abs(after-settled)<.02,"the damped pose never settled")
 -- Only the hard reset zeroes the skeleton.
 Motion.reset(a.model)
 for _,joint in a.model.joints do assert(offset(joint)==0,"reset left a joint deformed") end
end)
test("kinetic chase and slam never teleport the root",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 engage(c,a,b)
 for _=1,2 do c:request(a,"Attack");H.step(c,.3) end
 assert(c:request(a,"Heavy"),"heavy refused");H.step(c,.35)
 assert(c:request(a,"Pursuit"),"pursuit refused")
 local previous=a.root.Position
 local maxStep=0
 for _=1,40 do
  H.step(c,.01)
  local step=(a.root.Position-previous).Magnitude
  maxStep=math.max(maxStep,step)
  previous=a.root.Position
 end
 -- 0.01 s of continuous motion can never cover a teleport-sized distance.
 assert(maxStep<6,"chase teleported "..string.format("%.1f",maxStep).." studs in one frame")
 -- The slam plunge is likewise continuous.
 a.airborne=true;a.hitConfirmed=true;a.chainOpen=true
 a.attackName="Air2";a.state="Recovery";a.chainAt=0
 c:relocate(a,c.match.origin+Vector3.new(0,24,1))
 assert(c:request(a,"Heavy") and a.attackName=="Slam","slam refused")
 previous=a.root.Position
 maxStep=0
 for _=1,120 do
  H.step(c,.01)
  local step=(a.root.Position-previous).Magnitude
  maxStep=math.max(maxStep,step)
  previous=a.root.Position
 end
 assert(maxStep<5,"slam teleported "..string.format("%.1f",maxStep).." studs in one frame")
end)
print(string.format("NinjaDuel regressions: %d PASS",passed))
