local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local ApplyService = require(modules.ApplyService)

local history = {
	beginCount = 0,
	finishCount = 0,
	operation = nil,
}
function history:TryBeginRecording(name, displayName)
	assert(name == "PresetForgeApply")
	assert(displayName == "Apply PresetForge preset")
	self.beginCount += 1
	return "test-recording"
end
function history:FinishRecording(recording, operation)
	assert(recording == "test-recording")
	self.finishCount += 1
	self.operation = operation
end

local preset = {
	name = "Gameplay",
	capture = { properties = true, tags = true, attributes = true },
	properties = {
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 0.25,
		CastShadow = false,
		Massless = true,
	},
	tags = { "PresetTag" },
	attributes = {
		Health = 100,
		Enabled = false,
	},
}

local targetOne = Instance.new("Part")
targetOne.Color = Color3.fromRGB(12, 34, 56)
targetOne.Material = Enum.Material.Wood
targetOne:SetAttribute("Health", 10)
targetOne:SetAttribute("OutsidePreset", "keep")
CollectionService:AddTag(targetOne, "KeepTag")
local targetTwo = targetOne:Clone()

local service = ApplyService.new(CollectionService, history)
local applied, counts = service:apply(preset, { targetOne, targetTwo })
assert(applied == true, tostring(counts))
assert(history.beginCount == 1 and history.finishCount == 1)
assert(history.operation == Enum.FinishRecordingOperation.Commit, "the complete apply must be one committed recording")
assert(counts.properties == 14 and counts.tags == 2 and counts.attributes == 4)

for _, target in ipairs({ targetOne, targetTwo }) do
	assert(target.Anchored == true)
	assert(target.CanCollide == false)
	assert(target.CanTouch == false)
	assert(target.CanQuery == false)
	assert(target.Transparency == 0.25)
	assert(target.CastShadow == false)
	assert(target.Massless == true)
	assert(target.Color == Color3.fromRGB(12, 34, 56), "non-whitelisted Color must remain unchanged")
	assert(target.Material == Enum.Material.Wood, "non-whitelisted Material must remain unchanged")
	assert(CollectionService:HasTag(target, "PresetTag"))
	assert(CollectionService:HasTag(target, "KeepTag"), "existing tags must be preserved")
	assert(target:GetAttribute("Health") == 100)
	assert(target:GetAttribute("Enabled") == false)
	assert(target:GetAttribute("OutsidePreset") == "keep", "attributes outside the preset must be preserved")
end

local emptyApplied, emptyError = service:apply(preset, {})
assert(emptyApplied == false and emptyError:find("No compatible") ~= nil)
assert(history.beginCount == 1, "no-target apply must not begin a recording")

local unavailableHistory = {}
function unavailableHistory:TryBeginRecording()
	return nil
end
local untouched = Instance.new("Part")
untouched.Anchored = false
local refused, refusalError = ApplyService.new(CollectionService, unavailableHistory):apply(preset, { untouched })
assert(refused == false and refusalError:find("undo recording") ~= nil)
assert(untouched.Anchored == false, "apply must not start when Undo recording is unavailable")

local failedState = {
	Anchored = false,
	CanCollide = true,
	CanTouch = true,
	CanQuery = true,
	Transparency = 0,
	CastShadow = true,
	Massless = false,
}
local failingTarget = setmetatable({}, {
	__index = function(_, key)
		if failedState[key] ~= nil then
			return failedState[key]
		elseif key == "GetAttributes" then
			return function()
				return {}
			end
		elseif key == "GetFullName" then
			return function()
				return "FailingTarget"
			end
		end
		return nil
	end,
	__newindex = function(_, key, value)
		if key == "CanCollide" and value == false then
			error("injected write failure")
		end
		failedState[key] = value
	end,
})
local failureHistory = { operation = nil }
function failureHistory:TryBeginRecording()
	return "failure-recording"
end
function failureHistory:FinishRecording(_, operation)
	self.operation = operation
end
local propertiesOnly = {
	name = "Failure test",
	capture = { properties = true, tags = false, attributes = false },
	properties = preset.properties,
	tags = {},
	attributes = {},
}
local failed, failureMessage = ApplyService.new(CollectionService, failureHistory):apply(propertiesOnly, { failingTarget })
assert(failed == false and failureMessage:find("rolled back") ~= nil)
assert(failedState.Anchored == false and failedState.CanCollide == true, "a failed apply must restore earlier writes")
assert(failureHistory.operation == Enum.FinishRecordingOperation.Cancel)

targetOne:Destroy()
targetTwo:Destroy()
untouched:Destroy()

return true
