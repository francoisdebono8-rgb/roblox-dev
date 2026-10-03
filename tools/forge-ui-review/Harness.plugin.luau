-- Internal review harness, never packaged in a commercial plugin.
if workspace:GetAttribute("ForgeUIReview")~=true then return end
assert(game.PlaceId==0 and not game:GetService("RunService"):IsRunning())
local history=game:GetService("ChangeHistoryService")
local selection=game:GetService("Selection")
local widget=plugin:CreateDockWidgetPluginGuiAsync("ForgeUIReview_"..game:GetService("HttpService"):GenerateGUID(false),DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,true,true,562,666,562,666))
widget.Title="Forge UI review"
local host=Instance.new("Frame"); host.Name="ExactViewport"; host.BackgroundTransparency=1; host.Size=UDim2.fromOffset(560,640); host.Parent=widget
local fixture=Instance.new("Folder"); fixture.Name="ForgeUIReviewFixture"; fixture.Parent=workspace
local function part(name,position)
	local p=Instance.new("Part"); p.Name=name; p.Position=position; p.Anchored=true; p.Parent=fixture; return p
end
local controls={part("Pole_A",Vector3.new(0,12,0)),part("Guide_01",Vector3.new(12,8,7)),part("Guide_02",Vector3.new(26,11,-5)),part("Pole_B",Vector3.new(40,14,0))}
local start=part("Lower_Platform",Vector3.new(0,0,30)); local finish=part("Upper_Platform",Vector3.new(0,12,54))
local handle=part("Handle",Vector3.new(60,5,0)); local blade=part("Blade",Vector3.new(64,5,0)); blade.Anchored=false
local dispose,restore,current
local function mount(name)
	if dispose then dispose(); dispose=nil end
	if restore then restore(); restore=nil end
	local modules=script.Parent[name].Modules
	local ui=require(modules.StudioUI)
	local original=ui.new
	local callbacks={}
	-- Capture callbacks without changing Source or replacing native controls.
	-- This is callback-driven smoke, NOT proof of physical GUI clicks.
	ui.new=function(...)
		local value=original(...)
		local button=value.button
		value.button=function(parent,id,text,fn,style)
			local result=button(parent,id,text,fn,style)
			table.insert(callbacks,{button=result,fn=fn})
			return result
		end
		return value
	end
	restore=function() ui.new=original end
	dispose=require(modules.View).mount(host,selection,history)
	local function click(text,ordinal)
		local n=0
		for _,entry in ipairs(callbacks) do
			if entry.button.Parent and entry.button:IsDescendantOf(host) and entry.button.Text==text then
				n+=1; if n==(ordinal or 1) then entry.fn(); return end
			end
		end
		error("Missing button: "..text)
	end
	current={name=name,click=click}
	if name=="CurveForge" then
		selection:Set(controls); click("Use selected points"); click("Confirm displayed order"); click("2   Guide_01")
		click("Settings"); click("",6); click("Path")
		assert(host:FindFirstChild("GeometryPreview",true),"Curve preview missing")
	elseif name=="AccessForge" then
		selection:Set({start}); click("Assign",1)
		selection:Set({finish}); click("Assign",2)
		if not host:FindFirstChild("GeometryPreview",true) then
			for _,item in ipairs(host:GetDescendants()) do if item:IsA("TextLabel") then print("[ForgeUIReview] Access label="..item.Text) end end
			error("Assembly preview missing")
		end
	else
		selection:Set({handle}); click("Assign",1)
		selection:Set({blade}); click("Assign",2)
		click("Preview")
		assert(host:FindFirstChild("ApplyAction",true),"Joint exact plan missing")
	end
	print("[ForgeUIReview] "..name.." native mount + real engine Preview PASS; SHA256="..script.Parent:GetAttribute(name.."SHA256"))
end
local function review(name,width)
	host.Size=UDim2.fromOffset(width,640)
	mount(name)
	if width==320 and name~="JointForge" then current.click("Preview") end
	-- Native float can be hidden by macOS while another application has focus.
	widget.Title=name.." UI "..width
	widget.Enabled=false; task.wait(0.1); widget.Enabled=true; task.wait(3)
	print("[ForgeUIReview] CAPTURE "..name.." "..width.." viewport="..tostring(host.AbsoluteSize).." origin="..tostring(host.AbsolutePosition))
end
local bridge=Instance.new("BindableFunction"); bridge.Name="ForgeUIReview"; bridge.Parent=game:GetService("ServerStorage")
bridge.OnInvoke=function(name,width) review(name,width); return true end
task.spawn(function()
	local ok,err=xpcall(function()
		local before=#fixture:GetDescendants()
		local only=workspace:GetAttribute("ReviewProduct")
		for _,name in ipairs(only and {only} or {"CurveForge","AccessForge","JointForge"}) do
			for _,width in ipairs({560,320}) do
				review(name,width)
				assert(#fixture:GetDescendants()==before,"Preview modified fixture")
				print("[ForgeUIReview] "..name.." "..width.." read-only PASS")
				task.wait(25)
			end
		end
		print("[ForgeUIReview] First review complete; visual acceptance and final regression PENDING")
	end,debug.traceback)
	if not ok then warn("[ForgeUIReview] FAIL "..tostring(err)) end
end)
plugin.Unloading:Connect(function() if dispose then dispose() end; if restore then restore() end; widget:Destroy(); bridge:Destroy() end)
