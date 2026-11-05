-- Players online and challenges between them (user 04/11: « rentrer dans le
-- jeu, voir s'il y a des joueurs connectés et pouvoir lancer un match, que ça
-- envoie une notification à l'autre, l'autre il accepte ou non, et ça fait un
-- match », without typing a code). Every server of the game:
--  * Presence: publishes its players (name, fighter, state, do-not-disturb)
--    in a shared MemoryStore sorted map, refreshed every Tune.Publish s; an
--    entry nobody refreshes expires by itself (Tune.Life). It reads the map
--    back every Tune.Read s: that is the list a player challenges from.
--  * Challenges: the challenger's server sends the invitation to the server
--    the other player is on (MessagingService, one topic, each server keeps
--    what is addressed to its own players). Accepted, both go to a reserved
--    server (TeleportService), whose record (MemoryStore hash map, keyed by
--    its PrivateServerId) says which two players are expected and with which
--    fighters: the record lives on the servers, never in the client's
--    teleport data. Two players on the same server skip the teleport.
--  * Duel server: the two expected players arrive and are paired on the
--    online 1v1 that exists (Server/Online: pick, rounds, rematch); anyone
--    else, a no-show past Tune.Arrival, or a player going back to the roster
--    is sent home (a public server).
-- The client only ever sends ids and booleans (Shared/LobbyProtocol); every
-- invitation, answer and destination is decided here. Roblox services are
-- injected (Lobby.new(matches, services)) so the specs run two servers in one
-- process on fakes.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Protocol=require(Shared.LobbyProtocol)
local BetaRoster=require(Shared.BetaRoster)
local Lobby={};Lobby.__index=Lobby
Lobby.Tune=Protocol.Tune

-- The real services (a server in Studio without API access, or a test, may
-- lack some of them: each feature degrades to this server alone).
function Lobby.defaultServices()
	local svc={}
	pcall(function() svc.store=game:GetService("MemoryStoreService") end)
	pcall(function() svc.messaging=game:GetService("MessagingService") end)
	pcall(function() svc.teleport=game:GetService("TeleportService") end)
	svc.players=game:GetService("Players")
	svc.jobId=game.JobId
	svc.placeId=game.PlaceId
	svc.privateServerId=game.PrivateServerId
	svc.privateServerOwnerId=game.PrivateServerOwnerId
	svc.now=function() return DateTime.now().UnixTimestampMillis/1000 end
	svc.spawn=function(fn,...) task.spawn(fn,...) end
	svc.guid=function() return game:GetService("HttpService"):GenerateGUID(false) end
	svc.teleportOptions=function(code)
		local options=Instance.new("TeleportOptions")
		if code then options.ReservedServerAccessCode=code end
		return options
	end
	svc.friends=function(userId)
		local set={}
		local ok,pages=pcall(function() return game:GetService("Players"):GetFriendsAsync(userId) end)
		if not ok or not pages then return set end
		for _=1,10 do
			for _,friend in pages:GetCurrentPage() do set[friend.Id]=true end
			if pages.IsFinished then break end
			if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
		end
		return set
	end
	return svc
end

