-- Systemic chakra on the client, the player-facing layer (convergence 3,
-- mission §4): what a planted tool is for and how long it lasts, the wire as
-- one readable object (its two ends, the line, the body it holds, its tension
-- and its charge), which projectile won a meeting and why, lightning jumping
-- into metal, the Dragon Flame running the wire, a body locked by lightning or
-- standing in fire, a burning zone's edge, and a look of its own for each
-- infused flight. One layer installed into Effects (like SandFX / LeeFX):
-- Effects keeps the base chakra drawing (sheath, trail, the planted blade,
-- the contact flashes); this layer adds what makes it readable.
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)

local ChakraFX={}
local K -- Effects' helpers, handed over by install()
local FX -- the Effects class: infusion looks (FX.Infusion), models, FX:bolt
ChakraFX.clock=os.clock -- (headless tests drive time)
-- Headless tests turn this on so a drawing error fails the test; in play an
-- error is reported once and never breaks the frame or the contact feed.
ChakraFX.strict=false

local NEON=Enum.Material.Neon
local STEEL=Color3.fromRGB(214,220,230)
local SLACK=Color3.fromRGB(112,116,124)
local EMBER=Color3.fromRGB(255,138,52)
local TICKS=8 -- a planted object's life: eight ticks, one goes out per eighth
local SEGMENTS=6 -- pieces of a held wire's line (it sags as the bind runs out)

local function guard(fn,...)
	if ChakraFX.strict then return fn(...) end
	local ok,err=pcall(fn,...)
	if not ok and not ChakraFX.reported then
		ChakraFX.reported=true
		local report=warn or print
		report("[ChakraFX] "..tostring(err))
	end
	return nil
end
local function stateOf(fx)
	local st=fx.chakraLayer
	if not st then
		st={marks={},holds={},seals={},zones={},sealLife={},zoneLife={},bodies=setmetatable({},{__mode="k"})}
		fx.chakraLayer=st
	end
	return st
end
local function infusion(nature) return FX.Infusion[nature or ""] end
local function natureColor(nature)
	local look=infusion(nature)
	return if look then look.color else STEEL
end
local function lightning() return FX.Infusion.Lightning end
local function actorOf(data,id)
	if data.human and data.human.id==id then return data.human end
	if data.bot and data.bot.id==id then return data.bot end
	return nil
end
-- The owner's colour (his fighter's), so whose object it is reads at a glance.
local function ownerColor(data,id)
	local actor=actorOf(data,id)
	local def=actor and Fighters[actor.fighterId or ""]
	return if def and def.Color then Color3.fromRGB(table.unpack(def.Color)) else STEEL
end
local function find(folder,id) return folder and id and folder:FindFirstChild(id) end
local function piece(parent,name,size,cf,color,transparency,shape)
	local p=K.block(parent,size,cf,color,NEON)
	p.Name=name;p.Transparency=transparency or 0
	if shape then p.Shape=shape end
	return p
end
-- A frame on a surface whose look vector is the normal: offsets in its X/Y
-- lie on the surface, -Z stands off it.
local function surfaceFrame(at,normal)
	local n=if normal and normal.Magnitude>.5 then normal.Unit else Vector3.yAxis
	local ref=if math.abs(n.Y)<.9 then Vector3.yAxis else Vector3.xAxis
	local r=ref:Cross(n).Unit
	return CFrame.fromMatrix(at,r,(-n):Cross(r),-n)
end
-- A short jagged arc between two points: three neon segments that fade.
local function arc(fx,name,from,to,color,width,life)
	local delta=to-from
	if delta.Magnitude<.05 then return end
	local side=delta:Cross(Vector3.yAxis)
	if side.Magnitude<.05 then side=Vector3.xAxis end
	side=side.Unit
	local points={from}
	for k=1,2 do table.insert(points,from+delta*(k/3)+side*(math.random()-.5)*.6+Vector3.new(0,(math.random()-.5)*.6,0)) end
	table.insert(points,to)
	for k=1,#points-1 do
		local a,b=points[k],points[k+1]
		local length=(b-a).Magnitude
		if length>.02 then
			local seg=piece(fx.folder,name,Vector3.new(width,width,length),CFrame.lookAt(a:Lerp(b,.5),b),color,.1)
			K.tween(seg,life,{Transparency=1})
			Debris:AddItem(seg,life+.03)
		end
	end
