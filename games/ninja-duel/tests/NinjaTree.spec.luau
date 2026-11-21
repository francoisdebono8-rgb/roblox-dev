-- The ninja's tree (21/11, DEC-045, step 2): one tree for every kit, its
-- points from all the mastery earned, one nature at a time, infusions that
-- need a nature, the profile's record and commands, the view, the player's
-- NinjaNature and the def.Ninja a duel's kit carries. Headless.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local N=H.load("Shared/NinjaTree")
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")

test("points come from every kit's mastery, 1 every 15; three tiers",function()
	assert(N.points({Legion=100,Lion=80,Leaf=0})==12 and N.points(nil)==0 and N.points({Legion=-5})==0)
	assert(N.tier(0)==1 and N.tier(15)==2 and N.tier(39)==2 and N.tier(40)==3)
	local ids={}
	for _,node in N.Nodes do
		assert(not ids[node.Id],"twice "..node.Id);ids[node.Id]=true
		assert(type(node.Name)=="string" and type(node.Shows)=="string" and node.Cost>0 and node.Tier>=1 and node.Tier<=3,node.Id)
		for _,req in node.Requires or {} do assert(N.ById[req] and N.ById[req].Tier<=node.Tier,node.Id.." needs "..req) end
	end
	local natures=0
	for _,node in N.Nodes do if node.Set.Nature then natures+=1;assert(N.Infusion[node.Set.Nature],"no infusion for "..node.Set.Nature) end end
	assert(natures==5,"five natures")
end)

test("one nature at a time; an infusion needs a nature; turning the nature off turns the infusions off",function()
	local r=N.new()
	assert(not N.canLearn(r,"InfusedKunai",30),"an infusion without a nature")
	N.learn(r,"NatureFire",30)
	assert(N.nature(r)=="Fire")
	N.learn(r,"InfusedKunai",30)
	N.learn(r,"NatureWater",30)
	assert(N.nature(r)=="Water" and N.valid(r,30),"the second nature replaces the first")
	local def=N.def(r)
	assert(def.Nature=="Water" and def.KunaiInfused==true and def.Infusion.Slow==.15,"the duel's def")
	N.set(r,"NatureWater",false)
	assert(N.nature(r)==nil and N.def(r)==nil,"an infusion stayed on without a nature")
	N.set(r,"NatureFire",true)
	assert(N.nature(r)=="Fire" and not table.find(r.active,"InfusedKunai"),"the infusion came back by itself")
	assert(N.free(r,30)==30-14,"the points spent")
	N.learn(r,"InfusedBlade",30)
	assert(table.find(r.learned,"InfusedBlade") and not table.find(r.active,"InfusedBlade"),"learned while what it needs is off: it waits, off")
	N.set(r,"InfusedKunai",true);N.set(r,"InfusedBlade",true)
	assert(N.def(r).BladeInfused and N.valid(r,30),"turned on once the kunai is on")
end)

test("tiers and points gate the nodes; the view says why",function()
	local r=N.new()
	assert(not N.canLearn(r,"CloudStep",100),"a node before what it needs")
	N.learn(r,"WallRunner",14)
	local ok,why=N.canLearn(r,"CloudStep",14)
	assert(not ok and string.find(why,"Tier II"),"a tier II node at 14 points: "..tostring(why))
	assert(not N.canLearn(r,"NatureEarth",8),"more than the points")
	local v=N.view(r,14)
	assert(v.points==14 and v.free==9 and v.tier==1 and v.nature==nil)
	local states={}
	for _,node in v.nodes do states[node.id]=node end
	assert(states.WallRunner.state=="active" and states.NatureEarth.state=="open" and states.CloudStep.state=="locked" and states.CloudStep.why,"the states")
	assert(not N.valid({learned={"NatureFire","NatureWind"},active={"NatureFire","NatureWind"}}),"two natures valid")
	assert(not N.valid({learned={"NatureFire"},active={}},2),"overspent valid")
end)

test("the profile keeps it: ninjaLearn and ninjaSet, checked against the mastery",function()
	local p=S.new("dev_ninja")
	p.kits.mastery.Legion=120;p.kits.mastery.Leaf=45 -- 11 points
	local function run(kind,args) local np,r=S.apply(p,p.sequence+1,kind,args);p=np;return r end
	local r=run("ninjaLearn",{node="NatureLightning"})
	assert(r.nature=="Lightning" and r.free==7 and S.validate(p))
	run("ninjaLearn",{node="InfusedKunai"})
	assert(not pcall(S.apply,p,p.sequence+1,"ninjaLearn",{node="WallRunner"}),"over the points")
	assert(not pcall(S.apply,p,p.sequence+1,"ninjaLearn",{node="Nope"}),"an unknown node")
	r=run("ninjaSet",{node="NatureLightning",on=false})
	assert(r.nature==nil and #p.ninja.active==0 and S.validate(p))
	local bad=S.copy(p);bad.ninja.learned={"NatureFire","NatureFire"}
	assert(not S.validate(bad),"a node learned twice")
end)

-- Progression with players that carry attributes.
local getService=H.envBase.game.GetService
local owners=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "ninja-"..owners end} end
	return getService(g,name)
end
local function fakePlayer(id)
	local attrs={}
	return {UserId=id,Name="P"..id,DisplayName="P"..id,Parent=H.Players,
		SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
end

test("a player learns his nature: the view, his NinjaNature, and the kit his duel builds",function()
	local Progression=H.load("Server/Progression")
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local a=fakePlayer(951)
	assert(Progression.load(a),"profile")
	local h=Progression.handles[a]
	h.data.kits.mastery.Legion=300 -- 20 points
	local ok,why=Progression.ninjaLearn(a,"NatureWind")
	assert(ok,"learn: "..tostring(why))
	assert(a:GetAttribute("NinjaNature")=="Wind","his nature for the effects")
	assert(Progression.ninjaLearn(a,"InfusedKunai"))
	local view=Progression.view(a).ninja
	assert(view.nature=="Wind" and view.points==20 and view.free==10,"the view")
	-- the kit of a learned kit carries def.Ninja (Matches.resolveKit)
	h.data.kits.owned.Leaf=true
	local spec=Progression.kitSpec(a,"Leaf")
	assert(spec and spec.ninja and spec.ninja.Nature=="Wind" and spec.ninja.KunaiInfused,"the spec")
	local Matches=H.load("Server/Matches")
	local ok2,kit=Matches.resolveKit("Leaf",spec,nil)
	assert(ok2 and kit and kit.def.Ninja and kit.def.Ninja.Infusion.KunaiRange==1.2,"the duel's kit has no def.Ninja")
	assert(not Progression.ninjaLearn(a,"SmokeBomb"),"a tier III node at 20 points")
	assert(Progression.ninjaSet(a,"NatureWind",false))
	assert(a:GetAttribute("NinjaNature")==nil,"the nature stayed on him")
	Config.Progression.Enabled=false
	H.envBase.game.GetService=getService
end)

print(string.format("NinjaDuel the ninja's tree (DEC-045): %d PASS",passed))
