-- Temari (Gale, roster wave): the wind fan, on the shared systems. Her kit
-- lives here so the contested combat files only carry short registries
-- (Techniques.Tools / payoffs / awakenHooks / actorSteps / reposition, read by
-- Combat and Brawler): Kamaitachi, Great Gust and Rising Whirlwind (each one
-- leaves a zone, Zones.luau), the fan gust that replaces a thrown tool, the
-- wind step that re-enters at her range, the updraft route, the glide and the
-- Kirikiri Mai awakening. Sheet: docs/characters/TEMARI.md.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Zones=require(script.Parent.Zones)
local Motor=require(script.Parent.Motor)
local Brawler=require(script.Parent.Brawler)
local Defense=require(script.Parent.VelmoraDefense)
local Gale={}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function flatUnit(v,fallback)
	local f=flat(v)
	return if f.Magnitude>.05 then f.Unit else (fallback or Vector3.zAxis)
end
local function awake(c,a) return (a.awakenUntil or 0)>c.now and a.def.Awakening or nil end
-- After Kirikiri Mai the fan stays shut for a moment: no technique.
function Gale.fanOpen(c,a,_spec,now)
	local tune=a.def.Awakening
	local until_=a.awakenUntil or 0
	if tune and tune.FanClosed and a.awakened and until_>0 and now>=until_ and now<until_+tune.FanClosed then return false,"Fan closed" end
	return true
end
-- A lane of wind from `origin` (put on the floor) along `direction`. Kirikiri
-- Mai: longer, wider, and blades going up it are sent back.
local function lane(c,a,origin,direction,length,width,life,carrier)
	local on=awake(c,a)
	return Zones.add(c,a,"Wind",{origin=Vector3.new(origin.X,c.match.origin.Y,origin.Z),direction=direction,length=length,
		width=width*(if on then on.LaneWidth or 1 else 1),life=life*(if on then on.LaneLife or 1 else 1),carrier=carrier,reflect=on~=nil and on.Reflect==true})
end
Gale.lane=lane
-- The fan's line: from the hand at the aim, rising to a body held up in the
-- air (never steeper than ~40 degrees), and the flat direction of its lane.
local function windLine(c,a,aim,range)
	local origin=c.launchPoint(a,"Wind")
	aim=aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*range
	local d=aim-origin
	local f=flat(d)
	if f.Magnitude<1 then f=flat(a.root.CFrame.LookVector);d=f end
	local rise=math.clamp(d.Y,-f.Magnitude*.2,f.Magnitude*.84)
	return origin,Vector3.new(f.X,rise,f.Z).Unit,f.Unit
end
-- In the fan's cone (flat reach, cosine of the half angle, 10 studs up or down).
local function inCone(a,position,reach,cos)
	local d=position-a.root.Position
	local f=flat(d)
	if f.Magnitude>reach or math.abs(d.Y)>10 then return false end
	if f.Magnitude<1.5 then return true end
	return flatUnit(a.root.CFrame.LookVector):Dot(f.Unit)>=cos
end
Gale.inCone=inCone
-- The blades in the cone are blown out of the air (sent back at their thrower
-- when `back`), fire in it grows. Returns how many blades.
local function sweep(c,a,reach,cos,back)
	local count=0
	for _,p in table.clone(c.projectiles) do
		if p.a~=a and not p.dead and not p.planted and (p.speed or 0)>0 and inCone(a,p.position,reach,cos) then
			if Zones.FIRE[p.kind] then
				Zones.feed(c,p,a,Zones.KINDS.Wind.feed,Zones.KINDS.Wind.feedDamage)
			elseif Zones.OBJECT[p.kind] then
				count+=1
				if back then Zones.sendBack(c,p,a)
				else
					p.dead=true
					local index=table.find(c.projectiles,p)
					if index then table.remove(c.projectiles,index) end
					c:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=p.a.id,direction=-p.direction,chakra="blown"})
				end
			end
		end
	end
	return count
