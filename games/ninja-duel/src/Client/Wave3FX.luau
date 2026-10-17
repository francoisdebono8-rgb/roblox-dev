-- Roster 20, batch 3 (Haku, Zabuza, Kisame): the batch's own drawing, installed by
-- Effects like SandFX: projectile builders (kit.BUILD[kind]), FX.poses[kind],
-- and layers in FX.layers ({impact=..., fighter=..., step=..., frame=...}).
-- Most objects need nothing here: Shared/Looks + Client/FamilyFX draw them.
local M={}
function M.install(FX,kit) end
return M
