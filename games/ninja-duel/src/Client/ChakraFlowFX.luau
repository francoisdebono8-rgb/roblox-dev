-- ChakraFlow on the client (Freedom, user 28/10: chakra infusions): the load
-- (the body glows in its nature, chakra rising off it), the infused limbs
-- while the strike is out, the nature on contact, the leap and the dash.
-- Presentation only: the server (Server/ChakraFlow) decides everything.
-- One layer installed into Effects (like LeeFX): Effects only offers helpers.
local Debris=game:GetService("Debris")

local ChakraFlowFX={}
local K -- Effects' helpers, handed over by install()

ChakraFlowFX.Color={
	Lightning=Color3.fromRGB(150,205,255),Fire=Color3.fromRGB(255,124,44),Wind=Color3.fromRGB(176,255,226),
	Sand=Color3.fromRGB(218,184,116),GentleFist=Color3.fromRGB(196,216,255),Strength=Color3.fromRGB(255,196,90),
	Chakra=Color3.fromRGB(110,172,255),
}
local CORE=Color3.fromRGB(250,252,255)
local LIMBS={"RightHand","LeftHand","RightFoot","LeftFoot"}

local function colorOf(nature) return ChakraFlowFX.Color[nature or ""] or ChakraFlowFX.Color.Chakra end
local function stateOf(fx,model)
	fx.flowState=fx.flowState or setmetatable({},{__mode="k"})
	local st=fx.flowState[model]
	if not st then st={};fx.flowState[model]=st end
	return st
end
local function particles(parent,props)
	local e=K.new("ParticleEmitter",{Enabled=false,LightInfluence=0,ZOffset=.6},parent)
	for k,v in props do e[k]=v end
	return e
end
-- The aura: chakra rising off the whole body (and a light), built once.
local function aura(st,model,nature)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if st.aura and st.aura.nature==nature and st.aura.at.Parent then return st.aura end
	if st.aura then st.aura.at:Destroy() end
	local color=colorOf(nature)
	local at=K.new("Attachment",{Name="ChakraFlowAura",Position=Vector3.new(0,-.4,0)},root)
	local rise=particles(at,{Name="Rise",Texture=K.TEX.fire,Rate=60,Lifetime=NumberRange.new(.35,.6),Speed=NumberRange.new(5,9),
		SpreadAngle=Vector2.new(18,18),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,6,0),
		Color=K.seq({{0,CORE},{.3,color},{1,color}}),LightEmission=1,Size=K.num({{0,1.4},{.5,1.9},{1,.3}}),
		Transparency=K.num({{0,.35},{.6,.55},{1,1}}),Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
		ShapePartial=1,Drag=1})
	pcall(function() rise.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward end)
	local spark=if nature=="Lightning" then particles(at,{Name="Arc",Texture=K.TEX.spark,Rate=24,Lifetime=NumberRange.new(.08,.16),Speed=NumberRange.new(8,16),
		SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(CORE),LightEmission=1,Size=K.num({{0,.6},{1,0}})}) else nil
	local light=K.new("PointLight",{Color=color,Brightness=0,Range=12,Shadows=false},root)
	st.aura={at=at,rise=rise,spark=spark,light=light,nature=nature}
	return st.aura
end
-- Infused limbs: each hand and foot pours its nature while the strike is out.
local function limbs(st,model,nature)
	if st.limbs and st.limbs.nature==nature then return st.limbs end
	if st.limbs then for _,e in st.limbs.list do e:Destroy() end end
	local color=colorOf(nature)
	local list={}
	for _,name in LIMBS do
		local part=model:FindFirstChild(name)
		if part then
			local at=K.new("Attachment",{Name="ChakraFlowLimb"},part)
			table.insert(list,particles(at,{Name="Infused",Texture=K.TEX.fire,Rate=90,Lifetime=NumberRange.new(.15,.3),Speed=NumberRange.new(1,3),
				SpreadAngle=Vector2.new(180,180),Color=K.seq({{0,CORE},{.4,color},{1,color}}),LightEmission=1,
				Size=K.num({{0,.9},{1,.1}}),Transparency=K.num({{0,.2},{1,1}}),Drag=4}))
			table.insert(list,at)
		end
	end
	st.limbs={list=list,nature=nature}
	return st.limbs
