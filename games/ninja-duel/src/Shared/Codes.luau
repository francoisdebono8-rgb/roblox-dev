-- Codes (19/11, the CM's proposal « vague 2 » § 3, claude/cm-vague-2-2026-11-19:
-- « un code à chaque mise à jour publiée, un par cap atteint, un au début de
-- chaque événement »). A player types a code in the SHOP's BUY RYŌ page; the
-- server checks it (Server/ProfileSchema, command redeemCode): once per
-- player, between its dates, never power, never what is sold for Robux.
--
-- THE LIST IS THE CM'S (`Codes.List`, data only). One line per code:
--   code          capitals and figures, 16 at most; avoid O/0 and I/1
--   ryo           Ryō given (150: about three duels won; 300: a big one)
--   boostMinutes  or: mastery ×2 for this long (stacks after a running one)
--   item          or: a look of Shared/Catalog that is not sold for Robux
--   starts, ends  UTC days "YYYY-MM-DD", both included (starts: optional)
--   note          why it exists (the update, the cap, the event)
-- One reward per code. The CM's rule: three codes live at once at most.
-- The dates below wait for the update's publication date (François): the CM
-- sets them, 14 days for an update, 30 for a cap, the event's end for an
-- event's code.
local Exam=require(script.Parent.Exam)
local C={}

