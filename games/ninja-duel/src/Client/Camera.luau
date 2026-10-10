local Camera={}; Camera.__index=Camera
-- Persistent framing modes blend over several frames; controls remain live.
local framing={
 Ground={distance=18,height=7,fov=69,lift=1.4,side=.24},
 Launcher={distance=20,height=5,fov=74,lift=4.5,side=.32},
 Pursuit={distance=27,height=8,fov=82,lift=2.5,side=.48},
 AirCombo={distance=23,height=4,fov=76,lift=1.8,side=.45},
 Slam={distance=21,height=12,fov=79,lift=-2.2,side=.35},
 Wall={distance=24,height=10,fov=77,lift=2.5,side=.6},
}
local function mode(h,b)
 if h.attackName=="Slam" or b.attackName=="Slam" then return "Slam" end
 if h.state=="Pursuit" or b.state=="Pursuit" then return "Pursuit" end
 if h.wall or b.wall or h.reaction=="WallSplat" or b.reaction=="WallSplat" then return "Wall" end
 if h.reaction=="Launched" or b.reaction=="Launched" then return "Launcher" end
 if h.airborne or b.airborne then return "AirCombo" end
 return "Ground"
end
function Camera.new()
	local self=setmetatable({locked=true,look=Vector2.zero,yaw=0,pitch=.28,lastEpoch=-1,lastHealth=nil,lastEnemyHealth=nil,shakeUntil=0,shakeSize=0,fovKick=0,focus=nil,boom=nil,rng=Random.new(),zoom=0},Camera)
 local UIS=game:GetService("UserInputService")
 -- Right mouse now owns the heavy attack, so orbit and zoom are always live
 -- instead of needing a held modifier. Free-look only applies unlocked.
 UIS.InputChanged:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseMovement and not self.locked then
   self.yaw+=input.Delta.X*.004;self.pitch=math.clamp(self.pitch-input.Delta.Y*.003,.08,.9)
  elseif input.UserInputType==Enum.UserInputType.MouseWheel then
   self.zoom=math.clamp(self.zoom-input.Position.Z*1.4,-7,11)
  end
 end)
 return self
end
-- Impact-driven impulse. Small events must not make the camera twitch: only a
-- finisher, launcher, parry, slam or big jutsu earns a noticeable reaction.
local IMPULSE={
 whiff={0,0},kunai={0,0},shuriken={0,0},dodge={.012,.25},substitute={.02,.4},
 light={.02,.35},air={.028,.5},landing={.05,.8},block={.045,.7},
 launcher={.1,1.3},finisher={.14,1.7},parry={.15,1.8},jutsu={.17,2},
 slam={.26,3},
}
function Camera:impulse(style,role)
	local spec=IMPULSE[style] or IMPULSE.light
	if not spec or spec[1]<=0 then return end
	local weight=if role=="victim" then 1.35 elseif role=="neutral" then .5 else .85
	local now=os.clock()
	self.shakeSize=math.max(self.shakeSize or 0,spec[1]*weight)
	self.fovKick=math.max(self.fovKick or 0,spec[2]*weight)
	self.shakeUntil=math.max(self.shakeUntil or 0,now+(if style=="slam" then .16 else .07))
