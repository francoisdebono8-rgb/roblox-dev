local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local ApplyService = require(modules.ApplyService)
local CaptureService = require(modules.CaptureService)
local PreviewService = require(modules.PreviewService)
local TargetResolver = require(modules.TargetResolver)

local source = Instance.new("Part")
source.Name = "Source"
source.Anchored = true
source.CanCollide = false
source.Transparency = 0.75
source:SetAttribute("Damage", 25)
CollectionService:AddTag(source, "PresetForgeCaptureTest")

local captureService = CaptureService.new(CollectionService)
local captured, captureError = captureService:capture({ source }, {
	properties = { "Anchored" },
	tags = true,
	attributes = true,
})
assert(captured, captureError)
captured.name = "Selective part"
assert(captured.properties.Anchored == true and captured.properties.CanCollide == nil)

local target = Instance.new("Part")
target.Name = "Target"
target.Anchored = false
target.CanCollide = true
target.Transparency = 0.1
target.Color = Color3.fromRGB(12, 34, 56)
target:SetAttribute("Damage", 2)
target:SetAttribute("OutsideRecipe", "keep")
CollectionService:AddTag(target, "KeepTag")

local beforeColor = target.Color
local previewService = PreviewService.new(CollectionService, TargetResolver.new(CollectionService))
local preview, previewError = previewService:build(captured, { target }, { scope = "Selection" })
assert(preview, previewError)
assert(preview.affectedCount == 1 and preview.matchingCount == 0 and preview.ignoredCount == 0)
assert(preview.propertyChanges.Anchored == 1 and preview.propertyChanges.CanCollide == nil)
assert(preview.tagChanges.PresetForgeCaptureTest == 1)
assert(preview.attributeChanges.Damage.updated == 1)
assert(target.Anchored == false and target:GetAttribute("Damage") == 2, "Preview must be read-only")

local history = { beginCount = 0, finishCount = 0 }
function history:TryBeginRecording(name, displayName)
	assert(name == "PresetForgeApply" and displayName == "Apply PresetForge recipe")
	self.beginCount += 1
	return "capture-recording"
end
function history:FinishRecording(_, operation)
	self.finishCount += 1
	assert(operation == Enum.FinishRecordingOperation.Commit)
end
local applied, counts = ApplyService.new(CollectionService, history):apply(captured, preview.targets)
assert(applied, tostring(counts))
assert(counts.targets == 1 and counts.properties == 1 and counts.tags == 1 and counts.attributes == 1)
assert(history.beginCount == 1 and history.finishCount == 1)
assert(target.Anchored == true and target.CanCollide == true and math.abs(target.Transparency - 0.1) < 1e-6)
assert(target.Color == beforeColor, "properties outside the recipe must be preserved")
assert(target:GetAttribute("Damage") == 25 and target:GetAttribute("OutsideRecipe") == "keep")
assert(CollectionService:HasTag(target, "PresetForgeCaptureTest") and CollectionService:HasTag(target, "KeepTag"))

local tampered = {
	name = "Tampered",
	schemaId = "BasePart",
	capture = { tags = false, attributes = false },
	properties = { Color = Color3.new(1, 0, 0) },
	tags = {},
	attributes = {},
}
local rejected, rejection = ApplyService.new(CollectionService, history):apply(tampered, { target })
assert(rejected == false and rejection:find("Unsupported property") ~= nil)
assert(history.beginCount == 1, "an invalid recipe must be rejected before Undo recording")

local model = Instance.new("Model")
local invalid, invalidError = captureService:capture({ model }, {
	properties = {},
	tags = true,
	attributes = false,
})
assert(invalid == nil and invalidError:find("not supported") ~= nil)

source:Destroy()
target:Destroy()
model:Destroy()
return true
