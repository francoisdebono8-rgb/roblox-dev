local C=require('./Config')
local B=require('./Collection')
local O={}
local E=require('./Economy')
function O.luck(d,now,event,perfect,boostPreview)
 local boosted=(d.LuckUntil or 0)>now or boostPreview
 return 1+E.properties(E.equipped(d)).Luck+d.Upgrades.Luck*C.Upgrades.Luck.Effect+math.min(.3,math.sqrt(d.Prestige)*C.PrestigeMinorBonus)+B.rewards(d).Luck+(boosted and C.StarterLuckBonus or 0)+(perfect and C.PerfectLuckBonus or 0)+(event and event.Luck or 0)
end
function O.mutations(material,event)
 local mat=C.Materials[material or 1]; local pool={}
 for _,i in ipairs(mat.Mutations) do
  local weight=C.Mutations[i].Weight
  if i==2 and material==4 then weight*=2 end
  if event and event.Mutation==i then weight*=event.Weight end
  table.insert(pool,{Index=i,Weight=weight})
 end
 return pool
end
function O.percent(list,luck)
 local total=0; local result={}
 for i,v in ipairs(list) do local n=v.Weight*(i>2 and (luck or 1) or 1); result[i]=n; total+=n end
 for i,n in ipairs(result) do result[i]=100*n/total end
 return result
end
return O
