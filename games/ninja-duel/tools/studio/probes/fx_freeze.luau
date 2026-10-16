-- Client: freeze-frame of an effect for a screenshot. Waits for an object named
-- TARGET under NinjaDuelFX, waits DELAY, then copies every visible effect and
-- fighter part into workspace.FrozenFX (anchored, static), hides the live
-- bodies and holds a side camera on it. TARGET="off" clears everything.
local TARGET="SandLash"
local DELAY=.15
local DIST=17
local HEIGHT=4
local VIEW="side" -- or "behind": over the human's shoulder, like the game camera
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
pcall(function() RS:UnbindFromRenderStep("NdFreezeCam") end)
local old=workspace:FindFirstChild("FrozenFX");if old then old:Destroy() end
local function bodies()
	local me=Players.LocalPlayer.Character
	local bot=me and me.Parent and me.Parent:FindFirstChild("AIFighter")
	return me,bot
end
if TARGET=="off" then
	local me,bot=bodies()
	for _,m in {me,bot} do if m then for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=0 end end end end
	return "freeze off"
end
shared.NdFreeze="waiting"
task.spawn(function()
	local fxf=workspace:WaitForChild("NinjaDuelFX",10)
	local t0=os.clock();local hit
	while os.clock()-t0<25 do
		for _,d in fxf:GetDescendants() do if d.Name==TARGET then hit=d;break end end
		if hit then break end
		RS.RenderStepped:Wait()
	end
	if not hit then shared.NdFreeze="timeout";return end
	local t1=os.clock()
	while os.clock()-t1<DELAY do RS.RenderStepped:Wait() end
	local frozen=Instance.new("Folder");frozen.Name="FrozenFX"
	local function copy(part)
		local ok,c=pcall(function() return part:Clone() end)
		if not ok or not c then return nil end
		for _,x in c:GetDescendants() do
			if x:IsA("JointInstance") or x:IsA("WeldConstraint") or x:IsA("Constraint") or x:IsA("BasePart") then x:Destroy() end
		end
		c.Anchored=true;c.CanCollide=false;c.CanQuery=false;c.CFrame=part.CFrame;c.LocalTransparencyModifier=0;c.Parent=frozen
		return c
	end
	local sum,n=Vector3.zero,0
	-- Effect models are cloned whole (their Beams keep their handles); loose
	-- parts are copied one by one.
	for _,top in fxf:GetChildren() do
		if top:IsA("Model") then
			local ok,c=pcall(function() return top:Clone() end)
			if ok and c then
				for _,x in c:GetDescendants() do
					if x:IsA("BasePart") then x.Anchored=true;x.CanCollide=false end
					if x:IsA("JointInstance") or x:IsA("WeldConstraint") then x:Destroy() end
				end
				c.Parent=frozen
			end
			for _,d in top:GetDescendants() do
				if d:IsA("BasePart") and (top==hit or d==hit or top:IsDescendantOf(hit) or d:IsDescendantOf(hit)) then sum+=d.Position;n+=1 end
			end
		elseif top:IsA("BasePart") and top.Transparency<.98 then
			copy(top)
		end
	end
	local me,bot=bodies()
	for _,m in {me,bot} do
		if m then for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<.98 and p.Name~="HumanoidRootPart" then copy(p) end end end
	end
	local focus=if n>0 then sum/n elseif hit:IsA("BasePart") then hit.Position else (me and me:GetPivot().Position or Vector3.zero)
	local a=me and me:FindFirstChild("HumanoidRootPart");local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local line=if a and b then (b.Position-a.Position)*Vector3.new(1,0,1) else Vector3.zAxis
	local side=if line.Magnitude>.1 then line.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
	if a and b then focus=focus:Lerp((a.Position+b.Position)/2,.35) end
	frozen.Parent=workspace
	local cam=workspace.CurrentCamera
	RS:BindToRenderStep("NdFreezeCam",Enum.RenderPriority.Camera.Value+6,function()
		local eye=if VIEW=="behind" and a and b then a.Position-line.Unit*DIST+Vector3.new(0,HEIGHT,0)+side*2 else focus+side*DIST+Vector3.new(0,HEIGHT,0)
		cam.CFrame=CFrame.lookAt(eye,focus)
		cam.FieldOfView=50
		for _,m in {me,bot} do if m then for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=1 end end end end
	end)
	shared.NdFreeze=string.format("frozen %s (%d parts in it, %d copied)",TARGET,n,#frozen:GetChildren())
end)
return "armed "..TARGET
