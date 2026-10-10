-- Velmora additive R15 motion, adapted to Ninja Duel's server timings.
-- This stays a presentation layer: combat authority remains server-side.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)
local Motion={}
local joints={
 Waist={"LowerTorso","Waist"},Right={"UpperTorso","RightShoulder"},Left={"UpperTorso","LeftShoulder"},Neck={"UpperTorso","Neck"},
 RightHip={"LowerTorso","RightHip"},LeftHip={"LowerTorso","LeftHip"},
 Root={"HumanoidRootPart","Root"},RightElbow={"RightUpperArm","RightElbow"},LeftElbow={"LeftUpperArm","LeftElbow"},RightKnee={"RightUpperLeg","RightKnee"},LeftKnee={"LeftUpperLeg","LeftKnee"},
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
-- Each route has authored anticipation/contact/follow-through silhouettes.
-- Degrees are local joint rotations, independent of the locomotion Animator.
local function pose(root,waist,right,left,rhip,lhip,elbows,knees)
 return {Root=root,Waist=waist,Right=right,Left=left,RightHip=rhip,LeftHip=lhip,
 RightElbow={elbows and elbows[1] or 0,0,0},LeftElbow={elbows and elbows[2] or 0,0,0},
 RightKnee={knees and knees[1] or 0,0,0},LeftKnee={knees and knees[2] or 0,0,0}}
end
local choreography={
 Flashstep={
 -- Reverse-grip kunai cut, low cross slash, turning heel finisher.
 Light1={pose({0,-12,-8},{8,-32,0},{-35,0,65},{-40,0,-18},{-22,0,0},{18,0,0},{-95,-45}),pose({0,15,-5},{-15,48,-12},{-105,-35,-35},{20,0,-28},{22,0,0},{-28,0,0},{-12,-65})},
 Light2={pose({12,18,10},{20,40,12},{-65,30,-15},{-20,0,-55},{25,0,0},{-35,0,0},{-80,-60}),pose({-8,-28,-12},{-8,-65,-18},{-65,-65,75},{-90,25,-35},{-20,0,15},{38,0,-10},{-15,-20})},
 Light3={pose({0,-45,0},{-12,-45,0},{25,0,65},{-35,0,-65},{-55,15,-20},{15,0,0},{-60,-45},{-85,0}),pose({0,65,-18},{-18,48,-12},{25,0,75},{-50,0,-40},{-85,35,-65},{8,0,0},{-35,-80},{0,-12})},
 Launcher={pose({18,0,-12},{25,-25,0},{40,0,25},{-40,0,-25},{-60,0,0},{-25,0,0},{-85,-60},{-90,-45}),pose({-15,25,0},{-28,32,0},{-165,0,15},{20,0,-35},{-65,0,0},{28,0,0},{-15,-70},{-75,0})},
 DashAttack={pose({28,-20,-12},{12,-25,0},{55,0,15},{35,0,-25},{-35,0,0},{25,0,0},{-30,-25}),pose({15,20,-8},{-12,40,-10},{-95,-25,-20},{50,0,-30},{45,0,0},{-50,0,0},{-5,-45},{-15,-70})},
 Air1={pose({0,-30,-28},{5,-30,-15},{-55,0,65},{-35,0,-35},{-55,0,-20},{30,0,20},{-80,-70},{-60,-40}),pose({0,35,30},{-15,55,20},{-100,-50,-30},{45,0,-35},{25,0,-35},{-65,0,10},{-10,-50},{-25,-80})},
 Air2={pose({20,35,20},{20,35,0},{40,0,65},{-70,0,-25},{-45,0,0},{-65,0,15},{-50,-65},{-70,-90}),pose({-15,-50,-25},{-20,-45,-10},{-60,0,45},{20,0,-55},{-85,0,-30},{30,0,15},{-65,-25},{0,-65})},
 Slam={pose({-25,0,-15},{-20,-30,0},{-165,0,25},{-45,0,-25},{-65,0,0},{-30,0,0},{-65,-60},{-90,-70}),pose({48,20,0},{25,30,0},{-85,0,-15},{50,0,-25},{20,0,0},{-30,0,0},{-10,-55},{-15,-60})},
 },
 Mirage={
 -- Open palm check, shuriken flick, rooted side kick that creates space.
 Light1={pose({0,8,0},{0,18,0},{-45,0,15},{-65,0,-15},{0,0,0},{-12,0,0},{-90,-95}),pose({0,-8,0},{-5,-18,0},{-88,0,8},{-40,0,-12},{-8,0,0},{12,0,0},{-5,-100})},
 Light2={pose({0,-8,0},{0,-22,0},{-45,0,15},{-80,35,-50},{-10,0,0},{8,0,0},{-100,-115}),pose({0,12,0},{0,22,0},{-50,0,15},{-95,-30,-15},{10,0,0},{-8,0,0},{-90,-5})},
 Light3={pose({0,15,0},{0,25,0},{-55,0,20},{-65,0,-15},{10,0,0},{-65,0,-10},{-85,-85},{0,-115}),pose({-12,-25,12},{-8,-25,0},{-40,0,35},{-65,0,-25},{12,0,0},{-100,-15,-25},{-70,-90},{0,0})},
 Launcher={pose({6,-10,0},{12,-15,0},{-50,0,15},{-60,0,-15},{-65,0,0},{5,0,0},{-85,-90},{-110,0}),pose({-8,-15,-8},{-12,0,0},{-60,0,25},{-65,0,-20},{-145,0,0},{18,0,0},{-80,-90},{-8,0})},
 DashAttack={pose({8,20,0},{0,30,0},{-50,0,20},{-75,0,-15},{-20,0,0},{15,0,0},{-110,-100}),pose({8,-18,0},{0,-35,0},{-75,0,-10},{-50,0,-25},{15,0,0},{-20,0,0},{-120,-85})},
 Air1={pose({-8,10,0},{-8,20,0},{-55,0,15},{-65,0,-20},{-65,0,0},{-20,0,0},{-90,-90},{-100,-50}),pose({-10,-15,8},{-15,-20,0},{-45,0,25},{-60,0,-25},{-100,0,0},{20,0,0},{-90,-70},{0,-50})},
 Air2={pose({0,-15,0},{0,-25,0},{-60,0,20},{-80,20,-45},{-35,0,0},{-30,0,0},{-100,-110},{-70,-65}),pose({0,20,0},{0,35,0},{-65,0,25},{-95,-20,-15},{-20,0,0},{-45,0,0},{-80,-5},{-55,-75})},
 Slam={pose({-15,0,0},{-20,0,0},{-160,0,15},{-160,0,-15},{-45,0,0},{-45,0,0},{-110,-110},{-75,-75}),pose({25,0,0},{40,0,0},{-100,0,10},{-100,0,-10},{25,0,0},{15,0,0},{-5,-5},{-20,-30})},
 },
}
local function rotation(v)
 return if v then CFrame.Angles(math.rad(v[1]),math.rad(v[2]),math.rad(v[3])) else CFrame.identity
end
function Motion.pose(char,name,elapsed,fighterId)
 local spec=Attacks[name];if not spec then return end
 local fighter=Fighters[fighterId];local profile=fighter and fighter.AttackProfile and fighter.AttackProfile[name]
 local startup=spec.startup*(profile and profile.startup or 1)
 local active=spec.active*(profile and profile.active or 1)
 local recovery=spec.recovery*(profile and profile.recovery or 1)
 local route=choreography[fighterId] or choreography.Flashstep
 local frames=route[name] or route.Light1
 local from,to,t
 if elapsed<startup then from={};to=frames[1];t=smooth(elapsed/startup)
 elseif elapsed<startup+active*.55 then from=frames[1];to=frames[2];t=smooth((elapsed-startup)/(active*.55))
 else from=frames[2];to={};t=smooth((elapsed-startup-active*.55)/(recovery+active*.45)) end
 for key in joints do set(char,key,rotation(from[key]):Lerp(rotation(to[key]),t)) end
end
local weapons=setmetatable({}, {__mode="k"})
function Motion.weapon(char,actor)
 local item=weapons[char]
 if not item then
  local hand=char:FindFirstChild(if actor.fighterId=="Flashstep" then "RightHand" else "LeftHand")
  if not hand then return end
  item={};weapons[char]=item
  local minato=actor.fighterId=="Flashstep"
  for i=1,(if minato then 3 else 4) do
   local blade=Instance.new("WedgePart");blade.Name="CombatBlade";blade.Size=if minato then Vector3.new(.13,.42,1.2) else Vector3.new(.09,.3,.75)
   blade.Material=Enum.Material.Metal;blade.Color=Color3.fromRGB(195,210,222)
   blade.Massless=true;blade.CanCollide=false;blade.CanQuery=false;blade.CanTouch=false;blade.Parent=hand
   local weld=Instance.new("Weld");weld.Part0=hand;weld.Part1=blade
   weld.C0=if minato then CFrame.new((i-2)*.24,-.45,-.3)*CFrame.Angles(0,0,math.rad((i-2)*22)) else CFrame.new(0,-.35,0)*CFrame.Angles(0,math.rad(i*90),0)*CFrame.new(0,0,-.3)
   weld.Parent=blade;table.insert(item,blade)
  end
 end
 local active=actor.attackName and actor.state~="Neutral"
 local visible=active and (actor.fighterId=="Flashstep" and actor.attackName~="Light3" or actor.fighterId=="Mirage" and (actor.attackName=="Light2" or actor.attackName=="Air2"))
 for _,blade in item do blade.Transparency=if visible then 0 else 1 end
end
function Motion.defense(char,actor)
 local direction=actor.velocity or Vector3.zero
 local root=char:FindFirstChild("HumanoidRootPart")
 local localMotion=root and root.CFrame:VectorToObjectSpace(direction) or Vector3.zero
 if actor.state=="Dodging" then
  set(char,"Root",CFrame.Angles(math.rad(25),0,math.rad(math.clamp(-localMotion.X*2,-35,35))))
  set(char,"Waist",CFrame.Angles(math.rad(20),0,0))
  set(char,"RightHip",CFrame.Angles(math.rad(-60),0,0));set(char,"LeftHip",CFrame.Angles(math.rad(30),0,0))
  set(char,"RightKnee",CFrame.Angles(math.rad(-90),0,0));set(char,"Right",CFrame.Angles(math.rad(45),0,0))
 elseif actor.reaction=="Knockdown" or actor.reaction=="WallSplat" then
  set(char,"Root",CFrame.Angles(math.rad(if actor.reaction=="WallSplat" then -22 else 65),0,math.rad(14)))
  set(char,"Right",CFrame.Angles(0,0,math.rad(70)));set(char,"Left",CFrame.Angles(0,0,math.rad(-65)))
 elseif actor.reaction then Motion.recoil(char,.03,actor.reaction,true)
 end
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
