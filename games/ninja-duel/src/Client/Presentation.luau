-- Combat animation/feedback comes from the imported Bangla server components.
-- This client module retains only Ninja Duel's Itachi deception visual.
local Presentation={};Presentation.__index=Presentation
function Presentation.new() return setmetatable({ghosts={}},Presentation) end
function Presentation:illusion(data,model)
 local active=data.phase=="Duel" and data.human.illusion>0 and data.human.decoy
 local opponent=model and model.Parent and model.Parent:FindFirstChild("AIFighter")
 active=active and opponent~=nil
 if active and opponent and not self.echo then
  local ghost=opponent:Clone();ghost.Name="LocalAfterimage"
  for _,v in ghost:GetDescendants() do
   if v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanQuery=false;v.Transparency=math.max(v.Transparency,.72)
   elseif v:IsA("Humanoid") or v:IsA("Sound") or v:IsA("Trail") then v:Destroy() end
  end
  ghost.Parent=workspace;self.echo=ghost;self.echoEpoch=data.epoch
 end
 if self.echo then
  if not active or self.echoEpoch~=data.epoch then self.echo:Destroy();self.echo=nil
  else self.echo:PivotTo(CFrame.new(data.human.decoy)*opponent:GetPivot().Rotation) end
 end
end
function Presentation:update(data,_dt)
 if not data.human then
  if self.echo then self.echo:Destroy();self.echo=nil end
  return
 end
 self:illusion(data,game:GetService("Players").LocalPlayer.Character)
end
return Presentation
