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
-- Framing rule for the 9:16 band: keep the ACTOR centred.
--  front  : in front of fighter `a` (yaw from his look), looking at him
--  ots    : behind the other fighter, offset `off`, looking at `a` (a's face, the other's shoulder)
--  best   : like front/ots but the azimuth around `a` is searched once per segment
--           (clear line of sight, inside the arena, not in a bush, other fighter not blocking)
--  pair   : both fighters, camera square to their line, distance fitted to the band
--  center : both fighters, camera on the line from their midpoint to the arena centre (near walls)
local R = require(script.Parent.NDReplay)
local Sight = require(script.Parent.Sight)
shared.NDR = R
local RunService = game:GetService("RunService")
local UP = Vector3.yAxis
local CENTER = Vector3.new(0, 3, 0)
local D = {}
shared.NDD = D

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

function D.shot(kind, t, p)
	p = p or {}
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

-- one camera function over segments {from, to, kind, p, tau, push, pushEnd} (absolute times)
function D.track(segs, tau)
	refreshFilters()
	for _, s in segs do
		s.p = s.p or {}
		if s.kind == "best" and not s.p.theta then s.p.theta = D.pick(s.from, s.p) end
		if (s.kind == "pair" or s.kind == "ots") and type(s.p.side) ~= "number" then s.p.side = D.pickSide(s.kind, s.from, s.p) end
	end
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
-- `slow` (optional): render the whole program at this fraction of real time
-- (0.25 = a quarter-speed render, sped up x4 in the edit: every frame distinct).
function P.run(beats, gap, slow)
	gap = gap or 1.0
	slow = slow or 1
	P.log, P.done = {}, false
	tcg.Enabled = P.showTC
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	R.folder.Parent = workspace
	game:GetService("UserInputService").MouseIconEnabled = false
	workspace:SetAttribute("NDShot", P.shot)
	if P.f4 then workspace:SetAttribute("NDRec", (P.shot or "replay") .. " " .. os.date("%H:%M:%S")) end
	task.spawn(function()
		local c0 = os.clock()
		for _, beat in beats do
			blk.Enabled = true
			workspace:SetAttribute("NDScene", nil)
			local a, b = R.t0 + beat.a, R.t0 + beat.b
			local segs = {}
			for _, s in beat.segs do
				local c = table.clone(s); c.p = table.clone(s.p or {})
				c.from = R.t0 + math.max(s.from, beat.a); c.to = R.t0 + s.to
				table.insert(segs, c)
			end
			local camFn, segAt = D.track(segs)
			R.lastApplied = nil
			R.apply(a)
			local cf, fov = camFn(a)
			if cf then cam.CFrame = cf; cam.FieldOfView = fov end
			task.wait(gap)
			blk.Enabled = false
			workspace:SetAttribute("NDScene", beat.name)
			table.insert(P.log, {beat = beat.name, at = os.clock() - c0})
			local rt, spd = a, P.speedAt(beat, beat.a)
			local holdLeft, easeT, finished = beat.hold or 0, nil, false
			RunService:BindToRenderStep("NDProgram", Enum.RenderPriority.Last.Value + 300, function(dt)
				local rel = rt - R.t0
				local target = P.speedAt(beat, rel)
				local eased = false
				if beat.ease and rel >= beat.ease[1] then
					easeT = (easeT or 0) + dt
					local k = math.clamp(easeT / beat.ease[2], 0, 1)
					target *= (1 - k) ^ 2
					eased = k >= 1
				end
				spd += (target - spd) * (1 - math.exp(-dt / 0.06))
				-- particles, trails, beams and sounds follow the effective speed
				if math.abs(spd * slow - (R.speed or 1)) > 0.05 then R.setSpeed(spd * slow) end
				rt = math.min(rt + dt * spd * slow, b)
				R.apply(rt)
				-- who must be seen: the beat's `act`, else the segment's fighter
				local seg = segAt(rt)
				local act = beat.act or (seg and seg.p and (seg.p.a == "bot" and "B" or seg.p.a == "human" and "A")) or nil
				workspace:SetAttribute("NDAct", act)
				lab.Text = string.format("%s %.2f", beat.name:sub(1, 1), rt - R.t0)
				local c2, f2 = camFn(rt)
				if c2 then cam.CFrame = c2; cam.FieldOfView = f2 end
				if rt >= b or eased then
					if holdLeft > 0 then holdLeft -= dt * slow else finished = true end
				end
			end)
			while not finished do task.wait() end
			RunService:UnbindFromRenderStep("NDProgram")
			table.insert(P.log, {beat = beat.name .. " end", at = os.clock() - c0})
		end
		blk.Enabled = true
		workspace:SetAttribute("NDScene", nil)
		workspace:SetAttribute("NDAct", nil)
		task.wait(0.4)
		if P.f4 then workspace:SetAttribute("NDRec", nil) end
		P.done = true
	end)
end

return D
