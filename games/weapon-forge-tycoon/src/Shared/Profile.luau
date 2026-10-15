local C=require('./Config')
local P={}
function P.new(now)
 return {Schema=C.Schema,Coins=0,Upgrades={Speed=0,Value=0,Luck=0,Display=0,Capacity=0},Zone=1,Inventory={},Collection={},Prestige=0,Owned={},Receipts={},Settings={Music=true,SFX=true,LowVFX=false,CameraShake=true,AutoForge=false,AutoMerge=false,MergeThreshold=2},LastSeen=now,Stats={Forged=0,Sold=0,Merged=0,Earned=0,Seconds=0},Tutorial=0,LuckUntil=0}
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
 d.Zone=number(raw.Zone,1,1,3); d.Prestige=number(raw.Prestige,0,0,100000)
 d.LastSeen=number(raw.LastSeen,now,0,now); d.Tutorial=number(raw.Tutorial,0,0,5)
 d.LuckUntil=number(raw.LuckUntil,0,0,now+600)
 for k,u in pairs(C.Upgrades) do d.Upgrades[k]=number(type(raw.Upgrades)=='table' and raw.Upgrades[k],0,0,u.Max) end
 for k,v in pairs(d.Settings) do
  local x=type(raw.Settings)=='table' and raw.Settings[k]
  if type(x)==type(v) then d.Settings[k]=k=='MergeThreshold' and number(x,2,1,5) or x end
 end
 for k in pairs(d.Stats) do d.Stats[k]=number(type(raw.Stats)=='table' and raw.Stats[k],0,0,C.MaxCoins) end
 for k in pairs(C.Monetization) do if type(raw.Owned)=='table' and raw.Owned[k]==true then d.Owned[k]=true end end
 if type(raw.Receipts)=='table' then for id,v in pairs(raw.Receipts) do if type(id)=='string' and v==true then d.Receipts[id]=true end end end
 if type(raw.Collection)=='table' then for i=1,#C.Weapons do if raw.Collection[tostring(i)] then d.Collection[tostring(i)]=true end end end
 local seen,displayed={},0
 if type(raw.Inventory)=='table' then
  for _,w in ipairs(raw.Inventory) do
   if type(w)=='table' and type(w.Id)=='string' and #w.Id<=64 and not seen[w.Id] and type(w.Blueprint)=='number' and C.Weapons[w.Blueprint] and type(w.Rarity)=='number' and C.Rarities[w.Rarity] and type(w.Mutation)=='number' and C.Mutations[w.Mutation] then
    seen[w.Id]=true
    local display=w.Displayed==true and displayed<(C.DisplaySlots+(d.Owned.DisplaySlots and 2 or 0))
    if display then displayed+=1 end
    table.insert(d.Inventory,{Id=w.Id,Blueprint=w.Blueprint,Rarity=w.Rarity,Mutation=w.Mutation,Locked=w.Locked==true,Displayed=display})
   end
   if #d.Inventory>=C.InventoryBase+d.Upgrades.Capacity*10 then break end
  end
 end
 if type(raw.Flags)=='table' then d.Flags={} for k,v in pairs(raw.Flags) do if type(k)=='string' and #k<32 and v==true then d.Flags[k]=true end end end
 return d
end
return P
