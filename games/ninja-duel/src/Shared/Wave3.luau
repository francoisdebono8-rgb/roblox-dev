-- Roster 20, batch 3 (Haku, Zabuza, Kisame): this batch's shared data, merged into
-- Fighters, MoveGraphs and Attacks so parallel batches never edit the same
-- tables (docs/characters/ROSTER_20.md).
--   fighters[id]  a Fighters entry (techniques naming a Family first)
--   graphs[id]    a MoveGraphs entry (the shared directional grammar)
--   attacks(move, attacks)  optional: new strikes, built with Attacks' own
--                 move(startup, active, recovery, damage, travel, reaction,
--                 impulse, stun) and given their shape fields here
return {
	fighters={},
	graphs={},
	attacks=nil,
}
