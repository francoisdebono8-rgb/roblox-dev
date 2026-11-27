-- The vol plané (27/11, François: « créer des vraies animations de coups subis
-- selon la situation : vol plané, recul, etc. »). Headless: which blows send
-- the body flying laid out (Config.Flight: fast along the floor, never a light
-- string's), and how it ends: on its back, sliding, down a while before the
-- usual get-up (Server/Brawler). The clips (Knockback.Flung, Knockdown.Flung,
-- tools/blender/p3_kits) exist for the 8 kits. The look of it is a Studio check.
local H=require("./Harness")
local fs=require("@lune/fs")
local V=H.V
local Brawler=H.load("Server/Brawler")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function duel()
	local c,a,b=H.duel("Leaf","GentleFist")
	c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-4))
	H.step(c,.05)
	return c,a,b
end

test("a heavy blow fast along the floor flings; a light string's or a slow one does not",function()
	local c,a,b=duel()
	b.attackName="Heavy"
	Brawler.react(c,a,"Knockback",V.new(0,18,Config.Flight.Speed+2),.55,b)
	assert(a.flung==true,"a heavy blow at "..(Config.Flight.Speed+2).." did not fling")
	b.attackName="Light3"
	Brawler.react(c,a,"Knockback",V.new(0,18,Config.Flight.Speed+10),.55,b)
	assert(a.flung==nil,"a light string's last blow flung")
	b.attackName=nil
	Brawler.react(c,a,"Knockback",V.new(0,12,Config.Flight.Speed-10),.55,b)
	assert(a.flung==nil,"a slow knockback flung")
	Brawler.react(c,a,"HitStun",V.new(0,0,Config.Flight.Speed+20),.3,b)
	assert(a.flung==nil,"a hit-stun flung")
end)

test("the vol plané lands on its back: knocked down, sliding, down longer than a skid",function()
	local c,a,b=duel()
	b.attackName=nil
	Brawler.react(c,a,"Knockback",V.new(0,16,Config.Flight.Speed+4),.55,b)
	assert(a.airborne,"not in the air")
	local landed
	for _=1,300 do
		H.step(c,.01)
		if not a.airborne then landed=c.now;break end
	end
	assert(landed,"it never came down")
	assert(a.reaction=="Knockdown" and a.groundPose=="Knockdown","it landed "..tostring(a.reaction).." instead of on its back")
	assert(a.reactionUntil-landed>=Config.Flight.Down*.5,"not down for long: "..tostring(a.reactionUntil-landed))
	local v=a.reactionVelocity or V.zero
	assert(V.new(v.X,0,v.Z).Magnitude>1,"no slide along the floor")
end)

test("a body knocked back slowly still skids back onto its feet",function()
	local c,a,b=duel()
	b.attackName="Light3"
	Brawler.react(c,a,"Knockback",V.new(0,10,30),.45,b)
	for _=1,300 do H.step(c,.01);if not a.airborne then break end end
	assert(a.reaction~="Knockdown","a light knockback knocked down")
end)

test("the 8 kits have the flight and the landing",function()
	local all=""
	for i=36,48 do local path="src/Client/AuthoredJutsu"..i..".luau";if fs.isFile(path) then all..=fs.readFile(path) end end
	for _,k in {"Legion","Lion","Leaf","GentleFist","Sand","Copycat","Mirage","Flashstep"} do
		assert(string.find(all,'["'..k..'.Knockback.Flung"]',1,true),k..": no Knockback.Flung")
		assert(string.find(all,'["'..k..'.Knockdown.Flung"]',1,true),k..": no Knockdown.Flung")
	end
end)

print("Flight: "..passed.." passed")
