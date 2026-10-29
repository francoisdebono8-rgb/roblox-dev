-- Client-side combat VFX. Everything here is presentation driven by the server
-- snapshot and contact feed: real 3D kunai and shuriken flying on the exact
-- server path, planted Flying Thunder God seals, the Katon fireball, teleport
-- flashes, substitution logs, Itachi's crows, Rasengan and burning ground.
-- Nothing in this module can change gameplay.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Kit=require(script.Parent.VfxKit)
local FX={};FX.__index=FX
-- Cel flame streams of the fireballs in flight (VfxKit), by model.
FX.fireStreams=setmetatable({},{__mode="k"})
-- Identity layers: a fighter whose look lives in its own module (SandFX)
-- registers projectile builders and poses, contact styles and a per-frame step.
FX.layers={}
FX.poses={}

local TEX={
	fire="rbxasset://textures/particles/fire_main.dds",
	smoke="rbxasset://textures/particles/smoke_main.dds",
	spark="rbxasset://textures/particles/sparkles_main.dds",
	fireSpark="rbxasset://textures/particles/fire_sparks_main.dds",
	core="rbxasset://textures/particles/explosion01_core_main.dds",
	shock="rbxasset://textures/particles/explosion01_shockwave_main.dds",
	glow="rbxasset://textures/particles/forcefield_glow_main.dds",
	vortex="rbxasset://textures/particles/forcefield_vortex_main.dds",
}
local SOUND={
	whoosh="rbxassetid://5835032207",
	hit="rbxassetid://8595980577",
	heavy="rbxassetid://9117969717",
	boom="rbxasset://sounds/impact_explosion_03.mp3",
	land="rbxasset://sounds/action_jump_land.mp3",
	jump="rbxasset://sounds/action_jump.mp3",
	getUp="rbxasset://sounds/action_get_up.mp3",
	-- (Reference quality) Roblox's licensed Pro Sound Effects library.
	electric={"rbxassetid://9116279560","rbxassetid://9116276961","rbxassetid://9116275998"},
	swish="rbxassetid://9126284094",
	whooshBy="rbxassetid://9120711172",
	punch="rbxassetid://9117971636",
	body="rbxassetid://9113524242",
	bodyfall="rbxassetid://9113482032",
	debris="rbxassetid://9114221862",
}
FX.SOUND=SOUND
-- Contacts that bring the crowd to its feet, by strength.
local CHEER={chidori=1,groundbounce=.8,slam=1,launcher=.7,finisher=.8,fire=1,teleport=.9,parry=.8,substitute=.4,burst=.8,clash=.9,wall=.6,wallbounce=1,worldbreak=1,walltech=.5,repel=.9,trigram=.7}
local HYUGA=Color3.fromRGB(190,208,255)
-- Visual time runs a hair behind the server clock, like the bodies, so a blade
-- leaves the throwing hand on the frame the arm releases it.
FX.DELAY=.06
local STEEL=Color3.fromRGB(64,68,76)
local STEEL_EDGE=Color3.fromRGB(150,158,170)
local MINATO=Color3.fromRGB(255,214,92)
local LION=Color3.fromRGB(150,180,255)
local CURSE=Color3.fromRGB(120,60,200)
local MINATO_CORE=Color3.fromRGB(255,248,214)
local SHARINGAN=Color3.fromRGB(230,36,44)
local WIND=Color3.fromRGB(190,255,226)

local function new(class,props,parent)
	local x=Instance.new(class)
	for k,v in props do x[k]=v end
	if parent then x.Parent=parent end
	return x
end
local function block(parent,size,cf,color,material,class)
	local p=new(class or "Part",{Size=size,CFrame=cf,Color=color,Material=material or Enum.Material.SmoothPlastic,
		Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,
		TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},parent)
	return p
end
local function tween(object,time,goal,style,direction)
	local t=TweenService:Create(object,TweenInfo.new(time,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),goal)
	t:Play();return t
end
local function sound(parent,id,volume,speed,cut)
	if type(id)=="table" then id=id[math.random(1,#id)] end
	local s=new("Sound",{SoundId=id,Volume=volume or .4,PlaybackSpeed=speed or 1,RollOffMaxDistance=160,RollOffMinDistance=12},parent)
	s:Play();Debris:AddItem(s,3)
	-- A long take (debris, a body fall) is cut short with a fade.
	if cut then task.delay(cut,function() if s.Parent then tween(s,.35,{Volume=0}) end end) end
	-- A bare anchor made for this sound goes with it.
	if parent.Name=="SoundAnchor" then Debris:AddItem(parent,3) end
	return s
end
local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,ColorSequenceKeypoint.new(p[1],p[2])) end
	return ColorSequence.new(keys)
end
local function num(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function emitter(parent,props)
	local e=new("ParticleEmitter",{Enabled=false,LightInfluence=0,ZOffset=.5},parent)
	for k,v in props do e[k]=v end
	return e
end
-- An invisible point to hang a sound, light or emitter on (it used to be a
-- visible black cube left behind at every contact for the rest of the duel).
local function anchorPart(parent,position)
	local p=block(parent,Vector3.new(.2,.2,.2),CFrame.new(position),Color3.new(),Enum.Material.SmoothPlastic)
	p.Name="SoundAnchor";p.Transparency=1
	return p
end
-- Weld every piece of a model to its (anchored) root so one CFrame write moves
-- the whole object.
local function weldAll(root,parts)
	for _,p in parts do
		if p~=root then
			p.Anchored=false;p.Massless=true
			local w=new("WeldConstraint",{Part0=root,Part1=p},root)
			w.Name="Hold"
		end
	end
end
-- One half of a tapered leaf. Wedge local Y is the width axis (full at the back,
-- zero at the front edge), X the thickness. `tip` = -1 puts the point towards
-- -Z, +1 towards +Z; `side` picks the half.
local function taper(parent,center,width,length,thick,side,tip,color,material)
	local rot=CFrame.Angles(0,0,-side*math.pi/2)
	if tip>0 then rot=rot*CFrame.Angles(0,math.pi,0) end
	local cf=center*CFrame.new(side*width*.25,0,0)*rot
	return block(parent,Vector3.new(thick,width*.5,length),cf,color,material or Enum.Material.Metal,"WedgePart")
end
local function leaf(parent,center,width,front,back,thick,color,material)
	local list={}
	for _,side in {-1,1} do
		table.insert(list,taper(parent,center*CFrame.new(0,0,-front*.5),width,front,thick,side,-1,color,material))
		table.insert(list,taper(parent,center*CFrame.new(0,0,back*.5),width,back,thick,side,1,color,material))
	end
	return list
end
local function ring(parent,center,radius,count,size,color,material)
	local list={}
	for i=0,count-1 do
		local a=i/count*math.pi*2
		local cf=center*CFrame.Angles(a,0,0)*CFrame.new(0,radius,0)
		table.insert(list,block(parent,Vector3.new(size,size*.9,radius*2*math.pi/count*1.15),cf,color,material or Enum.Material.Metal))
	end
	return list
end

-- ------------------------------------------------------------------ models
-- Kunai built along -Z (point first). The grip centre is the origin, so the
-- same model sits correctly in a hand and flies point-first.
function FX.buildKunai(marked)
	local model=new("Model",{Name=if marked then "MarkedKunai" else "Kunai"})
	local root=block(model,Vector3.new(.1,.1,.1),CFrame.new(),Color3.new(),nil);root.Name="Root";root.Transparency=1
	local parts={}
	local handle=block(model,Vector3.new(.62,.12,.12),CFrame.new(0,0,.1)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(36,34,38),Enum.Material.Fabric)
	handle.Shape=Enum.PartType.Cylinder;table.insert(parts,handle)
	for i=-1,1 do
		local band=block(model,Vector3.new(.045,.145,.145),CFrame.new(0,0,.1+i*.19)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(122,108,88),Enum.Material.Fabric)
		band.Shape=Enum.PartType.Cylinder;table.insert(parts,band)
	end
	for _,p in ring(model,CFrame.new(0,0,.55),.13,8,.05,STEEL) do table.insert(parts,p) end
	local guard=block(model,Vector3.new(.22,.06,.08),CFrame.new(0,0,-.22),STEEL,Enum.Material.Metal);table.insert(parts,guard)
	-- Leaf blade: widest a third of the way up, long point.
	for _,p in leaf(model,CFrame.new(0,0,-.46),.34,.66,.22,.05,STEEL) do table.insert(parts,p) end
	-- Bright edge along the centre line so the blade reads at combat speed.
	table.insert(parts,block(model,Vector3.new(.02,.055,.82),CFrame.new(0,0,-.5),STEEL_EDGE,Enum.Material.Metal))
	if marked then
		-- Minato's three-pronged kunai: two swept side prongs, and the sealing
		-- formula tag wrapped on the grip.
		for _,side in {-1,1} do
			local base=CFrame.new(side*.12,0,-.3)*CFrame.Angles(0,side*math.rad(28),0)
			for _,p in leaf(model,base*CFrame.new(0,0,-.08),.14,.3,.06,.04,STEEL) do table.insert(parts,p) end
		end
		local tag=block(model,Vector3.new(.2,.02,.42),CFrame.new(0,.075,.12),Color3.fromRGB(236,226,196),Enum.Material.SmoothPlastic)
		tag.Name="SealTag";table.insert(parts,tag)
		for i=-1,1 do
			table.insert(parts,block(model,Vector3.new(.012,.024,.3-math.abs(i)*.08),CFrame.new(i*.05,.088,.12),Color3.fromRGB(30,32,40),Enum.Material.SmoothPlastic))
		end
	end
	weldAll(root,parts)
	model.PrimaryPart=root
	return model
end
-- Four-point shuriken, flat in the XZ plane, spun about its own Y axis.
function FX.buildShuriken()
	local model=new("Model",{Name="Shuriken"})
	local root=block(model,Vector3.new(.1,.1,.1),CFrame.new(),Color3.new());root.Name="Root";root.Transparency=1
	local parts={}
	local disc=block(model,Vector3.new(.07,.46,.46),CFrame.Angles(0,0,math.pi/2),STEEL,Enum.Material.Metal)
	disc.Shape=Enum.PartType.Cylinder;table.insert(parts,disc)
	local hole=block(model,Vector3.new(.08,.13,.13),CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(18,18,22),Enum.Material.SmoothPlastic)
	hole.Shape=Enum.PartType.Cylinder;table.insert(parts,hole)
	for i=0,3 do
		local base=CFrame.Angles(0,i*math.pi/2,0)*CFrame.new(0,0,-.3)
		for _,p in leaf(model,base*CFrame.new(0,0,-.05),.2,.42,.1,.04,STEEL) do table.insert(parts,p) end
		table.insert(parts,block(model,Vector3.new(.015,.05,.38),base*CFrame.new(0,0,-.22),STEEL_EDGE,Enum.Material.Metal))
	end
	weldAll(root,parts)
	model.PrimaryPart=root
	return model
end
-- Per-fighter dash streak (movement overhaul, brief §12): Lee a short, wide
-- physical burst; Itachi barely a trace; Shisui a long faint false continuation;
-- Gaara a slow sand glide; Haku a thin ice line; Zabuza a heavy grey wake;
-- Nagato a short, controlled one. Unlisted fighters keep the default.
local DASH_STREAK={
	Leaf={color=Color3.fromRGB(70,170,80),life=.1,alpha=.5,width=1.25},
	Mirage={color=Color3.fromRGB(150,20,30),life=.06,alpha=.78,width=.7},
	Flicker={color=Color3.fromRGB(110,200,150),life=.24,alpha=.72,width=.9},
	Sand={color=Color3.fromRGB(205,175,115),life=.22,alpha=.55,width=1.35},
	Mirror={color=Color3.fromRGB(190,230,255),life=.18,alpha=.6,width=.75},
	Mist={color=Color3.fromRGB(150,160,175),life=.13,alpha=.5,width=1.45},
	Rinnegan={color=Color3.fromRGB(150,120,200),life=.09,alpha=.7,width=.8},
}
local function addTrail(root,a,b,color,lifetime,transparency,width)
	local a0=new("Attachment",{Position=a},root)
	local a1=new("Attachment",{Position=b},root)
	return new("Trail",{Attachment0=a0,Attachment1=a1,Color=ColorSequence.new(color),LightEmission=.7,
		Transparency=num({{0,transparency or .35},{1,1}}),Lifetime=lifetime or .12,FaceCamera=true,WidthScale=num({{0,width or 1},{1,.2}})},root)
end
-- Each caster's Katon has its own fire (user 28/10 "les animations de Katon,
-- c'est toutes les mêmes"). Sasuke: a tight, white-hot sphere that rolls
-- fast. Itachi: a deep crimson mass, heavier smoke, slow roll, a long tail.
local FIRE_LOOK={
	default={core=Color3.fromRGB(255,240,180),mid=Color3.fromRGB(255,150,40),outer=Color3.fromRGB(230,70,20),
		ramp={Color3.fromRGB(255,240,170),Color3.fromRGB(255,140,40),Color3.fromRGB(200,50,20),Color3.fromRGB(60,20,10)},smoke=26,smokeColor=Color3.fromRGB(60,48,44),roll=3,flames=140,embers=40,light=Color3.fromRGB(255,140,60)},
	Lion={core=Color3.fromRGB(255,252,225),mid=Color3.fromRGB(255,196,70),outer=Color3.fromRGB(255,112,24),
		ramp={Color3.fromRGB(255,250,210),Color3.fromRGB(255,180,50),Color3.fromRGB(235,80,20),Color3.fromRGB(70,26,10)},smoke=14,smokeColor=Color3.fromRGB(70,56,48),roll=7,flames=170,embers=60,light=Color3.fromRGB(255,176,80)},
	Mirage={core=Color3.fromRGB(255,214,150),mid=Color3.fromRGB(236,92,28),outer=Color3.fromRGB(160,22,14),
		ramp={Color3.fromRGB(255,214,140),Color3.fromRGB(230,80,24),Color3.fromRGB(150,24,14),Color3.fromRGB(34,12,10)},smoke=44,smokeColor=Color3.fromRGB(38,30,30),roll=1.6,flames=120,embers=24,light=Color3.fromRGB(235,80,40),tail=true},
}
FX.FIRE_LOOK=FIRE_LOOK
FX.fireRoll=setmetatable({},{__mode="k"})
function FX.buildFireball(caster)
	local look=FIRE_LOOK[caster or ""] or FIRE_LOOK.default
	local model=new("Model",{Name="GreatFireball"})
	FX.fireRoll[model]=look.roll
	local root=block(model,Vector3.new(1,1,1),CFrame.new(),look.core,Enum.Material.Neon);root.Name="Root"
	root.Shape=Enum.PartType.Ball;root.Transparency=.05
	local mid=block(model,Vector3.new(1,1,1),CFrame.new(),look.mid,Enum.Material.Neon);mid.Shape=Enum.PartType.Ball;mid.Transparency=.35;mid.Name="Mid"
	local outer=block(model,Vector3.new(1,1,1),CFrame.new(),look.outer,Enum.Material.Neon);outer.Shape=Enum.PartType.Ball;outer.Transparency=.62;outer.Name="Outer"
	weldAll(root,{mid,outer})
	local at=new("Attachment",{},root)
	if look.tail then
		-- Itachi's mass drags a long fire tail behind it.
		addTrail(root,Vector3.new(0,1.6,0),Vector3.new(0,-1.6,0),look.outer,.5,.3,3)
	end
	local flames=emitter(at,{Name="Flames",Enabled=true,Texture=TEX.fire,Rate=look.flames,Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(2,7),SpreadAngle=Vector2.new(180,180),
		Color=seq({{0,look.ramp[1]},{.35,look.ramp[2]},{.75,look.ramp[3]},{1,look.ramp[4]}}),
		LightEmission=1,Size=num({{0,3},{.4,5},{1,1.5}}),Transparency=num({{0,.15},{.7,.4},{1,1}}),Drag=3,RotSpeed=NumberRange.new(-120,120),Rotation=NumberRange.new(0,360),ZOffset=1})
	if Kit.has("fire") then
		-- (Reference quality) cel flames: our own flipbook, colours baked in,
		-- left behind along the flight as it burns.
		flames.Rate=40
		FX.fireStreams[model]=Kit.stream(at,"fire",{Rate=55,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(1,4),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(Color3.new(1,1,1)),LightEmission=.25,Size=num({{0,3},{.5,5},{1,4}}),Transparency=num({{0,0},{.85,0},{1,1}}),
			Drag=3,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)})
	end
	emitter(at,{Name="Smoke",Enabled=true,Texture=TEX.smoke,Rate=look.smoke,Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(look.smokeColor),LightEmission=0,Size=num({{0,3},{1,8}}),Transparency=num({{0,.55},{1,1}}),Drag=2})
	emitter(at,{Name="Embers",Enabled=true,Texture=TEX.fireSpark,Rate=look.embers,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(Color3.fromRGB(255,190,90)),LightEmission=1,Size=num({{0,.35},{1,0}}),Acceleration=Vector3.new(0,6,0)})
	new("PointLight",{Color=look.light,Brightness=4,Range=28,Shadows=false},root)
	model.PrimaryPart=root
	return model
end
function FX.buildWind()
	local model=new("Model",{Name="WindBlade"})
	local root=block(model,Vector3.new(.1,.1,.1),CFrame.new(),Color3.new());root.Name="Root";root.Transparency=1
	local parts={}
	for i=-3,3 do
		local a=i*math.rad(16)
		local p=block(model,Vector3.new(1.3,.06,.35),CFrame.Angles(0,a,0)*CFrame.new(0,0,-1.6+math.abs(i)*.18),Color3.fromRGB(200,255,232),Enum.Material.Neon)
		p.Transparency=.35+math.abs(i)*.08;table.insert(parts,p)
	end
	weldAll(root,parts)
	addTrail(root,Vector3.new(-2.2,0,0),Vector3.new(2.2,0,0),Color3.fromRGB(190,255,226),.16,.55,1)
	model.PrimaryPart=root
	return model
end

-- ------------------------------------------------------------------ state
function FX.new()
	local folder=Instance.new("Folder");folder.Name="NinjaDuelFX";folder.Parent=workspace
	-- Decode the VFX textures now, before the first contact needs them.
	if task and task.defer then task.defer(function() pcall(Kit.warm) end) end
	-- (Reference quality) the world's marks (Server/WorldReaction scars) are
	-- drawn with our scorch and crack art instead of flat dark discs.
	if workspace.DescendantAdded then
		workspace.DescendantAdded:Connect(function(part) pcall(FX.dressScar,part) end)
	end
	return setmetatable({folder=folder,projectiles={},stuck={},seals={},hazards={},auras={},rasengan={},epoch=nil,
		clock=0,cache={}},FX)
end
function FX:reset()
	self.folder:ClearAllChildren()
	table.clear(self.projectiles);table.clear(self.stuck);table.clear(self.seals);table.clear(self.hazards);table.clear(self.rasengan)
	for _,aura in self.auras do if aura.trail then aura.trail.Enabled=false end end
end
local function serverNow() return workspace:GetServerTimeNow() end
function FX:visualTime() return serverNow()-FX.DELAY end
local BUILD={kunai=function() return FX.buildKunai(false) end,marked=function() return FX.buildKunai(true) end,wire=function() return FX.buildShuriken() end,
	shuriken=FX.buildShuriken,fireball=function(p) return FX.buildFireball(p and p.caster) end,wind=FX.buildWind,
	-- Vacuum Palm: a pale ring of compressed air (sized by the flight radius).
	palm=function()
		local model=new("Model",{Name="VacuumPalm"})
		local root=block(model,Vector3.new(.1,.1,.1),CFrame.new(),Color3.new());root.Name="Root";root.Transparency=1
		local ring=block(model,Vector3.new(.3,3,3),CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(214,228,255),Enum.Material.Neon);ring.Name="Ring"
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.62
		local core=block(model,Vector3.new(.2,1.6,1.6),CFrame.Angles(0,math.pi/2,0)*CFrame.new(-.4,0,0),Color3.fromRGB(240,246,255),Enum.Material.Neon);core.Name="Core"
		core.Shape=Enum.PartType.Cylinder;core.Transparency=.45
		weldAll(root,{ring,core})
		addTrail(root,Vector3.new(0,1.2,0),Vector3.new(0,-1.2,0),Color3.fromRGB(206,222,255),.12,.6,1)
		model.PrimaryPart=root
		return model
	end,
	-- Phoenix Flower: the same fire build, shrunk and dimmer.
	phoenix=function(p)
		local model=FX.buildFireball(p and p.caster)
		local light=model.PrimaryPart:FindFirstChildOfClass("PointLight");if light then light.Range=12;light.Brightness=2.5 end
		local at=model.PrimaryPart:FindFirstChildOfClass("Attachment")
		local smoke=at and at:FindFirstChild("Smoke");if smoke then smoke.Rate=8 end
		local flames=at and at:FindFirstChild("Flames");if flames then flames.Rate=60 end
		return model
	end}
-- Snapshot sync: create visuals for newly announced projectiles, mark the ones
-- the server no longer reports.
function FX:sync(data)
	if data.epoch~=self.epoch then self.epoch=data.epoch;self:reset() end
	-- The two fighters' model names in this duel (online they are not the AI names).
	if data.human and data.bot then self.fighterIds={data.human.id,data.bot.id} end
	local live={}
	for _,p in data.projectiles or {} do
		live[p.id]=true
		local entry=self.projectiles[p.id]
		if not entry and p.planted then
			-- A chakra blade planted in a surface, or a stretched wire: drawn once
			-- where it rests (ChakraCombat points); an unknown kind is skipped.
			local ok,built=pcall(self.planted,self,p)
			if ok and built then self.projectiles[p.id]=built end
			entry=self.projectiles[p.id]
			if not entry then continue end
		elseif not entry then
			local build=BUILD[p.kind] or BUILD.kunai
			local model=build(p)
			model.Parent=self.folder
			local root=model.PrimaryPart
			-- Chakra infusion: the object itself looks reinforced / windy / burning /
			-- charged (decorations only; the flight is the server's).
			local decor=p.infusion and select(2,pcall(self.infuse,self,model,root,p.infusion,p.kind))
			if p.infusion then
				-- the infusion owns the trail
			elseif p.kind=="kunai" or p.kind=="marked" then
				addTrail(root,Vector3.new(0,.06,.2),Vector3.new(0,-.06,.2),if p.kind=="marked" then MINATO else Color3.fromRGB(220,226,236),.1,.5,1)
			elseif p.kind=="shuriken" or p.kind=="wire" then
				addTrail(root,Vector3.new(-.35,0,0),Vector3.new(.35,0,0),Color3.fromRGB(226,232,240),.08,.6,1)
			end
			if p.kind=="wire" then
				-- Ninja wire: a thin line from the thrower's hand to the blade.
				local owner=self.fighters and self.fighters:FindFirstChild(p.owner or "")
				local hand=owner and owner:FindFirstChild("RightHand")
				if hand then
					local a0=new("Attachment",{Name="WireStart"},hand)
					local a1=new("Attachment",{Name="WireEnd"},root)
					new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.06,Width1=.06,Color=ColorSequence.new(Color3.fromRGB(210,214,220)),LightEmission=.3,FaceCamera=true,Segments=2},root)
					Debris:AddItem(a0,1.2)
				end
			end
			entry={data=p,model=model,root=root,spin=math.random()*math.pi*2,hidden=true,decor=if type(decor)=="table" then decor else nil}
			self.projectiles[p.id]=entry
			for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end end
			if p.kind=="fireball" then
				local owner=self.fighters and self.fighters:FindFirstChild(p.owner or "")
				local head=owner and owner:FindFirstChild("Head")
				if head then
					local look=FIRE_LOOK[p.caster or ""] or FIRE_LOOK.default
					local a0=new("Attachment",{Name="Breath",Position=Vector3.new(0,-.25,-.55)},head)
					local a1=new("Attachment",{Name="BreathEnd"},root)
					entry.breath={beam=new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.5,Width1=(p.radius or 2.4)*1.6,Texture=TEX.fire,TextureSpeed=4,TextureLength=3,
						Color=seq({{0,look.ramp[1]},{.5,look.ramp[2]},{1,look.ramp[3]}}),LightEmission=1,FaceCamera=true,Segments=8,
						Transparency=num({{0,.2},{1,.35}})},root),a0=a0}
					Debris:AddItem(a0,1)
				end
				sound(root,SOUND.boom,.35,.55)
			elseif p.kind=="phoenix" then
				sound(root,SOUND.whoosh,.25,.7)
			elseif p.kind=="palm" then
				sound(root,SOUND.whoosh,.45,.6)
			elseif p.kind=="kunai" or p.kind=="marked" or p.kind=="shuriken" or p.kind=="wire" then
				sound(root,SOUND.whoosh,.28,if p.kind=="shuriken" then 1.5 else 1.25)
			end
		elseif not p.planted and entry.data.born~=p.born then
			-- Re-based in the air (Combat:redirect: a wind lane turned it aside or
			-- sped it up): the old leg is drawn until the visual clock reaches the
			-- new one, so the flight bends where it bent instead of vanishing and
			-- jumping ahead.
			entry.previous=entry.data
		end
		entry.data=p;entry.missingSince=nil
	end
	for id,entry in self.projectiles do
		if not live[id] and not entry.missingSince then entry.missingSince=os.clock() end
	end
