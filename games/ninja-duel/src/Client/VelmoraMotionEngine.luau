-- Velmora additive R15 motion, adapted to Ninja Duel's server timings and
-- extended into a full combat presentation layer: authored stances, directional
-- locomotion, air and ground states, a hit-reaction vocabulary and authored
-- choreography. Presentation only; combat authority stays server-side.
--
-- Every joint value is written as a Motor6D.Transform, which the engine applies
-- *after* the Animator. Nothing here resets the skeleton per frame: each write
-- damps towards its target, and only Motion.reset hard-clears.
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
-- Every write is damped towards its target instead of snapping. Hard resets are
-- explicit (character switch, rematch, death); normal presentation never snaps.
-- Damping rates per layer. Attack sits highest so a swing stays snappy and the
-- authored ramp, not the damping, decides its timing; locomotion is the calmest.
local RATE={attack=42,recoil=26,guard=20,defense=22,locomotion=14,air=12,ground=10}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
-- Pose families. Two different families never share a silhouette, so a family
-- change is ramped over TRANSITION seconds; within one family the per-layer
-- damping is enough. This is what removes the idle <-> attack and ground <-> air
-- snaps without slowing any gameplay timing down.
local families=setmetatable({},{__mode="k"})
-- A simulated presentation clock advanced by dt, never the wall clock: the
-- animation must look identical on a 30 Hz and a 120 Hz client, and tests must
-- be deterministic.
local elapsedTime=0
-- Advanced exactly once per rendered frame by the caller. Nothing deeper in this
-- module may move it, or the animation would run at the wrong speed.
function Motion.tick(dt)
	if dt and dt>0 then elapsedTime+=math.min(dt,.1) end
	return elapsedTime
end
function Motion.now() return elapsedTime end
local TRANSITION=.13
local function setFamily(char,name)
	if not char then return end
	local state=families[char]
	if not state then families[char]={name=name,at=elapsedTime};return end
	if state.name~=name then state.name=name;state.at=elapsedTime end
end
local function familyBlend(char)
	local state=char and families[char]
	if not state then return 1 end
	local p=math.clamp((elapsedTime-state.at)/TRANSITION,0,1)
	return smooth(p)
end
local function set(char,key,value,rate,dt)
	local joint=motor(char,key)
	if not joint then return end
	local baseRate=rate or RATE.locomotion
	local alpha=if dt then 1-math.exp(-baseRate*dt) else 1
	if dt then
		-- A slow blend eases the body out of its previous family; once the
		-- transition is over the layer's own damping drives the motion.
		local blend=familyBlend(char)
		if blend<1 then
			local slow=math.max(baseRate*.45,6)
			local transitionAlpha=1-math.exp(-slow*dt)
			alpha=blend*alpha+(1-blend)*transitionAlpha
		end
	end
	joint.Transform=if alpha>=1 then value else joint.Transform:Lerp(value,alpha)
