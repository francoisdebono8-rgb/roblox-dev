-- Debug/QA places only (build.py DEBUG_SOURCES): QA-004 gate scenarios run
-- in the real build (native physics, real stage, real Combat) on the live
-- session, from the Server command bar:
--   workspace:SetAttribute("NinjaDuelGate","M1,M2")  (DevHooks runs it here)
-- Each scenario starts its own duel through the dev hook, drives both sides
-- through Combat:request (the remote's own entry point) and prints PASS/FAIL
-- with what was measured. It proves server behaviour in the native world;
-- real keys, the look and human feel are separate checks.
local ServerStorage=game:GetService("ServerStorage")
local LogService=game:GetService("LogService")
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local DevHooks=require(script.Parent.DevHooks)
local Bodies=require(script.Parent.Bodies)
local Brawler=require(script.Parent.Brawler)

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function slot(id,tech)
	for i,spec in Fighters[id].Techniques do if spec.Id==tech then return "Technique"..i,spec end end
	error(id.." has no "..tech)
end
local dev
local function session()
	for _,s in DevHooks.matches.sessions do if s.combat then return s end end
end
local function start(a,b)
	dev:Invoke("start",a,b)
	local t0=os.clock()
	repeat task.wait(.2);local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
	dev:Invoke("health","bot",400)
	local s=session()
	return s.combat,s.human,s.bot,s
end
local function place(c,a,b,pa,pb)
	local o=c.match.origin
	c:relocate(a,o+pa);c:relocate(b,o+pb)
	a.root.CFrame=CFrame.lookAt(a.root.Position,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
	b.root.CFrame=CFrame.lookAt(b.root.Position,Vector3.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
	a.move=Vector3.zero;b.move=Vector3.zero
	task.wait(.2)
end
local function confirmOne(c,a)
	c:request(a,"Attack")
	local t=os.clock()
	repeat task.wait() until (a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0)) or os.clock()-t>1
end

local S={}
-- M1 ----------------------------------------------------------------------
S.S1=function()
	local c,a,b=start("Puppet","Leaf");place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5));a.chakra=999
	c:request(a,(slot("Puppet","Marionette")),b.root.Position);task.wait(.8)
	local p=Bodies.of(c,a,"puppet")[1];if not p then return false,"no marionette" end
	place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5))
	confirmOne(c,a);c:request(a,"Heavy")
	local carried=a.attackName=="PuppetBlade" and a.pending and a.pending.body==p
	task.wait(2)
	return carried and p.alive and p.mode=="marionette",string.format("carried=%s alive=%s mode=%s",tostring(carried),tostring(p.alive),tostring(p.mode))
end
S.S2=function()
	local c,a,b=start("Puppet","Leaf");place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5));a.chakra=999
	c:request(a,(slot("Puppet","Marionette")),b.root.Position);task.wait(.8)
	local p=Bodies.of(c,a,"puppet")[1];if not p then return false,"no marionette" end
	place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5))
	confirmOne(c,a);confirmOne(c,a)
	a.move=flat(b.root.Position-a.root.Position).Unit;c:request(a,"Attack");a.move=Vector3.zero
	local route=a.attackName
	task.wait(2)
	return route=="PuppetRise" and p.alive and p.mode=="marionette",string.format("route=%s alive=%s mode=%s",tostring(route),tostring(p.alive),tostring(p.mode))
end
S.S3=function()
	local c,a,b=start("Puppet","Leaf");place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5));a.chakra=999
	c:request(a,(slot("Puppet","Marionette")),b.root.Position);task.wait(.8)
	local p=Bodies.of(c,a,"puppet")[1];if not p then return false,"no marionette" end
	place(c,a,b,Vector3.new(0,3,3.5),Vector3.new(0,3,-3.5))
	confirmOne(c,a);c:request(a,"Heavy")
	Brawler.react(c,a,"HitStun",Vector3.zero,.4,b)
	task.wait(1)
	return p.alive and p.mode=="marionette" and not p.carry,string.format("alive=%s mode=%s carry=%s",tostring(p.alive),tostring(p.mode),tostring(p.carry~=nil))
