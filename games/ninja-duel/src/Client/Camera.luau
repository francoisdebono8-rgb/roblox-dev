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
 Ground={distance=15,height=5.2,fov=68,lift=1.6,side=.32},
 Launcher={distance=18,height=4,fov=72,lift=4.5,side=.36},
 Pursuit={distance=21,height=6,fov=78,lift=3,side=.4},
 AirCombo={distance=19,height=3.5,fov=74,lift=2.5,side=.4},
 Slam={distance=19,height=10,fov=76,lift=-1.5,side=.34},
 Wall={distance=22,height=8,fov=75,lift=3,side=.5},
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
function Camera.new()
	local self=setmetatable({locked=true,look=Vector2.zero,yaw=0,pitch=.22,lastEpoch=-1,lastHealth=nil,lastEnemyHealth=nil,
		shakeUntil=0,shakeSize=0,fovKick=0,focus=nil,boomAngle=nil,distance=nil,rng=Random.new(),zoom=0,mode=nil},Camera)
 local UIS=game:GetService("UserInputService")
 -- Right mouse owns the heavy attack, so orbit and zoom are always live
 -- instead of needing a held modifier. Free-look only applies unlocked.
 UIS.InputChanged:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseMovement and not self.locked then
   self.yaw+=input.Delta.X*.004;self.pitch=math.clamp(self.pitch-input.Delta.Y*.003,.04,.9)
  elseif input.UserInputType==Enum.UserInputType.MouseWheel then
   self.zoom=math.clamp(self.zoom-input.Position.Z*1.4,-6,12)
  end
 end)
 return self
end
-- Impact-driven impulse. Small events must not make the camera twitch: only a
-- finisher, launcher, parry, slam, teleport or big jutsu earns a reaction.
local IMPULSE={
 whiff={0,0},kunai={0,0},shuriken={0,0},stick={0,0},fade={0,0},cast={0,0},chase={.02,1.2},dodge={.01,.25},substitute={.02,.4},
 light={.02,.3},air={.025,.45},landing={.04,.6},block={.04,.6},quickstep={.015,.8},teleport={.03,2.2},mirage={0,0},burst={.02,1},
 launcher={.1,1.3},finisher={.13,1.6},parry={.14,1.7},jutsu={.15,1.8},fire={.32,3.2},
 slam={.26,2.6},wall={.14,1.1},wallbounce={.2,2.0},clash={.12,1.6},walltech={.02,.4},pin={.02,.25},ember={.02,.35},palm={.015,.2},palmburst={.06,.9},flow={.03,.6},awaken={.12,2.4},groundbounce={.18,1.8},chidori={.1,2.2},afterimage={0,0},deflect={.01,.2},repel={.1,1.3},rotation={.04,.9},trigram={0,0},
}
function Camera:impulse(style,role)
	local spec=IMPULSE[style] or IMPULSE.light
	if not spec or (spec[1]<=0 and spec[2]<=0) then return end
	local weight=if role=="victim" then 1.25 elseif role=="neutral" then .6 else .85
	local now=os.clock()
	self.shakeSize=math.max(self.shakeSize or 0,spec[1]*weight)
	self.fovKick=math.max(self.fovKick or 0,spec[2]*weight)
	self.shakeUntil=math.max(self.shakeUntil or 0,now+(if style=="slam" or style=="fire" then .18 else .07))
	-- A decisive blow gets a beat of space: the lens eases back, then settles.
	local SETTLE={finisher=1.6,launcher=1.2,slam=2.4,wallbounce=2.4,wall=1.4,clash=1.4,repel=1.8,parry=1.4,fire=2}
	if SETTLE[style] then self.settleSize=math.max(if now<(self.settleUntil or 0) then self.settleSize or 0 else 0,SETTLE[style]);self.settleUntil=now+.75 end
