local Schema = {}
Schema.classes = { "Instance", "Model", "BasePart", "Part", "MeshPart", "Folder", "Configuration", "Attachment", "ProximityPrompt", "ObjectValue", "StringValue", "NumberValue", "IntValue", "BoolValue", "ParticleEmitter", "Sound", "PointLight", "SpotLight", "SurfaceLight", "Beam", "Trail" }
Schema.version = 2
Schema.kinds = { "number", "string", "boolean", "Vector2", "Vector3", "Color3", "CFrame", "UDim", "UDim2", "BrickColor", "NumberRange" }
local widths = { Vector2 = 2, Vector3 = 3, Color3 = 3, CFrame = 12, UDim = 2, UDim2 = 4, BrickColor = 1, NumberRange = 2 }

local function text(v, max, empty)
	return type(v) == "string" and #v <= max and (empty or #v > 0) and not v:find("[%c]")
end
local function finite(v)
	return type(v) == "number" and v == v and math.abs(v) < math.huge
end
function Schema.copy(v)
	local active, count = {}, 0
	local function copy(value, depth)
		if type(value) ~= "table" then return value end
		assert(depth <= 32 and not active[value], "Cyclic or deeply nested data")
		active[value] = true
		local result = {}
		for k, item in pairs(value) do
			count += 1; assert(count <= 100000, "Data exceeds copy limit")
			result[k] = copy(item, depth + 1)
		end
		active[value] = nil; return result
	end
	return copy(v, 1)
end
function Schema.new()
	return { version = Schema.version, name = "New schema", tag = "", className = "Model", fields = {}, children = {}, requiredTags = {}, forbiddenTags = {} }
end
function Schema.current(s)
	Schema.validate(s)
	local result = Schema.copy(s); result.version = Schema.version
	result.requiredTags = result.requiredTags or {}; result.forbiddenTags = result.forbiddenTags or {}
	return result
end
function Schema.components(value)
	local kind = typeof(value)
	if kind == "Vector2" then return {value.X, value.Y}
	elseif kind == "Vector3" then return {value.X, value.Y, value.Z}
	elseif kind == "Color3" then return {value.R, value.G, value.B}
	elseif kind == "CFrame" then return {value:GetComponents()}
	elseif kind == "UDim" then return {value.Scale, value.Offset}
	elseif kind == "UDim2" then return {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}
	elseif kind == "BrickColor" then return {value.Number}
	elseif kind == "NumberRange" then return {value.Min, value.Max} end
	return nil
end
local function construct(kind, c)
	if kind == "Vector2" then return Vector2.new(c[1], c[2])
	elseif kind == "Vector3" then return Vector3.new(c[1], c[2], c[3])
	elseif kind == "Color3" then return Color3.new(c[1], c[2], c[3])
	elseif kind == "CFrame" then return CFrame.new(table.unpack(c))
	elseif kind == "UDim" then return UDim.new(c[1], c[2])
	elseif kind == "UDim2" then return UDim2.new(c[1], c[2], c[3], c[4])
	elseif kind == "BrickColor" then
		local value = BrickColor.new(c[1]); assert(value.Number == c[1], "Invalid BrickColor number"); return value
	elseif kind == "NumberRange" then assert(c[1] <= c[2], "NumberRange minimum exceeds maximum"); return NumberRange.new(c[1], c[2]) end
	error("Unsupported datatype")
end
function Schema.equalValue(a, b)
	if typeof(a) ~= typeof(b) then return false end
	local ac, bc = Schema.components(a), Schema.components(b)
	if not ac then return a == b end
	for i, value in ipairs(ac) do if value ~= bc[i] then return false end end
	return true
end
function Schema.formatValue(value)
	local c = Schema.components(value)
	if not c then return typeof(value) == "string" and string.format("%q", value) or tostring(value) end
	local parts = {}; for _, n in ipairs(c) do table.insert(parts, string.format("%.17g", n)) end
	return typeof(value) .. "(" .. table.concat(parts, ", ") .. ")"
end
function Schema.initialValue(kind)
	if kind == "number" then return 0 elseif kind == "string" then return "" elseif kind == "boolean" then return false end
	local c = table.create(widths[kind], 0)
	if kind == "CFrame" then c[4] = 1; c[8] = 1; c[12] = 1 end
	if kind == "BrickColor" then c[1] = 1 end
	return construct(kind, c)
