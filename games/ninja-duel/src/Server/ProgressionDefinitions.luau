-- Validate optional configuration before any profile is created or simulated.
local S=require(script.Parent.ProfileSchema)
local Economy=require(script.Parent.CollectionEconomy)
local D={}
function D.validate(cfg)
 assert(cfg.SchemaVersion==2 and cfg.Characters[cfg.Starter],"Unknown schema / starter")
 assert(S.integer(cfg.MaxAmount,1000000000000) and cfg.MaxAmount>0 and S.integer(cfg.MaxLevel,10000) and cfg.MaxLevel>0 and S.integer(cfg.XPPerLevel,cfg.MaxAmount) and cfg.XPPerLevel>0,"Invalid progression limits")
 assert(S.integer(cfg.LeaseSeconds,3600) and cfg.LeaseSeconds>=30 and S.integer(cfg.SaveInterval,3600) and cfg.SaveInterval>0 and cfg.SaveInterval<cfg.LeaseSeconds/2 and S.integer(cfg.MaxRetries,5) and cfg.MaxRetries>0,"Invalid save cadence")
 local regions=0
 for id,enabled in cfg.Regions do regions+=1;assert(regions<=32 and S.id(id) and enabled==true,"Invalid region") end
 assert(regions>0,"Regions required")
 local tiers={};local rarityCount=0
 for id,tier in cfg.Rarities do
  rarityCount+=1;assert(rarityCount<=32 and S.id(id) and S.integer(tier,32) and tier>0 and not tiers[tier],"Invalid rarity tier");tiers[tier]=true
 end
 assert(rarityCount>0,"Rarities required")
 local ranks={};local previous=-1
 for _,rank in cfg.Ranks do assert(S.id(rank.id) and not ranks[rank.id] and S.integer(rank.xp,cfg.MaxAmount) and rank.xp>previous,"Invalid ranks");ranks[rank.id]=true;previous=rank.xp end
 assert(#cfg.Ranks>0 and cfg.Ranks[1].xp==0,"Initial rank required")
 local currencies=0
 for id,c in cfg.Currencies do currencies+=1;assert(currencies<=16 and S.id(id) and type(c.premium)=="boolean" and S.integer(c.initial,cfg.MaxAmount),"Invalid currency") end
 local count=0
 for id,ch in cfg.Characters do
  count+=1;assert(count<=256 and S.id(id) and S.integer(ch.unlockFragments,cfg.MaxAmount) and ch.unlockFragments>0 and cfg.Rarities[ch.rarity],"Invalid character")
  local stats=0
  for name,t in ch.stats do stats+=1;assert(stats<=32 and S.id(name) and type(t.base)=="number" and type(t.growth)=="number" and type(t.cap)=="number" and t.base>=0 and t.base<1e9 and t.growth>=0 and t.growth<1e9 and t.cap>=t.base and t.cap<1e9,"Invalid identity stat cap") end
  local rewards={}
  for _,reward in ch.rewards do
   assert(S.id(reward.id) and not rewards[reward.id] and ranks[reward.rank],"Invalid mastery reward");rewards[reward.id]=true
   for _,g in reward.grants do
    assert(S.id(g.id),"Invalid grant ID")
    if g.kind=="currency" then assert(cfg.Currencies[g.id] and S.integer(g.amount,cfg.MaxAmount),"Invalid currency reward")
    else assert(({variant=true,technique=true,awakening=true,cosmetic=true})[g.kind],"Invalid mastery reward kind") end
   end
  end
 end
 for id,pack in cfg.Packs do assert(S.id(id),"Invalid pack ID");Economy.validatePack(cfg,pack) end
 return true
end
return D
