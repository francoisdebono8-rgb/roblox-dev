return function()
	local storage = game:GetService("ServerStorage")
	local assets = storage.PlantAssets
	local root = Instance.new("Folder"); root.Name = "PlantGreenhouse"; root.Parent = workspace
	local farm = assets.Farm:Clone(); farm.Name = "Greenhouse"; farm.Parent = root
	farm:PivotTo(CFrame.new(0, 15, 0))
	local function part(name, size, cf, color, material)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
		p.Color = color; p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.Parent = root; return p
	end
	part("GardenGround", Vector3.new(180, 1, 180), CFrame.new(0, -1, 0), Color3.fromRGB(98, 137, 112), Enum.Material.Grass)
	part("GreenhousePath", Vector3.new(14, 0.2, 85), CFrame.new(0, -0.4, 10), Color3.fromRGB(192, 196, 181), Enum.Material.Concrete)
	local pots = Instance.new("Folder"); pots.Name = "ProductionPots"; pots.Parent = root
	local names = {"Cabbage_Reference", "Cabbage_02", "Cabbage_03", "Cabbage_04", "Cabbage_05", "Cabbage_06", "Cabbage_07", "Cabbage_08"}
	for i, name in ipairs(names) do
		local x = (i <= 4 and -1 or 1) * 10
		local z = ((i - 1) % 4 - 1.5) * 7
		if i == 1 or i == 5 then
			part("GrowingBench", Vector3.new(8, 0.6, 29), CFrame.new(x, 3, 0), Color3.fromRGB(204, 212, 205), Enum.Material.Metal)
			for _, dz in ipairs({-11, 11}) do part("BenchSupport", Vector3.new(7, 3, 0.8), CFrame.new(x, 1.3, dz), Color3.fromRGB(55, 74, 67), Enum.Material.Metal) end
		end
		local pot = assets.Pot:Clone(); pot.Name = name; pot.Parent = pots
		pot:PivotTo(CFrame.new(x, 5, z))
		local plant = assets.Plant.Stages["Ready for harvest"]:Clone(); plant.Name = "Plant"; plant.Parent = pot.Contents
		local target = pot:FindFirstChild("PlantAttachment", true)
		local origin = plant:FindFirstChild("PlantAttachment", true)
		if target and origin then plant:PivotTo(target.WorldCFrame * origin.WorldCFrame:Inverse() * plant:GetPivot()) else plant:PivotTo(CFrame.new(x, 7, z)) end
		for _, obj in ipairs(pot:GetDescendants()) do
			for key in pairs(obj:GetAttributes()) do if key:sub(1, 5) == "Rojo_" then obj:SetAttribute(key, nil) end end
		end
		for key in pairs(pot:GetAttributes()) do pot:SetAttribute(key, nil) end
		for _, tag in ipairs(pot:GetTags()) do pot:RemoveTag(tag) end
		pot:AddTag("GrowablePot"); pot:SetAttribute("Cost", 25); pot:SetAttribute("Enabled", true); pot:SetAttribute("Variety", "Cabbage")
		if i == 3 or i == 6 then pot:SetAttribute("Cost", nil) end
		if i == 4 then pot:SetAttribute("Cost", -5); pot:SetAttribute("Variety", "Cabage") end
		if i == 7 then pot:SetAttribute("Enabled", "yes") end
		if i == 8 then plant.Name = "UnassignedPlant" end
	end
	for _, obj in ipairs(root:GetDescendants()) do if obj:IsA("BasePart") then obj.Anchored = true end end
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14; lighting.Brightness = 2; lighting.Ambient = Color3.fromRGB(130, 145, 139)
	lighting.OutdoorAmbient = Color3.fromRGB(154, 170, 162)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(45, 38, 58), Vector3.new(0, 7, 0))
	workspace.CurrentCamera.FieldOfView = 48
	local schema = {version=1,name="Greenhouse pots",tag="GrowablePot",className="Model",fields={
		{name="Cost",kind="number",required=true,hasDefault=true,default=25,min=0,max=100,integer=true,choices={},description="Shop price in coins. Whole numbers from 0 to 100."},
		{name="Enabled",kind="boolean",required=true,hasDefault=false,default=true,integer=false,choices={},description="Whether this pot can grow a crop."},
		{name="Variety",kind="string",required=true,hasDefault=false,default="Cabbage",integer=false,choices={"Cabbage","Lettuce"},description="Crop identifier used by the planting system."}
	},children={{path="Contents/Plant",className="Model",description="Each pot needs its planted crop model."}}}
	local Store = require(storage.SchemaForgeCommercial.Modules.Store)
	Store.save(schema, nil, game:GetService("ChangeHistoryService"))
	game:GetService("Selection"):Set({pots.Cabbage_Reference})
	workspace:SetAttribute("SchemaForgeMediaBuild", nil)
	assets:Destroy(); storage.SchemaForgeMediaSetup:Destroy(); storage.SchemaForgeCommercial:Destroy()
	print("[SchemaForgeMedia] Plant scene ready: 8 pots, 6 intentional findings, 2 missing defaults. No executable scripts remain.")
end
