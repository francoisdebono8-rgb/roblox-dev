-- Codes (19/11, the CM's proposal « vague 2 » § 3): the CM's list checked
-- line by line (Shared/Codes), a code typed and normalized, redeemed once
-- per player between its dates (ProfileSchema `codes`, command redeemCode),
-- its reward (Ryō, mastery ×2 for a while, a look), and the server's request
-- (Matches RedeemCode: the answer said, no guessing in bulk).
-- Headless; the field in the shop is a Studio check.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Codes=H.load("Shared/Codes")
local Shop=H.load("Shared/Shop")
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")
local Exam=H.load("Shared/Exam")
local function at(y,m,d,h) return Exam.daysFrom(y,m,d)*86400+(h or 12)*3600 end

test("the CM's list: every code is well formed, gives one thing, never power or a Robux look",function()
	local seen={}
	for _,def in Codes.List do
		local ok,why=Codes.check(def,Shop)
		assert(ok,why)
		assert(not seen[def.code],"twice: "..def.code);seen[def.code]=true
		assert(type(def.note)=="string" and #def.note>0,def.code.." has no note")
	end
	-- the checks refuse what they must
	assert(not Codes.check({code="TWO",ryo=10,boostMinutes=5,ends="2026-12-01"},Shop),"two rewards")
	assert(not Codes.check({code="NONE",ends="2026-12-01"},Shop),"no reward")
	assert(not Codes.check({code="lower",ryo=10,ends="2026-12-01"},Shop),"small letters")
	assert(not Codes.check({code="RICH",ryo=50000,ends="2026-12-01"},Shop),"too many Ryō")
	assert(not Codes.check({code="NODATE",ryo=10},Shop),"no end date")
	assert(not Codes.check({code="BACKWARDS",ryo=10,starts="2026-12-05",ends="2026-12-01"},Shop),"starts after it ends")
	for _,item in Shop.Items do
		if item.robux then assert(not Codes.check({code="ROBUX",item=item.id,ends="2026-12-01"},Shop),"a Robux look given by a code: "..item.id) break end
	end
	for _,item in Shop.Items do
		if item.ryo then assert(Codes.check({code="LOOK",item=item.id,ends="2026-12-01"},Shop),"a market look refused: "..item.id) break end
	end
end)

test("what a player types: capitals, no spaces; between its dates",function()
	assert(Codes.normalize(" ninja duel ")=="NINJADUEL" and Codes.normalize("exam1")=="EXAM1")
	assert(Codes.normalize("")==nil and Codes.normalize("NINJA-DUEL")==nil and Codes.normalize(string.rep("A",17))==nil and Codes.normalize(42)==nil)
	local exam=Codes.get("EXAM1")
	assert(not Codes.active(exam,at(2026,11,26)),"open before it starts")
	assert(Codes.active(exam,at(2026,11,27,0)) and Codes.active(exam,at(2026,12,6,23)),"closed on its days")
	local ok,why=Codes.active(exam,at(2026,12,7,0))
	assert(not ok and why=="Code expired")
	assert(#Codes.live(at(2026,11,20))>=1,"no code live now")
end)

test("the profile: a code once, its reward, its dates, a mastery ×2 that stacks",function()
	local p=S.new("dev_codes")
	local function run(kind,args) local np,r=S.apply(p,p.sequence+1,kind,args);p=np;return r end
	local function fails(kind,args,want)
		local ok,err=pcall(S.apply,p,p.sequence+1,kind,args)
		assert(not ok,kind.." "..tostring(args.code).." was accepted")
		if want then assert(string.find(tostring(err),want),"why: "..tostring(err)) end
	end
	local now=at(2026,11,28)
	local r=run("redeemCode",{code="NINJADUEL",now=now})
	assert(r.ryo==300 and p.wallet.ryo==300 and r.total==300,"the Ryō")
	fails("redeemCode",{code="NINJADUEL",now=now+60},"already used")
	fails("redeemCode",{code="NOPE",now=now},"not found")
	fails("redeemCode",{code="EXAM1",now=at(2026,12,10)},"expired")
	r=run("redeemCode",{code="FIRSTDUEL",now=now})
	assert(r.minutes==15 and p.codes.boostUntil==now+15*60,"the mastery ×2")
	assert(S.validate(p))
	local bad=S.copy(p);bad.codes.used["bad code"]=1
	assert(not S.validate(bad),"a malformed code kept")
	bad=S.copy(p);bad.codes.boostUntil=-1
	assert(not S.validate(bad))
	-- a code that gives a look: owned, not worn
	local look=nil
	for _,item in Shop.Items do if item.ryo then look=item;break end end
	table.insert(Codes.List,{code="LOOKTEST",item=look.id,ends="2026-12-20",note="test"});Codes.ById.LOOKTEST=Codes.List[#Codes.List]
	r=run("redeemCode",{code="LOOKTEST",now=now})
	assert(r.item==look.id and p.style.owned[look.id] and p.style.equipped[look.slot]~=look.id,"the look")
	assert(string.find(Codes.thanks(r,Shop),"IS YOURS"))
	table.remove(Codes.List);Codes.ById.LOOKTEST=nil
	assert(Codes.thanks({code="NINJADUEL",ryo=300})=="CODE NINJADUEL: +300 RYŌ" and Codes.thanks({code="FIRSTDUEL",minutes=15})=="CODE FIRSTDUEL: MASTERY ×2 FOR 15 MIN")
	-- an older profile without the record
	assert(S.validate(S.new("dev_none")))
end)

-- The server: Progression and Matches on a memory store (as tests/Shop.spec).
local getService=H.envBase.game.GetService
local owners=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "server-"..owners end} end
	return getService(g,name)
end
H.workspace.GetServerTimeNow=function() return 9000 end
H.envBase.task={delay=function() end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Progression=H.load("Server/Progression")
local Matches=H.load("Server/Matches")

test("the server: a code typed in the shop is said back, a mastery ×2 doubles the duels, no guessing in bulk",function()
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local now=at(2026,11,28)
	Progression.now=function() return now end
	local sent={}
	local m=Matches.new({FireClient=function(_,player,data) sent[player]=data end})
	local player={UserId=812,Name="P812",DisplayName="P812",Parent=H.Players}
	m:selection(player)
	assert(Progression.load(player),"the profile did not load")
	local s=m.sessions[player]
	local function send(action,extra)
		local payload={action=action,epoch=s.epoch}
		for k,v in extra or {} do payload[k]=v end
		m:request(player,payload)
	end
	send("ChooseStarter",{player="Leaf"})
	s.lastCode=nil
	send("RedeemCode",{code="ninjaduel"})
	assert(sent[player].codeOk==true and sent[player].notice=="CODE NINJADUEL: +300 RYŌ" and sent[player].kits.ryo==300,"the answer: "..tostring(sent[player].notice))
	-- two tries in two seconds: the second one is not even read
	send("RedeemCode",{code="MYNINJA"})
	assert(sent[player].notice=="CODE NINJADUEL: +300 RYŌ","a try inside the gap was read")
	s.lastCode=-10
	send("RedeemCode",{code="NINJADUEL"})
	assert(sent[player].codeOk==false and sent[player].notice=="CODE ALREADY USED","the refusal: "..tostring(sent[player].notice))
	-- mastery ×2 from a code
	assert(not Progression.boosted(player))
	s.lastCode=-10
	send("RedeemCode",{code="FIRSTDUEL"})
	assert(Progression.boosted(player) and sent[player].kits.codeBoost==900,"the mastery ×2")
	now+=901
	assert(not Progression.boosted(player),"the mastery ×2 outlived its time")
	-- eight wrong codes in a row: a minute's wait
	for i=1,8 do s.lastCode=-10;send("RedeemCode",{code="WRONG"..i}) end
	assert(s.codeLock and s.codeLock>os.clock(),"no wait after eight wrong codes")
	s.lastCode=-10
	send("RedeemCode",{code="MYNINJA"})
	assert(sent[player].notice~="CODE MYNINJA: +150 RYŌ","a code read during the wait")
	s.codeLock=0;s.lastCode=-10
	send("RedeemCode",{code="MYNINJA"})
	assert(sent[player].notice=="CODE MYNINJA: +150 RYŌ","after the wait: "..tostring(sent[player].notice))
	Config.Progression.Enabled=false
end)

print(string.format("NinjaDuel codes (the CM's list): %d PASS",passed))
