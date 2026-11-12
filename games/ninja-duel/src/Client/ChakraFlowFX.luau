-- ChakraFlow on the client (Freedom, user 28/10: chakra infusions): the load
-- (the body glows in its nature, chakra rising off it), the infused limbs
-- while the strike is out, the nature on contact, the leap and the dash.
-- Presentation only: the server (Server/ChakraFlow) decides everything.
-- One layer installed into Effects (like LeeFX): Effects only offers helpers.
--
-- (06/11, user: « Tout ce qui est chargé au chakra, on comprend pas bien,
-- c'est similaire pour beaucoup. Il faut vraiment qu'il y ait des
-- différences. Et il faut qu'il y ait des bruits pour tout ça aussi. ») Every
-- nature rose off the body as the same flame texture, poured off the four
-- limbs as the same particles and flashed the same way on contact: only the
-- colour changed, and only lightning's contact made a sound. Each nature now
-- has its own shapes and its own sounds, at the load, on the limbs while the
-- strike is out, on contact, at the leap and at the dash:
--   Lightning   sparks crackling off the body, jagged arcs jumping across it,
--               a strobing light; electric crackle, a buzz while loaded
--   Fire        flames licking off the torso, embers drifting up, firelight
--               flicker; a crackle loop while lit, a fiery whump on contact
--   Wind        pale rings of air climbing the body, a spiral at the feet,
--               cutting trails on the limbs, an X of air cuts on contact;
--               high whistles
--   Sand        matte grains pouring off the shoulders, a dusty shell, dust
--               drifting at the feet (no glow); a grinding hiss
--   GentleFist  the chakra in the palms only, veins of light down the arms,
--               points twinkling on the body, a needle of chakra through the
--               body on contact; a deep hum and a crisp tap
--   Strength    (Lee cannot mould chakra) no glow at all: steam off the
--               body, sweat flicked off, the feet stamping dust; heavy thumps
--   Chakra      a clean blue glow hugging the body, smooth wisps (Minato and
--               any fighter without a nature); a clean resonant whoosh
--   Earth       (Kakashi's Doton spike) pebbles, rock dust, a crack; rock
--               and rumble
-- Restrained like look pass 2: the body and its colours stay readable inside.
-- Sounds come only from the game's own set (Effects SOUND), told apart by
-- pitch and layering.
local Debris=game:GetService("Debris")
local Kit=require(script.Parent.VfxKit)
local ShadowFX=require(script.Parent.ShadowFX)

local ChakraFlowFX={}
local K -- Effects' helpers, handed over by install()

ChakraFlowFX.Color={
	Lightning=Color3.fromRGB(150,205,255),Fire=Color3.fromRGB(255,124,44),Wind=Color3.fromRGB(176,255,226),
	Sand=Color3.fromRGB(218,184,116),GentleFist=Color3.fromRGB(196,216,255),Strength=Color3.fromRGB(255,196,90),
	Chakra=Color3.fromRGB(110,172,255),Earth=Color3.fromRGB(138,112,84),
}
local CORE=Color3.fromRGB(250,252,255)
local NEON=Enum.Material.Neon
local DUST=Color3.fromRGB(206,194,168)
local LIMBS={"RightHand","LeftHand","RightFoot","LeftFoot"}
local HANDS={"RightHand","LeftHand"}
-- Where a lightning arc may jump from on a loaded body.
local ARC_FROM={"UpperTorso","LowerTorso","RightUpperArm","LeftUpperArm","RightLowerLeg","LeftLowerLeg","Head"}
-- (06/11) Where each nature's aura sits on the root: lightning at the chest,
-- the wind at the feet (its rings climb the body), sand at the shoulders (it
-- pours down), Lee's steam at the chest; the rest at the hips.
local AURA_AT={Lightning=Vector3.new(0,.4,0),Wind=Vector3.new(0,-2.4,0),Sand=Vector3.new(0,1.1,0),Earth=Vector3.new(0,1.1,0),Strength=Vector3.new(0,.6,0)}
-- (06/11) Each nature's sounds: {sound (Effects SOUND), volume, pitch, fade}.
-- load: the chakra comes up; swing: the infused strike leaves; hit: contact;
-- leap / dash: the chakra jump and dash.
ChakraFlowFX.Sound={
	Lightning={load={{"electric",.45,1.15}},swing={{"electric",.28,1.5}},hit={{"electric",.5,1},{"hit",.3,1.45}},
		leap={{"electric",.35,1.3},{"whoosh",.22,.95}},dash={{"electric",.35,1.6}}},
	Fire={load={{"fireLoop",.45,1,.6},{"whoosh",.3,.5}},swing={{"fireLoop",.3,1.25,.35},{"whoosh",.22,.75}},
		hit={{"boom",.28,1.55},{"fireLoop",.35,1.1,.45}},leap={{"whoosh",.35,.6},{"fireLoop",.3,1,.5}},
		dash={{"whoosh",.35,.7},{"fireLoop",.25,1.2,.35}}},
	Wind={load={{"whooshBy",.45,1.7},{"swish",.25,1.35}},swing={{"swish",.35,1.65}},hit={{"swish",.45,1.3},{"whooshBy",.32,1.9}},
		leap={{"whooshBy",.42,1.35}},dash={{"whooshBy",.45,1.6}}},
	Sand={load={{"debris",.32,1.55,.5},{"land",.2,1.25}},swing={{"debris",.22,1.9,.3}},hit={{"debris",.42,1.3,.6},{"body",.35,.8}},
		leap={{"debris",.32,1.25,.5},{"land",.25,.9}},dash={{"debris",.28,1.7,.35}}},
	GentleFist={load={{"whoosh",.4,.42},{"swish",.18,.55}},swing={{"whoosh",.25,.62}},hit={{"hit",.4,1.55},{"whoosh",.3,.48}},
		leap={{"whoosh",.32,.5}},dash={{"whoosh",.35,.55}}},
	Strength={load={{"heavy",.4,.7},{"land",.35,.75}},swing={{"swish",.3,.75}},hit={{"heavy",.55,.8},{"punch",.4,.7}},
		leap={{"land",.5,.6},{"heavy",.35,.6}},dash={{"land",.3,.85},{"whooshBy",.28,.9}}},
	Chakra={load={{"whoosh",.32,.9},{"swish",.2,.6}},swing={{"swish",.28,1}},hit={{"hit",.35,1.15},{"whoosh",.25,1.2}},
		leap={{"whoosh",.4,.75}},dash={{"whoosh",.35,1.1}}},
	Earth={load={{"rock",.4,.8},{"debris",.25,.8,.5}},swing={{"swish",.3,.8}},hit={{"rock",.55,.8},{"debris",.4,.7,.8}},
		leap={{"rock",.4,.7},{"land",.35,.7}},dash={{"debris",.25,1.2,.35}}},
}

local function colorOf(nature) return ChakraFlowFX.Color[nature or ""] or ChakraFlowFX.Color.Chakra end
-- The look a nature is drawn with: an unknown nature is plain chakra.
local function lookOf(nature) return if ChakraFlowFX.Color[nature or ""] then nature else "Chakra" end
local function cueOf(look,moment)
	local set=ChakraFlowFX.Sound[look]
	return set and set[moment]
end
-- A cue's sounds on a part (they follow it), each a hair off pitch so a
-- repeated one never sounds machine-made.
local function play(parent,cue,scale)
	if not (cue and parent) then return end
	for _,s in cue do
		local id=K.SOUND[s[1]]
		if id then K.sound(parent,id,s[2]*(scale or 1),s[3]*(.96+math.random()*.08),s[4]) end
	end
end
local function playAt(fx,at,cue,scale)
	if cue then play(K.anchorPart(fx.folder,at),cue,scale) end
end
local function stateOf(fx,model)
	fx.flowState=fx.flowState or setmetatable({},{__mode="k"})
	local st=fx.flowState[model]
	if not st then st={};fx.flowState[model]=st end
	return st
end
local function particles(parent,props)
	local e=K.new("ParticleEmitter",{Enabled=false,LightInfluence=0,ZOffset=.6},parent)
	for k,v in props do e[k]=v end
	return e
end
local function add(list,parent,props)
	local e=particles(parent,props)
	table.insert(list,e)
	return e
end

-- ------------------------------------------------------------------ one-shot shapes
local function scatter()
	local v=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)
	return if v.Magnitude>.05 then v.Unit else Vector3.yAxis
end
-- A jagged lightning line: four neon kinks that fade.
local function jag(fx,from,to,color,width,life)
	local delta=to-from
	local length=delta.Magnitude
	if length<.1 then return end
	local side=delta:Cross(Vector3.yAxis)
	if side.Magnitude<.05 then side=Vector3.xAxis end
	side=side.Unit
	local up=side:Cross(delta).Unit
	local last=from
	for k=1,4 do
		local b=if k==4 then to else from+delta*(k/4)+side*(math.random()-.5)*length*.35+up*(math.random()-.5)*length*.25
		local piece=(b-last).Magnitude
		if piece>.02 then
			local seg=K.block(fx.folder,Vector3.new(width,width,piece),CFrame.lookAt(last:Lerp(b,.5),b),color,NEON)
			seg.Name="ChakraArc"
			K.tween(seg,life,{Transparency=1})
			Debris:AddItem(seg,life+.03)
		end
		last=b
	end
end
-- A one-shot burst whose emission points along `dir` (up when none).
local function aimed(fx,at,dir,props,count)
	local holder=K.anchorPart(fx.folder,at)
	if dir and dir.Magnitude>.05 and math.abs(dir.Unit.Y)<.95 then
		holder.CFrame=CFrame.lookAt(at,at+dir)*CFrame.Angles(-math.pi/2,0,0)
	end
	local e=particles(K.new("Attachment",{},holder),props)
	e:Emit(math.max(1,math.floor(count*(Kit.amount or 1)+.5)))
	Debris:AddItem(holder,2)
end
local function fireRamp(color)
	return K.seq({{0,Color3.fromRGB(255,240,180)},{.35,color},{1,Color3.fromRGB(150,36,12)}})
end
local function emberRamp()
	return K.seq({{0,Color3.fromRGB(255,232,150)},{1,Color3.fromRGB(255,96,30)}})
end
local function flames(fx,at,dir,count,size,spread)
	aimed(fx,at,dir,{Texture=K.TEX.fire,Lifetime=NumberRange.new(.22,.42),Speed=NumberRange.new(5,11),SpreadAngle=Vector2.new(spread,spread),
		Acceleration=Vector3.new(0,12,0),Drag=4,Color=fireRamp(ChakraFlowFX.Color.Fire),LightEmission=1,
		Size=K.num({{0,size*.8},{.35,size},{1,size*.3}}),Transparency=K.num({{0,.1},{.6,.35},{1,1}}),
		Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-90,90)},count)
