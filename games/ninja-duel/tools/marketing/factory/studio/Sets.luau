--!nocheck
-- Ninja Duel content factory: the filming sets, REBUILT FROM CODE (Edit mode).
--
-- Why: a hand-built set stays stuck in the copy of the game it was made in
-- (that is how every clip up to 04/11 came out of a pre-v25 build). Here the
-- sets are code: open the latest Labo build, run this, save as ND-Clips-vNN.
-- The fighters are dressed by the CURRENT build (World.rig + LookMeshes).
--
-- In execute_luau (Edit datamodel of the new place), with this file stored as
-- ServerStorage.NDFactory.Sets:
--   local S = require(game.ServerStorage.NDFactory.Sets)
--   S.check()        -- refuses an old build (no hand seals / no beta roster)
--   S.all()          -- TournamentSet + FactorySets.DevlogSet (with the host)
--   S.host()         -- only rebuild the devlog host
local Sets = {}
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local V, CF, rgb, rad = Vector3.new, CFrame.new, Color3.fromRGB, math.rad

local function find(name, root)
	for _, d in ipairs((root or SSS):GetDescendants()) do
		if d.Name == name and d:IsA("ModuleScript") then return d end
	end
end
local function new(class, props, parent)
	local x = Instance.new(class)
	for k, v in pairs(props) do x[k] = v end
	if parent then x.Parent = parent end
	return x
end
local function part(parent, name, size, cf, color, material, extra)
	local p = new("Part", {Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic,
		Anchored = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth}, nil)
	for k, v in pairs(extra or {}) do p[k] = v end
	p.Parent = parent
	return p