function Lobby.new(matches,services)
	local svc=services or Lobby.defaultServices()
	local self=setmetatable({matches=matches,svc=svc,players={},directory={},outgoing={},incoming={},
		nextPublish=0,nextRead=0,readAt=-math.huge,homing={}},Lobby)
	self.remote=svc.remote
	if not self.remote then
		local remote=Shared:FindFirstChild("Lobby") or Instance.new("RemoteEvent")
		remote.Name="Lobby";remote.Parent=Shared
		self.remote=remote
	end
	if self.remote.OnServerEvent then
		self.remote.OnServerEvent:Connect(function(player,payload) self:request(player,payload) end)
	end
	-- (Audit 04/11) a teleport refused after it started: back to the roster.
	pcall(function()
		if svc.teleport and svc.teleport.TeleportInitFailed then
			svc.teleport.TeleportInitFailed:Connect(function(player)
				self.homing[player.UserId]=nil
				local s=matches.sessions[player]
				if s and s.online and s.online.kind=="travel" then
					s.online=nil
					matches:selection(player)
					local p=self.players[player.UserId]
					if p then self:status(p,"THE DUEL COULD NOT START — TRY AGAIN","bad") end
				end
			end)
		end
	end)
	pcall(function()
		if svc.store then
			self.presence=svc.store:GetSortedMap(Protocol.Tune.PresenceMap)
			self.duelRecords=svc.store:GetHashMap(Protocol.Tune.DuelMap)
		end
	end)
	if svc.messaging then
		svc.spawn(function()
			local ok,err=pcall(function()
				svc.messaging:SubscribeAsync(Protocol.Tune.Topic,function(message) self:onMessage(message.Data) end)
			end)
			if not ok then warn("[NinjaDuel] Lobby: no cross-server messages ("..tostring(err)..")") end
		end)
	end
	-- A reserved server (no owner) is a duel server: it waits for the two
	-- players its record names.
	if svc.privateServerId~=nil and svc.privateServerId~="" and (svc.privateServerOwnerId or 0)==0 then
		self.duel={arrived={},seated={},startedAt=svc.now()}
		svc.spawn(function() self:loadDuel() end)
	end
	return self
end

-- ------------------------------------------------------------ players here
local function nameOf(player)
	local name=player.DisplayName
	if type(name)~="string" or name=="" then name=player.Name end
	return if type(name)=="string" and name~="" then string.sub(name,1,24) else "Ninja"
end
function Lobby:send(player,data)
	pcall(function() self.remote:FireClient(player,data) end)
end
function Lobby:track(player)
	local p={player=player,id=player.UserId,name=nameOf(player),fighter=BetaRoster[1],dnd=false,friends={},lastOp=-math.huge,
		lastChallenge=-math.huge,watching=false}
	self.players[player.UserId]=p
	self.svc.spawn(function() p.friends=self.svc.friends(player.UserId) or {} end)
	self.nextPublish=0
	if self.duel then self:arrive(player) end
	return p
end
function Lobby:untrack(player)
	local p=self.players[player.UserId]
	-- (Security review 04/11, finding 3) gone before his opponent arrived: no
	-- seat kept for him on the duel server.
	if self.duel then self.duel.arrived[player.UserId]=nil end
	self.homing[player.UserId]=nil
	if not p then return end
	self.players[player.UserId]=nil
	-- Invitations this player sent die with him; those he received are refused.
	for id,rec in table.clone(self.outgoing) do
		if rec.from==p.id then self.outgoing[id]=nil;self:deliver({k="drop",id=id,to=rec.to,toJob=rec.toJob}) end
	end
	for id,rec in table.clone(self.incoming) do
		if rec.to==p.id then self.incoming[id]=nil;self:deliver({k="no",id=id,to=rec.from,toJob=rec.fromJob,reason="gone",name=p.name}) end
	end
	if self.presence then
		local key=tostring(p.id)
		self.svc.spawn(function() pcall(function() self.presence:RemoveAsync(key) end) end)
	end
end
-- What the others see of a player here: free on the roster, training against
-- the AI (still challengeable: accepting ends the AI duel), or in a duel.
function Lobby:stateOf(p)
	if self.duel then return "duel" end
	local s=self.matches.sessions[p.player]
	if not s then return "free" end
	if s.online and (s.online.kind=="duel" or s.online.kind=="travel") then return "duel" end
	if s.online then return "queue" end
	if s.cup then return "cup" end
	if s.phase=="Duel" or s.phase=="Result" then return "training" end
	return "free"
end
function Lobby.challengeable(state) return state=="free" or state=="training" or state=="queue" or state=="cup" end

-- ------------------------------------------------------------ presence
function Lobby:publish(now)
	if not self.presence then return end
	local job=self.svc.jobId
	for _,p in self.players do
		local value={n=p.name,f=p.fighter,s=self:stateOf(p),d=p.dnd,j=job,t=now}
		local key=tostring(p.id)
		self.svc.spawn(function() pcall(function() self.presence:SetAsync(key,value,Protocol.Tune.Life) end) end)
	end
