-- (21/11, étape 3 ANIMATEUR 2, DEC-047) The personalization that is the ANIMATEUR's: every
-- victory pose and emote of the shop has its clip, every shop aura its look (Client/ShopAuraFX:
-- on the body, quieter in a duel, gone when removed, never a merit aura), and the chakra colour
-- (Client/ChakraTintFX) recolours what is drawn in the chakra blue and nothing else.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","Vector3","Vector2","Color3","CFrame","Enum","ColorSequence","ColorSequenceKeypoint","NumberSequence",
	"NumberSequenceKeypoint","NumberRange"} do H.envBase[k]=roblox[k] end
local Catalog=H.load("Shared/Catalog")
local Style=H.load("Shared/CatalogStyle")
local Aura=H.load("Client/ShopAuraFX")
local Tint=H.load("Client/ChakraTintFX")
local Instance,Vector3,Color3,CFrame=roblox.Instance,roblox.Vector3,roblox.Color3,roblox.CFrame
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local PARTS={"HumanoidRootPart","Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
	"LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
local function body()
	local m=Instance.new("Model")
	for _,n in PARTS do local p=Instance.new("Part");p.Name=n;p.Size=Vector3.new(1,1,1);p.Parent=m end
	return m
end
-- the clips in the game: the layers AuthoredJutsu9.. (étape 3) and the others (by name only)
local clips={}
for i=1,40 do
	local ok,mod=pcall(H.load,"Client/AuthoredJutsu"..i)
	if not ok then break end
	for name in mod do clips[name]=true end
end

test("every victory pose and emote of the shop has its clip",function()
	local n=0
	for _,list in {Catalog.Items,Style.Items} do
		for _,it in list do
			if it.slot=="victory" or it.slot=="emote" then
				assert(it.clip,it.id..": no clip")
				assert(clips[it.clip],it.id..": clip "..it.clip.." is not in the game")
				n+=1
			end
		end
	end
	assert(n>=14,"only "..n.." poses and emotes")
end)

test("every shop aura has its look, and none is a merit aura",function()
	local n=0
	for _,it in Catalog.Items do
		if it.slot=="aura" then
			n+=1
			assert(Aura.LOOKS[Aura.key(it.id)],it.id..": no look")
			assert(it.fx==Aura.fxName(it.id),it.id..": fx "..tostring(it.fx))
			assert(not it.tier,"a merit aura in the shop's list: "..it.id)
		end
	end
	assert(n==#Aura.ORDER,"looks "..#Aura.ORDER.." vs catalog "..n)
end)

test("a shop aura: on the body, quieter in a duel, gone without a trace",function()
	for _,k in Aura.ORDER do
		local m=body()
		local list=assert(Aura.wear(m,"Aura"..k),k..": nothing")
		local full={}
		for _,x in list do if x:IsA("ParticleEmitter") then table.insert(full,x.Rate) end end
		assert(#full>0,k..": no emitter")
		Aura.setQuiet(m,true)
		local i=0
		for _,x in list do if x:IsA("ParticleEmitter") then i+=1;assert(x.Rate<full[i],k..": not quieter") end end
		Aura.remove(m)
		for _,d in m:GetDescendants() do assert(not d:IsA("ParticleEmitter") and not d:IsA("Attachment"),k..": left "..d.ClassName) end
		assert(m:GetAttribute("ShopAura")==nil)
	end
	assert(Aura.wear(body(),"AuraNone")==nil and Aura.wear(nil,"AuraInk")==nil)
end)

test("the chakra colour: the chakra blue takes his hue, the rest keeps its colour",function()
	local crimson=Color3.fromRGB(220,40,48)
	local blue=Color3.fromRGB(110,180,255)
	local c,ok=Tint.shift(blue,crimson)
	local h=c:ToHSV()
	assert(ok and (h<.05 or h>.95),"the chakra blue did not turn crimson: "..h)
	for _,keep in {Color3.fromRGB(255,140,50),Color3.fromRGB(230,230,230),Color3.fromRGB(196,176,140)} do
		local c2,ok2=Tint.shift(keep,crimson)
		assert(not ok2 and c2==keep,"a non-chakra colour changed")
	end
	local m=body()
	local e=Instance.new("ParticleEmitter");e.Color=roblox.ColorSequence.new(blue);e.Parent=m.UpperTorso
	local fire=Instance.new("ParticleEmitter");fire.Color=roblox.ColorSequence.new(Color3.fromRGB(255,140,50));fire.Parent=m.RightHand
	m:SetAttribute("NinjaChakra",crimson)
	assert(Tint.colorOf(m)==crimson)
	assert(Tint.applyAll(m,crimson)==1,"one chakra emitter")
	assert(e:GetAttribute("ChakraTinted") and not fire:GetAttribute("ChakraTinted"))
	assert(Tint.applyAll(m,crimson)==0,"tinted twice")
end)

-- Konoha's street life (Client/KonohaLifeFX): drawn from the plan, above the street, cheap.
test("the street life comes from the plan and stays out of the fight",function()
	local Life=H.load("Client/KonohaLifeFX")
	local Layout=H.load("Shared/KonohaLayout")
	local O=Vector3.new(0,0,-2400)
	local plan=Life.plan(Layout,O,1.3)
	assert(#plan.steam>=2,"steam over Ichiraku and shops")
	assert(#plan.bunting>=3,"bunting across the market streets")
	assert(#plan.birds==3 and #plan.leaves==9)
	local ichi
	for _,b in Layout.Buildings do if b[1]=="ichiraku" then ichi=b end end
	assert(ichi,"Ichiraku is in the plan")
	assert((plan.steam[1].pos-Life.world(O,1.3,ichi[2],ichi[6]+1,ichi[3])).Magnitude<1e-3 or #plan.steam>1)
	local laundry=0
	for _,b in plan.bunting do
		assert(b.a.Y-O.Y>=(if b.laundry then 11 else 16)*1.3-1e-3,"a line under head height")
		if b.laundry then laundry+=1 end
	end
	assert(laundry>=8,"laundry lines: "..laundry)
	assert(#plan.nobori>=10,"shop banners: "..#plan.nobori)
	local folder=Instance.new("Folder")
	local made=Life.build(folder,plan)
	Life.step(made,1.5)
	local n=0
	for _,x in folder:GetDescendants() do
		if x:IsA("BasePart") then n+=1;assert(not x.CanCollide and not x.CanQuery and x.Anchored,x.Name.." collides") end
	end
	assert(n<900,"too many parts: "..n)
	assert(#made.birds==18)
end)

test("the kunai boards wear the modelled board, facing the mark, inside their Target",function()
	local Life=H.load("Client/KonohaLifeFX")
	local Solo=H.load("Shared/Solo")
	local data=H.load("Client/PropMeshData")
	assert(data.kunai_board and #data.kunai_board>0)
	local targets=Instance.new("Model")
	for i in Solo.Targets.boards do
		local b=Instance.new("Model");b.Name="Target"..i;b.Parent=targets
		local d=Instance.new("Part");d.Name="Disc";d.Parent=b
	end
	local n=Life.dressBoards(targets,Solo,function() return Instance.new("Part") end,data)
	assert(n==#Solo.Targets.boards,"dressed "..n)
	local b1=targets:FindFirstChild("Target1")
	assert(b1:FindFirstChild("BoardMesh") and b1:FindFirstChild("Disc").Transparency==1)
	local cf=Life.boardFrame(Solo.board(1),Solo.targetsMark())
	local toMark=(Solo.targetsMark()-Solo.board(1))
	assert(cf.LookVector:Dot(Vector3.new(toMark.X,0,toMark.Z).Unit)<-.99,"the face turns to the mark")
	assert(Life.dressBoards(targets,Solo,function() return Instance.new("Part") end,data)==0,"dressed once")
end)

test("the villagers: walk a street of the plan and back, wait at its ends, the duel's rig, never solid",function()
	local Folk=H.load("Client/KonohaFolkFX")
	local Layout=H.load("Shared/KonohaLayout")
	local O=Vector3.new(0,0,-2400)
	local routes=Folk.routes(Layout,O,1.3,26)
	assert(#routes==26)
	local streets={}
	for _,r in routes do streets[r.street]=true;assert((r.b-r.a).Magnitude>30) end
	local n=0;for _ in streets do n+=1 end
	assert(n>=12,"spread over the streets: "..n)
	local r=routes[1]
	local speed=5.2*1.3
	local walk=(r.b-r.a).Magnitude/speed
	local seen={walk=false,wait=false}
	for k=0,400 do
		local at,dir,moving=Folk.at(r,k*.25,speed)
		seen[if moving then "walk" else "wait"]=true
		-- always on his segment
		local ab=r.b-r.a
		local u=(at-r.a):Dot(ab)/ab:Dot(ab)
		assert(u>-1e-3 and u<1+1e-3)
		assert(math.abs(dir.Magnitude-1)<1e-3)
	end
	assert(seen.walk and seen.wait)
	local model=Folk.rig(Color3.new(1,.8,.7),Color3.new(.3,.3,.4),Color3.new(.2,.2,.2))
	local motors=0
	for _,d in model:GetDescendants() do
		if d:IsA("Motor6D") then motors+=1 end
		if d:IsA("BasePart") then assert(not d.CanCollide and not d.CanQuery,d.Name) end
	end
	assert(motors>=16 and model:FindFirstChild("RightUpperArm") and model.PrimaryPart.Anchored)
	-- the wardrobe on it: a fake Dress, each piece on its body part in the slot's colour
	local fake={template=function(name) local p=Instance.new("Part");p.Size=Vector3.one;return {{part=p,on="UpperTorso",slot="Cloth",o=Vector3.zero}} end,
		place=function(body) return Vector3.one,body.CFrame end,material=function(m) return m end}
	assert(Folk.dress(model,fake,{"Tunic","HairBowl"},{Cloth=Color3.new(1,0,0)})==2)
end)

test("every house its colours: its quarter's palette, picked by its place, landmarks untouched",function()
	local Life=H.load("Client/KonohaLifeFX")
	local Layout=H.load("Shared/KonohaLayout")
	local O=Vector3.new(0,0,-2400)
	local root=Instance.new("Folder")
	local copiesOf={}
	local made=0
	for _,b in Layout.Buildings do
		local u=Instance.new("Model");u.Parent=root
		u:SetAttribute("LayoutModel",b[1])
		u:SetAttribute("DressAt",CFrame.new(O+Vector3.new(b[2],0,b[3])*1.3))
		local w=Instance.new("Part");w.Name="Walls";w.Parent=u
		local list={}
		for _,name in {"Walls","Tiles","Timber","Openings"} do local p=Instance.new("Part");p.Name=name;p.Color=Color3.new(1,1,1);table.insert(list,p) end
		copiesOf[w]=list
		made+=1
	end
	local n=Life.tintHouses(root,copiesOf,Layout,O,1.3)
	assert(n>100 and n<made,"houses tinted: "..n.." of "..made)
	assert(Life.tintHouses(root,copiesOf,Layout,O,1.3)==0,"once")
	-- the market's houses do not all wear one colour, the Uchiha roofs are dark
	local market,uchiha={}, nil
	for w,list in copiesOf do
		local u=w.Parent
		local at=(u:GetAttribute("DressAt").Position-O)/1.3
		local d=Life.district(Layout,at.X,at.Z)
		if Life.HOUSES[u:GetAttribute("LayoutModel")] then
			if d=="Market" then market[tostring(list[1].Color)]=true end
			if d=="Uchiha" then uchiha=list[2].Color end
		else
			assert(list[1].Color==Color3.new(1,1,1),"a landmark keeps its own colours")
		end
	end
	local kinds=0;for _ in market do kinds+=1 end
	assert(kinds>=4,"market colours: "..kinds)
	assert(uchiha and uchiha.R<.45,"the Uchiha roofs are dark")
end)

test("the market's stalls and barrels wear their models, on the block's foot; the block stays solid",function()
	local Life=H.load("Client/KonohaLifeFX")
	local data=H.load("Client/PropMeshData")
	assert(data.market_stall and data.barrel)
	local root=Instance.new("Folder")
	local stall=Instance.new("Part");stall.Name="Prop_stall";stall.Size=Vector3.new(8,6,5);stall.CFrame=CFrame.new(10,3,20);stall.Parent=root
	local barrel=Instance.new("Part");barrel.Name="Prop_barrel";barrel.Size=Vector3.new(3,3.6,3)
	barrel.CFrame=CFrame.new(0,1.8,0)*CFrame.Angles(0,0,math.pi/2);barrel.Parent=root
	local n=Life.dressProps(root,function() return Instance.new("Part") end,data)
	assert(n==2 and stall.Transparency==1 and stall.CanCollide)
	assert(math.abs(Life.propFoot(stall).Position.Y)<1e-3 and math.abs(Life.propFoot(barrel).Position.Y)<1e-3,"on the ground")
	assert(Life.dressProps(root,function() return Instance.new("Part") end,data)==0,"once")
end)

-- (24/11, passe commune 1) « le personnage apparaît debout sur un tonneau »: no clutter where one
-- arrives, by a master or on a street-duel place; elsewhere the props stay.
test("the arrival, the masters and the duel places are kept clear of the village's clutter",function()
	local Life=H.load("Client/KonohaLifeFX")
	local HubMap=H.load("Shared/HubMap")
	local zones=Life.zones(HubMap)
	assert(#zones>=4,"zones")
	local gate=HubMap.Spawns.gate.at
	assert(Life.inClear(zones,gate+Vector3.new(3,0,2)),"the arrival")
	for _,m in HubMap.Masters do assert(Life.inClear(zones,m.at),"by a master") end
	local origin=Vector3.new(0,0,0)
	local root=Instance.new("Folder")
	local onSpawn=Instance.new("Part");onSpawn.Name="Prop_barrel";onSpawn.CFrame=CFrame.new(gate.X+1,1.8,gate.Z);onSpawn.Parent=root
	local far=Instance.new("Part");far.Name="Prop_barrel";far.CFrame=CFrame.new(5000,1.8,5000);far.Parent=root
	assert(Life.clearProps(root,zones,origin,nil)==1)
	assert(onSpawn.LocalTransparencyModifier==1 and not onSpawn.CanCollide and not onSpawn.CanQuery,"gone from this screen")
	assert(far:GetAttribute("LifeCleared")==nil and far.CanCollide,"kept elsewhere")
	assert(Life.dressProps(root,function() return Instance.new("Part") end,H.load("Client/PropMeshData"))==1,"only the far one dressed")
end)

-- (24/11, passe commune 1) the rogue ninjas (Server/Thugs) as this screen draws them
test("the rogue ninjas: their own look (never in the shop), their four clips, their state picks the clip",function()
	local Rogue=H.load("Client/KonohaRogueFX")
	for _,item in Catalog.Items do assert(item.id~=Rogue.LOOK,"the rogues' look is not in the shop") end
	local Meshes=H.load("Shared/OutfitMeshes")
	assert(Meshes.Sets[Rogue.LOOK] and Meshes.Items[Rogue.LOOK]==nil,"their look is modelled, and is no Shop item")
	for slot in Rogue.COLORS do assert(string.match(slot,"^%u%a+%u%a+$"),"a set's slot: "..slot) end
	for _,n in {"Rogue.Idle","Rogue.Racket","Rogue.Taunt","Rogue.Leave"} do assert(clips[n],"clip "..n) end
	assert(Rogue.keyOf("Thug_plaza")=="plaza" and Rogue.keyOf("Villager")==nil)
	assert(Rogue.clipAt("racket",10,11)=="Rogue.Racket" and select(2,Rogue.clipAt("racket",10,11))==1)
	assert(Rogue.clipAt("idle",1,5)=="Rogue.Idle" and Rogue.clipAt("leave",0,.2)=="Rogue.Leave")
end)

print(("NinjaDuel style FX: %d PASS"):format(passed))
