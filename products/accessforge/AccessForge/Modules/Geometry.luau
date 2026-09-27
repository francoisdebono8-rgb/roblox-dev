local Settings = require(script.Parent.Settings)
local Geometry = {}
local UP = Vector3.yAxis

local function horizontal(v) return Vector3.new(v.X, 0, v.Z) end

function Geometry.plan(a, b, input)
	local s = Settings.validate(input)
	for _, point in ipairs({ a, b }) do
		assert(typeof(point) == "Vector3" and Settings.number(point.Magnitude) and point.Magnitude < 20000, "Invalid marker position or too far from origin.")
	end
	local flat = horizontal(b - a)
	local rise, run = b.Y - a.Y, flat.Magnitude
	assert(run >= 0.5 and run <= 1000, "Markers need 0.5 to 1000 studs of horizontal separation.")
	local plan = { settings = s, parts = {}, rise = rise, run = run, steps = 0, actualRise = 0, depths = {}, warnings = {} }
	local function part(group, name, size, cf, rail, round)
		assert(#plan.parts < Settings.MAX_PARTS, "Output exceeds 1000 parts. Increase spacing or reduce the structure.")
		assert(size.X >= 0.05 and size.Y >= 0.05 and size.Z >= 0.05 and size.Magnitude < 2048, "A generated dimension is outside the supported range.")
		table.insert(plan.parts, { group = group, name = name, size = size, cf = cf, color = rail and s.RailColor or s.Color, material = rail and "Metal" or s.Material, round = round or false })
	end
	local function beam(group, name, p, q, thickness, rail, round)
		local length = (q - p).Magnitude
		assert(length >= 0.05, "Degenerate beam. Change dimensions.")
		local up = if math.abs((q - p).Unit:Dot(UP)) > 0.99 then Vector3.zAxis else UP
		local cf = CFrame.lookAt((p + q) / 2, q, up)
		if round then
			part(group, name, Vector3.new(length, thickness, thickness), cf * CFrame.Angles(0, math.pi / 2, 0), rail, true)
		else
			part(group, name, Vector3.new(thickness, thickness, length), cf, rail)
		end
	end
	local function railing(name, p, q, floorAt)
		local length = horizontal(q - p).Magnitude
		if length < 0.05 then return end
		local intervals = math.ceil(length / s.PostSpacing)
		assert(intervals <= Settings.MAX_PARTS, "Too many rail posts. Increase post spacing.")
		local round = s.RailProfile == "Round"
		beam("Rails", name .. "Top", p + UP * s.RailHeight, q + UP * s.RailHeight, 0.18, true, round)
		if s.MidRail then beam("Rails", name .. "Mid", p + UP * s.RailHeight * 0.5, q + UP * s.RailHeight * 0.5, 0.12, true, round) end
		for i = 0, intervals do
			local t = i / intervals
			local base = p:Lerp(q, t)
			local foot = floorAt and Vector3.new(base.X, floorAt(t), base.Z) or base
			local top = base + UP * s.RailHeight
			assert(top.Y - foot.Y >= 0.2, "Rail height is too low for these risers.")
			beam("Rails", name .. "Post" .. i, foot, top, 0.2, true, round)
		end
	end
	local function deck(name, center, direction, width, depth)
		part("Landings", name, Vector3.new(width, s.Thickness, depth), CFrame.lookAt(center - UP * s.Thickness / 2, center + direction - UP * s.Thickness / 2))
		if s.Supports then
			local bottom = center.Y - s.Thickness
			assert(bottom - s.FloorHeight >= 0.1, "Support floor must be below the deck underside.")
			local right = direction:Cross(UP)
			local intervals = math.max(1, math.ceil(depth / s.SupportSpacing))
			assert(intervals * 2 + #plan.parts < Settings.MAX_PARTS, "Too many supports. Increase support spacing.")
			for i = 0, intervals do
				for _, side in ipairs({ -1, 1 }) do
					local pos = center + right * side * (width / 2 - 0.25) + direction * ((i / intervals - 0.5) * math.max(depth - 0.5, 0.1))
					part("Supports", name .. "Support", Vector3.new(0.4, bottom - s.FloorHeight, 0.4), CFrame.new(pos.X, (bottom + s.FloorHeight) / 2, pos.Z))
				end
			end
		end
	end
	local function flight(name, p, q, count)
		local delta = horizontal(q - p)
		local direction, depth = delta.Unit, delta.Magnitude / count
		local h = (q.Y - p.Y) / count
		assert(depth >= 0.5 and depth <= 40, "Actual tread depth must be 0.5 to 40 studs. Move markers or change the rise/tread targets.")
		assert(h >= 0.1 and h <= s.RiserHeight + 1e-5, "The requested run produces risers below 0.1 studs. Increase target tread depth.")
		assert(s.Thickness <= h, "Tread thickness must not exceed the actual riser height.")
		if s.RailLeft or s.RailRight then assert(s.RailHeight > 2 * h + 0.2, "Rail height must exceed twice the actual rise plus 0.2 studs.") end
		table.insert(plan.depths, depth)
		local right = direction:Cross(UP)
		for i = 1, count do
			local center = p + direction * ((i - 0.5) * depth) + UP * (i * h - s.Thickness / 2)
			part("Stairs", name .. string.format("Tread%03d", i), Vector3.new(s.Width, s.Thickness, depth), CFrame.lookAt(center, center + direction))
		end
		for _, side in ipairs({ -1, 1 }) do
			local offset = right * side * (s.Width / 2 - 0.2) - UP * (s.Thickness + 0.15)
			beam("Stairs", name .. "Stringer", p + offset, q + offset, 0.3, false, false)
		end
		local function floorAt(t) return p.Y + math.clamp(math.floor(t * count + 1e-6) + 1, 1, count) * h end
		if s.RailLeft then railing(name .. "Left", p - right * s.Width / 2, q - right * s.Width / 2, floorAt) end
		if s.RailRight then railing(name .. "Right", p + right * s.Width / 2, q + right * s.Width / 2, floorAt) end
	end
	if s.Mode == "Catwalk" then
		assert(math.abs(rise) <= 0.01, "Catwalk markers must have the same elevation (within 0.01 studs).")
		local direction = flat.Unit
		b = Vector3.new(b.X, a.Y, b.Z)
		deck("Catwalk", (a + b) / 2, direction, s.Width, run)
		local side = direction:Cross(UP) * s.Width / 2
		if s.RailLeft then railing("CatwalkLeft", a - side, b - side) end
		if s.RailRight then railing("CatwalkRight", a + side, b + side) end
	else
		assert(rise >= 0.2 and rise <= 500, "End must be 0.2 to 500 studs above Start.")
		local count = math.max(2, math.ceil(rise / s.RiserHeight - 1e-9))
		if s.Mode == "Straight" then count = math.max(count, math.floor(run / s.TreadDepth + 0.5)) end
		assert(count <= Settings.MAX_STEPS, "More than 256 steps. Increase tread/riser targets or reduce the span.")
		plan.steps, plan.actualRise = count, rise / count
		if s.Mode == "Straight" then
			local direction = flat.Unit
			flight("Straight", a, b, count)
			if s.Landing then
				deck("TopLanding", b + direction * s.LandingDepth / 2, direction, s.Width, s.LandingDepth)
				local side = direction:Cross(UP) * s.Width / 2
				if s.RailLeft then railing("LandingLeft", b - side, b - side + direction * s.LandingDepth) end
				if s.RailRight then railing("LandingRight", b + side, b + side + direction * s.LandingDepth) end
			elseif s.Supports then table.insert(plan.warnings, "Supports apply to landings and catwalks; enable a top landing.") end
		else
			assert(run >= s.Width + 0.5, "Switchback entrances must be separated by stair width + at least 0.5 studs.")
			assert(run <= s.Width + 30, "Switchback entrance gap exceeds 30 studs. Bring markers closer.")
			assert(s.LandingDepth >= s.Width / 2, "Switchback landing depth must be at least half the stair width.")
			local across = flat.Unit
			local direction = UP:Cross(across) * (s.ReturnSide == "Right" and 1 or -1)
			local n1, n2 = math.floor(count / 2), math.ceil(count / 2)
			local flightRun = n2 * s.TreadDepth
			assert(flightRun <= 1000, "Switchback flight exceeds 1000 studs. Reduce tread depth.")
			plan.run = flightRun * 2
			local midY = a.Y + n1 * plan.actualRise
			local lowerEnd = Vector3.new(a.X, midY, a.Z) + direction * flightRun
			local upperStart = Vector3.new(b.X, midY, b.Z) + direction * flightRun
			flight("Lower", a, lowerEnd, n1)
			flight("Upper", upperStart, b, n2)
			deck("ReturnLanding", (lowerEnd + upperStart) / 2 + direction * s.LandingDepth / 2, direction, run + s.Width, s.LandingDepth)
			local outer = if s.ReturnSide == "Right" then s.RailLeft else s.RailRight
			local inner = if s.ReturnSide == "Right" then s.RailRight else s.RailLeft
			local left, right = lowerEnd - across * s.Width / 2, upperStart + across * s.Width / 2
			if outer then
				railing("LandingOuterA", left, left + direction * s.LandingDepth)
				railing("LandingBack", left + direction * s.LandingDepth, right + direction * s.LandingDepth)
				railing("LandingOuterB", right + direction * s.LandingDepth, right)
			end
			if inner then railing("LandingGap", lowerEnd + across * s.Width / 2, upperStart - across * s.Width / 2) end
		end
	end
	if #plan.parts > 600 then table.insert(plan.warnings, "Large structure: " .. #plan.parts .. " parts (cap 1000).") end
	if not s.Anchored then table.insert(plan.warnings, "Unanchored parts are independent; no welds are generated.") end
	plan.count = #plan.parts
	return plan
end

return Geometry
