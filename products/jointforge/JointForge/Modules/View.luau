local Schema = require(script.Parent.Schema)
local Graph = require(script.Parent.Graph)
local Planner = require(script.Parent.Planner)
local Transaction = require(script.Parent.Transaction)
local View = {}

local colors = { bg = Color3.fromRGB(30, 32, 35), panel = Color3.fromRGB(43, 46, 50), text = Color3.fromRGB(239, 241, 243), muted = Color3.fromRGB(174, 182, 191), accent = Color3.fromRGB(54, 171, 149), error = Color3.fromRGB(250, 138, 117) }

local function element(class, parent, props)
	local item = Instance.new(class)
	for key, value in pairs(props or {}) do item[key] = value end
	item.Parent = parent
	return item
end

local function stack(parent)
	return element("UIListLayout", parent, { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder })
end

local function label(parent, text, size, color)
	return element("TextLabel", parent, { Text = text, Font = Enum.Font.SourceSans, TextSize = size or 15, TextColor3 = color or colors.text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
end

local function button(parent, text, fn, primary)
	local b = element("TextButton", parent, { Text = text, Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextWrapped = true, TextColor3 = colors.text, BackgroundColor3 = if primary then colors.accent else colors.panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34), AutoButtonColor = true })
	b.Activated:Connect(fn)
	return b
end

local function row(parent, count)
	local frame = element("Frame", parent, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) })
	element("UIGridLayout", frame, { CellSize = UDim2.new(1 / count, -6 * (count - 1) / count, 1, 0), CellPadding = UDim2.fromOffset(6, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	return frame
end

local function path(item)
	return if item and item.Parent then item:GetFullName() else "Not assigned"
end

function View.mount(widget, selection, history)
	local state = { tab = "Create", class = "WeldConstraint", entries = {}, inspected = {}, checked = {}, drafts = {}, message = "Choose endpoint parts to begin.", plan = nil }
	local root = element("Frame", widget, { Name = "JointForgeUI", BackgroundColor3 = colors.bg, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })
	local header = element("Frame", root, { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 72) })
	stack(header)
	label(header, "JointForge  /  1.0", 22)
	local tabs = row(header, 3)
	local body = element("ScrollingFrame", root, { Name = "Workflow", Position = UDim2.fromOffset(12, 91), Size = UDim2.new(1, -24, 1, -103), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local render
	local function invalidate()
		if state.plan then state.plan.invalidated = true end
		state.plan = nil
		state.confirm = false
	end
	local function act(fn)
		return function()
			local ok, err = pcall(fn)
			if not ok then state.message = tostring(err); state.failed = true end
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
	for _, name in ipairs({ "Create", "Batch", "Inspect" }) do
		button(tabs, name, act(function() state.tab = name; invalidate(); setMessage(name .. " workflow") end))
	end
	local function endpoint(index)
		local key = if index == 0 then "a" else "b"
		local attachmentKey = "attachment" .. index
		label(body, "Part" .. index .. "  " .. path(state[key]), 15)
		local actions = row(body, 2)
		button(actions, "Use selected part", act(function() state[key] = one("BasePart"); state[attachmentKey] = nil; invalidate() end))
		button(actions, "Select Part" .. index, act(function() assert(state[key], "Assign this endpoint first."); selection:Set({ state[key] }) end))
		if Schema.usesAttachments(state.class) then
			label(body, "Attachment" .. index .. ": " .. (state[attachmentKey] and path(state[attachmentKey]) or "Create new on Apply"), 14, colors.muted)
			local attachments = row(body, 2)
			button(attachments, "Use selected attachment", act(function()
				local a = one("Attachment")
				assert(a.Parent:IsA("BasePart"), "Use an attachment directly under a BasePart.")
				state[key], state[attachmentKey] = a.Parent, a
				invalidate()
			end))
			button(attachments, "Create new instead", act(function() state[attachmentKey] = nil; invalidate() end))
		end
	end
	local function showPreview()
		local plan = state.plan
		if not plan then return end
		label(body, "PREVIEW  /  " .. #plan.operations .. " operations", 18)
		for _, err in ipairs(plan.errors) do label(body, "BLOCKED: " .. err, 14, colors.error) end
		for _, warning in ipairs(plan.warnings) do label(body, "NOTE: " .. warning, 14, colors.muted) end
		for _, op in ipairs(plan.operations) do
			if op.kind == "create" then
				label(body, "+ " .. op.class .. "\n" .. path(op.a) .. " -> " .. path(op.b))
				if Schema.usesAttachments(op.class) then
					label(body, "A0: " .. (op.attachment0 and path(op.attachment0) or "NEW") .. " | A1: " .. (op.attachment1 and path(op.attachment1) or "NEW"), 14, colors.muted)
				end
			elseif op.kind == "edit" then
				label(body, "Edit " .. path(op.joint))
				for field, value in pairs(op.changes) do label(body, field .. ": " .. Schema.format(op.joint[field]) .. " -> " .. Schema.format(value), 14, colors.muted) end
			else label(body, "Remove " .. path(op.joint), 15, colors.error) end
		end
		if #plan.errors > 0 then return end
		if plan.request.kind == "remove" then
			button(body, (state.confirm and "[x]" or "[ ]") .. " I confirm removal of these " .. #plan.operations .. " joints only", act(function() state.confirm = not state.confirm end))
		end
		button(body, "Apply " .. #plan.operations .. " operations", act(function()
			local result = Transaction.apply(plan, history, state.confirm)
			invalidate()
			state.drafts = {}
			setMessage("Applied. Use Studio Undo once to restore the previous state.")
			if #result > 0 then selection:Set(result) end
		end), true)
	end
	local function editForm(joint)
		if not joint or not joint:IsDescendantOf(workspace) then return end
		label(body, joint.ClassName .. " / " .. joint.Name, 18)
		local _, _, a, b = Graph.endpoints(joint)
		label(body, "Endpoint 0: " .. path(a) .. "\nEndpoint 1: " .. path(b), 14, colors.muted)
		local actions = row(body, 3)
		for index, item in pairs({ [0] = a, [1] = b }) do
			button(actions, "Select " .. index, act(function() selection:Set({ item }) end))
		end
		button(actions, "Locate joint", act(function() selection:Set({ joint }) end))
		if not Schema.supported(joint) then label(body, "Inspect-only class. Edit its properties in Studio.", 14, colors.muted); return end
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
				local input = element("TextBox", body, { Name = field, Text = if type(value) == "string" then value else Schema.format(value), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = colors.text, BackgroundColor3 = colors.panel, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, if typeof(sample) == "CFrame" then 50 else 32), TextWrapped = true })
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

	render = function()
		body:ClearAllChildren(); stack(body)
		label(body, string.upper(state.tab) .. "  /  SELECT > TYPE > PREVIEW > APPLY", 15, colors.accent)
		label(body, state.message, 14, if state.failed then colors.error else colors.muted)
		if state.tab == "Create" then
			label(body, "Assign each endpoint explicitly. Preview does not change your place.", 14, colors.muted)
			choose(body, state.class, Schema.types, function(value) state.class = value; invalidate() end)
			endpoint(0); endpoint(1)
			if Schema.usesAttachments(state.class) then label(body, "New hinge/ball pivots meet at the midpoint (or the chosen attachment); hinge X axes follow Part0. Other constraints start at part centers. Adjust attachments in Studio for a custom pivot.", 14, colors.muted) end
			button(body, "Preview joint", act(function() preview({ kind = "create", class = state.class, a = state.a, b = state.b, attachment0 = state.attachment0, attachment1 = state.attachment1 }) end), true)
		elseif state.tab == "Batch" then
			label(body, "Choose a root/Handle, then select parts and assign Static or Moving. World poses stay unchanged. Existing connections block Apply.", 14, colors.muted)
			label(body, "Root: " .. path(state.root))
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
			for i, entry in ipairs(state.entries) do
				label(body, path(entry.part) .. "  /  " .. entry.mode)
				local actions = row(body, 2)
				button(actions, "Select part", act(function() selection:Set({ entry.part }) end))
				button(actions, "Remove from batch", act(function() table.remove(state.entries, i); invalidate() end))
			end
			button(body, "Preview assembly", act(function() preview({ kind = "batch", root = state.root, entries = state.entries }) end), true)
		else
			label(body, "Select parts or a model, then scan. Endpoint buttons select objects in Studio. Check joints to remove; removal always needs Preview and confirmation.", 14, colors.muted)
			button(body, "Inspect current selection", act(function()
				state.inspected = Graph.inspect(workspace, selection:Get())
				state.checked, state.drafts, state.editing = {}, {}, nil
				invalidate(); setMessage(#state.inspected .. " joints / constraints found.")
			end), true)
			for _, info in ipairs(state.inspected) do
				local joint = info.joint
				if joint:IsDescendantOf(workspace) then
					label(body, (info.broken and "BROKEN  " or "") .. joint.ClassName .. " / " .. path(joint), 15, if info.broken then colors.error else colors.text)
					label(body, path(info.endpoint0) .. " -> " .. path(info.endpoint1), 14, colors.muted)
					local actions = row(body, 2)
					button(actions, "Inspect / edit", act(function() state.editing = joint; state.drafts = {}; invalidate() end))
					button(actions, (state.checked[joint] and "[x]" or "[ ]") .. " Remove", act(function() state.checked[joint] = not state.checked[joint]; invalidate() end))
				end
			end
			button(body, "Preview checked removals", act(function()
				local joints = {}
				for joint, checked in pairs(state.checked) do if checked then table.insert(joints, joint) end end
				preview({ kind = "remove", joints = joints })
			end))
			editForm(state.editing)
		end
		showPreview()
	end
	render()
	local connections = {
		selection.SelectionChanged:Connect(function()
			if state.plan then invalidate(); setMessage("Selection changed. Preview again before Apply."); render() end
		end),
		history.OnUndo:Connect(function() invalidate(); state.drafts = {}; setMessage("Undo completed. Refresh Inspect or Preview again."); render() end),
		history.OnRedo:Connect(function() invalidate(); state.drafts = {}; setMessage("Redo completed. Refresh Inspect or Preview again."); render() end),
	}
	return function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		root:Destroy()
	end
end

return View
