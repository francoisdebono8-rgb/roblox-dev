local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Physics=game:GetService('PhysicsService')
local Shared=game.ReplicatedStorage.WFT
local C=require(Shared.Config)
local E=require(Shared.Economy)
local A=require(Shared.Actions)
local B=require(Shared.Collection)
local Data=require(script.Parent.DataService)
local Plot=require(script.Parent.PlotService)
local Analytics=require(script.Parent.Analytics)
local Monetization=require(script.Parent.MonetizationService)
local Market=require(script.Parent.MarketService).new(Data)
local World=require(script.Parent.ResourceWorld)
local request=Instance.new('RemoteEvent'); request.Name='Request'; request.Parent=Shared
local state=Instance.new('RemoteEvent'); state.Name='State'; state.Parent=Shared
local Policy=game:GetService('PolicyService')
local function restrictedPurchase(key) return key=='Starter' or key=='LuckyForge' or key=='Small' or key=='Medium' or key=='Large' or key=='ResourceBoost' end
local eventState
local nextEvent=os.clock()+C.EventInterval
local function activeEvent() return eventState and os.clock()<eventState.Ends and C.Events[eventState.Index] or nil end
local buckets,confirms,ready,remainders,starts={},{},{},{},{}
local function push(player,event,result)
 local s=Data.Sessions[player]; if not s or not ready[player] then return end
 local d=s.Data
 local payload={Coins=d.Coins,Upgrades=d.Upgrades,Zone=d.Zone,Inventory=d.Inventory,Collection=d.Collection,Discoveries=d.Discoveries,Book=d.Book,CollectionMilestones=d.CollectionMilestones,MarketHistory=d.MarketHistory,CollectionRewards=B.rewards(d),Material=d.Material,Materials=d.Materials,Equipped=d.Equipped,Listings=d.Listings,MarketFunds=d.MarketFunds,Market=Market.snapshot(),MarketResults=d.MarketResults,MarketBusy=s.MarketBusy,Craft=d.Craft,Clock=os.clock(),Event=eventState,Prestige=d.Prestige,Owned=d.Owned,Settings=d.Settings,Tutorial=d.Tutorial,Stats=d.Stats,Income=E.income(d),Capacity=E.capacity(d),Slots=E.slots(d),Memory=s.Memory,PaidRandomAllowed=s.PaidRandomAllowed==true,Unix=os.time(),Busy=d.Craft~=nil,Duration=E.speed(d)}
 state:FireClient(player,payload,event,result)
 Plot.update(player,d)
end
local function first(player,d,key,event)
 d.Flags=d.Flags or {}
 if not d.Flags[key] then d.Flags[key]=true; Analytics.event(player,event) end
end
Plot.init()
World.init(Plot,Data,push)
pcall(function() Physics:RegisterCollisionGroup('WFTPlayers') end)
Physics:CollisionGroupSetCollidable('WFTPlayers','WFTPlayers',false)
local function joined(player)
 if not Plot.assign(player) then player:Kick('All six workshops are occupied. Please join another server.'); return end
 player.CharacterAdded:Connect(function(character)
  Plot.spawn(player,character)
  for _,p in ipairs(character:GetDescendants()) do if p:IsA('BasePart') then p.CollisionGroup='WFTPlayers' end end
  character.DescendantAdded:Connect(function(p) if p:IsA('BasePart') then p.CollisionGroup='WFTPlayers' end end)
 end)
 if player.Character then task.spawn(Plot.spawn,player,player.Character) end
 local s=Data.load(player)
 if not s then player:Kick('Your progress is still open elsewhere or saving is unavailable. Please try again shortly.'); Plot.release(player); return end
 if not player.Parent then Data.save(player,true); Data.Sessions[player]=nil; Plot.release(player); return end
 local offline=E.offline(s.Data,os.time()); A.credit(s.Data,offline); s.Data.LastSeen=os.time(); s.Offline=offline
 s.PaidRandomAllowed=false; s.PaidTradingAllowed=s.Memory==true
 if not s.Memory then local ok,policy=pcall(Policy.GetPolicyInfoForPlayerAsync,Policy,player); if ok then s.PaidRandomAllowed=policy.ArePaidRandomItemsRestricted==false; s.PaidTradingAllowed=policy.IsPaidItemTradingAllowed==true end end
 for _,w in ipairs(s.Data.Inventory) do if w.Id=='Starter-v2' then w.Id=Http:GenerateGUID(false) end end
 Market.recover(player,s)
 if s.Data.MarketResults.Count>0 then first(player,s.Data,'MarketSale','first_sale') end
 starts[player]=os.clock(); remainders[player]=0
 Analytics.event(player,'session_start'); if s.Data.Stats.Seconds>0 then Analytics.event(player,'session_return') end; Analytics.event(player,'tutorial_start'); Analytics.step(player,1,'Forge arrival')
 Monetization.refresh(player,Data,push)
 push(player,'welcome',offline)
