-- performEvade from Bangla WalkRunHandler (Dewan Mukto, MIT), adapted.
-- One finite server tick loop replaces leaked RenderStepped connections. No global
-- gravity change; swept travel preserves walls, lane boundaries and root facing.
local Evade={}
function Evade.begin(a,c)
 local direction=if a.move.Magnitude>.1 then a.move.Unit else a.root.CFrame.RightVector
 local evadeDistance=14*(a.def.DashScale or 1)
 local evadeDuration=.32
 -- Movement overhaul (docs/movement/MOVEMENT_OVERHAUL_AUDIT.md): the speed the
 -- body had going in is handed back on the way out, so a dodge inside a run
 -- flows back into the run (or an attack) instead of stopping dead.
 local v=a.root.AssemblyLinearVelocity
 local entry=math.max(Vector3.new(v.X,0,v.Z).Magnitude,(a.locomotion or Vector3.zero).Magnitude)
 -- Locked near the opponent, a side or back dodge is a sidestep / hop away
 -- that keeps the chest on them (Studio: turning into it made every dodge read
 -- as a forward dash, and hid the acrobatic bodies' cartwheel / handspring).
 local keep=false
 if a.locked~=false and a.target and a.target.root then
  local to=a.target.root.Position-a.root.Position;to=Vector3.new(to.X,0,to.Z)
  -- Not out of a committed run away (sprint, or travel facing the way it goes,
  -- Combat:faceLocked): running off, the dodge stays a dash along the run.
  keep=to.Magnitude<40 and to.Magnitude>.1 and direction:Dot(to.Unit)<.5 and not a.sprinting and not a.facingCommitted
 end
 a.evade={startPosition=a.root.Position,targetPosition=a.root.Position+direction*evadeDistance,startTime=c.now,duration=evadeDuration,direction=direction,entry=entry,keep=keep}
end
-- Exit with momentum: at least a running pace along the dodge, at most the
-- sprint, never more than it came in with plus a run (no free speed). Called
-- when the evade runs out and when the dodge state ends first.
function Evade.finish(a)
 local e=a.evade;if not e then return end
 a.evade=nil
 local walk=(a.def.Speed or 18)
 local carry=math.min(math.max(e.entry or 0,walk),walk+(e.entry or 0),45*(a.def.SprintScale or 1))
 local out=e.direction*carry
 a.evadeCarry=out
 local v=a.root.AssemblyLinearVelocity
 a.root.AssemblyLinearVelocity=Vector3.new(out.X,v.Y,out.Z)
end
function Evade.step(a,c,travel)
 local e=a.evade;if not e then return end
 local rootPart=a.root
 local targetPosition=e.targetPosition
 local evadeDuration=e.duration
 local startTime=e.startTime
 local elapsedTime=c.now-startTime
 if elapsedTime<evadeDuration then
  local t=math.clamp(elapsedTime/evadeDuration,0,1)
  -- Fast launch, soft brake: distance stays deterministic without the donor's
  -- moving-origin snap near the end of the evade. Quadratic, not cubic: the
  -- cubic left at 3x the mean speed (~2 studs in the first frame), which read
  -- as a pop in Studio; same distance and duration.
  local eased=1-(1-t)^2
  local position=e.startPosition:Lerp(targetPosition,eased)
  local delta=position-rootPart.Position
  travel(a,c,delta,delta.Magnitude)
  -- Turn into the dash at a bounded rate instead of snapping 90 degrees in a frame.
  local dt=math.max(1/240,c.now-(e.lastAt or startTime));e.lastAt=c.now
  -- Only a forward-ish dodge turns the body into it (Studio, §20 route: a side
  -- dodge out of a sprint swung the root 90 degrees and back in 0.3 s, a
  -- pivot that also hid the cartwheel); sideways or back, the body keeps its
  -- facing and the dodge reads as a sidestep / hop back (or the acrobatics).
  local look=rootPart.CFrame.LookVector;look=Vector3.new(look.X,0,look.Z)
  local ahead=look.Magnitude<.05 or e.direction:Dot(look.Unit)>.3
  if e.direction.Magnitude>.1 and not e.keep then if ahead then c:turnToward(a,e.direction,dt,900) end
  elseif e.keep and a.target and a.target.root then
   -- Chest held on them through the sidestep / hop away (small corrections).
   local to=a.target.root.Position-rootPart.Position
   to=Vector3.new(to.X,0,to.Z)
   if to.Magnitude>.1 then c:turnToward(a,to,dt,900) end
  end
  rootPart.AssemblyLinearVelocity=Vector3.zero
 else Evade.finish(a) end
end
return Evade
