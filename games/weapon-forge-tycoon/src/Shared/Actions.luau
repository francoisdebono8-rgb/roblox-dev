-- Pure authoritative transitions: no yielding, no client-supplied prices or roll results.
local C=require('./Config')
local E=require('./Economy')
local B=require('./Collection')
local O=require('./Odds')
local A={}
function A.credit(d,n,paid)
 d.Coins=math.min(C.MaxCoins,d.Coins+math.max(0,math.floor(n)))
 if not paid then d.MarketFunds=math.min(d.Coins,(d.MarketFunds or 0)+math.max(0,math.floor(n))) end
 d.Stats.Earned+=math.max(0,math.floor(n))
end
function A.find(d,id) for i,w in ipairs(d.Inventory) do if w.Id==id then return w,i end end end
function A.equip(d,id)
 local w=A.find(d,id)
 if not w or w.Displayed then return false,'Store this weapon before equipping it.' end
 d.Equipped=d.Equipped~=id and id or nil
 return true
end
function A.collect(d,material,now)
 local m=C.Materials[material]
 if not m or m.Zone>d.Zone then return false,'Unlock this resource zone first.' end
 local properties=E.properties(E.equipped(d))
 local amount=3+(material==1 and 1 or 0)
 if (d.ResourceUntil or 0)>now then amount*=2; d.HasPaidResources=true end
 local before=d.Materials[m.Name] or 0
 if before>=C.MaterialCap then return false,'Material storage is full. Return to your forge.' end
 d.Materials[m.Name]=math.min(C.MaterialCap,before+amount)
 return true,d.Materials[m.Name]-before,math.max(2,(5+material*2)/properties.Mining)
end
function A.material(d,key)
 if type(key)~='number' or key~=math.floor(key) or not C.Materials[key] or C.Materials[key].Zone>d.Zone then return false,'Unlock this material in the next forge.' end
 if d.Craft then return false,'Finish this weapon first.' end
 d.Material=key; return true
end
function A.forge(d,now,random,id,automatic)
 if d.Craft or #d.Inventory>=E.capacity(d) then return false,'Your inventory is full or the forge is busy.' end
 local material=d.Material or 1
 local m=C.Materials[material]
 if not m or m.Zone>d.Zone then return false,'This material is not unlocked.' end
 if (d.Materials[m.Name] or 0)<1 then return false,'Collect '..m.Name..' at the resource zone first.' end
 d.Materials[m.Name]-=1
 local duration=E.speed(d)
 d.Craft={Started=now,HeatEnd=now+duration*.42,Ready=now+duration,Duration=duration,Hits=0,PerfectHits=0,LastHit=now-1,Id=id,Material=material,Automatic=automatic==true}
 return true
end
function A.hammer(d,now)
 local c=d.Craft
 if not c or c.Automatic or now<c.HeatEnd or c.Hits>=3 or now-c.LastHit<.45 then return false,'Heat the metal, then land three hammer strikes.' end
 local target=c.HeatEnd+(c.Duration*.58/3)*(c.Hits+.5)
 local perfect=math.abs(now-target)<=C.PerfectWindow
 c.Hits+=1; c.LastHit=now
 if perfect then c.PerfectHits+=1 end
 return true,perfect
end
function A.finish(d,now,random,event,unixNow)
 local c=d.Craft
 if not c or now<c.Ready or (not c.Automatic and c.Hits<3) then return nil end
 d.Craft=nil
 local perfect=c.PerfectHits==3 and not c.Automatic
 local luck=O.luck(d,unixNow or os.time(),event,perfect)
 local mat=C.Materials[c.Material]
 local pool=O.mutations(c.Material,event)
 local w={Id=c.Id,Paid=d.HasPaidResources or (E.equipped(d) and E.equipped(d).Paid) or (d.LuckUntil or 0)>(unixNow or os.time()),FoundAt=unixNow or os.time(),Blueprint=(C.Materials[c.Material].Zone-1)*3+math.min(3,math.floor(random()*3)+1),Rarity=E.roll(C.Rarities,random,luck),Mutation=pool[E.roll(pool,random)].Index,Material=c.Material,Blade=math.min(mat.Parts,math.floor(random()*mat.Parts)+1),Guard=math.min(mat.Parts,math.floor(random()*mat.Parts)+1),Handle=math.min(mat.Parts,math.floor(random()*mat.Parts)+1),Secret=random()<C.SecretChance,Perfect=perfect,Locked=false,Displayed=false}
 if d.Stats.Forged==0 then w.Blueprint=2 end
 table.insert(d.Inventory,w); B.mark(d,w,E.value(d,w),unixNow); d.Stats.Forged+=1; d.Stats.BestValue=math.max(d.Stats.BestValue,E.value(d,w)); if w.Rarity==6 then d.Stats.Mythics+=1 end
 if d.Tutorial==0 then d.Tutorial=1 elseif d.Tutorial==3 then d.Tutorial=4 end
 return w
end
function A.sell(d,id)
 local w,i=A.find(d,id)
 if not w or w.Locked or w.Displayed or w.Id==d.Equipped then return false,'Only unlocked, stored weapons can be sold.' end
 local value=E.value(d,w); table.remove(d.Inventory,i); A.credit(d,value,w.Paid); d.Stats.Sold+=1
 if d.Tutorial==1 then d.Tutorial=2 end
 return true,value
