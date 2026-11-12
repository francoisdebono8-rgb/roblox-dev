-- Back and side reaction clips. Feel audit of 07/11, M3 "victimes retournées
-- d'un coup" (docs/reports/feel-audit-2026-11-07/AUDIT.md).
--
-- The CLIENT picks them by itself as soon as they exist (Client/
-- VelmoraMotionEngine, authoredReaction: from the hit's angle, the back clip
-- for a blow from behind, the side clip for one from the side, the frontal one
-- otherwise or while the variant is missing). Nothing to switch on. Throws
-- are shared reactions (AuthoredMotion borrows Sasuke's when a fighter has
-- none of his own), so since PR #58 every fighter gets their back and side
-- variants; a hold is each fighter's own.
--
-- The SERVER only has to know for a hold: until the held body has its own back
-- and side clips, it is hauled round to face the grabber (Brawler, GRAB_TURN,
-- ~0.2 s). Grabbed lists the fighters whose hold has them (Grabbed,
-- Grabbed.Back, Grabbed.Side; the ANIMATEUR adds a fighter when he delivers
-- them, tests/ReactionSides.spec checks each one); a listed held body keeps
-- its facing.
--
-- Clips per fighter F (".L" = the other side, optional; mirrored otherwise):
--   HitStun   F.Hit.Back, F.Hit.Side             in since ANIM-005
--   Launched  F.Launched.Back, F.Launched.Side   (also played for Juggled)
--   Knockback F.Knockback.Back, F.Knockback.Side
--   Grabbed   F.Grabbed (front), F.Grabbed.Back, F.Grabbed.Side
local ReactionSides={
	-- (12/11, ANIMATEUR PR #58) the 8 fighters of the beta.
	Grabbed={Copycat=true,Flashstep=true,GentleFist=true,Leaf=true,Legion=true,Lion=true,Mirage=true,Sand=true},
}
ReactionSides.Clips={
	HitStun={"Hit.Back","Hit.Side"},
	Launched={"Launched.Back","Launched.Side"},
	Knockback={"Knockback.Back","Knockback.Side"},
	Grabbed={"Grabbed.Back","Grabbed.Side"},
}
-- A held body of this fighter keeps its facing (its hold has back/side clips).
function ReactionSides.keepsFacing(kind,fighterId)
	local set=ReactionSides[kind]
	return type(set)=="table" and set[fighterId]==true
end
return ReactionSides
