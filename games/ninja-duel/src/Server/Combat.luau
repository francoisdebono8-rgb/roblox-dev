local Shared = game:GetService("ReplicatedStorage").NinjaDuel
local Config = require(Shared.Config)
local Fighters = require(Shared.Fighters)
local Rules = require(Shared.Rules)
local World = require(script.Parent.World)
local Motor = require(script.Parent.Motor)
local Animation = require(script.Parent.Animation)
local Techniques = require(script.Parent.Techniques)
local Brawler = require(script.Parent.Brawler)
local Bangla = require(script.Parent.BanglaCombat)
local Evade = require(script.Parent.BanglaEvade)
local HitDetection = require(script.Parent.VelmoraHitDetection)
local Defense = require(script.Parent.VelmoraDefense)
local Combat = {}; Combat.__index = Combat
function Combat.new(match)
	return setmetatable({match=match,now=0,actors={},effects={},projectiles={},hazards={},historyAt=0,impacts={},impactSerial=0,projectileSerial=0},Combat)
end
-- Where a thrown or breathed object physically leaves the body. Server-side
-- approximation of the animated hand/mouth so the projectile's first frame is
-- where the throwing arm actually is, not the middle of the chest.
local LAUNCH={
	Kunai={side=1.15,up=.95,forward=1.1},MarkedKunai={side=1.15,up=1.05,forward=1.1},Palm={side=.2,up=.9,forward=1.9},Ground={side=0,up=-2.2,forward=2.2},
	Shuriken={side=-1.1,up=.9,forward=1.2},Fireball={side=0,up=2.1,forward=2.6},Wind={side=.6,up=1,forward=2.2},
}
function Combat.launchPoint(a,kind)
	local spec=LAUNCH[kind] or {side=0,up=.6,forward=1.4}
	local cf=a.root.CFrame
	return cf.Position+cf.RightVector*spec.side+Vector3.yAxis*spec.up+cf.LookVector*spec.forward
end
-- `kit` (optional) is a validated skill build from SkillBuilds: its own copy
-- of the definition and move graph with the active nodes applied. Without one
-- the actor reads Fighters/MoveGraphs directly: today's fighter, unchanged.
function Combat:add(id,model,hum,root,joints,definition,kit)
	assert(kit==nil or kit.fighterId==definition,"Skill build does not belong to "..tostring(definition))
	local def = if kit then kit.def else Fighters[definition]
	if kit then hum.MaxHealth=def.Health;hum.Health=def.Health;hum.WalkSpeed=def.Speed end
	local a = { id=id,fighterId=definition,model=model,hum=hum,root=root,joints=joints,def=def,health=def.Health,
		graph=kit and kit.graph,build=kit and {nodes=table.clone(kit.nodes),spent=kit.spent,bracket=kit.bracket},
		chakra=def.Chakra or Config.Chakra,state="Neutral",untilTime=0,lockUntil=0,cooldowns={},move=Vector3.zero,
		combo=0,lastAttack=-10,readUntil=0,illusionUntil=0,bonusUntil=0,dodgeUntil=0,invulnerableUntil=0,
		color=Color3.fromRGB(table.unpack(def.Color)),guardHeld=false,lastMove=0, cue="",cueUntil=0,
		locomotion=Vector3.zero,sprinting=false,airborne=false,airDodgeUsed=false,landUntil=0,
		pursuitUntil=0,travelRemaining=0,travelDirection=Vector3.zero,chainOpen=false,hitConfirmed=false,airHold=0,
		subCharges=Config.Substitution.Charges,subCooldown=0,subRegenAt=math.huge,lastHurt=-10,neutralToolAt=0,wall=nil,wallNext=0,
		comboHits=0,comboDamage=0,anchors={},
		shieldCharges=def.SandShield and def.SandShield.Charges or 0,shieldRegenAt=0 }
	table.insert(self.actors,a)
	Defense.init(a)
	-- The client motion engine owns every pose. Server Animator tracks (Roblox
	-- default walk/run/idle, donor punches) replicate to clients and overwrote
	-- that motion, so they only play when explicitly enabled.
	if Config.DonorAnimations then Animation.attach(a) end
	return a
end
-- The tournament stage is round: positions are held inside a circle so no
-- corner of the old square limit reaches into the stands.
function Combat:clamp(p)
	local o=self.match.origin; local r=Config.ArenaRadius
	local flat=Vector3.new(p.X-o.X,0,p.Z-o.Z)
	if flat.Magnitude>r then flat=flat.Unit*r end
	return Vector3.new(o.X+flat.X,math.clamp(p.Y,o.Y+3,o.Y+Config.ArenaHeight),o.Z+flat.Z)
end
function Combat:relocate(a,p)
	-- A real teleport (seal, substitution, setup): the client snaps on it and
	-- smooths everything else.
	a.warpSerial=(a.warpSerial or 0)+1
	local look=a.root.CFrame.LookVector
	a.model:PivotTo(CFrame.lookAt(self:clamp(p),self:clamp(p)+Vector3.new(look.X,0,look.Z)))
	a.root.AssemblyLinearVelocity=Vector3.zero
end
function Combat:rayParams(excludeActors)
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={self.match.effects}
	if excludeActors then for _,a in self.actors do table.insert(exclude,a.model) end end
	params.FilterDescendantsInstances=exclude
	return params
end
function Combat:overlapParams()
	local p=OverlapParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={self.match.effects}; for _,a in self.actors do table.insert(exclude,a.model) end
	p.FilterDescendantsInstances=exclude; return p
end
function Combat:lineOfSight(a,b)
	local delta=b.root.Position-a.root.Position
	return workspace:Raycast(a.root.Position,delta,self:rayParams(true)) == nil
end
function Combat:targetValid(a,b,range,facing)
	if not b or b.health<=0 then return false end
	local roots={};for _,candidate in self.actors do table.insert(roots,candidate.root) end
	local angle=math.deg(math.acos(math.clamp(facing,-1,1)))
	-- Resolve each active-window sample against the newest recorded pose; the short
	-- history keeps interpolation stable without freezing a target at button-down.
	local root=HitDetection.resolve(a.root,range,angle,a.root.Position,a.root.CFrame.LookVector,self.now,roots,self.match.effects)
	return root==b.root
end
-- Server effects are logical markers only (anchor, echo, hitbox lifetimes).
-- Everything the player sees is drawn by the client from the snapshot and the
-- contact feed; the old translucent neon blocks read as debug geometry.
function Combat:effect(name,p,color,size,lifetime)
	local v=World.part(self.match.effects,name,size,CFrame.new(p),color,Enum.Material.Neon)
	v.CanCollide=false; v.CanQuery=false; v.CanTouch=false; v.Transparency=1; v.CastShadow=false
	table.insert(self.effects,{part=v,expires=self.now+lifetime})
	return v
end
function Combat:addHazard(a,position,radius,duration,damage,kind)
	local hazard={a=a,position=position,radius=radius,expires=self.now+duration,damage=damage,kind=kind,lastHit={}}
	table.insert(self.hazards,hazard)
	return hazard
end
-- Hitstop budget by impact weight. Only the defender stops, and only briefly:
-- freezing both actors on every light made a normal combo read as
-- move -> stop -> move -> stop.
local HITSTOP={light=0,air=0,block=.01,finisher=.05,launcher=.06,parry=.075,slam=.09,jutsu=.065,default=.025}
Combat.Hitstop=HITSTOP
function Combat:applyHitstop(attacker,victim,style,heavy)
	local stop=HITSTOP[style] or (if heavy then HITSTOP.default else 0)
	if stop<=0 then return stop end
	victim.hitstopUntil=math.max(victim.hitstopUntil or 0,self.now+stop)
	-- The attacker only joins on a genuinely heavy contact.
	if heavy then attacker.hitstopUntil=math.max(attacker.hitstopUntil or 0,self.now+stop*.5) end
	return stop
end
-- Short feed of contacts that actually happened. Snapshots carry it so the
-- client can layer sound and VFX on the real contact frame, never on the press.
function Combat:pushImpact(position,style,heavy,extra)
	local feed=self.impacts or {}
	self.impacts=feed
	self.impactSerial=(self.impactSerial or 0)+1
	local role="neutral"
	for _,actor in self.actors do
		if actor.root and (actor.root.Position-position).Magnitude<4.5 then
			role=if actor.health>0 then "victim" else "neutral"
			break
		end
	end
	local entry={style=style,at=self.now,position=position,heavy=heavy==true,serial=self.impactSerial,role=role}
	-- Optional context (projectile id, surface normal, teleport endpoints, owner)
	-- so the client can finish the exact object it was drawing.
	if extra then for k,v in extra do entry[k]=v end end
	table.insert(feed,entry)
	while #feed>12 do table.remove(feed,1) end
	-- Contacts are worth a snapshot now rather than at the next 50 ms tick.
	self.urgent=true
	return self.impactSerial
end
function Combat:cue(a,message,duration)
	a.cue=message; a.cueUntil=self.now+(duration or 1.1)
	if self.match.onCue then self.match.onCue(a,message) end
end
function Combat:setState(a,state,duration)
	a.state=state; a.untilTime=self.now+duration
	-- Chain and cancel windows belong to the attack recovery that computes them
	-- right after this call; any other state change must not inherit stale ones
	-- (a substitution or awaken recovery used to open a string-cancel). The
	-- same holds for a re-engage arrival (Brawler.arrive sets it after this).
	a.chainOpen=false; a.recoveryCancelAt=nil; a.arrivalRecovery=nil
