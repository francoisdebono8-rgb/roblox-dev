return {
	Flashstep = {
		Name = "Minato", FullName = "Minato Namikaze", Age = 13, Title = "THE FAST PRODIGY", Color = { 82, 177, 244 },
		Description = "Decision speed. Kunai placement, angle changes and an unfinished teleport seal.",
		Health = 125, Chakra = 110, ChakraRegen = 10.5, Speed = 29, SprintScale = 1.12, JumpScale = 1.1, AirControlScale = 1.15, AccelerationScale = 1.15,
		CombatTravel = 1.18, CombatDamage = 1, DashScale = 1.15, GuardStrength = 0.10, PreferredRange = 6,
		ComboToolCancel = true, CombatStyle = "Angles",
		AttackProfile = {
			Light1={startup=.82,recovery=.9,travel=1.08,angle=.24},Light2={startup=.84,recovery=.9,travel=1.12,angle=-.3},
			Light3={startup=.82,recovery=.88,travel=1.2,angle=.36,impulseZ=52},Launcher={startup=.72,travel=1.16,impulseY=62},
			DashAttack={startup=.78,travel=1.16,angle=-.18},Air1={startup=.8,angle=.24},Air2={startup=.82,angle=-.3},Slam={startup=.78,recovery=.86},
		},
		Skin = { 225, 196, 166 }, Hair = { 225, 228, 212 }, Outfit = { 45, 104, 156 },
		Techniques = {
			-- Thrown while running: the seal travels as a real kunai and can be
			-- reached mid-flight by Flying Thunder God.
			{ Id = "MarkedBlade", Name = "Marked Kunai", Mobile = true, Throw = "MarkedKunai", Cost = 10, Channel = 0.12, Active = 0.02, Recovery = 0, Cooldown = 2.2, Interruptible = true, Range = 50, Damage = 6, Hint = "Throw a sealed kunai • lasts 12s once planted" },
			{ Id = "Flashstep", Name = "Flying Thunder God", Cost = 18, Channel = 0.06, Active = 0.04, Recovery = 0.2, Cooldown = 2.6, Interruptible = true, Range = 60, Requires = "Anchor", Hint = "Teleport to the seal • strike on arrival" },
			{ Id = "BurstStrike", Name = "Rasengan", Cost = 24, Channel = 0.3, Active = 0.08, Recovery = 0.5, Cooldown = 5.5, Interruptible = true, Range = 8, Damage = 20, Hint = "Unfinished prototype • cancel a clean string into it" },
			{ Id = "Quickstep", Name = "Quickstep", Cost = 12, Channel = 0.11, Active = 0.08, Recovery = 0.21, Cooldown = 2.3, Interruptible = true, Range = 12, Hint = "Create an angle • no guaranteed hit" },
			{ Id = "WindCut", Name = "Wind Cut", Element = "Wind", Cost = 18, Channel = 0.32, Active = 0.1, Recovery = 0.34, Cooldown = 3.7, Interruptible = true, Range = 29, Damage = 7, Hint = "Displace with a cutting gust" },
		},
	},
	Mirage = {
		Name = "Itachi", FullName = "Itachi Uchiha", Age = 13, Title = "THE QUIET OBSERVER", Color = { 222, 70, 80 },
		Description = "Calm control. Shuriken geometry, timed reads, deception and the clan's first fire.",
		Health = 145, Chakra = 125, ChakraRegen = 8, Speed = 26, SprintScale = 0.98, JumpScale = 0.95, AirControlScale = 0.9, AccelerationScale = 0.92,
		CombatTravel = 0.95, CombatDamage = 1.08, DashScale = 0.93, GuardStrength = 0.08, PreferredRange = 10,
		ComboToolCancel = true, CombatStyle = "Control",
		AttackProfile = {
			Light1={startup=1.08,recovery=.92,travel=.88,range=6.5},Light2={startup=1.12,recovery=.9,travel=.84,range=7,chainTool=true},
			Light3={startup=1.15,recovery=1.08,travel=.78,impulseZ=58},Heavy={startup=1.08,recovery=1.12,travel=.82},
			Launcher={startup=1.12,travel=.78,impulseY=51,impulseZ=20},DashAttack={startup=1.05,travel=.86},
			Air1={startup=1.06,travel=.86},Air2={startup=1.08,travel=.82},Slam={startup=1.12,recovery=1.05},
		},
		Skin = { 197, 164, 143 }, Hair = { 30, 31, 43 }, Outfit = { 69, 49, 66 },
		Techniques = {
			{ Id = "Read", Name = "Read", Cost = 14, Channel = 0.12, Active = 0.9, Recovery = 0.24, Cooldown = 4, Interruptible = false, Range = 10, Hint = "Read one frontal melee • punish window" },
			{ Id = "NeedleFan", Name = "Shuriken Barrage", Cost = 18, Channel = 0.3, Active = 0.08, Recovery = 0.28, Cooldown = 3.8, Interruptible = true, Range = 42, Damage = 3, Hint = "Five blades • close the sideways escape" },
			{ Id = "MirageCast", Name = "Genjutsu: Mirage", Cost = 32, Channel = 0.9, Active = 0.08, Recovery = 0.45, Cooldown = 8, Interruptible = true, Range = 23, Requires = "Target", Hint = "Facing + sight • 3s decoy, full movement" },
			{ Id = "FireBloom", Name = "Great Fireball", Element = "Fire", Cost = 26, Channel = 0.55, Active = 0.42, Recovery = 0.36, Cooldown = 5.5, Interruptible = true, Feintable = true, Range = 62, Speed = 54, Damage = 16, Hint = "Hand signs • a travelling Katon blast" },
		},
	},
}
