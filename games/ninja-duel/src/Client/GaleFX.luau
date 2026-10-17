-- Temari on the client (roster wave): the iron fan (closed on her back at rest,
-- a heavy club in the hand for her strikes, opened moon by moon for the wind,
-- planted beside her at the intro), the Kamaitachi scythe and Kamatari in
-- flight, the zones (Zones.luau: wind lanes stream along their direction,
-- updraft columns rise; never fire), her gusts, the whirlwind and her contacts
-- in the wind's colours. One identity layer installed into Effects (like
-- SandFX and LeeFX), plus a `frame` step that draws the snapshot's zones.
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")

local GaleFX={}
local K -- Effects' helpers, handed over by install()
GaleFX.clock=os.clock -- (headless tests drive time)
local GALE="Gale"

local WIND=Color3.fromRGB(196,255,232)
local WIND_CORE=Color3.fromRGB(242,255,250)
local WIND_DEEP=Color3.fromRGB(116,204,170)
local MOON=Color3.fromRGB(146,108,204)
local IRON=Color3.fromRGB(60,62,72)
local IRON_EDGE=Color3.fromRGB(150,152,166)
local PAPER=Color3.fromRGB(230,226,214)
local DUST=Color3.fromRGB(214,206,186)
local FIRE=Color3.fromRGB(255,150,60)

local function flatUnit(v,fallback)
	local f=Vector3.new(v.X,0,v.Z)
	return if f.Magnitude>.05 then f.Unit else (fallback or Vector3.zAxis)
end
local function ground(fx,position,fallback)
	local ok,hit=pcall(K.floorUnder,fx,position,3,12)
	return if ok and hit then hit.Position.Y else fallback
end
-- Thin streaks of air: the readable unit of every wind effect here.
local function streak(parent,from,to,color,width,time,transparency)
	local d=to-from
	if d.Magnitude<.05 then return nil end
	local s=K.block(parent,Vector3.new(width or .1,width or .1,d.Magnitude),CFrame.lookAt(from:Lerp(to,.5),to),color or WIND,Enum.Material.Neon)
	s.Name="WindStreak";s.Transparency=transparency or .3
	if time then K.tween(s,time,{Transparency=1,Size=Vector3.new(.02,.02,d.Magnitude*1.2)});Debris:AddItem(s,time+.05) end
	return s
end
-- A fan of streaks blown from `at` along `direction` (a cone of half angle `spread`).
local function gustCone(fx,name,at,direction,range,spread,count,color,time)
	local holder=K.new("Model",{Name=name},fx.folder)
	local look=flatUnit(direction)
	for k=1,count do
		local a=((k-1)/math.max(1,count-1)-.5)*2*spread+(math.random()-.5)*.08
		local dir=CFrame.fromAxisAngle(Vector3.yAxis,a):VectorToWorldSpace(look)
		local from=at+dir*(1+math.random()*2)+Vector3.new(0,(math.random()-.5)*2.4,0)
		streak(holder,from,from+dir*(range*(.55+math.random()*.45)),color or WIND,.12,time or .3,.25)
	end
	Debris:AddItem(holder,(time or .3)+.2)
	return holder
end

