--!nocheck
-- NDReplay (FILM place only, client): record a REAL match frame by frame, then
-- replay it as many times as needed, at any speed, with any camera.
-- Written by the CM for FILM08 (12/11/2026, MEDIA/FILM08_SASUKE_GAARA/scripts),
-- brought into the repository by the OUTILLEUR on 13/11 (claude/revue-outil-f4-par-le-cm):
--   * the sounds: every Sound that plays is noted (instant, id, volume, speed,
--     place); the replay plays them again at normal speed, and soundLog() gives
--     the list for the edit (a slow render has no usable sound);
--   * the particle bursts (ParticleEmitter:Emit()): an emitter that stamps
--     NDEmit / NDEmitCount after Emit() is replayed exactly; any other emitter
--     born switched off gets one burst of `emitDefault` when it appears;
--   * the speed: particles (TimeScale), trails, beam textures and the sounds
--     follow M.speed, so a quarter-speed render is a real slow motion;
--   * workspace.NDClock carries the replay time (seconds from the start of the
--     recording) for the filming assistant F4 and the frame log.
-- Records every moving thing outside the static map: both fighters, their clones,
-- effect parts, attachments, emitters, beams, lights, highlights, decals, sprites.
-- Replay = anchored copies ("ghosts") moved to the recorded values; positions are
-- interpolated between samples (except teleports), so a slow replay is smooth.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local M = {}
M.list = {}
M.ghostOf = {}
M.origOf = {}
M.frames = {}
M.roots = {}
M.sounds = {}
M.emits = {}
M.recording = false
M.version = 2
M.emitDefault = 12
M.soundOn = true        -- play the recorded sounds during a replay
M.soundMinSpeed = 0.9   -- below this speed the replay is silent (the edit uses soundLog)

local nextId = 0
local queue, queued = {}, {}
local conns = {}
local soundLast = setmetatable({}, {__mode = "k"})

local PROPS = {
	{"BasePart", {{"CFrame", "cf"}, {"Size", "v3"}, {"Transparency", "n"}, {"Color", "c3"}}},
	{"Attachment", {{"CFrame", "cf"}}},
	{"ParticleEmitter", {{"Enabled", "s"}, {"Rate", "s"}}},
	{"Beam", {{"Enabled", "s"}, {"Width0", "n"}, {"Width1", "n"}, {"Transparency", "s"}, {"Color", "s"}}},
	{"Trail", {{"Enabled", "s"}}},
	{"Light", {{"Enabled", "s"}, {"Brightness", "n"}, {"Range", "n"}, {"Color", "c3"}}},
	{"Highlight", {{"Enabled", "s"}, {"FillTransparency", "n"}, {"OutlineTransparency", "n"}, {"FillColor", "c3"}}},
	{"Decal", {{"Transparency", "n"}}},
	{"SpecialMesh", {{"Scale", "v3"}, {"Offset", "v3"}}},
	{"BillboardGui", {{"Enabled", "s"}, {"Size", "s"}}},
	{"ImageLabel", {{"ImageTransparency", "n"}, {"ImageRectOffset", "s"}, {"Rotation", "n"}, {"ImageColor3", "c3"}, {"Size", "s"}, {"Visible", "s"}}},
}
local EXCL = {"Courtyard", "NinjaDuelArenaDress", "NinjaDuelMenuStage", "NDReplay"}

local function now() return workspace:GetServerTimeNow() end

local function excluded(inst)
	local terrain, cam = workspace.Terrain, workspace.CurrentCamera
	if inst == terrain or inst:IsDescendantOf(terrain) then return true end
	if cam and (inst == cam or inst:IsDescendantOf(cam)) then return true end
	for _, n in EXCL do
		if inst.Name == n or inst:FindFirstAncestor(n) then return true end
	end
	return false
end

local function propsFor(inst)
	local res
	for _, e in PROPS do
		if inst:IsA(e[1]) then
			res = res or {}
			for _, p in e[2] do table.insert(res, p) end
		end
	end
	return res
