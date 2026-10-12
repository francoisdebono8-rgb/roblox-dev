-- Detached primitive geometry only. Unsupported context is counted and omitted;
-- project content is never cloned recursively or used as input to the solver.
local Engine = require(script.Parent.Engine)
local Preview = {}
Preview.MAX_CONTEXT = 32
Preview.QUERY_LIMIT = 48
Preview.RADIUS = 18
Preview.MAX_CONTEXT_SIZE = 64

local function model(name, parent)
	local item = Instance.new("Model"); item.Name = name; item.Parent = parent
	return item
end

local function supportedPrimitive(source)
	local class = source.ClassName
	return (class == "Part" or class == "WedgePart" or class == "CornerWedgePart")
		and not source:FindFirstChildWhichIsA("DataModelMesh")
end

local function copyPrimitive(source, parent)
	assert(supportedPrimitive(source), "Unsupported primitive geometry.")
	local part = Instance.new(source.ClassName)
	part.Name, part.Size, part.CFrame = source.Name, source.Size, source.CFrame
	if source:IsA("Part") then part.Shape = source.Shape end
	part.Color, part.Material = source.Color, source.Material
	part.Transparency = source.Transparency
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function snapshot(source)
	return { object = source, parent = source.Parent, cf = source.CFrame, size = source.Size,
		color = source.Color, material = source.Material, transparency = source.Transparency,
		shape = source:IsA("Part") and source.Shape }
end

function Preview.isCurrent(preview)
	for _, s in ipairs(preview.sources) do
		local p = s.object
		if p.Parent ~= s.parent or not p:IsDescendantOf(workspace) or p.CFrame ~= s.cf or p.Size ~= s.size
			or p.Color ~= s.color or p.Material ~= s.material or p.Transparency ~= s.transparency
			or (s.shape and p.Shape ~= s.shape) or not p.Archivable or not supportedPrimitive(p) then return false end
	end
	return true
end

function Preview.capture(plan)
	local scene = model("ContextualAssembly")
	local ok, result = pcall(function()
		local proposed = Engine.output(plan); proposed.Name = "Proposed"; proposed.Parent = scene
		local existing = model("Existing", scene)
		for _, part in ipairs(plan.owned or {}) do copyPrimitive(part, existing) end
		local context = model("Context", scene)
		local sources, seen = {}, {}
		local count, omittedCount, queryLimited, available = 0, 0, false, true
		local omitted = { unsupported = 0, nonArchivable = 0, oversized = 0, invisible = 0, capacity = 0 }
		local function omit(reason)
			omitted[reason] += 1; omittedCount += 1
		end
		local function add(part)
			if seen[part] then return end
			seen[part] = true
			if not supportedPrimitive(part) then omit("unsupported"); return end
			if not part.Archivable then omit("nonArchivable"); return end
			if math.max(part.Size.X, part.Size.Y, part.Size.Z) > Preview.MAX_CONTEXT_SIZE then omit("oversized"); return end
			if part.Transparency >= 0.95 then omit("invisible"); return end
			if count >= Preview.MAX_CONTEXT then omit("capacity"); return end
			local copy = copyPrimitive(part, context)
			copy.Transparency = math.max(copy.Transparency, 0.35)
			count += 1; table.insert(sources, snapshot(part))
		end
		-- Endpoint surfaces are considered even when CanQuery is disabled. The same
		-- primitive/size/Archivable rules apply; markers below still show positions.
		add(plan.start); add(plan.finish)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = plan.target and {plan.start, plan.finish, plan.target} or {plan.start, plan.finish}
		params.MaxParts = Preview.QUERY_LIMIT
		for _, position in ipairs({plan.a, plan.b}) do
			local queried, parts = pcall(function()
				return workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.one * Preview.RADIUS * 2, params)
			end)
			if queried then
				if #parts == Preview.QUERY_LIMIT then queryLimited = true end
				table.sort(parts, function(a, b) return (a.Position - position).Magnitude < (b.Position - position).Magnitude end)
				for _, part in ipairs(parts) do add(part) end
			else available = false end
		end
		local endpoints = model("Endpoints", scene)
		local diameter = math.clamp(plan.settings.Width * 0.15, 0.6, 1.4)
		for index, position in ipairs({plan.a, plan.b}) do
			local point = Instance.new("Part")
			point.Name = index == 1 and "Start" or "End"
			point.Shape, point.Size, point.Position = Enum.PartType.Ball, Vector3.one * diameter, position
			point.Color = index == 1 and Color3.fromRGB(86, 191, 168) or Color3.fromRGB(180, 114, 216)
			point.Material = Enum.Material.Neon
			point.Anchored, point.CanCollide, point.CanTouch, point.CanQuery = true, false, false, false
			point.Parent = endpoints
		end
		local cf, size = scene:GetBoundingBox()
		return { model = scene, cf = cf, size = size, sources = sources, contextCount = count,
			omitted = omitted, omittedCount = omittedCount, queryLimited = queryLimited,
			limited = omittedCount > 0 or queryLimited or not available, available = available,
			existingCount = #(plan.owned or {}), a = plan.a, b = plan.b }
	end)
	if not ok then scene:Destroy(); error(result, 0) end
	return result
end

function Preview.display(preview, comparison)
	assert(comparison == "Proposed" or comparison == "Existing", "Unknown preview comparison.")
	local scene = preview.model:Clone()
	scene[comparison == "Proposed" and "Existing" or "Proposed"]:Destroy()
	return scene
end

return Preview
