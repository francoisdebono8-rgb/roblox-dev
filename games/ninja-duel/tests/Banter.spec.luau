-- The CM's street words (passe commune 2, DEC-054, 26/11; Shared/Banter): the
-- villagers, the market, the forest's bandit, the racket, the eight in the
-- street, the gate and the creation screen, and the interface's under-lines;
-- (passe 3) the Ōtsutsuki's tournament: the scenes, his final, Konoha's goal.
-- Checked: every list has lines; a bubble line fits a phone (48); never a
-- name or word from the anime, never death or blood; the eight inspirations
-- all speak in the four moments; the creation buttons fit a button; each
-- interface line says less than the line it replaces; pick() never says the
-- same line twice in a row; every story scene has its bubbles and Story.lines
-- reads them; the Ōtsutsuki speaks before, on a win, on a loss; the goal's
-- head fits the band and keeps its slots. Headless; how they look is the DESIGN's (Studio).
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local B=H.load("Shared/Banter")
local KitTexts=H.load("Shared/KitTexts")
local Text=H.load("Shared/Text")
local Story=H.load("Shared/Story")

local BANNED={"NARUTO","SASUKE","LEE","NEJI","GAARA","KAKASHI","ITACHI","MINATO","UZUMAKI","UCHIHA","HYUGA","HATAKE",
	"NAMIKAZE","SHARINGAN","BYAKUGAN","NINE%-TAILS","COPY NINJA","HOKAGE","DATTEBAYO","BELIEVE IT","BLOOD","KILL","DEAD","DIE"}
local function clean(s,who)
	local up=Text.upper(s)
	for _,word in BANNED do
		if string.find(up,"%f[%w]"..word.."%f[%W]") then error(who.." says "..word..": "..s) end
	end
