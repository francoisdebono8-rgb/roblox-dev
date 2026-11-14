-- Players online and challenges between them (Server/Lobby, user 04/11: see
-- who is connected, challenge one, he accepts or declines, a match starts —
-- no code). Several "servers" run in one process on the real Matches/Online,
-- sharing a fake MemoryStore, message bus and TeleportService: presence across
-- servers, invitations and answers, the reserved duel server and its record,
-- same-server pairing, the guards (gap, do not disturb, busy, expiry). It
-- proves the server logic, NOT Roblox's own services or a live teleport.
local H=require("./Harness")
local clock=5000
H.workspace.GetServerTimeNow=function() return clock end
H.envBase.task={delay=function() end,spawn=function(fn,...) fn(...) end,defer=function() end,wait=function() return 0 end}
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local Lobby=H.load("Server/Lobby")
local Protocol=H.load("Shared/LobbyProtocol")
local T=Protocol.Tune
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end

-- ---------------------------------------------------------------- the cloud
local function cloud()
	local world={maps={},hashes={},subscribers={},queue={},teleports={},reserved=0}
	local function sorted(name)
		world.maps[name]=world.maps[name] or {}
		local data=world.maps[name]
		return {
			SetAsync=function(_,key,value,life) data[key]={value=value,until_=clock+life} end,
			RemoveAsync=function(_,key) data[key]=nil end,
			GetRangeAsync=function(_,_,count)
				local keys={}
				for k,e in data do if e.until_>clock then table.insert(keys,k) end end
				table.sort(keys)
				local out={}
				for i=1,math.min(count,#keys) do table.insert(out,{key=keys[i],value=data[keys[i]].value}) end
				return out
			end,
		}
	end
	local function hash(name)
		world.hashes[name]=world.hashes[name] or {}
		local data=world.hashes[name]
		return {
			SetAsync=function(_,key,value,life) data[key]={value=value,until_=clock+life} end,
			GetAsync=function(_,key) local e=data[key];return e and e.until_>clock and e.value or nil end,
			RemoveAsync=function(_,key) data[key]=nil end,
		}
	end
	world.store={GetSortedMap=function(_,name) return sorted(name) end,GetHashMap=function(_,name) return hash(name) end}
	world.bus={
		SubscribeAsync=function(_,topic,fn) table.insert(world.subscribers,{topic=topic,fn=fn}) end,
		PublishAsync=function(_,topic,msg) table.insert(world.queue,{topic=topic,msg=msg}) end,
	}
	-- Messages reach every server (like MessagingService), in order.
	function world.pump()
		while #world.queue>0 do
			local m=table.remove(world.queue,1)
			for _,s in world.subscribers do if s.topic==m.topic then s.fn({Data=m.msg}) end end
		end
	end
	world.teleport={
		ReserveServer=function() world.reserved+=1;return "code"..world.reserved,"ps"..world.reserved end,
		TeleportAsync=function(_,placeId,players,options)
			for _,p in players do table.insert(world.teleports,{player=p,code=options and options.code}) end
		end,
	}
	return world
end
local inbox={}
local function remoteFor()
	return {FireClient=function(_,player,data) inbox[player]=inbox[player] or {};table.insert(inbox[player],data) end}
end
local function lastOf(player,kind)
	local list=inbox[player] or {}
	for i=#list,1,-1 do if list[i].kind==kind then return list[i] end end
	return nil
end
local guid=0
local function server(world,job,extra)
	local remote=remoteFor()
	local m=Matches.new(remote)
	local svc={store=world.store,messaging=world.bus,teleport=world.teleport,remote=remote,jobId=job,placeId=77,
		privateServerId=extra and extra.privateServerId or "",privateServerOwnerId=0,
		now=function() return clock end,spawn=function(fn,...) fn(...) end,
		guid=function() guid+=1;return string.format("challenge-%04d",guid) end,
		teleportOptions=function(code) return {code=code} end,
		friends=function(id) return extra and extra.friends and extra.friends[id] or {} end}
	local lobby=Lobby.new(m,svc)
	m.lobby=lobby
	return {m=m,lobby=lobby,job=job}
end
local nextId=100
local function join(sv,name)
	nextId+=1
	local player={UserId=nextId,Name=name,DisplayName=name,Parent=H.Players,Character=nil}
	sv.m:selection(player);sv.lobby:track(player)
	return player
end
local function op(sv,player,payload)
	local p=sv.lobby.players[player.UserId];if p then p.lastOp=-math.huge end
	sv.lobby:request(player,payload)
end
local function tick(world,servers,seconds)
	clock+=seconds or 0
	for _,sv in servers do sv.lobby:update() end
	world.pump()
end
-- Every server has published and read the others back.
local function settle(world,servers) tick(world,servers);tick(world,servers,T.Read+.5) end
local function freeGap(sv,player) sv.lobby.players[player.UserId].lastChallenge=-math.huge end

test("presence: each server lists the players of every server, friends first, without himself",function()
	local world=cloud()
	local a=server(world,"A");local b=server(world,"B")
	local alice=join(a,"Alice");local carol=join(a,"Carol")
	local bob=join(b,"Bob");local dave=join(b,"Dave")
	a.lobby.players[alice.UserId].friends={[dave.UserId]=true}
	settle(world,{a,b})
	op(a,alice,{op="open"})
	local list=lastOf(alice,"list")
	assert(list and #list.players==3,"Alice sees "..(list and #list.players or 0).." players")
	assert(list.players[1].id==dave.UserId and list.players[1].friend,"her friend is not first")
	local seen={}
	for _,e in list.players do seen[e.id]=e end
	assert(not seen[alice.UserId],"she sees herself")
	assert(seen[carol.UserId].here and not seen[bob.UserId].here,"here / elsewhere wrong")
	assert(seen[bob.UserId].state=="free","Bob is "..tostring(seen[bob.UserId].state))
	-- a server that stops publishing: its players expire from the map
	b.lobby.presence=nil
	tick(world,{a,b},T.Life+1);tick(world,{a,b},T.Read+1)
	op(a,alice,{op="open"})
	list=lastOf(alice,"list")
	assert(#list.players==1 and list.players[1].id==carol.UserId,"Bob and Dave never expired")
end)

test("challenge across servers: invitation, acceptance, both sent to one reserved duel server",function()
	local world=cloud()
	local a=server(world,"A");local b=server(world,"B")
	local alice=join(a,"Alice");local bob=join(b,"Bob")
	settle(world,{a,b})
	op(a,alice,{op="challenge",to=bob.UserId,fighter="Lion"})
	world.pump()
	local sent=lastOf(alice,"sent")
	local invite=lastOf(bob,"invite")
	assert(sent and sent.to=="Bob","Alice was not told the challenge left")
	assert(invite and invite.from=="Alice" and invite.fighter=="Lion","Bob got no invitation")
	op(b,bob,{op="answer",id=invite.id,accept=true,fighter="Sand"})
	world.pump();world.pump()
	assert(#world.teleports==2,"teleports: "..#world.teleports)
	local codes={}
	for _,t in world.teleports do codes[t.player]=t.code end
	assert(codes[alice]=="code1" and codes[bob]=="code1","not the same duel server")
	local record=world.hashes[T.DuelMap]["ps1"].value
	assert(record.a==alice.UserId and record.b==bob.UserId and record.fa=="Lion" and record.fb=="Sand","duel record "..tostring(record.fa))
	assert(a.m.sessions[alice].online.kind=="travel","Alice is not travelling")
	assert(a.lobby:stateOf(a.lobby.players[alice.UserId])=="duel","she still looks free")
end)

test("the duel server pairs the two players its record names and sends anyone else home",function()
	local world=cloud()
	world.store:GetHashMap(T.DuelMap):SetAsync("ps9",{a=501,b=502,fa="Mirage",fb="Leaf",id="x"},600)
	local d=server(world,"D",{privateServerId="ps9"})
	assert(d.lobby.duel and d.lobby.duel.record,"the duel server did not read its record")
	local function arrive(id,name)
		local player={UserId=id,Name=name,DisplayName=name,Parent=H.Players}
		d.m:selection(player);d.lobby:track(player)
		return player
	end
	local alice=arrive(501,"Alice")
	assert(d.m.sessions[alice].phase=="Queue","Alice does not wait for her opponent")
	local eve=arrive(777,"Eve")
	assert(#world.teleports==1 and world.teleports[1].player==eve and world.teleports[1].code==nil,"an uninvited player stayed")
	local bob=arrive(502,"Bob")
	local o=d.m.sessions[alice].online
	assert(o and o.kind=="duel" and o.duel.mode=="challenge" and o.duel.phase=="Pick","no pick after both arrived")
	assert(o.duel.seats[1].fighter=="Mirage" and o.duel.seats[2].fighter=="Leaf","fighters from the record lost")
	-- after the duel, back to the roster = back home
	d.m:selection(bob)
	assert(world.teleports[#world.teleports].player==bob and world.teleports[#world.teleports].code==nil,"Bob was not sent home")
end)

test("the duel server sends a lone player home when the other one never arrives",function()
	local world=cloud()
	world.store:GetHashMap(T.DuelMap):SetAsync("ps3",{a=601,b=602,fa="Lion",fb="Legion"},600)
	local d=server(world,"D",{privateServerId="ps3"})
	local alice={UserId=601,Name="Alice",DisplayName="Alice",Parent=H.Players}
	d.m:selection(alice);d.lobby:track(alice)
	tick(world,{d},T.Arrival+1)
	assert(#world.teleports==1 and world.teleports[1].player==alice,"Alice stayed alone")
end)

test("same server: an accepted challenge goes straight to the online pick, no teleport",function()
	local world=cloud()
	local a=server(world,"A")
	local alice=join(a,"Alice");local carol=join(a,"Carol")
	-- Carol is training against the AI: still challengeable, the AI duel ends
	assert(a.m:start(carol,"Leaf","Mirage",false),"Carol's AI duel did not start")
	tick(world,{a})
	op(a,alice,{op="challenge",to=carol.UserId,fighter="Copycat"})
	local invite=lastOf(carol,"invite")
	assert(invite,"Carol got no invitation in her AI duel")
	op(a,carol,{op="answer",id=invite.id,accept=true,fighter="GentleFist"})
	local o=a.m.sessions[alice].online
	assert(o and o.kind=="duel" and o.duel.phase=="Pick" and o.duel.mode=="challenge","no online pick")
	assert(o.duel.seats[1].fighter=="Copycat" and o.duel.seats[2].fighter=="GentleFist","fighters")
	assert(#world.teleports==0,"a teleport for a duel on the same server")
	assert(a.m.sessions[carol].phase=="Pick","Carol's AI duel did not end")
end)

test("guards: decline, no answer, do not disturb, in a duel, one challenge every 10 s, cancel",function()
	local world=cloud()
	local a=server(world,"A");local b=server(world,"B")
	local alice=join(a,"Alice");local bob=join(b,"Bob");local dave=join(b,"Dave")
	settle(world,{a,b})
	-- declined
	op(a,alice,{op="challenge",to=bob.UserId});world.pump()
	op(b,bob,{op="answer",id=lastOf(bob,"invite").id,accept=false});world.pump()
	assert(lastOf(alice,"status").text=="BOB DECLINED",lastOf(alice,"status").text)
	-- the gap
	op(a,alice,{op="challenge",to=dave.UserId})
	assert(string.find(lastOf(alice,"status").text,"WAIT",1,true),"no gap between challenges")
	-- no answer
	freeGap(a,alice)
	op(a,alice,{op="challenge",to=dave.UserId});world.pump()
	tick(world,{a,b},T.ChallengeLife+3)
	assert(lastOf(alice,"status").text=="NO ANSWER FROM DAVE",lastOf(alice,"status").text)
	assert(lastOf(dave,"closed"),"Dave's invitation stayed on screen")
	-- do not disturb (published, then read by the other server)
	op(b,bob,{op="dnd",on=true})
	tick(world,{a,b},T.Read+1);tick(world,{a,b},0)
	freeGap(a,alice)
	op(a,alice,{op="challenge",to=bob.UserId});world.pump()
	assert(string.find(lastOf(alice,"status").text,"DISTURBED",1,true),"do not disturb ignored")
	assert(lastOf(bob,"invite").id~=lastOf(alice,"sent").id,"Bob was disturbed")
	-- cancel
	freeGap(a,alice)
	op(a,alice,{op="challenge",to=dave.UserId});world.pump()
	local id=lastOf(alice,"sent").id
	op(a,alice,{op="cancel",id=id});world.pump()
	assert(lastOf(dave,"closed").id==id,"a cancelled challenge stayed with Dave")
	-- in an online duel: not challengeable
	local carol=join(a,"Carol")
	a.m.sessions[carol].online={kind="duel"}
	freeGap(a,alice)
	op(a,alice,{op="challenge",to=carol.UserId})
	assert(string.find(lastOf(alice,"status").text,"IN A DUEL",1,true),"challenged a player in a duel")
end)

test("requests: only ids and booleans, anything else ignored",function()
	local world=cloud()
	local a=server(world,"A")
	local alice=join(a,"Alice")
	for _,bad in {{op="challenge",to="1"},{op="challenge",to=0/0},{op="answer",id=string.rep("x",80),accept=true},{op="dnd",on="yes"},{op=5},"text"} do
		op(a,alice,bad)
	end
	assert(next(a.lobby.outgoing)==nil and not a.lobby.players[alice.UserId].dnd,"a malformed request did something")
	op(a,alice,{op="fighter",fighter="Mirror"})
	assert(a.lobby.players[alice.UserId].fighter~="Mirror","a fighter outside the beta was taken")
	-- (Studio 04/11) the list's own refresh, just before a click, never swallows it
	local carol=join(a,"Carol")
	a.lobby:request(alice,{op="open"})
	a.lobby:request(alice,{op="challenge",to=carol.UserId,fighter="Lion"})
	assert(lastOf(carol,"invite"),"the refresh swallowed the challenge")
end)

test("client panel: the list, a challenge, an invitation answered, the status line",function()
	H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim
	H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	H.workspace.GetAttribute=function() return nil end
	local savedTask=H.envBase.task
	H.envBase.task={delay=function() end,spawn=function() end,defer=function() end,wait=function() return 0 end}
	local savedInstance=H.envBase.Instance
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local ui=UI.new(baseNew("PlayerGui"),function() end)
		local fired,listener={},nil
		local remote={OnClientEvent={Connect=function(_,fn) listener=fn end},FireServer=function(_,payload) table.insert(fired,payload) end}
		local Panel=H.load("Client/LobbyPanel")
		local panel=Panel.new(ui,remote,UI.kit)
		panel.button.click()
		assert(panel.overlay.Visible and fired[#fired].op=="open","the list did not open")
		listener({kind="list",dnd=false,players={
			{id=7,name="Bob",fighter="Sand",state="free",friend=true},
			{id=8,name="Dave",fighter="Lion",state="duel"},
		}})
		assert(#panel.rows==2,"rows: "..#panel.rows)
		assert(string.find(panel.button.Text,"2",1,true),"the count is not on the button")
		ui.player="Mirage"
		-- the free player's CHALLENGE, the busy one's does nothing
		panel.rowButtons[2].click()
		assert(fired[#fired].op~="challenge","challenged a player in a duel")
		panel.rowButtons[1].click()
		assert(fired[#fired].op=="challenge" and fired[#fired].to==7 and fired[#fired].fighter=="Mirage","no challenge sent")
		listener({kind="sent",id="c1",to="Bob",remaining=20})
		assert(panel.statusBox.Visible and panel.cancelButton.Visible,"no status line with cancel")
		-- an invitation, accepted
		listener({kind="invite",id="c2",from="Eve",fromId=9,fighter="Leaf",remaining=20})
		assert(panel.inviteCard.Visible and string.find(panel.inviteText.Text,"EVE",1,true),"no invitation card")
		panel.acceptButton.click()
		assert(fired[#fired].op=="answer" and fired[#fired].accept==true and fired[#fired].id=="c2","the answer was not sent")
		assert(not panel.inviteCard.Visible,"the card stayed")
		panel:render({phase="Duel"})
		assert(not panel.button.Visible and not panel.overlay.Visible,"the list stayed over the duel")
	end)
	H.envBase.task=savedTask;H.envBase.Instance=savedInstance
	assert(ok,err)
end)

-- (14/11, challenges from Konoha) a duel that counts takes a learned kit:
-- a crafted request naming an unlearned one goes with the kit he chose.
test("a challenge and its answer carry a learned kit; an unlearned one gives way to the chosen kit",function()
	local world=cloud()
	local a=server(world,"A")
	local learned={}
	a.lobby.svc.owns=function(player,id) return learned[player.UserId] and learned[player.UserId][id]==true end
	a.lobby.svc.kitOf=function(player) return learned[player.UserId] and learned[player.UserId].chosen end
	local alice=join(a,"Alice");local carol=join(a,"Carol")
	learned[alice.UserId]={Leaf=true,chosen="Leaf"}
	learned[carol.UserId]={Sand=true,chosen="Sand"}
	op(a,alice,{op="challenge",to=carol.UserId,fighter="Flashstep"})
	local invite=lastOf(carol,"invite")
	assert(invite and invite.fighter=="Leaf","the invitation names "..tostring(invite and invite.fighter))
	op(a,carol,{op="answer",id=invite.id,accept=true,fighter="Mirage"})
	local o=a.m.sessions[alice].online
	assert(o and o.duel.seats[1].fighter=="Leaf" and o.duel.seats[2].fighter=="Sand",
		"seats: "..tostring(o and o.duel.seats[1].fighter).." / "..tostring(o and o.duel.seats[2].fighter))
	-- do not disturb shows on the player (Konoha's name tags)
	local seen
	local p=a.lobby.players[alice.UserId]
	p.player.SetAttribute=function(_,k,v) if k=="NinjaDnd" then seen=v end end
	op(a,alice,{op="dnd",on=true})
	assert(seen==true,"do not disturb not shown on the player")
end)

print(("Lobby: %d passed"):format(passed))
