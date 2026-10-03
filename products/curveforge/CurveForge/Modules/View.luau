local Engine = require(script.Parent.Engine)
local Settings = require(script.Parent.Settings)
local UI = require(script.Parent.StudioUI)
local ContextPreview = require(script.Parent.ContextPreview)
local View = {}
local function el(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props) do item[key] = value end
	item.Parent = parent; return item
end

function View.mount(widget, selection, history)
	local state = { controls = {}, settings = table.clone(Settings.defaults), confirmed = false, message = "Create a path or edit an existing output.", watches = {}, page = "Path", comparison = "Proposed", scroll = {} }
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
	local function invalidate(reason)
		state.plan = nil
		state.success = false
		state.message = type(reason)=="string" and reason or "Preview stale. Refresh to review changes."
		if state.snapshot then state.snapshot.model:Destroy(); state.snapshot=nil end
		local view = root:FindFirstChild("GeometryPreview", true); if view then view:Destroy() end
		local build = root:FindFirstChild("BuildAction", true); if build then ui.disable(build) end
		local status = root:FindFirstChild("PreviewStatus", true); if status then status.Text=state.message; status.TextColor3=colors.warning end
		local previewAction = root:FindFirstChild("PreviewAction", true); if previewAction then previewAction.BackgroundTransparency=0; previewAction.BackgroundColor3=colors.accent; previewAction.TextColor3=Color3.new(1,1,1) end
	end
	local function act(fn)
		return function()
			state.failed = false
			local ok, err = pcall(fn)
			if not ok then invalidate(); state.message = tostring(err):gsub("^.-:%d+: ", ""); state.failed = true end
			render()
		end
	end
	preview = function()
		invalidate("Preparing preview")
		assert(state.confirmed, "Confirm the displayed point order first.")
		local plan = Engine.plan(state.controls, state.settings, state.source, state.rotation)
		state.snapshot = ContextPreview.create(plan, state.target)
		state.plan, state.comparison, state.failed = plan, "Proposed", false
		state.message = state.target and ("Ready to regenerate " .. state.target.Name) or "Ready to build from this path"
		watch()
	end
	local function changed()
		invalidate(); generation += 1
		local stamp = generation
		task.defer(function()
			if disposed or stamp ~= generation then return end
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
			for _, p in ipairs(list) do
				table.insert(state.watches, p.Changed:Connect(changed))
				table.insert(state.watches, p.AttributeChanged:Connect(changed))
			end
			table.insert(state.watches, state.source.DescendantAdded:Connect(function() watch(); changed() end))
			table.insert(state.watches, state.source.DescendantRemoving:Connect(changed))
		end
		if state.target then
			table.insert(state.watches, state.target:GetPropertyChangedSignal("Name"):Connect(changed))
			table.insert(state.watches, state.target.AncestryChanged:Connect(changed))
			table.insert(state.watches, state.target.DescendantAdded:Connect(changed))
			table.insert(state.watches, state.target.DescendantRemoving:Connect(changed))
			for _, item in ipairs(state.target:GetDescendants()) do
				table.insert(state.watches, item.Changed:Connect(changed))
				table.insert(state.watches, item.AttributeChanged:Connect(changed))
			end
		end
		for _, part in ipairs(state.snapshot and state.snapshot.sources or {}) do
			table.insert(state.watches, part.Changed:Connect(changed))
			table.insert(state.watches, part.AncestryChanged:Connect(changed))
			table.insert(state.watches, part.DescendantAdded:Connect(changed))
			table.insert(state.watches, part.DescendantRemoving:Connect(changed))
			for _, child in ipairs(part:GetDescendants()) do table.insert(state.watches,child.Changed:Connect(changed)) end
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
			button(r, option, act(function()
				state.settings[key] = option; invalidate()
				if key=="Mode" and option=="Repeat" and not state.source then
					state.page="Output"; state.message="Select a source model for Repeat."
				elseif state.confirmed then preview() end
			end), state.settings[key] == option)
		end
	end
	render = function()
		if disposed then return end
		if state.plan then
			local fresh=pcall(Engine.check,state.plan)
			if not fresh then invalidate() end
		end
		if rail then state.scroll[rail:GetAttribute("Page")] = rail.CanvasPosition end
		if state.snapshot then state.snapshot.model.Parent=nil end
		root:ClearAllChildren()
		local wide = root.AbsoluteSize.X >= 520
		local compact = root.AbsoluteSize.Y < 440
		local bodyTop, bodyReserved = compact and 136 or 170, compact and 206 or 268
		ui.header("CurveForge", state.target and state.target.Name or "Untitled path", #state.controls .. " points  /  " .. state.settings.Mode .. " output" .. (state.target and "  /  Editing" or ""), compact)
		local modebar=el("Frame",root,{Name="OutputMode",Position=UDim2.fromOffset(12,compact and 64 or 92),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
		choose(modebar,"Mode",{"Cable","Repeat"})
		local nav=el("Frame",root,{Position=UDim2.fromOffset(12,compact and 102 or 130),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
		local navrow=row(nav,wide and 2 or 3)
		for _,page in ipairs(wide and {"Path","Output"} or {"Path","Output","Preview"}) do button(navrow,page,act(function() state.page=page end),state.page==page or (wide and page=="Path" and state.page=="Preview")) end
		rail=ui.scroll(root,"PointRail",UDim2.fromOffset(12,bodyTop),wide and UDim2.new(0,174,1,-bodyReserved) or UDim2.new(1,-24,1,-bodyReserved))
		rail:SetAttribute("Page",state.page)
		work=el("Frame",root,{Name="PathWorkspace",BackgroundTransparency=1,Position=wide and UDim2.fromOffset(202,bodyTop) or UDim2.fromOffset(12,bodyTop),Size=wide and UDim2.new(1,-214,1,-bodyReserved) or UDim2.new(1,-24,1,-bodyReserved)})
		rail.Visible=wide or state.page~="Preview"; work.Visible=wide or state.page=="Preview"
		body=rail
		footer=el("Frame",root,{Name="Commands",BackgroundTransparency=1,Position=UDim2.new(0,12,1,compact and -62 or -90),Size=UDim2.new(1,-24,0,compact and 60 or 82)})
		ui.stack(footer,6)
		local status=label(footer,state.message~="" and state.message or "Preview required",12,state.failed and colors.error or colors.muted,compact and 20 or 36)
		status.Name="PreviewStatus"; status.TextWrapped=not compact; status.TextTruncate=compact and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
		if state.page~="Output" then
		ui.section(body,"EDITABLE PATH")
		local actions = body
		button(actions, "New Path", act(function()
			invalidate(); state.selected=nil
			local camera = workspace.CurrentCamera
			state.controls = Engine.newPath(history, camera and (camera.CFrame.Position + camera.CFrame.LookVector * 25) or Vector3.new(0, 5, 0))
			state.confirmed, state.target, state.rotation = true, nil, nil
			watch(); preview(); selection:Set(state.controls)
		end))
		button(body, "Edit Existing", act(function()
			local list = selection:Get(); assert(#list == 1, "Select one CurveForge output model.")
			local plan = Engine.load(list[1]); invalidate()
			state.controls, state.settings, state.source, state.rotation = plan.controls, table.clone(plan.settings), plan.source, plan.rotation
			state.target, state.confirmed, state.selected = list[1], true, 1
			preview()
		end))
		ui.rule(body)
		button(actions, "Use selected points", act(function()
			local list = selection:Get()
			assert(#list >= 2 and #list <= 8, "Select 2 to 8 BaseParts.")
			for _, p in ipairs(list) do assert(p:IsA("BasePart") and p:IsDescendantOf(workspace), "Select BaseParts in Workspace only.") end
			state.controls, state.confirmed, state.target, state.rotation, state.selected = table.clone(list), false, nil, nil, 1
			invalidate("Confirm the displayed point order."); watch()
		end))
		for i, p in ipairs(state.controls) do
			local pointButton = button(body, tostring(i) .. "   " .. p.Name, act(function() state.selected=i; selection:Set({ p }) end),state.selected==i)
			pointButton.TextWrapped = false; pointButton.TextTruncate = Enum.TextTruncate.AtEnd
			pointButton.TextXAlignment=Enum.TextXAlignment.Left; ui.tip(pointButton,p:GetFullName())
			if state.selected==i then
				local r=row(body,3,30)
				local up=button(r,"\u{2191}",act(function() if i>1 then state.controls[i],state.controls[i-1]=state.controls[i-1],p; state.selected=i-1 end; state.confirmed=false; state.rotation=nil; invalidate() end)); ui.tip(up,"Move point earlier")
				local down=button(r,"\u{2193}",act(function() if i<#state.controls then state.controls[i],state.controls[i+1]=state.controls[i+1],p; state.selected=i+1 end; state.confirmed=false; state.rotation=nil; invalidate() end)); ui.tip(down,"Move point later")
				local remove=button(r,"\u{00D7}",act(function() table.remove(state.controls,i); state.selected=nil; state.confirmed=false; invalidate(); watch() end)); ui.tip(remove,"Remove from path")
			end
		end
		if #state.controls > 0 and not state.confirmed then button(body, "Confirm displayed order", act(function() state.confirmed = true; preview() end), true) end
		ui.rule(body)
		if #state.controls==0 then label(body,"2-8 ordered points shape a cable or your own repeated model.",13,colors.muted) end
		else
		ui.section(body,state.settings.Mode=="Cable" and "CABLE FINISH" or "REPEATED MODEL")
		toggle(body, "ControlRoll", "Control-point roll guides")
		if state.settings.Mode == "Cable" then
			input(body, "Diameter", "Diameter (studs)"); input(body, "SegmentLength", "Segment length")
			local swatches
			for index, rgb in ipairs({ {52,179,161}, {61,65,73}, {234,187,65}, {221,91,73}, {199,206,211}, {69,139,213} }) do
				if index%3==1 then swatches=row(body,3) end
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
		local snapshot=state.snapshot
		local reviewPlan=state.plan or state.completedPlan
		local short=root.AbsoluteSize.Y-bodyReserved<220
		local mode=label(work,state.success and "Built output" or (state.comparison .. " output"),16,colors.text,24); mode.Font=Enum.Font.BuilderSansBold
		mode.Visible=not compact
		local comparison=el("Frame",work,{Name="Comparison",Position=UDim2.fromOffset(0,compact and 0 or 30),Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
		local comparisons=row(comparison,2)
		for _, value in ipairs({"Existing","Proposed"}) do
			local b=button(comparisons,value,act(function() state.comparison=value end),state.comparison==value)
			if not snapshot or (value=="Existing" and not snapshot.existingAvailable) then ui.disable(b) end
		end
		local top=compact and (state.target and 36 or 0) or (state.target and 66 or 30)
		comparison.Visible=state.target~=nil
		local previewHost=el("Frame",work,{Name="PreviewSurface",Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,1,-top-(short and 0 or 70)),BackgroundColor3=colors.viewport,BorderSizePixel=0,ClipsDescendants=true})
		if snapshot then
			local ok, err = pcall(function()
				ContextPreview.show(snapshot,state.comparison)
				ui.viewport(previewHost,snapshot.model,snapshot,reviewPlan.positions,state.selected)
			end)
			if not ok then invalidate(); snapshot=nil; state.failed=true; status.Text=tostring(err):gsub("^.-:%d+: ", ""); status.TextColor3=colors.error end
		else
			local empty=label(previewHost,state.failed and "Preview unavailable" or "Preview required",13,colors.muted,30); empty.Position=UDim2.new(0,12,0.5,-15); empty.Size=UDim2.new(1,-24,0,30)
		end
		local estimates=snapshot and reviewPlan and reviewPlan.estimates
		local count=estimates and (state.settings.Mode=="Cable" and estimates.segmentCount or estimates.copyCount)
		local metricText=estimates and string.format("%.1f studs  /  %d %s",estimates.pathLength,count,state.settings.Mode=="Cable" and "segments" or "copies") or "No current output estimate"
		if estimates and state.comparison=="Existing" and not state.success then metricText="Proposed: "..metricText end
		local metrics=label(work,metricText,14,colors.text,24)
		metrics.Name="OutputMetrics"; metrics.Font=Enum.Font.BuilderSansMedium; metrics.Position=UDim2.new(0,0,1,-66); metrics.Visible=not short
		local source=label(work,state.settings.Mode=="Repeat" and (state.source and ("Source: "..state.source.Name) or "Select your source in Output") or (#state.controls.." ordered control points"),12,colors.muted,20)
		source.Position=UDim2.new(0,0,1,-42); source.Visible=not short
		if state.source then ui.tip(source,state.source:GetFullName()) end
		local contextText=snapshot and (snapshot.queryAvailable and ("Nearby snapshot: "..snapshot.contextCount.." parts"..((snapshot.limited or snapshot.skipped>0) and " (limited)" or "")) or "Nearby unavailable: controls only") or ""
		if snapshot and state.target and not snapshot.existingAvailable then contextText="Existing unavailable; proposed only" end
		local context=label(work,contextText,12,colors.muted,20); context.Position=UDim2.new(0,0,1,-20); context.Visible=not short
		if short and estimates then
			status.Text=(state.success and "Built: " or "")..metricText
			if not snapshot.queryAvailable or snapshot.limited or snapshot.skipped>0 or (state.target and not snapshot.existingAvailable) then status.Text..="\n"..contextText end
		end
		if compact then ui.tip(status,status.Text) end
		local actions2 = row(footer, 2,34)
		ui.button(actions2,"PreviewAction",state.plan and "Refresh" or "Preview",act(function() preview(); if not wide then state.page="Preview" end end),not state.plan and "primary" or nil)
		local build=ui.button(actions2, "BuildAction", (state.target and "Regenerate" or "Build") .. (state.plan and (" "..tostring(count)) or ""), act(function()
			assert(state.plan, "Preview a valid path first.")
			for _, c in ipairs(state.watches) do c:Disconnect() end; state.watches={}
			local model = Engine.apply(state.plan, history, state.target)
			state.target, state.rotation = model, state.plan.rotation
			invalidate(); selection:Set({ model })
			state.completedPlan=Engine.load(model)
			state.snapshot=ContextPreview.create(state.completedPlan,model)
			state.comparison,state.success="Existing",true
			state.message="Built "..tostring(count)..(state.settings.Mode=="Cable" and " segments." or " copies.").." Studio Undo available."
			watch()
		end), state.plan and "primary" or nil)
		if not state.plan then ui.disable(build) end
		rail.CanvasPosition=state.scroll[state.page] or Vector2.zero
	end
	render()
	local resized=root:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	local theme=settings().Studio.ThemeChanged:Connect(function() ui.theme(); colors.panel=colors.field; render() end)
	local undo=history.OnUndo:Connect(function() invalidate(); state.message="Undo complete. Preview required."; render() end)
	local redo=history.OnRedo:Connect(function() invalidate(); state.message="Redo complete. Preview required."; render() end)
	return function() disposed = true; resized:Disconnect(); theme:Disconnect(); undo:Disconnect(); redo:Disconnect(); for _, c in ipairs(state.watches) do c:Disconnect() end; if state.snapshot then state.snapshot.model:Destroy() end; root:Destroy() end
end
return View
