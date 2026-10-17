-- Roster 20, batch 2 (Shikamaru, Shino, Orochimaru): the batch's own drawing, installed by
-- Effects like SandFX: projectile builders (kit.BUILD[kind]), FX.poses[kind],
-- and layers in FX.layers ({impact=..., fighter=..., step=..., frame=...}).
-- Most objects need nothing here: Shared/Looks + Client/FamilyFX draw them.
local M={}
function M.install(FX,kit) end
return M
