-- A player simulated at the keys (OUTILLEUR, 21/11; DEC-047, step 3,
-- OUTILLEUR 2 and 3). What a person does with a duel in front of him: he sees
-- late, presses late and not always the right key, walks at the opponent a
-- little sideways, mashes the strike, reads the coach's prompt after a while
-- and does what it says, or not. Not an AI: it never reads the opponent's
-- plan, only what is on the screen (his body, his health, the prompt).
--
-- The same code plays in the headless harness (tests/DuelBot.spec.luau,
-- tools/duelbot/rounds.luau) and in Studio (tools/duelbot/studio_bot.luau,
-- through the game's own remote, as a client). Pure: the vector type comes
-- from the caller (Vector3 in Studio, the harness's in lune), and the dice are
-- its own, so a seed plays the same game in both.
--
--   local sim=PlayerSim.new("debutant",seed,Vector3)
--   each frame: local out=sim:tick(view,dt)
--     out.move    the stick (flat, length 0 or 1)   out.sprint  boolean
--     out.presses {{action=, aim=}}: what he pressed this frame
--   view (Studio: the duel snapshot; harness: tools/duelbot/Sim.luau):
--     now, me={pos,health,maxHealth,chakra,maxChakra,state,reaction,attackName,
--     techniques={{id,name,cost,remaining}}}, him={same}, prompt={id,key,done}
local PlayerSim={}
PlayerSim.__index=PlayerSim

-- Who plays. Times in seconds, chances per event unless said "per second".
PlayerSim.Profiles={
	-- A newcomer on his first fight: sees and presses late, a key in ten is the
	-- wrong one, follows most of the prompts once he has read them.
	debutant={
		Reaction={.45,1.0},     -- from a moment to his press
		Read={.9,1.8},          -- from a prompt on screen to acting on it
		Follow=.85,             -- he does what a prompt says
		PromptFor=5,            -- he tries it this long, then forgets
		Cadence={.28,.5},       -- between two strikes when he mashes
		Burst={3,6},            -- strikes before he stops a moment
		Pause={.5,1.2},
		Reach=5.2,              -- he strikes from this close
		Stop={2.8,4.8},         -- he stops walking this far from him
		Wander=28,              -- degrees his walk drifts off the line
		WrongKey=.1,            -- a strike that comes out as the heavy
		GuardHold={.8,1.5},
		GuardSkill=.25,         -- once the guard prompt was seen: he guards a wind-up
		EscapeSkill=.3,         -- once the escape prompt was seen: he escapes a string
		JutsuEvery={9,15},      -- a random jutsu when he has the chakra
		JumpPerSecond=.03,
		DodgePerSecond=.02,
		ToolAtRange=false,      -- he throws only when told
		SprintFar=.4,
	},
	-- A player who knows the keys: the duel as it is played after a few
	-- (the round's real length, OUTILLEUR 3).
	joueur={
		Reaction={.22,.38},
		Read={.5,.9},
		Follow=1,
		PromptFor=4,
		Cadence={.17,.24},
		Burst={4,5},
		Pause={.25,.5},
		Reach=5.6,
		Stop={3.2,4.2},
		Wander=10,
		WrongKey=.02,
		GuardHold={.45,.8},
		GuardSkill=.45,
		EscapeSkill=.45,
		JutsuEvery={2.5,5},
		JutsuBest=true,         -- the readiest damaging jutsu in range
		JumpPerSecond=.04,
		DodgePerSecond=.03,
		ToolAtRange=true,
		SprintFar=.9,
		HeavyEnd=.3,            -- a string ends on the heavy
		GrabGuard=.5,           -- he grabs a guard he is next to
		DodgeJutsu=.3,          -- he dodges a jutsu he sees coming
	},
}

local function lcg(seed)
	local state=math.floor(math.abs(seed or 1))*2654435761%4294967296
	return function()
		state=(1103515245*state+12345)%2147483648
		return state/2147483648
	end
end

function PlayerSim.new(profile,seed,V)
	local p=PlayerSim.Profiles[profile] or error("PlayerSim: no profile "..tostring(profile))
	local self=setmetatable({profile=profile,p=p,V=V,roll=lcg(seed),queue={},goal=nil,seen={},learned={},
		nextStrike=0,burstLeft=0,pauseUntil=0,stop=nil,stopUntil=0,wander=0,wanderUntil=0,guardUntil=0,
		nextJutsu=nil,lastHimState=nil,lastReaction=nil,runs=false,onScreen=nil,toolAt=-10,grabAt=-10,dodgeAt=-10,sigAt=-10,log={}},PlayerSim)
	return self
end

function PlayerSim:range(pair) return pair[1]+(pair[2]-pair[1])*self.roll() end
function PlayerSim:chance(p) return self.roll()<p end

-- A press decided now goes out after his reaction (or `after`).
function PlayerSim:later(now,action,aim,after,extra)
	table.insert(self.queue,{at=now+(after or self:range(self.p.Reaction)),action=action,aim=aim,extra=extra})
end

local function flat(V,v) return V.new(v.X,0,v.Z) end

-- The jutsu he has that can go now: {slot,spec}, the first one (or the best).
local function readyJutsu(view,best)
	local me=view.me
	local pick,spec,score=nil,nil,-1
	for slot,t in me.techniques or {} do
		if not t.locked and (t.remaining or 0)<=0 and (t.cost or 0)<=(me.chakra or 0) then
			if not best then return slot,t end
			local s=(t.damage or 1)+(if t.cost then t.cost/100 else 0)
			if s>score then pick,spec,score=slot,t,s end
		end
	end
	return pick,spec
end

function PlayerSim:tick(view,dt)
	local V,p,now=self.V,self.p,view.now
	local me,him=view.me,view.him
	local out={move=V.new(0,0,0),sprint=false,presses={}}
	if not me or not him or not me.pos or not him.pos then return out end
	local d=flat(V,him.pos-me.pos)
	local dist=d.Magnitude
	local toward=if dist>.01 then d.Unit else V.new(0,0,1)

	-- The prompt: read after a while, then done (or not) for a few seconds.
	-- A prompt that comes on screen (again: the coach shows it back when its
	-- moment returns) is read, then done or not.
	local prompt=view.prompt
	local shown=prompt and prompt.id and not prompt.done and prompt.id or nil
	if shown and shown~=self.onScreen and not (self.goal and self.goal.id==shown) then
		self.seen[shown]=(self.seen[shown] or 0)+1
		if self:chance(p.Follow) then
			-- read faster the second time
			local from=now+self:range(p.Read)*(if self.seen[shown]>1 then .6 else 1)
			self.goal={id=shown,key=prompt.key,from=from,untilT=from+p.PromptFor,tries=0}
		end
	end
	self.onScreen=shown
	local goal=self.goal
	if goal and now>goal.untilT then self.learned[goal.id]=true;self.goal=nil;goal=nil end
	if goal and prompt and prompt.id==goal.id and prompt.done then self.learned[goal.id]=true;self.goal=nil;goal=nil end
	local acting=goal and now>=goal.from and goal or nil

	-- Walking: at him, a little off the line, stops at his own distance.
	if now>=self.stopUntil then
		self.stop=self:range(p.Stop);self.stopUntil=now+self:range({2.5,4})
		self.runs=self:chance(p.SprintFar)
	end
	if now>=self.wanderUntil then self.wander=(self.roll()*2-1)*p.Wander;self.wanderUntil=now+self:range({.5,1}) end
	local keepAway=acting and acting.id=="tool"
	local guarding=now<self.guardUntil
	if not guarding and not keepAway and dist>self.stop then
		local a=math.rad(self.wander)
		local c,s=math.cos(a),math.sin(a)
		out.move=V.new(toward.X*c-toward.Z*s,0,toward.X*s+toward.Z*c).Unit
		out.sprint=dist>18 and self.runs==true
	end

	-- What the prompt asks.
	if acting then
		local id=acting.id
		if id=="guard" and not guarding and acting.tries<2 then
			acting.tries+=1
			table.insert(self.queue,{at=now,action="Guard"})
			local hold=self:range(p.GuardHold)
			self.guardUntil=now+hold
			table.insert(self.queue,{at=now+hold,action="GuardOff"})
		elseif id=="escape" and me.reaction=="HitStun" and now-self.dodgeAt>1.2 then
			self.dodgeAt=now;self:later(now,"Dodge",nil,self:range({.25,.6}))
		elseif id=="grab" and dist<5.5 and now-self.grabAt>1 then
			self.grabAt=now;self:later(now,"Grab",nil,.05)
		elseif id=="signature" and now-self.sigAt>1.2 and acting.tries<4 then
			-- the key the prompt names, pressed again while it stays on screen;
			-- he stops striking a moment to press it
			acting.tries+=1;self.sigAt=now
			local slot=tonumber(string.match(tostring(acting.key or ""),"%d"))
			if not slot then slot=readyJutsu(view,false) end
			if slot then
				self:later(now,"Technique"..slot,him.pos,.1)
				self.pauseUntil=math.max(self.pauseUntil,now+.6)
			end
		elseif id=="tool" and now-self.toolAt>1.5 then
			self.toolAt=now
			local miss=V.new((self.roll()*2-1)*2,0,(self.roll()*2-1)*2)
			self:later(now,"Tool",him.pos+miss,.1)
		end
	end

	-- Reading him: a wind-up (guard), a string (escape), once he has learned.
	if him.state=="Startup" and self.lastHimState~="Startup" then
		if (self.learned.guard or self.profile=="joueur") and dist<8 and not guarding and self:chance(p.GuardSkill) then
			local at=now+self:range(p.Reaction)
			local hold=self:range(p.GuardHold)
			table.insert(self.queue,{at=at,action="Guard"})
			table.insert(self.queue,{at=at+hold,action="GuardOff"})
			self.guardUntil=at+hold
		end
	end
	self.lastHimState=him.state
	if me.reaction=="HitStun" and self.lastReaction~="HitStun" then
		if (self.learned.escape or self.profile=="joueur") and self:chance(p.EscapeSkill) and now-self.dodgeAt>1 then
			self.dodgeAt=now;self:later(now,"Dodge")
		end
	end
	self.lastReaction=me.reaction
	if p.DodgeJutsu and (him.state=="TechniqueChannel") and now-self.dodgeAt>2 and self:chance(p.DodgeJutsu*dt*3) then
		self.dodgeAt=now;self:later(now,"Dodge")
	end
	if p.GrabGuard and him.state=="Guarding" and dist<5 and now-self.grabAt>1.2 and self:chance(p.GrabGuard*dt*4) then
		self.grabAt=now;self:later(now,"Grab")
	end

	-- The strike: mashed when he is close, in bursts.
	if not guarding and dist<=p.Reach and now>=self.nextStrike and now>=self.pauseUntil then
		if self.burstLeft<=0 then self.burstLeft=math.floor(self:range(p.Burst)+.5) end
		local action="Attack"
		if self:chance(p.WrongKey) then action="Heavy" end
		self.burstLeft-=1
		if self.burstLeft<=0 then
			if p.HeavyEnd and self:chance(p.HeavyEnd) then action="Heavy" end
			self.pauseUntil=now+self:range(p.Pause)
		end
		self.nextStrike=now+self:range(p.Cadence)
		table.insert(self.queue,{at=now+.02,action=action})
	end

	-- A jutsu now and then (the newcomer: any; the player: the best in range).
	self.nextJutsu=self.nextJutsu or now+self:range(p.JutsuEvery)
	if now>=self.nextJutsu and not guarding then
		self.nextJutsu=now+self:range(p.JutsuEvery)
		local slot,t=readyJutsu(view,p.JutsuBest)
		if slot and (not p.JutsuBest or dist<=math.max((t and t.range) or 14,6)+2) then
			self:later(now,"Technique"..slot,him.pos,.05)
		end
	end
	-- The tool at range (the player), the jump and the dodge pressed for nothing.
	if p.ToolAtRange and dist>14 and now-self.toolAt>2.2 then self.toolAt=now;self:later(now,"Tool",him.pos) end
	if self:chance(p.JumpPerSecond*dt) then table.insert(self.queue,{at=now,action="Jump"});table.insert(self.queue,{at=now+.3,action="JumpOff"}) end
	if self:chance(p.DodgePerSecond*dt) and now-self.dodgeAt>1 then self.dodgeAt=now;table.insert(self.queue,{at=now,action="Dodge"}) end

	-- What goes out this frame.
	local keep={}
	for _,q in self.queue do
		if q.at<=now then table.insert(out.presses,{action=q.action,aim=q.aim,extra=q.extra})
		else table.insert(keep,q) end
	end
	self.queue=keep
	for _,press in out.presses do table.insert(self.log,{t=now,action=press.action}) end
	return out
end

return PlayerSim
