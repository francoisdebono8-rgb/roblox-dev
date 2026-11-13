--!nocheck
-- NDDirector (FILM place only, client): cameras and the take program for NDReplay.
-- Written by the CM for FILM08 (12/11/2026), brought into the repository by the
-- OUTILLEUR on 13/11. Changes: the line of sight also sees the bushes and tree
-- tops (Sight: they are unqueryable, a raycast went through them); the program
-- tells the filming assistant F4 the scene, the shot, who acts and the replay
-- time (workspace NDScene, NDShot, NDAct, NDClock), and can start and stop its
-- take (P.f4); the FILM08 beats moved to docs/tools/OUTIL_TOURNAGE_F4.md.
--
--   local D=require(ReplicatedStorage.NDFactory.NDDirector)   -- also shared.NDD, shared.NDP
--
-- 13/11 evening (claude/demandes-outilleur-prises-humain-2026-11-13): the
-- director judges each shot as a viewer would (ClipJudge) and chooses the angle
-- itself where the written one fails:
--  * every segment is checked every D.cfg.step s of replay before REC: decor
--    in front of the face or the body (bushes and tree tops included), a body
--    in front, the actor seen from behind or looking into the lens, the lens on
--    the side the sun does not light, the actor under a third of the band;
--    where a viewer would say no, the director cuts to the best azimuth around
--    the actor (p.lock = true keeps the written shot; kind "auto" = let it choose);
--  * never wider: the one who acts fills at least D.cfg.minShare of the band;
--  * never out of the enclosure (World.WALL_RADIUS);
--  * the render is slow by default (P.slow = 0.25, sped up x4 in the edit):
--    speeds, eases and holds follow the screen's time, a frozen frame advances
--    the replay by at most P.maxStep, and a beat with a frozen frame is played
--    again (P.retakes);
--  * D.beatsFromMoments(NDReplay.highlights()): a program from a real match's
--    strongest moments.
--
-- Framing rule for the 9:16 band: keep the ACTOR centred.
--  front  : in front of fighter `a` (yaw from his look), looking at him
--  ots    : behind the other fighter, offset `off`, looking at `a` (a's face, the other's shoulder)
--  best   : like front/ots but the azimuth around `a` is searched once per segment
--           (clear line of sight, inside the arena, not in a bush, other fighter not blocking)
--  pair   : both fighters, camera square to their line, distance fitted to the band
--  center : both fighters, camera on the line from their midpoint to the arena centre (near walls)
local R = require(script.Parent.NDReplay)
local Sight = require(script.Parent.ClipSight)
local J = require(script.Parent.ClipJudge)
shared.NDR = R
local RunService = game:GetService("RunService")
local UP = Vector3.yAxis
local CENTER = Vector3.new(0, 3, 0)
local D = {}
shared.NDD = D
D.cfg = {
	auto = true,      -- check every segment and change the angle where a viewer would say no
	minShare = 1 / 3, -- the one who acts fills at least this share of the band's height (0: off)
	step = 0.25,      -- replay seconds between two checks of a segment
	thetaStep = 15,   -- the azimuths tried around the actor
	bad = 250,        -- a score this high: a viewer says no
	minShot = 0.7,    -- the shortest shot the director cuts to (FILM09 shots: 0.7 to 1.2 s)
	sun = 1.0,        -- cost per degree beyond 60° between the lens and the sun, around the actor
	verbose = true,   -- print the director's choices in Output
}
D.planLog = {}

local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilters() rp.FilterDescendantsInstances = {R.folder}; op.FilterDescendantsInstances = {R.folder}; Sight.refresh(true) end
local function flat(v) local f = v * Vector3.new(1, 0, 1); return if f.Magnitude > 1e-3 then f.Unit else Vector3.xAxis end
local function clear(a, b) return (Sight.clear(a, b, rp)) end
local function blockedLens(pos) return #workspace:GetPartBoundsInRadius(pos, 1.6, op) > 0 or Sight.near(pos, 1.2) ~= nil end
D.flat, D.clear = flat, clear

local function camPos(A, B, theta, d, h, hground)
	local f = flat(B - A); local r = f:Cross(UP); local th = math.rad(theta)
	local horiz = (f * math.cos(th) + r * math.sin(th)) * d
	local y = if hground then math.min(A.Y, B.Y) + hground else A.Y + h
	return Vector3.new(A.X + horiz.X, y, A.Z + horiz.Z)