end

local function push(it, key, v, t)
	local tr = it.tracks[key]
	if not tr then tr = {}; it.tracks[key] = tr end
	local n = #tr
	if n > 0 and M.prevT and tr[n][1] < M.prevT - 1e-6 then
		tr[n + 1] = {M.prevT, tr[n][2]}
		n += 1
	end
	tr[n + 1] = {t, v}
end

-- Sounds: noted when they start (Played and Playing both fire on Play(): one note).
local function watchSound(s)
	if soundLast[s] ~= nil then return end
	soundLast[s] = -math.huge
	local function note()
		if not M.recording or not s.Playing then return end
		local t = now()
		if t - soundLast[s] < 0.05 then return end
		soundLast[s] = t
		local p = s.Parent
		local pos = nil
		if p and p:IsA("BasePart") then pos = p.Position elseif p and p:IsA("Attachment") then pos = p.WorldPosition end
		table.insert(M.sounds, {t = t, id = s.SoundId, volume = s.Volume, speed = s.PlaybackSpeed, pos = pos, looped = s.Looped,
			name = s.Name, start = s.TimePosition, length = s.TimeLength, rolloff = s.RollOffMaxDistance})
	end
	table.insert(conns, s.Played:Connect(function() task.defer(note) end))
	table.insert(conns, s:GetPropertyChangedSignal("Playing"):Connect(note))
	if s.Playing then note() end
end

local KILL = {"LuaSourceContainer", "JointInstance", "WeldConstraint", "Constraint", "Sound", "BodyMover", "ForceField", "ProximityPrompt", "ClickDetector"}
local function prep(g, isFighter)
	local all = g:GetDescendants()
	table.insert(all, 1, g)
	for _, d in all do
		local kill = false
		for _, c in KILL do if d:IsA(c) then kill = true break end end
		if kill and d ~= g then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
		elseif d:IsA("Humanoid") then
			pcall(function()
				d.EvaluateStateMachine = false
				d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			end)
		elseif d:IsA("BillboardGui") and (isFighter or d:FindFirstChildWhichIsA("TextLabel", true)) then
			d.Enabled = false
			d:SetAttribute("NDRskip", true)
		end
	end
end

local function adopt(X, t, isFighter)
	if not X.Parent or not X:IsDescendantOf(workspace) then return end
	local all = X:GetDescendants()
	table.insert(all, 1, X)
	for _, d in all do
		if d:GetAttribute("NDR") == nil then
			nextId += 1
			d:SetAttribute("NDR", nextId)
		end
		pcall(function() d.Archivable = true end)
		if d:IsA("Sound") then watchSound(d) end
	end
	local g = X:Clone()
	if not g then return end
	local gall = g:GetDescendants()
	table.insert(gall, 1, g)
	for _, gd in gall do
		local id = gd:GetAttribute("NDR")
		if id then M.ghostOf[id] = gd end
	end
	prep(g, isFighter)
	-- references that point outside the copied tree
	for _, gd in g:GetDescendants() do
		if gd:IsA("Beam") or gd:IsA("Trail") then
			for _, k in {"Attachment0", "Attachment1"} do
				local a = gd[k]
				local id = a and a:GetAttribute("NDR")
				if id and M.ghostOf[id] and M.ghostOf[id] ~= a then gd[k] = M.ghostOf[id] end
			end
		elseif gd:IsA("Highlight") and gd.Adornee then
			local id = gd.Adornee:GetAttribute("NDR")
			if id and M.ghostOf[id] then gd.Adornee = M.ghostOf[id] end
		end
	end
	local pid = X.Parent and X.Parent:GetAttribute("NDR")
	local rootParent = (pid and M.ghostOf[pid]) or M.folder
	for _, d in all do
		local id = d:GetAttribute("NDR")
		local gd = M.ghostOf[id]
		if gd and (gd.Parent or gd == g) and not gd:GetAttribute("NDRskip") then
			local props = propsFor(d)
			if d == X or props then
				local it = {id = id, inst = d, ghost = gd, props = props, tracks = {}, last = {},
					gparent = if d == X then rootParent else gd.Parent, root = d == X, lastAlive = true}
				push(it, "__alive", true, t)
				if props then
					for _, p in props do
						local v = d[p[1]]
						it.last[p[1]] = v
						push(it, p[1], v, t)
					end
				end
				if d:IsA("ParticleEmitter") then
					-- A burst emitter: born switched off. Exact bursts if the effect stamps NDEmit.
					it.burst = (not d.Enabled) or d.Rate == 0
					table.insert(conns, d:GetAttributeChangedSignal("NDEmit"):Connect(function()
						if M.recording then
							it.stamped = true
							table.insert(M.emits, {t = now(), it = it, count = d:GetAttribute("NDEmitCount") or M.emitDefault})
						end
					end))
				end
				table.insert(M.list, it)
				M.origOf[id] = d
			end
		end
	end
	g.Parent = nil
	table.insert(M.roots, {inst = X, ghost = g, t = t, fighter = isFighter})
	return g
