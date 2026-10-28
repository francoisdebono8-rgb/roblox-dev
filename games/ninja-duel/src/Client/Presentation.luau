-- Velmora's additive combat motion and hit feedback, retaining Ninja Duel's
-- deception visual. Rendering is continuous: bodies are drawn on a smoothed
-- track of their replicated roots instead of jumping once per network packet.
local Motion=require(script.Parent.VelmoraMotionEngine)
local Feedback=require(script.Parent.VelmoraHitFeedback)
local Effects=require(script.Parent.Effects)
-- Bodies that are not fighters (Naruto's shadow clones).
local BodyViews=require(script.Parent.BodyViews)
local Smear=require(script.Parent.MotionSmear)
local Presentation={};Presentation.__index=Presentation
local LOCOMOTION_POSE_SPEED=26
function Presentation.new()
	return setmetatable({last={},recoil={},impactSerial=0,impactEpoch=nil,clocks={},landings={},botModel=nil,fx=Effects.new(),bodies=BodyViews.new(),smooth={}},Presentation)
end
-- The opponent's body in the viewer's duel folder: the server names it by the
-- id it sends as data.bot.id ("AIFighter" against the AI, a duelist online).
function Presentation.opponent(data,folder)
	return folder and folder:FindFirstChild(data and data.bot and data.bot.id or "AIFighter")
end
-- The replicated root of a server-owned fighter only moves every other
-- rendered frame (physics replication at ~30 Hz against a 60 Hz render), so a
-- body drawn on it advances in jerks. Each fighter is instead drawn on a short
-- interpolated track of its replicated positions, a fixed ~45 ms behind: the
-- motion is continuous every frame. A real teleport still snaps.
local TRACK_DELAY,TRACK_SNAP,TRACK_MAX,TRACK_SAMPLES=.045,45,12,8
local function yawOf(cf)
	local look=cf.LookVector
	return math.atan2(-look.X,-look.Z)
end
local function lerpAngle(a,b,t)
	local d=(b-a+math.pi)%(2*math.pi)-math.pi
	return a+d*t
end
function Presentation:smoothRoot(key,actualCF,dt,warp)
	local now=os.clock()
	local st=self.smooth[key]
	if not st then st={samples={},vel=Vector3.zero};self.smooth[key]=st end
	local samples=st.samples
	local actual=actualCF.Position
	local newest=samples[#samples]
	if (warp and warp~=st.warp) or (newest and (actual-newest.p).Magnitude>TRACK_SNAP) then
		table.clear(samples);newest=nil;st.vel=Vector3.zero;st.pos=nil
	end
	st.warp=warp
	local yaw=yawOf(actualCF)
	if not newest or (actual-newest.p).Magnitude>1e-4 or math.abs(lerpAngle(newest.yaw,yaw,1)-newest.yaw)>1e-4 then
		table.insert(samples,{t=now,p=actual,yaw=yaw})
		while #samples>TRACK_SAMPLES do table.remove(samples,1) end
	elseif now-newest.t>.1 then
		-- Standing still: keep the track anchored to the present.
		newest.t=now
	end
	local at=now-TRACK_DELAY
	local pos,face=samples[#samples].p,samples[#samples].yaw
	if at<=samples[1].t then pos,face=samples[1].p,samples[1].yaw
	else
		for i=#samples-1,1,-1 do
			local a,b=samples[i],samples[i+1]
			if at>=a.t then
				local span=b.t-a.t
				local t=if span>1e-4 then math.clamp((at-a.t)/span,0,1) else 1
				pos=a.p:Lerp(b.p,t);face=lerpAngle(a.yaw,b.yaw,t)
				break
			end
		end
	end
	local offset=pos-actual
	if offset.Magnitude>TRACK_MAX then pos=actual+offset.Unit*TRACK_MAX end
	-- Velocity of the drawn body: what the legs and lean must match.
	if st.pos then
		local v=(pos-st.pos)/math.max(dt,1/240)
		st.vel=st.vel:Lerp(v,math.min(1,dt*18))
	end
	st.pos=pos;st.yaw=face
	return CFrame.new(pos)*CFrame.Angles(0,face,0)
end
function Presentation:visualRoot(key)
	local st=self.smooth[key]
	return st and st.pos
end
function Presentation:visualVelocity(key)
	local st=self.smooth[key]
	return st and st.vel
end
-- Just before rendering: the replicated roots have their positions for this
-- frame; advance each track and draw the body on it (position and facing).
function Presentation:smoothStep(data,dt)
	if not data or data.phase~="Duel" then return end
	local character=game:GetService("Players").LocalPlayer.Character
	local folder=character and character.Parent
	for key,model in {human=character,bot=Presentation.opponent(data,folder)} do
		local root=model and model:FindFirstChild("HumanoidRootPart")
		local actor=data[key]
		if root and not root.Anchored and actor then
			-- The true replicated pose: if the root still sits exactly where we
			-- drew it last frame, no new packet arrived since.
			local st=self.smooth[key]
			local actualCF=root.CFrame
			if st and st.drawnCF and st.replicatedCF and (actualCF.Position-st.drawnCF.Position).Magnitude<1e-3
				and actualCF.LookVector:Dot(st.drawnCF.LookVector)>.99999 then actualCF=st.replicatedCF end
			local drawn=self:smoothRoot(key,actualCF,math.max(dt,1/240),actor.warpSerial)
			st=self.smooth[key]
			st.replicatedCF=actualCF
			-- Draw the whole body on the track for this frame only; the next
			-- replication packet overwrites the client copy, never the server.
			local target=drawn
			if (target.Position-root.Position).Magnitude>1e-4 or target.LookVector:Dot(root.CFrame.LookVector)<.99999 then
				model:PivotTo(target*root.CFrame:Inverse()*model:GetPivot())
			end
			st.drawnCF=root.CFrame
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
   Feedback.impact(impact.style or "light",impact.position,impact)
   self.fx:impact(impact,folder)
   if camera and camera.impulse then camera:impulse(impact.style,impact.role,impact) end
  end
 end
 self.impactSerial=serial
end
-- Genjutsu image. The server says who is deceived (illusion + decoy on that
-- actor). Seen by the deceived player, the image IS Itachi: a frozen copy in
-- his stance facing them, with a faint red outline pulsing now and then (the
-- tell), and the real body behind it drawn faint. Seen by Itachi's player, the
-- image is a red translucent afterimage of himself: he sees the trap he left.
function Presentation.fade(model,amount)
 if not model then return end
 for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=amount end end
end
function Presentation:clearEcho()
 local echo=self.echo
 if not echo then return end
 if echo.model then echo.model:Destroy() end
 if echo.mode=="deceived" then Presentation.fade(echo.source,0) end
 self.echo=nil
end
-- Which view of the genjutsu this client draws: "deceived" (my fighter is
-- under it), "caster" (the opponent is under mine) or nil.
function Presentation.illusionView(data)
 if not data or data.phase~="Duel" then return nil end
 if data.human and (data.human.illusion or 0)>0 and data.human.decoy then return "deceived",data.human.decoy end
 if data.bot and (data.bot.illusion or 0)>0 and data.bot.decoy then return "caster",data.bot.decoy end
 return nil
end
function Presentation:illusion(data,model)
 local folder=model and model.Parent
 local opponent=Presentation.opponent(data,folder)
 local mode,decoy=Presentation.illusionView(data)
 local source=if mode=="deceived" then opponent elseif mode=="caster" then model else nil
 local watcher=if mode=="deceived" then model else opponent
 if not source then mode=nil end
 local echo=self.echo
 if echo and (echo.mode~=mode or echo.epoch~=data.epoch or echo.source~=source) then self:clearEcho();echo=nil end
 if not mode then return end
 if not echo then
  echo={mode=mode,epoch=data.epoch,source=source,model=self.fx:image(source,mode),born=os.clock()}
  self.echo=echo
 end
 if mode=="deceived" then Presentation.fade(source,.55) end
 local image=echo.model
 if not image then return end
 local root=watcher and watcher:FindFirstChild("HumanoidRootPart")
 local look=if root then Vector3.new(root.Position.X-decoy.X,0,root.Position.Z-decoy.Z) else Vector3.zero
 if look.Magnitude<.1 then look=Vector3.zAxis end
 local t=os.clock()-echo.born
 local at=decoy+Vector3.new(0,math.sin(t*5)*.03,0)
 image:PivotTo(CFrame.lookAt(at,at+look.Unit))
 local tell=image:FindFirstChild("Tell")
 if tell then tell.OutlineTransparency=1-.45*math.max(0,math.sin(t*7))^8 end
end
-- Local presentation clocks: an attack animates from the frame it was first
-- seen, so a late or jittery packet cannot make the body jump backwards.
local function clockFor(self,key,actor,now)
 local clock=self.clocks[key]
 if not clock then clock={};self.clocks[key]=clock end
 -- A new swing restarts the clock even when it repeats the same move name.
 if actor.attackName~=clock.attackName or (actor.attackSerial or 0)~=clock.attackSerial then
  -- Start the clip where the server already is: a snapshot arrives up to an
  -- interval late, and a clip restarted at 0 trailed the real contact (the
  -- launcher's kick was cut off by the chase before it ever showed).
  clock.attackName=actor.attackName;clock.attackSerial=actor.attackSerial or 0
  clock.attackAt=now-math.clamp(actor.attackElapsed or 0,0,.12)
 end
 -- A fresh contact restarts the recoil even when it repeats the same reaction
 -- kind (Light1 -> Light2 are both HitStun), so every hit reads as a hit.
 if actor.reaction~=clock.reaction or (actor.reaction and (actor.impactSerial or 0)~=clock.impactSerial) then
  clock.reaction=actor.reaction;clock.reactionAt=now
 end
 clock.impactSerial=actor.impactSerial or 0
 clock.attackElapsed=if actor.attackName then now-clock.attackAt else 0
 clock.reactionElapsed=if actor.reaction then now-clock.reactionAt else 0
 return clock
end
-- A landing belongs to one body. Opponent landings must never bend the
-- player's knees; keep a local phase so compression releases before neutral.
function Presentation:landing(key,actor,previous,now)
 if previous and previous.airborne and not actor.airborne then
  self.landings[key]={at=now,duration=if actor.landStrong then .22 else .1,strong=actor.landStrong==true}
 end
 local landing=self.landings[key]
 if not landing then return false,0,false end
 if actor.airborne or now>=landing.at+landing.duration then
  self.landings[key]=nil
  return false,0,false
 end
 return true,math.clamp((now-landing.at)/landing.duration,0,1),landing.strong
end
function Presentation:update(data,dt)
 dt=math.max(dt or 1/60,.001)
 -- One presentation tick per rendered frame; every pose below reads this clock.
 Motion.tick(dt)
 local players=game:GetService("Players")
 if not data.human then
  self:clearEcho()
  self.fx:update(data,dt,nil)
  self.bodies:update(data,dt,nil)
  return
 end
 if self.epoch~=data.epoch then
  -- Character switch, rematch or a fresh duel: the only place a hard reset is
  -- right. Normal presentation never snaps the skeleton.
  self.epoch=data.epoch
  table.clear(self.clocks);table.clear(self.last);table.clear(self.smooth);table.clear(self.landings)
  self.smears={}
  if players.LocalPlayer.Character then Motion.reset(players.LocalPlayer.Character) end
  if self.botModel then Motion.reset(self.botModel) end
 end
 local now=os.clock()
 local character=players.LocalPlayer.Character
 self:illusion(data,character)
 local folder=character and character.Parent
 local bot=Presentation.opponent(data,folder)
 self.botModel=bot
 local models={human=character,bot=bot}
 for key,model in models do
  local actor=data[key];local previous=self.last[key]
  if model and actor then
   -- The motion engine owns every joint. A Humanoid Animator (run locally for
   -- the player's own character) resets the joints between our write and the
   -- render, which left the body in its rest pose; remove it on this client.
   local humanoid=model:FindFirstChildOfClass("Humanoid")
   local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
   if animator then animator:Destroy() end
   local clock=clockFor(self,key,actor,now)
   local root=model:FindFirstChild("HumanoidRootPart")
   -- The body is drawn on a smoothed track of the replicated root (see
   -- Presentation:smoothStep, run just before each frame is rendered).
   -- Take-off and get-up sounds, from the state change itself.
   if previous and not previous.airborne and actor.airborne and root and root.AssemblyLinearVelocity.Y>15 and not actor.reaction then self.fx:jumpSound(root.Position) end
   if previous and previous.reaction=="Wakeup" and actor.reaction~="Wakeup" and root then self.fx:getUpSound(root.Position) end
   local landing,landingPhase,landingStrong=self:landing(key,actor,previous,now)
   -- Health lost without a new contact (burn, sand): a slow drain such as the
   -- curse mark (~0.1 HP per snapshot) is not a hit and spawns nothing.
   if previous and actor.health<=previous.health-1 and actor.impactSerial==(previous.impactSerial or -1) then
    local damage=previous.health-actor.health
    if root then Feedback.burst(root.Position,if actor.cue=="GUARDED" then Color3.fromRGB(255,235,160) else Color3.fromRGB(255,91,74),damage,actor.cue=="GUARDED") end
   end
   if actor.events and previous and actor.events.Parry and actor.events.Parry>(previous.parry or 0) then
    if root then Feedback.burst(root.Position,Color3.fromRGB(255,245,176),0,true) end
   end
   -- Locomotion is posed from the rig's live velocity, not a 10 Hz value.
   local tracked=self:visualVelocity(key)
   local velocity=if root then root.AssemblyLinearVelocity else actor.velocity
   if tracked and velocity then
    -- Wall motion is positioned by the server with zero assembly velocity.
    -- Its vertical cadence must follow the drawn track as well as its X/Z.
    velocity=Vector3.new(tracked.X,if actor.wall then tracked.Y else velocity.Y,tracked.Z)
   end
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
   visual.landing=landing;visual.landingPhase=landingPhase;visual.landStrong=landingStrong
   visual.intro=data.intro
   local other=if key=="human" then "bot" else "human"
   visual.lookAt=self:visualRoot(other) or (data[other] and data[other].position)
   -- Throws and casts run on the shared server clock (slightly behind, like the
   -- projectiles), so the blade leaves the hand on the frame it starts flying.
   if data.serverNow then
    local visualNow=workspace:GetServerTimeNow()-Effects.DELAY
    if actor.throwElapsed then visual.throwElapsed=visualNow-(data.serverNow-actor.throwElapsed) end
    if actor.castElapsed then visual.castElapsed=workspace:GetServerTimeNow()-(data.serverNow-actor.castElapsed) end
    if actor.channel then visual.channel=math.max(0,actor.channel-(workspace:GetServerTimeNow()-data.serverNow)) end
   end
   Motion.weapon(model,visual)
   self.presented=self.presented or {}
   self.presented[key]=string.format("%s hp=%s state=%s",tostring(Motion.present(model,visual,clock,dt)),tostring(visual.health),tostring(visual.state))
   -- Speed smear (fluidity pass): faster than a sprint, or a teleport, is
   -- drawn as motion. Not during an intro or between rounds (repositioning).
   self.smears=self.smears or {}
   self.smears[key]=self.smears[key] or {}
   if data.phase=="Duel" and (data.intro or 0)<=0 then Smear.step(self.smears[key],model,dt) else self.smears[key]={} end
   self.arcs=self.arcs or {}
   self.arcs[key]=self.arcs[key] or {}
   Smear.limbs(self.arcs[key],model,actor.attackName~=nil and (actor.state=="Startup" or actor.state=="Active"))
   self.last[key]={health=actor.health,attackName=actor.attackName,parry=actor.events and actor.events.Parry or 0,
    impactSerial=actor.impactSerial or 0,airborne=actor.airborne,reaction=actor.reaction}
  end
 end
 self.fx:update(data,dt,folder)
 self.bodies:update(data,dt,folder)
end
return Presentation
