-- Shared headless harness for Ninja Duel specs (Lune).
-- Loads the real src/ modules into a stubbed Roblox environment so combat,
-- movement, animations, camera and feedback policy can be replayed deterministically.
-- It proves timing/state, NOT Studio physics, rendering or controller hardware.
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local V=roblox.Vector3
-- Lune 0.10.5 lookAt reverses facing relative to Roblox; use explicit basis.
local C=setmetatable({}, {__index=roblox.CFrame})
function C.lookAt(from,to)
 local forward=(to-from).Unit;local right=forward:Cross(V.yAxis).Unit;local up=right:Cross(forward)
 return roblox.CFrame.fromMatrix(from,right,up,-forward)
end
local Harness={roblox=roblox,V=V,C=C,effectEmits=0,stepDelta=1/60}
local JOINT_NAMES={"Root","Waist","Neck","LeftShoulder","RightShoulder","LeftElbow","RightElbow","LeftHip","RightHip","LeftKnee","RightKnee","LeftAnkle","RightAnkle"}
Harness.JOINT_NAMES=JOINT_NAMES
-- Which bone owns each Motor6D, so MotionEngine's part->joint lookup resolves.
local JOINT_HOST={Root="HumanoidRootPart",Waist="LowerTorso",Neck="UpperTorso",LeftShoulder="UpperTorso",RightShoulder="UpperTorso",
 LeftElbow="LeftUpperArm",RightElbow="RightUpperArm",LeftHip="LowerTorso",RightHip="LowerTorso",
 LeftKnee="LeftUpperLeg",RightKnee="RightUpperLeg",LeftAnkle="LeftLowerLeg",RightAnkle="RightLowerLeg"}
Harness.JOINT_HOST=JOINT_HOST

local function fakePart(position)
 local p={CFrame=C.new(position or V.zero),AssemblyLinearVelocity=V.zero,Parent=true,CanCollide=true,Transparency=0,
  Size=V.one,Anchored=false,Massless=false,CanQuery=true,CanTouch=true,Name="Part",Shape=roblox.Enum.PartType.Block,
  Material=roblox.Enum.Material.Plastic,Color=roblox.Color3.new(1,1,1)}
 p.children={}
 setmetatable(p,{__index=function(t,k) if k=="Position" then return t.CFrame.Position end end})
 function p:Destroy() self.Parent=nil end
 function p:IsA(class) return class=="Part" or class=="BasePart" or class==self.ClassName end
 p.attributes={}
 function p:GetAttribute(key) return self.attributes[key] end
 function p:SetAttribute(key,value) self.attributes[key]=value end
 function p:IsDescendantOf(other)
  local cursor=self
  while type(cursor)=="table" do
   if cursor==other then return true end
   cursor=cursor.Parent
  end
  return false
 end
 function p:FindFirstChild() return nil end
 function p:FindFirstChildOfClass() return nil end
 function p:GetChildren() return self.children end
 function p:FindFirstChildOfClass(class)
  for _,child in self.children do if child:IsA(class) then return child end end
  return nil
 end
 return p
end
Harness.fakePart=fakePart

-- Real BasePart stand-in for the floor so attribute/descendant APIs behave.
local groundPart=fakePart(V.new(0,-1,0))
groundPart.Name="Ground";groundPart.Size=V.new(300,2,300);groundPart.Anchored=true
local function newGround() return groundPart end
-- Shared world stub: raycasts return real ground at Y=0 so grounded logic works.
local workspace={Gravity=140}
Harness.workspace=workspace
-- Floor plane at y=0. A swept ray answers when the body's swept extent reaches
-- the plane, matching how the real arena floor stops a descending root.
local FLOOR_REACH=1.9
-- Optional vertical walls for wall-combat specs: planes x = X facing -X.
Harness.walls={}
function Harness.addWall(x)
 local part=fakePart(V.new(x+1,20,0));part.Name="Boundary";part.Size=V.new(2,40,400);part.Anchored=true
 part.attributes.NinjaWall=true
 table.insert(Harness.walls,{x=x,part=part})
 return part
end
function Harness.clearWalls() table.clear(Harness.walls) end
local floorRaycast
function workspace:Raycast(origin,delta,params)
 local floor=floorRaycast(origin,delta,params)
 for _,w in Harness.walls do
  if delta.X>0 and origin.X<=w.x and origin.X+delta.X>=w.x then
   local t=(w.x-origin.X)/delta.X
   local hit={Position=origin+delta*t,Normal=-V.xAxis,Distance=(delta*t).Magnitude,Instance=w.part}
   if not floor or hit.Distance<floor.Distance then floor=hit end
  end
 end
 return floor
