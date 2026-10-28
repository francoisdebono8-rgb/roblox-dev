-- Server (Debug build): a player agent (DEC-030, user 28/10 "test like a
-- human player"). It plays the human seat like a person on a pad: runs in,
-- strings lights, picks routes, jumps in, uses jutsu, dodges after being hit,
-- abuses whatever works. The AI bot plays the other seat. It records what a
-- player feels and returns a report:
--   moves (count, longest streak, share of the most used), hits per string,
--   airborne phases (duration / apex, and "flickers": < 0.3 s under 1 stud
--   while no jump was pressed), refused presses by reason, frozen states,
--   the bot's move repetition, rounds and time to KO.
-- Background: returns at once; shared.NdAgent.report when done (DURATION s).
local FIGHTER, OPPONENT, DURATION = "Lion", "Mirage", 75
local dev = game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev", 10)
local Fighters = require(game.ReplicatedStorage.NinjaDuel.Fighters)
local rng = Random.new(28)
local R = {moves = {}, botMoves = {}, seq = {}, botSeq = {}, strings = {}, airs = {}, flickers = {}, refused = {}, frozen = {}, kos = 0, log = {},
	infused = {}, botInfused = 0, loads = 0, airDashes = 0}
shared.NdAgent = R
local function note(t, s) table.insert(R.log, string.format("%.2f %s", t, s)) end

dev:Invoke("start", FIGHTER, OPPONENT)
local t0 = os.clock()
repeat task.wait(.2) local r = dev:Invoke("act", "human", "GuardOff") until (type(r) == "table" and r.reason ~= "Intro") or os.clock() - t0 > 12
dev:Invoke("autopilot", false)

local function now() return os.clock() - t0 end
local lastJumpAt = -10
local function act(a, aim)
	local s = dev:Invoke("state")
	local r = dev:Invoke("act", "human", a, aim or (s.bot and s.bot.position))
	if type(r) == "table" and r.ok == false and r.reason then
		local key = r.reason .. (if r.reason == "Committed" then "@" .. tostring(s.human and s.human.state) .. "/" .. a else "")
		R.refused[key] = (R.refused[key] or 0) + 1
	end
	if a == "Jump" then lastJumpAt = now() end
	return r
end
local function okAct(a) local r = act(a) return not (type(r) == "table" and r.ok == false) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

-- Observer: 30 Hz on both seats.
task.spawn(function()
	local lastA, lastB, airAt, apex, groundY, lastHits, stateSince, lastState, dead
	while R.done == nil do
		local s = dev:Invoke("state")
		local h, b = s.human, s.bot
		if h and b then
			local t = now()
			if h.attackName and h.attackName ~= lastA then
				R.moves[h.attackName] = (R.moves[h.attackName] or 0) + 1
				table.insert(R.seq, h.attackName)
				if h.infused then R.infused[h.attackName] = (R.infused[h.attackName] or 0) + 1 end
			end
			if b.attackName and b.attackName ~= lastB and b.infused then R.botInfused += 1 end
			lastA = h.attackName
			if b.attackName and b.attackName ~= lastB then
				R.botMoves[b.attackName] = (R.botMoves[b.attackName] or 0) + 1
				table.insert(R.botSeq, b.attackName)
			end
			lastB = b.attackName
			if not h.airborne then groundY = h.position.Y end
			if h.airborne and not airAt then airAt = t; apex = h.position.Y end
			if h.airborne then apex = math.max(apex, h.position.Y) end
			if not h.airborne and airAt then
				local dur, high = t - airAt, apex - (groundY or apex)
				table.insert(R.airs, {dur, high})
				if dur < .3 and high < 1 and t - lastJumpAt > .5 then table.insert(R.flickers, string.format("%.2f:%.2fs/%.2f", t, dur, high)) end
				airAt = nil
			end
			-- hits per string: the bot's combo counter as seen by the human (comboHits)
			if (h.comboHits or 0) < (lastHits or 0) then table.insert(R.strings, lastHits) end
			lastHits = h.comboHits or 0
			-- frozen: the same non-neutral state for > 2 s
			if h.state ~= lastState then lastState = h.state; stateSince = t end
			if h.state ~= "Neutral" and h.state ~= "Guarding" and h.state ~= "Defeated" and t - (stateSince or t) > 2 then
				table.insert(R.frozen, string.format("%.1f %s", t, h.state)); stateSince = t
			end
			local ko = (h.health or 1) <= 0 or (b.health or 1) <= 0
			if ko and not dead then R.kos += 1 end
			dead = ko
		end
		task.wait(1 / 30)
	end
end)

-- The player.
task.spawn(function()
	local def = Fighters[FIGHTER]
	local nextJutsu = 4
	while now() < DURATION do
		local s = dev:Invoke("state")
		local h, b = s.human, s.bot
		if not (h and b) or (h.health or 0) <= 0 or (b.health or 0) <= 0 then task.wait(.5); continue end
		local to = flat(b.position - h.position)
		local gap = to.Magnitude
		local dir = if gap > .1 then to.Unit else Vector3.zero
		local busy = h.state ~= "Neutral" and h.state ~= "Guarding" and h.state ~= "Recovery"
		if h.reaction then
			-- hit: a person mashes out or dodges once it is over
			if rng:NextNumber() < .3 then act("Dodge") end
			task.wait(.15)
		elseif gap > 12 and not h.airborne and rng:NextNumber() < .08 and (h.chakra or 0) > 40 then
			-- (Freedom) holds R1: loads chakra, then dashes in on it or leaps in
			if okAct("ChakraLoad") then R.loads += 1 end
			task.wait(.3)
			dev:Invoke("move", "human", dir)
			if rng:NextNumber() < .6 then act("Dodge"); task.wait(.35); act("Attack"); task.wait(.24); act("Attack")
			else act("Jump"); task.wait(.25)
				if (h.chakra or 0) > 30 and okAct("ChakraLoad") then R.loads += 1 end
				task.wait(.05); if okAct("Dodge") then R.airDashes += 1 end
				task.wait(.3); act("Attack"); task.wait(.24); act("Attack"); task.wait(.25); act("Heavy") end
		elseif gap > 9 then
			-- runs in (a pad player toggles sprint and holds the stick)
			dev:Invoke("sprint", "human", true); dev:Invoke("move", "human", dir)
			if gap < 14 and rng:NextNumber() < .35 then
				-- attacks out of the run (light or heavy), or jumps in
				local roll = rng:NextNumber()
				if roll < .5 then act("Attack"); task.wait(.24); act("Attack"); task.wait(.24); act("Attack") elseif roll < .7 then act("Heavy")
				else act("Jump"); task.wait(.18); act(if rng:NextNumber() < .5 then "Attack" else "Heavy"); task.wait(.25); act(if rng:NextNumber() < .6 then "Attack" else "Heavy") end
			end
			task.wait(.12)
		else
			dev:Invoke("sprint", "human", false)
			dev:Invoke("move", "human", if gap > 4 then dir else Vector3.zero)
			if now() > nextJutsu and rng:NextNumber() < .5 then
				nextJutsu = now() + 4 + rng:NextNumber() * 4
				act("Technique" .. rng:NextInteger(1, math.min(#(def.Techniques or {}), 4)))
				task.wait(.6)
			elseif not busy then
				-- a string: 2-3 lights, sometimes a route on the third press, sometimes heavy
				local n = rng:NextInteger(2, 3)
				for i = 1, n do
					if i == 3 and rng:NextNumber() < .4 then
						dev:Invoke("move", "human", if rng:NextNumber() < .5 then dir else -dir)
					end
					act("Attack"); task.wait(.24)
				end
				dev:Invoke("move", "human", Vector3.zero)
				if rng:NextNumber() < .35 then
					-- a loaded heavy now and then (hold R1, then triangle)
					if rng:NextNumber() < .3 and (h.chakra or 0) > 30 and okAct("ChakraLoad") then R.loads += 1; task.wait(.3) end
					act("Heavy"); task.wait(.3)
				end
				if rng:NextNumber() < .25 then act("Jump"); task.wait(.15); act("Attack"); task.wait(.25); act("Attack"); task.wait(.25); act("Heavy") end
				task.wait(.2)
			else
				task.wait(.08)
			end
		end
	end
	dev:Invoke("move", "human", Vector3.zero); dev:Invoke("sprint", "human", false)
	R.done = true
	-- Report.
	local function top(t)
		local best, n, total = nil, 0, 0
		for k, v in t do total += v; if v > n then best, n = k, v end end
		return best, n, total
	end
	local function streak(seq)
		local best, cur, name = 0, 0, nil
		for i, m in seq do
			if i > 1 and seq[i - 1] == m then cur += 1 else cur = 1 end
			if cur > best then best, name = cur, m end
		end
		return best, name
	end
	local function list(t)
		local o = {}
		for k, v in t do table.insert(o, k .. "=" .. v) end
		table.sort(o)
		return table.concat(o, " ")
	end
	local m, mn, mt = top(R.moves)
	local bm, bn, bt = top(R.botMoves)
	local st, sn = streak(R.seq)
	local bst, bsn = streak(R.botSeq)
	local airs = {}
	for _, a in R.airs do if a[2] > 1 then table.insert(airs, string.format("%.2f/%.1f", a[1], a[2])) end end
	R.report = table.concat({
		string.format("player %s vs %s, %ds, KOs %d", FIGHTER, OPPONENT, DURATION, R.kos),
		string.format("player moves (%d): %s", mt, list(R.moves)),
		string.format("  most used %s %d%%, longest streak %d x %s", tostring(m), mt > 0 and math.floor(mn / mt * 100) or 0, st, tostring(sn)),
		string.format("bot moves (%d): %s", bt, list(R.botMoves)),
		string.format("  most used %s %d%%, longest streak %d x %s", tostring(bm), bt > 0 and math.floor(bn / bt * 100) or 0, bst, tostring(bsn)),
		"strings landed on the bot (hits): " .. table.concat(R.strings, " "),
		"jumps (s/apex): " .. table.concat(airs, " "),
		"airborne flickers (no jump): " .. #R.flickers .. " " .. table.concat(R.flickers, " "),
		"refused presses: " .. list(R.refused),
		string.format("chakra loads %d, air dashes %d, infused player strikes: %s, bot infused strikes %d", R.loads, R.airDashes, list(R.infused), R.botInfused),
		"frozen > 2 s: " .. table.concat(R.frozen, " "),
	}, "\n")
end)
return "agent playing " .. FIGHTER .. " vs " .. OPPONENT
