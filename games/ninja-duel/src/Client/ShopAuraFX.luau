-- The auras of the shop (21/11, étape 3 ANIMATEUR 2, DEC-047). Next to the three merit auras
-- (MeritAuraFX: earned, never sold - flames at the feet, chakra on the outline, gold), these
-- are bought, and look nothing like them: a mood round the body, never a power, never a jutsu.
--
--   Aura.Sakura     petals drifting down round him, now and then
--   Aura.Ink        black ink wisps rising off the shoulders, like a brush drying
--   Aura.Fireflies  a few soft lights circling slowly at his waist
--   Aura.Frost      a cold breath at his feet, glints of ice in it
--   Aura.Thunder    a crackle across the shoulders every second or two, a faint hum
--   Aura.Shadow     a low violet smoke that clings to his legs
--
-- Who wears what: the player's attribute NinjaShopAura (Server/Progression: the id of the
-- Catalog item, AuraSakura...). Quieter in a duel (a third). Presentation only.
local AwakenFX=require(script.Parent.AwakenFX)
local emit=AwakenFX.emitter

local ShopAura={}
ShopAura.QUIET=.35
local C=Color3.fromRGB
local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function range(a,b) return NumberRange.new(a,b or a) end
local function cols(a,b) return ColorSequence.new(a,b or a) end
local function on(model,partName,name,pos)
	local p=model:FindFirstChild(partName)
	if not (p and p:IsA("BasePart")) then return nil end
	local a=Instance.new("Attachment");a.Name=name;a.Position=pos or Vector3.zero;a.Parent=p
	return a
end

