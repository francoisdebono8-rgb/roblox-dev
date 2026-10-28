-- Client: chronophotograph of the audit recording. One row per phase in ROWS
-- (a phase name or a prefix ending in "*"), K instants evenly spread over the
-- phase, frozen copies of everything recorded, laid out in the sky (Y+400),
-- seen from the side with the HUD hidden. MODE="clear" restores the view.
local MODE="show"
local ROWS={"chain","heavy"}
local K=8
local CELL=13
local ROWGAP=9
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local function restore()
	pcall(function() RS:UnbindFromRenderStep("NdAuditCam") end)
	if shared.NdAuditGrid then shared.NdAuditGrid:Destroy();shared.NdAuditGrid=nil end
	for gui,was in shared.NdAuditGuis or {} do pcall(function() gui.Enabled=was end) end
	shared.NdAuditGuis=nil
end
restore()
if MODE=="clear" then return "cleared" end
local rec=shared.NdAudit
if not rec or #rec.frames==0 then return "no recording" end
local grid=Instance.new("Model");grid.Name="NdAuditGrid"
local function matches(ph,pat)
	if string.sub(pat,-1)=="*" then return string.sub(ph,1,#pat-1)==string.sub(pat,1,-2) end
	return ph==pat
end
local info={}
local rowsUsed=0
local origin=nil
local axis,side
for r,pat in ROWS do
	local sel={}
	for _,f in rec.frames do if matches(f.phase,pat) then table.insert(sel,f) end end
	if #sel>0 then
		rowsUsed+=1
		local base=sel[1]
		-- Row frame: the fighters' line at the first frame of the phase.
		local me,bot
		for _,p in base.parts do
			if p.src.Parent and p.src.Name=="UpperTorso" then
				local m=p.src:FindFirstAncestorOfClass("Model")
				if m==Players.LocalPlayer.Character then me=p.cf.Position else bot=p.cf.Position end
			end
		end
		me=me or Vector3.zero;bot=bot or (me+Vector3.new(0,0,-5))
		local ax=Vector3.new(bot.X-me.X,0,bot.Z-me.Z)
		ax=if ax.Magnitude>.1 then ax.Unit else Vector3.zAxis
		local mid=(me+bot)/2
		local dest=Vector3.new(0,400-(rowsUsed-1)*ROWGAP,0)
		axis=axis or ax
		side=side or axis:Cross(Vector3.yAxis).Unit
		-- each row is rotated so its own fighters' line lies along the common axis
		local rowRot=CFrame.lookAt(Vector3.zero,ax)
		local common=CFrame.lookAt(Vector3.zero,axis)
		for k=0,K-1 do
			local f=sel[math.clamp(1+math.floor((#sel-1)*k/math.max(1,K-1)+.5),1,#sel)]
			local cellOrigin=CFrame.new(dest+axis*(k*CELL))*common*rowRot:Inverse()*CFrame.new(-mid)
			for _,p in f.parts do
				local src=p.src
				local g
				if p.size then
					g=Instance.new("Part");g.Size=p.size;g.Color=p.color;g.Material=p.mat
					if p.shape then pcall(function() g.Shape=p.shape end) end
				elseif src and src.Parent then
					local ok,c=pcall(function() src.Archivable=true;local c=src:Clone();for _,ch in c:GetChildren() do ch:Destroy() end;return c end)
					g=ok and c or nil
				end
				if g then
					g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false
					g.CFrame=cellOrigin*p.cf;g.Transparency=p.tr;g.LocalTransparencyModifier=0
					g.Parent=grid
				end
			end
		end
		table.insert(info,string.format("row %d %s: %d frames %.2f-%.2fs",rowsUsed,pat,#sel,sel[1].t,sel[#sel].t))
	end
end
grid.Parent=workspace
shared.NdAuditGrid=grid
local guis={}
for _,g in Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") then guis[g]=g.Enabled;g.Enabled=false end end
shared.NdAuditGuis=guis
axis=axis or Vector3.zAxis;side=side or Vector3.xAxis
local width=(K-1)*CELL+8
local height=rowsUsed*ROWGAP
local center=Vector3.new(0,400-(rowsUsed-1)*ROWGAP/2+.5,0)+axis*((K-1)*CELL/2)
local fov=36
local dist=math.max(width/(2*math.tan(math.rad(fov/2)))/ (16/9)*1.0, height/(2*math.tan(math.rad(fov/2))))*1.08+4
local cam=workspace.CurrentCamera
RS:BindToRenderStep("NdAuditCam",Enum.RenderPriority.Last.Value,function()
	cam.CameraType=Enum.CameraType.Scriptable
	cam.FieldOfView=fov
	cam.CFrame=CFrame.lookAt(center+side*dist+Vector3.new(0,dist*.12,0),center)
end)
return table.concat(info,"\n")
