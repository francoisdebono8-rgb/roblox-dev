local Camera={}; Camera.__index=Camera
function Camera.new()
	return setmetatable({locked=true,lastEpoch=-1,lastHealth=nil,shakeUntil=0,shakeSize=0,rng=Random.new()},Camera)
end
function Camera:update(data,dt)
	local camera=workspace.CurrentCamera
	if not data or data.phase=="Selection" then
		self.lastHealth=nil; camera.FieldOfView=70
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(Vector3.new(42,38,45),Vector3.new(0,0,0)); return
	end
	local character=game:GetService("Players").LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not self.locked and data.phase=="Duel" then
		camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=character:FindFirstChildOfClass("Humanoid"); return
	end
	camera.CameraType=Enum.CameraType.Scriptable
	if self.lastEpoch~=data.epoch then self.lastHealth=data.human.health end
	if self.lastHealth and data.human.health<self.lastHealth then
		local damage=self.lastHealth-data.human.health
		self.shakeSize=if damage>=12 then 0.37 else 0.18
		self.shakeUntil=os.clock()+0.13
	end
	self.lastHealth=data.human.health
	local targetFov=70+math.clamp((data.human.speed or 0)*0.18,0,8)
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
	local desired=a-flat.Unit*math.clamp(17+distance*0.32,18,29)+Vector3.new(0,11+distance*0.12,0)
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances={character,bot,folder:FindFirstChild("Effects")}
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
