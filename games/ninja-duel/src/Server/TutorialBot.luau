-- Debug/QA places only (build.py DEBUG_SOURCES). Plays the tutorial on its
-- own for a fighter, through the same Combat:request a player's remote reaches
-- (late presses included: the seat is a player), and returns the tutorial's
-- report: every step PASS / STUCK, with the refusals, the freezes and the
-- watchdogs the probe recorded. A STUCK step is a lead for a bug (or a step
-- this bot does not know how to play: read the line). From the command bar,
-- Server side, in a playtest:
--   require(game.ServerScriptService.NinjaDuelServer.TutorialBot).run(matches-free: uses the dev hook session)
-- or through the dev hook: NinjaDuelDev:Invoke("tutorialRun","Lion") then
-- NinjaDuelDev:Invoke("tutorial") for the report while it runs / when done.
local Tutorial=require(script.Parent.Tutorial)
local Brawler=require(script.Parent.Brawler)
local Bot={}
local function flat(v) return Vector3.new(v.X,0,v.Z) end

-- One script per step id: what a player would press. `s` is the session,
-- `wait(sec)` yields while the duel runs, `alive()` says the step still runs.
local function scripts(s,wait,alive)
	local c=s.combat
	local function A() return s.human end
	local function B() return s.bot end
	local function press(action,aim,opts) return c:request(A(),action,aim,nil,opts) end
	local function toward() local a,b=A(),B();local d=flat(b.root.Position-a.root.Position);return if d.Magnitude>.1 then d.Unit else Vector3.zAxis end
	-- The stick is also published on the body (TutorialStick/TutorialSprint):
	-- the debug client draws the player's own body ahead of the server by the
	-- local stick (Presentation:leadLocal); fed the bot's stick, it draws what a
	-- player holding that stick would see (Client/TutorialProbe).
	local function stick(v) local a=A();a.move=v;a.lastMove=os.clock()+5;Brawler.observe(c,a);a.model:SetAttribute("TutorialStick",v) end
	local function sprint(on) local a=A();a.sprinting=on;a.model:SetAttribute("TutorialSprint",on) end
	local function hold(v,sec) local t0=os.clock();while alive() and os.clock()-t0<sec do stick(v);wait(.05) end end
	local function chain(n,gap) for _=1,n do if not alive() then return end;press("Attack");wait(gap or .24) end end
	local S={}
	S.move=function() hold(toward():Cross(Vector3.yAxis),1.5);stick(Vector3.zero) end
	S.sprint=function() sprint(true);hold(toward():Cross(Vector3.yAxis),1.5);sprint(false);stick(Vector3.zero) end
	S.jump=function() press("Jump");wait(1.2) end
	S.lock=function()
		local a=A();a.locked=false;Brawler.event(c,a,"Unlock");wait(.2)
		a.locked=true;Brawler.event(c,a,"Lock");wait(.4)
	end
	S.dodge=function() stick(toward():Cross(Vector3.yAxis));press("Dodge");wait(.6);stick(Vector3.zero) end
	S.wall=function()
		-- Into the east wall (Tutorial places the body a few strides from it).
		local t0=os.clock()
		while alive() and not A().wall and os.clock()-t0<3 do stick(Vector3.xAxis);wait(.05) end
		wait(.15);press("Jump");wait(.6);stick(Vector3.zero)
	end
	S.string=function() stick(Vector3.zero);chain((A().def.StringLength or 4)+1,.26);wait(.5) end
	S.heavy=function() press("Heavy");wait(1) end
	-- The side route, like the others, opens after two hits (Brawler: combo>=2).
	S.routeSide=function() chain(2,.28);stick(toward():Cross(Vector3.yAxis));press("Attack");wait(.6);stick(Vector3.zero) end
	S.routeDown=function() chain(2,.28);stick(-toward());press("Attack");wait(.6);stick(Vector3.zero) end
	S.launch=function() chain(2,.28);stick(toward());press("Attack");wait(.6);stick(Vector3.zero) end
	S.chase=function() wait(.15);press("Pursuit");wait(.8) end
	S.air=function() press("Attack");wait(.26);press("Attack");wait(.6) end
	S.airFinish=function() press("Heavy");wait(.8) end
	S.runStrike=function()
		local a=A();sprint(true)
		local t0=os.clock()
		while alive() and os.clock()-t0<3 do
			stick(toward())
			local gap=flat(B().root.Position-a.root.Position).Magnitude
			if gap<9 and a.locomotion.Magnitude>28 then press("Attack");break end
			wait(.03)
		end
		sprint(false);wait(.6);stick(Vector3.zero)
	end
	-- Walk into reach first (Gaara and Sasori whiffed from the step's 5 studs:
	-- their grab does not carry the lunge the others do), then seize and throw.
	S.grab=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<1.5 and flat(B().root.Position-A().root.Position).Magnitude>2.8 do stick(toward());wait(.03) end
		stick(Vector3.zero);press("Grab");wait(.4);press("Attack");wait(1.2)
	end
	S.tool=function()
		local a=A()
		if a.def.Tool=="Deflect" then
			-- Kick when the partner's blade is coming (Techniques.bladeIncoming).
			local Techniques=require(script.Parent.Techniques)
			local t0=os.clock()
			while alive() and os.clock()-t0<4 do
				if Techniques.bladeIncoming(c,a,a.def.Deflect) then press("Tool",B().root.Position);wait(.9);return end
				wait(.02)
			end
			return
		end
		press("Tool",B().root.Position);wait(.9)
	end
	for i=1,5 do
		S["jutsu"..i]=function() press("Technique"..i,B().root.Position);wait(1.4) end
	end
	S.guard=function()
		local a=A();a.guardWanted=true;press("Guard")
		local t0=os.clock();while alive() and os.clock()-t0<3 do wait(.05) end
		a.guardWanted=false;press("GuardOff")
	end
	S.evade=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			local b=B()
			if b.attackName=="Heavy" and b.state=="Startup" and c.now-(b.attackStarted or c.now)>.12 then
				stick(toward():Cross(Vector3.yAxis));press("Dodge");wait(.6);stick(Vector3.zero);return
			end
			wait(.02)
		end
	end
	S.substitute=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			if A().reaction then wait(.05);press("Dodge");wait(.6);return end
			wait(.02)
		end
	end
	S.interrupt=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<5 do
			local b=B()
			if b.state=="TechniqueChannel" then
				local a=A()
				while alive() and B().state=="TechniqueChannel" and flat(B().root.Position-a.root.Position).Magnitude>5 do stick(toward());wait(.03) end
				stick(Vector3.zero);press("Attack");wait(.6);return
			end
			wait(.02)
		end
	end
	S.throwBreak=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			if A().reaction=="Grabbed" then press("Grab");wait(.5);return end
			wait(.02)
		end
	end
	S.awaken=function() press("Awaken");wait(1) end
	S.ultimate=function() press("Ultimate");wait(1.5) end
	return S
end

-- Plays the session's tutorial to its last step (the practice duel), each
-- step at most `perStep` seconds of its own timeout, then returns the report.
function Bot.play(s,perStep)
	local t=s.tutorial
	assert(t,"no tutorial running")
	t.timeoutScale=(perStep or 10)/40
	local index,started=0,0
	local function alive() return s.tutorial==t and t.index==index and s.phase=="Duel" end
	local S=scripts(s,task.wait,alive)
	while s.tutorial==t and s.phase=="Duel" do
		local spec=t.steps[t.index]
		if not spec or spec.id=="win" then break end
		if t.index~=index then index=t.index;started=os.clock() end
		local fn=S[spec.id]
		if fn then
			local ok,err=pcall(fn)
			if not ok then warn("[NinjaDuelTutorialBot] "..spec.id..": "..tostring(err)) end
		end
		task.wait(.1)
		if os.clock()-started>(perStep or 10)+2 then task.wait(.1) end
	end
	s.human.move=Vector3.zero;s.human.sprinting=false
	s.human.model:SetAttribute("TutorialStick",nil);s.human.model:SetAttribute("TutorialSprint",nil)
	return Tutorial.report(s)
end
return Bot
