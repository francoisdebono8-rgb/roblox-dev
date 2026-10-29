-- Lune fallback: actual combat modules + Roblox datatypes, deterministic geometry adapter.
-- This proves timing/policy, NOT Studio physics, rendering or controller hardware.
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local V=roblox.Vector3
-- Lune 0.10.5 lookAt reverses facing relative to Roblox; use explicit basis.
local C=setmetatable({}, {__index=roblox.CFrame})
function C.lookAt(from,to)
 local forward=(to-from).Unit;local right=forward:Cross(V.yAxis).Unit;local up=right:Cross(forward)
 return roblox.CFrame.fromMatrix(from,right,up,-forward)
end
local actors={};local ground={CanCollide=true,GetAttribute=function() return nil end}
local workspace={}
function workspace:Raycast(origin,delta,params)
 if delta.Y<0 and origin.Y+delta.Y<=0 then
  local t=-origin.Y/delta.Y
  return {Position=origin+delta*t,Normal=V.yAxis,Distance=(delta*t).Magnitude,Instance=ground}
 end
 return nil
end
function workspace:GetPartBoundsInBox(cf,size,params)
 local out={}
 for _,model in params.FilterDescendantsInstances do
  if model.root then
   local p=cf:PointToObjectSpace(model.root.Position)
   if math.abs(p.X)<=size.X/2+1 and math.abs(p.Y)<=size.Y/2+1 and math.abs(p.Z)<=size.Z/2+1 then table.insert(out,model.root) end
  end
 end
 return out
end
local function fakePart(position)
 local p={CFrame=C.new(position),AssemblyLinearVelocity=V.zero,Parent=true,CanCollide=true,Transparency=0,Size=V.one}
 setmetatable(p,{__index=function(t,k) if k=="Position" then return t.CFrame.Position end end})
 function p:Destroy() self.Parent=nil end
 return p
end
local World={pose=function() end,part=function(_,_,size,cf) local p=fakePart(cf.Position);p.Size=size;return p end}
local attributes={}
local effectEmits=0
local function emitter() return {IsA=function(_,class) return class=="ParticleEmitter" end,GetAttribute=function() return 4 end,Emit=function(_,count) effectEmits+=count end} end
local function attachment() return {Clone=function() return attachment() end,GetChildren=function() return {emitter()} end} end
local assets={VFX={BasicPunch={Attachment=attachment()},ComboPunch={Attachment=attachment()}}}
local sharedStub
-- Resolve src/ from either the repository root or the game folder.
local SRC
for _,candidate in {"games/ninja-duel/src","src"} do
 if fs.isDir(candidate) then SRC=candidate break end
end
assert(SRC,"Could not locate ninja-duel src; run lune from the repository root or games/ninja-duel")
local names={}
for _,dir in {"Shared","Server","Client"} do
 names[dir]={}
 for _,file in fs.readDir(SRC.."/"..dir) do if file:match("%.luau$") then local name=file:gsub("%.luau$","");names[dir][name]=dir.."/"..name end end
end
local cached={["Server/World"]=World};local loadModule
local envBase={Vector3=V,Vector2=roblox.Vector2,CFrame=C,Color3=roblox.Color3,Enum=roblox.Enum,workspace=workspace,
 RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}
