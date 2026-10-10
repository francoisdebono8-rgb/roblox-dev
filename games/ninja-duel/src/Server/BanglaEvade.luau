-- performEvade from Bangla WalkRunHandler (Dewan Mukto, MIT), adapted.
-- One finite server tick loop replaces leaked RenderStepped connections. No global
-- gravity change; swept travel preserves walls, lane boundaries and root facing.
local Evade={}
function Evade.begin(a,c)
 local direction=if a.move.Magnitude>.1 then a.move.Unit else a.root.CFrame.RightVector
 local evadeDistance=14*(a.def.DashScale or 1)
 local evadeDuration=.32
 a.evade={startPosition=a.root.Position,targetPosition=a.root.Position+direction*evadeDistance,startTime=c.now,duration=evadeDuration,direction=direction}
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
  -- moving-origin snap near the end of the evade.
  local eased=1-(1-t)^3
  local position=e.startPosition:Lerp(targetPosition,eased)
  local delta=position-rootPart.Position
  travel(a,c,delta,delta.Magnitude)
  if e.direction.Magnitude>.1 then rootPart.CFrame=CFrame.lookAt(rootPart.Position,rootPart.Position+e.direction) end
  rootPart.AssemblyLinearVelocity=Vector3.zero
 else a.evade=nil end
end
return Evade
