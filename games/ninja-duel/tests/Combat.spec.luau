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
local names={}
for _,dir in {"Shared","Server","Client"} do
 names[dir]={}
 for _,file in fs.readDir("games/ninja-duel/src/"..dir) do if file:match("%.luau$") then local name=file:gsub("%.luau$","");names[dir][name]=dir.."/"..name end end
end
local cached={["Server/World"]=World};local loadModule
local envBase={Vector3=V,Vector2=roblox.Vector2,CFrame=C,Color3=roblox.Color3,Enum=roblox.Enum,workspace=workspace,
 RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end}}
local bindings={}
local inputServices={
 ContextActionService={BindActionAtPriority=function(_,name,callback,_,_,...) bindings[name]={callback=callback,keys={...}} end},
 UserInputService={GetFocusedTextBox=function() return nil end,WindowFocusReleased={Connect=function() end}},
}
envBase.game={GetService=function(_,name)
 if name=="ReplicatedStorage" then return {NinjaDuel=names.Shared} end
 if inputServices[name] then return inputServices[name] end
 error("Unexpected service "..name)
end}
loadModule=function(path)
 if cached[path] then return cached[path] end
 local fn=assert(loadstring(fs.readFile("games/ninja-duel/src/"..path..".luau"),path))
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
  local model={root=root,Parent=true};function model:PivotTo(cf) self.root.CFrame=cf end
  local hum={Health=125,WalkSpeed=0,FindFirstChildOfClass=function() return nil end,Move=function() end}
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
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name) end
test("ground branch, real launch, 3D chase, two air hits, slam and wakeup",function()
 local c,a,b=pair();c.match.techniquesDisabled=true
 assert(not c:request(a,"Technique1"))
 for _=1,3 do assert(c:request(a,"Attack"));step(c,.3) end
 assert(c:request(a,"Heavy"));step(c,.35);assert(b.reaction=="Launched" and b.root.Position.Y>8)
 assert(c:request(a,"Pursuit"));step(c,.25)
 assert((a.root.Position-b.root.Position).Magnitude<8)
 assert(c:request(a,"Attack"));step(c,.28);assert(b.reaction=="Juggled")
 assert(c:request(a,"Attack"));step(c,.29);assert(a.events.AirHit==2)
 assert(c:request(a,"Heavy"));step(c,.4);assert(b.reaction=="Knockdown" and a.events.SlamHit==1)
 step(c,1.1);assert(b.reaction==nil);assert(not c:request(a,"Pursuit"))
end)
test("horizontal finisher differs from launcher",function()
 local c,a,b=pair()
 for _=1,4 do assert(c:request(a,"Attack"));step(c,.3) end
 assert(a.attackName=="Light4" and b.reaction=="Knockback" and b.reactionVelocity.Y<20)
end)
test("active window late entry, whiff recovery and combo buffer",function()
 local c,a,b=pair();b.root.CFrame=C.new(0,3,-20)
 assert(c:request(a,"Attack"));step(c,.12);assert(b.health==b.def.Health)
 b.root.CFrame=C.new(a.root.Position+a.root.CFrame.LookVector*5);step(c,.03);assert(b.health<b.def.Health)
 assert(not c:request(a,"Attack"));step(c,.14);assert(a.attackName=="Light2")
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
 for name,keys in Controls do
  local pad=false;for _,key in keys do if key.Name:match("^Button") or key.Name:match("^DPad") then pad=true end end
  assert(pad,name)
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
test("guarded Fire costs resources and interruptible channel cannot release",function()
 local c,a,b=pair();a,b=b,a
 assert(c:request(b,"Guard"));local health=b.health;local chakra=b.chakra
 assert(c:request(a,"Technique4",b.root.Position));step(c,.6)
 assert(b.health<health and health-b.health<4 and b.chakra<chakra)
 local x,y,z=pair();assert(x:request(z,"Technique4",y.root.Position));x:damage(y,z,7,false,true);step(x,1)
 assert(#x.hazards==0 and z.pending==nil and not x:request(z,"Technique4"))
end)
test("actual controller callbacks cover branches, sticks, modifiers and release",function()
 local Input=loadModule("Client/Input");local sent={};local state={phase="Duel",human={pursuit=0}};local camera={look=roblox.Vector2.zero}
 local input=Input.new(function(action) table.insert(sent,action) end,function() return state end,function() table.insert(sent,"Lock") end,camera)
 local function press(name,key,mode,position)
  return bindings["Ninja"..name].callback("Ninja"..name,mode or roblox.Enum.UserInputState.Begin,{KeyCode=roblox.Enum.KeyCode[key],Position=position or V.zero})
 end
 press("Light","ButtonX");assert(sent[#sent]=="Attack")
 press("Heavy","ButtonY");assert(sent[#sent]=="Heavy")
 press("Modifier","ButtonR1");press("Jump","ButtonA");assert(sent[#sent]=="Technique1")
 press("Light","ButtonX");assert(sent[#sent]=="Technique2")
 press("Heavy","ButtonY");assert(sent[#sent]=="Technique3")
 press("Dodge","ButtonB");assert(sent[#sent]=="Technique4")
 press("Technique5","DPadUp");assert(sent[#sent]=="Technique5")
 press("Modifier","ButtonR1",roblox.Enum.UserInputState.End)
 state.human.pursuit=1;press("Jump","ButtonA");assert(sent[#sent]=="Pursuit")
 press("Grab","ButtonL2");assert(sent[#sent]=="Grab")
 press("Guard","ButtonL1");assert(sent[#sent]=="Guard")
 press("Guard","ButtonL1",roblox.Enum.UserInputState.End);assert(sent[#sent]=="GuardOff")
 press("Tool","ButtonR2");assert(sent[#sent]=="Tool")
 press("Sprint","ButtonL3");assert(input.sprinting)
 press("MoveStick","Thumbstick1",roblox.Enum.UserInputState.Change,V.new(0,1,0))
 assert(input:direction({CFrame=C.new()}).Z<-.9)
 press("LookStick","Thumbstick2",roblox.Enum.UserInputState.Change,V.new(.7,0,0));assert(camera.look.X>.6)
 input:reset();assert(camera.look.Magnitude==0 and input.stick.Magnitude==0 and not input.sprinting)
 state.phase="Selection";assert(press("Jump","ButtonA")==roblox.Enum.ContextActionResult.Pass,"Menu activation was consumed by combat")
end)
print("NinjaDuel headless combat: "..passed.." PASS (geometry adapter; native QA still required)")
