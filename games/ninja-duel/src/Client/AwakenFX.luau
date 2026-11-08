-- The awakenings, seen for the whole state (lot 3 animation, 08/11).
--
-- Studio audit (ND-DEV @ 4a8ec28, 08/11): once the entry had passed, the eight
-- awakenings looked almost like the normal fighter: a tinted floor light, the
-- same broken slabs for all, a red eye, a faint mantle of 55 tiny fire specks
-- on the chest (Effects) and, for Lee, a steam that hardly showed. This layer
-- gives each awakening its own look, held as long as the state lasts, and its
-- own entry, in the direction of the VFX bible (06/11): anime, a little colour,
-- few layers, nothing in plain Neon, textures drawn for the game
-- (tools/vfx/vfxgen.py, ids uploaded on 06/11, branch claude/vfx-redesign).
--
--   Sasuke   CURSE MARK          dark wisps and purple flame tongues off the marked side
--   Naruto   NINE-TAILS CHAKRA   the red cloak burns on every limb (the tail: NarutoFX)
--   Gaara    SHUKAKU'S SAND      three streams of sand circling him, grains in the air
--   Lee      EIGHT GATES         green steam off the whole body, growing with each gate
--   Neji     BYAKUGAN FULL FIELD chakra burning in both palms, the field pulsing on the floor
--   Itachi   SHARINGAN FOCUS     crow feathers coming off him, a red mist at his feet
--   Kakashi  SHARINGAN UNCOVERED the lightning crackling in his hand, the eye lit
--   Minato   YELLOW FLASH        golden sparks torn off him as he moves, the formula at entry
--
-- One identity layer installed into Effects like the others. Presentation
-- only: nothing here can change gameplay.
local Debris=game:GetService("Debris")

local AwakenFX={}
local K -- Effects' helpers, handed over by install()
AwakenFX.clock=os.clock
AwakenFX.enabled=true

-- Textures of the VFX bible (06/11), uploaded under the game's owner.
local ID={
	smoke="rbxassetid://74803998450943",      -- 4x4, cel smoke that tears apart (white, tinted)
	dust="rbxassetid://110630590889405",      -- 4x4, flat dust (white, tinted)
	fireBurst="rbxassetid://102546534361734", -- 4x4, an explosion's flame (coloured)
	flame="rbxassetid://99943034086282",      -- 4x4 loop, a licking flame (coloured)
	lightning="rbxassetid://100625761935181", -- 4x4 loop, white bolts
	spark="rbxassetid://79205682571618",      -- a long tapered streak (white)
	ring="rbxassetid://126225681093802",      -- a broken pressure ring (white)
	leaf="rbxassetid://132068074134721",      -- 2x2, four leaves
	feather="rbxassetid://79191268061599",    -- 2x2, four dark feathers
	debris="rbxassetid://80574510604813",     -- 2x2, four rock shards (grey)
	glyph="rbxassetid://139199375333619",     -- the Flying Thunder God formula
	glow="rbxasset://textures/particles/forcefield_glow_main.dds",
}
local GRID4=Enum.ParticleFlipbookLayout.Grid4x4
local GRID2=Enum.ParticleFlipbookLayout.Grid2x2
local LAYOUT={smoke=GRID4,dust=GRID4,fireBurst=GRID4,flame=GRID4,lightning=GRID4,leaf=GRID2,feather=GRID2,debris=GRID2}
local MODE={flame=Enum.ParticleFlipbookMode.Loop,lightning=Enum.ParticleFlipbookMode.Loop,
	leaf=Enum.ParticleFlipbookMode.Random,feather=Enum.ParticleFlipbookMode.Random,debris=Enum.ParticleFlipbookMode.Random}
AwakenFX.ID=ID

