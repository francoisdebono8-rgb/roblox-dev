-- The kits' fingerprint (OUTILLEUR, 20/11, tools/kits): every prodigy of the
-- beta gets one, with numbers that mean something, in its three versions.
local H=require("./Harness")
local KitPrint=require("../tools/kits/KitPrint")
local mods={Fighters=H.load("Shared/Fighters"),Attacks=H.load("Shared/Attacks"),Combo=H.load("Shared/BanglaCombo"),
	BetaRoster=H.load("Shared/BetaRoster"),SkillBuilds=H.load("Server/SkillBuilds"),Config=H.load("Shared/Config"),
	NinjaTree=H.load("Shared/NinjaTree")}
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local print_=KitPrint.compute(mods)
test("every prodigy of the beta has a fingerprint",function()
	assert(#print_.order==#mods.BetaRoster,"kits: "..#print_.order)
	for _,id in print_.order do
		local k=print_.kits[id].versions.prodige
		assert(k.string.count>=4 and k.string.dps>0,id..": no string")
		assert(k.firstHit>0 and k.firstHit<1,id..": first hit "..tostring(k.firstHit))
		assert(k.reach>3 and k.reach<20,id..": reach "..tostring(k.reach))
		-- the run as the game moves (DEC-044): Movement.SprintSpeed x SprintScale
		local sprint=mods.Config.Movement.SprintSpeed*(mods.Fighters[id].SprintScale or 1)
		assert(math.abs(k.move.run-sprint)<.01,id..": run "..tostring(k.move.run).." vs "..sprint)
		assert(k.move.walk>0 and k.move.run>k.move.walk,id..": runs slower than he walks")
		assert(k.body.health>0,id..": health")
	end
end)
test("the string follows Brawler: four hits, five for Lee and Naruto, Light3 last",function()
	assert(#KitPrint.string({})==4 and KitPrint.string({})[4]=="Light3")
	local five=KitPrint.string({StringLength=5})
	assert(#five==5 and five[3]=="Light4" and five[4]=="Light5" and five[5]=="Light3",table.concat(five,","))
end)
test("a player's kit and the full tree come from SkillBuilds",function()
	for _,id in print_.order do
		local e=print_.kits[id]
		assert(e.versions.depart and e.versions.arbre,id..": versions")
		assert(e.tree.nodes>0,id..": no node stacked")
	end
end)
test("a technique a player has not earned is listed apart, never counted",function()
	local def={Name="X",Techniques={{Id="Open",Damage=10,Cooldown=5},{Id="Shut",Damage=40,Cooldown=2,Locked=true}}}
	local k=KitPrint.kit(def,mods.Attacks,mods.Config)
	assert(k.jutsu.count==1 and k.jutsu.dps==2,"counted "..k.jutsu.count.." / "..k.jutsu.dps)
	assert(k.jutsu.locked[1]=="Shut")
end)
test("the five natures, from the ninja tree's contract, on every kit of the full tree",function()
	local N=mods.NinjaTree
	for _,id in print_.order do
		local e=print_.kits[id]
		for _,nature in N.Natures do
			local n=assert(e.natures and e.natures[nature],id..": no "..nature)
			assert(#n.carriers>=1 and n.carriers[1]=="blade",id.." "..nature..": the third hit carries it")
		end
		-- at most once every Gap seconds, stronger with the mastery
		local fire=e.natures.Fire
		assert(math.abs(fire.burnDps-N.Infusion.Fire.Burn*N.Infusion.Strong/N.Infusion.Gap)<1e-3,id..": burn "..fire.burnDps)
		assert(e.natures.Lightning.frozen>0 and e.natures.Earth.guardDps>0 and e.natures.Water.slowed>0,id..": effects")
	end
	-- the wind: a thrown blade flies further; the blade's last hit throws the
	-- body further (Server/NinjaArts.gust), so a kit without a throw keeps that
	local tool=mods.Fighters.Leaf.ToolMastery
	if not (tool and (tool.Kind=="kunai" or tool.Kind=="shuriken")) then
		assert(print_.kits.Leaf.natures.Wind.kunaiRange==1,"Lee has no kunai to carry the wind")
	end
	assert(print_.kits.Leaf.natures.Wind.push>1,"Lee's last hit carries the wind")
	assert(print_.kits.Legion.natures.Wind.kunaiRange>1,"Naruto's kunai carries the wind")
end)
test("the node that transforms a technique is listed, and a kit may have none",function()
	for _,id in print_.order do
		local tree=print_.kits[id].tree
		if tree then
			assert(type(tree.transform)=="table",id..": the transform list")
			for _,t in tree.transform do assert(mods.SkillBuilds.node(id,t.id).Transform==true,id.."."..t.id) end
		end
	end
end)
print(("KitPrint: %d passed"):format(passed))
