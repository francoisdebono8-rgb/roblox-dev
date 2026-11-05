-- The server's own path (Studio, Server datamodel, through execute_luau; not
-- shipped). Counts the velocity breaks of each fighter's authoritative root,
-- with the same rule as the client probes (above 650 studs/s² while under
-- 120 studs/s, a jump of 10+ studs being a teleport), so the breaks the
-- client adds when it draws the bodies can be told from the ones the server
-- already has. Fluidity audit 05/11 (docs/reports/fluidite-2026-11-05).
-- _G.SRV.report() / _G.SRV.reset().
local Run=game:GetService("RunService")
if _G.SRV and _G.SRV.conn then _G.SRV.conn:Disconnect() end
local S={snap={human=0,bot=0},frames=0,st={human={},bot={}}}
_G.SRV=S
S.conn=Run.Heartbeat:Connect(function(dt)
	local duels=workspace:FindFirstChild("NinjaDuels")
	local duel=duels and duels:FindFirstChildWhichIsA("Folder")
	if not duel or dt>.1 then return end
	S.frames+=1
	for key,name in {human="PlayerFighter",bot="AIFighter"} do
		local m=duel:FindFirstChild(name)
		local root=m and m:FindFirstChild("HumanoidRootPart")
		local s=S.st[key]
		if root then
			local p=root.Position
			if s.p and (p-s.p).Magnitude<10 then
				local v=(p-s.p)/dt
				if s.v then
					local acc=(v-s.v).Magnitude/dt
					if acc>650 and v.Magnitude<120 then S.snap[key]+=1 end
				end
				s.v=v
			else s.v=nil end
			s.p=p
		end
	end
end)
function S.report()
	return string.format("server heartbeats %d | velocity breaks of the server's own roots (all states): human %d, bot %d",S.frames,S.snap.human,S.snap.bot)
end
function S.reset() S.snap={human=0,bot=0};S.frames=0 end
return "server path probe on"
