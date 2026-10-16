-- Codex's Studio dev tools (33028b2 / 7091585, ported): bounded metrics, the
-- command allowlist, the nine setups and the tool ops on the REAL Matches /
-- Combat, the profiler on local and online duels, report rows, the Studio-only
-- gates and the chakra lab's runtime gate. Harness rigs and a scripted clock:
-- it proves states, wrappers and isolation, NOT the F6 panel, MicroProfiler
-- scopes, replication or Studio physics (native checks: docs/tools/DEVTOOLS.md).
local H=require("./Harness")
local clock=1000
H.workspace.GetServerTimeNow=function() return clock end
-- Deterministic stand-in for task.delay (the KO beat between rounds).
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
-- The stage is not under test: no arena geometry, harness rigs for bodies.
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local Metrics=H.load("Shared/DevMetrics")
local Commands=H.load("Server/DevCommands")
local Scenarios=H.load("Server/DevScenarios")
local Tools=H.load("Server/DevTools")
local Fighters=H.load("Shared/Fighters")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local remote={FireClient=function() end}
local nextId=0
local function newPlayer(name)
	nextId+=1
	return {UserId=nextId,Name=name,DisplayName=name,Parent=H.Players,Character=nil}
end
local seed=11
local function fresh()
	local m=Matches.new(remote)
	m.online.rng={NextInteger=function(_,a,b) seed=(seed*1103515245+12345)%2147483648;return a+seed%(b-a+1) end}
	return m
end
local function join(m,...)
	local list={}
	for _,name in {...} do local p=newPlayer(name);m:selection(p);table.insert(list,p) end
	return table.unpack(list)
end
local function send(m,player,action,extra)
	local s=m.sessions[player];s.bucket.tokens=100;s.lastLifecycle=-10
	local payload={action=action,epoch=s.epoch}
	for k,v in extra or {} do payload[k]=v end
	m:request(player,payload)
end
local function step(m,seconds)
	for _=1,math.max(1,math.ceil(seconds/.01)) do clock+=.01;m:update(.01,clock);runTimers() end
end
local function fight(m,a,b)
	send(m,a,"Queue",{player="Flashstep"});send(m,b,"Queue",{player="Mirage"})
	send(m,a,"Confirm");send(m,b,"Confirm")
	local d=m.sessions[a].online and m.sessions[a].online.duel
	assert(d and d.phase=="Duel","the online fight did not start")
	return d
end

