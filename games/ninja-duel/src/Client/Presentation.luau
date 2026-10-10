-- Velmora's additive combat motion and hit feedback, retaining Ninja Duel's deception visual.
local Motion=require(script.Parent.VelmoraMotionEngine)
local Feedback=require(script.Parent.VelmoraHitFeedback)
local Presentation={};Presentation.__index=Presentation
function Presentation.new() return setmetatable({last={},recoil={}},Presentation) end
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
 local character=game:GetService("Players").LocalPlayer.Character
 self:illusion(data,character)
 local folder=character and character.Parent
 local bot=folder and folder:FindFirstChild("AIFighter")
 local models={human=character,bot=bot}
 local latency=os.clock()-(self.receivedAt or os.clock())
 for key,model in models do
  local actor=data[key];local previous=self.last[key]
  if model and actor then
   if previous and actor.health<previous.health then
    local damage=previous.health-actor.health;local root=model:FindFirstChild("HumanoidRootPart")
    if root then Feedback.burst(root.Position,if actor.cue=="GUARDED" then Color3.fromRGB(255,235,160) else Color3.fromRGB(255,91,74),damage,actor.cue=="GUARDED") end
			self.recoil[key]={at=os.clock(),reaction=actor.reaction,heavy=actor.impactHeavy}
   end
   if actor.events and previous and actor.events.Parry and actor.events.Parry>(previous.parry or 0) then
    local root=model:FindFirstChild("HumanoidRootPart");if root then Feedback.burst(root.Position,Color3.fromRGB(255,245,176),0,true) end
   end
		 local recoil=self.recoil[key]
		 local recoilDuration=recoil and (if recoil.heavy then .3 else .22) or 0
		 if recoil and os.clock()-recoil.at<recoilDuration then Motion.recoil(model,os.clock()-recoil.at,recoil.reaction,recoil.heavy)
   elseif actor.attackName then Motion.pose(model,actor.attackName,math.max(0,actor.attackElapsed+latency))
		 else Motion.locomotion(model,actor.speed or 0,actor.airborne,actor.velocity) end
   self.last[key]={health=actor.health,attackName=actor.attackName,parry=actor.events and actor.events.Parry or 0}
  end
 end
end
return Presentation