end
local function label(parentGui, text, color, y, h, stroke, strokeColor)
	local t = new("TextLabel", {Name = "TextLabel", Text = text, TextColor3 = color, TextScaled = true, BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, h), Position = UDim2.fromScale(0, y),
		FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json")}, parentGui)
	new("UIStroke", {Thickness = stroke or 3, Color = strokeColor or Color3.new()}, t)
	return t
end
local function surface(p, face, pps)
	return new("SurfaceGui", {Face = face, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = pps, LightInfluence = 0}, p)
end

----------------------------------------------------------------------- gate
-- What a filming build must have. Bump it when a release adds something the
-- videos must show (the factory's config.json has the same list).
Sets.REQUIRED = {"SealJutsu", "BetaRoster"}
function Sets.check()
	local ND = RS:FindFirstChild("NinjaDuel")
	local missing = {}
	for _, n in ipairs(Sets.REQUIRED) do
		if not (ND and ND:FindFirstChild(n, true)) and not find(n, RS) then table.insert(missing, n) end
	end
	-- the dev hooks (NinjaDuelDev appears in Play; in Edit, the DevHooks script and the debug flag)
	if not (SS:FindFirstChild("NinjaDuelDev") or (function() for _, d in ipairs(SSS:GetDescendants()) do if d.Name == "DevHooks" and d:IsA("LuaSourceContainer") then return true end end end)() or workspace:GetAttribute("NinjaDuelDebug")) then
		table.insert(missing, "DevHooks (open the ND-Test build)")
	end
	local ok = #missing == 0
	return {ok = ok, place = game.Name, missing = missing, features = Sets.features()}
end
function Sets.features()
	local f = {}
	for _, n in ipairs({"SealJutsu", "BetaRoster", "ChakraFlow", "Roster"}) do
		if find(n, RS) or find(n, SSS) then table.insert(f, n) end
	end
	return f
end

------------------------------------------------------------------ fighters
local World, LM, Fighters
local function engine()
	World = World or require(find("World"))
	LM = LM or require(find("LookMeshes"))
	Fighters = Fighters or require(RS.NinjaDuel.Fighters)
	LM.preload()
	local t = os.clock()
	while os.clock() - t < 20 do
		local busy = false
		for _, s in pairs(LM.state) do if s == "loading" then busy = true end end
		if not busy then break end
		task.wait(0.3)
	end
end

-- Lay the posed model's parts out from its joints (no physics in Edit).
local function solve(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local offs = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("WeldConstraint") and d.Part0 and d.Part1 then offs[d] = d.Part0.CFrame:ToObjectSpace(d.Part1.CFrame) end
	end
	local done, links = {[root] = true}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if (d:IsA("Motor6D") or d:IsA("Weld")) and d.Part0 and d.Part1 then
			table.insert(links, {d.Part0, d.Part1, function(p0) return p0.CFrame * d.C0 * d.C1:Inverse() end})
			table.insert(links, {d.Part1, d.Part0, function(p1) return p1.CFrame * d.C1 * d.C0:Inverse() end})
		elseif d:IsA("WeldConstraint") and offs[d] then
			local o = offs[d]
			table.insert(links, {d.Part0, d.Part1, function(p0) return p0.CFrame * o end})
			table.insert(links, {d.Part1, d.Part0, function(p1) return p1.CFrame * o:Inverse() end})
		end
	end
	for _ = 1, 40 do
		local moved = false
		for _, l in ipairs(links) do
			if done[l[1]] and not done[l[2]] then l[2].CFrame = l[3](l[1]); done[l[2]] = true; moved = true end
		end
		if not moved then break end
	end
end
Sets.solve = solve

Sets.POSES = {
	guard = {LeftShoulder = {38, -10, -14}, RightShoulder = {26, 12, 16}, LeftElbow = {72, 0, 0}, RightElbow = {84, 0, 0}, LeftHip = {14, 0, -6}, RightHip = {-10, 0, 6}, LeftKnee = {-18, 0, 0}, RightKnee = {-8, 0, 0}, Waist = {-4, -10, 0}, Neck = {2, 6, 0}},
	cross = {RightShoulder = {30, 40, 10}, RightElbow = {100, 0, 0}, LeftShoulder = {30, -40, -10}, LeftElbow = {100, 0, 0}, Neck = {-4, -12, 0}, Waist = {0, 8, 0}, LeftHip = {4, 0, -6}, RightHip = {-4, 0, 6}},
	relaxed = {LeftShoulder = {4, 0, -6}, RightShoulder = {4, 0, 6}, LeftElbow = {14, 0, 0}, RightElbow = {18, 0, 0}, Neck = {-2, 0, 0}},
	-- the devlog host: weight on one leg, the kunai held up in front of the chest
	host = {RightShoulder = {38, 0, 16}, RightElbow = {96, 0, 0}, LeftShoulder = {6, 0, -10}, LeftElbow = {22, 0, 0},
		Neck = {-4, -8, 0}, Waist = {0, 8, 0}, LeftHip = {6, 0, -5}, RightHip = {-4, 0, 6}, RightKnee = {-6, 0, 0}},
}
-- A dressed, anchored fighter of the current build, feet on `floorY`.
function Sets.fighter(parent, id, at, yaw, pose, floorY, name)
	engine()
	local model, _, root, joints = World.rig(parent, Fighters[id], CF(at) * CFrame.Angles(0, yaw or math.pi, 0), name or id)
	root.Anchored = true
	for jn, a in pairs(Sets.POSES[pose or "guard"] or {}) do
		local j = (joints and joints[jn]) or model:FindFirstChild(jn, true)
		if j and j:IsA("Motor6D") then j.C0 = j.C0 * CFrame.Angles(rad(a[1]), rad(a[2]), rad(a[3])) end
	end
	solve(model)
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	if floorY then
		local cf, size = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() + V(0, floorY - (cf.Y - size.Y / 2), 0))
	end
	return model
end

---------------------------------------------------------------- tournament
-- Same layout as the set the 04/11 videos used (ClipKit's _G.NDB reads it):
-- O = (0,200,900); tiers of 8/4/2/1 pedestals stepping up and back.
Sets.O = V(0, 200, 900)
Sets.TIERS = {{n = 8, sp = 7.5, y = 0, z = 0}, {n = 4, sp = 15, y = 5, z = -12}, {n = 2, sp = 30, y = 10, z = -24}, {n = 1, sp = 0, y = 15, z = -36}}
Sets.BRACKET = {"Legion", "GentleFist", "Leaf", "Sand", "Lion", "Copycat", "Mirage", "Flashstep"}
Sets.NAME = {Legion = "NARUTO", GentleFist = "NEJI", Leaf = "ROCK LEE", Sand = "GAARA", Lion = "SASUKE", Copycat = "KAKASHI", Mirage = "ITACHI", Flashstep = "MINATO"}
local function slot(t, i) local T = Sets.TIERS[t]; return Sets.O + V((i - (T.n + 1) / 2) * T.sp, T.y, T.z) end
Sets.slot = slot

function Sets.tournament(opts)
	opts = opts or {}
	local old = workspace:FindFirstChild("TournamentSet"); if old then old:Destroy() end
	local set = new("Model", {Name = "TournamentSet"}, workspace)
	local CYL = CFrame.Angles(0, 0, rad(90))
	part(set, "Stage", V(80, 2, 60), CF(0, 199, 886), rgb(46, 40, 66), Enum.Material.Slate)
	local LINE = rgb(255, 120, 30)
	for t, T in ipairs(Sets.TIERS) do
		for i = 1, T.n do
			local s = slot(t, i)
			local ped = s - V(0, 0.5, 0)
			part(set, ("Ped_%d_%d"):format(t, i), V(1.6, 5, 5), CF(ped) * CYL, t == 4 and rgb(230, 180, 60) or rgb(60, 58, 70), Enum.Material.Marble, {Shape = Enum.PartType.Cylinder})
			part(set, ("Ring_%d_%d"):format(t, i), V(0.3, 5.6, 5.6), CF(ped + V(0, 0.85, 0)) * CYL, rgb(255, 140, 40), Enum.Material.Neon, {Shape = Enum.PartType.Cylinder})
			if t > 1 then
				local h = 5 * (t - 1)
				part(set, ("Col_%d_%d"):format(t, i), V(4, h, 4), CF(s.X, s.Y - 0.5 - 0.7 - h / 2, s.Z), rgb(40, 38, 48), Enum.Material.Slate)
			end
		end
		-- bracket lines on the floor of each tier, towards the next one
		if t < 4 then
			local y, z = Sets.O.Y + T.y + 0.05, Sets.O.Z + T.z
			for i = 1, T.n do
				local s = slot(t, i)
				part(set, "Line", V(0.35, 0.25, 3.4), CF(s.X, y, z - 4.3), LINE, Enum.Material.Neon)
			end
			for q = 1, T.n / 2 do
				local a, b = slot(t, 2 * q - 1), slot(t, 2 * q)
				local mx = (a.X + b.X) / 2
				part(set, "Line", V(0.35, 0.25, b.X - a.X), CF(mx, y, z - 6) * CFrame.Angles(0, rad(90), 0), LINE, Enum.Material.Neon)
				part(set, "Line", V(0.35, 0.25, 3.4), CF(mx, y, z - 7.7), LINE, Enum.Material.Neon)
			end
		end
	end
	-- name plates (ClipKit moves them up the bracket)
	for i, id in ipairs(Sets.BRACKET) do
		local p = part(set, "Plate_" .. Sets.NAME[id], V(5.6, 1.2, 0.3), CF(slot(1, i) + V(0, 0.6, 3.3)), rgb(18, 18, 24))
		label(surface(p, Enum.NormalId.Back, 60), Sets.NAME[id], Color3.new(1, 1, 1), 0, 1, 3)
	end
	local banner = part(set, "Banner", V(70, 22, 1), CF(0, 214, 856), rgb(40, 32, 58), Enum.Material.Slate)
	label(surface(banner, Enum.NormalId.Back, 25), "PRODIGY TOURNAMENT", rgb(255, 200, 60), 0.04, 0.32, 6)
	part(set, "TrophyBase", V(1.2, 2.4, 2.4), CF(0, 215.6, 862.4) * CYL, rgb(240, 190, 60), Enum.Material.Metal, {Shape = Enum.PartType.Cylinder})
	part(set, "TrophyStem", V(2.2, 0.7, 0.7), CF(0, 217.2, 862.4) * CYL, rgb(240, 190, 60), Enum.Material.Metal, {Shape = Enum.PartType.Cylinder})
	part(set, "TrophyCup", V(2.8, 2.8, 2.8), CF(0, 219.2, 862.4), rgb(255, 205, 70), Enum.Material.Metal, {Shape = Enum.PartType.Ball})
	local key = part(set, "KeyLight", V(1, 1, 1), CF(0, 225, 930) * CFrame.Angles(rad(-29), 0, 0), Color3.new(1, 1, 1), nil, {Transparency = 1, CanCollide = false})
	new("SpotLight", {Brightness = 1.6, Range = 70, Angle = 90, Face = Enum.NormalId.Front, Color = Color3.new(1, 1, 1)}, key)
	-- the eight fighters of the current build, on the first tier
	if opts.fighters ~= false then
		for i, id in ipairs(Sets.BRACKET) do
			local s = slot(1, i)
			Sets.fighter(set, id, s + V(0, 3.2, 0), math.pi, opts.pose or "guard", s.Y + 0.3)
			task.wait()
		end
	end
	return set
end

-------------------------------------------------------------------- devlog
Sets.O2 = V(0, 200, 1150)
function Sets.devlog(opts)
	opts = opts or {}
	local root = workspace:FindFirstChild("FactorySets") or new("Folder", {Name = "FactorySets"}, workspace)
	local old = root:FindFirstChild("DevlogSet"); if old then old:Destroy() end
	local set = new("Model", {Name = "DevlogSet"}, root)
	part(set, "Floor", V(40, 1, 30), CF(0, 199.5, 1146), rgb(28, 26, 38), Enum.Material.Slate)
	local back = part(set, "Backdrop", V(40, 22, 1), CF(0, 210, 1138), rgb(22, 20, 32))
	local g = surface(back, Enum.NormalId.Front, 40)
	label(g, "NINJA DUEL", rgb(255, 196, 40), 0.16, 0.32, 6, rgb(14, 10, 18))
	label(g, "DEVLOG", rgb(0, 210, 255), 0.5, 0.14, 6, rgb(14, 10, 18))
	part(set, "Trim1", V(40, 0.25, 0.3), CF(0, 201.2, 1138.6), rgb(255, 150, 40), Enum.Material.Neon)
	part(set, "Trim2", V(40, 0.25, 0.3), CF(0, 218.5, 1138.6), rgb(255, 150, 40), Enum.Material.Neon)
	for k, x in ipairs({-7, 7}) do
		part(set, "Pillar" .. k, V(1.2, 16, 1.2), CF(x, 208, 1139.5), rgb(40, 36, 56))
		part(set, "PillarGlow" .. k, V(0.2, 14, 0.2), CF(x, 208, 1140.15), rgb(0, 210, 255), Enum.Material.Neon)
	end
	local key = part(set, "KeyLight", V(1, 1, 1), CF(-6, 209, 1160) * CFrame.fromOrientation(rad(-23), rad(-30), 0), Color3.new(1, 1, 1), nil, {Transparency = 1, CanCollide = false})
	new("SpotLight", {Brightness = 2.2, Range = 30, Angle = 70, Face = Enum.NormalId.Front, Color = rgb(255, 240, 225)}, key)
	local rim = part(set, "RimLight", V(1, 1, 1), CF(4, 209, 1144) * CFrame.fromOrientation(rad(-34), rad(146), 0), Color3.new(1, 1, 1), nil, {Transparency = 1, CanCollide = false})
	new("SpotLight", {Brightness = 3, Range = 25, Angle = 60, Face = Enum.NormalId.Front, Color = rgb(190, 120, 255)}, rim)
	if opts.host ~= false then Sets.host(set) end
	return set
end

---------------------------------------------------------------------- host
-- The devlog host (user 04/11 16:17): an original Otsutsuki — white hair with
-- two pink locks, one Rinnegan and one Sharingan, a mask like Kakashi's,
-- Itachi's ANBU armour, Minato's three-pronged kunai. Built on the current
-- Itachi rig (the armour), with pieces taken from the other looks.
Sets.HOST = {
	skin = rgb(246, 238, 238), hair = rgb(240, 240, 246), hairShade = rgb(206, 206, 222), pink = rgb(255, 120, 190),
	mask = rgb(30, 32, 42), brow = rgb(232, 232, 240),
	rinne = rgb(196, 176, 232), rinneRing = rgb(96, 64, 148), shar = rgb(214, 28, 36), sharDark = rgb(120, 8, 18),
	-- {look, piece, colour key}
	-- the mask (Kakashi's mesh) and a thigh holster; the hair is built below
	-- (user 04/11 16:37: « il n'a pas de cheveux… des cheveux en épi, un
	-- personnage stylé »): cone spikes swept up and back, a side-swept
	-- fringe, two pink locks framing the face.
	pieces = {{"Kakashi", "Head__Mask", "mask"}, {"Kakashi", "RightUpperLeg__Holster", nil}},
	drop = {"Head__BackHair", "Head__HairTie", "Head__BandKnot", "Head__HeadbandPlate", "Head__PlateMark", "TearLine"},
	-- {root (head space), direction, length, width, depth}: Looks' cone locks
	spikes = {
		{V(0, .85, -.15), V(0, 1, .55), 1.45, .78, .55}, {V(-.45, .78, -.05), V(-.45, 1, .55), 1.25, .7, .5},
		{V(.45, .78, -.05), V(.45, 1, .55), 1.25, .7, .5}, {V(-.2, .9, .35), V(-.2, .9, 1), 1.2, .7, .5},
		{V(.2, .9, .35), V(.2, .9, 1), 1.2, .7, .5}, {V(-.7, .62, .3), V(-.75, .75, .75), 1.05, .62, .46},
		{V(.7, .62, .3), V(.75, .75, .75), 1.05, .62, .46}, {V(-.85, .4, .05), V(-1, .45, .3), .9, .58, .42},
		{V(.85, .4, .05), V(1, .45, .3), .9, .58, .42}, {V(0, .55, .7), V(0, .35, 1), 1.1, .7, .5},
		{V(-.5, .4, .65), V(-.5, .2, 1), .95, .6, .45}, {V(.5, .4, .65), V(.5, .2, 1), .95, .6, .45},
		{V(0, .1, .82), V(0, -.45, 1), .85, .6, .45},
		-- the fringe, swept to one side
		{V(-.55, .78, -.5), V(.05, -1, -.3), .66, .48, .3}, {V(-.22, .86, -.56), V(.25, -1, -.32), .72, .5, .3},
		{V(.14, .86, -.56), V(.38, -1, -.3), .7, .48, .3}, {V(.48, .78, -.5), V(.5, -1, -.25), .66, .46, .3},
		-- over the ears
		{V(-.95, .3, .1), V(-.2, -1, .1), .85, .46, .38}, {V(.95, .3, .1), V(.2, -1, .1), .85, .46, .38},
	},
}

local function addPiece(model, look, pieceName, color)
	local data = LM.Data[look]; local made = LM.templates[look]
	if not data or not made then return nil, "no look " .. look end
	for _, pc in ipairs(data.pieces) do
		if pc.name == pieceName then
			local body = model:FindFirstChild(pc.body); local tpl = made[pc.name]
			if not body or not tpl then return nil, "no template " .. pieceName end
			local p = tpl:Clone()
			p.Name = "Host__" .. pieceName:gsub("^.-__", "")
			p.Size = pc.size; p.Color = color or pc.color
			p.Material = Enum.Material[pc.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = false
			p.CFrame = body.CFrame * CF(pc.offset)
			new("WeldConstraint", {Part0 = body, Part1 = p}, p)
			p.Parent = model
			return p
		end
	end
	return nil, "no piece " .. pieceName
end

-- Minato's Flying Thunder God kunai: the game's own model when the build has
-- it (Shared/HiraishinKunai), else the factory's copy (studio/HiraishinKunai).
function Sets.kunai(parent, at)
	local m = find("HiraishinKunai", RS) or find("HiraishinKunai", SS)
	local k = require(m).build()
	k.Parent = parent
	k:PivotTo(at)
	local list = {}
	for _, p in ipairs(k:GetDescendants()) do if p:IsA("BasePart") then table.insert(list, p) end end
	return k, list
end

-- Restyle the drawn eyes: one Rinnegan (rings, no tomoe), one Sharingan.
local function eyes(model, H)
	local head = model:FindFirstChild("Head")
	for _, p in ipairs(model:GetChildren()) do
		if p.Name == "FaceEye" and p:IsA("BasePart") then
			local gui = p:FindFirstChildOfClass("SurfaceGui")
			local white = gui and gui:FindFirstChild("White")
			local iris = white and white:FindFirstChild("Iris")
			if iris then
				local left = head.CFrame:PointToObjectSpace(p.Position).X < 0 -- the character's left eye
				local grad = iris:FindFirstChildOfClass("UIGradient")
				local pupil = iris:FindFirstChild("Pupil")
				for _, c in ipairs(iris:GetChildren()) do if c.Name == "Shine" then c.Size = UDim2.fromScale(c.Size.X.Scale * 0.6, c.Size.Y.Scale * 0.6) end end
				if left then
					iris.BackgroundColor3 = H.rinne
					if grad then grad.Color = ColorSequence.new(H.rinne:Lerp(H.rinneRing, 0.35), H.rinne) end
					iris.Size = UDim2.fromScale(iris.Size.X.Scale * 1.12, iris.Size.Y.Scale * 1.08)
					if pupil then pupil.Size = UDim2.fromScale(0.16, 0.16); pupil.BackgroundColor3 = H.rinneRing:Lerp(Color3.new(), 0.4) end
					for _, t in ipairs(iris:GetChildren()) do if t.Name == "Tomoe" then t.Visible = false end end
					for k, s in ipairs({0.82, 0.6, 0.38}) do
						local r = new("Frame", {Name = "RinneRing" .. k, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(s, s),
							BackgroundTransparency = 1, ZIndex = 2}, iris)
						new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, r)
						new("UIStroke", {Thickness = 2.2, Color = H.rinneRing}, r)
					end
				else
					iris.BackgroundColor3 = H.shar
					if grad then grad.Color = ColorSequence.new(H.sharDark, H.shar) end
					if pupil then pupil.Size = UDim2.fromScale(0.26, 0.26) end
					for _, t in ipairs(iris:GetChildren()) do if t.Name == "Tomoe" then t.Visible = true end end
					local r = new("Frame", {Name = "SharRing", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.6, 0.6),
						BackgroundTransparency = 1, ZIndex = 0}, iris)
					new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, r)
					new("UIStroke", {Thickness = 1.6, Color = H.sharDark:Lerp(Color3.new(), 0.3), Transparency = 0.2}, r)
				end
			end
			local brow = gui and gui:FindFirstChild("Brow"); if brow then brow.BackgroundColor3 = H.brow end
			local lid = white and white:FindFirstChild("Lid"); if lid then lid.BackgroundColor3 = H.skin end
		elseif p.Name == "FaceMouth" and p:IsA("BasePart") then
			p.Transparency = 1
			local gui = p:FindFirstChildOfClass("SurfaceGui"); if gui then gui.Enabled = false end -- under the mask
		end
	end
end

-- The hair: a rounded mass over the skull, cone spikes (the cone Looks
-- uses, rbxassetid 1778999: 1 x 1.3 x 1 at scale 1, apex up), and the two
-- pink locks framing the face.
local CONE, CONE_H = "rbxassetid://1778999", 1.3
local function cone(model, head, name, base, dir, len, w, d, color)
	local unit = dir.Unit
	local center = base + unit * len * .5
	local up = if math.abs(unit.Y) > .95 then Vector3.zAxis else Vector3.yAxis
	local p = part(model, name, V(.2, .2, .2), head.CFrame * (CFrame.lookAt(center, center + unit, up) * CFrame.Angles(-math.pi / 2, 0, 0)), color,
		Enum.Material.SmoothPlastic, {CanCollide = false, CastShadow = false, Massless = true})
	new("SpecialMesh", {MeshType = Enum.MeshType.FileMesh, MeshId = CONE, Scale = V(w, len / CONE_H, d or w)}, p)
	new("WeldConstraint", {Part0 = head, Part1 = p}, p)
	return p
end
local function hair(model, H)
	local head = model:FindFirstChild("Head")
	local base = part(model, "Host__HairBase", V(2.0, 1.15, 1.98), head.CFrame * CF(0, .52, .08), H.hair, Enum.Material.SmoothPlastic,
		{CanCollide = false, CastShadow = false, Massless = true})
	new("SpecialMesh", {MeshType = Enum.MeshType.Sphere}, base)
	new("WeldConstraint", {Part0 = head, Part1 = base}, base)
	for i, s in ipairs(H.spikes) do
		cone(model, head, "Host__Spike", s[1], s[2], s[3], s[4], s[5], if i % 4 == 0 then H.hairShade else H.hair)
	end
	for _, s in ipairs({-1, 1}) do
		cone(model, head, "Host__PinkLock", V(s * .82, .56, -.6), V(s * .05, -1, -.1), 1.55, .21, .14, H.pink)
	end
end

function Sets.host(parent, at, opts)
	engine()
	opts = opts or {}
	local H = table.clone(Sets.HOST)
	for k, v in pairs(opts) do H[k] = v end
	parent = parent or workspace.FactorySets.DevlogSet
	local old = parent:FindFirstChild("Otsutsuki"); if old then old:Destroy() end
	local base = at or (Sets.O2 + V(0, 3, 0))
	-- built standing straight (pose "relaxed"), then dressed, then laid out
	local model = Sets.fighter(parent, "Mirage", base, math.pi, H.pose or "host", nil, "Otsutsuki")
	model:SetAttribute("NDHost", true)
	for _, n in ipairs(H.drop) do
		for _, c in ipairs(model:GetChildren()) do if c.Name == n then c:Destroy() end end
	end
	-- pale Otsutsuki skin on every skin-coloured piece
	local itachiSkin = rgb(248, 224, 204)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:find("Skin") or d.Name:find("Fist") or d.Name:find("Toes") or (d.Color.R * 255 > 240 and math.abs(d.Color.G * 255 - 224) < 10)) and not d.Name:find("Host__") then
			if d.Transparency < 1 then d.Color = H.skin end
		end
	end
	local miss = {}
	for _, pc in ipairs(H.pieces) do
		local p, err = addPiece(model, pc[1], pc[2], pc[3] and H[pc[3]] or nil)
		if not p then table.insert(miss, err) end
	end
	hair(model, H)
	eyes(model, H)
	-- the kunai: one in the right hand (reverse grip), one tucked at the back of the belt
	local hand = model:FindFirstChild("RightHand")
	if hand then
		local _, list = Sets.kunai(model, hand.CFrame * CF(0, -0.18, 0) * CFrame.Angles(rad(-90), 0, 0))
		for _, p in ipairs(list) do new("WeldConstraint", {Part0 = hand, Part1 = p}, p) end
	end
	local lower = model:FindFirstChild("LowerTorso")
	if lower then
		local _, list = Sets.kunai(model, lower.CFrame * CF(0.35, 0.05, 0.62) * CFrame.Angles(0, 0, rad(-60)) * CFrame.Angles(rad(90), 0, 0))
		for _, p in ipairs(list) do new("WeldConstraint", {Part0 = lower, Part1 = p}, p) end
	end
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + V(0, (Sets.O2.Y + 0.0) - (cf.Y - size.Y / 2), 0))
	return model, miss
end

function Sets.all(opts)
	local c = Sets.check()
	if not c.ok and not (opts and opts.force) then
		return "REFUSED: this place is missing " .. table.concat(c.missing, ", ") .. " — open the latest ND-Test build (make_clip_place.py)"
	end
	Sets.tournament(opts)
	Sets.devlog(opts)
	return "sets built in " .. c.place
end

return Sets
