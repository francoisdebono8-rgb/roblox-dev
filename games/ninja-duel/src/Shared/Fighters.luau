return {
	Flashstep = {
		Name = "Minato", FullName = "Minato Namikaze", Age = 13, Title = "THE FAST PRODIGY", Color = { 82, 177, 244 },
		Description = "Decision speed. Kunai placement, angle changes and an unfinished teleport seal.",
		Health = 125, Chakra = 110, ChakraRegen = 8, Speed = 25, SprintScale = 1.12, JumpScale = 1.1, AirControlScale = 1.15, AccelerationScale = 1.15,
		CombatTravel = 1.18, CombatDamage = 1, DashScale = 1.15, GuardStrength = 0.10, PreferredRange = 6,
		ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
		AttackProfile = {
			Light1={startup=.82,recovery=.9,travel=1.08,angle=.24},Light2={startup=.84,recovery=.9,travel=1.12,angle=-.3},
			Light3={startup=.82,recovery=.88,travel=1.2,angle=.36,impulseZ=52},Launcher={startup=.72,travel=1.16,impulseY=62},
			DashAttack={startup=.78,travel=1.16,angle=-.18},Air1={startup=.8,angle=.24},Air2={startup=.82,angle=-.3},Slam={startup=.78,recovery=.86},
		},
		Skin = { 225, 196, 166 }, Hair = { 225, 228, 212 }, Outfit = { 45, 104, 156 },
		Techniques = {
			-- Thrown while running: the seal travels as a real kunai and can be
			-- reached mid-flight by Flying Thunder God.
			{ Id = "MarkedBlade", Name = "Marked Kunai", Mobile = true, Throw = "MarkedKunai", Cost = 10, Channel = 0.12, Active = 0.02, Recovery = 0, Cooldown = 2.2, Interruptible = true, Range = 50, Damage = 6, Hint = "Two seals planted at once • a hit seals the body" },
			{ Id = "Flashstep", Name = "Flying Thunder God", Cost = 16, Channel = 0.06, Active = 0.04, Recovery = 0.2, Cooldown = 1.5, Interruptible = true, Range = 60, Requires = "Anchor", Hint = "Stick picks the seal and the side • strike or 3 on arrival" },
			{ Id = "BurstStrike", Name = "Rasengan", Cost = 24, Channel = 0.3, Active = 0.08, Recovery = 0.5, Cooldown = 5.5, Interruptible = true, Range = 8, Damage = 20, Hint = "Instant after a teleport • plunges when airborne • ends a clean string" },
			{ Id = "Quickstep", Name = "Quickstep", Cost = 12, Channel = 0.11, Active = 0.08, Recovery = 0.21, Cooldown = 2.3, Interruptible = true, Range = 12, Hint = "Create an angle • no guaranteed hit" },
			{ Id = "WindCut", Name = "Wind Cut", Element = "Wind", Cost = 18, Channel = 0.32, Active = 0.1, Recovery = 0.34, Cooldown = 3.7, Interruptible = true, Range = 29, Damage = 7, Hint = "Displace with a cutting gust" },
		},
	},
	Mirage = {
		Name = "Itachi", FullName = "Itachi Uchiha", Age = 13, Title = "THE SHARINGAN PRODIGY", Color = { 222, 70, 80 },
		Description = "Sharingan already awakened. Reads, precise shuriken, deception and Katon fire.",
		Health = 145, Chakra = 125, ChakraRegen = 7.2, Speed = 23.5, SprintScale = 1.0, JumpScale = 0.98, AirControlScale = 0.95, AccelerationScale = 0.98,
		CombatTravel = 0.98, CombatDamage = 1.1, DashScale = 0.98, GuardStrength = 0.08, PreferredRange = 10,
		-- The Sharingan (three tomoe at 13): it sees strikes coming. Wider parry
		-- and perfect-dodge windows, each successful one opens a counter, and a
		-- raised guard tracks a teleport instead of being crossed up.
		Sharingan = { ParryWindow = 0.3, PerfectDodge = 0.22, Counter = 0.9 },
		ComboToolCancel = true, CombatStyle = "Control", Tool = "Shuriken",
		AttackProfile = {
			Light1={startup=.96,recovery=.9,travel=.92,range=6.6},Light2={startup=.98,recovery=.88,travel=.9,range=7,chainTool=true},
			Light3={startup=1.02,recovery=1.0,travel=.86,impulseZ=60},Heavy={startup=.98,recovery=1.02,travel=.9},
			Launcher={startup=1.0,travel=.86,impulseY=53,impulseZ=20},DashAttack={startup=.95,travel=.92},
			Air1={startup=.98,travel=.9},Air2={startup=1.0,travel=.88},Slam={startup=1.0,recovery=1.0},
		},
		Skin = { 197, 164, 143 }, Hair = { 30, 31, 43 }, Outfit = { 69, 49, 66 },
		Techniques = {
			{ Id = "Read", Name = "Sharingan Read", Cost = 14, Channel = 0.1, Active = 1.0, Recovery = 0.2, Cooldown = 3.6, Interruptible = false, Range = 10, Hint = "Read one frontal strike or Rasengan • counter" },
			{ Id = "NeedleFan", Name = "Shadow Shuriken", Cost = 18, Channel = 0.26, Active = 0.08, Recovery = 0.26, Cooldown = 3.6, Interruptible = true, Range = 42, Damage = 2, Hint = "Five blades, then two hidden ones aimed at the dodge" },
			{ Id = "MirageCast", Name = "Genjutsu: Mirage", Cost = 32, Channel = 0.9, Active = 0.08, Recovery = 0.45, Cooldown = 8, Interruptible = true, Range = 23, Requires = "Target", Hint = "3s decoy • a swing at it opens a punish" },
			{ Id = "FireBloom", Name = "Great Fireball", Element = "Fire", Cost = 26, Channel = 0.55, Active = 0.42, Recovery = 0.36, Cooldown = 5.5, Interruptible = true, Feintable = true, Range = 62, Speed = 54, Damage = 16, Hint = "A miss leaves the lane burning" },
			{ Id = "PhoenixFlower", Name = "Phoenix Flower", Element = "Fire", Cost = 20, Channel = 0.3, Active = 0.32, Recovery = 0.3, Cooldown = 5, Interruptible = true, Range = 48, Speed = 68, Damage = 4, Hint = "Five small flames fanned at the opponent • pressure" },
		},
	},
	-- Third prototype: the Hyuga genius at the Chunin Exam finals. Pure taijutsu
	-- with a different engine: palms that attack chakra, not health alone.
	GentleFist = {
		Name = "Neji", FullName = "Neji Hyuga", Age = 13, Title = "THE HYUGA GENIUS", Color = { 176, 196, 255 },
		Description = "Byakugan and the Gentle Fist. Palms that close chakra points, a perfect rotation defence.",
		Health = 135, Chakra = 115, ChakraRegen = 7.6, Speed = 23.5, SprintScale = 1.0, JumpScale = 0.98, AirControlScale = 0.95, AccelerationScale = 1.02,
		CombatTravel = 1.0, CombatDamage = 0.95, DashScale = 1.0, GuardStrength = 0.1, PreferredRange = 5,
		ComboToolCancel = true, CombatStyle = "GentleFist", Tool = "Kunai",
		-- Byakugan: near-360-degree sight. His guard covers every side except a
		-- narrow blind spot straight behind, and genjutsu decoys do not fool him.
		Byakugan = { BlindSpot = 0.9 },
		-- Gentle Fist: every palm drains chakra (even through a guard) and a clean
		-- one closes a chakra point, slowing the victim's chakra recovery.
		GentleFist = { Drain = 6, GuardDrain = 3, RegenCut = 0.15, MaxPoints = 4, Duration = 5 },
		AttackProfile = {
			Light1={startup=.92,recovery=.9,travel=1.0,range=6.4},Light2={startup=.94,recovery=.9,travel=1.0,range=6.6},
			Light3={startup=1.0,recovery=.96,travel=1.05,impulseZ=54},Heavy={startup=1.02,recovery=1.0},
			Launcher={startup=.98,travel=.95,impulseY=56},DashAttack={startup=.94,travel=1.02},
			Air1={startup=.96},Air2={startup=.98},Slam={startup=1.0},
		},
		Skin = { 228, 202, 178 }, Hair = { 52, 36, 30 }, Outfit = { 226, 220, 206 },
		Techniques = {
			{ Id = "Rotation", Name = "Rotation", Cost = 24, Channel = 0.04, Active = 0.55, Recovery = 0.24, Cooldown = 6, Interruptible = false, Range = 7, Damage = 6, Hint = "Spinning dome • repels strikes and blades • counter after" },
			{ Id = "VacuumPalm", Name = "Vacuum Palm", Cost = 14, Channel = 0.18, Active = 0.06, Recovery = 0.26, Cooldown = 2.8, Interruptible = true, Range = 26, Speed = 96, Damage = 7, Hint = "Air-pressure palm • pushes into walls • ends a clean string" },
			{ Id = "SixtyFourPalms", Name = "64 Palms", Cost = 30, Channel = 0.22, Active = 0.12, Recovery = 0.4, Cooldown = 10, Interruptible = true, Range = 5, Damage = 3, Hint = "Point blank • seals the chakra points (no jutsu)" },
		},
	},
}
