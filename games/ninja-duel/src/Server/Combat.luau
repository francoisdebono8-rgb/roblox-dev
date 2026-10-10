local Shared = game:GetService("ReplicatedStorage").NinjaDuel
local Config = require(Shared.Config)
local Fighters = require(Shared.Fighters)
local Rules = require(Shared.Rules)
local World = require(script.Parent.World)
local Motor = require(script.Parent.Motor)
local Animation = require(script.Parent.Animation)
local Techniques = require(script.Parent.Techniques)
local Brawler = require(script.Parent.Brawler)
local Combat = {}; Combat.__index = Combat
function Combat.new(match)
	return setmetatable({match=match,now=0,actors={},effects={},projectiles={},hazards={}},Combat)
end
function Combat:add(id,model,hum,root,joints,definition)
	local def = Fighters[definition]
	local a = { id=id,fighterId=definition,model=model,hum=hum,root=root,joints=joints,def=def,health=def.Health,
		chakra=def.Chakra or Config.Chakra,state="Neutral",untilTime=0,lockUntil=0,cooldowns={},move=Vector3.zero,
		combo=0,lastAttack=-10,readUntil=0,illusionUntil=0,bonusUntil=0,dodgeUntil=0,invulnerableUntil=0,
		color=Color3.fromRGB(table.unpack(def.Color)),guardHeld=false,lastMove=0, cue="",cueUntil=0,
		locomotion=Vector3.zero,sprinting=false,airborne=false,airDodgeUsed=false,landUntil=0,
		pursuitUntil=0,travelRemaining=0,travelDirection=Vector3.zero,chainOpen=false,hitConfirmed=false,
		subCharges=Config.Substitution.Charges,subCooldown=0,lastHurt=-10,neutralToolAt=0,wall=nil,wallNext=0 }
	table.insert(self.actors,a)
	Animation.attach(a)
	return a
end
function Combat:clamp(p)
	local o=self.match.origin; local r=Config.ArenaRadius
	return Vector3.new(math.clamp(p.X,o.X-r,o.X+r),math.clamp(p.Y,o.Y+3,o.Y+Config.ArenaHeight),math.clamp(p.Z,o.Z-r,o.Z+r))
end
function Combat:relocate(a,p)
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
	local delta=b.root.Position-a.root.Position
	if delta.Magnitude>range then return false end
	if delta.Magnitude>0.1 and a.root.CFrame.LookVector:Dot(delta.Unit)<facing then return false end
	return self:lineOfSight(a,b)
end
function Combat:effect(name,p,color,size,lifetime)
	local v=World.part(self.match.effects,name,size,CFrame.new(p),color,Enum.Material.Neon)
	v.CanCollide=false; v.CanQuery=false; v.Transparency=0.4
	table.insert(self.effects,{part=v,expires=self.now+lifetime})
	return v
end
function Combat:addHazard(a,position,radius,duration,damage,kind)
	local hazard={a=a,position=position,radius=radius,expires=self.now+duration,damage=damage,kind=kind,lastHit={}}
	table.insert(self.hazards,hazard)
	return hazard
end
function Combat:cue(a,message,duration)
	a.cue=message; a.cueUntil=self.now+(duration or 1.1)
	if self.match.onCue then self.match.onCue(a,message) end
end
function Combat:setState(a,state,duration)
	a.state=state; a.untilTime=self.now+duration
