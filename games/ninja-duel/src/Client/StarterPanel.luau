-- Choose your inspiration (DEC-041, user 14/11 21 h 35: « j'imaginais plus un
-- choix comme un choix de starter […] choisis ton inspi, ou va retrouver ton
-- inspiration, tu as le choix parmi les trois. Et après, un en amène
-- l'autre »). Naruto, Sasuke and Lee are genin of the player's age, not
-- sensei: three cards side by side, each with his funny line
-- (Shared/Inspirations) and where he waits in Konoha; HE'S MY INSPIRATION
-- takes his kit (the server's ChooseStarter), then the goal sends the player
-- to him for his first duel. It opens by itself on a new player's walk once
-- he is dressed (Client/OutfitPanel, when it exists); LATER closes it, the
-- goal still names the three.
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Masters=require(Shared.Masters)
local Fighters=require(Shared.Fighters)
local HubMap=require(Shared.HubMap)
local Shop=require(Shared.Shop)
local Inspirations=require(Shared.Inspirations)
local Text=require(Shared.Text)
local Panel={}
Panel.__index=Panel
Panel.CW,Panel.CH,Panel.GAP=380,470,24
Panel.W=3*Panel.CW+2*Panel.GAP
Panel.H=Panel.CH+150

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end

-- Whether the card should open by itself: a new player walking in Konoha,
-- dressed (when the outfit card exists), no other panel open.
function Panel.wanted(kits,walking,dressed,busy)
	return walking==true and kits~=nil and kits.state=="ready" and kits.needStarter==true and dressed~=false and not busy
end

function Panel.new(kit,gui,send,ui)
	local self=setmetatable({kit=kit,send=send,ui=ui,buttons={}},Panel)
	local P=kit.palette
	self.P=P
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(6,5,8),.25)
	self.root.ZIndex=74;self.root.Visible=false;self.root.Active=true
	local holder=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(Panel.W,Panel.H),P.ink,1)
	holder.AnchorPoint=Vector2.new(.5,.5)
	local scale=kit.create("UIScale",holder,{Scale=1})
	local function fit() scale.Scale=kit.fitScale(workspace.CurrentCamera.ViewportSize,Panel.W+40,Panel.H+40,1.15) end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local title=kit.inkTitle(kit.text(holder,"CHOOSE YOUR INSPIRATION",UDim2.fromOffset(0,0),UDim2.new(1,0,0,64),58,P.paper,kit.TITLE_FONT,Enum.TextXAlignment.Center))
	title.ZIndex=75
	kit.text(holder,"Three genin your age. Fight like the one you pick; he will lead you to the others.",UDim2.fromOffset(0,66),UDim2.new(1,0,0,22),17,P.gold,kit.BODY_FONT,Enum.TextXAlignment.Center).ZIndex=75
	for i,id in Masters.Starters do
		local def=Fighters[id] or {}
		local about=Inspirations.of(id) or {}
		local spot=HubMap.Masters[id]
		local card=kit.inkCard(kit.frame(holder,UDim2.fromOffset((i-1)*(Panel.CW+Panel.GAP),104),UDim2.fromOffset(Panel.CW,Panel.CH),kit.CARD,0))
		card.ZIndex=75
		kit.frame(card,UDim2.fromOffset(0,0),UDim2.new(1,0,0,8),rgb(def.Color or {200,200,200}),0).ZIndex=76
		local name=kit.inkTitle(kit.text(card,Text.upper(def.Name or id),UDim2.fromOffset(22,20),UDim2.fromOffset(Panel.CW-44,56),52,P.paper,kit.TITLE_FONT))
		name.ZIndex=76
		kit.text(card,about.title or "",UDim2.fromOffset(24,78),UDim2.fromOffset(Panel.CW-48,22),18,rgb(def.Color or {230,184,86}),kit.TITLE_FONT).ZIndex=76
		local line=kit.text(card,about.line or "",UDim2.fromOffset(24,112),UDim2.fromOffset(Panel.CW-48,120),17,P.text,kit.BODY_FONT)
		line.TextWrapped=true;line.TextYAlignment=Enum.TextYAlignment.Top;line.ZIndex=76
		local with=kit.text(card,about.with or "",UDim2.fromOffset(24,240),UDim2.fromOffset(Panel.CW-48,70),16,P.gold,kit.BODY_FONT)
		with.TextWrapped=true;with.TextYAlignment=Enum.TextYAlignment.Top;with.ZIndex=76
		kit.text(card,"HE WAITS AT  "..(spot and spot.place or ""),UDim2.fromOffset(24,322),UDim2.fromOffset(Panel.CW-48,18),12,P.muted,kit.BODY_FONT).ZIndex=76
		local pick=kit.button(card,"HE'S MY INSPIRATION",UDim2.fromOffset(20,Panel.CH-84),UDim2.fromOffset(Panel.CW-40,62),function() self:choose(id) end,P.red)
		pick.TextSize=26;pick.ZIndex=77
		self.buttons[id]=pick
	end
	self.later=kit.button(holder,"LATER",UDim2.new(.5,-110,0,Panel.H-34),UDim2.fromOffset(220,40),function() self:hide();self.dismissed=true end)
	self.later.TextSize=20
	pcall(function()
		UIS.InputBegan:Connect(function(input)
			if input.KeyCode==Enum.KeyCode.ButtonB and self.root.Visible then self:hide();self.dismissed=true end
		end)
	end)
	self.clock=0
	RunService.Heartbeat:Connect(function(dt) self:watch(dt) end)
	return self
end

function Panel:shown() return self.root.Visible end
function Panel:show(kits)
	if kits then self.kits=kits end
	self.root.Visible=true
	if UIS:GetLastInputType().Name:sub(1,7)=="Gamepad" then
		local first=self.buttons[Masters.Starters[1]]
		task.defer(function() pcall(function() GuiService.SelectedObject=first end) end)
	end
end
function Panel:hide()
	self.root.Visible=false
	pcall(function()
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.root) then GuiService.SelectedObject=nil end
	end)
end
function Panel:choose(id)
	self.send("ChooseStarter",{player=id})
	self.dismissed=true
	self:hide()
end
function Panel:refresh(kits)
	self.kits=kits
	-- his kit taken (here, at the shop or at the inspiration's home): gone
	if self.root.Visible and kits and not kits.needStarter then self:hide() end
end
-- Twice a second: opens by itself for a new player walking in Konoha.
function Panel:watch(dt)
	self.clock+=dt
	if self.clock<.5 then return end
	self.clock=0
	if self.root.Visible or self.dismissed then return end
	local ui=self.ui
	if not ui or not Players.LocalPlayer.Character then return end
	local kits=self.kits
	local dressed=if Shop.dressed and kits then Shop.dressed(kits.style) else nil
	local busy=(ui.shopPanel and ui.shopPanel:shown()) or (ui.treePanel and ui.treePanel:shown()) or (ui.outfitPanel and ui.outfitPanel:shown())
	if Panel.wanted(kits,ui.hubWalk,dressed,busy) then self:show() end
end

return Panel
