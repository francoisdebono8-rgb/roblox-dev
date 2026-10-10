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
 if h.airborne or b.airborne then return "AirCombo" end
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
 slam={.26,2.6},wall={.08,.8},
}
function Camera:impulse(style,role)
	local spec=IMPULSE[style] or IMPULSE.light
	if not spec or (spec[1]<=0 and spec[2]<=0) then return end
	local weight=if role=="victim" then 1.25 elseif role=="neutral" then .6 else .85
	local now=os.clock()
	self.shakeSize=math.max(self.shakeSize or 0,spec[1]*weight)
	self.fovKick=math.max(self.fovKick or 0,spec[2]*weight)
	self.shakeUntil=math.max(self.shakeUntil or 0,now+(if style=="slam" or style=="fire" then .18 else .07))
end
function Camera:update(data,dt)
	local camera=workspace.CurrentCamera
	if not data or data.phase=="Selection" then
		self.lastHealth=nil; self.lastEnemyHealth=nil; camera.FieldOfView=70
		camera.CameraType=Enum.CameraType.Scriptable
		-- Slow establishing orbit over the training ground behind the menu.
		local t=os.clock()*.06
		camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(t)*58,26,math.cos(t)*58),Vector3.new(0,6,0)); return
	end
	local character=game:GetService("Players").LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	camera.CameraType=Enum.CameraType.Scriptable
	local fresh=self.lastEpoch~=data.epoch
	if fresh then self.lastHealth=data.human.health; self.lastEnemyHealth=data.bot.health;self.yaw=0;self.pitch=.22;self.focus=nil;self.boomAngle=nil;self.distance=nil end
	-- Fallback only: the impact-style impulse above owns normal reactions.
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		if data.human.impactHeavy or damage>=12 then
			self.shakeSize=math.max(self.shakeSize or 0,.2);self.fovKick=math.max(self.fovKick or 0,2);self.shakeUntil=os.clock()+.12
		end
	end
	self.lastHealth=data.human.health
	self.lastEnemyHealth=data.bot.health
	local a=root.Position
	local folder=root.Parent and root.Parent.Parent
	local bot=folder and folder:FindFirstChild("AIFighter")
	local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local target=if b then b.Position else data.bot.position
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
	local targetFocus=a:Lerp(target,if separation>26 then .5 else .42)+Vector3.new(0,frame.lift,0)
	if not self.locked then targetFocus=a+Vector3.new(0,1.6,0) end
	local focusRate=if aerial or pursuit then 10 else 7
	self.focus=if self.focus then self.focus:Lerp(targetFocus,1-math.exp(-dt*focusRate)) else targetFocus
	local focus=self.focus
	local wantDistance=math.clamp(frame.distance+math.max(0,separation-7)*.55+vertical*.3+self.zoom,12,48)
	self.distance=if self.distance then self.distance+(wantDistance-self.distance)*(1-math.exp(-dt*4)) else wantDistance
	local height=frame.height+self.pitch*9+vertical*.28
	if slam then height+=math.clamp(-(data.human.velocity and data.human.velocity.Y or 0)*.04,0,4) end
	local desired=focus+boom*self.distance+Vector3.new(0,height,0)
	self.fovKick*=math.exp(-dt*9)
	local speed=math.max(data.human.speed or 0,data.bot.speed or 0)
	local targetFov=frame.fov+math.clamp(separation*.08,0,5)+math.clamp(speed*.05,0,3)+self.fovKick
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*(if pursuit or slam then 8 else 5)))
	-- Keep the lens out of walls and cover; effects and fighters never block it.
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={character};if bot then table.insert(exclude,bot) end
	local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
	local fx=workspace:FindFirstChild("NinjaDuelFX");if fx then table.insert(exclude,fx) end
	ray.FilterDescendantsInstances=exclude
	local hit=workspace:Raycast(focus,desired-focus,ray)
	if hit then
		desired=hit.Position+hit.Normal*1.2
		if (desired-focus).Magnitude<7 then
			local raised=focus+Vector3.new(0,12,0)+boom*5
			local overhead=workspace:Raycast(focus,raised-focus,ray)
			desired=if overhead then overhead.Position+overhead.Normal else raised
		end
	end
	local cf=CFrame.lookAt(desired,focus)
	if os.clock()<self.shakeUntil then
		cf*=CFrame.new(self.rng:NextNumber(-1,1)*self.shakeSize,self.rng:NextNumber(-1,1)*self.shakeSize,0)
	end
	-- Studio capture aid: on high-DPI Windows the Studio window only shows the
	-- top-left two thirds of the play viewport, so tooling can ask for the view
	-- to be re-aimed at that visible region. Never active outside Studio.
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("NinjaDuelCaptureShift") then
		cf*=CFrame.Angles(math.rad(-12),math.rad(-21),0)
	end
	if fresh then camera.CFrame=cf; self.lastEpoch=data.epoch
	else
		-- Follow tightly enough for teleports, but never jump more than a few
		-- studs in one frame.
		local nextCF=camera.CFrame:Lerp(cf,1-math.exp(-dt*(if aerial or pursuit or slam then 12 else 9)))
		local move=nextCF.Position-camera.CFrame.Position
		local limit=math.max(3.5,90*dt)
		if move.Magnitude>limit then nextCF=CFrame.new(camera.CFrame.Position+move.Unit*limit)*nextCF.Rotation end
		camera.CFrame=nextCF
	end
end
return Camera
