local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Controls=require(game:GetService("ReplicatedStorage").NinjaDuel.Controls)
local Input={};Input.__index=Input
-- Chakra chord: a modifier released this long before the tool still counts
-- (Z then R rolled quickly); the clock is a field so specs can drive it.
Input.ChakraChord=.3
-- The modifier held alone this long loads chakra into the next action
-- (server ChakraFlow): pad R1, keyboard Z.
Input.ChakraHold=.28
Input.now=os.clock
local KEYBOARD,GAMEPAD=Controls.Keyboard,Controls.Gamepad
local function key(code) return {code} end
local function both(action) return {KEYBOARD[action],GAMEPAD[action]} end
local function padObject(object)
 return Controls.isGamepad(object.UserInputType) or object.KeyCode.Name:match("^Button")~=nil
  or object.KeyCode.Name:match("^DPad")~=nil or object.KeyCode.Name:match("^Thumbstick")~=nil
end
local function released(state) return state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel end
-- The plain throw's aim (the client's send only computes it without extras):
-- the opponent on the pad, the mouse point on keyboard, within reach.
local function toolAim(state,pad)
 local ok,hit=pcall(function()
  local player=game:GetService("Players").LocalPlayer
  local point=if pad then state.bot and state.bot.position else player:GetMouse().Hit.Position
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if point and root and (point-root.Position).Magnitude<=140 then return point end
  return nil
 end)
 return if ok then hit else nil
end
function Input.new(send,getState,toggleLock,camera)
 local self=setmetatable({send=send,getState=getState,keys={},stick=Vector2.zero,look=Vector2.zero,
  sprinting=false,modifier=false,camera=camera,pad=Controls.isGamepad(UIS:GetLastInputType()),held={},guards={},jumps={}},Input)
 local function bind(name,keys,callback)
  local list={};for _,code in keys do if code then table.insert(list,code) end end
  CAS:BindActionAtPriority("Ninja"..name,function(_,state,object)
   if UIS:GetFocusedTextBox() or getState().phase~="Duel" or (name=="Skip" and not getState().tutorial) then return Enum.ContextActionResult.Pass end
   local stick=object.KeyCode==Enum.KeyCode.Thumbstick1 or object.KeyCode==Enum.KeyCode.Thumbstick2
   if not released(state) and (not stick or object.Position.Magnitude>.15) then self.pad=padObject(object) end
   callback(state,object)
   return Enum.ContextActionResult.Sink
  end,false,3000,table.unpack(list))
 end
 local function begin(state) return state==Enum.UserInputState.Begin end
 -- Schmitt thresholds: an analog trigger crossing its press threshold emits
 -- once. Change events while it is held never become repeated attacks.
 local function pressed(state,object)
  local code=object.KeyCode
  local id=if object.UserInputType==Enum.UserInputType.MouseButton1 or object.UserInputType==Enum.UserInputType.MouseButton2 then object.UserInputType.Name else code.Name
  if code==GAMEPAD.Grab or code==GAMEPAD.Tool then
   if released(state) or object.Position.Z<=.25 then self.held[id]=nil;return false end
   if object.Position.Z>=.55 and not self.held[id] then self.held[id]=true;return true end
   return false
  end
  if released(state) then self.held[id]=nil;return false end
  if begin(state) and not self.held[id] then self.held[id]=true;return true end
  return false
 end
 for _,code in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
  bind(code.Name,key(code),function(state)
   if begin(state) then self.keys[code.Name]=true elseif released(state) then self.keys[code.Name]=nil end
  end)
 end
 bind("MoveStick",key(Enum.KeyCode.Thumbstick1),function(state,obj)
  self.stick=if released(state) then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
 end)
 bind("LookStick",key(Enum.KeyCode.Thumbstick2),function(state,obj)
  self.look=if released(state) then Vector2.zero else Vector2.new(obj.Position.X,obj.Position.Y)
  camera.look=self.look
 end)
 bind("Modifier",key(GAMEPAD.Modifier),function(state)
  if begin(state) then self.modifier=true;self.modifierAt=Input.now();self.modifierSpent=false elseif released(state) then self.modifier=false end
 end)
 local function face(state,object,normal,slot)
  if pressed(state,object) then
   local modified=padObject(object) and self.modifier
   if modified then self.modifierSpent=true end
   send(if modified then "Technique"..slot else normal)
   return not modified
  end
  return false
 end
 bind("Light",both("Light"),function(state,obj) face(state,obj,"Attack",2) end)
 bind("Heavy",both("Heavy"),function(state,obj) face(state,obj,"Heavy",3) end)
 bind("Dodge",both("Dodge"),function(state,obj) face(state,obj,"Dodge",4) end)
 bind("Jump",both("Jump"),function(state,obj)
  local id=if padObject(obj) then obj.KeyCode.Name else obj.UserInputType.Name..obj.KeyCode.Name
  if released(state) then
   if self.jumps[id] then self.jumps[id]=nil;send("JumpOff") end
   pressed(state,obj)
  else
   local h=getState().human;local action=if h and h.pursuit>0 then "Pursuit" else "Jump"
   if face(state,obj,action,1) and action=="Jump" then self.jumps[id]=true end
  end
 end)
 bind("Guard",both("Guard"),function(state,obj)
  local id=obj.KeyCode.Name
  if released(state) then
   if self.guards[id] then
    self.guards[id]=nil
    if next(self.guards)==nil then send("GuardOff") end
   end
   pressed(state,obj)
  elseif pressed(state,obj) then
   if padObject(obj) and self.modifier then self.modifierSpent=true;send("WallDetach")
   else
    local already=next(self.guards)~=nil;self.guards[id]=true
    if not already then send("Guard") end
   end
  end
 end)
 -- Chakra modifier + tool: keyboard Z (held, or just pressed), pad R1 + R2.
 -- Only a boolean leaves the client; the server picks what the chakra does.
 bind("ChakraKey",key(KEYBOARD.Chakra),function(state)
  if begin(state) then self.chakra=true;self.chakraAt=Input.now();self.chakraDownAt=self.chakraAt;self.chakraSpent=false elseif released(state) then self.chakra=false;self.chakraAt=Input.now() end
 end)
 bind("Tool",both("Tool"),function(state,obj)
  if pressed(state,obj) then
   local chakra=if padObject(obj) then self.modifier else (self.chakra or Input.now()-(self.chakraAt or -math.huge)<=Input.ChakraChord)
   if chakra then self.modifierSpent=true;self.chakraSpent=true end
   if chakra then send("Tool",{chakra=true,aim=toolAim(getState(),padObject(obj))}) else send("Tool") end
  end
 end)
 bind("Grab",both("Grab"),function(state,obj)
  if pressed(state,obj) then
   if padObject(obj) and self.modifier then self.modifierSpent=true end
   send(if padObject(obj) and self.modifier then "Feint" else "Grab")
  end
 end)
 bind("Lock",both("Lock"),function(state,obj) if pressed(state,obj) then toggleLock() end end)
 bind("Sprint",both("Sprint"),function(state,obj)
  if obj.KeyCode==GAMEPAD.Sprint then if pressed(state,obj) then self.sprinting=not self.sprinting end
  elseif begin(state) then self.sprinting=true elseif released(state) then self.sprinting=false end
 end)
 for _,action in {"Substitute","WallDetach","Feint","Pursuit"} do
  bind(action.."Key",key(KEYBOARD[action]),function(state,obj) if pressed(state,obj) then send(action) end end)
 end
 for _,action in {"Technique5","Awaken","Arm"} do
  bind(action,both(action),function(state,obj) if pressed(state,obj) then send(action) end end)
 end
 -- Pad re-engage has no button of its own: × in a chase window (Jump above),
 -- else ○ toward a locked opponent while sprinting. The Dodge packet already
 -- carries the stick and the sprint toggle; the server turns it into the dash.
 bind("SubstitutePad",key(GAMEPAD.Substitute),function(state,obj) if pressed(state,obj) then send("Substitute") end end)
 bind("Skip",both("Skip"),function(state,obj) if pressed(state,obj) and getState().tutorial then send("TutorialSkip") end end)
 for index,code in {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four} do
  bind("Technique"..index,key(code),function(state,obj)
   if pressed(state,obj) then send("Technique"..index)
   -- The release lets a held technique go (a charged Katon).
   elseif released(state) then send("SealRelease") end
  end)
 end
 local function blur()
  local jumping=next(self.jumps)~=nil
  self:reset();send("GuardOff");if jumping then send("JumpOff") end;send("Move",Vector3.zero)
 end
 UIS.WindowFocusReleased:Connect(blur)
 UIS.TextBoxFocused:Connect(blur)
 UIS.GamepadDisconnected:Connect(function() if self.pad then blur();self.pad=false end end)
 UIS.LastInputTypeChanged:Connect(function(kind)
  -- Moving the cursor while using the pad must not erase the PS5 prompts.
  if kind~=Enum.UserInputType.MouseMovement then self.pad=Controls.isGamepad(kind) end
 end)
 return self
