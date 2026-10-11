-- Preview scaffold reuses Ninja Duel's R15 dimensions and joint spacing.
-- Explicit CFrame hierarchy also works in edit-mode ViewportFrames without physics.
local R={}
function R.new(parent,tint)
 local model=Instance.new("Model");model.Name="MotionLab_R15";model.Parent=parent
 local parts={};local joints={};local order={}
 local function body(name,size,offset,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.CFrame=CFrame.new(offset);p.Parent=model;parts[name]=p;return p
 end
 local neutral=Color3.fromRGB(122,135,151);tint=tint or Color3.fromRGB(122,191,225)
 local root=body("HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero,neutral);root.Transparency=1
 body("LowerTorso",Vector3.new(2,1,1),Vector3.zero,tint);body("UpperTorso",Vector3.new(2,1.4,1),Vector3.new(0,1.15,0),tint);body("Head",Vector3.new(1.5,1.5,1.5),Vector3.new(0,2.45,0),Color3.fromRGB(206,214,223))
 local function joint(key,name,p0,p1,c0,c1)
  local m=Instance.new("Motor6D");m.Name=name;m.Part0=parts[p0];m.Part1=parts[p1];m.C0=CFrame.new(c0);m.C1=CFrame.new(c1);m.Parent=parts[p0]
  joints[key]=m;table.insert(order,key)
 end
 joint("Root","Root","HumanoidRootPart","LowerTorso",Vector3.zero,Vector3.zero)
 joint("Waist","Waist","LowerTorso","UpperTorso",Vector3.new(0,.65,0),Vector3.new(0,-.5,0))
 joint("Neck","Neck","UpperTorso","Head",Vector3.new(0,.9,0),Vector3.new(0,-.55,0))
 for _,side in {-1,1} do
  local prefix=if side<0 then "Left" else "Right";local key=if side<0 then "Left" else "Right"
  for _,row in {{"UpperArm",Vector3.new(.8,1.1,.8),Vector3.new(side*1.45,.72,0),tint},{"LowerArm",Vector3.new(.76,.95,.76),Vector3.new(side*1.45,-.28,0),neutral},{"Hand",Vector3.new(.72,.5,.72),Vector3.new(side*1.45,-1,0),neutral},{"UpperLeg",Vector3.new(.85,1.1,.85),Vector3.new(side*.5,-.85,0),neutral},{"LowerLeg",Vector3.new(.8,1.05,.8),Vector3.new(side*.5,-1.75,0),neutral},{"Foot",Vector3.new(.8,.42,1.15),Vector3.new(side*.5,-2.55,-.15),neutral}} do body(prefix..row[1],row[2],row[3],row[4]) end
  joint(key,prefix.."Shoulder","UpperTorso",prefix.."UpperArm",Vector3.new(side*1.05,.45,0),Vector3.new(-side*.4,.5,0))
  joint(prefix.."Elbow",prefix.."Elbow",prefix.."UpperArm",prefix.."LowerArm",Vector3.new(0,-.55,0),Vector3.new(0,.45,0))
  joint(prefix.."Wrist",prefix.."Wrist",prefix.."LowerArm",prefix.."Hand",Vector3.new(0,-.48,0),Vector3.new(0,.25,0))
  joint(prefix.."Hip",prefix.."Hip","LowerTorso",prefix.."UpperLeg",Vector3.new(side*.5,-.55,0),Vector3.new(0,.5,0))
  joint(prefix.."Knee",prefix.."Knee",prefix.."UpperLeg",prefix.."LowerLeg",Vector3.new(0,-.55,0),Vector3.new(0,.5,0))
  joint(prefix.."Ankle",prefix.."Ankle",prefix.."LowerLeg",prefix.."Foot",Vector3.new(0,-.5,0),Vector3.new(0,.2,.15))
 end
 local hum=Instance.new("Humanoid");hum.RigType=Enum.HumanoidRigType.R15;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.RequiresNeck=false;hum.Parent=model
 model.PrimaryPart=root
 local weapon=body("PreviewWeapon",Vector3.new(.1,.25,1),Vector3.zero,Color3.fromRGB(207,223,239));weapon.Transparency=1
 return {model=model,parts=parts,joints=joints,order=order,root=root,weapon=weapon}
end
function R.apply(rig,pose,origin,showRoot,showWeapon)
 rig.root.CFrame=CFrame.new(origin+(if showRoot then pose.motion or Vector3.zero else Vector3.zero))
 for _,key in rig.order do local m=rig.joints[key];local transform=pose[key] or CFrame.identity;m.Transform=transform;m.Part1.CFrame=m.Part0.CFrame*m.C0*transform*m.C1:Inverse() end
 rig.weapon.CFrame=rig.parts.RightHand.CFrame*CFrame.new(0,-.1,-.55)*(pose.Weapon or CFrame.identity);rig.weapon.Transparency=if showWeapon then 0 else 1
end
return R