end
S.S4=function()
	local out={}
	for _,guarding in {true,false} do
		local c,a,b=start("Puppet","Leaf");place(c,a,b,Vector3.new(0,3,10),Vector3.new(0,3,-10));a.chakra=999;b.health=400
		c:request(a,(slot("Puppet","Marionette")),b.root.Position)
		local t=os.clock()
		repeat
			if guarding and b.state~="Guarding" then c:request(b,"Guard") end
			task.wait()
		until b.health<400 or os.clock()-t>5
		task.wait(.1)
		table.insert(out,{guarding=guarding,hit=b.health<400,poisoned=(b.poisonedUntil or 0)>0})
	end
	local ok=out[1].hit and not out[1].poisoned and out[2].hit and out[2].poisoned
	return ok,string.format("guard: hit=%s poisoned=%s • open: hit=%s poisoned=%s",tostring(out[1].hit),tostring(out[1].poisoned),tostring(out[2].hit),tostring(out[2].poisoned))
end
S.S5=function()
	local c,a,b,s=start("Puppet","Leaf");place(c,a,b,Vector3.new(0,3,6),Vector3.new(0,3,-6));a.chakra=999
	c:request(a,(slot("Puppet","Marionette")),b.root.Position);task.wait(.5)
	local p=Bodies.of(c,a,"puppet")[1];if not p then return false,"no marionette" end
	Bodies.dispel(c,p,"hit",b);task.wait(.3)
	local broken=#Bodies.of(c,a,"puppet")==0
	-- KO and the next round: nothing left over.
	dev:Invoke("ko","bot")
	task.wait(6)
	local s2=session()
	local left=s2 and s2.combat and #(s2.combat.bodies or {}) or 0
	return broken and left==0,string.format("broken=%s bodies after KO/reset=%d phase=%s",tostring(broken),left,tostring(s2 and s2.phase))
end
-- M2 ----------------------------------------------------------------------
S.S6=function()
	local c,a,b=start("Clay","Leaf");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-20));a.chakra=999
	local s,spec=slot("Clay","ClayMine")
	local o=c.match.origin
	c:request(a,s,o+Vector3.new(-10,3,-15));task.wait(.6)
	local near
	for _,h in c.hazards do if h.a==a then near=flat(h.position-a.root.Position).Magnitude end end
	a.cooldowns={};a.chakra=999
	local before=#c.hazards
	c:request(a,s,o+Vector3.new(0,3,-100));task.wait(.6)
	local far=0
	for _,h in c.hazards do if h.a==a then far=math.max(far,flat(h.position-a.root.Position).Magnitude) end end
	return near~=nil and far<=spec.Range+.5,string.format("aimed at 18: set at %.1f • aimed at 100: furthest %.1f (Range %d, hazards %d→%d)",near or -1,far,spec.Range,before,#c.hazards)
end
S.S8=function()
	local c,a,b=start("Mist","Leaf");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-20));a.chakra=999
	local from=a.root.Position
	local ok=c:request(a,(slot("Mist","SilentKilling")),b.root.Position)
	c:relocate(b,c.match.origin+Vector3.new(0,3,-105))
	task.wait(.7)
	local moved=flat(a.root.Position-from).Magnitude
	return ok and moved<4,string.format("accepted=%s moved=%.1f studs after the body left to 105",tostring(ok),moved)
end
S.S10=function()
	local c,a,b=start("Flicker","Leaf");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-20));a.chakra=999
	c:request(a,(slot("Flicker","BodyFlicker")),b.root.Position);task.wait(.4)
	local arrived=flat(a.root.Position-b.root.Position).Magnitude<6
	place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-80));a.chakra=999;a.cooldowns={}
	local back=c:request(a,(slot("Flicker","FlickerOut")),b.root.Position)
	local c2,a2,b2=start("Mist","Leaf");place(c2,a2,b2,Vector3.new(0,3,0),Vector3.new(0,3,-90));a2.chakra=999
	local chakra=a2.chakra
	local far,why=c2:request(a2,(slot("Mist","SilentKilling")),b2.root.Position)
	local mist=c2:request(a2,(slot("Mist","HiddenMist")))
	return arrived and back and not far and a2.chakra<=chakra and mist,string.format("flicker in range arrived=%s • retreat at 80=%s • kill at 90 refused=%s (%s) • mist Self=%s",
		tostring(arrived),tostring(back),tostring(not far),tostring(why),tostring(mist))
