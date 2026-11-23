-- The REPORT button of the test place (23/11, step 5, DEC-049: « un test avec
-- 3 à 5 vrais joueurs »). A tester writes one sentence; the server keeps it
-- with where he was and what he was doing, for the DEV and the OUTILLEUR's
-- reading of the test (tools/): DataStore "NinjaDuelReports", one key per
-- report, and one log line `[NinjaDuelReport] <UserId> <phase> <text>`.
-- The client sends only its text (the DESIGN's button: remote
-- NinjaDuel.Report:FireServer(text)); the rest is the server's. At most
-- RATE reports a minute per player, 3 to MAX characters, never shown to other
-- players (kept for the developers only).
local Reports={}
Reports.RATE,Reports.MIN,Reports.MAX=3,3,300
Reports.STORE="NinjaDuelReports"

-- (pure) the report to keep, or nil: the text cleaned, its context.
function Reports.make(player,text,now,context,buckets)
	if type(text)~="string" then return nil end
	text=string.gsub(text,"[%c]"," ")
	text=string.match(text,"^%s*(.-)%s*$") or ""
	if #text<Reports.MIN then return nil end
	if #text>Reports.MAX then text=string.sub(text,1,Reports.MAX) end
	local b=buckets[player]
	if not b or now-b.at>=60 then b={at=now,n=0};buckets[player]=b end
	if b.n>=Reports.RATE then return nil end
	b.n+=1
	context=context or {}
	return {user=player.UserId,text=text,at=math.floor(now),phase=context.phase,kit=context.kit,
		where=context.where,version=context.version}
end

function Reports.start(matches)
	local Shared=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel")
	if not Shared or Shared:FindFirstChild("Report") then return end
	local remote=Instance.new("RemoteEvent");remote.Name="Report";remote.Parent=Shared
	local buckets={}
	local store
	pcall(function() store=game:GetService("DataStoreService"):GetDataStore(Reports.STORE) end)
	remote.OnServerEvent:Connect(function(player,text)
		local s=matches and matches.sessions and matches.sessions[player]
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local where=root and string.format("%.0f,%.0f,%.0f",root.Position.X,root.Position.Y,root.Position.Z) or nil
		-- the build's commit (build.py: NinjaDuel.SourceCommit)
		local commit=Shared:FindFirstChild("SourceCommit")
		local report=Reports.make(player,text,os.time(),{phase=s and s.phase,kit=player:GetAttribute("NinjaKit"),where=where,
			version=commit and commit.Value or nil},buckets)
		if not report then return end
		print(string.format("[NinjaDuelReport] %d %s %s",report.user,tostring(report.phase),report.text))
		if store then
			task.spawn(pcall,function() store:SetAsync(string.format("r_%d_%d_%d",report.at,report.user,buckets[player].n),report) end)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player) buckets[player]=nil end)
end

return Reports
