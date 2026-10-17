-- Roster 20, batch 2 (DEC-022): Shisui, Orochimaru, Kabuto. This batch's
-- shared data, merged into Fighters, MoveGraphs and Attacks (see Wave1).
-- Young versions only: what each of them could already do at that age.
local RosterMoves=require(script.Parent.RosterMoves)
local V=Vector3.new

local fighters={}
-- Shisui (13, "of the Body Flicker"): an Uchiha whose game is speed, not
-- reads or fire-lightning rushdown. The Body Flicker is cheap and fast and
-- strikes from the flank; a second flicker takes him out of reach; a Katon
-- fireball; a Sharingan genjutsu that seals jutsu for a moment. Narrow
-- Sharingan windows (not Itachi's). No Mangekyō: that comes later.
fighters.Flicker = {
	Name = "Shisui", FullName = "Shisui Uchiha", Age = 13, Title = "THE BODY FLICKER", Color = { 214, 120, 96 },
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ flicker step (vanishes to the flank, the string goes on)  ·  heavy after one: flicker cut  ·  air: drive / spike / switch",
	Description = "The fastest Uchiha: the Body Flicker from the flank and out of reach, a Katon fireball, a genjutsu that seals jutsu.",
	Health = 122, Chakra = 120, ChakraRegen = 8.4, Speed = 20.5, SprintScale = 1.14, JumpScale = 1.1, AirControlScale = 1.15, AccelerationScale = 1.18,
	CombatTravel = 1.15, CombatDamage = 0.96, DashScale = 1.2, GuardStrength = 0.1, PreferredRange = 7,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 100, Damage = 3, Recover = .5 },
	Sharingan = { ParryWindow = 0.22, PerfectDodge = 0.2, Counter = 0.7 },
	-- Awakening: the flicker becomes instant. Faster legs, the flickers back
	-- almost at once and for half their cost, wider read windows.
	-- Rule: a Body Flicker whose cut lands gives the flicker back at once,
	-- three times in a row (a chain of flank cuts no one else can do).
	Awakening = { Name = "SHUNSHIN NO SHISUI", Speed = 1.12, Regen = 1.3, Cooldown = 0.7, Windows = 1.2, ChainTeleport = 3, Color = { 230, 50, 60 } },
	Motion = { body = "Lion", weapons = "kunai", springy = true,
		borrow = { FlickerStep = "AngleStep", FlickerCut = "Light3" },
		-- Loose and forward, almost a runner's stance: weight on the balls of
		-- the feet, the kunai held low and back in the right hand.
		stance = {root={y=-.46,pitch=10,yaw=24},torso={pitch=8,yaw=-8},head={pitch=-6,yaw=-12},
			ra={raise=10,out=24,twist=20,elbow=40,wrist=0},la={raise=64,out=-12,twist=-30,elbow=86,wrist=-10},
			rf={x=.22,z=.6,yaw=28},lf={x=-.1,z=-.64,yaw=-6},breath=1.2,tempo=8} },
	AttackProfile = {
		Light1={startup=.86,recovery=.86,travel=1.12},Light2={startup=.86,recovery=.86,travel=1.12,kind="slash"},
		Light3={startup=.92,recovery=.92,impulseZ=50},Heavy={startup=.94},
		Launcher={startup=.9,impulseY=56},DashAttack={startup=.84,travel=1.2},Air1={startup=.88},Air2={startup=.9},
	},
	Skin = { 230, 206, 184 }, Hair = { 24, 24, 30 }, Outfit = { 40, 44, 60 },
	Techniques = {
		{ Id = "BodyFlicker", Name = "Body Flicker", Family = "Teleport", Kind = "flicker", To = "Side", Distance = 3, Move = "FlickerCut", Damage = 6,
			Cost = 10, Channel = 0.06, Active = 0.03, Recovery = 0.16, Cooldown = 1.8, Interruptible = true, Range = 34, Invuln = .12,
			Hint = "Gone and at his flank in a blink • a cut on arrival • cheap: chain it", AI = { Min = 5, Max = 30, Chance = .4 } },
		{ Id = "FlickerOut", Name = "Afterimage Retreat", Family = "Teleport", Kind = "flicker", To = "Back", Distance = 13,
			Cost = 8, Channel = 0.04, Active = 0.03, Recovery = 0.12, Cooldown = 3, Interruptible = true, Range = 13, Invuln = .25,
			Hint = "Out of reach in a blink • an afterimage takes the blow" },
		{ Id = "ShisuiFireball", Name = "Fire Release: Great Fireball", Family = "Projectile", Kind = "fireball", Element = "Fire", Cost = 22, Channel = 0.42, Active = 0.12, Recovery = 0.34, Cooldown = 6, Interruptible = true,
			Range = 40, Speed = 62, Damage = 11, Radius = 2.2, Knock = 30, Lift = 12, Hint = "A great fireball • throws the body back" },
		{ Id = "ShisuiGenjutsu", Name = "Genjutsu: Sharingan", Family = "Burst", Kind = "flicker", Cost = 18, Channel = 0.12, Active = 0.1, Recovery = 0.3, Cooldown = 10, Interruptible = true,
			Radius = 7, Arc = 0.4, Damage = 2, Seal = 2.5, Slow = { Scale = .75, Time = 2 }, Range = 7, Style = "look",
			Hint = "Eye contact up close: the opponent's jutsu sealed 2.5 s, his legs heavy" },
	},
}

