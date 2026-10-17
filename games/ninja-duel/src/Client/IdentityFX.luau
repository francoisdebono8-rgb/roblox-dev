-- CORE4 identity on the client (mission NEXT_VALIDATION_ROSTER_SCALE §5): what
-- each of the four prodigies does differently must be seen, not read in numbers.
-- Every cue answers a server fact (the contact feed and the snapshot).
--   Neji    the palm lands on the very chakra point it closes (an open palm
--           printed there, not a fist burst at the body's centre); a blocked
--           palm still shows the chakra it drained; the closed points keep a
--           marker readable at any distance; 64 Palms counts 2-4-8-16-32-64 over
--           the victim for both players and the last palm throws the body; the
--           palms stay lit while the Rotation counter is open; a body a Vacuum
--           Palm drives into a wall leaves the air's palm print on the stone.
--   Minato  a planted kunai, a floor formula and a body mark look apart; the
--           arrival window rings under him; an arrival strike that carries the
--           combo through the jump links in gold; the Rasengan grinds where it
--           lands; Yellow Flash draws its thread back to the return seal.
--   Itachi  the Read stance turns its tomoe at his feet; a read draws the line
--           from his eyes to the swing and the counter window closes under him;
--           a caught image lights the real body; ricochet and Geometry paths
--           flash; his fire lane is one scorched strip across the field.
--   Sasuke  the curse spreads from the neck as it takes him (across the face
--           when it starves); the Dancing Leaf's shadow and the vault's arc; the
--           Phoenix Flower's hidden steel glints out of the flames; a Chidori
--           bursts along its line, or fizzles when it finds nothing.
-- One identity layer installed into Effects (like SandFX and LeeFX): Effects
-- only offers the registry and its helpers. Presentation only: nothing here can
-- change gameplay.
local Debris=game:GetService("Debris")

local IdentityFX={}
local K -- Effects' helpers, handed over by install()
IdentityFX.clock=os.clock -- (headless tests drive time)

local HYUGA=Color3.fromRGB(190,208,255)
local HYUGA_CORE=Color3.fromRGB(240,246,255)
local HYUGA_DEEP=Color3.fromRGB(110,140,230)

local function find(folder,id) return folder and id and folder:FindFirstChild(id) end
local function rootOf(model) return model and model:FindFirstChild("HumanoidRootPart") end
local function flatUnit(v,fallback)
	local f=Vector3.new(v.X,0,v.Z)
	return if f.Magnitude>.05 then f.Unit else (fallback or Vector3.zAxis)
end
local function stateOf(fx,model)
	fx.identityState=fx.identityState or setmetatable({},{__mode="k"})
	local st=fx.identityState[model]
	if not st then st={};fx.identityState[model]=st end
	return st
end
local function fade(part,time,grow)
	K.tween(part,time,{Transparency=1,Size=part.Size*(grow or 1)})
end

-- ------------------------------------------------------------------- Neji
-- An open palm laid on a point, facing `normal` (out of the body, toward the
-- striker): the heel of the hand, four fingers and the thumb. It flares, then
-- sinks into the body: the strike reaches the network, it does not shatter.
local FINGERS={{-.21,.34},{-.07,.42},{.07,.44},{.21,.36}}
local function palmPrint(fx,at,normal,scale,transparency,life)
	local base=CFrame.lookAt(at,at+normal)
	local model=K.new("Model",{Name="PalmPrint"},fx.folder)
	local function piece(size,offset)
		local p=K.block(model,size*scale,base*offset,HYUGA_CORE,Enum.Material.Neon)
		p.Transparency=transparency
		fade(p,life,1.3)
	end
	piece(Vector3.new(.62,.56,.03),CFrame.new(0,-.06*scale,0))
	for _,f in FINGERS do piece(Vector3.new(.11,f[2],.03),CFrame.new(f[1]*scale,(.22+f[2]/2)*scale,0)) end
	piece(Vector3.new(.12,.32,.03),CFrame.new(-.4*scale,-.02*scale,0)*CFrame.Angles(0,0,math.rad(42)))
	Debris:AddItem(model,life+.05)
	return model,base
end
-- The point that took the palm: the chakra point it closed, else the chest
-- facing the striker. Returns the point and the outward normal.
local function struckPoint(fx,data,folder)
	local victim=find(folder,data.victim)
	local striker=rootOf(find(folder,data.owner))
	local at=nil
	if victim and data.point then at=fx.tenketsuWorld(victim,data.point) end
	local center=rootOf(victim)
	local from=if striker then striker.Position elseif data.direction then (data.position-data.direction*4) else nil
	local normal=if from then flatUnit(from-(at or data.position)) else Vector3.zAxis
	if not at then at=(if center then center.Position else data.position)+normal*.6+Vector3.new(0,.35,0) end
	return at,normal
end
-- The striking hand flares with the chakra it just released.
local function handFlare(fx,folder,owner,at,color)
	local model=find(folder,owner)
	local best,gap=nil,math.huge
	for _,name in {"RightHand","LeftHand"} do
		local hand=model and model:FindFirstChild(name)
		if hand then
			local d=(hand.Position-at).Magnitude
			if d<gap then best,gap=hand,d end
		end
	end
	if best then K.flash(fx.folder,best.Position,color,.2,1.3,.14,.1) end
	return best
end
-- A palm on the network (the melee palms, the 64 Palms, the chakra palm).
local function palmCue(fx,data,folder)
	local at,normal=struckPoint(fx,data,folder)
	local heavy=data.heavy==true
	palmPrint(fx,at,normal,if heavy then 1.6 else 1,if heavy then 0 else .1,if heavy then .32 else .22)
	K.flash(fx.folder,at,HYUGA_CORE,.15,if heavy then 2.4 else 1.3,.12,0)
	-- Through the body: the chakra goes in, it does not bounce off.
	local line=K.block(fx.folder,Vector3.new(.07,.07,1.5),CFrame.lookAt(at,at+normal)*CFrame.new(0,0,.75),HYUGA,Enum.Material.Neon)
	line.Name="PalmThrough";line.Transparency=.2
	fade(line,.18)
	Debris:AddItem(line,.22)
	K.shockRing(fx.folder,at,HYUGA,.3,if heavy then 6 else 2.6,.2,normal)
	handFlare(fx,folder,data.owner,at,HYUGA)
	if heavy then
		-- The palm that throws the body: the air in front of it bursts the way it flies.
		local along=flatUnit(data.direction or -normal,-normal)
		K.shockRing(fx.folder,at+along*1.2,HYUGA_CORE,2,12,.3,along)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.heavy,.4,.7)
	end
	return at,normal
