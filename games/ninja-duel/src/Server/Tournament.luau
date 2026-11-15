-- The Prodigy Tournament against the AI (roadmap 04/11, step 2): the eight
-- prodigies of the beta in a bracket of eight, each once (the Chunin exam
-- finals). The player picks his fighter; the seven others take the seven other
-- places. Quarter-finals, semi-finals, final, each match first to two.
--  * His matches are ordinary local duels (Matches:start), the AI a little
--    stronger each round (Server/BuildPresets tiers, where the fighter has one).
--  * The AI-vs-AI matches are played for real in the arena with an autopilot
--    on the first fighter (as the Studio dev tools do), watched from a
--    spectator lens (snapshot `spectate`); SKIP decides one at once from the
--    matchup's win rate measured on the engine (Server/CupOdds: thousands of
--    headless AI-vs-AI fights), so a skipped match is not a coin toss.
--  * Between matches, the bracket (phase "Bracket"). He loses: the rest of
--    the bracket is decided the same way, to show who won. He wins the final:
--    phase "Champion".
-- Client: Client/CupScreen (bracket, spectator banner, champion card).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local BetaRoster=require(Shared.BetaRoster)
local Tournament={};Tournament.__index=Tournament

-- The story's pairings in the quarter-finals (seats 1-2, 3-4, 5-6, 7-8):
-- Naruto–Neji and Sasuke–Gaara (the exam's finals), Lee–Minato (speed
-- against speed), Itachi–Kakashi (Sharingan against Sharingan).
Tournament.Seats={"Legion","GentleFist","Lion","Sand","Leaf","Flashstep","Mirage","Copycat"}
Tournament.RoundNames={"QUARTER-FINAL","SEMI-FINAL","FINAL"}
-- The AI in the player's matches, by round (a tier the fighter's skill tree
-- offers; none: his base kit).
Tournament.Tiers={"Medium","Hard","Boss"}
-- A word before the match (original lines, by fighter, then for the story's
-- own pairs).
Tournament.Lines={
	Legion="I'm not losing to anybody here. Believe it!",
	GentleFist="The outcome was decided before you stepped in.",
	Lion="Get out of my way. I have someone to catch up with.",
	Sand="The sand already knows where you will fall.",
	Leaf="Hard work beats genius. Let me prove it!",
	Flashstep="Blink and it is over. Try not to blink.",
	Mirage="You see the blow. You do not see the one behind it.",
	Copycat="Show me something new. I'll take it with me.",
}
Tournament.Rivals={
	["Legion|GentleFist"]={"Fate? I'll knock that word right out of you!","Then come and fail, like you were always going to."},
	["Lion|Sand"]={"Show me what that sand of yours can really do.","It is already around your feet."},
	["Leaf|Flashstep"]={"My youth is faster than your flash!","Fast is a start. Let's see if it lasts."},
	["Mirage|Copycat"]={"You copy what you see. So see this.","I've seen enough not to blink."},
}

function Tournament.new(matches,odds)
	local self=setmetatable({matches=matches,odds=odds,rng=Random.new()},Tournament)
	if not self.odds then
		local ok,table_=pcall(function() return require(script.Parent.CupOdds) end)
		self.odds=if ok then table_ else {}
	end
	return self
end
-- Match m (1..7): the two seats it opposes (nil while a feeder is undecided).
function Tournament.pair(cup,m)
	if m<=4 then return 2*m-1,2*m end
	if m==5 then return cup.winners[1],cup.winners[2] end
	if m==6 then return cup.winners[3],cup.winners[4] end
	return cup.winners[5],cup.winners[6]
end
function Tournament.roundOf(m) return if m<=4 then 1 elseif m<=6 then 2 else 3 end
-- How likely the fighter on seat a beats the one on seat b (the engine's own
-- AI-vs-AI record; even when unknown).
function Tournament:chance(x,y)
	local row=self.odds[x]
	local p=row and row[y]
	if type(p)~="number" then
		local back=self.odds[y] and self.odds[y][x]
		p=if type(back)=="number" then 1-back else .5
	end
	return math.clamp(p,.1,.9)
end
function Tournament:decide(cup,m)
	local a,b=Tournament.pair(cup,m)
	local win=if self.rng:NextNumber()<self:chance(cup.seats[a],cup.seats[b]) then a else b
	cup.winners[m]=win
	cup.skipped[m]=true
	return win
