-- The player's own Roblox avatar as his fighter's body (DEC-036, user 12/11
-- 16:49: « c'est avec mon perso Roblox personnel qu'il faut tester, c'est ça
-- le vrai délire »). His clothes, layered clothing, hair, accessories, face
-- and skin; the KIT stays the prodigy's (stats, moves, jutsu, animations,
-- effects), and the pieces of that kit which serve a technique are put on
-- him (Shared/Appearance.KitItems: Gaara's gourd, Kakashi's tanto...).
--
-- One skeleton for everyone: the avatar is built at the standard scales
-- (height, width, depth, head 1; body type and proportions 0), then its joints
-- are set on the game's own skeleton (World.RIG): every joint pivot sits where
-- the rig's does, each part keeps its own offset from its pivot. So the
-- Blender clips, the feet planted on the floor and the reach are the same for
-- every avatar, and nobody fights in a giant's or a dwarf's body.
--
-- The avatar is built once per player, in the background
-- (AvatarBody.prepare), and cloned for each duel (AvatarBody.rig). Until it
-- is ready, or if Roblox does not give it, the fighter keeps the prodigy's
-- own body (World.rig). Off by default: Matches uses it only for a session
-- with avatarBody set (DevHooks « avatar », for the Studio trial).
local Players=game:GetService("Players")
local Appearance=require(game:GetService("ReplicatedStorage").NinjaDuel.Appearance)
local AvatarBody={cache=setmetatable({},{__mode="k"})}
AvatarBody.SCALES={HeightScale=1,WidthScale=1,DepthScale=1,HeadScale=1,BodyTypeScale=0,ProportionScale=0}

local World -- (required late: World requires nothing of this module)
local function world()
	World=World or require(script.Parent.World)
	return World
end

-- The avatar's description at the standard scales (yields).
function AvatarBody.description(userId)
	local ok,desc=pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
	if not ok or not desc then return nil,tostring(desc) end
	for key,value in AvatarBody.SCALES do pcall(function() (desc::any)[key]=value end) end
	return desc
end

-- Builds the player's avatar once, in the background.
function AvatarBody.prepare(player)
	local entry=AvatarBody.cache[player]
	if entry and entry.state~="failed" then return entry.state end
	entry={state="loading"}
	AvatarBody.cache[player]=entry
	task.spawn(function()
		local desc,why=AvatarBody.description(player.UserId)
		local ok,model=false,why
		if desc then
			ok,model=pcall(function() return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15) end)
		end
		if ok and model then
			entry.template=model;entry.state="ready"
		else
			entry.state="failed";entry.reason=tostring(model)
			warn("[AvatarBody] "..player.Name..": "..entry.reason)
		end
	end)
	return entry.state
end
function AvatarBody.ready(player)
	local entry=AvatarBody.cache[player]
	return entry~=nil and entry.state=="ready"
end
function AvatarBody.state(player)
	local entry=AvatarBody.cache[player]
	return if entry then entry.state else "none",entry and entry.reason
end
function AvatarBody.forget(player)
	local entry=AvatarBody.cache[player]
	if entry and entry.template then entry.template:Destroy() end
	AvatarBody.cache[player]=nil
end

-- Puts an R15 model on the game's skeleton (World.RIG). Each joint keeps the
-- avatar's own C1 (the part's offset from its pivot) and gets the C0 that
-- puts the pivot where the rig's is; the motors move under their Part0, where
-- the motion engine looks for them (Client/VelmoraMotionEngine). Returns the
-- joints by name and the parts' rest frames (root space), or nil and the
-- missing joint. Pure geometry: no Roblox service.
function AvatarBody.fit(model,rig)
	rig=rig or world().RIG
	local motors={}
	for _,d in model:GetDescendants() do
		if d:IsA("Motor6D") then motors[d.Name]=d end
	end
	local rest={HumanoidRootPart=CFrame.new()}
	local pivotOf={HumanoidRootPart=Vector3.zero}
	local joints={}
	for _,j in rig.joints do
		local name,p0,p1,c0=j[1],j[2],j[3],j[4]
		local m=motors[name]
		if not m or not m.Part0 or not m.Part1 then return nil,name end
		local parentRest=rest[p0]
		if not parentRest then return nil,name end
		-- The rig's pivot for this joint, in root space.
		local rigParent=if p0=="HumanoidRootPart" then Vector3.zero else rig.parts[p0][2]
		local pivot=rigParent+c0
		local pivotCF=CFrame.new(pivot)*m.C1.Rotation
		local childRest=pivotCF*m.C1:Inverse()
		m.C0=parentRest:Inverse()*pivotCF
		rest[p1]=childRest
		if m.Parent~=m.Part0 then m.Parent=m.Part0 end
		joints[name]=m
	end
	return joints,rest