end
local BUBBLE=48
local function bubble(s,who)
	assert(type(s)=="string" and #s>0,who.." is empty")
	assert(utf8.len(s)<=BUBBLE,who.." is too long for a bubble ("..utf8.len(s).."): "..s)
	clean(s,who)
end
local function lines(list,who,min)
	assert(type(list)=="table" and #list>=(min or 1),who.." has too few lines")
	local seen={}
	for i,s in list do
		bubble(s,who.."["..i.."]")
		assert(not seen[s],who.." says the same line twice: "..s); seen[s]=true
	end
end

test("the villagers speak in every moment, short, and never twice the same",function()
	for _,moment in {"idle","runPast","wallRun","jutsuNear","watchDuel","afterWin","afterLoss","clumsy"} do
		lines(B.Passersby[moment],"Passersby."..moment,2)
	end
	assert(#B.Passersby.idle>=8,"the street needs more idle lines to feel alive")
	lines(B.Merchants,"Merchants",4)
end)

test("the forest's bandit has a whole short fight to say",function()
	bubble(B.Bandit.name,"Bandit.name")
	lines(B.Bandit.block,"Bandit.block")
	for _,field in {"beforeFight","guarded","dodged","won","leaves"} do bubble(B.Bandit[field],"Bandit."..field) end
	for _,field in {"hurt","hits","defeated"} do lines(B.Bandit[field],"Bandit."..field,2) end
end)

test("the racket's thugs speak from the stop to the end",function()
	lines(B.Thugs.stop,"Thugs.stop")
	lines(B.Thugs.lost,"Thugs.lost")
	for _,field in {"threat","paid","fight","won"} do bubble(B.Thugs[field],"Thugs."..field) end
end)

test("the eight inspirations greet, wait, win and lose in their own voice",function()
	for _,kitId in KitTexts.Order do
		local who=B.Inspirations[kitId]
		assert(who,"no words for "..kitId)
		for _,moment in {"greet","idle","win","lose"} do bubble(who[moment],kitId.."."..moment) end
	end
	for kitId in B.Inspirations do assert(table.find(KitTexts.Order,kitId),"an unknown inspiration: "..kitId) end
end)

test("the gate and the creation screen: a sign, the guards, buttons that fit",function()
	bubble(B.Gate.sign,"Gate.sign")
	lines(B.Gate.guards,"Gate.guards",3)
	bubble(B.Creation.title,"Creation.title"); bubble(B.Creation.sub,"Creation.sub")
	for _,field in {"random","confirm","enter"} do
		local s=B.Creation[field]
		assert(type(s)=="string" and s==string.upper(s) and utf8.len(s)<=14,"Creation."..field.." does not fit a button: "..tostring(s))
	end
	for id,s in B.Creation.sections do assert(s==string.upper(s) and utf8.len(s)<=10,"section "..id..": "..s) end
	lines(B.Creation.quips,"Creation.quips",4)
end)

test("each interface line says it shorter than the line it replaces",function()
	local n=0
	for id,u in B.Ui do
		n+=1
		assert(type(u.at)=="string" and string.find(u.at,"%.luau:%d"),id.." has no place (file:line)")
		assert(type(u.was)=="string" and type(u.say)=="string" and #u.say>0,id.." has no words")
		assert(utf8.len(u.say)<utf8.len(u.was),id.." is not shorter: "..u.say)
		assert(utf8.len(u.say)<=80,id.." is still long: "..u.say)
		clean(u.say,"Ui."..id)
	end
	assert(n>=15,"the interface's under-lines are not all there ("..n..")")
end)

test("the Ōtsutsuki's tournament: every scene has its bubbles, in his words",function()
	for id in Story.Scenes do
		local list=B.Story[id]
		assert(type(list)=="table" and #list>=2,"scene "..id.." has no bubbles")
		for i,b in list do
			bubble(b.who,"Story."..id.."["..i.."].who"); bubble(b.line,"Story."..id.."["..i.."]")
		end
		assert(Story.lines(id,B)==list,"Story.lines does not read the scene "..id)
	end
	for id in B.Story do assert(Story.Scenes[id],"an unknown scene: "..id) end
	local his=0
	for _,b in B.Story.invitation do if b.who==Story.BOSS.name then his+=1 end end
	assert(his>=3,"the invitation is his to give")
end)

test("the Ōtsutsuki speaks before the final, when he wins, when he loses",function()
	for _,field in {"before","win","lose"} do lines(B.Otsutsuki[field],"Otsutsuki."..field,2) end
	bubble(B.Tournament.name,"Tournament.name"); bubble(B.Tournament.winner,"Tournament.winner")
end)

test("Konoha's goal: a short head, a line under it, the slots kept",function()
	for _,kind in {"seals","exam","final","weekly"} do
		local g=B.Goal[kind]
		assert(g and type(g.head)=="string" and type(g.sub)=="string","no goal for "..kind)
		local head=string.format(g.head,8,8); local sub=string.format(g.sub,"THE EXAM HALL")
		assert(utf8.len(head)<=28,"Goal."..kind..".head is too long: "..head)
		assert(utf8.len(sub)<=36,"Goal."..kind..".sub is too long: "..sub)
		assert(head==Text.upper(head) and sub==Text.upper(sub),"Goal."..kind.." is not in capitals")
		clean(head,"Goal."..kind); clean(sub,"Goal."..kind)
	end
	assert(select(2,string.gsub(B.Goal.seals.head,"%%d",""))==2,"the seals head lost its count")
	assert(string.find(B.Goal.exam.sub,"%%s"),"the exam line lost the proctor's place")
end)

test("pick() never says the same line twice in a row",function()
	math.randomseed(7)
	local rng={NextInteger=function(_,a,b) return math.random(a,b) end} -- a Random's face, headless
	local last
	for _=1,200 do
		local line=B.pick(B.Passersby.runPast,last,rng)
		assert(line~=last,"twice: "..tostring(line)); last=line
	end
	assert(B.pick({"only"},"only",rng)=="only","a list of one still answers")
	assert(B.pick("a line",nil,rng)=="a line","a single line passes through")
	assert(B.pick({},nil,rng)==nil,"an empty list says nothing")
end)

print(("Banter: %d passed"):format(passed))
