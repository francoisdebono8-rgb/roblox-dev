-- Server movement authority. This module owns locomotion, landing and safe
-- action travel; AI and human actors use the same movement profile.
local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)
local Motor={}
local UP=Vector3.yAxis
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function approach(from,to,maxDelta)
	local diff=to-from
	if diff.Magnitude<=maxDelta then return to end
	return from+diff.Unit*maxDelta
end
function Motor.grounded(a,c)
	local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances={a.model,c.match.effects}
	p.RespectCanCollide=true
	return workspace:Raycast(a.root.Position,Vector3.new(0,-3.6,0),p)~=nil
end
function Motor.jump(a,c,now)
	if not Motor.grounded(a,c) or now<(a.nextJump or 0) then return false end
	a.nextJump=now+Config.Movement.JumpCooldown
	a.root.AssemblyLinearVelocity=flat(a.root.AssemblyLinearVelocity)+UP*(Config.Movement.JumpVelocity*(a.def.JumpScale or 1))
	a.airborne=true; a.airDodgeUsed=false; a.takeoffUntil=now+0.18
	return true
end
function Motor.travel(a,c,direction,distance)
	local v=flat(direction)
	if v.Magnitude<0.01 or distance<=0 then return 0 end
	local start=a.root.Position
	local vector=v.Unit*distance
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={a.model,c.match.effects}
	params.RespectCanCollide=true
	local hit=workspace:Raycast(start,vector,params)
	local advance=if hit then math.max(0,hit.Distance-2.1) else vector.Magnitude
	local target=c:clamp(start+v.Unit*advance)
	a.root.CFrame=CFrame.new(target)*a.root.CFrame.Rotation
	return (target-start).Magnitude
end
function Motor.step(a,c,dt,now)
	local profile=Config.Movement
	local grounded=Motor.grounded(a,c)
	if grounded and a.airborne then
		a.airborne=false; a.airDodgeUsed=false
		local falling=math.abs(a.root.AssemblyLinearVelocity.Y)
		a.landUntil=now+(if falling>profile.HardLandVelocity then profile.HardLandRecovery else profile.SoftLandRecovery)
		c:effect("Land dust",a.root.Position-Vector3.new(0,2.8,0),a.color,Vector3.new(3,0.15,3),0.15)
	end
	if not grounded then a.airborne=true end
	local limit=a.def.Speed
	if a.sprinting then limit=profile.SprintSpeed*(a.def.SprintScale or 1) end
	if a.state=="Guarding" then limit=Config.GuardSpeed
	elseif a.state=="TechniqueChannel" then limit=Config.ChannelSpeed
	elseif a.state=="Stunned" or a.state=="Defeated" then limit=0
	elseif a.state=="Dodging" or a.state=="Pursuit" then limit=0
	elseif a.state~="Neutral" then limit=profile.AttackWalkSpeed end
	if now<(a.landUntil or 0) then limit=math.min(limit,profile.HardLandSpeed) end
	local desired=flat(a.move)
	if desired.Magnitude>1 then desired=desired.Unit end
	desired*=limit
	local rate=if grounded then (if desired.Magnitude> a.locomotion.Magnitude then profile.GroundAcceleration else profile.GroundDeceleration) else profile.AirAcceleration*(a.def.AirControlScale or 1)
	a.locomotion=approach(a.locomotion,desired,rate*dt)
	a.hum.WalkSpeed=a.locomotion.Magnitude
	a.hum:Move(if a.locomotion.Magnitude>0.05 then a.locomotion.Unit else Vector3.zero,false)
	if a.state=="Dodging" or a.state=="Pursuit" then a.hum:Move(Vector3.zero,false) end
	return grounded
end
return Motor