end
function Tournament:line(x,y)
	local pair=Tournament.Rivals[x.."|"..y]
	if pair then return pair[1],pair[2] end
	local back=Tournament.Rivals[y.."|"..x]
	if back then return back[2],back[1] end
	return Tournament.Lines[x],Tournament.Lines[y]
end
-- What the client draws: the seats, the winners so far, the next match.
function Tournament:view(cup)
	local m=cup.match
	local a,b=Tournament.pair(cup,m)
	local next_=nil
	if not cup.over and a and b then
		local la,lb=self:line(cup.seats[a],cup.seats[b])
		next_={match=m,round=Tournament.roundOf(m),roundName=Tournament.RoundNames[Tournament.roundOf(m)],a=a,b=b,
			mine=(a==cup.me or b==cup.me),lineA=la,lineB=lb}
	end
	return {seats=table.clone(cup.seats),me=cup.me,winners=table.clone(cup.winners),skipped=table.clone(cup.skipped),
		next=next_,over=cup.over==true,champion=cup.champion,out=cup.out,eliminatedIn=cup.eliminatedIn}
end
function Tournament:send(player,s,phase)
	s.phase=phase or "Bracket"
	self.matches:send(player,{phase=s.phase,epoch=s.epoch,cup=self:view(s.cup)})
end

-- ------------------------------------------------------------ flow
function Tournament:start(player,fighter)
	local m=self.matches
	if type(fighter)~="string" or not table.find(BetaRoster,fighter) or not Fighters[fighter] then return false end
	-- (DEC-037) the player's fighter in the cup: a learned kit.
	if not require(script.Parent.Progression).owns(player,fighter) then return false end
	local s=m:session(player)
	if s.online then return false end
	m:destroy(s)
	local seats=table.clone(Tournament.Seats)
	local cup={seats=seats,me=table.find(seats,fighter),winners={},skipped={},match=1,over=false}
	s.cup=cup
	s.epoch+=1
	self:send(player,s)
	return true
end
-- The next match: his own (a duel), or the AI's (watched).
function Tournament:fight(player)
	local m=self.matches
	local s=m:session(player)
	local cup=s.cup
	if not cup or cup.over or s.phase~="Bracket" then return end
	local a,b=Tournament.pair(cup,cup.match)
	if not a or not b then return end
	local mine=a==cup.me or b==cup.me
	local options=nil
	local first,second
	if mine then
		first=cup.seats[cup.me];second=cup.seats[if a==cup.me then b else a]
		local tier=Tournament.Tiers[Tournament.roundOf(cup.match)]
		if tier and require(script.Parent.BuildPresets).ai(second,tier) then options={bot={preset=tier}} end
	else
		first=cup.seats[a];second=cup.seats[b]
	end
	-- (DEC-036) Known before the bodies are built: a match he only watches is
	-- two prodigies, his own is fought in his avatar.
	s.spectate=if mine then nil else true
	local ok=m:start(player,first,second,false,options)
	if not ok and options then ok=m:start(player,first,second,false,nil) end
	if not ok then return end
	s.cup=cup;s.cupMatch=cup.match;s.cupResolved=false
	if not mine then
		-- The first fighter is the autopilot's; the player only watches.
		local AI=require(script.Parent.AI)
		s.autopilot=true;s.spectate=true
		s.cupPilot=AI.new(s.combat,s.human,(player.UserId%100000)+cup.match*7)
	else
		s.autopilot=nil;s.spectate=nil;s.cupPilot=nil
	end
	-- (B1) his own matches get stronger round by round (easy, normal, hard);
	-- a watched match is two bots at the same level.
	if m.aiLevel then s.ai=require(script.Parent.AI).new(s.combat,s.bot,(player.UserId%100000)+s.epoch,m.aiLevel(s)) end
	m:snapshot(player,s)
end
-- SKIP: an AI-vs-AI match decided at once (from the bracket or while watching).
function Tournament:skip(player)
	local m=self.matches
	local s=m:session(player)
	local cup=s.cup
	if not cup or cup.over then return end
	-- (Audit 04/11) the K.O. on screen is the result: no reroll over it.
	if s.finishing or s.phase=="Result" then return end
	local a,b=Tournament.pair(cup,cup.match)
	if not a or not b or a==cup.me or b==cup.me then return end
	if s.phase=="Duel" or s.phase=="Result" then m:destroy(s) end
	self:decide(cup,cup.match)
	self:advance(player,s)
