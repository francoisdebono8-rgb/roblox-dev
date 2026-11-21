-- The things to do alone in Konoha (21/11, étape 3 DEV 4, DEC-047; François
-- after playing: « il n'y a rien à faire dans le village s'il n'y a personne,
-- à part spammer »).
--   RACE       the rooftop race: from the start post at THE ROOFTOPS, ten
--              rings on the roofs of the market streets, in order, against
--              the clock. The best time goes on the board (Server/Leaderboards
--              "Rooftops", fastest first) and earns ROOFTOP RUNNER.
--   TARGETS    the kunai targets: eight boards down the market lane, every
--              one hit, as fast as possible (a miss costs a second).
--   TRAINING   the dummy of Training Ground Three (Server/Tutorial): each step
--              of his kit done there pays.
--   CHALLENGE  an inspiration who waits in a street of the village: beat him
--              where he stands (Server/SoloPlay).
--   ANYWHERE   a duel asked while walking is fought in the nearest free place
--              of the village (Server/Matches.nearSite), not in the stadium.
-- Everything pays mastery to the kit he has chosen (when he owns it), up to
-- a day's share (DayCap): the profile's record `solo` (Server/ProfileSchema,
-- command soloRecord). Pure: the server's rules, the client's view, the suite.
-- Places are in the plan's base studs (Shared/KonohaLayout, x z and the height
-- y over the ground); Solo.world turns them into the world's.
local HubMap=require(script.Parent.HubMap)

local Solo={}
local S=HubMap.Scale or 1

-- A base position (x, y, z) in the world.
function Solo.world(x,y,z) return HubMap.Origin+Vector3.new(x,y,z)*S end

-- ------------------------------------------------------------------ the race
-- rings: {x, top, z}: the roof (or deck) top each stands on, in order.
Solo.Race={
	start={44,0,122},          -- the start post, at THE ROOFTOPS
	startReach=10,             -- he starts within this of the post
	radius=7,                  -- a ring is passed within (across, base studs)
	above=8,                   -- and up to this over its roof
	countdown=3,               -- 3, 2, 1, GO (s)
	limit=240,                 -- given up after (s)
	maxAcross=90,              -- world studs a second across, at most (more: a teleport)
	rings={
		{60,10,104},           -- the rooftops' deck
		{71.6,15,74},          -- the townhouse over the market lane
		{99.5,22,91},          -- the walkway block
		{130.5,15,89},         -- across the north lane
		{160,15,106},          -- the shops in the middle
		{155.9,22,134.5},      -- up the tank house
		{130.5,15,170.4},      -- back west over the cross lane
		{99.5,15,170.5},
		{71.6,15,165.5},
		{36,13,136},           -- home: the rooftops' last deck
	},
}
-- The world position of ring i (its centre, a little over the roof).
function Solo.ring(i)
	local r=Solo.Race.rings[i]
	return r and Solo.world(r[1],r[2]+3,r[3])
end
function Solo.startPost() local p=Solo.Race.start;return Solo.world(p[1],0,p[3]) end
-- The route's length across (world studs): the start, ring to ring.
function Solo.raceLength()
	local total,last=0,Solo.startPost()
	for i in Solo.Race.rings do
		local at=Solo.ring(i)
		total+=(Vector3.new(at.X,0,at.Z)-Vector3.new(last.X,0,last.Z)).Magnitude
		last=at
	end
	return total
