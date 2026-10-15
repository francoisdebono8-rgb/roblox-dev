local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motor=require(script.Parent.Motor)
local Bangla=require(script.Parent.BanglaCombat)
local Combo=require(Shared.BanglaCombo)
local MoveGraphs=require(Shared.MoveGraphs)
local Config=require(Shared.Config)
-- Adapter: reaction/air/grab mechanics missing from the donor; ground M1
-- progression and all strike hit volumes/damage/feedback run through Bangla.
local Brawler={}
local airReactions={Launched=true,Juggled=true,Knockback=true,Knockdown=true,WallSplat=true,Spiked=true}
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
 -- A guard break or channel interrupt already set a longer stun: the melee
 -- reaction that follows keeps it instead of shortening it to the move's own.
 duration=math.max(duration,(a.stunFloorUntil or 0)-c.now);a.stunFloorUntil=nil
 a.chainOpen=false;a.recoveryCancelAt=nil
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
		spec.chainTool=profile.chainTool;spec.depth=profile.depth or spec.depth;spec.damageScale=profile.damage;spec.offset=profile.offset or spec.offset;spec.width=profile.width or spec.width;spec.impulse=Vector3.new(spec.impulse.X,profile.impulseY or spec.impulse.Y,profile.impulseZ or spec.impulse.Z)
	end
 a.buffered=nil
 a.queuedLight=nil
 a.attackVariant=nil
 a.hitBlocked=false
 a.attackSerial=(a.attackSerial or 0)+1
 a.attackName=name;a.attackStarted=c.now;a.hitConfirmed=false;a.chainOpen=false;a.chainAt=c.now+1e9;a.guardHeld=false
 -- The swing must reach the client as fast as the contact it leads to.
 c.urgent=true
 local slamWindow=0
 if name=="Slam" then
  -- Size the descent so the active window provably ends on or near the floor.
  local drop=math.max(6,a.root.Position.Y-(c.match.origin.Y+3.4))
  -- The plunge starts from rest and accelerates at 320 studs/s² up to 118
  -- (Motor.descend): time that fall, not an instant 118, or the window ends in
  -- mid-air and the recovery hovers there.
  local reach=118*118/(2*320)
  local fall=if drop<=reach then math.sqrt(2*drop/320) else 118/320+(drop-reach)/118
  slamWindow=math.clamp(fall+.04,.28,1.1)
 elseif name=="WallDive" then
  -- The dive lasts as long as the flight to the opponent (92 studs/s).
  local gap=(a.target.root.Position-a.root.Position).Magnitude
  slamWindow=math.clamp(gap/88,.16,.5)
 end
 a.pending={kind="Brawl",name=name,spec=spec,hit=false,slamWindow=slamWindow,flow=a.nextFlow==true}
 if not a.nextFlow then a.flowStreak=0 end
 a.nextFlow=nil
 Bangla.begin(c,a,a.pending)
 a.travelRemaining=spec.travel
 local flat=a.root.CFrame.LookVector*Vector3.new(1,0,1)
 local delta=a.target.root.Position-a.root.Position;delta=delta*Vector3.new(1,0,1)
 if delta.Magnitude>.1 and delta.Magnitude<11 and (flat:Dot(delta.Unit)>.55 or a.locked) then flat=delta.Unit end
 -- Locked on, a strike started mid-run snaps the body to the opponent.
 if a.locked and delta.Magnitude>.1 and delta.Magnitude<11 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+delta.Unit) end
	local side=a.root.CFrame.RightVector*(spec.angle or 0)
	a.travelDirection=(flat+side).Unit;a.state="Startup";a.untilTime=c.now+spec.startup
 if spec.air or name=="Slam" then a.airHold=c.now+spec.startup+math.max(spec.active,slamWindow)+spec.recovery+.18 end
 -- Lateral routes leave an afterimage where the body was (a flash for Minato).
 if name=="FeintStep" or name=="AirSwitch" or name=="CircleStep" then
  c:pushImpact(a.root.Position,if a.fighterId=="Flashstep" then "quickstep" else "afterimage",false,{owner=a.id,fighter=a.fighterId})
 end
 if name=="WallDive" then a.airborne=true;a.airHold=c.now+spec.startup end
 Brawler.event(c,a,name)
 return true
