-- Duel camera. A locked third-person rig that keeps both fighters readable:
--  * it sits behind the player on the line to the opponent, a little over the
--    shoulder, and *orbits* (speed-limited) when the fighters swap sides, so a
--    Minato teleport behind the opponent turns the view around instead of
--    leaving the camera on the wrong side of the fight;
--  * distance and height grow with separation and vertical gap, so launchers,
--    chases and slams stay in frame;
--  * framing modes blend over several frames; impact shake and FOV kicks are
--    reserved for heavy moments.
local Camera={}; Camera.__index=Camera
local framing={
 -- (Fluidity pass, user reference 28/10) close behind the shoulder: the
 -- body fills the frame, every motion of it reads; the opponent ahead.
 Ground={distance=12.5,height=3.6,fov=64,lift=1.8,side=.55},
 -- (05/11, user on the pad: "on sent qu'elle bascule entre 2") The air,
 -- chase, slam and wall framings were 6 to 10 studs further and 8 to 14
 -- degrees wider than the ground one, and a string with a launcher went in,
 -- out and in again. Closer to the ground frame now (the gap and the height
 -- between the bodies still pull the lens back on their own), and every
 -- change of framing is eased over a third of a second (Camera:update).
 Launcher={distance=15.5,height=4,fov=68,lift=3.5,side=.5},
 Pursuit={distance=17,height=5,fov=70,lift=3,side=.5},
 AirCombo={distance=15.5,height=3.5,fov=68,lift=2.5,side=.5},
 Slam={distance=16.5,height=7.5,fov=70,lift=-1,side=.45},
 Wall={distance=17,height=6,fov=70,lift=3,side=.5},
}
local function mode(h,b)
 if h.attackName=="Slam" or b.attackName=="Slam" then return "Slam" end
 if h.state=="Pursuit" or b.state=="Pursuit" then return "Pursuit" end
 if h.wall or b.wall or h.reaction=="WallSplat" or b.reaction=="WallSplat" then return "Wall" end
 if h.reaction=="Launched" or b.reaction=="Launched" then return "Launcher" end
 -- Air combo framing is for fighting in the air, not for every jump: an
 -- ordinary ninja jump keeps the ground rig and its vertical tracking.
 local function airFight(x) return x.airborne and (x.attackName~=nil or x.reaction~=nil) end
 if airFight(h) or airFight(b) then return "AirCombo" end
 return "Ground"
end
local function wrap(angle)
 return (angle+math.pi)%(2*math.pi)-math.pi
end
-- What stops the lens (it never goes into these): the floor, the stadium
-- wall in every piece (the wall, its cap: a lens lifted over a fight along the
-- wall used to slip through the cap into the stands), anything marked as a
-- wall, and any very large part. Smaller fighting-space props fade instead.
local function solid(part)
	return part.Name=="Training floor" or string.sub(part.Name,1,8)=="Boundary" or part:GetAttribute("NinjaWall")==true or part.Size.Magnitude>40
end
Camera.solid=solid
-- (08/11, F7 tool: the lens behind a field tree hid the player) A field tree
-- is an invisible box (World: cover, line of sight, breakable) carrying the
-- Blender tree. The lens's ray stops on the box, and fading the box alone
-- changed nothing on screen: an invisible part in the way fades what it
-- carries.
local function fadeHit(part,faded)
	faded[part]=true
	if part.Transparency>=.95 and part.GetDescendants then
		for _,d in part:GetDescendants() do if d:IsA("BasePart") then faded[d]=true end end
	end
end
Camera.fadeHit=fadeHit
function Camera.new()
	-- (DEC-031, user 03/11: "on est sur du Storm total") Free by default:
	-- the mouse turns the lens, SHIFT locks on.
	local self=setmetatable({locked=false,look=Vector2.zero,yaw=0,pitch=.22,lastEpoch=-1,lastHealth=nil,lastEnemyHealth=nil,
		shakeUntil=0,shakeSize=0,fovKick=0,focus=nil,boomAngle=nil,distance=nil,rng=Random.new(),zoom=0,mode=nil},Camera)
 local UIS=game:GetService("UserInputService")
 -- Right mouse owns the heavy attack, so orbit and zoom are always live
 -- instead of needing a held modifier. Free-look only applies unlocked.
 UIS.InputChanged:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseMovement and not self.locked then
   self.yaw+=input.Delta.X*.004;self.pitch=math.clamp(self.pitch-input.Delta.Y*.003,.04,.9)
   if input.Delta.Magnitude>.5 then self.lastLookInput=os.clock() end
  elseif input.UserInputType==Enum.UserInputType.MouseWheel then
   self.zoom=math.clamp(self.zoom-input.Position.Z*1.4,-6,12)
  end
 end)
 return self
end
-- Locked, yaw is an offset from "behind the player"; unlocked it is an
-- absolute heading. Convert on toggle so the lens stays where it is instead of
-- swinging to world north (and dragging the movement axes with it).
function Camera:setLocked(locked)
 if locked==self.locked then return end
 if locked then self.yaw=0 else self.yaw=self.boomAngle or self.yaw end
 self.locked=locked
