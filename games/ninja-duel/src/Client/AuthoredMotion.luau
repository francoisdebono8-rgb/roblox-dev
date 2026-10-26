-- Blender-authored body animation (DEC Blender-first pipeline): clips made in
-- Blender (tools/blender) and exported as joint transforms (AuthoredClips),
-- played by the motion engine instead of its procedural poses where a clip
-- exists. Gameplay, physics and timing stay the server's: every clip is
-- time-warped onto the server's real phases through its markers, so the
-- contact frame lands on the hit and the release frame on the jutsu.
--
-- Clip names: "<fighterId>.<move>" for strikes (Lion.Light1),
-- "<fighterId>.<techniqueId>.<part>" for techniques (Lion.FireBloom.Channel /
-- .Hold / .Release / .Recover), "<fighterId>.<name>" for states.
local Authored={}
local ok,DATA=pcall(function() return require(script.Parent.AuthoredClips) end)
if not ok or type(DATA)~="table" then DATA={} end
Authored.data=DATA

local ORDER={"Root","Waist","Neck","Right","Left","RightElbow","LeftElbow","RightWrist","LeftWrist",
	"RightHip","LeftHip","RightKnee","LeftKnee","RightAnkle","LeftAnkle"}
Authored.ORDER=ORDER
local UPPER={Waist=true,Neck=true,Right=true,Left=true,RightElbow=true,LeftElbow=true,RightWrist=true,LeftWrist=true}
Authored.UPPER=UPPER

-- Decoded once: per clip, per joint, an array of CFrames (one per sample).
local decoded={}
local function decode(name)
	local cached=decoded[name]
	if cached~=nil then return cached or nil end
	local c=DATA[name]
	if not c then decoded[name]=false;return nil end
	local out={fps=c.fps,frames=c.frames,length=c.length,loop=c.loop,markers=c.markers or {},meta=c.meta or {},joints={}}
	for _,joint in ORDER do
		local rows=c.joints[joint]
		if rows then
			local list={}
			if joint=="Root" then
				for i=0,c.frames-1 do
					local b=i*7
					list[i+1]=CFrame.new(rows[b+1],rows[b+2],rows[b+3],rows[b+4],rows[b+5],rows[b+6],rows[b+7])
				end
			else
				for i=0,c.frames-1 do
					local b=i*4
					list[i+1]=CFrame.new(0,0,0,rows[b+1],rows[b+2],rows[b+3],rows[b+4])
				end
			end
			out.joints[joint]=list
		end
	end
	decoded[name]=out
	return out
end
Authored.clip=decode
function Authored.has(name) return DATA[name]~=nil end

-- The pose at clip time t (seconds): {joint=CFrame}.
function Authored.sample(name,t)
	local c=decode(name)
	if not c then return nil end
	-- A held part loops from its "loop" marker to its end.
	local from=c.markers.loop
	if from and t>c.length then t=from+(t-from)%math.max(c.length-from,1/c.fps) end
	local f=t*c.fps
	if c.loop then f=f%(c.frames-1) else f=math.clamp(f,0,c.frames-1) end
	local i=math.floor(f)
	local u=f-i
	local out={}
	for joint,list in c.joints do
		local a=list[i+1] or list[#list]
		local b=list[i+2] or a
		out[joint]=if u<1e-4 then a else a:Lerp(b,u)
	end
	return out
end

-- The same pose seen in a mirror (left and right swapped): an animation
-- authored for a blow from the right plays for a blow from the left.
local SWAP={Right="Left",Left="Right",RightElbow="LeftElbow",LeftElbow="RightElbow",RightWrist="LeftWrist",LeftWrist="RightWrist",
	RightHip="LeftHip",LeftHip="RightHip",RightKnee="LeftKnee",LeftKnee="RightKnee",RightAnkle="LeftAnkle",LeftAnkle="RightAnkle"}
local function mirrorCF(cf)
	local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22=cf:GetComponents()
	return CFrame.new(-x,y,z,r00,-r01,-r02,-r10,r11,r12,-r20,r21,r22)
end
function Authored.mirror(pose)
	local out={}
	for joint,cf in pose do out[SWAP[joint] or joint]=mirrorCF(cf) end
	return out
end

-- Strike phase (the engine's 0..3: startup, active, recovery) -> clip time.
function Authored.attackTime(name,phase)
	local c=decode(name)
	if not c then return 0 end
	local contact=c.markers.contact or c.length*.3
	local recover=c.markers.recover or math.min(c.length,contact+.1)
	if phase<1 then return phase*contact end
	if phase<2 then return contact+(phase-1)*(recover-contact) end
	return recover+math.min(1,phase-2)*(c.length-recover)
end
-- A segment played over `duration` seconds of real time (a channel).
function Authored.stretch(name,elapsed,duration)
	local c=decode(name)
	if not c then return 0 end
	return math.clamp(elapsed/math.max(duration,1e-3),0,1)*c.length
end
function Authored.length(name)
	local c=decode(name)
	return c and c.length or 0
end
return Authored