end
function Lobby:read(now)
	if not self.presence then return end
	self.svc.spawn(function()
		local ok,items=pcall(function() return self.presence:GetRangeAsync(Enum.SortDirection.Ascending,Protocol.Tune.Page) end)
		if not ok or type(items)~="table" then return end
		local directory={}
		for _,item in items do
			local id=tonumber(item.key)
			local v=item.value
			if id and type(v)=="table" and type(v.n)=="string" and type(v.j)=="string" and type(v.t)=="number" and now-v.t<=Protocol.Tune.Life then
				directory[id]={id=id,name=string.sub(v.n,1,24),fighter=if type(v.f)=="string" and table.find(BetaRoster,v.f) then v.f else nil,
					state=if type(v.s)=="string" then v.s else "free",dnd=v.d==true,job=v.j}
			end
		end
		self.directory=directory;self.readAt=now
		for _,p in self.players do if p.watching then self:list(p) end end
	end)
end
-- Everyone a player can see: the servers' map plus this server's own players
-- (always current), without himself; friends first, then who is free.
function Lobby:entries(viewer)
	local seen={}
	local out={}
	local job=self.svc.jobId
	for id,p in self.players do
		seen[id]=true
		if id~=viewer.id then
			table.insert(out,{id=id,name=p.name,fighter=p.fighter,state=self:stateOf(p),dnd=p.dnd,here=true,friend=viewer.friends[id]==true})
		end
	end
	for id,e in self.directory do
		if not seen[id] and id~=viewer.id and e.job~=job then
			table.insert(out,{id=id,name=e.name,fighter=e.fighter,state=e.state,dnd=e.dnd,here=false,friend=viewer.friends[id]==true})
		end
	end
	table.sort(out,function(a,b)
		if a.friend~=b.friend then return a.friend end
		local fa,fb=Lobby.challengeable(a.state) and not a.dnd,Lobby.challengeable(b.state) and not b.dnd
		if fa~=fb then return fa end
		return string.lower(a.name)<string.lower(b.name)
	end)
	while #out>Protocol.Tune.ListMax do table.remove(out) end
	return out
end
function Lobby:list(p)
	local pending={}
	for id,rec in self.outgoing do if rec.from==p.id then pending[rec.to]=id end end
	local players=self:entries(p)
	for _,e in players do e.pending=pending[e.id]~=nil end
	self:send(p.player,{kind="list",players=players,dnd=p.dnd,duelServer=self.duel~=nil})
end
-- Where a player is: this server (his record here) or another one (the map).
function Lobby:locate(id)
	local p=self.players[id]
	if p then return {id=id,name=p.name,state=self:stateOf(p),dnd=p.dnd,job=self.svc.jobId,here=true} end
	local e=self.directory[id]
	if e then return {id=id,name=e.name,state=e.state,dnd=e.dnd,job=e.job,here=false} end
	return nil
end

-- ------------------------------------------------------------ messages
-- To the server a record names: this one (handled at once) or another one.
function Lobby:deliver(msg)
	if msg.toJob==self.svc.jobId or msg.toJob==nil and self.players[msg.to] then return self:onMessage(msg) end
	if not self.svc.messaging then return end
	self.svc.spawn(function() pcall(function() self.svc.messaging:PublishAsync(Protocol.Tune.Topic,msg) end) end)
end
function Lobby:onMessage(msg)
	if type(msg)~="table" or type(msg.k)~="string" or type(msg.to)~="number" then return end
	local p=self.players[msg.to]
	if not p then return end
	if msg.k=="ask" then return self:receive(p,msg) end
	if msg.k=="no" then return self:refused(p,msg) end
	if msg.k=="yes" then return self:accepted(p,msg) end
	if msg.k=="go" then return self:depart(p,msg.code,msg.name) end
	if msg.k=="drop" then
		if self.incoming[msg.id] then self.incoming[msg.id]=nil;self:send(p.player,{kind="closed",id=msg.id,text="CHALLENGE CANCELLED"}) end
	end