end
function Camera:update(data,dt)
	local camera=workspace.CurrentCamera
	if not data or data.phase=="Selection" then
		self.lastHealth=nil; self.lastEnemyHealth=nil; camera.FieldOfView=70
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(Vector3.new(42,38,45),Vector3.new(0,0,0)); return
	end
	local character=game:GetService("Players").LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	camera.CameraType=Enum.CameraType.Scriptable
	if self.lastEpoch~=data.epoch then self.lastHealth=data.human.health; self.lastEnemyHealth=data.bot.health;self.yaw=0;self.pitch=.28;self.focus=nil;self.boom=nil end
	-- Fallback only: the impact-style impulse above owns normal reactions. A big
	-- scratch should still register if the style never arrived.
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		if data.human.impactHeavy or damage>=12 then
			self.shakeSize=math.max(self.shakeSize or 0,.22)
			self.fovKick=math.max(self.fovKick or 0,2.4)
			self.shakeUntil=os.clock()+.12
		end
	end
	if self.lastEnemyHealth and data.bot.health<self.lastEnemyHealth then
		local damage=self.lastEnemyHealth-data.bot.health
		if data.bot.impactHeavy or damage>=12 then
			self.shakeSize=math.max(self.shakeSize or 0,.16)
			self.fovKick=math.max(self.fovKick or 0,1.8)
			self.shakeUntil=os.clock()+.1
		end
	end
	self.lastHealth=data.human.health
	self.lastEnemyHealth=data.bot.health
	local a=root.Position
	local folder=root.Parent.Parent
	local bot=folder and folder:FindFirstChild("AIFighter")
	local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local target=if b then b.Position else data.bot.position
	local flat=Vector3.new(target.X-a.X,0,target.Z-a.Z)
	if flat.Magnitude<0.01 then flat=-Vector3.zAxis end
	local distance=(target-a).Magnitude
	local vertical=math.abs(target.Y-a.Y);local aerial=data.human.airborne or data.bot.airborne or vertical>5
	local pursuit=data.human.state=="Pursuit" or data.bot.state=="Pursuit"
	local slam=data.human.attackName=="Slam" or data.bot.attackName=="Slam"
	local selected=mode(data.human,data.bot)
 self.mode=selected
 local frame=framing[selected]
 local targetFocus=a:Lerp(target,.5)+Vector3.new(0,frame.lift,0)
	local focusRate=if aerial or pursuit then 9 else 6
	self.focus=if self.focus then self.focus:Lerp(targetFocus,1-math.exp(-dt*focusRate)) else targetFocus
	local focus=self.focus
	self.yaw+=(self.look.X or 0)*dt*2.2;self.pitch=math.clamp(self.pitch-(self.look.Y or 0)*dt,0.08,.9)
	local behind=if self.locked then (CFrame.Angles(0,self.yaw,0):VectorToWorldSpace(-flat.Unit)) else Vector3.new(math.sin(self.yaw),0,math.cos(self.yaw))
	if not self.locked then focus=a+Vector3.new(0,1.5,0) end
	-- Preserve the viewing hemisphere when fighters cross instead of flipping 180°.
 if self.locked and self.boom and self.boom:Dot(behind)<0 then behind=-behind end
 behind=(behind+Vector3.new(-behind.Z,0,behind.X)*frame.side).Unit
 self.boom=if self.boom then self.boom:Lerp(behind,1-math.exp(-dt*4)) else behind
	if self.boom.Magnitude<.1 then self.boom=behind else self.boom=self.boom.Unit end
	local boomDistance=math.clamp(frame.distance+math.max(0,distance-8)*.48+vertical*.22+self.zoom,15,42)
	local height=frame.height+self.pitch*8+vertical*.24
	if slam then height+=math.clamp(-(data.human.velocity and data.human.velocity.Y or 0)*.04,0,4) end
	local desired=focus+self.boom*boomDistance+Vector3.new(0,height,0)
	self.fovKick*=math.exp(-dt*10)
	local speed=math.max(data.human.speed or 0,data.bot.speed or 0)
	local targetFov=frame.fov+math.clamp(distance*.12,0,5)+math.clamp(speed*.06,0,3)+self.fovKick
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*(if pursuit or slam then 9 else 5)))
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={character};if bot then table.insert(exclude,bot) end
	local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
	ray.FilterDescendantsInstances=exclude
	local hit=workspace:Raycast(focus,desired-focus,ray)
	if hit then
  desired=hit.Position+hit.Normal*1.2
  if (desired-focus).Magnitude<8 then
   local raised=focus+Vector3.new(0,13,0)+self.boom*5
   local overhead=workspace:Raycast(focus,raised-focus,ray)
   desired=if overhead then overhead.Position+overhead.Normal else raised
  end
 end
	local cf=CFrame.lookAt(desired,focus)
	if os.clock()<self.shakeUntil then
		cf*=CFrame.new(self.rng:NextNumber(-1,1)*self.shakeSize,self.rng:NextNumber(-1,1)*self.shakeSize,0)
	end
	if self.lastEpoch~=data.epoch then camera.CFrame=cf; self.lastEpoch=data.epoch
	else camera.CFrame=camera.CFrame:Lerp(cf,1-math.exp(-dt*(if aerial or pursuit or slam then 11 else 7))) end
end
return Camera
