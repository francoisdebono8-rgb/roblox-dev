-- Fighter progression profile (PROG-001). Per fighter: the skill points earned,
-- the nodes unlocked with them and the saved builds (one may be selected).
-- Versioned and JSON-safe, validated on every load and every commit, never
-- repaired silently. Points are granted by the server only: no currency, no
-- purchase. Serialization limits, the command ledger and the refusal to repair
-- come from Codex's foundation (29a9ec1), without its pack/collection economy.
-- Version 2 (DEC-037, 12/11): the kits a player has learned on the masters'
-- path (Shared/Masters): owned, the starter, the selected kit, the mastery per
-- kit, and the purchase receipts already granted (a kit bought is pay for
-- time; skill points still never come from a purchase).
local SkillBuilds=require(script.Parent.SkillBuilds)
local Masters=require(game:GetService("ReplicatedStorage").NinjaDuel.Masters)
local S={Version=2,MaxPoints=999,MaxBuilds=8,MaxSequence=1000000000,MaxReceipts=50}
S.copy=SkillBuilds.copy
function S.integer(n,max)
	return type(n)=="number" and n==n and n>=0 and n%1==0 and n<=(max or S.MaxSequence)
end
function S.id(v)
	return type(v)=="string" and #v>0 and #v<=64 and string.match(v,"^[%w_.:%-]+$")~=nil
end
-- Live players are u_<UserId>; tooling and tests use dev_<name>.
function S.profileId(v)
	return type(v)=="string" and #v<=40 and (string.match(v,"^u_%d+$")~=nil or string.match(v,"^dev_[%w_%-]+$")~=nil)
end
function S.buildName(v)
	return type(v)=="string" and #v>=1 and #v<=24 and string.match(v,"^[%w _%-]+$")~=nil
