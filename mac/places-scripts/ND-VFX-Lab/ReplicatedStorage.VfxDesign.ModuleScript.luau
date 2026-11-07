--!strict
-- VfxDesign : effets visuels de Ninja Duel, refonte du 06/11/2026.
-- (copie de labo, source : games/ninja-duel/src/Client/VfxDesign.luau)

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VfxDesign = {}

local ID: { [string]: number } = {
	star = 98653403631189,
	impact_lines = 95466528530083,
	spark = 79205682571618,
	ring = 126225681093802,
	smoke = 74803998450943,
	dust = 110630590889405,
	fire_burst = 102546534361734,
	flame_loop = 99943034086282,
	lightning = 100625761935181,
	crescent = 138976015806015,
	swirl = 79371527861672,
	debris = 80574510604813,
	leaf = 132068074134721,
	feather = 79191268061599,
	glyph = 139199375333619,
	crack = 73897435788755,
	scorch = 87363885818367,
}
VfxDesign.ID = ID

local SHEET: { [string]: Enum.ParticleFlipbookLayout } = {
	smoke = Enum.ParticleFlipbookLayout.Grid4x4,
	dust = Enum.ParticleFlipbookLayout.Grid4x4,
	fire_burst = Enum.ParticleFlipbookLayout.Grid4x4,
	flame_loop = Enum.ParticleFlipbookLayout.Grid4x4,
	lightning = Enum.ParticleFlipbookLayout.Grid4x4,
	debris = Enum.ParticleFlipbookLayout.Grid2x2,
	leaf = Enum.ParticleFlipbookLayout.Grid2x2,
	feather = Enum.ParticleFlipbookLayout.Grid2x2,
}
local VARIANTS: { [string]: boolean } = { debris = true, leaf = true, feather = true }
local LOOPS: { [string]: boolean } = { flame_loop = true, lightning = true }

VfxDesign.Palette = {
	Neutral = Color3.fromRGB(255, 240, 214),
	Lightning = Color3.fromRGB(150, 205, 255),
	Fire = Color3.fromRGB(255, 124, 44),
	Wind = Color3.fromRGB(176, 255, 226),
	Sand = Color3.fromRGB(218, 184, 116),
	GentleFist = Color3.fromRGB(196, 216, 255),
	Strength = Color3.fromRGB(255, 196, 90),
	Chakra = Color3.fromRGB(110, 172, 255),
	Earth = Color3.fromRGB(138, 112, 84),
}
local WHITE = Color3.new(1, 1, 1)
local SMOKE_LIT = Color3.fromRGB(238, 232, 222)

export type Layer = {
	tex: string,
	count: number,
	delay: number?,
	life: NumberRange,
	size: { number },
	sizeJitter: number?,
	speed: NumberRange?,
	spread: number?,
	orient: string?,
	rot: NumberRange?,
	spin: NumberRange?,
	color: string?,
	fade: string?,
	light: number?,
	z: number?,
	accel: Vector3?,
	drag: number?,
	squash: number?,
	ground: boolean?,
	up: boolean?,
}
export type Mark = { mark: string, size: number, hold: number, fadeTime: number, delay: number? }
export type Recipe = { layers: { Layer }, marks: { Mark }? }

local R: { [string]: Recipe } = {}
VfxDesign.Recipes = R

R.hit_light = {
	layers = {
		{ tex = "star", count = 1, life = NumberRange.new(0.09), size = { 2.2, 2.5, 1.2 }, rot = NumberRange.new(0, 360),
			color = "flash", fade = "cut", light = 0.4, z = 2 },
		{ tex = "spark", count = 4, life = NumberRange.new(0.12, 0.2), size = { 0.9, 0.7, 0 }, speed = NumberRange.new(24, 36),
			spread = 180, orient = "velocity", drag = 8, color = "flash", fade = "late", light = 0.5, z = 1.5, squash = 1 },
		{ tex = "smoke", count = 2, delay = 0.02, life = NumberRange.new(0.32, 0.42), size = { 1.4, 2.4, 2.6 }, sizeJitter = 0.25,
			speed = NumberRange.new(2, 4), spread = 180, rot = NumberRange.new(0, 360), color = "smoke", fade = "linear", z = -0.5, drag = 4 },
	},
}

