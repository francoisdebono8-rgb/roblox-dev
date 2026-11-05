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
-- (Audit 29/10) On the pad R1 is also the jutsu shift: a player holding it
-- while choosing the face button loaded chakra by accident (and the next ○
-- became a dash). The pad's load needs a deliberate hold.
Input.ChakraHoldPad=.5
-- (Audit 04/11) R1 + L1 let go unused is the ultimate only on a short tap:
-- a page opened to choose a seal and closed without one burnt the bar.
Input.UltimateTap=.4
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
  sprinting=false,modifier=false,camera=camera,pad=Controls.isGamepad(UIS:GetLastInputType()),held={},guards={},jumps={},seals={}},Input)
 local function bind(name,keys,callback)
  local list={};for _,code in keys do if code then table.insert(list,code) end end
  CAS:BindActionAtPriority("Ninja"..name,function(_,state,object)
   if UIS:GetFocusedTextBox() or getState().phase~="Duel" or (name=="Skip" and not getState().tutorial) then
    -- (Flight recorder, Debug) a press the client itself let go of.
    if Input.dropped and state==Enum.UserInputState.Begin and name~="MoveStick" and name~="LookStick" then
     table.insert(Input.dropped,{t=os.clock(),name=name,why=if UIS:GetFocusedTextBox() then "textbox" else "phase "..tostring(getState().phase)})
     while #Input.dropped>60 do table.remove(Input.dropped,1) end
    end
    return Enum.ContextActionResult.Pass
   end
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
 -- (Audit 04/11) The seal page: R1 + L1 in either order (L1 is the guard, so
 -- L1 first is the natural roll); the guard it started is let go while the
 -- page is open and taken back if L1 is still held when the page closes.
 local function openPage()
  self.modifierSpent=true;self.sealPad=true;self.sealPadUsed=false;self.sealPadAt=Input.now()
  local id=GAMEPAD.Guard.Name
  if self.guards[id] then
   self.guards[id]=nil
   if next(self.guards)==nil then send("GuardOff") end
  end
 end
 local function closePage()
  if not self.sealPad then return end
  self.sealPad=false
  if not self.sealPadUsed and Input.now()-(self.sealPadAt or -math.huge)<=Input.UltimateTap then send("Ultimate") end
  self.sealPadUsed=true
  -- L1 still down: the guard comes back.
  if self.padL1 then
   local already=next(self.guards)~=nil;self.guards[GAMEPAD.Guard.Name]=true
   if not already then send("Guard") end
  end
 end
 bind("Modifier",key(GAMEPAD.Modifier),function(state)
  if begin(state) then
   self.modifier=true;self.modifierAt=Input.now();self.modifierSpent=false
   if self.padL1 then openPage() end
  elseif released(state) then
   self.modifier=false
   closePage()
  end
 end)
 local function face(state,object,normal,slot)
  if pressed(state,object) then
   local modified=padObject(object) and self.modifier
   if modified then self.modifierSpent=true;self.seals[object.KeyCode.Name]=true end
   -- (04/11) R1 + L1 held: the second page, the seal jutsu (the ultimate waits
   -- for the chord's release, Guard below).
   if modified and self.sealPad then self.sealPadUsed=true;send("Seal"..slot);return false end
   -- (User 29/10) Pad L1 + □ is the grab (the guard held, the light pressed).
   if not modified and normal=="Attack" and padObject(object) and next(self.guards)~=nil then send("Grab");return false end
   -- The chakra button held (pad L2, keyboard Z): the press goes out infused.
   if modified then send("Technique"..slot)
   elseif self:chakraOn(padObject(object)) then send(normal,{chakra=true})
   else send(normal) end
   return not modified
  end
  -- (Audit 29/10) The face button let go after R1+face lets a held technique
  -- go, as keys 1-4 do (a pad Katon always charged to the end).
  if released(state) and self.seals[object.KeyCode.Name] then self.seals[object.KeyCode.Name]=nil;send("SealRelease") end
  return false
 end
 bind("Light",both("Light"),function(state,obj) face(state,obj,"Attack",1) end)
 bind("Heavy",both("Heavy"),function(state,obj) face(state,obj,"Heavy",2) end)
 bind("Dodge",both("Dodge"),function(state,obj) face(state,obj,"Dodge",3) end)
 bind("Jump",both("Jump"),function(state,obj)
  local id=if padObject(obj) then obj.KeyCode.Name else obj.UserInputType.Name..obj.KeyCode.Name
  if released(state) then
   if self.jumps[id] then self.jumps[id]=nil;send("JumpOff") end
   face(state,obj,"Jump",4)
  else
   -- (User 29/10: a jump pressed after a launch flew the body up after the
   -- other one.) On a pad × doubles as the chase inside its window (no
   -- spare button); on a keyboard the chase has its own key (E) and Space
   -- always jumps.
   -- (Audit 29/10) The pad sends PadJump: the server picks the chase if its
   -- own window is open, else the jump (Matches:act).
   local action=if padObject(obj) then "PadJump" else "Jump"
   if face(state,obj,action,4) then self.jumps[id]=true end
  end
 end)
 bind("Guard",both("Guard"),function(state,obj)
  local id=obj.KeyCode.Name
  if released(state) then
   -- (04/11) R1 + L1 tapped without a seal jutsu: the ultimate (on a wall, the
   -- server lets go of it instead).
   if padObject(obj) then
    self.padL1=false
    closePage()
   end
   if self.guards[id] then
    self.guards[id]=nil
    if next(self.guards)==nil then send("GuardOff") end
   end
   pressed(state,obj)
  elseif pressed(state,obj) then
   -- R1 + L1: the seal page while held (□ △ ○ × D-pad ↑), the ultimate when
   -- let go unused.
   if padObject(obj) then self.padL1=true end
   if padObject(obj) and self.modifier then openPage()
   else
    local already=next(self.guards)~=nil;self.guards[id]=true
    if not already then send("Guard") end
   end
  end
 end)
 -- Chakra modifier + tool: keyboard Z (held, or just pressed), pad R1 + R2.
 -- Only a boolean leaves the client; the server picks what the chakra does.
 bind("ChakraPad",key(GAMEPAD.Chakra),function(state,obj)
  if released(state) or (obj.Position and obj.Position.Z<=.25 and state~=Enum.UserInputState.Begin) then self.chakraPad=false;self.chakraPadAt=Input.now()
  elseif state==Enum.UserInputState.Begin or (obj.Position and obj.Position.Z>=.45) then self.chakraPad=true end
 end)
 bind("ChakraKey",key(KEYBOARD.Chakra),function(state)
  if begin(state) then self.chakra=true;self.chakraAt=Input.now();self.chakraDownAt=self.chakraAt;self.chakraSpent=false elseif released(state) then self.chakra=false;self.chakraAt=Input.now() end
 end)
 bind("Tool",both("Tool"),function(state,obj)
  if pressed(state,obj) then
   -- R1 + R2 on the pad is the feint now (R1 is the jutsu shift, L2 the chakra).
   if padObject(obj) and self.modifier then self.modifierSpent=true;if self.sealPad then self.sealPadUsed=true end;send("Feint");return end
   local chakra=self:chakraOn(padObject(obj))
   if chakra then self.chakraSpent=true end
   if chakra then send("Tool",{chakra=true,aim=toolAim(getState(),padObject(obj))}) else send("Tool") end
  end
 end)
 bind("Grab",both("Grab"),function(state,obj)
  if pressed(state,obj) then
   if padObject(obj) and self.modifier then self.modifierSpent=true;if self.sealPad then self.sealPadUsed=true end end
   send(if padObject(obj) and self.modifier then "Feint" else "Grab")
  end
 end)
 bind("Lock",both("Lock"),function(state,obj) if pressed(state,obj) then toggleLock() end end)
 bind("Sprint",both("Sprint"),function(state,obj)
  if obj.KeyCode==GAMEPAD.Sprint then if pressed(state,obj) then self.sprinting=not self.sprinting end
  elseif begin(state) then self.sprinting=true elseif released(state) then self.sprinting=false end
 end)
 -- Keyboard C: held, the second page of jutsu (1-5 cast the seal jutsu); on a
 -- wall the press still lets go of it.
 bind("SealKey",key(KEYBOARD.WallDetach),function(state,obj)
  if pressed(state,obj) then self.sealKey=true;send("WallDetach")
  elseif released(state) then self.sealKey=false end
 end)
 for _,action in {"Substitute","Feint","Pursuit","Ultimate"} do
  bind(action.."Key",key(KEYBOARD[action]),function(state,obj) if pressed(state,obj) then send(action) end end)
 end
 for _,action in {"Awaken","Arm"} do
  bind(action,both(action),function(state,obj) if pressed(state,obj) then send(action) end end)
 end
 -- Jutsu 5 (keyboard 5, D-pad ↑); on the seal page the fifth seal jutsu.
 bind("Technique5",both("Technique5"),function(state,obj)
  if pressed(state,obj) then
   local page=if padObject(obj) then self.sealPad else self.sealKey
   if page then self.sealPadUsed=true;send("Seal5") else send("Technique5") end
  end
 end)
 -- Pad re-engage has no button of its own: × in a chase window (Jump above),
 -- else ○ toward a locked opponent while sprinting. The Dodge packet already
 -- carries the stick and the sprint toggle; the server turns it into the dash.
 bind("SubstitutePad",key(GAMEPAD.Substitute),function(state,obj) if pressed(state,obj) then send("Substitute") end end)
 -- (Audit 04/11) The tutorial: a tap skips the step, held a second it leaves
 -- (BACKSPACE / touchpad; Escape is the Roblox menu and never arrives).
 bind("Skip",both("Skip"),function(state,obj)
  if not getState().tutorial then return end
  if pressed(state,obj) then self.skipAt=Input.now()
  elseif released(state) and self.skipAt then
   local held=Input.now()-self.skipAt;self.skipAt=nil
   send(if held>=1 then "TutorialSkip" else "TutorialStep")
  end
 end)
 for index,code in {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four} do
  bind("Technique"..index,key(code),function(state,obj)
   -- C held: the second page, the seal jutsu (one press, the cast weaves the signs).
   if pressed(state,obj) then send(if self.sealKey then "Seal"..index else "Technique"..index)
   -- The release lets a held technique go (a charged Katon).
   elseif released(state) then send("SealRelease") end
  end)
 end
 local function blur()
  local jumping=next(self.jumps)~=nil
  self:reset();send("GuardOff");if jumping then send("JumpOff") end;send("Move",Vector3.zero)
 end
 UIS.WindowFocusReleased:Connect(blur)
 -- (Freeze 02/11) Back in the window: the keys still held count again.
 UIS.WindowFocused:Connect(function() self:resync() end)
 UIS.TextBoxFocused:Connect(blur)
 UIS.GamepadDisconnected:Connect(function() if self.pad then blur();self.pad=false end end)
 UIS.LastInputTypeChanged:Connect(function(kind)
  -- Moving the cursor while using the pad must not erase the PS5 prompts.
  if kind~=Enum.UserInputType.MouseMovement then self.pad=Controls.isGamepad(kind) end
 end)
 return self
end
function Input:reset()
 table.clear(self.keys);table.clear(self.held);table.clear(self.guards);table.clear(self.jumps);table.clear(self.seals)
 self.sealKey=false;self.sealPad=false;self.sealPadUsed=true;self.padL1=false
 self.stick=Vector2.zero;self.look=Vector2.zero;self.modifier=false;self.sprinting=false;self.camera.look=Vector2.zero
 self.chakra=false;self.chakraAt=nil;self.modifierSpent=true;self.chakraSpent=true;self.chakraPad=false;self.chakraPadAt=nil
end
-- (Audit 29/10) A new round (or phase) clears the presses but not the hand:
-- a direction held through the round change was forgotten until the key was
-- pressed again, so the body stood still at the start of every round.
function Input:resync()
 local guarding=next(self.guards)~=nil
 local jumping=next(self.jumps)~=nil
 self:reset()
 -- (Audit v34 #3) the guard key: the server forgets it with the round, and a
 -- key cleared here never sent its GuardOff on release (the guard came back
 -- by itself next round). Still held: it is taken again; let go: said so.
 local held=false
 pcall(function()
  if UIS:IsKeyDown(KEYBOARD.Guard) then held=true;self.guards[KEYBOARD.Guard.Name]=true end
  if UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,GAMEPAD.Guard) then held=true;self.guards[GAMEPAD.Guard.Name]=true;self.padL1=true end
 end)
 -- Deferred: on a new round this runs before the client takes the new epoch,
 -- and a press stamped with the old one is dropped by the server.
 task.defer(function()
  if held then self.send("Guard") elseif guarding then self.send("GuardOff") end
  if jumping then self.send("JumpOff") end
 end)
 pcall(function()
  for _,code in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
   if UIS:IsKeyDown(code) then self.keys[code.Name]=true end
  end
  if not self.pad and UIS:IsKeyDown(KEYBOARD.Sprint) then self.sprinting=true end
  for _,input in UIS:GetGamepadState(Enum.UserInputType.Gamepad1) do
   if input.KeyCode==Enum.KeyCode.Thumbstick1 and input.Position.Magnitude>.15 then self.stick=Vector2.new(input.Position.X,input.Position.Y) end
  end
 end)
end
-- (Freedom) The modifier held alone: once per hold, the next action is
-- loaded with chakra. Polled every frame (Input:direction).
function Input:chakraHold()
 local now=Input.now()
 -- (User 29/10) Nothing loads on a hold alone any more: the chakra button
 -- infuses the press it is held with (Input:chakraOn).
 local _=now
end
-- The chakra button: held (or released a moment before, a rolled chord).
function Input:chakraOn(pad)
 local now=Input.now()
 if pad then return self.chakraPad==true or now-(self.chakraPadAt or -math.huge)<=Input.ChakraChord end
 return self.chakra==true or now-(self.chakraAt or -math.huge)<=Input.ChakraChord
end
function Input:direction(camera)
 self:chakraHold()
 -- The current device owns movement; a resting controller cannot steer WASD.
 local stick=if self.pad and self.stick.Magnitude>.15 then self.stick else Vector2.zero
 -- (04/11) a phone's stick (Client/TouchControls)
 if stick.Magnitude==0 and self.touchStick and self.touchStick.Magnitude>.15 then stick=self.touchStick end
 -- (Freeze 02/11) The keys drive whenever the stick does not. A connected pad
 -- (a drifting stick, any pad event is enough) switched to "pad" and WASD was
 -- ignored, even held: the body stood still until the key was pressed again.
 -- A stick really pushed still owns the route alone (no stale key mixed in).
 local keys=stick.Magnitude==0
 -- (User 28/10) The pad's sprint is a toggle (L3); it ends when the stick
 -- rests a moment, so a stop always gives the walk / string back (it stayed on
 -- and every light became the running strike).
 if self.pad and self.sprinting then
  if stick.Magnitude<.2 then
   self.restAt=self.restAt or Input.now()
   if Input.now()-self.restAt>.18 then self.sprinting=false;self.restAt=nil end
  else self.restAt=nil end
 end
 local x=stick.X+(if self.keys.D and keys then 1 else 0)-(if self.keys.A and keys then 1 else 0)
 local z=stick.Y+(if self.keys.W and keys then 1 else 0)-(if self.keys.S and keys then 1 else 0)
 local look=camera.CFrame.LookVector*Vector3.new(1,0,1)
 if look.Magnitude<.01 then look=-Vector3.zAxis end
 local right=Vector3.new(-look.Unit.Z,0,look.Unit.X)
 local v=right*x+look.Unit*z
 return if v.Magnitude>1 then v.Unit else v
end
return Input
