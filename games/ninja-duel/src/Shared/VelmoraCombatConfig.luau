-- Adapted from Velmora src/shared/config/CombatConfig.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
return table.freeze({
	ParryWindow = 0.20,
	ParryStun = 0.50,
	ParryCost = 16,
	ParryCooldown = 0.60,
	BlockHitCost = 9,
	BlockDamageMultiplier = 0.24,
	DodgeIFrames = 0.19,
	BloodstepWindow = 0.13,
	History = 0.20,
	TimestampWindow = 0.10,
	-- Minimum gap between two packets of one action (a flood guard, not a
	-- gameplay rule: the server state machine and the press buffer decide what
	-- a press does). Attack stays under a deliberate double tap (~0.1 s), or the
	-- second press of a buffered string was dropped before reaching the buffer.
	Rates = table.freeze({Attack=0.08,Heavy=0.24,Guard=0.05,Dodge=0.42,Grab=0.55,Tool=0.25,Technique=0.10}),
})