end
-- A palm stopped by a guard still drains: a faint print on the guard and the
-- chakra pulled out of the body into the striking hand.
local function drainCue(fx,data,folder)
	local victim=rootOf(find(folder,data.victim))
	local striker=find(folder,data.owner)
	if not victim then return end
	local normal=flatUnit((rootOf(striker) or victim).Position-victim.Position)
	local at=victim.Position+normal*1.1+Vector3.new(0,.3,0)
	palmPrint(fx,at,normal,1.15,.55,.2)
	local hand=handFlare(fx,folder,data.owner,at,HYUGA_DEEP)
	local target=if hand then hand.Position else at+normal*2
	local holder=K.new("Model",{Name="ChakraDrain"},fx.folder)
	for k=1,math.clamp(math.floor((data.drain or 3)+.5),2,6) do
		local start=victim.Position+Vector3.new((k%3-1)*.5,.2+(k%2)*.4,0)
		local wisp=K.block(holder,Vector3.one*.18,CFrame.new(start),HYUGA,Enum.Material.Neon)
		wisp.Shape=Enum.PartType.Ball;wisp.Transparency=.15
		K.tween(wisp,.28,{CFrame=CFrame.new(target),Transparency=1,Size=Vector3.one*.06})
	end
	Debris:AddItem(holder,.35)
end
-- 64 Palms: the count every palm calls (2, 4, 8 ... 64) over the victim, the
-- same for both players; a ring under Neji at each new call; it holds a beat
-- on the throwing palm, then clears.
local function countCue(fx,data,folder)
	local victim=find(folder,data.victim)
	local head=victim and (victim:FindFirstChild("Head") or rootOf(victim))
	if not head then return end
	local st=stateOf(fx,victim)
	local board=st.palmCount
	if not board or not board.gui.Parent then
		local gui=K.new("BillboardGui",{Name="PalmCount",Size=UDim2.fromOffset(150,84),StudsOffset=Vector3.new(0,3.4,0),AlwaysOnTop=true,LightInfluence=0,Adornee=head},fx.folder)
		local number=K.new("TextLabel",{Name="Count",Size=UDim2.fromScale(1,.68),BackgroundTransparency=1,Font=Enum.Font.Bangers,TextScaled=true,
			TextColor3=HYUGA_CORE,TextStrokeColor3=Color3.fromRGB(26,34,70),TextStrokeTransparency=.1,Text=""},gui)
		K.new("TextLabel",{Name="Palms",Position=UDim2.fromScale(0,.66),Size=UDim2.fromScale(1,.34),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,TextScaled=true,
			TextColor3=HYUGA,TextStrokeColor3=Color3.fromRGB(26,34,70),TextStrokeTransparency=.3,Text="PALMS"},gui)
		board={gui=gui,number=number,shown=0}
		st.palmCount=board
	end
	st.palmCountAt=IdentityFX.clock()
	local count=data.count or 0
	board.number.Text=tostring(count)
	if count~=board.shown then
		board.shown=count
		-- Each new call lands a little bigger.
		board.gui.Size=UDim2.fromOffset(150+count*.9,84+count*.5)
		local neji=rootOf(find(folder,data.owner))
		if neji then
			local floor=K.floorUnder(fx,neji.Position,2,10)
			local y=if floor then floor.Position.Y+.06 else neji.Position.Y-2.9
			local size=3+math.log(math.max(count,2),2)*1.6
			K.shockRing(fx.folder,Vector3.new(neji.Position.X,y,neji.Position.Z),if data.final then HYUGA_CORE else HYUGA,size*.6,size*2,.28)
		end
	end
	if data.final then
		board.number.TextColor3=Color3.fromRGB(255,255,255)
		st.palmCountAt=IdentityFX.clock()+.6
	end
