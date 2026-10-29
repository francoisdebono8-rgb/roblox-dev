-- Ultimates (stage 6, the approved move list, "Ultimes"): one per main
-- fighter, R1 + L1 on the pad (Y on the keyboard) when the ultimate bar is
-- full. The bar fills in the fight, by hitting and by being hit (not only
-- while awakened). The ultimate opens with one quick blow: if it lands, both
-- bodies are taken into a 3-4 s sequence (a dedicated camera on the client,
-- the "ultimate" impact); if it misses, the opponent has an opening.
-- Away from the 8 main fighters (no entry below) the button does nothing.
-- On a wall, R1 + L1 is still the wall detach (Combat routes it).
local Ultimates={}
local Shared=game:GetService("ReplicatedStorage").NinjaDuel

Ultimates.MAX=100
-- Bar gain per point of damage dealt / taken (a fight of ~3 rounds gives
-- one or two ultimates a side).
Ultimates.GAIN={Dealt=1.1,Taken=.8}
-- Each ultimate: the opener's reach, its startup, the sequence length, the
-- total damage (Blows blows of its own script, then the last blow), the camera beat
-- the client plays (kind) and how the opener reaches (Lunge: he arrives in
-- front of the body; Gaze/Sand: from where he stands).
Ultimates.DEFS={
	Naruto={Name="THOUSAND CLONES",Reach=10,Startup=.24,Time=3.4,Blows=9,Damage=30,Kind="clones",Opener="Lunge"},
	Sasuke={Name="CHIDORI: LION'S STRIKE",Reach=12,Startup=.3,Time=3.2,Blows=5,Damage=32,Kind="lion",Opener="Lunge"},
	Gaara={Name="IMPERIAL DESERT FUNERAL",Reach=26,Startup=.42,Time=3.6,Blows=5,Damage=34,Kind="pyramid",Opener="Sand"},
	["Rock Lee"]={Name="HIDDEN LOTUS",Reach=9,Startup=.2,Time=3.4,Blows=7,Damage=34,Kind="lotus",Opener="Lunge"},
	Neji={Name="128 PALMS",Reach=8,Startup=.24,Time=3.4,Blows=12,Damage=30,Kind="palms",Opener="Lunge"},
	Itachi={Name="TSUKUYOMI",Reach=20,Startup=.32,Time=3.6,Blows=4,Damage=28,Kind="tsukuyomi",Opener="Gaze"},
	Minato={Name="YELLOW FLASH",Reach=22,Startup=.16,Time=3.2,Blows=10,Damage=30,Kind="flash",Opener="Lunge"},
	Kakashi={Name="CHIDORI: RAIKIRI",Reach=22,Startup=.3,Time=3.2,Blows=3,Damage=34,Kind="raikiri",Opener="Lunge"},
}
function Ultimates.def(a)
	return Ultimates.DEFS[a.def.Name]
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end

-- Combat:damage, once the amount is final: both bodies fill their bar.
function Ultimates.gain(c,attacker,victim,amount)
	if attacker==victim or amount<=0 or victim.ultimateHeld then return end
	if Ultimates.def(attacker) and not attacker.ultimateRunning then
		attacker.ultimate=math.min(Ultimates.MAX,(attacker.ultimate or 0)+amount*Ultimates.GAIN.Dealt)
	end
	if Ultimates.def(victim) and not victim.ultimateRunning and not victim.ultimateHeld then
		victim.ultimate=math.min(Ultimates.MAX,(victim.ultimate or 0)+amount*Ultimates.GAIN.Taken)
	end
end
function Ultimates.ready(a)
	return Ultimates.def(a)~=nil and (a.ultimate or 0)>=Ultimates.MAX
end

-- R1 + L1: start the ultimate (the bar is spent at the press).
function Ultimates.start(c,a)
	local Brawler=require(script.Parent.Brawler)
	local u=Ultimates.def(a)
	if not u then return false,"No ultimate" end
	if (a.ultimate or 0)<Ultimates.MAX then return false,"Ultimate not ready" end
	if not Brawler.free(a,c.now) then return false,"Busy" end
	local b=a.target
	if not b or b.health<=0 then return false,"No target" end
	local gap=flat(b.root.Position-a.root.Position)
	if gap.Magnitude>u.Reach or not c:lineOfSight(a,b) then return false,"Out of range" end
	a.ultimate=0
	a.pending=nil;a.guardHeld=false
	c:setState(a,"Startup",u.Startup)
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+u.Startup)
	local face=if gap.Magnitude>.1 then gap.Unit else flat(a.root.CFrame.LookVector)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face)
	c:pushImpact(a.root.Position,"ultimateStart",true,{owner=a.id,fighter=a.fighterId,kind=u.Kind,name=u.Name})
	c:cue(a,u.Name,1.2)
	Brawler.event(c,a,"UltimateStart")
	c:schedule(c.now+u.Startup,function() Ultimates.connect(c,a,b,u) end)
	return true
