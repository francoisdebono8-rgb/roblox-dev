-- Explicit smoke test of the chakra lab, run by dev:Invoke("interactions","qa")
-- in the Debug/QA place (Codex 7091585, ported verbatim; DEBUG_SOURCES). Never
-- called by bootstrap. Needs the chakra runtime modules (DevTools.ChakraRuntime).
local QA={}
function QA.run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local cfg=require(script.Parent.ChakraConfig)
 local Dev=require(script.Parent.ChakraDev)
 local Shared=game:GetService("ReplicatedStorage").NinjaDuel
 local fighters=require(Shared.Fighters);local before={};for id,f in fighters do before[id]={speed=f.Speed,health=f.Health} end
 local camera=workspace.CurrentCamera;local cf=camera and camera.CFrame
 local tool=Dev.new(cfg,true);local passed=0
 local ok,err=pcall(function()
  for _,name in {"kunai_wind","kunai_seal","redirection","wire_property","projectile_surface","fire_surface"} do
   local demo=tool:run("demo",{name=name});assert(demo.ok,demo.error)
   local shown=tool:run("show",{enabled=true});assert(shown.ok,shown.error)
   local result=tool:run("step",{seconds=1});assert(result.ok,result.error)
   local report=result.result;local a=report.objects.a;assert(a and #report.events>0)
   if name=="kunai_wind" then assert(a.stats.speed>42)
   elseif name=="kunai_seal" then assert(a.embedded and a.anchor)
   elseif name=="redirection" then assert(report.objects.b.velocity.x>0)
   elseif name=="wire_property" then assert(a.tags.conductiveWire)
   elseif name=="projectile_surface" then assert(a.embedded)
   elseif name=="fire_surface" then assert(report.surfaces.wood.tags.ignited) end
   local model=tool.view.objects.a.model;assert((model:GetPivot().Position-(tool.view.origin+Vector3.new(a.position.x,a.position.y,a.position.z))).Magnitude<.01)
   for _,part in tool.view.folder:GetDescendants() do if part:IsA("BasePart") then assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch) end end
   passed+=1
  end
  tool:run("play");assert(tool.connection and tool.running);tool:stop();assert(not tool.connection)
  local folder=tool.view.folder;tool:destroy();assert(folder.Parent==nil)
  for id,f in fighters do assert(f.Speed==before[id].speed and f.Health==before[id].health) end
  assert(workspace.CurrentCamera==camera and (not camera or camera.CFrame==cf) and cfg.Enabled==false)
  passed+=1
 end)
 tool:destroy()
 local result={ok=ok,passed=passed,expected=7,build=Shared.BuildFingerprint.Value,gameplayIntegration=false,error=not ok and tostring(err) or nil}
 print("[NinjaDuelChakraQA] RESULT "..game:GetService("HttpService"):JSONEncode(result))
 assert(ok,err);return result
end
return QA
