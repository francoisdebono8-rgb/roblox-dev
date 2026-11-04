--!strict
-- Minato's Flying Thunder God kunai (user 04/11: « le kunai de Minato, on l'a
-- pas créé… cherche les références »). The three-pronged kunai: a long
-- central leaf blade, two side prongs that leave the base of the blade
-- outwards and curve forward to a point, a cloth-wrapped grip carrying the
-- seal formula, a ring at the pommel. Bigger than a plain kunai.
--
-- Same contract as Client/Effects FX.buildKunai: a Model built along -Z
-- (point first), the grip centre at the origin, PrimaryPart "Root"
-- (anchored); every other part is welded to it, unanchored and massless.
local K = {}

local STEEL = Color3.fromRGB(88, 94, 106)
local STEEL_EDGE = Color3.fromRGB(190, 198, 212)
local GRIP = Color3.fromRGB(30, 30, 38)
local WRAP = Color3.fromRGB(226, 214, 190)
local PAPER = Color3.fromRGB(240, 232, 206)
local INK = Color3.fromRGB(24, 24, 32)

local function block(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, class: string?): BasePart
	local p = Instance.new(class or "Part") :: BasePart
	p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	if p:IsA("Part") then p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth end
	p.Parent = parent
	return p
end
-- Half a leaf: a wedge whose width runs from `width/2` to nothing over `length`.
local function taper(parent: Instance, center: CFrame, width: number, length: number, thick: number, side: number, tip: number, color: Color3): BasePart
	local rot = CFrame.Angles(0, 0, -side * math.pi / 2)
	if tip > 0 then rot = rot * CFrame.Angles(0, math.pi, 0) end
	return block(parent, Vector3.new(thick, width * .5, length), center * CFrame.new(side * width * .25, 0, 0) * rot, color, Enum.Material.Metal, "WedgePart")
end
-- A flat leaf in the XZ plane at `center`: `front` long towards -Z, `back` towards +Z.
local function leaf(parent: Instance, center: CFrame, width: number, front: number, back: number, thick: number, color: Color3, list: {BasePart})
	for _, side in {-1, 1} do
		table.insert(list, taper(parent, center * CFrame.new(0, 0, -front * .5), width, front, thick, side, -1, color))
		if back > 0 then table.insert(list, taper(parent, center * CFrame.new(0, 0, back * .5), width, back, thick, side, 1, color)) end
	end
end
-- A side prong: three segments bending from outwards to forwards, the last one pointed.
local function prong(parent: Instance, side: number, list: {BasePart})
	local p = Vector3.new(side * .07, 0, -.24)
	local segs = {{70, .14, .085}, {38, .15, .075}, {12, .26, .07}}
	for i, s in segs do
		local a = math.rad(s[1]) * side
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local len = s[2]
		if i < #segs then
			local c = p + dir * len * .5
			table.insert(list, block(parent, Vector3.new(s[3], .045, len + .03), CFrame.lookAt(c, c + dir), STEEL))
		else
			leaf(parent, CFrame.lookAt(p, p + dir) * CFrame.new(0, 0, -len * .5 + .02), s[3] * 1.3, len, .03, .045, STEEL, list)
			table.insert(list, block(parent, Vector3.new(.014, .05, len * .8), CFrame.lookAt(p, p + dir) * CFrame.new(0, 0, -len * .45), STEEL_EDGE))
		end
		p += dir * len
	end
end

function K.build(): Model
	local model = Instance.new("Model")
	model.Name = "HiraishinKunai"
	local root = block(model, Vector3.new(.1, .1, .1), CFrame.new(), Color3.new(), nil)
	root.Name = "Root"; root.Transparency = 1
	local parts: {BasePart} = {}
	local Y90 = CFrame.Angles(0, math.pi / 2, 0)
	-- grip: dark, wrapped in pale cloth bands
	local grip = block(model, Vector3.new(.66, .13, .13), CFrame.new(0, 0, .12) * Y90, GRIP, Enum.Material.Fabric)
	;(grip :: Part).Shape = Enum.PartType.Cylinder; table.insert(parts, grip)
	for i = -2, 2 do
		local band = block(model, Vector3.new(.05, .15, .15), CFrame.new(0, 0, .12 + i * .13) * Y90, WRAP, Enum.Material.Fabric)
		;(band :: Part).Shape = Enum.PartType.Cylinder; table.insert(parts, band)
	end
	-- the seal formula: a paper strip along the grip, inked with three characters
	local tag = block(model, Vector3.new(.09, .02, .5), CFrame.new(0, .078, .12), PAPER, Enum.Material.SmoothPlastic)
	tag.Name = "SealTag"; table.insert(parts, tag)
	for c = 0, 2 do
		local z = -.04 + c * .16
		table.insert(parts, block(model, Vector3.new(.012, .024, .1), CFrame.new(0, .09, z), INK, Enum.Material.SmoothPlastic))
		table.insert(parts, block(model, Vector3.new(.06, .024, .012), CFrame.new(0, .09, z - .03), INK, Enum.Material.SmoothPlastic))
		table.insert(parts, block(model, Vector3.new(.05, .024, .012), CFrame.new(0, .09, z + .025), INK, Enum.Material.SmoothPlastic))
	end
	-- pommel ring, in the plane of the blade
	local R = .13
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local c = CFrame.new(0, 0, .45 + R) * CFrame.Angles(0, a, 0) * CFrame.new(R, 0, 0)
		table.insert(parts, block(model, Vector3.new(.045, .05, R * 2 * math.pi / 10 * 1.2), c, STEEL))
	end
	-- the collar where the blade and the prongs leave the grip
	table.insert(parts, block(model, Vector3.new(.2, .075, .09), CFrame.new(0, 0, -.22), STEEL))
	-- central blade: a long leaf, widest a third of the way up, a bright edge line
	leaf(model, CFrame.new(0, 0, -.52), .3, .82, .24, .05, STEEL, parts)
	table.insert(parts, block(model, Vector3.new(.018, .058, .9), CFrame.new(0, 0, -.74), STEEL_EDGE))
	-- the two prongs
	prong(model, -1, parts); prong(model, 1, parts)
	for _, p in parts do
		p.Anchored = false; p.Massless = true
		local w = Instance.new("WeldConstraint"); w.Name = "Hold"; w.Part0 = root; w.Part1 = p; w.Parent = root
	end
	model.PrimaryPart = root
	return model
end

return K
