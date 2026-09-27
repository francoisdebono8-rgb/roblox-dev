local Schema = require(script.Parent.Schema)
local Engine = require(script.Parent.Engine)
local Store = require(script.Parent.Store)
local View = {}
local C = { bg = Color3.fromRGB(29, 32, 33), field = Color3.fromRGB(47, 53, 54), text = Color3.fromRGB(238, 243, 242), muted = Color3.fromRGB(171, 187, 184), accent = Color3.fromRGB(103, 221, 180), error = Color3.fromRGB(255, 150, 136) }
local function make(class, parent, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent; return obj
end
local function stack(parent, gap)
	make("UIListLayout", parent, { Padding = UDim.new(0, gap or 7), SortOrder = Enum.SortOrder.LayoutOrder })
end
local function label(parent, text, height, color)
	return make("TextLabel", parent, { Text = text, Size = UDim2.new(1, -4, 0, height or 24), BackgroundTransparency = 1, TextColor3 = color or C.text, Font = Enum.Font.SourceSans, TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left })
end
local function row(parent, count, height)
	local f = make("Frame", parent, { Size = UDim2.new(1, -4, 0, height or 32), BackgroundTransparency = 1 })
	make("UIGridLayout", f, { CellSize = UDim2.new(1 / count, -5, 1, 0), CellPadding = UDim2.fromOffset(5, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	return f
end
function View.mount(widget, selection, history)
	local state = { schema = Schema.new(), tab = "Rules", scope = "Selection", fieldIndex = 1, childIndex = 1, page = 1, message = "", dirty = false }
	local disposed, rendering = false, false
	local render
	local shell = make("ScrollingFrame", widget, { Name = "SchemaForgeScroll", Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, BackgroundColor3 = C.bg, BorderSizePixel = 0, ScrollBarThickness = 4 })
	local root = make("Frame", shell, { Name = "SchemaForgeUI", BackgroundColor3 = C.bg, BorderSizePixel = 0 })
	local function resize() root.Size = UDim2.fromOffset(math.max(376, shell.AbsoluteSize.X - 4), math.max(650, shell.AbsoluteSize.Y)) end
	local resized = shell:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); resize()
	local function invalidate() state.audit = nil; state.plan = nil; state.page = 1 end
	local function changed() state.dirty = true; invalidate() end
	local function act(fn)
		return function()
			if disposed or rendering then return end
			state.failed = false; state.message = ""
			local ok, err = pcall(fn)
			if not ok then state.failed = true; state.message = tostring(err):gsub("^.-:%d+: ", "") end
			render()
		end
	end
	local function button(parent, name, text, fn, active)
		local b = make("TextButton", parent, { Name = name, Text = text, Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = active and C.accent or C.field, BorderSizePixel = 0, TextColor3 = active and C.bg or C.text, TextSize = 16, Font = Enum.Font.SourceSansSemibold, TextTruncate = Enum.TextTruncate.AtEnd })
		b.Activated:Connect(act(fn)); return b
	end
	local function input(parent, name, title, value, setter)
		label(parent, title, 19, C.muted)
		local box = make("TextBox", parent, { Name = name, Text = value == nil and "" or tostring(value), Size = UDim2.new(1, -4, 0, 30), ClearTextOnFocus = false, TextColor3 = C.text, BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left })
		make("UIPadding", box, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if rendering then return end
			local ok, err = pcall(function() setter(box.Text); changed() end)
			if not ok then state.message = tostring(err); state.failed = true; invalidate() end
		end)
		return box
	end
	local function toggle(parent, name, title, value, setter)
		button(parent, name, (value and "[x]  " or "[ ]  ") .. title, function() setter(not value); changed() end)
	end
	local function menu(parent, name, title, options, value, setter)
		button(parent, name, title .. ": " .. tostring(value) .. "  v", function() state.menu = state.menu == name and nil or name end)
		if state.menu == name then
			local scroll = make("ScrollingFrame", parent, { Name = name .. "Options", Size = UDim2.new(1, -4, 0, math.min(170, #options * 36)), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4 }); stack(scroll, 4)
			for _, choice in ipairs(options) do
				button(scroll, name .. choice, choice, function() state.menu = nil; setter(choice) end, choice == value)
			end
		end
	end
	local function confirm(title, fn)
		state.confirm = { title = title, fn = fn }
	end
	local function loadDraft(s, token)
		state.schema = s; state.token = token; state.loadedName = token and s.name or nil
		state.dirty = false; state.fieldIndex = 1; state.childIndex = 1; state.menu = nil; invalidate()
	end
	local function replaceDraft(fn)
		if state.dirty then confirm("Discard unsaved schema edits?", fn) else fn() end
	end
	local function audit()
		local roots = state.scope == "Workspace" and {workspace} or selection:Get()
		state.audit = Engine.audit(state.schema, roots); state.plan = nil; state.page = 1
		state.message = state.audit.matched == 0 and "No objects matched the target tag." or "Audit complete. Project unchanged."
	end
	local function rules(body)
		input(body, "SchemaName", "Schema name", state.schema.name, function(v) state.schema.name = v end)
		input(body, "TargetTag", "Target tag (exact)", state.schema.tag, function(v) state.schema.tag = v end)
		menu(body, "ExpectedClass", "Expected class", Schema.classes, state.schema.className, function(v) state.schema.className = v; changed() end)
		local modes = row(body, 2)
		button(modes, "AttributesMode", "Attributes (" .. #state.schema.fields .. ")", function() state.childMode = false end, not state.childMode)
		button(modes, "ChildrenMode", "Children (" .. #state.schema.children .. ")", function() state.childMode = true end, state.childMode)
		if state.childMode then
			local names = {}; for _, c in ipairs(state.schema.children) do table.insert(names, c.path) end
			if #names > 0 then menu(body, "ChildPicker", "Child", names, names[state.childIndex], function(v) state.childIndex = table.find(names, v) end) end
			button(body, "AddChild", "+ Add required child", function()
				assert(#state.schema.children < 32, "Limit: 32 child rules")
				table.insert(state.schema.children, { path = "Child" .. (#state.schema.children + 1), className = "Instance", description = "" }); state.childIndex = #state.schema.children; changed()
			end)
			local c = state.schema.children[state.childIndex]
			if c then
				input(body, "ChildPath", "Child path / nested child", c.path, function(v) c.path = v end)
				menu(body, "ChildClass", "Class", Schema.classes, c.className, function(v) c.className = v; changed() end)
				input(body, "ChildDescription", "Description", c.description, function(v) c.description = v end)
				button(body, "RemoveChild", "Remove child rule", function() table.remove(state.schema.children, state.childIndex); state.childIndex = math.max(1, state.childIndex - 1); changed() end)
			end
		else
			local names = {}; for _, f in ipairs(state.schema.fields) do table.insert(names, f.name) end
			if #names > 0 then menu(body, "FieldPicker", "Field", names, names[state.fieldIndex], function(v) state.fieldIndex = table.find(names, v) end) end
			button(body, "AddField", "+ Add attribute rule", function()
				assert(#state.schema.fields < 32, "Limit: 32 attribute rules")
				table.insert(state.schema.fields, { name = "Attribute" .. (#state.schema.fields + 1), kind = "number", required = true, hasDefault = false, default = 0, integer = false, choices = {}, description = "" }); state.fieldIndex = #state.schema.fields; changed()
			end)
			local f = state.schema.fields[state.fieldIndex]
			if f then
				input(body, "FieldName", "Attribute name", f.name, function(v) f.name = v end)
				menu(body, "FieldType", "Type", Schema.kinds, f.kind, function(v)
					f.kind = v; f.min = nil; f.max = nil; f.integer = false; f.choices = {}; f.hasDefault = false; f.default = v == "number" and 0 or v == "string" and "" or false; changed()
				end)
				input(body, "FieldDescription", "Designer note", f.description, function(v) f.description = v end)
				toggle(body, "Required", "Required", f.required, function(v) f.required = v end)
				if f.kind == "number" then
					local bounds = row(body, 2, 56)
					for _, key in ipairs({"min", "max"}) do
						local cell = make("Frame", bounds, { BackgroundTransparency = 1 }); stack(cell, 3)
						input(cell, key, key == "min" and "Minimum (optional)" or "Maximum (optional)", f[key], function(v) if v == "" then f[key] = nil else f[key] = tonumber(v) or v end end)
					end
					toggle(body, "Integer", "Integer only", f.integer, function(v) f.integer = v end)
				elseif f.kind == "string" then
					input(body, "Choices", "Allowed choices (comma-separated, optional)", table.concat(f.choices, ","), function(v)
						f.choices = {}; if v ~= "" then for _, part in ipairs(string.split(v, ",")) do table.insert(f.choices, part:match("^%s*(.-)%s*$")) end end
					end)
				end
				toggle(body, "UseDefault", "Enable missing-value repair", f.hasDefault, function(v) f.hasDefault = v end)
				if f.hasDefault then
					if f.kind == "boolean" then toggle(body, "DefaultBoolean", "Default: true", f.default == true, function(v) f.default = v end)
					else input(body, "DefaultValue", "Default value", f.default, function(v) f.default = f.kind == "number" and (tonumber(v) or v) or v end) end
				end
				button(body, "RemoveField", "Remove attribute rule", function() table.remove(state.schema.fields, state.fieldIndex); state.fieldIndex = math.max(1, state.fieldIndex - 1); changed() end)
			end
		end
	end
	local function findings(body)
		local r = row(body, 2)
		for _, scope in ipairs({"Selection", "Workspace"}) do button(r, "Scope" .. scope, scope, function() state.scope = scope; invalidate() end, state.scope == scope) end
		button(body, "Audit", "Audit tagged objects", audit, true)
		if not state.audit then return end
		local a = state.audit
		label(body, string.format("%d checked    %d valid    %d findings", a.matched, a.valid, #a.issues), 30, #a.issues == 0 and C.accent or C.error)
		label(body, a.schema.tag .. "  /  " .. a.schema.className, 22, C.muted)
		button(body, "SelectFindings", "Select affected objects", function() state.message = Engine.selectIssues(a, selection) .. " objects selected" end)
		button(body, "PrepareFixes", "Preview missing defaults", function() state.plan = Engine.preview(a); state.tab = "Fixes"; state.page = 1 end)
		local pages = math.max(1, math.ceil(#a.issues / 8)); state.page = math.min(state.page, pages)
		for i = (state.page - 1) * 8 + 1, math.min(state.page * 8, #a.issues) do
			local finding = a.issues[i]
			local b = button(body, "Finding" .. i, finding.instance.Name .. "  /  " .. finding.field .. "\n" .. finding.reason, function()
				assert(Engine.allowed(finding.instance), "Object was removed. Audit again")
				selection:Set({finding.instance}); state.message = finding.path .. (finding.description ~= "" and " | " .. finding.description or "")
			end)
			b.Size = UDim2.new(1, -4, 0, 55); b.TextWrapped = true; b.TextTruncate = Enum.TextTruncate.None; b.TextSize = 15
		end
		local nav = row(body, 3)
		button(nav, "Previous", "<", function() state.page = math.max(1, state.page - 1) end)
		label(nav, state.page .. " / " .. pages, 32)
		button(nav, "Next", ">", function() state.page = math.min(pages, state.page + 1) end)
	end
	local function fixes(body)
		if not state.plan then label(body, "No repair preview", 28, C.muted); return end
		local plan = state.plan
		label(body, #plan.changes .. " missing defaults", 30, C.accent)
		label(body, "Existing values and children: unchanged", 25, C.muted)
		if #plan.changes > 0 then
			button(body, "Apply", "Apply " .. #plan.changes .. " missing defaults", function()
				local count = Engine.apply(plan, history)
				state.audit = Engine.audit(plan.schema, plan.roots); state.plan = nil
				state.message = count .. " defaults added. Undo available."; state.tab = "Audit"
			end, true)
		end
		local pages = math.max(1, math.ceil(#plan.changes / 8)); state.page = math.min(state.page, pages)
		for i = (state.page - 1) * 8 + 1, math.min(state.page * 8, #plan.changes) do
			local c = plan.changes[i]
			label(body, c.instance.Name .. "  /  " .. c.name .. "\n(missing)  ->  " .. tostring(c.value), 53)
		end
		local nav = row(body, 3)
		button(nav, "Previous", "<", function() state.page = math.max(1, state.page - 1) end)
		label(nav, state.page .. " / " .. pages, 32)
		button(nav, "Next", ">", function() state.page = math.min(pages, state.page + 1) end)
	end
	render = function()
		if disposed then return end
		rendering = true
		for _, child in ipairs(root:GetChildren()) do child:Destroy() end
		make("UIPadding", root, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 10) })
		stack(root, 7)
		local heading = label(root, "SchemaForge", 29); heading.Font = Enum.Font.SourceSansBold; heading.TextSize = 23
		label(root, "PROJECT CONTRACTS   /   1.0", 19, C.accent)
		button(root, "Library", (state.library and "v  " or ">  ") .. "Project schemas", function() state.library = not state.library end)
		if state.library then
			local ok, names = pcall(Store.list)
			if not ok then label(root, "Schema storage conflict", 26, C.error)
			else
				local items = make("ScrollingFrame", root, { Name = "LibraryList", Size = UDim2.new(1, -4, 0, math.min(140, math.max(30, #names * 36))), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4 }); stack(items, 4)
				if #names == 0 then label(items, "No saved schemas", 26, C.muted) end
				for _, name in ipairs(names) do button(items, "Load" .. name, name, function() replaceDraft(function() local s, token = Store.load(name); loadDraft(s, token); state.library = false; state.message = "Loaded " .. name end) end) end
			end
		end
		local tools = row(root, 2)
		button(tools, "Capture", "Capture reference", function() replaceDraft(function()
			local selected = selection:Get(); assert(#selected == 1 and Engine.allowed(selected[1]), "Select exactly one project reference")
			local s, skipped = Schema.capture(selected[1]); loadDraft(s); state.dirty = true; state.tab = "Rules"; state.message = "Reference captured; " .. skipped .. " unsupported attributes skipped."
		end) end)
		button(tools, "New", "New schema", function() replaceDraft(function() loadDraft(Schema.new()); state.tab = "Rules" end) end)
		local saves = row(root, 2)
		button(saves, "Save", state.dirty and "Save schema *" or "Save schema", function()
			local token = state.loadedName == state.schema.name and state.token or nil
			state.token = Store.save(state.schema, token, history); state.loadedName = state.schema.name; state.dirty = false; state.message = "Saved in this project."
		end)
		button(saves, "Delete", "Delete saved", function()
			assert(state.loadedName and state.token, "Load or save a schema first")
			confirm("Delete saved schema " .. state.loadedName .. "?", function() Store.delete(state.loadedName, state.token, history); loadDraft(Schema.new()); state.message = "Schema deleted. Undo available." end)
		end)
		if state.confirm then
			label(root, state.confirm.title, 46, C.error)
			local r = row(root, 2)
			button(r, "Confirm", "Confirm", function() local fn = state.confirm.fn; state.confirm = nil; fn() end)
			button(r, "Cancel", "Cancel", function() state.confirm = nil end)
		end
		if state.message ~= "" then label(root, state.message, 49, state.failed and C.error or C.accent) end
		local tabs = row(root, 3)
		for _, name in ipairs({"Rules", "Audit", "Fixes"}) do button(tabs, "Tab" .. name, name, function() state.tab = name; state.menu = nil; state.page = 1 end, state.tab == name) end
		local body = make("ScrollingFrame", root, { Name = "Body", Size = UDim2.new(1, 0, 0, math.max(330, root.AbsoluteSize.Y - (state.library and 440 or 285) - (state.confirm and 85 or 0) - (state.message ~= "" and 56 or 0))), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4 }); stack(body, 7)
		if state.tab == "Rules" then rules(body) elseif state.tab == "Audit" then findings(body) else fixes(body) end
		rendering = false
	end
	local function historyChanged()
		invalidate(); state.message = "History changed. Run a fresh audit."
		task.defer(function() if not disposed then render() end end)
	end
	local undo = history.OnUndo:Connect(historyChanged); local redo = history.OnRedo:Connect(historyChanged)
	render()
	return function() disposed = true; undo:Disconnect(); redo:Disconnect(); resized:Disconnect(); shell:Destroy() end
end
return View
