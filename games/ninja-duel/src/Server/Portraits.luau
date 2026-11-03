-- The menu's fighters (UI pass 02/11, user: "be original in everything"): the
-- select screen shows each prodigy as he is in the duel, not a coloured block.
-- Once per server, every roster fighter is built with the duel's own rig and
-- costume (World.rig, World.dress), set in a guard stance, anchored, and kept
-- in ReplicatedStorage.NinjaDuelPortraits; Client/UI clones them into its
-- ViewportFrames. Built after the costume meshes had their chance to load,
-- one fighter per frame. Presentation only: nothing here touches a duel.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Portraits={}

-- A ready stance: guard up, weight low, the lead foot forward (radians).
local STANCE={
	-- (Menu staging 02/11) Hands at the chest, never in front of the face the
	-- bust shot is about; the head square to the shoulders.
	LeftShoulder=CFrame.Angles(math.rad(38),math.rad(-10),math.rad(-14)),
	RightShoulder=CFrame.Angles(math.rad(26),math.rad(12),math.rad(16)),
	LeftElbow=CFrame.Angles(math.rad(72),0,0),
	RightElbow=CFrame.Angles(math.rad(84),0,0),
	LeftHip=CFrame.Angles(math.rad(14),0,math.rad(-6)),
	RightHip=CFrame.Angles(math.rad(-10),0,math.rad(6)),
	LeftKnee=CFrame.Angles(math.rad(-18),0,0),
	RightKnee=CFrame.Angles(math.rad(-8),0,0),
	Waist=CFrame.Angles(math.rad(-4),math.rad(-10),0),
	Neck=CFrame.Angles(math.rad(2),math.rad(6),0),
}

local function strip(model)
	for _,d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Light") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false end
	end
	local hum=model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff end
end

function Portraits.build()
	if ReplicatedStorage:FindFirstChild("NinjaDuelPortraits") then return end
	local World=require(script.Parent.World)
	local Fighters=require(ReplicatedStorage.NinjaDuel.Fighters)
	-- (Beta 03/11) the select screen's fighters: the beta's (Shared/BetaRoster).
	local Roster=require(ReplicatedStorage.NinjaDuel.BetaRoster)
	local LookMeshes=require(script.Parent.LookMeshes)
	-- Costume meshes load in the background: give them a few seconds.
	local waited=os.clock()
	while os.clock()-waited<8 do
		local pending=false
		for _,state in LookMeshes.state do if state=="loading" then pending=true break end end
		if not pending then break end
		task.wait(.25)
	end
	-- Built in the workspace (the rig's network owner call needs it), far
	-- under the arena, then moved to ReplicatedStorage.
	local stage=Instance.new("Folder");stage.Name="NinjaDuelPortraitStage";stage.Parent=workspace
	local out=Instance.new("Folder");out.Name="NinjaDuelPortraits"
	for index,id in Roster do
		local def=Fighters[id]
		if def then
			local ok,err=pcall(function()
				local at=CFrame.new(index*12,700,-3000)
				local model,_,root,joints=World.rig(stage,def,at,id)
				root.Anchored=true
				-- Posed through C0 (a joint's Transform is the animator's, reset
				-- every frame); one physics step lays the limbs on the joints.
				for name,angles in STANCE do
					local joint=joints[name] or model:FindFirstChild(name,true)
					if joint and joint:IsA("Motor6D") then joint.C0=joint.C0*angles end
				end
				RunService.Heartbeat:Wait();RunService.Heartbeat:Wait()
				strip(model)
				-- Some costumes are built non-archivable: the client clones these.
				model.Archivable=true
				for _,d in model:GetDescendants() do d.Archivable=true end
				model:SetAttribute("Fighter",id)
				-- The client frames a fighter once all of it has replicated.
				model:SetAttribute("Descendants",#model:GetDescendants())
				model.Parent=out
			end)
			if not ok then warn("[NinjaDuel] portrait "..tostring(id)..": "..tostring(err)) end
			task.wait()
		end
	end
	stage:Destroy()
	out:SetAttribute("Count",#out:GetChildren())
	out.Parent=ReplicatedStorage
end

function Portraits.start()
	task.spawn(function()
		local ok,err=pcall(Portraits.build)
		if not ok then warn("[NinjaDuel] portraits unavailable: "..tostring(err)) end
	end)
end
return Portraits
