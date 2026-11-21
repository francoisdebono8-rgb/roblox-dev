-- Every major node changes something (OUTILLEUR, 21/11; DEC-045, step 2):
-- with and without it, the kit a player gets must differ (a technique more, a
-- range, an effect, an object). A major node that changes nothing fails here,
-- with its kit and its name. tools/kits/NodeCheck.luau does the measuring.
local H=require("./Harness")
local NodeCheck=require("../tools/kits/NodeCheck")
local mods={SkillBuilds=H.load("Server/SkillBuilds"),SkillTrees=H.load("Shared/SkillTrees"),BetaRoster=H.load("Shared/BetaRoster"),
	NinjaTree=H.load("Shared/NinjaTree")}
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local result=NodeCheck.run(mods)

test("every major node of every kit tree changes the kit a player gets",function()
	local majors=0
	for _,id in result.order do
		for _,row in result.kits[id] do if row.major then majors+=1 end end
	end
	assert(majors>=8*3,"major nodes found: "..majors)
	for _,line in NodeCheck.lines(result) do print("  "..line) end
	local kits={}
	for _,f in result.failures do if not string.match(f,"^ninja%.") then table.insert(kits,f) end end
	assert(#kits==0,#kits.." major node(s) change nothing: "..table.concat(kits," | "))
end)

test("a node that unlocks a technique or an object: without it, a player lacks it",function()
	for _,id in result.order do
		for _,row in result.kits[id] do
			if row.unlock or row.item then
				local found=false
				for _,c in row.changes do
					local k=NodeCheck.kind(c)
					if k=="technique" or k=="objet" then found=true end
				end
				assert(found,id.."."..row.id.." unlocks "..tostring(row.unlock or row.item).." but the kit without it has it too")
			end
		end
	end
end)

test("every node of the ninja's tree changes what the duel reads (def.Ninja)",function()
	assert(result.ninja and #result.ninja>=10,"ninja nodes: "..(result.ninja and #result.ninja or 0))
	local ninja={}
	for _,f in result.failures do if string.match(f,"^ninja%.") then table.insert(ninja,f) end end
	assert(#ninja==0,table.concat(ninja," | "))
end)

test("the measure itself: a change is found, and named by its kind",function()
	local d=NodeCheck.diff({Techniques={{Id="A",Range=10}},Speed=1},{Techniques={{Id="A",Range=12},{Id="B"}},Speed=1})
	assert(#d==2,"changes: "..#d)
	local kinds={}
	for _,c in d do kinds[c.path]=NodeCheck.kind({path="def."..c.path,before=c.before,after=c.after}) end
	assert(kinds["Techniques.A.Range"]=="nombre" and kinds["Techniques.B"]=="technique",kinds["Techniques.A.Range"])
	assert(#NodeCheck.diff({a={b=1}},{a={b=1}})==0)
end)

print(("Nodes: %d passed"):format(passed))
