--!nocheck
-- Ninja Duel content factory: client side (run in the Client datamodel of the
-- clip place, ND-Clips2, during Play). Paste the whole file into execute_luau.
--
--   _G.NDCam            camera settings; mode = "fight" | "hero" | "bracket"
--   _G.NDHideUI(on)     hides every ScreenGui, the Roblox core UI and the mouse
--   _G.NDB              the 3D tournament bracket (Workspace.TournamentSet)
--
-- The camera is a Scriptable camera bound at RenderPriority.Last, so nothing in
-- the game can fight it. It keeps both fighters in a 9:16 crop of the window.
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local V = Vector3.new

_G.NDCam = _G.NDCam or {}
local C = _G.NDCam
-- fight: k = distance per stud of separation, clear = margin, elev = height per stud of distance
for k, v in pairs({mode = "fight", minD = 10, maxD = 24, k = 1.6, clear = 8, elev = 0.32, fov = 50,
	heroDist = 5.5, heroUp = 0.4, heroSide = 1.2}) do if C[k] == nil then C[k] = v end end

local function duelModels()
	local root = workspace:FindFirstChild("NinjaDuels")
	if not root then return nil end
	for _, duel in ipairs(root:GetChildren()) do
		local a, b = duel:FindFirstChild("PlayerFighter"), duel:FindFirstChild("AIFighter")
		if a and b then return a, b, duel end
	end
end
local function hrp(m) return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) end
local function flat(v) return V(v.X, 0, v.Z) end
local function damp(a, b, rate, dt) return a:Lerp(b, 1 - math.exp(-rate * dt)) end
local function dampN(a, b, rate, dt) return a + (b - a) * (1 - math.exp(-rate * dt)) end

local st = {side = nil, yaw = 0, dist = 14, tgt = nil}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function fight(dt, cam)
	local A, B, duel = duelModels()
	local ra, rb = hrp(A), hrp(B)
	if not (ra and rb) then return end
	local pa, pb = ra.Position, rb.Position
	local mid = (pa + pb) / 2 + V(0, 1, 0)
	local oa = flat(pb - pa)
	local sep = oa.Magnitude
	local side = sep > 0.05 and oa.Unit:Cross(Vector3.yAxis) or (st.side or V(0, 0, 1))
	if st.side and side:Dot(st.side) < 0 then side = -side end -- never flip sides
	st.side = st.side and damp(st.side, side, 2, dt).Unit or side
	local yawWant = math.rad(18 + 47 * math.clamp((sep - 5) / 10, 0, 1))
	st.yaw = dampN(st.yaw, yawWant, 2.5, dt)
	local view = (CFrame.Angles(0, st.yaw, 0):VectorToWorldSpace(st.side)).Unit
	local want = math.max(math.clamp(sep * C.k + 4, C.minD, C.maxD), C.clear + math.abs(oa:Dot(view)))
	st.dist = dampN(st.dist, want, want > st.dist and 5 or 2, dt)
	st.tgt = st.tgt and damp(st.tgt, mid, 6, dt) or mid
	local pos = st.tgt + view * st.dist + V(0, 1.5 + st.dist * C.elev, 0)
	local ex = {A, B}
	local set = workspace:FindFirstChild("TournamentSet"); if set then table.insert(ex, set) end
	rayParams.FilterDescendantsInstances = ex
	local hit = workspace:Raycast(st.tgt, pos - st.tgt, rayParams)
	if hit then
		local dir = (pos - st.tgt).Unit
		pos = st.tgt + dir * math.max(4, hit.Distance - 1.5) + V(0, 2.5, 0)
	end
	cam.CFrame = CFrame.lookAt(pos, st.tgt)
	cam.FieldOfView = C.fov
end

-- hero: a close 3/4 shot on the performer's face (the PlayerFighter), slowly
-- pushing in. Used for the first second of a showcase ("this is ITACHI").
local heroT = 0
local function hero(dt, cam)
	local A = duelModels()
	local head = A and (A:FindFirstChild("Head") or hrp(A))
	if not head then return end
	heroT += dt
	local cf = hrp(A).CFrame
	local look = head.Position + V(0, 0.2, 0)
	local d = C.heroDist - math.min(heroT, 3) * 0.4
	local pos = look + cf.LookVector * d + cf.RightVector * C.heroSide + V(0, C.heroUp, 0)
	cam.CFrame = CFrame.lookAt(pos, look)
	cam.FieldOfView = C.fov
end
function C.heroReset() heroT = 0 end

pcall(function() RS:UnbindFromRenderStep("NDClipCam") end)
RS:BindToRenderStep("NDClipCam", Enum.RenderPriority.Last.Value, function(dt)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	if C.mode == "fight" then fight(dt, cam)
	elseif C.mode == "hero" then hero(dt, cam)
	elseif C.mode == "bracket" and C.cf then cam.CFrame = C.cf; cam.FieldOfView = C.fov or 60 end
end)

