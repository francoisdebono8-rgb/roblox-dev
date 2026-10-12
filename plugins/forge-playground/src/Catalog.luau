local Catalog = {
	version = "0.1.0", order = { "access", "curve", "joint", "schema", "preset" },
	stations = {
		access = { title = "AccessForge", accent = Color3.fromRGB(232, 219, 87),
			instruction = "Choose START, then an END platform.", run = "Preview", apply = "Build", controls = {
				{ key = "endpoint", label = "Destination", kind = "choice", values = { "Straight", "Switchback", "Catwalk", "Invalid" }, default = "Straight" },
				{ key = "rails", label = "Guardrails", kind = "toggle", default = true },
			} },
		curve = { title = "CurveForge", accent = Color3.fromRGB(140, 198, 255),
			instruction = "Choose a point. Change its offset.", run = "Preview", apply = "Build", controls = {
				{ key = "mode", label = "Output", kind = "choice", values = { "Cable", "Repeat" }, default = "Cable" },
				{ key = "point", label = "Control point", kind = "choice", values = { "1", "2", "3", "4" }, default = "2" },
				{ key = "offset", label = "Side offset", kind = "number", min = -6, max = 6, step = 3, default = 0 },
				{ key = "count", label = "Copies", kind = "number", min = 6, max = 24, step = 3, default = 12 },
			} },
		joint = { title = "JointForge", accent = Color3.fromRGB(255, 185, 77),
			instruction = "Scan the mechanism. Select one issue.", run = "Scan", apply = "Repair selected", controls = {
				{ key = "endpoint", label = "Broken joint: endpoint", kind = "choice", values = { "Handle", "Door" }, default = "Handle" },
			} },
		schema = { title = "SchemaForge", accent = Color3.fromRGB(218, 156, 225),
			instruction = "Audit the crates. Inspect a finding.", run = "Audit", apply = "Safe repair selected", controls = {} },
		preset = { title = "PresetForge", accent = Color3.fromRGB(62, 220, 205),
			instruction = "Choose a recipe. Preview the light changes.", run = "Preview", apply = "Apply recipe", controls = {
				{ key = "recipe", label = "Exact fields", kind = "choice", values = { "Cyan / Color", "Warm / Color + Brightness" }, default = "Cyan / Color" },
			} },
	},
}
function Catalog.defaults(id)
	local result = {}
	for _, field in ipairs(Catalog.stations[id].controls) do result[field.key] = field.default end
	return result
end
return Catalog