local bindings={}
local inputServices={
 ContextActionService={BindActionAtPriority=function(_,name,callback,_,_,...) bindings[name]={callback=callback,keys={...}} end},
 UserInputService={GetFocusedTextBox=function() return nil end,WindowFocusReleased={Connect=function() end},
  TextBoxFocused={Connect=function() end},GamepadDisconnected={Connect=function() end},LastInputTypeChanged={Connect=function() end},
  InputChanged={Connect=function() end},GetLastInputType=function() return roblox.Enum.UserInputType.Keyboard end,
  IsMouseButtonPressed=function() return false end},
}
envBase.Instance={new=function(class)
 local obj=fakePart(V.zero)
 obj.ClassName=class
 function obj:IsA(query) return query==self.ClassName or query=="BasePart" and self.ClassName=="Part" end
 function obj:Play() end
 return obj
end}
envBase.game={GetService=function(_,name)
 if name=="ReplicatedStorage" then
  sharedStub=sharedStub or setmetatable({BanglaAssets=assets,WaitForChild=function(_,key) return assets end},{__index=names.Shared})
  return {NinjaDuel=sharedStub}
 end
 if name=="Debris" then return {AddItem=function() end} end
 if name=="RunService" or name=="KeyframeSequenceProvider" or name=="ServerStorage" then return {} end
 if inputServices[name] then return inputServices[name] end
 error("Unexpected service "..name)
end}
loadModule=function(path)
 if cached[path] then return cached[path] end
 local fn=assert(loadstring(fs.readFile(SRC.."/"..path..".luau"),path))
 local env=setmetatable({require=loadModule,script={Parent=names[path:match("^(%w+)/")] }},{__index=function(_,key) return envBase[key] or getfenv()[key] end})
 setfenv(fn,env);cached[path]=fn();return cached[path]
end
local Combat=loadModule("Server/Combat")
local Brawler=loadModule("Server/Brawler")
local Tutorial=loadModule("Server/Tutorial")
local Controls=loadModule("Shared/Controls")
local function pair()
 table.clear(actors)
 local effects={ClearAllChildren=function() end}
 local match={origin=V.zero,phase="Duel",effects=effects}
 local c=Combat.new(match);c.now=100
 local function actor(id,key,z)
  local root=fakePart(V.new(0,3,z));root.CFrame=C.lookAt(root.Position,V.new(0,3,-z))
  local model={root=root,Parent=true,attributes={}};function model:PivotTo(cf) self.root.CFrame=cf end
  function model:SetAttribute(key,value) self.attributes[key]=value end
  function model:GetAttribute(key) return self.attributes[key] end
  function root:IsDescendantOf(other) return other==model end
  function root:IsA(query) return query=="BasePart" end
  local hum={Health=125,WalkSpeed=0,Parent=true,RigType=roblox.Enum.HumanoidRigType.R15,HipHeight=2,FloorMaterial=roblox.Enum.Material.Concrete,AutoRotate=true,Move=function(self,direction) self.MoveDirection=direction end,MoveDirection=V.zero,ChangeState=function(self,state) self.nativeState=state end,GetState=function(self) return self.nativeState or roblox.Enum.HumanoidStateType.Running end,FindFirstChildOfClass=function() return nil end}
  local a=c:add(id,model,hum,root,{},key);table.insert(actors,a);return a
 end
 local a,b=actor("A","Flashstep",2.5),actor("B","Mirage",-2.5);a.target=b;b.target=a
 match.finish=function() match.phase="Result";c:clear() end
 return c,a,b
end
local function step(c,time)
 for _=1,math.ceil(time/.01) do c:update(.01,c.now+.01) end
end
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
 passed+=1;print("PASS "..name)