end

-- ------------------------------------------------------------ challenges
function Lobby:status(p,text,tone) self:send(p.player,{kind="status",text=text,tone=tone or "info"}) end
function Lobby:outgoingOf(id)
	local n=0
	for _,rec in self.outgoing do if rec.from==id then n+=1 end end
	return n
end
function Lobby:challenge(p,to,fighter,now)
	if self.duel then return self:status(p,"BACK TO THE LOBBY FIRST","bad") end
	if to==p.id then return end
	if now-p.lastChallenge<Protocol.Tune.Gap then return self:status(p,"WAIT A MOMENT BEFORE THE NEXT CHALLENGE","bad") end
	if self:outgoingOf(p.id)>=Protocol.Tune.MaxOut then return self:status(p,"TOO MANY CHALLENGES WAITING","bad") end
	if not Lobby.challengeable(self:stateOf(p)) then return self:status(p,"FINISH YOUR DUEL FIRST","bad") end
	for _,rec in self.outgoing do if rec.from==p.id and rec.to==to then return end end
	local target=self:locate(to)
	if not target then return self:status(p,"THIS PLAYER IS NO LONGER ONLINE","bad") end
	if target.dnd then return self:status(p,string.upper(target.name).." DOES NOT WANT TO BE DISTURBED","bad") end
	if not Lobby.challengeable(target.state) then return self:status(p,string.upper(target.name).." IS IN A DUEL","bad") end
	p.lastChallenge=now
	if fighter then p.fighter=fighter end
	local rec={id=string.sub(self.svc.guid(),1,18),from=p.id,name=p.name,fighter=p.fighter,to=to,toName=target.name,
		fromJob=self.svc.jobId,toJob=target.job,expires=now+Protocol.Tune.ChallengeLife}
	self.outgoing[rec.id]=rec
	self:send(p.player,{kind="sent",id=rec.id,to=target.name,remaining=Protocol.Tune.ChallengeLife})
	self:deliver({k="ask",id=rec.id,to=to,toJob=target.job,from=p.id,name=p.name,fighter=p.fighter,fromJob=self.svc.jobId,expires=rec.expires})
	if p.watching then self:list(p) end
end
-- An invitation reaches the player it names (on this server).
function Lobby:receive(p,msg)
	local reply={k="no",id=msg.id,to=msg.from,toJob=msg.fromJob,name=p.name}
	if type(msg.id)~="string" or type(msg.from)~="number" or type(msg.name)~="string" then return end
	local count=0
	for _,rec in self.incoming do if rec.to==p.id then count+=1 end end
	if p.dnd then reply.reason="dnd";return self:deliver(reply) end
	if not Lobby.challengeable(self:stateOf(p)) or count>=Protocol.Tune.MaxIn then reply.reason="busy";return self:deliver(reply) end
	local rec={id=msg.id,from=msg.from,name=string.sub(msg.name,1,24),fighter=if type(msg.fighter)=="string" and table.find(BetaRoster,msg.fighter) then msg.fighter else nil,
		fromJob=msg.fromJob,to=p.id,expires=if type(msg.expires)=="number" then msg.expires else self.svc.now()+Protocol.Tune.ChallengeLife}
	self.incoming[rec.id]=rec
	self:send(p.player,{kind="invite",id=rec.id,from=rec.name,fromId=rec.from,fighter=rec.fighter,remaining=math.max(0,rec.expires-self.svc.now())})