local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function range(a,b) return NumberRange.new(a,b or a) end
-- One emitter. `spec` uses ParticleEmitter property names; tex names a texture.
local function emitter(parent,tex,spec)
	local e=Instance.new("ParticleEmitter")
	e.Texture=ID[tex] or tex
	if LAYOUT[tex] then
		e.FlipbookLayout=LAYOUT[tex]
		e.FlipbookMode=MODE[tex] or Enum.ParticleFlipbookMode.OneShot
		if e.FlipbookMode==Enum.ParticleFlipbookMode.Loop then e.FlipbookFramerate=range(18,24) end
	end
	e.LightInfluence=0
	for k,v in spec do
		-- (a size or a transparency given as a range is a random constant)
		if (k=="Size" or k=="Transparency") and typeof(v)=="NumberRange" then v=NumberSequence.new(v.Min+(v.Max-v.Min)*math.random()) end
		(e::any)[k]=v
	end
	e.Parent=parent
	return e
end
AwakenFX.emitter=emitter
local function attach(part,name,position)
	local a=Instance.new("Attachment")
	a.Name=name;a.Position=position or Vector3.zero;a.Parent=part
	return a
end
-- A flat sprite on the floor (a ring, a formula) that opens and fades.
local function floorSprite(folder,position,tex,color,from,to,time,transparency)
	local holder=Instance.new("Part")
	holder.Name="AwakenFloor";holder.Anchored=true;holder.CanCollide=false;holder.CanQuery=false;holder.CanTouch=false
	holder.Transparency=1;holder.Size=Vector3.one*.2;holder.CFrame=CFrame.new(position);holder.Parent=folder
	local e=emitter(holder,tex,{Enabled=false,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,EmissionDirection=Enum.NormalId.Top,
		Speed=range(.01),Lifetime=range(time),Rotation=range(0,360),Color=ColorSequence.new(color),LightEmission=.6,
		Size=seq({{0,from},{.35,to*.8},{1,to}}),Transparency=seq({{0,transparency or .15},{.6,(transparency or .15)+.3},{1,1}}),ZOffset=.2})
	e:Emit(1)
	Debris:AddItem(holder,time+.2)
	return holder
end
AwakenFX.floorSprite=floorSprite
-- A burst at a point (no emitter kept).
local function burst(folder,position,tex,count,spec)
	local holder=Instance.new("Part")
	holder.Name="AwakenBurst";holder.Anchored=true;holder.CanCollide=false;holder.CanQuery=false;holder.CanTouch=false
	holder.Transparency=1;holder.Size=Vector3.one*.2;holder.CFrame=CFrame.new(position);holder.Parent=folder
	local e=emitter(holder,tex,spec)
	e.Enabled=false
	e:Emit(count)
	Debris:AddItem(holder,(spec.Lifetime and spec.Lifetime.Max or 1)+.2)
end
AwakenFX.burst=burst
local function floorY(fx,root)
	local ok,hit=pcall(function() return K.floorUnder(fx,root.Position,3,12) end)
	return if ok and hit then hit.Position.Y+.08 else root.Position.Y-2.95
end

-- ------------------------------------------------------------------ recipes
-- Each recipe: hold(model, st) builds what stays on the body (returns the
-- instances to clear), step(model, actor, st, dt) for what moves (optional),
-- entry(fx, model, root, floor) the moment it opens.
local LIMBS={"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftUpperLeg","RightUpperLeg","Head"}
local function surface(part,tex,spec)
	-- Emitted from the part's own surface: the effect wraps the body.
	spec.Shape=Enum.ParticleEmitterShape.Box
	spec.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
	spec.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
	return emitter(part,tex,spec)
end
local function eachLimb(model,names,fn)
	local out={}
	for _,name in names do
		local p=model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local made=fn(p,name)
			if made then table.insert(out,made) end
		end
	end
	return out
end

local R={}
AwakenFX.RECIPES=R

