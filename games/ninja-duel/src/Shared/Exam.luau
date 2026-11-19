-- The exam of the week (19/11, plan « vague 2 », DEV 5; the CM's proposal,
-- claude/cm-vague-2-2026-11-19 § 3): the prodigies' tournament (Server/
-- Tournament) played during a weekly window counts for the week.
--  * WHEN: from Friday 18:00 to Sunday 21:00, Paris time (summer and winter
--    time both: the European rule, last Sunday of March and of October).
--  * SCORE of an attempt (a tournament started while the window is open):
--    matches won first, then rounds lost (fewer is better), then the health
--    kept in the matches won, then the time spent in his own duels (less is
--    better). Only the week's best counts.
--  * TITLES, over his head in Konoha (player attribute NinjaTitle):
--      EXAM PASSED        he won the final during the latest exam, until the
--                         next one opens;
--      TOP 3 OF THE WEEK  among the three best of the last exam closed,
--                         until the next one closes.
--  * THE CLIFF: the last exam's three best take places 2 to 4 on Konoha's
--    cliff (the number 1 first), for the week after (Server/ChampionCliff).
-- Its name and hours are Config.Exam (THE RANK EXAM while the names of the
-- work are not decided; THE CHUNIN EXAM if they are kept: CM § 1).
-- Pure: the calendar and the rules. The server side is Server/WeeklyExam.
local Config=require(script.Parent.Config)
local E={}

E.DAY=86400
E.HOUR=3600
function E.config()
	local c=Config.Exam or {}
	return {Enabled=c.Enabled~=false,Name=c.Name or "THE RANK EXAM",OpenDay=c.OpenDay or 5,OpenHour=c.OpenHour or 18,
		CloseDay=c.CloseDay or 0,CloseHour=c.CloseHour or 21}
end
E.PASSED="EXAM PASSED"
E.TOP="TOP 3 OF THE WEEK"
E.TOP_COUNT=3

-- ------------------------------------------------------------ the calendar
-- Days since 1970-01-01 of a civil date, and back (H. Hinnant's algorithms;
-- no os.time(table), whose time zone differs between Lua and Roblox).
function E.daysFrom(y,m,d)
	y-=if m<=2 then 1 else 0
	local era=math.floor(y/400)
	local yoe=y-era*400
	local mp=(m+9)%12
	local doy=math.floor((153*mp+2)/5)+d-1
	local doe=yoe*365+math.floor(yoe/4)-math.floor(yoe/100)+doy
	return era*146097+doe-719468
end
function E.civil(z)
	z+=719468
	local era=math.floor(z/146097)
	local doe=z-era*146097
	local yoe=math.floor((doe-math.floor(doe/1460)+math.floor(doe/36524)-math.floor(doe/146096))/365)
	local doy=doe-(365*yoe+math.floor(yoe/4)-math.floor(yoe/100))
	local mp=math.floor((5*doy+2)/153)
	local d=doy-math.floor((153*mp+2)/5)+1
	local m=if mp<10 then mp+3 else mp-9
	return yoe+era*400+(if m<=2 then 1 else 0),m,d
end
-- 0 = Sunday … 6 = Saturday (1970-01-01 was a Thursday).
function E.weekday(z) return (z+4)%7 end
function E.lastSunday(y,m)
	local last=if m==12 then E.daysFrom(y+1,1,1)-1 else E.daysFrom(y,m+1,1)-1
	return last-E.weekday(last)
end
-- Paris's offset from UTC at UTC time t, in seconds (CET +1 h, CEST +2 h:
-- from the last Sunday of March to the last Sunday of October, at 01:00 UTC).
function E.parisOffset(t)
	local y=E.civil(math.floor(t/E.DAY))
	local from=E.lastSunday(y,3)*E.DAY+E.HOUR
	local to=E.lastSunday(y,10)*E.DAY+E.HOUR
	return if t>=from and t<to then 2*E.HOUR else E.HOUR