end

-- The opener's moment: it reaches or it misses.
function Ultimates.connect(c,a,b,u)
	local Brawler=require(script.Parent.Brawler)
	if a.health<=0 or c.match.phase~="Duel" or c.match.finishing then return end
	if a.reaction then return end -- hit out of the startup: the ultimate is lost
	local gap=flat(b.root.Position-a.root.Position)
	local missed=b.health<=0 or gap.Magnitude>u.Reach*1.25 or (b.invulnerableUntil or 0)>c.now or b.state=="Dodging"
		or (b.rotationUntil or 0)>c.now or not c:lineOfSight(a,b)
	if missed then
		-- The opening: a long recovery, the bar is gone.
		c:setState(a,"Recovery",1.0)
		c:cue(a,"ULTIMATE MISSED",.9);c:cue(b,"OPENING",.8)
		c:pushImpact(a.root.Position,"ultimateMiss",false,{owner=a.id,kind=u.Kind})
		Brawler.event(c,a,"UltimateMiss")
		return
	end
	-- Caught: both bodies belong to the sequence (no input, no damage from
	-- elsewhere), and each fighter plays his own (Ultimates.SCRIPTS).
	local line=if gap.Magnitude>.1 then gap.Unit else flat(a.root.CFrame.LookVector)
	if u.Opener=="Lunge" then
		local from=a.root.Position
		c:relocate(a,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z)-line*3.2)
		c:pushImpact(a.root.Position,"teleport",false,{owner=a.id,from=from,to=a.root.Position,kind=u.Kind})
	end
	Brawler.releaseGrab(b);b.pending=nil;b.guardHeld=false
	a.ultimateRunning=true;b.ultimateHeld=true
	local hold=u.Time+.1
	c:setState(a,"Recovery",hold)
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+hold)
	local seq=Ultimates.sequence(c,a,b,u)
	c:pushImpact(b.root.Position,"ultimate",true,{owner=a.id,victim=b.id,fighter=a.fighterId,kind=u.Kind,name=u.Name,time=u.Time})
	c:cue(a,u.Name,u.Time);c:cue(b,u.Name,u.Time)
	Brawler.event(c,a,"Ultimate")
	Ultimates.SCRIPTS[u.Kind](seq)
	c:schedule(c.now+u.Time-.3,function() seq.finish() end)
end

-- --------------------------------------------------------------- sequences
-- The tools a script plays with. Times are from the catch (seconds).
--   at(t,fn)            run fn at t
--   strike(name,variant) the caster's body plays that strike (client clip)
--   blow(reaction,stun) a blow of the sequence lands: its share of the
--                       damage, the held body's reaction (no push), a contact
--   pin(x,to,t0,t1,air) carry a body from where it is to `to` between t0 and
--                       t1 (Ultimates.step holds it there; air: off the floor)
--   flash(to)           the caster reappears at `to` (a teleport contact)
--   last(reaction,push,move) the final blow at the sequence's end
local function lookAt(x,y)
	x.root.CFrame=CFrame.lookAt(x.root.Position,Vector3.new(y.root.Position.X,x.root.Position.Y,y.root.Position.Z))
