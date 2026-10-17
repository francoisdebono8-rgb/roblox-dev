-- Family objects seen in play (roster breadth pass): every projectile kind of
-- Shared/Looks gets a real model (never the kunai fallback), its flight pose,
-- its contact burst and, for zones, a ground look; buffs, counter stances,
-- drains and slows show on the bodies. Installed by Effects like SandFX.
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Looks=require(Shared.Looks)
local Fighters=require(Shared.Fighters)
local FamilyFX={}
-- Studio/test switch: drawing errors surface instead of being swallowed.
FamilyFX.strict=false

local function c3(t) return Color3.fromRGB(t[1],t[2],t[3]) end

function FamilyFX.install(FX,kit)
	local new,block,tween,sound,flash,shockRing,burst,smokePuff,sparks=kit.new,kit.block,kit.tween,kit.sound,kit.flash,kit.shockRing,kit.burst,kit.smokePuff,kit.sparks
	local num,seq,TEX,SOUND,BUILD,weldAll,floorUnder,anchorPart=kit.num,kit.seq,kit.TEX,kit.SOUND,kit.BUILD,kit.weldAll,kit.floorUnder,kit.anchorPart

	-- An ellipsoid of the given size (a Ball part stays round at its smallest
	-- side, which turned every beast into a small brown ball in Studio).
	local function ball(model,size,cf,color,material,transparency)
		local p=block(model,size,cf,color,material or Enum.Material.SmoothPlastic)
		p.Transparency=transparency or 0
		new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},p)
		return p
	end
	local function trail(root,width,color,lifetime)
		if width<=0 then return end
		local a0=new("Attachment",{Position=Vector3.new(0,width*.5,.2)},root)
		local a1=new("Attachment",{Position=Vector3.new(0,-width*.5,.2)},root)
		new("Trail",{Attachment0=a0,Attachment1=a1,Color=ColorSequence.new(color),Lifetime=lifetime or .18,LightEmission=.4,
			Transparency=num({{0,.35},{1,1}}),WidthScale=num({{0,1},{1,.2}}),FaceCamera=true},root)
	end
	local function glow(root,color,brightness,range)
		if brightness>0 then new("PointLight",{Color=color,Brightness=brightness,Range=range or 9,Shadows=false},root) end
	end
	local function spray(root,color,rate,size,speed)
		local at=new("Attachment",{},root)
		return new("ParticleEmitter",{Texture=TEX.smoke,Rate=rate,Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(speed or 2,(speed or 2)*2),
			SpreadAngle=Vector2.new(40,40),EmissionDirection=Enum.NormalId.Back,Color=ColorSequence.new(color),LightInfluence=.4,
			Size=num({{0,size},{1,size*2.4}}),Transparency=num({{0,.35},{1,1}}),Drag=4,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)},at)
	end

	-- One builder per shape. Every model is welded to an anchored root that the
	-- flight pose moves; sizes come from the look ({width, height, length}).
	local SHAPES={}
	SHAPES.orb=function(look)
		local m=new("Model",{Name="FamilyOrb"})
		local s=look.size
		local core=ball(m,Vector3.new(s[1]*.55,s[2]*.55,s[3]*.55),CFrame.new(),c3(look.color2),Enum.Material.Neon,.05)
		local shell=ball(m,Vector3.new(s[1],s[2],s[3]),CFrame.new(),c3(look.color),Enum.Material.Glass,.45)
		weldAll(core,{shell});m.PrimaryPart=core
		glow(core,c3(look.color),look.light)
		trail(core,look.trail,c3(look.color))
		spray(core,c3(look.color),30,s[1]*.35)
		return m
	end
	SHAPES.needle=function(look)
		local m=new("Model",{Name="FamilyNeedle"})
		local s=look.size
		local shaft=block(m,Vector3.new(s[1],s[2],s[3]),CFrame.new(),c3(look.color),Enum.Material.Metal)
		local tip=block(m,Vector3.new(s[1]*.6,s[2]*.6,s[3]*.25),CFrame.new(0,0,-s[3]*.6),c3(look.color2),Enum.Material.Metal)
		weldAll(shaft,{tip});m.PrimaryPart=shaft
		trail(shaft,math.max(look.trail,.08),c3(look.color),.08)
		return m
	end
	SHAPES.blade=function(look)
		local m=new("Model",{Name="FamilyBlade"})
		local s=look.size
		local glass=look.hit=="shatter"
		local body=block(m,Vector3.new(s[1],s[2],s[3]),CFrame.new(),c3(look.color),if glass then Enum.Material.Glass else Enum.Material.SmoothPlastic)
		body.Transparency=if glass then .25 else 0
		local edge=block(m,Vector3.new(s[1]*.5,s[2]*.5,s[3]*.4),CFrame.new(0,0,-s[3]*.55),c3(look.color2),if glass then Enum.Material.Ice else Enum.Material.SmoothPlastic,"WedgePart")
		edge.CFrame=CFrame.new(0,0,-s[3]*.6)*CFrame.Angles(math.rad(90),0,0)
		weldAll(body,{edge});m.PrimaryPart=body
		glow(body,c3(look.color),look.light,6)
		trail(body,math.max(look.trail,.1),c3(look.color),.12)
		return m
	end
	SHAPES.wave=function(look)
		local m=new("Model",{Name="FamilyWave"})
		local s=look.size
		local root=block(m,Vector3.new(s[1]*.4,s[2]*.4,s[3]*.4),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		root.Transparency=1
		local parts={}
		for i=-2,2 do
			local h=s[2]*(1-math.abs(i)*.18)
			local p=ball(m,Vector3.new(s[1]*.32,h,s[3]),CFrame.new(i*s[1]*.18,h*.5-s[2]*.2,math.abs(i)*.35),c3(if math.abs(i)==2 then look.color2 else look.color),Enum.Material.Slate)
			table.insert(parts,p)
		end
		weldAll(root,parts);m.PrimaryPart=root
		local e=spray(root,c3(look.color),50,s[1]*.25,4)
		e.EmissionDirection=Enum.NormalId.Top
		return m
	end
	SHAPES.beast=function(look)
		-- A creature read from its silhouette: a long body, the head raised
		-- forward with a pale snout and a dark nose, ears up, four legs and a
		-- tail for a hound; a dorsal and a tail fin, no legs, for a shark.
		local m=new("Model",{Name="FamilyBeast"})
		local s=look.size
		local w,h,l=s[1],s[2],s[3]
		local color,pale=c3(look.color),c3(look.color2)
		local dark=Color3.fromRGB(26,22,24)
		local water=look.zone=="water"
		local body=ball(m,Vector3.new(w*.8,h*.6,l*.64),CFrame.new(0,h*.08,0),color)
		local parts={}
		local function add(p) table.insert(parts,p);return p end
		add(ball(m,Vector3.new(w*.64,h*.34,l*.5),CFrame.new(0,-h*.1,-l*.02),pale))
		add(ball(m,Vector3.new(w*.62,h*.5,l*.3),CFrame.new(0,h*.34,-l*.4),color))
		add(ball(m,Vector3.new(w*.36,h*.24,l*.22),CFrame.new(0,h*.26,-l*.56),pale))
		add(ball(m,Vector3.new(w*.12,w*.1,w*.1),CFrame.new(0,h*.3,-l*.67),dark))
		for _,side in {-1,1} do
			add(ball(m,Vector3.new(w*.09,w*.09,w*.06),CFrame.new(side*w*.19,h*.46,-l*.52),dark))
		end
		if water then
			add(block(m,Vector3.new(w*.1,h*.55,l*.26),CFrame.new(0,h*.5,l*.02)*CFrame.Angles(0,math.pi,0),color,Enum.Material.SmoothPlastic,"WedgePart"))
			add(block(m,Vector3.new(w*.1,h*.7,l*.22),CFrame.new(0,h*.05,l*.46)*CFrame.Angles(0,math.pi,0),color,Enum.Material.SmoothPlastic,"WedgePart"))
			for _,side in {-1,1} do
				add(block(m,Vector3.new(w*.4,h*.06,l*.16),CFrame.new(side*w*.45,-h*.1,-l*.1)*CFrame.Angles(0,0,math.rad(side*-20)),color,Enum.Material.SmoothPlastic))
			end
		else
			for _,side in {-1,1} do
				add(block(m,Vector3.new(w*.12,h*.28,l*.08),CFrame.new(side*w*.17,h*.68,-l*.38),color,Enum.Material.SmoothPlastic,"WedgePart"))
				for _,z in {-.22,.22} do
					add(block(m,Vector3.new(w*.16,h*.46,w*.16),CFrame.new(side*w*.24,-h*.32,z*l),color,Enum.Material.SmoothPlastic))
				end
			end
			add(block(m,Vector3.new(w*.1,h*.12,l*.34),CFrame.new(0,h*.3,l*.42)*CFrame.Angles(math.rad(30),0,0),color,Enum.Material.SmoothPlastic))
		end
		weldAll(body,parts);m.PrimaryPart=body
		trail(body,look.trail,color,.2)
		if water then spray(body,color,40,w*.4,3) else spray(body,Color3.fromRGB(150,130,110),14,w*.3,2) end
		return m
	end
	SHAPES.serpent=function(look)
		local m=new("Model",{Name="FamilySerpent"})
		local s=look.size
		local head=ball(m,Vector3.new(s[1]*1.3,s[2]*1.1,s[1]*1.8),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		local parts={}
		-- Segments are posed every frame along the path behind the head.
		for i=1,6 do
			local w=s[1]*(1-i*.11)
			local seg=ball(m,Vector3.new(w,w,w*1.6),CFrame.new(0,0,i*s[3]/7),c3(if i%2==0 then look.color2 else look.color),Enum.Material.SmoothPlastic)
			seg.Name="Segment"..i;seg.Anchored=true
			table.insert(parts,seg)
		end
		for _,side in {-1,1} do
			local eye=ball(m,Vector3.new(s[1]*.22,s[1]*.22,s[1]*.12),CFrame.new(side*s[1]*.4,s[2]*.25,-s[1]*.6),Color3.fromRGB(250,220,80),Enum.Material.Neon)
			eye.Anchored=false;eye.Massless=true
			new("WeldConstraint",{Part0=head,Part1=eye},head)
		end
		m.PrimaryPart=head
		glow(head,c3(look.color),look.light)
		if look.zone=="water" then spray(head,c3(look.color),50,s[1]*.5,4) end
		return m
	end
	SHAPES.swarm=function(look)
		local m=new("Model",{Name="FamilySwarm"})
		local s=look.size
		local root=block(m,Vector3.new(.4,.4,.4),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		root.Transparency=1
		local at=new("Attachment",{},root)
		new("ParticleEmitter",{Texture=TEX.spark,Rate=180,Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(c3(look.color),c3(look.color2)),LightEmission=0,LightInfluence=1,Size=num({{0,.22},{1,.12}}),
			Transparency=num({{0,0},{1,.6}}),Acceleration=Vector3.zero,Drag=2,Shape=Enum.ParticleEmitterShape.Sphere},at).ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
		local cloud=new("ParticleEmitter",{Texture=TEX.smoke,Rate=24,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(1,2),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(c3(look.color)),LightInfluence=1,Size=num({{0,s[1]*.5},{1,s[1]*.9}}),Transparency=num({{0,.6},{1,1}})},at)
		cloud.Name="Cloud"
		m.PrimaryPart=root
		return m
	end
	SHAPES.shadow=function(look)
		-- A flat dark tongue running over the floor: its tip is the object, the
		-- strip back to where it left is a beam laid on the ground.
		local m=new("Model",{Name="FamilyShadow"})
		local s=look.size
		local tip=block(m,Vector3.new(s[1],s[2],s[1]*1.4),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		tip.Shape=Enum.PartType.Cylinder;tip.Size=Vector3.new(s[2],s[1]*1.2,s[1]*1.2)
		tip.Transparency=.1
		m.PrimaryPart=tip
		return m
	end
	SHAPES.boulder=function(look)
		local m=new("Model",{Name="FamilyBoulder"})
		local s=look.size
		local body=ball(m,Vector3.new(s[1],s[2],s[3]),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		local band=block(m,Vector3.new(s[1]*1.02,s[2]*.2,s[3]*1.02),CFrame.new(),c3(look.color2),Enum.Material.SmoothPlastic)
		band.Shape=Enum.PartType.Cylinder;band.Size=Vector3.new(s[2]*.22,s[1]*1.02,s[3]*1.02)
		weldAll(body,{band});m.PrimaryPart=body
		spray(body,Color3.fromRGB(170,150,120),30,s[1]*.3,3)
		return m
	end
	FamilyFX.SHAPES=SHAPES

	for kind,look in Looks do
		if not BUILD[kind] and SHAPES[look.shape] then
			BUILD[kind]=function() return SHAPES[look.shape](look) end
		end
	end

	-- Flight poses (FX.poses): orient, roll and animate by shape.
	for kind,look in Looks do
		if FX.poses[kind] then continue end
		local shape=look.shape
		if shape=="needle" or shape=="blade" then
			FX.poses[kind]=function(_,entry,p,age,cf,dt)
				entry.spin+=dt*(if shape=="needle" then 6 else 2)
				return cf*CFrame.Angles(0,0,entry.spin)
			end
		elseif shape=="beast" then
			FX.poses[kind]=function(_,entry,p,age,cf)
				local bob=math.abs(math.sin(age*14))*.5
				local flatLook=Vector3.new(p.direction.X,0,p.direction.Z)
				local at=cf.Position+Vector3.new(0,bob,0)
				return if flatLook.Magnitude>.05 then CFrame.lookAt(at,at+flatLook) else cf
			end
		elseif shape=="serpent" then
			FX.poses[kind]=function(_,entry,p,age,cf)
				local back=-p.direction
				local side=p.direction:Cross(Vector3.yAxis)
				side=if side.Magnitude>.05 then side.Unit else Vector3.xAxis
				local length=look.size[3]
				for i=1,6 do
					local seg=entry.model:FindFirstChild("Segment"..i)
					if seg then
						local d=i*length/7
						local wave=math.sin(age*12-i*.9)*look.size[1]*.6
						local at=cf.Position+back*d+side*wave
						seg.CFrame=CFrame.lookAt(at,at-back)
					end
				end
				return cf*CFrame.new(math.sin(age*12)*look.size[1]*.3,0,0)
			end
		elseif shape=="swarm" then
			FX.poses[kind]=function(_,entry,p,age,cf)
				return cf*CFrame.new(math.sin(age*9)*.4,math.cos(age*7)*.3,0)
			end
		elseif shape=="shadow" then
			FX.poses[kind]=function(fx,entry,p,age,cf)
				-- Laid on the floor under the flight line; the strip follows.
				local floor=floorUnder(fx,cf.Position,3,10)
				local at=if floor then floor.Position+Vector3.new(0,.04,0) else cf.Position
				if not entry.strip then
					local start=anchorPart(entry.model,if floor then Vector3.new(p.origin.X,at.Y,p.origin.Z) else p.origin)
					local a0=new("Attachment",{CFrame=CFrame.Angles(0,0,math.rad(90))},start)
					local a1=new("Attachment",{CFrame=CFrame.Angles(0,0,math.rad(90))},entry.root)
					entry.strip=new("Beam",{Attachment0=a0,Attachment1=a1,Width0=look.size[1]*.7,Width1=look.size[1]*1.1,Color=ColorSequence.new(c3(look.color)),
						Transparency=num({{0,.25},{1,.05}}),FaceCamera=false,LightInfluence=1,Segments=1},entry.root)
				end
				return CFrame.new(at)*CFrame.Angles(0,0,math.rad(90))
			end
		elseif shape=="boulder" then
			FX.poses[kind]=function(_,entry,p,age,cf,dt)
				entry.spin+=dt*10
				return cf*CFrame.Angles(-entry.spin,0,0)
			end
		end
	end

	-- Contact bursts by look.
	local function hit(fx,look,position,heavy,normal)
		local color,edge=c3(look.color),c3(look.color2)
		local kind=look.hit
		local scale=if heavy then 1.4 else 1
		if kind=="splash" then
			burst(fx.folder,position,{Texture=TEX.smoke,Lifetime=NumberRange.new(.35,.7),Speed=NumberRange.new(12,22),SpreadAngle=Vector2.new(70,70),
				EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,-50,0),Color=seq({{0,Color3.fromRGB(235,248,255)},{1,color}}),LightEmission=.2,
				Size=num({{0,.9*scale},{1,2.2*scale}}),Transparency=num({{0,.1},{1,1}}),Drag=2},28)
			shockRing(fx.folder,position-Vector3.new(0,1.5,0),edge,2,9*scale,.35)
			sound(anchorPart(fx.folder,position),SOUND.land,.5,.7)
		elseif kind=="shatter" then
			burst(fx.folder,position,{Texture=TEX.spark,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(14,26),SpreadAngle=Vector2.new(180,180),
				Acceleration=Vector3.new(0,-40,0),Color=ColorSequence.new(color),LightEmission=.6,Size=num({{0,.6},{1,.1}}),Drag=3},24)
			flash(fx.folder,position,color,.6,3*scale,.18,.3)
		elseif kind=="sparks" then
			sparks(fx.folder,position,edge,10,16)
		elseif kind=="smoke" then
			smokePuff(fx.folder,position,color,16,1.8*scale)
		elseif kind=="crush" then
			smokePuff(fx.folder,position-Vector3.new(0,1.5,0),Color3.fromRGB(176,160,138),18,2.2*scale)
			shockRing(fx.folder,position-Vector3.new(0,2,0),edge,2,10*scale,.4)
			sound(anchorPart(fx.folder,position),SOUND.heavy,.5,.9)
		else
			flash(fx.folder,position,color,.8,4*scale,.2,.2)
			burst(fx.folder,position,{Texture=TEX.spark,Lifetime=NumberRange.new(.2,.4),Speed=NumberRange.new(10,20),SpreadAngle=Vector2.new(180,180),
				Color=ColorSequence.new(edge),LightEmission=1,Size=num({{0,.6},{1,0}}),Drag=4},16)
		end
	end

	-- Zones on the ground (hazards with a look): drawn while they last.
	local ZONES={}
	ZONES.mist=function(holder,h,look)
		return new("ParticleEmitter",{Texture=TEX.smoke,Rate=26,Lifetime=NumberRange.new(2.4,3.6),Speed=NumberRange.new(.5,1.5),SpreadAngle=Vector2.new(30,30),
			EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Box,Color=ColorSequence.new(c3(look.color)),LightInfluence=1,
			Size=num({{0,8},{1,14}}),Transparency=num({{0,1},{.25,.45},{.75,.5},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-10,10)},holder)
	end
	ZONES.swarm=function(holder,h,look)
		return new("ParticleEmitter",{Texture=TEX.spark,Rate=140,Lifetime=NumberRange.new(.4,.9),Speed=NumberRange.new(2,6),SpreadAngle=Vector2.new(180,180),
			Shape=Enum.ParticleEmitterShape.Box,Color=ColorSequence.new(c3(look.color),c3(look.color2)),LightInfluence=1,
			Size=num({{0,.2},{1,.12}}),Transparency=num({{0,0},{1,.5}}),Drag=2},holder)
	end
	local function decal(holder,h,color,transparency,material)
		local disc=block(holder.Parent,Vector3.new(.08,h.radius*2,h.radius*2),CFrame.new(holder.Position)*CFrame.Angles(0,0,math.rad(90)),color,material or Enum.Material.SmoothPlastic)
		disc.Shape=Enum.PartType.Cylinder;disc.Transparency=1
		tween(disc,.3,{Transparency=transparency})
		return disc
	end
	ZONES.water=function(holder,h,look) local d=decal(holder,h,c3(look.color),.35,Enum.Material.Glass);d.Reflectance=.2;return nil,d end
	ZONES.ice=function(holder,h,look) local d=decal(holder,h,c3(look.color),.55,Enum.Material.Ice);return nil,d end
	ZONES.shadow=function(holder,h,look) local d=decal(holder,h,c3(look.color),.15);return nil,d end
	ZONES.mud=function(holder,h,look) local d=decal(holder,h,c3(look.color),.1,Enum.Material.Mud);return nil,d end
	ZONES.crater=function(holder,h,look) local d=decal(holder,h,Color3.fromRGB(96,78,60),.2,Enum.Material.Slate);return nil,d end
	ZONES.scorch=function(holder,h,look)
		local d=decal(holder,h,Color3.fromRGB(30,24,20),.3)
		local e=new("ParticleEmitter",{Texture=TEX.fire,Rate=30,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(2,5),EmissionDirection=Enum.NormalId.Top,
			Shape=Enum.ParticleEmitterShape.Box,Color=seq({{0,Color3.fromRGB(255,220,140)},{1,Color3.fromRGB(150,40,16)}}),LightEmission=1,LightInfluence=0,
			Size=num({{0,1},{1,.3}}),Transparency=num({{0,.2},{1,1}})},holder)
		return e,d
	end
	-- Bones out of the floor (Kimimaro's Dance of the Larch): a ring of spikes.
	ZONES.spikes=function(holder,h,look)
		local d=decal(holder,h,c3(look.color2),.6)
		for i=1,10 do
			local angle=i/10*math.pi*2
			local r=h.radius*(.45+.45*((i*7)%3)/2)
			local spike=block(holder.Parent,Vector3.new(.5,2.8,.5),CFrame.new(holder.Position+Vector3.new(math.cos(angle)*r,1.2,math.sin(angle)*r))*CFrame.Angles(math.rad(12*math.sin(angle)),0,math.rad(12*math.cos(angle))),c3(look.color),Enum.Material.SmoothPlastic)
			spike.Parent=d
		end
		return nil,d
	end
	-- A charge on the floor: a small lump of clay whose fuse glows, brighter
	-- once armed (Families.plant).
	ZONES.charge=function(holder,h,look)
		local lump=block(holder.Parent,Vector3.new(.9,.5,.9),CFrame.new(holder.Position+Vector3.new(0,.25,0)),c3(look.color),Enum.Material.SmoothPlastic)
		new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},lump)
		local fuse=block(lump,Vector3.new(.25,.25,.25),CFrame.new(holder.Position+Vector3.new(0,.6,0)),c3(look.color2),Enum.Material.Neon)
		new("PointLight",{Color=c3(look.color2),Brightness=1.5,Range=5,Shadows=false},fuse)
		tween(fuse,.4,{Transparency=.6})
		return nil,lump
	end
	FX.hazardBuild=function(fx,h)
		local look=Looks[h.look or ""]
		if not look then return nil end
		local draw=ZONES[look.zone or ""]
		if not draw then return nil end
		local floor=floorUnder(fx,h.position,3,14)
		local at=if floor then floor.Position+Vector3.new(0,.06,0) else h.position
		local holder=anchorPart(fx.folder,at);holder.Size=Vector3.new(h.radius*1.7,.2,h.radius*1.7)
		local e,disc=draw(holder,h,look)
		return {holder=holder,emitter=e,disc=disc,family=true}
	end
	FX.hazardFinish=function(entry)
		if entry.emitter then entry.emitter.Enabled=false end
		if entry.disc then tween(entry.disc,.4,{Transparency=1});Debris:AddItem(entry.disc,.5) end
		Debris:AddItem(entry.holder,3)
	end

	-- A body held by a family bind shows what holds it: beasts biting at the
	-- legs, coils round the torso, a pool of shadow, a swarm, or a sphere of
	-- the jutsu's substance (water prison). Anchored parts placed each frame.
	function FamilyFX.bindVisual(fx,model,root,look)
		local m=new("Model",{Name="FamilyBind"},fx.folder)
		local color,edge=c3(look.color),c3(look.color2)
		local feet=root.CFrame*CFrame.new(0,-2.5,0)
		if look.shape=="beast" then
			for _,side in {-1,1} do
				local b=SHAPES.beast(look)
				b.Name="BindBeast"
				-- Full size, flanking the legs, turned a little inward so each
				-- head reaches the shin from the front (facing the centre put the
				-- heads inside the legs in Studio).
				local cf=feet*CFrame.new(side*(.95+look.size[1]*.45),look.size[2]*.55-.3,.35)*CFrame.Angles(0,math.rad(side*-28),0)
				b.Parent=m;b:PivotTo(cf)
			end
		elseif look.shape=="serpent" then
			for k=1,3 do
				local ring=block(m,Vector3.new(.45,3.2,3.2),root.CFrame,if k%2==0 then edge else color,Enum.Material.SmoothPlastic)
				ring.Shape=Enum.PartType.Cylinder;ring.Name="BindCoil"
				ring:SetAttribute("Spin",1.5+k*.4);ring:SetAttribute("Y",-1.6+k*.9)
			end
		elseif look.shape=="shadow" then
			local pool=block(m,Vector3.new(.06,5.2,5.2),feet*CFrame.new(0,.05,0)*CFrame.Angles(0,0,math.rad(90)),color,Enum.Material.SmoothPlastic)
			pool.Shape=Enum.PartType.Cylinder;pool.Transparency=.15;pool.Name="BindShadow"
			for _,side in {-1,1} do
				local tendril=block(m,Vector3.new(.35,2.6,.35),feet*CFrame.new(side*.5,1.3,0),color,Enum.Material.SmoothPlastic)
				tendril.Transparency=.25;tendril.Name="BindShadow"
			end
		elseif look.shape=="swarm" then
			local core=block(m,Vector3.new(.2,.2,.2),root.CFrame,color,Enum.Material.SmoothPlastic);core.Transparency=1
			new("ParticleEmitter",{Texture=TEX.spark,Rate=200,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(3,6),SpreadAngle=Vector2.new(180,180),
				Shape=Enum.ParticleEmitterShape.Sphere,Color=ColorSequence.new(color,edge),LightInfluence=1,Size=num({{0,.2},{1,.12}})},new("Attachment",{},core))
		else
			local shell=block(m,Vector3.new(6,7,6),root.CFrame,color,Enum.Material.Glass);shell.Shape=Enum.PartType.Ball;shell.Transparency=.55;shell.Name="BindShell"
		end
		return m
	end
	-- Bodies: buff aura, counter stance ring, the dark of a slow.
	local auras=setmetatable({},{__mode="k"})
	local function auraOf(model)
		local st=auras[model]
		if st then return st end
		st={}
		auras[model]=st
		return st
	end
	local function fighterColor(actor)
		local def=Fighters[actor.fighterId or ""]
		return if def and def.Color then c3(def.Color) else Color3.fromRGB(220,220,255)
	end
	table.insert(FX.layers,{
		impact=function(fx,impact,folder)
			local style=impact.style
			-- A family relocation drawn in its own look (a mirror of ice, a swirl
			-- of mist, a body flicker), never Minato's yellow flash.
			if style=="teleport" and impact.kind and Looks[impact.kind] then
				local look=Looks[impact.kind]
				local color,edge=c3(look.color),c3(look.color2)
				local from,to=impact.from or impact.position,impact.to or impact.position
				smokePuff(fx.folder,from,color,14,2)
				flash(fx.folder,from,edge,1,4,.18,.3)
				smokePuff(fx.folder,to,color,10,1.6)
				flash(fx.folder,to,edge,1.5,6,.2,.2)
				shockRing(fx.folder,to-Vector3.new(0,2.6,0),color,2,10,.3)
				return true
			end
			if style=="look" then
				local look=Looks[impact.kind or ""] or Looks.chakra
				hit(fx,look,impact.position,impact.heavy,impact.normal)
				if impact.radius then shockRing(fx.folder,impact.position-Vector3.new(0,2.4,0),c3(look.color),2,impact.radius*2,.45) end
				return true
			elseif style=="zone" then
				local look=Looks[impact.kind or ""] or Looks.chakra
				shockRing(fx.folder,impact.position,c3(look.color2),2,(impact.radius or 8)*2,.5)
				smokePuff(fx.folder,impact.position+Vector3.new(0,1,0),c3(look.color),14,2.6)
				return true
			elseif style=="buff" then
				local model=folder and folder:FindFirstChild(impact.owner or "")
				local root=model and model:FindFirstChild("HumanoidRootPart")
				local color=Looks[impact.kind or ""] and c3(Looks[impact.kind].color) or Color3.fromRGB(255,240,200)
				flash(fx.folder,impact.position,color,2,9,.3,.4)
				shockRing(fx.folder,impact.position-Vector3.new(0,2.6,0),color,3,14,.5)
				if root then sound(root,SOUND.boom,.25,1.3) end
				return true
			elseif style=="stance" then
				local color=Looks[impact.kind or ""] and c3(Looks[impact.kind].color) or Color3.fromRGB(255,255,255)
				shockRing(fx.folder,impact.position-Vector3.new(0,2.6,0),color,7,3,impact.time or .6)
				return true
			elseif style=="drain" then
				local owner=folder and folder:FindFirstChild(impact.owner or "")
				local to=owner and owner:FindFirstChild("HumanoidRootPart")
				burst(fx.folder,impact.position,{Texture=TEX.glow,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(4,8),SpreadAngle=Vector2.new(60,60),
					Acceleration=if to then (to.Position-impact.position).Unit*30 else Vector3.zero,Color=ColorSequence.new(Color3.fromRGB(120,190,255)),
					LightEmission=1,Size=num({{0,.8},{1,.1}}),Transparency=num({{0,.2},{1,1}})},10)
				return true
			end
			return false
		end,
		fighter=function(fx,model,actor,dt)
			if not model then return end
			local st=auraOf(model)
			local fam=actor.family
			local root=model:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local buffed=fam and fam.buff~=nil
			-- A buff that draws a weapon (its Kind is a blade/needle look: the
			-- Camellia's bone sword, the chakra scalpel) holds it in the right hand.
			local held=nil
			if buffed then
				local def=Fighters[actor.fighterId or ""]
				for _,spec in (def and def.Techniques) or {} do
					if spec.Id==fam.buff and spec.Kind and Looks[spec.Kind] and (Looks[spec.Kind].shape=="blade" or Looks[spec.Kind].shape=="needle") then held=spec.Kind end
				end
			end
			if held~=st.weaponKind then
				if st.weapon then st.weapon:Destroy();st.weapon=nil end
				st.weaponKind=held
				local hand=model:FindFirstChild("RightHand")
				if held and hand then
					local look=Looks[held]
					local length=math.max(look.size[3]*1.6,2.2)
					local w=block(model,Vector3.new(math.max(look.size[1],.18),math.max(look.size[2],.18),length),hand.CFrame*CFrame.new(0,-.4,-length*.5),c3(look.color),Enum.Material.Neon)
					w.Name="FamilyWeapon";w.Anchored=false;w.CanCollide=false;w.Massless=true;w.Transparency=.1
					new("WeldConstraint",{Part0=hand,Part1=w},w)
					glow(w,c3(look.color2),look.light)
					st.weapon=w
				end
			end
			if buffed and not st.aura then
				local at=new("Attachment",{Name="FamilyAura"},root)
				local color=fighterColor(actor)
				st.aura=new("ParticleEmitter",{Texture=TEX.glow,Rate=26,Lifetime=NumberRange.new(.35,.6),Speed=NumberRange.new(2,4),SpreadAngle=Vector2.new(25,25),
					EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Cylinder,Color=ColorSequence.new(color),LightEmission=.8,LightInfluence=0,
					Size=num({{0,1.4},{1,.2}}),Transparency=num({{0,.45},{1,1}})},at)
				st.aura.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
				st.auraAt=at
			elseif not buffed and st.aura then
				st.aura.Enabled=false;Debris:AddItem(st.auraAt,1);st.aura=nil;st.auraAt=nil
			end
			-- Held by a family bind: what holds the body shows on it.
			local held=actor.boundKind
			if held~=st.heldKind then
				if st.held then st.held:Destroy();st.held=nil end
				st.heldKind=held
				if held and Looks[held] then st.held=FamilyFX.bindVisual(fx,model,root,Looks[held]) end
			end
			if st.held and st.held.Parent then
				local t=os.clock()
				for _,p in st.held:GetChildren() do
					local spin=p:GetAttribute("Spin")
					if spin then p.CFrame=root.CFrame*CFrame.new(0,p:GetAttribute("Y") or 0,0)*CFrame.Angles(0,t*spin,0)*CFrame.Angles(0,0,math.rad(90)) end
				end
			end
			local slowed=fam and (fam.slowed or 0)>0
			if slowed and not st.slow then
				local at=new("Attachment",{Name="FamilySlow",Position=Vector3.new(0,-2.6,0)},root)
				st.slow=new("ParticleEmitter",{Texture=TEX.smoke,Rate=14,Lifetime=NumberRange.new(.4,.7),Speed=NumberRange.new(.5,1.5),
					Color=ColorSequence.new(Color3.fromRGB(40,36,52)),LightInfluence=1,Size=num({{0,1.2},{1,2}}),Transparency=num({{0,.5},{1,1}})},at)
				st.slowAt=at
			elseif not slowed and st.slow then
				st.slow.Enabled=false;Debris:AddItem(st.slowAt,1);st.slow=nil;st.slowAt=nil
			end
		end,
	})
end
return FamilyFX
