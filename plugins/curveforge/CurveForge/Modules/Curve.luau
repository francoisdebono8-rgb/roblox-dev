local Curve = {}
Curve.TOLERANCE = 0.005
Curve.LENGTH_RELATIVE_TOLERANCE = 0.00001
Curve.MAX_SAMPLES = 8192
Curve.MAX_DEPTH = 18
local frames = setmetatable({}, { __mode = "k" })

local function span(points, i)
	local b, c = points[i], points[i + 1]
	local a, d = points[i - 1] or (2 * b - c), points[i + 2] or (2 * c - b)
	return { b, b + (c - a) / 6, c - (d - b) / 6, c }
end

local function derivative(s, t)
	return 3 * ((s[2] - s[1]) * (1 - t)^2 + 2 * (s[3] - s[2]) * (1 - t) * t + (s[4] - s[3]) * t^2)
end

function Curve.sample(points, guides)
	assert(#points >= 2 and #points <= 8, "Use 2 to 8 ordered control points.")
	for i, p in ipairs(points) do
		assert(p.X == p.X and p.Y == p.Y and p.Z == p.Z and p.Magnitude < 100000, "Invalid control point position.")
		if i > 1 then assert((p - points[i - 1]).Magnitude >= 0.05, "Adjacent control points must be distinct.") end
	end
	assert(not guides or #guides == #points, "One roll guide is required per control.")
	-- Subdivide near zero: float32 world coordinates otherwise manufacture curvature at every split.
	local origin, relative = points[1], {}
	for i, point in ipairs(points) do relative[i] = point - origin end
	local path = { positions = { points[1] }, localPositions = { relative[1] }, lengths = { 0 }, parameters = { 0 }, spans = {}, knots = { 0 }, length = 0, guides = guides and table.clone(guides) }
	local function append(p, u)
		local distance = (p - path.localPositions[#path.localPositions]).Magnitude
		if distance > 1e-8 then
			assert(#path.positions < Curve.MAX_SAMPLES, "Adaptive sample limit exceeded. Simplify the path.")
			path.length += distance
			table.insert(path.positions, if u % 1 == 0 then points[u + 1] else p + origin)
			table.insert(path.localPositions, p); table.insert(path.lengths, path.length); table.insert(path.parameters, u)
		end
	end
	local function subdivide(a, b, c, d, lo, hi, depth)
		local chord = (d - a).Magnitude
		local polygon = (b - a).Magnitude + (c - b).Magnitude + (d - c).Magnitude
		-- Both distance-to-chord and excess length are bounded; midpoint-only tests miss S bends.
		local function deviation(p)
			if chord < 1e-8 then return (p - a).Magnitude end
			local delta, axis = p - a, (d - a) / chord
			local along = math.clamp(delta:Dot(axis), 0, chord)
			return (delta - axis * along).Magnitude
		end
		if math.max(deviation(b), deviation(c)) <= Curve.TOLERANCE
			and polygon - chord <= math.max(1e-8, polygon * Curve.LENGTH_RELATIVE_TOLERANCE) then
			append(d, hi); return
		end
		assert(depth < Curve.MAX_DEPTH, "Adaptive depth limit exceeded. Simplify the path.")
		local ab, bc, cd = (a + b) / 2, (b + c) / 2, (c + d) / 2
		local abc, bcd = (ab + bc) / 2, (bc + cd) / 2
		local mid, u = (abc + bcd) / 2, (lo + hi) / 2
		subdivide(a, ab, abc, mid, lo, u, depth + 1)
		subdivide(mid, bcd, cd, d, u, hi, depth + 1)
	end
	for i = 1, #points - 1 do
		local s = span(relative, i); table.insert(path.spans, s)
		subdivide(s[1], s[2], s[3], s[4], i - 1, i, 0)
		table.insert(path.knots, path.length)
	end
	assert(path.length > 0.05 and path.length < 10000, "Path length must be between 0.05 and 10000 studs.")
	return path
end

local function interval(path, distance)
	distance = math.clamp(distance, 0, path.length)
	local low, high = 2, #path.lengths
	while low < high do
		local mid = math.floor((low + high) / 2)
		if path.lengths[mid] < distance then low = mid + 1 else high = mid end
	end
	return low, (distance - path.lengths[low - 1]) / (path.lengths[low] - path.lengths[low - 1])
end

function Curve.at(path, distance)
	local i, t = interval(path, distance)
	return path.positions[i - 1]:Lerp(path.positions[i], t)
end

local function tangent(path, u, fallback)
	local i = math.min(math.floor(u) + 1, #path.spans)
	local v = derivative(path.spans[i], u - i + 1)
	return if v.Magnitude > 1e-7 then v.Unit else fallback.Unit
end

local function transport(up, before, after)
	local cross, dot = before:Cross(after), math.clamp(before:Dot(after), -1, 1)
	if cross.Magnitude > 1e-7 then
		up = CFrame.fromAxisAngle(cross.Unit, math.atan2(cross.Magnitude, dot)):VectorToWorldSpace(up)
	end
	-- An exact cusp has no unique tangent frame: keep the previous normal for the half-turn.
	local projected = up - after * up:Dot(after)
	assert(projected.Magnitude > 1e-7, "Cannot resolve path frame. Adjust the cusp.")
	return projected.Unit
end

local function prepareFrames(path)
	local result = { directions = {}, ups = {}, rolls = {} }
	for i, u in ipairs(path.parameters) do
		local chord = path.localPositions[math.min(i + 1, #path.positions)] - path.localPositions[math.max(1, i - 1)]
		if chord.Magnitude < 1e-7 then chord = path.localPositions[i] - path.localPositions[i - 1] end
		local direction = tangent(path, u, chord)
		local up
		if i == 1 then
			-- Keep the V1 initial reference; never switch world axes further along the path.
			local seed = if math.abs(direction:Dot(Vector3.yAxis)) > 0.98 then Vector3.zAxis else Vector3.yAxis
			up = (seed - direction * seed:Dot(direction)).Unit
		else up = transport(result.ups[i - 1], result.directions[i - 1], direction) end
		result.directions[i], result.ups[i] = direction, up
	end
	frames[path] = result
	if path.guides then
		for k, distance in ipairs(path.knots) do
			local i, t = interval(path, distance)
			local index = if t < 0.5 then i - 1 else i
			local direction, up = result.directions[index], result.ups[index]
			local guide = path.guides[k] - direction * path.guides[k]:Dot(direction)
			local previous = result.rolls[k - 1] or 0
			local angle = previous
			if guide.Magnitude > 1e-6 then
				guide = guide.Unit
				angle = math.atan2(direction:Dot(up:Cross(guide)), up:Dot(guide))
				angle = previous + (angle - previous + math.pi) % (2 * math.pi) - math.pi
			end
			result.rolls[k] = angle
		end
	end
	return result
end

function Curve.frame(path, distance)
	distance = math.clamp(distance, 0, path.length)
	local i, t = interval(path, distance)
	local data = frames[path] or prepareFrames(path)
	local u = path.parameters[i - 1] + (path.parameters[i] - path.parameters[i - 1]) * t
	local direction = tangent(path, u, path.localPositions[i] - path.localPositions[i - 1])
	local up = transport(data.ups[i - 1], data.directions[i - 1], direction)
	if path.guides then
		local k = 2
		while k < #path.knots and distance > path.knots[k] do k += 1 end
		local f = math.clamp((distance - path.knots[k - 1]) / (path.knots[k] - path.knots[k - 1]), 0, 1)
		f = f * f * (3 - 2 * f)
		local roll = data.rolls[k - 1] + (data.rolls[k] - data.rolls[k - 1]) * f
		up = CFrame.fromAxisAngle(direction, roll):VectorToWorldSpace(up)
	end
	local position = Curve.at(path, distance)
	return CFrame.fromMatrix(position, direction:Cross(up).Unit, up, -direction)
end

return Curve
