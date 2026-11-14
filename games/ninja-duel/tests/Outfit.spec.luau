-- His ninja (DEC-040, user 14/11: « il arrive genre nu et on ait un petit truc
-- de customisation de personnage »): his avatar loses its clothes and keeps
-- body, face and hair (Server/Outfit.strip); the pieces he chose are welded on
-- his body parts, never colliding nor hit (Outfit.wear); the card cycles what
-- he may wear (Client/OutfitPanel). Headless (Lune's Roblox instances); the
-- look on a real avatar is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
H.envBase.Instance=roblox.Instance
local Instance=roblox.Instance
local Vector3=roblox.Vector3
local CFrame=roblox.CFrame
local Shop=H.load("Shared/Shop")
local Outfit=H.load("Server/Outfit")
local OutfitPanel=H.load("Client/OutfitPanel")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end

test("strip: the clothes, the shoes and every accessory come off; body, face and hair stay",function()
	local Hair,Shirt,Shoe={"Hair"},{"Shirt"},{"LeftShoe"}
	local layered={{AccessoryType=Hair,AssetId=1},{AccessoryType=Shirt,AssetId=2},{AccessoryType=Shoe,AssetId=3}}
	local savedEnum=H.envBase.Enum
	H.envBase.Enum=setmetatable({AccessoryType={Hair=Hair}},{__index=savedEnum})
	Outfit=H.load("Server/Outfit")
	local desc={Shirt=11,Pants=12,GraphicTShirt=13,HairAccessory="21,22",HatAccessory="31",FaceAccessory="32",BackAccessory="33",Face=40,Head=41,HeadColor="skin"}
	function desc:GetAccessories(rigid) assert(rigid==false);return layered end
	function desc:SetAccessories(list,rigid) assert(rigid==false);desc.kept=list end
	Outfit.strip(desc)
	H.envBase.Enum=savedEnum
	assert(desc.Shirt==0 and desc.Pants==0 and desc.GraphicTShirt==0,"his clothes stay on")
	assert(desc.HatAccessory=="" and desc.FaceAccessory=="" and desc.BackAccessory=="","an accessory stays on")
	assert(desc.HairAccessory=="21,22" and desc.Face==40 and desc.Head==41,"his hair, face or head went")
	assert(desc.kept and #desc.kept==1 and desc.kept[1].AssetId==1,"layered: only the hair stays")
end)

-- An R15 body of parts, the sizes of a standard avatar's.
local function body()
	local model=Instance.new("Model")
	local sizes={Head=Vector3.new(1.2,1.2,1.2),UpperTorso=Vector3.new(2,1.6,1),LowerTorso=Vector3.new(2,.4,1),
		LeftUpperArm=Vector3.new(1,1.2,1),RightUpperArm=Vector3.new(1,1.2,1),LeftLowerArm=Vector3.new(1,1.1,1),RightLowerArm=Vector3.new(1,1.1,1),
		LeftHand=Vector3.new(1,.3,1),RightHand=Vector3.new(1,.3,1),LeftUpperLeg=Vector3.new(1,1.2,1),RightUpperLeg=Vector3.new(1,1.2,1),
		LeftLowerLeg=Vector3.new(1,1.2,1),RightLowerLeg=Vector3.new(1,1.2,1),LeftFoot=Vector3.new(1,.3,1),RightFoot=Vector3.new(1,.3,1)}
	for name,size in sizes do
		local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(0,3,0);p.Parent=model
	end
	return model
end
local function pieces(model)
	local holder=model:FindFirstChild("NinjaOutfit")
	local out={}
	if holder then for _,p in holder:GetChildren() do table.insert(out,p) end end
	return out,holder
end

test("wear: the chosen pieces welded on his parts, never colliding nor hit; a master's outfit covers the rest",function()
	local model=body()
	assert(Outfit.wear(model,{})==nil and model:FindFirstChild("NinjaOutfit")==nil,"he wears something he did not choose")
	Outfit.wear(model,{top="TopTunicNavy",bottom="BottomPantsDark",arms="ArmsWraps",feet="FeetSandals"})
	local list,holder=pieces(model)
	assert(holder and #list>=12,"too few pieces: "..#list)
	for _,p in list do
		assert(p:IsA("BasePart") and not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Massless,p.Name.." collides or is hit")
		local weld=p:FindFirstChildOfClass("WeldConstraint")
		assert(weld and weld.Part1==p and weld.Part0 and weld.Part0.Parent==model,p.Name.." is not welded to his body")
	end
	-- the tunic covers the torso outside the body part
	local torso=model.UpperTorso
	local found=false
	for _,p in list do
		if p:FindFirstChildOfClass("WeldConstraint").Part0==torso and p.Size.X>torso.Size.X and p.Size.Z>torso.Size.Z then found=true end
	end
	assert(found,"no cloth round the torso")
	-- both arms and both legs
	local on={}
	for _,p in list do on[p:FindFirstChildOfClass("WeldConstraint").Part0.Name]=true end
	for _,name in {"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftUpperLeg","RightUpperLeg","LeftFoot","RightFoot"} do assert(on[name],name.." left bare") end
	-- a master's outfit: the only one worn, the old outfit gone
	Outfit.wear(model,{top="TopTunicNavy",set="SetLee"})
	local again,h2=pieces(model)
	assert(h2 and h2~=holder and holder.Parent==nil,"the old outfit stayed")
	assert(h2:GetAttribute("NinjaOutfit")=="SetLee","the master's outfit does not cover the rest: "..tostring(h2:GetAttribute("NinjaOutfit")))
	assert(#again>=10,"Lee's suit is thin")
	-- every master's outfit and every free piece builds
	for _,item in Shop.Items do
		if Shop.Slots[item.slot].outfit and not item.none then
			local m=body()
			Outfit.wear(m,{[item.slot]=item.id})
			assert(#pieces(m)>0,item.id.." builds nothing")
		end
	end
	-- taken off
	Outfit.wear(model,{})
	assert(model:FindFirstChild("NinjaOutfit")==nil,"the outfit did not come off")
end)

test("the card: what he may wear (free, owned), cycled both ways; dressed once he has a top or a master's outfit",function()
	local style={owned={SetLee=true},equipped={}}
	assert(not Shop.dressed(style) and not Shop.dressed(nil),"dressed before choosing")
	local tops=OutfitPanel.options(style,"top")
	assert(#tops>=3,"too few free tops")
	assert(OutfitPanel.cycle(style,"top",1).id==tops[1].id and OutfitPanel.cycle(style,"top",-1).id==tops[#tops].id,"the first press")
	style.equipped.top=tops[1].id
	assert(OutfitPanel.cycle(style,"top",1).id==tops[2].id and OutfitPanel.cycle(style,"top",-1).id==tops[#tops].id,"cycling")
	assert(Shop.dressed(style),"a top dresses him")
	local sets=OutfitPanel.options(style,"set")
	local ids={}
	for _,item in sets do ids[item.id]=true end
	assert(ids.SetNone and ids.SetLee and not ids.SetNaruto,"the sets offered are not his")
	assert(Shop.dressed({owned={SetLee=true},equipped={set="SetLee"}}),"a master's outfit dresses him")
	assert(not Shop.dressed({owned={},equipped={set="SetNone"}}),"MY OWN PIECES without a top dresses him")
end)

print(string.format("NinjaDuel outfit (DEC-040): %d PASS",passed))