end
-- Movement intent relative to the fighter's facing, read when a press lands:
-- this is what turns one string into a small move graph per character.
function Brawler.intent(a)
 -- A buffered press replays the direction it was pressed with.
 if a.intentOverride then return a.intentOverride[1],a.intentOverride[2] end
 local m=Vector3.new(a.move.X,0,a.move.Z)
 if m.Magnitude<.4 then return "neutral",0 end
 local l=a.root.CFrame:VectorToObjectSpace(m.Unit)
 local forward,side=-l.Z,l.X
 if forward<-.55 then return "back",0 end
 if math.abs(side)>.55 then return "side",if side>0 then 1 else -1 end
 if forward>.55 then return "forward",0 end
 return "neutral",0
end
-- Disengage branch: hop out of the string while a blade (Minato) or a pair of
-- shuriken (Itachi) covers the retreat. Ends the string; buys space, not damage.
function Brawler.disengage(c,a,kind)
 Bangla.close(a.pending);a.pending=nil;a.attackName=nil;a.chainOpen=false;a.queuedLight=nil;a.buffered=nil
 local away=a.root.Position-a.target.root.Position;away=Vector3.new(away.X,0,away.Z)
 if away.Magnitude<.1 then away=-a.root.CFrame.LookVector end
 local minato=kind=="Kunai"
 a.state="Recovery";a.untilTime=c.now+(if minato then .26 else .32);a.recoveryCancelAt=a.untilTime
 a.hop={direction=away.Unit,remaining=if minato then 5 else 6,speed=if minato then 46 else 38}
 c:beginThrow(a,{kind=kind,release=if minato then .07 else .1,count=if minato then 1 else 2,interval=.07,
  fire=function(index,target)
   local spread=if minato then Vector3.zero else a.root.CFrame.RightVector*(if index==1 then -.7 else .7)
   c:projectile(a,target+spread,if minato then 96 else 84,22,2,if minato then "kunai" else "shuriken")
  end})
 Brawler.event(c,a,"Disengage")
 return true