end
local function rot(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function sign(v) return if v<0 then -1 else 1 end
-- ---------------------------------------------------------------- choreography
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
	Heavy={pose({18,-25,0},{22,-30,0},{-70,0,40},{-55,0,-30},{-45,0,0},{20,0,0},{-95,-80},{-70,-40}),pose({-12,30,-10},{-18,35,-12},{-150,0,20},{15,0,-40},{-70,20,0},{30,0,0},{-10,-75},{-95,0})},
	Launcher={pose({18,0,-12},{25,-25,0},{40,0,25},{-40,0,-25},{-60,0,0},{-25,0,0},{-85,-60},{-90,-45}),pose({-15,25,0},{-28,32,0},{-165,0,15},{20,0,-35},{-65,0,0},{28,0,0},{-15,-70},{-75,0})},
	DashAttack={pose({28,-20,-12},{12,-25,0},{55,0,15},{35,0,-25},{-35,0,0},{25,0,0},{-30,-25}),pose({15,20,-8},{-12,40,-10},{-95,-25,-20},{50,0,-30},{45,0,0},{-50,0,0},{-5,-45},{-15,-70})},
	Air1={pose({0,-30,-28},{5,-30,-15},{-55,0,65},{-35,0,-35},{-55,0,-20},{30,0,20},{-80,-70},{-60,-40}),pose({0,35,30},{-15,55,20},{-100,-50,-30},{45,0,-35},{25,0,-35},{-65,0,10},{-10,-50},{-25,-80})},
	Air2={pose({20,35,20},{20,35,0},{40,0,65},{-70,0,-25},{-45,0,0},{-65,0,15},{-50,-65},{-70,-90}),pose({-15,-50,-25},{-20,-45,-10},{-60,0,45},{20,0,-55},{-85,0,-30},{30,0,15},{-65,-25},{0,-65})},
	Slam={pose({-25,0,-15},{-20,-30,0},{-165,0,25},{-45,0,-25},{-65,0,0},{-30,0,0},{-65,-60},{-90,-70}),pose({48,20,0},{25,30,0},{-85,0,-15},{50,0,-25},{20,0,0},{-30,0,0},{-10,-55},{-15,-60})},
	Grab={pose({6,-18,0},{10,-22,0},{-70,0,35},{-50,0,-25},{-25,0,0},{15,0,0},{-90,-70}),pose({-4,22,0},{-6,26,0},{-95,0,10},{-30,0,-20},{-35,0,0},{20,0,0},{-60,-60})},
	Throw={pose({-10,-35,0},{-12,-40,0},{30,0,55},{-25,0,-45},{-40,0,0},{20,0,0},{-70,-60}),pose({10,45,-12},{14,52,-14},{-120,0,25},{35,0,-30},{15,0,0},{-25,0,0},{-25,-65})},
	ThrowUp={pose({16,0,-14},{24,-18,0},{45,0,30},{-35,0,-30},{-55,0,0},{-20,0,0},{-85,-65}),pose({-14,22,0},{-24,28,0},{-160,0,12},{18,0,-30},{-60,0,0},{26,0,0},{-15,-70})},
	},
	Mirage={
	-- Open palm check, shuriken flick, rooted side kick that creates space.
	Light1={pose({0,8,0},{0,18,0},{-45,0,15},{-65,0,-15},{0,0,0},{-12,0,0},{-90,-95}),pose({0,-8,0},{-5,-18,0},{-88,0,8},{-40,0,-12},{-8,0,0},{12,0,0},{-5,-100})},
	Light2={pose({0,-8,0},{0,-22,0},{-45,0,15},{-80,35,-50},{-10,0,0},{8,0,0},{-100,-115}),pose({0,12,0},{0,22,0},{-50,0,15},{-95,-30,-15},{10,0,0},{-8,0,0},{-90,-5})},
	Light3={pose({0,15,0},{0,25,0},{-55,0,20},{-65,0,-15},{10,0,0},{-65,0,-10},{-85,-85},{0,-115}),pose({-12,-25,12},{-8,-25,0},{-40,0,35},{-65,0,-25},{12,0,0},{-100,-15,-25},{-70,-90},{0,0})},
	Heavy={pose({0,-14,0},{0,-26,0},{-60,0,22},{-70,0,-18},{-20,0,0},{10,0,0},{-95,-90}),pose({-8,20,-6},{-10,28,0},{-120,0,18},{-45,0,-25},{15,0,0},{-12,0,0},{-50,-85})},
	Launcher={pose({6,-10,0},{12,-15,0},{-50,0,15},{-60,0,-15},{-65,0,0},{5,0,0},{-85,-90},{-110,0}),pose({-8,-15,-8},{-12,0,0},{-60,0,25},{-65,0,-20},{-145,0,0},{18,0,0},{-80,-90},{-8,0})},
	DashAttack={pose({8,20,0},{0,30,0},{-50,0,20},{-75,0,-15},{-20,0,0},{15,0,0},{-110,-100}),pose({8,-18,0},{0,-35,0},{-75,0,-10},{-50,0,-25},{15,0,0},{-20,0,0},{-120,-85})},
	Air1={pose({-8,10,0},{-8,20,0},{-55,0,15},{-65,0,-20},{-65,0,0},{-20,0,0},{-90,-90},{-100,-50}),pose({-10,-15,8},{-15,-20,0},{-45,0,25},{-60,0,-25},{-100,0,0},{20,0,0},{-90,-70},{0,-50})},
	Air2={pose({0,-15,0},{0,-25,0},{-60,0,20},{-80,20,-45},{-35,0,0},{-30,0,0},{-100,-110},{-70,-65}),pose({0,20,0},{0,35,0},{-65,0,25},{-95,-20,-15},{-20,0,0},{-45,0,0},{-80,-5},{-55,-75})},
	Slam={pose({-15,0,0},{-20,0,0},{-160,0,15},{-160,0,-15},{-45,0,0},{-45,0,0},{-110,-110},{-75,-75}),pose({25,0,0},{40,0,0},{-100,0,10},{-100,0,-10},{25,0,0},{15,0,0},{-5,-5},{-20,-30})},
	Grab={pose({4,-10,0},{6,-14,0},{-60,0,25},{-55,0,-20},{-15,0,0},{10,0,0},{-85,-80}),pose({-2,14,0},{-4,18,0},{-80,0,12},{-40,0,-18},{-25,0,0},{14,0,0},{-55,-70})},
	Throw={pose({-6,-28,0},{-8,-32,0},{25,0,45},{-30,0,-38},{-30,0,0},{16,0,0},{-75,-65}),pose({6,36,-8},{8,42,-10},{-105,0,20},{28,0,-25},{12,0,0},{-20,0,0},{-30,-70})},
	ThrowUp={pose({10,-8,0},{16,-12,0},{-45,0,25},{-60,0,-22},{-45,0,0},{-15,0,0},{-80,-85}),pose({-10,16,0},{-16,20,0},{-130,0,15},{-50,0,-25},{-55,0,0},{22,0,0},{-40,-80})},
	},
}
local function rotation(v)
	return if v then rot(v[1],v[2],v[3]) else CFrame.identity
