-- ChakraCombat: the runtime adapter between the real duel (projectiles,
-- bodies, guards, wire) and the declarative rules Codex prepared
-- (ChakraRules + ChakraInputPlan) over the live ChakraTuning data.
--
--   OBJECT / BODY ACTION + CHAKRA + NATURE / MASTERY + CONTEXT = MODIFIED ACTION
--
-- Server-only. The client sends one validated boolean (the chakra modifier was
-- held with the tool action); the fighter's mastery profile, the object, the
-- cost, the context and every consequence are decided here from server state.
-- The rules select named signals; the handlers below are the only code that
-- turns a signal into a gameplay change, each one bounded and explicit.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Rules=require(script.Parent.ChakraRules)
local InputPlan=require(script.Parent.ChakraInputPlan)
local T=require(script.Parent.ChakraTuning)
local Brawler=require(script.Parent.Brawler)
local Motor=require(script.Parent.Motor)
assert(Rules.validate(T),"Invalid chakra tuning")
local E=T.Effects
local Chakra={Tuning=T}
local NATURE_TAGS={"fire","wind","lightning","earth"}
local NATURE_OF={}
for name,nature in T.Natures do NATURE_OF[nature.tag]=name end
local LABEL={Reinforce="CHAKRA",Wind="WIND",Fire="KATON",Lightning="RAITON",GentleFist="GENTLE FIST"}

local function set(list,into)
	into=into or {}
	for _,tag in list or {} do into[tag]=true end
	return into
end
local function copy(t)
	local out={}
	for k,v in t do out[k]=v end
	return out
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function natureOf(tags)
	for _,tag in NATURE_TAGS do if tags[tag] then return NATURE_OF[tag] end end
	return nil
end
local function beats(a,b) return a~=nil and b~=nil and T.Beats[a]==b end
local function closest(a,b,point)
	local ab=b-a
	local length=ab:Dot(ab)
	if length<1e-6 then return a end
	return a+ab*math.clamp((point-a):Dot(ab)/length,0,1)
end
-- Closest points of two segments [p1,q1] and [p2,q2] (s, t in 0..1).
local function segments(p1,q1,p2,q2)
	local d1,d2,r=q1-p1,q2-p2,p1-p2
	local a,e,f=d1:Dot(d1),d2:Dot(d2),d2:Dot(r)
	local s,t
	if a<1e-8 and e<1e-8 then return p1,p2,0,0 end
	if a<1e-8 then s=0;t=math.clamp(f/e,0,1)
	else
		local c=d1:Dot(r)
		if e<1e-8 then t=0;s=math.clamp(-c/a,0,1)
		else
			local b=d1:Dot(d2)
			local denom=a*e-b*b
			s=if denom>1e-8 then math.clamp((b*f-c*e)/denom,0,1) else 0
			t=(b*s+f)/e
			if t<0 then t=0;s=math.clamp(-c/a,0,1) elseif t>1 then t=1;s=math.clamp((b-c)/a,0,1) end
		end
	end
	return p1+d1*s,p2+d2*t,s,t
end
-- Earliest time in [0,horizon] at which two moving spheres touch.
local function meet(p0,v0,q0,v1,horizon,radius)
	local d=p0-q0
	local r=v0-v1
	local c0=d:Dot(d)-radius*radius
	if c0<=0 then return 0 end
	local aa=r:Dot(r)
	if aa<1e-8 then return nil end
	local bb=2*d:Dot(r)
	local disc=bb*bb-4*aa*c0
	if disc<0 then return nil end
	local t=(-bb-math.sqrt(disc))/(2*aa)
	if t>=0 and t<=horizon then return t end
	return nil
end
local function ground(c,position)
	local hit=workspace:Raycast(position+Vector3.new(0,1,0),Vector3.new(0,-80,0),c:rayParams(true))
	return if hit then hit.Position else Vector3.new(position.X,c.match.origin.Y,position.Z)
end

-- ------------------------------------------------------------- profiles
-- A character id only selects a mastery profile; the interpreter is shared.
function Chakra.profile(a)
	local id=T.CharacterMastery[a.fighterId] or "Basic"
	return id,T.Masteries[id] or T.Masteries.Basic
end
local function masteryOf(a)
	local _,m=Chakra.profile(a)
	return {tags=set(m.tags),levels=m.levels}
end
-- Studio A/B switch (devtools): changes the next triggers only.
function Chakra.toggle(c,ruleId,enabled)
	assert(type(enabled)=="boolean","Boolean switch required")
	local found=false
	for _,r in T.Rules do found=found or r.id==ruleId end
	assert(found,"Unknown chakra rule: "..tostring(ruleId))
	c.chakraSwitches=c.chakraSwitches or {}
	c.chakraSwitches[ruleId]=enabled
end
local function plan(c,trigger,event)
	event.trigger=trigger
	event.context=event.context or {tags={}}
	local selected=Rules.plan(T,event,c.chakraSwitches or {})
	local signals,applied={},{}
	for _,r in selected do
		table.insert(applied,r.id)
		for _,e in r.effects do if e.kind=="signal" then table.insert(signals,e.name) end end
	end
	return selected,signals,applied
end
-- Bounded decision log: which rules fired, for tests and Studio inspection.
local function record(c,trigger,applied,detail)
	if #applied==0 then return end
	c.chakraLog=c.chakraLog or {}
	local row={trigger=trigger,rules=applied,at=c.now}
	for k,v in detail or {} do row[k]=v end
	table.insert(c.chakraLog,row)
	while #c.chakraLog>40 do table.remove(c.chakraLog,1) end
