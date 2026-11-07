-- Naruto Uzumaki (roster wave: Part I, the Chunin Exam to the Valley of the
-- End, 13). The shadow clones on the shared Bodies component: how a clone
-- behaves (at his side, out on a flank, in the Uzumaki Barrage, shaping the
-- Rasengan), his jutsu (Shadow Clone, Rasengan, Multi Shadow Clone), the
-- transformed kunai, and the Nine-Tails chakra that takes the clones away
-- (Bodies.blocked: the cloak has claws instead). Installed into Techniques
-- by its last line, like a client identity layer into Effects.
-- Sheet: docs/characters/NARUTO.md; report: docs/reports/convergence3/NARUTO.md.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Bodies=require(script.Parent.Bodies)
local Legion={}
local CLONE="clone"
local JAB,KICK=Attacks.CloneJab,Attacks.BarrageKick
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function brawler() return require(script.Parent.Brawler) end
local function tune(a) return Bodies.tuning(a,CLONE) end
local function rightOf(a)
	local right=flat(a.root.CFrame.RightVector)
	return if right.Magnitude>.1 then right.Unit else Vector3.xAxis
end
-- Clones come out on alternate sides of him.
local function nextSide(a)
	a.cloneSide=-(a.cloneSide or -1)
	return a.cloneSide
end
local function aside(c,a,side,distance)
	local p=a.root.Position+rightOf(a)*side*(distance or 2.8)
	return Vector3.new(p.X,c.match.origin.Y+3,p.Z)
end
-- The opponent is open to a clone's jab: not swinging, not in a reaction, not
-- under wake-up cover.
local function open(c,b)
	if b.health<=0 or b.reaction or b.groundPose or (b.invulnerableUntil or 0)>c.now then return false end
	return b.state=="Neutral" or b.state=="Guarding" or b.state=="Recovery" or b.state=="TechniqueRecovery" or b.state=="Stunned"
end
-- Persistent clones ---------------------------------------------------------
-- "guard": at his side (a decoy for blades, a partner for the swap and the
-- Rasengan) until the opponent comes close; "flank": out to the opponent's
-- side, a jab (Attacks.CloneJab, judged from the clone) whenever the opponent
-- is open; when Naruto dashes in, a flanking clone rushes the other side.
local function jab(c,body,b)
	local t=c.now-body.actionAt
	if body.state=="Startup" and t>=JAB.startup then
		body.state="Active"
		local reach=tune(body.owner).Reach or 5.4
		if Bodies.hitFrom(c,body,b,{damage=tune(body.owner).Strike or 4,reach=reach+.8,arc=.2,reaction="HitStun",push=10,up=3,stun=JAB.stun,tag="Shadow Clone"}) then
			brawler().event(c,body.owner,"CloneJab")
		end
	elseif body.state=="Active" and t>=JAB.startup+JAB.active then body.state="Recovery"
	elseif body.state=="Recovery" and t>=JAB.startup+JAB.active+JAB.recovery then body.state="Neutral";body.action=nil end
end
local function persistent(c,body,dt)
	local a=body.owner
	local b=a.target
	if not b or b.health<=0 then return end
	local gap=flat(b.root.Position-body.position).Magnitude
	if body.state~="Neutral" then
		jab(c,body,b)
		if body.alive then Bodies.face(body,b.root.Position) end
		return
	end
	if body.mode=="guard" and gap<=12 then body.mode="flank" end
	local goal,speed
	if body.mode=="guard" then
		-- At his side, keeping pace with him even at a sprint.
		goal,speed=aside(c,a,body.side,2.8),math.max(28,(a.locomotion and a.locomotion.Magnitude or 0)*1.25)
	else
		-- Out on the opponent's flank, off the line between the two of them.
		local line=flat(a.root.Position-b.root.Position)
		line=if line.Magnitude>.1 then line.Unit else flat(-b.root.CFrame.LookVector).Unit
		local angle=body.side*100
		speed=if body.rush then 50 else 38
		if a.state=="Rush" and a.rush then
			-- The pincer: Naruto comes in on one angle, the clone on the other.
			if not body.pincer then body.pincer=true;body.nextStrike=c.now+.08 end
			angle=-(a.rush.side or body.side)*70;speed=80
		else body.pincer=nil end
		local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(line)
		goal=b.root.Position+around*4.2
		goal=Vector3.new(goal.X,c.match.origin.Y+3,goal.Z)
	end
	Bodies.move(c,body,goal,speed,dt)
	Bodies.face(body,b.root.Position)
	local reach=tune(a).Reach or 5.4
	if body.mode=="flank" and c.now>=body.nextStrike and gap<=reach and open(c,b) then
		body.rush=nil
		body.state="Startup";body.action="CloneJab";body.variant=nil;body.actionAt=c.now;body.actionSerial+=1
		-- A clone's rhythm: not the same beat twice in a row.
		body.nextStrike=c.now+(tune(a).Every or 1.9)*(.85+((body.id*7+body.actionSerial*3)%5)*.1)
	end