end
function Camera:update(data,dt)
	local camera=workspace.CurrentCamera
	if not data or data.phase=="Selection" then
		self.lastHealth=nil; self.lastEnemyHealth=nil; camera.FieldOfView=70
		camera.CameraType=Enum.CameraType.Scriptable
		-- Slow establishing orbit over the training ground behind the menu.
		local t=os.clock()*.06
		camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(t)*88,38,math.cos(t)*88),Vector3.new(0,8,0)); return
	end
	local character=game:GetService("Players").LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	camera.CameraType=Enum.CameraType.Scriptable
	local fresh=self.lastEpoch~=data.epoch
	if fresh then self.lastHealth=data.human.health; self.lastEnemyHealth=data.bot.health;self.yaw=0;self.pitch=.22;self.focus=nil;self.boomAngle=nil;self.distance=nil;self.sprint=0;self.wasSprinting=false end
	-- Fallback only: the impact-style impulse above owns normal reactions.
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		if data.human.impactHeavy or damage>=12 then
			self.shakeSize=math.max(self.shakeSize or 0,.2);self.fovKick=math.max(self.fovKick or 0,2);self.shakeUntil=os.clock()+.12
		end
	end
	self.lastHealth=data.human.health
	self.lastEnemyHealth=data.bot.health
	-- Frame the bodies where they are drawn (smoothed), not the stepping roots.
	local presentation=self.presentation
	local a=(presentation and presentation:visualRoot("human")) or root.Position
	local folder=root.Parent and root.Parent.Parent
	local bot=folder and folder:FindFirstChild("AIFighter")
	local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local target=(presentation and presentation:visualRoot("bot")) or (if b then b.Position else data.bot.position)
	local flat=Vector3.new(target.X-a.X,0,target.Z-a.Z)
	if flat.Magnitude<.01 then flat=-Vector3.zAxis end
	local separation=flat.Magnitude
	local vertical=math.abs(target.Y-a.Y)
	local aerial=data.human.airborne or data.bot.airborne or vertical>5
	local pursuit=data.human.state=="Pursuit" or data.bot.state=="Pursuit"
	local slam=data.human.attackName=="Slam" or data.bot.attackName=="Slam"
	local selected=mode(data.human,data.bot)
	self.mode=selected
	local frame=framing[selected]
	-- Look-stick / unlocked mouse orbit.
	self.yaw+=(self.look.X or 0)*dt*2.4;self.pitch=math.clamp(self.pitch-(self.look.Y or 0)*dt,.04,.9)
	-- Boom heading: behind the player on the player->opponent line, offset over
	-- the shoulder. When the fighters swap sides the heading orbits around at a
	-- bounded angular speed rather than staying on the old side.
	local behind=-flat.Unit
	local desiredAngle
	if self.locked then
		desiredAngle=math.atan2(behind.X,behind.Z)+self.yaw+frame.side
	else
		desiredAngle=self.yaw
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
	local bias=if separation<=26 then .42 else math.max(.3,.42-(separation-26)*.004)
	local targetFocus=a:Lerp(target,bias)+Vector3.new(0,frame.lift,0)
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
		local leadCap=2.6+sprint*2.4
		if lead.Magnitude>leadCap then lead=lead.Unit*leadCap end
		self.lead=(self.lead or Vector3.zero):Lerp(lead,1-math.exp(-dt*4))
		targetFocus+=self.lead
	end
	if not self.locked then targetFocus=a+Vector3.new(0,1.6,0) end
	local focusRate=if aerial or pursuit then 13 else 9
	self.focus=if self.focus then self.focus:Lerp(targetFocus,1-math.exp(-dt*focusRate)) else targetFocus
	local focus=self.focus
	local settle=math.max(0,(self.settleUntil or 0)-os.clock())/.75
	-- K.O.: a slow drift around the finish while the lens eases out.
	if data.ko then self.yaw+=dt*.3 end
	local spread=math.min(math.max(0,separation-7),19)*.68+math.max(0,separation-26)*.32
	local wantDistance=math.clamp(frame.distance-sprint*1.5+spread+vertical*.3+self.zoom+(self.settleSize or 0)*math.sin(settle*math.pi*.5)+(if data.ko then 6 else 0),12,48)
	self.distance=if self.distance then self.distance+(wantDistance-self.distance)*(1-math.exp(-dt*4)) else wantDistance
	local height=frame.height-sprint*.6+self.pitch*9+vertical*.28+math.min(math.max(0,separation-10)*.1,4)
	if slam then height+=math.clamp(-(data.human.velocity and data.human.velocity.Y or 0)*.04,0,4) end
	local desired=focus+boom*self.distance+Vector3.new(0,height,0)
	-- Match intro: a slow orbit that presents both fighters, then the normal
	-- rig takes over from wherever the orbit ended.
	if (data.intro or 0)>0 then
		local mid=a:Lerp(target,.5)
		local turn=self.boomAngle+math.rad(70)-(data.intro/2.6)*math.rad(110)
		focus=mid+Vector3.new(0,2.6,0)
		desired=focus+Vector3.new(math.sin(turn),0,math.cos(turn))*(separation*.5+13)+Vector3.new(0,3.2,0)
		self.focus=focus
	end
	self.fovKick*=math.exp(-dt*9)
	local speed=data.human.speed or 0
	local targetFov=frame.fov+math.clamp(separation*.08,0,5)+math.clamp(speed*.05,0,2)+sprint*5+self.fovKick
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*(if pursuit or slam then 8 else 5)))
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
	local hit=workspace:Raycast(focus,desired-focus,ray)
	for _=1,4 do
		if not hit or hit.Instance.Name=="Training floor" or hit.Instance.Name=="Boundary" then break end
		faded[hit.Instance]=true
		table.insert(exclude,hit.Instance)
		ray.FilterDescendantsInstances=exclude
		hit=workspace:Raycast(focus,desired-focus,ray)
	end
	for part in self.faded or {} do if not faded[part] and part.Parent then part.LocalTransparencyModifier=0 end end
	for part in faded do part.LocalTransparencyModifier=.72 end
	self.faded=faded
	if hit then
		local offset=desired-focus
		local full=offset.Magnitude
		local allowed=math.max(0,hit.Distance-1.2)
		local lost=math.clamp(full-allowed,0,full)
		-- The closer the wall pushes the lens, the higher it rises over the fight:
		-- continuous in the push, so a fight along the wall never snaps the view.
		desired=focus+offset.Unit*math.max(allowed,4.5)+Vector3.new(0,lost*.6,0)
		local check=workspace:Raycast(focus,desired-focus,ray)
		if check then desired=check.Position+check.Normal*1.2 end
	end
	local cf=CFrame.lookAt(desired,focus)
	if os.clock()<self.shakeUntil then
		cf*=CFrame.new(self.rng:NextNumber(-1,1)*self.shakeSize,self.rng:NextNumber(-1,1)*self.shakeSize,0)
	end
	-- Studio capture aid: on high-DPI Windows the Studio window only shows the
	-- top-left two thirds of the play viewport, so tooling can ask for the view
	-- to be re-aimed at that visible region. Never active outside Studio.
	local studio=game:GetService("RunService"):IsStudio()
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
	if film then camera.CFrame=cf;return end
	if fresh then camera.CFrame=cf; self.lastEpoch=data.epoch
	else
		-- Follow tightly enough for teleports, but never jump more than a few
		-- studs in one frame.
		local nextCF=camera.CFrame:Lerp(cf,1-math.exp(-dt*(if aerial or pursuit or slam then 15 else 11)))
		local move=nextCF.Position-camera.CFrame.Position
		local limit=math.max(3.5,520*dt)
		if move.Magnitude>limit then nextCF=CFrame.new(camera.CFrame.Position+move.Unit*limit)*nextCF.Rotation end
		camera.CFrame=nextCF
	end
end
return Camera
