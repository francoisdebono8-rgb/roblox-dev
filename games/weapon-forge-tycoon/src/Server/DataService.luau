local DSS=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local Run=game:GetService('RunService')
local Shared=game.ReplicatedStorage.WFT
local Profile=require(Shared.Profile)
local Data={Sessions={}}
local store
local function getStore()
 if not store then store=DSS:GetDataStore('WeaponForgeTycoon_v1') end
 return store
end
local function retry(fn)
 local last
 for attempt=1,4 do
  local ok,result=pcall(fn)
  if ok then return true,result end
  last=result; task.wait(math.min(2^(attempt-1),4))
 end
 warn('WFT persistence request failed: '..tostring(last))
 return false
end
function Data.load(player)
 local token=Http:GenerateGUID(false)
 local now=os.time()
 if Run:IsStudio() and (workspace:GetAttribute('WFT_LocalQA') or game.PlaceId==0) then
  local s={Data=Profile.new(now),Token=token,Busy=false,Memory=true,LastSave=os.clock(),Closing=false}
  Data.Sessions[player]=s; return s
 end
 local ok,record=retry(function()
  return getStore():UpdateAsync('u_'..player.UserId,function(old)
   if old and old.Lease and old.Lease.Expires>os.time() and old.Lease.Token~=token then return nil end
   local d=Profile.load(old and old.Profile,now)
   return {Profile=d,Lease={Token=token,Expires=os.time()+180}}
  end)
 end)
 local memory=false
 if not ok and Run:IsStudio() and workspace:GetAttribute('WFT_LocalQA') then
  memory=true; record={Profile=Profile.new(now)}
  warn('WFT LOCAL QA: unsaved Studio session; purchases disabled')
 elseif not ok or not record then return nil end
 local s={Data=record.Profile,Token=token,Busy=false,Memory=memory,LastSave=os.clock(),Closing=false}
 Data.Sessions[player]=s
 return s
end
function Data.save(player,release)
 local s=Data.Sessions[player]
 if not s or s.Busy then return false end
 s.Busy=true
 s.Data.LastSeen=os.time()
 local snapshot=Http:JSONDecode(Http:JSONEncode(s.Data))
 snapshot.Craft=nil -- unfinished crafts never survive reconnect
 local ok=true
 if not s.Memory then
  local result
  ok,result=retry(function()
   return getStore():UpdateAsync('u_'..player.UserId,function(old)
    if not old or not old.Lease or old.Lease.Token~=s.Token then return nil end
    return {Profile=snapshot,Lease=not release and {Token=s.Token,Expires=os.time()+180} or nil}
   end)
  end)
  ok=ok and result~=nil
 end
 s.Busy=false
 if ok then s.LastSave=os.clock() elseif os.clock()-s.LastSave>110 then
  s.Closing=true; player:Kick('Your save connection was lost. Please rejoin to protect your progress.')
 end
 return ok
end
return Data
