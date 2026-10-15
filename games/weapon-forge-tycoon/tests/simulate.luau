local C=require('../src/Shared/Config')
local E=require('../src/Shared/Economy')
local P=require('../src/Shared/Profile')
local A=require('../src/Shared/Actions')
-- Active free player: three hammer taps, display first four above-common items,
-- sell subsequent output, reserve some funds for the next zone, buy useful upgrades.
for seed=1,5 do
 math.randomseed(seed)
 local d=P.new(os.time()); local t=0; local zone2,zone3,prestige
 local checkpoints={600,1800,3600,10800,36000}; local checkpoint=1
 while t<36000 do
  local material=d.Zone==1 and 1 or d.Zone==2 and 4 or 5
  d.Material=material
  local travel=0
  if (d.Materials[C.Materials[material].Name] or 0)<1 then assert(A.collect(d,material,os.time())); travel=14+d.Zone*2 end
  local dt=E.speed(d)+4+travel -- menu decision / walking allowance
  t+=dt; A.credit(d,E.income(d)*dt)
  local before=d.Stats.Forged
  assert(A.forge(d,t-dt,math.random,'w'..before))
  local c=d.Craft; for hit=0,2 do assert(A.hammer(d,c.HeatEnd+c.Duration*.58/3*(hit+.5))) end
  local w=A.finish(d,t+2,math.random); assert(w)
  local displayed=0; for _,item in ipairs(d.Inventory) do if item.Displayed then displayed+=1 end end
  if displayed<4 and w.Rarity>=2 then A.display(d,w.Id) else A.sell(d,w.Id) end
  if d.Zone<3 and d.Coins>=C.Zones[d.Zone+1].Cost then A.zone(d); if d.Zone==2 then zone2=zone2 or t else zone3=zone3 or t end end
  if d.Zone==3 and d.Coins>=E.prestigeCost(d) then if not prestige then prestige=t end; A.prestige(d) end
  for _,key in ipairs({'Speed','Value','Luck','Display'}) do
   local cost=E.cost(key,d.Upgrades[key]); local budget=(key=='Speed' or key=='Value') and 0.25 or 0.08
   if cost<d.Coins*budget then A.upgrade(d,key) end
  end
  if checkpoints[checkpoint] and t>=checkpoints[checkpoint] then
   print(string.format('seed %d | %dm | coins %d | zone %d | forged %d | prestige %d',seed,checkpoints[checkpoint]/60,d.Coins,d.Zone,d.Stats.Forged,d.Prestige)); checkpoint+=1
  end
 end
 assert(d.Prestige>=2,'Long run must continue beyond the first prestige')
 print(string.format('seed %d MILESTONES zone2=%.1fm zone3=%.1fm prestige=%.1fm',seed,(zone2 or 0)/60,(zone3 or 0)/60,(prestige or 0)/60))
end