end
local function embers(fx,at,count)
	K.burst(fx.folder,at,{Texture=K.TEX.fireSpark,Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(180,180),
		Acceleration=Vector3.new(0,6,0),Drag=2.5,Color=emberRamp(),LightEmission=1,Size=K.num({{0,.35},{1,.05}})},count)
end
-- Matte grains (lit by the scene, no glow) thrown out, then falling.
local function grains(fx,at,dir,color,count,speed)
	aimed(fx,at,dir,{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.45,.75),Speed=NumberRange.new(speed*.6,speed),SpreadAngle=Vector2.new(55,55),
		Acceleration=Vector3.new(0,-38,0),Drag=1.5,Color=ColorSequence.new(color,color:Lerp(Color3.new(0,0,0),.25)),LightEmission=0,LightInfluence=1,
		Size=K.num({{0,.22},{1,.15}}),Transparency=K.num({{0,0},{.8,0},{1,1}})},count)
end
-- A ring of light that swells (the halo texture).
local function halo(fx,at,color,from,to,time)
	K.burst(fx.folder,at,{Texture=K.TEX.halo,Lifetime=NumberRange.new(time),Speed=NumberRange.new(0),Color=ColorSequence.new(color),LightEmission=1,
		Size=K.num({{0,from},{1,to}}),Transparency=K.num({{0,.2},{1,1}}),Rotation=NumberRange.new(0,360),ZOffset=1},1)
end
-- A spiral of air lying flat, spinning as it opens.
local function whirl(fx,at,color,from,to,time)
	K.burst(fx.folder,at,{Texture=K.TEX.swirl,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,Lifetime=NumberRange.new(time),
		Speed=NumberRange.new(.4),Color=ColorSequence.new(CORE,color),LightEmission=.6,Size=K.num({{0,from},{1,to}}),
		Transparency=K.num({{0,.3},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-760,-620)},1)
end
-- A thin blade of air laid across the line, tilted, carried on past the body.
local function slash(fx,at,dir,color,length,tilt,life)
	local across=dir:Cross(Vector3.yAxis)
	across=if across.Magnitude>.05 then across.Unit else Vector3.xAxis
	local t=math.rad(tilt)
	local along=across*math.cos(t)+Vector3.yAxis*math.sin(t)
	local cf=CFrame.lookAt(at,at+along)
	local bar=K.block(fx.folder,Vector3.new(.12,.12,length),cf,color,NEON)
	bar.Name="ChakraCut";bar.Transparency=.05
	K.tween(bar,life,{Size=Vector3.new(.02,.02,length*1.35),Transparency=1,CFrame=cf+dir*1.8})
	Debris:AddItem(bar,life+.05)
end
-- The gentle fist's chakra going clean through the body: a needle of light.
local function needle(fx,at,dir,color,length,life)
	local from=at-dir*length*.35
	local to=from+dir*length
	local bar=K.block(fx.folder,Vector3.new(.16,.16,length*.4),CFrame.lookAt(from:Lerp(to,.5),to),color,NEON)
	bar.Name="ChakraNeedle";bar.Transparency=.05
	K.tween(bar,life,{Size=Vector3.new(.03,.03,length),Transparency=1})
	Debris:AddItem(bar,life+.05)
end
-- Small stones thrown up and falling back (earth).
local function pebbles(fx,at,color,count)
	for _=1,count do
		local size=.25+math.random()*.3
		local rock=K.block(fx.folder,Vector3.one*size,CFrame.new(at)*CFrame.Angles(math.random()*6,math.random()*6,0),color,Enum.Material.Slate)
		rock.Name="ChakraPebble";ShadowFX.keep(rock)
		local a=math.random()*math.pi*2
		local out=Vector3.new(math.cos(a),0,math.sin(a))*(1.5+math.random()*2)
		K.tween(rock,.22,{CFrame=CFrame.new(at+out*.6+Vector3.new(0,1.4+math.random(),0))})
		task.delay(.22,function()
			if rock.Parent then K.tween(rock,.3,{CFrame=CFrame.new(at+out-Vector3.new(0,.3,0)),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In) end
		end)
		Debris:AddItem(rock,.6)
	end
end
-- A short-lived mark on the floor under a point (crack, scorch): the push
-- leaves a trace, held briefly so the arena never fills up with them.
local function groundMark(fx,at,texture,size,hold)
	local ok,floor=pcall(K.floorUnder,fx,at+Vector3.new(0,.5,0),2,6)
	if ok and floor then Kit.ground(fx.folder,floor.Position,floor.Normal,texture,size,hold,1,Color3.new(1,1,1),.1) end
end

-- ------------------------------------------------------------------ the aura
-- Built once per nature (an attachment on the root, a light, and the
-- nature's own pieces). `emitters` show while the body is loaded; `both` also
-- stay on through the infused strike that spends the load (the gentle fist's
-- palms and veins, the chakra sheath). The main emitter is always "Rise".
local BUILD={}
BUILD.Lightning=function(a,model,root,color)
	-- sparks crackling off the chest, static on the torso; arcs in TICK
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.spark,Rate=26,Lifetime=NumberRange.new(.05,.12),Speed=NumberRange.new(4,10),
		SpreadAngle=Vector2.new(180,180),Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,Size=K.num({{0,.7},{1,0}}),
		Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-600,600),Drag=6})
	local torso=model:FindFirstChild("UpperTorso")
	if torso then
		table.insert(a.extras,add(a.emitters,torso,{Name="ChakraFlowStatic",Texture=K.TEX.spark,Rate=16,Lifetime=NumberRange.new(.04,.08),
			Speed=NumberRange.new(0,1),Color=ColorSequence.new(CORE),LightEmission=1,Size=K.num({{0,.55},{1,0}}),Rotation=NumberRange.new(0,360),LockedToPart=true}))
	end
	a.light.Range=14
