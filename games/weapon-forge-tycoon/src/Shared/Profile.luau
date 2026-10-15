local C=require('./Config')
local B=require('./Collection')
local P={}
function P.new(now)
 return {Schema=C.Schema,Coins=0,MarketFunds=0,HasPaidResources=false,Upgrades={Speed=0,Value=0,Luck=0,Display=0,Capacity=0},Zone=1,Inventory={},Collection={},Discoveries={},Book={},CollectionMilestones={},MarketHistory={},Material=1,Materials={Iron=4},Equipped=nil,Listings={},MarketResults={Count=0,Coins=0},ResourceUntil=0,Prestige=0,Owned={},Receipts={},Settings={Music=true,SFX=true,LowVFX=false,CameraShake=true,AutoForge=false,AutoMerge=false,QuickMerge=false,MergeThreshold=2},LastSeen=now,Stats={Forged=0,Sold=0,Merged=0,Earned=0,Seconds=0,BestValue=0,MarketSales=0,MarketCount=0,Mythics=0},Tutorial=0,LuckUntil=0}
end
local function number(v, fallback, lo, hi)
 if type(v)~='number' or v~=v or math.abs(v)==math.huge then return fallback end
 return math.clamp(math.floor(v),lo,hi)
end
function P.load(raw,now)
 local d=P.new(now)
 if type(raw)~='table' then return d end
 if type(raw.Schema)=='number' and raw.Schema>C.Schema then error('Future profile schema; refusing downgrade') end
 d.Coins=number(raw.Coins,0,0,C.MaxCoins)
 d.MarketFunds=number(raw.MarketFunds,d.Coins,0,d.Coins)
 d.HasPaidResources=raw.HasPaidResources==true
 d.Zone=number(raw.Zone,1,1,3); d.Prestige=number(raw.Prestige,0,0,100000)
 d.LastSeen=number(raw.LastSeen,now,0,now); d.Tutorial=number(raw.Tutorial,0,0,5)
 d.LuckUntil=number(raw.LuckUntil,0,0,now+C.StarterLuckSeconds)
 for k,u in pairs(C.Upgrades) do d.Upgrades[k]=number(type(raw.Upgrades)=='table' and raw.Upgrades[k],0,0,u.Max) end
 for k,v in pairs(d.Settings) do
  local x=type(raw.Settings)=='table' and raw.Settings[k]
  if type(x)==type(v) then d.Settings[k]=k=='MergeThreshold' and number(x,2,1,5) or x end
 end
 for k in pairs(d.Stats) do d.Stats[k]=number(type(raw.Stats)=='table' and raw.Stats[k],0,0,C.MaxCoins) end
 for k in pairs(C.Monetization) do if type(raw.Owned)=='table' and raw.Owned[k]==true then d.Owned[k]=true end end
 if type(raw.Receipts)=='table' then for id,v in pairs(raw.Receipts) do if type(id)=='string' and v==true then d.Receipts[id]=true end end end
 if type(raw.Collection)=='table' then for i=1,#C.Weapons do if raw.Collection[tostring(i)] then d.Collection[tostring(i)]=true end end end
 d.Materials={}
 for _,m in ipairs(C.Materials) do d.Materials[m.Name]=number(type(raw.Materials)=='table' and raw.Materials[m.Name],m.Name=='Iron' and 4 or 0,0,C.MaterialCap) end
 d.MarketWallet=number(raw.MarketWallet,0,0,C.MaxCoins)
 d.ResourceUntil=number(raw.ResourceUntil,0,0,now+3600)
 -- Server-owned escrow and pending operations must survive reconnect unchanged.
 if type(raw.Listings)=='table' then d.Listings=raw.Listings end
 if type(raw.PendingMarket)=='table' then d.PendingMarket=raw.PendingMarket end
 if type(raw.MarketResults)=='table' then d.MarketResults={Count=number(raw.MarketResults.Count,0,0,C.MaxCoins),Coins=number(raw.MarketResults.Coins,0,0,C.MaxCoins)} end
 d.Material=number(raw.Material,1,1,#C.Materials)
 if C.Materials[d.Material].Zone>d.Zone then d.Material=1 end
 if type(raw.Discoveries)=='table' then
  for key,count in pairs({Blueprint=#C.Weapons,Blade=3,Guard=3,Handle=3,Material=#C.Materials,Rarity=#C.Rarities,Mutation=#C.Mutations,Variant=2}) do
   for i=1,count do local k=key..':'..i; if raw.Discoveries[k]==true then d.Discoveries[k]=true end end
  end
 end
 if type(raw.CollectionMilestones)=='table' then for i=1,5 do if raw.CollectionMilestones[tostring(i)]==true then d.CollectionMilestones[tostring(i)]=true end end end
 if type(raw.Book)=='table' then
  for key in pairs(d.Discoveries) do
   local entry=raw.Book[key]
   if type(entry)=='table' then
    local w=entry.Weapon
    if type(w)=='table' and C.Weapons[w.Blueprint] and C.Rarities[w.Rarity] and C.Mutations[w.Mutation] then
     d.Book[key]={FirstFound=number(entry.FirstFound,now,0,now),BestValue=number(entry.BestValue,0,0,C.MaxCoins),Weapon={Id='book',Blueprint=w.Blueprint,Rarity=w.Rarity,Mutation=w.Mutation,Material=number(w.Material,1,1,#C.Materials),Blade=number(w.Blade,1,1,3),Guard=number(w.Guard,1,1,3),Handle=number(w.Handle,1,1,3),Perfect=w.Perfect==true,Secret=w.Secret==true}}
    end
   end
  end
 end
 if type(raw.MarketHistory)=='table' then
  for _,entry in ipairs(raw.MarketHistory) do
   if type(entry)=='table' and (entry.Kind=='Bought' or entry.Kind=='Sold') and type(entry.Name)=='string' and #entry.Name<=64 then
    table.insert(d.MarketHistory,{Kind=entry.Kind,Name=entry.Name,Price=number(entry.Price,0,0,C.MaxCoins),Net=number(entry.Net,0,0,C.MaxCoins),At=number(entry.At,now,0,now)})
   end
   if #d.MarketHistory>=20 then break end
  end
 end
 -- Old blueprint discoveries survive even when their weapons have been sold.
 for k in pairs(d.Collection) do d.Discoveries['Blueprint:'..k]=true end
 local seen,displayed={},0
 if type(raw.Inventory)=='table' then
  for _,w in ipairs(raw.Inventory) do
   if type(w)=='table' and type(w.Id)=='string' and #w.Id<=64 and not seen[w.Id] and type(w.Blueprint)=='number' and C.Weapons[w.Blueprint] and type(w.Rarity)=='number' and C.Rarities[w.Rarity] and type(w.Mutation)=='number' and C.Mutations[w.Mutation] then
    seen[w.Id]=true
    local display=w.Displayed==true and displayed<(C.DisplaySlots+(d.Owned.DisplaySlots and 2 or 0)+B.rewards(d).Slots)
    if display then displayed+=1 end
    table.insert(d.Inventory,{Id=w.Id,Blueprint=w.Blueprint,Rarity=w.Rarity,Mutation=w.Mutation,Locked=w.Locked==true,Displayed=display,Material=number(w.Material,1,1,#C.Materials),Blade=number(w.Blade,1,1,3),Guard=number(w.Guard,1,1,3),Handle=number(w.Handle,1,1,3),Perfect=w.Perfect==true,Secret=w.Secret==true,Paid=w.Paid==true,FoundAt=number(w.FoundAt,now,0,now)})
   end
   if #d.Inventory>=C.InventoryBase+d.Upgrades.Capacity*C.Upgrades.Capacity.Effect then break end
  end
 end
 for _,w in ipairs(d.Inventory) do B.mark(d,w); if raw.Equipped==w.Id then d.Equipped=w.Id; w.Displayed=false end end
 if type(raw.Flags)=='table' then d.Flags={} for k,v in pairs(raw.Flags) do if type(k)=='string' and #k<32 and v==true then d.Flags[k]=true end end end
 return d
end
return P