-- Sasuke: the seal spreads from the left side of the neck; dark chakra
-- leaks off that side, purple tongues lick up from it.
local CURSE_DARK=Color3.fromRGB(46,18,62)
local CURSE=Color3.fromRGB(170,96,255)
R.Lion={
	hold=function(model)
		return eachLimb(model,{"Head","UpperTorso","LeftUpperArm","LeftLowerArm"},function(p,name)
			local side=name~="UpperTorso"
			local a=surface(p,"smoke",{Rate=if side then 7 else 9,Lifetime=range(.55,.85),Speed=range(.8,1.8),EmissionDirection=Enum.NormalId.Top,
				Acceleration=Vector3.new(0,3.5,0),Color=ColorSequence.new(CURSE_DARK),LightEmission=0,
				Size=seq({{0,.9},{.5,1.9},{1,2.5}}),Transparency=seq({{0,.15},{.7,.45},{1,1}}),Rotation=range(0,360),RotSpeed=range(-60,60)})
			local b=surface(p,"spark",{Rate=if side then 6 else 3,Lifetime=range(.22,.36),Speed=range(3,5),EmissionDirection=Enum.NormalId.Top,
				Orientation=Enum.ParticleOrientation.VelocityParallel,Color=ColorSequence.new(CURSE),LightEmission=.55,
				Size=seq({{0,.45},{1,.1}}),Transparency=seq({{0,.1},{1,1}})})
			return {a,b}
		end)
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,Vector3.new(root.Position.X,floor+.6,root.Position.Z),"smoke",18,{Lifetime=range(.6,.9),Speed=range(10,16),SpreadAngle=Vector2.new(180,8),
			EmissionDirection=Enum.NormalId.Top,Drag=4,Color=ColorSequence.new(CURSE_DARK),LightEmission=0,Size=seq({{0,1.6},{1,3.4}}),
			Transparency=seq({{0,.15},{1,1}}),Rotation=range(0,360)})
		burst(fx.folder,root.Position,"spark",20,{Lifetime=range(.25,.45),Speed=range(16,30),SpreadAngle=Vector2.new(25,25),EmissionDirection=Enum.NormalId.Top,
			Orientation=Enum.ParticleOrientation.VelocityParallel,Color=ColorSequence.new(CURSE),LightEmission=.7,Size=seq({{0,1},{1,.2}}),Transparency=seq({{0,0},{1,1}})})
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"ring",CURSE_DARK,3,16,.45,.2)
	end,
	light=Color3.fromRGB(150,80,230),
}

-- Naruto: the version-one cloak burns on every limb (red chakra boiling up);
-- NarutoFX keeps the shell, the ears and the tail.
local FOX=Color3.fromRGB(255,120,70)
R.Legion={
	hold=function(model)
		return eachLimb(model,LIMBS,function(p,name)
			local big=name=="UpperTorso" or name=="LowerTorso"
			-- (Studio 08/11, quality 10 and 15: the flame fills a narrow part
			-- of its cell, so a "1 stud" flame was a hidden speck)
			return surface(p,"flame",{Rate=if big then 14 else 7,Lifetime=range(.35,.55),Speed=range(.6,1.6),EmissionDirection=Enum.NormalId.Top,
				Acceleration=Vector3.new(0,5,0),Color=ColorSequence.new(FOX),LightEmission=.35,
				Size=seq({{0,1.3},{.4,2.3},{1,.6}}),Transparency=seq({{0,.2},{.6,.4},{1,1}})})
		end)
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,root.Position,"fireBurst",3,{Lifetime=range(.45,.55),Speed=range(0),Color=ColorSequence.new(Color3.fromRGB(255,170,140)),LightEmission=.4,
			Size=seq({{0,5},{1,9}}),Transparency=seq({{0,0},{1,.3}}),Rotation=range(0,360)})
		burst(fx.folder,Vector3.new(root.Position.X,floor+.5,root.Position.Z),"smoke",16,{Lifetime=range(.5,.8),Speed=range(12,18),SpreadAngle=Vector2.new(180,6),
			EmissionDirection=Enum.NormalId.Top,Drag=5,Color=ColorSequence.new(Color3.fromRGB(150,60,40)),LightEmission=.1,Size=seq({{0,1.4},{1,3}}),
			Transparency=seq({{0,.25},{1,1}}),Rotation=range(0,360)})
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"ring",FOX,3,18,.4,.15)
	end,
	light=Color3.fromRGB(255,110,50),
}