end
-- Wall hit: what drove the body into the stone. Neji's air pressure (a Vacuum
-- Palm, the twin palm, the throwing 64th) leaves a big palm print on the wall.
local PRESSURE={VacuumPalm=true,PalmThrust=true,SixtyFourPalms=true,Light3=true,AirDrive=true}
local function wallCue(fx,data)
	if data.by~="GentleFist" or not PRESSURE[data.cause or ""] then return end
	local normal=data.normal or Vector3.zAxis
	local at=data.position+normal*.1+Vector3.new(0,.6,0)
	palmPrint(fx,at,normal,4,.05,.45)
	for k=1,3 do K.shockRing(fx.folder,data.position+normal*.12,HYUGA,1+k,6+k*4,.25+k*.08,normal) end
	K.smokePuff(fx.folder,data.position+normal,Color3.fromRGB(226,232,246),14,2)
end
local function nejiImpact(fx,data,folder)
	local style=data.style
	if style=="palm" then
		palmCue(fx,data,folder)
		if data.count then countCue(fx,data,folder) end
		-- A chakra palm (ChakraCombat) keeps its own layer on top.
		return data.chakra==nil
	end
	if style=="block" and data.drain and data.fighter=="GentleFist" then drainCue(fx,data,folder);return false end
	if style=="wall" then wallCue(fx,data);return false end
	return false
end
-- Every closed point gets a marker of constant screen size, drawn over the
-- body: the network closing reads from any distance, for both players.
local function tenketsuMarks(fx,model,actor)
	local aura=fx.auras and fx.auras[model]
	if not aura or not aura.points then return end
	local severe=actor.tenketsuSevere==true
	for _,entry in aura.points do
		local dot=entry.dot
		if dot and dot.Parent then
			local mark=entry.mark
			if not mark or not mark.Parent then
				local gui=K.new("BillboardGui",{Name="TenketsuMark",Size=UDim2.fromOffset(12,12),AlwaysOnTop=true,LightInfluence=0,Adornee=dot},dot)
				local disc=K.new("Frame",{Name="Point",Size=UDim2.fromScale(1,1),BackgroundColor3=HYUGA,BorderSizePixel=0,BackgroundTransparency=.1},gui)
				K.new("UICorner",{CornerRadius=UDim.new(1,0)},disc)
				K.new("UIStroke",{Color=HYUGA_CORE,Thickness=1.5},disc)
				entry.mark=gui;entry.markDisc=disc
				mark=gui
			end
			entry.mark.Size=if severe then UDim2.fromOffset(16,16) else UDim2.fromOffset(12,12)
			entry.markDisc.BackgroundColor3=if severe then HYUGA_CORE else HYUGA
		end
	end
end
-- Rotation repelled a strike: until the counter is spent, Neji's palms hold the
-- dome's chakra (the twin palm that glides out of the spin releases it).
local function counterGlow(fx,model,actor,st)
	local open=actor.fighterId=="GentleFist" and (actor.counter or 0)>0 and (actor.health or 1)>0
	if open and not st.counterGlow then
		local glow={}
		for _,name in {"RightHand","LeftHand"} do
			local hand=model:FindFirstChild(name)
			if hand then
				local at=K.new("Attachment",{Name="CounterPalmGlow"},hand)
				K.new("PointLight",{Color=HYUGA,Brightness=2.4,Range=6,Shadows=false},at)
				K.new("ParticleEmitter",{Texture=K.TEX.glow,Rate=24,Lifetime=NumberRange.new(.12,.2),Speed=NumberRange.new(0,.5),LockedToPart=true,
					Color=ColorSequence.new(HYUGA),LightEmission=1,LightInfluence=0,Size=K.num({{0,1},{1,.3}}),Transparency=K.num({{0,.3},{1,1}})},at)
				table.insert(glow,at)
			end
		end
		st.counterGlow=glow
		local root=rootOf(model)
		if root then K.shockRing(fx.folder,root.Position-Vector3.new(0,2.6,0),HYUGA,12,2,.25) end
	elseif not open and st.counterGlow then
		for _,at in st.counterGlow do at:Destroy() end
		st.counterGlow=nil
	end
end
-- Any body can carry closed points and a 64 Palms count; only Neji glows.
local function networkFrame(fx,model,actor,st)
	tenketsuMarks(fx,model,actor)
	counterGlow(fx,model,actor,st)
	-- A 64 Palms count left over (the flurry cut short, or the throw held its beat).
	local board=st.palmCount
	if board and IdentityFX.clock()-(st.palmCountAt or 0)>.6 then
		board.gui:Destroy();st.palmCount=nil
	end
end