end

-- --------------------------------------------------------------- techniques
-- Kamaitachi: a wind scythe that knocks away (a wall behind the body splats
-- it) and leaves a lane of wind behind it, laid as it flies.
local function kamaitachi(c,a,pending)
	local spec=pending.spec
	local origin,line,direction=windLine(c,a,pending.aim,spec.Range)
	local p=c:projectile(a,origin+line*spec.Range,spec.Speed or 74,spec.Range,spec.Damage,"gale",nil,
		{origin=origin,radius=1.8,growth=.9,reaction="Knockback",impulse=Vector3.new(0,12,46),stun=.5,style="jutsu"})
	lane(c,a,origin,direction,spec.Range,spec.Lane or 3.2,spec.LaneLife or 3.6,p)
	c:cue(a,"KAMAITACHI",.6)
	Brawler.event(c,a,"Kamaitachi")
end
-- Great Gust: the fan fully open. Blades in the cone are blown away, fire
-- grows, the body is thrown back (a wall splat at range) and a wide lane stays.
local function greatGust(c,a,pending)
	local spec=pending.spec
	local reach,cos=spec.Range,spec.Cone or .74
	local look=flatUnit(a.root.CFrame.LookVector)
	local blown=sweep(c,a,reach,cos,false)
	local b=a.target
	if b and b.health>0 and inCone(a,b.root.Position,reach,cos) and c:lineOfSight(a,b) then
		c.damageTag="Great Gust"
		local hit=c:damage(a,b,spec.Damage,false,false)
		c.damageTag=nil
		if c.match.phase~="Duel" then return end
		if hit then
			local away=flatUnit(b.root.Position-a.root.Position,look)
			if b.impactStyle=="block" then Motor.travel(b,c,away,3)
			else Brawler.react(c,b,"Knockback",away*(spec.Push or 58)+Vector3.new(0,14,0),.6,a) end
			Brawler.event(c,a,"GreatGustHit")
		end
	end
	lane(c,a,a.root.Position+look*2,look,reach,spec.Lane or 5,spec.LaneLife or 4.2)
	c:pushImpact(a.root.Position+look*3,"greatgust",true,{owner=a.id,fighter=a.fighterId,direction=look,range=reach,blown=blown})
	c:cue(a,if blown>0 then "GREAT GUST • "..blown.." BLADES BLOWN AWAY" else "GREAT GUST",.7)
	Brawler.event(c,a,"GreatGust")
end
-- Rising Whirlwind: the spot where the opponent stands is marked; a beat later
-- a column of rising air erupts there. A body still in it is thrown up and
-- held (Zones "Updraft"); one that kept moving is not.
local function cyclone(c,a,pending)
	local spec=pending.spec
	local b=a.target
	local aim=pending.aim or (b and b.root.Position) or a.root.Position+a.root.CFrame.LookVector*spec.Range
	local d=flat(aim-a.root.Position)
	if d.Magnitude>spec.Range then aim=a.root.Position+d.Unit*spec.Range end
	local spot=Vector3.new(aim.X,c.match.origin.Y,aim.Z)
	local radius=spec.Radius or 3.4
	local delay=spec.Delay or .45
	c:pushImpact(spot+Vector3.new(0,.3,0),"cyclone",false,{owner=a.id,fighter=a.fighterId,phase="mark",delay=delay,radius=radius})
	c:cue(a,"RISING WHIRLWIND",.6)
	Brawler.event(c,a,"Cyclone")
	c:schedule(c.now+delay,function()
		if a.health<=0 or c.match.phase~="Duel" then return end
		local z=Zones.add(c,a,"Updraft",{origin=spot,radius=radius,life=spec.Life or 2.2})
		c:pushImpact(spot+Vector3.new(0,.3,0),"cyclone",true,{owner=a.id,fighter=a.fighterId,phase="rise",radius=radius,zone=z.id})
		local victim=a.target
		if not victim or victim.health<=0 or victim.invulnerableUntil>c.now or not Zones.inside(z,victim.root.Position) then return end
		c.damageTag="Rising Whirlwind";c.hitOrigin=spot+Vector3.new(0,3,0)
		local hit=c:damage(a,victim,spec.Damage,false,false)
		c.hitOrigin=nil;c.damageTag=nil
		if c.match.phase~="Duel" or not hit or victim.impactStyle=="block" then return end
		Brawler.react(c,victim,"Launched",Vector3.new(0,spec.Lift or 50,0),1.1,a)
		Brawler.event(c,a,"CycloneHit")
	end)