end
-- A Paris wall-clock time (seconds since 1970 as if Paris were UTC) to UTC.
-- (Never called near the 02:00/03:00 changes: the exam's hours are evenings.)
function E.fromParis(wall) return wall-E.parisOffset(wall-E.HOUR) end
function E.key(z) local y,m,d=E.civil(z) return string.format("%04d-%02d-%02d",y,m,d) end

-- The window of the week whose opening day (Paris) is `day`: {key, opens,
-- closes} in UTC seconds.
function E.windowOf(day,c)
	c=c or E.config()
	local span=(c.CloseDay-c.OpenDay)%7
	return {key=E.key(day),day=day,opens=E.fromParis(day*E.DAY+c.OpenHour*E.HOUR),closes=E.fromParis((day+span)*E.DAY+c.CloseHour*E.HOUR)}
end
-- The window opened on the latest opening day at or before t (Paris).
local function anchor(t,c)
	local today=math.floor((t+E.parisOffset(t))/E.DAY)
	return today-((E.weekday(today)-c.OpenDay)%7)
end
-- The window open at t, or nil.
function E.openAt(t,c)
	c=c or E.config()
	local w=E.windowOf(anchor(t,c),c)
	if t>=w.opens and t<w.closes then return w end
	return nil
end
-- The open window, else the next one.
function E.current(t,c)
	c=c or E.config()
	local w=E.windowOf(anchor(t,c),c)
	if t<w.closes then return w end
	return E.windowOf(w.day+7,c)
end
-- The latest window already opened (open now, or the last one).
function E.latest(t,c)
	c=c or E.config()
	local w=E.windowOf(anchor(t,c),c)
	if t>=w.opens then return w end
	return E.windowOf(w.day-7,c)
end
-- The latest window already closed.
function E.lastClosed(t,c)
	c=c or E.config()
	local w=E.windowOf(anchor(t,c),c)
	if t>=w.closes then return w end
	return E.windowOf(w.day-7,c)
end

-- ------------------------------------------------------------ the score
-- An attempt: {matches (won, 0..3), lost (rounds lost), hp (sum of the
-- health kept in the matches won, in %), seconds (in his own duels)}.
-- One whole number, higher is better, for an OrderedDataStore.
function E.score(a)
	local matches=math.clamp(math.floor(a.matches or 0),0,3)
	local lost=math.clamp(math.floor(a.lost or 0),0,9)
	local hp=math.clamp(math.floor(a.hp or 0),0,300)
	local slow=math.clamp(math.floor((a.seconds or 0)/2),0,999)
	return matches*10000000+(9-lost)*1000000+hp*1000+(999-slow)
end
-- Back to the parts, for the screens (matches, lost, hp; time in 2 s steps).
function E.parts(score)
	return {matches=math.floor(score/10000000),lost=9-math.floor(score/1000000)%10,hp=math.floor(score/1000)%1000,seconds=(999-score%1000)*2}
end

-- ------------------------------------------------------------ the titles
-- The profile's record: {week (a window's key), best (score), passed}.
function E.valid(r)
	if type(r)~="table" or type(r.week)~="string" or #r.week~=10 then return false,"exam week" end
	if type(r.best)~="number" or r.best<0 or r.best~=math.floor(r.best) or r.best>99999999 then return false,"exam best" end
	if type(r.passed)~="boolean" then return false,"exam passed" end
	return true
end
-- His title at t: `record` his profile's, `top` the last closed exam's best
-- ({{id,...}}, the number 1 first), `userId` his.
function E.title(record,top,userId,t,c)
	c=c or E.config()
	if not c.Enabled then return nil end
	for i=1,math.min(E.TOP_COUNT,#(top or {})) do
		if top[i].id==userId then return E.TOP end
	end
	local latest=E.latest(t,c)
	if record and record.passed and record.week==latest.key then return E.PASSED end
	return nil
end

-- What the client shows (the DESIGN's banner in Konoha, the champion card):
-- {name, open, opens, closes (UTC seconds of the open or next window), in
-- (seconds until it opens or closes), best, passed (this week)}.
function E.view(record,t,c)
	c=c or E.config()
	if not c.Enabled then return {enabled=false} end
	local w=E.current(t,c)
	local open=t>=w.opens
	local mine=record and record.week==w.key
	return {enabled=true,name=c.Name,key=w.key,open=open,opens=w.opens,closes=w.closes,
		["in"]=if open then w.closes-t else w.opens-t,best=if mine and open then record.best else 0,passed=mine and record.passed==true}
end

return E