end
-- Eight ticks round a point, lying on its surface.
local function tickRing(parent,name,frame,radius,color,count)
	local ticks={}
	for i=1,count do
		local cf=frame*CFrame.Angles(0,0,(i-1)/count*math.pi*2)*CFrame.new(0,radius,0)
		table.insert(ticks,piece(parent,name,Vector3.new(radius*.5,.08,.05),cf,color,.3))
	end
	return ticks
end
-- One tick goes out per share of the life gone; the last second blinks.
local function showLife(ticks,fraction,remaining,clock,on)
	local lit=math.clamp(math.ceil(fraction*#ticks-1e-6),0,#ticks)
	local blink=remaining<1 and math.sin(clock*24)<0
	for i,t in ticks do t.Transparency=if i<=lit and not blink then on or .3 else 1 end
end
local function fadeAway(model,time)
	if not model then return end
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then K.tween(d,time,{Transparency=1}) end
	end
	Debris:AddItem(model,time+.05)
end

-- ------------------------------------------------------------------ marks
-- A planted blade's mark. Meanings, as this player sees them: his own blade
-- (walk over it for chakra: a floating diamond), the other fighter's blade
-- (trample it to deny it: a cross), a live charge (a shock trap: a bolt, in
-- the lightning's colour, whoever planted it). Ticks in the owner's colour
-- count its life down. A stretched wire gets a ring at each end (its stake and
-- its blade), and crackles along its length while charged.
local function setGlyph(fx,mark,meaning,color)
	if mark.glyph then mark.glyph:Destroy() end
	local holder=K.new("Model",{Name="MarkGlyph"},mark.model)
	local frame=mark.frame
	mark.meaning=meaning;mark.glyph=holder;mark.glyphParts={}
	if meaning=="pickup" then
		local gem=piece(holder,"MarkPickup",Vector3.one*.32,frame*CFrame.new(0,0,-1.2)*CFrame.Angles(math.rad(45),math.rad(35),0),color,.15)
		table.insert(mark.glyphParts,gem)
	elseif meaning=="deny" then
		for _,angle in {45,-45} do
			table.insert(mark.glyphParts,piece(holder,"MarkDeny",Vector3.new(.75,.09,.06),frame*CFrame.new(0,0,-.9)*CFrame.Angles(0,0,math.rad(angle)),color,.25))
		end
	elseif meaning=="shock" then
		local core=lightning().core
		local zig={Vector3.new(-.16,0,-.7),Vector3.new(.14,0,-1.05),Vector3.new(-.1,0,-1.3),Vector3.new(.16,0,-1.7)}
		for k=1,#zig-1 do
			local a=(frame*CFrame.new(zig[k])).Position
			local b=(frame*CFrame.new(zig[k+1])).Position
			table.insert(mark.glyphParts,piece(holder,"MarkShock",Vector3.new(.09,.09,(b-a).Magnitude),CFrame.lookAt(a:Lerp(b,.5),b),core,.1))
		end
	end
end
local function buildMark(fx,data,p)
	local color=ownerColor(data,p.owner)
	local model=K.new("Model",{Name="ChakraMark"},fx.folder)
	if p.planted=="wire" then
		local tip=p.origin+p.direction*(p.range or 0)
		local mark={model=model,wire=true,color=color,origin=p.origin,tip=tip,frame=surfaceFrame(p.origin,Vector3.yAxis)}
		mark.ticks=tickRing(model,"WireEnd",mark.frame,.8,color,TICKS)
		mark.tipTicks=tickRing(model,"WireEnd",surfaceFrame(tip,Vector3.yAxis),.6,color,TICKS)
		return mark
	end
	local frame=surfaceFrame(p.origin,p.normal)
	local mark={model=model,color=color,frame=frame,born=ChakraFX.clock()}
	mark.ticks=tickRing(model,"LifeTick",frame,1.05,color,TICKS)
	return mark
end
local function stepMarks(fx,st,data,now,clock,dt)
	local live={}
	local viewer=data.human and data.human.id
	for _,p in data.projectiles or {} do
		if p.planted and p.planted~="held" and p.expires and p.origin then
			live[p.id]=true
			local mark=st.marks[p.id]
			if not mark then mark=buildMark(fx,data,p);st.marks[p.id]=mark end
			local charged=(p.charged or 0)>now
			local life=math.max(.05,p.expires-(p.born or now))
			local remaining=math.max(0,p.expires-now)
			showLife(mark.ticks,remaining/life,remaining,clock)
			if mark.wire then
				showLife(mark.tipTicks,remaining/life,remaining,clock)
				-- A live wire crackles along its length (Effects lights the line).
				if charged and clock>=(mark.nextArc or 0) then
					mark.nextArc=clock+.07
					local at=mark.origin:Lerp(mark.tip,math.random())
					local side=(mark.tip-mark.origin):Cross(Vector3.yAxis)
					side=if side.Magnitude>.05 then side.Unit*.45 else Vector3.xAxis*.45
					arc(fx,"WireCrackle",at-side,at+side+Vector3.new(0,.4,0),lightning().core,.06,.08)
				end
			else
				local meaning=if charged or p.mark=="shock" then "shock" elseif p.owner==viewer then "pickup" else "deny"
				if meaning~=mark.meaning then setGlyph(fx,mark,meaning,mark.color) end
				local t=clock-mark.born
				if meaning=="pickup" then
					-- His chakra waiting for him: the diamond bobs and turns.
					local gem=mark.glyphParts[1]
					if gem then gem.CFrame=mark.frame*CFrame.new(0,0,-1.2-math.sin(t*3)*.15)*CFrame.Angles(math.rad(45),t*2,0) end
				elseif meaning=="shock" then
					for _,part in mark.glyphParts do part.Transparency=if math.random()<.3 then .6 else .05 end
					if clock>=(mark.nextArc or 0) then
						mark.nextArc=clock+.12
						local a=(mark.frame*CFrame.Angles(0,0,math.random()*math.pi*2)*CFrame.new(0,1.05,0)).Position
						arc(fx,"MarkArc",a,mark.frame.Position,lightning().core,.05,.08)
					end
				end
			end
		end
	end
	for id,mark in st.marks do
		if not live[id] then fadeAway(mark.model,.15);st.marks[id]=nil end
	end
end

-- ------------------------------------------------------------------ the held wire
-- A wire holding a body (row planted "held"): from the thrower's hand (or the
-- stake of the stretched wire that caught it, then on to its blade) to the
-- body. Taut while the bind is fresh, it sags and dims as the bind runs out
-- (a current tightens it again); charged, it turns to lightning and crackles.
local function buildHold(fx,p)
	local model=K.new("Model",{Name="HeldWire"},fx.folder)
	local hold={model=model,segments={}}
	for k=1,(if p.anchored then SEGMENTS*2 else SEGMENTS) do
		table.insert(hold.segments,piece(model,"HeldWireSegment",Vector3.new(.07,.07,.5),CFrame.new(p.origin),STEEL,0))
	end
	hold.knot=piece(model,"HeldWireEnd",Vector3.one*.3,CFrame.new(p.origin),STEEL,.2,Enum.PartType.Ball)
	if p.anchored then
		-- Still tied to its stake and its blade: the body pulled the line into a V.
		local stake=FX.buildKunai(false);stake.Name="WireStake";stake.Parent=model
		stake:PivotTo(CFrame.lookAt(p.origin+Vector3.new(0,.35,0),p.origin-Vector3.new(0,1,0)))
		local tip=p.origin+p.direction*(p.range or 0)
		local blade=FX.buildShuriken();blade.Name="WireBlade";blade.Parent=model
		blade:PivotTo(CFrame.lookAt(tip,tip+p.direction)*CFrame.Angles(math.rad(80),0,0))
	end
	return hold
end
local function curve(segments,first,last,from,to,sag,color,width,transparency)
	local count=last-first+1
	for k=first,last do
		local u0,u1=(k-first)/count,(k-first+1)/count
		local a=from:Lerp(to,u0)-Vector3.new(0,sag*4*u0*(1-u0),0)
		local b=from:Lerp(to,u1)-Vector3.new(0,sag*4*u1*(1-u1),0)
		local seg=segments[k]
		local length=(b-a).Magnitude
		if length>.02 then
			seg.Size=Vector3.new(width,width,length)
			seg.CFrame=CFrame.lookAt(a:Lerp(b,.5),b)
		end
		seg.Color=color;seg.Transparency=transparency
	end
end
local function stepHolds(fx,st,data,now,clock,folder)
	local live={}
	for _,p in data.projectiles or {} do
		if p.planted=="held" and p.origin then
			live[p.id]=true
			local hold=st.holds[p.id]
			if not hold then hold=buildHold(fx,p);st.holds[p.id]=hold end
			local victim=find(folder,p.holds)
			local chest=victim and (victim:FindFirstChild("UpperTorso") or victim:FindFirstChild("HumanoidRootPart"))
			local tip=p.origin+p.direction*(p.range or 0)
			local body=if chest then chest.Position elseif p.anchored then p.origin:Lerp(tip,.5) else tip
			local start=p.origin
			if not p.anchored then
				local owner=find(folder,p.owner)
				local hand=owner and owner:FindFirstChild("RightHand")
				if hand then start=hand.Position end
			end
			-- Tension: the share of the bind still to come (its life is the bind).
			local total=math.max(.05,(p.expires or now)-(p.born or now))
			local tension=math.clamp(((p.expires or now)-now)/total,0,1)
			local charged=(p.charged or 0)>now
			local color=if charged then lightning().core else SLACK:Lerp(STEEL,tension)
			local width=if charged then .1+math.random()*.06 else .05+.03*tension
			local transparency=if charged then 0 else .1+(1-tension)*.35
			local slack=(1-tension)*.12
			curve(hold.segments,1,SEGMENTS,start,body,(start-body).Magnitude*slack,color,width,transparency)
			if p.anchored then curve(hold.segments,SEGMENTS+1,SEGMENTS*2,body,tip,(body-tip).Magnitude*slack,color,width,transparency) end
			hold.knot.CFrame=CFrame.new(start);hold.knot.Color=ownerColor(data,p.owner)
			if charged and clock>=(hold.nextArc or 0) then
				hold.nextArc=clock+.05
				local at=start:Lerp(body,math.random())
				arc(fx,"WireCurrent",at,at+Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5),lightning().core,.05,.07)
			end
		end
	end
	for id,hold in st.holds do
		if not live[id] then fadeAway(hold.model,.12);st.holds[id]=nil end
	end
end

-- ------------------------------------------------------------------ seals and zones
-- Minato's planted seal kunai: ticks round the seal in his colour count its
-- life down (the seal's own glyph is Effects'). A burning zone: ember ticks
-- on its exact edge, going out as it burns down.
local function stepSeals(fx,st,data,now,clock)
	local live={}
	for _,key in {"human","bot"} do
		local actor=data[key]
		for _,info in (actor and actor.seals) or {} do
			if info.surface and not info.body then
				local id=tostring(actor.id)..":"..tostring(info.id)
				live[id]=true
				local ring=st.seals[id]
				if not ring then
					local model=K.new("Model",{Name="SealLife"},fx.folder)
					ring={model=model,ticks=tickRing(model,"SealTick",surfaceFrame(info.surface,info.normal),2.1,ownerColor(data,actor.id),TICKS)}
					st.seals[id]=ring
				end
				-- The full life is the longest remaining time seen for this seal.
				st.sealLife[id]=math.max(st.sealLife[id] or 0,info.remaining or 0)
				showLife(ring.ticks,(info.remaining or 0)/math.max(.05,st.sealLife[id]),info.remaining or 0,clock)
			end
		end
	end
	for id,ring in st.seals do
		if not live[id] then fadeAway(ring.model,.15);st.seals[id]=nil;st.sealLife[id]=nil end
	end
end
local function stepZones(fx,st,data,clock)
	local live={}
	for _,h in data.hazards or {} do
		if h.kind=="Fire" and h.position then
			local key=string.format("%.1f:%.1f:%.1f",h.position.X,h.position.Y,h.position.Z)
			live[key]=true
			local zone=st.zones[key]
			if not zone then
				local ok,floor=pcall(K.floorUnder,fx,h.position,3,14)
				local at=if ok and floor then floor.Position+Vector3.new(0,.06,0) else h.position
				local model=K.new("Model",{Name="BurnZone"},fx.folder)
				zone={model=model,ticks=tickRing(model,"BurnEdge",surfaceFrame(at,Vector3.yAxis),h.radius,EMBER,12)}
				st.zones[key]=zone
			end
			st.zoneLife[key]=math.max(st.zoneLife[key] or 0,h.remaining or 0)
			showLife(zone.ticks,(h.remaining or 0)/math.max(.05,st.zoneLife[key]),h.remaining or 0,clock,.5)
		end
	end
	for key,zone in st.zones do
		if not live[key] then fadeAway(zone.model,.2);st.zones[key]=nil;st.zoneLife[key]=nil end
	end
end

-- ------------------------------------------------------------------ flights
-- Each infused flight reads apart from the plain throw: the wind kunai grows
-- two thin edges of cutting air past its point, reinforced steel a dense
-- outer shell, a lightning blade throws small arcs behind it (Effects adds
-- the sheath, the trail and the flames).
local function decorate(fx,entry)
	entry.chakraLook=true
	local nature=entry.data.infusion
	local kind=entry.data.kind
	local root=entry.root
	local made={}
	local blade=kind=="kunai" or kind=="marked"
	if nature=="Wind" and blade then
		local core=infusion("Wind").core
		for _,side in {-1,1} do
			table.insert(made,piece(entry.model,"WindEdge",Vector3.new(.03,.12,1.5),root.CFrame*CFrame.new(side*.17,0,-.75)*CFrame.Angles(0,side*math.rad(7),0),core,.35))
		end
	elseif nature=="Reinforce" and (blade or kind=="shuriken") then
		-- A sleeve round a kunai, a disc round a shuriken (Gaara's sand keeps its own look).
		local shell=if blade then piece(entry.model,"SteelWeight",Vector3.new(1.6,.52,.52),root.CFrame*CFrame.new(0,0,-.2)*CFrame.Angles(0,math.pi/2,0),infusion("Reinforce").color,.78)
			else piece(entry.model,"SteelWeight",Vector3.new(.26,1.45,1.45),root.CFrame*CFrame.Angles(0,0,math.pi/2),infusion("Reinforce").color,.8)
		shell.Shape=Enum.PartType.Cylinder
		table.insert(made,shell)
	end
	if #made>0 then
		K.weldAll(root,made)
		for _,part in made do part.LocalTransparencyModifier=if entry.hidden then 1 else 0 end
	end
end
local function stepFlights(fx,clock)
	for _,entry in fx.projectiles do
		local p=entry.data
		if not entry.static and p and p.infusion and entry.root and entry.model then
			if not entry.chakraLook then decorate(fx,entry) end
			if p.infusion=="Lightning" and not entry.hidden and clock>=(entry.nextArc or 0) then
				entry.nextArc=clock+.05
				local back=entry.root.CFrame.LookVector*-1.4
				local at=entry.root.Position
				arc(fx,"FlightArc",at,at+back+Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*.6,lightning().core,.05,.06)
			end
		end
	end
end

-- ------------------------------------------------------------------ contacts
-- Who won a meeting, and why (ChakraCombat sends it with the loser's impact):
-- the winner flashes in its nature's colour where it flies on; a nature
-- advantage shows the winning colour closing over the losing one; a cut blade
-- falls in two halves; weight shows as a short hard ring.
local function halves(fx,impact)
	local at=impact.position
	local across=(impact.direction or Vector3.zAxis):Cross(Vector3.yAxis)
	across=if across.Magnitude>.05 then across.Unit else Vector3.xAxis
	for _,side in {-1,1} do
		local half=K.block(fx.folder,Vector3.new(.1,.08,.42),CFrame.lookAt(at,at+across*side),Color3.fromRGB(150,158,170),Enum.Material.Metal)
		half.Name="CutHalf"
		K.tween(half,.4,{CFrame=CFrame.new(at+across*side*1.6+Vector3.new(0,-1.8,0))*CFrame.Angles(math.random()*6,math.random()*6,0),Transparency=1})
		Debris:AddItem(half,.45)
	end
end
local function explain(fx,impact)
	local at=impact.position
	local color=natureColor(impact.winnerNature)
	local entry=impact.winner and fx.projectiles[impact.winner]
	if entry and entry.root and entry.model then
		local glow=piece(entry.model,"WinnerFlash",Vector3.one*1.1,entry.root.CFrame,color,.15,Enum.PartType.Ball)
		K.weldAll(entry.root,{glow})
		K.tween(glow,.24,{Size=Vector3.one*2.6,Transparency=1})
		Debris:AddItem(glow,.3)
	elseif impact.winner then
		-- Not drawn yet on this client: the flash where it won.
		local glow=piece(fx.folder,"WinnerFlash",Vector3.one*1.1,CFrame.new(at),color,.15,Enum.PartType.Ball)
		K.tween(glow,.2,{Size=Vector3.one*2.6,Transparency=1})
		Debris:AddItem(glow,.25)
	end
	local reason=impact.reason
	if reason=="nature" then
		K.shockRing(fx.folder,at,color,1,8,.26,impact.direction)
		local lost=piece(fx.folder,"NatureVersus",Vector3.one*1.4,CFrame.new(at),natureColor(impact.loserNature),.1,Enum.PartType.Ball)
		K.tween(lost,.22,{Size=Vector3.one*.1,Transparency=1})
		Debris:AddItem(lost,.26)
	elseif reason=="cut" then
		halves(fx,impact)
	elseif reason=="weight" or reason=="steel" then
		K.shockRing(fx.folder,at,color,.6,4,.16,impact.direction)
	end
end
-- Lightning jumping into metal (ChakraCombat charge / spread).
local function arcInto(fx,impact)
	local from,to=impact.from or impact.position,impact.to or impact.position
	if (to-from).Magnitude>.1 then FX.bolt(fx,from,to,lightning().core) end
	local spark=piece(fx.folder,"ArcFlash",Vector3.one*.5,CFrame.new(to),lightning().color,.1,Enum.PartType.Ball)
	K.tween(spark,.16,{Size=Vector3.one*2.2,Transparency=1})
	Debris:AddItem(spark,.2)
end
-- The Dragon Flame runs the wire from the hand (or its stake) to the body;
-- Effects draws the blast on the body.
local function dragonFlame(fx,impact)
	local from,to=impact.from or impact.position,impact.to or impact.position
	local length=(to-from).Magnitude
	if length<.1 then return end
	local line=piece(fx.folder,"DragonFlameRun",Vector3.new(.35,.35,length),CFrame.lookAt(from:Lerp(to,.5),to),EMBER,.15)
	K.tween(line,.35,{Size=Vector3.new(.05,.05,length),Transparency=1})
	Debris:AddItem(line,.4)
	local fire=infusion("Fire")
	for k=0,5 do
		local at=from:Lerp(to,k/5)
		task.delay(k*.025,function()
			if not fx.folder.Parent then return end
			K.burst(fx.folder,at,{Texture=K.TEX.fire,Lifetime=NumberRange.new(.18,.32),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(180,180),
				Color=K.seq({{0,fire.core},{.5,fire.color},{1,Color3.fromRGB(90,24,10)}}),LightEmission=1,Size=K.num({{0,1.6},{1,.4}}),
				Transparency=K.num({{0,.15},{1,1}})},6)
		end)
	end
end
local function drawImpact(fx,impact)
	if impact.reason then explain(fx,impact) end
	local kind=impact.chakra
	if kind=="arc" then arcInto(fx,impact)
	elseif kind=="dragonflame" then dragonFlame(fx,impact) end
end
local function impact(fx,data,_folder)
	if data.chakra or data.reason then guard(drawImpact,fx,data) end
	return false -- Effects still draws its own part of the contact
end

-- ------------------------------------------------------------------ bodies
-- Locked by lightning (snapshot `shocked`: exactly the lengthened stun or the
-- bind the current extended): arcs crawl over the body. Standing in fire
-- (`burning`: while burn ticks land): small flames at the legs. Restrained:
-- one light and a few arcs, a handful of flames.
local function body(fx,model,actor)
	local st=stateOf(fx)
	local b=st.bodies[model]
	if not b then b={};st.bodies[model]=b end
	local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
	if not torso then return end
	local clock=ChakraFX.clock()
	local alive=(actor.health or 1)>0
	if alive and (actor.shocked or 0)>0 then
		if not (b.shock and b.shock.Parent) then
			b.shock=K.new("PointLight",{Name="ShockLight",Color=lightning().color,Brightness=2,Range=8,Shadows=false},torso)
		end
		b.shock.Brightness=1+math.random()*2.5
		if clock>=(b.nextArc or 0) then
			b.nextArc=clock+.06
			local center=torso.Position
			local offset=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*2.4
			arc(fx,"ShockArc",center+offset,center-offset*.6,lightning().core,.06,.08)
		end
	elseif b.shock then
		b.shock:Destroy();b.shock=nil
	end
	local feet=model:FindFirstChild("LowerTorso") or torso
	if alive and (actor.burning or 0)>0 then
		if not (b.burn and b.burn.Parent) then
			local at=K.new("Attachment",{Name="BurnFlames",Position=Vector3.new(0,-.7,0)},feet)
			local fire=infusion("Fire")
			K.new("ParticleEmitter",{Texture=K.TEX.fire,Rate=16,Lifetime=NumberRange.new(.2,.4),Speed=NumberRange.new(2,4),SpreadAngle=Vector2.new(25,25),
				EmissionDirection=Enum.NormalId.Top,Color=K.seq({{0,fire.core},{.6,fire.color},{1,Color3.fromRGB(90,24,10)}}),LightEmission=1,LightInfluence=0,
				Size=K.num({{0,.9},{1,.2}}),Transparency=K.num({{0,.25},{1,1}})},at)
			K.new("PointLight",{Color=fire.color,Brightness=1.4,Range=7,Shadows=false},at)
			b.burn=at
		end
	elseif b.burn then
		b.burn:Destroy();b.burn=nil
	end
end
local function fighter(fx,model,actor,_dt)
	if not model or not actor then return end
	guard(body,fx,model,actor)
end

-- ------------------------------------------------------------------ per frame
local function clear(st)
	for _,list in {st.marks,st.holds,st.seals,st.zones} do
		for key,entry in list do
			if entry.model then entry.model:Destroy() end
			list[key]=nil
		end
	end
	table.clear(st.sealLife);table.clear(st.zoneLife)
	for model,b in st.bodies do
		if b.shock then b.shock:Destroy() end
		if b.burn then b.burn:Destroy() end
		st.bodies[model]=nil
	end
end
local function frame(fx,data,dt,folder)
	local st=stateOf(fx)
	if not data or data.phase~="Duel" then clear(st);st.epoch=nil;return end
	if st.epoch~=data.epoch then clear(st);st.epoch=data.epoch end
	local now=workspace:GetServerTimeNow()
	local clock=ChakraFX.clock()
	stepMarks(fx,st,data,now,clock,dt)
	stepHolds(fx,st,data,now,clock,folder)
	stepSeals(fx,st,data,now,clock)
	stepZones(fx,st,data,clock)
	stepFlights(fx,clock)
end
local function step(fx,data,dt,folder)
	guard(frame,fx,data,dt,folder)
end

function ChakraFX.install(EffectsFX,kit)
	K=kit;FX=EffectsFX
	table.insert(FX.layers,{name="Chakra",impact=impact,fighter=fighter,step=step})
end
return ChakraFX
