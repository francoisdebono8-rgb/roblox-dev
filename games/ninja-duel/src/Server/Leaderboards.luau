-- The leaderboards (20/11, DEC-043, étape 1: « il y a un classement […] et
-- faire plusieurs classements »). Every server writes to the same
-- OrderedDataStores and reads their top 10 every minute:
--   Rating     the ranked rating (Shared/Ranked), all time
--   WeekWins   duels won against players this week (Monday to Sunday, UTC)
--   Merit      merit points (Shared/Merit), all time
--   Streak     days in a row (Shared/DailyQuests), now
--   Exam       the week's exam (Server/WeeklyExam writes it), the latest one
--   Rooftops   (21/11, DEC-047) the rooftop race's best time (Shared/Solo), in
--              hundredths, the FASTEST first (`ascending`); each row also
--              carries `text`, the time as the clock shows it ("0:42.31")
-- What clients read: ReplicatedStorage.NinjaDuelBoards, one StringValue per
-- board whose Value is JSON {id, title, rows={{rank,id,name,value}}, at}.
-- The DESIGN draws them (the boards in Konoha, a page on screen).
-- Where DataStores cannot run (a place file in Studio), every board lives on
-- this server alone, from what its players did: still something to see.
-- Roblox services are injected (Leaderboards.new(svc)) for the suite.
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Exam=require(Shared.Exam)

local L={}
L.__index=L
L.TOP=10
L.REFRESH=60
L.Boards={
	{id="Rating",title="RANKED",store="NinjaDuelRating"},
	{id="WeekWins",title="WINS THIS WEEK",store="NinjaDuelWeekWins",weekly=true},
	{id="Merit",title="MERIT",store="NinjaDuelMerit"},
	{id="Streak",title="DAYS IN A ROW",store="NinjaDuelStreak"},
	{id="Exam",title="THE WEEK'S EXAM",store="NinjaDuelExam",exam=true,readOnly=true},
	{id="Rooftops",title="ROOFTOP RACE",store="NinjaDuelRooftops",ascending=true,time=true},
}
L.ById={}
for _,b in L.Boards do L.ById[b.id]=b end

-- The week's key: its Monday (UTC), "YYYY-MM-DD".
function L.weekKey(t)
	local day=math.floor(t/86400)
	return Exam.key(day-((Exam.weekday(day)+6)%7))
end
-- The store's name of a board at time t.
function L.storeName(b,t)
	if b.weekly then return b.store.."_"..L.weekKey(t) end
	if b.exam then return b.store.."_"..Exam.latest(t).key end
	return b.store
end

function L.defaultServices()
	local svc={}
	local ds=nil
	if game.PlaceId~=0 then pcall(function() ds=game:GetService("DataStoreService") end) end
	svc.ordered=function(name)
		local store=nil
		if ds then pcall(function() store=ds:GetOrderedDataStore(name) end) end
		return store
	end
	svc.now=function() return os.time() end
	svc.name=function(id)
		local p=Players:GetPlayerByUserId(id)
		if p then return p.Name end
		local name=nil
		pcall(function() name=Players:GetNameFromUserIdAsync(id) end)
		return name or ""
	end
	svc.publish=function(id,json)
		local RS=game:GetService("ReplicatedStorage")
		local folder=RS:FindFirstChild("NinjaDuelBoards")
		if not folder then folder=Instance.new("Folder");folder.Name="NinjaDuelBoards";folder.Parent=RS end
		local value=folder:FindFirstChild(id)
		if not value then value=Instance.new("StringValue");value.Name=id;value.Parent=folder end
		value.Value=json
	end
	svc.encode=function(data) return game:GetService("HttpService"):JSONEncode(data) end
	svc.spawn=function(fn,...) task.spawn(fn,...) end
	svc.every=function(seconds,fn) task.spawn(function() while true do pcall(fn);task.wait(seconds) end end) end
	return svc
end

function L.new(svc)
	return setmetatable({svc=svc or L.defaultServices(),here={},names={},tops={}},L)
end

local function remember(self,b,player,value,how)
	local key=L.storeName(b,self.svc.now())
	self.here[key]=self.here[key] or {}
	local row=self.here[key][player.UserId]
	local old=row and row.value or 0
	local new=if how=="add" then old+value else value
	self.here[key][player.UserId]={name=player.Name,value=new}
	self.names[player.UserId]=player.Name
	return key,new
end
-- A board's value for him (set: his current value).
function L:submit(id,player,value)
	local b=L.ById[id]
	if not b or b.readOnly or type(value)~="number" or player.UserId<=0 then return end
	local key,new=remember(self,b,player,math.floor(value),"set")
	local store=self.svc.ordered(key)
	if store then self.svc.spawn(function() pcall(function() store:SetAsync(tostring(player.UserId),new) end) end) end
end
-- Adds to his value (WeekWins).
function L:add(id,player,amount)
	local b=L.ById[id]
	if not b or b.readOnly or type(amount)~="number" or player.UserId<=0 then return end
	local key=remember(self,b,player,math.floor(amount),"add")
	local store=self.svc.ordered(key)
	if store then
		self.svc.spawn(function()
			pcall(function() store:UpdateAsync(tostring(player.UserId),function(old) return (tonumber(old) or 0)+math.floor(amount) end) end)
		end)
	end
end

-- The top 10 of a board: from its store, else from this server's players.
function L:top(id)
	local b=L.ById[id]
	local key=L.storeName(b,self.svc.now())
	local rows={}
	local store=self.svc.ordered(key)
	local fromStore=false
	if store then
		local ok,page=pcall(function() return store:GetSortedAsync(b.ascending==true,L.TOP):GetCurrentPage() end)
		if ok and page then
			fromStore=true
			for _,row in page do
				local id_=tonumber(row.key)
				if id_ then
					local name=self.names[id_] or self.svc.name(id_)
					self.names[id_]=name
					table.insert(rows,{id=id_,name=name,value=tonumber(row.value) or 0})
				end
			end
		end
	end
	if not fromStore then
		for userId,row in self.here[key] or {} do table.insert(rows,{id=userId,name=row.name,value=row.value}) end
		table.sort(rows,function(a,c) if a.value~=c.value then return if b.ascending then a.value<c.value else a.value>c.value end return a.id<c.id end)
		while #rows>L.TOP do table.remove(rows) end
	end
	for i,row in rows do
		row.rank=i
		if b.time then row.text=require(Shared.Solo).clock(row.value) end
	end
	return {id=b.id,title=b.title,rows=rows,at=self.svc.now()}
end
function L:refresh()
	for _,b in L.Boards do
		local ok,top=pcall(function() return self:top(b.id) end)
		if ok and top then
			self.tops[b.id]=top
			pcall(function() self.svc.publish(b.id,self.svc.encode(top)) end)
		end
	end
end

function L:run()
	if self.svc.every then self.svc.every(L.REFRESH,function() self:refresh() end) end
	return self
end
L.current=nil
function L.begin()
	if not L.current then L.current=L.new():run() end
	return L.current
end

return L
