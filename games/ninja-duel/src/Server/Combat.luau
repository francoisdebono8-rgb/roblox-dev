local Shared = game:GetService("ReplicatedStorage").NinjaDuel
local Config = require(Shared.Config)
local Fighters = require(Shared.Fighters)
local Rules = require(Shared.Rules)
local World = require(script.Parent.World)
local Motor = require(script.Parent.Motor)
local Techniques = require(script.Parent.Techniques)
local Combat = {}; Combat.__index = Combat
function Combat.new(match)
	return setmetatable({match=match,now=0,actors={},effects={},projectiles={}},Combat)
end
function Combat:add(id,model,hum,root,joints,definition)
	local def = Fighters[definition]
	local a = { id=id,model=model,hum=hum,root=root,joints=joints,def=def,health=def.Health,
		chakra=Config.Chakra,state="Neutral",untilTime=0,lockUntil=0,cooldowns={},move=Vector3.zero,
		combo=0,lastAttack=-10,readUntil=0,illusionUntil=0,bonusUntil=0,dodgeUntil=0,invulnerableUntil=0,
		color=Color3.fromRGB(table.unpack(def.Color)),guardHeld=false,lastMove=0, cue="",cueUntil=0,
		locomotion=Vector3.zero,sprinting=false,airborne=false,airDodgeUsed=false,landUntil=0,
		pursuitUntil=0,travelRemaining=0,travelDirection=Vector3.zero,chainOpen=false,hitConfirmed=false }
	table.insert(self.actors,a)
	return a
end
function Combat:clamp(p)
	local o=self.match.origin; local r=Config.ArenaRadius
	return Vector3.new(math.clamp(p.X,o.X-r,o.X+r),math.clamp(p.Y,o.Y+3,o.Y+8),math.clamp(p.Z,o.Z-r,o.Z+r))
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
function Combat:cue(a,message,duration)
	a.cue=message; a.cueUntil=self.now+(duration or 1.1)
	if self.match.onCue then self.match.onCue(a,message) end
end
function Combat:setState(a,state,duration)
	a.state=state; a.untilTime=self.now+duration