end
function Schema.parseValue(kind, input)
	if kind == "string" then return input elseif kind == "number" then return tonumber(input) or input end
	assert(widths[kind], "Use a boolean control")
	local parts = string.split(input, ","); assert(#parts == widths[kind], "Expected " .. widths[kind] .. " numeric components")
	local c = {}; for _, part in ipairs(parts) do local n = tonumber(part); assert(finite(n), "Components must be finite"); table.insert(c, n) end
	local value = construct(kind, c)
	for _, n in ipairs(Schema.components(value)) do assert(finite(n), "Components overflow datatype") end
	return value
end
function Schema.editValue(value)
	local c = Schema.components(value)
	if not c then return value end
	local parts = {}; for _, n in ipairs(c) do table.insert(parts, string.format("%.17g", n)) end
	return table.concat(parts, ", ")
end
function Schema.valueError(rule, value)
	if typeof(value) ~= rule.kind then return "Expected " .. rule.kind .. "; found " .. typeof(value) end
	if rule.kind == "number" then
		if not finite(value) then return "Must be finite" end
		if rule.min ~= nil and value < rule.min then return "Below minimum " .. tostring(rule.min) end
		if rule.max ~= nil and value > rule.max then return "Above maximum " .. tostring(rule.max) end
		if rule.integer and value % 1 ~= 0 then return "Must be an integer" end
	elseif rule.kind == "string" and #rule.choices > 0 and not table.find(rule.choices, value) then
		return "Expected one of: " .. table.concat(rule.choices, ", ")
	end
	local components = Schema.components(value)
	if components then
		for _, n in ipairs(components) do if not finite(n) then return "Components must be finite" end end
		if rule.exact ~= nil and not Schema.equalValue(value, rule.exact) then return "Expected exactly " .. Schema.formatValue(rule.exact) end
	end
	if rule.kind == "Vector2" or rule.kind == "Vector3" then
		for _, axis in ipairs(rule.kind == "Vector2" and {"X", "Y"} or {"X", "Y", "Z"}) do
			if rule.axisMin and rule.axisMin[axis] and value[axis] < rule.axisMin[axis] then return axis .. " below minimum " .. rule.axisMin[axis] end
			if rule.axisMax and rule.axisMax[axis] and value[axis] > rule.axisMax[axis] then return axis .. " above maximum " .. rule.axisMax[axis] end
		end
		local magnitude = value.Magnitude
		if rule.magnitudeMin and magnitude < rule.magnitudeMin then return "Magnitude below minimum " .. rule.magnitudeMin end
		if rule.magnitudeMax and magnitude > rule.magnitudeMax then return "Magnitude above maximum " .. rule.magnitudeMax end
	end
	return nil
end
local function array(v, limit)
	assert(type(v) == "table" and #v <= limit, "Too many rules or invalid list")
	local n = 0
	for k in pairs(v) do assert(type(k) == "number" and k % 1 == 0 and k >= 1 and k <= #v, "Invalid list"); n += 1 end
	assert(n == #v, "Invalid list")
end
local function bounded(value)
	local active, count, bytes = {}, 0, 0
	local function visit(v, depth)
		if type(v) == "table" then
			assert(depth <= 16 and not active[v], "Cyclic or deeply nested schema")
			active[v] = true
			for key, item in pairs(v) do
				count += 1; assert(count <= 4096, "Schema exceeds data limit")
				assert(type(key) == "string" or (finite(key) and key % 1 == 0), "Invalid schema key")
				visit(key, depth + 1); visit(item, depth + 1)
			end
			active[v] = nil
		elseif type(v) == "string" then bytes += #v; assert(bytes <= 64000, "Schema data is too large")
		elseif type(v) == "number" then assert(finite(v), "Schema numbers must be finite")
		else assert(type(v) == "boolean" or widths[typeof(v)], "Unsupported schema data") end
	end
	visit(value, 1)
end
local function keys(value, allowed)
	for key in pairs(value) do assert(table.find(allowed, key), "Unknown schema key: " .. tostring(key)) end
end
function Schema.validate(s)
	bounded(s)
	assert(type(s) == "table" and (s.version == 1 or s.version == Schema.version), "Unsupported schema version")
	keys(s, {"version", "name", "tag", "className", "fields", "children", "requiredTags", "forbiddenTags"})
	if s.version == 1 then assert(s.requiredTags == nil and s.forbiddenTags == nil, "Tag rules require schema format 2") end
	assert(text(s.name, 80, false), "Schema name: 1-80 characters, no line breaks")
	assert(text(s.tag, 100, false), "A target tag is required (1-100 characters)")
	assert(table.find(Schema.classes, s.className), "Unsupported expected class")
	array(s.fields, 32); array(s.children, 32)
	local names = {}
	for _, f in ipairs(s.fields) do
		assert(type(f) == "table" and text(f.name, 100, false) and f.name:match("^[%w_%.%-%/]+$") and f.name:sub(1, 3) ~= "RBX", "Invalid attribute name")
		keys(f, {"name", "kind", "required", "hasDefault", "default", "integer", "choices", "description", "min", "max", "exact", "axisMin", "axisMax", "magnitudeMin", "magnitudeMax"})
		if s.version == 1 then
			for _, key in ipairs({"exact", "axisMin", "axisMax", "magnitudeMin", "magnitudeMax"}) do assert(f[key] == nil, "Typed constraints require schema format 2") end
		end
		assert(not names[f.name], "Duplicate attribute: " .. f.name); names[f.name] = true
		assert(table.find(Schema.kinds, f.kind) and (s.version == Schema.version or not widths[f.kind]), "Unsupported attribute kind for schema version")
		assert(type(f.required) == "boolean" and type(f.hasDefault) == "boolean", "Invalid rule flags")
		assert(text(f.description, 240, true), "Field description: at most 240 characters, one line")
		array(f.choices, 32)
		for _, choice in ipairs(f.choices) do assert(text(choice, 240, true), "Invalid string choice") end
		assert(type(f.integer) == "boolean", "Invalid integer flag")
		for _, key in ipairs({"min", "max"}) do assert(f[key] == nil or (f.kind == "number" and finite(f[key])), "Bounds must be finite numbers") end
		assert(not f.min or not f.max or f.min <= f.max, "Minimum exceeds maximum")
		assert(f.kind == "number" or not f.integer, "Integer applies to numbers only")
		assert(f.kind == "string" or #f.choices == 0, "Choices apply to strings only")
		local vector = f.kind == "Vector2" or f.kind == "Vector3"
		for _, key in ipairs({"axisMin", "axisMax"}) do
			if f[key] ~= nil then
				assert(vector and type(f[key]) == "table", "Axis bounds apply to vectors only")
				for axis, value in pairs(f[key]) do
					assert((axis == "X" or axis == "Y" or (axis == "Z" and f.kind == "Vector3")) and finite(value), "Invalid axis bound")
					assert(not f.axisMin or not f.axisMax or not f.axisMin[axis] or not f.axisMax[axis] or f.axisMin[axis] <= f.axisMax[axis], "Axis minimum exceeds maximum")
				end
			end
		end
		for _, key in ipairs({"magnitudeMin", "magnitudeMax"}) do assert(f[key] == nil or (vector and finite(f[key]) and f[key] >= 0), "Magnitude bounds must be finite and nonnegative") end
		assert(not f.magnitudeMin or not f.magnitudeMax or f.magnitudeMin <= f.magnitudeMax, "Magnitude minimum exceeds maximum")
		if f.exact ~= nil then
			assert(widths[f.kind] and typeof(f.exact) == f.kind, "Exact value must match a supported non-scalar kind")
			assert(not Schema.valueError(f, f.exact), "Exact value violates bounds")
		end
		if widths[f.kind] and f.default ~= nil then
			assert(typeof(f.default) == f.kind, "Invalid typed default")
			for _, value in ipairs(Schema.components(f.default)) do assert(finite(value), "Default components must be finite") end
		end
		if f.hasDefault then
			assert(not Schema.valueError(f, f.default), "Default violates rule: " .. f.name)
			assert(f.kind ~= "string" or text(f.default, 1000, true), "Default string: at most 1000 characters, one line")
		end
	end
	names = {}
	for _, c in ipairs(s.children) do
		assert(type(c) == "table" and text(c.path, 400, false), "Child path is required")
		keys(c, {"path", "className", "description", "optional"})
		if s.version == 1 then assert(c.optional == nil, "Optional children require schema format 2") end
		assert(not names[c.path], "Duplicate child path"); names[c.path] = true
		local segments = string.split(c.path, "/")
		assert(#segments <= 8, "Child path: at most 8 levels")
		for _, segment in ipairs(segments) do assert(text(segment, 100, false), "Invalid child path segment") end
		assert(table.find(Schema.classes, c.className), "Unsupported child class")
		assert(text(c.description, 240, true), "Child description: at most 240 characters, one line")
		assert(c.optional == nil or type(c.optional) == "boolean", "Invalid optional child flag")
	end
	local tags = {[s.tag] = true}
	for _, key in ipairs({"requiredTags", "forbiddenTags"}) do
		if s[key] ~= nil then
			array(s[key], 16)
			for _, tag in ipairs(s[key]) do
				assert(text(tag, 100, false) and tag:match("%S") and not tags[tag], "Invalid, duplicate or conflicting tag rule")
				tags[tag] = true
			end
		end
	end
	return s
end
-- Component strings retain every native bit even if JSON's number formatter changes.
local function encodeValue(value)
	local c = Schema.components(value)
	if not c then return value end
	local parts = {}; for _, n in ipairs(c) do assert(finite(n), "Non-finite component"); table.insert(parts, string.format("%.17g", n)) end
	return {kind = typeof(value), components = parts}
end
local function decodeValue(value, kind)
	assert(type(value) == "table" and value.kind == kind and widths[kind], "Invalid typed encoding")
	for key in pairs(value) do assert(key == "kind" or key == "components", "Unknown typed encoding key") end
	array(value.components, widths[kind]); assert(#value.components == widths[kind], "Wrong component count")
	local c = {}
	for _, part in ipairs(value.components) do
		assert(type(part) == "string" and #part <= 32, "Components must be numeric strings")
		local n = tonumber(part); assert(finite(n), "Invalid numeric component"); table.insert(c, n)
	end
	local result = construct(kind, c)
	for i, n in ipairs(Schema.components(result)) do assert(n == c[i], "Lossy or out-of-range typed encoding") end
	return result
end
function Schema.encode(s)
	local value = Schema.current(s)
	for _, field in ipairs(value.fields) do
		if widths[field.kind] then
			if field.default ~= nil then field.default = encodeValue(field.default) end
			if field.exact ~= nil then field.exact = encodeValue(field.exact) end
		end
	end
	return game:GetService("HttpService"):JSONEncode(value)
end
function Schema.decode(encoded)
	assert(type(encoded) == "string" and #encoded <= 64000, "Schema data is too large")
	local value = game:GetService("HttpService"):JSONDecode(encoded)
	bounded(value)
	assert(type(value) == "table" and (value.version == 1 or value.version == Schema.version), "Unsupported schema version")
	array(value.fields, 32)
	if value.version == Schema.version then
		for _, field in ipairs(value.fields) do
			assert(type(field) == "table", "Invalid field")
			if widths[field.kind] then
				if field.default ~= nil then field.default = decodeValue(field.default, field.kind) end
				if field.exact ~= nil then field.exact = decodeValue(field.exact, field.kind) end
			end
		end
	end
	return Schema.validate(value)
end
function Schema.capture(instance)
	assert(typeof(instance) == "Instance", "Select one reference object")
	local s, skipped = Schema.new(), 0
	s.name = instance.Name; s.className = table.find(Schema.classes, instance.ClassName) and instance.ClassName or "Instance"
	local tags = instance:GetTags(); table.sort(tags); s.tag = tags[1] or ""
	for name, value in pairs(instance:GetAttributes()) do
		if table.find(Schema.kinds, typeof(value)) and name:sub(1, 3) ~= "RBX" then
			table.insert(s.fields, { name = name, kind = typeof(value), required = true, hasDefault = false, default = value, integer = false, choices = {}, description = "" })
		else skipped += 1 end
	end
	table.sort(s.fields, function(a, b) return a.name < b.name end)
	assert(#s.fields <= 32, "Reference has more than 32 supported attributes")
	return s, skipped
end
return Schema
