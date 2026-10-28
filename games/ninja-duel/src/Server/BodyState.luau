-- Ninja Embodiment (DEC-027, SYS-001 sustained chakra): a technique that is a
-- state of the body, not a packet that plays itself.
--
--   prepare (the technique's channel) -> the state holds on the body (chakra
--   drains while it is kept) -> the body moves freely with it -> the next
--   strike releases it, shaped by the situation it is pressed in -> the world
--   or the opponent takes the consequence.
--
-- A technique opts in with data: `State = {...}` on its spec.
--   Time     seconds the state can be held
--   Drain    chakra per second while held (it ends when the chakra runs out)
--   Strike   the strike it releases into on the ground
--   Air      the strike out of the air (default: the shared drop strike)
--   Wall     the strike off a wall run (default: the shared wall dive)
--   Damage   the released strike's damage
--   World    {contact, element}: how the world takes it (Server/WorldReaction)
--   Style    the contact style pushed to the client on release
--   Name     the cue
-- The state ends on release, on a blow taken, on a guard, when its time or
-- the chakra runs out (a fizzle). Nothing here names a fighter.
local BodyState={}

local function brawler() return require(script.Parent.Brawler) end

function BodyState.active(a,now)
	local s=a.bodyState
	return s~=nil and now<s.untilTime and s or nil
end

function BodyState.enter(c,a,spec,held)
	local st=held or spec.State
	a.bodyState={id=spec.Id,spec=spec,state=st,at=c.now,untilTime=c.now+(st.Time or 2)}
	c:cue(a,string.upper(st.Name or spec.Name or spec.Id).." • ATTACK TO RELEASE",.9)
	brawler().event(c,a,"State:"..spec.Id)
	c:pushImpact(a.root.Position,st.Style or "chidori",false,{owner=a.id,state=spec.Id,phase="form"})
end

function BodyState.finish(c,a,why)
	local s=a.bodyState
	if not s then return end
	a.bodyState=nil
	if why~="release" then
		brawler().event(c,a,"StateEnd:"..why)
		if why=="fizzle" then c:cue(a,string.upper(s.state.Name or s.id).." • FADED",.6) end
	end
end

-- Per frame: the drain, the time limit, and what breaks the state.
function BodyState.step(c,a,dt)
	local s=a.bodyState
	if not s then return end
	if a.health<=0 or c.match.phase~="Duel" then a.bodyState=nil;return end
	if a.reaction or a.state=="Stunned" then BodyState.finish(c,a,"broken");return end
	if a.state=="Guarding" then BodyState.finish(c,a,"guard");return end
	a.chakra=math.max(0,a.chakra-(s.state.Drain or 0)*dt)
	if c.now>=s.untilTime or a.chakra<=0 then BodyState.finish(c,a,"fizzle") end
end

-- The strike press while the state holds: the state's strike, shaped by the
-- situation (off a wall: a dive; out of the air: a drop; running: it carries
-- the run). Returns the request's result, or nil when the state does not
-- answer this press.
function BodyState.release(c,a,action)
	local s=BodyState.active(a,c.now)
	if not s or (action~="Attack" and action~="Heavy") then return nil end
	if a.state~="Neutral" and a.state~="Recovery" and a.state~="Dodging" and a.state~="TechniqueRecovery" and a.state~="TechniqueActive" then return nil end
	local Brawler=brawler()
	local st=s.state
	local Motor=require(script.Parent.Motor)
	local move,shape=st.Strike or "Light3","ground"
	if a.wall then
		Motor.detach(a,c.now,false)
		move,shape=st.Wall or "WallDive","wall"
	elseif a.airborne then
		move,shape=st.Air or "DropStrike","air"
	end
	local runSpeed=a.locomotion and a.locomotion.Magnitude or 0
	a.state="Neutral";a.untilTime=c.now;a.evade=nil
	Brawler.breakString(a,a.airborne==true)
	BodyState.finish(c,a,"release")
	local ok=Brawler.start(c,a,move)
	local p=a.pending
	if ok==false or not p then return ok end
	p.spec.damage=st.Damage or p.spec.damage
	p.spec.world=st.World
	p.state=s.id
	-- A held Rasengan releases as the Rasengan (its own reaction, impulse and
	-- look); a held Chidori as the thrust it names.
	if st.Reaction then p.spec.reaction=st.Reaction end
	if st.Impulse then p.spec.impulse=if shape=="air" then Vector3.new(0,-70,16) else st.Impulse end
	if st.Stun then p.spec.stun=st.Stun end
	if st.Rasengan then
		p.rasengan=true
		if shape=="ground" then p.spec.travel=math.max(p.spec.travel,10);a.travelRemaining=math.max(a.travelRemaining or 0,p.spec.travel) end
	end
	a.attackVariant=(shape=="air" and st.AirVariant) or st.Variant or s.id
	a.lastAttack=c.now
	if shape=="ground" and runSpeed>8 then
		-- Released out of a run: the run is in the thrust.
		local need=runSpeed*(p.spec.travelTime or .3)*.9
		if need>p.spec.travel then p.spec.travel=need;a.travelRemaining=need end
	end
	Brawler.event(c,a,"Release:"..s.id);Brawler.event(c,a,"Release:"..shape)
	if st.Event then Brawler.event(c,a,st.Event) end
	c:pushImpact(a.root.Position,st.Style or "chidori",true,{owner=a.id,state=s.id,phase="release",shape=shape})
	c:cue(a,string.upper(st.Name or s.id),.6)
	-- The risk, said to both: a release that touched nothing (not even a
	-- guard) leaves the body open for its whole recovery.
	local serial=a.attackSerial
	c:schedule(c.now+p.spec.startup+p.spec.active+.02,function()
		if a.health<=0 or a.attackSerial~=serial or a.hitConfirmed or a.state~="Recovery" then return end
		c:cue(a,string.upper(st.Name or s.id).." • MISSED • OPEN",.8)
		if a.target and a.target.health>0 then c:cue(a.target,string.upper(st.Name or s.id).." MISSED • PUNISH",.8) end
		Brawler.event(c,a,"StateMissed:"..s.id)
	end)
	return ok
end

function BodyState.snapshot(a,now)
	local s=a.bodyState
	if not s or now>=s.untilTime then return nil end
	return {id=s.id,remaining=s.untilTime-now}
end

return BodyState
