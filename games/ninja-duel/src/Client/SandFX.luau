-- Gaara's sand on the client: the sand bullet and Sand Shuriken in flight, the
-- Sand Coffin wave and the body it holds, the automatic shield and its charges,
-- the body-flicker, the burial, the Desert Wave, the glide, and the lashes and
-- pillar of his strings. One identity layer installed into Effects (DEC-015: a
-- fighter's look lives in its own module, Effects only offers the registry and
-- helpers). Presentation only: nothing here can change gameplay.
--
-- Sand is one medium: moving sand is drawn as streams (two Beams with a
-- scrolling dust texture, a pale loose layer over a dense darker core) carried
-- by invisible handles, with grains and dust thrown off them. The first pass
-- used solid balls and cylinders, which read as blobs and planks (V1 directive).
local Debris=game:GetService("Debris")
local Tween=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)

local SandFX={}
local K -- Effects' helpers, handed over by install()
SandFX.clock=os.clock -- (headless tests drive time)

local SAND=Color3.fromRGB(212,176,118)
local SAND_DARK=Color3.fromRGB(176,136,82)
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

-- ------------------------------------------------------------------ streams
-- An invisible handle whose X axis is the stream's direction there (a Beam
-- curves along its attachments' axes: CurveSize0/1).
local function frame(pos,dir)
	dir=if dir.Magnitude>.01 then dir.Unit else Vector3.yAxis
	local up=Vector3.yAxis-dir*dir.Y
	if up.Magnitude<.05 then up=Vector3.xAxis-dir*dir.X end
	return CFrame.fromMatrix(pos,dir,up.Unit)
end
local function handle(parent,pos,dir)
	local p=K.block(parent,Vector3.new(.2,.2,.2),frame(pos,dir or Vector3.yAxis),SAND,Enum.Material.SmoothPlastic)
	p.Name="Handle";p.Transparency=1
	return p,K.new("Attachment",{},p)
end
local function ribbon(parent,a0,a1,w0,w1,core)
	return K.new("Beam",{Attachment0=a0,Attachment1=a1,Width0=w0,Width1=w1,Texture=K.TEX.smoke,TextureMode=Enum.TextureMode.Wrap,
		TextureLength=if core then 2 else 3,TextureSpeed=if core then 2.4 else 1.5,Color=ColorSequence.new(if core then SAND_DARK else SAND_PALE),
		Transparency=K.num(if core then {{0,0},{1,.04}} else {{0,.12},{1,.25}}),LightEmission=0,LightInfluence=1,FaceCamera=true,
		Segments=14,ZOffset=if core then .1 else 0},parent)
end
-- A stream: loose dust over a dense core, both between the same two handles.
local function stream(parent,a0,a1,w0,w1)
	return {ribbon(parent,a0,a1,w0*1.6,w1*1.6,false),ribbon(parent,a0,a1,w0,w1,true)}
end
local function widths(beams,w0,w1) beams[1].Width0=w0*1.6;beams[1].Width1=w1*1.6;beams[2].Width0=w0;beams[2].Width1=w1 end
local function curves(beams,c0,c1) for _,b in beams do b.CurveSize0=c0;b.CurveSize1=c1 end end
local function fadeWidths(beams,time) for _,b in beams do K.tween(b,time,{Width0=0,Width1=0}) end end
-- A one-off upright stream from `foot`, rising to `height` over `rise` s.
local function column(parent,foot,height,w0,w1,rise,lean)
	local h0,a0=handle(parent,foot,Vector3.yAxis)
	local h1,a1=handle(parent,foot+Vector3.new(0,.3,0),Vector3.yAxis)
	local beams=stream(parent,a0,a1,w0,w1)
	local top=foot+Vector3.new(0,height,0)+(lean or Vector3.zero)
	K.tween(h1,rise,{CFrame=frame(top,top-foot)})
	return {base=h0,top=h1,beams=beams,foot=foot}