end
-- M3 ----------------------------------------------------------------------
local Families=require(script.Parent.Families)
-- S11/S13: the player (Copycat) stands in the bot Zabuza's mist; Zabuza steps
-- sideways three times (watch the camera: it must not follow him), then the
-- player leaves the mist (the lock comes back).
S.S11=function()
	local c,a,b=start("Copycat","Mist");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-8));b.chakra=999
	c:request(b,(slot("Mist","HiddenMist")));task.wait(1)
	local lost=Families.shrouded(c,a)
	local o=c.match.origin
	for k=1,3 do c:relocate(b,o+Vector3.new(k%2==0 and -7 or 7,3,-8+k));task.wait(1.6) end
	local stillLost=Families.shrouded(c,a)
	c:relocate(a,o+Vector3.new(0,3,30));task.wait(1.5)
	local found=not Families.shrouded(c,a)
	return lost and stillLost and found,string.format("player lost in mist=%s (after 3 side steps=%s) • out of it, found again=%s",tostring(lost),tostring(stillLost),tostring(found))
end
-- S12/S14: inside the mist a manual tool aim goes where it was given (no
-- homing); Zabuza in his own mist is not lost; the bot lost aims at its memory.
S.S12=function()
	local c,a,b=start("Copycat","Mist");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-8));b.chakra=999
	c:request(b,(slot("Mist","HiddenMist")));task.wait(1)
	a.neutralToolAt=0;a.chakra=999
	local wide=b.root.Position+Vector3.new(5,0,0)
	local ok=c:request(a,"Tool",wide)
	local dir
	for _=1,30 do task.wait();for _,p in c.projectiles do if p.a==a then dir=p.direction end end;if dir then break end end
	local toAim,toBody=(wide-a.root.Position).Unit,(b.root.Position-a.root.Position).Unit
	local manual=dir~=nil and dir:Dot(toAim)>dir:Dot(toBody)
	local zabuzaSees=not Families.shrouded(c,b)
	return ok and manual and zabuzaSees,string.format("tool thrown=%s goes to the given aim=%s • Zabuza lost in his own mist=%s",tostring(ok),tostring(manual),tostring(not zabuzaSees))
end
-- M4 ----------------------------------------------------------------------
-- Native baseline of the grid's measures (no tuning). S15: third light then
-- heavy on a body at its HP: distance/time from each contact to the end of
-- its reaction. S16: L1, L2, toward+L (launcher), E, three air strikes, in one
-- sequence without refill or replacement; every request logged. S17: an AI
-- duel; distinct techniques counted by Cast:<Id> events.
local function measure(c,a,b,action,stick)
	local hp=b.health
	if stick then a.move=stick end
	local ok,why=c:request(a,action);a.move=Vector3.zero
	local t0=os.clock();local from,at,push,done=nil,nil,0,nil
	repeat
		task.wait()
		if not from and b.health<hp then from=b.root.Position;at=os.clock() end
		if from then push=math.max(push,flat(b.root.Position-from).Magnitude);if b.reaction==nil then done=os.clock() end end
	until done or os.clock()-t0>2.5
	return ok,why,from~=nil,push,(done and at) and done-at or -1
end
S.S15=function()
	local out={}
	for _,id in {"Lion","Mist","Puppet","Ink"} do
		local c,a,b=start(id,"Leaf");place(c,a,b,Vector3.new(0,3,(id=="Puppet" and 3.5) or 1.7),Vector3.new(0,3,-((id=="Puppet" and 3.5) or 1.7)))
		confirmOne(c,a);confirmOne(c,a)
		local _,_,hit3,push3,react3=measure(c,a,b,"Attack")
		task.wait(.6);place(c,a,b,Vector3.new(0,3,1.7),Vector3.new(0,3,-1.7))
		local _,_,hitH,pushH,reactH=measure(c,a,b,"Heavy")
		table.insert(out,string.format("%s L3 hit=%s push=%.1f react=%.2fs • heavy hit=%s push=%.1f react=%.2fs",id,tostring(hit3),push3,react3,tostring(hitH),pushH,reactH))
	end
	return true,table.concat(out," | ")
