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
	Lion={
		routes={up="LionKick",down="Sweep",side="VaultKick",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Shuriken",
		-- The rising kick is followed into the air at once (Shadow of the
		-- Dancing Leaf); a heavy there is the Lion Combo.
		onRoute={LionKick="shadowLeaf"},
		heavyAfterOne="KneeStrike",
		stringCancels={Chidori=true},
		blockCancels={},
	},
	Sand={
		routes={up="SandPillar",down="Sweep"},
		-- One lash, then the pillar: sand erupts under the opponent.
		heavyAfterOne="SandPillar",
		stringCancels={SandCoffin=true},
		blockCancels={Tool=true},
	},
	-- Rock Lee (stress-test wave, DEC-015): kicks all the way, no blade, so no
	-- disengage. Toward after two hits: the Leaf Rising Wind, followed into the
	-- air at once (the shared Shadow of the Dancing Leaf; Sasuke copied it from
	-- him); a heavy up there is his own finisher (airFinisher) instead of the
	-- Lion Combo. Away: the Leaf Hurricane, a low spinning kick that keeps the
	-- string going instead of ending it. Sideways: the Leaf Whirlwind, a wide
	-- spinning kick that catches a side step instead of taking an angle.
	Leaf={
		routes={up="LeafRising",down="LeafHurricane",side="LeafWhirlwind",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		onRoute={LeafRising="shadowLeaf"},
		heavyAfterOne="KneeStrike",
		stringCancels={LeafGreatWhirlwind=true},
		blockCancels={},
		--   airFinisher   the heavy inside the Shadow of the Dancing Leaf window
		--                 (Brawler.airFinisher): name (the client clip), cue,
		--                 event, damage, impulse, reaction, stun; healthCost is
		--                 paid from his own health (never to a KO) and refused
		--                 at or under minHealth (then `fallback`); `awakened`
		--                 replaces it, free, while the awakening burns.
		-- Primary Lotus: the body driven head first into the floor. In the Fifth
		-- Gate, the Hidden Lotus: harder, free, and the body bounces back up for
		-- one more strike.
		airFinisher={name="PrimaryLotus",cue="PRIMARY LOTUS",event="PrimaryLotus",damage=22,impulse=Vector3.new(0,-96,6),healthCost=10,minHealth=26,
			fallback={name="LeafHeel",cue="LEAF HEEL • NO STRENGTH LEFT FOR THE LOTUS",event="LeafHeel",damage=14},
			awakened={name="HiddenLotus",cue="FIFTH GATE • HIDDEN LOTUS",event="HiddenLotus",damage=26,reaction="Spiked",impulse=Vector3.new(0,-104,4),stun=.9}},
	},
}
