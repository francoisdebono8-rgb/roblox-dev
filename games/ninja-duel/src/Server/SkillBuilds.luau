-- Skill builds (PROG-001/002). Pure, server-side: validates a fighter's ACTIVE
-- skill nodes and applies them onto copies of the fighter definition and move
-- graph. The result (a "kit") is what Combat:add gives the actor; without a kit
-- the actor uses Fighters/MoveGraphs directly, so no build means today's fighter.
--
-- Hook contract: a node effect only targets data the runtime reads. Canonical
-- numeric fields need a declared bound (RATIO); fields absent from the base kit
-- must be declared in OPTIONAL with the code that reads them. A node is "wired"
-- when every field it touches has a live reader; unwired nodes stay data-only
-- and cannot be activated (except in design tooling with allowUnwired).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local MoveGraphs=require(Shared.MoveGraphs)
local Attacks=require(Shared.Attacks)
local Trees=require(script.Parent.SkillTrees)
local SkillBuilds={Trees=Trees}

SkillBuilds.KINDS={stat=true,property=true,route=true,airwall=true,counter=true,substitution=true,tool=true,jutsu=true,awakening=true}
SkillBuilds.LORE={CANON_YOUNG=true,PLAUSIBLE_YOUNG=true,GAMEPLAY_LIBERTY=true}
-- Every tree must reach this many skill points at its maximum (design), so a
-- 120+ endgame bracket still leaves choices.
SkillBuilds.DESIGN_MAX={120,150}
SkillBuilds.MAX_NODES=40
-- Route payoff kinds Brawler.routePayoff knows.
local PAYOFFS={bodySeal=true,floorSeal=true,coverBlades=true,shadowLeaf=true,tenketsu=true,echo=true}
-- Mild, bounded changes of canonical numbers: {min, max} ratio to the base value.
local RATIO={
	["def.Health"]={1,1.08},["def.Chakra"]={1,1.12},["def.ChakraRegen"]={1,1.12},
	["def.ToolMastery.Recover"]={.8,1},["def.ToolMastery.AirSpread"]={1,1.7},
	["def.Sharingan.ParryWindow"]={1,1.15},["def.Sharingan.PerfectDodge"]={1,1.15},
	["def.GentleFist.Drain"]={1,1.2},["def.GentleFist.Duration"]={1,1.35},
	["def.Byakugan.BlindSpot"]={1,1.06},["def.Awakening.HealthDrain"]={.65,1},
	["tech.Cost"]={.75,1},["tech.Cooldown"]={.7,1},["tech.Channel"]={.7,1},["tech.Active"]={1,1.4},["tech.Range"]={1,1.3},
}
-- Technique fields the shared pipeline reads for every technique, and the
-- techniques whose own implementation reads spec.Range.
local TECH_FIELDS={Cost=true,Cooldown=true,Channel=true,Active=true,Recovery=true}
local RANGE_READ={MarkedBlade=true,WindCut=true,NeedleFan=true,MirageCast=true,FireBloom=true,PhoenixFlower=true,VacuumPalm=true,SixtyFourPalms=true,WireTrap=true}
-- Fields absent from the base kit, each read by one explicit hook (Hook names
-- the reader). Kind: "attack" | "technique" (map key) | "payoff". Value: the
-- only accepted value; Values: accepted strings; Max/Min: absolute numeric
-- bounds; Default+Ratio: bounds relative to the implicit default; Fields: table
-- schema. Wired=false marks a declared hook that is not implemented yet.
SkillBuilds.OPTIONAL={
	["def.LauncherMove"]={Kind="attack",Hook="Brawler.request: heavy after two clean hits"},
	["graph.readCounter"]={Kind="attack",Hook="Brawler.request: strike inside a counter window"},
	["graph.stringCancels.*"]={Key="technique",Value=true,Hook="Combat:request: string cancel"},
	["graph.onRoute.*"]={Key="attack",Kind="payoff",Hook="Brawler.routePayoff"},
	["graph.blockCancels.Tool"]={Value=true,Hook="Combat:request: Tool after a blocked string"},
	["graph.wallBounce.*"]={Key="attack",Value=true,Hook="Brawler.wallFollow"},
	["def.Seals.PlantedLife"]={Default=12,Ratio={1,1.3},Hook="Techniques.plant"},
	["def.SealRecall"]={Fields={Radius={Max=5},Refund={Max=8}},Hook="Techniques.expireSeals"},
	["def.ArrivalThrow"]={Fields={Damage={Max=3}},Hook="Combat:arrivalThrow"},
	["def.Substitution"]={Fields={Mode={Values={flank=true}},Counter={Max=.8},PlantDeparture="boolean",FreeRush={Max=1}},Hook="Combat:substitute / Combat:rush"},
	["def.ParrySeal"]={Max=2.5,Hook="Combat:parryRider"},
	["def.ParryRedirect"]={Fields={Points={Max=2},Counter={Max=.8}},Hook="Combat:parryRider"},
	["def.WallSteer"]={Fields={Moves="table",Range={Max=16},Cone={Max=.8}},Hook="Brawler.hit (knockback aim)"},
	["def.ToolMastery.AirSpread"]={Min=2,Max=5,Hook="Combat:request: Tool in the air"},
	["def.ToolMastery.Chase"]={Max=.8,Hook="Combat:projectileHit (bounced blade)"},
	["def.ToolMastery.FireBlades"]={Fields={Damage={Max=2},Patch={Max=2}},Hook="Combat:igniteBlade / Combat:projectileHit"},
	["def.Awakening.FlashChain"]={Max=2.5,Hook="Brawler.hit"},
	["def.Awakening.Reflex"]={Max=2,Hook="Combat:reflexEcho"},
	["def.Awakening.GuardPoints"]={Value=true,Hook="Brawler.gentleFist"},
	["def.Awakening.BloodChakra"]={Value=true,Hook="Combat:curseBlood"},
	["tech.Quickstep.Arrival"]={Max=.45,Hook="Techniques.Quickstep"},
	["tech.WindCut.Chase"]={Max=1,Hook="Elements.wind / Combat:projectileHit"},
	["tech.BurstStrike.DropReaction"]={Values={Spiked=true},Hook="Techniques.BurstStrike"},
	["tech.NeedleFan.FlankBlades"]={Value=true,Hook="Techniques.NeedleFan"},
	["tech.VacuumPalm.Tenketsu"]={Value=true,Hook="Techniques.VacuumPalm / Combat:projectileHit"},
	["tech.Rotation.Reach"]={Default=7,Ratio={1,1.2},Hook="Techniques.Rotation / Combat:stepRotation"},
	["tech.Rotation.Reflect"]={Value=true,Hook="Combat:stepRotation"},
	["tech.SixtyFourPalms.Seal"]={Default=3.5,Ratio={1,1.3},Hook="Techniques.SixtyFourPalms"},
	["tech.WireTrap.WallPin"]={Fields={Range={Max=12},Bind={Max=1.5}},Hook="Techniques.wireBind"},
	["tech.PhoenixFlower.WiredBlades"]={Max=1,Hook="Elements.phoenix"},
	["tech.Chidori.WallCharge"]={Min=.25,Max=.62,Hook="Combat:request (Chidori from a wall run)"},
}
-- Ranked brackets (PROG-002): inside a bracket every fighter may ACTIVATE at
-- most Budget skill points, whatever he has unlocked. Progression gives more
-- build choices, not more power inside the same bracket.
SkillBuilds.Brackets={
	{Id="Fundamentals",Budget=50,Enabled=true,Label="50 SP - fundamentals"},
	{Id="Identity",Budget=80,Enabled=true,Label="80 SP - stronger fighter identity"},
	{Id="Advanced",Budget=100,Enabled=true,Label="100 SP - advanced builds"},
	{Id="Endgame",Budget=150,Enabled=false,Label="120+ SP - endgame / special (later)"},
}