end
function Lobby:answer(p,id,accept,fighter,now)
	local rec=self.incoming[id]
	if not rec or rec.to~=p.id then return end
	self.incoming[id]=nil
	self:send(p.player,{kind="closed",id=id})
	if now>rec.expires then return self:status(p,"THIS CHALLENGE HAS EXPIRED","bad") end
	if fighter then p.fighter=fighter end
	if not accept then return self:deliver({k="no",id=id,to=rec.from,toJob=rec.fromJob,reason="declined",name=p.name}) end
	if not Lobby.challengeable(self:stateOf(p)) then return self:deliver({k="no",id=id,to=rec.from,toJob=rec.fromJob,reason="busy",name=p.name}) end
	self:status(p,"ACCEPTED  •  WAITING FOR "..string.upper(rec.name))
	self:deliver({k="yes",id=id,to=rec.from,toJob=rec.fromJob,from=p.id,name=p.name,fighter=p.fighter,fromJob=self.svc.jobId})
end
local REASONS={declined="%s DECLINED",busy="%s IS BUSY",dnd="%s DOES NOT WANT TO BE DISTURBED",gone="%s LEFT",error="THE DUEL COULD NOT START — TRY AGAIN",expired="NO ANSWER FROM %s"}
function Lobby:refused(p,msg)
	local rec=self.outgoing[msg.id]
	if not rec then
		-- (the accepting side, told the duel could not start)
		if msg.reason=="error" or msg.reason=="gone" then self:status(p,string.format(REASONS[msg.reason],string.upper(tostring(msg.name or "THE PLAYER"))),"bad") end
		return
	end
	self.outgoing[msg.id]=nil
	self:status(p,string.format(REASONS[msg.reason] or REASONS.declined,string.upper(rec.toName or tostring(msg.name or "THE PLAYER"))),"bad")
	if p.watching then self:list(p) end
end
-- The challenged player said yes: the challenger's server sets the duel up.
function Lobby:accepted(p,msg)
	local rec=self.outgoing[msg.id]
	if not rec or rec.from~=p.id then return end
	self.outgoing[msg.id]=nil
	local fighter=if type(msg.fighter)=="string" and table.find(BetaRoster,msg.fighter) then msg.fighter else BetaRoster[1]
	local other=self.players[msg.from]
	if not Lobby.challengeable(self:stateOf(p)) then
		return self:deliver({k="no",id=msg.id,to=msg.from,toJob=msg.fromJob,reason="busy",name=p.name})
	end
	-- Same server: the online 1v1 at once, no teleport.
	if other then return self:pairHere(p,other,rec.fighter or p.fighter,fighter) end
	self:status(p,string.upper(rec.toName or "YOUR OPPONENT").." ACCEPTED  •  LEAVING FOR THE DUEL…")
	self.svc.spawn(function()
		local ok,code,serverId=pcall(function() return self.svc.teleport:ReserveServer(self.svc.placeId) end)
		local saved=ok and type(code)=="string" and type(serverId)=="string" and self.duelRecords~=nil and pcall(function()
			self.duelRecords:SetAsync(serverId,{a=p.id,b=msg.from,fa=rec.fighter or p.fighter,fb=fighter,id=msg.id},Protocol.Tune.DuelRecordLife)
		end)
		if not saved then
			self:status(p,REASONS.error,"bad")
			return self:deliver({k="no",id=msg.id,to=msg.from,toJob=msg.fromJob,reason="error",name=p.name})
		end
		self:deliver({k="go",id=msg.id,to=msg.from,toJob=msg.fromJob,code=code,name=p.name})
		self:depart(p,code,rec.toName)
	end)
end
-- Both players here: straight into the online pick (Server/Online).
function Lobby:pairHere(a,b,fa,fb)
	local m=self.matches
	for _,p in {a,b} do
		local s=m:session(p.player)
		if s.phase~="Selection" or s.online then m:selection(p.player) end
	end
	local sa,sb=m:session(a.player),m:session(b.player)
	m.online:pair({player=a.player,session=sa,fighter=fa},{player=b.player,session=sb,fighter=fb},"challenge")
