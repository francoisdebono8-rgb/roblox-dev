-- Server movement authority. This module owns locomotion, landing and safe
-- action travel; AI and human actors use the same movement profile.
local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)
local Place1Movement=require(script.Parent.Place1Movement)
local Place1Parkour=require(script.Parent.Place1Parkour)
-- This adapter retains swept action travel and the NinjaWall extension only.
-- Place1 owns free locomotion/jump/air steering/mantle/wall-hop at runtime.
local Motor={}
local function donor(a,c)
 if not a.movementDonor then a.movementDonor=Place1Movement.new(a,c);a.parkourDonor=Place1Parkour.new(a,c) end
 return a.movementDonor,a.parkourDonor
end
function Motor.reset(a)
 if a.parkourDonor then a.parkourDonor.reset() end
 a.movementDonor=nil;a.parkourDonor=nil
end
local UP=Vector3.yAxis
local function flat(v) return Vector3.new(v.X,0,v.Z) end
function Motor.grounded(a,c)
	local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances={a.model,c.match.effects}
	p.RespectCanCollide=true
	return workspace:Raycast(a.root.Position,Vector3.new(0,-3.6,0),p)~=nil
end
function Motor.jump(a,c,now)
 local movement,parkour=donor(a,c)
 if parkour.jump() then return true end
 return movement.jump(Motor.grounded(a,c))
end
function Motor.detach(a,now,rebound)
	local wall=a.wall
	if not wall then return false end
	a.wall=nil; a.wallNext=now+Config.Wall.ReattachDelay
	if rebound then a.wallJumpUntil=now+0.22 end
	if rebound and a.parkourDonor then a.parkourDonor.rebound(wall.normal)
 else a.root.AssemblyLinearVelocity=wall.normal*12+UP*8 end
	a.airborne=true
	return true
end
function Motor.tryWall(a,c,now)
	if a.wall or now<(a.wallNext or 0) or a.move.Magnitude<0.25 or a.state~="Neutral" then return false end
	local heading=flat(a.move)
	if heading.Magnitude<0.25 then return false end
 local _,parkour=donor(a,c)
 local hit=parkour.wallSurface()
	if not hit or not hit.Instance:GetAttribute("NinjaWall") or math.abs(hit.Normal.Y)>0.18 then return false end
	if heading.Unit:Dot(-hit.Normal)<0.45 then return false end
	a.wall={part=hit.Instance,normal=hit.Normal,untilTime=now+Config.Wall.MaxTime}
	a.airborne=true;a.airDodgeUsed=false
	c:cue(a,"WALL RUN • SPACE REBOUND / C DETACH",0.8)
	return true
end
function Motor.stepWall(a,c,dt,now)
	local wall=a.wall
	if not wall then return false end
	if now>=wall.untilTime or not wall.part.Parent or a.state=="Stunned" or a.state=="Defeated" then
		Motor.detach(a,now,false);return false
	end
	local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances={a.model,c.match.effects};p.RespectCanCollide=true
	local hit=workspace:Raycast(a.root.Position, -wall.normal*Config.Wall.Detect,p)
	if not hit or hit.Instance~=wall.part or hit.Normal:Dot(wall.normal)<0.72 then
		Motor.detach(a,now,false);return false
	end
	local into=math.max(0,flat(a.move):Dot(-wall.normal))
	local side=flat(a.move)+wall.normal*into
	local motion=side*Config.Wall.SideSpeed+UP*Config.Wall.RiseSpeed*math.max(0.2,into)
	local target=hit.Position+wall.normal*Config.Wall.Clearance+motion*dt
	if target.Y>wall.part.Position.Y+wall.part.Size.Y*0.5+1 then Motor.detach(a,now,true);return false end
	local obstacle=workspace:Raycast(a.root.Position,target-a.root.Position,p)
	if obstacle and obstacle.Instance~=wall.part then Motor.detach(a,now,false);return false end
	a.root.CFrame=CFrame.lookAt(c:clamp(target),c:clamp(target)-wall.normal)
	a.root.AssemblyLinearVelocity=Vector3.zero
	a.hum.AutoRotate=false;a.hum:Move(Vector3.zero,false)
	a.locomotion=side*Config.Wall.SideSpeed
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
-- Full 3D swept travel used by chase and controlled victim trajectories.
function Motor.flight(a,c,delta)
 if delta.Magnitude<.001 then return nil end
 local params=c:rayParams(true);params.RespectCanCollide=true
 local hit=workspace:Raycast(a.root.Position,delta.Unit*(delta.Magnitude+1.4),params)
 local movement=if hit then delta.Unit*math.max(0,hit.Distance-1.4) else delta
 local target=c:clamp(a.root.Position+movement)
 -- Root centre stays above the floor; actor body geometry is cosmetic.
 a.root.CFrame=CFrame.new(target)*a.root.CFrame.Rotation
 a.root.AssemblyLinearVelocity=Vector3.zero
 return hit
end
function Motor.step(a,c,dt,now)
	local profile=Config.Movement
 donor(a,c)
	if not a.wall then Motor.tryWall(a,c,now) end
	if Motor.stepWall(a,c,dt,now) then return false end
	local grounded=Motor.grounded(a,c)
	if grounded and a.airborne and now>(a.takeoffUntil or 0) and a.root.AssemblyLinearVelocity.Y<=5 then
		a.airborne=false; a.airDodgeUsed=false
		local falling=math.abs(a.root.AssemblyLinearVelocity.Y)
		a.landUntil=now+(if falling>profile.HardLandVelocity then profile.HardLandRecovery else profile.SoftLandRecovery)
		c:effect("Land dust",a.root.Position-Vector3.new(0,2.8,0),a.color,Vector3.new(3,0.15,3),0.15)
	end
	if not grounded then a.airborne=true end
 local movement,parkour=donor(a,c)
 a.grounded=grounded
 if parkour.step() then return false end
 local sprinting=movement.step(dt,grounded)
 local limit=a.hum.WalkSpeed
 if a.state=="Guarding" then limit=Config.GuardSpeed
 elseif a.state=="TechniqueChannel" then limit=Config.ChannelSpeed
 elseif a.state=="Stunned" or a.state=="Defeated" or a.state=="Dodging" or a.state=="Pursuit" then limit=0
 elseif a.state~="Neutral" then limit=profile.AttackWalkSpeed end
 if a.grabVictim then limit=math.min(limit,5) end
 if now<(a.landUntil or 0) then limit=math.min(limit,profile.HardLandSpeed) end
 a.hum.WalkSpeed=limit
 a.hum:Move(if limit>0 then a.move else Vector3.zero,false)
 a.locomotion=a.move*limit
 a.model:SetAttribute("MovementBase","Place1")
	return grounded
end
return Motor
