local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local TweenService, Input = game:GetService("TweenService"), game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local shared = RS:WaitForChild("ForgePlayground")
local Catalog = require(shared:WaitForChild("Catalog"))
local remote = shared:WaitForChild("Request")
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
local WHITE, MUTED = Color3.fromRGB(238, 241, 243), Color3.fromRGB(176, 183, 189)
local BG, SURFACE, CYAN = Color3.fromRGB(24, 26, 29), Color3.fromRGB(47, 50, 55), Color3.fromRGB(62, 220, 205)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior, gui.Parent = "ForgePlayground", false, Enum.ZIndexBehavior.Sibling, player:WaitForChild("PlayerGui")
local function frame(parent, name, size, position, color)
	local f = Instance.new("Frame"); f.Name, f.Size, f.Position = name, size, position or UDim2.new()
	f.BackgroundColor3, f.BorderSizePixel, f.Parent = color or BG, 0, parent; return f
end
local function text(parent, name, value, size, position, fontSize, color)
	local t = Instance.new("TextLabel"); t.Name, t.Text, t.Size, t.Position = name, value, size, position or UDim2.new()
	t.BackgroundTransparency, t.TextSize, t.TextColor3 = 1, fontSize or 14, color or WHITE
	t.Font, t.TextXAlignment, t.TextYAlignment, t.TextWrapped, t.Parent = Enum.Font.Gotham, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, true, parent
	return t
end
local function button(parent, name, label, size, position, fn)
	local b = Instance.new("TextButton"); b.Name, b.Text, b.Size, b.Position = name, label, size, position or UDim2.new()
	b.BackgroundColor3, b.BorderSizePixel, b.TextColor3 = SURFACE, 0, WHITE
	b.Font, b.TextSize, b.AutoButtonColor, b.Parent = Enum.Font.GothamMedium, 13, true, parent
	b.Activated:Connect(fn); return b
end
local function scroll(parent, name, size, position)
	local f = Instance.new("ScrollingFrame"); f.Name, f.Size, f.Position = name, size, position
	f.BackgroundColor3, f.BorderSizePixel, f.ScrollBarThickness = BG, 0, 3
	f.CanvasSize, f.AutomaticCanvasSize, f.Parent = UDim2.new(), Enum.AutomaticSize.Y, parent; return f
end
local function list(parent, padding)
	local l = Instance.new("UIListLayout"); l.Padding, l.SortOrder, l.Parent = UDim.new(0, padding), Enum.SortOrder.LayoutOrder, parent
