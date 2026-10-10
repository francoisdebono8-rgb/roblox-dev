-- Character move graphs: the data half of each fighter's combat identity.
-- Shared fundamentals (strings, launcher, chase, air route, defence) live in
-- Brawler/Combat; what a fighter does *differently* inside them is declared
-- here, so a new prodigy adds a table entry plus only the bespoke code its kit
-- really needs.
--
--   stringBranches[direction]  what a press does inside a clean string when the
--                              stick points side / back / forward:
--                              {kind="move",name=<Attacks entry>} or
--                              {kind="disengage",projectile=<throw kind>}
--   stringCancels[techniqueId] techniques that may cancel a clean string
--                              (with a shortened wind-up)
--   blockCancels[action]       actions still allowed out of a blocked light
--   readCounter                move started by the next press after a Read
return {
	Flashstep={
		stringBranches={
			side={kind="move",name="AngleStep"},
			back={kind="disengage",projectile="Kunai"},
		},
		stringCancels={BurstStrike=true},
		blockCancels={},
	},
	Mirage={
		stringBranches={
			side={kind="move",name="Sweep"},
			back={kind="disengage",projectile="Shuriken"},
		},
		stringCancels={},
		blockCancels={Tool=true},
		readCounter="CounterPalm",
	},
}
