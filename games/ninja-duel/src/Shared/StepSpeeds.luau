-- Step speeds: how fast the feet of a clip carry the body (studs/s) without
-- sliding. Feel audit of 07/11, M1 "glissades" (docs/reports/feel-audit-
-- 2026-11-07/AUDIT.md): the body moved under a fixed pose, 28 to 38 times a
-- minute. The end of a blow walked at 14 studs/s on the stick
-- (Config.Movement.AttackWalkSpeed); a guard pushed back skidded at up to 33-40
-- studs/s (Brawler: 5-14; ChakraFlow: Earth 20, Strength and Wind 30,
-- Rasengan 40).
--
-- FILLED BY THE ANIMATEUR (zones: docs/tools/RUNBOOK_4_DISCUSSIONS.md § 3
-- quater), read by DEV (Server/Motor, Server/Combat). Give the speed the clip
-- shows, per fighter ([fighterId], e.g. Lion = Sasuke) or for every fighter
-- (Default). The engine then never moves the body faster than that:
--   Recovery  - the end of a blow (recovery, a stick held): the walk the
--               end-of-blow legs show. Caps the stick's walk and what is left
--               of a run carried into the blow.
--   GuardSkid - a guard pushed back by a blocked blow: the fastest the skid
--               clip slides its feet. The push keeps its distance, it just
--               takes longer.
-- nil (not given yet): the engine keeps its old speed.
local StepSpeeds={
	Default={Recovery=nil,GuardSkid=nil},
	Recovery={},
	GuardSkid={},
}
local function pick(kind,fighterId)
	local own=StepSpeeds[kind][fighterId]
	if own~=nil then return own end
	return StepSpeeds.Default[kind]
end
-- The walk at the end of a blow (studs/s): the step speed given, else `old`.
function StepSpeeds.recovery(fighterId,old)
	return pick("Recovery",fighterId) or old
end
-- The fastest a pushed-back guard skids (studs/s), nil for no cap.
function StepSpeeds.guardSkid(fighterId)
	return pick("GuardSkid",fighterId)
end
return StepSpeeds
