-- (É7) The client's guesses of its own actions against what the server
-- really does. Presentation guesses a dodge, a jump-free dodge and the strike
-- a press will start, and draws them at the press; a wrong guess is a body
-- that goes one way and snaps back. AI duels, random presses on the first
-- fighter: the guess (from what the snapshot carries and what the client
-- draws) is compared with the server's outcome. Measured 02/11 before the
-- shared readers: 64 % of heavy and 60 % of light guesses were another move.
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
local Config=H.load("Shared/Config")
local stats={Dodge={tp=0,fp=0,fn=0,tn=0},Attack={tp=0,fp=0,fn=0,tn=0},Heavy={tp=0,fp=0,fn=0,tn=0}}
local wrong={}
local passed=0
local rng=H.envBase.Random.new(5)
for _,pair in {{"Lion","Mirage"},{"Legion","Leaf"},{"Sand","GentleFist"},{"Copycat","Flashstep"}} do
 for seed=1,2 do
  local c,a,b,match=H.duel(pair[1],pair[2])
  c:relocate(a,V.new(0,3,10));c:relocate(b,V.new(0,3,-10))
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local t=0
  while match.phase=="Duel" and t<60 do
   one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
   if rng:NextNumber()<.08 then
    local action=({"Dodge","Attack","Heavy"})[rng:NextInteger(1,3)]
    local now=c.now
    local h={state=a.state,reaction=a.reaction,airborne=a.airborne,wall=a.wall~=nil or nil,groundPose=a.groundPose,health=a.health,fighterId=a.fighterId,
     chakra=a.chakra,dodge=math.max(0,a.dodgeUntil-now),chakraLoad=if a.chakraLoad and a.chakraLoad.untilTime>now then a.chakraLoad.nature else nil,
     pursuit=math.max(0,a.pursuitUntil-now),attackName=a.attackName,attackSerial=a.attackSerial or 0,warpSerial=a.warpSerial or 0,
     riposte=(a.riposteUntil or 0)>now or (a.counterUntil or 0)>now,cancelReady=(a.state=="Recovery" or a.state=="TechniqueRecovery") and now>=(a.recoveryCancelAt or math.huge),jumpCancel=a.state=="Recovery" and now>=(a.recoveryCancelAt or 0),bodyState=a.bodyState,chainReady=Brawler.chainWindow(c,a),stringAlive=Brawler.stringAlive(c,a,false),arrival=Brawler.arrival(c,a)==true}
    local p=setmetatable({smooth={human={pos=a.root.Position},bot={pos=b.root.Position}},clocks={},last={}},{__index=P})
    p.inputDir=a.move;p.inputSprint=a.sprinting;p.lead={v=a.locomotion or V.zero}
    local data={human=h,bot={id="b",state=b.state,health=b.health,lookVector=b.root.CFrame.LookVector,airborne=b.airborne,reaction=b.reaction,groundPose=b.groundPose}}
    p.myLook=a.root.CFrame.LookVector
    local guessed
    if action=="Dodge" then P.predictMove(p,"Dodge",data);guessed=p.movePrediction~=nil
    else P.predictStrike(p,action,data);guessed=p.prediction and p.prediction.name or nil end
    local before=a.attackSerial or 0
    local ok=c:request(a,action,b.root.Position)
    local did
    if action=="Dodge" then did=a.state=="Dodging"
    else did=(a.attackSerial or 0)~=before and a.attackName or nil end
    local s=stats[action]
    if guessed and did and (action=="Dodge" or guessed==did) then s.tp+=1
    elseif guessed then s.fp+=1;table.insert(wrong,action..": guessed "..tostring(guessed).." got "..tostring(did).." state "..h.state.." air "..tostring(h.airborne))
    elseif did then s.fn+=1;if action=="Dodge" then table.insert(wrong,"MISSED dodge: state "..h.state.." air "..tostring(h.airborne).." chakra "..math.floor(h.chakra).." cd "..string.format('%.2f',h.dodge).." sprint "..tostring(a.sprinting)) end
    else s.tn+=1 end
   end
  end
 end
end
for k,s in stats do print(string.format("%s: right %d, wrong guess %d, missed %d, nothing %d",k,s.tp,s.fp,s.fn,s.tn)) end
for i=1,math.min(6,#wrong) do print("  "..wrong[i]) end

for k,s in stats do
 local guessed=s.tp+s.fp
 assert(guessed>=20,k..": too few guesses to judge ("..guessed..")")
 assert(s.fp/guessed<=.12,string.format("%s: %d of %d guesses were another move",k,s.fp,guessed))
end
print("NinjaDuel prediction agreement: 1 PASS (wrong guesses within 12 %)")
