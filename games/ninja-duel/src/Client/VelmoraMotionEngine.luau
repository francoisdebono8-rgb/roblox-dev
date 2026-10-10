-- Ninja Duel body animation. Started from Velmora's additive R15 layer (MIT) and
-- rebuilt into a full-body authored animation system:
--
--  * the presentation owns every joint it animates (it keeps its own pose state
--    instead of blending against whatever the Animator wrote this frame);
--  * grounded poses place the feet with two-bone leg IK, so stances crouch,
--    lunge and land with planted feet instead of floating or sliding;
--  * attacks, throws, hand signs and reactions are multi-key clips authored with
--    anatomical controls (raise / out / twist / elbow ...), so elbows and knees
--    bend the right way;
--  * locomotion is a real gait: stride, foot lift, pelvis/torso counter-twist,
--    arm swing, and the anime "ninja run" when sprinting or chasing.
--
-- Every joint is damped towards its target with an angular speed limit, so no
-- state change can snap the body. Presentation only: combat authority stays on
-- the server.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Fighters=require(Shared.Fighters)
-- Weapon models come from the VFX module; required lazily so headless tools
-- that only pose skeletons do not need its services.
local Effects=nil
local Motion={}
local rad=math.rad
local CF=CFrame.new
local ANG=CFrame.Angles
local IDENTITY=CFrame.identity

local JOINTS={
	Root={"HumanoidRootPart","Root"},Waist={"LowerTorso","Waist"},Neck={"UpperTorso","Neck"},
	Right={"UpperTorso","RightShoulder"},Left={"UpperTorso","LeftShoulder"},
	RightElbow={"RightUpperArm","RightElbow"},LeftElbow={"LeftUpperArm","LeftElbow"},
	RightWrist={"RightLowerArm","RightWrist"},LeftWrist={"LeftLowerArm","LeftWrist"},
	RightHip={"LowerTorso","RightHip"},LeftHip={"LowerTorso","LeftHip"},
	RightKnee={"RightUpperLeg","RightKnee"},LeftKnee={"LeftUpperLeg","LeftKnee"},
	RightAnkle={"RightLowerLeg","RightAnkle"},LeftAnkle={"LeftLowerLeg","LeftAnkle"},
}
local UPPER={Waist=true,Neck=true,Right=true,Left=true,RightElbow=true,LeftElbow=true,RightWrist=true,LeftWrist=true}

-- ------------------------------------------------------------------ state
local states=setmetatable({},{__mode="k"})
local function stateOf(char)
	local s=states[char]
	if not s then s={motors={},pose={},phase=0,clock=0};states[char]=s end
	return s
end
local function motor(char,key)
	local s=stateOf(char)
	local cached=s.motors[key]
	if cached~=nil then return cached or nil end
	local d=JOINTS[key];local part=char and char:FindFirstChild(d[1]);local m=part and part:FindFirstChild(d[2])
	local found=if m and m:IsA("Motor6D") then m else nil
	-- Only cache a positive lookup: a rig can still be assembling.
	if found then s.motors[key]=found end
	return found
end
-- A simulated presentation clock advanced once per rendered frame: identical on
-- 30 Hz and 120 Hz clients, deterministic in tests.
local elapsedTime=0
function Motion.tick(dt)
	if dt and dt>0 then elapsedTime+=math.min(dt,.1) end
	return elapsedTime
end
function Motion.now() return elapsedTime end

-- Damping rate per layer, and a hard angular speed limit (deg/s) so a sudden
-- target change still travels instead of teleporting.
local RATE={attack=30,throw=30,cast=22,recoil=30,guard=24,defense=24,locomotion=16,air=14,ground=12,wall=16,chase=18}
local MAX_SPEED=1750
local function angleBetween(a,b)
	local _,angle=(a:Inverse()*b):ToAxisAngle()
	return math.abs(angle)
end
-- Write one joint: damp the owned pose towards the target, limit the angular
-- step, then publish it as the Motor6D transform.
local function write(char,key,target,rate,dt)
	local joint=motor(char,key)
	if not joint then return end
	local s=stateOf(char)
	if not dt then s.pose[key]=target;joint.Transform=target;return end
	local current=s.pose[key] or joint.Transform
	local alpha=1-math.exp(-(rate or RATE.locomotion)*dt)
	local nextCF=current:Lerp(target,alpha)
	local step=angleBetween(current,nextCF)
	local limit=rad(MAX_SPEED)*dt
	if step>limit and step>1e-6 then nextCF=current:Lerp(nextCF,limit/step) end
	-- Translation (only the Root carries any) is speed-limited too.
	local move=nextCF.Position-current.Position
	local maxMove=14*dt
	if move.Magnitude>maxMove then nextCF=CF(current.Position+move.Unit*maxMove)*nextCF.Rotation end
	s.pose[key]=nextCF
	joint.Transform=nextCF
end
local function apply(char,targets,rate,dt)
	for key in JOINTS do write(char,key,targets[key] or IDENTITY,rate,dt) end
end

-- ------------------------------------------------------------- pose builder
-- Anatomical controls, degrees / studs:
--   root  {x,y,z,pitch,yaw,roll}  pitch + leans forward, yaw + turns right,
--         roll + tilts the top to the right; y < 0 crouches.
--   torso {pitch,yaw,roll}         same conventions, upper body on the hips.
--   head  {pitch,yaw,roll}
--   ra/la {raise,out,twist,elbow,wrist,wroll}  raise + lifts the arm forward,
--         out + away from the body, twist + rotates it inward, elbow + flexes.
--   rf/lf {x,y,z,yaw,toe}  IK foot target offset from the rest ankle (x right,
--         z backwards, y up) for planted feet;
--   rl/ll {lift,out,twist,knee,ankle}  free leg (air, kicks): lift + raises the
--         thigh forward, knee + flexes.
local L1,L2=1.05,1.0
local ANKLE_Y=-2.6 -- rest ankle height relative to HumanoidRootPart centre
local function ori(o)
	if not o then return IDENTITY end
	return ANG(rad(-(o.pitch or 0)),rad(-(o.yaw or 0)),rad(-(o.roll or 0)))
end
local function armCF(side,a)
	a=a or {}
	local shoulder=ANG(rad(a.raise or 0),0,0)*ANG(0,0,rad((a.out or 0)*side))*ANG(0,rad((a.twist or 0)*side),0)
	return shoulder,ANG(rad(a.elbow or 0),0,0),ANG(rad(a.wrist or 0),0,rad((a.wroll or 0)*side))
end
local function legFK(side,l)
	l=l or {}
	return ANG(rad(l.lift or 0),0,0)*ANG(0,0,rad((l.out or 0)*side))*ANG(0,rad((l.twist or 0)*side),0),ANG(rad(-(l.knee or 0)),0,0),ANG(rad(l.ankle or 0),0,0)
end
-- Two-bone IK in the LowerTorso frame: thigh/shin lengths are the rig's real
-- joint spacing; knees point forward (and a little out); the foot stays flat.
local function legIK(rootCF,side,ankle,footYaw,toe)
	local hip=rootCF*Vector3.new(.5*side,-.55,0)
	local inv=rootCF.Rotation:Inverse()
	local d=inv*(ankle-hip)
	local u=if d.Magnitude>1e-4 then d.Unit else Vector3.new(0,-1,0)
	local D=math.clamp(d.Magnitude,.45,L1+L2-1e-3)
	local bend=math.pi-math.acos(math.clamp((L1*L1+L2*L2-D*D)/(2*L1*L2),-1,1))
	local a=math.acos(math.clamp((L1*L1+D*D-L2*L2)/(2*L1*D),-1,1))
	local hint=Vector3.new(side*.18,0,-1).Unit
	local w=hint-u*hint:Dot(u)
	if w.Magnitude<1e-3 then w=Vector3.new(0,0,-1) end
	w=w.Unit
	local up=-(u*math.cos(a)+w*math.sin(a))
	local x=w:Cross(up)
	if x.Magnitude<1e-3 then x=Vector3.xAxis end
	x=x.Unit
	local z=x:Cross(up).Unit
	local hipCF=CFrame.fromMatrix(Vector3.zero,x,up,z)
	local kneeCF=ANG(-bend,0,0)
	local foot=(hipCF*kneeCF):Inverse()*inv*ANG(0,rad(-(footYaw or 0)),0)*ANG(rad(toe or 0),0,0)
	return hipCF,kneeCF,foot
end
local function rootCFOf(spec)
	local r=spec.root or {}
	return CF(r.x or 0,r.y or 0,r.z or 0)*ori(r)
end
-- Spec -> joint transforms. Unspecified parts stay at rest.
local function build(spec)
	local out={}
	local rootCF=rootCFOf(spec)
	out.Root=rootCF
	out.Waist=ori(spec.torso)
	out.Neck=ori(spec.head)
	out.Right,out.RightElbow,out.RightWrist=armCF(1,spec.ra)
	out.Left,out.LeftElbow,out.LeftWrist=armCF(-1,spec.la)
	for _,side in {1,-1} do
		local prefix=if side==1 then "Right" else "Left"
		local free=if side==1 then spec.rl else spec.ll
		if free then
			-- A free leg (air, kicks) is posed directly.
			out[prefix.."Hip"],out[prefix.."Knee"],out[prefix.."Ankle"]=legFK(side,free)
		else
			-- Otherwise the foot is planted (at rest unless told where) and the
			-- leg is solved to reach it, whatever the hips are doing.
			local foot=(if side==1 then spec.rf else spec.lf) or {}
			local ankle=Vector3.new(.5*side+(foot.x or 0),ANKLE_Y+(foot.y or 0),foot.z or 0)
			out[prefix.."Hip"],out[prefix.."Knee"],out[prefix.."Ankle"]=legIK(rootCF,side,ankle,foot.yaw,foot.toe)
		end
	end
	return out
