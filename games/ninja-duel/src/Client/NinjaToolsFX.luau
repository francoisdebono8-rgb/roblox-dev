-- The ninja's tools (21/11, étape 2 ANIMATEUR 3, DEC-045): the ninja's tree (Shared/NinjaTree,
-- branch TOOLS) gives the EXPLOSIVE TAG and the SMOKE BOMB. Their look:
--
--   the explosive tag   a paper strip tied to the kunai's ring, red bands and a red seal
--                       stroke (drawn in parts: no letters), fluttering in flight. Stuck in
--                       a wall or the floor, its end catches: embers, a hiss, the paper
--                       burns back toward the kunai for the second it has, then it blows -
--                       a short fire blast, paper scraps, a ring on the ground.
--   the smoke bomb      a dark ball the size of a fist, a white paper band round it; it
--                       pops into a thick white cloud that holds its place for the time it
--                       breaks the lock (1.5 s), then thins out and drifts.
--
-- Naruto part I: the tags are paper with a red seal (Kakashi, Zabuza's bridge), the smoke
-- bombs are white (the chūnin exams). Presentation only; what the server sends:
--   a projectile p.tag = true (a kunai carrying a tag), p.kind = "smoke" (a smoke bomb);
--   an impact style "stick" with impact.tag (the tagged kunai planted: the fuse starts),
--     style "tagBlast" (it blows: position, normal, radius), style "smoke" (the cloud:
--     position, radius, time).
local AwakenFX=require(script.Parent.AwakenFX)
local emit=AwakenFX.emitter
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local Tools={}
Tools.FUSE=1.0          -- the tag's second (Shared/NinjaTree: "blows 1 s after it lands")
Tools.SMOKE_TIME=1.5    -- the cloud's hold (NinjaTree: "breaks the rival's lock for 1.5 s")
Tools.SMOKE_RADIUS=7
local PAPER=Color3.fromRGB(236,226,198)
local INK=Color3.fromRGB(176,28,30)
local SMOKE=Color3.fromRGB(232,232,236)
local BALL=Color3.fromRGB(38,36,42)

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
local function range(a,b) return NumberRange.new(a,b or a) end
local function cols(a,b) return ColorSequence.new(a,b or a) end
local function part(parent,size,cf,color,material,class)
	local p=Instance.new(class or "Part")
	p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
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
local function tween(x,time,goal,style)
	pcall(function() TweenService:Create(x,TweenInfo.new(time,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play() end)
end
local function gone(x,time) pcall(function() Debris:AddItem(x,time) end) end
local function later(time,fn) if task and task.delay then task.delay(time,fn) end end

-- ------------------------------------------------------------------ the tag
-- The paper itself, built round `cf` (its top edge, where it is tied; the strip hangs along
-- -Y of cf). Returns the model, its root (the knot) and the paper part.
function Tools.buildTag(cf,scale)
	scale=scale or 1
	local m=Instance.new("Model");m.Name="ExplosiveTag"
	local w,h,t=.3*scale,.78*scale,.03
	local knot=part(m,Vector3.new(.08,.08,.08)*scale,cf,INK);knot.Name="Knot"
	local paper=part(m,Vector3.new(w,h,t),cf*CFrame.new(0,-h/2-.04*scale,0),PAPER);paper.Name="Paper"
	-- the red frame and the seal stroke, on both faces (thin parts: no letters, no logo)
	local function ink(size,off)
		for _,z in {-1,1} do
			local p=part(m,Vector3.new(size.X,size.Y,.01),paper.CFrame*CFrame.new(off.X,off.Y,z*(t/2+.004)),INK)
			p.Name="Ink"
		end
	end
	ink(Vector3.new(w,.035*scale,0),Vector2.new(0,h/2-.05*scale))
	ink(Vector3.new(w,.035*scale,0),Vector2.new(0,-h/2+.05*scale))
	ink(Vector3.new(.05*scale,h*.62,0),Vector2.new(0,0))
	ink(Vector3.new(w*.62,.04*scale,0),Vector2.new(0,h*.14))
	ink(Vector3.new(w*.45,.04*scale,0),Vector2.new(0,-h*.12))
	for _,p in m:GetChildren() do if p~=knot and p:IsA("BasePart") then weld(knot,p) end end
	m.PrimaryPart=knot
	return m,knot,paper
end

-- A kunai in flight carries a tag on its ring (Effects' kunai: -Z is the point, the ring
-- end is +Z): it trails behind and flutters.
function Tools.tagKunai(model,root)
	local tag,knot=Tools.buildTag(root.CFrame*CFrame.new(0,0,.55)*CFrame.Angles(math.rad(-90),0,0),.9)
	pcall(function() for _,p in tag:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=root.LocalTransparencyModifier end end end)
	tag.Parent=model
	local decor={tag=tag,knot=knot,t=0}
	function decor.step(dt)
		decor.t+=dt
		if knot.Parent then
			knot.Anchored=true
			knot.CFrame=root.CFrame*CFrame.new(0,0,.55)*CFrame.Angles(math.rad(-90+8*math.sin(decor.t*38)),0,math.rad(6*math.sin(decor.t*23)))
		end
	end
	return decor
end

-- The tagged kunai is planted: the paper hangs from its ring and burns back for the fuse.
-- position/direction: the impact's (Effects:stick puts the grip `.45` back from the point).
function Tools.fuse(folder,position,direction,normal,time)
	time=time or Tools.FUSE
	local into=if direction and direction.Magnitude>.01 then direction.Unit else -(normal or Vector3.yAxis)
	local ring=position-into*.85
	local hang=Vector3.yAxis
	if math.abs(into.Y)>.8 then hang=into:Cross(Vector3.xAxis).Unit end   -- planted in the floor: lies flat
	local right=into:Cross(hang)
	local cf=CFrame.fromMatrix(ring,if right.Magnitude>.01 then right.Unit else Vector3.xAxis,hang)
	local tag,knot,paper=Tools.buildTag(cf,1)
	tag.Parent=folder
	local edge=attach(paper,"Fuse",Vector3.new(0,-paper.Size.Y/2,0))
	local flame=emit(edge,"flame",{Name="TagFuse",Rate=40,Lifetime=range(.12,.22),Speed=range(.5,1.5),SpreadAngle=Vector2.new(40,40),
		Color=cols(Color3.fromRGB(255,220,140),Color3.fromRGB(255,110,40)),LightEmission=.9,Size=seq({{0,.35},{1,.05}}),ZOffset=.3})
	local embers=emit(edge,"spark",{Name="TagEmbers",Rate=30,Lifetime=range(.25,.5),Speed=range(2,5),SpreadAngle=Vector2.new(70,70),
		Acceleration=Vector3.new(0,-6,0),Color=cols(Color3.fromRGB(255,230,160),Color3.fromRGB(255,120,40)),LightEmission=1,Size=seq({{0,.15},{1,0}})})
	flame.Enabled=true;embers.Enabled=true
	local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,140,60);light.Brightness=1.5;light.Range=6;light.Shadows=false;light.Parent=paper
	-- the paper burns back toward the knot (it shortens from its free end, charring)
	local full=paper.Size
	for _,w in paper:GetChildren() do if w:IsA("WeldConstraint") then w:Destroy() end end
	paper.Anchored=true
	local top=paper.CFrame*CFrame.new(0,full.Y/2,0)
	tween(paper,time,{Size=Vector3.new(full.X,full.Y*.18,full.Z),CFrame=top*CFrame.new(0,-full.Y*.09,0),Color=Color3.fromRGB(60,40,30)},Enum.EasingStyle.Linear)
	for _,p in tag:GetChildren() do
		if p.Name=="Ink" then tween(p,time*.8,{Transparency=1}) end
	end
	tween(light,time,{Brightness=3.5},Enum.EasingStyle.Linear)
	gone(tag,time+.15)
	return tag
end

-- It blows: a short fire blast (Effects:explosion when there is one), scraps of paper, a ring.
function Tools.blast(fx,position,normal,radius)
	radius=radius or 5
	local folder=fx.folder or fx
	if fx.explosion then pcall(fx.explosion,fx,position,normal,math.clamp(radius/7,.5,1.1)) end
	local rng=newRng()
	for _=1,10 do
		local scrap=part(folder,Vector3.new(.22,.3,.02),CFrame.new(position)*CFrame.Angles(rng:NextNumber(0,6),rng:NextNumber(0,6),0),
			if rng:NextNumber()<.3 then INK else PAPER)
		scrap.Name="TagScrap"
		local out=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(.3,1.4),rng:NextNumber(-1,1)).Unit
		tween(scrap,.9,{CFrame=scrap.CFrame*CFrame.Angles(3,2,1)+out*rng:NextNumber(3,6)+Vector3.new(0,-1,0),Transparency=1,
			Color=Color3.fromRGB(70,50,40)})
		gone(scrap,1)
	end
	local holder=part(folder,Vector3.new(.2,.2,.2),CFrame.new(position),Color3.new());holder.Transparency=1;holder.Name="TagBlast"
	local at=attach(holder,"TagBlast")
	local ring=emit(at,"ring",{Name="TagBlastRing",Lifetime=range(.35),Speed=range(.01),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection=Enum.NormalId.Top,Color=cols(Color3.fromRGB(255,200,140)),LightEmission=.5,Size=seq({{0,1},{1,radius*1.6}}),
		Transparency=seq({{0,.2},{1,1}})})
	ring.Enabled=false;pcall(function() ring:Emit(1) end)
	local smoke=emit(at,"smoke",{Name="TagBlastSmoke",Lifetime=range(.6,1),Speed=range(4,9),SpreadAngle=Vector2.new(180,180),
		Color=cols(Color3.fromRGB(90,80,76)),Size=seq({{0,1.5},{1,4}}),Transparency=seq({{0,.2},{1,1}}),Drag=4,Rotation=range(0,360)})
	smoke.Enabled=false;pcall(function() smoke:Emit(8) end)
	gone(holder,1.6)
	return holder
end

-- ------------------------------------------------------------------ the smoke bomb
function Tools.buildSmokeBomb()
	local m=Instance.new("Model");m.Name="SmokeBomb"
	local ball=part(m,Vector3.one*.5,CFrame.new(),BALL,Enum.Material.SmoothPlastic);ball.Shape=Enum.PartType.Ball;ball.Name="Root"
	local band=part(m,Vector3.new(.16,.52,.52),CFrame.Angles(0,0,math.pi/2),PAPER);band.Shape=Enum.PartType.Cylinder;band.Name="Band"
	local fuse=part(m,Vector3.new(.05,.18,.05),CFrame.new(0,.3,0),Color3.fromRGB(120,90,60));fuse.Name="Fuse"
	weld(ball,band);weld(ball,fuse)
	local at=attach(fuse,"Spark",Vector3.new(0,.09,0))
	local s=emit(at,"spark",{Name="FuseSpark",Rate=40,Lifetime=range(.1,.2),Speed=range(1,3),SpreadAngle=Vector2.new(90,90),
		Color=cols(Color3.fromRGB(255,230,160)),LightEmission=1,Size=seq({{0,.15},{1,0}})})
	s.Enabled=true
	m.PrimaryPart=ball
	return m
end

-- The cloud: thick at once, held for `time`, then it thins and drifts off.
function Tools.smoke(folder,position,radius,time)
	radius=radius or Tools.SMOKE_RADIUS
	time=time or Tools.SMOKE_TIME
	local holder=part(folder,Vector3.new(radius*1.2,radius*.5,radius*1.2),CFrame.new(position+Vector3.new(0,radius*.2,0)),SMOKE)
	holder.Transparency=1;holder.Name="SmokeCloud"
	local at=attach(holder,"Cloud")
	local pop=emit(at,"smoke",{Name="SmokePop",Lifetime=range(.5,.8),Speed=range(radius*1.2,radius*2),SpreadAngle=Vector2.new(180,180),
		Color=cols(SMOKE),Size=seq({{0,radius*.35},{.5,radius*.6},{1,radius*.7}}),Transparency=seq({{0,0},{.8,.1},{1,1}}),
		Drag=7,Rotation=range(0,360),RotSpeed=range(-30,30)})
	pop.Enabled=false;pcall(function() pop:Emit(16) end)
	local hold=emit(at,"smoke",{Name="SmokeHold",Rate=26,Lifetime=range(time*.6,time*.9),Speed=range(.5,2),SpreadAngle=Vector2.new(180,180),
		Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
		Color=cols(SMOKE,Color3.fromRGB(210,210,216)),Size=seq({{0,radius*.45},{1,radius*.65}}),Transparency=seq({{0,.05},{.7,.15},{1,1}}),
		Drag=3,Rotation=range(0,360),RotSpeed=range(-20,20),Acceleration=Vector3.new(0,.6,0)})
	hold.Enabled=true
	local ring=emit(at,"dust",{Name="SmokeRing",Lifetime=range(.5,.8),Speed=range(radius*1.5,radius*2.4),SpreadAngle=Vector2.new(180,4),
		EmissionDirection=Enum.NormalId.Top,Color=cols(SMOKE),Size=seq({{0,1.2},{1,2.8}}),Transparency=seq({{0,.3},{1,1}}),Drag=5})
	ring.Enabled=false;pcall(function() ring:Emit(12) end)
	later(time,function() if hold.Parent then hold.Enabled=false end end)
	gone(holder,time+1.2)
	return holder
end

-- ------------------------------------------------------------------ in the duel
function Tools.install(FX,kit)
	if kit and kit.BUILD and not kit.BUILD.smoke then
		kit.BUILD.smoke=function() return Tools.buildSmokeBomb() end
	end
	local layer={}
	layer.frame=function(self)
		for _,entry in self.projectiles or {} do
			local p=entry.data
			if p and p.tag and not entry.tagDecor and entry.model and entry.root then
				entry.tagDecor=Tools.tagKunai(entry.model,entry.root) or false
			end
			if entry.tagDecor then pcall(entry.tagDecor.step,1/60) end
		end
	end
	layer.impact=function(self,impact)
		local pos=impact.position
		if not pos then return nil end
		if impact.style=="stick" and impact.tag then
			Tools.fuse(self.folder,pos,impact.direction,impact.normal,impact.fuse)
			if kit and kit.sound then pcall(kit.sound,kit.anchorPart(self.folder,pos),"rbxasset://sounds/action_swim.mp3",.25,2.2) end
			return nil
		elseif impact.style=="tagBlast" then
			Tools.blast(self,pos,impact.normal,impact.radius)
			return true
		elseif impact.style=="smoke" then
			Tools.smoke(self.folder,pos,impact.radius,impact.time)
			if kit and kit.sound and kit.SOUND then pcall(kit.sound,kit.anchorPart(self.folder,pos),kit.SOUND.whoosh,.5,.6) end
			return true
		end
		return nil
	end
	table.insert(FX.layers,layer)
	return layer
end

return Tools
