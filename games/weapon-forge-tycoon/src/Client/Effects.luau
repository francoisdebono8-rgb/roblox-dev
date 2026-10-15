local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Effects={Settings={}}
function Effects.sound(key)
 if Effects.Settings.SFX==false or not C.Sounds[key] then return end
 local s=Instance.new('Sound'); s.SoundId='rbxassetid://'..C.Sounds[key]; s.Volume=.35; s.Parent=game:GetService('SoundService'); s:Play(); Debris:AddItem(s,8)
end
function Effects.impact(position,color,big)
 Effects.sound(big and 'merge' or 'hammer_hit')
 if not Effects.Settings.LowVFX then
  local wave=Instance.new('Part'); wave.Name='Forge shockwave'; wave.Shape=Enum.PartType.Cylinder; wave.Size=Vector3.new(.05,.5,.5); wave.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2); wave.Material=Enum.Material.Neon; wave.Color=color; wave.Transparency=.45; wave.Anchored=true; wave.CanCollide=false; wave.CanTouch=false; wave.CanQuery=false; wave.Parent=workspace
  Tween:Create(wave,TweenInfo.new(.25),{Size=Vector3.new(.03,big and 7 or 3,big and 7 or 3),Transparency=1}):Play(); Debris:AddItem(wave,.3)
  for i=1,(big and 12 or 6) do
   local p=Instance.new('Part'); p.Size=Vector3.new(.12,.12,.4); p.Material=Enum.Material.Neon; p.Color=color; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CFrame=CFrame.new(position); p.Parent=workspace
   local delta=Vector3.new(math.random(-20,20)/10,math.random(5,25)/10,math.random(-20,20)/10)
   Tween:Create(p,TweenInfo.new(.35),{Position=position+delta,Transparency=1,Size=Vector3.new(.02,.02,.02)}):Play(); Debris:AddItem(p,.4)
  end
 end
 if Effects.Settings.CameraShake~=false then
  local camera=workspace.CurrentCamera
  local original=camera.CFrame
  camera.CFrame=original*CFrame.Angles(math.rad(.28),0,0)
 end
end
return Effects
