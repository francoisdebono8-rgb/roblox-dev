-- Client: remove the chronophotograph ghosts and give the live fighters and camera back.
local RS=game:GetService("RunService")
pcall(function() RS:UnbindFromRenderStep("NdFilmCam") end)
if shared.NdGhosts then shared.NdGhosts:Destroy();shared.NdGhosts=nil end
local film=shared.NdFilm
if film then
 for _,model in film.models do
  for _,d in model:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier=0 end end
 end
end
return "cleared"
