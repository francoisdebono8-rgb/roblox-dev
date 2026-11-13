--!nocheck
-- ClipJudge (FILM place): what a viewer sees of a fighter, and what happens in a match.
-- Shared by the filming assistant F4 (to judge a take), NDDirector (to choose
-- the angle itself) and NDReplay (to rank the moments of a match). Asked by the
-- CM on 13/11 (claude/demandes-outilleur-prises-humain-2026-11-13): a take F4
-- lets through must be a take the owner does not reject.
--   visible(cam, model, opts)   share of the face / the body hidden, by kind of blocker
--   shadow(model)               share of the face / the body the sun does not reach
--   backlit(cam, model)         the lens sees the side the sun does not light
--   facing(cam, model)          angle between the fighter's look and the lens
--   gaze(model, point)          angle between the head (or the chest) and a point
--   share(camCF, fov, model)    the fighter's height as a share of the 9:16 band
--   arena() / inside(pos)       the enclosure (World.WALL_RADIUS)
--   events(prev, cur, t, memo)  what happened between two states of the duel
--   moments(events, opts)       the strongest moments of a match, in real order
local Sight = require(script.Parent.ClipSight)
local Lighting = game:GetService("Lighting")

local J = {}
local V = Vector3.new
local function flat(v) return V(v.X, 0, v.Z) end
local function angle(a, b)
	if a.Magnitude < 1e-3 or b.Magnitude < 1e-3 then return 0 end
	return math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)))
end
J.flat, J.angle = flat, angle

-- The rig's own parts give the geometry (the look meshes ride on them).
local cache = setmetatable({}, {__mode = "k"})
function J.rig(model)
	local e = cache[model]
	local now = os.clock()
	if e and now - e.t < 0.5 then return e end
	e = {t = now, parts = {}, all = {}}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			e.parts[d.Name] = e.parts[d.Name] or d
			if d.Transparency < 0.9 and d.Name ~= "HumanoidRootPart" and d.Size.Magnitude > 0.3 then table.insert(e.all, d) end
		end
	end
	local p = e.parts
	e.head = p.Head or p.Head__Skin
	e.torso = p.UpperTorso or p.Torso
	e.root = p.HumanoidRootPart or model.PrimaryPart
	cache[model] = e
	return e
end

