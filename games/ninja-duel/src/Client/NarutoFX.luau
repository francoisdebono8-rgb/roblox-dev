-- Naruto on the client (roster wave, several bodies): the puffs of smoke of
-- his shadow clones (appearing, dispelled by one blow, spent after a route,
-- swapped in a substitution, a kunai turning back into one, burnt away by the
-- red chakra), the Rasengan forming between his palm and the clone that
-- shapes it, the Uzumaki Barrage called out (U-ZU-MA-KI), his orange dash,
-- and the Nine-Tails cloak (red chakra, one tail, slit eyes). The clones'
-- bodies themselves are Client/BodyViews. One identity layer installed into
-- Effects (like SandFX and LeeFX). Presentation only.
local Debris=game:GetService("Debris")
local NarutoFX={}
local K -- Effects' helpers, handed over by install()
local Face=require(game:GetService("ReplicatedStorage").NinjaDuel.Face)
NarutoFX.clock=os.clock -- (headless tests drive time)
local NARUTO="Legion"
local SMOKE=Color3.fromRGB(240,240,244)
local CHAKRA=Color3.fromRGB(255,160,70) -- his orange
local BLUE=Color3.fromRGB(110,190,255)
local CORE=Color3.fromRGB(235,250,255)
local FOX=Color3.fromRGB(232,64,30) -- the Nine-Tails' red chakra
local FOX_CORE=Color3.fromRGB(255,176,96)
local DUST=Color3.fromRGB(206,194,168)
local function stateOf(fx,model)
	fx.narutoState=fx.narutoState or setmetatable({},{__mode="k"})
	local st=fx.narutoState[model]
	if not st then st={};fx.narutoState[model]=st end
	return st
end
local function puff(fx,at,count,size,color) K.smokePuff(fx.folder,at,color or SMOKE,count,size) end
local function sparks(fx,at,color,count,speed)
	K.burst(fx.folder,at,{Texture=K.TEX.spark,Lifetime=NumberRange.new(.15,.35),Speed=NumberRange.new(speed or 10,(speed or 10)*1.8),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(color),LightEmission=1,Size=K.num({{0,.45},{1,0}}),Drag=5},count or 10)
end
-- A word called out over the fight (the barrage's syllables).
local function call(fx,at,text,size)
	local holder=K.anchorPart(fx.folder,at)
	holder.Name="UzumakiCall"
	local gui=K.new("BillboardGui",{Size=UDim2.fromOffset(size or 110,(size or 110)*.6),AlwaysOnTop=true,LightInfluence=0},holder)
	K.new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=text,TextColor3=CHAKRA,TextStrokeTransparency=0,TextScaled=true,Font=Enum.Font.GothamBlack},gui)
	Debris:AddItem(holder,.8)
	return holder
end

-- ------------------------------------------------------------------ contacts
-- A shadow clone comes or goes: always in a puff of smoke.
local function body(fx,impact)
	if impact.kind~="clone" then return false end
	local at=impact.position
	local phase=impact.phase
	local holder=K.new("Model",{Name="ClonePuff"},fx.folder)
	if phase=="appear" then
		K.flash(holder,at,SMOKE,.6,3.2,.14,.35)
		puff(fx,at,14,2)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.3,1.4)
	elseif phase=="hit" or phase=="blade" or phase=="area" then
		-- One blow and it is gone: a bigger puff and a dry pop.
		K.flash(holder,at,SMOKE,.8,4.4,.16,.25)
		K.shockRing(holder,at,SMOKE,1,7,.22)
		puff(fx,at,22,2.6)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.hit,.35,1.6)
		fx:cheer(.4)
	elseif phase=="cloak" then
		-- The red chakra burns the clones away.
		K.flash(holder,at,FOX,.8,4,.2,.3)
		puff(fx,at,14,2.2,Color3.fromRGB(255,190,170))
	elseif phase=="transform" then
		-- The kunai was a clone all along.
		K.flash(holder,at,CHAKRA,.4,2.6,.14,.3)
		puff(fx,at,14,2)
		if fx.tumble then fx:tumble("kunai",at,Vector3.yAxis,nil) end
	else
		-- Its time is up, its strike is over, a swap, a flicker.
		puff(fx,at,12,2)
	end
	Debris:AddItem(holder,.5)
	return true
end
-- "It was a clone!": smoke where he was hit, smoke where he comes back (no log).
local function swap(fx,impact)
	puff(fx,impact.position,22,2.4)
	if impact.to then puff(fx,impact.to,8,1.4) end
	K.sound(K.anchorPart(fx.folder,impact.position),K.SOUND.whoosh,.4,1.1)
	return true
