-- PhotoKit: build posed fighters on a backdrop for marketing captures (edit mode)
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local function find(name) for _,d in SSS:GetDescendants() do if d.Name==name and d:IsA("ModuleScript") then return d end end end
local World=require(find("World"))
local LM=require(find("LookMeshes"))
local Fighters=require(RS.NinjaDuel.Fighters)
local K={}
local r=math.rad
K.POSES={
 guard={LeftShoulder={38,-10,-14},RightShoulder={26,12,16},LeftElbow={72,0,0},RightElbow={84,0,0},LeftHip={14,0,-6},RightHip={-10,0,6},LeftKnee={-18,0,0},RightKnee={-8,0,0},Waist={-4,-10,0},Neck={2,6,0}},
 punch={RightShoulder={95,10,8},RightElbow={5,0,0},LeftShoulder={45,-20,-10},LeftElbow={95,0,0},Waist={-6,28,0},Neck={0,-20,0},LeftHip={28,0,-8},LeftKnee={-30,0,0},RightHip={-22,0,8},RightKnee={-10,0,0}},
 charge={RightShoulder={60,0,10},RightElbow={30,0,0},LeftShoulder={70,20,-30},LeftElbow={60,0,0},Waist={-12,-15,0},Neck={-10,10,0},LeftHip={30,0,-10},LeftKnee={-40,0,0},RightHip={-25,0,10},RightKnee={-15,0,0}},
 sign={RightShoulder={50,30,20},RightElbow={110,0,0},LeftShoulder={50,-30,-20},LeftElbow={110,0,0},Neck={-6,0,0},LeftHip={8,0,-8},RightHip={-6,0,8},Waist={0,0,0}},
 cross={RightShoulder={30,40,10},RightElbow={100,0,0},LeftShoulder={30,-40,-10},LeftElbow={100,0,0},Neck={-4,-12,0},Waist={0,8,0},LeftHip={4,0,-6},RightHip={-4,0,6}},
 kick={RightHip={95,0,10},RightKnee={-5,0,0},LeftHip={-10,0,-4},LeftKnee={-20,0,0},Waist={14,-10,0},RightShoulder={30,0,60},RightElbow={30,0,0},LeftShoulder={60,0,-20},LeftElbow={80,0,0},Neck={-14,0,0}},
 ready={RightShoulder={-30,0,40},RightElbow={20,0,0},LeftShoulder={40,-20,-20},LeftElbow={90,0,0},LeftHip={30,0,-12},LeftKnee={-45,0,0},RightHip={-35,0,14},RightKnee={-20,0,0},Waist={-18,-20,0},Neck={-14,15,0}},
}
function K.clear()
 local f=workspace:FindFirstChild("PhotoSet") if f then f:Destroy() end
 f=Instance.new("Folder") f.Name="PhotoSet" f.Parent=workspace return f
end
function K.load()
 LM.preload()
 local t=os.clock() while os.clock()-t<15 do local p=false for _,s in LM.state do if s=="loading" then p=true end end if not p then break end task.wait(.3) end
end
-- id, CFrame, pose name, extra overrides
function K.fighter(id,cf,pose,extra)
 local f=workspace:FindFirstChild("PhotoSet") or K.clear()
 local model,_,root,joints=World.rig(f,Fighters[id],cf,id)
 root.Anchored=true
 local offs=K.offsets(model)
 local p=table.clone(K.POSES[pose or "guard"]) if extra then for k,v in extra do p[k]=v end end
 for name,a in p do
  local j=joints and joints[name] or model:FindFirstChild(name,true)
  if j and j:IsA("Motor6D") then j.C0=j.C0*CFrame.Angles(r(a[1]),r(a[2]),r(a[3])) end
 end
 K.solve(model,offs)
 for _,d in model:GetDescendants() do
  if d:IsA("BasePart") then d.Anchored=true end
  if d:IsA("Humanoid") then d.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
 end
 return model
end
-- edit mode has no joint simulation: place every part from its joint chain
function K.solve(model,offsets)
 local root=model:FindFirstChild("HumanoidRootPart")
 local done={[root]=true}
 local links={}
 for _,d in model:GetDescendants() do
  if d:IsA("WeldConstraint") or d:IsA("JointInstance") then d.Enabled=false end
 end
 for _,d in model:GetDescendants() do
  if (d:IsA("Motor6D") or d:IsA("Weld")) and d.Part0 and d.Part1 then
   links[#links+1]={d.Part0,d.Part1,function(p0) return p0.CFrame*d.C0*d.C1:Inverse() end}
   links[#links+1]={d.Part1,d.Part0,function(p1) return p1.CFrame*d.C1*d.C0:Inverse() end}
  elseif d:IsA("WeldConstraint") and d.Part0 and d.Part1 and offsets[d] then
   local o=offsets[d]
   links[#links+1]={d.Part0,d.Part1,function(p0) return p0.CFrame*o end}
   links[#links+1]={d.Part1,d.Part0,function(p1) return p1.CFrame*o:Inverse() end}
  end
 end
 for _=1,30 do
  local moved=false
  for _,l in links do
   if done[l[1]] and not done[l[2]] then l[2].CFrame=l[3](l[1]) done[l[2]]=true moved=true end
  end
  if not moved then break end
 end
end
function K.offsets(model)
 local o={}
 for _,d in model:GetDescendants() do if d:IsA("WeldConstraint") and d.Part0 and d.Part1 then o[d]=d.Part0.CFrame:ToObjectSpace(d.Part1.CFrame) end end
 return o
end
function K.backdrop(color,cf,size)
 local f=workspace:FindFirstChild("PhotoSet")
 local bg=f:FindFirstChild("BG") or Instance.new("Part")
 bg.Name="BG" bg.Anchored=true bg.Size=size or Vector3.new(400,400,1) bg.CFrame=cf bg.Color=color bg.Material=Enum.Material.SmoothPlastic bg.CastShadow=false bg.Parent=f
 return bg
end
return K
