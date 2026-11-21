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
local Instance,Vector3,Color3=roblox.Instance,roblox.Vector3,roblox.Color3
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

print(("NinjaDuel style FX: %d PASS"):format(passed))
