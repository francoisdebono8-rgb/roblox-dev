-- Adapted from Velmora src/server/Combat/CombatAntiCheat.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
local Tune=require(game:GetService('ReplicatedStorage').NinjaDuel.VelmoraCombatConfig)
local AntiCheat={}
local last={}
function AntiCheat.check(actor,action,clientTime,now)
	if type(action)~='string' then return false end
	if clientTime~=nil then
		if type(clientTime)~='number' or clientTime~=clientTime then return false end
		local delta=now-clientTime
		if delta<-.05 or delta>Tune.History+Tune.TimestampWindow then return false end
	end
	local clock=os.clock();local bucket=last[actor]
	if not bucket then bucket={};last[actor]=bucket end
	local family=if string.match(action,'^Technique') then 'Technique' else action
	local gap=Tune.Rates[family] or .04
	if bucket[family] and clock-bucket[family]<gap then return false end
	bucket[family]=clock
	return true
end
function AntiCheat.clear(actor) last[actor]=nil end
return AntiCheat
