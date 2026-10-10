-- R6 -> R15 compatibility only; transforms/times remain the donor choreography.
local Donor={}
local basis={
 Torso=CFrame.Angles(-math.pi/2,0,math.pi),Head=CFrame.Angles(-math.pi/2,0,math.pi),
 ['Right Arm']=CFrame.Angles(0,math.pi/2,0),['Left Arm']=CFrame.Angles(0,-math.pi/2,0),
 ['Right Leg']=CFrame.Angles(0,math.pi/2,0),['Left Leg']=CFrame.Angles(0,-math.pi/2,0),
}
local mapped={Head='Head',['Right Arm']='RightUpperArm',['Left Arm']='LeftUpperArm',
 ['Right Leg']='RightUpperLeg',['Left Leg']='LeftUpperLeg'}
local function pose(parent,name,cf,weight)
 local p=Instance.new('Pose');p.Name=name;p.CFrame=cf;p.Weight=weight or 1;p.Parent=parent;return p
end
function Donor.retarget(sequence)
 local result=Instance.new('KeyframeSequence');result.Name=sequence.Name..'_R15';result.Loop=sequence.Loop;result.Priority=sequence.Priority
 for _,frame in sequence:GetKeyframes() do
  local key=Instance.new('Keyframe');key.Name=frame.Name;key.Time=frame.Time;key.Parent=result
  local byName={};for _,p in frame:GetDescendants() do if p:IsA('Pose') then byName[p.Name]=p end end
  local source=byName.Torso
  local root=pose(key,'HumanoidRootPart',CFrame.identity,0)
  local torsoCF=if source then basis.Torso*source.CFrame*basis.Torso:Inverse() else CFrame.identity
  local lower=pose(root,'LowerTorso',torsoCF)
  local upper=pose(lower,'UpperTorso',CFrame.identity)
  for old,name in mapped do
   local src=byName[old]
   if src then
    local b=basis[old]
    local cf=b*src.CFrame*b:Inverse()
    local p=pose(if old:find('Leg') then lower else upper,name,cf,src.Weight)
    p.EasingStyle=src.EasingStyle;p.EasingDirection=src.EasingDirection
   end
  end
  for _,child in frame:GetChildren() do if child:IsA('KeyframeMarker') then child:Clone().Parent=key end end
 end
 return result
end
return Donor