-- Points a viewer reads: the face (5), the trunk (4), hands and feet.
function J.samples(model)
	local r = J.rig(model)
	local face, body = {}, {}
	local h = r.head
	if h then
		local s = h.Size
		for _, o in {V(0, 0, -0.45), V(-0.3, 0.2, -0.4), V(0.3, 0.2, -0.4), V(-0.3, -0.25, -0.4), V(0.3, -0.25, -0.4)} do
			table.insert(face, (h.CFrame * CFrame.new(o.X * s.X, o.Y * s.Y, o.Z * s.Z)).Position)
		end
	end
	local t = r.torso
	if t then
		local s = t.Size
		for _, o in {V(-0.35, 0.3, 0), V(0.35, 0.3, 0), V(-0.3, -0.35, 0), V(0.3, -0.35, 0)} do
			table.insert(body, (t.CFrame * CFrame.new(o.X * s.X, o.Y * s.Y, 0)).Position)
		end
	end
	for _, n in {"LeftHand", "RightHand", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg"} do
		local p = r.parts[n]
		if p then table.insert(body, p.Position) end
	end
	return face, body
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
-- What stops the segment a -> b: a queryable opaque part, the unqueryable decor
-- (`decor`: a Sight.subset, all of it by default), or one of `parts`.
local function blocker(a, b, ignore, parts, decor)
	local exclude = table.clone(ignore)
	local dir = b - a
	local len = dir.Magnitude
	if len < 1e-3 then return nil end
	local best, bestT = nil, 0.97
	for _ = 1, 5 do
		rayParams.FilterDescendantsInstances = exclude
		local hit = workspace:Raycast(a, dir, rayParams)
		if not hit then break end
		local p = hit.Instance
		if p.Transparency < 0.6 and p.LocalTransparencyModifier < 0.6 then
			local t = (hit.Position - a).Magnitude / len
			if t < bestT then best, bestT = p, t end
			break
		end
		table.insert(exclude, p)
	end
	local d, dt = Sight.decor(a, b, 0.03, decor)
	if d and dt < bestT then best, bestT = d, dt end
	if parts and #parts > 0 then
		local q, qt = Sight.parts(a, b, parts, 0.03)
		if q and qt < bestT then best, bestT = q, qt end
	end
	return best
end
J.blocker = blocker

local FX = {NinjaDuelFX = true, Effects = true, NinjaUltimateFX = true, VfxMesh = true, WorldMemory = true, NDReplay = true}
-- "corps" (one of `others`), "clone" (any other body), "effet" (the game's
-- effects, and in the replay every ghost that is not a body), or "décor".
function J.kind(p, others)
	for _, m in others or {} do
		if m and p:IsDescendantOf(m) then return "corps" end
	end
	local m = p:FindFirstAncestorWhichIsA("Model")
	while m and m ~= workspace do
		if m:FindFirstChildOfClass("Humanoid") then return "clone" end
		m = m.Parent and m.Parent:IsA("Model") and m.Parent or nil
	end
	local a = p
	while a and a ~= workspace do
		if FX[a.Name] then return "effet" end
		a = a.Parent
	end
	return "décor"
end
-- A readable name for what blocks: the model (or the effect) it belongs to.
function J.name(p)
	local a = p
	while a.Parent and a.Parent ~= workspace and not FX[a.Parent.Name] and not (a.Parent:IsA("Folder") and a.Parent.Parent == workspace) do
		if a.Parent:IsA("Model") and a.Parent:FindFirstChildOfClass("Humanoid") then return a.Parent.Name end
		a = a.Parent
	end
	return a.Name
end

-- Share of the face and of the body hidden from `camPos`, by kind of blocker.
-- opts.ignore: instances never counted (the fighter himself is always ignored)
-- opts.parts: extra parts to test (the other body, clones, effect meshes: the
-- replay's ghosts and the game's look meshes are unqueryable)
-- opts.others: models counted as "corps"
-- opts.decor: a Sight.subset around the fighter (faster for many rays)
-- -> {face, body (0..1 hidden), faceBy = {kind = share}, bodyBy, what = {kind = name}}
function J.visible(camPos, model, opts)
	opts = opts or {}
	local face, body = J.samples(model)
	local ignore = {model}
	for _, x in opts.ignore or {} do table.insert(ignore, x) end
	local res = {face = 0, body = 0, faceBy = {}, bodyBy = {}, what = {}, nFace = #face, nBody = #body}
	local function count(list, by)
		if #list == 0 then return 0 end
		local hidden = 0
		for _, p in list do
			local b = blocker(camPos, p, ignore, opts.parts, opts.decor)
			if b then
				hidden += 1
				local k = J.kind(b, opts.others)
				by[k] = (by[k] or 0) + 1 / #list
				res.what[k] = res.what[k] or J.name(b)
			end
		end
		return hidden / #list
	end
	res.face = count(face, res.faceBy)
	res.body = count(body, res.bodyBy)
	return res
end

-- Share of the face and of the body the sun does not reach (the shadow of a
-- wall, a tree, the stand). Night: 1, 1, "nuit".
function J.shadow(model, decor)
	local sun = Lighting:GetSunDirection()
	if sun.Y < 0.02 then return 1, 1, "nuit" end
	local face, body = J.samples(model)
	local function shaded(list)
		if #list == 0 then return 0 end
		local n = 0
		for _, p in list do
			if blocker(p + sun * 0.6, p + sun * 300, {model}, nil, decor) then n += 1 end
		end
		return n / #list
	end
	return shaded(body), shaded(face)
end

-- The sun on the ground plane (unit), nil when it is (almost) overhead or down.
function J.sun()
	local sun = Lighting:GetSunDirection()
	local f = flat(sun)
	if sun.Y < 0.02 or f.Magnitude < 0.15 then return nil, sun end
	return f.Unit, sun
end
-- The lens sees the side of the fighter the sun does not light (backlight):
-- the angle around the fighter between the lens and the sun, in degrees.
function J.sunSide(camPos, model)
	local sunF = J.sun()
	if not sunF then return 0 end
	local r = J.rig(model)
	local at = r.root and r.root.Position or model:GetPivot().Position
	return angle(flat(camPos - at), sunF)
end

function J.facing(camPos, model)
	local r = J.rig(model)
	local cf = r.root and r.root.CFrame or model:GetPivot()
	return angle(flat(cf.LookVector), flat(camPos - cf.Position))
end

-- Where the fighter looks, against a point (the other fighter, the lens):
-- the head's angle, the chest's angle (ground plane), and the head's 3D angle.
function J.gaze(model, point)
	local r = J.rig(model)
	local h, t = r.head, r.torso or r.root
	if not h then return 0, 0, 0 end
	local head = angle(flat(h.CFrame.LookVector), flat(point - h.Position))
	local chest = t and angle(flat(t.CFrame.LookVector), flat(point - t.Position)) or head
	return head, chest, angle(h.CFrame.LookVector, point - h.Position)
end

-- The enclosure: centre and radius of the arena wall (World.WALL_RADIUS = 145).
J.WALL = 145
function J.arena()
	local c = workspace:GetAttribute("NDArenaCenter")
	if typeof(c) == "Vector3" then return c, J.WALL end
	local cy = workspace:FindFirstChild("Courtyard")
	if cy then
		local ok, cf = pcall(function() return cy:GetPivot() end)
		if ok and cf then return V(cf.Position.X, 0, cf.Position.Z), J.WALL end
	end
	return V(0, 0, 0), J.WALL
end
function J.inside(pos, margin)
	local c, r = J.arena()
	return flat(pos - c).Magnitude <= r - (margin or 3)
end

function J.height(model)
	local r = J.rig(model)
	if r.head and r.root then
		return math.max(3, (r.head.Position.Y + r.head.Size.Y * 0.9) - (r.root.Position.Y - 3))
	end
	return 5.5
end
-- The top of the hair and the soles: what "the fighter's height" means on screen.
function J.ends(model)
	local r = J.rig(model)
	local top = r.head and (r.head.Position + V(0, r.head.Size.Y * 0.9, 0)) or model:GetPivot().Position + V(0, 2.5, 0)
	local feet = (r.root and r.root.Position or model:GetPivot().Position) - V(0, 3, 0)
	return top, feet
end

-- The camera distance at which a fighter fills `share` of the frame height.
function J.maxDistance(model, fov, share)
	return J.height(model) / (2 * math.tan(math.rad(fov / 2)) * share)
end

-- A point in the kept 9:16 band of a camera (CFrame + vertical FOV), without a
-- Camera object: x, y in -1..1 inside the band (y up), depth in studs.
J.BAND = 9 / 16
function J.ndc(camCF, fov, p)
	local l = camCF:PointToObjectSpace(p)
	local depth = -l.Z
	if depth <= 1e-3 then return nil, nil, depth end
	local tv = math.tan(math.rad(fov / 2))
	return l.X / (depth * tv * J.BAND), l.Y / (depth * tv), depth
end
-- The fighter's height (hair to soles) as a share of the band's height.
function J.share(camCF, fov, model)
	local top, feet = J.ends(model)
	local _, yt, dt = J.ndc(camCF, fov, top)
	local _, yf, df = J.ndc(camCF, fov, feet)
	if not yt or not yf or dt <= 0 or df <= 0 then return 0 end
	return math.abs(yt - yf) / 2
end

----------------------------------------------------------------------------
-- What happens in a match: events between two states, and the strong moments.
-- A state: {phase, ko, A = fighter, B = fighter}; a fighter: {name, state,
-- reaction, health, maxHealth, attack, cast, parry, awaken} (the duel snapshot,
-- or the attributes the replay writes on its ghosts).
----------------------------------------------------------------------------
local REACT = {Knockdown = {4, "au sol"}, Launched = {5, "projeté en l'air"}, WallSplat = {5, "écrasé contre le mur"},
	Knockback = {3, "repoussé"}, Juggled = {3, "jonglé"}, Grabbed = {3, "saisi"}, Bound = {3, "immobilisé"}, HitStun = {1, "sonné"}}
J.REACT = REACT
function J.events(prev, cur, t, memo)
	local out = {}
	if not prev or not cur then return out end
	memo = memo or {}
	-- who: the fighter it happens to; actor: the one the camera should follow (the hitter for a hit)
	local function add(who, kind, w, text, actor) table.insert(out, {t = t, who = who, kind = kind, w = w, text = text, actor = actor or who}) end
	local ko = false
	for _, k in {"A", "B"} do
		local a, b = prev[k], cur[k]
		if a and b then
			local name = b.name or k
			local ok = k == "A" and "B" or "A"
			local o = cur[ok]
			local oname = o and o.name or "l'adversaire"
			if b.health and a.health then
				if b.health <= 0 and a.health > 0 then
					ko = true
					add(k, "ko", 10, "K.O. : " .. name .. " tombe", ok)
				elseif b.health < a.health - 0.5 then
					local share = (a.health - b.health) / math.max(1, b.maxHealth or 100)
					add(k, "touche", 3 + 20 * share, string.format("%s frappe %s (−%d PV)", oname, name, math.floor(a.health - b.health + 0.5)), ok)
				end
			end
			local r = b.reaction and REACT[b.reaction]
			if r and b.reaction ~= a.reaction then add(k, "réaction", r[1], name .. " " .. r[2], ok) end
			local what = b.cast or b.attack
			if b.state ~= a.state then
				if b.state == "TechniqueChannel" then add(k, "jutsu", 3, name .. " prépare " .. (what or "un jutsu"))
				elseif b.state == "TechniqueActive" then add(k, "jutsu", 5, name .. " lance " .. (what or "son jutsu"))
				elseif b.state == "Dodging" then add(k, "esquive", 2, name .. " esquive")
				elseif b.state == "Rush" or b.state == "Pursuit" then add(k, "fonce", 2, name .. " fonce sur " .. oname)
				elseif b.state == "Guarding" then add(k, "garde", 1, name .. " se met en garde")
				elseif b.state == "Startup" then add(k, "coup", 1, name .. " attaque" .. (what and (" (" .. what .. ")") or "")) end
			elseif b.state == "Startup" and b.attack and b.attack ~= a.attack then
				add(k, "coup", 1, name .. " enchaîne (" .. b.attack .. ")")
			end
			if (b.parry or 0) > (a.parry or 0) then add(k, "parade", 4, name .. " pare") end
			if (b.awaken or 0) > (a.awaken or 0) then add(k, "éveil", 6, name .. " s'éveille") end
		end
	end
	if cur.ko and not prev.ko and not ko and cur.A and cur.B then
		local loser = (cur.A.health or 1) <= (cur.B.health or 1) and "A" or "B"
		add(loser, "ko", 10, "K.O. : " .. (cur[loser].name or loser) .. " tombe")
	end
	-- A reversal: the one ahead on health changes.
	if cur.A and cur.B and cur.A.health and cur.B.health then
		local lead = cur.A.health / math.max(1, cur.A.maxHealth or 100) - cur.B.health / math.max(1, cur.B.maxHealth or 100)
		local leader = lead > 0.04 and "A" or lead < -0.04 and "B" or nil
		if leader and memo.leader and leader ~= memo.leader then
			add(leader, "retournement", 6, "retournement : " .. (cur[leader].name or leader) .. " repasse devant")
		end
		if leader then memo.leader = leader end
	end
	return out
end

-- The strongest moments of a list of events (seconds), in real order.
-- opts: n (4), len (longest moment, 6 s), pre (0.8 s before the first event),
-- post (1.5 s after the last), t0 / t1 (the range).
-- -> {score, perMinute, dead (share of the time with nothing within 1.5 s), moments = {{from, to, score, lines}}}
function J.moments(events, opts)
	opts = opts or {}
	local n, len, pre, post = opts.n or 4, opts.len or 6, opts.pre or 0.8, opts.post or 1.5
	local list = table.clone(events)
	table.sort(list, function(a, b) return a.t < b.t end)
	local t0 = opts.t0 or (list[1] and list[1].t or 0)
	local t1 = opts.t1 or (list[#list] and list[#list].t or t0)
	local total = 0
	for _, e in list do total += e.w end
	local dur = math.max(1e-3, t1 - t0)
	-- dead time: no event within 1.5 s
	local live, at = 0, t0
	for _, e in list do
		local a, b = math.max(at, e.t - 1.5), math.min(t1, e.t + 1.5)
		if b > a then live += b - a; at = b end
	end
	local chosen = {}
	local function overlaps(a, b)
		for _, m in chosen do if a < m.to and b > m.from then return true end end
		return false
	end
	for _ = 1, n do
		local best = nil
		for i, e in list do
			local from = math.max(t0, e.t - pre)
			if not overlaps(from, from + 0.01) then
				local score, last = 0, e
				for j = i, #list do
					local f = list[j]
					if f.t + post - from > len then break end
					score += f.w
					last = f
				end
				local to = math.min(t1 + post, last.t + post)
				if not overlaps(from, to) and (not best or score > best.score) then best = {from = from, to = to, score = score, i = i, last = last} end
			end
		end
		if not best or best.score <= 0 then break end
		best.lines = {}
		for j = best.i, #list do
			local f = list[j]
			if f.t > best.last.t then break end
			table.insert(best.lines, {t = f.t, text = f.text, w = f.w, who = f.who, actor = f.actor, kind = f.kind})
		end
		best.i, best.last = nil, nil
		table.insert(chosen, best)
	end
	table.sort(chosen, function(a, b) return a.from < b.from end)
	return {score = total, perMinute = total / dur * 60, dead = 1 - math.min(1, live / dur), duration = dur, moments = chosen}
end

return J
