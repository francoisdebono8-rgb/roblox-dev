-- The week's exam on the server (19/11, plan « vague 2 », DEV 5; the rules
-- and the calendar are Shared/Exam).
--  * An attempt: a tournament started while the window is open (Server/
--    Tournament asks WeeklyExam.attempt()). Each of his own matches adds to
--    it (WeeklyExam.match); when the tournament ends, its score goes to his
--    profile (the week's best, Progression.examResult) and, when it is his
--    best, to the week's leaderboard: an OrderedDataStore per week
--    (NinjaDuelExam_<key>), the same on every server.
--  * The week closed: the first server that sees it reads the three best,
--    writes them once in the cliff's store (week_v1) and puts them on the
--    cliff (Server/ChampionCliff.week); the other servers read week_v1.
--  * Titles: every player's NinjaTitle attribute (EXAM PASSED, TOP 3 OF THE
--    WEEK), read by Client/HubPlayers over his head in Konoha.
-- Studio only: workspace attribute NinjaExamOpen=true opens the window at
-- once (to try it before Friday); a live server never reads it.
-- Roblox services are injected (WeeklyExam.new(svc)) so the suite runs it on
-- fakes.
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Exam=require(Shared.Exam)

local W={}
W.__index=W
W.STORE="NinjaDuelExam"
W.CLIFF_STORE="NinjaDuelChampions"
W.WEEK_KEY="week_v1"
W.CLOSE_EVERY=300
W.TITLE_EVERY=30

function W.defaultServices()
	local svc={}
	local ds=nil
	pcall(function() ds=game:GetService("DataStoreService") end)
	svc.ordered=function(key)
		local store=nil
		if ds and game.PlaceId~=0 then pcall(function() store=ds:GetOrderedDataStore(W.STORE.."_"..key) end) end
		return store
	end
	if ds and game.PlaceId~=0 then pcall(function() svc.store=ds:GetDataStore(W.CLIFF_STORE) end) end
	svc.now=function() return os.time() end
	svc.name=function(id)
		local name=nil
		pcall(function() name=Players:GetNameFromUserIdAsync(id) end)
		return name or ""
	end
	svc.players=function() return Players:GetPlayers() end
	svc.forced=function()
		local studio=false
		pcall(function() studio=game:GetService("RunService"):IsStudio() end)
		return studio and workspace:GetAttribute("NinjaExamOpen")==true
	end
	svc.progression=function() return require(script.Parent.Progression) end
	svc.cliff=function(top) pcall(function() require(script.Parent.ChampionCliff).week(top) end) end
	svc.spawn=function(fn,...) task.spawn(fn,...) end
	svc.every=function(seconds,fn) task.spawn(function() while true do task.wait(seconds);pcall(fn) end end) end
	return svc
end

function W.new(svc)
	return setmetatable({svc=svc or W.defaultServices(),top={},week=nil},W)
end

-- ------------------------------------------------------------ attempts
-- The window an attempt started now counts for, or nil (closed).
function W:window()
	local now=self.svc.now()
	if self.svc.forced and self.svc.forced() then
		local w=Exam.current(now)
		return {key=w.key,opens=now,closes=math.max(w.closes,now+3600)}
	end
	return Exam.openAt(now)
end
-- A new attempt, or nil when no exam is open.
function W:attempt()
	if not Exam.config().Enabled then return nil end
	local w=self:window()
	if not w then return nil end
	return {key=w.key,matches=0,lost=0,hp=0,seconds=0,name=Exam.config().Name}
end
-- One of his own matches in the attempt: won, rounds lost, health kept (0 to
-- 1), seconds fought.
function W.match(a,won,lost,health,seconds)
	if type(a)~="table" or a.done then return end
	a.lost+=math.max(0,math.floor(lost or 0))
	a.seconds+=math.max(0,seconds or 0)
	if won then
		a.matches+=1
		a.hp+=math.clamp(math.floor((health or 0)*100+.5),0,100)
	end
