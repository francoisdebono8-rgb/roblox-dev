local Engine = require(script.Parent.Engine)
local Settings = require(script.Parent.Settings)
local View = {}
local colors = { bg = Color3.fromRGB(30, 32, 35), panel = Color3.fromRGB(47, 51, 56), text = Color3.fromRGB(238, 241, 243), muted = Color3.fromRGB(174, 183, 194), accent = Color3.fromRGB(40, 149, 132), error = Color3.fromRGB(255, 153, 126) }
local function el(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props) do item[key] = value end
	item.Parent = parent; return item
end
local function stack(parent)
	el("UIListLayout", parent, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
end
local function label(parent, text, size, color)
	return el("TextLabel", parent, { Text = text, Font = Enum.Font.SourceSans, TextSize = size or 15, TextColor3 = color or colors.text, BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left })
end
local function button(parent, text, callback, accent)
	local b = el("TextButton", parent, { Name = text, Text = text, Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextWrapped = true, TextColor3 = colors.text, BackgroundColor3 = accent and colors.accent or colors.panel, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 30) })
	b.Activated:Connect(callback); return b
end
local function row(parent, count)
	local r = el("Frame", parent, { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 30) })
	el("UIGridLayout", r, { CellSize = UDim2.new(1 / count, -5, 1, 0), CellPadding = UDim2.fromOffset(5, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	return r
end

function View.mount(widget, selection, history)
	local state = { controls = {}, settings = table.clone(Settings.defaults), confirmed = false, message = "", watches = {} }
	local root = el("Frame", widget, { Name = "CurveForgeUI", BackgroundColor3 = colors.bg, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })
	local body = el("ScrollingFrame", root, { Name = "Workflow", Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local render, watch, preview
	local disposed, generation = false, 0
	local function invalidate() state.plan = nil end
	local function act(fn)
		return function()
			state.message = ""; state.failed = false
			local ok, err = pcall(fn)
			if not ok then state.message = tostring(err); state.failed = true end
			render()
		end
	end
	preview = function()
		assert(state.confirmed, "Confirm the displayed point order first.")
		state.plan = Engine.plan(state.controls, state.settings, state.source, state.rotation)
		state.message = string.format("%.1f studs | %d %s", state.plan.path.length, #state.plan.distances - (state.settings.Mode == "Cable" and 1 or 0), state.settings.Mode == "Cable" and "segments" or "copies")
	end
	local function changed()
		invalidate(); generation += 1
		local stamp = generation
		task.delay(0.2, function()
			if disposed or stamp ~= generation then return end
			if state.confirmed then
				local ok, err = pcall(preview)
				state.failed = not ok; if not ok then state.message = tostring(err) end
			end
			render()
		end)
	end
	watch = function()
		for _, c in ipairs(state.watches) do c:Disconnect() end
		state.watches = {}
		for _, p in ipairs(state.controls) do
			table.insert(state.watches, p:GetPropertyChangedSignal("CFrame"):Connect(changed))
			table.insert(state.watches, p.AncestryChanged:Connect(changed))
		end
		if state.source then
			local list = state.source:GetDescendants(); table.insert(list, state.source)
			for _, p in ipairs(list) do table.insert(state.watches, p.Changed:Connect(changed)) end
			table.insert(state.watches, state.source.DescendantAdded:Connect(function() watch(); changed() end))
			table.insert(state.watches, state.source.DescendantRemoving:Connect(changed))
		end
	end
	local function input(parent, key, title)
		local r = row(parent, 2); label(r, title, 14, colors.muted)
		local box = el("TextBox", r, { Name = key, Text = tostring(state.settings[key]), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = colors.text, BackgroundColor3 = colors.panel, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })
		box:GetPropertyChangedSignal("Text"):Connect(invalidate)
		box.FocusLost:Connect(act(function()
			state.settings[key] = tonumber(box.Text) or box.Text
			if state.confirmed then preview() end
		end))
	end
	local function toggle(parent, key, title)
		button(parent, (state.settings[key] and "[x] " or "[ ] ") .. title, act(function()
			state.settings[key] = not state.settings[key]; invalidate(); if state.confirmed then preview() end
		end))
	end
	local function choose(parent, key, options)
		local r = row(parent, #options)
		for _, option in ipairs(options) do
			button(r, option, act(function() state.settings[key] = option; invalidate(); if state.confirmed then preview() end end), state.settings[key] == option)
		end
	end
	local function viewport(plan)
		local view = el("ViewportFrame", body, { Name = "Preview", Size = UDim2.new(1, -6, 0, 180), BackgroundColor3 = Color3.fromRGB(21, 25, 29), BorderSizePixel = 0, Ambient = Color3.fromRGB(190, 190, 190), LightDirection = Vector3.new(-1, -2, -1) })
		local world = Instance.new("WorldModel"); world.Parent = view
		local model = Engine.output(plan); model.Parent = world
		local cf, size = model:GetBoundingBox()
		local camera = Instance.new("Camera"); camera.FieldOfView = 45
		camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.4, 0.5, 1).Unit * math.max(size.Magnitude * 1.6, 4), cf.Position)
		camera.Parent = view; view.CurrentCamera = camera
	end
	render = function()
		if disposed then return end
		local scroll = body.CanvasPosition
		body:ClearAllChildren(); stack(body)
		label(body, "CurveForge  /  1.1", 22)
		if state.message ~= "" then label(body, state.message, 14, state.failed and colors.error or colors.muted) end
		label(body, "PATH", 15, colors.accent)
		local actions = row(body, 2)
		button(actions, "New Path", act(function()
			local camera = workspace.CurrentCamera
			state.controls = Engine.newPath(history, camera and (camera.CFrame.Position + camera.CFrame.LookVector * 25) or Vector3.new(0, 5, 0))
			state.confirmed, state.target, state.rotation = true, nil, nil
			watch(); preview(); selection:Set(state.controls)
		end))
		button(actions, "Use selected points", act(function()
			local list = selection:Get()
			assert(#list >= 2 and #list <= 8, "Select 2 to 8 BaseParts.")
			for _, p in ipairs(list) do assert(p:IsA("BasePart") and p:IsDescendantOf(workspace), "Select BaseParts in Workspace only.") end
			state.controls, state.confirmed, state.target, state.rotation = table.clone(list), false, nil, nil
			invalidate(); watch()
		end))
		for i, p in ipairs(state.controls) do
			local r = row(body, 4)
			local pointButton = button(r, tostring(i) .. ". " .. p.Name, act(function() selection:Set({ p }) end))
			pointButton.TextWrapped = false; pointButton.TextTruncate = Enum.TextTruncate.AtEnd
			button(r, "Up", act(function() if i > 1 then state.controls[i], state.controls[i - 1] = state.controls[i - 1], p end; state.confirmed = false; state.rotation = nil; invalidate() end))
			button(r, "Down", act(function() if i < #state.controls then state.controls[i], state.controls[i + 1] = state.controls[i + 1], p end; state.confirmed = false; state.rotation = nil; invalidate() end))
			button(r, "Remove", act(function() table.remove(state.controls, i); state.confirmed = false; invalidate(); watch() end))
		end
		if #state.controls > 0 and not state.confirmed then button(body, "Confirm displayed order", act(function() state.confirmed = true; preview() end), true) end
		label(body, "OUTPUT MODE", 15, colors.accent); choose(body, "Mode", { "Cable", "Repeat" })
		label(body, "SETTINGS", 15, colors.accent)
		toggle(body, "ControlRoll", "Control-point roll guides")
		if state.settings.Mode == "Cable" then
			input(body, "Diameter", "Diameter (studs)"); input(body, "SegmentLength", "Segment length")
			local swatches = row(body, 6)
			for _, rgb in ipairs({ {52,179,161}, {61,65,73}, {234,187,65}, {221,91,73}, {199,206,211}, {69,139,213} }) do
				local color = Color3.fromRGB(unpack(rgb))
				local b = button(swatches, "", act(function() state.settings.Color = color; invalidate(); if state.confirmed then preview() end end))
				b.BackgroundColor3 = color
			end
			local c = state.settings.Color
			local rgb = el("TextBox", body, { Name = "ColorRGB", Text = string.format("%d, %d, %d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)), PlaceholderText = "R, G, B", ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = colors.text, BackgroundColor3 = colors.panel, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 28) })
			rgb:GetPropertyChangedSignal("Text"):Connect(invalidate)
			rgb.FocusLost:Connect(act(function()
				local r, g, b = rgb.Text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
				assert(r and tonumber(r) <= 255 and tonumber(g) <= 255 and tonumber(b) <= 255, "Color requires R, G, B values from 0 to 255.")
				state.settings.Color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)); if state.confirmed then preview() end
			end))
			button(body, "Material: " .. state.settings.Material, act(function() state.materialMenu = not state.materialMenu end))
			if state.materialMenu then
				for _, material in ipairs(Settings.materials) do button(body, material, act(function() state.settings.Material = material; state.materialMenu = false; invalidate(); if state.confirmed then preview() end end)) end
			end
			local toggles = row(body, 3); toggle(toggles, "Anchored", "Anchored"); toggle(toggles, "CanCollide", "Collide"); toggle(toggles, "CastShadow", "Shadow")
		else
			button(body, "Source: " .. (state.source and state.source.Name or "Choose selection"), act(function()
				local list = selection:Get(); assert(#list == 1, "Select one source Part or Model.")
				state.source, state.rotation = list[1], nil; watch(); invalidate(); if state.confirmed then preview() end
			end))
			choose(body, "Distribution", { "Spacing", "Count" })
			input(body, state.settings.Distribution, state.settings.Distribution == "Spacing" and "Spacing (studs)" or "Copy count")
			toggle(body, "Orient", "Tangent orientation"); toggle(body, "PreserveRotation", "Preserve local rotation offset"); toggle(body, "Endpoints", "Include endpoints")
		end
		label(body, "PREVIEW / BUILD", 15, colors.accent)
		if state.plan then
			local ok, err = pcall(viewport, state.plan)
			if not ok then invalidate(); label(body, tostring(err), 14, colors.error) end
		end
		local actions2 = row(body, 2)
		button(actions2, "Preview", act(preview))
		button(actions2, state.target and "Regenerate" or "Build", act(function()
			assert(state.plan, "Preview a valid path first.")
			local model = Engine.apply(state.plan, history, state.target)
			state.target, state.rotation = model, state.plan.rotation
			invalidate(); selection:Set({ model }); state.message = "Complete. Studio Undo restores the previous state."
		end), true)
		label(body, "EDIT EXISTING", 15, colors.accent)
		button(body, "Edit Selected CurveForge Model", act(function()
			local list = selection:Get(); assert(#list == 1, "Select one CurveForge output model.")
			local plan = Engine.load(list[1])
			state.controls, state.settings, state.source, state.rotation = plan.controls, plan.settings, plan.source, plan.rotation
			state.target, state.confirmed, state.plan = list[1], true, plan
			watch(); state.message = "Loaded: " .. list[1].Name
		end))
		body.CanvasPosition = scroll
	end
	render()
	return function() disposed = true; for _, c in ipairs(state.watches) do c:Disconnect() end; root:Destroy() end
end
return View