end
-- Strikes that crack Gaara's sand shield outright (the rest each cost a charge).
local SHIELD_BREAKERS={Heavy=true,Launcher=true,Light3=true,Slam=true,KneeStrike=true,FlyingKick=true,PalmThrust=true,CounterPalm=true,WallDive=true,SandPillar=true}
function Combat:damage(attacker,victim,amount,heavy,readEligible)
	if self.match.phase~="Duel" or self.match.finishing or victim.health<=0 or attacker.health<=0 then return false end
	-- Inside Rotation nothing reaches Neji; the dome answers on its own step.
	if (victim.rotationUntil or 0)>self.now then return false end
	if victim.wall then Motor.detach(victim,self.now,false) end
	-- A blade is judged from where it came from (a redirected shuriken reaches
	-- the flank even when the thrower stands in front).
	local delta=(self.hitOrigin or attacker.root.Position)-victim.root.Position
	local frontal=delta.Magnitude<0.1 or victim.root.CFrame.LookVector:Dot(delta.Unit)>0.15
	-- Byakugan: the guard covers every side but a narrow blind spot behind.
	if victim.def.Byakugan and delta.Magnitude>=0.1 then
		local full=(victim.awakenUntil or 0)>self.now and victim.def.Awakening and victim.def.Awakening.NoBlindSpot
		frontal=full or victim.root.CFrame.LookVector:Dot(delta.Unit)>-victim.def.Byakugan.BlindSpot
	end
	-- Sharingan tracking: a raised guard follows a teleport instead of being crossed up.
	if not frontal and victim.def.Sharingan and victim.guardHeld and attacker.teleportAt and self.now-attacker.teleportAt<.7 then
		frontal=true
		local flat=Vector3.new(delta.X,0,delta.Z)
		if flat.Magnitude>.1 then victim.root.CFrame=CFrame.lookAt(victim.root.Position,victim.root.Position+flat) end
		self:cue(victim,"SHARINGAN • TRACKED",.7)
	end
	-- Sharingan Read: the blow is seen coming (VelmoraDefense.read).
	if readEligible and frontal and victim.readUntil>self.now then return Defense.read(self,attacker,victim) end
	-- Gaara's sand shield stops the hit by itself while it has charges.
	local shield=victim.def.SandShield
	-- Not while he is attacking or recovering from it: a whiffed lash is the opening.
	if shield and (victim.shieldCharges or 0)>0 and victim.state~="Startup" and victim.state~="Active" and victim.state~="Recovery" and victim.state~="Stunned"
		and not victim.reaction and not victim.grabbedBy and victim.invulnerableUntil<=self.now then
		local breaking=heavy or amount>=shield.Break or SHIELD_BREAKERS[attacker.attackName or ""]==true
		victim.shieldCharges=if breaking then 0 else victim.shieldCharges-1
		victim.shieldRegenAt=self.now+shield.Regen
		-- The sand absorbs the blow but the string keeps its rhythm: pressing on
		-- (light, light, third hit) is how the shield is cracked.
		attacker.hitConfirmed=true
		local face=if delta.Magnitude>.1 then delta.Unit else victim.root.CFrame.LookVector
		self:pushImpact(victim.root.Position+face*1.6,"sandshield",breaking,{owner=victim.id,direction=face})
		Brawler.event(self,victim,"SandShield")
		if breaking then
			self:setState(victim,"Stunned",.5)
			self:cue(victim,"SAND SHIELD BROKEN",.8);self:cue(attacker,"SAND SHIELD BROKEN",.8)
		else self:cue(victim,"SAND SHIELD",.4) end
		return false
	end
	local counterBefore=victim.counterUntil
	local outcome,resolved=Defense.resolve(self,attacker,victim,amount,frontal,readEligible)
	-- Skill build (Mirage Reflex): the read that just opened a Sharingan counter
	-- also leaves a genjutsu decoy while awakened.
	if (outcome=="Evaded" or outcome=="Parried") and victim.counterUntil~=counterBefore then self:reflexEcho(victim,attacker) end
	-- A guard break keeps its full stun through the melee reaction that follows.
	if outcome=="GuardBreak" then victim.stunFloorUntil=victim.untilTime end
	if outcome=="Evaded" then Brawler.event(self,victim,"Evaded");self:cue(victim,"EVADED");return false end
	if outcome=="Parried" then
		Brawler.event(self,victim,"Parry")
		if readEligible then Brawler.event(self,attacker,"Parried") end
		local style=if readEligible then "parry" else "deflect"
		victim.impactStyle=style;victim.impactAt=self.now
		self:pushImpact(victim.root.Position,style,false)
		self:effect("Parry",victim.root.Position,Color3.fromRGB(255,236,145),Vector3.new(3.8,3.8,3.8),.16)
		if readEligible then self:parryRider(victim,attacker) end
		return false
	end
	amount=resolved
	local guarded=outcome=="Blocked"
	if guarded then
		self:cue(victim,"GUARDED")
	else
		local interrupted=Rules.interruptible(victim)
		local protected= victim.state=="TechniqueChannel" and victim.pending and not victim.pending.spec.Interruptible
		if not protected then
			Brawler.releaseGrab(victim)
			victim.pending=nil; victim.readUntil=0; victim.guardHeld=false
			if outcome~="GuardBreak" then self:setState(victim,"Stunned",if interrupted then Config.InterruptStun else Config.HitStun) end
			if interrupted then victim.stunFloorUntil=victim.untilTime end
			if interrupted then victim.interruptedAt=self.now; Brawler.event(self,attacker,"Interrupt"); self:cue(victim,"INTERRUPTED"); self:cue(attacker,"CHANNEL INTERRUPTED") end
		end
	end
	if attacker.bonusUntil>self.now then amount*=1.35; attacker.bonusUntil=0 end
	if (attacker.awakenUntil or 0)>self.now then amount*=attacker.def.Awakening.Damage or 1 end
	-- An awakening with a price (the Curse Mark): the body that carries it takes more.
	if (victim.awakenUntil or 0)>self.now and victim.def.Awakening then amount*=1+(victim.def.Awakening.Vulnerability or 0) end
	-- Combo scaling: the opening hits of a combo land in full, every later hit
	-- is worth less. Long routes stay possible; they just stop being lethal.
	if not guarded then
		local tune=Config.ComboScaling
		local n=victim.comboHits or 0
		if n>=tune.Free then amount*=math.max(tune.Floor,1-tune.Step*(n-tune.Free+1)) end
		victim.comboHits=n+1;victim.comboDamage=(victim.comboDamage or 0)+amount;victim.comboBy=attacker
	end
	victim.lastHurt=self.now
	victim.health=math.max(0,victim.health-amount); victim.hum.Health=math.max(1,victim.health)
	-- Studio tooling only: where damage comes from, to tune fight length.
	if self.damageLog then table.insert(self.damageLog,{t=self.now,by=attacker.fighterId,amount=amount,tag=self.damageTag or "other",hits=victim.comboHits}) end
	victim.impactSerial=(victim.impactSerial or 0)+1; victim.impactHeavy=heavy or amount>=12
	local style=(if guarded then "block" elseif heavy and amount>=16 then "slam" elseif heavy then "launcher" elseif amount>=20 then "finisher" else "light")
	victim.impactStyle=style
	victim.impactAt=self.now
	-- Direction and weight of the contact so the victim's body can answer the
	-- hit it actually took instead of playing one generic recoil.
	local toward=Vector3.new(delta.X,0,delta.Z)
	if toward.Magnitude>.05 then
		victim.hitFrom=toward.Unit
		local facing=Vector3.new(victim.root.CFrame.LookVector.X,0,victim.root.CFrame.LookVector.Z)
		if facing.Magnitude>.05 then
			facing=facing.Unit
			victim.hitAngle=math.deg(math.atan2(facing:Cross(victim.hitFrom).Y,facing:Dot(victim.hitFrom)))
		else
			victim.hitAngle=0
		end
	else
		victim.hitFrom=Vector3.zAxis
		victim.hitAngle=0
	end
	victim.hitStrength=math.clamp(amount/26,0,1)
	-- Seed the stop; Brawler adds the exact per-move weight once it knows the move.
	self:applyHitstop(attacker,victim,style,heavy)
	self:pushImpact(victim.root.Position,style,victim.impactHeavy)
	Brawler.event(self,attacker,"Damage"); if guarded then Brawler.event(self,victim,"GuardHit") end
	self:effect("Impact",victim.root.Position,if guarded then Color3.fromRGB(221,203,152) else attacker.color,Vector3.new(2,2,2),0.12)
	if heavy and not guarded and victim.health>0 then
		attacker.pursuitUntil=self.now+Config.PursuitWindow
		self:cue(attacker,"LAUNCH • E TO PURSUE",Config.PursuitWindow)
		local push=Vector3.new(-delta.X,0,-delta.Z)
		if push.Magnitude>0.1 then Brawler.react(self,victim,"Launched",push.Unit*22+Vector3.new(0,42,0),.9) end
	end
	if victim.health<=0 then
		Brawler.releaseGrab(victim); victim.reaction=nil
		victim.state="Defeated"; victim.pending=nil; victim.move=Vector3.zero
		-- Remember the blow that ended it so the KO body matches the final hit.
		victim.koStyle=style
		victim.koAirborne=victim.airborne==true
		-- The last blow freezes for a beat on both bodies.
		attacker.hitstopUntil=self.now+.22;victim.hitstopUntil=self.now+.22
		attacker.pending=nil;attacker.move=Vector3.zero
		self.match.finish(attacker,victim)
	end
	attacker.hitConfirmed=true
	return true
end
function Combat:strike(a,damage,range,facing,heavy)
	if self:targetValid(a,a.target,range,facing) then return self:damage(a,a.target,damage,heavy,true) end
	return false
end
-- Skill-build hooks (SkillBuilds.OPTIONAL). Each reads one optional field of
-- the actor's definition; canonical kits never carry these fields.
-- Parry riders: ParrySeal (Minato) seals the stunned attacker for a teleport;
-- ParryRedirect (Neji) turns him aside, closes a point and opens a counter.
function Combat:parryRider(victim,attacker)
	if attacker.health<=0 then return end
	local seal=victim.def.ParrySeal
	if seal then
		local entry=Techniques.plant(self,victim,attacker.root.Position,Vector3.yAxis,attacker)
		entry.expires=self.now+seal
		self:cue(victim,"PARRY • SEALED • 2 TO FOLLOW",.8)
		Brawler.event(self,victim,"ParrySeal")
	end
	local redirect=victim.def.ParryRedirect
	if redirect then
		local away=attacker.root.Position-victim.root.Position;away=Vector3.new(away.X,0,away.Z)
		if away.Magnitude>.1 then
			-- A quarter turn aside: his chest no longer faces the palm that follows.
			local aside=Vector3.new(-away.Z,0,away.X).Unit
			attacker.root.CFrame=CFrame.lookAt(attacker.root.Position,attacker.root.Position+aside)
		end
		if victim.def.GentleFist then for _=1,redirect.Points or 1 do Brawler.gentleFist(self,victim,attacker,false) end end
		if redirect.Counter then victim.counterUntil=math.max(victim.counterUntil or 0,self.now+redirect.Counter) end
		self:pushImpact(attacker.root.Position,"deflect",false,{owner=victim.id})
		self:cue(victim,"REDIRECTED • COUNTER",.8);self:cue(attacker,"REDIRECTED",.6)
		Brawler.event(self,victim,"Redirect")
	end
end
-- Mirage Reflex (Itachi's awakening): the clean read that just opened a
-- Sharingan counter leaves a genjutsu decoy on the attacker.
function Combat:reflexEcho(victim,attacker)
	local tune=victim.def.Awakening
	local reflex=tune and tune.Reflex
	if not reflex or (victim.awakenUntil or 0)<=self.now or attacker==victim or attacker.health<=0 or attacker.def.Byakugan then return end
	attacker.illusionUntil=self.now+reflex
	attacker.decoyPosition=self:clamp(victim.root.Position+victim.root.CFrame.RightVector*5)
	self:effect("Echo",attacker.decoyPosition,victim.color,Vector3.new(2,5,1),reflex)
	self:pushImpact(victim.root.Position,"mirage",false,{owner=victim.id,fighter=victim.fighterId,to=attacker.decoyPosition})
	self:cue(victim,"FOCUS • MIRAGE REFLEX",.8);self:cue(attacker,"MIRAGE • TRUST THE BODY",reflex)
	Brawler.event(self,victim,"MirageReflex")
end
-- Blood for Chakra (Sasuke's Curse Mark): awakened, the chakra a technique
-- lacks is paid with health, never down to a KO.
function Combat:curseBlood(a,spec)
	local tune=a.def.Awakening
	if not (tune and tune.BloodChakra) or (a.awakenUntil or 0)<=self.now or a.chakra>=spec.Cost then return false end
	if (a.cooldowns[spec.Id] or 0)>self.now or (a.sealedUntil or 0)>self.now or self.match.techniquesDisabled then return false end
	local debt=spec.Cost-a.chakra
	if a.health<=debt+1 then return false end
	a.health-=debt;a.hum.Health=math.max(1,a.health);a.chakra=spec.Cost
	self:cue(a,"CURSE MARK • BLOOD FOR CHAKRA",.8)
	Brawler.event(self,a,"BloodChakra")
	return true
end
-- Air Exit (Minato): Tool during a teleport arrival in the air throws a marked
-- kunai straight down; where it lands becomes a seal. nil when not applicable.
function Combat:arrivalThrow(a)
	local throw=a.def.ArrivalThrow
	if not throw or (a.flashUntil or 0)<=self.now or not a.airborne or a.throwing
		or (a.state~="TechniqueRecovery" and a.state~="TechniqueActive") then return nil end
	if a.chakra<Config.ToolCost then return false,"Need chakra" end
	a.chakra-=Config.ToolCost
	a.flashUntil=0;a.pending=nil;self:setState(a,"Neutral",0)
	a.neutralToolAt=self.now+((a.def.ToolMastery and a.def.ToolMastery.Recover) or .55)
	local below=Vector3.new(a.root.Position.X,self.match.origin.Y,a.root.Position.Z)
	self:beginThrow(a,{kind="MarkedKunai",release=.08,count=1,aim=below,fire=function(_,target)
		self:projectile(a,target,96,40,throw.Damage or 2,"marked",function(position,normal,victim)
			if a.health<=0 or self.match.phase~="Duel" then return end
			Techniques.plant(self,a,position,normal,victim)
		end)
	end})
	self:cue(a,"SEAL BELOW",.6)
	Brawler.event(self,a,"ArrivalThrow")
	return true
end
-- Chakra infusion and projectile interactions (ChakraCombat over the rules
-- Codex prepared): infused throws, meetings in flight, planted points, wire.
local Chakra=require(script.Parent.ChakraCombat)
-- Projectile kinds: "kunai", "marked" (Minato's seal kunai), "shuriken",
-- "fireball" and "wind". Legacy names ("blade", "needle", "tool") still work.
local KIND_ALIAS={blade="marked",needle="shuriken",tool="kunai"}
local LAUNCH_FOR={kunai="Kunai",marked="MarkedKunai",shuriken="Shuriken",fireball="Fireball",wind="Wind"}
-- Straight, constant-speed flights: the client reproduces the exact path from
-- (origin, direction, speed, born) and only needs the end event from the feed.
function Combat:projectile(a,aim,speed,range,damage,kind,onSurface,opts)
	opts=opts or {}
	kind=KIND_ALIAS[kind] or kind
	local start=opts.origin or Combat.launchPoint(a,LAUNCH_FOR[kind] or "Kunai")
	local delta=aim-start
	if delta.Magnitude<0.1 then delta=a.root.CFrame.LookVector end
	self.projectileSerial=(self.projectileSerial or 0)+1
	local p={id=self.projectileSerial,a=a,origin=start,position=start,direction=delta.Unit,speed=speed,range=range,remaining=range,
		damage=damage,onSurface=onSurface,kind=kind,born=self.now,radius=opts.radius or 0,growth=opts.growth or 0,
		reaction=opts.reaction,impulse=opts.impulse,explode=opts.explode,heavy=opts.heavy,
		-- Skill-build riders (chase, chakra point, wall pin, bind): see projectileRiders.
		riders=opts.riders}
	-- A chakra plan (Chakra.plan / Chakra.innate) changes how this object flies
	-- and what it does on contact; without one the throw is the plain one.
	if opts.chakra then Chakra.arm(self,p,opts.chakra) end
	table.insert(self.projectiles,p)
	self.urgent=true
	return p
end
function Combat:removeProjectile(p)
	for i=#self.projectiles,1,-1 do
		if self.projectiles[i]==p then table.remove(self.projectiles,i) end
	end
end
-- The marked kunai that is still travelling, if any: Minato can relocate onto
-- it mid-flight, which is the whole point of the seal.
function Combat:markedInFlight(a)
	for _,p in self.projectiles do
		if p.a==a and p.kind=="marked" then return p end
	end
	return nil
end
-- Throws keep the thrower in Neutral so locomotion continues: the arm releases
-- on its authored frame while the legs keep running.
function Combat:beginThrow(a,spec)
	a.throwSerial=(a.throwSerial or 0)+1
	a.throwing={kind=spec.kind,started=self.now,release=self.now+spec.release,nextRelease=self.now+spec.release,
		count=spec.count or 1,fired=0,interval=spec.interval or .07,aim=spec.aim,fire=spec.fire,serial=a.throwSerial}
	a.throwKind=spec.kind;a.throwStarted=self.now;a.throwRelease=spec.release
	self.urgent=true
end
function Combat:stepThrow(a)
	local throw=a.throwing
	if not throw then return end
	if a.health<=0 or a.reaction or a.state=="Stunned" or a.state=="Defeated" or a.state=="Dodging" then
		a.throwing=nil;return
	end
	while a.throwing==throw and self.now>=throw.nextRelease and throw.fired<throw.count do
		throw.fired+=1
		-- Re-aim at release against the live target, unless an explicit point was
		-- chosen: a throw tracks the opponent the arm is actually throwing at.
		local aim=throw.aim or (a.target and a.target.root.Position) or (a.root.Position+a.root.CFrame.LookVector*20)
		throw.fire(throw.fired,aim)
		throw.nextRelease+=throw.interval
	end
	if a.throwing==throw and throw.fired>=throw.count then a.throwing=nil end
end
-- Facing while locked on. Small moves around the opponent are strafes with
-- the chest on them; a committed run (held away from them, sprinting, or from
-- far) turns the body into the run, three-quarters toward the opponent, so a
-- fighter never slides around a point like a mannequin. The turn is
-- progressive; guarding always squares up.
-- Turn the root toward a flat direction at a bounded angular speed (deg/s).
-- Instant lookAt writes read as the body teleporting its facing (measured up
-- to 175 degrees in one frame) and drag the planted feet with them.
function Combat:turnToward(a,direction,dt,rate)
	local want=Vector3.new(direction.X,0,direction.Z)
	if want.Magnitude<.01 then return end
	want=want.Unit
	local current=Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z)
	current=if current.Magnitude>.01 then current.Unit else want
	local angle=math.atan2(current:Cross(want).Y,current:Dot(want))
	local step=math.clamp(angle,-math.rad(rate)*dt,math.rad(rate)*dt)
	local look=CFrame.fromAxisAngle(Vector3.yAxis,step):VectorToWorldSpace(current)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+look)
end
function Combat:faceLocked(a,dt)
	local toward=a.target.root.Position-a.root.Position;toward=Vector3.new(toward.X,0,toward.Z)
	if toward.Magnitude<.1 then return end
	local target=toward.Unit
	local distance=toward.Magnitude
	local intent=Vector3.new(a.move.X,0,a.move.Z)
	local desired=target
	local committed=false
	if a.state=="Neutral" and intent.Magnitude>.4 then
		local moveDir=intent.Unit
		local along=target:Dot(moveDir) -- 1 toward, -1 away, 0 around
		if along<.55 then a.awayHeld=(a.awayHeld or 0)+dt else a.awayHeld=0 end
		committed=a.sprinting or (a.awayHeld or 0)>.3 or (distance>16 and along<.55)
		-- Close in and retreating a step: a backpedal keeps the chest on them.
		if along<-.5 and distance<10 and not a.sprinting then committed=false end
		if committed then
			local look=if distance<12 then .45 else .2
			desired=(moveDir+target*look).Unit
		end
	else a.awayHeld=0 end
	local current=Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z)
	if current.Magnitude<.01 then current=desired end
	current=current.Unit
	local angle=math.atan2(current:Cross(desired).Y,current:Dot(desired))
	local rate=math.rad(if committed then 540 else 760)*dt
	local turn=math.clamp(angle,-rate,rate)
	local look=CFrame.fromAxisAngle(Vector3.yAxis,turn):VectorToWorldSpace(current)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+look)
	a.facingCommitted=committed
