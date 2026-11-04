-- The Prodigy Tournament against the AI (Server/Tournament, roadmap 04/11
-- step 2): the bracket of the eight, the player's own matches as duels, the
-- AI-vs-AI matches watched with an autopilot (or skipped from the engine's
-- win rates), elimination, the champion. Real Matches/Combat/AI on harness
-- rigs and a scripted clock; the screen is checked in Studio.
local H=require("./Harness")
local clock=2000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local Tournament=H.load("Server/Tournament")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function last(player) local l=inbox[player];return l and l[#l] end
local id=0
local function fresh(odds)
	local m=Matches.new(remote)
	if odds then m.tournament.odds=odds end
	m.tournament.rng={NextNumber=function() return .5 end}
	id+=1
	local player={UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players}
	m:selection(player)
	return m,player
end
local function send(m,player,action,extra)
	local s=m.sessions[player]
	s.bucket.tokens=100;s.lastLifecycle=-10
	local payload={action=action,epoch=s.epoch}
	for k,v in extra or {} do payload[k]=v end
	m:request(player,payload)
end
local function step(m,seconds)
	for _=1,math.max(1,math.ceil(seconds/.02)) do clock+=.02;m:update(.02,clock);runTimers() end
end
-- A match of the player's ends: `won` decides who takes both rounds.
local function finish(m,player,won)
	local s=m.sessions[player]
	for _=1,2 do
		step(m,3)
		if s.phase~="Duel" then break end
		if won then s.finish(s.human,s.bot) else s.finish(s.bot,s.human) end
		step(m,3.2)
	end
	assert(s.phase=="Result","the match did not end ("..tostring(s.phase)..")")
	step(m,.1)
end

test("start: the eight in the story's bracket, each once, the player on his fighter's seat",function()
	local m,player=fresh()
	send(m,player,"CupStart",{player="Lion"})
	local s=m.sessions[player]
	local p=last(player)
	assert(s.phase=="Bracket" and p.phase=="Bracket" and p.cup,"no bracket")
	local seen={}
	for _,f in p.cup.seats do assert(not seen[f],"twice: "..f);seen[f]=true end
	assert(#p.cup.seats==8 and p.cup.seats[p.cup.me]=="Lion","Sasuke is not on his seat")
	assert(p.cup.next.match==1 and not p.cup.next.mine,"the first match is not Naruto–Neji")
	assert(type(p.cup.next.lineA)=="string" and #p.cup.next.lineA>4,"no word before the match")
	-- a fighter outside the beta cannot enter
	local m2,p2=fresh()
	send(m2,p2,"CupStart",{player="Mirror"})
	assert(m2.sessions[p2].phase=="Selection","a cup started with Haku")
end)

test("an AI-vs-AI match is played for real by an autopilot, the player's inputs drive nothing",function()
	local m,player=fresh()
	send(m,player,"CupStart",{player="Lion"})
	send(m,player,"CupFight")
	local s=m.sessions[player]
	assert(s.phase=="Duel" and s.spectate and s.autopilot and s.cupPilot,"not watching")
	assert(s.human.fighterId=="Legion" and s.bot.fighterId=="GentleFist","wrong pair")
	step(m,3)
	local p=last(player)
	assert(p.spectate==true and p.cup,"the snapshot does not say spectate")
	-- the player presses: nothing of his reaches the fighters
	local acted=0
	local act=m.act
	m.act=function(...) acted+=1;return act(...) end
	send(m,player,"Attack",{clientTime=clock});send(m,player,"Move",{direction=H.V.new(1,0,0)})
	m.act=act
	assert(acted==0,"input reached a watched fighter")
	-- the autopilot moves its fighter (its stick is not zeroed as stale)
	local from=s.human.root.Position
	step(m,4)
	assert((s.human.root.Position-from).Magnitude>1 or s.human.attackName~=nil or s.human.state~="Neutral","the autopilot never moved")
	-- the match is decided (whoever wins), the bracket records it
	for _=1,2 do if s.phase=="Duel" then s.finish(s.human,s.bot);step(m,3.4) end end
	step(m,.1)
	assert(s.phase=="Result" and s.cup.winners[1]==1,"the watched match's winner was not recorded")
	send(m,player,"Rematch")
	assert(s.phase=="Result","a rematch inside the cup")
	send(m,player,"CupBracket")
	assert(s.phase=="Bracket" and last(player).cup.next.match==2 and last(player).cup.next.mine,"not on to Sasuke–Gaara")
end)

test("skip: an AI match decided from the engine's win rates, never his own",function()
	local m,player=fresh({Legion={GentleFist=.9}})
	send(m,player,"CupStart",{player="Lion"})
	send(m,player,"CupSkip")
	local s=m.sessions[player]
	assert(s.cup.winners[1]==1 and s.cup.skipped[1],"Naruto (90%) did not go through")
	assert(s.phase=="Bracket" and s.cup.match==2,"not on to match 2")
	send(m,player,"CupSkip")
	assert(s.cup.winners[2]==nil,"his own match was skipped")
end)

test("his match: a duel against the next AI; lost, the bracket plays out without him",function()
	local m,player=fresh()
	send(m,player,"CupStart",{player="Lion"})
	send(m,player,"CupSkip")
	send(m,player,"CupFight")
	local s=m.sessions[player]
	assert(s.phase=="Duel" and not s.spectate and s.human.fighterId=="Lion" and s.bot.fighterId=="Sand","not Sasuke against Gaara")
	finish(m,player,false)
	send(m,player,"CupBracket")
	local cup=last(player).cup
	assert(cup.out and cup.over and cup.eliminatedIn=="QUARTER-FINAL","not eliminated in the quarter-final")
	assert(cup.champion and cup.champion~=cup.me and cup.winners[7],"the bracket did not play out")
	assert(s.phase=="Bracket","no bracket after the elimination")
end)

test("champion: three matches won, the champion's card; leaving ends the cup",function()
	local m,player=fresh()
	send(m,player,"CupStart",{player="Leaf"})
	local s=m.sessions[player]
	for _=1,7 do
		if s.cup.over then break end
		local n=last(player).cup.next
		if n.mine then send(m,player,"CupFight");finish(m,player,true);send(m,player,"CupBracket")
		else send(m,player,"CupSkip") end
	end
	assert(s.phase=="Champion" and last(player).phase=="Champion","no champion's card")
	assert(last(player).cup.champion==last(player).cup.me,"the champion is not him")
	-- (Audit 04/11) NEW TOURNAMENT on the champion's card starts a new bracket
	local before=s.cup
	send(m,player,"CupStart",{player="Leaf"})
	assert(s.cup and s.cup~=before and not s.cup.over and s.cup.match==1 and s.phase=="Bracket","NEW TOURNAMENT did nothing")
	send(m,player,"CupLeave")
	assert(s.phase=="Selection" and s.cup==nil,"the cup outlived the roster")
end)

-- (B1, 04/11) The AI's level: a duel takes the roster's choice (easy unless
-- said otherwise, kept for the rematch, an unknown word refused); in the cup
-- his matches climb easy, normal, hard; a watched match is normal.
test("AI levels: the roster's choice for a duel, climbing in the cup",function()
	local AI=H.load("Server/AI")
	local Config=H.load("Shared/Config")
	local easy=AI.new(nil,{},1,"easy")
	assert(easy.tune.Tick>Config.AI.Tick and easy.tune.Aggression<Config.AI.Aggression and easy.tune.Opening,"easy is not gentler")
	assert(AI.new(nil,{},1,"normal").tune.Aggression==Config.AI.Aggression,"normal is not the tuning")
	assert(AI.new(nil,{},1,"nonsense").tune.Aggression==Config.AI.Aggression,"an unknown level changed the tuning")
	assert(AI.new(nil,{},1,"hard").tune.Reaction<Config.AI.Reaction,"hard is not quicker")
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"Start",{player="Lion",bot="Sand"})
	assert(s.phase=="Duel" and s.ai.tune.Opening and Matches.aiLevel(s)=="easy","the first duel is not easy")
	m:selection(player)
	send(m,player,"Start",{player="Lion",bot="Sand",level="hard"})
	assert(Matches.aiLevel(s)=="hard" and s.ai.tune.Reaction<Config.AI.Reaction,"the roster's HARD was ignored")
	m:selection(player)
	send(m,player,"Start",{player="Lion",bot="Sand",level="god"})
	assert(Matches.aiLevel(s)=="hard","an unknown level replaced the last good one")
	-- the cup: easy in the quarter-final, harder after
	m:selection(player)
	send(m,player,"CupStart",{player="Leaf"})
	local seen={}
	for _=1,7 do
		if s.cup.over then break end
		local n=last(player).cup.next
		if n.mine then
			send(m,player,"CupFight")
			table.insert(seen,Matches.aiLevel(s))
			finish(m,player,true);send(m,player,"CupBracket")
		else
			send(m,player,"CupFight")
			assert(s.spectate and Matches.aiLevel(s)=="normal","a watched match is not normal")
			send(m,player,"CupSkip")
			if s.phase~="Bracket" then send(m,player,"CupBracket") end
		end
	end
	assert(table.concat(seen,",")=="easy,normal,hard","the cup does not climb: "..table.concat(seen,","))
end)

-- (Security review 04/11, finding 1) the cup's arena builds share the
-- roster's 0.8 s gap: CupFight right after CupStart is dropped.
test("cup actions are gated like the roster's: no arena rebuilt in a burst",function()
	local m,player=fresh()
	local s=m.sessions[player]
	s.bucket.tokens=100
	m:request(player,{action="CupStart",epoch=s.epoch,player="Lion"})
	assert(s.cup and s.phase=="Bracket","the cup did not start")
	local epoch=s.epoch
	m:request(player,{action="CupFight",epoch=s.epoch})
	assert(s.epoch==epoch and s.phase=="Bracket","CupFight inside the gap built an arena")
	s.lastLifecycle=-10
	m:request(player,{action="CupFight",epoch=s.epoch})
	assert(s.phase=="Duel","CupFight after the gap did nothing")
end)

test("odds: the engine's table covers the 56 ordered pairs and stays between 10 and 90 %",function()
	local odds=H.load("Server/CupOdds")
	local T=Tournament.new(nil,odds)
	local n=0
	for _,x in Tournament.Seats do for _,y in Tournament.Seats do if x~=y then
		local p=T:chance(x,y);n+=1
		assert(p>=.1 and p<=.9,x.." vs "..y.." "..p)
		assert(math.abs(p+T:chance(y,x)-1)<.21,"asymmetric "..x.." "..y)
	end end end
	assert(n==56)
end)

print(("Tournament: %d passed"):format(passed))
