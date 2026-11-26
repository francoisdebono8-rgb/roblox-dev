-- The server's side of the robots (OUTILLEUR, passe commune 2, 26/11). A
-- server module, injected in a Play of the game's place (DEC-052) with
--   python3 tools/robots/inject.py --server serverlog   (eval_server_runtime)
-- It keeps, from the moment it starts:
--   errors, warnings   the server's red and orange lines (each text once, counted)
--   tutorial           every [NinjaDuelTutorial] line: one per step finished
--                      (PASS, STUCK, SKIP, with the refusals and freezes)
--   perf               the server's frames (Heartbeat): steps per second, the
--                      slowest, those over 33 / 50 / 100 ms, between perfStart
--                      and perfStop (a hitch here is a hitch of every body)
--   _G.NDServerLog.start()  ·  .read()  ·  .perfStart(label)  ·  .perfStop()
--   .tutorialReport()  the running tutorial's own report (Server/Tutorial.report)
local LogService=game:GetService("LogService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Players=game:GetService("Players")

local Log={}
local conns={}
local errors,warnings,tutorial={}, {}, {}
local perf={}
local probe=nil

local function r1(x) return math.floor(x*10+.5)/10 end
function Log.start()
	for _,c in conns do c:Disconnect() end
	conns={};errors={};warnings={};tutorial={}
	local t0=os.clock()
	table.insert(conns,LogService.MessageOut:Connect(function(msg,kind)
		if string.find(msg,"NDServerLog",1,true) then return end
		if string.find(msg,"[NinjaDuelTutorial]",1,true) then
			table.insert(tutorial,{t=r1(os.clock()-t0),line=string.sub(msg,1,400)})
			return
		end
		local list=if kind==Enum.MessageType.MessageError then errors elseif kind==Enum.MessageType.MessageWarning then warnings else nil
		if not list then return end
		local short=string.sub(msg,1,240)
		local e=list[short]
		if not e then e={n=0,first=r1(os.clock()-t0)};list[short]=e end
		e.n+=1
	end))
	return "journal du serveur en route"
end
function Log.perfStart(label)
	if probe then probe.conn:Disconnect() end
	probe={label=label or "?",frames={},t0=os.clock()}
	probe.conn=RunService.Heartbeat:Connect(function(dt) table.insert(probe.frames,dt) end)
	return "mesure du serveur : "..probe.label
end
function Log.perfStop()
	if not probe then return nil end
	probe.conn:Disconnect()
	local f=probe.frames
	local n=#f
	local sum,worst=0,0
	local over33,over50,over100=0,0,0
	for _,dt in f do
		sum+=dt;worst=math.max(worst,dt)
		if dt>1/30 then over33+=1 end
		if dt>.05 then over50+=1 end
		if dt>.1 then over100+=1 end
	end
	table.sort(f,function(a,b) return a>b end)
	local p1=f[math.max(1,math.floor(n*.01))] or 0
	local rec={label=probe.label,seconds=r1(os.clock()-probe.t0),frames=n,steps=if sum>0 then r1(n/sum) else nil,
		worstMs=r1(worst*1000),p1Ms=r1(p1*1000),over33=over33,over50=over50,over100=over100}
	table.insert(perf,rec)
	probe=nil
	return HttpService:JSONEncode(rec)
end
function Log.read()
	local out={errors={},warnings={},tutorial=tutorial,perf=perf}
	for msg,e in errors do table.insert(out.errors,{msg=msg,n=e.n,first=e.first}) end
	for msg,e in warnings do table.insert(out.warnings,{msg=msg,n=e.n,first=e.first}) end
	return HttpService:JSONEncode(out)
end
-- The tutorial running for the (only) player: its report, step by step.
function Log.tutorialReport()
	local server=game:GetService("ServerScriptService"):FindFirstChild("NinjaDuelServer")
	local matches=server and require(server.Hub).matches
	local p=Players:GetPlayers()[1]
	local s=matches and p and matches.sessions[p]
	if not s or not s.tutorial then return nil end
	return HttpService:JSONEncode(require(server.Tutorial).report(s))
end
return Log
