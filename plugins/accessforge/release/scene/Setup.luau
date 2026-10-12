-- Offline media build only. Never included in the commercial plugin.
local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Color, p.Material = color, material or Enum.Material.Metal
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

return function()
	local storage = game:GetService("ServerStorage")
	local Engine = require(storage.AccessForgeCommercial.Modules.Engine)
	local Settings = require(storage.AccessForgeCommercial.Modules.Settings)
	local BuildRoot = require(storage.BuildRoot)
	local config = require(game.ReplicatedStorage.HackerTycoon.InteriorConfig)
	local history = game:GetService("ChangeHistoryService")
	assert(not workspace:FindFirstChild("AccessForgeDemo"), "Scene already built")
	local root = Instance.new("Folder"); root.Name = "AccessForgeDemo"; root.Parent = workspace
	local steel, amber = Color3.fromRGB(129,143,150), Color3.fromRGB(236,171,55)
	local cameras = {
		{Vector3.new(-39,30,-39), Vector3.new(0,8,6)},
		{Vector3.new(-31,34,-44), Vector3.new(0,10,2)},
		{Vector3.new(-42,31,-43), Vector3.new(0,10,6)},
	}
	local function assembly(scene, name, a, b, overrides)
		local markers = Instance.new("Folder"); markers.Name = name .. "_Controls"; markers.Parent = scene
		local points = {}
		for i, position in ipairs({a,b}) do
			local p = part(markers, i == 1 and "Start" or "End", Vector3.one * 0.6, position, amber)
			p.Shape, p.Transparency, p.CanCollide, p.CastShadow = Enum.PartType.Ball, 1, false, false
			points[i] = p
		end
		local s = table.clone(Settings.defaults)
		for k,v in pairs(overrides) do s[k] = v end
		local model = Engine.apply(Engine.plan(points[1],points[2],s), history)
		model.Name, model.Parent = name, scene
		return model
	end
	for i, title in ipairs({"FactoryStair", "SwitchbackAccess", "CatwalkSystem"}) do
		local scene = Instance.new("Model"); scene.Name = string.format("Scene%02d_%s", i, title); scene.Parent = root
		local offset = Vector3.new((i - 1) * 180, 0, 0)
		local env = BuildRoot.Build(scene); env.Name = "UtilityFacility_MIT"
		local transform = CFrame.new(offset) * config.BuildingBaseCFrame("ROOT"):Inverse()
		for _, p in ipairs(env:GetChildren()) do
			if p.Name == "Roof" or p.Name:match("^Front") or p.Name == "SideWallL" or p.Name == "DoorFrame" or p.Name == "SignAnchor" or p.Name == "CeilingLight" or p.Name:match("^Graffiti") or p.Name:match("^DenZombie") or p.Name == "EdgeTrim" then
				p:Destroy()
			elseif p:IsA("BasePart") then
				p.CFrame = transform * p.CFrame
				if p.Name == "Floor" then p.Color = Color3.fromRGB(79,89,96); p.Material = Enum.Material.Concrete
				elseif p.Name:find("Wall") then p.Color = Color3.fromRGB(165,175,179); p.Material = Enum.Material.Concrete
				elseif p.Material == Enum.Material.Neon then p.Color = Color3.fromRGB(57,148,151); p.Material = Enum.Material.SmoothPlastic end
				p.Locked = true
			end
		end
		for _, p in ipairs(env:GetDescendants()) do
			if p:IsA("Light") or p:IsA("BillboardGui") then p:Destroy()
			elseif p:IsA("TextLabel") then p.Text = "UTILITY CONTROL\nSYSTEM ONLINE\nPRESSURE 100%"; p.TextColor3 = Color3.fromRGB(106,210,204) end
		end
		local function P(name, size, pos, color, material)
			return part(env, name, size, offset + pos, color or steel, material)
		end
		for _, x in ipairs({-36,0,36}) do
			P("BuildingColumn", Vector3.new(1.2,26,1.2), Vector3.new(x,13,38), steel)
		end
		for _, y in ipairs({20,23}) do
			local pipe = P("UtilityConduit", Vector3.new(70,0.7,0.7), Vector3.new(0,y,38), Color3.fromRGB(50,105,113))
			pipe.Shape = Enum.PartType.Cylinder
		end
		local sign = P("MaintenanceSign", Vector3.new(17,3,0.3), Vector3.new(0,23,38.8), Color3.fromRGB(42,48,52))
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.CanvasSize = Vector2.new(680,120); gui.Parent = sign
		local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1,1); text.BackgroundTransparency = 1; text.TextColor3 = amber; text.Font = Enum.Font.SourceSansBold; text.TextSize = 55; text.Text = "MAINTENANCE / " .. string.format("%02d",i); text.Parent = gui
		local primary
		if i == 1 then
			P("UpperLevel", Vector3.new(26,0.8,12), Vector3.new(0,11.6,26), steel, Enum.Material.DiamondPlate)
			for _, x in ipairs({-11,11}) do P("MezzanineColumn",Vector3.new(1,12,1),Vector3.new(x,6,29)) end
			primary = assembly(scene,"FactoryStair",offset+Vector3.new(0,0,-16),offset+Vector3.new(0,12,14),{Landing=true,LandingDepth=6,Width=7})
		elseif i == 2 then
			P("UpperLevel",Vector3.new(20,0.8,12),Vector3.new(8,19.6,-19),steel,Enum.Material.DiamondPlate)
			for _, x in ipairs({0,16}) do P("MezzanineColumn",Vector3.new(1,20,1),Vector3.new(x,10,-22)) end
			primary = assembly(scene,"SwitchbackAccess",offset+Vector3.new(-5,0,-13),offset+Vector3.new(4,20,-13),{Mode="Switchback",Width=6,LandingDepth=7,Supports=true,ReturnSide="Left"})
		else
			P("ServiceLevel",Vector3.new(12,0.8,12),Vector3.new(-25,13.6,10),steel,Enum.Material.DiamondPlate)
			P("ServiceLevel",Vector3.new(12,0.8,12),Vector3.new(25,13.6,10),steel,Enum.Material.DiamondPlate)
			assembly(scene,"AccessStair",offset+Vector3.new(-25,0,-24),offset+Vector3.new(-25,14,4),{Width=6})
			primary = assembly(scene,"CatwalkSystem",offset+Vector3.new(-19,14,10),offset+Vector3.new(19,14,10),{Mode="Catwalk",Width=7,Supports=true,SupportSpacing=10,FloorHeight=0})
		end
		scene:SetAttribute("CameraCFrame",CFrame.lookAt(offset+cameras[i][1],offset+cameras[i][2]))
		scene:SetAttribute("CameraFocus",CFrame.new(offset+cameras[i][2]))
		local reference = Instance.new("ObjectValue"); reference.Name = "FeaturedAssembly"; reference.Value = primary; reference.Parent = scene
	end
	local lighting = game:GetService("Lighting")
	lighting.Brightness, lighting.ClockTime = 2.5, 14
	lighting.Ambient = Color3.fromRGB(145,148,155)
	lighting.OutdoorAmbient = Color3.fromRGB(150,157,166)
	lighting.GlobalShadows = true
	workspace.CurrentCamera.FieldOfView = 55
	workspace.CurrentCamera.CFrame = root.Scene01_FactoryStair:GetAttribute("CameraCFrame")
	workspace.CurrentCamera.Focus = root.Scene01_FactoryStair:GetAttribute("CameraFocus")
	game:GetService("Selection"):Set({root.Scene01_FactoryStair.FeaturedAssembly.Value})
	workspace:SetAttribute("AccessForgeMediaBuild",nil)
	workspace:SetAttribute("AccessForgeQA",nil)
	print("[AccessForgeMedia] PASS: 3 licensed native scenes built")
end
