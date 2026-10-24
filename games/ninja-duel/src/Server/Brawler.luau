local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Motor=require(script.Parent.Motor)
local Bangla=require(script.Parent.BanglaCombat)
local MoveGraphs=require(Shared.MoveGraphs)
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
-- Bodies that are not actors (Naruto's shadow clones): strikes they carry
-- out, strikes they take first, strikes aimed at them.
local Bodies=require(script.Parent.Bodies)
-- Adapter: reaction/air/grab mechanics missing from the donor; all strike hit
-- volumes/damage/feedback run through Bangla. String progression is Ninja
-- Duel's own (confirmed hits, below), no longer the donor's press counter.
local Brawler={}
-- A fighter module's own route payoffs (MoveGraphs onRoute kinds), e.g.
-- Naruto's "uzumaki" (Server/Legion).
Brawler.payoffs={}
local airReactions={Launched=true,Juggled=true,Knockback=true,Knockdown=true,WallSplat=true,Spiked=true}
local TUNE=Config.Combo
local UP=Vector3.yAxis
local function flatUnit(v)
 local f=Vector3.new(v.X,0,v.Z)
 return if f.Magnitude>.01 then f.Unit else nil
end
-- The move graph this actor fights with: its skill build's copy when it has
-- one (Combat:add), otherwise the canonical MoveGraphs entry.
function Brawler.graph(a)
 return a.graph or MoveGraphs[a.fighterId]
end
-- The strike a riposte (or a counter stance's answer) comes out as: the
-- fighter's own gesture (MoveGraphs riposte: Madara's pommel, Hashirama's
-- shoulder, Hiruzen's point), and while awake the one Awakening.Riposte
-- names for the stick held now (forward/back/side, `any` otherwise).
function Brawler.riposteMove(c,a,base)
 local graph=Brawler.graph(a) or {}
 local move=base or graph.riposte or "Riposte"
 local aw=a.def.Awakening
 if aw and aw.Riposte and (a.awakenUntil or 0)>c.now then
  local dir=Brawler.intent(a)
  local pick=(dir and aw.Riposte[dir]) or aw.Riposte.any
  if pick and Attacks[pick] then move=pick;Brawler.event(c,a,"AwakenedRiposte") end
 end
 return if Attacks[move] then move else "Riposte"
end
function Brawler.free(a,now)
 return a.reaction==nil or now>=(a.reactionUntil or 0)
end
function Brawler.event(c,a,event)
 a.events=a.events or {};a.events[event]=(a.events[event] or 0)+1
 if c.match.onCombatEvent then c.match.onCombatEvent(a,event) end
end
-- Combo model (CORE_COMBAT_CONVERGENCE_2 §1). A string is counted in
-- CONFIRMED hits: a press, a startup, a buffered input or a whiff never
-- advances it.
--   a.combo / a.airCombo   confirmed hits of the current ground / air string
--   a.stringUntil / a.airStringUntil   until then a press from neutral still
--                          continues it (chain window plus Config.Combo.Grace)
--   a.stringAt             when its last hit was confirmed (a hit taken since
--                          breaks it)
--   pending.step           the count a chain move confirms if it connects
-- Light step = confirmed hits + 1 (third light ends the string); routes ask for
-- confirmed hits; a whiff, a blocked strike or a hit taken restarts at Light1.
function Brawler.chainWindow(c,a)
 return a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0)
end
function Brawler.stringAlive(c,a,air)
 local count=if air then a.airCombo else a.combo
 if (count or 0)<1 then return false end
 if air and not a.airborne then return false end
 if (a.lastHurt or -10)>((if air then a.airStringAt else a.stringAt) or -10) then return false end
 if Brawler.chainWindow(c,a) and (a.chainAir==true)==(air==true) then return true end
 return c.now<=((if air then a.airStringUntil else a.stringUntil) or 0)
end
function Brawler.breakString(a,air)
 if air then a.airCombo=0;a.airStringUntil=0 else a.combo=0;a.stringUntil=0 end
end
function Brawler.resetStrings(a)
 Brawler.breakString(a,false);Brawler.breakString(a,true)
end
-- The swing connected (cleanly, or into armour or a sand shield): it is the
-- string's next confirmed hit.
function Brawler.confirm(c,a,p)
 if p.spec.air then a.airCombo=p.step;a.airStringAt=c.now else a.combo=p.step;a.stringAt=c.now end
end
-- The swing's outcome is known (end of its active window): a clean chain hit
-- keeps its string alive for the chain window plus the grace; a whiff or a
-- blocked hit ends it, so the next press is an opener again.
function Brawler.settle(c,a,p)
 local air=p.spec.air==true
 if a.chainOpen then
  a.chainAir=air
  if air then a.airStringUntil=a.untilTime+TUNE.Grace else a.stringUntil=a.untilTime+TUNE.Grace end
 elseif p.spec.chain then
  Brawler.breakString(a,air)
 end
end
-- Directional intent, relative to the opponent (CORE_COMBAT_CONVERGENCE_2 §1.6):
-- "forward" (toward him), "back" (away), "side" (+1 to the right of the line to
-- him, -1 to the left), or nil for a weak push. Toward and away are wide cones
-- (Config.Combo.Toward/Away), so a camera a few degrees off still reads the
-- route the player meant.
function Brawler.classify(a,stick)
 local m=Vector3.new(stick.X,0,stick.Z)
 if m.Magnitude<TUNE.IntentStrong then return nil,0 end
 local line=a.target and a.target.root and flatUnit(a.target.root.Position-a.root.Position)
 line=line or flatUnit(a.root.CFrame.LookVector) or Vector3.new(0,0,-1)
 local u=m.Unit
 local along=u:Dot(line)
 if along>=TUNE.Toward then return "forward",0 end
 if along<=-TUNE.Away then return "back",0 end
 return "side",if u:Dot(line:Cross(UP))>=0 then 1 else -1
end
-- The directional memory: the latest strong push, sampled every frame and at
-- every packet, so a stick released (or crossing the threshold) a moment
-- before the press still picks the route it was pushed for.
function Brawler.observe(c,a)
 a.intentAt=c.now
 local dir,sideSign=Brawler.classify(a,a.move or Vector3.zero)
 if dir then a.intentMemory={dir=dir,side=sideSign,at=c.now} end
end
-- Movement intent read when a press lands: this is what turns one string into
-- a small move graph per character. The current strong push first, else the
-- latest strong push inside Config.Combo.IntentWindow, else neutral. A
-- buffered press replays its own intent (intentOverride); the AI sets one too.
function Brawler.intent(a,now)
 if a.intentOverride then return a.intentOverride[1],a.intentOverride[2] end
 local dir,sideSign=Brawler.classify(a,a.move or Vector3.zero)
 if dir then return dir,sideSign end
 local memory=a.intentMemory
 now=now or a.intentAt or 0
 if memory and now-memory.at<=TUNE.IntentWindow then return memory.dir,memory.side end
 return "neutral",0
end
-- Presses made while the body is committed wait for its outcome: a swing
-- before its contact is known, a chase or a dash before the arrival, a
-- teleport before it lands.
local function bufferable(a)
 local p=a.pending
 if p and p.kind=="Brawl" and (a.state=="Startup" or a.state=="Active") then return true end
 if a.state=="Pursuit" or a.state=="Rush" then return true end
 return p~=nil and p.kind=="Technique" and p.spec.Id=="Flashstep" and (a.state=="TechniqueChannel" or a.state=="TechniqueActive")
end
local function bufferExpiry(a)
 local p=a.pending
 local active=0
 if p and a.state=="Startup" and p.kind=="Brawl" then active=p.spec.active
 elseif p and a.state=="TechniqueChannel" then active=p.spec.Active or 0 end
 return a.untilTime+active+TUNE.Buffer
end
-- Re-engage (CORE_COMBAT_CONVERGENCE_2 §3) -----------------------------------
local REENTRY={name="dash",speed=1,arrive=3.6,angle=0,chase=.3}
function Brawler.reentry(a)
 local graph=Brawler.graph(a)
 return (graph and graph.reengage) or REENTRY
end
-- A chase is over once the body is within reach and no longer escaping faster
-- than an air strike follows (a launched body near its apex, a knocked-away
-- one, a grounded one).
function Brawler.chaseArrived(c,a)
 local b=a.target
 if not b or c.now-(a.pursuitStarted or c.now)<.1 then return false end
 if (b.root.Position-a.root.Position).Magnitude>4.6 then return false end
 local rising=if b.reaction and b.reactionVelocity then b.reactionVelocity.Y else 0
 return rising<=30 or not b.airborne
end
-- The re-entry windows in which a press is the arrival strike (dash attack on
-- the ground, the air string in the air) or the arrival heavy.
function Brawler.arrival(c,a)
 if a.state=="Dodging" then return c.now>=a.untilTime-.23 end
 if a.state=="Rush" then
  local r=a.rush
  if c.now>=a.untilTime-.15 then return true end
  if r and not r.line and a.target then
   local d=a.target.root.Position-a.root.Position
   return Vector3.new(d.X,0,d.Z).Magnitude<=(r.arrive or 3.6)+1.4
  end
  return false
 end
 if a.state=="Pursuit" then return Brawler.chaseArrived(c,a) end
 if (a.rushArriveUntil or 0)>c.now then return a.state=="Neutral" or (a.state=="Recovery" and a.arrivalRecovery==true) end
 return false
end
-- The closest planted (not flying, not body) seal of Minato's near the target.
function Brawler.nearSeal(c,a,b,radius)
 local best,bestGap
 for _,seal in require(script.Parent.Techniques).seals(c,a,c.now) do
  if not seal.flying and not seal.body then
   local d=seal.position-b.root.Position
   local gap=Vector3.new(d.X,0,d.Z).Magnitude
   if gap<=(radius or 12) and (not bestGap or gap<bestGap) then best,bestGap=seal.position,gap end
  end
 end
 return best
end
-- Where a dash arrives: a step short of the body on the centre line, an angle
-- beside it (fixed in the world at the start, so it tracks the body without
-- spiralling), or a point through it for a committed line.
function Brawler.rushGoal(a,r)
 local b=a.target
 local y=a.root.Position.Y
 local there=Vector3.new(b.root.Position.X,y,b.root.Position.Z)
 if r.offset then return there+r.offset end
 local line=flatUnit(b.root.Position-a.root.Position) or flatUnit(a.root.CFrame.LookVector) or Vector3.new(0,0,-1)
 if r.past then return there+line*r.past end
 return there-line*r.arrive
end
function Brawler.rushPlan(c,a,style,line)
 local tune=Config.Rush
 local r={style=style,speed=tune.Speed*(style.speed or 1),arrive=style.arrive or 3.6,recovery=style.recovery or tune.Recovery,from=a.root.Position}
 if line then
  r.line=line;r.goal=c:clamp(a.root.Position+line*tune.Reposition)
  return r
 end
 local b=a.target
 local toward=flatUnit(b.root.Position-a.root.Position) or flatUnit(a.root.CFrame.LookVector) or Vector3.new(0,0,-1)
 local right=toward:Cross(UP)
 local angle=style.angle or 0
 local sign=nil
 if style.sealAngle then
  -- A planted seal near the target pulls the re-entry onto its side.
  local seal=Brawler.nearSeal(c,a,b)
  if seal then
   sign=if (seal-b.root.Position):Dot(right)>=0 then 1 else -1
   angle=style.sealAngle;r.speed*=style.sealPull or 1;r.sealed=true
  end
 end
 if angle>0 then
  if not sign then
   local dir,stickSide=Brawler.classify(a,a.move or Vector3.zero)
   sign=if dir=="side" then stickSide else (a.rushSide or 1)
   -- With no side asked for, the angle alternates from one dash to the next.
   a.rushSide=-sign
   -- (shuffle: Naruto) not a plain alternation: an irregular side, and every
   -- third entry a wider angle.
   if style.shuffle and dir~="side" then
    a.rushCount=(a.rushCount or 0)+1
    sign=if (a.rushCount*3+1)%5<2 then 1 else -1
    if a.rushCount%3==0 then angle*=1.5 end
   end
  end
  local rad=math.rad(angle)
  r.offset=(-toward*math.cos(rad)+right*sign*math.sin(rad))*r.arrive
  r.side=sign
 end
 if style.past then r.past=style.past;r.commitAt=c.now+(style.commit or 0) end
 r.goal=Brawler.rushGoal(a,r)
 return r
end
-- The dash is over: a short recovery that converts at once into a strike, a
-- heavy or a grab (Brawler.arrival), and into guard / dodge / jump only after
-- Config.Rush.CancelAfter. Nobody answering it leaves a punishable gap.
function Brawler.arrive(c,a)
 local r=a.rush or {}
 a.rush=nil;a.aimIntent=nil
 -- The dash stops where it arrives: the body keeps a step of momentum, not
 -- the dash speed (measured in Studio: live physics slid the root 10-25 studs
 -- past the opponent through the whole recovery).
 Brawler.brake(a,Config.Rush.Carry or 8)
 local recovery=r.recovery or Config.Rush.Recovery
 c:setState(a,"Recovery",recovery)
 a.recoveryCancelAt=c.now+math.min(Config.Rush.CancelAfter,recovery)
 a.arrivalRecovery=true
 a.rushArriveUntil=c.now+Config.Rush.Arrive
 Brawler.event(c,a,"RushArrive")
end
-- Kill a kinetic burst (dash, chase) down to `carry` studs/s along its line.
function Brawler.brake(a,carry)
 local v=a.root.AssemblyLinearVelocity
 local flat=Vector3.new(v.X,0,v.Z)
 local keep=if flat.Magnitude>.1 then flat.Unit*math.min(flat.Magnitude,carry) else Vector3.zero
 a.root.AssemblyLinearVelocity=Vector3.new(keep.X,v.Y,keep.Z)
 a.locomotion=keep
end
-- Itachi's feint: guard or dodge during his dash stops it where he is; an
-- afterimage carries on the illusion of the approach.
function Brawler.feintRush(c,a)
 a.rush=nil;a.rushArriveUntil=0;a.aimIntent=nil
 Brawler.brake(a,0)
 c:setState(a,"Neutral",0)
 c:pushImpact(a.root.Position,"afterimage",false,{owner=a.id,fighter=a.fighterId,variant="feint"})
 Brawler.event(c,a,"RushFeint")
 c:cue(a,"FEINT",.5)
end
-- Pad re-engage: sprint + dodge with the stick toward a locked opponent at
-- mid range (Combat:request turns it into the re-engage).
function Brawler.dashIntent(c,a)
 if not a.sprinting or not a.locked or a.airborne or a.wall or a.def.SandFlicker then return false end
 local b=a.target
 if not b or b.health<=0 then return false end
 -- The current push (a dodge goes where the stick is now), or the bot's own.
 local dir=if a.intentOverride then a.intentOverride[1] else (Brawler.classify(a,a.move or Vector3.zero))
 if dir~="forward" then return false end
 local d=b.root.Position-a.root.Position
 return Vector3.new(d.X,0,d.Z).Magnitude>=(Brawler.reentry(a).minRange or Config.Rush.MinRange)
end
function Brawler.releaseGrab(a)
 local b=a.grabVictim
 if b then b.grabbedBy=nil;b.reaction=nil;b.reactionUntil=0;a.grabVictim=nil end
 if a.grabbedBy then a.grabbedBy.grabVictim=nil;a.grabbedBy=nil end
end
-- `cause` (optional): what threw the body (a move or technique name); a wall
-- the flight ends on reports it, so the client can say which blow did it.
function Brawler.react(c,a,kind,velocity,duration,source,cause)
 Brawler.releaseGrab(a)
 Bangla.close(a.pending)
 -- A guard break or channel interrupt already set a longer stun: the melee
 -- reaction that follows keeps it instead of shortening it to the move's own.
 duration=math.max(duration,(a.stunFloorUntil or 0)-c.now);a.stunFloorUntil=nil
 a.chainOpen=false;a.recoveryCancelAt=nil
 a.reaction=kind;a.reactionUntil=c.now+duration;a.reactionVelocity=velocity
	 a.reactionSource=source;a.reactionCause=cause
 a.pending=nil;a.buffered=nil;a.attackName=nil;a.guardHeld=false;a.state="Neutral";a.untilTime=c.now
 -- Hit out of it: his own strings and re-entry are over.
 Brawler.resetStrings(a);a.rush=nil;a.arrivalRecovery=nil;a.rushArriveUntil=0
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
 -- Any new strike drops a pending running-strike hand-back (it is for the
 -- run after the swing, not for the next blow of a string).
 a.strikeCarry=nil
 -- A strike another body may carry out (MoveGraphs proxy: Naruto's clones),
 -- or its solo / awakened form when there is no body for it.
 local proxy,kind
 name,proxy,kind=Bodies.route(c,a,name)
 local spec=table.clone(Attacks[name]);spec.travel*=a.def.CombatTravel or 1
	local profile=a.def.AttackProfile and a.def.AttackProfile[name]
	if profile then
		spec.startup*=profile.startup or 1;spec.active*=profile.active or 1;spec.recovery*=profile.recovery or 1;spec.travel*=profile.travel or 1
		spec.travelTime=spec.startup+spec.active;spec.range=profile.range or spec.range;spec.angle=profile.angle
		spec.zone=profile.zone or spec.zone;spec.kind=profile.kind or spec.kind
		spec.chainTool=profile.chainTool;spec.depth=profile.depth or spec.depth;spec.damageScale=profile.damage;spec.offset=profile.offset or spec.offset;spec.width=profile.width or spec.width;spec.impulse=Vector3.new(spec.impulse.X,profile.impulseY or spec.impulse.Y,profile.impulseZ or spec.impulse.Z)
		-- A weapon's reach: the step-in stops further out (Temari's iron fan).
		spec.contact=profile.contact or spec.contact
	end
 -- An awakening that quickens the body (Awakening.Recovery: Naruto's cloak).
 local awake=a.def.Awakening
 if awake and awake.Recovery and (a.awakenUntil or 0)>c.now then spec.recovery*=awake.Recovery end
 -- A strike that opens (no string alive) may be pushed at an enemy body.
 local opener=not Brawler.stringAlive(c,a,spec.air==true)
 a.buffered=nil
 a.attackVariant=nil
 a.hitBlocked=false
 a.attackSerial=(a.attackSerial or 0)+1
 -- String bookkeeping: a chain move records the count it confirms if it
 -- connects (the string continues only while it is alive); a string ender
 -- (third light, route, heavy, grab, slam) closes its string now.
 local air=spec.air==true
 local step=nil
 if spec.chain then
  if not Brawler.stringAlive(c,a,air) then Brawler.breakString(a,air) end
  step=((if air then a.airCombo else a.combo) or 0)+1
 else
  Brawler.breakString(a,air or name=="Slam")
 end
 a.arrivalRecovery=nil
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
 a.pending={kind="Brawl",name=name,spec=spec,hit=false,slamWindow=slamWindow,flow=a.nextFlow==true,step=step}
 if not a.nextFlow then a.flowStreak=0 end
 a.nextFlow=nil
 Bangla.begin(c,a,a.pending)
 a.travelRemaining=spec.travel
 local flat=a.root.CFrame.LookVector*Vector3.new(1,0,1)
 local delta=a.target.root.Position-a.root.Position;delta=delta*Vector3.new(1,0,1)
 if delta.Magnitude>.1 and delta.Magnitude<11 and (flat:Dot(delta.Unit)>.55 or a.locked) then flat=delta.Unit end
 -- The lock stays on the real fighter, but an opener pushed at one of his
 -- bodies (a shadow clone in reach) swings at it (Bodies.aim; Combat turns
 -- and steps toward it).
 local body=opener and not spec.air and Bodies.aim(c,a)
 if body then
  a.pending.aim=body
  local to=body.position-a.root.Position
  flat=Vector3.new(to.X,0,to.Z).Unit
 end
 -- Locked on, a strike started mid-run turns into the opponent during its
 -- startup (Combat:turnToward, bounded rate) instead of snapping in one frame.
	local side=a.root.CFrame.RightVector*(spec.angle or 0)
	a.travelDirection=(flat+side).Unit;a.state="Startup";a.untilTime=c.now+spec.startup
 if proxy then Bodies.bind(c,a,a.pending,proxy,kind) end
 if spec.air or name=="Slam" then
  -- The air hold carries a string that works (or the first swing of a jump,
  -- and the slam): mashed whiffs used to keep a body hovering a stud above the
  -- floor indefinitely (an AI duel showed four seconds of Air1/Air2 over a
  -- knocked-down opponent).
  -- Movement overhaul (Studio, real keys): a jump-in swing with nobody in
  -- reach keeps the jump's momentum and gravity (a sprint leap's air light
  -- froze at the apex, 58 studs/s to 0); the hold is for an air string at a
  -- body in reach.
  local tgt=a.target and a.target.root
  local gap=tgt and (tgt.Position-a.root.Position)
  local inReach=gap~=nil and Vector3.new(gap.X,0,gap.Z).Magnitude<=(spec.range or 5)+4 and math.abs(gap.Y)<10
  if name=="Slam" or (a.airCombo or 0)>=1 or (not a.airSwingUsed and inReach) then
   a.airHold=c.now+spec.startup+math.max(spec.active,slamWindow)+spec.recovery+.18
  end
  a.airSwingUsed=true
 end
 -- Lateral routes leave an afterimage where the body was (a flash for Minato).
 if name=="FeintStep" or name=="AirSwitch" or name=="CircleStep" then
  c:pushImpact(a.root.Position,if a.fighterId=="Flashstep" then "quickstep" else "afterimage",false,{owner=a.id,fighter=a.fighterId})
  -- Where the afterimage stays (a skill build's echo payoff turns it into a decoy).
  a.stepFrom=a.root.Position
 end
 if name=="WallDive" then a.airborne=true;a.airHold=c.now+spec.startup end
 Brawler.event(c,a,name)
 return true
end
-- Disengage branch: hop out of the string while a blade (Minato) or a pair of
-- shuriken (Itachi) covers the retreat. Ends the string; buys space, not damage.
function Brawler.disengage(c,a,kind)
 Bangla.close(a.pending);a.pending=nil;a.attackName=nil;a.chainOpen=false;a.buffered=nil
 Brawler.breakString(a,false)
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
 -- at once and opens a string (its contact is the string's first hit).
 if action=="Attack" and (a.riposteUntil or 0)>c.now and (a.state=="Guarding" or a.state=="Neutral" or a.state=="Dodging" or a.state=="Recovery") and not a.airborne then
  a.riposteUntil=0;a.guardHeld=false;a.state="Neutral";a.untilTime=c.now;a.evade=nil
  Brawler.breakString(a,false);a.lastAttack=c.now
  c:cue(a,"RIPOSTE",.6);Brawler.event(c,a,"Riposte")
  return Brawler.start(c,a,Brawler.riposteMove(c,a))
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
 local canChain=Brawler.chainWindow(c,a)
 -- Re-entry windows: the end of a dodge, a dash or a chase arrival.
 local canDash=Brawler.arrival(c,a)
 local reentry=canDash and a.state~="Dodging"
 local style=reentry and Brawler.reentry(a)
 -- Rhythm: a chained press made on the beat (around the moment the chain
 -- opens, not mashed early during the swing) becomes a Flow strike. A bonus
 -- only: an off-beat press chains just the same.
 local pressAt=a.pressAt or c.now;a.pressAt=nil
 a.nextFlow=canChain and pressAt>=(a.chainAt or 0)-Config.Flow.Early and pressAt<=(a.chainAt or 0)+Config.Flow.Late
 -- Flying Thunder God arrival: the technique recovery is cancelled by a strike,
 -- so the teleport flows straight into an attack from the new angle. The
 -- arrival strike opens a fresh string.
 local canFlash=(a.state=="TechniqueRecovery" or a.state=="TechniqueActive") and (a.flashUntil or 0)>c.now
  and (a.pending==nil or (a.pending.kind=="Technique" and a.pending.spec.Id=="Flashstep"))
 -- Rotation already repelled a strike and is winding down: the strike comes
 -- straight out of the spin as the counter.
 if action=="Attack" and (a.counterUntil or 0)>c.now and (a.rotationCounterUntil or 0)>c.now and (a.state=="TechniqueActive" or a.state=="TechniqueRecovery") then
  a.pending=nil;a.rotationUntil=0;c:setState(a,"Neutral",0)
  return Brawler.counterStart(c,a)
 end
 -- A strike pressed inside a counter stance (Read, Rotation) waits for the
 -- stance to pay off instead of being refused.
 if action=="Attack" and Brawler.counterStance(a) then a.counterQueued=c.now;return true,"Buffered" end
 if canFlash then
  a.flashUntil=0;a.state="Neutral";a.untilTime=c.now;a.pending=nil;pending=nil
  local gap=(a.target.root.Position-a.root.Position).Magnitude
  -- The arrival strike (Brawler.hit reads it: a chain carried through the jump).
  local function arrival(ok) a.flashStrike=a.attackSerial;return ok end
  if action=="Heavy" then
   if a.airborne then return arrival(Brawler.start(c,a,"Slam")) end
   return arrival(Brawler.start(c,a,"Launcher"))
  end
  if action=="Attack" then
   if a.airborne then Brawler.breakString(a,true);a.lastAirAttack=c.now;return arrival(Brawler.start(c,a,"Air1")) end
   Brawler.breakString(a,false);a.lastAttack=c.now
   return arrival(Brawler.start(c,a,if gap>5.5 then "DashAttack" else "Light1"))
  end
 end
 if a.state~="Neutral" and a.state~="Guarding" and not canChain and not canDash then
  if bufferable(a) then
   -- Buffer a press made before the outcome of the committed swing, chase,
   -- dash or teleport is known: a press made a few frames early is never
   -- eaten, yet it prepares nothing. It fires when the chain opens (the swing
   -- landed cleanly), on the arrival, or, after a whiff or a block, as a fresh
   -- opener once the full recovery is over. The direction is the one it was
   -- pressed with (or pushed while it waits): Brawler.step.
   local dir,sideSign=Brawler.intent(a)
   a.buffered={action=action,at=c.now,intent={dir,sideSign},explicit=a.intentOverride~=nil,expires=bufferExpiry(a)}
   return true,"Buffered"
  end
  return false,"Committed"
 end
 if action=="Grab" then
  if a.airborne or (a.grabCooldown or 0)>c.now then return false,"Grab unavailable" end
  a.grabCooldown=c.now+1.4;return Brawler.start(c,a,"Grab")
 end
 if action=="ThrowUp" then return false,"No grab" end
 -- Running taijutsu: out of a full sprint the opening strike is the
 -- fighter's own running entry (its DashAttack: Bee's shoulder, Kimimaro's
 -- elbow, Zabuza's handle...; MoveGraphs runStrike names a kicker's flying
 -- kick) and the heavy a sliding sweep. Movement overhaul (Studio, real
 -- keys): the swing carries the run's speed and, after its recovery, hands
 -- part of it back so the run continues (the heavy pays more). Openers only:
 -- the confirmed-hit invariant is untouched.
 if not canChain and not canDash and a.state=="Neutral" and not a.airborne and a.sprinting and a.locomotion.Magnitude>28 and (action=="Attack" or action=="Heavy") then
  local runSpeed=a.locomotion.Magnitude
  local runGraph=Brawler.graph(a) or {}
  local name=if action=="Heavy" then "SlideSweep" else (runGraph.runStrike or "DashAttack")
  if not Attacks[name] then name="FlyingKick" end
  local ok=Brawler.start(c,a,name)
  local p=a.pending
  if ok~=false and p and p.kind=="Brawl" then
   local need=runSpeed*(p.spec.travelTime or .22)*.85
   if need>p.spec.travel then p.spec.travel=need;a.travelRemaining=need end
   a.strikeCarry={dir=a.travelDirection,speed=runSpeed*(if action=="Heavy" then .45 else .7),at=c.now}
   Brawler.event(c,a,"RunningStrike")
  end
  return ok
 end
 local graph=Brawler.graph(a) or {}
 local routes=graph.routes or {}
 -- Inside a confirmed string: its chain window picks routes and heavy
 -- conversions; the light step alone also continues in the short grace after
 -- it (a press a moment late is still the next light, never a route).
 local alive=not a.airborne and Brawler.stringAlive(c,a,false)
 local inChain=canChain and alive
 if action=="Heavy" then
  if a.airborne then
   -- A fighter's own finisher in the same window (MoveGraphs airFinisher,
   -- Rock Lee's lotuses); Sasuke's Lion Combo below stays the default.
   if graph.airFinisher and (a.lionUntil or 0)>c.now and a.target and a.target.health>0 then return Brawler.airFinisher(c,a,graph.airFinisher) end
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
  if inChain and a.combo==1 and graph.heavyAfterOne then return Brawler.start(c,a,graph.heavyAfterOne) end
  if inChain and a.combo>=2 then return Brawler.start(c,a,a.def.LauncherMove or "Launcher") end
  -- Heavy on a re-engage arrival: the prodigy's quick heavy (knee, palm),
  -- except on a body pinned to a wall, where the heavy is the wall bounce.
  if reentry and graph.heavyAfterOne and not (a.target and a.target.reaction=="WallSplat") then
   Brawler.event(c,a,"ArrivalHeavy");return Brawler.start(c,a,graph.heavyAfterOne)
  end
  return Brawler.start(c,a,a.def.HeavyMove or "Heavy")
 end
 if a.airborne then
  -- Air grammar: after a confirmed air hit the stick picks the follow-up.
  local airAlive=Brawler.stringAlive(c,a,true)
  -- Like the ground routes, an air route also takes the grace after its
  -- window: in Studio, W + a click a moment late after Air1 played Air2.
  if (canChain or a.state=="Neutral") and airAlive and (a.airCombo or 0)>=1 then
   local dir,sideSign=Brawler.intent(a)
   local route=if dir=="forward" then routes.airUp elseif dir=="back" then routes.airDown elseif dir=="side" then routes.airSide else nil
   if route then
    a.angleSide=sideSign;a.lastAirAttack=c.now
    Brawler.event(c,a,"Route");return Brawler.start(c,a,route)
   end
  end
  if not airAlive then Brawler.breakString(a,true) end
  a.lastAirAttack=c.now
  return Brawler.start(c,a,if (a.airCombo or 0)%2==0 then "Air1" else "Air2")
 end
 -- A successful Read (Itachi) pays off with the graph's counter on the next press.
 if action=="Attack" and graph.readCounter and (a.counterUntil or 0)>c.now and not canChain then
  return Brawler.counterStart(c,a)
 end
 -- Directional combo grammar: inside a confirmed string the stick picks the
 -- route. Toward the opponent launches, away goes low, sideways turns the
 -- angle; each fighter answers with its own move. A route also takes the
 -- grace after the window (Config.Combo.Grace), like the next light: with
 -- toward held, a press a moment late launched in Studio one time in three and
 -- played Light3 otherwise. (Heavy conversions still need the real window.)
 if action=="Attack" and (inChain or (alive and a.state=="Neutral")) then
  local dir,sideSign=Brawler.intent(a)
  local route=nil
  if dir=="forward" and a.combo>=2 then route=routes.up
  elseif dir=="back" and a.combo>=2 then route=routes.down
  elseif dir=="side" and a.combo>=1 then route=routes.side end
  if route and Attacks[route] then
   a.angleSide=sideSign;a.lastAttack=c.now
   Brawler.event(c,a,"Route");Brawler.event(c,a,if dir=="forward" then "RouteUp" elseif dir=="back" then "RouteDown" else "RouteSide")
   return Brawler.start(c,a,route)
  end
 end
 -- The light step follows the confirmed hits: Light1 opens, Light2 after one
 -- confirmed hit, Light3 (the string's end) after two. Out of a string (a
 -- whiff, a block, a pause, a hit taken) it is Light1 again.
 if not alive then Brawler.breakString(a,false) end
 local name="Light"..math.min((a.combo or 0)+1,3)
 a.lastAttack=c.now
 -- Context finisher (Neji): with three chakra points closed, the third palm
 -- becomes the twin-palm thrust that throws the body away.
 if name=="Light3" and a.def.GentleFist and a.target and (a.target.tenketsuUntil or 0)>c.now and (a.target.tenketsu or 0)>=3 then
  return Brawler.start(c,a,"PalmThrust")
 end
 if canDash then
  local ok=Brawler.start(c,a,"DashAttack")
  -- Sasuke's explosive re-entry: the arrival strike lands harder.
  if reentry and style and style.dashDamage and a.pending then
   a.pending.spec.damageScale=(a.pending.spec.damageScale or 1)*style.dashDamage
  end
  return ok
 end
 return Brawler.start(c,a,name)
end
-- What a fighter's own version of a route adds on contact.
function Brawler.routePayoff(c,a,b,p)
 local graph=Brawler.graph(a)
 local kind=graph and graph.onRoute and graph.onRoute[p.name]
 if not kind or b.health<=0 then return end
 local Techniques=require(script.Parent.Techniques)
 -- A payoff a fighter's own module registered (Techniques.payoffs: Temari's updraft).
 local custom=Techniques.payoffs and Techniques.payoffs[kind]
 if custom then custom(c,a,b,p);return end
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
    c:cue(a,"SHADOW OF THE DANCING LEAF • HEAVY = "..(if graph.airFinisher then graph.airFinisher.cue else "LION COMBO"),1)
    Brawler.event(c,a,"ShadowLeaf")
   else a.chakra-=Config.PursuitCost end
  end)
 elseif kind=="tenketsu" then
  -- Neji: the low route strikes a second chakra point.
  Brawler.gentleFist(c,a,b,false)
 elseif kind=="echo" then
  -- Itachi (skill build Feint Echo): the feint step's afterimage stays as a
  -- genjutsu decoy; a swing at it is caught (Combat: MirageCatch on a whiff).
  if b.def.Byakugan then c:cue(b,"BYAKUGAN • SEES THROUGH",.8);return end
  b.illusionUntil=c.now+1.2
  b.decoyPosition=c:clamp(a.stepFrom or a.root.Position)
  c:effect("Echo",b.decoyPosition,a.color,Vector3.new(2,5,1),1.2)
  c:pushImpact(a.root.Position,"mirage",false,{owner=a.id,fighter=a.fighterId,to=b.decoyPosition})
  c:cue(a,"ECHO LEFT",.8);c:cue(b,"MIRAGE • TRUST THE BODY",1.2)
 elseif Brawler.payoffs[kind] then
  Brawler.payoffs[kind](c,a,b,p)
 end