R.hit_medium = {
	layers = {
		{ tex = "star", count = 1, life = NumberRange.new(0.1), size = { 3.2, 3.6, 1.6 }, rot = NumberRange.new(0, 360),
			color = "flash", fade = "cut", light = 0.4, z = 2 },
		{ tex = "impact_lines", count = 1, delay = 0.016, life = NumberRange.new(0.12), size = { 5, 6.2, 6.8 }, rot = NumberRange.new(0, 360),
			color = "white", fade = "cut", light = 0.3, z = 1.8 },
		{ tex = "ring", count = 1, delay = 0.016, life = NumberRange.new(0.22), size = { 1.2, 4.2, 5.2 }, rot = NumberRange.new(0, 360),
			color = "tint", fade = "late", light = 0.3, z = 1 },
		{ tex = "spark", count = 8, life = NumberRange.new(0.14, 0.26), size = { 1.1, 0.8, 0 }, speed = NumberRange.new(28, 46),
			spread = 180, orient = "velocity", drag = 8, color = "flash", fade = "late", light = 0.5, z = 1.5, squash = 1 },
		{ tex = "smoke", count = 4, delay = 0.025, life = NumberRange.new(0.38, 0.5), size = { 1.8, 3, 3.3 }, sizeJitter = 0.25,
			speed = NumberRange.new(3, 6), spread = 180, rot = NumberRange.new(0, 360), color = "smoke", fade = "linear", z = -0.5, drag = 4 },
	},
}

R.hit_heavy = {
	layers = {
		{ tex = "star", count = 1, life = NumberRange.new(0.12), size = { 4.6, 5.2, 2.2 }, rot = NumberRange.new(0, 360),
			color = "flash", fade = "cut", light = 0.4, z = 2 },
		{ tex = "impact_lines", count = 1, delay = 0.016, life = NumberRange.new(0.15), size = { 7, 8.6, 9.4 }, rot = NumberRange.new(0, 360),
			color = "white", fade = "cut", light = 0.3, z = 1.8 },
		{ tex = "ring", count = 1, delay = 0.016, life = NumberRange.new(0.26), size = { 1.6, 6, 7.4 }, rot = NumberRange.new(0, 360),
			color = "tint", fade = "late", light = 0.3, z = 1 },
		{ tex = "spark", count = 10, life = NumberRange.new(0.16, 0.3), size = { 1.3, 0.9, 0 }, speed = NumberRange.new(34, 56),
			spread = 180, orient = "velocity", drag = 7, color = "flash", fade = "late", light = 0.5, z = 1.5, squash = 1 },
		{ tex = "smoke", count = 6, delay = 0.03, life = NumberRange.new(0.45, 0.62), size = { 2.4, 4, 4.4 }, sizeJitter = 0.25,
			speed = NumberRange.new(4, 8), spread = 180, rot = NumberRange.new(0, 360), color = "smoke", fade = "linear", z = -0.5, drag = 4 },
		{ tex = "ring", count = 1, delay = 0.03, ground = true, life = NumberRange.new(0.32), size = { 2, 9, 11 }, orient = "flat",
			color = "ground", fade = "late", z = 0.2 },
		{ tex = "dust", count = 6, delay = 0.03, ground = true, life = NumberRange.new(0.55, 0.75), size = { 2.4, 4, 4.6 }, sizeJitter = 0.3,
			speed = NumberRange.new(10, 16), spread = 82, up = true, drag = 5, color = "ground", fade = "linear", z = -0.3 },
		{ tex = "debris", count = 6, delay = 0.03, ground = true, life = NumberRange.new(0.6, 0.85), size = { 0.55, 0.55, 0.45 }, sizeJitter = 0.45,
			speed = NumberRange.new(16, 26), spread = 38, up = true, accel = Vector3.new(0, -90, 0), spin = NumberRange.new(-420, 420),
			rot = NumberRange.new(0, 360), color = "ground", fade = "late", z = 0.4 },
	},
	marks = { { mark = "crack", size = 7, hold = 5, fadeTime = 1.2, delay = 0.03 } },
}

