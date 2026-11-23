-- The REPORT button of the test place (23/11, step 5, DEC-049: « un test avec
-- 3 à 5 vrais joueurs »). A tester writes one sentence; the server keeps it
-- with where he was and what he was doing, for the DEV and the OUTILLEUR's
-- reading of the test (tools/): DataStore "NinjaDuelReports", one key per
-- report, and one log line `[NinjaDuelReport] <UserId> <phase> <text>`.
-- The client sends only its text and where it says it is (the DESIGN's
-- button: the action "Report" {text, where}); the rest is the server's. At most
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

-- The live side: the DESIGN's REPORT A PROBLEM (Client/SettingsPanel) sends
-- the action "Report" {text, where} on the game's one remote; Server/Matches
-- hands it here. Kept in the DataStore and a log line.
Reports.buckets={}
function Reports.record(player,text,where,session)
	local character=player.Character
	local root=typeof(character)=="Instance" and character:FindFirstChild("HumanoidRootPart") or nil
	local at=if type(where)=="string" and #where>0 then string.sub(where,1,80) else nil
	if root then
		at=(at and at.." @ " or "")..string.format("%.0f,%.0f,%.0f",root.Position.X,root.Position.Y,root.Position.Z)
	end
	-- the build's commit (build.py: NinjaDuel.SourceCommit)
	local okC,commit=pcall(function() return game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel"):FindFirstChild("SourceCommit") end)
	if not okC then commit=nil end
	local okK,kit=pcall(function() return player:GetAttribute("NinjaKit") end)
	local report=Reports.make(player,text,os.time(),{phase=session and session.phase,kit=okK and kit or nil,where=at,
		version=commit and commit.Value or nil},Reports.buckets)
	if not report then return false end
	print(string.format("[NinjaDuelReport] %d %s %s",report.user,tostring(report.phase),report.text))
	-- (the DataStore on the test place only: the published game keeps nothing)
	local store=Reports.testPlace() and Reports.dataStore()
	if store then
		local key=string.format("r_%d_%d_%d",report.at,report.user,Reports.buckets[player].n)
		task.spawn(pcall,function() store:SetAsync(key,report) end)
	end
	return true
end

function Reports.testPlace()
	local ok,on=pcall(function() return workspace:GetAttribute("NinjaTestPlace") end)
	return ok and on==true
end
function Reports.dataStore()
	if Reports.store==nil then
		Reports.store=false
		pcall(function() Reports.store=game:GetService("DataStoreService"):GetDataStore(Reports.STORE) end)
	end
	return Reports.store
end

-- (23/11, step 5, DEC-049) The test place: its PlaceId in Config.TestPlace
-- (François creates it); there, workspace's NinjaTestPlace shows the button.
function Reports.start()
	local ok,Config=pcall(function() return require(game:GetService("ReplicatedStorage").NinjaDuel.Config) end)
	local ids=ok and Config.TestPlace and Config.TestPlace.PlaceIds or {}
	if table.find(ids,game.PlaceId) then workspace:SetAttribute("NinjaTestPlace",true) end
	game:GetService("Players").PlayerRemoving:Connect(function(player) Reports.buckets[player]=nil end)
end

return Reports