end
BUILD.Fire=function(a,model,root,color)
	local ramp=fireRamp(color)
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.fire,Rate=20,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(4,7),
		SpreadAngle=Vector2.new(16,16),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,9,0),Color=ramp,LightEmission=.9,
		Size=K.num({{0,.9},{.4,1.3},{1,.2}}),Transparency=K.num({{0,.5},{.5,.62},{1,1}}),Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-60,60),Drag=1})
	add(a.emitters,a.at,{Name="Embers",Texture=K.TEX.fireSpark,Rate=12,Lifetime=NumberRange.new(.6,1.1),Speed=NumberRange.new(2,5),
		SpreadAngle=Vector2.new(50,50),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,5,0),Drag=1.5,Color=emberRamp(),
		LightEmission=1,Size=K.num({{0,.3},{1,.08}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-200,200)})
	local torso=model:FindFirstChild("UpperTorso")
	if torso then
		-- small tongues licking off the torso itself, not a column over it
		table.insert(a.extras,add(a.emitters,torso,{Name="ChakraFlowLick",Texture=K.TEX.fire,Rate=12,Lifetime=NumberRange.new(.2,.35),
			Speed=NumberRange.new(2,4),SpreadAngle=Vector2.new(20,20),Acceleration=Vector3.new(0,10,0),Color=ramp,LightEmission=.9,
			Size=K.num({{0,.6},{.4,.9},{1,.1}}),Transparency=K.num({{0,.45},{1,1}}),Rotation=NumberRange.new(0,360)}))
	end
	a.loop=K.new("Sound",{Name="ChakraFlowCrackle",SoundId=K.SOUND.fireLoop,Volume=0,Looped=true,PlaybackSpeed=1.05,
		RollOffMaxDistance=70,RollOffMinDistance=10},root)
	table.insert(a.extras,a.loop)
	a.seed=math.random()*100
end
BUILD.Wind=function(a,model,root,color)
	-- rings of air climbing the body from the feet, a spiral spinning under it
	-- (07/11, Studio: Naruto loaded, seen from behind: no ring at all. A low
	-- Rate is cut down by the graphics quality, to nothing here; pale mint
	-- added onto bright sand added nothing either) the rings are emitted by
	-- hand (TICK.Wind), a deeper teal lit by the scene.
	local deep=color:Lerp(Color3.fromRGB(30,150,130),.45)
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.halo,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection=Enum.NormalId.Top,Rate=0,Lifetime=NumberRange.new(.55,.7),Speed=NumberRange.new(5,6.5),SpreadAngle=Vector2.new(0,0),
		Color=K.seq({{0,color},{1,deep}}),LightEmission=.15,LightInfluence=.4,Size=K.num({{0,2.4},{1,3.4}}),Transparency=K.num({{0,1},{.15,.35},{.7,.5},{1,1}}),
		Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(120,260),LockedToPart=true})
	a.spiral=add(a.emitters,a.at,{Name="Spiral",Texture=K.TEX.swirl,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection=Enum.NormalId.Top,Rate=0,Lifetime=NumberRange.new(.3,.4),Speed=NumberRange.new(.4,.6),Color=ColorSequence.new(color,deep),
		LightEmission=.15,LightInfluence=.4,Size=K.num({{0,2.6},{1,4.2}}),Transparency=K.num({{0,.38},{1,1}}),Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-900,-700),LockedToPart=true})
