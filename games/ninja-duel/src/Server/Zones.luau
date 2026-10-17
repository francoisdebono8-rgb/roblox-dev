-- Persistent typed zones (ROSTER_WAVE_HOOKS H06), beside Combat's hazards
-- (which only burn): pieces of the arena that rewrite movement and flight for
-- a few seconds. A zone is data {kind, owner, shape, life}; KINDS says what a
-- kind does to bodies and to projectiles, the client draws each kind its own
-- way (GaleFX: wind, never fire), Combat:clear empties the list and the
-- snapshot carries it (Matches:view `zones`). First user: Temari (wind lanes,
-- updraft columns). Server authority only.
local Brawler=require(script.Parent.Brawler)
local Motor=require(script.Parent.Motor)
local Zones={}
-- Physical objects the wind turns aside, carries or sends back; fire it
-- feeds. Jutsu volumes (palms, sand waves, wind blades) go through.
local OBJECT={kunai=true,marked=true,shuriken=true,wire=true,sand=true,needle=true}
local FIRE={fireball=true,phoenix=true}
-- What a blade sent back becomes (a marked kunai loses its seal, a wire its wire).
local RETURN={kunai="kunai",marked="kunai",shuriken="shuriken",wire="shuriken",sand="sand",needle="shuriken"}
Zones.OBJECT=OBJECT;Zones.FIRE=FIRE;Zones.RETURN=RETURN
--   lane    origin (on the floor), flat direction, length, half width, height
--   column  origin (on the floor), radius, height
-- Wind: walking into it x headwind, with it x tailwind (the stick decides);
-- a free body is carried downwind (more in the air); a blade flying up it is
-- turned aside (x deflect speed, a short flight left), one riding it goes x
-- ride faster and +rideDamage; fire crossing it grows (x feed radius, x
-- feedDamage), whoever threw it. The owner gets `refund` chakra per blade
-- turned aside. Updraft: a body thrown up in it falls at `fall` at most, a free
-- airborne body is held at `hold`.
Zones.KINDS={
	Wind={shape="lane",height=9,headwind=.7,tailwind=1.15,carry=4,airCarry=11,deflect=.75,flightLeft=12,ride=1.4,rideDamage=1,feed=1.5,feedDamage=1.2,refund=2},
	Updraft={shape="column",height=18,fall=-6,hold=-4},
}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
-- spec: origin, direction, length, width, radius, height, life, carrier (a
-- projectile whose flight lays the lane: it grows as the projectile flies and
-- stops where it ended), reflect (blades going up it are sent back instead).
function Zones.add(c,owner,kind,spec)
	local tune=Zones.KINDS[kind]
	assert(tune,"Unknown zone kind "..tostring(kind))
	c.zones=c.zones or {}
	c.zoneSerial=(c.zoneSerial or 0)+1
	local direction=spec.direction and flat(spec.direction)
	local z={id=c.zoneSerial,kind=kind,tune=tune,owner=owner,origin=spec.origin,born=c.now,expires=c.now+(spec.life or 3),
		direction=if direction and direction.Magnitude>.01 then direction.Unit else Vector3.zAxis,length=spec.length or 0,
		width=spec.width or 3,radius=spec.radius or 3,height=spec.height or tune.height,carrier=spec.carrier,reflect=spec.reflect==true,
		touched=setmetatable({},{__mode="k"})}
	z.reach=if z.carrier then 0 else z.length
	table.insert(c.zones,z)
	c.urgent=true
	return z
end
-- Inside the zone? For a lane, also how far along it.
function Zones.inside(z,position)
	local d=position-z.origin
	if d.Y<-2.5 or d.Y>z.height then return false end
	if z.tune.shape=="column" then return flat(d).Magnitude<=z.radius,0 end
	local along=d.X*z.direction.X+d.Z*z.direction.Z
	if along<0 or along>z.reach then return false end
	return Vector3.new(d.X-z.direction.X*along,0,d.Z-z.direction.Z*along).Magnitude<=z.width,along
