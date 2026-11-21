-- The first combat (21/11, DEC-047, replacing the first minute of B1 lot 2):
-- PLAY on the roster starts one real round against the fighter's story rival
-- played by the novice AI, and the coach (Server/Coach) gives a prompt when
-- its moment comes, once; holding the skip silences it; the next duel is an
-- ordinary one. The server measures the first input, jutsu and finished duel.
-- Real Matches / Coach / Combat on harness rigs and a scripted clock; the
-- screen is checked in Studio.
local H=require("./Harness")
local clock=5000
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
local FirstMinute=H.load("Shared/FirstMinute")
local Fighters=H.load("Shared/Fighters")
local BetaRoster=H.load("Shared/BetaRoster")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function last(player) local l=inbox[player];return l and l[#l] end
local id=0
local function fresh()
	local m=Matches.new(remote)
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
local Coach=H.load("Server/Coach")

test("every beta fighter has a rival in the beta and a signature in slot 2",function()
	for _,f in BetaRoster do
		local rival=FirstMinute.rival(f)
		assert(rival and table.find(BetaRoster,rival) and rival~=f,"no rival for "..f)
		assert(FirstMinute.rival(rival)==f,"rivals not paired: "..f)
		local sig=FirstMinute.signature(Fighters[f])
		assert(sig and sig.Id and sig.Name,"no signature for "..f)
	end
	assert(FirstMinute.signature(Fighters.Lion).Id=="Chidori","Sasuke's signature is not the Chidori")
end)

test("PLAY: one real round against his rival played by the novice, the coach's prompts when their moment comes",function()
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"First",{player="Lion"})
	assert(s.phase=="Duel" and s.tutorial==nil and s.coach and s.firstFight,"the first combat did not start")
	assert(s.human.fighterId=="Lion" and s.bot.fighterId=="Sand","not Sasuke with Gaara")
	assert(s.roundsToWin==1 and Matches.aiLevel(s)=="first" and s.ai.tune.UltimateBelow==0,"not one round against the novice")
	assert(s.bot.outScale==Coach.BotDamage and s.human.healthFloor and s.human.healthFloor>0,"the novice's handicap")
	-- the novice hits softer, and he keeps his floor whatever happens
	local before=s.human.health
	s.combat:damage(s.bot,s.human,10,false,false)
	assert(math.abs((before-s.human.health)-10*Coach.BotDamage*(H.load("Shared/Config").DamageScale or 1))<.01,"the novice's blow was not softer")
	s.human.health=s.human.healthFloor+1
	s.combat:damage(s.bot,s.human,60,false,false)
	assert(s.human.health>=s.human.healthFloor,"he went under his floor")
	s.human.health=s.human.def.Health;s.human.state="Neutral";s.human.reaction=nil;s.human.untilTime=0
	-- after the intro, far from him: the coach says to go to him
	s.ai.update=function() end
	s.combat:relocate(s.bot,s.human.root.Position+H.V.new(0,0,-20))
	step(m,2.8)
	assert(s.coach.current and s.coach.current.id=="move","no prompt to go to him: "..tostring(s.coach.current and s.coach.current.id))
	local panel=last(player).tutorial
	assert(panel and panel.first and panel.coach and panel.key and panel.pad and panel.touch,"the panel does not get the prompt")
	assert(last(player).first=="duel","the snapshot does not say first duel")
	-- he walks to him: done, gone for good
	for _=1,5 do s.combat:relocate(s.human,s.human.root.Position+H.V.new(0,0,-3));step(m,.04) end
	assert(s.coach.done.move,"the walk did not count")
	step(m,Coach.DoneHold+.1)
	-- he winds up a strike close by: GUARD; a blocked blow ends it
	s.combat:relocate(s.human,s.bot.root.Position+H.V.new(0,0,4))
	s.bot.attackName="Light1";s.bot.state="Startup";s.bot.untilTime=s.combat.now+5
	step(m,.1)
	assert(s.coach.current and s.coach.current.id=="guard","no guard prompt as he winds up: "..tostring(s.coach.current and s.coach.current.id))
	s.human.events=s.human.events or {};s.human.events.GuardHit=(s.human.events.GuardHit or 0)+1
	step(m,.1)
	assert(s.coach.done.guard,"the blocked blow did not count")
	s.bot.attackName=nil;s.bot.state="Neutral";s.bot.untilTime=0
	-- the round ends: the first combat is over, the rematch is ordinary
	s.finish(s.human,s.bot);step(m,3.2)
	assert(s.phase=="Result","one round did not end the first combat")
	assert(s.metrics.duelAt,"the finished first combat was not measured")
	assert(s.firstFight==nil and s.coach==nil,"the first combat stays on")
	send(m,player,"Rematch")
	assert(s.phase=="Duel" and s.coach==nil and s.roundsToWin==2,"the rematch is still the first combat")
end)

test("holding the skip silences the coach; the duel goes on",function()
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"First",{player="Flashstep"})
	assert(s.bot.fighterId=="Leaf","Minato's rival is not Lee")
	step(m,.1)
	send(m,player,"TutorialSkip")
	step(m,.1)
	assert(s.coach==nil and s.phase=="Duel" and s.firstFight,"the skip ended more than the prompts")
