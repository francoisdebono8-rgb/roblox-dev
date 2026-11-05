-- Adapted from Velmora src/server/Combat/CombatAntiCheat.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
local Tune=require(game:GetService('ReplicatedStorage').NinjaDuel.VelmoraCombatConfig)
local AntiCheat={}
local last={}
-- (Audit v34 #4) A key let go is never refused: a dropped GuardOff left the
-- guard up for the rest of the round, a dropped JumpOff kept the glide on.
local RELEASE={GuardOff=true,JumpOff=true,SealRelease=true}
-- A press a little late (a ping spike) is kept and judged at the oldest time
-- the fight accepts, instead of vanishing; only a really old or future one goes.
AntiCheat.LateLimit=.6
AntiCheat.EarlyLimit=.1
-- Returns ok and, when the press stamp had to be moved back into the window,
-- the stamp to judge it with.
function AntiCheat.check(actor,action,clientTime,now)
	if type(action)~='string' then return false end
	if RELEASE[action] then return true end
	local stamp=nil
	if clientTime~=nil then
		if type(clientTime)~='number' or clientTime~=clientTime then return false end
		local delta=now-clientTime
		if delta<-AntiCheat.EarlyLimit or delta>AntiCheat.LateLimit then return false end
		if delta<0 then stamp=now
		elseif delta>Tune.History+Tune.TimestampWindow then stamp=now-(Tune.History+Tune.TimestampWindow) end
	end
	-- The flood gap is measured on the client's own press clock when there is
	-- one: packets bunched by the network arrive together but were pressed apart.
	local clock=if type(clientTime)=='number' then clientTime else now
	local bucket=last[actor]
	if not bucket then bucket={};last[actor]=bucket end
	local family=if string.match(action,'^Technique') or string.match(action,'^Seal%d') then 'Technique' else action
	local gap=Tune.Rates[family] or .04
	if bucket[family] and math.abs(clock-bucket[family])<gap then return false end
	bucket[family]=clock
	return true,stamp
end
function AntiCheat.clear(actor) last[actor]=nil end
return AntiCheat
