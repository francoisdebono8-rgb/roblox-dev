-- What the OUTILLEUR's two-player test in Studio found (19/11, claude/
-- outilleur-vague2-2026-11-19 § 3), fixed by the DEV:
--  * a body stuck on the roof of Ichiraku's stand in a street duel: put back
--    on the floor (Combat:unstick);
--  * no challenge in Studio: the local test players have negative ids,
--    taken there and never on a live server (Lobby.target);
--  * the online duel in the funnel: started, hit, duel, won (Matches.FUNNEL);
--  * the quests' module says Quest (Shared/DailyQuests).
-- Headless; the TALK bubble hidden over a duel is a Studio check (the
-- client's ProximityPromptService, Client/HubClient:apply).
local H=require("./Harness")
local roblox=require("@lune/roblox")
local Vector3,CFrame=roblox.Vector3,roblox.CFrame
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end

test("a body stuck above the floor of a village duel, asking to move, is put back on the floor",function()
	local c,a,b,match=H.duel("Leaf","Flashstep")
	match.radius=28
	-- a roof over x in [-12, 12], z in [8, 34], its top at 9.6 (Ichiraku's stand)
	local raycast=H.workspace.Raycast
	H.workspace.Raycast=function(ws,origin,delta,params)
		if delta.Y<0 and origin.X>=-12 and origin.X<=12 and origin.Z>=8 and origin.Z<=34 and origin.Y>9.6 then
			return {Position=Vector3.new(origin.X,9.6,origin.Z),Normal=Vector3.yAxis,Distance=origin.Y-9.6,Instance={Name="StandRoof",GetAttribute=function() return nil end}}
		end
		return raycast(ws,origin,delta,params)
	end
	local ok,err=pcall(function()
		local Combat=getmetatable(c).__index
		a.root.CFrame=CFrame.new(0,12.6,20)
		a.move=Vector3.new(1,0,0)
		c.now=200
		assert(not c:unstick(a,c.now),"rescued at once")
		c.now+=Combat.UNSTICK_AFTER-.1
		assert(not c:unstick(a,c.now),"rescued too early")
		c.now+=.2
		assert(c:unstick(a,c.now),"not rescued after the wait")
		local p=a.root.Position
		assert(p.Y<4,"still above the floor: "..tostring(p))
		assert(p.Z<8,"put back under the roof: "..tostring(p))
		assert(not a.airborne)
		-- standing on the floor, or not asking to move: left alone
		a.root.CFrame=CFrame.new(0,3,0);a.move=Vector3.new(1,0,0);c.now+=10
		c:unstick(a,c.now);c.now+=10
		assert(not c:unstick(a,c.now),"a body on the floor was moved")
		a.root.CFrame=CFrame.new(0,12.6,20);a.move=Vector3.zero
		c:unstick(a,c.now);c.now+=10
		assert(not c:unstick(a,c.now),"a body that does not ask to move was moved")
		-- moving on a roof (parkour): left alone
		a.move=Vector3.new(1,0,0)
		for k=1,6 do a.root.CFrame=CFrame.new(-10+k*3,12.6,20);c.now+=1;assert(not c:unstick(a,c.now),"a body running on the roof was moved") end
	end)
	H.workspace.Raycast=raycast
	assert(ok,err)
end)

test("a challenge's target: a real player, or a test player in Studio only",function()
	local Lobby=H.load("Server/Lobby")
	local was=Lobby.inStudio
	Lobby.inStudio=function() return false end
	assert(Lobby.target(42) and not Lobby.target(-1) and not Lobby.target(0) and not Lobby.target(1.5) and not Lobby.target("42") and not Lobby.target(0/0),"live")
	Lobby.inStudio=function() return true end
	assert(Lobby.target(-1) and Lobby.target(-2) and Lobby.target(42) and not Lobby.target(0),"Studio")
	Lobby.inStudio=was
end)

test("the funnel's format, and the quests' module named for the robot",function()
	H.envBase.task={delay=function() end,spawn=function() end,defer=function() end,wait=function() return 0 end}
	local World=H.load("Server/World")
	World.arena=function() end
	local Matches=H.load("Server/Matches")
	local seen={}
	for step,order in Matches.FUNNEL do
		assert(type(step)=="string" and type(order)=="number" and order==math.floor(order),"a step")
		assert(not seen[order],"two steps at "..order);seen[order]=step
	end
	for k=1,#seen do assert(seen[k],"a hole at "..k) end
	assert(Matches.FUNNEL.started<Matches.FUNNEL.hit and Matches.FUNNEL.hit<Matches.FUNNEL.duel and Matches.FUNNEL.duel<Matches.FUNNEL.won)
	-- an online seat is measured on its own session
	local lines={}
	local player={UserId=-3}
	local s={metrics={joined=os.clock()}}
	local print_=print
	print=function(line) table.insert(lines,line) end
	Matches.measure(player,s,"started");Matches.measure(player,s,"duel");Matches.measure(player,s,"duel")
	print=print_
	assert(#lines==2 and string.find(lines[1],"^%[NinjaDuelFirst%] %-3 started") and s.metrics.funnel==Matches.FUNNEL.duel,"the log lines: "..table.concat(lines," | "))
	local DailyQuests=H.load("Shared/DailyQuests")
	assert(DailyQuests.today and DailyQuests.record,"Shared/DailyQuests")
end)

print(string.format("NinjaDuel the OUTILLEUR's two-player test, fixed: %d PASS",passed))