end
local cache=setmetatable({},{__mode="k"})
local function built(spec)
	local c=cache[spec]
	if not c then c=build(spec);cache[spec]=c end
	return c
end
local function blend(a,b,t)
	if t<=0 then return a end
	if t>=1 then return b end
	local out={}
	for key in JOINTS do out[key]=(a[key] or IDENTITY):Lerp(b[key] or IDENTITY,t) end
	return out
end
-- Deep merge: `over` replaces numeric fields of `base`; tables are merged.
local function merge(base,over)
	local out={}
	for k,v in base do out[k]=if type(v)=="table" then table.clone(v) else v end
	for k,v in over or {} do
		if type(v)=="table" and type(out[k])=="table" and not v.replace then
			for kk,vv in v do out[k][kk]=vv end
		else
			out[k]=if type(v)=="table" then table.clone(v) else v
		end
	end
	return out
end
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local function easeOut(t) t=math.clamp(t,0,1);return 1-(1-t)*(1-t)*(1-t) end
local function easeIn(t) t=math.clamp(t,0,1);return t*t*t end
local EASE={smooth=smooth,out=easeOut,["in"]=easeIn,linear=function(t) return math.clamp(t,0,1) end}

-- ---------------------------------------------------------------- stances
-- Minato: light and coiled, lead foot forward, kunai hand low in reverse grip,
-- lead hand open. Itachi: upright and square, economical, left hand ready.
local STANCE={
	Flashstep={root={y=-.42,pitch=9,yaw=24},torso={pitch=5,yaw=-14},head={pitch=-6,yaw=-11},
		ra={raise=34,out=14,twist=24,elbow=98,wrist=-22},la={raise=58,out=2,twist=12,elbow=78,wrist=8},
		rf={x=.22,z=.78,yaw=32},lf={x=-.08,z=-.72,yaw=-4},breath=1.6,tempo=7.5},
	Mirage={root={y=-.2,pitch=3,yaw=14},torso={pitch=2,yaw=-8},head={pitch=1,yaw=-7},
		ra={raise=14,out=9,twist=8,elbow=32,wrist=0},la={raise=42,out=-6,twist=24,elbow=84,wrist=10},
		rf={x=.12,z=.5,yaw=22},lf={x=0,z=-.46,yaw=-2},breath=.7,tempo=5},
}
local function stance(id) return STANCE[id] or STANCE.Flashstep end

