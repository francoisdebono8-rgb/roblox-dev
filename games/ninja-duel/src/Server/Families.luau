-- Reusable technique families and fighter traits (ROSTER_20_BREADTH_PASS).
--
-- A technique that names a `Family` and has no bespoke Techniques.<Id> runs
-- here, driven by its own spec fields, so a new fighter is data first. The
-- core reads traits (buffs, on-hit riders, counter stances, zone effects)
-- through the few hooks below and never by fighter name. Bespoke techniques
-- (Flying Thunder God, Rotation, the Chidori...) stay in Techniques.
--
-- Families (spec.Family):
--   Projectile  Kind (Looks kind), Speed, Range, Damage, Count, Spread (rad,
--               whole fan), Radius, Growth, Launch (Combat launch point),
--               Ground (runs along the floor from the feet), Volley (s between
--               shots), plus the contact fields.
--   Strike      Move (Attacks name): a strike started by the jutsu pipeline
--               (like the Chidori thrust), Damage overrides the move's.
--   Burst       Radius, Arc (cosine, -1 = all round), Clear (enemy objects
--               in reach are destroyed), Style (contact style), at his feet;
--               Leave {Radius, Time, Damage, Kind, Look}: a zone left there.
--   Zone        At ("Self" | "Aim" | "Target"), Radius, Time, Damage (tick
--               base), ZoneKind, Slow/Drain/Seal applied per tick.
--   Buff        Time, Speed, Damage, Armor (share of damage removed), Heavy
--               (light strikes do not stagger), Regen, Heal (instant).
--   Teleport    To ("Behind" | "Side" | "Back" | "Aim"), Distance, Move
--               (strike on arrival), Invuln (s).
--   Counter     Time (window), Damage, Swap (reappears behind), contact fields:
--               a melee blow that meets the stance is answered.
-- Contact fields (Projectile, Strike, Burst, Counter): Knock, Lift, React,
-- Stun, Bind (s, held), Crush (damage when the bind ends), Drain (chakra
-- taken), Steal (share of the drain he gains), Slow {Scale, Time}, Seal (s:
-- techniques sealed), Pull (impulse toward him, never past PullTo studs in
-- front of him), Zone (left where it lands), Poison {Damage, Time, Every}
-- (damage over time, no stagger).
-- Teleport also reads Heal (instant, on arrival) and InZone (damage scale of
-- its arrival strike when the target stands in one of his own zones).
-- A Buff may carry OnHit (the same rider as def.OnHit while it lasts).
local Families={}
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Looks=require(Shared.Looks)

local function brawler() return require(script.Parent.Brawler) end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function unitOr(v,fallback)
	if v.Magnitude>.05 then return v.Unit end
	return fallback
end
local function aimOf(a,pending)
	return pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*20
end
Families.flat=flat

