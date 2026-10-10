-- Client-side combat VFX. Everything here is presentation driven by the server
-- snapshot and contact feed: real 3D kunai and shuriken flying on the exact
-- server path, planted Flying Thunder God seals, the Katon fireball, teleport
-- flashes, substitution logs, Itachi's crows, Rasengan and burning ground.
-- Nothing in this module can change gameplay.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local FX={};FX.__index=FX

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
}
-- Contacts that bring the crowd to its feet, by strength.
local CHEER={slam=1,launcher=.7,finisher=.8,fire=1,teleport=.9,parry=.8,substitute=.4,burst=.8}
-- Visual time runs a hair behind the server clock, like the bodies, so a blade
-- leaves the throwing hand on the frame the arm releases it.
FX.DELAY=.06
local STEEL=Color3.fromRGB(64,68,76)
local STEEL_EDGE=Color3.fromRGB(150,158,170)
local MINATO=Color3.fromRGB(255,214,92)
local MINATO_CORE=Color3.fromRGB(255,248,214)

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
local function sound(parent,id,volume,speed)
	local s=new("Sound",{SoundId=id,Volume=volume or .4,PlaybackSpeed=speed or 1,RollOffMaxDistance=160,RollOffMinDistance=12},parent)
	s:Play();Debris:AddItem(s,3)
	return s
end
local function tween(object,time,goal,style,direction)
	local t=TweenService:Create(object,TweenInfo.new(time,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),goal)
	t:Play();return t
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
local function anchorPart(parent,position)
	return block(parent,Vector3.new(.2,.2,.2),CFrame.new(position),Color3.new(),Enum.Material.SmoothPlastic)
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
local function addTrail(root,a,b,color,lifetime,transparency,width)
	local a0=new("Attachment",{Position=a},root)
	local a1=new("Attachment",{Position=b},root)
	return new("Trail",{Attachment0=a0,Attachment1=a1,Color=ColorSequence.new(color),LightEmission=.7,
		Transparency=num({{0,transparency or .35},{1,1}}),Lifetime=lifetime or .12,FaceCamera=true,WidthScale=num({{0,width or 1},{1,.2}})},root)
end
function FX.buildFireball()
	local model=new("Model",{Name="GreatFireball"})
	local root=block(model,Vector3.new(1,1,1),CFrame.new(),Color3.fromRGB(255,240,180),Enum.Material.Neon);root.Name="Root"
	root.Shape=Enum.PartType.Ball;root.Transparency=.05
	local mid=block(model,Vector3.new(1,1,1),CFrame.new(),Color3.fromRGB(255,150,40),Enum.Material.Neon);mid.Shape=Enum.PartType.Ball;mid.Transparency=.35;mid.Name="Mid"
	local outer=block(model,Vector3.new(1,1,1),CFrame.new(),Color3.fromRGB(230,70,20),Enum.Material.Neon);outer.Shape=Enum.PartType.Ball;outer.Transparency=.62;outer.Name="Outer"
	weldAll(root,{mid,outer})
	local at=new("Attachment",{},root)
	emitter(at,{Name="Flames",Enabled=true,Texture=TEX.fire,Rate=140,Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(2,7),SpreadAngle=Vector2.new(180,180),
		Color=seq({{0,Color3.fromRGB(255,240,170)},{.35,Color3.fromRGB(255,140,40)},{.75,Color3.fromRGB(200,50,20)},{1,Color3.fromRGB(60,20,10)}}),
		LightEmission=1,Size=num({{0,3},{.4,5},{1,1.5}}),Transparency=num({{0,.15},{.7,.4},{1,1}}),Drag=3,RotSpeed=NumberRange.new(-120,120),Rotation=NumberRange.new(0,360),ZOffset=1})
	emitter(at,{Name="Smoke",Enabled=true,Texture=TEX.smoke,Rate=26,Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(Color3.fromRGB(60,48,44)),LightEmission=0,Size=num({{0,3},{1,8}}),Transparency=num({{0,.55},{1,1}}),Drag=2})
	emitter(at,{Name="Embers",Enabled=true,Texture=TEX.fireSpark,Rate=40,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(Color3.fromRGB(255,190,90)),LightEmission=1,Size=num({{0,.35},{1,0}}),Acceleration=Vector3.new(0,6,0)})
	new("PointLight",{Color=Color3.fromRGB(255,140,60),Brightness=4,Range=28,Shadows=false},root)
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
local BUILD={kunai=function() return FX.buildKunai(false) end,marked=function() return FX.buildKunai(true) end,
	shuriken=FX.buildShuriken,fireball=FX.buildFireball,wind=FX.buildWind}
