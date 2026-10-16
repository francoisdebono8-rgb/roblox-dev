-- Online 1v1 (NET-001): casual queue, private duel codes, a short fighter
-- pick, then a duel between two players on the same server-authoritative
-- Combat as the local duel, with the same rounds, KO beat and result.
--  * Each player's requests drive only their own actor, through the local
--    duel's validation, per-player rate limit and anti-cheat (Matches:act).
--  * No AI is ever created or updated for an online duel.
--  * Every viewer receives the local-duel snapshot from their own side:
--    `human` is their actor and `bot` the opponent, whose model in the shared
--    duel folder is named `bot.id`; `winner` and `wins` are mapped the same way.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local Protocol=require(Shared.OnlineProtocol)
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AntiCheat=require(script.Parent.VelmoraAntiCheat)
local Online={};Online.__index=Online
function Online.new(matches)
	return setmetatable({matches=matches,queue={},codes={},duels={},freeLanes={},rng=Random.new()},Online)
end
local function fighter(id)
	return if type(id)=="string" and #id<=24 and Fighters[id]~=nil then id else nil
end
local function nameOf(player)
	local name=player.DisplayName
	if type(name)~="string" or name=="" then name=player.Name end
	return if type(name)=="string" and name~="" then name else "Opponent"
end
-- A typed code: spaces dropped, case folded, exact length and alphabet.
local function cleanCode(code)
	if type(code)~="string" or #code>16 then return nil end
	code=string.upper((string.gsub(code,"%s","")))
	if #code~=Protocol.CodeLength or string.match(code,"^[A-Z0-9]+$")==nil then return nil end
	return code
end
Online.cleanCode=cleanCode
function Online:newCode()
	local alphabet=Protocol.CodeAlphabet
	for _=1,32 do
		local chars={}
		for i=1,Protocol.CodeLength do
			local k=self.rng:NextInteger(1,#alphabet)
			chars[i]=string.sub(alphabet,k,k)
		end
		local code=table.concat(chars)
		if not self.codes[code] then return code end
	end
	return nil
end
-- Online duels draw lanes from the local sessions' counter (never the same
-- stage position) and hand them back when they are disposed.
function Online:claimLane()
	local lane=table.remove(self.freeLanes)
	if lane then return lane end
	self.matches.nextLane+=1
	return self.matches.nextLane
end
function Online:notice(player,s,message)
	self.matches:send(player,{phase="Selection",epoch=s.epoch,notice=message})
end
function Online:waiting(s)
	local o=s.online
	return {phase="Queue",epoch=s.epoch,online={mode=if o.kind=="host" then "private" else "casual",code=o.entry.code}}
end
-- From the roster: join the casual queue, host a private code or join one.
function Online:enter(player,s,action,payload)
	local id=fighter(payload.player)
	if not id then return self:notice(player,s,"CHOOSE A FIGHTER FIRST") end
	local entry={player=player,session=s,fighter=id}
	if action=="Join" then
		local code=cleanCode(payload.code)
		local host=code and self.codes[code]
		if not host or host.player==player then return self:notice(player,s,"NO PRIVATE DUEL WITH THIS CODE") end
		self.codes[code]=nil;host.session.online=nil
		self:pair(host,entry,"private",code)
		return
	end
	if action=="Host" then
		entry.code=self:newCode()
		if not entry.code then return self:notice(player,s,"NO FREE CODE — TRY AGAIN") end
		self.codes[entry.code]=entry
		s.online={kind="host",entry=entry}
	else
		table.insert(self.queue,entry)
		s.online={kind="queue",entry=entry}
	end
	s.phase="Queue";s.epoch+=1
	self.matches:send(player,self:waiting(s))
	-- Casual queue: first come, first paired.
	while #self.queue>=2 do
		local first=table.remove(self.queue,1);local second=table.remove(self.queue,1)
		first.session.online=nil;second.session.online=nil
		self:pair(first,second,"casual")
	end
end
-- Two players are paired: the duel exists from here, starting with the pick.
-- Its epoch starts above both players' own, so no client drops its packets.
function Online:pair(first,second,mode,code)
	local d={online=true,mode=mode,code=code,phase="Pick",epoch=0,seats={},lane=self:claimLane(),
		pickUntil=workspace:GetServerTimeNow()+Protocol.PickTime}
	d.origin=self.matches.laneOrigin(d.lane)
	for index,entry in {first,second} do
		local seat={index=index,player=entry.player,session=entry.session,fighter=entry.fighter,name=nameOf(entry.player),
			present=true,ready=false,rematch=false}
		d.seats[index]=seat
		entry.session.online={kind="duel",duel=d,seat=seat}
		d.epoch=math.max(d.epoch,entry.session.epoch)
	end
	d.epoch+=1
	self.duels[d]=true
	self:broadcast(d)
	return d