-- ----------------------------------------------------------- traits
-- Composition of a body's temporary traits (one policy for the twenty).
-- Two layers can be active together: a technique's buff (Buff family) and
-- the awakening's (Awakening.Buff). They are MERGED, never one hiding the
-- other, with bounded rules:
--   Heavy   either layer grants it;
--   Armor   the larger of the two (never added: 0.3 + 0.12 is not 0.42);
--   Damage, Speed   multiplied, then the whole outgoing scale including the
--           awakening's own Damage/Speed (applied by Combat) is capped at
--           Families.CAP (a buff inside an awakening still helps, it never
--           runs away);
--   Regen   the larger.
-- def.Armor (Kimimaro's bones) is a separate, permanent trait.
Families.CAP={Damage=1.4,Speed=1.35}
local TRAITS={"Heavy","Armor","Damage","Speed","Regen"}
local function layers(a,now)
	local b=a.buff
	local own=if b and now<b.untilT then b.spec else nil
	local awake=(a.awakenUntil or 0)>now and a.def.Awakening and a.def.Awakening.Buff or nil
	return own,awake
end
function Families.buff(a,now)
	local own,awake=layers(a,now)
	if not own then return awake end
	if not awake then return own end
	local merged={}
	for _,key in TRAITS do
		local x,y=own[key],awake[key]
		if key=="Heavy" then merged.Heavy=(x==true or y==true) or nil
		elseif key=="Damage" or key=="Speed" then merged[key]=if x or y then (x or 1)*(y or 1) else nil
		elseif x or y then merged[key]=math.max(x or 0,y or 0) end
	end
	return merged
end
-- The awakening's own multiplier (Combat applies it); the buff's part is
-- trimmed so that both together stay under the cap.
local function capped(a,now,key,value)
	local aw=(a.awakenUntil or 0)>now and a.def.Awakening and a.def.Awakening[key] or 1
	return math.min(value,Families.CAP[key]/aw)
end
-- Movement scale: buffs and slows (Combat sets speedScale every frame).
function Families.speedScale(a,now)
	local s=1
	local b=Families.buff(a,now)
	if b and b.Speed then s*=capped(a,now,"Speed",b.Speed) end
	if (a.slowUntil or 0)>now then s*=a.slowScale or 1 end
	return s
end
function Families.regenScale(a,now)
	local b=Families.buff(a,now)
	return (b and b.Regen) or 1
end
-- Outgoing and incoming damage: the attacker's buff, the victim's armour.
function Families.damageScale(attacker,victim,now)
	local s=1
	local b=Families.buff(attacker,now)
	if b and b.Damage then s*=capped(attacker,now,"Damage",b.Damage) end
	local armor=Families.buff(victim,now)
	if armor and armor.Armor then s*=1-armor.Armor end
	if victim.def.Armor then s*=1-victim.def.Armor end
	return s
end
-- Super armour: a light blow lands (damage) but does not stagger or interrupt.
function Families.withstands(a,now,heavy,amount)
	if heavy or amount>=12 then return false end
	local b=Families.buff(a,now)
	return b~=nil and b.Heavy==true
end
-- On-hit riders (def.OnHit, a running buff's OnHit, the awakening's OnHit):
-- merged FIELD BY FIELD, so a layer adds what it has without erasing the
-- others' (Kabuto's scalpel drain stays when his awakening adds its slow).
-- Where two layers carry the same rider the stronger wins: Drain/Steal/Heal
-- the larger, Slow the lower Scale (and the longer Time), Poison the larger
-- Damage per tick.
local function stronger(key,x,y)
	if x==nil then return y end
	if y==nil then return x end
	if key=="Slow" then
		return {Scale=math.min(x.Scale or .8,y.Scale or .8),Time=math.max(x.Time or 1.5,y.Time or 1.5)}
	elseif key=="Poison" then
		return if (y.Damage or 1)>(x.Damage or 1) then y else x
	end
	return math.max(x,y)
end
function Families.onHit(a,now)
	local own=a.buff and now<a.buff.untilT and a.buff.spec.OnHit or nil
	local awake=(a.awakenUntil or 0)>now and a.def.Awakening and a.def.Awakening.OnHit or nil
	local sources={a.def.OnHit,own,awake}
	local merged=nil
	for _,src in sources do
		if src then
			merged=merged or {}
			for key,value in src do merged[key]=stronger(key,merged[key],value) end
		end
	end
	return merged
end

