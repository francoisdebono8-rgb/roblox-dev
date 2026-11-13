-- Tunable V0 values; no client-supplied balance values are accepted.
return {
	Version = "0.13.0-arena-combo",
	ArenaRadius = 143, ArenaHeight = 76, WalkSpeed = 19, JumpPower = 68, Chakra = 100,
	ChakraRegen = 9, GuardDrain = 19, GuardChip = 0.12,
	GuardBreak = 0.65, HitStun = 0.22, InterruptStun = 0.42,
	-- A thrown object's flinch (Combat:damage): Stun on the first blade, then
	-- nothing for Window seconds (a volley is one flinch); a thrown object
	-- hitting for Heavy damage or more is a real blow and stuns as one.
	ProjectileStun = {Stun = 0.18, Window = 0.9, Heavy = 8},
	-- Walking into a standing body pushes it (Motor.step): the walker keeps
	-- Share of the inward speed.
	Push = {Share = 0.45},
	ComboReset = 1.05, MeleeRange = 7.6, MeleeFacing = 0.18,
	DodgeCost = 10, DodgeCooldown = 0.8, DodgeTime = 0.32, DodgeIFrames = 0.22,
	DodgeSpeed = 61, GuardSpeed = 8, ChannelSpeed = 7,
	ToolCost = 4, PursuitCost = 8, PursuitWindow = 0.85, PursuitRange = 46, PursuitSpeed = 74,
	-- (PursuitCost is the one re-engage price: the chase and the chakra dash.)
	-- Kawarimi: a limited escape that recharges. Usable while being hit (or
	-- grabbed, juggled, pinned), never as a neutral dodge. The attacker gets a
	-- short window to track the reappearance.
	-- Grace (05/11): a dodge this soon after the contact is the substitution even
	-- past the share of the stun where the body could step out (Combat:request).
	Substitution = {Cost = 15, Charges = 2, Recharge = 9, Cooldown = 1.1, Window = 0.42, Distance = 8, Track = 0.75, Grace = 0.35},
	-- Damage scaling inside one combo: the first hits land in full, every later
	-- hit is worth less, and a combo that runs too long ends in a knockdown.
	ComboScaling = {Free = 2, Step = 0.12, Floor = 0.35, Reset = 0.45, MaxHits = 11},
	-- (User 03/11: "les combats trop courts") Every blow's damage is scaled by
	-- this as it lands (Combat:damage, Combat:chip): the HP of the story stay,
	-- the rounds last longer (AI against AI: 42 s average at 1.0). The
	-- impact's look still reads the blow's own weight (unscaled).
	DamageScale = 0.6,
	Clash = {Window = 0.07, Push = 4.5, JutsuWindow = 0.35},
	-- Re-engage (CORE_COMBAT_CONVERGENCE_2 §3): one contextual action (E; on a pad
	-- × inside a chase window, sprint + ○ toward outside one). Inside a window it
	-- is the chase, outside it is this chakra dash at a locked opponent; both cost
	-- PursuitCost. The arrival converts at once into a strike, a heavy or a grab;
	-- guard, dodge or jump only after CancelAfter, so a predictable dash is
	-- punished. Unlocked, the dash is a straight Reposition-stud burst. Each
	-- prodigy re-enters his own way (MoveGraphs[...].reengage).
	-- Carry: the speed a dash keeps past its arrival (it stops where it arrives).
	Rush = {Cost = 8, Speed = 90, Range = 48, MinRange = 7, MaxTime = 0.55, Cooldown = 0.9, Arrive = 0.3, Recovery = 0.22, CancelAfter = 0.1, Reposition = 18, Carry = 8},
	-- Combo model (§1): strings count confirmed hits only. Grace: a press from
	-- neutral this long after a chain window still continues the string.
	-- Buffer: a press made during a committed swing waits this long past its
	-- active window. Intent: a push stronger than IntentStrong is remembered for
	-- IntentWindow seconds; toward is within acos(Toward) of the line to the
	-- opponent, away within acos(Away) of the line away from him, side between.
	Combo = {Grace = 0.18, Buffer = 0.3, IntentStrong = 0.45, IntentWindow = 0.22, Toward = 0.64, Away = 0.57},
	-- Late presses (audit 29/10: 7% of a player's presses were refused in the
	-- last 0.25 s of a recovery, a dodge or a stun, and nothing came out). A
	-- press refused because the body is busy is kept this long and fires on
	-- the first free frame: Late after the fighter's own commitment, LateHit
	-- at the end of a reaction (shorter: a reversal, not a free mash-out).
	Late = {Own = 0.2, Hit = 0.12},
	-- Awakening: once per match, at low health, a fighter-specific power-up.
	Awaken = {Threshold = 0.35, Duration = 12},
	-- Rhythm: a chained strike pressed on the beat (not mashed early) is a Flow strike.
	Flow = {Early = 0.07, Late = 0.13, Damage = 1.15, Stop = 0.035},
	ThrowBreak = 0.35,
	-- Ninja Embodiment (EMB-003): an ordinary blow takes control for a moment,
	-- not for the attacker's whole string. Past a share of its stun (never before
	-- Min seconds) a standing body may recover into its guard (guard stamina)
	-- or step out of it (chakra); a body thrown into the air may right itself
	-- past its apex (chakra, once per air time; an earned launcher holds longer);
	-- a knocked-down body landing may roll out (Tech). The substitution stays the
	-- escape from anywhere, earlier, for its own price. An air string drops the
	-- body after AirHits blows in one air time.
	Agency = {Stand = 0.45, Min = 0.12, Air = 0.35, AirHits = 4, Launched = 0.72, GuardCost = 10, StepCost = 6, AirCost = 8,
		Tech = 0.3, TechDistance = 4.5, AirLift = 16, AirPush = 10},
	-- Ninja Embodiment (EMB-004, Server/WorldReaction): the reactive arena.
	-- Budgets (server parts, replicated): MaxScars marks (oldest out, a mark
	-- close to one of its kind deepens it), MaxRubble pieces, MaxEmbeds blade
	-- facts. Energies: a body (studs/s x BodyEnergy), a projectile (damage x
	-- ProjectileEnergy), a strike that met the world (damage x StrikeEnergy),
	-- a zone (radius x ZoneEnergy); below MinEnergy nothing is marked.
	World = {MaxScars = 48, MaxRubble = 24, RubblePerBreak = 4, MaxEmbeds = 16, MinEnergy = 8,
		CrackedShare = 0.5, StumpHeight = 2.2, MoundShare = 0.38,
		BodySpeed = 14, LandingSpeed = 26, BodyEnergy = 1.4, ProjectileEnergy = 5, StrikeEnergy = 4, ZoneEnergy = 5,
		BodyRepeat = 0.35, SmashCarry = 0.6, HeavyKinds = {heavy = true, spike = true, launch = true},
		-- (User 28/10: "the arena must not become a minefield where nobody
		-- understands anything".) Weight: the floor only keeps what weighed
		-- something - a slam, a spike, a Great Fireball - not every landing;
		-- GroundEnergy for a contact mark, GroundElement for a scorch. The
		-- marks fade (Fade seconds, Major once the energy passed MajorEnergy
		-- or a mark was deepened three times; Out: the fade itself) and the
		-- floor holds at most MaxFloorScars at once (oldest first out).
		-- (06/11, user: « les traces au sol et les dégâts sur l'arène sont très
		-- légers ») Was 75 / 34 / 10 floor marks / 22 s and 60 s: the floor kept
		-- almost nothing. Now a heavy blow marks it, the marks stay for the
		-- round, and the blows that throw a body leave the ground torn where
		-- it stood (Blow) and its skid ploughed (Skid, its own budget).
		GroundEnergy = 40, GroundElement = 18, MajorEnergy = 90, MaxFloorScars = 18,
		Fade = {Minor = 40, Major = 90, Out = 1.6},
		Blow = {Speed = 30, Energy = 1.6}, Skid = {Speed = 9, Every = 0.13, Max = 14, Fade = 16}},
	-- Ninja Embodiment (Server/Perception): the space a body reads around a
	-- fight. Behind: how far past the target (or behind itself) a surface
	-- counts; Scan: how far around the target the nearest surface is looked
	-- for; Cache: seconds a read is reused; Refresh: seconds the arena's
	-- surface list is reused.
	-- (Continuity blocker) How fast a strike still turns to the opponent,
	-- degrees/s: in its startup, and once it is out (was 900 / 420); the
	-- lock's own turn in neutral, and while moving away or sprinting (was
	-- 760 / 540).
	Facing = {Startup = 480, Active = 160, Neutral = 520, Committed = 420},
	-- Free lens: a blow starting this close turns to the opponent at Rate (deg/s).
	-- (900: the startup's bounded turn, CombatFeel; standing near him the free
	-- body already faces him, Combat.updateActor)
	SoftLock = {Reach = 13, Rate = 900, Face = 12},
	-- (07/11, mission game feel: Studio audit, free lens, Minato and Sasuke
	-- landing blows while facing 45-86 deg away from the body they hit; between
	-- the blows of a string the body swung back to the lens) Engaged: within
	-- SoftLock.Face of the opponent, during an exchange (Hold s after one's
	-- own strike or reaction, or while the opponent winds up a blow), the free
	-- body keeps its chest on him instead of the lens. Turn: a soft-locked
	-- strike's turn finishes inside its startup (at most Turn deg/s).
	Engaged = {Hold = 0.8, Turn = 1800},
	-- (07/11, same audit) A blow lands on what is in front of it: the brawl
	-- contact cone is +-acos(Contact.Facing) around the striker's facing (was
	-- +-87 deg: a fist going forward knocked down a body beside it).
	Contact = {Facing = 0.5},
	-- (12/11, feel audit M2: bodies inside each other, contact down to 2 studs,
	-- a fighter standing in one lying on the floor) Two standing bodies are
	-- eased toward Gap studs apart (root to root) and never left closer than
	-- Floor (every strike's step-in stops at 2.4 studs or more). A body lying on
	-- the floor is LyingHalf studs long each way along its facing; a standing
	-- body is kept LyingGap studs from that line. Passing through (a dodge, a
	-- rush line), a hold and an ultimate are left alone.
	Bodies = {Gap = 3, Floor = 2.5, LyingHalf = 2.8, LyingGap = 2.0},
	-- (12/11) A travel (Combat:travelStart: a teleport jutsu, a signature
	-- dash) stays in the duel state Show s after its arrival: the arrival pose.
	Travel = {Show = 1.0},
	-- (DEC-032 §3) Hand seals: the weave stays open Open s for the first seal,
	-- then Gap s between seals.
	Seals = {Open = 1.4, Gap = 0.9},
	-- (DEC-032 §2) Free combos: at most Links free links in a combo (links
	-- less than Reset s apart).
	FreeCombo = {Links = 3, Reset = 1.6},
	-- (Continuity blocker) A chase heads for the point the body was going to
	-- and lets it drift at Steer studs/s; it turns at Turn degrees/s.
	Chase = {Steer = 60, Turn = 720},
	Perception = {Behind = 14, Scan = 48, Cache = 0.12, Refresh = 10},
	RoundsToWin = 2,
	-- (Final blow) The round's last hit throws the body: Speed / Lift (studs/s)
	-- for a heavy finish (a light one at Light of it), the first SlowFor
	-- seconds at SlowScale speed, back to full over Ease; Settle caps the flight.
	FinalBlow = {Speed = 38, Lift = 24, Light = 0.8, SlowFor = 0.45, SlowScale = 0.3, Ease = 0.35, Settle = 3},
	-- Where each fighter starts (studs from the centre): far enough apart that
	-- the round opens on an approach, not on a punch.
	StartDistance = 24,
	-- (QA 12/11) The intro's « BEGIN » shows over the last IntroBegin seconds
	-- (Client/UI) and the camera eases from the close-ups into the duel frame
	-- over the same seconds (Client/Camera): the player is in the frame at BEGIN.
	IntroBegin = 0.75,
	-- Server-side Animator playback (donor clips, default locomotion). Off: the
	-- client motion engine animates every body.
	DonorAnimations = false,
	Wall = {Detect = 3.4, Clearance = 1.7, RiseSpeed = 23, SideSpeed = 30, MaxTime = 1.65,
		ReboundUp = 61, ReboundAway = 29, ReattachDelay = 0.4,
		-- Wall combat: splat state, pins, tech window and the dive from a wall run.
		SplatSpeed = 17, SplatTime = 0.62, SplatDamage = 3, PinTime = 0.42, PinMax = 2,
		TechFrom = 0.05, TechUntil = 0.34, TechCost = 12, DiveRange = 50},
	RequestRate = 40, RequestBurst = 48, SnapshotInterval = 0.033,
	Movement = { SprintSpeed = 45, GroundAcceleration = 170, GroundDeceleration = 290, TurnAcceleration = 360, AirAcceleration = 76,
		BurstAcceleration = 520, BurstWindow = 0.16,
		-- Ninja jump at Gravity 140, gravity integrated once: ~12 studs apex and
		-- ~0.83 s of flight at scale 1 (JumpScale stretches it per fighter).
		-- HardLandVelocity sits above every fighter's own jump landing (~67 max),
		-- so only a real drop (~25 studs) lands heavy.
		JumpVelocity = 58, JumpCooldown = 0.4, AttackWalkSpeed = 14, HardLandVelocity = 84, FallbackGravity = 140,
		HardLandRecovery = 0.14, SoftLandRecovery = 0.04, HardLandSpeed = 14,
		MeleeTravelTime = 0.28, PursuitRecovery = 0.22 },
	-- Neutral rhythm (convergence §8): jutsu are paced (Gap + Jitter seconds
	-- between two, punishes excepted), a fast approach into melee range is read
	-- before the strike (guard / sidestep / counter-poke, no reaction latency:
	-- a guess), probing at range uses tools and step-in feints, and a fighter
	-- that just got hit backs off to neutral instead of mashing back.
	-- (DEC-037, 12/11) The masters' path (Server/Progression, Shared/Masters):
	-- off until the roster screen shows it; Live opens the live DataStore;
	-- Products maps a kit to its Developer Product id (empty: nothing sold);
	-- MasteryPass is the 2x mastery game pass id (0: none).
	-- (Beta loop, 13/11: « qu'on soit proche de la vraie boucle du jeu ») On in
	-- the beta: a new player picks one kit among three, the others are taught by
	-- their masters. Live = the published game's own store (progress kept
	-- between visits); Studio always uses the DEV store.
	Progression = { Enabled = true, Live = true, Products = {}, MasteryPass = 0 },
	-- (DEC-036) The player's fighter is his own Roblox avatar wearing the kit
	-- (Server/AvatarBody); the AI's and the watched fighters stay the prodigies.
	AvatarBody = { Enabled = true },
	-- (DEC-038, 13/11) Between duels the player walks Konoha as his own avatar:
	-- the masters at home, the exam hall's proctor opens the board of duels.
	-- Off: the roster screen, as before.
	Hub = { Enabled = true },
	AI = { Tick = 0.18, Reaction = 0.38, Aggression = 0.72, Defense = 0.58, Technique = 0.34,
		TechniqueGap = 2.6, TechniqueJitter = 2.6, ReadGuard = 0.3, ReadDodge = 0.16, ReadPoke = 0.22, GuardRead = 0.07,
		Feint = 0.1, ProbeTool = 2.4, Disengage = 0.45, WallRun = 0.35,
		-- Ninja Embodiment: the bot answers an ordinary blow (Recover: once per
		-- reaction) and comes in with a plan that makes the situation the
		-- strike reads (EMB-002): out of a run, over the top, from the side of a
		-- committed body; or straight in.
		-- It also reads the space (Server/Perception): with a surface within
		-- Herd studs of the opponent it circles to put him between itself and
		-- it (HerdTime per try, HerdGap between tries), and it steps out of a
		-- corner when its own back is within Corner studs of one.
		Recover = 0.5, Plan = 0.65, Herd = 40, HerdTime = 1.6, HerdGap = 2.5, Corner = 4.5,
		-- Spacing at range it drifts to scenery within Terrain studs.
		Terrain = 50, TerrainPull = 0.9,
		-- (Rupture) An ordinary string is short: after one confirmed hit
		-- (BreakOff1) or two (BreakOff2) it breaks off and moves for
		-- RepositionTime (+ jitter) instead of trading the next string.
		BreakOff1 = 0.3, BreakOff2 = 0.55, RepositionTime = 0.9, RepositionJitter = 0.6 },
}