end

local function sample()
	local t = now()
	if #queue > 0 then
		local q = queue
		queue, queued = {}, {}
		local inQ = {}
		for _, x in q do inQ[x] = true end
		for _, x in q do
			local p = x.Parent
			local nested = false
			while p and p ~= workspace do
				if inQ[p] then nested = true break end
				p = p.Parent
			end
			if not nested and x:GetAttribute("NDR") == nil then adopt(x, t, false) end
		end
	end
	for _, it in M.list do
		local inst = it.inst
		local alive = inst.Parent ~= nil and inst:IsDescendantOf(workspace)
		if alive ~= it.lastAlive then
			push(it, "__alive", alive, t)
			it.lastAlive = alive
		end
		if alive and it.props then
			for _, p in it.props do
				local v = inst[p[1]]
				if v ~= it.last[p[1]] then
					push(it, p[1], v, t)
					it.last[p[1]] = v
				end
			end
		end
	end
	M.prevT = t
	table.insert(M.frames, t)
end

function M.reset()
	M.stop()
	if M.folder then M.folder:Destroy() end
	M.list, M.ghostOf, M.origOf, M.frames, M.roots, M.sounds, M.emits = {}, {}, {}, {}, {}, {}, {}
	table.clear(soundLast)
	M.prevT = nil
	M.prepared = false
end

-- fighters: {human = model, bot = model}; others: instances present at the start
function M.start(fighters, others)
	M.reset()
	M.folder = Instance.new("Folder")
	M.folder.Name = "NDReplay"
	M.folder.Parent = nil
	local t = now()
	M.t0 = t
	M.fighters = {}
	for key, model in fighters do
		adopt(model, t, true)
		local hrp = model:FindFirstChild("HumanoidRootPart")
		M.fighters[key] = {model = model, id = model:GetAttribute("NDR"), hrp = hrp and hrp:GetAttribute("NDR"),
			head = model:FindFirstChild("Head") and model.Head:GetAttribute("NDR")}
	end
	for _, x in others or {} do adopt(x, t, false) end
	table.insert(conns, workspace.DescendantAdded:Connect(function(x)
		if not M.recording then return end
		if x:IsA("Sound") then watchSound(x) end
		if not queued[x] and not excluded(x) then
			queued[x] = true
			table.insert(queue, x)
		end
	end))
	-- Sounds that never enter workspace (2D sounds of the hit feedback and the HUD).
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	for _, root in {SoundService, pg} do
		if root then
			for _, d in root:GetDescendants() do if d:IsA("Sound") then watchSound(d) end end
			table.insert(conns, root.DescendantAdded:Connect(function(x) if x:IsA("Sound") then watchSound(x) end end))
		end
	end
	for _, d in workspace:GetDescendants() do if d:IsA("Sound") then watchSound(d) end end
	M.recording = true
	RunService:BindToRenderStep("NDReplayRec", Enum.RenderPriority.Last.Value + 50, function()
		if M.recording then sample() end
	end)
	return t
