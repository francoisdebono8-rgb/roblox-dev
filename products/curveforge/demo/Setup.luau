return function(modules)
	local Engine, Settings = require(modules.Engine), require(modules.Settings)
	local history = game:GetService("ChangeHistoryService")
	assert(not workspace:FindFirstChild("CurveForgeDemo"), "Demo already present.")
	local root = Instance.new("Folder"); root.Name = "CurveForgeDemo"; root.Parent = workspace
	local function part(parent, name, position, size, color)
		local p = Instance.new("Part"); p.Name, p.Position, p.Size = name, position, size; p.Anchored = true; p.Color = color; p.Material = Enum.Material.SmoothPlastic; p.Parent = parent; return p
	end
	part(root, "Ground", Vector3.new(0, -0.5, 0), Vector3.new(125, 1, 85), Color3.fromRGB(101, 119, 127))
	local scenarios = {
		{ name = "01_UtilityCable", color = Color3.fromRGB(40, 46, 52), positions = { Vector3.new(-42, 17, -18), Vector3.new(-32, 12, -18), Vector3.new(-20, 12, -18), Vector3.new(-10, 17, -18) }, diameter = 0.35 },
		{ name = "02_IndustrialPipe", color = Color3.fromRGB(229, 176, 48), positions = { Vector3.new(0, 3, -18), Vector3.new(9, 3, -18), Vector3.new(16, 7, -12), Vector3.new(24, 10, -8), Vector3.new(36, 10, -8) }, diameter = 1.4 },
		{ name = "03_RepeatedFence", color = Color3.fromRGB(64, 163, 150), positions = { Vector3.new(-38, 2, 15), Vector3.new(-18, 2, 8), Vector3.new(4, 2, 16), Vector3.new(35, 2, 13) } },
	}
	for _, scenario in ipairs(scenarios) do
		local folder = Instance.new("Folder"); folder.Name = scenario.name; folder.Parent = root
		local markers = Instance.new("Folder"); markers.Name = "ControlPoints"; markers.Parent = folder
		local controls = {}
		for i, position in ipairs(scenario.positions) do
			local p = part(markers, string.format("Point%02d", i), position, Vector3.one * 0.65, Color3.fromRGB(255, 211, 85)); p.Shape = Enum.PartType.Ball; p.Transparency = 1; p.CanCollide = false; table.insert(controls, p)
		end
		local s = table.clone(Settings.defaults); s.Color = scenario.color; s.Material = "Metal"; s.SegmentLength = 0.65
		local source
		if scenario.diameter then s.Diameter = scenario.diameter else
			s.Mode, s.Distribution, s.Count = "Repeat", "Count", 27
			source = Instance.new("Model"); source.Name = "FencePostSource"; source.Parent = folder
			local p = part(source, "Post", Vector3.new(-48, 2, 23), Vector3.new(0.55, 4, 0.55), scenario.color)
			part(source, "Cap", Vector3.new(-48, 4.1, 23), Vector3.new(0.9, 0.3, 0.9), Color3.fromRGB(227, 231, 235))
			source.PrimaryPart = p
		end
		local output = Engine.apply(Engine.plan(controls, s, source), history); output.Name = scenario.name .. "_CurveForge"; output.Parent = folder
		if scenario.name == "01_UtilityCable" then
			for _, index in ipairs({ 1, 4 }) do
				local p = scenario.positions[index]; part(folder, "UtilityPole", Vector3.new(p.X, 8, p.Z), Vector3.new(0.8, 16, 0.8), Color3.fromRGB(188, 194, 198))
				part(folder, "Crossarm", p, Vector3.new(4, 0.5, 0.7), Color3.fromRGB(77, 99, 110))
			end
		elseif scenario.name == "02_IndustrialPipe" then
			for _, p in ipairs({ scenario.positions[1], scenario.positions[#scenario.positions] }) do part(folder, "MachineHousing", p - Vector3.new(0, 1, 0), Vector3.new(4, 4, 5), Color3.fromRGB(59, 87, 102)) end
		end
	end
	workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(67, 65, 86), Vector3.new(0, 5, 0))
	game:GetService("Selection"):Set({ root["02_IndustrialPipe"]["02_IndustrialPipe_CurveForge"] })
	print("[CurveForgeDemo] Ready: three original primitive-only scenarios")
	return root
end