end

-- ---------------------------------------------------------------- the fan
-- The release of a gust: everything in the cone at that frame.
function Gale.blow(c,a,infused)
	local tune=a.def.Gust
	local on=awake(c,a)
	local reach=tune.Range*(if infused then tune.Infused or 1 else 1)*(if on then on.GustReach or 1 else 1)
	local cos=tune.Cone or .8
	local look=flatUnit(a.root.CFrame.LookVector)
	local sent=sweep(c,a,reach,cos,true)
	local b=a.target
	if b and b.health>0 and b.invulnerableUntil<=c.now and (b.rotationUntil or 0)<=c.now and not b.groundPose
		and inCone(a,b.root.Position,reach,cos) and c:lineOfSight(a,b) then
		local away=flatUnit(b.root.Position-a.root.Position,look)
		if b.state=="Guarding" then Motor.travel(b,c,away,tune.GuardPush or 2)
		else
			Brawler.react(c,b,"Knockback",away*(tune.Push or 34)+Vector3.new(0,8,0),.4,a)
			Brawler.event(c,a,"GustPush")
		end
	end
	if infused or (on and on.GustLane) then lane(c,a,a.root.Position+look*2,look,reach,tune.Lane or 3,tune.LaneLife or 2.6) end
	c:pushImpact(a.root.Position+look*2.5,"gust",infused~=nil,{owner=a.id,fighter=a.fighterId,direction=look,range=reach,sent=sent,infusion=infused and infused.infusion})
	if sent>0 then c:cue(a,"GUST • "..sent.." SENT BACK",.6);Brawler.event(c,a,"GustReturn") end
end
-- The tool button (Fighters.Gale.Gust): the fan swung like a throw (the legs
-- keep moving, a hit cancels it before the release). Free inside a clean
-- string (away + tool there also hops her back); with the chakra modifier a
-- Wind infusion (ChakraTuning WindFan): further, and a short lane stays.
function Gale.gust(c,a,chakra,aim)
	local tune=a.def.Gust
	if not tune then return false,"No tool" end
	if a.throwing then return false,"Throwing" end
	if a.reaction or a.wall then return false,"Committed" end
	local chainCancel=a.def.ComboToolCancel and a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0)
	if (not chainCancel and not Rules.canAct(a,c.now)) or c.now<(a.neutralToolAt or 0) then return false,"Tool recovering" end
	local infused=nil
	if chakra then
		local Chakra=require(script.Parent.ChakraCombat)
		local why
		infused,why=Chakra.plan(c,a,"Fan")
		if not infused then Chakra.refuse(c,a);return false,why end
		local cost=Chakra.cost(infused,chainCancel)
		if a.chakra<cost then Chakra.refuse(c,a);return false,"Need chakra" end
		a.chakra-=cost
		Chakra.record(c,"Infuse",infused.rules,{owner=a.id,object="Fan",infusion=infused.infusion,mode="gust"})
	elseif not chainCancel then
		if a.chakra<Config.ToolCost then return false,"Need chakra" end
		a.chakra-=Config.ToolCost
	end
	local back=chainCancel and Brawler.intent(a)=="back"
	if chainCancel then a.pending=nil;a.attackName=nil;a.chainOpen=false;c:setState(a,"Neutral",0);Brawler.event(c,a,"ChainTool") end
	if a.state=="Guarding" then Defense.guard(a,false,c.now);c:setState(a,"Neutral",0) end
	if back and a.target then
		a.hop={direction=flatUnit(a.root.Position-a.target.root.Position,-a.root.CFrame.LookVector),remaining=tune.Hop or 6,speed=40}
		Brawler.event(c,a,"Disengage")
	end
	a.neutralToolAt=c.now+(if chainCancel then .45 else tune.Recover or .7)
	c:beginThrow(a,{kind="Gust",release=tune.Release or .1,count=1,aim=aim,fire=function() Gale.blow(c,a,infused) end})
	c:cue(a,if infused then "WIND GUST • LANE" else "GUST",.5)
	Brawler.event(c,a,"Gust")
	return true
