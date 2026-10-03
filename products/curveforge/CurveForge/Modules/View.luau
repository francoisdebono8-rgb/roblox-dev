local Engine = require(script.Parent.Engine)
local Settings = require(script.Parent.Settings)
local UI = require(script.Parent.StudioUI)
local View = {}
local function el(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props) do item[key] = value end
	item.Parent = parent; return item
end

function View.mount(widget, selection, history)
	local state = { controls = {}, settings = table.clone(Settings.defaults), confirmed = false, message = "", watches = {}, page = "Path", section = "Shape" }
	local root = el("Frame", widget, { Name = "CurveForgeUI", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants=true })
	local ui = UI.new(root, Color3.fromRGB(77,125,210))
	local colors = ui.colors; colors.panel = colors.field
	local label, row = ui.label, ui.row
	local function button(parent, text, callback, accent)
		return ui.button(parent, text, text, callback, accent and "selected" or nil)
	end
	local body, rail, work, footer
	local render, watch, preview
	local disposed, generation = false, 0
	local function invalidate()
		state.plan = nil
		local view = root:FindFirstChild("GeometryPreview", true); if view then view:Destroy() end
		local build = root:FindFirstChild("BuildAction", true); if build then build.BackgroundColor3=colors.field end
	end
	local function act(fn)
		return function()
			state.failed = false
			local ok, err = pcall(fn)
			if not ok then state.message = tostring(err):gsub("^.-:%d+: ", ""); state.failed = true end
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
		label(parent, title, 12, colors.muted)
		ui.input(parent, key, tostring(state.settings[key]), invalidate, function(text) act(function()
			state.settings[key] = tonumber(text) or text
			if state.confirmed then preview() end
		end)() end)
	end
	local function toggle(parent, key, title)
		ui.toggle(parent, key, title, state.settings[key], act(function()
			state.settings[key] = not state.settings[key]; invalidate(); if state.confirmed then preview() end
		end))
	end
	local function choose(parent, key, options)
		local r = row(parent, #options)
		for _, option in ipairs(options) do
			button(r, option, act(function() state.settings[key] = option; invalidate(); if state.confirmed then preview() end end), state.settings[key] == option)
		end
	end
	render = function()
		if disposed then return end
		root:ClearAllChildren()
		local wide = root.AbsoluteSize.X >= 520
		ui.header("CurveForge", state.target and state.target.Name or "Untitled path", (state.target and "Editing existing" or "New path") .. "  /  " .. #state.controls .. " control points")
		local nav=el("Frame",root,{Position=UDim2.fromOffset(12,92),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
		local navrow=row(nav,wide and 2 or 3)
		for _,page in ipairs(wide and {"Path","Settings"} or {"Path","Settings","Preview"}) do button(navrow,page,act(function() state.page=page end),state.page==page) end
		rail=ui.scroll(root,"PointRail",UDim2.fromOffset(12,132),wide and UDim2.new(0,174,1,-232) or UDim2.new(1,-24,1,-232))
		work=el("Frame",root,{Name="PathWorkspace",BackgroundTransparency=1,Position=wide and UDim2.fromOffset(202,132) or UDim2.fromOffset(12,132),Size=wide and UDim2.new(1,-214,1,-232) or UDim2.new(1,-24,1,-232)})
		rail.Visible=wide or state.page~="Preview"; work.Visible=wide or state.page=="Preview"
		body=rail
		footer=el("Frame",root,{Name="Commands",BackgroundTransparency=1,Position=UDim2.new(0,12,1,-90),Size=UDim2.new(1,-24,0,82)})
		ui.stack(footer,6)
		local status=label(footer,state.message~="" and state.message or "Preview required",12,state.failed and colors.error or colors.muted,36)
		ui.tip(status,state.message)
		if state.page~="Settings" then
		ui.section(body,"CONTROL POINTS")
		local actions = body
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
			local pointButton = button(body, tostring(i) .. "   " .. p.Name, act(function() state.selected=i; selection:Set({ p }) end),state.selected==i)
			pointButton.TextWrapped = false; pointButton.TextTruncate = Enum.TextTruncate.AtEnd
			pointButton.TextXAlignment=Enum.TextXAlignment.Left; ui.tip(pointButton,p:GetFullName())
			if state.selected==i then
				local r=row(body,3,26)
				local up=button(r,"\u{2191}",act(function() if i>1 then state.controls[i],state.controls[i-1]=state.controls[i-1],p; state.selected=i-1 end; state.confirmed=false; state.rotation=nil; invalidate() end)); ui.tip(up,"Move point earlier")
				local down=button(r,"\u{2193}",act(function() if i<#state.controls then state.controls[i],state.controls[i+1]=state.controls[i+1],p; state.selected=i+1 end; state.confirmed=false; state.rotation=nil; invalidate() end)); ui.tip(down,"Move point later")
				local remove=button(r,"\u{00D7}",act(function() table.remove(state.controls,i); state.selected=nil; state.confirmed=false; invalidate(); watch() end)); ui.tip(remove,"Remove from path")
			end
		end
		if #state.controls > 0 and not state.confirmed then button(body, "Confirm displayed order", act(function() state.confirmed = true; preview() end), true) end
		ui.rule(body)
		button(body, "Edit Existing", act(function()
			local list = selection:Get(); assert(#list == 1, "Select one CurveForge output model.")
			local plan = Engine.load(list[1])
			state.controls, state.settings, state.source, state.rotation = plan.controls, table.clone(plan.settings), plan.source, plan.rotation
			state.target, state.confirmed, state.plan = list[1], true, plan
			watch(); state.message = "Loaded: " .. list[1].Name
		end))
		else
		ui.section(body,"OUTPUT"); choose(body, "Mode", { "Cable", "Repeat" })
		toggle(body, "ControlRoll", "Control-point roll guides")
		if state.settings.Mode == "Cable" then
			input(body, "Diameter", "Diameter (studs)"); input(body, "SegmentLength", "Segment length")
			local swatches = row(body, 6)
			for _, rgb in ipairs({ {52,179,161}, {61,65,73}, {234,187,65}, {221,91,73}, {199,206,211}, {69,139,213} }) do
				local color = Color3.fromRGB(unpack(rgb))
				local b = button(swatches, "", act(function() state.settings.Color = color; invalidate(); if state.confirmed then preview() end end))
				local swatch=el("Frame",b,{Position=UDim2.fromOffset(3,5),Size=UDim2.new(1,-6,1,-10),BackgroundColor3=color,BorderSizePixel=0})
				el("UICorner",swatch,{CornerRadius=UDim.new(0,3)})
				ui.tip(b,string.format("RGB %d, %d, %d",unpack(rgb)))
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
			toggle(body, "Anchored", "Anchored"); toggle(body, "CanCollide", "Collide"); toggle(body, "CastShadow", "Shadow")
		else
			button(body, "Source: " .. (state.source and state.source.Name or "Choose selection"), act(function()
				local list = selection:Get(); assert(#list == 1, "Select one source Part or Model.")
				state.source, state.rotation = list[1], nil; watch(); invalidate(); if state.confirmed then preview() end
			end))
			choose(body, "Distribution", { "Spacing", "Count" })
			input(body, state.settings.Distribution, state.settings.Distribution == "Spacing" and "Spacing (studs)" or "Copy count")
			toggle(body, "Orient", "Tangent orientation"); toggle(body, "PreserveRotation", "Preserve local rotation offset"); toggle(body, "Endpoints", "Include endpoints")
		end
		end
		local mode=label(work,state.settings.Mode .. " preview",15,colors.text,24); mode.Font=Enum.Font.BuilderSansBold
		local previewHost=el("Frame",work,{Name="PreviewSurface",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,1,-92),BackgroundColor3=colors.viewport,BorderSizePixel=0})
		if state.plan then
			local ok, err = pcall(function() ui.viewport(previewHost,Engine.output(state.plan)) end)
			if not ok then invalidate(); state.failed=true; status.Text=tostring(err); status.TextColor3=colors.error end
		else
			local empty=label(previewHost,"No current preview",13,colors.muted,30); empty.Position=UDim2.new(0,12,0.5,-15); empty.Size=UDim2.new(1,-24,0,30)
		end
		local metrics=label(work,state.plan and string.format("%.1f studs  /  %d %s",state.plan.path.length,#state.plan.distances-(state.settings.Mode=="Cable" and 1 or 0),state.settings.Mode=="Cable" and "segments" or "copies") or "2-8 ordered control points",13,colors.muted,24)
		metrics.Position=UDim2.new(0,0,1,-52)
		local source=label(work,state.source and ("Source: "..state.source.Name) or "Proposed output",12,colors.muted,20); source.Position=UDim2.new(0,0,1,-26)
		local actions2 = row(footer, 2,34)
		button(actions2, "Preview", act(preview))
		ui.button(actions2, "BuildAction", state.target and "Regenerate" or "Build", act(function()
			assert(state.plan, "Preview a valid path first.")
			local model = Engine.apply(state.plan, history, state.target)
			state.target, state.rotation = model, state.plan.rotation
			invalidate(); selection:Set({ model }); state.message = "Complete. Studio Undo restores the previous state."
		end), state.plan and "primary" or nil)
	end
	render()
	local resized=root:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	local theme=settings().Studio.ThemeChanged:Connect(function() ui.theme(); colors.panel=colors.field; render() end)
	local undo=history.OnUndo:Connect(function() invalidate(); state.message="Undo complete. Preview required."; render() end)
	local redo=history.OnRedo:Connect(function() invalidate(); state.message="Redo complete. Preview required."; render() end)
	return function() disposed = true; resized:Disconnect(); theme:Disconnect(); undo:Disconnect(); redo:Disconnect(); for _, c in ipairs(state.watches) do c:Disconnect() end; root:Destroy() end
end
return View