end
function FX:finishProjectile(id)
	local entry=self.projectiles[id]
	if not entry then return nil end
	self.projectiles[id]=nil
	local root=entry.root
	Kit.stop(FX.fireStreams[entry.model])
	-- Let a trail finish fading instead of cutting it.
	for _,d in entry.model:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency=1 elseif d:IsA("ParticleEmitter") or d:IsA("Beam") then d.Enabled=false elseif d:IsA("PointLight") then d.Enabled=false end
	end
	Debris:AddItem(entry.model,.6)
	return entry,root
end
function FX:stepProjectiles(dt)
	local t=self:visualTime()
	for id,entry in self.projectiles do
		local p=entry.data
		if entry.previous then
			if t<p.born then p=entry.previous else entry.previous=nil end
		end
		local age=t-p.born
		if entry.missingSince and os.clock()-entry.missingSince>.35 then
			self:finishProjectile(id)
			continue
		end
		if entry.static then
			pcall(self.restStep,self,entry)
			continue
		end
		-- Combat convergence (Studio, 60 fps probe): the held kunai vanished one
		-- frame before the thrown one appeared, and that one appeared ~2 studs
		-- ahead of the hand and 1.5 lower (the server origin). A thrown object
		-- now shows from the frame the hand lets go and leaves from the hand,
		-- easing onto the server flight in its first tenth of a second.
		local thrown=p.kind=="kunai" or p.kind=="marked" or p.kind=="shuriken" or p.kind=="wire"
		local hidden=age<(if thrown then -1/30 else 0)
		if thrown and not hidden and not entry.release then
			local owner=self.fighters and self.fighters:FindFirstChild(p.owner or "")
			local hand=owner and (owner:FindFirstChild(if p.kind=="shuriken" then "LeftHand" else "RightHand") or owner:FindFirstChild("RightHand"))
			entry.release=if hand then hand.Position else false
		end
		if hidden~=entry.hidden then
			entry.hidden=hidden
			for _,d in entry.model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=if hidden then 1 else 0 end end
			if entry.decor then for _,e in entry.decor.emitters do e.Enabled=not hidden end end
			local stream=FX.fireStreams[entry.model]
			if stream then stream.Enabled=not hidden end
		end
		if entry.breath then
			-- The breath thins and goes out over its first third of a second.
			local u=math.clamp(age/.35,0,1)
			if u>=1 then entry.breath.beam:Destroy();entry.breath.a0:Destroy();entry.breath=nil
			else entry.breath.beam.Transparency=num({{0,.2+.8*u},{1,.35+.65*u}}) end
		end
		if entry.decor and entry.decor.light then
			local look=entry.decor.look
			entry.decor.light.Brightness=if look.spark then look.light*(.4+math.random()*1.2) else look.light*(.85+math.sin(os.clock()*18)*.15)
		end
		local travel=if (p.speed or 0)<=0 then 0 else math.clamp(age,0,p.range/p.speed)*p.speed
		local position=p.origin+p.direction*travel
		if entry.release and age<.1 then
			local u=math.clamp((age+1/30)/(.1+1/30),0,1)
			position=entry.release:Lerp(position,u*u*(3-2*u))
		end
		local look=CFrame.lookAt(position,position+p.direction)
		local cf
		if entry.decor and entry.decor.ring then
			entry.decor.ring.CFrame=look*CFrame.Angles(0,0,os.clock()*20)*CFrame.Angles(0,math.pi/2,0)
		end
		if p.kind=="kunai" or p.kind=="marked" then
			-- Point first, with a slow roll so the blade catches the light.
			entry.spin+=dt*14
			cf=look*CFrame.Angles(0,0,entry.spin)
		elseif p.kind=="shuriken" or p.kind=="wire" then
			entry.spin+=dt*42
			cf=look*CFrame.Angles(0,entry.spin,0)*CFrame.Angles(0,0,math.rad(8))
		elseif p.kind=="fireball" or p.kind=="phoenix" then
			local radius=(p.radius or 2.4)+(p.growth or 0)*math.max(0,age)
			local wobble=1+math.sin(os.clock()*31)*.05
			entry.root.Size=Vector3.one*radius*1.15*wobble
			local mid=entry.model:FindFirstChild("Mid");local outer=entry.model:FindFirstChild("Outer")
			if mid then mid.Size=Vector3.one*radius*1.7 end
			if outer then outer.Size=Vector3.one*radius*2.25*wobble end
			local flames=entry.root:FindFirstChildOfClass("Attachment")
			if flames then
				local f=flames:FindFirstChild("Flames");if f then f.Size=num({{0,radius*1.1},{.4,radius*1.9},{1,radius*.6}}) end
				Kit.setSize(FX.fireStreams[entry.model],num({{0,radius*1.3},{.5,radius*2.3},{1,radius*2}}))
			end
			cf=look*CFrame.Angles(0,0,os.clock()*(FX.fireRoll[entry.model] or 3))
		elseif p.kind=="palm" then
			local radius=(p.radius or 1.5)+(p.growth or 0)*math.max(0,age)
			local ring=entry.model:FindFirstChild("Ring");local core=entry.model:FindFirstChild("Core")
			if ring then ring.Size=Vector3.new(.3,radius*2.2,radius*2.2) end
			if core then core.Size=Vector3.new(.2,radius*1.2,radius*1.2) end
			cf=look
		elseif FX.poses[p.kind] then
			cf=FX.poses[p.kind](self,entry,p,age,look,dt)
		else
			cf=look
		end
		entry.root.CFrame=cf
	end
end

-- ------------------------------------------------------------------ helpers
local function flash(parent,position,color,from,to,time,transparency,keepBall)
	if not keepBall and Kit.has("star") then
		-- (Reference quality) a flat cel flash (our star) and a short hot core,
		-- instead of a growing translucent bubble.
		Kit.star(parent,position,to*.95,color,math.max(.07,time*.8))
		local core=block(parent,Vector3.one*from*.6,CFrame.new(position),color,Enum.Material.Neon)
		core.Shape=Enum.PartType.Ball;core.Transparency=transparency or .15
		tween(core,time*.45,{Size=Vector3.one*from*1.1,Transparency=1})
		Debris:AddItem(core,time*.45+.05)
		return core
	end
	local ball=block(parent,Vector3.one*from,CFrame.new(position),color,Enum.Material.Neon)
	ball.Shape=Enum.PartType.Ball;ball.Transparency=transparency or .15
	tween(ball,time,{Size=Vector3.one*to,Transparency=1})
	Debris:AddItem(ball,time+.05)
	return ball
end
-- The floor under a point, ignoring bodies and effects: marks laid on the
-- ground (scorch, trigrams, burning lanes) must never land on a fighter.
local function floorUnder(fx,position,up,depth)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={fx.folder}
	if fx.fighters then table.insert(exclude,fx.fighters) end
	params.FilterDescendantsInstances=exclude
	return workspace:Raycast(position+Vector3.new(0,up,0),Vector3.new(0,-depth,0),params)
end
local function shockRing(parent,position,color,from,to,time,normal)
	local up=normal or Vector3.yAxis
	if Kit.has("ring") and up.Magnitude>.01 then
		-- (Reference quality) a soft-edged pressure ring (our texture).
		up=up.Unit
		local side=if math.abs(up.Y)>.95 then Vector3.xAxis else Vector3.yAxis
		Kit.plane(parent,CFrame.lookAt(position,position+up,side),"ring",Vector2.new(from,from),Vector2.new(to,to),time,color,0)
		return
	end
	local cf=CFrame.lookAt(position,position+up)*CFrame.Angles(0,math.pi/2,0)
	local ring=block(parent,Vector3.new(.12,from,from),cf,color,Enum.Material.Neon)
	ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.3
	tween(ring,time,{Size=Vector3.new(.04,to,to),Transparency=1})
	Debris:AddItem(ring,time+.05)