end
-- The tournament is over: his score, kept in his profile and, when it is his
-- week's best, on the week's leaderboard. What the champion card shows:
-- {name, score, best, improved, passed}.
function W:submit(player,a,passed)
	if type(a)~="table" or a.done then return nil end
	a.done=true
	local score=Exam.score(a)
	local P=self.svc.progression()
	local result=P.examResult(player,a.key,score,passed)
	if not result then return {name=a.name,score=score,best=score,improved=false,passed=passed==true,saved=false} end
	if result.improved then
		local store=self.svc.ordered(a.key)
		local id=tostring(player.UserId)
		if store then
			self.svc.spawn(function()
				pcall(function() store:UpdateAsync(id,function(old) return math.max(tonumber(old) or 0,score) end) end)
			end)
		end
	end
	self:retitle(player)
	return {name=a.name,score=score,best=result.best,improved=result.improved,passed=result.passed,saved=true}
end

-- ------------------------------------------------------------ the titles
function W:retitle(player)
	local P=self.svc.progression()
	local record=P.examRecord and P.examRecord(player) or nil
	local title=Exam.title(record,self.top,player.UserId,self.svc.now())
	-- (22/11) the exam's title under his name unless he chose one (Progression.showTitle)
	if player:GetAttribute("NinjaExamTitle")~=title then player:SetAttribute("NinjaExamTitle",title) end
	if not (P.showTitle and P.showTitle(player)) and player:GetAttribute("NinjaTitle")~=title then player:SetAttribute("NinjaTitle",title) end
	return title
end
function W:retitleAll()
	for _,player in self.svc.players() do pcall(function() self:retitle(player) end) end
end

-- ------------------------------------------------------------ the week closed
-- {{id,name,score}} from a stored record, checked.
function W.clean(list)
	local out={}
	if type(list)~="table" then return out end
	for _,e in list do
		if #out>=Exam.TOP_COUNT then break end
		if type(e)=="table" and type(e.id)=="number" and e.id>0 and e.id==math.floor(e.id) then
			table.insert(out,{id=e.id,name=string.sub(tostring(e.name or ""),1,24),score=tonumber(e.score) or 0})
		end
	end
	return out
end
-- The last closed exam's best three: read once per week (the store's
-- week_v1, else the week's leaderboard, then written for the others).
function W:close()
	if not Exam.config().Enabled then return end
	local last=Exam.lastClosed(self.svc.now())
	if self.week==last.key then return end
	local store=self.svc.store
	if store then
		local ok,rec=pcall(function() return store:GetAsync(W.WEEK_KEY) end)
		if ok and type(rec)=="table" and rec.week==last.key then
			self.week=last.key;self.top=W.clean(rec.top)
			self:retitleAll()
			return
		end
	end
	local top={}
	local board=self.svc.ordered(last.key)
	if board then
		local ok,page=pcall(function() return board:GetSortedAsync(false,Exam.TOP_COUNT):GetCurrentPage() end)
		if not ok then return end -- try again at the next turn
		for _,row in page or {} do
			local id=tonumber(row.key)
			if id and id>0 then table.insert(top,{id=id,name=self.svc.name(id),score=tonumber(row.value) or 0}) end
		end
	end
	self.week=last.key;self.top=top
	if store then
		pcall(function() store:UpdateAsync(W.WEEK_KEY,function(old)
			if type(old)=="table" and type(old.week)=="string" and old.week>=last.key then return nil end
			return {week=last.key,top=top}
		end) end)
	end
	-- nobody passed it: the cliff keeps last week's faces
	if #top>0 then self.svc.cliff(top) end
	self:retitleAll()
end

function W:run()
	self.svc.spawn(function() pcall(function() self:close() end) end)
	if self.svc.every then
		self.svc.every(W.CLOSE_EVERY,function() self:close() end)
		self.svc.every(W.TITLE_EVERY,function() self:retitleAll() end)
	end
	return self
end

-- ------------------------------------------------------------ the game's one
W.current=nil
-- Main: the one that runs (the week closed, the titles every 30 s).
function W.begin()
	if not W.current then W.current=W.new() end
	if not W.current.running then W.current.running=true;W.current:run() end
	return W.current
end
-- Server/Tournament: the running one, else a passive one (no loop started
-- from a tournament: the suites, a server where the exam is off).
function W.get()
	if not W.current then W.current=W.new() end
	return W.current
end

return W
