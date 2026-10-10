local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motor=require(script.Parent.Motor)
local Bangla=require(script.Parent.BanglaCombat)
local Combo=require(Shared.BanglaCombo)
-- Adapter: reaction/air/grab mechanics missing from the donor; ground M1
-- progression and all strike hit volumes/damage/feedback run through Bangla.
local Brawler={}
local airReactions={Launched=true,Juggled=true,Knockback=true,Knockdown=true,WallSplat=true}
function Brawler.free(a,now)
 return a.reaction==nil or now>=(a.reactionUntil or 0)
end
function Brawler.event(c,a,event)
 a.events=a.events or {};a.events[event]=(a.events[event] or 0)+1
 if c.match.onCombatEvent then c.match.onCombatEvent(a,event) end
end
function Brawler.releaseGrab(a)
 local b=a.grabVictim
 if b then b.grabbedBy=nil;b.reaction=nil;b.reactionUntil=0;a.grabVictim=nil end
 if a.grabbedBy then a.grabbedBy.grabVictim=nil;a.grabbedBy=nil end
end
function Brawler.react(c,a,kind,velocity,duration,source)
 Brawler.releaseGrab(a)
 Bangla.close(a.pending)
 a.reaction=kind;a.reactionUntil=c.now+duration;a.reactionVelocity=velocity
	 a.reactionSource=source
 a.pending=nil;a.buffered=nil;a.attackName=nil;a.guardHeld=false;a.state="Neutral";a.untilTime=c.now
 a.locomotion=Vector3.zero
 if airReactions[kind] then a.airborne=true end
 if kind=="Knockdown" then
  a.invulnerableUntil=c.now+duration+.24
  a.groundPose="Knockdown"
  -- Which side the body rolls onto, taken from the incoming direction.
  local from=a.hitFrom or Vector3.zAxis
  a.groundSide=if a.root.CFrame.RightVector:Dot(from)>=0 then 1 else -1
 end
 if kind=="WallSplat" then a.groundPose="Splat" end
 if not airReactions[kind] then a.groundPose=nil end
end
function Brawler.start(c,a,name)
 Bangla.close(a.pending)
 local spec=table.clone(Attacks[name]);spec.travel*=a.def.CombatTravel or 1
	local profile=a.def.AttackProfile and a.def.AttackProfile[name]
	if profile then
		spec.startup*=profile.startup or 1;spec.active*=profile.active or 1;spec.recovery*=profile.recovery or 1;spec.travel*=profile.travel or 1
		spec.travelTime=spec.startup+spec.active;spec.range=profile.range or spec.range;spec.angle=profile.angle
		spec.chainTool=profile.chainTool;spec.impulse=Vector3.new(spec.impulse.X,profile.impulseY or spec.impulse.Y,profile.impulseZ or spec.impulse.Z)
	end
 a.buffered=nil
 a.queuedLight=nil
 a.attackVariant=nil
 a.attackSerial=(a.attackSerial or 0)+1
 a.attackName=name;a.attackStarted=c.now;a.hitConfirmed=false;a.chainOpen=false;a.chainAt=c.now+1e9;a.guardHeld=false
 local slamWindow=0
 if name=="Slam" then
  -- Size the descent so the active window provably ends on or near the floor.
  local drop=math.max(6,a.root.Position.Y-(c.match.origin.Y+3.4))
  -- 118 studs/s is the plunge speed the slam uses at runtime.
  slamWindow=math.clamp(drop/118,.28,1.1)
 end
 a.pending={kind="Brawl",name=name,spec=spec,hit=false,slamWindow=slamWindow}
 Bangla.begin(c,a,a.pending)
 a.travelRemaining=spec.travel
 local flat=a.root.CFrame.LookVector*Vector3.new(1,0,1)
 local delta=a.target.root.Position-a.root.Position;delta=delta*Vector3.new(1,0,1)
 if delta.Magnitude>.1 and delta.Magnitude<11 and flat:Dot(delta.Unit)>.55 then flat=delta.Unit end
	local side=a.root.CFrame.RightVector*(spec.angle or 0)
	a.travelDirection=(flat+side).Unit;a.state="Startup";a.untilTime=c.now+spec.startup
 if name=="Air1" or name=="Air2" or name=="Slam" then a.airHold=c.now+spec.startup+math.max(spec.active,slamWindow)+spec.recovery+.18 end
 Brawler.event(c,a,name)
 return true
