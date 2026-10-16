-- Adapted from Velmora CombatService guard/parry/dodge resolution.
-- Copyright (c) 2026 Yashveer Singh, MIT.
local Tune=require(game:GetService('ReplicatedStorage').NinjaDuel.VelmoraCombatConfig)
local Defense={}
function Defense.init(a)
	a.stamina=100;a.guardPressedAt=-math.huge;a.parryReadyAt=0;a.dodgeStartedAt=-math.huge;a.bloodstepGrantedFor=-math.huge
end
function Defense.guard(a,down,now)
	if down and not a.guardHeld then a.guardPressedAt=now end
	a.guardHeld=down
end
function Defense.dodge(a,now)
	a.dodgeStartedAt=now
	a.invulnerableUntil=math.max(a.invulnerableUntil,now+Tune.DodgeIFrames)
end
-- `melee`: the blow came from the attacker's own body. Only then can a parry
-- stun them; a parried blade, flame or hazard is simply negated.
function Defense.resolve(c,attacker,victim,amount,frontal,melee)
	-- Itachi's Sharingan sees the strike coming: wider windows, and every
	-- clean read opens a counter.
	local eye=victim.def and victim.def.Sharingan
	if eye and (victim.awakenUntil or 0)>c.now and victim.def.Awakening and victim.def.Awakening.Windows then
		local k=victim.def.Awakening.Windows
		eye={ParryWindow=eye.ParryWindow*k,PerfectDodge=eye.PerfectDodge*k,Counter=eye.Counter}
	end
	if victim.invulnerableUntil>c.now then
		local clean=c.now-victim.dodgeStartedAt<=(if eye then eye.PerfectDodge else Tune.BloodstepWindow) and victim.bloodstepGrantedFor~=victim.dodgeStartedAt
		if clean then
			victim.bloodstepGrantedFor=victim.dodgeStartedAt;victim.bonusUntil=c.now+.8;victim.riposteUntil=c.now+.5
			if eye then victim.counterUntil=c.now+eye.Counter;c:cue(victim,'SHARINGAN • PERFECT DODGE • COUNTER')
			else c:cue(victim,'PERFECT DODGE • BLOODSTEP') end
		end
		return 'Evaded',0
	end
	if not frontal or not victim.guardHeld then return 'Hit',amount end
	local since=c.now-victim.guardPressedAt
	local window=if eye then eye.ParryWindow else Tune.ParryWindow
	-- Sharingan Focus: the raised guard itself reads. Any frontal blow that
	-- meets it is parried (parry cooldown and stamina still apply) and read.
	local focus=eye~=nil and victim.def.Awakening and victim.def.Awakening.GuardRead==true and (victim.awakenUntil or 0)>c.now
	if focus then window=1e3 end
	-- Closed chakra points (Gentle Fist) compromise the guard: the parry
	-- window narrows with each one (none left at four) and a blocked blow costs
	-- more stamina.
	local points=Defense.closedPoints(victim,c.now)
	window*=math.max(0,1-.25*points)
	if since<=window and c.now>=victim.parryReadyAt and victim.stamina>=Tune.ParryCost then
		victim.stamina-=Tune.ParryCost;victim.parryReadyAt=c.now+Tune.ParryCooldown;victim.guardPressedAt=-math.huge
		if not melee then c:cue(victim,'DEFLECTED');return 'Parried',0 end
		attacker.pending=nil;attacker.guardHeld=false;c:setState(attacker,'Stunned',Tune.ParryStun)
		if eye then victim.counterUntil=c.now+eye.Counter;c:cue(victim,'SHARINGAN • PARRY • COUNTER')
		else c:cue(victim,'PARRY • PUNISH') end
		if focus then
			victim.bonusUntil=c.now+1;victim.counterReach={expires=c.now+eye.Counter,max=4,variant="ReadCounter"}
			Defense.slip(c,victim,attacker,"focus")
			c:cue(victim,'SHARINGAN FOCUS • READ • COUNTER')
		end
		c:cue(attacker,'PARRIED • EXPOSED')
		return 'Parried',0
	end
	local blockCost=Tune.BlockHitCost*(1+.2*points)
	if victim.stamina>=blockCost then
		victim.stamina-=blockCost
		return 'Blocked',amount*Tune.BlockDamageMultiplier
	end
	victim.guardHeld=false;c:setState(victim,'Stunned',.65);c:cue(victim,'GUARD BREAK')
	return 'GuardBreak',amount
