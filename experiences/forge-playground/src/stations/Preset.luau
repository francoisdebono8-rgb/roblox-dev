local Root = script.Parent.Parent
local V, W = require(Root.Visuals), require(Root.World)
local Modules = Root.ProductModules.Preset
local PreviewService = require(Modules.PreviewService)
local TargetResolver = require(Modules.TargetResolver)
local CaptureService = require(Modules.CaptureService)
local Adapter = require(script.Parent.PlaygroundApplyAdapter)
local Collection = game:GetService("CollectionService")
local Preset = {}; Preset.__index = Preset
local CYAN, WARM = Color3.fromRGB(62, 220, 205), Color3.fromRGB(255, 197, 112)
function Preset.new(station)
	local self = setmetatable({ station = station, previewService = PreviewService.new(Collection, TargetResolver.new(Collection)) }, Preset)
	self:reset(); return self
end
function Preset:leave() self.preview = nil; self.selected = nil end
function Preset:reset()
	self:leave(); self.station.contents:ClearAllChildren()
	local s = self.station
	self.lights = V.folder(s.contents, "WarehouseLights")
	for i = 1, 36 do
		local row, col = math.floor((i - 1) / 6), (i - 1) % 6
		local position = Vector3.new((col - 2.5) * 5.2, 4, (row - 2.5) * 5.2 - 1)
		local case = V.part(s, self.lights, string.format("Fixture%02d", i), Vector3.new(3, 0.6, 3), position, i <= 6 and CYAN or Color3.fromRGB(231, 224, 202), Enum.Material.Neon)
		V.part(s, s.contents, "Stem" .. i, Vector3.new(0.3, 4, 0.3), position - Vector3.new(0, 2, 0), Color3.fromRGB(101, 113, 124), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Name = string.format(i <= 24 and "Accent_%02d" or "Maintenance_%02d", i)
		light.Color, light.Brightness, light.Range, light.Shadows = case.Color, 0.5, 7, false
		light.Parent = case
		if i <= 24 then light:AddTag("PGAccent") end
	end
	self.recipes = {}
	for index, item in ipairs({ { "Cyan / Color", CYAN, { "Color" } }, { "Warm / Color + Brightness", WARM, { "Color", "Brightness" } } }) do
		local source = V.part(s, s.contents, "RecipeSource" .. index, Vector3.new(3, 1, 3), Vector3.new(-12 + index * 8, 1, 18), item[2], Enum.Material.Neon)
		local light = Instance.new("PointLight"); light.Color, light.Brightness, light.Range, light.Parent = item[2], 2, 7, source
		local recipe = assert(CaptureService.new(Collection):capture({ light }, { properties = item[3], tags = false, attributes = false }))
		recipe.name = item[1]; self.recipes[item[1]] = recipe
		W.sign(s.contents, index == 1 and "COLOR" or "COLOR + POWER", source.Position + Vector3.new(0, 2.5, 0), 7, item[2])
	end
	self.summary, self.message = "36 real lights / 2 exact-field recipes", "Preview the Accent-tagged lights."
end
function Preset:context(options)
	return { recipe = self.recipes[options.recipe], selection = { self.lights },
		options = { scope = "Descendants", className = "PointLight", nameContains = "Accent", tag = "PGAccent" } }
end
function Preset:scan(options)
	local c = self:context(options)
	local preview, err = self.previewService:build(c.recipe, c.selection, c.options)
	assert(preview, err); self.preview, self.selected = preview, 1
	self.summary = string.format("%d scanned / %d compatible\n%d affected / %d matching / %d ignored\n%d writes", preview.scannedCount, preview.compatibleCount, preview.affectedCount, preview.matchingCount, preview.ignoredCount, preview.totalChanges)
	self.message = "PreviewService / Color only leaves Brightness untouched"
end
function Preset:handle(action, options, index)
	if action == "run" then self:scan(options)
	elseif action == "configure" then self:leave(); self.summary = "Recipe changed / Preview required"
	elseif action == "select" and self.preview and self.preview.results[index] then self.selected = index
	elseif action == "perturb" and self.preview then
		local first = self.preview.affected[1]
		if first then first.Color = Color3.fromRGB(227, 87, 98); first.Parent.Color = first.Color end
		self.message = "One target changed. Applying the old plan must fail."
	elseif action == "apply" then
		assert(self.preview, "Preview first.")
		local ok, counts = pcall(Adapter.apply, self.lights, self.preview.plan, self:context(options))
		if not ok then self:leave(); self.message = V.message(counts); return end
		for _, case in ipairs(self.lights:GetChildren()) do case.Color = case:FindFirstChildWhichIsA("PointLight").Color end
		self:scan(options)
		self.message = string.format("Applied: %d targets / %d property writes", counts.targets, counts.properties)
	end
end
function Preset:state()
	local rows, highlights = {}, {}
	if self.preview then
		for _, result in ipairs(self.preview.results) do
			local lines = {}
			for _, change in ipairs(result.changes) do table.insert(lines, change.name .. ": " .. V.format(change.before) .. " -> " .. V.format(change.after)) end
			table.insert(rows, { title = result.instance.Name .. " / " .. result.status, detail = #lines > 0 and table.concat(lines, "\n") or result.reason or "Already matches", instance = result.instance:IsA("Light") and result.instance.Parent or result.instance })
			if result.status == "affected" then table.insert(highlights, result.instance.Parent) end
		end
	end
	return { summary = self.summary, message = self.message, rows = rows, selected = self.selected,
		canApply = self.preview ~= nil and self.preview.totalChanges > 0, highlights = highlights }
end
return Preset