end
local function burst(parent,position,props,count)
	local holder=anchorPart(parent,position);holder.Transparency=1
	local at=new("Attachment",{},holder)
	local e=emitter(at,props)
	e:Emit(count)
	Debris:AddItem(holder,3)
	return holder
end
local function smokePuff(parent,position,color,count,size)
	if Kit.has("smoke") then
		-- (Reference quality) cel puffs: fewer, rounder, they swell and break up.
		size=size or 2.2
		Kit.burst(parent,position,"smoke",math.max(3,math.floor((count or 18)*.5)),{
			Lifetime=NumberRange.new(.45,.8),Speed=NumberRange.new(5,11),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(color or Color3.fromRGB(236,236,240)),
			Size=num({{0,size*.9},{.4,size*1.8},{1,size*2.2}}),Transparency=num({{0,0},{.7,.1},{1,1}}),
			Drag=6,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)})
		return
	end
	burst(parent,position,{Texture=TEX.smoke,Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(4,9),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(color or Color3.fromRGB(236,236,240)),LightEmission=0,Size=num({{0,size or 2.2},{1,(size or 2.2)*2.6}}),
		Transparency=num({{0,.15},{1,1}}),Drag=6,RotSpeed=NumberRange.new(-60,60),Rotation=NumberRange.new(0,360)},count or 18)
end
local function sparks(parent,position,color,count,speed)
	if Kit.has("streak") then
		Kit.streaks(parent,position,Vector3.yAxis,math.max(3,math.floor((count or 14)*.6)),color,(speed or 18)*1.6,180)
		return
	end
	burst(parent,position,{Texture=TEX.spark,Lifetime=NumberRange.new(.15,.35),Speed=NumberRange.new(speed or 18,(speed or 18)*1.8),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(color),LightEmission=1,Size=num({{0,.45},{1,0}}),Drag=5},count or 14)
end
-- A translucent copy of a fighter's current pose: afterimages for teleports,
-- dodges and substitutions.
function FX:ghost(model,color,time,transparency)
	if not model then return end
	local holder=new("Model",{Name="Afterimage"},self.folder)
	for _,d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" and d.Transparency<.9 then
			local g=block(holder,d.Size,d.CFrame,color,Enum.Material.Neon,if d:IsA("WedgePart") then "WedgePart" else "Part")
			if d:IsA("Part") then g.Shape=d.Shape end
			g.Transparency=transparency or .45
			tween(g,time,{Transparency=1,Size=d.Size*1.08})
		end
	end
	Debris:AddItem(holder,time+.1)
	return holder
end
local function crows(parent,position,count,spread)
	for i=1,count do
		local bird=new("Model",{Name="Crow"},parent)
		local body=block(bird,Vector3.new(.35,.3,.8),CFrame.new(position),Color3.fromRGB(14,14,18),Enum.Material.SmoothPlastic)
		local wingL=block(bird,Vector3.new(.9,.05,.4),CFrame.new(position),Color3.fromRGB(10,10,14),Enum.Material.SmoothPlastic,"WedgePart")
		local wingR=block(bird,Vector3.new(.9,.05,.4),CFrame.new(position),Color3.fromRGB(10,10,14),Enum.Material.SmoothPlastic,"WedgePart")
		local direction=Vector3.new(math.random()-.5,.35+math.random()*.6,math.random()-.5).Unit
		local distance=(spread or 9)*(0.6+math.random()*.7)
		local start=position+Vector3.new((math.random()-.5)*1.5,(math.random()-.5)*2,(math.random()-.5)*1.5)
		local finish=start+direction*distance
		local life=.55+math.random()*.35
		local t0=os.clock()
		task.spawn(function()
			while bird.Parent and os.clock()-t0<life do
				local k=(os.clock()-t0)/life
				local at=start:Lerp(finish,1-(1-k)^2)
				local cf=CFrame.lookAt(at,at+direction)
				local flap=math.sin(os.clock()*34+i)*.9
				body.CFrame=cf
				wingL.CFrame=cf*CFrame.new(-.45,0,0)*CFrame.Angles(0,0,flap)
				wingR.CFrame=cf*CFrame.new(.45,0,0)*CFrame.Angles(0,0,-flap)
				local fade=math.clamp((k-.6)/.4,0,1)
				body.Transparency=fade;wingL.Transparency=fade;wingR.Transparency=fade
				task.wait()
			end
			bird:Destroy()
		end)
	end
	smokePuff(parent,position,Color3.fromRGB(40,36,44),10,1.6)
end
FX.crows=crows

-- ----------------------------------------------------------------- identity
-- Restrained per-fighter feedback for the identity rules (all server-driven):
-- Itachi's read (eye glint, the afterimage the swing bites) and genjutsu image,
-- Neji's closed chakra points, Minato's wind seal and Yellow Flash, Sasuke's
-- curse. Nothing here can change gameplay.
-- Where each chakra point Neji can close sits on the body (bone, offset from
-- its centre; -Z is the front). Ids: Brawler.TENKETSU_ORDER on the server.
local TENKETSU={
	throat={"Head",CFrame.new(0,-.5,-.42)},heart={"UpperTorso",CFrame.new(-.32,.22,-.52)},solar={"UpperTorso",CFrame.new(0,-.3,-.52)},
	navel={"LowerTorso",CFrame.new(0,.08,-.52)},leftShoulder={"LeftUpperArm",CFrame.new(0,.3,-.3)},rightShoulder={"RightUpperArm",CFrame.new(0,.3,-.3)},
	leftHip={"LowerTorso",CFrame.new(-.52,-.12,-.46)},rightHip={"LowerTorso",CFrame.new(.52,-.12,-.46)},
}
FX.TENKETSU=TENKETSU
local function find(folder,id) return folder and id and folder:FindFirstChild(id) end
function FX.tenketsuWorld(model,id)
	local spec=TENKETSU[id or ""]
	local part=spec and model and model:FindFirstChild(spec[1])
	if not part then return nil,nil end
	return (part.CFrame*spec[2]).Position,part
end
-- Two red points and a thin glint across the eyes: the Sharingan reading.
local function eyeGlint(parent,model)
	local head=model and model:FindFirstChild("Head")
	if not head then return end
	for _,x in {-.22,.22} do flash(parent,(head.CFrame*CFrame.new(x,.1,-.62)).Position,SHARINGAN,.12,.55,.22,0) end
	local streak=block(parent,Vector3.new(1,.05,.05),head.CFrame*CFrame.new(0,.1,-.64),SHARINGAN,Enum.Material.Neon)
	streak.Transparency=.1
	tween(streak,.26,{Size=Vector3.new(2.4,.02,.02),Transparency=1})
	Debris:AddItem(streak,.3)
	local light=new("PointLight",{Color=SHARINGAN,Brightness=4,Range=8,Shadows=false},head)
	tween(light,.3,{Brightness=0})
	Debris:AddItem(light,.35)
end
FX.eyeGlint=eyeGlint
-- Sharingan Read / Focus read: the eyes, the afterimage where he stood that
-- the swing bites, a dry cut. A whiff read is the eyes and a ring only.
function FX:readCue(impact,folder)
	local reader=find(folder,impact.owner)
	eyeGlint(self.folder,reader)
	local at=impact.position
	if impact.phase=="whiff" then
		local victim=find(folder,impact.victim)
		local root=victim and victim:FindFirstChild("HumanoidRootPart")
		if root then shockRing(self.folder,root.Position-Vector3.new(0,2.6,0),SHARINGAN,1,5,.25) end
		sound(anchorPart(self.folder,at),SOUND.whoosh,.22,2.6)
		return
	end
	if reader then
		local ghost=self:ghost(reader,SHARINGAN,.34,.35)
		local root=reader:FindFirstChild("HumanoidRootPart")
		if ghost and root then
			-- The body may already be drawn at its new spot: leave the copy where he stood.
			local shift=at-root.Position
			ghost:PivotTo(ghost:GetPivot()+Vector3.new(shift.X,0,shift.Z))
		end
	end
	flash(self.folder,at+Vector3.new(0,.5,0),Color3.fromRGB(255,240,236),.3,2.8,.14,.2)
	sparks(self.folder,at+Vector3.new(0,.5,0),Color3.fromRGB(255,220,220),8,16)
	sound(anchorPart(self.folder,at),SOUND.whoosh,.34,2.3)
	sound(anchorPart(self.folder,at),SOUND.hit,.18,.6)
	self:cheer(.6)
end
-- Genjutsu: Mirage. cast = a red ripple under the deceived body as the image
-- takes; catch = the image breaks where the swing bit it; touch/break = it
-- dissolves; seen = the Byakugan shrugs it off. A skill-build echo: red smoke.
function FX:mirageCue(impact,folder)
	local at=impact.position
	local caster=find(folder,impact.owner)
	local phase=impact.phase
	if phase=="cast" then
		local victim=find(folder,impact.victim)
		local root=victim and victim:FindFirstChild("HumanoidRootPart")
		if root then shockRing(self.folder,root.Position-Vector3.new(0,2.6,0),SHARINGAN,2,9,.45) end
		flash(self.folder,at,Color3.fromRGB(150,24,34),1,4,.3,.55)
		eyeGlint(self.folder,caster)
		sound(anchorPart(self.folder,at),SOUND.whoosh,.3,.55)
	elseif phase=="catch" then
		for _=1,12 do
			local dir=Vector3.new(math.random()-.5,math.random()*.8,math.random()-.5)
			dir=if dir.Magnitude>.01 then dir.Unit else Vector3.yAxis
			local shard=block(self.folder,Vector3.new(.3,.5,.06),CFrame.lookAt(at,at+dir)*CFrame.new(0,(math.random()-.5)*3,0),SHARINGAN,Enum.Material.Neon)
			shard.Transparency=.25
			tween(shard,.4,{CFrame=shard.CFrame+dir*(2+math.random()*3),Transparency=1,Size=Vector3.new(.05,.2,.02)})
			Debris:AddItem(shard,.45)
		end
		flash(self.folder,at,SHARINGAN,1,6,.22,.15)
		smokePuff(self.folder,at,Color3.fromRGB(60,24,30),12,1.6)
		eyeGlint(self.folder,caster)
		sound(anchorPart(self.folder,at),SOUND.hit,.4,.7)
		self:cheer(.8)
	elseif phase=="seen" then
		local victim=find(folder,impact.victim)
		local head=victim and victim:FindFirstChild("Head")
		if head then flash(self.folder,head.Position,HYUGA,.4,2.4,.2,.2) end
	elseif phase=="touch" or phase=="break" then
		smokePuff(self.folder,at,Color3.fromRGB(70,40,46),6,1.2)
	else
		smokePuff(self.folder,at+Vector3.new(0,1,0),Color3.fromRGB(60,24,30),10,1.6)
		if impact.to then smokePuff(self.folder,impact.to+Vector3.new(0,1,0),Color3.fromRGB(60,24,30),6,1.2) end
	end
end
-- Gentle Fist: a pinpoint flash on the exact point that closed, a short chakra
-- pulse and a dry tick; a sealed network (every point) rings once, deeper.
function FX:tenketsuCue(impact,folder)
	local victim=find(folder,impact.victim)
	local at,part=FX.tenketsuWorld(victim,impact.point)
	at=at or impact.position
	local severe=impact.severe==true
	flash(self.folder,at,HYUGA,.12,if severe then 1.6 else 1.05,.14,0)
	shockRing(self.folder,at,HYUGA,.3,if severe then 4.6 else 3,.22,part and part.CFrame.LookVector or nil)
	sparks(self.folder,at,HYUGA,if severe then 10 else 5,8)
	sound(anchorPart(self.folder,at),SOUND.hit,.26,1.95)
	if severe then
		sound(anchorPart(self.folder,at),SOUND.heavy,.32,.6)
		local torso=victim and victim:FindFirstChild("UpperTorso")
		if torso then shockRing(self.folder,torso.Position,HYUGA,1,7,.4) end
	end
