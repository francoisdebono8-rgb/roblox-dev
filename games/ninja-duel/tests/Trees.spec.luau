-- The real trees of the beta's eight kits (13/11, DEC-038): points from the
-- kit's mastery, the kit objects a player's ninja earns on its tree (Gaara's
-- gourd, Lee's weights, Kakashi's tanto), the new hooks of Naruto, Gaara, Lee
-- and Kakashi, the tree commands of the profile, and the panel's view.
local H=require("./Harness")
local V=H.V
local SkillBuilds=H.load("Server/SkillBuilds")
local SkillTrees=H.load("Shared/SkillTrees")
local S=H.load("Server/ProfileSchema")
local Masters=H.load("Shared/Masters")
local TreeView=H.load("Shared/TreeView")
local BetaRoster=H.load("Shared/BetaRoster")
local passed=0
local function test(name,fn)
	H.clearWalls()
	local ok,err=pcall(fn)
	H.clearWalls()
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,pa,pb)
	c:relocate(a,pa);c:relocate(b,pb)
	a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
	b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end
local function duel(first,second,kitA,gap)
	local c,a,b,match=H.duel(first,second,{A=kitA})
	gap=gap or 4.5
	place(c,a,b,V.new(0,3,gap/2),V.new(0,3,-gap/2))
	return c,a,b,match
end
local function gated(fighter,nodes) return assert(SkillBuilds.build(fighter,nodes or {},{gated=true})) end
local function free(fighter,nodes) return assert(SkillBuilds.build(fighter,nodes or {})) end