end
-- Sand (and earth): matte, lit by the scene, never glowing.
local function dusty(a,model,root,color)
	local dark=color:Lerp(Color3.fromRGB(90,70,40),.35)
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.smoke,Rate=40,Lifetime=NumberRange.new(.5,.75),Speed=NumberRange.new(2,4),
		SpreadAngle=Vector2.new(60,60),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,-34,0),Drag=.5,
		Color=ColorSequence.new(color,dark),LightEmission=0,LightInfluence=1,Size=K.num({{0,.2},{1,.14}}),Transparency=K.num({{0,0},{.85,0},{1,1}})})
	local torso=model:FindFirstChild("UpperTorso")
	if torso then
		-- grains sliding off the torso, and a faint shell of dust round it
		table.insert(a.extras,add(a.emitters,torso,{Name="ChakraFlowPour",Texture=K.TEX.smoke,Rate=26,Lifetime=NumberRange.new(.4,.6),
			Speed=NumberRange.new(0,1),Acceleration=Vector3.new(0,-30,0),Color=ColorSequence.new(color,dark),LightEmission=0,LightInfluence=1,
			Size=K.num({{0,.18},{1,.12}}),Transparency=K.num({{0,0},{.85,0},{1,1}})}))
		table.insert(a.extras,add(a.emitters,torso,{Name="ChakraFlowShell",Texture=K.TEX.smoke,Rate=7,Lifetime=NumberRange.new(.6,.9),
			Speed=NumberRange.new(0,.4),Color=ColorSequence.new(color),LightEmission=0,LightInfluence=1,Size=K.num({{0,1.6},{1,2.4}}),
			Transparency=K.num({{0,1},{.3,.84},{.7,.88},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-30,30),LockedToPart=true}))
	end
	local feet=K.new("Attachment",{Name="ChakraFlowFeet",Position=Vector3.new(0,-2.6,0)},root)
	table.insert(a.extras,feet)
	add(a.emitters,feet,{Name="Drift",Texture=K.TEX.smoke,Rate=5,Lifetime=NumberRange.new(.5,.8),Speed=NumberRange.new(1.5,3),
		SpreadAngle=Vector2.new(80,80),Acceleration=Vector3.new(0,.5,0),Drag=2,Color=ColorSequence.new(color),LightEmission=0,LightInfluence=1,
		Size=K.num({{0,1},{1,2.2}}),Transparency=K.num({{0,.7},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)})
end
BUILD.Sand=dusty
BUILD.Earth=dusty
BUILD.GentleFist=function(a,model,root,color)
	-- (07/11: a Rate of 6 is cut to nothing at low graphics quality, see Wind)
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.glow,Rate=16,Lifetime=NumberRange.new(.5,.8),Speed=NumberRange.new(1,2),
		SpreadAngle=Vector2.new(30,30),EmissionDirection=Enum.NormalId.Top,Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,
		Size=K.num({{0,.6},{1,.1}}),Transparency=K.num({{0,.55},{1,1}})})
	local torso=model:FindFirstChild("UpperTorso")
	if torso then
		-- the chakra points twinkling on the body
		table.insert(a.extras,add(a.emitters,torso,{Name="ChakraFlowPoints",Texture=K.TEX.spark,Rate=10,Lifetime=NumberRange.new(.15,.3),
			Speed=NumberRange.new(0,0),Color=ColorSequence.new(CORE),LightEmission=1,Size=K.num({{0,0},{.3,.32},{1,0}}),LockedToPart=true}))
	end
	-- the chakra gathered in the palms
	for _,name in HANDS do
		local hand=model:FindFirstChild(name)
		if hand then
			local at=K.new("Attachment",{Name="ChakraFlowPalm"},hand)
			table.insert(a.extras,at)
			add(a.both,at,{Name="Palm",Texture=K.TEX.glow,Rate=16,Lifetime=NumberRange.new(.18,.28),Speed=NumberRange.new(0,.3),
				Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,Size=K.num({{0,1.1},{.5,1.4},{1,.6}}),Transparency=K.num({{0,.35},{1,1}}),LockedToPart=true})
		end
	end
	-- veins of light down each arm, pulsing (TICK)
	for _,side in {"Right","Left"} do
		local chain={}
		for _,name in {side.."UpperArm",side.."LowerArm",side.."Hand"} do
			local part=model:FindFirstChild(name)
			if part then
				local at=K.new("Attachment",{Name="ChakraFlowVein"},part)
				table.insert(a.extras,at);table.insert(chain,at)
			end
		end
		for k=1,#chain-1 do
			table.insert(a.beams,K.new("Beam",{Name="ChakraFlowVein",Enabled=false,Attachment0=chain[k],Attachment1=chain[k+1],Width0=.08,Width1=.05,
				CurveSize0=if k==1 then .35 else .2,CurveSize1=if k==1 then -.3 else -.15,Color=ColorSequence.new(CORE,color),LightEmission=1,
				LightInfluence=0,Transparency=K.num({{0,.15},{1,.35}}),FaceCamera=true,Segments=8,ZOffset=.6},chain[k]))
		end
	end
end
BUILD.Strength=function(a,model,root,color)
	-- no chakra glow: steam off a straining body
	-- (07/11, Studio: Lee loaded looked exactly like Lee unloaded; the steam
	-- at .84 vanished on the sand) thicker steam, bigger drops, harder stamps.
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.smoke,Rate=18,Lifetime=NumberRange.new(.6,1),Speed=NumberRange.new(2.5,4.5),
		SpreadAngle=Vector2.new(25,25),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,2,0),Drag=1,
		Color=ColorSequence.new(Color3.fromRGB(255,250,244)),LightEmission=.25,LightInfluence=.4,Size=K.num({{0,1.4},{1,3.2}}),
		Transparency=K.num({{0,1},{.2,.48},{.6,.58},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)})
	-- sweat flicked off the head
	local head=model:FindFirstChild("Head")
	local sweat=a.at
	if head then
		sweat=K.new("Attachment",{Name="ChakraFlowSweat",Position=Vector3.new(0,.3,0)},head)
		table.insert(a.extras,sweat)
	end
	add(a.emitters,sweat,{Name="Sweat",Texture=K.TEX.droplets,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,
		FlipbookMode=Enum.ParticleFlipbookMode.OneShot,Rate=12,Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(5,8),
		SpreadAngle=Vector2.new(70,70),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,-45,0),
		Color=ColorSequence.new(Color3.fromRGB(220,236,255)),LightEmission=.35,Size=K.num({{0,.6},{1,.45}}),Transparency=K.num({{0,0},{.7,.2},{1,1}})})
	-- the feet stamping the floor (pulsed in TICK, with a low thump)
	local feet=K.new("Attachment",{Name="ChakraFlowFeet",Position=Vector3.new(0,-2.6,0)},root)
	table.insert(a.extras,feet)
	a.stomp=particles(feet,{Name="Stomp",Texture=K.TEX.smoke,Lifetime=NumberRange.new(.35,.55),Speed=NumberRange.new(6,10),
		SpreadAngle=Vector2.new(85,85),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,2,0),Drag=5,Color=ColorSequence.new(DUST),
		LightEmission=0,LightInfluence=1,Size=K.num({{0,1.3},{1,2.6}}),Transparency=K.num({{0,.25},{1,1}}),Rotation=NumberRange.new(0,360)})
end
BUILD.Chakra=function(a,model,root,color)
	-- clean, smooth wisps (no flame texture) and a glow hugging the body
	a.rise=add(a.emitters,a.at,{Name="Rise",Texture=K.TEX.glow,Rate=22,Lifetime=NumberRange.new(.35,.55),Speed=NumberRange.new(3,5),
		SpreadAngle=Vector2.new(14,14),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,4,0),Color=K.seq({{0,CORE},{.4,color},{1,color}}),
		LightEmission=1,Size=K.num({{0,1},{.5,1.2},{1,.2}}),Transparency=K.num({{0,.6},{.6,.7},{1,1}}),Drag=1})
	for _,name in {"UpperTorso","LowerTorso"} do
		local part=model:FindFirstChild(name)
		if part then
			table.insert(a.extras,add(a.both,part,{Name="ChakraFlowSheath",Texture=K.TEX.glow,Rate=8,Lifetime=NumberRange.new(.25,.4),
				Speed=NumberRange.new(0,0),Color=ColorSequence.new(color),LightEmission=.8,Size=K.num({{0,1.4},{1,1.9}}),
				Transparency=K.num({{0,1},{.3,.8},{1,1}}),LockedToPart=true}))
		end
	end
end
local function drop(a)
	for _,x in a.extras do x:Destroy() end
	a.at:Destroy();a.light:Destroy()
