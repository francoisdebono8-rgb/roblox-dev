-- The inspirations' moods in Konoha (DEC-041, user 14/11 21 h 49: « avec des
-- petites animations, tu comprends leur état d'esprit »). Naruto can't keep
-- still and shows off; Sasuke leans apart, arms crossed, looking away (now and
-- then a glance at you, then away again); Lee trains: quick punches on the
-- spot, bouncing. On the player's screen only (Motor6D.Transform, never
-- replicated), on the master models of Server/Hub, over their guard stance.
--
-- An ANIMATEUR clip named "Mood.<kit>" (Client/AuthoredClips) replaces these
-- code poses as soon as it exists: these are the placeholders that make the
-- three readable until then.
local Moods={}
local A,r=CFrame.Angles,math.rad

local function wave(t,speed,phase) return math.sin(t*speed+(phase or 0)) end
-- 0 most of the time, 1 for `hold` seconds every `every` seconds (eased).
local function every(t,period,hold,offset)
	local u=(t+(offset or 0))%period
	if u>hold then return 0 end
	return math.sin(math.pi*u/hold)
end

-- Each mood: the joints' rotations (and the root's lift) at time t.
Moods.Poses={
	-- Naruto: hands behind the head, bouncing on his heels, swaying, a big
	-- grin to the side now and then.
	Legion=function(t)
		local bounce=math.abs(wave(t,4.2))*.18
		local sway=wave(t,2.1)
		local grin=every(t,5,1.2)
		return {
			Root=CFrame.new(0,bounce,0)*A(0,0,r(3*sway)),
			Waist=A(r(-4),r(8*sway),0),
			Neck=A(r(-6),r(-10*sway+24*grin),r(10*grin)),
			LeftShoulder=A(r(118),r(10),r(-30)),RightShoulder=A(r(118),r(-10),r(30)),
			LeftElbow=A(r(62),0,0),RightElbow=A(r(62),0,0),
			LeftHip=A(r(-4),0,r(-2)),RightHip=A(r(4),0,r(2)),
		}
	end,
	-- Sasuke: arms crossed tight, weight on one hip, head away; every six
	-- seconds a short glance toward you, then away again.
	Lion=function(t)
		local breath=wave(t,1.4)
		local glance=every(t,6,1.6,2)
		return {
			Root=CFrame.new(0,.03*breath,0)*A(0,0,r(-4)),
			Waist=A(r(-2+breath),r(10),r(2)),
			Neck=A(r(8-6*glance),r(-34+30*glance),0),
			LeftShoulder=A(r(16),r(28),r(10)),RightShoulder=A(r(22),r(-30),r(-10)),
			LeftElbow=A(r(34),0,0),RightElbow=A(r(26),0,0),
			LeftHip=A(r(6),0,r(-8)),RightHip=A(r(-8),0,r(6)),
			RightKnee=A(r(-16),0,0),
		}
	end,
	-- Lee: punches on the spot, one arm then the other, bouncing like a
	-- boxer; every eight seconds a fist raised high (« YOSH! »).
	Leaf=function(t)
		local beat=t*5
		local side=math.floor(beat)%2
		local hit=math.sin(math.pi*(beat%1))
		local bounce=math.abs(wave(t,7))*.12
		local cheer=every(t,8,1.4,5)
		local rs=if side==0 then hit else 0
		local ls=if side==1 then hit else 0
		return {
			Root=CFrame.new(0,bounce+.2*cheer,0),
			Waist=A(r(-6),r(18*(rs-ls)),0),
			Neck=A(r(4),r(-8*(rs-ls)),0),
			RightShoulder=A(r(30*rs+100*cheer),r(-10*rs),0),RightElbow=A(r(-64*rs-60*cheer),0,0),
			LeftShoulder=A(r(30*ls),r(10*ls),0),LeftElbow=A(r(-64*ls),0,0),
			LeftHip=A(r(-8),0,r(-6)),RightHip=A(r(10),0,r(6)),
			LeftKnee=A(r(-14),0,0),RightKnee=A(r(-10),0,0),
		}
	end,
}

-- The joints of a master model, by name (cached on the model).
local joints=setmetatable({},{__mode="k"})
function Moods.joints(model)
	local j=joints[model]
	if j then return j end
	j={}
	for _,d in model:GetDescendants() do
		if d:IsA("Motor6D") then j[d.Name]=d end
	end
	joints[model]=j
	-- The portraits are anchored part by part (Server/Portraits.strip): on
	-- this screen only, the limbs hang from the root so the joints move them.
	local root=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d~=root then d.Anchored=false end
	end
	return j
end

-- Plays `id`'s mood on `model` at time t; `clip` (optional) samples an
-- authored clip instead (name → joint CFrames). Returns whether it played.
function Moods.apply(model,id,t,clip)
	local pose=if clip then clip(t) else (Moods.Poses[id] and Moods.Poses[id](t))
	if not pose then return false end
	local j=Moods.joints(model)
	for name,cf in pose do
		local motor=j[name]
		if motor then motor.Transform=cf end
	end
	return true
end
-- Back to the plain stance.
function Moods.clear(model)
	for _,motor in Moods.joints(model) do motor.Transform=CFrame.identity end
end

return Moods
