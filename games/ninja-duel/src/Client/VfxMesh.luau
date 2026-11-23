--!strict
-- VfxMesh : effets en volume (formes modélisées dans Blender), refonte du 06/11/2026.
--
-- Retour de François (06/11, 13 h 53) : trop de couches, l'étoile et les
-- traits blancs sont moches ; les effets doivent être des formes faites dans
-- Blender, avec un peu de couleur. On suit donc les jeux de combat animé de
-- Roblox : des maillages Neon qui grandissent, tournent et s'effacent, des
-- rochers qui sortent du sol, et seulement quelques particules (fumée).
--
-- Formes : ~/Documents/NinjaDuelBlender/ND_VFX_meshes.blend
--   -> nd_vfx_meshes_v1.fbx -> modèle Roblox -> MeshParts dans le dossier
--   ReplicatedStorage.VfxMeshes (ND_RingBlade, ND_Crown, ND_Crescent,
--   ND_Spiral, ND_Spike, ND_Rock1..3 anguleux, ND_Slab1..3 dalles de sol, ND_Dome).
-- Présentation seule : rien ici ne touche au gameplay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VfxMesh = {}

-- Couleur par défaut d'un coup sans nature : un orangé chaud (pas de blanc pur).
VfxMesh.DefaultTint = Color3.fromRGB(255, 120, 30)
local WHITE = Color3.new(1, 1, 1)

local AssetService = game:GetService("AssetService")

-- Maillages envoyés le 06/11 (modèle 131130332204867, nd_vfx_meshes_v3.fbx, avec UV).
-- Chargés côté client au démarrage : aucun dossier de modèles à poser dans la place.
local MESH: { [string]: number } = {
	ND_Crescent = 126706042272219,
	ND_Crown = 102734361439896,
	ND_Dome = 79486192867749,
	ND_RingBlade = 139795598159559,
	ND_RingFlat = 90440108290185,
	ND_Rock1 = 138973609471632,
	ND_Rock2 = 103994207358340,
	ND_Rock3 = 89619121514326,
	ND_ShockSphere = 75273062070801,
	ND_Slab1 = 95308830291327,
	ND_Slab2 = 116046601252442,
	ND_Slab3 = 102852927253970,
	ND_Spike = 77187811142416,
	ND_Spiral = 126294882482289,
	ND_WindCone = 129789474452991,
}
VfxMesh.MESH = MESH
local built: { [string]: MeshPart } = {}
for name, id in MESH do
	task.spawn(function()
		local ok, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id))
		end)
		if ok and part then
			part.Name = name
			built[name] = part
		end
	end)
end

local templates: Folder? = nil
local live: { Tween } = {}
local frozen = false
local folder: Folder? = nil

local function getFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "VfxMesh"
	nf.Parent = Workspace
	folder = nf
	return nf
end

function VfxMesh.setTemplates(f: Folder)
	templates = f
end

local function template(name: string): MeshPart?
	local f = templates or ReplicatedStorage:FindFirstChild("VfxMeshes") :: Folder?
	local t = f and f:FindFirstChild(name)
	if t and t:IsA("MeshPart") then
		return t
	end
	return built[name]
end

local function spawn(name: string): MeshPart?
	local t = template(name)
	if not t then
		return nil
	end
	local p = t:Clone()
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = getFolder()
	return p
end