-- ------------------------------------------------------------------ the fan
-- Nine slats on one pivot (the grip), along -Y: folded onto one bar it is a
-- heavy iron club, spread over half a circle it is the open fan with its three
-- moons painted on the face.
local SLATS,LENGTH=9,4.4
local function buildFan()
	local model=K.new("Model",{Name="TemariFan"})
	local grip=K.block(model,Vector3.new(.3,.3,.3),CFrame.new(),IRON);grip.Name="Grip";grip.Transparency=1;grip.Anchored=false;grip.Massless=true
	model.PrimaryPart=grip
	local function hinge(part,c0)
		part.Anchored=false;part.Massless=true
		return K.new("Weld",{Name="Hinge",Part0=grip,Part1=part,C0=c0},part)
	end
	local slats={}
	for i=1,SLATS do
		local slat=K.block(model,Vector3.new(.95,LENGTH,.1),CFrame.new(),if i%2==0 then PAPER else Color3.fromRGB(238,234,224))
		slat.Name="FanSlat"
		table.insert(slats,{part=slat,weld=hinge(slat,CFrame.new(0,-LENGTH/2,0)),spread=(i-(SLATS+1)/2)/((SLATS-1)/2)})
	end
	-- Closed: the iron spine that makes it a weapon; two bands and a cap.
	local bar=K.block(model,Vector3.new(1.05,LENGTH+.1,.42),CFrame.new(),IRON,Enum.Material.Metal);bar.Name="FanBar"
	hinge(bar,CFrame.new(0,-LENGTH/2,0))
	local bands={}
	for k,y in {-.5,-LENGTH+.6} do
		local band=K.block(model,Vector3.new(1.12,.16,.5),CFrame.new(),IRON_EDGE,Enum.Material.Metal);band.Name="FanBand"
		hinge(band,CFrame.new(0,y,0));bands[k]=band
	end
	local moons={}
	for k=1,3 do
		local moon=K.block(model,Vector3.new(.04,1.05,1.05),CFrame.new(),MOON);moon.Name="FanMoon";moon.Shape=Enum.PartType.Cylinder;moon.Transparency=1
		moons[k]={part=moon,weld=hinge(moon,CFrame.new()),angle=({-46,0,46})[k]}
	end
	return {model=model,grip=grip,slats=slats,bar=bar,bands=bands,moons=moons,open=0,moonsShown=0}
end
-- Open fraction 0 (closed club) .. 1 (half circle), `moons` painted moons shown.
local function shapeFan(fan,open,moons,lit)
	fan.open=open;fan.moonsShown=moons
	for _,s in fan.slats do s.weld.C0=CFrame.Angles(0,0,math.rad(s.spread*82*open))*CFrame.new(0,-LENGTH/2,0) end
	local closed=open<.25
	fan.bar.Transparency=if closed then 0 else 1
	for _,band in fan.bands do band.Transparency=if closed then 0 else 1 end
	for k,m in fan.moons do
		m.weld.C0=CFrame.Angles(0,0,math.rad(m.angle*open))*CFrame.new(0,-LENGTH*.62,-.08)*CFrame.Angles(0,math.rad(90),0)
		-- One moon per third of the opening.
		m.part.Transparency=if k<=moons and open>=k/3-.02 then 0 else 1
		m.part.Material=if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end
-- Where it sits: on the back (grip over the right shoulder, across to the left
-- hip), in the right hand (closed along the forearm, open with its face to the
-- swing), planted beside her (the intro).
local MOUNT={
	back={"UpperTorso",CFrame.new(.72,1.25,.72)*CFrame.Angles(0,0,math.rad(-30))},
	hand={"RightHand",CFrame.new(0,-.22,0)},
	open={"RightHand",CFrame.new(0,-.22,0)*CFrame.Angles(0,math.rad(90),0)},
	planted={"HumanoidRootPart",CFrame.new(2.4,-2.9,.2)*CFrame.Angles(0,math.rad(70),math.pi)},
}
GaleFX.MOUNT=MOUNT
local CAST_MOONS={Kamaitachi=1,Cyclone=2,GreatGust=3}
local CHANNEL={Kamaitachi=.3,Cyclone=.24,GreatGust=.5}
-- The fan opens for the strikes that blow (the third, the pirouette, the dive, the scoop).
local OPEN_STRIKE={Light3=1,FanPirouette=1,FanDive=1,Updraft=.6}
local SWINGING={Startup=true,Active=true,Recovery=true}
local CASTING={TechniqueChannel=true,TechniqueActive=true,TechniqueRecovery=true}
-- Mount, open fraction and moons for this frame, from the snapshot alone.
function GaleFX.fanPose(actor)
	if (actor.health or 1)<=0 then return "back",0,0 end
	if (actor.intro or 0)>0 and actor.state=="Neutral" then return "planted",1,3 end
	local awake=(actor.awaken or 0)>0
	local cast=actor.castId
	if cast and CAST_MOONS[cast] and CASTING[actor.state] then
		local open=if actor.state=="TechniqueChannel" then math.clamp((actor.castElapsed or 0)/CHANNEL[cast],.15,1) else 1
		local moons=math.max(1,math.ceil(CAST_MOONS[cast]*open-.01))
		return "open",open,if awake then 3 else moons
	end
	if actor.throwKind=="Gust" and (actor.throwElapsed or 99)>=0 and (actor.throwElapsed or 99)<.45 then return "open",1,if awake then 3 else 1 end
	local name=actor.attackName
	-- (late in a recovery the arm is back on the hip: the fan is put away)
	if name and SWINGING[actor.state] and not (actor.state=="Recovery" and (actor.attackElapsed or 0)>.45) then
		local open=OPEN_STRIKE[name] or 0
		return if open>0 then "open" else "hand",open,if open>0 then 1 else 0
	end
	if actor.glide then return "open",1,0 end
	return "back",0,if awake then 3 else 0
