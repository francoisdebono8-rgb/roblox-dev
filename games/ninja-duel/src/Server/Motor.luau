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
	-- Movement overhaul (Studio): the wall step pins the velocity to zero, so
	-- the hop's tangential carry was always nothing. Hand it the wall motion
	-- first: a wall jump keeps the run along the wall.
	if rebound and wall.motion then a.root.AssemblyLinearVelocity=wall.motion end
	if rebound and a.parkourDonor then
		local hopped=a.parkourDonor.rebound(wall.normal)
		if hopped and wall.mode=="run" and wall.motion then
			-- Off a run (Studio): the donor hop keeps a capped ~15 studs/s along
			-- the wall; the ninja jump keeps most of the run's own speed instead.
			local v=a.root.AssemblyLinearVelocity
			local run=Vector3.new(wall.motion.X,0,wall.motion.Z)*.85
			local flatV=Vector3.new(v.X,0,v.Z)
			local tangential=flatV-wall.normal*flatV:Dot(wall.normal)
			if run.Magnitude>tangential.Magnitude then a.root.AssemblyLinearVelocity=v-tangential+run end
		end
	elseif wall.mode=="run" and wall.motion then
		-- Running off the end of a wall run: the stride continues along it.
		local along=Vector3.new(wall.motion.X,0,wall.motion.Z)
		a.root.AssemblyLinearVelocity=along+wall.normal*6+UP*math.max(0,wall.motion.Y)
		a.locomotion=along
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
	local into=heading.Unit:Dot(-hit.Normal)
	if into<0.45 then return false end
	-- Movement overhaul: the entry decides the run. A shallow entry runs
	-- along the wall from its own speed (losing it gradually); a steep one
	-- runs up it, as high as the entry speed carries (brief §9).
	local v=a.root.AssemblyLinearVelocity
	local entry=math.max(Vector3.new(v.X,0,v.Z).Magnitude,(a.locomotion or Vector3.zero).Magnitude)
	local mode=if into<0.8 then "run" else "climb"
	local along=heading-hit.Normal*heading:Dot(hit.Normal)
	a.wall={part=hit.Instance,normal=hit.Normal,untilTime=now+Config.Wall.MaxTime,mode=mode,startAt=now,
		speed=math.max(entry,Config.Wall.SideSpeed),tangent=if along.Magnitude>.05 then along.Unit else nil,
		rise=math.clamp(entry*.55,12,34)}
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
	if not hit or hit.Normal:Dot(wall.normal)<0.72 or (hit.Instance~=wall.part and not hit.Instance:GetAttribute("NinjaWall")) then
		Motor.detach(a,now,false);return false
	end
	-- Studio: the courtyard wall is a ring of segments. Running along it crosses
	-- seams; the next segment (same family, a few degrees off) is the same wall.
	if hit.Instance~=wall.part then wall.part=hit.Instance;wall.normal=hit.Normal end
	local into=math.max(0,flat(a.move):Dot(-wall.normal))
	local side=flat(a.move)+wall.normal*into
	local motion=side*Config.Wall.SideSpeed+UP*Config.Wall.RiseSpeed*math.max(0.2,into)
	local t=now-(wall.startAt or now)
	if wall.mode=="run" and wall.tangent then
		-- Along the wall (re-projected on its surface: the arena wall curves),
		-- the speed fading, a small arc up then down; spent, the body drops.
		local n=hit.Normal
		local tangent=wall.tangent-n*wall.tangent:Dot(n)
		tangent=if tangent.Magnitude>.05 then tangent.Unit else wall.tangent
		wall.tangent=tangent
		local speed=wall.speed*math.exp(-.9*t)
		if speed<14 or (t>.35 and Motor.grounded(a,c)) then Motor.detach(a,now,false);return false end
		-- Studio: from a ground entry the old +8 arc never left the floor (a lean
		-- along the ground; the humanoid snaps back near the floor). A real arc up,
		-- then down as the speed runs out.
		motion=tangent*speed+UP*math.max(-12,26-28*t)
	elseif wall.mode=="climb" then
		-- Up the wall as high as the entry carried it, sideways a little;
		-- out of speed, the body falls off.
		local rise=(wall.rise or Config.Wall.RiseSpeed)-20*t
		if rise<-6 then Motor.detach(a,now,false);return false end
		motion=side*Config.Wall.SideSpeed*.5+UP*rise
	end
	wall.motion=motion
	local target=hit.Position+wall.normal*Config.Wall.Clearance+motion*dt
	if target.Y>wall.part.Position.Y+wall.part.Size.Y*0.5+1 then Motor.detach(a,now,true);return false end
	local obstacle=workspace:Raycast(a.root.Position,target-a.root.Position,p)
	if obstacle and obstacle.Instance~=wall.part and not obstacle.Instance:GetAttribute("NinjaWall") then Motor.detach(a,now,false);return false end
	if wall.mode=="run" and wall.tangent then
		-- Running along it: the body faces the run, its side to the wall.
		local at=c:clamp(target)
		a.root.CFrame=CFrame.lookAt(at,at+wall.tangent)
		wall.side=if hit.Normal:Dot(a.root.CFrame.RightVector)<0 then 1 else -1
	else
		a.root.CFrame=CFrame.lookAt(c:clamp(target),c:clamp(target)-wall.normal)
	end
	a.root.AssemblyLinearVelocity=Vector3.zero
	a.hum.AutoRotate=false;a.hum:Move(Vector3.zero,false)
	a.locomotion=Vector3.new(motion.X,0,motion.Z)
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
-- Continuous aimed motion in three dimensions. The swept helper above teleports
-- the root along a line, which made chase and slam read as
-- advance -> correction -> advance. Kinetic motion instead accelerates a real
-- velocity towards the target and integrates it, so the server position and the
-- replicated velocity never disagree.
local function paramsFor(a,c)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={a.model,c.match.effects};params.RespectCanCollide=true
	return params
