-- The CM's words for playing (step 3, DEC-047, 21/11; Shared/PlayTexts): the
-- first combat's prompts, the things to do alone, the titles to earn.
-- Checked: every prompt of Server/Coach has its words and they fit a fight
-- with any prodigy's jutsu; every thing to do has a name, a line and a
-- button; the titles are unique, short, never a name from the anime, the
-- exam's two say what Shared/Exam gives, the natures cover Shared/NinjaTree,
-- the heirs cover the eight prodigies, the reference to 800 is TreeTiers'.
-- Headless; how they look on screen is the DESIGN's (Studio).
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local T=H.load("Shared/PlayTexts")
local Coach=H.load("Server/Coach")
local Fighters=H.load("Shared/Fighters")
local KitTexts=H.load("Shared/KitTexts")
local Exam=H.load("Shared/Exam")
local NinjaTree=H.load("Shared/NinjaTree")
local TreeTiers=H.load("Shared/TreeTiers")
local Text=H.load("Shared/Text")

local BANNED={"NARUTO","SASUKE","LEE","NEJI","GAARA","KAKASHI","ITACHI","MINATO","UZUMAKI","UCHIHA","HYUGA","HATAKE",
	"NAMIKAZE","SHARINGAN","BYAKUGAN","NINE%-TAILS","COPY NINJA","BLOOD","KILL","DEAD"}
local ALLOWED={["DEAD EYE"]=true} -- an archery word, not a death
local function clean(s,who)
	local up=Text.upper(s)
	for _,word in BANNED do
		if string.find(up,"%f[%w]"..word.."%f[%W]") and not ALLOWED[up] then error(who.." says "..word..": "..s) end
	end
end

test("every prompt of the first combat has its words, short enough for a fight",function()
	for _,prompt in Coach.Prompts do
		local words=T.Coach[prompt.id]
		assert(words,"no words for the prompt "..prompt.id)
		for _,field in {"title","done","touch"} do assert(type(words[field])=="string" and #words[field]>0,prompt.id.." has no "..field) end
		assert(#words.title<=26,prompt.id.."'s prompt is long: "..words.title)
		assert(words.done==string.upper(words.done) and #words.done<=12,prompt.id.."'s tick: "..words.done)
		assert(#words.touch<=32,prompt.id.."'s touch line: "..words.touch)
		clean(words.title,prompt.id)
	end
	for id in T.Coach do assert(Coach.ById[id],"words for a prompt the coach does not have: "..id) end
	-- filled with any prodigy's jutsu and tool, the prompt stays on one line
	for _,kitId in KitTexts.Order do
		for _,spec in Fighters[kitId].Techniques do
			local title=T.coachTitle("signature",{jutsu=spec.CardName or spec.Name})
			assert(#title<=40 and not string.find(title,"{"),kitId..": "..title)
		end
	end
	assert(T.coachTitle("tool",{tool="kunai"})=="Too far? Throw your kunai","the tool prompt: "..T.coachTitle("tool",{tool="kunai"}))
	assert(T.coachTitle("nothing")==nil and T.coachDone("nothing")=="NICE","an unknown prompt")
	assert(#T.FirstWin.head<=14 and #T.FirstWin.line<=60,"the first win")
end)

test("the things to do alone: a name, where, a line and a button",function()
	local n=0
	for id,a in T.Activities do
		n+=1
		for _,field in {"name","where","line","cta"} do assert(type(a[field])=="string" and #a[field]>0,id.." has no "..field) end
		assert(a.cta==string.upper(a.cta) and #a.cta<=10,id.."'s button: "..a.cta)
		assert(#a.line<=80,id.."'s line: "..a.line)
		local filled=T.activity(id,"Leaf")
		assert(not string.find(filled.name..filled.line,"{"),id.." keeps a blank: "..filled.name)
		assert(#filled.name<=28,id.."'s name is long: "..filled.name)
		clean(filled.name.." "..filled.line,id)
	end
	assert(n>=6,"the six things of the plan (dummies, race, targets, challenge, duel, street duel)")
	assert(T.activity("Challenge","Leaf").name=="THE HARD WORKER'S CHALLENGE",T.activity("Challenge","Leaf").name)
	assert(string.format(T.MasteryLine,40)=="+40 MASTERY")
end)

test("the inspirations' dares in the street and the ends of a race",function()
	for _,kitId in KitTexts.Order do
		local line=T.ChallengeLines[kitId]
		assert(type(line)=="string" and #line>=15 and #line<=60,kitId.."'s dare: "..tostring(line))
		clean(line,kitId)
		assert(not string.find(Text.upper(line),"BELIEVE IT",1,true),kitId.." uses a catchphrase from the anime")
	end
	local Solo=H.load("Shared/Solo")
	for kitId in Solo.Challenge.lines do assert(T.ChallengeLines[kitId],"no dare for "..kitId) end
	for _,why in {"teleport","time","floor","left","quit","far"} do
		local s=T.RaceEnds[why]
		assert(type(s)=="string" and s==string.upper(s) and #s<=36,"the end « "..why.." »: "..tostring(s))
	end
end)

test("the titles: unique, short, how to earn each, never a name from the anime",function()
	local seen,ids={},{}
	for _,t in T.Titles do
		assert(type(t.id)=="string" and not ids[t.id],"title id "..tostring(t.id));ids[t.id]=true
		assert(t.title==string.upper(t.title) and #t.title<=26,t.id.."'s title: "..t.title)
		assert(not seen[t.title],"two titles are "..t.title);seen[t.title]=true
		assert(type(t.how)=="string" and #t.how>=10 and #t.how<=90 and string.match(t.how,"%.$"),t.id.."'s how: "..tostring(t.how))
		assert(type(t.earned)=="string",t.id.." has no earned rule")
		clean(t.title,t.id)
		assert(T.ById[t.id]==t,t.id.." is not in ById")
	end
	assert(#T.Titles>=30,#T.Titles.." titles")
	-- the exam's two are the ones Shared/Exam gives
	assert(T.ById.ExamPassed.title==Exam.PASSED and T.ById.ExamTop3.title==Exam.TOP,"the exam's titles")
	-- one per nature of the ninja's tree
	for _,nature in NinjaTree.Natures do
		local found=false
		for _,t in T.Titles do if t.nature==nature then found=true end end
		assert(found,"no title for the "..nature.." nature")
	end
	-- one heir per prodigy, at the top tier of his tree
	for _,kitId in KitTexts.Order do
		local t=T.ById["TitleHeir"..kitId]
		assert(t and t.title==KitTexts.name(kitId).."'S HEIR" and string.find(t.how,tostring(TreeTiers.Need[3]),1,true),kitId.."'s heir")
	end
end)

test("the shop's earned titles (Shared/CatalogStyle) all have the CM's words, with the same rule",function()
	local Style=H.load("Shared/CatalogStyle")
	local inShop={}
	for _,item in Style.Items do
		if item.slot=="title" and not item.none then
			inShop[item.id]=true
			local t=T.ById[item.id]
			assert(t,"the shop's title "..item.id.." ("..tostring(item.name)..") has no words in PlayTexts")
			assert(t.earned==item.earned,item.id..": the rule is "..tostring(item.earned).." in the shop, "..t.earned.." here")
			assert(not t.new,item.id.." is counted already: not new")
		end
	end
	-- a title not marked new is one the game already counts (the shop or the exam)
	for _,t in T.Titles do
		if not t.new and t.earned~="exam" then assert(inShop[t.id],t.id.." is not new but the shop does not have it") end
	end
end)

print(string.format("NinjaDuel play texts (the CM's prompts, things to do, titles): %d PASS",passed))
