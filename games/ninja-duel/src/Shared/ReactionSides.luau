-- Back and side reaction clips. Feel audit of 07/11, M3 "victimes retournées
-- d'un coup" (docs/reports/feel-audit-2026-11-07/AUDIT.md).
--
-- The CLIENT picks them by itself as soon as they exist (Client/
-- VelmoraMotionEngine, authoredReaction: from the hit's angle, the back clip
-- for a blow from behind, the side clip for one from the side, the frontal one
-- otherwise or while the variant is missing). Nothing to switch on.
--
-- The SERVER only has to know for a hold: until the held body has its own back
-- and side clips, it is hauled round to face the grabber (Brawler, GRAB_TURN,
-- ~0.2 s). The ANIMATEUR sets Grabbed=true once Grabbed.Back and Grabbed.Side
-- are in for ALL fighters with authored reactions (tests/ReactionSides.spec
-- checks it); the held body then keeps its facing.
--
-- Clips per fighter F (".L" = the other side, optional; mirrored otherwise):
--   HitStun   F.Hit.Back, F.Hit.Side             in since ANIM-005
--   Launched  F.Launched.Back, F.Launched.Side   (also played for Juggled)
--   Knockback F.Knockback.Back, F.Knockback.Side
--   Grabbed   F.Grabbed (front), F.Grabbed.Back, F.Grabbed.Side
local ReactionSides={
	Grabbed=false,
}
ReactionSides.Clips={
	HitStun={"Hit.Back","Hit.Side"},
	Launched={"Launched.Back","Launched.Side"},
	Knockback={"Knockback.Back","Knockback.Side"},
	Grabbed={"Grabbed.Back","Grabbed.Side"},
}
return ReactionSides
