-- The ladder, merit and the leaderboards (20/11, DEC-043, étape 1 « Ça se
-- voit, et on se compare »): the rating and its six ranks (Shared/Ranked),
-- merit and its auras (Shared/Merit), kept in the profile, moved by every
-- duel between two players (Progression.rankedDuel), seen by everybody
-- (NinjaRank, NinjaRating, NinjaAura), and the boards' top 10 (Server/
-- Leaderboards). Headless; the emblems and the auras are Studio checks.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Ranked=H.load("Shared/Ranked")
local Merit=H.load("Shared/Merit")
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")

test("the rating: everybody at 1000, a win gains what the loser loses, an upset gains more",function()
	assert(Ranked.START==1000 and Ranked.rank(1000).name=="ACADEMY")
	local even=Ranked.after(1000,1000,true,0)
	assert(even==1024,"a first even win: "..even)
	assert(Ranked.after(1000,1000,false,0)==976,"a first even loss")
	assert(Ranked.after(1000,1000,true,20)==1016,"an even win after the first ten")
	local upset=Ranked.after(1000,1400,true,20)-1000
	local expected=Ranked.after(1400,1000,true,20)-1400
	assert(upset>20 and expected>=1 and expected<10,"upset "..upset..", expected "..expected)
	assert(Ranked.after(0,2000,false,30)==0,"below 0")
	assert(math.abs(Ranked.expected(1200,1000)+Ranked.expected(1000,1200)-1)<1e-9)
end)

test("six ranks read at a glance, in order, each with its emblem and the next one's distance",function()
	local names={}
	for i,r in Ranked.Ranks do
		table.insert(names,r.name)
		if i>1 then assert(r.from>Ranked.Ranks[i-1].from,"ranks out of order") end
		assert(type(r.emblem)=="string")
	end
	assert(table.concat(names," ")=="ACADEMY GENIN CHUNIN JONIN ANBU KAGE",table.concat(names," "))
	assert(Ranked.rank(1099).name=="ACADEMY" and Ranked.rank(1100).name=="GENIN" and Ranked.rank(2500).name=="KAGE")
	local v=Ranked.view({rating=1080,games=3,wins=3,peak=1080})
	assert(v.rank.name=="ACADEMY" and v.next.name=="GENIN" and v.next.need==20,"the view")
	assert(Ranked.view({rating=2100,games=90,wins=70,peak=2150}).next==nil,"KAGE has a next rank")
	local r=Ranked.new()
	local result
	for _=1,5 do result=Ranked.record(r,1000,true) end
	assert(result.rankUp and result.rank.name=="GENIN","five even wins from 1000: "..r.rating)
	assert(string.find(Ranked.line(result),"NEW RANK: GENIN"),Ranked.line(result))
	assert(Ranked.valid(r) and not Ranked.valid({rating=1000,games=1,wins=2,peak=1000}))
end)

test("merit: 1 point a win against the AI, 3 against a player; three auras kept once reached",function()
	local m=Merit.new()
	for _=1,24 do Merit.record(m,false) end
	assert(Merit.tier(m.points)==0)
	local r=Merit.record(m,false)
	assert(r.tierUp and r.tier==1 and string.find(Merit.line(r),"EMBER AURA"),"the first aura at 25")
	r=Merit.record(m,true)
	assert(r.gained==3 and m.pvpWins==1 and not r.tierUp)
	assert(Merit.view(m).next.name=="STORM AURA" and Merit.view(m).next.need==100-28)
	assert(Merit.valid(m) and not Merit.valid({points=1,wins=1,pvpWins=2}))
end)

test("the profile keeps both: rankedResult and meritAdd, checked",function()
	local p=S.new("dev_ranked")
	assert(S.validate(p),"a profile without them")
	local function run(kind,args) local np,r=S.apply(p,p.sequence+1,kind,args);p=np;return r end
	local r=run("rankedResult",{opponent=1000,won=true})
	assert(r.after==1024 and p.ranked.games==1 and p.ranked.wins==1)
	r=run("meritAdd",{pvp=true})
	assert(r.points==3 and p.merit.pvpWins==1)
	assert(S.validate(p))
	assert(not pcall(S.apply,p,p.sequence+1,"rankedResult",{opponent=-5,won=true}),"a negative rating")
	assert(not pcall(S.apply,p,p.sequence+1,"rankedResult",{opponent=1000,won="yes"}),"a result that is not a boolean")
	local bad=S.copy(p);bad.ranked.rating=1.5
	assert(not S.validate(bad))
end)

-- Progression on a memory store, with players that carry attributes.
local getService=H.envBase.game.GetService
local owners=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "server-"..owners end} end
	return getService(g,name)
end
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end

