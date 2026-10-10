-- Original in-project key choreography. No third-party animation IDs/assets.
-- Timeline has anticipation, contact and follow-through; rendered locally at display rate.
local Attacks=require(game:GetService("ReplicatedStorage").NinjaDuel.Attacks)
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Presentation={};Presentation.__index=Presentation
-- Engine-bundled sounds: referenced in place, never copied/uploaded.
local sounds={Hit="action_jump_land.mp3",Heavy="impact_explosion_03.mp3",Guard="action_jump_land.mp3",Dash="action_falling.ogg",Jump="action_jump.mp3",Land="action_jump_land.mp3",Technique="action_swim.mp3"}
local function sound(root,name)
 local s=Instance.new("Sound");s.Name="Combat"..name;s.SoundId="rbxasset://sounds/"..sounds[name]
 s.Volume=if name=="Heavy" then .18 else .27;s.PlaybackSpeed=if name=="Hit" then 1.8 elseif name=="Guard" then 2.4 elseif name=="Dash" then 1.7 else 1.1
 s.RollOffMaxDistance=65;s.Parent=root;s:Play();Debris:AddItem(s,2)
end
local function pose(waist,larm,rarm,lleg,rleg,twist,le,re,lk,rk)
 return {Waist=Vector3.new(waist or 0,twist or 0,0),LeftShoulder=Vector3.new(larm or -.45,0,-.2),RightShoulder=Vector3.new(rarm or -.6,0,.2),
 LeftHip=Vector3.new(lleg or 0,0,-.04),RightHip=Vector3.new(rleg or 0,0,.04),LeftElbow=Vector3.new(le or -.8,0,0),RightElbow=Vector3.new(re or -.8,0,0),LeftKnee=Vector3.new(lk or 0,0,0),RightKnee=Vector3.new(rk or 0,0,0)}
end
-- Distinct jab, cross, turning kick, driving kick and uppercut, not pose cycling.
local keys={
 Light1={pose(-.13,-.8,.6,0,-.2,-.5,-1.1,-1.4),pose(.23,-.5,-1.55,-.2,.3,.48,-1,-.1),pose(.1,-.5,-.8,0,.1,.18)},
 Light2={pose(-.1,.4,-.8,-.2,0,.6,-1.3,-1),pose(.3,-1.7,-.6,.25,-.25,-.65,-.1,-1.2),pose(.1,-.9,-.65,0,0,-.12)},
 Light3={pose(-.2,-.9,-.6,.5,-.6,-.65,-1,-1,.6,.2),pose(-.18,-.4,-1.1,.12,-1.7,.9,-.7,-.8,0,.12),pose(.1,-.6,-.8,0,-.45,.4)},
 Light4={pose(.15,-.8,-.4,-.8,.4,.3,-1,-1,1.2,0),pose(-.22,-1,-.3,-1.85,.3,-.25,-.9,-1,.05,0),pose(.22,-.4,-.8,-.4,.2,-.2)},
 Launcher={pose(.55,-.5,.5,-.65,-.6,-.35,-1.2,-1.5,.75,.5),pose(-.28,.2,-2.65,.4,-.3,.5,-.6,-.18),pose(.1,-.6,-1.3,.1,-.1,.2)},
 Heavy={pose(-.25,.4,.5,.4,-.7,-.75,-1.2,-1.3),pose(.55,-.7,-2.1,-.4,.4,.8,-.8,-.1),pose(.3,-.6,-.9,-.15,.1,.35)},
 DashAttack={pose(.55,.5,-.8,-.5,.7,-.4),pose(.4,-.5,-1.65,.5,-.5,.4,-1,-.1),pose(.15,-.5,-.8,0,0,.2)},
 Air1={pose(-.1,-.5,.6,.4,-.6,-.5),pose(.25,-.4,-1.75,-.6,.5,.65,-.8,-.1),pose(.1,-.7,-.7,.4,-.4,.2)},
 Air2={pose(.1,-.7,-.8,-.4,.6,.6),pose(-.3,-1,-.4,-1.9,.4,-.75,-.5,-.9,.1,.8),pose(.1,-.6,-.8,-.4,.4,-.2)},
 Slam={pose(-.5,-2.7,-2.7,.9,-.9,0,-.4,-.4,.8,.5),pose(.95,-1.35,-1.35,-.9,-.9,0,-.1,-.1,.2,.2),pose(.5,-.7,-.7,-.7,-.7,0,-.8,-.8,.7,.7)},
 Grab={pose(.1,-.7,-.7,-.2,.1),pose(.25,-1.5,-1.5,-.25,.2,0,-.3,-.3),pose(.15,-1.2,-1.2,0,0,0,-1,-1)},
 Throw={pose(.3,-1.2,-1.2,-.3,.3,-.65,-1.3,-1.3),pose(.55,-1.9,-1.9,.4,-.4,.9,-.1,-.1),pose(.2,-.6,-.6,0,0,.4)},
 ThrowUp={pose(.5,-1.4,-1.4,-.5,-.5,0,-1.3,-1.3),pose(-.3,-2.7,-2.7,.2,.2,0,-.1,-.1),pose(.1,-.9,-.9,0,0)},
}
function Presentation.new() return setmetatable({rigs={},impacts={}},Presentation) end
function Presentation:burst(position,color,heavy)
 local folder=workspace:FindFirstChild("LocalCombatFX")
 if not folder then folder=Instance.new("Folder");folder.Name="LocalCombatFX";folder.Parent=workspace end
 for i=1,(if heavy then 10 else 6) do
  local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(.12,.12,if heavy then 1.3 else .65)
  p.CFrame=CFrame.new(position)*CFrame.Angles(i*1.9,i*2.4,i*.7);p.Parent=folder
  local direction=p.CFrame.LookVector
  Tween:Create(p,TweenInfo.new(.17,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=p.CFrame+direction*(if heavy then 3.3 else 1.8),Transparency=1,Size=Vector3.new(.02,.02,.1)}):Play();Debris:AddItem(p,.2)
 end
