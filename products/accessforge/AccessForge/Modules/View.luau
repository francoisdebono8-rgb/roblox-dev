local Settings = require(script.Parent.Settings)
local Engine = require(script.Parent.Engine)
local View = {}
local C = { bg = Color3.fromRGB(28, 30, 32), field = Color3.fromRGB(49, 54, 58), text = Color3.fromRGB(235, 239, 242), muted = Color3.fromRGB(165, 179, 186), accent = Color3.fromRGB(233, 162, 47), error = Color3.fromRGB(255, 144, 125), ok = Color3.fromRGB(123, 206, 167) }
local function el(class, parent, props)
	local item = Instance.new(class)
	for k, v in pairs(props) do item[k] = v end
	item.Parent = parent; return item
end
local function label(parent, text, height, color)
	return el("TextLabel", parent, { Text = text, Size = UDim2.new(1, 0, 0, height or 24), TextColor3 = color or C.text, BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left })
end
local function stack(parent, gap)
	el("UIListLayout", parent, { Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder })
end
local function row(parent, count, height)
	local frame = el("Frame", parent, { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, height or 30) })
	el("UIGridLayout", frame, { CellSize = UDim2.new(1 / count, -4, 1, 0), CellPadding = UDim2.fromOffset(4, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	return frame
end

function View.mount(widget, selection, history)
	local state = { settings = table.clone(Settings.defaults), section = "Layout", message = "", watches = {} }
	-- Studio can dock a widget below its requested minimum size.
	local shell = el("ScrollingFrame", widget, { Name = "AccessForgeScroll", BackgroundColor3 = C.bg, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, ScrollBarThickness = 4 })
	local root = el("Frame", shell, { Name = "AccessForgeUI", BackgroundColor3 = C.bg, BorderSizePixel = 0 })
	local function resize()
		root.Size = UDim2.fromOffset(math.max(shell.AbsoluteSize.X - 4, 350), math.max(shell.AbsoluteSize.Y, 620))
	end
	local resized = shell:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	local render, updatePreview, watch
	local disposed, rendering = false, false
	local scrollPosition = Vector2.zero
	local function invalidate()
		state.plan = nil; state.confirm = false
		local preview = root:FindFirstChild("Preview", true)
		if preview then preview:Destroy() end
		local build = root:FindFirstChild("BuildAction", true)
		if build then build.BackgroundColor3 = C.field end
	end
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
		local b = el("TextButton", parent, { Name = name, Text = text, Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = active and C.accent or C.field, BorderSizePixel = 0, TextColor3 = active and C.bg or C.text, Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd })
		b.Activated:Connect(act(fn)); return b
	end
	updatePreview = function()
		invalidate()
		state.plan = Engine.plan(state.start, state.finish, state.settings, state.target)
		state.message = #state.plan.warnings > 0 and table.concat(state.plan.warnings, " ") or "Preview ready"
	end
	watch = function()
		for _, c in ipairs(state.watches) do c:Disconnect() end
		state.watches = {}
		for _, p in pairs({ state.start, state.finish }) do
			local function changed()
				invalidate(); state.message = "Markers changed. Preview required."; task.defer(function() if not disposed then render() end end)
			end
			table.insert(state.watches, p:GetPropertyChangedSignal("Position"):Connect(changed))
			table.insert(state.watches, p.AncestryChanged:Connect(changed))
		end
	end
	local function changed()
		invalidate()
		if state.start and state.finish then updatePreview() end
	end
	local function input(parent, key, title)
		local r = row(parent, 2); label(r, title, 30, C.muted)
		local box = el("TextBox", r, { Name = key, Text = tostring(state.settings[key]), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = C.text, BackgroundColor3 = C.field, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })
		box:GetPropertyChangedSignal("Text"):Connect(function() if not rendering then invalidate() end end)
		box.FocusLost:Connect(act(function() state.settings[key] = tonumber(box.Text) or box.Text; changed() end))
	end
	local function toggle(parent, key, title)
		button(parent, key, (state.settings[key] and "[x]  " or "[ ]  ") .. title, function() state.settings[key] = not state.settings[key]; changed() end)
	end
	local function choices(parent, key, options)
		local r = row(parent, #options)
		for _, value in ipairs(options) do button(r, key .. value, value, function() state.settings[key] = value; changed() end, state.settings[key] == value) end
	end
	local function color(parent, key, title)
		label(parent, title, 20, C.muted)
		local r = row(parent, 6, 24)
		for i, rgb in ipairs({ {102,112,119}, {202,210,211}, {233,162,47}, {182,75,58}, {45,113,110}, {56,60,63} }) do
			local c = Color3.fromRGB(unpack(rgb))
			local b = button(r, key .. i, "", function() state.settings[key] = c; changed() end)
			b.BackgroundColor3 = c
		end
		local c = state.settings[key]
		local box = el("TextBox", parent, { Name = key .. "RGB", Text = string.format("%d, %d, %d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = C.text, BackgroundColor3 = C.field, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 28) })
		box:GetPropertyChangedSignal("Text"):Connect(function() if not rendering then invalidate() end end)
		box.FocusLost:Connect(act(function()
			local r1, g, b = box.Text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
			assert(r1 and tonumber(r1) <= 255 and tonumber(g) <= 255 and tonumber(b) <= 255, "Color requires R, G, B from 0 to 255.")
			state.settings[key] = Color3.fromRGB(tonumber(r1), tonumber(g), tonumber(b)); changed()
		end))
	end
	local function viewport(parent, plan)
		local v = el("ViewportFrame", parent, { Name = "Preview", Size = UDim2.new(1, -6, 0, 155), BackgroundColor3 = Color3.fromRGB(18, 22, 25), BorderSizePixel = 0, Ambient = Color3.fromRGB(175, 183, 195), LightDirection = Vector3.new(-1, -2, -1), LightColor = Color3.fromRGB(255, 240, 213) })
		local world = Instance.new("WorldModel"); world.Parent = v
		local model = Engine.output(plan); model.Parent = world
		local cf, size = model:GetBoundingBox()
		local camera = Instance.new("Camera"); camera.FieldOfView = 42
		local direction = Vector3.new(0.8, 0.65, 1).Unit
		camera.CFrame = CFrame.lookAt(cf.Position + direction * math.max(size.Magnitude * 1.55, 8), cf.Position)
		camera.Parent = v; v.CurrentCamera = camera
	end
	render = function()
		if disposed or rendering then return end
		rendering = true
		local previous = root:FindFirstChild("Settings")
		if previous then scrollPosition = previous.CanvasPosition end
		root:ClearAllChildren()
		local header = el("Frame", root, { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 104), BackgroundTransparency = 1 }); stack(header, 5)
		local title = label(header, "ACCESSFORGE   /   1.1", 26, C.accent); title.TextSize = 21; title.Font = Enum.Font.SourceSansSemibold
		choices(header, "Mode", { "Straight", "Switchback", "Catwalk" })
		local tabs = row(header, 3, 26)
		for _, name in ipairs({ "Layout", "Rails", "Finish" }) do button(tabs, "Tab" .. name, name, function() state.section = name; scrollPosition = Vector2.zero end, state.section == name) end
		local body = el("ScrollingFrame", root, { Name = "Settings", Position = UDim2.fromOffset(12, 118), Size = UDim2.new(1, -24, 1, -426), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4 }); stack(body)
		if state.section == "Layout" then
			local r = row(body, 2)
			for _, binding in ipairs({ { "start", "Start" }, { "finish", "End" } }) do
				local key, name = binding[1], binding[2]
				button(r, "Assign" .. name, name .. ": " .. (state[key] and state[key].Name or "Selection"), function()
					local list = selection:Get(); assert(#list == 1 and list[1]:IsA("BasePart"), "Select one BasePart for " .. name .. ".")
					state[key] = list[1]; watch(); changed()
				end)
			end
			local actions = row(body, 2)
			button(actions, "NewMarkers", "New markers", function()
				local camera = workspace.CurrentCamera
				local origin = camera and camera.Focus.Position or Vector3.new(0, 0, 0)
				state.start, state.finish = Engine.newMarkers(history, origin, state.settings.Mode)
				state.target = nil; watch(); updatePreview(); selection:Set({ state.start, state.finish })
			end)
			button(actions, "EditExisting", "Edit Existing", function()
				local selected = selection:Get(); assert(#selected == 1, "Select one AccessForge assembly.")
				local plan = Engine.load(selected[1]); state.target = selected[1]
				state.start, state.finish, state.settings = plan.start, plan.finish, table.clone(plan.settings)
				state.plan, state.confirm, state.message = plan, false, "Editing " .. selected[1].Name; watch()
			end)
			input(body, "Width", "Width (studs)")
			input(body, "Thickness", "Deck / tread thickness")
			if state.settings.Mode ~= "Catwalk" then
				input(body, "TreadDepth", "Target tread depth")
				input(body, "RiserHeight", "Maximum riser")
				if state.settings.Mode == "Straight" then toggle(body, "Landing", "Top landing") else choices(body, "ReturnSide", { "Left", "Right" }) end
				if state.settings.Landing or state.settings.Mode == "Switchback" then input(body, "LandingDepth", "Landing depth") end
			end
		elseif state.section == "Rails" then
			local r = row(body, 2); toggle(r, "RailLeft", "Left rail"); toggle(r, "RailRight", "Right rail")
			input(body, "RailHeight", "Rail height"); input(body, "PostSpacing", "Post spacing")
			toggle(body, "MidRail", "Mid rail"); choices(body, "RailProfile", { "Square", "Round" })
			color(body, "RailColor", "Rail color (RGB)")
			toggle(body, "Supports", "Support posts")
			if state.settings.Supports then input(body, "SupportSpacing", "Support spacing"); input(body, "FloorHeight", "Support floor Y") end
		else
			button(body, "Material", "Material: " .. state.settings.Material, function() state.materialMenu = not state.materialMenu end)
			if state.materialMenu then
				for _, material in ipairs(Settings.materials) do button(body, "Material" .. material, material, function() state.settings.Material = material; state.materialMenu = false; changed() end) end
			end
			color(body, "Color", "Structure color (RGB)")
			toggle(body, "Anchored", "Anchored"); toggle(body, "CanCollide", "CanCollide")
		end
		body.CanvasPosition = scrollPosition
		local footer = el("Frame", root, { Name = "Result", Position = UDim2.new(0, 12, 1, -302), Size = UDim2.new(1, -24, 0, 294), BackgroundTransparency = 1 }); stack(footer, 5)
		local plan = state.plan
		local stats = plan and string.format("%d steps | rise %.2f | run %.2f\nRiser %.3f | tread %s | %d parts", plan.steps, plan.rise, plan.run, plan.actualRise, #plan.depths > 0 and string.format("%.2f", plan.depths[1]) or "-", plan.count) or "No current preview"
		label(footer, stats, 38, C.muted)
		if plan then
			local ok, err = pcall(viewport, footer, plan)
			if not ok then invalidate(); state.failed = true; state.message = tostring(err) end
		else el("Frame", footer, { Size = UDim2.new(1, -6, 0, 155), BackgroundColor3 = Color3.fromRGB(18, 22, 25), BorderSizePixel = 0 }) end
		label(footer, state.message, 44, state.failed and C.error or C.ok)
		local commands = row(footer, 2, 32)
		button(commands, "PreviewAction", "Preview", updatePreview)
		button(commands, "BuildAction", state.confirm and "Confirm " .. (state.target and "Regenerate" or "Build") or (state.target and "Regenerate" or "Build"), function()
			assert(state.plan, "Preview valid geometry first.")
			if not state.confirm then state.confirm = true; state.message = "Confirm " .. state.plan.count .. " parts"; return end
			local model = Engine.apply(state.plan, history)
			state.target = model; invalidate(); selection:Set({ model }); state.message = "Built " .. model.Name
			updatePreview(); state.message = "Built " .. model.Name
		end, state.plan ~= nil)
		rendering = false
	end
	local undo = history.OnUndo:Connect(function() invalidate(); state.message = "Undo complete. Preview or Edit Existing to continue."; render() end)
	local redo = history.OnRedo:Connect(function() invalidate(); state.message = "Redo complete. Preview or Edit Existing to continue."; render() end)
	render()
	return function()
		disposed = true; undo:Disconnect(); redo:Disconnect()
		for _, c in ipairs(state.watches) do c:Disconnect() end
		resized:Disconnect(); shell:Destroy()
	end
end

return View