end
-- -------------------------------------------------------------------- stances
-- Authored idle silhouettes. Minato is lighter and coiled forward with a
-- reverse-grip kunai; Itachi is calmer, more upright and deliberately still.
local stances={
	-- Minato: light, coiled forward, weight on the lead foot, kunai hand already
	-- low and reverse-gripped, other hand open and ready to angle off.
	Flashstep={
		root={-3,6,0},waist={-13,8,-3},neck={-6,-6,2},
		right={-30,4,20},left={-10,-6,-26},relbow=-82,lelbow=-44,
		rhip={-12,4,-5},lhip={10,-4,6},rknee={-22,0,0},lknee={-8,0,0},
		breath=2.8,tempo=9.5,
	},
	-- Itachi: upright, square, economical. Both hands deliberate and close to
	-- the body, feet planted evenly, almost no idle motion.
	Mirage={
		root={1,-2,0},waist={-2,-4,0},neck={1,4,-1},
		right={-44,-4,8},left={-40,4,-10},relbow=-62,lelbow=-66,
		rhip={2,-2,-3},lhip={-2,2,3},rknee={-9,0,0},lknee={-9,0,0},
		breath=1.1,tempo=6,
	},
}
local function stance(fighterId) return stances[fighterId] or stances.Flashstep end
-- ---------------------------------------------------------------- locomotion
-- The Animator still owns the leg cycle (Movement priority). This layer adds the
-- readable combat body language on top: torso lean and twist, weight shift, head
-- lead, arm counter-swing and, where it matters, foot placement.
local function planar(v) return if v then Vector3.new(v.X,0,v.Z) else Vector3.zero end
local function locomotionPose(char,actor,fighterId,dt,now)
	now=now or elapsedTime
	local base=stance(fighterId)
	local root=char:FindFirstChild("HumanoidRootPart")
	local velocity=planar(actor.velocity)
	local speed=velocity.Magnitude
	local alpha=math.clamp(speed/44,0,1)
	local minato=fighterId=="Flashstep"
	-- Direction relative to the body: +Z forward, +X right.
	local localMove=Vector3.zero
	if root then localMove=root.CFrame:VectorToObjectSpace(velocity) end
	local forward=math.clamp(localMove.Z/24,-1,1)
	local side=math.clamp(localMove.X/24,-1,1)
	local turning=if localMove.Magnitude>1 then math.clamp(math.atan2(localMove.X,localMove.Z),-1,1) else 0
	-- Stride phase advances with real speed, so a stopped fighter stops striding.
	local phase=now*(if minato then 9 else 6.6)*(0.6+alpha*1.5)
	local stride=math.sin(phase)
	local still=1-math.clamp(speed/6,0,1)
	local live=math.max(.3,alpha)
	local breath=math.sin(now*base.tempo)*(if speed<3 then 1 else .3)
	local back=forward<-.25
	-- Forward drive leans in; backing off stays chest-up and reads as retreating.
	-- Retreating is its own shape: chest up, weight back, lead leg extending,
	-- which is clearly not a slowed-down forward run.
	local retreat=math.max(0,-forward)
	local drive=if back then -retreat*(if minato then 24 else 17) else forward*math.min(26,7+alpha*22)
	local lean=base.waist[1]+drive+breath*base.breath
	-- Weight shifts onto the leading foot; strafing tilts the waist into travel.
	local shift=stride*math.rad(if minato then 9 else 6)*live
	local bank=math.rad(side*(if minato then 30 else 20))*math.max(.35,alpha)
	-- Strafing is a different shape: the torso tilts into travel and the lead
	-- shoulder opens, so sideways movement never reads as walking forward.
	local strafe=math.abs(side)*math.max(.3,alpha)
	set(char,"Waist",rot(lean*(1-strafe*.55),base.waist[2]+turning*18*alpha+shift+side*14*strafe,base.waist[3]+bank),RATE.locomotion,dt)
	set(char,"Neck",rot(base.neck[1]-drive*.22+retreat*6-turning*8*alpha,-turning*12*alpha,-bank*.3),RATE.locomotion,dt)
	-- Arms counter-swing the stride; backing up keeps the guard hand forward.
	-- At rest the stance's own arm shape survives, so idle is not generic.
	local swing=stride*math.rad(if minato then 34 else 22)*live
	local guard=if minato then math.max(0,-forward) else math.max(0,-forward)*.6
	set(char,"Right",rot(base.right[1]+swing*.9-guard*16+breath*base.breath*still*1.6,base.right[2]+breath*.6,base.right[3]-bank*.4),RATE.locomotion,dt)
	set(char,"Left",rot(base.left[1]-swing*.7-guard*10-breath*base.breath*still*1.2,base.left[2]-breath*.5,base.left[3]+bank*.4),RATE.locomotion,dt)
	set(char,"RightElbow",rot(base.relbow+math.abs(swing)*22*live+breath*.8,0,0),RATE.locomotion,dt)
	set(char,"LeftElbow",rot(base.lelbow+math.abs(swing)*16*live-breath*.6,0,0),RATE.locomotion,dt)
	set(char,"RightHip",rot(base.rhip[1]-swing*.55+retreat*26,base.rhip[2],base.rhip[3]-side*12*strafe),RATE.locomotion,dt)
	set(char,"LeftHip",rot(base.lhip[1]+swing*.55+retreat*14,base.lhip[2],base.lhip[3]-side*12*strafe),RATE.locomotion,dt)
	set(char,"RightKnee",rot(base.rknee[1]+math.max(0,-swing)*.5+retreat*18,0,0),RATE.locomotion,dt)
	set(char,"LeftKnee",rot(base.lknee[1]+math.max(0,swing)*.5+retreat*10,0,0),RATE.locomotion,dt)
	set(char,"RightKnee",rot(base.rknee[1]+math.max(0,-swing)*.5,0,0),RATE.locomotion,dt)
	set(char,"LeftKnee",rot(base.lknee[1]+math.max(0,swing)*.5,0,0),RATE.locomotion,dt)
	-- Torso leads the turn so the head and shoulders never snap independently.
	set(char,"Root",rot(base.root[1],base.root[2]+turning*6*alpha,base.root[3]),RATE.locomotion,dt)
