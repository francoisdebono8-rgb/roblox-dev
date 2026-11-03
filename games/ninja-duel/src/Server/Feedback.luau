-- Players' reports from inside the game (beta, user 03/11: "a way to collect
-- their opinions, the bugs they see while playing and the improvements they
-- would like"). One form on the client (Client/Feedback): a bug, an idea or an
-- opinion, a few lines of text; the game adds where it was sent from (screen,
-- fighters, round, device, build) so a bug can be found again.
--
-- Here, on the server:
--   * the request is checked: kind, length, one report every 30 s and twenty
--     per visit at most, the context reduced to short known fields;
--   * the text passes Roblox's text filter before it is kept or shown to
--     anyone (if the filter cannot run, the report is refused, never kept raw);
--   * it is kept in a DataStore (NinjaDuelFeedback_v1), newest first through
--     an ordered index, so nothing depends on an outside service;
--   * if the experience has a secret named "feedback_webhook" (the path of a
--     Discord webhook, see docs/active/FEEDBACK.md), a copy is posted to the
--     Discord's reports channel. Without the secret, or if Discord refuses,
--     the report is still kept.
-- In Studio, ServerStorage.NinjaDuelFeedback:Invoke("list", n) returns the n
-- newest reports (the developer reads them; the live game has no reader).
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TextService=game:GetService("TextService")
local Feedback={}

local STORE="NinjaDuelFeedback_v1"
local INDEX="NinjaDuelFeedbackIndex_v1"
local KINDS={bug="Bug",idea="Idea",opinion="Opinion"}
local MAX_TEXT=500
local MIN_TEXT=4
local COOLDOWN=30
local PER_VISIT=20
-- Context the client may describe; anything else is dropped.
local CONTEXT={phase=24,fighter=24,opponent=24,round=8,score=12,mode=16,device=12,tutorial=24}

local sent={} -- [player] = {last=os.clock(), count=n}

local function clean(value,limit)
	if typeof(value)~="string" and typeof(value)~="number" then return nil end
	local s=tostring(value):gsub("[%c]"," ")
	if #s==0 then return nil end
	return string.sub(s,1,limit)
end

local function filtered(text,userId)
	local ok,result=pcall(function()
		local r=TextService:FilterStringAsync(text,userId,Enum.TextFilterContext.PublicChat)
		return r:GetNonChatStringForBroadcastAsync()
	end)
	if ok and typeof(result)=="string" then return result end
	return nil
end

local function webhookUrl()
	local ok,secret=pcall(function() return HttpService:GetSecret("feedback_webhook") end)
	if not ok or not secret then return nil end
	local built
	ok=pcall(function() built=secret:AddPrefix("https://discord.com/api/webhooks/") end)
	if ok then return built end
	return nil
end

local COLORS={bug=0xBE2824,idea=0xE6B856,opinion=0x52B1F4}
local function toDiscord(report)
	local url=webhookUrl()
	if not url then return false end
	local fields={}
	for _,k in {"phase","fighter","opponent","round","score","mode","device","tutorial"} do
		if report.context[k] then table.insert(fields,{name=k,value=report.context[k],inline=true}) end
	end
	table.insert(fields,{name="build",value=report.build,inline=true})
	table.insert(fields,{name="version",value=tostring(report.placeVersion),inline=true})
	local body=HttpService:JSONEncode({
		username="Ninja Duel — in-game reports",
		allowed_mentions={parse={}},
		embeds={{
			title=KINDS[report.kind].." — "..report.player,
			description=report.text,
			color=COLORS[report.kind],
			fields=fields,
			footer={text=report.id},
			timestamp=DateTime.fromUnixTimestamp(report.time):ToIsoDate(),
		}},
	})
	local ok,response=pcall(function()
		return HttpService:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=body})
	end)
	if not ok then warn("[NinjaDuel] feedback → Discord: "..tostring(response));return false end
	if not response.Success then warn("[NinjaDuel] feedback → Discord: HTTP "..tostring(response.StatusCode));return false end
	return true