function _G.NDHideUI(on)
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then for _, g in ipairs(pg:GetChildren()) do if g:IsA("ScreenGui") then g.Enabled = not on end end end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not on) end)
	UIS.MouseIconEnabled = not on
end

--------------------------------------------------------------------------
-- The 3D bracket (Workspace.TournamentSet, built in Edit with PhotoKit).
-- Tiers: 8 / 4 / 2 / 1 slots rising and receding; fighters named by id.
--------------------------------------------------------------------------
local B = {}
_G.NDB = B
local O = V(0, 200, 900)
local tiers = { {n = 8, y = 0, z = 0, sp = 7.5}, {n = 4, y = 5, z = -12, sp = 15}, {n = 2, y = 10, z = -24, sp = 30}, {n = 1, y = 15, z = -36, sp = 0} }
B.O = O
B.ROSTER = {"Legion", "GentleFist", "Leaf", "Sand", "Lion", "Copycat", "Mirage", "Flashstep"}
B.NAME = {Legion = "NARUTO", GentleFist = "NEJI", Leaf = "ROCK LEE", Sand = "GAARA", Lion = "SASUKE", Copycat = "KAKASHI", Mirage = "ITACHI", Flashstep = "MINATO"}
function B.slot(t, i) local tier = tiers[t]; return O + V((i - (tier.n + 1) / 2) * tier.sp, tier.y, tier.z) end
function B.model(id) return workspace.TournamentSet:FindFirstChild(id) end
local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
function B.easeCubic(t) t = math.clamp(t, 0, 1); return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2 end
function B.lin(t) return math.clamp(t, 0, 1) end
function B.cam(p0, l0, p1, l1, dur, fn, fov0, fov1)
	C.mode = "bracket"
	local t0 = os.clock()
	while true do
		local k = (os.clock() - t0) / dur
		local e = (fn or ease)(k)
		C.cf = CFrame.lookAt(p0:Lerp(p1, e), l0:Lerp(l1, e))
		C.fov = (fov0 or 60) + ((fov1 or fov0 or 60) - (fov0 or 60)) * e
		if k >= 1 then break end
		RS.RenderStepped:Wait()
	end
end
function B.hold(p, l, dur, fov) B.cam(p, l, p, l, dur, nil, fov, fov) end
function B.jump(id, t, i, dur)
	local m = B.model(id); if not m then return end
	local a = m:GetPivot(); local target = B.slot(t, i) + V(0, 3, 0)
	local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / dur, 0, 1); local e = ease(k)
		local p = a.Position:Lerp(target, e) + V(0, 7 * math.sin(math.pi * k), 0)
		m:PivotTo(CFrame.new(p) * a.Rotation:Lerp(CFrame.lookAt(target, target + V(0, 0, 10)).Rotation, e))
		if k >= 1 then break end
		RS.RenderStepped:Wait()
	end
end
function B.fall(id, dur)
	local m = B.model(id); if not m then return end
	local a = m:GetPivot(); local foot = a.Position - V(0, 3, 0)
	for _, d in ipairs(m:GetDescendants()) do if (d:IsA("BasePart") or d:IsA("Decal")) and d:GetAttribute("T0") == nil then d:SetAttribute("T0", d.Transparency) end end
	local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / dur, 0, 1); local e = ease(k)
		m:PivotTo(CFrame.new(foot) * a.Rotation * CFrame.Angles(math.rad(-80 * e), 0, 0) * CFrame.new(0, 3, 0))
		for _, d in ipairs(m:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Decal")) and d:GetAttribute("T0") then d.Transparency = d:GetAttribute("T0") + (1 - d:GetAttribute("T0")) * 0.6 * e end
		end
		if k >= 1 then break end
		RS.RenderStepped:Wait()
	end
end
function B.face(id, look) local m = B.model(id); if not m then return end; local p = m:GetPivot().Position; m:PivotTo(CFrame.lookAt(p, V(look.X, p.Y, look.Z))) end
-- name plates follow their fighter up the bracket
function B.plate(id) return workspace.TournamentSet:FindFirstChild("Plate_" .. B.NAME[id]) end
function B.platePos(t, i) return B.slot(t, i) + V(0, 0.6, 3.3) end
function B.showPlate(id, on)
	local p = B.plate(id); if not p then return end
	p.Transparency = on and 0 or 1
	for _, g in ipairs(p:GetDescendants()) do if g:IsA("SurfaceGui") then g.Enabled = on end end
end
function B.movePlate(id, pos, dur)
	local p = B.plate(id); if not p then return end
	local a = p.Position; local rot = p.CFrame.Rotation; local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / dur, 0, 1); local e = k * k * (3 - 2 * k)
		p.CFrame = rot + a:Lerp(pos, e) + V(0, 4 * math.sin(math.pi * k), 0)
		if k >= 1 then break end; RS.RenderStepped:Wait()
	end
