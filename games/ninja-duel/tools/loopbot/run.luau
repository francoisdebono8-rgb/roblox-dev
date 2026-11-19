-- The loop robot's report (OUTILLEUR, 19/11). From games/ninja-duel:
--   lune run tools/loopbot/run.luau            the three starters
--   lune run tools/loopbot/run.luau Leaf       one of them
--   lune run tools/loopbot/run.luau --json     the reports as JSON (for the analytics later)
-- Exit code 1 when a step of the loop breaks.
local process=require("@lune/process")
local serde=require("@lune/serde")
local Bot=require("./LoopBot")

local kits,json={},false
for _,arg in process.args do
	if arg=="--json" then json=true else table.insert(kits,arg) end
end
if #kits==0 then kits={"Legion","Lion","Leaf"} end

local reports,ok={},true
for _,kit in kits do
	local r=Bot.run(kit)
	ok=ok and r.ok
	table.insert(reports,r)
	if not json then print(Bot.text(r));print("") end
end
if json then
	-- (the result's progress keeps only plain values)
	print(serde.encode("json",reports,true))
end
process.exit(if ok then 0 else 1)