end
S.S16=function()
	local out={}
	for _,id in {"Flicker","Bone","Clay"} do
		local c,a,b=start(id,"Leaf");place(c,a,b,Vector3.new(0,3,1.7),Vector3.new(0,3,-1.7))
		local log={}
		confirmOne(c,a);confirmOne(c,a)
		a.move=flat(b.root.Position-a.root.Position).Unit
		local ok,why=c:request(a,"Attack");a.move=Vector3.zero
		table.insert(log,"up="..(if ok then tostring(a.attackName) else tostring(why)))
		task.wait(.35)
		ok,why=c:request(a,"Pursuit");table.insert(log,"E="..(if ok then "ok" else tostring(why)));task.wait(.45)
		local before=b.health;local air=0
		for k=1,3 do
			ok,why=c:request(a,"Attack");table.insert(log,"A"..k.."="..(if ok then tostring(a.attackName) else tostring(why)));task.wait(.35)
			if b.health<before then air+=1;before=b.health end
		end
		local t=os.clock();repeat task.wait() until (not a.airborne and not b.airborne) or os.clock()-t>3
		table.insert(out,id.." "..table.concat(log," ").." air hits="..air.." landed="..tostring(not a.airborne))
	end
	return true,table.concat(out," | ")
end
S.S17=function()
	local c,a,b,s=start("Ink","Leaf")
	dev:Invoke("freezeBot",false);dev:Invoke("scripted",false);dev:Invoke("autopilot",true)
	local t=os.clock();repeat task.wait(.5) until s.phase~="Duel" or os.clock()-t>60
	dev:Invoke("autopilot",false)
	local casts,distinct={},0
	for k,v in a.events or {} do if string.sub(k,1,5)=="Cast:" and v>0 then distinct+=1;table.insert(casts,string.sub(k,6).."×"..v) end end
	return distinct>=1,string.format("duel %.0fs phase=%s • distinct techniques=%d (%s)",os.clock()-t,tostring(s.phase),distinct,table.concat(casts,", "))
end
-- M5 ----------------------------------------------------------------------
-- S18: a mine set 8 studs in front of the player, posed then armed (watch the
-- fuse light), then the body walks on it: one detonation, the charge gone.
S.S18=function()
	local c,a,b=start("Clay","Leaf");place(c,a,b,Vector3.new(0,3,6),Vector3.new(0,3,-12));a.chakra=999
	local o=c.match.origin
	c:request(a,(slot("Clay","ClayMine")),o+Vector3.new(-6,3,-2))
	task.wait(.3)
	local h
	for _,x in c.hazards do if x.a==a and x.charge then h=x end end
	if not h then return false,"no charge" end
	local posed=c.now<(h.armedAt or 0)
	task.wait(1.6)
	local armed=c.now>=(h.armedAt or 0)
	local before=(a.events or {}).Detonation or 0
	c:relocate(b,h.position+Vector3.new(0,2.5,0));task.wait(.8)
	local after=(a.events or {}).Detonation or 0
	local gone=c.now>=h.expires
	return posed and armed and after==before+1 and gone,string.format("posed at 0.3s=%s • armed at 1.9s=%s • detonations=%d • gone=%s",tostring(posed),tostring(armed),after-before,tostring(gone))
