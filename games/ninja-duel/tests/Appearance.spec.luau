-- The kit and the body (DEC-036, 12/11: the player's ninja wears a
-- prodigy's kit; AVATAR-001 steps 1 and 2). The kit is the prodigy
-- (Shared/Fighters); the body is the look worn (Shared/Appearance). Checked
-- here: every prodigy's own body is himself (built exactly as before); a
-- body can wear another prodigy's look and its own colours while the kit
-- stays; the pieces that serve a technique are listed per kit, exist in that
-- kit's look and are marked KitItem. Headless; the look itself is a Studio
-- check (step 3: every kit on the Ōtsutsuki).
local H=require("./Harness")
local fs=require("@lune/fs")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Fighters=H.load("Shared/Fighters")
local Appearance=H.load("Shared/Appearance")
local BetaRoster=H.load("Shared/BetaRoster")

test("every prodigy's own body is himself: he is dressed exactly as before",function()
	local World=H.load("Server/World")
	for id,def in Fighters do
		if type(def)=="table" and def.Name then
			assert(World.lookDef(nil,def)==def,id..": no body is not his own")
			assert(World.lookDef(Appearance.of(def),def)==def,id..": his own body is not himself")
		end
	end
end)

test("a body wears another look and its own colours; the kit does not change",function()
	local World=H.load("Server/World")
	local sasuke=Fighters.Lion
	local look=World.lookDef({look="Neji"},sasuke)
	assert(look.Name=="Neji" and look.Skin==Fighters.GentleFist.Skin,"the body does not wear Neji's look")
	local tinted=World.lookDef({look="Neji",hair={10,20,30},outfit={1,2,3}},sasuke)
	assert(tinted.Name=="Neji" and tinted.Hair[1]==10 and tinted.Outfit[3]==3 and tinted.Skin==Fighters.GentleFist.Skin,"the body's colours were not taken")
	assert(Fighters.GentleFist.Hair[1]~=10,"the colours leaked into Neji's own def")
	assert(sasuke.Name=="Sasuke" and sasuke.Health==Fighters.Lion.Health,"the kit changed")
end)

test("dress puts on the body's look, not the kit's",function()
	local instance,restore=H.stubScene()
	local ok,err=pcall(function()
		local World=H.load("Server/World")
		local Looks=H.load("Server/Looks")
		local worn={}
		local saved={Neji=Looks.dressers.Neji,Sasuke=Looks.dressers.Sasuke}
		Looks.dressers.Neji=function(_,d) table.insert(worn,d.Name) end
		Looks.dressers.Sasuke=function(_,d) table.insert(worn,d.Name) end
		local function model()
			local m=instance("Model")
			local head=instance("Part");head.Name="Head";head.Parent=m
			return m
		end
		World.dress(model(),Fighters.Lion)
		World.dress(model(),Fighters.Lion,{look="Neji"})
		Looks.dressers.Neji=saved.Neji;Looks.dressers.Sasuke=saved.Sasuke
		assert(worn[1]=="Sasuke","Sasuke's kit without a body was not dressed as Sasuke ("..tostring(worn[1])..")")
		assert(worn[2]=="Neji","Sasuke's kit in Neji's look was dressed as "..tostring(worn[2]))
	end)
	restore()
	assert(ok,err)
end)

test("the pieces that serve a technique are listed for their kit and exist in its look",function()
	local meshes=H.load("Server/LookMeshData")
	local looksSrc=fs.readFile("src/Server/Looks.luau")
	for id,prefixes in Appearance.KitItems do
		local def=Fighters[id]
		assert(def,"KitItems names a kit that does not exist: "..id)
		for _,prefix in prefixes do
			local found=false
			for _,piece in (meshes[def.Name] or {pieces={}}).pieces do
				if Appearance.isKitItem(id,piece.name) and string.find(piece.name,"__"..prefix,1,true) then found=true end
			end
			if not found and string.find(looksSrc,'"'..prefix,1,true) then found=true end
			assert(found,id.." "..prefix..": no such piece in "..def.Name.."'s look")
		end
	end
	-- The kits whose technique needs something worn are all covered.
	assert(Appearance.KitItems.Sand,"Gaara's gourd")
	assert(Fighters.Copycat.Weapon and Appearance.KitItems.Copycat,"Kakashi's tanto")
	assert(Appearance.KitItems.Lion,"Sasuke's curse mark")
	assert(Appearance.KitItems.GentleFist,"Neji's Byakugan veins")
	assert(Appearance.isKitItem("Sand","UpperTorso__GourdCork") and Appearance.isKitItem("Sand","GourdStrap"))
	assert(not Appearance.isKitItem("Sand","UpperTorso__Chest") and not Appearance.isKitItem("Sand","LeftLowerLeg__AnkleStrap"))
	assert(not Appearance.isKitItem("Mirage","UpperTorso__Sheath"),"Itachi's sheath serves no technique of his")
	for _,id in BetaRoster do assert(Fighters[id],id) end
end)

test("a dressed fighter's kit pieces carry KitItem = their prodigy",function()
	local instance,restore=H.stubScene()
	local ok,err=pcall(function()
		local World=H.load("Server/World")
		local m=instance("Model")
		local gourd=instance("MeshPart");gourd.Name="UpperTorso__GourdCork";gourd.Parent=m
		local chest=instance("MeshPart");chest.Name="UpperTorso__Chest";chest.Parent=m
		gourd.IsA=function(_,q) return q=="BasePart" or q=="MeshPart" end
		chest.IsA=gourd.IsA
		local attrs={}
		gourd.SetAttribute=function(_,k,v) attrs[k]=v end
		chest.SetAttribute=function(_,k,v) attrs["chest."..k]=v end
		World.markKitItems(m,Fighters.Sand)
		assert(attrs.KitItem=="Sand","the gourd is not marked as Gaara's kit")
		assert(attrs["chest.KitItem"]==nil,"the chest was marked")
	end)
	restore()
	assert(ok,err)
end)

print(string.format("NinjaDuel kit and body (DEC-036): %d PASS",passed))