end
-- A match of the cup has its result (Matches:update calls this once).
function Tournament:matchOver(player,s)
	local cup=s.cup
	if not cup or s.cupResolved or s.cupMatch~=cup.match then return end
	s.cupResolved=true
	local a,b=Tournament.pair(cup,cup.match)
	local mine=a==cup.me or b==cup.me
	local winnerSeat
	if mine then
		local other=if a==cup.me then b else a
		winnerSeat=if s.winner=="PlayerFighter" then cup.me else other
	else
		-- PlayerFighter is the first fighter of the pair (seat a).
		winnerSeat=if s.winner=="PlayerFighter" then a else b
	end
	cup.winners[cup.match]=winnerSeat
	-- (the lens stays the spectator's until the bracket comes back)
	s.cupPilot=nil
	if mine and winnerSeat~=cup.me then
		cup.out=true;cup.eliminatedIn=Tournament.RoundNames[Tournament.roundOf(cup.match)]
	end
	s.cupAdvanceReady=true
end
-- After a result or a skip: the next match, or the end.
function Tournament:advance(player,s)
	local cup=s.cup
	s.cupAdvanceReady=false
	if cup.out then
		-- Out: the rest of the bracket is decided, to show who won.
		for m=cup.match+1,7 do if not cup.winners[m] then cup.match=m;self:decide(cup,m) end end
	end
	if cup.winners[7] then
		cup.over=true
		cup.champion=cup.winners[7]
		if cup.champion==cup.me then
			-- (14/11) his face on Konoha's cliff, on every server
			pcall(function() require(script.Parent.ChampionCliff).champion(player) end)
			s.epoch+=1
			s.autopilot=nil;s.spectate=nil;s.cupPilot=nil
			self.matches:destroy(s)
			return self:send(player,s,"Champion")
		end
	else
		cup.match+=1
	end
	s.epoch+=1
	s.autopilot=nil;s.spectate=nil;s.cupPilot=nil
	self.matches:destroy(s)
	self:send(player,s,"Bracket")
end
function Tournament:leave(player)
	self.matches:selection(player)
end

-- Requests that belong to the cup; true when handled.
-- (Security review 04/11, finding 1) CupStart, CupFight, CupSkip and
-- CupLeave build or tear down a whole arena: they share the roster's 0.8 s
-- lifecycle gap (one client could otherwise rebuild it ~13 times a second).
local LIFECYCLE={CupStart=true,CupFight=true,CupSkip=true,CupLeave=true}
function Tournament:request(player,s,action,payload)
	if LIFECYCLE[action] then
		local clock=os.clock()
		if clock-(s.lastLifecycle or -10)<0.8 then return true end
		s.lastLifecycle=clock
	end
	if action=="CupStart" then
		-- (Audit 04/11) and NEW TOURNAMENT once one is over (champion or out).
		if (s.phase=="Selection" and not s.cup) or (s.cup and s.cup.over) then self:start(player,payload.player) end
		return true
	end
	if not s.cup then return false end
	if action=="CupFight" then self:fight(player);return true end
	if action=="CupSkip" then self:skip(player);return true end
	if action=="CupBracket" then
		if s.phase=="Result" and s.cupResolved then self:advance(player,s) end
		return true
	end
	if action=="CupLeave" then self:leave(player);return true end
	-- No rematch inside a cup: the result screen continues the bracket.
	if action=="Rematch" then return true end
	-- Watching: the player's own inputs drive nothing.
	if s.spectate and s.phase=="Duel" then return true end
	return false
end
-- Matches:update, every frame: the autopilot of a watched match, the result.
function Tournament:update(player,s,now)
	if not s.cup then return end
	if s.cupPilot and s.phase=="Duel" and not s.finishing and not (s.introUntil and now<s.introUntil) then
		if s.cupPilot.actor~=s.human then s.cupPilot=require(script.Parent.AI).new(s.combat,s.human,player.UserId%100000) end
		s.cupPilot:update(now)
	end
	if s.phase=="Result" and not s.cupResolved then self:matchOver(player,s) end
end
return Tournament
