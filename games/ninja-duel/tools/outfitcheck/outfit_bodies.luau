-- The bodies of the outfit check (OUTILLEUR, passe commune 2, 26/11; DEC-054:
-- « un contrôle des tenues sur plusieurs avatars Roblox : il dit quelle pièce
-- traverse ou flotte, sur quel corps »).
--
-- A server module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py --server outfitbodies   (eval_server_runtime)
-- It builds typical Roblox avatars the way the game builds the player's
-- (Server/AvatarBody: his description at the standard scales, the armour torso
-- and arms swapped, clothes off but the hair, grown to the prodigies' height),
-- then puts each one in a duel's body with AvatarBody.rig itself (the game's
-- skeleton, the kit's pieces, the headband, Server/Outfit's cloth): the very
-- path of a duel. The client of the Play dresses them with the modelled pieces
-- (Client/OutfitDress) as it dresses a fighter; tools/outfitcheck/outfit_check
-- measures them there. They stand in a row far from the map (Bodies.ORIGIN),
-- their roots anchored; nothing is saved (a Play).
--
--   _G.NDOutfitBodies.build()          the avatars (yields in a thread: read .state())
--   _G.NDOutfitBodies.dress(looks)     the row dressed in `looks` ({set=…} or slots)
--   _G.NDOutfitBodies.state()
local Players=game:GetService("Players")
local AssetService=game:GetService("AssetService")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local Server=game:GetService("ServerScriptService"):WaitForChild("NinjaDuelServer")
local AvatarBody=require(Server.AvatarBody)
local Outfit=require(Server.Outfit)
local Fighters=require(RS.NinjaDuel.Fighters)

local Bodies={}
Bodies.ORIGIN=Vector3.new(0,1200,9000)
Bodies.SPACING=6
-- (the bodies of tools/tenues/cabine.luau, 20/11, and why each one)
Bodies.AVATARS={
	{key="francois",label="FRANÇOIS",user=10699076432,why="l'avatar du propriétaire"},
	{key="bloc",label="BLOC R15",why="le corps par défaut",skin={204,142,105}},
	{key="femme",label="FEMME",bundle=239,hair="62234425",why="un corps mince"},
	{key="garcon",label="GARÇON ROBLOX",bundle=109,why="un corps petit, au torse étroit"},
	{key="vanessa",label="RTHRO VANESSA",bundle=551,hat="1772336109",why="un corps grand et mince (Rthro)"},
	{key="bigbill",label="RTHRO BIG BILL",bundle=363,hat="15656347831",why="un corps large et massif (Rthro)"},
	{key="korblox",label="KORBLOX",bundle=192,why="un corps à armure (torse et bras remplacés)"},
}
Bodies.KIT="Leaf" -- a kit with no piece of its own (Appearance.KitItems): only the outfit is worn
local templates={}
local status="vide"
local made={}