end
local function approach(current,target,delta)
	if target>current then return math.min(target,current+delta) end
	return math.max(target,current-delta)
end
function Motor.move(a,c,aim,dt)
	local velocity=a.root.AssemblyLinearVelocity
	local offset=aim.target-a.root.Position
	if offset.Magnitude<.02 then return 0 end
	local desired=offset.Unit*aim.speed
	local accel=aim.acceleration or 200
	local target=Vector3.new(
		approach(velocity.X,desired.X,accel*dt),
		approach(velocity.Y,desired.Y,accel*dt),
		approach(velocity.Z,desired.Z,accel*dt))
	local floor=c.match and c.match.origin.Y+3 or -math.huge
	-- With Studio physics live, the velocity set last frame has already moved the
	-- root; integrating it by hand as well doubled rush/chase speed and made them
	-- advance in visible jerks (measured natively). Hand integration is kept for a
	-- body nothing else steps (headless harness, a stalled root).
	local here=a.root.Position
	local last=a.kineticLast
	local live=last~=nil and c.now-last.at<.1 and (here-last.position).Magnitude>math.max(.01,last.speed*dt*.25)
	if live then
		local vy=if here.Y+target.Y*dt<floor then 0 else target.Y
		a.root.AssemblyLinearVelocity=Vector3.new(target.X,vy,target.Z)
		a.fallSpeed=if vy<0 then math.max(a.fallSpeed or 0,-vy) else 0
		a.kineticLast={at=c.now,position=here,speed=target.Magnitude}
		return Vector3.new(target.X*dt,0,target.Z*dt).Magnitude
	end
	-- Integrate the horizontal part by hand: server-owned actors must move even
	-- when no physics solver is stepping them. Vertical follows the same velocity
	-- unless the floor stops it, which also keeps grounded actors on the ground.
	local deltaPos=Vector3.new(target.X*dt,0,target.Z*dt)
	local advance=deltaPos
	if deltaPos.Magnitude>.0001 then
		local hit=workspace:Raycast(a.root.Position,deltaPos,paramsFor(a,c))
		if hit then advance=deltaPos.Unit*math.max(0,hit.Distance-1.9) end
	end
	local nextY=a.root.Position.Y+target.Y*dt
	local blockedFloor=nextY<floor
	local y=if blockedFloor then floor else nextY
	local nextPosition=c:clamp(Vector3.new(a.root.Position.X+advance.X,y,a.root.Position.Z+advance.Z))
	a.root.CFrame=CFrame.new(nextPosition)*a.root.CFrame.Rotation
	a.root.AssemblyLinearVelocity=Vector3.new(target.X,if blockedFloor then 0 else target.Y,target.Z)
	a.fallSpeed=if target.Y<0 then math.max(a.fallSpeed or 0,-target.Y) else 0
	a.kineticLast={at=c.now,position=nextPosition,speed=target.Magnitude}
	return advance.Magnitude