-- Snapshot sync: create visuals for newly announced projectiles, mark the ones
-- the server no longer reports.
function FX:sync(data)
	if data.epoch~=self.epoch then self.epoch=data.epoch;self:reset() end
	local live={}
	for _,p in data.projectiles or {} do
		live[p.id]=true
		local entry=self.projectiles[p.id]
		if not entry then
			local build=BUILD[p.kind] or BUILD.kunai
			local model=build()
			model.Parent=self.folder
			local root=model.PrimaryPart
			if p.kind=="kunai" or p.kind=="marked" then
				addTrail(root,Vector3.new(0,.06,.2),Vector3.new(0,-.06,.2),if p.kind=="marked" then MINATO else Color3.fromRGB(220,226,236),.1,.5,1)
			elseif p.kind=="shuriken" then
				addTrail(root,Vector3.new(-.35,0,0),Vector3.new(.35,0,0),Color3.fromRGB(226,232,240),.08,.6,1)
			end
			entry={data=p,model=model,root=root,spin=math.random()*math.pi*2,hidden=true}
			self.projectiles[p.id]=entry
			for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end end
			if p.kind=="fireball" then
				sound(root,SOUND.boom,.35,.55)
			elseif p.kind=="kunai" or p.kind=="marked" or p.kind=="shuriken" then
				sound(root,SOUND.whoosh,.28,if p.kind=="shuriken" then 1.5 else 1.25)
			end
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
	-- Let a trail finish fading instead of cutting it.
	for _,d in entry.model:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency=1 elseif d:IsA("ParticleEmitter") then d.Enabled=false elseif d:IsA("PointLight") then d.Enabled=false end
	end
	Debris:AddItem(entry.model,.6)
	return entry,root
end
function FX:stepProjectiles(dt)
	local t=self:visualTime()
	for id,entry in self.projectiles do
		local p=entry.data
		local age=t-p.born
		if entry.missingSince and os.clock()-entry.missingSince>.35 then
			self:finishProjectile(id)
			continue
		end
		local hidden=age<0
		if hidden~=entry.hidden then
			entry.hidden=hidden
			for _,d in entry.model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=if hidden then 1 else 0 end end
		end
		local travel=math.clamp(age,0,p.range/p.speed)*p.speed
		local position=p.origin+p.direction*travel
		local look=CFrame.lookAt(position,position+p.direction)
		local cf
		if p.kind=="kunai" or p.kind=="marked" then
			-- Point first, with a slow roll so the blade catches the light.
			entry.spin+=dt*14
			cf=look*CFrame.Angles(0,0,entry.spin)
		elseif p.kind=="shuriken" then
			entry.spin+=dt*42
			cf=look*CFrame.Angles(0,entry.spin,0)*CFrame.Angles(0,0,math.rad(8))
		elseif p.kind=="fireball" then
			local radius=(p.radius or 2.4)+(p.growth or 0)*math.max(0,age)
			local wobble=1+math.sin(os.clock()*31)*.05
			entry.root.Size=Vector3.one*radius*1.15*wobble
			local mid=entry.model:FindFirstChild("Mid");local outer=entry.model:FindFirstChild("Outer")
			if mid then mid.Size=Vector3.one*radius*1.7 end
			if outer then outer.Size=Vector3.one*radius*2.25*wobble end
			local flames=entry.root:FindFirstChildOfClass("Attachment")
			if flames then
				local f=flames:FindFirstChild("Flames");if f then f.Size=num({{0,radius*1.1},{.4,radius*1.9},{1,radius*.6}}) end
			end
			cf=look*CFrame.Angles(0,0,os.clock()*3)
		else
			cf=look
		end
		entry.root.CFrame=cf
	end
