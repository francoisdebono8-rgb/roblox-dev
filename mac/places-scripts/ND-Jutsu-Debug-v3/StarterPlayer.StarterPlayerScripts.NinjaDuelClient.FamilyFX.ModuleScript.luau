-- Family objects seen in play (roster breadth pass): every projectile kind of
-- Shared/Looks gets a real model (never the kunai fallback), its flight pose,
-- its contact burst and, for zones, a ground look; buffs, counter stances,
-- drains and slows show on the bodies. Installed by Effects like SandFX.
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Looks=require(Shared.Looks)
local SealJutsu=require(game:GetService("ReplicatedStorage").NinjaDuel.SealJutsu)
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
			-- (Audit 04/11) a wave of air (a look with light: Hasangeki) is not
			-- stone: it flew as five pale rocks with no glow and no trail.
			local air=(look.light or 0)>0
			local p=ball(m,Vector3.new(s[1]*.32,h,s[3]),CFrame.new(i*s[1]*.18,h*.5-s[2]*.2,math.abs(i)*.35),c3(if math.abs(i)==2 then look.color2 else look.color),if air then Enum.Material.ForceField else Enum.Material.Slate)
			if air then p.Transparency=.15 end
			table.insert(parts,p)
		end
		weldAll(root,parts);m.PrimaryPart=root
		local e=spray(root,c3(look.color),50,s[1]*.25,4)
		e.EmissionDirection=Enum.NormalId.Top
		if (look.light or 0)>0 then
			glow(parts[3],c3(look.color2),look.light)
			if (look.trail or 0)>0 then trail(parts[3],look.trail,c3(look.color),.4) end
		end
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
	-- (Studio film 28/10: Kakashi's Water Dragon read as one blue ball.) A
	-- serpent is a long body: the head, then one segment per ~1.1 stud of its
	-- length, each following the path the head really took (a snake, not a
	-- stiff rod waving); the water dragon also has horns and a jaw.
	local function segmentsFor(look) return math.clamp(math.floor(look.size[3]/1.1),6,18) end
	SHAPES.serpent=function(look)
		local m=new("Model",{Name="FamilySerpent"})
		local s=look.size
		local water=look.zone=="water"
		local head=ball(m,Vector3.new(s[1]*1.3,s[2]*1.1,s[1]*1.8),CFrame.new(),c3(look.color),Enum.Material.SmoothPlastic)
		local parts={}
		local n=segmentsFor(look)
		for i=1,n do
			local w=s[1]*(1-(i/n)*.72)
			local seg=ball(m,Vector3.new(w,w,w*1.7),CFrame.new(0,0,i*s[3]/(n+1)),c3(if i%3==0 then look.color2 else look.color),Enum.Material.SmoothPlastic,if water then .12 else 0)
			seg.Name="Segment"..i;seg.Anchored=true
			table.insert(parts,seg)
		end
		local attach={}
		for _,side in {-1,1} do
			table.insert(attach,ball(m,Vector3.new(s[1]*.22,s[1]*.22,s[1]*.12),CFrame.new(side*s[1]*.4,s[2]*.25,-s[1]*.6),Color3.fromRGB(250,220,80),Enum.Material.Neon))
			if water then
				-- horns swept back, and the open lower jaw
				table.insert(attach,block(m,Vector3.new(s[1]*.12,s[1]*.16,s[1]*1.1),CFrame.new(side*s[1]*.35,s[2]*.55,s[1]*.55)*CFrame.Angles(math.rad(25),math.rad(side*12),0),c3(look.color2),Enum.Material.SmoothPlastic))
			end
		end
		if water then
			table.insert(attach,ball(m,Vector3.new(s[1]*.9,s[2]*.3,s[1]*1.2),CFrame.new(0,-s[2]*.45,-s[1]*.35)*CFrame.Angles(math.rad(-18),0,0),c3(look.color2),Enum.Material.SmoothPlastic))
		end
		for _,a in attach do
			a.Anchored=false;a.Massless=true
			new("WeldConstraint",{Part0=head,Part1=a},head)
		end
		m.PrimaryPart=head
		glow(head,c3(look.color),look.light)
		if water then spray(head,c3(look.color),70,s[1]*.6,4) end
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

	-- (Jutsu pass 05/11, the reel: « le Fuma et le Moulin volent comme une
	-- boîte grise ») The windmill and fuma shuriken were the generic blade: a
	-- flat box with a wedge, rolled about its flight line. Now a real giant
	-- shuriken lying flat: a dark hub with its hole, four blades whose tips
	-- sweep back (the fuma's curve), a pale edge on each, a faint spin ring at
	-- the blade tips, and it spins flat about the vertical, fast.
	local function giantShuriken(look)
		local m=new("Model",{Name="FamilyFuma"})
		local d=look.size[1]
		local t=math.max(look.size[2],.08)
		local steel,dark=c3(look.color),c3(look.color2)
		local edgeTone=Color3.fromRGB(236,240,246)
		local root=block(m,Vector3.new(.1,.1,.1),CFrame.new(),dark);root.Transparency=1
		local parts={}
		local hub=block(m,Vector3.new(t*1.5,d*.27,d*.27),CFrame.Angles(0,0,math.pi/2),dark,Enum.Material.Metal);hub.Shape=Enum.PartType.Cylinder
		local hole=block(m,Vector3.new(t*1.7,d*.09,d*.09),CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(14,14,18),Enum.Material.SmoothPlastic);hole.Shape=Enum.PartType.Cylinder
		table.insert(parts,hub);table.insert(parts,hole)
		for k=0,3 do
			local base=CFrame.Angles(0,k*math.pi/2,0)
			table.insert(parts,block(m,Vector3.new(d*.16,t,d*.26),base*CFrame.new(0,0,-d*.2),steel,Enum.Material.Metal))
			-- the tip: a flat triangle (a wedge laid on its side), swept back
			local tipCF=base*CFrame.new(-d*.045,0,-d*.39)*CFrame.Angles(0,math.rad(26),0)*CFrame.Angles(0,0,math.pi/2)
			table.insert(parts,block(m,Vector3.new(t,d*.15,d*.24),tipCF,steel,Enum.Material.Metal,"WedgePart"))
			table.insert(parts,block(m,Vector3.new(d*.018,t*1.15,d*.42),base*CFrame.new(d*.075,0,-d*.27)*CFrame.Angles(0,math.rad(-6),0),edgeTone,Enum.Material.Metal))
		end
		local ring=block(m,Vector3.new(t*.6,d*.9,d*.9),CFrame.Angles(0,0,math.pi/2),edgeTone,Enum.Material.Neon);ring.Shape=Enum.PartType.Cylinder
		ring.Transparency=.82
		table.insert(parts,ring)
		weldAll(root,parts);m.PrimaryPart=root
		-- two trail points on the tips: as it spins they draw a blurred disc
		local a0=new("Attachment",{Position=Vector3.new(-d*.45,0,0)},root)
		local a1=new("Attachment",{Position=Vector3.new(d*.45,0,0)},root)
		new("Trail",{Attachment0=a0,Attachment1=a1,Color=ColorSequence.new(edgeTone),Lifetime=.09,LightEmission=.3,FaceCamera=false,
			Transparency=num({{0,.55},{1,1}})},root)
		return m
	end
	for _,kind in {"fuma","windmill"} do
		local look=Looks[kind]
		if look then
			BUILD[kind]=function() return giantShuriken(look) end
			FX.poses[kind]=function(_,entry,p,age,cf,dt)
				entry.spin+=dt*24
				return cf*CFrame.Angles(0,entry.spin,0)
			end
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
			local n=segmentsFor(look)
			local spacing=look.size[3]/(n+1)
			local rises=look.zone=="water"
			FX.poses[kind]=function(_,entry,p,age,cf)
				local side=p.direction:Cross(Vector3.yAxis)
				side=if side.Magnitude>.05 then side.Unit else Vector3.xAxis
				-- the head swims (side to side) and, for the dragon, rears up
				-- out of the cast and dives onto the target
				local travelled=math.min(age*(p.speed or 40),p.range or 40)
				local share=math.clamp(travelled/math.max(p.range or 40,1),0,1)
				local lift=if rises then math.sin(share*math.pi)*4.5*(1-share*.35) else 0
				local at=cf.Position+side*math.sin(age*9)*look.size[1]*.45+Vector3.new(0,lift,0)
				-- path history, newest first
				local hist=entry.serpentPath or {}
				entry.serpentPath=hist
				if #hist==0 or (hist[1]-at).Magnitude>.12 then table.insert(hist,1,at) end
				if #hist>200 then table.remove(hist) end
				local function along(d)
					local walked=0
					for k=1,#hist-1 do
						local a,b=hist[k],hist[k+1]
						local l=(b-a).Magnitude
						if walked+l>=d then return a:Lerp(b,(d-walked)/math.max(l,1e-3)) end
						walked+=l
					end
					-- not enough path yet: the body still coming out behind
					-- not enough path yet: the rest of the body is still coming
					-- up out of the ground under where it was cast
					local rest=d-walked
					return (hist[#hist] or at)-p.direction*rest*.3-Vector3.new(0,rest*.55,0)
				end
				local prev=at
				for i=1,n do
					local seg=entry.model:FindFirstChild("Segment"..i)
					if seg then
						local here=along(i*spacing)
						seg.CFrame=CFrame.lookAt(here,if (prev-here).Magnitude>1e-3 then prev else here+p.direction)
						prev=here
					end
				end
				local ahead=at+p.direction*2+Vector3.new(0,if rises then math.cos(share*math.pi)*1.6 else 0,0)
				return CFrame.lookAt(at,ahead)
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
	-- (04/11) Minato's sealing formula (Families zone Trap): ink on the floor,
	-- a double ring, eight strokes of script round the seal's kanji, faintly
	-- lit so it reads as a trap without shouting.
	ZONES.seal=function(holder,h,look)
		local ink,paper=c3(look.color2),c3(look.color)
		local at=holder.Position
		local d=decal(holder,h,paper,.82)
		local function ring(radius,width)
			local r=block(d,Vector3.new(.05,radius*2,radius*2),CFrame.new(at+Vector3.new(0,.03,0))*CFrame.Angles(0,0,math.rad(90)),ink,Enum.Material.SmoothPlastic)
			r.Shape=Enum.PartType.Cylinder;r.Transparency=1;tween(r,.4,{Transparency=.15})
			local inner=block(d,Vector3.new(.06,(radius-width)*2,(radius-width)*2),CFrame.new(at+Vector3.new(0,.035,0))*CFrame.Angles(0,0,math.rad(90)),paper,Enum.Material.SmoothPlastic)
			inner.Shape=Enum.PartType.Cylinder;inner.Transparency=1;tween(inner,.4,{Transparency=.3})
		end
		ring(h.radius,.18);ring(h.radius*.62,.12)
		for i=1,8 do
			local angle=i/8*math.pi*2
			local r=h.radius*.81
			local stroke=block(d,Vector3.new(.9,.04,.16),CFrame.new(at+Vector3.new(math.cos(angle)*r,.05,math.sin(angle)*r))*CFrame.Angles(0,-angle+math.pi/2,0),ink,Enum.Material.SmoothPlastic)
			stroke.Transparency=1;tween(stroke,.5,{Transparency=.1})
		end
		local plate=block(d,Vector3.new(h.radius*1.1,.04,h.radius*1.1),CFrame.new(at+Vector3.new(0,.06,0)),paper,Enum.Material.SmoothPlastic)
		plate.Transparency=1
		local gui=new("SurfaceGui",{Face=Enum.NormalId.Top,LightInfluence=0,Brightness=1.4,SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud,PixelsPerStud=40},plate)
		new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="封",TextScaled=true,Font=Enum.Font.GothamBold,TextColor3=ink,TextTransparency=.1},gui)
		local glow=new("PointLight",{Color=Color3.fromRGB(255,230,170),Brightness=.6,Range=h.radius*1.6,Shadows=false},plate)
		local _=glow
		return nil,d
	end
	-- A charge on the floor: a small lump of clay whose fuse glows, brighter
	-- once armed (Families.plant).
	-- A buried clay charge (QA-004 M5): posed, the fuse is dark; armed (the
	-- server's armedAt), it glows and a thin ring shows the trigger radius;
	-- consumed or expired, it goes with the hazard (detonation draws its blast).
	ZONES.charge=function(holder,h,look)
		local lump=block(holder.Parent,Vector3.new(.9,.5,.9),CFrame.new(holder.Position+Vector3.new(0,.25,0)),c3(look.color),Enum.Material.SmoothPlastic)
		new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},lump)
		local fuse=block(lump,Vector3.new(.25,.25,.25),CFrame.new(holder.Position+Vector3.new(0,.6,0)),Color3.fromRGB(70,60,52),Enum.Material.SmoothPlastic)
		fuse.Name="Fuse"
		local light=new("PointLight",{Color=c3(look.color2),Brightness=0,Range=5,Shadows=false},fuse)
		local ring=block(lump,Vector3.new(.06,h.radius*2,h.radius*2),CFrame.new(holder.Position+Vector3.new(0,.05,0))*CFrame.Angles(0,0,math.rad(90)),c3(look.color2),Enum.Material.Neon)
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=1;ring.Name="TriggerRing"
		return nil,lump
	end
	FX.hazardUpdate=function(entry,h)
		if not h.charge or not entry.disc then return end
		local lump=entry.disc
		entry.chargeState=entry.chargeState or "posed"
		if h.charge=="armed" and entry.chargeState~="armed" then
			entry.chargeState="armed"
			local fuse=lump:FindFirstChild("Fuse")
			if fuse then fuse.Material=Enum.Material.Neon;fuse.Color=Color3.fromRGB(255,120,60);local l=fuse:FindFirstChildOfClass("PointLight");if l then l.Brightness=1.6 end end
			local ring=lump:FindFirstChild("TriggerRing")
			if ring then ring.Transparency=.85 end
		end
		-- Armed: a slow pulse (readable without F8, never a flashing light).
		if h.charge=="armed" then
			local fuse=lump:FindFirstChild("Fuse")
			local l=fuse and fuse:FindFirstChildOfClass("PointLight")
			if l then l.Brightness=1.2+math.sin(os.clock()*6)*.5 end
		end
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
				if impact.kind=="leaf" then
					-- (Jutsu pass 06/11, the reel: « l'entrée dynamique fait un pouf,
					-- pas un coup de pied volant ») Lee does not vanish: he flies. No
					-- smoke; the dust he tears off the ground where he leaves, a trail
					-- of green afterimages of his kick strung along the line he flew,
					-- wind streaks along it, and the dust ring where he lands.
					local model=folder and folder:FindFirstChild(impact.owner or "")
					local line=to-from
					local GREEN=Color3.fromRGB(70,190,90)
					shockRing(fx.folder,from-Vector3.new(0,2.6,0),c3({206,194,168}),2,8,.3)
					burst(fx.folder,from-Vector3.new(0,2.4,0),{Texture=TEX.smoke,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(60,60),
						Color=ColorSequence.new(Color3.fromRGB(206,194,168)),LightInfluence=1,Size=num({{0,1},{1,2.4}}),Transparency=num({{0,.3},{1,1}}),Drag=4},10)
					if model and line.Magnitude>1 then
						for k=1,5 do
							local ghost=fx:ghost(model,GREEN,.18+k*.04,.35+k*.08)
							if ghost then
								local back=line*(-(1-k/6))
								pcall(function() ghost:PivotTo(ghost:GetPivot()+back) end)
							end
						end
					end
					if line.Magnitude>1 then
						local dir=line.Unit
						local mid=(from+to)/2+Vector3.new(0,.6,0)
						for k=-1,1 do
							local streak=block(fx.folder,Vector3.new(.06,.06,line.Magnitude*.8),CFrame.lookAt(mid+Vector3.new(0,k*.7,0),mid+Vector3.new(0,k*.7,0)+dir),Color3.fromRGB(236,255,236),Enum.Material.Neon)
							streak.Transparency=.35
							tween(streak,.22,{Transparency=1,Size=Vector3.new(.02,.02,line.Magnitude*.3),CFrame=streak.CFrame+dir*line.Magnitude*.3})
							Debris:AddItem(streak,.25)
						end
					end
					shockRing(fx.folder,to-Vector3.new(0,2.6,0),color,2,11,.3)
					sound(anchorPart(fx.folder,to),SOUND.whooshBy or SOUND.whoosh,.5,1.1)
					return true
				end
				smokePuff(fx.folder,from,color,14,2)
				flash(fx.folder,from,edge,1,4,.18,.3)
				smokePuff(fx.folder,to,color,10,1.6)
				flash(fx.folder,to,edge,1.5,6,.2,.2)
				shockRing(fx.folder,to-Vector3.new(0,2.6,0),color,2,10,.3)
				return true
			end
			if style=="look" and impact.kind=="crows" then
				-- (Jutsu pass 05/11, the reel: « on ne voit aucun corbeau ») Itachi's
				-- crow genjutsu drew only the look's puff of smoke. Now a flock pours
				-- out of his sleeve and floods the cone in front of him, wings
				-- beating, black feathers trailing, and scatters past the target.
				local owner=folder and folder:FindFirstChild(impact.owner or "")
				local root=owner and owner:FindFirstChild("HumanoidRootPart")
				local dir=impact.direction or (root and root.CFrame.LookVector) or Vector3.new(0,0,-1)
				dir=Vector3.new(dir.X,0,dir.Z)
				dir=if dir.Magnitude>.1 then dir.Unit else Vector3.new(0,0,-1)
				local side=dir:Cross(Vector3.yAxis)
				local origin=(if root then root.Position else impact.position)+side*.9+Vector3.new(0,.8,0)+dir*1.2
				local reach=impact.radius or 8
				local black,wingTone=Color3.fromRGB(12,12,16),Color3.fromRGB(8,8,12)
				local RunService=game:GetService("RunService")
				for i=1,16 do
					local bird=new("Model",{Name="Crow"},fx.folder)
					local s=.8+math.random()*.5
					local body=block(bird,Vector3.new(.4,.34,.9)*s,CFrame.new(origin),black,Enum.Material.SmoothPlastic)
					local head=block(bird,Vector3.new(.26,.26,.28)*s,CFrame.new(origin),black,Enum.Material.SmoothPlastic)
					local beak=block(bird,Vector3.new(.08,.08,.22)*s,CFrame.new(origin),Color3.fromRGB(40,36,30),Enum.Material.SmoothPlastic)
					local eye=block(bird,Vector3.new(.06,.06,.06)*s,CFrame.new(origin),Color3.fromRGB(200,20,30),Enum.Material.Neon)
					local wingL=block(bird,Vector3.new(1.1,.05,.5)*s,CFrame.new(origin),wingTone,Enum.Material.SmoothPlastic,"WedgePart")
					local wingR=block(bird,Vector3.new(1.1,.05,.5)*s,CFrame.new(origin),wingTone,Enum.Material.SmoothPlastic,"WedgePart")
					local spread=math.rad((math.random()-.5)*70)
					local heading=CFrame.fromAxisAngle(Vector3.yAxis,spread):VectorToWorldSpace(dir)
					local rise=(math.random()-.35)*.5
					local course=(heading+Vector3.new(0,rise,0)).Unit
					local distance=reach*(.8+math.random()*.7)
					local start=origin+Vector3.new((math.random()-.5)*.6,(math.random()-.5)*.8,(math.random()-.5)*.6)
					local delay=i*.024
					local life=.65+math.random()*.35
					local t0=os.clock()+delay
					local phase=math.random()*6
					local conn
					conn=RunService.RenderStepped:Connect(function()
						local k=(os.clock()-t0)/life
						if k<0 then return end
						if k>=1 or not bird.Parent then conn:Disconnect();bird:Destroy();return end
						local at=start:Lerp(start+course*distance,1-(1-k)^1.6)+Vector3.new(0,math.sin(k*math.pi)*.8,0)
						local cf=CFrame.lookAt(at,at+course)
						local flap=math.sin(os.clock()*30+phase)*1.0
						body.CFrame=cf
						head.CFrame=cf*CFrame.new(0,.08*s,-.52*s)
						beak.CFrame=cf*CFrame.new(0,.06*s,-.74*s)
						eye.CFrame=cf*CFrame.new(.1*s,.14*s,-.6*s)
						wingL.CFrame=cf*CFrame.new(-.55*s,.05,0)*CFrame.Angles(0,0,flap)
						wingR.CFrame=cf*CFrame.new(.55*s,.05,0)*CFrame.Angles(0,0,-flap)
						local fade=math.clamp((k-.75)/.25,0,1)
						for _,p in bird:GetChildren() do if p:IsA("BasePart") then p.Transparency=fade end end
					end)
				end
				-- feathers and a dark smoke at the sleeve
				burst(fx.folder,origin,{Texture=TEX.smoke,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(45,45),
					Color=ColorSequence.new(Color3.fromRGB(30,26,34)),LightInfluence=1,Size=num({{0,1},{1,2.6}}),Transparency=num({{0,.35},{1,1}}),Drag=3},10)
				burst(fx.folder,origin+dir*2,{Texture=TEX.spark,Lifetime=NumberRange.new(.6,1.1),Speed=NumberRange.new(4,10),SpreadAngle=Vector2.new(70,70),
					Color=ColorSequence.new(Color3.fromRGB(14,14,18)),LightEmission=0,LightInfluence=1,Size=num({{0,.3},{1,.18}}),
					Acceleration=Vector3.new(0,-4,0),Drag=2,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-200,200)},18)
				sound(anchorPart(fx.folder,origin),SOUND.whoosh,.5,.8)
				return true
			end
			if style=="look" and impact.kind=="sandarm" then
				-- (04/11) Gaara's Shukaku arm: a huge arm of sand grows out of his
				-- shoulder and sweeps the arc in front of him, then crumbles.
				local look=Looks.sandarm
				local owner=folder and folder:FindFirstChild(impact.owner or "")
				local root=owner and owner:FindFirstChild("HumanoidRootPart")
				local dir=impact.direction or (root and root.CFrame.LookVector) or Vector3.new(0,0,-1)
				dir=Vector3.new(dir.X,0,dir.Z)
				if dir.Magnitude<.1 then dir=Vector3.new(0,0,-1) end
				dir=dir.Unit
				local origin=(if root then root.Position else impact.position)+Vector3.new(0,1.2,0)
				local reach=impact.radius or 13
				-- (Jutsu pass 05/11, the reel: « juste une bouffée de sable ») The arm
				-- was five sand boxes and a box claw, gone in under half a second.
				-- Now a rounded arm that thickens to the hand (overlapping lumps of
				-- sand), a hand with three hooked fingers and a thumb, sand pouring
				-- off it, and a slower sweep (≈ .7 s) that can be seen.
				local arm=new("Model",{Name="ShukakuArm"},fx.folder)
				local sandTone,dark=c3(look.color),c3(look.color2)
				local function lump(size,tone)
					-- (Studio 06/11: the Sand material read olive green in the arena's
					-- light) plain smooth sand colour
					local p=block(arm,size,CFrame.new(origin),tone,Enum.Material.SmoothPlastic)
					new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},p)
					return p
				end
				local segs={}
				for i=1,7 do
					local k=i/7
					local w=1.5+k*2.1
					table.insert(segs,{part=lump(Vector3.new(w,w*.9,reach/6+1.4),if i%2==0 then dark else sandTone),k=k})
				end
				local palm=lump(Vector3.new(4.2,1.6,3.2),sandTone)
				local fingers={}
				for f=-1,1 do table.insert(fingers,{part=lump(Vector3.new(.9,.8,2.4),dark),x=f*1.25,curl=0}) end
				local thumb={part=lump(Vector3.new(.8,.8,1.8),dark),x=-2.1,curl=0}
				local pour=new("Attachment",{},palm)
				local spill=new("ParticleEmitter",{Texture=TEX.smoke,Rate=60,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(30,30),
					EmissionDirection=Enum.NormalId.Bottom,Color=ColorSequence.new(sandTone),LightInfluence=1,Size=num({{0,.8},{1,2}}),
					Transparency=num({{0,.3},{1,1}}),Acceleration=Vector3.new(0,-18,0),Drag=1},pour)
				local SPAN=.42 -- seconds per unit of t below (was .3)
				local t0=os.clock()
				local sweep
				sweep=game:GetService("RunService").RenderStepped:Connect(function()
					local t=(os.clock()-t0)/SPAN
					if t>1.7 or not arm.Parent then
						sweep:Disconnect()
						if arm.Parent then
							spill.Enabled=false
							for _,e in segs do smokePuff(fx.folder,e.part.Position,sandTone,6,1.8) end
							smokePuff(fx.folder,palm.Position,sandTone,10,2.4)
							arm:Destroy()
						end
						return
					end
					-- grows over the first third, sweeps from his right to his left,
					-- the hand closing as it crosses
					local grow=math.clamp(t*2.2,0,1)
					local swing=math.clamp((t-.15)/.85,0,1)
					local eased=swing*swing*(3-2*swing)
					local angle=math.rad(70-140*eased)
					local along=(CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(dir))
					for _,e in segs do
						local d=reach*e.k*grow
						local at=origin+along*d+Vector3.new(0,-1.3*e.k+math.sin(e.k*math.pi)*.8,0)
						e.part.CFrame=CFrame.lookAt(at,at+along)
					end
					local tip=origin+along*reach*grow+Vector3.new(0,-1.4,0)
					local hand=CFrame.lookAt(tip,tip+along)
					palm.CFrame=hand
					local close=math.rad(25+70*eased)
					for _,f in fingers do
						f.part.CFrame=hand*CFrame.new(f.x,0,-1.4)*CFrame.Angles(-close,0,0)*CFrame.new(0,0,-1)
					end
					thumb.part.CFrame=hand*CFrame.new(thumb.x,0,-.4)*CFrame.Angles(0,math.rad(50),0)*CFrame.Angles(-close*.6,0,0)*CFrame.new(0,0,-.8)
				end)
				burst(fx.folder,origin,{Texture=TEX.smoke,Lifetime=NumberRange.new(.5,1),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(80,80),
					Color=ColorSequence.new(c3(look.color)),LightInfluence=1,Size=num({{0,1.2},{1,3}}),Transparency=num({{0,.2},{1,1}}),Drag=2},24)
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
				-- (04/11) Minato's space-time barrier: a sphere of bent space round him
				-- and the formula hanging in front of his palms while it lasts.
				if impact.kind=="barrier" then
					local owner=folder and folder:FindFirstChild(impact.owner or "")
					local root=owner and owner:FindFirstChild("HumanoidRootPart")
					local time=impact.time or .9
					local at=if root then root.CFrame else CFrame.new(impact.position)
					local sphere=block(fx.folder,Vector3.new(1,1,1),at,color,Enum.Material.ForceField)
					new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},sphere)
					sphere.Transparency=.2
					tween(sphere,.12,{Size=Vector3.new(9,9,9)})
					task.delay(math.max(.1,time-.2),function() if sphere.Parent then tween(sphere,.2,{Size=Vector3.new(1,1,1),Transparency=1}) end end)
					Debris:AddItem(sphere,time+.3)
					local card=block(fx.folder,Vector3.new(3.4,3.4,.05),at*CFrame.new(0,.4,-2.6),Color3.fromRGB(250,244,226),Enum.Material.SmoothPlastic)
					card.Transparency=1
					local gui=new("SurfaceGui",{Face=Enum.NormalId.Back,LightInfluence=0,Brightness=2,SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud,PixelsPerStud=40},card)
					local label=new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="時空",TextScaled=true,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,214,92),TextTransparency=1},gui)
					tween(label,.1,{TextTransparency=.05})
					task.delay(math.max(.1,time-.2),function() if label.Parent then tween(label,.2,{TextTransparency=1}) end end)
					Debris:AddItem(card,time+.3)
					if root then
						local follow
						follow=game:GetService("RunService").RenderStepped:Connect(function()
							if not sphere.Parent or not root.Parent then follow:Disconnect();return end
							sphere.CFrame=root.CFrame;card.CFrame=root.CFrame*CFrame.new(0,.4,-2.6)
						end)
					end
				end
				return true
			elseif style=="summon" then
				-- (04/11) Naruto's Gamakichi: out of a puff of smoke, a small orange
				-- toad squats in front of him, puffs its cheeks and is gone again.
				local look=Looks[impact.kind or ""] or Looks.toad
				local at=impact.position
				-- (Audit 04/11) on the floor under the summoning point (it floated
				-- 1.6 studs up: the point is the water bullet's origin)
				local ok,floor=pcall(floorUnder,fx,at,3,10)
				if ok and floor then at=Vector3.new(at.X,floor.Position.Y,at.Z) end
				local dir=impact.direction or Vector3.new(0,0,-1)
				local frame=CFrame.lookAt(at,at+Vector3.new(dir.X,0,dir.Z))
				smokePuff(fx.folder,at+Vector3.new(0,.6,0),Color3.fromRGB(240,236,230),22,3.4)
				local m=new("Model",{Name="Gamakichi"},fx.folder)
				local skin,vest=c3(look.color),c3(look.color2)
				local body=block(m,Vector3.new(2.4,1.7,2.6),frame*CFrame.new(0,.85,0),skin,Enum.Material.SmoothPlastic)
				new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},body)
				local belly=block(m,Vector3.new(1.9,1.2,.5),frame*CFrame.new(0,.7,-1.15),Color3.fromRGB(252,214,160),Enum.Material.SmoothPlastic)
				new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},belly)
				local cape=block(m,Vector3.new(2.5,.9,1.6),frame*CFrame.new(0,1.35,.5),vest,Enum.Material.Fabric)
				new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},cape)
				for _,side in {-1,1} do
					local eye=block(m,Vector3.new(.7,.7,.7),frame*CFrame.new(side*.62,1.75,-.7),Color3.fromRGB(250,246,230),Enum.Material.SmoothPlastic)
					new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},eye)
					local pupil=block(m,Vector3.new(.32,.44,.2),frame*CFrame.new(side*.62,1.75,-1.02),Color3.fromRGB(20,16,14),Enum.Material.SmoothPlastic)
					new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},pupil)
					local leg=block(m,Vector3.new(.7,.5,1.2),frame*CFrame.new(side*1.1,.25,-.3),skin,Enum.Material.SmoothPlastic)
					new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},leg)
				end
				local parts={}
				for _,p in m:GetChildren() do if p:IsA("BasePart") then table.insert(parts,{p,p.Size}) ;p.Size=p.Size*.2 end end
				for _,e in parts do tween(e[1],.16,{Size=e[2]}) end
				-- the cheeks puff as it spits
				task.delay(.1,function() if body.Parent then tween(body,.08,{Size=Vector3.new(2.7,1.9,2.6)}) end end)
				task.delay(.22,function() if body.Parent then tween(body,.12,{Size=Vector3.new(2.4,1.7,2.6)}) end end)
				local life=impact.time or 1.4
				task.delay(life,function()
					if not m.Parent then return end
					smokePuff(fx.folder,at+Vector3.new(0,.8,0),Color3.fromRGB(240,236,230),16,2.6)
					m:Destroy()
				end)
				return true
			elseif style=="drain" then
				local owner=folder and folder:FindFirstChild(impact.owner or "")
				local to=owner and owner:FindFirstChild("HumanoidRootPart")
				burst(fx.folder,impact.position,{Texture=TEX.glow,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(4,8),SpreadAngle=Vector2.new(60,60),
					Acceleration=if to then (to.Position-impact.position).Unit*30 else Vector3.zero,Color=ColorSequence.new(Color3.fromRGB(120,190,255)),
					LightEmission=1,Size=num({{0,.8},{1,.1}}),Transparency=num({{0,.2},{1,1}})},10)
				-- An object swallowed by an absorbing window: the reward reads on him.
				if impact.projectile and to then
					flash(fx.folder,to.Position,Color3.fromRGB(196,170,230),1,5,.25,.3)
					shockRing(fx.folder,to.Position-Vector3.new(0,2.6,0),Color3.fromRGB(196,170,230),1.5,7,.3)
				end
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
			-- (04/11) Lee's nunchaku: out of his belt for the blow (attack
			-- "Nunchaku"), two sticks on a chain whirling from the right hand.
			local nun=actor.attackName=="Nunchaku" and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery")
			if nun and not st.nunchaku then
				local hand=model:FindFirstChild("RightHand")
				if hand then
					local m=new("Model",{Name="Nunchaku"},fx.folder)
					local wood=Color3.fromRGB(120,74,40)
					local s1=block(m,Vector3.new(.22,1.3,.22),hand.CFrame,wood,Enum.Material.Wood)
					local s2=block(m,Vector3.new(.22,1.3,.22),hand.CFrame,wood,Enum.Material.Wood)
					local link=block(m,Vector3.new(.06,.5,.06),hand.CFrame,Color3.fromRGB(150,150,156),Enum.Material.Metal)
					st.nunchaku={model=m,a=s1,b=s2,link=link,hand=hand,t0=os.clock()}
				end
			elseif not nun and st.nunchaku then
				st.nunchaku.model:Destroy();st.nunchaku=nil
			end
			if st.nunchaku and st.nunchaku.hand.Parent then
				local n=st.nunchaku
				local spin=(os.clock()-n.t0)*30
				local grip=n.hand.CFrame*CFrame.new(0,-.7,0)
				n.a.CFrame=grip*CFrame.new(0,-.3,0)
				n.link.CFrame=grip*CFrame.new(0,-1.1,0)
				n.b.CFrame=grip*CFrame.new(0,-1.2,0)*CFrame.Angles(spin,0,0)*CFrame.new(0,-.7,0)
			end
			local buffed=fam and fam.buff~=nil
			-- An absorbing window (a Buff with Absorb: Nagato's seal), QA-004 M5:
			-- open, a faint sphere of its radius round him; closed, it folds in
			-- with a ring, so the end of the window reads without F8.
			local absorbSpec=nil
			if buffed then
				local def=Fighters[actor.fighterId or ""]
				for _,spec in SealJutsu.all(def) do if spec.Id==fam.buff and spec.Absorb then absorbSpec=spec end end
			end
			if absorbSpec and not st.absorb then
				local look=Looks[absorbSpec.Kind or "chakra"] or Looks.chakra
				local r=(absorbSpec.Absorb.Radius or 6)
				local sphere=block(fx.folder,Vector3.new(r*2,r*2,r*2),root.CFrame,c3(look.color),Enum.Material.ForceField)
				new("SpecialMesh",{MeshType=Enum.MeshType.Sphere},sphere)
				sphere.Name="AbsorbWindow";sphere.Transparency=.55
				st.absorb=sphere;st.absorbColor=c3(look.color)
			elseif not absorbSpec and st.absorb then
				local sphere=st.absorb;st.absorb=nil
				tween(sphere,.25,{Size=Vector3.new(.5,.5,.5),Transparency=1});Debris:AddItem(sphere,.3)
				shockRing(fx.folder,root.Position-Vector3.new(0,2.6,0),st.absorbColor,6,1,.25)
			end
			if st.absorb then st.absorb.CFrame=root.CFrame end
			-- A buff that draws a weapon (its Kind is a blade/needle look: the
			-- Camellia's bone sword, the chakra scalpel) holds it in the right hand.
			local held=nil
			if buffed then
				local def=Fighters[actor.fighterId or ""]
				for _,spec in SealJutsu.all(def) do
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