end
-- Impact-driven impulse. Small events must not make the camera twitch: only a
-- finisher, launcher, parry, slam, teleport or big jutsu earns a reaction.
local IMPULSE={
 whiff={0,0},spent={0,0},seals={0,0},kunai={0,0},shuriken={0,0},stick={0,0},fade={0,0},cast={0,0},chase={.02,1.2},dodge={.01,.25},substitute={.02,.4},
 -- (FEEL 05/11) a landed light blow is felt in the lens too (was .02/.3).
 light={.05,.7},air={.055,.8},landing={.04,.6},block={.04,.6},quickstep={.015,.8},teleport={.03,2.2},mirage={0,0},burst={.02,1},
 -- (Stage 6) the ultimates and the awakenings' moments.
 jutsuclash={.26,3.2},conduct={.08,1},steam={.03,.8},puddle={0,0},sandmelt={0,0},
 ultimateStart={.08,2},ultimate={.12,1.2},ultimateTick={.05,.6},ultimateEnd={.3,3.2},ultimateMiss={0,0},tsukuyomi={.06,1.6},gate={.04,.8},reveal={0,0},
 launcher={.1,1.3},finisher={.13,1.6},parry={.14,1.7},jutsu={.15,1.8},fire={.32,3.2},
 slam={.26,2.6},wall={.14,1.1},wallbounce={.2,2.0},clash={.12,1.6},walltech={.02,.4},pin={.02,.25},ember={.02,.35},palm={.015,.2},palmburst={.06,.9},flow={.03,.6},awaken={.12,2.4},groundbounce={.18,1.8},worldbreak={.2,2.2},chidori={.1,2.2},afterimage={0,0},deflect={.01,.2},repel={.1,1.3},rotation={.04,.9},trigram={0,0},
}
-- (Stage 6) an ultimate takes the lens for its sequence (Server/Ultimates:
-- the "ultimate" contact carries kind, time, and the frame of the catch).
-- (Redone 02/11) Each sequence is filmed from its own shot list
-- (Shared/UltimateScripts: cuts, framings that follow a body, the fov of
-- each shot) instead of one orbit for all; it hands back where it stops.
local Scripts=require(game:GetService("ReplicatedStorage").NinjaDuel.UltimateScripts)
local CINEMA={
	clones={dist=14,height=4,rate=.5,fov=58},lion={dist=16,height=1.5,rate=.7,fov=62,follow=true},pyramid={dist=22,height=12,rate=.25,fov=60},
	lotus={dist=16,height=1.5,rate=.9,fov=62,follow=true},palms={dist=9,height=2.2,rate=.35,fov=48},tsukuyomi={dist=8,height=2,rate=.12,fov=42},
	flash={dist=15,height=5,rate=1.1,fov=60},raikiri={dist=15,height=3,rate=.35,fov=54},
}
Camera.CINEMA=CINEMA
function Camera:cinema(impact,now)
	local look=CINEMA[impact and impact.kind or ""] or CINEMA.clones
	local frame=nil
	if impact and impact.origin and impact.line and Scripts.KINDS[impact.kind or ""] then frame=Scripts.frame(impact.origin,impact.line) end
	self.cinematic={from=now,untilT=now+((impact and impact.time) or 3.4),look=look,sign=if math.random()<.5 then 1 else -1,
		kind=impact and impact.kind,frame=frame,owner=impact and impact.owner,victim=impact and impact.victim}
end
function Camera:impulse(style,role,impact)
	if style=="ultimate" then self:cinema(impact,os.clock())
	elseif (style=="ultimateEnd" or style=="ultimateMiss") and self.cinematic then self.cinematic.untilT=math.min(self.cinematic.untilT,os.clock()+.3) end
	local spec=IMPULSE[style] or IMPULSE.light
	if not spec or (spec[1]<=0 and spec[2]<=0) then return end
	local weight=if role=="victim" then 1.25 elseif role=="neutral" then .6 else .85
	-- (B1 lot 3) effects LOW: a calmer lens (a little shake, a small kick).
	if self.calm then weight*=.4 end
	local now=os.clock()
	self.shakeSize=math.max(self.shakeSize or 0,spec[1]*weight)
	self.fovKick=math.max(self.fovKick or 0,spec[2]*weight)
	self.shakeUntil=math.max(self.shakeUntil or 0,now+(if style=="slam" or style=="fire" then .18 else .07))
	-- A decisive blow gets a beat of space: the lens eases back, then settles.
	local SETTLE={finisher=1.6,launcher=1.2,slam=2.4,wallbounce=2.4,wall=1.4,clash=1.4,repel=1.8,parry=1.4,fire=2}
	if SETTLE[style] then self.settleSize=math.max(if now<(self.settleUntil or 0) then self.settleSize or 0 else 0,SETTLE[style]);self.settleUntil=now+.75 end
end
function Camera:mouse(data)
	local UIS=game:GetService("UserInputService")
	-- (Audit 04/11) watching a match: the cursor stays free for SKIP.
	local free=data~=nil and data.phase=="Duel" and not self.locked and not data.gamepad and not data.touch and not self.menuOpen and not data.spectate
	local want=if free then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	if UIS.MouseBehavior~=want then UIS.MouseBehavior=want end
