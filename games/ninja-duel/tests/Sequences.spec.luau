-- Manual-route replay: the 14-step acceptance sequence, executed headlessly for
-- both fighters. Any step that leaves an actor, the AI or the camera in a broken
-- state fails here instead of shipping. Geometry adapter: native QA still required.
local H=require("./Harness")
local V=H.V
local FRAMING={Ground=true,Launcher=true,Pursuit=true,AirCombo=true,Slam=true,Wall=true}
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local TERMINAL={Neutral=true,Guarding=true,Defeated=true}
local function assertClean(a,label)
 assert(a.state~="Startup" and a.state~="Active","stuck in "..a.state.." ("..label..")")
 assert(TERMINAL[a.state] or a.state=="Recovery","left in "..a.state.." ("..label..")")
 assert(a.pending==nil,"orphan pending ("..label..")")
 assert(a.evade==nil,"orphan evade ("..label..")")
 assert(a.airHold==0,"orphan airHold ("..label..")")
 local p=a.root.Position
 for _,v in {p.X,p.Y,p.Z,a.chakra,a.health} do
  assert(v==v and math.abs(v)<1e6,"non-finite actor state ("..label..")")
 end
end
local function assertJointsIdentity(model,label)
 for key,joint in model.joints do
  assert(joint.Transform:FuzzyEq(H.roblox.CFrame.identity,1e-4),label..": "..key.." left deformed")
 end
end
local function humanData(a)
 return {fighterId=a.fighterId,fighter=a.def.Name,health=a.health,maxHealth=a.def.Health,chakra=a.chakra,
  state=a.state,airborne=a.airborne,reaction=a.reaction,attackName=a.attackName,
  pursuit=math.max(0,a.pursuitUntil-a.untilTime),wall=a.wall~=nil,speed=a.locomotion.Magnitude,
  velocity=a.root.AssemblyLinearVelocity,guardImpact=0,impactSerial=a.impactSerial or 0,impactHeavy=a.impactHeavy,
  cue="",events=a.events,attackElapsed=0,illusion=0,decoy=nil,dodge=0,subCharges=a.subCharges,stamina=a.stamina,
  position=a.root.Position}
