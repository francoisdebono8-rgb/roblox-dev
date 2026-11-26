-- His kit in the street (26/11, passe 3, DEC-055, HUB-002; François : « qu'on
-- puisse utiliser nos attaques et tout quand on se balade, ça y est pas » ;
-- his choice: the first blow on a player is a challenge, the riposte starts
-- the duel). Headless: the rules, the moves on the walker's body (its kit's
-- clips) for himself and for the others; the blows landing in the village
-- are a Studio check.
local H=require("./Harness")
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local CFrame,Vector3=roblox.CFrame,roblox.Vector3
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Rules=H.load("Shared/HubFight")
local Authored=H.load("Client/AuthoredMotion")
local Body=H.load("Client/HubBody")
local BetaRoster=H.load("Shared/BetaRoster")

test("every move is a clip of every kit, on the walker's body",function()
	for _,kit in BetaRoster do
		for name,spec in Rules.Moves do
			assert(Body.clipName(Authored,kit,spec.clip),kit..": no clip for "..name.." ("..spec.clip..")")
		end
	end
	-- a blow has its contact inside its clip
	for name,spec in Rules.Moves do
		if spec.contact then
			local length=Authored.length(Body.clipName(Authored,"Lion",spec.clip))
			assert(spec.contact<length,name..": the blow lands after its clip ("..spec.contact.." / "..length..")")
		end
	end
end)

test("the light chain: 1, 2, 3, then again; a pause starts it over",function()
	assert(Rules.chain(nil,nil,5)==1)
	assert(Rules.chain(1,5,5.3)==2 and Rules.chain(2,5.3,5.6)==3 and Rules.chain(3,5.6,5.9)==1,"the chain")
	assert(Rules.chain(2,5,5+Rules.CHAIN+.01)==1,"a pause")
end)

test("the server grants a move at its pace, never a flood",function()
	local last={}
	assert(Rules.grant(last,"Light1",1))
	assert(not Rules.grant(last,"Light1",1.05),"the same blow again too soon")
	assert(Rules.grant(last,"Light2",1.06),"the next of the chain")
	assert(not Rules.grant(last,"Nope",2),"an unknown move")
	local n=0
	for i=0,40 do if Rules.grant(last,if i%2==0 then "Dodge" else "Guard",10+i*.02) then n+=1 end end
	assert(n<=Rules.RATE,"a flood: "..n)
end)

test("the challenge by a blow: struck, a riposte within the window starts the duel",function()
	local challenges,cooldowns={},{}
	assert(Rules.answer(challenges,cooldowns,1,2,10)=="challenge","the first blow")
	challenges[2]={from=1,at=10}
	assert(Rules.answer(challenges,cooldowns,2,1,12)=="accept","his riposte")
	assert(Rules.answer(challenges,cooldowns,2,1,10+Rules.CHALLENGE_WINDOW+1)=="challenge","too late: a new challenge")
	cooldowns[Rules.pairKey(1,2)]=20
	assert(Rules.answer({},cooldowns,1,2,25)=="wait","the same two, too soon")
	assert(Rules.answer({},cooldowns,1,2,20+Rules.CHALLENGE_COOLDOWN+1)=="challenge")
	assert(Rules.pairKey(5,3)==Rules.pairKey(3,5))
end)

test("the blow's box is in front of him",function()
	local cf,size=Rules.box(CFrame.new(0,3,0),Rules.Moves.Heavy)
	assert(cf.Position.Z<-1 and math.abs(cf.Position.X)<1e-6,"in front (−Z)")
	assert(math.abs(size.Z-Rules.Moves.Heavy.reach)<1e-4,"as deep as the reach")
end)

test("his body plays the move over the walk; the guard holds; the others see it once",function()
	local b=Body.new(Authored);b.kit="Leaf"
	local c=Body.choose(b,{now=10.1,dt=1/60,speed=12,vy=0,grounded=true,kit="Leaf",act="Light2",actAt=10})
	assert(c.move=="Light2" and math.abs(c.t-.1)<1e-6,"the blow while walking")
	c=Body.choose(b,{now=15,dt=1/60,speed=12,vy=0,grounded=true,kit="Leaf",act="Light2",actAt=10})
	assert(c.move=="Walk.F","the blow played through: the walk again")
	c=Body.choose(b,{now=15,dt=1/60,speed=0,vy=0,grounded=true,kit="Leaf",act="Guard",actAt=nil})
	assert(c.move=="Guard","the guard held")
	c=Body.choose(b,{now=15.2,dt=1/60,speed=0,vy=-10,grounded=false,kit="Leaf",act="Air1",actAt=15})
	assert(c.move=="Air1","the air strike")
	local w={}
	local f=Body.crowdFacts(w,1,1/60,Vector3.zero,true,"none",1,"Leaf",nil,0,"Heavy",4)
	assert(f.act==nil,"what he did before this screen saw him is not replayed")
	f=Body.crowdFacts(w,2,1/60,Vector3.zero,true,"none",1,"Leaf",nil,0,"Heavy",5)
	assert(f.act=="Heavy" and f.actAt==2,"his heavy blow, seen")
	f=Body.crowdFacts(w,2.1,1/60,Vector3.zero,true,"none",1,"Leaf",nil,0,"Heavy",5)
	assert(f.actAt==2,"seen once")
	f=Body.crowdFacts(w,3,1/60,Vector3.zero,true,"none",1,"Leaf",nil,0,"Dodge",6)
	assert(f.act=="Dash.F","his dash, its clip")
end)

test("the server takes the moves on its own remote, and starts with the game",function()
	local server=fs.readFile("src/Server/HubFight.luau")
	assert(string.find(server,'remote.Name="HubAct"',1,true) and string.find(server,'impactRemote.Name="HubImpact"',1,true),"the remotes")
	assert(string.find(server,"if not walking(player) then return false end",1,true),"only a walker in the village")
	assert(string.find(server,'intro=="fight" or intro=="create"',1,true),"not in the bandit's fight nor at the gate's card")
	local main=fs.readFile("src/Server/Main.server.luau")
	assert(string.find(main,"require(script.Parent.HubFight).start(matches)",1,true),"not started")
	local move=fs.readFile("src/Client/HubMove.luau")
	assert(string.find(move,"HubFightClient",1,true),"the walk does not step the street's fight")
end)

print(string.format("NinjaDuel his kit in the street (26/11): %d PASS",passed))