end
-- A fighter's own air finisher after the Shadow of the Dancing Leaf
-- (MoveGraphs[...].airFinisher, read by the heavy in its window; Sasuke keeps
-- the Lion Combo). Like the Lion Combo the body is put above the target and the
-- slam drives both down; the descriptor says what it is (name: the client clip
-- and attackVariant, cue, event, damage, impulse, reaction, stun) and what it
-- costs: healthCost from the attacker's own health, never to a KO and refused
-- at or under minHealth (then `fallback`), free in its `awakened` form.
function Brawler.airFinisher(c,a,f)
 a.lionUntil=0
 local b=a.target
 local use,cost=f,f.healthCost or 0
 if f.awakened and (a.awakenUntil or 0)>c.now then use,cost=f.awakened,0
 elseif cost>0 and a.health<=math.max(f.minHealth or 0,cost+1) then use,cost=f.fallback or {},0 end
 local look=b.root.Position-a.root.Position;look=Vector3.new(look.X,0,look.Z)
 look=if look.Magnitude>.1 then look.Unit else a.root.CFrame.LookVector
 -- Beside the body, a little above, more than a body width away and facing
 -- along the line (the dive is head first): put over its head, or turned
 -- toward it, the two bodies interpenetrated all the way down (seen in Studio).
 local side=look:Cross(Vector3.yAxis)
 c:relocate(a,b.root.Position+Vector3.new(0,1.8,0)+side*3)
 a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+look)
 a.airborne=true
 local ok=Brawler.start(c,a,"Slam")
 local p=a.pending
 if p then
  if use.damage then p.spec.damage=use.damage end
  if use.impulse then p.spec.impulse=use.impulse end
  if use.reaction then p.spec.reaction=use.reaction;p.spec.feedback=use.reaction end
  if use.stun then p.spec.stun=use.stun end
  a.attackVariant=use.name
 end
 if cost>0 then a.health=math.max(1,a.health-cost);a.hum.Health=math.max(1,a.health) end
 c:cue(a,use.cue or "AIR FINISHER",.9);Brawler.event(c,a,use.event or "AirFinisher")
 return ok
