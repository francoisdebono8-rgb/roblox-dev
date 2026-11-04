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
	-- The Nine-Tails chakra boils out of him (04/11, the user: "l'éveil de
	-- Naruto, c'est un peu léger"): a column of red chakra tears up out of the
	-- floor through the top of the frame, tongues of it lash out round him,
	-- the floor cracks red, two rings (the second a beat after the first) and
	-- a roar under the blast.
	local at=impact.position
	local floorY=at.Y-2.6
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,FOX,.55,.25) end
	local burstModel=K.new("Model",{Name="FoxBurst"},fx.folder)
	K.flash(burstModel,at,FOX_CORE,2,12,.32,.05)
	K.flash(burstModel,at,FOX,4,22,.55,.3)
	-- The column: an outer red shell and a hot core, rising and thinning out.
	for _,layer in {{FOX,5.2,8,.2},{FOX_CORE,2.4,3.6,.05}} do
		local col=K.block(burstModel,Vector3.new(2,layer[2],layer[2]),CFrame.new(at.X,floorY+1,at.Z)*CFrame.Angles(0,0,math.pi/2),layer[1],Enum.Material.Neon)
		col.Shape=Enum.PartType.Cylinder;col.Name="FoxPillar";col.Transparency=layer[4]
		K.tween(col,.55,{Size=Vector3.new(30,layer[3],layer[3]),CFrame=CFrame.new(at.X,floorY+15,at.Z)*CFrame.Angles(0,0,math.pi/2),Transparency=1})
	end
	-- Tongues of chakra whipped out round him, curling up.
	for k=0,7 do
		local a=k/8*math.pi*2+math.random()*.3
		local out=Vector3.new(math.cos(a),0,math.sin(a))
		local from=at+out*.8
		local tongue=K.block(burstModel,Vector3.new(.5,.5,2.6),CFrame.lookAt(from,from+out+Vector3.new(0,.3,0)),FOX,Enum.Material.Neon)
		tongue.Name="FoxTongue";tongue.Transparency=.15
		local to=at+out*(7+math.random()*2.5)+Vector3.new(0,2.5+math.random()*3,0)
		K.tween(tongue,.42,{CFrame=CFrame.lookAt(to,to+out+Vector3.new(0,1,0)),Size=Vector3.new(.12,.12,4.2),Transparency=1})
	end
	Debris:AddItem(burstModel,.8)
	-- The floor cracked red under him.
	local crack=K.new("Model",{Name="FoxCrack"},fx.folder)
	for k=0,6 do
		local a=k/7*math.pi*2+math.random()*.5
		local line=K.block(crack,Vector3.new(.16,.06,3.4+math.random()*1.6),CFrame.new(at.X,floorY+.05,at.Z)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-2.2),FOX,Enum.Material.Neon)
		line.Transparency=.1
	end
	task.delay(.6,function() for _,d in crack:GetChildren() do K.tween(d,.7,{Transparency=1}) end end)
	Debris:AddItem(crack,1.5)
	K.shockRing(fx.folder,Vector3.new(at.X,floorY,at.Z),FOX,3,28,.5)
	task.delay(.14,function() K.shockRing(fx.folder,Vector3.new(at.X,floorY+.4,at.Z),FOX_CORE,4,36,.55) end)
	puff(fx,Vector3.new(at.X,floorY+.4,at.Z),28,3,Color3.fromRGB(214,180,170))
	sparks(fx,at,FOX_CORE,26,26)
	local anchor=K.anchorPart(fx.folder,at)
	K.sound(anchor,K.SOUND.boom,.6,.7)
	K.sound(anchor,K.SOUND.heavy,.55,.5)
	Debris:AddItem(anchor,3)
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
-- The Nine-Tails cloak: the shared mantle burns red and the version-one cloak
-- covers him (04/11, "un peu léger" before: four small balls for a tail). A
-- shroud of red chakra a size up on every limb (a ForceField shell: it boils),
-- two pointed ears on the head, one long tail lashing from the hips, bubbles
-- of chakra rising off him, the eyes red; his dash trail is his orange.
local SHROUD={"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand",
	"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
local TAIL=10
local function shroud(fx,model)
	local holder=K.new("Model",{Name="FoxShroud"},fx.folder)
	local torsoShell
	for _,name in SHROUD do
		local p=model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local head=name=="Head"
			local size=if head then Vector3.one*math.max(p.Size.X,p.Size.Y,p.Size.Z)*1.3 else p.Size*1.14+Vector3.one*.12
			local s=K.block(holder,size,p.CFrame,FOX,Enum.Material.ForceField)
			if head then s.Shape=Enum.PartType.Ball end
			s.Name="FoxShell";s.Anchored=false;s.Massless=true
			K.new("WeldConstraint",{Part0=p,Part1=s},s)
			if name=="UpperTorso" then torsoShell=s end
		end
	end
	local head=model:FindFirstChild("Head")
	if head then
		local r=math.max(head.Size.X,head.Size.Y)*.5
		for _,side in {-1,1} do
			-- (a wedge's sharp corner is its top back: the ear points up and back)
			local ear=K.block(holder,Vector3.new(.18,.8,.5),head.CFrame*CFrame.new(side*r*.62,r*1.12,.1)*CFrame.Angles(math.rad(-8),0,math.rad(-side*18)),FOX,Enum.Material.Neon,"WedgePart")
			ear.Name="FoxEar";ear.Transparency=.12;ear.Anchored=false;ear.Massless=true
			K.new("WeldConstraint",{Part0=head,Part1=ear},ear)
		end
	end
	if torsoShell then
		K.new("ParticleEmitter",{Name="FoxBubbles",Texture=K.TEX.glow,Rate=36,Lifetime=NumberRange.new(.45,.85),Speed=NumberRange.new(.8,2.4),SpreadAngle=Vector2.new(180,180),
			Acceleration=Vector3.new(0,6,0),Color=ColorSequence.new(FOX_CORE,FOX),LightEmission=.8,LightInfluence=0,
			Size=K.num({{0,.2},{.4,.65},{1,0}}),Transparency=K.num({{0,.3},{1,1}})},torsoShell)
	end
	return holder
end
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
		for k=1,TAIL do
			local u=(k-1)/(TAIL-1)
			local p=K.block(tail,Vector3.one*(1.05-u*.7),hips.CFrame,if k==TAIL then FOX_CORE else FOX,Enum.Material.Neon)
			p.Shape=Enum.PartType.Ball;p.Transparency=.1+u*.35
			table.insert(parts,p)
		end
		st.tail=tail;st.tailParts=parts
		st.shroud=shroud(fx,model)
		st.irises={}
		for _,p in model:GetChildren() do
			if p.Name=="Iris" then
				table.insert(st.irises,{part=p,color=p.Color,material=p.Material})
				-- (the clones copied from him read these to start with his own eyes)
				pcall(function() p:SetAttribute("NDIrisColor",p.Color);p:SetAttribute("NDIrisMaterial",p.Material.Name) end)
				p.Color=FOX;p.Material=Enum.Material.Neon
			end
		end
		-- The drawn face: red slit eyes.
		st.face=st.face or Face.find(model)
		Face.tint(st.face,FOX,"fox")
	elseif not open and st.tail then
		st.tail:Destroy();st.tail=nil
		if st.shroud then
			-- the shroud burns off rather than vanishing
			for _,d in st.shroud:GetDescendants() do
				if d:IsA("BasePart") then K.tween(d,.3,{Transparency=1}) elseif d:IsA("ParticleEmitter") then d.Enabled=false end
			end
			st.shroud.Name="FoxShroudFading"
			Debris:AddItem(st.shroud,.6)
			st.shroud=nil
		end
		for _,iris in st.irises or {} do iris.part.Color=iris.color;iris.part.Material=iris.material end
		st.irises=nil
		if st.face then Face.tint(st.face,nil) end
		-- (Performance review 04/11) the face points back at its model: kept
		-- in the weak table, it kept the model alive after the duel.
		st.face=nil
	end
	if st.tail and hips then
		-- One long tail: thick at the hips, rising behind him, a wave running
		-- down it from the root to the tip (the tip lashes widest).
		local t=NarutoFX.clock()
		for k,p in st.tailParts do
			local u=(k-1)/(TAIL-1)
			local side=math.sin(t*5.2-k*.55)*(.15+u*1.25)
			local lift=.1+u^1.35*3.1+math.sin(t*3.1-k*.4)*.3*u
			local back=.55+u*3.0-u^2*.6
			p.CFrame=hips.CFrame*CFrame.new(side,lift,back)
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