end
function Presentation:actor(model,data,dt,now)
 if not model or not data then return end
 local root=model:FindFirstChild("HumanoidRootPart");if not root then return end
 local rig=self.rigs[model]
 if not rig then
  rig={joints={},trails={},lastImpact=data.impactSerial,lastAir=false,lastWall=false,events=table.clone(data.events or {})}
  for _,v in model:GetDescendants() do if v:IsA("Motor6D") then rig.joints[v.Name]=v end end
  for _,name in {"LeftHand","RightHand","LeftFoot","RightFoot"} do
   local limb=model:FindFirstChild(name)
   if limb then
    local first=Instance.new("Attachment");first.Position=Vector3.new(-.2,0,0);first.Parent=limb
    local second=Instance.new("Attachment");second.Position=Vector3.new(.2,0,0);second.Parent=limb
    local trail=Instance.new("Trail");trail.Attachment0=first;trail.Attachment1=second;trail.Lifetime=.09;trail.MinLength=.1;trail.FaceCamera=true
    trail.Color=ColorSequence.new(Color3.fromRGB(222,234,222));trail.Transparency=NumberSequence.new(.55,1);trail.Enabled=false;trail.Parent=limb
    rig.trails[name]=trail
   end
  end
  self.rigs[model]=rig
 end
 local authored=model:GetAttribute("AuthoredAnimations")==true
 local phase=now*(if data.speed>30 then 17 else 12);local swing=math.sin(phase)*math.min(data.speed/38,.9)
 local composed=data.fighterId=="Mirage"
 local target=pose(if data.speed>30 then .38 else .08,swing-(if composed then .75 else .3),-swing-(if composed then .8 else .45),-swing,swing,math.sin(phase)*.07,-.9,-.9,math.max(0,swing)*.8,math.max(0,-swing)*.8)
 local spec=Attacks[data.attackName]
 if spec and (data.state=="Startup" or data.state=="Active" or data.state=="Recovery") then
  local timeline=keys[data.attackName];local t=data.attackElapsed+(now-(self.receivedAt or now));local from,to,alpha
  if t<spec.startup then from=pose();to=timeline[1];alpha=math.clamp(t/spec.startup,0,1)
  elseif t<spec.startup+spec.active then from=timeline[1];to=timeline[2];alpha=math.clamp((t-spec.startup)/(.07),0,1)
  else from=timeline[2];to=timeline[3];alpha=math.clamp((t-spec.startup-spec.active)/spec.recovery,0,1) end
  target={};for name,v in from do target[name]=v:Lerp(to[name],alpha) end
 elseif data.reaction=="Knockdown" or data.reaction=="WallSplat" then target=pose(-.1,.6,.6,.25,.25,0,-.3,-.3,.3,.3)
 elseif data.reaction=="Launched" or data.reaction=="Juggled" or data.reaction=="Knockback" then target=pose(-.7,.75,.55,.6,-.5,-.2,-.6,-.7,.7,.3)
 elseif data.reaction=="HitStun" or data.reaction=="GuardStun" or data.state=="Stunned" then target=pose(-.35,.6,.3,-.2,.4,-.35)
 elseif data.reaction=="Grabbed" then target=pose(.55,.3,.3,-.1,-.1,0,-.4,-.4)
 elseif data.reaction=="Wakeup" then target=pose(.65,-1.1,-1.1,-.8,-.8,0,-.7,-.7,1.1,1.1)
 elseif data.state=="Guarding" then target=pose(.1,-1.4,-1.4,-.1,.1,0,-1.4,-1.4)
 elseif data.state=="Dodging" or data.state=="Pursuit" then target=pose(.55,-.8,.6,-.7,.7,-.25,-.8,-1.2,.7,.2)
 elseif data.state=="TechniqueChannel" then target=pose(.15,-1.65,-1.65,-.2,.2,0,-1.3,-1.3)
 elseif data.state=="TechniqueActive" then target=pose(.4,-1.2,-1.9,.3,-.3,.35,-.4,-.15)
 elseif data.wall then target=pose(.45,-1.3,-.9,-swing*1.2,swing*1.2,.2,-.8,-.8,math.max(swing,0),math.max(-swing,0))
 elseif data.airborne then target=pose(.12,-.8,-.6,.7,-.5,0,-.8,-.8,.9,.3)
 elseif data.state=="Defeated" then target=pose(.08,.5,.5,.2,.2,0,-.2,-.2,.2,.2) end
 if data.wall then target.Root=Vector3.new(-.7,0,0) end
 local rootOffset=Vector3.zero
 if data.reaction=="Knockdown" or data.state=="Defeated" then target.Root=Vector3.new(-1.48,0,.1);rootOffset=Vector3.new(0,-1.6,0)
 elseif data.reaction=="Wakeup" then target.Root=Vector3.new(-.65,0,0);rootOffset=Vector3.new(0,-.8,0)
 elseif data.reaction=="Launched" or data.reaction=="Juggled" then target.Root=Vector3.new(-.45,0,.18) end
 for name,trail in rig.trails do
  local kick=data.attackName=="Light3" or data.attackName=="Light4" or data.attackName=="Air2"
  trail.Enabled=data.state=="Active" and ((kick and name:match("Foot")~=nil) or (not kick and name:match("Hand")~=nil))
 end
 local alpha=1-math.exp(-dt*28)
 for name,joint in (if authored then {} else rig.joints) do
  local angles=target[name] or Vector3.zero
  joint.Transform=joint.Transform:Lerp(CFrame.new(if name=="Root" then rootOffset else Vector3.zero)*CFrame.Angles(angles.X,angles.Y,angles.Z),alpha)
 end
 if rig.lastImpact~=data.impactSerial then
  rig.lastImpact=data.impactSerial;sound(root,if data.impactHeavy then "Heavy" else "Hit");self:burst(root.Position,if composed then Color3.fromRGB(241,158,130) else Color3.fromRGB(130,208,241),data.impactHeavy)
 end
 for event,number in data.events or {} do
  if number>(rig.events[event] or 0) then
   if event=="Dodge" or event=="Chase" or event=="Substitute" then sound(root,"Dash")
   elseif event=="GuardHit" then sound(root,"Guard")
   elseif event=="Technique" then sound(root,"Technique") end
  end
 end
 rig.events=table.clone(data.events or {})
 if not rig.lastAir and data.airborne then sound(root,"Jump") end
 if rig.lastAir and not data.airborne then sound(root,"Land");self:burst(root.Position-Vector3.new(0,2.6,0),Color3.fromRGB(199,186,157),false) end
 rig.lastAir=data.airborne
end
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
function Presentation:update(data,dt)
 if not data.human then
  if self.echo then self.echo:Destroy();self.echo=nil end
  return
 end
 local player=game:GetService("Players").LocalPlayer;local model=player.Character
 self:illusion(data,model)
 self:actor(model,data.human,dt,os.clock())
 self:actor(model and model.Parent and model.Parent:FindFirstChild("AIFighter"),data.bot,dt,os.clock())
 for m in self.rigs do if not m.Parent then self.rigs[m]=nil end end
end
return Presentation
