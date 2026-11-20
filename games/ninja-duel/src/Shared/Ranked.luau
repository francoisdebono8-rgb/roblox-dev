-- The ranked ladder (20/11, DEC-043, étape 1 « Ça se voit, et on se
-- compare »; François: « Roblox c'est beaucoup se comparer aux autres »).
--  * EVERY DUEL BETWEEN TWO PLAYERS COUNTS, in a street of Konoha or
--    elsewhere: no ranked queue that would stay empty with few players. A
--    duel against the AI never moves the rating.
--  * THE RATING: Elo, everybody starts at 1000. A duel moves it by K × (result
--    − expected), K larger for the first duels so a new player finds his
--    place fast. Never below 0.
--  * SIX RANKS read at a glance (the headband's emblem, over the head and in
--    the duel's HUD: the DESIGN draws them, `emblem` names the colour):
--    ACADEMY, GENIN, CHUNIN, JONIN, ANBU, KAGE.
-- Pure, shared: the server keeps the record in the profile (ProfileSchema
-- `ranked`, command rankedResult); the DESIGN reads Ranked.view (kits.ranked)
-- and the players' attributes NinjaRank / NinjaRating (Server/Progression).
local R={}

R.START=1000
R.K_NEW=48      -- the first R.NEW duels
R.K=32
R.NEW=10
R.MAX=4000
R.Ranks={
	{id="Academy",name="ACADEMY",from=0,emblem="wood"},
	{id="Genin",name="GENIN",from=1100,emblem="iron"},
	{id="Chunin",name="CHUNIN",from=1250,emblem="bronze"},
	{id="Jonin",name="JONIN",from=1450,emblem="silver"},
	{id="Anbu",name="ANBU",from=1700,emblem="gold"},
	{id="Kage",name="KAGE",from=2000,emblem="crimson"},
}

function R.new() return {rating=R.START,games=0,wins=0,peak=R.START} end

-- The rank of a rating: {id,name,from,emblem,index}.
function R.rank(rating)
	local out,index=R.Ranks[1],1
	for i,r in R.Ranks do if rating>=r.from then out,index=r,i end end
	return {id=out.id,name=out.name,from=out.from,emblem=out.emblem,index=index}
end
-- What a player expects to score against another (0 to 1).
function R.expected(mine,theirs) return 1/(1+10^((theirs-mine)/400)) end
-- The new rating after one duel: `games` played before it.
function R.after(mine,theirs,won,games)
	local k=if (games or 0)<R.NEW then R.K_NEW else R.K
	local delta=math.round(k*((if won then 1 else 0)-R.expected(mine,theirs)))
	-- a win always gains, a loss always costs (at least a point)
	if won then delta=math.max(1,delta) else delta=math.min(-1,delta) end
	return math.clamp(mine+delta,0,R.MAX)
end

local function whole(n,max) return type(n)=="number" and n==math.floor(n) and n>=0 and n<=max end
function R.valid(r)
	if type(r)~="table" then return false,"ranked record" end
	if not whole(r.rating,R.MAX) or not whole(r.peak,R.MAX) then return false,"ranked rating" end
	if not whole(r.games,10000000) or not whole(r.wins,10000000) or r.wins>r.games then return false,"ranked games" end
	return true
end
-- Applies one duel to the record; returns {before, after, delta, rank,
-- rankUp (a new rank reached), rankDown}.
function R.record(r,theirs,won)
	local before=r.rating
	local beforeRank=R.rank(before)
	r.rating=R.after(before,theirs,won,r.games)
	r.games+=1
	if won then r.wins+=1 end
	r.peak=math.max(r.peak,r.rating)
	local rank=R.rank(r.rating)
	return {before=before,after=r.rating,delta=r.rating-before,rank=rank,rankUp=rank.index>beforeRank.index,rankDown=rank.index<beforeRank.index}
end

-- What the client shows: {rating, rank, next={name,need} or nil, games,
-- wins, peak}.
function R.view(r)
	r=r or R.new()
	local rank=R.rank(r.rating)
	local nextRank=R.Ranks[rank.index+1]
	return {rating=r.rating,rank=rank,games=r.games,wins=r.wins,peak=r.peak,
		next=if nextRank then {name=nextRank.name,need=nextRank.from-r.rating} else nil}
end

-- The result screen's words for a ranked duel ({before,after,delta,rank,rankUp}).
function R.line(result)
	if type(result)~="table" or type(result.rank)~="table" then return nil end
	local sign=if (result.delta or 0)>=0 then "+" else ""
	local text=string.format("RANKED: %s %d (%s%d).",result.rank.name,result.after or 0,sign,result.delta or 0)
	if result.rankUp then text=string.format("NEW RANK: %s! %d (%s%d).",result.rank.name,result.after or 0,sign,result.delta or 0) end
	return text
end

return R