end
-- --------------------------------------------------------------------- air
-- Distinct takeoff, rise, apex, fall and landing-compression silhouettes.
local function airPose(char,actor,fighterId,dt,now)
	now=now or elapsedTime
	local base=stance(fighterId)
	local rise=math.clamp((actor.velocity and actor.velocity.Y or 0)/72,-1,1)
	local rising=rise>.25
	local falling=rise<-.25
	local launch=actor.reaction=="Launched" or actor.reaction=="Juggled"
	if launch then
		-- Receiving the upward force: body folds, legs trail, arms follow.
		local t=math.clamp((actor.reactionElapsed or 0)/.22,0,1)
		local fold=smooth(t)
		set(char,"Waist",rot(-26*fold,6,0),RATE.air,dt)
		set(char,"Neck",rot(18*fold,0,0),RATE.air,dt)
		set(char,"Right",rot(-95*fold,0,34*fold),RATE.air,dt)
		set(char,"Left",rot(-88*fold,0,-30*fold),RATE.air,dt)
		set(char,"RightElbow",rot(-30*fold,0,0),RATE.air,dt)
		set(char,"LeftElbow",rot(-26*fold,0,0),RATE.air,dt)
		set(char,"RightHip",rot(30*fold,0,-8),RATE.air,dt)
		set(char,"LeftHip",rot(24*fold,0,8),RATE.air,dt)
		set(char,"RightKnee",rot(-52*fold,0,0),RATE.air,dt)
		set(char,"LeftKnee",rot(-46*fold,0,0),RATE.air,dt)
		set(char,"Root",rot(-10*fold,0,0),RATE.air,dt)
		return
	end
	if rising then
		set(char,"Waist",rot(-12,0,0),RATE.air,dt)
		set(char,"Neck",rot(-8,0,0),RATE.air,dt)
		set(char,"Right",rot(-58,-10,26),RATE.air,dt)
		set(char,"Left",rot(-48,10,-24),RATE.air,dt)
		set(char,"RightElbow",rot(-55,0,0),RATE.air,dt)
		set(char,"LeftElbow",rot(-50,0,0),RATE.air,dt)
		set(char,"RightHip",rot(-34,0,-6),RATE.air,dt)
		set(char,"LeftHip",rot(16,0,6),RATE.air,dt)
		set(char,"RightKnee",rot(-62,0,0),RATE.air,dt)
		set(char,"LeftKnee",rot(-24,0,0),RATE.air,dt)
		set(char,"Root",rot(-6,0,0),RATE.air,dt)
		return
	end
	if falling then
		set(char,"Waist",rot(6,0,0),RATE.air,dt)
		set(char,"Neck",rot(-4,0,0),RATE.air,dt)
		set(char,"Right",rot(24,0,30),RATE.air,dt)
		set(char,"Left",rot(20,0,-28),RATE.air,dt)
		set(char,"RightElbow",rot(-24,0,0),RATE.air,dt)
		set(char,"LeftElbow",rot(-22,0,0),RATE.air,dt)
		set(char,"RightHip",rot(-18,0,-6),RATE.air,dt)
		set(char,"LeftHip",rot(-24,0,6),RATE.air,dt)
		set(char,"RightKnee",rot(-30,0,0),RATE.air,dt)
		set(char,"LeftKnee",rot(-38,0,0),RATE.air,dt)
		set(char,"Root",rot(8,0,0),RATE.air,dt)
		return
	end
	-- Apex: coiled, ready to strike or land.
	set(char,"Waist",rot(base.waist[1],base.waist[2],base.waist[3]),RATE.air,dt)
	set(char,"Neck",rot(base.neck[1],0,0),RATE.air,dt)
	set(char,"Right",rot(base.right[1]-18,base.right[2],base.right[3]+8),RATE.air,dt)
	set(char,"Left",rot(base.left[1]-14,base.left[2],base.left[3]-8),RATE.air,dt)
	set(char,"RightElbow",rot(base.relbow-18,0,0),RATE.air,dt)
	set(char,"LeftElbow",rot(base.lelbow-14,0,0),RATE.air,dt)
	set(char,"RightHip",rot(-28,0,-6),RATE.air,dt)
	set(char,"LeftHip",rot(-20,0,6),RATE.air,dt)
	set(char,"RightKnee",rot(-44,0,0),RATE.air,dt)
	set(char,"LeftKnee",rot(-36,0,0),RATE.air,dt)
	set(char,"Root",rot(0,0,0),RATE.air,dt)