end
function Combat:damage(attacker,victim,amount,heavy,readEligible)
	if self.match.phase~="Duel" or victim.health<=0 or attacker.health<=0 then return false end
	if victim.invulnerableUntil>self.now then self:cue(victim,"EVADED"); return false end
	local delta=attacker.root.Position-victim.root.Position
	local frontal=delta.Magnitude<0.1 or victim.root.CFrame.LookVector:Dot(delta.Unit)>0.15
	if readEligible and frontal and victim.readUntil>self.now then
		victim.readUntil=0; victim.bonusUntil=self.now+1.4; victim.chakra=math.min(100,victim.chakra+10)
		attacker.pending=nil; self:setState(attacker,"Stunned",0.48)
		self:setState(victim,"Neutral",0)
		self:cue(victim,"READ SUCCESS • PUNISH"); self:cue(attacker,"READ • EXPOSED")
		return false
	end
	local guarded=Rules.isGuard(victim,frontal)
	if guarded then
		victim.chakra=math.max(0,victim.chakra-amount*1.6)
		amount*=Config.GuardChip
		self:cue(victim,"GUARDED")
		if victim.chakra<=0 then
			victim.guardHeld=false; self:setState(victim,"Stunned",Config.GuardBreak); self:cue(victim,"GUARD BREAK")
		end
	else
		local interrupted=Rules.interruptible(victim)
		local protected= victim.state=="TechniqueChannel" and victim.pending and not victim.pending.spec.Interruptible
		if not protected then
			victim.pending=nil; victim.readUntil=0; victim.guardHeld=false
			self:setState(victim,"Stunned",if interrupted then Config.InterruptStun else Config.HitStun)
			if interrupted then self:cue(victim,"INTERRUPTED"); self:cue(attacker,"CHANNEL INTERRUPTED") end
		end
	end
	if attacker.bonusUntil>self.now then amount*=1.35; attacker.bonusUntil=0 end
	victim.health=math.max(0,victim.health-amount); victim.hum.Health=victim.health
	self:effect("Impact",victim.root.Position,if guarded then Color3.fromRGB(221,203,152) else attacker.color,Vector3.new(2,2,2),0.12)
	if heavy and not guarded and victim.health>0 then
		attacker.pursuitUntil=self.now+Config.PursuitWindow
		self:cue(attacker,"LAUNCH • E TO PURSUE",Config.PursuitWindow)
		local push=Vector3.new(-delta.X,0,-delta.Z)
		if push.Magnitude>0.1 then victim.root.AssemblyLinearVelocity=push.Unit*38+Vector3.new(0,28,0) end
	end
	if victim.health<=0 then
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
	if kind=="blade" then visual.CFrame=CFrame.new(start)*CFrame.Angles(0,0,math.pi/4) end
	table.insert(self.projectiles,{a=a,position=start,direction=delta.Unit,speed=speed,remaining=range,damage=damage,part=visual,onSurface=onSurface})
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
	if action=="Pursuit" then
		if a.pursuitUntil<=self.now or a.target.health<=0 then return false,"No pursuit" end
		if a.chakra<Config.PursuitCost then return false,"Need chakra" end
		if (a.target.root.Position-a.root.Position).Magnitude>Config.PursuitRange then return false,"Too far" end
		if a.state~="Neutral" and a.state~="Recovery" and a.state~="TechniqueRecovery" then return false,"Committed" end
		a.chakra-=Config.PursuitCost; a.pursuitUntil=0
		self:setState(a,"Pursuit",0.25)
		self:effect("Pursuit",a.root.Position,a.color,Vector3.new(2,4,2),0.35)
		return true
	end
	if action=="Jump" then
		if a.state~="Neutral" and a.state~="Recovery" then return false,"Committed" end
		return Motor.jump(a,self,self.now),"Airborne"
	end
	local chain=action=="Attack" and a.state=="Recovery" and a.chainOpen and self.now>a.chainAt
	if not chain and not Rules.canAct(a,self.now) then return false,"Committed" end
	if action=="Guard" then a.guardHeld=true; self:setState(a,"Guarding",0); return true end
	if action=="Dodge" then
		if a.chakra<Config.DodgeCost then return false,"Need chakra" end
		if a.airborne and a.airDodgeUsed then return false,"Air dodge used" end
		if a.dodgeUntil>self.now then return false,"Cooldown" end
		a.chakra-=Config.DodgeCost; a.dodgeUntil=self.now+Config.DodgeCooldown
		if a.airborne then a.airDodgeUsed=true end
		a.dodgeDirection=if a.move.Magnitude>0.1 then a.move.Unit else a.root.CFrame.RightVector
		a.invulnerableUntil=self.now+Config.DodgeIFrames; a.guardHeld=false
		self:setState(a,"Dodging",Config.DodgeTime); self:effect("Dodge",a.root.Position,a.color,Vector3.new(2,4,1),0.2)
		return true
	end
	if action=="Attack" then
		a.combo=if self.now-a.lastAttack>Config.ComboReset then 1 else a.combo%4+1
		a.lastAttack=self.now; a.guardHeld=false
		a.pending={kind="Melee",damage=a.def.MeleeDamage[a.combo],heavy=a.combo==4}
		a.hitConfirmed=false; a.chainOpen=false
		a.travelRemaining=a.def.MeleeTravel[a.combo]
		a.travelDirection=a.root.CFrame.LookVector
		local toTarget=a.target.root.Position-a.root.Position
		local horizontal=Vector3.new(toTarget.X,0,toTarget.Z)
		if horizontal.Magnitude<9 and horizontal.Magnitude>0.1 and a.root.CFrame.LookVector:Dot(horizontal.Unit)>0.66 then
			a.travelDirection=horizontal.Unit
			a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+horizontal.Unit)
		end
		self:setState(a,"Startup",a.def.Startup)
		return true
	end
	local slot=tonumber(string.match(action,"^Technique([123])$"))
	local spec=slot and a.def.Techniques[slot]
	if not spec then return false,"Unknown action" end
	local technique=Techniques[spec.Id]
	local ok,reason=Rules.technique(a,spec,self.now,technique.check(self,a,spec,self.now))
	if not ok then return false,reason end
	Rules.reserve(a,spec,self.now); a.guardHeld=false
	a.pending={kind="Technique",spec=spec,implementation=technique,aim=aim or a.target.root.Position}
	local offset=a.pending.aim-a.root.Position
	local flat=Vector3.new(offset.X,0,offset.Z)
	if flat.Magnitude>0.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+flat) end
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
		a.chakra=math.min(Config.Chakra,a.chakra+Config.ChakraRegen*dt)
	end
	if a.state~="Neutral" and a.state~="Guarding" and a.untilTime<=now then
		local pending=a.pending
		if a.state=="Startup" and pending then
			self:setState(a,"Active",0.09)
			self:strike(a,pending.damage,Config.MeleeRange,Config.MeleeFacing,pending.heavy)
		elseif a.state=="Active" then
			a.pending=nil; self:setState(a,"Recovery",if pending and pending.heavy then a.def.Recovery+0.14 else a.def.Recovery)
			a.chainOpen=a.combo<4 and a.hitConfirmed
			a.chainAt=now+0.05
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
	if a.locked and (a.state=="Neutral" or a.state=="Guarding") then
		a.hum.AutoRotate=false
		local toward=a.target.root.Position-a.root.Position; toward=Vector3.new(toward.X,0,toward.Z)
		if toward.Magnitude>0.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+toward) end
	else a.hum.AutoRotate=not a.locked end
	if a.state=="Dodging" then
		Motor.travel(a,self,a.dodgeDirection,Config.DodgeSpeed*dt)
	elseif a.state=="Pursuit" then
		local toTarget=a.target.root.Position-a.root.Position
		local flatTarget=Vector3.new(toTarget.X,0,toTarget.Z)
		if flatTarget.Magnitude>3 then Motor.travel(a,self,flatTarget,math.min(Config.PursuitSpeed*dt,flatTarget.Magnitude-3)) end
	elseif (a.state=="Startup" or a.state=="Active") and a.pending and a.pending.kind=="Melee" and a.travelRemaining>0 then
		local toTarget=a.target.root.Position-a.root.Position
		local flatTarget=Vector3.new(toTarget.X,0,toTarget.Z)
		if flatTarget.Magnitude>2.6 then
			local distance=math.min(a.travelRemaining,a.def.MeleeTravel[a.combo]*dt/Config.Movement.MeleeTravelTime,flatTarget.Magnitude-2.6)
			a.travelRemaining-=Motor.travel(a,self,a.travelDirection,distance)
		end
	end
	Motor.step(a,self,dt,now)
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
				self:damage(p.a,p.a.target,p.damage,false,false)
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
function Combat:update(dt,now)
	self.now=now
	if self.match.phase~="Duel" then return end
	for _,a in self.actors do
		if self.match.phase~="Duel" then break end
		self:updateActor(a,dt)
	end
	if self.match.phase=="Duel" then self:updateProjectiles(dt) end
	for i=#self.effects,1,-1 do
		local e=self.effects[i]
		if e.expires<=now or not e.part.Parent then e.part:Destroy(); table.remove(self.effects,i) end
	end
end
function Combat:clear()
	for _,a in self.actors do
		a.pending=nil; a.anchor=nil; a.illusionUntil=0; a.decoyPosition=nil; a.move=Vector3.zero
		a.hum:Move(Vector3.zero); a.root.AssemblyLinearVelocity=Vector3.zero; a.locomotion=Vector3.zero; a.airborne=false
	end
	self.match.effects:ClearAllChildren(); table.clear(self.effects); table.clear(self.projectiles)
end
return Combat