R.hit_ko = {
	layers = {
		{ tex = "star", count = 1, life = NumberRange.new(0.16), size = { 6.4, 7.2, 3 }, rot = NumberRange.new(0, 360),
			color = "flash", fade = "cut", light = 0.45, z = 2 },
		{ tex = "impact_lines", count = 2, delay = 0.016, life = NumberRange.new(0.2), size = { 9, 11.5, 12.5 }, rot = NumberRange.new(0, 360),
			color = "white", fade = "cut", light = 0.3, z = 1.8 },
		{ tex = "ring", count = 2, delay = 0.016, life = NumberRange.new(0.3, 0.4), size = { 2, 8.5, 10.5 }, rot = NumberRange.new(0, 360),
			color = "tint", fade = "late", light = 0.3, z = 1 },
		{ tex = "spark", count = 14, life = NumberRange.new(0.2, 0.38), size = { 1.5, 1, 0 }, speed = NumberRange.new(40, 66),
			spread = 180, orient = "velocity", drag = 6, color = "flash", fade = "late", light = 0.5, z = 1.5, squash = 1 },
		{ tex = "smoke", count = 8, delay = 0.03, life = NumberRange.new(0.55, 0.8), size = { 3, 5, 5.6 }, sizeJitter = 0.25,
			speed = NumberRange.new(5, 10), spread = 180, rot = NumberRange.new(0, 360), color = "smoke", fade = "linear", z = -0.5, drag = 3.5 },
		{ tex = "ring", count = 1, delay = 0.03, ground = true, life = NumberRange.new(0.42), size = { 3, 13, 16 }, orient = "flat",
			color = "ground", fade = "late", z = 0.2 },
		{ tex = "dust", count = 9, delay = 0.03, ground = true, life = NumberRange.new(0.7, 1), size = { 3, 5, 5.8 }, sizeJitter = 0.3,
			speed = NumberRange.new(12, 20), spread = 84, up = true, drag = 4.5, color = "ground", fade = "linear", z = -0.3 },
		{ tex = "debris", count = 10, delay = 0.03, ground = true, life = NumberRange.new(0.7, 1), size = { 0.65, 0.65, 0.5 }, sizeJitter = 0.45,
			speed = NumberRange.new(20, 32), spread = 40, up = true, accel = Vector3.new(0, -90, 0), spin = NumberRange.new(-480, 480),
			rot = NumberRange.new(0, 360), color = "ground", fade = "late", z = 0.4 },
	},
	marks = { { mark = "crack", size = 11, hold = 8, fadeTime = 1.6, delay = 0.03 } },
}

local tier = "full"
local TIER_KEEP: { [string]: { [string]: boolean } } = {
	bare = { star = true, ring = true },
}
function VfxDesign.setTier(t: string)
	tier = t
end

local pool: { [string]: { att: Attachment, pe: ParticleEmitter } } = {}
local markPool: { BasePart } = {}
local folder: Folder? = nil

local function getFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "VfxDesign"
	f.Parent = Workspace
	folder = f
	return f
end

local function seq3(a: number, b: number, c: number, jitter: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, a, a * jitter),
		NumberSequenceKeypoint.new(0.35, b, b * jitter),
		NumberSequenceKeypoint.new(1, c, c * jitter),
	})
end

local FADES: { [string]: NumberSequence } = {
	cut = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(0.86, 1), NumberSequenceKeypoint.new(1, 1) }),
	late = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.05), NumberSequenceKeypoint.new(1, 1) }),
	linear = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0), NumberSequenceKeypoint.new(1, 0.6) }),
}

local function colorFor(layer: Layer, tint: Color3, groundColor: Color3): ColorSequence
	local mode = layer.color or "tint"
	if mode == "white" then
		return ColorSequence.new(WHITE)
	elseif mode == "flash" then
		return ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.3, WHITE:Lerp(tint, 0.55)), ColorSequenceKeypoint.new(1, tint) })
	elseif mode == "smoke" then
		local c = SMOKE_LIT:Lerp(tint, 0.18)
		return ColorSequence.new(c)
	elseif mode == "ground" then
		return ColorSequence.new(groundColor:Lerp(WHITE, 0.35))
	end
	return ColorSequence.new(tint)
end

