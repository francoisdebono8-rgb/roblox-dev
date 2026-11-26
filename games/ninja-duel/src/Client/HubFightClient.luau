-- His kit in the street, on his screen (26/11, passe 3, DEC-055, HUB-002;
-- François : « qu'on puisse utiliser nos attaques et tout quand on se balade,
-- ça y est pas »). The duel's keys work while he walks the village: the light
-- chain (LMB / pad X), the heavy blow (RMB tapped / pad Y), the dash (Q / pad
-- B), the guard held (F / pad L1), a light in the air is the air strike. His
-- body plays the move at once (Client/HubBody, the kit's clip), the server
-- is asked for it (the remote HubAct, Server/HubFight: everyone sees it, the
-- blow lands), and the blows that land flash and sound where they land (the
-- remote HubImpact).
-- Rules: Shared/HubFight. Client/HubMove steps it with the walk.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Rules=require(Shared.HubFight)

local Fight={}
Fight.__index=Fight
-- RMB is also the camera's drag: a tap is the heavy blow, a drag is not.
Fight.TAP=.25
Fight.TAP_MOVE=8

local function remote(name)
	return Shared:FindFirstChild(name)
end

function Fight.new(move)
	local self=setmetatable({move=move,act=nil,actAt=nil,lastLight=nil,lastLightAt=nil,guard=false,dashUntil=0,dashVelocity=nil,slowUntil=0,rmbAt=nil,rmbFrom=nil},Fight)
	-- (the robots and the filming: the walker's fight of this screen)
	Fight.current=self
	return self
end

-- (robots, filming) Holds the move `move`'s clip at time `t` on his body for
-- `seconds` (its blow is not asked of the server): a pose to look at.
function Fight:hold(move,t,seconds)
	local spec=Rules.Moves[move]
	if not spec then return false end
	local untilAt=os.clock()+(seconds or 2)
	task.spawn(function()
		while os.clock()<untilAt do
			self.act,self.actAt=spec.clip,os.clock()-(t or 0)
			task.wait()
		end
		self.act=nil
	end)
	return true
end

-- Whether his keys are the street's now: he walks the village (the walk was
-- stepped this instant), no text box has the keyboard, no kunai targets run.
function Fight:live()
	if os.clock()-(self.move and self.move.steppedAt or -10)>.5 then return false end
	if UIS:GetFocusedTextBox() then return false end
	local me=Players.LocalPlayer
	if me and me:GetAttribute("NinjaSolo")=="targets" then return false end
	local intro=me and me:GetAttribute("NinjaIntro")
	if intro=="fight" or intro=="create" then return false end
	return true
end

-- A move pressed: played now on his body, asked of the server.
function Fight:press(name)
	if not self:live() then return end
	local now=os.clock()
	local character=Players.LocalPlayer.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local airborne=hum.FloorMaterial==Enum.Material.Air
	local move=name
	if name=="Light" then
		if airborne then move="Air"
		else
			local n=Rules.chain(self.lastLight,self.lastLightAt,now)
			move="Light"..n
			self.lastLight,self.lastLightAt=n,now
		end
	end
	local spec=Rules.Moves[move]
	if not spec then return end
	-- (the client keeps the server's gap: a press too soon is not shown either)
	self.grants=self.grants or {}
	if not Rules.grant(self.grants,move,now) then return end
	-- the blow goes where he looks (the camera), not where he walked
	if spec.contact then
		local look=workspace.CurrentCamera.CFrame.LookVector
		local flat=Vector3.new(look.X,0,look.Z)
		if flat.Magnitude>.05 then root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit) end
		self.slowUntil=now+(spec.slow or 0)
	end
	if spec.dash then
		local dir=hum.MoveDirection
		if dir.Magnitude<.1 then dir=root.CFrame.LookVector end
		dir=Vector3.new(dir.X,0,dir.Z)
		if dir.Magnitude>.05 then
			dir=dir.Unit
			self.dashVelocity=dir*spec.dash
			self.dashUntil=now+(spec.dashTime or .15)
			root.CFrame=CFrame.lookAt(root.Position,root.Position+dir)
		end
	end
	self.act,self.actAt=spec.clip,now
	local r=remote("HubAct")
	if r then r:FireServer(move) end
end

-- One frame (Client/HubMove, after the walk set his speed): the slow of a
-- blow, the guard's walk, the dash. Returns the clip to play and when it
-- began (Client/HubBody), or nil.
function Fight:step(dt,hum,root)
	local now=os.clock()
	if hum then
		if self.guard then hum.WalkSpeed=math.min(hum.WalkSpeed,Rules.GUARD_SPEED)
		elseif now<self.slowUntil then hum.WalkSpeed=math.min(hum.WalkSpeed,Rules.SLOW_SPEED) end
	end
	if root and self.dashVelocity and now<self.dashUntil then
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(self.dashVelocity.X,math.max(v.Y,-2),self.dashVelocity.Z)
	elseif self.dashVelocity and now>=self.dashUntil then
		self.dashVelocity=nil
	end
	if self.guard then return "Guard",nil end
	return self.act,self.actAt
end

-- The blows that land, for everyone near: the flash and the sound.
local SOUNDS={hit="rbxassetid://9117971636",heavy="rbxassetid://9117969717",wood="rbxassetid://9114221862",stone="rbxassetid://9118588165",challenge="rbxassetid://9126284094"}
function Fight.impact(payload)
	if type(payload)~="table" or typeof(payload.at)~="Vector3" then return end
	local at=payload.at
	local kind=payload.kind
	local heavy=payload.heavy==true
	pcall(function()
		local VfxHit=require(script.Parent.VfxHit)
		local weight=if kind=="worldbreak" then "slam" elseif heavy then "heavy" elseif kind=="challenge" then "medium" else "light"
		local me=Players.LocalPlayer.Character
		VfxHit.hit(weight,at,{dir=Vector3.xAxis,ignore={me}})
	end)
	pcall(function()
		local id=if kind=="worldbreak" or kind=="wood" then SOUNDS.wood elseif kind=="stone" or kind=="earth" then SOUNDS.stone
			elseif heavy then SOUNDS.heavy else SOUNDS.hit
		local anchor=Instance.new("Part")
		anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Transparency=1
		anchor.Size=Vector3.new(.2,.2,.2);anchor.CFrame=CFrame.new(at);anchor.Parent=workspace
		local s=Instance.new("Sound");s.SoundId=id;s.Volume=if heavy then .5 else .35;s.RollOffMaxDistance=140;s.RollOffMinDistance=10
		s.PlaybackSpeed=.95+math.random()*.1;s.Parent=anchor;s:Play()
		game:GetService("Debris"):AddItem(anchor,3)
	end)
	-- a challenge: the two players are told (who struck whom)
	if kind=="challenge" then
		local me=Players.LocalPlayer
		local by=payload.by and Players:GetPlayerByUserId(payload.by)
		if me and payload.to==me.UserId and by then
			pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="CHALLENGE!",Text=string.upper(by.DisplayName).." STRUCK YOU. HIT BACK TO FIGHT.",Duration=5}) end)
		end
	end
