local Root = script.Parent.Parent
local V = require(Root.Visuals)
local W = require(Root.World)
local Engine = require(Root.ProductModules.Curve.Engine)
local Settings = require(Root.ProductModules.Curve.Settings)
local Curve = {}; Curve.__index = Curve
local base = { Vector3.new(-16, 2, 3), Vector3.new(-6, 2, -9), Vector3.new(6, 2, -9), Vector3.new(16, 2, 3) }
function Curve.new(station)
	local self = setmetatable({ station = station }, Curve); self:reset(); return self
end
function Curve:leave() self.plan = nil; V.clear(self.station, "Preview") end
function Curve:reset()
	self:leave(); self.station.contents:ClearAllChildren(); self.offsets = { 0, 0, 0, 0 }; self.controls = {}
	local s = self.station
	for index, position in ipairs(base) do
		local p = V.part(s, s.contents, "Point" .. index, Vector3.one * 1.6, position, Color3.fromRGB(112, 194, 255), Enum.Material.Neon)
		p.Shape, p.CanCollide = Enum.PartType.Ball, false
		V.pick(p, "curve", index); self.controls[index] = p
		W.sign(s.contents, tostring(index), p.Position + Vector3.new(0, 2, 0), 2)
	end
	self.source = V.folder(s.contents, "BollardSource", "Model")
	local stem = V.part(s, self.source, "Post", Vector3.new(0.65, 2.6, 0.65), Vector3.new(-18, 1.5, 12), Color3.fromRGB(143, 153, 166), Enum.Material.Metal)
	V.part(s, self.source, "Lamp", Vector3.new(1, 0.6, 1), Vector3.new(-18, 2.8, 12), Color3.fromRGB(242, 224, 163), Enum.Material.Neon)
	self.source.PrimaryPart = stem
	W.sign(s.contents, "SOURCE", stem.Position + Vector3.new(0, 3, 0), 6)
	self.summary, self.message = "4 ordered points / editable path", "Change a control point or output mode."
end
function Curve:settings(options)
	local settings = table.clone(Settings.defaults)
	settings.Mode, settings.Count, settings.Distribution = options.mode, options.count, "Count"
	settings.Color, settings.Material, settings.SegmentLength = Color3.fromRGB(129, 208, 250), "Metal", 1.5
	settings.PreserveRotation = false
	return settings
end
function Curve:preview(options)
	self:leave()
	self.plan = Engine.plan(self.controls, self:settings(options), self.source)
	V.ghost(self.station, Engine.output(self.plan))
	local metrics = self.plan.estimates
	self.summary = string.format("%.1f studs / %d %s\n%d adaptive samples", metrics.pathLength,
		options.mode == "Cable" and metrics.segmentCount or metrics.copyCount,
		options.mode == "Cable" and "segments" or "copies", metrics.sampleCount)
	self.message = "Engine.plan + Engine.output / real placement"
end
function Curve:handle(action, options, index)
	if action == "pick" and self.controls[index] then options.point = tostring(index); options.offset = self.offsets[index]
	elseif action == "configure" then
		local point = tonumber(options.point)
		self.offsets[point] = options.offset
		self.controls[point].Position = self.station.center + base[point] + Vector3.new(0, 0, options.offset)
		self:preview(options)
	elseif action == "run" then self:preview(options)
	elseif action == "apply" then
		assert(self.plan, "Preview first."); Engine.check(self.plan)
		V.commit(self.station, Engine.output(self.plan)); self.plan.used = true; self.plan = nil
		self.message = "Generated / change a point to regenerate"
	end
end
function Curve:state(options)
	return { summary = self.summary, message = self.message, rows = {}, canApply = self.plan ~= nil, focus = self.controls[tonumber(options.point)] }
end
return Curve