end
local function aura(st,model,nature)
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if st.aura and st.aura.nature==nature and st.aura.at.Parent then return st.aura end
	if st.aura then drop(st.aura) end
	local look=lookOf(nature)
	local color=colorOf(nature)
	local a={nature=nature,look=look,color=color,root=root,emitters={},both={},beams={},extras={}}
	a.at=K.new("Attachment",{Name="ChakraFlowAura",Position=AURA_AT[look] or Vector3.new(0,-.4,0)},root)
	a.light=K.new("PointLight",{Color=color,Brightness=0,Range=12,Shadows=false},root)
	-- (07/11, Studio: loaded and standing, the body looked the same: a spark
	-- now and then) The loaded body is outlined in its nature's colour.
	-- (Studio: Neji's pale blue on his white clothes did not show) a deeper rim
	local rimColor=if look=="GentleFist" then Color3.fromRGB(96,140,255) else color
	a.rim=K.new("Highlight",{Name="ChakraFlowRim",Adornee=model,FillColor=rimColor,FillTransparency=1,OutlineColor=rimColor,OutlineTransparency=1,
		DepthMode=Enum.HighlightDepthMode.Occluded,Enabled=false},model)
	table.insert(a.extras,a.rim)
	BUILD[look](a,model,root,color)
	st.aura=a
	return a
end
-- The light and the nature's own beat, every frame. `on`: loaded; `keep`:
-- loaded or out on the strike that spent the load.
local function ease(a,target,dt)
	a.light.Brightness+=(target-a.light.Brightness)*math.min(1,dt*14)
end
local TICK={}
TICK.Lightning=function(fx,a,model,now,dt,on,keep)
	if not keep then ease(a,0,dt) return end
	-- a strobe, not a breath
	a.light.Brightness=(if math.random()<.22 then 2.6 else .3+math.random()*.7)*(if on then 1 else .6)
	if not on then return end
	if now>=(a.nextArc or 0) then
		-- (07/11) two arcs at a time, oftener: the body crackles while loaded
		a.nextArc=now+.04+math.random()*.05
		for _=1,2 do
			local from=model:FindFirstChild(ARC_FROM[math.random(1,#ARC_FROM)]) or a.root
			local at=from.Position+scatter()*.5
			jag(fx,at,at+scatter()*(1.2+math.random()*1.3),if math.random()<.5 then CORE else a.color,.08,.1)
		end
	end
	if now>=(a.nextBuzz or 0) then
		a.nextBuzz=now+.5+math.random()*.35
		play(a.root,{{"electric",.12,1.6}})
	end
end
TICK.Fire=function(fx,a,model,now,dt,on,keep)
	-- firelight: a fast, uneven flicker
	ease(a,if keep then (1.2+math.noise(now*6,a.seed or 0)*.9)*(if on then 1 else .6) else 0,dt*2)
end
TICK.Wind=function(fx,a,model,now,dt,on,keep)
	ease(a,if on then .55 elseif keep then .3 else 0,dt)
	if on and now>=(a.nextRing or 0) then
		a.nextRing=now+.13
		a.rise:Emit(1)
		a.ringCount=(a.ringCount or 0)+1
		if a.spiral and a.ringCount%2==0 then a.spiral:Emit(1) end
	end
end
TICK.Sand=function(fx,a,model,now,dt,on,keep)
	ease(a,if on then .25 else 0,dt)
end
TICK.Earth=TICK.Sand
TICK.GentleFist=function(fx,a,model,now,dt,on,keep)
	ease(a,if not keep then 0 elseif on then .55+.3*math.sin(now*4) else .9,dt)
	if keep then
		for k,beam in a.beams do
			local w=.05+.06*(.5+.5*math.sin(now*7+k*1.7))
			beam.Width0=w;beam.Width1=w*.6
		end
	end
end
TICK.Strength=function(fx,a,model,now,dt,on,keep)
	ease(a,0,dt)
	if on and a.stomp and now>=(a.nextStomp or 0) then
		a.nextStomp=now+.5
		a.stomp:Emit(9)
		play(a.root,{{"heavy",.1,.5}})
	end
end
TICK.Chakra=function(fx,a,model,now,dt,on,keep)
	ease(a,if on then 1+.2*math.sin(now*5) elseif keep then .6 else 0,dt)
end

-- ------------------------------------------------------------------ infused limbs
-- Each hand and foot pours its nature while the strike is out (the gentle
-- fist: the palms only); the limb that moves fastest (the one striking)
-- pours the most, the others barely.
local function trail(limb,part,list,color,width,life,alpha,light)
	local a0=K.new("Attachment",{Name="ChakraFlowTrail0",Position=Vector3.new(0,width*.5,0)},part)
	local a1=K.new("Attachment",{Name="ChakraFlowTrail1",Position=Vector3.new(0,-width*.5,0)},part)
	local t=K.new("Trail",{Name="ChakraFlowTrail",Enabled=false,Attachment0=a0,Attachment1=a1,Lifetime=life,MinLength=.05,FaceCamera=true,
		LightEmission=light,LightInfluence=0,Color=ColorSequence.new(CORE,color),Transparency=K.num({{0,alpha},{1,1}}),WidthScale=K.num({{0,1},{1,.1}})},part)
	table.insert(list,a0);table.insert(list,a1);table.insert(list,t)
	table.insert(limb.trails,t)
end
local LIMB={}
LIMB.Lightning=function(limb,at,part,color,list)
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.spark,Rate=70,Lifetime=NumberRange.new(.04,.1),Speed=NumberRange.new(4,10),
		SpreadAngle=Vector2.new(180,180),Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,Size=K.num({{0,.8},{1,0}}),
		Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-600,600),Drag=6})
end
LIMB.Fire=function(limb,at,part,color,list)
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.fire,Rate=80,Lifetime=NumberRange.new(.14,.26),Speed=NumberRange.new(1,3),
		SpreadAngle=Vector2.new(180,180),Acceleration=Vector3.new(0,10,0),Color=fireRamp(color),LightEmission=1,
		Size=K.num({{0,1},{1,.15}}),Transparency=K.num({{0,.2},{1,1}}),Rotation=NumberRange.new(0,360),Drag=3})
	add(limb.emitters,at,{Name="Embers",Texture=K.TEX.fireSpark,Rate=18,Lifetime=NumberRange.new(.35,.6),Speed=NumberRange.new(2,5),
		SpreadAngle=Vector2.new(180,180),Acceleration=Vector3.new(0,4,0),Drag=2,Color=emberRamp(),LightEmission=1,Size=K.num({{0,.28},{1,.05}})})
end
LIMB.Wind=function(limb,at,part,color,list)
	-- a small spiral spun at the fist or the foot, and a cutting trail
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.swirl,Rate=18,Lifetime=NumberRange.new(.14,.2),Speed=NumberRange.new(0,0),
		Color=ColorSequence.new(CORE,color),LightEmission=.7,Size=K.num({{0,.8},{1,1.8}}),Transparency=K.num({{0,.45},{1,1}}),
		Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-1000,-800),LockedToPart=true})
	trail(limb,part,list,color,.9,.14,.25,.8)
end
LIMB.Sand=function(limb,at,part,color,list)
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.smoke,Rate=60,Lifetime=NumberRange.new(.4,.6),Speed=NumberRange.new(1,3),
		SpreadAngle=Vector2.new(180,180),Acceleration=Vector3.new(0,-30,0),Drag=1,Color=ColorSequence.new(color,color:Lerp(Color3.new(0,0,0),.25)),
		LightEmission=0,LightInfluence=1,Size=K.num({{0,.2},{1,.14}}),Transparency=K.num({{0,0},{.85,0},{1,1}})})
	add(limb.emitters,at,{Name="Dust",Texture=K.TEX.smoke,Rate=14,Lifetime=NumberRange.new(.3,.45),Speed=NumberRange.new(.5,1.5),
		SpreadAngle=Vector2.new(180,180),Color=ColorSequence.new(color),LightEmission=0,LightInfluence=1,
		Size=K.num({{0,.6},{1,1.4}}),Transparency=K.num({{0,.55},{1,1}}),Rotation=NumberRange.new(0,360),Drag=3})