end

-- Never wider than D.cfg.minShare of the band for the one who acts, never out of the enclosure.
local function settle(cf, fov, A, t)
	if not cf then return cf, fov end
	local ca = R.fighterCF(A, t)
	if not ca then return cf, fov end
	local pos, look = cf.Position, cf.LookVector
	local aim = pos + look * math.max(1, (ca.Position - pos):Dot(look))
	if (D.cfg.minShare or 0) > 0 then
		local g = R.ghostFighter(A)
		local h = g and J.height(g) or 5.5
		local dmax = h / (2 * math.tan(math.rad(fov / 2)) * D.cfg.minShare) * 0.97
		local depth = (ca.Position - pos):Dot(look)
		if depth > dmax then pos += look * (depth - dmax) end
	end
	if not J.inside(pos, 3) then
		local c, r = J.arena()
		local f = J.flat(pos - c)
		if f.Magnitude > 1e-3 then
			f = f.Unit * (r - 3)
			pos = Vector3.new(c.X + f.X, pos.Y, c.Z + f.Z)
			return CFrame.lookAt(pos, aim), fov
		end
	end
	return CFrame.lookAt(pos, pos + look), fov
end

local rawShot
function D.shot(kind, t, p)
	p = p or {}
	local cf, fov = rawShot(kind, t, p)
	return settle(cf, fov, p.a or "human", t)
end
function rawShot(kind, t, p)
	if kind == "auto" then kind = "best" end
	local A = p.a or "human"; local B = if A == "human" then "bot" else "human"
	local ca, cb = R.fighterCF(A, t), R.fighterCF(B, t)
	if not ca or not cb then return nil end
	local pa, pb = ca.Position, cb.Position
	local dir = flat(pa - pb); local side = dir:Cross(UP) * (p.side or 1)
	if kind == "ots" then
		local pos = pb - dir * (p.back or 5) + side * (p.off or 3) + UP * (p.h or 2)
		return CFrame.lookAt(pos, pa + UP * (p.lookh or 0.8)), p.fov or 50
	elseif kind == "front" then
		local v = CFrame.fromAxisAngle(UP, math.rad(p.yaw or 30)):VectorToWorldSpace(flat(ca.LookVector))
		local pos = pa + v * (p.d or 9) + UP * (p.h or 1.5)
		return CFrame.lookAt(pos, pa + UP * (p.lookh or 0.6) + (pb - pa) * (p.lead or 0)), p.fov or 50
	elseif kind == "best" then
		local pos = camPos(pa, pb, p.theta or 40, p.d or 9, p.h or 1.8, p.hground)
		return CFrame.lookAt(pos, pa + UP * (p.lookh or 1.0) + (pb - pa) * (p.lead or 0)), p.fov or 50
	elseif kind == "pair" then
		local a, b = R.fighterCF("human", t).Position + UP * 0.6, R.fighterCF("bot", t).Position + UP * 0.6
		local mid = (a + b) / 2; local ax = b - a; local r = flat(ax):Cross(UP)
		local fov = p.fov or 60; local tv = math.tan(math.rad(fov / 2)); local th = tv * 0.5625
		local dH = ((ax * Vector3.new(1, 0, 1)).Magnitude / 2 + (p.mh or 2)) / th
		local dV = (math.abs(ax.Y) / 2 + (p.mv or 3.5)) / tv
		local d = math.clamp(math.max(dH, dV), p.dmin or 9, p.dmax or 24)
		local s = p.side or 1
		local off = r * s * d
		if p.swing then off = CFrame.fromAxisAngle(UP, math.rad(p.swing * s)) * off end
		return CFrame.lookAt(mid + off + UP * (p.h or 1.5), mid + UP * (p.lookh or 0)), fov
	elseif kind == "center" then
		local mid = (pa + pb) / 2; local toC = flat(CENTER - mid); local r = toC:Cross(UP); local yw = math.rad(p.yaw or 0)
		local pos = mid + (toC * math.cos(yw) + r * math.sin(yw)) * (p.d or 15)
		pos = Vector3.new(pos.X, math.min(pa.Y, pb.Y) + (p.h or 2), pos.Z)
		return CFrame.lookAt(pos, mid + UP * (p.lookh or 0)), p.fov or 60
	end