end
-- The weight of a contact (Combat.Hitstop). By name for the shared grammar,
-- and by what the strike is (Attacks kind / reaction) for a fighter's own
-- routes and heavies (QA-004 M6): a cleaver brought down, a lariat or a
-- launcher of the roster weighed nothing before (every unnamed move was a
-- light, no stop at all).
function Brawler.stopStyle(p)
 local spec=p.spec or {}
 if p.name=="Slam" or spec.kind=="slam" or spec.kind=="spike" then return "slam" end
 if p.name=="Launcher" or p.name=="ThrowUp" or spec.kind=="launch" then return "launcher" end
 if p.name=="Heavy" or p.name=="Throw" or p.name=="Light3" or spec.kind=="heavy" or spec.reaction=="Knockdown" then return "finisher" end
 if spec.air then return "air" end
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
 local source=a.reactionSource
 -- `cause`/`by`: the blow that drove the body into the wall (a Vacuum Palm
 -- reads as Neji's air pressure on the stone, not a generic wall hit).
 c:pushImpact(hit.Position,"wall",true,{normal=normal,owner=a.id,cause=a.reactionCause,by=source and source.fighterId})
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
-- Wall Palm (skill build): the nearest wall the body can be driven into, within
-- steer.Range and a cone of +-acos(steer.Cone) around the attacker's facing.
-- Returns the flat direction toward it, or nil (the strike keeps its own line).
function Brawler.wallAim(c,a,b,steer)
 local look=a.root.CFrame.LookVector*Vector3.new(1,0,1)
 if look.Magnitude<.05 then return nil end
 look=look.Unit
 local half=math.acos(math.clamp(steer.Cone,-1,1))
 local params=c:rayParams(true)
 local best,bestDistance
 for k=-2,2 do
  local dir=CFrame.fromAxisAngle(Vector3.yAxis,half*k/2):VectorToWorldSpace(look)
  local hit=workspace:Raycast(b.root.Position,dir*steer.Range,params)
  if hit and math.abs(hit.Normal.Y)<.3 and Brawler.splatSurface(hit.Instance) and (not bestDistance or hit.Distance<bestDistance) then
   best,bestDistance=dir,hit.Distance
  end
 end
 if best then c:cue(a,"WALL READ",.6);Brawler.event(c,a,"WallSteer") end
 return best
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
 -- graph.wallBounce (skill build Trigram Rebound): extra moves that bounce too.
 local bounce=(Brawler.graph(a) or {}).wallBounce
 local heavy=p.name=="Heavy" or p.name=="Launcher" or p.name=="Slam" or p.name=="WallDive" or p.rasengan==true or (bounce~=nil and bounce[p.name]==true)
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
 -- (A strike another body carries out, Bodies.bind, never meets a blow thrown at its owner.)
 if not q or q.kind~="Brawl" or q.from or (b.state~="Active" and b.state~="Startup") or b.target~=a or b.hitConfirmed or a.hitConfirmed then return false end
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
  Bangla.close(x.pending);x.pending=nil;x.attackName=nil;x.chainOpen=false;x.buffered=nil;x.travelRemaining=0
  -- Neither strike landed: both strings start over.
  Brawler.resetStrings(x)
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
-- the victim's chakra recovery for a few seconds (stacks up to four). Each
-- closed point is a real place on the body: the snapshot lists them
-- (tenketsuPoints) and the client lights them, so the network is seen closing.
-- Which point closes follows where the palm landed (the strike's zone).
local TENKETSU_ORDER={
 head={"throat","leftShoulder","rightShoulder","heart","solar","navel","leftHip","rightHip"},
 chin={"throat","heart","leftShoulder","rightShoulder","solar","navel","leftHip","rightHip"},
 body={"heart","solar","navel","leftShoulder","rightShoulder","throat","leftHip","rightHip"},
 legs={"navel","leftHip","rightHip","solar","heart","throat","leftShoulder","rightShoulder"},
}
Brawler.TENKETSU_ORDER=TENKETSU_ORDER
-- Close one point on b; nil when every point is already closed (the palm then
-- only keeps them closed longer).
function Brawler.closePoint(c,a,b,zone)
 local g=a.def.GentleFist
 if (b.tenketsuUntil or 0)<=c.now then b.tenketsu=0;b.tenketsuPoints={} end
 b.tenketsuPoints=b.tenketsuPoints or {}
 b.tenketsuUntil=c.now+g.Duration;b.tenketsuCut=g.RegenCut
 if #b.tenketsuPoints>=g.MaxPoints then b.tenketsu=#b.tenketsuPoints;return nil end
 local closed={}
 for _,id in b.tenketsuPoints do closed[id]=true end
 local point
 for _,id in TENKETSU_ORDER[zone or "body"] or TENKETSU_ORDER.body do if not closed[id] then point=id;break end end
 if not point then return nil end
 table.insert(b.tenketsuPoints,point)
 b.tenketsu=#b.tenketsuPoints
 local severe=b.tenketsu>=g.MaxPoints
 c:pushImpact(b.root.Position,"tenketsu",false,{owner=a.id,fighter=a.fighterId,victim=b.id,point=point,count=b.tenketsu,severe=severe})
 Brawler.event(c,a,"PointClosed")
 if severe then c:cue(b,"CHAKRA NETWORK SEALED",1);Brawler.event(c,a,"Severed") end
 return point
end
-- Every point at once (the last of the Sixty-Four Palms).
function Brawler.sealPoints(c,a,b)
 for _=1,a.def.GentleFist.MaxPoints do if not Brawler.closePoint(c,a,b,"body") then break end end
end
-- The contact entry Combat:damage pushed for a blow on `b` this very frame
-- (a hit, a block), so the blow can say what it was. nil when there is none.
local CONTACT={light=true,palm=true,finisher=true,launcher=true,slam=true,block=true}
function Brawler.contactImpact(c,b)
 local feed=c.impacts or {}
 for i=#feed,1,-1 do
  local entry=feed[i]
  if entry.at~=c.now then return nil end
  if CONTACT[entry.style] and (entry.position-b.root.Position).Magnitude<1 then return entry end
 end
 return nil
end
-- What a landed (or blocked) strike was, written on its contact: the move, its
-- variant (Rasengan, a counter...), who threw it and at whom. Each fighter's
-- client identity layer draws its own blows from it.
function Brawler.tagContact(c,a,b,p)
 local entry=Brawler.contactImpact(c,b)
 if not entry then return nil end
 entry.move=p.name;entry.variant=a.attackVariant;entry.owner=a.id;entry.fighter=a.fighterId;entry.victim=b.id
 return entry
end
-- How much of its chakra recovery a body keeps under closed points (1: all).
-- Combat regenerates with it, the snapshot shows it on the chakra bar.
function Brawler.tenketsuRegen(a,now)
 if (a.tenketsuUntil or 0)<=now then return 1 end
 return math.max(.2,1-(a.tenketsuCut or .15)*(a.tenketsu or 0))
end
-- `zone`: where the palm landed (defaults to the body's last hit zone);
-- `palm`: a melee contact whose generic hit feedback becomes the palm's.
function Brawler.gentleFist(c,a,b,guarded,zone,palm)
 local g=a.def.GentleFist
 local tune=a.def.Awakening
 local awake=(a.awakenUntil or 0)>c.now and tune
 local boost=if awake then (tune.Drain or 1) else 1
 -- Skill build (Full Field Points): awakened, the palms reach the points
 -- through a guard (full drain and a closed point).
 local through=guarded and awake and tune.GuardPoints==true
 if through then c:cue(a,"FULL FIELD • THROUGH THE GUARD",.5) end
 local drained=(if guarded and not through then g.GuardDrain else g.Drain)*boost
 b.chakra=math.max(0,b.chakra-drained)
 -- The palm's own contact: even a blocked one shows the chakra it drained.
 local entry=if palm then Brawler.contactImpact(c,b) else nil
 if entry then entry.owner=a.id;entry.drain=drained end
 if guarded and not through then return end
 -- The contact reads as a palm on the network, not a punch: the generic light
 -- hit this blow pushed takes the palm's feedback (sound, flash, camera).
 if entry and entry.style=="light" then entry.style="palm" end
 zone=zone or b.hitZone or "body"
 -- Byakugan Full Field: he sees the whole network, a clean palm closes two.
 -- The palm lands on the (first) point it closes: the client strikes there.
 for _=1,(if awake and tune.Points and not guarded then tune.Points else 1) do
  local point=Brawler.closePoint(c,a,b,zone)
  if entry and point and not entry.point then entry.point=point end
 end
 -- Full Field: a palm that breaks a jutsu being moulded cuts the flow itself.
 if awake and tune.ChannelCut and b.interruptedAt==c.now then
  b.sealedUntil=math.max(b.sealedUntil or 0,c.now+tune.ChannelCut)
  c:cue(a,"BYAKUGAN • CHAKRA FLOW CUT",.8);c:cue(b,"CHAKRA FLOW SEALED • NO JUTSU",.9)
  Brawler.event(c,a,"FlowCut")
 end
end
-- Counter stances (Itachi's Read, Neji's Rotation): a strike pressed while the
-- stance holds is kept and fires the moment the stance reads or repels.
function Brawler.counterStance(a)
 local p=a.pending
 return (a.state=="TechniqueChannel" or a.state=="TechniqueActive") and p~=nil and p.kind=="Technique" and (p.spec.Id=="Read" or p.spec.Id=="Rotation")
end
-- The graph's counter (CounterPalm, PalmThrust...) out of a read, a repel or a
-- caught genjutsu. With a reach (a caught image, a repelled body) it glides the
-- distance to the body instead of swinging at the air.
function Brawler.counterStart(c,a)
 local graph=Brawler.graph(a) or {}
 if not graph.readCounter or not a.target then return false end
 a.counterUntil=0;a.counterQueued=nil
 local reach=a.counterReach;a.counterReach=nil
 -- The counter opens a fresh string (combo model: hits, not presses).
 Brawler.breakString(a,false)
 local ok=Brawler.start(c,a,graph.readCounter)
 local p=a.pending
 if ok and p and reach and reach.expires>c.now then
  local d=a.target.root.Position-a.root.Position
  local need=math.clamp(Vector3.new(d.X,0,d.Z).Magnitude-(p.spec.contact or 3.6),0,reach.max)
  if need>p.spec.travel then p.spec.travel=need;a.travelRemaining=need end
  a.attackVariant=reach.variant
 end
 Brawler.event(c,a,"Counter")
 return ok
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
 -- A strike carried by a body (Bodies.bind) that was dispelled on the way misses.
 if p.lost then return false end
 if p.name~="Throw" and p.name~="ThrowUp" then
	-- An enemy body in the swing takes it first and puffs away (Bodies.strike).
	if Bodies.strike(c,a,p) then return true end
	-- Two strikes meeting in the same instant cancel out (a carried strike's
	-- body is not its owner's).
	if p.name~="Grab" and not p.from and Brawler.clash(c,a,p) then return false end
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
 -- What landed (or was blocked), written on its contact for the client.
 local contact=if success then Brawler.tagContact(c,a,b,p) else nil
 if not success or b.health<=0 then return success end
 if protected then return true end
 if a.def.GentleFist then Brawler.gentleFist(c,a,b,guarded,p.spec.zone,true) end
 -- Flying Thunder God: the arrival strike lands on a body still inside the
 -- combo that led to the teleport. The chain went on through the relocation.
 if contact and not guarded and a.flashStrike==a.attackSerial and (b.comboHits or 0)>=2 then
  contact.arrival=true
  c:cue(a,"FLYING THUNDER GOD • THE CHAIN GOES ON",.8)
  Brawler.event(c,a,"FlashChain")
 end
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
 -- (A carried strike drives the body away from its carrier: a clone's kick
 -- from behind sends it toward Naruto.)
 local forward=(p.from or a.root.CFrame).LookVector
 -- Skill build (Wall Palm): the knockback of the listed moves aims at a wall
 -- in reach in front of the attacker, when there is one.
 local steer=a.def.WallSteer
 if steer and steer.Moves[p.name] then forward=Brawler.wallAim(c,a,b,steer) or forward end
 -- A lateral strike (Attacks lateral: Temari's pirouette) throws the body to
 -- the side the stick asked for instead of straight away.
 if spec.lateral then forward=a.root.CFrame.RightVector*(if (a.angleSide or 0)~=0 then a.angleSide else 1) end
 local impulse=forward*spec.impulse.Z+Vector3.yAxis*spec.impulse.Y
 -- What the body took: the client answers a head snap, a fold, a swept base.
 b.hitZone=spec.zone;b.hitKind=spec.kind;b.hitTwist=(spec.side or 1)*(if (a.angleSide or 0)~=0 and spec.orbit then a.angleSide else 1)
 -- A strike that backs off as it lands (Attacks retreat, studs: Madara's heel
 -- with the blade held across, Hiruzen's heel with the point covering).
 if spec.retreat then
  local away=a.root.Position-b.root.Position;away=Vector3.new(away.X,0,away.Z)
  a.hop={direction=if away.Magnitude>.1 then away.Unit else -a.root.CFrame.LookVector,remaining=spec.retreat,speed=26}
 end
 Brawler.routePayoff(c,a,b,p)
 -- Awakening rules on a landed strike (Techniques.awakenedHit/awakenedReact).
 local Techniques=require(script.Parent.Techniques)
 Techniques.awakenedHit(c,a,b,p)
 -- Move-specific weight: a light jab must not stop the fight, a slam must land hard.
 c:applyHitstop(a,b,Brawler.stopStyle(p),false)
 if b.reaction=="WallSplat" and Brawler.wallFollow(c,a,b,p) then Brawler.event(c,a,"Hit");return true end
 -- Super armour (Families Heavy buff): a plain hit-stun strike does not stop him.
 local Families=require(script.Parent.Families)
 if not (spec.reaction=="HitStun" and Families.withstands(b,c.now,false,spec.damage or 0)) then
  Brawler.react(c,b,spec.reaction,impulse,spec.stun,a,a.attackVariant or p.name)
 end
 Techniques.awakenedReact(c,a,b,p)
 -- A family strike (Families Strike/Teleport) adds its contact fields; so
 -- does a fighter's own strike that declares them (Attacks `riders`).
 if p.family or p.spec.riders then Families.strikeHit(c,a,b,p,false) end
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
   else
    -- A light hit (HitStun) slides the body back ~0.9 stud, enough for the
    -- string to drive forward instead of the attacker walking into it.
    Motor.travel(a,c,velocity,velocity.Magnitude*dt);velocity*=math.exp(-dt*(if a.reaction=="HitStun" then 8 else 14))
   end
		 a.reactionVelocity=velocity;return true
  end
 end
 local p=a.pending
 if p and p.kind=="Brawl" then
  if a.state=="Active" and not p.hit then
   -- Re-check every active frame. A single early test used to mark the whole
   -- swing as a whiff, so a target that entered the volume one frame later
   -- took no damage from a visibly connected strike.
   -- Contact is this swing's own: a blade, a burn or a cover shuriken landing
   -- while it is out (they also set hitConfirmed) is not the strike connecting.
   a.hitConfirmed=false
   local hit=Brawler.hit(c,a,p)
   if (hit or a.hitConfirmed) and not p.contact then
    p.contact=true
    -- The string's next confirmed hit (a guarded strike confirms nothing).
    if p.step and not a.hitBlocked then Brawler.confirm(c,a,p) end
   end
   p.hit=hit or nil
   a.hitConfirmed=p.contact==true
  end
 end
 local buffered=a.buffered
 if buffered and c.now>buffered.expires then a.buffered=nil;buffered=nil end
 if buffered and not a.reaction and not (a.throwing and c.now<a.throwing.release) then
  -- Released on the chain (the swing before it landed cleanly), on a re-entry
  -- arrival, or once the body is free again: after a whiff or a block the
  -- buffered press is a fresh opener that waited out the whole recovery.
  local canFlash=(a.flashUntil or 0)>c.now and (a.state=="TechniqueRecovery" or a.state=="TechniqueActive")
   and (a.pending==nil or (a.pending.kind=="Technique" and a.pending.spec.Id=="Flashstep"))
  if Brawler.chainWindow(c,a) or Brawler.arrival(c,a) or canFlash or Rules.canAct(a,c.now) then
   a.buffered=nil;a.pressAt=buffered.at
   -- The direction: a strong push made while it waited wins (the latest
   -- intent), else the one it was pressed with.
   local memory=a.intentMemory
   a.intentOverride=if memory and memory.at>buffered.at and not buffered.explicit then {memory.dir,memory.side} else buffered.intent
   Brawler.request(c,a,buffered.action)
   a.intentOverride=nil
  end
 end
 return false
end
return Brawler