-- Orochimaru (12, Hiruzen's genin, already a prodigy of ninjutsu): snakes
-- from the sleeves. A shadow snake that bites and drags the body in, a pair
-- that coil and hold it, a lunge with venom in it. Long, loose limbs (his
-- strikes reach a little further). No Kusanagi, no body transfer: adult.
fighters.Serpent = {
	Name = "Orochimaru", FullName = "Orochimaru", Age = 12, Title = "THE SNAKE PRODIGY", Color = { 130, 100, 160 },
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ feint step  ·  heavy after one: venom fang (poisons)  ·  air: drive / spike / switch",
	Description = "Snakes from the sleeves: a shadow snake that drags the body in, coils that hold it, a venomous fang.",
	Health = 130, Chakra = 130, ChakraRegen = 8, Speed = 18.5, SprintScale = 1.08, JumpScale = 1.0, AirControlScale = 1.0, AccelerationScale = 1.0,
	CombatTravel = 0.98, CombatDamage = 0.98, DashScale = 1.0, GuardStrength = 0.1, PreferredRange = 9,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 90, Damage = 3, Recover = .7 },
	-- Awakening: the snake contract. Every blow carries venom, his coils hold
	-- longer, his chakra comes back faster.
	Awakening = { Name = "SNAKE CONTRACT", Speed = 1.05, Regen = 1.45, Cooldown = 0.6, BindScale = 1.4,
		OnHit = { Poison = { Damage = .6, Time = 2, Every = .5 } }, Color = { 170, 140, 220 } },
	Motion = { body = "Mirage", weapons = "none", springy = false,
		borrow = { VenomFang = "Heavy" },
		-- Low and loose, the head forward like a snake's, the arms hanging and
		-- ready to whip out.
		stance = {root={y=-.5,pitch=14,yaw=20},torso={pitch=12,yaw=-6},head={pitch=-14,yaw=-10},
			ra={raise=24,out=18,twist=30,elbow=30,wrist=-20},la={raise=40,out=-6,twist=-30,elbow=46,wrist=-20},
			rf={x=.26,z=.56,yaw=30},lf={x=-.14,z=-.62,yaw=-10},breath=.7,tempo=4} },
	AttackProfile = {
		Light1={startup=.96,recovery=.94,range=7,contact=4},Light2={startup=.96,recovery=.94,range=7,contact=4,kind="palm"},
		Light3={startup=1.0,recovery=.98,range=7.2,impulseZ=50,kind="kick"},Heavy={startup=1.0,range=7.2},
		Launcher={startup=.98,impulseY=54},DashAttack={startup=.95,travel=1.0},Air1={startup=.96},Air2={startup=.98},
	},
	Skin = { 236, 228, 222 }, Hair = { 24, 24, 30 }, Outfit = { 70, 78, 96 },
	Techniques = {
		{ Id = "ShadowSnake", Name = "Striking Shadow Snakes", Family = "Projectile", Kind = "snake", Cost = 16, Channel = 0.26, Active = 0.06, Recovery = 0.3, Cooldown = 4, Interruptible = true,
			Range = 26, Speed = 82, Damage = 5, Radius = 1.1, Pull = 46, PullTo = 3.5, Poison = { Damage = 1, Time = 3, Every = .5 },
			Hint = "A snake from the sleeve bites and drags the body to him • venom" },
		{ Id = "SnakeCoil", Name = "Hidden Shadow Snake Hands", Family = "Projectile", Kind = "snakes", Count = 2, Spread = 0.2, Cost = 22, Channel = 0.34, Active = 0.08, Recovery = 0.3, Cooldown = 9, Interruptible = true,
			Range = 20, Speed = 72, Damage = 3, Radius = 1.1, Bind = 1.3, Crush = 6, Hint = "Two snakes coil round the body and hold it • then they squeeze" },
		{ Id = "SnakeLunge", Name = "Snake Lunge", Family = "Strike", Move = "VenomFang", Cost = 14, Channel = 0.14, Active = 0.05, Recovery = 0.1, Cooldown = 5, Interruptible = true,
			Range = 12, Damage = 9, Poison = { Damage = 1.2, Time = 3, Every = .5 }, Hint = "A lunge with a fang in it: poison", AI = { Min = 3.5, Max = 10 } },
	},
}