end
-- Wind Cut: a pale crescent where the cut throws the body aside; the wind seal
-- then rides on it (FX:seal draws it in the wind's colour).
function FX:windSealCue(impact)
	local at=impact.position
	local across=impact.direction or Vector3.xAxis
	local slash=block(self.folder,Vector3.new(.1,3.2,.25),CFrame.lookAt(at,at+across)*CFrame.Angles(0,0,math.rad(35)),WIND,Enum.Material.Neon)
	slash.Transparency=.2
	tween(slash,.22,{Size=Vector3.new(.04,4.2,.08),Transparency=1})
	Debris:AddItem(slash,.25)
	flash(self.folder,at,MINATO,.3,2,.16,.3)
	sound(anchorPart(self.folder,at),SOUND.whoosh,.34,1.9)
end
-- Curse Mark: the kick that does not let go flares purple on the body.
function FX:curseCue(impact)
	local at=impact.position
	flash(self.folder,at,CURSE,.4,3.2,.2,.2)
	sparks(self.folder,at,Color3.fromRGB(170,120,255),10,18)
	sound(anchorPart(self.folder,at),SOUND.heavy,.28,1.4)
end
-- The genjutsu image (Presentation:illusion): a frozen copy of `source` in its
-- current pose. "deceived": exactly the fighter, with a faint red outline that
-- pulses now and then (the tell); "caster": a red translucent afterimage, so
-- Itachi's player sees the trap he left. Its pivot is the copied root.
function FX:image(source,mode)
	if not source then return nil end
	local archivable=source.Archivable
	source.Archivable=true
	local ok,copy=pcall(function() return source:Clone() end)
	source.Archivable=archivable
	if not ok or not copy then return nil end
	copy.Name="GenjutsuImage"
	for _,d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false;d.CastShadow=false
			d.LocalTransparencyModifier=0
			if mode=="caster" and d.Transparency<.95 then d.Color=SHARINGAN;d.Material=Enum.Material.SmoothPlastic;d.Transparency=math.max(d.Transparency,.62) end
		elseif d:IsA("Humanoid") or d:IsA("Sound") or d:IsA("Trail") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") or d:IsA("BaseScript") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	if mode=="deceived" then
		new("Highlight",{Name="Tell",FillTransparency=1,OutlineColor=SHARINGAN,OutlineTransparency=1,DepthMode=Enum.HighlightDepthMode.Occluded},copy)
	end
	copy.Parent=self.folder
	return copy
end
-- Persistent identity cues, every frame (FX:fighter): Neji's closed points stay
-- lit on the body that carries them (pulsing fast once the network is sealed,
-- chakra leaking), Byakugan Full Field lays its field, a hungry Curse Mark
-- flickers.
function FX:identity(model,actor,aura)
	local root=model:FindFirstChild("HumanoidRootPart")
	local alive=(actor.health or 1)>0
	local severe=actor.tenketsuSevere==true and alive
	aura.points=aura.points or {}
	local live={}
	for _,id in (if alive then actor.tenketsuPoints else nil) or {} do
		live[id]=true
		local entry=aura.points[id]
		if not entry or not entry.dot.Parent then
			local dot=block(self.folder,Vector3.one*.18,CFrame.new(),HYUGA,Enum.Material.Neon);dot.Shape=Enum.PartType.Ball
			entry={dot=dot,born=os.clock()};aura.points[id]=entry
		end
		local at=FX.tenketsuWorld(model,id)
		if at then entry.dot.CFrame=CFrame.new(at) end
		local pulse=.5+.5*math.sin((os.clock()-entry.born)*(if severe then 14 else 5))
		entry.dot.Transparency=(if severe then .05 else .3)+pulse*.35
		entry.dot.Size=Vector3.one*(if severe then .26 else .18)
	end
	for id,entry in aura.points do if not live[id] then entry.dot:Destroy();aura.points[id]=nil end end
	local torso=model:FindFirstChild("UpperTorso") or root
	if severe and not aura.leak and torso then
		local at=new("Attachment",{Name="ChakraLeak"},torso)
		aura.leak=new("ParticleEmitter",{Texture=TEX.glow,Rate=10,Lifetime=NumberRange.new(.4,.7),Speed=NumberRange.new(1,2.5),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(HYUGA),LightEmission=.6,LightInfluence=0,Size=num({{0,.35},{1,0}}),Transparency=num({{0,.4},{1,1}})},at)
	elseif not severe and aura.leak then
		aura.leak.Enabled=false;Debris:AddItem(aura.leak.Parent,.8);aura.leak=nil
	end
	if actor.fighterId=="GentleFist" and root then
		local full=(actor.awaken or 0)>0 and alive
		if full and (not aura.field or not aura.field.Parent) then
			local ring=block(self.folder,Vector3.new(.06,16,16),root.CFrame,HYUGA,Enum.Material.Neon);ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.9
			aura.field=ring
		elseif not full and aura.field then
			tween(aura.field,.3,{Transparency=1});Debris:AddItem(aura.field,.35);aura.field=nil
		end
		if aura.field then aura.field.CFrame=CFrame.new(root.Position-Vector3.new(0,2.9,0))*CFrame.Angles(0,0,math.pi/2) end
	end
	if actor.fighterId=="Lion" and (actor.awaken or 0)>0 and actor.curseHunger and alive then
		local on=math.sin(os.clock()*18)>0
		for _,mark in aura.marks or {} do mark.Transparency=if on then .5 else 0 end
	end
end

-- ------------------------------------------------------------------ contacts
local function modelFor(folder,id)
	return folder and folder:FindFirstChild(id or "")
end
function FX:impact(impact,folder)
	local style=impact.style
	local position=impact.position
	if not position then return end
	if impact.other then self:finishProjectile(impact.other) end
	if impact.projectile then
		local entry=self.projectiles[impact.projectile]
		local direction=impact.direction or (entry and entry.data.direction) or Vector3.zAxis
		if entry then self:finishProjectile(impact.projectile) end
		if style=="stick" and not impact.chakra and (impact.kind=="kunai" or impact.kind=="marked" or impact.kind=="shuriken") then
			self:stick(impact.kind,position,impact.normal or Vector3.yAxis,direction,impact.owner)
		end
	end
	if CHEER[style] then self:cheer(CHEER[style]) end
	-- (Reference quality) the struck body flashes: red on a blow, gold on a
	-- guard, longer and stronger the harder it was.
	if impact.victim and impact.amount then
		local weight=math.clamp(impact.amount/20,.25,1)
		pcall(Kit.tint,modelFor(folder,impact.victim),if impact.guarded then Color3.fromRGB(255,214,120) else Color3.fromRGB(255,236,226),
			.06+.07*weight,if impact.guarded then .35 else .3+.25*weight)
	end
	for _,layer in FX.layers do if layer.impact and layer.impact(self,impact,folder) then return end end
	if style=="fire" then
		self:explosion(position,impact.normal,1+.7*(impact.charge or 0))
	elseif style=="teleport" then
		self:teleport(impact.from or position,impact.to or position,modelFor(folder,impact.owner),impact.awake)
	elseif style=="substitute" then
		self:substitute(position,impact.to,impact.fighter,modelFor(folder,impact.owner))
	elseif style=="mirage" then
		self:mirageCue(impact,folder)
	elseif style=="read" then
		self:readCue(impact,folder)
	elseif style=="tenketsu" then
		self:tenketsuCue(impact,folder)
	elseif style=="windseal" then
		self:windSealCue(impact)
	elseif style=="curse" then
		self:curseCue(impact)
	elseif style=="chase" then
		local model=modelFor(folder,impact.owner)
		-- Each prodigy's re-entry reads differently (server: MoveGraphs reengage):
		-- Minato a clean flash, Itachi a lingering copy, Neji a small chakra
		-- pulse, Sasuke an explosive kick-off. Unknown variants keep the plain look.
		local variant=impact.variant
		local tone=if impact.fighter=="Flashstep" then MINATO elseif impact.fighter=="GentleFist" then HYUGA elseif impact.fighter=="Lion" then LION else Color3.fromRGB(150,40,60)
		self:ghost(model,tone,if variant=="mirage" then .45 else .22,if variant=="mirage" then .4 else .55)
		if variant=="flash" then flash(self.folder,position,MINATO,1,4,.14,.3)
		elseif variant=="palm" then flash(self.folder,position,HYUGA,.5,3,.12,.25)
		elseif variant=="lion" then sparks(self.folder,position-Vector3.new(0,2.4,0),LION,10,18) end
		smokePuff(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(200,190,170),if variant=="lion" then 14 elseif variant=="flash" then 4 else 8,if variant=="lion" then 1.9 else 1.4)
		sound(anchorPart(self.folder,position),SOUND.whoosh,.35,if variant=="flash" then 1.15 elseif variant=="lion" then .7 else .8)
	elseif style=="dodge" then
		local nearest
		for _,name in self.fighterIds or {"PlayerFighter","AIFighter"} do
			local m=modelFor(folder,name);local r=m and m:FindFirstChild("HumanoidRootPart")
			if r and (r.Position-position).Magnitude<4 then nearest=m end
		end
		if nearest then self:ghost(nearest,Color3.fromRGB(200,220,255),.2,.6) end
		smokePuff(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(196,186,166),6,1.2)
	elseif style=="quickstep" then
		local model=modelFor(folder,impact.owner)
		flash(self.folder,position,MINATO,1,4,.16,.3)
		if model then self:ghost(model,MINATO,.2,.5) end
	elseif style=="cast" then
		local model=modelFor(folder,impact.owner)
		local hands=model and model:FindFirstChild("RightHand")
		if hands then
			local color=if impact.technique=="FireBloom" or impact.technique=="PhoenixFlower" then Color3.fromRGB(255,120,50) elseif impact.technique=="MirageCast" or impact.technique=="Read" then Color3.fromRGB(220,30,40)
				elseif impact.technique=="WindCut" then Color3.fromRGB(170,255,220) else Color3.fromRGB(140,200,255)
			sparks(self.folder,hands.Position,color,10,8)
		end
	elseif style=="landing" then
		smokePuff(self.folder,position-Vector3.new(0,2.7,0),Color3.fromRGB(190,178,150),6,1.1)
		sound(anchorPart(self.folder,position),SOUND.land,.35,1.05)
	elseif style=="slam" then
		smokePuff(self.folder,position-Vector3.new(0,2.4,0),Color3.fromRGB(176,160,130),22,2.6)
		local floor=floorUnder(self,position,2,8)
		if floor then Kit.ground(self.folder,floor.Position,floor.Normal,"crack",10,2.6,1.2,Color3.new(1,1,1),.05) end
		shockRing(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(255,214,160),3,22,.32)
	elseif style=="launcher" or style=="finisher" then
		shockRing(self.folder,position,Color3.fromRGB(255,236,200),2,9,.2,impact.direction)
	elseif style=="kunai" or style=="shuriken" then
		sparks(self.folder,position,Color3.fromRGB(255,236,200),10,20)
	elseif style=="parry" then
		sparks(self.folder,position,Color3.fromRGB(255,246,180),22,26)
		flash(self.folder,position,Color3.fromRGB(255,250,220),1,6,.14,.2)
	elseif style=="burst" then
		local model=modelFor(folder,impact.owner)
		if model then self:ghost(model,Color3.fromRGB(140,200,255),.25,.5) end
	elseif style=="clash" then
		-- Two strikes meeting: a hard white-gold flash and a ring across the line
		-- between the fighters, nothing else. It has to read instantly.
		local across=impact.direction or Vector3.zAxis
		sparks(self.folder,position,Color3.fromRGB(255,244,200),28,34)
		flash(self.folder,position,Color3.fromRGB(255,252,232),1,7,.16,.1)
		shockRing(self.folder,position,Color3.fromRGB(255,232,170),2,14,.26,across)
		sound(anchorPart(self.folder,position),SOUND.whoosh,.5,2.2)
	elseif style=="wall" or style=="wallbounce" then
		-- Impact on the wall: a ring flat on the surface, dust pushed out of it and
		-- a few chips of stone.
		local normal=impact.normal or Vector3.zAxis
		local big=style=="wallbounce"
		shockRing(self.folder,position+normal*.15,Color3.fromRGB(236,226,200),2,if big then 16 else 11,if big then .34 else .26,normal)
		smokePuff(self.folder,position+normal*.8,Color3.fromRGB(196,188,168),if big then 22 else 14,if big then 2.6 else 2)
		for k=1,(if big then 7 else 4) do
			local chip=block(self.folder,Vector3.new(.4,.3,.35),CFrame.new(position+normal*.5)*CFrame.Angles(math.random()*6,math.random()*6,0),Color3.fromRGB(186,178,160),Enum.Material.Concrete)
			local out=(normal+Vector3.new((math.random()-.5)*1.4,math.random()*.9,(math.random()-.5)*1.4)).Unit
			tween(chip,.45,{CFrame=chip.CFrame+out*(2.5+math.random()*3)+Vector3.new(0,-1.5,0),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
			Debris:AddItem(chip,.5)
		end
		if big then sparks(self.folder,position+normal,Color3.fromRGB(255,226,170),14,22) end
		-- (Reference quality) the surface cracks where the body met it.
		Kit.ground(self.folder,position,normal,"crack",if big then 9 else 6,2.2,1.2,Color3.new(1,1,1),.1)
	elseif style=="worldbreak" then
		-- (EMB-004) A tree going down or a boulder bursting: the server already
		-- changed the arena; this is the dust and the pieces flying off it.
		local wood=impact.material=="wood"
		local tone=if wood then Color3.fromRGB(120,88,58) else Color3.fromRGB(150,144,132)
		local out=impact.direction or Vector3.xAxis
		smokePuff(self.folder,position,if wood then Color3.fromRGB(176,156,124) else Color3.fromRGB(190,184,170),20,2.8)
		shockRing(self.folder,position,Color3.fromRGB(236,226,200),2,14,.3,-out)
		for k=1,8 do
			local piece=block(self.folder,if wood then Vector3.new(.25,.25,1.3) else Vector3.new(.6,.45,.5),CFrame.new(position)*CFrame.Angles(math.random()*6,math.random()*6,0),tone,if wood then Enum.Material.Wood else Enum.Material.Slate)
			local fly=(out+Vector3.new((math.random()-.5)*1.6,math.random()*1.2,(math.random()-.5)*1.6)).Unit
			tween(piece,.6,{CFrame=piece.CFrame+fly*(4+math.random()*5)+Vector3.new(0,-2,0),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
			Debris:AddItem(piece,.65)
		end
		sound(anchorPart(self.folder,position),SOUND.whoosh,.6,.6)
	elseif style=="walltech" then
		local model=modelFor(folder,impact.owner)
		if model then self:ghost(model,Color3.fromRGB(220,230,255),.2,.55) end
		local normal=impact.normal or Vector3.zAxis
		smokePuff(self.folder,position,Color3.fromRGB(226,222,210),12,1.8)
		shockRing(self.folder,position,Color3.fromRGB(220,232,255),1.5,8,.22,normal)
		sound(anchorPart(self.folder,position),SOUND.whoosh,.4,1.3)
	elseif style=="pin" then
		sparks(self.folder,position,Color3.fromRGB(255,236,200),8,16)
	elseif style=="flow" then
		-- On the beat: a crisp white-blue ring at the contact, nothing heavy.
		local count=impact.count or 1
		flash(self.folder,position,Color3.fromRGB(220,236,255),.6,3+math.min(count,4),.12,.15)
		shockRing(self.folder,position,Color3.fromRGB(200,226,255),1,6+math.min(count,4)*1.5,.18)
	elseif style=="awaken" then
		local model=modelFor(folder,impact.owner)
		local tone=if impact.fighter=="Flashstep" then MINATO elseif impact.fighter=="GentleFist" then HYUGA elseif impact.fighter=="Lion" then CURSE else Color3.fromRGB(230,40,50)
		if model then self:ghost(model,tone,.35,.4) end
		flash(self.folder,position,tone,2,14,.35,.2)
		shockRing(self.folder,position-Vector3.new(0,2.6,0),tone,3,24,.45)
		smokePuff(self.folder,position-Vector3.new(0,2.4,0),Color3.fromRGB(214,206,190),20,2.6)
		self:cheer(1)
	elseif style=="palmburst" then
		local along=impact.direction or Vector3.zAxis
		shockRing(self.folder,position,Color3.fromRGB(220,232,255),2,12,.24,along)
		smokePuff(self.folder,position,Color3.fromRGB(226,230,240),10,1.8)
	elseif style=="palm" then
		-- A Gentle Fist palm: a small, sharp chakra flash; no debris.
		flash(self.folder,position,HYUGA,.5,impact.heavy and 6 or 3,.12,.25)
		sparks(self.folder,position,HYUGA,impact.heavy and 16 or 6,impact.heavy and 22 or 12)
	elseif style=="deflect" then
		sparks(self.folder,position,Color3.fromRGB(230,240,255),12,24)
	elseif style=="repel" then
		shockRing(self.folder,position,HYUGA,3,16,.3,impact.direction)
		smokePuff(self.folder,position-Vector3.new(0,2.4,0),Color3.fromRGB(214,206,190),14,2)
	elseif style=="rotation" then
		shockRing(self.folder,position-Vector3.new(0,2.6,0),HYUGA,4,18,.5)
		smokePuff(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(214,206,190),18,2.4)
	elseif style=="trigram" then
		self:trigram(position)
	elseif style=="ember" then
		if Kit.has("fire") then self:explosion(position,impact.normal,.32) end
		flash(self.folder,position,Color3.fromRGB(255,170,80),.8,4.5,.18,.2)
		sparks(self.folder,position,Color3.fromRGB(255,170,80),10,14)
	elseif style=="afterimage" then
		-- A lateral route: the body leaves a fading copy where it stood.
		local model=modelFor(folder,impact.owner)
		if model then self:ghost(model,if impact.fighter=="GentleFist" then HYUGA elseif impact.fighter=="Lion" then LION else Color3.fromRGB(150,40,60),.3,.45) end
		smokePuff(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(196,186,166),5,1)
	elseif style=="chidori" then
		flash(self.folder,position,Color3.fromRGB(170,200,255),1,6,.18,.25)
		sparks(self.folder,position,Color3.fromRGB(200,225,255),24,30)
	elseif style=="groundbounce" then
		-- A spiked body hits the floor and pops back up: dust ring and cracks.
		smokePuff(self.folder,position,Color3.fromRGB(176,160,130),16,2.2)
		shockRing(self.folder,position+Vector3.new(0,.1,0),Color3.fromRGB(255,226,180),2,13,.26)
		sound(anchorPart(self.folder,position),SOUND.land,.6,.7)
		sound(anchorPart(self.folder,position),SOUND.bodyfall,.5,1.05,.7)
		local floor=floorUnder(self,position,2,6)
		if floor then Kit.ground(self.folder,floor.Position,floor.Normal,"crack",8,2.4,1.2,Color3.new(1,1,1),.1) end
	end
	-- Chakra interactions (infusion contacts, meetings in flight, planted
	-- points, wire). Presentation only, and never allowed to break the feed.
	if impact.chakra then pcall(self.chakraImpact,self,impact,folder) end
end
-- Eight trigrams drawn on the ground around Neji for the sixty-four palms.
function FX:trigram(position)
	local floor=floorUnder(self,position,2,10)
	local at=if floor then floor.Position+Vector3.new(0,.05,0) else position-Vector3.new(0,2.9,0)
	local glyph=new("Model",{Name="Trigrams"},self.folder)
	local base=CFrame.new(at)*CFrame.Angles(0,0,math.pi/2)
	local disc=block(glyph,Vector3.new(.04,15,15),base,HYUGA,Enum.Material.SmoothPlastic);disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.9
	local inner=block(glyph,Vector3.new(.05,3.4,3.4),base,Color3.fromRGB(236,240,255),Enum.Material.Neon);inner.Shape=Enum.PartType.Cylinder;inner.Transparency=.5
	for k=0,7 do
		local a=k/8*math.pi*2
		for line=0,2 do
			local broken=(k+line)%3==0
			local radius=5+line*.55
			local cf=CFrame.new(at+Vector3.new(math.sin(a)*radius,.02,math.cos(a)*radius))*CFrame.Angles(0,a,0)
			if broken then
				for _,side in {-1,1} do block(glyph,Vector3.new(.55,.05,.16),cf*CFrame.new(side*.42,0,0),HYUGA,Enum.Material.Neon) end
			else
				block(glyph,Vector3.new(1.4,.05,.16),cf,HYUGA,Enum.Material.Neon)
			end
		end
	end
	for _,d in glyph:GetDescendants() do if d:IsA("BasePart") then d.Transparency=math.max(d.Transparency,.35) end end
	flash(self.folder,at+Vector3.new(0,1,0),HYUGA,1,8,.25,.4)
	task.delay(1.6,function()
		for _,d in glyph:GetDescendants() do if d:IsA("BasePart") then tween(d,.4,{Transparency=1}) end end
	end)
	Debris:AddItem(glyph,2.1)
end
-- A thrown blade that missed stays embedded where it landed for a moment.
function FX:stick(kind,position,normal,direction,owner)
	if kind=="marked" then return end -- the seal renderer owns planted marked kunai
	local model=if kind=="shuriken" then FX.buildShuriken() else FX.buildKunai(false)
	model.Parent=self.folder
	local into=direction.Unit
	if into:Dot(normal)>-.2 then into=(into-normal*1.2).Unit end
	local depth=if kind=="shuriken" then .25 else .45
	local cf=CFrame.lookAt(position-into*depth,position-into*depth+into)
	if kind=="shuriken" then cf=cf*CFrame.Angles(math.rad(80),0,0) end
	model:PivotTo(cf)
	sparks(self.folder,position,Color3.fromRGB(255,226,170),6,12)
	task.delay(2.6,function()
		for _,d in model:GetDescendants() do if d:IsA("BasePart") then tween(d,.4,{Transparency=1}) end end
		Debris:AddItem(model,.5)
	end)
end
function FX:explosion(position,normal,scale)
	scale=scale or 1
	local holder=anchorPart(self.folder,position);holder.Transparency=1
	sound(holder,SOUND.boom,.8,.9)
	sound(holder,SOUND.debris,.32*scale,1.15,1.1)
	local light=new("PointLight",{Color=Color3.fromRGB(255,150,70),Brightness=10,Range=46*scale,Shadows=false},holder)
	tween(light,.9,{Brightness=0})
	if not Kit.has("fire") then
		-- Built-in look (no texture available).
		flash(self.folder,position,Color3.fromRGB(255,236,170),3,15,.35,.05)
		flash(self.folder,position,Color3.fromRGB(255,120,40),5,19,.5,.35)
		shockRing(self.folder,position,Color3.fromRGB(255,170,90),4,26,.38,normal)
		burst(self.folder,position,{Texture=TEX.fire,Lifetime=NumberRange.new(.45,.9),Speed=NumberRange.new(14,30),SpreadAngle=Vector2.new(180,180),
			Color=seq({{0,Color3.fromRGB(255,240,170)},{.4,Color3.fromRGB(255,130,40)},{1,Color3.fromRGB(80,24,10)}}),LightEmission=1,
			Size=num({{0,4},{.5,7},{1,2}}),Transparency=num({{0,.1},{1,1}}),Drag=4,RotSpeed=NumberRange.new(-90,90),Rotation=NumberRange.new(0,360)},34)
	else
		-- (Reference quality) a cel-shaded blast: a white core flash, billows of
		-- fire that swell, darken and break into smoke, a dome of pressure, the
		-- ground scorched in streaks, cracked under it, and debris thrown out.
		local folder=self.folder
		flash(folder,position,Color3.fromRGB(255,252,226),2*scale,13*scale,.16,0)
		local dome=flash(folder,position,Color3.fromRGB(255,244,226),4*scale,22*scale,.3,.5,true)
		dome.Material=Enum.Material.SmoothPlastic
		Kit.star(folder,position,16*scale,Color3.fromRGB(255,240,190),.14)
		Kit.burst(folder,position,"fire",math.floor(16*scale),{
			Lifetime=NumberRange.new(.8,1.25),Speed=NumberRange.new(10*scale,24*scale),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(Color3.new(1,1,1)),LightEmission=.15,
			Size=num({{0,5*scale},{.35,9*scale},{1,11*scale}}),Transparency=num({{0,0},{.85,0},{1,1}}),
			Drag=5,Acceleration=Vector3.new(0,4,0),RotSpeed=NumberRange.new(-30,30),Rotation=NumberRange.new(0,360),zoffset=1})
		Kit.burst(folder,position,"fire",math.floor(8*scale),{
			Lifetime=NumberRange.new(.5,.75),Speed=NumberRange.new(2,6),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(Color3.new(1,1,1)),LightEmission=.35,
			Size=num({{0,6*scale},{.4,10*scale},{1,8*scale}}),Transparency=num({{0,0},{.8,0},{1,1}}),
			Drag=3,Rotation=NumberRange.new(0,360),zoffset=1.5})
		task.delay(.22,function()
			Kit.burst(folder,position+Vector3.new(0,2.5,0),"smoke",math.floor(9*scale),{
				Lifetime=NumberRange.new(.9,1.4),Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(70,70),
				Color=ColorSequence.new(Color3.fromRGB(58,54,58)),LightEmission=0,
				Size=num({{0,5*scale},{1,11*scale}}),Transparency=num({{0,.1},{.5,.25},{1,1}}),
				Drag=2.5,Acceleration=Vector3.new(0,9,0),RotSpeed=NumberRange.new(-20,20),Rotation=NumberRange.new(0,360),zoffset=-.5})
		end)
		burst(folder,position,{Texture=TEX.fireSpark,Lifetime=NumberRange.new(.6,1.3),Speed=NumberRange.new(24,50),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(Color3.fromRGB(255,196,110)),LightEmission=1,Size=num({{0,.6},{1,0}}),Drag=2,Acceleration=Vector3.new(0,-34,0)},40)
		-- Debris: dark chips thrown out and falling.
		for k=1,math.floor(9*scale) do
			local chip=block(folder,Vector3.new(.5,.4,.45)*(.6+math.random()*.8),CFrame.new(position)*CFrame.Angles(math.random()*6,math.random()*6,0),
				Color3.fromRGB(46,34,30),Enum.Material.Slate)
			local out=Vector3.new(math.random()-.5,.4+math.random()*.8,math.random()-.5).Unit
			local reach=(6+math.random()*9)*scale
			tween(chip,.55,{CFrame=chip.CFrame*CFrame.Angles(3,2,0)+out*reach},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
			task.delay(.55,function() if chip.Parent then tween(chip,.35,{CFrame=chip.CFrame-Vector3.new(0,4,0),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In) end end)
			Debris:AddItem(chip,1)
		end
	end
	-- Scorched ground under the blast: radial burn streaks and cracks.
	local floor=floorUnder(self,position,2,14)
	if floor then
		if Kit.has("scorch") then
			Kit.ground(self.folder,floor.Position,floor.Normal,"scorch",16*scale,4.5,2,Color3.new(1,1,1),.08)
			Kit.ground(self.folder,floor.Position,floor.Normal,"crack",8*scale,3.5,1.5,Color3.new(1,1,1),.15)
			local flat=CFrame.lookAt(floor.Position+floor.Normal*.2,floor.Position+floor.Normal*1.2,Vector3.xAxis)
			Kit.plane(self.folder,flat,"ring",Vector2.new(4,4)*scale,Vector2.new(30,30)*scale,.42,Color3.fromRGB(255,200,140),0)
			Kit.dust(self.folder,floor.Position,math.floor(10*scale),3.2*scale,Color3.fromRGB(200,180,150),18)
		else
			local scorch=block(self.folder,Vector3.new(.05,9,9),CFrame.new(floor.Position+floor.Normal*.04)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(24,18,16),Enum.Material.Slate)
			scorch.Shape=Enum.PartType.Cylinder;scorch.Transparency=.25
			task.delay(3.5,function() tween(scorch,1.5,{Transparency=1}) end)
			Debris:AddItem(scorch,5.2)
		end
	end
end
function FX:teleport(from,to,model,awake)
	-- Yellow flash: a body-shaped afterimage where he stood, a single bright
	-- streak along the path, and a flash + shockwave where he reappears.
	if model then self:ghost(model,MINATO,.28,.25) end
	flash(self.folder,from,MINATO_CORE,1.5,7,.2,.05)
	local delta=to-from
	if delta.Magnitude>1 then
		local streak=block(self.folder,Vector3.new(.35,.35,delta.Magnitude),CFrame.lookAt(from:Lerp(to,.5),to),MINATO,Enum.Material.Neon)
		streak.Transparency=.15
		tween(streak,.16,{Size=Vector3.new(.02,.02,delta.Magnitude),Transparency=1})
		Debris:AddItem(streak,.2)
	end
	flash(self.folder,to,MINATO_CORE,2,9,.22,0)
	flash(self.folder,to,MINATO,4,12,.32,.4)
	if Kit.has("star") then
		-- (Reference quality) the Yellow Flash: a star where he lands, light
		-- thrown out along his line, the floor dust kicked up under him.
		Kit.star(self.folder,to,9,MINATO_CORE,.12)
		Kit.star(self.folder,from,5,MINATO,.08)
		if delta.Magnitude>1 then Kit.streaks(self.folder,to,delta.Unit,10,MINATO,80,30) end
		local floor=floorUnder(self,to,1,6)
		if floor then
			Kit.dust(self.folder,floor.Position,5,2,Color3.fromRGB(226,214,186),14)
			local flat=CFrame.lookAt(floor.Position+floor.Normal*.2,floor.Position+floor.Normal*1.2,Vector3.xAxis)
			Kit.plane(self.folder,flat,"ring",Vector2.new(2,2),Vector2.new(14,14),.3,MINATO,0)
		end
	end
	shockRing(self.folder,to-Vector3.new(0,2.6,0),MINATO,2,16,.3)
	sparks(self.folder,to,MINATO,18,24)
	if awake then
		-- Yellow Flash: a second, wider ring at the arrival and a flash left at
		-- the departure (the seal he leaves there): the chain has a rhythm.
		shockRing(self.folder,to-Vector3.new(0,2.6,0),MINATO_CORE,3,22,.4)
		flash(self.folder,from,MINATO,1,5,.3,.3)
	end
	local holder=anchorPart(self.folder,to);holder.Transparency=1
	sound(holder,SOUND.whoosh,.55,1.6)
	sound(holder,SOUND.whooshBy,.45,1.7)
	local light=new("PointLight",{Color=MINATO,Brightness=8,Range=24,Shadows=false},holder)
	tween(light,.35,{Brightness=0})
	Debris:AddItem(holder,1)
end
function FX:substitute(position,to,fighter,model)
	if model then self:ghost(model,Color3.fromRGB(220,220,230),.18,.5) end
	smokePuff(self.folder,position,Color3.fromRGB(240,240,244),22,2.4)
	if fighter=="Mirage" then
		crows(self.folder,position,10,11)
	else
		-- The classic: a wooden log takes the hit in his place.
		local log=block(self.folder,Vector3.new(4.2,1.3,1.3),CFrame.new(position)*CFrame.Angles(0,math.random()*math.pi,math.rad(70)),Color3.fromRGB(122,84,52),Enum.Material.Wood)
		log.Shape=Enum.PartType.Cylinder;log.Anchored=false;log.CanCollide=true;log.Massless=false
		log.AssemblyLinearVelocity=Vector3.new(0,6,0)
		task.delay(1.6,function() if log.Parent then tween(log,.4,{Transparency=1}) end end)
		Debris:AddItem(log,2.1)
	end
	if to then smokePuff(self.folder,to,Color3.fromRGB(236,236,240),8,1.4) end
	sound(anchorPart(self.folder,position),SOUND.whoosh,.4,.9)
end

-- ------------------------------------------------------------------ chakra
-- What an infusion looks like on the object, read from the snapshot's
-- `infusion` (ChakraCombat). Unknown natures fall back to plain reinforcement.
local INFUSION={
	Reinforce={color=Color3.fromRGB(150,205,255),core=Color3.fromRGB(232,246,255),light=2.6,trail=.2,width=1.8},
	Wind={color=Color3.fromRGB(150,255,214),core=Color3.fromRGB(232,255,246),light=2.2,trail=.36,width=2.8,ring=true},
	Fire={color=Color3.fromRGB(255,128,44),core=Color3.fromRGB(255,226,150),light=4,trail=.24,width=2,flame=true},
	Lightning={color=Color3.fromRGB(140,186,255),core=Color3.fromRGB(236,244,255),light=4,trail=.13,width=1.6,spark=true},
	GentleFist={color=HYUGA,core=Color3.fromRGB(236,242,255),light=2.6,trail=.14,width=1.4},
}
FX.Infusion=INFUSION
local function lookOf(infusion) return INFUSION[infusion or ""] or INFUSION.Reinforce end
-- Decorate a projectile model: a chakra sheath around the steel, a coloured
-- trail sized by the nature, a light, flames or sparks, a wind ring.
function FX:infuse(model,root,infusion,kind,planted)
	local look=lookOf(infusion)
	local decor={look=look,emitters={}}
	local flatBlade=kind=="shuriken" or kind=="wire"
	-- A translucent chakra sheath: a disc round a shuriken, a sleeve along a kunai.
	local sheath=if flatBlade then block(model,Vector3.new(.2,1.05,1.05),root.CFrame*CFrame.Angles(0,0,math.pi/2),look.color,Enum.Material.Neon)
		else block(model,Vector3.new(1.35,.34,.34),root.CFrame*CFrame.new(0,0,-.25)*CFrame.Angles(0,math.pi/2,0),look.color,Enum.Material.Neon)
	sheath.Shape=Enum.PartType.Cylinder;sheath.Transparency=.55;sheath.Name="ChakraSheath"
	weldAll(root,{sheath})
	if not planted then
		if flatBlade then addTrail(root,Vector3.new(-.5,0,0),Vector3.new(.5,0,0),look.color,look.trail,.3,look.width)
		else addTrail(root,Vector3.new(0,.12,.25),Vector3.new(0,-.12,.25),look.color,look.trail,.3,look.width) end
	end
	decor.light=new("PointLight",{Color=look.color,Brightness=look.light,Range=if planted then 7 else 10,Shadows=false},root)
	local at=new("Attachment",{},root)
	if look.flame then
		table.insert(decor.emitters,emitter(at,{Name="ChakraFlame",Enabled=false,Texture=TEX.fire,Rate=70,Lifetime=NumberRange.new(.12,.26),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(40,40),
			Color=seq({{0,Color3.fromRGB(255,232,150)},{.5,look.color},{1,Color3.fromRGB(120,30,10)}}),LightEmission=1,Size=num({{0,.9},{1,.2}}),Transparency=num({{0,.2},{1,1}})}))
	elseif look.spark then
		table.insert(decor.emitters,emitter(at,{Name="ChakraSpark",Enabled=false,Texture=TEX.spark,Rate=90,Lifetime=NumberRange.new(.05,.12),Speed=NumberRange.new(3,9),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(look.core),LightEmission=1,Size=num({{0,.7},{1,0}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-400,400)}))
	end
	if look.ring and not planted then
		-- The wind blade cuts with a thin spinning ring around its line.
		local ring=block(self.folder,Vector3.new(.06,1.5,1.5),root.CFrame,look.core,Enum.Material.Neon)
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.45;ring.Name="WindRing";ring.Parent=model
		decor.ring=ring
	end
	if planted then for _,e in decor.emitters do e.Enabled=true end end
	return decor
end
-- A planted chakra blade (kind "point") or a stretched wire (kind
-- "tripwire"): built once where it rests.
function FX:planted(p)
	local tool=p.planted
	local origin=p.origin
	if tool=="wire" then
		local far=origin+p.direction*(p.range or 0)
		local model=new("Model",{Name="Tripwire"},self.folder)
		local root=block(model,Vector3.new(.15,.15,.15),CFrame.new(origin),STEEL,Enum.Material.Metal);root.Name="Root"
		local tip=block(model,Vector3.new(.15,.15,.15),CFrame.new(far),STEEL,Enum.Material.Metal);tip.Transparency=1
		local stake=FX.buildKunai(false);stake.Parent=model
		stake:PivotTo(CFrame.lookAt(origin+Vector3.new(0,.35,0),origin-Vector3.new(0,1,0)))
		local blade=FX.buildShuriken();blade.Parent=model
		blade:PivotTo(CFrame.lookAt(far,far+p.direction)*CFrame.Angles(math.rad(80),0,0))
		local a0=new("Attachment",{},root);local a1=new("Attachment",{},tip)
		local beam=new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.1,Width1=.1,Color=ColorSequence.new(Color3.fromRGB(226,230,238)),LightEmission=.6,FaceCamera=true,Segments=2},root)
		local light=new("PointLight",{Color=INFUSION.Lightning.color,Brightness=0,Range=8,Shadows=false},tip)
		model.PrimaryPart=root
		sparks(self.folder,far,Color3.fromRGB(255,236,200),6,10)
		return {data=p,model=model,root=root,static=true,hidden=false,beam=beam,light=light,wire=true,born=os.clock()}
	end
	local model=if tool=="shuriken" then FX.buildShuriken() elseif tool=="kunai" or tool=="marked" then FX.buildKunai(tool=="marked") else nil
	if not model then return nil end
	model.Parent=self.folder
	local root=model.PrimaryPart
	local into=p.direction
	local depth=if tool=="shuriken" then .25 else .45
	local cf=CFrame.lookAt(origin-into*depth,origin-into*depth+into)
	if tool=="shuriken" then cf=cf*CFrame.Angles(math.rad(80),0,0) end
	root.CFrame=cf
	local decor=if p.infusion then self:infuse(model,root,p.infusion,tool,true) else nil
	flash(self.folder,origin,lookOf(p.infusion).color,.5,3,.18,.2)
	return {data=p,model=model,root=root,static=true,hidden=false,decor=decor,born=os.clock()}
end
-- A planted object at rest: a slow chakra pulse; a wire crackles while charged.
function FX:restStep(entry)
	local p=entry.data
	if entry.wire then
		local charged=p.infusion=="Lightning"
		entry.beam.Color=ColorSequence.new(if charged then INFUSION.Lightning.core else Color3.fromRGB(214,218,226))
		entry.beam.Width0=if charged then .13+math.random()*.08 else .1;entry.beam.Width1=entry.beam.Width0
		entry.light.Brightness=if charged then 1+math.random()*2.5 else 0
		return
	end
	local decor=entry.decor
	if decor and decor.light then
		local pulse=.5+.5*math.sin((os.clock()-entry.born)*5)
		decor.light.Brightness=if decor.look.spark then decor.look.light*(.3+math.random()) else decor.look.light*(.35+pulse*.5)
	end
end
-- A blade knocked out of the air spins away and drops.
function FX:tumble(kind,position,direction,color)
	local model=if kind=="shuriken" or kind=="wire" then FX.buildShuriken() elseif kind=="kunai" or kind=="marked" or kind=="point" then FX.buildKunai(kind=="marked") else nil
	if not model then return end
	model.Parent=self.folder
	local root=model.PrimaryPart
	local away=(direction or Vector3.yAxis)
	if away.Magnitude<.05 then away=Vector3.yAxis end
	away=away.Unit
	root.CFrame=CFrame.lookAt(position,position+away)
	local finish=CFrame.new(position+away*5+Vector3.new(0,-2.5,0))*CFrame.Angles(math.random()*6,math.random()*6,math.random()*6)
	tween(root,.45,{CFrame=finish},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
	if color then sparks(self.folder,position,color,8,14) end
	task.delay(.35,function()
		for _,d in model:GetDescendants() do if d:IsA("BasePart") then tween(d,.2,{Transparency=1}) end end
	end)
	Debris:AddItem(model,.7)
end
-- A jagged lightning line between two points, flickering twice.
function FX:bolt(from,to,color)
	if not from or not to then return end
	local function strike()
		local points={from}
		local delta=to-from
		local side=delta:Cross(Vector3.yAxis)
		if side.Magnitude<.05 then side=Vector3.xAxis end
		side=side.Unit
		for k=1,4 do
			local jitter=side*(math.random()-.5)*1.2+Vector3.new(0,(math.random()-.5)*1.2,0)
			table.insert(points,from+delta*(k/5)+jitter)
		end
		table.insert(points,to)
		for k=1,#points-1 do
			local a,b=points[k],points[k+1]
			local length=(b-a).Magnitude
			if length>.05 then
				local seg=block(self.folder,Vector3.new(.12,.12,length),CFrame.lookAt(a:Lerp(b,.5),b),color,Enum.Material.Neon)
				seg.Transparency=.1
				tween(seg,.14,{Transparency=1,Size=Vector3.new(.03,.03,length)})
				Debris:AddItem(seg,.18)
			end
		end
	end
	strike()
	task.delay(.07,strike)
	sparks(self.folder,to,color,14,22)
end
-- Hands lit with chakra for the palm (Neji's body infusion).
function FX:handGlow(model,color,time)
	if not model then return end
	for _,name in {"RightHand","LeftHand"} do
		local hand=model:FindFirstChild(name)
		if hand then
			local at=new("Attachment",{Name="ChakraPalm"},hand)
			local e=emitter(at,{Texture=TEX.glow,Rate=0,Lifetime=NumberRange.new(.12,.2),Speed=NumberRange.new(0,1),
				Color=ColorSequence.new(color),LightEmission=1,Size=num({{0,1.4},{1,.4}}),Transparency=num({{0,.25},{1,1}}),LockedToPart=true})
			e:Emit(10)
			local light=new("PointLight",{Color=color,Brightness=3,Range=6,Shadows=false},at)
			tween(light,time,{Brightness=0})
			Debris:AddItem(at,time+.1)
		end
	end
end
-- Every chakra contact the server reports (impact.chakra); unknown kinds do
-- nothing. Called inside pcall from FX:impact.
function FX:chakraImpact(impact,folder)
	local kind=impact.chakra
	local at=impact.position
	local look=lookOf(impact.infusion)
	local color=look.color
	if kind=="cut" then
		-- The wind kunai cuts the blade in its lane: a bright slash across it.
		local across=(impact.direction or Vector3.zAxis):Cross(Vector3.yAxis)
		if across.Magnitude<.05 then across=Vector3.xAxis end
		local slash=block(self.folder,Vector3.new(.08,.08,3.2),CFrame.lookAt(at,at+across.Unit),look.core,Enum.Material.Neon)
		tween(slash,.18,{Transparency=1,Size=Vector3.new(.02,.02,4.2)});Debris:AddItem(slash,.22)
		sparks(self.folder,at,color,12,24)
		self:tumble(impact.kind,at,impact.tumble,nil)
	elseif kind=="deflect" or kind=="knock" then
		sparks(self.folder,at,color,10,22)
		self:tumble(if kind=="knock" then impact.tool or "kunai" else impact.kind,at,impact.tumble,nil)
	elseif kind=="swat" then
		flash(self.folder,at,HYUGA,.6,3.5,.14,.25)
		self:tumble(impact.kind,at,impact.tumble,HYUGA)
	elseif kind=="blown" then
		shockRing(self.folder,at,Color3.fromRGB(220,232,255),1,6,.2,impact.direction)
		self:tumble(impact.kind,at,impact.tumble,nil)
	elseif kind=="burn" or kind=="absorb" then
		flash(self.folder,at,INFUSION.Fire.color,.8,if kind=="absorb" then 6 else 3.5,.2,.2)
		sparks(self.folder,at,INFUSION.Fire.core,12,16)
		if kind=="absorb" then shockRing(self.folder,at,INFUSION.Fire.color,1.5,9,.25,impact.direction) end
	elseif kind=="intercept" then
		-- Both blades drop out of the meeting, to either side.
		self:tumble(impact.kind,at,impact.tumble,nil)
		if impact.tumble then self:tumble(impact.otherKind,at,Vector3.new(-impact.tumble.X,impact.tumble.Y,-impact.tumble.Z),nil) end
	elseif kind=="crush" then
		-- Reinforced steel leaning on a guard: a hard ring and chips off the guard.
		shockRing(self.folder,at,INFUSION.Reinforce.core,1.5,if impact.heavy then 12 else 7,.24,impact.direction)
		flash(self.folder,at,INFUSION.Reinforce.color,.8,if impact.heavy then 6 else 3.5,.16,.2)
		sparks(self.folder,at,INFUSION.Reinforce.core,impact.heavy and 18 or 10,20)
	elseif kind=="shock" or kind=="pointshock" or kind=="wirecharge" then
		local victim=modelFor(folder,impact.victim)
		local root=victim and victim:FindFirstChild("HumanoidRootPart")
		local center=if root then root.Position else at
		for k=1,3 do
			local offset=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*3
			self:bolt(center+offset,center-offset,INFUSION.Lightning.core)
		end
		flash(self.folder,center,INFUSION.Lightning.color,.8,4.5,.14,.2)
	elseif kind=="surge" or kind=="conduct" then
		self:bolt(impact.from or at,impact.to or at,INFUSION.Lightning.core)
		flash(self.folder,impact.to or at,INFUSION.Lightning.color,1,5,.16,.2)
	elseif kind=="ignite" then
		burst(self.folder,at,{Texture=TEX.fire,Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(4,9),SpreadAngle=Vector2.new(180,180),
			Color=seq({{0,Color3.fromRGB(255,232,150)},{.5,INFUSION.Fire.color},{1,Color3.fromRGB(80,24,10)}}),LightEmission=1,Size=num({{0,1.6},{1,.4}}),Transparency=num({{0,.2},{1,1}})},14)
	elseif kind=="gust" then
		shockRing(self.folder,at,INFUSION.Wind.core,1.5,9,.22,impact.direction)
		smokePuff(self.folder,at-Vector3.new(0,2.4,0),Color3.fromRGB(214,236,226),6,1.2)
	elseif kind=="plant" or kind=="stretch" then
		flash(self.folder,at,color,.4,2.4,.14,.3)
	elseif kind=="recover" then
		flash(self.folder,at+Vector3.new(0,1,0),color,.4,2.5,.2,.3)
		sparks(self.folder,at+Vector3.new(0,1,0),look.core,8,8)
	elseif kind=="deny" or kind=="expire" or kind=="fizzle" then
		smokePuff(self.folder,at,if kind=="fizzle" then Color3.fromRGB(176,184,198) else Color3.fromRGB(206,206,214),if kind=="fizzle" then 6 else 4,.7)
	elseif kind=="palm" then
		self:handGlow(modelFor(folder,impact.owner),HYUGA,.35)
	elseif kind=="throughguard" then
		shockRing(self.folder,at,HYUGA,1.5,10,.24,impact.direction)
		flash(self.folder,at,HYUGA,.6,5,.16,.2)
	elseif kind=="tenketsu" then
		flash(self.folder,at,HYUGA,.3,2,.12,.2)
	elseif kind=="tripwire" or kind=="wirecut" then
		sparks(self.folder,at,Color3.fromRGB(230,234,240),10,14)
	elseif kind=="wireburn" then
		local from,to=impact.from or at,impact.to or at
		for k=0,4 do flash(self.folder,from:Lerp(to,k/4),INFUSION.Fire.color,.6,3,.2,.25) end
	end
end
-- ------------------------------------------------------------------ persistent
-- Planted Flying Thunder God seals: a real three-pronged kunai in the surface
-- and a slowly pulsing seal formula around it.
function FX:seal(owner,actor,folder)
	local live={}
	for _,info in (actor and actor.seals) or {} do
		local key=tostring(owner)..":"..tostring(info.id)
		live[key]=true
		local entry=self.seals[key]
		if info.body then
			-- A seal riding on the opponent: a small glowing formula on the back.
			local model=folder and folder:FindFirstChild(info.body)
			local torso=model and (model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart"))
			if torso then
				if not entry then
					local glyph=new("Model",{Name="Body seal"},self.folder)
					local tone=if info.wind then WIND else MINATO
					local disc=block(glyph,Vector3.new(.03,1.5,1.5),torso.CFrame,tone,Enum.Material.Neon);disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.35
					local marks={}
					for i=0,5 do table.insert(marks,block(glyph,Vector3.new(.04,.08,.36),torso.CFrame,tone,Enum.Material.Neon)) end
					local light=new("PointLight",{Color=tone,Brightness=2,Range=7,Shadows=false},disc)
					entry={glyph=glyph,disc=disc,marks=marks,light=light,body=true,born=os.clock()}
					self.seals[key]=entry
					flash(self.folder,torso.Position,tone,.6,4,.2,.2)
				end
				local back=torso.CFrame*CFrame.new(0,.1,.62)
				local base=CFrame.lookAt(back.Position,back.Position+torso.CFrame.LookVector*-1)*CFrame.Angles(0,math.pi/2,0)
				entry.disc.CFrame=base
				for i,mark in entry.marks do
					mark.CFrame=base*CFrame.Angles((i-1)/6*math.pi*2+os.clock()*2,0,0)*CFrame.new(0,.5,0)
				end
				local pulse=.5+.5*math.sin((os.clock()-entry.born)*7)
				entry.disc.Transparency=.25+pulse*.3
				entry.light.Brightness=1.5+pulse*1.5
			end
		elseif info.surface then
			local surface=info.surface
			local normal=info.normal or Vector3.yAxis
			if not entry then
				-- A Yellow Flash return seal is written where he stood: no kunai
				-- was thrown there (IdentityFX draws its floor formula).
				local model=if info.wake then nil else FX.buildKunai(true)
				if model then
					model.Parent=self.folder
					local into=-normal
					local tilt=(if math.abs(normal.Y)>.7 then Vector3.xAxis else Vector3.yAxis)*.35
					local axis=(into+tilt).Unit
					model:PivotTo(CFrame.lookAt(surface-axis*.55,surface-axis*.55+axis))
				end
				local glyph=new("Model",{Name="Seal"},self.folder)
				local base=CFrame.lookAt(surface+normal*.03,surface+normal*1.03)*CFrame.Angles(0,math.pi/2,0)
				local disc=block(glyph,Vector3.new(.03,3.2,3.2),base,MINATO,Enum.Material.Neon);disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.8
				for i=0,5 do
					local a=i/6*math.pi*2
					local mark=block(glyph,Vector3.new(.04,.12,.7),base*CFrame.Angles(a,0,0)*CFrame.new(0,1.1,0),MINATO,Enum.Material.Neon)
					mark.Transparency=.35
				end
				local light=new("PointLight",{Color=MINATO,Brightness=1.5,Range=9,Shadows=false},disc)
				entry={model=model,glyph=glyph,disc=disc,light=light,surface=surface,born=os.clock()}
				self.seals[key]=entry
				flash(self.folder,surface,MINATO,.6,3.5,.2,.2)
			end
			local pulse=.5+.5*math.sin((os.clock()-entry.born)*4)
			-- The last seconds of a seal flicker so its expiry is readable.
			local fading=(info.remaining or 12)<2 and math.sin(os.clock()*30)>0
			entry.disc.Transparency=if fading then .95 else .72+pulse*.18
			entry.light.Brightness=if fading then .3 else 1+pulse*1.2
		end
	end
	for key,entry in self.seals do
		if string.sub(key,1,#tostring(owner)+1)==tostring(owner)..":" and not live[key] then
			if entry.model then
				for _,d in entry.model:GetDescendants() do if d:IsA("BasePart") then tween(d,.15,{Transparency=1}) end end
				Debris:AddItem(entry.model,.2)
			end
			Debris:AddItem(entry.glyph,.2)
			self.seals[key]=nil
		end
	end
end
-- Built-in Roblox sounds (shipped with every client, Mac and PC).
function FX:jumpSound(position) sound(anchorPart(self.folder,position),SOUND.jump,.28,1.1) end
function FX:getUpSound(position) sound(anchorPart(self.folder,position),SOUND.getUp,.25,1.15) end
-- (Studio check 28/10) the crater is drawn in relief by the server now; the
-- black star decal over it read as an ink print.
-- Burns are a soft blackening that fades out at its edge (Studio: the spiky
-- scorch star read as ink too), not a stamped shape.
local SCAR_ART={scorch={"soft",1.9,Color3.fromRGB(18,14,10)},char={"soft",1.7,Color3.fromRGB(20,22,34)},
	splinter={"crack",1.2,Color3.new(1,1,1)}}
function FX.dressScar(part)
	if not part:IsA("BasePart") or string.sub(part.Name,1,5)~="Scar " then return end
	local art=SCAR_ART[string.sub(part.Name,6)]
	if not art or (art[1]~="soft" and not Kit.has(art[1])) then return end
	task.defer(function()
		if not part.Parent then return end
		local holder=Instance.new("Part")
		holder.Name="ScarArt";holder.Anchored=true;holder.CanCollide=false;holder.CanQuery=false;holder.CanTouch=false
		holder.CastShadow=false;holder.Transparency=1;holder.Parent=part
		local decal=Instance.new("Decal");decal.Face=Enum.NormalId.Top
		if art[1]=="soft" then decal.Texture=TEX.glow;decal.Transparency=.08 else decal.TextureContent=Kit.content(art[1]) end
		decal.Color3=art[3];decal.Parent=holder
		local spin=math.random()*math.pi*2
		local function fit()
			-- The scar's X axis is the surface normal (a flat cylinder).
			local cf=part.CFrame
			local normal=cf.RightVector
			local side=if math.abs(normal.Y)>.9 then Vector3.xAxis else Vector3.yAxis
			local right=side:Cross(normal).Unit
			local size=math.max(part.Size.Y,part.Size.Z)*art[2]
			holder.Size=Vector3.new(size,.05,size)
			holder.CFrame=CFrame.fromMatrix(cf.Position+normal*.03,right,normal)*CFrame.Angles(0,spin,0)
			part.Transparency=1
		end
		fit()
		part:GetPropertyChangedSignal("Size"):Connect(fit)
		part:GetPropertyChangedSignal("Transparency"):Connect(function() if part.Transparency<1 then part.Transparency=1 end end)
	end)
end
function FX:hazardsStep(data)
	local live={}
	for _,h in data.hazards or {} do
		local key=string.format("%s:%.1f:%.1f:%.1f",tostring(h.kind),h.position.X,h.position.Y,h.position.Z)
		live[key]=true
		local entry=self.hazards[key]
		-- A family zone (mist, insects, water, shadow...) has its own ground
		-- look (FamilyFX); every other hazard is fire.
		if not entry and h.look and FX.hazardBuild then
			entry=FX.hazardBuild(self,h)
			if entry then self.hazards[key]=entry end
		end
		if entry and entry.family then
			if FX.hazardUpdate then FX.hazardUpdate(entry,h) end
			continue
		end
		if not entry then
			local floor=floorUnder(self,h.position,3,14)
			local at=if floor then floor.Position else h.position
			local holder=anchorPart(self.folder,at);holder.Transparency=1;holder.Size=Vector3.new(h.radius*1.6,.2,h.radius*1.6)
			local e=new("ParticleEmitter",{Texture=TEX.fire,Rate=60,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(3,7),
				SpreadAngle=Vector2.new(12,12),EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Box,
				Color=seq({{0,Color3.fromRGB(255,220,140)},{.5,Color3.fromRGB(255,110,40)},{1,Color3.fromRGB(90,30,12)}}),LightEmission=1,LightInfluence=0,
				Size=num({{0,1.4},{.4,2.4},{1,.4}}),Transparency=num({{0,.2},{1,1}}),RotSpeed=NumberRange.new(-80,80),Rotation=NumberRange.new(0,360)},holder)
			local light=new("PointLight",{Color=Color3.fromRGB(255,130,60),Brightness=3,Range=h.radius*3,Shadows=false},holder)
			entry={holder=holder,emitter=e,light=light}
			self.hazards[key]=entry
		end
		-- Readable, not noisy: a small burning patch (a chakra blade's) flickers
		-- with fewer flames than a Great Fireball's lane (ChakraFX marks its edge).
		local scale=math.clamp(h.radius/4.5,.4,1)
		entry.light.Brightness=(2.4+math.sin(os.clock()*22)*.6+math.sin(os.clock()*9)*.5)*scale
		entry.emitter.Rate=(if h.remaining<.4 then 25 else 60)*scale
	end
	for key,entry in self.hazards do
		if not live[key] and entry.family then
			FX.hazardFinish(entry);self.hazards[key]=nil
		elseif not live[key] then
			entry.emitter.Enabled=false;tween(entry.light,.3,{Brightness=0})
			Debris:AddItem(entry.holder,1);self.hazards[key]=nil
		end
	end
end
-- Battle wear: as health drops (75 / 50 / 25 %), dirt, scuffs, small grazes
-- and darkened cloth accumulate on the body. Feedback, not gore.
local WEAR={
	-- {body part, size, offset, kind}
	{ {"UpperTorso",Vector3.new(.7,.5,.05),CFrame.new(.35,-.2,-.53),"dirt"},{"RightUpperLeg",Vector3.new(.5,.6,.05),CFrame.new(0,-.1,-.5),"dirt"},{"LeftLowerArm",Vector3.new(.45,.4,.05),CFrame.new(0,0,-.43),"dirt"} },
	{ {"UpperTorso",Vector3.new(.55,.35,.05),CFrame.new(-.4,.35,.53),"dirt"},{"LeftUpperLeg",Vector3.new(.55,.45,.05),CFrame.new(.1,.2,-.5),"tear"},{"Head",Vector3.new(.18,.06,.03),CFrame.new(.42,-.18,-.78),"graze"},{"RightUpperArm",Vector3.new(.5,.12,.05),CFrame.new(0,-.35,-.45),"tear"} },
	{ {"LowerTorso",Vector3.new(.8,.3,.05),CFrame.new(-.2,0,-.53),"dirt"},{"RightLowerArm",Vector3.new(.2,.08,.03),CFrame.new(.05,.1,-.44),"graze"},{"LeftLowerLeg",Vector3.new(.5,.5,.05),CFrame.new(0,.2,-.45),"dirt"},{"UpperTorso",Vector3.new(.3,.5,.05),CFrame.new(.1,.1,-.535),"tear"} },
}
local WEAR_LOOK={dirt={Color3.fromRGB(96,78,58),.35},tear={Color3.fromRGB(40,34,32),.25},graze={Color3.fromRGB(150,46,40),.2}}
function FX:wear(model,actor,aura)
	local ratio=(actor.health or 1)/math.max(1,actor.maxHealth or 1)
	local level=if ratio<=.25 then 3 elseif ratio<=.5 then 2 elseif ratio<=.75 then 1 else 0
	aura.wear=aura.wear or 0
	-- A new round restores health on the same bodies: the wear starts over
	-- instead of opening round two fully worn (and unable to build again).
	if aura.wear>0 and level==0 and ratio>=.99 then
		for _,p in model:GetDescendants() do if p.Name=="BattleWear" then p:Destroy() end end
		for part,color in aura.cloth or {} do if part.Parent then part.Color=color end end
		aura.cloth=nil;aura.wear=0
	end
	while aura.wear<level do
		aura.wear+=1
		for _,spec in WEAR[aura.wear] do
			local body=model:FindFirstChild(spec[1])
			if body and body:IsA("BasePart") then
				local look=WEAR_LOOK[spec[4]]
				local mark=block(model,spec[2],body.CFrame*spec[3],look[1],Enum.Material.SmoothPlastic)
				mark.Name="BattleWear";mark.Anchored=false;mark.Massless=true;mark.Transparency=look[2];mark.CastShadow=false
				new("WeldConstraint",{Part0=body,Part1=mark},mark)
			end
		end
		if aura.wear==3 then
			-- Low health: cloth looks dusty and darker.
			for _,p in model:GetChildren() do
				if p:IsA("BasePart") and p.Name~="HumanoidRootPart" and p.Name~="BattleWear" and p.Transparency<1 and p.Material~=Enum.Material.Neon then
					aura.cloth=aura.cloth or {};aura.cloth[p]=aura.cloth[p] or p.Color
					p.Color=p.Color:Lerp(Color3.fromRGB(110,92,74),.14)
				end
			end
		end
	end
end
-- Per-fighter identity layer: Minato's speed trail and Rasengan, Itachi's
-- Sharingan glow and fire breath. Restrained: it switches on only for the
-- moments it describes.
function FX:fighter(model,actor,dt)
	if not model or not actor then return end
	local aura=self.auras[model]
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not aura then
		aura={}
		self.auras[model]=aura
		local minato=actor.fighterId=="Flashstep"
		local color=if minato then MINATO elseif actor.fighterId=="GentleFist" then HYUGA elseif actor.fighterId=="Lion" then LION else Color3.fromRGB(170,30,48)
		local veins={}
		for _,p in model:GetChildren() do if p.Name=="ByakuganVein" then table.insert(veins,p) end end
		aura.veins=veins
		-- The dash streak is each fighter's (movement overhaul, brief §12), not
		-- one shared red: its tone, how long it lingers, how solid and how wide.
		local dash=DASH_STREAK[actor.fighterId]
		aura.trail=if dash then addTrail(root,Vector3.new(0,1.6,.3),Vector3.new(0,-1.9,.3),dash.color or color,dash.life,dash.alpha,dash.width)
			else addTrail(root,Vector3.new(0,1.6,.3),Vector3.new(0,-1.9,.3),color,if minato then .16 else .12,.62,1)
		aura.trail.Enabled=false
		local irises={}
		for _,p in model:GetChildren() do if p.Name=="Iris" then table.insert(irises,p) end end
		aura.irises=irises
		local head=model:FindFirstChild("Head")
		local marks={}
		for _,p in model:GetChildren() do if p.Name=="CurseMark" then table.insert(marks,p) end end
		aura.marks=marks
		if head and (actor.fighterId=="Mirage" or actor.fighterId=="Lion") then
			aura.eyeLight=new("PointLight",{Color=Color3.fromRGB(255,40,40),Brightness=0,Range=5,Shadows=false},head)
		end
	end
	self:wear(model,actor,aura)
	local speed=actor.speed or 0
	local fast=actor.state=="Dodging" or actor.state=="Pursuit" or actor.state=="Rush" or (actor.awaken or 0)>0 or actor.flash or (actor.fighterId=="Flashstep" and speed>34)
	aura.trail.Enabled=fast==true and (actor.health or 1)>0
	-- Itachi's Sharingan is always awake; it flares while he reads, casts,
	-- counters, or during the intro.
	if (actor.fighterId=="Mirage" or actor.fighterId=="Lion") and aura.irises then
		local lit=(actor.read or 0)>0 or (actor.counter or 0)>0 or actor.castId=="MirageCast" or actor.castId=="Read" or actor.castId=="FireBloom"
			or actor.castId=="PhoenixFlower" or actor.castId=="Chidori" or (actor.intro or 0)>0 or (actor.awaken or 0)>0
		for _,iris in aura.irises do
			iris.Material=Enum.Material.Neon
			iris.Color=if lit then Color3.fromRGB(255,36,36) else Color3.fromRGB(205,18,28)
		end
		if aura.eyeLight then aura.eyeLight.Brightness=if lit then 2.2 else .5 end
	end
	-- Awakening: a chakra mantle that rises off the body for the whole state.
	local awake=(actor.awaken or 0)>0 and (actor.health or 1)>0
	if awake and not aura.mantle then
		local torso=model:FindFirstChild("UpperTorso") or root
		local tone=if actor.fighterId=="Flashstep" then MINATO elseif actor.fighterId=="GentleFist" then HYUGA elseif actor.fighterId=="Lion" then CURSE else Color3.fromRGB(230,40,50)
		local at=new("Attachment",{Name="AwakenMantle"},torso)
		local e=new("ParticleEmitter",{Texture=TEX.fire,Rate=55,Lifetime=NumberRange.new(.35,.6),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(30,30),
			EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Box,Color=ColorSequence.new(tone),LightEmission=1,LightInfluence=0,
			Size=num({{0,1.6},{.5,1.2},{1,0}}),Transparency=num({{0,.45},{1,1}}),Acceleration=Vector3.new(0,6,0)},at)
		local light=new("PointLight",{Color=tone,Brightness=2.5,Range=12,Shadows=false},at)
		aura.mantle={attachment=at,emitter=e,light=light}
	elseif not awake and aura.mantle then
		aura.mantle.emitter.Enabled=false
		Debris:AddItem(aura.mantle.attachment,1)
		aura.mantle=nil
	end
	for _,mark in aura.marks or {} do mark.Transparency=if awake then 0 else 1 end
	-- Bound: wire coiled around the chest and arms while the bind holds.
	-- (Held by Gaara's sand: SandFX draws the coffin instead of the wire.)
	local bound=actor.bound==true and (actor.health or 1)>0 and actor.opponentFighter~="Sand"
	-- (Partie 1 feedback: "the wire changes a little, but it stays light".)
	-- Reference: Sasuke vs Itachi, the Windmill Shuriken bind (Shippuden 136)
	-- and Storm 4's wire grabs: many thin turns that snap TIGHT around the
	-- chest and arms (a visible constriction, not rings appearing), and the
	-- wire stays taut from the binder's hand to the body for the whole hold.
	if bound and not aura.binding then
		local torso=model:FindFirstChild("UpperTorso") or root
		local holder=new("Model",{Name="Binding"},self.folder)
		local coils={}
		for k=0,5 do
			local tilt=math.rad((k%2==0 and 1 or -1)*7)
			local offset=CFrame.new(0,-.75+k*.3,0)*CFrame.Angles(tilt,0,math.pi/2)
			local coil=block(holder,Vector3.new(.06,3.6,3.6),torso.CFrame*offset,Color3.fromRGB(214,218,226),Enum.Material.Metal)
			coil.Shape=Enum.PartType.Cylinder;coil.Transparency=.05
			table.insert(coils,{part=coil,offset=offset})
		end
		-- The taut line back to the binder's hand (the other fighter).
		local beam
		local binder
		for _,m in (self.fighters and self.fighters:GetChildren() or {}) do if m~=model and m:IsA("Model") then binder=m end end
		local hand=binder and binder:FindFirstChild("RightHand")
		if hand then
			local a0=new("Attachment",{Name="BindHand"},hand)
			local a1=new("Attachment",{Name="BindBody"},torso)
			beam=new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.05,Width1=.05,Color=ColorSequence.new(Color3.fromRGB(230,234,242)),LightEmission=.7,FaceCamera=true,Segments=8,CurveSize0=-.4,CurveSize1=.4},holder)
			aura.bindAttachments={a0,a1}
		end
		aura.binding={holder=holder,coils=coils,torso=torso,born=os.clock(),beam=beam}
		sound(torso,SOUND.whoosh,.55,2.2)
	elseif not bound and aura.binding then
		aura.binding.holder:Destroy()
		for _,att in aura.bindAttachments or {} do att:Destroy() end
		aura.bindAttachments=nil
		aura.binding=nil
	end
	if aura.binding then
		-- Snap tight in 0.12 s (diameter 3.6 -> 2.35), then a faint strain.
		local t=os.clock()-aura.binding.born
		local u=math.clamp(t/.12,0,1)
		local d=3.6-(1.25*(1-(1-u)^3))+.04*math.sin(t*38)*(1-u)
		for _,c in aura.binding.coils do
			c.part.Size=Vector3.new(.06,d,d)
			c.part.CFrame=aura.binding.torso.CFrame*c.offset
		end
		if aura.binding.beam then
			-- taut once tight: the sag goes out of the line with the constriction
			aura.binding.beam.CurveSize0=-.4*(1-u);aura.binding.beam.CurveSize1=.4*(1-u)
		end
	end
	-- Sasuke: the Chidori crackles in the right hand from the charge to the thrust.
	local chidori=(actor.castId=="Chidori" and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive"))
		or (actor.attackName=="ChidoriThrust" and (actor.state=="Startup" or actor.state=="Active"))
		-- (Embodiment) held in the hand as a state, and through the strike that releases it.
		or (actor.bodyState~=nil and (actor.bodyState.id=="Chidori" or actor.bodyState.id=="LightningBlade"))
		or (actor.attackVariant=="Chidori" and (actor.state=="Startup" or actor.state=="Active"))
	if chidori and not aura.chidori and (actor.health or 1)>0 then
		local hand=model:FindFirstChild("RightHand") or root
		local at=new("Attachment",{Name="Chidori"},hand)
		local e=new("ParticleEmitter",{Texture=TEX.spark,Rate=220,Lifetime=NumberRange.new(.05,.14),Speed=NumberRange.new(6,16),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(Color3.fromRGB(190,220,255)),LightEmission=1,LightInfluence=0,Size=num({{0,1.1},{1,0}}),Transparency=num({{0,0},{1,1}}),
			Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-400,400)},at)
		local core=new("ParticleEmitter",{Texture=TEX.glow,Rate=40,Lifetime=NumberRange.new(.08,.12),Speed=NumberRange.new(0,0),
			Color=ColorSequence.new(Color3.fromRGB(220,236,255)),LightEmission=1,LightInfluence=0,Size=num({{0,1.4},{1,1.0}}),Transparency=num({{0,.2},{1,1}})},at)
		local light=new("PointLight",{Color=Color3.fromRGB(150,190,255),Brightness=1.6,Range=8,Shadows=false},at)
		aura.chidori={attachment=at,emitter=e,core=core,light=light}
		if Kit.has("lightning") then
			-- (Reference quality) the birds: arcs of lightning thrown out of the
			-- hand, flickering through our own bolt sheet.
			aura.chidori.bolts=Kit.stream(at,"lightning",{Rate=45,Lifetime=NumberRange.new(.05,.1),Speed=NumberRange.new(0,0),
				FlipbookMode=Enum.ParticleFlipbookMode.Random,
				Color=ColorSequence.new(Color3.fromRGB(170,210,255)),LightEmission=1,Size=num({{0,4.2},{1,5.6}}),
				Transparency=num({{0,0},{1,.2}}),Rotation=NumberRange.new(0,360)})
			-- A hard white-blue core in the palm, pulsing.
			local ball=block(self.folder,Vector3.one*1.2,hand.CFrame,Color3.fromRGB(214,234,255),Enum.Material.Neon)
			ball.Shape=Enum.PartType.Ball;ball.Transparency=.1;ball.Name="ChidoriCore"
			aura.chidori.ball=ball;aura.chidori.hand=hand
			aura.chidori.light.Range=16
		end
		sound(hand,SOUND.whoosh,.5,2.6)
		sound(hand,SOUND.electric,.55,1)
		aura.chidori.crackleAt=os.clock()
	elseif not chidori and aura.chidori then
		aura.chidori.emitter.Enabled=false;aura.chidori.core.Enabled=false
		Kit.stop(aura.chidori.bolts)
		if aura.chidori.ball then aura.chidori.ball:Destroy() end
		Debris:AddItem(aura.chidori.attachment,.4)
		aura.chidori=nil
	end
	if aura.chidori then
		aura.chidori.light.Brightness=2+math.random()*3
		-- The birds: it keeps crackling while it is held.
		if os.clock()-(aura.chidori.crackleAt or 0)>.55 and aura.chidori.hand then
			aura.chidori.crackleAt=os.clock()
			sound(aura.chidori.hand,SOUND.electric,.32,.9+math.random()*.3)
		end
		if aura.chidori.ball and aura.chidori.hand then
			local size=1+math.random()*.5
			aura.chidori.ball.Size=Vector3.one*size
			aura.chidori.ball.CFrame=aura.chidori.hand.CFrame*CFrame.new(0,-.7,0)
		end
		-- Carried at a run, it tears at the ground beside him: a crackle to the
		-- floor and a scored line now and then.
		local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
		if Kit.has("lightning") and speed>10 and not actor.airborne and os.clock()-(aura.chidori.scoreAt or 0)>.09 then
			aura.chidori.scoreAt=os.clock()
			local hand=aura.chidori.attachment.WorldPosition
			local floor=floorUnder(self,hand,1,6)
			if floor then
				self:bolt(hand,floor.Position,Color3.fromRGB(220,236,255))
				Kit.ground(self.folder,floor.Position,floor.Normal,"scorch",2.2,.6,.5,Color3.new(1,1,1),.35)
				Kit.dust(self.folder,floor.Position,2,.9,Color3.fromRGB(200,190,170),4)
			end
		end
	end
	-- Neji: the Byakugan veins stand out while it is focused; the Rotation dome.
	if actor.fighterId=="GentleFist" then
		local focused=(actor.intro or 0)>0 or actor.castId~=nil or (actor.counter or 0)>0 or actor.rotation==true or (actor.awaken or 0)>0
		for _,vein in aura.veins or {} do vein.Transparency=if focused then 0 else 1 end
		local dome=aura.dome
		if actor.rotation and not dome then
			local holder=new("Model",{Name="Rotation"},self.folder)
			local shell=block(holder,Vector3.one*12,root.CFrame,Color3.fromRGB(200,220,255),Enum.Material.Glass);shell.Shape=Enum.PartType.Ball;shell.Transparency=.86
			local inner=block(holder,Vector3.one*9,root.CFrame,Color3.fromRGB(236,244,255),Enum.Material.ForceField);inner.Shape=Enum.PartType.Ball;inner.Transparency=.55
			local bands={}
			for k=1,3 do
				local band=block(holder,Vector3.new(.12,12.4,12.4),root.CFrame,HYUGA,Enum.Material.Neon);band.Shape=Enum.PartType.Cylinder;band.Transparency=.7
				table.insert(bands,band)
			end
			local light=new("PointLight",{Color=HYUGA,Brightness=4,Range=18,Shadows=false},shell)
			dome={holder=holder,shell=shell,inner=inner,bands=bands,light=light,born=os.clock()}
			aura.dome=dome
			sound(shell,SOUND.whoosh,.5,.45)
		end
		if dome then
			if actor.rotation then
				local grow=math.clamp((os.clock()-dome.born)/.12,.3,1)
				local center=root.CFrame*CFrame.new(0,-.6,0)
				dome.shell.CFrame=center;dome.shell.Size=Vector3.one*12*grow
				dome.inner.CFrame=center*CFrame.Angles(0,os.clock()*20,0);dome.inner.Size=Vector3.one*9*grow
				for k,band in dome.bands do
					band.CFrame=center*CFrame.Angles(0,os.clock()*(18+k*4),0)*CFrame.Angles(0,0,math.rad(60*k))
					band.Size=Vector3.new(.12,12.4*grow,12.4*grow)
				end
			else
				aura.dome=nil
				for _,d in dome.holder:GetDescendants() do if d:IsA("BasePart") then tween(d,.18,{Transparency=1,Size=d.Size*1.15}) end end
				Debris:AddItem(dome.holder,.25)
			end
		end
	end
	-- Rasengan forms in the right hand during the channel and stays through the strike.
	local rasengan=(actor.castId=="BurstStrike" and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive"))
		or ((actor.attackVariant=="Rasengan" or actor.attackVariant=="RasenganDrop") and (actor.state=="Startup" or actor.state=="Active"))
		-- (User 28/10) a held Rasengan stays in the palm while he runs with it.
		or (actor.bodyState~=nil and (actor.bodyState.id=="BurstStrike" or actor.bodyState.id=="CloneRasengan"))
	local orb=self.rasengan[model]
	local hand=model:FindFirstChild("RightHand")
	if rasengan and hand then
		if not orb then
			local holder=new("Model",{Name="Rasengan"},self.folder)
			local core=block(holder,Vector3.one*.6,hand.CFrame,Color3.fromRGB(235,250,255),Enum.Material.Neon);core.Shape=Enum.PartType.Ball
			local shell=block(holder,Vector3.one*1.5,hand.CFrame,Color3.fromRGB(110,190,255),Enum.Material.Neon);shell.Shape=Enum.PartType.Ball;shell.Transparency=.45
			local bands={}
			for i=1,3 do
				local band=block(holder,Vector3.new(.06,1.7,1.7),hand.CFrame,Color3.fromRGB(190,230,255),Enum.Material.Neon)
				band.Shape=Enum.PartType.Cylinder;band.Transparency=.55;table.insert(bands,band)
			end
			local at=new("Attachment",{},core)
			local e=new("ParticleEmitter",{Texture=TEX.vortex,Rate=40,Lifetime=NumberRange.new(.15,.3),Speed=NumberRange.new(0,1),
				Color=ColorSequence.new(Color3.fromRGB(150,210,255)),LightEmission=1,LightInfluence=0,Size=num({{0,1.6},{1,.4}}),
				Transparency=num({{0,.3},{1,1}}),RotSpeed=NumberRange.new(400,700),Rotation=NumberRange.new(0,360),LockedToPart=true},at)
			new("PointLight",{Color=Color3.fromRGB(120,190,255),Brightness=3,Range=12,Shadows=false},core)
			orb={holder=holder,core=core,shell=shell,bands=bands,emitter=e,born=os.clock()}
			self.rasengan[model]=orb
			sound(core,SOUND.whoosh,.3,.5)
		end
		local grow=math.clamp((os.clock()-orb.born)/.25,.2,1)
		local center=hand.CFrame*CFrame.new(0,-.75,-.35)
		orb.core.CFrame=center;orb.core.Size=Vector3.one*.65*grow
		orb.shell.CFrame=center;orb.shell.Size=Vector3.one*1.55*grow*(1+math.sin(os.clock()*40)*.05)
		for i,band in orb.bands do
			band.CFrame=center*CFrame.Angles(os.clock()*(9+i*3),os.clock()*(7-i*2),i)
			band.Size=Vector3.new(.06,1.75*grow,1.75*grow)
		end
	elseif orb then
		self.rasengan[model]=nil
		orb.emitter.Enabled=false
		flash(self.folder,orb.core.Position,Color3.fromRGB(170,220,255),1.5,5,.2,.2)
		orb.holder:Destroy()
	end
	-- Katon: embers gather at the mouth during the hand signs, then the breath.
	-- (Reference quality) Held, a ball of fire swells in front of the mouth
	-- with the charge, and goes out with the breath.
	do
		local head=model:FindFirstChild("Head")
		local casting=(actor.castId=="FireBloom" or actor.castId=="PhoenixFlower") and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive")
		if casting and head then
			if not aura.mouth then
				local at=new("Attachment",{Position=Vector3.new(0,-.25,-.8)},head)
				aura.mouthAt=at
				aura.mouth=new("ParticleEmitter",{Texture=TEX.fire,Rate=0,Lifetime=NumberRange.new(.15,.3),Speed=NumberRange.new(4,10),
					SpreadAngle=Vector2.new(18,18),EmissionDirection=Enum.NormalId.Front,Color=seq({{0,Color3.fromRGB(255,230,150)},{1,Color3.fromRGB(255,90,30)}}),
					LightEmission=1,LightInfluence=0,Size=num({{0,.6},{1,1.6}}),Transparency=num({{0,.2},{1,1}})},at)
				if Kit.has("fire") then
					aura.mouthCel=Kit.stream(at,"fire",{Rate=0,Lifetime=NumberRange.new(.18,.32),Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(14,14),front=true,
						Color=ColorSequence.new(Color3.new(1,1,1)),Size=num({{0,.8},{1,2.6}}),Transparency=num({{0,0},{.85,0},{1,1}}),Rotation=NumberRange.new(0,360)})
				end
				aura.mouthLight=new("PointLight",{Color=Color3.fromRGB(255,140,60),Brightness=0,Range=10,Shadows=false},at)
			end
			if not aura.orb or not aura.orb.Parent then
				local orb=block(self.folder,Vector3.one*.2,CFrame.new(),Color3.fromRGB(255,214,120),Enum.Material.Neon)
				orb.Shape=Enum.PartType.Ball;orb.Transparency=1;orb.Name="KatonCharge"
				aura.orb=orb
				local core=new("Attachment",{},orb)
				aura.orbFlames=Kit.stream(core,"fire",{Rate=0,Lifetime=NumberRange.new(.25,.4),Speed=NumberRange.new(1,3),
					SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(Color3.new(1,1,1)),
					Size=num({{0,1},{1,1.6}}),Transparency=num({{0,0},{.85,0},{1,1}}),Rotation=NumberRange.new(0,360)})
			end
			local breathing=actor.state=="TechniqueActive"
			local charge=actor.techCharge or 0
			aura.mouth.Rate=if breathing then 90 else 14+40*charge
			Kit.setRate(aura.mouthCel,if breathing then 40 else 4+10*charge)
			aura.mouthLight.Brightness=if breathing then 4 else 1.2+3*charge
			aura.mouthLight.Range=10+12*charge
			if charge>0 and not breathing and aura.orb then
				local size=.7+1.5*charge+math.sin(os.clock()*30)*.08
				aura.orb.Size=Vector3.one*size*.55
				aura.orb.CFrame=aura.mouthAt.WorldCFrame*CFrame.new(0,0,-(.5+size*.6))
				aura.orb.Transparency=.25
				Kit.setRate(aura.orbFlames,20+30*charge)
				Kit.setSize(aura.orbFlames,num({{0,size*.8},{1,size*1.2}}))
			elseif aura.orb then
				aura.orb.Transparency=1;Kit.setRate(aura.orbFlames,0)
			end
		elseif aura.mouth then
			aura.mouth.Rate=0;aura.mouthLight.Brightness=0;Kit.setRate(aura.mouthCel,0)
			if aura.orb then aura.orb.Transparency=1;Kit.setRate(aura.orbFlames,0) end
		end
	end
	self:identity(model,actor,aura)
end
-- ----------------------------------------------------------------- crowd
-- The stands react to the fight: big moments bring spectators to their feet,
-- banners sway in the wind. Local-only motion of anchored decor.
function FX:crowdOf(folder)
	if self.crowdFolder==folder then return end
	self.crowdFolder=folder
	self.crowd={};self.banners={}
	local yard=folder and folder:FindFirstChild("Courtyard")
	local decor=yard and yard:FindFirstChild("Decor")
	if not decor then return end
	for _,m in decor:GetChildren() do
		if m.Name=="SpectatorFigure" then
			local parts={}
			for _,p in m:GetChildren() do if p:IsA("BasePart") then table.insert(parts,{part=p,base=p.CFrame}) end end
			table.insert(self.crowd,{parts=parts,phase=math.random()*math.pi*2,speed=7+math.random()*4})
		elseif m.Name=="Banner" or m.Name=="Pavilion banner" then
			table.insert(self.banners,{part=m,base=m.CFrame,phase=math.random()*math.pi*2})
		end
	end
end
function FX:cheer(strength)
	self.cheerStart=os.clock()
	self.cheerStrength=math.max(strength,if self.cheerStart and os.clock()-self.cheerStart<.4 then self.cheerStrength or 0 else 0)
end
function FX:ambient(dt)
	local t=os.clock()
	for _,b in self.banners or {} do
		if b.part.Parent then
			local h=b.part.Size.Y
			local angle=math.rad(math.sin(t*1.3+b.phase)*3+math.sin(t*3.1+b.phase)*1)
			b.part.CFrame=b.base*CFrame.new(0,h/2,0)*CFrame.Angles(angle,0,0)*CFrame.new(0,-h/2,0)
		end
	end
	local elapsed=t-(self.cheerStart or -10)
	local active=elapsed<1.1
	if active or self.cheering then
		local strength=(self.cheerStrength or 0)*(1-math.clamp((elapsed-.6)/.5,0,1))
		for _,fig in self.crowd or {} do
			local lift=if active then math.abs(math.sin(t*fig.speed+fig.phase))*.75*strength else 0
			for _,entry in fig.parts do
				if entry.part.Parent then entry.part.CFrame=entry.base+Vector3.new(0,lift,0) end
			end
		end
		self.cheering=active
	end
end
function FX:update(data,dt,folder)
	self.fighters=folder
	if not data or data.phase~="Duel" then
		if self.epoch~=nil and data and data.phase=="Selection" then self.epoch=nil;self:reset() end
		self:stepProjectiles(dt)
		for _,layer in FX.layers do if layer.step then layer.step(self,data,dt,folder) end end
		return
	end
	self:stepProjectiles(dt)
	self:hazardsStep(data)
	-- Layers that draw from the whole snapshot (GaleFX: the zones, each kind its own way).
	for _,layer in FX.layers do if layer.frame then layer.frame(self,data,dt,folder) end end
	self:crowdOf(folder)
	self:ambient(dt)
	for _,key in {"human","bot"} do
		local actor=data[key]
		if actor then
			actor.intro=data.intro
			local other=data[if key=="human" then "bot" else "human"]
			actor.opponentFighter=other and other.fighterId
			self:seal(actor.id or key,actor,folder)
			local model=folder and folder:FindFirstChild(actor.id or "")
			self:fighter(model,actor,dt)
			for _,layer in FX.layers do if layer.fighter then layer.fighter(self,model,actor,dt) end end
		end
	end
	-- Layers that draw across the scene once per frame (ChakraFX).
	for _,layer in FX.layers do if layer.step then layer.step(self,data,dt,folder) end end
	-- (Audit 29/10) The layers' whole-duel frame already ran above: a second
	-- pass here stepped GaleFX, IdentityFX and the Wave1 shroud twice a frame
	-- (double cost, wind lanes at double speed).
end
-- Gaara's sand (projectiles, shield, flicker, coffin, Desert Wave, lashes).
require(script.Parent.SandFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Rock Lee (the Fifth Gate, lotuses, deflecting kick, Rupture, his speed).
require(script.Parent.LeeFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Systemic chakra, the player-facing layer (planted marks, the wire, clashes, bodies).
require(script.Parent.ChakraFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- CORE4 identity seen in play (Neji's palms and points, Minato's seals and
-- chains, Itachi's reads and geometry, Sasuke's curse and Chidori).
require(script.Parent.IdentityFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,sparks=sparks,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Family objects of the roster breadth pass (Shared/Looks): every kind gets
-- its own model, flight, contact and ground look; buffs and slows on bodies.
require(script.Parent.FamilyFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,sparks=sparks,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Roster 20 batches: their own drawing (most of it is FamilyFX's).
for _,name in {"Wave1FX","Wave2FX","Wave3FX","Wave4FX"} do
	require(script.Parent[name]).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
		smokePuff=smokePuff,sparks=sparks,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
end
-- Naruto (clone puffs, the Rasengan shaped with a clone, the barrage, the Nine-Tails cloak).
require(script.Parent.NarutoFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Chakra into the next action (hold the modifier): the load, infused limbs, natures.
require(script.Parent.ChakraFlowFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,sparks=sparks,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
-- Temari (the iron fan, Kamaitachi, Kamatari, wind lanes and updrafts, gusts).
require(script.Parent.GaleFX).install(FX,{new=new,block=block,tween=tween,sound=sound,flash=flash,shockRing=shockRing,burst=burst,
	smokePuff=smokePuff,floorUnder=floorUnder,anchorPart=anchorPart,weldAll=weldAll,num=num,seq=seq,TEX=TEX,SOUND=SOUND,BUILD=BUILD})
return FX