end
function floorRaycast(origin,delta,params)
 if delta.Y<0 and origin.Y+delta.Y<FLOOR_REACH then
  local travel=math.max(0,origin.Y-FLOOR_REACH)
  local t=math.min(1,travel/ -delta.Y)
  return {Position=origin+delta*t,Normal=V.yAxis,Distance=(delta*t).Magnitude,Instance=newGround()}
 end
 if delta.Y<0 and origin.Y<=FLOOR_REACH then
  return {Position=origin,Normal=V.yAxis,Distance=0,Instance=newGround()}
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
function workspace:FindFirstChild() return nil end
workspace.CurrentCamera=nil

local function emitter() return {IsA=function(_,class) return class=="ParticleEmitter" end,GetAttribute=function() return 4 end,Emit=function(_,count) Harness.effectEmits+=count end} end
local function attachment() return {Clone=function() return attachment() end,GetChildren=function() return {emitter()} end,Parent=nil} end
local assets={VFX={BasicPunch={Attachment=attachment()},ComboPunch={Attachment=attachment()}}}
-- Source root resolution: Lune runs with the repository as cwd, but the same
-- specs must also work from the game folder.
local SRC
for _,candidate in {"games/ninja-duel/src","src"} do
 if fs.isDir(candidate) then SRC=candidate break end
end
assert(SRC,"Could not locate ninja-duel src; run lune from the repository root or games/ninja-duel")
Harness.srcRoot=SRC
local sharedStub
local names={}
for _,dir in {"Shared","Server","Client"} do
 names[dir]={}
 for _,file in fs.readDir(SRC.."/"..dir) do
  if file:match("%.luau$") then local name=file:gsub("%.luau$","");names[dir][name]=dir.."/"..name end
 end
end
Harness.names=names

-- Sound stub records every played SoundId so feedback wiring is auditable.
local sounds={}
Harness.sounds=sounds
local function soundInstance()
 local s={SoundId="",Volume=0,PlaybackSpeed=1,Name="Sound",Parent=nil,Playing=false}
 function s:Play() self.Playing=true;table.insert(sounds,{id=self.SoundId,volume=self.Volume,speed=self.PlaybackSpeed,parent=self.Parent}) end
 function s:Stop() self.Playing=false end
 function s:IsA(class) return class=="Sound" end
 function s:Destroy() self.Parent=nil end
 return s
end

local function newInstance(class)
 if class=="Sound" then return soundInstance() end
 if class=="Motor6D" then
  local m={ClassName="Motor6D",Name="Motor6D",Transform=C.identity,C0=C.identity,C1=C.identity,Parent=nil,Part0=nil,Part1=nil}
  function m:IsA(query) return query=="Motor6D" end
  function m:Destroy() self.Parent=nil end
  return m
 end
 if class=="Humanoid" then
  local h={ClassName="Humanoid",Health=100,MaxHealth=100,WalkSpeed=16,AutoRotate=true}
  function h:IsA(query) return query=="Humanoid" end
  return h
 end
 if class=="Animation" then
  local a={ClassName="Animation",AnimationId="",Name="Animation",Parent=nil}
  function a:IsA(query) return query=="Animation" end
  function a:Destroy() self.Parent=nil end
  return a
 end
 local obj=fakePart()
 obj.ClassName=class;obj.Name=class;obj.Children=obj.children;obj.attributes={}
 function obj:IsA(query) return query==self.ClassName or (query=="BasePart" and self.ClassName=="Part") end
 obj.children=obj.children or {}
 function obj:Play() end
 function obj:Stop() end
 function obj:AdjustSpeed() end
 function obj:GetPropertyChangedSignal() return {Connect=function() end} end
 function obj:FindFirstChildOfClass() return nil end
 function obj:GetChildren() return self.Children end
 function obj:Clone() return newInstance(class) end
 function obj:SetAttribute(k,v) self.attributes[k]=v end
 function obj:GetAttribute(k) return self.attributes[k] end
 return obj
end

local cached={}
local envBase={Vector3=V,Vector2=roblox.Vector2,CFrame=C,Color3=roblox.Color3,Enum=roblox.Enum,workspace=workspace,
 RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end},Instance={new=newInstance},
 TweenInfo={new=function(...) return {...} end},UDim2={fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end},
 Random={new=function() return {NextNumber=function(_,a,b)
  if a and b then return a+(b-a)*0.5 end
  return 0.5
 end} end}}
