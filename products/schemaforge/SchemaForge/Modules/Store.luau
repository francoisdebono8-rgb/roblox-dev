local Schema = require(script.Parent.Schema)
local Engine = require(script.Parent.Engine)
local Store = {}
local NAME = "_SchemaForgeSchemas"
local function folder()
	local matches = {}
	for _, child in ipairs(game.ServerStorage:GetChildren()) do if child.Name == NAME then table.insert(matches, child) end end
	assert(#matches <= 1, "Duplicate schema storage folders; resolve manually")
	local f = matches[1]
	assert(not f or (f:IsA("Folder") and f:GetAttribute("SchemaForgeVersion") == 1), "Schema storage name is occupied by unrelated content")
	return f
end
local function entry(f, name)
	local result
	if f then
		for _, c in ipairs(f:GetChildren()) do
			if c.Name == name then assert(not result and c:IsA("StringValue"), "Conflicting schema entry"); result = c end
		end
	end
	return result
end
function Store.list()
	local f, names = folder(), {}
	if f then
		local seen = {}
		for _, c in ipairs(f:GetChildren()) do
			assert(c:IsA("StringValue") and not seen[c.Name], "Conflicting schema entry")
			seen[c.Name] = true; table.insert(names, c.Name)
		end
	end
	table.sort(names); return names
end
function Store.load(name)
	local e = entry(folder(), name); assert(e, "Saved schema no longer exists")
	assert(#e.Value <= 64000, "Schema data is too large")
	local s = Schema.decode(e.Value)
	assert(s.name == name, "Stored schema name mismatch")
	Engine.registerStoredSchema(s, e)
	return s, e.Value
end
function Store.save(schema, expected, history)
	schema = Schema.current(schema)
	local value = Schema.encode(schema); assert(#value <= 64000, "Schema data is too large")
	local f = folder(); local e = entry(f, schema.name)
	assert((not e and expected == nil) or (e and e.Value == expected), "Saved schema changed or name already exists. Reload it before saving")
	local count = #Store.list(); assert(e or count < 32, "Project limit: 32 schemas")
	if e and e.Value == value then return value end
	local old = e and e.Value; local createdFolder, createdEntry, wrote
	Engine.transaction(history, "SchemaForge: save schema", function()
		assert(folder() == f and entry(f, schema.name) == e and (not e or e.Value == expected), "Saved schema changed while opening Undo recording")
		local currentCount = #Store.list(); assert(e or currentCount < 32, "Project limit: 32 schemas")
		if not f then f = Instance.new("Folder"); f.Name = NAME; f:SetAttribute("SchemaForgeVersion", 1); createdFolder = f; f.Parent = game.ServerStorage end
		if not e then e = Instance.new("StringValue"); e.Name = schema.name; createdEntry = e; e.Parent = f end
		wrote = true; e.Value = value
		assert(e.Value == value and e.Parent == f and f.Parent == game.ServerStorage, "Schema write did not persist")
	end, function()
		if createdFolder then createdFolder.Parent = nil elseif createdEntry then createdEntry.Parent = nil elseif wrote then e.Value = old end
	end)
	return value
end
function Store.delete(name, expected, history)
	Store.list()
	local f = folder(); local e = entry(f, name)
	assert(e and e.Value == expected, "Saved schema changed. Reload it before deleting")
	local wrote = false
	Engine.transaction(history, "SchemaForge: delete schema", function()
		assert(folder() == f and entry(f, name) == e and e.Value == expected, "Saved schema changed while opening Undo recording")
		wrote = true; e.Parent = nil
	end, function() if wrote then e.Parent = f end end)
end
return Store