end
function Brawler.request(c,a,action)
 local relevant=action=="Attack" or action=="Heavy" or action=="Grab" or action=="ThrowUp"
 if not relevant then return nil end
 -- Throw break: grab back right as you are seized and both are thrown apart.
 if action=="Grab" and a.reaction=="Grabbed" and a.grabbedBy and c.now-(a.grabbedAt or -10)<=Config.ThrowBreak then
  local g=a.grabbedBy
  Brawler.releaseGrab(g);Brawler.releaseGrab(a)
  local away=a.root.Position-g.root.Position;away=Vector3.new(away.X,0,away.Z)
  away=if away.Magnitude>.05 then away.Unit else -a.root.CFrame.LookVector
  for _,x in {a,g} do Bangla.close(x.pending);x.pending=nil;x.attackName=nil;x.chainOpen=false;x.state="Recovery";x.untilTime=c.now+.22;x.recoveryCancelAt=c.now+.12 end
  a.hop={direction=away,remaining=3.5,speed=30};g.hop={direction=-away,remaining=3.5,speed=30}
  c:pushImpact(a.root.Position:Lerp(g.root.Position,.5),"clash",true,{direction=away})
  Brawler.event(c,a,"ThrowBreak");c:cue(a,"THROW BREAK",.7);c:cue(g,"THROW BROKEN",.7)
  return true
 end
 if not Brawler.free(a,c.now) then return false,"Reacting" end
 -- Riposte: right after a clean block or a perfect dodge, a strike comes out
 -- at once and opens the string.
 if action=="Attack" and (a.riposteUntil or 0)>c.now and (a.state=="Guarding" or a.state=="Neutral" or a.state=="Dodging" or a.state=="Recovery") and not a.airborne then
  a.riposteUntil=0;a.guardHeld=false;a.state="Neutral";a.untilTime=c.now;a.evade=nil
  a.combo=1;a.lastAttack=c.now;a.queuedLight=nil
  c:cue(a,"RIPOSTE",.6);Brawler.event(c,a,"Riposte")
  return Brawler.start(c,a,"Riposte")
 end
 if a.wall then
  -- From a wall run a strike becomes a dive at the opponent: height and an
  -- angle the guard has to read.
  Motor.detach(a,c.now,false)
  if (action=="Attack" or action=="Heavy") and a.state=="Neutral" and a.target and a.target.health>0
   and (a.target.root.Position-a.root.Position).Magnitude<=Config.Wall.DiveRange then
   return Brawler.start(c,a,"WallDive")
  end
 end
 if a.grabVictim then
  if action=="Attack" or action=="Heavy" or action=="Grab" or action=="ThrowUp" then
   return Brawler.start(c,a,if action=="Heavy" or action=="ThrowUp" then "ThrowUp" else "Throw")
  end
 end
 local pending=a.pending
 local canChain=a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0)
 local close=a.target and (a.target.root.Position-a.root.Position).Magnitude<5.5
 local canDash=(a.state=="Dodging" and c.now>=a.untilTime-.23) or (a.state=="Rush" and c.now>=a.untilTime-.15)
  or (a.state=="Pursuit" and close and c.now-(a.pursuitStarted or 0)>=.12)
  or (a.state=="Neutral" and (a.rushArriveUntil or 0)>c.now)
 -- Rhythm: a chained press made on the beat (around the moment the chain
 -- opens, not mashed early during the swing) becomes a Flow strike.
 local pressAt=a.pressAt or c.now;a.pressAt=nil
 a.nextFlow=canChain and pressAt>=(a.chainAt or 0)-Config.Flow.Early and pressAt<=(a.chainAt or 0)+Config.Flow.Late
 -- Flying Thunder God arrival: the technique recovery is cancelled by a strike,
 -- so the teleport flows straight into an attack from the new angle.
 local canFlash=(a.state=="TechniqueRecovery" or a.state=="TechniqueActive") and (a.flashUntil or 0)>c.now
  and (a.pending==nil or (a.pending.kind=="Technique" and a.pending.spec.Id=="Flashstep"))
 if canFlash then
  a.flashUntil=0;a.state="Neutral";a.untilTime=c.now;a.pending=nil;pending=nil
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
   if pending and pending.kind=="Brawl" then
    -- Buffer the follow-up pressed during a swing, even before contact: a press
    -- made a few frames early must not be eaten. It only fires if the chain
    -- opens (the swing landed cleanly); after a whiff it simply expires, so no
    -- phantom combo runs through a recovery the player must respect.
    -- The stick is read at the press, not when the buffer fires: a route
    -- pressed early (toward + strike) must not turn neutral on release.
    local dir,sideSign=Brawler.intent(a)
    a.buffered={action=action,at=c.now,intent={dir,sideSign},expires=a.untilTime+(if a.state=="Startup" then pending.spec.active else 0)+.3}
    return true,"Buffered"
   end
   return false,"Committed"
  end
 if action=="Grab" then
  if a.airborne or (a.grabCooldown or 0)>c.now then return false,"Grab unavailable" end
  a.grabCooldown=c.now+1.4;return Brawler.start(c,a,"Grab")
 end
 if action=="ThrowUp" then return false,"No grab" end
 -- Running taijutsu: out of a full sprint the strike becomes a flying kick
 -- and the heavy a sliding sweep.
 if not canChain and not canDash and a.state=="Neutral" and not a.airborne and a.sprinting and a.locomotion.Magnitude>30 then
  if action=="Attack" then a.combo=0;return Brawler.start(c,a,"FlyingKick") end
  if action=="Heavy" then return Brawler.start(c,a,"SlideSweep") end
 end
 if action=="Heavy" then
  if a.airborne then
   -- Lion Combo: after Shadow of the Dancing Leaf, the heavy is a barrage
   -- that ends in a heel drop driving the body into the floor.
   if (a.lionUntil or 0)>c.now and a.target and a.target.health>0 then
    a.lionUntil=0
    -- The flip over the body: the heel comes down from above it.
    local b=a.target
    local look=b.root.Position-a.root.Position;look=Vector3.new(look.X,0,look.Z)
    look=if look.Magnitude>.1 then look.Unit else a.root.CFrame.LookVector
    c:relocate(a,b.root.Position+Vector3.new(0,2.4,0)-look*1.2)
    a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+look)
    a.airborne=true
    local ok=Brawler.start(c,a,"Slam")
    if a.pending then a.pending.spec.damage=17;a.pending.spec.impulse=Vector3.new(0,-90,8);a.attackVariant="LionBarrage" end
    c:cue(a,"LION COMBO",.9);Brawler.event(c,a,"LionCombo")
    return ok
   end
   return Brawler.start(c,a,"Slam")
  end
  local heavyGraph=MoveGraphs[a.fighterId] or {}
  if canChain and a.combo==1 and heavyGraph.heavyAfterOne then a.combo=0;return Brawler.start(c,a,heavyGraph.heavyAfterOne) end
  if canChain and a.combo>=2 then a.combo=0;return Brawler.start(c,a,a.def.LauncherMove or "Launcher") end
  return Brawler.start(c,a,a.def.HeavyMove or "Heavy")
 end
 local graph=MoveGraphs[a.fighterId] or {}
 local routes=graph.routes or {}
 if a.airborne then
  -- Air grammar: after an air hit the stick picks the follow-up.
  if canChain and (a.airCombo or 0)>=1 and c.now-(a.lastAirAttack or 0)<=.8 then
   local dir,sideSign=Brawler.intent(a)
   local route=if dir=="forward" then routes.airUp elseif dir=="back" then routes.airDown elseif dir=="side" then routes.airSide else nil
   if route then
    a.angleSide=sideSign;a.airCombo=0;a.lastAirAttack=c.now
    Brawler.event(c,a,"Route");return Brawler.start(c,a,route)
   end
  end
  a.airCombo=if c.now-(a.lastAirAttack or 0)>.8 then 1 else (a.airCombo or 0)%2+1
  a.lastAirAttack=c.now;return Brawler.start(c,a,"Air"..a.airCombo)
 end
 -- A successful Read (Itachi) pays off with the graph's counter on the next press.
 if action=="Attack" and graph.readCounter and (a.counterUntil or 0)>c.now and not canChain then
  a.counterUntil=0;return Brawler.start(c,a,graph.readCounter)
 end
 -- Directional combo grammar: inside a confirmed string the stick picks the
 -- route. Toward the opponent launches, away goes low, sideways turns the
 -- angle; each fighter answers with its own move.
 if action=="Attack" and canChain then
  local dir,sideSign=Brawler.intent(a)
  local route=nil
  if dir=="forward" and a.combo>=2 then route=routes.up
  elseif dir=="back" and a.combo>=2 then route=routes.down
  elseif dir=="side" and a.combo>=1 then route=routes.side end
  if route and Attacks[route] then
   a.angleSide=sideSign;a.queuedLight=nil
   if not Attacks[route].chain then a.combo=0 end
   Brawler.event(c,a,"Route");Brawler.event(c,a,if dir=="forward" then "RouteUp" elseif dir=="back" then "RouteDown" else "RouteSide")
   return Brawler.start(c,a,route)
  end
 end
 -- The ground light step is resolved once per accepted press, so a buffered
 -- chain cannot advance the combo counter twice.
 local name=a.queuedLight
 if not name then
  name=Combo.next(a,c.now)
  a.queuedLight=name
 end
 -- Context finisher (Neji): with three chakra points closed, the third palm
 -- becomes the twin-palm thrust that throws the body away.
 if name=="Light3" and a.def.GentleFist and a.target and (a.target.tenketsuUntil or 0)>c.now and (a.target.tenketsu or 0)>=3 then
  a.queuedLight=nil;return Brawler.start(c,a,"PalmThrust")
 end
 return Brawler.start(c,a,if canDash then "DashAttack" else name)
