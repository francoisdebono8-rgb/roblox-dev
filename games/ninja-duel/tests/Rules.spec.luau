local Rules=require("../src/Shared/Rules")
local count=0
local function test(name,fn) fn(); count+=1; print("PASS "..name) end
local function actor() return {health=100,chakra=40,state="Neutral",cooldowns={}} end
local spec={Id="Cast",Cost=30,Cooldown=5,Channel=1,Interruptible=true}
test("finite values reject NaN/inf/types",function()
	assert(Rules.finite(1)); assert(not Rules.finite(0/0)); assert(not Rules.finite(math.huge)); assert(not Rules.finite("1"))
end)
test("state/health authority",function()
	for _,state in {"Startup","Active","Recovery","Stunned","Dodging","TechniqueChannel","TechniqueActive","TechniqueRecovery","Defeated"} do
		local a=actor(); a.state=state; assert(not Rules.canAct(a,10))
	end
	local a=actor(); a.health=0; assert(not Rules.canAct(a,10))
end)
test("cost charged on preparation, cooldown survives interruption",function()
	local a=actor(); assert(Rules.technique(a,spec,10,true)); Rules.reserve(a,spec,10)
	assert(a.chakra==10 and a.cooldowns.Cast==15 and a.untilTime==11)
	a.state="Neutral"; assert(not Rules.technique(a,spec,12,true))
	a.chakra=100; assert(not Rules.technique(a,spec,14,true)); assert(Rules.technique(a,spec,15,true))
end)
test("setup and chakra cannot be bypassed",function()
	local a=actor(); assert(not Rules.technique(a,spec,10,false)); a.chakra=29; assert(not Rules.technique(a,spec,10,true))
end)
test("only declared channels interrupt",function()
	local a=actor(); a.state="TechniqueChannel"; a.pending={spec=spec}; assert(Rules.interruptible(a))
	a.state="TechniqueActive"; assert(not Rules.interruptible(a)); a.state="TechniqueChannel"; a.pending={spec={Interruptible=false}}; assert(not Rules.interruptible(a))
end)
test("guard is directional and resource-limited",function()
	local a=actor(); a.state="Guarding"; assert(Rules.isGuard(a,true)); assert(not Rules.isGuard(a,false)); a.chakra=0; assert(not Rules.isGuard(a,true))
end)
test("token bucket limits burst and bounded refill",function()
	local b={tokens=3,time=10}
	for _=1,3 do assert(Rules.consumeToken(b,10,2,3)) end
	assert(not Rules.consumeToken(b,10,2,3)); assert(Rules.consumeToken(b,10.5,2,3)); assert(not Rules.consumeToken(b,10.5,2,3))
	assert(Rules.consumeToken(b,100,2,3)); assert(b.tokens==2)
end)
print(string.format("NinjaDuel pure policy: %d PASS",count))
