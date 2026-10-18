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
	return absorbed and melee and closed,string.format("kunai absorbed (+chakra)=%s • melee still lands=%s • window closed=%s • kunai after close dmg=%.1f",tostring(absorbed),tostring(melee),tostring(closed),hp-a.health)
end
local GROUPS={M1={"S1","S2","S3","S4","S5"},M2={"S6","S8","S10"},M3={"S11","S12"},M4={"S15","S16","S17"},M5={"S18","S20"}}

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