-- ----------------------------------------------------------- contact
-- What a family contact does to the body it reached, once the defence has
-- resolved (damaged: the blow landed; guarded: it met a guard).
function Families.contact(c,a,b,spec,direction,damaged,guarded,position)
	if not b or b.health<=0 or c.match.phase~="Duel" then return end
	local now=c.now
	local Brawler=brawler()
	direction=unitOr(flat(direction or (b.root.Position-a.root.Position)),flat(a.root.CFrame.LookVector).Unit)
	-- Chakra drained, even through a guard (half): insects, Samehada, a palm.
	if spec.Drain and (damaged or guarded) then
		local taken=math.min(b.chakra,spec.Drain*(if guarded then .5 else 1))
		b.chakra-=taken
		if spec.Steal then a.chakra=math.min(a.def.Chakra or 100,a.chakra+taken*spec.Steal) end
		if taken>0 then c:pushImpact(b.root.Position,"drain",false,{owner=a.id,victim=b.id,amount=taken}) end
	end
	if not damaged or guarded then return end
	if spec.Slow then
		b.slowUntil=now+(spec.Slow.Time or 2);b.slowScale=spec.Slow.Scale or .7
		c:cue(b,"SLOWED",.6)
	end
	if spec.Seal then
		b.sealedUntil=math.max(b.sealedUntil or 0,now+spec.Seal)
		c:cue(b,"JUTSU SEALED",.8)
	end
	if spec.Poison then Families.poison(c,a,b,spec.Poison) end
	if spec.Zone then
		local z=spec.Zone
		local h=c:addHazard(a,position or b.root.Position,z.Radius or 6,z.Time or 3,z.Damage or 4,z.Kind or "Fire")
		h.effects=z
		h.look=z.Look
	end
	if spec.Bind then
		Families.bind(c,a,b,spec)
		return
	end
	if spec.Pull then
		-- Toward him, never past PullTo studs in front of him (a close body
		-- would otherwise be thrown behind him).
		local gap=flat(b.root.Position-a.root.Position).Magnitude
		local pull=math.min(spec.Pull,math.max(0,gap-(spec.PullTo or 3.5))*4.2)
		Brawler.react(c,b,"Knockback",-direction*pull+Vector3.yAxis*(spec.Lift or 8),spec.Stun or .45,a)
	elseif spec.Knock or spec.Lift or spec.React then
		local kind=spec.React or (if (spec.Lift or 0)>=40 then "Launched" else "Knockback")
		Brawler.react(c,b,kind,direction*(spec.Knock or 0)+Vector3.yAxis*(spec.Lift or 0),spec.Stun or .5,a)
		if kind=="Knockback" and (spec.Knock or 0)>=30 then
			a.pursuitUntil=math.max(a.pursuitUntil or 0,now+.8)
			c:cue(a,"KNOCK AWAY • E TO CHASE",.7)
		end
	end
end
-- Poison: damage over time (needles, a puppet's blades, a snake's fangs).
-- A fresh dose replaces the running one; it never staggers.
function Families.poison(c,a,b,spec)
	local every=spec.Every or .5
	local ticks=math.max(1,math.floor((spec.Time or 3)/every))
	b.poisonSerial=(b.poisonSerial or 0)+1
	local serial=b.poisonSerial
	b.poisonedUntil=c.now+ticks*every
	c:cue(b,"POISONED",.7)
	for i=1,ticks do
		c:schedule(c.now+i*every,function()
			if b.poisonSerial~=serial or b.health<=0 or a.health<=0 or c.match.phase~="Duel" then return end
			c.damageTag="poison"
			c:chip(a,b,(spec.Damage or 1))
			c.damageTag=nil
		end)
	end
end
-- Held where it stands (shadow, water prison, snakes, hounds): substitution
-- escapes, as for the Sand Coffin. Crush lands when the hold ends.
function Families.bind(c,a,b,spec)
	if b.health<=0 or (b.invulnerableUntil or 0)>c.now then return end
	local Brawler=brawler()
	local awake=(a.awakenUntil or 0)>c.now and a.def.Awakening and a.def.Awakening.BindScale or 1
	local duration=spec.Bind*awake
	Brawler.react(c,b,"Bound",Vector3.zero,duration,a)
	b.boundBy=a
	-- What holds it, for the client (hounds at the legs, a shadow, coils...).
	b.boundKind=spec.Kind or "chakra"
	local name=string.upper(spec.Name or "BOUND")
	c:cue(a,name.." • BOUND",.8);c:cue(b,"BOUND • X TO ESCAPE",.9)
	Brawler.event(c,a,"FamilyBind")
	if spec.Crush then
		c:schedule(c.now+duration-.05,function()
			if b.reaction~="Bound" or b.boundBy~=a or a.health<=0 or b.health<=0 then return end
			b.boundBy=nil
			c.damageTag=spec.Name or "bind"
			c:damage(a,b,spec.Crush,true,false)
			c.damageTag=nil
			if c.match.phase~="Duel" or b.health<=0 then return end
			Brawler.react(c,b,"Knockdown",Vector3.new(0,16,0),.7,a)
			c:pushImpact(b.root.Position,"look",true,{owner=a.id,kind=spec.Kind,victim=b.id})
		end)
	end
