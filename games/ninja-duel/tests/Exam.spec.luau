-- The exam of the week (19/11, plan « vague 2 », DEV 5; the CM's rules,
-- claude/cm-vague-2-2026-11-19 § 3): the window in Paris time (summer and
-- winter), the score of an attempt, the titles, the profile's record, the
-- server side on fake stores (Server/WeeklyExam: attempts, the leaderboard,
-- the week closed once for every server, the cliff's three places).
-- Headless; the titles over the heads and the cliff are Studio checks.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Exam=H.load("Shared/Exam")
local S=H.load("Server/ProfileSchema")
local HOUR=3600
local function utc(y,m,d,h,mi) return Exam.daysFrom(y,m,d)*86400+(h or 0)*HOUR+(mi or 0)*60 end

test("the calendar: civil dates, weekdays, Paris summer and winter time",function()
	assert(Exam.daysFrom(1970,1,1)==0 and Exam.daysFrom(2026,11,19)==20776)
	for _,z in {0,59,60,365,11016,20776,20777,30000} do
		local y,m,d=Exam.civil(z)
		assert(Exam.daysFrom(y,m,d)==z,"round trip "..z)
	end
	assert(Exam.weekday(Exam.daysFrom(2026,11,20))==5,"20/11/2026 is a Friday")
	assert(Exam.key(Exam.daysFrom(2026,11,20))=="2026-11-20")
	assert(Exam.lastSunday(2026,3)==Exam.daysFrom(2026,3,29) and Exam.lastSunday(2026,10)==Exam.daysFrom(2026,10,25))
	assert(Exam.parisOffset(utc(2026,11,20,12))==HOUR,"November is winter time")
	assert(Exam.parisOffset(utc(2026,6,19,12))==2*HOUR,"June is summer time")
	assert(Exam.parisOffset(utc(2026,3,29,0,59))==HOUR and Exam.parisOffset(utc(2026,3,29,1))==2*HOUR,"the March change at 01:00 UTC")
	assert(Exam.parisOffset(utc(2026,10,25,0,59))==2*HOUR and Exam.parisOffset(utc(2026,10,25,1))==HOUR,"the October change")
end)

test("the window: Friday 18:00 to Sunday 21:00 in Paris, in winter and in summer",function()
	-- winter: 17:00 to 20:00 UTC
	local w=Exam.openAt(utc(2026,11,20,17,0))
	assert(w and w.key=="2026-11-20" and w.opens==utc(2026,11,20,17) and w.closes==utc(2026,11,22,20),"the 20/11 window")
	assert(Exam.openAt(utc(2026,11,20,16,59))==nil,"open before 18:00 Paris")
	assert(Exam.openAt(utc(2026,11,22,19,59)),"closed before 21:00 Paris on Sunday")
	assert(Exam.openAt(utc(2026,11,22,20,0))==nil,"open after 21:00 Paris")
	assert(Exam.openAt(utc(2026,11,21,3)),"closed on Saturday night")
	assert(Exam.openAt(utc(2026,11,24,12))==nil,"open on a Tuesday")
	-- summer: 16:00 to 19:00 UTC
	local s=Exam.openAt(utc(2026,6,19,16,0))
	assert(s and s.key=="2026-06-19" and s.closes==utc(2026,6,21,19),"the summer window")
	assert(Exam.openAt(utc(2026,6,19,15,59))==nil)
	-- current (open or next), latest (open or last), last closed
	local thursday=utc(2026,11,19,22)
	assert(Exam.current(thursday).key=="2026-11-20" and Exam.latest(thursday).key=="2026-11-13" and Exam.lastClosed(thursday).key=="2026-11-13")
	local saturday=utc(2026,11,21,12)
	assert(Exam.current(saturday).key=="2026-11-20" and Exam.latest(saturday).key=="2026-11-20" and Exam.lastClosed(saturday).key=="2026-11-13")
	local monday=utc(2026,11,23,9)
	assert(Exam.current(monday).key=="2026-11-27" and Exam.latest(monday).key=="2026-11-20" and Exam.lastClosed(monday).key=="2026-11-20")
	-- Sunday after the close, before midnight in Paris
	local late=utc(2026,11,22,21)
	assert(Exam.current(late).key=="2026-11-27" and Exam.lastClosed(late).key=="2026-11-20")
end)

test("the score: matches won first, then rounds lost, then health kept, then time",function()
	local champion=Exam.score({matches=3,lost=2,hp=120,seconds=400})
	assert(champion>Exam.score({matches=2,lost=0,hp=200,seconds=100}),"more matches won loses")
	assert(Exam.score({matches=3,lost=1,hp=10,seconds=900})>champion,"fewer rounds lost loses")
	assert(Exam.score({matches=3,lost=2,hp=150,seconds=900})>champion,"more health kept loses")
	assert(Exam.score({matches=3,lost=2,hp=120,seconds=200})>champion,"faster loses")
	local p=Exam.parts(champion)
	assert(p.matches==3 and p.lost==2 and p.hp==120 and p.seconds==400,"parts")
	assert(Exam.score({matches=9,lost=-3,hp=999,seconds=-5})==Exam.score({matches=3,lost=0,hp=300,seconds=0}),"bounds")
	assert(Exam.score({})>=0)
end)

test("the titles: TOP 3 of the last closed exam, EXAM PASSED until the next one opens",function()
	local saturday=utc(2026,11,21,12)
	local mine={week="2026-11-20",best=100,passed=true}
	assert(Exam.title(mine,{},7,saturday)==Exam.PASSED,"passed this week")
	assert(Exam.title(mine,{},7,utc(2026,11,25,12))==Exam.PASSED,"passed: kept until the next opens")
	assert(Exam.title(mine,{},7,utc(2026,11,27,17,30))==nil,"passed: kept after the next opened")
	assert(Exam.title({week="2026-11-20",best=100,passed=false},{},7,saturday)==nil,"not passed")
	assert(Exam.title(nil,{{id=9},{id=7}},7,saturday)==Exam.TOP,"top 3")
	assert(Exam.title(mine,{{id=1},{id=2},{id=3},{id=7}},7,saturday)==Exam.PASSED,"fourth is not top 3")
	local v=Exam.view(mine,saturday)
	assert(v.enabled and v.open and v.key=="2026-11-20" and v.best==100 and v.passed and v["in"]==utc(2026,11,22,20)-saturday,"the view")
	local w=Exam.view(mine,utc(2026,11,24,12))
	assert(not w.open and w.key=="2026-11-27" and w.best==0 and not w.passed,"the view between two exams")
end)

test("the profile: the week's best kept, a new week starts over, a past week refused",function()
	local p=S.new("dev_exam")
	local function run(kind,args) local np,r=S.apply(p,p.sequence+1,kind,args);p=np;return r end
	local r=run("examResult",{week="2026-11-20",score=500,passed=false})
	assert(r.improved and r.best==500 and not r.passed)
	r=run("examResult",{week="2026-11-20",score=300,passed=true})
	assert(not r.improved and r.best==500 and r.passed,"a worse attempt lowered the best, or the final won was lost")
	r=run("examResult",{week="2026-11-27",score=100,passed=false})
	assert(r.improved and r.best==100 and not r.passed and p.exam.week=="2026-11-27","a new week")
	assert(not pcall(S.apply,p,p.sequence+1,"examResult",{week="2026-11-20",score=900}),"a past week was accepted")
	assert(not pcall(S.apply,p,p.sequence+1,"examResult",{week="2026-11-27",score=-1}),"a negative score")
	local bad=S.copy(p);bad.exam.best=1.5
	assert(not S.validate(bad))
	assert(S.validate(p))
end)

-- ------------------------------------------------------------ the server, on fakes
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end
local function fakeOrdered()
	local data={}
	return {data=data,
		UpdateAsync=function(_,key,fn) data[key]=fn(data[key]) end,
		GetSortedAsync=function(_,asc,size)
			local rows={}
			for k,v in data do table.insert(rows,{key=k,value=v}) end
			table.sort(rows,function(a,b) if asc then return a.value<b.value end return a.value>b.value end)
			local page={}
			for i=1,math.min(size,#rows) do page[i]=rows[i] end
			return {GetCurrentPage=function() return page end}
		end}
end
local function fakeStore()
	local data={}
	return {data=data,GetAsync=function(_,k) return data[k] end,UpdateAsync=function(_,k,fn) local v=fn(data[k]);if v~=nil then data[k]=v end end}
end

test("the server: an attempt only while open, its score kept as the week's best, the leaderboard",function()
	local W=H.load("Server/WeeklyExam")
	local now=utc(2026,11,21,12)
	local boards={}
	local records={}
	local P={examResult=function(player,week,score,passed)
		local r=records[player.UserId]
		if not r or r.week~=week then r={week=week,best=0,passed=false};records[player.UserId]=r end
		local improved=score>r.best
		if improved then r.best=score end
		r.passed=r.passed or passed
		return {week=week,best=r.best,improved=improved,passed=r.passed}
	end,examRecord=function(player) return records[player.UserId] end}
	local player=fakePlayer(41)
	local svc={now=function() return now end,ordered=function(key) boards[key]=boards[key] or fakeOrdered();return boards[key] end,
		store=fakeStore(),name=function(id) return "N"..id end,players=function() return {player} end,forced=function() return false end,
		progression=function() return P end,cliff=function() end,spawn=function(fn,...) fn(...) end}
	local w=W.new(svc)
	local a=w:attempt()
	assert(a and a.key=="2026-11-20","no attempt while open")
	W.match(a,true,1,.8,120);W.match(a,true,0,.5,90);W.match(a,true,1,1,150)
	assert(a.matches==3 and a.lost==2 and a.hp==230 and a.seconds==360)
	local result=w:submit(player,a,true)
	assert(result.passed and result.improved and result.best==Exam.score(a),"the champion's attempt")
	assert(boards["2026-11-20"].data["41"]==result.score,"not on the leaderboard")
	assert(player:GetAttribute("NinjaTitle")==Exam.PASSED,"no title")
	assert(w:submit(player,a,true)==nil,"an attempt sent twice")
	-- a worse attempt: kept out of the leaderboard
	local b=w:attempt();W.match(b,false,2,0,60)
	local r2=w:submit(player,b,false)
	assert(not r2.improved and r2.best==result.score and boards["2026-11-20"].data["41"]==result.score)
	-- closed: no attempt (Studio can open it)
	now=utc(2026,11,24,12)
	assert(w:attempt()==nil,"an attempt on a Tuesday")
	svc.forced=function() return true end
	local f=w:attempt()
	assert(f and f.key=="2026-11-27","Studio's forced exam")
end)

test("the week closed: the three best read once, written for every server, carved on the cliff",function()
	local W=H.load("Server/WeeklyExam")
	local Cliff=H.load("Server/ChampionCliff")
	local now=utc(2026,11,23,9)
	local board=fakeOrdered()
	board.data["11"]=Exam.score({matches=3,lost=0,hp=250,seconds=300})
	board.data["12"]=Exam.score({matches=3,lost=1,hp=100,seconds=300})
	board.data["13"]=Exam.score({matches=2,lost=1,hp=100,seconds=300})
	board.data["14"]=Exam.score({matches=1,lost=2,hp=10,seconds=300})
	local store=fakeStore()
	local carved=nil
	local players={fakePlayer(11),fakePlayer(14)}
	local P={examRecord=function() return nil end}
	local reads=0
	local svc={now=function() return now end,ordered=function(key) reads+=1;assert(key=="2026-11-20","the wrong week "..key);return board end,
		store=store,name=function(id) return "N"..id end,players=function() return players end,progression=function() return P end,
		cliff=function(top) carved=top end,spawn=function(fn,...) fn(...) end}
	local w=W.new(svc)
	w:close()
	assert(#w.top==3 and w.top[1].id==11 and w.top[2].id==12 and w.top[3].id==13,"the three best")
	assert(store.data.week_v1 and store.data.week_v1.week=="2026-11-20","not written for the other servers")
	assert(carved and carved[1].id==11,"not carved")
	assert(players[1]:GetAttribute("NinjaTitle")==Exam.TOP and players[2]:GetAttribute("NinjaTitle")==nil,"the titles")
	w:close()
	assert(reads==1,"read twice the same week")
	-- another server: reads week_v1, not the leaderboard
	local carved2=nil
	local svc2=table.clone(svc);svc2.ordered=function() error("read the leaderboard again") end;svc2.cliff=function(top) carved2=top end
	local w2=W.new(svc2)
	w2:close()
	assert(#w2.top==3 and w2.top[1].id==11 and carved2==nil,"the other server")
	-- nobody the next week: the titles go, the cliff keeps its faces
	now=utc(2026,11,30,9)
	local empty=fakeOrdered()
	local carved3=nil
	local svc3=table.clone(svc);svc3.ordered=function() return empty end;svc3.cliff=function(top) carved3=top end
	local w3=W.new(svc3)
	w3:close()
	assert(#w3.top==0 and carved3==nil and store.data.week_v1.week=="2026-11-27","an empty week")
	assert(players[1]:GetAttribute("NinjaTitle")==nil,"the TOP 3 title outlived the next exam")
	-- the cliff's places: ranked, the number 1 first
	local entries=Cliff.weekEntries({{id=11,name="N11"},{id=12,name="N12"},{id=13,name="N13"},{id=14,name="N14"}},5)
	assert(#entries==3 and entries[1].rank==1 and entries[3].rank==3 and entries[1].id==11)
	assert(Cliff.clean(entries)[2].rank==2,"the rank is not kept")
	assert(Cliff.label("n11",1)=="NO 1 OF THE WEEK  N11" and Cliff.label("n9",nil)=="CHAMPION N9")
	assert(Cliff.plan(1,entries)[2]==11,"the number 1 is not in the first champion's place")
end)

print(string.format("NinjaDuel exam of the week (vague 2 DEV 5): %d PASS",passed))