end
LIMB.Earth=LIMB.Sand
LIMB.GentleFist=function(limb,at,part,color,list)
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.glow,Rate=40,Lifetime=NumberRange.new(.1,.18),Speed=NumberRange.new(0,.5),
		Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,Size=K.num({{0,1.3},{1,.5}}),Transparency=K.num({{0,.2},{1,1}}),LockedToPart=true})
	add(limb.emitters,at,{Name="Points",Texture=K.TEX.spark,Rate=16,Lifetime=NumberRange.new(.1,.2),Speed=NumberRange.new(2,4),
		SpreadAngle=Vector2.new(40,40),Color=ColorSequence.new(CORE),LightEmission=1,Size=K.num({{0,.3},{1,0}}),Drag=4})
end
LIMB.Strength=function(limb,at,part,color,list)
	-- no glow: the air the limb shoves, and a pale pressure streak
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.smoke,Rate=30,Lifetime=NumberRange.new(.12,.2),Speed=NumberRange.new(0,1),
		Color=ColorSequence.new(Color3.fromRGB(246,242,232)),LightEmission=0,LightInfluence=.5,Size=K.num({{0,.5},{1,1.2}}),
		Transparency=K.num({{0,.6},{1,1}}),Rotation=NumberRange.new(0,360),Drag=4})
	trail(limb,part,list,Color3.fromRGB(255,248,236),.6,.1,.45,.3)
end
LIMB.Chakra=function(limb,at,part,color,list)
	add(limb.emitters,at,{Name="Infused",Texture=K.TEX.glow,Rate=70,Lifetime=NumberRange.new(.15,.28),Speed=NumberRange.new(1,2),
		SpreadAngle=Vector2.new(180,180),Color=K.seq({{0,CORE},{.4,color},{1,color}}),LightEmission=1,
		Size=K.num({{0,.9},{1,.1}}),Transparency=K.num({{0,.25},{1,1}}),Drag=4})
	trail(limb,part,list,color,.45,.1,.35,.9)
end
local function limbs(st,model,nature)
	if st.limbs and st.limbs.nature==nature then return st.limbs end
	if st.limbs then for _,x in st.limbs.list do x:Destroy() end end
	local look=lookOf(nature)
	local color=colorOf(nature)
	local l={nature=nature,look=look,color=color,list={},limbs={},root=model:FindFirstChild("HumanoidRootPart")}
	for _,name in (if look=="GentleFist" then HANDS else LIMBS) do
		local part=model:FindFirstChild(name)
		if part then
			local at=K.new("Attachment",{Name="ChakraFlowLimb"},part)
			table.insert(l.list,at)
			local limb={part=part,emitters={},rates={},trails={}}
			LIMB[look](limb,at,part,color,l.list)
			for i,e in limb.emitters do limb.rates[i]=e.Rate end
			table.insert(l.limbs,limb)
		end
	end
	st.limbs=l
	return l
end
local function stepLimbs(fx,l,on,now,dt)
	local fastest,best=nil,0
	-- (measured against the root, so a running body does not make every limb
	-- read as the striking one)
	local base=if l.root and l.root.Parent then l.root.Position else Vector3.zero
	for _,limb in l.limbs do
		local pos=limb.part.Position-base
		local speed=if limb.last then (pos-limb.last).Magnitude/math.max(dt,1/240) else 0
		limb.last=pos
		if on then
			local k=math.clamp(.25+speed/28,.25,1)
			for i,e in limb.emitters do e.Rate=limb.rates[i]*k;e.Enabled=true end
			if speed>best then best=speed;fastest=limb end
		else
			for _,e in limb.emitters do e.Enabled=false end
		end
		for _,t in limb.trails do t.Enabled=on end
	end
	-- lightning: arcs jump off the striking limb
	if on and fastest and l.look=="Lightning" and now>=(l.nextArc or 0) then
		l.nextArc=now+.05
		local p=fastest.part.Position
		jag(fx,p,p+scatter()*(.8+math.random()*.8),if math.random()<.5 then CORE else l.color,.06,.07)
	end
