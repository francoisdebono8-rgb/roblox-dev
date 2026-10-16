-- Native smoke of the Studio dev tools themselves (Codex 33028b2, ported).
-- Never runs at bootstrap: started explicitly from the Debug/QA place with
-- dev:Invoke("tool","selftest"). It drives the same NinjaDuelDev "tool" ops
-- as the F6 panel: the nine setups, character / refill / awakening / repeat,
-- an AI-vs-AI capture with measurements on both sides, then checks that every
-- profiling wrapper is gone. Prints [NinjaDuelDevQA] PASS/FAIL rows and one
-- RESULT row (read by tools/dev.py report). Debug/QA places only (DEBUG_SOURCES).
local QA={}
local function stamp() return game:GetService("ReplicatedStorage").NinjaDuel.BuildFingerprint.Value end
function QA.run(matches)
	if not game:GetService("RunService"):IsStudio() then return end
	local Players=game:GetService("Players");local p=Players:GetPlayers()[1]
	local http=game:GetService("HttpService")
	if not p then warn("[NinjaDuelDevQA] FAIL no player in the playtest");return end
	local s0=matches.sessions[p]
	if s0 and s0.online then warn("[NinjaDuelDevQA] FAIL leave the online session first");return end
	local hook=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev")
	local failures={};local passed=0
	local function check(name,fn)
		local ok,err=pcall(fn)
		if ok then passed+=1;print("[NinjaDuelDevQA] PASS "..name)
		else table.insert(failures,name..": "..tostring(err));warn("[NinjaDuelDevQA] FAIL "..failures[#failures]) end
	end
	local function command(op,arg)
		local result=hook:Invoke("tool",op,arg);assert(type(result)=="table" and result.ok,type(result)=="table" and result.error or tostring(result));return result
	end
	local report=nil
	local ok,err=pcall(function()
		command("profile",{enabled=true})
		for _,name in {"neutral","launcher","air","wall","substitution","grab","whiff","projectile","ko"} do
			check(name,function()
				command("scenario",{name=name});local s=matches.sessions[p]
				assert(s and s.combat and s.botFrozen,"no frozen duel")
				if name=="launcher" then assert(s.bot.reaction=="Launched","bot not launched")
				elseif name=="wall" then assert(s.bot.reaction=="WallSplat","bot not splatted")
				elseif name=="air" then assert(s.human.airborne and s.bot.airborne,"not airborne")
				elseif name=="substitution" then assert(s.human.subCharges==1,"substitution charge not spent")
				elseif name=="ko" then assert(s.finishing,"no KO beat") end
				task.wait(.8)
			end)
		end
		check("fresh character / refill / awakening / repeat",function()
			command("character",{first="GentleFist",second="Mirage"});command("refill");command("awaken")
			assert(matches.sessions[p].human.awakened,"not awakened");command("repeat")
			assert(matches.sessions[p].human.fighterId=="GentleFist","repeat changed the fighter")
		end)
		command("reset",{first="Flashstep",second="Mirage"});command("dummy",{enabled=false});hook:Invoke("autopilot",true)
		task.wait(12);hook:Invoke("autopilot",false)
		report=command("report")
		check("both client and server measurements delivered",function()
			assert(report.client and report.client.stats["client.frame.ms"],"no client frame measurements (DevClient loaded? Studio in the foreground?)")
			assert(report.client.build==report.server.build,"client and server builds differ")
			assert(report.server.stats["server.combat.ms"],"no server combat measurements")
		end)
		command("profile",{enabled=false})
		check("all profiling wrappers removed",function()
			assert(rawget(matches,"update")==nil and rawget(matches.sessions[p].combat,"update")==nil,"a wrapper survived OFF")
		end)
		command("reset")
	end)
	if not ok then table.insert(failures,"aborted: "..tostring(err));warn("[NinjaDuelDevQA] FAIL aborted: "..tostring(err)) end
	pcall(function() hook:Invoke("autopilot",false);hook:Invoke("tool","profile",{enabled=false}) end)
	print("[NinjaDuelDevQA] RESULT "..http:JSONEncode({pass=passed,failures=failures,build=stamp()}))
end
return QA