end
-- -------------------------------------------------------------- hit reactions
-- A small reusable vocabulary. The pose is chosen from the reaction kind and the
-- incoming direction, so a side hit rotates the body and a front hit recoils.
local reactionDuration={HitStun=.22,GuardStun=.4,Knockback=.34,Launched=.5,Juggled=.4,WallSplat=.42,Grabbed=.3}
local function reactionPose(char,actor,fighterId,dt,now)
	local kind=actor.reaction or "HitStun"
	local elapsed=actor.reactionElapsed or 0
	local duration=reactionDuration[kind] or .24
	local t=1-smooth(math.clamp(elapsed/duration,0,1))
	local strong=math.clamp((actor.hitStrength or .4)*1.35,.35,1.4)
	local angle=math.rad(actor.hitAngle or 0)
	-- Rotate the reaction into the body so it answers the real hit direction.
	local from=math.cos(angle)		-- +1 hit from the front
	local side=math.sin(angle)		-- +1 hit from the fighter's right
	if kind=="Knockback" then
		-- Carried by force: chest opens, arms trail, feet leave the stance.
		local lift=math.clamp(elapsed/.12,0,1)
		set(char,"Waist",rot(16*t*strong,side*26*t,from*-10*t),RATE.recoil,dt)
		set(char,"Neck",rot(-14*t,-side*16*t,0),RATE.recoil,dt)
		set(char,"Right",rot(-58*t*strong,0,44*t),RATE.recoil,dt)
		set(char,"Left",rot(-52*t*strong,0,-40*t),RATE.recoil,dt)
		set(char,"RightElbow",rot(-18*t,0,0),RATE.recoil,dt)
		set(char,"LeftElbow",rot(-16*t,0,0),RATE.recoil,dt)
		set(char,"RightHip",rot(-30*t*lift,0,-10),RATE.recoil,dt)
		set(char,"LeftHip",rot(10*t*lift,0,10),RATE.recoil,dt)
		set(char,"RightKnee",rot(-40*t*lift,0,0),RATE.recoil,dt)
		set(char,"LeftKnee",rot(-24*t*lift,0,0),RATE.recoil,dt)
		set(char,"Root",rot(12*t*strong,0,0),RATE.recoil,dt)
		return
	end
	if kind=="WallSplat" then
		-- Clear collision, then compression against the surface.
		local splat=smooth(math.clamp(elapsed/.1,0,1))
		set(char,"Waist",rot(-20*splat,0,0),RATE.defense,dt)
		set(char,"Neck",rot(16*splat,0,0),RATE.defense,dt)
		set(char,"Right",rot(-30*splat,0,58*splat),RATE.defense,dt)
		set(char,"Left",rot(-30*splat,0,-58*splat),RATE.defense,dt)
		set(char,"RightElbow",rot(-40*splat,0,0),RATE.defense,dt)
		set(char,"LeftElbow",rot(-40*splat,0,0),RATE.defense,dt)
		set(char,"RightKnee",rot(-30*splat,0,0),RATE.defense,dt)
		set(char,"LeftKnee",rot(-26*splat,0,0),RATE.defense,dt)
		return
	end
	if kind=="GuardStun" then
		set(char,"Waist",rot(-10*t,0,side*8*t),RATE.recoil,dt)
		set(char,"Right",rot(-60+18*t,0,20),RATE.recoil,dt)
		set(char,"Left",rot(-60+18*t,0,-20),RATE.recoil,dt)
		return
	end
	if kind=="Grabbed" then
		set(char,"Waist",rot(-8,0,0),RATE.defense,dt)
		set(char,"Neck",rot(-10,0,0),RATE.defense,dt)
		set(char,"Right",rot(-40,0,30),RATE.defense,dt)
		set(char,"Left",rot(-40,0,-30),RATE.defense,dt)
		set(char,"RightElbow",rot(-60,0,0),RATE.defense,dt)
		set(char,"LeftElbow",rot(-60,0,0),RATE.defense,dt)
		return
	end
	-- Light / heavy body hit. Feet stay planted; the torso and head answer.
	-- A blow from behind folds the body forward, a frontal one folds it back.
	local head=math.max(.4,math.abs(from))
	local behind=math.max(0,-from)
	local pitch=-16*t*strong+behind*30*t*strong
	set(char,"Waist",rot(pitch,-side*22*t,from*8*t),RATE.recoil,dt)
	set(char,"Neck",rot(-12*t*strong+behind*24*t*strong,side*10*t,-from*4*t),RATE.recoil,dt)
	set(char,"RightHip",rot(-6*t*head+behind*14*t,0,-4),RATE.recoil,dt)
	set(char,"LeftHip",rot(-4*t*head+behind*10*t,0,4),RATE.recoil,dt)
	set(char,"Right",rot(-28*t*strong,0,26*t),RATE.recoil,dt)
	set(char,"Left",rot(-20*t*strong,0,-22*t),RATE.recoil,dt)
	set(char,"RightElbow",rot(-30*t*strong,0,0),RATE.recoil,dt)
	set(char,"LeftElbow",rot(-24*t*strong,0,0),RATE.recoil,dt)
	set(char,"RightHip",rot(-6*t*head,0,-4),RATE.recoil,dt)
	set(char,"LeftHip",rot(-4*t*head,0,4),RATE.recoil,dt)
	set(char,"Root",rot(-4*t*strong,side*6*t,0),RATE.recoil,dt)