end
function B.reset()
	for i, id in ipairs(B.ROSTER) do
		local m = B.model(id)
		for _, d in ipairs(m:GetDescendants()) do if (d:IsA("BasePart") or d:IsA("Decal")) and d:GetAttribute("T0") then d.Transparency = d:GetAttribute("T0") end end
		local s = B.slot(1, i) + V(0, 3, 0); m:PivotTo(CFrame.lookAt(s, s + V(0, 0, 10)))
		local p = B.plate(id); if p then p.CFrame = p.CFrame.Rotation + B.platePos(1, i); B.showPlate(id, true) end
	end
end
function B.pairCam(t, q)
	local s1, s2 = B.slot(t, 2 * q - 1), B.slot(t, 2 * q); local c = (s1 + s2) / 2
	local span = (s2 - s1).Magnitude
	return c + V(0, 5, span * 2.0 + 10), c + V(0, 5.0, -5)
end
-- one match resolved on the bracket: loser falls (plate hidden), winner and
-- his plate jump one tier up
function B.pair(t, q, win, los)
	local p0, l0 = B.pairCam(t, q)
	B.hold(p0, l0, 0.5, 55)
	task.spawn(B.fall, los, 0.6)
	task.delay(0.25, function() B.showPlate(los, false) end)
	task.delay(0.3, function() B.jump(win, t + 1, q, 0.9) end)
	task.delay(0.3, function() B.movePlate(win, B.platePos(t + 1, q), 0.9) end)
	local p1, l1 = p0 + V(0, 1.2, -2.5), l0 + V(0, 0.8, 0)
	B.cam(p0, l0, p1, l1, 1.4, nil, 55, 53)
	B.hold(p1, l1, 0.35, 53)
end
function B.hookPan()
	B.hold(O + V(0, 42, 100), O + V(0, 6, -14), 0.5, 70)
	B.cam(O + V(0, 42, 100), O + V(0, 6, -14), O + V(0, 7, 22), O + V(0, 6, -18), 1.0, B.easeCubic, 70, 60)
	B.hold(O + V(0, 7, 22), O + V(0, 6, -18), 0.3, 60)
	B.cam(O + V(-25, 5.2, 13), O + V(-25, 3.4, 0), O + V(25, 5.2, 13), O + V(25, 3.4, 0), 2.8, B.lin, 55, 55)
	B.hold(O + V(25, 5.2, 13), O + V(25, 3.4, 0), 0.3, 55)
end
function B.finals(R)
	local f1, f2 = B.slot(3, 1), B.slot(3, 2)
	B.face(R.SF1, f2); B.face(R.SF2, f1)
	local function sideCam(i, dur)
		local s = B.slot(3, i); local l = s + V(0, 3, 0); local dx = (i == 1) and 1 or -1
		B.cam(l + V(dx * 7, 1.5, 10), l, l + V(dx * 5, 1.2, 9), l, dur, nil, 50, 50)
	end
	sideCam(1, 1.1); sideCam(2, 1.1)
	local top = B.slot(4, 1) + V(0, 4, -1.6)
	B.cam(O + V(0, 14, 12), O + V(0, 12, -24), O + V(0, 21, -12), top, 1.6, B.easeCubic, 58, 50)
	B.hold(O + V(0, 21, -12), top, 0.6, 50)
end
-- the whole bracket story for one tournament: R = {QF1..QF4, SF1, SF2, F}
function B.all(R)
	B.reset(); task.wait(0.1)
	B.hookPan()
	for q = 1, 4 do
		local a, b = B.ROSTER[q * 2 - 1], B.ROSTER[q * 2]; local w = R["QF" .. q]
		B.pair(1, q, w, (w == a) and b or a)
	end
	for s = 1, 2 do
		local a, b = R["QF" .. (s * 2 - 1)], R["QF" .. (s * 2)]; local w = R["SF" .. s]
		B.pair(2, s, w, (w == a) and b or a)
	end
	B.finals(R)
	return "bracket done"
end
-- the champion's crowning (result video): winner jumps onto the trophy tier
function B.crown(R)
	local los = (R.F == R.SF1) and R.SF2 or R.SF1
	local top = B.slot(4, 1) + V(0, 3, 0)
	local p0, l0 = O + V(0, 16, 12), O + V(0, 12, -26)
	B.hold(p0, l0, 0.5, 55)
	task.spawn(B.fall, los, 0.6)
	task.delay(0.3, function() B.jump(R.F, 4, 1, 1.0) end)
	B.cam(p0, l0, O + V(0, 20, -20), top + V(0, 1.5, 0), 1.8, B.easeCubic, 55, 45)
	B.hold(O + V(0, 20, -20), top + V(0, 1.5, 0), 1.0, 45)
	return "crowned"
end