end)

test("measures: joined, the first input, the first jutsu, in order and once",function()
	local m,player=fresh()
	local s=m.sessions[player]
	assert(s.metrics.joinedAt,"joining was not measured")
	assert(not s.metrics.inputAt)
	send(m,player,"First",{player="Mirage"})
	assert(s.metrics.inputAt,"PLAY was not the first input")
	local first=s.metrics.inputAt
	send(m,player,"Move",{direction=H.V.new(1,0,0)})
	assert(s.metrics.inputAt==first,"the first input was measured twice")
	step(m,.1)
	assert(not s.metrics.jutsuAt)
	s.human.events=s.human.events or {};s.human.events["Cast:FireBloom"]=1
	step(m,.1)
	-- (19/11, vague 2 DEV 4) the jutsu stays in the log; the funnel follows
	-- the loop (Matches.FUNNEL): PLAY started his first duel
	assert(s.metrics.jutsuAt,"the first jutsu was not measured")
	assert(s.metrics.startedAt and s.metrics.funnel==4,"the funnel did not see the first duel start: "..tostring(s.metrics.funnel))
	-- his first blow that lands
	s.bot.health=s.bot.def.Health-1
	step(m,.1)
	assert(s.metrics.hitAt and s.metrics.funnel==5,"the funnel did not see the first blow land")
end)

test("a bad PLAY is refused: an unknown fighter, or outside the roster",function()
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"First",{player="Nobody"})
	assert(s.phase=="Selection" and s.firstStage==nil,"an unknown fighter started")
	send(m,player,"First",{player=42})
	assert(s.phase=="Selection","a number started")
	send(m,player,"First",{player="Lion"})
	local epoch=s.epoch
	send(m,player,"First",{player="Lion"})
	assert(s.epoch==epoch,"PLAY in a duel restarted it")
end)

-- (14/11, François: « que notre perso puisse combattre » dans la ville) A
-- duel asked at a master's home is fought there, in the village, when the
-- server finds the player's walker there; asked from the board, or from far
-- away, it is the stadium's.
test("a first duel asked at Lee's home is fought on Training Ground Three; elsewhere, the stadium",function()
	local Hub=H.load("Server/Hub")
	local HubMap=H.load("Shared/HubMap")
	local Config=H.load("Shared/Config")
	local builtWas,bodiesWas,enterWas=Hub.built,Hub.bodies,Hub.enter
	Hub.built=true;Hub.enter=function() end
	local ok,err=pcall(function()
		local m,player=fresh()
		local spot=HubMap.Masters.Leaf.duel
		local centre=HubMap.Origin+spot.at
		-- his walker in the village (Hub.enter makes it, a duel takes it away)
		local function walkAt(position)
			local root={Position=position}
			Hub.bodies[player]={character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end,GetAttribute=function() return nil end}}
		end
		Hub.bodies={}
		walkAt(centre+H.V.new(6,3,10))
		send(m,player,"First",{player="Leaf",here="Leaf"})
		local s=m.sessions[player]
		assert(s.phase=="Duel" and s.site and s.site.key=="Leaf","the first duel did not stay at Lee's")
		assert((s.origin-centre).Magnitude<1e-3 and s.radius==spot.radius,"not on the training ground: "..tostring(s.origin))
		-- the bodies are held inside the ground's own circle
		local far=s.combat:clamp(centre+H.V.new(200,3,0))
		assert(math.abs((far-centre).Magnitude-spot.radius)<.5,"the circle is the stadium's: "..tostring(far))
		-- (21/11, DEC-047) the first combat is the real duel, on the training ground
		assert(s.firstStage=="duel" and s.tutorial==nil and s.coach and s.site and s.site.key=="Leaf" and (s.origin-centre).Magnitude<1e-3,"the first combat left Lee's")
		-- back to Konoha: where it was fought
		m:selection(player);walkAt(centre)
		-- from the board (no `here`): the stadium
		send(m,player,"Start",{player="Leaf",bot="Lion"})
		assert(s.phase=="Duel" and s.site==nil and s.radius==nil and (s.origin-Matches.laneOrigin(s.lane)).Magnitude<1e-3,"a board duel left the stadium")
		m:selection(player)
		-- asked as if at Lee's while far away (a client's word only): the stadium
		walkAt(HubMap.Origin+H.V.new(0,3,190))
		send(m,player,"First",{player="Leaf",here="Leaf"})
		assert(s.site==nil,"a duel came to the village from the gate")
		m:selection(player)
		-- the flag off: the stadium
		walkAt(centre)
		Config.Hub.VillageDuels=false
		send(m,player,"First",{player="Leaf",here="Leaf"})
		assert(s.site==nil,"VillageDuels off, yet in the village")
		Config.Hub.VillageDuels=true
	end)
	Hub.built,Hub.bodies,Hub.enter=builtWas,bodiesWas,enterWas
	assert(ok,err)
end)

print(("FirstMinute: %d passed"):format(passed))