end
function Combat:damage(attacker,victim,amount,heavy,readEligible)
	if self.match.phase~="Duel" or victim.health<=0 or attacker.health<=0 then return false end
	if victim.invulnerableUntil>self.now then Brawler.event(self,victim,"Evaded"); self:cue(victim,"EVADED"); return false end
	if victim.wall then Motor.detach(victim,self.now,false) end
	local delta=attacker.root.Position-victim.root.Position
	local frontal=delta.Magnitude<0.1 or victim.root.CFrame.LookVector:Dot(delta.Unit)>0.15
	if readEligible and frontal and victim.readUntil>self.now then
		victim.readUntil=0; victim.bonusUntil=self.now+1.4; victim.chakra=math.min(victim.def.Chakra or Config.Chakra,victim.chakra+10)
		attacker.pending=nil; self:setState(attacker,"Stunned",0.48)
		self:setState(victim,"Neutral",0)
		self:cue(victim,"READ SUCCESS • PUNISH"); self:cue(attacker,"READ • EXPOSED")
		return false
	end
	local guarded=Rules.isGuard(victim,frontal)
	if guarded then
		victim.chakra=math.max(0,victim.chakra-amount*1.6)
		amount*=victim.def.GuardStrength or Config.GuardChip
		self:cue(victim,"GUARDED")
		if victim.chakra<=0 then
			victim.guardHeld=false; self:setState(victim,"Stunned",Config.GuardBreak); self:cue(victim,"GUARD BREAK")
		end
	else
		local interrupted=Rules.interruptible(victim)
		local protected= victim.state=="TechniqueChannel" and victim.pending and not victim.pending.spec.Interruptible
		if not protected then
			Brawler.releaseGrab(victim)
			victim.pending=nil; victim.readUntil=0; victim.guardHeld=false
			self:setState(victim,"Stunned",if interrupted then Config.InterruptStun else Config.HitStun)
			if interrupted then Brawler.event(self,attacker,"Interrupt"); self:cue(victim,"INTERRUPTED"); self:cue(attacker,"CHANNEL INTERRUPTED") end
		end
	end
	if attacker.bonusUntil>self.now then amount*=1.35; attacker.bonusUntil=0 end
	victim.lastHurt=self.now
	victim.health=math.max(0,victim.health-amount); victim.hum.Health=victim.health
	victim.impactSerial=(victim.impactSerial or 0)+1; victim.impactHeavy=heavy or amount>=12
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
		self.match.finish(attacker,victim)
	end
	attacker.hitConfirmed=true
	return true
end
function Combat:strike(a,damage,range,facing,heavy)
	if self:targetValid(a,a.target,range,facing) then return self:damage(a,a.target,damage,heavy,true) end
	return false
end
function Combat:projectile(a,aim,speed,range,damage,kind,onSurface)
	local start=a.root.Position+a.root.CFrame.LookVector*1.4
	local delta=aim-start
	if delta.Magnitude<0.1 then delta=a.root.CFrame.LookVector end
	local visual=self:effect(kind,start,a.color,if kind=="blade" then Vector3.new(0.7,0.7,0.2) else Vector3.new(0.15,0.15,1.5),range/speed+0.15)
	if kind=="wind" then visual.Size=Vector3.new(3,.12,1.2);visual.Color=Color3.fromRGB(172,238,208) end
	if kind=="blade" then visual.CFrame=CFrame.new(start)*CFrame.Angles(0,0,math.pi/4) end
	table.insert(self.projectiles,{a=a,position=start,direction=delta.Unit,speed=speed,remaining=range,damage=damage,part=visual,onSurface=onSurface,kind=kind})