end
local function fighter(fx,model,actor,dt)
	if not model or not actor then return end
	dt=dt or 1/60
	local st=stateOf(fx,model)
	local loaded=actor.chakraLoad
	-- (07/11, Studio: the Chidori Nagashi's current showed for ~0.2 s) the
	-- follow-through keeps it too.
	local strike=(actor.infused and actor.attackName and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery"))==true
	local now=os.clock()
	if loaded or st.aura then
		local a=if loaded then aura(st,model,loaded) else st.aura
		if a then
			local on=loaded~=nil
			local keep=on or (strike and actor.infused==a.nature)
			if on and not a.wasOn then a.nextBuzz=now+.45;a.nextStomp=now+.6;a.nextArc=now end
			a.wasOn=on
			if a.rim then
				-- a soft pulse: the outline breathes, the fill barely tints
				a.rim.Enabled=keep
				a.rim.OutlineTransparency=if on then .15+.2*math.sin(now*9) else .55
				a.rim.FillTransparency=if on then .8+.04*math.sin(now*9) else .92
			end
			for _,e in a.emitters do e.Enabled=on end
			for _,e in a.both do e.Enabled=keep end
			for _,b in a.beams do b.Enabled=keep end
			if a.loop and a.looping~=on then
				a.looping=on
				if on then a.loop.Volume=.13;a.loop:Play() else a.loop:Stop() end
			end
			local tick=TICK[a.look]
			if tick then tick(fx,a,model,now,dt,on,keep) else ease(a,if on then 1 else 0,dt) end
		end
	end
	if strike or st.limbs then
		local l=if strike then limbs(st,model,actor.infused) else st.limbs
		stepLimbs(fx,l,strike,now,dt)
	end
end

-- ------------------------------------------------------------------ contacts
local function modelOf(folder,id)
	return folder and id and folder:FindFirstChild(id)
end
-- The load: the chakra comes up, each nature its own way.
local function drawLoad(fx,i,look,color,model)
	local p=i.position
	local feet=p-Vector3.new(0,2.6,0)
	if look=="Lightning" then
		-- bolts climb from the floor round the feet into the body
		for k=1,4 do
			local a=k*math.pi/2+math.random()*.8
			local out=Vector3.new(math.cos(a),0,math.sin(a))
			jag(fx,feet+out*1.7,p+out*.4+Vector3.new(0,(math.random()-.3)*1.6,0),if k%2==0 then CORE else color,.09,.12)
		end
		K.sparks(fx.folder,p,CORE,14,20)
		K.flash(fx.folder,p,CORE,.6,4,.1,.3)
	elseif look=="Fire" then
		-- a ring of flame flares out of the floor and climbs
		flames(fx,feet+Vector3.new(0,.3,0),Vector3.yAxis,16,1.6,80)
		embers(fx,p,12)
		K.flash(fx.folder,p,color,.8,4,.16,.35)
	elseif look=="Wind" then
		-- rings of air open flat round the feet and the waist, a spiral under him
		K.shockRing(fx.folder,feet+Vector3.new(0,.15,0),color,2,11,.32)
		K.shockRing(fx.folder,p,CORE,1.5,7,.24)
		whirl(fx,feet+Vector3.new(0,.2,0),color,2,6,.35)
		K.smokePuff(fx.folder,feet+Vector3.new(0,.3,0),Color3.fromRGB(226,240,236),6,1.1)
	elseif look=="Sand" or look=="Earth" then
		-- the floor's sand rises round him and pours back
		K.smokePuff(fx.folder,feet+Vector3.new(0,.4,0),color,12,1.6)
		grains(fx,feet+Vector3.new(0,.3,0),Vector3.yAxis,color,26,9)
		if look=="Earth" then pebbles(fx,feet+Vector3.new(0,.3,0),color,5) end
	elseif look=="GentleFist" then
		-- no ground ring: the chakra gathers in the palms
		local any=false
		for _,name in HANDS do
			local hand=model and model:FindFirstChild(name)
			if hand then any=true;halo(fx,hand.Position,color,.4,2.6,.28) end
		end
		if not any then halo(fx,p,color,.6,3.5,.28) end
		K.shockRing(fx.folder,p+Vector3.new(0,.6,0),CORE,.8,5,.3)
	elseif look=="Strength" then
		-- a stamp: dust thrown out along the floor, a hard pale ring, no glow
		K.smokePuff(fx.folder,feet+Vector3.new(0,.3,0),DUST,14,1.6)
		K.shockRing(fx.folder,feet+Vector3.new(0,.1,0),Color3.fromRGB(255,240,214),2,12,.22)
	else
		-- the chakra comes up out of the ground round the feet
		K.shockRing(fx.folder,feet,color,2,9,.3)
		K.flash(fx.folder,p,color,1,5,.18,.35)
	end
	local root=model and model:FindFirstChild("HumanoidRootPart")
	if root then play(root,cueOf(look,"load")) else playAt(fx,p,cueOf(look,"load")) end
end
-- The infused strike leaves: a touch at the hand, and its sound on the hand.
local function drawStrike(fx,i,look,color,model)
	local hand=model and model:FindFirstChild("RightHand")
	local at=if hand then hand.Position else i.position
	if look=="Lightning" then
		K.sparks(fx.folder,at,CORE,8,14)
		for _=1,2 do jag(fx,at,at+scatter()*1.4,CORE,.06,.08) end
	elseif look=="Fire" then
		flames(fx,at,Vector3.yAxis,6,1,180)
	elseif look=="Wind" then
		local root=model and model:FindFirstChild("HumanoidRootPart")
		K.shockRing(fx.folder,at,CORE,.5,3.5,.14,root and root.CFrame.LookVector)
	elseif look=="Sand" or look=="Earth" then
		grains(fx,at,Vector3.yAxis,color,10,5)
	elseif look=="GentleFist" then
		for _,name in HANDS do
			local h=model and model:FindFirstChild(name)
			if h then halo(fx,h.Position,color,.3,1.8,.2) end
		end
	elseif look=="Strength" then
		-- (no glow: the swing is heard, the limbs show the shoved air)
	else
		K.flash(fx.folder,at,color,.6,3,.12,.3)
	end
	if hand then play(hand,cueOf(look,"swing")) else playAt(fx,at,cueOf(look,"swing")) end
end
-- Contact: each nature's own shape, never the same flash in another colour.
local function drawHit(fx,i,look,color)
	local p=i.position
	local big=i.heavy
	local dir=i.direction or Vector3.zAxis
	dir=if dir.Magnitude>.05 then dir.Unit else Vector3.zAxis
	if look=="Lightning" then
		-- bolts burst out of the contact, and flicker once more
		for k=1,(if big then 5 else 4) do jag(fx,p,p+scatter()*(1.8+math.random()*1.6),if k%2==1 then CORE else color,.1,.12) end
		-- (07/11, Studio: the current lasted one flash, .12 s, while the server
		-- holds the body .2-.45 s longer) it crackles over the body while held.
		task.spawn(function()
			local born=os.clock()
			while os.clock()-born<(if big then .5 else .4) do
				task.wait(.05)
				if not fx.folder.Parent then return end
				-- (Studio: .08 wide arcs were lost on the body) two, thicker
				for k=1,2 do
					local from=p+scatter()*(.4+math.random()*.8)
					jag(fx,from,from+scatter()*(1.4+math.random()*1.4),if k==1 then CORE else color,.13,.1)
				end
			end
		end)
		K.sparks(fx.folder,p,CORE,if big then 24 else 16,30)
		K.flash(fx.folder,p,CORE,1,if big then 6 else 4.5,.12,.1)
	elseif look=="Fire" then
		-- a bloom of flame thrown through the body, embers, a little dark smoke
		flames(fx,p,dir,if big then 22 else 14,if big then 2 else 1.5,55)
		embers(fx,p,if big then 16 else 10)
		K.flash(fx.folder,p,color,1,if big then 6 else 4.5,.18,.2)
		K.smokePuff(fx.folder,p+Vector3.new(0,.8,0),Color3.fromRGB(70,54,46),6,1.4)
	elseif look=="Wind" then
		-- an X of air cuts carried past the body, streaks of air along the line
		slash(fx,p,dir,CORE,if big then 4.6 else 3.6,35,.2)
		slash(fx,p,dir,color,if big then 4.2 else 3.2,-35,.22)
		K.shockRing(fx.folder,p+dir*1.2,color,1.5,if big then 13 else 9,.22,dir)
		aimed(fx,p,dir,{Texture=K.TEX.spark,Orientation=Enum.ParticleOrientation.VelocityParallel,Lifetime=NumberRange.new(.1,.16),
			Speed=NumberRange.new(30,46),SpreadAngle=Vector2.new(16,16),Color=K.seq({{0,CORE},{1,color}}),LightEmission=1,
			Size=K.num({{0,.45},{1,.1}}),Squash=K.num({{0,-1.4},{1,-1.8}}),Transparency=K.num({{0,0},{1,.6}}),Drag=8,ZOffset=1},if big then 12 else 8)
		K.smokePuff(fx.folder,p+dir*1.5,Color3.fromRGB(226,240,236),6,1.3)
	elseif look=="Sand" then
		-- a burst of matte sand and grains sprayed through
		K.smokePuff(fx.folder,p,color,if big then 18 else 12,2)
		grains(fx,p,dir+Vector3.new(0,.4,0),color,if big then 34 else 22,14)
		K.shockRing(fx.folder,p,color:Lerp(Color3.new(0,0,0),.2),2,if big then 11 else 8,.26,dir)
	elseif look=="Earth" then
		pebbles(fx,p,color,if big then 8 else 5)
		K.smokePuff(fx.folder,p,Color3.fromRGB(120,104,86),if big then 16 else 10,2)
		K.shockRing(fx.folder,p,color,2,if big then 12 else 9,.28,dir)
	elseif look=="GentleFist" then
		-- small and exact: the chakra goes in and out through the back
		needle(fx,p,dir,CORE,if big then 5 else 3.8,.16)
		K.shockRing(fx.folder,p+dir*1.6,color,.6,if big then 5 else 3.5,.18,dir)
		halo(fx,p,color,.5,if big then 3.4 else 2.4,.2)
	elseif look=="Strength" then
		-- raw pressure: pale rings, dust, no chakra colour
		K.shockRing(fx.folder,p,CORE,2,if big then 20 else 13,.28,dir)
		if big then K.shockRing(fx.folder,p+dir*1.5,Color3.fromRGB(255,236,200),1.5,12,.22,dir) end
		K.flash(fx.folder,p,CORE,1,if big then 6 else 4,.12,.15)
		K.smokePuff(fx.folder,p,Color3.fromRGB(214,204,180),if big then 14 else 8,if big then 2 else 1.5)
	else
		K.flash(fx.folder,p,color,1,5,.16,.2)
		K.shockRing(fx.folder,p,color,1.5,10,.22,dir)
		halo(fx,p,color,.6,3.6,.22)
	end
	playAt(fx,p,cueOf(look,"hit"),if big then 1.15 else .9)
end
-- The chakra leap: the floor takes the push, each nature its own way.
local function drawLeap(fx,i,look,color)
	local p=i.position
	if look=="Lightning" then
		K.shockRing(fx.folder,p,CORE,2,11,.24)
		for k=1,3 do
			local a=k*2.1+math.random()
			jag(fx,p+Vector3.new(math.cos(a)*1.4,0,math.sin(a)*1.4),p+Vector3.new(0,2.4+math.random(),0),if k==2 then color else CORE,.08,.12)
		end
		K.sparks(fx.folder,p+Vector3.new(0,.3,0),CORE,12,18)
	elseif look=="Fire" then
		flames(fx,p+Vector3.new(0,.3,0),Vector3.yAxis,14,1.5,85)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),Color3.fromRGB(90,74,62),6,1.4)
		groundMark(fx,p,"scorch",5,.9)
	elseif look=="Wind" then
		K.shockRing(fx.folder,p+Vector3.new(0,.1,0),color,2,14,.3)
		K.shockRing(fx.folder,p+Vector3.new(0,1.2,0),CORE,1.5,8,.24)
		whirl(fx,p+Vector3.new(0,.2,0),color,3,8,.4)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),Color3.fromRGB(226,240,236),8,1.4)
	elseif look=="Sand" or look=="Earth" then
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),color,16,2)
		grains(fx,p+Vector3.new(0,.3,0),Vector3.yAxis,color,24,12)
		if look=="Earth" then pebbles(fx,p,color,6) end
	elseif look=="GentleFist" then
		K.shockRing(fx.folder,p+Vector3.new(0,.1,0),color,1.5,10,.3)
		halo(fx,p+Vector3.new(0,.3,0),CORE,1,5,.25)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),DUST,6,1.2)
	elseif look=="Strength" then
		-- Lee's leap cracks the floor
		K.shockRing(fx.folder,p+Vector3.new(0,.1,0),Color3.fromRGB(255,240,214),2.5,16,.3)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),DUST,18,2.2)
		groundMark(fx,p,"crack",7,1.4)
	else
		-- the ground takes the push: a ring flat on it and the dust thrown out
		K.shockRing(fx.folder,p,color,2,13,.3)
		K.smokePuff(fx.folder,p+Vector3.new(0,.4,0),DUST,14,1.8)
	end
	playAt(fx,p,cueOf(look,"leap"))
