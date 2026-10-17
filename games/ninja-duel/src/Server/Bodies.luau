-- Light bodies that are not actors (roster hook H12): Naruto's shadow clones
-- first; a puppet or a ninja hound later takes the same path. A body is a
-- point on the stage with a small controller, a lifetime and a hit volume:
-- one blow from the other side (a strike, a blade, a dome) dispels it.
-- It never becomes a target, a lock-on or a camera subject: Combat keeps its
-- two actors. Bodies only add strike origins (a blow is judged from where the
-- body stands, through Combat hitOrigin, so a frontal guard does not cover a
-- clone behind) and volumes the opponent's strikes and blades reach first.
-- The client draws them from the snapshot (`bodies`, Client/BodyViews).
--
-- Data: Fighters[id].Bodies[kind] = {Max, Cost, Life, ...} (Max counts the
-- persistent bodies; a body made for one strike is `ephemeral`).
-- MoveGraphs[id].proxy[move] = {move, body, summon, solo, awake}: a strike
-- another body carries out (Bodies.route / Bodies.bind); Attacks[move].proxy
-- says where it stands ("behind", "side", "under").
local Bodies={}
Bodies.RADIUS=1.2 -- horizontal reach of a body's volume
Bodies.HALF=2.7 -- half height around its root (feet to head)
-- Kit hooks, filled by fighter modules (Server/Legion): a controller per
-- mode, what a dispel of a kind does, what a transforming tool becomes.
Bodies.controllers={}
Bodies.onDispel={}
Bodies.transforms={}
-- Jutsu volumes go through a body (it puffs away, the jutsu carries on);
-- blades stop in it.
local VOLUME={fireball=true,phoenix=true,palm=true,wind=true,sandwave=true}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function brawler() return require(script.Parent.Brawler) end
local function list(c) c.bodies=c.bodies or {};return c.bodies end
Bodies.list=list
function Bodies.tuning(a,kind)
	return (a.def.Bodies and a.def.Bodies[kind]) or {}