end
-- S20/S21: Nagato opens Absorb (watch the sphere), a kunai thrown into it is
-- swallowed (reward: chakra), melee still lands; after it closes a kunai hits.
S.S20=function()
	local c,a,b=start("Rinnegan","Copycat");place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-14));a.chakra=40;b.chakra=999
	c:request(a,(slot("Rinnegan","Absorb")));task.wait(.2)
	local chakra=a.chakra
	b.neutralToolAt=0;c:request(b,"Tool",a.root.Position);task.wait(.6)
	local absorbed=((a.events or {}).Absorbed or 0)>0 and a.chakra>chakra
	place(c,a,b,Vector3.new(0,3,1.7),Vector3.new(0,3,-1.7))
	local hp=a.health;c:request(b,"Attack");task.wait(.4)
	local melee=a.health<hp
	task.wait(2.2)
	local closed=not (a.buff and c.now<a.buff.untilT)
	place(c,a,b,Vector3.new(0,3,0),Vector3.new(0,3,-14))
	hp=a.health;b.neutralToolAt=0;b.chakra=999;c:request(b,"Tool",a.root.Position);task.wait(.8)
	return absorbed and melee and closed and hp-a.health>0,string.format("kunai absorbed (+chakra)=%s • melee still lands=%s • window closed=%s • kunai after close dmg=%.1f",tostring(absorbed),tostring(melee),tostring(closed),hp-a.health)