end

-- Is b inside one of a's own zones (hazards he left)?
function Families.inOwnZone(c,a,b)
	for _,h in c.hazards do
		if h.a==a and c.now<h.expires then
			local d=b.root.Position-h.position
			if Vector3.new(d.X,0,d.Z).Magnitude<=h.radius and math.abs(d.Y)<8 then return true end
		end
	end
	return false
end

-- Where a thrown technique flies, decided on its RELEASE frame, not on the
-- press: a cast aimed at the opponent's body (the mouse on or near him) is
-- re-aimed at where he is now, with a partial lead on his motion (spec.Lead,
-- default .55 of the flight). The channel no longer makes every jutsu miss a
-- body that merely walks; a late sidestep, a dash or a jump still beat it. An
-- aim far from the body (a zone, a lane) is kept as it was.
Families.AIM_SNAP=12
function Families.releaseAim(c,a,pending,spec)
	local aim=aimOf(a,pending)
	local b=a.target
	if not b or b.health<=0 then return aim end
	local at=b.root.Position
	if flat(aim-at).Magnitude>Families.AIM_SNAP and pending.aim then return aim end
	local motion=b.root.AssemblyLinearVelocity
	if motion.Magnitude<.5 then motion=b.locomotion or Vector3.zero end
	local flight=(at-a.root.Position).Magnitude/math.max(spec.Speed or 70,1)
	return at+flat(motion)*flight*(spec.Lead or .55)
end