C.MaxLength=16
C.MaxRyo=1000
C.MaxMinutes=120
-- (23/11, step 5, DEC-049) The opening's codes. François gives the opening
-- day ("YYYY-MM-DD", UTC): until he does, C.Opening is nil and no code is
-- live. Three at once at most (the CM's rule), each with its dates:
--   NINJADUEL   300 Ryō, the 14 days of the opening (an update: 14 days)
--   JADECHAKRA  the JADE chakra colour, a market look (never a Robux one),
--               the same 14 days
--   EXAM1       150 Ryō, the weekend of the first Rank Exam (the first
--               Friday on or after the opening, to Sunday: 18:00 Friday -
--               21:00 Sunday in Paris falls inside those UTC days)
-- MYNINJA and FIRSTDUEL (19/11) were never published: the wardrobe update
-- opens with the game, and a code gives Ryō or a look, not time.
C.Opening=nil

-- The UTC day number (days since 1970-01-01) as "YYYY-MM-DD": the inverse
-- of Exam.daysFrom (civil calendar, proleptic Gregorian).
function C.date(n)
	local z=n+719468
	local era=(if z>=0 then z else z-146096)//146097
	local doe=z-era*146097
	local yoe=(doe-doe//1460+doe//36524-doe//146096)//365
	local y=yoe+era*400
	local doy=doe-(365*yoe+yoe//4-yoe//100)
	local mp=(5*doy+2)//153
	local d=doy-(153*mp+2)//5+1
	local m=if mp<10 then mp+3 else mp-9
	if m<=2 then y+=1 end
	return string.format("%04d-%02d-%02d",y,m,d)
end

-- The opening's list for an opening day.
function C.openingCodes(opening)
	local d0=C.day(opening)
	assert(d0,"opening day "..tostring(opening))
	local function at(k) return C.date(d0+k) end
	local weekday=(d0+4)%7 -- 1970-01-01 was a Thursday; 0 = Sunday
	local friday=(5-weekday)%7
	return {
		{code="NINJADUEL",ryo=300,starts=at(0),ends=at(13),note="The opening: 14 days"},
		{code="JADECHAKRA",item="ChakraJade",starts=at(0),ends=at(13),note="The opening: the jade chakra, a look of the market"},
		{code="EXAM1",ryo=150,starts=at(friday),ends=at(friday+2),note="The first Rank Exam: Friday 18:00 - Sunday 21:00, Paris"},
	}
end
C.List={} -- filled by C.open(C.Opening) below, once the day reader is there

-- What a player typed, as a code: capitals, no spaces; nil when it cannot be one.
function C.normalize(text)
	if type(text)~="string" or #text>40 then return nil end
	local code=string.upper((string.gsub(text,"%s","")))
	if #code<1 or #code>C.MaxLength or string.find(code,"[^A-Z0-9]") then return nil end
	return code
end
local function day(date)
	if type(date)~="string" then return nil end
	local y,m,d=string.match(date,"^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not y then return nil end
	y,m,d=tonumber(y),tonumber(m),tonumber(d)
	if m<1 or m>12 or d<1 or d>31 then return nil end
	return Exam.daysFrom(y,m,d)
end
C.day=day

C.ById={}
for _,def in C.List do C.ById[def.code]=def end
-- Set the opening day (the CM, when François gives it; the suite with a test day).
function C.open(opening)
	C.Opening=opening
	C.List=if opening then C.openingCodes(opening) else {}
	C.ById={}
	for _,def in C.List do C.ById[def.code]=def end
	return C.List
end
C.open(C.Opening)
function C.get(code) return C.ById[code] end

-- Is it live at UTC time t?
function C.active(def,t)
	local today=math.floor(t/86400)
	local from=if def.starts then day(def.starts) else nil
	local to=day(def.ends)
	if from and today<from then return false,"Code not open yet" end
	if not to or today>to then return false,"Code expired" end
	return true
end
-- The codes live at t.
function C.live(t)
	local out={}
	for _,def in C.List do if C.active(def,t) then table.insert(out,def.code) end end
	return out
end

-- A line of the list, checked (the suite runs it on every line). `item`
-- needs Shared/Shop to say what it is.
function C.check(def,Shop)
	if type(def)~="table" or C.normalize(def.code)~=def.code then return false,"code "..tostring(def and def.code) end
	local rewards=0
	if def.ryo~=nil then
		rewards+=1
		if type(def.ryo)~="number" or def.ryo<1 or def.ryo>C.MaxRyo or def.ryo~=math.floor(def.ryo) then return false,def.code..": ryo" end
	end
	if def.boostMinutes~=nil then
		rewards+=1
		if type(def.boostMinutes)~="number" or def.boostMinutes<1 or def.boostMinutes>C.MaxMinutes then return false,def.code..": boost" end
	end
	if def.item~=nil then
		rewards+=1
		local item=Shop and Shop.item(def.item)
		if not item or item.robux or item.base then return false,def.code..": item (unknown, sold for Robux, or free)" end
	end
	if rewards~=1 then return false,def.code..": one reward" end
	if not day(def.ends) then return false,def.code..": ends" end
	if def.starts~=nil and (not day(def.starts) or day(def.starts)>day(def.ends)) then return false,def.code..": starts" end
	return true
end

-- What the screen says once a code is accepted (result of redeemCode).
function C.thanks(result,Shop)
	if type(result)~="table" then return "CODE ACCEPTED" end
	if (result.ryo or 0)>0 then return string.format("CODE %s: +%d RYŌ",result.code,result.ryo) end
	if (result.minutes or 0)>0 then return string.format("CODE %s: MASTERY ×2 FOR %d MIN",result.code,result.minutes) end
	if result.item then
		local item=Shop and Shop.item(result.item)
		return string.format("CODE %s: %s IS YOURS",result.code,string.upper(item and item.name or result.item))
	end
	return "CODE ACCEPTED"
end

-- The profile's record: {used={[CODE]=day}, boostUntil (UTC seconds)}.
C.MaxUsed=200
function C.valid(r)
	if type(r)~="table" or type(r.used)~="table" then return false,"codes record" end
	if type(r.boostUntil)~="number" or r.boostUntil<0 or r.boostUntil~=math.floor(r.boostUntil) then return false,"codes boost" end
	local n=0
	for code,d in r.used do
		n+=1
		if type(code)~="string" or C.normalize(code)~=code then return false,"code used" end
		if type(d)~="number" or d<0 or d~=math.floor(d) then return false,"code day" end
	end
	if n>C.MaxUsed then return false,"too many codes" end
	return true
end

return C