-- ---------------------------------------------------------- attack clips
-- Keys are placed on the move's own timeline: 0 = start, 1 = end of startup
-- (contact), 2 = end of active, 3 = end of recovery. `w` fades the clip out
-- over the tail of recovery so the body returns into its stance.
local function K(at,pose,ease) return {at=at,pose=pose,ease=ease or "smooth"} end
local M=STANCE.Flashstep
local I=STANCE.Mirage
local function m(over) return merge(M,over) end
local function i(over) return merge(I,over) end
local CLIPS={Flashstep={},Mirage={}}
-- Minato --------------------------------------------------------------
CLIPS.Flashstep.Light1={ -- reverse-grip kunai: cross-body load, outward slash
	K(0,m({root={y=-.55,yaw=10,pitch=12},torso={yaw=-28,pitch=8},ra={raise=72,out=-42,twist=38,elbow=112,wrist=-30},la={raise=40,out=12,elbow=70},lf={z=-.95}})),
	K(1,m({root={y=-.5,z=-.35,yaw=36,pitch=14},torso={yaw=24,pitch=6},head={yaw=-20},ra={raise=86,out=24,twist=-12,elbow=22,wrist=10},la={raise=22,out=22,elbow=60},lf={z=-1.2},rf={z=.95}}),"out"),
	K(2,m({root={y=-.48,z=-.38,yaw=42,pitch=12},torso={yaw=34},ra={raise=72,out=56,twist=-26,elbow=34},la={raise=26,out=26,elbow=64},lf={z=-1.2},rf={z=.95}})),
	K(3,M),
}
CLIPS.Flashstep.Light2={ -- body-turned palm strike with the lead hand, step in
	K(0,m({root={y=-.5,yaw=40,pitch=10},torso={yaw=18},la={raise=48,out=32,twist=-18,elbow=96},ra={raise=40,out=18,elbow=100}})),
	K(1,m({root={y=-.48,z=-.42,yaw=-8,pitch=14},torso={yaw=-30,pitch=8},head={yaw=8},la={raise=88,out=-14,twist=22,elbow=26,wrist=24},ra={raise=24,out=20,elbow=92},rf={x=.36,z=.2},lf={z=-1.0}}),"out"),
	K(2,m({root={y=-.46,z=-.45,yaw=-14,pitch=12},torso={yaw=-38},la={raise=80,out=-30,elbow=38},ra={raise=26,out=24,elbow=92},rf={x=.36,z=.2},lf={z=-1.0}})),
	K(3,M),
}
CLIPS.Flashstep.Light3={ -- spinning roundhouse with the right leg
	K(0,m({root={y=-.62,yaw=-40,pitch=8},torso={yaw=-22},ra={raise=52,out=-8,elbow=112},la={raise=52,out=-4,elbow=112},rl={lift=72,out=18,knee=104,ankle=-10},lf={z=-.35,yaw=-30}})),
	K(1,m({root={y=-.32,yaw=62,pitch=-6,roll=-20},torso={yaw=12,roll=-24},head={roll=14,yaw=-30},ra={raise=24,out=82,elbow=18},la={raise=34,out=70,elbow=30},rl={lift=86,out=56,twist=-28,knee=10,ankle=-24},lf={z=-.3,yaw=40}}),"out"),
	K(2,m({root={y=-.34,yaw=76,pitch=-4,roll=-18},torso={yaw=16,roll=-20},ra={raise=24,out=80,elbow=22},la={raise=32,out=68,elbow=34},rl={lift=80,out=60,twist=-30,knee=16,ankle=-20},lf={z=-.3,yaw=55}})),
	K(2.5,m({root={y=-.5,yaw=60},rl={lift=42,out=20,knee=76},lf={z=-.3,yaw=40}})),
	K(3,M),
}
CLIPS.Flashstep.Heavy={ -- coiled whole-body lunge, straight right
	K(0,m({root={y=-.72,z=.3,yaw=46,pitch=12},torso={yaw=26,pitch=8},ra={raise=-18,out=22,twist=22,elbow=120},la={raise=72,out=-4,elbow=58},lf={z=-1.1},rf={z=1.0,yaw=46}})),
	K(.75,m({root={y=-.86,z=.36,yaw=52,pitch=14},torso={yaw=30,pitch=10},ra={raise=-24,out=24,twist=24,elbow=126},la={raise=76,out=-6,elbow=54},lf={z=-1.15},rf={z=1.05,yaw=48}})),
	K(1,m({root={y=-.5,z=-.92,yaw=-26,pitch=22},torso={yaw=-22,pitch=10},head={yaw=16},ra={raise=90,out=-4,twist=-10,elbow=4,wrist=0},la={raise=-12,out=18,elbow=112},lf={z=-1.65},rf={z=1.25,yaw=10}}),"out"),
	K(2,m({root={y=-.52,z=-.95,yaw=-28,pitch=20},torso={yaw=-24,pitch=10},ra={raise=88,out=-6,twist=-10,elbow=8},la={raise=-10,out=18,elbow=110},lf={z=-1.65},rf={z=1.25,yaw=10}})),
	K(3,M),
}
CLIPS.Flashstep.Launcher={ -- crouch, then a vertical rising kick
	K(0,m({root={y=-.92,pitch=20},torso={pitch=12},ra={raise=42,out=22,elbow=92},la={raise=42,out=22,elbow=92},lf={z=-.42},rf={z=.5}})),
	K(1,m({root={y=.25,pitch=-22},torso={pitch=-14},head={pitch=-14},ra={raise=-32,out=30,elbow=22},la={raise=-28,out=30,elbow=20},rl={lift=150,out=6,knee=4,ankle=-32},lf={z=0,toe=-26}}),"out"),
	K(2,m({root={y=.2,pitch=-20},torso={pitch=-12},head={pitch=-12},ra={raise=-30,out=30,elbow=22},la={raise=-26,out=30,elbow=22},rl={lift=138,out=6,knee=12,ankle=-28},lf={z=0,toe=-20}})),
	K(3,M),
}
CLIPS.Flashstep.DashAttack={ -- low dashing kunai thrust
	K(0,m({root={y=-.75,z=.2,pitch=34},torso={pitch=6},ra={raise=12,out=26,twist=40,elbow=110},la={raise=82,out=-4,elbow=30},lf={z=-1.2},rf={z=1.3}})),
	K(1,m({root={y=-.72,z=-1.0,pitch=30,yaw=-10},torso={yaw=-12},head={pitch=-16},ra={raise=96,out=-6,twist=-60,elbow=0,wrist=-12},la={raise=-30,out=22,elbow=30},lf={z=-1.7},rf={z=1.5,y=.25,toe=-20}}),"out"),
	K(2,m({root={y=-.7,z=-1.0,pitch=28,yaw=-12},torso={yaw=-14},head={pitch=-14},ra={raise=94,out=-4,twist=-60,elbow=4},la={raise=-28,out=22,elbow=30},lf={z=-1.7},rf={z=1.5,y=.25,toe=-20}})),
	K(3,M),
}
local AIR_M={root={pitch=6},torso={pitch=6},head={pitch=-6},ra={raise=48,out=20,elbow=96},la={raise=52,out=14,elbow=86},rl={lift=58,knee=96,ankle=-10},ll={lift=34,knee=74,ankle=-10}}
CLIPS.Flashstep.Air1={
	K(0,merge(AIR_M,{torso={yaw=-24,pitch=-4},ra={raise=128,out=42,elbow=104,twist=10},la={raise=40,out=30,elbow=70}})),
	K(1,merge(AIR_M,{torso={yaw=26,pitch=16},root={pitch=10},ra={raise=58,out=-32,elbow=14,wrist=12},la={raise=10,out=44,elbow=50}}),"out"),
	K(2,merge(AIR_M,{torso={yaw=32,pitch=18},root={pitch=12},ra={raise=44,out=-40,elbow=18},la={raise=8,out=46,elbow=50}})),
	K(3,AIR_M),
}
CLIPS.Flashstep.Air2={
	K(0,merge(AIR_M,{root={yaw=-50},torso={yaw=-18},rl={lift=80,out=10,knee=112},ra={raise=50,out=-10,elbow=110},la={raise=50,out=-10,elbow=110}})),
	K(1,merge(AIR_M,{root={yaw=52,roll=-14},torso={yaw=14},rl={lift=92,out=62,twist=-26,knee=8,ankle=-24},ll={lift=18,knee=52},ra={raise=26,out=78,elbow=22},la={raise=30,out=72,elbow=26}}),"out"),
	K(2,merge(AIR_M,{root={yaw=62,roll=-12},rl={lift=86,out=64,twist=-26,knee=12},ll={lift=18,knee=52},ra={raise=26,out=78,elbow=22},la={raise=30,out=72,elbow=26}})),
	K(3,AIR_M),
}
CLIPS.Flashstep.Slam={ -- double hammer-fist driven straight down
	K(0,merge(AIR_M,{root={pitch=-14},torso={pitch=-22},head={pitch=-14},ra={raise=172,out=8,elbow=42},la={raise=172,out=8,elbow=42},rl={lift=64,knee=112},ll={lift=58,knee=106}})),
	K(1,merge(AIR_M,{root={pitch=26},torso={pitch=44},head={pitch=12},ra={raise=42,out=-12,elbow=6},la={raise=42,out=-12,elbow=6},rl={lift=-14,knee=40},ll={lift=12,knee=62}}),"out"),
	K(2,merge(AIR_M,{root={pitch=30},torso={pitch=46},ra={raise=30,out=-12,elbow=8},la={raise=30,out=-12,elbow=8},rl={lift=-12,knee=36},ll={lift=14,knee=60}})),
	K(3,m({root={y=-.9,pitch=24},torso={pitch=20}})),
}
CLIPS.Flashstep.Grab={
	K(0,m({root={y=-.55,pitch=14},ra={raise=60,out=12,elbow=70},la={raise=60,out=12,elbow=70}})),
	K(1,m({root={y=-.5,z=-.45,pitch=18,yaw=0},torso={yaw=0},ra={raise=86,out=-12,elbow=22},la={raise=86,out=-12,elbow=22},lf={z=-1.1}}),"out"),
	K(3,m({ra={raise=70,out=-6,elbow=60},la={raise=70,out=-6,elbow=60}})),
}
CLIPS.Flashstep.Throw={ -- hip toss: twist and pull across
	K(0,m({root={y=-.6,yaw=20},ra={raise=80,out=-10,elbow=60},la={raise=90,out=10,elbow=90}})),
	K(1,m({root={y=-.62,yaw=-72,pitch=16},torso={yaw=-32,pitch=12},ra={raise=58,out=-52,elbow=62},la={raise=104,out=22,elbow=92},rf={x=.4,z=.1}}),"out"),
	K(3,M),
}
CLIPS.Flashstep.ThrowUp={
	K(0,m({root={y=-.85,pitch=16},ra={raise=70,out=-8,elbow=80},la={raise=70,out=-8,elbow=80}})),
	K(1,m({root={y=.1,pitch=-16},torso={pitch=-12},head={pitch=-20},ra={raise=162,out=6,elbow=18},la={raise=162,out=6,elbow=18},rf={toe=-20},lf={toe=-20}}),"out"),
	K(3,M),
}
-- Itachi --------------------------------------------------------------
CLIPS.Mirage.Light1={ -- compact lead jab
	K(0,i({torso={yaw=10},la={raise=56,out=4,twist=20,elbow=112}})),
	K(1,i({root={z=-.25,yaw=-4,pitch=6},torso={yaw=-16},la={raise=90,out=-6,twist=-18,elbow=4,wrist=0},ra={raise=30,out=10,elbow=96}}),"out"),
	K(2,i({root={z=-.25,yaw=-4,pitch=6},torso={yaw=-18},la={raise=88,out=-6,twist=-18,elbow=8},ra={raise=30,out=10,elbow=96}})),
	K(3,I),
}
CLIPS.Mirage.Light2={ -- right palm, left hand flicks a blade on the way out
	K(0,i({root={yaw=30},torso={yaw=14},ra={raise=40,out=16,twist=10,elbow=112},la={raise=60,out=-30,twist=30,elbow=110}})),
	K(1,i({root={z=-.3,yaw=-10,pitch=6},torso={yaw=-22},ra={raise=88,out=-2,twist=70,elbow=4,wrist=-58},la={raise=72,out=44,twist=-10,elbow=30,wrist=20}}),"out"),
	K(2,i({root={z=-.3,yaw=-12,pitch=6},torso={yaw=-24},ra={raise=86,out=-2,twist=70,elbow=8,wrist=-56},la={raise=64,out=50,elbow=34}})),
	K(3,I),
}
CLIPS.Mirage.Light3={ -- chambered side kick that creates space
	K(0,i({root={y=-.32,yaw=-62,roll=6},torso={yaw=-10},ra={raise=50,out=-6,elbow=118},la={raise=54,out=-6,elbow=120},rl={lift=82,out=12,twist=-18,knee=112,ankle=-8},lf={yaw=-40}})),
	K(1,i({root={y=-.22,yaw=-76,roll=28},torso={roll=-18,yaw=-6},head={roll=-20,yaw=60},ra={raise=50,out=-6,elbow=120},la={raise=30,out=30,elbow=80},rl={lift=86,out=72,knee=0,ankle=12},lf={yaw=-60}}),"out"),
	K(2,i({root={y=-.24,yaw=-76,roll=26},torso={roll=-16},head={roll=-18,yaw=60},ra={raise=50,out=-6,elbow=118},la={raise=30,out=30,elbow=80},rl={lift=82,out=70,knee=6,ankle=10},lf={yaw=-60}})),
	K(3,I),
}
CLIPS.Mirage.Heavy={ -- turning back kick
	K(0,i({root={y=-.4,yaw=96,pitch=6},torso={yaw=20},ra={raise=50,out=-8,elbow=116},la={raise=52,out=-8,elbow=116},lf={yaw=60}})),
	K(1,i({root={y=-.3,yaw=172,pitch=30},torso={pitch=20},head={pitch=-30,yaw=-10},ra={raise=30,out=36,elbow=60},la={raise=20,out=40,elbow=60},rl={lift=-58,out=8,knee=6,ankle=10},lf={yaw=150}}),"out"),
	K(2,i({root={y=-.3,yaw=176,pitch=30},torso={pitch=20},head={pitch=-30},ra={raise=30,out=36,elbow=60},la={raise=20,out=40,elbow=60},rl={lift=-56,out=8,knee=10,ankle=10},lf={yaw=150}})),
	K(2.6,i({root={y=-.36,yaw=200},lf={yaw=160}})),
	K(3,I),
}
CLIPS.Mirage.Launcher={ -- rising palm uppercut
	K(0,i({root={y=-.82,pitch=14},torso={pitch=10},ra={raise=-12,out=14,twist=40,elbow=104},la={raise=52,out=-10,elbow=96},lf={z=-.6},rf={z=.6}})),
	K(1,i({root={y=.18,pitch=-10,yaw=-8},torso={pitch=-12,yaw=-14},head={pitch=-22},ra={raise=166,out=6,twist=70,elbow=8,wrist=-40},la={raise=10,out=24,elbow=40},rf={toe=-22},lf={z=-.6}}),"out"),
	K(2,i({root={y=.15,pitch=-10,yaw=-10},torso={pitch=-12,yaw=-16},head={pitch=-20},ra={raise=160,out=6,twist=70,elbow=12},la={raise=10,out=24,elbow=40},rf={toe=-20},lf={z=-.6}})),
	K(3,I),
}
CLIPS.Mirage.DashAttack={ -- gliding open-palm thrust
	K(0,i({root={y=-.6,z=.2,pitch=22},ra={raise=20,out=20,twist=40,elbow=104},la={raise=50,out=-10,elbow=100},lf={z=-1.0},rf={z=1.1}})),
	K(1,i({root={y=-.56,z=-.85,pitch=20,yaw=-8},torso={yaw=-12},ra={raise=92,out=-4,twist=72,elbow=2,wrist=-62},la={raise=30,out=24,elbow=60},lf={z=-1.5},rf={z=1.3}}),"out"),
	K(2,i({root={y=-.55,z=-.86,pitch=18,yaw=-8},torso={yaw=-14},ra={raise=90,out=-4,twist=72,elbow=6,wrist=-60},la={raise=30,out=24,elbow=60},lf={z=-1.5},rf={z=1.3}})),
	K(3,I),
}
local AIR_I={root={pitch=2},torso={pitch=4},ra={raise=34,out=16,elbow=80},la={raise=42,out=8,elbow=90},rl={lift=48,knee=88},ll={lift=28,knee=64}}
CLIPS.Mirage.Air1={ -- driving knee
	K(0,merge(AIR_I,{rl={lift=60,knee=120},ra={raise=80,out=20,elbow=90},la={raise=80,out=20,elbow=90}})),
	K(1,merge(AIR_I,{root={pitch=14},torso={pitch=18},rl={lift=118,knee=146,ankle=-20},ra={raise=50,out=-10,elbow=96},la={raise=50,out=-10,elbow=96}}),"out"),
	K(2,merge(AIR_I,{root={pitch=14},torso={pitch=18},rl={lift=112,knee=140},ra={raise=50,out=-10,elbow=96},la={raise=50,out=-10,elbow=96}})),
	K(3,AIR_I),
}
CLIPS.Mirage.Air2={ -- tight spinning hook kick
	K(0,merge(AIR_I,{root={yaw=-40},rl={lift=76,out=6,knee=118}})),
	K(1,merge(AIR_I,{root={yaw=48,roll=-10},rl={lift=88,out=58,twist=-20,knee=14,ankle=-20},ll={lift=20,knee=60},ra={raise=24,out=56,elbow=40},la={raise=40,out=-6,elbow=110}}),"out"),
	K(2,merge(AIR_I,{root={yaw=56,roll=-8},rl={lift=84,out=60,knee=20},ll={lift=20,knee=60},ra={raise=24,out=56,elbow=40},la={raise=40,out=-6,elbow=110}})),
	K(3,AIR_I),
}
CLIPS.Mirage.Slam={ -- axe kick
	K(0,merge(AIR_I,{root={pitch=-12},torso={pitch=-10},rl={lift=160,out=4,knee=6,ankle=-30},ll={lift=10,knee=40},ra={raise=30,out=40,elbow=40},la={raise=30,out=40,elbow=40}})),
	K(1,merge(AIR_I,{root={pitch=22},torso={pitch=26},rl={lift=10,out=2,knee=8,ankle=-10},ll={lift=-10,knee=50},ra={raise=20,out=40,elbow=30},la={raise=20,out=40,elbow=30}}),"out"),
	K(2,merge(AIR_I,{root={pitch=24},torso={pitch=26},rl={lift=4,knee=12},ll={lift=-10,knee=50}})),
	K(3,i({root={y=-.8,pitch=16},torso={pitch=14}})),
}
CLIPS.Mirage.Grab={
	K(0,i({root={y=-.4,pitch=10},ra={raise=56,out=10,elbow=80},la={raise=56,out=10,elbow=80}})),
	K(1,i({root={y=-.4,z=-.4,pitch=14},ra={raise=84,out=-10,elbow=24},la={raise=84,out=-10,elbow=24},lf={z=-1.0}}),"out"),
	K(3,i({ra={raise=70,out=-6,elbow=60},la={raise=70,out=-6,elbow=60}})),
}
CLIPS.Mirage.Throw={
	K(0,i({root={y=-.5,yaw=18},ra={raise=78,out=-10,elbow=62},la={raise=88,out=10,elbow=90}})),
	K(1,i({root={y=-.55,yaw=-66,pitch=12},torso={yaw=-28,pitch=10},ra={raise=54,out=-48,elbow=64},la={raise=100,out=20,elbow=90},rf={x=.4,z=.1}}),"out"),
	K(3,I),
}
CLIPS.Mirage.ThrowUp={
	K(0,i({root={y=-.8,pitch=12},ra={raise=70,out=-8,elbow=80},la={raise=70,out=-8,elbow=80}})),
	K(1,i({root={y=.05,pitch=-12},torso={pitch=-10},head={pitch=-18},ra={raise=160,out=6,elbow=16},la={raise=160,out=6,elbow=16},rf={toe=-18},lf={toe=-18}}),"out"),
	K(3,I),
}
-- Rasengan: the Burst Strike release, palm driven forward with the orb.
CLIPS.Flashstep.Rasengan={
	K(0,m({root={y=-.75,z=.2,pitch=26},ra={raise=74,out=8,twist=-70,elbow=62,wrist=10},la={raise=78,out=-30,twist=40,elbow=82},lf={z=-1.2},rf={z=1.2}})),
	K(1,m({root={y=-.62,z=-1.05,pitch=24,yaw=-14},torso={yaw=-16},head={pitch=-14},ra={raise=92,out=-2,twist=-40,elbow=2,wrist=-20},la={raise=40,out=30,elbow=50},lf={z=-1.75},rf={z=1.5,y=.2,toe=-18}}),"out"),
	K(2,m({root={y=-.6,z=-1.08,pitch=22,yaw=-16},torso={yaw=-18},ra={raise=90,out=-2,twist=-40,elbow=4},la={raise=40,out=30,elbow=50},lf={z=-1.75},rf={z=1.5,y=.2,toe=-18}})),
	K(3,M),
}

