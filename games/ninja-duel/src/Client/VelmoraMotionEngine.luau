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
-- Blender-authored clips (Client/AuthoredMotion): where one exists for a
-- strike or a technique, it replaces the procedural pose below.
local Authored=nil
do
	local okA,mod=pcall(function() return require(script.Parent.AuthoredMotion) end)
	if okA then Authored=mod end
end
local Motion={}
Motion.Authored=Authored
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
	if not s then s={motors={},pose={},phase=0,clock=0,inert={},vel={}};states[char]=s end
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
local RATE={attack=42,throw=32,cast=24,recoil=36,guard=26,defense=26,locomotion=22,air=14,ground=12,wall=16,chase=22,chainIn=26,kick=43,
	-- Blender-authored body motion is already the final curve: played almost
	-- as is (a frame of smoothing only to join one clip to the next).
	authored=48}
local KICK_SPEED=1600 -- deg/s cap for a free (kicking) leg during a strike
local CHAIN_IN=.08 -- seconds of a chained strike during which the upper body eases in
local CHAIN_IN_SPEED=800 -- deg/s cap per upper-body joint meanwhile (a strike may whip at 2280)
local MAX_SPEED=1750
-- deg/s: the fastest any authored joint turns (a sprint thigh peaks ~1200,
-- a kick ~1500). The reference footage never moves a limb more than ~25 deg
-- between two 60 Hz frames outside a speed smear. The kunai string (ANIM-005)
-- whips a slash over 2-3 frames and turns a somersault in 9: up to ~35 deg
-- per frame on the arm and the pelvis, so the cap sits above that (a real
-- flip is still drawn over its own frames, a 180 deg pop is still split).
local AUTHORED_SPEED=2200
local function angleBetween(a,b)
	local _,angle=(a:Inverse()*b):ToAxisAngle()
	return math.abs(angle)
