local C = require('./Config')
local B=require('./Collection')
local E = {}
function E.cost(key, level)
 local u=C.Upgrades[key]
 return math.floor(u.Base*u.Growth^level)
end
function E.capacity(d) return C.InventoryBase+d.Upgrades.Capacity*C.Upgrades.Capacity.Effect end
function E.slots(d) return C.DisplaySlots+(d.Owned.DisplaySlots and 2 or 0)+B.rewards(d).Slots end
function E.speed(d) return math.max(C.ForgeMinimumSeconds,C.ForgeSeconds/(1+d.Upgrades.Speed*C.Upgrades.Speed.Effect+math.min(.6,math.sqrt(d.Prestige)*C.PrestigeMinorBonus))) end
function E.multiplier(d) return (1+d.Upgrades.Value*C.Upgrades.Value.Effect)*(1+math.min(1,math.sqrt(d.Prestige)*C.PrestigeBonus))*(d.Owned.DoubleCoins and 2 or 1) end
function E.value(d,w)
 return math.floor(C.Weapons[w.Blueprint].Value*C.Rarities[w.Rarity].Multiplier*C.Mutations[w.Mutation].Multiplier*C.Materials[w.Material or 1].Multiplier*(w.Perfect and (1+C.PerfectValueBonus) or 1)*(w.Secret and 1.5 or 1)*E.multiplier(d))
end
-- Two properties only. Shape choices deliberately differ from sale value.
function E.properties(w)
 if not w then return {Mining=1,Luck=0} end
 local shape=C.Weapons[w.Blueprint].Shape
 local mining=1+(w.Rarity-1)*.12+(w.Material or 1)*.05
 if shape=='Axe' or shape=='Hammer' then mining+=.65 end
 local luck=(w.Rarity-1)*.006
 if shape=='Katana' or w.Mutation==4 then luck+=.035 end
 return {Mining=math.round(mining*100)/100,Luck=math.min(.10,luck)}
end
function E.equipped(d)
 for _,w in ipairs(d.Inventory) do if w.Id==d.Equipped then return w end end
end
function E.income(d)
 local total=0
 for _,w in ipairs(d.Inventory) do if w.Displayed then total+=E.value(d,w)*C.DisplayRate*(1+d.Upgrades.Display*C.Upgrades.Display.Effect) end end
 return total
end
function E.offline(d,now) return math.floor(E.income(d)*math.clamp(now-d.LastSeen,0,C.OfflineCap)) end
function E.coinPack(d,key)
 local p=C.Monetization[key]
 local rate=C.Weapons[d.Zone*3-1].Value*C.ExpectedRarityValue*E.multiplier(d)/E.speed(d)+E.income(d)
 return math.floor(math.clamp(rate*p.Minutes*60,p.Floor,p.Cap))
end
function E.prestigeCost(d) return math.floor(C.PrestigeCost*(1+d.Prestige*.12)) end
function E.starterCoins(d) return math.clamp(math.floor(E.coinPack(d,'Small')*.25),C.StarterCoins,10000) end
function E.roll(list,random,luck)
 local sum=0
 for i,v in ipairs(list) do sum+=v.Weight*(i>2 and (luck or 1) or 1) end
 local r=random()*sum
 for i,v in ipairs(list) do r-=v.Weight*(i>2 and (luck or 1) or 1); if r<=0 then return i end end
 return #list
end
return E
