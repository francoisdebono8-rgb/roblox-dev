local S=require(script.Parent.ProfileSchema)
local P={}
function P.rank(cfg,xp)
 local rank=cfg.Ranks[1];for _,r in cfg.Ranks do if xp>=r.xp then rank=r end end;return rank.id
end
function P.level(cfg,xp) return math.min(cfg.MaxLevel,1+math.floor(xp/cfg.XPPerLevel)) end
function P.project(cfg,id,ch,normalized)
 local def=cfg.Characters[id];assert(def,"Unknown character")
 local out={level=P.level(cfg,ch.xp),rank=P.rank(cfg,ch.xp),stats={},applicationEnabled=false}
 for name,tune in def.stats do
  out.stats[name]=if normalized then tune.base else math.min(tune.cap,tune.base+tune.growth*(out.level-1))
 end
 return out -- data preview ONLY; never written into Fighters/Combat actors.
end
function P.xp(profile,cfg,id,amount)
 assert(profile.collection[id] and cfg.Characters[id],"Character not owned")
 assert(S.integer(amount,cfg.MaxAmount),"Invalid XP")
 local ch=profile.characters[id];assert(ch.xp+amount<=cfg.MaxAmount and ch.stats.xpEarned+amount<=cfg.MaxAmount,"XP cap")
 ch.xp+=amount;ch.stats.xpEarned+=amount;return P.project(cfg,id,ch,false)
end
function P.setRank(profile,cfg,id,rank)
 assert(profile.collection[id],"Character not owned")
 for _,r in cfg.Ranks do if r.id==rank then profile.characters[id].xp=r.xp;return P.project(cfg,id,profile.characters[id],false) end end
 error("Unknown rank")
end
function P.claim(profile,cfg,id,rewardId)
 assert(profile.collection[id] and cfg.Characters[id],"Character not owned")
 local ch=profile.characters[id];local reward
 for _,r in cfg.Characters[id].rewards do if r.id==rewardId then reward=r end end
 assert(reward,"Unknown mastery reward")
 if ch.claimed[rewardId] then return {alreadyClaimed=true} end
 local required;for _,rank in cfg.Ranks do if rank.id==reward.rank then required=rank.xp end end
 assert(required and ch.xp>=required,"Mastery rank not reached")
 -- Caller applies this inside a transaction; partial grants never escape it.
 for _,grant in reward.grants do
  if grant.kind=="currency" then
   assert(cfg.Currencies[grant.id] and S.integer(grant.amount,cfg.MaxAmount),"Invalid reward currency")
   assert(profile.currencies[grant.id]+grant.amount<=cfg.MaxAmount,"Currency cap");profile.currencies[grant.id]+=grant.amount
  else
   local field=({variant="variants",technique="techniques",awakening="awakenings",cosmetic="cosmetics"})[grant.kind]
   assert(field and S.id(grant.id),"Unknown reward kind");ch[field][grant.id]=true
  end
 end
 ch.claimed[rewardId]=true;return {reward=rewardId}
end
return P
