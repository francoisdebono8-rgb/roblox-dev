-- Rock Lee on the client (stress-test wave, DEC-015): the Fifth Gate (a green
-- chakra mantle and a flushed, burning body), his lotuses (the spin drawn
-- round the body, the crater where it lands), the crescent of the deflecting
-- kick, the Rupture's ring, and his speed (green afterimages, dust kicked up)
-- instead of the shared colours. One identity layer installed into Effects
-- (like SandFX): Effects only offers the registry and its helpers.
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")

local LeeFX={}
local VfxKit=require(script.Parent.VfxKit)
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
	-- (13/11) the modelled crater: a sunk bowl, plates pushed up, cracks
	if VfxKit.mark(fx.folder,"GroundCrater",Vector3.new(at.X,y,at.Z),Vector3.yAxis,size*.75,1.6,.8) then
		K.shockRing(fx.folder,Vector3.new(at.X,y+.1,at.Z),DUST,2,size*2.2,.35)
		kickDust(fx,Vector3.new(at.X,y+.8,at.Z),22,2.4)
		return
	end
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
-- (06/11) A gate opening (Server Techniques.gateStep): a green burst off his
-- body, the floor cracking under him from the third on.
local function gateOpens(fx,impact)
	local at=impact.position
	local gate=impact.gate or 2
	K.shockRing(fx.folder,at,GATE,1.5,8+gate*3,.35)
	K.flash(fx.folder,at,GATE_CORE,.6,3+gate*.6,.2,.3)
	if gate>=3 then crater(fx,at,3+gate) end
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.25+gate*.05,1.6-gate*.08)
end
-- (13/11, user: « les poids ») Remove the Weights: the two training weights
-- come off his shins and drop like anvils (modelled: MeshKit "LegWeight"),
-- each one cratering the floor where it lands; they stay there a moment.
-- (27/11, the CM's scene « Lee's weights », INBOX-CM-SCENES: « les poids
-- visibles aux chevilles de l'avatar avant la chute ») Whoever carries Remove
-- the Weights (Lee, or an avatar who learned it) wears the two weights round
-- his lower shins, just over the ankles, from the start of the duel until he
-- drops them (the buff); they are back on him once it ends. Seen in Studio on
-- an avatar: the modelled LegWeight (dark grey, MeshKit) vanished into navy
-- trousers and its rims caught the light as spikes. François's reference
-- (27/11, 11 h 29, « rappel poids de Lee ») and the anime: a belt of pale beige
-- blocks wrapped round the shin, each block lettered 根性 (« guts ») in black.
-- François again (11 h 54, « les poids sont trop gros, ils sont fins de
-- base »): thin plates hugging the leg, not a sandbag. So that is the weight
-- drawn here: WEIGHT_BLOCKS blocks round the ankle, over
-- the widest clothing there, each with its 根性 facing out; and it is those
-- same two belts that come off and crater the floor.
LeeFX.WEIGHT_LOW=.05 -- below the shin's centre, as a share of its length
LeeFX.WEIGHT_PROUD=.1 -- studs the belt stands out of the widest clothing round the shin
LeeFX.WEIGHT_TALL=.5 -- the blocks' height, studs
LeeFX.WEIGHT_BLOCKS=8
LeeFX.WEIGHT_DEPTH=.07 -- the blocks' thickness
LeeFX.WEIGHT_BLOCK=Color3.fromRGB(228,220,192)
LeeFX.WEIGHT_EDGE=Color3.fromRGB(150,140,112)
LeeFX.WEIGHT_INK=Color3.fromRGB(20,18,16)
LeeFX.WEIGHT_WORD="根性"
local function weightPart(parent,size,cf,color,material)
	local part=Instance.new("Part")
	part.Size=size;part.CFrame=cf;part.Color=color;part.Material=material
	part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
	part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;part.CastShadow=false
	part.Parent=parent
	return part
end
-- One belt, its axis up, centred on cf, `across` studs wide.
local function buildWeight(cf,across)
	local w=Instance.new("Model");w.Name="LeeWeightWorn"
	local tall,n,depth=LeeFX.WEIGHT_TALL,LeeFX.WEIGHT_BLOCKS,LeeFX.WEIGHT_DEPTH
	local r=across/2-depth/2
	local wide=2*r*math.tan(math.pi/n)*.94
	local core=weightPart(w,Vector3.new(.1,.1,.1),cf,LeeFX.WEIGHT_EDGE,Enum.Material.SmoothPlastic)
	core.Name="Root";core.Transparency=1
	for k=0,n-1 do
		local face=cf*CFrame.Angles(0,k*math.pi*2/n,0)*CFrame.new(0,0,-r)
		-- the darker backing shows as an outline round each block
		local back=weightPart(w,Vector3.new(wide+.03,tall+.03,depth*.6),face*CFrame.new(0,0,depth*.3),LeeFX.WEIGHT_EDGE,Enum.Material.SmoothPlastic)
		back.Name="Edge"
		local block=weightPart(w,Vector3.new(wide-.02,tall-.04,depth),face,LeeFX.WEIGHT_BLOCK,Enum.Material.SmoothPlastic)
		block.Name="Block"
		local gui=Instance.new("SurfaceGui")
		gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=120
		gui.LightInfluence=1;gui.Parent=block
		local word=Instance.new("TextLabel")
		word.BackgroundTransparency=1;word.Size=UDim2.fromScale(1,1);word.Text=LeeFX.WEIGHT_WORD
		word.TextScaled=true;word.TextColor3=LeeFX.WEIGHT_INK;word.Font=Enum.Font.GothamBlack
		word.Parent=gui
		local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(.06,0);pad.PaddingRight=UDim.new(.06,0);pad.PaddingTop=UDim.new(.14,0);pad.PaddingBottom=UDim.new(.14,0);pad.Parent=word
	end
	w.PrimaryPart=core
	return w
end
local function girthAt(model,shin,at)
	-- an avatar's trouser or leg warmer is wider than the shin: the widest piece
	-- worn at that height
	local girth=math.max(shin.Size.X,shin.Size.Z)
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d~=shin and d.Transparency<1 and d.Name~="HumanoidRootPart" and not d:FindFirstAncestor("LeeWeightWorn") then
			local rel=at:PointToObjectSpace(d.Position)
			if Vector3.new(rel.X,0,rel.Z).Magnitude<.45 and math.abs(rel.Y)<d.Size.Y/2+.1 then
				girth=math.max(girth,math.min(d.Size.X,1.6),math.min(d.Size.Z,1.6))
			end
		end
	end
	return girth
end
local function dropWeights(fx,impact,folder)
	local model=folder and folder:FindFirstChild(impact.owner or "")
	local at=impact.position
	local y=ground(fx,at,at.Y-2.8)
	-- the weights he was wearing come off him (no copy appears)
	local worn={}
	if model then
		local st=stateOf(fx,model)
		if st.worn then for _,w in st.worn do if w.Parent then table.insert(worn,w) end end end
		st.worn=nil;st.dropped=os.clock()
	end
	for i,name in {"LeftLowerLeg","RightLowerLeg"} do
		local shin=model and model:FindFirstChild(name)
		local w=worn[i]
		local from=if w then w:GetPivot() elseif shin then shin.CFrame else CFrame.new(at+Vector3.new(i==1 and -.5 or .5,-1.8,0))
		if not w then
			local cf=from*CFrame.new(0,if shin then -shin.Size.Y*LeeFX.WEIGHT_LOW else 0,0)
			w=buildWeight(cf,(if shin then girthAt(model,shin,cf) else .9)+LeeFX.WEIGHT_PROUD)
			from=cf
		end
		w.Name="LeeWeight"
		local parts={}
		for _,d in w:GetDescendants() do
			if d:IsA("WeldConstraint") then d:Destroy() end
			if d:IsA("BasePart") then d.Anchored=true;table.insert(parts,{part=d,offset=from:ToObjectSpace(d.CFrame)}) end
		end
		w.Parent=fx.folder
		local land=Vector3.new(from.Position.X+(i==1 and -.35 or .35),y+.36,from.Position.Z+.2)
		local rest=CFrame.new(land)*CFrame.Angles(math.rad(90),math.rad(i*37),0)
		-- it drops like lead: straight down, accelerating, onto its side
		local start=os.clock()
		local conn
		conn=game:GetService("RunService").Heartbeat:Connect(function()
			local t=math.min(1,(os.clock()-start)/.3)
			local e=t*t
			local cf=from:Lerp(rest,e)
			for _,p in parts do if p.part.Parent then p.part.CFrame=cf*p.offset end end
			if t>=1 or not w.Parent then conn:Disconnect() end
		end)
		task.delay(2.6,function()
			if not w.Parent then return end
			for _,p in parts do if p.part.Name~="Root" then K.tween(p.part,.5,{Transparency=1}) end end
			for _,d in w:GetDescendants() do if d:IsA("TextLabel") then K.tween(d,.5,{TextTransparency=1}) end end
		end)
		Debris:AddItem(w,3.2)
		task.delay(.3,function()
			if not VfxKit.mark(fx.folder,"GroundCrater",Vector3.new(land.X,y,land.Z),Vector3.yAxis,1.9,2.4,.6) then crater(fx,land,2.2) end
			kickDust(fx,Vector3.new(land.X,y+.5,land.Z),12,1.6)
			K.shockRing(fx.folder,Vector3.new(land.X,y+.1,land.Z),DUST,1.5,7,.3)
			K.sound(K.anchorPart(fx.folder,land),K.SOUND.boom,.45,1.5)
		end)
	end
end
local function carriesWeights(actor)
	for _,t in actor.techniques or {} do if t.id=="RemoveWeights" then return true end end
	return false
end
local function wearWeights(fx,model,actor,st)
	local on=carriesWeights(actor) and not (actor.family and actor.family.buff=="RemoveWeights") and (actor.health or 1)>0
	-- the dropped pair lies on the floor a moment before he can wear them again
	if on and st.dropped and os.clock()-st.dropped<1.2 then on=false end
	if not on then
		if st.worn then for _,w in st.worn do if w.Parent then w:Destroy() end end;st.worn=nil end
		return
	end
	if st.worn then
		local ok=true
		for _,w in st.worn do if not w.Parent then ok=false end end
		if ok then return end
		for _,w in st.worn do if w.Parent then w:Destroy() end end
	end
	local worn={}
	-- one size for the pair: the wider of the two ankles
	local across=0
	for _,name in {"LeftLowerLeg","RightLowerLeg"} do
		local shin=model:FindFirstChild(name)
		if shin then across=math.max(across,girthAt(model,shin,shin.CFrame*CFrame.new(0,-shin.Size.Y*LeeFX.WEIGHT_LOW,0))) end
	end
	for _,name in {"LeftLowerLeg","RightLowerLeg"} do
		local shin=model:FindFirstChild(name)
		if shin then
			local at=shin.CFrame*CFrame.new(0,-shin.Size.Y*LeeFX.WEIGHT_LOW,0)
			local w=buildWeight(at,across+LeeFX.WEIGHT_PROUD)
			for _,d in w:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored=false
					local weld=Instance.new("WeldConstraint");weld.Part0=shin;weld.Part1=d;weld.Parent=d
				end
			end
			w.Parent=model
			table.insert(worn,w)
		end
	end
	st.worn=worn
end
LeeFX.carriesWeights=carriesWeights
local function impact(fx,data,folder)
	-- the weights fall off whoever wore them (an avatar with Lee's technique too)
	if data.style=="cast" and data.technique=="RemoveWeights" then dropWeights(fx,data,folder);return true end
	if data.fighter~=LEE then return false end
	local style=data.style
	if style=="awaken" then awaken(fx,data,folder);return true end
	if style=="gate" then gateOpens(fx,data);return true end
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
	-- (06/11) the flush and the steam grow with the gate that is open.
	local gateNow=if open then (actor.gate or 1) else 0
	if open and st.flush and st.gate~=gateNow then
		st.gate=gateNow
		for _,p in st.flush do if p.Parent then K.tintLayer(p,"flush",math.min(.85,.3+gateNow*.11)) end end
		local e=st.steam and st.steam:FindFirstChildOfClass("ParticleEmitter")
		if e then e.Rate=10+gateNow*8 end
	end
	if open and head and not st.flush then
		-- (the original colours come from Effects' one record, shared with the
		-- battle wear: each layer adds itself, nothing is restored blindly)
		st.flush={}
		local skin=head.Color and K.baseColor(head)
		for _,p in model:GetDescendants() do
			if skin and p:IsA("BasePart") and p.Name~="HumanoidRootPart" and p.Color and skinLike(K.baseColor(p),skin) then
				table.insert(st.flush,p)
				K.tintLayer(p,"flush",math.min(.85,.3+(actor.gate or 1)*.11))
			end
		end
		local torso=model:FindFirstChild("UpperTorso") or head
		local at=K.new("Attachment",{Name="GateSteam",Position=Vector3.new(0,.7,0)},torso)
		K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=18,Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(1.4,3),SpreadAngle=Vector2.new(35,35),
			EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,2.5,0),Color=ColorSequence.new(STEAM),LightEmission=.25,LightInfluence=.3,
			Size=K.num({{0,.7},{1,2.4}}),Transparency=K.num({{0,.62},{.4,.7},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-45,45)},at)
		st.steam=at;st.gate=nil
	elseif not open and st.flush then
		for _,p in st.flush do if p.Parent then K.tintLayer(p,"flush",nil) end end
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
	if not model or not actor then return end
	-- the weights: on whoever carries them, Lee or not
	pcall(wearWeights,fx,model,actor,stateOf(fx,model))
	if actor.fighterId~=LEE then return end
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