end
-- (B1) The player's own body fades when the lens comes close to his head (a
-- wall behind him): see-through from 5.5 studs, at most 0.85. Only parts no
-- one else hid (an effect's hidden part stays at 1), and only parts it faded
-- itself are given back. The part list is kept per character.
local partsOf=setmetatable({},{__mode="k"})
function Camera:fadeSelf(character,lens,at)
	local amount=0
	if character and lens and at then
		amount=math.clamp((5.5-(lens-(at+Vector3.new(0,1.5,0))).Magnitude)/2.2,0,.85)
	end
	local faded=self.selfFaded
	if amount<=.01 then
		if faded then
			for part,value in faded do if part.Parent and math.abs(part.LocalTransparencyModifier-value)<1e-3 then part.LocalTransparencyModifier=0 end end
			self.selfFaded=nil
		end
		return
	end
	local parts=partsOf[character]
	if not parts or #parts==0 or not parts[1].Parent then
		parts={}
		local ok,list=pcall(function() return character:GetDescendants() end)
		for _,d in if ok then list else {} do if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then table.insert(parts,d) end end
		partsOf[character]=parts
	end
	faded=faded or {}
	for _,part in parts do
		local now=part.LocalTransparencyModifier
		if now<.99 and (faded[part]==nil and now<.01 or faded[part]~=nil) then part.LocalTransparencyModifier=amount;faded[part]=amount end
	end
	self.selfFaded=faded
end
-- (FEEL 05/11) How much to tilt the lens up (radians) and widen it (degrees)
-- so `top` (the higher body's head) is inside the frame without pushing
-- `bottom` (the player's feet) out of it. A margin of 5 degrees inside the
-- vertical field of view. Pure: Camera.spec checks it.
function Camera.keepInFrame(cf,fov,top,bottom)
	local half=math.rad(fov*.5)-math.rad(5)
	local function pitchOf(p)
		local v=cf:PointToObjectSpace(p)
		return math.atan2(v.Y,math.max(-v.Z,.1))
	end
	local need=pitchOf(top)-half
	if need<=0 then return 0,0 end
	-- Room under the feet before they leave the bottom edge.
	local room=math.max(0,pitchOf(bottom)+half)
	local tilt=math.min(need,room,.6)
	local widen=math.min(math.deg(need-tilt)*2,16)
	return tilt,widen
end
-- (FEEL 05/11, AVANT defect 1) The lens squeezed by a solid (the stadium
-- wall, the floor) looks for the nearest clear heading around the player:
-- tries half a radian, then one, then one and a half, on both sides, and
-- prefers what is closest to the swing it already has. Back at zero once the
-- plain heading has been clear for 0.6 s. Only solids count: props fade.
local WALL_TRIES={0,.5,-.5,1,-1,1.5,-1.5}
function Camera:steerAroundWall(focus,distance,height,squeeze,ray,dt,clock)
	local base=self.baseAngle
	if not base or not distance then return end
	local current=self.wallGoal or 0
	local function clear(off)
		local angle=base+off
		local spot=focus+Vector3.new(math.sin(angle),0,math.cos(angle))*distance+Vector3.new(0,height,0)
		local reach=spot-focus
		local hit=workspace:Raycast(focus,reach,ray)
		return not (hit and solid(hit.Instance) and hit.Distance<reach.Magnitude*.75)
	end
	if squeeze>.3 then
		self.wallClearSince=nil
		local best,score=nil,math.huge
		for _,step in WALL_TRIES do
			local off=current+step
			if math.abs(off)<=1.6 and clear(off) then
				local s=math.abs(step)+.25*math.abs(off)
				if s<score then best,score=off,s end
			end
		end
		if best then self.wallGoal=best end
	elseif current~=0 then
		if clear(0) then
			self.wallClearSince=self.wallClearSince or clock
			if clock-self.wallClearSince>.6 then self.wallGoal=0;self.wallClearSince=nil end
		else
			self.wallClearSince=nil
		end
	end
	local goal=self.wallGoal or 0
	local yaw=self.wallYaw or 0
	yaw+=(goal-yaw)*(1-math.exp(-dt*4))
	self.wallYaw=if math.abs(yaw)<1e-3 and goal==0 then nil else yaw
end
-- (FEEL 05/11, AVANT defect 5) The bushes along the wall and the field
-- trees' crowns are decor: no collision, no query (World/ArenaMeshes), so
-- the lens never faded them and a body that ran into one vanished inside it
-- (Studio, take 1: both fighters in a bush at the wall). Pieces close to a
-- fighter, or across the line from the lens to the player, fade; the list is
-- read once per arena.
local DECOR_FADE=.7
function Camera:fadeDecor(folder,a,target,lens,clock)
	local yard=folder and folder:FindFirstChild("Courtyard")
	local list=self.decorList
	if yard~=self.decorYard then
		list={}
		if yard then
			local center=nil
			for _,d in yard:GetDescendants() do
				if d:IsA("BasePart") and (string.sub(d.Name,1,5)=="Bush_" or string.sub(d.Name,1,5)=="Tree_") then
					table.insert(list,{part=d,center=d.Position,radius=math.max(d.Size.X,d.Size.Z)*.5,top=d.Position.Y+d.Size.Y*.5,bottom=d.Position.Y-d.Size.Y*.5})
				end
				if d.Name=="Training floor" then center=d.Position end
			end
			-- The forest beyond the wall stays as it is.
			if center then
				for i=#list,1,-1 do
					local flat=Vector3.new(list[i].center.X-center.X,0,list[i].center.Z-center.Z)
					if flat.Magnitude>(150) then table.remove(list,i) end
				end
			end
		end
		self.decorYard=yard;self.decorList=list
	end
	if not list or #list==0 then return end
	-- Ten times a second is enough for decor.
	if clock<(self.decorNext or 0) then return end
	self.decorNext=clock+.1
	local faded=self.decorFaded or {}
	local now={}
	local function near(item,p)
		local flat=Vector3.new(p.X-item.center.X,0,p.Z-item.center.Z).Magnitude
		return flat<item.radius+2.5 and p.Y-3<item.top
	end
	-- (08/11, F7 tool) Across the line over the piece's whole height, not
	-- near its centre: a trunk's centre stands 7 to 9 studs up, and a line at
	-- body height through the trunk passed "too far" from it - the trunk hid
	-- the player and stayed opaque.
	local function across(item)
		if not lens then return false end
		local seg=a-lens
		if seg.Magnitude<.1 then return false end
		local flat=Vector3.new(seg.X,0,seg.Z)
		local len2=flat:Dot(flat)
		local t=if len2>1e-4 then math.clamp(Vector3.new(item.center.X-lens.X,0,item.center.Z-lens.Z):Dot(flat)/len2,0,1) else 0
		local p=lens+seg*t
		return Vector3.new(p.X-item.center.X,0,p.Z-item.center.Z).Magnitude<item.radius*.9 and p.Y>item.bottom-1 and p.Y<item.top+1
	end
	for _,item in list do
		local part=item.part
		if part.Parent and (near(item,a) or (target and near(item,target)) or across(item)) then
			now[part]=true
			if part.LocalTransparencyModifier<DECOR_FADE then part.LocalTransparencyModifier=DECOR_FADE end
		end
	end
	for part in faded do
		if not now[part] and part.Parent and math.abs(part.LocalTransparencyModifier-DECOR_FADE)<1e-3 then part.LocalTransparencyModifier=0 end
	end
	self.decorFaded=now
end
-- (B1, B0 defect 4) Whether the lens on screen is the player's own: not the
-- round's intro, a K.O., an ultimate's sequence or a watched match. Only then
-- does a free mouse lens turn the body (Main sends `look`): during the intro
-- the body followed the intro's lens and turned its back to the opponent.
function Camera:steers(data)
	if not data or data.phase~="Duel" or data.spectate or data.ko or (data.intro or 0)>0 then return false end
	if self.cinematic and os.clock()<self.cinematic.untilT then return false end
	return true
end
function Camera:update(data,dt)
	local camera=workspace.CurrentCamera
	pcall(self.mouse,self,data)
	-- Roster, online queue and fighter pick: no duel on screen yet.
	if not data or (data.phase~="Duel" and data.phase~="Result") or not data.human or not data.bot then
		self.lastHealth=nil; self.lastEnemyHealth=nil; camera.FieldOfView=70
		camera.CameraType=Enum.CameraType.Scriptable
		-- The roster and the online pick film the fighters' set (Client/MenuStage).
		if self.menuShot and data and (data.phase=="Selection" or data.phase=="Pick") then
			local shot,fov=self.menuShot()
			if shot then camera.CFrame=shot;camera.FieldOfView=fov or 70;return end
		end
		-- Slow establishing orbit over the training ground behind the menu.
		local t=os.clock()*.06
		camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(t)*88,38,math.cos(t)*88),Vector3.new(0,8,0)); return
	end
	local character=game:GetService("Players").LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	camera.CameraType=Enum.CameraType.Scriptable
	local fresh=self.lastEpoch~=data.epoch
	if fresh then self.faceOpponent=true end
	if fresh then self.lastHealth=data.human.health; self.lastEnemyHealth=data.bot.health;self.yaw=0;self.pitch=.22;self.focus=nil;self.boomAngle=nil;self.distance=nil;self.sprint=0;self.wasSprinting=false;self.lastImpactSerial=data.human.impactSerial or 0 end
	-- Fallback only: the impact-style impulse above owns normal reactions.
	-- Only a new contact counts: a health drain (curse mark) carries a stale
	-- impactHeavy and must not shake the lens every snapshot.
	local serial=data.human.impactSerial or 0
	if self.lastHealth and data.human.health<self.lastHealth and serial~=self.lastImpactSerial then
		local damage=self.lastHealth-data.human.health
		if data.human.impactHeavy or damage>=12 then
			self.shakeSize=math.max(self.shakeSize or 0,.2);self.fovKick=math.max(self.fovKick or 0,2);self.shakeUntil=math.max(self.shakeUntil or 0,os.clock()+.12)
		end
	end
	self.lastImpactSerial=serial
	self.lastHealth=data.human.health
	self.lastEnemyHealth=data.bot.health
	-- Frame the bodies where they are drawn (smoothed), not the stepping roots.
	local presentation=self.presentation
	local a=(presentation and presentation:visualRoot("human")) or root.Position
	local folder=root.Parent and root.Parent.Parent
	-- The opponent's model is named by its id (AIFighter locally, a duelist online).
	local bot=folder and folder:FindFirstChild(data.bot.id or "AIFighter")
	local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local target=(presentation and presentation:visualRoot("bot")) or (if b then b.Position else data.bot.position)
	-- Lost in the opponent's shroud (snapshot family.shrouded, QA-004 M3): the
	-- lens stops following him. It keeps the last place it saw him for its
	-- framing and turns like an unlocked camera; the lock preference itself
	-- (self.locked) is untouched and comes back as soon as he is seen again.
	local lost=data.human.family~=nil and data.human.family.shrouded==true
	if lost then
		if not self.lostFrom then self.lostFrom=self.lastSeen or target;self.fogYaw=self.boomAngle end
		target=self.lostFrom
	else
		self.lostFrom=nil;self.fogYaw=nil;self.lastSeen=target
	end
	local follow=self.locked and not lost
	local flat=Vector3.new(target.X-a.X,0,target.Z-a.Z)
	if flat.Magnitude<.01 then flat=-Vector3.zAxis end
	local separation=flat.Magnitude
	local vertical=math.abs(target.Y-a.Y)
	local aerial=data.human.airborne or data.bot.airborne or vertical>5
	local pursuit=data.human.state=="Pursuit" or data.bot.state=="Pursuit"
	local slam=data.human.attackName=="Slam" or data.bot.attackName=="Slam"
	local selected=mode(data.human,data.bot)
	-- (Audit 29/10) A mode is kept at least 0.4 s: the air-combo flags drop
	-- between two blows, and the lens swung 12 degrees and dollied in and out
	-- in the middle of a string.
	local clock=os.clock()
	if self.mode and selected~=self.mode and clock<(self.modeSince or 0)+.4 and selected~="Slam" and selected~="Pursuit" then selected=self.mode end
	if selected~=self.mode then self.modeSince=clock end
	self.mode=selected
	-- (User 03/11, free lens: "sometimes the camera switches from free to the
	-- character and back") The framing modes (chase 21 studs, wall 22, slam
	-- 19 and 10 up, against 12.5 on the ground) frame the pair when locked
	-- on; free, they jumped the lens in and out. Free keeps the ground frame.
	local goal=if follow then framing[selected] else framing.Ground
	-- (05/11) The framing in use slides toward the selected one (a third of a
	-- second) instead of switching tables.
	local frame=self.frameNow
	if fresh or not frame then frame=table.clone(goal)
	else
		local k=1-math.exp(-dt*3)
		for key,value in goal do frame[key]+=(value-frame[key])*k end
	end
	self.frameNow=frame
	-- (05/11) How locked the rig is, eased from 0 (free) to 1 (locked): the
	-- R3 / SHIFT toggle, or the shroud taking the opponent away, slides the
	-- focus, the distance and the height from one rig to the other instead of
	-- cutting between two cameras.
	local lockGoal=if follow then 1 else 0
	self.lockT=if fresh or self.lockT==nil then lockGoal else self.lockT+(lockGoal-self.lockT)*(1-math.exp(-dt*5))
	local lockT=self.lockT
	-- A pad or a phone: the right thumb also strikes (Camera:update below).
	local auto=data.gamepad==true or data.touch==true
	-- Look-stick / unlocked mouse orbit.
	self.yaw+=(self.look.X or 0)*dt*2.4;self.pitch=math.clamp(self.pitch-(self.look.Y or 0)*dt,.04,.9)
	if (self.look.Magnitude or 0)>.05 then self.lastLookInput=clock end
	-- (Audit 29/10) Locked, a nudge of the right stick is a glance: it eases
	-- back behind the shoulder once the stick rests (it stayed off for good).
	if follow and not data.ko and math.abs(self.look.X or 0)<.05 then self.yaw*=math.exp(-dt*1.6) end
	-- Boom heading: behind the player on the player->opponent line, offset over
	-- the shoulder. When the fighters swap sides the heading orbits around at a
	-- bounded angular speed rather than staying on the old side.
	local behind=-flat.Unit
	local desiredAngle
	if follow then
		-- (Audit 29/10) Bodies on top of each other (a cross-up, a vault, a
		-- grab): the line between them is noise, the heading holds instead of
		-- whipping at up to 420 deg/s.
		if separation<3.2 and self.heldBehind then behind=self.heldBehind else self.heldBehind=behind end
		-- (FEEL 05/11, AVANT defect 1) the wall swing (Camera:steerAroundWall) is
		-- added on top of the heading, so the boom's own rate limits ease it.
		self.baseAngle=math.atan2(behind.X,behind.Z)+self.yaw+frame.side
		desiredAngle=self.baseAngle+(self.wallYaw or 0)
	elseif lost and self.locked then
		desiredAngle=self.fogYaw or self.boomAngle or 0
	else
		if self.faceOpponent then self.yaw=math.atan2(behind.X,behind.Z);self.boomAngle=nil;self.faceOpponent=nil end
		-- (B1, B0 defect 4 and Studio 04/11 v37: free, the opponent was often off
		-- screen, at the wall above all) The free lens brings the opponent back
		-- toward the frame.
		-- (05/11, user on the pad: "on sent qu'elle bascule entre 2") It used to
		-- switch on after 0.9 s without the stick and without a move, then off
		-- at the first step: the lens kept changing hands. Now:
		--  * pad or phone (the right thumb also strikes): the follow is always
		--    on, a dead zone of 22 degrees around the centre and a spring past
		--    it, run or not; the stick only borrows the lens and, let go, the
		--    follow comes back over 0.6 s. The body stays free (only a lock
		--    turns it toward the opponent, DEC-031);
		--  * mouse: the player steers the body with the lens, so it only helps
		--    a player who stands and leaves it alone, eased in, never switched.
		local idle=clock-(self.lastLookInput or -math.huge)
		if not lost and not data.ko and separation>3.2 then
			local weight,edge,rate
			if auto then weight=math.clamp((idle-.6)/.6,0,1);edge=math.rad(22);rate=3.2
			else
				local still=presentation==nil or presentation.inputDir==nil or presentation.inputDir.Magnitude<.1
				weight=if still then math.clamp((idle-.9)/.6,0,1) else 0;edge=math.rad(32);rate=2.4
			end
			local off=wrap(self.yaw-math.atan2(behind.X,behind.Z))
			if weight>0 and math.abs(off)>edge then
				local turn=math.min((math.abs(off)-edge)*(1-math.exp(-dt*rate)),math.rad(150)*dt)*weight
				self.yaw=wrap(self.yaw-math.sign(off)*turn)
			end
		end
		-- (FEEL 05/11, Studio: free with a pad, backed into the wall, the player
		-- was off screen for 100 % of the frames) A pad's free lens swings
		-- along the wall too; a mouse lens stays the player's (it turns the body).
		self.baseAngle=self.yaw
		desiredAngle=self.yaw+(if auto then (self.wallYaw or 0) else 0)
	end
	if not self.boomAngle then self.boomAngle=desiredAngle end
	local delta=wrap(desiredAngle-self.boomAngle)
	-- A large swing (teleport behind, cross-up) turns faster than a small drift.
	local maxRate=if math.abs(delta)>1.4 then math.rad(420) else math.rad(240)
	local step=delta*(1-math.exp(-dt*(if math.abs(delta)>1.4 then 7 else 5)))
	step=math.clamp(step,-maxRate*dt,maxRate*dt)
	self.boomAngle=wrap(self.boomAngle+step)
	local boom=Vector3.new(math.sin(self.boomAngle),0,math.cos(self.boomAngle))
	-- Focus: between the fighters, biased towards the player, raised for air.
	local bias=if separation<=26 then .42 else math.max(.3,.42-(separation-26)*.003)
	local targetFocus=a:Lerp(target,bias)+Vector3.new(0,frame.lift,0)
	-- (FEEL 05/11, AVANT defect 2) A body far above (a chakra launcher at 66
	-- studs): the pair's focus rises to their middle, so the lens looks level
	-- at both instead of up from under one of them.
	if vertical>8 then
		local mid=a.Y+(target.Y-a.Y)*.5
		local k=math.clamp((vertical-8)/10,0,1)
		targetFocus=Vector3.new(targetFocus.X,targetFocus.Y+(mid+frame.lift-targetFocus.Y)*k,targetFocus.Z)
	end
	-- Sprint feel: only the player's own sprint (never the opponent's) eases
	-- in a wider lens, a slightly tighter and lower boom and a longer lead, so
	-- the floor streams past without the camera falling behind the body.
	local sprintTarget=if data.human.sprinting and (data.human.speed or 0)>24 then 1 else 0
	local sprint=self.sprint or 0
	sprint+=(sprintTarget-sprint)*(1-math.exp(-dt*(if sprintTarget>sprint then 6 else 3)))
	if sprintTarget==1 and not self.wasSprinting then self.fovKick=math.max(self.fovKick or 0,2.5) end
	self.sprint=sprint;self.wasSprinting=sprintTarget==1
	-- Lead a little where the player is going so a run is framed ahead of it.
	local moving=presentation and presentation:visualVelocity("human")
	if moving then
		local lead=Vector3.new(moving.X,0,moving.Z)*.11
		-- (B1, B0 defect 3: backing toward the lens, the body slid out of the
		-- bottom of the frame) No lead toward the lens: there is nothing to
		-- show "ahead" behind the camera, it only pulled the aim onto him.
		local back=lead:Dot(boom)
		if back>0 then lead-=boom*back end
		local leadCap=2.6+sprint*2.4
		if lead.Magnitude>leadCap then lead=lead.Unit*leadCap end
		self.lead=(self.lead or Vector3.zero):Lerp(lead,1-math.exp(-dt*4))
		targetFocus+=self.lead
	end
	-- Free, the lens follows the player (over the shoulder); locked, the pair.
	-- (05/11) Blended by lockT, so the toggle slides; on a pad the free lens
	-- leans a little toward the fight it keeps in view.
	-- (FEEL 05/11) A pad's free lens swung along the wall (steerAroundWall)
	-- frames the pair while it is swung, as a lock would: seen from the side,
	-- the player alone left the opponent out (Studio: 209 of 240 frames).
	local pairT=lockT
	if auto and not lost then pairT=math.max(lockT,math.clamp(math.abs(self.wallYaw or 0)/.6,0,1)) end
	if pairT<.999 then
		local look=Vector3.new(-boom.X,0,-boom.Z)
		local freeFocus=a+Vector3.new(0,1.6,0)+(if look.Magnitude>.05 then look.Unit:Cross(Vector3.yAxis)*1.7 else Vector3.zero)
		if auto and not lost then
			freeFocus+=flat.Unit*math.min(separation*.1,2.5)
			-- (FEEL 05/11) and climbs with a body launched far above.
			if vertical>8 then
				local k=math.clamp((vertical-8)/10,0,1)
				freeFocus=Vector3.new(freeFocus.X,freeFocus.Y+(targetFocus.Y-freeFocus.Y)*k,freeFocus.Z)
			end
		end
		targetFocus=freeFocus:Lerp(targetFocus,pairT)
	end
	-- (FEEL 05/11) a body shooting far up is followed faster (AVANT defect 2).
	local focusRate=if vertical>8 then 20 elseif aerial or pursuit then 13 else 9
	self.focus=if self.focus then self.focus:Lerp(targetFocus,1-math.exp(-dt*focusRate)) else targetFocus
	local focus=self.focus
	local settle=math.max(0,(self.settleUntil or 0)-os.clock())/.75
	-- K.O.: a slow drift around the finish while the lens eases out.
	if data.ko then self.yaw+=dt*.3 end
	local spread=math.min(math.max(0,separation-7),19)*.42+math.max(0,separation-26)*.22
	-- Free, the lens follows the player, not the pair: no pull-back for the gap
	-- to the opponent (a wall run 40 studs from him filmed the player tiny).
	-- (05/11) A pad's free lens keeps half of it (the opponent it keeps in view
	-- stays readable); the share slides with lockT.
	local freeShare=if auto and not lost then .5 else 0
	local share=freeShare+(1-freeShare)*pairT
	spread*=share
	local pairVertical=vertical*share
	-- (FEEL 05/11, AVANT defect 2) The distance that holds the whole height of
	-- the pair inside the vertical field of view (a launch of 60 studs needs a
	-- wide shot for its 2 seconds); ordinary jumps are under the threshold.
	-- A pad's free lens keeps the opponent in view by itself: for this it
	-- holds the whole height too (Studio 05/11: free, the lens still lost him
	-- for 1.1 s at half weight).
	local holdShare=if auto and not lost then 1 else share
	local verticalNeed=0
	if vertical*holdShare>8 then
		local halfV=math.rad(math.max(20,frame.fov*.5-6))
		verticalNeed=math.max(0,(vertical+6)*.5/math.tan(halfV)-(frame.distance+spread))*holdShare
	end
	local wantDistance=math.clamp(frame.distance-sprint*1.5+spread+pairVertical*.3+verticalNeed+self.zoom+(self.settleSize or 0)*math.sin(settle*math.pi*.5)+(if data.ko then 6 else 0),8.5,if verticalNeed>0 then 66 else 48)
	local distanceRate=if verticalNeed>0 and self.distance and wantDistance>self.distance then 12 else 4
	self.distance=if self.distance then self.distance+(wantDistance-self.distance)*(1-math.exp(-dt*distanceRate)) else wantDistance
	-- The lens rises with the gap up to 12 studs; past that the focus climbs
	-- to the pair's middle instead (above) and the lens stays level with it.
	local height=frame.height-sprint*.6+self.pitch*9+(math.min(vertical,12)*.28+math.min(math.max(0,separation-10)*.1,4))*share
	if slam then height+=math.clamp(-(data.human.velocity and data.human.velocity.Y or 0)*.04,0,4) end
	local desired=focus+boom*self.distance+Vector3.new(0,height,0)
	-- Match intro: a slow orbit that presents both fighters, then the normal
	-- rig takes over from wherever the orbit ended.
	-- (Partie 1 feedback: "I don't really see the opening pose".) The old
	-- orbit framed both bodies from 20+ studs, so an entrance pose was a few
	-- pixels. Fighting-game entrance instead (Storm 4, Tekken 8): each
	-- fighter in turn, three-quarter front, close enough that the pose reads,
	-- a slow dolly across; then the camera eases into the duel frame.
	if (data.intro or 0)>0 then
		self.introTotal=math.max(self.introTotal or 0,data.intro)
		local total,left=self.introTotal,data.intro
		local shown=total-left
		local split=total*.5
		local first=shown<split
		local subject=if first then a else target
		local other=if first then target else a
		local toward=Vector3.new(other.X-subject.X,0,other.Z-subject.Z)
		toward=if toward.Magnitude>.1 then toward.Unit else Vector3.zAxis
		local across=toward:Cross(Vector3.yAxis)
		local u=if first then shown/split else (shown-split)/math.max(total-split,1e-3)
		local sign=if first then 1 else -1
		local closeFocus=subject+Vector3.new(0,1.3-u*.3,0)
		local close=closeFocus+toward*(6.2+u*1.2)+across*sign*(2.6-u*1.6)+Vector3.new(0,.4+u*.3,0)
		local out=math.clamp((.5-left)/.5,0,1)
		out=out*out*(3-2*out)
		focus=closeFocus:Lerp(focus,out)
		desired=close:Lerp(desired,out)
		self.focus=focus
	else
		self.introTotal=nil
	end
	self.fovKick*=math.exp(-dt*9)
	local speed=data.human.speed or 0
	local targetFov=frame.fov+math.clamp(separation*.08,0,5)+math.clamp(speed*.05,0,2)+sprint*5+self.fovKick+(self.keepWiden or 0)
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*(if pursuit or slam or (self.keepWiden or 0)>.5 then 8 else 5)))
	-- Keep the lens out of walls and cover; effects and fighters never block it.
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={character};if bot then table.insert(exclude,bot) end
	local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
	local fx=workspace:FindFirstChild("NinjaDuelFX");if fx then table.insert(exclude,fx) end
	ray.FilterDescendantsInstances=exclude
	-- Fighting-space props (slabs, cover, posts, platforms) never shove the lens
	-- into the player's back: the camera looks through them and they fade.
	-- Only the floor and the bowl's boundary still stop the lens.
	local faded={}
	-- (Studio 03/11, v26: a Naruto clone between the lens and the player hid
	-- him entirely) A body in the way (a clone, a puppet, a summon, the
	-- opponent's double) fades whole, and a body brushing the line counts
	-- too (a sphere, not a thin ray, from the player to the lens).
	local function fadeBody(part)
		local model=part:FindFirstAncestorOfClass("Model")
		if model and model~=workspace and model:FindFirstChildOfClass("Humanoid") then
			for _,d in model:GetDescendants() do if d:IsA("BasePart") then faded[d]=true end end
			table.insert(exclude,model)
			return true
		end
		return false
	end
	local function cast()
		local ok,result=pcall(workspace.Spherecast,workspace,focus,.9,desired-focus,ray)
		local sphere=if ok then result else nil
		if sphere and not solid(sphere.Instance) and sphere.Instance:FindFirstAncestorOfClass("Model") and sphere.Instance:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then return sphere end
		return workspace:Raycast(focus,desired-focus,ray)
	end
	local hit=cast()
	for _=1,6 do
		if not hit or solid(hit.Instance) then break end
		if not fadeBody(hit.Instance) then
			fadeHit(hit.Instance,faded)
			table.insert(exclude,hit.Instance)
		end
		ray.FilterDescendantsInstances=exclude
		hit=cast()
	end
	for part in self.faded or {} do if not faded[part] and part.Parent then part.LocalTransparencyModifier=if self.decorFaded and self.decorFaded[part] then DECOR_FADE else 0 end end
	for part in faded do part.LocalTransparencyModifier=.72 end
	self.faded=faded
	local squeeze=0
	if hit then
		local offset=desired-focus
		local full=offset.Magnitude
		local allowed=math.max(0,hit.Distance-1.2)
		local lost=math.clamp(full-allowed,0,full)
		squeeze=lost/math.max(full,1e-3)
		-- (B1, B0 defect 2: backed into the arena's wall, the lens sat on his
		-- head and looked down at it, the screen full of hair and the hedge,
		-- the opponent out of frame) The wall brings the lens in and only a
		-- little higher; the lens then looks ahead over the shoulder (below)
		-- and the player's own body fades, as Roblox's own close camera does.
		desired=focus+offset.Unit*math.max(allowed,3)+Vector3.new(0,lost*.2,0)
		local check=workspace:Raycast(focus,desired-focus,ray)
		if check then desired=check.Position+check.Normal*1.2 end
	end
	-- (FEEL 05/11, AVANT defect 1) Locked with his back to the wall, the
	-- squeezed lens sat on his head and looked past him: the player was off
	-- screen for 100 % of a wall run (Studio, take 2). The boom swings along
	-- the wall to the nearest clear side, so the body is seen three-quarter
	-- with the opponent; the squeeze above stays the last resort.
	if (follow or (auto and not lost)) and (data.intro or 0)<=0 and not data.ko then
		self:steerAroundWall(focus,self.distance,height,squeeze,ray,dt,clock)
	else
		self.wallYaw=nil;self.wallGoal=nil;self.wallClearSince=nil
	end
	-- (FEEL 05/11, AVANT defect 5) Bushes and tree crowns are decor (no query,
	-- no collision): a body that ran into one was hidden inside it.
	self:fadeDecor(folder,a,target,desired,clock)
	-- In at once (never into the wall), out over a third of a second: the push
	-- of a body against the wall no longer shakes the lens frame to frame.
	self.squeeze=if squeeze>=(self.squeeze or 0) then squeeze else (self.squeeze or 0)+(squeeze-(self.squeeze or 0))*(1-math.exp(-dt*3))
	local aim=focus
	if self.squeeze>.02 then
		local ahead=Vector3.new(focus.X-desired.X,0,focus.Z-desired.Z)
		-- (FEEL 05/11) swung along the wall, the lens sees him from the side:
		-- it looks at the pair again instead of past him.
		local swung=math.clamp(math.abs(self.wallYaw or 0)/.5,0,1)
		if ahead.Magnitude>.05 then aim=focus+ahead.Unit*(16*self.squeeze*(1-swung)) end
	end
	local filming=(data.intro or 0)>0 or data.spectate or (self.cinematic~=nil and os.clock()<self.cinematic.untilT)
	self:fadeSelf(if self.squeeze>.02 and not filming then character else nil,desired,a)
	local cf=CFrame.lookAt(desired,aim)
	-- (FEEL 05/11, AVANT defect 2) Neji's chakra launcher threw the opponent 66
	-- studs up and the lens lost him for 1.8 s. Whenever the pair is framed
	-- (locked, or a pad's free lens that keeps the fight in view), the lens
	-- tilts up to keep the higher body in frame, and widens for what the tilt
	-- cannot take without dropping the player's feet out of the bottom.
	local pairShare=if follow or (auto and not lost) then 1 else 0
	local tilt,widen=0,0
	if pairShare>0 and not filming and not data.ko then
		tilt,widen=Camera.keepInFrame(cf,camera.FieldOfView,target+Vector3.new(0,2.6,0),a-Vector3.new(0,2.8,0))
	end
	local keep=self.keepTilt or 0
	keep+=(tilt*pairShare-keep)*(1-math.exp(-dt*(if tilt*pairShare>keep then 12 else 3)))
	self.keepTilt=keep
	local wide=self.keepWiden or 0
	wide+=(widen*pairShare-wide)*(1-math.exp(-dt*(if widen*pairShare>wide then 10 else 2.5)))
	self.keepWiden=wide
	if keep>1e-3 then cf=cf*CFrame.Angles(keep,0,0) end
	-- Shake is an offset on top of the smoothed rig (applied last, never fed
	-- back into the follow), so it is neither damped away nor left behind.
	-- A continuous, decaying oscillation (~7-10 Hz) rather than a fresh random
	-- offset every frame: random per-frame offsets read as the whole image
	-- jumping (measured natively), an oscillation reads as an impact.
	local shake=CFrame.identity
	local clock=os.clock()
	if clock<self.shakeUntil then
		local amp=self.shakeSize*math.clamp((self.shakeUntil-clock)/.18,0,1)
		shake=CFrame.new(math.sin(clock*47)*amp,math.sin(clock*61+1.3)*amp*.8,0)
	end
	-- Studio capture aid: on high-DPI Windows the Studio window only shows the
	-- top-left two thirds of the play viewport, so tooling can ask for the view
	-- to be re-aimed at that visible region. Never active outside Studio.
	local studio=game:GetService("RunService"):IsStudio()
	-- (Stage 6) the ultimate's own lens: it orbits the two bodies for the
	-- sequence; the rig picks up from where it stops.
	local cine=self.cinematic
	if cine and clock<cine.untilT and data.phase=="Duel" then
		local look=cine.look
		local mid=a:Lerp(target,.5)
		local t=clock-cine.from
		if cine.frame then
			-- The script's shot at t: the bodies where they are drawn.
			local frame=cine.frame
			local casterIsHuman=cine.owner~=nil and cine.owner==data.human.id
			local live={caster=frame.anchor(if casterIsHuman then a else target),victim=frame.anchor(if casterIsHuman then target else a)}
			local eye,at,fov,index=Scripts.shot(cine.kind,t,function(name) return live[name] or live.victim end)
			if eye then
				local weye,wat=frame.world(eye),frame.world(at)
				weye=Vector3.new(weye.X,math.max(weye.Y,frame.origin.Y-2.4),weye.Z)
				if (wat-weye).Magnitude<.2 then wat=weye+frame.f end
				local cf=CFrame.lookAt(weye,wat)*shake
				-- The first shot eases in from the fight's lens; every later
				-- cut is a cut (the script decides).
				local ease=if index==1 then math.clamp(t/.25,0,1) else 1
				camera.CFrame=(self.rigCF or camera.CFrame):Lerp(cf,ease)
				camera.FieldOfView=if index==1 then camera.FieldOfView+(fov-camera.FieldOfView)*math.clamp(dt*10,0,1) else fov
				if ease>=1 then self.rigCF=camera.CFrame end
				return
			end
		end
		local line=Vector3.new(target.X-a.X,0,target.Z-a.Z)
		if line.Magnitude<.1 then line=Vector3.xAxis end
		local base=math.atan2(line.Unit.X,line.Unit.Z)+math.pi/2
		local angle=base+cine.sign*t*look.rate
		-- An aerial sequence (Sasuke, Lee): the lens stays down near the floor
		-- and looks up at the bodies, so the height reads.
		cine.floorY=cine.floorY or math.min(a.Y,target.Y)
		local eye=mid+Vector3.new(math.sin(angle)*look.dist,look.height,math.cos(angle)*look.dist)
		if look.follow then eye=Vector3.new(eye.X,cine.floorY+look.height,eye.Z) end
		local cf=CFrame.lookAt(eye,mid+Vector3.new(0,1,0))*shake
		local ease=math.clamp(t/.3,0,1)
		camera.CFrame=(self.rigCF or camera.CFrame):Lerp(cf,ease)
		camera.FieldOfView=camera.FieldOfView+(look.fov-camera.FieldOfView)*math.clamp(dt*6,0,1)
		if ease>=1 then self.rigCF=camera.CFrame end
		return
	elseif cine then
		self.cinematic=nil;self.rigCF=camera.CFrame
	end
	-- (Tournament, 04/11) A match the player watches: the stands' lens, high
	-- on the side of the pair, drifting slowly along the arena, both bodies in
	-- frame whatever they do.
	if data.spectate then
		local mid=a:Lerp(target,.5)
		local line=Vector3.new(target.X-a.X,0,target.Z-a.Z)
		if line.Magnitude<.1 then line=self.spectateLine or Vector3.xAxis end
		self.spectateLine=line
		local side=line.Unit:Cross(Vector3.yAxis)
		if self.spectateSide and side:Dot(self.spectateSide)<0 then side=-side end
		self.spectateSide=side
		local drift=math.sin(clock*.12)*.35
		local dir=(side*math.cos(drift)+line.Unit*math.sin(drift)).Unit
		local dist=math.max(30,line.Magnitude*.9+22)
		local eye=mid+dir*dist+Vector3.new(0,13+line.Magnitude*.15,0)
		local look=mid+Vector3.new(0,2,0)
		-- (Studio 04/11: one of the arena's trees stood between the stands' lens
		-- and the pair) Props in the way fade, as for the player's own lens; the
		-- floor and the bowl's wall bring the lens in, a little higher.
		local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude
		local exclude={character};if bot then table.insert(exclude,bot) end
		local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
		local fx=workspace:FindFirstChild("NinjaDuelFX");if fx then table.insert(exclude,fx) end
		local faded={}
		local hit
		for _=1,8 do
			ray.FilterDescendantsInstances=exclude
			hit=workspace:Raycast(look,eye-look,ray)
			if not hit or solid(hit.Instance) then break end
			local model=hit.Instance:FindFirstAncestorOfClass("Model")
			if model and model~=workspace and model:FindFirstChildOfClass("Humanoid") then
				for _,d in model:GetDescendants() do if d:IsA("BasePart") then faded[d]=true end end
				table.insert(exclude,model)
			else
				fadeHit(hit.Instance,faded);table.insert(exclude,hit.Instance)
			end
		end
		if hit then eye=hit.Position+hit.Normal*1.2+Vector3.new(0,math.max(0,(eye-look).Magnitude-hit.Distance)*.4,0) end
		for part in self.faded or {} do if not faded[part] and part.Parent then part.LocalTransparencyModifier=if self.decorFaded and self.decorFaded[part] then DECOR_FADE else 0 end end
		for part in faded do part.LocalTransparencyModifier=.72 end
		self.faded=faded
		local cf=CFrame.lookAt(eye,look)*shake
		self.spectateCF=if self.spectateCF then self.spectateCF:Lerp(cf,math.clamp(dt*3,0,1)) else cf
		camera.CFrame=self.spectateCF
		camera.FieldOfView=camera.FieldOfView+(55-camera.FieldOfView)*math.clamp(dt*4,0,1)
		self.rigCF=camera.CFrame
		return
	end
	self.spectateCF=nil;self.spectateSide=nil
	-- Studio film camera (tooling only): a low side view of both fighters, the
	-- way a fighting-game camera shows feet, ground contact and body mechanics.
	local film=studio and workspace:GetAttribute("NinjaDuelFilmCam")
	if film then
		local mid=a:Lerp(target,.5)
		local line=Vector3.new(target.X-a.X,0,target.Z-a.Z)
		if line.Magnitude<.1 then line=Vector3.xAxis end
		local side=line.Unit:Cross(Vector3.yAxis)
		local dist=(if type(film)=="number" then film else 0)+math.max(11,separation*.75+8)
		local look=mid+Vector3.new(0,-.4,0)
		cf=CFrame.lookAt(look+side*dist+Vector3.new(0,1.2,0),look)
		camera.FieldOfView=50
	end
	if studio and workspace:GetAttribute("NinjaDuelCaptureShift") then
		-- Turn about the world vertical, then pitch, and rebuild with a world up
		-- so the horizon never rolls.
		local look=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(-21)):VectorToWorldSpace(cf.LookVector)
		look=(look-Vector3.yAxis*math.tan(math.rad(12))).Unit
		cf=CFrame.lookAt(cf.Position,cf.Position+look)
	end
	if film then camera.CFrame=cf;self.rigCF=nil;return end
	if fresh or not self.rigCF then self.rigCF=cf; self.lastEpoch=data.epoch
	else
		-- Follow tightly enough for teleports, but never jump more than a few
		-- studs in one frame.
		local base=self.rigCF
		local nextCF=base:Lerp(cf,1-math.exp(-dt*(if vertical>8 then 20 elseif aerial or pursuit or slam then 15 else 11)))
		local move=nextCF.Position-base.Position
		local limit=math.max(3.5,520*dt)
		if move.Magnitude>limit then nextCF=CFrame.new(base.Position+move.Unit*limit)*nextCF.Rotation end
		self.rigCF=nextCF
	end
	-- (Continuity blocker) The smoothed lens and its shake are checked last:
	-- the follow lags behind a pushed-in target and the shake adds an offset,
	-- either could carry the lens through the wall. Whatever stops the lens
	-- now holds it on this side, without a lerp back through.
	local final=self.rigCF*shake
	local reach=final.Position-focus
	if reach.Magnitude>.05 then
		local block=workspace:Raycast(focus,reach,ray)
		for _=1,4 do
			if not block or solid(block.Instance) then break end
			table.insert(exclude,block.Instance);ray.FilterDescendantsInstances=exclude
			block=workspace:Raycast(focus,reach,ray)
		end
		if block then
			-- Off the surface along its normal (a ray grazing the wall puts a
			-- point "1.2 back along the ray" still on the wall's face).
			local safe=block.Position+block.Normal*1.2-reach.Unit*.4
			self.rigCF=CFrame.new(safe)*self.rigCF.Rotation
			final=self.rigCF*shake
		end
	end
	-- And never closer than the near plane allows to a solid surface the ray
	-- did not cross (a lens sliding along the wall, just short of it).
	local around=OverlapParams.new();around.FilterType=Enum.RaycastFilterType.Exclude;around.FilterDescendantsInstances=exclude
	for _,part in workspace:GetPartBoundsInRadius(final.Position,1.1,around) do
		if solid(part) then
			local p=part.CFrame:PointToObjectSpace(final.Position)
			local half=part.Size/2
			local closest=part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(p.X,-half.X,half.X),math.clamp(p.Y,-half.Y,half.Y),math.clamp(p.Z,-half.Z,half.Z)))
			local away=final.Position-closest
			local gap=away.Magnitude
			if gap<1.1 then
				local push=(if gap>.01 then away.Unit else (focus-final.Position).Unit)*(1.1-gap)
				self.rigCF=self.rigCF+push;final=final+push
			end
		end
	end
	camera.CFrame=final
end
return Camera
