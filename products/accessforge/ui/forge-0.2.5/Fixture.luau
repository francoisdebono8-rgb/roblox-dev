local Fixture = {}

local function part(parent, name, position, size, color)
	local p = Instance.new("Part")
	p.Name, p.Position, p.Size, p.Color = name, position, size, color
	p.Anchored = true; p.Material = Enum.Material.Concrete
	p.Parent = parent
	return p
end

function Fixture.create()
	assert(not workspace:FindFirstChild("AccessForge025Fixture"), "Fixture already present")
	local root = Instance.new("Folder"); root.Name = "AccessForge025Fixture"; root.Parent = workspace
	local cases = {}
	for index, mode in ipairs({"Straight", "Switchback", "Catwalk", "Invalid"}) do
		local folder = Instance.new("Folder"); folder.Name = mode; folder.Parent = root
		local origin = Vector3.new((index - 1) * 120, 10, 0)
		local delta = mode == "Switchback" and Vector3.new(9,16,0) or mode == "Catwalk" and Vector3.new(0,0,-28) or mode == "Invalid" and Vector3.new(0,-4,-24) or Vector3.new(0,12,-30)
		local a = part(folder, "Start", origin, Vector3.one * 0.6, Color3.fromRGB(86,191,168))
		local b = part(folder, "End", origin + delta, Vector3.one * 0.6, Color3.fromRGB(180,114,216))
		a.CanCollide, b.CanCollide, a.CanQuery, b.CanQuery = false, false, false, false
		local lower = part(folder, "LowerPlatform", origin + Vector3.new(0,-1,5), Vector3.new(mode == "Switchback" and 7 or 12,2,10), Color3.fromRGB(104,122,131))
		local upper = part(folder, "UpperPlatform", b.Position + Vector3.new(0,-1,mode == "Switchback" and 5 or -5), Vector3.new(mode == "Switchback" and 7 or 12,2,10), Color3.fromRGB(153,164,170))
		local s = {Mode = mode == "Invalid" and "Straight" or mode}
		cases[mode] = {folder=folder,start=a,finish=b,lower=lower,upper=upper,settings=s}
	end
	return root, cases
end

return Fixture