end
-- Uzumaki Barrage clones: they burst out beside the launched body, kick it
-- higher ("U-ZU-MA-") and puff away; Naruto brings the last word down.
local function barrage(c,body,dt)
	local b=body.owner.target
	if not b or b.health<=0 then return end
	local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(body.angle or 0)):VectorToWorldSpace(body.line or Vector3.new(0,0,-1))
	local goal=b.root.Position+around*2.3-Vector3.new(0,1.1,0)
	body.position=c:clamp(body.position:Lerp(goal,math.min(1,dt*18)))
	Bodies.face(body,b.root.Position)
	if body.state=="Startup" and c.now>=body.actionAt+KICK.startup then
		body.state="Active"
		if Bodies.hitFrom(c,body,b,{damage=KICK.damage,reach=4.8,height=6,arc=-1,reaction="Juggled",push=2,up=22,stun=KICK.stun,tag="Uzumaki Barrage"}) then
			brawler().event(c,body.owner,"BarrageKick")
			c:pushImpact(b.root.Position,"uzumaki",false,{owner=body.owner.id,fighter=body.owner.fighterId,syllable=body.syllable})
		end
	elseif body.state=="Active" and c.now>=body.actionAt+KICK.startup+KICK.active then body.state="Recovery" end
end
-- The Rasengan's helper: beside his right hand, shaping the sphere in his
-- palm until the release (or until it is struck: the jutsu falls apart).
local function shape(c,body,dt)
	local a=body.owner
	local p=body.shaping
	if not p or a.pending~=p or a.health<=0 then
		body.shaping=nil;body.cast=nil;body.mode="spent";body.state="Recovery"
		body.expires=math.min(body.expires,c.now+.2)
		return
	end
	local fwd=flat(a.root.CFrame.LookVector)
	fwd=if fwd.Magnitude>.1 then fwd.Unit else Vector3.new(0,0,-1)
	local right=rightOf(a)
	local goal=a.root.Position+right*1.9+fwd*.7
	Bodies.move(c,body,Vector3.new(goal.X,c.match.origin.Y+3,goal.Z),60,dt)
	body.look=-right;body.cast="RasenganShape";body.state="Neutral"
end
-- A clone struck while it shapes the Rasengan: the technique falls apart
-- (the chakra is spent, the cooldown runs, a short recovery to punish).
local function lost(c,body,why,by)
	local a=body.owner
	local p=body.shaping
	if p and a.pending==p and a.state=="TechniqueChannel" and (why=="hit" or why=="blade" or why=="area") then
		a.pending=nil;c:setState(a,"Recovery",.4)
		c:pushImpact(a.root.Position,"rasengan",false,{phase="broken",owner=a.id,fighter=a.fighterId})
		c:cue(a,"RASENGAN • THE CLONE WAS BROKEN",.9)
		if by then c:cue(by,"CLONE BROKEN • NO RASENGAN",.8) end
		brawler().event(c,a,"RasenganBroken")
	end
