return {
	Flashstep = {
		Name = "Flashstep", Title = "THE ANCHOR RUNNER", Color = { 82, 177, 244 },
		Description = "Place a blade. Draw a reaction. Change the angle and punish.",
		Health = 125, Speed = 29, SprintScale = 1.12, JumpScale = 1.1, AirControlScale = 1.15, PreferredRange = 6,
		MeleeDamage = { 6, 7, 8, 13 }, MeleeTravel = { 4.5, 3.4, 4.3, 6.6 }, Startup = 0.13, Recovery = 0.24,
		Skin = { 225, 196, 166 }, Hair = { 225, 228, 212 }, Outfit = { 45, 104, 156 },
		Techniques = {
			{ Id = "MarkedBlade", Name = "Marked Blade", Cost = 12, Channel = 0.25, Active = 0.08, Recovery = 0.25, Cooldown = 2.5, Interruptible = true, Range = 36, Damage = 6, Hint = "Aim at floor / wall • anchor lasts 12s" },
			{ Id = "Flashstep", Name = "Flashstep", Cost = 24, Channel = 0.24, Active = 0.06, Recovery = 0.38, Cooldown = 4, Interruptible = true, Range = 40, Requires = "Anchor", Hint = "Relocate to anchor • vulnerable arrival" },
			{ Id = "BurstStrike", Name = "Burst Strike", Cost = 22, Channel = 0.32, Active = 0.08, Recovery = 0.55, Cooldown = 5, Interruptible = true, Range = 8, Damage = 24, Hint = "Close punish • unsafe on a miss" },
		},
	},
	Mirage = {
		Name = "Mirage", Title = "THE QUIET OBSERVER", Color = { 222, 106, 137 },
		Description = "Provoke a commitment. Read it. Hide your next approach in an echo.",
		Health = 135, Speed = 26, SprintScale = 0.98, JumpScale = 0.95, AirControlScale = 0.9, PreferredRange = 10,
		MeleeDamage = { 7, 8, 9, 15 }, MeleeTravel = { 3.8, 3.2, 3.6, 5.3 }, Startup = 0.17, Recovery = 0.29,
		Skin = { 197, 164, 143 }, Hair = { 30, 31, 43 }, Outfit = { 69, 49, 66 },
		Techniques = {
			{ Id = "Read", Name = "Read", Cost = 14, Channel = 0.12, Active = 0.9, Recovery = 0.24, Cooldown = 4, Interruptible = false, Range = 10, Hint = "Read one frontal melee • punish window" },
			{ Id = "NeedleFan", Name = "Needle Fan", Cost = 18, Channel = 0.42, Active = 0.08, Recovery = 0.32, Cooldown = 3.8, Interruptible = true, Range = 30, Damage = 5, Hint = "Three needles • force a sideways dodge" },
			{ Id = "MirageCast", Name = "Mirage Cast", Cost = 32, Channel = 1.05, Active = 0.08, Recovery = 0.55, Cooldown = 8, Interruptible = true, Range = 23, Requires = "Target", Hint = "Facing + sight • 3s decoy, full movement" },
		},
	},
}
