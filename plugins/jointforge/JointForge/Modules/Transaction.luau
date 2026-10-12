local Planner = require(script.Parent.Planner)
local Schema = require(script.Parent.Schema)
local Graph = require(script.Parent.Graph)
local Transaction = {}

function Transaction.apply(plan, history, confirmed)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before editing joints.")
	Planner.check(plan)
	assert(plan.request.kind ~= "remove" or confirmed == true, "Removal requires explicit confirmation.")
	Planner.consume(plan)
	local created, journal, result, recording, mutated = {}, {}, {}, nil, false
	local function write(item, field, value)
		-- A native setter may mutate and then throw. Journal first, including Parent.
		table.insert(journal, { item = item, field = field, old = item[field] })
		mutated = true
		item[field] = value
		assert(Schema.accepted(item[field], value), "Native write readback mismatch: " .. field)
	end
	local function make(class, name)
		local item = Instance.new(class); table.insert(created, item)
		write(item, "Name", name)
		return item
	end
	local function attachments(op)
		local resultAttachments = {}
		for _, spec in ipairs(op.attachments) do
			local item = spec.existing
			if not item then
				item = make("Attachment", spec.name)
				write(item, "CFrame", spec.localFrame); write(item, "Parent", spec.part)
			end
			assert(Schema.accepted(item.WorldCFrame, spec.world), "Attachment world CFrame changed.")
			table.insert(resultAttachments, item)
		end
		return resultAttachments
	end
	local function fields(joint, values, order)
		for _, field in ipairs(order or Schema.fields[joint.ClassName]) do
			if joint[field] ~= values[field] then write(joint, field, values[field]) end
		end
		for _, field in ipairs(Schema.fields[joint.ClassName]) do
			assert(Schema.accepted(joint[field], values[field]), "Final field readback mismatch: " .. field)
		end
	end
	local ok, err = pcall(function()
		recording = history:TryBeginRecording("JointForge", "JointForge " .. plan.request.kind)
		assert(recording, "Studio cannot start an Undo recording.")
		Planner.check(plan, true)
		for _, op in ipairs(plan.operations) do
			if op.kind == "create" then
				local joint = make(op.class, op.name)
				fields(joint, op.values)
				if op.attachments then
					local endpoints = attachments(op)
					write(joint, "Attachment0", endpoints[1]); write(joint, "Attachment1", endpoints[2])
				else write(joint, "Part0", op.a); write(joint, "Part1", op.b) end
				write(joint, "Parent", op.parent)
				table.insert(result, joint)
			elseif op.kind == "edit" then
				fields(op.joint, op.values, op.order)
				table.insert(result, op.joint)
			elseif op.kind == "reassign" then
				local joint = op.joint
				write(joint, "Enabled", false)
				if op.attachments then
					local endpoints = attachments(op)
					write(joint, "Attachment0", endpoints[1]); write(joint, "Attachment1", endpoints[2])
				else
					write(joint, "Part0", nil); write(joint, "Part1", nil)
					if joint:IsA("Weld") or joint:IsA("Motor6D") then
						write(joint, "C0", op.values.C0); write(joint, "C1", op.values.C1)
					end
					write(joint, "Part0", op.a); write(joint, "Part1", op.b)
				end
				write(joint, "Enabled", op.values.Enabled)
				fields(joint, op.values, op.order)
				table.insert(result, joint)
			elseif op.kind == "remove" then
				-- Keep this exact instance alive for native Undo/Redo.
				write(op.joint, "Parent", nil)
			end
		end
		local preservePose = true
		for operationIndex, op in ipairs(plan.operations) do
			if op.kind == "edit" and (op.changes.C0 or op.changes.C1) or op.kind == "reassign" and not op.preservePose then preservePose = false end
			if op.kind == "create" or op.kind == "reassign" then
				local joint = if op.kind == "create" then result[operationIndex] else op.joint
				local a, b = Graph.endpoints(joint)
				assert(a == op.a and b == op.b, "Final endpoint readback mismatch.")
			end
		end
		if preservePose then
			for item, before in pairs(plan.snapshot) do
				if item:IsA("BasePart") then assert(item.CFrame:FuzzyEq(before.cf, 1e-5), "World pose changed unexpectedly.") end
			end
		end
		history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end)
	Planner.finish(plan)
	if not ok then
		local rollbackErrors = {}
		local function restore(fn)
			local restored, message = pcall(fn)
			if not restored then table.insert(rollbackErrors, tostring(message)) end
		end
		for i = #journal, 1, -1 do
			local entry = journal[i]
			restore(function()
				entry.item[entry.field] = entry.old
				assert(Schema.accepted(entry.item[entry.field], entry.old), "Rollback field readback mismatch.")
			end)
		end
		for i = #created, 1, -1 do restore(function() created[i]:Destroy() end) end
		if mutated then
			local parts = {}
			for item, before in pairs(plan.snapshot) do if item:IsA("BasePart") and item.Parent and item.CFrame ~= before.cf then table.insert(parts, item) end end
			table.sort(parts, function(a, b) return Graph.id(a) < Graph.id(b) end)
			for _, item in ipairs(parts) do restore(function() item.CFrame = plan.snapshot[item].cf end) end
			for _, item in ipairs(parts) do restore(function() assert(item.CFrame:FuzzyEq(plan.snapshot[item].cf, 1e-5), "Rollback pose mismatch.") end) end
		end
		if recording then restore(function() history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end) end
		error(tostring(err) .. (#rollbackErrors > 0 and ("; rollback failed: " .. table.concat(rollbackErrors, "; ")) or " (no changes retained)"), 0)
	end
	return result
end

return Transaction