end
function Ultimates.sequence(c,a,b,u)
	local Brawler=require(script.Parent.Brawler)
	local t0=c.now
	local seq={c=c,a=a,b=b,u=u,blows=0,ground=b.root.Position.Y}
	local line=flat(b.root.Position-a.root.Position)
	seq.line=if line.Magnitude>.1 then line.Unit else flat(a.root.CFrame.LookVector)
	lookAt(a,b);lookAt(b,a)
	local function alive() return a.health>0 and b.health>0 and c.match.phase=="Duel" and a.ultimateRunning==true end
	function seq.at(t,fn) c:schedule(t0+t,function() if alive() then fn() end end) end
	function seq.strike(name,variant)
		a.attackName=name;a.attackSerial=(a.attackSerial or 0)+1;a.attackVariant=variant
	end
	function seq.blow(reaction,stun,heavy)
		seq.blows+=1
		c.damageTag=u.Name
		c:chip(a,b,u.Damage*.65/u.Blows)
		c.damageTag=nil
		if b.health<=0 or c.match.phase~="Duel" then return end
		b.hitFrom=flat(a.root.Position-b.root.Position)
		Brawler.react(c,b,reaction or "HitStun",Vector3.zero,stun or .5,a)
		c:pushImpact(b.root.Position+Vector3.new(0,.6,0),"ultimateTick",heavy==true,{owner=a.id,victim=b.id,kind=u.Kind,index=seq.blows})
	end
	function seq.pin(x,to,from,till,air)
		x.ultimatePin={from=x.root.Position,to=to,t0=t0+from,t1=t0+till,air=air,face=if x==a then b else a}
	end
	function seq.flash(to)
		local from=a.root.Position
		c:relocate(a,to);lookAt(a,b)
		a.ultimatePin=nil
		c:pushImpact(a.root.Position,"teleport",false,{owner=a.id,from=from,to=a.root.Position,kind=u.Kind})
	end
	function seq.above(height) return Vector3.new(b.root.Position.X,seq.ground+height,b.root.Position.Z) end
	seq.final={reaction="Knockdown",push=Vector3.new(0,22,0),away=46,stun=.9}
	function seq.finish()
		a.ultimateRunning=nil;b.ultimateHeld=nil
		a.ultimatePin=nil;b.ultimatePin=nil
		if b.boundBy==a then b.boundBy=nil;b.boundKind=nil end
		if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then return end
		b.invulnerableUntil=0
		local f=seq.final
		if f.move then seq.strike(f.move,f.variant) end
		local away=flat(b.root.Position-a.root.Position)
		away=if away.Magnitude>.1 then away.Unit else seq.line
		c.damageTag=u.Name
		local landed=c:damage(a,b,u.Damage*.35,true,false)
		c.damageTag=nil
		if c.match.phase~="Duel" or b.health<=0 then return end
		if landed then Brawler.react(c,b,f.reaction,away*f.away+f.push,f.stun,a) end
		c:pushImpact(b.root.Position,"ultimateEnd",true,{owner=a.id,victim=b.id,kind=u.Kind})
		c:setState(a,"Recovery",.35)
		c:schedule(c.now+.36,function() if a.state~="Startup" and a.state~="Active" then a.attackName=nil;a.attackVariant=nil end end)
	end
	return seq
end
-- Server step: a pinned body is carried along its line (no physics of its own).
function Ultimates.step(c)
	for _,x in c.actors do
		local pin=x.ultimatePin
		if pin then
			local k=if pin.t1>pin.t0 then math.clamp((c.now-pin.t0)/(pin.t1-pin.t0),0,1) else 1
			if c.now>=pin.t0 then
				local p=pin.from:Lerp(pin.to,k*k*(3-2*k))
				local face=pin.face and pin.face.root.Position or p+x.root.CFrame.LookVector
				local look=Vector3.new(face.X,p.Y,face.Z)
				x.model:PivotTo(if (look-p).Magnitude>.1 then CFrame.lookAt(p,look) else CFrame.new(p))
				x.root.AssemblyLinearVelocity=Vector3.zero
			end
			if pin.air then x.airborne=true;x.airHold=c.now+.25 end
		end
	end
end

-- One sequence per fighter, as in the anime (the move list, "Ultimes").
Ultimates.SCRIPTS={}
local S=Ultimates.SCRIPTS
-- Naruto: he jumps back and makes the sign; dozens of shadow clones pour in
-- from every side and beat the body (the client draws them); he ends it
-- himself with one punch.
function S.clones(q)
	local a,b=q.a,q.b
	q.pin(a,b.root.Position-q.line*6,0,.2)
	for k=0,8 do q.at(.35+k*.28,function() q.blow(if k%2==0 then "HitStun" else "HitStun",.45,k%3==2) end) end
	q.at(2.85,function() q.pin(a,b.root.Position-q.line*2.4,2.85,2.95) end)
	q.final={move="Heavy",reaction="Knockback",push=Vector3.new(0,18,0),away=70,stun=.8}
end
-- Sasuke: the Chidori in his hand (drawn from the press), driven into the
-- belly; the body is carried up, the Lion Combo kicks in the air, and the
-- heel drives it into the floor.
function S.lion(q)
	local a,b=q.a,q.b
	q.at(0,function() q.strike("ChidoriThrust","Chidori");q.blow("Launched",.6,true) end)
	q.pin(b,q.above(9),0,.55,true)
	q.pin(a,q.above(8)-q.line*2.6,.1,.6,true)
	local kicks={"Air1","Air2","Air1","Air2"}
	for k,name in kicks do q.at(.75+(k-1)*.38,function() q.strike(name);q.blow("Juggled",.5) end) end
	q.at(2.35,function()
		q.strike("AirSpike","LionBarrage")
		q.pin(b,Vector3.new(b.root.Position.X,q.ground,b.root.Position.Z),2.35,2.75,true)
		q.pin(a,Vector3.new(a.root.Position.X,q.ground,a.root.Position.Z)-q.line*1.2,2.4,2.8,true)
	end)
	q.final={move="Slam",variant="LionBarrage",reaction="Spiked",push=Vector3.new(0,-40,0),away=6,stun=1}