end

function D.pick(t, p)
	local Ak = p.a or "human"; local Bk = if Ak == "human" then "bot" else "human"
	local A, B = R.fighterCF(Ak, t).Position, R.fighterCF(Bk, t).Position
	local best, bestScore
	for theta = -170, 170, 10 do
		local pos = camPos(A, B, theta, p.d or 9, p.h or 1.8, p.hground)
		local score = math.abs(math.abs(theta) - (p.want or 40))
		local headA = A + UP * 1.5
		if not clear(pos, headA) then score += 1000 end
		if not clear(pos, B + UP) then score += 60 end
		if Vector2.new(pos.X, pos.Z).Magnitude > 150 then score += 500 end
		if blockedLens(pos) then score += 1000 end
		local toA, toB = headA - pos, B + UP - pos
		if toB.Magnitude < toA.Magnitude and math.deg(math.acos(math.clamp(toA.Unit:Dot(toB.Unit), -1, 1))) < 12 then score += 200 end
		if not bestScore or score < bestScore then best, bestScore = theta, score end
	end
	return best, bestScore
end

function D.pickSide(kind, t, p)
	local best, bestScore
	for _, s in {1, -1} do
		local q = table.clone(p); q.side = s
		local cf = D.shot(kind, t, q)
		if cf then
			local pos = cf.Position
			local score = (pos - CENTER).Magnitude * 0.05
			for _, k in {"human", "bot"} do if not clear(pos, R.fighterCF(k, t).Position + UP) then score += 1000 end end
			if blockedLens(pos) then score += 1000 end
			if not bestScore or score < bestScore then best, bestScore = s, score end
		end
	end
	return best, bestScore
end

----------------------------------------------------------------------------
-- The viewer's judgement (ClipJudge) and the director's own choice of angle.
----------------------------------------------------------------------------
-- The scene at replay time t, seen from the actor `Ak` ("human" / "bot"): the
-- ghosts are moved to t (no sound, no burst: lastApplied is cleared).
local function sceneAt(t, Ak)
	if R.folder and R.folder.Parent ~= workspace then R.folder.Parent = workspace end
	R.lastApplied = nil
	R.apply(t)
	R.lastApplied = nil
	local Bk = if Ak == "human" then "bot" else "human"
	local actor, other = R.ghostFighter(Ak), R.ghostFighter(Bk)
	if not actor or not actor.Parent then return nil end
	local r = J.rig(actor)
	local center = r.root and r.root.Position or actor:GetPivot().Position
	local parts = {}
	for _, d in R.folder:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.6 and d.Size.Magnitude > 0.3 and not d:IsDescendantOf(actor) and (d.Position - center).Magnitude < 45 then
			table.insert(parts, d)
		end
	end
	return {actor = actor, other = other, parts = parts, decor = Sight.subset(center, 70), head = r.head and r.head.Position or center + UP * 1.5}
end
D.sceneAt = sceneAt

-- How a viewer would judge a camera (the ghosts at its time): lower is better,
-- D.cfg.bad and above a viewer says no. -> score, reasons
function D.judge(cf, fov, ctx)
	local actor, other = ctx.actor, ctx.other
	local pos = cf.Position
	local s, why = 0, {}
	local function add(n, text) s += n; if text then table.insert(why, text) end end
	if not J.inside(pos, 2) then add(1000, "hors de l'enceinte") end
	if blockedLens(pos) then add(1000, "objectif dans le décor") end
	local v = J.visible(pos, actor, {parts = ctx.parts, others = {other}, decor = ctx.decor})
	local dF, dB = v.faceBy["décor"] or 0, v.bodyBy["décor"] or 0
	if dF > 0.15 or dB > 0.15 then add(300, string.format("décor %d %% (%s)", math.floor(math.max(dF, dB) * 100 + 0.5), v.what["décor"] or "?")) end
	add(200 * dF + 150 * dB)
	local bF = (v.faceBy.corps or 0) + (v.faceBy.clone or 0)
	local bB = (v.bodyBy.corps or 0) + (v.bodyBy.clone or 0)
	if bF >= 0.6 or bB >= 0.6 then add(300, "caché par un corps") end
	add(150 * bF + 80 * bB)
	local face = J.facing(pos, actor)
	if face > 115 then add(300, string.format("de dos (%d°)", math.floor(face))) elseif face > 50 then add((face - 50) * 2.5) end
	local _, _, lens = J.gaze(actor, pos)
	if lens < 15 then add(120, "regarde l'objectif") end
	local sunF, sunDir = J.sun()
	if sunF then
		local side = J.sunSide(pos, actor)
		if side > 60 then add((side - 60) * D.cfg.sun, if side > 120 then "contre-jour" else nil) end
		if cf.LookVector:Dot(sunDir) > math.cos(math.rad(35)) then add(150, "face au soleil") end
	end
	local share = J.share(cf, fov, actor)
	if share < D.cfg.minShare then add((D.cfg.minShare - share) * 900, string.format("petit (%d %%)", math.floor(share * 100 + 0.5))) end
	local x, y = J.ndc(cf, fov, ctx.head)
	if not x or math.abs(x) > 0.9 or math.abs(y) > 1 then add(300, "hors du cadre") end
	return s, why
