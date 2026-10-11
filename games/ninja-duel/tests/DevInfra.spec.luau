local H=require("./Harness")
local Metrics=H.load("Shared/DevMetrics")
local Commands=H.load("Shared/DevCommands")
local Profiler=H.load("Server/DevProfiler")
local Scenarios=H.load("Server/DevScenarios")
local Tools=H.load("Server/DevTools")
local passed=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name) end
local function matches()
 local m={sessions={}}
 function m:destroy(s) if s.combat then s.combat:clear() end end
 function m:start(p,first,second)
  if self.sessions[p] then self:destroy(self.sessions[p]) end
  local c,a,b,s=H.duel(first,second);s.combat=c;s.human=a;s.bot=b;s.playerId=first;s.botId=second;s.epoch=(self.sessions[p] and self.sessions[p].epoch or 0)+1
  self.sessions[p]=s;return true
 end
 function m:snapshot() end
 function m:update(dt) for _,s in self.sessions do s.combat:update(dt,s.combat.now+dt) end end
 function m:request(p,data) return self.sessions[p].combat:request(self.sessions[p].human,data.action) end
 function m:send() end
 return m
end
test("instrumentation preserves nil returns, errors and inherited methods",function()
 local clock=0;local m=Metrics.new(function() clock+=.001;return clock end)
 local original=function(_,v) if v==false then error("original error") end;return v,nil,3 end
 local obj=setmetatable({}, {__index={f=original}})
 m:start();m:wrap(obj,"f","test")
 local a,b,c=obj:f(7);assert(a==7 and b==nil and c==3)
 local ok,err=pcall(function() obj:f(false) end);assert(not ok and tostring(err):find("original error"))
 m:stop();assert(rawget(obj,"f")==nil and obj.f==original)
 assert(m:report().stats["test.ms"].count==2)
end)
test("measurements bounded and inert while disabled",function()
 local m=Metrics.new();m:sample("none",1);m:count("none");m:event("none",{});assert(next(m.stats)==nil and #m.events==0)
 m:start();for i=1,1000 do m:sample("value",i);m:event("e",{});m:count("label"..i) end
 local report=m:report();assert(report.stats.value.count==1000 and report.stats.value.window==240 and #report.events==80)
 local n=0;for _ in m.stats do n+=1 end;for _ in m.counters do n+=1 end;assert(n<=129)
 local cycle={};cycle.self=cycle;assert(Metrics.estimate(cycle)<100000)
end)
test("QA RPC allowlists reject malformed arguments",function()
 assert(not Commands.validate("eval",{}));assert(not Commands.validate("reset",7));assert(not Commands.validate("ko",{actor="any"}))
 assert(not Commands.validate("scenario",{name="wall",position=H.V.zero}));assert(Commands.validate("profile",{enabled=true}))
 assert(not Metrics.validPayload({text=string.rep("x",513)}))
 local many={};for i=1,2050 do many[i]=i end;assert(not Metrics.validPayload(many))
 assert(Metrics.validPayload({stats={value={mean=2}},events={{kind="test",at=1}}}))
end)
test("profile on/off leaves actual attack health/events identical",function()
 local function run(enabled)
  local p={};local m=matches();m:start(p,"Flashstep","Mirage");local s=m.sessions[p];local prof=Profiler.new(m)
  local original=s.combat.update;if enabled then prof:start() end
  assert(m:request(p,{action="Attack"}));for _=1,70 do m:update(.01) end
  local health=s.bot.health;local hits=s.human.events.Hit or 0
  if enabled then assert(prof:report().stats["server.combat.ms"].count==70) end
  prof:stop();assert(s.combat.update==original);return health,hits
 end
 local a,b=run(false);local c,d=run(true);assert(a==c and b==d)
end)
test("repeated resets release old profiler wrappers",function()
 local p={};local m=matches();m:start(p,"Flashstep","Mirage");local prof=Profiler.new(m);prof:start()
 local old=m.sessions[p].combat;assert(rawget(old,"update")~=nil)
 for _=1,20 do m:start(p,"Mirage","Flashstep");prof:attach(m.sessions[p].combat) end
 assert(rawget(old,"update")==nil and #prof.metrics.restores<20);prof:stop()
end)
test("explicit setups use live combat and reinitialize actors",function()
 local p={};local m=matches();local tools=Tools.new(m)
 for _,name in {"neutral","launcher","air","substitution","grab","whiff","projectile","ko"} do
  local result=tools:run(p,"scenario",{name=name});assert(result.ok,name.." "..tostring(result.error))
  local s=m.sessions[p];assert(s.botFrozen and s.human.target==s.bot)
  if name=="launcher" then assert(s.bot.reaction=="Launched" and s.bot.reactionVelocity.Y>0)
  elseif name=="air" then assert(s.human.airborne and s.bot.airborne)
  elseif name=="substitution" then assert(s.human.subCharges==1)
  elseif name=="ko" then assert(s.bot.health<=0) end
 end
 assert(tools:run(p,"reset").ok and m.sessions[p].bot.health>0)
 assert(tools:run(p,"dummy",{enabled=false}).ok and not m.sessions[p].botFrozen)
 assert(not tools:run(p,"character",{first="unknown"}).ok)
end)
test("Studio tools install is a no-op in production",function()
 H.load("Server/DevHooks").install({})
 assert(H.load("Client/DevClient").install({})==nil)
end)
test("report export rows remain valid JSON below Studio truncation",function()
 local serde=require("@lune/serde");local output={};local gameBefore=H.envBase.game;local printBefore=H.envBase.print
 H.envBase.game={GetService=function(_,name) if name=="HttpService" then return {JSONEncode=function(_,data) return serde.encode("json",data) end} end;return gameBefore:GetService(name) end}
 H.envBase.print=function(line) table.insert(output,line) end
 local m=Metrics.new();m:start();for i=1,300 do m:sample("label"..i,i) end
 m:event("script-error",{error=string.rep("x",2000)})
 local report=m:report();report.build=string.rep("a",64)
 H.load("Server/DevReport").print({server=report,client=report})
 H.envBase.game=gameBefore;H.envBase.print=printBefore
 local rows=0
 for _,line in output do assert(#line<1000);local data=serde.decode("json",line:sub(#"[NinjaDuelPerf] "+1));if data.kind~="begin" and data.kind~="end" then rows+=1 elseif data.kind=="end" then assert(data.rows==rows) end end
 assert(rows>250)
end)
print("NinjaDuel dev infrastructure: "..passed.." PASS")
