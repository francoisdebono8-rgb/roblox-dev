-- Rock Lee on the client (stress-test wave, DEC-015): the Fifth Gate (a green
-- chakra mantle and a flushed, burning body), his lotuses (the spin drawn
-- round the body, the crater where it lands), the crescent of the deflecting
-- kick, the Rupture's ring, and his speed (green afterimages, dust kicked up)
-- instead of the shared colours. One identity layer installed into Effects
-- (like SandFX): Effects only offers the registry and its helpers.
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")

local LeeFX={}
local K -- Effects' helpers, handed over by install()
LeeFX.clock=os.clock -- (headless tests drive time)
local LEE="Leaf"

local GATE=Color3.fromRGB(120,230,140) -- the gates' chakra
local GATE_CORE=Color3.fromRGB(226,255,226)
local FLUSH=Color3.fromRGB(226,92,72) -- the body burning in the gates
local DUST=Color3.fromRGB(206,194,168)
local LOTUS={PrimaryLotus=true,HiddenLotus=true,LeafHeel=true}

local function stateOf(fx,model)
	fx.leeState=fx.leeState or setmetatable({},{__mode="k"})
	local st=fx.leeState[model]
	if not st then st={};fx.leeState[model]=st end
	return st
end
local function ground(fx,position,fallback)
	local ok,hit=pcall(K.floorUnder,fx,position,3,12)
	return if ok and hit then hit.Position.Y else fallback
end
local function kickDust(fx,position,count,size)
	K.smokePuff(fx.folder,position,DUST,count,size)
end
-- Cracks and a ring of dust where a body was driven into the floor.
local function crater(fx,at,size)
	local y=ground(fx,at,at.Y-2.8)
	local holder=K.new("Model",{Name="LotusCrater"},fx.folder)
	local disc=K.block(holder,Vector3.new(.06,size,size),CFrame.new(at.X,y+.04,at.Z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(70,62,54),Enum.Material.Slate)
	disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.35
	for k=0,5 do
		local a=k/6*math.pi*2+math.random()*.4
		local crack=K.block(holder,Vector3.new(.08,.05,size*.45),CFrame.new(at.X,y+.06,at.Z)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-size*.3),Color3.fromRGB(40,36,32),Enum.Material.Slate)
		crack.Transparency=.2
	end
	task.delay(1.2,function() for _,d in holder:GetChildren() do K.tween(d,.6,{Transparency=1}) end end)
	Debris:AddItem(holder,2)
	K.shockRing(fx.folder,Vector3.new(at.X,y+.1,at.Z),DUST,2,size*2.2,.35)
	kickDust(fx,Vector3.new(at.X,y+.8,at.Z),22,2.4)
end

-- ------------------------------------------------------------------ contacts
local function awaken(fx,impact,folder)
	-- The Fifth Gate opens: a green burst, the floor cracked under him.
	local at=impact.position
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,GATE,.4,.35) end
	local burst=K.new("Model",{Name="GateBurst"},fx.folder)
	K.flash(burst,at,GATE_CORE,2,10,.3,.1)
	K.flash(burst,at,GATE,4,16,.45,.35)
	Debris:AddItem(burst,.6)
	crater(fx,at,7)
	K.shockRing(fx.folder,at-Vector3.new(0,2.6,0),GATE,3,26,.5)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.5,1.3)
	fx:cheer(1)
end
local function speed(fx,impact,folder)
	-- His dash and the shadow under a rising body: a green afterimage and the
	-- dust his feet tear up.
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,GATE,.2,.6) end
	kickDust(fx,impact.position-Vector3.new(0,2.6,0),10,1.5)
	K.sound(K.anchorPart(fx.folder,impact.position),K.SOUND.whoosh,.4,1.25)
end
local function rupture(fx,impact)
	-- The Rupture: a spinning kick on the spot that throws the attacker off.
	local at=impact.position
	local holder=K.new("Model",{Name="RuptureRing"},fx.folder)
	K.shockRing(holder,at-Vector3.new(0,.6,0),GATE_CORE,2,13,.25)
	K.shockRing(holder,at-Vector3.new(0,2.5,0),DUST,2,10,.3)
	Debris:AddItem(holder,.4)
	kickDust(fx,at-Vector3.new(0,2.5,0),12,1.6)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.5,.9)
end
local function windUp(fx,impact)
	-- The Leaf Great Whirlwind needs no seal: the dust spins up round his feet.
	local at=impact.position
	K.shockRing(fx.folder,at-Vector3.new(0,2.6,0),DUST,2,9,.3)
	kickDust(fx,at-Vector3.new(0,2.4,0),10,1.4)
end
local function impact(fx,data,folder)
	if data.fighter~=LEE then return false end
	local style=data.style
	if style=="awaken" then awaken(fx,data,folder);return true end
	if style=="chase" or style=="afterimage" then speed(fx,data,folder);return true end
	if style=="repel" then rupture(fx,data);return true end
	if style=="cast" and data.technique=="LeafGreatWhirlwind" then windUp(fx,data);return true end
	return false
end