end
-- Kawarimi. A limited escape from a combo: two charges that come back one at a
-- time, a chakra cost, and a short tracking window for the attacker so a
-- predictable substitution can still be punished. Each prodigy reappears in
-- his own way: Minato on a planted seal if he has one, Itachi as a crow clone
-- behind the attacker, otherwise a short hop away.
function Combat:substitute(a)
	local tune=Config.Substitution
	if a.subCharges<=0 then return false,"No substitution" end
	if self.now<a.subCooldown then return false,"Substitution recovering" end
	if a.chakra<tune.Cost then return false,"Need chakra" end
	local hurt=(a.reaction~=nil and a.reaction~="Wakeup" and not (a.reaction=="Knockdown" and not a.airborne))
		or a.state=="Stunned" or self.now-a.lastHurt<=tune.Window
	if not hurt then return false,"No escape window" end
	local attacker=a.target
	local departure=a.root.Position
	local destination,mode=nil,"hop"
	-- Skill-build twist (SkillBuilds def.Substitution); nil for canonical kits.
	local twist=a.def.Substitution
	local seal=a.fighterId=="Flashstep" and Techniques.escapeSeal(self,a,self.now)
	if seal then
		destination=self:clamp(seal.position);mode="seal"
	elseif a.fighterId=="Mirage" and attacker and attacker.health>0 then
		local back=-attacker.root.CFrame.LookVector*Vector3.new(1,0,1)
		if back.Magnitude>.1 then
			local spot=self:clamp(Vector3.new(attacker.root.Position.X,self.match.origin.Y+3,attacker.root.Position.Z)+back.Unit*5.5)
			if self:openSpot(attacker,spot) then destination=spot;mode="crow" end
		end
	elseif twist and twist.Mode=="flank" and attacker and attacker.health>0 then
		-- Neji's outside step: reappear on the attacker's flank, on the side he
		-- was already on, else the other one.
		local right=attacker.root.CFrame.RightVector*Vector3.new(1,0,1)
		if right.Magnitude>.1 then
			right=right.Unit
			local first=if (a.root.Position-attacker.root.Position):Dot(right)>=0 then 1 else -1
			for _,sign in {first,-first} do
				local spot=self:clamp(Vector3.new(attacker.root.Position.X,self.match.origin.Y+3,attacker.root.Position.Z)+right*sign*5)
				if self:openSpot(attacker,spot) then destination=spot;mode="flank";break end
			end
		end
	end
	if destination then
		self:relocate(a,destination)
	else
		local away=a.root.Position-(if attacker then attacker.root.Position else a.root.Position-a.root.CFrame.LookVector)
		away=Vector3.new(away.X,0,away.Z)
		if away.Magnitude<0.1 then away=a.root.CFrame.RightVector end
		-- Pinned against a wall the straight escape is blocked: slide along it.
		local moved=Motor.travel(a,self,away,tune.Distance)
		if moved<2 then
			local side=Vector3.new(-away.Z,0,away.X)
			moved=Motor.travel(a,self,side,tune.Distance)
			if moved<2 then moved=Motor.travel(a,self,-side,tune.Distance) end
		end
		if moved<2 then return false,"Escape blocked" end
	end
	if attacker then
		local face=attacker.root.Position-a.root.Position;face=Vector3.new(face.X,0,face.Z)
		if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
	end
	if a.subCharges>=tune.Charges then a.subRegenAt=self.now+tune.Recharge end
	a.subCharges-=1; a.chakra-=tune.Cost; a.subCooldown=self.now+tune.Cooldown
	a.subUntil=self.now+0.17
	Brawler.releaseGrab(a); a.reaction=nil; a.reactionVelocity=nil; a.airHold=0; a.throwing=nil;a.groundPose=nil
	a.airborne=a.root.Position.Y>self.match.origin.Y+4.2
	if seal then Techniques.consumeSeal(self,a,seal) end
	-- Skill-build twist riders: a seal left where he stood (Return Seal), a
	-- counter window (Crow Counter, Outside Step), a free counter-rush.
	local extra=""
	if twist then
		if twist.PlantDeparture then
			Techniques.plant(self,a,Vector3.new(departure.X,self.match.origin.Y,departure.Z),Vector3.yAxis)
			extra=" • SEAL LEFT"
		end
		if twist.Counter then a.counterUntil=self.now+twist.Counter;extra=extra.." • COUNTER" end
		if twist.FreeRush then a.freeRushUntil=self.now+twist.FreeRush;extra=extra.." • E: COUNTER-RUSH" end
	end
	Brawler.event(self,a,"Substitute"); a.pending=nil; a.guardHeld=false; a.invulnerableUntil=self.now+0.24
	a.comboHits=0;a.comboDamage=0
	self:setState(a,"Recovery",0.14)
	-- The attacker may read the reappearance: a short chase window.
	if attacker and attacker.health>0 then
		attacker.pursuitUntil=math.max(attacker.pursuitUntil,self.now+tune.Track)
		self:cue(attacker,"SUBSTITUTION • E TO TRACK",tune.Track)
	end
	self:pushImpact(departure,"substitute",false,{owner=a.id,fighter=a.fighterId,to=a.root.Position,mode=mode})
	self:effect("Afterimage",departure,a.color,Vector3.new(2,4,2),0.35)
	self:effect("Substitution",a.root.Position,a.color,Vector3.new(3,4,3),0.25)
	self:cue(a,(if mode=="seal" then "SUBSTITUTION • TO THE SEAL" elseif mode=="crow" then "SUBSTITUTION • CROW CLONE" elseif mode=="flank" then "SUBSTITUTION • OUTSIDE STEP" else "SUBSTITUTION • REPOSITIONED")..extra)
	return true
end
-- A reappearance point next to `attacker` is usable when nothing solid fills it
-- and the attacker has a clear line to it.
function Combat:openSpot(attacker,spot)
	for _,part in workspace:GetPartBoundsInBox(CFrame.new(spot),Vector3.new(2.6,4.6,2.6),self:overlapParams()) do
		if part.CanCollide then return false end
	end
	return workspace:Raycast(attacker.root.Position,spot-attacker.root.Position,self:rayParams(true))==nil
end
-- Wall tech: pinned against a wall, a well-timed dodge kicks off it. Too early
-- (before the impact settles) or too late and the pin holds.
-- Re-engage (CORE_COMBAT_CONVERGENCE_2 §3): ONE contextual action — keyboard
-- E; on a pad × inside a chase window, sprint + ○ toward outside one. Inside a
-- chase window (knock-away, launch, throw, wall splat or bounce, a substitution
-- to track) it is the chase; outside it is the chakra dash at a locked
-- opponent. Same chakra either way; each prodigy re-enters his own way
-- (MoveGraphs[...].reengage, Brawler.rushPlan).
function Combat:reengage(a)
	if a.pursuitUntil>self.now and a.target.health>0 then return self:chase(a) end
	return self:rush(a)
end
-- The chase: reach the knocked-away / launched / thrown body in three
-- dimensions (motion in updateActor). The strike that connected and opened the
-- window (a launcher, the third light, a palm thrust...) may be cancelled into
-- it at once: E pressed on the knock-away is never eaten by its active frames.
function Combat:chase(a)
	if a.chakra<Config.PursuitCost then return false,"Need chakra" end
	if (a.target.root.Position-a.root.Position).Magnitude>Config.PursuitRange then return false,"Too far" end
	local launchCancel=a.hitConfirmed and (a.state=="Active" or a.state=="Recovery")
		and a.pending~=nil and a.pending.kind=="Brawl"
	if a.state~="Neutral" and a.state~="Recovery" and a.state~="TechniqueRecovery" and not launchCancel then return false,"Committed" end
	if launchCancel then Bangla.close(a.pending);a.pending=nil;a.hitstopUntil=0 end
	local style=Brawler.reentry(a)
	a.chakra-=Config.PursuitCost; a.pursuitUntil=0
	a.reaction=nil; a.airborne=true
	a.pursuitStarted=self.now
	-- A body still rising fast (a chase pressed on the launch itself) is
	-- followed up to where an air strike can catch it, not dropped at 0.24 s.
	local b=a.target
	local rising=if b.reaction and b.reactionVelocity then math.max(0,b.reactionVelocity.Y) else 0
	local duration=(style.chase or .3)+math.clamp((rising-30)/75,0,.3)
	a.pursuitDuration=duration
	-- The side of the body the chase arrives on: the attacker's own.
	local line=Vector3.new(b.root.Position.X-a.root.Position.X,0,b.root.Position.Z-a.root.Position.Z)
	a.pursuitLine=if line.Magnitude>.2 then line.Unit else Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z).Unit
	a.airHold=self.now+duration+.45
	Brawler.breakString(a,false)
	Brawler.event(self,a,"Chase");Brawler.event(self,a,"Reengage")
	self:setState(a,"Pursuit",duration)
	self:effect("Pursuit",a.root.Position,a.color,Vector3.new(2,4,2),0.35)
	self:pushImpact(a.root.Position,"chase",false,{owner=a.id,fighter=a.fighterId,variant=style.name,mode="chase"})
	return true
