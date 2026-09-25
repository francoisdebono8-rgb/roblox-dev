local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local CaptureService = require(modules.CaptureService)
local PreviewService = require(modules.PreviewService)

local captureService = CaptureService.new(CollectionService)
local previewService = PreviewService.new(CollectionService)

local source = Instance.new("Part")
source.Name = "PresetSource"
source.Anchored = true
source.CanCollide = false
source.CanTouch = false
source.CanQuery = false
source.Transparency = 0.4
source.CastShadow = false
source.Massless = true
source.Color = Color3.fromRGB(240, 20, 20)
source.Material = Enum.Material.Neon
source:SetAttribute("Health", 100)
source:SetAttribute("Label", "Captured")
CollectionService:AddTag(source, "PresetTag")

local options = { properties = true, tags = true, attributes = true }
local captured = assert(captureService:capture({ source }, options))
assert(captured.properties.Anchored == true)
assert(captured.properties.CanCollide == false)
assert(captured.properties.CanTouch == false)
assert(captured.properties.CanQuery == false)
assert(captured.properties.Transparency == 0.4)
assert(captured.properties.CastShadow == false)
assert(captured.properties.Massless == true)
assert(captured.properties.Color == nil and captured.properties.Material == nil, "capture must honor the exact whitelist")

local extraSource = Instance.new("Part")
local invalidMultiple, multipleError = captureService:capture({ source, extraSource }, options)
assert(invalidMultiple == nil and multipleError:find("exactly one") ~= nil)
extraSource:Destroy()
local model = Instance.new("Model")
local invalidType, typeError = captureService:capture({ model }, options)
assert(invalidType == nil and typeError:find("BasePart") ~= nil)

local targetOne = Instance.new("Part")
targetOne.Name = "TargetOne"
targetOne.Anchored = false
targetOne.CanCollide = true
targetOne.CanTouch = true
targetOne.CanQuery = true
targetOne.Transparency = 0
targetOne.CastShadow = true
targetOne.Massless = false
targetOne.Color = Color3.fromRGB(10, 30, 220)
targetOne.Material = Enum.Material.Wood
targetOne:SetAttribute("Health", 25)
targetOne:SetAttribute("OutsidePreset", "keep")
CollectionService:AddTag(targetOne, "KeepTag")

local targetTwo = targetOne:Clone()
targetTwo.Name = "TargetTwo"
targetTwo:SetAttribute("Health", 100)
CollectionService:AddTag(targetTwo, "KeepTag")
CollectionService:AddTag(targetTwo, "PresetTag")

local before = {
	anchored = targetOne.Anchored,
	color = targetOne.Color,
	material = targetOne.Material,
	health = targetOne:GetAttribute("Health"),
	outside = targetOne:GetAttribute("OutsidePreset"),
	hasKeepTag = CollectionService:HasTag(targetOne, "KeepTag"),
	hasPresetTag = CollectionService:HasTag(targetOne, "PresetTag"),
}
local preview = previewService:build(captured, { targetOne, model, targetTwo })
assert(preview.selectionCount == 3 and preview.compatibleCount == 2 and preview.ignoredCount == 1)
assert(preview.propertyChanges.Anchored == 2)
assert(preview.propertyChanges.CanCollide == 2)
assert(preview.propertyChanges.CanTouch == 2)
assert(preview.propertyChanges.CanQuery == 2)
assert(preview.propertyChanges.Transparency == 2)
assert(preview.propertyChanges.CastShadow == 2)
assert(preview.propertyChanges.Massless == 2)
assert(preview.tagChanges.PresetTag == 1)
assert(preview.attributeChanges.Health.updated == 1)
assert(preview.attributeChanges.Label.added == 2)

assert(targetOne.Anchored == before.anchored, "Preview must not change properties")
assert(targetOne.Color == before.color and targetOne.Material == before.material)
assert(targetOne:GetAttribute("Health") == before.health)
assert(targetOne:GetAttribute("OutsidePreset") == before.outside)
assert(CollectionService:HasTag(targetOne, "KeepTag") == before.hasKeepTag)
assert(CollectionService:HasTag(targetOne, "PresetTag") == before.hasPresetTag)

source:Destroy()
targetOne:Destroy()
targetTwo:Destroy()
model:Destroy()

return true
