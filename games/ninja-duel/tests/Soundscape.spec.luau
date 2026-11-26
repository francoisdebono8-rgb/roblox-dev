-- The village's sounds (26/11, passe 3, DEC-055, AMB-001; François : « son
-- ambiance et tout, ça y est pas » ; his choice: a soft music and the
-- street's sounds). Headless: the bank's data and the rules that pick what
-- is heard; hearing them is a Studio check (each sound proven loaded there).
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local SoundBank=H.load("Shared/SoundBank")
local HubMap=H.load("Shared/HubMap")
local Soundscape=H.load("Client/Soundscape")

test("the bank: a playlist per state, every sound measured and levelled",function()
	for _,state in {"forest","konoha","duel","final"} do
		local list=SoundBank.Music[state]
		assert(list and #list>=2,state..": a playlist of two tracks at least")
	end
	local seen={}
	for _,entry in SoundBank.all() do
		local t=entry.sound
		assert(string.match(t.id,"^rbxassetid://%d+$"),entry.key..": an asset id")
		assert(not seen[t.id],entry.key..": the same sound twice in the bank")
		seen[t.id]=true
		assert(type(t.loudness)=="number" and t.loudness>0,entry.key..": its loudness measured")
		assert(t.volume>0 and t.volume<=10,entry.key..": a volume Roblox takes ("..t.volume..")")
		assert(math.abs(t.volume*t.loudness-SoundBank.LEVEL[t.layer])<1e-6 or t.volume==10,entry.key..": brought to its layer's level")
		assert(t.source and t.length and t.length>0,entry.key..": its source and length")
	end
	-- the music stays under the combat's hits (they peak at 100-300)
	for state,list in SoundBank.Music do for _,t in list do assert(t.volume*t.loudness<=80,state..": the music louder than the hits") end end
end)

test("the state: the forest, Konoha, a duel, the final",function()
	assert(Soundscape.state({phase="Selection"},"forest")=="forest")
	assert(Soundscape.state({phase="Selection"},"create")=="forest")
	assert(Soundscape.state({phase="Selection"},nil)=="konoha")
	assert(Soundscape.state({phase="Duel"},"fight")=="duel","the bandit's fight is a duel")
	assert(Soundscape.state({phase="Result",site={street=true}},nil)=="duel")
	assert(Soundscape.state({phase="Duel",site={final=true}},nil)=="final")
	assert(Soundscape.state({phase="Duel",final=true},nil)=="final")
	assert(Soundscape.state({phase="Selection",final=true},nil)=="konoha","after the final, the village again")
	assert(Soundscape.state(nil,nil)=="konoha")
end)

test("the street's ambience: every place has its mix, a duel lowers it",function()
	for _,place in HubMap.Places do
		assert(Soundscape.Mix[place.id],place.id..": no ambience")
		for key in Soundscape.Mix[place.id] do assert(SoundBank.Ambience[key],place.id..": "..key.." is not in the bank") end
	end
	local market=Soundscape.mix("Market","konoha")
	assert(market.walla==1 and market.woods==0,"the market's crowd")
	local duel=Soundscape.mix("Market","duel")
	assert(math.abs(duel.walla-Soundscape.DUEL_STREET)<1e-9,"a duel lowers the street")
	local forest=Soundscape.mix("Market","forest")
	assert(forest.woods==1 and forest.walla==0,"the intro is the woods, wherever")
	assert(Soundscape.mix(nil,"konoha").birds>0,"nowhere: the birds")
end)

test("the fades and the playlists",function()
	assert(Soundscape.ease(0,1,.5,1)==.5)
	assert(Soundscape.ease(.9,1,.5,1)==1,"the fade stops at its target")
	assert(Soundscape.ease(1,0,.25,2)==.5)
	local list={{id="a"},{id="b"},{id="c"}}
	for i=0,9 do assert(Soundscape.draw(list,list[2],i/10)~=list[2],"the same track twice in a row") end
	assert(Soundscape.draw({list[1]},list[1],.5)==list[1],"a lone track plays again")
	assert(Soundscape.draw({},nil,.5)==nil)
end)

print(string.format("NinjaDuel sounds (26/11): %d PASS",passed))
