-- Objectives observe the real engine; setups reset the practice pair, never fake success.
local Brawler=require(script.Parent.Brawler)
local Tutorial={}
Tutorial.Steps={
 {title="Move",pad="Left stick",key="W A S D",kind="Move"},
 {title="Sprint",pad="Click LS, then move",key="Hold CTRL + move",kind="Sprint"},
 {title="Jump and land",pad="A / Cross",key="SPACE",kind="Land"},
 {title="Unlock, then lock the target",pad="Click RS twice",key="SHIFT twice",kind="Lock"},
 {title="Directional dash",pad="Left stick + B / Circle",key="Direction + Q",event="Dodge"},
 {title="Run up the wall, then rebound",pad="Push LS into wall, then A",key="Move into wall, then SPACE",kind="Wall"},
 {title="Land three light strikes",pad="X / Square three times",key="LMB three times",kind="Combo"},
 {title="Branch into a launcher",pad="X, X, then Y / Triangle",key="LMB, LMB, RMB",event="LaunchHit"},
 {title="Chase the launched target",pad="A / Cross after launch",key="E or SPACE after launch",kind="Chase"},
 {title="Land two aerial strikes",pad="X / Square twice in air",key="LMB twice in air",kind="AirCombo"},
 {title="Finish downward",pad="Y / Triangle in air",key="RMB in air",event="SlamHit"},
 {title="Guard the incoming strike",pad="Hold LB / L1",key="Hold F",event="GuardHit"},
 {title="Dodge the incoming strike",pad="B / Circle during windup",key="Q during windup",kind="Evade"},
 {title="Escape after being hit",pad="B / Circle just after contact",key="X just after contact",event="Substitute"},
 {title="Grab, then throw",pad="LT / L2, then X (Y throws upward)",key="V, then LMB (RMB throws upward)",event="ThrowHit"},
 {title="Perform a character technique",pad="Hold RB / R1 + A",key="1",kind="Technique"},
 {title="Interrupt the telegraphed technique",pad="X / Square during hand signs",key="LMB during hand signs",kind="Interrupt"},
 {title="Win the practice duel",pad="Use your complete kit",key="Use your complete kit",kind="Win"},
}
function Tutorial.new(s)
 local t={index=1,entered=0,baseline={},travel=0,seenAir=false,seenWall=false,unlocked=false,attackAt=0};s.tutorial=t;return t
end
function Tutorial.enter(s,now)
 local t,a,b=s.tutorial,s.human,s.bot;t.entered=now;t.completedAt=nil;t.baseline=table.clone(a.events or {});t.travel=0;t.seenAir=false;t.seenWall=false;t.unlocked=false;t.health=a.health;t.lastPosition=a.root.Position
 local c=s.combat;c:clear(true)
 for _,actor in {a,b} do actor.health=actor.def.Health;actor.hum.Health=actor.health;actor.state="Neutral";actor.chakra=actor.def.Chakra;actor.subCharges=2;actor.subCooldown=0;actor.cooldowns={};actor.invulnerableUntil=0 end
 t.health=a.health
 b.trainingChannelScale=if t.index==17 and b.fighterId=="Flashstep" then 3 else 1
 local near=t.index>=7 and t.index~=16
 c:relocate(a,s.origin+Vector3.new(0,3,if near then 3 else 14));c:relocate(b,s.origin+Vector3.new(0,3,if near then -2 else -14))
 if t.index==6 then c:relocate(a,s.origin+Vector3.new(24,3,0));c:relocate(b,s.origin+Vector3.new(16,3,0)) end
 a.root.CFrame=CFrame.lookAt(a.root.Position,b.root.Position);b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position)
 if t.index==9 then Brawler.react(c,b,"Launched",Vector3.new(0,48,0),1.2);a.pursuitUntil=now+1.2 end
 if t.index==10 or t.index==11 then
  c:relocate(a,s.origin+Vector3.new(0,16,3));c:relocate(b,s.origin+Vector3.new(0,16,-2));a.airborne=true;a.airHold=now+1.8
  Brawler.react(c,b,"Juggled",Vector3.zero,1.8)
 end
 t.attackAt=now+1
end
function Tutorial.update(s,now,dt)
 local t,a,b=s.tutorial,s.human,s.bot;local c=s.combat
 if t.entered==0 then Tutorial.enter(s,now) end
 local spec=Tutorial.Steps[t.index]
 b.move=Vector3.zero;b.sprinting=false
 if t.index==18 then s.ai:update(now);return end
 local displacement=(a.root.Position-(t.lastPosition or a.root.Position)).Magnitude;t.travel+=math.min(displacement,4);t.lastPosition=a.root.Position
 local function event(name) return (a.events and a.events[name] or 0)>(t.baseline[name] or 0) end
 local done=spec.event and event(spec.event)
 if spec.kind=="Move" then done=t.travel>12
 elseif spec.kind=="Sprint" then done=a.sprinting and a.locomotion.Magnitude>30
 elseif spec.kind=="Land" then t.seenAir=t.seenAir or a.airborne;done=t.seenAir and not a.airborne
 elseif spec.kind=="Lock" then t.unlocked=t.unlocked or not a.locked;done=(t.unlocked or event("Unlock")) and a.locked and event("Lock")
 elseif spec.kind=="Wall" then t.seenWall=t.seenWall or a.wall~=nil;done=t.seenWall and (a.wallJumpUntil or 0)>now
 elseif spec.kind=="Combo" then done=(a.events and a.events.Hit or 0)-(t.baseline.Hit or 0)>=3
 elseif spec.kind=="Chase" then done=event("Chase") and a.state=="Neutral" and a.airborne and (a.root.Position-b.root.Position).Magnitude<7
 elseif spec.kind=="AirCombo" then done=(a.events and a.events.AirHit or 0)-(t.baseline.AirHit or 0)>=2
 elseif spec.kind=="Technique" then done=event("Technique") and a.state=="TechniqueRecovery"
 elseif spec.kind=="Evade" then done=event("Dodge") and (event("Evaded") or (b.attackName=="Heavy" and now-(b.attackStarted or now)>.46 and a.health==t.health))
 elseif spec.kind=="Interrupt" then done=event("Interrupt") end
 if done and not t.completedAt then t.completedAt=now end
 if t.completedAt and now-t.completedAt>=.22 then t.index+=1;Tutorial.enter(s,now);return end
 if (t.index==12 or t.index==13 or t.index==14) and now>=t.attackAt then
  if (b.root.Position-a.root.Position).Magnitude>7 then c:relocate(b,a.root.Position+a.root.CFrame.LookVector*5) end
  b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position);c:request(b,"Heavy");t.attackAt=now+1.7
 end
 if t.index==17 and now>=t.attackAt then
  b.cooldowns={};b.chakra=b.def.Chakra;c:request(b,if b.fighterId=="Mirage" then "Technique4" else "Technique1",a.root.Position);t.attackAt=now+1.4
 end
 -- Failed launch/juggle exercises reset quickly without skipping their objectives.
 if (t.index==9 or t.index==10 or t.index==11) and now-t.entered>3 then Tutorial.enter(s,now) end
 if a.health<a.def.Health*.3 then a.health=a.def.Health;a.hum.Health=a.health end
 if b.health<b.def.Health*.25 then b.health=b.def.Health;b.hum.Health=b.health end
end
function Tutorial.snapshot(s)
 local t=s.tutorial;if not t then return nil end
 local step=Tutorial.Steps[t.index]
 return {index=t.index,total=#Tutorial.Steps,title=step.title,pad=step.pad,key=step.key}
end
return Tutorial
