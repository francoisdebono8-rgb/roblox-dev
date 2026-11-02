-- (É7) The client's guesses of its own actions against what the server
-- really does. Presentation guesses a dodge and the strike a press will
-- start (ground and air, openers, strings, routes, re-entries) and draws them
-- at the press; a wrong guess is a body that goes one way and snaps back.
-- AI duels, random presses on the first fighter: the guess (from the
-- snapshot's guess view, Brawler.guessView, and what the client draws) is
-- compared with the server's outcome.
--
-- With ping: the client guesses from a snapshot LAG/2 old and its press
-- reaches the server LAG/2 later (one round trip after the state it read);
-- meanwhile the opponent fights on and the windows run out. Run at 0 and at
-- 100 ms; the 100 ms run is the one the player lives.
-- Measured 02/11 before the shared readers: 64 % of heavy and 60 % of light
-- guesses were another move (at 0 ms).
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local P=H.load("Client/Presentation")
local Brawler=H.load("Server/Brawler")

-- What the snapshot carries for the guess (Matches: the same fields).
local function snapshot(c,a,b)
 local now=c.now
 local h={state=a.state,reaction=a.reaction,airborne=a.airborne,wall=a.wall~=nil or nil,groundPose=a.groundPose,health=a.health,fighterId=a.fighterId,
  chakra=a.chakra,dodge=math.max(0,a.dodgeUntil-now),chakraLoad=if a.chakraLoad and a.chakraLoad.untilTime>now then a.chakraLoad.nature else nil,
  pursuit=math.max(0,a.pursuitUntil-now),attackName=a.attackName,attackSerial=a.attackSerial or 0,warpSerial=a.warpSerial or 0,
  bodyState=a.bodyState,counter=math.max(0,(a.counterUntil or 0)-now),awaken=math.max(0,(a.awakenUntil or 0)-now),
  illusion=math.max(0,a.illusionUntil-now),decoy=a.decoyPosition,velocity=a.root.AssemblyLinearVelocity,
  throwKind=a.throwKind,throwElapsed=now-(a.throwStarted or -10),throwRelease=a.throwRelease or .1,
  guess=Brawler.guessView(c,a)}
 local bot={id="b",state=b.state,health=b.health,lookVector=b.root.CFrame.LookVector,airborne=b.airborne,reaction=b.reaction,groundPose=b.groundPose,
  tenketsu=if (b.tenketsuUntil or 0)>now then b.tenketsu or 0 else 0}
 return {human=h,bot=bot}
end

local function run(lag)
 local stats={Dodge={tp=0,fp=0,fn=0,tn=0,hit=0},Attack={tp=0,fp=0,fn=0,tn=0,hit=0},Heavy={tp=0,fp=0,fn=0,tn=0,hit=0},Air={tp=0,fp=0,fn=0,tn=0,hit=0}}
 local wrong={}
 local rng=H.envBase.Random.new(5)
 for index,pair in {{"Lion","Mirage"},{"Legion","Leaf"},{"Sand","GentleFist"},{"Copycat","Flashstep"}} do
  for seed=1,2 do
   H.clearWalls()
   -- (one duel in two by a wall: the string's drive into it is read too)
   if seed==2 then H.addWall(14) end
   local c,a,b,match=H.duel(pair[1],pair[2])
   c:relocate(a,V.new(0,3,10));c:relocate(b,V.new(0,3,-10))
   local one,two=AI.new(c,a,seed*7+index),AI.new(c,b,seed*13+1)
   local p=setmetatable({smooth={human={pos=a.root.Position},bot={pos=b.root.Position}},clocks={},last={}},{__index=P})
   local queue={}
   local t=0
   while match.phase=="Duel" and t<60 do
    -- (the player's own hands: no other input of his while a press is in
    -- flight; the opponent keeps fighting and the timers keep running)
    if not queue[1] then one:update(c.now) end
    two:update(c.now);H.step(c,.02);t+=.02
    -- what this client draws and reads: the snapshot of now, pressed now,
    -- reaching the server LAG later (it left LAG/2 ago, the press takes LAG/2)
    p.smooth.human.pos=a.root.Position;p.smooth.bot.pos=b.root.Position;p.smooth.bot.vel=b.locomotion or V.zero
    p.inputDir=a.move;p.inputSprint=a.sprinting;p.lead={v=a.locomotion or V.zero};p.myLook=a.root.CFrame.LookVector
    P.observeStick(p,c.now)
    -- (more presses in the air: air time is short and its reading is its own)
    if not queue[1] and rng:NextNumber()<(if a.airborne then .3 else .08) then
     local action=({"Dodge","Attack","Heavy"})[rng:NextInteger(1,3)]
     local data=snapshot(c,a,b)
     p.prediction=nil;p.movePrediction=nil;p.lastDodgeGuess=nil
     local guessed
     if action=="Dodge" then P.predictMove(p,"Dodge",data,lag);guessed=p.movePrediction~=nil
     else P.predictStrike(p,action,data,c.now,lag);guessed=p.prediction and p.prediction.name or nil end
     table.insert(queue,{due=c.now+lag,action=action,guessed=guessed,h=data.human,hurt=a.lastHurt})
    end
    -- presses reaching the server
    while queue[1] and queue[1].due<=c.now+1e-9 do
     local q=table.remove(queue,1)
     local action,guessed,h=q.action,q.guessed,q.h
     local before,beforeDodge=a.attackSerial or 0,a.dodgeUntil
     c:request(a,action,b.root.Position)
     local did
     if action=="Dodge" then did=a.dodgeUntil~=beforeDodge
     else did=(a.attackSerial or 0)~=before and a.attackName or nil end
     local s=if action~="Dodge" and h.airborne then stats.Air else stats[action]
     if guessed and did and (action=="Dodge" or guessed==did) then s.tp+=1
     elseif guessed and a.lastHurt~=q.hurt then s.hit+=1
     elseif guessed then s.fp+=1;table.insert(wrong,action..": guessed "..tostring(guessed).." got "..tostring(did).." state "..h.state.." air "..tostring(h.airborne))
     elseif did then s.fn+=1
     else s.tn+=1 end
    end
   end
  end
 end
 H.clearWalls()
 return stats,wrong
end

for _,lag in {0,.1} do
 local stats,wrong=run(lag)
 print(string.format("-- ping %d ms",lag*1000))
 for _,k in {"Attack","Heavy","Air","Dodge"} do local s=stats[k];print(string.format("%s: right %d, wrong guess %d (+%d hit in flight), missed %d, nothing %d",k,s.tp,s.fp,s.hit,s.fn,s.tn)) end
 for i=1,math.min(8,#wrong) do print("  "..wrong[i]) end
 for _,k in {"Attack","Heavy","Air","Dodge"} do
  local s=stats[k]
  local guessed=s.tp+s.fp
  assert(guessed>=(if lag==0 then (if k=="Air" then 8 else 20) else (if k=="Air" then 4 else 15)),k..": too few guesses to judge ("..guessed..") at "..lag*1000 .." ms")
  -- At 0 ms the client reads exactly what the server reads; with ping the
  -- opponent fights on during the trip. A blow landing on the body in flight
  -- turns any press into another outcome (a dodge into the substitution): it
  -- is counted apart; the cap is on what the client could have read.
  local cap=if lag==0 then .08 else .15
  assert(s.fp/guessed<=cap,string.format("%s: %d of %d guesses were another move at %d ms",k,s.fp,guessed,lag*1000))
  assert(s.hit<=s.tp*.25,string.format("%s: %d guesses undone by a blow in flight (%d right)",k,s.hit,s.tp))
 end
end
print("NinjaDuel prediction agreement: 1 PASS (wrong guesses within 8 % at 0 ms, 15 % at 100 ms)")