end
test("ground branch, real launch, 3D chase, two air hits, slam and wakeup",function()
 local c,a,b=pair();c.match.techniquesDisabled=true
 assert(not c:request(a,"Technique1"))
 for _=1,2 do assert(c:request(a,"Attack"));step(c,.3) end
 assert(c:request(a,"Heavy"));step(c,.35);assert(b.reaction=="Launched" and b.root.Position.Y>8)
 assert(c:request(a,"Pursuit"));step(c,.25)
 assert((a.root.Position-b.root.Position).Magnitude<8)
 assert(c:request(a,"Attack"));step(c,.28);assert(b.reaction=="Juggled")
 assert(c:request(a,"Attack"));step(c,.29);assert(a.events.AirHit==2)
 assert(c:request(a,"Heavy"));step(c,.4);assert(b.reaction=="Knockdown" and a.events.SlamHit==1)
 step(c,1.1);assert(b.reaction==nil)
 -- Outside a chase window E is the chakra dash, never the aerial pursuit.
 c:request(a,"Pursuit");assert(a.state~="Pursuit","pursuit without a window")
end)
test("horizontal finisher differs from launcher",function()
 local c,a,b=pair()
 for _=1,3 do assert(c:request(a,"Attack"));step(c,.3) end
 assert(a.attackName=="Light3" and b.reaction=="Knockback" and b.reactionVelocity.Y<20)
end)
test("active window late entry, whiff recovery and combo buffer",function()
 local c,a,b=pair();b.root.CFrame=C.new(0,3,-20)
 assert(c:request(a,"Attack"));step(c,.12);assert(b.health==b.def.Health)
 b.root.CFrame=C.new(a.root.Position+a.root.CFrame.LookVector*3);step(c,.03);assert(b.health<b.def.Health)
 -- The swing connected, so the next press is buffered and chains on recovery.
 assert(c:request(a,"Attack"));step(c,.4)
 assert(a.attackName=="Light2" and a.combo==2,"connected light did not chain")
 -- A pause ends the string (CORE_COMBAT_CONVERGENCE_2 §1): the next press is
 -- an opener again, not the third light of a string the player let go.
 b.root.CFrame=C.new(0,3,-30);step(c,.6)
 local health=b.health
 assert(c:request(a,"Attack"));assert(a.attackName=="Light1","a press after a pause continued the string ("..tostring(a.attackName)..")")
 -- An early press may be held in the buffer: a whiff never chains it, it comes
 -- out as a fresh opener once the whole recovery is over.
 local ok,reason=c:request(a,"Attack")
 assert(not ok or reason=="Buffered","whiffed swing accepted a chain")
 step(c,.5)
 assert(b.health==health and not a.chainOpen,"whiff produced a contact or a chain")
 assert(a.combo==0,"a whiff advanced the combo ("..tostring(a.combo)..")")
 assert(a.attackName==nil or a.attackName=="Light1","a buffered press after a whiff was not a fresh opener ("..tostring(a.attackName)..")")
end)
test("grab, directional throw, no orphan relationship and upthrow",function()
 local c,a,b=pair();assert(c:request(a,"Grab"));step(c,.23)
 assert(a.grabVictim==b and b.grabbedBy==a and not c:request(b,"Attack"))
 a.move=V.xAxis;assert(c:request(a,"Attack"));step(c,.2)
 assert(not a.grabVictim and not b.grabbedBy and b.reaction=="Knockdown" and b.reactionVelocity.X>20)
 local x,y,z=pair();assert(x:request(y,"Grab"));step(x,.23);assert(x:request(y,"Heavy"));step(x,.2);assert(z.reaction=="Launched")
end)
test("escape legality and reaction independent of aerial action",function()
 local c,a,b=pair();assert(not c:request(b,"Substitute"));assert(c:request(a,"Attack"));step(c,.16)
 assert(b.reaction=="HitStun");assert(c:request(b,"Dodge"));assert(b.subCharges==1 and not b.reaction)
 b.subCharges=0;b.state="Stunned";b.lastHurt=c.now;assert(not c:request(b,"Substitute"))
 local x,y,z=pair();assert(x:request(y,"Grab"));step(x,.23);assert(x:request(z,"Substitute"));assert(not y.grabVictim and not z.grabbedBy)
end)
test("death and reset clear launch, grab, buffer and chase",function()
 local c,a,b=pair();assert(c:request(a,"Grab"));step(c,.23);a.buffered={};a.pursuitUntil=110
 c:damage(b,a,1000,false,false)
 assert(c.match.phase=="Result" and not a.grabVictim and not b.grabbedBy and not b.reaction and not a.buffered and a.pursuitUntil==0)
end)
test("every semantic action has controller mapping; tutorial cannot skip success",function()
 for name,key in Controls.Gamepad do
  assert(typeof(key)=="EnumItem","gamepad mapping missing for "..name)
 end
 for name,key in Controls.Keyboard do
  assert(typeof(key)=="EnumItem" and type(key.Name)=="string","keyboard mapping missing for "..name)
 end
 local c,a,b=pair();local s=c.match;s.combat=c;s.human=a;s.bot=b;s.ai={update=function() end};Tutorial.new(s)
 Tutorial.update(s,100,.02);assert(s.tutorial.index==1)
 for _=1,4 do a.root.CFrame+=V.new(4,0,0);Tutorial.update(s,100.02,.02) end
 Tutorial.update(s,100.4,.02);assert(s.tutorial.index==2)
end)
test("tutorial launcher-to-slam objectives observe completed real actions",function()
 local c,a,b=pair();local s=c.match;s.combat=c;s.human=a;s.bot=b;s.ai={update=function() end}
 Tutorial.new(s);s.tutorial.index=8;Tutorial.enter(s,c.now)
 local function tick(time)
  for _=1,math.ceil(time/.01) do c:update(.01,c.now+.01);Tutorial.update(s,c.now,.01) end
 end
 assert(c:request(a,"Attack"));tick(.3);assert(c:request(a,"Attack"));tick(.3)
 assert(c:request(a,"Heavy"));tick(.45);assert(s.tutorial.index==9)
 assert(c:request(a,"Pursuit"));tick(.05);assert(s.tutorial.index==9,"Chase start incorrectly completed objective")
 tick(.45);assert(s.tutorial.index==10)
 assert(c:request(a,"Attack"));tick(.28);assert(c:request(a,"Attack"));tick(.5);assert(s.tutorial.index==11)
 assert(c:request(a,"Heavy"));tick(.45);assert(s.tutorial.index==12)
end)
test("guarded Fire costs stamina and interruptible channel cannot release",function()
 local c,a,b=pair();a,b=b,a
	 assert(c:request(b,"Guard"));local health=b.health;local stamina=b.stamina
 assert(c:request(a,"Technique4",b.root.Position));step(c,.6)
	 assert(b.health<health and health-b.health<4 and b.stamina<stamina)
 local x,y,z=pair();assert(x:request(z,"Technique4",y.root.Position));x:damage(y,z,7,false,true);step(x,1)
 assert(#x.hazards==0 and z.pending==nil and not x:request(z,"Technique4"))
end)
test("Velmora parry and perfect dodge create punish windows",function()
 local c,a,b=pair();local health=b.health
 assert(c:request(b,"Guard"));assert(not c:damage(a,b,8,false,true))
 assert(b.health==health and a.state=="Stunned" and b.events.Parry==1)
 local x,y,z=pair();local dodgeHealth=z.health
 assert(x:request(z,"Dodge"));assert(not x:damage(y,z,8,false,true))
 assert(z.health==dodgeHealth and z.bonusUntil>x.now and z.events.Evaded==1)
 local guard,u,v=pair();v.stamina=.1;assert(guard:request(v,"Guard"));step(guard,.02)
 assert(v.state=="Stunned" and v.cue=="GUARD EXHAUSTED")
end)
test("actual controller callbacks cover branches, sticks, modifiers and release",function()
 local Input=loadModule("Client/Input");local sent={};local state={phase="Duel",human={pursuit=0}};local camera={look=roblox.Vector2.zero}
 local input=Input.new(function(action) table.insert(sent,action) end,function() return state end,function() table.insert(sent,"Lock") end,camera)
 local function press(name,key,mode,position)
  local isMouse=key:match("^Mouse")
  local code=if isMouse then roblox.Enum.UserInputType[key] else roblox.Enum.KeyCode[key]
  return bindings["Ninja"..name].callback("Ninja"..name,mode or roblox.Enum.UserInputState.Begin,
   {KeyCode=code,UserInputType=if isMouse then code else roblox.Enum.UserInputType.Keyboard,Position=position or (if key=="ButtonL2" or key=="ButtonR2" then V.new(0,0,1) else V.zero)})
 end
 press("Light","ButtonX");assert(sent[#sent]=="Attack")
 press("Heavy","ButtonY");assert(sent[#sent]=="Heavy")
 press("Modifier","ButtonR1");press("Jump","ButtonA");assert(sent[#sent]=="Technique1")
 press("Light","ButtonX",roblox.Enum.UserInputState.End);press("Light","ButtonX");assert(sent[#sent]=="Technique2")
 press("Heavy","ButtonY",roblox.Enum.UserInputState.End);press("Heavy","ButtonY");assert(sent[#sent]=="Technique3")
 press("Dodge","ButtonB");assert(sent[#sent]=="Technique4")
 press("Technique5","DPadUp");assert(sent[#sent]=="Technique5")
 press("Modifier","ButtonR1",roblox.Enum.UserInputState.End)
 state.human.pursuit=1;press("Jump","ButtonA",roblox.Enum.UserInputState.End);press("Jump","ButtonA");assert(sent[#sent]=="PadJump","× is the server-decided chase-or-jump (audit 29/10)")
 press("Guard","ButtonL1");assert(sent[#sent]=="Guard")
 press("Guard","ButtonL1",roblox.Enum.UserInputState.End);assert(sent[#sent]=="GuardOff")
 press("Tool","ButtonR2");assert(sent[#sent]=="Tool")
 press("Sprint","ButtonL3");assert(input.sprinting)
 -- Keyboard side of the remap: the physical keys must reach the same semantics.
 press("Dodge","Q");assert(sent[#sent]=="Dodge","Q is not dodge")
 press("Guard","F");assert(sent[#sent]=="Guard","F is not guard")
 press("Guard","F",roblox.Enum.UserInputState.End);assert(sent[#sent]=="GuardOff")
 press("Grab","V");assert(sent[#sent]=="Grab","V is not grab")
 press("Tool","R");assert(sent[#sent]=="Tool","R is not tool")
 press("PursuitKey","E");assert(sent[#sent]=="Pursuit","E is not pursuit")
 press("SubstituteKey","X");assert(sent[#sent]=="Substitute","X is not substitution")
 state.human.pursuit=0
 press("Jump","Space");assert(sent[#sent]=="Jump","SPACE is not jump")
 press("Heavy","MouseButton2");assert(sent[#sent]=="Heavy","RMB is not heavy")
 press("Light","MouseButton1");assert(sent[#sent]=="Attack","LMB is not light")
 press("MoveStick","Thumbstick1",roblox.Enum.UserInputState.Change,V.new(0,1,0))
 assert(input:direction({CFrame=C.new()}).Z<-.9)
 press("LookStick","Thumbstick2",roblox.Enum.UserInputState.Change,V.new(.7,0,0));assert(camera.look.X>.6)
 input:reset();assert(camera.look.Magnitude==0 and input.stick.Magnitude==0 and not input.sprinting)
 state.phase="Selection";assert(press("Jump","ButtonA")==roblox.Enum.ContextActionResult.Pass,"Menu activation was consumed by combat")
end)
test("imported Bangla combo owns damage, contacts, effects and cleanup",function()
 local c,a,b=pair();local health=b.health;local emits=effectEmits
 assert(c:request(a,"Attack"));step(c,.3)
 assert(health-b.health==5 and a.model:GetAttribute("CombatBase")=="BanglaBattlegrounds")
 assert(a.donorHitCount==1 and effectEmits>emits)
 -- A press on the beat is a Flow strike (Config.Flow.Damage = x1.15).
 local function flowScale() return if a.pending and a.pending.flow then 1.15 else 1 end
 health=b.health;assert(c:request(a,"Attack"));local f2=flowScale();step(c,.3);assert(math.abs(health-b.health-10*f2)<.01,"second hit "..(health-b.health))
 -- The third hit (MegaPunch 18) is scaled by Config.ComboScaling: 18 * 0.88.
 health=b.health;assert(c:request(a,"Attack"));local f3=flowScale();step(c,.3);assert(math.abs(health-b.health-15.84*f3)<.01,"third hit not scaled: "..(health-b.health))
 -- The third hit ends the string: nothing left to continue, no chain.
 assert(a.attackName=="Light3" and a.combo==0 and not a.chainOpen)
 -- The next press opens a new string; it counts once it connects.
 step(c,.5);assert(c:request(a,"Attack") and a.attackName=="Light1" and a.combo==0)
 c:clear();assert(a.combo==0 and not a.pending and a.donorHitCount==0)
end)
test("Place1 sprint stamina, takeoff carry and air steering run on actors",function()
 local Motor=loadModule("Server/Motor")
 local c,a,b=pair();a.move=V.xAxis;a.sprinting=true
 -- Sprinting runs where the body faces (a side step is slower).
 a.root.CFrame=C.lookAt(a.root.Position,a.root.Position+V.xAxis)
 Motor.step(a,c,.1,c.now)
 assert(a.hum.WalkSpeed>40 and a.model:GetAttribute("MovementBase")=="Place1")
 assert(a.model:GetAttribute("MovementStamina")<1)
 assert(Motor.jump(a,c,c.now))
 assert(a.root.AssemblyLinearVelocity.X>=62 and a.root.AssemblyLinearVelocity.Y>=60)
 a.root.CFrame=C.new(0,10,0);a.hum.FloorMaterial=roblox.Enum.Material.Air
 a.move=V.zAxis;c.now+=.2
 local speed=a.root.AssemblyLinearVelocity.Magnitude;local previousX=a.root.AssemblyLinearVelocity.X
 Motor.step(a,c,.1,c.now)
 assert(a.root.AssemblyLinearVelocity.Z>0 and a.root.AssemblyLinearVelocity.X<previousX)
 assert(a.root.AssemblyLinearVelocity.Magnitude<=speed+10)
 a.root.CFrame=C.lookAt(V.new(0,3,0),V.new(0,3,1));a.hum.FloorMaterial=roblox.Enum.Material.Concrete
 for _=1,610 do c.now+=.1;Motor.step(a,c,.1,c.now) end
 assert(a.hum.WalkSpeed==a.def.Speed,"Exhausted sprint failed to drop to walk")
 c:clear();assert(not a.movementDonor and not a.parkourDonor)
end)
test("Place1 mantle clearance, arc, state cancellation and wall-hop limits",function()
 local Parkour=loadModule("Server/Place1Parkour")
 local c,a,b=pair();a.root.CFrame=C.lookAt(V.new(0,3,0),V.new(1,3,0));a.move=V.xAxis
 local oldRay,oldBox=workspace.Raycast,workspace.GetPartBoundsInBox
 local wall={Anchored=true,CanCollide=true,Parent=nil,IsA=function(_,class) return class=="BasePart" end,GetAttribute=function() return nil end,GetFullName=function() return "Ledge" end}
 local top=table.clone(wall)
 workspace.Raycast=function(_,origin,delta)
  if delta.Y<0 and origin.Y>5 then return {Instance=top,Position=V.new(origin.X,4,origin.Z),Normal=V.yAxis,Distance=origin.Y-4} end
  if math.abs(delta.X)>1 then return {Instance=wall,Position=V.new(2,origin.Y,origin.Z),Normal=-V.xAxis,Distance=2} end
  if delta.Y<0 then return {Instance=ground,Position=V.new(origin.X,0,origin.Z),Normal=V.yAxis,Distance=origin.Y} end
 end
 workspace.GetPartBoundsInBox=function() return {} end
 local p=Parkour.new(a,c);assert(p.jump())
 assert(a.model:GetAttribute("MovementTraversalActive"))
 local start=a.root.Position;c.now+=.15;assert(p.step());assert(a.root.Position.Y>start.Y)
 c.now+=.4;p.step();assert(not a.model:GetAttribute("MovementTraversalActive") and a.root.Position.Y>6)
 -- A fresh mantle is cancelled immediately by a combat reaction.
 p.reset();a.root.CFrame=C.lookAt(V.new(0,3,0),V.new(1,3,0));c.now+=.5
 assert(p.jump());a.reaction="HitStun";p.step();assert(not a.model:GetAttribute("MovementTraversalActive"))
 assert(a.hum:GetState()~=roblox.Enum.HumanoidStateType.Physics,"Cancelled mantle retained Physics state")
 a.reaction=nil;a.hum.FloorMaterial=roblox.Enum.Material.Air
 c.now+=.2;assert(p.rebound(-V.xAxis));assert(a.root.AssemblyLinearVelocity.Y==64)
 c.now+=.2;assert(p.rebound(-V.xAxis));c.now+=.2;assert(not p.rebound(-V.xAxis))
 workspace.Raycast,workspace.GetPartBoundsInBox=oldRay,oldBox
end)
test("Bangla evade remains directional, bounded by collision and finite",function()
 local Evade=loadModule("Server/BanglaEvade");local Motor=loadModule("Server/Motor")
 local c,a,b=pair();a.move=V.xAxis;local start=a.root.Position
 Evade.begin(a,c);c.now+=.16;Evade.step(a,c,Motor.travel)
 assert(a.root.Position.X>start.X+3 and a.root.Position.X<start.X+20)
 c.now+=.2;Evade.step(a,c,Motor.travel);assert(not a.evade)
 local old=workspace.Raycast
 workspace.Raycast=function(_,origin,delta) return {Distance=2,Position=origin+delta.Unit*2,Normal=-delta.Unit,Instance=ground} end
 local before=a.root.Position;Evade.begin(a,c);c.now+=.1;Evade.step(a,c,Motor.travel)
 assert((a.root.Position-before).Magnitude<.01,"Evade crossed blocking geometry")
 workspace.Raycast=old
end)
test("R6 donor retarget preserves timing, neutral limb bases and R15 hierarchy",function()
 local factory=envBase.Instance;envBase.Instance=roblox.Instance
 local Donor=loadModule("Server/DonorAnimations")
 local frames={}
 for _,time in {0,.3} do
  local key=roblox.Instance.new("Keyframe");key.Name="Frame";key.Time=time
  local root=roblox.Instance.new("Pose");root.Name="HumanoidRootPart";root.CFrame=C.identity;root.Weight=0;root.Parent=key
  local torso=roblox.Instance.new("Pose");torso.Name="Torso";torso.CFrame=C.identity;torso.Weight=1;torso.Parent=root
  local arm=roblox.Instance.new("Pose");arm.Name="Right Arm";arm.CFrame=C.identity;arm.Weight=1;arm.EasingStyle=roblox.Enum.PoseEasingStyle.Linear;arm.EasingDirection=roblox.Enum.PoseEasingDirection.In;arm.Parent=torso
  table.insert(frames,key)
 end
 local seq={Name="Punch",Loop=false,Priority=roblox.Enum.AnimationPriority.Action,GetKeyframes=function() return frames end}
 local r15=Donor.retarget(seq)
 assert(#r15:GetChildren()==2)
 for i,key in r15:GetChildren() do
  assert(key.Time==frames[i].Time)
  local lower=key.HumanoidRootPart.LowerTorso
  local arm=lower.UpperTorso.RightUpperArm
  assert(arm.CFrame:FuzzyEq(C.identity,1e-5))
 end
 r15:Destroy();for _,frame in frames do frame:Destroy() end
 envBase.Instance=factory
end)
test("fighter choreography differs across eight attacks and resets all joints",function()
 local Motion=loadModule("Client/VelmoraMotionEngine")
 local function rig()
  local joints={}
  local model={FindFirstChild=function(_,part)
   return {FindFirstChild=function(_,name)
    joints[name]=joints[name] or {Transform=C.identity,IsA=function() return true end}
    return joints[name]
   end}
  end}
  return model,joints
 end
 local a,aj=rig();local b,bj=rig()
 for _,name in {"Light1","Light2","Light3","Launcher","DashAttack","Air1","Air2","Slam"} do
  Motion.pose(a,name,.16,"Flashstep");Motion.pose(b,name,.16,"Mirage")
  local different=0
  for key,joint in aj do if not joint.Transform:FuzzyEq(bj[key].Transform,.03) then different+=1 end end
  assert(different>=5,name.." lacks distinct full-body choreography")
  Motion.clear(a)
  for _,joint in aj do assert(joint.Transform:FuzzyEq(C.identity,1e-5),"Stale attack joint") end
 end
end)
print("NinjaDuel headless combat/migration: "..passed.." PASS (geometry adapter; native QA still required)")
