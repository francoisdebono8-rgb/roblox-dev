-- Does every major node change something? (OUTILLEUR, 21/11; DEC-045, step 2,
-- OUTILLEUR 2.) François, 20/11: « no difference in play between few tree
-- nodes and the full kit ». A Major node must change a thing that can be
-- measured: a technique more, a range, an effect, an object. This builds the
-- kit a player gets with the node and without it (its prerequisites active
-- in both, the kit gated as a player's: SkillBuilds.apply then .gate), and
-- lists what differs. A Major node whose kit does not differ changes nothing,
-- and tests/Nodes.spec.luau fails on it.
-- The ninja's tree (Shared/NinjaTree): each node must change def.Ninja, the
-- fields the combat reads; tools/kits/noeuds_lus.py checks they are read.
-- Pure: the modules come from the caller.
--   NodeCheck.run({SkillBuilds=, SkillTrees=, BetaRoster=, NinjaTree=})
local NodeCheck={}

local function sorted(t)
	local keys={}
	for k in t do table.insert(keys,k) end
	table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
	return keys
end
-- An array of tables that all carry an Id (the techniques): keyed by Id, so a
-- technique more or less reads as one change, not as every index shifting.
local function byId(t)
	if type(t)~="table" or #t==0 then return nil end
	local map={}
	for i,v in t do
		if type(v)~="table" or type(v.Id)~="string" then return nil end
		map[v.Id]=v
	end
	return map
end
local function show(v)
	if type(v)=="table" then return "{…}" end
	if type(v)=="number" then return tostring(math.floor(v*1000+.5)/1000) end
	return tostring(v)
end

-- Every difference between a and b: {path, before, after}.
function NodeCheck.diff(a,b,path,out)
	out=out or {}
	path=path or ""
	if type(a)=="table" and type(b)=="table" then
		local ia,ib=byId(a),byId(b)
		if ia and ib then a,b=ia,ib end
		local keys={}
		for k in a do keys[k]=true end
		for k in b do keys[k]=true end
		for _,k in sorted(keys) do
			NodeCheck.diff(a[k],b[k],if path=="" then tostring(k) else path.."."..tostring(k),out)
		end
	elseif a~=b then
		if not (type(a)=="number" and type(b)=="number" and math.abs(a-b)<1e-9) then
			table.insert(out,{path=path,before=a,after=b})
		end
	end
	return out
end

-- What a change is, for the reader: a technique gained or unlocked, a kit
-- object, a rule the base kit lacks, or a number.
function NodeCheck.kind(change)
	local p=change.path
	if string.match(p,"^def%.Techniques%.[%w_]+$") or string.match(p,"^def%.Techniques%.[%w_]+%.Locked$") then return "technique" end
	if string.match(p,"^locks") or string.match(p,"^def%.Items") or string.match(p,"Locked$") then return "objet" end
	if change.before==nil or type(change.before)~=type(change.after) or type(change.after)=="boolean" or type(change.after)=="string" then return "règle" end
	return "nombre"
end

-- The node and every node it needs (Requires, and the first workable option
-- of RequiresAny), as a valid build.
function NodeCheck.closure(SB,fighterId,id)
	local set,list={}, {}
	local function add(nid)
		if set[nid] then return end
		local node=SB.node(fighterId,nid)
		if not node then return end
		set[nid]=true
		for _,need in node.Requires or {} do add(need) end
		if node.RequiresAny then
			local any=false
			for _,need in node.RequiresAny do if set[need] then any=true end end
			if not any then add(node.RequiresAny[1]) end
		end
	end
	add(id)
	for _,node in SB.tree(fighterId).Nodes do if set[node.Id] then table.insert(list,node.Id) end end
	return list
end

local function kitOf(SB,fighterId,nodes)
	local kit=SB.apply(fighterId,nodes)
	if SB.gate then SB.gate(kit) end
	return {def=kit.def,graph=kit.graph,locks=kit.locks or {}}
end

-- One kit tree: every node, with what it changes. A Major node with no change
-- is a failure; so is a Major node whose build is not valid.
function NodeCheck.tree(SB,fighterId)
	local rows,failures={}, {}
	local tree=SB.tree(fighterId)
	if not tree then return rows,failures end
	for _,node in tree.Nodes do
		local with=NodeCheck.closure(SB,fighterId,node.Id)
		local without={}
		for _,nid in with do if nid~=node.Id then table.insert(without,nid) end end
		local ok,why=SB.validate(fighterId,with,{allowUnwired=true})
		local row={id=node.Id,name=node.Name,kind=node.Kind,major=node.Major==true,tier=node.Tier,unlock=node.Unlock,item=node.Item,
			wired=SB.wired(fighterId,node.Id),changes={},kinds={}}
		if not ok then
			row.error=tostring(why)
		else
			local built,err=pcall(function()
				row.changes=NodeCheck.diff(kitOf(SB,fighterId,without),kitOf(SB,fighterId,with))
			end)
			if not built then row.error=tostring(err) end
			local seen={}
			for _,c in row.changes do
				local k=NodeCheck.kind(c)
				if not seen[k] then seen[k]=true;table.insert(row.kinds,k) end
			end
		end
		if row.major then
			if row.error then
				table.insert(failures,fighterId.."."..node.Id..": "..row.error)
			elseif #row.changes==0 then
				table.insert(failures,fighterId.."."..node.Id.." ("..tostring(node.Name)..") changes nothing in the kit")
			end
		end
		table.insert(rows,row)
	end
	return rows,failures
end

-- The ninja's tree: each node, active with what it needs, against the same
-- record without it. A node that leaves def.Ninja as it was changes nothing.
function NodeCheck.ninja(N)
	local rows,failures={}, {}
	if not N then return rows,failures end
	for _,node in N.Nodes do
		local function record(withIt)
			local r=N.new()
			local function need(id)
				local n=N.ById[id]
				if not n or table.find(r.learned,id) then return end
				for _,req in n.Requires or {} do need(req) end
				if n.NeedsNature and not N.nature(r) and id~="NatureFire" then need("NatureFire") end
				table.insert(r.learned,id);table.insert(r.active,id)
			end
			for _,req in node.Requires or {} do need(req) end
			if node.NeedsNature then need("NatureFire") end
			if withIt then need(node.Id) end
			return r
		end
		local before,after=N.def(record(false)),N.def(record(true))
		local changes=NodeCheck.diff(before or {},after or {})
		local row={id=node.Id,name=node.Name,branch=node.Branch,changes=changes}
		if #changes==0 then table.insert(failures,"ninja."..node.Id.." changes nothing in def.Ninja") end
		table.insert(rows,row)
	end
	return rows,failures
end

function NodeCheck.run(mods)
	local out={kits={},order={},failures={},ninja=nil}
	for _,id in mods.BetaRoster do
		if mods.SkillBuilds.tree(id) then
			local rows,failures=NodeCheck.tree(mods.SkillBuilds,id)
			out.kits[id]=rows
			table.insert(out.order,id)
			for _,f in failures do table.insert(out.failures,f) end
		end
	end
	if mods.NinjaTree then
		local rows,failures=NodeCheck.ninja(mods.NinjaTree)
		out.ninja=rows
		for _,f in failures do table.insert(out.failures,f) end
	end
	return out
end

-- One line per node, for a reader: what it changes, by kind, with a sample.
function NodeCheck.lines(result)
	local lines={}
	for _,id in result.order do
		for _,row in result.kits[id] do
			if row.major then
				local sample={}
				for i,c in row.changes do
					if i>3 then table.insert(sample,"…");break end
					table.insert(sample,c.path.." "..show(c.before).."→"..show(c.after))
				end
				table.insert(lines,string.format("%s %-22s %s  %s",id,row.id,
					if #row.changes==0 then "RIEN" else table.concat(row.kinds,"+"),table.concat(sample,"; ")))
			end
		end
	end
	return lines
end

return NodeCheck
