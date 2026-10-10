-- Character move graphs: the data half of each fighter's combat identity.
-- Shared fundamentals (strings, launcher, chase, air route, defence) live in
-- Brawler/Combat; what a fighter does *differently* inside them is declared
-- here, so a new prodigy adds a table entry plus only the bespoke code its kit
-- really needs.
--
-- Directional combo grammar (shared by every fighter, interpreted by each):
--   routes.up      stick toward the opponent + strike, 2+ hits in: launcher
--   routes.down    stick away + strike, 2+ hits in: low route (sweep)
--   routes.side    stick left/right + strike, 1+ hit in: lateral route
--   routes.airUp / airDown / airSide   the same grammar after an air hit:
--                  drive away, spike down, switch sides
--   disengage      stick away + tool inside a string: hop out behind a throw
--   onRoute[name]  what that fighter's version of a route adds (a seal, blades)
--   stringCancels[techniqueId] techniques that may cancel a clean string
--                              (with a shortened wind-up)
--   blockCancels[action]       actions still allowed out of a blocked light
--   readCounter                move started by the next press after a Read
return {
	Flashstep={
		routes={up="Launcher",down="Sweep",side="AngleStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		-- The rising kick leaves a seal on the body (2 follows it up); the leg
		-- sweep plants a marked kunai where the opponent fell.
		onRoute={Launcher="bodySeal",Sweep="floorSeal"},
		-- Heavy after one clean cut: a rising knee that pops the opponent up.
		heavyAfterOne="KneeStrike",
		stringCancels={BurstStrike=true},
		blockCancels={},
	},
	Mirage={
		routes={up="Launcher",down="Sweep",side="FeintStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Shuriken",
		-- The rising palm is covered by two shuriken thrown up after the body;
		-- the feint step leaves an afterimage where he stood.
		onRoute={Launcher="coverBlades",AirDrive="coverBlades"},
		-- Heavy after one clean strike: the palm that drives the opponent away
		-- (toward a wall when one is near) instead of the launcher.
		heavyAfterOne="CounterPalm",
		stringCancels={},
		blockCancels={Tool=true},
		readCounter="CounterPalm",
	},
	GentleFist={
		routes={up="Launcher",down="Sweep",side="CircleStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		-- Every Gentle Fist route closes chakra points; the low route closes two.
		onRoute={Sweep="tenketsu"},
		-- Heavy after a single clean palm: a twin-palm thrust that drives the
		-- opponent away (into a wall when one is near) instead of the launcher.
		heavyAfterOne="PalmThrust",
		stringCancels={VacuumPalm=true},
		blockCancels={},
		-- After Rotation repels an attack, the next press is the palm thrust.
		readCounter="PalmThrust",
	},
	Sand={
		routes={up="SandPillar",down="Sweep"},
		-- One lash, then the pillar: sand erupts under the opponent.
		heavyAfterOne="SandPillar",
		stringCancels={SandCoffin=true},
		blockCancels={Tool=true},
	},
}