end

-- The kit's own pieces (Appearance.KitItems) from its prodigy's Blender look,
-- welded on the avatar's body parts. Their offsets are the rig's: close
-- enough on the shared skeleton. Marked KitItem. Returns how many.
function AvatarBody.wearKit(model,kitId,def)
	local LookMeshes=require(script.Parent.LookMeshes)
	local look=LookMeshes.Data[def.Name]
	local made=LookMeshes.templates[def.Name]
	if not look or not made or not Appearance.KitItems[kitId] then return 0 end
	local n=0
	for _,piece in look.pieces do
		local body=model:FindFirstChild(piece.body)
		local template=made[piece.name]
		if body and template and Appearance.isKitItem(kitId,piece.name) then
			local p=template:Clone()
			p.Name=piece.name;p.Size=piece.size;p.Color=piece.color
			p.Material=Enum.Material[piece.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic
			p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true
			p.CFrame=body.CFrame*CFrame.new(piece.offset)
			local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
			p:SetAttribute("KitItem",kitId)
			p.Parent=model
			n+=1
		end
	end
	return n
end

-- A fighter in the player's avatar: what World.rig returns (model, humanoid,
-- root, joints), or nil when the avatar is not ready (the caller then builds
-- the prodigy's body).
-- `looks` (optional, 13/11): the player's looks (Progression.looks): his
-- headband goes on the avatar (Server/Headband).
function AvatarBody.rig(player,parent,kitId,def,cf,name,looks)
	local entry=AvatarBody.cache[player]
	if not entry or entry.state~="ready" then return nil end
	local W=world()
	W.fighterGroup()
	local model=entry.template:Clone()
	model.Name=name
	for _,d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Sound") then d:Destroy() end
	end
	local joints,rest=AvatarBody.fit(model,W.RIG)
	if not joints then model:Destroy();warn("[AvatarBody] no joint "..tostring(rest));return nil end
	local hum=model:FindFirstChildOfClass("Humanoid")
	local root=model:FindFirstChild("HumanoidRootPart")
	if not hum or not root then model:Destroy();return nil end
	pcall(function() hum.AutomaticScalingEnabled=false end)
	hum.RigType=Enum.HumanoidRigType.R15;hum.RequiresNeck=true;hum.BreakJointsOnDeath=false
	hum.MaxHealth=def.Health;hum.Health=def.Health;hum.WalkSpeed=def.Speed
	hum.UseJumpPower=true;hum.JumpPower=68;hum.HipHeight=2
	hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator",hum) end
	-- The body as the rig's: only the root collides, the torso and head are hit.
	local hit={HumanoidRootPart=true,LowerTorso=true,UpperTorso=true,Head=true}
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local own=p.Parent==model
			p.Anchored=false
			p.CanCollide=p==root
			p.CanQuery=own and hit[p.Name]==true
			p.Massless=p~=root
			if rest[p.Name] and own then p.CFrame=cf*rest[p.Name] end
		end
	end
	root.CFrame=cf;root.Transparency=1
	AvatarBody.wearKit(model,kitId,def)
	pcall(function() require(script.Parent.Headband).fromLooks(model,looks) end)
	model:SetAttribute("Avatar",player.UserId)
	model.PrimaryPart=root
	model.Parent=parent
	pcall(function() root:SetNetworkOwner(nil) end)
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CollisionGroup="NinjaFighters" end end
	return model,hum,root,joints
end

return AvatarBody