end
local function fanFor(fx,model)
	fx.galeFans=fx.galeFans or setmetatable({},{__mode="k"})
	local fan=fx.galeFans[model]
	if fan and fan.model.Parent==model then return fan end
	fan=buildFan()
	fan.model.Parent=model
	fan.carry=K.new("Weld",{Name="FanCarry",Part1=fan.grip},fan.grip)
	fx.galeFans[model]=fan
	return fan
end
local function holdFan(fx,model,actor)
	local fan=fanFor(fx,model)
	local mount,open,moons=GaleFX.fanPose(actor)
	local spec=MOUNT[mount]
	local part=model:FindFirstChild(spec[1]) or model:FindFirstChild("HumanoidRootPart")
	if part and (fan.carry.Part0~=part or fan.mount~=mount) then
		fan.carry.Part0=part;fan.carry.C0=spec[2]
		-- Drawn or put away: a small gust where the fan moves.
		if fan.mount and (mount=="back")~=(fan.mount=="back") then
			local at=(part.CFrame*spec[2]).Position
			K.shockRing(fx.folder,at,WIND,.4,3.2,.18)
		end
		fan.mount=mount
	end
	if math.abs(fan.open-open)>.01 or fan.moonsShown~=moons or fan.lit~=((actor.awaken or 0)>0) then
		fan.lit=(actor.awaken or 0)>0
		shapeFan(fan,open,moons,fan.lit)
	end
	return fan
end

-- ------------------------------------------------------------------ flights
-- Kamaitachi: a wide crescent of cutting air, as big as the server's swept
-- radius at every moment (it grows as it flies), streaming a pale trail.
local ARC=9
local function buildScythe(name,color)
	return function()
		local model=K.new("Model",{Name=name})
		local root=K.block(model,Vector3.new(.1,.1,.1),CFrame.new(),Color3.new());root.Name="Root";root.Transparency=1
		for k=1,ARC do
			local seg=K.block(model,Vector3.new(1,.08,.4),CFrame.new(),color or WIND,Enum.Material.Neon)
			seg.Name="ScytheArc";seg.Transparency=.25+math.abs(k-(ARC+1)/2)*.07
		end
		local a0=K.new("Attachment",{Position=Vector3.new(-2.6,0,0)},root)
		local a1=K.new("Attachment",{Position=Vector3.new(2.6,0,0)},root)
		K.new("Trail",{Attachment0=a0,Attachment1=a1,Color=ColorSequence.new(color or WIND),LightEmission=.6,Transparency=K.num({{0,.5},{1,1}}),
			Lifetime=.22,FaceCamera=true},root)
		model.PrimaryPart=root
		return model
	end