end
-- What a fighter's own version of a route adds on contact.
function Brawler.routePayoff(c,a,b,p)
 local graph=MoveGraphs[a.fighterId]
 local kind=graph and graph.onRoute and graph.onRoute[p.name]
 if not kind or b.health<=0 then return end
 local Techniques=require(script.Parent.Techniques)
 if kind=="bodySeal" then
  -- Minato: the rising kick leaves a short seal on the body: 2 follows it up.
  local entry=Techniques.plant(c,a,b.root.Position,Vector3.yAxis,b)
  entry.expires=c.now+1.8
  c:cue(a,"SEALED • 2 TO FOLLOW UP",.8)
 elseif kind=="floorSeal" then
  -- Minato: the sweep plants a marked kunai where the opponent falls.
  local floor=Vector3.new(b.root.Position.X,c.match.origin.Y,b.root.Position.Z)
  Techniques.plant(c,a,floor,Vector3.yAxis)
 elseif kind=="coverBlades" then
  -- Itachi: two shuriken follow the body up, keeping it in the air.
  c:schedule(c.now+.2,function()
   if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then return end
   c:beginThrow(a,{kind="Shuriken",release=.06,count=2,interval=.08,fire=function(index,target)
    local spread=a.root.CFrame.RightVector*(if index==1 then -.6 else .6)
    c:projectile(a,target+spread,92,30,1.5,"shuriken")
   end})
  end)
 elseif kind=="shadowLeaf" then
  -- Sasuke: Shadow of the Dancing Leaf. He shoots up after the rising body
  -- (a free chase); a heavy up there is the Lion Combo.
  a.lionUntil=c.now+2.1
  c:schedule(c.now+.12,function()
   if a.health<=0 or b.health<=0 or c.match.phase~="Duel" or not (b.reaction=="Launched" or b.reaction=="Juggled") then return end
   a.chakra+=Config.PursuitCost
   local from=a.root.Position
   if c:request(a,"Pursuit") then
    -- The shadow sticks to the rising body up to its apex, then hangs there.
    a.untilTime=c.now+.5;a.shadowUntil=a.untilTime;a.airHold=c.now+1.1
    c:pushImpact(from,"afterimage",false,{owner=a.id,fighter=a.fighterId})
    c:cue(a,"SHADOW OF THE DANCING LEAF • HEAVY = LION COMBO",1)
    Brawler.event(c,a,"ShadowLeaf")
   else a.chakra-=Config.PursuitCost end
  end)
 elseif kind=="tenketsu" then
  -- Neji: the low route strikes a second chakra point.
  Brawler.gentleFist(c,a,b,false)
 end