end
Players.PlayerAdded:Connect(joined)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(joined,p) end
request.OnServerEvent:Connect(function(player,action,arg)
 if type(action)~='string' or #action>32 then return end
 local now=os.clock(); local b=buckets[player] or {Tokens=12,At=now}; buckets[player]=b
 b.Tokens=math.min(12,b.Tokens+(now-b.At)*5); b.At=now
 if b.Tokens<1 then return end; b.Tokens-=1
 if action=='Ready' then ready[player]=true; local s=Data.Sessions[player]; if s then push(player,'welcome',s.Offline); s.Offline=0 end; return end
 local s=Data.Sessions[player]; if not s or s.Busy or s.Closing or s.MarketBusy or s.MarketWorking then return end
 local d=s.Data; local ok,result=false,'Action unavailable.'
 if action=='MarketList' or action=='MarketBuy' or action=='MarketCancel' then
  s.MarketWorking=true
  if action=='MarketList' and type(arg)=='table' and type(arg.Id)=='string' and #arg.Id<=64 then ok,result=Market.list(player,s,arg.Id,arg.Price); if ok then first(player,d,'Listing','first_listing') end
  elseif action=='MarketBuy' and type(arg)=='string' and #arg<=64 then ok,result=Market.buy(player,s,arg); if ok and d.Flags and d.Flags.MarketPurchase then first(player,d,'PurchaseEvent','first_purchase') end
  elseif action=='MarketCancel' and type(arg)=='string' and #arg<=64 then ok,result=Market.cancel(player,s,arg) end
  s.MarketWorking=false
  if ok then push(player,action,result) else state:FireClient(player,nil,'error',result) end
  for p in pairs(Data.Sessions) do push(p) end
  return
 elseif action=='Inspect' and type(arg)=='table' and type(arg.Owner)=='number' and type(arg.Id)=='string' then
  local owner=Players:GetPlayerByUserId(arg.Owner); local session=owner and Data.Sessions[owner]
  local weapon=session and A.find(session.Data,arg.Id)
  local plot=owner and Plot.Plots[owner:GetAttribute('Plot') or 0]
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if weapon and weapon.Displayed and plot and root then
   for _,anchor in ipairs(plot.Racks:GetDescendants()) do
    if anchor:IsA('BasePart') and anchor:GetAttribute('WeaponId')==weapon.Id and (root.Position-anchor.Position).Magnitude<=15 then state:FireClient(player,nil,'inspect',{Weapon=weapon,Owner=owner.Name,OwnerId=owner.UserId,Value=E.value(session.Data,weapon)}); return end
   end
  end
  result='Walk closer to the displayed weapon.'
 elseif action=='MarketOpen' then first(player,d,'MarketOpen','first_market_open'); push(player); return
 elseif action=='MarketResultsSeen' then d.MarketResults={Count=0,Coins=0}; return
 elseif action=='Equip' and type(arg)=='string' then ok,result=A.equip(d,arg)
 elseif action=='Keep' then ok=true; first(player,d,'Keep','first_keep')
 elseif action=='Material' then ok,result=A.material(d,arg)
 elseif action=='Forge' then
  local plot=Plot.Plots[player:GetAttribute('Plot') or 0]
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if plot and root and (root.Position-plot.Anvil.Position).Magnitude<=16 then ok,result=A.forge(d,now,math.random,Http:GenerateGUID(false)) else result='Return to your anvil to forge.' end
 elseif action=='Hammer' then ok,result=A.hammer(d,now); if ok then state:FireClient(player,nil,'hammer',result) end
 elseif (action=='Sell' or action=='Display' or action=='Lock') and type(arg)=='string' and #arg<=64 then
  if action=='Sell' then ok,result=A.sell(d,arg); if ok then first(player,d,'Sell','first_sell') end
  elseif action=='Display' then ok,result=A.display(d,arg); if ok then first(player,d,'Display','first_display') end
  else ok,result=A.lock(d,arg) end
 elseif action=='MergePreview' then
  local ids,rarity=A.mergePreview(d)
  if ids then confirms[player]={Kind='Merge',Ids=ids,Token=Http:GenerateGUID(false),Expires=now+30}; state:FireClient(player,nil,'merge_preview',{Ids=ids,Rarity=rarity,Token=confirms[player].Token}); return end
  result='Keep three unlocked weapons of the same rarity to merge.'
 elseif action=='MergeConfirm' and type(arg)=='string' then
  local c=confirms[player]; confirms[player]=nil
  if c and c.Kind=='Merge' and c.Token==arg and c.Expires>=now then ok,result=A.merge(d,c.Ids,Http:GenerateGUID(false)); if ok then first(player,d,'Merge','first_merge') end end
 elseif action=='Upgrade' and type(arg)=='string' then ok,result=A.upgrade(d,arg); if ok then first(player,d,'Upgrade','first_upgrade') end
 elseif action=='Zone' then ok,result=A.zone(d); if ok then Analytics.event(player,'zone'..d.Zone..'_unlock') end
 elseif action=='PrestigePreview' then
  confirms[player]={Kind='Prestige',Token=Http:GenerateGUID(false),Expires=now+30}
  state:FireClient(player,nil,'prestige_preview',confirms[player].Token); return
 elseif action=='PrestigeConfirm' and type(arg)=='string' then
  local c=confirms[player]; confirms[player]=nil
  if c and c.Kind=='Prestige' and c.Token==arg and c.Expires>=now then ok,result=A.prestige(d); if ok then Analytics.event(player,'prestige') end end
 elseif action=='Setting' and type(arg)=='table' and type(arg.Key)=='string' then
  local key,value=arg.Key,arg.Value
  if key=='MergeThreshold' and type(value)=='number' and value==math.floor(value) and value>=1 and value<=5 then d.Settings[key]=value; ok=true
  elseif type(d.Settings[key])=='boolean' and type(value)=='boolean' then
   if key=='AutoForge' and not d.Owned.AutoForge or key=='AutoMerge' and not d.Owned.AutoMerge then result='This option needs its matching pass.'
   else d.Settings[key]=value; ok=true end
  end
 elseif action=='TutorialDone' and d.Tutorial==4 then d.Tutorial=5; ok=true; Analytics.event(player,'tutorial_complete'); Analytics.step(player,5,'Ready to collect')
 elseif action=='Shop' then Analytics.event(player,'shop_open'); return
 elseif action=='PurchasePrompt' and type(arg)=='string' and C.Monetization[arg] and C.Monetization[arg].Id and not s.Memory and (not restrictedPurchase(arg) or s.PaidRandomAllowed) then
  Analytics.event(player,'purchase_prompt'); state:FireClient(player,nil,'purchase_prompt',arg); return
 end
 if ok then
  if action=='Forge' then state:FireClient(player,nil,'forge_start',d.Craft) end
  push(player,action,result)
 else state:FireClient(player,nil,'error',result) end
end)
Monetization.init(Data,push)
Players.PlayerRemoving:Connect(function(player)
 local s=Data.Sessions[player]
 if s then
  s.Closing=true
  Analytics.event(player,'session_seconds',os.clock()-(starts[player] or os.clock()))
  while s.Busy or s.MarketWorking do task.wait(.1) end
  Data.save(player,true); Data.Sessions[player]=nil
 end
 Plot.release(player); buckets[player]=nil; confirms[player]=nil; ready[player]=nil; remainders[player]=nil; starts[player]=nil
end)
task.spawn(function()
 while true do
  task.wait(.25)
  for player,s in pairs(Data.Sessions) do
   if not s.Busy and not s.Closing and not s.MarketBusy and not s.MarketWorking then
    local d=s.Data; local now=os.clock()
    remainders[player]=(remainders[player] or 0)+E.income(d)*.25
    if remainders[player]>=1 then local n=math.floor(remainders[player]); remainders[player]-=n; A.credit(d,n) end
    local _,_,collectionProgress=B.progress(d)
    if collectionProgress>=.25 then first(player,d,'Collection25','collection_25') end
    if collectionProgress>=.5 then first(player,d,'Collection50','collection_50') end
    local starter=A.claimStarter(d,math.random,Http:GenerateGUID(false)); if starter then push(player,'starter_weapon',starter) end
    local weapon=A.finish(d,now,math.random,activeEvent(),os.time())
    if weapon then first(player,d,'Forge','first_forge'); push(player,'reveal',weapon) end
    if eventState and now>=eventState.Ends then eventState=nil end
    if now>=nextEvent then eventState={Index=math.random(#C.Events),Ends=now+C.EventSeconds}; nextEvent=now+C.EventInterval; for p in pairs(Data.Sessions) do push(p,'event',eventState) end end
    if d.Settings.AutoMerge and d.Owned.AutoMerge then
     local ids=A.mergePreview(d,d.Settings.MergeThreshold)
     if ids then local merged,result=A.merge(d,ids,Http:GenerateGUID(false)); if merged then first(player,d,'Merge','first_merge'); push(player,'auto_merge',result) end end
    end
    if not d.Craft and d.Settings.AutoForge and d.Owned.AutoForge then
     if A.forge(d,now,math.random,Http:GenerateGUID(false),true) then state:FireClient(player,nil,'forge_start',d.Craft); push(player) end
    end
   end
  end
 end
end)
task.spawn(function()
 while true do
  task.wait(2)
  for player,s in pairs(Data.Sessions) do if not s.Closing then
   if not s.Busy and not s.MarketBusy and not s.MarketWorking then s.Data.Stats.Seconds+=2 end
   push(player)
   if s.Data.Stats.Seconds>=600 and not s.TenMinutes then s.TenMinutes=true; Analytics.event(player,'session_10_minutes') end
   if not s.Busy and not s.MarketWorking and os.clock()>=(s.MarketRetryAt or 0) and (s.MarketBusy or os.clock()-(s.LastMarketCheck or 0)>15) then
    s.LastMarketCheck=os.clock(); s.MarketWorking=true
    task.spawn(function()
     local before=s.Data.Stats.MarketCount
     local recovered=Market.recover(player,s)
     s.MarketFailures=recovered and 0 or math.min(5,(s.MarketFailures or 0)+1); s.MarketRetryAt=os.clock()+(recovered and 0 or 2^s.MarketFailures)
     if s.Data.Stats.MarketCount>before then first(player,s.Data,'MarketSale','first_sale'); push(player,'market_sale',s.Data.MarketResults) end
     s.MarketWorking=false
    end)
   end
   if os.clock()-s.LastSave>30 and not s.Busy and not s.MarketWorking and not s.MarketBusy then task.spawn(Data.save,player,false) end
  end end
  World.update(Data)
 end
end)
game:BindToClose(function()
 local pending=0
 for player,s in pairs(Data.Sessions) do pending+=1; s.Closing=true; task.spawn(function() while s.Busy or s.MarketWorking do task.wait(.1) end; Data.save(player,true); pending-=1 end) end
 local deadline=os.clock()+25; while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