end
local bar = frame(gui, "Header", UDim2.new(1, 0, 0, 64))
text(bar, "Brand", "FORGE / PLAYGROUND", UDim2.new(1, -132, 0, 26), UDim2.fromOffset(16, 2), 16, CYAN).Font = Enum.Font.GothamBold
local disclosure = text(bar, "Disclosure", "Interactive Forge demonstration.", UDim2.new(1, -132, 0, 30), UDim2.fromOffset(16, 27), 11, MUTED)
local tabs = scroll(gui, "Stations", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 64))
tabs.AutomaticCanvasSize, tabs.CanvasSize, tabs.ScrollingDirection = Enum.AutomaticSize.None, UDim2.fromOffset(700, 0), Enum.ScrollingDirection.X
local panel = scroll(gui, "Controls", UDim2.new(0, 326, 1, -282), UDim2.fromOffset(12, 116))
local content = frame(panel, "Content", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(12, 8))
content.BackgroundTransparency, content.AutomaticSize = 1, Enum.AutomaticSize.Y; list(content, 10)
local order = 0
local function ordered(item) order += 1; item.LayoutOrder = order; return item end
local title = ordered(text(content, "Product", "", UDim2.new(1, 0, 0, 26), nil, 22))
title.Font = Enum.Font.GothamBold
local instruction = ordered(text(content, "Instruction", "", UDim2.new(1, 0, 0, 38), nil, 13, MUTED))
local fields = ordered(frame(content, "Fields", UDim2.new(1, 0, 0, 0)))
fields.AutomaticSize, fields.BackgroundTransparency = Enum.AutomaticSize.Y, 1; list(fields, 6)
local summary = ordered(text(content, "Summary", "Connecting...", UDim2.new(1, 0, 0, 58), nil, 14, CYAN))
local results = ordered(scroll(content, "Findings", UDim2.new(1, 0, 0, 148), UDim2.new()))
list(results, 3)
local inspector = ordered(text(content, "Inspector", "", UDim2.new(1, -4, 0, 0), nil, 12, WHITE))
inspector.AutomaticSize, inspector.TextYAlignment = Enum.AutomaticSize.Y, Enum.TextYAlignment.Top
local send, updateCamera, renderFields, render
local perturb = ordered(button(content, "StaleTest", "Change one target", UDim2.new(1, 0, 0, 36), nil, function() send("perturb") end))
ordered(frame(content, "Spacer", UDim2.new(1, 0, 0, 8))).BackgroundTransparency = 1
local dock = frame(gui, "Actions", UDim2.fromOffset(326, 148), UDim2.new(0, 12, 1, -172))
local id, busy, exploring, state, cameraTween = "access", false, false, nil, nil
local options = {}; for _, key in ipairs(Catalog.order) do options[key] = Catalog.defaults(key) end
local primary = button(dock, "Primary", "Start", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 8), function() send(state and state.canApply and "apply" or "run") end)
local rerun = button(dock, "Rerun", "Preview", UDim2.new(0.63, -16, 0, 34), UDim2.fromOffset(12, 54), function() send("run") end)
local reset = button(dock, "Reset", "Reset", UDim2.new(0.37, -16, 0, 34), UDim2.new(0.63, 4, 0, 54), function() send("reset") end)
local status = text(dock, "Status", "", UDim2.new(1, -24, 0, 54), UDim2.fromOffset(12, 92), 11, MUTED)
local footer = text(gui, "StudioNotice", "The Studio plugin works on your own Roblox projects.", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 1, -22), 10, MUTED)
footer.BackgroundTransparency, footer.BackgroundColor3 = 0, BG
local nav, marks = {}, Instance.new("Folder"); marks.Name, marks.Parent = "PlaygroundHighlights", workspace
local function enabled(b, value)
	b.Active, b.AutoButtonColor, b.TextTransparency = value, value, value and 0 or 0.55
end
local function updateButtons()
	for _, b in ipairs({ primary, rerun, reset, perturb }) do enabled(b, not busy) end
	primary.Text = state and state.canApply and Catalog.stations[id].apply or (state and state.runLabel or Catalog.stations[id].run)
	primary.BackgroundColor3, primary.TextColor3 = Catalog.stations[id].accent, BG
	rerun.Text = state and state.runLabel or Catalog.stations[id].run
	perturb.Visible = id == "preset" and state ~= nil and state.canApply == true
end
local function highlight(item, color, strong)
	if not item or not item:IsDescendantOf(workspace) or not (item:IsA("Model") or item:IsA("BasePart")) then return end
	local h = Instance.new("Highlight"); h.Adornee, h.FillColor, h.OutlineColor = item, color, color
	h.FillTransparency, h.OutlineTransparency = strong and 0.45 or 0.88, strong and 0 or 0.35
	h.DepthMode, h.Parent = Enum.HighlightDepthMode.AlwaysOnTop, marks
end
local function change(key, value)
	if busy then return end
	if id == "curve" and key == "point" then send("pick", tonumber(value)); return end
	options[id][key] = value; send("configure")