end
Chakra.record=record

-- ------------------------------------------------------------- infusion
local function resolve(c,a,objectId,infusionId,innate)
	local def=T.Objects[objectId]
	local infusion=T.Infusions[infusionId]
	local tags=set(def.tags)
	local stats=copy(def.stats)
	if innate then
		-- Carried by a jutsu (blades hidden in fire): the nature only, no
		-- reinforcement, no cost, no stat change.
		if infusion.nature then tags[T.Natures[infusion.nature].tag]=true end
		return {object=objectId,infusion=infusionId,nature=infusion.nature,tags=tags,stats=stats,cost=0,mode="throw",innate=true,rules={},signals={}}
	end
	set(infusion.tags,tags)
	if infusion.nature then tags[T.Natures[infusion.nature].tag]=true end
	-- Context comes from server state only.
	local context={}
	local victim=a.wireVictim
	if victim and victim.reaction=="Bound" and victim.boundBy==a and victim.health>0 and (victim.wireConducts or 0)<E.conduct.uses then
		context.holdingWire=true
	end
	local mastery=masteryOf(a)
	local selected,signals,applied=plan(c,"Infuse",{source={tags=tags,toolType=def.toolType},context={tags=context},mastery=mastery})
	local cost=infusion.cost
	for _,r in selected do
		cost+=r.cost or 0
		for _,e in r.effects do
			if e.kind=="scaleStat" and stats[e.stat]~=nil then
				-- Codex's semantics: factor + per-level mastery bonus, bounded by
				-- maxFactor, the result bounded by the object's cap.
				local factor=e.factor+(e.perLevel or 0)*(if e.mastery then mastery.levels[e.mastery] or 0 else 0)
				factor=math.min(e.maxFactor or 4,factor)
				stats[e.stat]=math.min(def.caps[e.stat] or math.huge,stats[e.stat]*factor)
			elseif e.kind=="tag" then tags[e.tag]=true end
		end
	end
	local mode="throw"
	if table.find(signals,"conduct-wire") then mode="conduct" elseif table.find(signals,"chakra-palm") then mode="body" end
	return {object=objectId,infusion=infusionId,nature=infusion.nature,tags=tags,stats=stats,cost=cost,mode=mode,rules=applied,signals=signals}
end
-- The chakra modifier on the tool action. `object` is the tool the fighter's
-- action uses ("Kunai", "Shuriken", "Sand"); a body mastery replaces it with
-- the palm. Codex's input planner (Modifier mode) keeps the existing action
-- and refuses an incompatible proposal. Returns the plan, or nil + refusal.
function Chakra.plan(c,a,object)
	local profileId=Chakra.profile(a)
	local objectId=T.BodyTool[profileId] or object
	if not T.Objects[objectId] then return nil,"No chakra tool" end
	local preferred=(T.Preferred[profileId] or {})[objectId] or T.Preferred.Basic[objectId]
	local input=InputPlan.build(T,"Modifier",{action="Tool",modified=true},{tool=objectId,selectedInfusion=preferred})
	if input.infusion=="None" then return nil,"No chakra tool" end
	local result=resolve(c,a,objectId,input.infusion,false)
	result.profile=profileId;result.owner=a.id
	-- The palm is a grounded twin-palm thrust: refused in the air, before any cost.
	if result.mode=="body" and a.airborne then return nil,"Palm needs the ground" end
	return result
end
-- A nature carried by a jutsu (no input, no cost).
function Chakra.innate(c,a,object,infusionId)
	if not T.Objects[object] or not T.Infusions[infusionId] then return nil end
	return resolve(c,a,object,infusionId,true)
end
-- Chakra spent: a thrown chakra tool also pays the plain throw cost, which a
-- string cancel waives; a palm or a current down the wire throws nothing.
function Chakra.cost(p,chainCancel)
	return p.cost+(if p.mode=="throw" and E.toolCost and not chainCancel then Config.ToolCost else 0)
end
function Chakra.label(p)
	return (LABEL[p.infusion] or "CHAKRA").." "..string.upper(p.object)
end
-- Refused (chakra short, or nothing to infuse): the chakra fizzles at the
-- hand, so the refusal is seen even when the HUD cue stays quiet.
function Chakra.refuse(c,a)
	local hand=a.root.Position+a.root.CFrame.RightVector*1.1+a.root.CFrame.LookVector*1.1+Vector3.new(0,.9,0)
	c:pushImpact(hand,"fade",false,{owner=a.id,chakra="fizzle"})
	Brawler.event(c,a,"ChakraRefused")
end
-- The infusion is logged once, when the chakra is actually committed (a plan
-- refused for cost leaves no trace).
local function committed(c,infused)
	if infused.logged or infused.innate then return end
	infused.logged=true
	record(c,"Infuse",infused.rules,{owner=infused.owner,object=infused.object,infusion=infused.infusion,mode=infused.mode})
end
-- A projectile thrown with a plan carries it for its whole life.
function Chakra.arm(c,p,infused)
	committed(c,infused)
	local s=infused.stats
	p.chakra=infused;p.infusion=infused.infusion;p.tags=infused.tags
	if not infused.innate then
		p.speed*=s.speed or 1;p.range*=s.range or 1;p.remaining=p.range;p.damage*=s.damage or 1
		-- Stronger contact: the chakra blade connects through a small sphere.
		p.radius=math.max(p.radius or 0,E.hitRadius)
	end
	p.weight=s.weight or 1;p.impact=s.impact or 1
	p.contest=(T.Objects[infused.object].radius or .45)+(if infused.innate then 0 else E.contestBonus)
