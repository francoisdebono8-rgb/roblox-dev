local Layout = {}
local PREFIX = "[SchemaForgeLayout]"

local function visible(object, root)
	local current = object
	while current and current ~= root.Parent do
		if current:IsA("GuiObject") and not current.Visible then return false end
		current = current.Parent
	end
	return true
end

local function settle(root)
	local previous, stable = nil, 0
	for _ = 1, 45 do
		task.wait()
		local parts = {}
		for _, object in ipairs(root:GetDescendants()) do
			if object:IsA("GuiObject") and visible(object, root) then
				table.insert(parts, tostring(object.AbsolutePosition) .. "/" .. tostring(object.AbsoluteSize))
				if object:IsA("ScrollingFrame") then table.insert(parts, tostring(object.AbsoluteCanvasSize)) end
				if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then table.insert(parts, tostring(object.TextBounds)) end
			end
		end
		local signature = table.concat(parts, "|")
		stable = signature == previous and stable + 1 or 0
		if stable >= 3 then return end
		previous = signature
	end
	error("Layout did not settle within 45 scheduler frames")
end

local function horizontalBounds(object, parent)
	local left, width = object.AbsolutePosition.X, object.AbsoluteSize.X
	assert(width > 0, object.Name .. ": zero/negative width")
	assert(left >= parent.AbsolutePosition.X - 1 and left + width <= parent.AbsolutePosition.X + parent.AbsoluteSize.X + 1,
		object:GetFullName() .. ": horizontal overflow outside " .. parent.Name)
end

local function geometry(root)
	local measured = 0
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("GuiObject") and visible(object, root) then
			measured += 1
			horizontalBounds(object, root)
			if object.Parent:IsA("GuiObject") then horizontalBounds(object, object.Parent) end
			if object:IsA("ScrollingFrame") then
				assert(object.ScrollingDirection == Enum.ScrollingDirection.Y, object.Name .. ": horizontal scrolling enabled")
				assert(object.CanvasSize.X == UDim.new(), object.Name .. ": horizontal canvas configured")
				assert(object.AbsoluteCanvasSize.X <= object.AbsoluteSize.X + 1, object.Name .. ": canvas exceeds viewport width")
			elseif object:IsA("TextLabel") and object.Text ~= "" and object.TextTruncate == Enum.TextTruncate.None then
				assert(object.TextBounds.X <= object.AbsoluteSize.X + 1, object.Name .. ": label text overflows horizontally")
				assert(object.TextBounds.Y <= object.AbsoluteSize.Y + 1, object.Name .. ": label text overflows vertically")
			end
		end
	end
	assert(measured >= 20, "Expected a populated rendered UI")
end

local function inViewport(object, root)
	assert(visible(object, root) and object.AbsoluteSize.Y > 0, object.Name .. ": hidden/empty control")
	local top, bottom = object.AbsolutePosition.Y, object.AbsolutePosition.Y + object.AbsoluteSize.Y
	local ancestor = object.Parent
	while ancestor and ancestor ~= root.Parent do
		if ancestor:IsA("GuiObject") and (ancestor == root or ancestor.ClipsDescendants) then
			local height = ancestor:IsA("ScrollingFrame") and ancestor.AbsoluteWindowSize.Y or ancestor.AbsoluteSize.Y
			assert(top >= ancestor.AbsolutePosition.Y - 1 and bottom <= ancestor.AbsolutePosition.Y + height + 1,
				object.Name .. ": not fully reachable inside " .. ancestor.Name)
		end
		ancestor = ancestor.Parent
	end
end

local function reach(object, body, root)
	local desired = body.CanvasPosition.Y + object.AbsolutePosition.Y - body.AbsolutePosition.Y
	local spare = math.max(0, body.AbsoluteWindowSize.Y - object.AbsoluteSize.Y)
	local maximum = math.max(0, body.AbsoluteCanvasSize.Y - body.AbsoluteWindowSize.Y)
	body.CanvasPosition = Vector2.new(0, math.clamp(desired - spare / 2, 0, maximum))
	settle(root)
	inViewport(object, root)
