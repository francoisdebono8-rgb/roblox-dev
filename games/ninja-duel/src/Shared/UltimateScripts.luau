-- The eight ultimates as scripts (stage 6, redone 02/11: "globalement tous
-- les mêmes ... même effet même sensation à chaque fois"). One table per
-- sequence, shared by the server (who moves the bodies and lands the blows)
-- and the client (who films it and draws it), so the two never disagree.
--
-- Everything is written in the ANCHOR frame of the catch: origin = the held
-- body's spot on the floor, z = the line from the caster to it (+z forward,
-- away from the caster), x = to the right of that line, y = up. Times are
-- seconds from the catch.
--   caster / victim  paths: {t, position | "start", ease, face=...}
--     ease (of the segment arriving at the key): "smooth" (default), "in"
--     (accelerating: a fall, a dive), "out" (decelerating: a launch), "linear",
--     "snap" (a teleport at the key: Minato)
--     face: "other" (towards the other body), "fixed" (as at the catch),
--     "away" (back turned to the other)
--   blows   {t, heavy, text}: each takes its share of the damage (the last
--           blow, `final` at Time-0.3, takes the rest)
--   clones  Naruto's real shadow clones (Server/Bodies): their paths and blows
--   shots   the lens: {t, eye, at, fov, cut}; eye/at are anchor points or
--           {"victim"|"caster", offset} (follows that body)
--   cues    {t, name}: what the client draws at that moment (UltimateFX)
-- The bodies themselves play authored clips (tools/blender/ult_clips.py):
-- "<fighter>.Ultimate" for the caster from the press, "Ult.<kind>.Victim"
-- for the held body from the catch.
local Scripts={}

local function P(x,y,z) return Vector3.new(x,y,z) end
Scripts.P=P