end
function Input:reset()
 table.clear(self.keys);table.clear(self.held);table.clear(self.guards);table.clear(self.jumps)
 self.stick=Vector2.zero;self.look=Vector2.zero;self.modifier=false;self.sprinting=false;self.camera.look=Vector2.zero
 self.chakra=false;self.chakraAt=nil;self.modifierSpent=true;self.chakraSpent=true
end
-- (Freedom) The modifier held alone: once per hold, the next action is
-- loaded with chakra. Polled every frame (Input:direction).
function Input:chakraHold()
 local now=Input.now()
 if self.modifier and not self.modifierSpent and now-(self.modifierAt or now)>=Input.ChakraHold then
  self.modifierSpent=true;self.send("ChakraLoad")
 end
 if self.chakra and not self.chakraSpent and now-(self.chakraDownAt or now)>=Input.ChakraHold then
  self.chakraSpent=true;self.send("ChakraLoad")
 end
end
function Input:direction(camera)
 self:chakraHold()
 -- The current device owns movement; a resting controller cannot steer WASD.
 local stick=if self.pad and self.stick.Magnitude>.15 then self.stick else Vector2.zero
 -- (User 28/10) The pad's sprint is a toggle (L3); it ends when the stick
 -- rests a moment, so a stop always gives the walk / string back (it stayed on
 -- and every light became the running strike).
 if self.pad and self.sprinting then
  if stick.Magnitude<.2 then
   self.restAt=self.restAt or Input.now()
   if Input.now()-self.restAt>.18 then self.sprinting=false;self.restAt=nil end
  else self.restAt=nil end
 end
 local x=stick.X+(if self.keys.D and not self.pad then 1 else 0)-(if self.keys.A and not self.pad then 1 else 0)
 local z=stick.Y+(if self.keys.W and not self.pad then 1 else 0)-(if self.keys.S and not self.pad then 1 else 0)
 local look=camera.CFrame.LookVector*Vector3.new(1,0,1)
 if look.Magnitude<.01 then look=-Vector3.zAxis end
 local right=Vector3.new(-look.Unit.Z,0,look.Unit.X)
 local v=right*x+look.Unit*z
 return if v.Magnitude>1 then v.Unit else v
end
return Input