end
-- An awakening that takes the bodies away (Naruto's Nine-Tails cloak).
function Bodies.blocked(c,a)
	local tune=a.def.Awakening
	return tune~=nil and tune.NoBodies==true and (a.awakenUntil or 0)>c.now
end
-- Live bodies of `a` (of one kind), persistent ones only unless asked.
function Bodies.of(c,a,kind,ephemeral)
	local out={}
	for _,body in c.bodies or {} do
		if body.alive and body.owner==a and (not kind or body.kind==kind) and (ephemeral or not body.ephemeral) then table.insert(out,body) end
	end
	return out
end
function Bodies.count(c,a,kind) return #Bodies.of(c,a,kind) end
-- A persistent body free for a job (not already carrying a strike or shaping
-- a jutsu): the one nearest the owner's target.
function Bodies.free(c,a,kind)
	local best,bestGap
	local t=a.target
	for _,body in Bodies.of(c,a,kind) do
		if not body.carry and body.mode~="shape" and body.mode~="spent" then
			local gap=if t then (body.position-t.root.Position).Magnitude else 0
			if not bestGap or gap<bestGap then best,bestGap=body,gap end
		end
	end
	return best
end
function Bodies.face(body,point)
	local d=flat(point-body.position)
	if d.Magnitude>.1 then body.look=d.Unit end
end
-- Kinematic motion toward a point (bodies do not collide with fighters).
function Bodies.move(c,body,goal,speed,dt)
	local to=goal-body.position
	local step=speed*dt
	body.position=c:clamp(if to.Magnitude<=step then goal else body.position+to.Unit*step)
end
function Bodies.spawn(c,owner,spec)
	local kind=spec.kind or "clone"
	if not spec.ephemeral and Bodies.count(c,owner,kind)>=(Bodies.tuning(owner,kind).Max or 2) then return nil end
	c.bodySerial=(c.bodySerial or 0)+1
	local position=c:clamp(spec.position or owner.root.Position)
	local look=spec.look
	if not look then
		local t=owner.target
		look=flat(if t then t.root.Position-position else owner.root.CFrame.LookVector)
		look=if look.Magnitude>.1 then look.Unit else Vector3.new(0,0,-1)
	end
	local body={id=c.bodySerial,owner=owner,kind=kind,position=position,look=look,born=c.now,expires=c.now+(spec.life or Bodies.tuning(owner,kind).Life or 6),
		alive=true,state=spec.state or "Neutral",action=spec.action,actionAt=c.now,actionSerial=if spec.action then 1 else 0,mode=spec.mode or "guard",
		ephemeral=spec.ephemeral==true,velocity=Vector3.zero,airborne=spec.airborne==true,side=spec.side or 1,nextStrike=c.now+(spec.delay or 1),warp=0}
	table.insert(list(c),body)
	c:pushImpact(position,"body",false,{phase="appear",kind=kind,body=body.id,owner=owner.id,fighter=owner.fighterId})
	brawler().event(c,owner,"BodySpawned")
	return body
end
-- Gone in a puff of smoke. why: "hit", "blade", "area", "expire", "spent"
-- (its strike is over), "swap" (a substitution), "cloak", "owner".
function Bodies.dispel(c,body,why,by,extra)
	if not body.alive then return false end
	body.alive=false
	local all=c.bodies
	local index=all and table.find(all,body)
	if index then table.remove(all,index) end
	if body.carry then body.carry.lost=true;body.carry.from=nil;body.carry=nil end
	local entry={phase=why or "hit",kind=body.kind,body=body.id,owner=body.owner.id,fighter=body.owner.fighterId,by=by and by.id}
	for k,v in extra or {} do entry[k]=v end
	c:pushImpact(body.position,"body",why=="hit" or why=="blade",entry)
	local hook=Bodies.onDispel[body.kind]
	if hook then hook(c,body,why,by) end
	local Brawler=brawler()
	Brawler.event(c,body.owner,"BodyLost")
	if by and by~=body.owner then
		Brawler.event(c,by,"BodyDispelled")
		c:cue(by,string.upper(body.kind).." DISPELLED",.5)
	end
	return true
end
-- A real relocation (a body flickering across the stage): the client snaps.
function Bodies.warp(c,body,at)
	c:pushImpact(body.position,"body",false,{phase="vanish",kind=body.kind,body=body.id,owner=body.owner.id,fighter=body.owner.fighterId})
	body.position=c:clamp(at);body.warp+=1
	c:pushImpact(body.position,"body",false,{phase="appear",kind=body.kind,body=body.id,owner=body.owner.id,fighter=body.owner.fighterId})
end
-- Where a carried strike is thrown from (Attacks[move].proxy): "behind" the
-- target (the far side from its owner), "side" (the flank the stick asked
-- for), "under" (in close beside it, for a launcher). On the ground.
function Bodies.place(c,a,how,side)
	local b=a.target
	local at=b.root.Position
	local line=flat(at-a.root.Position)
	line=if line.Magnitude>.1 then line.Unit else flat(a.root.CFrame.LookVector).Unit
	local right=line:Cross(Vector3.yAxis)
	local s=if side and side~=0 then side else 1
	local p
	if how=="behind" then p=at+line*2.7
	elseif how=="side" then p=at+right*s*2.9
	else p=at-line*1.9+right*s*1.3 end
	return c:clamp(Vector3.new(p.X,c.match.origin.Y+3,p.Z))
end
-- Which move a press actually starts (Brawler.start): the proxy move with
-- the body that carries it (a free one, or "summon" for its cost), its
-- awakened form, or the solo move when there is no body to carry it.
function Bodies.route(c,a,name)
	local graph=brawler().graph(a)
	local d=graph and graph.proxy and graph.proxy[name]
	if not d then return name end
	if (a.awakenUntil or 0)>c.now and d.awake then return d.awake end
	if not Bodies.blocked(c,a) then
		local free=Bodies.free(c,a,d.body)
		if free then return d.move,free,d.body end
		if d.summon and a.chakra>=(Bodies.tuning(a,d.body).Cost or 12) then return d.move,"summon",d.body end
	end
	return d.solo or name
end
-- The strike's body goes to its spot (a summoned one appears there in a
-- puff, an existing one runs, or flickers from far away) and the strike is
-- judged from it: `p.from` is its frame, kept current by Bodies.step.
function Bodies.bind(c,a,p,proxy,kind)
	local spec=p.spec
	p.side=if (a.angleSide or 0)~=0 then a.angleSide else 1
	local at=Bodies.place(c,a,spec.proxy,p.side)
	local body=proxy
	local span=spec.startup+spec.active+spec.recovery
	if proxy=="summon" then
		a.chakra=math.max(0,a.chakra-(Bodies.tuning(a,kind).Cost or 12))
		body=Bodies.spawn(c,a,{kind=kind,position=at,ephemeral=true,life=span+.6,mode="carry"})
		if not body then p.lost=true;return nil end
	elseif (at-body.position).Magnitude>14 then
		Bodies.warp(c,body,at)
	end
	body.carry=p;body.mode="carry";body.goal=at
	body.action=p.name;body.variant=spec.proxyClip;body.actionAt=c.now;body.actionSerial+=1;body.state="Startup"
	body.expires=math.max(body.expires,c.now+span+.6)
	Bodies.face(body,a.target.root.Position)
	p.body=body;p.from=CFrame.lookAt(body.position,body.position+body.look)
	brawler().event(c,a,"BodyStrike")
	return body