end

-- ------------------------------------------------------------------ helpers
local function flash(parent,position,color,from,to,time,transparency)
	local ball=block(parent,Vector3.one*from,CFrame.new(position),color,Enum.Material.Neon)
	ball.Shape=Enum.PartType.Ball;ball.Transparency=transparency or .15
	tween(ball,time,{Size=Vector3.one*to,Transparency=1})
	Debris:AddItem(ball,time+.05)
	return ball
end
local function shockRing(parent,position,color,from,to,time,normal)
	local up=normal or Vector3.yAxis
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
	burst(parent,position,{Texture=TEX.smoke,Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(4,9),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(color or Color3.fromRGB(236,236,240)),LightEmission=0,Size=num({{0,size or 2.2},{1,(size or 2.2)*2.6}}),
		Transparency=num({{0,.15},{1,1}}),Drag=6,RotSpeed=NumberRange.new(-60,60),Rotation=NumberRange.new(0,360)},count or 18)
end
local function sparks(parent,position,color,count,speed)
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

-- ------------------------------------------------------------------ contacts
local function modelFor(folder,id)
	return folder and folder:FindFirstChild(id or "")
end
function FX:impact(impact,folder)
	local style=impact.style
	local position=impact.position
	if not position then return end
	if impact.projectile then
		local entry=self.projectiles[impact.projectile]
		local direction=impact.direction or (entry and entry.data.direction) or Vector3.zAxis
		if entry then self:finishProjectile(impact.projectile) end
		if style=="stick" and (impact.kind=="kunai" or impact.kind=="marked" or impact.kind=="shuriken") then
			self:stick(impact.kind,position,impact.normal or Vector3.yAxis,direction,impact.owner)
		end
	end
	if CHEER[style] then self:cheer(CHEER[style]) end
	if style=="fire" then
		self:explosion(position,impact.normal)
	elseif style=="teleport" then
		self:teleport(impact.from or position,impact.to or position,modelFor(folder,impact.owner))
	elseif style=="substitute" then
		self:substitute(position,impact.to,impact.fighter,modelFor(folder,impact.owner))
	elseif style=="mirage" then
		crows(self.folder,position+Vector3.new(0,1,0),9,10)
		if impact.to then crows(self.folder,impact.to+Vector3.new(0,1,0),5,6) end
	elseif style=="chase" then
		local model=modelFor(folder,impact.owner)
		self:ghost(model,if impact.fighter=="Flashstep" then MINATO else Color3.fromRGB(150,40,60),.22,.55)
		smokePuff(self.folder,position-Vector3.new(0,2.6,0),Color3.fromRGB(200,190,170),8,1.4)
		sound(anchorPart(self.folder,position),SOUND.whoosh,.35,.8)
	elseif style=="dodge" then
		local nearest
		for _,name in {"PlayerFighter","AIFighter"} do
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
			local color=if impact.technique=="FireBloom" then Color3.fromRGB(255,120,50) elseif impact.technique=="MirageCast" or impact.technique=="Read" then Color3.fromRGB(220,30,40)
				elseif impact.technique=="WindCut" then Color3.fromRGB(170,255,220) else Color3.fromRGB(140,200,255)
			sparks(self.folder,hands.Position,color,10,8)
		end
	elseif style=="landing" then
		smokePuff(self.folder,position-Vector3.new(0,2.7,0),Color3.fromRGB(190,178,150),6,1.1)
	elseif style=="slam" then
		smokePuff(self.folder,position-Vector3.new(0,2.4,0),Color3.fromRGB(176,160,130),22,2.6)
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
	end
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
function FX:explosion(position,normal)
	local holder=anchorPart(self.folder,position);holder.Transparency=1
	sound(holder,SOUND.boom,.75,.95)
	flash(self.folder,position,Color3.fromRGB(255,236,170),3,15,.35,.05)
	flash(self.folder,position,Color3.fromRGB(255,120,40),5,19,.5,.35)
	shockRing(self.folder,position,Color3.fromRGB(255,170,90),4,26,.38,normal)
	burst(self.folder,position,{Texture=TEX.fire,Lifetime=NumberRange.new(.45,.9),Speed=NumberRange.new(14,30),SpreadAngle=Vector2.new(180,180),
		Color=seq({{0,Color3.fromRGB(255,240,170)},{.4,Color3.fromRGB(255,130,40)},{1,Color3.fromRGB(80,24,10)}}),LightEmission=1,
		Size=num({{0,4},{.5,7},{1,2}}),Transparency=num({{0,.1},{1,1}}),Drag=4,RotSpeed=NumberRange.new(-90,90),Rotation=NumberRange.new(0,360)},34)
	burst(self.folder,position,{Texture=TEX.smoke,Lifetime=NumberRange.new(1.2,2.2),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(Color3.fromRGB(56,48,46)),LightEmission=0,Size=num({{0,5},{1,14}}),Transparency=num({{0,.35},{1,1}}),Drag=3,Acceleration=Vector3.new(0,5,0)},18)
	burst(self.folder,position,{Texture=TEX.fireSpark,Lifetime=NumberRange.new(.6,1.2),Speed=NumberRange.new(20,44),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(Color3.fromRGB(255,196,110)),LightEmission=1,Size=num({{0,.5},{1,0}}),Drag=2,Acceleration=Vector3.new(0,-30,0)},40)
	local light=new("PointLight",{Color=Color3.fromRGB(255,150,70),Brightness=9,Range=40,Shadows=false},holder)
	tween(light,.7,{Brightness=0})
	-- Scorched ground under the blast.
	local floor=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-12,0))
	if floor then
		local scorch=block(self.folder,Vector3.new(.05,9,9),CFrame.new(floor.Position+floor.Normal*.04)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(24,18,16),Enum.Material.Slate)
		scorch.Shape=Enum.PartType.Cylinder;scorch.Transparency=.25
		task.delay(3.5,function() tween(scorch,1.5,{Transparency=1}) end)
		Debris:AddItem(scorch,5.2)
	end