end
function Combat:request(a,action,aim)
	if self.match.phase~="Duel" or a.health<=0 then return false,"No duel" end
	if action=="GuardOff" then
		a.guardHeld=false
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
	if action=="Dodge" and not Brawler.free(a,self.now) then action="Substitute" end
	if action=="Substitute" then
		local tune=Config.Substitution
		if a.subCharges<=0 or self.now<a.subCooldown then return false,"No substitution" end
		if a.chakra<tune.Cost then return false,"Need chakra" end
		if self.now-a.lastHurt>tune.Window or (a.state~="Stunned" and Brawler.free(a,self.now)) then return false,"No escape window" end
		local away=a.root.Position-a.target.root.Position
		away=Vector3.new(away.X,0,away.Z)
		if away.Magnitude<0.1 then away=a.root.CFrame.RightVector end
		local departure=a.root.Position
		local moved=Motor.travel(a,self,away,tune.Distance)
		if moved<2 then return false,"Escape blocked" end
		a.subCharges-=1; a.chakra-=tune.Cost; a.subCooldown=self.now+tune.Cooldown
		a.subUntil=self.now+0.17
		Brawler.releaseGrab(a); a.reaction=nil; a.reactionVelocity=nil; a.airHold=0
		Brawler.event(self,a,"Substitute"); a.pending=nil; a.guardHeld=false; a.invulnerableUntil=self.now+0.16
		self:setState(a,"Recovery",0.16)
		self:effect("Afterimage",departure,a.color,Vector3.new(2,4,2),0.35)
		self:effect("Substitution",a.root.Position,a.color,Vector3.new(3,4,3),0.25)
		self:cue(a,"SUBSTITUTION • REPOSITIONED")
		return true
	end
	if action=="Feint" then
		local pending=a.pending
		if a.state~="TechniqueChannel" or not pending or not pending.spec.Feintable then return false,"No feint window" end
		if self.now>a.untilTime-pending.spec.Channel*0.5 then return false,"Feint too late" end
		a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+pending.spec.Cost*0.35)
		a.pending=nil; self:setState(a,"Recovery",0.24); self:cue(a,"FEINT • CHAKRA PARTIAL")
		return true
	end
	local handled,reason=Brawler.request(self,a,action)
	if handled~=nil then return handled,reason end
	if not Brawler.free(a,self.now) then return false,"Reacting" end
	if action=="Pursuit" then
		if a.pursuitUntil<=self.now or a.target.health<=0 then return false,"No pursuit" end
		if a.chakra<Config.PursuitCost then return false,"Need chakra" end
		if (a.target.root.Position-a.root.Position).Magnitude>Config.PursuitRange then return false,"Too far" end
		if a.state~="Neutral" and a.state~="Recovery" and a.state~="TechniqueRecovery" then return false,"Committed" end
		a.chakra-=Config.PursuitCost; a.pursuitUntil=0
		a.reaction=nil; a.airborne=true; a.airHold=self.now+.75
		Brawler.event(self,a,"Chase")
		self:setState(a,"Pursuit",0.24)
		self:effect("Pursuit",a.root.Position,a.color,Vector3.new(2,4,2),0.35)
		return true
	end
	if action=="Jump" then
		if a.wall then Motor.detach(a,self.now,true); return true end
		if a.state~="Neutral" and a.state~="Recovery" then return false,"Committed" end
		return Motor.jump(a,self,self.now),"Airborne"
	end
	if action=="Tool" then
		if not Rules.canAct(a,self.now) or self.now<a.neutralToolAt then return false,"Tool recovering" end
		if a.wall then Motor.detach(a,self.now,false) end
		a.neutralToolAt=self.now+(if a.def.Name=="Minato" then 0.7 else 0.9)
		self:projectile(a,aim or a.target.root.Position,if a.def.Name=="Minato" then 76 else 69,34,if a.def.Name=="Minato" then 4 else 5,"tool")
		self:setState(a,"Recovery",0.12); self:cue(a,"PROJECTILE")
		return true
	end
	local chain=action=="Attack" and a.state=="Recovery" and a.chainOpen and self.now>a.chainAt
	if not chain and not Rules.canAct(a,self.now) then return false,"Committed" end
	if action=="Guard" then Brawler.event(self,a,"Guard"); a.guardHeld=true; self:setState(a,"Guarding",0); return true end
	if action=="Dodge" then
		if a.chakra<Config.DodgeCost then return false,"Need chakra" end
		if a.airborne and a.airDodgeUsed then return false,"Air dodge used" end
		if a.dodgeUntil>self.now then return false,"Cooldown" end
		a.chakra-=Config.DodgeCost; a.dodgeUntil=self.now+Config.DodgeCooldown
		if a.wall then Motor.detach(a,self.now,false) end
		if a.airborne then a.airDodgeUsed=true end
		a.dodgeDirection=if a.move.Magnitude>0.1 then a.move.Unit else a.root.CFrame.RightVector
		a.invulnerableUntil=self.now+Config.DodgeIFrames; a.guardHeld=false
		Brawler.event(self,a,"Dodge"); self:setState(a,"Dodging",Config.DodgeTime); self:effect("Dodge",a.root.Position,a.color,Vector3.new(2,4,1),0.2)
		return true
	end
	if self.match.techniquesDisabled then return false,"Techniques disabled" end
	local slot=tonumber(string.match(action,"^Technique([1-5])$"))
	local spec=slot and a.def.Techniques[slot]
 if spec and (a.trainingChannelScale or 1)~=1 then spec=table.clone(spec);spec.Channel*=a.trainingChannelScale end
	if not spec then return false,"Unknown action" end
	local technique=Techniques[spec.Id]
	local ok,reason=Rules.technique(a,spec,self.now,technique.check(self,a,spec,self.now))
	if not ok then return false,reason end
	if a.wall then Motor.detach(a,self.now,false) end
	Brawler.event(self,a,"Technique"); Rules.reserve(a,spec,self.now); a.guardHeld=false
	a.pending={kind="Technique",spec=spec,implementation=technique,aim=aim or a.target.root.Position}
	local offset=a.pending.aim-a.root.Position
	local flat=Vector3.new(offset.X,0,offset.Z)
	if flat.Magnitude>0.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+flat) end
	if spec.Element=="Fire" then
  local telegraph=self:effect("Fire telegraph",a.root.Position+a.root.CFrame.LookVector*8-Vector3.new(0,2.7,0),Color3.fromRGB(255,175,95),Vector3.new(.06,11.6,11.6),spec.Channel)
  telegraph.Shape=Enum.PartType.Cylinder;telegraph.CFrame*=CFrame.Angles(0,0,math.pi/2);telegraph.Transparency=.82
 end
 self:cue(a,spec.Name.." • PREPARING",spec.Channel)
	self:effect("Channel",a.root.Position-Vector3.new(0,2.8,0),a.color,Vector3.new(4,0.12,4),spec.Channel)
	return true