-- ------------------------------------------------------------------ paths
local EASE={
	smooth=function(k) return k*k*(3-2*k) end,
	linear=function(k) return k end,
	["in"]=function(k) return k*k end,
	out=function(k) return 1-(1-k)*(1-k) end,
}
-- Position of a path at t (anchor frame); `start` stands for "start" keys.
function Scripts.at(path,t,start)
	local function pos(key) return if key[2]=="start" then start else key[2] end
	if t<=path[1][1] then return pos(path[1]) end
	for i=1,#path-1 do
		local a,b=path[i],path[i+1]
		if t<b[1] then
			local e=b[3] or "smooth"
			if e=="snap" then return pos(a) end
			local k=math.clamp((t-a[1])/math.max(1e-3,b[1]-a[1]),0,1)
			return pos(a):Lerp(pos(b),(EASE[e] or EASE.smooth)(k))
		end
	end
	return pos(path[#path])
end
-- Which way the body faces at t (the last key that says so).
function Scripts.face(path,t,default)
	local face=default
	for _,key in path do
		if key[1]>t then break end
		if key.face then face=key.face end
	end
	return face
end
-- The snap keys of a path (Minato's appearances), in time order.
function Scripts.snaps(path)
	local out={}
	for i,key in path do if i>1 and key[3]=="snap" then table.insert(out,key[1]) end end
	return out
end
-- Anchor <-> world.
function Scripts.frame(origin,line)
	local f=Vector3.new(line.X,0,line.Z)
	f=if f.Magnitude>.01 then f.Unit else Vector3.new(0,0,-1)
	local r=f:Cross(Vector3.yAxis)
	return {origin=origin,f=f,r=r,
		world=function(p) return origin+r*p.X+Vector3.yAxis*p.Y+f*p.Z end,
		anchor=function(w) local d=w-origin;return Vector3.new(d:Dot(r),d.Y,d:Dot(f)) end,
		dir=function(p) return r*p.X+Vector3.yAxis*p.Y+f*p.Z end}
end

-- Neji's palms: 2, 4, 8 ... 128, each step faster (ult_clips.palm_times).
function Scripts.palmTimes()
	local gaps={{.3,.15},{.6,.1},{1.0,.07},{1.45,.06},{1.9,.05},{2.35,.05},{2.8,.05}}
	local out={}
	for n,g in gaps do
		local stop=if gaps[n+1] then gaps[n+1][1] else 3.0
		local t=g[1]
		while t<stop-1e-6 do table.insert(out,t);t+=g[2] end
	end
	return out
end

-- ---------------------------------------------------------------- scripts
local S={}
Scripts.KINDS=S

-- NARUTO - THOUSAND CLONES (Uzumaki Naruto Rendan). The punch in the
-- stomach, a leap back and the sign: his clones burst out of the smoke all
-- round, beat the body standing, four of them kick it up into the sky
-- (U-ZU-MA-KI), and he comes down from above it, heel first.
do
	local victim={{0,"start"},{.3,P(0,0,.7),"out"},{1.56,P(0,0,.7)},
		{1.6,P(0,2.6,.7),"out"},{1.95,P(0,5.2,.7),"out"},{2.35,P(0,7.6,.7),"out"},{2.75,P(0,9.6,.7),"out"},
		{3.25,P(0,10.4,.7),"out"},{3.35,P(0,9.9,.7)},{3.6,P(0,0,.7),"in"}}
	local clones={}
	local ring={"Light1","Light2","Headbutt","Light3","Tackle","CloneJab"}
	for i=0,7 do
		local a=math.rad(i*45+22.5)
		local dir=P(math.sin(a),0,math.cos(a))
		local c=P(0,0,.7)
		local hit=if i<6 then .9+i*.13 else nil
		local path={{.55,c+dir*6.5},{.82,c+dir*2.3,"out"}}
		local acts={}
		if hit then
			table.insert(path,{hit-.06,c+dir*2.3});table.insert(path,{hit,c+dir*1.5,"out"});table.insert(path,{hit+.16,c+dir*2.3})
			table.insert(acts,{hit-.08,ring[i+1]})
		end
		table.insert(path,{1.62,c+dir*2.6});table.insert(path,{1.72,c+dir*4.2,"out"})
		table.insert(clones,{born=.55+i*.02,gone=1.76+i*.03,path=path,actions=acts})
	end
	-- U-ZU-MA-KI: a clone under the body for each kick, from alternate sides.
	local kicks={1.6,1.95,2.35,2.75}
	for i,t in kicks do
		local side=if i%2==1 then 1 else -1
		local at=Scripts.at(victim,t,P(0,0,.7))
		local from=Scripts.at(victim,t-.2,P(0,0,.7))
		table.insert(clones,{born=t-.24,gone=t+.32,air=t>1.7,
			path={{t-.24,from+P(side*1.1,-2.2,-1.1)},{t,at+P(side*.8,-1.5,-.9),"out"},{t+.3,at+P(side*1.6,-.6,-1.6),"out"}},
			actions={{t-.14,if i==1 or i==4 then "UzumakiKick" else "BarrageKick"}}})
	end
	S.clones={
		opener="Lunge",close=2.0,
		caster={{0,"start"},{.15,P(0,1.8,-4.6),"out"},{.38,P(0,0,-7.6),"in"},{2.55,P(0,0,-7.6)},
			{2.7,P(0,2.6,-6.2),"out"},{3.0,P(0,10.6,-2.6),"out"},{3.22,P(0,11.8,-1.2)},{3.35,P(0,10.6,-.6),"in"},{3.6,P(0,0,-1.4),"in"}},
		victim=victim,
		blows={{.9},{1.03},{1.16},{1.29},{1.42},{1.55},{1.6,true,"U"},{1.95,true,"ZU"},{2.35,true,"MA"},{2.75,true,"KI"},{3.35,true,"NARUTO RENDAN!"}},
		final={reaction="Knockdown",push=P(0,-30,0),away=10,stun=1.2},
		clones=clones,
		shots={
			{0,P(3.4,1.3,-1.4),"mid",48},
			{.3,P(1.5,7,-17),P(0,1,-3),60,true},
			{.56,{"caster",P(1.3,1.3,3.3)},{"caster",P(0,1.3,0)},40,true},
			{.82,P(10,4,5),{"victim",P(0,0,0)},62,true},{1.55,P(-9,3.4,7),{"victim",P(0,0,0)},60},
			{1.58,P(3.2,.4,4.2),{"victim",P(0,.8,0)},64,true},{2.8,P(5,2.6,7),{"victim",P(0,0,0)},62},
			{2.86,P(6,16,-5),{"victim",P(0,0,0)},55,true},{3.3,P(5,13,-3),{"victim",P(0,0,0)},55},
			{3.36,P(8,1.2,8),P(0,1.5,.7),60,true},
		},
		cues={{0,"punch"},{.55,"sign"},{.56,"text:TAJU KAGE BUNSHIN NO JUTSU"},{3.35,"impactFrame"},{3.6,"crater"}},
	}
end

-- SASUKE - CHIDORI: LION'S STRIKE. The Chidori screams in his hand; he
-- tears down the line and drives it through; he lifts the body on his arm,
-- throws it into the sky, goes after it - a spinning kick, a fist, the heel
-- raised over his head - and drives it into the floor.
S.lion={
	opener="Run",
	caster={{0,"start"},{.36,P(0,0,-1.6),"linear"},{.74,P(0,0,-1.6)},{1.1,P(0,.3,-1.4)},{1.25,P(0,.6,-1.4)},{1.45,P(0,0,-1.4)},
		{1.65,P(0,5,-1.2),"out"},{1.76,P(-1.2,8.2,-1.0),"out"},{1.9,P(-1.5,9.8,-.4)},{2.1,P(-.5,10.6,-1.4)},{2.2,P(0,10.8,-1.6)},
		{2.42,P(0,12.6,-1.0),"out"},{2.5,P(0,12,-.8)},{2.85,P(0,9.8,-.9)},{3.25,P(0,0,-1.2),"in"}},
	victim={{0,"start"},{.36,P(0,0,.2)},{.8,P(0,1.6,.2)},{1.1,P(0,2.4,.2)},{1.25,P(0,2.6,.2)},{1.5,P(0,7,.2),"out"},{1.9,P(0,10,.2),"out"},
		{2.2,P(0,10.8,.2),"out"},{2.5,P(0,10.6,.2)},{2.85,P(0,8.8,.2)},{3.25,P(0,0,.2),"in"}},
	blows={{.36,true,"CHIDORI"},{.5},{.62},{1.9,true},{2.2,true},{2.5,true,"LION COMBO"}},
	final={reaction="Knockdown",push=P(0,-40,0),away=6,stun=1.2},
	shots={
		{0,{"caster",P(1.3,1.1,-3.6)},{"victim",P(0,1,0)},50},
		{.34,P(3.6,1.5,-.8),P(0,1.2,-.6),44,true},
		{.8,P(-2.6,.5,3.6),{"victim",P(0,.4,0)},56,true},
		{1.48,P(6.5,1,8),{"victim",P(0,0,0)},62,true},{2.38,P(9,2,3),{"victim",P(0,0,0)},60},
		{2.4,{"caster",P(1.6,3.2,-3.2)},{"victim",P(0,0,0)},55,true},
		{2.86,P(8,1,5),P(0,2,0),62,true},
	},
	cues={{0,"chidoriRun"},{.36,"impactFrame"},{.36,"impale"},{1.25,"throwUp"},{1.9,"airHit"},{2.2,"airHit"},{2.5,"airHit"},{3.25,"crater"}},
}

-- GAARA - IMPERIAL DESERT FUNERAL (Sabaku Kyu, Sabaku Soso). He barely
-- moves. The sand floods out from under him across the floor and swallows
-- the legs, climbs the body and closes it in a cocoon (one mass, never a
-- second shape), lifts it high, and his hand closes: the cocoon crushes,
-- and bursts.
S.pyramid={
	opener="Sand",
	caster={{0,"start"}},
	victim={{0,"start"},{.25,P(0,0,0)},{.85,P(0,-.6,0)},{1.5,P(0,-.4,0)},{2.2,P(0,5.6,0)},{2.85,P(0,5.9,0)},{2.92,P(0,5.3,0)},{3.3,P(0,5.5,0)}},
	blows={{.85},{1.5},{2.2},{2.92,true,"SABAKU SOSO"}},
	final={reaction="Knockdown",push=P(0,-12,0),away=10,stun=1.2},
	shots={
		{0,{"caster",P(1.9,2.4,-5.2)},{"victim",P(0,0,0)},52},
		{.84,P(2.9,1.2,2.6),P(0,.5,0),44,true},
		{1.48,P(9,1,6),{"victim",P(0,0,0)},55,true},{2.25,P(10,3.2,3),{"victim",P(0,0,0)},55},
		{2.56,{"caster",P(1.7,1.6,2.4)},{"caster",P(.5,1.5,.6)},38,true},
		{2.9,P(-8.5,3,8.5),P(0,5,0),58,true},{3.3,P(-9.5,2.6,9.5),P(0,5,0),60},
	},
	cues={{0,"sandFlood"},{.85,"sandGrip"},{1.5,"sandCocoon"},{2.2,"sandLift"},{2.6,"sandTighten"},{2.92,"sandCrush"},{2.92,"impactFrame"},{3.3,"sandBurst"}},
}

-- ROCK LEE - HIDDEN LOTUS. The gates open (a roar, the skin flushes red),
-- the rising kick under the chin, and he is everywhere round the body in the
-- air, a kick, a fist, a kick, a fist; the bandage wraps it, he pulls it in,
-- turns it head down, and they fall together into the floor.
do
	local caster={{0,"start"},{.32,"start"},{.42,P(0,1.2,-1.4),"out"},{.9,P(0,10,-1.8),"out"}}
	local victim={{0,"start"},{.42,P(0,1,0)},{.95,P(0,10.2,0),"out"}}
	for i=0,8 do
		local t=1.0+i*.15
		local a=math.rad(i*75+200)
		table.insert(caster,{t-.06,P(math.sin(a)*2.9,10.4+(i%2)*.8,math.cos(a)*2.9),"out"})
		table.insert(caster,{t,P(math.sin(a)*1.7,10.4+(i%2)*.6,math.cos(a)*1.7),"out"})
		local push=P(-math.sin(a),.3,-math.cos(a))*.5
		table.insert(victim,{t+.04,P(0,10.3+i*.08,0)+push,"out"})
	end
	for _,key in {{2.3,P(0,11.4,-2.8)},{2.55,P(0,11.6,-1.6)},{2.72,P(0,12.8,-1.3)},{3.08,P(0,2.6,-1.3),"in"},{3.12,P(0,0,-2.2)}} do table.insert(caster,key) end
	for _,key in {{2.3,P(0,11.2,0)},{2.55,P(0,11.2,-.6)},{2.72,P(0,11.6,-.8)},{3.08,P(0,1.6,-.8),"in"},{3.12,P(0,0,-.8),"in"}} do table.insert(victim,key) end
	S.lotus={
		opener="Lunge",close=1.6,
		caster=caster,victim=victim,
		blows={{.42,true},{1.0},{1.15},{1.3},{1.45},{1.6},{1.75},{1.9},{2.05},{2.2,true},{2.72,true,"OMOTE RENGE"}},
		final={reaction="Knockdown",push=P(0,-50,0),away=4,stun=1.2},
		shots={
			{0,{"caster",P(.9,1.3,3.4)},{"caster",P(0,1.4,0)},40},
			{.36,P(5,.6,0),{"victim",P(0,1,0)},60,true},
			{.95,P(7,9,6),{"victim",P(0,0,0)},62,true},{1.6,P(-3,13,8),{"victim",P(0,0,0)},62},{2.25,P(-7,12,5),{"victim",P(0,0,0)},60},
			{2.3,{"victim",P(2.4,3.6,-4.4)},"mid",55,true},
			{2.7,P(5.5,.8,5),{"victim",P(0,0,0)},64,true},{3.1,P(6.5,1,6.5),{"victim",P(0,0,0)},62},
		},
		cues={{0,"gates"},{.42,"impactFrame"},{.95,"airTrail"},{2.3,"bandage"},{2.72,"spin"},{3.12,"crater"},{3.12,"impactFrame"}},
	}
end

-- NEJI - 128 PALMS (Hakke Rokujuyon Sho). The eight trigrams open under
-- both; the palms come in a doubling count, faster and faster - 2, 4, 8 ...
-- 128 - the body sags as its points close; then nothing for a breath, and
-- the last palm sends it across the arena.
S.palms={
	opener="Lunge",close=2.0,
	caster={{0,"start"}},
	victim={{0,"start"},{3.32,"start"}},
	blows={{.3,false,"2 PALMS"},{.6,false,"4 PALMS"},{1.0,false,"8 PALMS"},{1.45,false,"16 PALMS"},{1.9,false,"32 PALMS"},{2.35,false,"64 PALMS"},{2.8,true,"128 PALMS"}},
	final={reaction="Knockback",push=P(0,12,0),away=86,stun=1},
	shots={
		{0,P(.8,15,-5),P(0,0,-1),50},
		{.48,P(4.6,1.6,-1.2),P(0,1.3,-1),46,true},{1.4,P(3.2,1.4,1),P(0,1.3,-1),44},
		{1.45,{"caster",P(1.1,1.9,-2.3)},{"victim",P(0,1,0)},40,true},
		{2.33,P(-.9,1.5,2.7),P(0,1.2,0),36,true},
		{3.0,P(6.5,2,-1),P(0,1,-1),50,true},
	},
	cues={{0,"trigrams"},{.3,"palmRain"},{3.0,"silence"},{3.3,"impactFrame"},{3.3,"lastPalm"}},
}

-- ITACHI - TSUKUYOMI. No blow is seen. The eye, close: the world goes red
-- and black, the body is on a cross under a red moon, and seventy-two hours
-- pass in a second (the swords, again and again); then the world comes back
-- and the body falls to its knees.
S.tsukuyomi={
	opener="Gaze",
	caster={{0,"start"}},
	victim={{0,"start"},{.4,"start"},{.7,P(0,1.2,0)},{3.35,P(0,1.2,0)},{3.45,P(0,0,0),"in"}},
	blows={{1.0,false,"72:00:00"},{1.7,false,"48:00:00"},{2.4,false,"24:00:00"},{3.0,true,"00:00:01"}},
	final={reaction="Knockdown",push=P(0,2,0),away=2,stun=1.6},
	shots={
		{0,{"caster",P(0,1.55,1.5)},{"caster",P(0,1.5,0)},28},
		{.5,P(4.2,1,4.2),{"victim",P(0,1,0)},50,true},{1.45,P(-4,1.3,4.4),{"victim",P(0,1,0)},48},
		{1.5,{"victim",P(.4,1.7,2.4)},{"victim",P(0,1.3,0)},40,true},
		{2.38,P(2,10,5),{"victim",P(0,0,0)},50,true},
		{3.32,P(6,2,-1.5),"mid",55,true},
	},
	cues={{0,"eye"},{.4,"redWorld"},{.7,"cross"},{1.0,"swords"},{1.7,"swords"},{2.4,"swords"},{3.0,"swords"},{3.32,"worldBack"}},
}

-- MINATO - YELLOW FLASH. A fan of marked kunai round the body; then time
-- stops (the world grey, the body frozen): he is at one kunai, then another,
-- then another - eight places in two seconds, a yellow streak behind each -
-- and he is behind the body, his back to it. Time starts: every cut lands at
-- once.
do
	local caster={{0,"start"},{.45,"start"}}
	local order={0,3,6,1,4,7,2,5}
	for i,k in order do
		local a=math.rad(k*45+22.5)
		table.insert(caster,{.5+(i-1)*.24,P(math.sin(a)*3.2,0,math.cos(a)*3.2),"snap",face="other"})
	end
	table.insert(caster,{2.42,P(0,0,2.8),"snap",face="away"})
	local ring={}
	for k=0,7 do local a=math.rad(k*45+22.5);ring[k+1]=P(math.sin(a)*3.6,0,math.cos(a)*3.6) end
	S.flash={
		opener="Throw",
		caster=caster,
		victim={{0,"start"},{2.9,"start"},{3.1,P(0,0,-.4)}},
		blows={{2.92,true},{2.96,true},{3.0,true},{3.04,true,"HIRAISHIN"}},
		final={reaction="Knockdown",push=P(0,-6,0),away=40,stun=1.1},
		kunai=ring,
		shots={
			{0,P(6.5,7,-8),P(0,1,-1),58},
			{.48,P(7,2,0),{"victim",P(0,1,0)},55,true},{1.1,P(5,3,5),{"victim",P(0,1,0)},55},{1.7,P(-5,2.5,5),{"victim",P(0,1,0)},55},{2.38,P(-7,2,0),{"victim",P(0,1,0)},55},
			{2.42,P(4.4,1.4,1.4),P(0,1.2,1.4),46,true},
			{2.92,P(5,1.6,1),P(0,1.2,1),50},
		},
		cues={{0,"kunaiFan"},{.5,"timeStop"},{2.9,"timeStart"},{2.9,"impactFrame"},{2.92,"cutsLand"}},
	}
end

-- KAKASHI - CHIDORI: RAIKIRI. His hounds burst out of the floor and pin the
-- body. He steps back; the hand signs; the Raikiri screams in his hand,
-- white, while he waits; then the run - slow first, the floor torn open
-- behind his hand, then flat out - and one thrust through.
S.raikiri={
	opener="Hounds",
	caster={{0,"start"},{.3,P(0,0,-10),"smooth"},{1.25,P(0,0,-10)},{2.42,P(0,0,-1.5),"in"},{2.86,P(0,0,-1.1)},{2.92,P(0,.4,-1.0)}},
	victim={{0,"start"},{2.38,"start"},{2.42,P(0,0,.3)},{2.92,P(0,.6,.6)}},
	blows={{.15},{2.42,true,"RAIKIRI"},{2.54},{2.66},{2.78}},
	final={reaction="Knockback",push=P(0,16,0),away=90,stun=1},
	shots={
		{0,P(4,1.2,-1),{"victim",P(0,.4,0)},50},
		{.4,{"caster",P(1.3,1.1,1.6)},{"caster",P(.5,1,.4)},36,true},
		{1.25,{"caster",P(0,.9,5.2)},{"caster",P(0,1.3,0)},50,true},
		{1.95,{"caster",P(8.5,1.4,0)},{"caster",P(0,1,0)},42,true},
		{2.4,P(2.9,1.4,-1.3),P(0,1.2,-.5),42,true},
		{2.92,P(7,2,4),P(0,1,2),58,true},
	},
	cues={{0,"hounds"},{.4,"raikiriCharge"},{1.25,"raikiriRun"},{2.42,"impactFrame"},{2.42,"impale"}},
}

-- The camera at t (anchor-frame eye and target, fov); `live` resolves a body.
function Scripts.shot(kind,t,live)
	local spec=S[kind]
	if not spec or not spec.shots then return nil end
	local shots=spec.shots
	local function point(v)
		if typeof(v)=="Vector3" then return v end
		if v=="mid" then return (live("caster")+live("victim"))*.5+P(0,1,0) end
		if type(v)=="table" then return live(v[1])+v[2] end
		return live("victim")
	end
	local i=1
	for n=1,#shots do if shots[n][1]<=t then i=n end end
	local a=shots[i]
	local b=shots[i+1]
	local eye,at,fov=point(a[2]),point(a[3]),a[4]
	if b and not b[5] then
		local k=math.clamp((t-a[1])/math.max(1e-3,b[1]-a[1]),0,1)
		k=k*k*(3-2*k)
		eye=eye:Lerp(point(b[2]),k);at=at:Lerp(point(b[3]),k);fov=fov+(b[4]-fov)*k
	end
	return eye,at,fov,i
end

return Scripts