test("every kit of the beta has a real tree: valid, 120-150 SP, three wired majors at least, every node playable",function()
	for _,id in BetaRoster do
		local errors=SkillBuilds.checkTree(id)
		assert(#errors==0,table.concat(errors," | "))
		local design=SkillBuilds.maxCost(id,false)
		assert(design>=120 and design<=150,id.." design max "..design)
		assert(#SkillBuilds.unwired(id)==0,id.." has nodes nobody reads: "..table.concat(SkillBuilds.unwired(id),","))
		local majors=0
		for _,node in SkillTrees[id].Nodes do if node.Major then majors+=1 end end
		assert(majors>=3,id.." has "..majors.." major nodes")
	end
end)

test("the kit objects: Gaara's gourd, Lee's weights and Kakashi's tanto are earned on a player's tree",function()
	local items={}
	for _,id in BetaRoster do for _,entry in SkillBuilds.items(id) do items[entry.item]=id end end
	assert(items.Gourd=="Sand" and items.Weights=="Leaf" and items.Tanto=="Copycat","items: "..tostring(items.Gourd)..tostring(items.Weights)..tostring(items.Tanto))
	-- A player's kit without the node lacks the object; with it, it has it.
	local sand=gated("Sand")
	assert(sand.def.SandShield==nil and table.find(sand.locks,"Gourd"),"the gourd's shield came without the node")
	assert(gated("Sand",{"Gourd"}).def.SandShield~=nil,"the node did not give the shield")
	local lee=gated("Leaf")
	local weights
	for _,spec in lee.def.Techniques do if spec.Id=="RemoveWeights" then weights=spec end end
	assert(weights and weights.Locked==true,"the weights came off without Gai's permission")
	for _,spec in gated("Leaf",{"Weights"}).def.Techniques do if spec.Id=="RemoveWeights" then assert(not spec.Locked,"locked with the node") end end
	assert(gated("Copycat").def.WeaponLocked==true and gated("Copycat",{"Tanto"}).def.WeaponLocked==nil,"the tanto lock")
	-- The prodigies themselves (AI, masters, films) are never gated.
	assert(free("Sand").def.SandShield~=nil and free("Copycat").def.WeaponLocked==nil,"an ungated kit lost its object")
	for _,spec in free("Leaf").def.Techniques do assert(not spec.Locked,"an ungated Lee lost a technique") end
	-- A kit without an object is not touched by the gate.
	assert(#gated("Legion").locks==0,"Naruto has no kit object")
end)

test("in a duel: the locked weights are refused, the sheathed tanto stays, no gourd means no sand charge",function()
	local c,a=duel("Leaf","Lion",gated("Leaf"))
	a.chakra=100
	local ok,why=c:request(a,H.slot(a,"RemoveWeights"))
	assert(not ok and why=="Locked","the weights came off: "..tostring(why))
	c,a=duel("Leaf","Lion",gated("Leaf",{"Weights"}))
	a.chakra=100
	assert(c:request(a,H.slot(a,"RemoveWeights")),"with the node the weights stayed on")
	c,a=duel("Copycat","Lion",gated("Copycat"))
	local drew,reason=c:request(a,"Arm")
	assert(not drew and reason=="Locked" and not a.armed,"the tanto came out without the node")
	c,a=duel("Copycat","Lion",gated("Copycat",{"Tanto"}))
	assert(c:request(a,"Arm") and a.armed,"the tanto stayed in with the node")
	c,a=duel("Sand","Lion",gated("Sand"))
	assert((a.shieldCharges or 0)==0,"sand charges without the gourd")
	c,a=duel("Sand","Lion",gated("Sand",{"Gourd"}))
	assert(a.shieldCharges==3,"the gourd gave "..tostring(a.shieldCharges).." charges")
end)

test("Lee · Falling Weights: the weights he drops crater the floor and knock down a body at his feet",function()
	local function drop(nodes,gap)
		local c,a,b=duel("Leaf","Lion",gated("Leaf",nodes),gap)
		a.chakra=100
		local before=b.health
		assert(c:request(a,H.slot(a,"RemoveWeights")),"the weights stayed on")
		for _=1,60 do H.step(c,.01) end
		return before-b.health,b
	end
	local taken,b=drop({"Weights","HeavyDrop"},4)
	assert(taken>=5,"the drop did not hurt a body at his feet: "..taken)
	assert(b.reaction=="Knockdown" or b.state=="Stunned" or b.reaction~=nil,"the body stayed up")
	local far=drop({"Weights","HeavyDrop"},14)
	assert(far==0,"the drop reached 14 studs: "..far)
	assert(drop({"Weights"},4)==0,"the weights cratered without the node")
end)

test("Naruto · Fox Healing: the Nine-Tails' chakra closes his wounds while it burns",function()
	local function heal(nodes)
		local c,a=duel("Legion","Lion",gated("Legion",nodes),12)
		a.health=30;a.hum.Health=30
		c:awaken(a)
		assert((a.awakenUntil or 0)>c.now,"no awakening")
		local start=a.health
		for _=1,200 do H.step(c,.01) end
		return a.health-start
	end
	assert(heal({"RedChakra","FoxHealing"})>=2.5,"no healing in 2 s")
	assert(heal({"RedChakra"})<.5,"healing without the node")
end)

test("Naruto · It Was a Clone!: right after a substitution E is a free dash back",function()
	local function rush(nodes)
		local c,a,b=duel("Legion","Lion",gated("Legion",nodes))
		assert(c:damage(b,a,5,false,false))
		assert(c:request(a,"Substitute"))
		H.step(c,.16)
		a.chakra=0
		return c:request(a,"Pursuit"),a
	end
	local ok,a=rush({"SwapRush"})
	assert(ok and a.state=="Rush","no free dash after the swap")
	assert(not rush({}),"the base substitution gave a free dash")
end)

test("string cancels of the new trees: Naruto into Shadow Clone, Kakashi into Lightning Cut, only with the node",function()
	local function attempt(fighter,nodes,technique)
		local c,a=duel(fighter,"Lion",gated(fighter,nodes))
		a.chakra=200
		assert(c:request(a,"Attack"),"opening strike refused")
		for _=1,90 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0) then break end end
		return c:request(a,H.slot(a,technique)) and a.state~="Recovery",a
	end
	assert(attempt("Legion",{"CloneCraft","CloneCancel"},"ShadowClone"),"Naruto's string did not cancel into a clone")
	assert(attempt("Copycat",{"Tanto","CutCancel"},"LightningCut"),"Kakashi's string did not cancel into Lightning Cut")
	assert(not attempt("Legion",{"CloneCraft"},"ShadowClone"),"Naruto's string cancelled into a clone without the node")
	assert(not attempt("Copycat",{"Tanto"},"LightningCut"),"Kakashi's string cancelled without the node")
end)

test("points come from the kit's mastery; a node learned goes into the kit's build; on, off, exclusive",function()
	local p=S.new("dev_trees")
	local seq=0
	local function run(kind,args) seq+=1;local out,result=S.apply(p,seq,kind,args);p=out;return result end
	local function fails(kind,args) local ok=pcall(S.apply,p,seq+1,kind,args);return not ok end
	run("chooseStarter",{fighter="Leaf"})
	assert(fails("learnNode",{fighter="Leaf",node="Weights"}),"a node learned with no points")
	local r=run("gainMastery",{fighter="Leaf",amount=110})
	assert(r.points==11 and p.fighters.Leaf.earned==11,"110 mastery gave "..tostring(r.points).." points")
	r=run("learnNode",{fighter="Leaf",node="Weights"})
	assert(r.active and p.fighters.Leaf.selected==S.MainBuild,"the node is not in the build")
	assert(fails("learnNode",{fighter="Leaf",node="HeavyDrop"}),"9 points spent with 1 left")
	assert(fails("learnNode",{fighter="Sand",node="Gourd"}),"a node of a kit not learned")
	for _=1,3 do run("gainMastery",{fighter="Leaf",amount=200}) end
	run("learnNode",{fighter="Leaf",node="HeavyDrop"})
	local nodes=S.selection(p,"Leaf")
	assert(table.find(nodes,"Weights") and table.find(nodes,"HeavyDrop"),"the build lost a node")
	-- Off: what requires it goes off too; on again: only itself.
	run("setNode",{fighter="Leaf",node="Weights",on=false})
	nodes=S.selection(p,"Leaf")
	assert(#nodes==0,"Falling Weights stayed on without the weights")
	run("setNode",{fighter="Leaf",node="Weights",on=true})
	assert(#S.selection(p,"Leaf")==1)
	-- Exclusive: Kakashi's two string cancels, one at a time.
	run("learnKit",{fighter="Copycat",via="purchase",receipt="r1"})
	for _=1,2 do run("gainMastery",{fighter="Copycat",amount=200}) end
	run("learnNode",{fighter="Copycat",node="CutCancel"})
	local second=run("learnNode",{fighter="Copycat",node="FangCancel"})
	assert(not second.active,"two exclusive nodes on at once")
	run("setNode",{fighter="Copycat",node="FangCancel",on=true})
	nodes=S.selection(p,"Copycat")
	assert(table.find(nodes,"FangCancel") and not table.find(nodes,"CutCancel"),"the exclusive swap")
	assert(S.validate(p))
	-- A kit bought brings no point: the tree grows by playing it.
	run("learnKit",{fighter="Sand",via="purchase",receipt="r2"})
	assert(p.fighters.Sand==nil or p.fighters.Sand.earned==0,"a purchase gave points")
	assert(Masters.points(299)==29 and Masters.points(-5)==0 and Masters.points(1e9)==Masters.MaxPoints)
end)

test("the tree panel: statuses, the detail strip and its button",function()
	local state={points=20,free=10,unlocked={"Weights"},active={"Weights"}}
	local layout=TreeView.layout("Leaf",state)
	assert(layout and layout.title=="ROCK LEE'S TREE" and #layout.branches>=3,"layout")
	local seen={}
	for _,branch in layout.branches do for _,node in branch.nodes do seen[node.id]=node end end
	assert(seen.Weights.status=="active" and seen.Weights.item=="Weights","the object node")
	assert(seen.HeavyDrop.status=="learn","Falling Weights should be learnable: "..seen.HeavyDrop.status)
	assert(seen.GateSpeed.status=="locked","Fifth Gate Speed needs Gate Control")
	local d=TreeView.detail("Leaf",state,"HeavyDrop")
	assert(d.action and d.action.kind=="learn" and string.find(d.action.label,"9"),"learn button")
	d=TreeView.detail("Leaf",state,"Weights")
	assert(d.action.kind=="off" and string.find(d.head,"KIT OBJECT"),"turn off an active node")
	d=TreeView.detail("Leaf",state,"GateSpeed")
	assert(d.action==nil and string.find(d.note,"GATE CONTROL"),"what a locked node needs: "..tostring(d.note))
	d=TreeView.detail("Copycat",{points=0,free=0,unlocked={},active={}},"CutCancel")
	assert(string.find(d.note,"PACK CALL"),"the exclusive choice is not said")
	assert(TreeView.layout("Nobody",state)==nil)
end)

print(string.format("NinjaDuel skill trees of the eight kits (DEC-038): %d PASS",passed))