end
-- The kunai transformed back into a clone near the target (the chakra chord
-- on his tool): it lands on the opponent's flank and strikes at once.
local function kunaiClone(c,p)
	local a=p.a
	local b=a.target
	local at=Vector3.new(p.position.X,c.match.origin.Y+3,p.position.Z)
	local line=flat(a.root.Position-b.root.Position)
	local side=if line.Magnitude>.1 and line.Unit:Cross(Vector3.yAxis):Dot(flat(at-b.root.Position))>=0 then 1 else -1
	local body=Bodies.spawn(c,a,{kind=CLONE,position=at,mode="flank",side=side,delay=0})
	if body then
		-- It pops where the kunai was and hops onto the flank before it strikes.
		body.rush=true;body.nextStrike=c.now+.16
		c:cue(a,"TRANSFORMATION • CLONE",.6)
		brawler().event(c,a,"CloneKunai")
	end
end
-- The Uzumaki Barrage (route payoff of the launcher route UzumakiKick): two
-- more clones keep the body up, and the heavy after the chase is his own
-- finisher (MoveGraphs.Legion.airFinisher: NARUTO UZUMAKI RENDAN).
local function uzumaki(c,a,b,p)
	a.lionUntil=c.now+2.1
	c:cue(a,"U-ZU-MA-KI • E, THEN HEAVY: NARUTO RENDAN",1)
	brawler().event(c,a,"UzumakiBarrage")
	c:pushImpact(b.root.Position,"uzumaki",false,{owner=a.id,fighter=a.fighterId,syllable="U"})
	local line=flat(a.root.Position-b.root.Position)
	line=if line.Magnitude>.1 then line.Unit else Vector3.new(0,0,-1)
	local syllables={"ZU","MA"}
	for k,angle in {125,-125} do
		c:schedule(c.now+.12+k*.18,function()
			if a.health<=0 or b.health<=0 or c.match.phase~="Duel" or not (b.reaction=="Launched" or b.reaction=="Juggled") then return end
			local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(line)
			local body=Bodies.spawn(c,a,{kind=CLONE,position=b.root.Position+around*2.3-Vector3.new(0,1.1,0),ephemeral=true,life=.42,
				mode="barrage",airborne=true,state="Startup",action="BarrageKick"})
			if body then body.line=line;body.angle=angle;body.syllable=syllables[k] end
		end)
	end
end
-- (Move list: "air □ □ △ : U-ZU-MA-KI, ses clones le renvoient au sol")
-- The heavy that ends his air string: two clones burst out above the body,
-- one on each side, and drive it down with their heels while he comes down
-- with it. Free (it is his string, not a jutsu); not under the Nine-Tails
-- chakra (no clones there).
local function drive(c,body,dt)
	local d=body.drive
	local b=d.target
	if not b or b.health<=0 then return end
	local k=math.clamp((c.now-d.t0)/.32,0,1)
	local line=d.line
	local side=line:Cross(Vector3.yAxis)*d.side
	body.position=b.root.Position+side*1.25-line*.4+Vector3.new(0,2.8-1.6*k*k,0)
	body.airborne=true
	local look=flat(b.root.Position-body.position)
	if look.Magnitude>.1 then body.look=look.Unit end
end
function Legion.airDrive(c,a,b)
	if Bodies.blocked(c,a) then return false end
	local line=flat(b.root.Position-a.root.Position)
	line=if line.Magnitude>.1 then line.Unit else flat(a.root.CFrame.LookVector)
	for i,s in {1,-1} do
		c:schedule(c.now+(i-1)*.05,function()
			if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then return end
			local body=Bodies.spawn(c,a,{kind=CLONE,position=b.root.Position+Vector3.new(0,2.8,0)+line:Cross(Vector3.yAxis)*s*1.25,ephemeral=true,life=.55,
				mode="drive",airborne=true,state="Active",action="AirSpike"})
			if body then body.drive={target=b,side=s,line=line,t0=c.now} end
		end)
	end
	c:pushImpact(b.root.Position,"uzumaki",false,{owner=a.id,fighter=a.fighterId,syllable="KI"})
	brawler().event(c,a,"CloneDrive")
	return true
end

