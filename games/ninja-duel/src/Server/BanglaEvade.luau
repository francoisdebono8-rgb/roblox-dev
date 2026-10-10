-- performEvade from Bangla WalkRunHandler (Dewan Mukto, MIT), adapted.
-- One finite server tick loop replaces leaked RenderStepped connections. No global
-- gravity change; swept travel preserves walls, lane boundaries and root facing.
local Evade={}
function Evade.begin(a,c)
 local direction=if a.move.Magnitude>.1 then a.move.Unit else a.root.CFrame.RightVector
 local evadeDistance=14*(a.def.DashScale or 1)
 local evadeDuration=.32
 a.evade={targetPosition=a.root.Position+direction*evadeDistance,startTime=c.now,duration=evadeDuration}
end
function Evade.step(a,c,travel)
 local e=a.evade;if not e then return end
 local rootPart=a.root
 local targetPosition=e.targetPosition
 local evadeDuration=e.duration
 local startTime=e.startTime
 local elapsedTime=c.now-startTime
 if elapsedTime<evadeDuration then
  -- Donor's moving-origin interpolation, applied through the collision seam.
  local position=rootPart.Position:Lerp(targetPosition,elapsedTime/evadeDuration)
  local delta=position-rootPart.Position
  travel(a,c,delta,delta.Magnitude)
  rootPart.AssemblyLinearVelocity=Vector3.zero
 else a.evade=nil end
end
return Evade
