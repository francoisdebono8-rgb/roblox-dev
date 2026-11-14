-- Konoha on the client (DEC-038, user 13/11: « le décor, les scènes, où est-ce
-- qu'on va choisir le maître, […] les premiers déplacements »). Between duels
-- the player walks the village as his own avatar with the default controls,
-- a run (Shift / L3) and a ninja's second jump. Over each master a marker
-- says who he is and what he is to the player (START, TEACHES YOU, YOURS,
-- LOCKED) and how far; the HUD names the place and the kit, and what to do
-- next (a new player: choose your first master). E at a master opens his card
-- (take his kit, your first duel, spar, his duel, try his kit, buy it, his
-- tree); E at the proctor in the exam hall opens the board of duels (the
-- roster). Every decision is the server's (Matches); this only asks.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local HubMap=require(Shared.HubMap)
local MastersView=require(Shared.MastersView)
local Masters=require(Shared.Masters)
local Fighters=require(Shared.Fighters)
local Text=require(Shared.Text)
local Hub={}
Hub.__index=Hub

Hub.WALK,Hub.RUN,Hub.JUMP,Hub.LEAP=16,30,56,54

local function upper(s) return Text.upper(s or "") end
local function nameOf(id) local def=Fighters[id] return upper(def and def.Name or id) end

function Hub.enabled() return Config.Hub~=nil and Config.Hub.Enabled==true end

function Hub.new(ui,camera,send,controls)
	local self=setmetatable({ui=ui,camera=camera,send=send,controls=controls,active=false,board=false,markers={},kits=nil},Hub)
	local K=ui.kit or require(script.Parent.UI).kit
	self.K=K
	local P=K.palette
	-- The HUD: the place and the kit (top left), what to do next (top).
	self.hud=K.frame(ui.gui,UDim2.fromOffset(18,18),UDim2.fromOffset(430,74),K.CARD,.12)
	K.corner(self.hud,10);self.hud.Visible=false;self.hud.ZIndex=20
	self.placeLabel=K.text(self.hud,"",UDim2.fromOffset(14,8),UDim2.fromOffset(404,26),22,P.paper,K.TITLE_FONT)
	self.kitLabel=K.text(self.hud,"",UDim2.fromOffset(14,38),UDim2.fromOffset(404,26),14,P.gold,K.BODY_FONT)
	self.goal=K.text(ui.gui,"",UDim2.new(.5,-420,0,18),UDim2.fromOffset(840,30),17,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",self.goal,{Color=P.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.goal.Visible=false
	-- (13/11) The shop and the Ryō, top right.
	self.shopBox=K.frame(ui.gui,UDim2.new(1,-300,0,18),UDim2.fromOffset(282,60),K.CARD,1)
	self.shopBox.Visible=false;self.shopBox.ZIndex=20
	local wallet=K.frame(self.shopBox,UDim2.fromOffset(0,0),UDim2.fromOffset(120,60),K.CARD,.12);K.corner(wallet,10)
	K.text(wallet,"RYŌ",UDim2.fromOffset(12,6),UDim2.fromOffset(96,14),10,P.muted,K.BODY_FONT,Enum.TextXAlignment.Right)
	self.ryoLabel=K.text(wallet,"0",UDim2.fromOffset(12,20),UDim2.fromOffset(96,34),28,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Right)
	local shop=K.button(self.shopBox,"SHOP",UDim2.fromOffset(132,0),UDim2.fromOffset(150,60),function()
		if self.ui.shopPanel then self.ui.shopPanel:show(self.kits) end
	end,P.red)
	shop.TextSize=28
	self.keys=K.text(ui.gui,"",UDim2.new(.5,-360,1,-34),UDim2.fromOffset(720,22),14,P.paper,K.BODY_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",self.keys,{Color=P.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.keys.Visible=false
	-- The master's card (right of the screen).
	local card=K.inkCard(K.frame(ui.gui,UDim2.new(1,-520,.5,-190),UDim2.fromOffset(490,380),K.CARD,0))
	card.Visible=false;card.ZIndex=30
	self.card=card
	self.cardName=K.inkTitle(K.text(card,"",UDim2.fromOffset(24,16),UDim2.fromOffset(360,46),40,P.paper,K.TITLE_FONT))
	self.cardPlace=K.text(card,"",UDim2.fromOffset(26,60),UDim2.fromOffset(440,20),14,P.gold,K.BODY_FONT)
	self.cardLine=K.text(card,"",UDim2.fromOffset(26,86),UDim2.fromOffset(440,46),16,P.text,K.BODY_FONT)
	self.cardLine.TextYAlignment=Enum.TextYAlignment.Top
	self.cardNote=K.text(card,"",UDim2.fromOffset(26,136),UDim2.fromOffset(440,58),14,P.gold,K.BODY_FONT)
	self.cardNote.TextYAlignment=Enum.TextYAlignment.Top
	self.primary=K.button(card,"",UDim2.fromOffset(24,204),UDim2.fromOffset(442,60),function() self:press("primary") end,P.red)
	self.primary.TextSize=28
	self.second=K.button(card,"",UDim2.fromOffset(24,276),UDim2.fromOffset(216,48),function() self:press("second") end)
	self.third=K.button(card,"",UDim2.fromOffset(250,276),UDim2.fromOffset(216,48),function() self:press("third") end)
	self.closeCard=K.button(card,"✕",UDim2.fromOffset(490-62,14),UDim2.fromOffset(44,44),function() self:hideCard() end)
	K.text(card,"E: TALK  •  WALK AWAY TO CLOSE",UDim2.fromOffset(24,336),UDim2.fromOffset(442,24),12,P.muted,K.BODY_FONT,Enum.TextXAlignment.Center)
	-- Prompts: a master, the proctor.
	PPS.PromptTriggered:Connect(function(prompt)
		if not self.active then return end
		local master=prompt:GetAttribute("NinjaMaster")
		if master then self:showCard(master) return end
		if prompt:GetAttribute("NinjaBoard") then self:openBoard() end
	end)
	-- The run and the second jump.
	self.leapUsed=false
	UIS.JumpRequest:Connect(function() self:jumpRequest() end)
	RunService.RenderStepped:Connect(function(dt) self:step(dt) end)
	return self
end

-- ------------------------------------------------------------------ state
function Hub:render(data)
	if data.kits~=nil or data.phase=="Selection" then
		if data.kits~=nil then self.kits=data.kits end
	end
	local walk=Hub.enabled() and (data.phase=="Selection" or data.phase=="Queue")
	if walk~=self.active then
		self.active=walk
		if not walk then self.board=false;self:hideCard() end
	end
	self:apply()
	if self.cardId then self:fillCard() end
	self:refreshMarkers()
	self:refreshHud()
end
-- Controls and lens: the village walk, or the board (the roster) over it.
function Hub:apply()
	local walking=self.active and not self.board
	-- The tree panel or the shop over the village: the walk waits behind it.
	local panel=(self.ui.treePanel and self.ui.treePanel:shown()) or (self.ui.shopPanel and self.ui.shopPanel:shown()) or false
	self.panelOpen=panel
	self.ui.hubWalk=walking
	self.camera.hubWalk=walking
	self.hud.Visible=walking;self.goal.Visible=walking and self.goal.Text~="";self.keys.Visible=walking
	self.shopBox.Visible=walking and self.kits~=nil and self.ui.shopPanel~=nil
	if not walking then self.card.Visible=false end
	pcall(function()
		if walking and not panel then self.controls:Enable() else self.controls:Disable() end
	end)
	if walking then
		local camera=workspace.CurrentCamera
		local character=Players.LocalPlayer.Character
		local hum=character and character:FindFirstChildOfClass("Humanoid")
		if camera.CameraType~=Enum.CameraType.Custom then camera.CameraType=Enum.CameraType.Custom end
		if hum and camera.CameraSubject~=hum then camera.CameraSubject=hum end
		camera.FieldOfView=70
	end
end
function Hub:openBoard()
	self.board=true;self:hideCard();self:apply()
	if self.ui.lastLobby then self.ui:render(self.ui.lastLobby) end
end
function Hub:closeBoard()
	self.board=false;self:apply()
	if self.ui.lastLobby then self.ui:render(self.ui.lastLobby) end
end

-- ------------------------------------------------------------------ the walk
function Hub:jumpRequest()
	if not self.active or self.board then return end
	local character=Players.LocalPlayer.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local state=hum:GetState()
	if (state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping) and not self.leapUsed and os.clock()-(self.jumpedAt or 0)>.18 then
		-- A ninja's second jump: chakra under the feet.
		self.leapUsed=true
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(v.X,Hub.LEAP,v.Z)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	elseif state~=Enum.HumanoidStateType.Freefall then
		self.jumpedAt=os.clock()
	end
end
function Hub:step(dt)
	if not self.active then return end
	if ((self.ui.treePanel and self.ui.treePanel:shown()) or (self.ui.shopPanel and self.ui.shopPanel:shown()) or false)~=self.panelOpen then self:apply() end
	local character=Players.LocalPlayer.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	if not self.board then
		local camera=workspace.CurrentCamera
		if camera.CameraSubject~=hum then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=hum end
	end
	local run=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
	pcall(function() run=run or UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,Enum.KeyCode.ButtonL3) end)
	hum.WalkSpeed=if run then Hub.RUN else Hub.WALK
	hum.UseJumpPower=true;hum.JumpPower=Hub.JUMP
	local state=hum:GetState()
	if state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.RunningNoPhysics then self.leapUsed=false end
	-- Fell out of the village (into the lake's floor, off the cliff): the gate.
	if root.Position.Y<HubMap.Origin.Y-40 then
		local spot=HubMap.Spawns.gate
		local at=HubMap.Origin+spot.at+Vector3.new(0,4,0)
		character:PivotTo(CFrame.lookAt(at,at+spot.face))
	end
	-- The card closes when he walks away from the master.
	if self.cardId and self.cardAt and (root.Position-self.cardAt).Magnitude>26 then self:hideCard() end
	self.clock=(self.clock or 0)+dt
	if self.clock>.25 then
		self.clock=0
		-- The masters arrive after the village (their portraits first).
		local count=0
		for _ in self.markers do count+=1 end
		if count<9 then self:refreshMarkers() end
		self:refreshHud(root.Position)
		for _,marker in self.markers do
			if marker.model and marker.model.Parent and marker.distance then
				local at=marker.model:GetPivot().Position
				marker.distance.Text=string.format("%d m",math.floor((at-root.Position).Magnitude/3.5+.5))
			end
		end
	end
end

-- ------------------------------------------------------------------ guidance
function Hub:status(id)
	return MastersView.status(self.kits,id)
end
function Hub:refreshHud(position)
	local K,P=self.K,self.K.palette
	if position then
		local place=HubMap.placeAt(position)
		self.placeLabel.Text="KONOHA  •  "..(place and place.name or "")
	elseif self.placeLabel.Text=="" then self.placeLabel.Text="KONOHA"
	end
	local kits=self.kits
	local kitLine="EVERY KIT IS OPEN"
	local goal=""
	if kits and kits.state=="ready" then
		local selected=kits.selected
		if selected and kits.owned[selected] then
			local tree=kits.trees and kits.trees[selected]
			kitLine=string.format("YOUR KIT: %s  •  MASTERY %d",nameOf(selected),kits.mastery and kits.mastery[selected] or 0)
			if tree and (tree.free or 0)>0 then kitLine..=string.format("  •  %d POINTS TO SPEND",tree.free) end
		else
			kitLine="NO KIT YET"
		end
		if kits.needStarter then
			goal="CHOOSE YOUR FIRST MASTER  •  NARUTO AT ICHIRAKU  •  SASUKE ON THE UCHIHA PIER  •  LEE ON TRAINING GROUND THREE"
		else
			for _,id in Masters.Kits do
				local m=kits.masters and kits.masters[id]
				if m and m.ready and not kits.owned[id] then
					goal=nameOf(id).." WILL TEACH YOU  •  "..(HubMap.Masters[id] and HubMap.Masters[id].place or "")
					break
				end
			end
			if goal=="" then goal="DUELS AND THE TOURNAMENT  •  THE PROCTOR, IN THE EXAM HALL" end
		end
	elseif kits and kits.state~="ready" then
		kitLine="YOUR KITS ARE ON THEIR WAY…"
	else
		goal="DUELS AND THE TOURNAMENT  •  THE PROCTOR, IN THE EXAM HALL"
	end
	self.kitLabel.Text=kitLine
	self.ryoLabel.Text=tostring(kits and kits.ryo or 0)
	self.shopBox.Visible=self.active and not self.board and kits~=nil and self.ui.shopPanel~=nil
	self.goal.Text=goal
	self.goal.Visible=self.active and not self.board and goal~=""
	local pad=UIS.GamepadEnabled and UIS:GetLastInputType()==Enum.UserInputType.Gamepad1
	self.keys.Text=if pad then "L3 RUN  •  A TWICE: LEAP  •  X TALK" else "SHIFT RUN  •  SPACE TWICE: LEAP  •  E TALK"
end

local TAG={open={"",nil},loading={"…",nil},starter={"START HERE","gold"},starterLocked={"LATER","muted"},
	owned={"YOUR KIT","paper"},master={"TEACHES YOU NOW","gold"},locked={"LOCKED","muted"}}
function Hub:marker(model,id,title,place)
	local K,P=self.K,self.K.palette
	local head=model:FindFirstChild("Head",true) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
	if not head then return nil end
	local gui=Instance.new("BillboardGui")
	gui.Name="NinjaHubMarker";gui.Adornee=head;gui.Size=UDim2.fromOffset(220,74);gui.StudsOffset=Vector3.new(0,3.6,0)
	gui.LightInfluence=0;gui.MaxDistance=1000;gui.ResetOnSpawn=false
	gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
	local name=K.text(gui,title,UDim2.fromOffset(0,0),UDim2.fromOffset(220,30),26,P.paper,K.TITLE_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",name,{Color=P.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	local tag=K.text(gui,"",UDim2.fromOffset(0,30),UDim2.fromOffset(220,20),15,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",tag,{Color=P.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	local distance=K.text(gui,"",UDim2.fromOffset(0,50),UDim2.fromOffset(220,18),13,P.muted,K.BODY_FONT,Enum.TextXAlignment.Center)
	return {gui=gui,model=model,id=id,name=name,tag=tag,distance=distance,place=place}
end
function Hub:refreshMarkers()
	local folder=workspace:FindFirstChild("NinjaDuelHub")
	local holder=folder and folder:FindFirstChild("Masters")
	if not holder then return end
	local P=self.K.palette
	for _,model in holder:GetChildren() do
		local id=model:GetAttribute("NinjaMaster")
		local key=id or (model:GetAttribute("NinjaBoard") and "Proctor")
		if key and (not self.markers[key] or self.markers[key].model~=model) then
			if self.markers[key] then self.markers[key].gui:Destroy() end
			local title=if id then nameOf(id) else "THE PROCTOR"
			self.markers[key]=self:marker(model,id,title,if id then HubMap.Masters[id] and HubMap.Masters[id].place else HubMap.Proctor.place)
		end
	end
	for key,marker in self.markers do
		if marker then
			marker.gui.Enabled=self.active and not self.board
			if marker.id then
				local status=self:status(marker.id)
				local tag=TAG[status] or TAG.locked
				marker.tag.Text=tag[1]
				marker.tag.TextColor3=P[tag[2] or "gold"] or P.gold
				-- What matters now is seen through the walls: a new player's
				-- three masters, a master who teaches him now.
				local loud=status=="starter" or status=="master"
				marker.gui.AlwaysOnTop=loud
				marker.gui.MaxDistance=if loud then 2000 else 140
			else
				marker.tag.Text="DUELS  •  TOURNAMENT"
				marker.gui.AlwaysOnTop=true;marker.gui.MaxDistance=2000
			end
		end
	end
end

-- ------------------------------------------------------------------ the card
function Hub:showCard(id)
	self.cardId=id
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	self.cardAt=root and root.Position
	self:fillCard()
	self.card.Visible=self.active and not self.board
end
function Hub:hideCard()
	self.cardId=nil;self.card.Visible=false;self.actions=nil
end
-- What the three buttons do for this master (Shared/MastersView.card).
function Hub:cardActions(id) return MastersView.card(self.kits,id) end
function Hub:fillCard()
	local id=self.cardId
	if not id then return end
	local spot=HubMap.Masters[id]
	local def=Fighters[id]
	self.cardName.Text=nameOf(id)
	self.cardPlace.Text=upper((def and def.Title or "")).."  •  "..(spot and spot.place or "")
	self.cardLine.Text="« "..(spot and spot.line or "").." »"
	local a=self:cardActions(id)
	self.actions=a
	local owned=self.kits and self.kits.owned and self.kits.owned[id]
	local note=a.note or ""
	if owned and self.kits.mastery then
		local tree=self.kits.trees and self.kits.trees[id]
		note=string.format("MASTERY %d  •  %d POINTS EARNED",self.kits.mastery[id] or 0,tree and tree.points or Masters.points(self.kits.mastery[id] or 0))
		local leads=MastersView.leadsTo(id)
		if #leads>0 then
			local names={}
			for _,other in leads do table.insert(names,nameOf(other)) end
			note..="  •  AT "..Masters.Need..": "..table.concat(names,", ").." WILL TEACH YOU"
		end
	end
	self.cardNote.Text=note
	self.primary.Text=a.primary and a.primary.label or ""
	self.primary.Visible=a.primary~=nil
	self.primary.AutoButtonColor=a.primary~=nil and a.primary.send~=nil
	for _,pair in {{self.second,a.second},{self.third,a.third}} do
		pair[1].Visible=pair[2]~=nil
		pair[1].Text=pair[2] and pair[2].label or ""
	end
end
function Hub:press(which)
	local a=self.actions
	local item=a and a[which]
	if not item then return end
	if item.tree then
		if self.ui.treePanel then self.ui.treePanel:show(item.tree,self.kits) end
		return
	end
	if item.send then self.send(item.send[1],item.send[2]) end
end

return Hub
