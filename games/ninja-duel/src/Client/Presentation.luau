-- Velmora's additive combat motion and hit feedback, retaining Ninja Duel's
-- deception visual. Rendering is continuous: bodies are drawn on a smoothed
-- track of their replicated roots instead of jumping once per network packet.
local Motion=require(script.Parent.VelmoraMotionEngine)
local Feedback=require(script.Parent.VelmoraHitFeedback)
local Effects=require(script.Parent.Effects)
local Presentation={};Presentation.__index=Presentation
local LOCOMOTION_POSE_SPEED=26
function Presentation.new()
	return setmetatable({last={},recoil={},impactSerial=0,impactEpoch=nil,clocks={},botModel=nil,fx=Effects.new(),smooth={}},Presentation)
end
-- The replicated root of a server-owned fighter only moves every other
-- rendered frame (physics replication at ~30 Hz against a 60 Hz render), so a
-- body drawn on it advances in jerks. Each fighter is instead drawn on a short
-- interpolated track of its replicated positions, a fixed ~45 ms behind: the
-- motion is continuous every frame. A real teleport still snaps.
local TRACK_DELAY,TRACK_SNAP,TRACK_MAX,TRACK_SAMPLES=.045,9,6,8
function Presentation:smoothRoot(key,actual,dt)
	local now=os.clock()
	local st=self.smooth[key]
	if not st then st={samples={}};self.smooth[key]=st end
	local samples=st.samples
	local newest=samples[#samples]
	if newest and (actual-newest.p).Magnitude>TRACK_SNAP then table.clear(samples);newest=nil end
	if not newest or (actual-newest.p).Magnitude>1e-4 then
		table.insert(samples,{t=now,p=actual})
		while #samples>TRACK_SAMPLES do table.remove(samples,1) end
	elseif now-newest.t>.1 then
		-- Standing still: keep the track anchored to the present.
		newest.t=now
	end
	local at=now-TRACK_DELAY
	local pos=samples[#samples].p
	if at<=samples[1].t then pos=samples[1].p
	else
		for i=#samples-1,1,-1 do
			local a,b=samples[i],samples[i+1]
			if at>=a.t then
				local span=b.t-a.t
				pos=if span>1e-4 then a.p:Lerp(b.p,math.clamp((at-a.t)/span,0,1)) else b.p
				break
			end
		end
	end
	local offset=pos-actual
	if offset.Magnitude>TRACK_MAX then pos=actual+offset.Unit*TRACK_MAX end
	st.pos=pos
	return pos
end
function Presentation:visualRoot(key)
	local st=self.smooth[key]
	return st and st.pos
end
-- Post-simulation: the replicated roots have moved for this frame; advance the
-- filter and draw each skeleton on its smoothed track before rendering.
function Presentation:smoothStep(data,dt)
	if not data or data.phase~="Duel" then return end
	local character=game:GetService("Players").LocalPlayer.Character
	local folder=character and character.Parent
	for key,model in {human=character,bot=folder and folder:FindFirstChild("AIFighter")} do
		local root=model and model:FindFirstChild("HumanoidRootPart")
		if root and not root.Anchored then
			-- The true replicated position: if the root still sits exactly where we
			-- drew it last frame, no new packet arrived and the server position is
			-- the one we last saw.
			local st=self.smooth[key]
			local actual=root.Position
			if st and st.drawn and st.replicated and (actual-st.drawn).Magnitude<1e-3 then actual=st.replicated end
			local smoothed=self:smoothRoot(key,actual,math.max(dt,1/240))
			st=self.smooth[key]
			st.replicated=actual
			-- Draw the whole body on the smoothed track for this frame only; the
			-- next replication packet overwrites the client copy, never the server.
			local delta=smoothed-root.Position
			if delta.Magnitude>1e-4 then model:PivotTo(model:GetPivot()+delta) end
			st.drawn=root.Position
		end
	end
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
  table.clear(self.clocks);table.clear(self.last);table.clear(self.smooth)
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
   local clock=clockFor(self,key,actor,now)
   local root=model:FindFirstChild("HumanoidRootPart")
   -- The body is drawn on a smoothed track of the replicated root (see
   -- Presentation:smoothStep, run just before each frame is rendered).
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
