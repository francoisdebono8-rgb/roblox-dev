-- Server-owned collection/inventory operations; no marketplace or receipts.
local S=require(script.Parent.ProfileSchema)
local Progression=require(script.Parent.CharacterProgression)
local E={}
function E.currency(profile,cfg,id,amount)
 assert(cfg.Currencies[id] and type(amount)=="number" and amount%1==0 and math.abs(amount)<=cfg.MaxAmount,"Invalid currency delta")
 local value=profile.currencies[id]+amount;assert(S.integer(value,cfg.MaxAmount),"Insufficient currency / cap")
 profile.currencies[id]=value;return value
end
function E.unlock(profile,cfg,id)
 assert(cfg.Characters[id],"Unknown character")
 local owned=profile.collection[id]==true;profile.collection[id]=true;profile.characters[id]=profile.characters[id] or S.character()
 return {character=id,alreadyOwned=owned}
end
function E.revoke(profile,cfg,id)
 assert(cfg.Characters[id] and profile.collection[id],"Not owned")
 local fallback;local ids={};for name in profile.collection do if name~=id then table.insert(ids,name) end end;table.sort(ids);fallback=ids[1]
 assert(fallback,"Cannot remove final character")
 profile.collection[id]=nil;if profile.selected==id then profile.selected=fallback end
 return {removed=id} -- preserve mastery/cosmetics for future reacquisition.
end
function E.fragments(profile,cfg,id,n)
 local def=cfg.Characters[id];assert(def and S.integer(n,cfg.MaxAmount),"Invalid fragments")
 local value=(profile.fragments[id] or 0)+n;assert(value<=cfg.MaxAmount,"Fragment cap")
 local unlocked=false
 if not profile.collection[id] and value>=def.unlockFragments then value-=def.unlockFragments;E.unlock(profile,cfg,id);unlocked=true end
 profile.fragments[id]=value;return {unlocked=unlocked,character=id,remaining=value}
end
local function rng(nextNumber)
 local n=nextNumber();assert(type(n)=="number" and n==n and n>=0 and n<1,"RNG must be in [0,1)");return n
