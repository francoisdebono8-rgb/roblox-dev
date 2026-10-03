local Modules = script.Parent.Parent.ProductModules.Preset
local ExecutionPlan = require(Modules.ExecutionPlan)
local ValueCodec = require(Modules.ValueCodec)
local Adapter = {}

-- This consumes the real issued plan; it never calls or bypasses ApplyService.
function Adapter.apply(root, plan, context)
	local valid, reason = ExecutionPlan.validate(plan, context)
	assert(valid, reason)
	assert(#plan.entries > 0, "No affected targets.")
	for _, entry in ipairs(plan.entries) do assert(entry.instance:IsDescendantOf(root), "Outside the demo fixture.") end
	local consumed, current = ExecutionPlan.consume(plan, context)
	assert(consumed, current)
	local fresh, freshError = current(); assert(fresh, freshError)
	local changed = {}
	local ok, err = pcall(function()
		for _, entry in ipairs(plan.entries) do
			for _, change in ipairs(entry.changes) do
				local target = entry.instance
				assert(target:IsDescendantOf(root), "Target left the demo fixture.")
				table.insert(changed, { target = target, change = change })
				if change.kind == "property" then
					target[change.name] = change.after
					assert(ValueCodec.equalAny(target[change.name], change.after), "Property readback failed.")
				elseif change.kind == "attribute" then target:SetAttribute(change.name, change.after)
				elseif change.kind == "tag" then target:AddTag(change.name)
				else error("Unsupported plan write.") end
			end
		end
	end)
	if not ok then
		for i = #changed, 1, -1 do
			local target, change = changed[i].target, changed[i].change
			if change.kind == "property" then target[change.name] = change.before
			elseif change.kind == "attribute" then target:SetAttribute(change.name, change.before)
			elseif not change.before then target:RemoveTag(change.name) end
		end
		error(err)
	end
	return plan.counts
end
return Adapter
