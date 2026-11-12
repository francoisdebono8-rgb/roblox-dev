-- The bots' variety and their fight's place (QA test of b822ee5, 12/11, four
-- AI-against-AI films of 95 s): Sasuke 9 Wall Dives, Itachi 20 blades,
-- Naruto 12 Multi Shadow Clone, Neji never placing his 64 Palms or his
-- Rotation, the fights sliding to the trees at the edge, Sasuke-Gaara with no
-- K.O. Replayed here on the same four pairs (seeded rolls, the game's damage
-- scale): each round ends in a K.O. inside 95 s; no bot throws more than
-- four blades in ten seconds or more than twelve in a round; no jutsu takes
-- more than half of a bot's jutsu; Neji places his 64 Palms and his
-- Rotation in every round; the pair fights near the middle. Headless: no
-- trees, no wall run (Studio films for those); tests/AIVariety.sim.luau
-- prints the counts.
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
		NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
H.load("Shared/Config").DamageScale=H.GameDamageScale
local Copy=H.load("Server/Copy")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end

test("a move used to its limit waits; a jutsu not placed yet is owed after a while",function()
	local bot=AI.new({},{},3)
	assert(not bot:tired("Tool",10))
	bot:used("Tool",10);bot:used("Tool",14)
	assert(bot:tired("Tool",15),"two blades in four seconds: a third one did not wait")
	assert(not bot:tired("Tool",24.5),"the blade limit outlived its ten seconds")
	bot.roundStart=0
	assert(not bot:owed("Rotation",5),"a jutsu was owed five seconds into the round")
	assert(bot:owed("Rotation",AI.Variety.OweAfter+1),"a jutsu never placed was not owed")
	bot:used("Rotation",AI.Variety.OweAfter+2)
	assert(not bot:owed("Rotation",AI.Variety.OweAfter+3),"a placed jutsu stayed owed")
end)

local function label(c,a,action)
	if string.sub(action,1,9)=="Technique" then
		local slot=tonumber(string.sub(action,10))
		local spec=slot and (Copy.slotSpec(c,a,slot) or a.def.Techniques[slot])
		return spec and spec.Id or action
	elseif action=="Tool" then return "Tool" end
	return nil
end
local function round(x,y,seed)
	H.clearWalls()
	local c,a,b,match=H.duel(x,y)
	c:relocate(a,V.new(0,3,24));c:relocate(b,V.new(0,3,-24))
	local log={[a]={},[b]={}}
	local request=c.request
	c.request=function(self,actor,action,...)
		local ok,r=request(self,actor,action,...)
		local name=ok and log[actor] and label(self,actor,action)
		if name then table.insert(log[actor],{name=name,at=self.now}) end
		return ok,r
	end
	local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
	local t,far,samples=0,0,0
	while match.phase=="Duel" and t<95 do
		one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
		local mid=(a.root.Position+b.root.Position)/2-match.origin
		far+=V.new(mid.X,0,mid.Z).Magnitude;samples+=1
	end
	return {a=a,b=b,log=log,time=t,ko=a.health<=0 or b.health<=0,centre=far/samples}
end

local PAIRS={{"Lion","Sand"},{"Legion","GentleFist"},{"Leaf","Flashstep"},{"Copycat","Mirage"}}
local SEEDS=3
local results={}
for _,pair in PAIRS do
	for seed=1,SEEDS do table.insert(results,{pair=pair,seed=seed,r=round(pair[1],pair[2],seed)}) end
end

test("every round of the four filmed pairs ends in a K.O. inside 95 s",function()
	for _,entry in results do
		assert(entry.r.ko,string.format("%s vs %s (seed %d): no K.O. in %.0f s",entry.pair[1],entry.pair[2],entry.seed,entry.r.time))
	end
end)

test("no bot throws more than four blades in ten seconds, nor twelve in a round",function()
	for _,entry in results do
		for actor,list in entry.r.log do
			local times={}
			for _,u in list do if u.name=="Tool" then table.insert(times,u.at) end end
			assert(#times<=12,string.format("%s (vs %s, seed %d) threw %d blades",actor.fighterId,actor.target.fighterId,entry.seed,#times))
			for i=1,#times do
				local n=0
				for j=i,#times do if times[j]-times[i]<=10 then n+=1 end end
				assert(n<=4,string.format("%s (seed %d) threw %d blades in ten seconds",actor.fighterId,entry.seed,n))
			end
		end
	end
end)

test("no jutsu takes more than half of a bot's jutsu in a round (three allowed)",function()
	for _,entry in results do
		for actor,list in entry.r.log do
			local counts,total={},0
			for _,u in list do if u.name~="Tool" then counts[u.name]=(counts[u.name] or 0)+1;total+=1 end end
			for name,n in counts do
				assert(n<=math.max(3,total*.5),string.format("%s (seed %d): %s is %d of %d jutsu",actor.fighterId,entry.seed,name,n,total))
			end
		end
	end
end)

test("Neji places his 64 Palms and his Rotation in every round against Naruto",function()
	for _,entry in results do
		if entry.pair[2]=="GentleFist" then
			local placed={}
			for _,u in entry.r.log[entry.r.b] do placed[u.name]=true end
			assert(placed.SixtyFourPalms,"seed "..entry.seed..": no 64 Palms")
			assert(placed.Rotation,"seed "..entry.seed..": no Rotation")
		end
	end
end)

test("the pair fights near the middle, not at the trees",function()
	for _,pair in PAIRS do
		local sum=0
		for _,entry in results do if entry.pair==pair then sum+=entry.r.centre end end
		local mean=sum/SEEDS
		assert(mean<=65,string.format("%s vs %s: the fight's centre is %.0f studs from the middle on average (trees from 92)",pair[1],pair[2],mean))
	end
end)

print(string.format("NinjaDuel AI variety (QA 12/11): %d PASS",passed))
