local Catalog = require(game:GetService("ReplicatedStorage").ForgePlayground.Catalog)
local World = {}
local DARK = Color3.fromRGB(36, 38, 41)
local centers = {
	preset = Vector3.new(-59, 0, 8), schema = Vector3.new(-59, 0, -45),
	curve = Vector3.new(0, 0, -60), access = Vector3.new(59, 0, -45), joint = Vector3.new(59, 0, 8),
}

function World.part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color or DARK, material or Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function World.sign(parent, text, position, width, color)
	local p = World.part(parent, "Sign", Vector3.new(width, 2.3, 0.25), CFrame.new(position), DARK)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.LightInfluence = Enum.NormalId.Back, Vector2.new(width * 50, 115), 0
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.TextSize = text, color or Color3.new(1, 1, 1), 44
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return p
end

function World.create(parent, slot)
	local origin = Vector3.new(((slot - 1) % 3) * 230, 0, math.floor((slot - 1) / 3) * 190)
	local model = Instance.new("Model")
	model.Name = "Workshop_" .. slot
	model.Parent = parent
	World.part(model, "Floor", Vector3.new(192, 1, 148), CFrame.new(origin + Vector3.new(0, -0.5, -17)), Color3.fromRGB(66, 69, 72), Enum.Material.Concrete)
	World.part(model, "BackWall", Vector3.new(192, 18, 1), CFrame.new(origin + Vector3.new(0, 8, -91)), DARK)
	World.sign(model, "FORGE / PLAYGROUND", origin + Vector3.new(0, 12, -90.3), 43, Color3.fromRGB(62, 220, 205))
	for _, x in ipairs({ -95, 95 }) do
		World.part(model, "SideWall", Vector3.new(1, 4, 148), CFrame.new(origin + Vector3.new(x, 1.5, -17)), DARK)
	end
	World.part(model, "FrontWall", Vector3.new(192, 4, 1), CFrame.new(origin + Vector3.new(0, 1.5, 57)), DARK)
	for x = -84, 84, 12 do
		World.part(model, "FloorJoint", Vector3.new(0.04, 0.02, 140), CFrame.new(origin + Vector3.new(x, 0.015, -17)), Color3.fromRGB(91, 94, 96))
	end
	local stations = {}
	for index, id in ipairs(Catalog.order) do
		local center = origin + centers[id]
		local station = Instance.new("Model")
		station.Name, station.Parent = id, model
		World.part(station, "Stage", Vector3.new(44, 0.3, 42), CFrame.new(center), Color3.fromRGB(47, 49, 53))
		World.part(station, "Accent", Vector3.new(44, 0.07, 0.2), CFrame.new(center + Vector3.new(0, 0.2, 20.5)), Catalog.stations[id].accent, Enum.Material.Neon)
		World.sign(station, string.format("%02d / %s", index, Catalog.stations[id].title), center + Vector3.new(0, 13, -20), 27, Catalog.stations[id].accent)
		local contents = Instance.new("Model")
		contents.Name, contents.Parent = "Contents", station
		stations[id] = { center = center, model = station, contents = contents }
	end
	return { model = model, stations = stations, origin = origin, spawn = CFrame.new(origin + Vector3.new(0, 4, 32)) }
end

return World
