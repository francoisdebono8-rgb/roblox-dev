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

-- (20/11, the OUTILLEUR's fitting room) An armour body (Korblox) has an
-- UpperTorso of 3.25 x 6.30 x 3.02 studs: every piece sized on it became a
-- box. A torso past these sizes (standard R15 2 x 1.6 x 1; Rthro about
-- 2.3 x 2.1 x 1.2) is swapped for the standard torso; his legs, arms, head,
-- face and hair stay his.
AvatarBody.TORSO_MAX=Vector3.new(3,3,2)
function AvatarBody.oversized(model)
	local t=model and model:FindFirstChild("UpperTorso")
	if not t or not t:IsA("BasePart") then return false end
	local m=AvatarBody.TORSO_MAX
	return t.Size.X>m.X or t.Size.Y>m.Y or t.Size.Z>m.Z
end
-- `desc` with the standard torso when his own is oversized (builds a test
-- body once; yields). Returns whether it was swapped.
function AvatarBody.plainTorso(desc,build)
	build=build or function(d) return Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15) end
	local ok,model=pcall(build,desc)
	if not ok or not model then return false end
	local big=AvatarBody.oversized(model)
	pcall(function() model:Destroy() end)
	if big then pcall(function() desc.Torso=0 end) end
	return big
end

-- The avatar's description at the standard scales (yields).
function AvatarBody.description(userId)
	local ok,desc=pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
	if not ok or not desc then return nil,tostring(desc) end
	for key,value in AvatarBody.SCALES do pcall(function() (desc::any)[key]=value end) end
	AvatarBody.plainTorso(desc)
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
		-- (DEC-040) body, face and hair: the clothes come off, the ninja
		-- outfit he chose goes on in each duel (Server/Outfit)
		if desc then pcall(function() require(script.Parent.Outfit).strip(desc) end) end
		if desc then
			ok,model=pcall(function() return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15) end)
		end
		-- (14/11) Roblox's joints as AnimationConstraints: the Motor6Ds they are
		if ok and model then pcall(AvatarBody.motorize,model) end
		-- (19/11) the prodigies' height, as in the village (Hub.enter)
		if ok and model then entry.growth=AvatarBody.grow(model) end
		if ok and model then
			entry.template=model;entry.state="ready"
		else
			entry.state="failed";entry.reason=tostring(model)
			warn("[AvatarBody] "..player.Name..": "..entry.reason)
		end
	end)
	return entry.state
end
-- (19/11, measured in Studio on the owner's avatar) The avatar stood 5.10
-- studs tall in Konoha and 5.96 in a duel, while the prodigies stand 6.51: the
-- inspirations, his own age, were a head taller than him, his size changed
-- between the village and the duel, and in the duel his limbs were pulled
-- apart on the rig's pivots (0.2 stud of air at the elbow, arms off the
-- torso). Every avatar is now scaled whole, its own proportions kept, to the
-- prodigies' height (soles to the top of the head, at rest), in the village
-- and in the duel, before anything is worn on it. The skeleton the duel plays
-- on does not change (World.RIG): only how big the body drawn on it is.
AvatarBody.HEIGHT=6.5
AvatarBody.GROW={.8,1.6}
-- The model's rest pose, from its joints alone (Motor6Ds, or the
-- AnimationConstraints Roblox builds now): soles to the top of the head.
-- nil when the chain from the root to the head and a foot is incomplete.
function AvatarBody.restHeight(model)
	local links={}
	for _,d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			links[d.Part1]={d.Part0,d.C0,d.C1}
		elseif d:IsA("AnimationConstraint") then
			local a0,a1=d.Attachment0,d.Attachment1
			if a0 and a1 and a0.Parent and a1.Parent then links[a1.Parent]={a0.Parent,a0.CFrame,a1.CFrame} end
		end
	end
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local rest={}
	local function frame(part,depth)
		if part==root then return CFrame.new() end
		if rest[part] then return rest[part] end
		local link=links[part]
		if not link or depth>24 then return nil end
		local above=frame(link[1],depth+1)
		if not above then return nil end
		rest[part]=above*link[2]*link[3]:Inverse()
		return rest[part]
	end
	local head=model:FindFirstChild("Head")
	local top=head and frame(head,0)
	if not top then return nil end
	local low
	for _,name in {"LeftFoot","RightFoot"} do
		local foot=model:FindFirstChild(name)
		local at=foot and frame(foot,0)
		if at then
			local bottom=at.Position.Y-foot.Size.Y/2
			low=if low then math.min(low,bottom) else bottom
		end
	end
	if not low then return nil end
	return top.Position.Y+head.Size.Y/2-low
