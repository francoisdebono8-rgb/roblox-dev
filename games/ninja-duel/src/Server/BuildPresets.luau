-- Example ranked builds (PROG-002) and AI budget builds (PROG-003). Every
-- preset is an ordinary build of the fighter's skill tree: Matches validates it
-- through SkillBuilds like a player's, so an AI gets choices, never hidden
-- stats. AI presets favour nodes the current AI already exercises (passive
-- rules, routes, defence riders) over inputs it never makes.
local Presets={}
-- Budget per AI tier: Min/Max skill points, or within NearMax of the fighter's
-- playable maximum (SkillBuilds.maxCost(fighter,true)).
Presets.AITiers={
	{Id="Beginner",Min=20,Max=30},
	{Id="Medium",Min=40,Max=50},
	{Id="Hard",Min=60,Max=70},
	{Id="Boss",Min=80,Max=100},
	{Id="Legendary",NearMax=8},
}
Presets.AI={
	Flashstep={
		Beginner={Why="Seals that survive his substitution: the base loop, a little more forgiving.",
			Nodes={"FlashEconomy","SealCraft","ReturnSeal","DeepReserves","Endurance"}},
		Medium={Why="Adds the air spike that plants a destination and a cheaper Rasengan.",
			Nodes={"FlashEconomy","SealCraft","ReturnSeal","DeepReserves","Endurance","SpikeAnchor","RasenganFocus","QuickHands"}},
		Hard={Why="Rasengan drive pick-ups, longer seals and a parry that seals the attacker.",
			Nodes={"FlashEconomy","SealCraft","ReturnSeal","DeepReserves","Endurance","SpikeAnchor","RasenganFocus","QuickHands","RasenganDrive","SealInk","ParrySeal"}},
		Boss={Why="The full relocation fighter: string teleports and air exits.",
			Nodes={"FlashEconomy","SealCraft","ReturnSeal","DeepReserves","Endurance","SpikeAnchor","RasenganFocus","QuickHands","RasenganDrive","SealInk","ParrySeal","StringFlash","AirExit","LongSeal"}},
		Legendary={Why="Everything, with the floor-seal air spike.",
			Nodes={"SealInk","LongSeal","SealCraft","KunaiRecall","ReturnSeal","FlashEconomy","StringFlash","SpikeAnchor","AirExit","ParrySeal","YellowFlow","QuickstepCut","GaleChase","RasenganFocus","RasenganDrive","DeepReserves","Endurance","QuickHands"}},
	},
	Mirage={
		Beginner={Why="Crow counter and blades: calm defence first.",
			Nodes={"EconomicRead","CrowCounter","Precision","WideFan","SteadyBreath"}},
		Medium={Why="A longer Read and ricochets that lead to a chase.",
			Nodes={"EconomicRead","CrowCounter","Precision","WideFan","SteadyBreath","QuickRead","PatientRead","RicochetChase"}},
		Hard={Why="Feint echoes and the palm that finds the wall.",
			Nodes={"EconomicRead","CrowCounter","Precision","WideFan","SteadyBreath","QuickRead","PatientRead","RicochetChase","FeintEcho","WallPalm","Composure"}},
		Boss={Why="Flank blades and burning geometry: every angle is covered.",
			Nodes={"EconomicRead","CrowCounter","Precision","WideFan","SteadyBreath","QuickRead","PatientRead","RicochetChase","FeintEcho","WallPalm","Composure","FlankBlades","FireTempo","FireGeometry"}},
		Legendary={Why="Everything, with the patient Read and the awakened reflex.",
			Nodes={"QuickRead","EconomicRead","PatientRead","MirageReflex","CrowCounter","Precision","WideFan","RicochetChase","FlankBlades","FeintEcho","WallPalm","ShortSigns","PhoenixVolley","FireTempo","FireGeometry","SteadyBreath","Composure"}},
	},
	GentleFist={
		Beginner={Why="The Rotation defence and a second point on the circular step.",
			Nodes={"SwiftRotation","WideDome","PrecisePalms","PointStep","Conditioning"}},
		Medium={Why="Blades come back off the dome; the vacuum palm closes points.",
			Nodes={"SwiftRotation","WideDome","PrecisePalms","PointStep","Conditioning","ReturningRotation","VacuumEconomy","SealingPalm"}},
		Hard={Why="The outside-step substitution and deeper points.",
			Nodes={"SwiftRotation","WideDome","PrecisePalms","PointStep","Conditioning","ReturningRotation","VacuumEconomy","SealingPalm","NarrowBlindSpot","OutsideStep","DeepPoints"}},
		Boss={Why="Redirecting parries, wall rebounds and a lasting seal.",
			Nodes={"SwiftRotation","WideDome","PrecisePalms","PointStep","Conditioning","ReturningRotation","VacuumEconomy","SealingPalm","NarrowBlindSpot","OutsideStep","DeepPoints","RedirectParry","TrigramRebound","LingeringSeal"}},
		Legendary={Why="Everything, with the 64 Palms string ender.",
			Nodes={"PrecisePalms","DeepPoints","PointStep","PalmBarrage","FullFieldPoints","SwiftRotation","WideDome","ReturningRotation","NarrowBlindSpot","RedirectParry","OutsideStep","VacuumEconomy","SealingPalm","LingeringSeal","TrigramRebound","Conditioning","ChakraControl","ChakraReserve"}},
	},
	Lion={
		Beginner={Why="The Dancing Leaf from the heavy and cheaper fire.",
			Nodes={"DancingLeaf","FireMastery","PhoenixTempo","Stamina","ChakraFlow"}},
		Medium={Why="Wired flames into the Dragon Flame, sharper eyes.",
			Nodes={"DancingLeaf","FireMastery","PhoenixTempo","Stamina","ChakraFlow","ShurikenFan","WiredFlames","SharperEyes"}},
		Hard={Why="Sharingan counters, a faster Chidori, a lighter curse.",
			Nodes={"DancingLeaf","FireMastery","PhoenixTempo","Stamina","ChakraFlow","ShurikenFan","WiredFlames","SharperEyes","SharinganCounter","ChidoriFocus","CurseControl"}},
		Boss={Why="Blood for chakra and the counter-rush: the cornered assault.",
			Nodes={"DancingLeaf","FireMastery","PhoenixTempo","Stamina","ChakraFlow","ShurikenFan","WiredFlames","SharperEyes","SharinganCounter","ChidoriFocus","CurseControl","CurseBlood","CounterRush"}},
		Legendary={Why="Everything, with the wired flames.",
			Nodes={"DancingLeaf","SharperEyes","SharinganCounter","CounterRush","ShurikenFan","BlockedTool","WireCancel","WiredFlames","FireMastery","PhoenixTempo","ChidoriFocus","ChidoriEconomy","WallChidori","CurseControl","CurseBlood","Stamina","ChakraFlow","Reserves"}},
	},
}
-- One example build per ranked bracket: what a fighter looks like at that budget.
Presets.Ranked={
	Flashstep={
		Fundamentals={Why="Teleport strings, kunai recall and the quickstep cut.",
			Nodes={"FlashEconomy","StringFlash","SealInk","KunaiRecall","QuickstepCut","DeepReserves","Endurance"}},
		Identity={Why="The air chain: switch seal and air exits.",
			Nodes={"FlashEconomy","StringFlash","SealInk","KunaiRecall","QuickstepCut","DeepReserves","Endurance","AirSwitchSeal","AirExit","SealCraft","LongSeal","QuickHands"}},
		Advanced={Why="Return seals and the gust that re-enters.",
			Nodes={"FlashEconomy","StringFlash","SealInk","KunaiRecall","QuickstepCut","DeepReserves","Endurance","AirSwitchSeal","AirExit","SealCraft","LongSeal","QuickHands","ReturnSeal","RasenganFocus","GaleChase"}},
		Endgame={Why="The whole tree with the switch seal.",
			Nodes={"SealInk","LongSeal","SealCraft","KunaiRecall","ReturnSeal","FlashEconomy","StringFlash","AirSwitchSeal","AirExit","ParrySeal","YellowFlow","QuickstepCut","GaleChase","RasenganFocus","RasenganDrive","DeepReserves","Endurance","QuickHands"}},
	},
	Mirage={
		Fundamentals={Why="Read cancels, ricochet chases, the feint echo and the crow counter.",
			Nodes={"QuickRead","ReadCancel","Precision","RicochetChase","FeintEcho","EconomicRead","CrowCounter"}},
		Identity={Why="Geometry everywhere: wall palm, wide fan, flank blades.",
			Nodes={"QuickRead","ReadCancel","Precision","RicochetChase","FeintEcho","EconomicRead","CrowCounter","WallPalm","WideFan","FlankBlades","SteadyBreath"}},
		Advanced={Why="Adds burning geometry.",
			Nodes={"QuickRead","ReadCancel","Precision","RicochetChase","FeintEcho","EconomicRead","CrowCounter","WallPalm","WideFan","FlankBlades","SteadyBreath","FireTempo","FireGeometry","Composure"}},
		Endgame={Why="The whole tree with the Read cancel.",
			Nodes={"QuickRead","EconomicRead","ReadCancel","MirageReflex","CrowCounter","Precision","WideFan","RicochetChase","FlankBlades","FeintEcho","WallPalm","ShortSigns","PhoenixVolley","FireTempo","FireGeometry","SteadyBreath","Composure"}},
	},
	GentleFist={
		Fundamentals={Why="Kaiten cancels, returning blades, redirecting parries.",
			Nodes={"PrecisePalms","KaitenCancel","SwiftRotation","ReturningRotation","NarrowBlindSpot","RedirectParry","Conditioning"}},
		Identity={Why="Points everywhere: step, sealing palm, outside step.",
			Nodes={"PrecisePalms","KaitenCancel","SwiftRotation","ReturningRotation","NarrowBlindSpot","RedirectParry","Conditioning","PointStep","VacuumEconomy","SealingPalm","OutsideStep","ChakraControl"}},
		Advanced={Why="Wall rebounds and a wider dome.",
			Nodes={"PrecisePalms","KaitenCancel","SwiftRotation","ReturningRotation","NarrowBlindSpot","RedirectParry","Conditioning","PointStep","VacuumEconomy","SealingPalm","OutsideStep","ChakraControl","TrigramRebound","WideDome","DeepPoints"}},
		Endgame={Why="The whole tree with the 64 Palms ender.",
			Nodes={"PrecisePalms","DeepPoints","PointStep","PalmBarrage","FullFieldPoints","SwiftRotation","WideDome","ReturningRotation","NarrowBlindSpot","RedirectParry","OutsideStep","VacuumEconomy","SealingPalm","LingeringSeal","TrigramRebound","Conditioning","ChakraControl","ChakraReserve"}},
	},
	Lion={
		Fundamentals={Why="Dancing Leaf from the heavy, Sharingan counters, wire cancels.",
			Nodes={"DancingLeaf","SharperEyes","SharinganCounter","BlockedTool","WireCancel","ChidoriFocus","Stamina"}},
		Identity={Why="Wire pins on the walls and the counter-rush.",
			Nodes={"DancingLeaf","SharperEyes","SharinganCounter","BlockedTool","WireCancel","ChidoriFocus","Stamina","ShurikenFan","WirePin","CounterRush","FireMastery","ChakraFlow"}},
		Advanced={Why="A cheaper, faster Chidori and a lighter curse.",
			Nodes={"DancingLeaf","SharperEyes","SharinganCounter","BlockedTool","WireCancel","ChidoriFocus","Stamina","ShurikenFan","WirePin","CounterRush","FireMastery","ChakraFlow","CurseControl","ChidoriEconomy","PhoenixTempo","Reserves"}},
		Endgame={Why="The whole tree with the wall wire.",
			Nodes={"DancingLeaf","SharperEyes","SharinganCounter","CounterRush","ShurikenFan","BlockedTool","WireCancel","WirePin","FireMastery","PhoenixTempo","ChidoriFocus","ChidoriEconomy","WallChidori","CurseControl","CurseBlood","Stamina","ChakraFlow","Reserves"}},
	},
}
function Presets.tier(id)
	for _,tier in Presets.AITiers do if tier.Id==id then return tier end end
	return nil
end
-- A copy of a preset's node list, or nil when it does not exist.
function Presets.ai(fighterId,tier)
	local preset=Presets.AI[fighterId] and Presets.AI[fighterId][tier]
	return preset and table.clone(preset.Nodes)
end
function Presets.ranked(fighterId,bracketId)
	local preset=Presets.Ranked[fighterId] and Presets.Ranked[fighterId][bracketId]
	return preset and table.clone(preset.Nodes)
end
return Presets