end

function M.stop()
	M.recording = false
	pcall(function() RunService:UnbindFromRenderStep("NDReplayRec") end)
	for _, c in conns do c:Disconnect() end
	conns = {}
	if #M.frames > 0 then M.t1 = M.frames[#M.frames] end
end

-- value lookup -----------------------------------------------------------------
local function valueAt(tr, t, mode)
	local n = #tr
	if t <= tr[1][1] then return tr[1][2] end
	if t >= tr[n][1] then return tr[n][2] end
	local lo, hi = 1, n
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if tr[mid][1] <= t then lo = mid else hi = mid end
	end
	local a, b = tr[lo], tr[hi]
	local dt = b[1] - a[1]
	if mode == "s" or dt > 0.25 or dt <= 0 then return a[2] end
	local f = (t - a[1]) / dt
	if mode == "cf" then
		if (b[2].Position - a[2].Position).Magnitude > 6 then return if f < 0.5 then a[2] else b[2] end
		return a[2]:Lerp(b[2], f)
	elseif mode == "n" then
		return a[2] + (b[2] - a[2]) * f
	else
		return a[2]:Lerp(b[2], f)
	end
end
M.valueAt = valueAt

function M.itemById(id)
	for _, it in M.list do if it.id == id then return it end end
end

-- world CFrame of a recorded part (by NDR id) at time t
local cache = {}
function M.cfAt(id, t)
	local it = cache[id]
	if not it then it = M.itemById(id); cache[id] = it end
	if not it or not it.tracks.CFrame then return nil end
	return valueAt(it.tracks.CFrame, t, "cf")
end
function M.fighterCF(key, t)
	local f = M.fighters[key]
	return f and M.cfAt(f.hrp, t)
end
-- the ghost model of a fighter ("human" / "bot"), for the filming assistant F4
function M.ghostFighter(key)
	local f = M.fighters and M.fighters[key]
	return f and M.ghostOf[f.id]
end

