-- Read-only QA projection. Never imported by combat, movement or Motion Lab.
-- State, reaction and locomotion are independent axes in the existing engine.
local Inspector={}
-- Discoverable hooks into the existing common engine, not a second tool system.
Inspector.ToolHooks={
 holdEquip="Combat.beginThrow(actor, spec); no persistent inventory/equip state",
 release="Combat.stepThrow(actor): spec.fire(index, aim) on the authored release frame",
 spawn="Combat.projectile(actor, aim, speed, range, damage, kind, onSurface?, opts?)",
 impact="Combat.projectileHit(projectile, target, position, normal)",
 surface="Combat.projectileSurface(projectile, raycastResult); projectile.onSurface(position, normal, victim?)",
 embedded="Techniques.plant / actor.anchors for Minato seals; ordinary blade stick is a presentation impact",
 recall="Combat.markedInFlight reads a travelling seal; no generic weapon recall mechanic",
 cleanup="Combat.removeProjectile / updateProjectiles / Combat.clear / Techniques.expireSeals",
 conversion="Existing ToolMastery, MoveGraphs, onSurface callbacks and Techniques.wireBind; preserve character identity",
}
local function remaining(value,now) return math.max(0,(value or 0)-now) end
local function counts(source)
 local result={};for key,value in source or {} do if type(value)=="number" then result[key]=value end end;return result
end
function Inspector.actor(c,a)
 local now=c.now;local pending=a.pending;local spec=pending and pending.spec
 local attack=if pending then pending.name or (spec and spec.Id) else nil
 local phase=if a.state=="Startup" or a.state=="TechniqueChannel" then "startup" elseif a.state=="Active" or a.state=="TechniqueActive" then "active" elseif a.state=="Recovery" or a.state=="TechniqueRecovery" then "recovery" else "none"
 local durations=if spec then {startup=spec.startup or spec.Channel or 0,active=spec.active or spec.Active or 0,recovery=spec.recovery or spec.Recovery or 0} else nil
 local velocity=a.root.AssemblyLinearVelocity
 local terrain=if a.wall then "wall" elseif a.airborne then (if velocity.Y<-.1 then "falling" else "air") else "ground"
 local movement=if a.wall then "wall" elseif a.reaction then "reaction:"..a.reaction elseif a.state=="Pursuit" or a.state=="Rush" or a.state=="Dodging" then a.state elseif a.airborne then "air" elseif (a.locomotion or Vector3.zero).Magnitude>.1 then (if a.sprinting then "sprint" else "locomotion") else "idle"
 local projectiles={}
 for _,p in c.projectiles do if p.a==a then table.insert(projectiles,{id=p.id,kind=p.kind,remaining=p.remaining,age=now-p.born}) end end
 local anchors={}
 for _,anchor in a.anchors or {} do table.insert(anchors,{id=anchor.id,body=anchor.actor and anchor.actor.id,remaining=remaining(anchor.expires,now)}) end
 return {id=a.id,fighterId=a.fighterId,name=a.def.Name,state=a.state,reaction=a.reaction or "none",reactionRemaining=remaining(a.reactionUntil,now),
  move=attack or "none",attackVariant=a.attackVariant or "none",phase=phase,phaseRemaining=remaining(a.untilTime,now),durations=durations,
  elapsed=if pending then math.max(0,now-(if pending.kind=="Brawl" then a.attackStarted or now else a.castStarted or now)) else 0,
  combo=a.combo or 0,comboRoute=attack or a.attackName or "none",comboHits=a.comboHits or 0,hitConfirmed=a.hitConfirmed==true,chainOpen=a.chainOpen==true and now>=(a.chainAt or math.huge),
  buffered=a.buffered and a.buffered.action or "none",target=a.target and a.target.id or "none",locked=a.locked==true,terrain=terrain,movement=movement,
  cue=if (a.cueUntil or 0)>now then a.cue or "" else "",guard=a.guardHeld==true,stamina=a.stamina or 0,parryCooldown=remaining(a.parryReadyAt,now),dodge=remaining(a.dodgeUntil,now),invulnerability=remaining(a.invulnerableUntil,now),
  counter=remaining(a.counterUntil,now),riposte=remaining(a.riposteUntil,now),read=remaining(a.readUntil,now),
  grabbedBy=a.grabbedBy and a.grabbedBy.id or "none",grabVictim=a.grabVictim and a.grabVictim.id or "none",
  throw=if a.throwing then {kind=a.throwing.kind,fired=a.throwing.fired,count=a.throwing.count,releaseIn=remaining(a.throwing.nextRelease,now)} else nil,
  projectiles=projectiles,anchors=anchors,wireVictim=a.wireVictim and a.wireVictim.id or "none",bound=a.reaction=="Bound",
  awakening=remaining(a.awakenUntil,now),events=counts(a.events),health=a.health,chakra=a.chakra,
  -- Clashes are events followed by Recovery, not a persistent WeaponClash state.
  clashes=(a.events or {}).Clash or 0,weaponClashState="not a persistent state"}
end
function Inspector.snapshot(s)
 local rows={};for _,a in s.combat.actors do table.insert(rows,Inspector.actor(s.combat,a)) end
 local impacts={}
 for _,impact in s.combat.impacts or {} do table.insert(impacts,{id=impact.id or impact.serial,style=impact.style,kind=impact.kind,owner=impact.owner,victim=impact.victim}) end
 return {phase=s.phase,epoch=s.epoch,now=s.combat.now,actors=rows,projectileCount=#s.combat.projectiles,hazardCount=#s.combat.hazards,impacts=impacts}
end
function Inspector.record(trace,snapshot,limit)
 -- Compare projections, never hold references to mutable actors or pending moves.
 trace.last=trace.last or {};trace.entries=trace.entries or {}
 for _,a in snapshot.actors do
  local key=table.concat({a.state,a.reaction,a.move,a.attackVariant,a.terrain,tostring(a.combo),tostring(a.clashes),a.throw and a.throw.kind or "none"},"|")
  if trace.last[a.id]~=key then
   trace.last[a.id]=key
   table.insert(trace.entries,{at=snapshot.now,id=a.id,fighter=a.fighterId,state=a.state,reaction=a.reaction,move=a.move,variant=a.attackVariant,terrain=a.terrain,combo=a.combo,clashes=a.clashes})
  end
 end
 while #trace.entries>(limit or 80) do table.remove(trace.entries,1) end
end
return Inspector