local function play(inst: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local tw = TweenService:Create(inst, info, goal)
	table.insert(live, tw)
	tw.Completed:Once(function()
		local i = table.find(live, tw)
		if i then
			table.remove(live, i)
		end
	end)
	if not frozen then
		tw:Play()
	end
	return tw
end

-- Taille proportionnelle à la taille d'origine du maillage (diamètre voulu en studs).
local function sized(p: MeshPart, diameter: number, yScale: number?): Vector3
	local base = p.MeshSize
	local k = diameter / math.max(base.X, base.Z)
	return Vector3.new(base.X * k, base.Y * k * (yScale or 1), base.Z * k)
end

-- Disparition différée (attend la fin d'un arrêt sur image en revue).
local function expire(p: Instance, t: number)
	task.delay(t, function()
		while frozen do
			task.wait(0.1)
		end
		p:Destroy()
	end)
end

local function later(t: number, fn: () -> ())
	if t <= 0 then
		fn()
	else
		task.delay(t, fn)
	end
end

-- Anneau-lame face au coup : grandit vite, tourne un peu, s'efface.
function VfxMesh.ring(at: Vector3, dir: Vector3, color: Color3, d0: number, d1: number, life: number, thick: number?)
	local p = spawn("ND_RingBlade")
	if not p then
		return
	end
	local cf = CFrame.lookAt(at, at + dir) * CFrame.Angles(-math.pi / 2, 0, 0)
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0
	p.Size = sized(p, d0, thick)
	p.CFrame = cf
	play(p, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = sized(p, d1, (thick or 1) * 0.6), CFrame = cf * CFrame.Angles(0, math.rad(40), 0) })
	play(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
	expire(p, life + 0.05)
end

-- Couronne qui jaillit du sol puis retombe.
function VfxMesh.crown(ground: Vector3, color: Color3, d0: number, d1: number, height: number, life: number)
	local p = spawn("ND_Crown")
	if not p then
		return
	end
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.05
	local base = p.MeshSize
	local function sz(d: number, h: number): Vector3
		local k = d / math.max(base.X, base.Z)
		return Vector3.new(base.X * k, h, base.Z * k)
	end
	p.Size = sz(d0, height * 0.2)
	local cf = CFrame.new(ground + Vector3.new(0, height * 0.1, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
	p.CFrame = cf
	local up = life * 0.35
	play(p, TweenInfo.new(up, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = sz(d1 * 0.8, height), CFrame = cf + Vector3.new(0, height * 0.4, 0) })
	task.delay(up, function()
		play(p, TweenInfo.new(life - up, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = sz(d1, height * 0.15), Transparency = 1, CFrame = cf })
	end)
	expire(p, life + 0.05)
end

-- Dôme de souffle au sol (K.O., ultimes).
function VfxMesh.dome(ground: Vector3, color: Color3, d0: number, d1: number, life: number)
	local p = spawn("ND_Dome")
	if not p then
		return
	end
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.25
	p.Size = sized(p, d0, 0.6)
	p.CFrame = CFrame.new(ground)
	play(p, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = sized(p, d1, 0.45) })
	play(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
	expire(p, life + 0.05)
end

-- Cratère : le sol se soulève en plaques penchées vers l'extérieur, qui restent
-- puis s'enfoncent (des marques qui pèsent, sans couvrir l'arène).
function VfxMesh.crater(ground: Vector3, groundColor: Color3, radius: number, count: number, size: number, hold: number, material: Enum.Material?)
	local a0 = math.random() * math.pi * 2
	for i = 1, count do
		local p = spawn("ND_Slab" .. ((i - 1) % 3 + 1))
		if not p then
			return
		end
		local a = a0 + (i / count) * math.pi * 2 + (math.random() - 0.5) * 0.35
		local r = radius * (0.9 + math.random() * 0.2)
		local s = size * (0.75 + math.random() * 0.5)
		p.Material = material or Enum.Material.Sand
		p.Color = groundColor:Lerp(Color3.new(0, 0, 0), 0.05 + math.random() * 0.08)
		p.Size = sized(p, s)
		local pos = ground + Vector3.new(math.cos(a) * r, s * 0.12, math.sin(a) * r)
		local cf = CFrame.lookAt(pos, Vector3.new(ground.X, pos.Y, ground.Z))
			* CFrame.Angles(math.rad(-(38 + math.random() * 22)), 0, math.random() * 0.4 - 0.2)
		p.CFrame = cf - Vector3.new(0, s * 0.6, 0)
		play(p, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = cf })
		task.delay(hold, function()
			play(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = cf - Vector3.new(0, s, 0) })
			expire(p, 0.75)
		end)
	end
end

-- Éclats de roche projetés (physique locale, sans collision).
function VfxMesh.chunks(ground: Vector3, groundColor: Color3, count: number, size: number, speed: number)
	for i = 1, count do
		local p = spawn("ND_Rock" .. ((i - 1) % 3 + 1))
		if not p then
			return
		end
		p.Material = Enum.Material.Slate
		p.Color = groundColor:Lerp(Color3.new(0, 0, 0), 0.15)
		p.Size = sized(p, size * (0.6 + math.random() * 0.7))
		local a = math.random() * math.pi * 2
		p.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * 0.8, 0.4, math.sin(a) * 0.8)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		if frozen then
			continue
		end
		p.Anchored = false
		p.AssemblyLinearVelocity = Vector3.new(math.cos(a) * speed * 0.45, speed * (0.8 + math.random() * 0.4), math.sin(a) * speed * 0.45)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 20 - 10, math.random() * 20 - 10, math.random() * 20 - 10)
		expire(p, 1.1)
	end
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