end

local function schemaFixture(Schema)
	local schema = Schema.new()
	schema.name = string.rep("LongContract", 6)
	schema.tag = string.rep("TaggedObject", 7)
	for index = 1, 32 do
		table.insert(schema.fields, {name = string.format("Field%02d_", index) .. string.rep("LongName", 10),
			kind = "number", required = true, hasDefault = true, default = 25, min = 0, max = 100, integer = true,
			choices = {}, description = string.rep("Designer note. ", 15)})
		table.insert(schema.children, {path = "Socket" .. index .. "/Prompt", className = "ProximityPrompt", description = "Required interaction point"})
	end
	return Schema.validate(schema)
end

local function mount(modules, width, height, seed, cleanup, nativeHost)
	local Schema, View = require(modules.Schema), require(modules.View)
	local host = nativeHost
	if not host then
		local screen = Instance.new("ScreenGui")
		screen.Name = "SchemaForgeLayoutHost"; screen.IgnoreGuiInset = true; screen.ResetOnSpawn = false
		cleanup(function() screen:Destroy() end)
		host = Instance.new("Frame")
		host.Name = "MeasuredViewport"; host.BackgroundTransparency = 1; host.Size = UDim2.fromOffset(width, height); host.Parent = screen
		screen.Parent = game:GetService("CoreGui")
	end
	local selected, undo, redo = Instance.new("BindableEvent"), Instance.new("BindableEvent"), Instance.new("BindableEvent")
	cleanup(function() selected:Destroy(); undo:Destroy(); redo:Destroy() end)
	local selection = {Get = function() return {} end, SelectionChanged = selected.Event,
		Set = function() error("Pure layout tests must not change selection") end}
	local history = {OnUndo = undo.Event, OnRedo = redo.Event,
		TryBeginRecording = function() error("Pure layout tests must not mutate project data") end}
	-- Seed only initial construction. This is fixture setup, not capture/load UI coverage.
	local originalNew = Schema.new
	if seed then Schema.new = function() return Schema.copy(seed) end end
	local ok, dispose = xpcall(function() return View.mount(host, selection, history) end, debug.traceback)
	Schema.new = originalNew
	assert(ok, dispose)
	local disposed = false
	local function finish() if not disposed then dispose(); disposed = true end end
	cleanup(finish)
	settle(host)
	local root = assert(host:FindFirstChild("SchemaForgeUI", true), "Missing SchemaForgeUI root")
	return {host = host, root = root, body = assert(root:FindFirstChild("Body")), dispose = finish, undo = undo, redo = redo}
end

local function fixedControls(ui, width, height)
	local root, body = ui.root, ui.body
	assert(math.abs(root.AbsoluteSize.X - width) <= 1 and math.abs(root.AbsoluteSize.Y - height) <= 1, "Incorrect rendered host dimensions")
	local header, footer = assert(root:FindFirstChild("Header")), assert(root:FindFirstChild("Footer"))
	assert(math.abs(header.AbsoluteSize.Y - 128) <= 1, "Header must reserve 128px")
	assert(math.abs(root.AbsolutePosition.Y + height - footer.AbsolutePosition.Y - 100) <= 1, "Footer must reserve the final 100px")
	assert(body.AbsoluteSize.Y > 0 and body.AbsolutePosition.Y >= header.AbsolutePosition.Y + header.AbsoluteSize.Y,
		"Body overlaps header or has no height")
	assert(body.AbsolutePosition.Y + body.AbsoluteSize.Y <= footer.AbsolutePosition.Y + 1, "Body overlaps footer")
	inViewport(header, root); inViewport(footer, root)
	for _, name in ipairs({"Library", "TabRules", "TabAudit", "TabRepairs", "Save"}) do
		local control = assert(root:FindFirstChild(name, true), "Missing core control " .. name)
		inViewport(control, root)
		assert(control.TextBounds.X <= control.AbsoluteSize.X + 1 and control.TextBounds.Y <= control.AbsoluteSize.Y + 1,
			name .. ": core control text does not fit")
		assert(control.TextFits, name .. ": core control text clipped")
	end
	assert(root:FindFirstChild("Audit", true) == nil, "Empty Rules view must not expose an Audit action")
	return header, footer
