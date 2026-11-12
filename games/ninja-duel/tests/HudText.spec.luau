-- The fight screen's words (QA test of b822ee5, 12/11): « SōSHūHA » and
-- « GōRIKI SENPū » (string.upper leaves the long vowels small), « KNOCK
-- AWAY • E TO CHASE » and « E / SPACE – CHASE » at once, « BUSY — STILL IN
-- YOUR MOVE » mid-screen in autopilot, « NARUTO UZUMAKI RENDAN » small on two
-- lines on Naruto's card 4. Headless: the words and the rules that pick
-- them; their size on screen is a Studio check.
local H=require("./Harness")
local fs=require("@lune/fs")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Text=H.load("Shared/Text")
local Fighters=H.load("Shared/Fighters")
local BetaRoster=H.load("Shared/BetaRoster")
local SealJutsu=H.load("Shared/SealJutsu")

test("capitals keep the long vowels and the accents",function()
	assert(Text.upper("Sōshūha")=="SŌSHŪHA",Text.upper("Sōshūha"))
	assert(Text.upper("Gōriki Senpū")=="GŌRIKI SENPŪ",Text.upper("Gōriki Senpū"))
	assert(Text.upper("Ōtsutsuki ā ē ī")=="ŌTSUTSUKI Ā Ē Ī")
	assert(Text.upper("Chûnin à l'école")=="CHÛNIN À L'ÉCOLE",Text.upper("Chûnin à l'école"))
	assert(Text.upper("12 ÷ 3")=="12 ÷ 3","the division sign changed")
	assert(Text.upper(nil)=="")
end)

test("no name on the beta's screen keeps a small long vowel once in capitals",function()
	local function check(name)
		local up=Text.upper(name)
		for lower in Text.LONG do assert(not string.find(up,lower,1,true),name.." stays "..up) end
	end
	for _,id in BetaRoster do
		local def=Fighters[id]
		check(def.Name);check(def.FullName or "");check(def.Title or "")
		for _,spec in def.Techniques do check(spec.Name) end
		for _,spec in def.SealJutsu or {} do check(spec.Name) end
	end
	for _,list in SealJutsu do if type(list)=="table" then for _,spec in list do if type(spec)=="table" and spec.Name then check(spec.Name) end end end end
end)

test("the screen's capitals go through Text.upper",function()
	for _,path in {"src/Client/UI.luau","src/Client/CupScreen.luau","src/Client/LobbyPanel.luau","src/Client/TouchControls.luau"} do
		local src=fs.readFile(path)
		local n=0
		for line in string.gmatch(src,"[^\n]+") do
			-- (the private code box and a one-letter initial stay ASCII)
			if string.find(line,"string.upper(",1,true) and not string.find(line,"codeBox.Text",1,true) and not string.find(line,"widget.initial",1,true) then
				n+=1;print("  "..path..": "..line)
			end
		end
		assert(n==0,path.." still writes "..n.." name(s) with string.upper")
	end
end)

test("a jutsu card names it short enough for its card: Naruto's card 4 reads UZUMAKI RENDAN",function()
	local rendan
	for _,spec in Fighters.Legion.Techniques do if spec.Id=="NarutoRendan" then rendan=spec end end
	assert(rendan and Text.upper(rendan.CardName or rendan.Name)=="UZUMAKI RENDAN","Naruto's card 4 is "..tostring(rendan and (rendan.CardName or rendan.Name)))
	for _,id in BetaRoster do
		for _,spec in Fighters[id].Techniques do
			local card=spec.CardName or spec.Name
			assert(#card<=20,id.." card « "..card.." » is "..#card.." letters (two small lines on its card)")
		end
	end
	local src=fs.readFile("src/Server/Matches.luau")
	assert(string.find(src,"card=spec.CardName",1,true),"the snapshot does not send the short name")
	assert(string.find(fs.readFile("src/Client/UI.luau"),"Text.upper(tech.card or tech.name)",1,true),"the card does not take the short name")
end)

test("the chase is said once: the hint stays quiet while the cue says it",function()
	local UI=H.load("Client/UI")
	assert(UI.cueNamesChase("KNOCK AWAY • E TO CHASE"))
	assert(UI.cueNamesChase("BLADE • E TO PURSUE"))
	assert(UI.cueNamesChase("THROWN • × TO CHASE"),"the pad's cue")
	assert(not UI.cueNamesChase("PARRY") and not UI.cueNamesChase("") and not UI.cueNamesChase(nil))
	assert(string.find(fs.readFile("src/Client/UI.luau"),"h.pursuit>0 and not UI.cueNamesChase(self.cue.Text)",1,true),"the chase hint ignores the cue")
end)

test("no quiet reason for a fighter the player does not drive (autopilot, a watched match)",function()
	H.workspace.GetServerTimeNow=function() return 4000 end
	local World=H.load("Server/World")
	World.arena=function() end
	World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
	local Matches=H.load("Server/Matches")
	local m=Matches.new({FireClient=function() end})
	local player={UserId=91,Name="P91",DisplayName="P91",Parent=H.Players}
	m:selection(player)
	assert(m:start(player,"Lion","Sand"))
	local s=m.sessions[player]
	s.combat:quiet(s.human,"BUSY")
	assert(m:view(s,s,s.human,s.bot).human.quiet=="BUSY","the player's own refused press says nothing")
	s.autopilot=true
	assert(m:view(s,s,s.human,s.bot).human.quiet==nil,"autopilot: BUSY on screen")
	s.autopilot=nil;s.spectate=true
	assert(m:view(s,s,s.human,s.bot).human.quiet==nil,"a watched match: BUSY on screen")
end)

print(string.format("NinjaDuel fight screen words (QA 12/11): %d PASS",passed))
