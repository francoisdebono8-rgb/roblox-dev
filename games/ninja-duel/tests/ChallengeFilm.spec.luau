-- The CM's series « MY AVATAR VS THE 8 » (24/11, doc projet
-- claude/cm-serie-my-avatar-vs-the-8-2026-11-24): the challengeFilm op
-- (Server/DevChallengeFilm) plays an inspiration's challenge in the street
-- exactly as a player meets it — the inspiration blocks the street with his
-- dare, the challenge is accepted there, the duel's intro gives his line then
-- the VS card — with an AI at the avatar's stick too, to the decided duel,
-- and tells who won each round and when. Also: all eight inspirations may
-- challenge him (STUDENT OF THE EIGHT without changing kits), and the board of
-- the eight's state (Progression.challenges8).
-- Real Matches / SoloPlay / Combat / AI on harness rigs and a scripted clock;
-- the picture is the CM's, in Studio.
local H=require("./Harness")
local V=H.V
local clock=5000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
		NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
H.load("Shared/Config").DamageScale=H.GameDamageScale
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local SoloPlay=H.load("Server/SoloPlay")
local Progression=H.load("Server/Progression")
local AI=H.load("Server/AI")
local Film=H.load("Server/DevChallengeFilm")
local HubMap=H.load("Shared/HubMap")
local PlayTexts=H.load("Shared/PlayTexts")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function last(player) local l=inbox[player];return l and l[#l] end
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end

-- A walker in the village: his root, and where the server put him.
local function walker(at)
	local moved={}
	local root={Position=at}
	local model={PivotTo=function(_,cf) root.Position=cf.Position;table.insert(moved,cf) end}
	root.Parent=model
	return {character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end}},root,moved
end

