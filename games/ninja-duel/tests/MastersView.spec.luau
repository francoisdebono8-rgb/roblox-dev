-- The roster and the result screen on the masters' path (beta loop 13/11,
-- DEC-037; Shared/MastersView). Headless: what each kit says and what the
-- stage button does, for a new player, a player with kits, a master ready.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local V=H.load("Shared/MastersView")
local Masters=H.load("Shared/Masters")
local BetaRoster=H.load("Shared/BetaRoster")

test("off: every kit plays as before (no tag, no lock, the usual button)",function()
	for _,id in BetaRoster do
		local t=V.tablet(nil,id)
		assert(t.status=="open" and not t.locked and t.tag=="",id)
		local a=V.action(nil,id)
		assert(a.kind=="play" and a.label==nil and a.note==nil,id)
	end
end)

test("loading: nothing starts until the kits are known",function()
	local a=V.action({state="loading",owned={},mastery={},masters={}},"Leaf")
	assert(a.kind=="wait" and a.label)
end)

test("a new player: the three starters are taken, the five others are tried",function()
	local kits={state="ready",owned={},mastery={},masters={},needStarter=true}
	local starters,others=0,0
	for _,id in BetaRoster do
		local a=V.action(kits,id)
		local t=V.tablet(kits,id)
		if Masters.isStarter(id) then
			starters+=1
			assert(a.kind=="choose" and a.label=="TAKE THIS KIT" and t.tag=="START" and not t.locked,id)
		else
			others+=1
			assert(a.kind=="try" and t.locked and t.tag=="LOCKED",id)
			assert(string.find(a.note,"NARUTO") and string.find(a.note,"SASUKE") and string.find(a.note,"LEE"),"the note does not name the starters: "..a.note)
		end
	end
	assert(starters==3 and others==5,starters.." "..others)
end)

test("with Lee learned: his kit plays and says where it leads; Neji waits for mastery, then teaches",function()
	local kits={state="ready",owned={Leaf=true},mastery={Leaf=120},starter="Leaf",selected="Leaf",masters={}}
	for id in Masters.Map do kits.masters[id]={ready=false,best=0} end
	kits.masters.GentleFist={ready=false,best=120}
	local lee=V.action(kits,"Leaf")
	assert(lee.kind=="play" and string.find(lee.note,"MASTERY 120") and string.find(lee.note,"NEJI") and string.find(lee.note,"GAARA"),lee.note)
	local t=V.tablet(kits,"Leaf")
	assert(not t.locked and math.abs(t.progress-120/Masters.Need)<1e-6,"Lee's mastery bar")
	local neji=V.action(kits,"GentleFist")
	assert(neji.kind=="try" and string.find(neji.note,"BEST: 120") and string.find(neji.note,tostring(Masters.Need)),neji.note)
	assert(neji.product==nil,"nothing is sold while Roblox sells nothing")
	-- A kit Roblox sells: the roster offers to buy it (the button sends BuyKit).
	kits.masters.Sand={ready=false,best=120,product=9002}
	assert(V.action(kits,"Sand").product==9002,"the kit on sale has no product")
	-- Mastery reached: Neji's duel, fought with Lee.
	kits.mastery.Leaf=Masters.Need
	kits.masters.GentleFist={ready=true,via="Leaf"}
	local ready=V.action(kits,"GentleFist")
	assert(ready.kind=="master" and ready.label=="DUEL THE MASTER" and ready.via=="Leaf","Neji's duel: "..tostring(ready.kind))
	assert(V.tablet(kits,"GentleFist").tag=="MASTER")
end)

test("the result screen: mastery earned, the masters who now teach, a kit learned",function()
	local line=V.result({gained=true,amount=110,mastery=230,need=300,fighter="Leaf"})
	assert(line and string.find(line,"+110 MASTERY") and string.find(line,"230 / 300"),tostring(line))
	assert(not string.find(line,"WILL TEACH"),line)
	line=V.result({gained=true,amount=110,mastery=340,need=300,fighter="Leaf"},{owned={Leaf=true,Sand=true}})
	assert(string.find(line,"NEJI") and not string.find(line,"GAARA"),"a master already learned is still announced: "..line)
	line=V.result({gained=true,amount=80,mastery=300,need=300,fighter="Leaf",learned="GentleFist"})
	assert(string.find(line,"NEJI'S KIT IS YOURS"),line)
	assert(V.result(nil)==nil and V.result({gained=false})==nil,"practice says nothing")
end)

test("every master's kit leads somewhere and every kit is led to",function()
	for _,id in BetaRoster do
		assert(Masters.isKit(id),id.." is not on the path")
		if Masters.Map[id] then assert(#Masters.Map[id].from>0,id) end
	end
	local led=0
	for _,id in BetaRoster do if #V.leadsTo(id)>0 then led+=1 end end
	assert(led>=5,"too few kits lead to a master: "..led)
end)

print(string.format("NinjaDuel masters' path on the roster (beta loop): %d PASS",passed))