-- Multi Shadow Clone: the crowd ---------------------------------------------
-- (06/11, user, after the @piercevile reel: « il envoie une foule de
-- multiclonage ; on peut prendre le corps de n'importe quel clone ») Tajū
-- Kage Bunshin is a crowd: Crowd clones burst out around him in a ripple of
-- smoke, stand a beat in his stance, then run round the opponent and ring
-- him: an inner ring in reach turning one way, an outer ring turning the
-- other. One conductor for the crowd: one strike at a time (CrowdEvery apart),
-- thrown by the clone most behind him (now and then a clone of the outer ring
-- dashes in instead), and a breath (CrowdGrace) after one lands, so the crowd
-- harries him instead of locking him; while Naruto's own strike is out on
-- him, the crowd holds. Each clone still falls to one blow (a wide swing or a
-- dome clears many), and the crowd melts away after CrowdLife.
-- A second press of the key takes the body of any clone (Legion.switch).
local CROWD_MOVES={"Light1","Light2","Light1","Light3"}
local CROWD_RINGS={4.3,7.4}
local CROWD_STARTUP=.18 -- a crowd strike always shows its wind-up this long
local function crowdState(a)
	local st=a.crowd
	if not st then st={next=0,grace=0,serial=0,turn=0};a.crowd=st end
	return st
end
-- The crowd's strike, from the clone that throws it.
local function crowdStrike(c,body,b,dt)
	local spec=Attacks[body.action or ""] or JAB
	local startup=math.max(spec.startup,CROWD_STARTUP)
	local t=c.now-body.actionAt
	if body.state=="Startup" then
		if body.lunge then
			-- From the outer ring: the run in, stopping at arm's length.
			local to=flat(b.root.Position-body.position)
			if to.Magnitude>3.4 then Bodies.move(c,body,body.position+to.Unit*(to.Magnitude-3.3),body.lunge,dt) end
		end
		if t>=startup then
			body.state="Active"
			local tn=tune(body.owner)
			local kick=body.action=="Light3"
			if Bodies.hitFrom(c,body,b,{damage=if kick then tn.CrowdKick or 4 else tn.CrowdStrike or 3,reach=(tn.Reach or 5.4)+.6,arc=.2,
				reaction=if kick then "Knockback" else "HitStun",push=if kick then 30 else 9,up=if kick then 9 else 3,stun=if kick then .45 else .3,tag="Multi Shadow Clone"}) then
				crowdState(body.owner).grace=c.now+(tn.CrowdGrace or .85)
				brawler().event(c,body.owner,"CrowdStrike")
			end
		end
	elseif body.state=="Active" and t>=startup+spec.active then body.state="Recovery"
	elseif body.state=="Recovery" and t>=startup+spec.active+spec.recovery then body.state="Neutral";body.action=nil;body.lunge=nil end
end
-- Once a step for the whole crowd: who strikes next.
local function conduct(c,a,b,st,members)
	if c.now<st.next or c.now<st.grace or not open(c,b) then return end
	if (a.state=="Startup" or a.state=="Active") and flat(a.root.Position-b.root.Position).Magnitude<9 then return end
	local reach=(tune(a).Reach or 5.4)+.4
	local back=flat(-b.root.CFrame.LookVector)
	back=if back.Magnitude>.1 then back.Unit else Vector3.zero
	-- Every fourth strike comes from the outer ring, running in.
	local outerTurn=st.serial%4==3
	local best,score
	for _,body in members do
		if body.state=="Neutral" and not body.carry and body.mode=="crowd" and c.now>=(body.waitUntil or 0) then
			local d=flat(body.position-b.root.Position)
			local gap=d.Magnitude
			local behind=if gap>.1 then d.Unit:Dot(back) else 0
			local s=nil
			if gap<=reach then s=behind+(if outerTurn then 0 else 2)
			elseif gap<=10 then s=behind+(if outerTurn then 2 else -1) end
			if s then
				s+=((body.id*13+st.serial*7)%10)*.03
				if not score or s>score then best,score=body,s end
			end
		end
	end
	if not best then return end
	st.serial+=1
	local far=flat(best.position-b.root.Position).Magnitude>reach
	best.action=if far then "DashAttack" else CROWD_MOVES[(st.serial-1)%#CROWD_MOVES+1]
	best.lunge=if far then 46 else nil
	best.state="Startup";best.variant=nil;best.actionAt=c.now;best.actionSerial+=1
	st.next=c.now+(tune(a).CrowdEvery or .5)*(.8+((best.id*7+st.serial*3)%5)*.1)
end
local function crowd(c,body,dt)
	local a=body.owner
	local b=a.target
	if not b or b.health<=0 then return end
	local st=crowdState(a)
	if st.tick~=c.now then
		st.tick=c.now;st.turn+=.3*dt
		st.members=Bodies.crowd(c,a,CLONE)
		conduct(c,a,b,st,st.members)
	end
	if body.state~="Neutral" then
		crowdStrike(c,body,b,dt)
		if body.alive then Bodies.face(body,b.root.Position) end
		return
	end
	if c.now<(body.waitUntil or 0) then
		-- The beat after the smoke: in his stance, facing the opponent.
		Bodies.face(body,b.root.Position)
		return
	end
	local ring=body.ring or 1
	local angle=(body.slot or 0)+(if ring==1 then st.turn else -st.turn*.7)
	local goal=b.root.Position+Vector3.new(math.cos(angle),0,math.sin(angle))*CROWD_RINGS[ring]
	-- Elbow room: two clones never stand in one spot.
	for _,other in st.members or {} do
		if other~=body and other.alive then
			local d=flat(body.position-other.position)
			if d.Magnitude<1.9 then goal+=(if d.Magnitude>.05 then d.Unit else Vector3.xAxis)*(1.9-d.Magnitude) end
		end
	end
	goal=c:clamp(Vector3.new(goal.X,c.match.origin.Y+3,goal.Z))
	local gap=(goal-body.position).Magnitude
	Bodies.move(c,body,goal,(if gap>3 then 30 else 12)*(body.pace or 1),dt)
	Bodies.face(body,b.root.Position)
end
-- The crowd comes out: clones already out join it, the rest burst out round
-- him in a ripple (front and sides first, never in the lens behind him), and
-- each takes a slot on a ring round the opponent, spread from Naruto's side.
local function massClone(c,a)
	local tn=tune(a)
	local b=a.target
	local st=crowdState(a)
	st.next=c.now+.6;st.grace=0;st.turn=0
	local base=0
	if b then
		local d=flat(a.root.Position-b.root.Position)
		if d.Magnitude>.1 then base=math.atan2(d.Z,d.X) end
	end
	local total=tn.Crowd or 10
	local inner,outer=0,0
	local function seat(body,k)
		body.mode="crowd";body.crowd=true;body.rush=nil
		-- Odd ones on the inner ring, even ones on the outer; the outer slots sit
		-- between the inner ones.
		local half=math.ceil(total/2)
		if k%2==1 then inner+=1;body.ring=1;body.slot=base+2*math.pi*(inner-.5)/half
		else outer+=1;body.ring=2;body.slot=base+2*math.pi*outer/(total-half) end
		body.pace=.9+(k%4)*.07
		body.waitUntil=c.now+.32+k*.02
		body.expires=c.now+(tn.CrowdLife or 9)+k*.05
	end
	local k=0
	for _,body in Bodies.of(c,a,CLONE) do
		if not body.carry and body.mode~="shape" and body.mode~="spent" and k<total then k+=1;seat(body,k) end
	end
	local fresh=total-k
	for i=1,fresh do
		local n=k+i
		c:schedule(c.now+i*.028,function()
			if a.health<=0 or c.match.phase~="Duel" or Bodies.blocked(c,a) then return end
			local t=a.target
			local fwd=flat(if t then t.root.Position-a.root.Position else a.root.CFrame.LookVector)
			fwd=if fwd.Magnitude>.1 then fwd.Unit else Vector3.new(0,0,-1)
			-- -150° to +150° from the line to the opponent, two rows.
			local spread=if fresh>1 then -150+(i-1)*300/(fresh-1) else 0
			local dir=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(spread)):VectorToWorldSpace(fwd)
			local at=a.root.Position+dir*(if i%2==1 then 3.4 else 5.8)
			local body=Bodies.spawn(c,a,{kind=CLONE,position=Vector3.new(at.X,c.match.origin.Y+3,at.Z),mode="crowd",crowd=true,side=if spread>=0 then 1 else -1,delay=1,
				life=(tn.CrowdLife or 9)+n*.05})
			if body then seat(body,n);Bodies.face(body,if t then t.root.Position else at+fwd) end
		end)
	end
	c:cue(a,"MULTI SHADOW CLONE • "..total.." CLONES",.9)
	brawler().event(c,a,"MassShadowClone")
end
-- Taking a clone's body (the key again with the crowd out). The stick picks
-- the clone in its direction (any distance); no stick, the clone most behind
-- the opponent. He and the clone trade places in a flicker of chakra: he goes
-- on from where it stood, it goes on from where he stood.
function Legion.switchTarget(c,a)
	local members=Bodies.crowd(c,a,CLONE)
	local b=a.target
	local stick=flat(a.move or Vector3.zero)
	local function pick(useStick)
		local best,score
		for _,body in members do
			if not body.carry and body.mode=="crowd" then
				local s=nil
				if useStick then
					local d=flat(body.position-a.root.Position)
					if d.Magnitude>1 then
						local dot=stick.Unit:Dot(d.Unit)
						if dot>=.3 then s=dot*10-d.Magnitude*.05 end
					end
				elseif b then
					local e=flat(body.position-b.root.Position)
					local back=flat(-b.root.CFrame.LookVector)
					local behind=if e.Magnitude>.1 and back.Magnitude>.1 then e.Unit:Dot(back.Unit) else 0
					s=behind*4-e.Magnitude*.4
				else s=0 end
				if s and (not score or s>score) then best,score=body,s end
			end
		end
		return best
	end
	return (stick.Magnitude>=.45 and pick(true)) or pick(false)
end
local SWITCH_FROM={Neutral=true,Guarding=true,Recovery=true,TechniqueRecovery=true}
function Legion.switch(c,a)
	local tn=tune(a)
	if a.reaction or not SWITCH_FROM[a.state] or c.now<(a.lockUntil or 0) or a.health<=0 then return false,"Committed" end
	if c.now<(a.switchReadyAt or 0) then return false,"Cooldown" end
	if a.chakra<(tn.Switch or 6) then return false,"Need chakra" end
	local body=Legion.switchTarget(c,a)
	if not body then return false,"No clone free" end
	local departure=a.root.Position
	local look=flat(a.root.CFrame.LookVector)
	local to=body.position
	c:relocate(a,to)
	a.airborne=a.root.Position.Y>c.match.origin.Y+4.2
	local b=a.target
	if b and b.health>0 then
		local face=flat(b.root.Position-a.root.Position)
		if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
	end
	if a.state~="Neutral" and a.state~="Guarding" then a.pending=nil;c:setState(a,"Neutral",0) end
	-- The clone takes his place (on the ground under it) and his facing.
	body.position=c:clamp(Vector3.new(departure.X,c.match.origin.Y+3,departure.Z))
	body.look=if look.Magnitude>.1 then look.Unit else body.look
	body.warp+=1;body.state="Neutral";body.action=nil;body.lunge=nil
	body.waitUntil=c.now+.25
	a.chakra-=tn.Switch or 6
	a.switchReadyAt=c.now+(tn.SwitchCooldown or .6)
	c:pushImpact(departure,"bodyswitch",false,{owner=a.id,fighter=a.fighterId,to=to,body=body.id})
	c:cue(a,"BODY SWITCH",.45)
	brawler().event(c,a,"BodySwitch")
	return true
end
function Legion.install(Techniques)
	Bodies.controllers.drive=drive
	Bodies.controllers.guard=persistent
	Bodies.controllers.flank=persistent
	Bodies.controllers.barrage=barrage
	Bodies.controllers.shape=shape
	Bodies.controllers.crowd=crowd
	Bodies.onDispel[CLONE]=lost
	Bodies.transforms[CLONE]=kunaiClone
	brawler().payoffs.uzumaki=uzumaki
	-- Kage Bunshin: one clone at his side (two at most). Near the opponent it
	-- goes straight out to a flank.
	local function canClone(c,a)
		if Bodies.blocked(c,a) then c:cue(a,"NINE-TAILS CHAKRA • NO CLONES",.6);return false end
		if #Bodies.crowd(c,a,CLONE)>0 then c:cue(a,"THE CROWD IS OUT",.6);return false end
		if Bodies.count(c,a,CLONE)>=(tune(a).Max or 2) then c:cue(a,"TWO CLONES AT MOST",.6);return false end
		return true
	end
	Techniques.ShadowClone={
		check=canClone,
		execute=function(c,a)
			local side=nextSide(a)
			local b=a.target
			local near=b~=nil and b.health>0 and (b.root.Position-a.root.Position).Magnitude<=16
			local body=Bodies.spawn(c,a,{kind=CLONE,position=aside(c,a,side),mode=if near then "flank" else "guard",side=side,delay=.3})
			if not body then return end
			c:cue(a,"SHADOW CLONE • "..Bodies.count(c,a,CLONE).." / "..(tune(a).Max or 2),.7)
			brawler().event(c,a,"ShadowClone")
		end,
	}
	-- Tajū Kage Bunshin: the crowd (massClone). Clones already out join it.
	-- With the crowd out, the same key takes a clone's body (recast, before
	-- the cooldown and the cost), and the HUD names it (view).
	Techniques.MassShadowClone={
		check=function(c,a)
			if Bodies.blocked(c,a) then c:cue(a,"NINE-TAILS CHAKRA • NO CLONES",.6);return false end
			return true
		end,
		execute=massClone,
		recast=function(c,a)
			if #Bodies.crowd(c,a,CLONE)==0 then return nil end
			return Legion.switch(c,a)
		end,
		view=function(c,a,spec,now)
			if #Bodies.crowd(c,a,CLONE)==0 then return nil end
			return {name="Take a Body",cost=tune(a).Switch or 6,remaining=math.max(0,(a.switchReadyAt or 0)-now),condition=true}
		end,
	}
	-- Rasengan, Part I: he cannot shape it alone. A free clone comes to his
	-- side and shapes it through the channel; with none he makes one for it
	-- (CloneCost more chakra, a longer channel). Striking that clone breaks
	-- the jutsu. In the Nine-Tails cloak: no clone, almost no wind-up.
	Techniques.CloneRasengan={
		check=function(c,a,spec)
			if Bodies.blocked(c,a) or Bodies.free(c,a,CLONE) then return true end
			return a.chakra>=spec.Cost+(spec.CloneCost or 12)
		end,
		start=function(c,a,pending)
			local spec=table.clone(pending.spec);pending.spec=spec
			-- (A channel lengthened elsewhere, the tutorial's interrupt step, stays long.)
			if Bodies.blocked(c,a) then
				spec.Channel=math.min(spec.Channel,spec.CloakChannel or .2);pending.cloak=true
				c:cue(a,"NINE-TAILS RASENGAN",.6)
			else
				local body=Bodies.free(c,a,CLONE)
				if body then
					c:cue(a,"RASENGAN • THE CLONE SHAPES IT",spec.Channel)
				else
					a.chakra=math.max(0,a.chakra-(spec.CloneCost or 12))
					spec.Channel=math.max(spec.Channel,spec.SoloChannel or .6)
					body=Bodies.spawn(c,a,{kind=CLONE,position=aside(c,a,1,1.9),ephemeral=true,life=spec.Channel+1})
					c:cue(a,"RASENGAN • A CLONE FOR IT",spec.Channel)
				end
				if body then body.mode="shape";body.shaping=pending;body.cast="RasenganShape";body.expires=math.max(body.expires,c.now+spec.Channel+1);pending.shaper=body end
			end
			a.untilTime=c.now+spec.Channel
		end,
		execute=function(c,a,pending)
			local shaper=pending.shaper
			if shaper and not shaper.alive then return end
			local Brawler=brawler()
			Brawler.start(c,a,"DashAttack")
			local p=a.pending
			if not p then return end
			p.spec=table.clone(p.spec)
			p.spec.damage=pending.spec.Damage;p.spec.travel=10;p.spec.recovery=.45
			p.spec.reaction="Knockback";p.spec.impulse=Vector3.new(0,22,74);p.spec.stun=.62
			p.rasengan=true;a.travelRemaining=10
			-- (One variant: the client draws it red in the cloak.)
			a.attackVariant="Rasengan"
			c:pushImpact(a.root.Position,"burst",false,{owner=a.id,fighter=a.fighterId,cloak=pending.cloak})
			Brawler.event(c,a,"Rasengan")
		end,
	}
end
return Legion