-- Kabuto (13, the spy medic): medical ninjutsu turned on the body. The
-- chakra scalpel cuts muscles (the body slows) and drains; a scalpel strike
-- that cuts the legs; a body flicker back that mends him on the way.
fighters.Medic = {
	Name = "Kabuto", FullName = "Kabuto Yakushi", Age = 13, Title = "THE SPY MEDIC", Color = { 120, 110, 160 },
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ circle step  ·  heavy after one: scalpel slice (slows)  ·  air: drive / spike / switch",
	Description = "Medical ninjutsu as a weapon: the chakra scalpel cuts muscles, he mends himself on the way out.",
	Health = 130, Chakra = 125, ChakraRegen = 9, Speed = 19, SprintScale = 1.08, JumpScale = 1.02, AirControlScale = 1.0, AccelerationScale = 1.04,
	CombatTravel = 1.02, CombatDamage = 0.92, DashScale = 1.04, GuardStrength = 0.12, PreferredRange = 4.5,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 90, Damage = 3, Recover = .7 },
	-- Awakening: the medical genius. Chakra back fast, every blow cuts a
	-- muscle (slows), techniques back sooner.
	Awakening = { Name = "MEDICAL GENIUS", Speed = 1.05, Regen = 1.6, Cooldown = 0.6, OnHit = { Slow = { Scale = .8, Time = 1.2 } }, Color = { 120, 240, 190 } },
	Motion = { body = "GentleFist", weapons = "palms", springy = false,
		borrow = { ScalpelSlice = "PalmThrust" },
		-- Calm and neat, glasses-level composure: upright, both hands open and
		-- low, ready to cut.
		stance = {root={y=-.26,pitch=4,yaw=22},torso={pitch=2,yaw=-8},head={pitch=0,yaw=-12},
			ra={raise=40,out=10,twist=20,elbow=70,wrist=-10},la={raise=50,out=-10,twist=-20,elbow=80,wrist=-10},
			rf={x=.2,z=.56,yaw=30},lf={x=-.08,z=-.56,yaw=-6},breath=.6,tempo=5} },
	AttackProfile = {
		Light1={startup=.92,recovery=.9,range=6.2,kind="palm"},Light2={startup=.92,recovery=.9,range=6.2,kind="palm"},
		Light3={startup=.98,recovery=.96,impulseZ=48,kind="palm"},Heavy={startup=1.0,kind="palm"},
		Launcher={startup=.98,impulseY=54},DashAttack={startup=.94},Air1={startup=.96},Air2={startup=.98},
	},
	Skin = { 236, 214, 196 }, Hair = { 200, 200, 206 }, Outfit = { 110, 84, 130 },
	Techniques = {
		{ Id = "ChakraScalpel", Name = "Chakra Scalpel", Family = "Buff", Kind = "scalpel", Cost = 18, Channel = 0.25, Active = 0.05, Recovery = 0.2, Cooldown = 12, Interruptible = true,
			Time = 8, Damage = 1.1, Range = 20, OnHit = { Slow = { Scale = .72, Time = 1.6 }, Drain = 3 },
			Hint = "Blades of chakra on his hands for 8 s: every blow cuts a muscle (slows) and drains" },
		{ Id = "TendonCut", Name = "Scalpel: Tendon Cut", Family = "Strike", Move = "ScalpelSlice", Cost = 12, Channel = 0.12, Active = 0.05, Recovery = 0.1, Cooldown = 4.5, Interruptible = true,
			Range = 10, Damage = 8, Slow = { Scale = .6, Time = 2.4 }, Hint = "A low cut at the legs: the body slows hard", AI = { Min = 3, Max = 9 } },
		{ Id = "MendingRetreat", Name = "Mystical Palm Retreat", Family = "Teleport", Kind = "scalpel", To = "Back", Distance = 11, Heal = 14,
			Cost = 20, Channel = 0.1, Active = 0.04, Recovery = 0.2, Cooldown = 11, Interruptible = true, Range = 11, Invuln = .2,
			Hint = "A flicker out of reach, the Mystical Palm closing his wounds" },
	},
}