end
function FX:teleport(from,to,model)
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
	shockRing(self.folder,to-Vector3.new(0,2.6,0),MINATO,2,16,.3)
	sparks(self.folder,to,MINATO,18,24)
	local holder=anchorPart(self.folder,to);holder.Transparency=1
	sound(holder,SOUND.whoosh,.55,1.6)
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

-- ------------------------------------------------------------------ persistent
-- Planted Flying Thunder God seals: a real three-pronged kunai in the surface
-- and a slowly pulsing seal formula around it.
function FX:seal(owner,actor)
	local entry=self.seals[owner]
	local surface=actor and actor.anchorSurface
	if not surface then
		if entry then
			for _,d in entry.model:GetDescendants() do if d:IsA("BasePart") then tween(d,.15,{Transparency=1}) end end
			Debris:AddItem(entry.model,.2);Debris:AddItem(entry.glyph,.2)
			self.seals[owner]=nil
		end
		return
	end
	local normal=actor.anchorNormal or Vector3.yAxis
	if entry and (entry.surface-surface).Magnitude>.05 then
		entry.model:Destroy();entry.glyph:Destroy();entry=nil;self.seals[owner]=nil
	end
	if not entry then
		local model=FX.buildKunai(true)
		model.Parent=self.folder
		local into=-normal
		local tilt=(if math.abs(normal.Y)>.7 then Vector3.xAxis else Vector3.yAxis)*.35
		local axis=(into+tilt).Unit
		model:PivotTo(CFrame.lookAt(surface-axis*.55,surface-axis*.55+axis))
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
		self.seals[owner]=entry
		flash(self.folder,surface,MINATO,.6,3.5,.2,.2)
	end
	local pulse=.5+.5*math.sin((os.clock()-entry.born)*4)
	entry.disc.Transparency=.72+pulse*.18
	entry.light.Brightness=1+pulse*1.2