-- Gaara: three streams of sand circle him at different heights; loose
-- grains hang in the air around him.
local SAND=Color3.fromRGB(222,190,132)
local SAND_DARK=Color3.fromRGB(170,136,86)
R.Sand={
	hold=function(model,st)
		local root=model:FindFirstChild("HumanoidRootPart")
		if not root then return {} end
		local out={}
		st.orbit={}
		for k=1,3 do
			local a=attach(root,"SandOrbit",Vector3.zero)
			table.insert(out,a)
			table.insert(st.orbit,{attachment=a,phase=k*2.1,height=-1.6+k*1.05,radius=2.2+(k%2)*.5,speed=2.4+k*.35})
			emitter(a,"dust",{Rate=34,Lifetime=range(.45,.7),Speed=range(.1,.4),SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(SAND,SAND_DARK),
				LightEmission=0,LightInfluence=.6,Size=seq({{0,.7},{1,1.4}}),Transparency=seq({{0,.1},{.7,.35},{1,1}}),Rotation=range(0,360)})
			emitter(a,"debris",{Rate=10,Lifetime=range(.5,.8),Speed=range(.5,1.5),SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(SAND),
				LightEmission=0,LightInfluence=.8,Size=range(.18,.28),Transparency=range(0),Rotation=range(0,360),RotSpeed=range(-200,200)})
		end
		return out
	end,
	step=function(model,actor,st,dt)
		local t=AwakenFX.clock()
		for _,o in st.orbit or {} do
			local a=o.phase+t*o.speed
			o.attachment.Position=Vector3.new(math.cos(a)*o.radius,o.height+math.sin(t*1.7+o.phase)*.25,math.sin(a)*o.radius)
		end
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,Vector3.new(root.Position.X,floor+.4,root.Position.Z),"dust",26,{Lifetime=range(.6,1),Speed=range(14,22),SpreadAngle=Vector2.new(180,10),
			EmissionDirection=Enum.NormalId.Top,Drag=4,Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=.7,Size=seq({{0,1.5},{1,3.6}}),
			Transparency=seq({{0,0},{1,1}}),Rotation=range(0,360)})
		burst(fx.folder,root.Position,"debris",24,{Lifetime=range(.6,1),Speed=range(10,20),SpreadAngle=Vector2.new(70,70),EmissionDirection=Enum.NormalId.Top,
			Acceleration=Vector3.new(0,-30,0),Color=ColorSequence.new(SAND),LightInfluence=.8,Size=range(.25,.45),Rotation=range(0,360),RotSpeed=range(-300,300)})
	end,
	light=Color3.fromRGB(232,196,120),
}

-- Lee: the gates burn the body; green steam tears off every limb, more with
-- each gate open (LeeFX keeps the flush of the skin).
local GATE_STEAM=Color3.fromRGB(176,255,196)
R.Leaf={
	hold=function(model,st)
		st.steam=eachLimb(model,LIMBS,function(p,name)
			return surface(p,"smoke",{Rate=8,Lifetime=range(.45,.75),Speed=range(1.8,3.6),EmissionDirection=Enum.NormalId.Top,
				Acceleration=Vector3.new(0,4,0),Color=ColorSequence.new(GATE_STEAM),LightEmission=.25,
				Size=seq({{0,.9},{.5,2},{1,2.8}}),Transparency=seq({{0,.1},{.6,.35},{1,1}}),Rotation=range(0,360),RotSpeed=range(-90,90)})
		end)
		local root=model:FindFirstChild("HumanoidRootPart")
		local out=table.clone(st.steam)
		if root then
			local a=attach(root,"GateLeaves",Vector3.new(0,-2.4,0))
			emitter(a,"leaf",{Rate=3,Lifetime=range(.9,1.4),Speed=range(3,6),SpreadAngle=Vector2.new(60,60),EmissionDirection=Enum.NormalId.Top,
				Acceleration=Vector3.new(0,-4,0),Color=ColorSequence.new(Color3.new(1,1,1)),LightInfluence=.6,Size=range(.35,.5),Rotation=range(0,360),RotSpeed=range(-240,240)})
			table.insert(out,a)
		end
		st.gateShown=nil
		return out
	end,
	step=function(model,actor,st)
		local gate=actor.gate or 1
		if st.gateShown~=gate then
			st.gateShown=gate
			for _,e in st.steam or {} do e.Rate=7+gate*1.6 end
		end
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,Vector3.new(root.Position.X,floor+.4,root.Position.Z),"dust",22,{Lifetime=range(.5,.8),Speed=range(16,24),SpreadAngle=Vector2.new(180,6),
			EmissionDirection=Enum.NormalId.Top,Drag=5,Color=ColorSequence.new(Color3.fromRGB(214,204,180)),LightInfluence=.7,Size=seq({{0,1.2},{1,3}}),
			Transparency=seq({{0,0},{1,1}}),Rotation=range(0,360)})
		burst(fx.folder,root.Position,"smoke",14,{Lifetime=range(.5,.8),Speed=range(8,14),SpreadAngle=Vector2.new(180,180),Drag=3,
			Color=ColorSequence.new(GATE_STEAM),LightEmission=.4,Size=seq({{0,1.5},{1,3.2}}),Transparency=seq({{0,.2},{1,1}}),Rotation=range(0,360)})
		burst(fx.folder,root.Position,"leaf",16,{Lifetime=range(.8,1.3),Speed=range(10,18),SpreadAngle=Vector2.new(180,40),Acceleration=Vector3.new(0,-8,0),
			LightInfluence=.6,Size=range(.4,.6),Rotation=range(0,360),RotSpeed=range(-300,300)})
	end,
	light=Color3.fromRGB(120,230,140),
}

