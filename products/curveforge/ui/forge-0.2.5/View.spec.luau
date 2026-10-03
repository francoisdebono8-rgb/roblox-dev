-- Native callback smoke, not evidence of clicks in the installed commercial plugin.
return function(modules, fixtureFactory)
	local UI,View=require(modules.StudioUI),require(modules.View)
	local originalNew=UI.new
	local fixture=fixtureFactory(modules)
	local callbacks,buttons={},{}
	local gui=Instance.new("ScreenGui")
	gui.Parent=game:GetService("CoreGui")
	local dispose
	local passed=0
	local ok,err=xpcall(function()
		UI.new=function(...)
			local ui=originalNew(...)
			local originalButton=ui.button
			ui.button=function(parent,name,text,callback,style)
				local button=originalButton(parent,name,text,callback,style)
				callbacks[name],buttons[name]=callback,button
				return button
			end
			return ui
		end
		local selected={fixture.Cable.output}
		dispose=View.mount(gui,{Get=function() return selected end,Set=function(_,items) selected=items end},game:GetService("ChangeHistoryService"))
		local function check(name,fn)
			fn(); passed+=1; print("[CurveForge025][VIEW PASS] "..name)
		end
		check("Cable/Repeat both first-class and initial Build disabled",function()
			assert(buttons.Cable:IsDescendantOf(gui.CurveForgeUI.OutputMode))
			assert(buttons.Repeat:IsDescendantOf(gui.CurveForgeUI.OutputMode))
			assert(not buttons.BuildAction.Active)
		end)
		callbacks["Edit Existing"]()
		check("Edit Existing loads true comparison and exact result",function()
			assert(buttons.BuildAction.Active and buttons.Existing.Active)
			assert(gui:FindFirstChild("ContextualPreview",true):FindFirstChild("Existing"))
			assert(gui:FindFirstChild("OutputMetrics",true).Text:find("segments"))
		end)
		local outputPart=fixture.Cable.output.Output:FindFirstChildWhichIsA("BasePart")
		outputPart.Position+=Vector3.new(0,2,0); task.wait()
		check("Direct Existing geometry edit invalidates comparison and disables write",function()
			assert(not buttons.BuildAction.Active and not buttons.Existing.Active)
			assert(not gui:FindFirstChild("ContextualPreview",true))
			assert(gui:FindFirstChild("PreviewStatus",true).Text:find("stale"))
		end)
		callbacks.PreviewAction(); callbacks.Existing()
		check("Refresh recaptures actual edited Existing geometry",function()
			assert(buttons.BuildAction.Active)
			local copy=gui:FindFirstChild("ContextualPreview",true).Existing:FindFirstChild(outputPart.Name)
			assert(copy and copy.CFrame==outputPart.CFrame)
		end)
		selected={fixture.Repeat.output}; callbacks.Path(); callbacks["Edit Existing"]()
		check("Repeat load exposes custom source and exact copies",function()
			assert(buttons.BuildAction.Active and gui:FindFirstChild("OutputMetrics",true).Text:find("14 copies"))
		end)
		check("Short dock preserves review geometry and reachable commands",function()
			for _,height in ipairs({338,360}) do
				gui.CurveForgeUI.Size=UDim2.fromOffset(240,height); task.wait()
				callbacks.Preview(); task.wait()
				local root=gui.CurveForgeUI
				local preview=root:FindFirstChild("PreviewSurface",true)
				assert(preview.AbsoluteSize.Y>=96 and preview.AbsoluteSize.X>=200)
				assert(preview.AbsolutePosition.Y+preview.AbsoluteSize.Y<=root.Commands.AbsolutePosition.Y)
				assert(buttons.BuildAction.AbsolutePosition.Y+buttons.BuildAction.AbsoluteSize.Y<=root.AbsolutePosition.Y+height)
				assert(buttons.Existing.AbsoluteSize.Y>=28 and buttons.Proposed.AbsoluteSize.Y>=28)
			end
			callbacks.BuildAction(); task.wait()
			assert(gui:FindFirstChild("PreviewStatus",true).Text:find("Built:",1,true))
			assert(not buttons.BuildAction.Active)
		end)
		fixture.Repeat.source.Stem:SetAttribute("PreviewChanged",true); task.wait()
		check("Source attribute change clears ready state",function()
			assert(not buttons.BuildAction.Active and not gui:FindFirstChild("ContextualPreview",true))
		end)
	end,debug.traceback)
	UI.new=originalNew
	if dispose then dispose() end
	gui:Destroy(); fixture.root:Destroy()
	if not ok then warn("[CurveForge025][VIEW FAIL] "..tostring(err)) end
	print(string.format("[CurveForge025][VIEW] %d passed / %d failed; callback smoke only",passed,ok and 0 or 1))
	return ok
end
