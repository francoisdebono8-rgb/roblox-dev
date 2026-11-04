--!nocheck
-- Ninja Duel content factory: SNAPSHOT a hand-built set (Edit mode).
-- Run with execute_luau in the place that has the set; returns JSON that
-- Sets.luau can rebuild in any later build of the game. Static pieces are
-- copied property by property; a fighter Model is stored as its fighter id,
-- pivot and joint poses, so it is re-dressed with the CURRENT build's looks.
--
--   local snap = loadstring(<this file>)()     -- or paste, then:
--   return snap(workspace.TournamentSet, {skipModels = {"Shinobot"}})
local Http = game:GetService("HttpService")

local function v3(v) return {v.X, v.Y, v.Z} end
local function cf(c) return {c:GetComponents()} end
local function c3(c) return {c.R, c.G, c.B} end
local function u2(u) return {u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset} end
local function u1(u) return {u.Scale, u.Offset} end
local function e(x) return tostring(x) end -- "Enum.Material.Neon"
local function cseq(s) local t = {} for _, k in ipairs(s.Keypoints) do table.insert(t, {k.Time, k.Value.R, k.Value.G, k.Value.B}) end return t end
local function nseq(s) local t = {} for _, k in ipairs(s.Keypoints) do table.insert(t, {k.Time, k.Value, k.Envelope}) end return t end

local GUI = {"Size", "Position", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "Rotation", "ZIndex", "Visible", "ClipsDescendants", "LayoutOrder"}
local P = {
	Part = {"Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "Shape", "Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "Locked"},
	WedgePart = {"Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "Anchored", "CanCollide", "CastShadow"},
	SpecialMesh = {"MeshType", "Scale", "Offset", "MeshId", "TextureId", "VertexColor"},
	SurfaceGui = {"Face", "SizingMode", "PixelsPerStud", "CanvasSize", "LightInfluence", "Brightness", "AlwaysOnTop", "ZOffset", "ClipsDescendants"},
	Frame = GUI,
	CanvasGroup = table.move({"GroupColor3", "GroupTransparency"}, 1, 2, #GUI + 1, table.clone(GUI)),
	TextLabel = table.move({"Text", "FontFace", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
		"TextXAlignment", "TextYAlignment", "TextWrapped", "RichText"}, 1, 12, #GUI + 1, table.clone(GUI)),
	ImageLabel = table.move({"Image", "ImageColor3", "ImageTransparency", "ScaleType"}, 1, 4, #GUI + 1, table.clone(GUI)),
	UICorner = {"CornerRadius"},
	UIGradient = {"Color", "Transparency", "Rotation", "Offset", "Enabled"},
	UIStroke = {"Color", "Thickness", "Transparency", "ApplyStrokeMode", "LineJoinMode", "Enabled"},
	SpotLight = {"Brightness", "Range", "Angle", "Color", "Face", "Shadows", "Enabled"},
	PointLight = {"Brightness", "Range", "Color", "Shadows", "Enabled"},
	SurfaceLight = {"Brightness", "Range", "Angle", "Color", "Face", "Shadows", "Enabled"},
	Decal = {"Texture", "Face", "Color3", "Transparency"},
}

local function enc(val)
	local t = typeof(val)
	if t == "Vector3" then return {_t = "V3", v = v3(val)}
	elseif t == "CFrame" then return {_t = "CF", v = cf(val)}
	elseif t == "Color3" then return {_t = "C3", v = c3(val)}
	elseif t == "UDim2" then return {_t = "U2", v = u2(val)}
	elseif t == "UDim" then return {_t = "U1", v = u1(val)}
	elseif t == "Vector2" then return {_t = "V2", v = {val.X, val.Y}}
	elseif t == "EnumItem" then return {_t = "EN", v = e(val)}
	elseif t == "ColorSequence" then return {_t = "CS", v = cseq(val)}
	elseif t == "NumberSequence" then return {_t = "NS", v = nseq(val)}
	elseif t == "Font" then return {_t = "FO", v = {val.Family, val.Weight.Name, val.Style.Name}}
	elseif t == "string" or t == "number" or t == "boolean" then return val
	end
	return nil
end

local function node(inst, opts, stats)
	if inst:IsA("Model") then
		if opts.skipModels and table.find(opts.skipModels, inst.Name) then return nil end
		-- a fighter: id, pivot, joint poses; re-dressed by the current build
		local joints = {}
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("Motor6D") then joints[d.Name] = cf(d.C0) end
		end
		stats.models += 1
		local a = {}
		for k, v in pairs(inst:GetAttributes()) do a[k] = enc(v) end
		return {class = "Fighter", name = inst.Name, pivot = cf(inst:GetPivot()), joints = joints,
			scale = inst:GetScale(), attrs = a}
	end
	local list = P[inst.ClassName]
	if not list then stats.skipped[inst.ClassName] = (stats.skipped[inst.ClassName] or 0) + 1; return nil end
	local props = {}
	for _, k in ipairs(list) do
		local ok, v = pcall(function() return inst[k] end)
		if ok then props[k] = enc(v) end
	end
	local attrs = {}
	for k, v in pairs(inst:GetAttributes()) do attrs[k] = enc(v) end
	local kids = {}
	for _, c in ipairs(inst:GetChildren()) do
		local n = node(c, opts, stats)
		if n then table.insert(kids, n) end
	end
	stats.parts += 1
	return {class = inst.ClassName, name = inst.Name, props = props, attrs = next(attrs) and attrs or nil, kids = #kids > 0 and kids or nil}
end

return function(root, opts)
	opts = opts or {}
	local stats = {parts = 0, models = 0, skipped = {}}
	local kids = {}
	for _, c in ipairs(root:GetChildren()) do
		local n = node(c, opts, stats)
		if n then table.insert(kids, n) end
	end
	local snap = {name = root.Name, class = root.ClassName, parent = root.Parent and root.Parent:GetFullName(), kids = kids,
		attrs = (function() local a = {} for k, v in pairs(root:GetAttributes()) do a[k] = enc(v) end return a end)(), stats = stats}
	if root:IsA("BasePart") then snap.props = {} end
	return Http:JSONEncode(snap)
end
