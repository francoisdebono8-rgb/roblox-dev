-- Gaara's sand on the client: the sand bullet and Sand Shuriken in flight, the
-- Sand Coffin wave and the body it holds, the automatic shield and its charges,
-- the body-flicker, the burial, the Desert Wave, and the lashes and pillar of
-- his strings. One identity layer installed into Effects (DEC-015: a fighter's
-- look lives in its own module, Effects only offers the registry and helpers).
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)

local SandFX={}
local K -- Effects' helpers, handed over by install()
SandFX.clock=os.clock -- (headless tests drive time)

local SAND=Color3.fromRGB(212,176,118)
local SAND_DARK=Color3.fromRGB(164,126,78)
local SAND_PALE=Color3.fromRGB(238,218,176)
local SHUKAKU=Color3.fromRGB(222,176,112)
local GRAIN=Enum.Material.Sand

local function smooth(x) x=math.clamp(x,0,1) return x*x*(3-2*x) end
local function flatUnit(v,fallback)
	local f=Vector3.new(v.X,0,v.Z)
	return if f.Magnitude>.05 then f.Unit else (fallback or Vector3.zAxis)
end
local function ground(fx,position,fallback)
	local ok,hit=pcall(K.floorUnder,fx,position,3,12)
	return if ok and hit then hit.Position.Y else fallback
end
-- Grains thrown out and falling back: what makes it read as sand, not smoke.
local function grains(fx,position,count,speed,up)
	K.burst(fx.folder,position,{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.35,.7),Speed=NumberRange.new(speed*.5,speed),
		SpreadAngle=if up then Vector2.new(40,40) else Vector2.new(180,180),EmissionDirection=Enum.NormalId.Top,
		Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,.4},{1,.15}}),
		Transparency=K.num({{0,.05},{.7,.25},{1,1}}),Acceleration=Vector3.new(0,-60,0),Drag=1.5,Rotation=NumberRange.new(0,360)},count)
end
local function dust(fx,position,count,size) K.smokePuff(fx.folder,position,SAND_PALE,count,size) end
local function thud(fx,position,volume,speed) K.sound(K.anchorPart(fx.folder,position),K.SOUND.land,volume,speed) end
-- A flat ring of sand spreading over the floor.
local function sandRing(fx,position,from,to,time)
	local y=ground(fx,position,position.Y-2.6)
	local disc=K.block(fx.folder,Vector3.new(.08,from,from),CFrame.new(position.X,y+.05,position.Z)*CFrame.Angles(0,0,math.pi/2),SAND,GRAIN)
	disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.2
	K.tween(disc,time,{Size=Vector3.new(.04,to,to),Transparency=1})
	Debris:AddItem(disc,time+.05)
end
-- A rounded column of sand standing on `frame` (its foot): a cylinder with a
-- ball for a crown, so walls and pillars read as poured sand, not planks.
local function column(parent,height,radius,color)
	local body=K.block(parent,Vector3.new(height,radius*2,radius*2),CFrame.new(),color or SAND,GRAIN);body.Shape=Enum.PartType.Cylinder
	local cap=K.block(parent,Vector3.one*radius*2.1,CFrame.new(),color or SAND,GRAIN);cap.Shape=Enum.PartType.Ball
	return {body=body,cap=cap,height=height,radius=radius}
end
local function columnAt(c,frame)
	return frame*CFrame.new(0,c.height/2,0)*CFrame.Angles(0,0,math.pi/2),frame*CFrame.new(0,c.height-c.radius*.5,0)
end
local function placeColumn(c,frame)
	local body,cap=columnAt(c,frame);c.body.CFrame=body;c.cap.CFrame=cap
end
-- `fade`: also fade it out over the move.
local function moveColumn(c,frame,time,fade,style,direction)
	local body,cap=columnAt(c,frame)
	K.tween(c.body,time,{CFrame=body,Transparency=if fade then 1 else c.body.Transparency},style,direction)
	K.tween(c.cap,time,{CFrame=cap,Transparency=if fade then 1 else c.cap.Transparency},style,direction)
