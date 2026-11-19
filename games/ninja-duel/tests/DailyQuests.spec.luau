-- Reasons to come back (19/11, plan « vague 2 », DEV 5): the day's three
-- quests in Ryō and the days in a row (Shared/DailyQuests), kept in the profile
-- (ProfileSchema `daily`, command dailyRecord), paid by the duels the profile
-- counts (Server/Progression), shown on the result screen (UI.dailyLine).
-- Headless; the DESIGN's panel in Konoha is a Studio check.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Daily=H.load("Shared/DailyQuests")
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")
local DAY=20776 -- 19/11/2026

test("three quests a day, one per tier, the same for everyone, and they change",function()
	local seen={}
	for d=DAY,DAY+20 do
		local q=Daily.today(d)
		assert(#q==3,"not three quests")
		for t=1,3 do
			assert(q[t].tier==t,"quest "..t.." is not of tier "..t)
			assert(Daily.Events[q[t].event],q[t].id.." counts an unknown event")
			assert(q[t].goal>=1 and q[t].ryo>0,q[t].id)
		end
		assert(Daily.today(d)[2].id==q[2].id,"not the same quests twice the same day")
		seen[q[1].id..q[2].id..q[3].id]=true
	end
	local n=0
	for _ in seen do n+=1 end
	assert(n>=5,"the days repeat the same three ("..n..")")
	-- a hard quest pays more than a medium, a medium than an easy
	assert(Daily.Tiers[3].ryo>Daily.Tiers[2].ryo and Daily.Tiers[2].ryo>Daily.Tiers[1].ryo)
end)

test("a quest fills, pays once when done, and a new day starts over",function()
	local r=Daily.new()
	local today=Daily.today(DAY)
	local easy=today[1]
	local events={}
	events[easy.event]=easy.goal-1
	local paid=Daily.record(r,DAY,events)
	if easy.goal>1 then
		assert(#paid.completed==0 or paid.completed[1].id~=easy.id,"done too early")
		assert(r.progress[easy.id]==easy.goal-1)
	end
	events[easy.event]=5
	paid=Daily.record(r,DAY,events)
	local found=false
	for _,c in paid.completed do if c.id==easy.id then found=true;assert(c.ryo==Daily.Tiers[1].ryo) end end
	assert(found or easy.goal==1,"the easy quest was not paid when done")
	assert(r.done[easy.id] and r.progress[easy.id]==easy.goal,"not done, or past its goal")
	-- done: never paid twice
	paid=Daily.record(r,DAY,events)
	for _,c in paid.completed do assert(c.id~=easy.id,"paid twice") end
	-- the next day: cleared
	Daily.record(r,DAY+1,{})
	assert(r.day==DAY+1 and next(r.done)==nil and next(r.progress)==nil,"the new day kept yesterday's quests")
	assert(Daily.valid(r),"the record is not valid")
end)

test("the days in a row: counted by the day's first duel, broken by a missed day, the seventh pays most",function()
	local r=Daily.new()
	local paid=Daily.record(r,DAY,{duel=1})
	assert(paid.streak and paid.streak.days==1 and paid.streak.ryo==Daily.Streak[1],"day 1")
	assert(Daily.record(r,DAY,{duel=1}).streak==nil,"the same day counted twice")
	assert(Daily.record(r,DAY,{win=1}).streak==nil)
	for d=2,7 do
		paid=Daily.record(r,DAY+d-1,{duel=1})
		assert(paid.streak.days==d and paid.streak.ryo==Daily.Streak[d],"day "..d)
	end
	assert(Daily.Streak[7]==math.max(table.unpack(Daily.Streak)),"the seventh day is not the best")
	paid=Daily.record(r,DAY+7,{duel=1})
	assert(paid.streak.days==8 and paid.streak.ryo==Daily.Streak[1],"the week does not start over")
	-- a lost duel still counts the day (no event but `duel`)
	local view=Daily.view(r,(DAY+8)*86400+100)
	assert(view.streak.days==8 and not view.streak.counted and view.streak.today==Daily.Streak[2],"tomorrow's view")
	-- a missed day: back to 1
	paid=Daily.record(r,DAY+10,{duel=1})
	assert(paid.streak.days==1,"a missed day kept the streak")
	assert(Daily.view(r,(DAY+13)*86400).streak.days==0,"an old streak still shows")
end)

test("the view: today's quests with their progress, the days in a row, the time left",function()
	local r=Daily.new()
	Daily.record(r,DAY,{duel=1,win=1,jutsu=2})
	local v=Daily.view(r,DAY*86400+3600)
	assert(#v.quests==3 and v.resetIn==86400-3600,"quests or time left")
	assert(v.streak.counted and v.streak.days==1 and v.streak.today==Daily.Streak[1] and v.streak.tomorrow==Daily.Streak[2])
	for _,q in v.quests do assert(q.text and q.goal and q.ryo and q.tier and q.progress>=0) end
	-- yesterday's record seen today: no progress
	local w=Daily.view(r,(DAY+1)*86400)
	for _,q in w.quests do assert(q.progress==0 and not q.done,"yesterday's progress shows today") end
	assert(w.streak.days==1 and not w.streak.counted and w.streak.today==Daily.Streak[2])
end)

test("the profile: dailyRecord pays into the wallet, the record is checked, a day past is refused",function()
	local p=S.new("dev_daily")
	assert(S.validate(p),"a profile without a daily record is not valid")
	local function run(kind,args)
		local np,result=S.apply(p,p.sequence+1,kind,args)
		p=np
		return result
	end
	local result=run("dailyRecord",{day=DAY,events={duel=1,win=1}})
	assert(result.streak and result.ryo>=Daily.Streak[1] and p.wallet.ryo==result.ryo and result.total==p.wallet.ryo,"not paid into the wallet")
	assert(S.validate(p))
	local ok=pcall(S.apply,p,p.sequence+1,"dailyRecord",{day=DAY-1,events={duel=1}})
	assert(not ok,"a day already past was accepted")
	ok=pcall(S.apply,p,p.sequence+1,"dailyRecord",{day=DAY,events={kills=3}})
	assert(not ok,"an unknown event was accepted")
	ok=pcall(S.apply,p,p.sequence+1,"dailyRecord",{day=DAY,events={win=1000}})
	assert(not ok,"a huge event was accepted")
	local bad=S.copy(p);bad.daily.progress.Nope=1
	assert(not S.validate(bad),"an unknown quest was kept")
	bad=S.copy(p);bad.daily.streak=-1
	assert(not S.validate(bad),"a negative streak was kept")
	-- an older server's profile (no record) migrates untouched
	local m=S.migrate(S.copy(S.new("dev_old3")))
	assert(m and m.daily==nil,"a v3 profile without the record")
end)

test("the duels the profile counts fill the quests; the result screen says what they paid",function()
	local getService=H.envBase.game.GetService
	local owners=0
	H.envBase.game.GetService=function(g,name)
		if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "server-"..owners end} end
		return getService(g,name)
	end
	local Progression=H.load("Server/Progression")
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	Progression.now=function() return DAY*86400+7200 end
	local player={UserId=712,Name="P712",DisplayName="P712",Parent=H.Players}
	assert(Progression.load(player),"the profile did not load")
	assert(Progression.chooseStarter(player,"Leaf"))
	local out=Progression.daily(player,nil,{duel=1,win=1,jutsu=3,flawless=1,nonsense=4})
	assert(out and out.daily and out.daily.streak and out.daily.streak.days==1,"the first duel did not count the day")
	local view=Progression.view(player)
	assert(view.daily and #view.daily.quests==3 and view.daily.streak.counted,"the view has no quests")
	assert(view.ryo==out.daily.total,"the wallet in the view")
	assert(view.exam and view.exam.enabled==true and view.exam.name,"the view has no exam")
	-- the result screen's words
	local line=Daily.line({ryo=85,streak={days=3,ryo=45},completed={{id="Win1",text="Win a duel",ryo=60}}})
	assert(line and string.find(line,"DAY 3 IN A ROW %+45") and string.find(line,"WIN A DUEL %+60"),"the line: "..tostring(line))
	assert(Daily.line(nil)==nil and Daily.line({ryo=0,completed={}})==nil)
	assert(Daily.line(out.daily),"no words for the first duel of the day")
	Config.Progression.Enabled=false
end)

print(string.format("NinjaDuel daily quests and days in a row (vague 2 DEV 5): %d PASS",passed))