end
-- How much the avatar grows to stand AvatarBody.HEIGHT tall (1 when it cannot
-- be measured).
function AvatarBody.growth(model)
	local height=AvatarBody.restHeight(model)
	if not height or height<=0 then return 1 end
	return math.clamp(AvatarBody.HEIGHT/height,AvatarBody.GROW[1],AvatarBody.GROW[2])
end
-- Scales the avatar (Model:ScaleTo: parts, joints, attachments, accessories);
-- returns the factor applied.
function AvatarBody.grow(model)
	local k=AvatarBody.growth(model)
	if math.abs(k-1)<.01 then return 1 end
	local ok=pcall(function() model:ScaleTo(model:GetScale()*k) end)
	return if ok then k else 1
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

-- (14/11, Studio: « [AvatarBody] no joint Root ») Roblox now builds an
-- avatar's joints as AnimationConstraints (the avatar joint upgrade), not
-- Motor6Ds: fit refused every avatar and the player fought in his prodigy's
-- body. Each constraint becomes the Motor6D it stands for: Part0 and Part1
-- are its attachments' parts, C0 and C1 their frames; the motor goes under
-- Part1 as Roblox puts its own, and the constraint goes. `make` builds the
-- motor (Instance.new; the suites pass their own). Returns how many.
function AvatarBody.motorize(model,make)
	make=make or function(class) return Instance.new(class) end
	local count=0
	for _,c in model:GetDescendants() do
		if c:IsA("AnimationConstraint") then
			local a0,a1=c.Attachment0,c.Attachment1
			local p0,p1=a0 and a0.Parent,a1 and a1.Parent
			if p0 and p1 and p0:IsA("BasePart") and p1:IsA("BasePart") then
				local m=make("Motor6D")
				m.Name=c.Name;m.Part0=p0;m.Part1=p1;m.C0=a0.CFrame;m.C1=a1.CFrame
				m.Parent=p1
				c:Destroy()
				count+=1
			end
		end
	end
	return count
end

-- Puts an R15 model on the game's skeleton (World.RIG). Each part takes the
-- rig's size and offset from its pivot (19/11; the head keeps its size), and
-- each joint gets the C0 that puts the pivot where the rig's is; the motors move under their Part0, where
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
	local chain={HumanoidRootPart=Vector3.zero}
	local joints={}
	for _,j in rig.joints do
		local name,p0,p1,c0=j[1],j[2],j[3],j[4]
		local m=motors[name]
		if not m or not m.Part0 or not m.Part1 then return nil,name end
		local parentRest=rest[p0]
		if not parentRest then return nil,name end
		-- The rig's pivot for this joint, in root space: where its motors put it
		-- (19/11: the table's part centres, which World.rig only starts the
		-- parts at, are not that for the arms and the legs; taken as the
		-- parent's place, they put the avatar's elbows 0.38 and its ankles 0.35
		-- higher than every prodigy's, hence the air at the elbow and the feet
		-- above the floor).
		local from=chain[p0]
		if not from then return nil,name end
		local pivot=from+c0
		chain[p1]=pivot-(j[5] or Vector3.zero)
		-- (19/11, seen in Studio) The avatar's own parts on the rig's pivots
		-- overlapped or left air (its torso taller than the rig's: the head sank
		-- into it and a coat's collar rose over the face; 0.2 stud of air at the
		-- elbow; feet 0.16 to 0.25 above the floor). The body is now the rig's:
		-- each part takes the rig's size and sits where the rig's does on its
		-- pivot, with the avatar's own meshes, colours, face and hair. The head
		-- keeps its own size (the hair is fitted to it: AvatarBody.grow brought
		-- it to the prodigies' height) and sits on the torso as the rig's does.
		local size,c1=rig.parts[p1] and rig.parts[p1][1],j[5]
		if p1=="Head" and size and c1 then
			local below=size.Y/2+c1.Y -- the rig's head bottom under its neck pivot
			m.C1=CFrame.new(c1.X,-(m.Part1.Size.Y/2-below),c1.Z)*m.C1.Rotation
		elseif size and c1 then
			m.Part1.Size=size
			m.C1=CFrame.new(c1)*m.C1.Rotation
		end
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
	-- (19/11) the avatar grew to the prodigies' height (AvatarBody.grow), its
	-- root with it; the duel's root stays the rig's, which HipHeight 2 and the
	-- feet on the floor are measured on.
	root.Size=Vector3.new(2,2,1)
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
	pcall(function() require(script.Parent.Outfit).wear(model,looks) end)
	model:SetAttribute("Avatar",player.UserId)
	model.PrimaryPart=root
	model.Parent=parent
	pcall(function() root:SetNetworkOwner(nil) end)
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CollisionGroup="NinjaFighters" end end
	return model,hum,root,joints
end

return AvatarBody
