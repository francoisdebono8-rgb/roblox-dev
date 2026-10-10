-- Velmora additive R15 motion, adapted to Ninja Duel's server timings.
-- This stays a presentation layer: combat authority remains server-side.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)
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
function Motion.pose(char,name,elapsed,fighterId)
	local spec=Attacks[name]
	if not spec then return end
	spec=table.clone(spec)
	local fighter=Fighters[fighterId];local profile=fighter and fighter.AttackProfile and fighter.AttackProfile[name]
	if profile then spec.startup*=profile.startup or 1;spec.active*=profile.active or 1;spec.recovery*=profile.recovery or 1 end
	local coil,drive,settle=phases(elapsed,spec);local hold=1-settle
	local minato=fighterId=="Flashstep";local side=spec.side or 1
	if profile and profile.angle then side=if profile.angle<0 then -1 else 1 end
	local twist=math.rad(spec.twist or 24)*(if minato then 1.18 else .86)
	local lean=math.rad(spec.lean or 10)*(if minato then 1.12 else .72);local arm=math.rad(spec.arm or 80)*(if minato then 1 else .92)
	local strike=drive*hold;local wind=coil*(1-drive)
	local yaw=side*(-twist*.52*wind+twist*strike);local pitch=lean*(.2*wind-.72*strike)*hold
	if name=="Launcher" or name=="ThrowUp" then pitch=-math.abs(lean)*(.65*wind+strike) end
	if name=="Slam" then pitch=math.abs(lean)*(.22*wind+strike) end
	set(char,"Waist",CFrame.Angles(pitch,yaw,side*math.rad(5)*(strike-wind)))
	set(char,"Neck",CFrame.Angles(-pitch*.3,-yaw*.38,0))
	local attack=CFrame.Angles(-arm*(.28*wind+strike),side*math.rad(if minato then 14 else 7)*strike,-side*math.rad(if minato then 22 else 13)*(wind+strike))
	local guard=CFrame.Angles(math.rad(if minato then -18 else -28)*hold,-side*math.rad(5),side*math.rad(10)*hold)
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
function Motion.guard(char,impact,fighterId)
	local recoil=math.clamp(impact/.18,0,1);local calm=if fighterId=="Mirage" then .72 else 1
	set(char,"Waist",CFrame.Angles(math.rad(-7+16*recoil)*calm,0,0));set(char,"Right",CFrame.Angles(math.rad(-54+18*recoil),0,math.rad(17)));set(char,"Left",CFrame.Angles(math.rad(-54+18*recoil),0,math.rad(-17)))
	set(char,"RightHip",CFrame.Angles(math.rad(8*recoil),0,0));set(char,"LeftHip",CFrame.Angles(math.rad(-8*recoil),0,0))
end
function Motion.locomotion(char,speed,airborne,velocity,fighterId)
	local alpha=math.clamp(speed/46,0,1)
	if airborne then
		local rise=math.clamp((velocity and velocity.Y or 0)/72,-1,1)
		set(char,"Waist",CFrame.Angles(math.rad(-8-7*rise),0,0));set(char,"RightHip",CFrame.Angles(math.rad(18),0,math.rad(-5)));set(char,"LeftHip",CFrame.Angles(math.rad(-12),0,math.rad(5)));return
	end
	local minato=fighterId=="Flashstep";local cycle=os.clock()*((if minato then 8.5 else 6.5)+alpha*(if minato then 6 else 3.5));local swing=math.sin(cycle)*math.rad(if minato then 12 else 7)*alpha
	set(char,"Waist",CFrame.Angles(math.rad(if minato then -11 else -4)*alpha,0,math.sin(cycle*2)*math.rad(if minato then 2.5 else 1.2)*alpha))
	set(char,"Right",CFrame.Angles(swing,0,0));set(char,"Left",CFrame.Angles(-swing,0,0));set(char,"RightHip",CFrame.Angles(-swing,0,0));set(char,"LeftHip",CFrame.Angles(swing,0,0));set(char,"Neck",CFrame.identity)
end
function Motion.clear(char)
	for key in joints do local m=motor(char,key);if m then m.Transform=CFrame.identity end end
end
return Motion