end
local function scythePose(_,entry,p,age,look,dt)
	local radius=(p.radius or 2)+(p.growth or 0)*math.max(0,age)
	entry.spin=(entry.spin or 0)+dt*2
	local i=0
	for _,seg in entry.model:GetChildren() do
		if seg.Name=="ScytheArc" then
			i+=1
			local a=math.rad(-62+(i-1)*124/(ARC-1))
			local tilt=math.sin(entry.spin+i)*.06
			seg.Size=Vector3.new(radius*.48,.08+radius*.02,.42)
			seg.CFrame=look*CFrame.Angles(0,a,tilt)*CFrame.new(0,0,-radius*.85)
		end
	end
	return look
end
-- Kamatari: the one-eyed weasel riding a giant crescent, its sickle out.
local function buildKamatari()
	local model=buildScythe("Kamatari",WIND_CORE)()
	local root=model.PrimaryPart
	local fur=Color3.fromRGB(240,236,226)
	local parts={}
	local body=K.block(model,Vector3.new(1.1,1,2.2),CFrame.new(0,.9,.4),fur);body.Shape=Enum.PartType.Ball;body.Name="KamatariBody";table.insert(parts,body)
	local head=K.block(model,Vector3.new(.9,.85,.9),CFrame.new(0,1.5,-.7),fur);head.Shape=Enum.PartType.Ball;head.Name="KamatariHead";table.insert(parts,head)
	for _,x in {-.3,.3} do table.insert(parts,K.block(model,Vector3.new(.2,.3,.12),CFrame.new(x,1.95,-.75),fur)) end
	table.insert(parts,K.block(model,Vector3.new(.24,.06,.04),CFrame.new(-.18,1.58,-1.14),Color3.fromRGB(30,26,30))) -- the scarred eye
	local tail=K.block(model,Vector3.new(.35,.35,1.6),CFrame.new(0,1.1,1.8)*CFrame.Angles(math.rad(-25),0,0),fur);tail.Name="KamatariTail";table.insert(parts,tail)
	local blade=K.block(model,Vector3.new(.08,.5,2.6),CFrame.new(.9,1.3,-.6)*CFrame.Angles(0,math.rad(20),math.rad(-30)),IRON_EDGE,Enum.Material.Metal)
	blade.Name="KamatariSickle";table.insert(parts,blade)
	K.weldAll(root,parts)
	return model
end

-- ------------------------------------------------------------------ zones
-- A lane: a faint band on the floor and streaks of air running along it,
-- downwind, at body height (the kind of zone is read at a glance: no flame).
local LANE_STREAKS=12
local function laneVisual(fx,z)
	local holder=K.new("Model",{Name="WindLane"},fx.folder)
	local y=ground(fx,z.origin+Vector3.new(0,1,0),z.origin.Y)
	local band=K.block(holder,Vector3.new(1,.06,1),CFrame.new(),if z.reflect then MOON else WIND_DEEP);band.Name="WindBand";band.Transparency=.84
	local streaks={}
	for k=1,LANE_STREAKS do
		local s=K.block(holder,Vector3.new(.09,.09,2.6),CFrame.new(),if z.reflect and k%3==0 then MOON else WIND,Enum.Material.Neon)
		s.Name="WindStreak";s.Transparency=.4
		table.insert(streaks,{part=s,phase=math.random(),across=(math.random()*2-1),height=.5+math.random()*4,speed=.75+math.random()*.5})
	end
	Debris:AddItem(holder,(z.remaining or 4)+1)
	return {holder=holder,band=band,streaks=streaks,floor=y,shown=0}