end
-- Walking with or against the wind: the multiplier on this actor's speed this
-- frame (Combat:updateActor folds it into speedScale, which Place1Movement and
-- Motor.step both read).
function Zones.speedScale(c,a)
	local list=c.zones
	if not list or #list==0 or not a.move then return 1 end
	local move=flat(a.move)
	if move.Magnitude<.2 then return 1 end
	move=move.Unit
	local scale=1
	for _,z in list do
		local tune=z.tune
		if tune.headwind and Zones.inside(z,a.root.Position) then
			local along=move:Dot(z.direction)
			scale*=if along<0 then 1+(tune.headwind-1)*-along else 1+(tune.tailwind-1)*along
		end
	end
	return scale
end
-- Fire feeds on wind: the flight goes on from here (re-announced), bigger and hotter.
function Zones.feed(c,p,owner,factor,damage)
	local radius=(p.radius or 0)+(p.growth or 0)*math.max(0,c.now-p.born)
	c:redirect(p)
	p.radius=math.max(radius,1)*factor;p.damage*=damage;p.fed=(p.fed or 0)+1
	c:pushImpact(p.position,"windfeed",false,{projectile=p.id,kind=p.kind,owner=owner.id,fighter=owner.fighterId,direction=p.direction})
	Brawler.event(c,owner,"WindFeed")
end
-- A blade sent back at its thrower: the old flight ends, a new one (owned by
-- the wind's owner) leaves from where it was.
function Zones.sendBack(c,p,owner)
	local thrower=p.a
	p.dead=true
	local index=table.find(c.projectiles,p)
	if index then table.remove(c.projectiles,index) end
	c:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=thrower.id,direction=-p.direction})
	if thrower.health<=0 or owner.target~=thrower then return nil end
	local gap=(thrower.root.Position-p.position).Magnitude
	local back=c:projectile(owner,thrower.root.Position,math.max(p.speed,80)*1.1,gap+10,p.damage,RETURN[p.kind] or "kunai",nil,{origin=p.position,radius=p.radius})
	back.bounced=true
	-- An infused blade keeps its chakra on the way back (like a ricochet).
	if p.chakra then require(script.Parent.ChakraCombat).inherit(back,p) end
	return back
end
-- One projectile entering one lane (once per lane).
local function flight(c,z,p)
	local tune=z.tune
	local owner=z.owner
	if FIRE[p.kind] then Zones.feed(c,p,owner,tune.feed,tune.feedDamage);return end
	if not OBJECT[p.kind] then return end
	local course=flat(p.direction)
	if course.Magnitude<.05 then return end
	local along=course.Unit:Dot(z.direction)
	if along<=-.35 then
		-- Up the lane: turned aside out of it, or (Kirikiri Mai) sent back.
		owner.chakra=math.min(owner.def.Chakra or 100,owner.chakra+(tune.refund or 0))
		if z.reflect then
			Zones.sendBack(c,p,owner)
			Brawler.event(c,owner,"WindReturn")
			return
		end
		local d=p.position-z.origin
		local across=Vector3.new(d.X,0,d.Z)-z.direction*(d.X*z.direction.X+d.Z*z.direction.Z)
		local side=if across.Magnitude>.2 then across.Unit else z.direction:Cross(Vector3.yAxis).Unit
		p.remaining=math.min(p.remaining,tune.flightLeft)
		c:redirect(p,z.direction*.5+side*.85+Vector3.new(0,.15,0),p.speed*tune.deflect)
		c:pushImpact(p.position,"winddeflect",false,{owner=owner.id,fighter=owner.fighterId,kind=p.kind,direction=p.direction,zone=z.id})
		Brawler.event(c,owner,"WindDeflect")
	elseif along>=.35 then
		-- Riding it: faster and harder, on the same line.
		c:redirect(p,nil,p.speed*tune.ride)
		p.damage+=tune.rideDamage
		Brawler.event(c,owner,"WindRide")
	end