end

-- A blade born from an infused one (a ricochet) carries the same chakra,
-- without scaling its flight a second time.
function Chakra.inherit(q,p)
	if not p.chakra then return end
	q.chakra=p.chakra;q.infusion=p.infusion;q.tags=p.tags;q.weight=p.weight;q.impact=p.impact;q.contest=p.contest;q.flared=p.flared
	q.radius=math.max(q.radius or 0,p.radius or 0)
end

-- ------------------------------------------------------------- views
-- The interaction view of any live projectile: tags, weight and the radius at
-- which it meets another object. Plain tools and jutsu volumes come straight
-- from their object data (a plain throw itself is never changed).
local function view(c,p)
	if p.chakra then
		local def=T.Objects[p.chakra.object]
		return {tags=p.tags,weight=p.weight or 1,contest=p.contest or .5,volume=false,nature=natureOf(p.tags),toolType=def.toolType}
	end
	local id=T.ObjectOf[p.kind]
	local def=id and T.Objects[id]
	if not def then return nil end
	local tags=set(def.tags)
	-- A shuriken that crossed its thrower's burning ground (Fire Geometry) burns.
	if p.ignited then tags.fire=true end
	local volume=tags.volume==true
	local contest=if volume then (p.radius or 0)+(p.growth or 0)*math.max(0,c.now-p.born) else def.radius
	return {tags=tags,weight=def.stats.weight or 1,contest=math.max(contest,.3),volume=volume,nature=natureOf(tags),toolType=def.toolType}
end
Chakra.view=view
local function moving(p)
	return not p.dead and not p.planted and (p.speed or 0)>0 and (p.remaining or 0)>0
end
local function kill(c,p,position,style,extra)
	if p.dead then return end
	p.dead=true
	local entry={projectile=p.id,kind=p.kind,owner=p.a.id,direction=p.direction}
	for k,v in extra or {} do entry[k]=v end
	c:pushImpact(position,style,false,entry)
end

-- ------------------------------------------------------------- clashes
-- Which side leads a meeting: elemental precedence, then a reinforced blade
-- heavier than a small flame, then the jutsu volume, then weight, then age.
local function dominant(p,q,vp,vq)
	if vp.volume and vq.volume then
		if p.id<=q.id then return p,q,vp,vq end
		return q,p,vq,vp
	end
	if vp.volume~=vq.volume then
		local vol,tool,vv,vt=p,q,vp,vq
		if vq.volume then vol,tool,vv,vt=q,p,vq,vp end
		local steel=vt.tags.reinforced and vt.weight>vv.weight+.25 and not (vv.nature=="Fire" and vt.nature=="Wind")
		if steel then return tool,vol,vt,vv end
		return vol,tool,vv,vt
	end
	if beats(vp.nature,vq.nature) then return p,q,vp,vq end
	if beats(vq.nature,vp.nature) then return q,p,vq,vp end
	if math.abs(vp.weight-vq.weight)>.25 then
		if vp.weight>vq.weight then return p,q,vp,vq end
		return q,p,vq,vp
	end
	if p.id<=q.id then return p,q,vp,vq end
	return q,p,vq,vp
end
local OUTCOME={["clash-pass"]="pass",["clash-absorb"]="absorb",["clash-pierce"]="pierce",["clash-swallow"]="swallow",
	["clash-swat"]="swat",["clash-deflect"]="deflect",["clash-intercept"]="intercept"}
local function tumble(direction,across)
	local side=across:Cross(Vector3.yAxis)
	if side.Magnitude<.05 then side=Vector3.xAxis end
	local away=(direction*.4+side.Unit*(if direction:Dot(side)>=0 then 1 else -1)+Vector3.new(0,.7,0))
	return if away.Magnitude>.05 then away.Unit else Vector3.yAxis
end
local function flare(s)
	if s.chakra or not (s.radius and s.radius>0) then
		s.damage+=E.feed.damage;s.flared=true
	else
		s.radius+=.6;s.damage*=1.15;s.flared=true
	end