end
-- The body he leaves is sand: a copy of the pose that slumps and pours down.
local function sandBody(fx,model,at)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	-- The impact may arrive after the body already reappeared elsewhere.
	local shift=at-root.Position
	if shift.Magnitude<1.5 then shift=Vector3.zero end
	local holder=K.new("Model",{Name="SandBody"},fx.folder)
	local floorY=ground(fx,at,at.Y-3)
	for _,d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" and d.Transparency<.9 then
			local cf=d.CFrame+shift
			local copy=K.block(holder,d.Size,cf,SAND,GRAIN,if d:IsA("WedgePart") then "WedgePart" else "Part")
			if d:IsA("Part") then copy.Shape=d.Shape end
			local drop=math.max(0,cf.Position.Y-floorY-.3)
			K.tween(copy,.45,{CFrame=cf-Vector3.new(0,drop*.85,0),Size=d.Size*Vector3.new(1.3,.3,1.3),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
		end
	end
	grains(fx,at,20,8,true)
	Debris:AddItem(holder,.6)
end

-- ------------------------------------------------------------------ flights
-- Sand bullet / Sand Shuriken: a hardened clump tumbling, shedding dust.
local function buildBullet()
	local model=K.new("Model",{Name="SandBullet"})
	local root=K.block(model,Vector3.one*.95,CFrame.new(),SAND,GRAIN);root.Name="Root";root.Shape=Enum.PartType.Ball
	local tail=K.block(model,Vector3.one*.62,CFrame.new(0,.12,.38),SAND_DARK,GRAIN);tail.Name="Tail";tail.Shape=Enum.PartType.Ball
	K.weldAll(root,{tail})
	local at=K.new("Attachment",{},root)
	K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=60,Lifetime=NumberRange.new(.25,.45),Speed=NumberRange.new(0,1.5),SpreadAngle=Vector2.new(25,25),
		Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,.7},{1,1.6}}),Transparency=K.num({{0,.35},{1,1}}),
		Drag=3,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)},at)
	model.PrimaryPart=root
	return model
end
local function bulletPose(_,entry,_,_,look,dt)
	entry.spin+=dt*9
	return look*CFrame.Angles(entry.spin,entry.spin*.6,0)
end
-- Sand Coffin: a low wave of sand running along the floor, crest first, that
-- grows as it travels and leaves a disturbed lane behind it.
local WAVE={{"Crest",.85,-.5,.75},{"Body",1,.5,.55},{"Tail",.8,1.6,.35}}
local function buildWave()
	local model=K.new("Model",{Name="SandWave"})
	local root=K.block(model,Vector3.new(.2,.2,.2),CFrame.new(),SAND,GRAIN);root.Name="Root";root.Transparency=1
	for i,spec in WAVE do
		local part=K.block(model,Vector3.one*2,CFrame.new(0,0,spec[3]),if i==1 then SAND_PALE else SAND,GRAIN)
		part.Name=spec[1];part.Shape=Enum.PartType.Ball
	end
	local at=K.new("Attachment",{Name="Spray"},root)
	K.new("ParticleEmitter",{Name="Spray",Texture=K.TEX.smoke,Rate=70,Lifetime=NumberRange.new(.35,.7),Speed=NumberRange.new(3,7),SpreadAngle=Vector2.new(55,55),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.2},{1,3}}),
		Transparency=K.num({{0,.3},{1,1}}),Drag=3,Acceleration=Vector3.new(0,-6,0),Rotation=NumberRange.new(0,360)},at)
	model.PrimaryPart=root
	return model