end
local FREE={Neutral=true,Guarding=true,Recovery=true,Startup=true,Active=true,TechniqueChannel=true,TechniqueActive=true,TechniqueRecovery=true}
local function body(c,a,dt)
	for _,z in c.zones do
		if Zones.inside(z,a.root.Position) then
			local tune=z.tune
			if tune.carry then
				-- The wind carries a free body downwind (a dash, a chase or a
				-- reaction is its own motion).
				if not a.reaction and not a.wall and not a.grabbedBy and FREE[a.state] then
					Motor.travel(a,c,z.direction,(if a.airborne then tune.airCarry else tune.carry)*dt)
				elseif a.state=="Rush" and a.rush and not a.rush.windHeld and a.rush.goal then
					-- A chakra dash into the wind is held back (it may fall short).
					local way=flat(a.rush.goal-a.root.Position)
					if way.Magnitude>.5 and way.Unit:Dot(z.direction)<-.35 then
						a.rush.speed*=tune.headwind;a.rush.windHeld=true
						Brawler.event(c,z.owner,"WindHold")
					end
				end
			elseif tune.fall then
				local v=a.reactionVelocity
				if a.reaction and a.airborne and v and (v.Y<tune.fall or a.reaction=="Launched" or a.reaction=="Juggled") then
					-- Thrown up in it: it comes down slowly and is held while the
					-- column stands (in reach of the wind; a substitution escapes).
					if v.Y<tune.fall then a.reactionVelocity=Vector3.new(v.X*.9,tune.fall,v.Z*.9) end
					if a.reaction=="Launched" or a.reaction=="Juggled" then a.reactionUntil=math.max(a.reactionUntil or 0,c.now+.05) end
				elseif not a.reaction and a.airborne and a.state~="Pursuit" and a.state~="Rush" then
					local w=a.root.AssemblyLinearVelocity
					if w.Y<tune.hold then a.root.AssemblyLinearVelocity=Vector3.new(w.X,tune.hold,w.Z) end
				end
			end
		end
	end
end
-- Every frame, before the projectiles move: expiry, lanes laid by their
-- carrier, then bodies and flights inside the zones.
function Zones.step(c,dt)
	local list=c.zones
	if not list or #list==0 then return end
	for i=#list,1,-1 do
		local z=list[i]
		if c.now>=z.expires then
			table.remove(list,i);c.urgent=true
		elseif z.carrier then
			local p=z.carrier
			if p.dead or not table.find(c.projectiles,p) then z.carrier=nil
			else
				local d=p.position-z.origin
				z.reach=math.clamp(d.X*z.direction.X+d.Z*z.direction.Z,z.reach,z.length)
			end
		end
	end
	if #list==0 then return end
	for _,a in c.actors do
		if a.health>0 then body(c,a,dt) end
		if c.match.phase~="Duel" then return end
	end
	for _,p in table.clone(c.projectiles) do
		if not p.dead and not p.planted and (p.speed or 0)>0 then
			for _,z in list do
				if z.tune.shape=="lane" and not z.touched[p] and Zones.inside(z,p.position) then
					z.touched[p]=true
					flight(c,z,p)
					if p.dead then break end
				end
			end
		end
	end
end
-- What the client draws (each kind its own way).
function Zones.snapshot(c,now)
	local out={}
	for _,z in c.zones or {} do
		table.insert(out,{id=z.id,kind=z.kind,owner=z.owner.id,origin=z.origin,direction=z.direction,length=z.reach,width=z.width,
			radius=z.radius,height=z.height,remaining=math.max(0,z.expires-now),life=z.expires-z.born,reflect=z.reflect})
	end
	return out
end
function Zones.clear(c)
	if c.zones then table.clear(c.zones) end
end
return Zones