end
-- (ANIM-002) Inertialization: when the body changes clip (a strike out of
-- the run, the next blow of a string, a landing, a hit), the new clip plays
-- at its own authored spacing at once and the difference with the body as it
-- was drawn - its pose and its velocity - is carried as an offset that decays
-- on a critically damped spring. Nothing snaps and nothing lags: the old
-- motion flows into the new one (Bollo, "High Performance Animation in Gears
-- of War 4", SIGGRAPH 2017; Holden's spring formulation).
local LN2=0.69314718
local function damper(x,v,half,dt)
	local y=(4*LN2/math.max(half,1e-3))*.5
	local j1=v+x*y
	local e=math.exp(-y*dt)
	return (x+j1*dt)*e,(v-j1*y*dt)*e
end
local function rotVec(cf)
	local axis,angle=cf:ToAxisAngle()
	if angle>math.pi then angle-=2*math.pi end
	if angle~=angle or axis~=axis then return Vector3.zero end
	return axis*angle
end
local function fromRot(v)
	local m=v.Magnitude
	if m<1e-6 then return IDENTITY end
	return CFrame.fromAxisAngle(v/m,m)
end
Motion._damper=damper
-- Write one joint: damp the owned pose towards the target, limit the angular
-- step, then publish it as the Motor6D transform.
local function write(char,key,target,rate,dt)
	local joint=motor(char,key)
	if not joint then return end
	local s=stateOf(char)
	if not dt then s.pose[key]=target;joint.Transform=target;return end
	local current=s.pose[key] or joint.Transform
	local inert=s.inert[key]
	if s.capture and rate==RATE.authored then
		-- A new clip: carry the body's drawn pose and velocity as an offset.
		local off=target:Inverse()*current
		local vel=s.vel[key]
		inert={r=rotVec(off),p=off.Position,vr=vel and vel.w or Vector3.zero,vp=vel and vel.v or Vector3.zero,half=s.capture,t0=target}
		if inert.vr.Magnitude>25 then inert.vr=inert.vr.Unit*25 end
		s.inert[key]=inert
	elseif inert and inert.t0 then
		-- Second frame: the offset's velocity is the old motion minus the new one.
		local tv=rotVec(inert.t0:Inverse()*target)/dt
		inert.vr-=tv;inert.vp-=(target.Position-inert.t0.Position)/dt
		inert.t0=nil
	end
	local desired=target
	if inert then
		inert.r,inert.vr=damper(inert.r,inert.vr,inert.half,dt)
		inert.p,inert.vp=damper(inert.p,inert.vp,inert.half,dt)
		if inert.r.Magnitude<1e-3 and inert.vr.Magnitude<1e-2 and inert.p.Magnitude<1e-3 and inert.vp.Magnitude<1e-2 then
			s.inert[key]=nil
		else
			desired=target*(CF(inert.p)*fromRot(inert.r))
		end
	end
	local nextCF
	if rate==RATE.authored then
		-- Authored motion is the final curve: drawn as is (with its transition
		-- offset). (Fluidity pass, reference: no limb ever jumps.) A joint
		-- turns at most AUTHORED_SPEED: a whip is drawn over two or three
		-- frames instead of one, the eye reads motion, not a pop.
		nextCF=desired
		local step=angleBetween(current,nextCF)
		-- (The Root is the whole body turning in the air - a salto, a spin -
		-- not a limb: it may turn up to 60 deg a frame.)
		local limit=rad(if key=="Root" then 3600 else AUTHORED_SPEED)*dt
		if step>limit and step>1e-6 then nextCF=current:Lerp(nextCF,limit/step) end
	else
		local alpha=1-math.exp(-(rate or RATE.locomotion)*dt)
		nextCF=current:Lerp(desired,alpha)
		local step=angleBetween(current,nextCF)
		-- Strikes may whip faster than ordinary motion so their shape reads.
		local limit=rad(if rate==RATE.chainIn then CHAIN_IN_SPEED elseif rate==RATE.kick then KICK_SPEED elseif (rate or 0)>=RATE.attack then 2280 else MAX_SPEED)*dt
		if step>limit and step>1e-6 then nextCF=current:Lerp(nextCF,limit/step) end
	end
	-- Translation (only the Root carries any) is speed-limited too.
	local move=nextCF.Position-current.Position
	-- (The salto drops the hips ~1 stud a frame onto its landing: authored
	-- motion may carry the Root that fast, or the feet land late.)
	local maxMove=(if rate==RATE.authored then 90 else 14)*dt
	if move.Magnitude>maxMove then nextCF=CF(current.Position+move.Unit*maxMove)*nextCF.Rotation end
	-- The drawn velocity (joint space), for the next transition.
	local vel=s.vel[key] or {}
	vel.w=rotVec(current:Inverse()*nextCF)/dt;vel.v=(nextCF.Position-current.Position)/dt
	s.vel[key]=vel
	s.pose[key]=nextCF
	joint.Transform=nextCF
end
local LEG_SIDE={RightHip="R",RightKnee="R",RightAnkle="R",LeftHip="L",LeftKnee="L",LeftAnkle="L"}
local legIK
-- Name the clip the next apply() draws: a change of name is a transition
-- (inertialized over `half` seconds when the new clip is authored).
local function mark(char,key,half)
	local s=stateOf(char)
	s.markKey=key;s.markHalf=half or .1
end
Motion._mark=mark
local KUNAI_ARM={Right=true,RightElbow=true,RightWrist=true}
local function apply(char,targets,rate,dt,upperRate,legRate)
	local s=stateOf(char)
	local key=s.markKey or ("proc:"..tostring(rate))
	if key~=s.lastMarkKey then
		if s.lastMarkKey~=nil and dt then s.capture=if s.markKey then s.markHalf or .1 else .06 end
		s.lastMarkKey=key
	end
	s.markKey=nil
	local feet=targets.__feet
	-- Global kunai (DEC-030): the drawn blade's arm, laid over any body pose.
	local held=s.armOverlay
	for key in JOINTS do
		local side=LEG_SIDE[key]
		if not (feet and side and feet[side]) then
			local r=if upperRate and UPPER[key] then upperRate elseif legRate and side then legRate else rate
			local target=targets[key] or IDENTITY
			if held and KUNAI_ARM[key] and held.pose[key] then target=target:Lerp(held.pose[key],held.w) end
			write(char,key,target,r,dt)
		end
	end
	s.capture=nil
	if feet then
		-- The hips are damped; a planted foot must not be. Solve each planted leg
		-- against the hips as drawn this frame and set it almost at once.
		local hips=s.pose.Root or targets.Root
		s.ikOn=s.ikOn or {};s.ikEnter=s.ikEnter or {}
		for side,f in feet do
			local prefix=if side=="R" then "Right" else "Left"
			local target=f.ankle
			-- (ANIM-005) A leg handed from a drawn pose (a get-up, an air pose,
			-- a reaction) to the feet solver starts from where its ankle was and
			-- reaches the solver's spot over 0.1 s; it jumped there in one frame.
			if not s.ikOn[side] and dt and s.pose[prefix.."Hip"] then
				local sg=if side=="R" then 1 else -1
				local from=(s.pose.Root or IDENTITY)*CF(.5*sg,-.55,0)*(s.pose[prefix.."Hip"] or IDENTITY)*CF(0,-1.05,0)
					*(s.pose[prefix.."Knee"] or IDENTITY)*CF(0,-1,0)
				local rootPart=char:FindFirstChild("HumanoidRootPart")
				-- (held in the world: a lerp in root space crept with the body)
				if rootPart and (from.Position-target).Magnitude>.3 then
					s.ikEnter[side]={from=rootPart.CFrame:PointToWorldSpace(from.Position),at=elapsedTime}
				end
			end
			-- (An authored clip's planted foot is exact; the hand-over blend only
			-- carries a foot that is still on its way.)
			if f.planted and rate==RATE.authored then s.ikEnter[side]=nil end
			local enter=s.ikEnter[side]
			if enter then
				local u=(elapsedTime-enter.at)/.1
				local rootPart=char:FindFirstChild("HumanoidRootPart")
				if u>=1 or not rootPart then s.ikEnter[side]=nil else
					u=math.max(u,0);target=rootPart.CFrame:PointToObjectSpace(enter.from):Lerp(target,u*u*(3-2*u))
				end
			end
			local hip,knee,ankle=legIK(hips,if side=="R" then 1 else -1,target,f.yaw,f.toe)
			for _,j in {prefix.."Hip",prefix.."Knee",prefix.."Ankle"} do s.inert[j]=nil end
			-- (Authored: exact, a damped leg lets the foot creep with the body.)
			local legRate2=if rate==RATE.authored then RATE.authored else 60
			-- (A foot planted by an authored clip is exact: its knee and hip go
			-- where the hips take them this frame. Speed-capped, the leg lagged
			-- behind a landing and the "planted" foot slid down onto the floor.)
			local legDt=if rate==RATE.authored and f.planted and not enter then nil else dt
			write(char,prefix.."Hip",hip,legRate2,legDt);write(char,prefix.."Knee",knee,legRate2,legDt);write(char,prefix.."Ankle",ankle,legRate2,legDt)
		end
	end
	s.ikOn=s.ikOn or {}
	s.ikOn.R=feet~=nil and feet.R~=nil;s.ikOn.L=feet~=nil and feet.L~=nil
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
function legIK(rootCF,side,ankle,footYaw,toe)
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
			-- Remember the planted foot: apply() re-solves the leg against the
			-- hips actually drawn this frame, so the foot stays where it was put.
			out.__feet=out.__feet or {}
			out.__feet[if side==1 then "R" else "L"]={ankle=ankle,yaw=foot.yaw or 0,toe=foot.toe or 0}
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
	local fa,fb=a.__feet,b.__feet
	if fa and fb then
		for _,side in {"R","L"} do
			local x,y=fa[side],fb[side]
			if x and y then
				out.__feet=out.__feet or {}
				out.__feet[side]={ankle=x.ankle:Lerp(y.ankle,t),yaw=x.yaw+(y.yaw-x.yaw)*t,toe=x.toe+(y.toe-x.toe)*t}
			end
		end
	end
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
-- Neji: the Gentle Fist stance. Side-on and low, lead palm extended toward the
-- opponent, rear palm guarding the centre line.
STANCE.GentleFist={root={y=-.62,pitch=6,yaw=38},torso={pitch=4,yaw=-14},head={pitch=-2,yaw=-22},
	la={raise=80,out=-6,twist=-40,elbow=26,wrist=-46},ra={raise=56,out=-30,twist=40,elbow=96,wrist=-36},
	rf={x=.32,z=.92,yaw=64},lf={x=-.18,z=-.95,yaw=-6},breath=.8,tempo=5.5}
-- Sasuke: low and forward, lead hand out, rear hand by the chin, coiled to kick.
STANCE.Lion={root={y=-.5,pitch=10,yaw=30},torso={pitch=6,yaw=-14},head={pitch=-6,yaw=-14},
	la={raise=66,out=6,twist=10,elbow=64,wrist=0},ra={raise=52,out=-16,twist=24,elbow=118,wrist=0},
	rf={x=.26,z=.84,yaw=38},lf={x=-.1,z=-.76,yaw=-6},breath=1.3,tempo=7}
-- Motion families: the character production framework (DEC-015). A fighter
-- names the body language it is built from (stance, gait, clip set), its
-- weapon family and its intro; a new fighter declares `Motion = {body=...,
-- weapons=..., clips=...}` in Fighters instead of silently inheriting Minato.
-- Bespoke stance/clips by its own id still win over the family.
-- Identity traits are declared, never inferred from the body: `awakenPosture`
-- ("curse": Sasuke's hunched Curse Mark guard) does not follow his kicks into
-- another fighter's family (Rock Lee is built on them).
local FAMILY={
	Flashstep={body="Flashstep",weapons="kunai",springy=true},
	Mirage={body="Mirage",weapons="shuriken",springy=false},
	GentleFist={body="GentleFist",weapons="palms",springy=false},
	Lion={body="Lion",weapons="wire",springy=true,awakenPosture="curse"},
	Sand={body="Sand",weapons="none",springy=false},
}
local function familyOf(id)
	local f=FAMILY[id]
	if f then return f end
	local def=Fighters[id]
	if def and def.Motion then return def.Motion end
	return FAMILY.Flashstep
end
Motion.familyOf=familyOf
-- Gaara: upright and still, arms folded across the chest, feet close. He does
-- not fight with his body: the sand moves, he barely does.
STANCE.Sand={root={y=-.06,pitch=0,yaw=6},torso={pitch=-2,yaw=-2},head={pitch=6,yaw=-4},
	ra={raise=62,out=-42,twist=44,elbow=122,wrist=0},la={raise=58,out=-46,twist=40,elbow=118,wrist=0},
	rf={x=.06,z=.22,yaw=8},lf={x=-.06,z=-.2,yaw=-4},breath=.35,tempo=3.6}
-- Rock Lee (stress-test wave, DEC-015): the Strong Fist stance. Side-on, low
-- and springy, the lead hand open and held out at the opponent, the rear hand
-- folded behind the small of the back. His family (Fighters.Leaf.Motion) is
-- Sasuke's kicks; this stance and a few clips (CLIPS.Leaf) are his own.
STANCE.Leaf={root={y=-.58,pitch=8,yaw=36},torso={pitch=5,yaw=-16},head={pitch=-4,yaw=-22},
	la={raise=92,out=-8,twist=-24,elbow=24,wrist=-30},ra={raise=-48,out=-4,twist=96,elbow=68,wrist=0},
	rf={x=.3,z=.92,yaw=46},lf={x=-.12,z=-.88,yaw=-8},breath=1.5,tempo=8.5}
-- A breadth-pass fighter may carry its own stance in data (Motion.stance).
local function stance(id) return STANCE[id] or familyOf(id).stance or STANCE[familyOf(id).body] or STANCE.Flashstep end
-- Gait families: springy (Minato, Sasuke) or controlled (Itachi, Neji).
local SPRINGY={Flashstep=true,Lion=true}
local function springy(id)
	local f=familyOf(id)
	if f.springy~=nil then return f.springy end
	return SPRINGY[f.body]==true
end

-- ---------------------------------------------------------- attack clips
-- Keys are placed on the move's own timeline: 0 = start, 1 = end of startup
-- (contact), 2 = end of active, 3 = end of recovery. `w` fades the clip out
-- over the tail of recovery so the body returns into its stance.
local function K(at,pose,ease) return {at=at,pose=pose,ease=ease or "smooth"} end
local M=STANCE.Flashstep
local I=STANCE.Mirage
local function m(over) return merge(M,over) end
local function i(over) return merge(I,over) end
local N=STANCE.GentleFist
local function n(over) return merge(N,over) end
local CLIPS={Flashstep={},Mirage={},GentleFist={},Lion={},Sand={}}
-- Read-only view for the headless suites (which clips a fighter authors).
Motion.CLIPS=CLIPS
-- Gaara ---------------------------------------------------------------
-- He barely moves: one hand unfolds and flicks the sand out, then folds back.
local G=STANCE.Sand
local function g(over) return merge(G,over) end
CLIPS.Sand.Light1={ -- right hand flicks the sand out, palm open
	K(0,g({torso={yaw=6},ra={raise=72,out=-14,twist=10,elbow=94,wrist=0}})),
	K(1,g({torso={yaw=-12},head={yaw=4},ra={raise=94,out=8,twist=-6,elbow=8,wrist=-42}}),"out"),
	K(2,g({torso={yaw=-12},ra={raise=92,out=8,twist=-6,elbow=12,wrist=-40}})),
	K(3,G),
}
CLIPS.Sand.Light2={ -- the left hand answers
	K(0,g({torso={yaw=-6},la={raise=72,out=-14,twist=10,elbow=94,wrist=0}})),
	K(1,g({torso={yaw=12},head={yaw=-4},la={raise=94,out=8,twist=-6,elbow=8,wrist=-42}}),"out"),
	K(2,g({torso={yaw=12},la={raise=92,out=8,twist=-6,elbow=12,wrist=-40}})),
	K(3,G),
}
CLIPS.Sand.Light3={ -- both palms push: the sand wave throws the body back
	K(0,g({root={z=.15},ra={raise=66,out=-6,elbow=100},la={raise=66,out=-6,elbow=100}})),
	K(1,g({root={z=.25,pitch=-3},torso={pitch=-4},ra={raise=90,out=10,elbow=10,wrist=-44},la={raise=90,out=10,elbow=10,wrist=-44}}),"out"),
	K(2,g({root={z=.25,pitch=-3},ra={raise=88,out=10,elbow=14,wrist=-40},la={raise=88,out=10,elbow=14,wrist=-40}})),
	K(3,G),
}
CLIPS.Sand.SandPillar={ -- the hand rises palm up: sand erupts under the opponent
	K(0,g({root={y=-.12},head={pitch=12},ra={raise=40,out=10,twist=-30,elbow=100,wrist=30}})),
	K(1,g({root={y=.02,pitch=-4},torso={pitch=-6},head={pitch=-14},ra={raise=152,out=18,twist=-30,elbow=36,wrist=40}}),"out"),
	K(2,g({root={pitch=-4},torso={pitch=-6},head={pitch=-14},ra={raise=150,out=18,twist=-30,elbow=38,wrist=40}})),
	K(3,G),
}
CLIPS.Sand.Sweep={ -- the arm sweeps low: sand reaps the legs
	K(0,g({root={y=-.15},ra={raise=30,out=62,twist=0,elbow=40,wrist=0}})),
	K(1,g({root={y=-.2},torso={yaw=-20},ra={raise=16,out=-34,twist=0,elbow=24,wrist=-30}}),"out"),
	K(2,g({root={y=-.2},torso={yaw=-22},ra={raise=16,out=-36,elbow=26,wrist=-30}})),
	K(3,G),
}
CLIPS.Sand.DashAttack={ -- gliding forward on the sand, both hands out
	K(0,g({root={pitch=6},ra={raise=70,out=-8,elbow=90},la={raise=70,out=-8,elbow=90}})),
	K(1,g({root={pitch=10,z=-.2},ra={raise=88,out=14,elbow=12,wrist=-40},la={raise=86,out=14,elbow=14,wrist=-40}}),"out"),
	K(2,g({root={pitch=10,z=-.2},ra={raise=86,out=14,elbow=14,wrist=-40},la={raise=84,out=14,elbow=16,wrist=-40}})),
	K(3,G),
}
CLIPS.Sand.Air1=CLIPS.Sand.Light1
CLIPS.Sand.Air2=CLIPS.Sand.Light2
CLIPS.Sand.Slam={ -- both hands drive down: the sand crashes on the body
	K(0,g({ra={raise=150,out=10,elbow=40},la={raise=150,out=10,elbow=40}})),
	K(1,g({torso={pitch=10},ra={raise=40,out=-6,elbow=10,wrist=-30},la={raise=40,out=-6,elbow=10,wrist=-30}}),"out"),
	K(2,g({torso={pitch=10},ra={raise=38,out=-6,elbow=12},la={raise=38,out=-6,elbow=12}})),
	K(3,G),
}
CLIPS.Sand.Riposte=CLIPS.Sand.Light1
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
	K(1,m({root={y=-.32,yaw=62,pitch=-6,roll=-20},torso={yaw=12,roll=-24},head={roll=14,yaw=-30},ra={raise=-6,out=40,elbow=46},la={raise=62,out=-6,twist=18,elbow=104},rl={lift=86,out=56,twist=-28,knee=10,ankle=-24},lf={z=-.3,yaw=40}}),"out"),
	K(2,m({root={y=-.34,yaw=76,pitch=-4,roll=-18},torso={yaw=16,roll=-20},ra={raise=-4,out=40,elbow=48},la={raise=60,out=-6,twist=18,elbow=104},rl={lift=80,out=60,twist=-30,knee=16,ankle=-20},lf={z=-.3,yaw=55}})),
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

-- Minato's KneeStrike: hands pull the opponent down onto a rising knee.
CLIPS.Flashstep.KneeStrike={
	K(0,m({root={y=-.5,z=.1,pitch=6},torso={pitch=4},ra={raise=86,out=-10,elbow=60},la={raise=86,out=-10,elbow=60},rl={lift=40,knee=80}})),
	K(1,m({root={y=-.2,z=-.5,pitch=-6},torso={pitch=14},head={pitch=10},ra={raise=60,out=-16,elbow=90,wrist=-20},la={raise=60,out=-16,elbow=90,wrist=-20},rl={lift=112,knee=138,ankle=-20},lf={toe=-24}}),"out"),
	K(2,m({root={y=-.22,z=-.52,pitch=-4},torso={pitch=12},ra={raise=58,out=-16,elbow=92},la={raise=58,out=-16,elbow=92},rl={lift=104,knee=134},lf={toe=-20}})),
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

-- Neji ----------------------------------------------------------------
-- Gentle Fist: open palms driven by the hips, never fists. Every strike turns
-- the waist through the target; the rear hand stays on the centre line.
local PALM_L={raise=90,out=-4,twist=-72,elbow=2,wrist=-62}
local PALM_R={raise=90,out=-2,twist=72,elbow=2,wrist=-62}
CLIPS.GentleFist.Light1={ -- lead palm to the chest
	K(0,n({root={y=-.66,yaw=48},torso={yaw=-6},la={raise=60,out=-10,twist=-60,elbow=100,wrist=-40}})),
	K(1,n({root={y=-.6,z=-.38,yaw=18,pitch=8},torso={yaw=-24,pitch=4},head={yaw=-10},la=PALM_L,ra={raise=50,out=-26,twist=40,elbow=100}}),"out"),
	K(2,n({root={y=-.6,z=-.4,yaw=16,pitch=8},torso={yaw=-26,pitch=4},la=PALM_L,ra={raise=50,out=-26,twist=40,elbow=100}})),
	K(3,N),
}
CLIPS.GentleFist.Light2={ -- rear palm, hips turning square
	K(0,n({root={y=-.66,yaw=46},torso={yaw=10},ra={raise=46,out=10,twist=60,elbow=112,wrist=-30},la={raise=70,out=-6,elbow=60}})),
	K(1,n({root={y=-.58,z=-.46,yaw=-12,pitch=10},torso={yaw=-30,pitch=6},head={yaw=8},ra=PALM_R,la={raise=40,out=10,twist=-40,elbow=96},lf={z=-1.05},rf={z=.7,x=.2}}),"out"),
	K(2,n({root={y=-.58,z=-.48,yaw=-14,pitch=10},torso={yaw=-32,pitch=6},ra=PALM_R,la={raise=40,out=10,twist=-40,elbow=96},lf={z=-1.05},rf={z=.7,x=.2}})),
	K(3,N),
}
CLIPS.GentleFist.Light3={ -- twin palms from the hips: the shove that creates space
	K(0,n({root={y=-.86,z=.22,yaw=12,pitch=6},torso={yaw=0},ra={raise=20,out=6,twist=50,elbow=118,wrist=-20},la={raise=20,out=6,twist=-50,elbow=118,wrist=-20},lf={z=-1.0},rf={z=.9}})),
	K(1,n({root={y=-.62,z=-.85,yaw=4,pitch=16},torso={yaw=-4,pitch=8},head={yaw=-4},ra={raise=86,out=-8,twist=72,elbow=4,wrist=-64},la={raise=86,out=-8,twist=-72,elbow=4,wrist=-64},lf={z=-1.55},rf={z=1.2,toe=-18}}),"out"),
	K(2,n({root={y=-.62,z=-.88,yaw=4,pitch=16},torso={yaw=-4,pitch=8},ra={raise=84,out=-8,twist=72,elbow=8,wrist=-62},la={raise=84,out=-8,twist=-72,elbow=8,wrist=-62},lf={z=-1.55},rf={z=1.2,toe=-18}})),
	K(3,N),
}
CLIPS.GentleFist.Heavy={ -- deep stepping palm: the whole body coils, then drives through
	K(0,n({root={y=-.92,z=.3,yaw=74,pitch=10},torso={yaw=18,pitch=6},la={raise=30,out=-4,twist=-50,elbow=120,wrist=-30},ra={raise=70,out=-30,elbow=80},lf={z=-1.05},rf={z=1.0,yaw=70}})),
	K(.75,n({root={y=-.98,z=.34,yaw=80,pitch=12},torso={yaw=22,pitch=8},la={raise=26,out=-4,twist=-52,elbow=124,wrist=-30},ra={raise=72,out=-30,elbow=78},lf={z=-1.1},rf={z=1.05,yaw=72}})),
	K(1,n({root={y=-.64,z=-1.0,yaw=-6,pitch=20},torso={yaw=-28,pitch=10},head={yaw=12},la={raise=92,out=-4,twist=-72,elbow=0,wrist=-64},ra={raise=-10,out=24,elbow=60},lf={z=-1.7},rf={z=1.25,yaw=20,toe=-20}}),"out"),
	K(2,n({root={y=-.64,z=-1.02,yaw=-8,pitch=20},torso={yaw=-30,pitch=10},la={raise=90,out=-4,twist=-72,elbow=4,wrist=-62},ra={raise=-10,out=24,elbow=60},lf={z=-1.7},rf={z=1.25,yaw=20,toe=-20}})),
	K(3,N),
}
CLIPS.GentleFist.Launcher={ -- rising palm heel under the chin
	K(0,n({root={y=-.98,pitch=16,yaw=30},torso={pitch=10},la={raise=-10,out=12,twist=-40,elbow=108},ra={raise=60,out=-24,elbow=90},lf={z=-.7},rf={z=.7}})),
	K(1,n({root={y=.12,pitch=-10,yaw=10},torso={pitch=-12,yaw=-10},head={pitch=-22},la={raise=168,out=4,twist=-70,elbow=6,wrist=-40},ra={raise=20,out=24,elbow=50},lf={toe=-24},rf={z=.6}}),"out"),
	K(2,n({root={y=.1,pitch=-10,yaw=8},torso={pitch=-12,yaw=-12},head={pitch=-20},la={raise=162,out=4,twist=-70,elbow=10},ra={raise=20,out=24,elbow=50},lf={toe=-20},rf={z=.6}})),
	K(3,N),
}
CLIPS.GentleFist.DashAttack={ -- gliding lead palm
	K(0,n({root={y=-.8,z=.2,pitch=24,yaw=30},la={raise=40,out=-6,twist=-50,elbow=104},ra={raise=60,out=-24,elbow=90},lf={z=-1.1},rf={z=1.15}})),
	K(1,n({root={y=-.72,z=-.95,pitch=22,yaw=6},torso={yaw=-18},la=PALM_L,ra={raise=30,out=20,elbow=70},lf={z=-1.6},rf={z=1.35,toe=-18}}),"out"),
	K(2,n({root={y=-.72,z=-.96,pitch=20,yaw=4},torso={yaw=-20},la=PALM_L,ra={raise=30,out=20,elbow=70},lf={z=-1.6},rf={z=1.35,toe=-18}})),
	K(3,N),
}
CLIPS.GentleFist.PalmThrust={ -- twin palm thrust: the counter that throws a body into a wall
	K(0,n({root={y=-1.0,z=.32,yaw=8,pitch=8},torso={yaw=0,pitch=4},ra={raise=14,out=8,twist=50,elbow=124,wrist=-20},la={raise=14,out=8,twist=-50,elbow=124,wrist=-20},lf={z=-1.1},rf={z=1.0}})),
	K(1,n({root={y=-.6,z=-1.15,yaw=2,pitch=20},torso={yaw=-2,pitch=10},head={pitch=-4},ra={raise=94,out=-10,twist=72,elbow=0,wrist=-66},la={raise=94,out=-10,twist=-72,elbow=0,wrist=-66},lf={z=-1.8},rf={z=1.35,toe=-24}}),"out"),
	K(2,n({root={y=-.6,z=-1.18,yaw=2,pitch=20},torso={yaw=-2,pitch=10},ra={raise=92,out=-10,twist=72,elbow=4,wrist=-64},la={raise=92,out=-10,twist=-72,elbow=4,wrist=-64},lf={z=-1.8},rf={z=1.35,toe=-24}})),
	K(3,N),
}
-- Anything Neji does not author yet (air strings, throws, sweep) borrows
-- Itachi's controlled clips rather than Minato's.
setmetatable(CLIPS.GentleFist,{__index=CLIPS.Mirage})

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

-- Running taijutsu ---------------------------------------------------------
-- Out of a full sprint: a flying kick (strike) or a sliding sweep (heavy).
local function runningClips(f,base)
	CLIPS[f].FlyingKick={
		K(0,merge(base,{root={y=-.2,pitch=-8},torso={pitch=-4},ra={raise=-30,out=40,elbow=40},la={raise=60,out=10,elbow=90},rl={lift=70,knee=120,ankle=-10},ll={lift=-10,knee=40}})),
		K(1,merge(base,{root={y=.35,pitch=-16,yaw=-10},torso={pitch=6,yaw=-14},head={pitch=10},ra={raise=-40,out=56,elbow=20},la={raise=74,out=-10,elbow=96},rl={lift=92,out=4,knee=2,ankle=-24},ll={lift=-18,knee=112,ankle=-10}}),"out"),
		K(2,merge(base,{root={y=.3,pitch=-14,yaw=-10},torso={pitch=6,yaw=-14},ra={raise=-40,out=56,elbow=20},la={raise=74,out=-10,elbow=96},rl={lift=88,out=4,knee=6,ankle=-24},ll={lift=-18,knee=112}})),
		K(3,base),
	}
	CLIPS[f].SlideSweep={
		K(0,merge(base,{root={y=-1.0,pitch=14},torso={pitch=10},ra={raise=30,out=40,elbow=60},la={raise=60,out=20,elbow=80}})),
		K(1,merge(base,{root={y=-1.7,pitch=-28,yaw=14},torso={pitch=-6,yaw=-10},head={pitch=20},ra={raise=-10,out=70,elbow=10},la={raise=70,out=20,elbow=90},rl={lift=84,out=10,knee=2,ankle=-30},ll={lift=30,knee=118,ankle=-10}}),"out"),
		K(2,merge(base,{root={y=-1.7,pitch=-26,yaw=16},torso={pitch=-6,yaw=-10},ra={raise=-10,out=70,elbow=10},la={raise=70,out=20,elbow=90},rl={lift=80,out=10,knee=6,ankle=-30},ll={lift=30,knee=118}})),
		K(2.6,merge(base,{root={y=-1.1,pitch=8},rl={lift=50,knee=80},ll={lift=20,knee=100}})),
		K(3,base),
	}
end
runningClips("Flashstep",M);runningClips("Mirage",I);runningClips("GentleFist",N);runningClips("Lion",STANCE.Lion)
-- Directional routes ------------------------------------------------------
-- The same grammar, three bodies. Low route: Minato drops into a spinning leg
-- sweep (a marked kunai left behind), Itachi reaps with the extended leg, Neji
-- turns a full rotation low with a palm on the ground. Lateral route: Minato's
-- AngleStep, Itachi's feint step (an afterimage stays), Neji's circular step.
CLIPS.Flashstep.Sweep={
	K(0,m({root={y=-1.05,pitch=22,yaw=-20},torso={pitch=10,yaw=-10},ra={raise=44,out=30,twist=30,elbow=96,wrist=-20},la={raise=26,out=24,elbow=30},lf={x=.5,z=-.25},rf={z=.75}})),
	K(1,m({root={y=-1.45,pitch=30,yaw=84},torso={pitch=14,yaw=8},head={yaw=-58},la={raise=18,out=46,elbow=6,wrist=-30},ra={raise=60,out=40,twist=20,elbow=84},rl={lift=16,out=78,twist=-40,knee=4,ankle=-12},lf={x=.5,z=-.1,yaw=84}}),"out"),
	K(2,m({root={y=-1.4,pitch=28,yaw=160},torso={pitch=12,yaw=10},head={yaw=-70},la={raise=14,out=50,elbow=8},ra={raise=56,out=44,elbow=86},rl={lift=14,out=76,twist=-40,knee=6,ankle=-12},lf={x=.5,z=-.1,yaw=160}})),
	K(2.5,m({root={y=-1.1,pitch=20,yaw=250},torso={pitch=8},head={yaw=-40},rl={lift=36,out=40,knee=50},lf={x=.5,z=0,yaw=250}})),
	K(2.8,m({root={y=-.7,pitch=12,yaw=330},lf={x=.3,z=-.4,yaw=330},rf={x=.1,z=.6,yaw=330}})),
	K(3,merge(M,{root={yaw=M.root.yaw+360}})),
}
CLIPS.GentleFist.Sweep={
	K(0,n({root={y=-1.15,pitch=26,yaw=10},torso={pitch=14,yaw=-10},la={raise=30,out=24,elbow=20,wrist=-40},ra={raise=60,out=-20,twist=40,elbow=96},lf={x=.5,z=-.2},rf={z=.8}})),
	K(1,n({root={y=-1.55,pitch=32,yaw=100},torso={pitch=16,yaw=10},head={yaw=-70},la={raise=26,out=40,elbow=8,wrist=-50},ra={raise=40,out=30,twist=60,elbow=20,wrist=-50},rl={lift=12,out=80,twist=-40,knee=4,ankle=-12},lf={x=.5,z=-.1,yaw=100}}),"out"),
	K(2,n({root={y=-1.5,pitch=30,yaw=190},torso={pitch=14,yaw=12},head={yaw=-70},la={raise=24,out=42,elbow=8},ra={raise=40,out=36,twist=60,elbow=20},rl={lift=12,out=80,twist=-40,knee=6,ankle=-12},lf={x=.5,z=-.1,yaw=190}})),
	K(2.5,n({root={y=-1.2,pitch=24,yaw=280},torso={pitch=10},rl={lift=30,out=50,knee=40},lf={x=.5,z=0,yaw=280}})),
	K(3,merge(N,{root={yaw=N.root.yaw+360}})),
}
CLIPS.Mirage.FeintStep={ -- slips to the flank (an afterimage stays) and palms the ribs
	K(0,i({root={y=-.5,yaw=-40,roll=8},torso={yaw=-16},ra={raise=30,out=20,twist=40,elbow=110},la={raise=56,out=-20,elbow=100},lf={x=-.5,z=-.2},rf={x=.4,z=.6}})),
	K(1,i({root={y=-.5,z=-.3,yaw=36,pitch=12,roll=-10},torso={yaw=-28,pitch=6},head={yaw=-20},ra={raise=90,out=-4,twist=72,elbow=2,wrist=-60},la={raise=30,out=30,elbow=70},lf={x=.3,z=-.8},rf={x=.6,z=.7}}),"out"),
	K(2,i({root={y=-.5,z=-.32,yaw=40,pitch=12,roll=-8},torso={yaw=-30,pitch=6},ra={raise=88,out=-4,twist=72,elbow=6,wrist=-58},la={raise=30,out=30,elbow=70},lf={x=.3,z=-.8},rf={x=.6,z=.7}})),
	K(3,I),
}
CLIPS.GentleFist.CircleStep={ -- a circular step around the guard, palm into the flank
	K(0,n({root={y=-.7,yaw=70,roll=6},torso={yaw=-10},la={raise=60,out=-10,twist=-60,elbow=100,wrist=-40},ra={raise=50,out=-20,twist=40,elbow=96},lf={x=-.3,z=-.4},rf={x=.4,z=.8}})),
	K(1,n({root={y=-.62,z=-.3,yaw=0,pitch=8,roll=-6},torso={yaw=-30,pitch=4},head={yaw=-6},la=PALM_L,ra={raise=40,out=-20,twist=40,elbow=100},lf={x=.2,z=-1.0},rf={x=.6,z=.6}}),"out"),
	K(2,n({root={y=-.62,z=-.32,yaw=-4,pitch=8,roll=-6},torso={yaw=-32,pitch=4},la=PALM_L,ra={raise=40,out=-20,twist=40,elbow=100},lf={x=.2,z=-1.0},rf={x=.6,z=.6}})),
	K(3,N),
}
-- Air routes: drive (push kick / side kick / twin palm), spike (axe kick /
-- hammer drop / descending palm) and switch (vault into a spinning strike).
CLIPS.Flashstep.AirDrive={
	K(0,merge(AIR_M,{root={pitch=-6},torso={pitch=-8},rl={lift=104,knee=124,ankle=-10},ll={lift=30,knee=60},ra={raise=40,out=40,elbow=60},la={raise=60,out=10,elbow=90}})),
	K(1,merge(AIR_M,{root={pitch=-22},torso={pitch=-10,yaw=-10},head={pitch=12},rl={lift=96,out=0,knee=2,ankle=-30},ll={lift=-10,knee=70},ra={raise=-20,out=50,elbow=30},la={raise=70,out=-10,elbow=100}}),"out"),
	K(2,merge(AIR_M,{root={pitch=-20},torso={pitch=-10,yaw=-12},rl={lift=92,knee=6,ankle=-28},ll={lift=-10,knee=70},ra={raise=-20,out=50,elbow=30},la={raise=70,out=-10,elbow=100}})),
	K(3,AIR_M),
}
CLIPS.Flashstep.AirSpike={
	K(0,merge(AIR_M,{root={pitch=-18},torso={pitch=-10},rl={lift=165,out=4,knee=4,ankle=-30},ll={lift=10,knee=40},ra={raise=40,out=50,elbow=40},la={raise=40,out=50,elbow=40}})),
	K(1,merge(AIR_M,{root={pitch=24},torso={pitch=24},head={pitch=-10},rl={lift=20,out=4,knee=6,ankle=-10},ll={lift=-10,knee=60},ra={raise=20,out=50,elbow=30},la={raise=20,out=50,elbow=30}}),"out"),
	K(2,merge(AIR_M,{root={pitch=26},torso={pitch=26},rl={lift=14,out=4,knee=8},ll={lift=-10,knee=60},ra={raise=20,out=50,elbow=30},la={raise=20,out=50,elbow=30}})),
	K(3,AIR_M),
}
CLIPS.Flashstep.AirSwitch={
	K(0,merge(AIR_M,{root={yaw=-60,roll=10},torso={yaw=-20},rl={lift=90,knee=130},ll={lift=80,knee=120},ra={raise=60,out=20,elbow=110},la={raise=60,out=20,elbow=110}})),
	K(1,merge(AIR_M,{root={yaw=70,roll=-16,pitch=8},torso={yaw=20},head={yaw=-40},rl={lift=80,out=70,twist=-30,knee=6,ankle=-20},ll={lift=30,knee=80},ra={raise=20,out=80,elbow=20},la={raise=30,out=70,elbow=30}}),"out"),
	K(2,merge(AIR_M,{root={yaw=84,roll=-14,pitch=8},torso={yaw=22},rl={lift=76,out=70,twist=-30,knee=10,ankle=-20},ll={lift=30,knee=80},ra={raise=20,out=80,elbow=20},la={raise=30,out=70,elbow=30}})),
	K(3,AIR_M),
}
CLIPS.Mirage.AirDrive={
	K(0,merge(AIR_I,{root={yaw=-70},torso={yaw=-10},rl={lift=80,out=10,twist=-20,knee=120},ra={raise=50,out=-6,elbow=118},la={raise=54,out=-6,elbow=120}})),
	K(1,merge(AIR_I,{root={yaw=-84,roll=26},torso={roll=-16},head={yaw=60,roll=-18},rl={lift=86,out=72,knee=0,ankle=12},ll={lift=20,knee=70},ra={raise=50,out=-6,elbow=120},la={raise=30,out=30,elbow=80}}),"out"),
	K(2,merge(AIR_I,{root={yaw=-84,roll=24},torso={roll=-14},head={yaw=60,roll=-16},rl={lift=82,out=70,knee=6,ankle=10},ll={lift=20,knee=70},ra={raise=50,out=-6,elbow=120},la={raise=30,out=30,elbow=80}})),
	K(3,AIR_I),
}
CLIPS.Mirage.AirSpike={
	K(0,merge(AIR_I,{root={pitch=-10},torso={pitch=-16,yaw=-10},ra={raise=170,out=10,elbow=60},la={raise=140,out=-10,elbow=90},rl={lift=60,knee=110},ll={lift=40,knee=90}})),
	K(1,merge(AIR_I,{root={pitch=24},torso={pitch=36,yaw=6},head={pitch=10},ra={raise=50,out=-14,elbow=10,wrist=-20},la={raise=30,out=30,elbow=60},rl={lift=40,knee=70},ll={lift=20,knee=50}}),"out"),
	K(2,merge(AIR_I,{root={pitch=26},torso={pitch=38,yaw=6},ra={raise=44,out=-14,elbow=12},la={raise=30,out=30,elbow=60},rl={lift=40,knee=70},ll={lift=20,knee=50}})),
	K(3,AIR_I),
}
CLIPS.Mirage.AirSwitch={
	K(0,merge(AIR_I,{root={yaw=50,roll=-10},torso={yaw=16},ll={lift=90,knee=130},rl={lift=70,knee=110},ra={raise=50,out=20,elbow=110},la={raise=50,out=20,elbow=110}})),
	K(1,merge(AIR_I,{root={yaw=-60,roll=14},torso={yaw=-16},head={yaw=40},ll={lift=86,out=64,twist=-24,knee=10,ankle=-20},rl={lift=24,knee=70},ra={raise=30,out=70,elbow=24},la={raise=24,out=60,elbow=30}}),"out"),
	K(2,merge(AIR_I,{root={yaw=-70,roll=12},torso={yaw=-18},ll={lift=82,out=64,twist=-24,knee=14,ankle=-20},rl={lift=24,knee=70},ra={raise=30,out=70,elbow=24},la={raise=24,out=60,elbow=30}})),
	K(3,AIR_I),
}
CLIPS.GentleFist.AirDrive={
	K(0,merge(AIR_I,{root={pitch=-6},torso={pitch=-4},ra={raise=20,out=6,twist=50,elbow=120,wrist=-20},la={raise=20,out=6,twist=-50,elbow=120,wrist=-20},rl={lift=60,knee=100},ll={lift=40,knee=80}})),
	K(1,merge(AIR_I,{root={pitch=10},torso={pitch=10},ra={raise=92,out=-8,twist=72,elbow=2,wrist=-64},la={raise=92,out=-8,twist=-72,elbow=2,wrist=-64},rl={lift=20,knee=60},ll={lift=50,knee=90}}),"out"),
	K(2,merge(AIR_I,{root={pitch=10},torso={pitch=10},ra={raise=90,out=-8,twist=72,elbow=6,wrist=-62},la={raise=90,out=-8,twist=-72,elbow=6,wrist=-62},rl={lift=20,knee=60},ll={lift=50,knee=90}})),
	K(3,AIR_I),
}
CLIPS.GentleFist.AirSpike={
	K(0,merge(AIR_I,{root={pitch=-12},torso={pitch=-14},la={raise=170,out=6,twist=-60,elbow=20,wrist=-40},ra={raise=60,out=-20,elbow=96},rl={lift=70,knee=110},ll={lift=50,knee=100}})),
	K(1,merge(AIR_I,{root={pitch=30},torso={pitch=34},head={pitch=6},la={raise=40,out=-4,twist=-72,elbow=2,wrist=-64},ra={raise=30,out=30,elbow=60},rl={lift=30,knee=70},ll={lift=10,knee=50}}),"out"),
	K(2,merge(AIR_I,{root={pitch=32},torso={pitch=36},la={raise=36,out=-4,twist=-72,elbow=6,wrist=-62},ra={raise=30,out=30,elbow=60},rl={lift=30,knee=70},ll={lift=10,knee=50}})),
	K(3,AIR_I),
}
CLIPS.GentleFist.AirSwitch={
	K(0,merge(AIR_I,{root={yaw=-60},torso={yaw=-20},la={raise=60,out=30,twist=-60,elbow=90},ra={raise=60,out=30,twist=60,elbow=90},rl={lift=70,knee=110},ll={lift=60,knee=100}})),
	K(1,merge(AIR_I,{root={yaw=60,roll=-10},torso={yaw=10},la={raise=90,out=60,twist=-72,elbow=4,wrist=-60},ra={raise=90,out=50,twist=72,elbow=4,wrist=-60},rl={lift=50,knee=90},ll={lift=40,knee=70}}),"out"),
	K(2,merge(AIR_I,{root={yaw=70,roll=-10},torso={yaw=12},la={raise=88,out=60,twist=-72,elbow=8},ra={raise=88,out=50,twist=72,elbow=8},rl={lift=50,knee=90},ll={lift=40,knee=70}})),
	K(3,AIR_I),
}
-- Sasuke ----------------------------------------------------------------
-- Aggressive Uchiha taijutsu: a jab, a roundhouse to the body, a spinning
-- heel kick; an acrobatic rising kick he follows into the air; a vault over
-- the opponent into a back kick; the Lion Combo heel drop; the Chidori thrust.
local S=STANCE.Lion
local function sk(over) return merge(S,over) end
local AIR_S={root={pitch=8},torso={pitch=6},head={pitch=-6},ra={raise=50,out=24,elbow=96},la={raise=56,out=16,elbow=86},rl={lift=62,knee=100,ankle=-10},ll={lift=36,knee=76,ankle=-10}}
CLIPS.Lion.Light1={ -- lead-hand jab
	K(0,sk({torso={yaw=12},la={raise=56,out=6,twist=20,elbow=112}})),
	K(1,sk({root={z=-.32,yaw=-6,pitch=8},torso={yaw=-18},la={raise=92,out=-4,twist=-14,elbow=4,wrist=0},ra={raise=50,out=-16,elbow=118}}),"out"),
	K(2,sk({root={z=-.32,yaw=-6,pitch=8},torso={yaw=-20},la={raise=90,out=-4,twist=-14,elbow=8},ra={raise=50,out=-16,elbow=118}})),
	K(3,S),
}
CLIPS.Lion.Light2={ -- rear-leg roundhouse to the ribs
	K(0,sk({root={y=-.55,yaw=-24,pitch=6},torso={yaw=-16},ra={raise=50,out=-10,elbow=110},la={raise=60,out=10,elbow=90},rl={lift=62,out=22,knee=112,ankle=-10},lf={yaw=-24}})),
	K(1,sk({root={y=-.4,yaw=70,pitch=-4,roll=-18},torso={yaw=10,roll=-18},head={yaw=-40,roll=12},ra={raise=-10,out=34,elbow=40},la={raise=64,out=-8,twist=20,elbow=112},rl={lift=76,out=62,twist=-26,knee=8,ankle=-20},lf={yaw=50}}),"out"),
	K(2,sk({root={y=-.42,yaw=80,pitch=-4,roll=-16},torso={yaw=12,roll=-16},ra={raise=-8,out=34,elbow=44},la={raise=64,out=-8,twist=20,elbow=112},rl={lift=72,out=64,twist=-26,knee=12,ankle=-20},lf={yaw=60}})),
	K(2.6,sk({root={y=-.5,yaw=50},rl={lift=40,out=20,knee=70},lf={yaw=30}})),
	K(3,S),
}
CLIPS.Lion.Light3={ -- spinning heel kick: the turning strike that sends the body away
	K(0,sk({root={y=-.62,yaw=-20,pitch=6},torso={yaw=-20},ra={raise=40,out=30,elbow=90},la={raise=40,out=30,elbow=90}})),
	K(.5,sk({root={y=-.45,yaw=90,pitch=0,roll=8},torso={yaw=-10},head={yaw=-60},ra={raise=40,out=24,elbow=100},la={raise=40,out=24,elbow=100},rl={lift=40,out=30,knee=90},lf={yaw=90,x=.4,z=0}})),
	K(1,sk({root={y=-.25,yaw=196,pitch=-8,roll=16},torso={yaw=16,roll=12},head={yaw=50},ra={raise=24,out=46,elbow=50},la={raise=34,out=40,elbow=60},rl={lift=94,out=52,twist=20,knee=6,ankle=-20},lf={yaw=196,x=.4,z=0}}),"out"),
	K(2,sk({root={y=-.28,yaw=214,pitch=-6,roll=14},torso={yaw=18,roll=10},ra={raise=24,out=48,elbow=52},la={raise=34,out=42,elbow=60},rl={lift=88,out=54,twist=20,knee=10,ankle=-20},lf={yaw=214,x=.4,z=0}})),
	K(2.5,sk({root={y=-.45,yaw=290},rl={lift=40,out=20,knee=70},lf={yaw=290,x=.3,z=0}})),
	K(3,merge(S,{root={yaw=S.root.yaw+360}})),
}
CLIPS.Lion.Heavy={ -- driving front kick off the rear leg
	K(0,sk({root={y=-.75,z=.25,pitch=12},torso={pitch=8},ra={raise=40,out=20,elbow=100},la={raise=60,out=10,elbow=90},lf={z=-1.0}})),
	K(1,sk({root={y=-.3,z=-.6,pitch=-14},torso={pitch=-6,yaw=-8},head={pitch=10},ra={raise=-20,out=40,elbow=40},la={raise=70,out=-10,elbow=100},rl={lift=96,out=4,knee=4,ankle=-30},lf={z=-1.2,toe=-10}}),"out"),
	K(2,sk({root={y=-.32,z=-.62,pitch=-12},torso={pitch=-6,yaw=-8},ra={raise=-20,out=40,elbow=40},la={raise=70,out=-10,elbow=100},rl={lift=92,knee=8,ankle=-28},lf={z=-1.2}})),
	K(3,S),
}
CLIPS.Lion.LionKick={ -- deep crouch, then a rising flip kick straight up under the chin
	K(0,sk({root={y=-1.05,pitch=22},torso={pitch=14},ra={raise=30,out=40,elbow=80},la={raise=30,out=40,elbow=80},lf={z=-.4},rf={z=.5}})),
	K(1,sk({root={y=.45,pitch=-46},torso={pitch=-14},head={pitch=-20},ra={raise=-40,out=44,elbow=20},la={raise=-36,out=44,elbow=20},rl={lift=168,out=4,knee=2,ankle=-30},ll={lift=24,knee=70}}),"out"),
	K(2,sk({root={y=.5,pitch=-56},torso={pitch=-16},head={pitch=-20},ra={raise=-44,out=44,elbow=20},la={raise=-40,out=44,elbow=20},rl={lift=160,out=4,knee=8,ankle=-28},ll={lift=30,knee=80}})),
	K(3,S),
}
CLIPS.Lion.DashAttack={ -- flying knee, hands pulling the head down onto it
	K(0,sk({root={y=-.6,pitch=20},ra={raise=30,out=30,elbow=90},la={raise=30,out=30,elbow=90},lf={z=-1.0},rf={z=1.1}})),
	K(1,sk({root={y=-.1,z=-.8,pitch=6},torso={pitch=10},rl={lift=112,knee=142,ankle=-20},ra={raise=84,out=-10,elbow=60},la={raise=84,out=-10,elbow=60},lf={z=-1.3,toe=-30}}),"out"),
	K(2,sk({root={y=-.12,z=-.82,pitch=6},torso={pitch=10},rl={lift=108,knee=140},ra={raise=80,out=-10,elbow=64},la={raise=80,out=-10,elbow=64},lf={z=-1.3,toe=-24}})),
	K(3,S),
}
CLIPS.Lion.Sweep={ -- both hands on the floor, a full low spin that reaps the legs
	K(0,sk({root={y=-1.15,pitch=30,yaw=0},torso={pitch=16,yaw=-10},ra={raise=20,out=20,elbow=20,wrist=-40},la={raise=24,out=16,elbow=20,wrist=-40},lf={x=.5,z=-.2},rf={z=.8}})),
	K(1,sk({root={y=-1.55,pitch=34,yaw=96},torso={pitch=18,yaw=10},head={yaw=-70},ra={raise=16,out=40,elbow=8,wrist=-50},la={raise=20,out=30,elbow=8,wrist=-50},rl={lift=12,out=82,twist=-40,knee=4,ankle=-12},lf={x=.5,z=-.1,yaw=96}}),"out"),
	K(2,sk({root={y=-1.5,pitch=32,yaw=186},torso={pitch=16,yaw=12},head={yaw=-70},ra={raise=16,out=40,elbow=8},la={raise=20,out=30,elbow=8},rl={lift=12,out=82,twist=-40,knee=6,ankle=-12},lf={x=.5,z=-.1,yaw=186}})),
	K(2.5,sk({root={y=-1.15,pitch=24,yaw=276},torso={pitch=10},rl={lift=34,out=48,knee=40},lf={x=.5,z=0,yaw=276}})),
	K(3,merge(S,{root={yaw=S.root.yaw+360}})),
}
CLIPS.Lion.VaultKick={ -- over the opponent's shoulder, a back kick from the other side
	K(0,sk({root={y=-.8,pitch=16},torso={pitch=10},ra={raise=80,out=10,elbow=40},la={raise=80,out=10,elbow=40},lf={z=-.6},rf={z=.6}})),
	K(1,sk({root={y=.55,pitch=36,yaw=-20},torso={pitch=20},head={pitch=-30,yaw=30},ra={raise=60,out=30,elbow=30},la={raise=50,out=40,elbow=40},rl={lift=-62,out=6,knee=4,ankle=20},ll={lift=60,knee=110}}),"out"),
	K(2,sk({root={y=.45,pitch=34,yaw=-22},torso={pitch=18},head={pitch=-28,yaw=30},ra={raise=60,out=30,elbow=30},la={raise=50,out=40,elbow=40},rl={lift=-58,out=6,knee=8,ankle=20},ll={lift=56,knee=106}})),
	K(3,S),
}
CLIPS.Lion.LionBarrage={ -- Lion Combo: the heel raised overhead, then driven through the body to the floor
	K(0,merge(AIR_S,{root={pitch=-22,yaw=30},torso={pitch=-14,yaw=10},rl={lift=172,out=6,knee=2,ankle=-30},ll={lift=10,knee=50},ra={raise=30,out=60,elbow=30},la={raise=30,out=60,elbow=30}})),
	K(1,merge(AIR_S,{root={pitch=30,yaw=0},torso={pitch=30},head={pitch=-12},rl={lift=12,out=6,knee=6,ankle=-10},ll={lift=-14,knee=60},ra={raise=10,out=60,elbow=20},la={raise=10,out=60,elbow=20}}),"out"),
	K(2,merge(AIR_S,{root={pitch=32},torso={pitch=32},rl={lift=8,knee=8},ll={lift=-14,knee=60},ra={raise=10,out=60,elbow=20},la={raise=10,out=60,elbow=20}})),
	K(3,sk({root={y=-1.0,pitch=26},torso={pitch=22},lf={z=-.9},rf={z=.9}})),
}
CLIPS.Lion.ChidoriThrust={ -- the lightning hand driven straight through, the whole body behind it
	K(0,sk({root={y=-.95,z=.25,pitch=24,yaw=20},torso={pitch=14,yaw=10},head={pitch=-14},ra={raise=-20,out=20,twist=40,elbow=30,wrist=-30},la={raise=20,out=-30,twist=40,elbow=90},lf={z=-1.2},rf={z=1.1,yaw=40}})),
	K(1,sk({root={y=-.7,z=-1.25,pitch=28,yaw=-12},torso={pitch=12,yaw=-14},head={pitch=-16},ra={raise=94,out=-4,twist=-20,elbow=2,wrist=-10},la={raise=40,out=-20,twist=30,elbow=100},lf={z=-1.85},rf={z=1.55,y=.2,toe=-24}}),"out"),
	K(2,sk({root={y=-.7,z=-1.28,pitch=28,yaw=-14},torso={pitch=12,yaw=-16},ra={raise=92,out=-4,twist=-20,elbow=4},la={raise=40,out=-20,twist=30,elbow=100},lf={z=-1.85},rf={z=1.55,y=.2,toe=-24}})),
	K(3,S),
}
CLIPS.Lion.Riposte=CLIPS.Lion.Light1
-- Spins are authored with their exact angles (no exaggeration), each key
-- under half a turn from the next so the body turns the right way round.
for _,clip in {CLIPS.Flashstep.Sweep,CLIPS.GentleFist.Sweep,CLIPS.Lion.Sweep,CLIPS.Lion.Light3} do
	for _,key in clip do
		if key.pose~=M and key.pose~=I and key.pose~=N and key.pose~=S then key.pose.keep=true end
	end
end
-- Anything Sasuke does not author (air strings, throws, knee) borrows Minato's
-- springier clips.
setmetatable(CLIPS.Lion,{__index=CLIPS.Flashstep})
-- Riposte: each fighter's shortest strike, thrown straight out of the guard.
CLIPS.Flashstep.Riposte=CLIPS.Flashstep.Light2
CLIPS.Mirage.Riposte=CLIPS.Mirage.CounterPalm
CLIPS.GentleFist.Riposte=CLIPS.GentleFist.Light1
-- Rock Lee (stress-test wave, DEC-015) -------------------------------------
-- Built from Sasuke's kicking family (the string, the knee, the air string and
-- routes, throws: CLIPS.Lion and through it Minato's), with his own clips only
-- where his identity needs them: the rising kick out of a crouch, the low spin
-- on one hand, the crescent kick that clears blades and the lotuses. The rear
-- hand stays behind his back in all of them. Authored at their final size: the
-- CORE4 readability and kinetic-chain passes below do not touch them.
local LE=STANCE.Leaf
local function le(over) return merge(LE,over) end
local AIR_LE={root={pitch=8},torso={pitch=6},head={pitch=-6},ra=LE.ra,la={raise=60,out=20,elbow=70},rl={lift=62,knee=100,ankle=-10},ll={lift=36,knee=76,ankle=-10}}
-- Both arms wrapped round a body (the lotus holds its opponent).
local HUG={raise=96,out=-36,twist=30,elbow=96,wrist=0}
CLIPS.Leaf={}
CLIPS.Leaf.LeafRising={ -- Konoha Shōfū: a deep crouch, then one leg straight up under the chin
	K(0,le({root={y=-1.12,pitch=20},torso={pitch=12},la={raise=40,out=20,elbow=60},lf={z=-.5},rf={z=.55}})),
	K(.55,le({root={y=-.9,pitch=10},torso={pitch=6},la={raise=30,out=30,elbow=40},rl={lift=84,knee=112,ankle=-10},lf={z=-.3,toe=-10}})),
	K(1,le({root={y=-.04,pitch=-16,yaw=4},torso={pitch=-10,yaw=-6},head={pitch=-14,yaw=-6},la={raise=-30,out=40,elbow=20},rl={lift=142,out=2,knee=4,ankle=-30},lf={z=0,toe=-26}}),"out"),
	K(2,le({root={y=-.02,pitch=-20,yaw=4},torso={pitch=-12,yaw=-6},head={pitch=-16,yaw=-6},la={raise=-34,out=40,elbow=20},rl={lift=152,out=2,knee=6,ankle=-28},lf={z=0,toe=-24}})),
	K(2.5,le({root={y=-.4,pitch=-4},rl={lift=60,knee=90}})),
	K(3,LE),
}
CLIPS.Leaf.LeafHurricane={ -- Konoha Senpū, low: dropped onto the lead hand, a full spin that reaps the legs
	K(0,le({root={y=-1.2,pitch=26,yaw=10},torso={pitch=14,yaw=-8},la={raise=24,out=24,elbow=20,wrist=-40},lf={x=.45,z=-.2},rf={z=.8}})),
	K(1,le({root={y=-1.55,pitch=24,yaw=100},torso={pitch=16,yaw=8},head={yaw=-60},la={raise=14,out=40,elbow=8,wrist=-50},rl={lift=14,out=84,twist=-40,knee=4,ankle=-12},lf={x=.5,z=-.1,yaw=100}}),"out"),
	K(2,le({root={y=-1.5,pitch=22,yaw=190},torso={pitch=14,yaw=10},head={yaw=-60},la={raise=14,out=42,elbow=8},rl={lift=14,out=84,twist=-40,knee=6,ankle=-12},lf={x=.5,z=-.1,yaw=190}})),
	K(2.5,le({root={y=-1.15,pitch=22,yaw=280},torso={pitch=10},rl={lift=34,out=46,knee=40},lf={x=.5,z=0,yaw=280}})),
	K(3,merge(LE,{root={yaw=LE.root.yaw+360}})),
}
CLIPS.Leaf.DeflectKick={ -- the crescent kick that clears blades: the lead leg sweeps across his front
	K(0,le({root={y=-.5,yaw=20},torso={yaw=-6},la={raise=60,out=30,elbow=50},ll={lift=60,out=30,twist=20,knee=90,ankle=-10}})),
	K(1,le({root={y=-.3,yaw=-30,pitch=-6},torso={yaw=-20},head={yaw=10},la={raise=40,out=60,elbow=30},ll={lift=100,out=-10,twist=-30,knee=10,ankle=-20}}),"out"),
	K(2,le({root={y=-.3,yaw=-44,pitch=-6},torso={yaw=-24},la={raise=40,out=60,elbow=30},ll={lift=92,out=-24,twist=-30,knee=14,ankle=-20}})),
	K(2.5,le({root={y=-.45,yaw=0},ll={lift=40,knee=70}})),
	K(3,LE),
}
CLIPS.Leaf.PrimaryLotus={ -- Omote Renge: the arms wrap the body, the spin turns head first, the drive into the floor
	K(0,merge(AIR_LE,{root={pitch=-14},torso={pitch=-10},head={pitch=-10},ra=HUG,la=HUG,rl={lift=96,knee=120,ankle=-20},ll={lift=90,knee=116,ankle=-20}})),
	K(.6,merge(AIR_LE,{root={pitch=64},torso={pitch=18},head={pitch=18},ra=HUG,la=HUG,rl={lift=70,knee=100},ll={lift=64,knee=96}})),
	K(1,merge(AIR_LE,{root={pitch=120},torso={pitch=22},head={pitch=22},ra=HUG,la=HUG,rl={lift=20,knee=30,ankle=-30},ll={lift=14,knee=26,ankle=-30}}),"out"),
	K(2,merge(AIR_LE,{root={pitch=128},torso={pitch=24},head={pitch=24},ra=HUG,la=HUG,rl={lift=16,knee=26},ll={lift=12,knee=22}})),
	K(3,le({root={y=-1.05,pitch=24},torso={pitch=18},la={raise=40,out=30,elbow=40},lf={z=-.9},rf={z=.9}})),
}
CLIPS.Leaf.HiddenLotus={ -- Ura Renge (Fifth Gate): blows from above, then both fists driven down through the body
	K(0,merge(AIR_LE,{root={pitch=-8},torso={pitch=-16,yaw=-20},ra={raise=150,out=20,elbow=90},la={raise=150,out=20,elbow=90},rl={lift=70,knee=110},ll={lift=60,knee=100}})),
	K(.5,merge(AIR_LE,{root={pitch=10},torso={pitch=10,yaw=20},ra={raise=60,out=-10,elbow=20},la={raise=140,out=20,elbow=80},rl={lift=50,knee=90},ll={lift=70,knee=110}})),
	K(1,merge(AIR_LE,{root={pitch=40},torso={pitch=40},head={pitch=10},ra={raise=40,out=-14,elbow=4,wrist=-10},la={raise=40,out=-14,elbow=4,wrist=-10},rl={lift=-10,knee=40},ll={lift=10,knee=60}}),"out"),
	K(2,merge(AIR_LE,{root={pitch=44},torso={pitch=42},ra={raise=34,out=-14,elbow=6},la={raise=34,out=-14,elbow=6},rl={lift=-10,knee=40},ll={lift=10,knee=60}})),
	K(3,le({root={y=-1.1,pitch=26},torso={pitch=20},la={raise=50,out=24,elbow=40},lf={z=-.95},rf={z=.95}})),
}
-- Reused where the family already has the move (the stress test counts them):
-- the heel drop for his plain air heavy and the Leaf Heel, Sasuke's spinning
-- heel kick for the Leaf Whirlwind, Minato's spinning roundhouse for the Leaf
-- Great Whirlwind.
CLIPS.Leaf.Slam=CLIPS.Lion.LionBarrage
CLIPS.Leaf.LeafHeel=CLIPS.Lion.LionBarrage
CLIPS.Leaf.LeafWhirlwind=CLIPS.Lion.Light3
CLIPS.Leaf.GreatWhirlwind=CLIPS.Flashstep.Light3
setmetatable(CLIPS.Leaf,{__index=CLIPS.Lion})
-- Naruto (roster wave, several bodies) ---------------------------------------
-- A brawler, not a prodigy of form: a low, square, loose guard with both fists
-- up and the elbows out, a hook / straight / push kick string, the headbutt and
-- the tackle. His clones are his own body (Client/BodyViews draws a copy of
-- him), so the clips they play live here too: the kick from behind, the kick
-- up under the body, the flank hook, their jab and the barrage kick. While a
-- clone carries his route he plays his side of it (bracing, crouching to
-- spring). Air strings and throws come from the shared families. Authored at
-- their final size (the CORE4 passes below do not touch them).
STANCE.Legion={root={y=-.46,pitch=12,yaw=20},torso={pitch=8,yaw=-10},head={pitch=-8,yaw=-10},
	ra={raise=60,out=18,twist=14,elbow=108,wrist=0},la={raise=66,out=12,twist=10,elbow=98,wrist=0},
	rf={x=.36,z=.66,yaw=30},lf={x=-.24,z=-.62,yaw=-12},breath=1.5,tempo=8}
local NR=STANCE.Legion
local function nr(over) return merge(NR,over) end
local AIR_NR={root={pitch=6},torso={pitch=6},head={pitch=-8},ra={raise=50,out=30,elbow=96},la={raise=54,out=26,elbow=90},rl={lift=60,knee=100,ankle=-10},ll={lift=38,knee=80,ankle=-10}}
CLIPS.Legion={}
CLIPS.Legion.Light1={ -- a wide looping right hook, thrown with the shoulders
	K(0,nr({root={yaw=34},torso={yaw=24},ra={raise=70,out=62,twist=-10,elbow=96},la={raise=60,out=10,elbow=100}})),
	K(1,nr({root={z=-.35,yaw=-10,pitch=14},torso={yaw=-30,pitch=8},head={yaw=8},ra={raise=88,out=-6,twist=40,elbow=76,wrist=0},la={raise=52,out=14,elbow=110},rf={z=.8},lf={z=-.9}}),"out"),
	K(2,nr({root={z=-.38,yaw=-16,pitch=14},torso={yaw=-38,pitch=8},ra={raise=84,out=-24,twist=44,elbow=80},la={raise=50,out=14,elbow=110},rf={z=.8},lf={z=-.9}})),
	K(3,NR),
}
CLIPS.Legion.Light2={ -- the straight: the left fist driven out, the body behind it
	K(0,nr({torso={yaw=16},la={raise=62,out=8,twist=10,elbow=118}})),
	K(1,nr({root={z=-.4,yaw=-8,pitch=12},torso={yaw=-22,pitch=6},la={raise=92,out=-6,twist=-10,elbow=4,wrist=0},ra={raise=58,out=20,elbow=112}}),"out"),
	K(2,nr({root={z=-.42,yaw=-10,pitch=12},torso={yaw=-24},la={raise=90,out=-6,twist=-10,elbow=8},ra={raise=58,out=20,elbow=112}})),
	K(3,NR),
}
CLIPS.Legion.Light3={ -- a big push kick off the back leg
	K(0,nr({root={y=-.6,z=.2,pitch=6},torso={pitch=2},ra={raise=50,out=30,elbow=90},la={raise=56,out=24,elbow=96},rl={lift=70,knee=118,ankle=-10}})),
	K(1,nr({root={y=-.3,z=-.5,pitch=-16},torso={pitch=-8,yaw=-6},head={pitch=12},ra={raise=20,out=46,elbow=50},la={raise=70,out=20,elbow=90},rl={lift=94,out=4,knee=4,ankle=-30},lf={z=-1.0,toe=-10}}),"out"),
	K(2,nr({root={y=-.32,z=-.52,pitch=-14},torso={pitch=-8},ra={raise=20,out=46,elbow=50},la={raise=70,out=20,elbow=90},rl={lift=90,knee=8,ankle=-28},lf={z=-1.0}})),
	K(2.5,nr({root={y=-.5},rl={lift=40,knee=70}})),
	K(3,NR),
}
CLIPS.Legion.Heavy={ -- a wound-up haymaker: everything he has in one right hand
	K(0,nr({root={y=-.66,z=.3,yaw=40,pitch=6},torso={yaw=34,pitch=-4},ra={raise=120,out=40,twist=-20,elbow=120},la={raise=70,out=-6,elbow=70},rf={z=1.0}})),
	K(1,nr({root={y=-.5,z=-.8,yaw=-24,pitch=24},torso={yaw=-30,pitch=14},head={yaw=12,pitch=4},ra={raise=80,out=-10,twist=30,elbow=20},la={raise=-10,out=20,elbow=90},lf={z=-1.4},rf={z=1.2}}),"out"),
	K(2,nr({root={y=-.52,z=-.84,yaw=-28,pitch=24},torso={yaw=-34,pitch=14},ra={raise=76,out=-14,twist=30,elbow=24},la={raise=-10,out=20,elbow=90},lf={z=-1.4},rf={z=1.2}})),
	K(3,NR),
}
CLIPS.Legion.Headbutt={ -- both hands on the collar, the forehead driven in
	K(0,nr({root={y=-.4,pitch=-10,z=.2},torso={pitch=-14},head={pitch=-22},ra={raise=88,out=-10,elbow=60},la={raise=88,out=-10,elbow=60}})),
	K(1,nr({root={y=-.5,z=-.6,pitch=26},torso={pitch=22},head={pitch=24},ra={raise=80,out=-20,elbow=70},la={raise=80,out=-20,elbow=70},lf={z=-1.1},rf={z=.9}}),"out"),
	K(2,nr({root={y=-.5,z=-.62,pitch=24},torso={pitch=20},head={pitch=20},ra={raise=78,out=-20,elbow=72},la={raise=78,out=-20,elbow=72},lf={z=-1.1},rf={z=.9}})),
	K(3,NR),
}
CLIPS.Legion.Tackle={ -- a low dive into the legs, the arms wide to wrap them
	K(0,nr({root={y=-.9,pitch=30},torso={pitch=16},head={pitch=-20},ra={raise=40,out=40,elbow=60},la={raise=40,out=40,elbow=60},lf={z=-1.0},rf={z=1.0}})),
	K(1,nr({root={y=-1.3,z=-1.0,pitch=58},torso={pitch=22},head={pitch=-34},ra={raise=110,out=30,elbow=30},la={raise=110,out=30,elbow=30},rl={lift=-20,knee=40,ankle=20},lf={z=-1.4}}),"out"),
	K(2,nr({root={y=-1.35,z=-1.05,pitch=60},torso={pitch=22},head={pitch=-34},ra={raise=104,out=-10,elbow=60},la={raise=104,out=-10,elbow=60},rl={lift=-20,knee=40,ankle=20},lf={z=-1.4}})),
	K(2.6,nr({root={y=-1.0,pitch=30},torso={pitch=12}})),
	K(3,NR),
}
CLIPS.Legion.DashAttack={ -- out of the dash: a flying right fist, the whole body behind it
	K(0,nr({root={y=-.6,pitch=22},ra={raise=40,out=30,elbow=110},la={raise=60,out=20,elbow=90},lf={z=-1.0},rf={z=1.0}})),
	K(1,nr({root={y=-.4,z=-.9,pitch=20,yaw=-10},torso={yaw=-18,pitch=8},head={pitch=-10},ra={raise=92,out=-6,twist=10,elbow=4},la={raise=-10,out=30,elbow=60},lf={z=-1.5},rf={z=1.4,y=.2,toe=-20}}),"out"),
	K(2,nr({root={y=-.42,z=-.92,pitch=20,yaw=-10},torso={yaw=-20,pitch=8},ra={raise=90,out=-6,twist=10,elbow=8},la={raise=-10,out=30,elbow=60},lf={z=-1.5},rf={z=1.4,y=.2,toe=-20}})),
	K(3,NR),
}
CLIPS.Legion.Rasengan={ -- the sphere in the right palm, the whole body lunging behind it
	K(0,nr({root={y=-.8,z=.2,pitch=18},torso={pitch=10,yaw=16},ra={raise=60,out=20,twist=-60,elbow=90,wrist=10},la={raise=40,out=30,elbow=60}})),
	K(1,nr({root={y=-.7,z=-1.1,pitch=26,yaw=-10},torso={pitch=12,yaw=-14},head={pitch=-14},ra={raise=94,out=-4,twist=-70,elbow=6,wrist=-10},la={raise=-20,out=30,elbow=40},lf={z=-1.6},rf={z=1.3,toe=-20}}),"out"),
	K(2,nr({root={y=-.7,z=-1.15,pitch=26,yaw=-12},torso={pitch=12,yaw=-16},ra={raise=92,out=-4,twist=-70,elbow=8},la={raise=-20,out=30,elbow=40},lf={z=-1.6},rf={z=1.3,toe=-20}})),
	K(3,NR),
}
-- His side of the clone routes.
CLIPS.Legion.CloneKick={ -- (his clone kicks from behind) he braces to meet the body coming at him
	K(0,nr({root={y=-.5,z=.25},torso={pitch=4},ra={raise=74,out=6,elbow=100},la={raise=78,out=2,elbow=92}})),
	K(1,nr({root={y=-.62,z=.3,pitch=14},torso={pitch=10},head={pitch=-6},ra={raise=84,out=-10,twist=20,elbow=70},la={raise=86,out=-12,twist=20,elbow=66},lf={z=-1.0},rf={z=.9}}),"out"),
	K(2,nr({root={y=-.62,z=.3,pitch=14},torso={pitch=10},ra={raise=84,out=-10,twist=20,elbow=70},la={raise=86,out=-12,twist=20,elbow=66},lf={z=-1.0},rf={z=.9}})),
	K(3,NR),
}
CLIPS.Legion.UzumakiKick={ -- (a clone kicks the body up) he drops low, ready to spring after it
	K(0,nr({root={y=-.7,pitch=14},torso={pitch=10},ra={raise=40,out=30,elbow=80},la={raise=40,out=30,elbow=80}})),
	K(1,nr({root={y=-1.0,pitch=20},torso={pitch=12},head={pitch=-24},ra={raise=-20,out=40,elbow=40},la={raise=-20,out=40,elbow=40},lf={z=-.6},rf={z=.6}}),"out"),
	K(2,nr({root={y=-1.0,pitch=18},torso={pitch=10},head={pitch=-30},ra={raise=-24,out=40,elbow=40},la={raise=-24,out=40,elbow=40},lf={z=-.6},rf={z=.6}})),
	K(3,NR),
}
CLIPS.Legion.MirrorClone={ -- (a clone hooks from the flank) he feints the same hook on his side
	K(0,nr({root={yaw=30,roll=6},torso={yaw=20},la={raise=70,out=50,elbow=96},ra={raise=60,out=14,elbow=104}})),
	K(1,nr({root={yaw=-6,pitch=12,roll=-6},torso={yaw=-20},la={raise=86,out=-4,twist=40,elbow=80},ra={raise=56,out=14,elbow=110}}),"out"),
	K(2,nr({root={yaw=-8,pitch=12},torso={yaw=-22},la={raise=84,out=-14,twist=40,elbow=82},ra={raise=56,out=14,elbow=110}})),
	K(3,NR),
}
-- The clones' side (BodyViews: attackVariant of the carried move).
CLIPS.Legion.CloneKickStrike={ -- a clone: a roundhouse into the opponent's back
	K(0,nr({root={y=-.62,yaw=-30,pitch=6},torso={yaw=-18},ra={raise=50,out=20,elbow=100},la={raise=56,out=20,elbow=100},rl={lift=60,out=20,knee=110,ankle=-10}})),
	K(1,nr({root={y=-.3,yaw=66,pitch=-4,roll=-18},torso={yaw=12,roll=-18},head={yaw=-36},ra={raise=-8,out=40,elbow=44},la={raise=60,out=-6,elbow=100},rl={lift=82,out=60,twist=-26,knee=8,ankle=-20},lf={yaw=50}}),"out"),
	K(2,nr({root={y=-.32,yaw=76,pitch=-4,roll=-16},torso={yaw=14,roll=-16},ra={raise=-6,out=40,elbow=46},la={raise=60,out=-6,elbow=100},rl={lift=78,out=62,twist=-26,knee=12,ankle=-20},lf={yaw=60}})),
	K(3,NR),
}
CLIPS.Legion.UzumakiRise={ -- a clone: down low under the body, one leg driven straight up
	K(0,nr({root={y=-1.2,pitch=24},torso={pitch=14},ra={raise=30,out=40,elbow=60},la={raise=30,out=40,elbow=60},lf={z=-.4},rf={z=.5}})),
	K(1,nr({root={y=-.1,pitch=-28},torso={pitch=-14},head={pitch=-22},ra={raise=-30,out=40,elbow=24},la={raise=-30,out=40,elbow=24},rl={lift=150,out=4,knee=4,ankle=-30},lf={z=0,toe=-24}}),"out"),
	K(2,nr({root={y=-.06,pitch=-30},torso={pitch=-16},head={pitch=-22},ra={raise=-32,out=40,elbow=24},la={raise=-32,out=40,elbow=24},rl={lift=156,out=4,knee=6,ankle=-28},lf={z=0,toe=-20}})),
	K(3,NR),
}
CLIPS.Legion.MirrorStrike=CLIPS.Legion.Light1 -- a clone hooks like him
CLIPS.Legion.CloneJab=CLIPS.Legion.Light2 -- and jabs like him
CLIPS.Legion.BarrageKick={ -- a clone in the air under the body: a rising kick ("U-ZU-MA")
	K(0,merge(AIR_NR,{root={pitch=-10},rl={lift=90,knee=130},ra={raise=30,out=50,elbow=40}})),
	K(1,merge(AIR_NR,{root={pitch=-30},torso={pitch=-12},head={pitch=-24},rl={lift=160,knee=6,ankle=-30},ll={lift=10,knee=40}}),"out"),
	K(2,merge(AIR_NR,{root={pitch=-32},torso={pitch=-12},rl={lift=156,knee=10,ankle=-28},ll={lift=10,knee=40}})),
	K(3,AIR_NR),
}
CLIPS.Legion.NarutoRendan={ -- the barrage's last word: his heel brought down from above the body
	K(0,merge(AIR_NR,{root={pitch=-26,yaw=10},torso={pitch=-16},head={pitch=-10},rl={lift=170,out=4,knee=4,ankle=-30},ll={lift=10,knee=46},ra={raise=40,out=60,elbow=30},la={raise=40,out=60,elbow=30}})),
	K(1,merge(AIR_NR,{root={pitch=34},torso={pitch=30},head={pitch=-14},rl={lift=10,out=4,knee=6,ankle=-10},ll={lift=-12,knee=60},ra={raise=10,out=60,elbow=20},la={raise=10,out=60,elbow=20}}),"out"),
	K(2,merge(AIR_NR,{root={pitch=36},torso={pitch=32},rl={lift=8,knee=8},ll={lift=-12,knee=60},ra={raise=10,out=60,elbow=20},la={raise=10,out=60,elbow=20}})),
	K(3,nr({root={y=-1.0,pitch=26},torso={pitch=22},lf={z=-.9},rf={z=.9}})),
}
-- The Nine-Tails cloak: no clones, a chakra claw instead.
CLIPS.Legion.ClawRise={ -- low on all fours, then a claw ripped upward
	K(0,nr({root={y=-1.2,pitch=34},torso={pitch=20},head={pitch=-30},ra={raise=20,out=30,elbow=40,wrist=-30},la={raise=40,out=20,elbow=40},lf={z=-.7},rf={z=.8}})),
	K(1,nr({root={y=-.3,pitch=-10,yaw=-14},torso={pitch=-16,yaw=-20},head={pitch=-20},ra={raise=172,out=20,twist=-20,elbow=20,wrist=-20},la={raise=10,out=40,elbow=40}}),"out"),
	K(2,nr({root={y=-.28,pitch=-12,yaw=-16},torso={pitch=-18,yaw=-22},ra={raise=168,out=24,elbow=24},la={raise=10,out=40,elbow=40}})),
	K(3,NR),
}
CLIPS.Legion.ClawSwipe={ -- a long sweep of the chakra claw across the body
	K(0,nr({root={y=-.8,yaw=50,pitch=16},torso={yaw=40,pitch=10},ra={raise=80,out=90,twist=-20,elbow=40,wrist=-30},la={raise=40,out=10,elbow=90}})),
	K(1,nr({root={y=-.75,yaw=-40,pitch=18},torso={yaw=-44,pitch=10},head={yaw=20},ra={raise=86,out=-40,twist=30,elbow=20,wrist=-30},la={raise=30,out=30,elbow=80},lf={z=-1.1},rf={z=.9}}),"out"),
	K(2,nr({root={y=-.75,yaw=-50,pitch=18},torso={yaw=-50,pitch=10},ra={raise=84,out=-50,twist=30,elbow=24},la={raise=30,out=30,elbow=80},lf={z=-1.1},rf={z=.9}})),
	K(3,NR),
}
CLIPS.Legion.Riposte=CLIPS.Legion.Light2
setmetatable(CLIPS.Legion,{__index=CLIPS.Lion})
-- Taijutsu readability: on ground strikes, push hips, shoulders and the step
-- further from the stance so the body mechanics read at fight distance.
local EXAGGERATE,STEP=1.3,1.15
local AIRBORNE={Air1=true,Air2=true,Slam=true,RasenganDrop=true,WallDive=true,FlyingKick=true,AirDrive=true,AirSpike=true,AirSwitch=true,LionBarrage=true}
local done={}
for fighterId,route in {Flashstep=CLIPS.Flashstep,Mirage=CLIPS.Mirage,GentleFist=CLIPS.GentleFist,Lion=CLIPS.Lion} do
	local base=stance(fighterId)
	for name,keys in route do
		if not AIRBORNE[name] and type(keys)=="table" then
			for _,key in keys do
				local pose=key.pose
				if type(pose)=="table" and pose~=base and not done[pose] and pose~=M and pose~=I and pose~=N and pose~=STANCE.Lion and not pose.keep then
					done[pose]=true
					for _,part in {"root","torso"} do
						local p,b=pose[part],base[part] or {}
						if p then
							for _,field in {"yaw","pitch","roll"} do
								if p[field] then p[field]=(b[field] or 0)+(p[field]-(b[field] or 0))*EXAGGERATE end
							end
							if part=="root" and p.z then p.z=math.clamp((b.z or 0)+(p.z-(b.z or 0))*EXAGGERATE,-1.4,1.4) end
						end
					end
					for _,foot in {"rf","lf"} do
						local p,b=pose[foot],base[foot] or {}
						if p and p.z then p.z=math.clamp((b.z or 0)+(p.z-(b.z or 0))*STEP,-1.9,1.6) end
					end
				end
			end
		end
	end
end

-- Kinetic chain: every ground strike is driven from the floor up. Between the
-- load and the contact a key is inserted where the feet and hips have already
-- moved (the step and the hip turn) while the chest and the striking limb are
-- still loaded; the contact then snaps the shoulders through. After the active
-- frames a follow-through key carries the chest and arms past the strike, so
-- weight is seen transferring rather than a limb moving alone.
local CHAIN={root=.78,rf=.88,lf=.88,torso=.32,head=.4,ra=.14,la=.14,rl=.4,ll=.4}
local function mixPart(a,b,base,w)
	local out={}
	local seen={}
	for k in a or {} do seen[k]=true end
	for k in b or {} do seen[k]=true end
	for k in seen do
		local va=(a and a[k]) or (base and base[k]) or 0
		local vb=(b and b[k]) or (base and base[k]) or 0
		if type(va)=="number" and type(vb)=="number" then out[k]=va+(vb-va)*w end
	end
	return out
end
local function chainPose(p0,p1,base)
	local out={}
	for part,w in CHAIN do
		local free=part=="rl" or part=="ll"
		local plant=part=="rf" or part=="lf"
		local freeKey=if part=="rf" then "rl" elseif part=="lf" then "ll" else nil
		if free then
			if p0[part] and p1[part] then out[part]=mixPart(p0[part],p1[part],nil,w) end
		elseif plant then
			if not (p0[freeKey] or p1[freeKey]) then out[part]=mixPart(p0[part],p1[part],base[part],w) end
		else
			out[part]=mixPart(p0[part],p1[part],base[part],w)
		end
	end
	-- A leg that kicks in both keys stays free; one that kicks in only one of
	-- them is left to the neighbouring keys (no mixed planted/free leg).
	if out.rl==nil and out.rf==nil and not (p0.rl or p1.rl) then out.rf=mixPart(p0.rf,p1.rf,base.rf,.88) end
	if out.ll==nil and out.lf==nil and not (p0.ll or p1.ll) then out.lf=mixPart(p0.lf,p1.lf,base.lf,.88) end
	return out
end
local function followPose(p2,base)
	local out={}
	for part,v in p2 do
		if type(v)=="table" then out[part]=table.clone(v) end
	end
	local function push(part,field,k)
		local t=out[part];if not t or not t[field] then return end
		local b=(base[part] and base[part][field]) or 0
		t[field]=t[field]+(t[field]-b)*k
	end
	push("torso","yaw",.16);push("torso","pitch",.12);push("root","yaw",.1)
	for _,arm in {"ra","la"} do push(arm,"raise",.06);push(arm,"out",.1) end
	if out.root then out.root.z=math.clamp((out.root.z or 0)-.08,-1.5,1.5) end
	return out
end
local chained={}
for fighterId,route in {Flashstep=CLIPS.Flashstep,Mirage=CLIPS.Mirage,GentleFist=CLIPS.GentleFist,Lion=CLIPS.Lion} do
	local base=stance(fighterId)
	for name,keys in route do
		if not AIRBORNE[name] and type(keys)=="table" and not chained[keys] and #keys>=3 then
			chained[keys]=true
			if keys[1].at==0 and keys[2].at==1 then
				table.insert(keys,2,K(.55,chainPose(keys[1].pose,keys[2].pose,base),"smooth"))
				keys[3].ease="out"
			end
			for index=1,#keys-1 do
				if keys[index].at==2 and keys[index+1].at>2.2 then
					table.insert(keys,index+1,K(2.25,followPose(keys[index].pose,base),"out"))
					break
				end
			end
		end
	end
end

-- Sample a key list at time `t` on the [0,3] attack timeline.
-- The drive into contact accelerates through the strike (slow load, fast
-- arrival) instead of popping out of the chamber at full speed: an "out" ease
-- on the contact key put the fastest frame at the very start, which read as
-- pose A -> pose B. Other keys keep their authored ease.
local function keyEase(b)
	if b.at==1 and b.ease=="out" then return smooth end
	return EASE[b.ease] or smooth
end
local function sampleKeys(keys,t)
	if t<=keys[1].at then return built(keys[1].pose) end
	for index=1,#keys-1 do
		local a,b=keys[index],keys[index+1]
		if t<=b.at then
			local span=math.max(b.at-a.at,1e-3)
			local ease=keyEase(b)
			return blend(built(a.pose),built(b.pose),ease((t-a.at)/span))
		end
	end
	return built(keys[#keys].pose)
end
-- Real-seconds -> move timeline, using the exact per-fighter timings the server
-- uses. A small lead compensates for the damping lag so contact frames land on
-- the server's active window.
local LEAD=.03
-- Variants: strikes the server starts under another move's name
-- (attackVariant). The clip is the variant's, the timing the carrier move's.
-- Rock Lee's finishers ride on the Slam like the Lion Combo.
local VARIANT_OF={Rasengan="DashAttack",RasenganDrop="Slam",LionBarrage="Slam",PrimaryLotus="Slam",HiddenLotus="Slam",LeafHeel="Slam"}
Motion.VARIANT_OF=VARIANT_OF
-- Naruto: the barrage's finisher rides on the Slam; a clone plays its side of
-- a route he carries out on that route's own timing (Attacks proxyClip).
VARIANT_OF.NarutoRendan="Slam";VARIANT_OF.CloneKickStrike="CloneKick";VARIANT_OF.UzumakiRise="UzumakiKick";VARIANT_OF.MirrorStrike="MirrorClone"
-- Global kunai (DEC-030): with a drawn blade the string and the heavy play
-- the shared Kunai.* clips (tools/blender/kunai_lion.py), on any fighter.
local KUNAI_STRIKE={Light1=true,Light2=true,Light3=true,Heavy=true}
local function kunaiClip(subject,name)
	if subject.armed and KUNAI_STRIKE[name] and Authored and Authored.has("Kunai."..name) then return "Kunai."..name end
	return nil
end
Motion.kunaiClip=kunaiClip
local function clipName(subject)
	return if VARIANT_OF[subject.attackVariant or ""] then subject.attackVariant else subject.attackName
end
local function timing(name,fighterId)
	local spec=Attacks[name] or Attacks[VARIANT_OF[name] or "DashAttack"]
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
-- The clip's footwork at `elapsed`: where each planted foot should be (root
-- space), or nil for a leg that is kicking (free) at this moment.
local function attackFeet(name,elapsed,fighterId,clip)
	if clip or (Authored and Authored.has(tostring(fighterId).."."..tostring(name))) then return nil end
	local route=CLIPS[fighterId] or CLIPS[familyOf(fighterId).clips or familyOf(fighterId).body] or CLIPS.Flashstep
	local borrow=familyOf(fighterId).borrow
	local keys=route[name] or (borrow and borrow[name] and route[borrow[name]]) or (Attacks[name] and Attacks[name].clip and route[Attacks[name].clip]) or route.Light1
	local t=attackPhase(name,elapsed,fighterId)
	local a,b=keys[1],keys[1]
	local u=0
	if t>keys[1].at then
		a,b=keys[#keys],keys[#keys]
		for index=1,#keys-1 do
			if t<=keys[index+1].at then
				a,b=keys[index],keys[index+1]
				u=keyEase(b)((t-a.at)/math.max(b.at-a.at,1e-3))
				break
			end
		end
	end
	local out={}
	for _,side in {"R","L"} do
		local free=if side=="R" then "rl" else "ll"
		local plant=if side=="R" then "rf" else "lf"
		if not (a.pose[free] or b.pose[free]) then
			local fa,fb=a.pose[plant] or {},b.pose[plant] or {}
			local function mix(k) return (fa[k] or 0)+((fb[k] or 0)-(fa[k] or 0))*u end
			out[side]={x=mix("x"),z=mix("z"),yaw=mix("yaw"),y=mix("y"),toe=mix("toe")}
		end
	end
	return out
end
-- Pose + weight of an attack at `elapsed`. The weight stays at 1 through the
-- active window and most of recovery, then fades so the stance takes over.
local function attackTargets(name,elapsed,fighterId,clip)
	local authored=clip or tostring(fighterId).."."..tostring(name)
	if Authored and Authored.has(authored) then
		-- (Blender-first) the authored strike, time-warped onto the server's
		-- startup / active / recovery through its contact markers.
		local phase,startup,_,recovery=attackPhase(name,elapsed,fighterId)
		local weight=if phase<2.55 then 1 else 1-smooth((phase-2.55)/.45)
		local t=Authored.attackTime(authored,phase)
		if phase<1 then
			-- (ANIM-005) The contact lands on the server's frame. A wind-up
			-- authored longer than the startup the server allows plays at most
			-- 1.25x its own speed; the slow start of it (leaving the stance) is
			-- skipped and the transition (inertialized) carries the body in.
			local c=Authored.clip(authored)
			local contact=c.markers.contact or c.length*.3
			local visible=math.max(startup-LEAD,1/60)
			local t0=math.max(0,contact-visible*1.25)
			t=t0+phase*(contact-t0)
		end
		if phase>=2 then
			-- (ANIM-002) The recovery plays at the clip's own speed: squeezed
			-- into a short server recovery, a re-chamber turned into a snap.
			-- If the server frees the body first, the next clip takes over
			-- through the transition.
			local c=Authored.clip(authored)
			local recover=c.markers.recover or c.length
			t=math.min(c.length,recover+(phase-2)*recovery)
		end
		return Authored.sample(authored,t),weight,phase
	end
	local route=CLIPS[fighterId] or CLIPS[familyOf(fighterId).clips or familyOf(fighterId).body] or CLIPS.Flashstep
	local borrow=familyOf(fighterId).borrow
	local keys=route[name] or (borrow and borrow[name] and route[borrow[name]]) or (Attacks[name] and Attacks[name].clip and route[Attacks[name].clip]) or route.Light1
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
	-- Wind Cut: thrown on the run as a horizontal slash off the kunai's edge
	-- (the gust leaves the blade sideways), not an overhand throw.
	WindCut=function(t,release)
		local from={torso={yaw=-30,pitch=2},head={yaw=14},ra={raise=86,out=60,twist=-20,elbow=20,wrist=-10},la={raise=36,out=22,elbow=64}}
		local to={torso={yaw=10,pitch=6},head={yaw=-6},ra={raise=88,out=-40,twist=20,elbow=10,wrist=24},la={raise=30,out=26,elbow=70}}
		local start=math.max(release-.06,.02)
		if t<start then return from,smooth(t/start) end
		if t<release+.06 then
			local u=smooth((t-start)/(release+.06-start))
			return {torso=mixPart(from.torso,to.torso,nil,u),head=mixPart(from.head,to.head,nil,u),ra=mixPart(from.ra,to.ra,nil,u),la=mixPart(from.la,to.la,nil,u)},1
		end
		if t<release+.2 then return to,1 end
		return to,1-smooth((t-release-.2)/.16)
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
local function techSpec(fighterId,id)
	local def=Fighters[fighterId]
	for _,spec in (def and def.Techniques) or {} do if spec.Id==id then return spec end end
	return {}
end
-- Cast poses and intros registered by a fighter's own motion module
-- (GaleMotion.install): CAST[techniqueId](actor,base,t,state) -> spec or nil,
-- INTRO[family intro](base) -> spec.
local CAST,INTRO={},{}
local function castSpec(actor)
	local id=actor.castId
	local fighterId=actor.fighterId
	local base=stance(fighterId)
	local t=actor.castElapsed or 0
	local state=actor.state
	if CAST[id] then return CAST[id](actor,base,t,state) end
	if id=="Rotation" then
		-- Eight Trigrams Rotation: a full-body spin, arms out, weight centred.
		local spin=(t*1500)%360
		return merge(base,{root={y=-.45,pitch=2,yaw=spin},torso={pitch=0,yaw=0},head={pitch=0,yaw=0},
			ra={raise=78,out=64,twist=0,elbow=12,wrist=-20},la={raise=78,out=64,twist=0,elbow=12,wrist=-20},rf={x=.3,z=.4},lf={x=-.3,z=-.4}})
	elseif id=="VacuumPalm" then
		if state=="TechniqueChannel" then return merge(base,{root={y=-.8,yaw=56},torso={yaw=10},la={raise=50,out=-10,twist=-60,elbow=112,wrist=-30}}) end
		return merge(base,{root={y=-.66,z=-.4,yaw=14,pitch=10},torso={yaw=-26},la={raise=94,out=-4,twist=-72,elbow=0,wrist=-70},ra={raise=40,out=20,elbow=80},lf={z=-1.4},rf={z=1.1}})
	elseif id=="SixtyFourPalms" then
		if state=="TechniqueChannel" then
			-- "You are within my field of divination": very wide, very low.
			return merge(base,{root={y=-1.05,yaw=44,pitch=8},torso={yaw=-10},head={yaw=-26},la={raise=86,out=-4,twist=-60,elbow=12,wrist=-50},ra={raise=140,out=-20,twist=30,elbow=60,wrist=-40},lf={z=-1.45,x=-.2},rf={z=1.35,x=.35,yaw=70}})
		end
		local beat=math.floor(t*16)%2==0
		local jitter=math.sin(t*50)*6
		return merge(base,{root={y=-.95,z=-.3,yaw=24+jitter,pitch=12},torso={yaw=if beat then -18 else 12},head={yaw=-14},
			la=if beat then {raise=92,out=-6,twist=-72,elbow=2,wrist=-64} else {raise=60,out=-10,twist=-50,elbow=90,wrist=-30},
			ra=if beat then {raise=60,out=-20,twist=50,elbow=92,wrist=-30} else {raise=92,out=-4,twist=72,elbow=2,wrist=-64},
			lf={z=-1.45,x=-.2},rf={z=1.3,x=.35,yaw=64}})
	elseif id=="PhoenixFlower" then
		if state=="TechniqueChannel" then return sealPose(base,t,false) end
		-- Phoenix Flower: a quick sweep of the head across the fan while the hand
		-- ring stays at the mouth.
		local sweep=math.sin(math.clamp(t-(actor.channel or 0),0,.4)*14)*18
		return merge(base,{root={y=-.55,pitch=10,yaw=sweep*.5},torso={pitch=8,yaw=sweep},head={pitch=8,yaw=sweep*.6},
			ra={raise=112,out=-36,twist=22,elbow=146,wrist=-10},la={raise=8,out=28,elbow=30},lf={z=-1.0},rf={z=.95,yaw=24}})
	elseif id=="FireBloom" then
		if state=="TechniqueChannel" and (actor.techCharge or 0)>0 then
			-- (Reference quality) Held: the ring of fingers at the mouth, the chest
			-- drawing in deeper and the weight sinking back the longer he holds.
			local c=actor.techCharge
			local quiver=math.sin(t*38)*2*c
			return merge(base,{root={y=-.5-.35*c,z=.25*c,pitch=-6-10*c,yaw=8},torso={pitch=-12-12*c+quiver,yaw=-4},head={pitch=-10-8*c},
				ra={raise=112,out=-36,twist=22,elbow=146,wrist=-10},la={raise=30+20*c,out=10,elbow=60,wrist=-10},lf={z=-1.0-.2*c},rf={z=.95+.25*c,yaw=30}})
		end
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
		if state=="TechniqueChannel" then
			-- One hand signs at the chest, the weight already going back.
			return merge(base,{root={y=-.24,z=.3,pitch=-4},head={pitch=4,yaw=-4},ra={raise=96,out=-34,twist=30,elbow=140,wrist=10},la={raise=10,out=12,elbow=30}})
		end
		-- Released: he withdraws behind his image, then is back in guard.
		local since=t-(techSpec(fighterId,id).Channel or .42)
		if since<.12 then return merge(base,{root={y=-.3,z=.6,pitch=-6},head={pitch=2},ra={raise=50,out=-10,elbow=90},la={raise=20,out=14,elbow=40}}) end
		return nil
	elseif id=="Read" then
		-- Chin a little down, hands low and open: waiting for the blow.
		return merge(base,{root={y=-.45,pitch=6},head={pitch=-4},ra={raise=30,out=-16,elbow=80,wrist=-10},la={raise=45,out=-20,elbow=70,wrist=-10}})
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
		if actor.airborne and state=="TechniqueRecovery" then
			-- Arriving beside a launched body: already in the air, kunai up, ready
			-- for the air strike (the legs keep the air pose).
			return merge(base,{root={pitch=8},torso={pitch=6},head={pitch=-10},ra={raise=118,out=24,twist=30,elbow=58,wrist=-20},la={raise=36,out=34,elbow=40}})
		end
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
	elseif id=="WireTrap" then
		if state=="TechniqueChannel" then return merge(base,{torso={yaw=20},ra={raise=40,out=-30,twist=30,elbow=110},la={raise=40,out=-30,twist=30,elbow=110}}) end
		return merge(base,{torso={yaw=-24,pitch=6},ra={raise=88,out=40,elbow=8,wrist=24},la={raise=30,out=20,elbow=70}})
	elseif id=="Chidori" then
		-- The charge: low, the lightning hand down and back, the other gripping
		-- its wrist; the thrust itself is the ChidoriThrust strike.
		local shake=math.sin(t*90)*2
		return merge(base,{root={y=-.95,pitch=24,yaw=20+shake},torso={pitch=14,yaw=10},head={pitch=-14},ra={raise=-20,out=20,twist=40,elbow=30,wrist=-30},
			la={raise=20,out=-30,twist=40,elbow=90},lf={z=-1.2},rf={z=1.1,yaw=40}})
	elseif id=="LeafGreatWhirlwind" then
		-- Rock Lee forms no seal: a crouch wound up for the spin, then the kick
		-- itself is the GreatWhirlwind strike.
		return merge(base,{root={y=-1.0,pitch=16,yaw=64},torso={pitch=8,yaw=30},head={yaw=-44},la={raise=50,out=30,elbow=60},lf={z=-1.0},rf={z=.9}})
	elseif id=="ShadowClone" or id=="MassShadowClone" then
		-- Naruto's Kage Bunshin: one seal, the cross of both hands before the chest
		-- (wider and lower for the multi clone).
		local wide=id=="MassShadowClone"
		return merge(base,{root={y=if wide then -.72 else -.46,pitch=4},torso={pitch=4},head={pitch=6},
			ra={raise=70,out=-30,twist=40,elbow=100,wrist=10},la={raise=64,out=-34,twist=-30,elbow=96,wrist=-10},lf={z=-.6,x=-.2},rf={z=.6,x=.2}})
	elseif id=="CloneRasengan" then
		-- The right palm held out flat, the left hand over it: the sphere turns between.
		return merge(base,{root={y=-.6,pitch=12,yaw=8},torso={pitch=8,yaw=-6},head={pitch=14},ra={raise=74,out=12,twist=-80,elbow=58,wrist=10},la={raise=40,out=10,elbow=60}})
	elseif id=="RasenganShape" then
		-- (His clone beside him) both hands cupped over his palm, shaping it.
		return merge(base,{root={y=-.62,pitch=16,yaw=-20},torso={pitch=12,yaw=-14},head={pitch=18,yaw=-10},ra={raise=66,out=-30,twist=40,elbow=80,wrist=-20},la={raise=70,out=-36,twist=-40,elbow=70,wrist=-20}})
	end
	-- A family technique (Server/Families) without its own clip: signs while it
	-- is moulded, then the family's release shape. spec.Pose = {channel=...,
	-- release=...} (this merge format) overrides either.
	local spec=techSpec(fighterId,id)
	if spec.Family then
		local custom=spec.Pose
		if state=="TechniqueChannel" then
			if custom and custom.channel then return merge(base,custom.channel) end
			return sealPose(base,t,false)
		end
		if custom and custom.release then return merge(base,custom.release) end
		local family=spec.Family
		if family=="Projectile" then
			-- Thrust from the shoulder, weight on the front foot.
			return merge(base,{root={y=-.55,pitch=10,yaw=-14},torso={pitch=6,yaw=-18},head={pitch=4},ra={raise=92,out=8,twist=-60,elbow=6,wrist=-50},
				la={raise=30,out=24,elbow=60},lf={z=-1.05},rf={z=1.0,yaw=30}})
		elseif family=="Burst" then
			-- Low and wide, both arms flung out: the release comes from the body.
			return merge(base,{root={y=-1.0,pitch=6},torso={pitch=4},head={pitch=-6},ra={raise=70,out=70,twist=0,elbow=14,wrist=-20},
				la={raise=70,out=70,twist=0,elbow=14,wrist=-20},lf={x=-.35,z=-.6},rf={x=.35,z=.6}})
		elseif family=="Zone" then
			-- One palm pressed toward the ground, the other holding the seal.
			return merge(base,{root={y=-1.15,pitch=24},torso={pitch=18},head={pitch=-14},ra={raise=20,out=10,twist=-40,elbow=20,wrist=-60},
				la={raise=96,out=-34,twist=30,elbow=140,wrist=10},lf={z=-1.1},rf={z=.9}})
		elseif family=="Buff" then
			-- Fists down at the hips, chest up: the chakra rises around him.
			return merge(base,{root={y=-.7,pitch=-4},torso={pitch=-10},head={pitch=-12},ra={raise=14,out=34,twist=20,elbow=40,wrist=0},
				la={raise=14,out=34,twist=20,elbow=40,wrist=0},lf={x=-.3,z=-.3},rf={x=.3,z=.3}})
		elseif family=="Counter" then
			-- Open guard, hands forward: waiting for the blow.
			return merge(base,{root={y=-.6,pitch=6},head={pitch=-4},ra={raise=52,out=-12,elbow=70,wrist=-10},la={raise=66,out=-20,elbow=60,wrist=-10}})
		elseif family=="Teleport" then
			-- Landed low out of the movement, already turned to the opponent.
			return merge(base,{root={y=-1.0,pitch=18},torso={pitch=10},head={pitch=-16},ra={raise=50,out=20,elbow=80},la={raise=10,out=24,elbow=20},lf={z=-1.0},rf={z=1.0,yaw=40}})
		end
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
-- Feet planted in the world. A foot stays exactly where it was put down until
-- it drifts too far from where it belongs under the moving body; then it steps
-- (one foot at a time, the other holds the ground). Walking, strafing,
-- stopping and turning on the spot all come out of the same rule, so feet
-- never skate and the steps always match the real displacement.
local STEP_REACH,STEP_LEAD,RUN_SPEED=1.3,1.05,9
local MIN_STANCE=.085 -- seconds a running foot stays on the ground, at least
-- How each prodigy carries his body before any jutsu: stride and cadence
-- (Minato long and explosive, Itachi economical, Neji short precise steps),
-- arm swing, forward lean, vertical bounce, and a guard carried while moving.
local GAIT={
	Flashstep={stride=1.12,cadence=.98,arm=50,lean=5,bob=1.15,guard=0},
	Mirage={stride=1.0,cadence=.94,arm=24,lean=-1,bob=.7,guard=.35},
	GentleFist={stride=.84,cadence=1.12,arm=16,lean=0,bob=.55,guard=.8},
	Lion={stride=1.08,cadence=1.02,arm=44,lean=6,bob=1.05,guard=.15},
	-- Gaara walks with his arms folded: short steps, almost no bounce.
	Sand={stride=.8,cadence=.88,arm=0,lean=-1,bob=.35,guard=0,holdArms=true},
}
-- Rock Lee: long, quick and bouncy steps, leaning in; the rear hand stays behind
-- his back until he breaks into a full sprint (holdRear).
GAIT.Leaf={stride=1.16,cadence=1.1,arm=40,lean=8,bob=1.0,guard=.1,holdRear=true}
-- Naruto: energetic and loose, arms swinging wide, a heavy bouncing stride.
GAIT.Legion={stride=1.1,cadence=1.05,arm=48,lean=7,bob=1.2,guard=.05}
local function gaitOf(id) return GAIT[id] or GAIT[familyOf(id).body] or GAIT.Flashstep end
-- The full sprint per fighter (movement overhaul, brief §3 / §17): how far the
-- body pitches into the run (x the shared ninja run) and what the arms do —
-- swept back (default), low and loose (economical), pumping (heavy) or
-- trailing wide (glide). Same server speeds; only the body differs.
local RUN={default={lean=1,arms="back"},
	Leaf={lean=1.2,arms="back"},Lion={lean=1.1,arms="back"},Flicker={lean=1.15,arms="back"},Legion={lean=1.05,arms="back"},
	Mirage={lean=.6,arms="low"},Rinnegan={lean=.45,arms="low"},Puppet={lean=.5,arms="low"},Professor={lean=.7,arms="low"},
	Mist={lean=.75,arms="pump"},Clay={lean=.8,arms="pump"},Bone={lean=.9,arms="pump"},Ink={lean=.95,arms="pump"},
	Mirror={lean=1.05,arms="glide"},Serpent={lean=.85,arms="glide"}}
-- A fighter whose motion data lives in its own module (DEC-015: the engine
-- offers the tables and builders, the module adds its stance, gait, clips,
-- throw overlays, cast poses and intro). Temari first.
require(script.Parent.GaleMotion).install({STANCE=STANCE,GAIT=GAIT,CLIPS=CLIPS,THROWS=THROWS,CAST=CAST,INTRO=INTRO,
	K=K,merge=merge,smooth=smooth,mixPart=mixPart,sealPose=sealPose})
-- DEC-026 newcomers (Madara, Hashirama, Hiruzen as children): their own clips.
require(script.Parent.Wave4Motion).install({STANCE=STANCE,GAIT=GAIT,CLIPS=CLIPS,THROWS=THROWS,CAST=CAST,INTRO=INTRO,
	K=K,merge=merge,smooth=smooth,mixPart=mixPart,sealPose=sealPose})
-- Batch 1 bodies authored from their bibles (Zabuza first).
require(script.Parent.Wave1Motion).install({STANCE=STANCE,GAIT=GAIT,CLIPS=CLIPS,THROWS=THROWS,CAST=CAST,INTRO=INTRO,
	K=K,merge=merge,smooth=smooth,mixPart=mixPart,sealPose=sealPose})
-- Batch 3 bodies authored from their bibles (Killer Bee first).
require(script.Parent.Wave3Motion).install({STANCE=STANCE,GAIT=GAIT,CLIPS=CLIPS,THROWS=THROWS,CAST=CAST,INTRO=INTRO,
	K=K,merge=merge,smooth=smooth,mixPart=mixPart,sealPose=sealPose})
local function stepFeet(char,s,base,velocity,speed,dt,mode)
	local root=char:FindFirstChild("HumanoidRootPart")
	dt=dt or 1/60
	local function authored(side) return ((if side==1 then base.rf else base.lf) or {}) end
	if not root then return authored(1),authored(-1),0,0 end
	local rootCF=root.CFrame
	local look=Vector3.new(rootCF.LookVector.X,0,rootCF.LookVector.Z)
	if look.Magnitude<1e-3 then look=Vector3.new(0,0,-1) end
	local flat=CFrame.lookAt(rootCF.Position,rootCF.Position+look.Unit)
	local groundY=rootCF.Position.Y+ANKLE_Y
	-- Re-seat after anything that was not ground locomotion (air, a reaction).
	if s.feet and elapsedTime-(s.feetAt or -1)>.25 then s.feet=nil end
	s.feetAt=elapsedTime
	local moving=if mode then 0 else math.clamp(speed/8,0,1)
	local running=not mode and speed>=RUN_SPEED
	-- Finish a running swing from its actual world position, including its
	-- height. Old walking timers must not resume underneath a running foot.
	if s.feet and not running then
		for _,f in s.feet do
			if f.runStance==false and f.runRel then
				local p=f.p or 0
				local height=math.sin(math.pi*p^.75)*(s.runLift or .45)
				f.world=f.hipNow+f.runRel+Vector3.new(0,height,0)
				f.from=f.world;f.t=0;f.p=0;f.dur=.12
			end
			f.runStance=nil;f.runRel=nil
		end
		s.runPhase=nil
	end
	-- Cadence from geometry: a foot lands `lead` ahead of the hip and may drift
	-- `threshold` behind before it must step, so it holds the ground for
	-- (lead+threshold)/speed; the swing must fit inside the other foot's stance
	-- or the body outruns its own legs.
	local threshold=if mode=="attack" then .28 elseif mode=="react" then .35 else math.clamp(.3+speed*.03,.3,STEP_REACH)
	local leadLength=math.min(STEP_LEAD,speed*.06)
	local stanceTime=if speed>.5 then (leadLength+threshold)/speed else .3
	local swingTime=if mode=="attack" then .09 elseif mode=="react" then .12 else math.clamp(stanceTime*.92,.065,.26)
	local lead=if speed>.01 then velocity.Unit*leadLength else Vector3.zero
	local feet=s.feet or {}
	s.feet=feet
	local rests={}
	for _,side in {1,-1} do
		local key=if side==1 then "R" else "L"
		local a=authored(side)
		local restLocal=Vector3.new(.5*side+(a.x or 0)*(1-moving)+.06*side*moving,0,(a.z or 0)*(1-moving))
		local rest=flat:PointToWorldSpace(restLocal)+lead
		rests[key]=Vector3.new(rest.X,groundY,rest.Z)
		if not feet[key] then feet[key]={world=rests[key],planted=true} end
	end
	for key,f in feet do
		if not f.planted and f.runStance==nil and f.t then
			f.t+=dt
			f.p=math.min(1,f.t/f.dur)
			if f.p>=1 then f.planted=true;f.world=rests[key];f.p=nil end
		elseif not f.planted and f.runStance==nil then
			-- Left a run mid-flight: finish the step onto the rest spot.
			f.t=0;f.dur=.12;f.from=f.from or f.world
		end
		-- The ground under a planted foot is the floor the body stands on.
		if f.planted then f.world=Vector3.new(f.world.X,groundY,f.world.Z) end
	end
	local function drift(key)
		local w,r=feet[key].world,rests[key]
		return Vector3.new(w.X-r.X,0,w.Z-r.Z).Magnitude
	end
	local order=if drift("L")>drift("R") then {"L","R"} else {"R","L"}
	if not mode and speed>=RUN_SPEED then order={} end
	for _,key in order do
		local f=feet[key];local other=feet[if key=="R" then "L" else "R"]
		local e=drift(key)
		if f.planted and e>STEP_REACH*2.4 then f.world=rests[key] -- carried away (knockback, slide): re-seat
		elseif f.planted and e>threshold and (other.planted or (other.p or 0)>.6) then
			f.planted=false;f.from=f.world;f.t=0;f.p=0;f.dur=swingTime*math.clamp(e/math.max(threshold,.01),.75,1.15)
			break
		end
	end
	local lift=math.clamp(.22+speed*.012,.22,.75)
	-- Running (not walking, turning or attacking): a real stride with a flight
	-- phase. A phase clock sets a natural cadence; each foot holds the ground
	-- for exactly stanceLen/speed (so it never skates while planted), then
	-- flies forward to land ahead of the hip. Steps get long instead of the
	-- legs pattering, and the arms and chest have time to move.
	local runDip=0
	local stanceLen=1
	-- Swing height: a running foot rises well off the floor (heel toward the
	-- hips, knee driven through), more the faster the body travels.
	local runLift=math.clamp(.3+speed*.024,.45,1.35)
	s.runLift=runLift
	if running then
		local gait=s.gait or GAIT.Flashstep
		-- A sprint drives the legs faster as well as longer: above run speed the
		-- cadence keeps rising (3.8 cap) so a sprint reads fast before the floor does.
		local cadence=math.clamp(speed/7.2,1.7,3.8)*gait.cadence
		-- The sprint posture sits lower, so its planted foot can reach further.
		stanceLen=math.clamp((1+speed*.03)*gait.stride,.9,if speed>28 then 2.3 else 1.85)
		local duty=math.clamp(stanceLen/speed*cadence,.16,.6)
		-- Never fewer than ~5 frames on the ground: at sprint speed a world-locked
		-- foot sweeps under the body in 2-3 frames, which reads as the foot
		-- teleporting. The stance foot glides a little with the body instead
		-- (slip), which the speed hides.
		duty=math.max(duty,math.min(.6,MIN_STANCE*cadence))
		local slip=math.max(0,1-stanceLen*cadence/(speed*duty))
		if not s.runPhase then
			-- Enter the cycle with the foot that is already ahead in stance.
			local rz=rootCF:PointToObjectSpace(feet.R.world).Z
			s.runPhase=if rz<0 then 0 else .5
		end
		s.runPhase=(s.runPhase+dt*cadence)%1
		local dirUnit=if speed>.01 then velocity.Unit else look.Unit
		for key,f in feet do
			local side=if key=="R" then 1 else -1
			local q=(s.runPhase+(if key=="R" then 0 else .5))%1
			local hip=flat:PointToWorldSpace(Vector3.new(.45*side,0,0))
			if q<duty then
				-- Stance: planted on its landing spot, locked in the world.
				if not f.runStance then
					local land=hip+dirUnit*stanceLen*.5
					f.world=Vector3.new(land.X,groundY,land.Z);f.planted=true;f.p=nil
				end
				f.runStance=true
				if slip>0 then f.world+=Vector3.new(dirUnit.X,0,dirUnit.Z)*speed*slip*dt end
				runDip=math.max(runDip,math.sin(math.pi*q/duty))
			else
				-- Flight / swing: the foot is carried with the hips, from where it
				-- pushed off (behind) to its landing spot (ahead of the hip).
				if f.runStance~=false then
					local back=f.world-hip
					f.fromRel=Vector3.new(back.X,0,back.Z);f.planted=false
				end
				f.runStance=false
				local u=(q-duty)/(1-duty)
				f.p=u
				-- Not a glide from back to front at ankle height: the foot peels off
				-- behind while the heel rises, then the knee drives through and the
				-- shin reaches out to land ahead of the hip.
				local h=if u<.3 then .1*smooth(u/.3) else .1+.9*smooth((u-.3)/.7)
				f.runRel=f.fromRel:Lerp(dirUnit*stanceLen*.5,h)
				f.hipNow=Vector3.new(hip.X,groundY,hip.Z)
			end
		end
	end
	local out={}
	for key,f in feet do
		local pos=f.world
		local toe=if f.planted then 0 else -18
		if not f.planted then
			local p=f.p or 0
			if f.runRel and f.runStance==false then
				-- Peak early (heel recovery), still high as the knee drives, down to land.
				pos=f.hipNow+f.runRel+Vector3.new(0,math.sin(math.pi*p^.75)*runLift,0)
				toe=-18-22*math.sin(math.pi*math.min(1,p/.7))
			else pos=f.from:Lerp(rests[key],smooth(p))+Vector3.new(0,math.sin(math.pi*p)*lift,0) end
		end
		local side=if key=="R" then 1 else -1
		local l=rootCF:PointToObjectSpace(pos)
		local a=authored(side)
		out[key]={x=l.X-.5*side,y=l.Y-ANKLE_Y,z=l.Z,yaw=(a.yaw or 0)*(1-moving),toe=toe}
	end
	-- The body is lowest as a foot lands and rises through the step (running:
	-- it sinks through each stance and floats in the flight phase).
	local swingP=feet.R.p or feet.L.p
	local bob
	if running then bob=(.03-.13*runDip)*((s.gait and s.gait.bob) or 1)
	else bob=if swingP then -.05*moving+.08*math.sin(math.pi*swingP)*moving else -.05*moving end
	-- Arms answer the legs: the left arm comes forward with the right foot.
	-- Running: normalised by the stride, so the arms pump through their whole
	-- range instead of a third of it.
	local localTravel=flat:VectorToObjectSpace(if speed>.01 then velocity.Unit else Vector3.new(0,0,0))
	-- Measure along travel, not just the body's forward axis: pure strafing
	-- used to leave the arms and pelvis frozen while the legs stepped.
	local separation=(out.R.x-out.L.x)*localTravel.X+(out.R.z-out.L.z)*localTravel.Z
	local armSwing=math.clamp(separation/(if running then stanceLen*.8 else 2.2),-1,1)
	return out.R,out.L,bob,armSwing
end
-- ------------------------------------------------- authored locomotion
-- (Blender-first) A fighter with an authored locomotion set (tools/blender,
-- clips_loco) moves with it instead of the procedural gait: the idle, the
-- walk / run cycles in four directions and the sprint, blended by the body's
-- real direction and speed. Every cycle starts on the right foot's strike,
-- and its phase advances by the distance travelled over the clip's stride,
-- so the planted feet stay on the floor at any speed.
-- (ANIM-002) The ankle of a drawn pose, in HumanoidRootPart space (the rig's
-- Motor6D chain: Root, hip, knee, ankle pivots).
local function ankleFrame(pose,key)
	local prefix=if key=="R" then "Right" else "Left"
	local side=if key=="R" then 1 else -1
	return (pose.Root or IDENTITY)*CF(.5*side,-.55,0)*(pose[prefix.."Hip"] or IDENTITY)*CF(0,-1.05,0)
		*(pose[prefix.."Knee"] or IDENTITY)*CF(0,-1,0)*(pose[prefix.."Ankle"] or IDENTITY)
end
Motion._ankleFrame=ankleFrame
-- (ANIM-002) Feet of an authored clip on the real floor. A foot the clip keeps
-- on the ground (low and still in the clip) is locked where it landed in the
-- world, whatever the server does with the body meanwhile (a lunge, the slide
-- out of a running strike); a foot the clip lifts leaves from where it really
-- was and joins the clip's path over a few frames (a step, not a glide). A
-- locked foot the body has carried out of reach is released the same way.
local function authoredFeet(char,pose,dt)
	local s=stateOf(char)
	local root=char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	dt=dt or 1/60
	local fresh=not s.af or elapsedTime-(s.afAt or -1)>.2
	if fresh then s.af={} end
	s.afAt=elapsedTime
	local rootCF=root.CFrame
	local feet={}
	for _,key in {"R","L"} do
		local f=s.af[key]
		local frame=ankleFrame(pose,key)
		local clipPos=frame.Position
		if not f then
			-- (ANIM-005) Entering an authored clip: the foot starts where the
			-- body really has it (the gait, the stance) and swings onto the
			-- clip's path; planted at the clip's spot it snapped the ankle.
			f={off=Vector3.zero}
			if fresh and s.pose[(if key=="R" then "Right" else "Left").."Hip"] then
				local here=ankleFrame(s.pose,key).Position-clipPos
				if here.Magnitude>.12 and here.Magnitude<2.5 then f.off=here;f.offV=Vector3.zero;f.release=true end
			end
		end
		s.af[key]=f
		local speed=if f.prev then (clipPos-f.prev).Magnitude/dt else 0
		f.prev=clipPos
		local low=clipPos.Y-ANKLE_Y<(if f.planted then .3 else .16)
		local still=speed<(if f.planted then 6 else 3.5)
		-- A foot released to step does not plant again before it has arrived.
		-- (Also any swing still under way: planting it mid-arc dropped the foot
		-- by its lift in one frame.)
		local stepping=not f.planted and f.swing0~=nil and f.off.Magnitude>.12
		if not stepping then f.release=nil end
		if low and still and not stepping then
			if not f.planted then
				f.planted=true
				local at=rootCF:PointToWorldSpace(clipPos+f.off)
				f.world=Vector3.new(at.X,rootCF.Position.Y+ANKLE_Y,at.Z)
			end
			local here=rootCF:PointToObjectSpace(f.world)
			here=Vector3.new(here.X,ANKLE_Y,here.Z)
			local hip=(pose.Root or IDENTITY)*Vector3.new(if key=="R" then .5 else -.5,-.55,0)
			if (here-hip).Magnitude>L1+L2-.04 or (here-clipPos).Magnitude>1.3 then
				-- Out of reach: let it go, it steps back under the body.
				f.planted=false;f.off=here-clipPos;f.release=true;f.offV=Vector3.zero
			else
				f.off=here-clipPos
			end
		else
			if f.planted then f.planted=false;f.off=rootCF:PointToObjectSpace(f.world)-clipPos;f.offV=Vector3.zero end
		end
		local lift=0
		if not f.planted then
			-- A swing from where the foot really was onto the clip's path, lifted
			-- off the floor in an arc (a step, never a skate).
			if f.off.Magnitude>.05 then
				f.swing0=math.max(f.swing0 or 0,f.off.Magnitude)
				-- A critically damped spring, not a decay: the foot leaves the
				-- floor from rest and accelerates into the step (an exponential
				-- moved it a third of the way on the release frame: a knee snap).
				f.off,f.offV=damper(f.off,f.offV or Vector3.zero,.055,dt)
				local u=1-f.off.Magnitude/f.swing0
				lift=4*u*(1-u)*math.min(.55,f.swing0*.35)
			else
				f.off=Vector3.zero;f.swing0=nil;f.offV=Vector3.zero
			end
		else
			f.swing0=nil;f.offV=Vector3.zero
		end
		-- A foot the clip kicks high stays the clip's own (free leg).
		if clipPos.Y-ANKLE_Y<.9 then
			local rx,ry=frame:ToEulerAnglesYXZ()
			local target=clipPos+f.off
			if f.planted then target=Vector3.new(target.X,ANKLE_Y,target.Z) else target+=Vector3.new(0,lift,0) end
			feet[key]={ankle=target,yaw=-math.deg(ry),toe=math.deg(rx),planted=f.planted}
		end
	end
	return feet
end
Motion._authoredFeet=authoredFeet
Motion._feetState=function(char) return stateOf(char).af end
local LOCO_DIRS={"F","B","R","L"}
local function mixPoses(list)
	local out,acc=nil,0
	for _,e in list do
		local pose,w=e[1],e[2]
		if pose and w>1e-3 then
			acc+=w
			if not out then out=table.clone(pose)
			else
				local t=w/acc
				for joint,cf in pose do out[joint]=(out[joint] or IDENTITY):Lerp(cf,t) end
			end
		end
	end
	return out
end
Motion._mixPoses=mixPoses
local function strideOf(name)
	local c=Authored and Authored.clip(name)
	return c and c.meta and c.meta.stride or 7
end
local function hasAuthoredLoco(fighterId)
	return Authored~=nil and Authored.has(tostring(fighterId)..".Run.F")
end
Motion.hasAuthoredLoco=hasAuthoredLoco
-- Eyes on the opponent (yaw on the chest and head, degrees).
local function trackOf(root,actor)
	if not (root and actor.lookAt) then return 0,0 end
	local to=actor.lookAt-root.Position
	local l=root.CFrame:VectorToObjectSpace(Vector3.new(to.X,0,to.Z))
	if l.Magnitude<=1 then return 0,0 end
	local angle=math.deg(math.atan2(l.X,-l.Z))
	local torso=math.clamp(angle*.4,-38,38)
	return torso,math.clamp(angle*.8-torso,-48,48)
end
local function authoredLocomotion(char,actor,fighterId,dt)
	local F=tostring(fighterId)
	local s=stateOf(char)
	local root=char:FindFirstChild("HumanoidRootPart")
	local velocity=planar(actor.velocity)
	local speed=velocity.Magnitude
	local idle=Authored.sample(F..".Idle",elapsedTime) or {}
	local pose=idle
	if speed>.4 then
		local lv=if root then root.CFrame:VectorToObjectSpace(velocity) else Vector3.new(0,0,-speed)
		local fwd,side=-lv.Z/speed,lv.X/speed
		local dirW={F=math.max(0,fwd),B=math.max(0,-fwd),R=math.max(0,side),L=math.max(0,-side)}
		-- Walk below ~8 studs/s, run at the fighter's speed (~20), the ninja
		-- run when sprinting (forward only).
		local toRun=smooth((speed-6)/(15-6))
		local toSprint=smooth((speed-24)/(38-24))
		local list,stride,total={},0,0
		local function add(name,w)
			if w>1e-3 and Authored.has(name) then
				table.insert(list,{name,w});stride+=strideOf(name)*w;total+=w
			end
		end
		for _,d in LOCO_DIRS do
			local w=dirW[d]
			if w>0 then
				add(F..".Walk."..d,w*(1-toRun))
				add(F..".Run."..d,w*toRun*(if d=="F" and Authored.has(F..".Sprint") then 1-toSprint else 1))
			end
		end
		add(F..".Sprint",dirW.F*toRun*toSprint)
		stride=if total>0 then stride/total else 7
		s.locoPhase=((s.locoPhase or 0)+speed*(dt or 1/60)/math.max(stride,.5))%1
		local samples={}
		for _,e in list do
			table.insert(samples,{Authored.sample(e[1],s.locoPhase*Authored.length(e[1])),e[2]})
		end
		local moving=mixPoses(samples)
		if moving then
			-- Starting off and stopping: the stance hands over to the cycle over
			-- the first few studs per second.
			pose=mixPoses({{idle,1},{moving,smooth(speed/4)/math.max(1-smooth(speed/4),1e-3)}}) or moving
		end
	else
		s.locoPhase=0
	end
	-- (ANIM-001) Starting off and stopping are authored one-shots: the body
	-- falls into the first steps (Start) and catches itself on a planted heel
	-- (Brake) instead of the cycle simply speeding up or freezing.
	local now=elapsedTime
	s.locoTag=nil
	if speed<2 then s.stillAt=now end
	s.peakSpeed=math.max(speed,(s.peakSpeed or 0)-(dt or 1/60)*30)
	if speed>8 and s.stillAt and now-s.stillAt<.12 and not s.startAt and Authored.has(F..".Start") then s.startAt=now;s.brakeAt=nil end
	if speed<4 and (s.prevSpeed or 0)>=4 and (s.peakSpeed or 0)>13 and Authored.has(F..".Brake") then s.brakeAt=now;s.startAt=nil end
	s.prevSpeed=speed
	local oneShot=nil
	if s.startAt then
		local t=now-s.startAt
		local len=Authored.length(F..".Start")
		if t<len and speed>5 then
			local w=smooth((t/len-.55)/.45)
			oneShot=mixPoses({{Authored.sample(F..".Start",t),1-w},{pose,w}})
			s.locoTag="start"
		else s.startAt=nil end
	end
	if not oneShot and s.brakeAt then
		local t=now-s.brakeAt
		local len=Authored.length(F..".Brake")
		if t<len and speed<6 then
			oneShot=table.clone(Authored.sample(F..".Brake",t))
			s.locoTag="brake"
		else s.brakeAt=nil end
	end
	if oneShot then
		pose=oneShot
		pose.__feet=authoredFeet(char,pose,dt)
	end
	local trackTorso,trackHead=trackOf(root,actor)
	local feet=pose.__feet
	pose=table.clone(pose)
	pose.__feet=feet
	-- (ANIM-002) Momentum: the chest leans into acceleration and sits back to
	-- brake, the body banks into a turn (the cycles are drawn at constant speed).
	local accel=Vector3.zero
	if s.authLastVel and dt and dt>0 then accel=(velocity-s.authLastVel)/dt end
	s.authLastVel=velocity
	s.authAccel=(s.authAccel or Vector3.zero):Lerp(accel,math.min(1,(dt or 1/60)*9))
	if root then
		local a=root.CFrame:VectorToObjectSpace(s.authAccel)
		local forward=math.clamp(-a.Z*.05,-14,12)
		local bank=math.clamp(a.X*.03,-9,9)
		if math.abs(forward)>.2 or math.abs(bank)>.2 then
			pose.Waist=ANG(rad(-forward*.8),0,rad(-bank*.6))*(pose.Waist or IDENTITY)
			pose.Root=(pose.Root or IDENTITY)*ANG(rad(-forward*.25),0,rad(-bank*.5))
			pose.Neck=ANG(rad(forward*.35),0,0)*(pose.Neck or IDENTITY)
		end
	end
	if math.abs(trackTorso)>.5 then pose.Waist=(pose.Waist or IDENTITY)*ANG(0,rad(-trackTorso*.6),0) end
	if math.abs(trackHead)>.5 then pose.Neck=(pose.Neck or IDENTITY)*ANG(0,rad(-trackHead*.6),0) end
	return pose
end
local function locomotionTargets(char,actor,fighterId,dt,rest,mode)
	if not mode and not rest and hasAuthoredLoco(fighterId) then
		return authoredLocomotion(char,actor,fighterId,dt),RATE.authored
	end
	local s=stateOf(char)
	local minato=springy(fighterId)
	local root=char:FindFirstChild("HumanoidRootPart")
	local velocity=planar(actor.velocity)
	local speed=velocity.Magnitude
	local base=stance(fighterId)
	local gait=gaitOf(fighterId)
	s.gait=gait
	local rf,lf,bob,armSwing=stepFeet(char,s,rest or base,velocity,speed,dt,mode)
	-- Centre of gravity: the body leans into acceleration (forward to start,
	-- back to brake, into a turn), from the drawn body's real velocity.
	local accel=Vector3.zero
	if s.lastVel and dt and dt>0 then accel=(velocity-s.lastVel)/dt end
	s.lastVel=velocity
	s.accel=(s.accel or Vector3.zero):Lerp(accel,math.min(1,(dt or 1/60)*10))
	local accLocal=if root then root.CFrame:VectorToObjectSpace(s.accel) else Vector3.zero
	local accForward,accSide=math.clamp(-accLocal.Z*.045,-11,11),math.clamp(accLocal.X*.025,-6,6)
	-- Eyes on the opponent: when the body runs another way, the head and the
	-- chest keep tracking them (a three-quarter run, never a blind one).
	local trackTorso,trackHead=0,0
	if root and actor.lookAt then
		local to=actor.lookAt-root.Position
		local l=root.CFrame:VectorToObjectSpace(Vector3.new(to.X,0,to.Z))
		if l.Magnitude>1 then
			local angle=math.deg(math.atan2(l.X,-l.Z))
			trackTorso=math.clamp(angle*.4,-38,38)
			trackHead=math.clamp(angle*.8-trackTorso,-48,48)
		end
	end
	if speed<1.2 then
		local breath=math.sin(elapsedTime*(base.tempo or 6))
		local spec=merge(base,{root={y=base.root.y+breath*.03+bob,pitch=(base.root.pitch or 0)+accForward*.5,roll=(base.root.roll or 0)+accSide*.5},
			torso={pitch=base.torso.pitch+breath*(base.breath or 1),yaw=(base.torso.yaw or 0)+trackTorso*.5},head={yaw=(base.head.yaw or 0)+trackHead*.5}})
		spec.rf=rf;spec.lf=lf
		return build(spec),RATE.locomotion
	end
	local localMove=if root then root.CFrame:VectorToObjectSpace(velocity) else Vector3.new(0,0,-speed)
	local dir=Vector3.new(localMove.X,0,localMove.Z)
	dir=if dir.Magnitude>1e-3 then dir.Unit else Vector3.new(0,0,-1)
	local forward=-dir.Z -- +1 moving where the body faces
	local side=dir.X
	local sprint=speed>(if minato then 30 else 28) and not gait.holdArms
	local swing=armSwing
	local alpha=math.clamp(speed/30,0,1)
	local lean=if forward>-.3 then forward*(5+alpha*(if minato then 18 else 12)) else forward*10
	local spec
	if sprint and forward>.3 then
		-- The ninja run: chest low, arms swept back, legs driving. How far the
		-- body pitches and what the arms do is each fighter's (RUN, brief §3).
		local run=RUN[fighterId] or RUN.default
		spec={root={y=-.55+bob,pitch=(if minato then 22 else 16)*run.lean,yaw=swing*6},
			torso={pitch=(if minato then 24 else 18)*run.lean,yaw=-swing*9},head={pitch=-28*run.lean},
			ra={raise=-58+swing*6,out=14,twist=-10,elbow=12},la={raise=-58-swing*6,out=14,twist=-10,elbow=12}}
		if run.arms=="low" then
			-- Economical: loose arms low by the sides, a small swing.
			spec.ra={raise=-16-swing*14,out=8,elbow=34};spec.la={raise=-16+swing*14,out=8,elbow=34}
		elseif run.arms=="pump" then
			-- Heavy: bent arms pumping with the legs.
			spec.ra={raise=18-swing*42,out=12,elbow=92};spec.la={raise=18+swing*42,out=12,elbow=92}
		elseif run.arms=="glide" then
			-- Gliding: arms trailing wide and low, almost still.
			spec.ra={raise=-44+swing*4,out=42,elbow=8};spec.la={raise=-44-swing*4,out=42,elbow=8}
		end
	else
		local arm=gait.arm*math.clamp(speed/16,.3,1)
		spec={root={y=-.32+bob,pitch=lean,yaw=swing*6*alpha,roll=side*(if minato then 4 else 3)},
			torso={pitch=(if forward<-.3 then -6 else 4)+alpha*4,yaw=-swing*15*alpha,roll=-side*3},head={pitch=-lean*.4,yaw=swing*4*alpha},
			ra={raise=12-swing*arm,out=12,twist=10,elbow=40+alpha*40},la={raise=12+swing*arm,out=12,twist=10,elbow=40+alpha*40}}
		if not minato then spec.la.raise+=12;spec.la.elbow+=10 end
		-- Readable directions: a strafe leans into the step with the shoulders
		-- turned to the opponent; a retreat sits back behind a raised guard.
		local strafe=math.clamp(math.abs(side)-math.max(0,forward),0,1)
		if strafe>.2 then
			spec.root.roll=(spec.root.roll or 0)+side*4*strafe
			spec.torso.yaw=(spec.torso.yaw or 0)-side*14*strafe
			spec.head.yaw=-side*10*strafe
		end
		if forward<-.3 then
			local back=math.clamp(-forward,0,1)
			spec.root.pitch=-8*back;spec.torso.pitch=-6*back;spec.head.pitch=4*back
			spec.ra={raise=62,out=-16,twist=30,elbow=104,wrist=-10}
			spec.la={raise=70,out=-12,twist=30,elbow=96,wrist=-10}
		end
		if fighterId=="GentleFist" then
			local guard=1-math.clamp((speed-8)/16,0,1)
			spec.la={raise=spec.la.raise+(64-spec.la.raise)*guard,out=-4,twist=-30*guard,elbow=40+20*guard,wrist=-30*guard}
		end
	end
	-- Lean into acceleration, carry the guard, keep eyes on the opponent.
	spec.root.pitch=(spec.root.pitch or 0)+accForward+gait.lean*alpha
	spec.root.roll=(spec.root.roll or 0)+accSide
	spec.torso.yaw=(spec.torso.yaw or 0)+trackTorso
	spec.head.yaw=(spec.head.yaw or 0)+trackHead
	if gait.guard>0 and not (sprint and forward>.3) then
		local g=gait.guard*(1-math.clamp((speed-12)/20,0,.6))
		spec.ra.raise=spec.ra.raise+(58-spec.ra.raise)*g;spec.ra.elbow=spec.ra.elbow+(96-spec.ra.elbow)*g
		spec.la.raise=spec.la.raise+(66-spec.la.raise)*g;spec.la.elbow=spec.la.elbow+(80-spec.la.elbow)*g
	end
	if gait.holdArms then
		-- (Gaara) the arms stay folded whatever the legs do.
		spec.ra=table.clone(base.ra);spec.la=table.clone(base.la)
	end
	if gait.holdRear and not (sprint and forward>.3) then
		-- (Rock Lee) the rear hand stays behind his back while he moves in his
		-- stance; only a full sprint swings both arms.
		spec.ra=table.clone(base.ra)
	end
	spec.rf=rf;spec.lf=lf
	return build(spec),(if sprint then RATE.chase else RATE.locomotion)
end
-- ------------------------------------------------------------ acrobatics
-- Movement overhaul (docs/movement/MOVEMENT_OVERHAUL_AUDIT.md, reference
-- videos of 24/10): full-body rotations are part of the ninja's travel, not
-- decoration. The context picks them (takeoff direction and speed, a chained
-- launched jump, leaving a wall, a dodge) and each fighter's acrobatic level
-- decides who does them: below the threshold the same context keeps the
-- plain lean. Presentation only: the server trajectory is never touched.
local ACRO={Leaf=1,Lion=.85,Flicker=.85,Flashstep=.8,Legion=.8,Mirror=.7,Rival=.65,Bone=.6,Copycat=.55,Ink=.55,
	GentleFist=.5,Professor=.5,Serpent=.45,Sapling=.45,Clay=.4,Mirage=.35,Puppet=.2,Mist=.15,Rinnegan=.1,Sand=0}
-- Minimum level per trick: a back flip out of contact, a side flip on a side
-- jump, a front flip on a chained sprint jump, a flip off a wall, a cartwheel
-- or back handspring as a dodge.
local TRICK_AT={back=.5,side=.6,front=.7,wall=.4,dodge=.75}
local DODGE_TIME=.32
local function acroOf(id) return ACRO[id or ""] or .5 end
Motion.ACRO=ACRO
Motion.TRICK_AT=TRICK_AT
local function chooseTrick(char,actor,s,fromWall)
	local level=acroOf(actor.fighterId)
	local v=actor.velocity or Vector3.zero
	-- Only a real takeoff turns: walking off a ledge or being knocked up does not.
	if not fromWall and v.Y<12 then return nil end
	local air=2*math.max(v.Y,10)/math.max(workspace.Gravity,1)
	local dur=math.clamp(air*.72,.36,.62)
	if fromWall then
		if level<TRICK_AT.wall then return nil end
		return {axis="pitch",sign=-1,dur=math.clamp(air*.7,.36,.55),at=elapsedTime,kind="wall"}
	end
	local root=char:FindFirstChild("HumanoidRootPart")
	local flatV=planar(v)
	-- Studio (real keys): a sprint always faces its travel, so leaving contact
	-- backward is a locked backpedal (~14 studs/s) and a side jump a strafe
	-- (~17): the thresholds sit under those, above a standing hop's drift.
	if not root or flatV.Magnitude<9 then return nil end
	local lv=root.CFrame:VectorToObjectSpace(flatV.Unit)
	local forward,side=-lv.Z,lv.X
	if forward<-.55 and level>=TRICK_AT.back then return {axis="pitch",sign=-1,dur=dur,at=elapsedTime,kind="back"} end
	if math.abs(side)>.6 and flatV.Magnitude>=12 and level>=TRICK_AT.side then return {axis="roll",sign=if side>0 then 1 else -1,dur=dur,at=elapsedTime,kind="side"} end
	-- A front flip only on a launched jump chained off a landing, and never two
	-- in a row: leap, flip, leap... (most long jumps stay leaps, as in the references).
	if forward>.6 and flatV.Magnitude>=28 and level>=TRICK_AT.front and elapsedTime-(s.landedAt or -9)<.45 and not s.lastJumpFlipped then
		return {axis="pitch",sign=1,dur=dur,at=elapsedTime,kind="front"}
	end
	return nil
end
-- Called once per presented frame: notices takeoffs (from the ground or a
-- wall) and landings, and cancels a rotation the moment the body commits to
-- something else (a strike, a technique, a dodge, a chase, a hit).
local function trickStep(char,actor)
	local s=stateOf(char)
	local onWall=actor.wall==true
	local air=actor.airborne==true and not onWall and actor.reaction==nil and (actor.health or 1)>0
	if air and (not s.inAir or s.onWall) then
		s.trick=chooseTrick(char,actor,s,s.onWall==true)
		if not s.onWall then s.lastJumpFlipped=s.trick~=nil and s.trick.kind=="front" end
	elseif not air and s.inAir and not onWall then
		s.landedAt=elapsedTime
		if s.trick then s.trickEndAt=elapsedTime end
		s.trick=nil
	end
	s.inAir=air;s.onWall=onWall
	local tr=s.trick
	if tr then
		local committed=actor.attackName~=nil or actor.castId~=nil or actor.reaction~=nil
			or actor.state=="Dodging" or actor.state=="Pursuit" or actor.state=="Rush"
		if committed then s.trick=nil
		elseif elapsedTime-tr.at>=tr.dur then s.trick=nil;s.trickEndAt=elapsedTime end
	end
	return s.trick
end
Motion.trickOf=function(char) return stateOf(char).trick end
-- The rotation itself, about a pivot near the belly so the body turns around
-- its own centre; eased in and out, fastest at the top of the arc.
local function rotate(targets,axis,sign,p,lift)
	local e=smooth(p)
	local angle=rad(360*e)*sign
	local turn=if axis=="pitch" then ANG(-angle,0,0) else ANG(0,0,-angle)
	local pivot=CF(0,.35,0)
	local out=table.clone(targets)
	out.Root=CF(0,(lift or 0)*math.sin(math.pi*p),0)*pivot*turn*pivot:Inverse()*(targets.Root or IDENTITY)
	return out
end
-- (Blender-first) The authored jump: its time axis is the arc itself, read
-- from the body's vertical speed (take-off, rise, apex, fall, reach for the
-- floor); a running jump leans into the authored leap; a flip plays the
-- authored tuck while the body turns over.
local JUMP_V=58
local function authoredAir(char,actor,fighterId)
	local F=tostring(fighterId)
	local v=actor.velocity or Vector3.zero
	local u=math.clamp((JUMP_V-v.Y)/(2*JUMP_V),0,1)
	-- (ANIM-005) The arc axis follows the body's vertical speed, which the
	-- server can change at once (a pursuit ends, a hit lands, a wall kick):
	-- the pose then jumped across the arc in one frame. It moves at most a
	-- whole arc in 0.35 s; a fresh jump starts where its speed says.
	local st=stateOf(char)
	local now=elapsedTime
	if st.airU and now-(st.airAt or -1)<.2 then
		local step=math.max(now-st.airAt,0)/.35
		u=st.airU+math.clamp(u-st.airU,-step,step)
	end
	st.airU=u;st.airAt=now
	local air=Authored.sample(F..".Jump.Air",u*Authored.length(F..".Jump.Air"))
	local root=char:FindFirstChild("HumanoidRootPart")
	local flatV=planar(v)
	local localV=if root and flatV.Magnitude>1 then root.CFrame:VectorToObjectSpace(flatV).Unit else Vector3.zero
	local forward=-localV.Z
	local momentum=math.clamp((flatV.Magnitude-8)/22,0,1)
	local travel=momentum*math.max(0,forward)
	if st.airTravel and now-(st.airTravelAt or -1)<.2 then
		local step=math.max(now-st.airTravelAt,0)/.25
		travel=st.airTravel+math.clamp(travel-st.airTravel,-step,step)
	end
	st.airTravel=travel;st.airTravelAt=now
	if travel>.01 and Authored.has(F..".Jump.Leap") then
		air=mixPoses({{air,1},{Authored.sample(F..".Jump.Leap",u*Authored.length(F..".Jump.Leap")),travel/math.max(1-travel,1e-3)}})
	end
	local targets=table.clone(air)
	-- Sideways and backward jumps lean that way.
	local sideways=momentum*localV.X*(1-math.max(0,forward))
	local backward=momentum*math.max(0,-forward)
	if math.abs(sideways)>.05 or backward>.05 then
		targets.Root=(targets.Root or IDENTITY)*ANG(rad(12*backward),0,rad(-14*sideways))
	end
	local tr=stateOf(char).trick
	if tr and Authored.has(F..".Flip") then
		local p=math.clamp((elapsedTime-tr.at)/tr.dur,0,1)
		local tuck=table.clone(Authored.sample(F..".Flip",p*Authored.length(F..".Flip")))
		return rotate(tuck,tr.axis,tr.sign,p,.25),RATE.attack
	end
	return targets,RATE.authored
end
local function airTargets(char,actor,fighterId)
	if Authored and Authored.has(tostring(fighterId)..".Jump.Air") then return authoredAir(char,actor,fighterId) end
	local rise=(actor.velocity and actor.velocity.Y or 0)/70
	local minato=springy(fighterId)
	local spec
	if rise>.25 then
		-- Take-off: the lead knee drives up, the push-off leg trails, the arms
		-- answer the legs. The chest stays over the hips (no lean back).
		spec={root={pitch=2},torso={pitch=3},head={pitch=-6},ra={raise=-20,out=30,elbow=40},la={raise=60,out=24,elbow=70},
			rl={lift=74,knee=104,ankle=-14},ll={lift=-18,knee=40,ankle=-24}}
	elseif rise<-.3 then
		spec={root={pitch=4},torso={pitch=8},head={pitch=-4},ra={raise=34,out=44,elbow=34},la={raise=30,out=40,elbow=36},
			rl={lift=26,knee=42,ankle=-6},ll={lift=8,knee=30,ankle=-6}}
	else
		spec={root={pitch=8},torso={pitch=10},head={pitch=-8},ra={raise=48,out=22,elbow=96},la={raise=54,out=16,elbow=88},
			rl={lift=62,knee=100,ankle=-10},ll={lift=40,knee=84,ankle=-10}}
	end
	if not minato then spec.ra.out=(spec.ra.out or 0)*.6;spec.la.out=(spec.la.out or 0)*.6 end
	-- Momentum: a running or sprint jump travels. The chest leads, the arms
	-- sweep back like the ninja run and the legs stay split in a stride instead
	-- of a standing hop's tuck, so the arc reads as distance, not a bounce.
	local root=char:FindFirstChild("HumanoidRootPart")
	local flatV=planar(actor.velocity or Vector3.zero)
	local localV=if root and flatV.Magnitude>1 then root.CFrame:VectorToObjectSpace(flatV).Unit else Vector3.zero
	local forward=-localV.Z
	-- A plain running jump (run speed ~19) already leaps; a sprint jump fully.
	local momentum=math.clamp((flatV.Magnitude-8)/22,0,1)
	local travel=momentum*math.max(0,forward)
	-- Sideways and backward jumps read as such: lean into a side hop, sit
	-- back into a retreating jump with the guard up.
	local sideways=momentum*localV.X*(1-math.max(0,forward))
	local backward=momentum*math.max(0,-forward)
	if math.abs(sideways)>.05 then
		spec.root.roll=(spec.root.roll or 0)+14*sideways;spec.torso.roll=(spec.torso.roll or 0)-6*sideways
		spec.head.roll=(spec.head.roll or 0)-8*sideways
	end
	if backward>.05 then
		spec.root.pitch-=14*backward;spec.torso.pitch-=6*backward;spec.head.pitch+=8*backward
		spec.ra.raise+=(58-spec.ra.raise)*backward;spec.ra.elbow+=(100-spec.ra.elbow)*backward
		spec.la.raise+=(66-spec.la.raise)*backward;spec.la.elbow+=(86-spec.la.elbow)*backward
	end
	if travel>0 then
		spec.root.pitch+=18*travel;spec.torso.pitch+=10*travel;spec.head.pitch-=14*travel
		spec.ra.raise+=(-52-spec.ra.raise)*travel;spec.ra.elbow+=(16-spec.ra.elbow)*travel
		spec.la.raise+=(-52-spec.la.raise)*travel;spec.la.elbow+=(16-spec.la.elbow)*travel
		spec.rl.lift+=(68-spec.rl.lift)*travel;spec.rl.knee+=(70-spec.rl.knee)*travel
		spec.ll.lift+=(-36-spec.ll.lift)*travel;spec.ll.knee+=(28-spec.ll.knee)*travel
	end
	local tr=stateOf(char).trick
	if tr then
		-- A flip: the body gathers into a tuck at the top of the rotation (a
		-- side flip opens the arms instead), then opens again for the landing.
		local p=math.clamp((elapsedTime-tr.at)/tr.dur,0,1)
		local w=math.sin(math.pi*p)
		local function to(part,key,value) part[key]=(part[key] or 0)+(value-(part[key] or 0))*w end
		if tr.axis=="pitch" then
			to(spec.ra,"raise",64);to(spec.ra,"out",14);to(spec.ra,"elbow",104)
			to(spec.la,"raise",60);to(spec.la,"out",14);to(spec.la,"elbow",108)
			to(spec.rl,"lift",118);to(spec.rl,"knee",140);to(spec.ll,"lift",108);to(spec.ll,"knee",142)
		else
			to(spec.ra,"raise",10);to(spec.ra,"out",86);to(spec.ra,"elbow",12)
			to(spec.la,"raise",10);to(spec.la,"out",86);to(spec.la,"elbow",12)
			spec.rl.out=(spec.rl.out or 0)+30*w;spec.ll.out=(spec.ll.out or 0)+30*w
			to(spec.rl,"lift",40);to(spec.rl,"knee",50);to(spec.ll,"lift",20);to(spec.ll,"knee",40)
		end
		spec.root.pitch=spec.root.pitch*(1-w);spec.root.roll=(spec.root.roll or 0)*(1-w)
		return rotate(build(spec),tr.axis,tr.sign,p,.25),RATE.attack
	end
	return build(spec),RATE.air
end
-- Running up a wall with chakra: the body stands out from the surface, feet on
-- it, chest to the sky, legs cycling up the wall.
local function wallTargets(char,actor,dt)
 local s=stateOf(char)
 local speed=(actor.velocity or Vector3.zero).Magnitude
 local drive=math.clamp(speed/12,0,1)
 -- Distance-driven cadence: planted support at rest, alternating knee drive
 -- while climbing. The server's wall/root trajectory is never changed here.
 s.wallPhase=((s.wallPhase or 0)+math.min(dt or 1/60,.1)*math.clamp(speed/6,0,4))%1
 local swing=math.sin(s.wallPhase*math.pi*2)*drive
 return build({root={z=1.35,pitch=-78,y=-.05*math.abs(swing)},torso={pitch=10,yaw=-swing*4},head={pitch=40,yaw=swing*3},
  ra={raise=-38+swing*18,out=18,elbow=34-swing*12},la={raise=-38-swing*18,out=18,elbow=34+swing*12},
  rl={lift=32+swing*30,knee=52-swing*28,ankle=-10-swing*6},ll={lift=32-swing*30,knee=52+swing*28,ankle=-10+swing*6}}),RATE.wall
end
-- Running along a wall (movement overhaul, brief §9): upright, leaning into
-- the wall (wallSide +1 = the wall on the right), legs and arms in a running
-- cycle; not the climbing pose turned sideways.
local function wallRunTargets(char,actor,dt)
	local s=stateOf(char)
	s.wallPhase=((s.wallPhase or 0)+math.min(dt or 1/60,.1)*3.4)%1
	local swing=math.sin(s.wallPhase*math.pi*2)
	local side=actor.wallSide or 1
	return build({root={roll=side*26,pitch=10,y=-.15},torso={roll=side*6,pitch=6,yaw=-swing*6},head={roll=-side*14,pitch=-6},
		ra={raise=-30+swing*44,out=16,elbow=70},la={raise=-30-swing*44,out=16,elbow=70},
		rl={lift=40-swing*46,knee=60+swing*30,ankle=-10},ll={lift=40+swing*46,knee=60-swing*30,ankle=-10}}),RATE.wall
end
local function chaseTargets(char,actor,dt)
	local s=stateOf(char)
	s.phase=(s.phase+(dt or 1/60)*3)%1
	local swing=math.sin(s.phase*math.pi*2)
	local F=tostring(actor.fighterId)
	local dash=if Authored and Authored.has(F..".Chase") then Authored.sample(F..".Chase",s.phase*Authored.length(F..".Chase"))
		else build({root={pitch=52},torso={pitch=14},head={pitch=-48},ra={raise=-70,out=18,elbow=10},la={raise=-70,out=18,elbow=10},
		rl={lift=40+swing*30,knee=60-swing*20},ll={lift=-20-swing*20,knee=70+swing*10}})
	-- Chasing a launched body is a leap, not a dive along the floor: the body
	-- goes up vertical behind its own rising knee, arms pulling up, eyes on
	-- the target — the launcher's kick carries on into the jump after it.
	local v=actor.velocity or Vector3.zero
	local flat=Vector3.new(v.X,0,v.Z).Magnitude
	local rise=math.clamp((v.Y-flat*.4)/30,0,1)
	if rise<=.01 then return dash,RATE.chase end
	local leap=build({root={pitch=-4},torso={pitch=-12},head={pitch=-26},ra={raise=150,out=22,elbow=34},la={raise=70,out=30,elbow=86},
		rl={lift=100,knee=112,ankle=-18},ll={lift=-16,knee=22,ankle=-32}})
	return blend(dash,leap,rise),RATE.chase
end

-- ------------------------------------------------------------ reactions
-- Per body: where its last knockback flight left the legs (landing blend),
-- and the root height it stands at (how near the floor a flight is).
local LANDINGS={}
local function noteStand(actor)
	if actor and actor.id and not actor.airborne and actor.position then
		local l=LANDINGS[actor.id] or {};LANDINGS[actor.id]=l
		if not actor.reaction then l.standY=actor.position.Y end
	end
end
local reactionDuration={HitStun=.24,GuardStun=.42,Knockback=.36,Launched=.5,Juggled=.42,WallSplat=.42,Grabbed=.3}
-- The blow lands within two or three frames, then the body recovers: the
-- reaction peaks at once instead of easing in after the hit.
local function snapEnvelope(elapsed,hold)
	return math.clamp(elapsed/.035,0,1)*(1-smooth(math.clamp((elapsed-.035)/hold,0,1)))
end
-- (Blender-first) Authored reactions: where the fighter has them, the blow
-- picks its clip (face, body, side, back, legs; thrown back, launched,
-- knocked down, guard), mirrored for a blow from the other side.
local HIT_RATE=70
local function authoredReaction(actor)
	local F=tostring(actor.fighterId)
	if not (Authored and Authored.has(F..".Hit.Body")) then return nil end
	local kind=actor.reaction or "HitStun"
	local elapsed=actor.reactionElapsed or 0
	local function play(name,t,mirror)
		local full=F.."."..name
		if not Authored.has(full) then return nil end
		-- (ANIM-005) The other side is authored (".L"): the body takes the blow
		-- from the left without swapping its lead foot, which a mirror did.
		if mirror and Authored.has(full..".L") then return Authored.sample(full..".L",t) end
		local pose=Authored.sample(full,t)
		if mirror then pose=Authored.mirror(pose) end
		return pose
	end
	local angle=rad(actor.hitAngle or 0)
	local from,side=math.cos(angle),math.sin(angle)
	local twist=actor.hitTwist or 1
	if kind=="Launched" or kind=="Juggled" then
		-- (ANIM-005) The clip opens on the stance; a body already in the air
		-- (and every juggle hit) starts on the whip, the transition carries it.
		local p=play("Launched",elapsed+3/60,side<0);if p then return p,RATE.authored,"Launched" end
	elseif kind=="Knockdown" then
		local p=play("Knockdown",elapsed*Authored.length(F..".Knockdown")/.34,side<0);if p then return p,RATE.authored,"Knockdown" end
	elseif kind=="Knockback" then
		local land=LANDINGS[actor.id or ""] or {}
		LANDINGS[actor.id or ""]=land
		if actor.airborne then
			land.groundAt=nil
			local p=play("Knockback",elapsed+2/60,side<0);if p then return p,RATE.authored,"Knockback" end
		else
			land.groundAt=land.groundAt or elapsedTime
			-- The skid ends in his own stance: never mirrored (the lead foot stays).
			local p=play("Knockback.Land",elapsedTime-land.groundAt,false);if p then return p,RATE.authored,"Knockback.Land" end
		end
	elseif kind=="GuardStun" then
		local p=play("Guard.Impact",elapsed,false);if p then return p,RATE.authored,"Guard.Impact" end
	elseif kind=="HitStun" then
		local zone=actor.hitZone or "body"
		local hitKind=actor.hitKind or "strike"
		local dir=if math.abs(side)>.3 then (if side>0 then 1 else -1) else twist
		local name,mirror
		if hitKind=="kick" or hitKind=="slash" or math.abs(side)>.6 then name,mirror="Hit.Side",dir<0
		elseif from<-.4 then name,mirror="Hit.Back",twist<0
		elseif zone=="head" or zone=="chin" then name,mirror="Hit.Head",twist<0
		elseif zone=="legs" then name,mirror="Hit.Legs",twist<0
		else name,mirror="Hit.Body",twist<0 end
		local p=play(name,elapsed,mirror)
		if p then
			-- A light blow moves the body a little over half as far as a heavy one.
			local amp=math.clamp((actor.hitStrength or .4)*1.4,.35,1.4)
			local w=.55+.45*math.clamp((amp-.35)/1.05,0,1)
			if w<.999 then p=mixPoses({{play(name,0,mirror),1},{p,w/(1-w)}}) or p end
			-- (DEC-030) The shared clips are chosen by zone; the kind of blow
			-- still changes how it lands. A palm shoves the trunk back as one
			-- block (Neji's, Itachi's); a chakra point jolts: the shoulders
			-- hike and the head snaps (Gentle Fist).
			if hitKind=="palm" or hitKind=="tenketsu" then
				p=table.clone(p)
				local u=snapEnvelope(elapsed,.22)
				if hitKind=="palm" then
					p.Root=(p.Root or IDENTITY)*CF(0,0,.3*u)*ANG(rad(-9*u),0,0)
					p.Waist=(p.Waist or IDENTITY)*ANG(rad(-12*u),0,0)
					p.Neck=(p.Neck or IDENTITY)*ANG(rad(8*u),0,0)
				else
					p.Right=(p.Right or IDENTITY)*ANG(0,0,rad(20*u))
					p.Left=(p.Left or IDENTITY)*ANG(0,0,rad(-20*u))
					p.Neck=(p.Neck or IDENTITY)*ANG(rad(-14*u),0,0)
				end
			end
			return p,RATE.authored,name..(if mirror then ".L" else "")
		end
	end
	return nil
end
local function reactionTargets(actor,feet)
	local authoredPose,authoredRate,clip=authoredReaction(actor)
	if authoredPose then return authoredPose,authoredRate,clip end
	local kind=actor.reaction or "HitStun"
	local elapsed=actor.reactionElapsed or 0
	local t=1-smooth(math.clamp(elapsed/(reactionDuration[kind] or .24),0,1))
	local strong=math.clamp((actor.hitStrength or .4)*1.4,.35,1.4)
	local angle=rad(actor.hitAngle or 0)
	local from=math.cos(angle) -- +1: hit from the front
	local side=math.sin(angle) -- +1: hit from the fighter's right
	local behind=math.max(0,-from)
	local zone=actor.hitZone or "body"
	local hitKind=actor.hitKind or "strike"
	local twist=actor.hitTwist or 1
	if kind=="Launched" or kind=="Juggled" then
		-- A launcher hits the chin: the head snaps back and the body arches
		-- before it folds around the blow and is carried up, limbs trailing.
		local fold=smooth(math.clamp(elapsed/.2,0,1))
		local whip=if zone=="chin" or hitKind=="launch" then 1-smooth(math.clamp(elapsed/.16,0,1)) else 0
		return build({root={pitch=-18*fold-14*whip,roll=side*10*fold},torso={pitch=-26*fold-22*whip,yaw=side*16},head={pitch=-22*fold-34*whip},
			ra={raise=-40*fold+20*whip,out=40*fold,elbow=30},la={raise=-36*fold+16*whip,out=38*fold,elbow=26},
			rl={lift=34*fold,knee=60*fold},ll={lift=-6,knee=34*fold}}),RATE.recoil
	end
	if kind=="Bound" then
		-- Bound by wire or sand: arms pinned to the body, a stiff struggle.
		local struggle=math.sin(elapsed*26)*4
		return build({root={y=-.15,yaw=struggle*.5},torso={pitch=-4,roll=struggle*.6},head={pitch=-10,yaw=struggle},
			ra={raise=-4,out=-2,twist=-10,elbow=14},la={raise=-4,out=-2,twist=-10,elbow=14},
			rf={x=-.18,z=.05},lf={x=.18,z=-.05}}),RATE.defense
	end
	if kind=="Spiked" then
		-- Driven down: folded forward, arms trailing above, legs whipped behind.
		local drive=smooth(math.clamp(elapsed/.08,0,1))
		return build({root={pitch=48*drive},torso={pitch=30*drive},head={pitch=-26*drive},
			ra={raise=150*drive,out=30,elbow=30},la={raise=140*drive,out=34,elbow=26},
			rl={lift=-34*drive,knee=70*drive},ll={lift=-20*drive,knee=50*drive}}),RATE.recoil*1.2
	end
	if kind=="Knockdown" then
		-- Falling: the body turns toward the floor during the flight so the
		-- landing meets the lying pose. A sweep takes the legs first (they fly
		-- up, the back drops at once); a heavy blow spins the body as it goes.
		if hitKind=="sweep" then
			local fall=smooth(math.clamp(elapsed/.16,0,1))
			return build({root={y=-.5*fall,pitch=-72*fall,roll=side*8*fall},torso={pitch=-8*fall},head={pitch=20*fall},
				ra={raise=74*fall,out=50,elbow=36},la={raise=66*fall,out=54,elbow=30},
				rl={lift=66*fall,knee=26},ll={lift=44*fall,knee=46}}),RATE.recoil*1.3
		end
		local fall=smooth(math.clamp(elapsed/.34,0,1))
		local spin=if hitKind=="heavy" or hitKind=="kick" then twist*46*fall else 0
		return build({root={pitch=-58*fall-10*t,yaw=spin,roll=side*16*fall},torso={pitch=-16*fall,yaw=spin*.3},head={pitch=16*fall-18*t},
			ra={raise=50+30*t,out=58,elbow=34},la={raise=44+26*t,out=54,elbow=30},
			rl={lift=40*fall,knee=56*fall},ll={lift=18*fall,knee=40*fall}}),RATE.recoil
	end
	if kind=="Knockback" then
		-- Combat convergence (Studio strips): the body used to stay upright and
		-- slide back on planted feet (a pushed dummy). Now the blow takes it off
		-- its feet: the hips go first, the chest is thrown back almost flat while
		-- it flies, arms and legs trail toward the striker; near the ground the
		-- legs reach down for the skid and the chest comes back over them.
		local lift=smooth(math.clamp(elapsed/.1,0,1))
		local turn=if hitKind=="kick" then twist*34*lift else 0
		local vy=actor.velocity and actor.velocity.Y or 0
		-- (Continuity blocker: landing) The touchdown is a blend, not a switch:
		-- the airborne flag used to throw the body from the flying pose to the
		-- skid pose in one frame. From the pose the flight had reached, the
		-- legs take the floor over ~0.16 s and the hips compress on contact.
		local land=LANDINGS[actor.id or ""] or {}
		LANDINGS[actor.id or ""]=land
		local landing,compress
		local y=actor.position and actor.position.Y
		local quick=false
		if actor.airborne then
			-- The legs reach for the floor as it comes near (a low, flat flight
			-- falls slowly but still lands), not only when falling fast.
			local near=if y and land.standY then math.clamp(1-(y-land.standY)/2.5,0,1) else 0
			landing=math.max(math.clamp(-vy/30,0,1),near);land.v=landing;land.groundAt=nil;compress=0
		else
			if not land.groundAt then land.groundAt=elapsedTime;land.from=land.v or 0 end
			local k=smooth(math.clamp((elapsedTime-land.groundAt)/.16,0,1))
			landing=land.from+(1-land.from)*k
			quick=k<1
			compress=math.clamp((elapsedTime-land.groundAt)/.05,0,1)*(1-smooth(math.clamp((elapsedTime-land.groundAt-.05)/.22,0,1)))
		end
		local throw=lift*(1-.65*landing)
		-- On the floor a body still thrown back is low (its hips near the
		-- ground), not lying in the air at standing height.
		local low=if actor.airborne then 0 else 1.3*throw
		return build({root={y=-.3*landing-.45*compress-low,pitch=-(46*throw+10)*math.max(strong,.85),roll=side*16*lift,yaw=turn},
			torso={pitch=-22*throw-6*landing,yaw=side*20*lift+turn*.4},head={pitch=18*throw-10,yaw=-turn*.6},
			ra={raise=78*throw+30,out=50,elbow=30+30*landing},la={raise=70*throw+28,out=46,elbow=28+30*landing},
			rl={lift=48*throw+30*landing,knee=40+30*landing},ll={lift=20*throw+50*landing,knee=26+50*landing}}),RATE.recoil*(if quick then 2.6 else 1.2)
	end
	if kind=="GuardStun" then
		return build({root={y=-.55,z=.2*t,pitch=-6*t},torso={pitch=-12*t,roll=side*8*t},ra={raise=78,out=-26,twist=36,elbow=118},la={raise=78,out=-26,twist=36,elbow=118},
			lf={z=-.7},rf={z=.7}}),RATE.recoil
	end
	if kind=="Grabbed" then
		return build({root={y=-.3,pitch=10},torso={pitch=14},head={pitch=18},ra={raise=30,out=24,elbow=60},la={raise=30,out=24,elbow=60},rf={z=.3,toe=-30},lf={z=.2,toe=-30}}),RATE.defense
	end
	if kind=="WallSplat" then
		-- The back meets the wall: the body compresses (knees, chest folding in,
		-- head whipping back into the stone), then spreads flat against it.
		local splat=smooth(math.clamp((elapsed-.05)/.08,0,1))
		local crush=math.clamp(elapsed/.03,0,1)*(1-splat)
		return build({root={y=-.35*crush,pitch=-18*splat+10*crush},torso={pitch=-22*splat+20*crush},head={pitch=-20*splat-30*crush},
			ra={raise=30+30*crush,out=70*splat,elbow=40+40*crush},la={raise=30+30*crush,out=70*splat,elbow=40+40*crush},
			rl={lift=20+30*crush,knee=30+50*crush},ll={lift=10+24*crush,knee=26+40*crush}}),RATE.recoil*1.4
	end
	-- Standing hits answer where the blow landed. The head snaps away from a
	-- strike to the face, the body folds around one to the ribs, a low kick
	-- buckles the knee on its side; from behind the body arches instead.
	local snap=snapEnvelope(elapsed,reactionDuration[kind] or .24)
	-- Even a jab must read at game speed (a 5-damage hit was worth 9 degrees of
	-- fold): light blows get a floor, heavier ones still go further.
	-- (Combat convergence, Studio strips: at .62 a jab still read as a target
	-- dummy at normal speed; the whole body now answers, not only the head.)
	local s=math.max(strong,.95)
	local spec
	-- Which way the blow came from (+1: from the fighter's right).
	local dir=if math.abs(side)>.3 then (if side>0 then 1 else -1) else twist
	if hitKind=="palm" then
		-- A palm is a push, not a punch: the chest is driven straight back and
		-- the shoulders round over it, hips sent back, head jolted.
		spec={root={y=-.2*snap,z=.85*snap*math.max(from,.3),pitch=-6*snap},torso={pitch=14*snap*s,roll=-dir*6*snap},head={pitch=-14*snap,yaw=-dir*8*snap},
			ra={raise=30*snap,out=40*snap,elbow=30+30*snap},la={raise=26*snap,out=40*snap,elbow=30+30*snap}}
	elseif hitKind=="tenketsu" then
		-- Gentle Fist: a precise, small, stiff jolt rather than a recoil; the
		-- struck side goes slack (that arm drops out of the guard).
		local twitch=math.sin(elapsed*70)*(1-math.clamp(elapsed/.3,0,1))
		spec={root={y=-.12*snap,z=.25*snap,pitch=3*snap},torso={pitch=6*snap+2*twitch,roll=dir*4*snap},head={pitch=-6*snap,yaw=dir*6*snap+2*twitch},
			ra={raise=34*snap,out=10,elbow=70},la={raise=34*snap,out=10,elbow=70}}
		local slack={raise=-6,out=14,elbow=12}
		if dir>0 then spec.ra=slack else spec.la=slack end
	elseif hitKind=="kick" or hitKind=="slash" then
		-- From the side (roundhouse to the ribs, a kunai cut): the body bends
		-- away from the blow and turns with it instead of folding forward.
		spec={root={y=-.35*snap,z=.45*snap,roll=-dir*22*snap*s,yaw=-dir*28*snap},torso={roll=-dir*20*snap*s,yaw=-dir*30*snap,pitch=12*snap},head={roll=-dir*16*snap,yaw=-dir*28*snap},
			ra={raise=20*snap,out=62*snap,elbow=50},la={raise=18*snap,out=62*snap,elbow=48}}
	elseif zone=="head" then
		-- The face takes it: the head whips away and back, the whole upper body
		-- follows it back over the hips, the arms fly open.
		spec={root={y=-.25*snap,z=.6*snap*math.max(from,.4),pitch=-12*snap*s,yaw=twist*16*snap,roll=-twist*9*snap},torso={pitch=-20*snap*s,yaw=twist*24*snap,roll=-twist*10*snap},
			head={pitch=-34*snap*s,yaw=twist*52*snap,roll=twist*20*snap},
			-- (Recorded free fights: arms thrown forward put the struck body's
			-- hand inside the striker's head; they fly open to the sides instead.)
			ra={raise=-6*snap,out=72*snap,elbow=36},la={raise=-4*snap,out=68*snap,elbow=34}}
	elseif zone=="legs" then
		-- The base is taken: the hit knee buckles, the body drops toward it and
		-- the arms go out for balance.
		spec={root={y=-.85*snap,roll=twist*18*snap,pitch=10*snap},torso={pitch=14*snap,roll=-twist*14*snap},head={pitch=10*snap,yaw=twist*12*snap},
			ra={raise=52*snap,out=56*snap,elbow=40},la={raise=48*snap,out=56*snap,elbow=38}}
	else
		-- Support -> fold: the hips are driven back off the blow, the chest folds
		-- hard over it and twists away, the head follows the chest down, the
		-- arms come in around the struck body.
		local fold=(1-behind)*44*snap*s
		spec={root={y=-.5*snap*s,z=from*.85*snap,pitch=14*snap*s*(1-behind),yaw=twist*18*snap},torso={pitch=fold-behind*30*snap,yaw=twist*28*snap,roll=-side*12*snap},
			head={pitch=24*snap*(1-behind)-behind*30*snap,yaw=-side*16*snap},
			ra={raise=52*snap,out=-12*snap,elbow=100*snap+30},la={raise=46*snap,out=-10*snap,elbow=96*snap+30}}
	end
	spec.rf=feet and feet.rf or {z=.25};spec.lf=feet and feet.lf or {z=-.35}
	return build(spec),RATE.recoil*1.5
end
-- Lying on the floor after a knockdown, then a quick, readable get-up.
local function groundTargets(actor)
	local pose=actor.groundPose or (if actor.reaction=="WallSplat" then "Splat" else "Knockdown")
	local side=actor.groundSide or 1
	local F=tostring(actor.fighterId)
	if Authored and Authored.has(F..".Down") and pose~="Splat" then
		-- (Blender-first) lying on the floor, then the authored get-up, played
		-- over the server's wake-up window.
		local out
		local clip="Down"
		local fallLen=if Authored.has(F..".Knockdown") then Authored.length(F..".Knockdown") else 0
		local elapsed=actor.reactionElapsed or 0
		if pose=="Knockdown" and actor.reaction=="Knockdown" and fallLen>0 and (actor.airborne or elapsed<.34) then
			-- (ANIM-005) Thrown down: the authored fall plays (it ends lying,
			-- where Down starts); the body went to the lying pose at once.
			clip="Knockdown"
			out=Authored.sample(F..".Knockdown",math.min(fallLen,elapsed*fallLen/.34))
			if side<0 then out=Authored.mirror(out) end
		elseif (pose=="Wakeup" or actor.reaction=="Wakeup") and Authored.has(F..".Getup") then
			clip="Getup"
			-- (ANIM-005) Rolled onto the other side: its own get-up, which still
			-- ends in his stance (a mirrored get-up stood him up on the wrong lead).
			local name=if side<0 and Authored.has(F..".Getup.L") then F..".Getup.L" else F..".Getup"
			out=Authored.sample(name,(actor.reactionElapsed or 0)*Authored.length(name)/.24)
			if side<0 and name==F..".Getup" then out=Authored.mirror(out) end
		else
			out=Authored.sample(F..".Down",elapsedTime)
			if side<0 then out=Authored.mirror(out) end
		end
		return out,RATE.authored,clip
	end
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
	local F=tostring(fighterId)
	if Authored and Authored.has(F..".Guard") then
		-- (Blender-first) the authored guard; a blow on it plays the impact
		-- over the server's .18 s window.
		if (impact or 0)>0 and Authored.has(F..".Guard.Impact") then
			return Authored.sample(F..".Guard.Impact",(.18-impact)*2),HIT_RATE
		end
		return Authored.sample(F..".Guard",elapsedTime),RATE.authored
	end
	local absorbed=math.clamp((impact or 0)/.18,0,1)
	local base=stance(fighterId)
	-- A fighter may guard with what it carries (Motion.guard: Zabuza's blade
	-- held flat across); otherwise crossed forearms, weight down, braced.
	local own=familyOf(fighterId).guard
	if own then
		return build(merge(merge(base,own),{root={pitch=(own.root and own.root.pitch or 6)-6*absorbed,z=.2*absorbed}})),RATE.guard
	end
	return build(merge(base,{root={y=-.6,pitch=8-6*absorbed,z=.2*absorbed},torso={pitch=10-10*absorbed,yaw=-4},head={pitch=10},
		ra={raise=92,out=-34,twist=42,elbow=112,wrist=-10},la={raise=96,out=-30,twist=40,elbow=108,wrist=-10}})),RATE.guard
end
-- A dash is pushed off a leg: for its first few frames the body drops and
-- the pushing leg drives against the ground, then the glide takes over.
local DASH_PUSH=.08
local function dodgeTargets(char,actor,t)
	local root=char:FindFirstChild("HumanoidRootPart")
	local direction=planar(actor.velocity)
	local localMotion=if root and direction.Magnitude>.1 then root.CFrame:VectorToObjectSpace(direction) else Vector3.new(1,0,0)
	local forward=math.clamp(-localMotion.Z/14,-1,1)
	local side=math.clamp(localMotion.X/14,-1,1)
	local push=1-smooth(math.clamp((t or 1)/DASH_PUSH,0,1))
	-- The most acrobatic bodies turn a side dodge into a cartwheel and a back
	-- dodge into a back handspring (hands toward the floor, legs over); the
	-- others keep the low slide. Forward stays a low slip off the line.
	local F=tostring(actor.fighterId)
	if Authored and Authored.has(F..".Dash.F") then
		-- (Blender-first) authored dodges: the forward dash, and the shape of
		-- the body through the cartwheel or the back handspring the engine turns.
		local p=math.clamp((t or 0)/DODGE_TIME,0,1)
		local sideways=math.abs(side)>math.abs(forward)*.8
		if acroOf(actor.fighterId)>=TRICK_AT.dodge and sideways and Authored.has(F..".Cartwheel") then
			return rotate(Authored.sample(F..".Cartwheel",p*Authored.length(F..".Cartwheel")),"roll",if side<0 then -1 else 1,p,.4),RATE.attack
		elseif acroOf(actor.fighterId)>=TRICK_AT.dodge and forward<-.3 and Authored.has(F..".Handspring") then
			return rotate(Authored.sample(F..".Handspring",p*Authored.length(F..".Handspring")),"pitch",-1,p,.4),RATE.attack
		elseif not sideways and forward>=0 then
			return Authored.sample(F..".Dash.F",p*Authored.length(F..".Dash.F")),RATE.authored
		end
	end
	if acroOf(actor.fighterId)>=TRICK_AT.dodge and (math.abs(side)>math.abs(forward)*.8 or forward<-.3) then
		local p=math.clamp((t or 0)/DODGE_TIME,0,1)
		local w=math.sin(math.pi*p)
		if math.abs(side)>math.abs(forward)*.8 then
			local s=if side<0 then -1 else 1
			local spec={root={y=-.4},torso={},head={},ra={raise=170*w,out=40,elbow=10},la={raise=170*w,out=40,elbow=10},
				rl={lift=10,out=40+40*w,knee=10},ll={lift=10,out=40+40*w,knee=10}}
			return rotate(build(spec),"roll",s,p,.4),RATE.attack
		end
		local spec={root={y=-.5},torso={pitch=-10*w},head={pitch=20*w},ra={raise=150+20*w,out=24,elbow=10},la={raise=150+20*w,out=24,elbow=10},
			rl={lift=40*w,knee=30},ll={lift=60*w,knee=50}}
		return rotate(build(spec),"pitch",-1,p,.4),RATE.attack
	end
	local glide,load
	if math.abs(side)>math.abs(forward)*.8 then
		local s=if side<0 then -1 else 1
		glide={root={y=-.9,roll=s*26,pitch=10},torso={roll=s*12},head={roll=-s*10},ra={raise=50,out=40,elbow=60},la={raise=50,out=40,elbow=60},
			rf={x=s*.6,z=.1},lf={x=s*.6,z=-.1}}
		-- The far leg pushes: it is extended away from the dash.
		load={root={y=-1.2,roll=-s*8,pitch=8},torso={roll=-s*6},ra={raise=40,out=30,elbow=70},la={raise=40,out=30,elbow=70},
			rf=if s>0 then {x=.2,z=0} else {x=-.9,z=0,toe=-25},lf=if s>0 then {x=.9,z=0,toe=-25} else {x=-.2,z=0}}
	elseif forward>=0 then
		glide={root={y=-1.0,pitch=38},torso={pitch=10},head={pitch=-30},ra={raise=-40,out=20,elbow=20},la={raise=-40,out=20,elbow=20},
			lf={z=-1.2},rf={z=1.2,y=.2,toe=-20}}
		load={root={y=-1.2,pitch=22},torso={pitch=14},head={pitch=-18},ra={raise=20,out=24,elbow=60},la={raise=30,out=24,elbow=70},lf={z=-.5},rf={z=1.5,toe=-30}}
	else
		glide={root={y=-.8,pitch=-14,z=.3},torso={pitch=-10},head={pitch=6},ra={raise=70,out=20,elbow=70},la={raise=70,out=20,elbow=70},
			lf={z=-.4},rf={z=1.1}}
		load={root={y=-1.1,pitch=-4},torso={pitch=0},ra={raise=70,out=20,elbow=80},la={raise=70,out=20,elbow=80},lf={z=-1.3,toe=-25},rf={z=.3}}
	end
	if push<=0 then return build(glide),RATE.defense end
	return blend(build(glide),build(load),push),RATE.defense*1.4
end
local function landTargets(fighterId,strength,ninja)
	local base=stance(fighterId)
	local absorb=math.clamp(strength,0,1)
	if ninja then
		return build(merge(base,{root={y=base.root.y-1.05*absorb,pitch=base.root.pitch+22*absorb},torso={pitch=base.torso.pitch+16*absorb},head={pitch=-14*absorb},
			ra={raise=34,out=72*absorb+(base.ra.out or 0)*(1-absorb),elbow=18,twist=0},la={raise=30,out=70*absorb+(base.la.out or 0)*(1-absorb),elbow=20,twist=0},
			rf={x=(base.rf and base.rf.x or 0)+.35*absorb},lf={x=(base.lf and base.lf.x or 0)-.35*absorb}})),RATE.defense
	end
	return build(merge(base,{root={y=base.root.y-.75*absorb,pitch=base.root.pitch+14*absorb},torso={pitch=base.torso.pitch+12*absorb},
		ra={raise=base.ra.raise-10*absorb,out=base.ra.out+18*absorb},la={raise=base.la.raise-10*absorb,out=base.la.out+18*absorb}})),RATE.defense
end

-- --------------------------------------------------------------- weapons
-- Minato keeps a reverse-grip kunai for his cutting strings, a forward-grip
-- kunai for throws and his marked three-pronged kunai for the seal throw.
-- Itachi holds shuriken flat between the fingers of his left hand.
local weapons=setmetatable({},{__mode="k"})
-- Sasuke's kunai string (ANIM-005): forward grip, blade out of the thumb
-- side 50 deg off the arm (tools/blender/kunai_lion.py KUNAI_POS/KUNAI_DIR:
-- the same weld the Blender file is animated with).
local LION_KUNAI_C0=CF(0,-.12,-.12)*ANG(math.rad(-50.3),0,0)
local MELEE={Lion={Light1=true,Light2=true,Light3=true,Heavy=true,KneeStrike=true,LionKick=true,Sweep=true,VaultKick=true,FlyingKick=true,
	Air1=true,Air2=true,AirDrive=true,AirSpike=true,AirSwitch=true,Launcher=true,DashAttack=true},Flashstep={Light1=true,Light2=true,DashAttack=true,Air1=true,AngleStep=true,Riposte=true,AirSwitch=true},Mirage={Light2=true,Light1=true,DashAttack=true,Air1=true,Air2=true,Light3=true}}
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
	local kind=familyOf(fighterId).weapons
	local minato=kind=="kunai"
	local palms=kind=="palms"
	-- Global kunai (DEC-030): every fighter carries a blade he may draw, held
	-- in the forward grip the shared Kunai.* clips are animated with.
	local right=char:FindFirstChild("RightHand")
	if right then pcall(function() Effects=Effects or require(script.Parent.Effects);items.drawn=makeItem(right,Effects.buildKunai(false),LION_KUNAI_C0) end) end
	if kind=="none" then for _,item in items do setVisible(item,false) end return items end
	local hand=char:FindFirstChild(if kind=="shuriken" then "LeftHand" else "RightHand")
	if not hand then weapons[char]=nil;return nil end
	local ok=pcall(function()
		Effects=Effects or require(script.Parent.Effects)
		if palms then
			items.throw=makeItem(hand,Effects.buildKunai(false),CF(0,-.16,-.08)*ANG(math.rad(10),0,0))
		elseif minato then
			-- Reverse grip: blade out of the little-finger side, along the forearm.
			items.melee=makeItem(hand,Effects.buildKunai(false),CF(0,-.14,.12)*ANG(math.rad(-12),math.pi,0))
			items.throw=makeItem(hand,Effects.buildKunai(false),CF(0,-.16,-.08)*ANG(math.rad(10),0,0))
			items.marked=makeItem(hand,Effects.buildKunai(true),CF(0,-.16,-.08)*ANG(math.rad(10),0,0))
		else
			items.shuriken=makeItem(hand,Effects.buildShuriken(),CF(0,-.34,-.08)*ANG(0,0,math.pi/2))
			if kind=="wire" then items.melee=makeItem(hand,Effects.buildKunai(false),LION_KUNAI_C0) end
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
	local kind=familyOf(actor.fighterId).weapons
	local minato=kind=="kunai"
	local name=actor.attackName
	local spec=name and Attacks[name]
	local swinging=name~=nil and actor.state~="Neutral" and actor.state~="Guarding"
	-- (Sasuke keeps the kunai out through the whole recovery: the string flows on.)
	local keep=if kind=="wire" then .95 else .45
	local release=if spec then (function() local s,a,r=timing(name,actor.fighterId);return s+a+r*keep end)() else .35
	local meleeOut=(swinging and (MELEE[actor.fighterId] or MELEE[familyOf(actor.fighterId).body] or {})[name]==true and (actor.attackElapsed or 0)<=release
		and actor.attackVariant~="Rasengan") or (minato and (actor.intro or 0)>0)
	-- Thrown weapons sit in the hand from the wind-up until their release frame.
	local throwKind=actor.throwKind
	local throwElapsed=actor.throwElapsed or 99
	local releaseAt=actor.throwRelease or .1
	local holding=throwKind~=nil and throwElapsed>=0 and throwElapsed<releaseAt
	if throwKind=="Shuriken" and throwElapsed>=releaseAt and throwElapsed<releaseAt+.08 then holding=throwElapsed>=releaseAt+.03 end
	local castFan=actor.castId=="NeedleFan" and actor.state=="TechniqueChannel"
	-- The drawn blade stays in the hand until thrown (the throw shows it to its
	-- release frame where the fighter has no throwing kunai of his own).
	local drawn=actor.armed==true or (holding and throwKind=="Kunai" and not items.throw and kind~="kunai")
	setVisible(items.drawn,drawn)
	if actor.armed then meleeOut=false end
	if kind=="none" then
		-- (no hand weapon: the sand does the work)
	elseif kind=="palms" then
		setVisible(items.throw,holding and throwKind=="Kunai")
	elseif minato then
		setVisible(items.melee,meleeOut and not holding)
		setVisible(items.throw,holding and throwKind=="Kunai")
		setVisible(items.marked,holding and throwKind=="MarkedKunai")
	elseif kind=="wire" then
		setVisible(items.shuriken,(holding and throwKind=="Shuriken") or (actor.castId=="WireTrap" and actor.state=="TechniqueChannel"))
		if items.melee then setVisible(items.melee,meleeOut and not holding) end
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
	if not Attacks[name] and not VARIANT_OF[name] then return end
	local targets,weight=attackTargets(name,elapsed,fighterId)
	apply(char,blend({},targets,weight),RATE.attack,dt)
end
function Motion.locomotion(char,speed,airborne,velocity,fighterId,dt,actor,now)
	noteStand(actor)
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
		local s=stateOf(char)
		if s.lastDefenseState~="Dodging" then s.dashAt=elapsedTime end
		targets,rate=dodgeTargets(char,actor,elapsedTime-(s.dashAt or elapsedTime))
	elseif actor.groundPose or actor.reaction=="Knockdown" or actor.reaction=="Wakeup" then
		local clip
		targets,rate,clip=groundTargets(actor)
		-- Fall, down, get-up: each its own (inertialized) transition.
		mark(char,"ground:"..tostring(clip or actor.groundPose or actor.reaction),if clip=="Knockdown" then .07 else .1)
	elseif actor.reaction then
		-- Standing hit: the feet stay planted and stagger-step as the body is
		-- pushed, instead of sliding with it.
		local feet=nil
		if not actor.airborne then
			local velocity=planar(actor.velocity)
			local rf,lf=stepFeet(char,stateOf(char),stance(actor.fighterId),velocity,velocity.Magnitude,dt,"react")
			feet={rf=rf,lf=lf}
		end
		local clip
		targets,rate,clip=reactionTargets(actor,feet)
		if clip then
			-- (ANIM-005) An authored reaction: each blow is its own transition
			-- (a new hit restarts the clip: inertialized over 30 ms, the blow
			-- lands at once), and on the ground its planted feet hold the floor
			-- while the server slides the body; the other foot steps to catch it.
			local s=stateOf(char)
			local elapsed=actor.reactionElapsed or 0
			if s.reactClip~=clip or elapsed+1e-3<(s.reactElapsed or 0) then s.reactSerial=(s.reactSerial or 0)+1 end
			s.reactClip=clip;s.reactElapsed=elapsed
			if not actor.airborne then targets.__feet=authoredFeet(char,targets,dt) end
			-- (a body set down after a flight takes a little longer to land)
			mark(char,"react:"..clip..":"..s.reactSerial,if clip=="Knockback.Land" then .1 else .05)
		end
	else
		return
	end
	stateOf(char).lastDefenseState=actor.state
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
-- Closed chakra points weigh on the body (Neji's tenketsu, on any fighter):
-- the spine folds a little more per point and the guard hands sag; a sealed
-- network (four points) bends the knees, the arms hang and the head trembles.
local function tenketsuPosture(targets,points,severe)
	local out=table.clone(targets)
	local sealed=points>=4 or severe==true
	local spine=if sealed then 10 elseif points>=3 then 6 else 3
	local sag=if sealed then 20 elseif points>=3 then 15 else 8
	out.Waist=(targets.Waist or IDENTITY)*ANG(rad(-spine),0,0)
	out.Right=ANG(rad(-sag*.7),0,0)*(targets.Right or IDENTITY)
	out.Left=ANG(rad(-sag),0,0)*(targets.Left or IDENTITY)
	if sealed then
		out.Root=CF(0,-.15,0)*(targets.Root or IDENTITY)
		out.Neck=(targets.Neck or IDENTITY)*ANG(0,rad(math.sin(elapsedTime*44)*4),0)
	end
	return out
end
-- Curse Mark (Sasuke awakened): a lower, hunched, hungrier guard; the
-- shoulders twitch while the seal is starving.
local function cursePosture(targets,hungry)
	local out=table.clone(targets)
	out.Root=CF(0,-.1,0)*(targets.Root or IDENTITY)*ANG(rad(-6),0,0)
	if hungry then out.Waist=(targets.Waist or IDENTITY)*ANG(0,0,rad(math.sin(elapsedTime*56)*3)) end
	return out
end
-- The end of a chakra dash: the body brakes low, leaning back, arms out for
-- balance, instead of popping straight back into the walk.
local function brakePosture(targets,w)
	local out=table.clone(targets)
	out.Root=CF(0,-.45*w,0)*(targets.Root or IDENTITY)*ANG(rad(8*w),0,0)
	out.Right=ANG(rad(18*w),0,rad(26*w))*(targets.Right or IDENTITY)
	out.Left=ANG(rad(18*w),0,rad(-26*w))*(targets.Left or IDENTITY)
	return out
end
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
	local memo=stateOf(char)
	-- Studio: the dodge clock only restarted when the last *defense* state
	-- differed, and nothing cleared it between dodges, so every dodge after the
	-- first ran on the first one's clock (its push and its cartwheel already
	-- over: the body stood upright through the dash). Out of defense, forget it.
	if subject.state~="Dodging" and not subject.reaction then memo.lastDefenseState=nil end
	trickStep(char,subject)
	if subject.state~=memo.lastState then
		if memo.lastState=="Rush" and subject.state=="Recovery" and not subject.attackName then memo.brakeAt=elapsedTime end
		memo.lastState=subject.state
	end
	-- A Read that bit: the eye slips aside (events count, so every slip shows).
	local slips=subject.events and subject.events.ReadSlip or 0
	if slips>(memo.slips or slips) then memo.slipAt=elapsedTime end
	memo.slips=slips
	-- Global kunai (DEC-030): a drawn blade is held in guard by the right arm
	-- over whatever the body does (run, jump, guard), except while it strikes,
	-- casts, throws or takes a blow; the draw itself is a short authored gesture.
	local draws=subject.events and subject.events.Draw or 0
	if draws>(memo.draws or draws) then memo.drawAt=elapsedTime end
	memo.draws=draws
	local busy=subject.victory==true or subject.reaction~=nil or (subject.attackName~=nil and (subject.state=="Startup" or subject.state=="Active" or subject.state=="Recovery"))
		or (subject.castId~=nil and string.sub(subject.state or "",1,9)=="Technique") or (subject.throwElapsed or 99)<.3
	local wantArm=if subject.armed and not busy then 1 else 0
	memo.armW=(memo.armW or 0)+(wantArm-(memo.armW or 0))*math.min(1,(dt or 1/60)*16)
	memo.armOverlay=nil
	if Authored and memo.drawAt and subject.armed and not busy and Authored.has("Kunai.Draw") and elapsedTime-memo.drawAt<Authored.length("Kunai.Draw") then
		memo.armOverlay={pose=Authored.sample("Kunai.Draw",elapsedTime-memo.drawAt),w=1}
	elseif Authored and memo.armW>.01 and Authored.has("Kunai.Idle") then
		memo.armOverlay={pose=Authored.sample("Kunai.Idle",elapsedTime),w=memo.armW}
	end
	-- (Partie 1) Authored one-shots: the match intro and the awakening entry.
	local F=tostring(subject.fighterId)
	local wakes=subject.events and subject.events.Awaken or 0
	if wakes>(memo.wakes or wakes) then memo.awakenAt=elapsedTime end
	memo.wakes=wakes
	if (subject.intro or 0)<=0 then memo.introAt=nil end
	-- (Partie 2) Victory: the winner's authored pose once the finishing blow
	-- is through, held on its last frame (Storm 4 / Tekken win poses).
	local finishing=subject.attackName~=nil and (subject.state=="Startup" or subject.state=="Active")
	if subject.victory and Authored and Authored.has(F..".Win") and not subject.reaction and not finishing then
		memo.winAt=memo.winAt or elapsedTime
		local targets=table.clone(Authored.sample(F..".Win",math.min(elapsedTime-memo.winAt,Authored.length(F..".Win"))))
		targets.__feet=authoredFeet(char,targets,dt)
		mark(char,"win",.18)
		apply(char,targets,RATE.authored,dt)
		return "win"
	end
	if not subject.victory then memo.winAt=nil end
	if Authored and memo.awakenAt and Authored.has(F..".Awaken") and not subject.reaction and not subject.attackName then
		local t=elapsedTime-memo.awakenAt
		if t<Authored.length(F..".Awaken") then
			local targets=table.clone(Authored.sample(F..".Awaken",t))
			targets.__feet=authoredFeet(char,targets,dt)
			mark(char,"awaken",.08)
			apply(char,targets,RATE.authored,dt)
			return "awaken"
		end
		memo.awakenAt=nil
	end
	if Authored and (subject.intro or 0)>0 and subject.state=="Neutral" and Authored.has(F..".Intro") then
		memo.introAt=memo.introAt or elapsedTime
		local targets=table.clone(Authored.sample(F..".Intro",elapsedTime-memo.introAt))
		targets.__feet=authoredFeet(char,targets,dt)
		mark(char,"intro",.1)
		apply(char,targets,RATE.authored,dt)
		return "intro"
	end
	-- Match intro attitude: Minato twirls a kunai, Itachi waits, perfectly still.
	if (subject.intro or 0)>0 and subject.state=="Neutral" then
		local base=stance(subject.fighterId)
		local spec
		-- A family may name its own intro (Rock Lee's), else its body's.
		local body=familyOf(subject.fighterId).intro or familyOf(subject.fighterId).body
		if INTRO[body] then
			spec=INTRO[body](base)
		elseif body=="Leaf" then
			-- Rock Lee: fired up. Upright on springy knees, the fist clenched at
			-- shoulder height, chin up; the other hand already behind his back.
			spec=merge(base,{root={y=-.2,pitch=-2,yaw=20},torso={pitch=-6,yaw=-8},head={pitch=-10,yaw=-14},
				la={raise=70,out=30,twist=-60,elbow=128,wrist=0},rf={x=.2,z=.5},lf={x=-.1,z=-.5}})
		elseif body=="Legion" then
			-- Naruto: a grin and a thumb up at the opponent, the other fist on his hip.
			spec=merge(base,{root={y=-.12,pitch=-2,yaw=14},torso={pitch=-6,yaw=-6},head={pitch=-8,yaw=-10},
				ra={raise=96,out=10,twist=-20,elbow=40,wrist=0},la={raise=-10,out=40,twist=-40,elbow=100,wrist=0},rf={x=.2,z=.4},lf={x=-.1,z=-.4}})
		elseif body=="Sand" then
			-- Arms folded, chin down, perfectly still: the sand will do it.
			spec=merge(base,{root={y=-.04,pitch=-1},head={pitch=10,yaw=0},torso={pitch=-2}})
		elseif body=="Mirage" then
			spec=merge(base,{root={y=-.1,pitch=0,yaw=8},torso={pitch=-2,yaw=-4},head={pitch=-4,yaw=-6},ra={raise=6,out=6,elbow=14},la={raise=6,out=6,elbow=14}})
		elseif body=="Lion" then
			-- Hands in the pockets, chin up: unimpressed until the fight starts.
			spec=merge(base,{root={y=-.08,pitch=-2,yaw=10},torso={pitch=-4,yaw=-6},head={pitch=-8,yaw=-10},ra={raise=-6,out=14,twist=-30,elbow=60,wrist=0},la={raise=-6,out=14,twist=-30,elbow=60,wrist=0},rf={x=.1,z=.2},lf={x=-.1,z=-.2}})
		elseif body=="GentleFist" then
			-- Byakugan: two fingers raised to the eyes, then the stance.
			spec=merge(base,{root={y=-.4,yaw=30},head={pitch=0,yaw=-18},ra={raise=128,out=-30,twist=20,elbow=146,wrist=0},la={raise=40,out=10,elbow=40}})
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
	-- Combat convergence (Studio timelines): inside a string the server lets a
	-- hit-stun lapse for a frame or two before the next blow lands, and the
	-- body flashed back toward its stance between two reactions. A standing
	-- reaction now keeps its tail for a few frames when nothing else takes over.
	if subject.reaction=="HitStun" or subject.reaction=="GuardStun" then
		memo.reactionTail={reaction=subject.reaction,hitAngle=subject.hitAngle,hitZone=subject.hitZone,hitKind=subject.hitKind,
			hitTwist=subject.hitTwist,hitStrength=subject.hitStrength,elapsed=subject.reactionElapsed or 0,at=elapsedTime}
	elseif not subject.reaction and memo.reactionTail and subject.state=="Neutral" and not subject.attackName and not subject.airborne
		and elapsedTime-memo.reactionTail.at<.09 and (subject.speed or 0)<8 then
		local tail=memo.reactionTail
		local held=table.clone(subject)
		held.reaction=tail.reaction;held.hitAngle=tail.hitAngle;held.hitZone=tail.hitZone;held.hitKind=tail.hitKind
		held.hitTwist=tail.hitTwist;held.hitStrength=tail.hitStrength
		held.reactionElapsed=tail.elapsed+(elapsedTime-tail.at)
		Motion.defense(char,held,dt)
		return "defense"
	else
		memo.reactionTail=nil
	end
	if subject.state=="Dodging" or subject.reaction then
		Motion.defense(char,subject,dt)
		return "defense"
	end
	if subject.state=="Pursuit" or subject.state=="Rush" then
		local targets,rate=chaseTargets(char,subject,dt)
		apply(char,targets,rate,dt)
		return "chase"
	end
	if subject.wall then
		local targets,rate=if subject.wallMode=="run" then wallRunTargets(char,subject,dt) else wallTargets(char,subject,dt)
		apply(char,targets,rate,dt)
		return "wall"
	end
	if subject.state=="Guarding" then
		local targets,rate=guardTargets(subject.fighterId,subject.guardImpact)
		apply(char,targets,rate,dt)
		return "guard"
	end
	local cue=if type(subject.cue)=="string" then subject.cue else ""
	local seeking=string.find(cue,"EXPOSED",1,true)~=nil
	if subject.state=="Stunned" and not subject.reaction and not subject.airborne and (seeking or string.find(cue,"BROKEN",1,true)~=nil) then
		-- Exposed (a swing caught by an image, read or parried) or a broken
		-- shield: overextended into nothing, the head turning to find the body.
		apply(char,build(merge(stance(subject.fighterId),{root={y=-.5,z=-.3,pitch=12},torso={pitch=14,yaw=-8},head={pitch=-6,yaw=if seeking then 30 else 8},
			ra={raise=92,out=-6,twist=10,elbow=10,wrist=-10},la={raise=20,out=26,elbow=40},lf={z=-1.1},rf={z=.9}})),RATE.recoil,dt)
		return "exposed"
	end
	local swinging=subject.attackName~=nil and (subject.state=="Startup" or subject.state=="Active" or subject.state=="Recovery")
	local casting=subject.castId~=nil and (subject.state=="TechniqueChannel" or subject.state=="TechniqueActive" or subject.state=="TechniqueRecovery")
	-- The base the body returns to: gait on the ground, air pose in the air.
	local base,baseRate
	local attackName=clipName(subject)
	local footwork=swinging and not subject.airborne and attackFeet(attackName,subject.attackElapsed or 0,subject.fighterId,kunaiClip(subject,attackName)) or nil
	if subject.airborne then base,baseRate=airTargets(char,subject,subject.fighterId)
	elseif footwork then
		-- Attack footwork: the clip says where each foot goes; the stepping
		-- system plants it there in the world, so a lunge is a real step.
		local stanceFeet=stance(subject.fighterId)
		base,baseRate=locomotionTargets(char,subject,subject.fighterId,dt,{rf=footwork.R or stanceFeet.rf,lf=footwork.L or stanceFeet.lf},"attack")
	else base,baseRate=locomotionTargets(char,subject,subject.fighterId,dt) end
	if casting and not swinging and Authored then
		-- (Blender-first) an authored technique: Channel (or Form), Hold while a
		-- held technique gathers, Release, Recover.
		local fighterId,id=tostring(subject.fighterId),tostring(subject.castId)
		local prefix=fighterId.."."..id
		local key=subject.state..":"..id
		if memo.castKey~=key then memo.castKey=key;memo.castAt=elapsedTime end
		if subject.state~="TechniqueChannel" or (subject.techCharge or 0)<=0 then memo.holdAt=nil end
		local name,t
		if subject.state=="TechniqueChannel" then
			if (subject.techCharge or 0)>0 and Authored.has(prefix..".Hold") then
				memo.holdAt=memo.holdAt or elapsedTime
				name=prefix..".Hold";t=elapsedTime-memo.holdAt
			else
				name=if Authored.has(prefix..".Channel") then prefix..".Channel" else prefix..".Form"
				if Authored.has(name) then t=Authored.stretch(name,subject.castElapsed or 0,techSpec(subject.fighterId,subject.castId).Channel or .4) end
			end
		elseif subject.state=="TechniqueActive" then
			name=prefix..".Release";t=elapsedTime-memo.castAt
		else
			name=prefix..".Recover";t=elapsedTime-memo.castAt
		end
		if name and t and Authored.has(name) then
			local targets=table.clone(Authored.sample(name,t))
			if subject.airborne then
				for joint in JOINTS do if not UPPER[joint] and joint~="Root" then targets[joint]=base[joint] end end
			else
				targets.__feet=authoredFeet(char,targets,dt)
			end
			mark(char,"cast:"..name,.1)
			apply(char,targets,RATE.authored,dt)
			return "technique"
		end
	end
	if casting and not swinging then
		local spec=castSpec(subject)
		if spec then
			local targets=build(spec)
			if subject.airborne then
				-- Keep the legs of the air pose; the upper body casts.
				for key in JOINTS do if not UPPER[key] and key~="Root" then targets[key]=base[key] end end
			end
			local slip=memo.slipAt and elapsedTime-memo.slipAt
			if slip and slip<.14 and subject.castId=="Read" then
				-- The slip: hips turn toward the attacker, a small roll away from
				-- the blow, the front hand opens and rises for the palm.
				local w=1-smooth(slip/.14)
				targets=table.clone(targets)
				targets.Root=(targets.Root or IDENTITY)*ANG(0,rad(-20*w),rad(6*w))
				targets.Left=ANG(rad(40*w),0,0)*(targets.Left or IDENTITY)
				targets.LeftElbow=(targets.LeftElbow or IDENTITY):Lerp(ANG(rad(60),0,0),w)
			end
			apply(char,targets,RATE.cast,dt)
			return "technique"
		end
	end
	if swinging then
		local name=clipName(subject)
		local targets,weight=attackTargets(name,subject.attackElapsed or 0,subject.fighterId,kunaiClip(subject,name))
		-- (Clone: blend may hand back a cached clip pose, which must not change.)
		local final=table.clone(blend(base,targets,weight))
		local variant=subject.attackVariant
		if variant=="MirageCounter" or variant=="ReadCounter" or variant=="TrigramCounter" then
			local phase=attackPhase(name,subject.attackElapsed or 0,subject.fighterId)
			if variant=="TrigramCounter" then
				-- Out of the spin: the yaw unwinds onto the opponent in the startup.
				final.Root=(final.Root or IDENTITY)*ANG(0,rad(90*(1-smooth(math.min(phase,1)))),0)
			else
				-- A low glide through the image / past the read blow.
				local w=if phase<1 then 1 elseif phase<2 then 2-phase else 0
				final.Root=CF(0,-.7*w,-1.2*w)*(final.Root or IDENTITY)
			end
		end
		-- Combat convergence (whiff quality): a swing that met nothing does not
		-- recover like one that landed. The body carries on past where the
		-- contact should have been, hips dropped and forward, chest over the
		-- front foot, then hauls itself back. Planted feet stay planted (they
		-- are solved against the hips as drawn).
		-- Combat convergence (free fights: a punch drove the fist through the
		-- opponent's head when he had stepped in under arm's length). The swing
		-- keeps its shape; the hips and chest give way back by the missing
		-- distance so the blow lands on the body, not inside it. Planted feet
		-- stay planted.
		local rootPart=char:FindFirstChild("HumanoidRootPart")
		if subject.lookAt and rootPart and not subject.airborne and weight>0 then
			local to=subject.lookAt-rootPart.Position
			local along=-rootPart.CFrame:VectorToObjectSpace(Vector3.new(to.X,0,to.Z)).Z
			-- Two limits (recorded free fights, part by part): the striking hand
			-- stays out of the body at the server's contact distance (the clips
			-- reach ~0.3 past it), and the chest, carried forward by the clip's
			-- lunge and lean, never meets the opponent's (a dash attack drove the
			-- two torsos within 1.4 studs for a dozen frames).
			local chest=(final.Root or IDENTITY):PointToWorldSpace(Vector3.new(0,1.2,0))
			local short=math.clamp(math.max(3.9-along,2.6-(along+chest.Z)),0,2)
			if along>0 and short>0 and math.abs(to.Y)<3 then
				local w=short*weight
				final.Root=CF(0,0,w)*(final.Root or IDENTITY)
				final.Waist=(final.Waist or IDENTITY)*ANG(rad(6*w),0,0)
			end
		end
		if subject.whiffed and not subject.airborne then
			local phase=attackPhase(name,subject.attackElapsed or 0,subject.fighterId)
			local w=smooth(math.clamp((phase-2)/.12,0,1))*(1-smooth(math.clamp((phase-2.45)/.4,0,1)))
			if w>0 then
				final.Root=CF(0,-.32*w,-.55*w)*(final.Root or IDENTITY)*ANG(rad(-9*w),0,0)
				final.Waist=(final.Waist or IDENTITY)*ANG(rad(-10*w),0,0)
				final.Neck=(final.Neck or IDENTITY)*ANG(rad(8*w),0,0)
			end
		end
		-- Planted feet come from the stepping system; kicking legs from the clip.
		if footwork and base.__feet then
			final.__feet={}
			for side in footwork do final.__feet[side]=base.__feet[side] end
		else final.__feet=nil end
		local authoredStrike=Authored and Authored.has(tostring(subject.fighterId).."."..tostring(name))
		if authoredStrike then
			-- (ANIM-002) A strike thrown on the move comes out of the run: the legs
			-- keep the stride (phase by distance, feet on the floor) as long as the
			-- body really travels, the hips give half their turn to the run, the
			-- arms and chest throw the blow. Slowing through the recovery, the
			-- strike's own footwork takes the legs back, its planted feet locked
			-- on the floor where they land.
			local speed=planar(subject.velocity).Magnitude
			local wMove=if subject.airborne then 0 else smooth((speed-7)/10)*weight
			if wMove>0 and baseRate==RATE.authored then
				-- (`base` is this frame's authored locomotion: its phase already advanced.)
				local run=base
				for joint in JOINTS do
					if not UPPER[joint] and joint~="Root" and run[joint] then final[joint]=(final[joint] or IDENTITY):Lerp(run[joint],wMove) end
				end
				local r0,r1=final.Root or IDENTITY,run.Root or IDENTITY
				final.Root=CF(r0.Position:Lerp(r1.Position,wMove))*r0.Rotation:Lerp(r1.Rotation,wMove*.5)
			end
			-- (While the run carries the legs, its own cycle keeps them on the floor.)
			if not subject.airborne and wMove<.35 then final.__feet=authoredFeet(char,final,dt) end
		end
		-- Chaining into the next strike: the arms travel from the last contact
		-- pose back into the new chamber over a few frames instead of in one or
		-- two (a hand used to jump ~3 studs in a frame between Light1 and Light2,
		-- four times a real punch). The strike itself keeps its full speed.
		local s=stateOf(char)
		local key=tostring(name)..":"..tostring(subject.attackSerial or 0)
		if s.swingKey~=key then
			s.chainedIn=s.lastBranch=="attack" and elapsedTime-(s.lastBranchAt or -1)<.1
			s.swingKey=key;s.swingAt=elapsedTime
		end
		local chainIn=s.chainedIn and elapsedTime-s.swingAt<CHAIN_IN
		s.lastBranch="attack";s.lastBranchAt=elapsedTime
		-- A kicking (free) leg whips a little slower than an arm: at the strike
		-- cap a foot crossed ~2.5 studs in one frame, twice a real kick.
		if authoredStrike then
			mark(char,"atk:"..key,if s.chainedIn then .07 else .09)
			apply(char,final,RATE.authored,dt)
			return "attack"
		end
		apply(char,final,RATE.attack,dt,if chainIn then RATE.chainIn else nil,RATE.kick)
		return "attack"
	end
	-- (Blender-first) Touch-down: the authored landing plays through (the
	-- server's landing window is only a tenth of a second), unless the body
	-- runs on or does anything else.
	local landName=Authored and tostring(subject.fighterId)..".Land"
	if landName and Authored.has(landName) then
		if subject.landing and not memo.wasLanding then
			memo.landAt=elapsedTime;memo.landHard=subject.landStrong==true or elapsedTime-(memo.trickEndAt or -9)<.6
		end
		memo.wasLanding=subject.landing==true
		local since=memo.landAt and elapsedTime-memo.landAt
		local still=not subject.airborne and (subject.speed or 0)<6 and not swinging and not casting and subject.state=="Neutral"
		if since and still then
			local len=Authored.length(landName)
			-- A plain hop lands lighter and quicker than a drop or a flip.
			local t=since*(if memo.landHard then 1 else 1.7)
			if t<len then
				local pose=Authored.sample(landName,t)
				local final=table.clone(if memo.landHard then pose else mixPoses({{base,1},{pose,1.4}}))
				final.__feet=authoredFeet(char,final,dt)
				mark(char,"land",.07)
				apply(char,final,RATE.authored,dt)
				return "landing"
			end
			memo.landAt=nil
		elseif since and not subject.landing then
			memo.landAt=nil
		end
	end
	if subject.landing then
  -- Load quickly, then release progressively into gait/guard. Holding the
  -- deepest crouch until the flag disappears used to pop the body upright.
  local phase=subject.landingPhase
  local load=if phase==nil then 1 elseif phase<.25 then .55+.45*smooth(phase/.25) else 1-smooth((phase-.25)/.75)
		-- Coming out of a flip: the ninja landing, low on spread feet with the
		-- arms out for balance (the references' crouched touch-down), then the
		-- run picks up from it; the server keeps the travel meanwhile.
		if elapsedTime-(memo.trickEndAt or -9)<.6 then
			local targets,rate=landTargets(subject.fighterId,load,true)
			apply(char,targets,rate,dt)
			return "landing"
		end
		if not subject.landStrong and not subject.airborne and (subject.speed or 0)>6 then
			-- A running landing keeps its stride and momentum: the hips absorb the
			-- drop for a few frames instead of the body stopping in a crouch.
			local final=table.clone(base)
			final.Root=(base.Root or IDENTITY)*CF(0,-.3*load,0)*ANG(rad(-7*load),0,0)
			apply(char,final,baseRate or RATE.locomotion,dt)
			return "landing"
		end
		local targets,rate=landTargets(subject.fighterId,(if subject.landStrong then 1 else .45)*load)
		apply(char,targets,rate,dt)
		return "landing"
	end
	-- Throw overlay on top of the gait: the arm throws, the legs keep running.
	local throw=subject.throwKind and THROWS[subject.throwKind]
	if subject.castId=="WindCut" and math.abs((subject.castElapsed or 99)-(subject.throwElapsed or -99))<.08 then throw=THROWS.WindCut end
	local throwElapsed=subject.throwElapsed or 99
	-- (Wind Cut keeps its own slash: the clip is looked up under its name.)
	local throwName=if throw==THROWS.WindCut then "WindCut" else subject.throwKind
	local throwClip=Authored and throwName and tostring(subject.fighterId)..".Throw."..tostring(throwName)
	if throwClip and Authored.has(throwClip) and throwElapsed>=0 then
		-- (ANIM-001) An authored throw: its release frame lands on the server's
		-- release; the upper body throws, the legs keep their own motion.
		local c=Authored.clip(throwClip)
		local rel=c.markers.release or c.length*.4
		local release=math.max(subject.throwRelease or .1,1/60)
		local t=if throwElapsed<release then throwElapsed/release*rel else rel+(throwElapsed-release)
		if t<c.length then
			local w=1-smooth((t-(c.length-.12))/.12)
			local pose=Authored.sample(throwClip,t)
			local targets=table.clone(base)
			for key in UPPER do if pose[key] then targets[key]=(base[key] or IDENTITY):Lerp(pose[key],w) end end
			mark(char,"throw:"..throwClip,.07)
			apply(char,targets,RATE.authored,dt)
			return "throw"
		end
	end
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
	-- (Blender-first) a technique carried on the body (BodyState, the Chidori):
	-- the upper body holds its authored carry over the gait.
	local carried=subject.bodyState and Authored and tostring(subject.fighterId).."."..tostring(subject.bodyState.id)..".Hold"
	if carried and Authored.has(carried) then
		memo.carryAt=memo.carryAt or elapsedTime
		local pose=Authored.sample(carried,elapsedTime-memo.carryAt)
		base=table.clone(base)
		for joint in UPPER do if pose[joint] then base[joint]=pose[joint] end end
	else
		memo.carryAt=nil
	end
	if (subject.tenketsu or 0)>0 then base=tenketsuPosture(base,subject.tenketsu,subject.tenketsuSevere) end
	if (subject.awaken or 0)>0 and familyOf(subject.fighterId).awakenPosture=="curse" then base=cursePosture(base,subject.curseHunger) end
	local brake=memo.brakeAt and elapsedTime-memo.brakeAt
	if brake and brake<.3 and subject.state=="Recovery" then base=brakePosture(base,1-smooth(brake/.3)) end
	if baseRate==RATE.authored then
		local tag=memo.locoTag
		mark(char,if subject.airborne then "air" else "loco"..(if tag then ":"..tag else ""),if subject.airborne then .12 elseif tag=="brake" then .08 else .15)
	end
	apply(char,base,baseRate,dt)
	return "locomotion"
end
-- Hard reset: only for a character switch, rematch, death or destruction.
function Motion.reset(char)
	local s=stateOf(char)
	-- Anchors, gait phase, acceleration and attack-transition memory belong
	-- to the previous life/rig just as much as its joint pose does.
	table.clear(s)
	s.motors={};s.pose={};s.phase=0;s.clock=0;s.inert={};s.vel={}
	for key in JOINTS do local joint=motor(char,key);if joint then joint.Transform=IDENTITY end end
end
Motion.clear=Motion.reset
-- Exposed for the headless suite: the world-planted stepping rule.
Motion._stepFeet=function(char,base,velocity,dt,mode) return stepFeet(char,stateOf(char),base,velocity,velocity.Magnitude,dt,mode) end
Motion._ankleY=ANKLE_Y
return Motion