-- Neji: the chakra burns in both palms (the Gentle Fist ready), and the full
-- field sweeps the floor around him, a pulse every 1.3 s.
local HYUGA=Color3.fromRGB(200,218,255)
R.GentleFist={
	hold=function(model,st)
		st.pulseAt=AwakenFX.clock()+.4
		return eachLimb(model,{"LeftHand","RightHand"},function(p)
			local a=surface(p,"smoke",{Rate=14,Lifetime=range(.25,.4),Speed=range(1,2.2),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,5,0),
				Color=ColorSequence.new(HYUGA),LightEmission=.7,Size=seq({{0,.35},{.5,.7},{1,.2}}),Transparency=seq({{0,.15},{1,1}}),Rotation=range(0,360)})
			local b=emitter(p,"glow",{Rate=8,Lifetime=range(.12,.18),Speed=range(0),Color=ColorSequence.new(HYUGA),LightEmission=1,
				Size=seq({{0,1.1},{1,.8}}),Transparency=seq({{0,.35},{1,1}})})
			return {a,b}
		end)
	end,
	step=function(model,actor,st,dt,fx)
		local now=AwakenFX.clock()
		if now<(st.pulseAt or 0) then return end
		st.pulseAt=now+1.3
		local root=model:FindFirstChild("HumanoidRootPart")
		if root then floorSprite(fx.folder,Vector3.new(root.Position.X,floorY(fx,root),root.Position.Z),"ring",HYUGA,2,22,.75,.45) end
	end,
	entry=function(fx,model,root,floor)
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"ring",HYUGA,2,28,.5,.05)
		burst(fx.folder,root.Position,"glow",1,{Lifetime=range(.18),Speed=range(0),Color=ColorSequence.new(HYUGA),LightEmission=1,Size=seq({{0,3},{1,8}}),Transparency=seq({{0,.2},{1,1}})})
	end,
	light=Color3.fromRGB(190,210,255),
}