-- ------------------------------------------------------------------ per frame
-- The Fifth Gate: the shared mantle burns green and the body itself burns.
-- (04/11, the user: "sur l'éveil de Lee, les poids sur sa tête, c'est moche,
-- c'est bizarre": the red ball that sat round his head is gone.) The gates show
-- on him: every skin-coloured part flushes red (given back as they close) and
-- the steam of the burning body rises off his shoulders.
local STEAM=Color3.fromRGB(232,255,234)
local function skinLike(a,b) return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)<.07 end
local function gate(fx,model,actor,st)
	local aura=fx.auras and fx.auras[model]
	local open=(actor.awaken or 0)>0 and (actor.health or 1)>0
	if aura and aura.mantle and aura.leeMantle~=aura.mantle then
		aura.mantle.emitter.Color=ColorSequence.new(GATE)
		aura.mantle.light.Color=GATE
		aura.leeMantle=aura.mantle
	end
	if aura and aura.trail and not aura.leeTrail then aura.trail.Color=ColorSequence.new(GATE);aura.leeTrail=true end
	local head=model:FindFirstChild("Head")
	if open and head and not st.flush then
		st.flush={}
		local skin=head.Color
		for _,p in model:GetDescendants() do
			if skin and p:IsA("BasePart") and p.Name~="HumanoidRootPart" and p.Color and skinLike(p.Color,skin) then
				table.insert(st.flush,{part=p,color=p.Color})
				p.Color=p.Color:Lerp(FLUSH,.45)
			end
		end
		local torso=model:FindFirstChild("UpperTorso") or head
		local at=K.new("Attachment",{Name="GateSteam",Position=Vector3.new(0,.7,0)},torso)
		K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=18,Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(1.4,3),SpreadAngle=Vector2.new(35,35),
			EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,2.5,0),Color=ColorSequence.new(STEAM),LightEmission=.25,LightInfluence=.3,
			Size=K.num({{0,.7},{1,2.4}}),Transparency=K.num({{0,.62},{.4,.7},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-45,45)},at)
		st.steam=at
	elseif not open and st.flush then
		for _,f in st.flush do if f.part.Parent then f.part.Color=f.color end end
		st.flush=nil
		if st.steam then
			local e=st.steam:FindFirstChildOfClass("ParticleEmitter")
			if e then e.Enabled=false end
			st.steam.Name="GateSteamFading"
			Debris:AddItem(st.steam,1.3)
			st.steam=nil
		end
	end
end
-- The lotuses: a spiral of chakra round the falling body, a crater where it lands.
local function lotus(fx,model,actor,st)
	local root=model:FindFirstChild("HumanoidRootPart")
	local variant=actor.attackVariant
	local falling=root and LOTUS[variant or ""] and actor.attackName=="Slam" and (actor.state=="Startup" or actor.state=="Active")
	if falling then
		st.lotus=variant
		st.spin=(st.spin or 0)+.9
		local hidden=variant=="HiddenLotus"
		for k=0,1 do
			local a=st.spin+k*math.pi
			local at=root.Position+Vector3.new(math.cos(a)*2.2,(k-.5)*1.2,math.sin(a)*2.2)
			local streak=K.block(fx.folder,Vector3.new(.18,.18,1.6),CFrame.lookAt(at,at+Vector3.new(-math.sin(a),0,math.cos(a))),if hidden then FLUSH else GATE_CORE,Enum.Material.Neon)
			streak.Name="LotusSpiral";streak.Transparency=.25
			K.tween(streak,.22,{Transparency=1,Size=Vector3.new(.04,.04,2.2)})
			Debris:AddItem(streak,.25)
		end
	elseif st.lotus and root then
		-- Landed (or cut short): the floor takes it.
		crater(fx,root.Position,if st.lotus=="HiddenLotus" then 10 else 7)
		if st.lotus=="HiddenLotus" then K.shockRing(fx.folder,root.Position-Vector3.new(0,2.5,0),FLUSH,3,20,.4) end
		st.lotus=nil
	end
end
-- The deflecting kick: a crescent of air swept across his front.
local function crescent(fx,model,actor,st)
	if actor.attackName~="DeflectKick" or actor.state~="Startup" then return end
	local serial=actor.attackSerial or 0
	if st.kick==serial then return end
	st.kick=serial
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local holder=K.new("Model",{Name="DeflectArc"},fx.folder)
	for k=-3,3 do
		local a=math.rad(k*20)
		local cf=root.CFrame*CFrame.new(0,.6,0)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-3.2)
		local piece=K.block(holder,Vector3.new(1.15,.1,.22),cf,Color3.fromRGB(236,244,255),Enum.Material.Neon)
		piece.Transparency=.35+math.abs(k)*.08
		K.tween(piece,.24,{Transparency=1})
	end
	Debris:AddItem(holder,.3)
end
local function fighter(fx,model,actor,dt)
	if not model or not actor or actor.fighterId~=LEE then return end
	local st=stateOf(fx,model)
	gate(fx,model,actor,st)
	lotus(fx,model,actor,st)
	crescent(fx,model,actor,st)
end

function LeeFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Lee",impact=impact,fighter=fighter})
end
return LeeFX