end
-- Vertical partner of Motor.move, used by the slam plunge.
function Motor.descend(a,c,speed,dt)
	local velocity=a.root.AssemblyLinearVelocity
	local vertical=approach(velocity.Y,-math.abs(speed),320*dt)
	local delta=Vector3.new(0,vertical*dt,0)
	local hit=workspace:Raycast(a.root.Position,delta,paramsFor(a,c))
	if hit then
		a.root.CFrame=CFrame.new(c:clamp(hit.Position+hit.Normal*1.9))*a.root.CFrame.Rotation
		a.root.AssemblyLinearVelocity=Vector3.new(velocity.X,0,velocity.Z)
		return true
	end
	a.root.CFrame=CFrame.new(c:clamp(a.root.Position+delta))*a.root.CFrame.Rotation
	a.root.AssemblyLinearVelocity=Vector3.new(velocity.X,vertical,velocity.Z)
	return false
end
-- How close a walk may bring one body to the other (root to root).
Motor.SURFACE=3.4
function Motor.step(a,c,dt,now)
	local profile=Config.Movement
 donor(a,c)
	if not a.wall then Motor.tryWall(a,c,now) end
	if Motor.stepWall(a,c,dt,now) then return false end
	local vertical=a.root.AssemblyLinearVelocity.Y
	if vertical<0 then a.fallSpeed=math.max(a.fallSpeed or 0,-vertical) end
	local grounded=Motor.grounded(a,c)
	if grounded and a.airborne and now>(a.takeoffUntil or 0) and a.root.AssemblyLinearVelocity.Y<=5 then
		a.airborne=false; a.airDodgeUsed=false; a.airHold=0; a.airSwingUsed=false; a.airRecoverUsed=false; a.airStringHits=0
		local falling=a.fallSpeed or 0;a.fallSpeed=0
		-- Only a real drop costs speed. A standard or sprint jump lands below
		-- HardLandVelocity and keeps its momentum straight into the next step.
		local hard=falling>profile.HardLandVelocity
		a.landUntil=if hard then now+profile.HardLandRecovery else nil
		a.model:SetAttribute("MovementLandedAt",now)
		a.model:SetAttribute("MovementHardLanding",hard)
		c:effect("Land dust",a.root.Position-Vector3.new(0,2.8,0),a.color,Vector3.new(3,0.15,3),0.15)
	end
	-- (User 28/10, recorded match: 15 airborne flickers of 0.1-0.2 s under a
	-- stud while running.) Coyote time: an uneven floor (a grass patch, a
	-- stone, a step) that misses the ground ray for a frame or two does not
	-- make the body airborne; a real drop (falling past 10 studs/s) or a
	-- jump (which sets airborne itself) does.
	if grounded then a.ungroundedAt=nil
	elseif not a.airborne then
		a.ungroundedAt=a.ungroundedAt or now
		if now-a.ungroundedAt>.12 or vertical< -10 then a.airborne=true;a.ungroundedAt=nil end
	end
 local movement,parkour=donor(a,c)
 a.grounded=grounded
 if parkour.step() then return false end
 local sprinting=movement.step(dt,grounded)
 -- Gravity fallback for server-owned actors with no client simulation. Real
 -- physics owns a falling root; this only pulls back a body that has stalled in
 -- the air, which is what used to leave a fighter hovering after a slam. When
 -- the solver already moved the root since the last step, applying it too would
 -- integrate gravity twice: a rocket hop, a crash landing, half the air time.
 local airY=a.root.Position.Y
 if not grounded and a.reaction==nil and not a.wall then
  local velocity=a.root.AssemblyLinearVelocity
  -- First airborne step only records: the solver gets one frame to show it is live.
  local stalled=a.fallbackAirY~=nil and math.abs(airY-a.fallbackAirY)<math.max(.005,math.abs(a.fallbackAirVY or 0)*dt*.25)
  if stalled then
   local fall=math.min(70,velocity.Y-Config.Movement.FallbackGravity*dt)
   a.root.CFrame=CFrame.new(c:clamp(a.root.Position+Vector3.new(0,fall*dt,0)))*a.root.CFrame.Rotation
   a.root.AssemblyLinearVelocity=Vector3.new(velocity.X,fall,velocity.Z)
  end
  a.fallbackAirY=a.root.Position.Y;a.fallbackAirVY=a.root.AssemblyLinearVelocity.Y
 else
  a.fallbackAirY=nil;a.fallbackAirVY=nil
 end
 local locomotion=a.locomotion
 -- The awakening's speed bonus (speedScale) is part of the limit: the donor
 -- movement already asks for it, and clamping it back here cancelled it.
 local limit=(if sprinting then profile.SprintSpeed*(a.def.SprintScale or 1) else a.def.Speed)*(a.speedScale or 1)
 if a.state=="Guarding" then limit=Config.GuardSpeed
 elseif a.state=="TechniqueChannel" then limit=Config.ChannelSpeed
 elseif a.state=="Stunned" or a.state=="Defeated" or a.state=="Dodging" or a.state=="Pursuit" or a.state=="Rush" then limit=0
 elseif a.state~="Neutral" then limit=profile.AttackWalkSpeed end
 -- Movement overhaul (Studio, real keys): a jump-in air strike with no air
 -- hold (nobody in reach) rides the leap: the attack walk cap braked a
 -- sprint leap from ~52 to ~12 studs/s mid-swing. It keeps its speed, never
 -- gains any.
 if a.airborne and (a.airHold or 0)<=now and ((a.pending and a.pending.spec and a.pending.spec.air) or (a.state=="Recovery" and a.airSwingUsed)) then
  limit=math.max(limit,(a.locomotion or Vector3.zero).Magnitude)
 end
 if a.aimIntent then
  -- Chase and slam supply their own continuous motion for this frame.
  Motor.move(a,c,a.aimIntent,dt)
  a.locomotion=Vector3.new(a.root.AssemblyLinearVelocity.X,0,a.root.AssemblyLinearVelocity.Z)
  a.hum.WalkSpeed=a.locomotion.Magnitude
  a.hum:Move(if a.locomotion.Magnitude>.01 then a.locomotion.Unit else Vector3.zero)
  a.model:SetAttribute("MovementBase","Kinetic")
  return grounded
 end
 if a.grabVictim then limit=math.min(limit,5) end
 if now<(a.landUntil or 0) then limit=math.min(limit,profile.HardLandSpeed) end
 -- Bodies do not collide (Combat:separate eases them apart): walking into the
 -- opponent stops at his surface instead of sliding round to his side, which
 -- also kept turning a held "toward" into "side" in the middle of a string.
 local other=a.target
 if other and other.health>0 and other.root and not a.airborne then
  local d=other.root.Position-a.root.Position
  local flat=Vector3.new(d.X,0,d.Z)
  if flat.Magnitude>.05 and flat.Magnitude<Motor.SURFACE and math.abs(d.Y)<4 then
   local n=flat.Unit
   local inward=locomotion:Dot(n)
   if inward>0 then locomotion-=n*inward*math.clamp((Motor.SURFACE-flat.Magnitude)/.6,0,1) end
  end
 end
	 if locomotion.Magnitude>limit then
	  if a.state~="Neutral" and limit==profile.AttackWalkSpeed and not a.airborne then
	   -- (Fluidity pass, user reference 28/10) A strike thrown on the move
	   -- does not brake the body to a walk in one frame: the run carries into
	   -- it and settles to the attack walk over ~0.1 s, the body keeps moving
	   -- under the blow instead of planting.
	   local excess=(locomotion.Magnitude-limit)*math.exp(-dt/.06)
	   locomotion=locomotion.Unit*(limit+excess)
	  else
	   locomotion=locomotion.Unit*limit
	  end
	 end
	 a.locomotion=locomotion
	 a.hum.WalkSpeed=locomotion.Magnitude
	 a.hum:Move(if locomotion.Magnitude>.01 then locomotion.Unit else Vector3.zero,false)
 a.model:SetAttribute("MovementBase","Place1")
	return grounded
end
return Motor