end
function Brawler.stopStyle(p)
 if p.name=="Slam" then return "slam" end
 if p.name=="Launcher" or p.name=="ThrowUp" then return "launcher" end
 if p.name=="Heavy" or p.name=="Throw" or p.name=="Light3" then return "finisher" end
 if p.spec and p.spec.air then return "air" end
 return "light"
end
-- Surfaces a flying body can be slammed into: the stadium wall, the field
-- trees and the boulders.
function Brawler.splatSurface(part)
 return part:GetAttribute("NinjaWall")==true or part.Name=="Field tree" or part.Name=="Cover"
end
-- Wall splat: a body carried into a wall hard enough sticks to it for a
-- moment. The attacker chooses: pursue (E), pin it with lighter hits or
-- blades, bounce it back out with a heavy blow, or reset. The defender can
-- tech off the wall on the impact (Q), spend a substitution, or take it.
function Brawler.splat(c,a,hit)
 local tune=Config.Wall
 local normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z)
 normal=if normal.Magnitude>.05 then normal.Unit else -a.root.CFrame.LookVector
 a.reaction="WallSplat";a.reactionUntil=c.now+tune.SplatTime;a.splatAt=c.now;a.splatNormal=normal;a.splatPart=hit.Instance
 a.wallSplats=(a.wallSplats or 0)+1
 a.reactionVelocity=Vector3.zero;a.groundPose="Splat";a.invulnerableUntil=c.now
 a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+normal)
 a.hitstopUntil=math.max(a.hitstopUntil or 0,c.now+.07)
 Brawler.event(c,a,"WallSplat")
 c:pushImpact(hit.Position,"wall",true,{normal=normal,owner=a.id})
 local source=a.reactionSource
 if source and source.health>0 then
  c.damageTag="wall";c:damage(source,a,tune.SplatDamage,false,false);c.damageTag=nil
  if c.match.phase~="Duel" then return end
  a.reaction="WallSplat";a.state="Neutral";a.untilTime=c.now
  source.pursuitUntil=math.max(source.pursuitUntil or 0,c.now+.8)
  Brawler.event(c,source,"WallConvert")
  c:cue(source,"WALL SPLAT • E PURSUE • HEAVY BOUNCE",.8)
 end
 c:cue(a,"WALL SPLAT • Q ON IMPACT TO TECH",.6)