end
local function carry(c,body,dt)
	local p=body.carry
	local a=body.owner
	local b=a.target
	if a.pending~=p or a.health<=0 or not b or b.health<=0 then
		-- The strike is over (landed, missed, or its owner was hit): spent.
		body.carry=nil;body.mode="spent";body.state="Recovery"
		body.expires=math.min(body.expires,c.now+.22)
		return
	end
	body.state=a.state
	if a.state=="Startup" then body.goal=Bodies.place(c,a,p.spec.proxy,p.side) end
	Bodies.move(c,body,body.goal or body.position,90,dt)
	Bodies.face(body,b.root.Position)
	p.from=CFrame.lookAt(body.position,body.position+body.look)
end
function Bodies.step(c,dt)
	local all=c.bodies
	if not all or #all==0 then return end
	for _,body in table.clone(all) do
		if body.alive then
			local owner=body.owner
			if owner.health<=0 or c.match.phase~="Duel" then Bodies.dispel(c,body,"owner")
			elseif c.now>=body.expires then Bodies.dispel(c,body,if body.mode=="spent" then "spent" else "expire")
			elseif Bodies.blocked(c,owner) then Bodies.dispel(c,body,"cloak")
			else
				local from=body.position
				if body.carry then carry(c,body,dt)
				else
					local control=Bodies.controllers[body.mode]
					if control then control(c,body,dt) end
				end
				if body.alive and dt>0 then body.velocity=(body.position-from)/dt end
			end
		end
	end
end
-- A body's own blow (a clone's jab, a barrage kick), judged from where it
-- stands and paid to its owner's account; it never touches its owner's own
-- string (hitConfirmed) and cannot be read or parried into a stun of him.
-- spec: damage, reach, height, arc (cosine of the half angle in front of the
-- body), reaction, push, up, stun, tag. Returns whether it landed.
function Bodies.hitFrom(c,body,victim,spec)
	local owner=body.owner
	if c.match.phase~="Duel" or not body.alive or owner.health<=0 or not victim or victim.health<=0 then return false end
	local d=victim.root.Position-body.position
	local f=flat(d)
	if f.Magnitude>(spec.reach or 5.5) or math.abs(d.Y)>(spec.height or 4) then return false end
	if f.Magnitude>.5 and body.look:Dot(f.Unit)<(spec.arc or .2) then return false end
	local confirmed=owner.hitConfirmed
	c.hitOrigin=body.position;c.damageTag=spec.tag or "Body"
	local landed=c:damage(owner,victim,(spec.damage or 4)*(owner.def.CombatDamage or 1),false,false)
	c.hitOrigin=nil;c.damageTag=nil
	owner.hitConfirmed=confirmed
	if c.match.phase~="Duel" then return landed end
	if landed and victim.impactStyle~="block" and victim.health>0 then
		local push=if f.Magnitude>.1 then f.Unit else body.look
		brawler().react(c,victim,spec.reaction or "HitStun",push*(spec.push or 10)+Vector3.new(0,spec.up or 3,0),spec.stun or .32,owner)
	end
	return landed
