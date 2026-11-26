-- The way in, on this screen (26/11, DEC-054; the server's Server/Forest).
-- The player attribute NinjaIntro says where a new player is:
--   forest  his first steps, toward the clearing where the bandit waits
--   fight   the bandit (the duel's own screen)
--   path    the bandit down: the path to the great gate
--   create  at the gate's foot: his ninja (the DESIGN's card, Client/
--           CreatorPanel; else the wardrobe or the outfit card)
-- At "create" the card opens by itself; closed, the server lets him into
-- Konoha (action IntroDone). A short line says where to go meanwhile (the
-- CM's words replace these, the DESIGN's look the label's).
local Players=game:GetService("Players")
local Intro={}
Intro.__index=Intro

Intro.HINT={
	forest="FOLLOW THE PATH",
	path="THE GREAT GATE IS AHEAD",
	create="MAKE YOUR NINJA, THEN ENTER KONOHA",
}

function Intro.new(hub)
	local self=setmetatable({hub=hub,opened=false,sent=false,label=nil},Intro)
	-- (26/11, seen in Studio: « FOLLOW THE PATH » stayed over the bandit's duel)
	-- the line only while he walks (the village client steps only then)
	pcall(function()
		game:GetService("RunService").Heartbeat:Connect(function()
			if self.label and self.label.Visible and not self.hub.active then self.label.Visible=false end
		end)
	end)
	return self
end
function Intro.stage()
	local ok,stage=pcall(function() return Players.LocalPlayer:GetAttribute("NinjaIntro") end)
	return if ok then stage else nil
end
function Intro:hint(text)
	local ui=self.hub.ui
	local gui=ui and ui.gui
	if not gui then return end
	if not self.label then
		local label=Instance.new("TextLabel")
		label.Name="ForestHint";label.BackgroundTransparency=1;label.AnchorPoint=Vector2.new(.5,0)
		label.Position=UDim2.new(.5,0,0,96);label.Size=UDim2.fromOffset(520,30)
		label.Font=Enum.Font.Bangers;label.TextScaled=true;label.TextColor3=Color3.fromRGB(246,238,220)
		label.TextStrokeTransparency=.35;label.TextStrokeColor3=Color3.fromRGB(30,24,20)
		label.Parent=gui
		self.label=label
	end
	self.label.Text=text or ""
	-- (not over the gate's card, which says it itself)
	local card=ui.creator
	self.label.Visible=text~=nil and self.hub.active==true and not (card and card:shown())
end
-- (26/11, DESIGN passe 2) At the gate's foot: the DESIGN's card (Client/
-- CreatorPanel; ENTER KONOHA sends "Create", the server dresses him and lets
-- him in), else the wardrobe or the outfit card (closed: "IntroDone").
Intro.RETRY=4
function Intro.panel(ui)
	return ui and (ui.creator or ui.wardrobe or ui.outfitPanel)
end
-- Every frame of the walk (Client/HubClient:step).
function Intro:step(dt)
	local stage=Intro.stage()
	local hub=self.hub
	local ui=hub.ui
	self:hint(if stage then Intro.HINT[stage] else nil)
	if stage~="create" then
		self.opened=false
		if stage==nil then self.sent=false end
		return
	end
	if self.sent then return end
	local panel=Intro.panel(ui)
	if not panel then self.sent=true;hub.send("IntroDone",{});return end
	local card=panel==ui.creator
	if not self.opened then
		if not panel:shown() then
			if card then panel:show() else panel:show(hub.kits or ui.kits) end
		end
		self.opened=panel:shown();self.closedAt=nil
	elseif not panel:shown() then
		if not card then
			self.sent=true
			hub.send("IntroDone",{})
			return
		end
		-- ENTER KONOHA sent "Create": the server lets him in (the stage goes).
		-- Still at the gate a while after (the message lost): the card again.
		local now=os.clock()
		self.closedAt=self.closedAt or now
		if now-self.closedAt>Intro.RETRY then self.opened=false;self.closedAt=nil end
	end
end

return Intro