test("all eight inspirations may challenge him, his own kit's too",function()
	local kits=SoloPlay.challengers("Legion")
	assert(#kits==8 and table.find(kits,"Legion"),"the eight: "..table.concat(kits,","))
end)

test("the board of the eight: the inspirations beaten, in the board's order",function()
	local b=Progression.challenges8({beaten={Sand=true,Legion=true,Nobody=true}})
	assert(b.count==2 and b.need==8 and b.beaten.Legion and b.beaten.Sand and not b.beaten.Nobody,"the beaten: "..b.count)
	assert(b.order[1]=="Legion" and #b.order==8,"the order")
	local none=Progression.challenges8(nil)
	assert(none.count==0 and next(none.beaten)==nil,"a new profile")
end)

test("challengeFilm's spec: the eight, the streets, 1 to 3 rounds, the AI levels, the avatar's kit",function()
	assert(Film.plan({kit="Nobody"},"Lion")==nil,"an unknown inspiration")
	local _,why=Film.plan({kit="Legion",street="Moon"},"Lion")
	assert(why and string.find(why,"MarketLane",1,true),"the streets are not listed: "..tostring(why))
	assert(Film.plan({kit="Legion",rounds=4},"Lion")==nil and Film.plan({kit="Legion",rounds=1.5},"Lion")==nil,"rounds")
	assert(Film.plan({kit="Legion",avatar="god"},"Lion")==nil and Film.plan({kit="Legion",prodigy="first"},"Lion")==nil,"levels")
	assert(Film.plan({kit="Legion"},nil)==nil,"no kit for the avatar")
	local p=assert(Film.plan({kit="Legion"},"Lion"))
	assert(p.site.key=="MarketLane" and p.rounds==2 and p.dare==3 and p.with=="Lion" and p.avatar=="normal" and p.prodigy=="normal","the defaults")
	-- his own kit's inspiration: a mirror, as in the game
	assert(Film.plan({kit="Lion"},"Lion"),"his own kit's inspiration refused")
end)

test("challengeFilm: the dare in the street, the challenge accepted there, both AIs to the decided duel",function()
	local m=Matches.new(remote)
	local player=fakePlayer(7)
	m:selection(player)
	local site
	for _,s in HubMap.Streets do if s.key=="Courtyard" then site=s end end
	local body,root,moved=walker(HubMap.Origin+site.at+V.new(60,3,0))
	m.solo.bodies={[player]=body}
	local shown={}
	m.solo.rig=function(c) table.insert(shown,c);return {Destroy=function() end} end
	-- a random challenger elsewhere goes when the film's comes
	m.solo.challenge={kit="Sand",site=HubMap.Streets[1],at=clock,leaveAt=clock+100,line="x"}
	local film=Film.new({matches=m,AI=AI,selected=function() return nil end,learned=function() return true end,seed=function() return 11 end})
	local r=film:start(player,{kit="Legion",street="Courtyard",with="Lion",dare=1,rounds=2},clock)
	assert(r.ok and r.kit=="Legion" and r.street=="Courtyard" and r.line==PlayTexts.ChallengeLines.Legion,"not started: "..tostring(r.error))
	-- the avatar at one end of the street, facing the inspiration in its middle
	local stand,centre=Film.marks(site)
	assert(#moved==1 and (root.Position-stand).Magnitude<.01,"the avatar was not put in the street")
	local look=moved[1].LookVector
	assert(look:Dot((centre-stand)*V.new(1,0,1)/((centre-stand)*V.new(1,0,1)).Magnitude)>.99,"the avatar does not face him")
	assert(m.solo.challenge and m.solo.challenge.kit=="Legion" and m.solo.challenge.site==site and #shown==1,"the inspiration is not in the street")
	local s=m.sessions[player]
	local function step(seconds)
		for _=1,math.max(1,math.ceil(seconds/.02)) do clock+=.02;m:update(.02,clock);runTimers();film:step(clock) end
	end
	-- his dare: still walking
	step(.5)
	assert(s.phase=="Selection" and film:result().state=="dare","the duel began before his dare")
	step(.6)
	assert(s.phase=="Duel" and s.challenge=="Legion" and s.site and s.site.key=="Courtyard" and s.site.street,"not fought where he stood")
	assert(s.human.fighterId=="Lion" and s.bot.fighterId=="Legion","not the avatar's kit against the inspiration")
	assert(s.roundsToWin==2 and s.autopilot and s.scripted and Matches.aiLevel(s)=="normal","the duel's frame")
	-- the intro: his line, the VS card, BEGIN
	local snap=last(player)
	assert(snap.dare and snap.dare.kit=="Legion" and snap.dare.line==PlayTexts.ChallengeLines.Legion,"the dare is not in the snapshot")
	local intro=Matches.Dare.line+Matches.Dare.vs+(Config.IntroBegin or .75)
	assert(snap.intro<=intro+.01 and snap.intro>intro-.3,"the intro: "..snap.intro)
	-- the avatar's AI waits for BEGIN like the inspiration's
	local start=s.human.root.Position
	step(intro-.3)
	assert((s.human.root.Position-start).Magnitude<.5,"the avatar moved during the intro")
	assert(last(player).dare,"the dare left before BEGIN")
	step(.4)
	assert(last(player).dare==nil,"the dare outlives the intro")
	-- to the end
	local t=0
	local hurt=false
	while film:result().state=="duel" and t<Film.MAX_DUEL do
		step(.2);t+=.2
		if s.bot.health<s.bot.def.Health then hurt=true end
	end
	local res=film:result()
	assert(res.state=="done" and (res.winner=="avatar" or res.winner=="prodigy"),"no winner: "..tostring(res.state).." "..tostring(res.error))
	assert(hurt,"the avatar never touched him")
	assert(#res.rounds>=2 and #res.rounds<=3,"rounds: "..#res.rounds)
	local wins={avatar=0,prodigy=0}
	for i,round in res.rounds do
		wins[round.winner]+=1
		assert(round.round==i and round.since>0 and round.at>res.duelAt,"round "..i)
		assert(round.decisive==(i==#res.rounds),"round "..i.." decisive")
	end
	assert(wins[res.winner]==2,"the winner did not win two rounds")
	assert(res.finalBlow and res.finalBlow.by==res.winner and res.finalBlow.at==res.rounds[#res.rounds].at,"the final blow")
	assert(s.phase=="Result" and not s.autopilot and not s.scripted,"his stick is not back")
	assert(m.solo.challenge==nil,"the inspiration stays in the street")
	print(string.format("     Lion avatar vs Legion: %s in %d rounds, final blow %.1f s into the duel",res.winner,#res.rounds,res.finalBlow.since))
	-- another take: from the result screen, straight back into the street
	local again=film:start(player,{kit="Legion",street="Courtyard",with="Lion",dare=0,rounds=1},clock)
	assert(again.ok or string.find(again.error or "","walking",1,true),"another take: "..tostring(again.error))
end)

test("challengeFilm refuses what it cannot film, and says why",function()
	local m=Matches.new(remote)
	local player=fakePlayer(8)
	m:selection(player)
	m.solo.bodies={}
	local film=Film.new({matches=m,AI=AI,selected=function() return "Lion" end,learned=function(_,kit) return kit=="Lion" end,seed=function() return 1 end})
	local r=film:start(player,{kit="Legion"},clock)
	assert(not r.ok and string.find(r.error,"walking",1,true),"not walking: "..tostring(r.error))
	r=film:start(player,{kit="Legion",with="Sand"},clock)
	assert(not r.ok and string.find(r.error,"learned",1,true),"a kit he has not learned: "..tostring(r.error))
	r=film:start(player,{kit="Legion",street="Moon"},clock)
	assert(not r.ok and string.find(r.error,"street",1,true),"a street that is not one")
end)

print(string.format("NinjaDuel challengeFilm (the CM's series): %d PASS",passed))