local function emitterFor(layer: Layer, tint: Color3, groundColor: Color3, scale: number): ParticleEmitter
	local col = colorFor(layer, tint, groundColor)
	local key = string.format("%s|%s|%s|%.2f|%s|%s", layer.tex, tostring(layer.size[1]), tostring(layer.orient), scale,
		tostring(col.Keypoints[#col.Keypoints].Value), tostring(layer.life))
	local slot = pool[key]
	if slot and slot.pe.Parent then
		return slot.pe
	end
	local att = Instance.new("Attachment")
	att.Name = layer.tex
	att.Parent = Workspace.Terrain
	local pe = Instance.new("ParticleEmitter")
	pe.Name = layer.tex
	pe.Enabled = false
	pe.Texture = "rbxassetid://" .. ID[layer.tex]
	pe.Lifetime = layer.life
	local j = layer.sizeJitter or 0
	pe.Size = seq3(layer.size[1] * scale, layer.size[2] * scale, layer.size[3] * scale, j)
	pe.Transparency = FADES[layer.fade or "linear"]
	pe.Color = col
	pe.LightEmission = layer.light or 0
	pe.LightInfluence = 0
	pe.ZOffset = layer.z or 0
	pe.Speed = layer.speed or NumberRange.new(0.01)
	pe.Drag = layer.drag or 0
	pe.Acceleration = layer.accel or Vector3.zero
	pe.Rotation = layer.rot or NumberRange.new(0)
	pe.RotSpeed = layer.spin or NumberRange.new(0)
	pe.Squash = NumberSequence.new(layer.squash or 0)
	local spread = layer.spread or 0
	pe.SpreadAngle = Vector2.new(spread, spread)
	pe.EmissionDirection = Enum.NormalId.Top
	local o = layer.orient or "face"
	if o == "velocity" then
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
	elseif o == "flat" then
		pe.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		pe.Speed = NumberRange.new(0.01)
		pe.SpreadAngle = Vector2.zero
	elseif o == "upright" then
		pe.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
	else
		pe.Orientation = Enum.ParticleOrientation.FacingCamera
	end
	local sheet = SHEET[layer.tex]
	if sheet then
		pe.FlipbookLayout = sheet
		if VARIANTS[layer.tex] then
			pe.FlipbookMode = Enum.ParticleFlipbookMode.Loop
			pe.FlipbookFramerate = NumberRange.new(0)
			pe.FlipbookStartRandom = true
		elseif LOOPS[layer.tex] then
			pe.FlipbookMode = Enum.ParticleFlipbookMode.Loop
			pe.FlipbookFramerate = NumberRange.new(24)
			pe.FlipbookStartRandom = true
		else
			pe.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		end
	end
	pe.Parent = att
	pool[key] = { att = att, pe = pe }
	return pe
end

local function groundBelow(pos: Vector3, ignore: { Instance }?): (Vector3, Color3)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = { getFolder() }
	if ignore then
		for _, i in ignore do
			table.insert(list, i)
		end
	end
	params.FilterDescendantsInstances = list
	local hit = Workspace:Raycast(pos, Vector3.new(0, -40, 0), params)
	if hit then
		local inst = hit.Instance
		local c = if inst:IsA("BasePart") then inst.Color else Color3.fromRGB(196, 168, 122)
		if inst == Workspace.Terrain then
			c = Workspace.Terrain:GetMaterialColor(hit.Material)
		end
		return hit.Position, c
	end
	return pos - Vector3.new(0, 3, 0), Color3.fromRGB(196, 168, 122)
end

local function placeMark(m: Mark, at: Vector3, scale: number)
	local part = table.remove(markPool)
	if not part then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(1, 0.05, 1)
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Top
		d.Parent = p
		p.Name = "Mark"
		part = p
	end
	local p = part :: BasePart
	local d = p:FindFirstChildOfClass("Decal") :: Decal
	d.Texture = "rbxassetid://" .. ID[m.mark]
	d.Transparency = 0
	local s = m.size * scale
	p.Size = Vector3.new(s, 0.05, s)
	p.CFrame = CFrame.new(at + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	p.Parent = getFolder()
	task.delay(m.hold, function()
		local tw = TweenService:Create(d, TweenInfo.new(m.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		p.Parent = nil
		table.insert(markPool, p)
	end)
end

export type PlayOpts = {
	tint: Color3?,
	scale: number?,
	ignore: { Instance }?,
	facing: Vector3?,
}

function VfxDesign.play(name: string, position: Vector3, opts: PlayOpts?)
	local recipe = R[name]
	if not recipe then
		return
	end
	local o: PlayOpts = opts or {}
	local tint = o.tint or VfxDesign.Palette.Neutral
	local scale = o.scale or 1
	local groundPos, groundColor = groundBelow(position, o.ignore)
	local keep = TIER_KEEP[tier]
	for _, layer in recipe.layers do
		if keep and not keep[layer.tex] then
			continue
		end
		local count = layer.count
		if tier == "low" then
			count = math.max(1, math.floor(count * 0.4 + 0.5))
		end
		local pe = emitterFor(layer, tint, groundColor, scale)
		local att = pe.Parent :: Attachment
		local at = if layer.ground then groundPos + Vector3.new(0, 0.15, 0) else position
		local function fire()
			att.WorldCFrame = CFrame.new(at)
			pe:Emit(count)
		end
		local d = layer.delay or 0
		if d > 0 then
			task.delay(d, fire)
		else
			fire()
		end
	end
	if recipe.marks and tier ~= "bare" then
		for _, m in recipe.marks do
			task.delay(m.delay or 0, placeMark, m, groundPos, scale)
		end
	end
end

function VfxDesign.freeze(on: boolean)
	for _, slot in pool do
		slot.pe.TimeScale = if on then 0 else 1
	end
end

function VfxDesign.clear()
	for _, slot in pool do
		slot.pe:Clear()
	end
	local f = folder
	if f then
		for _, c in f:GetChildren() do
			c.Parent = nil
		end
	end
end

return VfxDesign