end

local function editing(ui, populated)
	local root, body = ui.root, ui.body
	local boxes = {}
	local last
	for _, object in ipairs(body:GetDescendants()) do
		if object:IsA("TextBox") and visible(object, root) then
			boxes[object.Name] = object
			if not last or object.AbsolutePosition.Y > last.AbsolutePosition.Y then last = object end
		end
	end
	assert(last and last.Name == (populated and "DefaultValue" or "TargetTag"), "Unexpected last editable field")
	local header, footer = root.Header, root.Footer
	local headerPosition, footerPosition = header.AbsolutePosition, footer.AbsolutePosition
	reach(last, body, root)
	if populated then assert(body.CanvasPosition.Y > 0, "Long numeric editor did not exercise scrolling") end
	local scroll = body.CanvasPosition
	last.Text = populated and "37" or "SchemaForgeLayoutTag"
	settle(root)
	assert(body.CanvasPosition == scroll, "Valid text update moved the scroll position")
	local function sameInstances()
		assert(ui.host:FindFirstChild("SchemaForgeUI") == root and root:FindFirstChild("Body") == body, "Editing replaced the root/body")
		for name, box in pairs(boxes) do assert(body:FindFirstChild(name, true) == box, name .. ": Text update destroyed/replaced textbox") end
		assert(header.AbsolutePosition == headerPosition and footer.AbsolutePosition == footerPosition, "Scrolling/editing moved fixed controls")
	end
	sameInstances()
	local input = assert(boxes[populated and "min" or "SchemaName"])
	local errorLabel = assert(body:FindFirstChild(input.Name .. "Error", true), "Missing contextual error label")
	local valid = input.Text
	input.Text = populated and "not-a-number" or ""
	settle(root); sameInstances()
	assert(errorLabel.Visible and #errorLabel.Text > 0, "Invalid draft has no visible contextual error")
	assert(errorLabel.Text:find(populated and "finite number" or "Schema name", 1, true), "Unexpected contextual validation")
	assert(errorLabel.TextColor3 ~= input.TextColor3, "Error color must be distinct from normal text")
	geometry(root)
	reach(errorLabel, body, root)
	input.Text = valid
	settle(root); sameInstances()
	assert(body:FindFirstChild(input.Name .. "Error", true) == errorLabel and not errorLabel.Visible, "Correcting a draft must clear the existing error label")
	reach(last, body, root)
	if populated then reach(assert(body:FindFirstChild("RemoveField")), body, root) end
	assert(header.AbsolutePosition == headerPosition and footer.AbsolutePosition == footerPosition, "Body scroll moved header/footer")
end

local function awaitCondition(predicate, message)
	for _ = 1, 90 do
		if predicate() then return end
		task.wait()
	end
	error(message)
end

local function releaseFocus(root)
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("TextBox") and object:IsFocused() then object:ReleaseFocus(false) end
	end
end

local function nativeFocus(ui, label)
	local body, root = ui.body, ui.root
	local box = assert(body:FindFirstChild("FieldDescription"), "Missing seeded field editor")
	reach(box, body, root)
	box:CaptureFocus()
	awaitCondition(function() return box:IsFocused() end, "DockWidget CaptureFocus could not acquire native focus; regression was not exercised")
	local draft = "DockWidget focus selection draft 0123456789"
	box.Text = draft
	settle(root)
	assert(body:FindFirstChild(box.Name) == box and box:IsFocused(), "Text update replaced the focused input or lost focus")
	inViewport(box, root)
	assert(body.CanvasPosition.Y > 0, "Focus regression requires a scrolled form")
	for index, event in ipairs({ui.undo, ui.redo}) do
		local cursor, selection = index == 1 and 25 or 7, index == 1 and 7 or 25
		box.CursorPosition = cursor; box.SelectionStart = selection
		settle(root)
		assert(box:IsFocused() and box.CursorPosition == cursor and box.SelectionStart == selection,
			"Native caret/selection setup failed before rerender")
		local scroll = body.CanvasPosition
		print(string.format("%s[FOCUS] %s %s: IsFocused=true cursor=%d selection=%d scrollY=%.1f",
			PREFIX, label, index == 1 and "OnUndo" or "OnRedo", cursor, selection, scroll.Y))
		local previous = box
		-- Exercise the real View history callback, without a project Undo or GUI click.
		event:Fire()
		awaitCondition(function()
			local replacement = body:FindFirstChild("FieldDescription")
			return replacement ~= nil and replacement ~= previous
		end, "History event did not rerender the field editor")
		settle(root)
		box = assert(body:FindFirstChild("FieldDescription"))
		assert(previous.Parent == nil and box ~= previous, "History rerender did not replace the textbox")
		assert(box:IsFocused(), "Rerender lost native DockWidget focus: replacement TextBox:IsFocused() is false")
		assert(box.CursorPosition == cursor, string.format("Rerender changed caret: expected %d, actual %d", cursor, box.CursorPosition))
		assert(box.SelectionStart == selection, string.format("Rerender changed selection: expected %d, actual %d", selection, box.SelectionStart))
		assert(box.Text == draft, "Rerender lost the typed draft")
		assert(math.abs(body.CanvasPosition.X - scroll.X) <= 1 and math.abs(body.CanvasPosition.Y - scroll.Y) <= 1,
			string.format("Rerender changed scroll: before=%s after=%s", tostring(scroll), tostring(body.CanvasPosition)))
		inViewport(box, root)
	end
end

function Layout.run(modules, pluginHandle)
	local pass, fail = 0, 0
	local function test(name, fn)
		local cleanups = {}
		local ok, err = xpcall(function() fn(function(callback) table.insert(cleanups, callback) end) end, debug.traceback)
		for index = #cleanups, 1, -1 do
			local cleaned, cleanupError = pcall(cleanups[index])
			if not cleaned then ok = false; err = tostring(err or "") .. " Cleanup: " .. tostring(cleanupError) end
		end
		if ok then pass += 1; print(PREFIX .. "[PASS] " .. name)
		else fail += 1; warn(PREFIX .. "[FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local studio = settings().Studio
	-- Theme setters can crash Studio from plugin threads. Read the current theme only.
	local currentTheme = studio.Theme
	local themeName = currentTheme.Name
	print(PREFIX .. "[THEME] " .. themeName .. "; 24 ScreenGui + 8 DockWidget cases; Studio theme settings are read-only")
	for _, width in ipairs({240, 320, 400, 560}) do
		for _, height in ipairs({360, 640, 900}) do
			for _, populated in ipairs({false, true}) do
				local label = string.format("%s %dx%d %s / geometry, controls, scroll, edits, errors, dispose", themeName, width, height, populated and "32-rule draft" or "empty draft")
				test(label, function(cleanup)
					assert(studio.Theme == currentTheme, "Theme changed during this run; rerun the layout suite")
					local Schema = require(modules.Schema)
					local ui = mount(modules, width, height, populated and schemaFixture(Schema) or nil, cleanup)
					geometry(ui.root); fixedControls(ui, width, height)
					assert(ui.root.BackgroundColor3 == currentTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground), "Root does not follow the Studio theme")
					assert(ui.body:FindFirstChild(populated and "FieldPicker" or "Capture"), "Expected populated/reference-first controls")
					editing(ui, populated)
					geometry(ui.root); fixedControls(ui, width, height)
					ui.dispose(); task.wait()
					assert(#ui.host:GetChildren() == 0, "Dispose left UI children attached")
					assert(studio.Theme == currentTheme, "Theme changed during this run; rerun the layout suite")
				end)
			end
		end
	end
	if pluginHandle == nil then
		test("DockWidget plugin handle required", function() error("Pass the installed QA plugin handle to Layout.run(modules, plugin); DockWidget cases were not run") end)
	else
		local chrome = Vector2.zero
		test("Measure native DockWidget window chrome", function(cleanup)
			local id = "SchemaForgeSizeQA_" .. game:GetService("HttpService"):GenerateGUID(false)
			local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 400, 640, 240, 360)
			local widget = pluginHandle:CreateDockWidgetPluginGuiAsync(id, info)
			cleanup(function() widget:Destroy() end)
			awaitCondition(function() return widget.AbsoluteSize.X > 0 and widget.AbsoluteSize.Y > 0 end, "Calibration widget has no client area")
			settle(widget)
			chrome = Vector2.new(400, 640) - widget.AbsoluteSize
			assert(chrome.X >= 0 and chrome.X < 100 and chrome.Y >= 0 and chrome.Y < 100, "Unexpected native window chrome: " .. tostring(chrome))
			print(PREFIX .. "[CHROME] measured outer-minus-client=" .. tostring(chrome))
		end)
		for _, width in ipairs({240, 320, 400, 560}) do
			for _, height in ipairs({360, 640}) do
				local label = string.format("%s DockWidget %dx%d / geometry, native focus, caret, selection, scroll, dispose", themeName, width, height)
				test(label, function(cleanup)
					assert(studio.Theme == currentTheme, "Theme changed during this run; rerun the layout suite")
					local id = "SchemaForgeFocusQA_" .. game:GetService("HttpService"):GenerateGUID(false)
					local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, width + chrome.X, height + chrome.Y, 240, 360)
					local widget = pluginHandle:CreateDockWidgetPluginGuiAsync(id, info)
					cleanup(function() widget:Destroy() end)
					widget.Title = "SchemaForge QA"
					local ui = mount(modules, width, height, schemaFixture(require(modules.Schema)), cleanup, widget)
					cleanup(function() releaseFocus(ui.root) end)
					local size = widget.AbsoluteSize
					local exact = math.abs(size.X - width) <= 1 and math.abs(size.Y - height) <= 1
					local dimensions = string.format("requested=%dx%d actualClient=%.1fx%.1f content=%.1fx%.1f restored=%s",
						width, height, size.X, size.Y, ui.root.AbsoluteSize.X, ui.root.AbsoluteSize.Y, tostring(widget.HostWidgetWasRestored))
					print(PREFIX .. "[DOCK SIZE] " .. dimensions)
					if not exact then warn(PREFIX .. "[HOST SIZE MISMATCH] " .. dimensions .. "; possible native window/chrome constraint; requested size cannot PASS") end
					assert(widget.Enabled and not widget.HostWidgetWasRestored, "Unique QA widget was hidden or restored an existing host")
					geometry(ui.root); fixedControls(ui, size.X, size.Y)
					assert(ui.root.BackgroundColor3 == currentTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground), "DockWidget does not follow the Studio theme")
					nativeFocus(ui, label)
					geometry(ui.root); fixedControls(ui, size.X, size.Y)
					releaseFocus(ui.root)
					ui.dispose(); task.wait()
					assert(widget:FindFirstChild("SchemaForgeUI") == nil, "Dispose left commercial UI in the DockWidget")
					assert(studio.Theme == currentTheme, "Theme changed during this run; rerun the layout suite")
					assert(exact, "Requested DockWidget dimensions not exercised: " .. dimensions)
				end)
			end
		end
	end
	print(string.format("%s[SUMMARY] %d PASS / %d FAIL; theme=%s", PREFIX, pass, fail, themeName))
	print(PREFIX .. " Other themes require a separate run after changing Studio Settings through the native UI.")
	print(PREFIX .. " ScreenGui geometry, DockWidget CaptureFocus/caret/selection and BindableEvent history rerenders; no human typing/clicks, native history transaction or rule-switching claim.")
	return fail == 0
end

return Layout
