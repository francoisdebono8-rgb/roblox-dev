local Settings = {}

Settings.defaults = {
	Mode = "Straight", Width = 6, TreadDepth = 2, RiserHeight = 0.8,
	Thickness = 0.3, Landing = false, LandingDepth = 6, ReturnSide = "Right",
	RailLeft = true, RailRight = true, RailHeight = 3.5, PostSpacing = 6,
	MidRail = true, RailProfile = "Square", Supports = false, SupportSpacing = 12,
	FloorHeight = 0, Material = "DiamondPlate", Color = Color3.fromRGB(102, 112, 119),
	RailColor = Color3.fromRGB(236, 171, 55), Anchored = true, CanCollide = true,
}
Settings.materials = { "DiamondPlate", "Metal", "CorrodedMetal", "Concrete", "SmoothPlastic", "WoodPlanks" }
Settings.limits = {
	Width = { 2, 100 }, TreadDepth = { 0.5, 20 }, RiserHeight = { 0.1, 4 },
	Thickness = { 0.05, 4 }, LandingDepth = { 1, 100 }, RailHeight = { 1, 12 },
	PostSpacing = { 0.5, 30 }, SupportSpacing = { 1, 100 }, FloorHeight = { -10000, 10000 },
}
Settings.MAX_PARTS = 1000
Settings.MAX_STEPS = 256

function Settings.number(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Settings.validate(input)
	assert(type(input) == "table", "Invalid settings.")
	local result = {}
	for key, default in pairs(Settings.defaults) do
		local value = input[key]
		local bounds = Settings.limits[key]
		if bounds then
			assert(Settings.number(value) and value >= bounds[1] and value <= bounds[2], key .. ": enter " .. bounds[1] .. " to " .. bounds[2] .. ".")
		elseif typeof(default) == "Color3" then
			assert(typeof(value) == "Color3", key .. ": choose a valid color.")
			for _, c in ipairs({ value.R, value.G, value.B }) do assert(Settings.number(c) and c >= 0 and c <= 1, "Invalid color component.") end
		elseif type(default) == "boolean" then
			assert(type(value) == "boolean", key .. ": use the checkbox.")
		elseif key == "Mode" then
			assert(table.find({ "Straight", "Switchback", "Catwalk" }, value), "Choose a supported structure mode.")
		elseif key == "ReturnSide" then
			assert(value == "Left" or value == "Right", "Choose Left or Right return.")
		elseif key == "RailProfile" then
			assert(value == "Square" or value == "Round", "Choose Square or Round rails.")
		elseif key == "Material" then
			assert(table.find(Settings.materials, value), "Choose a supported material.")
		end
		result[key] = value
	end
	return result
end

return Settings