-- ----------------------------------------------------------------- Minato
local MINATO=Color3.fromRGB(255,214,92)
local MINATO_CORE=Color3.fromRGB(255,248,214)
local WIND=Color3.fromRGB(190,255,226)
local RASENGAN=Color3.fromRGB(150,210,255)
local RASENGAN_CORE=Color3.fromRGB(235,250,255)
-- Three kinds of Flying Thunder God seal, three looks (Effects draws the kunai
-- and its disc; this adds what tells them apart):
--   planted kunai  a thrown marked kunai stuck in a surface: a gold beacon
--                  stands over it, seen across the stadium;
--   floor formula  the Yellow Flash return seal written where he stood (no
--                  kunai): the formula drawn on the floor, white-gold, turning;
--   body mark      a seal riding on the opponent (a marked kunai that hit, the
--                  rising kick, a wind cut): a ring of formula round the body,
--                  seen from the front as from the back, tightening as it expires.
local function segmentRing(parent,count,radius,size,color)
	local parts={}
	for _=1,count do
		local p=K.block(parent,size,CFrame.new(),color,Enum.Material.Neon)
		p.Transparency=.25
		table.insert(parts,p)
	end
	return parts
end
local function placeRing(parts,center,radius,spin,tilt)
	for i,p in parts do
		local a=(i-1)/#parts*math.pi*2+spin
		p.CFrame=center*CFrame.Angles(tilt or 0,a,0)*CFrame.new(0,0,-radius)
	end
end
local function buildSeal(fx,info)
	local model=K.new("Model",{Name="SealMark"},fx.folder)
	local look={model=model}
	if info.body then
		look.kind="body"
		look.ring=segmentRing(model,8,1.6,Vector3.new(.5,.09,.07),if info.wind then WIND else MINATO)
		look.tags=segmentRing(model,3,1.75,Vector3.new(.08,.5,.08),if info.wind then WIND else MINATO_CORE)
	elseif info.wake then
		look.kind="floor"
		look.ring=segmentRing(model,16,2.5,Vector3.new(.85,.04,.12),MINATO_CORE)
		look.strokes=segmentRing(model,8,1.5,Vector3.new(.1,.04,.7),MINATO)
		local cross={}
		for _,yaw in {0,math.pi/2} do
			local p=K.block(model,Vector3.new(1.4,.04,.14),CFrame.new(),MINATO_CORE,Enum.Material.Neon);p.Transparency=.2
			table.insert(cross,{part=p,yaw=yaw})
		end
		look.cross=cross
		K.flash(fx.folder,info.surface,MINATO_CORE,.6,5,.25,.2)
	else
		look.kind="kunai"
		local beam=K.block(model,Vector3.new(.14,7,.14),CFrame.new(),MINATO,Enum.Material.Neon)
		beam.Name="SealBeacon";beam.Transparency=.6
		look.beacon=beam
	end
	return look
end
local function stepSeal(fx,folder,look,info,clock)
	local remaining=info.remaining or 12
	local ending=remaining<1 and math.sin(clock*30)>0
	if look.kind=="body" then
		local body=folder and folder:FindFirstChild(info.body or "")
		local torso=body and (body:FindFirstChild("UpperTorso") or rootOf(body))
		if not torso then return end
		-- Round the waist, turning: wherever the camera stands it crosses the body.
		local center=CFrame.new(torso.Position-Vector3.new(0,.35,0))
		local radius=1.25+.45*math.clamp(remaining/1.5,0,1)
		placeRing(look.ring,center,radius,clock*2.2)
		placeRing(look.tags,center,radius+.15,-clock*1.4)
		for _,p in look.ring do p.Transparency=if ending then .9 else .25 end
	elseif look.kind=="floor" then
		local at=info.surface+(info.normal or Vector3.yAxis)*.06
		local base=CFrame.new(at)
		placeRing(look.ring,base,2.5,clock*.35)
		placeRing(look.strokes,base,1.5,-clock*.6)
		for _,c in look.cross do c.part.CFrame=base*CFrame.Angles(0,c.yaw+clock*.35,0) end
		local glow=if ending then .9 else .2+.15*math.sin(clock*4)
		for _,p in look.ring do p.Transparency=glow end
	else
		-- The beacon stands up from the kunai, whatever surface holds it.
		local at=info.surface+(info.normal or Vector3.yAxis)*.3
		look.beacon.CFrame=CFrame.new(at+Vector3.new(0,3.6,0))
		look.beacon.Transparency=if ending then .95 else .55+.15*math.sin(clock*5)
	end
