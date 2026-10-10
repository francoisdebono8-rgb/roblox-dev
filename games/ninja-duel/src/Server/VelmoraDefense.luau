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
function Defense.resolve(c,attacker,victim,amount,frontal)
	-- Itachi's Sharingan sees the strike coming: wider windows, and every
	-- clean read opens a counter.
	local eye=victim.def and victim.def.Sharingan
	if victim.invulnerableUntil>c.now then
		local clean=c.now-victim.dodgeStartedAt<=(if eye then eye.PerfectDodge else Tune.BloodstepWindow) and victim.bloodstepGrantedFor~=victim.dodgeStartedAt
		if clean then
			victim.bloodstepGrantedFor=victim.dodgeStartedAt;victim.bonusUntil=c.now+.8
			if eye then victim.counterUntil=c.now+eye.Counter;c:cue(victim,'SHARINGAN • PERFECT DODGE • COUNTER')
			else c:cue(victim,'PERFECT DODGE • BLOODSTEP') end
		end
		return 'Evaded',0
	end
	if not frontal or not victim.guardHeld then return 'Hit',amount end
	local since=c.now-victim.guardPressedAt
	if since<=(if eye then eye.ParryWindow else Tune.ParryWindow) and c.now>=victim.parryReadyAt and victim.stamina>=Tune.ParryCost then
		victim.stamina-=Tune.ParryCost;victim.parryReadyAt=c.now+Tune.ParryCooldown;victim.guardPressedAt=-math.huge
		attacker.pending=nil;attacker.guardHeld=false;c:setState(attacker,'Stunned',Tune.ParryStun)
		if eye then victim.counterUntil=c.now+eye.Counter;c:cue(victim,'SHARINGAN • PARRY • COUNTER')
		else c:cue(victim,'PARRY • PUNISH') end
		c:cue(attacker,'PARRIED • EXPOSED')
		return 'Parried',0
	end
	if victim.stamina>=Tune.BlockHitCost then
		victim.stamina-=Tune.BlockHitCost
		return 'Blocked',amount*Tune.BlockDamageMultiplier
	end
	victim.guardHeld=false;c:setState(victim,'Stunned',.65);c:cue(victim,'GUARD BREAK')
	return 'GuardBreak',amount
end
function Defense.step(c,a,dt,now)
	if a.guardHeld then
		a.stamina=math.max(0,a.stamina-12*dt)
		if a.stamina<=0 then a.guardHeld=false;c:setState(a,'Stunned',.45);c:cue(a,'GUARD EXHAUSTED') end
	else a.stamina=math.min(100,a.stamina+18*dt) end
end
return Defense
