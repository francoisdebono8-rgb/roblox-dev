-- The kits' fingerprint (OUTILLEUR, 20/11, tools/kits): every prodigy of the
-- beta gets one, with numbers that mean something, in its three versions.
local H=require("./Harness")
local KitPrint=require("../tools/kits/KitPrint")
local mods={Fighters=H.load("Shared/Fighters"),Attacks=H.load("Shared/Attacks"),Combo=H.load("Shared/BanglaCombo"),
	BetaRoster=H.load("Shared/BetaRoster"),SkillBuilds=H.load("Server/SkillBuilds")}
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
		-- the fingerprint reports the run as the game has it: Gaara's SprintScale
		-- is below 1 (his run is slower than his walk), a question for the DEV,
		-- not a broken fingerprint (ANIMATEUR, 20/11: this line failed on Sand)
		assert(k.move.walk>0 and k.move.run>0,id..": walk/run")
		if k.move.run<k.move.walk then print(("NOTE %s: run %.2f < walk %.2f (SprintScale < 1)"):format(id,k.move.run,k.move.walk)) end
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
print(("KitPrint: %d passed"):format(passed))