end

-- The keys (bound once).
function Fight:bind()
	if self.bound then return end
	self.bound=true
	UIS.InputBegan:Connect(function(input,processed)
		if processed then return end
		local t,k=input.UserInputType,input.KeyCode
		if t==Enum.UserInputType.MouseButton1 or k==Enum.KeyCode.ButtonX then self:press("Light")
		elseif k==Enum.KeyCode.ButtonY then self:press("Heavy")
		elseif t==Enum.UserInputType.MouseButton2 then self.rmbAt=os.clock();self.rmbFrom=UIS:GetMouseLocation()
		elseif k==Enum.KeyCode.Q or k==Enum.KeyCode.ButtonB then self:press("Dodge")
		elseif k==Enum.KeyCode.F or k==Enum.KeyCode.ButtonL1 then
			if self:live() then self.guard=true;self.act,self.actAt="Guard",os.clock();local r=remote("HubAct");if r then r:FireServer("Guard") end end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		local t,k=input.UserInputType,input.KeyCode
		if t==Enum.UserInputType.MouseButton2 and self.rmbAt then
			local held=os.clock()-self.rmbAt
			local moved=(UIS:GetMouseLocation()-(self.rmbFrom or UIS:GetMouseLocation())).Magnitude
			self.rmbAt=nil
			if held<=Fight.TAP and moved<=Fight.TAP_MOVE then self:press("Heavy") end
		elseif k==Enum.KeyCode.F or k==Enum.KeyCode.ButtonL1 then
			self.guard=false
			if self.act=="Guard" then self.act=nil end
		end
	end)
	task.spawn(function()
		local r=Shared:WaitForChild("HubImpact",30)
		if r then r.OnClientEvent:Connect(Fight.impact) end
	end)
end

return Fight
