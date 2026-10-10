local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Controls=require(game:GetService("ReplicatedStorage").NinjaDuel.Controls)
local Input={};Input.__index=Input
-- One binding per semantic action, keyboard and gamepad declared together. The
-- keyboard side keeps combat on the WASD home row; the gamepad side is unchanged.
local KEYBOARD, GAMEPAD = Controls.Keyboard, Controls.Gamepad
local function key(keyCode) return {keyCode} end
local function both(action) return {KEYBOARD[action],GAMEPAD[action]} end
function Input.new(send,getState,toggleLock,camera)
 local self=setmetatable({send=send,getState=getState,keys={},stick=Vector2.zero,look=Vector2.zero,
  sprinting=false,modifier=false,camera=camera,pad=false},Input)
 local function bind(name,keys,callback)
  local list={}
  for _,input in keys do if input then table.insert(list,input) end end
  CAS:BindActionAtPriority("Ninja"..name,function(_,state,object)
   if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
   if getState().phase~="Duel" then return Enum.ContextActionResult.Pass end
   callback(state,object)
   return Enum.ContextActionResult.Sink
  end,false,3000,table.unpack(list))
 end
 local function begin(state) return state==Enum.UserInputState.Begin end
 for _,input in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
  bind(input.Name,key(input),function(state) self.keys[input.Name]=begin(state) end)
 end
 bind("MoveStick",key(Enum.KeyCode.Thumbstick1),function(state,obj)
  self.stick=if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
 end)
 bind("LookStick",key(Enum.KeyCode.Thumbstick2),function(state,obj)
  self.look=if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
  camera.look=self.look
 end)
 -- Gamepad modifier only: RB + face button selects a technique.
 bind("Modifier",key(GAMEPAD.Modifier),function(state) self.modifier=begin(state) end)
 local function face(state,normal,slot)
  if begin(state) then send(if self.modifier then "Technique"..slot else normal) end
 end
 bind("Light",both("Light"),function(state) face(state,"Attack",2) end)
 bind("Heavy",both("Heavy"),function(state) face(state,"Heavy",3) end)
 bind("Dodge",both("Dodge"),function(state) face(state,"Dodge",4) end)
 bind("Jump",both("Jump"),function(state)
  if begin(state) then
   local human=getState().human
   -- The contextual chase stays on jump: A on a controller, SPACE on the keyboard.
   face(state,if human and human.pursuit>0 then "Pursuit" else "Jump",1)
  elseif state==Enum.UserInputState.End then send("JumpOff") end
 end)
 bind("Guard",both("Guard"),function(state) send(if begin(state) then "Guard" else "GuardOff") end)
 bind("Tool",both("Tool"),function(state) if begin(state) then send("Tool") end end)
 bind("Grab",both("Grab"),function(state) if begin(state) then send(if self.modifier then "Feint" else "Grab") end end)
 bind("Lock",both("Lock"),function(state) if begin(state) then toggleLock() end end)
 bind("Sprint",both("Sprint"),function(state,object)
  if object and object.KeyCode==GAMEPAD.Sprint then
   if begin(state) then self.sprinting=not self.sprinting end
  else self.sprinting=begin(state) end
 end)
 -- Keyboard-only actions.
 bind("Substitute",key(KEYBOARD.Substitute),function(state) if begin(state) then send("Substitute") end end)
 bind("WallDetach",key(KEYBOARD.WallDetach),function(state) if begin(state) then send("WallDetach") end end)
 bind("FeintKey",key(KEYBOARD.Feint),function(state) if begin(state) then send("Feint") end end)
 bind("PursuitKey",key(KEYBOARD.Pursuit),function(state) if begin(state) then send("Pursuit") end end)
 bind("Technique5",both("Technique5"),function(state) if begin(state) then send("Technique5") end end)
 bind("Awaken",both("Awaken"),function(state) if begin(state) then send("Awaken") end end)
 bind("RushPad",key(GAMEPAD.Rush),function(state) if begin(state) then send("Pursuit") end end)
 bind("Skip",both("Skip"),function(state) if begin(state) and getState().tutorial then send("TutorialSkip") end end)
 for index,input in {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four} do
  bind("Technique"..index,key(input),function(state) if begin(state) then send("Technique"..index) end end)
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
