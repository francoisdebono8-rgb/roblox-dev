-- The chakra natures on the weapon (21/11, étape 2 ANIMATEUR 2, DEC-045): the ninja's tree
-- (Shared/NinjaTree) gives one nature, Fire, Wind, Lightning, Earth or Water; INFUSED KUNAI
-- puts it on the kunai (in flight and at the impact), INFUSED BLADE on the 3rd hit of the
-- basic string, ELEMENT MASTERY makes it stronger and more visible. Five looks, one each:
--
--   Infusion.Fire       the kunai burns (flames along the steel, embers behind); the hit
--                       blooms into a burst of fire and embers
--   Infusion.Wind       two pale crescents spin round the kunai, a long thin wake; the hit
--                       is three cuts crossing in the air and a ring of dust
--   Infusion.Lightning  arcs crawl over the steel and redraw every few hundredths; the hit
--                       throws short bolts out and a white flash
--   Infusion.Earth      the blade is sheathed in stone shards and drags dust; the hit breaks
--                       stones off and lifts a ring of dust
--   Infusion.Water      a sleeve of water round the steel and a ribbon of drops; the hit is a
--                       splash, drops and a ripple
--
-- In the VFX bible's direction (06/11): anime, a little colour, few layers, shapes rather
-- than a flat star; the infused hit has to read at the duel camera's distance in one look,
-- and it must never be mistaken for a jutsu (it stays on the weapon and the limb, small).
--
-- What the client reads (the DEV's, Server/NinjaArts, 21/11): the projectile's `ninja` (its
-- nature), the fighter's `ninja` view (nature, blade, strong, ready) with his attackName, and
-- the impacts of style "infusion" (see InfusionFX.install). The player's chosen nature is the
-- attribute NinjaNature (Server/Progression): a preview (TreePanel, the DESIGN's) can call
-- InfusionFX.limb / InfusionFX.kunai with it.
-- Presentation only.
local AwakenFX=require(script.Parent.AwakenFX)
local emit=AwakenFX.emitter
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local InfusionFX={}
InfusionFX.NATURES={"Fire","Wind","Lightning","Earth","Water"}
InfusionFX.STRONG=1.35        -- ELEMENT MASTERY: bigger, denser
InfusionFX.BLADE_TIME=.38     -- how long the limb carries the nature for the 3rd hit
InfusionFX.clock=os.clock     -- (headless tests drive time)

local C=Color3.fromRGB
InfusionFX.LOOK={
	Fire={core=C(255,236,170),color=C(255,140,50),dark=C(150,40,12)},
	Wind={core=C(236,255,250),color=C(165,236,218),dark=C(90,150,140)},
	Lightning={core=C(242,248,255),color=C(135,182,255),dark=C(60,80,170)},
	Earth={core=C(196,176,140),color=C(132,110,84),dark=C(78,64,50)},
	Water={core=C(214,242,255),color=C(70,152,232),dark=C(24,70,140)},
}
local DROPLETS="rbxassetid://72264530299648"   -- 4x4 flipbook (the game's water drops)
local SPLASH="rbxassetid://12390096354"        -- 8x8 flipbook (the game's splash)

function InfusionFX.id(nature) return "Infusion."..tostring(nature) end
function InfusionFX.valid(nature) return InfusionFX.LOOK[nature or ""]~=nil end

-- ------------------------------------------------------------------ helpers
-- (math.random behind Random's NextNumber: the same calls, and the headless tests run it)
local Rng={}
Rng.__index=Rng
function Rng:NextNumber(a,b)
	if a==nil then return math.random() end
	return a+(b-a)*math.random()
end
local function newRng() return setmetatable({},Rng) end
local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function cols(a,b,c)
	if c then return ColorSequence.new({ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(.5,b),ColorSequenceKeypoint.new(1,c)}) end
	return ColorSequence.new(a,b or a)
end
local function range(a,b) return NumberRange.new(a,b or a) end
local function part(parent,size,cf,color,material,class)
	local p=Instance.new(class or "Part")
	p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Neon
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Parent=parent
	return p
end
local function weld(root,p)
	p.Anchored=false;p.Massless=true
	local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=p;w.Parent=p
	return p
end
local function attach(p,name,pos)
	local a=Instance.new("Attachment");a.Name=name;a.Position=pos or Vector3.zero;a.Parent=p
	return a
end
local function trail(p,a,b,color,life,width,transparency)
	local a0=attach(p,"InfusionTrail0",a);local a1=attach(p,"InfusionTrail1",b)
	local t=Instance.new("Trail")
	t.Name="InfusionTrail";t.Attachment0=a0;t.Attachment1=a1
	t.Color=color;t.Lifetime=life;t.LightEmission=.7;t.LightInfluence=0;t.FaceCamera=true
	t.WidthScale=seq({{0,1},{1,width or .2}});t.Transparency=seq({{0,transparency or .25},{1,1}})
	t.Parent=p
	return t
end
local function later(time,fn)
	if task and task.delay then task.delay(time,fn) end
end
local function fade(p,time,goal)
	pcall(function() TweenService:Create(p,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play() end)
	pcall(function() Debris:AddItem(p,time+.05) end)
end
local function anchor(parent,position)
	local p=part(parent,Vector3.new(.2,.2,.2),CFrame.new(position),Color3.new(),Enum.Material.SmoothPlastic)
	p.Transparency=1;p.Name="InfusionAnchor"
	pcall(function() Debris:AddItem(p,2.5) end)
	return p
end
local function puff(at,tex,spec,count)
	local e=emit(at,tex,spec)
	e.Enabled=false
	pcall(function() e:Emit(count) end)
	return e
end
-- A jagged arc from a to b (Lightning): a few short Neon segments thrown aside.
local function arc(parent,a,b,rng,width,color,list)
	local pts={a}
	for k=1,3 do
		local p=a:Lerp(b,k/4)
		table.insert(pts,p+Vector3.new(rng:NextNumber(-.18,.18),rng:NextNumber(-.18,.18),rng:NextNumber(-.18,.18)))
	end
	table.insert(pts,b)
	for k=1,#pts-1 do
		local p,q=pts[k],pts[k+1]
		local len=(q-p).Magnitude
		if len>.02 then
			local seg=part(parent,Vector3.new(width,width,len),CFrame.lookAt((p+q)/2,q),color)
			seg.Name="InfusionArc"
			if list then table.insert(list,seg) end
		end
	end
end

-- ------------------------------------------------------------------ the kunai
-- Decorate a flying kunai (built along -Z, point first, origin at the grip). Returns the
-- decoration {nature, parts, emitters, step(dt)}; everything hangs on the model, so it goes
-- with it (Effects:finishProjectile fades and removes the model).
function InfusionFX.kunai(model,root,nature,strong)
	local look=InfusionFX.LOOK[nature or ""]
	if not look or not root then return nil end
	local k=if strong then InfusionFX.STRONG else 1
	local decor={nature=nature,strong=strong and true or false,parts={},emitters={},spin=0}
	local name=InfusionFX.id(nature)
	local cf=root.CFrame
	local function add(p) p.Name=name;weld(root,p);table.insert(decor.parts,p);p.Parent=model;return p end
	local at=attach(root,name,Vector3.new(0,0,-.3))
	if nature=="Fire" then
		local sleeve=add(part(model,Vector3.new(1.2,.26*k,.26*k),cf*CFrame.new(0,0,-.3)*CFrame.Angles(0,math.pi/2,0),look.color))
		sleeve.Shape=Enum.PartType.Cylinder;sleeve.Transparency=.55
		table.insert(decor.emitters,emit(at,"flame",{Name=name,Rate=46*k,Lifetime=range(.16,.3),Speed=range(.5,1.6),SpreadAngle=Vector2.new(25,25),
			Color=cols(look.core,look.color,look.dark),LightEmission=.9,Size=seq({{0,.7*k},{.6,.5*k},{1,.1}}),Transparency=seq({{0,.1},{.7,.3},{1,1}}),ZOffset=.3}))
		table.insert(decor.emitters,emit(at,"spark",{Name=name,Rate=18*k,Lifetime=range(.25,.45),Speed=range(1,3),SpreadAngle=Vector2.new(60,60),
			Acceleration=Vector3.new(0,3,0),Color=cols(look.core,look.color),LightEmission=1,Size=seq({{0,.18},{1,0}})}))
		trail(root,Vector3.new(0,.12*k,.25),Vector3.new(0,-.12*k,.25),cols(look.core,look.color,look.dark),.22,.25)
	elseif nature=="Wind" then
		for i=0,1 do
			-- (anchored and placed every frame round the root, not welded: they spin)
			local blade=part(model,Vector3.new(.05,.18*k,1.1*k),cf*CFrame.Angles(0,0,i*math.pi)*CFrame.new(0,.42*k,-.25),look.core,Enum.Material.Neon,"WedgePart")
			blade.Transparency=.35;blade.Name=name
			table.insert(decor.parts,blade)
			decor["blade"..i]=blade
		end
		local ring=add(part(model,Vector3.new(.05,1.0*k,1.0*k),cf*CFrame.new(0,0,-.55)*CFrame.Angles(0,math.pi/2,0),look.core))
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.7
		trail(root,Vector3.new(0,.05,.25),Vector3.new(0,-.05,.25),cols(look.core,look.color),.4,.05,.35)
		table.insert(decor.emitters,emit(at,"spark",{Name=name,Rate=14*k,Lifetime=range(.12,.22),Speed=range(4,8),SpreadAngle=Vector2.new(12,12),
			EmissionDirection=Enum.NormalId.Back,Color=cols(look.core),LightEmission=.6,Size=seq({{0,.25},{1,0}}),Transparency=seq({{0,.3},{1,1}})}))
	elseif nature=="Lightning" then
		decor.rng=newRng()
		decor.arcs={}
		table.insert(decor.emitters,emit(at,"spark",{Name=name,Rate=40*k,Lifetime=range(.05,.12),Speed=range(3,9),SpreadAngle=Vector2.new(180,180),
			Color=cols(look.core,look.color),LightEmission=1,Size=seq({{0,.3*k},{1,0}}),Rotation=range(0,360)}))
		trail(root,Vector3.new(0,.06,.25),Vector3.new(0,-.06,.25),cols(look.core,look.color),.13,.1,.15)
		local light=Instance.new("PointLight");light.Name=name;light.Color=look.color;light.Brightness=2.5*k;light.Range=8;light.Shadows=false;light.Parent=root
		decor.light=light
	elseif nature=="Earth" then
		for i=0,2 do
			local a=i/3*math.pi*2
			local shard=add(part(model,Vector3.new(.14*k,.2*k,.75*k),cf*CFrame.Angles(0,0,a)*CFrame.new(0,.16*k,-.3)*CFrame.Angles(math.rad(8),0,0),
				look.color,Enum.Material.Slate,"WedgePart"))
			shard.Color=if i==1 then look.dark else look.color
		end
		table.insert(decor.emitters,emit(at,"dust",{Name=name,Rate=22*k,Lifetime=range(.35,.6),Speed=range(.5,1.5),SpreadAngle=Vector2.new(30,30),
			EmissionDirection=Enum.NormalId.Back,Color=cols(look.core),LightEmission=0,Size=seq({{0,.5*k},{1,1.4*k}}),Transparency=seq({{0,.35},{1,1}}),Drag=3}))
		trail(root,Vector3.new(0,.1,.25),Vector3.new(0,-.1,.25),cols(look.core,look.color),.18,.4,.45)
	elseif nature=="Water" then
		local sleeve=add(part(model,Vector3.new(1.25,.32*k,.32*k),cf*CFrame.new(0,0,-.3)*CFrame.Angles(0,math.pi/2,0),look.color,Enum.Material.Glass))
		sleeve.Shape=Enum.PartType.Cylinder;sleeve.Transparency=.45
		local drops=Instance.new("ParticleEmitter")
		drops.Name=name;drops.Texture=DROPLETS;drops.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4;drops.FlipbookMode=Enum.ParticleFlipbookMode.OneShot
		drops.Rate=26*k;drops.Lifetime=range(.3,.5);drops.Speed=range(1,3);drops.SpreadAngle=Vector2.new(50,50);drops.Acceleration=Vector3.new(0,-30,0)
		drops.Color=cols(look.core,look.color);drops.LightInfluence=0;drops.LightEmission=.3;drops.Size=seq({{0,.35*k},{1,.15}});drops.Parent=at
		table.insert(decor.emitters,drops)
		trail(root,Vector3.new(0,.1*k,.25),Vector3.new(0,-.1*k,.25),cols(look.core,look.color,look.dark),.3,.35,.3)
	end
	for _,e in decor.emitters do e.Enabled=true end
	-- (a kunai is drawn hidden until the visual clock reaches its throw: so is its nature)
	pcall(function() for _,x in decor.parts do x.LocalTransparencyModifier=root.LocalTransparencyModifier end end)
	model:SetAttribute("Infusion",nature)
	-- every frame: the wind's crescents spin, the lightning's arcs redraw
	function decor.step(dt)
		if nature=="Wind" then
			decor.spin+=dt*28
			for i=0,1 do
				local b=decor["blade"..i]
				if b and b.Parent then
					b.CFrame=root.CFrame*CFrame.Angles(0,0,decor.spin+i*math.pi)*CFrame.new(0,.42*k,-.25)
				end
			end
		elseif nature=="Lightning" then
			local now=InfusionFX.clock()
			if not decor.drawn or now-decor.drawn>.05 then
				decor.drawn=now
				for _,seg in decor.arcs do seg:Destroy() end
				table.clear(decor.arcs)
				local c=root.CFrame
				for _=1,2 do
					local a=c*CFrame.new(decor.rng:NextNumber(-.2,.2),decor.rng:NextNumber(-.2,.2),.2)
					local b=c*CFrame.new(decor.rng:NextNumber(-.35,.35)*k,decor.rng:NextNumber(-.35,.35)*k,-.9)
					arc(model,a.Position,b.Position,decor.rng,.05*k,look.core,decor.arcs)
				end
				if decor.light then decor.light.Brightness=(1.2+decor.rng:NextNumber()*2.4)*k end
			end
		end
	end
	return decor
end

-- ------------------------------------------------------------------ the impact
-- The infused hit lands (the kunai, or the 3rd hit's contact): a burst in the nature's
-- shape at `position`, oriented by `direction` (the blow's) and `normal` (the surface's).
function InfusionFX.impact(folder,position,nature,strong,direction,normal)
	local look=InfusionFX.LOOK[nature or ""]
	if not look or not position then return nil end
	local k=if strong then InfusionFX.STRONG else 1
	local name=InfusionFX.id(nature)
	local holder=anchor(folder,position)
	holder.Name=name
	local at=attach(holder,name)
	local dir=if direction and direction.Magnitude>.01 then direction.Unit else Vector3.zAxis
	if nature=="Fire" then
		puff(at,"fireBurst",{Name=name,Lifetime=range(.32,.5),Speed=range(3,7),SpreadAngle=Vector2.new(70,70),Color=cols(C(255,255,255)),
			LightEmission=.5,Size=seq({{0,1.6*k},{1,3.2*k}}),Transparency=seq({{0,0},{.8,.2},{1,1}}),Rotation=range(0,360),Drag=4},math.floor(5*k))
		puff(at,"spark",{Name=name,Lifetime=range(.3,.6),Speed=range(10,22),SpreadAngle=Vector2.new(80,80),Acceleration=Vector3.new(0,-12,0),
			Color=cols(look.core,look.color),LightEmission=1,Size=seq({{0,.35},{1,0}}),Drag=3},math.floor(14*k))
		local light=Instance.new("PointLight");light.Color=look.color;light.Brightness=4*k;light.Range=12;light.Shadows=false;light.Parent=holder
		fade(light,.4,{Brightness=0})
	elseif nature=="Wind" then
		local rng=newRng()
		for i=1,3 do
			local cf=CFrame.lookAt(position,position+dir)*CFrame.Angles(0,0,math.rad(-50+i*35+rng:NextNumber(-8,8)))*CFrame.Angles(math.rad(90),0,0)
			local cut=part(folder,Vector3.new(.06,.06,.6),cf,look.core)
			cut.Name=name;cut.Transparency=.1
			fade(cut,.2,{Size=Vector3.new(.03,.03,4.2*k),Transparency=1})
		end
		puff(at,"ring",{Name=name,Lifetime=range(.3),Speed=range(.01),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection=Enum.NormalId.Top,Color=cols(look.core),LightEmission=.4,Size=seq({{0,1},{1,4.5*k}}),Transparency=seq({{0,.3},{1,1}})},1)
		puff(at,"dust",{Name=name,Lifetime=range(.3,.5),Speed=range(6,12),SpreadAngle=Vector2.new(180,20),Color=cols(look.core),
			Size=seq({{0,.6},{1,1.6}}),Transparency=seq({{0,.45},{1,1}}),Drag=6},math.floor(8*k))
	elseif nature=="Lightning" then
		local rng=newRng()
		for _=1,math.floor(5*k) do
			local out=(dir*-.3+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.6,1),rng:NextNumber(-1,1))).Unit
			local list={}
			arc(folder,position,position+out*rng:NextNumber(1.4,2.4)*k,rng,.07*k,look.core,list)
			for _,seg in list do seg.Name=name;fade(seg,.14,{Transparency=1}) end
		end
		local ball=part(folder,Vector3.one*.6,CFrame.new(position),look.core)
		ball.Shape=Enum.PartType.Ball;ball.Name=name;ball.Transparency=.1
		fade(ball,.12,{Size=Vector3.one*2.6*k,Transparency=1})
		puff(at,"spark",{Name=name,Lifetime=range(.08,.18),Speed=range(10,24),SpreadAngle=Vector2.new(180,180),Color=cols(look.core,look.color),
			LightEmission=1,Size=seq({{0,.4},{1,0}})},math.floor(16*k))
		local light=Instance.new("PointLight");light.Color=look.color;light.Brightness=6*k;light.Range=12;light.Shadows=false;light.Parent=holder
		fade(light,.2,{Brightness=0})
	elseif nature=="Earth" then
		local rng=newRng()
		for _=1,math.floor(6*k) do
			local s=rng:NextNumber(.22,.45)*k
			local rock=part(folder,Vector3.new(s,s*.8,s*1.1),CFrame.new(position)*CFrame.Angles(rng:NextNumber(0,6),rng:NextNumber(0,6),0),
				if rng:NextNumber()<.4 then look.dark else look.color,Enum.Material.Slate)
			rock.Name=name
			local out=(-dir*.5+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(.2,1.2),rng:NextNumber(-1,1))).Unit
			pcall(function()
				TweenService:Create(rock,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
					{CFrame=rock.CFrame*CFrame.Angles(2,1,0)+out*rng:NextNumber(1.5,3)*k}):Play()
			end)
			later(.35,function() if rock.Parent then fade(rock,.25,{Transparency=1,Size=rock.Size*.4}) end end)
			pcall(function() Debris:AddItem(rock,.8) end)
		end
		puff(at,"debris",{Name=name,Lifetime=range(.4,.7),Speed=range(8,16),SpreadAngle=Vector2.new(70,70),Acceleration=Vector3.new(0,-40,0),
			Color=cols(look.color,look.dark),Size=range(.3,.55),Rotation=range(0,360),RotSpeed=range(-300,300)},math.floor(10*k))
		puff(at,"dust",{Name=name,Lifetime=range(.5,.9),Speed=range(4,9),SpreadAngle=Vector2.new(180,30),Color=cols(look.core),
			Size=seq({{0,1},{1,2.6*k}}),Transparency=seq({{0,.25},{1,1}}),Drag=5},math.floor(9*k))
	elseif nature=="Water" then
		local splash=Instance.new("ParticleEmitter")
		splash.Name=name;splash.Texture=SPLASH;splash.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid8x8;splash.FlipbookMode=Enum.ParticleFlipbookMode.OneShot
		splash.Enabled=false;splash.Lifetime=range(.35,.45);splash.Speed=range(.5,1.5);splash.Color=cols(look.core,look.color);splash.LightInfluence=0
		splash.LightEmission=.2;splash.Size=seq({{0,2*k},{1,3.2*k}});splash.Rotation=range(-20,20);splash.Parent=at
		pcall(function() splash:Emit(2) end)
		local drops=Instance.new("ParticleEmitter")
		drops.Name=name;drops.Texture=DROPLETS;drops.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4;drops.Enabled=false
		drops.Lifetime=range(.4,.7);drops.Speed=range(8,16);drops.SpreadAngle=Vector2.new(70,70);drops.Acceleration=Vector3.new(0,-45,0)
		drops.Color=cols(look.core,look.color);drops.LightInfluence=0;drops.Size=seq({{0,.45},{1,.2}});drops.Parent=at
		pcall(function() drops:Emit(math.floor(16*k)) end)
		puff(at,"ring",{Name=name,Lifetime=range(.45),Speed=range(.01),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection=Enum.NormalId.Top,Color=cols(look.core,look.color),LightEmission=.2,Size=seq({{0,.8},{1,3.6*k}}),Transparency=seq({{0,.25},{1,1}})},1)
	end
	return holder
end

-- ------------------------------------------------------------------ the limb (the 3rd hit)
-- The striking limb carries the nature for the blow: flames round the foot, a spiral of wind,
-- arcs over the shin, stone plates, a ribbon of water. Removed after `time`.
local LIMB_PARTS={RightFoot={"RightFoot","RightLowerLeg"},LeftFoot={"LeftFoot","LeftLowerLeg"},
	RightHand={"RightHand","RightLowerArm"},LeftHand={"LeftHand","LeftLowerArm"}}
InfusionFX.LIMB_PARTS=LIMB_PARTS
-- The limb each kit's 3rd hit strikes with (the étape 2 clips: a kick for the three
-- prodigies redone); any other kit: the right hand.
InfusionFX.STRIKER={Leaf="RightFoot",Lion="RightFoot",Legion="RightFoot"}
function InfusionFX.limb(model,limb,nature,strong,time)
	local look=InfusionFX.LOOK[nature or ""]
	if not look or not model then return nil end
	local k=if strong then InfusionFX.STRONG else 1
	local name=InfusionFX.id(nature)
	local made={}
	for i,pname in LIMB_PARTS[limb] or LIMB_PARTS.RightHand do
		local p=model:FindFirstChild(pname)
		if p and p:IsA("BasePart") then
			local at=attach(p,name);table.insert(made,at)
			local tip=i==1
			if nature=="Fire" then
				table.insert(made,emit(at,"flame",{Name=name,Rate=(if tip then 60 else 30)*k,Lifetime=range(.14,.26),Speed=range(1,2.5),
					SpreadAngle=Vector2.new(30,30),Color=cols(look.core,look.color,look.dark),LightEmission=.9,Size=seq({{0,.8*k},{1,.15}}),
					Transparency=seq({{0,.1},{1,1}}),ZOffset=.4}))
			elseif nature=="Lightning" then
				table.insert(made,emit(at,"spark",{Name=name,Rate=(if tip then 70 else 40)*k,Lifetime=range(.05,.1),Speed=range(4,10),
					SpreadAngle=Vector2.new(180,180),Color=cols(look.core,look.color),LightEmission=1,Size=seq({{0,.35*k},{1,0}}),Rotation=range(0,360)}))
			elseif nature=="Wind" then
				table.insert(made,emit(at,"spark",{Name=name,Rate=(if tip then 30 else 16)*k,Lifetime=range(.12,.2),Speed=range(5,9),
					SpreadAngle=Vector2.new(20,20),Color=cols(look.core),LightEmission=.5,Size=seq({{0,.3},{1,0}}),Transparency=seq({{0,.35},{1,1}})}))
				if tip then
					local ring=part(model,Vector3.new(.05,1.5*k,1.5*k),p.CFrame*CFrame.Angles(0,0,math.pi/2),look.core)
					ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.6;ring.Name=name
					weld(p,ring);table.insert(made,ring)
				end
			elseif nature=="Earth" then
				local plate=part(model,p.Size*Vector3.new(1.18,.7,1.18),p.CFrame,if tip then look.color else look.dark,Enum.Material.Slate)
				plate.Name=name;weld(p,plate);table.insert(made,plate)
				table.insert(made,emit(at,"dust",{Name=name,Rate=14*k,Lifetime=range(.3,.5),Speed=range(.5,1.5),Color=cols(look.core),
					Size=seq({{0,.5},{1,1.2}}),Transparency=seq({{0,.4},{1,1}}),Drag=3}))
			elseif nature=="Water" then
				local drops=Instance.new("ParticleEmitter")
				drops.Name=name;drops.Texture=DROPLETS;drops.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4;drops.Rate=(if tip then 40 else 20)*k
				drops.Lifetime=range(.25,.45);drops.Speed=range(1,3);drops.SpreadAngle=Vector2.new(80,80);drops.Acceleration=Vector3.new(0,-35,0)
				drops.Color=cols(look.core,look.color);drops.LightInfluence=0;drops.Size=seq({{0,.35*k},{1,.15}});drops.Parent=at
				table.insert(made,drops)
			end
			if tip then
				table.insert(made,trail(p,Vector3.new(0,p.Size.Y*.5,0),Vector3.new(0,-p.Size.Y*.5,0),cols(look.core,look.color,look.dark),
					if nature=="Wind" then .3 else .18,.3,.2))
			end
		end
	end
	model:SetAttribute("Infusion",nature)
	local function clear()
		for _,x in made do
			if x.Parent then
				if x:IsA("ParticleEmitter") or x:IsA("Trail") then x.Enabled=false end
				pcall(function() Debris:AddItem(x,.4) end)
			end
		end
		if model:GetAttribute("Infusion")==nature then model:SetAttribute("Infusion",nil) end
	end
	if time then later(time,clear) end
	return made,clear
end

-- ------------------------------------------------------------------ on the struck body
-- What the nature did to the body it reached (the server only sends the impact when the
-- effect went off): Fire burns for its 2 s (flames licking, a char tint), Lightning locks
-- him in arcs for the stun, Water leaves him dripping and dark for the slow, Earth cracks
-- the guard (stone chips off the arms).
function InfusionFX.body(model,nature,strong,time)
	local look=InfusionFX.LOOK[nature or ""]
	if not look or not model then return nil end
	local k=if strong then InfusionFX.STRONG else 1
	local name=InfusionFX.id(nature)..".Body"
	local made={}
	local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
	if not torso then return nil end
	local function on(partName,tex,spec)
		local p=model:FindFirstChild(partName)
		if not (p and p:IsA("BasePart")) then return end
		local at=attach(p,name);table.insert(made,at)
		local e=emit(at,tex,spec);e.Name=name;e.Enabled=true;table.insert(made,e)
	end
	if nature=="Fire" then
		time=time or 2
		for _,n in {"UpperTorso","LeftUpperArm","RightUpperLeg"} do
			on(n,"flame",{Rate=14*k,Lifetime=range(.25,.45),Speed=range(1,2.5),SpreadAngle=Vector2.new(25,25),Acceleration=Vector3.new(0,4,0),
				Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
				Color=cols(look.core,look.color,look.dark),LightEmission=.8,Size=seq({{0,.6*k},{1,.1}}),Transparency=seq({{0,.15},{1,1}}),ZOffset=.4})
		end
		on("Head","smoke",{Rate=5,Lifetime=range(.6,1),Speed=range(1,2),Acceleration=Vector3.new(0,3,0),Color=cols(C(70,62,58)),
			Size=seq({{0,.6},{1,1.6}}),Transparency=seq({{0,.5},{1,1}})})
	elseif nature=="Lightning" then
		time=time or .3
		for _,n in {"UpperTorso","LeftLowerArm","RightLowerArm","LeftLowerLeg","RightLowerLeg"} do
			on(n,"spark",{Rate=50*k,Lifetime=range(.04,.09),Speed=range(3,8),SpreadAngle=Vector2.new(180,180),
				Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
				Color=cols(look.core,look.color),LightEmission=1,Size=seq({{0,.35*k},{1,0}}),Rotation=range(0,360)})
		end
		local folder=model
		local rng=newRng()
		local ok,centre=pcall(function() return torso.Position end)
		if not ok then centre=Vector3.zero end
		for _=1,3 do
			local list={}
			local a0=centre+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-1.5,1.2),rng:NextNumber(-.5,.5))
			arc(folder,a0,a0+Vector3.new(rng:NextNumber(-1.2,1.2),rng:NextNumber(-1,1),rng:NextNumber(-.6,.6)),rng,.05,look.core,list)
			for _,seg in list do seg.Name=name;table.insert(made,seg);fade(seg,math.min(time,.25),{Transparency=1}) end
		end
	elseif nature=="Water" then
		time=time or 1.5
		for _,n in {"Head","UpperTorso","LeftLowerArm","RightLowerArm"} do
			local p=model:FindFirstChild(n)
			if p and p:IsA("BasePart") then
				local at=attach(p,name);table.insert(made,at)
				local drops=Instance.new("ParticleEmitter")
				drops.Name=name;drops.Texture=DROPLETS;drops.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4;drops.Rate=8*k
				drops.Lifetime=range(.35,.55);drops.Speed=range(0,.5);drops.Acceleration=Vector3.new(0,-30,0);drops.Shape=Enum.ParticleEmitterShape.Box
				drops.Color=cols(look.core,look.color);drops.LightInfluence=0;drops.Size=seq({{0,.3},{1,.15}});drops.Parent=at
				table.insert(made,drops)
			end
		end
	elseif nature=="Earth" then
		time=time or .5
		for _,n in {"LeftLowerArm","RightLowerArm"} do
			on(n,"debris",{Rate=0,Lifetime=range(.4,.6),Speed=range(4,8),SpreadAngle=Vector2.new(70,70),Acceleration=Vector3.new(0,-40,0),
				Color=cols(look.color,look.dark),Size=range(.25,.4),Rotation=range(0,360),RotSpeed=range(-200,200)})
			local e=made[#made]
			if e and e:IsA("ParticleEmitter") then e.Enabled=false;pcall(function() e:Emit(math.floor(6*k)) end) end
		end
	else
		time=time or .5
	end
	model:SetAttribute("InfusionBody",nature)
	local function clear()
		for _,x in made do
			if x.Parent then
				if x:IsA("ParticleEmitter") then x.Enabled=false end
				pcall(function() Debris:AddItem(x,.6) end)
			end
		end
		if model:GetAttribute("InfusionBody")==nature then model:SetAttribute("InfusionBody",nil) end
	end
	later(time,clear)
	return made,clear
end

-- ------------------------------------------------------------------ in the duel
-- A layer of Client/Effects (FX.layers), on the DEV's fields (Server/NinjaArts, 21/11):
--   projectile  p.ninja = the nature (a string) when the kunai is infused, p.owner
--   fighter     actor.ninja = {nature, kunai, blade, strong, tag, smoke, airJump, rise, ready},
--               actor.attackName (the 3rd hit is "Light3")
--   impact      style "infusion" {nature, how = "kunai" | "blade", strong, owner, target,
--               position}: the nature's effect went off on the target
local TIME={Fire=2,Lightning=.3,Water=1.5,Earth=.5,Wind=.3}
function InfusionFX.install(FX,kit)
	local layer={name="Infusion"}
	local function actorOf(data,id)
		for _,key in {"human","bot"} do
			local a=data and data[key]
			if a and a.id==id then return a end
		end
		return nil
	end
	layer.frame=function(self,data)
		for _,entry in self.projectiles or {} do
			local p=entry.data
			local nature=p and (if type(p.ninja)=="string" then p.ninja else p.nature)
			if nature and InfusionFX.valid(nature) and entry.infusion2==nil and entry.model and entry.root then
				local owner=actorOf(data,p.owner)
				local strong=p.strong or (owner and owner.ninja and owner.ninja.strong)
				entry.infusion2=InfusionFX.kunai(entry.model,entry.root,nature,strong) or false
			end
			if entry.infusion2 then pcall(entry.infusion2.step,1/60) end
		end
	end
	layer.impact=function(self,impact,folder)
		if impact.style~="infusion" or not InfusionFX.valid(impact.nature) then return nil end
		local where=impact.position
		local target=folder and folder:FindFirstChild(impact.target or "")
		if where then InfusionFX.impact(self.folder,where,impact.nature,impact.strong,impact.direction,impact.normal) end
		if target then InfusionFX.body(target,impact.nature,impact.strong,TIME[impact.nature]) end
		if kit and kit.sound and kit.SOUND and where then
			pcall(kit.sound,kit.anchorPart(self.folder,where),
				if impact.nature=="Lightning" then kit.SOUND.electric elseif impact.nature=="Fire" then kit.SOUND.boom else kit.SOUND.whoosh,.3,1.2)
		end
		return true
	end
	-- the 3rd hit, while it is out, when the nature is ready (its 4 s gap is over)
	layer.fighter=function(self,model,actor)
		if not model then return end
		self.infusedState=self.infusedState or setmetatable({},{__mode="k"})
		local n=actor.ninja
		local on=type(n)=="table" and n.blade and n.ready and InfusionFX.valid(n.nature) and actor.attackName=="Light3"
			and (actor.state=="Startup" or actor.state=="Active") or false
		local was=self.infusedState[model]
		if on and not was then
			InfusionFX.limb(model,InfusionFX.STRIKER[actor.fighterId] or "RightHand",n.nature,n.strong,InfusionFX.BLADE_TIME)
		end
		self.infusedState[model]=on or nil
	end
	-- first in line: another layer that takes the blow's style must not hide its nature
	table.insert(FX.layers,1,layer)
	return layer
end

return InfusionFX