end
renderFields = function()
	for _, child in ipairs(fields:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for index, f in ipairs(Catalog.stations[id].controls) do
		local choiceRows = f.kind == "choice" and math.ceil(#f.values / 2) or 0
		local r = frame(fields, f.key, UDim2.new(1, 0, 0, choiceRows > 0 and 26 + 40 * choiceRows or 40))
		r.BackgroundTransparency, r.LayoutOrder = 1, index
		local value = options[id][f.key]
		if f.kind == "toggle" then
			button(r, "Checkbox", value and "X" or "", UDim2.fromOffset(36, 36), UDim2.fromOffset(0, 2), function() change(f.key, not value) end)
			text(r, "Label", f.label, UDim2.new(1, -44, 1, 0), UDim2.fromOffset(44, 0), 13)
		elseif f.kind == "choice" then
			text(r, "Label", f.label, UDim2.new(1, 0, 0, 22), nil, 12, MUTED)
			for n, choice in ipairs(f.values) do
				local b = button(r, "Choice" .. n, choice, UDim2.new(0.5, -3, 0, 36), UDim2.new((n - 1) % 2 * 0.5, 0, 0, 26 + math.floor((n - 1) / 2) * 40), function() change(f.key, choice) end)
				b.TextWrapped = true
				if #choice > 20 then b.TextSize = 11 end
				if choice == value then b.BackgroundColor3, b.TextColor3 = Catalog.stations[id].accent, BG end
			end
		else
			text(r, "Label", f.label, UDim2.new(1, -130, 1, 0), nil, 13)
			button(r, "Minus", "-", UDim2.fromOffset(36, 36), UDim2.new(1, -128, 0, 2), function() change(f.key, math.max(f.min, value - f.step)) end)
			text(r, "Value", tostring(value), UDim2.fromOffset(44, 36), UDim2.new(1, -80, 0, 2), 16)
			button(r, "Plus", "+", UDim2.fromOffset(36, 36), UDim2.new(1, -36, 0, 2), function() change(f.key, math.min(f.max, value + f.step)) end)
		end
	end
end
render = function()
	options[id] = state.options
	summary.Text, status.Text = state.summary or "", state.message or ""
	marks:ClearAllChildren()
	for index, item in ipairs(state.highlights or {}) do if index <= 28 then highlight(item, Catalog.stations[id].accent, false) end end
	for _, item in ipairs(results:GetChildren()) do if item:IsA("GuiButton") then item:Destroy() end end
	results.Visible = #(state.rows or {}) > 0
	for index, row in ipairs(state.rows or {}) do
		local b = button(results, "Result" .. index, row.title, UDim2.new(1, -6, 0, 34), nil, function() send("select", index) end)
		b.LayoutOrder, b.TextSize, b.TextTruncate, b.TextXAlignment = index, 11, Enum.TextTruncate.AtEnd, Enum.TextXAlignment.Left
		if index == state.selected then b.BackgroundColor3 = Color3.fromRGB(64, 80, 81) end
	end
	local selected = state.selected and state.rows[state.selected]
	inspector.Text = selected and selected.detail or ""
	highlight(selected and selected.instance or state.focus, Color3.fromRGB(250, 235, 157), true)
	renderFields(); updateButtons()
end
local explore, characterControls
updateCamera = function(animate)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local narrow = camera.ViewportSize.X < 740
	local compact = camera.ViewportSize.Y < 600
	bar.Size = UDim2.new(1, 0, 0, compact and 48 or 64)
	disclosure.Size = UDim2.new(1, -132, 0, compact and 20 or 30)
	tabs.Position = UDim2.fromOffset(0, compact and 48 or 64)
	title.Visible, instruction.Visible = not compact, not compact
	if narrow then
		panel.Size, panel.Position = UDim2.new(1, 0, 0.47, -172), UDim2.fromScale(0, 0.53)
		dock.Size, dock.Position = UDim2.new(1, 0, 0, 148), UDim2.new(0, 0, 1, -172)
	else
		panel.Size, panel.Position = UDim2.new(0, 326, 1, -288), UDim2.fromOffset(12, 116)
		dock.Size, dock.Position = UDim2.fromOffset(326, 148), UDim2.new(0, 12, 1, -172)
	end
	if compact then
		panel.Size, panel.Position = UDim2.new(0, 326, 1, -208), UDim2.fromOffset(12, 96)
		dock.Size, dock.Position = UDim2.fromOffset(326, 88), UDim2.new(0, 12, 1, -112)
		primary.Size, primary.Position = UDim2.new(0.48, -8, 0, 34), UDim2.fromOffset(8, 4)
		rerun.Size, rerun.Position = UDim2.new(0.29, -4, 0, 34), UDim2.new(0.48, 4, 0, 4)
		reset.Size, reset.Position = UDim2.new(0.23, -12, 0, 34), UDim2.new(0.77, 8, 0, 4)
		status.Size, status.Position = UDim2.new(1, -16, 0, 46), UDim2.fromOffset(8, 40)
		primary.TextSize, rerun.TextSize, reset.TextSize = 11, 11, 11
	else
		primary.Size, primary.Position = UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 8)
		rerun.Size, rerun.Position = UDim2.new(0.63, -16, 0, 34), UDim2.fromOffset(12, 54)
		reset.Size, reset.Position = UDim2.new(0.37, -16, 0, 34), UDim2.new(0.63, 4, 0, 54)
		status.Size, status.Position = UDim2.new(1, -24, 0, 54), UDim2.fromOffset(12, 92)
		primary.TextSize, rerun.TextSize, reset.TextSize = 13, 13, 13
	end
	panel.Visible, dock.Visible = not exploring, not exploring
	if characterControls then
		if exploring then characterControls:Enable() else characterControls:Disable() end
	end
	if cameraTween then cameraTween:Cancel() end
	if exploring then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); return
	end
	if not state then return end
	camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, 55
	local center, offset = state.center + Vector3.new(0, 4, 0), Vector3.new(28, 28, 44)
	local baseFrame = CFrame.lookAt(center + offset, center)
	if narrow then
		local aspect = camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1)
		offset *= math.max(1.05, 0.85 / math.max(aspect, 0.35))
		center -= baseFrame.UpVector * offset.Magnitude * 0.17
	else center -= baseFrame.RightVector * 7 end
	local goal = CFrame.lookAt(center + offset, center)
	if animate then
		cameraTween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal }); cameraTween:Play()
	else camera.CFrame = goal end