end
-- Resolve one meeting. The rules pick one outcome (exclusive group "clash");
-- the dominant side is the rule source.
local function settle(c,s,t,vs,vt,at,forced)
	local ctx={}
	if not (vs.tags.chakra or vs.tags.volume or vt.tags.chakra or vt.tags.volume) then ctx.plain=true end
	if beats(vs.nature,vt.nature) then ctx.natureAdvantage=true end
	local gap=vs.weight-vt.weight
	if gap>.25 then ctx.heavier=true elseif gap>=-.25 then ctx.even=true end
	local _,signals,applied=plan(c,"ProjectileClash",{source={tags=vs.tags,toolType=vs.toolType},target={tags=vt.tags,toolType=vt.toolType},
		context={tags=ctx},mastery=masteryOf(s.a or forced)})
	local outcome="pass"
	for _,name in signals do if OUTCOME[name] then outcome=OUTCOME[name];break end end
	-- A forced source (the palm) is not a projectile: it only ever swats a blade
	-- (switching its rule off leaves the blades alone).
	if forced and outcome~="swat" then outcome="pass" end
	local owner=forced or s.a
	local dir=s.direction or (owner and owner.root.CFrame.LookVector) or Vector3.zAxis
	local infusion=s.infusion
	if outcome=="absorb" then
		kill(c,t,at,"ember",{chakra="absorb",infusion="Fire",by=owner.id})
		if not forced then flare(s) end
	elseif outcome=="pierce" then
		kill(c,t,at,"deflect",{chakra="cut",infusion=infusion,direction=dir,tumble=tumble(t.direction,dir),by=owner.id})
	elseif outcome=="swallow" then
		local fire=vs.tags.fire==true
		kill(c,t,at,if fire then "ember" else "deflect",{chakra=if fire then "burn" else "blown",infusion=infusion,direction=dir,tumble=tumble(t.direction,dir),by=owner.id})
	elseif outcome=="swat" then
		kill(c,t,at,"deflect",{chakra="swat",infusion="GentleFist",direction=dir,tumble=tumble(t.direction,dir),by=owner.id})
	elseif outcome=="deflect" then
		kill(c,t,at,"deflect",{chakra="deflect",infusion=infusion,direction=dir,tumble=tumble(t.direction,dir),by=owner.id})
	elseif outcome=="intercept" then
		t.dead=true
		kill(c,s,at,"clash",{chakra="intercept",other=t.id,otherKind=t.kind,direction=dir,tumble=tumble(s.direction,t.direction),by=owner.id})
	end
	if outcome~="pass" then
		Brawler.event(c,owner,"ChakraClash")
		Brawler.event(c,owner,"Clash_"..outcome)
		-- Wind Cut's lane (Techniques.cutLane) and this clash rule are one
		-- behaviour: whichever meets the blade first, the gust cut it.
		if s.kind=="wind" and t.kind~="wind" and outcome~="intercept" then Brawler.event(c,owner,"WindCutBlade") end
	end
	record(c,"ProjectileClash",applied,{outcome=outcome,source=s.kind,target=t.kind,sourceInfusion=s.infusion,targetInfusion=t.infusion})
	return outcome
end
-- Neji's chakra palm: for its startup and active frames, the blades in front of
-- it are swatted aside (a frontal answer, unlike the 360-degree Rotation).
local function swat(c,a)
	local st=a.chakraPalm
	local look=flat(a.root.CFrame.LookVector)
	if look.Magnitude<.05 then return end
	look=look.Unit
	local palm={tags=st.plan.tags,weight=T.Objects.Palm.stats.weight,contest=1,volume=false,toolType="Palm"}
	for _,p in c.projectiles do
		if p.a~=a and moving(p) then
			local v=view(c,p)
			if v and not v.volume and v.tags.tool then
				local d=p.position-a.root.Position
				local f=flat(d)
				if d.Magnitude<=E.palm.reach and (f.Magnitude<1 or look:Dot(f.Unit)>=E.palm.cone) then
					settle(c,{direction=look,kind="palm",infusion="GentleFist"},p,palm,v,p.position,a)
				end
			end
		end
	end
end
-- Wire crossed by a flying object: fire runs along it, the owner's lightning
-- charges it, wind cuts it.
local burnWire
local function crossWire(c,p,w,at)
	local v=view(c,p)
	if not v then return end
	local ctx={}
	if p.a==w.a then ctx.own=true end
	local _,signals,applied=plan(c,"WireCross",{source={tags=v.tags,toolType=v.toolType},target={tags=w.tags},context={tags=ctx},mastery=masteryOf(p.a)})
	for _,name in signals do
		if name=="wire-burn" then burnWire(c,w,p.a)
		elseif name=="wire-charge" then
			w.charged=c.now+E.tripwire.charge;w.tags.charged=true;w.infusion="Lightning"
			c:pushImpact(at,"shock",false,{owner=w.a.id,chakra="wirecharge",infusion="Lightning"})
			Brawler.event(c,w.a,"WireCharged")
		elseif name=="wire-cut" then
			kill(c,w,at,"deflect",{chakra="wirecut",infusion=p.infusion,by=p.a.id})
			Brawler.event(c,p.a,"WireCut")
		end
	end
	record(c,"WireCross",applied,{source=p.kind,infusion=p.infusion})
end
function burnWire(c,w,fireOwner)
	if w.dead then return end
	local tune=E.tripwire
	local far=w.origin+w.direction*w.range
	local steps=math.max(1,math.floor(w.range/tune.patch))
	for k=0,steps do
		local point=w.origin:Lerp(far,k/steps)
		c:addHazard(fireOwner,point,2.2,tune.burn,4,"Fire")
	end
	kill(c,w,w.origin:Lerp(far,.5),"ember",{chakra="wireburn",infusion="Fire",from=w.origin,to=far,by=fireOwner.id})
	Brawler.event(c,fireOwner,"WireBurn")
end

-- ------------------------------------------------------------- planted points
local POINT={}
POINT["point-recover"]=function(c,q,x)
	kill(c,q,q.position,"fade",{chakra="recover",infusion=q.infusion})
	x.chakra=math.min(x.def.Chakra or Config.Chakra,x.chakra+E.plant.refund)
	c:cue(x,"CHAKRA BLADE RECOVERED • +"..E.plant.refund,.6)
	Brawler.event(c,x,"ChakraRecover")
end
POINT["point-shock"]=function(c,q,x)
	kill(c,q,q.position,"shock",{chakra="pointshock",infusion="Lightning",victim=x.id})
	c.damageTag="Shock Point";c.hitOrigin=q.position
	local hit=c:damage(q.a,x,E.shockPoint.damage,false,false)
	c.hitOrigin=nil;c.damageTag=nil
	if hit and x.state=="Stunned" and not x.reaction then x.untilTime=math.max(x.untilTime,c.now+E.shockPoint.stun) end
	c:cue(q.a,"SHOCK POINT",.6)
	Brawler.event(c,q.a,"ChakraShockPoint")
