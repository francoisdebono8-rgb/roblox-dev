-- Ultimates (stage 6, the approved move list, "Ultimes"): one per main
-- fighter, R1 + L1 on the pad (Y on the keyboard) when the ultimate bar is
-- full. The bar fills in the fight, by hitting and by being hit (not only
-- while awakened). The ultimate opens with one quick move: if it reaches,
-- both bodies are taken into a 3-4 s sequence; if it misses, the opponent
-- has an opening. Away from the 8 main fighters (no entry below) the button
-- does nothing. On a wall, R1 + L1 is still the wall detach (Combat routes it).
--
-- (Redone 02/11, user: "globalement tous les mêmes ... les coups sont mal
-- faits ... même effet même sensation à chaque fois".) Each sequence is now
-- a script of its own (Shared/UltimateScripts): the paths both bodies follow
-- in the frame of the catch, its blows, Naruto's real shadow clones, the
-- lens and the cues the client draws. The bodies play authored clips for
-- the whole sequence ("<fighter>.Ultimate" from the press, "Ult.<kind>.Victim"
-- from the catch: tools/blender/ult_clips.py), not the fight's strikes.
local Ultimates={}
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Scripts=require(Shared.UltimateScripts)
Ultimates.Scripts=Scripts

Ultimates.MAX=100
-- Bar gain per point of damage dealt / taken (a fight of ~3 rounds gives
-- one or two ultimates a side).
Ultimates.GAIN={Dealt=1.1,Taken=.8}
-- Each ultimate: the opener's reach, its startup, the sequence length, the
-- total damage (its script's blows, then the last blow), the sequence kind
-- (Shared/UltimateScripts). Keep Startup/Time equal to tools/blender/ult_clips.py ULT.
Ultimates.DEFS={
	Naruto={Name="THOUSAND CLONES",Reach=10,Startup=.24,Time=3.9,Damage=30,Kind="clones"},
	Sasuke={Name="CHIDORI: LION'S STRIKE",Reach=12,Startup=.3,Time=3.6,Damage=32,Kind="lion"},
	Gaara={Name="IMPERIAL DESERT FUNERAL",Reach=26,Startup=.42,Time=3.6,Damage=34,Kind="pyramid"},
	["Rock Lee"]={Name="HIDDEN LOTUS",Reach=9,Startup=.2,Time=3.7,Damage=34,Kind="lotus"},
	Neji={Name="128 PALMS",Reach=8,Startup=.24,Time=3.6,Damage=30,Kind="palms"},
	Itachi={Name="TSUKUYOMI",Reach=20,Startup=.32,Time=4.0,Damage=28,Kind="tsukuyomi"},
	Minato={Name="YELLOW FLASH",Reach=22,Startup=.16,Time=3.4,Damage=30,Kind="flash"},
	Kakashi={Name="CHIDORI: RAIKIRI",Reach=22,Startup=.3,Time=3.4,Damage=34,Kind="raikiri"},
}
for _,u in Ultimates.DEFS do
	local spec=Scripts.KINDS[u.Kind]
	u.Opener=spec.opener;u.Blows=#spec.blows
end
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

-- A body plays a whole-sequence clip (the snapshot's ultClip / ultElapsed).
local function play(c,x,clip)
	x.ultClip=clip;x.ultAt=c.now;x.ultSerial=(x.ultSerial or 0)+1
end
Ultimates.play=play
local function stopClip(x,clip)
	if x.ultClip==clip then x.ultClip=nil end
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
	a.pending=nil;a.guardHeld=false;a.attackName=nil;a.attackVariant=nil
	c:setState(a,"Startup",u.Startup)
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+u.Startup)
	local face=if gap.Magnitude>.1 then gap.Unit else flat(a.root.CFrame.LookVector)
	a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face)
	-- The caster's clip runs from the press (its startup is the clip's start).
	play(c,a,a.fighterId..".Ultimate")
	local spec=Scripts.KINDS[u.Kind]
	-- A lunge closes the gap during the startup (one glide, no teleport).
	if spec.opener=="Lunge" and gap.Magnitude>spec.close then
		local goal=Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z)-face*spec.close
		a.ultimateGlide={from=a.root.Position,to=c:clamp(goal),t0=c.now,t1=c.now+u.Startup*.85,face=b}
	end
	c:pushImpact(a.root.Position,"ultimateStart",true,{owner=a.id,fighter=a.fighterId,kind=u.Kind,name=u.Name,victim=b.id})
	c:cue(a,u.Name,1.2)
	Brawler.event(c,a,"UltimateStart")
	c:schedule(c.now+u.Startup,function() Ultimates.connect(c,a,b,u) end)
	return true