end

local function angleGap(a, b) local d = math.abs((a - b + 180) % 360 - 180); return d end
-- The shots tried for a segment: the written one, then every azimuth around the actor.
local function candidates(seg)
	local list = {}
	local p = seg.p
	local own = seg.kind == "best" or seg.kind == "auto"
	if seg.kind ~= "auto" then table.insert(list, {kind = seg.kind, p = p, pref = 0, written = true}) end
	local want = p.want or (seg.kind == "best" and p.theta) or 40
	for th = -180 + D.cfg.thetaStep, 180, D.cfg.thetaStep do
		local q = {a = p.a, theta = th, d = own and p.d or 9, h = own and p.h or 1.8, lookh = p.lookh, lead = p.lead,
			fov = own and p.fov or 50, hground = p.hground}
		table.insert(list, {kind = "best", p = q, pref = 25 + math.min(angleGap(th, want), angleGap(th, -want)) * 0.3})
	end
	return list
end

-- Cut a segment into shots a viewer accepts (sub-segments, absolute times).
function D.plan(seg)
	local Ak = seg.p.a or "human"
	local cands = candidates(seg)
	local step = D.cfg.step
	local times = {}
	local t = seg.from
	while t < seg.to - 1e-3 do table.insert(times, t); t += step end
	if #times == 0 then times = {seg.from} end
	local cost, why = {}, {}
	for c in cands do cost[c] = {}; why[c] = {} end
	local yieldAt = os.clock()
	for i, ti in times do
		local ctx = sceneAt(ti, Ak)
		for c, cand in cands do
			local sc, w = 2000, {"pas d'image"}
			if ctx then
				local cf, fov = D.shot(cand.kind, ti, cand.p)
				if cf then sc, w = D.judge(cf, fov, ctx) end
			end
			cost[c][i], why[c][i] = sc, w
		end
		if os.clock() - yieldAt > 0.2 and coroutine.isyieldable() then task.wait(); yieldAt = os.clock() end
	end
	-- the longest acceptable run from each point; the same shot as before is preferred
	local n, runs, i, prevC = #times, {}, 1, nil
	local minN = math.max(1, math.ceil(D.cfg.minShot / step - 1e-6))
	while i <= n do
		local bestC, bestU, bestLen
		for c, cand in cands do
			local len, sum = 0, 0
			for j = i, n do
				if cost[c][j] >= D.cfg.bad then break end
				len += 1; sum += cost[c][j] + cand.pref
			end
			local u = if len == 0 then -1e9 - cost[c][i] else len - 2 * (sum / len) / D.cfg.bad + (if c == prevC then 1 else 0)
			if not bestU or u > bestU then bestC, bestU, bestLen = c, u, len end
		end
		local len = math.max(bestLen, 1)
		if len < minN then len = math.min(n - i + 1, minN) end
		if #runs > 0 and len < minN then
			runs[#runs].i1 = i + len - 1 -- a short tail stays with the shot before
		elseif #runs > 0 and runs[#runs].c == bestC then
			runs[#runs].i1 = i + len - 1
		else
			table.insert(runs, {c = bestC, i0 = i, i1 = i + len - 1})
		end
		prevC = bestC
		i += len
	end
	local out = {}
	for k, r in runs do
		local cand = cands[r.c]
		local from = if k == 1 then seg.from else times[r.i0] - step / 2
		local to = if k == #runs then seg.to else times[runs[k + 1].i0] - step / 2
		local x = {from = from, to = to, kind = cand.kind, p = table.clone(cand.p), tau = seg.tau}
		if cand.written then x.push, x.pushEnd = seg.push, seg.pushEnd end
		local worst, reasons = 0, nil
		for j = r.i0, r.i1 do if cost[r.c][j] > worst then worst, reasons = cost[r.c][j], why[r.c][j] end end
		local writtenBad = nil
		if not cand.written and cands[1].written then
			for j = r.i0, r.i1 do
				if cost[1][j] >= D.cfg.bad then writtenBad = string.format("%.2f s : %s", times[j] - R.t0, table.concat(why[1][j], ", ")); break end
			end
		end
		local entry = {from = from - R.t0, to = to - R.t0, kind = cand.kind, theta = cand.p.theta, written = cand.written == true,
			worst = math.floor(worst), reasons = reasons, writtenFailed = writtenBad}
		table.insert(D.planLog, entry)
		if D.cfg.verbose then
			print(string.format("[NDDirector] %.2f–%.2f s : %s%s%s%s", entry.from, entry.to,
				if cand.written then "plan écrit (" .. cand.kind .. ")" else string.format("angle choisi θ=%d°", cand.p.theta or 0),
				if worst >= D.cfg.bad then " — AUCUN ANGLE PROPRE : " .. table.concat(reasons or {}, ", ") else "",
				if writtenBad then " — le plan écrit échouait à " .. writtenBad else "",
				if entry.worst > 0 and worst < D.cfg.bad and reasons and #reasons > 0 then " (" .. table.concat(reasons, ", ") .. ")" else ""))
		end
		table.insert(out, x)
	end
	return out
end

-- one camera function over segments {from, to, kind, p, tau, push, pushEnd} (absolute times)
function D.track(segs, tau)
	refreshFilters()
	for _, s in segs do
		s.p = s.p or {}
		if s.kind == "best" and not s.p.theta then s.p.theta = D.pick(s.from, s.p) end
		if (s.kind == "pair" or s.kind == "ots") and type(s.p.side) ~= "number" then s.p.side = D.pickSide(s.kind, s.from, s.p) end
	end
	-- the viewer's check: where the written shot fails, the director cuts to another angle
	local planned = {}
	for _, s in segs do
		if s.kind == "auto" or (D.cfg.auto and not s.p.lock) then
			for _, x in D.plan(s) do table.insert(planned, x) end
		else
			table.insert(planned, s)
		end
	end
	segs = planned
	local cur, curSeg, lastT
	local fn = function(t)
		local seg
		for _, s in segs do if t >= s.from and t < s.to then seg = s break end end
		seg = seg or segs[#segs]
		local cf, fov = D.shot(seg.kind, t, seg.p)
		if not cf then return nil end
		if seg.push then
			local k = math.clamp((t - seg.from) / math.max((seg.pushEnd or seg.to) - seg.from, 0.01), 0, 1)
			cf = cf + cf.LookVector * seg.push * (1 - (1 - k) ^ 2)
		end
		if seg ~= curSeg or not cur or not lastT or t < lastT then
			cur = {pos = cf.Position, at = cf.Position + cf.LookVector * 10, fov = fov}; curSeg = seg
		else
			local a = 1 - math.exp(-math.max(t - lastT, 0) / (seg.tau or tau or 0.08))
			cur.pos = cur.pos:Lerp(cf.Position, a); cur.at = cur.at:Lerp(cf.Position + cf.LookVector * 10, a)
			cur.fov += (fov - cur.fov) * a
		end
		lastT = t
		return CFrame.lookAt(cur.pos, cur.at), cur.fov
	end
	return fn, function(t)
		for _, s in segs do if t >= s.from and t < s.to then return s end end
		return segs[#segs]
	end
end

-- the take program: beats one after another, black between them (CapCut cuts on it),
-- speed ramps baked in (real slow motion), ease to a stop by SCREEN time, optional timecode
local P = {}
shared.NDP = P
P.f4 = false      -- true: one F4 take for the whole program (workspace.NDRec)
P.shot = nil      -- the camera map's name, written to workspace.NDShot (B3: one program per map)
local pg = game.Players.LocalPlayer.PlayerGui
local function gui(name, order)
	local g = pg:FindFirstChild(name) or Instance.new("ScreenGui")
	g.Name = name; g.IgnoreGuiInset = true; g.DisplayOrder = order; g.ResetOnSpawn = false; g.Parent = pg
	return g
end
local blk = gui("NDBlack", 1000)
local fr = blk:FindFirstChild("F") or Instance.new("Frame")
fr.Name = "F"; fr.Size = UDim2.fromScale(1, 1); fr.BackgroundColor3 = Color3.new(); fr.BorderSizePixel = 0; fr.Parent = blk
blk.Enabled = false
local tcg = gui("NDTC", 900)
local lab = tcg:FindFirstChild("L") or Instance.new("TextLabel")
lab.Name = "L"; lab.AnchorPoint = Vector2.new(0.5, 0); lab.Position = UDim2.fromScale(0.5, 0.03); lab.Size = UDim2.fromOffset(160, 34)
lab.BackgroundColor3 = Color3.new(); lab.BackgroundTransparency = 0.3; lab.TextColor3 = Color3.new(1, 1, 0); lab.TextSize = 26; lab.Font = Enum.Font.Code; lab.Parent = tcg
P.showTC = false
tcg.Enabled = false

function P.speedAt(beat, rel)
	local s = 1
	for _, k in beat.speeds or {} do if rel >= k[1] then s = k[2] end end
	return s
end
-- `slow`: render the whole program at this fraction of real time (default
-- P.slow = 0.25: a quarter-speed render, sped up x4 in the edit, every final
-- frame distinct; 1 = real time, with the sounds).
P.slow = 0.25
P.maxStep = 1 / 30 -- a frozen frame advances the replay by at most this (real seconds): no jump after a freeze
P.retakes = 1      -- a beat with a frozen frame is played again (this many times); the edit keeps the clean one
P.hitch = 0.05     -- a frame longer than this on screen (after the speed-up) is a frozen frame

-- One beat, black before it. Returns true when a frame froze during it.
local function playBeat(beat, track, gap, slow, c0)
	local cam = workspace.CurrentCamera
	local camFn, segAt = track[1], track[2]
	blk.Enabled = true
	workspace:SetAttribute("NDCut", true)
	workspace:SetAttribute("NDScene", nil)
	local a, b = R.t0 + beat.a, R.t0 + beat.b
	R.lastApplied = nil
	R.apply(a)
	local cf, fov = camFn(a)
	if cf then cam.CFrame = cf; cam.FieldOfView = fov end
	task.wait(gap)
	blk.Enabled = false
	workspace:SetAttribute("NDScene", beat.name)
	workspace:SetAttribute("NDCut", nil)
	table.insert(P.log, {beat = beat.name, at = os.clock() - c0})
	local rt, spd = a, P.speedAt(beat, beat.a)
	local holdLeft, easeT, finished, frozen = beat.hold or 0, nil, false, false
	local meanDt = 1 / 60
	RunService:BindToRenderStep("NDProgram", Enum.RenderPriority.Last.Value + 300, function(dt)
		-- the screen's time: what this frame lasts once the slow render is sped up
		local step = math.min(dt, P.maxStep or dt)
		local sdt = step * slow
		if dt * slow > (P.hitch or 0.05) and dt > 2.5 * meanDt then frozen = true end
		meanDt = meanDt * 0.95 + math.min(dt, 0.1) * 0.05
		local rel = rt - R.t0
		local target = P.speedAt(beat, rel)
		local eased = false
		if beat.ease and rel >= beat.ease[1] then
			easeT = (easeT or 0) + sdt
			local k = math.clamp(easeT / beat.ease[2], 0, 1)
			target *= (1 - k) ^ 2
			eased = k >= 1
		end
		spd += (target - spd) * (1 - math.exp(-sdt / 0.06))
		-- particles, trails, beams and sounds follow the effective speed
		if math.abs(spd * slow - (R.speed or 1)) > 0.02 then R.setSpeed(spd * slow) end
		rt = math.min(rt + step * spd * slow, b)
		R.apply(rt)
		-- who must be seen: the beat's `act`, else the segment's fighter
		local seg = segAt(rt)
		local act = beat.act or (seg and seg.p and (seg.p.a == "bot" and "B" or seg.p.a == "human" and "A")) or nil
		workspace:SetAttribute("NDAct", act)
		lab.Text = string.format("%s %.2f", beat.name:sub(1, 1), rt - R.t0)
		local c2, f2 = camFn(rt)
		if c2 then cam.CFrame = c2; cam.FieldOfView = f2 end
		if rt >= b or eased then
			if holdLeft > 0 then holdLeft -= sdt else finished = true end
		end
	end)
	while not finished do task.wait() end
	RunService:UnbindFromRenderStep("NDProgram")
	table.insert(P.log, {beat = beat.name .. " end", at = os.clock() - c0, frozen = frozen})
	return frozen
end

function P.run(beats, gap, slow)
	gap = gap or 1.0
	slow = slow or P.slow or 1
	P.log, P.done = {}, false
	tcg.Enabled = P.showTC
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	R.folder.Parent = workspace
	game:GetService("UserInputService").MouseIconEnabled = false
	blk.Enabled = true
	workspace:SetAttribute("NDCut", true)
	task.spawn(function()
		-- Every beat's shots are checked and chosen before REC, behind the black screen.
		D.planLog = {}
		local tracks = {}
		for i, beat in beats do
			local segs = {}
			for _, s in beat.segs do
				local c = table.clone(s); c.p = table.clone(s.p or {})
				if not c.p.a and type(beat.act) == "string" and #beat.act == 1 then c.p.a = if beat.act == "B" then "bot" else "human" end
				c.from = R.t0 + math.max(s.from, beat.a); c.to = R.t0 + s.to
				table.insert(segs, c)
			end
			if D.cfg.verbose then print("[NDDirector] " .. tostring(beat.name) .. " : choix des plans") end
			tracks[i] = {D.track(segs)}
		end
		workspace:SetAttribute("NDSlow", if slow < 1 then slow else nil)
		workspace:SetAttribute("NDShot", P.shot)
		if P.f4 then workspace:SetAttribute("NDRec", (P.shot or "replay") .. " " .. os.date("%H:%M:%S")) end
		local c0 = os.clock()
		for i, beat in beats do
			local tries = 0
			while true do
				local frozen = playBeat(beat, tracks[i], gap, slow, c0)
				tries += 1
				if not frozen or tries > (P.retakes or 0) then break end
				print("[NDDirector] " .. tostring(beat.name) .. " : image figée, le temps est rejoué")
			end
		end
		blk.Enabled = true
		workspace:SetAttribute("NDCut", true)
		workspace:SetAttribute("NDScene", nil)
		workspace:SetAttribute("NDAct", nil)
		task.wait(0.4)
		if P.f4 then workspace:SetAttribute("NDRec", nil) end
		workspace:SetAttribute("NDCut", nil)
		workspace:SetAttribute("NDSlow", nil)
		R.setSpeed(1)
		P.done = true
	end)
end

-- A program from a real match's strongest moments (NDReplay.highlights()): one
-- beat per moment, the camera on whoever leads the action (the hitter of a hit),
-- the angles left to the director.
function D.beatsFromMoments(h, opts)
	opts = opts or {}
	local beats = {}
	for i, m in (h and h.moments) or {} do
		local segs = {}
		for _, l in m.lines do
			local who = if l.actor == "B" then "bot" else "human"
			local at = math.max(m.from, l.t - 0.4)
			local cur = segs[#segs]
			if not cur or cur.p.a ~= who then
				if cur then cur.to = at end
				table.insert(segs, {from = if #segs == 0 then m.from else at, to = m.to, kind = "auto", p = {a = who}})
			end
		end
		if #segs == 0 then segs = {{from = m.from, to = m.to, kind = "auto", p = {a = "human"}}} end
		-- a shot shorter than D.cfg.minShot stays with the one before
		local merged = {}
		for _, s in segs do
			local prev = merged[#merged]
			if prev and s.to - s.from < D.cfg.minShot then prev.to = s.to else table.insert(merged, s) end
		end
		table.insert(beats, {name = (opts.prefix or "M") .. i, a = m.from, b = m.to, segs = merged, hold = opts.hold or 0.3})
	end
	return beats
end

return D
