-- The player's record for the test with 3 to 5 real players (23/11, step 5,
-- DEC-049; the OUTILLEUR's reading page, tools/testread/CONTRAT.md). On the
-- test place only (workspace's NinjaTestPlace, Server/Reports): the published
-- game writes nothing.
--
-- One key per player and visit, `s_<UserId>_<arrival>`, in the DataStore
-- NinjaDuelReports (beside the reports, `r_…`), written every WRITE_EVERY
-- seconds and when he leaves:
--   screens   the seconds in each screen: the server's phase (Konoha, Duel,
--             Cup, Result), or the one the client names (action "Screen"
--             {name}: Shop, Tree, Settings… the DESIGN's screens)
--   funnel    the seconds from his arrival to each step (Matches.FUNNEL)
--   duels     played, won, lost, left before the end
--   quit      what he left before its end ({what, at}: duel, race…)
--   race      the rooftop race: runs finished, best time
local TestLog={}
TestLog.WRITE_EVERY=120
TestLog.TICK=1
TestLog.PHASE={Selection="Konoha",Duel="Duel",Result="Result",Bracket="Cup",Champion="Cup",Spectate="Cup"}
TestLog.MAX_QUIT=40

function TestLog.on()
	local ok,on=pcall(function() return workspace:GetAttribute("NinjaTestPlace") end)
	return ok and on==true
end

-- A visit begins (Matches:session).
function TestLog.open(s,nowTime,nowClock)
	s.log={joined=nowTime,clock=nowClock,screens={},duels={played=0,won=0,lost=0,left=0},quit={},race={runs=0}}
	return s.log
end

-- (pure) the screen of a session now: the client's, else the phase's.
function TestLog.screenOf(s)
	if type(s.clientScreen)=="string" then return s.clientScreen end
	return TestLog.PHASE[s.phase or ""] or tostring(s.phase or "Konoha")
end
-- `dt` seconds more in the screen he is on.
function TestLog.tick(s,dt)
	local log=s.log
	if not log then return end
	local name=TestLog.screenOf(s)
	log.screens[name]=(log.screens[name] or 0)+dt
end
-- The client names his screen (action "Screen" {name}): letters only, 16 at
-- most; empty, the server's phase again.
function TestLog.clientScreen(s,name)
	if name==nil or name=="" then s.clientScreen=nil;return true end
	if type(name)~="string" or #name>16 or not string.match(name,"^[%a]+$") then return false end
	s.clientScreen=name
	return true
end
-- A duel decided ("won" | "lost") or left before its end ("left").
function TestLog.duel(s,outcome,nowClock)
	local log=s.log
	if not log then return end
	if outcome=="left" then
		log.duels.left+=1
		TestLog.quit(s,"duel",nowClock)
	else
		log.duels.played+=1
		if outcome=="won" then log.duels.won+=1 elseif outcome=="lost" then log.duels.lost+=1 end
	end
end
function TestLog.quit(s,what,nowClock)
	local log=s.log
	if not log or #log.quit>=TestLog.MAX_QUIT then return end
	table.insert(log.quit,{what=what,at=math.floor((nowClock or os.clock())-log.clock)})
end
-- The rooftop race: a run finished in `time` s.
function TestLog.race(s,time)
	local log=s.log
	if not log or type(time)~="number" then return end
	log.race.runs+=1
	if not log.race.best or time<log.race.best then log.race.best=math.floor(time*100+.5)/100 end
end

-- (pure) the record as the reading page reads it.
function TestLog.record(player,s,nowTime,funnelSteps,build)
	local log=s.log
	local funnel={}
	local m=s.metrics or {}
	for step in funnelSteps or {} do
		local at=m[step.."At"]
		if at and m.joined then funnel[step]=math.floor(at-m.joined+.5) end
	end
	local screens={}
	for name,sec in log.screens do screens[name]=math.floor(sec+.5) end
	local okK,kit=pcall(function() return player:GetAttribute("NinjaKit") end)
	return {kind="session",userId=player.UserId,name=player.Name,joined=log.joined,left=nowTime,seconds=nowTime-log.joined,
		screens=screens,funnel=funnel,duels=table.clone(log.duels),quit=table.clone(log.quit),
		race={runs=log.race.runs,best=log.race.best},kit=okK and kit or nil,build=build}
end
function TestLog.key(player,s) return string.format("s_%d_%d",player.UserId,s.log.joined) end

-- The live side: every second the screens, every WRITE_EVERY s and when he
-- leaves the record, on the test place only.
function TestLog.write(player,s)
	if not (s and s.log and TestLog.on()) then return end
	local okF,Matches=pcall(require,script.Parent.Matches)
	local okC,commit=pcall(function() return game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel"):FindFirstChild("SourceCommit") end)
	local record=TestLog.record(player,s,os.time(),okF and Matches.FUNNEL or {},okC and commit and commit.Value or nil)
	local Reports=require(script.Parent.Reports)
	local store=Reports.dataStore()
	if store then
		local key=TestLog.key(player,s)
		task.spawn(pcall,function() store:SetAsync(key,record) end)
	end
end
function TestLog.start(matches)
	task.spawn(function()
		local sinceWrite=0
		while true do
			task.wait(TestLog.TICK)
			sinceWrite+=TestLog.TICK
			for _,s in matches.sessions do TestLog.tick(s,TestLog.TICK) end
			if sinceWrite>=TestLog.WRITE_EVERY then
				sinceWrite=0
				if TestLog.on() then for player,s in matches.sessions do TestLog.write(player,s) end end
			end
		end
	end)
end

return TestLog