end
POINT["point-deny"]=function(c,q,x)
	kill(c,q,q.position,"fade",{chakra="deny",infusion=q.infusion})
	Brawler.event(c,x,"ChakraDeny")
end
local function touchPoint(c,q,x,owner)
	local d=x.root.Position-q.position
	if flat(d).Magnitude>E.plant.radius or math.abs(d.Y)>E.plant.height then return end
	if x.health<=0 or (not owner and x.invulnerableUntil>c.now) then return end
	local ctx={}
	ctx[if owner then "owner" else "opponent"]=true
	if not x.airborne then ctx.grounded=true end
	local _,signals,applied=plan(c,"PointContact",{source={tags=q.tags},target={tags={actor=true}},context={tags=ctx},mastery=masteryOf(q.a)})
	for _,name in signals do
		local handler=POINT[name]
		if handler and not q.dead then handler(c,q,x) end
		if c.match.phase~="Duel" then return end
	end
	record(c,"PointContact",applied,{owner=q.a.id,actor=x.id,infusion=q.infusion})
end
local function touchWire(c,w,x)
	local tune=E.tripwire
	if x.health<=0 or x.invulnerableUntil>c.now or x.reaction=="Bound" then return end
	local far=w.origin+w.direction*w.range
	local point=closest(w.origin,far,x.root.Position)
	if (x.root.Position-point).Magnitude>tune.radius then return end
	local ctx={opponent=true}
	if not x.airborne then ctx.grounded=true end
	local _,signals,applied=plan(c,"WireContact",{source={tags=w.tags},target={tags={actor=true}},context={tags=ctx},mastery=masteryOf(w.a)})
	local bind,shock=table.find(signals,"tripwire-bind")~=nil,table.find(signals,"tripwire-shock")~=nil
	if bind then
		kill(c,w,point,"pin",{chakra="tripwire",infusion=w.infusion,from=w.origin,to=far,victim=x.id})
		require(script.Parent.Techniques).wireBind(c,w.a,x,nil,w.direction)
		if c.match.phase~="Duel" then return end
		if shock and x.reaction=="Bound" then
			c.damageTag="Charged Wire";c.hitOrigin=point
			c:damage(w.a,x,tune.shock,false,false)
			c.hitOrigin=nil;c.damageTag=nil
			if c.match.phase~="Duel" then return end
			x.reactionUntil+=tune.bind
			c:pushImpact(x.root.Position,"chidori",false,{owner=w.a.id,victim=x.id,chakra="surge",infusion="Lightning",from=point,to=x.root.Position})
		end
		c:cue(w.a,"TRIPWIRE • 1 = DRAGON FLAME",.9)
		Brawler.event(c,w.a,"TripwireBind")
	end
	record(c,"WireContact",applied,{owner=w.a.id,actor=x.id,charged=w.charged~=nil})
end

-- ------------------------------------------------------------- per tick
-- Runs before projectiles move: palm swats, meetings between flying objects
-- (and with planted points and stretched wires), then the planted objects
-- against bodies and fire. Meetings resolve in time order, so the outcome
-- never depends on the order of the projectile list.
function Chakra.step(c,dt)
	local now=c.now
	for _,a in c.actors do
		if a.chakraPalm and now<a.chakraPalm.untilTime and a.health>0 then swat(c,a) end
	end
	local list=c.projectiles
	local hits={}
	for i=1,#list do
		local p=list[i]
		if moving(p) then
			local vp=view(c,p)
			if vp then
				local horizon=math.min(dt,p.remaining/p.speed)
				local velocity=p.direction*p.speed
				for j=1,#list do
					local q=list[j]
					-- Own objects never meet, except a stretched wire: the owner's
					-- lightning charges it and his own fire runs along it.
					if q~=p and (q.a~=p.a or q.planted=="wire") and not q.dead and not (p.clashed and p.clashed[q.id]) then
						if q.planted=="wire" then
							local a1,b1=p.position,p.position+velocity*horizon
							local far=q.origin+q.direction*q.range
							local onPath,onWire,s=segments(a1,b1,q.origin,far)
							if (onPath-onWire).Magnitude<=vp.contest+.35 then table.insert(hits,{t=s*horizon,p=p,q=q,kind="wire",at=onWire}) end
						elseif q.planted then
							local t=meet(p.position,velocity,q.position,Vector3.zero,horizon,vp.contest+E.plant.contest)
							if t then table.insert(hits,{t=t,p=p,q=q,kind="point"}) end
						elseif j>i and moving(q) then
							local vq=view(c,q)
							if vq then
								local t=meet(p.position,velocity,q.position,q.direction*q.speed,math.min(horizon,q.remaining/q.speed),vp.contest+vq.contest)
								if t then table.insert(hits,{t=t,p=p,q=q,kind="pair",vp=vp,vq=vq}) end
							end
						end
					end
				end
			end
		end
	end
	table.sort(hits,function(x,y)
		if x.t~=y.t then return x.t<y.t end
		local xa,ya=math.min(x.p.id,x.q.id),math.min(y.p.id,y.q.id)
		if xa~=ya then return xa<ya end
		return math.max(x.p.id,x.q.id)<math.max(y.p.id,y.q.id)
	end)
	for _,hit in hits do
		local p,q=hit.p,hit.q
		if not p.dead and not q.dead then
			p.clashed=p.clashed or {};p.clashed[q.id]=true
			q.clashed=q.clashed or {};q.clashed[p.id]=true
			if hit.kind=="pair" then
				local P=p.position+p.direction*p.speed*hit.t
				local Q=q.position+q.direction*q.speed*hit.t
				local s,t,vs,vt=dominant(p,q,hit.vp,hit.vq)
				settle(c,s,t,vs,vt,P:Lerp(Q,.5))
			elseif hit.kind=="point" then
				-- A planted point is contestable: any thrown object knocks it out.
				kill(c,q,q.position,"deflect",{chakra="knock",tool=q.planted,infusion=q.infusion,direction=p.direction,tumble=tumble(p.direction,p.direction),by=p.a.id})
				Brawler.event(c,p.a,"ChakraPointKnocked")
				record(c,"PointKnocked",{"thrown-object-knocks-point"},{owner=q.a.id,by=p.kind})
			elseif hit.kind=="wire" then
				crossWire(c,p,q,hit.at)
			end
			if c.match.phase~="Duel" then return end
		end
	end
	-- Planted points and wires against bodies, fire and time.
	for i=#list,1,-1 do
		local q=list[i]
		if q and q.planted and not q.dead then
			if now>=(q.expires or 0) or q.a.health<=0 then
				kill(c,q,q.position,"fade",{chakra="expire",infusion=q.infusion})
			elseif q.planted=="wire" then
				if q.charged and now>=q.charged then q.charged=nil;q.tags.charged=nil;q.infusion=nil end
				local far=q.origin+q.direction*q.range
				for _,h in c.hazards do
					if h.kind=="Fire" and not q.dead and (h.position-closest(q.origin,far,h.position)).Magnitude<=h.radius then burnWire(c,q,h.a) end
				end
				-- Rotation's dome snaps a wire it touches anywhere along its length.
				for _,spin in c.actors do
					if spin~=q.a and (spin.rotationUntil or 0)>now and not q.dead then
						local reach=spin.rotationReach or 7
						local point=closest(q.origin,far,spin.root.Position)
						if (point-spin.root.Position).Magnitude<=reach then
							kill(c,q,point,"deflect",{chakra="wirecut",by=spin.id})
							Brawler.event(c,spin,"WireCut")
						end
					end
				end
				local x=q.a.target
				if x and not q.dead then touchWire(c,q,x) end
			elseif now-q.born>=E.plant.settle then
				touchPoint(c,q,q.a,true)
				local x=q.a.target
				if x and not q.dead then touchPoint(c,q,x,false) end
			end
			if c.match.phase~="Duel" then return end
		end
	end