end
local function laneStep(fx,v,z,dt)
	-- The lane grows with the scythe that lays it: ease toward the reported length.
	v.shown=v.shown+(z.length-v.shown)*math.min(1,dt*18)
	local length=math.max(.5,v.shown)
	local dir=flatUnit(z.direction)
	local across=dir:Cross(Vector3.yAxis)
	local base=Vector3.new(z.origin.X,v.floor,z.origin.Z)
	local fade=math.clamp((z.remaining or 1)/.5,0,1)
	v.band.Size=Vector3.new(z.width*2,.06,length)
	v.band.CFrame=CFrame.lookAt(base+dir*length/2+Vector3.new(0,.04,0),base+dir*length/2+Vector3.new(0,.04,0)+dir)
	v.band.Transparency=1-(.16*fade)
	local t=GaleFX.clock()
	for _,s in v.streaks do
		local along=((t*s.speed*1.4+s.phase)%1)*length
		local at=base+dir*along+across*s.across*z.width*.9+Vector3.new(0,s.height,0)
		s.part.CFrame=CFrame.lookAt(at,at+dir)
		-- Bright mid-lane, fading at both ends and as the lane dies.
		local edge=math.min(along,length-along)/math.max(1,length*.2)
		s.part.Transparency=1-(.6*math.clamp(edge,0,1)*fade)
	end
end
-- A column of rising air: rings climbing and turning, streaks spiralling up.
local function columnVisual(fx,z)
	local holder=K.new("Model",{Name="Updraft"},fx.folder)
	local y=ground(fx,z.origin+Vector3.new(0,1,0),z.origin.Y)
	local rings={}
	for k=1,3 do
		local r=K.block(holder,Vector3.new(.08,z.radius*2,z.radius*2),CFrame.new(),WIND,Enum.Material.Neon);r.Name="UpdraftRing";r.Shape=Enum.PartType.Cylinder;r.Transparency=.6
		table.insert(rings,{part=r,phase=k/3})
	end
	local spirals={}
	for k=1,6 do
		local s=K.block(holder,Vector3.new(.1,1.8,.1),CFrame.new(),WIND_CORE,Enum.Material.Neon);s.Name="WindStreak";s.Transparency=.4
		table.insert(spirals,{part=s,phase=k/6})
	end
	K.smokePuff(fx.folder,Vector3.new(z.origin.X,y+.6,z.origin.Z),DUST,14,1.8)
	Debris:AddItem(holder,(z.remaining or 2)+1)
	return {holder=holder,rings=rings,spirals=spirals,floor=y}
end
local function columnStep(fx,v,z,dt)
	local t=GaleFX.clock()
	local base=Vector3.new(z.origin.X,v.floor,z.origin.Z)
	local fade=math.clamp((z.remaining or 1)/.4,0,1)
	local h=math.min(z.height or 16,16)
	for _,r in v.rings do
		local u=(t*.8+r.phase)%1
		r.part.Size=Vector3.new(.08,z.radius*2*(1-u*.3),z.radius*2*(1-u*.3))
		r.part.CFrame=CFrame.new(base+Vector3.new(0,.2+u*h,0))*CFrame.Angles(0,t*3,math.pi/2)
		r.part.Transparency=1-(.4*(1-u)*fade)
	end
	for _,s in v.spirals do
		local u=(t*.9+s.phase)%1
		local a=s.phase*math.pi*2+t*5
		local at=base+Vector3.new(math.cos(a)*z.radius*.8,.5+u*h,math.sin(a)*z.radius*.8)
		s.part.CFrame=CFrame.new(at)*CFrame.Angles(0,-a,math.rad(18))
		s.part.Transparency=1-(.55*(1-u)*fade)
	end
end
local function frame(fx,data,dt)
	local st=fx.galeZones
	if not st or st.epoch~=data.epoch then
		if st then for _,v in st.list do v.holder:Destroy() end end
		st={epoch=data.epoch,list={}};fx.galeZones=st
	end
	local live={}
	for _,z in data.zones or {} do
		live[z.id]=true
		local v=st.list[z.id]
		if not v then
			v=if z.kind=="Updraft" then columnVisual(fx,z) else laneVisual(fx,z)
			v.kind=z.kind;st.list[z.id]=v
		end
		if z.kind=="Updraft" then columnStep(fx,v,z,dt) else laneStep(fx,v,z,dt) end
	end
	for id,v in st.list do
		if not live[id] then
			for _,d in v.holder:GetDescendants() do if d:IsA("BasePart") then K.tween(d,.25,{Transparency=1}) end end
			Debris:AddItem(v.holder,.3)
			st.list[id]=nil
		end
	end
