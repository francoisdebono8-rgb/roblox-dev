-- BuildRoot - Session 5A "InteriorWorld" builder for the /root ACCESS building.
--
-- SERVER ONLY. Self-contained ModuleScript. Mirrors PlotBuilder/MapBuilder runtime-
-- neon style (no --!strict; instance-heavy). Builds the enterable HACKER DEN: a dim,
-- claustrophobic green room of terminal desks running fake decrypt/loading screens,
-- a couple of blinking server racks, and eerie lore graffiti on the walls.
--
-- KEY "ROOT" (/root ACCESS). entry.size 80 x 26 x 80. Dead end (no secret room).
-- Reads ALL coordinates/colors/sizes from ReplicatedStorage.HackerTycoon.InteriorConfig.
-- Exposes ONE function: M.Build(parent) -> Model. Creates only its own instances under
-- the Model it returns; touches no existing system. Build() prints nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteriorConfig = require(ReplicatedStorage:WaitForChild("HackerTycoon"):WaitForChild("InteriorConfig"))

local BuildRoot = {}

local KEY = "ROOT"
local NL = string.char(10)

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local any = p :: any
	for k, v in pairs(props) do
		any[k] = v
	end
	return p
end

-- Small green PointLight helper (Shadows off, dim, claustrophobic den glow).
local function addLight(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = part
	return light
end

function BuildRoot.Build(parent)
	local entry = InteriorConfig.GetBuilding(KEY)
	local base = InteriorConfig.BuildingBaseCFrame(KEY)
	if not entry or not base then
		return nil
	end
	local size = entry.size
	local accent = entry.color
	local DARK = InteriorConfig.DARK
	-- Sickly green for the static decor figures (theme calls for a posed hacker corpse).
	local SICKLY = Color3.fromRGB(120, 200, 90)

	-- Local-space placement helper: world CFrame = base * CFrame.new(x, y, z).
	-- Local -Z faces the Core (door wall); +Z runs deeper; +Y up; +X to the side.
	local function L(x, y, z)
		return base * CFrame.new(x, y, z)
	end

	local model = Instance.new("Model")
	model.Name = KEY .. "_Building"

	local halfX = size.X / 2
	local halfZ = size.Z / 2
	local wallH = size.Y
	local wallT = 1.5

	------------------------------------------------------------------
	-- SHELL: floor, four walls (front wall is a doorway), roof.
	------------------------------------------------------------------
	-- Floor slab: top at world y=1 (local y=0). 1 thick, so centre at local y=-0.5.
	local floor = newPart({
		Name = "Floor",
		Size = Vector3.new(size.X, 1, size.Z),
		CFrame = L(0, -0.5, 0),
		Color = DARK,
		Material = Enum.Material.Metal,
	})
	floor.Parent = model
	model.PrimaryPart = floor

	-- Floor neon grid trim (thin lines) for the green den glow underfoot.
	for _, lz in ipairs({ -halfZ + 8, 0, halfZ - 8 }) do
		local stripe = newPart({
			Name = "FloorStripe",
			Size = Vector3.new(size.X - 6, 0.2, 0.5),
			CFrame = L(0, 0.1, lz),
			Color = accent,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
		})
		stripe.Parent = model
	end

	-- Roof slab: bottom at wall top. Centre at local y = wallH + 0.5.
	local roof = newPart({
		Name = "Roof",
		Size = Vector3.new(size.X, 1, size.Z),
		CFrame = L(0, wallH + 0.5, 0),
		Color = DARK,
		Material = Enum.Material.Metal,
	})
	roof.Parent = model

	-- Helper to build a solid dark wall with a neon edge strip along its top.
	local function solidWall(name, partSize, cf)
		local w = newPart({
			Name = name,
			Size = partSize,
			CFrame = cf,
			Color = DARK,
			Material = Enum.Material.SmoothPlastic,
		})
		w.Parent = model
	end

	-- Back wall (local +Z, far from Core).
	solidWall("BackWall", Vector3.new(size.X, wallH, wallT), L(0, wallH / 2, halfZ))
	-- Side walls (local +/-X).
	solidWall("SideWallR", Vector3.new(wallT, wallH, size.Z), L(halfX, wallH / 2, 0))
	solidWall("SideWallL", Vector3.new(wallT, wallH, size.Z), L(-halfX, wallH / 2, 0))

	-- Neon edge trim along the top of three walls + the front lintel area.
	for _, t in ipairs({
		{ Vector3.new(size.X, 0.5, 0.6), L(0, wallH - 0.5, halfZ) },
		{ Vector3.new(0.6, 0.5, size.Z), L(halfX, wallH - 0.5, 0) },
		{ Vector3.new(0.6, 0.5, size.Z), L(-halfX, wallH - 0.5, 0) },
	}) do
		local trim = newPart({
			Name = "EdgeTrim",
			Size = t[1],
			CFrame = t[2],
			Color = accent,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		})
		trim.Parent = model
	end

	------------------------------------------------------------------
	-- FRONT WALL (local -Z, faces Core) with a ~12 wide x 14 tall DOORWAY:
	-- two side pillars + a lintel, NOT a solid slab, so the player walks in.
	------------------------------------------------------------------
	local doorW = 12
	local doorH = 14
	local sidePanelW = (size.X - doorW) / 2
	-- Left pillar (toward -X).
	solidWall(
		"FrontPillarL",
		Vector3.new(sidePanelW, wallH, wallT),
		L(-(doorW / 2 + sidePanelW / 2), wallH / 2, -halfZ)
	)
	-- Right pillar (toward +X).
	solidWall(
		"FrontPillarR",
		Vector3.new(sidePanelW, wallH, wallT),
		L((doorW / 2 + sidePanelW / 2), wallH / 2, -halfZ)
	)
	-- Lintel above the doorway (fills wall from doorH up to wallH).
	local lintelH = wallH - doorH
	solidWall(
		"FrontLintel",
		Vector3.new(doorW, lintelH, wallT),
		L(0, doorH + lintelH / 2, -halfZ)
	)
	-- Neon doorway frame (two uprights + a bar) in green.
	for _, d in ipairs({
		{ Vector3.new(0.6, doorH, 0.8), L(-doorW / 2, doorH / 2, -halfZ) },
		{ Vector3.new(0.6, doorH, 0.8), L(doorW / 2, doorH / 2, -halfZ) },
		{ Vector3.new(doorW + 1.2, 0.6, 0.8), L(0, doorH, -halfZ) },
	}) do
		local frame = newPart({
			Name = "DoorFrame",
			Size = d[1],
			CFrame = d[2],
			Color = accent,
			Material = Enum.Material.Neon,
		})
		frame.Parent = model
	end

	------------------------------------------------------------------
	-- EXTERIOR SIGN above the doorway (entry.sign in entry.color).
	-- entry.sign for ROOT is "/root ACCESS" (non-empty), so we build it.
	------------------------------------------------------------------
	if entry.sign ~= "" then
		local signPost = newPart({
			Name = "SignAnchor",
			Size = Vector3.new(doorW + 2, 1, 1),
			CFrame = L(0, doorH + 2.5, -halfZ - 0.6),
			Color = DARK,
			Material = Enum.Material.Neon,
			Transparency = 1,
		})
		signPost.Parent = model
		local sg = Instance.new("BillboardGui")
		sg.Name = "ExteriorSign"
		sg.Size = UDim2.fromScale(14, 3.5)
		sg.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
		sg.MaxDistance = 300
		sg.AlwaysOnTop = false
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(6, 10, 8)
		lbl.BackgroundTransparency = 0.3
		lbl.Font = Enum.Font.Code
		lbl.TextColor3 = accent
		lbl.TextStrokeTransparency = 0.3
		lbl.TextScaled = true
		lbl.Text = entry.sign
		lbl.Parent = sg
		sg.Parent = signPost
	end

	------------------------------------------------------------------
	-- INTERIOR LIGHTING: a few dim green PointLights. Low light = claustrophobic.
	------------------------------------------------------------------
	for _, lp in ipairs({
		L(-halfX + 14, wallH - 3, -halfZ + 16),
		L(halfX - 14, wallH - 3, -halfZ + 16),
		L(-halfX + 14, wallH - 3, halfZ - 16),
		L(halfX - 14, wallH - 3, halfZ - 16),
		L(0, wallH - 3, 0),
	}) do
		local fixture = newPart({
			Name = "CeilingLight",
			Size = Vector3.new(3, 0.6, 3),
			CFrame = lp,
			Color = accent,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		})
		addLight(fixture, accent, 26, 1.4)
		fixture.Parent = model
	end

	------------------------------------------------------------------
	-- TERMINAL DESKS in rows: dark desk + upright neon monitor panel showing a
	-- fake decrypt / cascading-code / loading screen. Kept off the central walk path.
	------------------------------------------------------------------
	-- Pre-built code-cascade text (columns of 1s and 0s + a decrypt header).
	local function codeCascade(seed)
		local rng = Random.new(seed)
		local rows = {}
		rows[#rows + 1] = ">> DECRYPTING..."
		for _ = 1, 9 do
			local cols = {}
			for _ = 1, 18 do
				cols[#cols + 1] = (rng:NextInteger(0, 1) == 1) and "1" or "0"
			end
			rows[#rows + 1] = table.concat(cols, " ")
		end
		rows[#rows + 1] = ">> KEY @ 0x" .. string.format("%04X", rng:NextInteger(0, 65535))
		return table.concat(rows, NL)
	end

	local function buildDesk(name, cf, seed, facingSign)
		-- Desk surface (solid, you can lean on it but cannot pass through).
		local desk = newPart({
			Name = name .. "_Desk",
			Size = Vector3.new(7, 0.6, 3),
			CFrame = cf * CFrame.new(0, 2, 0),
			Color = Color3.fromRGB(22, 26, 32),
			Material = Enum.Material.Metal,
			CanCollide = true,
		})
		desk.Parent = model
		-- Two legs.
		for _, lx in ipairs({ -3, 3 }) do
			local leg = newPart({
				Name = name .. "_Leg",
				Size = Vector3.new(0.5, 2, 0.5),
				CFrame = cf * CFrame.new(lx, 1, 0),
				Color = DARK,
				Material = Enum.Material.Metal,
				CanCollide = false,
			})
			leg.Parent = model
		end
		-- Upright neon monitor panel (flat, non-colliding).
		local monitor = newPart({
			Name = name .. "_Monitor",
			Size = Vector3.new(6, 4, 0.3),
			CFrame = cf * CFrame.new(0, 4.6, -0.9),
			Color = Color3.fromRGB(4, 8, 6),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		monitor.Parent = model
		addLight(monitor, accent, 12, 1.2)
		-- Screen text on the side that faces back toward the open room (facingSign tells
		-- us which local face is visible to a walking player).
		local sg = Instance.new("SurfaceGui")
		sg.Name = "Screen"
		sg.Face = facingSign
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.Parent = monitor
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(3, 8, 5)
		lbl.BackgroundTransparency = 0.1
		lbl.Font = Enum.Font.Code
		lbl.TextColor3 = accent
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.TextScaled = true
		lbl.Text = codeCascade(seed)
		lbl.Parent = sg
		-- A neon "loading bar" part sitting on the desk in front of the monitor.
		local barBack = newPart({
			Name = name .. "_LoadBack",
			Size = Vector3.new(4.5, 0.5, 0.4),
			CFrame = cf * CFrame.new(0, 2.5, -0.4),
			Color = Color3.fromRGB(8, 14, 10),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		barBack.Parent = model
		local barFill = newPart({
			Name = name .. "_LoadFill",
			Size = Vector3.new(1.8, 0.55, 0.45),
			CFrame = cf * CFrame.new(-0.9, 2.5, -0.4),
			Color = accent,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		barFill.Parent = model
		-- Tiny text label above the bar reading a "[####------] 40%" style readout.
		local bg = Instance.new("BillboardGui")
		bg.Name = "LoadText"
		bg.Size = UDim2.fromScale(6, 1.2)
		bg.StudsOffsetWorldSpace = Vector3.new(0, 0.8, 0)
		bg.MaxDistance = 60
		bg.Adornee = barBack
		local blbl = Instance.new("TextLabel")
		blbl.Size = UDim2.fromScale(1, 1)
		blbl.BackgroundTransparency = 1
		blbl.Font = Enum.Font.Code
		blbl.TextColor3 = accent
		blbl.TextStrokeTransparency = 0.4
		blbl.TextScaled = true
		blbl.Text = "[####------] 40%"
		blbl.Parent = bg
		bg.Parent = barBack
	end

	-- Two rows of desks down the sides (along +X and -X), monitors against the side
	-- walls, screens facing inward toward the central walk path. Front-to-back (+Z).
	local deskZs = { -halfZ + 22, -halfZ + 40, halfZ - 18 }
	local n = 0
	for _, lz in ipairs(deskZs) do
		-- Left row: desk near the -X wall, facing +X (right face = inward).
		n += 1
		buildDesk("DeskL" .. n, L(-halfX + 10, 0, lz) * CFrame.Angles(0, math.rad(90), 0), 100 + n, Enum.NormalId.Front)
		-- Right row: desk near the +X wall, facing -X (also inward).
		n += 1
		buildDesk("DeskR" .. n, L(halfX - 10, 0, lz) * CFrame.Angles(0, math.rad(-90), 0), 200 + n, Enum.NormalId.Front)
	end

	------------------------------------------------------------------
	-- SERVER RACKS: a couple of tall dark cabinets with blinking neon dots.
	------------------------------------------------------------------
	local function buildRack(name, cf, seed)
		local cabinet = newPart({
			Name = name,
			Size = Vector3.new(5, 16, 4),
			CFrame = cf * CFrame.new(0, 8, 0),
			Color = Color3.fromRGB(16, 18, 24),
			Material = Enum.Material.Metal,
			CanCollide = true,
		})
		cabinet.Parent = model
		local rng = Random.new(seed)
		-- A grid of small neon "blinking" dots on the front face (+local-Z toward open room).
		for row = 0, 6 do
			for col = 0, 2 do
				local on = rng:NextNumber() > 0.4
				local dot = newPart({
					Name = name .. "_LED",
					Size = Vector3.new(0.4, 0.4, 0.3),
					CFrame = cf * CFrame.new(-1.6 + col * 1.6, 3 + row * 1.8, -2.1),
					Color = on and accent or Color3.fromRGB(10, 20, 14),
					Material = Enum.Material.Neon,
					Transparency = on and 0 or 0.5,
					CanCollide = false,
				})
				if on then
					addLight(dot, accent, 4, 0.5)
				end
				dot.Parent = model
			end
		end
	end

	-- Two racks against the back wall, flanking the center, leaving the path clear.
	buildRack("ServerRackA", L(-halfX + 16, 0, halfZ - 6), 555)
	buildRack("ServerRackB", L(halfX - 16, 0, halfZ - 6), 777)

	------------------------------------------------------------------
	-- LORE GRAFFITI: neon TextLabels on the walls. REQUIRED lines included verbatim.
	------------------------------------------------------------------
	local function graffiti(name, text, cf, faceSize)
		local panel = newPart({
			Name = name,
			Size = Vector3.new(faceSize.X, faceSize.Y, 0.3),
			CFrame = cf,
			Color = Color3.fromRGB(8, 12, 9),
			Material = Enum.Material.Neon,
			Transparency = 0.5,
			CanCollide = false,
		})
		panel.Parent = model
		local sg = Instance.new("SurfaceGui")
		sg.Name = "Graffiti"
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.Parent = panel
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Code
		lbl.TextColor3 = accent
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.TextStrokeTransparency = 0.2
		lbl.TextScaled = true
		lbl.Text = text
		lbl.Parent = sg
	end

	-- Left side wall (-X): panel faces +X (Front of a part rotated to look toward +X).
	graffiti(
		"GraffitiCoreLies",
		"THE CORE LIES",
		L(-halfX + wallT, wallH / 2 + 2, -halfZ + 28) * CFrame.Angles(0, math.rad(90), 0),
		Vector2.new(20, 7)
	)
	graffiti(
		"GraffitiNotAnomalies",
		"THEY ARE NOT ANOMALIES",
		L(-halfX + wallT, wallH / 2 - 4, halfZ - 26) * CFrame.Angles(0, math.rad(90), 0),
		Vector2.new(22, 5)
	)
	-- Right side wall (+X): panel faces -X.
	graffiti(
		"GraffitiCollect",
		"COLLECT BEFORE THEY COME",
		L(halfX - wallT, wallH / 2 + 2, -halfZ + 30) * CFrame.Angles(0, math.rad(-90), 0),
		Vector2.new(22, 6)
	)
	-- Back wall (+Z): panel faces -Z (toward the room / door).
	graffiti(
		"GraffitiNumbers",
		"9 5 6 3",
		L(-halfX + 30, wallH / 2 + 4, halfZ - wallT) * CFrame.Angles(0, math.rad(180), 0),
		Vector2.new(16, 8)
	)

	------------------------------------------------------------------
	-- DECOR NPC: one posed, sickly-green geometric hacker figure slumped against a
	-- dead terminal (static decor, CanCollide=false, NOT an AmbientLife zombie).
	------------------------------------------------------------------
	local function buildZombie(name, cf)
		local parts = {
			-- torso
			{ "Torso", Vector3.new(2, 2.6, 1), CFrame.new(0, 1.6, 0) },
			-- head, tilted/drooping forward
			{ "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 3.1, 0.4) * CFrame.Angles(math.rad(35), 0, 0) },
			-- arms slack at sides
			{ "ArmL", Vector3.new(0.7, 2.2, 0.7), CFrame.new(-1.4, 1.5, 0.1) * CFrame.Angles(math.rad(10), 0, 0) },
			{ "ArmR", Vector3.new(0.7, 2.2, 0.7), CFrame.new(1.4, 1.5, 0.1) * CFrame.Angles(math.rad(10), 0, 0) },
			-- legs sprawled forward (sitting against the terminal)
			{ "LegL", Vector3.new(0.8, 2.4, 0.8), CFrame.new(-0.6, 0.2, 1.2) * CFrame.Angles(math.rad(80), 0, 0) },
			{ "LegR", Vector3.new(0.8, 2.4, 0.8), CFrame.new(0.6, 0.2, 1.2) * CFrame.Angles(math.rad(80), 0, 0) },
		}
		for _, pp in ipairs(parts) do
			local isHead = pp[1] == "Head"
			local figPart = newPart({
				Name = name .. "_" .. pp[1],
				Size = pp[2],
				CFrame = cf * pp[3],
				Color = isHead and Color3.fromRGB(150, 220, 110) or SICKLY,
				Material = Enum.Material.Neon,
				Transparency = 0.15,
				CanCollide = false,
			})
			figPart.Parent = model
		end
	end

	-- Slumped in the back-left corner against a server rack, half in shadow.
	buildZombie("DenZombie", L(-halfX + 22, 0, halfZ - 12) * CFrame.Angles(0, math.rad(200), 0))

	model.Parent = parent
	return model
end

return BuildRoot
