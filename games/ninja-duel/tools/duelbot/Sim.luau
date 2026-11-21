-- The simulated player in the headless harness (OUTILLEUR, 21/11; DEC-047).
-- tools/duelbot/PlayerSim decides; this plays its presses as the server takes
-- a player's (Server/Matches:act: the stick, the held guard, the held jutsu
-- key) on the real Combat, AI and Coach, and records what a player meets:
-- the time, who wins, each prompt of the coach (when it came, if he did it).
--
--   Sim.first(H,mods,kit,seed,profile)        the first combat (Coach, AI "first")
--   Sim.round(H,mods,kit,rival,level,seed,profile)  one round of a duel
-- mods: {PlayerSim=,AI=,Coach=,FirstMinute=,Config=}; H: tests/Harness.
local Sim={}

-- What the screen shows of a body, as the duel's snapshot (Matches.view).
local function body(c,a)
	local techniques={}
	for slot,spec in a.def.Techniques or {} do
		techniques[slot]={id=spec.Id,name=spec.Name,cost=spec.Cost,damage=spec.Damage,range=spec.Range,locked=spec.Locked==true,
			remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-c.now)}
	end
	return {pos=a.root.Position,health=a.health,maxHealth=a.def.Health,chakra=a.chakra,maxChakra=a.def.Chakra,state=a.state,
		reaction=a.reaction,attackName=a.attackName,techniques=techniques}
end
function Sim.view(c,a,b,prompt)
	return {now=c.now,me=body(c,a),him=body(c,b),prompt=prompt}
end

-- One press, as Matches:act takes it from a client.
function Sim.press(c,a,press)
	local action=press.action
	if action=="Guard" then a.guardWanted=true elseif action=="GuardOff" then a.guardWanted=false end
	local slot=string.match(action,"^Technique(%d)$")
	if slot then a.techHold={slot=tonumber(slot),down=true} end
	local ok,reason=c:request(a,action,press.aim)
	-- the key comes back up a moment later (a held jutsu goes)
	if slot then a.techHold={slot=tonumber(slot),down=false} end
	return ok~=false,reason
end

local function drive(c,a,sim,view,dt,stats)
	local out=sim:tick(view,dt)
	a.move=out.move;a.sprinting=out.sprint;a.lastMove=c.now
	for _,press in out.presses do
		local ok,reason=Sim.press(c,a,press)
		stats.presses+=1
		if not ok then stats.refused+=1;stats.reasons[reason or "?"]=(stats.reasons[reason or "?"] or 0)+1 end
	end
end

function Sim.first(H,mods,kit,seed,profile)
	local V=H.V
	local rival=mods.FirstMinute.rival(kit)
	local c,a,b,match=H.duel(kit,rival)
	local half=mods.Config.StartDistance or 24
	c:relocate(a,V.new(0,3,half));c:relocate(b,V.new(0,3,-half))
	a.playerInput=true
	local s={human=a,bot=b,combat=c}
	mods.Coach.new(s,c.now)
	local ai=mods.AI.new(c,b,seed*7+1,"first")
	local sim=mods.PlayerSim.new(profile or "debutant",seed,V)
	local stats={kit=kit,rival=rival,seed=seed,presses=0,refused=0,reasons={},prompts={}}
	local current,started=nil,c.now
	local t=0
	while match.phase=="Duel" and t<150 do
		ai:update(c.now)
		local snap=mods.Coach.snapshot(s)
		drive(c,a,sim,Sim.view(c,a,b,snap),.02,stats)
		mods.Coach.update(s,c.now,.02)
		local k=s.coach
		if k and k.current~=current then
			current=k.current
			if current then table.insert(stats.prompts,{id=current.id,shown=c.now-started}) end
		end
		if k and k.current and k.doneAt then
			local last=stats.prompts[#stats.prompts]
			if last and not last.done then last.done=k.doneAt-started end
		end
		H.step(c,.02);t+=.02
	end
	stats.t=t;stats.winner=match.winner;stats.won=match.winner=="A"
	stats.health=a.health/a.def.Health;stats.hisHealth=b.health/b.def.Health
	local done,seen,ids={}, {}, {}
	for _,p in stats.prompts do
		if not seen[p.id] then seen[p.id]=true;table.insert(ids,p.id) end
		if p.done then done[p.id]=true end
	end
	stats.seen=ids
	local n=0 for _ in done do n+=1 end
	stats.doneCount=n
	return stats
end

function Sim.round(H,mods,kit,rival,level,seed,profile)
	local V=H.V
	local c,a,b,match=H.duel(kit,rival)
	local half=mods.Config.StartDistance or 24
	c:relocate(a,V.new(0,3,half));c:relocate(b,V.new(0,3,-half))
	a.playerInput=true
	local ai=mods.AI.new(c,b,seed*13+5,level)
	local sim=mods.PlayerSim.new(profile or "joueur",seed,V)
	local stats={kit=kit,rival=rival,level=level,seed=seed,presses=0,refused=0,reasons={}}
	local t=0
	while match.phase=="Duel" and t<150 do
		ai:update(c.now)
		drive(c,a,sim,Sim.view(c,a,b,nil),.02,stats)
		H.step(c,.02);t+=.02
	end
	stats.t=t;stats.winner=match.winner;stats.won=match.winner=="A";stats.timeout=match.phase=="Duel"
	stats.health=a.health/a.def.Health;stats.hisHealth=b.health/b.def.Health
	return stats
end

return Sim