test("a duel between two players moves both ratings; everybody sees the rank; a player not loaded is skipped",function()
	local Progression=H.load("Server/Progression")
	local L=H.load("Server/Leaderboards")
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local a,b,c=fakePlayer(901),fakePlayer(902),fakePlayer(903)
	assert(Progression.load(a) and Progression.load(b),"profiles")
	assert(a:GetAttribute("NinjaRank")=="ACADEMY" and a:GetAttribute("NinjaRating")==1000 and a:GetAttribute("NinjaAura")==0,"badges at load")
	-- the boards, on this server only
	local published={}
	L.current=L.new({ordered=function() return nil end,now=function() return 1795200000 end,name=function(id) return "N"..id end,
		publish=function(id,json) published[id]=json end,encode=function(t) return t end,spawn=function(fn,...) fn(...) end})
	local out=Progression.rankedDuel(a,b)
	assert(out[a].after==1024 and out[b].after==976,"the ratings")
	assert(a:GetAttribute("NinjaRating")==1024 and b:GetAttribute("NinjaRating")==976)
	local duels=1
	while a:GetAttribute("NinjaRating")<1100 and duels<12 do Progression.rankedDuel(a,b);duels+=1 end
	assert(a:GetAttribute("NinjaRank")=="GENIN","rank over the head: "..tostring(a:GetAttribute("NinjaRank")))
	assert(Progression.view(a).ranked.rank.name=="GENIN","the view")
	-- a player whose profile is not loaded: skipped, the other still moves
	local r=Progression.rankedDuel(a,c)
	assert(r[a] and r[c]==nil,"a player not loaded")
	-- merit: a won duel against a player
	local d=Progression.daily(a,nil,{duel=1,win=1,pvp=true})
	assert(d.merit and d.merit.gained==3,"merit against a player")
	d=Progression.daily(b,nil,{duel=1,win=1})
	assert(d.merit and d.merit.gained==1,"merit against the AI")
	-- the boards
	L.current:refresh()
	local rating=published.Rating
	assert(rating and rating.rows[1].id==901 and rating.rows[1].value==a:GetAttribute("NinjaRating") and rating.rows[2].id==902,"the ranked board")
	assert(published.WeekWins.rows[1].id==901 and published.WeekWins.rows[1].value==duels+1,"wins this week: "..tostring(published.WeekWins.rows[1] and published.WeekWins.rows[1].value))
	assert(published.Merit.rows[1].value==3 and published.Streak and published.Exam,"merit, streak and exam boards")
	L.current=nil
	Config.Progression.Enabled=false
end)

test("the boards: weekly keys, the store's top 10, nothing written by a test player",function()
	local L=H.load("Server/Leaderboards")
	local Exam=H.load("Shared/Exam")
	-- 20/11/2026 is a Friday: its week starts Monday 16/11
	local friday=Exam.daysFrom(2026,11,20)*86400+3600
	assert(L.weekKey(friday)=="2026-11-16" and L.weekKey(Exam.daysFrom(2026,11,16)*86400)=="2026-11-16" and L.weekKey(Exam.daysFrom(2026,11,22)*86400+80000)=="2026-11-16")
	assert(L.storeName(L.ById.WeekWins,friday)=="NinjaDuelWeekWins_2026-11-16" and L.storeName(L.ById.Rating,friday)=="NinjaDuelRating")
	local stores={}
	local function ordered(name)
		stores[name]=stores[name] or {data={},SetAsync=function(self,k,v) self.data[k]=v end,UpdateAsync=function(self,k,fn) self.data[k]=fn(self.data[k]) end,
			GetSortedAsync=function(self,asc,n)
				local rows={}
				for k,v in self.data do table.insert(rows,{key=k,value=v}) end
				table.sort(rows,function(x,y) return x.value>y.value end)
				local page={}
				for i=1,math.min(n,#rows) do page[i]=rows[i] end
				return {GetCurrentPage=function() return page end}
			end}
		return stores[name]
	end
	local l=L.new({ordered=ordered,now=function() return friday end,name=function(id) return "N"..id end,publish=function() end,encode=function(t) return t end,spawn=function(fn,...) fn(...) end})
	for i=1,14 do l:submit("Rating",fakePlayer(100+i),1000+i*10) end
	l:submit("Rating",fakePlayer(-1),5000)
	l:submit("Exam",fakePlayer(7),99)
	local top=l:top("Rating")
	assert(#top.rows==10 and top.rows[1].id==114 and top.rows[1].rank==1 and top.rows[10].id==105,"the top 10")
	for _,row in top.rows do assert(row.id>0,"a test player on the board") end
	assert(stores["NinjaDuelExam_"..Exam.latest(friday).key]==nil or next(stores["NinjaDuelExam_"..Exam.latest(friday).key].data)==nil,"the exam board written by the boards")
end)

print(string.format("NinjaDuel the ladder, merit and the boards (DEC-043): %d PASS",passed))