end
function Lobby:depart(p,code,opponent)
	if type(code)~="string" or #code>200 then return end
	local s=self.matches:session(p.player)
	-- (Audit 04/11) out of an AI duel first: a travel that failed left the
	-- player in a frozen duel, every button refused.
	if s.phase~="Selection" then self.matches:selection(p.player) end
	if s.online then self.matches.online:leave(p.player,s) end
	s.online={kind="travel",at=self.svc.now()}
	self:status(p,"LEAVING FOR THE DUEL"..(if opponent then " AGAINST "..string.upper(tostring(opponent)) else "").."…")
	self:teleport(p.player,code)
end
function Lobby:teleport(player,code)
	local svc=self.svc
	if not svc.teleport then return end
	svc.spawn(function()
		for attempt=1,2 do
			local ok,err=pcall(function() svc.teleport:TeleportAsync(svc.placeId,{player},svc.teleportOptions(code)) end)
			if ok then return end
			warn("[NinjaDuel] Lobby teleport failed ("..attempt.."): "..tostring(err))
		end
		local p=self.players[player.UserId]
		local s=self.matches.sessions[player]
		if code==nil then self.homing[player.UserId]=nil end
		if s and s.online and s.online.kind=="travel" then s.online=nil end
		if p then self:status(p,REASONS.error,"bad") end
	end)
end
function Lobby:cancel(p,id)
	local rec=self.outgoing[id]
	if not rec or rec.from~=p.id then return end
	self.outgoing[id]=nil
	self:deliver({k="drop",id=id,to=rec.to,toJob=rec.toJob})
	self:status(p,"CHALLENGE CANCELLED")
	if p.watching then self:list(p) end
end

-- ------------------------------------------------------------ duel server
function Lobby:loadDuel()
	local d=self.duel
	for _=1,12 do
		local ok,rec=pcall(function() return self.duelRecords and self.duelRecords:GetAsync(self.svc.privateServerId) end)
		if ok and type(rec)=="table" and type(rec.a)=="number" and type(rec.b)=="number" then
			d.record=rec
			for id in d.arrived do self:arrive(d.arrived[id]) end
			return
		end
		task.wait(1)
	end
	d.failed=true
	for _,p in self.players do self:home(p.player,"THE DUEL COULD NOT START") end
end
function Lobby:arrive(player)
	local d=self.duel
	d.arrived[player.UserId]=player
	local rec=d.record
	if not rec then return end
	if player.UserId~=rec.a and player.UserId~=rec.b then return self:home(player,nil) end
	local a,b=d.arrived[rec.a],d.arrived[rec.b]
	if a and b and not d.paired and a.Parent and b.Parent then
		d.paired=true
		local m=self.matches
		-- (Security review 04/11, finding 3) a local duel or cup started while
		-- the record loaded is ended first (it kept sending its snapshots).
		for _,pl in {a,b} do local s=m.sessions[pl];if s and (s.combat or s.cup) then m:destroy(s);s.cup=nil;s.spectate=nil;s.autopilot=nil;s.cupPilot=nil end end
		for _,pl in {a,b} do d.seated[pl.UserId]=true end
		local fa=if type(rec.fa)=="string" and table.find(BetaRoster,rec.fa) then rec.fa else BetaRoster[1]
		local fb=if type(rec.fb)=="string" and table.find(BetaRoster,rec.fb) then rec.fb else BetaRoster[2]
		m.online:pair({player=a,session=m:session(a),fighter=fa},{player=b,session=m:session(b),fighter=fb},"challenge")
	elseif not d.paired then
		local s=self.matches:session(player)
		s.phase="Queue";s.epoch+=1
		self.matches:send(player,{phase="Queue",epoch=s.epoch,online={mode="challenge"}})
	end
end
-- Back to a public server (the roster), with a word on the way.
-- (05/11, lot 4 review) One trip at a time per player: "home" every 0.25 s
-- started a new TeleportAsync task each time. The flag drops when that
-- teleport fails (Lobby:teleport, TeleportInitFailed), when he leaves, or
-- after HOME_HOLD seconds.
local HOME_HOLD=15
function Lobby:home(player,text)
	local now=self.svc.now()
	local since=self.homing[player.UserId]
	if since and now-since<HOME_HOLD then return end
	self.homing[player.UserId]=now
	local p=self.players[player.UserId]
	if p then self:status(p,text or "BACK TO THE LOBBY…") end
	self:teleport(player,nil)