end
function Combat:updateActor(a,dt)
	local now=self.now
	if a.health<=0 then a.hum:Move(Vector3.zero); return end
	if a.anchor and a.anchor.expires<=now then a.anchor.part:Destroy(); a.anchor=nil end
	if a.illusionUntil<=now then a.decoyPosition=nil end
	if a.state=="Guarding" then
		a.chakra=math.max(0,a.chakra-Config.GuardDrain*dt)
		if a.chakra<=0 then a.guardHeld=false; self:setState(a,"Stunned",Config.GuardBreak); self:cue(a,"GUARD BREAK") end
	elseif a.state~="TechniqueChannel" and a.state~="Stunned" then
		a.chakra=math.min(a.def.Chakra or Config.Chakra,a.chakra+(a.def.ChakraRegen or Config.ChakraRegen)*dt)
	end
	if a.state~="Neutral" and a.state~="Guarding" and a.untilTime<=now then
		local pending=a.pending
		if a.state=="Startup" and pending then
			self:setState(a,"Active",pending.spec.active)
		elseif a.state=="Active" then
			a.pending=nil; self:setState(a,"Recovery",if pending then pending.spec.recovery else .22)
			a.chainOpen=a.hitConfirmed and pending and pending.kind=="Brawl" and pending.spec.chain==true
			a.chainAt=now+0.035
		elseif a.state=="TechniqueChannel" and pending then
			-- State changes before payoff so simultaneous channels resolve deterministically.
			self:setState(a,"TechniqueActive",pending.spec.Active)
			pending.implementation.execute(self,a,pending,now)
		elseif a.state=="TechniqueActive" and pending then
			a.pending=nil; self:setState(a,"TechniqueRecovery",pending.spec.Recovery)
		else
			a.pending=nil; self:setState(a,"Neutral",0)
		end
	end
	if self.match.phase~="Duel" then a.hum:Move(Vector3.zero); return end
	if Brawler.step(self,a,dt) then World.pose(a,now,dt); return end
	if a.locked and (a.state=="Neutral" or a.state=="Guarding") then
		a.hum.AutoRotate=false
		local toward=a.target.root.Position-a.root.Position; toward=Vector3.new(toward.X,0,toward.Z)
		if toward.Magnitude>0.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+toward) end
	else a.hum.AutoRotate=not a.locked end
	if a.state=="Dodging" then
		Motor.travel(a,self,a.dodgeDirection,Config.DodgeSpeed*(a.def.DashScale or 1)*dt)
	elseif a.state=="Pursuit" then
		local toTarget=a.target.root.Position-a.root.Position
		if toTarget.Magnitude>3 then Motor.flight(a,self,toTarget.Unit*math.min(100*dt,toTarget.Magnitude-3)) end
	elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Brawl" and (a.attackName=="Air1" or a.attackName=="Air2" or a.attackName=="Slam") then
  local delta=a.target.root.Position-a.root.Position
  if delta.Magnitude<10 and self:lineOfSight(a,a.target) then
   local correction=Vector3.new(0,math.clamp(delta.Y,-40*dt,40*dt),0)
   if math.abs(delta.Y)<.6 then correction=Vector3.zero end
   Motor.flight(a,self,correction)
  end
 elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Brawl" and a.travelRemaining>0 then
		local toTarget=a.target.root.Position-a.root.Position
		local flatTarget=Vector3.new(toTarget.X,0,toTarget.Z)
		if flatTarget.Magnitude>2.6 then
			local distance=math.min(a.travelRemaining,a.pending.spec.travel*dt/a.pending.spec.travelTime,flatTarget.Magnitude-2.6)
			a.travelRemaining-=Motor.travel(a,self,a.travelDirection,distance)
		end
	end
	if now<(a.airHold or 0) and a.airborne then
		a.root.AssemblyLinearVelocity=Vector3.zero; a.hum:Move(Vector3.zero)
	else Motor.step(a,self,dt,now) end
	-- Server-owned humanoids + server-clamped arena coordinates.
	local p=a.root.Position
	if math.abs(p.X-self.match.origin.X)>Config.ArenaRadius or math.abs(p.Z-self.match.origin.Z)>Config.ArenaRadius or p.Y<self.match.origin.Y-3 then self:relocate(a,p) end
	World.pose(a,now,dt)