end
-- Chakra points Neji has closed on this fighter (0 once they reopen).
function Defense.closedPoints(a,now)
	return if (a.tenketsuUntil or 0)>now then (a.tenketsu or 0) else 0
end
-- A read: the reader slips a step to the outside of the blow (an afterimage
-- stays where he stood and the swing bites it), turns square to the attacker,
-- and the client shows the eye, the afterimage and the bitten swing ("read").
function Defense.slip(c,reader,attacker,phase)
	local Motor=require(script.Parent.Motor)
	local from=reader.root.Position
	local line=from-attacker.root.Position;line=Vector3.new(line.X,0,line.Z)
	line=if line.Magnitude>.1 then line.Unit else Vector3.new(reader.root.CFrame.LookVector.X,0,reader.root.CFrame.LookVector.Z).Unit
	local side=Vector3.new(-line.Z,0,line.X)
	local stick=Vector3.new(reader.move.X,0,reader.move.Z)
	local sign=if stick.Magnitude>.4 then (if stick:Dot(side)>=0 then 1 else -1) else (reader.slipSide or 1)
	reader.slipSide=-sign
	if Motor.travel(reader,c,side*sign,2.2)<1 then Motor.travel(reader,c,-side*sign,2.2) end
	local face=attacker.root.Position-reader.root.Position;face=Vector3.new(face.X,0,face.Z)
	if face.Magnitude>.1 then reader.root.CFrame=CFrame.lookAt(reader.root.Position,reader.root.Position+face) end
	c:pushImpact(from,"read",false,{owner=reader.id,fighter=reader.fighterId,victim=attacker.id,to=reader.root.Position,phase=phase})
	require(script.Parent.Brawler).event(c,reader,"ReadSlip")
end
-- A strike pressed during the counter stance fires the moment it pays off.
function Defense.fireQueued(c,a)
	if not a.counterQueued or c.now-a.counterQueued>1.1 then return end
	c:schedule(c.now,function()
		if a.health>0 and (a.counterUntil or 0)>c.now and a.state=="Neutral" and not a.reaction then require(script.Parent.Brawler).counterStart(c,a) end
	end)
end
-- Sharingan Read paid off (Combat:damage, a frontal melee blow inside the
-- stance): no damage, the attacker is caught out, the reader slips aside out
-- of the stance at once and the counter palm opens (instantly when the strike
-- was already pressed during the stance). Returns false (no damage).
function Defense.read(c,attacker,victim)
	local now=c.now
	victim.readUntil=0;victim.bonusUntil=now+1.4;victim.counterUntil=now+1.0
	victim.counterReach={expires=now+1.0,max=4,variant="ReadCounter"}
	victim.chakra=math.min(victim.def.Chakra or 100,victim.chakra+10)
	attacker.pending=nil;c:setState(attacker,"Stunned",.5)
	victim.pending=nil;c:setState(victim,"Neutral",0)
	Defense.slip(c,victim,attacker,"read")
	c:cue(victim,"READ • SEEN COMING • PUNISH");c:cue(attacker,"READ • EXPOSED")
	require(script.Parent.Brawler).event(c,victim,"ReadSuccess")
	Defense.fireQueued(c,victim)
	return false
end
function Defense.step(c,a,dt,now)
	if a.guardHeld then
		a.stamina=math.max(0,a.stamina-12*dt)
		if a.stamina<=0 then a.guardHeld=false;c:setState(a,'Stunned',.45);c:cue(a,'GUARD EXHAUSTED') end
	else a.stamina=math.min(100,a.stamina+18*dt) end
end
return Defense