end
function Brawler.request(c,a,action)
 local relevant=action=="Attack" or action=="Heavy" or action=="Grab" or action=="ThrowUp"
 if not relevant then return nil end
 if not Brawler.free(a,c.now) then return false,"Reacting" end
 if a.wall then Motor.detach(a,c.now,false) end
 if a.grabVictim then
  if action=="Attack" or action=="Heavy" or action=="Grab" or action=="ThrowUp" then
   return Brawler.start(c,a,if action=="Heavy" or action=="ThrowUp" then "ThrowUp" else "Throw")
  end
 end
 local pending=a.pending
 local canChain=a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0)
 local canDash=a.state=="Dodging" and c.now>=a.untilTime-.23
 -- Flying Thunder God arrival: the technique recovery is cancelled by a strike,
 -- so the teleport flows straight into an attack from the new angle.
 local canFlash=(a.state=="TechniqueRecovery" or a.state=="TechniqueActive") and (a.flashUntil or 0)>c.now and a.pending==nil
 if canFlash then
  a.flashUntil=0;a.state="Neutral";a.untilTime=c.now
  local gap=(a.target.root.Position-a.root.Position).Magnitude
  if action=="Heavy" then
   if a.airborne then return Brawler.start(c,a,"Slam") end
   return Brawler.start(c,a,"Launcher")
  end
  if action=="Attack" then
   if a.airborne then a.airCombo=1;a.lastAirAttack=c.now;return Brawler.start(c,a,"Air1") end
   a.combo=1;a.lastAttack=c.now
   return Brawler.start(c,a,if gap>5.5 then "DashAttack" else "Light1")
  end
 end
  if a.state~="Neutral" and a.state~="Guarding" and not canChain and not canDash then
   if pending and pending.kind=="Brawl" and a.hitConfirmed then
    -- Buffer the follow-up, but only behind a swing that actually connected.
    -- Waiting for the open chain felt sticky; buffering a whiffed swing would
    -- queue a phantom combo through a recovery the player is meant to respect.
    a.buffered={action=action,expires=c.now+.32}
    return true,"Buffered"
   end
   return false,"Committed"
  end
 if action=="Grab" then
  if a.airborne or (a.grabCooldown or 0)>c.now then return false,"Grab unavailable" end
  a.grabCooldown=c.now+1.4;return Brawler.start(c,a,"Grab")
 end
 if action=="ThrowUp" then return false,"No grab" end
 if action=="Heavy" then
  if a.airborne then return Brawler.start(c,a,"Slam") end
  if canChain and a.combo>=2 then a.combo=0;return Brawler.start(c,a,"Launcher") end
  return Brawler.start(c,a,"Heavy")
 end
 if a.airborne then
  a.airCombo=if c.now-(a.lastAirAttack or 0)>.8 then 1 else (a.airCombo or 0)%2+1
  a.lastAirAttack=c.now;return Brawler.start(c,a,"Air"..a.airCombo)
 end
 -- The ground light step is resolved once per accepted press, so a buffered
 -- chain cannot advance the combo counter twice.
 local name=a.queuedLight
 if not name then
  name=Combo.next(a,c.now)
  a.queuedLight=name
 end
 return Brawler.start(c,a,if canDash then "DashAttack" else name)
end
function Brawler.stopStyle(p)
 if p.name=="Slam" then return "slam" end
 if p.name=="Launcher" or p.name=="ThrowUp" then return "launcher" end
 if p.name=="Heavy" or p.name=="Throw" or p.name=="Light3" then return "finisher" end
 if p.name=="Air1" or p.name=="Air2" then return "air" end
 return "light"
end
function Brawler.hit(c,a,p)
 local b=a.target;local spec=p.spec
 if p.name=="Throw" or p.name=="ThrowUp" then
  b=a.grabVictim
  if not b or b.health<=0 then return false end
  Brawler.releaseGrab(a)
  local direction=if a.move.Magnitude>.2 then a.move.Unit else a.root.CFrame.LookVector
  a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+direction)
 end
 local success,guarded,protected
 if p.name~="Throw" and p.name~="ThrowUp" then
	if p.spec.chainTool and not p.chainToolFired then
		p.chainToolFired=true;c:projectile(a,b.root.Position,88,11,2,"needle");Brawler.event(c,a,"ChainTool")
	end
  -- Grab has no donor damage action; donor contact volume still validates it.
  if p.name=="Grab" then
   if not c:targetValid(a,b,spec.range,.05) then return false end
   local donor=p.donor
   donor.hitbox.CFrame=a.root.CFrame*CFrame.new(0,0,-2)
   local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={b.model}
   if #workspace:GetPartBoundsInBox(donor.hitbox.CFrame,donor.hitbox.Size,params)==0 then return false end
  else
   success,guarded,protected=Bangla.tryHit(c,a,p)
   if not success then return false end
  end
 end
 if p.name=="Grab" then
  if b.invulnerableUntil>c.now or b.grabbedBy or b.reaction=="Wakeup" then return false end
  Brawler.releaseGrab(b);b.pending=nil;b.state="Neutral";b.guardHeld=false
  b.lastHurt=c.now; b.reaction="Grabbed";b.reactionUntil=c.now+.8;b.grabbedBy=a;a.grabVictim=b
  a.grabUntil=c.now+.8;Brawler.event(c,a,"GrabHit");return true
 end
 if p.name=="Throw" or p.name=="ThrowUp" then
  success=c:damage(a,b,spec.damage*(a.def.CombatDamage or 1),false,true)
 end
 if not success or b.health<=0 then return success end
 if protected then return true end
 if guarded then
	 c:applyHitstop(a,b,"block",false)
  Brawler.event(c,b,"GuardHit")
  if p.name=="Heavy" or p.name=="Slam" then b.chakra=math.max(0,b.chakra-25) end
  if b.chakra<=0 then Brawler.react(c,b,"GuardStun",Vector3.zero,.6);b.guardHeld=false
	else
		b.guardImpact=c.now+.18
		local push=if p.name=="Heavy" or p.name=="Slam" or p.name=="Light3" then 1.15 else .42
		Motor.travel(b,c,a.root.CFrame.LookVector,push)
	end
  return true
 end
 local impulse=a.root.CFrame.LookVector*spec.impulse.Z+Vector3.yAxis*spec.impulse.Y
 -- Move-specific weight: a light jab must not stop the fight, a slam must land hard.
 c:applyHitstop(a,b,Brawler.stopStyle(p),false)
 Brawler.react(c,b,spec.reaction,impulse,spec.stun,a)
 if spec.reaction=="Launched" then a.pursuitUntil=c.now+1.15;Brawler.event(c,a,"LaunchHit") end
 if p.name=="Air1" or p.name=="Air2" then Brawler.event(c,a,"AirHit") end
 if p.name=="Slam" then Brawler.event(c,a,"SlamHit");a.airHold=0 end
 if p.name=="Throw" or p.name=="ThrowUp" then Brawler.event(c,a,"ThrowHit") end
 Brawler.event(c,a,"Hit");return true