end
local function wavePose(fx,entry,p,age,look,dt)
	local radius=((p.radius or 1.8)+(p.growth or 0)*math.max(0,age))*1.2
	local pos=look.Position
	entry.groundIn=(entry.groundIn or 0)-dt
	if entry.groundIn<=0 then entry.groundIn=.1;entry.ground=ground(fx,pos,entry.ground or pos.Y-1.6) end
	local y=entry.ground or pos.Y-1.6
	local at=Vector3.new(pos.X,y,pos.Z)
	local base=CFrame.lookAt(at,at+flatUnit(p.direction))
	local wobble=1+math.sin(os.clock()*14)*.08
	for _,spec in WAVE do
		local part=entry.model:FindFirstChild(spec[1])
		if part then
			local r=radius*spec[2]*wobble
			-- A sphere sunk into the floor shows a dome spec[4]*r tall.
			part.Size=Vector3.one*r*2
			part.CFrame=base*CFrame.new(0,r*(spec[4]-1),spec[3]*radius)
		end
	end
	if not entry.hidden and (not entry.markAt or (at-entry.markAt).Magnitude>1.6) then
		entry.markAt=at
		local size=radius*(.75+math.random()*.45)
		local mark=K.block(fx.folder,Vector3.new(.05,size,size*(.65+math.random()*.4)),CFrame.new(at+Vector3.new(0,.03,0))*CFrame.Angles(0,math.random()*math.pi,math.pi/2),SAND_DARK,GRAIN)
		mark.Shape=Enum.PartType.Cylinder;mark.Transparency=.45
		task.delay(.6,function() if mark.Parent then K.tween(mark,.6,{Transparency=1}) end end)
		Debris:AddItem(mark,1.3)
	end
	return base
end

-- ------------------------------------------------------------------ contacts
local STYLES={}
STYLES.sandhit=function(fx,impact)
	dust(fx,impact.position,8,1.3)
	grains(fx,impact.position,12,14,false)
	thud(fx,impact.position,.3,1.4)
end
STYLES.sandburst=function(fx,impact)
	dust(fx,impact.position,18,2.4)
	grains(fx,impact.position,26,22,true)
	sandRing(fx,impact.position,2,12,.45)
	thud(fx,impact.position,.45,.8)
end
-- The shield: a curved wall of sand columns snaps up between him and the
-- blow, then pours back down; a breaking blow bursts it apart.
STYLES.sandshield=function(fx,impact)
	local at=impact.position
	local face=flatUnit(impact.direction or Vector3.zAxis)
	local breaking=impact.heavy==true
	local centre=at-face*1.6
	local y=ground(fx,centre,centre.Y-3)
	local holder=K.new("Model",{Name="SandShield"},fx.folder)
	local cols={}
	for k=-3,3 do
		local dir=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(k*17)):VectorToWorldSpace(face)
		local spot=Vector3.new(centre.X,y,centre.Z)+dir*2
		local frame=CFrame.lookAt(spot,spot+dir)*CFrame.Angles(math.rad((math.random()-.5)*10),0,math.rad((math.random()-.5)*10))
		local c=column(holder,5.3-math.abs(k)*.5+math.random()*.5,if k==0 then .9 else .8,if k%2==0 then SAND else SAND_PALE)
		placeColumn(c,frame*CFrame.new(0,-c.height,0))
		moveColumn(c,frame,.07)
		c.frame=frame;c.dir=dir
		table.insert(cols,c)
	end
	dust(fx,at,if breaking then 22 else 10,if breaking then 2.4 else 1.6)
	grains(fx,at,if breaking then 30 else 14,if breaking then 26 else 14,false)
	thud(fx,at,if breaking then .7 else .45,if breaking then .55 else .9)
	if breaking then
		fx:cheer(.6)
		task.delay(.06,function()
			for _,c in cols do
				local fly=c.dir*(3+math.random()*3)+Vector3.new((math.random()-.5)*2,1.5+math.random()*2,(math.random()-.5)*2)
				moveColumn(c,(c.frame+fly)*CFrame.Angles(math.random()*1.5,0,math.random()*1.5),.4,true)
			end
		end)
		Debris:AddItem(holder,.55)
	else
		task.delay(.24,function()
			for _,c in cols do moveColumn(c,c.frame*CFrame.new(0,-c.height*.6,0),.35,true,Enum.EasingStyle.Quad,Enum.EasingDirection.In) end
		end)
		Debris:AddItem(holder,.7)
	end
