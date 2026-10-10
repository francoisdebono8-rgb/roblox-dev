-- Tunable V0 values; no client-supplied balance values are accepted.
return {
	Version = "0.11.0-final-today",
	ArenaRadius = 64.4, ArenaHeight = 48, WalkSpeed = 19, JumpPower = 68, Chakra = 100,
	ChakraRegen = 9, GuardDrain = 19, GuardChip = 0.12,
	GuardBreak = 0.65, HitStun = 0.22, InterruptStun = 0.42,
	ComboReset = 1.05, MeleeRange = 7.6, MeleeFacing = 0.18,
	DodgeCost = 10, DodgeCooldown = 0.8, DodgeTime = 0.32, DodgeIFrames = 0.22,
	DodgeSpeed = 61, GuardSpeed = 8, ChannelSpeed = 7,
	ToolCost = 4, PursuitCost = 8, PursuitWindow = 0.85, PursuitRange = 35, PursuitSpeed = 67,
	-- Kawarimi: a limited escape that recharges. Usable while being hit (or
	-- grabbed, juggled, pinned), never as a neutral dodge. The attacker gets a
	-- short window to track the reappearance.
	Substitution = {Cost = 15, Charges = 2, Recharge = 9, Cooldown = 1.1, Window = 0.42, Distance = 8, Track = 0.75},
	-- Damage scaling inside one combo: the first hits land in full, every later
	-- hit is worth less, and a combo that runs too long ends in a knockdown.
	ComboScaling = {Free = 2, Step = 0.12, Floor = 0.35, Reset = 0.45, MaxHits = 11},
	Clash = {Window = 0.07, Push = 4.5},
	Wall = {Detect = 3.4, Clearance = 1.7, RiseSpeed = 23, SideSpeed = 30, MaxTime = 1.65,
		ReboundUp = 61, ReboundAway = 29, ReattachDelay = 0.4,
		-- Wall combat: splat state, pins, tech window and the dive from a wall run.
		SplatSpeed = 17, SplatTime = 0.62, SplatDamage = 3, PinTime = 0.42, PinMax = 2,
		TechFrom = 0.05, TechUntil = 0.34, TechCost = 12, DiveRange = 40},
	RequestRate = 24, RequestBurst = 32, SnapshotInterval = 0.066,
	Movement = { SprintSpeed = 46, GroundAcceleration = 170, GroundDeceleration = 290, TurnAcceleration = 360, AirAcceleration = 76,
		BurstAcceleration = 520, BurstWindow = 0.16,
		JumpVelocity = 72, JumpCooldown = 0.4, AttackWalkSpeed = 12, HardLandVelocity = 56,
		HardLandRecovery = 0.14, SoftLandRecovery = 0.04, HardLandSpeed = 14,
		MeleeTravelTime = 0.28, PursuitRecovery = 0.22 },
	AI = { Tick = 0.18, Reaction = 0.38, Aggression = 0.72, Defense = 0.58, Technique = 0.34 },
}
