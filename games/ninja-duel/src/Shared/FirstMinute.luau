-- The first minute (B1 lot 2, DEC-034; Codex's audit 26f8623 §3: a first
-- input in under 15 s, a first spectacular action in under 45 s, a first duel
-- within 3 minutes, few buttons at first, the full tutorial kept but not
-- imposed). From the roster's PLAY: four prompts on the field with a partner
-- who waits (move, strike, dodge, the fighter's signature), then straight into
-- a real duel against the easy AI. The full tutorial stays as TRAINING.
--
-- Shared: the server runs the steps (Server/Tutorial.firstPlan), the client
-- names them and keeps the HUD to these few controls in the first duel.
local FirstMinute={}

-- Each prodigy's signature is his second jutsu (one key: 2, □ + R1's second
-- glyph on the pad, the second jutsu button on a phone).
FirstMinute.SignatureSlot=2
-- His partner and first opponent: the story's pair of the tournament's
-- quarter-finals (Server/Tournament.Seats).
FirstMinute.Rival={
	Lion="Sand",Sand="Lion",Legion="GentleFist",GentleFist="Legion",
	Leaf="Flashstep",Flashstep="Leaf",Mirage="Copycat",Copycat="Mirage",
}
-- What a touch player presses (the TouchControls buttons).
FirstMinute.Touch={
	move="Drag on the left of the screen",
	string="Tap ATTACK three times",
	dodge="Hold a direction, tap DODGE",
	signature="Tap the second jutsu button",
}
function FirstMinute.signature(def)
	return def and def.Techniques and def.Techniques[FirstMinute.SignatureSlot]
end
function FirstMinute.rival(fighterId)
	return FirstMinute.Rival[fighterId]
end
return FirstMinute
