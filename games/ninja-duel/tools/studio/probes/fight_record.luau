-- Client: record successive live duels (including tool/pose diagnostics).
-- Read-only observer. Templates stay unparented until film_show is invoked.
local RS=game:GetService('RunService')
local Players=game:GetService('Players')
local remote=game.ReplicatedStorage.NinjaDuel.Action
local Motion=require(Players.LocalPlayer.PlayerScripts.NinjaDuelClient.VelmoraMotionEngine)
shared.NdFilms={}
local latest,current
local function keyOf(model,part)
 local names={};local node=part
 while node and node~=model do
  local index=0
  for _,sibling in node.Parent:GetChildren() do if sibling.Name==node.Name then index+=1 end;if sibling==node then break end end
  table.insert(names,1,node.Name..'#'..index);node=node.Parent
 end
 return table.concat(names,'/')
end
local function template(model)
 model.Archivable=true
 for _,x in model:GetDescendants() do x.Archivable=true end
 local copy=model:Clone()
 for _,x in copy:GetDescendants() do if x:IsA('LuaSourceContainer') then x:Destroy() end end
 return copy
end
remote.OnClientEvent:Connect(function(s)latest=s end)
RS:BindToRenderStep('NdFightRecord',Enum.RenderPriority.Camera.Value+4,function()
 local s=latest
 if not s or s.phase~='Duel' then return end
 local me=Players.LocalPlayer.Character
 local folder=me and me.Parent
 local bot=folder and folder:FindFirstChild(s.bot.id)
 if not me or not bot then return end
 if not current or current.epoch~=s.epoch then
  current={epoch=s.epoch,started=os.clock(),frames={},models={},fighters={s.human.fighterId,s.bot.fighterId},keys=setmetatable({},{__mode='k'}),toolSamples=0,toolErrors=0}
  shared.NdFilms[s.epoch]=current
 end
 if #current.frames>=2200 then return end
 local t=os.clock()-current.started
 if t>2 and not current.models.me then current.models={me=template(me),bot=template(bot)} end
 local frame={t=t,label=string.format('%s:%s/%s/%s %s:%s/%s/%s',s.human.fighterId,s.human.state,s.human.attackName or '-',s.human.reaction or '-',s.bot.fighterId,s.bot.state,s.bot.attackName or '-',s.bot.reaction or '-'),poses={}}
 for who,model in {me=me,bot=bot} do
  local pose={}
  for _,d in model:GetDescendants() do
   if d:IsA('BasePart') then
    local key=current.keys[d];if not key then key=keyOf(model,d);current.keys[d]=key end
    pose[key]={cf=d.CFrame,tr=d.Transparency+d.LocalTransparencyModifier}
   end
  end
  frame.poses[who]=pose
 end
 table.insert(current.frames,frame)
end)
return 'continuous fight recorder armed'