end
local function cast(fx,impact,folder)
	local model=folder and folder:FindFirstChild(impact.owner or "")
	local hand=model and model:FindFirstChild("RightHand")
	if impact.technique=="ShadowClone" or impact.technique=="MassShadowClone" then
		-- The cross seal: his chakra flares in his hands.
		if hand then sparks(fx,hand.Position,CHAKRA,if impact.technique=="MassShadowClone" then 18 else 10,8) end
		return true
	elseif impact.technique=="CloneRasengan" then
		if hand then sparks(fx,hand.Position,BLUE,10,6) end
		return true
	end
	return false
end
-- The Rasengan comes apart: the clone shaping it was struck.
local function broken(fx,impact,folder)
	local model=folder and folder:FindFirstChild(impact.owner or "")
	local hand=model and model:FindFirstChild("RightHand")
	local at=if hand then hand.Position else impact.position
	local holder=K.new("Model",{Name="RasenganBroken"},fx.folder)
	K.flash(holder,at,BLUE,1,3.6,.18,.3)
	sparks(fx,at,BLUE,16,14)
	puff(fx,at,6,1,Color3.fromRGB(200,220,240))
	Debris:AddItem(holder,.4)
	return true
end
-- The release: the sphere bursts forward with him (red in the cloak).
local function release(fx,impact,folder)
	local model=folder and folder:FindFirstChild(impact.owner or "")
	local tone=if impact.cloak then FOX else BLUE
	if model then fx:ghost(model,tone,.25,.5) end
	K.flash(fx.folder,impact.position,tone,1,4,.16,.3)
	return true
end
local function speed(fx,impact,folder)
	-- His dash: an orange afterimage and the dust his feet throw up.
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,CHAKRA,.22,.55) end
	puff(fx,impact.position-Vector3.new(0,2.6,0),10,1.5,DUST)
	K.sound(K.anchorPart(fx.folder,impact.position),K.SOUND.whoosh,.4,1.05)
	return true
end
local function awaken(fx,impact,folder)
	-- The Nine-Tails chakra boils out of him.
	local at=impact.position
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,FOX,.4,.35) end
	local burstModel=K.new("Model",{Name="FoxBurst"},fx.folder)
	K.flash(burstModel,at,FOX_CORE,2,10,.3,.1)
	K.flash(burstModel,at,FOX,4,18,.5,.35)
	Debris:AddItem(burstModel,.6)
	K.shockRing(fx.folder,at-Vector3.new(0,2.6,0),FOX,3,26,.5)
	puff(fx,at-Vector3.new(0,2.4,0),20,2.6,Color3.fromRGB(214,180,170))
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.5,.8)
	fx:cheer(1)
	return true
end
local function impact(fx,data,folder)
	local style=data.style
	if style=="body" then return body(fx,data) end
	if data.fighter~=NARUTO then return false end
	if style=="substitute" and data.mode=="clone" then return swap(fx,data) end
	if style=="cast" then return cast(fx,data,folder) end
	if style=="rasengan" then return broken(fx,data,folder) end
	if style=="burst" then return release(fx,data,folder) end
	if style=="uzumaki" then
		call(fx,data.position+Vector3.new(0,2.6,0),data.syllable or "U")
		K.shockRing(fx.folder,data.position,CHAKRA,1,8,.2)
		return true
	end
	if style=="chase" or style=="afterimage" then return speed(fx,data,folder) end
	if style=="awaken" then return awaken(fx,data,folder) end
	return false
end