end
function E.validatePack(cfg,pack)
 assert(pack and cfg.Currencies[pack.currency] and S.integer(pack.cost,cfg.MaxAmount) and S.integer(pack.slots,20) and pack.slots>0,"Invalid pack cost/slots")
 assert(type(pack.entries)=="table" and #pack.entries>0 and #pack.entries<=256,"Invalid pack entries")
 local total=0
 for _,row in pack.entries do
  assert(cfg.Characters[row.character] and cfg.Rarities[row.rarity] and type(row.weight)=="number" and row.weight>0 and row.weight<1e9 and S.integer(row.fragments,cfg.MaxAmount) and row.fragments>0,"Invalid drop")
  total+=row.weight
 end
 local function eligible(rule)
  assert(rule and cfg.Rarities[rule.minRarity],"Unknown guarantee rarity")
  for _,row in pack.entries do if cfg.Rarities[row.rarity]>=cfg.Rarities[rule.minRarity] then return end end
  error("Impossible guarantee")
 end
 if pack.guarantee then eligible(pack.guarantee) end
 if pack.pity then assert(S.integer(pack.pity.after,10000) and pack.pity.after>0,"Invalid pity");eligible(pack.pity) end
 local dup=pack.duplicate
 assert(dup and (dup.mode=="fragments" or dup.mode=="currency") and S.integer(dup.amount,cfg.MaxAmount),"Invalid duplicate policy")
 if dup.mode=="currency" then assert(cfg.Currencies[dup.currency],"Unknown duplicate currency") end
 return total
end
local function draw(cfg,pack,nextNumber,minRarity)
 local pool={};local total=0
 for _,row in pack.entries do if not minRarity or cfg.Rarities[row.rarity]>=cfg.Rarities[minRarity] then table.insert(pool,row);total+=row.weight end end
 assert(total>0,"Empty draw pool")
 local roll=rng(nextNumber)*total;local at=0
 for _,row in pool do at+=row.weight;if roll<at then return row end end
 return pool[#pool]
end
function E.pack(profile,cfg,id,nextNumber)
 local pack=cfg.Packs[id];E.validatePack(cfg,pack)
 E.currency(profile,cfg,pack.currency,-pack.cost)
 local minimum=pack.guarantee and pack.guarantee.minRarity
 local misses=profile.pity[id] or 0;local forced=pack.pity and misses+1>=pack.pity.after
 if forced and (not minimum or cfg.Rarities[pack.pity.minRarity]>cfg.Rarities[minimum]) then minimum=pack.pity.minRarity end
 local qualified=false;local drops={}
 for slot=1,pack.slots do
  local row=draw(cfg,pack,nextNumber,if slot==pack.slots then minimum else nil)
  if pack.pity and cfg.Rarities[row.rarity]>=cfg.Rarities[pack.pity.minRarity] then qualified=true end
  local duplicate=profile.collection[row.character]==true;local result
  if duplicate and pack.duplicate.mode=="currency" then E.currency(profile,cfg,pack.duplicate.currency,pack.duplicate.amount);result={unlocked=false}
  else result=E.fragments(profile,cfg,row.character,if duplicate then pack.duplicate.amount else row.fragments) end
  table.insert(drops,{character=row.character,rarity=row.rarity,duplicate=duplicate,fragments=if duplicate and pack.duplicate.mode=="currency" then 0 else (if duplicate then pack.duplicate.amount else row.fragments),unlocked=result.unlocked})
  profile.stats.drops+=1;if duplicate then profile.stats.duplicates+=1 end
 end
 profile.pity[id]=if qualified or not pack.pity then 0 else misses+1
 profile.stats.packs+=1
 return {pack=id,drops=drops,pityForced=forced==true,cost=pack.cost}
end
-- Monotonic reward stream prevents re-grants without an evicting receipt cache.
function E.reward(profile,cfg,stream,sequence,grants)
 assert(S.id(stream) and S.integer(sequence,cfg.MaxAmount) and sequence>0,"Invalid reward sequence")
 local previous=profile.rewardStreams[stream] or 0
 if sequence<=previous then return {alreadyApplied=true} end
 assert(sequence==previous+1,"Reward stream gap")
 for _,g in grants do
  if g.kind=="currency" then assert(S.integer(g.amount,cfg.MaxAmount));E.currency(profile,cfg,g.id,g.amount)
  elseif g.kind=="fragments" then E.fragments(profile,cfg,g.id,g.amount)
  elseif g.kind=="character" then E.unlock(profile,cfg,g.id)
  else error("Unknown grant") end
 end
 profile.rewardStreams[stream]=sequence;return {applied=true}
end
-- Pure copy/validate/commit operation. RNG is evaluated once here, never in a
-- DataStore transform. Caller owns and persists the returned profile atomically.
function E.apply(profile,cfg,sequence,kind,args,nextNumber)
 assert(S.integer(sequence,cfg.MaxAmount) and sequence>0,"Invalid command sequence")
 if sequence==profile.commandSequence and profile.lastCommand and profile.lastCommand.kind==kind then return S.copy(profile),S.copy(profile.lastCommand.result),true end
 assert(sequence==profile.commandSequence+1,"Stale/gapped command")
 local p=S.copy(profile);local result
 if kind=="unlock" then result=E.unlock(p,cfg,args.character)
 elseif kind=="revoke" then result=E.revoke(p,cfg,args.character)
 elseif kind=="currency" then result={balance=E.currency(p,cfg,args.currency,args.amount)}
 elseif kind=="xp" then result=Progression.xp(p,cfg,args.character,args.amount)
 elseif kind=="rank" then result=Progression.setRank(p,cfg,args.character,args.rank)
 elseif kind=="mastery" then result=Progression.claim(p,cfg,args.character,args.reward)
 elseif kind=="pack" then result=E.pack(p,cfg,args.pack,nextNumber)
 elseif kind=="reward" then result=E.reward(p,cfg,args.stream,args.rewardSequence,args.grants)
 elseif kind=="matchResult" then
  assert(type(args.won)=="boolean","Invalid result")
  result=Progression.xp(p,cfg,args.character,args.xp)
  local stats=p.characters[args.character].stats;stats.matches+=1
  if args.won then stats.wins+=1 else stats.losses+=1 end
  p.stats.matches+=1
 elseif kind=="select" then assert(p.collection[args.character] and cfg.Characters[args.character],"Character locked");p.selected=args.character;result={selected=p.selected}
 else error("Unknown operation") end
 p.commandSequence=sequence;p.lastCommand={sequence=sequence,kind=kind,result=S.copy(result)}
 local valid,reason=S.validate(p,cfg);assert(valid,reason);return p,result,false
end
return E
