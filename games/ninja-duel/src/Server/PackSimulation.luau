-- Internal deterministic economy simulation. No purchases or profile writes.
local S=require(script.Parent.ProfileSchema)
local E=require(script.Parent.CollectionEconomy)
local RNG=require(script.Parent.ProgressionRandom)
local Definitions=require(script.Parent.ProgressionDefinitions)
local Sim={}
function Sim.run(cfg,options,yieldProfile)
 options=options or {};Definitions.validate(cfg)
 local profiles=options.profiles or 100;local packs=options.packs or 100;local seed=options.seed or 42;local packId=options.pack or "Training"
 assert(S.integer(profiles,10000) and profiles>0 and S.integer(packs,100000) and packs>0 and profiles*packs<=1000000,"Simulation budget max 1,000,000 packs")
 local pack=cfg.Packs[packId];local totalWeight=E.validatePack(cfg,pack);local random=RNG.new(seed)
 assert(pack.cost*packs<=cfg.MaxAmount and profiles*packs*pack.slots<=1000000,"Simulation currency/drop budget exceeded")
 local ids={};local dist={};for id in cfg.Characters do table.insert(ids,id);dist[id]={draws=0,unlockedProfiles=0,unlockPacksTotal=0} end;table.sort(ids)
 local milestones={1,5,10,25,50,100,packs};local history={};for _,n in milestones do if n<=packs then history[tostring(n)]=0 end end
 local duplicates,drops,ownedTotal,complete,totalCompletePacks,firstUnlocks,firstUnlockPacks,stranded=0,0,0,0,0,0,0,0
 local finalCurrencies={};for id in cfg.Currencies do finalCurrencies[id]=0 end
 for i=1,profiles do
  local p=S.new("dev_sim_"..i,cfg);p.currencies[pack.currency]=pack.cost*packs
  local at={[cfg.Starter]=0};local first=nil;local completed=nil
  for n=1,packs do
   local result=E.pack(p,cfg,packId,function() return random:next() end)
   for _,drop in result.drops do
    dist[drop.character].draws+=1;drops+=1
    if drop.duplicate then duplicates+=1 end
    if drop.unlocked then at[drop.character]=n;first=first or n end
   end
   local owned=0;for _ in p.collection do owned+=1 end
   if owned==#ids then completed=completed or n end
   if history[tostring(n)] then history[tostring(n)]+=owned end
  end
  local owned=0;for id in p.collection do owned+=1;stranded+=p.fragments[id] or 0 end;ownedTotal+=owned
  for id,n in at do dist[id].unlockedProfiles+=1;dist[id].unlockPacksTotal+=n end
  if first then firstUnlocks+=1;firstUnlockPacks+=first end
  if completed then complete+=1;totalCompletePacks+=completed end
  for id,balance in p.currencies do finalCurrencies[id]+=balance end
  if yieldProfile and i%10==0 then yieldProfile() end
 end
 for id,row in dist do
  local baseline=0;for _,e in pack.entries do if e.character==id then baseline+=e.weight/totalWeight end end
  row.baselineProbability=baseline;row.frequency=row.draws/drops;row.unlockRate=row.unlockedProfiles/profiles
  row.censoredProfiles=profiles-row.unlockedProfiles;row.averagePacksToUnlockAmongSuccesses=if row.unlockedProfiles>0 then row.unlockPacksTotal/row.unlockedProfiles else nil
  row.starter=id==cfg.Starter
 end
 for n,value in history do history[n]=value/profiles end
 for id,value in finalCurrencies do finalCurrencies[id]=value/profiles end
 local warnings={"Fixture balance only; no approved commercial economy.","Unlock-time averages exclude censored profiles; use unlockRate/censoredProfiles as well."}
 if complete<profiles then table.insert(warnings,"Incomplete collections remain at the simulation horizon.") end
 if stranded>0 then table.insert(warnings,"Owned-character fragments accumulate: a sink/crafting policy is not defined.") end
 if pack.pity or pack.guarantee then table.insert(warnings,"Guarantees/pity alter raw-weight probabilities; baselineProbability is not an effective rate.") end
 return {fixtureOnly=true,seed=seed,pack=packId,profiles=profiles,packsPerProfile=packs,openings=profiles*packs,drops=drops,distribution=dist,
  duplicateRate=duplicates/drops,averageOwned=ownedTotal/profiles,rosterSize=#ids,collectionTrajectory=history,
  completedProfiles=complete,completionRate=complete/profiles,censoredCompletionProfiles=profiles-complete,
  averagePacksToCompleteAmongSuccesses=if complete>0 then totalCompletePacks/complete else nil,
  averagePacksToFirstUnlockAmongSuccesses=if firstUnlocks>0 then firstUnlockPacks/firstUnlocks else nil,
  firstUnlockCensoredProfiles=profiles-firstUnlocks,averageCost=pack.cost*packs,averageFinalCurrencies=finalCurrencies,
  averageStrandedOwnedFragments=stranded/profiles,warnings=warnings}
end
return Sim