end
-- M7 ----------------------------------------------------------------------
-- One continuous sequence per fighter, no refill, no replacement after the
-- start (QA-004 M7): walk in, light, light, toward+light (its route), chase
-- (E), air strikes, land, step out, tool, every technique it can pay for in
-- turn (a refused one is logged with its reason), a guard that holds a blow,
-- then a KO and the next round: nothing of the first round left over (buff,
-- stance, slow, poison, zones/charges of his, bodies, cooldowns).
local Roster=require(game:GetService("ReplicatedStorage").NinjaDuel.Roster)
local Rules=require(game:GetService("ReplicatedStorage").NinjaDuel.Rules)
local function Rules_canAct(a,c) return Rules.canAct(a,c.now) end
local function seq(id)
	local c,a,b,s=start(id,"Leaf")
	place(c,a,b,Vector3.new(0,3,7),Vector3.new(0,3,-7))
	dev:Invoke("health","bot",250)
	local log={}
	local fails={}
	local function note(k,v) table.insert(log,k.."="..tostring(v)) end
	-- Every contract is mandatory (Codex audit 5bb52fd..aeff49a, F1): a step
	-- that is refused, whiffs or times out fails the sequence.
	local function need(k,ok) if not ok then table.insert(fails,k) end end
	local MoveGraphs=require(game:GetService("ReplicatedStorage").NinjaDuel.MoveGraphs)
	local graph=MoveGraphs[id] or {}
	-- In reach (the human's own walking is the client's: placed, not walked).
	local reach=((a.def.AttackProfile and a.def.AttackProfile.Light1 and a.def.AttackProfile.Light1.contact) or 3.4)
	place(c,a,b,Vector3.new(0,3,reach/2),Vector3.new(0,3,-reach/2))
	local t=os.clock()
	local hp=b.health
	confirmOne(c,a);confirmOne(c,a)
	note("lights",string.format("%.0f",hp-b.health))
	need("lights",hp-b.health>0 and (b.comboHits or 0)>=2)
	a.move=flat(b.root.Position-a.root.Position).Unit;local ok,why=c:request(a,"Attack");a.move=Vector3.zero
	note("route",if ok then a.attackName else why)
	-- The toward route of its own graph (or the launcher it names, or the
	-- proxy that carries it).
	local up=graph.routes and graph.routes.up
	local proxy=graph.proxy and up and graph.proxy[up]
	local expected={[up or ""]=true,[a.def.LauncherMove or ""]=true,[(proxy and proxy.move) or ""]=true,[(proxy and proxy.solo) or ""]=true}
	need("route",ok and expected[a.attackName or "?"]==true)
	task.wait(.4)
	ok,why=c:request(a,"Pursuit");note("E",if ok then "ok" else why);task.wait(.45)
	-- A route that chases by itself (Sasuke's Lion Kick, Lee's Rising Wind)
	-- refuses E as Committed; any other refusal fails.
	local selfChase=graph.onRoute and up and graph.onRoute[up]~=nil
	need("E",ok or (selfChase and why=="Committed"))
	local airHits,before=0,b.health
	-- Each air strike gets its own time to land (Gaara's lashes are slow).
	for _=1,2 do
		c:request(a,"Attack")
		local ta=os.clock();repeat task.wait() until b.health<before or os.clock()-ta>.6
		if b.health<before then airHits+=1;before=b.health end
	end
	note("air",airHits)
	need("air",airHits>=1)
	t=os.clock();repeat task.wait() until (not a.airborne and Rules_canAct(a,c)) or os.clock()-t>3
	-- Step out and throw.
	local away=flat(a.root.Position-b.root.Position);away=if away.Magnitude>.1 then away.Unit else Vector3.zAxis
	c:relocate(a,b.root.Position+away*12+Vector3.new(0,.1,0));task.wait(.2)
	ok,why=c:request(a,"Tool",b.root.Position);note("tool",if ok then "ok" else why);task.wait(.8)
	-- Lee's tool is a deflecting kick: with nothing thrown at him it refuses.
	need("tool",ok or (a.def.Tool=="Deflect" and why=="Nothing to deflect"))
	-- Every technique, as the reserve allows.
	local casts={}
	for slot,spec in a.def.Techniques do
		t=os.clock();repeat task.wait() until (Rules_canAct(a,c) and a.state=="Neutral") or os.clock()-t>2.5
		local gap=math.clamp((spec.Range or 10)*.45,3.4,14)
		if spec.Family=="Burst" or spec.Family=="Counter" then gap=math.min(gap,(spec.Radius or 6)-1.5) end
		local d=flat(a.root.Position-b.root.Position).Magnitude
		local dir=flat(a.root.Position-b.root.Position);dir=if dir.Magnitude>.1 then dir.Unit else Vector3.zAxis
		if math.abs(d-gap)>2 then c:relocate(a,b.root.Position+dir*math.max(gap,3)+Vector3.new(0,.1,0));task.wait(.15) end
		local hpT,evT=b.health,0
		for _,v in a.events or {} do evT+=v end
		local r1,r2=c:request(a,"Technique"..slot,b.root.Position)
		local effect=false
		local t1=os.clock()
		repeat
			task.wait()
			local ev=0;for _,v in a.events or {} do ev+=v end
			if b.health<hpT or b.reaction or a.buff or a.counterStance or #c.hazards>0 or #(c.bodies or {})>0 or ev>evT+1 then effect=true end
		until os.clock()-t1>1.2
		table.insert(casts,spec.Id..":"..(if r1 then (if effect then "ok" else "noeffect") else tostring(r2)))
		-- A technique that needs a setup (Minato's seal) may refuse with its reason.
		need(spec.Id,(r1 and effect) or (not r1 and spec.Requires~=nil))
	end
	note("jutsu",table.concat(casts,","))
	-- Defence: the bot throws a light at a raised guard.
	t=os.clock();repeat task.wait() until (Rules_canAct(a,c) and a.state=="Neutral") or os.clock()-t>3
	place(c,a,b,Vector3.new(0,3,1.8),Vector3.new(0,3,-1.8))
	-- His own bodies (Sasori's marionette) step out of this check: it is about
	-- his guard, and a marionette that keeps jabbing would keep the bot reacting.
	for _,body in Bodies.of(c,a) do Bodies.dispel(c,body,"expire") end
	-- The bot must be free to strike (its last technique may still hold it:
	-- a water prison, coils, a tentacle, a mist it cannot see through).
	t=os.clock();repeat task.wait() until (b.reaction==nil and Rules_canAct(b,c)) or os.clock()-t>4
	place(c,a,b,Vector3.new(0,3,1.8),Vector3.new(0,3,-1.8))
	-- Held past the parry window, so the blow meets a plain guard (a parry is
	-- its own scenario); a parry, or a sand shield taking it, counts as held.
	c:request(a,"Guard");task.wait(.35)
	local hpA=a.health
	local ev=a.events or {}
	local guardHits,shield=ev.GuardHit or 0,ev.SandShield or 0
	local hit=c:request(b,"Attack")
	local blocked=false
	local t2=os.clock()
	repeat
		task.wait()
		local e=a.events or {}
		if (a.riposteUntil or 0)>c.now or a.impactStyle=="block" or b.state=="Stunned" or (e.GuardHit or 0)>guardHits or (e.SandShield or 0)>shield then blocked=true end
	until blocked or os.clock()-t2>.6
	note("guard",string.format("solicited=%s blocked=%s chip=%.1f",tostring(hit),tostring(blocked),hpA-a.health))
	need("guard",hit and blocked)
	c:request(a,"GuardOff")
	-- KO and the next round.
	dev:Invoke("ko","bot")
	t=os.clock();repeat task.wait(.2) until s.round and s.round>=2 and s.phase=="Duel" or os.clock()-t>10
	local c2=s.combat
	local mine=0
	for _,h in c2.hazards do if h.a==a then mine+=1 end end
	local bodies=#(c2.bodies or {})
	local leftover=(a.buff~=nil) or (a.counterStance~=nil) or ((a.slowUntil or 0)>c2.now) or ((a.poisonedUntil or 0)>c2.now) or mine>0 or bodies>0
	local cools=0
	for _,v in a.cooldowns or {} do if v>c2.now then cools+=1 end end
	for _,v in b.cooldowns or {} do if v>c2.now then cools+=1 end end
	local theirs=(b.buff~=nil) or ((b.slowUntil or 0)>c2.now) or ((b.poisonedUntil or 0)>c2.now) or b.reaction=="Bound"
	note("reset",string.format("round=%s phase=%s clean=%s cooldowns=%d",tostring(s.round),tostring(s.phase),tostring(not leftover and not theirs),cools))
	need("reset",(s.round or 0)>=2 and s.phase=="Duel" and not leftover and not theirs and cools==0)
	if #fails>0 then table.insert(log,"FAILED["..table.concat(fails,",").."]") end
	return #fails==0,table.concat(log," ")
end
for _,id in Roster do S["Q:"..id]=function() return seq(id) end end
local everyone={}
for _,id in Roster do table.insert(everyone,"Q:"..id) end
-- NEW (DEC-026 newcomers, Shared/RosterStaging): the M7 sequence for each,
-- then its own body checks in the native world: side after one and away
-- after two are its own routes, a clean block is answered with its own
-- riposte gesture, its counter stance answers a blow with a strike that
-- lands, and (Madara, Hiruzen) the Katon cone burns ahead and not at the flank.
local Staging=require(game:GetService("ReplicatedStorage").NinjaDuel.RosterStaging)
local MoveGraphs=require(game:GetService("ReplicatedStorage").NinjaDuel.MoveGraphs)
local function body(id)
	local log={}
	local pass=true
	local function check(name,ok,detail) table.insert(log,name.."="..(if ok then "ok" else "NO").."("..tostring(detail)..")");pass=pass and ok end
	local g=MoveGraphs[id]
	local c,a,b=start(id,"Leaf")
	local reach=a.def.AttackProfile.Light1.contact
	place(c,a,b,Vector3.new(0,3,reach/2),Vector3.new(0,3,-reach/2))
	confirmOne(c,a)
	a.move=a.root.CFrame.RightVector;c:request(a,"Attack");a.move=Vector3.zero
	check("side",a.attackName==g.routes.side,a.attackName)
	task.wait(1.2)
	place(c,a,b,Vector3.new(0,3,reach/2),Vector3.new(0,3,-reach/2))
	confirmOne(c,a);confirmOne(c,a)
	a.move=flat(a.root.Position-b.root.Position).Unit;c:request(a,"Attack");a.move=Vector3.zero
	check("away",a.attackName==g.routes.down,a.attackName)
	task.wait(1.4)
	-- Riposte: the bot strikes a raised guard.
	place(c,a,b,Vector3.new(0,3,1.8),Vector3.new(0,3,-1.8))
	c:request(a,"Guard");task.wait(.25)
	c:request(b,"Attack")
	local t=os.clock();repeat task.wait() until a.impactStyle=="block" or os.clock()-t>.6
	c:request(a,"Attack")
	check("riposte",a.attackName==g.riposte,a.attackName)
	task.wait(1.2)
	-- Counter stance.
	local counter
	for i,spec in a.def.Techniques do if spec.Family=="Counter" then counter=i end end
	place(c,a,b,Vector3.new(0,3,1.8),Vector3.new(0,3,-1.8));dev:Invoke("refill")
	c:request(a,"Technique"..counter);task.wait(.12)
	local hp=b.health
	c:request(b,"Attack")
	t=os.clock();repeat task.wait() until a.attackName==a.def.Techniques[counter].Move or os.clock()-t>.8
	local answered=a.attackName
	task.wait(.7)
	check("counter",answered==a.def.Techniques[counter].Move and b.health<hp,string.format("%s dmg=%.1f",tostring(answered),hp-b.health))
	-- Katon cone.
	for i,spec in a.def.Techniques do
		if spec.Family=="Burst" and spec.Arc then
			task.wait(1);dev:Invoke("refill")
			place(c,a,b,Vector3.new(0,3,4),Vector3.new(0,3,-4))
			hp=b.health;c:request(a,"Technique"..i,b.root.Position);task.wait(.9)
			local front=hp-b.health
			task.wait(spec.Cooldown+.2);dev:Invoke("refill")
			place(c,a,b,Vector3.new(0,3,4),Vector3.new(0,3,-4))
			-- The aim is taken before the body moves to the flank (the caster's
			-- auto-facing turns him toward it within a frame).
			local ahead=a.root.Position+a.root.CFrame.LookVector*8
			c:relocate(b,a.root.Position+a.root.CFrame.RightVector*7);task.wait(.15)
			hp=b.health;c:request(a,"Technique"..i,ahead);task.wait(.9)
			check("katon",front>0 and hp-b.health==0,string.format("front=%.1f flank=%.1f",front,hp-b.health))
		end
	end
	return pass,table.concat(log," ")
end
local newcomers={}
for _,id in Staging do
	S["Q:"..id]=function() return seq(id) end
	S["N:"..id]=function() return body(id) end
	table.insert(newcomers,"Q:"..id);table.insert(newcomers,"N:"..id)
end
-- Negative controls (Codex F1): the verdict must fail when a contract is
-- broken. NEG1 refuses the human's every Attack (no string, no route, no air);
-- NEG2 has the bot never strike the raised guard. Both must print FAIL.
local Combat=require(script.Parent.Combat)
local function withRefusal(filter,fn)
	local orig=Combat.request
	Combat.request=function(self,actor,action,...)
		if filter(actor,action) then return false,"Injected refusal" end
		return orig(self,actor,action,...)
	end
	local ok,pass,detail=pcall(fn)
	Combat.request=orig
	if not ok then error(pass) end
	return pass,detail
end
S.NEG1=function()
	local pass,detail=withRefusal(function(actor,action) return actor.fighterId=="Mirage" and action=="Attack" end,function() return seq("Mirage") end)
	return not pass,"control (must fail): verdict="..(if pass then "PASS" else "FAIL").." • "..tostring(detail)
end
S.NEG2=function()
	local pass,detail=withRefusal(function(actor,action) return actor.fighterId=="Leaf" and action=="Attack" end,function() return seq("Mirage") end)
	return not pass,"control (must fail): verdict="..(if pass then "PASS" else "FAIL").." • "..tostring(detail)
end
local GROUPS={M1={"S1","S2","S3","S4","S5"},M2={"S6","S8","S10"},M3={"S11","S12"},M4={"S15","S16","S17"},M5={"S18","S20"},M7=everyone,NEW=newcomers,NEG={"NEG1","NEG2"}}

return function(list)
	dev=ServerStorage:WaitForChild("NinjaDuelDev",10)
	local errors={}
	local conn=LogService.MessageOut:Connect(function(m,k) if k==Enum.MessageType.MessageError then table.insert(errors,m) end end)
	local lines={}
	for group in string.gmatch(list,"[^,%s]+") do
		for _,name in GROUPS[group] or {group} do
			local fn=S[name]
			local ok,pass,detail=pcall(fn)
			local line=if not ok then name.." ERROR "..tostring(pass) else name.." "..(if pass then "PASS" else "FAIL").." • "..tostring(detail)
			print("[GateCheck] "..line);table.insert(lines,line)
		end
	end
	conn:Disconnect()
	print("[GateCheck] errors in Output during the run: "..#errors..(if #errors>0 then " • "..errors[1] else ""))
	return table.concat(lines,"\n")
end
