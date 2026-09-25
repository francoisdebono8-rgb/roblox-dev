local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local ApplyService = require(modules.ApplyService)
local CaptureService = require(modules.CaptureService)
local PreviewService = require(modules.PreviewService)
local Schema = require(modules.Schema)
local TargetResolver = require(modules.TargetResolver)
local ValueCodec = require(modules.ValueCodec)

local captureService = CaptureService.new(CollectionService)
local previewService = PreviewService.new(CollectionService, TargetResolver.new(CollectionService))

local function history()
	local service = { beginCount = 0, finishCount = 0 }
	function service:TryBeginRecording()
		self.beginCount += 1
		return "schema-recording"
	end
	function service:FinishRecording(_, operation)
		self.finishCount += 1
		assert(operation == Enum.FinishRecordingOperation.Commit)
	end
	return service
end

local cases = {
	{ "Part", "BasePart", "Anchored", true, false },
	{ "PointLight", "PointLight", "Brightness", 2, 0.5 },
	{ "SpotLight", "SpotLight", "Angle", 80, 30 },
	{ "SurfaceLight", "SurfaceLight", "Face", Enum.NormalId.Top, Enum.NormalId.Front },
	{ "Sound", "Sound", "Looped", true, false },
	{ "ParticleEmitter", "ParticleEmitter", "Rate", 12, 3 },
	{ "Decal", "Decal", "Transparency", 0.4, 0 },
	{ "Texture", "Texture", "StudsPerTileU", 3, 1 },
	{ "Frame", "GuiObject", "BackgroundTransparency", 0.25, 1 },
	{ "ProximityPrompt", "ProximityPrompt", "HoldDuration", 2, 0.1 },
}

for _, case in ipairs(cases) do
	local className, schemaId, propertyName, sourceValue, targetValue = table.unpack(case)
	local source = Instance.new(className)
	local target = Instance.new(className)
	source[propertyName] = sourceValue
	target[propertyName] = targetValue
	assert(Schema.forInstance(source).id == schemaId, className .. " resolved to the wrong schema")

	local recipe, captureError = captureService:capture({ source }, {
		properties = { propertyName },
		tags = false,
		attributes = false,
	})
	assert(recipe, captureError)
	recipe.name = className .. " recipe"
	assert(next(recipe.properties) == propertyName, "capture must contain only the selected property")

	local preview, previewError = previewService:build(recipe, { target }, { scope = "Selection" })
	assert(preview, previewError)
	assert(preview.affectedCount == 1 and preview.totalChanges == 1)
	local fakeHistory = history()
	local applied, applyResult = ApplyService.new(CollectionService, fakeHistory):apply(recipe, preview.targets)
	assert(applied, tostring(applyResult))
	assert(ValueCodec.equal(Schema.property(schemaId, propertyName), target[propertyName], sourceValue))
	assert(fakeHistory.beginCount == 1 and fakeHistory.finishCount == 1)
	source:Destroy()
	target:Destroy()
end

local sourceConfiguration = Instance.new("Configuration")
sourceConfiguration:SetAttribute("Difficulty", 4)
CollectionService:AddTag(sourceConfiguration, "PresetForgeSchemaTest")
local targetConfiguration = Instance.new("Configuration")
local configurationRecipe = assert(captureService:capture({ sourceConfiguration }, {
	properties = {},
	tags = true,
	attributes = true,
}))
configurationRecipe.name = "Configuration recipe"
assert(configurationRecipe.schemaId == "Configuration")
local configurationPreview = assert(previewService:build(
	configurationRecipe,
	{ targetConfiguration },
	{ scope = "Selection" }
))
assert(configurationPreview.totalChanges == 2)
assert(ApplyService.new(CollectionService, history()):apply(configurationRecipe, configurationPreview.targets))
assert(targetConfiguration:GetAttribute("Difficulty") == 4)
assert(CollectionService:HasTag(targetConfiguration, "PresetForgeSchemaTest"))
sourceConfiguration:Destroy()
targetConfiguration:Destroy()

local valid, validationError = Schema.validateValue("BasePart", "Color", Color3.new(1, 0, 0))
assert(valid == false and validationError:find("Unsupported property") ~= nil)
valid, validationError = Schema.validateValue("BasePart", "Transparency", "unsafe")
assert(valid == false and validationError:find("finite number") ~= nil)
valid, validationError = Schema.validateValue("GuiObject", "ZIndex", 1.5)
assert(valid == false and validationError:find("integer") ~= nil)

return true