end

-- The opener's moment: it reaches or it misses.
function Ultimates.connect(c,a,b,u)
	local Brawler=require(script.Parent.Brawler)
	a.ultimateGlide=nil
	local clip=a.fighterId..".Ultimate"
	if a.health<=0 or c.match.phase~="Duel" or c.match.finishing then stopClip(a,clip);return end
	if a.reaction then stopClip(a,clip);return end -- hit out of the startup: the ultimate is lost
	local gap=flat(b.root.Position-a.root.Position)
	local missed=b.health<=0 or gap.Magnitude>u.Reach*1.25 or (b.invulnerableUntil or 0)>c.now or b.state=="Dodging"
		or (b.rotationUntil or 0)>c.now or not c:lineOfSight(a,b)
	if missed then
		-- The opening: a long recovery, the bar is gone.
		stopClip(a,clip)
		c:setState(a,"Recovery",1.0)
		c:cue(a,"ULTIMATE MISSED",.9);c:cue(b,"OPENING",.8)
		c:pushImpact(a.root.Position,"ultimateMiss",false,{owner=a.id,kind=u.Kind})
		Brawler.event(c,a,"UltimateMiss")
		return
	end
	-- Caught: both bodies belong to the sequence (no input, no damage from
	-- elsewhere) and follow its script.
	Brawler.releaseGrab(b);b.pending=nil;b.guardHeld=false;b.attackName=nil
	if b.ultimateRunning then Ultimates.abort(c,b) end
	a.ultimateRunning=true;b.ultimateHeld=true
	local hold=u.Time+.1
	c:setState(a,"Recovery",hold)
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+hold)
	-- The held body: stunned for the whole sequence (a stun, not a wire), its
	-- own clip from the catch.
	Brawler.react(c,b,"HitStun",Vector3.zero,hold,a)
	play(c,b,"Ult."..u.Kind..".Victim")
	local seq=Ultimates.sequence(c,a,b,u)
	c:pushImpact(b.root.Position,"ultimate",true,{owner=a.id,victim=b.id,fighter=a.fighterId,kind=u.Kind,name=u.Name,time=u.Time,
		origin=seq.frame.origin,line=seq.frame.f,casterStart=seq.startA,victimStart=seq.startB})
	c:cue(a,u.Name,u.Time);c:cue(b,u.Name,u.Time)
	Brawler.event(c,a,"Ultimate")
	return seq
end

-- --------------------------------------------------------------- sequences
-- The running sequence: both bodies on their paths (Ultimates.step), the
-- blows at their times, the clones, the last blow at Time-0.3.
local function lookAt(x,y)
	x.root.CFrame=CFrame.lookAt(x.root.Position,Vector3.new(y.root.Position.X,x.root.Position.Y,y.root.Position.Z))