end
-- Gaara: the sand closes on the body (the coffin), lifts it inside a rising
-- pyramid, and the hand closes: the funeral.
function S.pyramid(q)
	local a,b=q.a,q.b
	local Brawler=require(script.Parent.Brawler)
	Brawler.react(q.c,b,"Bound",Vector3.zero,q.u.Time,a);b.boundBy=a;b.boundKind="pyramid"
	q.pin(b,q.above(4),.3,2.6,true)
	for k=0,4 do q.at(.35+k*.5,function() q.strike("SandHand");q.blow("Bound",q.u.Time,k==4) end) end
	q.final={move="SandHand",reaction="Knockdown",push=Vector3.new(0,-10,0),away=10,stun=1.1}
end
-- Rock Lee: the gates open, the kick sends the body up, he is behind it in
-- the air (the Shadow of the Dancing Leaf), a flurry up there, and the lotus
-- drives it head first into the ground.
function S.lotus(q)
	local a,b=q.a,q.b
	q.at(0,function() q.strike("LeafRising");q.blow("Launched",.6,true) end)
	q.pin(b,q.above(11),0,.6,true)
	q.pin(a,q.above(10)-q.line*2.4,.15,.7,true)
	for k=0,5 do q.at(.85+k*.24,function() q.strike(if k%2==0 then "Air1" else "Air2");q.blow("Juggled",.45,k==5) end) end
	q.at(2.35,function()
		q.strike("Slam","HiddenLotus")
		q.pin(b,Vector3.new(b.root.Position.X,q.ground,b.root.Position.Z),2.35,2.75,true)
		q.pin(a,Vector3.new(a.root.Position.X,q.ground,a.root.Position.Z)-q.line*1.4,2.4,2.8,true)
	end)
	q.final={move="Slam",variant="HiddenLotus",reaction="Spiked",push=Vector3.new(0,-50,0),away=4,stun=1.1}
end
-- Neji: the eight trigrams under both (the client draws the field), the
-- palms in a doubling count (2, 4, 8 ... 128) and the last one throws.
function S.palms(q)
	local a,b=q.a,q.b
	q.pin(a,b.root.Position-q.line*2.2,0,.15)
	for k=0,11 do q.at(.25+k*.18,function() q.strike(if k%2==0 then "Light1" else "Light2");q.blow("HitStun",.4,k==11) end) end
	q.at(2.6,function() q.strike("PalmThrust") end)
	q.final={move="PalmThrust",reaction="Knockback",push=Vector3.new(0,14,0),away=80,stun=.9}
end
-- Itachi: no blow is seen. The world turns red and black for the body, it
-- stands frozen while the days pass in a second, and it falls.
function S.tsukuyomi(q)
	local a,b=q.a,q.b
	local Brawler=require(script.Parent.Brawler)
	Brawler.react(q.c,b,"HitStun",Vector3.zero,q.u.Time,a)
	for k=0,3 do q.at(.5+k*.7,function() q.blow("HitStun",1,k==3) end) end
	q.final={reaction="Knockdown",push=Vector3.new(0,2,0),away=2,stun=1.4}
end
-- Minato: the yellow flash, everywhere at once: he reappears round the body
-- with a kunai cut each time, and ends it from above.
function S.flash(q)
	local a,b=q.a,q.b
	local cuts={"Light1","DashAttack","Light2","Light3","DashAttack"}
	for k=0,9 do
		q.at(.1+k*.24,function()
			local angle=k*2.4
			q.flash(b.root.Position+Vector3.new(math.cos(angle)*3.2,0,math.sin(angle)*3.2))
			q.strike(cuts[k%#cuts+1]);q.blow("HitStun",.4,k==9)
		end)
	end
	q.at(2.6,function() q.flash(b.root.Position-q.line*2.4+Vector3.new(0,3,0)) end)
	q.final={move="Heavy",reaction="Knockdown",push=Vector3.new(0,-6,0),away=30,stun=1}
end
-- Kakashi: he leaps back, the Raikiri screams in his hand while the body is
-- frozen by the sound, then one charge straight through it.
function S.raikiri(q)
	local a,b=q.a,q.b
	local Brawler=require(script.Parent.Brawler)
	q.pin(a,b.root.Position-q.line*11,0,.3)
	Brawler.react(q.c,b,"HitStun",Vector3.zero,q.u.Time,a)
	for k=0,1 do q.at(.8+k*.6,function() q.blow("HitStun",1.2) end) end
	q.at(2.2,function()
		q.strike("ChidoriThrust","Raikiri")
		q.pin(a,b.root.Position+q.line*2.6,2.2,2.45)
	end)
	q.at(2.35,function() q.blow("HitStun",.6,true) end)
	q.final={move="ChidoriThrust",variant="Raikiri",reaction="Knockback",push=Vector3.new(0,16,0),away=90,stun=.9}
end

return Ultimates
