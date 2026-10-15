local C=require('./Config')
local B={}
B.Categories={{Name='Weapons',Key='Blueprint',Count=#C.Weapons},{Name='Materials',Key='Material',Count=#C.Materials},{Name='Rarities',Key='Rarity',Count=#C.Rarities},{Name='Mutations',Key='Mutation',Count=#C.Mutations,Start=2},{Name='Special variants',Key='Variant',Count=2}}
B.Paliers={{At=.1,Name='Apprentice luck +10%'},{At=.25,Name='Extra display slot'},{At=.5,Name='Collector forge skin'},{At=.75,Name='Collector title'},{At=1,Name='Master forge aura'}}
function B.progress(d)
 local found,total=0,0
 for _,category in ipairs(B.Categories) do
  for i=category.Start or 1,category.Count do total+=1; if d.Discoveries and d.Discoveries[category.Key..':'..i] then found+=1 end end
 end
 return found,total,found/total
end
function B.mark(d,w,value,now)
 d.Discoveries=d.Discoveries or {}; d.Book=d.Book or {}; d.CollectionMilestones=d.CollectionMilestones or {}
 d.Collection[tostring(w.Blueprint)]=true
 local keys={}
 for _,key in ipairs({'Blueprint','Blade','Guard','Handle','Material','Rarity','Mutation'}) do
  local v=w[key] or 1
  if key~='Mutation' or v>1 then table.insert(keys,key..':'..v) end
 end
 if w.Perfect then table.insert(keys,'Variant:1') end
 if w.Secret then table.insert(keys,'Variant:2') end
 value=value or math.floor(C.Weapons[w.Blueprint].Value*C.Rarities[w.Rarity].Multiplier*C.Mutations[w.Mutation].Multiplier*C.Materials[w.Material or 1].Multiplier)
 for _,key in ipairs(keys) do
  d.Discoveries[key]=true
  local entry=d.Book[key]
  if not entry then entry={FirstFound=now or w.FoundAt or os.time(),BestValue=0}; d.Book[key]=entry end
  if value>entry.BestValue then
   entry.BestValue=value; entry.Weapon=table.clone(w); entry.Weapon.Displayed=false; entry.Weapon.Locked=false
  end
 end
 local _,_,progress=B.progress(d)
 for i,palier in ipairs(B.Paliers) do if progress>=palier.At then d.CollectionMilestones[tostring(i)]=true end end
end
function B.rewards(d)
 local _,_,p=B.progress(d); local flags=d.CollectionMilestones or {}
 return {Luck=(flags['1'] or p>=.1) and .1 or 0,Slots=(flags['2'] or p>=.25) and 1 or 0,Skin=flags['3'] or p>=.5,Title=flags['4'] or p>=.75,Master=flags['5'] or p>=1}
end
return B
