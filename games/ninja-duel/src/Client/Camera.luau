local Camera={}; Camera.__index=Camera
function Camera.new()
	local self=setmetatable({locked=true,look=Vector2.zero,yaw=0,pitch=.28,lastEpoch=-1,lastHealth=nil,lastEnemyHealth=nil,shakeUntil=0,shakeSize=0,rng=Random.new()},Camera)
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
	if self.lastEpoch~=data.epoch then self.lastHealth=data.human.health; self.lastEnemyHealth=data.bot.health;self.yaw=0;self.pitch=.28 end
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		self.shakeSize=if damage>=12 then 0.37 else 0.18
		self.shakeUntil=os.clock()+0.13
	end
	if self.lastEnemyHealth and data.bot.health<self.lastEnemyHealth then
		local damage=self.lastEnemyHealth-data.bot.health
		self.shakeSize=if damage>=12 then 0.28 else 0.1
		self.shakeUntil=os.clock()+0.1
	end
	self.lastHealth=data.human.health
	self.lastEnemyHealth=data.bot.health
	local targetFov=70+math.clamp((data.human.speed or 0)*0.18,0,8)+(if data.human.wall then 3 else 0)
	camera.FieldOfView+=(targetFov-camera.FieldOfView)*(1-math.exp(-dt*7))
	local a=root.Position
	local folder=root.Parent.Parent
	local bot=folder and folder:FindFirstChild("AIFighter")
	local b=bot and bot:FindFirstChild("HumanoidRootPart")
	local target=if b then b.Position else data.bot.position
	local flat=Vector3.new(target.X-a.X,0,target.Z-a.Z)
	if flat.Magnitude<0.01 then flat=-Vector3.zAxis end
	local distance=(target-a).Magnitude
	local focus=a:Lerp(target,0.5)+Vector3.new(0,1.5,0)
	self.yaw+=(self.look.X or 0)*dt*2.2;self.pitch=math.clamp(self.pitch-(self.look.Y or 0)*dt,0.08,.9)
	local behind=if self.locked then (CFrame.Angles(0,self.yaw,0):VectorToWorldSpace(-flat.Unit)) else Vector3.new(math.sin(self.yaw),0,math.cos(self.yaw))
	if not self.locked then focus=a+Vector3.new(0,1.5,0) end
	local desired=a+behind*math.clamp(17+distance*0.32,18,31)+Vector3.new(0,7+self.pitch*15+math.abs(target.Y-a.Y)*.32,0)
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
	else camera.CFrame=camera.CFrame:Lerp(cf,1-math.exp(-dt*10)) end
end
return Camera
