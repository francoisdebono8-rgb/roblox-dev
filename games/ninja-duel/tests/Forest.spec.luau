-- The way in (26/11, DEC-054; François: « en dehors du village […] un combat
-- sans compétence très court, contre un PNJ, on arrive par une forêt », « je
-- veux plus qu'il apparaisse nu »). Server/Forest and Matches.forestFight: a new
-- player walks to the bandit, a fight of one short round where no technique,
-- tool, awakening, ultimate nor substitution answers (Combat's `bare`), the
-- coach without the jutsu and tool prompts; the bandit down, the path, the
-- gate's foot opens the creation, then Konoha for good. The forest's place on
-- the map (HubMap.Forest) and its build (Server/Hub.forestOutside).
-- Real Matches / Combat / AI on harness rigs and a scripted clock; the look is
-- a Studio check.
local H=require("./Harness")
local V=H.V
local clock=5000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
		NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
H.load("Shared/Config").DamageScale=H.GameDamageScale
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local SoloPlay=H.load("Server/SoloPlay")
local Progression=H.load("Server/Progression")
local AI=H.load("Server/AI")
local HubMap=H.load("Shared/HubMap")
local Config=H.load("Shared/Config")
local Forest=H.load("Server/Forest")
local Hub=H.load("Server/Hub")
local Coach=H.load("Server/Coach")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
local remote={FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
local function last(player) local l=inbox[player];return l and l[#l] end
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end
-- A walker: his root, moved by the test.
local function walker(at)
	local root={Position=at}
	local model={PivotTo=function(_,cf) root.Position=cf.Position end}
	root.Parent=model
	return {character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end}},root
end

test("the forest: beyond the great gate, outside the village, its path from the far end to the gate, the bandit on it",function()
	local F=HubMap.Forest
	assert(HubMap.inForest(HubMap.Spawns.forest.at) and not HubMap.inside(HubMap.Spawns.forest.at),"the spawn")
	assert(F.z0>HubMap.MaxZ,"the forest overlaps the village")
	assert(HubMap.inForest(F.bandit) and HubMap.inForest(F.clearing.at) and HubMap.inForest(F.gate),"its marks")
	assert(F.path.a.Z>F.clearing.at.Z and F.clearing.at.Z>F.gate.Z,"spawn, clearing, gate: in that order along the path")
	assert(math.abs(F.bandit.Z-F.clearing.at.Z)<F.clearing.radius,"the bandit is not at the clearing")
	local place=HubMap.placeAt(HubMap.Origin+HubMap.Spawns.forest.at)
	assert(place and place.id=="Forest","the HUD's place: "..tostring(place and place.id))
end)

test("its build: trees thick off the path, the clearing and the gate's foot; not too many",function()
	local F=HubMap.Forest
	local S=HubMap.Scale
	local a=F.path.a/S
	local trees=Hub.forestTrees()
	assert(#trees>=70 and #trees<=200,"trees: "..#trees)
	for _,t in trees do
		local at=V.new(t[1],0,t[2])
		assert(math.abs(at.X-a.X)>F.path.width/S/2+2 or at.Z>a.Z+4,"a tree on the path at "..tostring(at))
		assert(((at-F.clearing.at/S)*V.new(1,0,1)).Magnitude>F.clearing.radius/S,"a tree in the clearing at "..tostring(at))
		assert(((at-F.gate/S)*V.new(1,0,1)).Magnitude>12,"a tree at the gate's foot")
	end
	local g=Hub.forestOutside(H.envBase.Instance.new("Folder"))
	assert(g and g.Name=="Forest" and g:GetAttribute("Trees")==#trees,"no forest built")
	print("     "..#trees.." trees")
end)

test("bare: strikes, guard, dodge, jump and grab answer; no technique, tool, awakening, ultimate, chakra nor substitution",function()
	local m=Matches.new(remote)
	local player=fakePlayer(41)
	m:selection(player)
	Forest.matches=m
	assert(m:forestFight(player),"no forest fight")
	local s=m.sessions[player]
	assert(s.phase=="Duel" and s.bare and s.techniquesDisabled and s.roundsToWin==1 and s.site and s.site.key=="Forest","the fight's frame")
	assert(s.human.fighterId==Forest.KIT and s.bot.fighterId==Forest.BANDIT_KIT and Matches.aiLevel(s)=="first","the bodies, the novice")
	-- (26/11) the CM's words: his name, his line in the dare's bubble, no VS card
	local Banter=H.load("Shared/Banter")
	assert(Forest.NAME==Banter.Bandit.name and s.bot.displayName==Forest.NAME,"his name")
	assert(s.dare and s.dare.who==Forest.NAME and s.dare.line==Banter.Bandit.beforeFight and s.dare.vsFor==0,"his line before the fight")
	assert(s.dare.lineFor<(s.introUntil-s.combat.now),"the bubble outlasts the intro")
	assert(s.coach and s.coach.done.signature and s.coach.done.tool,"the coach still teaches the jutsu and the tool")
	assert(Coach.snapshot(s)==nil or Coach.snapshot(s).total==#Coach.Prompts-2,"the coach's count")
	local c=s.combat
	c.now=s.introUntil+.1
	s.human.chakra=100
	for _,action in {"Technique1","Technique2","Tool","Ultimate","Awaken","Substitute","Seals","Seal1","ChakraLoad","Arm","Pursuit"} do
		local ok,why=c:request(s.human,action,nil,c.now)
		assert(ok==false,action.." answered in the forest ("..tostring(why)..")")
	end
	local ok,why=c:request(s.human,"Attack",nil,c.now,{chakra=true})
	assert(ok==false,"a chakra strike answered")
	ok,why=c:request(s.human,"Attack",nil,c.now)
	assert(ok~=false,"the strike: "..tostring(why))
end)

test("the way in: the walk, the bandit there and then, a very short fight, the path, the gate's foot, Konoha",function()
	local m=Matches.new(remote)
	local player=fakePlayer(42)
	m:selection(player)
	Forest.matches=m
	Hub.bodies=Hub.bodies or {}
	local body,root=walker(HubMap.Origin+HubMap.Spawns.forest.at+V.new(0,3,0))
	Hub.bodies[player]=body
	Forest.state[player]={stage="forest",at=0}
	local s=m.sessions[player]
	-- far from him, not yet
	Forest.tick(1)
	assert(Forest.of(player)=="forest" and s.phase=="Selection","the bandit came at once")
	-- he walks up the path: the bandit is on him
	root.Position=HubMap.Origin+HubMap.Forest.bandit+V.new(0,3,Forest.TRIGGER-4)
	Forest.tick(2)
	assert(Forest.of(player)=="fight" and s.phase=="Duel" and player:GetAttribute("NinjaIntro")=="fight","no fight near him")
	-- both at the stick (the player's an AI here), to the K.O.
	local pilot=AI.new(s.combat,s.human,7,"normal"):withStrategy()
	s.autopilot=true
	local t=0
	local function step(seconds)
		for _=1,math.max(1,math.ceil(seconds/.02)) do
			clock+=.02;t+=.02
			if s.phase=="Duel" and not s.finishing and not (s.introUntil and s.combat.now<s.introUntil) then pilot:update(s.combat.now) end
			m:update(.02,clock);runTimers()
		end
	end
	local started=clock
	while s.phase=="Duel" and clock-started<90 do step(.2) end
	local length=clock-started
	assert(s.phase=="Result","no result after "..length.." s")
	assert(s.forestWon==true,"the novice beat him")
	assert(length<34,("« très court »: %.1f s"):format(length))
	assert(last(player).progress and last(player).progress.forest and last(player).progress.forest.won,"the result does not say it")
	-- (26/11, the CM's Banter) his last word, beaten
	local say=last(player).progress.forest.say
	local Banter=H.load("Shared/Banter")
	assert(say and say.who==Banter.Bandit.name and table.find(Banter.Bandit.defeated,say.line),"the bandit's last word: "..tostring(say and say.line))
	local beaten=Matches.lastWord("forest",nil,false)
	assert(beaten and beaten.line==Banter.Bandit.won,"his word when he wins")
	local dare=Matches.lastWord("challenge","Legion",true)
	assert(dare and dare.line==Banter.Inspirations.Legion.lose and dare.who~="","the inspiration's excuse")
	assert(Matches.lastWord("challenge","Nobody",true)==nil,"a kit without words")
	assert(not s.bare and not s.techniquesDisabled and not s.forest,"the forest's rules outlive its fight")
	print(("     the bandit down in %.1f s"):format(length))
	-- the result a beat, then the path from the clearing
	Forest.tick(100)
	Forest.tick(100+Forest.RESULT+.1)
	assert(s.phase=="Selection" and Forest.of(player)=="path" and player:GetAttribute("NinjaIntro")=="path","not back on the path")
	-- the gate's foot: his ninja
	root.Position=HubMap.Origin+HubMap.Forest.gate+V.new(0,3,2)
	Forest.tick(110)
	assert(Forest.of(player)=="create" and player:GetAttribute("NinjaIntro")=="create","no creation at the gate")
	-- done: Konoha, for good
	assert(Forest.created(player),"not created")
	assert(Forest.state[player]==nil and player:GetAttribute("NinjaIntro")==nil,"still in the forest")
	assert(not Forest.created(player),"created twice")
end)

test("a lost fight (the coach's floor makes it rare): the bandit waits again on the path",function()
	local m=Matches.new(remote)
	local player=fakePlayer(43)
	m:selection(player)
	Forest.matches=m
	local body,root=walker(HubMap.Origin+HubMap.Forest.bandit+V.new(0,3,2))
	Hub.bodies[player]=body
	Forest.state[player]={stage="forest",at=0}
	Forest.tick(1)
	local s=m.sessions[player]
	assert(s.phase=="Duel","no fight")
	s.phase="Result";s.forestWon=false
	Forest.tick(5);Forest.tick(5+Forest.RESULT+.1)
	assert(Forest.of(player)=="forest","lost, yet on to the gate")
end)

test("the profile: a new player needs the way in, once; a player from before (a kit chosen) never",function()
	local data={kits={selected=nil},style={equipped={}}}
	local P=Progression
	local player=fakePlayer(44)
	P.handles=P.handles or {}
	P.handles[player]={data=data}
	assert(P.needsIntro(player),"a new player")
	data.kits.selected="Lion"
	assert(not P.needsIntro(player),"a player who already chose a kit")
	data.kits.selected=nil;data.intro=true
	assert(not P.needsIntro(player),"the way in done")
	P.handles[player]=nil
	assert(not P.needsIntro(player),"no profile: no forest")
end)

-- (26/11, DESIGN passe 2) the gate's card (Client/CreatorPanel) sends "Create"
test("the gate's creation: the starter pieces worn, one hair and one colour given, his way in, once",function()
	local S=H.load("Server/ProfileSchema")
	local p=S.new("dev_gate")
	local picks={top="TopTunicGreen",bottom="BottomShorts",feet="FeetBlack",headband="HeadbandBlue",hair="HairBowl",hairColor="HairSun"}
	local np,result=S.apply(p,1,"create",Progression.createPicks(picks));p=np
	local e=p.style.equipped
	assert(e.top=="TopTunicGreen" and e.bottom=="BottomShorts" and e.feet=="FeetBlack" and e.headband=="HeadbandBlue","the pieces")
	assert(e.hair=="HairBowl" and p.style.owned.HairBowl and e.hairColor=="HairSun" and p.style.owned.HairSun,"the hair given")
	assert(p.intro==true and result.intro==true,"his way in")
	assert(not pcall(S.apply,p,2,"create",{}),"created twice")
	-- his own Roblox hair: nothing in the hair slot
	local q=S.new("dev_gate2")
	q.style.equipped.hair="HairBowl";q.style.owned.HairBowl=true
	q=S.apply(q,1,"create",Progression.createPicks({hair="",hairColor="HairNatural"}))
	assert(q.style.equipped.hair==nil and q.style.equipped.hairColor=="HairNatural","his own hair")
	-- a forged card: only what the gate gives is kept; the rest stays as it is
	local forged=Progression.createPicks({top="TopTrackJacketOrange",bottom="HairBowl",feet=string.rep("x",60),hair="TopTunicNavy",hairColor=7,headband="HeadbandNone"})
	assert(forged.top==nil and forged.bottom==nil and forged.feet==nil and forged.hair==nil and forged.hairColor==nil,"a forged pick kept")
	assert(forged.headband=="HeadbandNone","a real pick dropped")
	assert(not pcall(S.apply,S.new("dev_gate3"),1,"create",{top="TopTrackJacketOrange"}),"a market top given at the gate")
	-- only at the gate's foot, then Konoha
	local player=fakePlayer(45)
	local sent=nil
	local create=Progression.create
	Progression.create=function(_,args) sent=args;return true end
	Forest.state[player]={stage="path",at=0}
	assert(not Forest.create(player,picks) and sent==nil,"made before the gate")
	Forest.state[player]={stage="create",at=0}
	local ok=Forest.create(player,picks)
	Progression.create=create
	assert(ok and sent==picks,"the card not taken")
	assert(Forest.state[player]==nil and player:GetAttribute("NinjaIntro")==nil,"still at the gate")
	assert(not Forest.create(player,picks),"created twice")
end)

print(string.format("NinjaDuel the way in (DEC-054): %d PASS",passed))
