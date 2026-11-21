-- The ninja's tree (21/11, DEC-045, step 2): one tree for every kit, next to
-- each kit's own (Shared/SkillTrees). Its points come from all the mastery a
-- player has earned, whatever the kit (1 point every 15), and are never sold.
--   NATURE    one chakra nature at a time: Fire, Wind, Lightning, Earth, Water
--   INFUSION  the nature on the kunai, then on the blade (the last hit of
--             the basic string), then mastered (stronger, more visible)
--   MOBILITY  longer wall runs, a second jump in the air, a quick get-up
--   TOOLS     the explosive tag, the smoke bomb
-- Pure and shared: the profile's record `ninja` (Server/ProfileSchema,
-- commands ninjaLearn and ninjaSet), the fighter's def.Ninja in a duel
-- (Server/SkillBuilds.applyNinja, read by the combat), the player attribute
-- NinjaNature (the ANIMATEUR's Infusion.<Nature>), the view for the DESIGN.
-- The node texts are placeholders: the CM writes them (step 2).
local N={}

N.PointEvery=15
N.TierNeed={0,15,40}
N.TierNames={"I","II","III"}
N.Natures={"Fire","Wind","Lightning","Earth","Water"}

-- What an infused hit does: small, readable, at most once every Gap seconds,
-- always with an answer (the plan's table, 21/11). Mastery: Strong times.
N.Infusion={
	Gap=4,Strong=1.5,
	Fire={Burn=3,BurnTime=2,Answer="a guard stops the burn"},
	Wind={KunaiRange=1.2,KunaiSpeed=1.2,Answer="it is seen coming from further"},
	Lightning={Stun=.25,Answer="once every 4 s"},
	Earth={GuardDamage=10,Answer="a dodge avoids it whole"},
	Water={Slow=.15,SlowTime=1.5,Answer="a substitution washes it off"},
}
-- The ninja's tools (Server/NinjaArts): the tag rides on a thrown blade once
-- every TagEvery s and blows TagDelay s after it lands (step out); the smoke
-- of a substitution hides him SmokeTime s (the rival loses him).
N.Tools={TagEvery=8,TagDelay=1,TagRadius=6,TagDamage=8,TagKnock=34,TagLift=24,SmokeTime=1.5,SmokeRadius=7}
-- Mobility (Server/Motor, Brawler.react): the second jump's share of a
-- jump's height, the share of the time down a quick rise keeps.
N.Mobility={AirJump=.85,QuickRise=.55}

-- Nodes. Id: saved in profiles, never rename. Set: the fields it gives the
-- fighter's def.Ninja while active. Requires: nodes learned and active first.
-- NeedsNature: an active nature first. Exclusive: one active per group.
N.Nodes={
	{Id="NatureFire",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Fire"},
		Name="FIRE NATURE",Shows="Your infused kunai and blade burn: 3 damage over 2 s."},
	{Id="NatureWind",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Wind"},
		Name="WIND NATURE",Shows="Your infused kunai flies 20% further and faster."},
	{Id="NatureLightning",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Lightning"},
		Name="LIGHTNING NATURE",Shows="Your infused hits freeze the rival for a quarter of a second."},
	{Id="NatureEarth",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Earth"},
		Name="EARTH NATURE",Shows="Your infused hits crack guards: 10 more guard damage."},
	{Id="NatureWater",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Water"},
		Name="WATER NATURE",Shows="Your infused hits slow the rival by 15% for 1.5 s."},
	{Id="InfusedKunai",Branch="Infusion",Tier=1,Cost=6,NeedsNature=true,Set={KunaiInfused=true},
		Name="INFUSED KUNAI",Shows="Your kunai carries your nature, in flight and on impact."},
	{Id="InfusedBlade",Branch="Infusion",Tier=2,Cost=8,NeedsNature=true,Requires={"InfusedKunai"},Set={BladeInfused=true},
		Name="INFUSED BLADE",Shows="The last hit of your basic string carries your nature."},
	{Id="ElementMastery",Branch="Infusion",Tier=3,Cost=12,NeedsNature=true,Requires={"InfusedBlade"},Set={Mastery=true},
		Name="ELEMENT MASTERY",Shows="Your nature hits half again as hard, and everyone sees it."},
	{Id="WallRunner",Branch="Mobility",Tier=1,Cost=5,Set={WallRun=1.4},
		Name="WALL RUNNER",Shows="You run 40% longer on walls."},
	{Id="CloudStep",Branch="Mobility",Tier=2,Cost=8,Requires={"WallRunner"},Set={AirJump=true},
		Name="CLOUD STEP",Shows="A second jump in the air."},
	{Id="QuickRise",Branch="Mobility",Tier=2,Cost=6,Set={QuickRise=true},
		Name="QUICK RISE",Shows="Knocked down, you are back up in half the time."},
	{Id="ExplosiveTag",Branch="Tools",Tier=2,Cost=8,Set={ExplosiveTag=true},
		Name="EXPLOSIVE TAG",Shows="Every 8 s a thrown blade carries a paper bomb: it blows 1 s after it lands."},
	{Id="SmokeBomb",Branch="Tools",Tier=3,Cost=8,Set={SmokeBomb=true},
		Name="SMOKE BOMB",Shows="Your substitution leaves smoke: the rival loses you for 1.5 s."},
}
N.ById={}
for _,node in N.Nodes do N.ById[node.Id]=node end

-- His ninja points: every kit's mastery together (kits.mastery of the profile).
function N.points(mastery)
	local total=0
	for _,value in mastery or {} do if type(value)=="number" and value>0 then total+=value end end
	return math.floor(total/N.PointEvery)
end
function N.tier(points)
	local tier=1
	for k,need in N.TierNeed do if (points or 0)>=need then tier=k end end
	return tier
end
function N.new() return {learned={},active={}} end

local function has(list,id) for _,x in list do if x==id then return true end end return false end
local function remove(list,id) for i=#list,1,-1 do if list[i]==id then table.remove(list,i) end end end
function N.spent(r)
	local n=0
	for _,id in r.learned do local node=N.ById[id];if node then n+=node.Cost end end
	return n
end
function N.free(r,points) return (points or 0)-N.spent(r) end
-- The active nature, or nil.
function N.nature(r)
	for _,id in r.active do local node=N.ById[id];if node and node.Set.Nature then return node.Set.Nature end end
	return nil
end
local function needsMet(r,node)
	for _,req in node.Requires or {} do if not has(r.active,req) then return false end end
	if node.NeedsNature and not N.nature(r) then return false end
	return true
end

-- Whether he may learn `id` with `points`: false and why otherwise.
function N.canLearn(r,id,points)
	local node=N.ById[id]
	if not node then return false,"Unknown node" end
	if has(r.learned,id) then return false,"Already learned" end
	if N.tier(points)<node.Tier then return false,string.format("Tier %s opens at %d ninja points",N.TierNames[node.Tier],N.TierNeed[node.Tier]) end
	if N.free(r,points)<node.Cost then return false,"Not enough ninja points" end
	for _,req in node.Requires or {} do if not has(r.learned,req) then return false,"Needs "..N.ById[req].Name end end
	if node.NeedsNature and not N.nature(r) then return false,"Choose a nature first" end
	return true
end

-- Turns a learned node on or off. On: the other node of its group goes off.
-- Off: what needs it goes off too. Returns the record.
function N.set(r,id,on)
	local node=N.ById[id]
	assert(node and has(r.learned,id),"Node not learned")
	if on then
		if node.Exclusive then
			for _,other in table.clone(r.active) do
				local o=N.ById[other]
				if o and o.Exclusive==node.Exclusive and other~=id then remove(r.active,other) end
			end
		end
		assert(needsMet(r,node),"Its requirements are off")
		if not has(r.active,id) then table.insert(r.active,id) end
	else
		remove(r.active,id)
	end
	-- whatever no longer has what it needs goes off (in tree order: settles)
	local changed=true
	while changed do
		changed=false
		for _,other in table.clone(r.active) do
			local o=N.ById[other]
			if o and not needsMet(r,o) then remove(r.active,other);changed=true end
		end
	end
	return r
end
-- Learns `id`: it goes on at once when what it needs is on, else it waits,
-- learned and off. Errors when it may not be learned.
function N.learn(r,id,points)
	local ok,why=N.canLearn(r,id,points)
	assert(ok,why)
	table.insert(r.learned,id)
	if needsMet(r,N.ById[id]) then N.set(r,id,true) end
	return r
end

function N.valid(r,points)
	if type(r)~="table" or type(r.learned)~="table" or type(r.active)~="table" then return false,"ninja record" end
	local seen={}
	for _,id in r.learned do
		if type(id)~="string" or not N.ById[id] or seen[id] then return false,"ninja learned" end
		seen[id]=true
	end
	local groups={}
	for _,id in r.active do
		local node=N.ById[id]
		if not seen[id] or not node then return false,"ninja active" end
		if node.Exclusive then
			if groups[node.Exclusive] then return false,"two natures" end
			groups[node.Exclusive]=true
		end
	end
	if points~=nil and N.spent(r)>points then return false,"ninja overspent" end
	return true
end

-- The fields the active nodes give the fighter's def.Ninja (nil: none).
function N.def(r)
	if not r then return nil end
	local out={}
	local any=false
	for _,node in N.Nodes do
		if has(r.active,node.Id) and needsMet(r,node) then
			for key,value in node.Set do out[key]=value;any=true end
		end
	end
	if not any then return nil end
	if out.Nature then out.Infusion=N.Infusion[out.Nature] end
	return out
end

-- What the client draws: the points, the tier, the nature and each node's state
-- (active, learned, open: can be learned now, locked: and why).
function N.view(r,points)
	r=r or N.new()
	local nodes={}
	for _,node in N.Nodes do
		local state,why
		if has(r.active,node.Id) then state="active"
		elseif has(r.learned,node.Id) then state="learned"
		else
			local ok,reason=N.canLearn(r,node.Id,points)
			state=if ok then "open" else "locked"
			why=if ok then nil else reason
		end
		table.insert(nodes,{id=node.Id,name=node.Name,shows=node.Shows,branch=node.Branch,tier=node.Tier,cost=node.Cost,
			state=state,why=why,nature=node.Set.Nature})
	end
	return {points=points or 0,free=N.free(r,points),tier=N.tier(points),nature=N.nature(r),nodes=nodes}
end

return N