end
-- A burst of sand that stays together as a curtain: emitted inside a box.
local function curtain(fx,cf,size,count,up)
	local box=K.block(fx.folder,size,cf,SAND,Enum.Material.SmoothPlastic);box.Transparency=1
	local e=K.new("ParticleEmitter",{Enabled=false,Texture=K.TEX.smoke,Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection=Enum.NormalId.Top,Speed=NumberRange.new(up*.5,up),Lifetime=NumberRange.new(.4,.75),SpreadAngle=Vector2.new(15,15),
		Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.2},{.5,2},{1,1.4}}),Transparency=K.num({{0,.15},{.7,.35},{1,1}}),
		Acceleration=Vector3.new(0,-30,0),Drag=1,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)},box)
	e:Emit(count)
	Debris:AddItem(box,1.2)
	return box
end
-- A body pours to the floor: each visible part sheds its volume as sand.
local function sandBody(fx,model,at)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	-- The impact may arrive after the body already reappeared elsewhere.
	local shift=at-root.Position
	if shift.Magnitude<1.5 then shift=Vector3.zero end
	local holder=K.new("Model",{Name="SandBody"},fx.folder)
	for _,d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" and d.Transparency<.9 then
			local box=K.block(holder,d.Size,d.CFrame+shift,SAND,Enum.Material.SmoothPlastic);box.Transparency=1
			local e=K.new("ParticleEmitter",{Enabled=false,Texture=K.TEX.smoke,Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
				Speed=NumberRange.new(0,1.5),Lifetime=NumberRange.new(.45,.75),Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,
				Size=K.num({{0,.9},{1,.5}}),Transparency=K.num({{0,.1},{.6,.3},{1,1}}),Acceleration=Vector3.new(0,-45,0),Rotation=NumberRange.new(0,360)},box)
			e:Emit(math.clamp(math.floor(d.Size.X*d.Size.Y*d.Size.Z*4),4,18))
		end
	end
	grains(fx,at,20,8,true)
	Debris:AddItem(holder,1)
end

-- ------------------------------------------------------------------ flights
-- Sand bullet / Sand Shuriken: a small hardened clump tumbling, shedding dust.
local function buildBullet()
	local model=K.new("Model",{Name="SandBullet"})
	local root=K.block(model,Vector3.one*.8,CFrame.new(),SAND,GRAIN);root.Name="Root";root.Shape=Enum.PartType.Ball
	local tail=K.block(model,Vector3.one*.5,CFrame.new(0,.1,.32),SAND_DARK,GRAIN);tail.Name="Tail";tail.Shape=Enum.PartType.Ball
	K.weldAll(root,{tail})
	local at=K.new("Attachment",{},root)
	K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=80,Lifetime=NumberRange.new(.25,.45),Speed=NumberRange.new(0,1.5),SpreadAngle=Vector2.new(25,25),
		Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,.8},{1,1.8}}),Transparency=K.num({{0,.3},{1,1}}),
		Drag=3,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)},at)
	model.PrimaryPart=root
	return model
end
local function bulletPose(_,entry,_,_,look,dt)
	entry.spin+=dt*9
	return look*CFrame.Angles(entry.spin,entry.spin*.6,0)