end
-- ------------------------------------------------------------ ground and KO
-- Grounded poses so a knockdown never slides along the floor standing up.
local function groundPose(char,actor,dt,now)
	now=now or elapsedTime
	local kind=actor.reaction or "Knockdown"
	local elapsed=actor.reactionElapsed or 0
	local pose=actor.groundPose or (if kind=="WallSplat" then "Splat" else "Knockdown")
	if pose=="Wakeup" then
		-- Short, readable get-up: push up, gather, stand. Never cinematic.
		local t=math.clamp(elapsed/.24,0,1)
		local push=smooth(t)
		set(char,"Root",rot(-52*(1-push),0,10*(1-push)),RATE.ground,dt)
		set(char,"Waist",rot(-38*(1-push*.4),0,0),RATE.ground,dt)
		set(char,"Neck",rot(16*(1-push*.5),0,0),RATE.ground,dt)
		set(char,"Right",rot(-70*(1-push),0,40*(1-push*.5)),RATE.ground,dt)
		set(char,"Left",rot(-64*(1-push),0,-36*(1-push*.5)),RATE.ground,dt)
		set(char,"RightElbow",rot(-20,0,0),RATE.ground,dt)
		set(char,"LeftElbow",rot(-18,0,0),RATE.ground,dt)
		set(char,"RightHip",rot(-70*(1-push*.5),0,-8),RATE.ground,dt)
		set(char,"LeftHip",rot(-48*(1-push*.5),0,8),RATE.ground,dt)
		set(char,"RightKnee",rot(-80*(1-push*.4),0,0),RATE.ground,dt)
		set(char,"LeftKnee",rot(-56*(1-push*.4),0,0),RATE.ground,dt)
		return
	end
	-- Flat on the back / side after the impact, arms settled, legs loose.
	local side=if actor.groundSide then actor.groundSide else 1
	set(char,"Root",rot(-78,0,16*side),RATE.ground,dt)
	set(char,"Waist",rot(-16,0,-6*side),RATE.ground,dt)
	set(char,"Neck",rot(22,0,0),RATE.ground,dt)
	set(char,"Right",rot(-88,0,52),RATE.ground,dt)
	set(char,"Left",rot(-70,0,-46),RATE.ground,dt)
	set(char,"RightElbow",rot(-30,0,0),RATE.ground,dt)
	set(char,"LeftElbow",rot(-24,0,0),RATE.ground,dt)
	set(char,"RightHip",rot(-64,0,-12*side),RATE.ground,dt)
	set(char,"LeftHip",rot(-38,0,12*side),RATE.ground,dt)
	set(char,"RightKnee",rot(-58,0,0),RATE.ground,dt)
	set(char,"LeftKnee",rot(-30,0,0),RATE.ground,dt)
end
-- Final state of a defeated fighter. Chosen from the blow that ended it.
local koPoses={
	light={root={-74,0,14},waist={-12,0,-8},neck={20,0,0},right={-84,0,50},left={-66,0,-44},rknee=-52,lknee=-28},
	finisher={root={-88,0,20},waist={-20,0,-12},neck={26,0,0},right={-100,0,60},left={-80,0,-52},rknee=-64,lknee=-36},
	launcher={root={-64,0,26},waist={-24,6,-14},neck={28,0,0},right={-92,0,66},left={-76,0,-58},rknee=-70,lknee=-44},
	slam={root={-84,0,8},waist={-14,0,-4},neck={24,0,0},right={-78,0,44},left={-70,0,-40},rknee=-46,lknee=-22},
}
function Motion.ko(char,style,dt)
	local kinds=if style=="finisher" or style=="slam" or style=="launcher" then style else "light"
	local spec=koPoses[kinds] or koPoses.light
	set(char,"Root",rot(spec.root[1],spec.root[2],spec.root[3]),RATE.ground,dt)
	set(char,"Waist",rot(spec.waist[1],spec.waist[2],spec.waist[3]),RATE.ground,dt)
	set(char,"Neck",rot(spec.neck[1],spec.neck[2],spec.neck[3]),RATE.ground,dt)
	set(char,"Right",rot(spec.right[1],spec.right[2],spec.right[3]),RATE.ground,dt)
	set(char,"Left",rot(spec.left[1],spec.left[2],spec.left[3]),RATE.ground,dt)
	set(char,"RightElbow",rot(-16,0,0),RATE.ground,dt)
	set(char,"LeftElbow",rot(-12,0,0),RATE.ground,dt)
	set(char,"RightKnee",rot(spec.rknee,0,0),RATE.ground,dt)
	set(char,"LeftKnee",rot(spec.lknee,0,0),RATE.ground,dt)
end
-- -------------------------------------------------------------- attack poses
function Motion.pose(char,name,elapsed,fighterId,dt)
	local spec=Attacks[name];if not spec then return end
	local fighter=Fighters[fighterId];local profile=fighter and fighter.AttackProfile and fighter.AttackProfile[name]
	local startup=spec.startup*(profile and profile.startup or 1)
	local active=spec.active*(profile and profile.active or 1)
	local recovery=spec.recovery*(profile and profile.recovery or 1)
	local route=choreography[fighterId] or choreography.Flashstep
	local frames=route[name] or route.Light1
	local from,to,t
	if elapsed<startup then from={};to=frames[1];t=smooth(elapsed/math.max(startup,.01))
	elseif elapsed<startup+active*.55 then from=frames[1];to=frames[2];t=smooth((elapsed-startup)/math.max(active*.55,.01))
	else from=frames[2];to={};t=smooth((elapsed-startup-active*.55)/math.max(recovery+active*.45,.01)) end
	-- The pose ramps from whatever the body is already doing towards the authored
	-- silhouette, so a chained attack continues out of the previous follow-through
	-- instead of resetting to neutral first. The ramp, not the damping, sets the
	-- tempo, which keeps every frame's joint change small.
	-- The authored ramp decides the tempo; damping and the family blend carry the
	-- body into it from whatever it was already doing.
	for key in joints do
		set(char,key,rotation(from[key]):Lerp(rotation(to[key]),t),RATE.attack,dt)
	end