end

-- ------------------------------------------------------------- contact
local CONTACT={}
CONTACT["guard-crush"]=function(c,p,b)
	-- Reinforced steel leans on the guard: stamina, a shove, and a break when
	-- the guard has nothing left.
	local tune=E.guardCrush
	local impact=p.impact or 1
	b.stamina=math.max(0,(b.stamina or 100)-tune.stamina*impact)
	local push=flat(p.direction)
	if push.Magnitude>.05 then Motor.travel(b,c,push.Unit,tune.push*impact) end
	b.guardImpact=c.now+.18
	local broken=b.stamina<=0 and b.guardHeld
	if broken then
		b.guardHeld=false;c:setState(b,"Stunned",tune.stun)
		c:cue(b,"GUARD BREAK",.7);c:cue(p.a,"GUARD BREAK",.7)
		Brawler.event(c,p.a,"GuardCrushBreak")
	end
	c:pushImpact(b.root.Position,"crush",broken,{owner=p.a.id,victim=b.id,direction=p.direction,chakra="crush",infusion=p.infusion})
	Brawler.event(c,p.a,"GuardCrush")
end
CONTACT["shock"]=function(c,p,b)
	-- Lightning locks the muscles: the hit stun lasts longer (grounded only).
	if b.state=="Stunned" and not b.reaction then b.untilTime=math.max(b.untilTime,c.now+E.shock.stun) end
	c:pushImpact(b.root.Position,"shock",false,{owner=p.a.id,victim=b.id,chakra="shock",infusion="Lightning"})
	Brawler.event(c,p.a,"ChakraShock")
end
CONTACT["wire-surge"]=function(c,p,b)
	-- Lightning reaching a body held by the thrower's own wire runs through it.
	local tune=E.wireSurge
	c.damageTag="Wire Lightning"
	c:damage(p.a,b,tune.damage,false,false)
	c.damageTag=nil
	if c.match.phase~="Duel" then return end
	if b.reaction=="Bound" then b.reactionUntil=math.min(b.reactionUntil+tune.bind,(b.boundAt or c.now)+E.conduct.maxBind) end
	c:pushImpact(b.root.Position,"chidori",false,{owner=p.a.id,victim=b.id,chakra="surge",infusion="Lightning",from=p.a.root.Position,to=b.root.Position})
	Brawler.event(c,p.a,"WireSurge")
end
CONTACT["ignite"]=function(c,p,b)
	local tune=E.ignite
	c:addHazard(p.a,ground(c,b.root.Position),tune.radius*(if p.flared then 1.4 else 1),tune.duration,tune.damage,"Fire")
	c:pushImpact(b.root.Position,"ember",false,{owner=p.a.id,victim=b.id,chakra="ignite",infusion="Fire"})
	Brawler.event(c,p.a,"ChakraIgnite")
