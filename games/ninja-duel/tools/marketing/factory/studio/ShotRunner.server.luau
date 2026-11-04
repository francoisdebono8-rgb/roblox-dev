--!nocheck
-- Ninja Duel content factory: server side (Server datamodel of ND-Clips2, in
-- Play, with workspace attribute NinjaDuelDebug = true). Paste into execute_luau.
--
-- Every take starts with a SYNC FLASH: the scene goes white for ~0.15 s. The
-- factory finds that frame in the screen recording, so every logged event
-- (hits, KO, moves) lands on the exact video frame without guessing.
--
--   _G.NDShot.duel(a, b, {maxT=60, noUlt=true})     AI vs AI, runs async
--   _G.NDShot.showcase(id, {dummy="Leaf"})          one fighter's moveset on a frozen dummy, async
--   _G.NDShot.result()                              "running" or the JSON log of the last take
--
-- Log (JSON): {kind, a, b, build={place, features}, flash={now}, events=[{t, kind, by, amount, tag, name}], winner, ko}
-- All times are in the combat clock (workspace:GetServerTimeNow()).
local Lighting = game:GetService("Lighting")
local Http = game:GetService("HttpService")
local dev = game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev")
local S = {}
_G.NDShot = S
local busy, last = false, nil
local function now() return workspace:GetServerTimeNow() end
local RS = game:GetService("ReplicatedStorage")
local function rsmod(name)
	for _, d in ipairs(RS:GetDescendants()) do if d:IsA("ModuleScript") and d.Name == name then return d end end
end
-- Which build filmed this take: the factory refuses a take without the
-- features the videos must show (config.json "required_features").
function S.build()
	local f = {}
	for _, n in ipairs({"SealJutsu", "BetaRoster", "ChakraFlow"}) do if rsmod(n) then table.insert(f, n) end end
	return {place = game.Name, features = f}
end
-- Duels are one round in clips (Matches reads Config.RoundsToWin at start).
local function rounds(n)
	local m = rsmod("Config"); if not m then return end
	pcall(function() require(m).RoundsToWin = n end)
end

function S.flash()
	local e0, b0 = Lighting.ExposureCompensation, Lighting.Brightness
	local t = now()
	Lighting.ExposureCompensation = 6; Lighting.Brightness = 10
	task.wait(0.15)
	Lighting.ExposureCompensation = e0; Lighting.Brightness = b0
	return t
end

local noUlt = false
task.spawn(function()
	while true do
		if noUlt then pcall(function() dev:Invoke("ultimate", "human", 0); dev:Invoke("ultimate", "bot", 0) end) end
		task.wait(0.2)
	end
end)

local function start(a, b, training)
	dev:Invoke("autopilot", false)
	local ok = dev:Invoke("start", a, b, training == true)
	task.wait(0.3)
	return ok
end
local function phase() local s = dev:Invoke("state"); return type(s) == "table" and s.phase or tostring(s), s end
local function waitDuel(maxT)
	local t0 = os.clock()
	while os.clock() - t0 < (maxT or 10) do
		if phase() == "Duel" then return true end
		task.wait(0.1)
	end
end

-- AI vs AI duel: fighter a on the human seat (autopilot), b is the bot.
function S.duel(a, b, opts)
	if busy then return "busy" end
	opts = opts or {}
	busy, last = true, nil
	task.spawn(function()
		local log = {kind = "duel", a = a, b = b, events = {}, build = S.build()}
		local ok, err = pcall(function()
			noUlt = opts.noUlt ~= false
			rounds(opts.rounds or 1)
			start(a, b, false)
			waitDuel(10)
			dev:Invoke("damagelog", true) -- clear and start logging
			task.wait(opts.lead or 1.0)    -- let the recording settle
			log.flash = {now = S.flash()}
			dev:Invoke("autopilot", true)
			local t0 = os.clock()
			local winner
			while os.clock() - t0 < (opts.maxT or 60) do
				local ph, s = phase()
				if ph == "Result" then
					log.ko = now()
					local hh = s.human and s.human.health or 0
					winner = (hh > 0) and a or b
					break
				end
				task.wait(0.05)
			end
			log.winner = winner or "none"
			for _, d in ipairs(dev:Invoke("damagelog") or {}) do
				table.insert(log.events, {t = d.t, kind = "hit", by = d.by, amount = d.amount, tag = d.tag, hits = d.hits})
			end
			if log.ko then table.insert(log.events, {t = log.ko, kind = "ko", by = winner}) end
		end)
		noUlt = false
		if not ok then log.error = tostring(err) end
		last = log; busy = false
	end)
	return "running"
