-- Velmora's additive combat motion and hit feedback, retaining Ninja Duel's
-- deception visual. Rendering is continuous: it interpolates a short snapshot
-- buffer instead of stepping the whole body once per network packet.
local Motion=require(script.Parent.VelmoraMotionEngine)
local Feedback=require(script.Parent.VelmoraHitFeedback)
local Effects=require(script.Parent.Effects)
local Presentation={};Presentation.__index=Presentation
-- Render slightly behind the newest snapshot so motion is always interpolated
-- between two known samples instead of being extrapolated from one.
local RENDER_DELAY=.085
local BUFFER=8
-- Beyond this, the server really did move the actor (substitution, flashstep,
-- respawn) and a hard correction is correct.
local SNAP_DISTANCE=14
local LOCOMOTION_POSE_SPEED=26
function Presentation.new()
	return setmetatable({last={},recoil={},impactSerial=0,impactEpoch=nil,samples={},clocks={},botModel=nil,fx=Effects.new()},Presentation)
end
-- Contact feed straight from the server: play the impact on the frame the hit
-- happened, so sound and VFX never lead or lag the animation.
function Presentation:impacts(data,camera)
 -- Projectiles first, so a contact in the same packet can finish its blade.
 if data.phase=="Duel" then self.fx:sync(data) end
 if not data.impacts then return end
 -- The server restarts its contact serial with every duel.
 if self.impactEpoch~=data.epoch then self.impactEpoch=data.epoch;self.impactSerial=0 end
 local serial=data.impactSerial or 0
 if serial<=self.impactSerial then return end
 local character=game:GetService("Players").LocalPlayer.Character
 local folder=character and character.Parent
 for _,impact in data.impacts do
  if impact.serial==nil or impact.serial>self.impactSerial then
   Feedback.impact(impact.style or "light",impact.position)
   self.fx:impact(impact,folder)
   if camera and camera.impulse then camera:impulse(impact.style,impact.role,impact) end
  end
 end
 self.impactSerial=serial
end
function Presentation:illusion(data,model)
 local active=data.phase=="Duel" and data.human.illusion>0 and data.human.decoy
 local opponent=model and model.Parent and model.Parent:FindFirstChild("AIFighter")
 active=active and opponent~=nil
 if active and opponent and not self.echo then
  local ghost=opponent:Clone();ghost.Name="LocalAfterimage"
  for _,v in ghost:GetDescendants() do
   if v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanQuery=false;v.Transparency=math.max(v.Transparency,.72)
   elseif v:IsA("Humanoid") or v:IsA("Sound") or v:IsA("Trail") then v:Destroy() end
  end
  ghost.Parent=workspace;self.echo=ghost;self.echoEpoch=data.epoch
 end
 if self.echo then
  if not active or self.echoEpoch~=data.epoch then self.echo:Destroy();self.echo=nil
  else self.echo:PivotTo(CFrame.new(data.human.decoy)*opponent:GetPivot().Rotation) end
 end
end
-- Local presentation clocks: an attack animates from the frame it was first
-- seen, so a late or jittery packet cannot make the body jump backwards.
local function clockFor(self,key,actor,now)
 local clock=self.clocks[key]
 if not clock then clock={};self.clocks[key]=clock end
 -- A new swing restarts the clock even when it repeats the same move name.
 if actor.attackName~=clock.attackName or (actor.attackSerial or 0)~=clock.attackSerial then
  clock.attackName=actor.attackName;clock.attackSerial=actor.attackSerial or 0;clock.attackAt=now
 end
 if actor.reaction~=clock.reaction then
  clock.reaction=actor.reaction;clock.reactionAt=now
 end
 clock.attackElapsed=if actor.attackName then now-clock.attackAt else 0
 clock.reactionElapsed=if actor.reaction then now-clock.reactionAt else 0
 return clock