--------------------------------------------------------------------------
-- Takes run from the client log their own timeline (os.clock) after a local
-- sync flash, so the factory can cut them without a server log.
--------------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local Http = game:GetService("HttpService")
local takeLog
-- which build is filming (the factory refuses takes without the hand seals)
local function build()
	local f = {}
	for _, n in ipairs({"SealJutsu", "BetaRoster", "ChakraFlow"}) do
		if game:GetService("ReplicatedStorage"):FindFirstChild(n, true) then table.insert(f, n) end
	end
	return {place = game.Name, features = f}
end
B.build = build
function C.flash()
	local e0, b0 = Lighting.ExposureCompensation, Lighting.Brightness
	local t = os.clock()
	Lighting.ExposureCompensation = 6; Lighting.Brightness = 10
	task.wait(0.15)
	Lighting.ExposureCompensation = e0; Lighting.Brightness = b0
	return t
end
local function mark(kind, extra)
	local e = extra or {}; e.kind = kind; e.t = os.clock(); table.insert(takeLog.events, e)
end
-- bracket take for the "pick" tournament: hook (rush + pan over the 8) then,
-- once the matches are known (R), the champion's crowning
function B.pickTake(R)
	takeLog = {kind = "bracket", events = {}, build = build()}
	B.reset(); task.wait(0.2)
	B.hold(O + V(0, 42, 100), O + V(0, 6, -14), 0.6, 70)
	takeLog.flash = {now = C.flash()}
	task.wait(0.4)
	mark("hook")
	B.hookPan()
	mark("hook_end")
	if R and R.F then
		-- jump the bracket straight to the final state, then crown
		for q = 1, 4 do
			local a, b = B.ROSTER[q * 2 - 1], B.ROSTER[q * 2]; local w = R["QF" .. q]; local l = (w == a) and b or a
			task.spawn(B.fall, l, 0.05); B.showPlate(l, false)
		end
		for s = 1, 2 do
			local w = R["SF" .. s]; local l = (w == R["QF" .. (s * 2 - 1)]) and R["QF" .. (s * 2)] or R["QF" .. (s * 2 - 1)]
			local m = B.model(w); local p = B.slot(3, s) + V(0, 3, 0); m:PivotTo(CFrame.lookAt(p, p + V(0, 0, 10)))
			local pl = B.plate(w); if pl then pl.CFrame = pl.CFrame.Rotation + B.platePos(3, s) end
		end
		task.wait(0.2)
		mark("crown")
		B.crown(R)
		mark("crown_end")
	end
	return Http:JSONEncode(takeLog)
end

--------------------------------------------------------------------------
-- Devlog: the host (FactorySets.DevlogSet, the model with attribute NDHost —
-- the original Otsutsuki built by Sets.host) "talks" to the voice: the head
-- nods with the envelope (20 values a second), the mask moves over the jaw,
-- the eyes glow, and an arm gestures on cues. The host's parts are anchored
-- (built in Edit), so the take moves rigid groups itself, on this client.
-- opts = {env = {...0..1...}, rate = 20, cues = {{t=1.2, g="point"|"open"|"kunai"}, ...}, cam = "mid" | "close"}
--------------------------------------------------------------------------
local function host()
	local fs = workspace:FindFirstChild("FactorySets")
	local set = fs and fs:FindFirstChild("DevlogSet")
	if not set then return end
	for _, m in ipairs(set:GetChildren()) do
		if m:IsA("Model") and (m:GetAttribute("NDHost") or m.Name == "Shinobot") then return m end
	end
end
B.host = host
local function devlogCam(kind)
	local h = host(); if not h then return end
	local head = h.Head.Position
	local look = head + V(0, kind == "close" and 0 or -1.4, 0)
	local side = h.Head.CFrame.RightVector
	local dist = kind == "close" and 5 or 8.5
	local pos = look + h.Head.CFrame.LookVector * dist + side * (kind == "close" and -0.6 or -1.2) + V(0, kind == "close" and 0.2 or 0.6, 0)
	C.mode = "bracket"; C.cf = CFrame.lookAt(pos, look); C.fov = 50
	return pos, look
end
B.devlogCam = devlogCam
-- body part -> every part welded onto it (costume meshes, face plates, kunai)
local function rigid(model)
	local g = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("WeldConstraint") and d.Part0 and d.Part1 then
			g[d.Part0] = g[d.Part0] or {d.Part0}
			table.insert(g[d.Part0], d.Part1)
		end
	end
	return g
end
local function collect(g, model, names)
	local list = {}
	for _, n in ipairs(names) do
		local p = model:FindFirstChild(n)
		if p then for _, q in ipairs(g[p] or {p}) do table.insert(list, {part = q, base = q.CFrame}) end end
	end
	return list
end
local function jointPivot(model, name)
	local j = model:FindFirstChild(name, true)
	return j and j:IsA("Motor6D") and j.Part0 and (j.Part0.CFrame * j.C0) or nil
