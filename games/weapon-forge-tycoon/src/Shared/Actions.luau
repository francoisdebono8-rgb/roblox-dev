-- Pure authoritative transitions: no yielding, no client-supplied prices or roll results.
local C=require('./Config')
local E=require('./Economy')
local A={}
function A.credit(d,n)
 d.Coins=math.min(C.MaxCoins,d.Coins+math.max(0,math.floor(n)))
 d.Stats.Earned+=math.max(0,math.floor(n))
end
function A.find(d,id) for i,w in ipairs(d.Inventory) do if w.Id==id then return w,i end end end
function A.forge(d,now,random,id)
 if d.Craft or #d.Inventory>=E.capacity(d) then return false,'Your inventory is full or the forge is busy.' end
 d.Craft={Started=now,Ready=now+E.speed(d),Hits=0,LastHit=now-1,Id=id}
 return true
end
function A.hammer(d,now)
 local c=d.Craft
 if not c or c.Hits>=3 or now-c.LastHit<0.45 then return false,'Wait for the next hammer strike.' end
 c.Hits+=1; c.LastHit=now; c.Ready=math.max(now,c.Ready-C.HammerReduction)
 return true
end
function A.finish(d,now,random)
 local c=d.Craft
 if not c or now<c.Ready then return nil end
 d.Craft=nil
 local luck=1+d.Upgrades.Luck*0.18+d.Prestige*0.03+(d.LuckUntil>os.time() and 0.5 or 0)
 local w={Id=c.Id,Blueprint=(d.Zone-1)*3+math.min(3,math.floor(random()*3)+1),Rarity=E.roll(C.Rarities,random,luck),Mutation=E.roll(C.Mutations,random),Locked=false,Displayed=false}
 if d.Stats.Forged==0 then w.Blueprint=2 end -- first sale always funds the 20-coin speed upgrade
 table.insert(d.Inventory,w); d.Collection[tostring(w.Blueprint)]=true; d.Stats.Forged+=1
 if d.Tutorial==0 then d.Tutorial=1 elseif d.Tutorial==3 then d.Tutorial=4 end
 return w
end
function A.sell(d,id)
 local w,i=A.find(d,id)
 if not w or w.Locked or w.Displayed then return false,'Only unlocked, stored weapons can be sold.' end
 local value=E.value(d,w); table.remove(d.Inventory,i); A.credit(d,value); d.Stats.Sold+=1
 if d.Tutorial==1 then d.Tutorial=2 end
 return true,value
end
function A.display(d,id)
 local w=A.find(d,id); if not w then return false,'Weapon no longer exists.' end
 if w.Displayed then w.Displayed=false; return true end
 local count=0; for _,v in ipairs(d.Inventory) do if v.Displayed then count+=1 end end
 if count>=E.slots(d) then return false,'All rack slots are occupied. Store a displayed weapon first.' end
 w.Displayed=true; return true
end
function A.lock(d,id) local w=A.find(d,id); if not w then return false,'Weapon no longer exists.' end; w.Locked=not w.Locked; return true end
function A.mergePreview(d,threshold)
 for rarity=1,math.min(threshold or 5,5) do
  local ids={}
  for _,w in ipairs(d.Inventory) do if w.Rarity==rarity and not w.Displayed and not w.Locked then table.insert(ids,w.Id); if #ids==3 then return ids,rarity+1 end end end
 end
 return nil
end
function A.merge(d,ids,id)
 if type(ids)~='table' or #ids~=3 then return false,'Choose three weapons.' end
 local items,seen={},{}
 for _,key in ipairs(ids) do
  if type(key)~='string' or seen[key] then return false,'Invalid merge.' end
  seen[key]=true; local w=A.find(d,key)
  if not w or w.Locked or w.Displayed or w.Rarity>=6 then return false,'Merge contents changed. Review again.' end
  table.insert(items,w)
 end
 if items[1].Rarity~=items[2].Rarity or items[1].Rarity~=items[3].Rarity then return false,'Rarities must match.' end
 -- The first preview weapon supplies silhouette and mutation; explicitly shown in UI.
 local result={Id=id,Blueprint=items[1].Blueprint,Rarity=items[1].Rarity+1,Mutation=items[1].Mutation,Locked=false,Displayed=false}
 for i=#d.Inventory,1,-1 do if seen[d.Inventory[i].Id] then table.remove(d.Inventory,i) end end
 table.insert(d.Inventory,result); d.Stats.Merged+=1
 return true,result
end
function A.upgrade(d,key)
 local u=C.Upgrades[key]; if not u then return false,'Unknown upgrade.' end
 local level=d.Upgrades[key]; if level>=u.Max then return false,'Maximum level reached.' end
 local cost=E.cost(key,level); if d.Coins<cost then return false,'Earn more coins first.' end
 d.Coins-=cost; d.Upgrades[key]+=1
 if d.Tutorial==2 then d.Tutorial=3 end
 return true
end
function A.zone(d)
 if d.Zone>=3 then return false,'All forges unlocked.' end
 local cost=C.Zones[d.Zone+1].Cost; if d.Coins<cost then return false,'Earn more coins to unlock the next forge.' end
 if d.Craft then return false,'Finish forging first.' end
 d.Coins-=cost; d.Zone+=1; return true
end
function A.prestige(d)
 if d.Zone~=3 or d.Coins<C.PrestigeCost or d.Craft then return false,'Unlock Arcane Forge and hold 150,000 coins. Finish forging first.' end
 d.Coins=0; d.Zone=1; d.Inventory={}; d.Prestige+=1
 for k in pairs(d.Upgrades) do d.Upgrades[k]=0 end
 return true
end
function A.pass(d,key,now)
 local p=C.Monetization[key]
 if not p or p.Kind~='Pass' then return false end
 if d.Owned[key] then return true end
 d.Owned[key]=true
 if key=='Starter' then A.credit(d,500); d.LuckUntil=now+600 end
 return true
end
function A.receipt(d,receipt,key)
 local p=C.Monetization[key]
 if not p or p.Kind~='Product' or type(receipt)~='string' then return false end
 if d.Receipts[receipt] then return true end
 A.credit(d,E.coinPack(d,key)); d.Receipts[receipt]=true; return true
end
return A
