-- The first minute (B1 lot 2, DEC-034): PLAY on the roster runs four prompts
-- with the fighter's story rival as a waiting partner (move, three hits, a
-- dodge, the signature), then a real duel against the easy AI; holding the
-- skip goes straight to that duel; the next duel is an ordinary one. The
-- server measures the first input, jutsu and finished duel. Real Matches /
-- Tutorial / Combat on harness rigs and a scripted clock; the screen is
-- checked in Studio.
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
-- Do what the current prompt asks, as the engine would record it.
local function perform(s)
	local t=s.tutorial
	local spec=t.steps[t.index]
	s.human.events=s.human.events or {}
	local ev=s.human.events
	if spec.id=="move" then t.travel=20
	elseif spec.id=="string" then ev.Hit=(ev.Hit or 0)+3
	elseif spec.id=="dodge" then ev.Dodge=(ev.Dodge or 0)+1
	elseif spec.id=="signature" then local k="Cast:"..spec.technique.Id;ev[k]=(ev[k] or 0)+1 end
end

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

test("PLAY: four prompts against his rival, then a real duel against the easy AI",function()
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"First",{player="Lion"})
	assert(s.phase=="Duel" and s.tutorial and s.tutorial.first,"the first minute did not start")
	assert(s.human.fighterId=="Lion" and s.bot.fighterId=="Sand","not Sasuke with Gaara")
	local ids={}
	for _,spec in s.tutorial.steps do table.insert(ids,spec.id);assert(spec.touch and spec.key and spec.pad,"a prompt without its keys: "..spec.id) end
	assert(table.concat(ids,",")=="move,string,dodge,signature","the prompts: "..table.concat(ids,","))
	step(m,.1)
	assert(last(player).tutorial.first and last(player).tutorial.touch,"the panel does not know it is the first minute")
	assert(last(player).first=="intro","the snapshot does not say intro")
	local epoch=s.epoch
	for k=1,4 do
		assert(s.tutorial and s.tutorial.index==k,"not on prompt "..k)
		perform(s);step(m,if k==4 then 2.6 else .4)
	end
	assert(s.epoch>epoch and s.tutorial==nil and s.firstStage=="duel","no duel after the prompts")
	assert(s.roundsToWin==2 and s.human.fighterId=="Lion" and s.bot.fighterId=="Sand","not the real duel")
	assert(Matches.aiLevel(s)=="easy" and s.ai.tune.Opening,"the first duel is not easy")
	step(m,.1)
	assert(last(player).first=="duel","the snapshot does not say first duel")
	-- the duel ends: the next one (REMATCH) is ordinary
	s.finish(s.human,s.bot);step(m,3.2)
	if s.phase=="Duel" then s.finish(s.human,s.bot);step(m,3.2) end
	assert(s.phase=="Result","the first duel did not end")
	assert(s.metrics.duelAt,"the finished first duel was not measured")
	send(m,player,"Rematch")
	assert(s.phase=="Duel" and s.firstStage==nil,"the rematch is still the first duel")
end)

test("holding the skip goes straight to the duel; a prompt nobody finds moves on by itself",function()
	local m,player=fresh()
	local s=m.sessions[player]
	send(m,player,"First",{player="Flashstep"})
	assert(s.bot.fighterId=="Leaf","Minato's partner is not Lee")
	step(m,.1)
	-- nothing pressed: the first prompt gives way after its 25 s
	step(m,26)
	assert(s.tutorial and s.tutorial.index==2,"the move prompt held him")
	send(m,player,"TutorialSkip")
	step(m,.1)
	assert(s.tutorial==nil and s.firstStage=="duel" and s.phase=="Duel","holding the skip did not start the duel")
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
	assert(s.metrics.jutsuAt and s.metrics.funnel==3,"the first jutsu was not measured")
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

print(("FirstMinute: %d passed"):format(passed))