end

-- Moveset showcase: the fighter runs its kit on a frozen dummy, one move every
-- `gap` seconds, each move logged with its name (for the on-screen caption).
-- Since v29 the kit goes on past the four slots: the HAND SEALS (Seals, then
-- two jutsu keys) call the jutsu of the fighter's story; opts.seals = false
-- leaves them out, a number keeps only the first n.
S.STEPS = {
	{action = "Attack", name = "COMBO", repeat_ = 4, every = 0.32, dur = 1.9},
	{action = "Heavy", name = "HEAVY", dur = 1.6},
	{action = "Technique1", dur = 2.4, chakra = true},
	{action = "Technique2", dur = 2.4, chakra = true},
	{action = "Technique3", dur = 2.4, chakra = true},
	{action = "Technique4", dur = 2.4, chakra = true},
}
function S.showcase(id, opts)
	if busy then return "busy" end
	opts = opts or {}
	busy, last = true, nil
	task.spawn(function()
		local log = {kind = "showcase", a = id, b = opts.dummy or "Leaf", events = {}, build = S.build()}
		local ok, err = pcall(function()
			local mod
			for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
				if d:IsA("ModuleScript") and d.Name == "Fighters" then mod = d; break end
			end
			local Fighters = mod and require(mod) or {}
			local def = Fighters[id] or {}
			log.title = def.Title; log.fullName = def.FullName
			local techs = def.Techniques or {}
			local steps = table.clone(opts.steps or S.STEPS)
			local sj = rsmod("SealJutsu")
			local SJ = sj and require(sj) or {}
			if opts.seals ~= false then
				for k, spec in ipairs(SJ[id] or {}) do
					if type(opts.seals) == "number" and k > opts.seals then break end
					local nm = SJ.Names or {}
					table.insert(steps, {action = "Seals", seq = spec.Signs, name = string.upper(spec.Name or spec.Id),
						signs = (nm[spec.Signs[1]] or "?") .. " · " .. (nm[spec.Signs[2]] or "?"), dur = 2.6})
				end
			end
			start(id, log.b, true)
			waitDuel(10)
			dev:Invoke("freezeBot", true)
			dev:Invoke("scripted", true)
			dev:Invoke("place", Vector3.new(0, 3, 5), Vector3.new(0, 3, -2))
			dev:Invoke("refill")
			dev:Invoke("damagelog", true)
			task.wait(opts.lead or 1.0)
			log.flash = {now = S.flash()}
			task.wait(0.6)
			for i, step in ipairs(steps) do
				dev:Invoke("refill")
				dev:Invoke("place", Vector3.new(0, 3, 5), Vector3.new(0, 3, -2))
				task.wait(0.25)
				local name = step.name
				local n = tonumber(step.action:match("Technique(%d)"))
				if n and techs[n] then name = string.upper(techs[n].Name or techs[n].Id or step.action) end
				table.insert(log.events, {t = now(), kind = "move", name = name, action = step.action, signs = step.signs,
					keys = step.seq and ("C + " .. step.seq[1] .. "-" .. step.seq[2]) or nil})
				if step.seq then
					-- the weave: open, then the two seals (the jutsu goes on the second)
					local r0 = dev:Invoke("act", "human", "Seals")
					task.wait(0.32)
					dev:Invoke("act", "human", "Technique" .. step.seq[1])
					task.wait(0.32)
					local r2 = dev:Invoke("act", "human", "Technique" .. step.seq[2])
					local ev = log.events[#log.events]
					ev.ok = type(r2) == "table" and r2.ok or false
					ev.why = (type(r2) == "table" and r2.reason) or (type(r0) == "table" and r0.reason) or nil
				else
					for r = 1, (step.repeat_ or 1) do
						dev:Invoke("act", "human", step.action, nil, step.chakra and {chakra = true} or nil)
						if step.every then task.wait(step.every) end
					end
				end
				task.wait(step.dur or 2)
			end
			table.insert(log.events, {t = now(), kind = "end"})
			for _, d in ipairs(dev:Invoke("damagelog") or {}) do
				table.insert(log.events, {t = d.t, kind = "hit", by = d.by, amount = d.amount, tag = d.tag, hits = d.hits})
			end
			dev:Invoke("scripted", false)
			dev:Invoke("freezeBot", false)
		end)
		if not ok then log.error = tostring(err) end
		last = log; busy = false
	end)
	return "running"
end

-- Full 8-fighter tournament in ONE take ("pick your ninja" format): the seven
-- matches back to back, one sync flash at the start. Each match logs its start,
-- every hit and its KO, so the edit can cut combo + KO for each match.
S.BRACKET = {"Legion", "GentleFist", "Leaf", "Sand", "Lion", "Copycat", "Mirage", "Flashstep"}
function S.tournament(entrants, opts)
	if busy then return "busy" end
	opts = opts or {}
	busy, last = true, nil
	task.spawn(function()
		local E = entrants or S.BRACKET
		local log = {kind = "tournament", entrants = E, events = {}, results = {}, build = S.build()}
		local ok, err = pcall(function()
			noUlt = opts.noUlt ~= false
			rounds(opts.rounds or 1)
			local function match(a, b, stage, key)
				start(a, b, false); waitDuel(10)
				dev:Invoke("damagelog", true)
				task.wait(0.4)
				table.insert(log.events, {t = now(), kind = "match", a = a, b = b, stage = stage, key = key})
				dev:Invoke("autopilot", true)
				local t0, winner = os.clock(), nil
				while os.clock() - t0 < (opts.maxT or 55) do
					local ph, s = phase()
					if ph == "Result" then
						winner = ((s.human and s.human.health or 0) > 0) and a or b
						table.insert(log.events, {t = now(), kind = "ko", by = winner, a = a, b = b, stage = stage, key = key})
						break
					end
					task.wait(0.05)
				end
				if not winner then -- too long: the healthier fighter finishes it
					local _, s = phase()
					winner = ((s.human and s.human.health or 0) >= (s.bot and s.bot.health or 0)) and a or b
					dev:Invoke("ko", winner == a and "bot" or "human"); task.wait(0.3)
					table.insert(log.events, {t = now(), kind = "ko", by = winner, a = a, b = b, stage = stage, key = key, forced = true})
				end
				for _, d in ipairs(dev:Invoke("damagelog") or {}) do
					table.insert(log.events, {t = d.t, kind = "hit", by = d.by, amount = d.amount, tag = d.tag, hits = d.hits, key = key})
				end
				task.wait(opts.after or 2.0)
				dev:Invoke("autopilot", false)
				log.results[key] = winner
				return winner
			end
			start(E[1], E[2], false); waitDuel(10)
			task.wait(opts.lead or 1.0)
			log.flash = {now = S.flash()}
			local R = log.results
			for q = 1, 4 do match(E[2 * q - 1], E[2 * q], "QUARTER-FINAL", "QF" .. q) end
			match(R.QF1, R.QF2, "SEMI-FINAL", "SF1")
			match(R.QF3, R.QF4, "SEMI-FINAL", "SF2")
			match(R.SF1, R.SF2, "FINAL", "F")
		end)
		noUlt = false
		if not ok then log.error = tostring(err) end
		last = log; busy = false
	end)
	return "running"
end

-- A WRITTEN fight ("LEGENDARY FIGHTS", 04/11): no AI, every move placed in
-- time by the script, so each exchange reads (action, then reaction). The
-- same scene is played once per camera angle (ClipKit B.scene), the edit cuts
-- between the takes beat by beat.
--   spec = {a = "Lion", b = "Legion", place = {Vector3, Vector3}, rounds = 1,
--     beats = {{name = "faceoff", dur = 2}, {name = "seals", dur = 1.8, acts = {
--       {at = 0, who = "A", seals = {4, 1}},           -- Seals then Technique4, Technique1
--       {at = 0.5, who = "B", action = "Technique2", chakra = true},
--       {at = 1, who = "A", move = Vector3.new(0, 0, -1), hold = 0.4}}}}}  -- walk direction for `hold` s
-- workspace attribute NDBeat = "<name>#<n>" at each beat (the camera follows it).
function S.scene(spec)
	if busy then return "busy" end
	busy, last = true, nil
	task.spawn(function()
		local log = {kind = "scene", a = spec.a, b = spec.b, events = {}, build = S.build()}
		local ok, err = pcall(function()
			noUlt = spec.noUlt == true
			rounds(spec.rounds or 1)
			start(spec.a, spec.b, true); waitDuel(10)
			dev:Invoke("autopilot", false)
			dev:Invoke("freezeBot", true)
			dev:Invoke("scripted", true)
			local P = spec.place or {Vector3.new(0, 3, 6), Vector3.new(0, 3, -6)}
			dev:Invoke("place", P[1], P[2])
			dev:Invoke("refill")
			dev:Invoke("damagelog", true)
			workspace:SetAttribute("NDBeat", "ready#0")
			task.wait(spec.lead or 1.2)
			log.flash = {now = S.flash()}
			task.wait(0.5)
			local seat = {A = "human", B = "bot"}
			for n, beat in ipairs(spec.beats) do
				workspace:SetAttribute("NDBeat", beat.name .. "#" .. n)
				table.insert(log.events, {t = now(), kind = "beat", name = beat.name, n = n, dur = beat.dur})
				for _, act in ipairs(beat.acts or {}) do
					task.delay(act.at or 0, function()
						local who = seat[act.who or "A"]
						local res
						if act.refill then dev:Invoke("refill") end
						if act.seals then
							res = dev:Invoke("act", who, "Seals")
							task.wait(act.gap or 0.3)
							dev:Invoke("act", who, "Technique" .. act.seals[1])
							task.wait(act.gap or 0.3)
							res = dev:Invoke("act", who, "Technique" .. act.seals[2])
						elseif act.move then
							dev:Invoke("move", who, act.move, act.hold or 0.3)
						elseif act.ultimate then
							dev:Invoke("ultimate", who, 100)
							res = dev:Invoke("act", who, "Ultimate")
						elseif act.action then
							res = dev:Invoke("act", who, act.action, act.aim, act.chakra and {chakra = true} or nil)
						end
						table.insert(log.events, {t = now(), kind = "act", who = act.who, beat = beat.name,
							action = act.action or (act.seals and ("Seals " .. act.seals[1] .. "-" .. act.seals[2])) or (act.ultimate and "Ultimate") or (act.move and "move"),
							ok = type(res) == "table" and res.ok or res, why = type(res) == "table" and res.reason or nil})
					end)
				end
				task.wait(beat.dur or 1.5)
			end
			workspace:SetAttribute("NDBeat", "end#" .. (#spec.beats + 1))
			table.insert(log.events, {t = now(), kind = "end"})
			for _, d in ipairs(dev:Invoke("damagelog") or {}) do
				table.insert(log.events, {t = d.t, kind = "hit", by = d.by, amount = d.amount, tag = d.tag, hits = d.hits})
			end
			local _, s = phase()
			log.health = {A = s.human and s.human.health, B = s.bot and s.bot.health}
			dev:Invoke("scripted", false)
			dev:Invoke("freezeBot", false)
		end)
		noUlt = false
		if not ok then log.error = tostring(err) end
		last = log; busy = false
	end)
	return "running"
end

function S.result()
	if busy then return "running" end
	return last and Http:JSONEncode(last) or "none"
end

return "ShotRunner ready"