-- Itachi: feathers come off his shoulders and fall; a red mist lies at his feet.
local MIST=Color3.fromRGB(96,10,20)
R.Mirage={
	hold=function(model)
		local out=eachLimb(model,{"UpperTorso","LeftUpperArm","RightUpperArm"},function(p)
			return surface(p,"feather",{Rate=2.5,Lifetime=range(1.2,1.8),Speed=range(1,2.5),EmissionDirection=Enum.NormalId.Top,SpreadAngle=Vector2.new(80,80),
				Acceleration=Vector3.new(0,-2.2,0),Drag=1,Color=ColorSequence.new(Color3.fromRGB(200,200,215)),LightInfluence=.7,
				Size=range(.45,.7),Transparency=seq({{0,0},{.8,0},{1,1}}),Rotation=range(0,360),RotSpeed=range(-120,120)})
		end)
		local root=model:FindFirstChild("HumanoidRootPart")
		if root then
			local a=attach(root,"RedMist",Vector3.new(0,-2.6,0))
			emitter(a,"smoke",{Rate=7,Lifetime=range(.9,1.4),Speed=range(1,2.4),SpreadAngle=Vector2.new(180,4),EmissionDirection=Enum.NormalId.Top,Drag=1.5,
				Color=ColorSequence.new(MIST),LightEmission=.05,Size=seq({{0,1.2},{1,3.4}}),Transparency=seq({{0,.45},{.5,.6},{1,1}}),Rotation=range(0,360),RotSpeed=range(-30,30)})
			table.insert(out,a)
		end
		return out
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,root.Position+Vector3.new(0,.6,0),"feather",34,{Lifetime=range(.9,1.5),Speed=range(8,16),SpreadAngle=Vector2.new(180,180),Drag=3,
			Acceleration=Vector3.new(0,-3,0),Color=ColorSequence.new(Color3.fromRGB(200,200,215)),LightInfluence=.7,Size=range(.6,.9),Rotation=range(0,360),RotSpeed=range(-300,300)})
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"ring",Color3.fromRGB(200,30,40),3,14,.45,.2)
	end,
	light=Color3.fromRGB(230,40,50),
}

-- Kakashi: the lightning lives in his hand while the eye is uncovered.
local BOLT=Color3.fromRGB(176,214,255)
R.Copycat={
	hold=function(model)
		local out=eachLimb(model,{"RightHand","RightLowerArm"},function(p,name)
			return surface(p,"lightning",{Rate=if name=="RightHand" then 10 else 4,Lifetime=range(.08,.14),Speed=range(.5,2),SpreadAngle=Vector2.new(180,180),
				Color=ColorSequence.new(BOLT),LightEmission=1,Size=seq({{0,.9},{1,.6}}),Transparency=seq({{0,0},{1,.4}}),Rotation=range(0,360)})
		end)
		local torso=model:FindFirstChild("UpperTorso")
		if torso then
			table.insert(out,surface(torso,"lightning",{Rate=2.5,Lifetime=range(.06,.1),Speed=range(.2),Color=ColorSequence.new(BOLT),LightEmission=1,
				Size=range(1.1,1.6),Transparency=range(.1),Rotation=range(0,360)}))
		end
		return out
	end,
	entry=function(fx,model,root,floor)
		burst(fx.folder,root.Position,"lightning",12,{Lifetime=range(.1,.2),Speed=range(10,20),SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(BOLT),
			LightEmission=1,Size=range(2,3),Rotation=range(0,360)})
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"ring",Color3.fromRGB(226,40,50),3,14,.4,.2)
	end,
	light=Color3.fromRGB(176,214,255),
}

-- Minato: golden sparks are torn off him as he moves (more the faster he
-- goes); the formula opens under him at the entry.
local FLASH=Color3.fromRGB(255,222,120)
R.Flashstep={
	hold=function(model,st)
		st.sparks=eachLimb(model,{"UpperTorso","LowerTorso","LeftUpperLeg","RightUpperLeg","Head"},function(p)
			return surface(p,"spark",{Rate=2,Lifetime=range(.18,.3),Speed=range(.5,1.5),Orientation=Enum.ParticleOrientation.VelocityParallel,
				SpreadAngle=Vector2.new(30,30),EmissionDirection=Enum.NormalId.Back,Color=ColorSequence.new(FLASH),LightEmission=.8,
				Size=seq({{0,.6},{1,.1}}),Transparency=seq({{0,.05},{1,1}})})
		end)
		return table.clone(st.sparks)
	end,
	step=function(model,actor,st)
		local speed=actor.speed or 0
		local rate=2+math.clamp(speed/45,0,1)*22
		for _,e in st.sparks or {} do e.Rate=rate end
	end,
	entry=function(fx,model,root,floor)
		floorSprite(fx.folder,Vector3.new(root.Position.X,floor,root.Position.Z),"glyph",FLASH,2,9,.7,.05)
		burst(fx.folder,root.Position,"spark",26,{Lifetime=range(.2,.35),Speed=range(20,36),SpreadAngle=Vector2.new(180,180),
			Orientation=Enum.ParticleOrientation.VelocityParallel,Color=ColorSequence.new(FLASH),LightEmission=.9,Size=seq({{0,1.2},{1,.2}}),Transparency=seq({{0,0},{1,1}})})
	end,
	light=Color3.fromRGB(255,214,92),
}

