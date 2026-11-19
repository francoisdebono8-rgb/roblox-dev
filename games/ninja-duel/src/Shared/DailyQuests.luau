-- The daily quests (DailyQuests: the name says Quest, for the OUTILLEUR's
-- loop robot). Reasons to come back tomorrow (19/11, plan « vague 2 », DEV 5; the CM's
-- market study: every big game of the genre has daily quests in its own
-- currency and a reward that grows with the days in a row).
--  * THREE QUESTS A DAY, paid in Ryō the moment one is done (no claim
--    button): one easy, one medium, one hard, the same three for everyone
--    that day (people can talk about « today's quests »).
--  * THE DAYS IN A ROW: the first counted duel of a day counts the day; a
--    missed day starts again at 1. Its Ryō grows over a week, the seventh day
--    pays the most, then the week starts over.
-- A day is a UTC day (00:00 UTC, 01:00 in Paris in winter), like the day's
-- first win (Shared/Shop.Ryo.FirstWinOfDay).
-- Pure rules, shared: the server keeps the record in the profile
-- (Server/ProfileSchema `daily`, command dailyRecord), the DESIGN reads the
-- view the client gets (Progression.view `daily`: Daily.view).
-- What counts: a duel the profile counts (the kit is learned; not practice,
-- not a watched match), against the AI, in the tournament or against a
-- player. Events, from Server/Progression:
--   duel      a counted duel finished (won or lost)
--   win       a counted duel won
--   jutsu     techniques used in it
--   flawless  won without losing a round
--   cup       a match of the tournament won
local D={}

D.DAY=86400
function D.day(t) return math.floor(t/D.DAY) end
-- Seconds until the next day starts.
function D.resetIn(t) return D.DAY-(t%D.DAY) end

D.Events={duel=true,win=true,jutsu=true,flawless=true,cup=true}
-- One quest of each tier a day. `ryo`: what the tier pays.
D.Tiers={
	{name="EASY",ryo=60,quests={
		{id="Duels2",text="Finish 2 duels",event="duel",goal=2},
		{id="Jutsu5",text="Use 5 jutsu in your duels",event="jutsu",goal=5},
		{id="Win1",text="Win a duel",event="win",goal=1},
	}},
	{name="MEDIUM",ryo=90,quests={
		{id="Win3",text="Win 3 duels",event="win",goal=3},
		{id="Flawless1",text="Win a duel without losing a round",event="flawless",goal=1},
		{id="Cup1",text="Win a match in the tournament",event="cup",goal=1},
	}},
	{name="HARD",ryo=150,quests={
		{id="Win6",text="Win 6 duels",event="win",goal=6},
		{id="Cup2",text="Win 2 matches in the tournament",event="cup",goal=2},
		{id="Jutsu20",text="Use 20 jutsu in your duels",event="jutsu",goal=20},
	}},
}
D.ById={}
for t,tier in D.Tiers do
	for _,q in tier.quests do D.ById[q.id]={id=q.id,text=q.text,event=q.event,goal=q.goal,tier=t,tierName=tier.name,ryo=tier.ryo} end
end
-- The days in a row: day n of a streak pays Streak[(n-1)%7+1].
D.Streak={25,35,45,55,65,80,150}
function D.streakRyo(n)
	if type(n)~="number" or n<1 then return 0 end
	return D.Streak[((math.floor(n)-1)%#D.Streak)+1]
end
D.MaxStreak=100000

-- The three quests of day `day`: each tier turns every day, the second and
-- third a little out of step (the same three come back together every 27
-- days).
function D.today(day)
	local out={}
	for t,tier in D.Tiers do
		local n=#tier.quests
		local q=tier.quests[((day+math.floor(day/n^(t-1)))%n)+1]
		table.insert(out,D.ById[q.id])
	end
	return out
end

function D.new() return {day=0,progress={},done={},streak=0,streakDay=0} end

local function whole(n,max) return type(n)=="number" and n==math.floor(n) and n>=0 and n<=(max or 2^31) end
-- The profile's record, checked on every load and commit.
function D.valid(r)
	if type(r)~="table" or type(r.progress)~="table" or type(r.done)~="table" then return false,"daily record" end
	if not whole(r.day) or not whole(r.streakDay) or not whole(r.streak,D.MaxStreak) then return false,"daily days" end
	for id,n in r.progress do
		local q=D.ById[id]
		if not q or not whole(n,q.goal) then return false,"daily progress "..tostring(id) end
	end
	for id,flag in r.done do if flag~=true or not D.ById[id] then return false,"daily done "..tostring(id) end end
	return true
end

-- The days in a row as of `day`: a streak whose last day is older than
-- yesterday is broken (0).
function D.streakOf(r,day)
	if not r or not whole(r.streak) or r.streak<1 then return 0 end
	if r.streakDay==day or r.streakDay==day-1 then return r.streak end
	return 0
end

-- One counted duel's events on day `day` (a new day clears the quests).
-- Changes `r`; returns what it paid: {ryo, completed={{id,text,ryo}},
-- streak={days,ryo} or nil}.
function D.record(r,day,events)
	local out={ryo=0,completed={}}
	if r.day~=day then r.day=day;r.progress={};r.done={} end
	if (events.duel or 0)>0 and r.streakDay~=day then
		r.streak=math.min(D.MaxStreak,if r.streakDay==day-1 then r.streak+1 else 1)
		r.streakDay=day
		local ryo=D.streakRyo(r.streak)
		out.streak={days=r.streak,ryo=ryo}
		out.ryo+=ryo
	end
	for _,q in D.today(day) do
		local add=events[q.event] or 0
		if not r.done[q.id] and add>0 then
			local n=math.min(q.goal,(r.progress[q.id] or 0)+add)
			r.progress[q.id]=n
			if n>=q.goal then
				r.done[q.id]=true
				table.insert(out.completed,{id=q.id,text=q.text,ryo=q.ryo})
				out.ryo+=q.ryo
			end
		end
	end
	return out
end

-- What the client shows (the DESIGN's panel in Konoha, the result screen):
-- {day, resetIn, quests={{id,text,tier,goal,progress,done,ryo}},
--  streak={days, counted (today already counted), today (what today pays,
--  or paid), tomorrow (what the next day pays)}}.
function D.view(r,now)
	local day=D.day(now)
	r=r or D.new()
	local same=r.day==day
	local out={day=day,resetIn=D.resetIn(now),quests={}}
	for _,q in D.today(day) do
		table.insert(out.quests,{id=q.id,text=q.text,tier=q.tierName,goal=q.goal,ryo=q.ryo,
			progress=if same then r.progress[q.id] or 0 else 0,done=same and r.done[q.id]==true})
	end
	local days=D.streakOf(r,day)
	local counted=r.streakDay==day
	-- not counted yet: today's first duel makes it days+1
	local today=if counted then days else days+1
	out.streak={days=days,counted=counted,today=D.streakRyo(today),tomorrow=D.streakRyo(today+1)}
	return out
end

-- The result screen's words for what a duel's events paid (out.daily:
-- {ryo, completed, streak}), or nil.
function D.line(paid)
	if type(paid)~="table" then return nil end
	local parts={}
	if type(paid.streak)=="table" and (paid.streak.ryo or 0)>0 then
		table.insert(parts,string.format("DAY %d IN A ROW +%d RYŌ.",paid.streak.days or 1,paid.streak.ryo))
	end
	for _,q in paid.completed or {} do
		table.insert(parts,string.format("DAILY QUEST DONE: %s +%d RYŌ.",string.upper(q.text or ""),q.ryo or 0))
	end
	return if #parts>0 then table.concat(parts,"  ") else nil
end

return D
