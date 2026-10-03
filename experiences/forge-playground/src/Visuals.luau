local World = require(script.Parent.World)
local Visuals = {}
function Visuals.folder(parent, name, class)
	local f = Instance.new(class or "Folder"); f.Name, f.Parent = name, parent; return f
end
function Visuals.part(station, parent, name, size, position, color, material)
	return World.part(parent, name, size, CFrame.new(station.center + position), color, material)
end
function Visuals.pick(part, stationId, index)
	part:SetAttribute("Station", stationId); part:SetAttribute("PickIndex", index)
end
function Visuals.clear(station, name)
	local existing = station.model:FindFirstChild(name)
	if existing then existing:Destroy() end
end
function Visuals.ghost(station, model)
	Visuals.clear(station, "Preview")
	model.Name = "Preview"
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Transparency, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = 0.65, false, false, false, false
			p.Color, p.Material = Color3.fromRGB(97, 224, 211), Enum.Material.ForceField
		end
	end
	model.Parent = station.model
end
function Visuals.parts(specs)
	local model = Instance.new("Model")
	for _, spec in ipairs(specs) do
		local p = World.part(model, spec.name, spec.size, spec.cf, spec.color, Enum.Material[spec.material])
		if spec.round then p.Shape = Enum.PartType.Cylinder end
	end
	return model
end
function Visuals.commit(station, model)
	model.Name = "Generated"
	local old = station.contents:FindFirstChild("Generated")
	model.Parent = station.contents
	if old then old:Destroy() end
	Visuals.clear(station, "Preview")
end
function Visuals.message(err)
	return tostring(err):gsub("^.-:%d+: ", "")
end
function Visuals.format(value)
	if typeof(value) == "Color3" then return string.format("RGB %d, %d, %d", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255)) end
	if typeof(value) == "number" then return string.format("%.2f", value) end
	return tostring(value)
end
return Visuals
