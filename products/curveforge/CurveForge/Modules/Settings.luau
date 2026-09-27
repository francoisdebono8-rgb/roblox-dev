local Settings = {}
Settings.defaults = { Mode = "Cable", Diameter = 0.4, SegmentLength = 1, Color = Color3.fromRGB(52, 179, 161), Material = "SmoothPlastic", Anchored = true, CanCollide = false, CastShadow = true, Distribution = "Spacing", Spacing = 3, Count = 12, Orient = true, PreserveRotation = true, Endpoints = true, ControlRoll = false }
Settings.materials = { "SmoothPlastic", "Plastic", "Metal", "DiamondPlate", "Wood", "Concrete", "Neon", "Glass" }
local bounds = { Diameter = { 0.05, 50 }, SegmentLength = { 0.1, 100 }, Spacing = { 0.1, 1000 }, Count = { 2, 500 } }
function Settings.validate(settings)
	local result = {}
	for key, default in pairs(Settings.defaults) do
		local value = settings[key]
		if key == "ControlRoll" and value == nil then value = false end
		assert(typeof(value) == typeof(default), "Invalid setting: " .. key)
		if bounds[key] then
			assert(value == value and value >= bounds[key][1] and value <= bounds[key][2], key .. " outside supported range " .. bounds[key][1] .. " to " .. bounds[key][2])
		end
		result[key] = value
	end
	assert(result.Count % 1 == 0, "Count must be a whole number.")
	assert(result.Mode == "Cable" or result.Mode == "Repeat", "Unsupported output mode.")
	assert(result.Distribution == "Spacing" or result.Distribution == "Count", "Unsupported distribution.")
	assert(table.find(Settings.materials, result.Material), "Unsupported material.")
	for _, v in ipairs({ result.Color.R, result.Color.G, result.Color.B }) do assert(v == v and v >= 0 and v <= 1, "Invalid color.") end
	return result
end
return Settings