Harness.envBase=envBase

local function buildRig(folder,def,cf,name)
 local model=fakePart(cf.Position)
 model.CFrame=cf;model.Parent=folder;model.Name=name;model.ClassName="Model"
 model.attributes={};model.bones={};model.joints={}
 function model:SetAttribute(k,v) self.attributes[k]=v end
 function model:GetAttribute(k) return self.attributes[k] end
 function model:IsA(query) return query=="Model" or query=="Instance" end
 function model:FindFirstChild(key) return self.bones[key] end
 function model:FindFirstChildOfClass() return self.hum end
 function model:GetChildren() return {} end
 function model:PivotTo(target)
  local delta=target.Position-self.root.Position
  for _,part in self.bones do part.CFrame=part.CFrame+delta end
  self.root.CFrame=C.lookAt(self.root.Position,self.root.Position+target.LookVector)
 end
 local rootPart=fakePart(cf.Position)
 rootPart.Name="HumanoidRootPart";rootPart.Parent=model;rootPart.CanCollide=true
 function rootPart:IsDescendantOf(other) return other==model end
 model.root=rootPart;model.bones.HumanoidRootPart=rootPart
 local hum={Health=def.Health,MaxHealth=def.Health,WalkSpeed=def.Speed,Parent=model,RigType=roblox.Enum.HumanoidRigType.R15,
  HipHeight=2,AutoRotate=true,JumpPower=68,UseJumpPower=true,BreakJointsOnDeath=false,FloorMaterial=roblox.Enum.Material.Concrete,
  MoveDirection=V.zero,Died={Connect=function() end}}
 -- Stand in for humanoid locomotion: the harness has no physics solver, so a
 -- Move request advances the root by WalkSpeed. Tests must not teleport around
 -- the systems they are checking.
 function hum:Move(direction)
  self.MoveDirection=direction or V.zero
  local speed=self.WalkSpeed or 0
  if speed>0 and self.MoveDirection.Magnitude>0.01 then
   local delta=self.MoveDirection.Unit*speed*Harness.stepDelta
   rootPart.CFrame=roblox.CFrame.new(rootPart.Position+delta)*rootPart.CFrame.Rotation
  end
 end
 function hum:ChangeState(state) self.nativeState=state end
 function hum:GetState() return self.nativeState or roblox.Enum.HumanoidStateType.Running end
 function hum:FindFirstChildOfClass() return nil end
 function hum:FindFirstChild() return nil end
 function hum:IsA() return true end
 model.hum=hum
 for _,part in {"LowerTorso","UpperTorso","Head","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand",
   "LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Hair","Sash","Eyes"} do
  local p=fakePart(cf.Position);p.Name=part;p.Parent=model
  model.bones[part]=p
 end
 -- Every joint is owned by a bone, and a bone may host several joints. The
 -- lookup must answer for all of them or the motion engine silently skips joints.
 local hosts={}
 for _,joint in JOINT_NAMES do
  local m={Name=joint,Transform=C.identity,Parent=true,C0=C.identity,C1=C.identity,ClassName="Motor6D"}
  function m:IsA(class) return class=="Motor6D" end
  model.joints[joint]=m
  local hostName=JOINT_HOST[joint]
  if hostName then
   hosts[hostName]=hosts[hostName] or {}
   table.insert(hosts[hostName],m)
  end
 end
 for hostName,list in hosts do
  local host=model.bones[hostName]
  if host then
   host.FindFirstChild=function(_,key)
    for _,joint in list do if joint.Name==key then return joint end end
    return model.bones[key]
   end
  end
 end
 return model,hum,rootPart,model.joints
end
Harness.buildRig=buildRig

local loadModule
loadModule=function(path)
 if cached[path] then return cached[path] end
 local fn=assert(loadstring(fs.readFile(SRC.."/"..path..".luau"),path))
 local env=setmetatable({require=loadModule,script={Parent=names[path:match("^(%w+)/")] }},{__index=function(_,key) return envBase[key] or getfenv()[key] end})
 setfenv(fn,env);cached[path]=fn();return cached[path]
end
Harness.load=loadModule
Harness.cached=cached

