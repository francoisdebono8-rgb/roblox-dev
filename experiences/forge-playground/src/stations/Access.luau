local Root = script.Parent.Parent
local V = require(Root.Visuals)
local W = require(Root.World)
local Geometry = require(Root.ProductModules.Access.Geometry)
local Settings = require(Root.ProductModules.Access.Settings)
local Access = {}; Access.__index = Access
local destinations = { "Straight", "Switchback", "Catwalk", "Invalid" }
local points = { Straight = Vector3.new(-7, 8.5, -12), Switchback = Vector3.new(1, 10.5, 9), Catwalk = Vector3.new(16, 0.5, 9), Invalid = Vector3.new(-7, 0.5, 9) }
function Access.new(station)
	local self = setmetatable({ station = station }, Access); self:reset(); return self
end
function Access:reset()
	self:leave(); self.station.contents:ClearAllChildren(); self.started = false
	local s = self.station
	self.start = V.part(s, s.contents, "Start", Vector3.new(6, 0.5, 6), Vector3.new(-7, 0.25, 12), Color3.fromRGB(86, 219, 176))
	V.pick(self.start, "access", 1)
	W.sign(s.contents, "START", self.start.Position + Vector3.new(0, 2, 2), 6)
	self.ends = {}
	for index, name in ipairs(destinations) do
		local p = points[name]
		local platform = V.part(s, s.contents, name, Vector3.new(6, 0.5, 4), p + Vector3.new(0, -0.25, -2), name == "Invalid" and Color3.fromRGB(225, 103, 104) or Color3.fromRGB(188, 182, 91))
		V.pick(platform, "access", index + 1); self.ends[name] = platform
		W.sign(s.contents, name, platform.Position + Vector3.new(0, 2.1, -1), 8)
		if p.Y > 2 then V.part(s, s.contents, name .. "Support", Vector3.new(0.7, p.Y, 0.7), Vector3.new(p.X, p.Y / 2, p.Z - 2), Color3.fromRGB(104, 112, 119)) end
	end
	self.summary, self.message = "4 destinations / 3 valid layouts", "Select the green START platform."
end
function Access:leave() self.plan = nil; V.clear(self.station, "Preview") end
function Access:inputs(options)
	local settings = table.clone(Settings.defaults)
	settings.Mode = options.endpoint == "Invalid" and "Straight" or options.endpoint
	settings.Width, settings.TreadDepth = 5, 1.5
	settings.RailLeft, settings.RailRight = options.rails, options.rails
	settings.Landing, settings.LandingDepth = false, 4
	local a = self.station.center + Vector3.new(-7, 0.5, 9)
	return a, self.station.center + points[options.endpoint], settings
end
function Access:preview(options)
	self:leave()
	if not self.started then self.message = "Select START first."; return end
	local a, b, settings = self:inputs(options)
	local ok, plan = pcall(Geometry.plan, a, b, settings)
	if not ok then self.summary, self.message = "No build / invalid destination", V.message(plan); return end
	self.plan = plan; V.ghost(self.station, V.parts(plan.parts))
	self.summary = string.format("%d steps / %d parts\nRise %.1f / run %.1f studs", plan.steps, plan.count, plan.rise, plan.run)
	self.message = "Geometry.plan / valid preview"
end
function Access:handle(action, options, index)
	if action == "pick" then
		if index == 1 then self.started = true; self.message = "START selected. Choose a destination."
		elseif destinations[index - 1] then options.endpoint = destinations[index - 1]; self:preview(options) end
	elseif action == "run" then
		if not self.started then self.started = true; self.message = "START selected. Choose a destination." else self:preview(options) end
	elseif action == "configure" then self:preview(options)
	elseif action == "apply" then
		assert(self.plan, "Choose a valid destination first.")
		local a, b, settings = self:inputs(options)
		local fresh = Geometry.plan(a, b, settings)
		V.commit(self.station, V.parts(fresh.parts)); self.plan = nil; self.message = "Built / solid walkable Parts"
	end
end
function Access:state(options)
	return { summary = self.summary, message = self.message, rows = {}, canApply = self.plan ~= nil,
		runLabel = self.started and "Preview" or "Select START", primary = self.started and "Build" or "Select START",
		focus = self.started and self.ends[options.endpoint] or self.start }
end
return Access