end
-- The fastest a run can honestly be (s): the route at a speed no walker has.
function Solo.raceFloor() return Solo.raceLength()/60 end
-- Whether `pos` (a world position: the body's root) passes ring i.
function Solo.inRing(i,pos)
	local r=Solo.Race.rings[i]
	if not r then return false end
	local at=Solo.world(r[1],r[2],r[3])
	local across=(Vector3.new(pos.X,0,pos.Z)-Vector3.new(at.X,0,at.Z)).Magnitude
	local up=pos.Y-at.Y
	return across<=Solo.Race.radius*S and up>=-1 and up<=Solo.Race.above*S
end
-- A new run, started at `now` (the clock starts after the countdown).
function Solo.newRun(now,pos)
	return {kind="race",at=now+Solo.Race.countdown,next=1,last=pos,lastAt=now}
end
-- One sample of a run: the body at `pos` at `now`. Returns what happened:
-- "ring" (index), "finish" (time, s), "fail" (why), nil.
function Solo.raceStep(run,pos,now)
	if run.done then return nil end
	if now<run.at then
		-- the countdown: he waits at the post
		if (Vector3.new(pos.X,0,pos.Z)-Vector3.new(Solo.startPost().X,0,Solo.startPost().Z)).Magnitude>Solo.Race.startReach*S*1.5 then
			run.at=now+Solo.Race.countdown
		end
		run.last,run.lastAt=pos,now
		return nil
	end
	local dt=now-run.lastAt
	if dt>.04 then
		local across=(Vector3.new(pos.X,0,pos.Z)-Vector3.new(run.last.X,0,run.last.Z)).Magnitude
		if across/dt>Solo.Race.maxAcross then run.done=true;return "fail","teleport" end
		run.last,run.lastAt=pos,now
	end
	if now-run.at>Solo.Race.limit then run.done=true;return "fail","time" end
	if Solo.inRing(run.next,pos) then
		local i=run.next
		run.next+=1
		if run.next>#Solo.Race.rings then
			run.done=true
			local time=now-run.at
			if time<Solo.raceFloor() then return "fail","floor" end
			return "finish",time
		end
		return "ring",i
	end
	return nil
end

-- ------------------------------------------------------------------ the targets
-- boards: {x, y, z}: each board's centre (y over the ground), facing the mark.
Solo.Targets={
	mark={30,0,56},            -- the throw mark, at the market lane's mouth
	reach=36,                  -- he throws from within this of the mark
	radius=1.6,                -- a board is hit within this of its centre (world)
	range=90,                  -- a kunai flies this far (world)
	gap=.3,                    -- one throw every
	miss=1,                    -- a miss costs (s)
	limit=60,                  -- given up after (s)
	countdown=3,
	boards={
		{46,5,56.5},{52,8,54.5},{58,4,57.5},{64,9,55},
		{70,6,57},{76,3.5,54.5},{82,10,56},{88,6,55.5},
	},
}
function Solo.board(i)
	local b=Solo.Targets.boards[i]
	return b and Solo.world(b[1],b[2],b[3])
end
function Solo.targetsMark() local m=Solo.Targets.mark;return Solo.world(m[1],0,m[3]) end
function Solo.newTargets(now)
	local up={}
	for i in Solo.Targets.boards do up[i]=true end
	return {kind="targets",at=now+Solo.Targets.countdown,up=up,left=#Solo.Targets.boards,misses=0,lastThrow=-10}
end
-- The board a kunai thrown from `origin` along `direction` (unit) hits first,
-- among those still up: its index, the point, the distance; nil: a miss.
function Solo.hitBoard(round,origin,direction)
	local best,bestT,bestAt=nil,Solo.Targets.range,nil
	local r=Solo.Targets.radius
	for i,on in round.up do
		if on then
			local c=Solo.board(i)
			local m=origin-c
			local b=m:Dot(direction)
			local q=m:Dot(m)-r*r
			local disc=b*b-q
			if disc>=0 then
				local t=-b-math.sqrt(disc)
				if t<0 then t=-b+math.sqrt(disc) end
				if t>=0 and t<bestT then best,bestT,bestAt=i,t,origin+direction*t end
			end
		end
	end
	return best,bestAt,bestT
end
-- A throw at `now`: "hit" (index, point), "done" (time with the misses), "miss", "wait", "fail".
function Solo.throw(round,origin,direction,now)
	if round.done then return nil end
	if now<round.at or now-round.lastThrow<Solo.Targets.gap then return "wait" end
	if now-round.at>Solo.Targets.limit then round.done=true;return "fail","time" end
	round.lastThrow=now
	local i,at=Solo.hitBoard(round,origin,direction)
	if not i then round.misses+=1;return "miss" end
	round.up[i]=false;round.left-=1
	if round.left<=0 then
		round.done=true
		return "done",now-round.at+round.misses*Solo.Targets.miss,i,at
	end
	return "hit",i,at
end
-- Whether he stands where he may throw.
function Solo.atMark(pos)
	local m=Solo.targetsMark()
	return (Vector3.new(pos.X,0,pos.Z)-Vector3.new(m.X,0,m.Z)).Magnitude<=Solo.Targets.reach*S
end

-- ------------------------------------------------------------------ the challenge
-- An inspiration waits in a street of the village (HubMap.Streets) for a while;
-- whoever walks up and accepts fights him there, at Level. Won: Gain.Challenge.
Solo.Challenge={every=70,stay=150,level="normal",lines={
	Leaf="My youth burns hot today. Show me yours!",
	Lion="You are in my way. Prove you are not weak.",
	Legion="Believe it! Fight me right here, right now!",
	Copycat="Let us see what you have learned.",
	Sand="Come. Your existence will prove mine.",
	GentleFist="Fate brought you to me. Fight.",
	Flashstep="A quick one? I will not hold back.",
	Mirage="You lack hatred. Show me otherwise.",
}}

-- ------------------------------------------------------------------ what it pays
-- Mastery to his chosen kit; Ryō for nothing here (the duels pay those).
Solo.Gain={
	RaceFirst=60,      -- the first rooftop race finished
	RaceBest=35,       -- a new best time
	RaceDone=15,       -- another one
	TargetsFirst=40,TargetsBest=25,TargetsDone=10,
	Step=4,            -- a step of his kit done with the dummy
	ChallengeWon=60,ChallengeLost=10,
}
Solo.DayCap=300        -- the day's share of mastery from the things done alone
Solo.MAX=100000000

-- The profile's record. Times in hundredths (0: never finished).
function Solo.new() return {day=0,earned=0,rooftops={best=0,runs=0},targets={best=0,runs=0},challenges=0} end
local function whole(n,max) return type(n)=="number" and n==math.floor(n) and n>=0 and n<=(max or Solo.MAX) end
function Solo.valid(r)
	if type(r)~="table" or not whole(r.day) or not whole(r.earned,Solo.DayCap) or not whole(r.challenges) then return false,"solo record" end
	for _,key in {"rooftops","targets"} do
		local t=r[key]
		if type(t)~="table" or not whole(t.best) or not whole(t.runs) then return false,"solo "..key end
	end
	return true
end
-- Hundredths of a second, rounded.
function Solo.hundredths(seconds) return math.max(1,math.floor(seconds*100+.5)) end
-- "0:42.31" from hundredths.
function Solo.clock(cs)
	cs=math.max(0,math.floor(cs or 0))
	local minutes=math.floor(cs/6000)
	local rest=cs-minutes*6000
	return string.format("%d:%02d.%02d",minutes,math.floor(rest/100),rest%100)
end
-- Pays `amount` within the day's share (a new day starts it over): what it pays.
function Solo.pay(r,day,amount)
	if r.day~=day then r.day=day;r.earned=0 end
	local paid=math.clamp(math.floor(amount),0,Solo.DayCap-r.earned)
	r.earned+=paid
	return paid
end
-- A thing done: kind "race" or "targets" (time: hundredths), "step",
-- "challenge" (won). Returns {paid, best, improved, first, runs}.
function Solo.record(r,day,kind,args)
	local G=Solo.Gain
	if kind=="race" or kind=="targets" then
		local t=if kind=="race" then r.rooftops else r.targets
		local first=t.best==0
		local improved=first or args.time<t.best
		if improved then t.best=args.time end
		t.runs=math.min(Solo.MAX,t.runs+1)
		local amount=if kind=="race" then (if first then G.RaceFirst elseif improved then G.RaceBest else G.RaceDone)
			else (if first then G.TargetsFirst elseif improved then G.TargetsBest else G.TargetsDone)
		return {paid=Solo.pay(r,day,amount),best=t.best,improved=improved,first=first,runs=t.runs}
	elseif kind=="step" then
		return {paid=Solo.pay(r,day,G.Step)}
	elseif kind=="challenge" then
		if args.won then r.challenges=math.min(Solo.MAX,r.challenges+1) end
		return {paid=Solo.pay(r,day,if args.won then G.ChallengeWon else G.ChallengeLost),challenges=r.challenges}
	end
	error("Unknown solo kind")
end

return Solo