-- Branch moves ----------------------------------------------------------
-- Minato's AngleStep: a crossing sidestep that cuts on the way past.
CLIPS.Flashstep.AngleStep={
	K(0,m({root={y=-.62,yaw=-30,pitch=12,roll=10},torso={yaw=-24},ra={raise=66,out=-40,twist=36,elbow=110,wrist=-28},la={raise=30,out=30,elbow=60},lf={z=-.4,x=-.4},rf={z=.8,x=.5}})),
	K(1,m({root={y=-.55,yaw=40,pitch=14,roll=-12},torso={yaw=26,roll=-8},head={yaw=-26},ra={raise=84,out=34,twist=-16,elbow=20,wrist=12},la={raise=20,out=40,elbow=50},lf={z=-.9,x=.3},rf={z=.6,x=.8}}),"out"),
	K(2,m({root={y=-.5,yaw=48,pitch=12,roll=-10},torso={yaw=32},ra={raise=70,out=58,twist=-28,elbow=30},la={raise=22,out=40,elbow=54},lf={z=-.9,x=.3},rf={z=.6,x=.8}})),
	K(3,M),
}
-- Itachi's Sweep: drop low, pivot on the lead foot, extended leg reaps.
CLIPS.Mirage.Sweep={
	K(0,i({root={y=-1.05,pitch=24,yaw=-30},torso={pitch=12,yaw=-14},ra={raise=-20,out=40,elbow=30},la={raise=40,out=-10,elbow=100},lf={z=-.6,yaw=-30},rf={z=.8}})),
	K(1,i({root={y=-1.25,pitch=30,yaw=70},torso={pitch=16,yaw=12},head={yaw=-50},ra={raise=-40,out=60,elbow=10},la={raise=30,out=10,elbow=90},rl={lift=20,out=72,twist=-40,knee=6,ankle=-10},lf={z=-.4,yaw=60}}),"out"),
	K(2,i({root={y=-1.2,pitch=28,yaw=120},torso={pitch=14,yaw=16},ra={raise=-40,out=60,elbow=10},la={raise=30,out=10,elbow=90},rl={lift=18,out=70,twist=-40,knee=10},lf={z=-.4,yaw=100}})),
	K(2.7,i({root={y=-.8,yaw=170},lf={yaw=150}})),
	K(3,I),
}
-- Itachi's CounterPalm: the read has already happened; no wind-up, all hip.
CLIPS.Mirage.CounterPalm={
	K(0,i({root={y=-.5,yaw=24,pitch=8},torso={yaw=16},ra={raise=30,out=14,twist=40,elbow=110},la={raise=60,out=-20,elbow=100}})),
	K(1,i({root={y=-.55,z=-.6,yaw=-20,pitch=16},torso={yaw=-24,pitch=8},head={yaw=12},ra={raise=90,out=-2,twist=72,elbow=2,wrist=-62},la={raise=20,out=30,elbow=60},lf={z=-1.25},rf={z=1.0,yaw=20}}),"out"),
	K(2,i({root={y=-.55,z=-.62,yaw=-22,pitch=16},torso={yaw=-26,pitch=8},ra={raise=88,out=-2,twist=72,elbow=6,wrist=-60},la={raise=20,out=30,elbow=60},lf={z=-1.25},rf={z=1.0,yaw=20}})),
	K(3,I),
}

-- Phase 4 -----------------------------------------------------------------
-- Wall dive: crouched against the wall during the startup, then a flying kick
-- with the lead leg straight at the opponent, arms thrown back for balance.
local DIVE_CROUCH={root={pitch=-8,y=-.4},torso={pitch=16},head={pitch=-20},ra={raise=40,out=40,elbow=90},la={raise=40,out=40,elbow=90},
	rl={lift=96,knee=124,ankle=-20},ll={lift=88,knee=118,ankle=-20}}
local DIVE_KICK={root={pitch=-14,roll=-6},torso={pitch=12,yaw=-18},head={pitch=-14,yaw=10},ra={raise=-36,out=46,elbow=26},la={raise=70,out=-14,elbow=96},
	rl={lift=84,out=6,knee=4,ankle=-24},ll={lift=-24,knee=112,ankle=-10}}
CLIPS.Flashstep.WallDive={
	K(0,merge(AIR_M,DIVE_CROUCH)),
	K(1,merge(AIR_M,DIVE_KICK),"out"),
	K(2,merge(AIR_M,DIVE_KICK)),
	K(3,m({root={y=-.9,pitch=18},torso={pitch=12},lf={z=-.8},rf={z=.8}})),
}
CLIPS.Mirage.WallDive={
	K(0,merge(AIR_M,DIVE_CROUCH)),
	-- Itachi dives heel-first and keeps the shuriken hand ready.
	K(1,merge(merge(AIR_M,DIVE_KICK),{torso={yaw=14},la={raise=96,out=10,twist=30,elbow=40},ra={raise=-30,out=40,elbow=30}}),"out"),
	K(2,merge(merge(AIR_M,DIVE_KICK),{torso={yaw=14},la={raise=96,out=10,twist=30,elbow=40},ra={raise=-30,out=40,elbow=30}})),
	K(3,i({root={y=-.9,pitch=18},torso={pitch=12},lf={z=-.8},rf={z=.8}})),
}
-- Airborne Rasengan: the orb raised overhead, then driven straight down
-- with the whole body behind the palm.
CLIPS.Flashstep.RasenganDrop={
	K(0,merge(AIR_M,{root={pitch=-16},torso={pitch=-18,yaw=-10},head={pitch=-20},ra={raise=168,out=12,twist=-40,elbow=30,wrist=-20},la={raise=130,out=-20,twist=30,elbow=70},rl={lift=70,knee=120},ll={lift=60,knee=110}})),
	K(1,merge(AIR_M,{root={pitch=34},torso={pitch=40,yaw=-12},head={pitch=6},ra={raise=50,out=-6,twist=-40,elbow=2,wrist=-30},la={raise=30,out=40,elbow=40},rl={lift=-10,knee=40},ll={lift=20,knee=70}}),"out"),
	K(2,merge(AIR_M,{root={pitch=36},torso={pitch=42,yaw=-12},ra={raise=44,out=-6,twist=-40,elbow=4,wrist=-30},la={raise=30,out=40,elbow=40},rl={lift=-8,knee=38},ll={lift=22,knee=70}})),
	K(3,m({root={y=-1.0,pitch=26},torso={pitch=22},ra={raise=60,out=10,elbow=20},lf={z=-.9},rf={z=.9}})),
}
CLIPS.Mirage.RasenganDrop=CLIPS.Flashstep.RasenganDrop