-- ----------------------------------------------------------- families
local F={}
F.Projectile={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local aim=Families.releaseAim(c,a,pending,spec)
		local kind=spec.Kind or "chakra"
		local look=Looks[kind]
		local launch=spec.Launch or (look and look.launch) or (if spec.Ground then "Ground" else "Palm")
		local origin=c.launchPoint(a,launch)
		local count=spec.Count or 1
		local fan=spec.Spread or 0
		local function fire(i)
			if a.health<=0 or c.match.phase~="Duel" then return end
			local from=if (spec.Volley or 0)>0 then c.launchPoint(a,launch) else origin
			local d=aim-from
			if spec.Ground then d=flat(d) end
			d=unitOr(d,a.root.CFrame.LookVector)
			local angle=if count>1 then -fan/2+fan*(i-1)/(count-1) else 0
			if angle~=0 then d=CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(d) end
			local range=spec.Range or 40
			local p=c:projectile(a,from+d*range,spec.Speed or 70,range,spec.Damage or 4,kind,nil,{origin=from,radius=spec.Radius or (look and look.radius) or .6,growth=spec.Growth or 0})
			p.family=spec
		end
		for i=1,count do
			if (spec.Volley or 0)>0 and i>1 then c:schedule(c.now+spec.Volley*(i-1),function() fire(i) end) else fire(i) end
		end
		c:cue(a,string.upper(spec.Name),.6)
	end,
}
F.Strike={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local Brawler=brawler()
		a.stringCancel=nil
		Brawler.start(c,a,spec.Move or "JutsuStrike")
		if a.pending then
			if spec.Damage then a.pending.spec.damage=spec.Damage end
			a.pending.family=spec
		end
		c:pushImpact(a.root.Position,"afterimage",false,{owner=a.id,fighter=a.fighterId})
		c:cue(a,string.upper(spec.Name),.7)
	end,
}
F.Burst={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local reach=spec.Radius or 7
		local look=flat(a.root.CFrame.LookVector)
		look=unitOr(look,Vector3.zAxis)
		if spec.Clear then
			for i=#c.projectiles,1,-1 do
				local p=c.projectiles[i]
				if p.a~=a and not p.planted and (p.position-a.root.Position).Magnitude<=reach+2 then
					table.remove(c.projectiles,i)
					c:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=p.a.id})
				end
			end
		end
		local b=a.target
		if b and b.health>0 then
			local d=flat(b.root.Position-a.root.Position)
			local inArc=d.Magnitude<2 or look:Dot(d.Unit)>(spec.Arc or -1)
			if d.Magnitude<=reach and math.abs(b.root.Position.Y-a.root.Position.Y)<7 and inArc then
				c.damageTag=spec.Name
				local hit=c:damage(a,b,spec.Damage or 6,(spec.Damage or 6)>=12,false)
				c.damageTag=nil
				if c.match.phase~="Duel" then return end
				Families.contact(c,a,b,spec,d,hit,hit and b.impactStyle=="block",b.root.Position)
			end
		end
		c:pushImpact(a.root.Position,spec.Style or "look",true,{owner=a.id,kind=spec.Kind,radius=reach,direction=look})
		-- What the burst leaves at his feet (Leave: a zone, e.g. spiked floor).
		if spec.Leave and c.match.phase=="Duel" then
			local z=spec.Leave
			local floor=workspace:Raycast(a.root.Position+Vector3.new(0,2,0),Vector3.new(0,-30,0),c:rayParams(true))
			local at=if floor then floor.Position+Vector3.new(0,.5,0) else a.root.Position
			local h=c:addHazard(a,at,z.Radius or 6,z.Time or 3,z.Damage or 3,z.Kind or "Spikes")
			h.effects=z
			h.look=z.Look
			c:pushImpact(at,"zone",true,{owner=a.id,kind=z.Look,radius=z.Radius or 6,time=z.Time or 3})
		end
		c:cue(a,string.upper(spec.Name),.6)
	end,
}
F.Zone={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local at=spec.At or "Aim"
		local position=if at=="Self" then a.root.Position elseif at=="Target" and a.target then a.target.root.Position else aimOf(a,pending)
		local floor=workspace:Raycast(position+Vector3.new(0,4,0),Vector3.new(0,-30,0),c:rayParams(true))
		if floor then position=floor.Position+Vector3.new(0,.5,0) end
		local h=c:addHazard(a,position,spec.Radius or 8,spec.Time or 4,spec.Damage or 3,spec.ZoneKind or "Fire")
		h.effects=spec
		h.look=spec.Kind
		c:pushImpact(position,"zone",true,{owner=a.id,kind=spec.Kind,radius=spec.Radius or 8,time=spec.Time or 4})
		c:cue(a,string.upper(spec.Name),.6)
	end,
}
F.Buff={
	check=function(c,a,spec,now)
		-- Not while the same buff still runs.
		return not (a.buff and now<a.buff.untilT and a.buff.spec==spec)
	end,
	execute=function(c,a,pending)
		local spec=pending.spec
		a.buff={untilT=c.now+(spec.Time or 5),spec=spec,id=spec.Id}
		if spec.Heal then
			a.health=math.min(a.def.Health,a.health+spec.Heal);a.hum.Health=math.max(1,a.health)
		end
		c:pushImpact(a.root.Position,"buff",true,{owner=a.id,kind=spec.Kind,technique=spec.Id,time=spec.Time or 5})
		c:cue(a,string.upper(spec.Name),.8)
		brawler().event(c,a,"Buff")
	end,
}
-- A relocation onto the opponent (Behind, Side, Aim) needs the body inside
-- the technique's Range and in sight (no blinking through a wall to it); a
-- refusal happens before any cost. A step back (Back) needs neither.
Families.TELEPORT_SLACK=1.5
F.Teleport={
	check=function(c,a,spec)
		local b=a.target
		if not b or b.health<=0 then return false,"No target" end
		if (spec.To or "Behind")=="Back" then return true end
		local gap=(b.root.Position-a.root.Position).Magnitude
		if gap>(spec.Range or 30)+Families.TELEPORT_SLACK then return false,"Out of range" end
		if not c:lineOfSight(a,b) then return false,"No line of sight" end
		return true
	end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local b=a.target
		local to=spec.To or "Behind"
		local d=spec.Distance or 3.2
		local from=a.root.Position
		local line=unitOr(flat(b.root.Position-from),flat(a.root.CFrame.LookVector).Unit)
		local destination
		if to=="Behind" then destination=b.root.Position+line*d
		elseif to=="Side" then a.teleportSide=-(a.teleportSide or 1);destination=b.root.Position+line:Cross(Vector3.yAxis)*d*a.teleportSide
		elseif to=="Back" then destination=from-line*d
		else
			local aim=aimOf(a,pending)
			local off=flat(aim-from)
			destination=from+unitOr(off,line)*math.min(off.Magnitude,d)
		end
		destination=Vector3.new(destination.X,from.Y,destination.Z)
		c:relocate(a,destination)
		local face=flat(b.root.Position-a.root.Position)
		if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
		a.teleportAt=c.now
		if spec.Invuln then a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+spec.Invuln) end
		if spec.Heal then a.health=math.min(a.def.Health,a.health+spec.Heal);a.hum.Health=math.max(1,a.health) end
		local bonus=1
		if spec.InZone and Families.inOwnZone(c,a,b) then bonus=spec.InZone;c:cue(a,"FROM THE "..string.upper(spec.ZoneName or "zone"),.6) end
		c:pushImpact(destination,"teleport",false,{owner=a.id,from=from,to=destination,kind=spec.Kind})
		c:cue(a,string.upper(spec.Name),.6)
		if spec.Move then
			c:schedule(c.now+.06,function()
				if a.health<=0 or c.match.phase~="Duel" or a.reaction then return end
				brawler().start(c,a,spec.Move)
				if a.pending then
					if spec.Damage then a.pending.spec.damage=spec.Damage end
					if bonus~=1 then a.pending.spec.damage=(a.pending.spec.damage or 8)*bonus end
					a.pending.family=spec
				end
			end)
		end
	end,
}
F.Counter={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		a.counterStance={untilT=c.now+(spec.Time or .8),spec=spec}
		c:pushImpact(a.root.Position,"stance",false,{owner=a.id,kind=spec.Kind,time=spec.Time or .8})
		c:cue(a,string.upper(spec.Name),.6)
	end,
}
Families.F=F

