-- Velmora additive R15 motion, adapted to Ninja Duel's server timings.
-- This stays a presentation layer: combat authority remains server-side.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motion={}
local joints={
 Waist={"LowerTorso","Waist"},Right={"UpperTorso","RightShoulder"},Left={"UpperTorso","LeftShoulder"},Neck={"UpperTorso","Neck"},
 RightHip={"LowerTorso","RightHip"},LeftHip={"LowerTorso","LeftHip"},
}
local function motor(char,key)
	local d=joints[key];local part=char and char:FindFirstChild(d[1]);local m=part and part:FindFirstChild(d[2])
	return if m and m:IsA("Motor6D") then m else nil
end
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function phases(elapsed,spec)
 if elapsed<spec.startup then return smooth(elapsed/math.max(spec.startup,.01)),0,0 end
 elapsed-=spec.startup
 if elapsed<spec.active then return 1,smooth(elapsed/math.max(spec.active,.01)),0 end
 elapsed-=spec.active
 return 0,1,smooth(elapsed/math.max(spec.recovery,.01))
end
local function set(char,key,value)
 local joint=motor(char,key);if joint then joint.Transform=value end
end
function Motion.pose(char,name,elapsed)
	local spec=Attacks[name]
	if not spec then return end
	local coil,drive,settle=phases(elapsed,spec);local hold=1-settle
	local side=spec.side or 1;local twist=math.rad(spec.twist or 24);local lean=math.rad(spec.lean or 10);local arm=math.rad(spec.arm or 80)
	local strike=drive*hold;local wind=coil*(1-drive)
	local yaw=side*(-twist*.52*wind+twist*strike);local pitch=lean*(.2*wind-.72*strike)*hold
	if name=="Launcher" or name=="ThrowUp" then pitch=-math.abs(lean)*(.65*wind+strike) end
	if name=="Slam" then pitch=math.abs(lean)*(.22*wind+strike) end
	set(char,"Waist",CFrame.Angles(pitch,yaw,side*math.rad(5)*(strike-wind)))
	set(char,"Neck",CFrame.Angles(-pitch*.3,-yaw*.38,0))
	local attack=CFrame.Angles(-arm*(.28*wind+strike),side*math.rad(10)*strike,-side*math.rad(18)*(wind+strike))
	local guard=CFrame.Angles(math.rad(-18)*hold,-side*math.rad(5),side*math.rad(10)*hold)
	if side>0 then set(char,"Right",attack);set(char,"Left",guard) else set(char,"Left",attack);set(char,"Right",guard) end
	local crouch=math.rad(16)*wind*hold;local stride=math.rad(14)*strike
	set(char,"RightHip",CFrame.Angles(crouch+stride*side,0,-side*math.rad(5)*hold))
	set(char,"LeftHip",CFrame.Angles(crouch-stride*side,0,side*math.rad(5)*hold))
end
function Motion.recoil(char,elapsed,reaction,heavy)
	local duration=if heavy then .3 else .22;local t=1-smooth(elapsed/duration);local scale=if heavy then 1.35 else 1
	local airborne=reaction=="Launched" or reaction=="Juggled" or reaction=="Knockback" or reaction=="Knockdown"
	local pitch=math.rad(if airborne then 28 else -19)*t*scale
	set(char,"Waist",CFrame.Angles(pitch,math.rad(12)*t,math.rad(-7)*t));set(char,"Neck",CFrame.Angles(-pitch*.45,math.rad(-8)*t,0))
	set(char,"Right",CFrame.Angles(math.rad(38)*t,0,math.rad(22)*t));set(char,"Left",CFrame.Angles(math.rad(24)*t,0,math.rad(-28)*t))
	set(char,"RightHip",CFrame.Angles(-pitch*.25,0,math.rad(-8)*t));set(char,"LeftHip",CFrame.Angles(-pitch*.18,0,math.rad(8)*t))
end
function Motion.locomotion(char,speed,airborne,velocity)
	local alpha=math.clamp(speed/46,0,1)
	if airborne then
		local rise=math.clamp((velocity and velocity.Y or 0)/72,-1,1)
		set(char,"Waist",CFrame.Angles(math.rad(-8-7*rise),0,0));set(char,"RightHip",CFrame.Angles(math.rad(18),0,math.rad(-5)));set(char,"LeftHip",CFrame.Angles(math.rad(-12),0,math.rad(5)));return
	end
	local cycle=os.clock()*(7+alpha*5);local swing=math.sin(cycle)*math.rad(10)*alpha
	set(char,"Waist",CFrame.Angles(math.rad(-9)*alpha,0,math.sin(cycle*2)*math.rad(2)*alpha))
	set(char,"Right",CFrame.Angles(swing,0,0));set(char,"Left",CFrame.Angles(-swing,0,0));set(char,"RightHip",CFrame.Angles(-swing,0,0));set(char,"LeftHip",CFrame.Angles(swing,0,0));set(char,"Neck",CFrame.identity)
end
function Motion.clear(char)
	for key in joints do local m=motor(char,key);if m then m.Transform=CFrame.identity end end
end
return Motion
