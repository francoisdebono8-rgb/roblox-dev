local CollectionService = game:GetService("CollectionService")
local Support = require(script.Parent.GateTestSupport)

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
	for _ = 1, 30 do
		task.wait()
		local parts = {}
		for _, object in ipairs(root:GetDescendants()) do
			if object:IsA("GuiObject") and visible(object, root) then
				parts[#parts + 1] = tostring(object.AbsolutePosition) .. "/" .. tostring(object.AbsoluteSize)
				if object:IsA("ScrollingFrame") then parts[#parts + 1] = tostring(object.AbsoluteCanvasSize) end
				if object:IsA("TextLabel") or object:IsA("TextButton") then parts[#parts + 1] = tostring(object.TextBounds) end
			end
		end
		local signature = table.concat(parts, "|")
		stable = signature == previous and stable + 1 or 0
		if stable >= 3 then return end
		previous = signature
	end
	error("UI layout did not settle within 30 scheduler frames")
end

local function horizontalBounds(object, parent)
	local left = object.AbsolutePosition.X
	local right = left + object.AbsoluteSize.X
	assert(object.AbsoluteSize.X > 0, object:GetFullName() .. ": zero/negative width")
	assert(left >= parent.AbsolutePosition.X - 1 and right <= parent.AbsolutePosition.X + parent.AbsoluteSize.X + 1,
		string.format("%s: horizontal clipping [%.1f, %.1f] outside %s [%.1f, %.1f]", object:GetFullName(), left, right,
			parent.Name, parent.AbsolutePosition.X, parent.AbsolutePosition.X + parent.AbsoluteSize.X))
end

local function checkGeometry(root)
	local measured = 0
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("GuiObject") and visible(object, root) then
			measured += 1
			horizontalBounds(object, root)
			if object.Parent:IsA("GuiObject") then horizontalBounds(object, object.Parent) end
			if object:IsA("ScrollingFrame") then
				assert(object.ScrollingDirection == Enum.ScrollingDirection.Y, object.Name .. ": horizontal scrolling enabled")
				assert(object.CanvasSize.X.Scale == 0 and object.CanvasSize.X.Offset == 0, object.Name .. ": horizontal canvas configured")
				assert(object.AbsoluteCanvasSize.X <= object.AbsoluteSize.X + 1, object.Name .. ": canvas exceeds viewport width")
			elseif (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text ~= "" then
				local truncatedIdentity = object:IsA("TextLabel") and object.TextTruncate == Enum.TextTruncate.AtEnd
				local fits = truncatedIdentity or object.TextFits
				if not fits then
					-- TextFits also sees ancestor clipping. Measure the same control at its
					-- actual size without that clipping; scroll reachability is checked separately.
					local probe = object:Clone()
					probe.AutomaticSize = Enum.AutomaticSize.None
					probe.Size = UDim2.fromOffset(object.AbsoluteSize.X, object.AbsoluteSize.Y)
					probe.Position = UDim2.fromOffset(0, 0)
					probe.Parent = root:FindFirstAncestorOfClass("ScreenGui")
					task.wait(); task.wait()
					fits = probe.TextFits
					probe:Destroy()
				end
				assert(fits, string.format("%s: text does not fit: size=%s bounds=%s text=%s",
					object:GetFullName(), tostring(object.AbsoluteSize), tostring(object.TextBounds), object.Text:sub(1, 70)))
				if object.Name == "ObjectPath" then
					assert(object.TextBounds.X <= object.AbsoluteSize.X + 1, "Object path overflows after truncation")
				end
			end
		end
	end
	assert(measured > 10, "Layout check must measure a populated, rendered UI")
end

local function inViewport(object, root)
	assert(visible(object, root), object.Name .. ": required control is hidden")
	assert(object.AbsoluteSize.Y > 0, object.Name .. ": required control has no height")
	local top = object.AbsolutePosition.Y
	local bottom = top + object.AbsoluteSize.Y
	local ancestor = object.Parent
	while ancestor and ancestor ~= root.Parent do
		if ancestor:IsA("GuiObject") and (ancestor == root or ancestor.ClipsDescendants) then
			local viewTop = ancestor.AbsolutePosition.Y
			local height = ancestor:IsA("ScrollingFrame") and ancestor.AbsoluteWindowSize.Y or ancestor.AbsoluteSize.Y
			assert(math.min(bottom, viewTop + height) - math.max(top, viewTop) > 1,
				object:GetFullName() .. ": action is clipped vertically by " .. ancestor.Name)
		end
		ancestor = ancestor.Parent
	end
end

local function reach(object, root)
	local ancestor = object.Parent
	while ancestor and ancestor ~= root.Parent do
		if ancestor:IsA("ScrollingFrame") then
			local desired = ancestor.CanvasPosition.Y + object.AbsolutePosition.Y - ancestor.AbsolutePosition.Y
			local spare = math.max(0, ancestor.AbsoluteWindowSize.Y - object.AbsoluteSize.Y)
			local maximum = math.max(0, ancestor.AbsoluteCanvasSize.Y - ancestor.AbsoluteWindowSize.Y)
			ancestor.CanvasPosition = Vector2.new(0, math.clamp(desired - spare / 2, 0, maximum))
			task.wait()
		end
		ancestor = ancestor.Parent
	end
	inViewport(object, root)
end

return function(test)
	for _, width in ipairs({ 240, 320, 400, 560 }) do
		for _, height in ipairs({ 360, 640, 900 }) do
			test(string.format("%dx%d / library, recipe, targets/changes, capture, fixed actions", width, height), function(cleanup)
				local repository = Support.repository(cleanup)
				local folder = Instance.new("Folder")
				folder.Name = "LongContainerNameWithoutSpacesForWrapping"
				cleanup(function() folder:Destroy() end)
				local target = Support.part(folder, string.rep("TargetName", 8), false)
				local matching = Support.part(folder, "Matching", true)
				local ignored = Instance.new("Folder")
				ignored.Parent = folder
				local recipe = Support.recipe()
				recipe.attributes.Note = string.rep("Exact long value [literal].% ", 10) .. "END"
				for name, value in pairs(recipe.attributes) do matching:SetAttribute(name, value) end
				for _, tag in ipairs(recipe.tags) do CollectionService:AddTag(matching, tag) end
				local longName = string.rep("LongName", 5)
				assert(repository:create("Local", longName, recipe))
				for index = 1, 8 do assert(repository:create("Project", "Other recipe " .. index, recipe)) end
				local host = Support.host(cleanup, width, height)
				local controller, ui, selection = Support.controller(cleanup, repository, { folder }, host)
				Support.selectRecipe(controller, "Local", longName)
				controller:_setScope("Descendants")
				controller:_runPreview()
				controller._showMatching, controller._showIgnored = true, true
				controller:_renderResults()
				settle(ui.root)
				assert(math.abs(ui.root.AbsoluteSize.X - width) <= 1 and math.abs(ui.root.AbsoluteSize.Y - height) <= 1,
					"host did not render at the requested dimensions")
				local headerPosition, footerPosition = ui.header.AbsolutePosition, ui.footer.AbsolutePosition
				local controls = {
					Library = { "searchInput", "saveButton" },
					Recipe = { "editButton", "duplicateButton", "renameButton", "recaptureButton", "deleteButton", "renameInput", "renameConfirm", "renameCancel" },
					Targets = { "scopeSelectionButton", "scopeDescendantsButton", "classFilterInput", "nameFilterInput", "tagFilterInput" },
					Changes = { "selectAffectedButton", "frameAffectedButton", "showMatchingButton", "showIgnoredButton", "selectMatchingButton", "selectIgnoredButton" },
				}
				ui.renamePanel.Visible = true
				ui.renameInput.Text = longName
				for _, name in ipairs({ "Library", "Recipe", "Targets", "Changes" }) do
					assert(ui.showView(name) ~= false, "showView rejected " .. name)
					ui.filterPanel.FilterFields.Visible = name == "Targets"
					settle(ui.root)
					assert(ui.views[name].Visible and ui.body.AbsoluteSize.Y > 0)
					checkGeometry(ui.root)
					assert(not ui.viewButtons.Targets.Visible, "Targets must share the Changes workspace")
					assert(ui.viewButtons.Library.Visible == (width < 520), "Wide library must use its own pane")
					for _, tab in pairs(ui.viewButtons) do if tab.Visible then inViewport(tab, ui.root) end end
					for _, key in ipairs(controls[name]) do reach(assert(ui[key], key), ui.root) end
					if name == "Library" then
						local rows = 0
						for _, row in ipairs(ui.presetList:GetChildren()) do
							if row:IsA("TextButton") then reach(row, ui.root); rows += 1 end
						end
						assert(rows == 9, "populated recipe list missing rows")
					end
					inViewport(ui.previewButton, ui.root)
					inViewport(ui.applyButton, ui.root)
					assert(ui.header.AbsolutePosition == headerPosition and ui.footer.AbsolutePosition == footerPosition,
						"body scrolling moved fixed header/footer")
				end

				selection:Set({ target })
				task.wait()
				controller:_openEdit()
				assert(ui.editorOverlay.Visible)
				settle(ui.editorOverlay)
				checkGeometry(ui.editorOverlay)
				local editorFooterPosition = ui.editorFooter.AbsolutePosition
				for _, key in ipairs({ "editorNameInput", "localLibraryButton", "projectLibraryButton", "tagsCheck", "attributesCheck" }) do
					reach(ui[key], ui.editorOverlay)
				end
				local fields = 0
				for _, checkbox in pairs(controller._editorFields) do
					reach(checkbox, ui.editorOverlay)
					fields += 1
				end
				assert(fields >= 7, "capture field list was not populated")
				inViewport(ui.editorConfirm, ui.editorOverlay)
				inViewport(ui.editorCancel, ui.editorOverlay)
				assert(ui.editorFooter.AbsolutePosition == editorFooterPosition, "field scrolling moved Save/Cancel")
			end)
		end
	end
end