end
function A.display(d,id)
 local w=A.find(d,id); if not w then return false,'Weapon no longer exists.' end
 if w.Id==d.Equipped then return false,'Unequip this weapon first.' end
 if w.Displayed then w.Displayed=false; return true end
 local count=0; for _,v in ipairs(d.Inventory) do if v.Displayed then count+=1 end end
 if count>=E.slots(d) then return false,'All rack slots are occupied. Store a displayed weapon first.' end
 w.Displayed=true; return true
end
function A.lock(d,id) local w=A.find(d,id); if not w then return false,'Weapon no longer exists.' end; w.Locked=not w.Locked; return true end
function A.mergePreview(d,threshold)
 for rarity=1,math.min(threshold or 5,5) do
  local ids={}
  for _,w in ipairs(d.Inventory) do if w.Rarity==rarity and not w.Displayed and not w.Locked and w.Id~=d.Equipped then table.insert(ids,w.Id); if #ids==3 then return ids,rarity+1 end end end
 end
 return nil
end
function A.merge(d,ids,id)
 if type(ids)~='table' or #ids~=3 then return false,'Choose three weapons.' end
 local items,seen={},{}
 for _,key in ipairs(ids) do
  if type(key)~='string' or seen[key] then return false,'Invalid merge.' end
  seen[key]=true; local w=A.find(d,key)
  if not w or w.Locked or w.Displayed or w.Id==d.Equipped or w.Rarity>=6 then return false,'Merge contents changed. Review again.' end
  table.insert(items,w)
 end
 if items[1].Rarity~=items[2].Rarity or items[1].Rarity~=items[3].Rarity then return false,'Rarities must match.' end
 -- The first preview weapon supplies silhouette and mutation; explicitly shown in UI.
 local result={Id=id,Blueprint=items[1].Blueprint,Rarity=items[1].Rarity+1,Mutation=items[1].Mutation,Material=items[1].Material or 1,Blade=items[1].Blade or 1,Guard=items[1].Guard or 1,Handle=items[1].Handle or 1,Paid=items[1].Paid or items[2].Paid or items[3].Paid,FoundAt=os.time(),Perfect=items[1].Perfect==true,Secret=items[1].Secret==true,Locked=false,Displayed=false}
 for i=#d.Inventory,1,-1 do if seen[d.Inventory[i].Id] then table.remove(d.Inventory,i) end end
 table.insert(d.Inventory,result); B.mark(d,result,E.value(d,result)); d.Stats.Merged+=1
 return true,result
end
function A.upgrade(d,key)
 local u=C.Upgrades[key]; if not u then return false,'Unknown upgrade.' end
 local level=d.Upgrades[key]; if level>=u.Max then return false,'Maximum level reached.' end
 local cost=E.cost(key,level); if d.Coins<cost then return false,'Earn more coins first.' end
 d.Coins-=cost; d.MarketFunds=math.min(d.MarketFunds or 0,d.Coins); d.Upgrades[key]+=1
 if d.Tutorial==2 then d.Tutorial=3 end
 return true
end
function A.zone(d)
 if d.Zone>=3 then return false,'All forges unlocked.' end
 local cost=C.Zones[d.Zone+1].Cost; if d.Coins<cost then return false,'Earn more coins to unlock the next forge.' end
 if d.Craft then return false,'Finish forging first.' end
 d.Coins-=cost; d.MarketFunds=math.min(d.MarketFunds or 0,d.Coins); d.Zone+=1; return true
end
function A.prestige(d)
 if d.Zone~=3 or d.Coins<E.prestigeCost(d) or d.Craft then return false,'Unlock Arcane Ruins and reach your prestige Coins goal. Finish forging first.' end
 if #d.Inventory>30 then return false,'Store at most 30 weapons before resetting capacity.' end
 d.Coins=0; d.MarketFunds=0; d.HasPaidResources=false; d.Zone=1; d.Material=1; d.Prestige+=1; d.Materials={Iron=4,Steel=math.min(8,d.Prestige*2)}
 for k in pairs(d.Upgrades) do d.Upgrades[k]=0 end
 return true
end
function A.pass(d,key,now)
 local p=C.Monetization[key]
 if not p or p.Kind~='Pass' then return false end
 if d.Owned[key] then return true end
 d.Owned[key]=true
 if key=='Starter' then A.credit(d,E.starterCoins(d),true); d.LuckUntil=now+C.StarterLuckSeconds end
 return true
end
function A.claimStarter(d,random,id)
 d.Flags=d.Flags or {}
 if not d.Owned.Starter or d.Flags.StarterV02 or #d.Inventory>=E.capacity(d) then return nil end
 local w={Id=id or 'Starter-v2',Paid=true,FoundAt=os.time(),Blueprint=(d.Zone-1)*3+math.min(3,math.floor(random()*3)+1),Rarity=random()<.85 and 3 or 4,Mutation=1,Material=d.Material or 1,Blade=math.min(2,math.floor(random()*2)+1),Guard=2,Handle=2,Secret=false,Perfect=false,Locked=true,Displayed=false}
 table.insert(d.Inventory,w); B.mark(d,w,E.value(d,w)); d.Flags.StarterV02=true
 return w
end
function A.receipt(d,receipt,key)
 local p=C.Monetization[key]
 if not p or p.Kind~='Product' or type(receipt)~='string' then return false end
 if d.Receipts[receipt] then return true end
 if p.ResourceBoost then d.ResourceUntil=math.min(math.max(d.ResourceUntil or 0,os.time())+600,os.time()+3600) elseif p.Boost then d.LuckUntil=math.min(math.max(d.LuckUntil or 0,os.time())+C.StarterLuckSeconds,os.time()+3600) else A.credit(d,E.coinPack(d,key),true) end; d.Receipts[receipt]=true; return true
end
return A
