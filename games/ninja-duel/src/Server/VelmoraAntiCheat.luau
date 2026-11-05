-- Adapted from Velmora src/server/Combat/CombatAntiCheat.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
local Tune=require(game:GetService('ReplicatedStorage').NinjaDuel.VelmoraCombatConfig)
local AntiCheat={}
local last={}
function AntiCheat.check(actor,action,clientTime,now)
	if type(action)~='string' then return false end
	local late=false
	if clientTime~=nil then
		if type(clientTime)~='number' or clientTime~=clientTime then return false end
		local delta=now-clientTime
		if delta<-.05 then return false end
		-- (FEEL 05/11, AVANT defect 3) A press older than the history window
		-- used to be dropped without a word: a hitch or a ping spike ate the
		-- dodge (Studio: 402 ms after a 379 ms frame). Its time only dates the
		-- commit (Combat.attackCommitTime), it grants nothing; up to LateAccept
		-- the press counts as late (the caller drops its time), past it it is
		-- too old to mean anything.
		if delta>Tune.History+Tune.TimestampWindow then
			if delta>(Tune.LateAccept or 0) then return false end
			late=true
		end
	end
	local clock=os.clock();local bucket=last[actor]
	if not bucket then bucket={};last[actor]=bucket end
	local family=if string.match(action,'^Technique') or string.match(action,'^Seal%d') then 'Technique' else action
	local gap=Tune.Rates[family] or .04
	if bucket[family] and clock-bucket[family]<gap then return false end
	bucket[family]=clock
	return true,late
end
function AntiCheat.clear(actor) last[actor]=nil end
return AntiCheat
