local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motor=require(script.Parent.Motor)
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
function Brawler.react(c,a,kind,velocity,duration)
 Brawler.releaseGrab(a)
 a.reaction=kind;a.reactionUntil=c.now+duration;a.reactionVelocity=velocity
 a.pending=nil;a.buffered=nil;a.guardHeld=false;a.state="Neutral";a.untilTime=c.now
 a.locomotion=Vector3.zero
 if airReactions[kind] then a.airborne=true end
 if kind=="Knockdown" then a.invulnerableUntil=c.now+duration+.24 end
end
function Brawler.start(c,a,name)
 local spec=table.clone(Attacks[name]);spec.travel*=a.def.CombatTravel or 1
 a.buffered=nil
 a.attackName=name;a.attackStarted=c.now;a.hitConfirmed=false;a.chainOpen=false;a.guardHeld=false
 a.pending={kind="Brawl",name=name,spec=spec,hit=false}
 a.travelRemaining=spec.travel
 local flat=a.root.CFrame.LookVector*Vector3.new(1,0,1)
 local delta=a.target.root.Position-a.root.Position;delta=delta*Vector3.new(1,0,1)
 if delta.Magnitude>.1 and delta.Magnitude<11 and flat:Dot(delta.Unit)>.55 then flat=delta.Unit end
 a.travelDirection=flat.Unit;a.state="Startup";a.untilTime=c.now+spec.startup
 if name=="Air1" or name=="Air2" or name=="Slam" then a.airHold=c.now+spec.startup+spec.active+spec.recovery+.18 end
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
 local canDash=a.state=="Dodging" and c.now>=a.untilTime-.16
 if a.state~="Neutral" and a.state~="Guarding" and not canChain and not canDash then
  if pending and pending.kind=="Brawl" and (a.state=="Active" or a.state=="Recovery" or (a.state=="Startup" and c.now>=a.untilTime-.07)) then a.buffered={action=action,expires=c.now+.24} end
  return false,"Committed"
 end
 if action=="Grab" then
  if a.airborne or (a.grabCooldown or 0)>c.now then return false,"Grab unavailable" end
  a.grabCooldown=c.now+1.4;return Brawler.start(c,a,"Grab")
 end
 if action=="ThrowUp" then return false,"No grab" end
 if action=="Heavy" then
  if a.airborne then return Brawler.start(c,a,"Slam") end
  if canChain and a.combo>=2 then a.combo=4;return Brawler.start(c,a,"Launcher") end
  return Brawler.start(c,a,"Heavy")
 end
 if a.airborne then
  a.airCombo=if c.now-(a.lastAirAttack or 0)>.8 then 1 else (a.airCombo or 0)%2+1
  a.lastAirAttack=c.now;return Brawler.start(c,a,"Air"..a.airCombo)
 end
 a.combo=if c.now-a.lastAttack>1.1 then 1 else a.combo%4+1;a.lastAttack=c.now
 return Brawler.start(c,a,if canDash then "DashAttack" else "Light"..a.combo)
end
function Brawler.hit(c,a,p)
 local b=a.target;local spec=p.spec
 if p.name=="Throw" or p.name=="ThrowUp" then
  b=a.grabVictim
  if not b or b.health<=0 then return false end
  Brawler.releaseGrab(a)
  local direction=if a.move.Magnitude>.2 then a.move.Unit else a.root.CFrame.LookVector
  a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+direction)
 elseif not c:targetValid(a,b,spec.range,.05) then return false
 else
  local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={b.model}
  local box=a.root.CFrame*CFrame.new(0,0,-spec.range*.42)
  if #workspace:GetPartBoundsInBox(box,Vector3.new(spec.width,spec.height,spec.range),params)==0 then return false end
 end
 if p.name=="Grab" then
  if b.invulnerableUntil>c.now or b.grabbedBy or b.reaction=="Wakeup" then return false end
  Brawler.releaseGrab(b);b.pending=nil;b.state="Neutral";b.guardHeld=false
  b.lastHurt=c.now; b.reaction="Grabbed";b.reactionUntil=c.now+.8;b.grabbedBy=a;a.grabVictim=b
  a.grabUntil=c.now+.8;Brawler.event(c,a,"GrabHit");return true
 end
 local guarded=b.state=="Guarding" and b.chakra>0 and b.root.CFrame.LookVector:Dot((a.root.Position-b.root.Position).Unit)>.15
 local protected=b.state=="TechniqueChannel" and b.pending and not b.pending.spec.Interruptible
 local success=c:damage(a,b,spec.damage*(a.def.CombatDamage or 1),false,true)
 if not success or b.health<=0 then return success end
 if protected then return true end
 if guarded then
  Brawler.event(c,b,"GuardHit")
  if p.name=="Heavy" or p.name=="Slam" then b.chakra=math.max(0,b.chakra-25) end
  if b.chakra<=0 then Brawler.react(c,b,"GuardStun",Vector3.zero,.6);b.guardHeld=false
  else b.guardImpact=c.now+.15 end
  return true
 end
 local impulse=a.root.CFrame.LookVector*spec.impulse.Z+Vector3.yAxis*spec.impulse.Y
 Brawler.react(c,b,spec.reaction,impulse,spec.stun)
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
   else a.reaction=nil;a.reactionVelocity=nil end
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
      velocity=Vector3.zero
     elseif math.abs(hit.Normal.Y)<.2 and hit.Instance:GetAttribute("NinjaWall") then
      a.reaction="WallSplat";a.reactionUntil=c.now+.35;velocity=hit.Normal*10;Brawler.event(c,a,"WallSplat")
     end
    end
   else Motor.travel(a,c,velocity,velocity.Magnitude*dt);velocity*=math.exp(-dt*14) end
   a.reactionVelocity=velocity;return true
  end
 end
 local p=a.pending
 if p and p.kind=="Brawl" then
  if a.state=="Active" and not p.hit then
   p.hit=Brawler.hit(c,a,p);a.hitConfirmed=p.hit or a.hitConfirmed
  end
 end
 if a.buffered and c.now<=a.buffered.expires and a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt then
  local action=a.buffered.action;a.buffered=nil;Brawler.request(c,a,action)
 end
 return false
end
return Brawler
