-- QA only: original primitive geometry, built through the imported production engine.
return function(modules)
	assert(not workspace:FindFirstChild("CurveForge025Demo"), "Fixture already exists")
	local Engine, Settings = require(modules.Engine), require(modules.Settings)
	local history = game:GetService("ChangeHistoryService")
	local root = Instance.new("Folder"); root.Name = "CurveForge025Demo"; root.Parent = workspace
	local function part(parent, name, position, size, color)
		local p = Instance.new("Part"); p.Name, p.Position, p.Size, p.Color = name, position, size, color
		p.Anchored = true; p.Material = Enum.Material.Metal; p.Parent = parent; return p
	end
	local result = { root = root }
	for index, mode in ipairs({ "Cable", "Repeat" }) do
		local scene = Instance.new("Folder"); scene.Name = mode; scene.Parent = root
		local controls = Instance.new("Folder"); controls.Name = "ControlPoints"; controls.Parent = scene
		local z, points = (index - 1) * 40, {}
		local positions = mode == "Cable" and {
			Vector3.new(-18, 15, z), Vector3.new(-6, 10, z+3), Vector3.new(6, 10, z-3), Vector3.new(18, 15, z),
		} or {
			Vector3.new(-18, 2, z), Vector3.new(-6, 2, z+5), Vector3.new(6, 3, z-4), Vector3.new(18, 4, z),
		}
		for i, position in ipairs(positions) do
			local p = part(controls, string.format("Point%02d",i), position, Vector3.one*0.5, Color3.fromRGB(77,125,210))
			p.Shape, p.Transparency, p.CanCollide = Enum.PartType.Ball, 0.6, false; table.insert(points,p)
		end
		local config=table.clone(Settings.defaults)
		config.Mode,config.Material,config.Color,config.Diameter,config.SegmentLength=mode,"Metal",Color3.fromRGB(210,218,225),0.55,0.8
		local source
		if mode=="Cable" then
			for _,i in ipairs({1,4}) do
				local p=positions[i]
				part(scene,"Pole"..i,Vector3.new(p.X,7.1,p.Z),Vector3.new(1,14.2,1),Color3.fromRGB(104,121,130))
				part(scene,"Crossarm"..i,p-Vector3.new(0,0.6,0),Vector3.new(5,0.7,1.2),Color3.fromRGB(139,150,156))
			end
		else
			source=Instance.new("Model"); source.Name="CustomBeacon"; source.Parent=scene
			local base=part(source,"Stem",Vector3.new(-24,2,z+8),Vector3.new(0.6,4,0.6),Color3.fromRGB(58,87,98))
			part(source,"Housing",Vector3.new(-24,4.3,z+8),Vector3.new(1.4,0.65,1),Color3.fromRGB(218,179,70))
			local lens=part(source,"Lens",Vector3.new(-24,4.3,z+7.45),Vector3.new(1.1,0.4,0.12),Color3.fromRGB(210,230,231))
			lens.Material=Enum.Material.Glass; source.PrimaryPart=base
			config.Distribution,config.Count,config.ControlRoll="Count",14,true
			part(scene,"PlatformA",Vector3.new(-18,-0.5,z),Vector3.new(9,1,9),Color3.fromRGB(119,127,133))
			part(scene,"PlatformB",Vector3.new(18,1.5,z),Vector3.new(9,1,9),Color3.fromRGB(119,127,133))
		end
		history:SetWaypoint("CurveForge 0.2.5 fixture baseline")
		local output=Engine.apply(Engine.plan(points,config,source),history)
		output.Name=mode=="Cable" and "UtilityCable" or "CustomBeaconPath"; output.Parent=scene
		result[mode]={controls=points,settings=config,source=source,output=output,scene=scene}
	end
	return result
end
