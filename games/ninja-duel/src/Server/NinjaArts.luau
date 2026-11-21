-- The ninja's tree in a duel (21/11, DEC-045, step 2): what the fighter's
-- def.Ninja changes in the fight. def.Ninja comes from Shared/NinjaTree.def
-- through Matches.resolveKit (a player's own kit); the AI, the masters, the
-- films and ranked have none, so every hook here is inert for them.
-- Small, readable effects, each with its answer (NinjaTree.Infusion):
--   INFUSED KUNAI / BLADE  a thrown blade (Combat:projectileHit) or the end of
--                          the basic string (Light3, Brawler.hit) carries the
--                          nature, at most once every Infusion.Gap seconds:
--                          Fire burns (a raised guard stops it), Lightning
--                          holds the body a beat, Earth cracks the guard (a
--                          dodge avoids it whole), Water slows (a substitution
--                          washes it off), Wind pushes the body further.
--   WIND KUNAI             the infused throw flies further and faster (armThrow).
--   EXPLOSIVE TAG          a thrown blade carries it every Tools.TagEvery s;
--                          where it ends it blows Tools.TagDelay s later.
--   SMOKE BOMB             a substitution leaves smoke: the rival loses him
--                          (Families.shrouded) for Tools.SmokeTime s.
--   MOBILITY               Motor (WallRun, AirJump), Brawler.react (QuickRise).
-- The client reads the projectile's `ninja` (nature) and `tag`, the fighter's
-- `ninja` (Matches snapshot, NinjaArts.view), the event AirJump and the
-- impacts "infusion" {nature, how, strong, owner, target} to draw
-- Infusion.<Nature> (the ANIMATEUR's effects).
-- Timers end in "Until": Families.clearState resets them with each round.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local NinjaTree=require(Shared.NinjaTree)
local A={}
local function families() return require(script.Parent.Families) end

function A.of(a) return a and a.def and a.def.Ninja end
local function strong(n) return if n.Mastery then NinjaTree.Infusion.Strong else 1 end
local function infusion(n) return n.Infusion or NinjaTree.Infusion[n.Nature or ""] end
local function alive(c,b) return b~=nil and b.health>0 and c.match.phase=="Duel" and not c.match.finishing end

-- A blade thrown with the tool button or a drawn kunai, just created
-- (Combat:projectile): the nature rides on it, Wind flies further and
-- faster, the explosive tag rides on it when ready.
function A.armThrow(c,a,p)
	local n=A.of(a)
	if not n or not p then return p end
	if n.KunaiInfused and n.Nature then
		p.ninja=n.Nature
		local fx=infusion(n)
		if fx and fx.KunaiRange then
			local k=strong(n)
			p.speed*=1+((fx.KunaiSpeed or 1)-1)*k
			p.range*=1+(fx.KunaiRange-1)*k;p.remaining=p.range
		end
	end
	if n.ExplosiveTag and c.now>=(a.tagUntil or 0) then
		a.tagUntil=c.now+NinjaTree.Tools.TagEvery
		p.tag=true
		c:cue(a,"EXPLOSIVE TAG",.5)
	end
	return p
end

-- Fire: chip damage in ticks; a raised guard puts it out.
function A.burn(c,a,b,total,time)
	local every=.5
	local ticks=math.max(1,math.floor(time/every+.5))
	b.ninjaBurnSerial=(b.ninjaBurnSerial or 0)+1
	local serial=b.ninjaBurnSerial
	b.burnUntil=math.max(b.burnUntil or 0,c.now+.55)
	for i=1,ticks do
		c:schedule(c.now+i*every,function()
			if b.ninjaBurnSerial~=serial or not alive(c,b) or a.health<=0 then return end
			if b.guardHeld then
				b.ninjaBurnSerial+=1
				c:cue(b,"GUARD • FLAMES OUT",.5)
				return
			end
			c.damageTag="burn"
			if c:chip(a,b,total/ticks) then b.burnUntil=c.now+.55 end
			c.damageTag=nil
		end)
	end
	c:cue(b,"BURNING",.6)
	return true
end
-- Lightning: the body is held `stun` seconds longer. `base`: the reaction the
-- strike is about to give (Brawler.react takes the floor), nil for a thrown
-- blade whose stun is already running.
function A.shock(c,b,stun,base)
	if base then
		b.stunFloorUntil=math.max(b.stunFloorUntil or 0,c.now+base+stun)
	elseif b.reaction then
		b.reactionUntil=math.max(b.reactionUntil or c.now,c.now)+stun
	elseif b.state=="Stunned" then
		b.untilTime=math.max(b.untilTime,c.now)+stun
	else
		b.pending=nil;b.guardHeld=false
		c:setState(b,"Stunned",stun)
	end
	b.shockUntil=math.max(b.shockUntil or 0,c.now+stun+(base or 0))
	c:cue(b,"PARALYSED",.5)
	return true
end
-- Earth, on a guard: the guard's stamina takes `amount` more; spent, it breaks.
function A.crack(c,b,amount)
	b.stamina=math.max(0,(b.stamina or 0)-amount)
	if b.stamina<=0 then
		b.guardHeld=false;b.pending=nil
		c:setState(b,"Stunned",.65)
		c:cue(b,"GUARD BREAK",.7)
	else
		c:cue(b,"GUARD CRACKED",.5)
	end
	return true
end
-- Water: slowed; the substitution washes it off (A.substitute).
function A.soak(c,b,slow,time)
	local until_=c.now+time
	local scale=1-slow
	if (b.slowUntil or 0)>c.now and (b.slowScale or 1)<scale then return false end
	b.slowUntil=until_;b.slowScale=scale;b.waterSlowUntil=until_
	c:cue(b,"SLOWED",.5)
	return true
end

-- An infused hit reached b. how: "kunai" (a thrown blade carrying p.ninja) or
-- "blade" (the end of the basic string). landed: it hit or met a guard;
-- guarded: on the guard. base: the stun of the reaction the strike gives
-- (blade only). Returns the nature whose effect went off, or nil.
function A.hit(c,a,b,how,landed,guarded,base)
	local n=A.of(a)
	if not n or not n.Nature or not landed or not alive(c,b) then return nil end
	if how=="kunai" and not n.KunaiInfused then return nil end
	if how=="blade" and not n.BladeInfused then return nil end
	local fx=infusion(n)
	if not fx or c.now<(a.infusionUntil or 0) then return nil end
	local k=strong(n)
	local nature=n.Nature
	local done=false
	if nature=="Fire" then done=not guarded and A.burn(c,a,b,fx.Burn*k,fx.BurnTime)
	elseif nature=="Lightning" then done=not guarded and A.shock(c,b,fx.Stun*k,if how=="blade" then (base or 0) else nil)
	elseif nature=="Earth" then done=guarded and A.crack(c,b,fx.GuardDamage*k)
	elseif nature=="Water" then done=not guarded and A.soak(c,b,fx.Slow*k,fx.SlowTime)
	elseif nature=="Wind" then done=how=="blade" and not guarded
	end
	if not done then return nil end
	a.infusionUntil=c.now+NinjaTree.Infusion.Gap
	-- No `victim` field: the client's hit stop and flash belong to the blow itself.
	c:pushImpact(b.root.Position,"infusion",false,{owner=a.id,target=b.id,nature=nature,how=how,strong=n.Mastery==true})
	c:cue(a,string.upper(nature).." "..(if how=="blade" then "BLADE" else "KUNAI"),.45)
	return nature
end
-- Wind on the blade: the struck body flies further (the strike's impulse).
function A.gust(a,impulse)
	local n=A.of(a)
	local fx=n and infusion(n)
	if not fx or not fx.KunaiRange then return impulse end
	local k=1+(fx.KunaiRange-1)*strong(n)
	return Vector3.new(impulse.X*k,impulse.Y,impulse.Z*k)
end

-- A tagged blade ended (on a body, a surface or at the end of its flight):
-- the tag lies there and blows TagDelay seconds later (Families charge: posed,
-- then the blast, knock and lift).
function A.tagEnd(c,p,position)
	if not p.tag or p.tagDone or c.match.phase~="Duel" then return end
	p.tagDone=true
	local T=NinjaTree.Tools
	local F=families()
	local h=F.plant(c,p.a,position,{Trigger=1.2,Radius=T.TagRadius,Damage=T.TagDamage,Knock=T.TagKnock,Lift=T.TagLift,
		Arm=T.TagDelay,Life=T.TagDelay+.3,Look="tag",Blast="tag"},"tag")
	c:schedule(c.now+T.TagDelay,function() F.detonate(c,h) end)
	local b=p.a.target
	if b and b.health>0 then c:cue(b,"EXPLOSIVE TAG • STEP OUT",T.TagDelay) end
end

-- A substitution came out (Combat:substitute): the water's slow washes off;
-- the smoke bomb hides him from the rival.
function A.substitute(c,a,rival,departure)
	if (a.waterSlowUntil or 0)>c.now and a.slowUntil==a.waterSlowUntil then
		a.slowUntil=0;a.waterSlowUntil=0
	end
	local n=A.of(a)
	if not n or not n.SmokeBomb then return false end
	local T=NinjaTree.Tools
	a.smokeUntil=c.now+T.SmokeTime
	c:pushImpact(departure,"zone",false,{owner=a.id,kind="mist",radius=T.SmokeRadius,time=T.SmokeTime,smoke=true})
	if rival and rival.health>0 then
		-- No chase through the smoke: the rival lost him.
		rival.pursuitUntil=c.now
		c:cue(rival,"SMOKE • LOST HIM",T.SmokeTime)
	end
	return true
end
-- Families.shrouded: the rival of a body in its own smoke has lost it.
function A.hidden(c,b)
	return b~=nil and (b.smokeUntil or 0)>c.now
end

-- Quick Rise: the time spent down after a knockdown.
function A.downTime(a,duration)
	local n=A.of(a)
	if n and n.QuickRise then return duration*NinjaTree.Mobility.QuickRise end
	return duration
end

-- What the client draws (Matches snapshot): nil without a ninja tree.
function A.view(c,a)
	local n=A.of(a)
	if not n then return nil end
	return {nature=n.Nature,kunai=n.KunaiInfused==true,blade=n.BladeInfused==true,strong=n.Mastery==true,
		tag=if n.ExplosiveTag then c.now>=(a.tagUntil or 0) else nil,smoke=if (a.smokeUntil or 0)>c.now then true else nil,
		airJump=if n.AirJump then not a.airJumpUsed else nil,rise=n.QuickRise==true,
		ready=c.now>=(a.infusionUntil or 0)}
end

return A
