-- The CM's words for the eight prodigies (DEC-043, step 1, 20/11): their
-- titles on screen, one « pourquoi ce kit » sentence and what only this kit
-- does (Shared/KitTexts). Checked here: the eight are all there, a title is
-- never a name from the anime, a sheet is one sentence, the three at the gate
-- say the same as their cards (Shared/Inspirations), and every « only » claim
-- that a number can prove is true in Shared/Fighters.
-- Headless; how the titles look on the screens is a Studio check.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local K=H.load("Shared/KitTexts")
local Fighters=H.load("Shared/Fighters")
local Masters=H.load("Shared/Masters")
local Inspirations=H.load("Shared/Inspirations")
local Text=H.load("Shared/Text")
local FIELDS={"title","tag","line","with","why","only"}

test("the eight prodigies, each with a title, a tag, a card and a sheet",function()
	assert(#K.Order==#Masters.Kits,"not eight: "..#K.Order)
	for _,id in Masters.Kits do assert(table.find(K.Order,id),id.." has no words") end
	local titles,initials={},{}
	for _,id in K.Order do
		local t=K.of(id)
		assert(Fighters[id] and t,id.." is not a fighter with words")
		for _,field in FIELDS do assert(type(t[field])=="string" and #t[field]>0,id.." has no "..field) end
		assert(string.match(t.title,"^THE [A-Z][A-Z ]+$"),id.."'s title is not « THE ... » in capitals: "..t.title)
		assert(not titles[t.title],"two prodigies are "..t.title);titles[t.title]=id
		assert(t.tag==string.upper(t.tag) and #t.tag<=24,id.."'s tag is too long or not in capitals: "..t.tag)
		local letter=K.initial(id)
		assert(#letter==1 and letter~="T","the badge of "..id.." says « "..letter.." »")
		assert(not initials[letter],id.." and "..tostring(initials[letter]).." share the badge "..letter);initials[letter]=id
	end
	assert(K.of("Flashstep").title=="THE YELLOW FLASH","François's choice (19/11): Minato is THE YELLOW FLASH")
end)

test("« pourquoi ce kit » is one sentence, « only » fits a card",function()
	for _,id in K.Order do
		local t=K.of(id)
		assert(#t.why>=40 and #t.why<=140,id.."'s sentence is "..#t.why.." characters")
		assert(string.match(t.why,"[%.!]$"),id.."'s sentence has no end")
		assert(not string.find(string.sub(t.why,1,-2),"[%.!%?] "),id.."'s « why » is more than one sentence: "..t.why)
		assert(#t.only>=40 and #t.only<=150,id.."'s « only » is "..#t.only.." characters")
		assert(#t.line<=130 and #t.with<=80,id.."'s card is too long")
	end
end)

test("no name from the anime in a title, a tag, a card or a sheet (technique names stay, option B)",function()
	local banned={"NARUTO","SASUKE","LEE","NEJI","GAARA","KAKASHI","ITACHI","MINATO","UZUMAKI","UCHIHA","HYUGA","HATAKE","NAMIKAZE",
		"SHARINGAN","BYAKUGAN","NINE%-TAILS","SHUKAKU","KYUBI","COPY NINJA","ROOKIE OF THE YEAR","NUMBER ONE"}
	for _,id in K.Order do
		for _,field in FIELDS do
			local s=Text.upper(K.of(id)[field])
			for _,word in banned do
				assert(not string.find(s,"%f[%w]"..word.."%f[%W]"),id.."'s "..field.." says "..word..": "..s)
			end
		end
	end
end)

test("the three at the gate say what their cards say (Shared/Inspirations)",function()
	for _,id in Masters.Starters do
		local card,t=Inspirations.of(id),K.of(id)
		assert(card,id.." has no card")
		for _,field in {"title","line","with"} do
			assert(card[field]==t[field],id.."'s "..field.." differs: « "..tostring(card[field]).." » / « "..t[field].." »")
		end
	end
end)

test("the name on screen: a title for a prodigy, his own name for anyone else",function()
	for _,id in K.Order do
		assert(K.name(id)==K.of(id).title and K.fullName(id)==K.of(id).title,id.." is shown as "..K.name(id).." / "..K.fullName(id))
		assert(K.tag(id)==K.of(id).tag,id.."'s tag")
		assert(K.idOf(Fighters[id].Name)==id,"« "..Fighters[id].Name.." » is not found back as "..id)
	end
	assert(K.idOf("Rock Lee")=="Leaf","Rock Lee is Leaf")
	assert(K.sub("Leaf")=="AGE 13  •  TAIJUTSU ONLY","Leaf's line under his name: "..K.sub("Leaf"))
	assert(K.sub("Lion")=="AGE 12  •  LIGHTNING IN HAND","Lion's line under his name: "..K.sub("Lion"))
	for id,def in Fighters do
		if type(def)=="table" and def.Name and not K.of(id) then
			assert(K.name(id)==Text.upper(def.Name),id.." (not a prodigy) is shown as "..K.name(id))
			assert(K.fullName(id)==Text.upper(def.FullName or def.Name),id.." (not a prodigy) has lost his full name")
			assert(K.of(id)==nil and K.sub(id)==string.format("AGE %d  •  %s",def.Age or 13,Text.upper(def.Title or "")),id.."'s line changed")
		end
	end
	assert(K.name("Nobody")=="NOBODY" and K.sub("Nobody")=="" and K.idOf("Nobody")==nil,"an unknown id")
end)

test("every « only » that a number can prove is true in Shared/Fighters",function()
	local function best(field,sign)
		local top,who,tie=nil,nil,false
		for _,id in K.Order do
			local v=Fighters[id][field]*sign
			if top==nil or v>top then top,who,tie=v,id,false elseif v==top then tie=true end
		end
		assert(not tie,"two prodigies share the "..(if sign>0 then "most " else "least ")..field)
		return who
	end
	-- Legion: the most health and chakra of the eight; a crowd of ten clones
	assert(best("Health",1)=="Legion" and best("Chakra",1)=="Legion","Legion has not the most health and chakra")
	local bodies=Fighters.Legion.Bodies
	local crowd=bodies and bodies.clone and bodies.clone.Crowd
	assert(crowd==10,"Legion's crowd is "..tostring(crowd).." clones, the sheet says ten")
	-- Leaf: the fastest legs; the gates up to the fifth, paid with his health
	assert(best("Speed",1)=="Leaf","Leaf has not the fastest legs")
	local gates=Fighters.Leaf.Awakening.Gates
	assert(gates and gates.Max==5 and (Fighters.Leaf.Awakening.HealthDrain or 0)>0,"Leaf's gates")
	-- Sand: the slowest; a shield of his own that guards everywhere but behind
	assert(best("Speed",-1)=="Sand","Sand is not the slowest")
	local shield=Fighters.Sand.SandShield
	assert(shield and shield.Cover>-1 and shield.Cover<0,"Sand's shield should cover the sides, not behind")
	-- Flashstep: the least health
	assert(best("Health",-1)=="Flashstep","Flashstep has not the least health")
	-- one kit alone has each of these
	local function alone(id,has)
		for _,other in K.Order do assert((has(Fighters[other])==true)==(other==id),other.." has "..id.."'s trick") end
	end
	alone("Copycat",function(d) return d.Copy~=nil end)
	assert(Fighters.Copycat.Copy.Uses==1 and Fighters.Copycat.Copy.Life==15,"Copycat's copy: one cast, 15 s")
	alone("Mirage",function(d) return d.Awakening and d.Awakening.Tsukuyomi~=nil end)
	assert(Fighters.Mirage.Awakening.Tsukuyomi==1.5,"Mirage's illusion holds 1.5 s")
	alone("Flashstep",function(d) return d.Awakening and d.Awakening.FlashPursuit==true end)
	alone("Leaf",function(d) return d.Awakening and d.Awakening.Gates~=nil end)
	alone("Sand",function(d) return d.SandShield~=nil end)
end)

print(string.format("NinjaDuel kit texts (the CM's titles and sheets): %d PASS",passed))