end
function Brawler.step(c,a,dt)
 if a.buffered and c.now>a.buffered.expires then a.buffered=nil end
 if a.grabVictim then
  local b=a.grabVictim
  if c.now>=(a.grabUntil or 0) or a.health<=0 or b.health<=0 then Brawler.releaseGrab(a)
  else
   local pos=a.root.Position+a.root.CFrame.LookVector*2.6
   local delta=pos-b.root.Position
   local grip=b.root.Position+(if delta.Magnitude>.001 then delta.Unit*math.min(delta.Magnitude,26*dt) else Vector3.zero)
   b.root.CFrame=CFrame.lookAt(grip,a.root.Position);b.root.AssemblyLinearVelocity=Vector3.zero;b.hum:Move(Vector3.zero)
  end
 end
 if a.reaction then
  if a.reaction=="Grabbed" then return true end
  if c.now>=a.reactionUntil then
   if a.reaction=="Knockdown" or a.reaction=="WallSplat" then a.reaction="Wakeup";a.reactionUntil=c.now+.24;a.invulnerableUntil=c.now+.24
   else
    a.reaction=nil;a.reactionVelocity=nil
    -- Fully recovered: drop the grounded presentation state with it.
    a.groundPose=nil
   end
  end
  if a.reaction then
   a.hum:Move(Vector3.zero);a.root.AssemblyLinearVelocity=Vector3.zero
   local velocity=a.reactionVelocity or Vector3.zero
   if airReactions[a.reaction] then
    velocity+=Vector3.new(0,-75*dt,0)
    local hit=Motor.flight(a,c,velocity*dt)
    if hit then
     if hit.Normal.Y>.5 and velocity.Y<0 then
      if a.reaction=="Knockdown" then a.reactionUntil=math.min(a.reactionUntil,c.now+.55);Brawler.event(c,a,"LandedSlam") end
      -- The body is on the floor now: stop reporting it as airborne so the
      -- presentation plays the grounded pose instead of an air reaction.
      a.airborne=false
      a.landedAt=c.now
      velocity=Vector3.zero
     elseif math.abs(hit.Normal.Y)<.2 and hit.Instance:GetAttribute("NinjaWall") then
			 a.reaction="WallSplat";a.reactionUntil=c.now+.42;velocity=hit.Normal*8;Brawler.event(c,a,"WallSplat")
			 a.groundPose="Splat"
			 c:pushImpact(hit.Position,"wall",false)
			 local source=a.reactionSource
			 if source and source.health>0 then source.pursuitUntil=math.max(source.pursuitUntil or 0,c.now+.72);Brawler.event(c,source,"WallConvert");c:cue(source,"WALL CONVERT • PURSUE",.65) end
     end
    end
   else Motor.travel(a,c,velocity,velocity.Magnitude*dt);velocity*=math.exp(-dt*14) end
		 a.reactionVelocity=velocity;return true
  end
 end
 local p=a.pending
 if p and p.kind=="Brawl" then
  if a.state=="Active" and not p.hit then
   -- Re-check every active frame. A single early test used to mark the whole
   -- swing as a whiff, so a target that entered the volume one frame later
   -- took no damage from a visibly connected strike.
   p.hit=Brawler.hit(c,a,p) or nil;a.hitConfirmed=p.hit==true or a.hitConfirmed
  end
 end
	if a.buffered and c.now<=a.buffered.expires and a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt then
  local action=a.buffered.action;a.buffered=nil;Brawler.request(c,a,action)
 end
 return false
end
return Brawler
