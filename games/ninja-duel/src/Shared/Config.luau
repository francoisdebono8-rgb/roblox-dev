-- Tunable V0 values; no client-supplied balance values are accepted.
return {
	Version = "0.2.0",
	ArenaRadius = 46, WalkSpeed = 19, JumpPower = 68, Chakra = 100,
	ChakraRegen = 9, GuardDrain = 19, GuardChip = 0.12,
	GuardBreak = 0.65, HitStun = 0.22, InterruptStun = 0.42,
	ComboReset = 1.05, MeleeRange = 7.6, MeleeFacing = 0.18,
	DodgeCost = 16, DodgeCooldown = 1.5, DodgeTime = 0.32, DodgeIFrames = 0.22,
	DodgeSpeed = 61, GuardSpeed = 8, ChannelSpeed = 7,
	PursuitCost = 8, PursuitWindow = 0.85, PursuitRange = 23, PursuitSpeed = 67,
	RequestRate = 24, RequestBurst = 32, SnapshotInterval = 0.1,
	Movement = { SprintSpeed = 38, GroundAcceleration = 175, GroundDeceleration = 205, AirAcceleration = 88,
		JumpVelocity = 70, JumpCooldown = 0.4, AttackWalkSpeed = 16, HardLandVelocity = 56,
		HardLandRecovery = 0.12, SoftLandRecovery = 0, HardLandSpeed = 19,
		MeleeTravelTime = 0.28, PursuitRecovery = 0.22 },
	AI = { Tick = 0.18, Reaction = 0.38, Aggression = 0.72, Defense = 0.58, Technique = 0.65 },
}