-- id -> {colour (the shop's swatch), build(model, list)}
ShopAura.LOOKS={
	Sakura={color=C(255,170,205),build=function(m,list)
		local a=on(m,"Head","ShopAura",Vector3.new(0,2.5,0));if not a then return end
		table.insert(list,a)
		table.insert(list,emit(a,"leaf",{Rate=3,Lifetime=range(2.4,3.2),Speed=range(.6,1.2),SpreadAngle=Vector2.new(180,180),
			Shape=Enum.ParticleEmitterShape.Cylinder,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
			Acceleration=Vector3.new(.4,-1.2,0),Drag=1.5,Rotation=range(0,360),RotSpeed=range(-120,120),
			Color=cols(C(255,190,215),C(255,140,190)),LightEmission=.1,Size=seq({{0,.28},{.8,.26},{1,0}}),Transparency=seq({{0,.05},{.8,.15},{1,1}})}))
	end},
	Ink={color=C(30,28,36),build=function(m,list)
		for _,n in {"LeftUpperArm","RightUpperArm"} do
			local a=on(m,n,"ShopAura",Vector3.new(0,.4,0))
			if a then
				table.insert(list,a)
				table.insert(list,emit(a,"smoke",{Rate=4,Lifetime=range(.9,1.4),Speed=range(.6,1.2),SpreadAngle=Vector2.new(20,20),
					Acceleration=Vector3.new(0,1.6,0),Rotation=range(0,360),RotSpeed=range(-40,40),Color=cols(C(20,18,24),C(60,56,70)),
					LightEmission=0,Size=seq({{0,.4},{.6,.9},{1,1.2}}),Transparency=seq({{0,.35},{.6,.6},{1,1}})}))
			end
		end
	end},
	Fireflies={color=C(255,230,120),build=function(m,list)
		local a=on(m,"LowerTorso","ShopAura");if not a then return end
		table.insert(list,a)
		table.insert(list,emit(a,"spark",{Rate=2.5,Lifetime=range(2.5,3.5),Speed=range(.3,.7),SpreadAngle=Vector2.new(180,180),
			Shape=Enum.ParticleEmitterShape.Sphere,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Drag=.5,
			Color=cols(C(255,240,150),C(200,255,120)),LightEmission=1,Size=seq({{0,0},{.15,.2},{.5,.12},{.85,.2},{1,0}}),
			Transparency=seq({{0,.2},{.5,.5},{1,.2}})}))
	end},
	Frost={color=C(180,230,255),build=function(m,list)
		for _,n in {"LeftFoot","RightFoot"} do
			local a=on(m,n,"ShopAura")
			if a then
				table.insert(list,a)
				table.insert(list,emit(a,"dust",{Rate=5,Lifetime=range(.9,1.4),Speed=range(.3,.8),SpreadAngle=Vector2.new(70,10),
					Acceleration=Vector3.new(0,-.2,0),Drag=1,Color=cols(C(220,245,255)),LightEmission=.2,
					Size=seq({{0,.6},{1,1.6}}),Transparency=seq({{0,.55},{1,1}})}))
				table.insert(list,emit(a,"spark",{Rate=2,Lifetime=range(.5,.9),Speed=range(.2,.6),SpreadAngle=Vector2.new(90,90),
					Color=cols(C(240,250,255)),LightEmission=1,Size=seq({{0,0},{.3,.15},{1,0}})}))
			end
		end
	end},
	Thunder={color=C(150,180,255),build=function(m,list)
		local a=on(m,"UpperTorso","ShopAura",Vector3.new(0,.6,0));if not a then return end
		table.insert(list,a)
		table.insert(list,emit(a,"lightning",{Rate=.8,Lifetime=range(.08,.14),Speed=range(0),Rotation=range(0,360),
			Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
			Color=cols(C(220,235,255),C(140,170,255)),LightEmission=1,Size=range(1,1.6),Transparency=seq({{0,.1},{1,.6}})}))
		table.insert(list,emit(a,"spark",{Rate=4,Lifetime=range(.1,.25),Speed=range(2,5),SpreadAngle=Vector2.new(180,180),
			Color=cols(C(200,220,255)),LightEmission=1,Size=seq({{0,.15},{1,0}})}))
	end},
	Shadow={color=C(110,70,150),build=function(m,list)
		for _,n in {"LeftLowerLeg","RightLowerLeg"} do
			local a=on(m,n,"ShopAura",Vector3.new(0,-.3,0))
			if a then
				table.insert(list,a)
				table.insert(list,emit(a,"smoke",{Rate=6,Lifetime=range(.7,1.1),Speed=range(.2,.6),SpreadAngle=Vector2.new(60,60),
					Acceleration=Vector3.new(0,.8,0),Rotation=range(0,360),RotSpeed=range(-30,30),Color=cols(C(70,40,100),C(30,20,40)),
					LightEmission=.1,Size=seq({{0,.7},{1,1.6}}),Transparency=seq({{0,.45},{1,1}})}))
			end
		end
	end},
}
ShopAura.ORDER={"Sakura","Ink","Fireflies","Frost","Thunder","Shadow"}
function ShopAura.key(id)
	id=tostring(id or "")
	return (string.gsub(id,"^Aura",""))
end
function ShopAura.fxName(id) return "Aura."..ShopAura.key(id) end

ShopAura.worn=setmetatable({},{__mode="k"})
function ShopAura.remove(model)
	local st=model and ShopAura.worn[model]
	if not st then return end
	for _,x in st.items do
		if x.Parent then
			if x:IsA("ParticleEmitter") then x.Enabled=false end
			x:Destroy()
		end
	end
	ShopAura.worn[model]=nil
	model:SetAttribute("ShopAura",nil)
end
function ShopAura.setQuiet(model,quiet)
	local st=model and ShopAura.worn[model]
	if not st then return end
	for _,x in st.items do
		if x:IsA("ParticleEmitter") then x.Rate=(x:GetAttribute("AuraRate") or x.Rate)*(if quiet then ShopAura.QUIET else 1) end
	end
end
function ShopAura.wear(model,id,quiet)
	if not model then return nil end
	ShopAura.remove(model)
	local look=ShopAura.LOOKS[ShopAura.key(id)]
	if not look then return nil end
	local list={}
	local ok,err=pcall(look.build,model,list)
	if not ok then
		for _,x in list do if x.Parent then x:Destroy() end end
		warn("[ShopAuraFX] "..tostring(err))
		return nil
	end
	for _,x in list do
		if x:IsA("ParticleEmitter") then x.Name=ShopAura.fxName(id);x:SetAttribute("AuraRate",x.Rate);x.Enabled=true end
	end
	ShopAura.worn[model]={id=id,items=list}
	model:SetAttribute("ShopAura",ShopAura.key(id))
	if quiet then ShopAura.setQuiet(model,true) end
	return list
end

-- Every player's character wears his NinjaShopAura, now and at each respawn.
function ShopAura.start()
	if ShopAura.started then return end
	ShopAura.started=true
	local Players=game:GetService("Players")
	local function dress(player)
		local ch=player.Character
		if not ch then return end
		local id=player:GetAttribute("NinjaShopAura")
		local st=ShopAura.worn[ch]
		if not id or id=="" then ShopAura.remove(ch)
		elseif not st or st.id~=id then ShopAura.wear(ch,id) end
	end
	local function track(player)
		player:GetAttributeChangedSignal("NinjaShopAura"):Connect(function() dress(player) end)
		player.CharacterAdded:Connect(function(ch) ch:WaitForChild("HumanoidRootPart",10);dress(player) end)
		dress(player)
	end
	for _,p in Players:GetPlayers() do task.spawn(track,p) end
	Players.PlayerAdded:Connect(track)
end

return ShopAura