local graphs={
	Flicker={
		routes={up="Launcher",down="Sweep",side="FlickerStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="FlickerCut",
		stringCancels={BodyFlicker=true,FlickerOut=true},
		blockCancels={Tool=true},
		-- The fastest re-entry on the widest angle, never twice the same side.
		reengage={name="flicker",speed=1.45,arrive=3,angle=55,shuffle=true,chase=.24,recovery=.14},
	},
	Serpent={
		routes={up="Launcher",down="Sweep",side="FeintStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="VenomFang",
		stringCancels={ShadowSnake=true},
		blockCancels={Tool=true},
		reengage={name="serpent",speed=1.0,arrive=3.6,angle=25,chase=.3,recovery=.2},
	},
	Medic={
		routes={up="Launcher",down="Sweep",side="CircleStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="ScalpelSlice",
		stringCancels={TendonCut=true,MendingRetreat=true},
		blockCancels={},
		reengage={name="medic",speed=1.0,arrive=3,angle=10,chase=.3,recovery=.2},
	},
}

local function attacks(move,list)
	RosterMoves.add(move,list,{
		-- Shisui: a flicker to the flank that keeps the string, the cut on arrival.
		FlickerStep={{.07,.1,.2,6,1.2,"HitStun",V(0,0,9),.3},{contact=3.4,range=6.5,width=5,zone="body",kind="slash",side=1,twist=40,lean=10,arm=90,step=1.1,orbit=40,chain=true}},
		FlickerCut={{.07,.12,.3,8,2.8,"Knockback",V(0,10,44),.48},{contact=3.6,range=6.8,zone="body",kind="slash",side=1,twist=60,lean=14,arm=100,step=1.2}},
		-- Orochimaru: a fang lunge (venom).
		VenomFang={{.09,.14,.32,8,3.4,"Knockback",V(0,8,40),.48},{contact=4,range=7.4,zone="body",kind="strike",side=1,twist=24,lean=26,arm=110,step=1.25,riders={Poison={Damage=1,Time=2.5,Every=.5}}}},
		-- Kabuto: a scalpel slice at the legs (slows).
		ScalpelSlice={{.1,.12,.32,9,3,"Knockback",V(0,8,42),.48},{contact=3.6,range=6.6,zone="legs",kind="palm",side=1,twist=20,lean=20,arm=100,step=1.2,riders={Slow={Scale=.7,Time=1.8}}}},
	})
end

return {
	fighters=fighters,
	graphs=graphs,
	attacks=attacks,
}