test("instrumentation preserves nil returns, errors and inherited methods",function()
	local t=0;local m=Metrics.new(function() t+=.001;return t end)
	local original=function(_,v) if v==false then error("original error") end;return v,nil,3 end
	local obj=setmetatable({},{__index={f=original}})
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
test("tool RPC allowlist rejects malformed arguments; client reports stay bounded",function()
	assert(not Commands.validate("eval",{}));assert(not Commands.validate("reset",7));assert(not Commands.validate("ko",{actor="any"}))
	assert(not Commands.validate("scenario",{name="wall",position=H.V.zero}));assert(not Commands.validate("scenario",{name=string.rep("x",33)}))
	assert(not Commands.validate("character",{first="A",second="B",name="c",actor="bot",enabled=true,extra=1}))
	for _,op in {"profile","list","panel","selftest","repeat"} do assert(Commands.validate(op,{}),op) end
	assert(Commands.validate("profile",{enabled=true}))
	assert(not Metrics.validPayload({text=string.rep("x",513)}))
	local many={};for i=1,2050 do many[i]=i end;assert(not Metrics.validPayload(many));assert(Metrics.validPayload(many,8192))
	assert(Metrics.validPayload({stats={value={mean=2}},events={{kind="test",at=1}}}))
	-- A full client capture (every label, 80 events) fits the server's report bound.
	local m=Metrics.new();m:start()
	for i=1,40 do m:sample("client.label"..i,i);m:count("client.count"..i) end
	for i=1,100 do m:event("visual-position-jump",{actor="bot",state="Neutral",reaction="Launched",attack="Heavy",studs=i,warp=i,previousWarp=i-1,ms=16}) end
	local report=m:report();report.build=string.rep("a",64)
	assert(Metrics.validPayload(report,8192) and Metrics.estimate(report,0,{left=8192})<200000)
end)
test("profile on/off leaves the real duel's health and events identical",function()
	local function run(enabled)
		local m=fresh();local p=join(m,"Prof");local tools=Tools.new(m)
		assert(tools:run(p,"reset",{first="Flashstep",second="Mirage"}).ok)
		local s=m.sessions[p];local original=s.combat.update
		if enabled then assert(tools:run(p,"profile",{enabled=true}).enabled==true) end
		assert(s.combat:request(s.human,"Attack"))
		step(m,.7)
		local health=s.bot.health;local hits=s.human.events and s.human.events.Hit or 0
		if enabled then
			local report=tools.profiler:report()
			assert(report.stats["server.combat.ms"] and report.stats["server.combat.ms"].count==70,"combat tick not measured once per step")
			assert(report.stats["server.heartbeat.ms"] and report.stats["server.snapshot.estimatedBytes"],"matches wrappers missing")
			assert(report.build=="headless")
		end
		assert(tools:run(p,"profile",{enabled=false}).enabled==false)
		assert(s.combat.update==original and rawget(s.combat,"update")==nil and rawget(m,"update")==nil and rawget(m,"send")==nil)
		return health,hits
	end
	local a,b=run(false);local c,d=run(true)
	assert(a==c and b==d,"measurements changed the fight")
	assert(a<Fighters.Mirage.Health,"the scripted light never connected: the comparison would prove nothing")
end)
test("repeated resets release the old profiler wrappers",function()
	local m=fresh();local p=join(m,"Reset");local tools=Tools.new(m)
	assert(tools:run(p,"reset").ok);assert(tools:run(p,"profile",{enabled=true}).ok)
	local old=m.sessions[p].combat;assert(rawget(old,"update")~=nil)
	for i=1,20 do
		assert(tools:run(p,"character",{first=if i%2==0 then "Flashstep" else "Lion"}).ok)
		tools.profiler:attach(m.sessions[p].combat)
	end
	assert(rawget(old,"update")==nil and #tools.profiler.metrics.restores<20)
	assert(tools:run(p,"profile",{enabled=false}).ok and #tools.profiler.metrics.restores==0)
	assert(rawget(m.sessions[p].combat,"update")==nil)
end)
test("nine setups rebuild a live duel and reach their state through the engine",function()
	local m=fresh();local p=join(m,"Setups");local tools=Tools.new(m)
	assert(tools:run(p,"reset").ok)
	-- A real NinjaWall plane at World.WALL_RADIUS on +X of this lane.
	H.addWall(m.sessions[p].origin.X+World.WALL_RADIUS)
	for _,name in Scenarios.names do
		local before=m.sessions[p].epoch
		local result=tools:run(p,"scenario",{name=name});assert(result.ok,name..": "..tostring(result.error))
		local s=m.sessions[p];local c=s.combat
		assert(result.scenario.scenario==name and result.scenario.epoch==s.epoch and s.epoch>before,name.." did not rebuild the duel")
		assert(s.botFrozen and s.introUntil==nil and s.human.target==s.bot and s.phase=="Duel",name)
		if name=="neutral" then assert((s.human.root.Position-s.bot.root.Position).Magnitude<7 and s.human.health==s.human.def.Health)
		elseif name=="launcher" then assert(s.bot.reaction=="Launched" and s.bot.reactionVelocity.Y>0 and s.human.pursuitUntil>c.now)
		elseif name=="air" then assert(s.human.airborne and s.bot.airborne and s.bot.reaction=="Juggled")
		elseif name=="wall" then
			assert(s.bot.reaction=="WallSplat" and s.bot.splatPart and s.bot.splatPart:GetAttribute("NinjaWall"),"no splat on the NinjaWall")
			assert(s.human.pursuitUntil>c.now and (s.bot.events or {}).WallSplat==1,"the engine's splat did not run")
		elseif name=="substitution" then assert(s.human.subCharges==1)
		elseif name=="grab" then assert(s.human.attackName=="Grab")
		elseif name=="whiff" then assert(s.human.attackName=="Heavy" and (s.human.root.Position-s.bot.root.Position).Magnitude>15)
		elseif name=="projectile" then assert(s.human.throwing~=nil or #c.projectiles>0)
		elseif name=="ko" then assert(s.bot.health<=0 and s.finishing) end
	end
	H.clearWalls()
	-- The KO beat still resolves through the real round flow; the dummy stays frozen.
	local koEpoch=m.sessions[p].epoch
	step(m,2.2)
	local s=m.sessions[p]
	assert(s.epoch>koEpoch and s.bot.health==s.bot.def.Health and s.botFrozen,"the KO setup broke the round flow")
	assert(tools:run(p,"repeat").ok and tools.last[p]=="ko")
	assert(tools:run(p,"reset").ok and m.sessions[p].bot.health>0 and not m.sessions[p].finishing)
	assert(tools:run(p,"dummy",{enabled=false}).ok and not m.sessions[p].botFrozen)
	assert(tools:run(p,"reset").ok and not m.sessions[p].botFrozen,"reset lost the AI choice")
	assert(not tools:run(p,"character",{first="unknown"}).ok and not tools:run(p,"scenario",{name="unknown"}).ok)
end)
test("the wall setup refuses a stage without a NinjaWall instead of inventing one",function()
	local m=fresh();local p=join(m,"NoWall");local tools=Tools.new(m)
	local result=tools:run(p,"scenario",{name="wall"})
	assert(not result.ok and result.error:find("No wall"))
end)
test("CORE4 character swaps, refill, awakening and KO run the real engine",function()
	local m=fresh();local p=join(m,"Ops");local tools=Tools.new(m)
	for _,id in Scenarios.core do assert(Fighters[id],id) end
	assert(tools:run(p,"reset",{first="GentleFist",second="Lion"}).ok)
	local s=m.sessions[p]
	assert(s.human.fighterId=="GentleFist" and s.bot.fighterId=="Lion")
	assert(tools:run(p,"character",{second="Mirage"}).ok and m.sessions[p].human.fighterId=="GentleFist" and m.sessions[p].bot.fighterId=="Mirage")
	s=m.sessions[p]
	s.human.chakra=0;s.human.cooldowns={Rotation=1e9};s.human.subCharges=0
	assert(tools:run(p,"refill").ok and s.human.chakra==s.human.def.Chakra and next(s.human.cooldowns)==nil and s.human.subCharges==2)
	assert(tools:run(p,"awaken").ok and s.human.awakened and s.human.awakenUntil>s.combat.now)
	-- The real awakening shockwave knocks the close opponent back: it must recover first.
	local refused=tools:run(p,"awaken",{actor="bot"})
	assert(not refused.ok and refused.error=="Reacting" and not s.bot.awakened,tostring(refused.error))
	step(m,1.2)
	local result=tools:run(p,"awaken",{actor="bot"});assert(result.ok and s.bot.awakened,tostring(result.error))
	step(m,1.2)
	result=tools:run(p,"awaken");assert(result.ok,"QA awakening is repeatable: "..tostring(result.error))
	assert(tools:run(p,"ko",{actor="bot"}).ok and s.bot.health<=0 and s.finishing)
	local list=tools:run(p,"list")
	assert(list.ok and #list.scenarios==9 and #list.fighters==4 and list.dummy==true)
	assert(tools:run(p,"panel").ok and tools:run(p,"selftest").ok,"DevHooks-carried ops must validate")
end)
test("a skill build survives a setup on the same pairing, never on a new one",function()
	local m=fresh();local p=join(m,"Build");local tools=Tools.new(m)
	assert(m:start(p,"Flashstep","Mirage",false,{bot={preset="Hard"}}),"preset start refused")
	assert(m.sessions[p].bot.build~=nil)
	assert(tools:run(p,"scenario",{name="neutral"}).ok and m.sessions[p].bot.build~=nil,"the setup dropped the build")
	assert(tools:run(p,"character",{second="GentleFist"}).ok and m.sessions[p].bot.build==nil and m.sessions[p].options==nil)
end)
test("online sessions are refused and left untouched, waiting or fighting",function()
	local m=fresh();local a,b=join(m,"Alpha","Bravo");local tools=Tools.new(m)
	send(m,a,"Queue",{player="Flashstep"})
	local s=m.sessions[a];local epoch=s.epoch
	assert(s.phase=="Queue" and s.online)
	for _,command in {{"reset"},{"character",{first="Mirage"}},{"scenario",{name="neutral"}},{"repeat"},{"dummy",{enabled=true}},{"refill"},{"awaken"},{"ko",{actor="bot"}}} do
		local result=tools:run(a,command[1],command[2])
		assert(not result.ok and result.error:find("Online"),command[1])
	end
	assert(s.phase=="Queue" and s.epoch==epoch and s.online and not s.combat,"a refused op touched the queue")
	local d=fight(m,a,b)
	assert(not tools:run(a,"scenario",{name="launcher"}).ok and not tools:run(b,"reset").ok)
	assert(d.phase=="Duel" and d.combat and m.sessions[a].online.duel==d and m.sessions[b].online.duel==d)
end)
test("the profiler observes an online duel and releases it on teardown",function()
	local m=fresh();local a,b=join(m,"Uno","Dos");local tools=Tools.new(m)
	local d=fight(m,a,b);local c=d.combat
	assert(tools:run(a,"profile",{enabled=true}).ok)
	assert(rawget(c,"update")~=nil,"online combat not attached")
	step(m,.3)
	local report=tools.profiler:report()
	assert(report.stats["server.combat.ms"] and report.stats["server.combat.ms"].count>=30)
	m:selection(a);m:selection(b)
	assert(d.combat==nil and rawget(c,"update")==nil,"teardown kept the wrappers")
	assert(tools:run(a,"profile",{enabled=false}).ok and rawget(m.online,"teardown")==nil)
end)
test("Studio tools install is a no-op outside Studio",function()
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
	local ok,err=pcall(function() H.load("Server/DevReport").print({server=report,client=report}) end)
	H.envBase.game=gameBefore;H.envBase.print=printBefore
	assert(ok,err)
	local rows=0
	for _,line in output do
		assert(#line<1000)
		local data=serde.decode("json",line:sub(#"[NinjaDuelPerf] "+1))
		if data.kind~="begin" and data.kind~="end" then rows+=1 elseif data.kind=="end" then assert(data.rows==rows) end
	end
	assert(rows>250)
end)
-- The chakra lab is ported, the chakra runtime it drives is not: DevHooks only
-- loads the lab when every runtime module exists (DevTools.ChakraRuntime).
local runtime=true
for _,name in Tools.ChakraRuntime do if not H.names.Server[name] then runtime=false end end
test("the chakra lab is gated on the chakra runtime modules",function()
	local parent=setmetatable({},{__index={FindFirstChild=function(_,name) return H.names.Server[name] end}})
	local missing=Tools.missing(parent,Tools.ChakraRuntime)
	if runtime then assert(missing==nil) else assert(missing~=nil and H.names.Server[missing]==nil,"gate named a present module") end
	for _,name in {"ChakraLab","ChakraDev","ChakraStudioView","ChakraStudioQA"} do assert(H.names.Server[name],name) end
	assert(Tools.missing(parent,{})==nil)
end)
if runtime then
	test("chakra lab drives the runtime: six demos, comparison, Studio-only ops refused headless",function()
		local cfg=H.load("Server/ChakraConfig");local Dev=H.load("Server/ChakraDev")
		local d=Dev.new(cfg,false)
		for _,name in {"kunai_wind","kunai_seal","redirection","wire_property","projectile_surface","fire_surface"} do
			local demo=d:run("demo",{name=name});assert(demo.ok,name..": "..tostring(demo.error))
			local result=d:run("step",{seconds=1});assert(result.ok,tostring(result.error))
			local report=result.result;local a=report.objects.a;assert(a and #report.events>0,name)
			if name=="kunai_wind" then assert(a.stats.speed>42)
			elseif name=="kunai_seal" then assert(a.embedded and a.anchor)
			elseif name=="redirection" then assert(report.objects.b.velocity.x>0)
			elseif name=="wire_property" then assert(a.tags.conductiveWire)
			elseif name=="projectile_surface" then assert(a.embedded)
			elseif name=="fire_surface" then assert(report.surfaces.wood.tags.ignited) end
		end
		local rows=d:run("compare");assert(rows.ok and #rows.result==6)
		assert(not d:run("show").ok and not d:run("play").ok and not d:run("qa").ok and not d:run("unknown").ok)
		assert(cfg.Enabled==false,"the lab enabled the shared configuration")
	end)
end
print("NinjaDuel dev tools: "..passed.." PASS"..(if runtime then " (chakra lab on the runtime)" else " (chakra lab gated: runtime modules absent)"))