end
function Presentation:record(key,position)
 local samples=self.samples[key]
 if not samples then samples={};self.samples[key]=samples end
 local newest=samples[#samples]
 -- A stalled actor must not accumulate latency from identical samples.
 if newest and (newest.position-position).Magnitude<.01 and os.clock()-newest.at<.05 then return end
 table.insert(samples,{at=os.clock(),position=position})
 while #samples>BUFFER do table.remove(samples,1) end
end
function Presentation:visualPosition(key)
 local samples=self.samples[key]
 if not samples or #samples==0 then return nil end
 local target=os.clock()-RENDER_DELAY
 local newest=samples[#samples]
 if target>=newest.at then return newest.position end
 if target<=samples[1].at then return samples[1].position end
 for i=#samples-1,1,-1 do
  local a,b=samples[i],samples[i+1]
  if target>=a.at and target<=b.at then
   local span=b.at-a.at
   return a.position:Lerp(b.position,if span>0 then (target-a.at)/span else 0)
  end
 end
 return newest.position
end
function Presentation:update(data,dt)
 dt=math.max(dt or 1/60,.001)
 -- One presentation tick per rendered frame; every pose below reads this clock.
 Motion.tick(dt)
 local players=game:GetService("Players")
 if not data.human then
  if self.echo then self.echo:Destroy();self.echo=nil end
  self.fx:update(data,dt,nil)
  return
 end
 if self.epoch~=data.epoch then
  -- Character switch, rematch or a fresh duel: the only place a hard reset is
  -- right. Normal presentation never snaps the skeleton.
  self.epoch=data.epoch
  table.clear(self.samples);table.clear(self.clocks);table.clear(self.last)
  if players.LocalPlayer.Character then Motion.reset(players.LocalPlayer.Character) end
  if self.botModel then Motion.reset(self.botModel) end
 end
 local now=os.clock()
 local character=players.LocalPlayer.Character
 self:illusion(data,character)
 local folder=character and character.Parent
 local bot=folder and folder:FindFirstChild("AIFighter")
 self.botModel=bot
 local models={human=character,bot=bot}
 for key,model in models do
  local actor=data[key];local previous=self.last[key]
  if model and actor then
   self:record(key,actor.position)
   local clock=clockFor(self,key,actor,now)
   local root=model:FindFirstChild("HumanoidRootPart")
   -- Continue the body smoothly towards the interpolated network position.
   local visual=self:visualPosition(key)
   if root and visual then
    local error_=(root.Position-visual).Magnitude
    if error_>SNAP_DISTANCE then
     model:PivotTo(CFrame.new(visual)*model:GetPivot().Rotation)
    elseif error_>.05 then
     local alpha=1-math.exp(-dt*18)
     model:PivotTo(CFrame.new(root.Position:Lerp(visual,alpha))*model:GetPivot().Rotation)
    end
   end
   if previous and previous.airborne and not actor.airborne then
    -- Landing compression lasts a few frames; a soft landing barely shows.
    self.landingUntil=now+(if actor.landStrong then .22 else .1)
   end
   if previous and actor.health<previous.health and actor.impactSerial==(previous.impactSerial or -1) then
    local damage=previous.health-actor.health
    if root then Feedback.burst(root.Position,if actor.cue=="GUARDED" then Color3.fromRGB(255,235,160) else Color3.fromRGB(255,91,74),damage,actor.cue=="GUARDED") end
   end
   if actor.events and previous and actor.events.Parry and actor.events.Parry>(previous.parry or 0) then
    if root then Feedback.burst(root.Position,Color3.fromRGB(255,245,176),0,true) end
   end
   -- Locomotion is posed from the rig's live velocity, not a 10 Hz value.
   local velocity=if root then root.AssemblyLinearVelocity else actor.velocity
   local planar=if velocity then Vector3.new(velocity.X,0,velocity.Z).Magnitude else 0
   local speed=math.max(actor.speed or 0,planar)
   -- Everything the presentation contract needs, with locally measured clocks so
   -- a late packet cannot make the body replay its wind-up.
   local visual=table.clone(actor)
   -- A dash is server-driven translation: pose it from its declared direction.
   visual.velocity=if actor.state=="Dodging" then actor.velocity else velocity
   visual.speed=speed
   visual.reactionElapsed=clock.reactionElapsed
   visual.attackElapsed=clock.attackElapsed
   visual.landing=self.landingUntil~=nil and now<self.landingUntil
   visual.intro=data.intro
   -- Throws and casts run on the shared server clock (slightly behind, like the
   -- projectiles), so the blade leaves the hand on the frame it starts flying.
   if data.serverNow then
    local visualNow=workspace:GetServerTimeNow()-Effects.DELAY
    if actor.throwElapsed then visual.throwElapsed=visualNow-(data.serverNow-actor.throwElapsed) end
    if actor.castElapsed then visual.castElapsed=workspace:GetServerTimeNow()-(data.serverNow-actor.castElapsed) end
    if actor.channel then visual.channel=math.max(0,actor.channel-(workspace:GetServerTimeNow()-data.serverNow)) end
   end
   Motion.weapon(model,visual)
   Motion.present(model,visual,clock,dt)
   self.last[key]={health=actor.health,attackName=actor.attackName,parry=actor.events and actor.events.Parry or 0,
    impactSerial=actor.impactSerial or 0,airborne=actor.airborne}
  end
 end
 self.fx:update(data,dt,folder)
end
return Presentation
