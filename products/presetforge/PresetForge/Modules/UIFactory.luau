local Constants = require(script.Parent.Constants)
local TextService = game:GetService("TextService")

local UIFactory = {}
-- Canonical SVG raster, unchanged from SchemaForge (32 x 42).
local forgeMarkRaster = [[
5,1,51;6,2,68;8,1,85;9,2,102;11,2,119;13,1,136;14,2,153;16,2,170;18,1,187;19,2,204;21,2,221;23,1,238;24,1,255
4,1,136;5,20,255
3,1,68;4,21,255
2,1,34;3,1,238;4,20,255;24,1,170
2,1,204;3,20,255;23,1,170
1,1,136;2,20,255;22,1,170
0,1,85;1,20,255;21,1,170
0,1,238;1,6,255;7,13,153;20,1,136
0,1,238;1,5,255;6,1,102
0,1,221;1,4,255;5,1,102
0,1,221;1,3,255;4,1,119
0,1,204;1,2,255;3,1,136;7,2,17;9,2,34;11,2,51;13,1,68;14,2,85;16,2,102;18,2,119;20,2,136;22,1,17
0,1,187;1,1,255;2,1,153;5,1,51;6,1,238;7,14,255;21,1,102
0,1,170;1,1,153;4,1,85;5,15,255;20,1,119
0,1,85;3,1,119;4,15,255;19,1,153
2,1,153;3,15,255;18,1,170
0,1,17;1,1,187;2,15,255;17,1,187
0,1,153;1,15,255;16,1,204;17,1,17
0,1,153;1,6,255;7,1,102;8,1,85;9,2,68;11,1,51;12,2,34;14,2,17
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,6,255
0,1,153;1,5,255;6,1,153
0,1,153;1,4,255;5,1,136
0,1,153;1,3,255;4,1,85
0,1,153;1,1,255;2,1,238;3,1,51
0,1,153;1,1,204;2,1,34
0,1,85;1,1,17







]]
local contexts = setmetatable({}, { __mode = "k" })

local function studioSettings()
	local ok, studio = pcall(function()
		return settings().Studio
	end)
	return ok and studio or nil
end

local function palette(studio)
	local colors = {
		background = Color3.fromRGB(24, 26, 28),
		panel = Color3.fromRGB(30, 32, 34),
		panelHover = Color3.fromRGB(40, 44, 46),
		border = Color3.fromRGB(47, 51, 53),
		text = Color3.fromRGB(232, 234, 236),
		muted = Color3.fromRGB(158, 163, 166),
		accent = Color3.fromRGB(209, 163, 72),
		accentHover = Color3.fromRGB(224, 180, 92),
		onAccent = Color3.fromRGB(38, 30, 15),
		danger = Color3.fromRGB(255, 139, 139),
		success = Color3.fromRGB(116, 214, 158),
		warning = Color3.fromRGB(245, 198, 106),
	}
	if studio then
		local theme = studio.Theme
		local bg = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		if bg.R + bg.G + bg.B > 1.5 then
			colors.background = Color3.fromRGB(246, 247, 247)
			colors.panel = Color3.fromRGB(241, 243, 243)
			colors.panelHover = Color3.fromRGB(235, 238, 237)
			colors.border = Color3.fromRGB(221, 224, 223)
			colors.text = Color3.fromRGB(36, 39, 41)
			colors.muted = Color3.fromRGB(102, 108, 111)
		end
	end
	local light = colors.background.R + colors.background.G + colors.background.B > 1.5
	colors.accentDark = colors.background:Lerp(colors.accent, 0.12)
	colors.accentText = light and Color3.fromRGB(128, 86, 12) or colors.accent
	if light then
		colors.danger = Color3.fromRGB(174, 37, 43)
		colors.success = Color3.fromRGB(30, 112, 66)
		colors.warning = Color3.fromRGB(135, 84, 0)
	end
	return colors
end

local fallbackColors = palette(nil)

local function contextFor(instance)
	while instance do
		if contexts[instance] then
			return contexts[instance]
		end
		instance = instance.Parent
	end
	return nil
end

local function paint(instance, property, role)
	local context = contextFor(instance)
	instance[property] = (context and context.colors or fallbackColors)[role]
	if context then
		local roles = context.styles[instance] or {}
		roles[property] = role
		context.styles[instance] = roles
	end
end

local function listen(owner, signal, callback)
	local connection = signal:Connect(callback)
	local context = contextFor(owner)
	if context then
		local connections = context.connections[owner]
		if not connections then
			connections = {}
			context.connections[owner] = connections
			if not contexts[owner] then
				connections[1] = owner.Destroying:Connect(function()
					for _, owned in ipairs(connections) do
						owned:Disconnect()
					end
					context.connections[owner] = nil
					context.styles[owner] = nil
				end)
			end
		end
		connections[#connections + 1] = connection
	end
	return connection
end

local function create(className, properties, parent)
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
		instance.LayoutOrder = parent and #parent:GetChildren() + 1 or 0
		if parent and parent:IsA("GuiObject") then
			instance.ZIndex = parent.ZIndex
		end
	end
	for property, value in pairs(properties) do
		instance[property] = value
	end
	instance.Parent = parent
	return instance
end

local function padding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	}, parent)
end

local function border(parent, role)
	create("UICorner", { CornerRadius = UDim.new(0, 4) }, parent)
	local result = create("UIStroke", {
		Name = "Border",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
	}, parent)
	paint(result, "Color", role or "border")
	return result
end

local function stack(parent, name)
	local result = create("Frame", {
		Name = name,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
	}, parent)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, result)
	return result
end

