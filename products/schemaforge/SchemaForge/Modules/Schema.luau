local Schema = {}
Schema.classes = { "Instance", "Model", "BasePart", "Part", "MeshPart", "Folder", "Configuration", "Attachment", "ProximityPrompt", "ObjectValue", "StringValue", "NumberValue", "IntValue", "BoolValue", "ParticleEmitter", "Sound", "PointLight", "SpotLight", "SurfaceLight", "Beam", "Trail" }
Schema.kinds = { "number", "string", "boolean" }

local function text(v, max, empty)
	return type(v) == "string" and #v <= max and (empty or #v > 0) and not v:find("[%c]")
end
local function finite(v)
	return type(v) == "number" and v == v and math.abs(v) < math.huge
end
function Schema.copy(v)
	if type(v) ~= "table" then return v end
	local result = {}; for k, item in pairs(v) do result[k] = Schema.copy(item) end; return result
end
function Schema.new()
	return { version = 1, name = "New schema", tag = "", className = "Model", fields = {}, children = {} }
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
	return nil
end
local function array(v, limit)
	assert(type(v) == "table" and #v <= limit, "Too many rules or invalid list")
	local n = 0
	for k in pairs(v) do assert(type(k) == "number" and k % 1 == 0 and k >= 1 and k <= #v, "Invalid list"); n += 1 end
	assert(n == #v, "Invalid list")
end
function Schema.validate(s)
	assert(type(s) == "table" and s.version == 1, "Unsupported schema version")
	assert(text(s.name, 80, false), "Schema name: 1-80 characters, no line breaks")
	assert(text(s.tag, 100, false), "A target tag is required (1-100 characters)")
	assert(table.find(Schema.classes, s.className), "Unsupported expected class")
	array(s.fields, 32); array(s.children, 32)
	local names = {}
	for _, f in ipairs(s.fields) do
		assert(type(f) == "table" and text(f.name, 100, false) and f.name:match("^[%w_%.%-%/]+$") and f.name:sub(1, 3) ~= "RBX", "Invalid attribute name")
		assert(not names[f.name], "Duplicate attribute: " .. f.name); names[f.name] = true
		assert(table.find(Schema.kinds, f.kind), "Only number, string and boolean rules are supported")
		assert(type(f.required) == "boolean" and type(f.hasDefault) == "boolean", "Invalid rule flags")
		assert(text(f.description, 240, true), "Field description: at most 240 characters, one line")
		array(f.choices, 32)
		for _, choice in ipairs(f.choices) do assert(text(choice, 240, true), "Invalid string choice") end
		assert(type(f.integer) == "boolean", "Invalid integer flag")
		for _, key in ipairs({"min", "max"}) do assert(f[key] == nil or (f.kind == "number" and finite(f[key])), "Bounds must be finite numbers") end
		assert(not f.min or not f.max or f.min <= f.max, "Minimum exceeds maximum")
		assert(f.kind == "number" or not f.integer, "Integer applies to numbers only")
		assert(f.kind == "string" or #f.choices == 0, "Choices apply to strings only")
		if f.hasDefault then
			assert(not Schema.valueError(f, f.default), "Default violates rule: " .. f.name)
			assert(f.kind ~= "string" or text(f.default, 1000, true), "Default string: at most 1000 characters, one line")
		end
	end
	names = {}
	for _, c in ipairs(s.children) do
		assert(type(c) == "table" and text(c.path, 400, false), "Child path is required")
		assert(not names[c.path], "Duplicate child path"); names[c.path] = true
		local segments = string.split(c.path, "/")
		assert(#segments <= 8, "Child path: at most 8 levels")
		for _, segment in ipairs(segments) do assert(text(segment, 100, false), "Invalid child path segment") end
		assert(table.find(Schema.classes, c.className), "Unsupported child class")
		assert(text(c.description, 240, true), "Child description: at most 240 characters, one line")
	end
	return s
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