-- (26/11) A bundle lists several outfits: the body's, then its face's and its
-- head's. The cabine took the last one (tools/tenues): a description with a
-- head and no body (the Woman, Vanessa and Big Bill bundles came out in the
-- default block body, Torso 0). The body's outfit is the first that is not a
-- face or a head; the bundle's own body parts then go on by their names.
local PARTS={{"Left Arm","LeftArm"},{"Right Arm","RightArm"},{"Left Leg","LeftLeg"},{"Right Leg","RightLeg"},{"Torso","Torso"}}
local function description(spec)
	local desc
	if spec.user then
		desc=Players:GetHumanoidDescriptionFromUserId(spec.user)
	elseif spec.bundle then
		local d=AssetService:GetBundleDetailsAsync(spec.bundle)
		for _,it in d.Items do
			if it.Type=="UserOutfit" and not desc and not string.find(it.Name,"Face",1,true) and not string.find(it.Name,"Head",1,true) then
				desc=Players:GetHumanoidDescriptionFromOutfitId(it.Id)
			end
		end
		desc=desc or Instance.new("HumanoidDescription")
		for _,it in d.Items do
			if it.Type=="Asset" then
				for _,pair in PARTS do
					if string.sub(it.Name,-#pair[1])==pair[1] then (desc::any)[pair[2]]=it.Id end
				end
			end
		end
	end
	return desc or Instance.new("HumanoidDescription")
end

function Bodies.build()
	status="construction"
	task.spawn(function()
		for _,spec in Bodies.AVATARS do
			local ok,err=pcall(function()
				local desc=description(spec)
				for key,value in AvatarBody.SCALES do pcall(function() (desc::any)[key]=value end) end
				local function add(key,id)
					local now=desc[key]
					desc[key]=if type(now)=="string" and now~="" then now..","..id else id
				end
				if spec.hair then add("HairAccessory",spec.hair) end
				if spec.hat then add("HatAccessory",spec.hat) end
				local swapped=false
				pcall(function() swapped=AvatarBody.plainTorso(desc)==true end)
				Outfit.strip(desc)
				if spec.skin then
					local c=Color3.fromRGB(spec.skin[1],spec.skin[2],spec.skin[3])
					for _,key in {"HeadColor","TorsoColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor"} do (desc::any)[key]=c end
				end
				local model=Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
				pcall(AvatarBody.motorize,model)
				local growth=AvatarBody.grow(model)
				local parts={}
				for _,name in {"UpperTorso","RightUpperArm","RightLowerArm","RightHand","RightUpperLeg","Head"} do
					local p=model:FindFirstChild(name)
					if p and p:IsA("BasePart") then parts[name]={math.floor(p.Size.X*100)/100,math.floor(p.Size.Y*100)/100,math.floor(p.Size.Z*100)/100} end
				end
				templates[spec.key]={state="ready",template=model,growth=growth,swapped=swapped,parts=parts,
					torso=desc.Torso,rightArm=desc.RightArm,head=desc.Head}
			end)
			if not ok then templates[spec.key]={state="failed",reason=tostring(err)} end
		end
		status="prêt"
	end)
	return "construction lancée"
end

local function folder()
	local f=workspace:FindFirstChild("NDOutfitBodies")
	if not f then f=Instance.new("Folder");f.Name="NDOutfitBodies";f.Parent=workspace end
	return f
end
function Bodies.centre()
	return Bodies.ORIGIN+Vector3.new((#Bodies.AVATARS-1)*Bodies.SPACING/2,0,0)
end

-- The row, each body in its duel body wearing `looks` (the client dresses them).
function Bodies.dress(looks,kit)
	kit=kit or Bodies.KIT
	local f=folder()
	f:ClearAllChildren()
	made={}
	local floor=Instance.new("Part");floor.Name="Floor";floor.Anchored=true
	floor.Size=Vector3.new(#Bodies.AVATARS*Bodies.SPACING+24,1,40)
	floor.CFrame=CFrame.new(Bodies.centre()-Vector3.new(0,.5,0))
	floor.Color=Color3.fromRGB(196,190,178);floor.Material=Enum.Material.SmoothPlastic
	floor.Parent=f
	for i,spec in Bodies.AVATARS do
		local entry=templates[spec.key]
		if entry and entry.state=="ready" then
			local fake={UserId=0,Name=spec.key}
			AvatarBody.cache[fake]=entry
			-- a body faces -Z: toward the front camera; the root 3 studs over the floor (HipHeight 2)
			local at=Bodies.ORIGIN+Vector3.new((i-1)*Bodies.SPACING,3,0)
			local ok,model=pcall(AvatarBody.rig,fake,f,kit,Fighters[kit],CFrame.new(at),"NDBody_"..spec.key,looks)
			AvatarBody.cache[fake]=nil
			if ok and model then
				model:SetAttribute("NDBodyKey",spec.key)
				model:SetAttribute("NDBodyLabel",spec.label)
				local root=model:FindFirstChild("HumanoidRootPart")
				if root then root.Anchored=true end
				local hum=model:FindFirstChildOfClass("Humanoid")
				if hum then hum.PlatformStand=true end
				made[spec.key]=true
			else
				made[spec.key]=tostring(model)
			end
		end
	end
	return HttpService:JSONEncode(made)
end
function Bodies.state()
	local out={status=status,bodies={}}
	for _,spec in Bodies.AVATARS do
		local e=templates[spec.key]
		out.bodies[spec.key]=if e then {state=e.state,reason=e.reason,swapped=e.swapped,growth=e.growth,parts=e.parts,torso=e.torso,rightArm=e.rightArm} else nil
	end
	out.made=made
	return HttpService:JSONEncode(out)
end
function Bodies.clear()
	local f=workspace:FindFirstChild("NDOutfitBodies")
	if f then f:Destroy() end
	return "ok"
end
return Bodies
