local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local PreviewService = require(modules.PreviewService)
local TargetResolver = require(modules.TargetResolver)

local root = Instance.new("Folder")
root.Name = "ScopeRoot"
local function part(name, anchored, parent)
	local value = Instance.new("Part")
	value.Name = name
	value.Anchored = anchored
	value.Parent = parent
	return value
end

local glowA = part("GlowA", false, root)
local glowB = part("GlowB", true, root)
local other = part("Other", false, root)
local light = Instance.new("PointLight")
light.Name = "GlowLight"
light.Parent = root
local nested = Instance.new("Folder")
nested.Name = "Nested"
nested.Parent = root
local glowNested = part("GlowNested", false, nested)
for _, instance in ipairs({ glowA, glowB, glowNested }) do
	CollectionService:AddTag(instance, "PresetForgeBulkTest")
end

local recipe = {
	name = "Anchored bulk",
	schemaId = "BasePart",
	capture = { tags = false, attributes = false },
	properties = { Anchored = true },
	tags = {},
	attributes = {},
}
local previewService = PreviewService.new(CollectionService, TargetResolver.new(CollectionService))
local options = {
	scope = "Descendants",
	className = "Part",
	nameContains = "glow",
	tag = "PresetForgeBulkTest",
}
local preview, previewError = previewService:build(recipe, { root }, options)
assert(preview, previewError)
assert(preview.selectionCount == 1 and preview.scannedCount == 6)
assert(preview.compatibleCount == 3 and preview.affectedCount == 2 and preview.matchingCount == 1)
assert(preview.ignoredCount == 3 and #preview.targets == 2)
assert(#preview.affected == 2 and #preview.matching == 1 and #preview.ignored == 3)

local detailed
for _, result in ipairs(preview.results) do
	if result.instance == glowA then
		detailed = result
	end
end
assert(detailed and detailed.status == "affected" and #detailed.changes == 1)
assert(detailed.changes[1].before == false and detailed.changes[1].after == true)
assert(glowA.Anchored == false and glowNested.Anchored == false, "Preview must not mutate descendants")

local repeated = assert(previewService:build(recipe, { root }, options))
assert(PreviewService.same(preview, repeated))
glowA.Color = Color3.fromRGB(255, 0, 0)
local unrelatedChange = assert(previewService:build(recipe, { root }, options))
assert(PreviewService.same(preview, unrelatedChange), "unselected properties must not stale a Preview")
glowA.Anchored = true
local selectedChange = assert(previewService:build(recipe, { root }, options))
assert(not PreviewService.same(preview, selectedChange), "selected property changes must stale a Preview")
glowA.Anchored = false

local mixed = assert(previewService:build(recipe, { glowA, light, glowB }, { scope = "Selection" }))
assert(mixed.scannedCount == 3 and mixed.compatibleCount == 2)
assert(mixed.affectedCount == 1 and mixed.matchingCount == 1 and mixed.ignoredCount == 1)

local noNameFilter = assert(previewService:build(recipe, { root }, {
	scope = "Descendants",
	className = "Part",
	nameContains = "",
	tag = "PresetForgeBulkTest",
}))
assert(noNameFilter.compatibleCount == 3 and noNameFilter.ignoredCount == 3)
local invalid, invalidError = previewService:build(recipe, { root }, {
	scope = "Descendants",
	className = "Model",
	nameContains = "",
	tag = "",
})
assert(invalid == nil and invalidError:find("supported class filter") ~= nil)

root:Destroy()
return true