end
send = function(action, index)
	if busy then return end
	busy = true; updateButtons(); status.Text = "Working..."
	local ok, reply = pcall(function() return remote:InvokeServer(action, id, table.clone(options[id]), index) end)
	busy = false
	if ok and reply.ok then
		local first = state == nil; state = reply; render()
		if first or action == "visit" then updateCamera(true) end
	else status.Text = ok and reply.message or "Connection unavailable. Try again."; updateButtons() end
end
local function visit(key)
	if busy then return end
	id, state, exploring = key, nil, false; explore.Text = "Explore"
	title.Text, title.TextColor3 = Catalog.stations[id].title, Catalog.stations[id].accent
	instruction.Text = Catalog.stations[id].instruction
	panel.CanvasPosition, results.CanvasPosition = Vector2.zero, Vector2.zero
	for k, b in pairs(nav) do b.TextColor3 = k == id and Catalog.stations[id].accent or MUTED end
	send("visit")
end
explore = button(bar, "Explore", "Explore", UDim2.fromOffset(96, 36), UDim2.new(1, -108, 0, 10), function()
	if busy then return end; exploring = not exploring; explore.Text = exploring and "Demo view" or "Explore"; updateCamera(false)
end)
for i, key in ipairs(Catalog.order) do
	nav[key] = button(tabs, key, Catalog.stations[key].title, UDim2.fromOffset(136, 40), UDim2.fromOffset((i - 1) * 140 + 4, 0), function() visit(key) end)
	nav[key].BackgroundTransparency = 1
end
local function pick(position)
	if busy or exploring or not state then return end
	local ray = workspace.CurrentCamera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = { state.fixture }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	if hit and hit.Instance:GetAttribute("Station") == id then send("pick", hit.Instance:GetAttribute("PickIndex")) end
end
Input.InputEnded:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then pick(input.Position) end
end)
Input.TouchTapInWorld:Connect(function(position, processed) if not processed then pick(position) end end)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() updateCamera(false) end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() updateCamera(false) end)
player.CharacterAdded:Connect(function() task.defer(function() updateCamera(false) end) end)
updateCamera(false); visit("access")
task.spawn(function()
	local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
	if module then characterControls = require(module):GetControls(); updateCamera(false) end
end)