export type HitOpts = { tint: Color3?, dir: Vector3?, ignore: { Instance }?, smoke: ((string, Vector3, any) -> ())? }

-- Coups qui touchent : léger, moyen, lourd, K.O. Peu de couches, de la couleur.
function VfxMesh.hit(weight: string, at: Vector3, opts: HitOpts?)
	local o: HitOpts = opts or {}
	local tint = o.tint or VfxMesh.DefaultTint
	local dir = (o.dir or Vector3.new(1, 0, 0)).Unit
	local ground, groundColor = groundBelow(at, o.ignore)
	local pale = tint:Lerp(WHITE, 0.5)
	if weight == "light" then
		VfxMesh.ring(at, dir, tint, 0.6, 3.2, 0.16)
	elseif weight == "medium" then
		VfxMesh.ring(at, dir, tint, 0.8, 4.4, 0.2)
		later(0.03, function()
			VfxMesh.ring(at + dir * 0.6, dir, pale, 0.5, 3, 0.16, 0.7)
		end)
	elseif weight == "heavy" then
		VfxMesh.ring(at, dir, tint, 1, 6.5, 0.26, 1.2)
		later(0.03, function()
			VfxMesh.ring(at + dir * 0.9, dir, pale, 0.6, 4.2, 0.2, 0.8)
		end)
		later(0.02, function()
			VfxMesh.crater(ground, groundColor, 3.0, 6, 2.8, 4)
			VfxMesh.chunks(ground, groundColor, 4, 0.6, 28)
		end)
	elseif weight == "ko" then
		VfxMesh.ring(at, dir, tint, 1.2, 9, 0.32, 1.4)
		later(0.03, function()
			VfxMesh.ring(at + dir * 1.2, dir, pale, 0.8, 6, 0.26, 0.9)
		end)
		later(0.02, function()
			VfxMesh.dome(ground, pale, 2, 14, 0.5)
			VfxMesh.crater(ground, groundColor, 4.0, 9, 3.6, 7)
			VfxMesh.chunks(ground, groundColor, 7, 0.75, 34)
		end)
	end
	if o.smoke then
		local n = ({ light = 0, medium = 1, heavy = 2, ko = 3 } :: { [string]: number })[weight] or 0
		if n > 0 then
			o.smoke("smoke" .. n, at, tint)
		end
	end
end

-- Outil de revue (Studio) : fige ou relance les formes en cours.
function VfxMesh.freeze(on: boolean)
	frozen = on
	for _, tw in live do
		if on then
			tw:Pause()
		else
			tw:Play()
		end
	end
	for _, p in getFolder():GetChildren() do
		if p:IsA("BasePart") and on then
			p.Anchored = true
		end
	end
end

function VfxMesh.clear()
	for _, tw in live do
		tw:Cancel()
	end
	table.clear(live)
	getFolder():ClearAllChildren()
end

-- Outils internes exposés au labo Studio (réglages en direct).
VfxMesh._k = { spawn = spawn, play = play, sized = sized, expire = expire, later = later, groundBelow = groundBelow }

return VfxMesh
