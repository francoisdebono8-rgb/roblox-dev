local Camera={}; Camera.__index=Camera
function Camera.new()
	local self=setmetatable({locked=true,look=Vector2.zero,yaw=0,pitch=.28,lastEpoch=-1,lastHealth=nil,lastEnemyHealth=nil,shakeUntil=0,shakeSize=0,fovKick=0,focus=nil,boom=nil,rng=Random.new()},Camera)
 local UIS=game:GetService("UserInputService")
 UIS.InputChanged:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
   self.yaw+=input.Delta.X*.004;self.pitch=math.clamp(self.pitch-input.Delta.Y*.003,.08,.9)
  end
 end)
 return self
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
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		self.shakeSize=if data.human.impactHeavy or damage>=12 then .34 else .045
		self.fovKick=if data.human.impactHeavy or damage>=12 then 4 else 1
		self.shakeUntil=os.clock()+(if damage>=12 then .13 else .06)
	end
	if self.lastEnemyHealth and data.bot.health<self.lastEnemyHealth then
		local damage=self.lastEnemyHealth-data.bot.health
		self.shakeSize=if data.bot.impactHeavy or damage>=12 then .26 else .035
		self.fovKick=if data.bot.impactHeavy or damage>=12 then 3 else .7
		self.shakeUntil=os.clock()+(if damage>=12 then .11 else .05)
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
	local targetFocus=a:Lerp(target,.5)+Vector3.new(0,if aerial then 1.1 else 1.55,0)
	local focusRate=if aerial or pursuit then 9 else 6
	self.focus=if self.focus then self.focus:Lerp(targetFocus,1-math.exp(-dt*focusRate)) else targetFocus
	local focus=self.focus
	self.yaw+=(self.look.X or 0)*dt*2.2;self.pitch=math.clamp(self.pitch-(self.look.Y or 0)*dt,0.08,.9)
	local behind=if self.locked then (CFrame.Angles(0,self.yaw,0):VectorToWorldSpace(-flat.Unit)) else Vector3.new(math.sin(self.yaw),0,math.cos(self.yaw))
	if not self.locked then focus=a+Vector3.new(0,1.5,0) end
	self.boom=if self.boom and self.boom:Dot(behind)>-.65 then self.boom:Lerp(behind,1-math.exp(-dt*5)) else behind
	if self.boom.Magnitude<.1 then self.boom=behind else self.boom=self.boom.Unit end
	local boomDistance=math.clamp(15+distance*.48+vertical*.22+(if aerial then 2.5 else 0),17,34)
	local height=6+self.pitch*12+vertical*.34+(if aerial then 2 else 0)
	if slam then height+=math.clamp(-(data.human.velocity and data.human.velocity.Y or 0)*.04,0,4) end
	local desired=focus+self.boom*boomDistance+Vector3.new(0,height,0)
	self.fovKick*=math.exp(-dt*10)
	local speed=math.max(data.human.speed or 0,data.bot.speed or 0)
	local targetFov=68+math.clamp(distance*.22,0,7)+math.clamp(speed*.1,0,5)+(if aerial then 3 else 0)+(if pursuit then 4 else 0)+(if data.human.wall or data.bot.wall then 2 else 0)+self.fovKick
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*(if pursuit or slam then 9 else 5)))
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={character};if bot then table.insert(exclude,bot) end
	local effects=folder and folder:FindFirstChild("Effects");if effects then table.insert(exclude,effects) end
	ray.FilterDescendantsInstances=exclude
	local hit=workspace:Raycast(focus,desired-focus,ray)
	if hit then desired=hit.Position+hit.Normal*0.7 end
	local cf=CFrame.lookAt(desired,focus)
	if os.clock()<self.shakeUntil then
		cf*=CFrame.new(self.rng:NextNumber(-1,1)*self.shakeSize,self.rng:NextNumber(-1,1)*self.shakeSize,0)
	end
	if self.lastEpoch~=data.epoch then camera.CFrame=cf; self.lastEpoch=data.epoch
	else camera.CFrame=camera.CFrame:Lerp(cf,1-math.exp(-dt*(if aerial or pursuit or slam then 11 else 7))) end
end
return Camera
