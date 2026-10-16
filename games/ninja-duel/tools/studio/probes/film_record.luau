-- Client: record every rendered frame of both fighters' parts for DUR seconds into
-- shared.NdFilm (poses only, no VFX), annotated with the inspector's combat state.
local DUR=4
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local me=Players.LocalPlayer.Character
local folder=me and me.Parent
local models={me=me,bot=folder and folder:FindFirstChild("AIFighter")}
if not models.me or not models.bot then return "no fighters" end
local keyCache=setmetatable({},{__mode="k"})
local function keyOf(model,part)
 local k=keyCache[part]
 if k then return k end
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
 k=table.concat(names,"/")
 keyCache[part]=k
 return k
end
local latest=nil
local remote=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuelCombatDebug")
local rconn=remote and remote.OnClientEvent:Connect(function(snap) latest=snap end)
local function label()
 if not latest or not latest.actors then return "" end
 local out={}
 for _,a in latest.actors do
  table.insert(out,string.format("%s:%s/%s/%s",string.sub(a.fighterId or a.id or "?",1,4),a.state or "?",a.move or "-",a.reaction or "-"))
 end
 return table.concat(out," ")
end
local frames={}
local t0=os.clock()
local conn=RS.RenderStepped:Connect(function()
 local f={t=os.clock()-t0,label=label(),poses={}}
 for who,model in models do
  local pose={}
  for _,d in model:GetDescendants() do
   if d:IsA("BasePart") then pose[keyOf(model,d)]={cf=d.CFrame,tr=d.Transparency+d.LocalTransparencyModifier} end
  end
  f.poses[who]=pose
 end
 table.insert(frames,f)
end)
task.wait(DUR)
conn:Disconnect();if rconn then rconn:Disconnect() end
shared.NdFilm={frames=frames,models=models}
return string.format("recorded %d frames over %.2f s",#frames,DUR)