local function copy(value)
	if type(value)~="table" then return value end
	local out={}
	for k,v in value do out[k]=copy(v) end
	return out
end
SkillBuilds.copy=copy
local function split(path)
	local parts={}
	for part in string.gmatch(path,"[^%.]+") do table.insert(parts,part) end
	return parts
end
local function techniqueOf(def,id)
	for _,spec in def.Techniques or {} do if spec.Id==id then return spec end end
	return nil
end
-- The table holding a path's leaf, and the leaf key. Missing intermediate
-- tables are created only when `create` is set (optional rule tables).
local function locate(kit,path,create)
	local parts=split(path)
	local node,start
	if parts[1]=="def" then node=kit.def;start=2
	elseif parts[1]=="graph" then node=kit.graph;start=2
	elseif parts[1]=="tech" then node=techniqueOf(kit.def,parts[2]);start=3
	else return nil end
	if type(node)~="table" or #parts<start then return nil end
	for k=start,#parts-1 do
		local child=node[parts[k]]
		if child==nil and create then child={};node[parts[k]]=child end
		if type(child)~="table" then return nil end
		node=child
	end
	return node,parts[#parts]
end
local function canonical(fighterId,path)
	local holder,key=locate({def=Fighters[fighterId],graph=MoveGraphs[fighterId] or {}},path,false)
	if holder==nil then return nil end
	return holder[key]
end
local function optionalOf(path)
	local spec=SkillBuilds.OPTIONAL[path]
	if spec then return spec,nil end
	local parent,key=string.match(path,"^(.+)%.([^%.]+)$")
	if parent then
		spec=SkillBuilds.OPTIONAL[parent..".*"]
		if spec then return spec,key end
	end
	return nil,nil
end
SkillBuilds.optionalOf=optionalOf
local function ratioOf(path,spec)
	if RATIO[path] then return RATIO[path] end
	local field=string.match(path,"^tech%.[%w]+%.(%w+)$")
	if field and RATIO["tech."..field] then return RATIO["tech."..field] end
	return spec and spec.Ratio
end

local index={}
local function nodesOf(fighterId)
	local tree=Trees[fighterId]
	if not tree then return nil end
	if not index[fighterId] then
		local map={}
		for order,node in tree.Nodes do map[node.Id]={node=node,order=order} end
		index[fighterId]=map
	end
	return index[fighterId]
end
function SkillBuilds.tree(fighterId) return Trees[fighterId] end
function SkillBuilds.node(fighterId,id)
	local map=nodesOf(fighterId)
	local entry=map and map[id]
	return entry and entry.node
end
-- A node is live when every field it touches has an implemented reader.
function SkillBuilds.wired(fighterId,id)
	local node=SkillBuilds.node(fighterId,id)
	if not node then return false end
	for _,effect in node.Effects do
		local spec=optionalOf(effect[1])
		if spec and spec.Wired==false then return false end
	end
	return true
end
function SkillBuilds.unwired(fighterId)
	local list={}
	for _,node in (Trees[fighterId] or {Nodes={}}).Nodes do
		if not SkillBuilds.wired(fighterId,node.Id) then table.insert(list,node.Id) end
	end
	return list
end
-- Nodes in tree order (the order effects stack in).
local function ordered(fighterId,set)
	local list={}
	for _,node in Trees[fighterId].Nodes do if set[node.Id] then table.insert(list,node.Id) end end
	return list
end
function SkillBuilds.cost(fighterId,nodes)
	local total=0
	for _,id in nodes do
		local node=SkillBuilds.node(fighterId,id)
		if node then total+=node.Cost end
	end
	return total
end
-- Validate an ACTIVE build. opts.budget: maximum skill points (ranked bracket);
-- opts.unlocked: set of unlocked node ids (profile); opts.allowUnwired: design
-- tooling only. Returns true, total cost or false, reason.
function SkillBuilds.validate(fighterId,nodes,opts)
	opts=opts or {}
	local map=nodesOf(fighterId)
	if not map then return false,"No skill tree for "..tostring(fighterId) end
	if type(nodes)~="table" then return false,"Invalid build" end
	local count=0
	for _ in nodes do count+=1 end
	if count~=#nodes or count>SkillBuilds.MAX_NODES then return false,"Invalid build" end
	local active,total={},0
	for _,id in nodes do
		if type(id)~="string" or not map[id] then return false,"Unknown node "..tostring(id) end
		if active[id] then return false,"Duplicate node "..id end
		active[id]=true;total+=map[id].node.Cost
	end
	local groups={}
	for _,id in ordered(fighterId,active) do
		local node=map[id].node
		if not opts.allowUnwired and not SkillBuilds.wired(fighterId,id) then return false,"Node not available yet: "..id end
		if opts.unlocked and opts.unlocked[id]~=true then return false,"Node locked: "..id end
		for _,need in node.Requires or {} do
			if not active[need] then return false,id.." requires "..need end
		end
		if node.RequiresAny then
			local any=false
			for _,need in node.RequiresAny do if active[need] then any=true end end
			if not any then return false,id.." requires one of "..table.concat(node.RequiresAny,", ") end
		end
		if node.Exclusive then
			if groups[node.Exclusive] then return false,"Exclusive choice "..node.Exclusive..": "..groups[node.Exclusive].." or "..id end
			groups[node.Exclusive]=id
		end
	end
	if opts.budget and total>opts.budget then return false,string.format("Build costs %d SP, budget is %d",total,opts.budget) end
	return true,total
end
-- Apply nodes (assumed valid) onto copies of the canonical kit. Effects stack in
-- tree order, so a build gives the same kit whatever order it was listed in.
function SkillBuilds.apply(fighterId,nodes)
	assert(Trees[fighterId] and Fighters[fighterId],"No skill tree for "..tostring(fighterId))
	local kit={fighterId=fighterId,def=copy(Fighters[fighterId]),graph=copy(MoveGraphs[fighterId] or {}),nodes={},spent=0}
	local active={}
	for _,id in nodes or {} do
		assert(SkillBuilds.node(fighterId,id),"Unknown node "..tostring(id))
		active[id]=true
	end
	for _,node in Trees[fighterId].Nodes do
		if active[node.Id] then
			for _,effect in node.Effects do
				local path,op,value=effect[1],effect[2],effect[3]
				local holder,key=locate(kit,path,true)
				assert(holder,"Unresolved effect path "..path)
				if op=="set" then holder[key]=copy(value)
				else
					local spec=optionalOf(path)
					local start=holder[key]
					if start==nil and spec then start=spec.Default end
					assert(type(start)=="number" and type(value)=="number","Numeric effect on a non-number: "..path)
					holder[key]=if op=="add" then start+value else start*value
				end
			end
			table.insert(kit.nodes,node.Id);kit.spent+=node.Cost
		end
	end
	return kit
end
-- Validate then apply: the only way server code should obtain a kit.
function SkillBuilds.build(fighterId,nodes,opts)
	local ok,reason=SkillBuilds.validate(fighterId,nodes,opts)
	if not ok then return nil,reason end
	return SkillBuilds.apply(fighterId,nodes)
end
function SkillBuilds.bracket(id)
	for _,bracket in SkillBuilds.Brackets do if bracket.Id==id then return bracket end end
	return nil
end
-- Ranked admission: what a player may ACTIVATE in a bracket queue. The server
-- calls this with the profile's unlocked set; an over-budget, locked or
-- inconsistent build is refused, never trimmed.
function SkillBuilds.admit(bracketId,fighterId,nodes,unlocked,opts)
	local bracket=SkillBuilds.bracket(bracketId)
	if not bracket then return nil,"Unknown bracket" end
	if not bracket.Enabled and not (opts and opts.allowClosed) then return nil,"Bracket closed" end
	local kit,reason=SkillBuilds.build(fighterId,nodes,{budget=bracket.Budget,unlocked=unlocked})
	if not kit then return nil,reason end
	kit.bracket=bracket.Id;kit.budget=bracket.Budget
	return kit
end
function SkillBuilds.checkBrackets(list)
	local errors,seen,previous={}, {},0
	local enabled=0
	for _,bracket in list or SkillBuilds.Brackets do
		if type(bracket.Id)~="string" or seen[bracket.Id] then table.insert(errors,"bracket id "..tostring(bracket.Id)) end
		seen[bracket.Id or ""]=true
		if type(bracket.Budget)~="number" or bracket.Budget%1~=0 or bracket.Budget<=previous then table.insert(errors,"bracket budgets must be increasing integers ("..tostring(bracket.Id)..")") end
		previous=if type(bracket.Budget)=="number" then bracket.Budget else previous
		if bracket.Enabled then enabled+=1 end
	end
	if enabled==0 then table.insert(errors,"no open bracket") end
	return errors
end
-- Drop nodes whose requirements are missing (until stable), keep tree order.
local function prune(fighterId,list)
	local set={}
	for _,id in list do set[id]=true end
	local changed=true
	while changed do
		changed=false
		for id in table.clone(set) do
			local node=SkillBuilds.node(fighterId,id)
			local ok=true
			for _,need in node.Requires or {} do if not set[need] then ok=false end end
			if node.RequiresAny then
				local any=false
				for _,need in node.RequiresAny do if set[need] then any=true end end
				ok=ok and any
			end
			if not ok then set[id]=nil;changed=true end
		end
	end
	return ordered(fighterId,set)
end
-- Every largest build: all nodes, one option per exclusive group (each combination).
function SkillBuilds.maximalBuilds(fighterId,wiredOnly)
	local groups,order,fixed={}, {}, {}
	for _,node in Trees[fighterId].Nodes do
		if not wiredOnly or SkillBuilds.wired(fighterId,node.Id) then
			if node.Exclusive then
				if not groups[node.Exclusive] then groups[node.Exclusive]={};table.insert(order,node.Exclusive) end
				table.insert(groups[node.Exclusive],node.Id)
			else table.insert(fixed,node.Id) end
		end
	end
	local builds={fixed}
	for _,name in order do
		local grown={}
		for _,build in builds do
			for _,id in groups[name] do
				local option=table.clone(build);table.insert(option,id);table.insert(grown,option)
			end
		end
		builds=grown
	end
	for i,build in builds do builds[i]=prune(fighterId,build) end
	return builds
end
-- Highest cost of a valid build (wiredOnly: what can actually be activated).
function SkillBuilds.maxCost(fighterId,wiredOnly)
	local best=0
	for _,build in SkillBuilds.maximalBuilds(fighterId,wiredOnly) do best=math.max(best,SkillBuilds.cost(fighterId,build)) end
	return best
end
local function checkValue(fighterId,path,op,value,errors)
	local base=canonical(fighterId,path)
	local spec,key=optionalOf(path)
	local function fail(message) table.insert(errors,path..": "..message) end
	if op~="set" and op~="add" and op~="mul" then return fail("unknown op "..tostring(op)) end
	local root,tech,field=string.match(path,"^(%a+)%.([%w]+)%.?([%w]*)")
	if root=="tech" then
		if not techniqueOf(Fighters[fighterId],tech) then return fail("unknown technique") end
		local leaf=string.match(path,"^tech%.[%w]+%.(%w+)$")
		if not spec and not TECH_FIELDS[leaf or ""] and not (leaf=="Range" and RANGE_READ[tech]) then return fail("technique field not read by the runtime") end
	elseif root~="def" and root~="graph" then return fail("unknown root")
	end
	if field=="" and root=="tech" then return fail("technique field missing") end
	if base==nil and not spec then return fail("no canonical value and no declared hook") end
	if op=="add" or op=="mul" then
		local start=if base~=nil then base else spec and spec.Default
		if type(value)~="number" or type(start)~="number" then return fail("numeric op needs numbers") end
		if not ratioOf(path,spec) and not (spec and (spec.Max or spec.Min)) then return fail("no bound declared") end
		return
	end
	if base~=nil then
		-- A node may scale a base number; it never replaces part of the base kit.
		if type(base)~="number" or type(value)~="number" then return fail("would replace part of the base kit") end
		if not ratioOf(path,spec) then return fail("no bound declared") end
		return
	end
	if spec.Key=="technique" and not techniqueOf(Fighters[fighterId],key) then return fail("unknown technique key") end
	if spec.Key=="attack" and not Attacks[key] then return fail("unknown move key") end
	if spec.Kind=="attack" and not Attacks[value] then return fail("unknown move") end
	if spec.Kind=="payoff" and not PAYOFFS[value] then return fail("unknown route payoff") end
	if spec.Value~=nil and value~=spec.Value then return fail("value must be "..tostring(spec.Value)) end
	if spec.Values and not spec.Values[value] then return fail("value not allowed") end
	if spec.Max or spec.Min or spec.Default then
		if type(value)~="number" then return fail("number expected") end
	end
	if spec.Fields then
		if type(value)~="table" then return fail("table expected") end
		for name,item in value do
			local rule=spec.Fields[name]
			if rule==nil then fail("unexpected field "..tostring(name))
			elseif type(rule)=="string" then if type(item)~=rule then fail(name.." must be a "..rule) end
			else
				if rule.Values then if not rule.Values[item] then fail(name.." not allowed") end
				elseif type(item)~="number" or item<=0 or (rule.Max and item>rule.Max) then fail(name.." out of bounds") end
			end
		end
	end
end
-- Tree integrity (PROG-001 contract). Returns a list of errors (empty = valid).
function SkillBuilds.checkTree(fighterId)
	local errors={}
	local function fail(message) table.insert(errors,fighterId..": "..message) end
	local tree=Trees[fighterId]
	if not tree or tree.Fighter~=fighterId or not Fighters[fighterId] or not MoveGraphs[fighterId] then fail("tree/fighter/graph mismatch");return errors end
	local ids,kinds,groups={}, {}, {}
	for _,node in tree.Nodes do
		local id=node.Id
		if type(id)~="string" or not string.match(id,"^%a%w*$") or #id>32 or ids[id] then fail("bad or duplicate id "..tostring(id)) end
		ids[id or ""]=node
		if type(node.Name)~="string" or type(node.Branch)~="string" then fail(tostring(id)..": name/branch") end
		if not SkillBuilds.KINDS[node.Kind] then fail(tostring(id)..": kind "..tostring(node.Kind)) end
		kinds[node.Kind or ""]=true
		if type(node.Cost)~="number" or node.Cost%1~=0 or node.Cost<1 or node.Cost>20 then fail(tostring(id)..": cost") end
		if type(node.Shows)~="string" or #node.Shows<20 or type(node.Counter)~="string" or #node.Counter<10 then fail(tostring(id)..": Shows/Counter text") end
		if not SkillBuilds.LORE[node.Lore] then fail(tostring(id)..": lore label") end
		if type(node.Effects)~="table" or #node.Effects==0 then fail(tostring(id)..": no effect") end
		if node.Exclusive then groups[node.Exclusive]=(groups[node.Exclusive] or 0)+1 end
		local addsBehaviour=false
		for _,effect in node.Effects or {} do
			local path,op,value=effect[1],effect[2],effect[3]
			if type(path)~="string" then fail(tostring(id)..": effect path");continue end
			local before=#errors
			checkValue(fighterId,path,op,value,errors)
			for k=before+1,#errors do errors[k]=fighterId.."."..tostring(id)..": "..errors[k] end
			if op=="set" and canonical(fighterId,path)==nil then addsBehaviour=true end
			if node.Kind=="stat" and path~="def.Health" and path~="def.Chakra" and path~="def.ChakraRegen" then fail(tostring(id)..": a stat node only changes health or chakra") end
		end
		if node.Major then
			if node.Kind=="stat" then fail(tostring(id)..": a major node cannot be a stat") end
			-- DO/SEE: a major node adds a rule, route or behaviour the base kit lacks.
			if not addsBehaviour then fail(tostring(id)..": a major node must add behaviour, not only scale a number") end
			if #node.Shows<40 then fail(tostring(id)..": a major node must explain what changes") end
		end
	end
	for name,count in groups do if count<2 then fail("exclusive group "..name.." needs two options") end end
	for kind in SkillBuilds.KINDS do if not kinds[kind] then fail("no "..kind.." node") end end
	-- Requirements exist, cannot sit in the node's own exclusive group, no cycle.
	for _,node in tree.Nodes do
		for _,need in node.Requires or {} do
			local other=ids[need]
			if not other or need==node.Id then fail(tostring(node.Id).." requires unknown "..tostring(need))
			elseif node.Exclusive and other.Exclusive==node.Exclusive then fail(tostring(node.Id).." requires its own exclusive alternative") end
		end
		for _,need in node.RequiresAny or {} do if not ids[need] then fail(tostring(node.Id).." requires unknown "..tostring(need)) end end
	end
	local state={}
	local function visit(id)
		if state[id]=="open" then fail("prerequisite cycle at "..id);return end
		if state[id] then return end
		state[id]="open"
		local node=ids[id]
		for _,need in node and node.Requires or {} do if ids[need] then visit(need) end end
		for _,need in node and node.RequiresAny or {} do if ids[need] then visit(need) end end
		state[id]="done"
	end
	for _,node in tree.Nodes do if type(node.Id)=="string" then visit(node.Id) end end
	if #errors>0 then return errors end
	-- Design maximum and bounds on every largest build.
	local design=SkillBuilds.maxCost(fighterId,false)
	if design<SkillBuilds.DESIGN_MAX[1] or design>SkillBuilds.DESIGN_MAX[2] then fail("design maximum "..design.." SP outside "..SkillBuilds.DESIGN_MAX[1].."-"..SkillBuilds.DESIGN_MAX[2]) end
	for _,build in SkillBuilds.maximalBuilds(fighterId,false) do
		local ok,reason=SkillBuilds.validate(fighterId,build,{allowUnwired=true})
		if not ok then fail("largest build invalid: "..reason) end
		local kit=SkillBuilds.apply(fighterId,build)
		for _,id in build do
			for _,effect in SkillBuilds.node(fighterId,id).Effects do
				local path=effect[1]
				local holder,key=locate(kit,path,false)
				local final=holder and holder[key]
				if type(final)=="number" then
					local spec=optionalOf(path)
					local base=canonical(fighterId,path)
					if base==nil and spec then base=spec.Default end
					local ratio=if base then ratioOf(path,spec) else nil
					if ratio and base and base~=0 then
						local r=final/base
						if r<ratio[1]-1e-9 or r>ratio[2]+1e-9 then fail(path.." ends at "..final.." ("..string.format("%.3f",r).."x base)") end
					end
					if spec and spec.Max and final>spec.Max+1e-9 then fail(path.." above "..spec.Max) end
					if spec and spec.Min and final<spec.Min-1e-9 then fail(path.." below "..spec.Min) end
					if string.match(path,"%.Channel$") and final<.04 then fail(path.." channel below 0.04 s") end
				end
			end
		end
	end
	return errors
end
return SkillBuilds
