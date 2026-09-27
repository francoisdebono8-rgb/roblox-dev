local Curve = {}

function Curve.sample(points)
	assert(#points >= 2 and #points <= 8, "Use 2 to 8 ordered control points.")
	for i, p in ipairs(points) do
		assert(p.X == p.X and p.Y == p.Y and p.Z == p.Z and p.Magnitude < 100000, "Invalid control point position.")
		if i > 1 then assert((p - points[i - 1]).Magnitude >= 0.05, "Adjacent control points must be distinct.") end
	end
	local samples, lengths, total = { points[1] }, { 0 }, 0
	for i = 1, #points - 1 do
		local b, c = points[i], points[i + 1]
		local a, d = points[i - 1] or (2 * b - c), points[i + 2] or (2 * c - b)
		for step = 1, 64 do
			local t = step / 64
			local p = 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t)
			local distance = (p - samples[#samples]).Magnitude
			if distance > 1e-6 then
				total += distance; table.insert(samples, p); table.insert(lengths, total)
			end
		end
	end
	assert(total > 0.05 and total < 10000, "Path length must be between 0.05 and 10000 studs.")
	return { positions = samples, lengths = lengths, length = total }
end

function Curve.at(path, distance)
	distance = math.clamp(distance, 0, path.length)
	local low, high = 2, #path.lengths
	while low < high do
		local mid = math.floor((low + high) / 2)
		if path.lengths[mid] < distance then low = mid + 1 else high = mid end
	end
	local a, b = path.positions[low - 1], path.positions[low]
	return a:Lerp(b, (distance - path.lengths[low - 1]) / (path.lengths[low] - path.lengths[low - 1]))
end

function Curve.frame(path, distance)
	local position = Curve.at(path, distance)
	local direction = (Curve.at(path, math.min(path.length, distance + 0.02)) - Curve.at(path, math.max(0, distance - 0.02))).Unit
	local up = if math.abs(direction:Dot(Vector3.yAxis)) > 0.98 then Vector3.zAxis else Vector3.yAxis
	return CFrame.lookAt(position, position + direction, up)
end

return Curve