end
local function drawDash(fx,i,look,color,model)
	local p=i.position
	local feet=p-Vector3.new(0,if i.air then 0 else 2.5,0)
	if model and fx.ghost then
		fx:ghost(model,if look=="Strength" then Color3.fromRGB(255,244,226) else color,.25,if look=="Sand" or look=="Strength" then .6 else .45)
	end
	if look=="Lightning" then
		for _=1,3 do jag(fx,p,p+scatter()*2,CORE,.07,.1) end
		K.sparks(fx.folder,p,CORE,12,20)
	elseif look=="Fire" then
		flames(fx,p,Vector3.yAxis,10,1.4,180)
		embers(fx,p,8)
	elseif look=="Wind" then
		K.shockRing(fx.folder,p,CORE,1.5,9,.22)
		whirl(fx,feet+Vector3.new(0,.2,0),color,2,5,.3)
	elseif look=="Sand" or look=="Earth" then
		grains(fx,p,Vector3.yAxis,color,14,8)
		K.smokePuff(fx.folder,p,color,8,1.5)
	elseif look=="GentleFist" then
		halo(fx,p,color,.6,4,.22)
	elseif look=="Strength" then
		-- (no glow: the floor takes the push)
	else
		K.flash(fx.folder,p,color,1,6,.16,.3)
	end
	K.smokePuff(fx.folder,feet,DUST,if i.air then 4 elseif look=="Strength" then 14 else 10,1.5)
	playAt(fx,p,cueOf(look,"dash"))
end
local function impact(fx,i,folder)
	local style=i.style
	if style~="chakraload" and style~="chakrastrike" and style~="chakrahit" and style~="chakraleap" and style~="chakradash" then return false end
	local look=lookOf(i.nature)
	local color=colorOf(i.nature)
	local p=i.position
	if style=="chakraload" then
		drawLoad(fx,i,look,color,modelOf(folder,i.owner))
	elseif style=="chakrastrike" then
		drawStrike(fx,i,look,color,modelOf(folder,i.owner))
	elseif style=="chakrahit" then
		-- (Neji's Rotation draws its dome, not a palm through his own body)
		if i.sig~="Rotation" then drawHit(fx,i,look,color) end
		if i.guarded then K.flash(fx.folder,p,Color3.fromRGB(255,214,120),.5,3,.1,.3) end
		-- (DEC-032) a signature's own mark: Kakashi's spike of earth, Neji's
		-- Rotation dome
		if i.sig=="EarthSpike" then
			local ok=pcall(function()
				local spike=Instance.new("Part");spike.Name="EarthSpike";spike.Anchored=true;spike.CanCollide=false;spike.CanQuery=false
				spike.Material=Enum.Material.Slate;spike.Color=color;spike.Size=Vector3.new(1.5,.2,1.5);ShadowFX.keep(spike)
				local base=CFrame.new(p)*CFrame.Angles(0,math.rad(45),math.rad(4))
				spike.CFrame=base;spike.Parent=fx.folder
				local TS=game:GetService("TweenService")
				TS:Create(spike,TweenInfo.new(.12,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(1.5,6.5,1.5),CFrame=base*CFrame.new(0,3.2,0)}):Play()
				task.delay(.55,function() if spike.Parent then TS:Create(spike,TweenInfo.new(.35),{Transparency=1,Size=Vector3.new(1.2,4,1.2)}):Play() end end)
				game:GetService("Debris"):AddItem(spike,1)
			end)
			K.smokePuff(fx.folder,p,Color3.fromRGB(120,104,86),18,2.2)
			if not ok then K.shockRing(fx.folder,p,color,2,12,.3,Vector3.yAxis) end
			-- (06/11) the floor it burst out of cracks, briefly
			groundMark(fx,p+Vector3.new(0,.3,0),"crack",6,1.2)
		elseif i.sig=="Rotation" then
			K.shockRing(fx.folder,p,color,3,14,.36,Vector3.yAxis)
			K.flash(fx.folder,p,CORE,1,8,.2,.2)
			-- (06/11) the spin is heard: a deep turn of air
			playAt(fx,p,{{"whoosh",.45,.6},{"swish",.3,.8}})
		end
	elseif style=="chakraleap" then
		drawLeap(fx,i,look,color)
	elseif style=="chakradash" then
		drawDash(fx,i,look,color,modelOf(folder,i.owner))
	end
	-- the other layers still draw their own on a chakra hit (a fist burst...)
	return style~="chakrahit"
end

function ChakraFlowFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="ChakraFlow",impact=impact,fighter=fighter})
end
return ChakraFlowFX
