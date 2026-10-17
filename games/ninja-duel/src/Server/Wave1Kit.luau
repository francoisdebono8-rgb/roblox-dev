-- Roster 20, batch 1 (Sakura, Choji, Kiba, Kimimaro): the batch's server side. Bespoke techniques
-- (only where a family is not enough) register in install(Techniques); the
-- costumes register in dress(dressers, kit) with World's helpers (wear, cyl,
-- face, hairCap, spike, rgb, A, R). Never a condition on a fighter's name in
-- the shared core: hooks and families (Server/Families).
local Kit={}
function Kit.install(Techniques) end
function Kit.dress(dressers,kit) end
return Kit