end

-- ------------------------------------------------------------------ contacts
local function windBurst(fx,at,direction,size,color)
	local holder=K.new("Model",{Name="WindBurst"},fx.folder)
	local look=flatUnit(direction or Vector3.zAxis)
	for k=1,7 do
		local a=math.rad(-70+(k-1)*140/6)
		local dir=CFrame.fromAxisAngle(Vector3.yAxis,a):VectorToWorldSpace(look)
		streak(holder,at+dir*.6,at+dir*(size*(1+math.random()*.5)),color or WIND,.12,.22,.2)
	end
	K.shockRing(holder,at,color or WIND,.6,size*2.4,.24,look)
	Debris:AddItem(holder,.4)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.4,.8+math.random()*.2)
end
local function impact(fx,data,folder)
	local style=data.style
	local at=data.position
	if data.kind=="gale" or data.kind=="kamatari" then
		-- The scythe (or Kamatari) ends: on a body, on a wall, on a guard, or in the air.
		local big=data.kind=="kamatari"
		local size=if style=="fade" then 1.4 elseif style=="spent" then 2 else 3
		windBurst(fx,at,data.direction,size*(if big then 1.6 else 1),if big then WIND_CORE else WIND)
		if style~="fade" then K.smokePuff(fx.folder,at,DUST,if big then 16 else 8,if big then 2.2 else 1.4) end
		if style~="fade" and style~="spent" then fx:cheer(if big then 1 else .5) end
		return true
	end
	if style=="gust" then
		local reach=data.range or 18
		gustCone(fx,"FanGust",at,data.direction or Vector3.zAxis,reach,math.rad(34),if data.heavy then 14 else 9,if data.infusion then WIND_CORE else WIND,.32)
		K.smokePuff(fx.folder,at-Vector3.new(0,2.2,0)+flatUnit(data.direction or Vector3.zAxis)*3,DUST,8,1.3)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.45,.7)
		return true
	elseif style=="greatgust" then
		local look=flatUnit(data.direction or Vector3.zAxis)
		gustCone(fx,"GreatGust",at,look,data.range or 30,math.rad(42),22,WIND,.45)
		K.shockRing(fx.folder,at-Vector3.new(0,2.4,0),WIND,3,(data.range or 30)*.9,.45)
		K.smokePuff(fx.folder,at-Vector3.new(0,2.2,0)+look*6,DUST,24,2.6)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.4,1.4)
		fx:cheer(.8)
		return true
	elseif style=="cyclone" then
		local radius=data.radius or 3.4
		if data.phase=="mark" then
			-- The spot is marked a beat before it rises: a swirl on the floor.
			local y=ground(fx,at,at.Y-.3)
			local holder=K.new("Model",{Name="CycloneMark"},fx.folder)
			local disc=K.block(holder,Vector3.new(.05,radius*2,radius*2),CFrame.new(at.X,y+.05,at.Z)*CFrame.Angles(0,0,math.pi/2),WIND_DEEP);disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.6
			for k=0,5 do
				local a=k/6*math.pi*2
				streak(holder,Vector3.new(at.X+math.cos(a)*radius,y+.1,at.Z+math.sin(a)*radius),Vector3.new(at.X+math.cos(a+1)*radius*.4,y+.1,at.Z+math.sin(a+1)*radius*.4),WIND,.1,data.delay or .45,.3)
			end
			K.tween(disc,data.delay or .45,{Transparency=.3})
			Debris:AddItem(holder,(data.delay or .45)+.1)
		else
			-- It rises (or holds the scooped body): a burst of air straight up.
			local holder=K.new("Model",{Name="CycloneRise"},fx.folder)
			for k=0,7 do
				local a=k/8*math.pi*2
				local from=at+Vector3.new(math.cos(a)*radius*.7,.2,math.sin(a)*radius*.7)
				streak(holder,from,from+Vector3.new(math.cos(a+.6),8,math.sin(a+.6)),WIND,.14,.4,.2)
			end
			K.shockRing(holder,at,WIND,1,radius*3,.3)
			Debris:AddItem(holder,.5)
			K.smokePuff(fx.folder,at,DUST,if data.phase=="rise" then 16 else 6,1.6)
			K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.5,.6)
		end
		return true
	elseif style=="windfeed" then
		-- Fire crossing her wind flares up.
		K.flash(fx.folder,at,FIRE,1,5,.25,.2)
		K.shockRing(fx.folder,at,WIND,.8,5,.25,data.direction)
		return true
	elseif style=="winddeflect" then
		-- A blade turned aside by a lane: a swirl, the blade tumbles out of it.
		K.shockRing(fx.folder,at,WIND,.5,3.6,.2,data.direction)
		pcall(fx.tumble,fx,data.kind,at,data.direction,WIND)
		return true
	end
	if data.fighter~=GALE then return false end
	if style=="awaken" then
		-- Kirikiri Mai: the fan fully open, the moons lit, the wind around her.
		local model=folder and folder:FindFirstChild(data.owner or "")
		if model then fx:ghost(model,WIND,.4,.4) end
		K.flash(fx.folder,at,WIND_CORE,2,12,.3,.15)
		K.shockRing(fx.folder,at-Vector3.new(0,2.6,0),MOON,3,22,.45)
		K.shockRing(fx.folder,at-Vector3.new(0,2.4,0),WIND,3,28,.55)
		gustCone(fx,"KirikiriMai",at,Vector3.xAxis,14,math.pi,16,WIND,.5)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.45,1.2)
		fx:cheer(1)
		return true
	elseif style=="chase" then
		-- Her wind step (or a chase): a pale copy left behind, streaks along the way.
		local model=folder and folder:FindFirstChild(data.owner or "")
		if model then fx:ghost(model,WIND,.25,.55) end
		if data.to then
			for k=1,4 do
				local off=Vector3.new((math.random()-.5)*1.6,(math.random()-.2)*2,(math.random()-.5)*1.6)
				streak(fx.folder,at+off,data.to+off,WIND,.1,.25,.35)
			end
		end
		K.smokePuff(fx.folder,at-Vector3.new(0,2.6,0),DUST,6,1.2)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.35,1.05)
		return true
	elseif style=="afterimage" then
		local model=folder and folder:FindFirstChild(data.owner or "")
		if model then fx:ghost(model,WIND,.3,.5) end
		return true
	elseif style=="cast" then
		-- The fan opens: air gathers round the hand.
		local model=folder and folder:FindFirstChild(data.owner or "")
		local hand=model and model:FindFirstChild("RightHand")
		local where=if hand then hand.Position else at
		K.shockRing(fx.folder,where,WIND,.4,4,.25)
		return true
	end
	return false
end

-- ------------------------------------------------------------------ per frame
local function fighter(fx,model,actor,_dt)
	if not model or not actor or actor.fighterId~=GALE then return end
	holdFan(fx,model,actor)
	-- Her awakening mantle and speed trail take the wind's colour.
	local aura=fx.auras and fx.auras[model]
	if aura and aura.mantle and aura.galeMantle~=aura.mantle then
		aura.mantle.emitter.Color=ColorSequence.new(WIND)
		aura.mantle.light.Color=WIND
		aura.galeMantle=aura.mantle
	end
	if aura and aura.trail and not aura.galeTrail then aura.trail.Color=ColorSequence.new(WIND);aura.galeTrail=true end
end

function GaleFX.install(FX,kit)
	K=kit
	kit.BUILD.gale=buildScythe("Kamaitachi",WIND)
	kit.BUILD.kamatari=buildKamatari
	FX.poses.gale=scythePose
	FX.poses.kamatari=scythePose
	table.insert(FX.layers,{name="Gale",impact=impact,fighter=fighter,frame=frame})
end
return GaleFX