local localPlayer={UserId=1,Name="QAPlayer",Character=nil,Parent=true}
function localPlayer:GetMouse() return {Hit=CFrame.new(0,3,0),Target=nil} end
local playerService={LocalPlayer=localPlayer,GetPlayers=function() return {localPlayer} end,PlayerAdded={Connect=function() end},
 PlayerRemoving={Connect=function() end},CharacterAutoLoads=true}
Harness.localPlayer=localPlayer
Harness.Players=playerService

envBase.game={GetService=function(_,name)
 if name=="ReplicatedStorage" then
  sharedStub=sharedStub or setmetatable({BanglaAssets=assets,WaitForChild=function(_,key) return assets end,BuildFingerprint={Value="headless"}},{__index=names.Shared})
  return {NinjaDuel=sharedStub}
 end
 if name=="Players" then return playerService end
 if name=="Debris" then return {AddItem=function() end} end
 if name=="RunService" then return {IsStudio=function() return false end,Heartbeat={Connect=function() end},PreSimulation={Connect=function() end},RenderStepped={Connect=function() end}} end
 if name=="TweenService" then return {Create=function() return {Play=function() end} end} end
 if name=="KeyframeSequenceProvider" then return {GetKeyframeSequenceAsync=function() error("no network") end,RegisterKeyframeSequence=function(_,s) return s end} end
 if name=="ServerStorage" then return {} end
 if name=="SoundService" then return {} end
 if name=="GuiService" then return {AutoSelectGuiEnabled=false,SelectedObject=nil} end
 if name=="StarterGui" then return {SetCoreGuiEnabled=function() end} end
 if name=="UserInputService" then
  local uis={GetFocusedTextBox=function() return nil end,WindowFocusReleased={Connect=function() end},
   TextBoxFocused={Connect=function() end},GamepadDisconnected={Connect=function() end},LastInputTypeChanged={Connect=function() end},
   InputChanged={Connect=function() end},GetLastInputType=function() return roblox.Enum.UserInputType.Keyboard end,
   IsMouseButtonPressed=function() return false end,InputBegan={Connect=function() end},InputEnded={Connect=function() end},
   MouseBehavior=roblox.Enum.MouseBehavior.Default,GetMouseLocation=function() return roblox.Vector2.zero end}
  return uis
 end
 if name=="ContextActionService" then return {BindActionAtPriority=function(_,bindName,callback,_,_,...)
  local bindings=Harness.bindings;bindings[bindName]={callback=callback,keys={...}}
 end} end
 error("Unexpected service "..name)
end}
Harness.bindings={}

-- Deterministic duel fixture: real Combat/Brawler/AI against two rigs.
function Harness.duel(first,second)
 local effects=fakePart();effects.Name="Effects";effects.children={}
 function effects:ClearAllChildren() self.children={} end
 function effects:GetChildren() return self.children end
 function effects:FindFirstChild() return nil end
 local folder=fakePart();folder.Name="Duel_1"
 folder.bones={}
 function folder:FindFirstChild(key) if key=="Effects" then return effects end return nil end
 -- The arena floor sits at the origin plane and actors stand 3 studs above it,
  -- exactly like World.arena + World.rig, so grounded and landing logic is real.
  local match={origin=V.zero,phase="Duel",effects=effects,folder=folder,events={},cues={}}
 function match.onCombatEvent(a,event) match.events[event]=(match.events[event] or 0)+1 end
 function match.onCue(a,message) table.insert(match.cues,{actor=a.id,message=message}) end
 local Combat=loadModule("Server/Combat")
 local c=Combat.new(match);c.now=100
 local fighters=loadModule("Shared/Fighters")
 local function actor(id,key,z)
  local position=V.new(0,3,z)
  local model,hum,root,joints=buildRig(folder,fighters[key],C.lookAt(position,V.new(0,3,-z)),id)
  return c:add(id,model,hum,root,joints,key)
 end
 local a,b=actor("A",first,2.5),actor("B",second,-2.5)
 a.target=b;b.target=a
 -- Face each other explicitly: the fixture must not depend on CFrame quirks.
 a.root.CFrame=C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=C.lookAt(b.root.Position,a.root.Position)
 match.finish=function(winner) match.phase="Result";match.winner=winner.id;c:clear() end
 return c,a,b,match
end

function Harness.step(c,time)
 for _=1,math.max(1,math.ceil(time/.01)) do c:update(.01,c.now+.01) end
end

Harness.fighters=loadModule("Shared/Fighters")
Harness.Attacks=loadModule("Shared/Attacks")
return Harness