end
-- Keep a splatted body on the wall a little longer (lighter hits, blades).
function Brawler.pin(c,b,duration,source)
 if b.reaction~="WallSplat" or (b.splatPins or 0)>=Config.Wall.PinMax then return false end
 b.splatPins=(b.splatPins or 0)+1
 b.reactionUntil=math.max(b.reactionUntil,c.now+duration)
 b.reactionVelocity=Vector3.zero
 c:pushImpact(b.root.Position,"pin",false,{owner=source and source.id,normal=b.splatNormal})
 if source then c:cue(source,"WALL PIN",.5) end
 return true
end
-- Hits on a pinned body: a heavy blow (heavy, launcher, Rasengan, dive) bounces
-- it off the wall back into the open for a fresh air phase; lighter hits pin
-- it for a short extension. Both are limited, so a wall is a phase, not a trap.
function Brawler.wallFollow(c,a,b,p)
 local heavy=p.name=="Heavy" or p.name=="Launcher" or p.name=="Slam" or p.name=="WallDive" or p.rasengan==true
 if heavy and not b.wallBounced then
  b.wallBounced=true
  local out=b.splatNormal or -a.root.CFrame.LookVector
  Brawler.react(c,b,"Launched",out*24+Vector3.new(0,46,0),1.05,a)
  b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+.07);a.hitstopUntil=math.max(a.hitstopUntil or 0,c.now+.04)
  a.pursuitUntil=c.now+1.1
  c:pushImpact(b.root.Position-out*1.2,"wallbounce",true,{normal=out,owner=b.id})
  Brawler.event(c,a,"WallBounce");c:cue(a,"WALL BOUNCE • E TO PURSUE",.9)
  return true
 end
 if not heavy and Brawler.pin(c,b,Config.Wall.PinTime,a) then Brawler.event(c,a,"WallPin");return true end
 return false
end
-- Clash: both strikes became active together, facing, in reach. Neither
-- lands; both fighters are pushed apart into a fresh close-range neutral.
function Brawler.clash(c,a,p)
 local b=a.target
 local q=b and b.pending
 if not q or q.kind~="Brawl" or (b.state~="Active" and b.state~="Startup") or b.target~=a or b.hitConfirmed or a.hitConfirmed then return false end
 if q.name=="Grab" or q.name=="Throw" or q.name=="ThrowUp" then return false end
 -- Simultaneous means the two active frames start within the clash window
 -- (the other swing may be a frame or two from becoming active).
 local other=if b.state=="Active" then (b.activeAt or 10) else b.untilTime
 if math.abs((a.activeAt or -10)-other)>Config.Clash.Window then return false end
 local delta=b.root.Position-a.root.Position
 local flat=Vector3.new(delta.X,0,delta.Z)
 if flat.Magnitude<.1 or delta.Magnitude>math.max(p.spec.range or 6,q.spec.range or 6)+1.5 then return false end
 if a.root.CFrame.LookVector:Dot(flat.Unit)<.4 or b.root.CFrame.LookVector:Dot(-flat.Unit)<.4 then return false end
 for _,x in {a,b} do
  Bangla.close(x.pending);x.pending=nil;x.attackName=nil;x.chainOpen=false;x.buffered=nil;x.queuedLight=nil;x.travelRemaining=0
  x.state="Recovery";x.untilTime=c.now+.24;x.recoveryCancelAt=c.now+.12
  x.hitstopUntil=math.max(x.hitstopUntil or 0,c.now+.08)
 end
 a.hop={direction=-flat.Unit,remaining=Config.Clash.Push,speed=30}
 b.hop={direction=flat.Unit,remaining=Config.Clash.Push,speed=30}
 c:pushImpact(a.root.Position:Lerp(b.root.Position,.5),"clash",true,{direction=flat.Unit})
 Brawler.event(c,a,"Clash");Brawler.event(c,b,"Clash")
 c:cue(a,"CLASH",.6);c:cue(b,"CLASH",.6)
 return true
