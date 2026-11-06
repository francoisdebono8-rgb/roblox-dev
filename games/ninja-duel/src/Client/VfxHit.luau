--!strict
-- VfxHit : coups qui touchent, style « animé moderne » (06/11/2026).
--
-- Choix de François (14 h 05) : le modèle est l'animé moderne de Roblox
-- (Jujutsu Shenanigans, The Strongest Battlegrounds). Un impact se lit en
-- mouvement : la cible flashe en blanc, un éclair rond, une sphère de traits
-- de vent qui tourne, un cône de souffle qui traverse la cible dans le sens
-- du coup, des étincelles projetées vers l'arrière, et au sol un anneau de
-- poussière et un cratère de dalles. Pas d'étoile, pas de Neon uni.
-- L'arrêt sur image et la secousse restent dans Feedback / Camera.
-- Formes : VfxMesh (modèle Blender 131130332204867). Présentation seule.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VfxMesh = require(script.Parent.VfxMesh)
local K = VfxMesh._k

local VfxHit = {}

local TEX = {
	streak = "rbxassetid://114052840081545",
	glow = "rbxassetid://106966465851735",
	ringband = "rbxassetid://103142974880636",
	spark = "rbxassetid://79205682571618",
	smoke = "rbxassetid://74803998450943",
}
local WHITE = Color3.new(1, 1, 1)
-- Coup sans chakra : blanc chaud ; avec chakra, la couleur de la nature.
VfxHit.NeutralTint = Color3.fromRGB(255, 200, 130)

-- -------------------------------------------------------------- particules
local pool: { [string]: ParticleEmitter } = {}

local function emitter(key: string, build: (ParticleEmitter) -> ()): ParticleEmitter
	local pe = pool[key]
	if pe and pe.Parent then
		return pe
	end
	local att = Instance.new("Attachment")
	att.Name = "VfxHit"
	att.Parent = Workspace.Terrain
	local n = Instance.new("ParticleEmitter")
	n.Enabled = false
	n.LightInfluence = 0
	build(n)
	n.Parent = att
	pool[key] = n
	return n
end

local function fireAt(pe: ParticleEmitter, cf: CFrame, count: number)
	local att = pe.Parent :: Attachment
	att.WorldCFrame = cf
	pe:Emit(count)
end

-- Repère dont l'axe +Y suit la direction du coup (les émetteurs tirent vers « Top »).
local function along(at: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(at, at + dir) * CFrame.Angles(-math.pi / 2, 0, 0)
end

local function glow(at: Vector3, tint: Color3, s: number)
	local key = string.format("glow|%.2f|%s", s, tostring(tint))
	local pe = emitter(key, function(e)
		e.Texture = TEX.glow
		e.Lifetime = NumberRange.new(0.09)
		e.Speed = NumberRange.new(0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5 * s), NumberSequenceKeypoint.new(0.4, 6.5 * s), NumberSequenceKeypoint.new(1, 7 * s) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, tint) })
		e.LightEmission = 1
		e.ZOffset = 2
	end)
	fireAt(pe, CFrame.new(at), 1)
end

local function sparks(at: Vector3, dir: Vector3, tint: Color3, s: number, count: number)
	local key = string.format("spark|%.2f|%s", s, tostring(tint))
	local pe = emitter(key, function(e)
		e.Texture = TEX.spark
		e.Lifetime = NumberRange.new(0.12, 0.22)
		e.Speed = NumberRange.new(55 * s, 85 * s)
		e.Drag = 9
		e.SpreadAngle = Vector2.new(32, 32)
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.8 * s), NumberSequenceKeypoint.new(0.5, 2.2 * s), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, tint) })
		e.LightEmission = 1
		e.ZOffset = 1.5
	end)
	fireAt(pe, along(at, dir), count)
end

local function dust(ground: Vector3, dir: Vector3, groundColor: Color3, s: number, count: number)
	local c = groundColor:Lerp(WHITE, 0.3)
	local key = string.format("dust|%.2f|%s", s, tostring(c))
	local pe = emitter(key, function(e)
		e.Texture = TEX.smoke
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		e.Lifetime = NumberRange.new(0.5, 0.75)
		e.Speed = NumberRange.new(9 * s, 15 * s)
		e.Drag = 4
		e.SpreadAngle = Vector2.new(35, 35)
		e.Acceleration = Vector3.new(0, 3, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2 * s, 0.5 * s), NumberSequenceKeypoint.new(0.4, 3.6 * s, 0.8 * s), NumberSequenceKeypoint.new(1, 4.2 * s, 0.8 * s) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0), NumberSequenceKeypoint.new(1, 0.6) })
		e.Color = ColorSequence.new(c)
		e.ZOffset = -1
	end)
	-- vers l'arrière de la cible, à ras du sol
	local flat = Vector3.new(dir.X, 0, dir.Z)
	local d = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(1, 0, 0)
	fireAt(pe, along(ground + Vector3.new(0, 0.6, 0), (d + Vector3.new(0, 0.35, 0)).Unit), count)
end

-- -------------------------------------------------------------- formes
local function shockSphere(at: Vector3, dir: Vector3, tint: Color3, s: number, life: number)
	local p = K.spawn("ND_ShockSphere")
	if not p then
		return
	end
	p.Material = Enum.Material.Neon
	p.TextureID = TEX.streak
	p.Color = WHITE:Lerp(tint, 0.25)
	p.Transparency = 0.02
	local cf = along(at, dir)
	p.Size = Vector3.one * 1.2 * s
	p.CFrame = cf
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = Vector3.one * 7 * s, CFrame = cf * CFrame.Angles(0, math.rad(150), 0) })
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
	K.expire(p, life + 0.05)
