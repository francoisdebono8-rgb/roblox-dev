-- The fitting room (OUTILLEUR, 20/11; DEC-043, étape 1, OUTILLEUR 3): the
-- game's outfits on typical Roblox avatars, to be seen from the front and the
-- back. Run in Studio, EDIT mode, in a LAB copy of a place of the game (never
-- in another discussion's place): nothing is saved, the room lives far from
-- the map (Cabine.ORIGIN).
--
-- Each avatar is built the way the game builds the player's (Server/AvatarBody:
-- standard scales, clothes and accessories off but the hair, grown whole to
-- the prodigies' height), then dressed the way a duel dresses him: the cloth
-- pieces of Server/Outfit, the ANIMATEUR's modelled pieces of
-- Client/OutfitDress over them (the cloth of a modelled look hidden, as on
-- the client), the headband of Server/Headband.
--
--   python3 tools/tenues/studio_code.py setup        builds the avatars (yields: their assets load)
--   python3 tools/tenues/studio_code.py dress <look>  dresses all of them in a look of Cabine.LOOKS
--   python3 tools/tenues/studio_code.py camera front  where to capture from (then back)
--   then python3 tools/tenues/planche.py <captures> <out>  (README.md)
local Players=game:GetService("Players")
local AssetService=game:GetService("AssetService")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local Server=SSS:WaitForChild("NinjaDuelServer")
local ClientFolder=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("NinjaDuelClient")

local Cabine={}
Cabine.ORIGIN=Vector3.new(0,1200,9000)
Cabine.SPACING=5.5
-- Typical avatars (bundles of Roblox's catalogue, read 20/11; the owner's own).
Cabine.AVATARS={
	{key="francois",label="FRANÇOIS",user=10699076432},
	{key="bloc",label="BLOC R15",skin={204,142,105}},
	-- (21/11) these three bundles carry no hair at all (their outfits list no
	-- accessory before the strip): a player wearing them has his own. Each gets
	-- a free hair of the catalogue, two of them filed as hats, to check that
	-- Outfit.hairInHats keeps them (DEC-044)
	{key="femme",label="FEMME",bundle=239,hair="62234425"},
	{key="garcon",label="GARÇON ROBLOX",bundle=109},
	{key="vanessa",label="RTHRO VANESSA",bundle=551,hat="1772336109"},
	{key="bigbill",label="RTHRO BIG BILL",bundle=363,hat="15656347831"},
	{key="korblox",label="KORBLOX",bundle=192},
}
-- The looks: the eight inspirations' outfits, three simple outfits of the
-- base catalogue, and one with the accessories (mask, cape, back).
local BASE_A={top="TopTunicNavy",bottom="BottomPantsDark",arms="ArmsWraps",feet="FeetSandals",headband="HeadbandBlue"}
Cabine.LOOKS={
	SetNaruto={set="SetNaruto",headband="HeadbandBlue"},SetSasuke={set="SetSasuke",headband="HeadbandBlue"},
	SetLee={set="SetLee",headband="HeadbandBlue"},SetNeji={set="SetNeji",headband="HeadbandBlue"},
	SetGaara={set="SetGaara"},SetKakashi={set="SetKakashi",headband="HeadbandBlue"},
	SetItachi={set="SetItachi",headband="HeadbandBlue"},SetMinato={set="SetMinato",headband="HeadbandBlue"},
	BaseA=BASE_A,
	BaseB={top="TopHighCollar",bottom="BottomPantsSand",arms="ArmsGuards",feet="FeetBlack",headband="HeadbandBlack"},
	BaseC={top="TopSleeveless",bottom="BottomShorts",feet="FeetSandals",headband="HeadbandRed"},
	Accessoires={top="TopTunicNavy",bottom="BottomPantsDark",arms="ArmsWraps",feet="FeetSandals",headband="HeadbandBlue",
		mask="MaskCloth",cape="CapeTravel",back="BackScroll"},
	-- (20/11, after the ANIMATEUR's wardrobe) the six invented outfits, sold
	-- SOON, and the new accessories (a neck headband: it needs its model)
	SetEmberMonk={set="SetEmberMonk",headband="HeadbandBlue"},SetMistHunter={set="SetMistHunter",headband="HeadbandBlue"},
	SetStormCourier={set="SetStormCourier",headband="HeadbandBlue"},SetShadowScout={set="SetShadowScout",headband="HeadbandBlue"},
	SetLeafMedic={set="SetLeafMedic",headband="HeadbandBlue"},SetSandNomad={set="SetSandNomad",headband="HeadbandBlue"},
	Accessoires2={top="TopTunicNavy",bottom="BottomPantsDark",arms="ArmsWraps",feet="FeetSandals",headband="HeadbandNeck",
		mask="MaskFox",cape="CloakHooded",back="BackSword"},
}
-- (21/11, step 3, OUTILLEUR 4) The hairstyles and their colours, as soon as
-- the shop sells them (DEV 2: the slots, ANIMATEUR: the content): one look
-- per item of a hair slot, on the simple outfit (BaseA), so the sheet shows
-- each one on the seven avatars. Empty until the slots exist.
Cabine.HAIR_SLOTS={"hair","hairstyle","hairColor","haircolor"}
function Cabine.hairLooks()
	local looks,order={}, {}
	local ok,Shop=pcall(function() return require(RS:WaitForChild("NinjaDuel"):WaitForChild("Shop")) end)
	if not ok or type(Shop)~="table" or not Shop.Slots then return looks,order end
	for _,slot in Cabine.HAIR_SLOTS do
		if Shop.Slots[slot] then
			for _,item in Shop.inSlot(slot) do
				local look=table.clone(BASE_A);look[slot]=item.id
				local name="Hair_"..tostring(item.id)
				looks[name]=look;table.insert(order,name)
			end
		end
	end
	return looks,order
end
Cabine.ORDER={"SetNaruto","SetSasuke","SetLee","SetNeji","SetGaara","SetKakashi","SetItachi","SetMinato","BaseA","BaseB","BaseC","Accessoires",
	"SetEmberMonk","SetMistHunter","SetStormCourier","SetShadowScout","SetLeafMedic","SetSandNomad","Accessoires2"}

local function folder()
	local f=workspace:FindFirstChild("NDCabine")
	if not f then f=Instance.new("Folder");f.Name="NDCabine";f.Parent=workspace end
	return f
end

-- The camera for the row: from the front (the avatars face it) and from the back.
local function centre()
	return Cabine.ORIGIN+Vector3.new((#Cabine.AVATARS-1)*Cabine.SPACING/2,3.3,0)
end
function Cabine.camera(view)
	local c=centre()
	local dist=(#Cabine.AVATARS*Cabine.SPACING)*.45
	local at=if view=="back" then c+Vector3.new(0,.6,dist) else c+Vector3.new(0,.6,-dist)
	return {position={at.X,at.Y,at.Z},lookAt={c.X,c.Y,c.Z}}
end

-- The description of an avatar type (yields).
function Cabine.description(spec)
	local desc
	if spec.user then
		desc=Players:GetHumanoidDescriptionFromUserId(spec.user)
	elseif spec.bundle then
		-- (26/11, passe 2) the body's outfit is the first that is not a face or a
		-- head (the last one was the head's: Woman, Vanessa and Big Bill came out
		-- in the block body), then the bundle's own body parts by their names
		-- (tools/outfitcheck/outfit_bodies.luau)
		local d=AssetService:GetBundleDetailsAsync(spec.bundle)
		for _,it in d.Items do
			if it.Type=="UserOutfit" and not desc and not string.find(it.Name,"Face",1,true) and not string.find(it.Name,"Head",1,true) then
				desc=Players:GetHumanoidDescriptionFromOutfitId(it.Id)
			end
		end
		desc=desc or Instance.new("HumanoidDescription")
		for _,it in d.Items do
			if it.Type=="Asset" then
				for _,pair in {{"Left Arm","LeftArm"},{"Right Arm","RightArm"},{"Left Leg","LeftLeg"},{"Right Leg","RightLeg"},{"Torso","Torso"}} do
					if string.sub(it.Name,-#pair[1])==pair[1] then (desc::any)[pair[2]]=it.Id end
				end
			end
		end
	end
	return desc or Instance.new("HumanoidDescription")
end

-- Edit mode solves no joint (Studio 20/11: a Rthro head sat 2 studs inside
-- its torso): every part is put where its joints hold it at rest, from the
-- root, as the game's skeleton does in play (C0, C1, no animation).
function Cabine.pose(model)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return 0 end
	local joints={}
	for _,d in model:GetDescendants() do
		if d:IsA("JointInstance") and d.Part0 and d.Part1 then table.insert(joints,d) end
	end
	local done={[root]=true}
	local moved,progress=0,true
	while progress do
		progress=false
		for _,j in joints do
			local a,b=j.Part0,j.Part1
			if done[a] and not done[b] then
				b.CFrame=a.CFrame*j.C0*j.C1:Inverse();done[b]=true;moved+=1;progress=true
			elseif done[b] and not done[a] then
				a.CFrame=b.CFrame*j.C1*j.C0:Inverse();done[a]=true;moved+=1;progress=true
			end
		end
	end
	return moved
end

-- Builds every avatar of Cabine.AVATARS in a row (yields). Returns their
-- heights and part sizes.
function Cabine.setup()
	local AvatarBody=require(Server.AvatarBody)
	local Outfit=require(Server.Outfit)
	local f=folder()
	f:ClearAllChildren()
	local floor=Instance.new("Part");floor.Name="Floor";floor.Anchored=true;floor.Size=Vector3.new(#Cabine.AVATARS*Cabine.SPACING+20,1,40)
	floor.CFrame=CFrame.new(centre()-Vector3.new(0,3.3+.5,0));floor.Color=Color3.fromRGB(196,190,178);floor.Material=Enum.Material.SmoothPlastic
	floor.Parent=f
	local out={}
	for i,spec in Cabine.AVATARS do
		local ok,err=pcall(function()
			local desc=Cabine.description(spec)
			for key,value in AvatarBody.SCALES do pcall(function() (desc::any)[key]=value end) end
			-- the hair a player of this body would wear (a hair, or a hair filed as a hat)
			local function add(key,id)
				local now=desc[key]
				desc[key]=if type(now)=="string" and now~="" then now..","..id else id
			end
			if spec.hair then add("HairAccessory",spec.hair) end
			if spec.hat then add("HatAccessory",spec.hat) end
			-- (21/11) as AvatarBody.description: an armour torso (Korblox)
			-- becomes the standard one (DEC-044)
			local swapped=false
			if AvatarBody.plainTorso then
				local done,big=pcall(AvatarBody.plainTorso,desc)
				swapped=done and big==true
			end
			-- what he wears before the strip, to read why a head comes out bald
			local worn={}
			pcall(function()
				for _,a in desc:GetAccessories(true) do
					table.insert(worn,{id=a.AssetId,type=a.AccessoryType.Name,layered=a.IsLayered})
				end
			end)
			local hats=desc.HatAccessory
			Outfit.strip(desc)
			local hairKept=desc.HairAccessory
			if spec.skin then
				local c=Color3.fromRGB(spec.skin[1],spec.skin[2],spec.skin[3])
				for _,key in {"HeadColor","TorsoColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor"} do (desc::any)[key]=c end
			end
			local model=Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
			model.Name=spec.key
			model:SetAttribute("Label",spec.label)
			pcall(AvatarBody.motorize,model)
			local k=AvatarBody.grow(model)
			Cabine.pose(model)
			for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true end end
			-- facing the front camera (a body faces -Z), soles on the floor
			local height=AvatarBody.restHeight(model) or 6.5
			local at=Cabine.ORIGIN+Vector3.new((i-1)*Cabine.SPACING,0,0)
			model:PivotTo(CFrame.new(at+Vector3.new(0,4,0)))
			local low=math.huge
			for _,name in {"LeftFoot","RightFoot"} do
				local foot=model:FindFirstChild(name)
				if foot then low=math.min(low,foot.Position.Y-foot.Size.Y/2) end
			end
			if low<math.huge then model:PivotTo(model:GetPivot()+Vector3.new(0,Cabine.ORIGIN.Y-low,0)) end
			model.Parent=f
			local sizes={}
			for _,name in {"Head","UpperTorso","LowerTorso","RightUpperArm","RightLowerArm","RightUpperLeg","RightLowerLeg","RightFoot"} do
				local p=model:FindFirstChild(name)
				if p then sizes[name]={math.floor(p.Size.X*100)/100,math.floor(p.Size.Y*100)/100,math.floor(p.Size.Z*100)/100} end
			end
			-- after the strip, what he still wears on the head is his hair (a
			-- hair filed as a hat keeps the hat's type: every accessory counts)
			local hairOn=0
			for _,a in model:GetChildren() do if a:IsA("Accessory") then hairOn+=1 end end
			out[spec.key]={grow=math.floor(k*1000)/1000,height=math.floor(height*100)/100,sizes=sizes,
				torsoSwapped=swapped,hairKept=hairKept,hatsBefore=hats,hairOnModel=hairOn,
				-- a bald head: what he wore before the strip, to see what it took
				worn=if hairOn==0 then worn else nil}
		end)
		if not ok then out[spec.key]={error=tostring(err)} end
	end
	return out
end

-- Dresses every avatar of the room in a look (Cabine.LOOKS[name], or a table
-- of slot -> item id). Returns, per avatar, the pieces put on.
function Cabine.dress(name)
	local looks=if type(name)=="table" then name else Cabine.LOOKS[name] or (Cabine.hairLooks())[name]
	assert(looks,"no look "..tostring(name))
	local Outfit=require(Server.Outfit)
	local Headband=require(Server.Headband)
	local Dress=require(ClientFolder.OutfitDress)
	local out={}
	for _,model in folder():GetChildren() do
		if model:IsA("Model") then
			for _,old in model:GetChildren() do
				if old:GetAttribute("NinjaOutfit") or old:GetAttribute("NinjaHeadband") or old.Name=="NinjaOutfitMesh" then old:Destroy() end
			end
			-- as the duel's rig (AvatarBody.rig): the headband first, by the
			-- rule of the looks (DEC-044: a set with its own protector wins, a
			-- modelled headband goes with the outfit), then the outfit
			if Headband.fromLooks then pcall(Headband.fromLooks,model,looks)
			elseif looks.headband then pcall(Headband.wear,model,looks.headband) end
			local holder=Outfit.wear(model,looks)
			local modelled=0
			if holder then
				modelled=Dress.wear(holder)
				-- the cloth of a modelled look, hidden as the client hides it
				for _,piece in holder:GetDescendants() do
					if piece:IsA("BasePart") and piece.LocalTransparencyModifier>=1 then piece.Transparency=1 end
				end
			end
			for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true end end
			out[model.Name]={cloth=holder and #holder:GetChildren() or 0,modelled=modelled}
		end
	end
	return out
end

return Cabine
