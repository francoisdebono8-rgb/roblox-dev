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
local TreeTiers=require(game:GetService("ReplicatedStorage").NinjaDuel.TreeTiers)
local Shop=require(game:GetService("ReplicatedStorage").NinjaDuel.Shop)
-- Version 3 (13/11, the shop): the wallet (Ryō, earned by playing or bought
-- in packs; the day of the last first win) and the looks (owned, and the one
-- worn in each slot: Shared/Shop). A look never changes a number.
local S={Version=3,MaxPoints=999,MaxBuilds=8,MaxSequence=1000000000,MaxReceipts=50}
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
	return {schemaVersion=S.Version,id=id,fighters={},sequence=0,kits=S.kits(),wallet=S.wallet(),style=S.style()}
end
function S.kits() return {owned={},mastery={},receipts={}} end
function S.wallet() return {ryo=0} end
function S.style() return {owned={},equipped={}} end
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
local function walletValid(w)
	if type(w)~="table" or not S.integer(w.ryo,Shop.MaxRyo) then return false,"ryo" end
	if w.winDay~=nil and (type(w.winDay)~="string" or #w.winDay>10) then return false,"win day" end
	return true
end
local function styleValid(st)
	if type(st)~="table" or type(st.owned)~="table" or type(st.equipped)~="table" then return false,"style record" end
	for id,flag in st.owned do
		local item=Shop.item(id)
		if flag~=true or not item then return false,"unknown look "..tostring(id) end
	end
	for slot,id in st.equipped do
		local item=Shop.item(id)
		if not Shop.Slots[slot] or not item or item.slot~=slot or not (item.base or st.owned[id]) then return false,"look worn in "..tostring(slot) end
	end
	return true
end
function S.validate(p)
	if not S.serializable(p) then return false,"Unsafe serialized data" end
	if type(p)~="table" or p.schemaVersion~=S.Version or not S.profileId(p.id) or not S.integer(p.sequence) or type(p.fighters)~="table" then return false,"Profile header/version" end
	local okKits,whyKits=kitsValid(p.kits)
	if not okKits then return false,"kits: "..whyKits end
	local okWallet,whyWallet=walletValid(p.wallet)
	if not okWallet then return false,"wallet: "..whyWallet end
	local okStyle,whyStyle=styleValid(p.style)
	if not okStyle then return false,"style: "..whyStyle end
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
	-- Version 2 gains an empty wallet and the base looks.
	if raw.schemaVersion==2 then
		raw=S.copy(raw);raw.schemaVersion=3;raw.wallet=S.wallet();raw.style=S.style()
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
	-- (DEC-038) The kit's tree grows with its mastery.
	local points=S.syncPoints(p,args.fighter)
	return {fighter=args.fighter,mastery=k.mastery[args.fighter],points=points}
end
-- The tree's points follow the kit's mastery (never down: a point already
-- earned stays). Returns the points earned, nil for a kit without a tree.
function S.syncPoints(p,fighterId)
	if not SkillBuilds.tree(fighterId) then return nil end
	local r=record(p,fighterId)
	r.earned=math.max(r.earned,math.min(S.MaxPoints,Masters.points(p.kits.mastery[fighterId] or 0)))
	return r.earned
end
-- (DEC-038) The tree at the master's: a node bought with the kit's points goes
-- straight into the kit's build ("Main", selected), when it fits beside the
-- nodes already active (an exclusive choice keeps the first one).
function S.Commands.syncPoints(p,args)
	assert(p.kits.owned[args.fighter],"Kit not learned")
	return {fighter=args.fighter,points=S.syncPoints(p,args.fighter)}
end
S.MainBuild="Main"
local function mainNodes(r)
	local build=r.builds[S.MainBuild]
	return if build then S.copy(build.nodes) else {}
end
local function setMain(fighterId,r,nodes)
	local ok,reason=SkillBuilds.validate(fighterId,nodes,{unlocked=r.unlocked})
	assert(ok,reason)
	r.builds[S.MainBuild]={nodes=SkillBuilds.apply(fighterId,nodes).nodes}
	r.selected=S.MainBuild
end
function S.Commands.learnNode(p,args)
	assert(p.kits.owned[args.fighter],"Kit not learned")
	-- (13/11) The tree opens in tiers with the kit's mastery (Shared/TreeTiers).
	local node=SkillBuilds.node(args.fighter,args.node)
	assert(node,"Unknown node")
	local need=TreeTiers.need(node)
	assert((p.kits.mastery[args.fighter] or 0)>=need,"Tier "..TreeTiers.Names[TreeTiers.of(node)].." opens at "..need.." mastery")
	local r=record(p,args.fighter)
	S.Commands.unlock(p,{fighter=args.fighter,node=args.node})
	local nodes=mainNodes(r)
	table.insert(nodes,args.node)
	local active=false
	if SkillBuilds.validate(args.fighter,nodes,{unlocked=r.unlocked}) then setMain(args.fighter,r,nodes);active=true
	elseif r.builds[S.MainBuild]==nil then setMain(args.fighter,r,mainNodes(r)) end
	return {fighter=args.fighter,node=args.node,active=active,free=r.earned-S.spent(args.fighter,r)}
end
-- Turn an unlocked node on or off in the kit's build. On: its exclusive
-- alternative goes off. Off: the nodes that require it go off too.
function S.Commands.setNode(p,args)
	assert(p.kits.owned[args.fighter],"Kit not learned")
	local r=record(p,args.fighter)
	local node=SkillBuilds.node(args.fighter,args.node)
	assert(node and r.unlocked[node.Id],"Node not unlocked")
	local nodes=mainNodes(r)
	local set={}
	for _,id in nodes do set[id]=true end
	if args.on==true then
		if node.Exclusive then
			for id in set do
				local other=SkillBuilds.node(args.fighter,id)
				if other and other.Exclusive==node.Exclusive then set[id]=nil end
			end
		end
		set[node.Id]=true
	else
		set[node.Id]=nil
		local changed=true
		while changed do
			changed=false
			for id in set do
				local other=SkillBuilds.node(args.fighter,id)
				for _,need in other and other.Requires or {} do if not set[need] then set[id]=nil;changed=true end end
				if other and other.RequiresAny then
					local any=false
					for _,need in other.RequiresAny do if set[need] then any=true end end
					if not any then set[id]=nil;changed=true end
				end
			end
		end
	end
	local list={}
	for id in set do table.insert(list,id) end
	setMain(args.fighter,r,list)
	return {fighter=args.fighter,node=node.Id,on=args.on==true,active=r.builds[S.MainBuild].nodes}
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
-- ------------------------------------------------------------ the shop
-- (13/11) Ryō from a decided duel (the server computes it, Shop.duelRyo);
-- `day` marks the day's first win once it is paid.
function S.Commands.earnRyo(p,args)
	assert(S.integer(args.amount,10000) and args.amount>0,"Invalid amount")
	local w=p.wallet
	w.ryo=math.min(Shop.MaxRyo,w.ryo+args.amount)
	if args.day~=nil then assert(type(args.day)=="string" and #args.day<=10,"Invalid day");w.winDay=args.day end
	return {ryo=w.ryo,amount=args.amount}
end
-- A look bought with Ryō: paid once, worn at once.
function S.Commands.buyItem(p,args)
	local item=Shop.item(args.item)
	assert(item,"Unknown look")
	assert(item.ryo and not item.base,"Not sold for Ryō")
	assert(not p.style.owned[item.id],"Already yours")
	assert(p.wallet.ryo>=item.ryo,"Not enough Ryō")
	p.wallet.ryo-=item.ryo
	p.style.owned[item.id]=true
	p.style.equipped[item.slot]=item.id
	return {item=item.id,ryo=p.wallet.ryo}
end
-- Bought with Robux (a receipt): a look, or a pack of Ryō. Once per receipt.
local function receipt(p,id)
	assert(S.id(id),"Receipt required")
	local k=p.kits
	assert(not table.find(k.receipts,id),"Receipt already granted")
	table.insert(k.receipts,id)
	while #k.receipts>S.MaxReceipts do table.remove(k.receipts,1) end
end
function S.Commands.grantItem(p,args)
	local item=Shop.item(args.item)
	assert(item and item.robux,"Not sold for Robux")
	receipt(p,args.receipt)
	p.style.owned[item.id]=true
	p.style.equipped[item.slot]=item.id
	return {item=item.id}
end
function S.Commands.grantRyo(p,args)
	assert(S.integer(args.amount,1000000) and args.amount>0,"Invalid amount")
	receipt(p,args.receipt)
	p.wallet.ryo=math.min(Shop.MaxRyo,p.wallet.ryo+args.amount)
	return {ryo=p.wallet.ryo}
end
-- Wear a look the player owns (or a base one) in its slot.
function S.Commands.equipItem(p,args)
	local item=Shop.item(args.item)
	assert(item,"Unknown look")
	assert(item.base or p.style.owned[item.id],"Not yours")
	p.style.equipped[item.slot]=item.id
	return {item=item.id,slot=item.slot}
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