end
-- Chakra dash. A committed burst at a locked opponent from neutral (or out of
-- a recovery's cancel point), a straight reposition when unlocked. It is not
-- armoured: a blade, a guard or a read answers it. The arrival (Brawler.arrive)
-- converts at once into the dash attack, the quick heavy or a grab, but guards
-- only after Config.Rush.CancelAfter: a predictable dash is punished.
function Combat:rush(a)
	local tune=Config.Rush
	local style=Brawler.reentry(a)
	local cancel=a.state=="Recovery" and self.now>=(a.recoveryCancelAt or math.huge)
	if not Rules.canAct(a,self.now) and not cancel then return false,"Committed" end
	if a.airborne or a.wall or a.reaction then return false,"No chakra dash" end
	-- Skill build (Counter-Rush): right after a substitution the dash is free.
	local free=(a.freeRushUntil or 0)>self.now
	if a.chakra<Config.PursuitCost and not free then return false,"Need chakra" end
	if self.now<(a.rushReadyAt or 0) then return false,"Cooldown" end
	local gap=(a.target.root.Position-a.root.Position).Magnitude
	local line=nil
	if a.locked==false then
		-- Unlocked: no homing, a straight burst along the stick (or the facing).
		local stick=Vector3.new(a.move.X,0,a.move.Z)
		local look=a.root.CFrame.LookVector
		line=if stick.Magnitude>.2 then stick.Unit else Vector3.new(look.X,0,look.Z).Unit
	else
		if gap<(style.minRange or tune.MinRange) then return false,"Too close" end
		if gap>tune.Range then return false,"Too far" end
	end
	if cancel then Bangla.close(a.pending) end
	if free then a.freeRushUntil=nil;self:cue(a,"COUNTER-RUSH",.5) else a.chakra-=Config.PursuitCost end
	a.rushReadyAt=self.now+tune.Cooldown
	a.pending=nil;a.attackName=nil;a.guardHeld=false;a.chainOpen=false
	-- A re-entry opens a fresh string on arrival.
	Brawler.breakString(a,false)
	local departure=a.root.Position
	local plan=Brawler.rushPlan(self,a,style,line)
	local travel=if line then tune.Reposition else gap
	local duration=math.clamp(travel/plan.speed+.12,.12,tune.MaxTime*(style.time or 1))
	self:setState(a,"Rush",duration)
	a.rush=plan
	a.rushArriveUntil=self.now+duration+tune.Arrive
	Brawler.event(self,a,"Rush");Brawler.event(self,a,"Reengage")
	-- Itachi: the approach starts from an afterimage left where he stood.
	if style.afterimage then self:pushImpact(departure,"afterimage",false,{owner=a.id,fighter=a.fighterId,variant="reengage"}) end
	self:pushImpact(departure,"chase",false,{owner=a.id,fighter=a.fighterId,variant=style.name,mode="dash",to=plan.goal,sealed=plan.sealed})
	return true
end
-- Awakening: once per match, below a third of health. A shockwave buys space,
-- chakra comes back, and each prodigy's own strength is pushed for a while.
function Combat:awaken(a)
	local tune=a.def.Awakening
	if not tune or a.awakened then return false,"No awakening" end
	if a.health>a.def.Health*Config.Awaken.Threshold then return false,"Not yet" end
	if not Brawler.free(a,self.now) then return false,"Reacting" end
	a.awakened=true;a.awakenUntil=self.now+Config.Awaken.Duration;a.awakenedAt=self.now;a.curseLanded=self.now;a.curseFedUntil=0
	a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+40)
	a.cooldowns={}
	a.invulnerableUntil=math.max(a.invulnerableUntil,self.now+.45)
	a.pending=nil;a.guardHeld=false;self:setState(a,"Recovery",.3)
	local b=a.target
	if b and b.health>0 then
		local away=b.root.Position-a.root.Position;away=Vector3.new(away.X,0,away.Z)
		if away.Magnitude<9 and away.Magnitude>.05 then Brawler.react(self,b,"Knockback",away.Unit*34+Vector3.new(0,12,0),.45,a) end
	end
	a.hitstopUntil=self.now+.12
	self:pushImpact(a.root.Position,"awaken",true,{owner=a.id,fighter=a.fighterId})
	self:cue(a,"AWAKENING • "..tune.Name,1.4)
	if b then self:cue(b,"OPPONENT AWAKENED",1) end
	Brawler.event(self,a,"Awaken")
	return true
end
-- Awakened techniques recover faster (and Itachi's cost less).
function Combat:awakenTechnique(a,spec)
	if (a.awakenUntil or 0)<=self.now then return end
	local tune=a.def.Awakening
	a.cooldowns[spec.Id]=self.now+spec.Cooldown*(tune.Cooldown or 1)
	if tune.CostScale then a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+spec.Cost*(1-tune.CostScale)) end
end
function Combat:wallTech(a)
	local tune=Config.Wall
	local elapsed=self.now-(a.splatAt or -10)
	if elapsed<tune.TechFrom or elapsed>tune.TechUntil or (a.hitstopUntil or 0)>self.now then
		a.techLockUntil=self.now+.25
		return false,"Tech missed"
	end
	if (a.techLockUntil or 0)>self.now then return false,"Tech missed" end
	if a.chakra<tune.TechCost then return false,"Need chakra" end
	local normal=a.splatNormal or -a.root.CFrame.LookVector
	normal=Vector3.new(normal.X,0,normal.Z)
	normal=if normal.Magnitude>.05 then normal.Unit else -a.root.CFrame.LookVector
	a.chakra-=tune.TechCost
	a.reaction=nil;a.reactionVelocity=nil;a.groundPose=nil;a.comboHits=0;a.comboDamage=0
	-- Kick off along the stick (sideways along the wall or straight out).
	local stick=Vector3.new(a.move.X,0,a.move.Z)
	local along=stick-normal*stick:Dot(normal)
	local out=normal*30+(if along.Magnitude>.3 then along.Unit*18 else Vector3.zero)
	a.root.AssemblyLinearVelocity=out+Vector3.new(0,36,0)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+normal)
	a.airborne=true;a.airDodgeUsed=false;a.takeoffUntil=self.now+.12;a.wallNext=self.now+.35
	a.invulnerableUntil=self.now+.28
	self:setState(a,"Recovery",.16)
	Brawler.event(self,a,"WallTech")
	self:pushImpact(a.root.Position-normal*1.2,"walltech",false,{owner=a.id,fighter=a.fighterId,normal=normal})
	self:cue(a,"WALL TECH")
	if a.target then self:cue(a.target,"WALL TECH • RESET",.7) end
	return true