end
function Combat:updateProjectiles(dt)
	for i=#self.projectiles,1,-1 do
		local p=self.projectiles[i]
		if not p or self.match.phase~="Duel" then return end
		local step=p.direction*math.min(p.speed*dt,p.remaining)
		local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
		ray.FilterDescendantsInstances={self.match.effects,p.a.model}
		local hit=workspace:Raycast(p.position,step,ray)
		local done=false
		if hit then
			if hit.Instance:IsDescendantOf(p.a.target.model) then
				local damaged=self:damage(p.a,p.a.target,p.damage,false,false)
				if damaged and p.kind=="wind" then
					p.a.target.root.AssemblyLinearVelocity=p.direction*37+Vector3.new(0,14,0)
				end
				if self.match.phase~="Duel" then return end
				-- A blade also leaves an anchor beneath its struck target.
				if p.onSurface then p.onSurface(hit.Position,hit.Normal) end
			elseif p.onSurface and hit.Instance.CanCollide then p.onSurface(hit.Position,hit.Normal) end
			done=true
		end
		p.position+=step; p.remaining-=step.Magnitude
		if p.part.Parent then p.part.CFrame=CFrame.lookAt(p.position,p.position+p.direction) end
		if done or p.remaining<=0 or p.a.health<=0 then p.part:Destroy(); table.remove(self.projectiles,i) end
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
					self:damage(h.a,target,h.damage*0.34,false,false)
				end
			end
		end
	end
end
function Combat:update(dt,now)
	self.now=now
	if self.match.phase~="Duel" then return end
	for _,a in self.actors do
		if self.match.phase~="Duel" then break end
		self:updateActor(a,dt)
	end
	if self.match.phase=="Duel" then self:updateProjectiles(dt); self:updateHazards() end
	for i=#self.effects,1,-1 do
		local e=self.effects[i]
		if e.expires<=now or not e.part.Parent then e.part:Destroy(); table.remove(self.effects,i) end
	end
end
function Combat:clear(preserveAnimations)
	for _,a in self.actors do
		if not preserveAnimations then Animation.clear(a) end
		Brawler.releaseGrab(a); a.reaction=nil; a.reactionVelocity=nil; a.buffered=nil; a.airHold=0; a.pursuitUntil=0; a.chainOpen=false
		a.state=if a.health>0 then "Neutral" else "Defeated"; a.guardHeld=false; a.readUntil=0; a.bonusUntil=0; a.dodgeUntil=0; a.invulnerableUntil=0; a.travelRemaining=0
		a.attackName=nil; a.attackStarted=0; a.pending=nil; a.anchor=nil; a.illusionUntil=0; a.decoyPosition=nil; a.move=Vector3.zero; a.wall=nil
		a.hum:Move(Vector3.zero); a.root.AssemblyLinearVelocity=Vector3.zero; a.locomotion=Vector3.zero; a.airborne=false
	end
	self.match.effects:ClearAllChildren(); table.clear(self.effects); table.clear(self.projectiles); table.clear(self.hazards)
end
return Combat
