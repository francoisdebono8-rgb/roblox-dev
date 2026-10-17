-- Debug/QA places only (build.py DEBUG_SOURCES): a native Studio pass for
-- roster fighters through the real server pipeline (the dev hook's `act`, the
-- same Combat:request the client remote reaches), for a Studio session driven
-- without the Windows MCP bridge (tools/studio/fighter_check.py). From the
-- command bar, Server side:
--   require(game.ServerScriptService.NinjaDuelServer.DevRosterCheck)("Mirror,Mist", 1.2)
-- For each fighter, against a frozen Rock Lee: a three-light string, the
-- toward route after two hits, the heavy, a jump and an air strike, the tool,
-- every technique aimed at the body, the awakening; then an AI-vs-AI duel to a
-- KO. Prints one line per step (what it produced) and every error the Output
-- received meanwhile. `pause` (s) leaves time to watch or capture each step.
-- It proves the server path in the real build; real keys and the look stay
-- checks of their own.
local LogService=game:GetService("LogService")
local ServerStorage=game:GetService("ServerStorage")
return function(list,pause)
	pause=pause or 1
	local dev=ServerStorage:WaitForChild("NinjaDuelDev",10)
	local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
	local errors={}
	local conn=LogService.MessageOut:Connect(function(message,kind)
		if kind==Enum.MessageType.MessageError then table.insert(errors,message) end
	end)
	local report={}
	local function line(text) print("[RosterCheck] "..text);table.insert(report,text) end
	local function state() return dev:Invoke("state") end
	local function place(gap) dev:Invoke("move","human",Vector3.zero);dev:Invoke("place",Vector3.new(0,3,gap/2),Vector3.new(0,3,-gap/2));task.wait(.25) end
	local function act(action,aim,stick)
		if stick then dev:Invoke("move","human",stick) end
		local r=dev:Invoke("act","human",action,aim)
		if stick then dev:Invoke("move","human",Vector3.zero) end
		return r
	end
	local function botPos() local s=state();return s.bot and s.bot.position end
	for id in string.gmatch(list,"[^,%s]+") do
		local def=Fighters[id]
		if not def then line(id..": NO DEFINITION");continue end
		local before=#errors
		dev:Invoke("start",id,"Leaf")
		local t0=os.clock()
		repeat task.wait(.2);local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
		dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true)
		local function reset(gap) dev:Invoke("refill");dev:Invoke("health","bot",400);dev:Invoke("health","human",def.Health);place(gap or 3.4) end
		-- String.
		reset(3.4)
		local hits=0
		local hp=state().bot.health
		for k=1,3 do
			act("Attack");task.wait(.42)
			local s=state()
			if s.bot.health<hp then hits+=1;hp=s.bot.health end
		end
		line(string.format("%s string: %d/3 lights landed",id,hits))
		task.wait(pause)
		-- Toward route after two confirmed hits.
		reset(3.4)
		act("Attack");task.wait(.42);act("Attack");task.wait(.36)
		local toward=(botPos()-state().human.position)*Vector3.new(1,0,1)
		act("Attack",nil,toward.Unit)
		task.wait(.05)
		line(string.format("%s toward route: %s",id,tostring(state().human.attackName)))
		task.wait(pause)
		-- Heavy.
		reset(3.4);act("Heavy");task.wait(.05)
		line(string.format("%s heavy: %s",id,tostring(state().human.attackName)))
		task.wait(pause)
		-- Jump + air strike.
		reset(6);act("Jump");task.wait(.2);act("Attack");task.wait(.05)
		local s=state()
		line(string.format("%s air: airborne=%s strike=%s",id,tostring(s.human.airborne),tostring(s.human.attackName)))
		task.wait(pause)
		-- Tool.
		reset(12)
		local r=act("Tool",botPos())
		local kinds={}
		for _=1,8 do task.wait(.05);for _,p in state().projectiles do kinds[p.kind]=true end end
		local seen={}
		for k in kinds do table.insert(seen,k) end
		line(string.format("%s tool: ok=%s reason=%s objects=%s",id,tostring(r.ok),tostring(r.reason),table.concat(seen,"/")))
		task.wait(pause)
		-- Techniques.
		for slot,spec in def.Techniques do
			local gap=math.clamp((spec.Range or 10)*.45,3.4,14)
			if spec.Family=="Burst" or spec.Family=="Counter" then gap=math.min(gap,(spec.Radius or 6)-1.5) end
			reset(math.max(gap,3))
			local hp0=state().bot.health
			local tr=act("Technique"..slot,botPos())
			local most,reaction,objects,hazards=0,nil,0,0
			for _=1,30 do
				task.wait(.05)
				local st=state()
				most=math.max(most,hp0-st.bot.health)
				reaction=reaction or st.bot.reaction
				objects=math.max(objects,#st.projectiles);hazards=math.max(hazards,st.hazards)
			end
			line(string.format("%s %s (%s): ok=%s reason=%s damage=%.1f reaction=%s objects=%d zones=%d",id,spec.Id,tostring(spec.Family or "own"),
				tostring(tr.ok),tostring(tr.reason),most,tostring(reaction),objects,hazards))
			task.wait(pause)
		end
		-- Awakening under the threshold.
		reset(10)
		dev:Invoke("health","human",def.Health*.25)
		local ar=act("Awaken");task.wait(.6)
		line(string.format("%s awakening: ok=%s reason=%s",id,tostring(ar.ok),tostring(ar.reason)))
		task.wait(pause)
		-- AI vs AI to a KO.
		dev:Invoke("start",id,"Leaf")
		task.wait(4)
		dev:Invoke("freezeBot",false);dev:Invoke("scripted",false);dev:Invoke("autopilot",true)
		local t1=os.clock()
		local phase
		repeat task.wait(.5);phase=state().phase until phase~="Duel" or os.clock()-t1>90
		dev:Invoke("autopilot",false)
		line(string.format("%s AI duel vs Leaf: phase=%s after %.0f s",id,tostring(phase),os.clock()-t1))
		local new=#errors-before
		line(string.format("%s errors during the pass: %d%s",id,new,if new>0 then " • "..errors[before+1] else ""))
	end
	conn:Disconnect()
	return table.concat(report,"\n")
end
