-- Tunable V0 values; no client-supplied balance values are accepted.
return {
	Version = "0.13.0-arena-combo",
	ArenaRadius = 143, ArenaHeight = 76, WalkSpeed = 19, JumpPower = 68, Chakra = 100,
	ChakraRegen = 9, GuardDrain = 19, GuardChip = 0.12,
	GuardBreak = 0.65, HitStun = 0.22, InterruptStun = 0.42,
	ComboReset = 1.05, MeleeRange = 7.6, MeleeFacing = 0.18,
	DodgeCost = 10, DodgeCooldown = 0.8, DodgeTime = 0.32, DodgeIFrames = 0.22,
	DodgeSpeed = 61, GuardSpeed = 8, ChannelSpeed = 7,
	ToolCost = 4, PursuitCost = 8, PursuitWindow = 0.85, PursuitRange = 46, PursuitSpeed = 74,
	-- Kawarimi: a limited escape that recharges. Usable while being hit (or
	-- grabbed, juggled, pinned), never as a neutral dodge. The attacker gets a
	-- short window to track the reappearance.
	Substitution = {Cost = 15, Charges = 2, Recharge = 9, Cooldown = 1.1, Window = 0.42, Distance = 8, Track = 0.75},
	-- Damage scaling inside one combo: the first hits land in full, every later
	-- hit is worth less, and a combo that runs too long ends in a knockdown.
	ComboScaling = {Free = 2, Step = 0.12, Floor = 0.35, Reset = 0.45, MaxHits = 11},
	Clash = {Window = 0.07, Push = 4.5},
	-- Chakra dash (E outside a chase window): a committed burst at the opponent.
	Rush = {Cost = 10, Speed = 90, Range = 48, MinRange = 7, MaxTime = 0.55, Cooldown = 0.9, Arrive = 0.3},
	-- Awakening: once per match, at low health, a fighter-specific power-up.
	Awaken = {Threshold = 0.35, Duration = 12},
	-- Rhythm: a chained strike pressed on the beat (not mashed early) is a Flow strike.
	Flow = {Early = 0.07, Late = 0.13, Damage = 1.15, Stop = 0.035},
	ThrowBreak = 0.35,
	RoundsToWin = 2,
	-- Where each fighter starts (studs from the centre): far enough apart that
	-- the round opens on an approach, not on a punch.
	StartDistance = 24,
	-- Server-side Animator playback (donor clips, default locomotion). Off: the
	-- client motion engine animates every body.
	DonorAnimations = false,
	Wall = {Detect = 3.4, Clearance = 1.7, RiseSpeed = 23, SideSpeed = 30, MaxTime = 1.65,
		ReboundUp = 61, ReboundAway = 29, ReattachDelay = 0.4,
		-- Wall combat: splat state, pins, tech window and the dive from a wall run.
		SplatSpeed = 17, SplatTime = 0.62, SplatDamage = 3, PinTime = 0.42, PinMax = 2,
		TechFrom = 0.05, TechUntil = 0.34, TechCost = 12, DiveRange = 50},
	RequestRate = 24, RequestBurst = 32, SnapshotInterval = 0.066,
	Movement = { SprintSpeed = 45, GroundAcceleration = 170, GroundDeceleration = 290, TurnAcceleration = 360, AirAcceleration = 76,
		BurstAcceleration = 520, BurstWindow = 0.16,
		-- Ninja jump at Gravity 140, gravity integrated once: ~12 studs apex and
		-- ~0.83 s of flight at scale 1 (JumpScale stretches it per fighter).
		-- HardLandVelocity sits above every fighter's own jump landing (~67 max),
		-- so only a real drop (~25 studs) lands heavy.
		JumpVelocity = 58, JumpCooldown = 0.4, AttackWalkSpeed = 12, HardLandVelocity = 84, FallbackGravity = 140,
		HardLandRecovery = 0.14, SoftLandRecovery = 0.04, HardLandSpeed = 14,
		MeleeTravelTime = 0.28, PursuitRecovery = 0.22 },
	-- Neutral rhythm (convergence §8): jutsu are paced (Gap + Jitter seconds
	-- between two, punishes excepted), a fast approach into melee range is read
	-- before the strike (guard / sidestep / counter-poke, no reaction latency:
	-- a guess), probing at range uses tools and step-in feints, and a fighter
	-- that just got hit backs off to neutral instead of mashing back.
	AI = { Tick = 0.18, Reaction = 0.38, Aggression = 0.72, Defense = 0.58, Technique = 0.34,
		TechniqueGap = 2.6, TechniqueJitter = 2.6, ReadGuard = 0.3, ReadDodge = 0.16, ReadPoke = 0.22, GuardRead = 0.07,
		Feint = 0.1, ProbeTool = 2.4, Disengage = 0.45, WallRun = 0.35 },
}
