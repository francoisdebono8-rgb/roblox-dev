-- Native tooling smoke/performance run. Included ONLY by --dev-qa.
local QA={}
function QA.run(matches)
 local rs=game:GetService("RunService");if not rs:IsStudio() or workspace:GetAttribute("NinjaDuelDevQA")~=true then return end
 local Players=game:GetService("Players");local p=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
 task.wait(3)
 local hook=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev")
 local failures={};local passed=0
 local function check(name,fn)
  local ok,err=pcall(fn)
  if ok then passed+=1;print("[NinjaDuelDevQA] PASS "..name) else table.insert(failures,name..": "..tostring(err));warn("[NinjaDuelDevQA] FAIL "..failures[#failures]) end
 end
 local function command(op,arg)
  local result=hook:Invoke("tool",op,arg);assert(result.ok,result.error);return result
 end
 command("profile",{enabled=true})
 for _,name in {"neutral","launcher","air","wall","substitution","grab","whiff","projectile","ko"} do
  check(name,function()
   command("scenario",{name=name});local s=matches.sessions[p]
   assert(s and s.combat and s.botFrozen)
   if name=="launcher" then assert(s.bot.reaction=="Launched")
   elseif name=="wall" then assert(s.bot.reaction=="WallSplat")
   elseif name=="air" then assert(s.human.airborne and s.bot.airborne)
   elseif name=="substitution" then assert(s.human.subCharges==1)
   elseif name=="ko" then assert(s.finishing) end
   task.wait(.8)
  end)
 end
 check("fresh character / refill / awakening / repeat",function()
  command("character",{first="GentleFist",second="Mirage"});command("refill");command("awaken")
  assert(matches.sessions[p].human.awakened);command("repeat");assert(matches.sessions[p].human.fighterId=="GentleFist")
 end)
 command("reset",{first="Flashstep",second="Mirage"});command("dummy",{enabled=false});hook:Invoke("autopilot",true)
 task.wait(12);hook:Invoke("autopilot",false)
 local report=command("report")
 check("both client and server measurements delivered",function()
  assert(report.client and report.client.stats["client.frame.ms"])
  assert(report.client.build==report.server.build)
  assert(report.server.stats["server.combat.ms"])
 end)
 command("profile",{enabled=false})
 check("all profiling wrappers removed",function() assert(rawget(matches,"update")==nil and rawget(matches.sessions[p].combat,"update")==nil) end)
 command("reset")
 print("[NinjaDuelDevQA] RESULT "..game:GetService("HttpService"):JSONEncode({pass=passed,failures=failures,build=report.server.build}))
end
return QA