end
CONTACT["gust"]=function(c,p,b)
	-- The wind kunai shoves the body along its line and opens a chase.
	local tune=E.gust
	local push=flat(p.direction)
	if push.Magnitude>.05 and not b.reaction then b.root.AssemblyLinearVelocity=push.Unit*tune.push+Vector3.new(0,tune.lift,0) end
	p.a.pursuitUntil=math.max(p.a.pursuitUntil or 0,c.now+tune.chase)
	c:cue(p.a,"WIND KUNAI • E TO CHASE",tune.chase)
	c:pushImpact(b.root.Position,"gust",false,{owner=p.a.id,victim=b.id,chakra="gust",infusion="Wind",direction=p.direction})
	Brawler.event(c,p.a,"ChakraGust")
end
-- A chakra projectile reached a body. `damaged` is what Combat:damage
-- returned (false: evaded, parried, absorbed: the chakra does nothing).
function Chakra.contact(c,p,b,damaged)
	if not p.chakra or not damaged or b.health<=0 or c.match.phase~="Duel" then return end
	local guarded=b.impactStyle=="block"
	local tags={actor=true}
	if guarded then tags.guarding=true end
	if b.reaction=="Bound" then tags.bound=true;if b.boundBy==p.a then tags.wired=true end end
	if b.airborne then tags.airborne=true end
	local ctx={}
	ctx[if guarded then "guarded" else "clean"]=true
	local _,signals,applied=plan(c,"Contact",{source={tags=p.tags,toolType=T.Objects[p.chakra.object].toolType},target={tags=tags},context={tags=ctx},mastery=masteryOf(p.a)})
	for _,name in signals do
		local handler=CONTACT[name]
		if handler then handler(c,p,b) end
		if c.match.phase~="Duel" or b.health<=0 then break end
	end
	record(c,"Contact",applied,{source=p.kind,infusion=p.infusion,victim=b.id,guarded=guarded})
end

-- ------------------------------------------------------------- surfaces
local function plantPoint(c,p,position,normal,shock)
	local into=p.direction
	if into:Dot(normal)>-.2 then into=(into-normal*1.2).Unit end
	c.projectileSerial=(c.projectileSerial or 0)+1
	local tags=copy(p.tags)
	if shock then tags.shockPoint=true end
	local q={id=c.projectileSerial,a=p.a,origin=position,position=position,direction=into,speed=0,range=0,remaining=0,damage=0,
		kind="point",planted=p.kind,born=c.now,radius=0,growth=0,expires=c.now+E.plant.life,normal=normal,
		chakra=p.chakra,infusion=p.infusion,tags=tags,weight=p.weight,impact=p.impact,contest=E.plant.contest}
	table.insert(c.projectiles,q)
	local mine={}
	for _,x in c.projectiles do if x.a==p.a and x.kind=="point" and not x.dead then table.insert(mine,x) end end
	for i=1,#mine-E.plant.max do kill(c,mine[i],mine[i].position,"fade",{chakra="expire",infusion=mine[i].infusion}) end
	c.urgent=true
	Brawler.event(c,p.a,"ChakraPlant")
	return q
end
-- A wired shuriken that misses stays strung from where it was thrown (tied
-- off at ankle height) to where it landed: a tripwire across that lane.
local function stretch(c,p,position,normal)
	local near=ground(c,p.origin)+Vector3.new(0,.7,0)
	local far=position+normal*.15
	local span=far-near
	if span.Magnitude<3 or span.Magnitude>80 then return nil end
	for _,x in c.projectiles do
		if x.a==p.a and x.kind=="tripwire" and not x.dead then kill(c,x,x.position,"fade",{chakra="expire"}) end
	end
	c.projectileSerial=(c.projectileSerial or 0)+1
	local w={id=c.projectileSerial,a=p.a,origin=near,position=near,direction=span.Unit,speed=0,range=span.Magnitude,remaining=0,damage=0,
		kind="tripwire",planted="wire",born=c.now,radius=0,growth=0,expires=c.now+E.tripwire.life,tags={tool=true,wire=true,metal=true}}
	table.insert(c.projectiles,w)
	c.urgent=true
	c:cue(p.a,"WIRE STRETCHED",.8)
	Brawler.event(c,p.a,"Tripwire")
	return w
end
-- A chakra blade or a wire reached a wall or the floor. Returns what stayed
-- behind ({point=, wire=, burn=}) so the caller tags its own impact.
function Chakra.surface(c,p,position,normal,instance)
	local v=view(c,p)
	if not v or not (p.chakra or v.tags.wire) then return nil end
	local tags={solid=true}
	tags[if math.abs(normal.Y)<.7 then "wall" else "floor"]=true
	if instance==nil or instance.CanCollide~=false then tags.anchorCompatible=true end
	local selected,signals,applied=plan(c,"SurfaceHit",{source={tags=v.tags,toolType=v.toolType},surface={tags=tags},mastery=masteryOf(p.a)})
	local embed,shock=false,false
	for _,r in selected do
		for _,e in r.effects do
			if e.kind=="embed" then embed=true elseif e.kind=="tag" and e.tag=="shockPoint" then shock=true end
		end
	end
	local outcome={}
	if embed then outcome.point=plantPoint(c,p,position,normal,shock) end
	for _,name in signals do
		if name=="burn-point" then
			local tune=E.burnPoint
			c:addHazard(p.a,position+normal*.6,tune.radius*(if p.flared then 1.4 else 1),tune.duration,tune.damage,"Fire")
			outcome.burn=true
		elseif name=="wire-stretch" then outcome.wire=stretch(c,p,position,normal) end
	end
	record(c,"SurfaceHit",applied,{source=p.kind,infusion=p.infusion,planted=outcome.point~=nil,wire=outcome.wire~=nil})
	return outcome