-- Sample a key list at time `t` on the [0,3] attack timeline.
local function sampleKeys(keys,t)
	if t<=keys[1].at then return built(keys[1].pose) end
	for index=1,#keys-1 do
		local a,b=keys[index],keys[index+1]
		if t<=b.at then
			local span=math.max(b.at-a.at,1e-3)
			local ease=EASE[b.ease] or smooth
			return blend(built(a.pose),built(b.pose),ease((t-a.at)/span))
		end
	end
	return built(keys[#keys].pose)
end
-- Real-seconds -> move timeline, using the exact per-fighter timings the server
-- uses. A small lead compensates for the damping lag so contact frames land on
-- the server's active window.
local LEAD=.03
local function timing(name,fighterId)
	local spec=Attacks[name] or (if name=="RasenganDrop" then Attacks.Slam else Attacks.DashAttack)
	local fighter=Fighters[fighterId]
	local profile=fighter and fighter.AttackProfile and fighter.AttackProfile[name]
	local startup=spec.startup*(profile and profile.startup or 1)
	local active=spec.active*(profile and profile.active or 1)
	local recovery=spec.recovery*(profile and profile.recovery or 1)
	if name=="Rasengan" then startup,active,recovery=.1,.12,.48 end
	return startup,active,recovery
end
local function attackPhase(name,elapsed,fighterId)
	local startup,active,recovery=timing(name,fighterId)
	local t=elapsed+LEAD
	if t<startup then return t/math.max(startup,1e-3),startup,active,recovery end
	if t<startup+active then return 1+(t-startup)/math.max(active,1e-3),startup,active,recovery end
	return 2+math.min(1,(t-startup-active)/math.max(recovery,1e-3)),startup,active,recovery
end
-- Pose + weight of an attack at `elapsed`. The weight stays at 1 through the
-- active window and most of recovery, then fades so the stance takes over.
local function attackTargets(name,elapsed,fighterId)
	local route=CLIPS[fighterId] or CLIPS.Flashstep
	local keys=route[name] or route.Light1
	local phase=attackPhase(name,elapsed,fighterId)
	local weight=if phase<2.55 then 1 else 1-smooth((phase-2.55)/.45)
	return sampleKeys(keys,phase),weight,phase
end

-- --------------------------------------------------------------- throws
-- Upper-body overlays timed on the release frame (seconds relative to throw
-- start; `release` is the server's release delay). Legs keep their gait.
local THROWS={
	Kunai=function(t,release)
		local wind={torso={yaw=26,pitch=-4},head={yaw=-18},ra={raise=150,out=32,twist=-30,elbow=112,wrist=-20},la={raise=82,out=-8,elbow=36}}
		local snap={torso={yaw=-22,pitch=8},head={yaw=6},ra={raise=96,out=6,twist=18,elbow=12,wrist=34},la={raise=24,out=24,elbow=60}}
		local follow={torso={yaw=-26,pitch=10},ra={raise=66,out=-22,twist=10,elbow=30,wrist=20},la={raise=30,out=20,elbow=70}}
		if t<release then return wind,smooth(t/math.max(release*.6,.02)) end
		if t<release+.08 then return snap,1 end
		if t<release+.22 then return follow,1 end
		return follow,1-smooth((t-release-.22)/.16)
	end,
	MarkedKunai=function(t,release)
		local wind={torso={yaw=34,pitch=-8},head={yaw=-22},ra={raise=158,out=36,twist=-34,elbow=118,wrist=-24},la={raise=66,out=-34,twist=30,elbow=122}}
		local snap={torso={yaw=-28,pitch=10},head={yaw=8},ra={raise=98,out=4,twist=16,elbow=8,wrist=36},la={raise=60,out=-32,twist=30,elbow=118}}
		local follow={torso={yaw=-30,pitch=12},ra={raise=62,out=-26,elbow=26,wrist=18},la={raise=58,out=-30,twist=30,elbow=116}}
		if t<release then return wind,smooth(t/math.max(release*.6,.02)) end
		if t<release+.09 then return snap,1 end
		if t<release+.24 then return follow,1 end
		return follow,1-smooth((t-release-.24)/.18)
	end,
	Shuriken=function(t,release)
		local cock={torso={yaw=22},head={yaw=-14},la={raise=70,out=-60,twist=40,elbow=122,wrist=10}}
		local flick={torso={yaw=-16,pitch=4},head={yaw=8},la={raise=86,out=38,twist=-20,elbow=12,wrist=24}}
		if t<release then return cock,smooth(t/math.max(release*.6,.02)) end
		if t<release+.04 then return flick,1 end
		if t<release+.08 then return merge(cock,{la={raise=76,out=-34,elbow=96}}),1 end
		if t<release+.2 then return merge(flick,{la={out=46}}),1 end
		return flick,1-smooth((t-release-.2)/.16)
	end,
}

-- --------------------------------------------------------- technique poses
-- Hand signs cycle through a few distinct seals; the last one is held.
local SEALS={
	{ra={raise=56,out=-30,twist=32,elbow=104,wrist=8},la={raise=56,out=-30,twist=32,elbow=104,wrist=8}},
	{ra={raise=66,out=-26,twist=44,elbow=92,wrist=24},la={raise=62,out=-28,twist=20,elbow=100,wrist=-10}},
	{ra={raise=50,out=-34,twist=18,elbow=116,wrist=-16},la={raise=54,out=-32,twist=40,elbow=110,wrist=14}},
	{ra={raise=60,out=-28,twist=36,elbow=100,wrist=30},la={raise=60,out=-28,twist=36,elbow=100,wrist=30}},
}
local function sealPose(base,t,hold)
	local index=if hold then #SEALS else (math.floor(t/.1)%#SEALS)+1
	return merge(base,merge(SEALS[index],{torso={pitch=6,yaw=-2},head={pitch=8,yaw=0}}))
end
local function castSpec(actor)
	local id=actor.castId
	local fighterId=actor.fighterId
	local base=stance(fighterId)
	local t=actor.castElapsed or 0
	local state=actor.state
	if id=="PhoenixFlower" then
		if state=="TechniqueChannel" then return sealPose(base,t,false) end
		-- Phoenix Flower: a quick sweep of the head across the fan while the hand
		-- ring stays at the mouth.
		local sweep=math.sin(math.clamp(t-(actor.channel or 0),0,.4)*14)*18
		return merge(base,{root={y=-.55,pitch=10,yaw=sweep*.5},torso={pitch=8,yaw=sweep},head={pitch=8,yaw=sweep*.6},
			ra={raise=112,out=-36,twist=22,elbow=146,wrist=-10},la={raise=8,out=28,elbow=30},lf={z=-1.0},rf={z=.95,yaw=24}})
	elseif id=="FireBloom" then
		if state=="TechniqueChannel" then
			-- Signs, then a held tiger seal and a deep inhale before the breath.
			local remaining=(actor.channel or 0)
			if remaining<.14 then return merge(sealPose(base,t,true),{root={pitch=-8,y=-.3},torso={pitch=-16},head={pitch=-14}}) end
			return sealPose(base,t,false)
		end
		-- Katon breath: braced wide stance, hand ring at the mouth, body driving
		-- forward into the blast.
		return merge(base,{root={y=-.62,pitch=16,yaw=6},torso={pitch=12,yaw=-6},head={pitch=12,yaw=-4},
			ra={raise=112,out=-36,twist=22,elbow=146,wrist=-10},la={raise=8,out=28,elbow=30},lf={z=-1.15},rf={z=1.05,yaw=30}})
	elseif id=="MirageCast" then
		return merge(base,{root={y=-.24},head={pitch=4,yaw=-4},ra={raise=110,out=-28,twist=30,elbow=150,wrist=10},la={raise=10,out=12,elbow=30}})
	elseif id=="Read" then
		return merge(base,{root={y=-.45,pitch=6},head={pitch=2},ra={raise=40,out=-16,elbow=110},la={raise=60,out=-20,elbow=104}})
	elseif id=="NeedleFan" then
		if state=="TechniqueChannel" then return merge(base,{torso={yaw=26},la={raise=12,out=-42,twist=30,elbow=112},ra={raise=20,out=10,elbow=60}}) end
		return merge(base,{torso={yaw=-24,pitch=6},la={raise=88,out=54,twist=-24,elbow=8,wrist=24},ra={raise=24,out=18,elbow=60}})
	elseif id=="BurstStrike" then
		-- Rasengan forms in the right palm, the left hand shaping it from above.
		return merge(base,{root={y=-.6,pitch=14,yaw=10},torso={pitch=8},head={pitch=12},ra={raise=72,out=10,twist=-72,elbow=64,wrist=12},la={raise=78,out=-30,twist=42,elbow=84,wrist=-10}})
	elseif id=="WindCut" then
		if state=="TechniqueChannel" then return sealPose(base,t,false) end
		return merge(base,{torso={yaw=-34,pitch=6},ra={raise=88,out=50,elbow=8,wrist=-10},la={raise=40,out=24,elbow=50},root={yaw=-20,y=-.5}})
	elseif id=="Flashstep" then
		if state=="TechniqueChannel" or state=="TechniqueActive" then
			return merge(base,{root={y=-.6,pitch=12},la={raise=66,out=-34,twist=30,elbow=122},ra={raise=40,out=16,elbow=96}})
		end
		-- Arrival: low, balanced, kunai already up — a combat action, not a pop-in.
		return merge(base,{root={y=-1.05,pitch=22,yaw=8},torso={pitch=10},head={pitch=-18},ra={raise=66,out=14,twist=30,elbow=84,wrist=-20},
			la={raise=-8,out=24,elbow=20},lf={z=-1.0,x=-.2},rf={z=1.1,x=.3,yaw=40}})
	elseif id=="Quickstep" then
		return merge(base,{root={y=-.75,pitch=20,roll=12},torso={roll=-8}})
	elseif id=="MarkedBlade" then
		return nil
	end
	return sealPose(base,t,false)
end

-- ------------------------------------------------------------- locomotion
local function planar(v) return if v then Vector3.new(v.X,0,v.Z) else Vector3.zero end
local function stanceTargets(fighterId)
	local base=stance(fighterId)
	local breath=math.sin(elapsedTime*(base.tempo or 6))
	local spec=merge(base,{root={y=base.root.y+breath*.03},torso={pitch=base.torso.pitch+breath*(base.breath or 1)}})
	return build(spec)
end
local function locomotionTargets(char,actor,fighterId,dt)
	local s=stateOf(char)
	local minato=fighterId~="Mirage"
	local root=char:FindFirstChild("HumanoidRootPart")
	local velocity=planar(actor.velocity)
	local speed=velocity.Magnitude
	if speed<1.2 then
		s.phase=0
		return stanceTargets(fighterId),RATE.locomotion
	end
	local localMove=if root then root.CFrame:VectorToObjectSpace(velocity) else Vector3.new(0,0,-speed)
	local dir=Vector3.new(localMove.X,0,localMove.Z)
	dir=if dir.Magnitude>1e-3 then dir.Unit else Vector3.new(0,0,-1)
	local forward=-dir.Z -- +1 moving where the body faces
	local side=dir.X
	local sprint=speed>(if minato then 38 else 34)
	-- Cadence and stride grow with speed but are capped: at anime speeds the
	-- legs blur through a fast cycle instead of taking impossible steps.
	local frequency=math.clamp(speed/(if sprint then 9 else 6.5),1.4,if minato then 3.9 else 3.3)
	s.phase=(s.phase+(dt or 1/60)*frequency)%1
	local phase=s.phase
	local stride=math.clamp(speed*.05,.35,1.45)
	local lift=math.clamp(.28+speed*.013,.28,1.0)
	local duty=if speed<14 then .58 else .4
	local function foot(offset)
		local p=(phase+offset)%1
		local along,height
		if p<duty then
			along=stride*(1-2*p/duty);height=0
		else
			local q=(p-duty)/(1-duty)
			along=-stride+2*stride*smooth(q);height=lift*math.sin(math.pi*q)
		end
		return along,height
	end
	local rAlong,rHeight=foot(0)
	local lAlong,lHeight=foot(.5)
	local swing=math.sin(phase*math.pi*2)
	local bounce=math.abs(math.cos(phase*math.pi*2))
	local alpha=math.clamp(speed/40,0,1)
	local lean=if forward>-.3 then forward*(6+alpha*(if minato then 20 else 13)) else forward*10
	local spec
	if sprint and forward>.3 then
		-- The ninja run: chest low, arms swept back, legs cycling hard.
		spec={root={y=-.55-bounce*.12,pitch=(if minato then 22 else 16),yaw=swing*8},
			torso={pitch=(if minato then 26 else 20),yaw=-swing*10},head={pitch=-30},
			ra={raise=-58+swing*6,out=14,twist=-10,elbow=12},la={raise=-58-swing*6,out=14,twist=-10,elbow=12}}
	else
		local arm=(if minato then 38 else 24)*math.clamp(speed/24,.3,1)
		spec={root={y=-.3-bounce*.1*alpha,pitch=lean,yaw=swing*7*alpha,roll=side*(if minato then 9 else 6)},
			torso={pitch=(if forward<-.3 then -6 else 4),yaw=-swing*11*alpha,roll=-side*6},head={pitch=-lean*.4,yaw=0},
			ra={raise=12-swing*arm,out=12,twist=10,elbow=40+alpha*40},la={raise=12+swing*arm,out=12,twist=10,elbow=40+alpha*40}}
		if not minato then spec.la.raise+=12;spec.la.elbow+=10 end
	end
	-- Feet travel along the movement direction (x right, z back in root space).
	local axis=Vector3.new(dir.X,0,dir.Z)
	local rFoot=-axis*rAlong
	local lFoot=-axis*lAlong
	spec.rf={x=rFoot.X+.05,z=rFoot.Z,y=rHeight,yaw=math.deg(math.atan2(-dir.X,-dir.Z))*.35}
	spec.lf={x=lFoot.X-.05,z=lFoot.Z,y=lHeight,yaw=math.deg(math.atan2(-dir.X,-dir.Z))*.35}
	return build(spec),(if sprint then RATE.chase else RATE.locomotion)
end
local function airTargets(char,actor,fighterId)
	local rise=(actor.velocity and actor.velocity.Y or 0)/70
	local minato=fighterId~="Mirage"
	local spec
	if rise>.25 then
		spec={root={pitch=-4},torso={pitch=-10},head={pitch=-10},ra={raise=-20,out=30,elbow=40},la={raise=60,out=24,elbow=70},
			rl={lift=74,knee=104,ankle=-14},ll={lift=-12,knee=46,ankle=-20}}
	elseif rise<-.3 then
		spec={root={pitch=4},torso={pitch=8},head={pitch=-4},ra={raise=34,out=44,elbow=34},la={raise=30,out=40,elbow=36},
			rl={lift=26,knee=42,ankle=-6},ll={lift=8,knee=30,ankle=-6}}
	else
		spec={root={pitch=8},torso={pitch=10},head={pitch=-8},ra={raise=48,out=22,elbow=96},la={raise=54,out=16,elbow=88},
			rl={lift=62,knee=100,ankle=-10},ll={lift=40,knee=84,ankle=-10}}
	end
	if not minato then spec.ra.out=(spec.ra.out or 0)*.6;spec.la.out=(spec.la.out or 0)*.6 end
	return build(spec),RATE.air
end
-- Running up a wall with chakra: the body stands out from the surface, feet on
-- it, chest to the sky, legs cycling up the wall.
local function wallTargets(char,actor,dt)
	local s=stateOf(char)
	s.phase=(s.phase+(dt or 1/60)*3.2)%1
	local swing=math.sin(s.phase*math.pi*2)
	return build({root={z=1.35,pitch=-78},torso={pitch=10},head={pitch=40},
		ra={raise=-50+swing*20,out=16,elbow=20},la={raise=-50-swing*20,out=16,elbow=20},
		rl={lift=40+swing*36,knee=50-swing*30},ll={lift=40-swing*36,knee=50+swing*30}}),RATE.wall
end
local function chaseTargets(char,actor,dt)
	local s=stateOf(char)
	s.phase=(s.phase+(dt or 1/60)*3)%1
	local swing=math.sin(s.phase*math.pi*2)
	return build({root={pitch=52},torso={pitch=14},head={pitch=-48},ra={raise=-70,out=18,elbow=10},la={raise=-70,out=18,elbow=10},
		rl={lift=40+swing*30,knee=60-swing*20},ll={lift=-20-swing*20,knee=70+swing*10}}),RATE.chase
end

-- ------------------------------------------------------------ reactions
local reactionDuration={HitStun=.24,GuardStun=.42,Knockback=.36,Launched=.5,Juggled=.42,WallSplat=.42,Grabbed=.3}
local function reactionTargets(actor)
	local kind=actor.reaction or "HitStun"
	local elapsed=actor.reactionElapsed or 0
	local t=1-smooth(math.clamp(elapsed/(reactionDuration[kind] or .24),0,1))
	local strong=math.clamp((actor.hitStrength or .4)*1.4,.35,1.4)
	local angle=rad(actor.hitAngle or 0)
	local from=math.cos(angle) -- +1: hit from the front
	local side=math.sin(angle) -- +1: hit from the fighter's right
	local behind=math.max(0,-from)
	if kind=="Launched" or kind=="Juggled" then
		-- Folded around the blow, limbs trailing as the body is carried up.
		local fold=smooth(math.clamp(elapsed/.2,0,1))
		return build({root={pitch=-18*fold,roll=side*10*fold},torso={pitch=-26*fold,yaw=side*16},head={pitch=-22*fold},
			ra={raise=-40*fold,out=40*fold,elbow=30},la={raise=-36*fold,out=38*fold,elbow=26},
			rl={lift=34*fold,knee=60*fold},ll={lift=-6,knee=34*fold}}),RATE.recoil
	end
	if kind=="Knockback" then
		local lift=smooth(math.clamp(elapsed/.12,0,1))
		return build({root={pitch=-22*strong*t-8,roll=side*14*t},torso={pitch=-20*t*strong,yaw=side*24*t},head={pitch=-24*t},
			ra={raise=60*t*strong,out=46*t,elbow=24},la={raise=54*t*strong,out=42*t,elbow=22},
			rl={lift=30*lift,knee=50*lift},ll={lift=-10*lift,knee=30*lift}}),RATE.recoil
	end
	if kind=="GuardStun" then
		return build({root={y=-.55,z=.2*t,pitch=-6*t},torso={pitch=-12*t,roll=side*8*t},ra={raise=78,out=-26,twist=36,elbow=118},la={raise=78,out=-26,twist=36,elbow=118},
			lf={z=-.7},rf={z=.7}}),RATE.recoil
	end
	if kind=="Grabbed" then
		return build({root={y=-.3,pitch=10},torso={pitch=14},head={pitch=18},ra={raise=30,out=24,elbow=60},la={raise=30,out=24,elbow=60},rf={z=.3,toe=-30},lf={z=.2,toe=-30}}),RATE.defense
	end
	if kind=="WallSplat" then
		local splat=smooth(math.clamp(elapsed/.08,0,1))
		return build({root={pitch=-18*splat},torso={pitch=-22*splat},head={pitch=-20*splat},ra={raise=30,out=70*splat,elbow=40},la={raise=30,out=70*splat,elbow=40},
			rl={lift=20,knee=30},ll={lift=10,knee=26}}),RATE.defense
	end
	-- Grounded body hit: the torso and head answer the blow, knees give.
	local pitch=-18*t*strong+behind*34*t*strong
	return build({root={y=-.3-.25*t*strong,z=from*.35*t,pitch=-6*t*strong+behind*14*t,yaw=-side*10*t,roll=-side*8*t},
		torso={pitch=pitch,yaw=-side*24*t,roll=-side*12*t},head={pitch=-16*t*strong+behind*26*t,yaw=-side*14*t},
		ra={raise=30*t*strong,out=34*t,elbow=40},la={raise=26*t*strong,out=30*t,elbow=36},
		rf={z=.25},lf={z=-.35}}),RATE.recoil
end
-- Lying on the floor after a knockdown, then a quick, readable get-up.
local function groundTargets(actor)
	local pose=actor.groundPose or (if actor.reaction=="WallSplat" then "Splat" else "Knockdown")
	local side=actor.groundSide or 1
	local lying={root={y=-2.45,z=.6,pitch=-84,roll=side*14},torso={pitch=-8,roll=side*6},head={pitch=-14,yaw=side*20},
		ra={raise=20,out=62,elbow=24},la={raise=14,out=56,elbow=30},rl={lift=18,out=8,knee=30},ll={lift=6,out=10,knee=12}}
	if pose=="Splat" and actor.reaction=="WallSplat" then
		-- Slid down to the foot of the wall: sitting, back against it, legs out.
		return build({root={y=-1.95,z=.35,pitch=-28},torso={pitch=-10},head={pitch=12,roll=side*8},
			ra={raise=12,out=44,elbow=20},la={raise=10,out=40,elbow=26},rl={lift=78,out=10,knee=22},ll={lift=70,out=14,knee=34}}),RATE.ground
	end
	if pose=="Wakeup" or actor.reaction=="Wakeup" then
		local push=smooth(math.clamp((actor.reactionElapsed or 0)/.24,0,1))
		local crouch={root={y=-1.0,pitch=22},torso={pitch=14},head={pitch=-10},ra={raise=30,out=20,elbow=60},la={raise=40,out=20,elbow=60},lf={z=-.7},rf={z=.6,x=.2}}
		return blend(build(lying),build(crouch),push),RATE.ground*1.6
	end
	return build(lying),RATE.ground
end
local KO={
	light={root={y=-2.45,z=.6,pitch=-84,roll=12},torso={pitch=-6,roll=8},head={pitch=-16,yaw=26},ra={raise=16,out=70,elbow=26},la={raise=10,out=58,elbow=34},rl={lift=20,out=10,knee=34},ll={lift=4,out=8,knee=10}},
	finisher={root={y=-2.5,z=-.6,pitch=86,roll=-10},torso={pitch=6,roll=-6},head={pitch=10,yaw=-30},ra={raise=120,out=40,elbow=40},la={raise=-10,out=20,elbow=20},rl={lift=-6,out=12,knee=40},ll={lift=4,out=4,knee=8}},
	launcher={root={y=-2.3,pitch=-20,roll=78},torso={pitch=24,roll=6},head={pitch=20,roll=10},ra={raise=60,out=-10,elbow=70},la={raise=40,out=10,elbow=50},rl={lift=50,knee=80},ll={lift=30,knee=60}},
	slam={root={y=-2.55,z=.4,pitch=-88},torso={pitch=-2},head={pitch=-6},ra={raise=0,out=85,elbow=6},la={raise=0,out=85,elbow=6},rl={lift=0,out=22,knee=4},ll={lift=0,out=22,knee=4}},
}
local function koTargets(style)
	local key=if style=="finisher" or style=="slam" or style=="launcher" then style else "light"
	return built(KO[key])
end

-- ---------------------------------------------------------- defence poses
local function guardTargets(fighterId,impact)
	local absorbed=math.clamp((impact or 0)/.18,0,1)
	local base=stance(fighterId)
	-- Crossed forearms in front of the face, weight down, braced.
	return build(merge(base,{root={y=-.6,pitch=8-6*absorbed,z=.2*absorbed},torso={pitch=10-10*absorbed,yaw=-4},head={pitch=10},
		ra={raise=92,out=-34,twist=42,elbow=112,wrist=-10},la={raise=96,out=-30,twist=40,elbow=108,wrist=-10}})),RATE.guard
end
local function dodgeTargets(char,actor)
	local root=char:FindFirstChild("HumanoidRootPart")
	local direction=planar(actor.velocity)
	local localMotion=if root and direction.Magnitude>.1 then root.CFrame:VectorToObjectSpace(direction) else Vector3.new(1,0,0)
	local forward=math.clamp(-localMotion.Z/14,-1,1)
	local side=math.clamp(localMotion.X/14,-1,1)
	if math.abs(side)>math.abs(forward)*.8 then
		local s=if side<0 then -1 else 1
		return build({root={y=-.9,roll=s*26,pitch=10},torso={roll=s*12},head={roll=-s*10},ra={raise=50,out=40,elbow=60},la={raise=50,out=40,elbow=60},
			rf={x=s*.6,z=.1},lf={x=s*.6,z=-.1}}),RATE.defense
	elseif forward>=0 then
		return build({root={y=-1.0,pitch=38},torso={pitch=10},head={pitch=-30},ra={raise=-40,out=20,elbow=20},la={raise=-40,out=20,elbow=20},
			lf={z=-1.2},rf={z=1.2,y=.2,toe=-20}}),RATE.defense
	end
	return build({root={y=-.8,pitch=-14,z=.3},torso={pitch=-10},head={pitch=6},ra={raise=70,out=20,elbow=70},la={raise=70,out=20,elbow=70},
		lf={z=-.4},rf={z=1.1}}),RATE.defense
end
local function landTargets(fighterId,strength)
	local base=stance(fighterId)
	local absorb=math.clamp(strength,0,1)
	return build(merge(base,{root={y=base.root.y-.75*absorb,pitch=base.root.pitch+14*absorb},torso={pitch=base.torso.pitch+12*absorb},
		ra={raise=base.ra.raise-10*absorb,out=base.ra.out+18*absorb},la={raise=base.la.raise-10*absorb,out=base.la.out+18*absorb}})),RATE.defense
end

-- --------------------------------------------------------------- weapons
-- Minato keeps a reverse-grip kunai for his cutting strings, a forward-grip
-- kunai for throws and his marked three-pronged kunai for the seal throw.
-- Itachi holds shuriken flat between the fingers of his left hand.
local weapons=setmetatable({},{__mode="k"})
local MELEE={Flashstep={Light1=true,Light2=true,DashAttack=true,Air1=true,AngleStep=true},Mirage={Light2=true,Light1=true,DashAttack=true,Air1=true,Air2=true,Light3=true}}
local function makeItem(hand,model,c0)
	model.Parent=hand
	local root=model.PrimaryPart
	root.Anchored=false;root.Massless=true
	local weld=Instance.new("Weld");weld.Part0=hand;weld.Part1=root;weld.C0=c0;weld.Parent=root
	local parts={}
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") and p~=root then
			p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=false
			table.insert(parts,{part=p,base=p.Transparency})
		end
	end
	return {model=model,parts=parts,visible=true}
end
local function setVisible(item,visible)
	if not item or item.visible==visible then return end
	item.visible=visible
	for _,entry in item.parts do entry.part.Transparency=if visible then entry.base else 1 end
end
local function weaponsFor(char,fighterId)
	local items=weapons[char]
	if items then return items end
	items={}
	weapons[char]=items
	local minato=fighterId~="Mirage"
	local hand=char:FindFirstChild(if minato then "RightHand" else "LeftHand")
	if not hand then weapons[char]=nil;return nil end
	local ok=pcall(function()
		Effects=Effects or require(script.Parent.Effects)
		if minato then
			-- Reverse grip: blade out of the little-finger side, along the forearm.
			items.melee=makeItem(hand,Effects.buildKunai(false),CF(0,-.14,.12)*ANG(math.rad(-12),math.pi,0))
			items.throw=makeItem(hand,Effects.buildKunai(false),CF(0,-.16,-.08)*ANG(math.rad(10),0,0))
			items.marked=makeItem(hand,Effects.buildKunai(true),CF(0,-.16,-.08)*ANG(math.rad(10),0,0))
		else
			items.shuriken=makeItem(hand,Effects.buildShuriken(),CF(0,-.34,-.08)*ANG(0,0,math.pi/2))
		end
	end)
	if not ok then
		-- Headless or partial rigs: fall back to simple blades so the contract holds.
		items={}
		weapons[char]=items
		local blade=Instance.new("WedgePart");blade.Name="CombatBlade";blade.Size=Vector3.new(.1,.3,1);blade.Parent=hand
		blade.CanCollide=false;blade.Massless=true
		items.melee={parts={{part=blade,base=0}},visible=true}
	end
	for _,item in items do setVisible(item,false) end
	return items
end
function Motion.weapon(char,actor)
	local items=weaponsFor(char,actor.fighterId)
	if not items then return end
	local minato=actor.fighterId~="Mirage"
	local name=actor.attackName
	local spec=name and Attacks[name]
	local swinging=name~=nil and actor.state~="Neutral" and actor.state~="Guarding"
	local release=if spec then (function() local s,a,r=timing(name,actor.fighterId);return s+a+r*.45 end)() else .35
	local meleeOut=(swinging and (MELEE[actor.fighterId] or MELEE.Flashstep)[name]==true and (actor.attackElapsed or 0)<=release
		and actor.attackVariant~="Rasengan") or (minato and (actor.intro or 0)>0)
	-- Thrown weapons sit in the hand from the wind-up until their release frame.
	local throwKind=actor.throwKind
	local throwElapsed=actor.throwElapsed or 99
	local releaseAt=actor.throwRelease or .1
	local holding=throwKind~=nil and throwElapsed>=0 and throwElapsed<releaseAt
	if throwKind=="Shuriken" and throwElapsed>=releaseAt and throwElapsed<releaseAt+.08 then holding=throwElapsed>=releaseAt+.03 end
	local castFan=actor.castId=="NeedleFan" and actor.state=="TechniqueChannel"
	if minato then
		setVisible(items.melee,meleeOut and not holding)
		setVisible(items.throw,holding and throwKind=="Kunai")
		setVisible(items.marked,holding and throwKind=="MarkedKunai")
	else
		setVisible(items.shuriken,(meleeOut and (name=="Light2")) or (holding and throwKind=="Shuriken") or castFan)
		if items.melee then setVisible(items.melee,meleeOut and name=="Light2") end
	end
	items.debug=string.format("%s/%s/el=%.2f",tostring(name),tostring(actor.state),actor.attackElapsed or -1)
	items.attackName=name
end
function Motion.weaponState(char)
	local items=weapons[char]
	if not items then return {visible=false,count=0} end
	local count,shown=0,0
	for key,item in items do
		if type(item)=="table" and item.parts then
			for _,entry in item.parts do
				count+=1
				if entry.part.Transparency<.5 then shown+=1 end
			end
		end
	end
	return {visible=shown>0,count=count,shown=shown,attackName=items.attackName,debug=items.debug}
end

-- --------------------------------------------------------- public entries
-- Attack pose on its own (blended over the rest pose): used by tests and tools.
function Motion.pose(char,name,elapsed,fighterId,dt)
	if not Attacks[name] and name~="Rasengan" and name~="RasenganDrop" then return end
	local targets,weight=attackTargets(name,elapsed,fighterId)
	apply(char,blend({},targets,weight),RATE.attack,dt)
end
function Motion.locomotion(char,speed,airborne,velocity,fighterId,dt,actor,now)
	local subject=actor or {velocity=velocity,speed=speed}
	if not subject.velocity then subject=table.clone(subject);subject.velocity=velocity end
	local targets,rate
	if airborne then
		if subject.reaction=="Launched" or subject.reaction=="Juggled" or subject.reaction=="Knockback" then
			targets,rate=reactionTargets(subject)
		else
			targets,rate=airTargets(char,subject,fighterId)
		end
	else
		targets,rate=locomotionTargets(char,subject,fighterId,dt)
	end
	apply(char,targets,rate,dt)
end
function Motion.defense(char,actor,dt)
	local targets,rate
	if actor.state=="Dodging" then
		targets,rate=dodgeTargets(char,actor)
	elseif actor.groundPose or actor.reaction=="Knockdown" or actor.reaction=="Wakeup" then
		targets,rate=groundTargets(actor)
	elseif actor.reaction then
		targets,rate=reactionTargets(actor)
	else
		return
	end
	apply(char,targets,rate,dt)
end
function Motion.recoil(char,elapsed,reaction,heavy,dt)
	local targets,rate=reactionTargets({reaction=reaction,reactionElapsed=elapsed,hitStrength=if heavy then .9 else .45})
	apply(char,targets,rate,dt)
end
function Motion.guard(char,impact,fighterId,dt)
	local targets,rate=guardTargets(fighterId,impact)
	apply(char,targets,rate,dt)
end
function Motion.land(char,actor,fighterId,strength,dt)
	local targets,rate=landTargets(fighterId,strength)
	apply(char,targets,rate,dt)
end
function Motion.ko(char,style,dt)
	apply(char,koTargets(style),RATE.ground,dt)
end
-- One entry point deciding which body this frame shows. Priority is the whole
-- presentation contract: a defeated body settles, a grounded body stays down, an
-- airborne reaction keeps its trajectory, then defence, chase, wall, guard,
-- techniques, attacks, landing and locomotion. Throws layer on the upper body.
function Motion.present(char,actor,clock,dt)
	local elapsed=clock or {}
	local subject=actor
	if elapsed.reactionElapsed or elapsed.attackElapsed then
		subject=table.clone(actor)
		subject.reactionElapsed=elapsed.reactionElapsed or actor.reactionElapsed
		subject.attackElapsed=elapsed.attackElapsed or actor.attackElapsed
	end
	if (subject.health or 1)<=0 then
		apply(char,koTargets(subject.koStyle),RATE.ground,dt)
		return "ko"
	end
	-- Match intro attitude: Minato twirls a kunai, Itachi waits, perfectly still.
	if (subject.intro or 0)>0 and subject.state=="Neutral" then
		local base=stance(subject.fighterId)
		local spec
		if subject.fighterId=="Mirage" then
			spec=merge(base,{root={y=-.1,pitch=0,yaw=8},torso={pitch=-2,yaw=-4},head={pitch=-4,yaw=-6},ra={raise=6,out=6,elbow=14},la={raise=6,out=6,elbow=14}})
		else
			spec=merge(base,{ra={raise=78,out=22,twist=10,elbow=112,wrist=0,wroll=(elapsedTime*1080)%360},la={raise=30,out=14,elbow=40},head={yaw=-18,pitch=-4}})
		end
		apply(char,build(spec),RATE.cast,dt)
		return "intro"
	end
	if subject.groundPose~=nil and subject.airborne~=true then
		local targets,rate=groundTargets(subject)
		apply(char,targets,rate,dt)
		return "ground"
	end
	if subject.reaction and subject.airborne then
		local targets,rate=reactionTargets(subject)
		apply(char,targets,rate,dt)
		return "air reaction"
	end
	if subject.state=="Dodging" or subject.reaction then
		Motion.defense(char,subject,dt)
		return "defense"
	end
	if subject.state=="Pursuit" then
		local targets,rate=chaseTargets(char,subject,dt)
		apply(char,targets,rate,dt)
		return "chase"
	end
	if subject.wall then
		local targets,rate=wallTargets(char,subject,dt)
		apply(char,targets,rate,dt)
		return "wall"
	end
	if subject.state=="Guarding" then
		local targets,rate=guardTargets(subject.fighterId,subject.guardImpact)
		apply(char,targets,rate,dt)
		return "guard"
	end
	local swinging=subject.attackName~=nil and (subject.state=="Startup" or subject.state=="Active" or subject.state=="Recovery")
	local casting=subject.castId~=nil and (subject.state=="TechniqueChannel" or subject.state=="TechniqueActive" or subject.state=="TechniqueRecovery")
	-- The base the body returns to: gait on the ground, air pose in the air.
	local base,baseRate
	if subject.airborne then base,baseRate=airTargets(char,subject,subject.fighterId)
	else base,baseRate=locomotionTargets(char,subject,subject.fighterId,dt) end
	if casting and not swinging then
		local spec=castSpec(subject)
		if spec then
			local targets=build(spec)
			if subject.airborne then
				-- Keep the legs of the air pose; the upper body casts.
				for key in JOINTS do if not UPPER[key] and key~="Root" then targets[key]=base[key] end end
			end
			apply(char,targets,RATE.cast,dt)
			return "technique"
		end
	end
	if swinging then
		local name=if subject.attackVariant=="Rasengan" or subject.attackVariant=="RasenganDrop" then subject.attackVariant else subject.attackName
		local targets,weight=attackTargets(name,subject.attackElapsed or 0,subject.fighterId)
		apply(char,blend(base,targets,weight),RATE.attack,dt)
		return "attack"
	end
	if subject.landing then
		local targets,rate=landTargets(subject.fighterId,if subject.landStrong then 1 else .45)
		apply(char,targets,rate,dt)
		return "landing"
	end
	-- Throw overlay on top of the gait: the arm throws, the legs keep running.
	local throw=subject.throwKind and THROWS[subject.throwKind]
	local throwElapsed=subject.throwElapsed or 99
	if throw and throwElapsed>=0 and throwElapsed<(subject.throwRelease or .1)+.45 then
		local spec,weight=throw(throwElapsed,subject.throwRelease or .1)
		if weight>0 then
			local overlay=build(merge(stance(subject.fighterId),spec))
			local targets=table.clone(base)
			for key in UPPER do targets[key]=(base[key] or IDENTITY):Lerp(overlay[key],weight) end
			apply(char,targets,RATE.throw,dt)
			return "throw"
		end
	end
	apply(char,base,baseRate,dt)
	return "locomotion"
end
-- Hard reset: only for a character switch, rematch, death or destruction.
function Motion.reset(char)
	local s=stateOf(char)
	table.clear(s.pose)
	s.phase=0
	for key in JOINTS do local joint=motor(char,key);if joint then joint.Transform=IDENTITY end end
end
Motion.clear=Motion.reset
return Motion
