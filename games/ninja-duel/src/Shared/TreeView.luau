-- What the tree panel shows for a learned kit (DEC-038, user 13/11: « il faut
-- faire les arbres de compétences réelles »). Pure: the client's TreePanel
-- draws it, the headless suites test it. `state` is the server's
-- Progression.view(...).trees[kit]: {points, free, unlocked={ids}, active={ids}}.
local Trees=require(script.Parent.SkillTrees)
local Fighters=require(script.Parent.Fighters)
local Text=require(script.Parent.Text)
local Masters=require(script.Parent.Masters)
local TreeTiers=require(script.Parent.TreeTiers)
local V={}

local KIND_LABEL={stat="BODY",property="EDGE",route="ROUTE",airwall="WALL",counter="COUNTER",
	substitution="ESCAPE",tool="OBJECT",jutsu="JUTSU",awakening="AWAKENING"}
V.KIND_LABEL=KIND_LABEL

local function sets(state)
	local unlocked,active={},{}
	for _,id in state and state.unlocked or {} do unlocked[id]=true end
	for _,id in state and state.active or {} do active[id]=true end
	return unlocked,active
end
local function nodeOf(kit,id)
	for _,node in (Trees[kit] or {Nodes={}}).Nodes do if node.Id==id then return node end end
	return nil
end
V.node=nodeOf
function V.tree(kit) return (Trees[kit] or {Nodes={}}).Nodes end

local function missing(node,unlocked)
	local out={}
	for _,need in node.Requires or {} do if not unlocked[need] then table.insert(out,need) end end
	if node.RequiresAny then
		local any=false
		for _,need in node.RequiresAny do if unlocked[need] then any=true end end
		if not any then table.insert(out,table.concat(node.RequiresAny," or ")) end
	end
	return out
end

-- active · off (unlocked, not in the build) · learn (affordable now) ·
-- short (needs more points) · tier (its tier needs more mastery) · locked
-- (a node before it first)
function V.status(kit,state,node)
	local unlocked,active=sets(state)
	if active[node.Id] then return "active" end
	if unlocked[node.Id] then return "off" end
	if (state and state.mastery or 0)<TreeTiers.need(node) then return "tier" end
	if #missing(node,unlocked)>0 then return "locked" end
	if (state and state.free or 0)>=node.Cost then return "learn" end
	return "short"
end

-- The panel: the kit's branches in tree order, each with its nodes.
function V.layout(kit,state)
	local tree=Trees[kit]
	if not tree then return nil end
	local def=Fighters[kit]
	local out={kit=kit,title=Text.upper(def and def.Name or kit).."'S TREE",points=state and state.points or 0,free=state and state.free or 0,branches={}}
	local byName={}
	for _,node in tree.Nodes do
		local branch=byName[node.Branch]
		if not branch then branch={name=Text.upper(node.Branch),nodes={}};byName[node.Branch]=branch;table.insert(out.branches,branch) end
		table.insert(branch.nodes,{id=node.Id,name=node.Name,cost=node.Cost,kind=node.Kind,kindLabel=KIND_LABEL[node.Kind] or "",
			major=node.Major==true,item=node.Item,status=V.status(kit,state,node),tier=TreeTiers.of(node),requires=node.Requires})
	end
	-- The grid the panel draws: the tiers as rows, the branches as columns.
	local mastery=state and state.mastery or 0
	out.mastery=mastery
	out.tiers={}
	for t,need in TreeTiers.Need do
		local row={index=t,name=TreeTiers.Names[t],need=need,open=mastery>=need,cells={}}
		for b,branch in out.branches do
			row.cells[b]={}
			for _,node in branch.nodes do if node.tier==t then table.insert(row.cells[b],node) end end
		end
		table.insert(out.tiers,row)
	end
	local nextTier=nil
	for _,row in out.tiers do if not row.open then nextTier=row break end end
	out.nextTier=nextTier
	out.progress=if nextTier then math.clamp(mastery/nextTier.need,0,1) else 1
	out.subtitle=string.format("%d POINTS FREE  •  %d EARNED  •  1 POINT PER %d MASTERY WITH %s",out.free,out.points,Masters.PointEvery,Text.upper(def and def.Name or kit))
	return out
end

-- The strip under the tree for one node: what it does, what answers it,
-- what it needs, and the button.
function V.detail(kit,state,id)
	local node=nodeOf(kit,id)
	if not node then return nil end
	local unlocked=sets(state)
	local status=V.status(kit,state,node)
	local needs=missing(node,unlocked)
	local names={}
	for _,need in needs do
		local other=nodeOf(kit,need)
		table.insert(names,if other then Text.upper(other.Name) else Text.upper(need))
	end
	local head=Text.upper(node.Name).."  •  "..node.Cost.." POINTS  •  TIER "..TreeTiers.Names[TreeTiers.of(node)].."  •  "..(KIND_LABEL[node.Kind] or "")
	if node.Item then head..="  •  KIT OBJECT" end
	local action=nil
	if status=="learn" then action={kind="learn",label="LEARN  •  "..node.Cost.." POINTS"}
	elseif status=="off" then action={kind="on",label="TURN ON"}
	elseif status=="active" then action={kind="off",label="TURN OFF"} end
	local note=nil
	if status=="tier" then
		local def=Fighters[kit]
		note=string.format("TIER %s OPENS AT %d MASTERY WITH %s (NOW %d)",TreeTiers.Names[TreeTiers.of(node)],TreeTiers.need(node),Text.upper(def and def.Name or kit),state and state.mastery or 0)
		if #names>0 then note..="  •  THEN FIRST: "..table.concat(names,", ") end
	elseif status=="locked" then note="FIRST: "..table.concat(names,", ")
	elseif status=="short" then note=string.format("%d MORE POINTS: PLAY DUELS WITH THIS KIT",node.Cost-(state and state.free or 0)) end
	if node.Exclusive then
		local others={}
		for _,other in Trees[kit].Nodes do
			if other.Exclusive==node.Exclusive and other.Id~=node.Id then table.insert(others,Text.upper(other.Name)) end
		end
		local choice="ONE OR THE OTHER: "..table.concat(others,", ")
		note=if note then note.."  •  "..choice else choice
	end
	return {id=node.Id,head=head,shows=node.Shows,counter="ANSWER: "..node.Counter,note=note,status=status,action=action,item=node.Item}
end

return V
