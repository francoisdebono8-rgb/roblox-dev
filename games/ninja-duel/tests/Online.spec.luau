-- Online 1v1 (NET-001): casual queue, private codes, fighter pick, a duel of
-- two human actors on the real Matches/Online/Combat, per-viewer snapshots,
-- per-player input/anti-cheat, rounds, rematch, leave and disconnect cleanup.
-- Harness rigs and a scripted clock: it proves server authority and lifecycle,
-- NOT replication, real latency or a two-client Studio session.
local H=require("./Harness")
local V=H.V
local clock=1000
H.workspace.GetServerTimeNow=function() return clock end
-- Deterministic stand-in for task.delay (the KO beat between rounds).
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
-- Duel folders are cleared between rounds like real Folders; GUI buttons can
-- be clicked by the UI smoke test (`x.click`).
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	x.Activated={Connect=function(_,fn) x.click=fn end}
	return x
end}
-- The stage is not under test: no arena geometry, harness rigs for bodies.
local World=H.load("Server/World")
local arenas=0
World.arena=function() arenas+=1 end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local AI=H.load("Server/AI")
local aiCreated=0
local aiNew=AI.new
AI.new=function(...) aiCreated+=1;return aiNew(...) end
local Matches=H.load("Server/Matches")
local AntiCheat=H.load("Server/VelmoraAntiCheat")
local Protocol=H.load("Shared/OnlineProtocol")
local DevHooks=H.load("Server/DevHooks")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local inbox={}
-- The client drops any packet older than the last epoch it saw: every player's
-- stream of epochs must never go backwards, whatever flow they went through.
local remote={FireClient=function(_,player,data)
	inbox[player]=inbox[player] or {}
	local previous=inbox[player][#inbox[player]]
	assert(type(data.epoch)=="number","packet without an epoch")
	assert(not previous or data.epoch>=previous.epoch,string.format("epoch went backwards for %s: %d -> %d (%s)",player.Name,previous and previous.epoch or -1,data.epoch,tostring(data.phase)))
	table.insert(inbox[player],data)
end}
local function last(player) local list=inbox[player];return list and list[#list] end
local nextId=0
local function newPlayer(name)
	nextId+=1
	local player={UserId=nextId,Name=name,DisplayName=name,Parent=H.Players,Character=nil}
	return player
end
local seed=7
local function fresh()
	local m=Matches.new(remote)
	-- Deterministic codes (Roblox's Random is entropy-seeded).
	m.online.rng={NextInteger=function(_,a,b) seed=(seed*1103515245+12345)%2147483648;return a+seed%(b-a+1) end}
	return m
end
local function join(m,...)
	local list={}
	for _,name in {...} do local p=newPlayer(name);m:selection(p);table.insert(list,p) end
	return table.unpack(list)
end
-- One request as the client sends it: the current epoch, a fresh token bucket
-- (the real bucket runs on wall-clock time), extras merged in.
local function send(m,player,action,extra,epoch)
	local s=m.sessions[player]
	s.bucket.tokens=100
	local payload={action=action,epoch=epoch or s.epoch}
	for k,v in extra or {} do payload[k]=v end
	m:request(player,payload)
end
local function lifecycle(m,player,action,extra)
	m.sessions[player].lastLifecycle=-10
	send(m,player,action,extra)
end
local function actorOf(m,player) return m.sessions[player].online.seat.actor end
local function act(m,player,action,extra)
	AntiCheat.clear(actorOf(m,player))
	local payload={clientTime=clock}
	for k,v in extra or {} do payload[k]=v end
	send(m,player,action,payload)
end
local function step(m,seconds)
	for _=1,math.max(1,math.ceil(seconds/.01)) do
		clock+=.01
		m:update(.01,clock)
		runTimers()
	end
end
local function duelOf(m,player) return m.sessions[player].online.duel end
-- Two players paired through the casual queue, fighters confirmed.
local function fight(m,first,second,a,b)
	lifecycle(m,first,"Queue",{player=a or "Flashstep"});lifecycle(m,second,"Queue",{player=b or "Mirage"})
	send(m,first,"Confirm");send(m,second,"Confirm")
	local d=duelOf(m,first)
	assert(d and d.phase=="Duel","the fight did not start")
	return d
end
local function count(t) local n=0;for _ in t do n+=1 end;return n end

test("casual queue pairs the first two players, keeps the next waiting and rejects bad entries",function()
	local m=fresh()
	local a,b,c,e=join(m,"Alpha","Bravo","Charlie","Echo")
	local before=m.sessions[a].epoch
	lifecycle(m,a,"Queue",{player="Flashstep"})
	assert(m.sessions[a].phase=="Queue" and last(a).phase=="Queue" and last(a).online.mode=="casual")
	assert(m.sessions[a].epoch>before,"waiting must open a new epoch")
	lifecycle(m,b,"Queue",{player="Mirage"})
	local d=duelOf(m,a)
	assert(d and d==duelOf(m,b) and d.phase=="Pick" and d.mode=="casual")
	assert(d.seats[1].player==a and d.seats[2].player==b,"first come, first seated")
	for _,p in {a,b} do assert(m.sessions[p].phase=="Pick" and m.sessions[p].epoch==d.epoch and last(p).epoch==d.epoch) end
	assert(last(a).online.me=="Flashstep" and last(a).online.them=="Mirage" and last(a).online.opponent=="Bravo")
	assert(last(b).online.me=="Mirage" and last(b).online.them=="Flashstep" and last(b).online.opponent=="Alpha")
	assert(last(a).online.remaining>0 and last(a).online.remaining<=Protocol.PickTime)
	lifecycle(m,c,"Queue",{player="Lion"})
	assert(m.sessions[c].phase=="Queue" and #m.online.queue==1)
	lifecycle(m,c,"Queue",{player="Lion"})
	assert(#m.online.queue==1,"a waiting player queued twice")
	lifecycle(m,e,"Queue",{player="NotAFighter"})
	assert(m.sessions[e].phase=="Selection" and last(e).notice=="CHOOSE A FIGHTER FIRST" and #m.online.queue==1)
	lifecycle(m,e,"Queue",{player={}})
	assert(m.sessions[e].phase=="Selection" and #m.online.queue==1)
	-- Waiting players cannot start a local duel behind the queue's back.
	lifecycle(m,c,"Start",{player="Lion",bot="Mirage"})
	assert(m.sessions[c].phase=="Queue" and not m.sessions[c].combat)
	lifecycle(m,c,"Cancel")
	assert(m.sessions[c].phase=="Selection" and #m.online.queue==0 and not m.sessions[c].online)
end)

test("private code: hosted, refused when wrong, case-insensitive, single use",function()
	local m=fresh()
	local a,b,c=join(m,"Host","Friend","Late")
	lifecycle(m,a,"Host",{player="Lion"})
	local code=last(a).online.code
	assert(last(a).phase=="Queue" and last(a).online.mode=="private" and type(code)=="string" and #code==Protocol.CodeLength)
	for i=1,#code do assert(string.find(Protocol.CodeAlphabet,string.sub(code,i,i),1,true),"code outside the alphabet") end
	assert(m.online.codes[code] and #m.online.queue==0,"a private host must not enter the casual queue")
	local wrong=if code=="AAAAA" then "BBBBB" else "AAAAA"
	for _,bad in {wrong,123,string.rep("A",400),"A A",nil} do
		lifecycle(m,b,"Join",{player="Mirage",code=bad})
		assert(m.sessions[b].phase=="Selection" and last(b).notice=="NO PRIVATE DUEL WITH THIS CODE")
	end
	-- The host is waiting: joining anything, even its own code, is ignored.
	lifecycle(m,a,"Join",{player="Lion",code=code})
	assert(m.sessions[a].phase=="Queue" and m.online.codes[code])
	lifecycle(m,b,"Join",{player="Mirage",code=" "..string.lower(code).." "})
	local d=duelOf(m,a)
	assert(d and d==duelOf(m,b) and d.mode=="private" and d.code==code and d.phase=="Pick")
	assert(m.online.codes[code]==nil,"a code must be single use")
	lifecycle(m,c,"Join",{player="Flashstep",code=code})
	assert(m.sessions[c].phase=="Selection" and last(c).notice=="NO PRIVATE DUEL WITH THIS CODE")
	-- A host may cancel: the code dies with it.
	lifecycle(m,c,"Host",{player="Flashstep"})
	local other=last(c).online.code
	lifecycle(m,c,"Cancel")
	assert(m.online.codes[other]==nil and m.sessions[c].phase=="Selection")
end)

test("pick: change and confirm, then a duel of two human actors with no AI",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local ai=aiCreated
	lifecycle(m,a,"Queue",{player="Flashstep"});lifecycle(m,b,"Queue",{player="Mirage"})
	local d=duelOf(m,a)
	send(m,a,"Pick",{player="GentleFist"})
	assert(d.seats[1].fighter=="GentleFist" and last(b).online.them=="GentleFist")
	send(m,a,"Pick",{player="Ghost"})
	assert(d.seats[1].fighter=="GentleFist","an unknown pick was accepted")
	send(m,a,"Confirm")
	assert(d.seats[1].ready and last(b).online.theirReady and d.phase=="Pick")
	send(m,a,"Pick",{player="Lion"})
	assert(d.seats[1].fighter=="GentleFist","a confirmed pick changed")
	local arenasBefore=arenas
	send(m,b,"Confirm")
	assert(d.phase=="Duel" and d.combat and #d.combat.actors==2 and arenas==arenasBefore+1)
	local one,two=d.seats[1].actor,d.seats[2].actor
	assert(one.fighterId=="GentleFist" and two.fighterId=="Mirage")
	assert(a.Character==one.model and b.Character==two.model,"each player must own their own body")
	assert(one.target==two and two.target==one and one.locked and two.locked)
	assert(d.combat.match==d and d.ai==nil and aiCreated==ai,"an online duel created an AI")
	for _,p in {a,b} do assert(m.sessions[p].phase=="Duel" and m.sessions[p].epoch==d.epoch and not m.sessions[p].combat) end
	assert(last(a).phase=="Duel" and last(a).intro>0,"the round opens with the tournament intro")
	-- The pick timer starts the fight on its own.
	local c,e=join(m,"Charlie","Echo")
	lifecycle(m,c,"Queue",{player="Lion"});lifecycle(m,e,"Queue",{player="Lion"})
	local timed=duelOf(m,c)
	step(m,Protocol.PickTime*.5)
	assert(timed.phase=="Pick" and last(c).phase=="Pick" and last(c).online.remaining<Protocol.PickTime)
	step(m,Protocol.PickTime*.5+.05)
	assert(timed.phase=="Duel" and timed.seats[1].actor.fighterId=="Lion" and timed.seats[2].actor.fighterId=="Lion")
	assert(timed.lane~=d.lane,"two live duels shared a stage")
end)

test("each viewer gets its own actor as human and finds the opponent model by bot.id",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b,"Lion","GentleFist")
	local one,two=d.seats[1].actor,d.seats[2].actor
	local va,vb=last(a),last(b)
	assert(va.human.id==one.id and va.bot.id==two.id and vb.human.id==two.id and vb.bot.id==one.id)
	assert(va.human.fighterId=="Lion" and vb.human.fighterId=="GentleFist")
	assert(one.id~="AIFighter" and two.id~="AIFighter","online models must not borrow the AI name")
	-- The opponent rig: a sibling of the viewer's character named bot.id.
	assert(two.model.Name==va.bot.id and two.model.Parent==a.Character.Parent)
	assert(one.model.Name==vb.bot.id and one.model.Parent==b.Character.Parent)
	assert(va.online.opponent=="Bravo" and vb.online.opponent=="Alpha")
	d.introUntil=nil
	d.combat:damage(two,one,10,false,false)
	step(m,.1)
	assert(last(a).human.health<last(a).human.maxHealth and last(b).bot.health==last(a).human.health)
	assert(last(b).human.health==two.def.Health)
end)

test("a player's requests drive only their own actor; client values never write state",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b)
	d.introUntil=nil
	local one,two=d.seats[1].actor,d.seats[2].actor
	send(m,b,"Move",{direction=V.xAxis,sprint=true})
	assert(two.move==V.xAxis and two.sprinting and one.move==V.zero and not one.sprinting)
	send(m,a,"Move",{direction=-V.zAxis,locked=false})
	assert(one.move==-V.zAxis and not one.locked and two.move==V.xAxis and two.locked)
	act(m,b,"Attack")
	assert(two.state=="Startup" and one.state=="Neutral","B's strike moved A")
	act(m,a,"Guard")
	assert(one.guardWanted and not two.guardWanted)
	-- The local duel's idle rule holds for each player separately.
	send(m,a,"Move",{direction=V.xAxis})
	two.lastMove=os.clock()-1
	step(m,.02)
	assert(two.move==V.zero and one.move==V.xAxis,"a silent player kept moving, or the other was stopped")
	local health=one.health
	send(m,a,"Move",{direction=V.zero,health=9999,actor=two,state="Defeated",position=V.new(99,99,99)})
	assert(one.health==health and two.health==two.def.Health and one.state~="Defeated")
end)

test("no AI runs in an online duel: an idle player's fighter stays idle",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local ai=aiCreated
	local d=fight(m,a,b,"Mirage","Flashstep")
	local two=d.seats[2].actor
	local from=two.root.Position
	step(m,4)
	assert(d.combat.now>d.introUntil,"the intro never ended")
	assert(two.state=="Neutral" and two.attackName==nil and two.events==nil and #d.combat.projectiles==0,"the idle fighter acted on its own")
	assert((two.root.Position-from).Magnitude<.5 and aiCreated==ai and d.ai==nil)
end)

test("anti-cheat, rate limits, epochs and payload validation stay per player",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b)
	d.introUntil=nil
	local one,two=d.seats[1].actor,d.seats[2].actor
	act(m,a,"Attack")
	assert(one.state=="Startup")
	-- A's attack rate state does not throttle B.
	assert(not AntiCheat.check(one,"Attack",clock,clock),"A's second press inside the rate gap passed")
	assert(AntiCheat.check(two,"Attack",clock,clock));AntiCheat.clear(two)
	-- Stale or future client clocks are refused, then a fresh one passes.
	act(m,b,"Heavy",{clientTime=clock-1});assert(two.state=="Neutral","stale clientTime accepted")
	-- Refusals are counted per player for the Studio latency matrix (DevHooks "online").
	assert(two.refusedInputs==1 and math.abs(two.refusedAge-1)<1e-6 and (one.refusedInputs or 0)==0)
	local seats=m.online:summary().duels[1].seats
	assert(seats[2].refusedInputs==1 and seats[1].refusedInputs==0)
	act(m,b,"Heavy",{clientTime=clock+1});assert(two.state=="Neutral","future clientTime accepted")
	act(m,b,"Heavy",{clientTime="soon"});assert(two.state=="Neutral")
	-- An old epoch, a malformed direction or an impossible aim never reach Combat.
	local s=m.sessions[b]
	AntiCheat.clear(two);send(m,b,"Heavy",{clientTime=clock},s.epoch-1);assert(two.state=="Neutral")
	for _,dir in {V.new(3,0,0),V.new(0,1,0),V.new(0/0,0,0),"left"} do
		send(m,b,"Move",{direction=dir});assert(two.move==V.zero)
		act(m,b,"Dodge",{direction=dir});assert(two.state=="Neutral")
	end
	-- Shadow Shuriken: refused at an impossible aim, accepted at a real one.
	act(m,b,"Technique2",{aim=two.root.Position+V.new(0,0,500)});assert(two.state=="Neutral" and two.pending==nil)
	act(m,b,"Technique2",{aim=one.root.Position});assert(two.state=="TechniqueChannel","the valid aim control failed")
	-- Each player's token bucket is their own.
	-- (Audit 29/10: the stick has a budget of its own, s.moveBucket.)
	s.bucket.tokens=0;s.moveBucket={tokens=0,time=os.clock()}
	local ownBucket=m.sessions[a].bucket
	ownBucket.tokens=100
	m:request(b,{action="Move",epoch=s.epoch,direction=V.xAxis})
	assert(two.move==V.zero,"an empty bucket still passed")
	m:request(a,{action="Move",epoch=m.sessions[a].epoch,direction=V.xAxis})
	assert(one.move==V.xAxis,"B's empty bucket throttled A")
end)

test("two players drive blades, substitution, Flying Thunder God, grab break, jump and clash with their own requests",function()
	local Config=H.load("Shared/Config")
	local Techniques=H.load("Server/Techniques")
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b,"Flashstep","Mirage")
	d.introUntil=nil
	local c=d.combat
	local one,two=d.seats[1].actor,d.seats[2].actor
	local function place(gap)
		c:relocate(one,d.origin+V.new(0,3,gap/2));c:relocate(two,d.origin+V.new(0,3,-gap/2))
		one.root.CFrame=H.C.lookAt(one.root.Position,two.root.Position);two.root.CFrame=H.C.lookAt(two.root.Position,one.root.Position)
		for _,x in {one,two} do x.move=V.zero;x.reaction=nil;x.reactionUntil=0;x.state="Neutral";x.pending=nil;x.attackName=nil;x.untilTime=0;x.hop=nil end
	end
	-- Bravo's shuriken: thrown by Bravo's request, owned by Bravo's model, hits Alpha.
	place(20)
	act(m,b,"Tool",{aim=one.root.Position})
	local blade
	for _=1,40 do
		step(m,.01)
		for _,p in c.projectiles do if p.a==two then blade=p end end
		if blade then break end
	end
	assert(blade,"Bravo's request threw no blade")
	-- No body geometry in the harness: apply the contact Studio's raycast finds.
	c:projectileHit(blade,one,one.root.Position,-blade.direction);c:removeProjectile(blade)
	step(m,.1)
	assert(one.health<one.def.Health and two.health==two.def.Health,"Bravo's blade did not hurt Alpha")
	local flew,hit=false,false
	for _,packet in inbox[a] do
		for _,p in packet.projectiles or {} do if p.owner==two.id then flew=true end end
		for _,i in packet.impacts or {} do if i.owner==two.id and i.victim==one.id then hit=true end end
	end
	assert(flew and hit,"Alpha's packets never named Bravo's blade and its contact")
	-- Kawarimi: Alpha hits, Bravo escapes with his own request (crow clone behind Alpha).
	step(m,1);place(4)
	assert(c:damage(one,two,5,false,false))
	local from=two.root.Position
	act(m,b,"Substitute")
	assert(two.subCharges==Config.Substitution.Charges-1 and (two.root.Position-from).Magnitude>2,"Bravo did not substitute")
	assert(one.subCharges==Config.Substitution.Charges and one.pursuitUntil>c.now,"Alpha's side of the substitution is wrong")
	-- Flying Thunder God: Alpha's request takes Alpha to Alpha's seal; Bravo stays.
	step(m,1.2);place(30)
	Techniques.plant(c,one,d.origin+V.new(30,0,0),V.yAxis)
	local stay=two.root.Position
	act(m,a,"Technique2")
	for _=1,40 do step(m,.01);if (one.flashUntil or 0)>c.now then break end end
	assert((one.flashUntil or 0)>c.now and one.root.Position.X-d.origin.X>25,"Alpha's teleport did not reach the seal")
	assert((two.root.Position-stay).Magnitude<1,"Alpha's teleport moved Bravo")
	-- Grab and throw break, each from its own player.
	step(m,1.5);place(3)
	act(m,a,"Grab")
	for _=1,40 do step(m,.01);if two.reaction=="Grabbed" then break end end
	assert(one.grabVictim==two and two.reaction=="Grabbed","Alpha's grab did not seize Bravo")
	act(m,b,"Grab")
	assert(two.grabbedBy==nil and one.grabVictim==nil and two.events.ThrowBreak==1,"Bravo's throw break failed")
	-- Bravo jumps, Alpha stays grounded.
	step(m,1);place(12)
	act(m,b,"Jump")
	local rose=false
	for _=1,40 do step(m,.01);if two.airborne then rose=true;break end end
	assert(rose and not one.airborne,"Bravo's jump did not leave the ground (or moved Alpha)")
	-- Clash: two players' strikes going active together cancel out.
	local e,f=join(m,"Echo","Foxtrot")
	local mirror=fight(m,e,f,"Flashstep","Flashstep")
	mirror.introUntil=nil
	local x,y=mirror.seats[1].actor,mirror.seats[2].actor
	mirror.combat:relocate(x,mirror.origin+V.new(0,3,2.25));mirror.combat:relocate(y,mirror.origin+V.new(0,3,-2.25))
	x.root.CFrame=H.C.lookAt(x.root.Position,y.root.Position);y.root.CFrame=H.C.lookAt(y.root.Position,x.root.Position)
	act(m,e,"Attack");act(m,f,"Attack")
	for _=1,30 do step(m,.01);if x.events and (x.events.Clash or 0)>0 then break end end
	assert(x.events.Clash==1 and y.events.Clash==1 and x.health==x.def.Health and y.health==y.def.Health,"the two players' strikes did not clash")
end)

test("during a fight only combat requests reach Combat; lobby and AI requests are ignored",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b)
	d.introUntil=nil
	local one=d.seats[1].actor
	local s=m.sessions[a]
	for _,action in {"Start","Tutorial","Queue","Host","Join","Cancel","Rematch","Selection","Pick","Confirm","TutorialSkip","Explode"} do
		one.cue="";AntiCheat.clear(one)
		lifecycle(m,a,action,{player="Lion",bot="Lion",code="AAAAA",clientTime=clock})
		assert(d.phase=="Duel" and s.online and s.online.duel==d and not s.human and not s.combat,action.." leaked out of the fight")
		assert(one.state=="Neutral" and one.cue~="UNKNOWN ACTION",action.." reached Combat")
	end
	act(m,a,"Attack");assert(one.state=="Startup","a real combat request was not executed")
end)

test("rounds, KO beat and the result are mapped to each viewer",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local ai=aiCreated
	local d=fight(m,a,b)
	d.introUntil=nil
	local one,two=d.seats[1].actor,d.seats[2].actor
	local epoch=d.epoch
	d.combat:damage(two,one,1000,false,false)
	assert(d.finishing and d.winner==two.id and last(a).ko and last(b).ko)
	assert(last(b).winner=="PlayerFighter" and last(a).winner=="AIFighter")
	-- (Final blow) the KO beat holds the thrown body's flight: 2.6 s, then 2.2 s on match point
	step(m,2.7)
	assert(d.round==2 and d.epoch==epoch+1 and not d.finishing and d.phase=="Duel")
	for _,p in {a,b} do assert(m.sessions[p].epoch==d.epoch and last(p).epoch==d.epoch and last(p).round==2) end
	assert(last(a).wins.human==0 and last(a).wins.bot==1 and last(b).wins.human==1 and last(b).wins.bot==0)
	assert(one.health==one.def.Health and two.health==two.def.Health and last(a).winner==nil)
	assert(one.root.Position.Z>two.root.Position.Z,"the rounds must restart on the same sides")
	d.introUntil=nil
	d.combat:damage(two,one,1000,false,false)
	assert(d.matchPoint)
	step(m,2.3)
	assert(d.phase=="Result" and m.sessions[a].phase=="Result" and m.sessions[b].phase=="Result")
	assert(last(b).phase=="Result" and last(b).winner=="PlayerFighter" and last(b).wins.human==2)
	assert(last(a).winner=="AIFighter" and last(a).wins.bot==2 and not last(a).online.forfeit)
	assert(one.root.Anchored and two.root.Anchored)
	assert(aiCreated==ai and d.ai==nil,"a new round created an AI")
end)

test("a client resync (Ready) gets the packet of its current online phase",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local function ready(p) m.sessions[p].bucket.tokens=100;m:request(p,{action="Ready"});return last(p) end
	lifecycle(m,a,"Host",{player="Lion"})
	local code=last(a).online.code
	local packet=ready(a)
	assert(packet.phase=="Queue" and packet.online.code==code and packet.epoch==m.sessions[a].epoch)
	lifecycle(m,b,"Join",{player="Mirage",code=code})
	packet=ready(b)
	assert(packet.phase=="Pick" and packet.online.me=="Mirage" and packet.online.them=="Lion")
	send(m,a,"Confirm");send(m,b,"Confirm")
	packet=ready(b)
	local d=duelOf(m,b)
	assert(packet.phase=="Duel" and packet.human.id==d.seats[2].actor.id and packet.bot.id==d.seats[1].actor.id and packet.epoch==d.epoch)
end)

test("rematch needs both players and rebuilds a fresh fight",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b)
	d.introUntil=nil
	d.combat:damage(d.seats[2].actor,d.seats[1].actor,1000,false,false);step(m,2.7)
	d.introUntil=nil
	d.combat:damage(d.seats[2].actor,d.seats[1].actor,1000,false,false);step(m,2.3)
	assert(d.phase=="Result")
	local oldFolder,oldActor,arenasBefore,epoch=d.folder,d.seats[1].actor,arenas,d.epoch
	lifecycle(m,a,"Rematch")
	assert(d.phase=="Result" and d.seats[1].rematch and last(b).online.theirRematch and last(a).online.rematch)
	lifecycle(m,a,"Rematch")
	assert(d.phase=="Result","one player's double rematch started the fight")
	lifecycle(m,b,"Rematch")
	assert(d.phase=="Duel" and d.epoch>epoch and arenas==arenasBefore+1 and oldFolder.Parent==nil)
	local one=d.seats[1].actor
	assert(one~=oldActor and one.health==one.def.Health and d.round==1 and d.wins[one.id]==0 and a.Character==one.model)
	assert(not d.seats[1].rematch and not d.seats[2].rematch and last(a).phase=="Duel" and last(a).epoch==d.epoch)
end)

test("leaving and disconnecting clean up queue, codes, pick, fight and stage",function()
	local m=fresh()
	local a,b,c,e=join(m,"Alpha","Bravo","Charlie","Echo")
	-- Pick abandoned: the other player is sent back with the reason.
	lifecycle(m,a,"Queue",{player="Flashstep"});lifecycle(m,b,"Queue",{player="Mirage"})
	local picked=duelOf(m,a)
	lifecycle(m,a,"Cancel")
	assert(m.sessions[a].phase=="Selection" and m.sessions[b].phase=="Selection" and last(b).notice=="OPPONENT LEFT")
	assert(not m.sessions[a].online and not m.sessions[b].online and count(m.online.duels)==0)
	assert(m.sessions[b].epoch>picked.epoch and table.find(m.online.freeLanes,picked.lane))
	-- Disconnect mid-fight: forfeit to the player who stays, body kept for the result.
	local d=fight(m,a,b)
	assert(d.lane==picked.lane,"a freed lane was not reused")
	d.introUntil=nil
	local one,two=d.seats[1].actor,d.seats[2].actor
	m:remove(a)
	assert(m.sessions[a]==nil and a.Character==nil and one.model.Parent~=nil)
	assert(d.phase=="Result" and d.forfeit and d.winner==two.id)
	assert(last(b).phase=="Result" and last(b).winner=="PlayerFighter" and last(b).online.forfeit and last(b).online.opponentLeft)
	lifecycle(m,b,"Rematch")
	assert(d.phase=="Result" and not d.seats[2].rematch,"rematch offered against a player who left")
	local folder=d.folder
	lifecycle(m,b,"Selection")
	assert(m.sessions[b].phase=="Selection" and m.sessions[b].epoch>d.epoch and b.Character==nil)
	assert(count(m.online.duels)==0 and folder.Parent==nil and d.combat==nil and table.find(m.online.freeLanes,d.lane))
	-- Queued then gone: nobody is paired with a ghost.
	lifecycle(m,c,"Queue",{player="Lion"})
	m:remove(c)
	assert(#m.online.queue==0)
	lifecycle(m,e,"Queue",{player="Lion"})
	assert(m.sessions[e].phase=="Queue" and not duelOf(m,e) and #m.online.queue==1)
	lifecycle(m,e,"Cancel")
	-- A host who leaves takes the code away.
	lifecycle(m,e,"Host",{player="Lion"})
	local code=last(e).online.code
	m:remove(e)
	assert(m.online.codes[code]==nil)
	local f=join(m,"Foxtrot")
	lifecycle(m,f,"Join",{player="Lion",code=code})
	assert(m.sessions[f].phase=="Selection" and last(f).notice=="NO PRIVATE DUEL WITH THIS CODE")
end)

test("a decided knockout keeps its winner when that winner disconnects during the beat",function()
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	local d=fight(m,a,b)
	d.introUntil=nil
	local one,two=d.seats[1].actor,d.seats[2].actor
	d.wins[two.id]=1
	d.combat:damage(two,one,1000,false,false)
	assert(d.finishing and d.matchPoint)
	m:remove(b)
	assert(d.phase=="Result" and d.winner==two.id and not d.forfeit)
	assert(last(a).winner=="AIFighter" and last(a).online.opponentLeft and not last(a).online.forfeit)
	step(m,2)
	assert(d.phase=="Result","the pending KO beat restarted a finished duel")
	lifecycle(m,a,"Selection")
	assert(count(m.online.duels)==0)
end)

test("the local AI duel keeps its contract on the shared helpers",function()
	local m=fresh()
	local p=join(m,"Solo")
	local ai=aiCreated
	assert(m:start(p,"Flashstep","Mirage"))
	local s=m.sessions[p]
	assert(aiCreated==ai+1 and s.ai and not s.online and s.human.id=="PlayerFighter" and s.bot.id=="AIFighter")
	assert(p.Character==s.human.model and s.human.locked and s.bot.locked)
	assert(last(p).human.id=="PlayerFighter" and last(p).bot.id=="AIFighter" and last(p).online==nil)
	s.introUntil=nil
	AntiCheat.clear(s.human)
	send(m,p,"Move",{direction=V.xAxis})
	assert(s.human.move==V.xAxis,"the local duel no longer takes the player's input")
	s.combat:damage(s.human,s.bot,1000,false,false)
	assert(s.finishing and last(p).winner=="PlayerFighter" and last(p).wins.human==1)
	local epoch=s.epoch
	step(m,2.7)
	assert(s.round==2 and s.epoch==epoch+1 and aiCreated==ai+2 and last(p).epoch==s.epoch and last(p).wins.human==1)
	assert(s.human.root.Position.Z>s.bot.root.Position.Z)
	-- Queue requests are refused outside the roster.
	lifecycle(m,p,"Queue",{player="Flashstep"})
	assert(s.phase=="Duel" and not s.online and #m.online.queue==0)
	m:selection(p)
	assert(s.phase=="Selection" and not s.combat)
end)

test("Studio latency simulation delays each player's requests in order and can be turned off",function()
	local t=0
	local latency,jitter=0,0
	local rolls={1,0,.5}
	local roll=0
	local seen={}
	local fake={request=function(_,player,payload) table.insert(seen,{player=player,id=payload.id,at=t}) end}
	local flush=DevHooks.delayRequests(fake,function() return latency,jitter end,function() return t end,function() roll+=1;return rolls[(roll-1)%#rolls+1] end)
	local p,q={Parent=true},{Parent=true}
	fake:request(p,{id=0});assert(#seen==1 and seen[1].at==0,"no latency must pass straight through")
	latency,jitter=100,40
	fake:request(p,{id=1}) -- due 0.140
	fake:request(p,{id=2}) -- rolled 0.060, held behind id 1
	fake:request(q,{id=3}) -- due 0.100, another player's own lane
	t=.099;flush();assert(#seen==1)
	t=.1;flush();assert(#seen==2 and seen[2].id==3)
	t=.14;flush();assert(#seen==4 and seen[3].id==1 and seen[4].id==2,"reliable order lost")
	latency,jitter=0,0
	fake:request(p,{id=4});assert(#seen==5 and seen[5].id==4)
	-- A player who left drops their pending requests.
	latency=50;fake:request(q,{id=5});q.Parent=nil;t=1;flush();assert(#seen==5)
end)

test("the client UI renders the real roster, queue, pick, duel and result packets",function()
	-- Real Roblox value types for the GUI layout; a 1600x900 viewport.
	H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim
	H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	H.workspace.GetAttribute=function() return nil end
	local UI=H.load("Client/UI")
	local sent={}
	local ui=UI.new(baseNew("PlayerGui"),function(action,extra) table.insert(sent,{action=action,extra=extra}) end)
	local function lastSent() return sent[#sent] end
	assert(ui.selection.Visible and ui.onlineRow.Visible and not ui.queue.Visible and ui.opponentLabel.Text=="OPPONENT (AI)")
	ui.selectionButtons.playerLion.click()
	ui.queueButton.click()
	assert(lastSent().action=="Queue" and lastSent().extra.player=="Lion")
	ui.hostButton.click();assert(lastSent().action=="Host" and lastSent().extra.player=="Lion")
	ui.codeBox.Text="k7qx2";ui.joinButton.click();assert(lastSent().action=="Join" and lastSent().extra.code=="k7qx2")
	-- The same packets the server sends, rendered from one player's side.
	local m=fresh()
	local a,b=join(m,"Alpha","Bravo")
	lifecycle(m,a,"Queue",{player="Lion"})
	ui:render(last(a))
	assert(ui.queue.Visible and not ui.selection.Visible and ui.queueTitle.Text=="SEARCHING FOR AN OPPONENT" and ui.queueCode.Text=="")
	ui.cancelButton.click();assert(lastSent().action=="Cancel")
	lifecycle(m,b,"Queue",{player="Mirage"})
	ui:render(last(a))
	assert(ui.selection.Visible and not ui.queue.Visible and ui.picking and not ui.onlineRow.Visible)
	assert(ui.startButton.Text=="READY" and ui.tutorialButton.Text=="LEAVE" and ui.opponentLabel.Text:find("BRAVO",1,true))
	assert(ui.notice.Text:find("STARTS IN",1,true) and ui.matchup.Text:find("ITACHI",1,true),"the opponent's pick is not on screen")
	local bot=ui.bot
	ui.selectionButtons.botLion.click();assert(ui.bot==bot,"the opponent's half changed the local AI pick")
	ui.selectionButtons.playerGentleFist.click()
	assert(lastSent().action=="Pick" and lastSent().extra.player=="GentleFist" and ui.player=="GentleFist")
	send(m,a,"Pick",lastSent().extra)
	ui.startButton.click();assert(lastSent().action=="Confirm")
	send(m,a,"Confirm");ui:render(last(a))
	assert(ui.startButton.Text:find("WAITING",1,true))
	local count=#sent
	ui.selectionButtons.playerLion.click();assert(#sent==count and ui.player=="GentleFist","a confirmed pick still changed")
	ui.tutorialButton.click();assert(lastSent().action=="Cancel")
	send(m,b,"Confirm")
	local d=duelOf(m,a)
	ui:render(last(a))
	assert(ui.intro.Visible and ui.introLeftName.Text:find("NEJI",1,true) and ui.introRightName.Text:find("ITACHI",1,true))
	d.introUntil=nil;step(m,.1);ui:render(last(a))
	assert(ui.hud.Visible and not ui.intro.Visible and ui.enemy.title.Text:find("BRAVO",1,true) and ui.hp.title.Text:find("YOU",1,true))
	assert(ui.hp.name.Text:find("NEJI",1,true) and ui.enemy.name.Text:find("ITACHI",1,true))
	-- Two knockouts for Alpha: VICTORY from Alpha's side.
	for _=1,2 do d.introUntil=nil;d.combat:damage(d.seats[1].actor,d.seats[2].actor,1000,false,false);step(m,2.7) end
	ui:render(last(a))
	assert(ui.result.Visible and ui.resultTitle.Text:find("VICTORY",1,true) and ui.rematchButton.Text=="REMATCH")
	lifecycle(m,b,"Rematch");ui:render(last(a))
	assert(ui.rematchButton.Text:find("OPPONENT IS READY",1,true))
	m:remove(b);ui:render(last(a))
	assert(ui.rematchButton.Text=="OPPONENT LEFT")
	lifecycle(m,a,"Selection");ui:render(last(a))
	assert(ui.selection.Visible and not ui.picking and ui.onlineRow.Visible and ui.startButton.Text=="ENTER THE STAGE" and ui.opponentLabel.Text=="OPPONENT (AI)")
	-- A forfeit and a pick abandoned by the opponent both say so.
	local c,e=join(m,"Charlie","Echo")
	d=fight(m,c,e)
	m:remove(e);ui:render(last(c))
	assert(ui.result.Visible and ui.resultTitle.Text=="VICTORY  •  FORFEIT" and ui.resultNote.Text:find("left the duel",1,true))
	lifecycle(m,c,"Selection")
	local f=join(m,"Foxtrot")
	lifecycle(m,c,"Host",{player="Lion"});ui:render(last(c))
	assert(ui.queue.Visible and ui.queueTitle.Text=="PRIVATE DUEL" and ui.queueCode.Text==last(c).online.code)
	lifecycle(m,f,"Join",{player="Lion",code=last(c).online.code})
	lifecycle(m,f,"Cancel");ui:render(last(c))
	assert(ui.selection.Visible and ui.notice.Text=="OPPONENT LEFT")
	-- The local AI duel still reads as the AI.
	local p=join(m,"Solo")
	m:start(p,"Flashstep","Mirage");m.sessions[p].introUntil=nil;step(m,.1);ui:render(last(p))
	assert(ui.hud.Visible and ui.enemy.title.Text:sub(1,2)=="AI" and ui.rematchButton.Text~=nil)
end)

print(string.format("NinjaDuel online 1v1: %d PASS (server lifecycle/authority; replication, latency and two-client Studio still required)",passed))
