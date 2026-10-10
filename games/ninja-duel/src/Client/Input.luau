local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Controls=require(game:GetService("ReplicatedStorage").NinjaDuel.Controls)
local Input={};Input.__index=Input
function Input.new(send,getState,toggleLock,camera)
 local self=setmetatable({send=send,getState=getState,keys={},stick=Vector2.zero,look=Vector2.zero,sprinting=false,modifier=false,camera=camera},Input)
 local function bind(name,keys,callback)
  CAS:BindActionAtPriority("Ninja"..name,function(_,state,object)
   if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
   if getState().phase~="Duel" then return Enum.ContextActionResult.Pass end
   callback(state,object)
   return Enum.ContextActionResult.Sink
  end,false,3000,table.unpack(keys))
 end
 local function begin(state) return state==Enum.UserInputState.Begin end
 for _,key in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
  bind(key.Name,{key},function(state) self.keys[key.Name]=begin(state) end)
 end
 bind("MoveStick",{Enum.KeyCode.Thumbstick1},function(state,obj)
  self.stick=if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
 end)
 bind("LookStick",{Enum.KeyCode.Thumbstick2},function(state,obj)
  self.look=if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
  camera.look=self.look
 end)
 bind("Modifier",Controls.Modifier,function(state) self.modifier=begin(state) end)
 local function face(state,normal,slot)
  if begin(state) then send(if self.modifier then "Technique"..slot else normal) end
 end
 bind("Light",Controls.Light,function(state) face(state,"Attack",2) end)
 bind("Heavy",Controls.Heavy,function(state) face(state,"Heavy",3) end)
 bind("Dodge",Controls.Dodge,function(state) face(state,"Dodge",4) end)
 bind("Jump",Controls.Jump,function(state)
  if begin(state) then
   local h=getState().human
   face(state,if h and h.pursuit>0 then "Pursuit" else "Jump",1)
  elseif state==Enum.UserInputState.End then send("JumpOff") end
 end)
 bind("Guard",Controls.Guard,function(state) send(if begin(state) then "Guard" else "GuardOff") end)
 bind("Tool",Controls.Tool,function(state) if begin(state) then send("Tool") end end)
 bind("Grab",Controls.Grab,function(state) if begin(state) then send(if self.modifier then "Feint" else "Grab") end end)
 bind("Lock",Controls.Lock,function(state) if begin(state) then toggleLock() end end)
 bind("Sprint",Controls.Sprint,function(state,obj)
  if obj.KeyCode==Enum.KeyCode.ButtonL3 then if begin(state) then self.sprinting=not self.sprinting end
  else self.sprinting=begin(state) end
 end)
 bind("Technique5",Controls.Technique5,function(state) if begin(state) then send("Technique5") end end)
 bind("Skip",Controls.Skip,function(state) if begin(state) and getState().tutorial then send("TutorialSkip") end end)
 for i,key in {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four} do
  bind("Technique"..i,{key},function(state) if begin(state) then send("Technique"..i) end end)
 end
 for name,key in {Substitute=Enum.KeyCode.X,WallDetach=Enum.KeyCode.C,Feint=Enum.KeyCode.G,Pursuit=Enum.KeyCode.E} do
  bind(name,{key},function(state) if begin(state) then send(name) end end)
 end
 UIS.WindowFocusReleased:Connect(function() self:reset();send("GuardOff");send("Move",Vector3.zero) end)
 return self
end
function Input:reset()
 table.clear(self.keys);self.stick=Vector2.zero;self.look=Vector2.zero;self.modifier=false;self.sprinting=false;self.camera.look=Vector2.zero
end
function Input:direction(camera)
 local stick=if self.stick.Magnitude>.15 then self.stick else Vector2.zero
 local x=stick.X+(if self.keys.D then 1 else 0)-(if self.keys.A then 1 else 0)
 local z=stick.Y+(if self.keys.W then 1 else 0)-(if self.keys.S then 1 else 0)
 local look=camera.CFrame.LookVector*Vector3.new(1,0,1)
 if look.Magnitude<.01 then look=-Vector3.zAxis end
 local right=Vector3.new(-look.Unit.Z,0,look.Unit.X)
 local v=right*x+look.Unit*z
 return if v.Magnitude>1 then v.Unit else v
end
return Input
