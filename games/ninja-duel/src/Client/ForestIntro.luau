-- The way in, on this screen (26/11, DEC-054; the server's Server/Forest).
-- The player attribute NinjaIntro says where a new player is:
--   forest  his first steps, toward the clearing where the bandit waits
--   fight   the bandit (the duel's own screen)
--   path    the bandit down: the path to the great gate
--   create  at the gate's foot: his ninja (the wardrobe, else the outfit card)
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
	return setmetatable({hub=hub,opened=false,sent=false,label=nil},Intro)
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
	self.label.Visible=text~=nil and self.hub.active==true
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
	local panel=ui and (ui.wardrobe or ui.outfitPanel)
	if not panel then self.sent=true;hub.send("IntroDone",{});return end
	if not self.opened then
		if not panel:shown() then panel:show(hub.kits or ui.kits) end
		self.opened=panel:shown()
	elseif not panel:shown() then
		self.sent=true
		hub.send("IntroDone",{})
	end
end

return Intro