local function fitWrappedText(target)
	local minimum = target.Size.Y.Offset
	local function resizeText()
		if target.AutomaticSize ~= Enum.AutomaticSize.Y or target.AbsoluteSize.X <= 0 then
			return
		end
		local inset = target:FindFirstChildOfClass("UIPadding")
		local horizontal = inset and (inset.PaddingLeft.Offset + inset.PaddingRight.Offset) or 0
		local vertical = inset and (inset.PaddingTop.Offset + inset.PaddingBottom.Offset) or 0
		-- Measure beyond the scroll viewport: automatic Y can otherwise use clipped text bounds.
		local bounds = TextService:GetTextSize(target.Text, target.TextSize, target.Font,
			Vector2.new(math.max(1, target.AbsoluteSize.X - horizontal), 1000000))
		local height = math.max(minimum, math.ceil(bounds.Y) + vertical + 2)
		if target.Size.Y.Offset ~= height then
			target.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, 0, height)
		end
	end
	for _, property in ipairs({ "AbsoluteSize", "Text", "TextSize", "Font", "AutomaticSize" }) do
		listen(target, target:GetPropertyChangedSignal(property), resizeText)
	end
	resizeText()
end

local function label(parent, text, size, role, bold)
	local result = create("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,
		Size = UDim2.new(1, 0, 0, size + 6),
		Text = text,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
	paint(result, "TextColor3", role or "text")
	fitWrappedText(result)
	return result
end

local function renderButton(target)
	local selected = target:GetAttribute("Selected") or target:GetAttribute("Checked")
	local primary = target:GetAttribute("Primary")
	local hover = target:GetAttribute("Hovered") and target.Active
	paint(target, "BackgroundColor3", selected and "accentDark"
		or primary and (hover and "accentHover" or "accent")
		or (hover or target:GetAttribute("Pressed")) and "panelHover" or "panel")
	if target:GetAttribute("Quiet") then
		target.BackgroundTransparency = (selected or hover or target:GetAttribute("Pressed")) and 0 or 1
	end
	local outline = target:FindFirstChildOfClass("UIStroke")
	if outline then
		paint(outline, "Color", (selected or primary) and "accent" or "border")
	end
end

local function button(parent, text, primary)
	local result = create("TextButton", {
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.new(1, 0, 0, 32),
		Text = text,
		TextSize = 13,
		TextWrapped = true,
	}, parent)
	result:SetAttribute("Primary", primary == true)
	paint(result, "TextColor3", primary and "onAccent" or "text")
	border(result)
	listen(result, result.MouseEnter, function()
		result:SetAttribute("Hovered", true)
		renderButton(result)
	end)
	listen(result, result.MouseLeave, function()
		result:SetAttribute("Hovered", false)
		result:SetAttribute("Pressed", false)
		renderButton(result)
	end)
	listen(result, result.MouseButton1Down, function() result:SetAttribute("Pressed", true); renderButton(result) end)
	listen(result, result.MouseButton1Up, function() result:SetAttribute("Pressed", false); renderButton(result) end)
	renderButton(result)
	return result
end

local function textBox(parent, placeholder)
	local result = create("TextBox", {
		AutomaticSize = Enum.AutomaticSize.Y,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		MultiLine = false,
		PlaceholderText = placeholder,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	paint(result, "BackgroundColor3", "panel")
	paint(result, "TextColor3", "text")
	paint(result, "PlaceholderColor3", "muted")
	padding(result, 7, 8, 7, 8)
	local outline = border(result)
	listen(result, result.Focused, function() paint(outline, "Color", "accent") end)
	listen(result, result.FocusLost, function() paint(outline, "Color", "border") end)
	fitWrappedText(result)
	return result
end

local function pair(parent, name)
	return create("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
	}, parent)
end

local function inPair(target, index)
	target.Size = UDim2.new(0.5, -4, 1, 0)
	target.Position = UDim2.new((index - 1) * 0.5, (index - 1) * 4, 0, 0)
	return target
end

local function scroll(parent, name)
	local result = create("ScrollingFrame", {
		Name = name,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, parent)
	paint(result, "ScrollBarImageColor3", "border")
	padding(result, 12, 16, 12, 12)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, result)
	return result
end

function UIFactory.setButtonEnabled(target, enabled)
	target.Active = enabled
	target.Selectable = enabled
	target.TextTransparency = enabled and 0 or 0.5
	target.BackgroundTransparency = enabled and 0 or 0.35
	local outline = target:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Transparency = enabled and 0 or 0.55
	end
	renderButton(target)
end

function UIFactory.setSegment(target, selected)
	target:SetAttribute("Selected", selected)
	renderButton(target)
end

function UIFactory.createCheckbox(parent, text, checked)
	local result = button(parent, text, false)
	result.Name = "FieldCheckbox"
	result.AutomaticSize = Enum.AutomaticSize.Y
	result.Font = Enum.Font.BuilderSans
	result.Size = UDim2.new(1, 0, 0, 34)
	result.TextXAlignment = Enum.TextXAlignment.Left
	result.TextYAlignment = Enum.TextYAlignment.Top
	padding(result, 8, 8, 8, 36)
	fitWrappedText(result)
	result:SetAttribute("Label", text)
	local box = create("Frame", {
		Name = "Checkbox",
		Position = UDim2.fromOffset(-28, 0),
		Size = UDim2.fromOffset(16, 16),
	}, result)
	border(box)
	local mark = label(box, utf8.char(0x2713), 14, "onAccent", true)
	mark.Name = "Checkmark"
	mark.AutomaticSize = Enum.AutomaticSize.None
	mark.Size = UDim2.fromScale(1, 1)
	mark.TextXAlignment = Enum.TextXAlignment.Center
	mark.TextYAlignment = Enum.TextYAlignment.Center
	local function layer()
		box.ZIndex = result.ZIndex + 1
		mark.ZIndex = result.ZIndex + 2
	end
	listen(result, result:GetPropertyChangedSignal("ZIndex"), layer)
	layer()
	local function render()
		local value = result:GetAttribute("Checked") == true
		mark.Visible = value
		paint(box, "BackgroundColor3", value and "accent" or "panel")
		renderButton(result)
	end
	listen(result, result:GetAttributeChangedSignal("Checked"), render)
	listen(result, result.Activated, function()
		if result.Active then
			UIFactory.setCheckbox(result, not result:GetAttribute("Checked"))
		end
	end)
	UIFactory.setCheckbox(result, checked == true)
	render()
	return result
end

function UIFactory.setCheckbox(target, checked, text)
	if text then
		target:SetAttribute("Label", text)
	end
	target.Text = target:GetAttribute("Label") or target.Text
	target:SetAttribute("Checked", checked == true)
	renderButton(target)
end

local function quiet(target)
	target:SetAttribute("Quiet", true)
	local outline = target:FindFirstChildOfClass("UIStroke")
	if outline then outline:Destroy() end
	renderButton(target)
	return target
end

local function fixedLabel(parent, text, size, role, bold)
	local result = label(parent, text, size, role, bold)
	result.AutomaticSize = Enum.AutomaticSize.None
	result.TextWrapped = false
	result.TextTruncate = Enum.TextTruncate.AtEnd
	result.TextYAlignment = Enum.TextYAlignment.Center
	return result
end

local function tip(target, text)
	local context = contextFor(target)
	local hovering = false
	listen(target, target.MouseEnter, function()
		hovering = true
		task.delay(0.6, function()
			if not hovering or not target.Parent or context.destroyed or not context.tooltip then return end
			if not text and target.TextFits then return end
			local tooltip = context.tooltip
			tooltip.Text = text or target.Text
			tooltip.Position = UDim2.fromOffset(12, math.clamp(target.AbsolutePosition.Y - context.root.AbsolutePosition.Y + target.AbsoluteSize.Y, 8, math.max(8, context.root.AbsoluteSize.Y - 110)))
			tooltip.Visible = true
		end)
	end)
	listen(target, target.MouseLeave, function() hovering = false; if context.tooltip then context.tooltip.Visible = false end end)
	listen(target, target.Destroying, function() hovering = false; if context.tooltip then context.tooltip.Visible = false end end)
end

local function separator(parent)
	local rule = create("Frame", {Name = "Separator", Size = UDim2.new(1, 0, 0, 1)}, parent)
	paint(rule, "BackgroundColor3", "border")
	return rule
end

function UIFactory.createPresetButton(parent, recipe, selected)
	local result = quiet(button(parent, "", false))
	result.Name = "PresetButton"
	result.Size = UDim2.new(1, 0, 0, 52)
	result:SetAttribute("RecipeName", recipe.name)
	result:SetAttribute("Library", recipe.library)
	local name = fixedLabel(result, recipe.name, 13, selected and "accentText" or "text", selected)
	name.Position = UDim2.fromOffset(10, 6); name.Size = UDim2.new(1, -18, 0, 20); tip(name)
	local meta = fixedLabel(result, recipe.library .. "  /  " .. recipe.schemaId, 11, "muted", false)
	meta.Position = UDim2.fromOffset(10, 28); meta.Size = UDim2.new(1, -18, 0, 16); tip(meta)
	if selected then
		local marker = create("Frame", {Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(2, 32)}, result)
		paint(marker, "BackgroundColor3", "accent")
	end
	UIFactory.setSegment(result, selected)
	return result
end

function UIFactory.createResultRow(parent, result, formatValue)
	local group = stack(parent, "ObjectChanges")
	group:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 6)
	group:SetAttribute("Status", result.status)
	separator(group)
	local heading = pair(group, "ObjectHeading")
	heading.Size = UDim2.new(1, 0, 0, 42)
	local title = fixedLabel(heading, result.instance.Name, 14, "text", true)
	title.Size = UDim2.new(1, -96, 0, 22); tip(title)
	local path = fixedLabel(heading, result.path, 11, "muted", false)
	path.Name = "ObjectPath"
	path.Position = UDim2.fromOffset(0, 23); path.Size = UDim2.new(1, 0, 0, 16); tip(path, result.path)
	-- Native truncation can overflow an auto-height list in a floating Studio dock.
	local function fitPath()
		local rootWidth = contextFor(path).root.AbsoluteSize.X
		local available = math.min(path.AbsoluteSize.X, rootWidth - (rootWidth >= 520 and 168 or 0) - 28)
		if available <= 0 then return end
		local function fits(text)
			return TextService:GetTextSize(text, path.TextSize, path.Font, Vector2.new(4096, 100)).X <= available
		end
		if fits(result.path) then path.Text = result.path; return end
		local offsets = {}
		if utf8.len(result.path) then
			for offset in utf8.codes(result.path) do offsets[#offsets + 1] = offset end
		else
			for offset = 1, #result.path do offsets[#offsets + 1] = offset end
		end
		offsets[#offsets + 1] = #result.path + 1
		local low, high = 0, #offsets - 1
		while low < high do
			local middle = math.ceil((low + high) / 2)
			if fits(string.sub(result.path, 1, offsets[middle + 1] - 1) .. "...") then low = middle else high = middle - 1 end
		end
		path.Text = string.sub(result.path, 1, offsets[low + 1] - 1) .. "..."
	end
	listen(path, path:GetPropertyChangedSignal("AbsoluteSize"), fitPath)
	listen(path, contextFor(path).root:GetPropertyChangedSignal("AbsoluteSize"), fitPath)
	fitPath()
	local selectButton = quiet(button(heading, "Select", false))
	selectButton.Position = UDim2.new(1, -96, 0, 0); selectButton.Size = UDim2.fromOffset(48, 24)
	local frameButton = quiet(button(heading, "Frame", false))
	frameButton.Position = UDim2.new(1, -48, 0, 0); frameButton.Size = UDim2.fromOffset(48, 24)
	if #result.changes > 0 then
		local headings = pair(group, "ValueHeadings"); headings.Size = UDim2.new(1, 0, 0, 16)
		for i, name in ipairs({"FIELD", "BEFORE", "AFTER"}) do
			local h = fixedLabel(headings, name, 10, "muted", false)
			h.Position = UDim2.new(i == 1 and 0 or i == 2 and 0.42 or 0.71, 0, 0, 0)
			h.Size = UDim2.new(i == 1 and 0.42 or 0.29, -6, 1, 0)
		end
		for _, change in ipairs(result.changes) do
			local values = pair(group, "FieldChange")
			local before = change.beforeExists == false and "Missing" or formatValue(change.before)
			local texts = {change.name, before, formatValue(change.after)}
			local cells = {}
			for i, text in ipairs(texts) do
				local cell = label(values, text, 12, i == 1 and "text" or i == 3 and "accentText" or "muted", i == 1)
				cell.Position = UDim2.new(i == 1 and 0 or i == 2 and 0.42 or 0.71, 0, 0, 0)
				cell.Size = UDim2.new(i == 1 and 0.42 or 0.29, -6, 0, 18)
				cells[i] = cell
				local value = i == 2 and change.before or i == 3 and change.after or nil
				if typeof(value) == "Color3" then
					local hex = value:ToHex():upper()
					local byteColor = Color3.fromHex(hex)
					-- Hex is exact only for byte-derived colors; retain arbitrary float values verbatim.
					if value == byteColor then
						cell.Text = "#" .. hex
						cell.TextSize = 11
						padding(cell, 0, 0, 0, 19)
						local swatch = create("Frame", {Name = "ColorSwatch", BackgroundColor3 = value,
							Position = cell.Position + UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(12, 12)}, values)
						border(swatch)
					end
					tip(cell, text)
				end
			end
			tip(cells[1], change.kind .. " / " .. change.name)
			local function sizeValues() values.Size = UDim2.new(1, 0, 0, math.max(cells[1].AbsoluteSize.Y, cells[2].AbsoluteSize.Y, cells[3].AbsoluteSize.Y, 22)) end
			for _, cell in ipairs(cells) do listen(cell, cell:GetPropertyChangedSignal("AbsoluteSize"), sizeValues) end
			sizeValues()
		end
	else
		label(group, result.reason or "Every captured field already matches.", 12, "muted", false)
	end
	return group, selectButton, frameButton
end

local function refreshTheme(root, context, studio)
	local nextColors = palette(studio)
	local descendants = root:GetDescendants()
	descendants[#descendants + 1] = root
	for _, instance in ipairs(descendants) do
		local properties = {}
		if instance:IsA("GuiObject") then
			properties[#properties + 1] = "BackgroundColor3"
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			properties[#properties + 1] = "TextColor3"
		end
		if instance:IsA("TextBox") then
			properties[#properties + 1] = "PlaceholderColor3"
		elseif instance:IsA("ScrollingFrame") then
			properties[#properties + 1] = "ScrollBarImageColor3"
		elseif instance:IsA("UIStroke") then
			properties[#properties + 1] = "Color"
		end
		local roles = context.styles[instance] or {}
		for _, property in ipairs(properties) do
			local role = roles[property]
			-- Controller writes tones directly; preserve its current semantic color.
			if not role or instance[property] ~= context.colors[role] then
				role = nil
				for candidate, oldColor in pairs(context.colors) do
					if instance[property] == oldColor then
						role = candidate
						break
					end
				end
			end
			if role then
				instance[property] = nextColors[role]
				roles[property] = role
			end
		end
		context.styles[instance] = roles
	end
	-- Controller and dynamic row factories retain this palette table.
	for role, color in pairs(nextColors) do
		context.colors[role] = color
	end
end

function UIFactory.build(widget)
	local studio = studioSettings()
	local context = {
		colors = palette(studio),
		styles = setmetatable({}, { __mode = "k" }),
		connections = {},
		destroyed = false,
	}
	local ui = { colors = context.colors, views = {}, viewButtons = {} }
	local function expose(key, instance)
		instance.Name = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
		ui[key] = instance
		return instance
	end
	local root = expose("root", create("Frame", {
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, widget))
	contexts[root] = context
	context.root = root
	paint(root, "BackgroundColor3", "background")
	context.tooltip = label(root, "", 12, "text", false)
	context.tooltip.Name = "Tooltip"; context.tooltip.Visible = false; context.tooltip.ZIndex = 50
	context.tooltip.Size = UDim2.new(1, -24, 0, 0); context.tooltip.BackgroundTransparency = 0
	paint(context.tooltip, "BackgroundColor3", "panelHover"); padding(context.tooltip, 8, 8, 8, 8)
	local header = expose("header", create("Frame", { Size = UDim2.new(1, 0, 0, 80) }, root))
	paint(header, "BackgroundColor3", "background")
	local title = fixedLabel(header, "PresetForge", 13, "text", true)
	title.Name = "ProductTitle"
	title.Position = UDim2.fromOffset(38, 6)
	title.Size = UDim2.fromOffset(82, 18)
	local maker = fixedLabel(header, "Forge Studio", 11, "muted", false)
	maker.Name = "Maker"; maker.Position = UDim2.fromOffset(121, 6); maker.Size = UDim2.fromOffset(76, 18)
	local mark = create("Frame", {Name = "ForgeMark", Position = UDim2.fromOffset(12, 3), Size = UDim2.fromOffset(20, 26.25), BackgroundTransparency = 1}, header)
	local markRow = 0
	for row in forgeMarkRaster:gmatch("([^\n]*)\n") do
		for x, width, alpha in row:gmatch("(%d+),(%d+),(%d+)") do
			local run = create("Frame", {Position = UDim2.fromScale(tonumber(x)/32, markRow/42), Size = UDim2.fromScale(tonumber(width)/32, 1/42), BackgroundTransparency = 1-tonumber(alpha)/255}, mark)
			paint(run, "BackgroundColor3", "text")
		end
		markRow += 1
	end
	expose("detailName", fixedLabel(header, "Choose a recipe", 18, "text", true))
	ui.detailName.Position = UDim2.fromOffset(12, 32); ui.detailName.Size = UDim2.new(1, -94, 0, 25); tip(ui.detailName)
	expose("libraryBadge", fixedLabel(header, "", 11, "accentText", false))
	ui.libraryBadge.Position = UDim2.new(1, -78, 0, 35); ui.libraryBadge.Size = UDim2.fromOffset(66, 20); ui.libraryBadge.TextXAlignment = Enum.TextXAlignment.Right
	expose("detailCounts", fixedLabel(header, "No recipe selected", 12, "muted", false))
	ui.detailCounts.Position = UDim2.fromOffset(12, 59); ui.detailCounts.Size = UDim2.new(1, -24, 0, 18); tip(ui.detailCounts)
	local headerLine = separator(header); headerLine.Position = UDim2.new(0, 0, 1, -1)
	local navigation = create("Frame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 82),
		Size = UDim2.new(1, -24, 0, 32),
	}, header)
	local tabLayout = create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(4, 4),
		CellSize = UDim2.new(1/3, -3, 0, 30),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, navigation)
	local body = expose("body", create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, root))
	for index, name in ipairs({ "Library", "Recipe", "Targets", "Changes" }) do
		local view
		if name == "Library" then
			view = create("Frame", {
				Name = "LibraryView",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ClipsDescendants = true,
			}, body)
		elseif name == "Targets" then
			view = stack(body, "TargetsView")
		else
			view = scroll(body, name .. "View")
		end
		view.Visible = name == "Library"
		ui.views[name] = view
		local tab = quiet(button(navigation, name == "Changes" and "Targets / Changes" or name, false))
		tab.Name = name .. "Tab"
		tab.LayoutOrder = index
		ui.viewButtons[name] = tab
		if name == "Targets" then tab.Visible = false end
		listen(tab, tab.Activated, function()
			ui.showView(name)
		end)
	end
	ui.detailScroll = ui.views.Recipe
	ui.views.Targets.Parent = ui.views.Changes
	ui.views.Targets.LayoutOrder = 0
	local paneLine = separator(body); paneLine.Size = UDim2.new(0, 1, 1, 0)
	local library = ui.views.Library
	local libraryControls = stack(library, "LibraryControls")
	libraryControls.Position = UDim2.fromOffset(12, 12)
	libraryControls.Size = UDim2.new(1, -24, 0, 0)
	local libraryTitle = pair(libraryControls, "LibraryHeading")
	local libraryLabel = fixedLabel(libraryTitle, "RECIPES", 11, "muted", true); libraryLabel.Size = UDim2.new(1, -32, 1, 0)
	expose("saveButton", quiet(button(libraryTitle, "+", false)))
	ui.saveButton.Position = UDim2.new(1, -28, 0, 0); ui.saveButton.Size = UDim2.fromOffset(28, 28); ui.saveButton.TextSize = 22
	tip(ui.saveButton, "Capture a recipe from the selected source")
	expose("searchInput", textBox(libraryControls, "Search recipes"))
	-- A search query stays on one line so a pasted query cannot hide the library.
	ui.searchInput.AutomaticSize = Enum.AutomaticSize.None
	ui.searchInput.TextWrapped = false
	expose("presetList", scroll(library, "PresetList"))
	ui.presetList.Position = UDim2.fromOffset(0, 84)
	ui.presetList.Size = UDim2.new(1, 0, 1, -84)

	local recipe = ui.views.Recipe
	label(recipe, "Captured recipe", 16, "text", true)
	expose("capturedFields", stack(recipe, "CapturedFields"))
	separator(recipe)
	local editRow = pair(recipe, "EditActions")
	expose("editButton", inPair(button(editRow, "Edit", false), 1))
	expose("duplicateButton", inPair(button(editRow, "Duplicate", false), 2))
	local nameRow = pair(recipe, "RecipeActions")
	expose("renameButton", inPair(button(nameRow, "Rename", false), 1))
	expose("recaptureButton", inPair(button(nameRow, "Recapture", false), 2))
	local renamePanel = expose("renamePanel", stack(recipe, "RenamePanel"))
	renamePanel.Visible = false
	expose("renameInput", textBox(renamePanel, "Recipe name"))
	local renameActions = pair(renamePanel, "RenameActions")
	expose("renameCancel", inPair(button(renameActions, "Cancel", false), 1))
	expose("renameConfirm", inPair(button(renameActions, "Save", true), 2))
	expose("capturedText", label(recipe, "Select a recipe to inspect its fields.", 14, "text", false))
	ui.capturedText.Visible = false
	expose("deleteButton", button(recipe, "Delete", false))
	paint(ui.deleteButton, "TextColor3", "danger")
	for _, key in ipairs({"editButton", "duplicateButton", "renameButton", "recaptureButton", "deleteButton"}) do quiet(ui[key]) end
	function ui.renderCaptured(selectedRecipe, formatValue)
		for _, child in ipairs(ui.capturedFields:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		if not selectedRecipe then label(ui.capturedFields, "No captured fields", 13, "muted", false); return end
		local function section(name, values)
			local keys = {}; for key in pairs(values) do keys[#keys + 1] = key end; table.sort(keys)
			if #keys == 0 then return end
			label(ui.capturedFields, name, 11, "muted", true)
			for _, key in ipairs(keys) do
				local field = stack(ui.capturedFields, "CapturedField")
				field:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 2)
				label(field, key, 13, "text", true)
				label(field, formatValue(values[key]), 12, "muted", false)
			end
		end
		section("PROPERTIES", selectedRecipe.properties)
		if selectedRecipe.capture.tags and #selectedRecipe.tags > 0 then
			label(ui.capturedFields, "TAGS", 11, "muted", true)
			label(ui.capturedFields, table.concat(selectedRecipe.tags, ", "), 13, "text", false)
		end
		if selectedRecipe.capture.attributes then section("ATTRIBUTES", selectedRecipe.attributes) end
	end

	local targets = ui.views.Targets
	targets:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 4)
	local targetHeading = pair(targets, "TargetHeading"); targetHeading.Size = UDim2.new(1, 0, 0, 18)
	local scopeTitle = fixedLabel(targetHeading, "TARGETS", 11, "muted", true); scopeTitle.Size = UDim2.new(0.35, 0, 1, 0)
	expose("selectionText", fixedLabel(targetHeading, "0 selected", 11, "muted", false))
	ui.selectionText.Position = UDim2.fromScale(0.35, 0); ui.selectionText.Size = UDim2.fromScale(0.65, 1); ui.selectionText.TextXAlignment = Enum.TextXAlignment.Right
	tip(ui.selectionText)
	local scopeRow = pair(targets, "ScopeOptions")
	expose("scopeSelectionButton", inPair(quiet(button(scopeRow, "Selection", false)), 1))
	expose("scopeDescendantsButton", inPair(quiet(button(scopeRow, "Descendants", false)), 2))
	UIFactory.setSegment(ui.scopeSelectionButton, true)
	local filters = expose("filterPanel", stack(targets, "FilterPanel"))
	filters.Visible = false
	local filterToggle = quiet(button(filters, "Filters", false)); filterToggle.TextXAlignment = Enum.TextXAlignment.Left
	filterToggle.Size = UDim2.new(1, 0, 0, 26); filterToggle.Font = Enum.Font.BuilderSans; filterToggle.TextSize = 12
	local filterFields = stack(filters, "FilterFields"); filterFields.Visible = false
	listen(filterToggle, filterToggle.Activated, function() filterFields.Visible = not filterFields.Visible end)
	for _, spec in ipairs({{"classFilterInput", "Class", "Required class"}, {"nameFilterInput", "Name contains", "Optional name"}, {"tagFilterInput", "Tag", "Optional tag"}}) do
		local row = pair(filterFields, spec[1] .. "Row")
		local caption = fixedLabel(row, spec[2], 12, "muted", false); caption.Size = UDim2.fromOffset(92, 32)
		local input = expose(spec[1], textBox(row, spec[3])); input.Position = UDim2.fromOffset(96, 0); input.Size = UDim2.new(1, -96, 0, 32)
		input.AutomaticSize = Enum.AutomaticSize.None; input.TextWrapped = false
		listen(input, input:GetPropertyChangedSignal("Text"), function()
			filterToggle.Text = "Filters  /  " .. (ui.classFilterInput and ui.classFilterInput.Text or "")
				.. ((ui.nameFilterInput and ui.nameFilterInput.Text ~= "") and "  /  name" or "")
				.. ((ui.tagFilterInput and ui.tagFilterInput.Text ~= "") and "  /  tag" or "")
		end)
	end

	local changes = ui.views.Changes
	separator(changes)
	local affectedActions = pair(changes, "AffectedActions")
	affectedActions.Size = UDim2.new(1, 0, 0, 26)
	local changesTitle = fixedLabel(affectedActions, "Changes", 17, "text", true); changesTitle.Name = "ChangesTitle"; changesTitle.Size = UDim2.new(1, -132, 1, 0)
	expose("selectAffectedButton", quiet(button(affectedActions, "Select all", false)))
	ui.selectAffectedButton.Position = UDim2.new(1, -132, 0, 0); ui.selectAffectedButton.Size = UDim2.fromOffset(70, 26); ui.selectAffectedButton.TextSize = 12
	expose("frameAffectedButton", quiet(button(affectedActions, "Frame", false)))
	ui.frameAffectedButton.Position = UDim2.new(1, -56, 0, 0); ui.frameAffectedButton.Size = UDim2.fromOffset(56, 26); ui.frameAffectedButton.TextSize = 12
	tip(ui.selectAffectedButton, "Select affected objects only"); tip(ui.frameAffectedButton, "Frame affected objects")
	expose("previewSummary", label(changes, "No preview", 12, "muted", false))
	local metrics = expose("previewMetrics", create("Frame", {Size = UDim2.new(1, 0, 0, 100), BackgroundTransparency = 1, Visible = false}, changes))
	local impact = fixedLabel(metrics, "", 20, "text", true)
	impact.Name = "AffectedMetric"; impact.Size = UDim2.new(0.62, 0, 0, 30)
	local matching = fixedLabel(metrics, "", 12, "muted", false)
	matching.Name = "MatchingMetric"; matching.Position = UDim2.fromScale(0.62, 0); matching.Size = UDim2.new(0.38, 0, 0, 30)
	matching.TextXAlignment = Enum.TextXAlignment.Right
	local scanned = fixedLabel(metrics, "", 12, "muted", false)
	scanned.Name = "ScopeMetrics"; scanned.Position = UDim2.fromOffset(0, 32); scanned.Size = UDim2.new(1, 0, 0, 20)
	tip(scanned)
	local writeMetrics = {}
	for index, spec in ipairs({{"propertyWrites", "property writes"}, {"tagWrites", "tag writes"}, {"attributeWrites", "attribute writes"}}) do
		local value = fixedLabel(metrics, "", 15, "text", true)
		value.Name = spec[1]; value.Position = UDim2.new((index - 1)/3, 0, 0, 60); value.Size = UDim2.new(1/3, -4, 0, 20)
		local caption = fixedLabel(metrics, spec[2], 11, "muted", false)
		caption.Position = UDim2.new((index - 1)/3, 0, 0, 80); caption.Size = UDim2.new(1/3, -4, 0, 18)
		writeMetrics[spec[1]] = value
	end
	function ui.renderMetrics(data)
		metrics.Visible = data ~= nil
		ui.previewSummary.Visible = data == nil
		if not data then return end
		impact.Text = tostring(data.affected) .. " will change"
		matching.Text = tostring(data.matching) .. " matching"
		scanned.Text = string.format("%d scanned / %d compatible / %d ignored", data.scanned, data.compatible, data.ignored)
		for key, control in pairs(writeMetrics) do control.Text = tostring(data[key]) end
	end
	expose("resultList", stack(changes, "ResultList"))
	for _, kind in ipairs({"Matching", "Ignored"}) do
		local row = pair(changes, kind .. "Actions")
		expose("show" .. kind .. "Button", inPair(quiet(button(row, "Show " .. kind:lower(), false)), 1))
		expose("select" .. kind .. "Button", inPair(quiet(button(row, "Select " .. kind:lower(), false)), 2))
	end

	local footer = expose("footer", create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 76),
	}, root))
	paint(footer, "BackgroundColor3", "background")
	separator(footer)
	padding(footer, 8, 12, 8, 12)
	local actions = pair(footer, "PreviewActions")
	expose("previewButton", inPair(button(actions, "Preview", false), 1))
	expose("applyButton", inPair(button(actions, "Apply", true), 2))
	local version = label(footer, "v" .. Constants.VERSION, 12, "muted", false)
	version.Name = "Version"
	version.AutomaticSize = Enum.AutomaticSize.None
	version.Position = UDim2.fromOffset(0, 40)
	version.Size = UDim2.new(1, -64, 0, 20)
	local helpButton = expose("helpButton", quiet(button(footer, "Help", false)))
	helpButton.Position = UDim2.new(1, -56, 0, 36)
	helpButton.Size = UDim2.fromOffset(56, 28)

	-- Feedback is shared by every view and scrolls independently of the fixed actions.
	local feedbackScroll = scroll(root, "FeedbackScroll")
	local feedbackPadding = feedbackScroll:FindFirstChildOfClass("UIPadding")
	feedbackPadding.PaddingTop = UDim.new(0, 4)
	feedbackPadding.PaddingBottom = UDim.new(0, 4)
	expose("feedback", label(feedbackScroll, "", 13, "muted", false))
	ui.feedback.Visible = false

	local overlay = expose("editorOverlay", create("Frame", {
		Active = true,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
		ClipsDescendants = true,
	}, root))
	paint(overlay, "BackgroundColor3", "background")
	local editorHeader = expose("editorHeader", create("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
	}, overlay))
	paint(editorHeader, "BackgroundColor3", "background")
	local editorTitle = expose("editorTitle", label(editorHeader, "Capture recipe", 18, "text", true))
	editorTitle.Position = UDim2.fromOffset(12, 12)
	editorTitle.Size = UDim2.new(1, -24, 0, 24)
	local editorScroll = expose("editorScroll", scroll(overlay, "EditorScroll"))
	editorScroll.Position = UDim2.fromOffset(0, 48)
	editorScroll.Size = UDim2.new(1, 0, 1, -104)
	expose("editorHint", label(editorScroll, "Choose the fields to capture.", 13, "muted", false))
	expose("editorSourceText", label(editorScroll, "Source: none", 13, "muted", false))
	label(editorScroll, "Recipe name", 14, "text", true).Name = "RecipeNameLabel"
	expose("editorNameInput", textBox(editorScroll, "Recipe name"))
	label(editorScroll, "Save to", 14, "text", true).Name = "StorageLabel"
	local storageRow = pair(editorScroll, "LibraryOptions")
	expose("localLibraryButton", inPair(button(storageRow, "Local", false), 1))
	expose("projectLibraryButton", inPair(button(storageRow, "Project", false), 2))
	UIFactory.setSegment(ui.localLibraryButton, true)
	expose("editorLibraryHelp", label(editorScroll, "Local recipes are saved in your Studio settings.", 13, "muted", false))
	label(editorScroll, "Fields", 14, "text", true).Name = "EditorFieldsTitle"
	expose("fieldList", stack(editorScroll, "FieldList"))
	expose("tagsCheck", UIFactory.createCheckbox(editorScroll, "Tags", false))
	expose("tagList", stack(editorScroll, "TagList"))
	expose("attributesCheck", UIFactory.createCheckbox(editorScroll, "Attributes", false))
	expose("attributeList", stack(editorScroll, "AttributeList"))
	for _, spec in ipairs({{ui.tagsCheck, ui.tagList}, {ui.attributesCheck, ui.attributeList}}) do
		spec[2].Visible = false
		listen(spec[1], spec[1]:GetAttributeChangedSignal("Checked"), function() spec[2].Visible = spec[1]:GetAttribute("Checked") == true end)
	end
	local editorFooter = expose("editorFooter", create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 56),
	}, overlay))
	paint(editorFooter, "BackgroundColor3", "background")
	padding(editorFooter, 12, 12, 12, 12)
	local editorActions = pair(editorFooter, "EditorActions")
	expose("editorCancel", inPair(button(editorActions, "Cancel", false), 1))
	expose("editorConfirm", inPair(button(editorActions, "Save", true), 2))

	local help = create("Frame", {
		Name = "HelpOverlay",
		Active = true,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
	}, root)
	paint(help, "BackgroundColor3", "background")
	local helpBody = scroll(help, "HelpBody")
	helpBody.Size = UDim2.new(1, 0, 1, -56)
	label(helpBody, "PresetForge help", 18, "text", true)
	label(helpBody, "Capture one selected source, choose fields, then save the recipe.", 14, "text", false)
	label(helpBody, "Local recipes stay in Studio settings. Saving a Project recipe writes recipe storage into this place.", 14, "text", false)
	label(helpBody, "Choose target scope and filters, then Preview. Changes shows pending writes and exact before/after values.", 14, "text", false)
	label(helpBody, "Frame affected locates changed objects. Apply writes checked fields; use Studio Undo to revert an apply.", 14, "text", false)
	local closeHelp = button(help, "Close help", false)
	closeHelp.Name = "CloseHelp"
	closeHelp.Position = UDim2.new(0, 12, 1, -44)
	closeHelp.Size = UDim2.new(1, -24, 0, 32)
	listen(helpButton, helpButton.Activated, function()
		help.Visible = true
	end)
	listen(closeHelp, closeHelp.Activated, function()
		help.Visible = false
	end)

	local function layoutViews()
		local wide = root.AbsoluteSize.X >= 520
		local current = ui.currentView or "Library"
		for viewName, view in pairs(ui.views) do
			if viewName ~= "Targets" then
				view.Visible = (viewName == "Library" and wide) or viewName == current
				view.Position = UDim2.fromOffset(wide and viewName ~= "Library" and 168 or 0, 0)
				view.Size = viewName == "Library" and wide and UDim2.new(0, 168, 1, 0) or UDim2.new(1, wide and -168 or 0, 1, 0)
			end
			UIFactory.setSegment(ui.viewButtons[viewName], viewName == current)
		end
		ui.views.Targets.Visible = true
		paneLine.Visible = wide; paneLine.Position = UDim2.fromOffset(167, 0)
		ui.viewButtons.Library.Visible = not wide
		navigation.Position = UDim2.fromOffset(wide and 180 or 12, 82)
		navigation.Size = UDim2.new(1, wide and -192 or -24, 0, 30)
		tabLayout.CellSize = UDim2.new(wide and 0.5 or 1/3, -3, 0, 30)
	end
	function ui.showView(name)
		if context.destroyed or not ui.views[name] then
			return false
		end
		if name == "Targets" then name = "Changes" end
		if name == "Library" and root.AbsoluteSize.X >= 520 then name = "Recipe" end
		ui.currentView = name
		layoutViews()
		return true
	end

	local function resize()
		local headerHeight = 120
		local feedbackLimit = root.AbsoluteSize.Y < 480 and 48 or 72
		local feedbackHeight = ui.feedback.Visible and math.min(feedbackLimit, ui.feedback.AbsoluteSize.Y + 8) or 0
		if root.AbsoluteSize.X >= 520 and ui.currentView == "Library" then ui.currentView = "Recipe" end
		layoutViews()
		header.Size = UDim2.new(1, 0, 0, headerHeight)
		body.Position = UDim2.fromOffset(0, headerHeight)
		body.Size = UDim2.new(1, 0, 1, -(headerHeight + 76 + feedbackHeight))
		feedbackScroll.Visible = ui.feedback.Visible
		feedbackScroll.Position = UDim2.new(0, 0, 1, -(76 + feedbackHeight))
		feedbackScroll.Size = UDim2.new(1, 0, 0, feedbackHeight)
	end
	listen(root, root:GetPropertyChangedSignal("AbsoluteSize"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("Visible"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("AbsoluteSize"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("Text"), function()
		feedbackScroll.CanvasPosition = Vector2.zero
	end)
	if studio then
		listen(root, studio.ThemeChanged, function()
			refreshTheme(root, context, studio)
		end)
	end
	listen(ui.editorHint, ui.editorHint:GetPropertyChangedSignal("Text"), function()
		if overlay.Visible then
			editorScroll.CanvasPosition = Vector2.zero
		end
	end)

	local function disconnect()
		if context.destroyed then
			return
		end
		context.destroyed = true
		for _, connections in pairs(context.connections) do
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
		end
		table.clear(context.connections)
		table.clear(context.styles)
		contexts[root] = nil
	end
	function ui.destroy()
		if context.destroyed then
			return
		end
		disconnect()
		root:Destroy()
	end
	listen(root, root.Destroying, disconnect)
	for _, key in ipairs({
		"renameButton", "editButton", "duplicateButton", "recaptureButton", "deleteButton",
		"previewButton", "applyButton", "selectAffectedButton", "frameAffectedButton",
		"selectMatchingButton", "selectIgnoredButton", "showMatchingButton", "showIgnoredButton",
	}) do
		UIFactory.setButtonEnabled(ui[key], false)
	end
	ui.showView("Library")
	resize()
	return ui
end

return UIFactory