end
-- End of flight: a chakra blade or a wire drops to the floor and stays there.
function Chakra.expire(c,p)
	if not ((p.chakra and not p.chakra.innate) or p.kind=="wire") then return false end
	local floor=workspace:Raycast(p.position,Vector3.new(0,-80,0),c:rayParams(true))
	if not floor then return false end
	local outcome=Chakra.surface(c,p,floor.Position,floor.Normal,floor.Instance)
	if not outcome or not (outcome.point or outcome.wire) then return false end
	c:pushImpact(floor.Position,"stick",false,{projectile=p.id,kind=p.kind,normal=floor.Normal,owner=p.a.id,direction=p.direction,
		chakra=if outcome.wire then "stretch" else "plant",infusion=p.infusion})
	return true
end

-- ------------------------------------------------------------- body chakra
-- Neji: the chakra goes through the palm. A short twin-palm thrust that swats
-- the blades in front of it while it comes out, drains and closes a point
-- through a guard, and closes an extra point on a clean hit.
function Chakra.palm(c,a,infused)
	committed(c,infused)
	Brawler.start(c,a,"PalmThrust")
	local pending=a.pending
	if not pending then return false,"Committed" end
	local tune=E.palm
	pending.spec.damage*=tune.damage;pending.spec.travel=tune.travel;a.travelRemaining=tune.travel
	pending.chakra=infused
	a.attackVariant="ChakraPalm"
	local window=pending.spec.startup+pending.spec.active
	local serial=a.attackSerial
	a.chakraPalm={untilTime=c.now+window+.04,serial=serial,plan=infused}
	c:schedule(c.now+window+.02,function() Chakra.palmResolve(c,a,serial) end)
	c:pushImpact(a.root.Position,"cast",false,{owner=a.id,fighter=a.fighterId,technique="ChakraPalm",chakra="palm",infusion="GentleFist"})
	c:cue(a,"CHAKRA PALM",.5)
	Brawler.event(c,a,"ChakraPalm")
	return true
end
function Chakra.palmResolve(c,a,serial)
	local st=a.chakraPalm
	if not st or st.serial~=serial then return end
	a.chakraPalm=nil
	local b=a.target
	if a.health<=0 or not b or b.health<=0 or a.attackSerial~=serial or not a.hitConfirmed or not a.def.GentleFist then return end
	local guarded=a.hitBlocked==true
	local tags={actor=true}
	if guarded then tags.guarding=true end
	local ctx={}
	ctx[if guarded then "guarded" else "clean"]=true
	local _,signals,applied=plan(c,"Contact",{source={tags=st.plan.tags,toolType="Palm"},target={tags=tags},context={tags=ctx},mastery=masteryOf(a)})
	local tune=E.palm
	for _,name in signals do
		if name=="palm-through-guard" then
			b.chakra=math.max(0,b.chakra-tune.drain)
			b.stamina=math.max(0,(b.stamina or 100)-tune.stamina)
			-- The point closes as if the guard were not there.
			Brawler.gentleFist(c,a,b,false)
			local push=flat(b.root.Position-a.root.Position)
			if push.Magnitude>.05 then Motor.travel(b,c,push.Unit,tune.push) end
			b.guardImpact=c.now+.18
			c:pushImpact(b.root.Position,"palm",true,{owner=a.id,victim=b.id,chakra="throughguard",infusion="GentleFist",direction=a.root.CFrame.LookVector})
			c:cue(a,"CHAKRA PALM • THROUGH THE GUARD",.8);c:cue(b,"CHAKRA DRAINED",.6)
			Brawler.event(c,a,"PalmThroughGuard")
		elseif name=="palm-point" then
			for _=1,tune.points do Brawler.gentleFist(c,a,b,false) end
			c:pushImpact(b.root.Position,"palm",false,{owner=a.id,victim=b.id,chakra="tenketsu",infusion="GentleFist"})
			Brawler.event(c,a,"PalmPoint")
		end
	end
	record(c,"Contact",applied,{source="palm",infusion="GentleFist",victim=b.id,guarded=guarded})
end
-- Sasuke: with the wire still on a bound body, the chakra tool sends the
-- lightning down the wire instead of throwing (the wire stays: Dragon Flame
-- remains available). Bounded: two currents per bind, never past 2.2 s.
function Chakra.conduct(c,a,infused)
	local b=a.wireVictim
	if not (b and b.reaction=="Bound" and b.boundBy==a and b.health>0) then return false,"Wire lost" end
	local tune=E.conduct
	committed(c,infused)
	b.wireConducts=(b.wireConducts or 0)+1
	local hand=c.launchPoint(a,"Kunai")
	c.damageTag="Wire Lightning";c.hitOrigin=hand
	local hit=c:damage(a,b,tune.damage,false,false)
	c.hitOrigin=nil;c.damageTag=nil
	if c.match.phase~="Duel" then return true end
	if b.reaction=="Bound" then b.reactionUntil=math.min(b.reactionUntil+tune.bind,(b.boundAt or c.now)+tune.maxBind) end
	if hit and b.state=="Stunned" then b.untilTime=math.max(b.untilTime,b.reactionUntil or c.now) end
	c:pushImpact(b.root.Position,"chidori",false,{owner=a.id,victim=b.id,chakra="conduct",infusion="Lightning",from=hand,to=b.root.Position})
	c:cue(a,"WIRED • LIGHTNING • 1 = DRAGON FLAME",.9);c:cue(b,"WIRED • X TO ESCAPE",.9)
	Brawler.event(c,a,"WireLightning")
	record(c,"Conduct",infused.rules,{owner=a.id,victim=b.id,uses=b.wireConducts})
	return true
end
return Chakra
