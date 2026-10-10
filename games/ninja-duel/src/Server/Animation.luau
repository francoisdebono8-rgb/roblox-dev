-- Bangla PunchMoves animation playback, adapted for server-owned human and AI R15.
-- Combat uses imported choreography; the previous procedural punch fallback is removed.
local Shared=game:GetService('ReplicatedStorage').NinjaDuel
local Combo=require(Shared.BanglaCombo)
local Bindings=require(Shared.AnimationBindings)
local Donor=require(script.Parent.DonorAnimations)
local RunService=game:GetService('RunService')
local Provider=game:GetService('KeyframeSequenceProvider')
local ServerStorage=game:GetService('ServerStorage')
local Animation={}
local catalog={Idle=656117400,Run=656118852,Walk=656121766,Jump=656117878,Fall=656115606,Climb=656114359}
local cache,failures,loading={},{},{}
local function resolve(name)
 if Bindings[name] and Bindings[name]>0 then return 'rbxassetid://'..Bindings[name] end
 if not RunService:IsStudio() then return nil,'Publish the retargeted '..name..' R15 sequence and fill AnimationBindings.' end
 if cache[name] then return cache[name] end
 if failures[name] then return nil,failures[name] end
 if loading[name] then
  local deadline=os.clock()+15
  repeat task.wait(.05) until not loading[name] or os.clock()>=deadline
  return cache[name],failures[name] or 'Animation fetch still pending'
 end
 loading[name]=true
 local ok,value=pcall(function()
 local seq=Provider:GetKeyframeSequenceAsync('rbxassetid://'..Combo.AnimationIds[name])
 local r15=Donor.retarget(seq);seq:Destroy()
 local folder=ServerStorage:FindFirstChild('BanglaR15Sequences')
 if not folder then folder=Instance.new('Folder');folder.Name='BanglaR15Sequences';folder.Parent=ServerStorage end
 r15.Name=name;r15.Parent=folder
 return Provider:RegisterKeyframeSequence(r15)
 end)
 loading[name]=nil
 if ok then cache[name]=value;return value end
 failures[name]=tostring(value);return nil,failures[name]
end
function Animation.attach(a)
 if a.model:GetAttribute('SkipDonorAnimationQA') then return false end
 local animator=a.hum:FindFirstChildOfClass('Animator');if not animator then return false end
 local player={tracks={},instances={},current=nil,currentEvent=nil};a.animation=player
 a.model:SetAttribute('AuthoredAnimations',true)
 a.model:SetAttribute('DonorAnimationStatus','Loading')
 task.spawn(function()
  for name,id in catalog do
   local asset=Instance.new('Animation');asset.AnimationId='rbxassetid://'..id
   local ok,track=pcall(function() return animator:LoadAnimation(asset) end)
   if a.animation~=player then if ok then track:Destroy() end;asset:Destroy();return end
   table.insert(player.instances,asset)
   if ok then track.Priority=Enum.AnimationPriority.Movement;track.Looped=name=='Idle' or name=='Run' or name=='Walk' or name=='Climb';player.tracks[name]=track end
  end
  local ready=true
  for name in Combo.AnimationIds do
   local ok,id,reason=pcall(resolve,name)
   if a.animation~=player then return end
   if ok and id then
    local asset=Instance.new('Animation');asset.Name=name;asset.AnimationId=id
    local loaded,track=pcall(function() return animator:LoadAnimation(asset) end)
    table.insert(player.instances,asset)
    if loaded then track.Priority=Enum.AnimationPriority.Action;player.tracks[name]=track
    else ready=false;warn('[NinjaDuelAnimation] BLOCKED '..name..': '..tostring(track)) end
   else ready=false;warn('[NinjaDuelAnimation] BLOCKED '..name..': '..tostring(reason or id)) end
  end
  a.model:SetAttribute('DonorAnimationStatus',if ready then 'Ready' else 'Blocked')
 end)
 return true
end
local function choose(a,now)
 if a.health<=0 then return nil end
 if a.state=='Startup' or a.state=='Active' or a.state=='Recovery' and a.attackName and now-a.attackStarted<.5 then
  local action=Combo.Actions[a.attackName]
  -- Missing ninja branches reuse the imported moves; no local pose timeline.
  action=action or (if a.attackName=='Air1' or a.attackName=='DashAttack' then 'Punch' elseif a.attackName=='Air2' then 'HardSmack' else 'MegaPunch')
  return action,a.attackStarted
 end
 if a.reaction or a.state=='Stunned' then return nil end
 if a.state=='Guarding' then return 'Parry',0 end
 if a.state=='TechniqueChannel' then return 'Parry',a.untilTime end
 if a.wall then return 'Climb',0 end
 if a.airborne then return if a.root.AssemblyLinearVelocity.Y>0 then 'Jump' else 'Fall',0 end
 if a.locomotion.Magnitude>2 then return if a.locomotion.Magnitude>30 then 'Run' else 'Walk',0 end
 return 'Idle',0
end
function Animation.step(a,now)
 local p=a.animation;if not p then return false end
 local name,event=choose(a,now)
 if p.current~=name or p.currentEvent~=event then
  if p.current and p.tracks[p.current] then p.tracks[p.current]:Stop(.08) end
  p.current=name;p.currentEvent=event
  if name and p.tracks[name] then p.tracks[name]:Play(.06) end
 elseif name and p.tracks[name] and not p.tracks[name].IsPlaying and (name=='Idle' or name=='Run' or name=='Walk' or name=='Climb' or name=='Parry') then
  p.tracks[name]:Play(.08)
 end
 if (name=='Run' or name=='Walk') and p.tracks[name] then p.tracks[name]:AdjustSpeed(math.clamp(a.locomotion.Magnitude/(if name=='Run' then 32 else 18),.75,1.7)) end
 return true
end
function Animation.clear(a)
 local p=a.animation;a.animation=nil;if not p then return end
 for _,track in p.tracks do track:Stop(0);track:Destroy() end
 for _,asset in p.instances do asset:Destroy() end
end
return Animation