end

-- ------------------------------------------------------------ the wind step
-- E outside a chase window (MoveGraphs.Gale.reengage.reposition): back to her
-- range on the wind. Close in, out at an angle; far, in to `keep` studs (never
-- into melee); at range, a step aside that changes her lanes' angle. Same
-- price, cooldown and Rush state as the shared chakra dash (its motion and
-- arrival are Combat's), so it can be read and punished the same way.
function Gale.reposition(c,a,style)
	local tune=Config.Rush
	local cancel=a.state=="Recovery" and c.now>=(a.recoveryCancelAt or math.huge)
	if not Rules.canAct(a,c.now) and not cancel then return false,"Committed" end
	if a.airborne or a.wall or a.reaction then return false,"No chakra dash" end
	if a.chakra<Config.PursuitCost then return false,"Need chakra" end
	if c.now<(a.rushReadyAt or 0) then return false,"Cooldown" end
	local b=a.target
	if not b then return false,"No target" end
	local look=flatUnit(a.root.CFrame.LookVector)
	local gap=flat(b.root.Position-a.root.Position).Magnitude
	local toward=flatUnit(b.root.Position-a.root.Position,look)
	local right=toward:Cross(Vector3.yAxis)
	local dir,stickSide=Brawler.classify(a,a.move or Vector3.zero)
	local side=if dir=="side" then stickSide else (a.rushSide or 1)
	a.rushSide=-side
	local keep=style.keep or 17
	local line,distance,mode
	if a.locked==false then
		local stick=flat(a.move or Vector3.zero)
		line=if stick.Magnitude>.2 then stick.Unit else look;distance=tune.Reposition;mode="step"
	elseif gap>keep+4 then
		line=toward;distance=math.min(gap-keep,style.reach or 22);mode="in"
	elseif gap<keep-4 then
		-- Out at an angle, to `keep` studs from the body.
		local rad=math.rad(style.angle or 30)
		line=(-toward*math.cos(rad)+right*side*math.sin(rad)).Unit
		local along=gap*line:Dot(toward)
		distance=math.clamp(along+math.sqrt(math.max(0,along*along-gap*gap+keep*keep)),6,style.reach or 22)
		mode="out"
	else
		line=right*side;distance=style.side or 10;mode="aside"
	end
	if cancel then a.pending=nil end
	a.chakra-=Config.PursuitCost
	a.rushReadyAt=c.now+tune.Cooldown
	a.pending=nil;a.attackName=nil;a.guardHeld=false;a.chainOpen=false
	Brawler.breakString(a,false)
	local speed=tune.Speed*(style.speed or 1)
	local goal=c:clamp(a.root.Position+line*distance)
	local duration=math.clamp(distance/speed+.12,.12,tune.MaxTime*(style.time or 1))
	c:setState(a,"Rush",duration)
	a.rush={style=style,speed=speed,arrive=0,recovery=style.recovery or tune.Recovery,from=a.root.Position,line=line,goal=goal,reposition=mode}
	a.rushArriveUntil=c.now+duration+tune.Arrive
	Brawler.event(c,a,"Rush");Brawler.event(c,a,"Reengage");Brawler.event(c,a,"WindStep")
	c:pushImpact(a.root.Position,"chase",false,{owner=a.id,fighter=a.fighterId,variant=style.name,mode="dash",to=goal,reposition=mode})
	c:cue(a,"WIND STEP",.4)
	return true
end

-- ------------------------------------------------------------ air and route
-- The glide (Fighters.Gale.Glide): jump held in the air, the open fan holds
-- her up (the fall is capped). Free bodies only: an attack, a reaction, a
-- dash or a hover window own their own motion.
function Gale.glide(c,a,_dt,now)
	local g=a.def.Glide
	if not g then return end
	local on=a.jumpHeld==true and a.airborne and not a.reaction and not a.wall and a.state=="Neutral" and (a.airHold or 0)<=now
	if on then
		local v=a.root.AssemblyLinearVelocity
		if v.Y<-g.Fall then a.root.AssemblyLinearVelocity=Vector3.new(v.X,-g.Fall,v.Z) end
		if not a.gliding then a.gliding=true;Brawler.event(c,a,"Glide") end
	else a.gliding=nil end
end
-- The Updraft route (onRoute "updraft"): the scooped body is held up by a
-- column of rising air, in reach of the wind instead of a chase.
function Gale.updraft(c,a,b,_p)
	local z=Zones.add(c,a,"Updraft",{origin=Vector3.new(b.root.Position.X,c.match.origin.Y,b.root.Position.Z),radius=4.6,life=2})
	c:pushImpact(b.root.Position,"cyclone",false,{owner=a.id,fighter=a.fighterId,phase="updraft",radius=4.6,zone=z.id})
	c:cue(a,"UPDRAFT • KAMAITACHI OR GUST",1)
	Brawler.event(c,a,"UpdraftHold")
end

-- --------------------------------------------------------------- awakening
-- Kuchiyose: Kirikiri Mai (Combat:awaken, Techniques.awakenHooks): Kamatari
-- cuts across the arena at the opponent, a big wind projectile that knocks
-- down and lays a long lane. The rest of the rules are read where they apply
-- (lane, Gale.blow, Gale.fanOpen).
function Gale.summon(c,a)
	local tune=a.def.Awakening
	local s=tune and tune.Summon
	if not s then return end
	local b=a.target
	local look=flatUnit(a.root.CFrame.LookVector)
	local toward=if b then flatUnit(b.root.Position-a.root.Position,look) else look
	local origin=a.root.Position+toward*2+Vector3.new(0,.6,0)
	local p=c:projectile(a,origin+toward*s.Range,s.Speed,s.Range,s.Damage,"kamatari",nil,
		{origin=origin,radius=s.Radius,growth=0,reaction="Knockdown",impulse=Vector3.new(0,16,34),stun=.8,style="jutsu",heavy=true})
	lane(c,a,origin,toward,s.Range,s.Lane or 4.5,s.LaneLife or 6,p)
	c:cue(a,"KUCHIYOSE • KIRIKIRI MAI",1.2)
	Brawler.event(c,a,"Kamatari")
end

function Gale.install(T)
	T.Kamaitachi={check=Gale.fanOpen,execute=kamaitachi}
	T.GreatGust={check=Gale.fanOpen,execute=greatGust}
	T.Cyclone={check=Gale.fanOpen,execute=cyclone}
	T.Tools=T.Tools or {};T.Tools.Gust=Gale.gust
	T.payoffs=T.payoffs or {};T.payoffs.updraft=Gale.updraft
	T.awakenHooks=T.awakenHooks or {};table.insert(T.awakenHooks,Gale.summon)
	T.actorSteps=T.actorSteps or {};table.insert(T.actorSteps,Gale.glide)
	T.reposition=Gale.reposition
end
return Gale
