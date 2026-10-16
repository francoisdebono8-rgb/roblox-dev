-- Character move graphs: the data half of each fighter's combat identity.
-- Shared fundamentals (strings, launcher, chase, air route, defence) live in
-- Brawler/Combat; what a fighter does *differently* inside them is declared
-- here, so a new prodigy adds a table entry plus only the bespoke code its kit
-- really needs.
--
-- Directional combo grammar (shared by every fighter, interpreted by each).
-- Hits are CONFIRMED hits (a whiff or a blocked strike restarts the string);
-- the stick is read relative to the opponent through a short memory
-- (Config.Combo), so a push released a moment before the press still counts.
--   routes.up      stick toward the opponent + strike, 2+ hits in: launcher
--   routes.down    stick away + strike, 2+ hits in: low route (sweep)
--   routes.side    stick left/right + strike, 1+ hit in: lateral route
--   routes.airUp / airDown / airSide   the same grammar after an air hit:
--                  drive away, spike down, switch sides
--   disengage      stick away + tool inside a string: hop out behind a throw
--   onRoute[name]  what that fighter's version of a route adds (a seal, blades)
--   heavyAfterOne  heavy after one clean hit, and the heavy on a re-engage
--                  arrival (chase or chakra dash)
--   stringCancels[techniqueId] techniques that may cancel a clean string
--                              (with a shortened wind-up)
--   blockCancels[action]       actions still allowed out of a blocked light
--   readCounter                move started by the next press after a Read
--   reengage       how the prodigy re-enters (Combat:reengage / chase / rush):
--                  speed (x Config.Rush.Speed), arrive (studs short of the
--                  body), angle (degrees off the line he arrives on), chase
--                  (seconds of a chase), recovery (an unanswered arrival),
--                  minRange, and the style's own rules: sealAngle/sealPull
--                  (a planted seal near the target), afterimage + feint (guard
--                  or dodge aborts the dash), commit + past (the line is fixed
--                  after `commit` s and aims `past` studs through the body),
--                  dashDamage (the arrival strike). `name` reaches the client.
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
		-- Surgical: the fastest re-entry, onto an angle beside the body; a seal
		-- planted near the target pulls him onto its side, wider and quicker.
		reengage={name="flash",speed=1.3,arrive=3.2,angle=32,sealAngle=58,sealPull=1.12,chase=.24,recovery=.14},
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
		-- Body attack -> projectile cover: a clean string ends in Shadow Shuriken.
		stringCancels={NeedleFan=true},
		blockCancels={Tool=true},
		readCounter="CounterPalm",
		-- Calm and deceptive: a slower approach that leaves an afterimage where
		-- he started, arrives a little aside, and can be aborted (guard or dodge).
		reengage={name="mirage",speed=.8,arrive=3.8,angle=18,afterimage=true,feint=true,chase=.34,recovery=.2},
	},
	GentleFist={
		routes={up="Launcher",down="Sweep",side="CircleStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		-- Every Gentle Fist route closes chakra points; the low routes (the sweep
		-- and the descending air palm) close two.
		onRoute={Sweep="tenketsu",AirSpike="tenketsu"},
		-- Heavy after a single clean palm: a twin-palm thrust that drives the
		-- opponent away (into a wall when one is near) instead of the launcher.
		heavyAfterOne="PalmThrust",
		stringCancels={VacuumPalm=true},
		blockCancels={},
		-- After Rotation repels an attack, the next press is the palm thrust.
		readCounter="PalmThrust",
		-- Compact and direct: straight down the centre line, tighter, and from
		-- closer than anyone else.
		reengage={name="palm",speed=1.02,arrive=2.9,angle=0,minRange=5,chase=.3,recovery=.18},
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
		-- Explosive and committed: fast, his line is fixed almost at once and aims
		-- through the body (a side-step makes him overshoot), the arrival strike
		-- hits harder, an unanswered arrival recovers longest.
		reengage={name="lion",speed=1.15,arrive=2.8,angle=0,commit=.06,past=2.6,dashDamage=1.15,chase=.28,recovery=.3},
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
		-- Relentless: the fastest re-entry of all, straight down the line, from
		-- closer than most, and the shortest recovery after an arrival.
		reengage={name="leaf",speed=1.4,arrive=3,angle=0,minRange=6,chase=.24,recovery=.16},
	},
	-- Temari (roster wave): the fan strikes make distance. Toward after two
	-- hits: the Updraft, a scoop into a column of rising air (onRoute "updraft",
	-- Gale.updraft): the body comes down slowly, in reach of the wind, not of a
	-- chase. Away: the closed fan slammed down. Sideways after one: a full turn,
	-- the gust throws the body aside (Attacks lateral). In the air, the drive
	-- and the Fan Dive; no switch (she does not vault over anyone).
	--   reengage.reposition  the wind step (Gale.reposition): E outside a chase
	--                        window takes her back to `keep` studs (out at an
	--                        `angle` when close, in when far, aside at range),
	--                        never into melee.
	Gale={
		routes={up="Updraft",down="FanSlam",side="FanPirouette",airUp="AirDrive",airDown="FanDive"},
		onRoute={Updraft="updraft"},
		heavyAfterOne="FanBackhand",
		stringCancels={Kamaitachi=true},
		blockCancels={Tool=true},
		reengage={name="gale",reposition=true,keep=17,speed=1.0,reach=22,angle=30,side=10,chase=.26,recovery=.16},
	},
}