end
function Ultimates.sequence(c,a,b,u)
	local Brawler=require(script.Parent.Brawler)
	local spec=Scripts.KINDS[u.Kind]
	local t0=c.now
	local ground=(c.match.origin and c.match.origin.Y+3) or b.root.Position.Y
	local line=flat(b.root.Position-a.root.Position)
	if line.Magnitude<.1 then line=flat(a.root.CFrame.LookVector) end
	local frame=Scripts.frame(Vector3.new(b.root.Position.X,ground,b.root.Position.Z),line)
	-- (12/11, feel audit M3: Kakashi caught in HitStun turned 155 deg in one
	-- frame, Itachi 176 deg) The caster faces him at once (his own startup
	-- already turned him); the caught body is turned by its path, at a rate
	-- (Ultimates.VICTIM_TURN, Ultimates.step), not snapped here.
	lookAt(a,b)
	local seq={c=c,a=a,b=b,u=u,spec=spec,t0=t0,frame=frame,blows=0,ground=ground,bodies={}}
	seq.startA=frame.anchor(a.root.Position);seq.startB=frame.anchor(b.root.Position)
	-- Faces: the caster at the other body, the held one as it was caught.
	local fixed=-frame.f
	a.ultimatePath={seq=seq,path=spec.caster,start=seq.startA,face="other",other=b,snaps=Scripts.snaps(spec.caster),snapped=0}
	b.ultimatePath={seq=seq,path=spec.victim,start=seq.startB,face="fixed",other=a,fixed=fixed,snaps={},snapped=0}
	a.ultimateSeq=seq
	local function alive() return a.health>0 and b.health>0 and c.match.phase=="Duel" and a.ultimateSeq==seq end
	function seq.at(t,fn) c:schedule(t0+t,function() if alive() then fn() end end) end
	local share=u.Damage*.65/math.max(1,#spec.blows)
	for i,blow in spec.blows do
		seq.at(blow[1],function()
			seq.blows+=1
			c.damageTag=u.Name
			c:chip(a,b,share)
			c.damageTag=nil
			if b.health<=0 or c.match.phase~="Duel" then return end
			b.hitFrom=flat(a.root.Position-b.root.Position)
			c:pushImpact(b.root.Position+Vector3.new(0,.6,0),"ultimateTick",blow[2]==true,{owner=a.id,victim=b.id,kind=u.Kind,index=i,text=blow[3],t=blow[1]})
		end)
	end
	-- Naruto's clones: real bodies (Server/Bodies), each on its own path.
	if spec.clones then
		local Bodies=require(script.Parent.Bodies)
		Bodies.controllers.ult=Ultimates.cloneStep
		for _,clone in spec.clones do
			seq.at(clone.born,function()
				local at=frame.world(Scripts.at(clone.path,clone.born,Vector3.zero))
				local body=Bodies.spawn(c,a,{kind="clone",position=at,ephemeral=true,life=clone.gone-clone.born+.5,mode="ult",airborne=clone.air==true})
				if not body then return end
				body.ult={seq=seq,path=clone.path}
				Bodies.face(body,b.root.Position)
				table.insert(seq.bodies,body)
				for _,act in clone.actions do
					seq.at(act[1],function()
						if not body.alive then return end
						body.state="Active";body.action=act[2];body.variant=nil;body.actionAt=c.now;body.actionSerial+=1
						c:schedule(c.now+.4,function() if body.alive and body.action==act[2] then body.state="Neutral";body.action=nil end end)
					end)
				end
				seq.at(clone.gone,function() if body.alive then Bodies.dispel(c,body,"spent") end end)
			end)
		end
	end
	-- Each script's moments the server must announce (Minato's kunai fan).
	if spec.kunai then
		seq.at(.15,function()
			local points={}
			for i,p in spec.kunai do points[i]=frame.world(p) end
			c:pushImpact(b.root.Position,"ultimateKunai",false,{owner=a.id,victim=b.id,points=points})
		end)
	end
	seq.final=spec.final
	function seq.finish()
		if a.ultimateSeq~=seq then return end
		a.ultimateSeq=nil
		a.ultimateRunning=nil;b.ultimateHeld=nil
		a.ultimatePath=nil;b.ultimatePath=nil
		for _,body in seq.bodies do if body.alive then require(script.Parent.Bodies).dispel(c,body,"spent") end end
		c:schedule(c.now+.3,function() stopClip(b,"Ult."..u.Kind..".Victim") end)
		c:schedule(c.now+.36,function() stopClip(a,a.fighterId..".Ultimate") end)
		if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then stopClip(a,a.fighterId..".Ultimate");stopClip(b,"Ult."..u.Kind..".Victim");return end
		b.invulnerableUntil=0
		local f=seq.final
		local away=flat(b.root.Position-a.root.Position)
		away=if away.Magnitude>.1 then away.Unit else frame.f
		c.damageTag=u.Name
		local landed=c:damage(a,b,u.Damage*.35,true,false)
		c.damageTag=nil
		if c.match.phase~="Duel" or b.health<=0 then return end
		if landed then Brawler.react(c,b,f.reaction,away*f.away+f.push,f.stun,a) end
		c:pushImpact(b.root.Position,"ultimateEnd",true,{owner=a.id,victim=b.id,kind=u.Kind})
		c:setState(a,"Recovery",.35)
	end
	c:schedule(t0+u.Time-.3,function() seq.finish() end)
	return seq