end
-- Sand Coffin: a wave of sand running along the floor — a churning crest that
-- grows as it travels and lays dust down behind it.
local function buildWave()
	local model=K.new("Model",{Name="SandWave"})
	local root=K.block(model,Vector3.new(3,.4,3),CFrame.new(),SAND,Enum.Material.SmoothPlastic);root.Name="Root";root.Transparency=1
	local at=K.new("Attachment",{Name="Spray"},root)
	K.new("ParticleEmitter",{Name="Crest",Texture=K.TEX.smoke,Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection=Enum.NormalId.Top,Rate=170,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(5,11),SpreadAngle=Vector2.new(25,25),
		Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.4},{.5,2.4},{1,1.6}}),Transparency=K.num({{0,.12},{.7,.3},{1,1}}),
		Acceleration=Vector3.new(0,-38,0),Drag=1,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)},root)
	K.new("ParticleEmitter",{Name="Spray",Texture=K.TEX.smoke,Rate=60,Lifetime=NumberRange.new(.35,.7),Speed=NumberRange.new(3,7),SpreadAngle=Vector2.new(55,55),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND_PALE),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.2},{1,3}}),
		Transparency=K.num({{0,.3},{1,1}}),Drag=3,Acceleration=Vector3.new(0,-6,0),Rotation=NumberRange.new(0,360)},at)
	K.new("ParticleEmitter",{Name="Settle",Texture=K.TEX.smoke,Rate=40,Lifetime=NumberRange.new(.9,1.3),Speed=NumberRange.new(0,.6),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(SAND_DARK),LightEmission=0,LightInfluence=1,Size=K.num({{0,2.2},{1,3.4}}),Transparency=K.num({{0,.55},{1,1}}),
		Rotation=NumberRange.new(0,360)},at)
	model.PrimaryPart=root
	return model
end
local function wavePose(fx,entry,p,age,look,dt)
	local radius=((p.radius or 1.8)+(p.growth or 0)*math.max(0,age))*1.2
	local pos=look.Position
	entry.groundIn=(entry.groundIn or 0)-dt
	if entry.groundIn<=0 then entry.groundIn=.1;entry.ground=ground(fx,pos,entry.ground or pos.Y-1.6) end
	local y=entry.ground or pos.Y-1.6
	local at=Vector3.new(pos.X,y+.3,pos.Z)
	-- The crest box grows with the wave (the emitter fills the root's volume).
	entry.root.Size=Vector3.new(radius*1.7,.4,radius*1.1)
	return CFrame.lookAt(at,at+flatUnit(p.direction))
end

-- ------------------------------------------------------------------ contacts
local STYLES={}
STYLES.sandhit=function(fx,impact)
	dust(fx,impact.position,8,1.3)
	grains(fx,impact.position,12,14,false)
	thud(fx,impact.position,.3,1.4)
end
STYLES.sandburst=function(fx,impact)
	local y=ground(fx,impact.position,impact.position.Y-2.6)
	dust(fx,impact.position,18,2.4)
	grains(fx,impact.position,26,22,true)
	curtain(fx,CFrame.new(impact.position.X,y+1,impact.position.Z),Vector3.new(5,1.5,5),40,14)
	thud(fx,impact.position,.45,.8)
end
-- The shield: an arc of sand streams snaps up between him and the blow with a
-- curtain of sand in front, then pours back down; a breaking blow bursts it.
STYLES.sandshield=function(fx,impact)
	local at=impact.position
	local face=flatUnit(impact.direction or Vector3.zAxis)
	local breaking=impact.heavy==true
	local centre=at-face*1.6
	local y=ground(fx,centre,centre.Y-3)
	local holder=K.new("Model",{Name="SandShield"},fx.folder)
	local cols={}
	for k=-2,2 do
		local dir=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(k*22)):VectorToWorldSpace(face)
		local foot=Vector3.new(centre.X,y+.2,centre.Z)+dir*2.4
		local c=column(holder,foot,5.6-math.abs(k)*.45,2.6,2.1,.07,dir*.35)
		c.dir=dir
		table.insert(cols,c)
	end
	curtain(fx,CFrame.lookAt(Vector3.new(centre.X,y+2.4,centre.Z)+face*2.3,Vector3.new(centre.X,y+2.4,centre.Z)+face*4),Vector3.new(4.5,4,.8),if breaking then 70 else 45,6)
	dust(fx,at,if breaking then 22 else 10,if breaking then 2.4 else 1.6)
	grains(fx,at,if breaking then 30 else 14,if breaking then 26 else 14,false)
	thud(fx,at,if breaking then .7 else .45,if breaking then .55 else .9)
	if breaking then
		fx:cheer(.6)
		task.delay(.06,function()
			for _,c in cols do
				if c.top.Parent then
					local fly=c.foot+c.dir*4+Vector3.new((math.random()-.5)*2,2+math.random()*2,(math.random()-.5)*2)
					K.tween(c.top,.35,{CFrame=frame(fly,fly-c.foot)});fadeWidths(c.beams,.35)
				end
			end
		end)
		Debris:AddItem(holder,.5)
	else
		task.delay(.24,function()
			for _,c in cols do
				if c.top.Parent then K.tween(c.top,.35,{CFrame=frame(c.foot+Vector3.new(0,.4,0),Vector3.yAxis)},Enum.EasingStyle.Quad,Enum.EasingDirection.In);fadeWidths(c.beams,.35) end
			end
		end)
		Debris:AddItem(holder,.7)
	end
