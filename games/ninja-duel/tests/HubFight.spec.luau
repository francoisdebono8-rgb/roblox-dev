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
local Instance,Enum=roblox.Instance,roblox.Enum
H.envBase.Instance=H.envBase.Instance or roblox.Instance
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

-- (26/11, seen in the game: after the gate's card the walker had no joint to
-- pose, Roblox's walk showed and the blows did not) the joints looked for again
test("a rebuilt or half-built character gets its joints back",function()
	local body=fs.readFile("src/Client/HubBody.luau")
	assert(string.find(body,"if not any or not self.j[any].Parent then self.j=joints(character) end",1,true),"the joints are not looked for again")
end)

test("a blow turns to the body or dummy right there, not past it",function()
	local from=Vector3.new(0,3,0)
	local look=Vector3.new(-.87,0,-.49)
	local dummy=Vector3.new(0,4,-4.2)
	local dir=Rules.aim(from,look,{dummy})
	assert(dir and dir.Z<-.99,"the dummy 60 degrees off his look: "..tostring(dir))
	-- behind him or too far: where he looks
	local away=Rules.aim(from,look,{Vector3.new(0,3,6),Vector3.new(-20,3,-11)})
	assert(away and math.abs(away.X-look.Unit.X)<1e-3,"turned to something out of reach")
	-- the nearest of two
	local near=Rules.aim(from,Vector3.new(0,0,-1),{Vector3.new(1,3,-6),Vector3.new(-1,3,-3)})
	assert(near.X<0,"not the nearest")
	assert(Rules.aim(from,Vector3.new(0,-1,0),{})==nil,"looking straight down")
end)

test("the facing sent with a blow: a flat unit vector or nothing",function()
	local Server=H.load("Server/HubFight")
	local f=Server.facing(Vector3.new(0,.3,-1))
	assert(f and math.abs(f.Magnitude-1)<1e-6 and f.Y==0,"a facing not flattened")
	assert(Server.facing(Vector3.new(0,0,0))==nil and Server.facing(Vector3.new(50,0,0))==nil and Server.facing("north")==nil,"a forged facing")
	assert(Server.facing(Vector3.new(0/0,0,1))==nil,"NaN")
	assert(string.find(fs.readFile("src/Client/HubFightClient.luau"),"FireServer(move,root.CFrame.LookVector)",1,true),"the client does not send its turn")
end)

-- (26/11, passe 3, seen in the game: the walk's lens inside a green wooden
-- prop) what may fade between his head and the lens
test("the walk's lens: a prop in its way fades; his body, the ground, a walker never",function()
	local Sight=H.load("Client/HubSight")
	local character={}
	local function part(name,opts)
		opts=opts or {}
		return {Name=name,IsA=function(_,c) return c=="BasePart" end,
			IsDescendantOf=function(_,x) return opts.mine and x==character end,
			FindFirstAncestorOfClass=function() return opts.model end}
	end
	assert(Sight.fades(part("StallRoof"),character),"a stall's roof stays opaque in the lens")
	assert(not Sight.fades(part("Head",{mine=true}),character),"his own head")
	assert(not Sight.fades(part("Ground"),character),"the ground")
	local walker={FindFirstChildOfClass=function(_,c) return if c=="Humanoid" then {} else nil end}
	assert(not Sight.fades(part("UpperTorso",{model=walker}),character),"another walker")
	assert(Sight.FADE>.5 and Sight.FADE<1,"the fade")
end)

-- (27/11, the OUTILLEUR at two clients) a player's body is found under Workspace
test("a blow finds the player's body right under Workspace (a Model itself), and a rig in a model",function()
	local Server=H.load("Server/HubFight")
	local function node(classes,parent) return {Parent=parent,IsA=function(_,c) return classes[c]==true end} end
	local ws=node({Model=true,WorldRoot=true},nil)
	local character=node({Model=true},ws)
	local part={FindFirstAncestorOfClass=function(_,c) return if c=="Model" then character else nil end}
	assert(Server.modelOf(part)==character,"the character climbed to Workspace")
	-- a piece of a rig inside a larger model: the outer model
	local outer=node({Model=true},ws)
	local inner=node({Model=true},outer)
	local piece={FindFirstAncestorOfClass=function() return inner end}
	assert(Server.modelOf(piece)==outer,"not the outer model")
end)

-- (27/11, the OUTILLEUR's kit bench) a kit's strike is its own before anyone else's
test("no kit borrows another's strike in the street while it has one of its own",function()
	for _,kit in BetaRoster do
		for name,spec in Rules.Moves do
			local clip=Body.clipName(Authored,kit,spec.clip)
			if spec.kind=="Light" or spec.kind=="Heavy" then
				local owner=string.match(clip,"^([^.]+)%.")
				local family=Body.family(kit)
				assert(owner==kit or table.find(family,owner),kit.." "..name.." plays "..clip.." (another kit's)")
			end
		end
	end
	assert(Body.clipName(Authored,"Sand","Heavy")~="Lion.Heavy","Gaara's heavy is still Sasuke's kick")
end)

-- (27/11, the OUTILLEUR's sounds and the crate's image) what a landed blow
-- sounds and looks like in the street
test("a street blow's sound and flash: the challenge is heard, a crate snaps like wood, no crater for a prop",function()
	local Fight=H.load("Client/HubFightClient")
	assert(Fight.soundOf("challenge",false)=="challenge","the challenge plays no sound of its own")
	assert(Fight.soundOf("worldbreak",true,"wood")=="wood","a crate does not snap like wood")
	assert(Fight.soundOf("worldbreak",true,"stone")=="stone","a stone lantern snaps like wood")
	assert(Fight.soundOf("wood",false,"wood")=="wood" and Fight.soundOf("hit",false)=="hit" and Fight.soundOf("hit",true)=="heavy","a blow's sound")
	for name,s in Fight.SOUNDS do
		assert(type(s.id)=="string" and s.id:match("^rbxassetid://%d+$") and s.volume>0 and s.volume<=1,"the sound "..name)
	end
	assert(Fight.SOUNDS.wood.id~="rbxassetid://9114221862","the crate's break is still a rock slide")
	assert(Fight.SOUNDS.challenge.id~="rbxassetid://9126284094","the challenge is still a whoosh")
	assert(Fight.weightOf("worldbreak",true)~="slam","a broken prop digs a crater in the ground under it")
	-- the server: a broken crate caves in low, its boards around it
	local WorldReaction=H.load("Server/WorldReaction")
	local stage=Instance.new("Folder")
	local c={match={folder=stage},now=0,pushImpact=function() end}
	local crate=Instance.new("Part");crate.Name="Crate";crate.Material=Enum.Material.WoodPlanks
	crate.Size=Vector3.new(5.2,5.2,5.2);crate.CFrame=CFrame.new(0,2.6,0);crate:SetAttribute("WorldBreakable",true);crate.Parent=stage
	local broken=false
	for _=1,8 do
		local r=WorldReaction.impact(c,{part=crate,position=crate.CFrame.Position,normal=Vector3.new(1,0,0),energy=60,contact="blunt",direction=Vector3.new(-1,0,0)})
		if r and r.broken then broken=true;break end
	end
	assert(broken,"the crate did not break")
	assert(crate.Size.Y<=1.2,"a broken crate still stands "..crate.Size.Y.." high")
	local boards=0
	for _,r in WorldReaction.state(c).rubble do
		local d=r.part
		if d.Name=="Rubble" and d.Size.Z>=d.Size.X*2.5 then boards+=1 end
	end
	assert(boards>=3,"few boards around the broken crate: "..boards)
end)

-- (27/11, OUTILLEUR passe 3: bodies stopped at the Plaza duel's edge with no
-- wall seen; the lens inside a tree's trunk) the street duel's edge is drawn,
-- and a tree drawn wider than its box fades for a lens crossing it
test("a street duel's edge is drawn on the ground and lights where a fighter presses; a wide tree fades for the lens",function()
	local Ring=H.load("Client/StreetRing")
	local o=Vector3.new(0,0,-2400)
	assert(Ring.wanted({phase="Duel",origin=o,site={key="Plaza",radius=36,street=true}}),"no ring for a street duel")
	assert(not Ring.wanted({phase="Duel",origin=o,site={key="Lane",radius=36}}),"a ring for a duel that is not in the street")
	assert(not Ring.wanted({phase="Result",origin=o,site={key="Plaza",radius=36,street=true}}),"a ring after the duel")
	local pts=Ring.points(o,36)
	assert(#pts==Ring.SEGMENTS,"segments")
	for _,p in pts do assert(math.abs((p.at-o).Magnitude-36)<1e-3,"a segment off the circle") end
	local edge=Vector3.new(35,0,-2400)
	assert(Ring.shade(Vector3.new(36,0,-2400),{edge},o,36)==Ring.LIT,"the edge does not light under a fighter pressing on it")
	assert(Ring.shade(Vector3.new(-36,0,-2400),{edge},o,36)==Ring.FAINT,"the far side lit")
	assert(Ring.shade(Vector3.new(36,0,-2400),{o},o,36)==Ring.FAINT,"lit with nobody near")
	local Camera=H.load("Client/Camera")
	local box=CFrame.new(10,5,0)
	assert(Camera.segmentBox(Vector3.new(0,5,0),Vector3.new(20,5,0),box,Vector3.new(4,10,4)),"a line through the trunk misses it")
	assert(Camera.segmentBox(Vector3.new(0,5,0),Vector3.new(10,5,0),box,Vector3.new(4,10,4)),"a lens inside the trunk misses it")
	assert(not Camera.segmentBox(Vector3.new(0,5,6),Vector3.new(20,5,6),box,Vector3.new(4,10,4)),"a line beside the trunk crosses it")
	assert(not Camera.segmentBox(Vector3.new(0,5,0),Vector3.new(7,5,0),box,Vector3.new(4,10,4)),"a line short of the trunk crosses it")
end)

-- (27/11, Studio) whoever waits in a place where a duel is fought steps out
test("a challenger or a thug waiting in a place where a duel is fought steps out of its ring",function()
	local ok,Matches=pcall(H.load,"Server/Matches")
	assert(ok,"Matches: "..tostring(Matches))
	local sites={{key="Plaza",origin=Vector3.new(0,0,-2387),radius=36.4}}
	assert(Matches.waitsIn(Vector3.new(0,3,-2387),sites),"the challenger in the middle stays")
	assert(Matches.waitsIn(Vector3.new(36.4,3,-2387),sites),"the thug on the edge stays")
	assert(not Matches.waitsIn(Vector3.new(60,3,-2387),sites),"one far off steps out")
	assert(not Matches.waitsIn(Vector3.new(0,3,-2387),{}),"one steps out with no duel")
end)

print(string.format("NinjaDuel his kit in the street (26/11): %d PASS",passed))
