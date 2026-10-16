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

-- ------------------------------------------------------------------ layer
local function impact(fx,data,folder)
	return nejiImpact(fx,data,folder)
end
local function fighter(fx,model,actor,dt)
	if not model or not actor then return end
	local st=stateOf(fx,model)
	networkFrame(fx,model,actor,st)
end
function IdentityFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Identity",impact=impact,fighter=fighter})
end
IdentityFX.palmPrint=function(fx,at,normal) return palmPrint(fx,at,normal,1,.1,.22) end
return IdentityFX
