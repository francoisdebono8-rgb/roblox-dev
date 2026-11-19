-- The loop of a new player, played by the loop robot (OUTILLEUR, 19/11, plan
-- § 4 OUTILLEUR 1; tools/loopbot/LoopBot): arrival, inspiration, outfit, the
-- first minute up to a real hit on the partner and its duel, what the result
-- screen gets, a look bought at the market, a node of the tree, for each of
-- the three starters. Fails when a step breaks; prints the estimated play
-- time until the first hit and the duels until the first purchase and node.
-- Headless (real Matches, Progression on a memory store, Tutorial, Combat on
-- harness rigs): the screens, Konoha's paths and a real player's pace are the
-- Studio run (tools/loopbot/README.md).
local Bot=require("../tools/loopbot/LoopBot")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end

local reports={}
for _,kit in {"Leaf","Lion","Legion"} do
	test("the loop with "..kit..": every step, from the gate to a node of the tree",function()
		local r=Bot.run(kit)
		reports[kit]=r
		print(Bot.text(r))
		assert(r.ok,"broken at « "..tostring(r.failed).." »: "..tostring(r.steps[#r.steps] and r.steps[#r.steps].detail))
		local ids={}
		for _,st in r.steps do table.insert(ids,st.id) end
		assert(table.concat(ids,",")=="arrivee,inspiration,tenue,duel,gains,marche,arbre","the steps: "..table.concat(ids,","))
		-- the first hit is a real one, landed within the first minute's prompts
		assert(r.firstHit.simulated and r.firstHit.simulated>0 and r.firstHit.simulated<45,"the first hit: "..tostring(r.firstHit.simulated))
		assert(r.firstHit.total>r.firstHit.simulated,"the estimate lost its walks and screens")
		assert(r.loop.market.duels>=1 and r.loop.node.duels>=1,"the loop counted no duel")
	end)
end

test("the estimate follows Konoha's walk speed and map, and the plan's target",function()
	local walk,run=Bot.walkSpeeds()
	assert(walk>0 and run>walk,"the speeds read from HubClient: "..tostring(walk).." / "..tostring(run))
	for _,kit in {"Leaf","Lion","Legion"} do
		local w=Bot.walks(kit)
		assert(w.toDoor>0 and w.toHome>0,kit..": no walk from the gate or to his home")
		assert(math.abs(w.homeSeconds-w.toHome/walk)<.1,kit..": the walk is not at walk speed")
	end
	-- (plan § 1) Sasuke's home is about 22 s of walking from the door; the
	-- first duel is asked at the door (Studio 19/11): the estimate leaves it out
	local lion=Bot.walks("Lion")
	assert(lion.homeSeconds>15 and lion.homeSeconds<30,"Sasuke's walk: "..tostring(lion.homeSeconds).." s")
	for _,kit in {"Leaf","Lion","Legion"} do
		assert(Bot.walks(kit).doorSeconds<5,kit..": the inspirations are no longer by the gate")
	end
	assert(Bot.Target==60,"the plan's target is 60 s")
end)

print(("Loop: %d passed"):format(passed))
