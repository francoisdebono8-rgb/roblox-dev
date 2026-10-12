-- Read-only presentation of Graph findings and Planner's existing conflict policy.
local Graph = require(script.Parent.Graph)
local Planner = require(script.Parent.Planner)
local Schema = require(script.Parent.Schema)
local Inspection = {}
Inspection.maxConnections = 128

Inspection.labels = table.freeze({
	["broken-endpoint"] = "Broken endpoint", ["same-endpoint"] = "Same endpoint",
	["direct-duplicate"] = "Direct duplicate", ["indirect-path"] = "Indirect physical path",
	["attachment-ancestry"] = "Invalid attachment ancestry", ["anchored-both"] = "Both anchored",
	["hinge-axis"] = "Hinge axes differ", ["separated-pivot"] = "Separated pivots",
	["inspect-only"] = "Inspect only",
})

function Inspection.scan(world, scope, progress)
	assert(#scope > 0, "Select an assembly, parts or joints to scan.")
	assert(#scope <= Inspection.maxConnections,"Select at most 128 scope objects; no partial result.")
	for _, item in ipairs(scope) do
		assert(typeof(item) == "Instance" and (item == world or item:IsDescendantOf(world)), "Scan selection must remain inside Workspace.")
	end
	local rows = Graph.inspect(world, scope)
	assert(#rows <= Inspection.maxConnections, "Scan limit: 128 connections. Select a smaller assembly; no partial result.")
	local seeds, selected = {}, {}
	for _, info in ipairs(rows) do
		selected[info.joint] = true
		for _, key in ipairs({"a","b","endpoint0","endpoint1"}) do
			if info[key] then table.insert(seeds,info[key]) end
		end
	end
	local fingerprint = Graph.fingerprint(Graph.build(world),seeds,selected,{})
	local result = { rows = rows, byJoint = {}, groups = {}, jointCount = #rows, issueCount = 0, affectedCount = 0 }
	for i, info in ipairs(rows) do
		if progress then progress(i,#rows) end
		local seen = {}
		for _, diagnostic in ipairs(info.diagnostics) do seen[diagnostic.code] = true end
		-- Reassign the same explicit endpoint in a disposable Preview. The Planner
		-- excludes this joint, so its own edge cannot become a false duplicate/path.
		if Schema.supported(info.joint) and not info.broken then
			local plan = Planner.preview(world, { kind = "reassign", joint = info.joint, endpoint0 = info.endpoint0, poseMode = "raw" })
			for _, diagnostic in ipairs(plan.diagnostics) do
				if (diagnostic.code == "direct-duplicate" or diagnostic.code == "indirect-path") and not seen[diagnostic.code] then
					table.insert(info.diagnostics, { code = diagnostic.code, message = diagnostic.message,
						joint = info.joint, counterpart = diagnostic.joint })
					seen[diagnostic.code] = true
				end
			end
			-- A bounded graph failure must not appear as a clean scan.
			for _, diagnostic in ipairs(plan.diagnostics) do
				assert(diagnostic.code ~= "invalid-request", diagnostic.message)
			end
			Planner.invalidate(plan)
		end
		info.issueCount = #info.diagnostics
		result.byJoint[info.joint] = info
		result.issueCount += info.issueCount
		if info.issueCount > 0 then result.affectedCount += 1 end
		for _, diagnostic in ipairs(info.diagnostics) do
			result.groups[diagnostic.code] = (result.groups[diagnostic.code] or 0) + 1
		end
	end
	assert(Graph.equal(fingerprint,Graph.fingerprint(Graph.build(world),seeds,selected,{})), "Assembly changed during Scan. Rescan; no complete result.")
	local ending = Graph.inspect(world,scope)
	assert(#ending == #rows,"Scan scope changed. Rescan; no complete result.")
	for i,info in ipairs(ending) do assert(info.joint==rows[i].joint,"Scan scope changed. Rescan; no complete result.") end
	return result
end

return Inspection