end
-- Every present player gets the duel from their own side; their session
-- follows the duel's phase and epoch, which their requests must carry back.
function Online:broadcast(d)
	for _,seat in d.seats do
		if seat.present then
			seat.session.phase=d.phase;seat.session.epoch=d.epoch
			self.matches:send(seat.player,self:packet(d,seat))
		end
	end
end
function Online:packet(d,seat)
	local other=d.seats[3-seat.index]
	local info={mode=d.mode,code=d.code,opponent=other.name,opponentLeft=not other.present,forfeit=d.forfeit==true,
		me=seat.fighter,them=other.fighter,ready=seat.ready,theirReady=other.ready,rematch=seat.rematch,theirRematch=other.rematch}
	if d.phase=="Pick" then
		info.remaining=math.max(0,d.pickUntil-workspace:GetServerTimeNow())
		return {phase="Pick",epoch=d.epoch,online=info}
	end
	local view=self.matches:view(d,seat,seat.actor,other.actor)
	view.online=info
	return view
end
function Online:refresh(player,s)
	local o=s.online
	if o.kind=="duel" then self.matches:send(player,self:packet(o.duel,o.seat))
	else self.matches:send(player,self:waiting(s)) end
end
function Online:pick(d,seat,action,payload)
	if seat.ready then return end
	if action=="Pick" then
		local id=fighter(payload.player)
		if id and id~=seat.fighter then seat.fighter=id;self:broadcast(d) end
	elseif action=="Confirm" then
		seat.ready=true
		if d.seats[1].ready and d.seats[2].ready then self:fight(d) else self:broadcast(d) end
	end
end
-- The fight: a fresh stage in the duel's lane, one actor per player and the
-- local duel's tournament rounds. A rematch rebuilds it the same way.
function Online:fight(d)
	local m=self.matches
	self:teardown(d)
	d.phase="Duel";d.winner=nil;d.forfeit=nil;d.finishing=false;d.matchPoint=false
	d.folder=Instance.new("Folder");d.folder.Name="Online_"..d.lane;d.folder.Parent=m.folder
	d.effects=Instance.new("Folder");d.effects.Name="Effects";d.effects.Parent=d.folder
	World.arena(d.folder,d.origin)
	local c=Combat.new(d);c.now=workspace:GetServerTimeNow();d.combat=c
	for index,seat in d.seats do
		local side=if index==1 then 1 else -1
		local from=d.origin+Vector3.new(0,3,side*Config.StartDistance)
		local id="Duelist"..index
		local model,hum,root,joints=World.rig(d.folder,Fighters[seat.fighter],CFrame.lookAt(from,d.origin+Vector3.new(0,3,-side*Config.StartDistance)),id)
		seat.actor=c:add(id,model,hum,root,joints,seat.fighter)
		-- Two players: both start locked on, as the local duel's fighters do.
		seat.actor.locked=true
		seat.ready=false;seat.rematch=false;seat.sentImpact=nil;seat.impactEpoch=nil
	end
	local a,b=d.seats[1].actor,d.seats[2].actor
	a.target=b;b.target=a
	for _,seat in d.seats do
		if seat.present then
			seat.player.Character=seat.actor.model
			-- The body stays server-simulated even as the player's character.
			pcall(function() seat.actor.root:SetNetworkOwner(nil) end)
		end
	end
	d.round=1;d.wins={[a.id]=0,[b.id]=0};d.roundsToWin=Config.RoundsToWin
	d.introUntil=c.now+2.6
	d.finish=function(winner)
		m:roundOver(d,winner,function() self:broadcast(d) end,function() m:resetRound(d);self:broadcast(d) end)
	end
	for _,seat in d.seats do
		local actor,other=seat.actor,d.seats[3-seat.index].actor
		actor.hum.Died:Connect(function()
			if d.combat==c and d.phase=="Duel" then actor.health=0;actor.state="Defeated";d.finish(other,actor) end
		end)
	end
	d.epoch+=1
	self:broadcast(d)
end
function Online:rematch(d,seat)
	local other=d.seats[3-seat.index]
	if seat.rematch or not other.present then return end
	seat.rematch=true
	if other.rematch then self:fight(d) else self:broadcast(d) end
end
function Online:teardown(d)
	local c=d.combat
	d.combat=nil
	if c then
		c:clear()
		for _,a in c.actors do AntiCheat.clear(a) end
	end
	for _,seat in d.seats do
		if seat.actor and seat.present and seat.player.Character==seat.actor.model then seat.player.Character=nil end
		seat.actor=nil
	end
	if d.folder then d.folder:Destroy() end
	d.folder=nil;d.effects=nil
end
function Online:dispose(d)
	if not self.duels[d] then return end
	self.duels[d]=nil
	self:teardown(d)
	table.insert(self.freeLanes,d.lane)