end
function Combat:request(a,action,aim,clientTime,opts)
	if self.match.phase~="Duel" or a.health<=0 then return false,"No duel" end
	if self.match.introUntil and self.now<self.match.introUntil then return false,"Intro" end
	if self.match.finishing then return false,"Intro" end
	-- The press carries its own stick (Matches:act): remember it as intent.
	Brawler.observe(self,a)
	if action=="GuardOff" then
		Defense.guard(a,false,self.now)
		if a.state=="Guarding" then self:setState(a,"Neutral",0) end
		return true
	end
	if action=="JumpOff" then
		if a.airborne and a.root.AssemblyLinearVelocity.Y>22 and self.now<(a.takeoffUntil or 0)+0.18 then
			local v=a.root.AssemblyLinearVelocity
			a.root.AssemblyLinearVelocity=Vector3.new(v.X,v.Y*0.66,v.Z)
		end
		return true
	end
	if action=="WallDetach" then Motor.detach(a,self.now,false); return true end
	-- Pinned against a wall, the dodge button is a timed wall tech, never a
	-- substitution: a mistimed tech must not silently spend a charge.
	if action=="Dodge" and a.reaction=="WallSplat" then return self:wallTech(a) end
	if action=="Dodge" and not Brawler.free(a,self.now) then action="Substitute" end
	if action=="Substitute" then return self:substitute(a) end
	if action=="Awaken" then return self:awaken(a) end
	if action=="Feint" then
		local pending=a.pending
		if a.state=="Startup" and pending and pending.kind=="Brawl" and pending.name=="Heavy" and self.now-a.attackStarted<=pending.spec.startup*.62 then
			Bangla.close(pending);a.pending=nil;a.attackName=nil;a.travelRemaining=0;a.chakra=math.max(0,a.chakra-4)
			self:setState(a,"Recovery",.09);self:cue(a,"HEAVY FEINT • MOVE");Brawler.event(self,a,"Feint")
			return true
		end
		if a.state~="TechniqueChannel" or not pending or not pending.spec.Feintable then return false,"No feint window" end
		if self.now>a.untilTime-pending.spec.Channel*0.5 then return false,"Feint too late" end
		a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+pending.spec.Cost*0.35)
		a.pending=nil; self:setState(a,"Recovery",0.24); self:cue(a,"FEINT • CHAKRA PARTIAL")
		return true
	end
	-- The throwing arm owns the body until the blade leaves the hand; after the
	-- release the follow-up is free, which is what lets a kunai lead a rush.
	local throwHeld=a.throwing and self.now<a.throwing.release
	if throwHeld and (action=="Attack" or action=="Heavy" or action=="Grab" or action=="Tool" or string.match(action,"^Technique")) then
		return false,"Committed"
	end
	-- (The light step is no longer resolved here: Brawler.request reads it from
	-- the confirmed hits when the press actually starts a strike.)
	if action=="Attack" or action=="Heavy" or action=="Grab" then a.attackCommitTime=clientTime or self.now end
	local handled,reason=Brawler.request(self,a,action)
	if handled~=nil then return handled,reason end
	if not Brawler.free(a,self.now) then return false,"Reacting" end
	-- Itachi's re-entry is a feint he can abort: guard or dodge stops the dash.
	if (action=="Guard" or action=="Dodge") and a.state=="Rush" and Brawler.reentry(a).feint then Brawler.feintRush(self,a) end
	if (action=="Guard" or action=="Dodge") and (a.state=="Recovery" or a.state=="TechniqueRecovery") and self.now>=(a.recoveryCancelAt or math.huge) then
		a.pending=nil;self:setState(a,"Neutral",0)
	end
	-- Pad re-engage: sprint + dodge toward a locked opponent at mid range is the
	-- re-engage (chase in a window, chakra dash outside); anything else, or a
	-- re-engage that is not available (cooldown, chakra), stays a dodge.
	if action=="Dodge" and Brawler.dashIntent(self,a) then
		local ok,why=self:reengage(a)
		if ok then return ok,why end
	end
	if action=="Pursuit" then return self:reengage(a) end
	if action=="Jump" then
		if a.wall then Motor.detach(a,self.now,true); return true end
		if a.state~="Neutral" and a.state~="Recovery" then return false,"Committed" end
		-- Like a guard or a dodge, a jump leaves a recovery only at its cancel
		-- point: a whiff (or an unanswered dash) cannot hop out of its punish.
		if a.state=="Recovery" and self.now<(a.recoveryCancelAt or 0) then return false,"Committed" end
		return Motor.jump(a,self,self.now),"Airborne"
	end
	if action=="Tool" then
		if a.def.ArrivalThrow then
			local thrown,refusal=self:arrivalThrow(a)
			if thrown~=nil then return thrown,refusal end
		end
		local graph=Brawler.graph(a) or {}
		local chainCancel=a.def.ComboToolCancel and a.state=="Recovery" and (a.chainOpen or (a.hitBlocked and graph.blockCancels and graph.blockCancels.Tool)) and self.now>=(a.chainAt or 0)
		-- Chakra modifier held (keyboard Z + R, pad R1 + R2). With the wire still on
		-- a bound body, the current may leave the jutsu recovery, like Dragon Flame.
		local chakra=opts~=nil and opts.chakra==true
		local wired=chakra and a.state=="TechniqueRecovery" and a.wireVictim~=nil and a.wireVictim.reaction=="Bound" and a.wireVictim.boundBy==a
		if (not chainCancel and not wired and not Rules.canAct(a,self.now)) or self.now<a.neutralToolAt then return false,"Tool recovering" end
		if a.throwing then return false,"Throwing" end
		-- The fighter's mastery decides what the chakra does to this tool (server
		-- side only); a reserve that cannot pay refuses with a visible fizzle.
		local mastery=a.def.ToolMastery or {Kind="kunai",Count=1,Speed=90,Damage=3,Recover=.75}
		local infused=nil
		if chakra then
			local why
			infused,why=Chakra.plan(self,a,if a.def.Tool=="Sand" then "Sand" elseif mastery.Kind=="kunai" then "Kunai" else "Shuriken")
			if not infused then Chakra.refuse(self,a);return false,why end
			if wired and infused.mode~="conduct" then return false,"Tool recovering" end
			if a.chakra<Chakra.cost(infused,chainCancel) then Chakra.refuse(self,a);return false,"Need chakra" end
		end
		-- A neutral throw costs a little chakra so blades pressure, not spam;
		-- the throw that cancels a confirmed string stays free.
		if not infused and not chainCancel and a.chakra<Config.ToolCost then return false,"Need chakra" end
		if infused then a.chakra-=Chakra.cost(infused,chainCancel) elseif not chainCancel then a.chakra-=Config.ToolCost end
		if wired then a.pending=nil;self:setState(a,"Neutral",0) end
		-- Stick away + tool inside a string: hop out of it behind the throw.
		local disengage=graph.disengage
		if chainCancel and a.chainOpen and disengage and Brawler.intent(a)=="back" and not infused then
			a.neutralToolAt=self.now+.5
			return Brawler.disengage(self,a,disengage)
		end
		if chainCancel then a.pending=nil;a.attackName=nil;a.chainOpen=false;self:setState(a,"Neutral",0);Brawler.event(self,a,"ChainTool") end
		-- Throwing lowers the guard: a blade never leaves a fully blocking body.
		if a.state=="Guarding" then Defense.guard(a,false,self.now);self:setState(a,"Neutral",0) end
		if a.wall then Motor.detach(a,self.now,false) end
		-- Chakra without a throw: down the wire (Sasuke) or through the palm (Neji).
		if infused and infused.mode=="conduct" then
			a.neutralToolAt=self.now+.35
			return Chakra.conduct(self,a,infused)
		end
		if infused and infused.mode=="body" then
			a.neutralToolAt=self.now+mastery.Recover
			return Chakra.palm(self,a,infused)
		end
		if a.def.Tool=="Sand" then
			a.neutralToolAt=self.now+(if chainCancel then .42 else .6)
			self:beginThrow(a,{kind="Sand",release=.12,count=1,aim=aim,fire=function(_,target)
				self:projectile(a,target,90,if chainCancel then 20 else 56,3,"sand",nil,{origin=self.launchPoint(a,"Palm"),radius=.6,chakra=infused})
			end})
			self:cue(a,if infused then Chakra.label(infused) else "SAND BULLET",.5)
			return true
		end
		local blade=mastery.Kind=="kunai"
		a.neutralToolAt=self.now+(if chainCancel then .42 else mastery.Recover)
		local range=if chainCancel then 20 else 62
		-- Shuriken Geometry (mastery): side + tool throws one blade wide and a
		-- second that strikes it beside the opponent; both fly into the flank.
		local dir,sideSign=Brawler.intent(a)
		if mastery.Geometry and dir=="side" and not chainCancel and a.target and a.target.health>0 then
			return self:shurikenGeometry(a,sideSign,infused)
		end
		-- In the air a master fans several blades down at the opponent.
		local count=if a.airborne and mastery.AirSpread then mastery.AirSpread else mastery.Count
		self:beginThrow(a,{kind=if blade then "Kunai" else "Shuriken",release=if blade then .1 else .13,
			count=count,interval=if count>2 then .05 else .08,aim=aim,
			fire=function(index,target)
				local spread=Vector3.zero
				if count>1 then spread=a.root.CFrame.RightVector*((index-(count+1)/2)*(if count>2 then 1.6 else 1.8)) end
				self:projectile(a,target+spread,mastery.Speed,range,mastery.Damage,if blade then "kunai" else "shuriken",nil,{chakra=infused})
			end})
		self:cue(a,if infused then Chakra.label(infused) elseif chainCancel then "CHAIN TOOL • KEEP PRESSURE" else (if blade then "KUNAI" else "SHURIKEN"))
		return true
	end
	-- Melee -> technique: Minato may spend a confirmed string on Rasengan with
	-- a shortened wind-up. It is a read/finisher, not a neutral button.
	a.stringCancel=nil
	local cancelSlot=tonumber(string.match(action,"^Technique([1-5])$"))
	local cancelSpec=cancelSlot and a.def.Techniques[cancelSlot]
	-- Skill build (Blood for Chakra): the Curse Mark pays what the reserve lacks
	-- before the usual checks, for a cancel or a neutral cast alike.
	if cancelSpec and a.def.Awakening and a.def.Awakening.BloodChakra and ((a.state=="Recovery" and a.chainOpen) or Rules.canAct(a,self.now))
		and Techniques[cancelSpec.Id].check(self,a,cancelSpec,self.now) then self:curseBlood(a,cancelSpec) end
	local cancelGraph=Brawler.graph(a) or {}
	-- The technique's own condition is checked before the string is spent (a
	-- teleport cancel needs a seal); the original cancels have none.
	if cancelSpec and cancelGraph.stringCancels and cancelGraph.stringCancels[cancelSpec.Id] and a.state=="Recovery" and a.chainOpen and self.now>=(a.chainAt or 0)
		and (a.cooldowns[cancelSpec.Id] or 0)<=self.now and a.chakra>=cancelSpec.Cost and Techniques[cancelSpec.Id].check(self,a,cancelSpec,self.now) then
		Bangla.close(a.pending);a.pending=nil;a.attackName=nil;a.chainOpen=false;a.state="Neutral";a.untilTime=self.now
		a.stringCancel=cancelSpec.Id
	end
	-- Flying Thunder God arrival: the Rasengan is already forming in the hand,
	-- so it cancels the teleport recovery with almost no wind-up.
	a.flashCancel=nil
	local arriving=(a.flashUntil or 0)>self.now and (a.state=="TechniqueRecovery" or a.state=="TechniqueActive")
		and (a.pending==nil or a.pending.spec.Id=="Flashstep")
	if cancelSpec and cancelSpec.Id=="BurstStrike" and arriving
		and (a.cooldowns[cancelSpec.Id] or 0)<=self.now and a.chakra>=cancelSpec.Cost then
		a.flashUntil=0;a.state="Neutral";a.untilTime=self.now;a.pending=nil
		a.flashCancel=true
	end
	-- Dragon Flame: with the wire still holding the body, the fire runs along
	-- it at once (the wire throw's recovery is cancelled, the signs are short).
	a.wireCancel=nil
	local wired=a.wireVictim and a.wireVictim.reaction=="Bound" and a.wireVictim.boundBy==a
	if cancelSpec and cancelSpec.Id=="FireBloom" and wired and (a.state=="TechniqueRecovery" or a.state=="Neutral" or a.state=="Recovery")
		and (a.cooldowns[cancelSpec.Id] or 0)<=self.now and a.chakra>=cancelSpec.Cost then
		a.state="Neutral";a.untilTime=self.now;a.pending=nil
		a.wireCancel=true
	end
	local chain=action=="Attack" and a.state=="Recovery" and a.chainOpen and self.now>a.chainAt
	if not chain and not Rules.canAct(a,self.now) then return false,"Committed" end
	if action=="Guard" then Brawler.event(self,a,"Guard");Defense.guard(a,true,self.now);self:setState(a,"Guarding",0);return true end
	if action=="Dodge" and a.def.SandFlicker and not a.airborne then
		-- Gaara's dodge: a sand body-flicker, an instant reposition.
		if a.chakra<Config.DodgeCost then return false,"Need chakra" end
		if a.dodgeUntil>self.now then return false,"Cooldown" end
		a.chakra-=Config.DodgeCost;a.dodgeUntil=self.now+Config.DodgeCooldown
		local direction=if a.move.Magnitude>.1 then a.move.Unit else -a.root.CFrame.LookVector
		local from=a.root.Position
		Motor.travel(a,self,direction,a.def.SandFlicker.Distance)
		a.warpSerial=(a.warpSerial or 0)+1
		a.invulnerableUntil=self.now+.24;Defense.guard(a,false,self.now);Defense.dodge(a,self.now)
		self:setState(a,"Recovery",.14)
		self:pushImpact(from,"sandflicker",false,{owner=a.id,fighter=a.fighterId,to=a.root.Position})
		Brawler.event(self,a,"Dodge")
		return true
	end
	if action=="Dodge" then
		if a.chakra<Config.DodgeCost then return false,"Need chakra" end
		if a.airborne and a.airDodgeUsed then return false,"Air dodge used" end
		if a.dodgeUntil>self.now then return false,"Cooldown" end
		a.chakra-=Config.DodgeCost; a.dodgeUntil=self.now+Config.DodgeCooldown
		if a.wall then Motor.detach(a,self.now,false) end
		if a.airborne then a.airDodgeUsed=true end
		a.dodgeDirection=if a.move.Magnitude>0.1 then a.move.Unit else a.root.CFrame.RightVector
		a.invulnerableUntil=self.now+Config.DodgeIFrames;Defense.guard(a,false,self.now);Defense.dodge(a,self.now)
		Evade.begin(a,self)
		self:pushImpact(a.root.Position,"dodge",false)
		Brawler.event(self,a,"Dodge"); self:setState(a,"Dodging",Config.DodgeTime); self:effect("Dodge",a.root.Position,a.color,Vector3.new(2,4,1),0.2)
		return true
	end
	if self.match.techniquesDisabled then return false,"Techniques disabled" end
	if string.match(action,"^Technique") and (a.sealedUntil or 0)>self.now then return false,"Chakra points sealed" end
	local slot=tonumber(string.match(action,"^Technique([1-5])$"))
	local spec=slot and a.def.Techniques[slot]
 if spec and (a.trainingChannelScale or 1)~=1 then spec=table.clone(spec);spec.Channel*=a.trainingChannelScale end
	if not spec then return false,"Unknown action" end
	local technique=Techniques[spec.Id]
	-- A string cancel shortens the wind-up to .14 s; a technique that is already
	-- quicker (a teleport, the Read, Rotation) keeps its own.
	if a.stringCancel==spec.Id then spec=table.clone(spec);spec.Channel=math.min(spec.Channel,.14) end
	a.stringCancel=nil
	if a.wireCancel and spec.Id=="FireBloom" then spec=table.clone(spec);spec.Channel=.16 end
	a.wireCancel=nil
	-- Context: the same Rasengan is a different tool after a teleport (instant
	-- thrust) and in the air (a plunge that ends the air phase).
	local variant=nil
	if spec.Id=="BurstStrike" then
		if a.flashCancel then spec=table.clone(spec);spec.Channel=.05;variant="FlashRasengan"
		elseif a.airborne then spec=table.clone(spec);spec.Channel=math.min(spec.Channel,.12);variant="RasenganDrop" end
	end
	-- Skill build (Wall Chidori): charged from a wall run, he hangs on the wall
	-- for a shorter charge, then the thrust dives at the opponent.
	if spec.Id=="Chidori" and spec.WallCharge and a.wall then spec=table.clone(spec);spec.Channel=math.min(spec.Channel,spec.WallCharge);variant="WallChidori" end
	a.flashCancel=nil
	local ok,reason=Rules.technique(a,spec,self.now,technique.check(self,a,spec,self.now))
	if not ok then return false,reason end
	if a.wall then Motor.detach(a,self.now,false) end
	if spec.Mobile then
		-- A thrown technique (Minato's marked kunai): chakra and cooldown are
		-- committed now, but the body stays in Neutral so the legs keep moving
		-- while the arm throws; the payoff fires on the release frame.
		Brawler.event(self,a,"Technique"); a.chakra-=spec.Cost; a.cooldowns[spec.Id]=self.now+spec.Cooldown; a.guardHeld=false
		-- Same for a thrown technique: no guard pose (and guard speed) without a guard.
		if a.state=="Guarding" then self:setState(a,"Neutral",0) end
		self:awakenTechnique(a,spec)
		a.castId=spec.Id;a.castStarted=self.now
		local pending={kind="Technique",spec=spec,implementation=technique,aim=aim}
		self:beginThrow(a,{kind=spec.Throw or "MarkedKunai",release=spec.Channel,count=1,aim=aim,fire=function(_,target)
			pending.aim=target
			technique.execute(self,a,pending,self.now)
			Brawler.event(self,a,"TechniqueResolved")
		end})
		self:cue(a,spec.Name,.6)
		return true
	end
	Brawler.event(self,a,"Technique"); Rules.reserve(a,spec,self.now); a.guardHeld=false
	self:awakenTechnique(a,spec)
	a.pending={kind="Technique",spec=spec,implementation=technique,aim=aim or a.target.root.Position,variant=variant}
	a.castId=spec.Id;a.castStarted=self.now
	local offset=a.pending.aim-a.root.Position
	local flat=Vector3.new(offset.X,0,offset.Z)
	a.castFace=nil
	if flat.Magnitude>0.1 then
		-- A small correction snaps (unseen); a large one turns through the
		-- channel instead of teleporting the facing on the first frame.
		local look=Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z)
		if look.Magnitude<.01 or look.Unit:Dot(flat.Unit)>=.82 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+flat)
		else a.castFace=flat.Unit end
	end
	self:cue(a,spec.Name.." • PREPARING",spec.Channel)
	if variant=="WallChidori" then
		-- Held off the wall for the whole charge (the hover window zeroes the fall).
		a.airborne=true;a.airHold=self.now+spec.Channel+.05
		self:cue(a,"CHIDORI • FROM THE WALL",spec.Channel)
	end
	self:effect("Channel",a.root.Position-Vector3.new(0,2.8,0),a.color,Vector3.new(4,0.12,4),spec.Channel)
	self:pushImpact(a.root.Position,"cast",false,{owner=a.id,fighter=a.fighterId,technique=spec.Id,channel=spec.Channel})
	return true