end
-- Place both fighters in a known exchange position; the acceptance route is
-- about state, not about surviving whatever the previous step left behind.
local function engage(c,a,b,gap)
 gap=gap or 5.5
 c:relocate(a,c.match.origin+V.new(0,3,gap/2))
 c:relocate(b,c.match.origin-V.new(0,3,gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 a.move=V.zero;a.reaction=nil;a.reactionUntil=0;a.state="Neutral";a.pending=nil;a.attackName=nil
 b.move=V.zero;b.reaction=nil;b.reactionUntil=0;b.state="Neutral";b.pending=nil;b.attackName=nil
 a.hum.Health=a.health;b.hum.Health=b.health
end
local function makeCamera()
 local camera=H.roblox.Instance.new("Camera")
 camera.CameraType=H.roblox.Enum.CameraType.Scriptable
 camera.FieldOfView=70
 camera.ViewportSize=H.roblox.Vector2.new(1280,720)
 camera.CFrame=H.roblox.CFrame.new(0,10,30)
 H.workspace.CurrentCamera=camera
 return camera
end

for _,fighter in {"Flashstep","Mirage"} do
 local other=if fighter=="Flashstep" then "Mirage" else "Flashstep"
 test(fighter..": full ground route, launcher, pursuit, air combo, slam, wakeup",function()
  local c,a,b=H.duel(fighter,other)
  c.match.techniquesDisabled=true
  a.move=V.new(1,0,0);H.step(c,.2);a.move=V.zero
  assert(b.health==b.def.Health,"idle movement caused damage")
  assert(c:request(a,"Dodge"),"dodge refused from neutral")
  H.step(c,.5);assertClean(a,"after dodge")
  engage(c,a,b)
  assert(c:request(a,"Attack"),"light 1 refused")
  H.step(c,.3)
  assert(b.health<b.def.Health,"the first light never connected")
  -- Press slightly before the chain window opens: the input must buffer.
  assert(c:request(a,"Attack"),"early chain press was dropped")
  local chained=false
  for _=1,60 do
   H.step(c,.01)
   if not chained and a.state=="Recovery" and a.chainOpen then
    chained=true
    assert(c:request(a,"Heavy"),"heavy refused at the chain window")
   end
  end
  assert(chained,"the buffered second light never opened a chain")
  assert(a.attackName=="Launcher","chain did not select the launcher: "..tostring(a.attackName))
  H.step(c,.35)
  assert(b.reaction=="Launched" and b.airborne,"launcher did not launch")
  assert(a.pursuitUntil>c.now,"no pursuit window after the launch")
  assert(c:request(a,"Pursuit"),"pursuit refused during the launch window")
  H.step(c,.3)
  assert((a.root.Position-b.root.Position).Magnitude<9,"pursuit did not close the gap")
  assert(c:request(a,"Attack"),"first air strike refused");H.step(c,.28)
  assert(c:request(a,"Attack"),"second air strike refused");H.step(c,.28)
  assert((a.events.AirHit or 0)>=2,"air combo did not register two contacts")
  assert(c:request(a,"Heavy"),"slam refused");H.step(c,.45)
  assert(b.reaction=="Knockdown","slam did not knock down")
  H.step(c,1.6)
  assert(not a.airborne,"slam left the attacker airborne")
  assert(a.root.Position.Y<6,"slam left the attacker suspended at Y="..string.format("%.1f",a.root.Position.Y))
  assert(b.reaction==nil or b.reaction=="Wakeup","victim stuck in "..tostring(b.reaction))
  H.step(c,.6);assertClean(a,"end of route");assertClean(b,"end of route")
 end)
 test(fighter..": guard, parry, dodge and substitution leave no locked state",function()
  local c,a,b=H.duel(fighter,other)
  engage(c,a,b)
  assert(c:request(b,"Guard"),"guard refused")
  H.step(c,.05)
  assert(not c:damage(a,b,8,false,true),"guard let damage through")
  assert(a.state=="Stunned","parry did not expose the attacker")
  H.step(c,.7)
  assert(c:request(b,"GuardOff"),"guard release refused")
  assert(c:damage(a,b,9,false,true),"strike after guard release failed")
  assert(c:request(b,"Substitute"),"substitution refused during the hurt window")
  assert(b.state=="Recovery" and b.airHold==0)
  H.step(c,.4);assertClean(b,"after substitution")
  engage(c,a,b)
  c:damage(a,b,5,false,true)
  H.step(c,.5)
  assert(c:request(b,"Dodge"),"dodge refused after recovery")
  H.step(c,.6);assertClean(b,"after dodge")
 end)
 test(fighter..": tool and every jutsu resolve then recover",function()
  local c,a,b=H.duel(fighter,other)
  engage(c,a,b)
  assert(c:request(a,"Tool",b.root.Position),"tool refused")
  H.step(c,.4);assertClean(a,"after tool")
  for slot=1,#a.def.Techniques do
   a.cooldowns={};a.chakra=a.def.Chakra
   if a.def.Techniques[slot].Requires=="Anchor" then
    a.anchor={position=a.root.Position+V.new(6,0,0),expires=c.now+12,part=c:effect("Anchor",a.root.Position,a.color,V.one,12)}
   end
   assert(c:request(a,"Technique"..slot,b.root.Position),"technique "..slot.." refused")
   H.step(c,2.4)
   assertClean(a,"after technique "..slot)
   assert(a.state~="TechniqueChannel" and a.state~="TechniqueActive","technique "..slot.." never resolved")
  end
 end)
 test(fighter..": wall interaction and detach stay bounded",function()
  local c,a,b=H.duel(fighter,other)
  local World=H.load("Server/World")
  local yard=H.fakePart(V.zero);yard.Name="Courtyard";yard.Parent=nil
  local wall=World.part(yard,"Ninja wall",V.new(3,23,26),H.C.new(V.new(26,11.5,0)),H.roblox.Color3.new(0,0,0))
  wall:SetAttribute("NinjaWall",true)
  local oldRay=H.workspace.Raycast
  H.workspace.Raycast=function(self,origin,delta,params)
   local flat=V.new(delta.X,0,delta.Z)
   if flat.Magnitude>0.2 and flat.Unit.X>0.3 then
    local distance=26-origin.X
    if distance>0.5 and distance<=flat.Magnitude+1.4 then
     return {Position=V.new(26,origin.Y,origin.Z),Normal=V.new(-1,0,0),Distance=distance,Instance=wall}
    end
   end
   return oldRay(self,origin,delta,params)
  end
  -- Approach the wall like a player: keep the move intent live and let the
  -- donor locomotion close the last studs. Facing must already be into it.
  c:relocate(a,V.new(21,3,0));a.root.CFrame=H.C.lookAt(a.root.Position,V.new(30,3,0))
  for _=1,20 do
   a.move=V.new(1,0,0)
   H.step(c,.02)
   if a.wall then break end
  end
  assert(a.wall~=nil,"never attached to the wall")
  assert(c:request(a,"WallDetach"),"wall detach refused")
  assert(a.wall==nil,"detach left the actor attached")
  H.step(c,.9);assertClean(a,"after wall detach")
  H.workspace.Raycast=oldRay
 end)
 test(fighter..": death and rematch reset every actor field",function()
  local c,a,b,m=H.duel(fighter,other)
  c:request(a,"Grab");H.step(c,.25)
  c:damage(b,a,1000,false,false)
  assert(m.phase=="Result","death did not end the duel")
  assert(not a.grabVictim and not b.grabbedBy and b.reaction==nil,"death left the grab attached")
  assert(a.pending==nil and a.attackName==nil,"death left a committed attack")
  c:clear(true)
  for _,actor in {a,b} do assertClean(actor,"after death clear") end
 end)
 test(fighter..": AI never commits an impossible chained action",function()
  local c,a,b=H.duel(fighter,other)
  local AI=H.load("Server/AI")
  local ai=AI.new(c,b,7)
  engage(c,a,b,9)
  local seen={}
  for _=1,600 do
   c:update(.01,c.now+.01)
   ai:update(c.now)
   seen[b.state]=true
   assert(b.hum.MoveDirection~=nil,"AI produced no move intent")
   if b.pending then
    local okState=b.state=="Startup" or b.state=="Active"
     or b.state=="TechniqueActive"
     or (b.state=="TechniqueChannel" and b.pending.kind=="Technique")
    assert(okState,"pending outside a committed window: "..b.state.."/"..tostring(b.pending.kind))
   else
    assert(b.state~="TechniqueChannel","channel without a pending technique")
   end
   if b.reaction then assert(b.pending==nil,"AI reacted while a swing was committed") end
  end
  assert(seen.Neutral or seen.Recovery,"AI never returned to a playable state")
  assert(a.health>0 and b.health>0,"AI duel ended unexpectedly")
 end)
end
test("minato lateral angles do not desynchronise or push through the target",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local maxDrift=0
 c:request(a,"Attack")
 for _=1,60 do
  H.step(c,.01)
  local distance=(a.root.Position-b.root.Position).Magnitude
  if distance<4 then maxDrift=math.max(maxDrift,4-distance) end
 end
 assert(maxDrift<2.6,"attacker pushed inside the target by "..string.format("%.2f",maxDrift))
 H.step(c,.6)
 assert((a.root.Position-b.root.Position).Magnitude<9,"fighters did not resettle after the exchange")
end)
test("camera never enters the wall: fights against it, with the shake of a slam, keep the lens on this side",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local Camera=H.load("Client/Camera")
 local camera=makeCamera()
 local keepPlayer=H.localPlayer.Character
 H.localPlayer.Character=a.model
 H.clearWalls()
 H.addWall(9)
 local cam=Camera.new()
 local worst=-99
 for k,spot in {{6,-2},{7.5,1},{4,7.5},{8,3}} do
  c:relocate(a,V.new(spot[1],3,k%2==0 and 2 or -2));c:relocate(b,V.new(spot[2],3,0))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
  for f=1,90 do
   if f==30 then cam:impulse("slam","victim") end
   cam:update({phase="Duel",epoch=1,human=humanData(a),bot=humanData(b)},1/60)
   worst=math.max(worst,camera.CFrame.Position.X)
  end
 end
 H.clearWalls()
 H.localPlayer.Character=keepPlayer
 assert(worst<=9-1,string.format("the lens went to x=%.2f against a wall at x=9",worst))
end)

test("camera framing stays bounded, focused and free of snaps",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local Camera=H.load("Client/Camera")
 local camera=makeCamera()
 local keepPlayer=H.localPlayer.Character
 H.localPlayer.Character=a.model
 local cam=Camera.new()
 local function sample()
  cam:update({phase="Duel",epoch=1,human=humanData(a),bot=humanData(b)},1/60)
  return camera.CFrame
 end
 local function check(label)
  local cf=sample()
  assert(cam.mode==nil or FRAMING[cam.mode],"unknown camera mode "..tostring(cam.mode))
  assert(camera.FieldOfView>55 and camera.FieldOfView<100,label..": FOV "..string.format("%.1f",camera.FieldOfView))
  local focus=cf.Position+cf.LookVector
  local mid=a.root.Position:Lerp(b.root.Position,.5)
  assert((cam.focus-mid).Magnitude<26,label..": focus drifted off the fighters")
  return cf
 end
 local previous=nil
 local function advance(frames,label)
  for _=1,frames do
   local cf=check(label)
   if previous then
    local step=(cf.Position-previous.Position).Magnitude
    assert(step<7,label..": camera snapped "..string.format("%.1f",step).." studs in one frame")
   end
   previous=cf
  end
 end
 advance(30,"ground")
 engage(c,a,b)
 c:request(a,"Dodge");advance(30,"dodge")
 H.step(c,.6)
 engage(c,a,b)
 for _=1,2 do c:request(a,"Attack");H.step(c,.3) end
 c:request(a,"Heavy");advance(20,"launcher")
 c:request(a,"Pursuit");advance(20,"pursuit")
 c:request(a,"Attack");advance(20,"air combo")
 c:request(a,"Attack");advance(20,"air combo 2")
 c:request(a,"Heavy");advance(40,"slam")
 H.step(c,.8)
 advance(80,"recovery")
 H.localPlayer.Character=keepPlayer
end)
test("animation pose never leaves a joint deformed or non-finite",function()
 local Motion=H.load("Client/VelmoraMotionEngine")
 for _,fighter in {"Flashstep","Mirage"} do
  local c,a=H.duel(fighter,if fighter=="Flashstep" then "Mirage" else "Flashstep")
  for _,name in {"Light1","Light2","Light3","Heavy","Launcher","DashAttack","Air1","Air2","Slam","Grab","Throw","ThrowUp"} do
   for _,elapsed in {0,.05,.12,.2,.3,.45,1,3} do
    Motion.pose(a.model,name,elapsed,fighter)
    for key,joint in a.model.joints do
     local components={joint.Transform:GetComponents()}
     for _,value in components do
      assert(value==value and math.abs(value)<1e6,name.."/"..key.." non-finite transform")
     end
    end
   end
   Motion.pose(a.model,name,10,fighter)
   assertJointsIdentity(a.model,name)
  end
  Motion.clear(a.model)
  assertJointsIdentity(a.model,"clear")
 end
end)
print(string.format("NinjaDuel sequence replay: %d PASS (headless geometry adapter; native QA still required)",passed))
