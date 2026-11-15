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
local GuiService=game:GetService("GuiService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local HubMap=require(Shared.HubMap)
local MastersView=require(Shared.MastersView)
local Masters=require(Shared.Masters)
local Fighters=require(Shared.Fighters)
local Text=require(Shared.Text)
local HubLayout=require(script.Parent.HubLayout)
local HubMoods=require(script.Parent.HubMoods)
local Inspirations=require(Shared.Inspirations)
local Hub={}
Hub.__index=Hub
-- (14/11) The run latched by L3 or the touch RUN button stops after this long
-- at rest (the duel's pad sprint does the same, DECISIONS socle 2).
Hub.REST=.35

Hub.WALK,Hub.RUN,Hub.JUMP,Hub.LEAP=16,30,56,54

local function upper(s) return Text.upper(s or "") end
local function nameOf(id) local def=Fighters[id] return upper(def and def.Name or id) end

function Hub.enabled() return Config.Hub~=nil and Config.Hub.Enabled==true end

function Hub.new(ui,camera,send,controls)
	local self=setmetatable({ui=ui,camera=camera,send=send,controls=controls,active=false,board=false,markers={},kits=nil},Hub)
	local K=ui.kit or require(script.Parent.UI).kit
	self.K=K
	local P=K.palette
	-- (DA v3, DESIGN, validated 14/11: « Konoha — PC, en balade ») A manga page
	-- over the village: paper labels ringed with ink, the next goal on a band
	-- of ink underlined in red, one red for the action. Placed and scaled by
	-- Client/HubLayout (Hub:layout) under Roblox's top bar.
	local M=K.MANGA or {paper=Color3.fromRGB(255,253,248),ink=Color3.fromRGB(20,16,17),red=Color3.fromRGB(195,18,29),cream=Color3.fromRGB(246,238,222),redSoft=Color3.fromRGB(240,120,110)}
	self.M=M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	local BROWN=Color3.fromRGB(94,79,67)
	local function inkRing(gui,thick) return K.create("UIStroke",gui,{Color=M.ink,Thickness=thick or 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
	-- a keycap: the key to press, drawn as on the keyboard
	local function keycap(parent,key,position)
		local cap=K.text(parent,key,position,UDim2.fromOffset(30,24),15,M.ink,STRONG,Enum.TextXAlignment.Center)
		cap.BackgroundColor3=M.paper;cap.BackgroundTransparency=0;cap.ZIndex=(parent.ZIndex or 1)+2
		K.corner(cap,5);inkRing(cap,2)
		return cap
	end
	self.hud=K.frame(ui.gui,UDim2.fromOffset(18,18),UDim2.fromOffset(HubLayout.HUD.w,HubLayout.HUD.h),M.paper,0)
	self.hud.Visible=false;self.hud.ZIndex=20;self.hud.Rotation=-1.5
	inkRing(self.hud,3)
	self.hudScale=K.create("UIScale",self.hud,{Scale=1})
	self.placeLabel=K.text(self.hud,"",UDim2.fromOffset(16,8),UDim2.fromOffset(400,28),24,M.ink,STRONG)
	self.kitLabel=K.text(self.hud,"",UDim2.fromOffset(16,40),UDim2.fromOffset(400,24),16,Color3.fromRGB(58,47,40),K.BODY_FONT)
	self.kitLabel.TextScaled=true
	K.create("UITextSizeConstraint",self.kitLabel,{MaxTextSize=16,MinTextSize=10})
	-- The goal: « NEXT » and where to go, cream on a band of ink, a red brush
	-- stroke under it; never under the shop or Roblox's buttons.
	self.goal=K.frame(ui.gui,UDim2.fromOffset(0,18),UDim2.fromOffset(HubLayout.GOAL.w,HubLayout.GOAL.h),M.ink,0)
	self.goal.Visible=false;self.goal.ZIndex=20;self.goal.Rotation=-.8
	self.goalScale=K.create("UIScale",self.goal,{Scale=1})
	local brush=K.frame(self.goal,UDim2.new(.18,0,1,4),UDim2.new(.64,0,0,7),M.red,0)
	brush.ZIndex=19;K.corner(brush,4)
	self.goalHead=K.text(self.goal,"",UDim2.fromOffset(0,2),UDim2.new(1,0,0,26),18,M.redSoft,STRONG,Enum.TextXAlignment.Center)
	self.goalSub=K.text(self.goal,"",UDim2.fromOffset(0,30),UDim2.new(1,0,0,24),20,M.cream,STRONG,Enum.TextXAlignment.Center)
	self.goalSub.TextWrapped=false;self.goalSub.TextScaled=true
	K.create("UITextSizeConstraint",self.goalSub,{MaxTextSize=20,MinTextSize=10})
	-- The Ryō on paper, DUELS in ink, SHOP in red, top right.
	self.shopBox=K.frame(ui.gui,UDim2.new(1,-300,0,18),UDim2.fromOffset(HubLayout.SHOP.w,HubLayout.SHOP.h),M.paper,1)
	self.shopBox.Visible=false;self.shopBox.ZIndex=20
	self.shopScale=K.create("UIScale",self.shopBox,{Scale=1})
	local wallet=K.frame(self.shopBox,UDim2.fromOffset(0,4),UDim2.fromOffset(120,52),M.paper,0)
	wallet.Rotation=2;inkRing(wallet,3)
	K.text(wallet,"RYŌ",UDim2.fromOffset(10,4),UDim2.fromOffset(100,14),12,BROWN,STRONG,Enum.TextXAlignment.Right)
	self.ryoLabel=K.text(wallet,"0",UDim2.fromOffset(10,18),UDim2.fromOffset(100,30),28,M.ink,STRONG,Enum.TextXAlignment.Right)
	-- (14/11, audit: the board of duels was only at the proctor's, 15 s from
	-- the gate; VISION: « les menus restent disponibles partout ») DUELS opens
	-- it from anywhere in the village (B, the pad's R1).
	self.duelsButton=K.button(self.shopBox,"DUELS",UDim2.fromOffset(132,0),UDim2.fromOffset(140,60),function() self:openBoard() end,M.ink)
	self.duelsButton.TextSize=32;self.duelsButton.TextColor3=M.cream;self.duelsButton.Rotation=-1.5
	self.duelsKey=keycap(self.duelsButton,"B",UDim2.new(1,-24,0,-10))
	local shop=K.button(self.shopBox,"SHOP",UDim2.fromOffset(284,0),UDim2.fromOffset(140,60),function() self:openShop() end,M.red)
	shop.TextSize=34;shop.TextColor3=M.cream;shop.Rotation=-2
	self.keys=K.text(ui.gui,"",UDim2.new(.5,-360,1,-34),UDim2.fromOffset(720,22),16,M.cream,K.BODY_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",self.keys,{Color=M.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.keys.Visible=false
	-- (14/11) Touch: Roblox gives a thumbstick and a jump button, no run; a
	-- RUN button left of the jump button latches the run (Hub:step).
	self.runButton=K.button(ui.gui,"RUN",UDim2.fromOffset(0,0),UDim2.fromOffset(70,70),function()
		self.runLatch=not self.runLatch;self.runMoved=false;self.restFor=0;self:paintRun()
	end,P.ink)
	self.runButton.TextSize=20;self.runButton.Visible=false;self.runButton.ZIndex=25
	-- round (the kit's button already has its corner: a second one is ignored)
	local round=self.runButton:FindFirstChildOfClass("UICorner") or K.corner(self.runButton,6)
	round.CornerRadius=UDim.new(.5,0)
	K.create("UIStroke",self.runButton,{Color=P.paper,Transparency=.3,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	-- (DA v3, DESIGN, validated 14/11: « Konoha — PC, en parlant à un maître »)
	-- The inspiration speaks in a manga bubble (the voice font), his name on a
	-- black tag; red for the duel, paper for the rest. Right of the screen,
	-- centred on a narrow one (Client/HubLayout).
	local card=K.frame(ui.gui,UDim2.new(1,-520,.5,-190),UDim2.fromOffset(HubLayout.CARD.w,HubLayout.CARD.h),M.paper,1)
	card.Visible=false;card.ZIndex=30
	self.card=card
	self.cardScale=K.create("UIScale",card,{Scale=1})
	local bubble=K.frame(card,UDim2.fromOffset(0,24),UDim2.fromOffset(490,176),M.paper,0)
	bubble.ZIndex=30;K.corner(bubble,46);inkRing(bubble,4)
	local tail=K.frame(card,UDim2.fromOffset(60,186),UDim2.fromOffset(26,26),M.paper,0)
	tail.Rotation=45;tail.ZIndex=29;inkRing(tail,4)
	self.cardBubble=bubble
	local tag=K.frame(card,UDim2.fromOffset(6,6),UDim2.fromOffset(300,36),M.ink,0)
	tag.Rotation=-3;tag.ZIndex=33
	self.cardName=K.text(tag,"",UDim2.fromOffset(12,2),UDim2.fromOffset(276,32),24,M.cream,STRONG)
	self.cardName.ZIndex=34;self.cardName.RichText=true
	self.cardName.TextScaled=true
	K.create("UITextSizeConstraint",self.cardName,{MaxTextSize=24,MinTextSize=12})
	self.cardPlace=K.text(bubble,"",UDim2.fromOffset(30,22),UDim2.fromOffset(430,18),13,BROWN,STRONG,Enum.TextXAlignment.Center)
	self.cardLine=K.text(bubble,"",UDim2.fromOffset(30,44),UDim2.fromOffset(430,74),22,M.ink,K.VOICE_FONT or K.BODY_FONT,Enum.TextXAlignment.Center)
	self.cardLine.TextYAlignment=Enum.TextYAlignment.Top
	-- (DEC-041) an inspiration's funny line runs three lines: it shrinks to fit
	self.cardLine.TextWrapped=true;self.cardLine.TextScaled=true
	K.create("UITextSizeConstraint",self.cardLine,{MaxTextSize=22,MinTextSize=12})
	self.cardNote=K.text(bubble,"",UDim2.fromOffset(30,120),UDim2.fromOffset(430,44),14,M.red,STRONG,Enum.TextXAlignment.Center)
	self.cardNote.TextYAlignment=Enum.TextYAlignment.Top
	self.cardNote.TextWrapped=true;self.cardNote.TextScaled=true
	K.create("UITextSizeConstraint",self.cardNote,{MaxTextSize=14,MinTextSize=10})
	for _,g in {self.cardPlace,self.cardLine,self.cardNote} do g.ZIndex=31 end
	self.primary=K.button(card,"",UDim2.fromOffset(24,218),UDim2.fromOffset(442,56),function() self:press("primary") end,M.red)
	self.primary.TextSize=26;self.primary.TextColor3=M.cream;self.primary.Font=STRONG
	self.second=K.button(card,"",UDim2.fromOffset(24,284),UDim2.fromOffset(216,46),function() self:press("second") end,M.paper)
	self.third=K.button(card,"",UDim2.fromOffset(250,284),UDim2.fromOffset(216,46),function() self:press("third") end,M.paper)
	for _,b in {self.second,self.third} do b.TextColor3=M.ink;b.Font=STRONG;b.TextSize=18;inkRing(b,3) end
	-- (the mock-up's « Later »: B on a pad, or walk away)
	self.closeCard=K.button(card,"LATER",UDim2.fromOffset(490-118,4),UDim2.fromOffset(112,38),function() self:hideCard() end,M.paper)
	self.closeCard.TextColor3=M.ink;self.closeCard.Font=STRONG;self.closeCard.TextSize=18;self.closeCard.ZIndex=34;inkRing(self.closeCard,3)
	self.cardFoot=K.text(card,"",UDim2.fromOffset(24,338),UDim2.fromOffset(442,24),14,M.cream,K.BODY_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",self.cardFoot,{Color=M.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	-- Prompts: a master, the proctor.
	PPS.PromptTriggered:Connect(function(prompt)
		if not self.active then return end
		local master=prompt:GetAttribute("NinjaMaster")
		if master then self:showCard(master) return end
		if prompt:GetAttribute("NinjaBoard") then self:openBoard() end
		if prompt:GetAttribute("NinjaTrain") then self:train() end
		-- (14/11) the market: the looks sold for Ryō
		if prompt:GetAttribute("NinjaMarket") and self.ui.shopPanel then self:hideCard();self.ui.shopPanel:show(self.kits,"WEAPONS","market") end
	end)
	-- The run and the second jump.
	self.leapUsed=false
	self.runLatch=false;self.restFor=0
	UIS.JumpRequest:Connect(function() self:jumpRequest() end)
	RunService.RenderStepped:Connect(function(dt) self:step(dt) end)
	-- (14/11) The pad: L3 latches the run (held, it was a strain on the thumb
	-- for every street), Y opens the shop, B closes a master's card, R1 opens
	-- the board of duels (the keyboard's B; not while he types in the chat).
	UIS.InputBegan:Connect(function(input,processed)
		if not self.active or self.board then return end
		local key=input.KeyCode
		if (key==Enum.KeyCode.ButtonR1 or (key==Enum.KeyCode.B and not processed)) and not self.panelOpen and not self.card.Visible then
			self:openBoard()
		elseif key==Enum.KeyCode.ButtonL3 and not self.panelOpen then
			self.runLatch=not self.runLatch;self.runMoved=false;self.restFor=0;self:paintRun()
		elseif key==Enum.KeyCode.ButtonY and not self.panelOpen and not self.card.Visible then
			self:openShop()
		elseif key==Enum.KeyCode.ButtonB and self.card.Visible and not self.panelOpen then
			-- (a panel open over the card closes first: panelOpen is last frame's)
			self:hideCard()
		end
	end)
	-- The layout follows the window and the way he plays (touch, pad, keys).
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:layout() end) end)
	-- (only when the way changes: mouse and keys alternate all the time)
	pcall(function() UIS.LastInputTypeChanged:Connect(function()
		local now=self:input()
		if now~=self.lastInput then self.lastInput=now;self:layout();self:refreshHud() end
	end) end)
	self.lastInput=self:input()
	self:layout()
	return self
end

-- ------------------------------------------------------------------ layout
-- The way he plays now: "touch", "pad" or "keys".
function Hub:input()
	local last=UIS:GetLastInputType()
	if last==Enum.UserInputType.Touch then return "touch" end
	if last.Name:sub(1,7)=="Gamepad" then return "pad" end
	if UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.GamepadEnabled then return "touch" end
	return "keys"
end
-- Places the HUD, the goal, the shop box, the card and the RUN button
-- (Client/HubLayout) under Roblox's top bar, for this window.
function Hub:layout()
	local camera=workspace.CurrentCamera
	if not camera then return end
	local inset=0
	pcall(function() inset=GuiService:GetGuiInset().Y end)
	local touch=self:input()=="touch"
	local L=HubLayout.compute(camera.ViewportSize,inset,touch)
	self.lay=L
	local function at(gui,r) gui.Position=UDim2.fromOffset(math.floor(r.x+.5),math.floor(r.y+.5)) end
	at(self.hud,L.hud);self.hudScale.Scale=L.scale
	at(self.shopBox,L.shop);self.shopScale.Scale=L.scale
	at(self.goal,L.goal);self.goalScale.Scale=L.scale
	self.goal.Size=UDim2.fromOffset(L.goal.w/L.scale,L.goal.h/L.scale)
	-- narrow: the places one a line under the head (Hub:refreshHud)
	self.goalSub.Size=UDim2.new(1,0,0,if L.goal.stack then HubLayout.GOAL.stackH-34 else 22)
	self.goalSub.TextWrapped=L.goal.stack==true
	if self.goalSubText then self:refreshHud() end
	at(self.card,L.card);self.cardScale.Scale=L.card.scale
	if L.keys then
		at(self.keys,L.keys);self.keys.Size=UDim2.fromOffset(L.keys.w,L.keys.h);self.keys.TextSize=math.max(11,math.floor(14*L.scale+.5))
	end
	if L.run then
		at(self.runButton,L.run);self.runButton.Size=UDim2.fromOffset(L.run.w,L.run.h)
		self.runButton.TextSize=math.floor(L.run.w*.28+.5)
	end
	self:paintRun()
	self:apply()
end
function Hub:paintRun()
	local M=self.M
	self.runButton.BackgroundColor3=if self.runLatch then M.red else M.ink
	self.runButton.TextColor3=M.cream
	self.runButton.BackgroundTransparency=if self.runLatch then 0 else .25
end
function Hub:openShop()
	if not self.ui.shopPanel then return end
	self:hideCard()
	self.ui.shopPanel:show(self.kits)
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
	local panel=(self.ui.treePanel and self.ui.treePanel:shown()) or (self.ui.shopPanel and self.ui.shopPanel:shown()) or (self.ui.outfitPanel and self.ui.outfitPanel:shown()) or false
	self.panelOpen=panel
	self.ui.hubWalk=walking
	self.camera.hubWalk=walking
	if not walking then self.card.Visible=false end
	self:showHud()
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
-- What of the HUD shows (no controls, no camera: Hub:refreshHud calls it
-- four times a second).
function Hub:showHud()
	local walking=self.active and not self.board
	local panel=self.panelOpen
	local touch=self.lay~=nil and self.lay.touch
	-- (a phone's card takes the top row: the place box and the shop step aside)
	local talking=self.card.Visible and self.lay~=nil and self.lay.card.overTop==true
	self.hud.Visible=walking and not talking;self.keys.Visible=walking and not touch
	self.goal.Visible=walking and self.goalHead.Text~="" and not self.card.Visible
	self.runButton.Visible=walking and touch and not panel
	self.shopBox.Visible=walking and not talking and self.kits~=nil and self.ui.shopPanel~=nil
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
	if ((self.ui.treePanel and self.ui.treePanel:shown()) or (self.ui.shopPanel and self.ui.shopPanel:shown()) or (self.ui.outfitPanel and self.ui.outfitPanel:shown()) or false)~=self.panelOpen then self:apply() end
	local character=Players.LocalPlayer.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	if not self.board then
		local camera=workspace.CurrentCamera
		if camera.CameraSubject~=hum then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=hum end
	end
	-- Shift held, or the run latched (L3, the touch RUN button) until he stops.
	-- (Latched standing still, it waits for him to move: the rest that ends
	-- it is the one after a run.)
	if self.runLatch then
		if hum.MoveDirection.Magnitude>=.1 then self.runMoved=true;self.restFor=0
		elseif self.runMoved then self.restFor=(self.restFor or 0)+dt end
		if self.restFor>Hub.REST then self.runLatch=false;self.runMoved=false;self.restFor=0;self:paintRun() end
	end
	local run=self.runLatch or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
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
	-- (DEC-041) the first three inspirations in their moods, when he is near
	self.moodClock=(self.moodClock or 0)+dt
	self:moods(root.Position)
	self.clock=(self.clock or 0)+dt
	if self.clock>.25 then
		self.clock=0
		-- The masters arrive after the village (their portraits first): the
		-- masters, the proctor, the training dummy and the market.
		local count,want=0,3
		for _ in self.markers do count+=1 end
		for _ in HubMap.Masters do want+=1 end
		if count<want then self:refreshMarkers() end
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
	if kits and kits.state=="ready" then
		local selected=kits.selected
		if selected and kits.owned[selected] then
			local tree=kits.trees and kits.trees[selected]
			kitLine=string.format("YOUR KIT: %s  •  MASTERY %d",nameOf(selected),kits.mastery and kits.mastery[selected] or 0)
			if tree and (tree.free or 0)>0 then kitLine..=string.format("  •  %d POINTS TO SPEND",tree.free) end
		else
			kitLine="NO KIT YET"
		end
	elseif kits and kits.state~="ready" then
		kitLine="YOUR KITS ARE ON THEIR WAY…"
	end
	-- (14/11) The goal: a head and where to go (Shared/MastersView.goal).
	local goal=MastersView.goal(kits)
	self.kitLabel.Text=kitLine
	self.ryoLabel.Text=tostring(kits and kits.ryo or 0)
	self.goalSubText=goal.sub
	self.goalHead.Text=goal.head
	self.goalSub.Text=if self.lay and self.lay.goal.stack then table.concat(goal.items,"\n") else goal.sub
	self:showHud()
	local input=self:input()
	self.keys.Text=if input=="pad" then "L3 RUN  •  A TWICE: LEAP  •  X TALK  •  Y SHOP  •  R1 DUELS" else "SHIFT RUN  •  SPACE TWICE: LEAP  •  E TALK  •  B DUELS"
	self.cardFoot.Text=if input=="pad" then "B: CLOSE" elseif input=="touch" then "✕ OR WALK AWAY TO CLOSE" else "E: TALK  •  WALK AWAY TO CLOSE"
end

local TAG={open={"",nil},loading={"…",nil},starter={"START HERE","gold"},starterLocked={"LATER","muted"},
	owned={"YOUR KIT","paper"},master={"READY FOR YOU","gold"},locked={"LOCKED","muted"}}
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
-- (DEC-041, user 14/11: « tu vas vraiment les rencontrer avec ton personnage
-- […] ensemble près de la porte ») A new player meets the three first
-- inspirations together just inside the gate (HubMap.Welcome); once he has
-- chosen, they are back home. On his screen only: the models move here, their
-- server prompt sleeps and a prompt of this screen takes its place (a prompt
-- the server still places at home could not be reached at the gate).
function Hub:welcome(holder)
	local want=self.kits~=nil and self.kits.state=="ready" and self.kits.needStarter==true
	self.homes=self.homes or {}
	for id,spot in HubMap.Welcome do
		local model=holder:FindFirstChild(id)
		local root=model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
		if model and root and model:GetAttribute("NinjaMaster")==id then
			local entry=self.homes[id]
			if want and not entry then
				entry={pivot=model:GetPivot()}
				self.homes[id]=entry
				local at=HubMap.Origin+spot.at+Vector3.new(0,3,0)
				local target=CFrame.lookAt(at,at+Vector3.new(spot.face.X,0,spot.face.Z))
				model:PivotTo(target*root.CFrame:Inverse()*model:GetPivot())
				local server=model:FindFirstChild("Talk",true)
				if server then server.Enabled=false end
				local prompt=Instance.new("ProximityPrompt")
				prompt.Name="WelcomeTalk";prompt.ActionText="TALK";prompt.ObjectText=(Inspirations.of(id) or {}).title or ""
				prompt.HoldDuration=0;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false
				prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
				prompt:SetAttribute("NinjaMaster",id)
				prompt.Parent=root
				entry.prompt=prompt
			elseif not want and entry then
				if entry.prompt then entry.prompt:Destroy() end
				local server=model:FindFirstChild("Talk",true)
				if server then server.Enabled=true end
				HubMoods.clear(model)
				model:PivotTo(entry.pivot)
				self.homes[id]=nil
			end
		end
	end
end
-- The three's moods (Client/HubMoods): while they wait for a new player at
-- the gate, within sight of him.
function Hub:moods(position)
	if not self.homes then return end
	local folder=workspace:FindFirstChild("NinjaDuelHub")
	local holder=folder and folder:FindFirstChild("Masters")
	if not holder then return end
	for id in self.homes do
		local model=holder:FindFirstChild(id)
		if model and (model:GetPivot().Position-position).Magnitude<160 then
			pcall(HubMoods.apply,model,id,self.moodClock+#id)
		end
	end
end
function Hub:refreshMarkers()
	local folder=workspace:FindFirstChild("NinjaDuelHub")
	local holder=folder and folder:FindFirstChild("Masters")
	if not holder then return end
	self:welcome(holder)
	local P=self.K.palette
	for _,model in holder:GetChildren() do
		local id=model:GetAttribute("NinjaMaster")
		local key=id or (model:GetAttribute("NinjaBoard") and "Proctor") or (model:GetAttribute("NinjaTrain") and "Training") or (model:GetAttribute("NinjaMarket") and "Market")
		if key and (not self.markers[key] or self.markers[key].model~=model) then
			if self.markers[key] then self.markers[key].gui:Destroy() end
			local title=if id then nameOf(id) elseif key=="Training" then "TRAINING" elseif key=="Market" then "THE MARKET" else "THE PROCTOR"
			local place=if id then HubMap.Masters[id] and HubMap.Masters[id].place elseif key=="Training" then HubMap.Training.place elseif key=="Market" then HubMap.Market.place else HubMap.Proctor.place
			self.markers[key]=self:marker(model,id,title,place)
			if self.markers[key] then self.markers[key].key=key end
		end
	end
	for key,marker in self.markers do
		if marker then
			marker.gui.Enabled=self.active and not self.board
			if marker.id then
				local status=self:status(marker.id)
				local tag=TAG[status] or TAG.locked
				-- (14/11) his first kit taken, its master waits for his first duel
				local first=MastersView.firstDuel(self.kits)==marker.id
				if first then tag={"YOUR FIRST DUEL","gold"} end
				marker.tag.Text=tag[1]
				marker.tag.TextColor3=P[tag[2] or "gold"] or P.gold
				-- What matters now is seen through the walls: a new player's
				-- three masters, a master who teaches him now, the first duel.
				local loud=status=="starter" or status=="master" or first
				marker.gui.AlwaysOnTop=loud
				marker.gui.MaxDistance=if loud then 2000 else 140
			elseif marker.key=="Training" then
				-- seen on the ground only (the masters guide a new player)
				local kit=self:trainingKit()
				marker.tag.Text=if kit then "TRY "..nameOf(kit).."'S KIT" else "YOUR KIT"
				marker.gui.AlwaysOnTop=false;marker.gui.MaxDistance=140
			elseif marker.key=="Market" then
				-- seen in the market's lanes only
				marker.tag.Text="LOOKS FOR RYŌ"
				marker.gui.AlwaysOnTop=false;marker.gui.MaxDistance=120
			else
				marker.tag.Text="DUELS  •  TOURNAMENT"
				-- (14/11, Studio: from the gate the proctor's marker sat on
				-- Naruto's, through the walls) while a new player has a master
				-- to find or a first duel to fight, the proctor stays quiet
				local busy=self.kits~=nil and (self.kits.needStarter==true or MastersView.firstDuel(self.kits)~=nil)
				marker.gui.AlwaysOnTop=not busy;marker.gui.MaxDistance=if busy then 140 else 2000
			end
		end
	end
end

-- ------------------------------------------------------------------ training
-- The kit he trains with at the dummy: his own (owned and chosen), else Lee's
-- (it is Lee's ground: TRY LEE'S KIT, as on Lee's card). nil = his own.
function Hub:trainingKit()
	local kits=self.kits
	local selected=kits and kits.selected
	if selected and kits.owned and kits.owned[selected] then return nil end
	return "Leaf"
end
function Hub:train()
	local kits=self.kits
	if not kits or kits.state~="ready" then return end
	local FirstMinute=require(Shared.FirstMinute)
	local kit=self:trainingKit() or kits.selected
	self:hideCard()
	self.send("Tutorial",{player=kit,bot=FirstMinute.rival(kit) or "Lion",here="Training"})
end

-- ------------------------------------------------------------------ the card
function Hub:showCard(id)
	self.cardId=id
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	self.cardAt=root and root.Position
	self:fillCard()
	self.card.Visible=self.active and not self.board
	-- (14/11) While he talks, the goal steps aside (on a laptop or a phone
	-- the card covers its row). With a pad the card's first button takes the
	-- focus: without it no pad could press TAKE HIS KIT.
	self:showHud()
	if self.card.Visible and self:input()=="pad" then
		local target=if self.primary.Visible then self.primary elseif self.second.Visible then self.second else self.closeCard
		task.defer(function() pcall(function() GuiService.SelectedObject=target end) end)
	end
end
function Hub:hideCard()
	self.cardId=nil;self.card.Visible=false;self.actions=nil
	pcall(function()
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.card) then GuiService.SelectedObject=nil end
	end)
	self:showHud()
end
-- What the three buttons do for this master (Shared/MastersView.card).
function Hub:cardActions(id) return MastersView.card(self.kits,id) end
function Hub:fillCard()
	local id=self.cardId
	if not id then return end
	local spot=HubMap.Masters[id]
	local def=Fighters[id]
	-- the black tag: « NAME · INSPIRATION », the suffix in soft red
	local function tag(suffix) self.cardName.Text=nameOf(id)..(if suffix~="" then ' <font color="#FF9C8A">· '..suffix..'</font>' else "") end
	tag("MASTER")
	self.cardPlace.Text=upper((def and def.Title or "")).."  •  "..(spot and spot.place or "")
	self.cardLine.Text="« "..(spot and spot.line or "").." »"
	local a=self:cardActions(id)
	self.actions=a
	-- (DEC-041) a first inspiration, met by the gate: who he is, in a funny
	-- line, and what fighting like him means
	local about=Inspirations.of(id)
	if a.kind=="choose" and about then
		tag("INSPIRATION")
		self.cardPlace.Text=about.title.."  •  LIVES AT "..(spot and spot.place or "")
		self.cardLine.Text=about.line
		self.cardNote.Text=about.with
		self.primary.Text=a.primary and a.primary.label or ""
		self.primary.Visible=a.primary~=nil
		self.primary.AutoButtonColor=true;self.primary.BackgroundColor3=self.M.red
		for _,pair in {{self.second,a.second},{self.third,a.third}} do
			pair[1].Visible=pair[2]~=nil
			pair[1].Text=pair[2] and pair[2].label or ""
		end
		return
	end
	local owned=self.kits and self.kits.owned and self.kits.owned[id]
	local note=a.note or ""
	if owned and self.kits.mastery then
		local tree=self.kits.trees and self.kits.trees[id]
		note=string.format("MASTERY %d  •  %d POINTS EARNED",self.kits.mastery[id] or 0,tree and tree.points or Masters.points(self.kits.mastery[id] or 0))
		local leads=MastersView.leadsTo(id)
		if #leads>0 then
			local names={}
			for _,other in leads do table.insert(names,nameOf(other)) end
			note..="  •  AT "..Masters.Need..": "..table.concat(names,", ").." WANT TO MEET YOU"
		end
	end
	self.cardNote.Text=note
	self.primary.Text=a.primary and a.primary.label or ""
	self.primary.Visible=a.primary~=nil
	self.primary.AutoButtonColor=a.primary~=nil and a.primary.send~=nil
	-- (DA v3) what cannot be pressed yet is grey, not red
	self.primary.BackgroundColor3=if self.primary.AutoButtonColor or (a.primary and a.primary.tree) then self.M.red else Color3.fromRGB(138,124,112)
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
	if item.send then
		-- (14/11) a duel asked at the master's home is fought there, when the
		-- server finds him there (Matches.villageSite)
		local payload=item.send[2]
		if type(payload)=="table" and (item.send[1]=="Start" or item.send[1]=="First" or item.send[1]=="MasterTrial") then
			payload=table.clone(payload);payload.here=self.cardId
		end
		self.send(item.send[1],payload)
	end
end

return Hub
