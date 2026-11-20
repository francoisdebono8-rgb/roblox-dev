-- The game's one light (14/11, François: « toutes les textures n'apparaissent
-- pas au même moment, les lumières, surtout dans l'écran d'accueil, quand on
-- change de perso… même au début du match »). Measured in Studio on a
-- first arrival: the place's light at 0.05 s, the client's look at 0.73 s,
-- the server's own afternoon (another sun, another grade) at 1.79 s when the
-- first arena was built, the client's look again at 1.86 s: the screen
-- changed light three times in two seconds, and up to a second each time
-- (the client looked once a second).
--
-- One table now, applied by the server at its start (Server/Main: what a
-- client receives on joining is already this light) and by the client
-- (Client/WorldLook), so a later apply changes nothing on screen.
-- Presentation only.
local Look={}
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

-- (Look pass 2, 03/11; 12/11 QA of b822ee5, validated by François) a lower,
-- warmer sun, shadows on, less light, a darker fill.
-- (14/11, seen in Studio, François: « l'ombre est bizarre ») At 16.9 h the
-- stadium wall's shadow covered the whole field: the fight happened in the
-- dark. At 15.2 h the field is in the sun; the validated light levels stay.
-- (20/11, DEC-044, François 21 h 47: « c'est trop sombre ») A frank daylight
-- Konoha: the sun higher (14 h), the exposure back to neutral, the shadows
-- kept for the relief but filled (ambients lifted), a lighter, clearer air
-- (less haze, a sky-blue decay), a grade that brightens instead of
-- darkening. What burnt the image white on 12/11 stays out: the shadows stay
-- on and the bloom only takes what really shines (a higher threshold).
Look.LIGHT={
	ClockTime=14,GeographicLatitude=32,Brightness=2.8,ExposureCompensation=0,GlobalShadows=true,
	EnvironmentDiffuseScale=.75,EnvironmentSpecularScale=.45,ShadowSoftness=.22,
	Ambient=rgb(104,102,114),OutdoorAmbient=rgb(142,142,156),
	ColorShift_Top=rgb(255,232,200),ColorShift_Bottom=rgb(118,138,182),
}
Look.ATMOSPHERE={Density=.24,Offset=.25,Color=rgb(222,230,240),Decay=rgb(150,172,206),Glare=.12,Haze=.55}
-- The graded image: colour and a light contrast, a hint of warmth, a soft
-- bloom on what shines, rays round the sun, the far stands softly out of
-- focus.
Look.EFFECTS={
	{"ColorCorrectionEffect","NinjaLookGrade",{Saturation=.2,Contrast=.14,Brightness=.03,TintColor=rgb(255,250,242)}},
	{"BloomEffect","NinjaLookBloom",{Intensity=.22,Size=20,Threshold=2.6}},
	{"SunRaysEffect","NinjaLookRays",{Intensity=.03,Spread=.7}},
	{"DepthOfFieldEffect","NinjaLookDepth",{FarIntensity=.12,FocusDistance=40,InFocusRadius=80,NearIntensity=0}},
}
Look.CLOUDS={Cover=.42,Density=.5,Color=rgb(255,255,255)}
-- The menu's studio (Client/MenuStage films the roster's fighters in a dark
-- box: low ambient, no sky light; key and coloured back lights model them).
Look.STUDIO={Ambient=rgb(40,36,46),OutdoorAmbient=rgb(40,36,46),ExposureCompensation=0,Brightness=0,
	EnvironmentDiffuseScale=0,EnvironmentSpecularScale=0,ColorShift_Top=rgb(0,0,0),ColorShift_Bottom=rgb(0,0,0)}

-- Equal as the engine stores them (floats are read back as float32).
local function same(a,b)
	if type(a)=="number" and type(b)=="number" then return math.abs(a-b)<1e-3 end
	if typeof(a)=="Color3" and typeof(b)=="Color3" then
		return math.abs(a.R-b.R)<.002 and math.abs(a.G-b.G)<.002 and math.abs(a.B-b.B)<.002
	end
	return a==b
end
Look.same=same
local function set(obj,k,v)
	pcall(function() if not same((obj::any)[k],v) then (obj::any)[k]=v end end)
end

-- The values a mode wants: the world's light, with the studio's over it.
function Look.values(studio)
	local out=table.clone(Look.LIGHT)
	if studio then for k,v in Look.STUDIO do out[k]=v end end
	return out
end

-- Sets the light, the air, the grade and the clouds; writes only what
-- differs, so applying it twice changes nothing on screen.
function Look.apply(lighting,terrain,studio)
	lighting=lighting or game:GetService("Lighting")
	for k,v in Look.values(studio) do set(lighting,k,v) end
	set(lighting,"Technology",Enum.Technology.Future)
	-- One air: every atmosphere gets the same values (the engine uses one).
	local any=false
	for _,atmo in lighting:GetChildren() do
		if atmo:IsA("Atmosphere") then
			any=true
			for k,v in Look.ATMOSPHERE do set(atmo,k,v) end
		end
	end
	if not any then
		local atmo=Instance.new("Atmosphere");atmo.Name="NinjaLookAtmosphere"
		for k,v in Look.ATMOSPHERE do (atmo::any)[k]=v end
		atmo.Parent=lighting
	end
	for _,spec in Look.EFFECTS do
		local class,name,props=spec[1],spec[2],spec[3]
		local e=lighting:FindFirstChild(name)
		if not e then e=Instance.new(class);e.Name=name;e.Parent=lighting end
		for k,v in props do set(e,k,v) end
	end
	-- An older build's grade, bloom and rays (Server/World made them) stay off.
	for _,name in {"NinjaDuelGrade","NinjaDuelBloom","NinjaDuelRays"} do
		local e=lighting:FindFirstChild(name);if e and e.Enabled then e.Enabled=false end
	end
	terrain=terrain or workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds=terrain:FindFirstChildOfClass("Clouds")
		if not clouds then clouds=Instance.new("Clouds");clouds.Parent=terrain end
		for k,v in Look.CLOUDS do set(clouds,k,v) end
	end
end

-- True when the lighting already shows the mode (nothing to write).
function Look.holds(lighting,studio)
	for k,v in Look.values(studio) do
		local ok,equal=pcall(function() return same((lighting::any)[k],v) end)
		if ok and not equal then return false end
	end
	return true
end

return Look
