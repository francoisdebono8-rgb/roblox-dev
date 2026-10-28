-- Client: record the audit showcase (audit_show.luau) frame by frame: both
-- fighters' parts and the visible effect parts, with the server's NdPhase.
-- Background: returns at once; shared.NdAudit.done when NdPhase=="done".
local MAXDUR=90
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local frames={}
shared.NdAudit={frames=frames,done=false}
local t0=os.clock()
local conn
local function models()
	local me=Players.LocalPlayer.Character
	local folder=me and me.Parent
	return {me=me,bot=folder and folder:FindFirstChild("AIFighter")}
end
conn=RS.RenderStepped:Connect(function()
	local ph=workspace:GetAttribute("NdPhase")
	if ph=="done" or os.clock()-t0>MAXDUR then
		conn:Disconnect();shared.NdAudit.done=true;return
	end
	if ph==nil or ph=="setup" then return end
	local f={t=os.clock()-t0,phase=ph,parts={}}
	for who,model in models() do
		if model then
			for _,d in model:GetDescendants() do
				if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then
					local tr=d.Transparency+d.LocalTransparencyModifier
					if tr<.98 then table.insert(f.parts,{src=d,cf=d.CFrame,tr=tr}) end
				end
			end
		end
	end
	local fx=workspace:FindFirstChild("NinjaDuelFX")
	if fx then
		local n=0
		for _,d in fx:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency<.97 and n<250 then
				n+=1
				table.insert(f.parts,{src=d,cf=d.CFrame,tr=d.Transparency,size=d.Size,color=d.Color,mat=d.Material,shape=d:IsA("Part") and d.Shape or nil})
			end
		end
	end
	table.insert(frames,f)
end)
return "recording"
