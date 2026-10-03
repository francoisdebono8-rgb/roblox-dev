local Schema = require(script.Parent.Schema)
local Graph = require(script.Parent.Graph)
local Planner = require(script.Parent.Planner)
local Transaction = require(script.Parent.Transaction)
local UI = require(script.Parent.StudioUI)
local View = {}


local function element(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props or {}) do item[key] = value end
	item.Parent = parent
	return item
end


local function path(item)
	return if item and item.Parent then item:GetFullName() else "Not assigned"
end

function View.mount(widget, selection, history)
	local state = { tab = "Create", class = "WeldConstraint", entries = {}, inspected = {}, checked = {}, drafts = {}, message = "Choose endpoint parts to begin.", plan = nil, detailSection = "Properties" }
	local root = element("Frame", widget, { Name = "JointForgeUI", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants=true })
	local ui=UI.new(root,Color3.fromRGB(215,122,62)); local colors=ui.colors; colors.panel=colors.field
	local label,row,stack=ui.label,ui.row,ui.stack
	local function button(parent,text,fn,primary)
		return ui.button(parent,text,text,fn,primary and "selected" or nil)
	end
	local body, commands, previewButton, disposed
	local render
	local function invalidate()
		if state.plan then Planner.invalidate(state.plan) end
		state.plan = nil
		state.confirm = false
		state.batchConflicts=nil
		local apply=root:FindFirstChild("ApplyAction",true); if apply then apply:Destroy() end
	end
	local function act(fn)
		return function()
			local ok, err = pcall(fn)
			if not ok then state.message = tostring(err):gsub("^.-:%d+: ", ""); state.failed = true end
			render()
		end
	end
	local function one(class)
		local list = selection:Get()
		assert(#list == 1 and list[1]:IsA(class), "Select exactly one " .. class .. " in Explorer or the viewport.")
		assert(list[1]:IsDescendantOf(workspace), "Selection must be inside Workspace.")
		return list[1]
	end
	local function setMessage(text)
		state.message, state.failed = text, false
	end
	local function preview(request)
		state.plan = Planner.preview(workspace, request)
		state.confirm = false
		setMessage(if #state.plan.errors == 0 then "Preview ready. Review every operation before Apply." else "Preview blocked. Existing objects will be preserved.")
	end
	local function choose(parent, current, options, callback)
		local opened = false
		local container = element("Frame", parent, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		stack(container)
		local menu
		button(container, current .. "  v", function()
			opened = not opened
			if menu then menu:Destroy(); menu = nil end
			if opened then
				menu = element("Frame", container, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
				stack(menu)
				for _, value in ipairs(options) do button(menu, tostring(value), act(function() callback(value) end)) end
			end
		end)
	end
	local function identity(parent, item, fallback)
		local title=label(parent,item and item.Name or fallback,17,colors.text,28); title.Font=Enum.Font.BuilderSansBold
		if item then ui.tip(title,path(item)) end
		return title
	end
	local function endpoint(parent,index)
		local key = if index == 0 then "a" else "b"
		local attachmentKey = "attachment" .. index
		ui.section(parent,"PART "..index)
		identity(parent,state[key],"Not assigned")
		label(parent,state[key] and state[key].ClassName or "BasePart",12,colors.muted,20)
		local actions = row(parent, 2)
		button(actions, "Assign", act(function() state[key] = one("BasePart"); state[attachmentKey] = nil; invalidate() end))
		button(actions, "Locate", act(function() assert(state[key], "Assign this endpoint first."); selection:Set({ state[key] }) end))
		if Schema.usesAttachments(state.class) then
			label(parent, "Attachment " .. index,12,colors.muted,20)
			local attachment=label(parent,state[attachmentKey] and state[attachmentKey].Name or "New on Apply",13,colors.text,22)
			if state[attachmentKey] then ui.tip(attachment,path(state[attachmentKey])) end
			local attachments = row(parent, 2)
			local assign=button(attachments, "Assign", act(function()
				local a = one("Attachment")
				assert(a.Parent:IsA("BasePart"), "Use an attachment directly under a BasePart.")
				state[key], state[attachmentKey] = a.Parent, a
				invalidate()
			end))
			ui.tip(assign,"Use selected attachment")
			button(attachments, "New", act(function() state[attachmentKey] = nil; invalidate() end))
		end
	end
	local function showPreview()
		local plan = state.plan
		if not plan then return end
		ui.section(body,"EXACT PLAN  /  " .. #plan.operations .. " OPERATIONS")
		for _, err in ipairs(plan.errors) do label(body, "BLOCKED: " .. err, 14, colors.error) end
		for _, warning in ipairs(plan.warnings) do label(body, "NOTE: " .. warning, 14, colors.muted) end
		for _, op in ipairs(plan.operations) do
			if op.kind == "create" then
				label(body,op.class,15)
				local pair=label(body,op.a.Name .. "  \u{2194}  " .. op.b.Name,13,colors.muted)
				ui.tip(pair,path(op.a).." -> "..path(op.b))
				if Schema.usesAttachments(op.class) then
					label(body, "A0: " .. (op.attachment0 and path(op.attachment0) or "NEW") .. " | A1: " .. (op.attachment1 and path(op.attachment1) or "NEW"), 14, colors.muted)
				end
			elseif op.kind == "reassign" then
				label(body, "Reassign " .. path(op.joint))
				local function replacement(index)
					if not op.attachments then return path(index == 1 and op.a or op.b) end
					local spec = op.attachments[index]
					return spec.existing and path(spec.existing) or ("NEW " .. path(spec.part) .. "." .. spec.name)
				end
				label(body, "0: " .. path(op.old0) .. " -> " .. replacement(1) .. "\n1: " .. path(op.old1) .. " -> " .. replacement(2), 14, colors.muted)
				label(body, op.preservePose and "Preserve world pose" or "Raw frames: assembly may move", 14, colors.muted)
			elseif op.kind == "edit" then
				label(body, "Edit " .. path(op.joint))
				for field, value in pairs(op.changes) do label(body, field .. ": " .. Schema.format(op.joint[field]) .. " -> " .. Schema.format(value), 14, colors.muted) end
			else label(body, "Remove " .. path(op.joint), 15, colors.error) end
		end
		if #plan.errors > 0 then return end
		if plan.request.kind == "remove" then
			button(body, (state.confirm and "[x]" or "[ ]") .. " I confirm removal of these " .. #plan.operations .. " joints only", act(function() state.confirm = not state.confirm end))
		end
		ui.button(commands, "ApplyAction", "Apply " .. #plan.operations, act(function()
			local result = Transaction.apply(plan, history, state.confirm)
			invalidate()
			state.drafts = {}
			setMessage("Applied. Use Studio Undo once to restore the previous state.")
			if #result > 0 then selection:Set(result) end
		end), "primary")
	end
	local function editForm(joint)
		if not joint or not joint:IsDescendantOf(workspace) then return end
		identity(body,joint,"Joint")
		label(body,joint.ClassName,12,colors.muted)
		local _, _, a, b = Graph.endpoints(joint)
		local pair=label(body,(a and a.Name or "Missing") .. "  \u{2194}  " .. (b and b.Name or "Missing"),14,colors.text)
		ui.tip(pair,path(a).." -> "..path(b))
		local actions = row(body, 3)
		for index, item in pairs({ [0] = a, [1] = b }) do
			button(actions, "Select " .. index, act(function() selection:Set({ item }) end))
		end
		button(actions, "Locate joint", act(function() selection:Set({ joint }) end))
		if not Schema.supported(joint) then label(body, "Inspect-only class. Edit its properties in Studio.", 14, colors.muted); return end
		local sections=row(body,2)
		for _,name in ipairs({"Properties","Endpoints"}) do button(sections,name,act(function() state.detailSection=name end),state.detailSection==name) end
		ui.rule(body)
		state.reassign = state.reassign or {}
		if state.detailSection=="Endpoints" then
		for index = 0, 1 do
			local key = "endpoint" .. index
			local value = state.reassign[key]
			label(body, "New endpoint " .. index .. ": " .. (value and path(typeof(value) == "Instance" and value or value.part) or "Keep current"), 14, colors.muted)
			button(body, "Assign selected " .. (Schema.usesAttachments(joint.ClassName) and "attachment" or "part") .. " to " .. index, act(function()
				state.reassign[key] = one(Schema.usesAttachments(joint.ClassName) and "Attachment" or "BasePart"); invalidate()
			end))
			if Schema.usesAttachments(joint.ClassName) then
				button(body, "Create attachment " .. index .. " at selected part", act(function()
					local p = one("BasePart")
					state.reassign[key] = { create = true, part = p, worldCFrame = p.CFrame }; invalidate()
				end))
			end
		end
		button(body, (state.rawPose and "[x]" or "[ ]") .. " Raw frames (may move parts)", act(function() state.rawPose = not state.rawPose; invalidate() end))
		button(body, "Preview explicit endpoint reassignment", act(function()
			preview({ kind = "reassign", joint = joint, endpoint0 = state.reassign.endpoint0, endpoint1 = state.reassign.endpoint1, poseMode = state.rawPose and "raw" or "preserve" })
		end))
		else
		if joint:IsA("Weld") or joint:IsA("Motor6D") then label(body, "C0 / C1: X Y Z RX RY RZ. Rotations in degrees. Editing or resetting offsets can move parts.", 14, colors.muted) end
		local readers = {}
		for _, field in ipairs(Schema.fields[joint.ClassName]) do
			local sample = joint[field]
			local value = state.drafts[field]
			if value == nil then value = sample end
			label(body, field, 14, colors.muted)
			if typeof(sample) == "boolean" then
				button(body, (value and "[x] " or "[ ] ") .. field, act(function() state.drafts[field] = not value; invalidate() end))
			elseif typeof(sample) == "EnumItem" then
				choose(body, value.Name, { "None", "Motor", "Servo" }, function(v) state.drafts[field] = Enum.ActuatorType[v]; invalidate() end)
			else
				local input = element("TextBox", body, { Name = field, Text = if type(value) == "string" then value else Schema.format(value), ClearTextOnFocus = false, Font = Enum.Font.BuilderSans, TextSize = 13, TextColor3 = colors.text, BackgroundColor3 = colors.field, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, if typeof(sample) == "CFrame" then 50 else 32), TextWrapped = true })
				readers[field] = function() return Schema.parse(input.Text, sample) end
				input:GetPropertyChangedSignal("Text"):Connect(function() state.drafts[field] = input.Text; invalidate() end)
				if typeof(sample) == "CFrame" then
					button(body, "Reset " .. field .. " to identity (preview only)", act(function() state.drafts[field] = CFrame.identity; invalidate() end))
				end
			end
		end
		button(body, "Preview field changes", act(function()
			local changes = {}
			for field, value in pairs(state.drafts) do
				local parsed = if readers[field] then readers[field]() else value
				if parsed ~= joint[field] then changes[field] = parsed end
			end
			preview({ kind = "edit", joint = joint, changes = changes })
		end))
		end
	end

	render = function()
		if disposed then return end
		root:ClearAllChildren()
		local wide=root.AbsoluteSize.X>=520
		local context=state.tab=="Create" and "New connection" or state.tab=="Batch" and "Assembly connections" or state.editing and state.editing.Name or "Joint inspector"
		ui.header("JointForge",context,state.tab=="Create" and state.class or state.tab=="Batch" and (#state.entries.." parts") or (#state.inspected.." joints / constraints"))
		local nav=element("Frame",root,{Position=UDim2.fromOffset(12,92),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
		local tabs=row(nav,3)
		for _,name in ipairs({"Create","Batch","Inspect"}) do button(tabs,name,act(function() state.tab=name; invalidate(); setMessage(name.." workflow") end),state.tab==name) end
		local workflow=ui.scroll(root,"Workflow",UDim2.fromOffset(12,132),UDim2.new(1,-24,1,-232)); body=workflow
		local footer=element("Frame",root,{Name="Commands",BackgroundTransparency=1,Position=UDim2.new(0,12,1,-90),Size=UDim2.new(1,-24,0,82)}); stack(footer,6)
		local message=label(footer,state.message,12,state.failed and colors.error or colors.muted,36); ui.tip(message,state.message)
		commands=row(footer,2,34)
		previewButton=nil
		if state.tab == "Create" then
			choose(body, state.class, Schema.types, function(value) state.class = value; invalidate() end)
			if wide then
				local pair=element("Frame",body,{Name="EndpointPair",BackgroundTransparency=1,Size=UDim2.new(1,0,0,Schema.usesAttachments(state.class) and 234 or 134)})
				for i=0,1 do
					local region=element("Frame",pair,{Name="Part"..i,BackgroundTransparency=1,Position=UDim2.new(i/2,i==1 and 12 or 0,0,0),Size=UDim2.new(0.5,-12,1,0)})
					stack(region,4); endpoint(region,i)
				end
				local divider=element("Frame",pair,{Position=UDim2.new(0.5,0,0,8),Size=UDim2.new(0,1,1,-16),BackgroundColor3=colors.line,BorderSizePixel=0})
			else endpoint(body,0); ui.rule(body); endpoint(body,1) end
			ui.rule(body)
			previewButton=button(commands,"Preview",act(function() preview({ kind = "create", class = state.class, a = state.a, b = state.b, attachment0 = state.attachment0, attachment1 = state.attachment1 }) end))
		elseif state.tab == "Batch" then
			ui.section(body,"ROOT")
			identity(body,state.root,"Not assigned")
			button(body, "Use selected part as root", act(function() state.root = one("BasePart"); invalidate() end))
			local modes = row(body, 2)
			for _, mode in ipairs({ "Static", "Moving" }) do
				button(modes, "Assign selection: " .. mode, act(function()
					local parts = selection:Get()
					assert(#parts > 0, "Select at least one part.")
					for _, p in ipairs(parts) do assert(p:IsA("BasePart") and p:IsDescendantOf(workspace) and p ~= state.root, "Select BaseParts only, excluding the root.") end
					for _, p in ipairs(parts) do
						local found = false
						for _, entry in ipairs(state.entries) do if entry.part == p then entry.mode = mode; found = true end end
						if not found then table.insert(state.entries, { part = p, mode = mode }) end
					end
					invalidate()
				end))
			end
			ui.rule(body)
			ui.section(body,"PARTS  /  PLANNED CONNECTION")
			for i, entry in ipairs(state.entries) do
				local item=element("Frame",body,{Name="BatchRow",BackgroundTransparency=1,Size=UDim2.new(1,0,0,60)})
				local part=button(item,entry.part.Name,act(function() selection:Set({entry.part}) end)); part.Size=UDim2.new(1,-114,0,28); part.TextXAlignment=Enum.TextXAlignment.Left; ui.tip(part,path(entry.part))
				local role=button(item,entry.mode,act(function() entry.mode=entry.mode=="Static" and "Moving" or "Static"; invalidate() end),true); role.Position=UDim2.new(1,-108,0,0); role.Size=UDim2.fromOffset(78,28)
				local remove=button(item,"\u{00D7}",act(function() table.remove(state.entries,i); invalidate() end)); remove.Position=UDim2.new(1,-26,0,0); remove.Size=UDim2.fromOffset(26,28); ui.tip(remove,"Remove from batch")
				local connection=label(item,entry.mode=="Moving" and "Motor6D" or "WeldConstraint",12,colors.muted,24); connection.Position=UDim2.fromOffset(0,30)
				if state.batchConflicts and state.batchConflicts[entry.part] then connection.Text=state.batchConflicts[entry.part]; connection.TextColor3=colors.error; ui.tip(connection,connection.Text) end
			end
			previewButton=button(commands,"Preview",act(function()
				preview({ kind = "batch", root = state.root, entries = state.entries })
				state.batchConflicts={}
				-- Presentation-only per-row diagnostics from the same bounded graph API.
				local ok,index=pcall(Graph.build,workspace)
				if ok then for _,entry in ipairs(state.entries) do
					for _,edge in ipairs(index.adjacency[entry.part] or {}) do
						if not edge.noCollision then state.batchConflicts[entry.part]="Existing physical connection"; break end
					end
				end end
			end))
		else
			if wide then workflow.Size=UDim2.new(0,180,1,-232) end
			workflow.Visible=wide or not state.editing
			button(body, "Scan selection", act(function()
				state.inspected = Graph.inspect(workspace, selection:Get())
				state.checked, state.drafts, state.editing = {}, {}, nil
				invalidate(); setMessage(#state.inspected .. " joints / constraints found.")
			end), true)
			for _, info in ipairs(state.inspected) do
				local joint = info.joint
				if joint:IsDescendantOf(workspace) then
					local item=button(body,joint.Name,act(function() state.editing=joint; state.drafts={}; state.reassign={}; state.rawPose=false; invalidate() end),state.editing==joint)
					item.TextXAlignment=Enum.TextXAlignment.Left; ui.tip(item,path(joint))
					label(body,(info.broken and "Broken / " or "")..joint.ClassName,12,info.broken and colors.error or colors.muted)
					ui.toggle(body,"Remove"..joint.Name,"Remove",state.checked[joint],act(function() state.checked[joint] = not state.checked[joint]; invalidate() end))
					ui.rule(body)
				end
			end
			button(body, "Preview checked removals", act(function()
				local joints = {}
				for joint, checked in pairs(state.checked) do if checked then table.insert(joints, joint) end end
				preview({ kind = "remove", joints = joints })
			end))
			if wide or state.editing then
				body=ui.scroll(root,"JointDetail",wide and UDim2.fromOffset(208,132) or UDim2.fromOffset(12,132),wide and UDim2.new(1,-220,1,-232) or UDim2.new(1,-24,1,-232))
				if not wide then button(body,"\u{2190} Joints",act(function() state.editing=nil end)) end
				if state.editing then editForm(state.editing) else label(body,"Select a joint",17,colors.muted) end
			end
		end
		showPreview()
	end
	render()
	local connections = {
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(render),
		settings().Studio.ThemeChanged:Connect(function() ui.theme(); colors.panel=colors.field; render() end),
		selection.SelectionChanged:Connect(function()
			if state.plan then invalidate(); setMessage("Selection changed. Preview again before Apply."); render() end
		end),
		history.OnUndo:Connect(function() invalidate(); state.drafts = {}; setMessage("Undo completed. Refresh Inspect or Preview again."); render() end),
		history.OnRedo:Connect(function() invalidate(); state.drafts = {}; setMessage("Redo completed. Refresh Inspect or Preview again."); render() end),
	}
	return function()
		disposed=true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		root:Destroy()
	end
end

return View
