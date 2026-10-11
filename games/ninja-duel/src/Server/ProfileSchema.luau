-- JSON-safe versioned profile. Never silently repairs corrupt/future saves.
local S={}
function S.copy(v)
 if type(v)~="table" then return v end
 local out={};for k,item in v do out[k]=S.copy(item) end;return out
end
function S.integer(n,max) return type(n)=="number" and n==n and n>=0 and n%1==0 and n<=(max or 1000000000) end
function S.id(v) return type(v)=="string" and #v>0 and #v<=64 and v:match("^[%w_.:%-]+$")~=nil end
function S.devId(v) return S.id(v) and #v<=32 and v:match("^dev_[%w_%-]+$")~=nil end
function S.character()
 return {xp=0,claimed={},variants={},techniques={},awakenings={},cosmetics={},stats={matches=0,wins=0,losses=0,xpEarned=0}}
end
function S.new(id,cfg)
 assert(S.devId(id),"Development profile ID must start dev_")
 local currencies={};for name,spec in cfg.Currencies do currencies[name]=spec.initial or 0 end
 return {schemaVersion=cfg.SchemaVersion,id=id,starter=cfg.Starter,selected=cfg.Starter,
  collection={[cfg.Starter]=true},characters={[cfg.Starter]=S.character()},fragments={},currencies=currencies,pity={},
  commandSequence=0,rewardStreams={},stats={packs=0,drops=0,duplicates=0,matches=0},lastCommand=nil}
end
local function map(t,valueCheck,limit)
 if type(t)~="table" then return false end;local n=0
 for k,v in t do n+=1;if n>(limit or 256) or not S.id(k) or not valueCheck(v) then return false end end
 return true
end
local function flags(t) return map(t,function(v) return v==true end,1024) end
local function statistics(t,required,cfg)
 if not map(t,function(n) return S.integer(n,cfg.MaxAmount) end) then return false end
 for _,key in required do if not S.integer(t[key],cfg.MaxAmount) then return false end end
 return true
end
function S.serializable(value)
 local seen={};local nodes=0;local bytes=0
 local function walk(v,depth)
  nodes+=1;if nodes>20000 or depth>16 then return false end
  if type(v)=="number" then return v==v and math.abs(v)<math.huge
  elseif type(v)=="boolean" or v==nil then return true
  elseif type(v)=="string" then bytes+=#v;return #v<=2048 and bytes<1000000
  elseif type(v)=="table" then
   if seen[v] then return false end;seen[v]=true
   local numeric=false;local text=false;local count=0
   for k,item in v do
    count+=1;if type(k)=="number" then numeric=true;if not S.integer(k,20000) or k<1 then return false end
    elseif type(k)=="string" then text=true else return false end
    if not walk(k,depth+1) or not walk(item,depth+1) then return false end
   end
   if numeric and (text or count~=#v) then return false end
   seen[v]=nil;return true
  end
  return false
 end
 return walk(value,0)
end
function S.validate(p,cfg)
 if not S.serializable(p) then return false,"Unsafe serialized data" end
 if type(p)~="table" or p.schemaVersion~=cfg.SchemaVersion or not S.devId(p.id) or not S.id(p.starter) or not S.id(p.selected) then return false,"Profile header/version" end
 if not flags(p.collection) or not p.collection[p.selected] or next(p.collection)==nil then return false,"Collection/selection" end
 if not map(p.currencies,function(n) return S.integer(n,cfg.MaxAmount) end) or not map(p.fragments,function(n) return S.integer(n,cfg.MaxAmount) end) then return false,"Balances/fragments" end
 for id in cfg.Currencies do if p.currencies[id]==nil then return false,"Missing currency" end end
 if not map(p.pity,function(n) return S.integer(n,cfg.MaxAmount) end) or not map(p.rewardStreams,function(n) return S.integer(n,cfg.MaxAmount) end,64) then return false,"Counters" end
 if not S.integer(p.commandSequence,cfg.MaxAmount) or not statistics(p.stats,{"packs","drops","duplicates","matches"},cfg) then return false,"Statistics" end
 if not map(p.characters,function(ch)
  return type(ch)=="table" and S.integer(ch.xp,cfg.MaxAmount) and flags(ch.claimed) and flags(ch.variants) and flags(ch.techniques) and flags(ch.awakenings) and flags(ch.cosmetics)
   and statistics(ch.stats,{"matches","wins","losses","xpEarned"},cfg)
 end) then return false,"Character progression" end
 for id in p.collection do if not p.characters[id] then return false,"Owned character missing record" end end
 if p.lastCommand~=nil then
  local last=p.lastCommand
  if type(last)~="table" or not S.integer(last.sequence,cfg.MaxAmount) or last.sequence~=p.commandSequence or not S.id(last.kind) then return false,"Command ledger" end
 end
 return true
end
-- v1: characterXP map instead of full character mastery records.
function S.migrate(raw,cfg)
 if not S.serializable(raw) or type(raw)~="table" or not S.integer(raw.schemaVersion,cfg.SchemaVersion) then return nil,"Unknown/future schema" end
 local p=S.copy(raw)
 if p.schemaVersion==1 then
  p.characters=p.characters or {}
  if type(p.characterXP)~="table" or type(p.collection)~="table" or type(p.characters)~="table" or type(p.currencies)~="table" then return nil,"Invalid v1 save" end
  for id,xp in p.characterXP do
   if not S.integer(xp,cfg.MaxAmount) then return nil,"Invalid legacy XP" end
   local ch=S.character();ch.xp=xp;ch.stats.xpEarned=xp;p.characters[id]=ch
  end
  for id in p.collection do p.characters[id]=p.characters[id] or S.character() end
  p.characterXP=nil;p.rewardStreams=p.rewardStreams or {};p.commandSequence=p.commandSequence or 0;p.stats=p.stats or {packs=0,drops=0,duplicates=0,matches=0};p.pity=p.pity or {}
  for id,spec in cfg.Currencies do if p.currencies[id]==nil then p.currencies[id]=spec.initial end end
  p.schemaVersion=2
 end
 local ok,reason=S.validate(p,cfg);if not ok then return nil,reason end
 return p
end
return S