end
local function inBox(box,size,point,margin)
	local q=box:PointToObjectSpace(point)
	return math.abs(q.X)<=size.X/2+margin and math.abs(q.Y)<=size.Y/2+Bodies.HALF-.7 and math.abs(q.Z)<=size.Z/2+margin
end
-- A melee strike that reaches an enemy body first (Brawler.hit): the body is
-- dispelled and the strike is spent on it, like a blocked one (the string
-- starts over, the recovery stays short). The real fighter still takes the
-- blow when he stands nearer in the same swing, unless it was aimed at the
-- body (Bodies.aim). A wide swing (Bodies.WIDE: sweeps, spinning kicks,
-- claws) clears every enemy body it covers and still reaches the fighter.
-- Returns true when a body took the strike.
Bodies.WIDE=6.5
function Bodies.strike(c,a,p)
	local all=c.bodies
	if not all or #all==0 or p.lost then return false end
	local spec=p.spec
	local frame=p.from or a.root.CFrame
	local box=frame*CFrame.new(0,0,-(spec.offset or 2))
	local size=Vector3.new(spec.width or 5,spec.height or 5,spec.depth or 2)
	local covered={}
	local best,bestGap
	for _,body in all do
		if body.alive and body.owner~=a and inBox(box,size,body.position,1) then
			table.insert(covered,body)
			local gap=(body.position-frame.Position).Magnitude
			if not bestGap or gap<bestGap then best,bestGap=body,gap end
		end
	end
	if not best then return false end
	local t=a.target
	local real=t~=nil and t.health>0 and inBox(box,size,t.root.Position,1)
	if (spec.width or 5)>=Bodies.WIDE then
		for _,body in covered do Bodies.dispel(c,body,"hit",a) end
		if real then return false end
		a.hitBlocked=true
		return true
	end
	if p.aim~=best and real and (t.root.Position-frame.Position).Magnitude<bestGap then return false end
	a.hitBlocked=true
	Bodies.dispel(c,best,"hit",a)
	return true
end
local function closestOnSegment(a,b,point)
	local ab=b-a
	local length=ab:Dot(ab)
	if length<1e-6 then return a end
	return a+ab*math.clamp((point-a):Dot(ab)/length,0,1)
end
-- A projectile's step through an enemy body (Combat:updateProjectiles): the
-- body puffs away; a blade stops in it (true: the projectile is spent), a
-- jutsu volume carries on (false).
function Bodies.projectile(c,p,step)
	local all=c.bodies
	if not all or #all==0 or not p.a then return false end
	local radius=(p.radius or 0)+(p.growth or 0)*math.max(0,c.now-(p.born or c.now))
	local from=p.position
	local hit,best
	for _,body in all do
		if body.alive and body.owner~=p.a then
			local close=closestOnSegment(from,from+step,body.position)
			local d=body.position-close
			if flat(d).Magnitude<=Bodies.RADIUS+radius and math.abs(d.Y)<=Bodies.HALF+radius then
				local along=(close-from).Magnitude
				if not best or along<best then hit,best=body,along end
			end
		end
	end
	if not hit then return false end
	-- The real fighter nearer on the same step takes it (a clone behind him is
	-- no shield for the blade that reaches him first).
	local t=p.a.target
	if t and t.health>0 then
		local close=closestOnSegment(from,from+step,t.root.Position)
		local d=t.root.Position-close
		if flat(d).Magnitude<=Bodies.RADIUS+radius and math.abs(d.Y)<=Bodies.HALF+radius and (close-from).Magnitude<best then return false end
	end
	local volume=VOLUME[p.kind]==true
	Bodies.dispel(c,hit,"blade",p.a,if volume then {kind=hit.kind,through=p.kind} else {projectile=p.id,blade=p.kind,direction=p.direction})
	return not volume
end
-- Every enemy body of `a` within `radius` of `center` (a dome, a shockwave).
function Bodies.area(c,a,center,radius)
	local all=c.bodies
	if not all or #all==0 then return 0 end
	local count=0
	for _,body in table.clone(all) do
		local d=body.position-center
		if body.alive and body.owner~=a and flat(d).Magnitude<=radius+Bodies.RADIUS and math.abs(d.Y)<6 then
			Bodies.dispel(c,body,"area",a);count+=1
		end
	end
	return count