end
-- Sand body-flicker: the body pours to the floor where he stood and the sand
-- gathers into him where he reappears.
STYLES.sandflicker=function(fx,impact,folder)
	local from=impact.position
	local to=impact.to or from
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then sandBody(fx,model,from) end
	dust(fx,to-Vector3.new(0,2.4,0),10,1.5)
	local column=K.block(fx.folder,Vector3.new(5,2.4,2.4),CFrame.new(to-Vector3.new(0,.4,0))*CFrame.Angles(0,0,math.pi/2),SAND,GRAIN)
	column.Shape=Enum.PartType.Cylinder;column.Transparency=.35
	K.tween(column,.28,{Size=Vector3.new(5.4,.6,.6),Transparency=1})
	Debris:AddItem(column,.32)
	if (to-from).Magnitude>1 then
		for k=1,4 do grains(fx,from:Lerp(to,k/5)-Vector3.new(0,1,0),5,6,true) end
	end
	K.sound(K.anchorPart(fx.folder,from),K.SOUND.whoosh,.35,.6)
end
-- Sand Burial: the coffin closes on the body and bursts.
STYLES.sandburial=function(fx,impact)
	local at=impact.position
	local ball=K.block(fx.folder,Vector3.one*7.5,CFrame.new(at),SAND,GRAIN);ball.Shape=Enum.PartType.Ball;ball.Transparency=.05
	K.tween(ball,.12,{Size=Vector3.one*5.2},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
	task.delay(.13,function() if ball.Parent then K.tween(ball,.3,{Size=Vector3.one*9,Transparency=1}) end end)
	Debris:AddItem(ball,.5)
	task.delay(.12,function()
		dust(fx,at,30,3)
		grains(fx,at+Vector3.new(0,1,0),40,30,false)
		sandRing(fx,at,3,18,.5)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.55,.6)
	end)
	fx:cheer(1)
end
-- Desert Wave: a wall of sand columns rises in front of him, then its crest
-- falls forward onto whoever stood there.
STYLES.sandwall=function(fx,impact)
	local at=impact.position
	local look=flatUnit(impact.direction or Vector3.zAxis)
	local y=ground(fx,at,at.Y-3)
	local across=Vector3.new(-look.Z,0,look.X)
	local holder=K.new("Model",{Name="DesertWave"},fx.folder)
	for k=-4,4 do
		local spot=Vector3.new(at.X,y,at.Z)+across*k*1.45-look*math.abs(k)*.3
		local frame=CFrame.lookAt(spot,spot+look)
		local c=column(holder,7-math.abs(k)*.5+math.random()*.8,1.05,if k%2==0 then SAND else SAND_PALE)
		placeColumn(c,frame*CFrame.new(0,-c.height,0))
		task.delay(math.abs(k)*.02,function()
			if not c.body.Parent then return end
			moveColumn(c,frame,.12)
			task.delay(.3,function()
				if not c.body.Parent then return end
				-- Tip forward about the front of its foot.
				local fall=frame*CFrame.new(0,0,-c.radius)*CFrame.Angles(math.rad(-75),0,0)*CFrame.new(0,0,c.radius)
				moveColumn(c,fall,.4,true,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
			end)
		end)
	end
	Debris:AddItem(holder,1.1)
	local foot=Vector3.new(at.X,y,at.Z)
	dust(fx,foot+Vector3.new(0,1,0),26,3)
	grains(fx,foot+Vector3.new(0,.5,0),40,30,true)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.55,.5)
	thud(fx,at,.5,.6)
	fx:cheer(.6)
end
-- Shukaku's Sand (awakening): sand surges up around him.
local function awaken(fx,impact,folder)
	local at=impact.position
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,SHUKAKU,.35,.45) end
	local y=ground(fx,at,at.Y-3)
	for k=1,3 do
		local cf=CFrame.new(at.X,y+k*1.3,at.Z)*CFrame.Angles(0,0,math.pi/2)
		local disc=K.block(fx.folder,Vector3.new(.5,3+k*1.6,3+k*1.6),cf,SAND,GRAIN)
		disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.35
		K.tween(disc,.55,{Size=Vector3.new(.2,8+k*3,8+k*3),Transparency=1,CFrame=cf+Vector3.new(0,2,0)})
		Debris:AddItem(disc,.6)
	end
	dust(fx,Vector3.new(at.X,y+1,at.Z),26,2.8)
	grains(fx,at,40,26,true)
	K.shockRing(fx.folder,Vector3.new(at.X,y+.1,at.Z),SHUKAKU,3,24,.45)
	fx:cheer(1)