end
function Combat:updateActor(a,dt)
	local now=self.now
	if a.health<=0 then a.hum:Move(Vector3.zero); return end
	-- Movement intents last exactly one frame; each control block re-declares its own.
	a.aimIntent=nil
	-- Directional memory for routes: the latest strong push, every frame.
	Brawler.observe(self,a)
	Defense.step(self,a,dt,now)
	Techniques.expireSeals(self,a,now)
	-- A combo ends once the victim has been free to act for a moment.
	if a.reaction or a.state=="Stunned" then a.freeSince=nil elseif not a.freeSince then a.freeSince=now end
	if a.freeSince and now-a.freeSince>=Config.ComboScaling.Reset and (a.comboHits>0 or (a.wallSplats or 0)>0) then a.comboHits=0;a.comboDamage=0;a.wallSplats=0;a.splatPins=0;a.wallBounced=false;a.groundBounced=false end
	-- Substitution charges come back one at a time.
	if a.subCharges<Config.Substitution.Charges and now>=a.subRegenAt then
		a.subCharges+=1
		a.subRegenAt=if a.subCharges<Config.Substitution.Charges then now+Config.Substitution.Recharge else math.huge
		self:cue(a,"SUBSTITUTION READY",.6)
	end
	Techniques.stepIllusion(self,a,now)
	if a.state~="TechniqueChannel" and a.state~="Stunned" then
		local regen=a.def.ChakraRegen or Config.ChakraRegen
		-- Closed chakra points (Gentle Fist) slow the recovery.
		if (a.tenketsuUntil or 0)>now then regen*=math.max(.2,1-(a.tenketsuCut or .15)*(a.tenketsu or 0)) end
		if (a.awakenUntil or 0)>now then regen*=a.def.Awakening.Regen or 1 end
		a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+regen*dt)
	end
	if (a.rotationUntil or 0)>now then self:stepRotation(a) end
	if a.def.SandShield and a.shieldCharges<a.def.SandShield.Charges and now>=(a.shieldRegenAt or 0) then
		a.shieldCharges+=1
		local rate=if (a.awakenUntil or 0)>now then (a.def.Awakening.ShieldRegen or 1) else 1
		a.shieldRegenAt=now+a.def.SandShield.Regen/rate
	end
	a.speedScale=if (a.awakenUntil or 0)>now then (a.def.Awakening.Speed or 1) else 1
	-- The curse mark burns the body that carries it (never to a KO), faster
	-- while it goes hungry (Techniques.curseDrain).
	Techniques.curseDrain(self,a,dt,now)
	-- Rooted while spinning or striking the sixty-four palms.
	if (a.rotationUntil or 0)>now or (a.flurryUntil or 0)>now then a.move=Vector3.zero end
	if now<(a.hitstopUntil or 0) then
		-- Weight, not a pause: the swing clock keeps running so the animation never
		-- drifts behind the hitbox, and only the frozen body is held still.
		a.hum:Move(Vector3.zero)
		if a.reaction then a.root.AssemblyLinearVelocity=Vector3.zero end
		World.pose(a,now,dt);return
	end
	if a.state~="Neutral" and a.state~="Guarding" and a.untilTime<=now then
		local pending=a.pending
		if a.state=="Startup" and pending then
			-- The slam's active window is its sized descent; everything else uses
			-- the authored active duration.
			self:setState(a,"Active",if pending.slamWindow and pending.slamWindow>0 then pending.slamWindow else pending.spec.active)
			a.activeAt=now
		elseif a.state=="Active" then
			Bangla.close(pending)
			-- The swing's own contact (Brawler.step), never a blade or a burn that
			-- landed while it was out.
			local brawl=pending~=nil and pending.kind=="Brawl"
			a.hitConfirmed=brawl and pending.contact==true
			-- A committed swing that never touched anything: report the whiff so
			-- the client can answer with air movement instead of silence.
			if brawl and not a.hitConfirmed then
				self:pushImpact(a.root.Position+a.root.CFrame.LookVector*2.2,"whiff",false)
				-- Genjutsu image / Sharingan Focus: a swing at the wrong place is read.
				Techniques.whiffRead(self,a,pending,now)
			end
			local recovery=if pending then pending.spec.recovery else .22
			a.pending=nil; self:setState(a,"Recovery",recovery)
			-- Cancel philosophy: a string continues only on a clean hit. On block the
			-- attacker keeps a dodge cancel (and Itachi a shuriken cancel); a whiff
			-- keeps its full recovery.
			a.chainOpen=a.hitConfirmed and not a.hitBlocked and brawl and pending.spec.chain==true
			a.chainAt=now
			-- Combo model: a clean chain hit keeps its string for the chain window
			-- plus the grace; a whiff or a block ends it (the next press opens).
			if brawl then Brawler.settle(self,a,pending) end
			local whiffHeavy=brawl and pending.name=="Heavy" and not a.hitConfirmed
			a.recoveryCancelAt=if whiffHeavy then a.untilTime else now+recovery*(if a.hitConfirmed then .36 else .72)
		elseif a.state=="Rush" then
			-- The dash is over: its arrival (Brawler.arrive).
			Brawler.arrive(self,a)
		elseif a.state=="Pursuit" then
			-- The chase arrived: a short window in which a press is the arrival
			-- strike (air string up there, dash attack on the ground) or heavy.
			a.pending=nil;a.attackName=nil;self:setState(a,"Neutral",0)
			a.rushArriveUntil=now+Config.Rush.Arrive
		elseif a.state=="TechniqueChannel" and pending then
			-- State changes before payoff so simultaneous channels resolve deterministically.
			self:setState(a,"TechniqueActive",pending.spec.Active)
			pending.implementation.execute(self,a,pending,now)
			Brawler.event(self,a,"TechniqueResolved")
		elseif a.state=="TechniqueActive" and pending then
			a.pending=nil; self:setState(a,"TechniqueRecovery",pending.spec.Recovery)
			-- A utility jutsu (Flow) yields the second half of its recovery to a
			-- guard or a dodge: it flows back into movement instead of freezing.
			if pending.spec.Flow then a.recoveryCancelAt=now+pending.spec.Recovery*.5 end
		else
			a.pending=nil;a.attackName=nil; self:setState(a,"Neutral",0)
		end
	end
	if self.match.phase~="Duel" then a.hum:Move(Vector3.zero); return end
 if a.state~="Dodging" then a.evade=nil end
	self:stepThrow(a)
	-- A guard key still held through a hit, a recovery or a throw comes back up
	-- as soon as the fighter is free. The automatic raise leaves guardPressedAt
	-- alone, so it never grants a fresh parry window.
	if a.guardWanted and a.state=="Neutral" and not a.guardHeld and not a.throwing and not a.reaction
		and not a.grabbedBy and not a.pending and Rules.canAct(a,now) then
		a.guardHeld=true;self:setState(a,"Guarding",0)
	end
	if a.hop then
		local step=math.min(a.hop.remaining,a.hop.speed*dt)
		a.hop.remaining-=step
		Motor.travel(a,self,a.hop.direction,step)
		if a.hop.remaining<=.01 or a.reaction then a.hop=nil end
	end
	if a.castId and not a.pending and not a.throwing and a.state~="TechniqueRecovery" then a.castId=nil end
	-- A cast that started off-line turns into its aim through the channel.
	if a.castFace then
		if (a.state=="TechniqueChannel" or a.state=="TechniqueActive") and (a.rotationUntil or 0)<=now then self:turnToward(a,a.castFace,dt,1440)
		elseif a.state~="TechniqueChannel" and a.state~="TechniqueActive" then a.castFace=nil end
	end
	if Brawler.step(self,a,dt) then World.pose(a,now,dt); return end
	if a.locked and (a.state=="Neutral" or a.state=="Guarding") then
		a.hum.AutoRotate=false
		self:faceLocked(a,dt)
	else a.hum.AutoRotate=not a.locked end
	if a.state=="Dodging" then
		Evade.step(a,self,Motor.travel)
	elseif a.state=="Pursuit" and (a.shadowUntil or 0)>now then
		-- Shadow of the Dancing Leaf: glued just behind and below the rising
		-- body, closing the gap in proportion to it (no overshoot, no bobbing).
		local b=a.target
		local back=a.root.Position-b.root.Position;back=Vector3.new(back.X,0,back.Z)
		back=if back.Magnitude>.1 then back.Unit else -b.root.CFrame.LookVector
		local point=b.root.Position+back*2.1-Vector3.new(0,1.1,0)
		local offset=point-a.root.Position
		a.airborne=true
		a.aimIntent={target=point,speed=math.clamp(offset.Magnitude*16,0,140),acceleration=3200}
		local flat=Vector3.new(-back.X,0,-back.Z)
		a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+flat)
	elseif a.state=="Pursuit" then
		-- Reach the victim in three dimensions, but kinetically: the chase keeps
		-- a continuous velocity instead of being teleported frame by frame. A
		-- body in a reaction flies on its reactionVelocity (its root velocity is
		-- held at zero), so that is what the chase leads. It arrives on its own
		-- side of the body, a step short and a little below, facing it, and ends
		-- as soon as the body is within reach and an air strike can follow it.
		local b=a.target
		local elapsed=now-(a.pursuitStarted or now)
		local remaining=math.max(.04,(a.pursuitDuration or .24)-elapsed)
		local velocity=if b.reaction and b.reactionVelocity then b.reactionVelocity else b.root.AssemblyLinearVelocity
		local lead=math.min(remaining,.15)
		local fall=if b.reaction and b.airborne then 37.5*lead*lead else 0
		local predicted=b.root.Position+velocity*lead-Vector3.new(0,fall,0)
		local line=a.pursuitLine or Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z).Unit
		local point=predicted-line*2.6-Vector3.new(0,.6,0)
		local toward=point-a.root.Position
		local distance=(b.root.Position-a.root.Position).Magnitude
		local face=Vector3.new(b.root.Position.X-a.root.Position.X,0,b.root.Position.Z-a.root.Position.Z)
		if face.Magnitude>.3 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
		if Brawler.chaseArrived(self,a) then
			a.untilTime=math.min(a.untilTime,now)
		elseif toward.Magnitude>.2 then
			-- Reach the window in time, then ease in on approach so the chaser
			-- never overshoots its own target and snaps back.
			local speed=math.clamp(toward.Magnitude/math.max(remaining,.06),70,420)
			if distance<7 then speed=math.min(speed,60+distance*distance*3) end
			a.aimIntent={target=point,speed=speed,acceleration=1600}
		end
	elseif a.state=="Rush" then
		-- Chakra dash toward its arrival point (Brawler.rushPlan): a step short of
		-- the body, an angle beside it, or a committed line through it.
		local r=a.rush
		if not r then a.untilTime=math.min(a.untilTime,now)
		else
			local b=a.target
			if not r.line and (not r.commitAt or now<r.commitAt) then r.goal=Brawler.rushGoal(a,r) end
			local toTarget=Vector3.new(b.root.Position.X-a.root.Position.X,0,b.root.Position.Z-a.root.Position.Z)
			local toGoal=Vector3.new(r.goal.X-a.root.Position.X,0,r.goal.Z-a.root.Position.Z)
			local committed=r.line~=nil or (r.commitAt~=nil and now>=r.commitAt)
			local face=if committed then toGoal elseif toTarget.Magnitude>.1 then toTarget else toGoal
			if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
			if toGoal.Magnitude<.6 or (not r.line and toTarget.Magnitude<=r.arrive) then a.untilTime=math.min(a.untilTime,now)
			else a.aimIntent={target=a.root.Position+toGoal,speed=r.speed,acceleration=1100} end
		end
	elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Brawl" and a.attackName=="WallDive" then
		-- Wall dive: a beat crouched against the wall (held by airHold), then a
		-- straight lunge at the opponent's body.
		local delta=a.target.root.Position-a.root.Position
		local flat=Vector3.new(delta.X,0,delta.Z)
		if flat.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+flat) end
		if a.state=="Active" and delta.Magnitude>2.8 then
			a.aimIntent={target=a.target.root.Position-delta.Unit*2.4,speed=92,acceleration=2600}
		end
	elseif a.state=="Active" and a.pending and a.pending.kind=="Brawl" and a.attackName=="Slam" then
  -- The slam owns a continuous plunge: a constant downward velocity with bounded
  -- acceleration, plus a gentle drift onto the victim. No per-frame correction.
  local delta=a.target.root.Position-a.root.Position
  local horizontal=Vector3.new(delta.X,0,delta.Z)
  if horizontal.Magnitude>2.7 then
   -- Horizontal only: an aimed move toward a point at the same height braked
   -- the plunge (vertical velocity pulled toward 0) and moved it twice.
   Motor.travel(a,self,horizontal,math.min(horizontal.Magnitude-2.7,42*dt))
  end
  if a.airborne then
   local landed=Motor.descend(a,self,118,dt)
   if landed or a.root.Position.Y<=self.match.origin.Y+3.6 then
    a.hum:ChangeState(Enum.HumanoidStateType.Landed)
    a.airborne=false;a.airHold=0
    a.root.AssemblyLinearVelocity=Vector3.zero
   end
  end
	elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Brawl" and a.pending.spec.air and not a.pending.spec.orbit then
  local delta=a.target.root.Position-a.root.Position
  if delta.Magnitude<10 and self:lineOfSight(a,a.target) then
		 local horizontal=Vector3.new(delta.X,0,delta.Z)
		 local planar=if horizontal.Magnitude>2.7 then horizontal.Unit*math.min(horizontal.Magnitude-2.7,30*dt) else Vector3.zero
		 local vertical=math.clamp(delta.Y,-48*dt,48*dt)
		 if math.abs(delta.Y)<.45 then vertical=0 end
		 local correction=planar+Vector3.new(0,vertical,0)
   Motor.flight(a,self,correction)
  end
 elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Brawl" and a.travelRemaining>0 then
		local toTarget=a.target.root.Position-a.root.Position
		local flatTarget=Vector3.new(toTarget.X,0,toTarget.Z)
		local gap=a.pending.spec.contact or 3.6
		if flatTarget.Magnitude>gap then
			local elapsed=now-(a.attackStarted or now)
			local progress=math.clamp(elapsed/a.pending.spec.travelTime,0,1)
			local drive=.32+1.18*math.sin(progress*math.pi)
			if flatTarget.Magnitude>.1 then a.travelDirection=(a.travelDirection:Lerp(flatTarget.Unit,math.min(1,dt*10))).Unit end
			local distance=math.min(a.travelRemaining,a.pending.spec.travel*drive*dt/a.pending.spec.travelTime,flatTarget.Magnitude-gap)
			a.travelRemaining-=Motor.travel(a,self,a.travelDirection,distance)
		end
	end
 local attack=a.pending
 if attack and attack.kind=="Brawl" and (a.state=="Startup" or a.state=="Active") then
  local delta=a.target.root.Position-a.root.Position
  local flat=Vector3.new(delta.X,0,delta.Z)
  -- A locked strike starting up to 11 studs out turns into the opponent here
  -- (Brawler.start no longer snaps the body round in one frame).
  if flat.Magnitude>2 and flat.Magnitude<(if a.state=="Startup" and a.locked then 11 else 9) then
   local tangent=Vector3.new(-flat.Z,0,flat.X).Unit
   local spec=attack.spec
   if spec.orbit and a.state~="Recovery" then
    -- Lateral routes: swing around the opponent's guard while striking (an
    -- air switch vaults all the way to the other side).
    if spec.air then Motor.flight(a,self,tangent*(a.angleSide or 1)*dt*spec.orbit)
    else Motor.travel(a,self,tangent*(a.angleSide or 1),dt*spec.orbit) end
   elseif a.fighterId=="Flashstep" and spec.angle then
    Motor.travel(a,self,tangent*(if spec.angle<0 then -1 else 1),dt*(if a.airborne then 9 else 7))
   elseif a.fighterId=="Mirage" and a.state=="Active" and a.hitConfirmed and (attack.name=="Light3" or attack.name=="Air2") then
    Motor.travel(a,self,-flat,dt*9)
   end
   self:turnToward(a,flat,dt,1080)
  end
 end
	if a.landedAtSerial~=a.model:GetAttribute("MovementLandedAt") then
		a.landedAtSerial=a.model:GetAttribute("MovementLandedAt")
		-- Only a real drop shakes the lens and throws debris; a ninja jump lands
		-- light (Motor still leaves its small dust ring).
		if a.landedAtSerial and a.model:GetAttribute("MovementHardLanding")==true then self:pushImpact(a.root.Position,"landing",false) end
	end
	if a.aimIntent then
		-- Chase, slam drift and any other aimed motion outrank the hover window;
		-- hovering exists to hold a fighter still, never to cancel their movement.
		Motor.step(a,self,dt,now)
	elseif a.state=="Active" and a.attackName=="Slam" and a.airborne then
		-- The slam branch above already drove this frame's plunge; holding the
		-- body here would zero it every frame (a ~5 studs/s float, not a dive).
	elseif now<(a.airHold or 0) and a.airborne then
		a.root.AssemblyLinearVelocity=Vector3.zero; a.hum:Move(Vector3.zero)
	else Motor.step(a,self,dt,now) end
	-- Server-owned humanoids + server-clamped arena coordinates.
	local p=a.root.Position
	if Vector3.new(p.X-self.match.origin.X,0,p.Z-self.match.origin.Z).Magnitude>Config.ArenaRadius or p.Y<self.match.origin.Y-3 then self:relocate(a,p) end
	World.pose(a,now,dt)