end
-- Sand body-flicker: the body pours to the floor where he stood and a column
-- of sand gathers into him where he reappears.
STYLES.sandflicker=function(fx,impact,folder)
	local from=impact.position
	local to=impact.to or from
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then sandBody(fx,model,from) end
	local y=ground(fx,to,to.Y-3)
	local holder=K.new("Model",{Name="SandGather"},fx.folder)
	local c=column(holder,Vector3.new(to.X,y,to.Z),5.5,1.8,1,.12)
	task.delay(.12,function() if c.top.Parent then fadeWidths(c.beams,.22) end end)
	Debris:AddItem(holder,.4)
	dust(fx,to-Vector3.new(0,2.4,0),10,1.5)
	if (to-from).Magnitude>1 then
		for k=1,4 do grains(fx,from:Lerp(to,k/5)-Vector3.new(0,1,0),5,6,true) end
	end
	K.sound(K.anchorPart(fx.folder,from),K.SOUND.whoosh,.35,.6)
end
-- Sand Burial: the sand closes in on the body and bursts.
STYLES.sandburial=function(fx,impact)
	local at=impact.position
	local shell=K.block(fx.folder,Vector3.one*.4,CFrame.new(at),SAND,Enum.Material.SmoothPlastic);shell.Transparency=1
	local e=K.new("ParticleEmitter",{Enabled=false,Texture=K.TEX.smoke,Shape=Enum.ParticleEmitterShape.Sphere,ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward,
		Speed=NumberRange.new(14,20),Lifetime=NumberRange.new(.18,.26),Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,
		Size=K.num({{0,2.4},{1,1.4}}),Transparency=K.num({{0,.1},{1,.4}}),Rotation=NumberRange.new(0,360)},shell)
	shell.Size=Vector3.one*8
	e:Emit(70)
	Debris:AddItem(shell,.6)
	task.delay(.16,function()
		dust(fx,at,30,3)
		grains(fx,at+Vector3.new(0,1,0),40,30,false)
		local y=ground(fx,at,at.Y-3)
		curtain(fx,CFrame.new(at.X,y+1,at.Z),Vector3.new(6,1.5,6),50,18)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.boom,.55,.6)
	end)
	fx:cheer(1)