end
function B.devlogTake(opts)
	takeLog = {kind = "devlog", events = {}, build = build()}
	local h = host()
	if not h then return "no host: run Sets.devlog() in Edit first" end
	local g = rigid(h)
	local headG = collect(g, h, {"Head"})
	local rArm = collect(g, h, {"RightUpperArm", "RightLowerArm", "RightHand"})
	local lArm = collect(g, h, {"LeftUpperArm", "LeftLowerArm", "LeftHand"})
	local upper = collect(g, h, {"UpperTorso"})
	local neckP, rShP, lShP, waistP = jointPivot(h, "Neck"), jointPivot(h, "RightShoulder"), jointPivot(h, "LeftShoulder"), jointPivot(h, "Waist")
	local mask = h:FindFirstChild("Host__Mask") or h:FindFirstChild("Robot__Visor")
	local maskBase = mask and mask.CFrame
	-- eye glow: a small light in the head, Rinnegan purple
	local glow = Instance.new("PointLight"); glow.Color = Color3.fromRGB(190, 150, 255); glow.Range = 6; glow.Brightness = 0; glow.Shadows = false; glow.Parent = h.Head
	local function rot(pivot, ang) return pivot * ang * pivot:Inverse() end
	local function place(list, R) for _, x in ipairs(list) do if x.part ~= mask then x.part.CFrame = R * x.base end end end
	local pos, look = devlogCam(opts.cam or "mid")
	task.wait(0.4)
	takeLog.flash = {now = C.flash()}
	task.wait(opts.lead or 0.5)
	mark("voice") -- the voice track starts here
	local env, rate = opts.env or {}, opts.rate or 20
	local cues = opts.cues or {}
	local t0 = os.clock()
	local total = #env / rate + 0.5
	while os.clock() - t0 < total do
		local t = os.clock() - t0
		local e = env[math.clamp(math.floor(t * rate) + 1, 1, math.max(1, #env))] or 0
		-- whole upper body: breathing and a slow sway about the waist
		local W = waistP and rot(waistP, CFrame.Angles(math.sin(t * 1.7) * 0.012, math.rad(2.5 * math.sin(t * 0.4)), 0)) or CFrame.new()
		-- head: nods with the voice, a slow look around
		local Hh = neckP and rot(neckP, CFrame.Angles(math.rad(-5 * e + 2 * math.sin(t * 0.9)), math.rad(6 * math.sin(t * 0.55)), 0)) or CFrame.new()
		-- gestures: a cue raises the right arm (point / kunai) or both (open) for ~1.2 s
		local gR, gL, kind = 0, 0, nil
		for _, c in ipairs(cues) do
			if t >= c.t and t < c.t + 1.2 then
				local k = math.sin(math.pi * (t - c.t) / 1.2); kind = c.g
				gR = k; if c.g == "open" then gL = k end
			end
		end
		local ra = kind == "kunai" and CFrame.Angles(math.rad(-110 * gR), 0, math.rad(-20 * gR)) or CFrame.Angles(math.rad(-75 * gR), 0, math.rad(-10 * gR))
		local Rr = rShP and rot(rShP, ra) or CFrame.new()
		local Rl = lShP and rot(lShP, CFrame.Angles(math.rad(-60 * gL), 0, math.rad(25 * gL))) or CFrame.new()
		place(upper, W)
		place(headG, W * Hh)
		place(rArm, W * Rr)
		place(lArm, W * Rl)
		if mask and maskBase then mask.CFrame = W * Hh * maskBase * CFrame.new(0, -0.035 * e, -0.006 * e) end
		glow.Brightness = 0.2 + 1.4 * e
		-- slow push-in on the camera
		local k = math.clamp(t / total, 0, 1)
		C.cf = CFrame.lookAt(pos:Lerp(look + (pos - look) * 0.82, k), look)
		RS.RenderStepped:Wait()
	end
	-- back to rest
	for _, list in ipairs({upper, headG, rArm, lArm}) do place(list, CFrame.new()) end
	if mask and maskBase then mask.CFrame = maskBase end
	glow:Destroy()
	mark("voice_end")
	return Http:JSONEncode(takeLog)
end

--------------------------------------------------------------------------
-- Cinematic shots v3 ("LEGENDARY FIGHTS", 04/11). The server plays a written
-- scene (ShotRunner.scene / S.takes) and sets workspace.NDBeat = "<beat>#<n>"
-- and workspace.NDTake = take number; each beat takes the shot listed for it
-- in that take, so the same scene played three times gives three angles of
-- every beat, cut together in CapCut from ONE raw recording.
--
-- Every framing is SOLVED for the 9:16 area kept from the recording (full
-- viewport height, 830/1480 of it in width): the camera backs off until the
-- subject's real parts (hair spikes included) fit inside it. All cameras stay
-- on one side of the fight axis (180 degree rule), locked at the face-off.
--   B.scene({T1 = {faceoff = {kind = "fit", yaw = 48}, ...}, T2 = {...}})
-- Shot kinds (who = "A" the human seat, "B" the bot; "X" adds shadow clones):
--   fit    both bodies whole            who ("AB"/"ABX"), yaw (>0 toward A's back), pitch, fov, m (margin)
--          top = true: from above, the fight axis along the frame height
--   close  head framed (hair included)  who, ang (deg off the face), pitch, drop, parts = "mcu" adds the hands
--   ots    over `who`'s shoulder onto the other   ang, pitch
--   track  follows `who` from the side  yaw, m
--   seq = {{at = 0, ...shot}, {at = 1.4, ...shot}} switches shot inside a beat
-- No push-ins on fitted shots (they push the near fighter out of frame), and
-- no depth of field (it made the capture stutter): colour + bloom only.
--------------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local CROPW = 830 / 1480
local SIDE_SIGN = 1
C.shot3, C.shotT = nil, 0
local partCache = {}
local function isHead(n) return n == "Head" or n:sub(1, 6) == "Head__" end
local function isHand(n) return n == "LeftHand" or n == "RightHand" or n:sub(1, 10) == "LeftHand__" or n:sub(1, 11) == "RightHand__" end
local function partsOf(m, mode)
	local e = partCache[m]
	local t = os.clock()
	if not e or t - e.t > 0.35 then
		e = {t = t, head = {}, hands = {}, body = {}}
		local r = hrp(m)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.9 then
				if isHead(d.Name) then table.insert(e.head, d) end
				if isHand(d.Name) then table.insert(e.hands, d) end
				if r and (d.Position - r.Position).Magnitude < 5.5 and d.Size.Magnitude < 7 then table.insert(e.body, d) end
			end
		end
		partCache[m] = e
	end
	return e[mode]
end
local SIGNS = {V(1, 1, 1), V(1, 1, -1), V(1, -1, 1), V(1, -1, -1), V(-1, 1, 1), V(-1, 1, -1), V(-1, -1, 1), V(-1, -1, -1)}
local function addCorners(pts, p)
	local cf, h = p.CFrame, p.Size / 2
	for _, s in ipairs(SIGNS) do table.insert(pts, cf * (h * s)) end
end
local extraT, extras = 0, {}
local function extraModels()
	if os.clock() - extraT < 0.25 then return extras end
	extraT = os.clock(); extras = {}
	local A, Bm, duel = duelModels()
	local rb = hrp(Bm)
	if not rb then return extras end
	local seen = {}
	for _, root in ipairs({duel, workspace:FindFirstChild("NinjaDuelFX"), workspace:FindFirstChild("NinjaDuelBodies")}) do
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d.Name == "Head" and d:IsA("BasePart") then
				local m = d:FindFirstAncestorOfClass("Model")
				if m and m ~= A and m ~= Bm and not seen[m] and (d.Position - rb.Position).Magnitude < 22 then
					seen[m] = true; table.insert(extras, m)
				end
			end
		end
	end
	return extras
end
-- Minato's planted seal (Client/Effects FX:seal draws a "Seal" glyph and a
-- three-pronged kunai in workspace.NinjaDuelFX): the one nearest Neji (B).
local function sealPoint()
	local fx = workspace:FindFirstChild("NinjaDuelFX")
	local _, Bm = duelModels()
	local rb = hrp(Bm)
	local best, bestD
	for _, m in ipairs(fx and fx:GetChildren() or {}) do
		if m.Name == "Seal" and m:IsA("Model") then
			local disc = m:FindFirstChildWhichIsA("BasePart")
			if disc then
				local d = rb and (disc.Position - rb.Position).Magnitude or 0
				if not bestD or d < bestD then best, bestD = disc.Position, d end
			end
		end
	end
	return best
end
B.sealPoint = sealPoint
local function subject(who)
	local A, Bm = duelModels()
	if who == "B" then return Bm, A end
	return A, Bm
end
local function gather(sp)
	local who = sp.who or "AB"
	local A, Bm = duelModels()
	local pts = {}
	local function add(m)
		if not m then return end
		for _, p in ipairs(partsOf(m, "body")) do addCorners(pts, p) end
	end
	if who:find("A") then add(A) end
	if who:find("B") then add(Bm) end
	if who:find("S") then
		local sp0 = sealPoint()
		if sp0 then for _, sg in ipairs(SIGNS) do table.insert(pts, sp0 + V(0.9, 1.1, 0.9) * sg + V(0, 0.9, 0)) end end
	end
	if who:find("X") then
		for _, m in ipairs(extraModels()) do
			local cf, size = m:GetBoundingBox()
			if size.Magnitude < 12 then
				for _, s in ipairs(SIGNS) do table.insert(pts, cf * (size / 2 * s)) end
			end
		end
	end
	return pts
end
local AXIS = V(0, 0, -1)
local function lockAxis()
	local A, Bm = duelModels(); local ra, rb = hrp(A), hrp(Bm)
	if not (ra and rb) then return end
	local ax = flat(rb.Position - ra.Position)
	if ax.Magnitude > 0.5 then AXIS = ax.Unit end
end
local function SIDE() return AXIS:Cross(Vector3.yAxis) * SIDE_SIGN end
local function tilt(dir, pitch)
	local p = math.rad(pitch or 0)
	return (dir * math.cos(p) + Vector3.yAxis * math.sin(p)).Unit
end
local function sideDir(yaw, pitch)
	local y = math.rad(yaw or 0)
	return tilt(SIDE() * math.cos(y) - AXIS * math.sin(y), pitch)
end
local function frontDir(who, ang, pitch)
	local front = (who == "B") and -AXIS or AXIS
	local a = math.rad(ang or 35)
	return tilt(front * math.cos(a) + SIDE() * math.sin(a), pitch)
end
local function behindDir(who, ang, pitch)
	local front = (who == "B") and -AXIS or AXIS
	local a = math.rad(ang or 28)
	return tilt(-front * math.cos(a) + SIDE() * math.sin(a), pitch)
end
-- distance at which every point fits the kept 9:16 area, camera looking at c
local function solve(pts, c, back, fov, m, upHint)
	local fwd = -back
	local right = fwd:Cross(upHint)
	right = right.Magnitude > 1e-3 and right.Unit or Vector3.xAxis
	local up = right:Cross(fwd).Unit
	local tv = math.tan(math.rad(fov) / 2) * m
	local th = tv * CROPW
	local d = 0.5
	for _, p in ipairs(pts) do
		local r = p - c
		local need = r:Dot(back) + math.max(math.abs(r:Dot(right)) / th, math.abs(r:Dot(up)) / tv)
		if need > d then d = need end
	end
	return d
end
local function bboxCenter(pts)
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(pts) do lo = lo:Min(p); hi = hi:Max(p) end
	return (lo + hi) / 2, hi - lo
end
local SH = {}
function SH.fit(sp)
	local pts = gather(sp)
	if #pts == 0 then return end
	local c, size = bboxCenter(pts)
	c += V(0, (sp.look or 0) * size.Y, 0)
	local dir = sp.top and tilt(SIDE() * 0.25 - AXIS * 0.02, sp.pitch or 80) or sideDir(sp.yaw, sp.pitch or 6)
	return pts, c, dir, sp.fov or 46, sp.m or 0.84
end
function SH.close(sp)
	local M = subject(sp.who)
	if not M then return end
	local pts = {}
	for _, p in ipairs(partsOf(M, "head")) do addCorners(pts, p) end
	if sp.parts == "mcu" then for _, p in ipairs(partsOf(M, "hands")) do addCorners(pts, p) end end
	if #pts == 0 then return end
	local c, size = bboxCenter(pts)
	c -= V(0, (sp.drop or 0.35) * math.max(size.Y, 1.5), 0)
	return pts, c, frontDir(sp.who, sp.ang, sp.pitch or -4), sp.fov or 30, sp.m or 0.86
end
function SH.ots(sp)
	local M, O = subject(sp.who)
	if not (M and O) then return end
	local pts = {}
	for _, p in ipairs(partsOf(O, "body")) do addCorners(pts, p) end
	for _, p in ipairs(partsOf(M, "head")) do addCorners(pts, p) end
	if #pts == 0 then return end
	return pts, (bboxCenter(pts)), behindDir(sp.who, sp.ang, sp.pitch or 6), sp.fov or 42, sp.m or 0.92
end
function SH.track(sp)
	local M = subject(sp.who)
	if not M then return end
	local pts = {}
	for _, p in ipairs(partsOf(M, "body")) do addCorners(pts, p) end
	if #pts == 0 then return end
	return pts, (bboxCenter(pts)), sideDir(sp.yaw, sp.pitch or 4), sp.fov or 40, sp.m or 0.6
end
-- The planted kunai in close-up, low, with B standing behind it (the hook).
-- dist: camera to kunai; h: camera height over the floor; lift: how far up
-- B's body the lens looks (0 = the kunai, 1 = B's head).
function SH.seal(sp)
	local at = sealPoint()
	local _, Bm = duelModels()
	local rb = hrp(Bm)
	if not (at and rb) then return end
	local toB = flat(rb.Position - at)
	toB = toB.Magnitude > 0.1 and toB.Unit or AXIS
	local side = toB:Cross(Vector3.yAxis)
	local floorY = at.Y
	local eye = at - toB * (sp.dist or 3.4) + side * (sp.off or 0.8) + V(0, sp.h or 0.9, 0)
	local look = at:Lerp(rb.Position + V(0, 1.2, 0), sp.lift or 0.22)
	return nil, eye, look, sp.fov or 38, floorY
end
B.SH = SH
-- film look: a little contrast and bloom (no depth of field: it stuttered)
local function film(on)
	for _, n in ipairs({"NDFilmDOF", "NDFilmCC", "NDFilmBloom"}) do local e = Lighting:FindFirstChild(n); if e then e:Destroy() end end
	if not on then return end
	local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "NDFilmCC"; cc.Contrast = 0.12; cc.Saturation = 0.12; cc.Parent = Lighting
	local bl = Instance.new("BloomEffect"); bl.Name = "NDFilmBloom"; bl.Intensity = 0.7; bl.Threshold = 1.4; bl.Size = 28; bl.Parent = Lighting
end
B.film = film
local sm = {}
local function pickSub(spec, t)
	if not spec.seq then return spec, 0 end
	local cur, idx = spec.seq[1], 1
	for i, s in ipairs(spec.seq) do if t >= (s.at or 0) then cur, idx = s, i end end
	return cur, idx
end
pcall(function() RS:UnbindFromRenderStep("NDClipShot") end)
RS:BindToRenderStep("NDClipShot", Enum.RenderPriority.Last.Value + 2, function(dt)
	if not C.shot3 then return end
	C.mode = "shot"
	C.shotT += dt
	if not C.axisLocked and C.shotT > 0.12 and C.beatName == "faceoff" then
		lockAxis(); C.axisLocked = true
	end
	local sp, idx = pickSub(C.shot3, C.shotT)
	if idx ~= sm.idx then sm.idx = idx; sm.snap = true end
	local fn = SH[sp.kind or "fit"]
	if not fn then return end
	local pts, c, dir, fov, m = fn(sp)
	if not pts and typeof(c) == "Vector3" and typeof(dir) == "Vector3" then
		-- a placed lens (SH.seal): eye c looking at dir, eased in
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local eye, look = c, dir
		if sm.snap or not sm.eye then sm.eye, sm.look, sm.snap = eye, look, false
		else sm.eye = dampN(sm.eye, eye, sp.rate or 6, dt); sm.look = dampN(sm.look, look, sp.rate or 6, dt) end
		cam.CFrame = CFrame.lookAt(sm.eye, sm.look)
		cam.FieldOfView = fov
		sm.c = nil
		return
	end
	if not pts then return end
	local upHint = sp.top and AXIS or Vector3.yAxis
	local d = math.clamp(solve(pts, c, dir, fov, m, upHint), sp.minD or 1.6, sp.maxD or 70)
	if sm.snap or not sm.c then
		sm.c, sm.dir, sm.d, sm.snap = c, dir, d, false
	else
		local rate = sp.rate or 7
		sm.c = dampN(sm.c, c, rate, dt)
		sm.dir = dampN(sm.dir, dir, rate * 0.7, dt).Unit
		sm.d = dampN(sm.d, d, (d > sm.d) and 12 or 2.5, dt)
	end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local eye = sm.c + sm.dir * sm.d
	-- never under the arena floor (low angles near the ground)
	local A, Bm = duelModels(); local ra, rb = hrp(A), hrp(Bm)
	if ra and rb and not sp.top then
		local floorY = math.min(ra.Position.Y, rb.Position.Y) - 2.9
		if eye.Y < floorY + (sp.minH or 0.6) then eye = V(eye.X, floorY + (sp.minH or 0.6), eye.Z) end
	end
	cam.CFrame = CFrame.lookAt(eye, sm.c, upHint)
	cam.FieldOfView = fov
end)
local beatConn, takeConn
function B.scene(maps, opts)
	opts = opts or {}
	film(opts.film ~= false)
	local function apply()
		local v = workspace:GetAttribute("NDBeat") or ""
		local name = v:match("^(.-)#") or v
		local take = workspace:GetAttribute("NDTake") or 1
		local map = maps["T" .. tostring(take)] or maps.T1 or maps
		C.shot3 = map[name] or map.default or {kind = "fit"}
		C.shotT = 0; C.beatName = name; sm.snap = true; sm.idx = nil
	end
	if beatConn then beatConn:Disconnect() end
	if takeConn then takeConn:Disconnect() end
	beatConn = workspace:GetAttributeChangedSignal("NDBeat"):Connect(apply)
	takeConn = workspace:GetAttributeChangedSignal("NDTake"):Connect(function() C.axisLocked = false; apply() end)
	C.mode = "shot"
	apply()
	return "scene camera on (" .. tostring(workspace:GetAttribute("NDBeat")) .. ")"
end
function B.sceneOff()
	if beatConn then beatConn:Disconnect(); beatConn = nil end
	if takeConn then takeConn:Disconnect(); takeConn = nil end
	film(false); C.mode = "fight"; C.shot3 = nil
end

_G.NDHideUI(true)
return "ClipKit ready (mode " .. C.mode .. ")"