end
function FX:hazardsStep(data)
	local live={}
	for _,h in data.hazards or {} do
		local key=string.format("%s:%.1f:%.1f:%.1f",tostring(h.kind),h.position.X,h.position.Y,h.position.Z)
		live[key]=true
		local entry=self.hazards[key]
		if not entry then
			local floor=workspace:Raycast(h.position+Vector3.new(0,3,0),Vector3.new(0,-14,0))
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
		entry.light.Brightness=2.4+math.sin(os.clock()*22)*.6+math.sin(os.clock()*9)*.5
		entry.emitter.Rate=if h.remaining<.4 then 25 else 60
	end
	for key,entry in self.hazards do
		if not live[key] then
			entry.emitter.Enabled=false;tween(entry.light,.3,{Brightness=0})
			Debris:AddItem(entry.holder,1);self.hazards[key]=nil
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
		local color=if minato then MINATO else Color3.fromRGB(170,30,48)
		aura.trail=addTrail(root,Vector3.new(0,1.6,.3),Vector3.new(0,-1.9,.3),color,if minato then .16 else .12,.62,1)
		aura.trail.Enabled=false
		local eyes=model:FindFirstChild("Eyes")
		aura.eyes=eyes
	end
	local speed=actor.speed or 0
	local fast=actor.state=="Dodging" or actor.state=="Pursuit" or actor.flash or (actor.fighterId=="Flashstep" and speed>34)
	aura.trail.Enabled=fast==true and (actor.health or 1)>0
	-- Itachi: the Sharingan flares while he reads, casts, or sizes up an opponent.
	if aura.eyes and actor.fighterId=="Mirage" then
		local lit=(actor.read or 0)>0 or actor.castId=="MirageCast" or actor.castId=="Read" or actor.castId=="FireBloom" or (actor.intro or 0)>0
		aura.eyes.Color=if lit then Color3.fromRGB(255,40,40) else Color3.fromRGB(190,20,30)
		aura.eyes.Material=Enum.Material.Neon
	end
	-- Rasengan forms in the right hand during the channel and stays through the strike.
	local rasengan=(actor.castId=="BurstStrike" and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive"))
		or (actor.attackVariant=="Rasengan" and (actor.state=="Startup" or actor.state=="Active"))
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
	if actor.fighterId=="Mirage" then
		local head=model:FindFirstChild("Head")
		local casting=actor.castId=="FireBloom" and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive")
		if casting and head then
			if not aura.mouth then
				local at=new("Attachment",{Position=Vector3.new(0,-.25,-.8)},head)
				aura.mouth=new("ParticleEmitter",{Texture=TEX.fire,Rate=0,Lifetime=NumberRange.new(.15,.3),Speed=NumberRange.new(4,10),
					SpreadAngle=Vector2.new(18,18),EmissionDirection=Enum.NormalId.Front,Color=seq({{0,Color3.fromRGB(255,230,150)},{1,Color3.fromRGB(255,90,30)}}),
					LightEmission=1,LightInfluence=0,Size=num({{0,.6},{1,1.6}}),Transparency=num({{0,.2},{1,1}})},at)
				aura.mouthLight=new("PointLight",{Color=Color3.fromRGB(255,140,60),Brightness=0,Range=10,Shadows=false},at)
			end
			local breathing=actor.state=="TechniqueActive"
			aura.mouth.Rate=if breathing then 90 else 14
			aura.mouthLight.Brightness=if breathing then 4 else 1.2
		elseif aura.mouth then
			aura.mouth.Rate=0;aura.mouthLight.Brightness=0
		end
	end
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
	if not data or data.phase~="Duel" then
		if self.epoch~=nil and data and data.phase=="Selection" then self.epoch=nil;self:reset() end
		self:stepProjectiles(dt)
		return
	end
	self:stepProjectiles(dt)
	self:hazardsStep(data)
	self:crowdOf(folder)
	self:ambient(dt)
	for _,key in {"human","bot"} do
		local actor=data[key]
		if actor then
			actor.intro=data.intro
			self:seal(actor.id or key,actor)
			local model=folder and folder:FindFirstChild(actor.id or "")
			self:fighter(model,actor,dt)
		end
	end
end
return FX