end
local function fighter(fx,model,actor,dt)
	if not model or not actor then return end
	local st=stateOf(fx,model)
	local loaded=actor.chakraLoad
	if loaded or st.aura then
		local a=if loaded then aura(st,model,loaded) else st.aura
		if a then
			a.rise.Enabled=loaded~=nil
			if a.spark then a.spark.Enabled=loaded~=nil end
			-- the light swells in, then breathes
			local target=if loaded then 2.2+math.sin(os.clock()*9)*.5 else 0
			a.light.Brightness+=(target-a.light.Brightness)*math.min(1,(dt or 1/60)*14)
		end
	end
	local infused=actor.infused and actor.attackName and (actor.state=="Startup" or actor.state=="Active")
	if infused or st.limbs then
		local l=if infused then limbs(st,model,actor.infused) else st.limbs
		for _,e in l.list do if e:IsA("ParticleEmitter") then e.Enabled=infused==true end end
	end
end
local function modelOf(folder,id)
	return folder and id and folder:FindFirstChild(id)
end
local function impact(fx,i,folder)
	local style=i.style
	if style~="chakraload" and style~="chakrastrike" and style~="chakrahit" and style~="chakraleap" and style~="chakradash" then return false end
	local color=colorOf(i.nature)
	local p=i.position
	if style=="chakraload" then
		-- The chakra comes up out of the ground round the feet.
		K.shockRing(fx.folder,p-Vector3.new(0,2.6,0),color,2,9,.3)
		K.flash(fx.folder,p,color,1,5,.18,.35)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.whoosh,.3,.55)
	elseif style=="chakrastrike" then
		local model=modelOf(folder,i.owner)
		local hand=model and model:FindFirstChild("RightHand")
		K.flash(fx.folder,if hand then hand.Position else p,color,.6,3,.12,.3)
	elseif style=="chakrahit" then
		local big=i.heavy
		local dir=i.direction or Vector3.zAxis
		if i.nature=="Lightning" then
			K.sparks(fx.folder,p,CORE,if big then 30 else 20,30)
			K.sparks(fx.folder,p,color,16,22)
			K.flash(fx.folder,p,CORE,1,if big then 7 else 5,.14,.1)
			K.sound(K.anchorPart(fx.folder,p),K.SOUND.electric,.4,1.2)
		elseif i.nature=="Fire" then
			K.flash(fx.folder,p,color,1.2,if big then 7 else 5,.2,.2)
			K.smokePuff(fx.folder,p,Color3.fromRGB(70,54,46),10,1.6)
			K.sparks(fx.folder,p,Color3.fromRGB(255,190,90),14,18)
		elseif i.nature=="Wind" then
			-- a cut of air carried past the body
			K.shockRing(fx.folder,p,color,2,if big then 16 else 11,.24,dir)
			K.shockRing(fx.folder,p+dir*2.5,CORE,1,8,.2,dir)
			K.smokePuff(fx.folder,p+dir*1.5,Color3.fromRGB(226,240,236),8,1.5)
		elseif i.nature=="GentleFist" then
			K.flash(fx.folder,p,color,.6,if big then 6 else 4,.14,.2)
			K.shockRing(fx.folder,p,color,1,6,.18,dir)
		elseif i.nature=="Sand" then
			K.smokePuff(fx.folder,p,color,16,2)
			K.shockRing(fx.folder,p,color,2,10,.26,dir)
		elseif i.nature=="Strength" then
			K.shockRing(fx.folder,p,color,2,if big then 20 else 14,.3,dir)
			K.flash(fx.folder,p,CORE,1,6,.14,.15)
			K.smokePuff(fx.folder,p,Color3.fromRGB(214,204,180),14,2)
		else
			K.flash(fx.folder,p,color,1,5,.16,.2)
			K.shockRing(fx.folder,p,color,1.5,10,.22,dir)
		end
		if i.guarded then K.flash(fx.folder,p,Color3.fromRGB(255,214,120),.5,3,.1,.3) end
	elseif style=="chakraleap" then
		-- The ground takes the push: a ring flat on it and the dust thrown out.
		K.shockRing(fx.folder,p,color,2,13,.3)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),Color3.fromRGB(206,194,168),14,1.8)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.whoosh,.4,.75)
	elseif style=="chakradash" then
		local model=modelOf(folder,i.owner)
		if model and fx.ghost then fx:ghost(model,color,.25,.45) end
		K.flash(fx.folder,p,color,1,6,.16,.3)
		K.smokePuff(fx.folder,p-Vector3.new(0,if i.air then 0 else 2.5,0),Color3.fromRGB(206,194,168),if i.air then 4 else 10,1.5)
	end
	-- the other layers still draw their own on a chakra hit (a fist burst...)
	return style~="chakrahit"
end

function ChakraFlowFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="ChakraFlow",impact=impact,fighter=fighter})
end
return ChakraFlowFX