end
-- A sequence cut short (the caster caught in another's ultimate, a KO).
function Ultimates.abort(c,a)
	local seq=a.ultimateSeq
	if not seq then return end
	a.ultimateSeq=nil;a.ultimateRunning=nil
	seq.b.ultimateHeld=nil
	a.ultimatePath=nil;seq.b.ultimatePath=nil
	stopClip(a,a.fighterId..".Ultimate");stopClip(seq.b,"Ult."..seq.u.Kind..".Victim")
	for _,body in seq.bodies do if body.alive then require(script.Parent.Bodies).dispel(c,body,"spent") end end
end

-- A clone of the sequence (Bodies.controllers.ult): carried on its path.
function Ultimates.cloneStep(c,body,dt)
	local ult=body.ult
	if not ult then return end
	local seq=ult.seq
	local p=seq.frame.world(Scripts.at(ult.path,c.now-seq.t0,Vector3.zero))
	body.position=p
	body.airborne=p.Y>seq.ground+.4
	local d=flat(seq.b.root.Position-p)
	if d.Magnitude>.1 then body.look=d.Unit end
end

-- Server step: both bodies on their paths (no physics of their own), and the
-- caster's glide in the startup of a lunge.
Ultimates.VICTIM_TURN=900
function Ultimates.step(c)
	for _,x in c.actors do
		local glide=x.ultimateGlide
		-- A body struck out of its glide stops gliding (the 64 Palms' step in
		-- uses the same glide; an ultimate struck in its startup is lost anyway).
		if glide and x.reaction then x.ultimateGlide=nil;glide=nil end
		if glide then
			local k=math.clamp((c.now-glide.t0)/math.max(1e-3,glide.t1-glide.t0),0,1)
			local p=glide.from:Lerp(glide.to,1-(1-k)^3)
			local look=Vector3.new(glide.face.root.Position.X,p.Y,glide.face.root.Position.Z)
			x.model:PivotTo(if (look-p).Magnitude>.1 then CFrame.lookAt(p,look) else CFrame.new(p))
			x.root.AssemblyLinearVelocity=Vector3.zero
			if k>=1 then x.ultimateGlide=nil end
		end
		local run=x.ultimatePath
		if run then
			local seq=run.seq
			local t=c.now-seq.t0
			local anchor=Scripts.at(run.path,t,run.start)
			local p=seq.frame.world(anchor)
			local flatP=c:clamp(p)
			p=Vector3.new(flatP.X,math.max(p.Y,seq.ground-1),flatP.Z)
			-- A teleport (Minato): the client snaps instead of sliding.
			while run.snapped<#run.snaps and t>=run.snaps[run.snapped+1] do
				run.snapped+=1
				local from=x.root.Position
				x.warpSerial=(x.warpSerial or 0)+1
				c:pushImpact(p,"teleport",false,{owner=x.id,from=from,to=p,kind=seq.u.Kind})
			end
			local face=Scripts.face(run.path,t,run.face)
			local dir
			if face=="fixed" then dir=run.fixed or x.root.CFrame.LookVector
			else
				dir=flat(run.other.root.Position-p)
				if face=="away" then dir=-dir end
			end
			dir=flat(dir)
			-- (12/11, feel audit M3) The caught body turns to its path's facing
			-- at VICTIM_TURN (a blow hauls it round, ~0.2 s for a half turn), as a
			-- held body does (Brawler.GRAB_TURN); it was set in one frame.
			local dt=math.clamp(c.now-(run.lastAt or c.now),0,.1);run.lastAt=c.now
			local look=flat(x.root.CFrame.LookVector)
			if x==seq.b and dir.Magnitude>.05 and look.Magnitude>.05 then
				local want,cur=dir.Unit,look.Unit
				local angle=math.atan2(cur:Cross(want).Y,cur:Dot(want))
				local step=math.clamp(angle,-math.rad(Ultimates.VICTIM_TURN)*dt,math.rad(Ultimates.VICTIM_TURN)*dt)
				dir=CFrame.fromAxisAngle(Vector3.yAxis,step):VectorToWorldSpace(cur)
			end
			x.model:PivotTo(if dir.Magnitude>.05 then CFrame.lookAt(p,p+dir.Unit) else CFrame.new(p))
			x.root.AssemblyLinearVelocity=Vector3.zero
			if p.Y>seq.ground+.4 then x.airborne=true;x.airHold=c.now+.25 end
		end
	end
end

return Ultimates
