local Planner = require(script.Parent.Planner)
local Schema = require(script.Parent.Schema)
local Transaction = {}

local function unique(parent, name)
	local candidate, i = name, 1
	while parent:FindFirstChild(candidate) do i += 1; candidate = name .. "_" .. i end
	return candidate
end

function Transaction.apply(plan, history, confirmed)
	assert(not game:GetService("RunService"):IsRunning(), "Stop the simulation before editing joints.")
	Planner.check(plan)
	assert(plan.request.kind ~= "remove" or confirmed == true, "Removal requires explicit confirmation.")
	local recording = history:TryBeginRecording("JointForge", "JointForge " .. plan.request.kind)
	assert(recording, "Studio cannot start an Undo recording. Finish the other operation and retry.")
	local created, rollback, result = {}, {}, {}
	local function make(class, parent, name)
		local item = Instance.new(class)
		table.insert(created, item)
		item.Name = unique(parent, name)
		return item
	end
	local ok, err = pcall(function()
		for _, op in ipairs(plan.operations) do
			if op.kind == "create" then
				local joint = make(op.class, op.a, "JF_" .. op.class .. "_" .. op.b.Name)
				if Schema.usesAttachments(op.class) then
					local function attachment(existing, part, cf, suffix)
						if existing then return existing end
						local item = make("Attachment", part, "JF_Attachment" .. suffix)
						item.CFrame = part.CFrame:ToObjectSpace(cf)
						item.Parent = part
						return item
					end
					joint.Attachment0 = attachment(op.attachment0, op.a, op.world0, "0")
					joint.Attachment1 = attachment(op.attachment1, op.b, op.world1, "1")
					if op.class == "RopeConstraint" or op.class == "RodConstraint" then joint.Length = op.length end
					if op.class == "SpringConstraint" then joint.FreeLength = op.length end
					joint.Visible = true
				else
					if op.class == "Weld" or op.class == "Motor6D" then
						joint.C0 = op.a.CFrame:ToObjectSpace(op.b.CFrame)
						joint.C1 = CFrame.identity
					end
					joint.Part0, joint.Part1 = op.a, op.b
				end
				joint.Parent = op.a
				table.insert(result, joint)
			elseif op.kind == "edit" then
				for field, value in pairs(op.changes) do
					local old = op.joint[field]
					table.insert(rollback, function() op.joint[field] = old end)
					op.joint[field] = value
				end
				table.insert(result, op.joint)
			else
				local oldParent = op.joint.Parent
				table.insert(rollback, function() op.joint.Parent = oldParent end)
				-- Detach instead of Destroy so history and rollback retain the exact instance.
				op.joint.Parent = nil
			end
		end
		history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		local rollbackErrors = {}
		for i = #rollback, 1, -1 do
			local restored, message = pcall(rollback[i])
			if not restored then table.insert(rollbackErrors, tostring(message)) end
		end
		for i = #created, 1, -1 do created[i]:Destroy() end
		-- Offset edits can move connected parts immediately, even outside simulation.
		for item, state in pairs(plan.snapshot) do
			if item:IsA("BasePart") and item.Parent and state.cf and item.CFrame ~= state.cf then
				local restored, message = pcall(function() item.CFrame = state.cf end)
				if not restored then table.insert(rollbackErrors, tostring(message)) end
			end
		end
		local closed, closeError = pcall(function() history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end)
		if not closed then table.insert(rollbackErrors, tostring(closeError)) end
		error(tostring(err) .. (#rollbackErrors > 0 and ("; rollback: " .. table.concat(rollbackErrors, "; ")) or " (changes rolled back)"))
	end
	plan.used = true
	return result
end

return Transaction