end
-- Desert Wave: a wall of sand streams rises in front of him, then its crest
-- falls forward onto whoever stood there.
STYLES.sandwall=function(fx,impact)
	local at=impact.position
	local look=flatUnit(impact.direction or Vector3.zAxis)
	local y=ground(fx,at,at.Y-3)
	local across=Vector3.new(-look.Z,0,look.X)
	local holder=K.new("Model",{Name="DesertWave"},fx.folder)
	for k=-3,3 do
		local foot=Vector3.new(at.X,y,at.Z)+across*k*1.6-look*math.abs(k)*.3
		local height=6.8-math.abs(k)*.5+math.random()*.6
		local c=column(holder,foot,height,2.8,2.1,.12+math.abs(k)*.02,look*.6)
		task.delay(.42,function()
			if not c.top.Parent then return end
			-- The crest tips forward and pours down in front of the wall.
			local fall=foot+look*4.5+Vector3.new(0,1,0)
			K.tween(c.top,.4,{CFrame=frame(fall,fall-foot)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
			fadeWidths(c.beams,.45)
		end)
	end
	Debris:AddItem(holder,1.1)
	local foot=Vector3.new(at.X,y,at.Z)
	curtain(fx,CFrame.lookAt(foot+Vector3.new(0,1.5,0),foot+Vector3.new(0,1.5,0)+look),Vector3.new(11,2.5,1.4),80,16)
	dust(fx,foot+Vector3.new(0,1,0),26,3)
	grains(fx,foot+Vector3.new(0,.5,0),40,30,true)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.55,.5)
	thud(fx,at,.5,.6)
	fx:cheer(.6)
end
-- Shukaku's Sand (awakening): sand spirals up around him.
local function awaken(fx,impact,folder)
	local at=impact.position
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model then fx:ghost(model,SHUKAKU,.35,.45) end
	local y=ground(fx,at,at.Y-3)
	local holder=K.new("Model",{Name="ShukakuSand"},fx.folder)
	for k=0,3 do
		local a=k/4*math.pi*2
		local foot=Vector3.new(at.X,y,at.Z)+Vector3.new(math.cos(a),0,math.sin(a))*2.4
		local c=column(holder,foot,7,1.4,.9,.18,Vector3.new(math.cos(a+1.4),0,math.sin(a+1.4))*2)
		task.delay(.3,function() if c.top.Parent then fadeWidths(c.beams,.3) end end)
	end
	Debris:AddItem(holder,.8)
	dust(fx,Vector3.new(at.X,y+1,at.Z),26,2.8)
	grains(fx,at,40,26,true)
	curtain(fx,CFrame.new(at.X,y+1,at.Z),Vector3.new(7,2,7),60,18)
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
		if model then sandBody(fx,model,data.position) end
		dust(fx,data.position-Vector3.new(0,2.6,0),8,1.4)
		K.sound(K.anchorPart(fx.folder,data.position),K.SOUND.whoosh,.35,.7)
		return true
	end
	return false
end

-- ------------------------------------------------------------------ per frame
-- Lashes: a stream of sand from the hand that strikes, out on the clip's
-- contact key, held through the active frames, drawn back in the recovery.
local LASH={
	Light1={{"RightHand",1}},Light2={{"LeftHand",-1}},Light3={{"RightHand",.7},{"LeftHand",-.7}},
	Air1={{"RightHand",1}},Air2={{"LeftHand",-1}},Riposte={{"RightHand",1}},
	DashAttack={{"RightHand",.45},{"LeftHand",-.45}},Sweep={{"RightHand",1.3,low=true}},
	Slam={{"RightHand",.25,down=true},{"LeftHand",-.25,down=true}},
	Light4={{"RightHand",1}},Light5={{"LeftHand",-1}},
	SandHand={{"RightHand",.15},{"LeftHand",-.15}},SandLowWave={{"RightHand",.6,down=true},{"LeftHand",-.6,down=true}},SandGlide={{"RightHand",.8}},SandFist={{"RightHand",.5},{"LeftHand",-.5}},
}
-- The move's own timeline as the motion engine plays it (same per-fighter
-- timings and lead), so the sand leaves the hand on the clip's contact key.
local LEAD=.03
local function timing(name)
	local spec=Attacks[name] or Attacks.Light1
	local profile=Fighters.Sand.AttackProfile and (Fighters.Sand.AttackProfile[name] or Fighters.Sand.AttackProfile[spec.clip or ""])
	return spec.startup*(profile and profile.startup or 1),spec.active*(profile and profile.active or 1),spec.recovery*(profile and profile.recovery or 1)
