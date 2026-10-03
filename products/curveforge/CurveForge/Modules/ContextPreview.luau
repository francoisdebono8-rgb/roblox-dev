-- Detached render copies only. Never reparent originals or record project history.
local Engine = require(script.Parent.Engine)
local Preview = {}
Preview.limits = { contextParts = 32, queryParts = 64, partDescendants = 32, existingInstances = 5000 }

local function group(parent, name)
	local model = Instance.new("Model"); model.Name = name; model.Parent = parent; return model
end

local function visualCopy(part)
	if not part.Archivable or #part:GetDescendants() > Preview.limits.partDescendants then return nil end
	local copy = part:Clone()
	if not copy then return nil end
	-- Keep real mesh/texture appearance, discard scripts, constraints and references.
	for _, child in ipairs(copy:GetChildren()) do
		if child:IsA("DataModelMesh") or child:IsA("SurfaceAppearance") or child:IsA("Decal") then
			child:ClearAllChildren()
		else child:Destroy() end
	end
	for _, tag in ipairs(copy:GetTags()) do copy:RemoveTag(tag) end
	copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery = true, false, false, false
	return copy
end

function Preview.create(plan, target, queryWorld)
	Engine.check(plan)
	local scene = Instance.new("Model"); scene.Name = "ContextualPreview"
	local result = { model = scene, sources = {}, contextCount = 0, skipped = 0, limited = false, existingAvailable = false }
	local ok, err = pcall(function()
		result.proposed = Engine.output(plan); result.proposed.Name = "Proposed"; result.proposed.Parent = scene
		result.context = group(scene, "Context")
		result.existing = group(scene, "Existing")
		local minimum, maximum = plan.positions[1], plan.positions[1]
		for _, position in ipairs(plan.path.positions) do minimum = minimum:Min(position); maximum = maximum:Max(position) end
		local extent = maximum - minimum
		local exclusions = table.clone(plan.controls)
		if target then table.insert(exclusions, target) end
		if plan.source then table.insert(exclusions, plan.source) end
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, exclusions
		params.MaxParts = Preview.limits.queryParts
		local queryOK, nearby = pcall(function()
			return (queryWorld or workspace):GetPartBoundsInBox(CFrame.new((minimum + maximum) / 2), extent + Vector3.one * 16, params)
		end)
		result.queryAvailable = queryOK
		nearby = queryOK and nearby or {}
		result.limited = #nearby == Preview.limits.queryParts
		local center = (minimum + maximum) / 2
		table.sort(nearby, function(a, b) return (a.Position - center).Magnitude < (b.Position - center).Magnitude end)
		local function contextPart(part, control)
			-- Oversized floors would hide the output by dominating the camera fit.
			if not control and (part.Transparency >= 1 or part.Size.Magnitude > math.max(32, extent.Magnitude * 1.5)) then return end
			local copy = visualCopy(part)
			if copy then
				copy.Parent = result.context; table.insert(result.sources, part)
				if not control then result.contextCount += 1 end
			else result.skipped += 1 end
		end
		for _, part in ipairs(plan.controls) do contextPart(part, true) end
		for _, part in ipairs(nearby) do
			if result.contextCount >= Preview.limits.contextParts then result.limited = true; break end
			contextPart(part, false)
		end
		local output = target and target:IsDescendantOf(workspace) and target:FindFirstChild("Output")
		if output and output:IsA("Model") then
			local items = output:GetDescendants()
			local complete, count = #items <= Preview.limits.existingInstances, 0
			if complete then
				for _, item in ipairs(items) do
					if item:IsA("BasePart") then
						local copy = visualCopy(item)
						if not copy then complete = false; break end
						copy.Parent = result.existing; count += 1
					end
				end
			end
			result.existingAvailable = complete and count > 0
			if not result.existingAvailable then result.existing:ClearAllChildren() end
		end
		-- Generated Repeat may carry live tags/references; the viewport needs geometry only.
		for _, item in ipairs(scene:GetDescendants()) do
			for _, tag in ipairs(item:GetTags()) do item:RemoveTag(tag) end
			if item:IsA("LuaSourceContainer") or item:IsA("ObjectValue") or item:IsA("Constraint") or item:IsA("JointInstance") or item:IsA("WeldConstraint") then item:Destroy() end
		end
		result.boundsCFrame, result.boundsSize = scene:GetBoundingBox()
		result.appearance = {}
		for _, item in ipairs(scene:GetDescendants()) do
			if item:IsA("BasePart") then
				item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
			end
			if item:IsA("BasePart") or item:IsA("Decal") then result.appearance[item] = item.Transparency end
		end
	end)
	if not ok then scene:Destroy(); error(err, 0) end
	return result
end

function Preview.show(result, mode)
	assert(mode == "Proposed" or (mode == "Existing" and result.existingAvailable), "Existing output unavailable")
	for item, transparency in pairs(result.appearance) do
		local hidden = (mode == "Existing" and item:IsDescendantOf(result.proposed))
			or (mode == "Proposed" and item:IsDescendantOf(result.existing))
		item.Transparency = hidden and 1 or transparency
	end
end

return Preview