end

local function keep(report)
	local store=DataStoreService:GetDataStore(STORE)
	local index=DataStoreService:GetOrderedDataStore(INDEX)
	local ok,err=pcall(function()
		store:SetAsync(report.id,report,{report.userId})
		index:SetAsync(report.id,report.time)
	end)
	if not ok then warn("[NinjaDuel] feedback not kept: "..tostring(err)) end
	return ok
end

-- The request from a client: returns ok, message for the form.
function Feedback.submit(player,payload)
	if typeof(payload)~="table" then return false,"Something went wrong. Try again." end
	local kind=payload.kind
	if typeof(kind)~="string" or not KINDS[kind] then return false,"Pick bug, idea or opinion." end
	local raw=payload.text
	if typeof(raw)~="string" then return false,"Write a few words first." end
	raw=string.gsub(raw,"^%s+","");raw=string.gsub(raw,"%s+$","")
	if #raw<MIN_TEXT then return false,"Write a few words first." end
	raw=string.sub(raw,1,MAX_TEXT)
	local now=os.clock()
	local mine=sent[player] or {last=-math.huge,count=0}
	if now-mine.last<COOLDOWN then return false,("Thanks! Wait %d s before the next one."):format(math.ceil(COOLDOWN-(now-mine.last))) end
	if mine.count>=PER_VISIT then return false,"That's a lot of reports for one visit — thank you! Send more next time." end
	local text=filtered(raw,player.UserId)
	if not text then return false,"Couldn't check the text right now. Try again in a moment." end
	mine.last=now;mine.count+=1;sent[player]=mine
	local context={}
	if typeof(payload.context)=="table" then
		for k,limit in CONTEXT do
			local v=clean(payload.context[k],limit)
			if v then context[k]=v end
		end
	end
	local time=os.time()
	local build="?"
	pcall(function() build=string.sub(game:GetService("ReplicatedStorage").NinjaDuel.BuildFingerprint.Value,1,12) end)
	local report={
		id=("%d_%d_%s"):format(time,player.UserId,string.sub(HttpService:GenerateGUID(false),1,6)),
		kind=kind,text=text,time=time,
		userId=player.UserId,player=player.Name,
		context=context,build=build,placeVersion=game.PlaceVersion,
		studio=RunService:IsStudio(),
	}
	local kept=keep(report)
	local posted=toDiscord(report)
	if not kept and not posted then
		mine.last=-math.huge;mine.count-=1
		return false,"Couldn't send it right now. Try again in a moment."
	end
	return true,"Sent — thank you! We read every report."
end

-- The newest reports (Studio reader).
function Feedback.list(count)
	count=math.clamp(tonumber(count) or 20,1,100)
	local store=DataStoreService:GetDataStore(STORE)
	local index=DataStoreService:GetOrderedDataStore(INDEX)
	local out={}
	local ok,err=pcall(function()
		local page=index:GetSortedAsync(false,count):GetCurrentPage()
		for _,entry in page do
			local report=store:GetAsync(entry.key)
			if report then table.insert(out,report) end
		end
	end)
	if not ok then return {error=tostring(err)} end
	return out
end

function Feedback.start(shared)
	local remote=Instance.new("RemoteFunction");remote.Name="Feedback";remote.Parent=shared
	remote.OnServerInvoke=function(player,payload)
		local ok,a,b=pcall(Feedback.submit,player,payload)
		if not ok then warn("[NinjaDuel] feedback: "..tostring(a));return false,"Something went wrong. Try again." end
		return a,b
	end
	Players.PlayerRemoving:Connect(function(player) sent[player]=nil end)
	if RunService:IsStudio() then
		local reader=Instance.new("BindableFunction");reader.Name="NinjaDuelFeedback"
		reader.OnInvoke=function(action,arg)
			if action=="list" then return Feedback.list(arg) end
			if action=="webhook" then return webhookUrl()~=nil end
			return nil
		end
		reader.Parent=game:GetService("ServerStorage")
	end
end
return Feedback
