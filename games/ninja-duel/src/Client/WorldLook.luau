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
-- (Look pass 2, 03/11.) A lower, warmer sun from the side the camera mostly
-- faces across: the wall throws a long shadow over the earth, bodies get a lit
-- side and a shade side; the shade is cool and darker than before, so the
-- image has depth instead of the flat, all-lit midday of a default place.
local LIGHT={
	ClockTime=16.9,GeographicLatitude=36,Brightness=3.6,ExposureCompensation=.12,
	EnvironmentDiffuseScale=.7,EnvironmentSpecularScale=.32,ShadowSoftness=.12,
	Ambient=rgb(84,80,100),OutdoorAmbient=rgb(126,120,142),
	ColorShift_Top=rgb(255,212,164),ColorShift_Bottom=rgb(84,104,160),
}
local function effect(class,name,props)
	local e=Lighting:FindFirstChild(name)
	if not e then e=Instance.new(class);e.Name=name;e.Parent=Lighting end
	for k,v in props do pcall(function() (e::any)[k]=v end) end
	return e
end

function WorldLook.apply()
	for k,v in LIGHT do pcall(function() (Lighting::any)[k]=v end) end
	-- The server's own grade, bloom and rays are replaced by this look's.
	for _,name in {"NinjaDuelGrade","NinjaDuelBloom","NinjaDuelRays"} do
		local e=Lighting:FindFirstChild(name);if e then e.Enabled=false end
	end
	-- One air: the server's atmosphere and this look's would fight (the engine
	-- uses one of them, either), so every atmosphere gets the same values.
	local any=false
	for _,atmo in Lighting:GetChildren() do
		if atmo:IsA("Atmosphere") then
			any=true
			atmo.Density=.3;atmo.Offset=.2;atmo.Color=rgb(236,214,190);atmo.Decay=rgb(112,100,128);atmo.Glare=.55;atmo.Haze=1.6
		end
	end
	if not any then Instance.new("Atmosphere",Lighting);return WorldLook.apply() end
	effect("ColorCorrectionEffect","NinjaLookGrade",{Saturation=.16,Contrast=.18,Brightness=-.015,TintColor=rgb(255,244,234)})
	effect("BloomEffect","NinjaLookBloom",{Intensity=.65,Size=30,Threshold=1.25})
	effect("SunRaysEffect","NinjaLookRays",{Intensity=.07,Spread=.75})
	effect("DepthOfFieldEffect","NinjaLookDepth",{FarIntensity=.18,FocusDistance=40,InFocusRadius=75,NearIntensity=0})
	local terrain=workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds=terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover=.52;clouds.Density=.62;clouds.Color=rgb(255,250,246);clouds.Parent=terrain
	end
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
local function isBody(model)
	return model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")~=nil or (model:IsA("Model") and model:GetAttribute("Fighter")~=nil)
end
function WorldLook.start()
	WorldLook.apply()
	local function watch(root)
		for _,d in root:GetDescendants() do if d:IsA("Model") and (d.Name=="PlayerFighter" or d.Name=="AIFighter" or d.Name=="ShadowClone" or d:GetAttribute("Fighter")) then outline(d) end end
		root.DescendantAdded:Connect(function(d)
			if d:IsA("Model") then
				task.defer(function()
					if d.Parent and (d.Name=="PlayerFighter" or d.Name=="AIFighter" or d.Name=="ShadowClone" or d:GetAttribute("Fighter") or isBody(d)) then outline(d) end
				end)
			end
		end)
	end
	watch(workspace)
	-- The stadium's own dressing on this screen (banners, ink circle, air).
	local dress=script.Parent:FindFirstChild("ArenaDress")
	if dress then pcall(function() require(dress).start() end) end
	-- The look holds: anything that resets the lighting (a cutscene's grade
	-- ends, the menu's studio gives the light back) finds it again.
	local last=0
	RunService.Heartbeat:Connect(function()
		local t=os.clock()
		if t-last<1 then return end
		last=t
		if not WorldLook.borrowed and math.abs(Lighting.ClockTime-LIGHT.ClockTime)>.01 then WorldLook.apply() end
	end)
end
return WorldLook
