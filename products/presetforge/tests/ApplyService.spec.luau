local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local ApplyService = require(modules.ApplyService)

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

local applied, counts = ApplyService.new(CollectionService, history):apply(recipe, { targetOne, targetTwo })
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

local emptyApplied, emptyError = ApplyService.new(CollectionService, history):apply(recipe, {})
assert(emptyApplied == false and emptyError:find("No affected") ~= nil)
assert(history.beginCount == 1)

local unavailableHistory = {}
function unavailableHistory:TryBeginRecording()
	return nil
end
local untouched = Instance.new("Part")
untouched.Anchored = false
local refused, refusalError = ApplyService.new(CollectionService, unavailableHistory):apply(recipe, { untouched })
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
local failed, failureMessage = ApplyService.new(CollectionService, failingHistory):apply(recipe, { rollbackTarget })
assert(failed == false and failureMessage:find("rolled back") ~= nil)
assert(rollbackTarget.Anchored == false)
assert(not CollectionService:HasTag(rollbackTarget, "PresetForgeApplyTest"))
assert(rollbackTarget:GetAttribute("Level") == nil)
assert(failingHistory.calls == 2, "failed commit must be cancelled after rollback")

targetOne:Destroy()
targetTwo:Destroy()
untouched:Destroy()
rollbackTarget:Destroy()
return true
