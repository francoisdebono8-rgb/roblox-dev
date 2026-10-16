-- Client: chronophotograph of shared.NdFilm. COUNT frames evenly spaced between FROM
-- and TO seconds are posed as anchored ghost copies, side by side (SPACING studs apart
-- along the attack axis), seen from the side; the live fighters are hidden meanwhile.
local FROM,TO,COUNT,SPACING=1.0,2.0,6,9
local COLS=3 -- frames per row; rows stack upward (ROW_GAP studs)
local ROW_GAP=7.5
local RS=game:GetService("RunService")
local film=shared.NdFilm
if not film or #film.frames==0 then return "no film" end
pcall(function() RS:UnbindFromRenderStep("NdFilmCam") end)
if shared.NdGhosts then shared.NdGhosts:Destroy() end
local ghosts=Instance.new("Folder");ghosts.Name="NdGhosts";ghosts.Parent=workspace
shared.NdGhosts=ghosts
local function frameAt(t)
 local best=film.frames[1]
 for _,f in film.frames do if math.abs(f.t-t)<math.abs(best.t-t) then best=f end end
 return best
end
-- Stripped template per fighter: parts only, no joints, humanoid or scripts.
local function keyOf(model,part)
 local names={}
 local node=part
 while node and node~=model do
  local parent=node.Parent
  local index=0
  if parent then
   for _,sibling in parent:GetChildren() do
    if sibling.Name==node.Name then index+=1 end
    if sibling==node then break end
   end
  end
  table.insert(names,1,node.Name.."#"..index)
  node=parent
 end
 return table.concat(names,"/")
end
local function ghostOf(model)
 for _,d in model:GetDescendants() do pcall(function() d.Archivable=true end) end
 model.Archivable=true
 local copy=model:Clone()
 local keyed={}
 -- Keys from the live model (same hierarchy as the copy at clone time).
 local live={}
 for _,d in model:GetDescendants() do if d:IsA("BasePart") then table.insert(live,keyOf(model,d)) end end
 local i=0
 for _,d in copy:GetDescendants() do
  if d:IsA("BasePart") then
   i+=1
   keyed[live[i] or ("?"..i)]=d
   d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false;d.LocalTransparencyModifier=0
  elseif d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Humanoid") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Light") or d:IsA("BillboardGui") then
   d:Destroy()
  end
 end
 return copy,keyed
end
local first=frameAt(FROM)
-- Attack axis: from the player's fighter to the bot at the first shown frame.
local function rootOf(pose) local p=pose["HumanoidRootPart#1"];return p and p.cf.Position end
local a,b=rootOf(first.poses.me),rootOf(first.poses.bot)
if not a or not b then return "no roots in film" end
local axis=Vector3.new(b.X-a.X,0,b.Z-a.Z)
axis=if axis.Magnitude>.1 then axis.Unit else Vector3.xAxis
local labels={}
for n=0,COUNT-1 do
 local t=FROM+(TO-FROM)*n/math.max(1,COUNT-1)
 local f=frameAt(t)
 table.insert(labels,string.format("%d:%.2fs %s",n+1,f.t,f.label))
 local col,row=n%COLS,math.floor(n/COLS)
 local rows=math.ceil(COUNT/COLS)
 local offset=axis*(col*SPACING)+Vector3.new(0,(rows-1-row)*ROW_GAP,0)
 for who,model in film.models do
  local copy,keyed=ghostOf(model)
  copy.Name="Ghost_"..who.."_"..n
  for key,part in keyed do
   local rec=f.poses[who][key]
   if rec then part.CFrame=rec.cf+offset;part.Transparency=math.clamp(rec.tr,0,1) else part.Transparency=1 end
  end
  copy.Parent=ghosts
 end
end
-- Hide the live fighters while the ghosts are shown.
for _,model in film.models do
 for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end end
end
local cam=workspace.CurrentCamera
local rows=math.ceil(COUNT/COLS)
local cols=math.min(COUNT,COLS)
local mid=(a+b)/2+axis*((cols-1)*SPACING/2)+Vector3.new(0,(rows-1)*ROW_GAP/2,0)
local side=axis:Cross(Vector3.yAxis).Unit
local width=math.max((cols-1)*SPACING+9,(rows*ROW_GAP)*1.6)
local fov=40
local dist=(width/2)/math.tan(math.rad(fov/2))*1.05
RS:BindToRenderStep("NdFilmCam",Enum.RenderPriority.Camera.Value+6,function()
 cam.FieldOfView=fov
 cam.CFrame=CFrame.lookAt(mid+side*dist+Vector3.new(0,1.5,0),mid+Vector3.new(0,-.5,0))
 for _,model in film.models do
  for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=1 end end
 end
end)
return table.concat(labels,"\n")
