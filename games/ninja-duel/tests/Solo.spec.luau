-- The things to do alone in Konoha (21/11, étape 3 DEV 4, DEC-047; François:
-- « il n'y a rien à faire dans le village s'il n'y a personne »): the rooftop
-- race (its rings on the plan's roofs, its rules, its board fastest first),
-- the kunai targets, what they pay (the day's share, the title), the
-- inspiration's challenge, the duel asked anywhere fought near him.
-- Headless (Lune's Roblox instances); the run on the roofs, the look of the
-- rings and the throws are Studio checks (the OUTILLEUR's robot times them).
local H=require("./Harness")
local roblox=require("@lune/roblox")
H.envBase.Instance=roblox.Instance
H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim;H.envBase.Vector2=roblox.Vector2
local Instance=roblox.Instance
local Vector3=roblox.Vector3
local HubMap=H.load("Shared/HubMap")
local Solo=H.load("Shared/Solo")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local S=HubMap.Scale or 1
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end
local function body(at)
	local root={Position=at}
	return {character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end}},root
end

-- the plan's village, built once
local Hub=H.load("Server/Hub")
local village
do
	local mode=Config.Hub.Layout
	Config.Hub.Layout="konoha2"
	Hub.folder=nil;Hub.built=false
	village=Hub.build(Instance.new("Folder"))
	Config.Hub.Layout=mode
end

test("the race's rings stand on the plan's roofs, in order, and the route can be run (not one jump across the map)",function()
	assert(#Solo.Race.rings==10,"ten rings")
	local tops={}
	for _,d in village:GetDescendants() do
		if d:IsA("BasePart") and (d.Name=="Roof" or d.Name=="RoofDeck") then table.insert(tops,d) end
	end
	for i,r in Solo.Race.rings do
		local floor=Solo.world(r[1],r[2],r[3])
		local under=nil
		for _,p in tops do
			local l=p.CFrame:PointToObjectSpace(floor)
			if math.abs(l.X)<=p.Size.X/2 and math.abs(l.Z)<=p.Size.Z/2 and math.abs(p.CFrame.Position.Y+p.Size.Y/2-floor.Y)<.6 then under=p end
		end
		assert(under,"ring "..i.." stands on no roof at "..tostring(floor))
		-- its centre over the roof, passed by a body standing there
		assert(Solo.inRing(i,floor+Vector3.new(0,3,0)) and not Solo.inRing(i,floor+Vector3.new(0,-6,0)),"ring "..i.." passed from the street")
	end
	-- no two rings further apart than a run over the roofs (the market streets)
	for i=2,#Solo.Race.rings do
		local a,b=Solo.ring(i-1),Solo.ring(i)
		assert((Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude<60*S,"ring "..i.." too far from "..(i-1))
	end
	print(string.format("  the route: %.0f studs; the fastest honest time %.1f s",Solo.raceLength(),Solo.raceFloor()))
	assert(Solo.raceFloor()>4 and Solo.raceFloor()<20)
end)

test("a run: the countdown at the post, the rings in order, the time; a teleport, too slow, too fast do not count",function()
	local post=Solo.startPost()+Vector3.new(0,3,0)
	local run=Solo.newRun(0,post)
	assert(Solo.raceStep(run,post,1)==nil and run.at==Solo.Race.countdown,"the countdown")
	-- walking away during the countdown starts it over
	Solo.raceStep(run,post+Vector3.new(40*S,0,0),2)
	assert(run.at==2+Solo.Race.countdown,"the countdown did not start over")
	run=Solo.newRun(0,post)
	local t=Solo.Race.countdown
	local last=post
	-- ring 2 before ring 1: nothing
	local function go(to,dt)
		-- walk there in steps an honest walker can take
		local steps=math.ceil((Vector3.new(to.X,0,to.Z)-Vector3.new(last.X,0,last.Z)).Magnitude/(40*.1))
		local what,value
		for k=1,math.max(1,steps) do
			t+=dt or .1
			local at=last:Lerp(to,k/math.max(1,steps))
			local w,v=Solo.raceStep(run,at,t)
			if w then what,value=w,v end
			if w=="fail" or w=="finish" then last=to;return w,v end
		end
		last=to
		return what,value
	end
	-- standing in ring 2 before ring 1: nothing
	local early=Solo.newRun(0,Solo.ring(2))
	assert(Solo.raceStep(early,Solo.ring(2),Solo.Race.countdown+.5)==nil and early.next==1,"ring 2 counted before ring 1")
	for i=1,#Solo.Race.rings-1 do
		local what,value=go(Solo.ring(i))
		assert(what=="ring" and value==i,"ring "..i..": "..tostring(what))
	end
	local what,value=go(Solo.ring(#Solo.Race.rings))
	assert(what=="finish" and value>Solo.raceFloor(),"no finish: "..tostring(what).." "..tostring(value))
	print(string.format("  a walker at 40 studs/s: %.1f s",value))
	-- a jump across the map
	run=Solo.newRun(0,post);t=Solo.Race.countdown+.1;Solo.raceStep(run,post,t)
	local w,why=Solo.raceStep(run,Solo.ring(5),t+.1)
	assert(w=="fail" and why=="teleport","a teleport counted")
	-- too slow
	run=Solo.newRun(0,post)
	w,why=Solo.raceStep(run,post,Solo.Race.countdown+Solo.Race.limit+1)
	assert(w=="fail" and why=="time","no limit")
	-- faster than any walker: every ring in one sample each, a hair apart
	run=Solo.newRun(0,post);run.last=Solo.ring(1)
	local tt=Solo.Race.countdown
	for i=1,#Solo.Race.rings do tt+=.03;run.lastAt=tt;run.last=Solo.ring(i);w,why=Solo.raceStep(run,Solo.ring(i),tt) end
	assert(w=="fail" and why=="floor","an impossible time counted: "..tostring(w))
end)

test("the targets: each board hit from the mark, a miss costs a second, the time; thrown too soon waits",function()
	local round=Solo.newTargets(0)
	local mark=Solo.targetsMark()+Vector3.new(0,4.5,0)
	assert(Solo.throw(round,mark,Vector3.new(1,0,0),1)=="wait","a throw in the countdown")
	local t=Solo.Targets.countdown+.1
	assert(Solo.throw(round,mark,Vector3.new(0,1,0),t)=="miss" and round.misses==1,"a throw at the sky hits")
	for i in Solo.Targets.boards do
		t+=.5
		local what,a=Solo.throw(round,mark,(Solo.board(i)-mark).Unit,t)
		if i<#Solo.Targets.boards then assert(what=="hit" and a==i,"board "..i..": "..tostring(what).." "..tostring(a))
		else assert(what=="done" and math.abs(a-(t-Solo.Targets.countdown+1))<1e-6,"the time with the miss: "..tostring(a)) end
	end
	-- a board already down is not hit again: the kunai flies through
	round=Solo.newTargets(0);t=Solo.Targets.countdown+.1
	Solo.throw(round,mark,(Solo.board(1)-mark).Unit,t)
	assert(round.up[1]==false)
	local i=Solo.hitBoard(round,mark,(Solo.board(1)-mark).Unit)
	assert(i~=1,"a board down was hit again")
	assert(Solo.throw(round,mark,(Solo.board(2)-mark).Unit,t+.1)=="wait","two throws in .1 s")
	assert(Solo.atMark(Solo.targetsMark()) and not Solo.atMark(Solo.targetsMark()+Vector3.new(0,0,80*S)),"where he may throw")
end)

test("what it pays: the first time, a new best, the day's share; the profile's record and the title",function()
	local r=Solo.new()
	local a=Solo.record(r,100,"race",{time=6000})
	assert(a.first and a.improved and a.paid==Solo.Gain.RaceFirst and r.rooftops.best==6000,"the first race")
	a=Solo.record(r,100,"race",{time=6500})
	assert(not a.improved and a.paid==Solo.Gain.RaceDone and r.rooftops.best==6000,"a slower race")
	a=Solo.record(r,100,"race",{time=5000})
	assert(a.improved and a.paid==Solo.Gain.RaceBest and r.rooftops.best==5000,"a new best")
	for _=1,100 do Solo.record(r,100,"step",{}) end
	assert(r.earned==Solo.DayCap and Solo.record(r,100,"step",{}).paid==0,"the day's share")
	assert(Solo.record(r,101,"step",{}).paid==Solo.Gain.Step,"a new day")
	assert(Solo.valid(r),"the record")
	assert(Solo.clock(4231)=="0:42.31" and Solo.clock(6000)=="1:00.00" and Solo.hundredths(42.314)==4231)
	-- through the profile
	local PS=H.load("Server/ProfileSchema")
	local p=PS.new("dev_solo")
	local out
	p,out=PS.apply(p,p.sequence+1,"soloRecord",{day=200,kind="race",time=5321})
	assert(out.first and p.solo.rooftops.best==5321 and PS.validate(p),"the profile's race")
	assert(not pcall(PS.apply,p,p.sequence+1,"soloRecord",{day=199,kind="step"}),"a day already past")
	assert(not pcall(PS.apply,p,p.sequence+1,"soloRecord",{day=200,kind="race",time=0}),"no time")
	assert(not pcall(PS.apply,p,p.sequence+1,"soloRecord",{day=200,kind="fly"}),"an unknown kind")
	local Style=H.load("Shared/CatalogStyle")
	assert(Style.met(p,"rooftops") and not Style.met(PS.new("dev_none"),"rooftops"),"ROOFTOP RUNNER")
end)

test("the board of the rooftop race: the fastest first, each time as the clock shows it",function()
	local L=H.load("Server/Leaderboards")
	local published={}
	local boards=L.new({ordered=function() return nil end,now=function() return 1795200000 end,name=function(id) return "N"..id end,
		publish=function(id,json) published[id]=json end,encode=function(t) return t end,spawn=function(fn,...) fn(...) end})
	boards:submit("Rooftops",fakePlayer(11),5200)
	boards:submit("Rooftops",fakePlayer(12),4100)
	boards:submit("Rooftops",fakePlayer(13),6150)
	boards:refresh()
	local rows=published.Rooftops.rows
	assert(rows[1].id==12 and rows[2].id==11 and rows[3].id==13,"not the fastest first")
	assert(rows[1].text=="0:41.00" and rows[3].text=="1:01.50","the clock's text")
	assert(published.Rating.rows[1]==nil or published.Rating.rows[1].text==nil,"a rating as a time")
end)

test("the server: a race run and paid, a throw that hits, the challenger in the street and his duel paid",function()
	local SoloPlay=H.load("Server/SoloPlay")
	local bodies={}
	local paid={}
	local function pay(player,kind,args) table.insert(paid,{kind=kind,args=args});return {paid=10,amount=10,best=args and args.time,improved=true} end
	local shown={}
	local sp=SoloPlay.new({siteFree=function() return true end},{bodies=bodies,pay=pay,rig=function(c) table.insert(shown,c);return nil end,random=function(a) return a end})
	local p=fakePlayer(21)
	-- far from the post: refused
	local b,root=body(Solo.startPost()+Vector3.new(60*S,3,0))
	bodies[p]=b
	assert(not sp:start(p,"race",0),"a race from afar")
	root.Position=Solo.startPost()+Vector3.new(0,3,0)
	assert(sp:start(p,"race",0) and p:GetAttribute("NinjaSolo")=="race" and p:GetAttribute("NinjaSoloNext")==1,"the race")
	local t=0
	local function walk(to)
		local from=root.Position
		local steps=math.ceil((Vector3.new(to.X,0,to.Z)-Vector3.new(from.X,0,from.Z)).Magnitude/4)+1
		for k=1,steps do t+=.11;root.Position=from:Lerp(to,k/steps);sp:update(t) end
	end
	t=Solo.Race.countdown
	for i in Solo.Race.rings do walk(Solo.ring(i)) end
	assert(p:GetAttribute("NinjaSoloEnd")=="finish" and p:GetAttribute("NinjaSolo")==nil and p:GetAttribute("NinjaSoloSerial")==1,"no finish: "..tostring(p:GetAttribute("NinjaSoloEnd")))
	assert(#paid==1 and paid[1].kind=="race" and paid[1].args.time==p:GetAttribute("NinjaSoloTime"),"not paid")
	-- the targets
	root.Position=Solo.targetsMark()+Vector3.new(0,3,0)
	assert(sp:start(p,"targets",t),"the targets")
	t+=Solo.Targets.countdown+.2
	assert(sp:throw(p,(Solo.board(3)-(root.Position+Vector3.new(0,1.5,0))).Unit*5,t)=="hit" and string.sub(p:GetAttribute("NinjaSoloUp"),3,3)=="0","a hit")
	assert(sp:throw(p,"far",t+1)==nil,"a throw that is not a direction")
	sp:stop(p,"quit")
	assert(p:GetAttribute("NinjaSolo")==nil and p:GetAttribute("NinjaSoloEnd")=="fail:quit","given up")
	-- the challenger comes near a walker, the walker accepts, the duel decided pays
	t+=Solo.Challenge.every
	sp:update(t)
	local c=sp.challenge
	assert(c and #shown==1 and c.kit~=nil and Solo.Challenge.lines[c.kit] and c.site,"no challenger")
	local q=fakePlayer(22)
	local qb=body(HubMap.Origin+c.site.at+Vector3.new(0,3,4))
	bodies[q]=qb
	assert(sp:accept(q,"Nobody",t)==nil,"another kit accepted")
	assert(sp:accept(q,c.kit,t)==c and c.taken==q,"not accepted")
	assert(sp:accept(p,c.kit,t)==nil,"taken twice")
	local r=sp:challengeEnded(q,true,t+40)
	assert(r and paid[#paid].kind=="challenge" and paid[#paid].args.won==true and sp.challenge==nil and q:GetAttribute("NinjaSoloEnd")=="won","the challenge's end")
	-- the next one comes later, not at once
	sp:update(t+41)
	assert(sp.challenge==nil,"a challenger at once")
	-- nobody accepts: he leaves
	sp:update(t+41+Solo.Challenge.every+1)
	assert(sp.challenge~=nil,"no next challenger")
	sp:update(t+41+Solo.Challenge.every+2+Solo.Challenge.stay)
	assert(sp.challenge==nil,"the challenger never leaves")
end)

test("the village: the race's post and the targets with their prompts; a duel asked anywhere is fought near him",function()
	local holder=Instance.new("Folder");holder.Name="Masters";holder.Parent=village
	Hub.folder=village
	Hub.placeSolo(holder)
	local race=holder:FindFirstChild("RooftopRace")
	local targets=holder:FindFirstChild("KunaiTargets")
	assert(race and targets,"the places")
	local prompt=race:FindFirstChildWhichIsA("ProximityPrompt",true)
	assert(prompt and prompt:GetAttribute("NinjaSolo")=="race","the race's prompt")
	prompt=targets:FindFirstChildWhichIsA("ProximityPrompt",true)
	assert(prompt and prompt:GetAttribute("NinjaSolo")=="targets","the targets' prompt")
	for i in Solo.Targets.boards do
		local board=targets:FindFirstChild("Target"..i)
		assert(board,"board "..i)
		for _,p in board:GetDescendants() do if p:IsA("BasePart") then assert(not p.CanCollide,"a board in the walkers' way") end end
	end
	-- the duel anywhere
	local Matches=H.load("Server/Matches")
	local p=fakePlayer(31)
	local bodiesWas=Hub.bodies
	local street=HubMap.Streets[1]
	Hub.bodies={[p]=body(HubMap.Origin+street.at+Vector3.new(6,3,0))}
	local fake=setmetatable({sessions={},online=nil},Matches)
	local site=fake:nearSite(p,nil)
	Hub.bodies=bodiesWas
	assert(site and site.key==street.key and site.street,"not fought near him: "..tostring(site and site.key))
	Hub.bodies={}
	assert(fake:nearSite(p,nil)==nil,"a duel near a player who does not walk")
	Hub.bodies=bodiesWas
end)

-- (21/11, étape 3 DEV 5) The open 1v1: a ring round a duel in the village.
test("the open 1v1: a ring round a duel fought in the village, the passers-by set outside, taken down after",function()
	Hub.folder=village
	local street=HubMap.Streets[1]
	local origin=HubMap.Origin+street.at
	local moved=nil
	local root={Position=origin+Vector3.new(4,3,0)}
	local walker={character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end,PivotTo=function(_,cf) moved=cf end}}
	local bodiesWas=Hub.bodies
	Hub.bodies={[fakePlayer(41)]=walker}
	Hub.duelRings({{key=street.key,origin=origin,radius=street.radius}})
	local ring=village:FindFirstChild("DuelRing_"..street.key)
	assert(ring and #ring:GetChildren()>=Hub.RING_WALLS,"no ring")
	for _,p in ring:GetChildren() do
		local at=p.CFrame.Position
		assert((Vector3.new(at.X,0,at.Z)-Vector3.new(origin.X,0,origin.Z)).Magnitude>street.radius-2,"a piece inside the ring")
		if p.Name=="Wall" then assert(p.CanCollide and not p.CanQuery and p.Transparency==1,"the wall") end
	end
	assert(moved and (Vector3.new(moved.Position.X,0,moved.Position.Z)-Vector3.new(origin.X,0,origin.Z)).Magnitude>street.radius,"the walker left inside")
	Hub.duelRings({})
	assert(village:FindFirstChild("DuelRing_"..street.key)==nil,"the ring stays after the duel")
	Hub.bodies=bodiesWas
end)

-- (21/11, étape 3 DEV 6) The AI changes plan during a round.
test("the AI's plan: pressing first, a short turn at range or in wait, a beating changes it, the novice keeps one way",function()
	local AI=H.load("Server/AI")
	local actor={health=100,def={Health=100,PreferredRange=7}}
	local bot=AI.new({},actor,3,"normal")
	bot:strategyStep(0)
	assert(bot.strategy==nil,"a bot made on its own plans")
	bot:withStrategy();bot:strategyStep(0)
	assert(bot.strategy=="pressure" and actor.strategy=="pressure","not pressing first")
	assert(bot.tune.Aggression>bot.baseTune.Aggression and bot.tune.TechniqueGap<bot.baseTune.TechniqueGap,"pressing moves nothing")
	local turnAt=bot.strategyUntil
	assert(turnAt>=10 and turnAt<=15,"pressing held "..turnAt)
	bot:strategyStep(turnAt+.1)
	assert(bot.strategy=="distance" or bot.strategy=="trap","no turn after pressing: "..tostring(bot.strategy))
	local turn=bot.strategy
	assert(bot.strategyUntil-(turnAt+.1)<=4.5,"a turn held too long")
	if turn=="trap" then assert(bot.tune.Defense>bot.baseTune.Defense and bot.tune.Aggression<bot.baseTune.Aggression,"the trap") end
	-- a beating within the window: pressing again at once
	actor.health-=25
	bot:strategyStep(turnAt+1)
	assert(bot.strategy=="pressure","a beating did not change the plan")
	-- a long reach opens at range
	local zoner=AI.new({},{health=100,def={Health=100,PreferredRange=16}},4,"normal"):withStrategy()
	zoner:strategyStep(0)
	assert(zoner.strategy=="distance","a zoner opens pressing")
	-- the novice of the first combat: no plan
	local novice=AI.new({},{health=100,def={Health=100}},5,"first"):withStrategy()
	novice:strategyStep(0)
	assert(novice.strategy==nil and novice.tune==novice.baseTune,"the novice changes plans")
	-- the chances stay chances
	local hard=AI.new({},{health=100,def={Health=100}},6,"hard")
	for _,name in {"pressure","distance","trap"} do
		local t=AI.strategyTune(hard.baseTune,name)
		for _,k in {"Aggression","Defense","ReadGuard","ReadDodge"} do assert(t[k]>=0 and t[k]<=1,name.." "..k.." "..t[k]) end
	end
end)

print(string.format("NinjaDuel things to do alone (DEC-047): %d PASS",passed))
