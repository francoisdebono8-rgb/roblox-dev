-- Pure path math only: this does not replace the Studio engine suite.
local Curve = require("../CurveForge/Modules/Curve")
local V = {}
local mt = {}
function V.new(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, mt) end
mt.__add = function(a, b) return V.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
mt.__sub = function(a, b) return V.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
mt.__unm = function(a) return V.new(-a.X, -a.Y, -a.Z) end
mt.__mul = function(a, b) if type(a) == "number" then a, b = b, a end; return V.new(a.X * b, a.Y * b, a.Z * b) end
mt.__index = function(a, key)
	if key == "Magnitude" then return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z) end
	if key == "Lerp" then return function(self, b, t) return self + (b - self) * t end end
end
local function near(a, b) assert((a - b).Magnitude < 1e-4) end
local straight = Curve.sample({ V.new(0, 0, 0), V.new(20, 0, 0) })
assert(math.abs(straight.length - 20) < 1e-5)
for d = 0, 20 do near(Curve.at(straight, d), V.new(d, 0, 0)) end
print("PASS straight path / arc-length positions")
for _, points in ipairs({
	{ V.new(0, 0, 0), V.new(5, 8, 0), V.new(12, 2, 4), V.new(20, 4, 0) },
	{ V.new(0, 0, 0), V.new(0, 10, 0), V.new(8, 15, 7), V.new(10, 20, 2) },
}) do
	local path = Curve.sample(points)
	near(Curve.at(path, 0), points[1]); near(Curve.at(path, path.length), points[#points])
	for _, point in ipairs(points) do
		local found = false; for _, position in ipairs(path.positions) do if (position - point).Magnitude < 1e-4 then found = true end end; assert(found)
	end
	for i = 2, #path.lengths do assert(path.lengths[i] > path.lengths[i - 1]) end
end
print("PASS curved / vertical / 3D interpolation and monotonic distance")
assert(not pcall(Curve.sample, { V.new(0, 0, 0), V.new(0, 0, 0) }))
assert(not pcall(Curve.sample, { V.new(0/0, 0, 0), V.new(10, 0, 0) }))
assert(not pcall(Curve.sample, { V.new(0, 0, 0) }))
assert(not pcall(Curve.sample, { V.new(0, 0, 0), V.new(math.huge, 0, 0) }))
print("PASS invalid / duplicate / nonfinite controls")