end
-- The fight ends early: the player who stays wins, unless the final knockout
-- had already decided the match (its winner stands).
function Online:forfeit(d,stay)
	if not (d.finishing and d.matchPoint) then d.winner=stay.actor.id;d.forfeit=true end
	d.finishing=false;d.matchPoint=true;d.phase="Result"
	local c=d.combat
	c:clear(true)
	for _,a in c.actors do World.pose(a,c.now,.1);a.hum.WalkSpeed=0;a.root.Anchored=true end
end
-- A player leaves the online flow (cancel, back to the roster, disconnect).
-- Waiting entries are withdrawn; a fight in progress is forfeited to the
-- player who stays; the duel and its stage go once nobody is left in it.
function Online:leave(player,s)
	local o=s.online
	if not o then return end
	s.online=nil
	if o.kind=="queue" then
		local index=table.find(self.queue,o.entry)
		if index then table.remove(self.queue,index) end
		return
	elseif o.kind=="host" then
		if self.codes[o.entry.code]==o.entry then self.codes[o.entry.code]=nil end
		return
	end
	local d,seat=o.duel,o.seat
	seat.present=false
	s.epoch=math.max(s.epoch,d.epoch)
	if seat.actor and player.Character==seat.actor.model then player.Character=nil end
	local other=d.seats[3-seat.index]
	if other.present then
		if d.phase=="Pick" then
			-- No fight yet: the pairing is void and the other player is told why.
			other.present=false;other.session.online=nil
			other.session.epoch=math.max(other.session.epoch,d.epoch)
			self.matches:selection(other.player,"OPPONENT LEFT")
		else
			if d.phase=="Duel" then self:forfeit(d,other) end
			self:broadcast(d)
		end
	end
	if not other.present then self:dispose(d) end
end
-- Returns true when the request belongs to the online flow (handled or
-- deliberately ignored); false hands it to the local duel.
function Online:request(player,s,action,payload,clock)
	local o=s.online
	local gap=clock-s.lastLifecycle>=Protocol.LifecycleGap
	if not o then
		if not Protocol.Lifecycle[action] then return false end
		if action~="Cancel" and s.phase=="Selection" and gap then
			s.lastLifecycle=clock
			self:enter(player,s,action,payload)
		end
		return true
	end
	if o.kind~="duel" then
		-- Waiting in the queue or on a private code: only cancelling is possible.
		if action=="Cancel" and gap then s.lastLifecycle=clock;self.matches:selection(player) end
		return true
	end
	local d,seat=o.duel,o.seat
	if d.phase=="Duel" then
		if Protocol.Combat[action] and seat.actor then self.matches:act(d,seat.actor,payload,clock) end
		return true
	end
	if d.phase=="Pick" and (action=="Pick" or action=="Confirm") then
		self:pick(d,seat,action,payload)
	elseif action=="Cancel" or action=="Selection" then
		if gap then s.lastLifecycle=clock;self.matches:selection(player) end
	elseif action=="Rematch" and d.phase=="Result" and gap then
		s.lastLifecycle=clock;self:rematch(d,seat)
	end
	return true
end
function Online:update(dt,now)
	for d in table.clone(self.duels) do
		if not self.duels[d] then continue end
		if d.phase=="Pick" then
			if now>=d.pickUntil then self:fight(d)
			elseif now>=(d.nextPick or 0) then d.nextPick=now+1;self:broadcast(d) end
			continue
		end
		local c=d.combat
		if not c then continue end
		if d.phase=="Duel" then
			-- The local duel's idle rule, for both players.
			for _,seat in d.seats do if os.clock()-seat.actor.lastMove>0.4 then seat.actor.move=Vector3.zero end end
			c:update(math.min(dt,0.1),now)
		end
		-- Regular cadence, plus an immediate packet on a contact, throw or teleport.
		local urgent=c.urgent and now>=(d.lastUrgent or 0)+.03
		if d.combat==c and (now>=(d.nextSnapshot or 0) or urgent) then
			d.nextSnapshot=now+Config.SnapshotInterval;c.urgent=false;d.lastUrgent=now;self:broadcast(d)
		end
	end
end
-- Read-only state for Studio tooling (DevHooks "online").
function Online:summary()
	local duels={}
	for d in self.duels do
		local seats={}
		for _,seat in d.seats do
			local a=seat.actor
			table.insert(seats,{name=seat.name,fighter=seat.fighter,present=seat.present,ready=seat.ready,rematch=seat.rematch,
				health=a and a.health,state=a and a.state,refusedInputs=a and a.refusedInputs or 0,refusedAge=a and a.refusedAge})
		end
		table.insert(duels,{mode=d.mode,phase=d.phase,lane=d.lane,round=d.round,winner=d.winner,forfeit=d.forfeit,seats=seats})
	end
	local codes=0
	for _ in self.codes do codes+=1 end
	return {queued=#self.queue,codes=codes,duels=duels}
end
return Online