end
-- ------------------------------------------------------------------ weapons
local weapons=setmetatable({}, {__mode="k"})
-- Which hand actually holds the weapon, and when it should be visible.
local weaponWhen={
	Flashstep={Light1=true,Light2=true,DashAttack=true,Air1=true,Grab=true,Launcher=true},
	Mirage={Light1=true,Light2=true,Light3=true,DashAttack=true,Air1=true,Air2=true,Tool=true},
}
function Motion.weapon(char,actor)
	local item=weapons[char]
	if not item then
		local hand=char:FindFirstChild(if actor.fighterId=="Flashstep" then "RightHand" else "LeftHand")
		if not hand then return end
		item={hand=hand,parts={}};weapons[char]=item
		local minato=actor.fighterId=="Flashstep"
		for i=1,(if minato then 3 else 4) do
			local blade=Instance.new("WedgePart")
			blade.Name="CombatBlade"
			blade.Size=if minato then Vector3.new(.13,.42,1.2) else Vector3.new(.09,.3,.75)
			blade.Material=Enum.Material.Metal;blade.Color=Color3.fromRGB(195,210,222)
			blade.Massless=true;blade.CanCollide=false;blade.CanQuery=false;blade.CanTouch=false;blade.Parent=hand
			local weld=Instance.new("Weld");weld.Part0=hand;weld.Part1=blade
			-- Reverse grip for Minato so the blade follows the wrist naturally;
			-- Itachi's shuriken sits flat between finger and thumb.
			weld.C0=if minato
				then CFrame.new((i-2)*.24,-.45,-.3)*CFrame.Angles(0,0,math.rad((i-2)*22))*CFrame.Angles(math.pi,0,0)
				else CFrame.new(0,-.35,0)*CFrame.Angles(0,math.rad(i*90),0)*CFrame.new(0,0,-.3)
			weld.Parent=blade;table.insert(item.parts,blade)
		end
	end
	local when=weaponWhen[actor.fighterId] or weaponWhen.Flashstep
	-- Held during the wind-up and the strike, released after the follow-through:
	-- the blade follows the wrist through the swing, then goes away.
	local held=actor.attackName~=nil and actor.state~="Neutral" and when[actor.attackName]==true
	-- Released as the swing finishes: the blade is out for the wind-up, the
	-- strike and the first part of the follow-through, then it is put away.
	local spec=actor.attackName and Attacks[actor.attackName]
	local release=if spec then spec.startup+spec.active+spec.recovery*.45 else .35
	local visible=held and (actor.attackElapsed or 0)<=release
	for _,blade in item.parts do blade.Transparency=if visible then 0 else 1 end
	item.visible=visible
	item.attackName=actor.attackName
	item.debug=string.format("%s/%s/el=%.2f/held=%s",tostring(actor.attackName),tostring(actor.state),actor.attackElapsed or -1,tostring(held))