end
-- The enemy body a string opener is pushed at: the lock stays on the real
-- fighter, the stick picks the clone. nil when the stick points at none in
-- reach, or points closer to the locked target.
function Bodies.aim(c,a)
	local all=c.bodies
	if not all or #all==0 then return nil end
	local stick=flat(a.move or Vector3.zero)
	if stick.Magnitude<.45 then return nil end
	stick=stick.Unit
	local best,bestDot
	for _,body in all do
		if body.alive and body.owner~=a and math.abs(body.position.Y-a.root.Position.Y)<4 then
			local d=flat(body.position-a.root.Position)
			if d.Magnitude>.5 and d.Magnitude<=8 then
				local dot=stick:Dot(d.Unit)
				if dot>=.7 and (not bestDot or dot>bestDot) then best,bestDot=body,dot end
			end
		end
	end
	local t=a.target
	if best and t then
		local d=flat(t.root.Position-a.root.Position)
		if d.Magnitude>.5 and stick:Dot(d.Unit)>bestDot then return nil end
	end
	return best
end
-- The nearest enemy body within `reach` of `a` (the AI answers it).
function Bodies.threat(c,a,reach)
	local best,bestGap
	for _,body in c.bodies or {} do
		if body.alive and body.owner~=a then
			local gap=flat(body.position-a.root.Position).Magnitude
			if gap<=reach and math.abs(body.position.Y-a.root.Position.Y)<4 and (not bestGap or gap<bestGap) then best,bestGap=body,gap end
		end
	end
	return best
end
-- Substitution by swap (Fighters[id].Substitution.Mode "clone"): the free
-- body he trades places with, and that body left where he was hit.
function Bodies.swapWith(c,a)
	local best,bestGap
	for _,body in Bodies.of(c,a) do
		if not body.carry and body.mode~="shape" and body.mode~="spent" then
			local gap=(body.position-a.root.Position).Magnitude
			if gap<=45 and (not bestGap or gap<bestGap) then best,bestGap=body,gap end
		end
	end
	return best
end
function Bodies.swapped(c,body,departure)
	body.position=departure
	return Bodies.dispel(c,body,"swap")
end
-- A tool that turns into a body (ToolMastery.Transform, the chakra chord):
-- the body's cost while one can still be made, else nil.
function Bodies.transformCost(c,a,mastery)
	local kind=mastery and mastery.Transform
	if not kind or not Bodies.transforms[kind] or Bodies.blocked(c,a) then return nil end
	local tune=Bodies.tuning(a,kind)
	if Bodies.count(c,a,kind)>=(tune.Max or 2) then return nil end
	return tune.Cost or 12
end
-- The transforming tool in flight: close to its target, or at the end of its
-- flight, it becomes the body (Bodies.transforms[kind]). true: the
-- projectile is gone.
function Bodies.transform(c,p,step)
	local make=Bodies.transforms[p.transform]
	local b=p.a.target
	if not make or not b or b.health<=0 or p.a.health<=0 then return false end
	if (b.root.Position-p.position).Magnitude>5.5 and p.remaining-step.Magnitude>0 then return false end
	c:pushImpact(p.position,"body",false,{phase="transform",kind=p.transform,projectile=p.id,owner=p.a.id,fighter=p.a.fighterId})
	make(c,p)
	return true
end
-- Round over, KO, a new duel: every body goes without a puff.
function Bodies.clear(c)
	for _,body in c.bodies or {} do body.alive=false;body.carry=nil end
	if c.bodies then table.clear(c.bodies) end
end
-- The snapshot list the client draws (Matches:view).
function Bodies.view(c)
	local out={}
	for _,body in c.bodies or {} do
		if body.alive then
			table.insert(out,{id=body.id,owner=body.owner.id,fighterId=body.owner.fighterId,kind=body.kind,position=body.position,look=body.look,
				state=body.state,action=body.action,variant=body.variant,actionSerial=body.actionSerial,actionElapsed=c.now-(body.actionAt or c.now),
				airborne=body.airborne,velocity=body.velocity,remaining=math.max(0,body.expires-c.now),mode=body.mode,cast=body.cast,
				ephemeral=body.ephemeral,warp=body.warp})
		end
	end
	return out
end
return Bodies
