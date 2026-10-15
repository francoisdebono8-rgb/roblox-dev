local C = require('./Config')
local E = {}
function E.cost(key, level)
 local u=C.Upgrades[key]
 return math.floor(u.Base*u.Growth^level)
end
function E.capacity(d) return C.InventoryBase+d.Upgrades.Capacity*10 end
function E.slots(d) return C.DisplaySlots+(d.Owned.DisplaySlots and 2 or 0) end
function E.speed(d) return math.max(1.6,C.ForgeSeconds/(1+d.Upgrades.Speed*0.10+d.Prestige*0.03)) end
function E.multiplier(d) return (1+d.Upgrades.Value*0.25)*(1+d.Prestige*C.PrestigeBonus)*(d.Owned.DoubleCoins and 2 or 1) end
function E.value(d,w)
 return math.floor(C.Weapons[w.Blueprint].Value*C.Rarities[w.Rarity].Multiplier*C.Mutations[w.Mutation].Multiplier*E.multiplier(d))
end
function E.income(d)
 local total=0
 for _,w in ipairs(d.Inventory) do if w.Displayed then total+=E.value(d,w)*C.DisplayRate*(1+d.Upgrades.Display*0.30) end end
 return total
end
function E.offline(d,now) return math.floor(E.income(d)*math.clamp(now-d.LastSeen,0,C.OfflineCap)) end
function E.coinPack(d,key)
 local p=C.Monetization[key]
 local rate=C.Weapons[d.Zone*3-1].Value*1.55*E.multiplier(d)/E.speed(d)+E.income(d)
 return math.floor(math.clamp(rate*p.Minutes*60,p.Floor,p.Cap))
end
function E.roll(list,random,luck)
 local sum=0
 for i,v in ipairs(list) do sum+=v.Weight*(i>2 and (luck or 1) or 1) end
 local r=random()*sum
 for i,v in ipairs(list) do r-=v.Weight*(i>2 and (luck or 1) or 1); if r<=0 then return i end end
 return #list
end
return E