end
local IMPACT_STYLE={wire="shuriken",kunai="kunai",marked="kunai",shuriken="shuriken",wind="jutsu",fireball="fire",phoenix="ember",palm="palmburst",sand="sandhit",sandwave="sandburst"}
-- Eight Trigrams Rotation: blades and fire near the dome are deflected, and an
-- opponent inside it is thrown out once. Repelling a strike opens a counter.
local REFLECTED={kunai="kunai",shuriken="shuriken",marked="kunai"}
function Combat:stepRotation(a)
	-- Skill builds: a wider dome (rotationReach) and blades sent back at their
	-- thrower (rotationReflect), both set by Techniques.Rotation from the spec.
	local reach=a.rotationReach or Techniques.ROTATION_REACH or 7
	for i=#self.projectiles,1,-1 do
		local p=self.projectiles[i]
		if p.a~=a and (p.position-a.root.Position).Magnitude<=reach+1.5 then
			table.remove(self.projectiles,i)
			self:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=p.a.id,direction=-p.direction})
			Brawler.event(self,a,"Deflect")
			local thrower=p.a
			if a.rotationReflect and REFLECTED[p.kind] and thrower.health>0 and a.target==thrower then
				local gap=(thrower.root.Position-p.position).Magnitude
				local back=self:projectile(a,thrower.root.Position,p.speed,gap+8,p.damage,REFLECTED[p.kind],nil,{origin=p.position})
				back.bounced=true
				Brawler.event(self,a,"Reflect")
			end
		end
	end
	local b=a.target
	a.rotationHit=a.rotationHit or {}
	if b and b.health>0 and not a.rotationHit[b] and (b.root.Position-a.root.Position).Magnitude<=reach then
		a.rotationHit[b]=true
		local attacking=b.state=="Startup" or b.state=="Active" or b.state=="Pursuit"
		local away=b.root.Position-a.root.Position;away=Vector3.new(away.X,0,away.Z)
		away=if away.Magnitude>.1 then away.Unit else a.root.CFrame.LookVector
		self.damageTag="Rotation"
		local hit=self:damage(a,b,a.rotationDamage or 6,false,false)
		self.damageTag=nil
		if self.match.phase~="Duel" then return end
		-- The dome throws a body that was only standing in it out, even through a
		-- guard; a strike it turns aside staggers out of the dome instead, still
		-- inside the palm that answers (Techniques.rotationCounter).
		if hit then
			if attacking and b.airborne then Brawler.react(self,b,"Juggled",away*16+Vector3.new(0,14,0),.6,a)
			elseif attacking then Brawler.react(self,b,"HitStun",away*20,.6,a)
			else Brawler.react(self,b,"Knockback",away*48+Vector3.new(0,18,0),.55,a) end
		end
		self:pushImpact(b.root.Position,"repel",true,{owner=a.id,direction=away})
		if attacking then
			a.counterUntil=self.now+.9
			a.counterReach={expires=self.now+.9,max=7,variant="TrigramCounter"}
			Brawler.event(self,a,"Repel")
			self:cue(a,"ROTATION • REPELLED • COUNTER",.8);self:cue(b,"REPELLED",.6)
			Techniques.rotationCounter(self,a)
		end
	end
end
-- Delayed releases (hidden shuriken, the Phoenix Flower volley). Each entry
-- re-checks its owner when it fires, so a hit fighter never keeps throwing.
function Combat:schedule(at,fn)
	self.scheduled=self.scheduled or {}
	table.insert(self.scheduled,{at=at,fn=fn})
end
function Combat:runScheduled()
	local list=self.scheduled
	if not list or #list==0 then return end
	local due={}
	for i=#list,1,-1 do if list[i].at<=self.now then table.insert(due,1,list[i]);table.remove(list,i) end end
	for _,entry in due do
		if self.match.phase~="Duel" then return end
		entry.fn()
	end
end
local function closestOnSegment(a,b,point)
	local ab=b-a
	local length=ab:Dot(ab)
	if length<1e-6 then return a end
	return a+ab*math.clamp((point-a):Dot(ab)/length,0,1)
end
-- A Katon blast: the impact flash, a short splash, then flames that keep the
-- ground dangerous for a moment.
function Combat:fireExplosion(p,position,direct)
	local target=p.a.target
	-- A blast that misses the body becomes space denial: a wider patch of
	-- burning ground that holds the lane for a few seconds.
	if direct then self:addHazard(p.a,position,5.5,1.5,p.damage*.6,"Fire")
	else self:addHazard(p.a,position,7.5,3.2,p.damage*.45,"Fire") end
	if not direct and target and target.health>0 then
		local delta=target.root.Position-position
		if delta.Magnitude<=7.5 and workspace:Raycast(position,delta,self:rayParams(true))==nil then
			self.damageTag="splash"
			self:damage(p.a,target,p.damage*.5,false,false)
			self.damageTag=nil
		end
	end
end
-- Skill-build riders (SkillBuilds) on a clean projectile hit: a chase window
-- (Wind Cut, or a ricochet/Geometry blade with ToolMastery.Chase), a closed
-- chakra point (Vacuum Palm) and the fire patch of a blade that crossed the
-- thrower's burning ground. Inert for canonical kits.
function Combat:projectileRiders(p,target)
	local riders=p.riders or {}
	local owner=p.a
	local mastery=owner.def.ToolMastery
	local chase=riders.chase
	if not chase and p.bounced and p.kind=="shuriken" and mastery and mastery.Chase then chase=mastery.Chase end
	if chase then
		owner.pursuitUntil=math.max(owner.pursuitUntil or 0,self.now+chase)
		self:cue(owner,if p.kind=="wind" then "GUST • E TO CHASE" else "BLADE • E TO PURSUE",chase)
		Brawler.event(self,owner,"RiderChase")
	end
	if riders.tenketsu and owner.def.GentleFist and target.health>0 then
		Brawler.gentleFist(self,owner,target,false)
		self:cue(owner,"VACUUM PALM • POINT CLOSED",.6)
	end
	if p.ignited and mastery and mastery.FireBlades then
		self:addHazard(owner,Vector3.new(target.root.Position.X,self.match.origin.Y+.5,target.root.Position.Z),2.5,mastery.FireBlades.Patch,p.damage,"Fire")
	end
end
-- Fire Geometry (skill build): a thrower's shuriken that crosses his own
-- burning ground catches fire once (+damage, an ember on the client).
function Combat:igniteBlade(p)
	local fire=p.a.def.ToolMastery.FireBlades
	for _,h in self.hazards do
		if h.a==p.a and h.kind=="Fire" then
			local d=p.position-h.position
			if Vector3.new(d.X,0,d.Z).Magnitude<=h.radius and math.abs(d.Y)<6 then
				p.ignited=true;p.damage+=fire.Damage
				self:pushImpact(p.position,"ember",false,{projectile=p.id,kind=p.kind,owner=p.a.id,direction=p.direction})
				Brawler.event(self,p.a,"BladeIgnited")
				return true
			end
		end
	end
	return false