end
local function reachOf(name)
	local clip=Attacks[name] and Attacks[name].clip or ""
	local profile=Fighters.Sand.AttackProfile and (Fighters.Sand.AttackProfile[name] or Fighters.Sand.AttackProfile[clip])
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
	local h0,a0=handle(holder,Vector3.zero)
	local h1,a1=handle(holder,Vector3.zero)
	h1.Name="Tip"
	local beams=stream(holder,a0,a1,0,0)
	local spray=K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=0,Lifetime=NumberRange.new(.2,.4),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
		Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.4},{1,2.2}}),Transparency=K.num({{0,.2},{1,1}}),Drag=4,
		Rotation=NumberRange.new(0,360)},a1)
	return {holder=holder,h0=h0,h1=h1,beams=beams,spray=spray,hand=spec[1],arc=spec[2],low=spec.low,down=spec.down}
end
local function dropLashes(st)
	for _,l in st.lashes or {} do l.holder:Destroy() end
	st.lashes=nil
end
-- Sand Pillar: sand erupts under the opponent when he stands in the volume,
-- otherwise where the volume ends: twisting streams, a crown that bursts open
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
	local cols={}
	for k=0,2 do
		local a=k/3*math.pi*2
		local off=Vector3.new(math.cos(a),0,math.sin(a))*.9
		local twist=Vector3.new(math.cos(a+1.2),0,math.sin(a+1.2))*.9-off
		table.insert(cols,column(holder,base+off,10,4.2,2.4,.1+k*.02,twist))
	end
	local top=base+Vector3.new(0,10,0)
	task.delay(.08,function()
		K.burst(fx.folder,top,{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(14,26),SpreadAngle=Vector2.new(45,45),
			EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.8},{1,3.6}}),
			Transparency=K.num({{0,.2},{1,1}}),Acceleration=Vector3.new(0,-40,0),Drag=1,Rotation=NumberRange.new(0,360)},34)
	end)
	task.delay(.3,function()
		for _,c in cols do
			if c.top.Parent then K.tween(c.top,.45,{CFrame=frame(c.foot+Vector3.new(0,2,0),Vector3.yAxis)},Enum.EasingStyle.Quad,Enum.EasingDirection.In);fadeWidths(c.beams,.45) end
		end
	end)
	Debris:AddItem(holder,.9)
	curtain(fx,CFrame.new(base+Vector3.new(0,1,0)),Vector3.new(5,1.5,5),40,22)
	dust(fx,base+Vector3.new(0,1,0),22,2.4)
	grains(fx,base+Vector3.new(0,1.5,0),34,34,true)
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
		-- The part of the curve already out: a quadratic Bezier cut at `ext`,
		-- drawn as the Beam's cubic (CurveSize along each handle's axis).
		local u=math.max(ext,.02)
		local c1=from:Lerp(mid,u)
		local p1=c1:Lerp(mid:Lerp(tip,u),u)
		local q1=from+(c1-from)*(2/3)
		local q2=p1+(c1-p1)*(2/3)
		l.h0.CFrame=frame(from,q1-from)
		l.h1.CFrame=frame(p1,p1-q2)
		curves(l.beams,(q1-from).Magnitude,(p1-q2).Magnitude)
		widths(l.beams,.45*ext,1.5*ext)
		l.spray.Rate=if ext>.6 then 60 else 0
	end
	if not st.landed and t>=startup and not st.cut then
		st.landed=true
		for _,l in st.lashes do
			local at=l.h1.Position
			grains(fx,at,12,12,false)
			dust(fx,at,6,1.2)
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
			K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=14,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(0,.5),Color=ColorSequence.new(SAND_PALE),
				LightEmission=0,LightInfluence=1,Size=K.num({{0,.6},{1,1}}),Transparency=K.num({{0,.5},{1,1}}),Rotation=NumberRange.new(0,360)},orb)
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
		e.part.Size=Vector3.one*(.18+.3*e.shown)
		e.part.Transparency=1-e.shown*.95
	end