end
local function impact(fx,data,folder)
	local style=data.style
	local handler=STYLES[style]
	if handler then handler(fx,data,folder);return true end
	if data.fighter~="Sand" then return false end
	-- Shared contact styles drawn in sand instead of another fighter's colours.
	if style=="awaken" then awaken(fx,data,folder);return true end
	if style=="chase" or style=="afterimage" then
		local model=folder and folder:FindFirstChild(data.owner or "")
		if model then fx:ghost(model,SAND,.25,.55) end
		dust(fx,data.position-Vector3.new(0,2.6,0),8,1.4)
		K.sound(K.anchorPart(fx.folder,data.position),K.SOUND.whoosh,.35,.7)
		return true
	end
	return false
end

-- ------------------------------------------------------------------ per frame
-- Lashes: a tendril of sand from the hand that strikes, out on the clip's
-- contact key, held through the active frames, drawn back in the recovery.
local LASH={
	Light1={{"RightHand",1}},Light2={{"LeftHand",-1}},Light3={{"RightHand",.7},{"LeftHand",-.7}},
	Air1={{"RightHand",1}},Air2={{"LeftHand",-1}},Riposte={{"RightHand",1}},
	DashAttack={{"RightHand",.45},{"LeftHand",-.45}},Sweep={{"RightHand",1.3,low=true}},
	Slam={{"RightHand",.25,down=true},{"LeftHand",-.25,down=true}},
}
local SEGMENTS=18
-- The move's own timeline as the motion engine plays it (same per-fighter
-- timings and lead), so the sand leaves the hand on the clip's contact key.
local LEAD=.03
local function timing(name)
	local spec=Attacks[name] or Attacks.Light1
	local profile=Fighters.Sand.AttackProfile and Fighters.Sand.AttackProfile[name]
	return spec.startup*(profile and profile.startup or 1),spec.active*(profile and profile.active or 1),spec.recovery*(profile and profile.recovery or 1)
end
local function reachOf(name)
	local profile=Fighters.Sand.AttackProfile and Fighters.Sand.AttackProfile[name]
	return (profile and profile.range) or (Attacks[name] and Attacks[name].range) or 8
end
local function stateOf(fx,model)
	fx.sandState=fx.sandState or setmetatable({},{__mode="k"})
	local st=fx.sandState[model]
	if not st then st={};fx.sandState[model]=st end
	return st
end
local function newLash(fx,spec)
	local holder=K.new("Model",{Name="SandLash"},fx.folder)
	local balls={}
	for i=1,SEGMENTS do
		local ball=K.block(holder,Vector3.one*.5,CFrame.new(),if i==SEGMENTS then SAND_PALE else SAND,GRAIN)
		ball.Shape=Enum.PartType.Ball;ball.Transparency=1
		balls[i]=ball
	end
	local spray=K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=0,Lifetime=NumberRange.new(.2,.4),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,.8},{1,1.8}}),Transparency=K.num({{0,.35},{1,1}}),Drag=4},
		K.new("Attachment",{},balls[SEGMENTS]))
	return {holder=holder,balls=balls,spray=spray,hand=spec[1],arc=spec[2],low=spec.low,down=spec.down}
end
local function dropLashes(st)
	for _,l in st.lashes or {} do l.holder:Destroy() end
	st.lashes=nil