-- ----------------------------------------------------------- core hooks
-- Combat:damage, before any defence: a counter stance answers a melee blow.
-- Returns true when the blow was taken by the stance.
function Families.beforeHit(c,attacker,victim,readEligible)
	local stance=victim.counterStance
	if not stance or c.now>=stance.untilT or not readEligible then return false end
	victim.counterStance=nil
	local spec=stance.spec
	local Brawler=brawler()
	if spec.Swap then
		local line=unitOr(flat(attacker.root.Position-victim.root.Position),flat(victim.root.CFrame.LookVector).Unit)
		local from=victim.root.Position
		c:relocate(victim,attacker.root.Position+line*3)
		victim.root.CFrame=CFrame.lookAt(victim.root.Position,Vector3.new(attacker.root.Position.X,victim.root.Position.Y,attacker.root.Position.Z))
		c:pushImpact(victim.root.Position,"teleport",false,{owner=victim.id,from=from,to=victim.root.Position,kind=spec.Kind})
	end
	attacker.pending=nil
	c.damageTag=spec.Name
	local hit=c:damage(victim,attacker,spec.Damage or 8,true,false)
	c.damageTag=nil
	if c.match.phase~="Duel" then return true end
	Families.contact(c,victim,attacker,spec,attacker.root.Position-victim.root.Position,hit,hit and attacker.impactStyle=="block",attacker.root.Position)
	if hit and not spec.Bind and not spec.Knock and not spec.Lift and not spec.React then
		Brawler.react(c,attacker,"Knockback",unitOr(flat(attacker.root.Position-victim.root.Position),Vector3.zAxis)*40+Vector3.new(0,14,0),.5,victim)
	end
	c:pushImpact(attacker.root.Position,"look",true,{owner=victim.id,kind=spec.Kind,victim=attacker.id})
	c:cue(victim,string.upper(spec.Name).." • COUNTER",.8)
	Brawler.event(c,victim,"Counter")
	return true
