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
-- total damage (ticks on a held body, then the last blow), the camera beat
-- the client plays (kind) and how the opener reaches (Lunge: he arrives in
-- front of the body; Gaze/Sand: from where he stands).
Ultimates.DEFS={
	Naruto={Name="THOUSAND CLONES",Reach=10,Startup=.24,Time=3.4,Ticks=9,Damage=30,Kind="clones",Opener="Lunge"},
	Sasuke={Name="CHIDORI: LION'S STRIKE",Reach=12,Startup=.3,Time=3.2,Ticks=6,Damage=32,Kind="lion",Opener="Lunge"},
	Gaara={Name="IMPERIAL DESERT FUNERAL",Reach=26,Startup=.42,Time=3.6,Ticks=5,Damage=34,Kind="pyramid",Opener="Sand"},
	["Rock Lee"]={Name="HIDDEN LOTUS",Reach=9,Startup=.2,Time=3.4,Ticks=10,Damage=34,Kind="lotus",Opener="Lunge"},
	Neji={Name="128 PALMS",Reach=8,Startup=.24,Time=3.4,Ticks=12,Damage=30,Kind="palms",Opener="Lunge"},
	Itachi={Name="TSUKUYOMI",Reach=20,Startup=.32,Time=3.6,Ticks=4,Damage=28,Kind="tsukuyomi",Opener="Gaze"},
	Minato={Name="YELLOW FLASH",Reach=22,Startup=.16,Time=3.2,Ticks=12,Damage=30,Kind="flash",Opener="Lunge"},
	Kakashi={Name="CHIDORI: RAIKIRI",Reach=22,Startup=.3,Time=3.2,Ticks=4,Damage=34,Kind="raikiri",Opener="Lunge"},
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
	-- Caught: the lunge brings him in front of the body; the sand and the
	-- gaze work from where he stands.
	local line=if gap.Magnitude>.1 then gap.Unit else flat(a.root.CFrame.LookVector)
	if u.Opener=="Lunge" then
		local from=a.root.Position
		c:relocate(a,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z)-line*3.2)
		c:pushImpact(a.root.Position,"teleport",false,{owner=a.id,from=from,to=a.root.Position,kind=u.Kind})
	end
	a.root.CFrame=CFrame.lookAt(a.root.Position,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
	b.root.CFrame=CFrame.lookAt(b.root.Position,Vector3.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
	Brawler.releaseGrab(b);b.pending=nil;b.guardHeld=false
	a.ultimateRunning=true;b.ultimateHeld=true
	local hold=u.Time+.1
	-- Both bodies belong to the sequence: no input, no damage from elsewhere.
	c:setState(a,"Recovery",hold)
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+hold)
	Brawler.react(c,b,"Bound",Vector3.zero,hold,a)
	b.boundBy=a;b.boundKind="ultimate"
	c:pushImpact(b.root.Position,"ultimate",true,{owner=a.id,victim=b.id,fighter=a.fighterId,kind=u.Kind,name=u.Name,time=u.Time})
	c:cue(a,u.Name,u.Time);c:cue(b,u.Name,u.Time)
	Brawler.event(c,a,"Ultimate")
	-- Ticks across the sequence, then the last blow at its end.
	local tick=u.Damage*.65/u.Ticks
	for k=1,u.Ticks do
		c:schedule(c.now+(u.Time-.5)*k/(u.Ticks+1),function()
			if a.health<=0 or b.health<=0 or c.match.phase~="Duel" or not a.ultimateRunning then return end
			c.damageTag=u.Name
			c:chip(a,b,tick)
			c.damageTag=nil
			c:pushImpact(b.root.Position+Vector3.new(0,.6,0),"ultimateTick",k%3==0,{owner=a.id,victim=b.id,kind=u.Kind,index=k})
		end)
	end
	c:schedule(c.now+u.Time-.3,function()
		a.ultimateRunning=nil;b.ultimateHeld=nil
		if b.boundBy==a then b.boundBy=nil end
		if a.health<=0 or b.health<=0 or c.match.phase~="Duel" then return end
		b.invulnerableUntil=0
		local away=flat(b.root.Position-a.root.Position)
		away=if away.Magnitude>.1 then away.Unit else line
		c.damageTag=u.Name
		local landed=c:damage(a,b,u.Damage*.35,true,false)
		c.damageTag=nil
		if c.match.phase~="Duel" or b.health<=0 then return end
		if landed then Brawler.react(c,b,"Knockdown",away*46+Vector3.new(0,22,0),.9,a) end
		c:pushImpact(b.root.Position,"ultimateEnd",true,{owner=a.id,victim=b.id,kind=u.Kind})
		c:setState(a,"Recovery",.35)
	end)
end

return Ultimates
