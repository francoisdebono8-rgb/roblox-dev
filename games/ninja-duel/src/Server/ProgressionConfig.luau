-- Development fixture only: no approved progression/economy balance.
-- No bootstrap imports this module. Combat never reads these values.
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local C={Enabled=false,CombatEffectsEnabled=false,MonetizationEnabled=false,DevDataStoreEnabled=false,
 SchemaVersion=2,Starter="Flashstep",MaxLevel=50,XPPerLevel=100,MaxAmount=1000000000,
 LeaseSeconds=120,SaveInterval=30,MaxRetries=3,StoreName="NinjaDuel_DEV_Progression",StoreScope="development_v1",
 Currencies={Coins={premium=false,initial=0},Premium={premium=true,initial=0},MasteryTokens={premium=false,initial=0}},
 Rarities={Common=1,Rare=2,Epic=3,Legendary=4},Regions={EU=true,NA=true,AS=true},Characters={},
 Ranks={{id="Novice",xp=0},{id="Adept",xp=500},{id="Expert",xp=1500},{id="Master",xp=3000}},Packs={}}
-- Deliberately modest sample caps retain the speed bands of active identities.
local sample={Flashstep={growth=.08,cap=21},Mirage={growth=.03,cap=18.6},GentleFist={growth=.025,cap=18},Lion={growth=.03,cap=19},Sand={growth=.02,cap=16}}
for id,f in Fighters do
 local speed=sample[id] or {growth=0,cap=f.Speed}
 C.Characters[id]={name=f.Name,rarity=if id=="Flashstep" then "Legendary" elseif id=="Mirage" then "Epic" elseif id=="Sand" then "Common" else "Rare",
  unlockFragments=50,stats={Speed={base=f.Speed,growth=speed.growth,cap=math.max(f.Speed,speed.cap)},Health={base=f.Health,growth=0,cap=f.Health}},
  rewards={{id=id..":adept",rank="Adept",grants={{kind="variant",id=id..":optional-route"}}},
   {id=id..":expert",rank="Expert",grants={{kind="awakening",id=id..":awakening-option"}}},
   {id=id..":master",rank="Master",grants={{kind="cosmetic",id=id..":mastery-aura"},{kind="currency",id="MasteryTokens",amount=10}}}}}
end
local entries={};local ids={};for id in C.Characters do table.insert(ids,id) end;table.sort(ids)
for _,id in ids do local ch=C.Characters[id];table.insert(entries,{character=id,rarity=ch.rarity,weight=if ch.rarity=="Legendary" then 5 elseif ch.rarity=="Epic" then 15 elseif ch.rarity=="Rare" then 25 else 30,fragments=10}) end
C.Packs.Training={currency="Coins",cost=100,slots=1,entries=entries,duplicate={mode="fragments",amount=10},pity={after=20,minRarity="Epic"}}
return C
