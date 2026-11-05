-- Mission FEEL (issue #44), AVANT defect 3: a button that does nothing must
-- say why. A press refused inside the body's own move is kept for a moment
-- (Config.Late); if the body never comes free in time it is lost, and the
-- quiet line says BUSY. Every refusal is counted per round for analytics.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if not ok then error(name..": "..tostring(err),0) end
	passed+=1;print("PASS "..name)
end

test("a dodge pressed deep in a heavy is buffered, then lost with a quiet BUSY",function()
	local c,a,b=H.duel("GentleFist","Flashstep")
	a.playerInput=true
	assert(c:request(a,"Heavy"))
	-- Into the heavy's active part: the dodge is refused (committed) and kept.
	for _=1,20 do H.step(c,.01);if a.state=="Active" then break end end
	local ok,reason=c:request(a,"Dodge")
	assert(ok==false and reason=="Committed",("dodge in the heavy: %s %s"):format(tostring(ok),tostring(reason)))
	assert(a.latePress,"the refused dodge was not buffered")
	do
		-- Hold the body past the buffer window (a long recovery).
		local late=a.latePress
		a.state="Recovery";a.untilTime=c.now+1
		for _=1,40 do H.step(c,.01);a.state="Recovery";a.untilTime=c.now+1 end
		assert(a.latePress==nil,"the buffered press never expired")
		assert(a.quiet=="BUSY" and (a.quietUntil or 0)>c.now,"no quiet BUSY for the lost press")
		assert(a.pressStats and a.pressStats.lost==1,"the lost press was not counted")
		local _=late
	end
	local _=b
end)

test("the quiet line is per player and short",function()
	local c,a=H.duel("GentleFist","Flashstep")
	c:quiet(a,"RECHARGING")
	assert(a.quiet=="RECHARGING" and a.quietUntil-c.now<=.61)
	local serial=a.quietSerial
	c:quiet(a,"BUSY")
	assert(a.quietSerial==serial+1)
end)

print(("FeelPress: %d passed"):format(passed))