end
-- Sand Pillar: sand erupts under the opponent when he stands in the volume,
-- otherwise where the volume ends: tapering tiers, a crown that bursts open
-- and a geyser of sand.
local function pillar(fx,model,root)
	local look=flatUnit(root.CFrame.LookVector)
	local spot=root.Position+look*7
	for _,id in fx.fighterIds or {} do
		local other=fx.fighters and fx.fighters:FindFirstChild(id)
		local r=other and other~=model and other:FindFirstChild("HumanoidRootPart")
		if r then
			local d=r.Position-root.Position
			local f=Vector3.new(d.X,0,d.Z)
			if f.Magnitude<13 and (f.Magnitude<1 or look:Dot(f.Unit)>.25) then spot=r.Position end
		end
	end
	local base=Vector3.new(spot.X,ground(fx,spot,root.Position.Y-3),spot.Z)
	local holder=K.new("Model",{Name="SandPillar"},fx.folder)
	local rise=0
	for i,tier in {{4,2.35},{3.6,2.05},{3.2,1.75}} do
		local frame=CFrame.new(base+Vector3.new(0,rise,0))*CFrame.Angles(0,i*1.3,0)
		local c=column(holder,tier[1],tier[2],SAND)
		placeColumn(c,frame*CFrame.new(0,-12,0))
		task.delay((i-1)*.025,function() if c.body.Parent then moveColumn(c,frame,.1) end end)
		rise+=tier[1]*.92
	end
	local top=base+Vector3.new(0,rise,0)
	for k=0,5 do
		local out=Vector3.new(math.cos(k/6*math.pi*2),0,math.sin(k/6*math.pi*2))
		local ball=K.block(holder,Vector3.one*1.2,CFrame.new(top-Vector3.new(0,1,0)),SAND_PALE,GRAIN);ball.Shape=Enum.PartType.Ball
		task.delay(.08,function() if ball.Parent then K.tween(ball,.18,{CFrame=CFrame.new(top+out*1.9+Vector3.new(0,.3,0)),Size=Vector3.one*1.5}) end end)
	end
	K.burst(fx.folder,top,{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(14,26),SpreadAngle=Vector2.new(30,30),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.6},{1,3.4}}),
		Transparency=K.num({{0,.3},{1,1}}),Acceleration=Vector3.new(0,-40,0),Drag=1},26)
	task.delay(.3,function()
		for _,d in holder:GetChildren() do
			if d:IsA("BasePart") then K.tween(d,.45,{Transparency=1,CFrame=d.CFrame-Vector3.new(0,3,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In) end
		end
	end)
	Debris:AddItem(holder,.9)
	dust(fx,base+Vector3.new(0,1,0),22,2.4)
	grains(fx,base+Vector3.new(0,1.5,0),34,34,true)
	sandRing(fx,base+Vector3.new(0,1,0),3,14,.4)
	thud(fx,base,.6,.55)
end
local function stepStrike(fx,model,actor,st)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local name=actor.attackName
	local swinging=name~=nil and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery")
	local serial=actor.attackSerial or 0
	if swinging and serial~=st.serial then
		-- A new swing: its clock starts where the server's is, like the clip's.
		st.serial=serial
		dropLashes(st)
		st.name=name;st.cut=nil;st.landed=false;st.pillarDone=name~="SandPillar"
		st.startedAt=SandFX.clock()-math.clamp(actor.attackElapsed or 0,0,.12)
		if LASH[name] then
			st.lashes={}
			for _,spec in LASH[name] do table.insert(st.lashes,newLash(fx,spec)) end
		end
	end
	if not st.name then return end
	local startup,active,recovery=timing(st.name)
	local t=SandFX.clock()-st.startedAt+LEAD
	if not st.pillarDone and t>=startup*.9 then st.pillarDone=true;pillar(fx,model,root) end
	if not st.lashes then
		if t>startup+active+recovery then st.name=nil end
		return
	end
	local out0=startup*.45
	local ext=if t<out0 then 0 elseif t<startup then smooth((t-out0)/math.max(startup-out0,1e-3))
		elseif t<startup+active then 1 else 1-smooth((t-startup-active)/math.max(recovery*.55,1e-3))
	-- Hit out of the swing: the sand collapses at once.
	if actor.reaction or actor.state=="Stunned" then st.cut=st.cut or SandFX.clock() end
	if st.cut then ext=math.min(ext,1-(SandFX.clock()-st.cut)/.12) end
	if ext<=0 and (t>startup or st.cut) then dropLashes(st);st.name=nil;return end
	local reach=reachOf(st.name)
	local base=root.CFrame
	for _,l in st.lashes do
		local hand=model:FindFirstChild(l.hand)
		local from=if hand then hand.Position else base.Position
		local tipLocal=if l.down then Vector3.new(l.arc*.8,-2.6,-reach*.75) elseif l.low then Vector3.new(l.arc*.6,-2.5,-reach) else Vector3.new(l.arc*.5,.2,-reach)
		local tip=base:PointToWorldSpace(tipLocal)
		local mid=from:Lerp(tip,.45)+base.RightVector*l.arc*reach*.22+Vector3.new(0,if l.down then 2.2 else .9,0)
		local count=#l.balls
		for i,ball in l.balls do
			local u=ext*i/count
			local p=from:Lerp(mid,u):Lerp(mid:Lerp(tip,u),u)
			ball.Size=Vector3.one*(.42+.8*(i/count)^1.5)*(.4+.6*ext)
			ball.CFrame=CFrame.new(p)
			ball.Transparency=if ext<.05 then 1 else .02+(1-ext)*.5
		end
		l.spray.Rate=if ext>.6 then 50 else 0
	end
	if not st.landed and t>=startup and not st.cut then
		st.landed=true
		for _,l in st.lashes do
			local at=l.balls[#l.balls].Position
			grains(fx,at,10,12,false)
			dust(fx,at,5,1.1)
		end
	end
end
-- Shield charges: one cluster of sand circling his hips per charge. They dim
-- while he swings or is hurt, the moments the shield does not answer.
local function stepCharges(fx,model,actor,st,dt)
	local max=actor.shieldMax or 0
	local root=model:FindFirstChild("HumanoidRootPart")
	if max<=0 or not root or (actor.health or 1)<=0 then
		if st.charges then st.charges.holder:Destroy();st.charges=nil end
		return
	end
	if not st.charges or not st.charges.holder.Parent then
		local holder=K.new("Model",{Name="SandShieldCharges"},fx.folder)
		local list={}
		for i=1,max do
			local orb=K.block(holder,Vector3.one*.5,root.CFrame,SAND,GRAIN);orb.Shape=Enum.PartType.Ball
			list[i]={part=orb,shown=0}
		end
		st.charges={holder=holder,list=list,spin=0,count=actor.shield or 0}
	end
	local o=st.charges
	local count=actor.shield or 0
	for i=count+1,o.count do local e=o.list[i];if e then grains(fx,e.part.Position,6,6,false) end end
	o.count=count
	o.spin+=dt*(if (actor.awaken or 0)>0 then 2.6 else 1.5)
	local open=actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery" or actor.state=="Stunned" or actor.reaction~=nil
	for i,e in o.list do
		local want=if i<=count then (if open then .3 else 1) else 0
		e.shown+=(want-e.shown)*math.min(1,dt*10)
		local a=o.spin+(i-1)/#o.list*math.pi*2
		e.part.CFrame=CFrame.new(root.Position+Vector3.new(math.cos(a)*2.1,-.5+math.sin(o.spin*2+i)*.18,math.sin(a)*2.1))
		e.part.Size=Vector3.one*(.18+.34*e.shown)
		e.part.Transparency=1-e.shown*.95
	end
end
-- Bound in Sand Coffin (any fighter whose opponent is Gaara): bands of sand
-- climb the body from the feet and hold it.
local function stepCoffin(fx,model,actor,st)
	local held=actor.bound==true and actor.opponentFighter=="Sand" and (actor.health or 1)>0
	local root=model:FindFirstChild("HumanoidRootPart")
	if held and root and not (st.coffin and st.coffin.holder.Parent) then
		local holder=K.new("Model",{Name="SandCoffin"},fx.folder)
		local bands={}
		for k=0,4 do
			local width=3.2-k*.2+math.random()*.35
			local band=K.block(holder,Vector3.new(.8+math.random()*.3,width,width),root.CFrame,if k%2==0 then SAND else SAND_DARK,GRAIN)
			band.Shape=Enum.PartType.Cylinder;band.Transparency=1
			table.insert(bands,{part=band,y=-2.4+k*.62,phase=k*.9,tilt=(math.random()-.5)*.35,roll=(math.random()-.5)*.35})
		end
		local swirl=K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=40,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,1},{1,2.2}}),Transparency=K.num({{0,.4},{1,1}}),
			Drag=2,Acceleration=Vector3.new(0,-3,0)},K.new("Attachment",{},bands[1].part))
		st.coffin={holder=holder,bands=bands,born=SandFX.clock(),swirl=swirl}
		thud(fx,root.Position,.5,.5)
	elseif not held and st.coffin then
		local c=st.coffin;st.coffin=nil
		c.swirl.Enabled=false
		for _,b in c.bands do K.tween(b.part,.3,{Transparency=1,Size=b.part.Size*Vector3.new(.4,1.3,1.3)}) end
		Debris:AddItem(c.holder,.35)
	end
	local c=st.coffin
	if c and root then
		local grow=smooth((SandFX.clock()-c.born)/.35)
		for i,b in c.bands do
			local rise=math.clamp(grow*#c.bands-(i-1),0,1)
			b.part.CFrame=root.CFrame*CFrame.new(0,-3+(b.y+3)*rise,0)*CFrame.Angles(b.tilt,os.clock()*(2+i*.5)+b.phase,b.roll)*CFrame.Angles(0,0,math.pi/2)
			b.part.Transparency=if rise<=0 then 1 else .08
		end
	end
end
-- The shared speed trail and awakening mantle, in sand.
local function tint(fx,model)
	local aura=fx.auras and fx.auras[model]
	if not aura then return end
	if aura.trail and not aura.sandTrail then aura.trail.Color=ColorSequence.new(SAND);aura.sandTrail=true end
	if aura.mantle and aura.sandMantle~=aura.mantle then
		aura.mantle.emitter.Color=ColorSequence.new(SHUKAKU)
		aura.mantle.emitter.Texture=K.TEX.smoke
		aura.mantle.emitter.LightEmission=.2
		aura.mantle.light.Color=SHUKAKU
		aura.sandMantle=aura.mantle
	end
end
-- The re-engage is a glide on a wave of sand, not a run: sand pours under
-- his feet for as long as it lasts.
local function stepGlide(fx,model,actor,st)
	local root=model:FindFirstChild("HumanoidRootPart")
	local gliding=actor.state=="Rush" and (actor.health or 1)>0
	if gliding and root and not (st.glide and st.glide.Parent) then
		local at=K.new("Attachment",{Name="SandGlide",Position=Vector3.new(0,-2.8,0)},root)
		K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=90,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(70,70),
			EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.4},{1,3.2}}),
			Transparency=K.num({{0,.25},{1,1}}),Drag=3,Acceleration=Vector3.new(0,-8,0),Rotation=NumberRange.new(0,360)},at)
		st.glide=at
	elseif not gliding and st.glide then
		local e=st.glide:FindFirstChildOfClass("ParticleEmitter");if e then e.Enabled=false end
		Debris:AddItem(st.glide,.7);st.glide=nil
	end
end
local function fighter(fx,model,actor,dt)
	if not model or not actor then return end
	local st=stateOf(fx,model)
	stepCoffin(fx,model,actor,st)
	if actor.fighterId~="Sand" then return end
	stepGlide(fx,model,actor,st)
	stepStrike(fx,model,actor,st)
	stepCharges(fx,model,actor,st,dt)
	tint(fx,model)
end

function SandFX.install(FX,kit)
	K=kit
	kit.BUILD.sand=buildBullet
	kit.BUILD.sandwave=buildWave
	FX.poses.sand=bulletPose
	FX.poses.sandwave=wavePose
	table.insert(FX.layers,{name="Sand",impact=impact,fighter=fighter})
end
SandFX.STYLES=STYLES
return SandFX