-- ------------------------------------------------------------------ per frame
-- The Rasengan forming in his palm through the channel, chakra drawn in from
-- the clone at his right side; the thrust itself is Effects' sphere (red in
-- the cloak).
local function rasengan(fx,model,actor,st)
	local forming=actor.castId=="CloneRasengan" and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive") and (actor.health or 1)>0
	local hand=model:FindFirstChild("RightHand")
	local cloak=(actor.awaken or 0)>0
	if forming and hand then
		if not (st.orb and st.orb.Parent) then
			local holder=K.new("Model",{Name="RasenganForming"},fx.folder)
			local core=K.block(holder,Vector3.one*.4,hand.CFrame,CORE,Enum.Material.Neon);core.Shape=Enum.PartType.Ball
			local shell=K.block(holder,Vector3.one,hand.CFrame,BLUE,Enum.Material.Neon);shell.Shape=Enum.PartType.Ball;shell.Transparency=.5
			st.orb=holder;st.core=core;st.shell=shell;st.born=NarutoFX.clock();st.wisp=nil
		end
		local t=NarutoFX.clock()-st.born
		local grow=math.clamp(t/.45,.25,1)
		local center=hand.CFrame*CFrame.new(0,-.7,-.35)
		st.core.CFrame=center;st.core.Size=Vector3.one*.6*grow;st.core.Color=if cloak then FOX_CORE else CORE
		st.shell.CFrame=center;st.shell.Size=Vector3.one*1.5*grow*(1+math.sin(t*40)*.06);st.shell.Color=if cloak then FOX else BLUE
		local root=model:FindFirstChild("HumanoidRootPart")
		local beat=math.floor(t*30)
		if not cloak and root and beat~=st.wisp then
			st.wisp=beat
			local from=(root.CFrame*CFrame.new(1.6,.4,-.9)).Position
			local wisp=K.block(fx.folder,Vector3.new(.08,.08,1.2),CFrame.lookAt(from,center.Position),BLUE,Enum.Material.Neon)
			wisp.Name="RasenganWisp";wisp.Transparency=.3
			K.tween(wisp,.14,{CFrame=CFrame.lookAt(center.Position,center.Position+(center.Position-from)),Transparency=1,Size=Vector3.new(.03,.03,.4)})
			Debris:AddItem(wisp,.16)
		end
	elseif st.orb then
		st.orb:Destroy();st.orb=nil
	end
	local sphere=fx.rasengan and fx.rasengan[model]
	if sphere and cloak then
		sphere.core.Color=FOX_CORE;sphere.shell.Color=FOX
		for _,band in sphere.bands do band.Color=FOX_CORE end
	end
end
-- The Nine-Tails cloak: the shared mantle burns red, one tail of red chakra
-- waves behind his hips, the eyes turn red; his dash trail is his orange.
local function cloak(fx,model,actor,st)
	local aura=fx.auras and fx.auras[model]
	local open=(actor.awaken or 0)>0 and (actor.health or 1)>0
	if aura and aura.mantle and aura.foxMantle~=aura.mantle then
		aura.mantle.emitter.Color=ColorSequence.new(FOX);aura.mantle.light.Color=FOX;aura.foxMantle=aura.mantle
	end
	if aura and aura.trail and not aura.foxTrail then aura.trail.Color=ColorSequence.new(CHAKRA);aura.foxTrail=true end
	local hips=model:FindFirstChild("LowerTorso") or model:FindFirstChild("HumanoidRootPart")
	if open and hips and not (st.tail and st.tail.Parent) then
		local tail=K.new("Model",{Name="FoxTail"},fx.folder)
		local parts={}
		for k=1,4 do
			local p=K.block(tail,Vector3.one*(.8-k*.12),hips.CFrame,FOX,Enum.Material.Neon)
			p.Shape=Enum.PartType.Ball;p.Transparency=.25+k*.12
			table.insert(parts,p)
		end
		st.tail=tail;st.tailParts=parts
		st.irises={}
		for _,p in model:GetChildren() do
			if p.Name=="Iris" then table.insert(st.irises,{part=p,color=p.Color,material=p.Material});p.Color=FOX;p.Material=Enum.Material.Neon end
		end
		-- The drawn face: red slit eyes.
		st.face=st.face or Face.find(model)
		Face.tint(st.face,FOX,"fox")
	elseif not open and st.tail then
		st.tail:Destroy();st.tail=nil
		for _,iris in st.irises or {} do iris.part.Color=iris.color;iris.part.Material=iris.material end
		st.irises=nil
		if st.face then Face.tint(st.face,nil) end
	end
	if st.tail and hips then
		local t=NarutoFX.clock()
		for k,p in st.tailParts do
			p.CFrame=hips.CFrame*CFrame.new(math.sin(t*6-k*.8)*.35*k,.15+k*.35,.6+k*.55)
		end
	end
end
-- Naruto Rendan: the last syllable called as the heel comes down.
local function rendan(fx,model,actor,st)
	if actor.attackVariant~="NarutoRendan" or actor.state~="Startup" then return end
	local serial=actor.attackSerial or 0
	if st.rendan==serial then return end
	st.rendan=serial
	local root=model:FindFirstChild("HumanoidRootPart")
	if root then call(fx,root.Position+Vector3.new(0,3.4,0),"KI!",150) end
end
local function fighter(fx,model,actor,dt)
	if not model or not actor or actor.fighterId~=NARUTO then return end
	local st=stateOf(fx,model)
	rasengan(fx,model,actor,st)
	cloak(fx,model,actor,st)
	rendan(fx,model,actor,st)
end

function NarutoFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Naruto",impact=impact,fighter=fighter})
end
return NarutoFX