end

local function windCone(at: Vector3, dir: Vector3, tint: Color3, s: number, life: number)
	local p = K.spawn("ND_WindCone")
	if not p then
		return
	end
	p.Material = Enum.Material.Neon
	p.TextureID = TEX.streak
	p.Color = WHITE:Lerp(tint, 0.15)
	p.Transparency = 0.02
	local cf = along(at - dir * 0.4, dir)
	local function place(diameter: number, length: number): (Vector3, CFrame)
		return Vector3.new(diameter, length, diameter), cf * CFrame.new(0, length / 2, 0)
	end
	local s0, c0 = place(1.4 * s, 1 * s)
	p.Size = s0
	p.CFrame = c0
	local s1, c1 = place(5.5 * s, 10 * s)
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = s1, CFrame = c1 * CFrame.Angles(0, math.rad(200), 0) })
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
	K.expire(p, life + 0.05)
end

local function groundRing(ground: Vector3, groundColor: Color3, s: number, life: number)
	local p = K.spawn("ND_RingFlat")
	if not p then
		return
	end
	p.Material = Enum.Material.Neon
	p.TextureID = TEX.ringband
	p.Color = groundColor:Lerp(WHITE, 0.55)
	p.Transparency = 0.15
	local cf = CFrame.new(ground + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
	p.Size = Vector3.new(2 * s, 0.01, 2 * s)
	p.CFrame = cf
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = Vector3.new(13 * s, 0.01, 13 * s), CFrame = cf * CFrame.Angles(0, 0.6, 0) })
	K.play(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
	K.expire(p, life + 0.05)
end

-- La cible flashe en blanc (contour à la couleur du coup), puis s'efface.
function VfxHit.flash(model: Instance?, tint: Color3, hold: number, fade: number)
	if not model then
		return
	end
	local h = Instance.new("Highlight")
	h.FillColor = WHITE
	h.OutlineColor = tint
	h.FillTransparency = 0
	h.OutlineTransparency = 0.2
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = model
	h.Parent = model
	task.delay(hold, function()
		local tw = TweenService:Create(h, TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 1 })
		tw:Play()
		tw.Completed:Once(function()
			h:Destroy()
		end)
	end)
end

-- Lumière d'impact : éclaire les deux corps une fraction de seconde.
local function light(at: Vector3, tint: Color3, s: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = Workspace.Terrain
	local l = Instance.new("PointLight")
	l.Color = WHITE:Lerp(tint, 0.5)
	l.Brightness = 5 * s
	l.Range = 12 * s
	l.Shadows = false
	l.Parent = a
	TweenService:Create(l, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	task.delay(0.2, function()
		a:Destroy()
	end)
end

export type HitOpts = { dir: Vector3?, tint: Color3?, victim: Instance?, ignore: { Instance }? }

local WEIGHT: { [string]: { s: number, sparks: number, cone: boolean, ground: boolean, crater: boolean, hold: number } } = {
	light = { s = 0.55, sparks = 4, cone = false, ground = false, crater = false, hold = 0.03 },
	medium = { s = 0.78, sparks = 7, cone = true, ground = false, crater = false, hold = 0.04 },
	heavy = { s = 1, sparks = 10, cone = true, ground = true, crater = false, hold = 0.05 },
	slam = { s = 1.1, sparks = 12, cone = true, ground = true, crater = true, hold = 0.06 },
	ko = { s = 1.35, sparks = 14, cone = true, ground = true, crater = true, hold = 0.07 },
}

-- Interrupteur général (repli sur les anciens effets si false).
VfxHit.enabled = true
-- Styles de contact du serveur (Combat:pushImpact) repris par ce module, et leur poids.
-- La garde (block / parry) garde son propre rendu.
VfxHit.STYLE = { light = "light", air = "light", flow = "light", launcher = "medium", finisher = "heavy", slam = "slam" } :: { [string]: string }
function VfxHit.handles(style: string?): boolean
	return VfxHit.enabled and style ~= nil and VfxHit.STYLE[style] ~= nil
end

function VfxHit.hit(weight: string, at: Vector3, opts: HitOpts?)
	local w = WEIGHT[weight] or WEIGHT.medium
	local o: HitOpts = opts or {}
	local tint = o.tint or VfxHit.NeutralTint
	local dir = o.dir or Vector3.new(1, 0, 0)
	dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(1, 0, 0)
	local s = w.s
	VfxHit.flash(o.victim, tint, w.hold, 0.14 + 0.06 * s)
	glow(at, tint, s)
	light(at, tint, s)
	sparks(at, dir, tint, s, w.sparks)
	shockSphere(at, dir, tint, s, 0.16 + 0.08 * s)
	if w.cone then
		windCone(at, dir, tint, s, 0.2 + 0.08 * s)
	end
	if w.ground then
		local ground, groundColor = K.groundBelow(at, o.ignore)
		if (at - ground).Magnitude < 9 then
			groundRing(ground, groundColor, s, 0.34)
			dust(ground, dir, groundColor, s, if weight == "ko" then 5 else 3)
			if w.crater then
				VfxMesh.crater(ground, groundColor, 2.6 * s, if weight == "ko" then 9 else 6, 2.2 * s, if weight == "ko" then 7 else 4)
				VfxMesh.chunks(ground, groundColor, if weight == "ko" then 7 else 4, 0.6 * s, 30 * s)
			end
		end
	end
end

function VfxHit.freeze(on: boolean)
	for _, pe in pool do
		pe.TimeScale = if on then 0 else 1
	end
	VfxMesh.freeze(on)
end

function VfxHit.clear()
	for _, pe in pool do
		pe:Clear()
	end
	VfxMesh.clear()
end

return VfxHit
