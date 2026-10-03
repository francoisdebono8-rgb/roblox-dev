local Settings = require(script.Parent.Settings)
local Engine = require(script.Parent.Engine)
local Preview = require(script.Parent.Preview)
local UI = require(script.Parent.StudioUI)
local View = {}
local function el(class, parent, props)
	local item = Instance.new(class)
	for k, v in pairs(props) do item[k] = v end
	item.Parent = parent; return item
end

function View.mount(widget, selection, history)
	local state = { settings = table.clone(Settings.defaults), section = "Layout", page = "Endpoints", comparison = "Proposed", message = "", watches = {} }
	local root = el("Frame", widget, { Name = "AccessForgeUI", BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.fromScale(1,1), ClipsDescendants = true })
	local ui = UI.new(root, Color3.fromRGB(163,75,197)); local C = ui.colors
	local row, stack = ui.row, ui.stack
	local function label(parent, text, height, color) return ui.label(parent,text,13,color,height) end
	local render, updatePreview, watch
	local disposed, rendering = false, false
	local scrollPosition = Vector2.zero
	local function invalidate()
		state.plan = nil; state.confirm = false
		if state.preview then state.preview.model:Destroy(); state.preview = nil end
		local preview = root:FindFirstChild("GeometryPreview", true)
		if preview then preview:Destroy() end
		local build = root:FindFirstChild("BuildAction", true)
		if build then build.Active = false; build.BackgroundColor3 = C.field; build.TextColor3 = C.muted end
		local metrics = root:FindFirstChild("AssemblyMetrics", true)
		if metrics then metrics.Text = "Preview required" end
		local status = root:FindFirstChild("PreviewStatus", true)
		if status then status.Text = "Preview required"; status.TextColor3 = C.warning end
	end
	local function act(fn)
		return function()
			if disposed or rendering then return end
			state.failed = false
			local ok, err = pcall(fn)
			if not ok then invalidate(); state.failed = true; state.message = tostring(err):gsub("^.-:%d+: ", "") end
			render()
		end
	end
	local function button(parent, name, text, fn, active)
		return ui.button(parent,name,text,act(fn),active and "selected" or nil)
	end
	updatePreview = function()
		invalidate()
		state.plan = Engine.plan(state.start, state.finish, state.settings, state.target)
		state.preview = Preview.capture(state.plan)
		state.comparison = "Proposed"
		state.message = #state.plan.warnings > 0 and table.concat(state.plan.warnings, " ") or "Preview ready"
	end
	watch = function()
		for _, c in ipairs(state.watches) do c:Disconnect() end
		state.watches = {}
		for _, p in pairs({ state.start, state.finish }) do
			local function changed()
				invalidate(); state.message = "Markers changed. Preview required."; task.defer(function() if not disposed then render() end end)
			end
			table.insert(state.watches, p:GetPropertyChangedSignal("CFrame"):Connect(changed))
			table.insert(state.watches, p.AncestryChanged:Connect(changed))
		end
	end
	local function changed()
		invalidate()
		if state.start and state.finish then updatePreview() end
	end
	local function input(parent, key, title)
		label(parent,title,nil,C.muted)
		ui.input(parent,key,tostring(state.settings[key]),function() if not rendering then invalidate() end end,function(text)
			act(function() state.settings[key]=tonumber(text) or text; changed() end)()
		end)
	end
	local function toggle(parent, key, title)
		ui.toggle(parent,key,title,state.settings[key],act(function() state.settings[key] = not state.settings[key]; changed() end))
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
			local swatch=el("Frame",b,{Position=UDim2.fromOffset(3,3),Size=UDim2.new(1,-6,1,-6),BackgroundColor3=c,BorderSizePixel=0})
			el("UICorner",swatch,{CornerRadius=UDim.new(0,3)})
			ui.tip(b,string.format("RGB %d, %d, %d",unpack(rgb)))
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
	render = function()
		if disposed or rendering then return end
		rendering = true
		local previous = root:FindFirstChild("Settings")
		if previous then scrollPosition = previous.CanvasPosition end
		root:ClearAllChildren()
		local wide=root.AbsoluteSize.X>=520
		ui.header("AccessForge",state.target and state.target.Name or "Untitled assembly",state.settings.Mode .. (state.target and "  /  Editing existing" or "  /  New assembly"))
		local nav=el("Frame",root,{Position=UDim2.fromOffset(12,92),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
		local tabs=row(nav,wide and 2 or 3)
		for _,name in ipairs(wide and {"Endpoints","Settings"} or {"Endpoints","Settings","Preview"}) do
			button(tabs,"Page"..name,name,function() state.page=name; scrollPosition=Vector2.zero end,state.page==name)
		end
		local body=ui.scroll(root,"Settings",UDim2.fromOffset(12,132),wide and UDim2.new(0,190,1,-232) or UDim2.new(1,-24,1,-232))
		body.Visible=wide or state.page~="Preview"
		local assembly=ui.scroll(root,"AssemblyWorkspace",wide and UDim2.fromOffset(218,132) or UDim2.fromOffset(12,132),wide and UDim2.new(1,-230,1,-232) or UDim2.new(1,-24,1,-232))
		assembly.Visible=wide or state.page=="Preview"
		if state.page~="Settings" then
			ui.section(body,"ENDPOINTS")
			for _, binding in ipairs({ { "start", "Start" }, { "finish", "End" } }) do
				local key, name = binding[1], binding[2]
				label(body,name,20,C.muted)
				local endpoint=label(body,state[key] and state[key].Name or "Not assigned",24,C.text); endpoint.Font=Enum.Font.BuilderSansBold
				if state[key] then ui.tip(endpoint,state[key]:GetFullName()) end
				local r=row(body,2,30)
				button(r, "Assign" .. name, "Assign", function()
					local list = selection:Get(); assert(#list == 1 and list[1]:IsA("BasePart"), "Select one BasePart for " .. name .. ".")
					state[key] = list[1]; watch(); changed()
				end)
				button(r,"Locate"..name,"Locate",function() assert(state[key],"Assign "..name.." first."); selection:Set({state[key]}) end)
				ui.rule(body)
			end
			if state.start and state.finish then
				label(body,string.format("Rise %.2f  /  span %.2f",state.finish.Position.Y-state.start.Position.Y,(state.finish.Position-state.start.Position).Magnitude),nil,C.muted)
			end
			local actions = row(body,2,30)
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
				watch(); updatePreview(); state.message = "Editing " .. selected[1].Name
			end)
			ui.section(body,"ASSEMBLY")
			for _,mode in ipairs({"Straight","Switchback","Catwalk"}) do
				button(body,"Mode"..mode,mode,function() state.settings.Mode=mode; changed() end,state.settings.Mode==mode)
			end
		else
			ui.section(body,"ASSEMBLY MODE")
			for _,mode in ipairs({"Straight","Switchback","Catwalk"}) do
				button(body,"Mode"..mode,mode,function() state.settings.Mode=mode; changed() end,state.settings.Mode==mode)
			end
			ui.rule(body)
			local sections=row(body,3,28)
			for _,name in ipairs({"Layout","Rails","Finish"}) do button(sections,"Tab"..name,name,function() state.section=name; scrollPosition=Vector2.zero end,state.section==name) end
		if state.section == "Layout" then
			input(body, "Width", "Width (studs)")
			input(body, "Thickness", "Deck / tread thickness")
			if state.settings.Mode ~= "Catwalk" then
				input(body, "TreadDepth", "Target tread depth")
				input(body, "RiserHeight", "Maximum riser")
				if state.settings.Mode == "Straight" then toggle(body, "Landing", "Top landing") else choices(body, "ReturnSide", { "Left", "Right" }) end
				if state.settings.Landing or state.settings.Mode == "Switchback" then input(body, "LandingDepth", "Landing depth") end
			end
		elseif state.section == "Rails" then
			toggle(body, "RailLeft", "Left rail"); toggle(body, "RailRight", "Right rail")
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
		end
		body.CanvasPosition = scrollPosition
		local footer = el("Frame", root, { Name = "Result", Position = UDim2.new(0, 12, 1, -90), Size = UDim2.new(1, -24, 0, 82), BackgroundTransparency = 1 }); stack(footer, 6)
		local plan = state.plan
		local title=label(assembly,state.settings.Mode.." assembly",24,C.text); title.Font=Enum.Font.BuilderSansBold
		if state.target and plan then
			local comparisons=row(assembly,2,30)
			for _,name in ipairs({"Proposed","Existing"}) do
				button(comparisons,"Compare"..name,name,function() state.comparison=name end,state.comparison==name)
			end
		else label(assembly,"Start + End",20,C.muted) end
		local host=el("Frame",assembly,{Name="PreviewSurface",Size=UDim2.new(1,0,0,math.max(160,root.AbsoluteSize.Y-480)),BackgroundColor3=C.viewport,BorderSizePixel=0})
		if plan and state.preview then
			ui.viewport(host,Preview.display(state.preview,state.comparison),state.preview)
		else local empty=label(host,"No current preview",30,C.muted); empty.Position=UDim2.new(0,12,0.5,-15); empty.Size=UDim2.new(1,-24,0,30) end
		if state.preview then
			local p=state.preview
			local summary=string.format("Context: %d shown / %d omitted",p.contextCount,p.omittedCount)
			if not p.available then summary..="\nContext query incomplete"
			elseif p.queryLimited then summary..="\nQuery limit reached" end
			local context=label(assembly,summary,nil,C.muted); context.Name="ContextSummary"
			ui.tip(context,string.format("Omissions among sampled objects: %d unsupported shapes, %d non-Archivable, %d oversized, %d invisible, %d over the display cap. At most %d parts shown, two queries of at most %d results within %d studs per axis of each endpoint. Terrain, other non-queryable objects and unsampled objects are not counted; more may be omitted.",p.omitted.unsupported,p.omitted.nonArchivable,p.omitted.oversized,p.omitted.invisible,p.omitted.capacity,Preview.MAX_CONTEXT,Preview.QUERY_LIMIT,Preview.RADIUS))
			local scope=label(assembly,"Primitive context / no clearance check",20,C.muted)
			ui.tip(scope,"Only Part, WedgePart and CornerWedgePart geometry without child meshes is shown. Meshes, unions, trusses and other shapes are omitted. Appearance is simplified; no collision or clearance check is performed.")
		end
		local stats="Start and End required"
		if plan then
			local m=plan.metrics
			local depths={}; for _,value in ipairs(m.actualTreadDepths) do table.insert(depths,string.format("%.2f",value)) end
			stats=string.format("Proposed: %d steps / %d parts\nRise %.2f / run %.2f\nRiser %.3f / tread %s\n%d landings / %d supports\n%d rail segments / %d posts",m.stepCount,m.totalGeneratedParts,m.rise,m.pathRun,m.actualRiserHeight,#depths>0 and table.concat(depths," / ") or "-",m.landingCount,m.supportCount,m.railSegmentCount,m.railPostCount)
			if state.target then stats=string.format("Existing: %d parts\n",state.preview.existingCount)..stats end
		end
		local metrics=label(assembly,stats,nil,C.muted); metrics.Name="AssemblyMetrics"
		local status=label(footer,state.message~="" and state.message or "Preview required",36,state.failed and C.error or C.muted); status.Name="PreviewStatus"; ui.tip(status,state.message)
		local commands = row(footer, 2, 34)
		ui.button(commands, "PreviewAction", "Preview", act(function() updatePreview(); state.page="Preview" end),not state.plan and "primary" or nil)
		local actionName=state.target and "Regenerate" or "Build"
		local build=ui.button(commands, "BuildAction", state.confirm and (root.AbsoluteSize.X<400 and "Confirm" or "Confirm "..actionName) or actionName, act(function()
			assert(state.plan, "Preview valid geometry first.")
			assert(state.preview and Preview.isCurrent(state.preview),"Context changed. Preview again.")
			if not state.confirm then state.confirm = true; state.message = "Confirm " .. state.plan.count .. " parts"; return end
			local model = Engine.apply(state.plan, history)
			state.target = model; invalidate(); selection:Set({ model }); state.message = "Built " .. model.Name
			updatePreview(); state.message = "Built " .. model.Name
		end), state.plan and "primary" or nil)
		build.Active=state.plan~=nil
		if not state.plan then build.TextColor3=C.muted end
		rendering = false
	end
	local undo = history.OnUndo:Connect(function() invalidate(); state.message = "Undo complete. Preview or Edit Existing to continue."; render() end)
	local redo = history.OnRedo:Connect(function() invalidate(); state.message = "Redo complete. Preview or Edit Existing to continue."; render() end)
	render()
	local resized=root:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	local theme=settings().Studio.ThemeChanged:Connect(function() ui.theme(); render() end)
	-- Engine freshness also covers ownership/metadata changes, beyond endpoint events.
	task.spawn(function()
		while not disposed do
			task.wait(0.5)
			if not disposed and state.plan and (not Engine.isFresh(state.plan) or not Preview.isCurrent(state.preview)) then
				invalidate(); state.message="Preview stale. Preview again."; render()
			end
		end
	end)
	return function()
		disposed = true; undo:Disconnect(); redo:Disconnect()
		if state.preview then state.preview.model:Destroy() end
		for _, c in ipairs(state.watches) do c:Disconnect() end
		resized:Disconnect(); theme:Disconnect(); root:Destroy()
	end
end

return View