-- ------------------------------------------------------------------ per frame
local function stateOf(fx,model)
	fx.awakenState=fx.awakenState or setmetatable({},{__mode="k"})
	local st=fx.awakenState[model]
	if not st then st={};fx.awakenState[model]=st end
	return st
end
local function clear(st,fade)
	for _,item in st.items or {} do
		if typeof(item)=="Instance" and item.Parent then
			if item:IsA("ParticleEmitter") then item.Enabled=false;Debris:AddItem(item,fade and 1.5 or 0)
			else
				for _,d in item:GetDescendants() do if d:IsA("ParticleEmitter") then d.Enabled=false end end
				Debris:AddItem(item,fade and 1.5 or 0)
			end
		elseif type(item)=="table" then
			for _,sub in item do if typeof(sub)=="Instance" and sub:IsA("ParticleEmitter") then sub.Enabled=false;Debris:AddItem(sub,fade and 1.5 or 0) end end
		end
	end
	st.items=nil;st.open=nil;st.orbit=nil;st.steam=nil;st.sparks=nil
end
-- (Studio 08/11) a duel restarted while awake left the old state's records on
-- the reused model: the next awakening drew nothing. A held state whose
-- instances have left the body is rebuilt.
local function alive(st)
	for _,item in st.items or {} do
		if typeof(item)=="Instance" then return item.Parent~=nil end
		if type(item)=="table" and typeof(item[1])=="Instance" then return item[1].Parent~=nil end
	end
	return st.items~=nil
end
local function fighter(fx,model,actor,dt)
	if not AwakenFX.enabled or not model or not actor then return end
	local recipe=R[actor.fighterId or ""]
	if not recipe then return end
	local st=stateOf(fx,model)
	local open=(actor.awaken or 0)>0 and (actor.health or 1)>0
	if open and not (st.open and alive(st)) then
		if st.items then clear(st,false) end
		st.open=true
		st.items=recipe.hold(model,st) or {}
		local root=model:FindFirstChild("HumanoidRootPart")
		local torso=model:FindFirstChild("UpperTorso")
		-- (Studio 08/11) at a low graphics quality Roblox thins the particles
		-- out (Automatic on a busy machine: the eight awakenings looked
		-- empty). The light is not thinned: it carries the colour there. (No
		-- Highlight: the body's ink line is one already, a second would hide it.)
		if recipe.light and torso then
			local light=Instance.new("PointLight")
			light.Name="AwakenLight";light.Color=recipe.light;light.Brightness=2;light.Range=12;light.Shadows=false;light.Parent=torso
			table.insert(st.items,light)
		end
		-- The entry plays once per awakening (not on a rebuild late in the state).
		local wakes=actor.events and actor.events.Awaken or 0
		if root and recipe.entry and st.wakes~=wakes then
			st.wakes=wakes
			pcall(function() recipe.entry(fx,model,root,floorY(fx,root)) end)
		end
		-- The shared mantle (Effects) is replaced by this layer's own.
		local aura=fx.auras and fx.auras[model]
		if aura and aura.mantle and aura.mantle.emitter then aura.mantle.emitter.Enabled=false;aura.mantle.light.Enabled=false end
	elseif not open and st.open then
		clear(st,true)
	end
	if st.open and recipe.step then recipe.step(model,actor,st,dt,fx) end
end
AwakenFX.fighter=fighter

-- (Studio 08/11) a fault here must never stop Effects' frame (every layer
-- after this one, and the next frames): it is caught, reported once, and the
-- state that failed is not rebuilt every frame.
local reported=false
local function safe(fx,model,actor,dt)
	local ok,err=pcall(fighter,fx,model,actor,dt)
	if not ok then
		if model and fx.awakenState and fx.awakenState[model] then local st=fx.awakenState[model];st.open=true;st.items=st.items or {} end
		if not reported then reported=true;warn("[AwakenFX] "..tostring(err)) end
	end
end
function AwakenFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Awaken",fighter=safe})
end
return AwakenFX