end
-- Combat:damage, after health was taken: the attacker's on-hit trait
-- (def.OnHit: Samehada's drain, insects on the body...).
function Families.afterHit(c,attacker,victim,amount,guarded)
	if victim.health<=0 or attacker==victim then return end
	local spec=Families.onHit(attacker,c.now)
	if not spec then return end
	if spec.Drain then
		local taken=math.min(victim.chakra,spec.Drain*(if guarded then .5 else 1))
		victim.chakra-=taken
		if spec.Steal then attacker.chakra=math.min(attacker.def.Chakra or 100,attacker.chakra+taken*spec.Steal) end
		if spec.Heal and taken>0 then attacker.health=math.min(attacker.def.Health,attacker.health+taken*spec.Heal);attacker.hum.Health=math.max(1,attacker.health) end
		if taken>0 then c:pushImpact(victim.root.Position,"drain",false,{owner=attacker.id,victim=victim.id,amount=taken}) end
	end
	if spec.Slow and not guarded then victim.slowUntil=c.now+(spec.Slow.Time or 1.5);victim.slowScale=spec.Slow.Scale or .8 end
	-- A dose that still runs is not stacked by every light of a string.
	if spec.Poison and not guarded and c.now>=(victim.poisonedUntil or 0) then Families.poison(c,attacker,victim,spec.Poison) end
end
-- Brawler.hit, after the strike's own reaction: a Strike/Teleport family move
-- adds its contact fields.
function Families.strikeHit(c,a,b,p,guarded)
	local spec=p.family or (p.spec and p.spec.riders)
	if not spec then return end
	Families.contact(c,a,b,spec,a.root.CFrame.LookVector,not guarded,guarded,b.root.Position)
end
-- Combat:updateHazards, on each tick that reached the body: the zone's riders.
function Families.zoneTick(c,h,target)
	local z=h.effects
	if not z then return end
	if z.Slow then target.slowUntil=c.now+.6;target.slowScale=z.Slow.Scale or .7 end
	if z.Drain then
		local taken=math.min(target.chakra,z.Drain)
		target.chakra-=taken
		if z.Steal then h.a.chakra=math.min(h.a.def.Chakra or 100,h.a.chakra+taken*z.Steal) end
	end
	if z.Seal then target.sealedUntil=math.max(target.sealedUntil or 0,c.now+z.Seal) end
end
-- Projectiles: a family object reports its contact (Combat:projectileHit).
function Families.projectileHit(c,p,target,damaged,guarded,position)
	if p.family then Families.contact(c,p.a,target,p.family,p.direction,damaged,guarded,position) end
end
-- Techniques: every fighter technique that names a Family and has no bespoke
-- implementation gets the family's.
function Families.install(Techniques,Fighters)
	for _,def in Fighters do
		for _,spec in def.Techniques or {} do
			if spec.Family and not Techniques[spec.Id] then
				local family=F[spec.Family]
				assert(family,"Unknown technique family "..tostring(spec.Family).." for "..tostring(spec.Id))
				Techniques[spec.Id]=family
			end
		end
	end
end
-- Lifecycle (Combat:clear: a new round, the result screen, a rematch, a
-- player who leaves): every temporary state a body carries ends there, the
-- families' own (buff, counter stance, slow, poison, the bind's look) and any
-- `...Until` window the core or a fighter module left on the actor, so
-- nothing of a round leaks into the next one (a buff, a dose still ticking).
function Families.clearState(a)
	a.buff=nil;a.counterStance=nil;a.slowScale=nil;a.boundKind=nil;a.teleportSide=nil
	-- A dose already scheduled checks its serial: a new one cancels it.
	a.poisonSerial=(a.poisonSerial or 0)+1
	for key,value in a do
		if type(key)=="string" and type(value)=="number" and string.sub(key,-5)=="Until" then a[key]=0 end
	end
end
-- Snapshot: what a body carries from the families (client auras, HUD).
function Families.snapshot(a,now)
	local b=a.buff
	return {
		buff=if b and now<b.untilT then b.id else nil,
		buffLeft=if b and now<b.untilT then b.untilT-now else 0,
		stance=if a.counterStance and now<a.counterStance.untilT then a.counterStance.spec.Id else nil,
		slowed=math.max(0,(a.slowUntil or 0)-now),
		poisoned=math.max(0,(a.poisonedUntil or 0)-now),
	}
end
return Families
