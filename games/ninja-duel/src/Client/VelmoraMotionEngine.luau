-- Adapted from Velmora src/client/Combat/MotionEngine.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
-- A local additive R15 coil/drive/settle layer synchronized to server attack timings.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motion={}
local joints={Waist={"LowerTorso","Waist"},Right={"UpperTorso","RightShoulder"},Left={"UpperTorso","LeftShoulder"},Neck={"UpperTorso","Neck"}}
local function motor(char,key)
	local d=joints[key];local part=char and char:FindFirstChild(d[1]);local m=part and part:FindFirstChild(d[2])
	return if m and m:IsA("Motor6D") then m else nil
end
local function smooth(t) return t*t*(3-2*t) end
local function envelope(elapsed,spec)
	if elapsed<0 then return 0 end
	if elapsed<spec.startup then return -smooth(elapsed/spec.startup) end
	if elapsed<spec.startup+spec.active then return -1+2*smooth((elapsed-spec.startup)/spec.active) end
	local recovery=math.max(spec.recovery,.01)
	return math.max(0,1-(elapsed-spec.startup-spec.active)/recovery)
end
function Motion.pose(char,name,elapsed)
	local spec=Attacks[name]
	if not spec then return end
	local e=envelope(elapsed,spec);local heavy=spec.damage>=12 and 1.25 or 1
	local coil=math.rad(math.min(18,(8+spec.startup*30)*heavy))*e
	local waist=motor(char,"Waist");if waist then waist.Transform=CFrame.Angles(-math.abs(coil)*.22,coil,0) end
	local right=motor(char,"Right");if right then right.Transform=CFrame.Angles(-math.abs(coil)*.85,0,-coil*.35) end
	local left=motor(char,"Left");if left then left.Transform=CFrame.Angles(math.abs(coil)*.25,0,coil*.2) end
	local neck=motor(char,"Neck");if neck then neck.Transform=CFrame.Angles(0,-coil*.35,0) end
end
function Motion.recoil(char,elapsed)
	local waist=motor(char,"Waist");if waist then waist.Transform=CFrame.Angles(math.rad(-18)*math.max(0,1-elapsed/.22),0,0) end
end
function Motion.clear(char)
	for key in joints do local m=motor(char,key);if m then m.Transform=CFrame.identity end end
end
return Motion
