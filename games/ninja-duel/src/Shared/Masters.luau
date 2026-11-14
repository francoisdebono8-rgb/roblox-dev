-- The masters' path (user 12/11, 17 h 02-17 h 21; DEC-037): a new player
-- picks one kit among three; every other kit is taught by its master, the
-- prodigy himself, once the player has enough mastery in a kit linked to him
-- (the map follows the story). The kit can also be bought at once (pay for
-- time, never a random draw; ranked and tournament budgets stay equal).
-- Shared: the server rules (Server/Progression, Server/ProfileSchema) and
-- the roster screen read the same data.
local Masters={}

-- The kits a new player chooses from (one), and the beta's eight.
Masters.Starters={"Legion","Lion","Leaf"}
Masters.Kits={"Legion","Lion","Leaf","GentleFist","Sand","Mirage","Copycat","Flashstep"}

-- Who leads to whom: a master teaches once the player has Need mastery in
-- one of the kits in `from`. The links follow the story, and from any
-- starter every kit can be reached (the two starters not chosen have their
-- master too): the rivals Naruto and Sasuke, Gai's team (Lee, Neji), the
-- exam's fights (Lee-Gaara, Naruto-Neji), the two jinchūriki, Sasuke's
-- brother, Team 7's sensei, Kakashi against Itachi, Kakashi's own sensei.
Masters.Need=300
Masters.Map={
	Legion={from={"Lion","Sand"}},
	Lion={from={"Legion","Mirage"}},
	Leaf={from={"GentleFist","Sand"}},
	GentleFist={from={"Leaf","Legion"}},
	Sand={from={"Leaf","Legion"}},
	Copycat={from={"Legion","Lion"}},
	Mirage={from={"Lion","Copycat"}},
	Flashstep={from={"Copycat"}},
}
-- The master's duel: the prodigy, at this AI level.
Masters.DuelLevel="hard"

Masters.MaxMastery=1000000
-- Mastery earned by one decided duel with a kit the player owns: finishing
-- it, winning it, and using that kit's own jutsu (variety, not spam: each
-- different jutsu counts once, three at most). Easy AI counts for less.
Masters.Gain={Finished=30,Won=50,PerTechnique=10,MaxTechniques=3,EasyScale=.6,Max=200}

function Masters.isKit(id)
	return type(id)=="string" and table.find(Masters.Kits,id)~=nil
end
function Masters.isStarter(id)
	return type(id)=="string" and table.find(Masters.Starters,id)~=nil
end

-- Whether a player with `kits` (profile.kits: owned, mastery) can be taught
-- `id` by its master now. Returns ok and, when not, what is missing.
function Masters.canLearn(kits,id)
	if not Masters.isKit(id) then return false,"Unknown kit" end
	local owned=kits and kits.owned or {}
	if owned[id] then return false,"Already learned" end
	local rule=Masters.Map[id]
	if not rule then return false,"Starter kit: chosen at the start" end
	local best,via=0,nil
	for _,from in rule.from do
		local m=owned[from] and (kits.mastery and kits.mastery[from] or 0) or 0
		if m>best then best,via=m,from end
	end
	if best>=Masters.Need then return true,via end
	return false,"Needs "..Masters.Need.." mastery in "..table.concat(rule.from," or "),best
end

-- (DEC-038, 13/11) Skill points come from the kit's own mastery: every
-- PointEvery mastery is one point of that kit's tree. A kit bought brings no
-- point: the tree grows by playing it.
Masters.PointEvery=10
Masters.MaxPoints=999
function Masters.points(mastery)
	if type(mastery)~="number" or mastery~=mastery then return 0 end
	return math.clamp(math.floor(mastery/Masters.PointEvery),0,Masters.MaxPoints)
end

-- Mastery for one decided duel. r = {won, techniques (distinct jutsu used),
-- level ("easy"|"normal"|"hard")}.
function Masters.duelGain(r)
	local G=Masters.Gain
	local n=G.Finished+(if r.won then G.Won else 0)+math.min(r.techniques or 0,G.MaxTechniques)*G.PerTechnique
	if r.level=="easy" then n*=G.EasyScale end
	return math.clamp(math.floor(n+.5),0,G.Max)
end

return Masters
