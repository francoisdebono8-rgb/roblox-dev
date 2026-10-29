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
	-- (Audit 29/10, tests/Control.sim: Heavy 0.24 / Dodge 0.42 / Grab 0.55
	-- dropped a person's second press silently, even when the first one had
	-- been refused by the fight, so a dodge pressed in a stun and again as it
	-- ended did nothing.) Every gap is now under what a hand can do on one
	-- button (~0.08 s); cooldowns stay the fight's business.
	Rates = table.freeze({Attack=0.05,Heavy=0.07,Guard=0.04,Dodge=0.07,Grab=0.07,Tool=0.07,Technique=0.07}),
})