end
-- Bounded JSON-safe data: finite numbers, short strings, no cycles, arrays
-- without holes, string or array keys only.
function S.serializable(value)
	local seen,nodes,bytes={},0,0
	local function walk(v,depth)
		nodes+=1
		if nodes>20000 or depth>16 then return false end
		if type(v)=="number" then return v==v and math.abs(v)<math.huge end
		if type(v)=="boolean" or v==nil then return true end
		if type(v)=="string" then bytes+=#v;return #v<=2048 and bytes<1000000 end
		if type(v)~="table" or seen[v] then return false end
		seen[v]=true
		local numeric,text,count=false,false,0
		for k,item in v do
			count+=1
			if type(k)=="number" then numeric=true;if not S.integer(k,20000) or k<1 then return false end
			elseif type(k)=="string" then text=true else return false end
			if not walk(k,depth+1) or not walk(item,depth+1) then return false end
		end
		if numeric and (text or count~=#v) then return false end
		seen[v]=nil
		return true
	end
	return walk(value,0)
end
function S.new(id)
	assert(S.profileId(id),"Profile id must be u_<UserId> or dev_<name>")
	return {schemaVersion=S.Version,id=id,fighters={},sequence=0,kits=S.kits()}
end
function S.kits() return {owned={},mastery={},receipts={}} end
function S.fighter() return {earned=0,unlocked={},builds={}} end
-- Skill points spent on unlocks (derived, never stored).
function S.spent(fighterId,record)
	local total=0
	for id in record.unlocked do
		local node=SkillBuilds.node(fighterId,id)
		total+=if node then node.Cost else 0
	end
	return total
end
local function unlockReady(fighterId,node,unlocked)
	for _,need in node.Requires or {} do if not unlocked[need] then return false,node.Id.." requires "..need end end
	if node.RequiresAny then
		for _,need in node.RequiresAny do if unlocked[need] then return true end end
		return false,node.Id.." requires one of "..table.concat(node.RequiresAny,", ")
	end
	return true
end
local function fighterValid(fighterId,record)
	if type(record)~="table" or not S.integer(record.earned,S.MaxPoints) then return false,"points" end
	if type(record.unlocked)~="table" or type(record.builds)~="table" then return false,"record" end
	for id,flag in record.unlocked do
		local node=SkillBuilds.node(fighterId,id)
		if flag~=true or not node then return false,"unknown unlocked node "..tostring(id) end
		local ok,reason=unlockReady(fighterId,node,record.unlocked)
		if not ok then return false,reason end
	end
	if S.spent(fighterId,record)>record.earned then return false,"more points spent than earned" end
	local count=0
	for name,build in record.builds do
		count+=1
		if count>S.MaxBuilds or not S.buildName(name) or type(build)~="table" or type(build.nodes)~="table" then return false,"builds" end
		local ok,reason=SkillBuilds.validate(fighterId,build.nodes,{unlocked=record.unlocked})
		if not ok then return false,"build "..name..": "..reason end
	end
	if record.selected~=nil and record.builds[record.selected]==nil then return false,"selected build missing" end
	return true
end
local function kitsValid(k)
	if type(k)~="table" or type(k.owned)~="table" or type(k.mastery)~="table" or type(k.receipts)~="table" then return false,"kits record" end
	for id,flag in k.owned do if flag~=true or not Masters.isKit(id) then return false,"unknown owned kit "..tostring(id) end end
	for id,m in k.mastery do if not Masters.isKit(id) or not S.integer(m,Masters.MaxMastery) then return false,"mastery "..tostring(id) end end
	if k.starter~=nil and not (Masters.isStarter(k.starter) and k.owned[k.starter]) then return false,"starter" end
	if k.selected~=nil and not k.owned[k.selected] then return false,"selected kit not owned" end
	if #k.receipts>S.MaxReceipts then return false,"receipts" end
	for i,r in k.receipts do if type(i)~="number" or not S.id(r) then return false,"receipt" end end
	return true
end
function S.validate(p)
	if not S.serializable(p) then return false,"Unsafe serialized data" end
	if type(p)~="table" or p.schemaVersion~=S.Version or not S.profileId(p.id) or not S.integer(p.sequence) or type(p.fighters)~="table" then return false,"Profile header/version" end
	local okKits,whyKits=kitsValid(p.kits)
	if not okKits then return false,"kits: "..whyKits end
	for fighterId,record in p.fighters do
		if not SkillBuilds.tree(fighterId) then return false,"No skill tree for "..tostring(fighterId) end
		local ok,reason=fighterValid(fighterId,record)
		if not ok then return false,fighterId..": "..reason end
	end
	local last=p.lastCommand
	if last~=nil and (type(last)~="table" or last.sequence~=p.sequence or not S.id(last.kind)) then return false,"Command ledger" end
	return true
end
-- Version 1 gains its kits record (nothing learned yet); a future or unknown
-- version is refused, never rewritten by an older server.
function S.migrate(raw)
	if not S.serializable(raw) or type(raw)~="table" then return nil,"Unknown/future schema" end
	if raw.schemaVersion==1 then
		raw=S.copy(raw);raw.schemaVersion=2;raw.kits=S.kits()
	end
	if raw.schemaVersion~=S.Version then return nil,"Unknown/future schema" end
	local p=S.copy(raw)
	local ok,reason=S.validate(p)
	if not ok then return nil,reason end
	return p
end
-- Commands: server-side mutations, run on a copy by S.apply (an error aborts
-- the whole command). Refusals are errors with a readable reason.
local function record(p,fighterId)
	assert(SkillBuilds.tree(fighterId),"No skill tree for "..tostring(fighterId))
	p.fighters[fighterId]=p.fighters[fighterId] or S.fighter()
	return p.fighters[fighterId]
end
local function buildCount(r)
	local n=0
	for _ in r.builds do n+=1 end
	return n
end
S.Commands={}
-- Points come from the server only (match rewards, tooling): never a purchase.
function S.Commands.grant(p,args)
	assert(S.integer(args.amount,S.MaxPoints) and args.amount>0,"Invalid amount")
	local r=record(p,args.fighter)
	assert(r.earned+args.amount<=S.MaxPoints,"Point cap")
	r.earned+=args.amount
	return {fighter=args.fighter,earned=r.earned}
end
-- Unlock with earned points. Both options of an exclusive choice may be
-- unlocked; the build decides which one is active.
function S.Commands.unlock(p,args)
	local r=record(p,args.fighter)
	local node=SkillBuilds.node(args.fighter,args.node)
	assert(node,"Unknown node")
	assert(SkillBuilds.wired(args.fighter,node.Id),"Node not available yet")
	assert(not r.unlocked[node.Id],"Already unlocked")
	local ready,reason=unlockReady(args.fighter,node,r.unlocked)
	assert(ready,reason)
	assert(r.earned-S.spent(args.fighter,r)>=node.Cost,"Not enough skill points")
	r.unlocked[node.Id]=true
	return {fighter=args.fighter,node=node.Id,free=r.earned-S.spent(args.fighter,r)}
end
function S.Commands.saveBuild(p,args)
	local r=record(p,args.fighter)
	assert(S.buildName(args.name),"Invalid build name")
	assert(r.builds[args.name]~=nil or buildCount(r)<S.MaxBuilds,"Too many builds")
	local ok,reason=SkillBuilds.validate(args.fighter,args.nodes,{unlocked=r.unlocked})
	assert(ok,reason)
	local nodes=SkillBuilds.apply(args.fighter,args.nodes).nodes
	r.builds[args.name]={nodes=nodes}
	return {fighter=args.fighter,name=args.name,cost=SkillBuilds.cost(args.fighter,nodes)}
end
function S.Commands.deleteBuild(p,args)
	local r=record(p,args.fighter)
	assert(r.builds[args.name],"Unknown build")
	r.builds[args.name]=nil
	if r.selected==args.name then r.selected=nil end
	return {fighter=args.fighter,deleted=args.name}
end
-- name=nil selects the base fighter (no node active).
function S.Commands.selectBuild(p,args)
	local r=record(p,args.fighter)
	assert(args.name==nil or r.builds[args.name],"Unknown build")
	r.selected=args.name
	return {fighter=args.fighter,selected=args.name}
end
-- ------------------------------------------------------------ the masters' path
-- (DEC-037) A new player picks one kit among the starters, once.
function S.Commands.chooseStarter(p,args)
	local k=p.kits
	assert(k.starter==nil,"Starter already chosen")
	assert(Masters.isStarter(args.fighter),"Not a starter kit")
	k.owned[args.fighter]=true;k.starter=args.fighter;k.selected=args.fighter
	return {fighter=args.fighter}
end
-- Mastery from a decided duel with an owned kit (the server computes it,
-- Masters.duelGain; never more than Gain.Max at once).
function S.Commands.gainMastery(p,args)
	local k=p.kits
	assert(k.owned[args.fighter],"Kit not learned")
	assert(S.integer(args.amount,Masters.Gain.Max) and args.amount>0,"Invalid amount")
	k.mastery[args.fighter]=math.min(Masters.MaxMastery,(k.mastery[args.fighter] or 0)+args.amount)
	return {fighter=args.fighter,mastery=k.mastery[args.fighter]}
end
-- A kit learned: from its master (his duel won, the mastery condition met) or
-- bought (a receipt, granted once whatever happens to the save after it).
function S.Commands.learnKit(p,args)
	local k=p.kits
	assert(Masters.isKit(args.fighter),"Unknown kit")
	if args.via=="purchase" then
		assert(S.id(args.receipt),"Receipt required")
		assert(not table.find(k.receipts,args.receipt),"Receipt already granted")
		table.insert(k.receipts,args.receipt)
		while #k.receipts>S.MaxReceipts do table.remove(k.receipts,1) end
		local already=k.owned[args.fighter]==true
		k.owned[args.fighter]=true
		return {fighter=args.fighter,via="purchase",already=already}
	end
	assert(args.via=="master","Unknown way to learn")
	local ok,why=Masters.canLearn(k,args.fighter)
	assert(ok,why)
	k.owned[args.fighter]=true
	return {fighter=args.fighter,via="master"}
end
-- The kit the next duels are fought with: one already learned.
function S.Commands.selectKit(p,args)
	assert(p.kits.owned[args.fighter],"Kit not learned")
	p.kits.selected=args.fighter
	return {fighter=args.fighter}
end
-- Copy/validate/commit. The same sequence and kind replays the stored result
-- (an ambiguous save or a repeated request never applies twice); an older or
-- skipped sequence is refused.
function S.apply(profile,sequence,kind,args)
	assert(S.integer(sequence) and sequence>0,"Invalid command sequence")
	if sequence==profile.sequence and profile.lastCommand and profile.lastCommand.kind==kind then
		return S.copy(profile),S.copy(profile.lastCommand.result),true
	end
	assert(sequence==profile.sequence+1,"Stale or gapped command")
	local command=S.Commands[kind]
	assert(command,"Unknown command")
	assert(type(args)=="table" and S.serializable(args),"Invalid arguments")
	local p=S.copy(profile)
	local result=command(p,args)
	p.sequence=sequence;p.lastCommand={sequence=sequence,kind=kind,result=S.copy(result)}
	local ok,reason=S.validate(p)
	assert(ok,reason)
	return p,result,false
end
-- The nodes of a fighter's selected build (nil = base fighter): what a lobby
-- passes to Matches/SkillBuilds.admit together with the unlocked set.
function S.selection(p,fighterId)
	local r=p.fighters[fighterId]
	if not r then return nil,{} end
	local build=r.selected and r.builds[r.selected]
	return build and S.copy(build.nodes),S.copy(r.unlocked)
end
return S
