local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local ApplyService = require(modules.ApplyService)
local PreviewService = require(modules.PreviewService)
local TargetResolver = require(modules.TargetResolver)
local function apply(historyService, recipe, targets)
	local preview = assert(PreviewService.new(CollectionService, TargetResolver.new(CollectionService)):build(recipe, targets, { scope = "Selection" }))
	return ApplyService.new(CollectionService, historyService):apply(preview.plan, { recipe = recipe, selection = targets, options = { scope = "Selection" } })
end

local history = { beginCount = 0, finishCount = 0, operation = nil }
function history:TryBeginRecording(name, displayName)
	assert(name == "PresetForgeApply" and displayName == "Apply PresetForge recipe")
	self.beginCount += 1
	return "apply-recording"
end
function history:FinishRecording(recording, operation)
	assert(recording == "apply-recording")
	self.finishCount += 1
	self.operation = operation
end

local recipe = {
	name = "Safe apply",
	schemaId = "BasePart",
	capture = { tags = true, attributes = true },
	properties = { Anchored = true },
	tags = { "PresetForgeApplyTest" },
	attributes = { Level = 4 },
}
local targetOne = Instance.new("Part")
targetOne.Anchored = false
targetOne.CanCollide = false
targetOne.Color = Color3.fromRGB(12, 34, 56)
targetOne:SetAttribute("Level", 1)
targetOne:SetAttribute("OutsideRecipe", "keep")
CollectionService:AddTag(targetOne, "KeepTag")
local targetTwo = targetOne:Clone()
targetTwo:SetAttribute("Level", nil)

local applied, counts = apply(history, recipe, { targetOne, targetTwo })
assert(applied, tostring(counts))
assert(counts.targets == 2 and counts.properties == 2 and counts.tags == 2 and counts.attributes == 2)
assert(history.beginCount == 1 and history.finishCount == 1)
assert(history.operation == Enum.FinishRecordingOperation.Commit)
for _, target in ipairs({ targetOne, targetTwo }) do
	assert(target.Anchored == true and target.CanCollide == false)
	assert(target.Color == Color3.fromRGB(12, 34, 56))
	assert(target:GetAttribute("Level") == 4 and target:GetAttribute("OutsideRecipe") == "keep")
	assert(CollectionService:HasTag(target, "PresetForgeApplyTest"))
	assert(CollectionService:HasTag(target, "KeepTag"))
end

local emptyApplied, emptyError = apply(history, recipe, {})
assert(emptyApplied == false and emptyError:find("No affected") ~= nil)
assert(history.beginCount == 1)

local unavailableHistory = {}
function unavailableHistory:TryBeginRecording()
	return nil
end
local untouched = Instance.new("Part")
untouched.Anchored = false
local refused, refusalError = apply(unavailableHistory, recipe, { untouched })
assert(refused == false and refusalError:find("undo recording") ~= nil and untouched.Anchored == false)

local failingHistory = { calls = 0 }
function failingHistory:TryBeginRecording()
	return "failing-recording"
end
function failingHistory:FinishRecording(_, operation)
	self.calls += 1
	if operation == Enum.FinishRecordingOperation.Commit then
		error("injected commit failure")
	end
end
local rollbackTarget = Instance.new("Part")
rollbackTarget.Anchored = false
local failed, failureMessage = apply(failingHistory, recipe, { rollbackTarget })
assert(failed == false and failureMessage:find("rolled back") ~= nil)
assert(rollbackTarget.Anchored == false)
assert(not CollectionService:HasTag(rollbackTarget, "PresetForgeApplyTest"))
assert(rollbackTarget:GetAttribute("Level") == nil)
assert(failingHistory.calls == 2, "failed commit must be cancelled after rollback")

local falseAttributeTarget = rollbackTarget:Clone()
falseAttributeTarget:SetAttribute("Level", false)
local falseFailed, falseMessage = apply(failingHistory, recipe, { falseAttributeTarget })
assert(falseFailed == false and falseMessage:find("rolled back") ~= nil)
assert(falseAttributeTarget:GetAttribute("Level") == false, "commit rollback must preserve an existing false attribute")
assert(falseAttributeTarget.Anchored == false and not CollectionService:HasTag(falseAttributeTarget, "PresetForgeApplyTest"))
assert(failingHistory.calls == 4)

targetOne:Destroy()
targetTwo:Destroy()
untouched:Destroy()
rollbackTarget:Destroy()
falseAttributeTarget:Destroy()
return true
