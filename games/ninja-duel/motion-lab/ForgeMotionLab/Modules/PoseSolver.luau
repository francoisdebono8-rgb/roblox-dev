-- R15 anatomical solver reused from Ninja Duel / VelmoraMotionEngine (MIT ancestry).
-- Presentation only; no world physics/authority. Original dimensions kept.
local Solver={}
local rad=math.rad;local CF=CFrame.new;local ANG=CFrame.Angles;local IDENTITY=CFrame.identity
local legIK
local L1,L2=1.05,1.0
local ANKLE_Y=-2.6 -- rest ankle height relative to HumanoidRootPart centre
local function ori(o)
	if not o then return IDENTITY end
	return ANG(rad(-(o.pitch or 0)),rad(-(o.yaw or 0)),rad(-(o.roll or 0)))
end
local function armCF(side,a)
	a=a or {}
	local shoulder=ANG(rad(a.raise or 0),0,0)*ANG(0,0,rad((a.out or 0)*side))*ANG(0,rad((a.twist or 0)*side),0)
	return shoulder,ANG(rad(a.elbow or 0),rad((a.elbowTwist or 0)*side),0),ANG(rad(a.wrist or 0),0,rad((a.wroll or 0)*side))
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

-- Preserve the solved stance when a correction switches between planted IK and FK.
function Solver.freeLeg(spec,side)
 local pose=build(spec);local prefix=if side==1 then "Right" else "Left"
 local _,_,_,r11,r12,r13,_,r22,_,_,r32=pose[prefix.."Hip"]:GetComponents()
 local knee=select(1,pose[prefix.."Knee"]:ToEulerAnglesXYZ());local ankle=select(1,pose[prefix.."Ankle"]:ToEulerAnglesXYZ())
 return {lift=math.deg(math.atan2(r32,r22)),out=math.deg(math.asin(math.clamp(-r12,-1,1)))*side,twist=math.deg(math.atan2(r13,r11))*side,knee=-math.deg(knee),ankle=math.deg(ankle)}
end
function Solver.footTarget(spec,side)
 local pose=build(spec);local prefix=if side==1 then "Right" else "Left"
 local hip=pose.Root*CF(.5*side,-.55,0)*pose[prefix.."Hip"]
 local ankle=hip*Vector3.new(0,-L1,0)+(hip.Rotation*pose[prefix.."Knee"])*Vector3.new(0,-L2,0)
 return {x=ankle.X-.5*side,y=ankle.Y-ANKLE_Y,z=ankle.Z,yaw=0,toe=0}
end
Solver.build=build
return Solver