-- live world on/off during the replay (client-local reparent)
local BIN = 0.5
function M.prepare()
	local t0 = M.t0
	M.bins = {}
	M.shown = {}
	table.clear(cache)
	local nConst = 0
	for _, it in M.list do
		it.isPart = it.ghost:IsA("BasePart")
		local al = it.tracks.__alive
		local aStart = al[1][1]
		local aEnd = M.t1 or al[#al][1]
		if al[#al][2] == false then aEnd = al[#al][1] end
		it.aStart, it.aEnd = aStart, aEnd
		it.cur = {}
		it.live = {}
		if it.props then
			for _, p in it.props do
				local tr = it.tracks[p[1]]
				if tr then
					local const = true
					local v1 = tr[1][2]
					for i = 2, #tr do if tr[i][2] ~= v1 then const = false break end end
					if const then
						nConst += 1
						if p[1] == "CFrame" and it.isPart then it.ghost.CFrame = v1 else pcall(function() it.ghost[p[1]] = v1 end) end
					else
						table.insert(it.live, p)
					end
				end
			end
		end
		for k = math.floor((aStart - t0) / BIN), math.floor((aEnd - t0) / BIN) do
			local b = M.bins[k]
			if not b then b = {}; M.bins[k] = b end
			table.insert(b, it)
		end
	end
	for _, it in M.list do it.ghost.Parent = nil end
	table.sort(M.sounds, function(a, b) return a.t < b.t end)
	table.sort(M.emits, function(a, b) return a.t < b.t end)
	M.prepared = true
	return nConst
end

local function at(it, key, tr, t, mode)
	local n = #tr
	if t <= tr[1][1] then return tr[1][2] end
	if t >= tr[n][1] then return tr[n][2] end
	local i = it.cur[key] or 1
	if i >= n or tr[i][1] > t then
		-- binary search
		local lo, hi = 1, n
		while hi - lo > 1 do
			local mid = (lo + hi) // 2
			if tr[mid][1] <= t then lo = mid else hi = mid end
		end
		i = lo
	else
		while i < n - 1 and tr[i + 1][1] <= t do i += 1 end
	end
	it.cur[key] = i
	local a, b = tr[i], tr[i + 1]
	local dt = b[1] - a[1]
	if mode == "s" or dt > 0.25 or dt <= 0 then return a[2] end
	local f = (t - a[1]) / dt
	if mode == "cf" then
		if (b[2].Position - a[2].Position).Magnitude > 6 then return if f < 0.5 then a[2] else b[2] end
		return a[2]:Lerp(b[2], f)
	elseif mode == "n" then
		return a[2] + (b[2] - a[2]) * f
	else
		return a[2]:Lerp(b[2], f)
	end
end

-- Sounds and stamped bursts between two replay times (forward only).
local function playSound(s)
	if not M.soundOn or M.speed < M.soundMinSpeed or s.id == "" then return end
	local snd = Instance.new("Sound")
	snd.SoundId = s.id; snd.Volume = s.volume; snd.PlaybackSpeed = s.speed * M.speed; snd.Looped = false
	pcall(function() snd.TimePosition = s.start or 0 end)
	local holder
	if s.pos then
		holder = Instance.new("Part")
		holder.Anchored = true; holder.CanCollide = false; holder.CanQuery = false; holder.CanTouch = false
		holder.Transparency = 1; holder.Size = Vector3.new(0.2, 0.2, 0.2); holder.CFrame = CFrame.new(s.pos)
		holder.Name = "NDReplaySound"; holder.Parent = M.folder
		if s.rolloff then snd.RollOffMaxDistance = s.rolloff end
		snd.Parent = holder
	else
		snd.Parent = SoundService
	end
	snd:Play()
	task.delay(math.min(math.max((s.length or 2) / math.max(s.speed * M.speed, 0.1), 0.5), 12), function()
		snd:Destroy(); if holder then holder:Destroy() end
	end)
end
local function crossings(a, b)
	if b <= a then return end
	for _, s in M.sounds do
		if s.t > b then break end
		if s.t > a then playSound(s) end
	end
	for _, e in M.emits do
		if e.t > b then break end
		if e.t > a and e.it.ghost.Parent then pcall(function() e.it.ghost:Emit(e.count) end) end
	end
end

M.lastApplied = nil
function M.apply(t)
	if not M.prepared then M.prepare() end
	local k = math.floor((t - M.t0) / BIN)
	local bin = M.bins[k] or {}
	local nowShown = {}
	local parts, cfs = {}, {}
	local forward = M.lastApplied ~= nil and t > M.lastApplied and t - M.lastApplied < 1
	for _, it in bin do
		local alive = t >= it.aStart and t <= it.aEnd and at(it, "__alive", it.tracks.__alive, t, "s")
		local g = it.ghost
		if alive then
			nowShown[it] = true
			if g.Parent ~= it.gparent then g.Parent = it.gparent end
			for _, p in it.live do
				local v = at(it, p[1], it.tracks[p[1]], t, p[2])
				if p[1] == "CFrame" and it.isPart then
					parts[#parts + 1] = g
					cfs[#cfs + 1] = v
				elseif g[p[1]] ~= v then
					g[p[1]] = v
				end
			end
			-- an unstamped burst emitter: one burst when it appears
			if forward and it.burst and not it.stamped and not M.shown[it] then
				pcall(function() g:Emit(it.inst:GetAttribute("NDEmitCount") or M.emitDefault) end)
			end
		end
	end
	for it in M.shown do
		if not nowShown[it] and it.ghost.Parent ~= nil then it.ghost.Parent = nil end
	end
	M.shown = nowShown
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	if forward then crossings(M.lastApplied, t) end
	M.lastApplied = t
	workspace:SetAttribute("NDClock", math.floor((t - M.t0) * 1000 + 0.5) / 1000)
end

M.hidden = {}
function M.hideLive(list)
	M.holder = M.holder or Instance.new("Folder")
	M.holder.Name = "NDReplayLiveHidden"
	M.holder.Parent = game:GetService("ReplicatedStorage")
	for _, x in list do
		if x and x.Parent then
			table.insert(M.hidden, {x, x.Parent})
			x.Parent = M.holder
		end
	end
end
function M.showLive()
	for _, h in M.hidden do pcall(function() h[1].Parent = h[2] end) end
	M.hidden = {}
end

-- Everything that runs on its own clock follows the replay speed.
function M.setSpeed(speed)
	M.speed = speed
	for _, it in M.list do
		local g = it.ghost
		if g:IsA("ParticleEmitter") then g.TimeScale = speed
		elseif g:IsA("Trail") then
			it.baseLife = it.baseLife or it.inst.Lifetime
			g.Lifetime = it.baseLife / math.max(speed, 0.05)
		elseif g:IsA("Beam") then
			it.baseTex = it.baseTex or it.inst.TextureSpeed
			g.TextureSpeed = it.baseTex * speed
		end
	end
end
M.speed = 1

-- play [a, b] of the recording at `speed`; camFn(t) -> CFrame, fov (optional)
function M.play(a, b, speed, camFn, onDone)
	M.halt()
	M.folder.Parent = workspace
	for _, it in M.list do it.isPart = it.ghost:IsA("BasePart") end
	M.setSpeed(speed)
	local rt = a
	M.rt = rt
	M.lastApplied = nil
	local cam = workspace.CurrentCamera
	if camFn then cam.CameraType = Enum.CameraType.Scriptable end
	M.playing = true
	RunService:BindToRenderStep("NDReplayPlay", Enum.RenderPriority.Last.Value + 300, function(dt)
		if not M.playing then return end
		if not M.paused then rt += dt * M.speed end
		if rt >= b then rt = b end
		M.rt = rt
		M.apply(rt)
		if camFn then
			local cf, fov = camFn(rt, dt)
			if cf then cam.CFrame = cf end
			if fov then cam.FieldOfView = fov end
		end
		if rt >= b and not M.paused then
			M.paused = true
			if onDone then task.spawn(onDone) end
		end
	end)
end
function M.halt()
	M.playing = false
	M.paused = false
	pcall(function() RunService:UnbindFromRenderStep("NDReplayPlay") end)
end
function M.seek(t, camFn)
	M.folder.Parent = workspace
	for _, it in M.list do it.isPart = it.ghost:IsA("BasePart") end
	M.lastApplied = nil
	M.apply(t)
	if camFn then
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local cf, fov = camFn(t, 1)
		if cf then cam.CFrame = cf end
		if fov then cam.FieldOfView = fov end
	end
end

-- The sounds of the recording, for the edit: seconds from the start of the recording.
function M.soundLog()
	local out = {}
	for _, s in M.sounds do
		table.insert(out, {t = math.floor((s.t - M.t0) * 1000 + 0.5) / 1000, id = s.id, volume = s.volume, speed = s.speed,
			name = s.name, length = s.length, looped = s.looped, pos = s.pos and {s.pos.X, s.pos.Y, s.pos.Z} or nil})
	end
	return out
end

function M.stats()
	local nParts, nTracks, nEntries, bursts, stamped = 0, 0, 0, 0, 0
	for _, it in M.list do
		if it.inst:IsA("BasePart") then nParts += 1 end
		if it.burst then bursts += 1 end
		if it.stamped then stamped += 1 end
		for _, tr in it.tracks do nTracks += 1; nEntries += #tr end
	end
	return {items = #M.list, parts = nParts, tracks = nTracks, entries = nEntries, frames = #M.frames,
		dur = M.t1 and M.t0 and (M.t1 - M.t0), roots = #M.roots, sounds = #M.sounds, burstEmitters = bursts,
		stampedEmitters = stamped, stampedBursts = #M.emits}
end

return M