end
-- Presentation state for tests and debugging: which weapon is out, and where.
function Motion.weaponState(char)
	local item=weapons[char]
	if not item then return {visible=false,count=0} end
	local visible=0
	for _,blade in item.parts do if blade.Transparency<.5 then visible+=1 end end
	return {visible=visible>0,count=#item.parts,shown=visible,attackName=item.attackName,debug=item.debug}
end
-- ------------------------------------------------------------------- dodge
function Motion.defense(char,actor,dt)
	local root=char:FindFirstChild("HumanoidRootPart")
	local direction=planar(actor.velocity)
	local localMotion=if root then root.CFrame:ToObjectSpace(CFrame.new(direction)).Position else Vector3.zero
	if actor.state=="Dodging" then
		-- Direction-specific: a backstep, a forward slip and a side roll read
		-- differently instead of sharing one pose.
		local forward=math.clamp(localMotion.Z/14,-1,1)
		local side=math.clamp(localMotion.X/14,-1,1)
		local roll=if math.abs(side)>math.abs(forward)*.8 then sign(side) else 0
		set(char,"Root",rot(-18-roll*14,0,roll*34+side*18),RATE.defense,dt)
		set(char,"Waist",rot(-14+forward*10,roll*10,-side*10),RATE.defense,dt)
		set(char,"Neck",rot(8,-roll*8,0),RATE.defense,dt)
		set(char,"Right",rot(-58+forward*16,0,30+side*10),RATE.defense,dt)
		set(char,"Left",rot(-52+forward*14,0,-26+side*10),RATE.defense,dt)
		set(char,"RightElbow",rot(-70,0,0),RATE.defense,dt)
		set(char,"LeftElbow",rot(-64,0,0),RATE.defense,dt)
		set(char,"RightHip",rot(-40-forward*20,0,-8),RATE.defense,dt)
		set(char,"LeftHip",rot(-20+forward*14,0,8),RATE.defense,dt)
		set(char,"RightKnee",rot(-70,0,0),RATE.defense,dt)
		set(char,"LeftKnee",rot(-40,0,0),RATE.defense,dt)
		return
	end
	if actor.reaction and (actor.reaction=="Knockdown" or actor.reaction=="WallSplat") then
		groundPose(char,actor,dt,elapsedTime)
		return
	end
	if actor.reaction then reactionPose(char,actor,actor.fighterId,dt,elapsedTime) end
end
function Motion.recoil(char,elapsed,reaction,heavy,dt)
	reactionPose(char,{reaction=reaction,reactionElapsed=elapsed,hitStrength=if heavy then .9 else .45},nil,dt,elapsedTime)
end
function Motion.guard(char,impact,fighterId,dt)
	local absorbed=math.clamp(impact/.18,0,1)
	local calm=if fighterId=="Mirage" then .72 else 1
	-- Stable, intentional guard: both forearms up, weight settles back a little.
	set(char,"Waist",rot((-6+14*absorbed)*calm,0,0),RATE.guard,dt)
	set(char,"Neck",rot((-2+8*absorbed)*calm,0,0),RATE.guard,dt)
	set(char,"Right",rot(-58+16*absorbed,0,18),RATE.guard,dt)
	set(char,"Left",rot(-58+16*absorbed,0,-18),RATE.guard,dt)
	set(char,"RightElbow",rot(-84+10*absorbed,0,0),RATE.guard,dt)
	set(char,"LeftElbow",rot(-82+10*absorbed,0,0),RATE.guard,dt)
	set(char,"RightHip",rot(-6+8*absorbed,0,-4),RATE.guard,dt)
	set(char,"LeftHip",rot(4-8*absorbed,0,4),RATE.guard,dt)
	set(char,"RightKnee",rot(-14-8*absorbed,0,0),RATE.guard,dt)
	set(char,"LeftKnee",rot(-12-8*absorbed,0,0),RATE.guard,dt)
end
-- ------------------------------------------------------------------ landing
function Motion.land(char,actor,fighterId,strength,dt)
	local absorb=math.clamp(strength,0,1)
	local base=stance(fighterId)
	set(char,"Root",rot(-8*absorb,0,0),RATE.defense,dt)
	set(char,"Waist",rot(base.waist[1]+22*absorb,base.waist[2],base.waist[3]),RATE.defense,dt)
	set(char,"Neck",rot(-10*absorb,0,0),RATE.defense,dt)
	set(char,"Right",rot(base.right[1]+18*absorb,0,base.right[3]+6),RATE.defense,dt)
	set(char,"Left",rot(base.left[1]+16*absorb,0,base.left[3]-6),RATE.defense,dt)
	set(char,"RightElbow",rot(base.relbow-22*absorb,0,0),RATE.defense,dt)
	set(char,"LeftElbow",rot(base.lelbow-20*absorb,0,0),RATE.defense,dt)
	set(char,"RightHip",rot(-30*absorb,0,-6),RATE.defense,dt)
	set(char,"LeftHip",rot(-26*absorb,0,6),RATE.defense,dt)
	set(char,"RightKnee",rot(-48*absorb,0,0),RATE.defense,dt)
	set(char,"LeftKnee",rot(-42*absorb,0,0),RATE.defense,dt)
end
-- One entry point that decides which authored pose describes this frame. The
-- priority order is the whole presentation contract: a defeated body settles, a
-- grounded body stays grounded, an airborne reaction keeps its trajectory, and
-- everything else is attack, guard, landing or locomotion.
-- `clock` carries locally measured attack/reaction elapsed times.
function Motion.present(char,actor,clock,dt)
	local now=elapsedTime
	local elapsed=clock or {}
	local swinging=actor.attackName~=nil and (actor.state=="Startup" or actor.state=="Active" or actor.state=="Recovery")
	if (actor.health or 1)<=0 then
		setFamily(char,"ko")
		Motion.ko(char,actor.koStyle,dt)
		return "ko"
	end
	if actor.groundPose~=nil and actor.airborne~=true then
		setFamily(char,"ground")
		local subject=table.clone(actor)
		subject.reactionElapsed=elapsed.reactionElapsed
		Motion.defense(char,subject,dt)
		return "ground"
	end
	setFamily(char,"air")
	if actor.reaction and actor.airborne then
		local subject=table.clone(actor)
		subject.reactionElapsed=elapsed.reactionElapsed
		Motion.locomotion(char,0,true,actor.velocity,actor.fighterId,dt,subject,now)
		return "air reaction"
	end
	setFamily(char,"defense")
	if actor.state=="Dodging" or actor.reaction then
		local subject=table.clone(actor)
		subject.reactionElapsed=elapsed.reactionElapsed
		Motion.defense(char,subject,dt)
		return "defense"
	end
	setFamily(char,"guard")
	if actor.state=="Guarding" then
		Motion.guard(char,actor.guardImpact or 0,actor.fighterId,dt)
		return "guard"
	end
	-- Landing compression is checked before the attack so its family is correct;
	-- a hard landing absorbs visibly, a soft one barely interrupts the flow.
	if actor.landing then
		setFamily(char,"landing")
		Motion.land(char,actor,actor.fighterId,if actor.landStrong then 1 else .45,dt)
		return "landing"
	end
	setFamily(char,"attack")
	if swinging then
		Motion.pose(char,actor.attackName,elapsed.attackElapsed or 0,actor.fighterId,dt)
		return "attack"
	end
	setFamily(char,"locomotion")
	Motion.locomotion(char,actor.speed or 0,actor.airborne,actor.velocity,actor.fighterId,dt,actor,now)
	return "locomotion"
end
-- One entry point for the idle / walk / run / strafe presentation.
function Motion.locomotion(char,speed,airborne,velocity,fighterId,dt,actor,now)
	now=now or elapsedTime
	local subject=actor or {velocity=velocity}
	if airborne then
		airPose(char,subject,fighterId,dt,now)
	else
		locomotionPose(char,subject,fighterId,dt,now)
	end
end
-- Hard reset: only for a character switch, rematch, death or destruction. The
-- normal frame path damps towards its target and never calls this.
function Motion.reset(char)
	for key in joints do local m=motor(char,key);if m then m.Transform=CFrame.identity end end
end
Motion.clear=Motion.reset
return Motion