end
-- Matches:selection calls this: in a duel server the roster is the lobby.
function Lobby:onSelection(player)
	local d=self.duel
	if d and (d.seated[player.UserId] or d.failed) then self:home(player,nil) end
end

-- ------------------------------------------------------------ requests
function Lobby:request(player,payload)
	local p=self.players[player.UserId]
	if not p or type(payload)~="table" or type(payload.op)~="string" then return end
	local now=self.svc.now()
	local op=payload.op
	-- (Studio 04/11) The open list refreshes itself every second: a refresh
	-- has its own budget and never swallows the click that follows it.
	local refresh=op=="open" or op=="close" or op=="fighter"
	if refresh then
		if now-(p.lastRefresh or -math.huge)<Protocol.Tune.OpGap then return end
		p.lastRefresh=now
	else
		if now-p.lastOp<Protocol.Tune.OpGap then return end
		p.lastOp=now
	end
	local fighter=if type(payload.fighter)=="string" and table.find(BetaRoster,payload.fighter) then payload.fighter else nil
	if op=="open" then p.watching=true;self:list(p)
	elseif op=="close" then p.watching=false
	elseif op=="fighter" then if fighter then p.fighter=fighter end
	elseif op=="dnd" then
		-- (Security review 04/11, finding 2) a flip publishes within 2 s, not
		-- at once: toggled every 0.25 s it rewrote every presence entry 4 times
		-- a second, on a MemoryStore quota shared by the whole experience.
		if type(payload.on)=="boolean" then p.dnd=payload.on;self.nextPublish=math.min(self.nextPublish,now+2);self:send(p.player,{kind="dnd",on=p.dnd}) end
	elseif op=="challenge" then
		if type(payload.to)=="number" and payload.to==payload.to and payload.to>0 then self:challenge(p,math.floor(payload.to),fighter,now) end
	elseif op=="answer" then
		if type(payload.id)=="string" and #payload.id<=40 and type(payload.accept)=="boolean" then self:answer(p,payload.id,payload.accept,fighter,now) end
	elseif op=="cancel" then
		if type(payload.id)=="string" and #payload.id<=40 then self:cancel(p,payload.id) end
	elseif op=="home" then
		if self.duel then self:home(player,nil) end
	end
end

function Lobby:update(now)
	now=self.svc.now()
	if now>=self.nextPublish then self.nextPublish=now+Protocol.Tune.Publish;self:publish(now) end
	if now>=self.nextRead then self.nextRead=now+Protocol.Tune.Read;self:read(now) end
	for id,rec in table.clone(self.outgoing) do
		if now>rec.expires+2 then
			self.outgoing[id]=nil
			local p=self.players[rec.from]
			if p then self:status(p,string.format(REASONS.expired,string.upper(rec.toName or "THE PLAYER")),"bad");if p.watching then self:list(p) end end
		end
	end
	for id,rec in table.clone(self.incoming) do
		if now>rec.expires then
			self.incoming[id]=nil
			local p=self.players[rec.to]
			if p then self:send(p.player,{kind="closed",id=id}) end
		end
	end
	-- (Audit 04/11) a teleport that never happened (TeleportInitFailed, or no
	-- answer at all): the player gets his roster back.
	for _,p in self.players do
		local s=self.matches.sessions[p.player]
		if s and s.online and s.online.kind=="travel" and now-(s.online.at or now)>25 then
			s.online=nil
			self.matches:selection(p.player)
			self:status(p,REASONS.error,"bad")
		end
	end
	local d=self.duel
	if d and d.record and not d.paired and now-d.startedAt>Protocol.Tune.Arrival then
		d.failed=true
		for _,p in self.players do self:home(p.player,"YOUR OPPONENT DID NOT ARRIVE") end
		d.startedAt=math.huge
	end
end
return Lobby
