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
	-- every master's outfit and every free piece builds; (19/11, seen in
	-- Studio) none in Fabric, which reads near-black under the game's light
	for _,item in Shop.Items do
		if Shop.Slots[item.slot].outfit and not item.none then
			local m=body()
			Outfit.wear(m,{[item.slot]=item.id})
			local made=pieces(m)
			assert(#made>0,item.id.." builds nothing")
			for _,p in made do assert(not string.find(tostring(p.Material),"Fabric"),item.id.." "..p.Name.." is Fabric: its colour does not show") end
		end
	end
	local fs=require("@lune/fs")
	assert(string.find(fs.readFile("src/Client/OutfitDress.luau"),"p.Material=Dress.material(p.Material)",1,true),"the modelled pieces keep Fabric")
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

-- (DEC-040, the ANIMATEUR's models, PR #111) On each screen the modelled
-- pieces replace the cloth: placed by the contract of Shared/OutfitMeshes
-- (scaled by the part's size over the standard part's, welded at the scaled
-- offset), painted by the item's slot (or the model's new slot).
-- (DESIGN 19/11, OUTILLEUR's measure on an iPhone 13: arrows 31 px, DONE 32)
-- a phone in landscape gets the strip along the bottom: three columns, the
-- arrows and DONE at 44 px or more once scaled to 844 x 390.
test("the card on a phone: a strip along the bottom, every button 44 px or more",function()
	local P=OutfitPanel
	local scale=math.clamp(math.min((844-100)/P.CW,(390*.62)/P.CH),.45,1.1)
	assert(scale*64>=44,"arrows "..scale*64)
	assert(390<P.COMPACT_BELOW,"an iPhone 13 in landscape is compact")
	local fake={rows={},card={},title={},rule={},sub={},foot={},done={}}
	for _,slot in P.ROWS do fake.rows[slot]={frame={},prev={},next={},label={},name={}} end
	setmetatable(fake,P)
	local savedU=H.envBase.UDim2;H.envBase.UDim2=roblox.UDim2
	P.layout(fake,true)
	assert(fake.rows.top.prev.Size.X.Offset*scale>=44 and fake.done.Size.Y.Offset*scale>=44,"the strip's buttons")
	assert(fake.card.AnchorPoint.Y==1 and not fake.sub.Visible,"along the bottom, his face above")
	P.layout(fake,false)
	assert(fake.card.AnchorPoint.Y==.5 and fake.sub.Visible,"back to the column on a PC")
	H.envBase.UDim2=savedU
end)

test("the modelled pieces: placed by the body part's size, painted by the item's slot",function()
	local Dress=H.load("Client/OutfitDress")
	local Meshes=H.load("Shared/OutfitMeshes")
	local ref=Meshes.Ref.UpperTorso
	local torso=Instance.new("Part");torso.Size=Vector3.new(ref.X*2,ref.Y,ref.Z*1.5);torso.CFrame=CFrame.new(10,5,0)
	local size,cf=Dress.place(torso,"UpperTorso",Vector3.new(1,1,1),Vector3.new(.5,.2,-.1))
	assert(size and math.abs(size.X-2)<1e-4 and math.abs(size.Y-1)<1e-4 and math.abs(size.Z-1.5)<1e-4,"scaled by the part: "..tostring(size))
	local p=cf.Position
	assert(math.abs(p.X-11)<1e-4 and math.abs(p.Y-5.2)<1e-4 and math.abs(p.Z+.15)<1e-4,"the offset is not scaled: "..tostring(p))
	assert(Dress.place(torso,"Tail",Vector3.one,Vector3.zero)==nil,"a part with no reference got placed")
	-- every slot of every model gets a colour: the item's, else the new slot's
	for id,model in Meshes.Items do
		local item=Shop.item(id)
		for _,piece in Meshes.Models[model] do
			local c=(item.colors and item.colors[piece.slot]) or (Meshes.NewSlots[model] and Meshes.NewSlots[model][piece.slot])
			assert(c,id.." has no colour for "..piece.slot)
		end
	end
end)

-- (15/11, François: « les tenues ne s'adaptent pas aux personnages ») A coat's
-- tails hang from the hips along the legs: on hips twice the standard height
-- (a bundle), the tails keep the legs' length, not twice it.
test("a coat's tails follow the legs, not the hips' height",function()
	local Dress=H.load("Client/OutfitDress")
	local Meshes=H.load("Shared/OutfitMeshes")
	local ref=Meshes.Ref.LowerTorso
	local function body(hips)
		local model=Instance.new("Model")
		local lower=Instance.new("Part");lower.Name="LowerTorso";lower.Size=Vector3.new(ref.X,hips,ref.Z);lower.CFrame=CFrame.new(0,3,0);lower.Parent=model
		for name,r in {RightUpperLeg=Meshes.Ref.RightUpperLeg,RightLowerLeg=Meshes.Ref.RightLowerLeg} do
			local leg=Instance.new("Part");leg.Name=name;leg.Size=r;leg.Parent=model
		end
		return model,lower
	end
	-- Gaara's coat: 3.88 hips tall, its centre 2.34 hips below the hips' centre
	local size0=Vector3.new(2.86,3.88*ref.Y,.26)
	local o=Vector3.new(0,-2.34*ref.Y,-.71)
	local m1,standard=body(ref.Y)
	local s1,c1=Dress.place(standard,"LowerTorso",size0,o,m1)
	assert(math.abs(s1.Y-size0.Y)<1e-3 and math.abs(c1.Position.Y-(3+o.Y))<1e-3,"the standard body's coat moved")
	local m2,thick=body(ref.Y*2)
	local s2,c2=Dress.place(thick,"LowerTorso",size0,o,m2)
	local bottom1=c1.Position.Y-s1.Y/2-(3-standard.Size.Y/2)
	local bottom2=c2.Position.Y-s2.Y/2-(3-thick.Size.Y/2)
	assert(math.abs(bottom2-bottom1)<.05,string.format("the tails reach %.2f below the hips instead of %.2f",-bottom2,-bottom1))
	assert(s2.Y<size0.Y*1.2,"the coat doubled with the hips: "..s2.Y)
	-- without the legs (no model): the hips alone, as before
	local s3=Dress.place(thick,"LowerTorso",size0,o)
	assert(math.abs(s3.Y-size0.Y*2)<1e-3,"the old rule without legs")
	-- the server's cloth tail: along the legs too
	local Outfit=H.load("Server/Outfit")
	assert(math.abs(Outfit.legScale(m2)-1)<1e-3 and Outfit.legScale(nil)==1,"the legs scale: "..tostring(Outfit.legScale(m2)))
end)

-- (19/11, vague 2 DEV 2) The accessories: over a set or the pieces, each
-- cloth piece knowing its look, so the client hides only what it has a model
-- for (a cape stays over a modelled tunic).
test("the accessories: a mask, a cape and a scroll over Lee's suit; each piece knows its look",function()
	local model=body()
	Outfit.wear(model,{set="SetLee",mask="MaskCloth",cape="CapeTravel",back="BackScroll"})
	local list,holder=pieces(model)
	assert(holder:GetAttribute("NinjaOutfit")=="SetLee,MaskCloth,CapeTravel,BackScroll","what he wears: "..tostring(holder:GetAttribute("NinjaOutfit")))
	local by={}
	for _,p in list do
		local of=p:GetAttribute("NinjaItem")
		assert(of,p.Name.." does not know its look")
		by[of]=(by[of] or 0)+1
	end
	assert(by.SetLee and by.MaskCloth and by.CapeTravel and by.BackScroll,"a look built nothing")
	local cape,scroll
	for _,p in list do
		if p.Name=="Cape" then cape=p elseif p.Name=="Scroll" then scroll=p end
	end
	local torso=model.UpperTorso
	assert(cape and cape.Size.Y>torso.Size.Y*2,"the cape does not reach the knees")
	assert(scroll,"no scroll on the back")
	-- the mask: on the head, under the eyes (its top at the head's centre)
	for _,p in list do
		if p:GetAttribute("NinjaItem")=="MaskCloth" then
			local w=p:FindFirstChildOfClass("WeldConstraint")
			assert(w.Part0==model.Head,"the mask is not on the head")
		end
	end
	-- the pieces alone: the accessories still go on, a set's absence changes nothing
	Outfit.wear(model,{top="TopTunicNavy",cape="CapeTravel"})
	local _,h2=pieces(model)
	assert(h2:GetAttribute("NinjaOutfit")=="TopTunicNavy,CapeTravel","a cape over the pieces")
	local fs=require("@lune/fs")
	assert(string.find(fs.readFile("src/Client/OutfitDress.luau"),"of==nil or modelled[of]",1,true),"the client hides every cloth piece, modelled or not")
end)

print(string.format("NinjaDuel outfit (DEC-040): %d PASS",passed))
