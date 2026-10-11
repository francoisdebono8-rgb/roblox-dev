-- Offline tooling on actual modules; no Roblox client, network, cloud or live state.
local H=require("../tests/Harness");local serde=require("@lune/serde");local process=require("@lune/process")
local S=H.load("Server/ProfileSchema");local cfg=H.load("Server/ChakraConfig")
local Dev=H.load("Server/ChakraDev");local Lab=H.load("Server/ChakraLab")
local args=process.args;local op=args[1];local options=serde.decode("json",args[2] or "{}")
assert(S.serializable(options),"Unsafe CLI arguments")
local result
if op=="compare" then result=Dev.new(cfg,false):run(op,options)
elseif op=="demo" then
 local d=Dev.new(cfg,false);local started=d:run("demo",options);assert(started.ok,started.error)
 result=d:run("step",{seconds=options.seconds or 1})
elseif op=="batch" then
 assert(type(options.commands)=="table" and #options.commands<=64,"Batch budget max 64 commands")
 local d=Dev.new(cfg,false);local rows={}
 for _,command in options.commands do local value=d:run(command.op,command.args);assert(value.ok,value.error);table.insert(rows,{op=command.op,result=value.result}) end
 result={ok=true,operations=rows,report=d.lab:report()}
elseif op=="suite" then
 local reports={}
 for _,name in {"kunai_wind","kunai_seal","redirection","wire_property","projectile_surface","fire_surface"} do
  local lab=Lab.new(cfg);lab:demo(name);reports[name]=lab:run(1)
 end
 result={ok=true,fixtureOnly=true,gameplayIntegration=false,configSnapshot=S.copy(cfg),reports=reports,comparison=Lab.compare(cfg,"Kunai",{"None","Reinforce","Wind"},{"Basic","WeaponExpert"})}
else error("Unknown CLI operation") end
print(serde.encode("json",result));if not result.ok then process.exit(1) end
