local Tween=game:GetService('TweenService')
local Shared=game.ReplicatedStorage.WFT
local W=require(Shared.WeaponModel)
local F={Generation=0}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=material or Enum.Material.Metal; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Parent=parent; return p
end
function F.clear()
 F.Generation+=1
 if F.Model then F.Model:Destroy(); F.Model=nil end
end
function F.begin(anvil,duration,hit)
 F.clear(); if not anvil then return end
 local gen=F.Generation
 local model=Instance.new('Model'); model.Name='LocalForging'; model.Parent=workspace; F.Model=model
 local base=anvil.CFrame*CFrame.new(0,.8,0)
 local ingot=part(model,'Heated billet',Vector3.new(2,.3,.6),base,Color3.fromRGB(96,70,54),Enum.Material.Neon)
 Tween:Create(ingot,TweenInfo.new(duration/4),{Color=Color3.fromRGB(255,158,66)}):Play()
 local handle=part(model,'Hammer haft',Vector3.new(.22,2,.22),base*CFrame.new(0,2.5,0),Color3.fromRGB(92,57,34),Enum.Material.Wood)
 local head=part(model,'Hammer face',Vector3.new(1.4,.7,.7),base*CFrame.new(0,1.5,0),Color3.fromRGB(159,165,170))
 task.spawn(function()
  for _=1,3 do
   task.wait(duration/4)
   if gen~=F.Generation then return end
   Tween:Create(head,TweenInfo.new(.12),{CFrame=base*CFrame.new(0,.6,0)}):Play()
   Tween:Create(handle,TweenInfo.new(.12),{CFrame=base*CFrame.new(0,1.6,0)}):Play()
   hit(false)
   task.wait(.12)
   if gen~=F.Generation then return end
   Tween:Create(head,TweenInfo.new(.18),{CFrame=base*CFrame.new(0,1.5,0)}):Play()
   Tween:Create(handle,TweenInfo.new(.18),{CFrame=base*CFrame.new(0,2.5,0)}):Play()
  end
 end)
end
function F.reveal(anvil,w)
 F.clear(); if not anvil then return end
 local model=W.build(w,workspace,anvil.CFrame*CFrame.new(0,3,0),.8); F.Model=model
 local gen=F.Generation
 for _,p in ipairs(model:GetChildren()) do if p:IsA('BasePart') then Tween:Create(p,TweenInfo.new(.4,Enum.EasingStyle.Back),{CFrame=p.CFrame*CFrame.new(0,.7,0)}):Play() end end
 task.delay(4,function() if gen==F.Generation then F.clear() end end)
end
return F