end
function Combat:projectileHit(p,target,position,normal)
	local style=IMPACT_STYLE[p.kind] or "shuriken"
	self:pushImpact(position,style,p.kind=="fireball",{projectile=p.id,kind=p.kind,normal=normal,owner=p.a.id,victim=target.id,direction=p.direction})
	-- The entry still finishes the blade on the client; it only reads as a body
	-- hit once the defence has resolved. A blade that was evaded, parried or
	-- absorbed ends silently ("spent"): the defence pushed its own effect.
	local entry=self.impacts[#self.impacts]
	self.damageTag=p.kind
	self.hitOrigin=position-p.direction*4
	local damaged=self:damage(p.a,target,p.damage,false,false)
	if not damaged and entry and entry.projectile==p.id then entry.style="spent";entry.heavy=false end
	self.hitOrigin=nil
	self.damageTag=nil
	if self.match.phase~="Duel" then return end
	-- Infused objects add their own consequence (guard crush, shock, ignition,
	-- gust, current through a wire) once the defence has resolved.
	if p.chakra then
		if entry and entry.projectile==p.id then entry.infusion=p.infusion end
		Chakra.contact(self,p,target,damaged)
		if self.match.phase~="Duel" then return end
	end
	local guarded=target.impactStyle=="block"
	if damaged and not guarded then
		if p.kind=="sandwave" then
			Techniques.bindInSand(self,p.a,target)
		elseif p.kind=="wire" then
			Techniques.wireBind(self,p.a,target,p.riders,p.direction)
		elseif p.kind=="palm" then
			-- Vacuum Palm: a wall of air that carries the body away.
			local push=Vector3.new(p.direction.X,0,p.direction.Z)
			if push.Magnitude<.05 then push=p.a.root.CFrame.LookVector end
			Brawler.react(self,target,"Knockback",push.Unit*54+Vector3.new(0,12,0),.5,p.a)
		elseif p.kind=="wind" then
			target.root.AssemblyLinearVelocity=p.direction*37+Vector3.new(0,14,0)
		elseif p.kind=="fireball" then
			local push=Vector3.new(p.direction.X,0,p.direction.Z)
			if push.Magnitude<.05 then push=p.a.root.CFrame.LookVector end
			Brawler.react(self,target,"Knockback",push.Unit*44+Vector3.new(0,20,0),.55,p.a)
		end
		if p.riders or p.bounced or p.ignited then self:projectileRiders(p,target) end
	end
	-- Blades thrown at a body pinned against a wall nail it there a little longer
	-- (Itachi's precision): the wall phase is extended, never restarted.
	if damaged and not guarded and (p.kind=="shuriken" or p.kind=="kunai" or p.kind=="marked") and target.reaction=="WallSplat" then
		Brawler.pin(self,target,.34,p.a)
	end
	-- A guarded blast is absorbed whole: no burning ground under a raised guard.
	if p.kind=="fireball" and not guarded then self:fireExplosion(p,position,true) end
	-- A marked blade that connects leaves its seal on the body; a guarded one
	-- drops at the guard's feet.
	if p.onSurface then
		if damaged and not guarded and target.health>0 then p.onSurface(position,normal or Vector3.yAxis,target)
		else
			local floor=workspace:Raycast(target.root.Position,Vector3.new(0,-8,0),self:rayParams(true))
			p.onSurface(if floor then floor.Position else position,if floor then floor.Normal else Vector3.yAxis)
		end
	end
end
function Combat:projectileSurface(p,hit)
	local style=if p.kind=="fireball" then "fire" elseif p.kind=="phoenix" then "ember" elseif p.kind=="wind" then "jutsu" elseif p.kind=="palm" then "palmburst" else "stick"
	local mastery=p.a.def.ToolMastery
	local target=p.a.target
	-- Itachi's ricochet is decided first: a blade that bounces does not also stay.
	local bounceFrom=nil
	if mastery and mastery.Ricochet and p.kind=="shuriken" and not p.bounced and hit.Instance.CanCollide and math.abs(hit.Normal.Y)<.7
		and target and target.health>0 and (target.root.Position-hit.Position).Magnitude<36 then
		local from=hit.Position+hit.Normal*.8
		local clear=workspace:Raycast(from,target.root.Position-from,self:rayParams(true))
		if not clear or clear.Instance:IsDescendantOf(target.model) then bounceFrom=from end
	end
	-- A chakra blade stays planted (a contestable point), a fire blade leaves a
	-- burning point, a missed wire stays stretched: decided before the impact
	-- so the client draws the object that stays instead of a plain stuck blade.
	local stayed=(p.chakra or p.kind=="wire") and not bounceFrom and Chakra.surface(self,p,hit.Position,hit.Normal,hit.Instance)
	local marker=if stayed and stayed.wire then "stretch" elseif stayed and stayed.point then "plant" else nil
	self:pushImpact(hit.Position,style,p.kind=="fireball",{projectile=p.id,kind=p.kind,normal=hit.Normal,owner=p.a.id,direction=p.direction,chakra=marker,infusion=p.infusion})
	if p.kind=="fireball" then self:fireExplosion(p,hit.Position+hit.Normal*1.5,false) end
	if p.kind=="phoenix" then self:addHazard(p.a,hit.Position+hit.Normal*1.2,3.4,1.8,p.damage*.6,"Fire") end
	if self.match.phase~="Duel" then return end
	if p.onSurface and hit.Instance.CanCollide then p.onSurface(hit.Position,hit.Normal) end
	if bounceFrom then
		local bounce=self:projectile(p.a,target.root.Position,p.speed*.9,40,p.damage,"shuriken",nil,{origin=bounceFrom})
		bounce.bounced=true
		-- An infused blade keeps its chakra through the bounce (no second scaling).
		Chakra.inherit(bounce,p)
		self:pushImpact(hit.Position,"deflect",false,{owner=p.a.id})
		Brawler.event(self,p.a,"Ricochet")
	end
end
-- Itachi's Shuriken Geometry: a blade thrown wide of the opponent, a second
-- thrown to strike it beside them; the collision sends both into the flank.
function Combat:shurikenGeometry(a,sideSign,infused)
	local b=a.target
	local start=Combat.launchPoint(a,"Shuriken")
	local toward=Vector3.new(b.root.Position.X-start.X,0,b.root.Position.Z-start.Z)
	if toward.Magnitude<.1 then toward=a.root.CFrame.LookVector end
	local forward=toward.Unit
	local right=forward:Cross(Vector3.yAxis).Unit*-(sideSign~=0 and sideSign or 1)
	-- The meeting point: beside the opponent and a little past them.
	local meet=b.root.Position+right*-6+forward*1.5
	meet=Vector3.new(meet.X,start.Y,meet.Z)
	local flight=(meet-start).Magnitude
	local arrive=flight/70
	a.neutralToolAt=self.now+.8
	self:beginThrow(a,{kind="Shuriken",release=.12,count=2,interval=.1,fire=function(index)
		local from=Combat.launchPoint(a,"Shuriken")
		local gap=(meet-from).Magnitude
		-- The second blade is thrown later and faster: both reach the point together.
		local speed=if index==1 then 70 else math.max(70,gap/math.max(.08,arrive-.1))
		local p=self:projectile(a,meet,speed,gap,0,"shuriken",nil,{origin=from})
		p.geometry=index==1 and {meet=meet,chakra=infused}
	end})
	self:cue(a,"SHURIKEN GEOMETRY",.7)
	Brawler.event(self,a,"Geometry")
	return true
end
function Combat:projectileExpire(p)
	if p.geometry and p.a.target and p.a.target.health>0 then
		local b=p.a.target
		self:pushImpact(p.position,"clash",false,{owner=p.a.id,direction=p.direction})
		for k=1,2 do
			local aim=b.root.Position+Vector3.new(0,(k-1.5)*.8,0)
			local redirected=self:projectile(p.a,aim,88,18,2.5,"shuriken",nil,{origin=p.position,chakra=p.geometry.chakra})
			redirected.bounced=true
		end
		Brawler.event(self,p.a,"GeometryHit")
		return
	end
	if p.kind=="fireball" then
		self:pushImpact(p.position,"fire",true,{projectile=p.id,kind=p.kind,normal=Vector3.yAxis,owner=p.a.id,direction=p.direction})
		self:fireExplosion(p,p.position,false)
		return
	end
	if p.kind=="phoenix" then
		self:pushImpact(p.position,"ember",false,{projectile=p.id,kind=p.kind,normal=Vector3.yAxis,owner=p.a.id,direction=p.direction})
		return
	end
	-- A chakra blade (or a wire) at the end of its flight drops and stays there.
	if Chakra.expire(self,p) then return end
	-- A marked kunai that reaches the end of its flight drops to the ground and
	-- still plants its seal there: a long throw is a long-range anchor.
	if p.kind=="marked" and p.onSurface then
		local floor=workspace:Raycast(p.position,Vector3.new(0,-80,0),self:rayParams(true))
		if floor then
			self:pushImpact(floor.Position,"stick",false,{projectile=p.id,kind=p.kind,normal=floor.Normal,owner=p.a.id,direction=p.direction})
			p.onSurface(floor.Position,floor.Normal)
			return
		end
	end
	self:pushImpact(p.position,"fade",false,{projectile=p.id,kind=p.kind,owner=p.a.id})
end
function Combat:updateProjectiles(dt)
	-- Meetings in flight, planted points and stretched wires (ChakraCombat).
	Chakra.step(self,dt)
	if self.match.phase~="Duel" then return end
	for i=#self.projectiles,1,-1 do
		local p=self.projectiles[i]
		if not p or self.match.phase~="Duel" then return end
		-- Removed by a meeting, or planted: never moved here. A projectile without
		-- speed (a reflection of something planted) cannot fly either.
		if p.dead or p.planted or (p.speed or 0)<=0 then
			if p.dead or not p.planted then
				local index=table.find(self.projectiles,p)
				if index then table.remove(self.projectiles,index) end
			end
			continue
		end
		if p.kind=="shuriken" and not p.ignited and p.a.def.ToolMastery and p.a.def.ToolMastery.FireBlades then self:igniteBlade(p) end
		local travel=math.min(p.speed*dt,p.remaining)
		local step=p.direction*travel
		local target=p.a.target
		local done=false
		-- Volumetric techniques test the body against the swept sphere, so a
		-- fireball that visibly engulfs the fighter always connects.
		local radius=p.radius+p.growth*(self.now-p.born)
		if radius>0 and target and target.health>0 then
			local closest=closestOnSegment(p.position,p.position+step,target.root.Position)
			if (target.root.Position-closest).Magnitude<=radius+1.2 then
				self:projectileHit(p,target,closest,-p.direction)
				if self.match.phase~="Duel" then return end
				done=true
			end
		end
		if not done then
			local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
			local exclude={self.match.effects,p.a.model}
			if radius>0 and target then table.insert(exclude,target.model) end
			ray.FilterDescendantsInstances=exclude
			local hit=workspace:Raycast(p.position,step,ray)
			if hit then
				if target and hit.Instance:IsDescendantOf(target.model) then
					self:projectileHit(p,target,hit.Position,hit.Normal)
				else
					self:projectileSurface(p,hit)
				end
				if self.match.phase~="Duel" then return end
				done=true
			end
		end
		p.position+=step; p.remaining-=travel
		if not done and p.remaining<=0 then
			self:projectileExpire(p)
			if self.match.phase~="Duel" then return end
		end
		if done or p.remaining<=0 or p.a.health<=0 or p.dead then
			local index=table.find(self.projectiles,p)
			if index then table.remove(self.projectiles,index) end
		end
	end
end
function Combat:updateHazards()
	for i=#self.hazards,1,-1 do
		local h=self.hazards[i]
		if self.now>=h.expires or h.a.health<=0 then table.remove(self.hazards,i)
		else
			local target=h.a.target
			local delta=target.root.Position-h.position
			local flat=Vector3.new(delta.X,0,delta.Z)
			if target.health>0 and flat.Magnitude<=h.radius and math.abs(delta.Y)<6 and self.now-(h.lastHit[target] or -10)>0.48 then
				local ray=workspace:Raycast(h.position,target.root.Position-h.position,self:rayParams(true))
				if not ray then
					h.lastHit[target]=self.now
					self.damageTag="burn"
					self:damage(h.a,target,h.damage*0.34,false,false)
					self.damageTag=nil
				end
			end
		end
	end
end
-- Bodies do not collide physically (that made fighters climb each other);
-- two grounded fighters closer than a body width are eased apart instead.
function Combat:separate()
	local a,b=self.actors[1],self.actors[2]
	if not a or not b or a.health<=0 or b.health<=0 or a.grabVictim or b.grabVictim then return end
	local delta=b.root.Position-a.root.Position
	local flat=Vector3.new(delta.X,0,delta.Z)
	local gap=flat.Magnitude
	if gap>=3 or math.abs(delta.Y)>4 then return end
	local push=math.min(3-gap,.35)*.5
	local dir=if gap>.05 then flat.Unit else a.root.CFrame.RightVector
	Motor.travel(a,self,-dir,push);Motor.travel(b,self,dir,push)
end
function Combat:update(dt,now)
	self.now=now
	if self.match.phase~="Duel" then return end
	-- Record every frame. Sampling at 1/30 used to validate contact against a
	-- position up to a third of a second stale while the attacker closed in,
	-- so visibly connected strikes were rejected as out of range.
	for _,a in self.actors do HitDetection.record(a.root,now) end
	for _,a in self.actors do
		if self.match.phase~="Duel" then break end
		self:updateActor(a,dt)
	end
	if self.match.phase=="Duel" then self:separate() end
	if self.match.phase=="Duel" then self:runScheduled() end
	if self.match.phase=="Duel" then self:updateProjectiles(dt); self:updateHazards() end
	for i=#self.effects,1,-1 do
		local e=self.effects[i]
		if e.expires<=now or not e.part.Parent then e.part:Destroy(); table.remove(self.effects,i) end
	end
end
function Combat:clear(preserveAnimations)
	for _,a in self.actors do
		HitDetection.clear(a.root)
		if not preserveAnimations then Animation.clear(a) end
		Bangla.close(a.pending); Motor.reset(a);
		Brawler.releaseGrab(a); a.reaction=nil; a.reactionVelocity=nil; a.buffered=nil; a.airHold=0; a.pursuitUntil=0; a.chainOpen=false
		a.state=if a.health>0 then "Neutral" else "Defeated";Defense.guard(a,false,self.now);a.readUntil=0;a.bonusUntil=0;a.dodgeUntil=0;a.invulnerableUntil=0;a.travelRemaining=0
		a.evade=nil;a.donorHitCount=0;a.donorLastHit=nil; a.combo=0;a.lastAttack=-10;a.throwing=nil;a.castId=nil;a.flashUntil=0;a.hop=nil;a.counterUntil=0;a.hitBlocked=false;
		a.anchors={};a.comboHits=0;a.comboDamage=0;a.splatAt=nil;a.splatPins=0;a.flashCancel=nil
		a.rotationUntil=0;a.flurryUntil=0;a.sealedUntil=0;a.tenketsu=0;a.tenketsuUntil=0
		a.rushArriveUntil=0;a.awakenUntil=0;a.flowStreak=0;a.nextFlow=nil;a.grabbedAt=nil;a.boundBy=nil
		Brawler.resetStrings(a);a.intentMemory=nil;a.intentOverride=nil;a.rush=nil;a.arrivalRecovery=nil;a.pursuitDuration=nil;a.rushReadyAt=0
		a.shieldCharges=a.def.SandShield and a.def.SandShield.Charges or 0
		a.attackName=nil; a.attackStarted=0; a.pending=nil; a.anchor=nil; a.illusionUntil=0; a.decoyPosition=nil; a.move=Vector3.zero; a.wall=nil
		a.hum:Move(Vector3.zero); a.root.AssemblyLinearVelocity=Vector3.zero; a.locomotion=Vector3.zero; a.airborne=false
	end
	self.match.effects:ClearAllChildren(); table.clear(self.effects); table.clear(self.projectiles); table.clear(self.hazards)
	if self.scheduled then table.clear(self.scheduled) end
	self.impacts={}; self.impactSerial=0
end
return Combat