end
-- Bound in Sand Coffin (any fighter whose opponent is Gaara): streams of sand
-- wind up the body from the feet and hold it.
local function stepCoffin(fx,model,actor,st)
	local held=actor.bound==true and actor.opponentFighter=="Sand" and (actor.health or 1)>0
	local root=model:FindFirstChild("HumanoidRootPart")
	if held and root and not (st.coffin and st.coffin.holder.Parent) then
		local holder=K.new("Model",{Name="SandCoffin"},fx.folder)
		local winds={}
		for k=0,2 do
			local h0,a0=handle(holder,root.Position)
			local h1,a1=handle(holder,root.Position)
			table.insert(winds,{h0=h0,h1=h1,beams=stream(holder,a0,a1,1.4,1),phase=k/3*math.pi*2})
		end
		local swirl=K.new("ParticleEmitter",{Texture=K.TEX.smoke,Rate=50,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.2},{1,2.4}}),Transparency=K.num({{0,.35},{1,1}}),
			Drag=2,Acceleration=Vector3.new(0,-3,0),Rotation=NumberRange.new(0,360)},K.new("Attachment",{},winds[1].h0))
		-- (Studio film 28/10: the bind read as dust at the feet.) The coffin
		-- itself: bands of packed sand that climb the body from the feet and
		-- close round it up to the neck, each a little narrower, turning
		-- against the next, so the body is visibly encased (the series' shot).
		local bands={}
		for k=1,8 do
			local band=K.block(holder,Vector3.new(.7,2.9,2.9),root.CFrame,if k%2==0 then SAND_DARK else SAND,GRAIN)
			band.Shape=Enum.PartType.Cylinder;band.Transparency=1;band.CastShadow=true
			table.insert(bands,{part=band,k=k,turn=(if k%2==0 then 1 else -1)*(.8+k*.12)})
		end
		st.coffin={holder=holder,winds=winds,born=SandFX.clock(),swirl=swirl,bands=bands}
		thud(fx,root.Position,.5,.5)
	elseif not held and st.coffin then
		local c=st.coffin;st.coffin=nil
		c.swirl.Enabled=false
		for _,w in c.winds do fadeWidths(w.beams,.3) end
		-- released: the shell crumbles (bands drop and thin out)
		for _,b in c.bands or {} do
			Tween:Create(b.part,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
				{Transparency=1,CFrame=b.part.CFrame*CFrame.new(-.8,0,0),Size=b.part.Size*Vector3.new(.4,1.15,1.15)}):Play()
		end
		Debris:AddItem(c.holder,.35)
	end
	local c=st.coffin
	if c and root then
		local grow=smooth((SandFX.clock()-c.born)/.35)
		local spin=SandFX.clock()*2.4
		for _,w in c.winds do
			local a=spin+w.phase
			local foot=root.Position+Vector3.new(math.cos(a)*1.7,-2.8,math.sin(a)*1.7)
			local b=a+2.2
			local top=root.Position+Vector3.new(math.cos(b)*1.5,-2.8+4.4*grow,math.sin(b)*1.5)
			w.h0.CFrame=frame(foot,top-foot)
			w.h1.CFrame=frame(top,top-foot)
		end
		local age=SandFX.clock()-c.born
		for _,b in c.bands or {} do
			-- band k reaches its height at (k-1)*.06 s and settles there
			local up=smooth((age-(b.k-1)*.055)/.2)
			local y=-2.75+(b.k-.5)*.66
			local r=(2.9-b.k*.12)*(.55+.45*up)
			local wob=math.sin(age*7+b.k)*.06
			b.part.Size=Vector3.new(.66,r,r)
			b.part.CFrame=CFrame.new(root.Position+Vector3.new(wob,y-(1-up)*1.2,-wob))*CFrame.Angles(0,age*b.turn,0)*CFrame.Angles(0,0,math.pi/2)
			b.part.Transparency=1-up
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
			EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(SAND),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.4},{1,3.2}}),
			Transparency=K.num({{0,.2},{1,1}}),Drag=3,Acceleration=Vector3.new(0,-8,0),Rotation=NumberRange.new(0,360)},at)
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
