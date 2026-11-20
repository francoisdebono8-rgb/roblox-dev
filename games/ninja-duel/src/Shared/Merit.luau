-- Merit (20/11, DEC-043, étape 1): what a player earns by winning and never
-- buys. Its first marks are three auras (the ANIMATEUR's VFX, clip names
-- `Aura.<id>`), worn in Konoha and in the duel, seen by everybody: « tu vois
-- peut-être du coup les auras des joueurs ».
--  * POINTS: a duel the profile counts and won: 1 against the AI, 3 against
--    a player (a player is the merit; the AI is the road there).
--  * TIERS: Ember at 25 points, Storm at 100, Legend at 300. A tier once
--    reached is kept.
-- Pure, shared: the profile's record `merit` (ProfileSchema, command
-- meritAdd), the player attribute NinjaAura (the tier's index, 0 for none:
-- Server/Progression), the view kits.merit for the DESIGN.
local M={}

M.AI=1
M.PLAYER=3
M.Tiers={
	{id="Ember",name="EMBER AURA",points=25},
	{id="Storm",name="STORM AURA",points=100},
	{id="Legend",name="LEGEND AURA",points=300},
}
M.MAX=100000000

function M.new() return {points=0,wins=0,pvpWins=0} end
-- The tier index (0: none yet) of `points`.
function M.tier(points)
	local out=0
	for i,t in M.Tiers do if points>=t.points then out=i end end
	return out
end
local function whole(n) return type(n)=="number" and n==math.floor(n) and n>=0 and n<=M.MAX end
function M.valid(r)
	if type(r)~="table" or not whole(r.points) or not whole(r.wins) or not whole(r.pvpWins) or r.pvpWins>r.wins then return false,"merit record" end
	return true
end
-- A won duel: `pvp` against a player. Returns {points, gained, tier, tierUp}.
function M.record(r,pvp)
	local before=M.tier(r.points)
	local gained=if pvp then M.PLAYER else M.AI
	r.points=math.min(M.MAX,r.points+gained)
	r.wins+=1
	if pvp then r.pvpWins+=1 end
	local tier=M.tier(r.points)
	return {points=r.points,gained=gained,tier=tier,tierUp=tier>before}
end
-- What the client shows: {points, tier (index), name, next={name,need}}.
function M.view(r)
	r=r or M.new()
	local tier=M.tier(r.points)
	local nextTier=M.Tiers[tier+1]
	return {points=r.points,wins=r.wins,pvpWins=r.pvpWins,tier=tier,name=if tier>0 then M.Tiers[tier].name else nil,
		next=if nextTier then {name=nextTier.name,need=nextTier.points-r.points} else nil}
end
-- The words when a tier is reached.
function M.line(result)
	if type(result)~="table" or not result.tierUp then return nil end
	local t=M.Tiers[result.tier]
	return t and string.format("%s UNLOCKED!",t.name) or nil
end

return M
