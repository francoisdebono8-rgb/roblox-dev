local AttributeCodec = require(script.Parent.AttributeCodec)
local ExecutionPlan = require(script.Parent.ExecutionPlan)
local Schema = require(script.Parent.Schema)
local ValueCodec = require(script.Parent.ValueCodec)

local ApplyService = {}
ApplyService.__index = ApplyService

function ApplyService.new(collectionService, changeHistoryService, writer)
	return setmetatable({ _collectionService = collectionService, _changeHistoryService = changeHistoryService, _writer = writer }, ApplyService)
end

function ApplyService:_write(target, change, value)
	if change.kind == "property" then target[change.name] = value
	elseif change.kind == "attribute" then target:SetAttribute(change.name, value)
	elseif value then self._collectionService:AddTag(target, change.name)
	else self._collectionService:RemoveTag(target, change.name) end
end

function ApplyService:_equals(target, change, value, schemaId)
	if change.kind == "property" then return ValueCodec.equal(Schema.property(schemaId, change.name), target[change.name], value)
	elseif change.kind == "tag" then return self._collectionService:HasTag(target, change.name) == value
	else
		local current = target:GetAttribute(change.name)
		return if value == nil then current == nil else AttributeCodec.equal(current, value)
	end
end

function ApplyService:apply(plan, context)
	if game:GetService("RunService"):IsRunning() then return false, "Apply requires Studio Edit mode" end
	local valid, revalidate = ExecutionPlan.consume(plan, context)
	if not valid then return false, revalidate end
	if #plan.entries == 0 then return false, "No affected compatible targets" end
	local history = self._changeHistoryService
	local started, recording = pcall(history.TryBeginRecording, history, "PresetForgeApply", "Apply PresetForge recipe")
	if not started or not recording then return false, "Could not start an undo recording" end
	local journal, counts = {}, { targets = #plan.entries, properties = 0, tags = 0, attributes = 0 }
	local ok, err = pcall(function()
		local fresh, staleError = revalidate()
		assert(fresh, staleError)
		for _, entry in ipairs(plan.entries) do
			for _, change in ipairs(entry.changes) do
				-- Setters may mutate then throw; journal before invoking them.
				journal[#journal + 1] = { target = entry.instance, change = change }
				if self._writer then self._writer(entry.instance, change, function() self:_write(entry.instance, change, change.after) end)
				else self:_write(entry.instance, change, change.after) end
				assert(self:_equals(entry.instance, change, change.after, plan.schemaId), "Write readback mismatch: " .. change.name)
				local key = ({ property = "properties", tag = "tags", attribute = "attributes" })[change.kind]
				counts[key] += 1
			end
		end
		for _, entry in ipairs(plan.entries) do
			for _, change in ipairs(entry.changes) do assert(self:_equals(entry.instance, change, change.after, plan.schemaId), "Final readback mismatch") end
		end
		for key, count in pairs(plan.counts) do assert(counts[key] == count, "Actual write count differs from Preview") end
		history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		local errors = {}
		for index = #journal, 1, -1 do
			local item = journal[index]
			local restored, restoreError = pcall(function()
				self:_write(item.target, item.change, item.change.before)
				assert(self:_equals(item.target, item.change, item.change.before, plan.schemaId), "Rollback readback mismatch")
			end)
			if not restored then errors[#errors + 1] = tostring(restoreError) end
		end
		local cancelled, cancelError = pcall(history.FinishRecording, history, recording, Enum.FinishRecordingOperation.Cancel)
		if not cancelled then errors[#errors + 1] = tostring(cancelError) end
		return false, "Apply failed; changes rolled back: " .. tostring(err)
			.. (#errors > 0 and (" Rollback/cancel errors: " .. table.concat(errors, "; ")) or "")
	end
	return true, counts
end

return ApplyService