end
local function sealFrame(fx,model,actor,clock)
	fx.identitySeals=fx.identitySeals or {}
	local folder=model.Parent
	local live={}
	for _,info in actor.seals or {} do
		local key=tostring(actor.id)..":"..tostring(info.id)
		live[key]=true
		local look=fx.identitySeals[key]
		if not look or not look.model.Parent then look=buildSeal(fx,info);fx.identitySeals[key]=look end
		stepSeal(fx,folder,look,info,clock)
	end
	local prefix=tostring(actor.id)..":"
	for key,look in fx.identitySeals do
		if string.sub(key,1,#prefix)==prefix and not live[key] then look.model:Destroy();fx.identitySeals[key]=nil end
	end
end
-- After a teleport the arrival window is open (a strike or Rasengan cancels the
-- recovery): a gold ring under him shrinks to nothing as it closes.
local function arrivalRing(fx,model,actor,st,clock)
	local root=rootOf(model)
	if actor.flash and root and (actor.health or 1)>0 then
		if not st.arrival or not st.arrival.ring.Parent then
			local ring=K.block(fx.folder,Vector3.new(.06,5,5),CFrame.new(),MINATO,Enum.Material.Neon)
			ring.Name="ArrivalWindow";ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.35
			st.arrival={ring=ring,born=clock,window=if (actor.awaken or 0)>0 then .8 else .55}
		end
		local left=1-math.clamp((clock-st.arrival.born)/st.arrival.window,0,1)
		local size=1+4*left
		st.arrival.ring.Size=Vector3.new(.06,size,size)
		st.arrival.ring.CFrame=CFrame.new(root.Position-Vector3.new(0,2.85,0))*CFrame.Angles(0,0,math.pi/2)
	elseif st.arrival then
		st.arrival.ring:Destroy();st.arrival=nil
	end
end
-- Yellow Flash: a thin gold thread from him to his newest return seal, the way
-- back the next jump takes (A -> B -> A).
local function returnThread(fx,model,actor,st)
	local awake=(actor.awaken or 0)>0 and (actor.health or 1)>0
	local newest=nil
	if awake then
		for _,info in actor.seals or {} do
			if info.wake and info.surface and (not newest or info.id>newest.id) then newest=info end
		end
	end
	local torso=model:FindFirstChild("UpperTorso") or rootOf(model)
	if newest and torso then
		local thread=st.thread
		if not thread or not thread.anchor.Parent then
			local anchor=K.anchorPart(fx.folder,newest.surface);anchor.Name="ReturnSeal"
			local a0=K.new("Attachment",{Name="ReturnThread"},torso)
			local a1=K.new("Attachment",{},anchor)
			local beam=K.new("Beam",{Name="ReturnThread",Attachment0=a0,Attachment1=a1,Width0=.12,Width1=.3,FaceCamera=true,Segments=8,CurveSize0=-4,
				Color=ColorSequence.new(MINATO),LightEmission=1,Transparency=K.num({{0,.35},{1,.55}})},anchor)
			thread={anchor=anchor,a0=a0,beam=beam,id=newest.id}
			st.thread=thread
		end
		if thread.id~=newest.id then thread.anchor.CFrame=CFrame.new(newest.surface+Vector3.new(0,.3,0));thread.id=newest.id end
	elseif st.thread then
		st.thread.anchor:Destroy();st.thread.a0:Destroy();st.thread=nil
	end
end
-- The arrival strike landed on a body still inside the combo that led to the
-- jump: a gold link where it lands, the chain visibly goes on.
local function chainCue(fx,data,folder)
	local at=data.position
	local striker=rootOf(find(folder,data.owner))
	local along=if striker then flatUnit(at-striker.Position) else Vector3.zAxis
	K.shockRing(fx.folder,at,MINATO_CORE,1.5,7,.24,along)
	K.shockRing(fx.folder,at,MINATO,3,11,.32,along)
	K.sparks(fx.folder,at,MINATO,16,22)
	if striker then
		local delta=at-striker.Position
		local streak=K.block(fx.folder,Vector3.new(.25,.25,math.max(delta.Magnitude,.5)),CFrame.lookAt(striker.Position:Lerp(at,.5),at),MINATO,Enum.Material.Neon)
		streak.Name="ChainLink";streak.Transparency=.2
		fade(streak,.18)
		Debris:AddItem(streak,.22)
	end
end
-- Rasengan where it lands: the sphere grinds into the body (rings turning on
-- every axis), not a punch flash.
local function grindCue(fx,data)
	local at=data.position
	local model=K.new("Model",{Name="RasenganGrind"},fx.folder)
	for k=1,3 do
		local ring=K.block(model,Vector3.new(.08,1.6,1.6),CFrame.new(at)*CFrame.Angles(k*1.1,k*.7,k*1.9),if k==1 then RASENGAN_CORE else RASENGAN,Enum.Material.Neon)
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.2
		K.tween(ring,.32,{Size=Vector3.new(.03,5.5,5.5),Transparency=1,CFrame=ring.CFrame*CFrame.Angles(math.pi,0,0)})
	end
	K.flash(fx.folder,at,RASENGAN_CORE,1,5,.2,0)
	K.sparks(fx.folder,at,RASENGAN,24,26)
	Debris:AddItem(model,.4)
end
local function minatoImpact(fx,data,folder)
	if data.arrival then chainCue(fx,data,folder) end
	if data.variant=="Rasengan" or data.variant=="RasenganDrop" then grindCue(fx,data) end
	return false
end
local function minatoFrame(fx,model,actor,st,clock)
	sealFrame(fx,model,actor,clock)
	arrivalRing(fx,model,actor,st,clock)
	returnThread(fx,model,actor,st)
end

-- ----------------------------------------------------------------- Itachi
local SHARINGAN=Color3.fromRGB(230,36,44)
local SHARINGAN_DEEP=Color3.fromRGB(150,16,26)
local EMBER=Color3.fromRGB(255,128,44)
-- A straight line of light from one point to another that fades at once: a
-- path shown for a beat (a prediction, a ricochet, the body behind an image).
local function streak(fx,from,to,color,width,life,name)
	local delta=to-from
	if delta.Magnitude<.3 then return nil end
	local line=K.block(fx.folder,Vector3.new(width,width,delta.Magnitude),CFrame.lookAt(from:Lerp(to,.5),to),color,Enum.Material.Neon)
	line.Name=name or "Streak";line.Transparency=.15
	K.tween(line,life,{Transparency=1,Size=Vector3.new(width*.2,width*.2,delta.Magnitude)})
	Debris:AddItem(line,life+.05)
	return line
end
-- Read stance: three tomoe turn round his feet while the eye waits for the
-- blow. The attacker sees it too: swinging into it is his choice.
local function tomoeRing(fx,model,actor,st,clock)
	local root=rootOf(model)
	if (actor.read or 0)>0 and root and (actor.health or 1)>0 then
		if not st.tomoe or not st.tomoe.model.Parent then
			local holder=K.new("Model",{Name="ReadTomoe"},fx.folder)
			local ring=K.block(holder,Vector3.new(.05,4.6,4.6),CFrame.new(),SHARINGAN,Enum.Material.Neon)
			ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.7
			local marks={}
			for _=1,3 do
				local head=K.block(holder,Vector3.one*.42,CFrame.new(),SHARINGAN_DEEP,Enum.Material.Neon);head.Shape=Enum.PartType.Ball
				local tail=K.block(holder,Vector3.new(.14,.06,.5),CFrame.new(),SHARINGAN_DEEP,Enum.Material.Neon)
				table.insert(marks,{head=head,tail=tail})
			end
			st.tomoe={model=holder,ring=ring,marks=marks}
		end
		local base=CFrame.new(root.Position-Vector3.new(0,2.85,0))
		st.tomoe.ring.CFrame=base*CFrame.Angles(0,0,math.pi/2)
		for k,m in st.tomoe.marks do
			local at=base*CFrame.Angles(0,clock*3+k*2*math.pi/3,0)*CFrame.new(0,.05,-1.75)
			m.head.CFrame=at;m.tail.CFrame=at*CFrame.new(.28,0,.12)*CFrame.Angles(0,math.rad(-50),0)
		end
	elseif st.tomoe then
		st.tomoe.model:Destroy();st.tomoe=nil
	end
end
-- A read paid off: a red ring under him shrinks with the counter window (the
-- snapshot's counter is the time left), the punish is now.
local function counterWindow(fx,model,actor,st)
	local root=rootOf(model)
	local left=actor.counter or 0
	if left>0 and root and (actor.health or 1)>0 then
		if not st.window or not st.window.Parent then
			local ring=K.block(fx.folder,Vector3.new(.06,5,5),CFrame.new(),SHARINGAN,Enum.Material.Neon)
			ring.Name="CounterWindow";ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.35
			st.window=ring
		end
		local size=1+4*math.clamp(left,0,1)
		st.window.Size=Vector3.new(.06,size,size)
		st.window.CFrame=CFrame.new(root.Position-Vector3.new(0,2.85,0))*CFrame.Angles(0,0,math.pi/2)
	elseif st.window then
		st.window:Destroy();st.window=nil
	end
end
local function itachiImpact(fx,data,folder)
	local style=data.style
	if style=="read" and data.phase~="whiff" then
		-- He saw it coming: a line from his eyes to the body that swung.
		local reader=find(folder,data.owner)
		local head=reader and reader:FindFirstChild("Head")
		local swing=rootOf(find(folder,data.victim))
		if head and swing then
			streak(fx,head.Position,swing.Position+Vector3.new(0,.6,0),SHARINGAN,.07,.3,"ReadLine")
			K.flash(fx.folder,swing.Position+Vector3.new(0,.6,0),SHARINGAN,.3,2.2,.16,.25)
		end
	elseif style=="mirage" and data.phase=="catch" then
		-- The image breaks: the real body behind it lights for a beat.
		local caster=rootOf(find(folder,data.owner))
		if caster then
			streak(fx,data.position,caster.Position,SHARINGAN,.12,.3,"MirageReveal")
			K.flash(fx.folder,caster.Position,SHARINGAN,.5,3.5,.2,.2)
		end
	elseif style=="deflect" and data.ricochet and data.to then
		-- A ricochet: its new path flashes from the bounce to the body it seeks.
		streak(fx,data.position,data.to,Color3.fromRGB(255,236,236),.1,.25,"RicochetPath")
		K.shockRing(fx.folder,data.position,SHARINGAN,.5,3.2,.18,data.direction)
	elseif style=="clash" and data.geometry and data.to then
		-- Shuriken Geometry: the two blades' meeting sends them into the flank.
		for _,side in {-.6,.6} do
			local across=flatUnit(data.to-data.position):Cross(Vector3.yAxis)*side
			streak(fx,data.position,data.to+across,Color3.fromRGB(255,236,236),.08,.25,"GeometryPath")
		end
	end
	return false
end
-- Itachi's burning lane (Elements.burnLane): the patches of one lane share a
-- scorched strip from the first to the last, so it reads as a line across the
-- field, not as scattered fires.
local function laneFrame(fx,data)
	fx.identityLanes=fx.identityLanes or {}
	local lanes={}
	for _,h in data.hazards or {} do
		if h.lane then
			local lane=lanes[h.lane] or {}
			table.insert(lane,h)
			lanes[h.lane]=lane
		end
	end
	for id,patches in lanes do
		local strip=fx.identityLanes[id]
		local first,last=patches[1].position,patches[#patches].position
		local span=Vector3.new(last.X-first.X,0,last.Z-first.Z)
		if #patches>=2 and span.Magnitude>.5 and (not strip or strip.count~=#patches or not strip.model.Parent) then
			if strip then strip.model:Destroy() end
			local model=K.new("Model",{Name="FireLane"},fx.folder)
			local width=patches[1].radius*1.5
			local along=CFrame.lookAt(first:Lerp(last,.5)-Vector3.new(0,.42,0),last-Vector3.new(0,.42,0))
			local scorch=K.block(model,Vector3.new(width,.05,span.Magnitude+width),along,Color3.fromRGB(32,22,18),Enum.Material.Slate)
			scorch.Transparency=.25
			for _,side in {-1,1} do
				local edge=K.block(model,Vector3.new(.12,.06,span.Magnitude+width*.8),along*CFrame.new(side*width*.5,.02,0),EMBER,Enum.Material.Neon)
				edge.Transparency=.3
			end
			strip={model=model,count=#patches}
			fx.identityLanes[id]=strip
		end
	end
	for id,strip in fx.identityLanes do
		if not lanes[id] then strip.model:Destroy();fx.identityLanes[id]=nil end
	end
end
local function itachiFrame(fx,model,actor,st,clock)
	tomoeRing(fx,model,actor,st,clock)
	if actor.fighterId=="Mirage" then counterWindow(fx,model,actor,st) end
end

-- ----------------------------------------------------------------- Sasuke
local CURSE=Color3.fromRGB(120,60,200)
local CURSE_INK=Color3.fromRGB(14,10,18)
local SHADOW=Color3.fromRGB(40,44,74)
local CHIDORI=Color3.fromRGB(190,220,255)
local CHIDORI_CORE=Color3.fromRGB(236,244,255)
-- The cursed seal spreads out of the neck as the awakening takes him, one
-- flame mark after another (the dress keeps three at the seal itself), and on
-- across the face while it starves. {part, offset}: the offset's Z axis is the
-- surface normal (front faces -Z, the left side turned a quarter).
local SIDE=CFrame.Angles(0,math.pi/2,0)
local CURSE_SPREAD={
	{"Head",CFrame.new(-.77,-.12,-.3)*SIDE*CFrame.Angles(0,0,math.rad(20))},
	{"Head",CFrame.new(-.77,.16,-.5)*SIDE*CFrame.Angles(0,0,math.rad(40))},
	{"UpperTorso",CFrame.new(-.75,.6,-.51)*CFrame.Angles(0,0,math.rad(-15))},
	{"Head",CFrame.new(-.5,.32,-.77)*CFrame.Angles(0,0,math.rad(55))},
	{"UpperTorso",CFrame.new(-1.01,.35,-.15)*SIDE},
	{"UpperTorso",CFrame.new(-.45,.25,-.51)*CFrame.Angles(0,0,math.rad(25))},
	{"LeftUpperArm",CFrame.new(-.05,.3,-.41)},
	{"LeftUpperArm",CFrame.new(-.41,0,-.05)*SIDE*CFrame.Angles(0,0,math.rad(15))},
	{"LeftUpperArm",CFrame.new(-.05,-.32,-.41)},
	-- Hunger: the curse reaches across the face.
	{"Head",CFrame.new(-.2,.48,-.77)*CFrame.Angles(0,0,math.rad(70)),hunger=true},
	{"Head",CFrame.new(.12,-.36,-.77)*CFrame.Angles(0,0,math.rad(-30)),hunger=true},
}
IdentityFX.CURSE_SPREAD=CURSE_SPREAD
local SPREAD_STEP=.09
local function curseSpread(fx,model,actor,st,clock)
	local awake=(actor.awaken or 0)>0 and (actor.health or 1)>0
	if not awake then
		if st.curse then for _,mark in st.curse.marks do mark:Destroy() end;st.curse=nil end
		return
	end
	if not st.curse then
		local marks={}
		for i,spec in CURSE_SPREAD do
			local body=model:FindFirstChild(spec[1])
			if body then
				local mark=K.block(model,Vector3.new(.12,.34,.04),body.CFrame*spec[2],CURSE_INK,Enum.Material.SmoothPlastic)
				mark.Name="CurseSpread";mark.Anchored=false;mark.Massless=true;mark.Transparency=1
				K.new("WeldConstraint",{Part0=body,Part1=mark},mark)
				marks[i]=mark
			end
		end
		st.curse={marks=marks,born=clock}
	end
	local hungry=actor.curseHunger==true
	local pulse=math.sin(clock*18)>0
	for i,mark in st.curse.marks do
		local spec=CURSE_SPREAD[i]
		local shown=clock-st.curse.born>=(i-1)*SPREAD_STEP and (not spec.hunger or hungry)
		mark.Transparency=if shown then 0 else 1
		mark.Material=if hungry and pulse then Enum.Material.Neon else Enum.Material.SmoothPlastic
		mark.Color=if hungry and pulse then CURSE else CURSE_INK
	end
end
-- Shadow of the Dancing Leaf: a dark shadow chain glued under the rising body
-- while he follows it up (the heavy up there is the Lion Combo); the vault kick
-- draws its arc over the opponent.
local function shadowLeaf(fx,model,actor,st,clock)
	if actor.state=="Pursuit" and (actor.lion or 0)>0 then
		if clock-(st.shadowAt or -1)>=.07 then st.shadowAt=clock;fx:ghost(model,SHADOW,.3,.45) end
	end
	local aura=fx.auras and fx.auras[model]
	if aura and aura.trail and actor.attackName=="VaultKick" and (actor.state=="Startup" or actor.state=="Active") then aura.trail.Enabled=true end
end
-- Chidori: a thrust that lands bursts in lightning along its line; one that
-- finds nothing fizzles out in front of him (the opening is his).
local function chidoriCue(fx,data,folder)
	local at=data.position
	local striker=rootOf(find(folder,data.owner))
	if striker then streak(fx,striker.Position,at,CHIDORI,.3,.22,"ChidoriLine") end
	for k=1,4 do
		local a=k*math.pi/2+math.random()*.6
		fx:bolt(at,at+Vector3.new(math.cos(a)*3.2,(math.random()-.3)*2.4,math.sin(a)*3.2),CHIDORI_CORE)
	end
	K.flash(fx.folder,at,CHIDORI_CORE,1,7,.2,0)
	K.shockRing(fx.folder,at,CHIDORI,2,12,.26,data.direction)
end
local function chidoriFizzle(fx,data)
	local holder=K.new("Model",{Name="ChidoriFizzle"},fx.folder)
	K.burst(holder,data.position,{Texture=K.TEX.spark,Lifetime=NumberRange.new(.2,.5),Speed=NumberRange.new(2,6),SpreadAngle=Vector2.new(60,60),
		Color=ColorSequence.new(CHIDORI),LightEmission=1,Size=K.num({{0,.5},{1,0}}),Acceleration=Vector3.new(0,-40,0),Drag=2},18)
	K.flash(holder,data.position,Color3.fromRGB(120,140,170),.4,2.2,.25,.4)
	K.sound(K.anchorPart(fx.folder,data.position),K.SOUND.whoosh,.3,.5)
	Debris:AddItem(holder,.6)
end
-- The steel hidden in the Phoenix Flower glints once as it leaves the flames.
local function hiddenGlint(fx,data)
	fx.identityGlints=fx.identityGlints or {}
	local now=fx:visualTime()
	for _,p in data.projectiles or {} do
		local entry=fx.projectiles[p.id]
		if p.hidden and entry and not fx.identityGlints[p.id] and now-p.born>=.1 then
			fx.identityGlints[p.id]=true
			local at=entry.root.Position
			local glint=K.new("Model",{Name="HiddenGlint"},fx.folder)
			for _,roll in {0,math.pi/2} do
				local ray=K.block(glint,Vector3.new(.06,1.6,.06),CFrame.new(at)*CFrame.Angles(0,0,roll+math.pi/4),Color3.fromRGB(255,255,255),Enum.Material.Neon)
				fade(ray,.18,1.6)
			end
			K.flash(glint,at,Color3.fromRGB(255,250,236),.2,1.4,.12,0)
			K.sound(K.anchorPart(fx.folder,at),K.SOUND.whoosh,.25,2.4)
			Debris:AddItem(glint,.25)
		end
	end
end
local function sasukeImpact(fx,data,folder)
	if data.move=="ChidoriThrust" then
		if data.style=="whiff" then chidoriFizzle(fx,data) elseif data.style~="block" then chidoriCue(fx,data,folder) end
	end
	return false
end
local function sasukeFrame(fx,model,actor,st,clock)
	if actor.fighterId~="Lion" then return end
	curseSpread(fx,model,actor,st,clock)
	shadowLeaf(fx,model,actor,st,clock)
end

-- ------------------------------------------------------------------ layer
local function impact(fx,data,folder)
	if minatoImpact(fx,data,folder) then return true end
	if itachiImpact(fx,data,folder) then return true end
	if sasukeImpact(fx,data,folder) then return true end
	return nejiImpact(fx,data,folder)
end
local function fighter(fx,model,actor,dt)
	if not model or not actor then return end
	local st=stateOf(fx,model)
	local clock=IdentityFX.clock()
	networkFrame(fx,model,actor,st)
	if actor.fighterId=="Flashstep" or #(actor.seals or {})>0 then minatoFrame(fx,model,actor,st,clock) end
	itachiFrame(fx,model,actor,st,clock)
	sasukeFrame(fx,model,actor,st,clock)
end
local function frame(fx,data,dt,folder)
	laneFrame(fx,data)
	hiddenGlint(fx,data)
end
function IdentityFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Identity",impact=impact,fighter=fighter,frame=frame})
end
IdentityFX.palmPrint=function(fx,at,normal) return palmPrint(fx,at,normal,1,.1,.22) end
return IdentityFX