end
-- Neji's Gentle Fist: palms reach the chakra network. Every palm drains
-- chakra, even through a guard; a clean one closes a chakra point, which slows
-- the victim's chakra recovery for a few seconds (stacks up to four).
function Brawler.gentleFist(c,a,b,guarded)
 local g=a.def.GentleFist
 local boost=if (a.awakenUntil or 0)>c.now and a.def.Awakening then (a.def.Awakening.Drain or 1) else 1
 b.chakra=math.max(0,b.chakra-(if guarded then g.GuardDrain else g.Drain)*boost)
 if not guarded then
  local points=if (b.tenketsuUntil or 0)>c.now then (b.tenketsu or 0) else 0
  b.tenketsu=math.min(g.MaxPoints,points+1);b.tenketsuUntil=c.now+g.Duration;b.tenketsuCut=g.RegenCut
 end
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
	-- Two strikes meeting in the same instant cancel out.
	if p.name~="Grab" and Brawler.clash(c,a,p) then return false end
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
  b.lastHurt=c.now; b.reaction="Grabbed";b.reactionUntil=c.now+.8;b.grabbedBy=a;a.grabVictim=b;b.grabbedAt=c.now
  a.grabUntil=c.now+.8;Brawler.event(c,a,"GrabHit");return true
 end
 if p.name=="Throw" or p.name=="ThrowUp" then
  c.damageTag=p.name;success=c:damage(a,b,spec.damage*(a.def.CombatDamage or 1),false,true);c.damageTag=nil
 end
 if not success or b.health<=0 then return success end
 if protected then return true end
 if a.def.GentleFist then Brawler.gentleFist(c,a,b,guarded) end
 if p.flow and not guarded and b.health>0 then
  a.flowStreak=(a.flowStreak or 0)+1
  b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+Config.Flow.Stop)
  c:pushImpact(b.root.Position,"flow",false,{owner=a.id,fighter=a.fighterId,count=a.flowStreak})
  c:cue(a,if a.flowStreak>1 then "FLOW ×"..a.flowStreak else "FLOW",.6)
  Brawler.event(c,a,"Flow")
 end
 if guarded then
  a.hitBlocked=true
  b.riposteUntil=c.now+.34
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
 -- What the body took: the client answers a head snap, a fold, a swept base.
 b.hitZone=spec.zone;b.hitKind=spec.kind;b.hitTwist=(spec.side or 1)*(if (a.angleSide or 0)~=0 and spec.orbit then a.angleSide else 1)
 Brawler.routePayoff(c,a,b,p)
 -- Move-specific weight: a light jab must not stop the fight, a slam must land hard.
 c:applyHitstop(a,b,Brawler.stopStyle(p),false)
 if b.reaction=="WallSplat" and Brawler.wallFollow(c,a,b,p) then Brawler.event(c,a,"Hit");return true end
 Brawler.react(c,b,spec.reaction,impulse,spec.stun,a)
 -- A combo that runs too long drops the body out of it (with wake-up cover).
 if (b.comboHits or 0)>=Config.ComboScaling.MaxHits and b.reaction~="Knockdown" then
  Brawler.react(c,b,"Knockdown",Vector3.new(impulse.X*.3,math.min(impulse.Y,0)-18,impulse.Z*.3),.5,a)
  c:cue(a,"COMBO LIMIT",.7);Brawler.event(c,a,"ComboLimit")
  return true
 end
 if spec.reaction=="Launched" then a.pursuitUntil=c.now+1.15;Brawler.event(c,a,"LaunchHit") end
 -- Knock-away -> chase -> re-entry: a body sent flying by a strike can be
 -- chased down (E) for a fresh exchange.
 if spec.reaction=="Knockback" and b.reaction=="Knockback" then
  a.pursuitUntil=math.max(a.pursuitUntil or 0,c.now+.8)
  c:cue(a,"KNOCK AWAY • E TO CHASE",.7)
 end
 if p.name=="Air1" or p.name=="Air2" then Brawler.event(c,a,"AirHit") end
 if p.name=="Slam" then Brawler.event(c,a,"SlamHit");a.airHold=0 end
 if p.name=="Throw" or p.name=="ThrowUp" then
  Brawler.event(c,a,"ThrowHit")
  -- Projection -> pursuit: the thrown body can be chased to where it lands.
  if p.name=="Throw" then a.pursuitUntil=math.max(a.pursuitUntil or 0,c.now+.9);c:cue(a,"THROWN • E TO CHASE",.8) end
 end
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
  -- Bound in sand: held in place until the burial or a substitution.
  if a.reaction=="Bound" and c.now<a.reactionUntil then
   a.hum:Move(Vector3.zero);a.root.AssemblyLinearVelocity=Vector3.zero
   return true
  end
  if c.now>=a.reactionUntil then
   if a.reaction=="WallSplat" and a.airborne and a.root.Position.Y>c.match.origin.Y+5 then
    -- Released high on the wall: drop to the floor, then wake up.
    local normal=a.splatNormal or Vector3.zero
    a.reaction="Knockdown";a.reactionUntil=c.now+.9;a.reactionVelocity=normal*7+Vector3.new(0,-6,0)
    a.groundPose="Knockdown";a.invulnerableUntil=c.now+1.1
   elseif a.reaction=="Knockdown" or a.reaction=="WallSplat" then a.reaction="Wakeup";a.reactionUntil=c.now+.24;a.invulnerableUntil=c.now+.24
   else
    a.reaction=nil;a.reactionVelocity=nil
    -- Fully recovered: drop the grounded presentation state with it.
    a.groundPose=nil
   end
  end
  if a.reaction then
   a.hum:Move(Vector3.zero);a.root.AssemblyLinearVelocity=Vector3.zero
   local velocity=a.reactionVelocity or Vector3.zero
   if a.reaction=="WallSplat" then
    -- Pinned: slide slowly down the wall instead of falling off it.
    velocity=Vector3.new(0,math.max(velocity.Y-30*dt,-11),0)
    local hit=Motor.flight(a,c,velocity*dt)
    if hit and hit.Normal.Y>.5 then velocity=Vector3.zero;a.airborne=false;a.landedAt=c.now end
   elseif airReactions[a.reaction] then
    velocity+=Vector3.new(0,-75*dt,0)
    local hit=Motor.flight(a,c,velocity*dt)
    if hit then
     if hit.Normal.Y>.5 and velocity.Y<0 and a.reaction=="Spiked" and not a.groundBounced then
      -- Ground bounce: the spike drives the body into the floor and it pops
      -- back up once, low, for a pick-up.
      a.groundBounced=true;a.reaction="Juggled";a.reactionUntil=c.now+.62
      velocity=Vector3.new(velocity.X*.3,30,velocity.Z*.3)
      c:pushImpact(a.root.Position-Vector3.new(0,2.6,0),"groundbounce",true,{victim=a.id})
      Brawler.event(c,a,"GroundBounce")
      a.reactionVelocity=velocity;return true
     end
     if hit.Normal.Y>.5 and velocity.Y<0 then
      if a.reaction=="Spiked" then a.reaction="Knockdown";a.groundPose="Knockdown";a.reactionUntil=c.now+.6;a.invulnerableUntil=c.now+.85 end
      if a.reaction=="Knockdown" then a.reactionUntil=math.min(a.reactionUntil,c.now+.55);Brawler.event(c,a,"LandedSlam") end
      -- The body is on the floor now: stop reporting it as airborne so the
      -- presentation plays the grounded pose instead of an air reaction.
      a.airborne=false
      a.landedAt=c.now
      velocity=Vector3.zero
     elseif math.abs(hit.Normal.Y)<.3 and Brawler.splatSurface(hit.Instance) and -velocity:Dot(hit.Normal)>=Config.Wall.SplatSpeed and (a.wallSplats or 0)<2 then
      Brawler.splat(c,a,hit)
      if c.match.phase~="Duel" or not a.reaction then return true end
      velocity=a.reactionVelocity or Vector3.zero
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
  local action,at,intent=a.buffered.action,a.buffered.at,a.buffered.intent;a.buffered=nil;a.pressAt=at
  a.intentOverride=intent
  Brawler.request(c,a,action)
  a.intentOverride=nil
 end
 return false
end
return Brawler
