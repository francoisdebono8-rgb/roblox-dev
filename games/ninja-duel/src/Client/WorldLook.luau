-- What the screen looks like (user 03/11: "the brightness, the graphics,
-- everything that shows on the screen"). One look for the whole game, set on
-- this client over the server's afternoon (Server/World.atmosphere):
--   * a late-afternoon sun, lower and warmer: longer shadows that model the
--     bodies and the arena, a cool sky fill from below;
--   * a graded image: more contrast and colour, a warm tint, a softer bloom on
--     what shines, light rays round the sun, the far stands softly out of focus;
--   * a sky with depth (Roblox clouds) and a haze that warms into the distance;
--   * the anime line: every fighter and shadow clone drawn with an ink
--     outline (Highlight), on the stage and in the menu.
-- Client/MenuStage borrows the lighting while it films its studio and gives
-- it back. Presentation only.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local WorldLook={}

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- (14/11) The values live in Shared/Look: the server applies the same light
-- at its start, so the client's apply changes nothing on screen.
local Look=require(game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Look"))
local LIGHT=Look.LIGHT
WorldLook.LIGHT=LIGHT
-- The menu's studio (Client/MenuStage asks for it while the board is filmed).
WorldLook.studio=false

function WorldLook.apply()
	Look.apply(Lighting,workspace:FindFirstChildOfClass("Terrain"),WorldLook.studio)
end
-- The menu's studio on or off, in the same frame (it was MenuStage's own
-- copy of the lighting, which the world's look overwrote a second later).
function WorldLook.setStudio(on)
	WorldLook.studio=on==true
	if not WorldLook.borrowed then WorldLook.apply() end
end

-- The ink line round every fighter body (the duel's two, shadow clones, the
-- menu's two). At most a few dozen Highlights exist at once; each body gets one.
local OUTLINE=rgb(22,17,26)
local function outline(model)
	if model:FindFirstChild("NinjaInkLine") then return end
	local h=Instance.new("Highlight")
	h.Name="NinjaInkLine";h.FillTransparency=1;h.OutlineColor=OUTLINE;h.OutlineTransparency=.15
	h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Adornee=model;h.Parent=model
end
-- Only the two duelling bodies and the menu's fighters: a Highlight also draws
-- the outline of invisible parts, and clones, afterimages and substitution
-- logs hide or fade their parts, so an outline on them floats in the air.
local function isBody(model)
	return model.Name=="PlayerFighter" or model.Name=="AIFighter" or model:GetAttribute("Fighter")~=nil
end
function WorldLook.start()
	WorldLook.apply()
	local function watch(root)
		for _,d in root:GetDescendants() do if d:IsA("Model") and isBody(d) then outline(d) end end
		root.DescendantAdded:Connect(function(d)
			if d:IsA("Model") then
				task.defer(function()
					if d.Parent and isBody(d) then outline(d) end
				end)
			end
		end)
	end
	watch(workspace)
	-- The stadium's own dressing on this screen (banners, ink circle, air).
	local dress=script.Parent:FindFirstChild("ArenaDress")
	if dress then pcall(function() require(dress).start() end) end
	-- The look holds: anything that changes the lighting (the server, a
	-- cutscene's grade ending) finds it again before the next frame is drawn
	-- (it was looked at once a second: up to a second of another light).
	local queued=false
	local function hold()
		if queued or WorldLook.borrowed then return end
		queued=true
		task.defer(function()
			queued=false
			if not WorldLook.borrowed and not Look.holds(Lighting,WorldLook.studio) then WorldLook.apply() end
		end)
	end
	for k in Look.values(true) do
		pcall(function() Lighting:GetPropertyChangedSignal(k):Connect(hold) end)
	end
	Lighting.ChildAdded:Connect(hold)
	-- (and once a second, as a safety)
	local last=0
	RunService.Heartbeat:Connect(function()
		local t=os.clock()
		if t-last<1 then return end
		last=t
		if not WorldLook.borrowed and not Look.holds(Lighting,WorldLook.studio) then hold() end
	end)
end
return WorldLook
