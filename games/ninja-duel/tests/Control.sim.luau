-- Not a test: a player's control, measured (user 29/10: "je pouvais plus
-- bouger", "c'est plein de bugs et d'incohérences"). A scripted pad player
-- (runs in, strings, mashes one button, jumps in and strikes on the way down,
-- dodges, jutsu) against the real AI, for each of the eight main fighters.
-- Every press goes through the same gate as a real one (the anti-cheat rate
-- gate of Matches:act, replayed on the duel clock) and then Combat:request.
-- Reports what a player feels:
--   dead presses   refused or dropped presses, by reason and by the state
--                  the player was in (a "free" refusal = Neutral, no reaction)
--   freezes        stick held, Neutral, grounded, no reaction, and the body
--                  does not move for 0.3 s
--   ghost air      "airborne" while standing on the floor for > 0.25 s
--   stuck states   one state or reaction lasting > 2 s
--   stun share     time in a reaction; the longest one without control
-- lune run tests/Control.sim.luau [seconds] [seeds] [fighter]
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local Tune=H.load("Shared/VelmoraCombatConfig")
local process=require("@lune/process")
-- tests/Control.spec.luau runs it as a release gate (ControlGate).
local gate=_G.ControlGate
local duration=if gate then gate.seconds else tonumber(process.args[1]) or 90
local seeds=if gate then 1 else tonumber(process.args[2]) or 2
local only=process.args[3]
if only=="all" or gate then only=nil end
-- "gate": fails when a player loses control (freeze, ghost air, stuck state,
-- too many eaten presses).
local GATE=gate~=nil or process.args[4]=="gate"
local MAIN={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf","Legion","Copycat"}
local DT=.02
local Motor=H.load("Server/Motor")
DEBUG_GHOST=process.args[4]=="ghost"

local function flat(v) return V.new(v.X,0,v.Z) end
local function inc(t,k,n) t[k]=(t[k] or 0)+(n or 1) end
local function list(t,limit)
 local o={}
 for k,v in t do table.insert(o,{k,v}) end
 table.sort(o,function(x,y) return x[2]>y[2] end)
 local s={}
 for i,p in o do if i>(limit or 99) then break end table.insert(s,p[1].."="..(if type(p[2])=="number" and p[2]%1~=0 then string.format("%.1f",p[2]) else tostring(p[2]))) end
 return table.concat(s,"  ")
end

local ALL={presses=0,dead=0,free=0,freezes=0,ghost=0,stuck=0,minutes=0,reasons={},freeReasons={},freezeWhere={},ghostWhere={},stuckWhere={}}

for _,id in MAIN do if not only or only==id then
 local row={presses=0,dead=0,free=0,reasons={},freeReasons={},freezes=0,freezeWhere={},ghost=0,ghostWhere={},stuck=0,stuckWhere={},
  stun=0,longestStun=0,eaten=0,eatenWhy={},time=0,kos=0,examples={}}
 for seed=1,seeds do
  H.clearWalls()
  local opp=MAIN[(table.find(MAIN,id)+seed*3-1)%#MAIN+1]
  if opp==id then opp=MAIN[(table.find(MAIN,id))%#MAIN+1] end
  local c,a,b,match=H.duel(id,opp)
  c:relocate(a,V.new(0,3,12));c:relocate(b,V.new(0,3,-12))
  a.ai=nil;a.playerInput=true
  local bot=AI.new(c,b,seed*13+1)
  local rng=H.envBase.Random.new(seed*7+#id)
  local gate={}
  local pendingRefused={}
  -- a late press that comes out (Combat: Config.Late) is not eaten
  local request=c.request
  c.request=function(self,actor,action,aim,clientTime,opts)
   local ok,reason=request(self,actor,action,aim,clientTime,opts)
   if actor==a and opts and opts.late then
    if ok~=false then row.lateFired=(row.lateFired or 0)+1;table.clear(pendingRefused) else row.lateRefused=(row.lateRefused or 0)+1 end
   end
   return ok,reason
  end
  local t=0
  -- the press gate of Matches:act (VelmoraAntiCheat), on the duel clock
  local function press(action)
   row.presses+=1
   local family=if string.match(action,"^Technique") then "Technique" else action
   local gap=Tune.Rates[family] or .04
   local free=a.state=="Neutral" and not a.reaction and a.health>0
   local ok,reason
   if gate[family] and c.now-gate[family]<gap then ok,reason=false,"RateGate"
   else gate[family]=c.now;ok,reason=c:request(a,action,b.root.Position) end
   if ok==false then
    row.dead+=1
    if reason~="Airborne" and not string.match(tostring(reason),"chakra") and reason~="Cooldown" then
     table.insert(pendingRefused,{t=t,action=action,why=tostring(reason).."@"..tostring(a.reaction or a.state)})
    end
    local key=tostring(reason).."@"..tostring(a.reaction or a.state)..(if a.airborne then "/air" else "")
    inc(row.reasons,key)
    if free then row.free+=1;inc(row.freeReasons,tostring(reason).."/"..action)
     if #row.examples<6 then table.insert(row.examples,string.format("%.1fs %s refused %s (Neutral%s)",t,action,tostring(reason),if a.airborne then ", air" else "")) end
    end
   end
   if ok~=false then table.clear(pendingRefused) end
   return ok~=false
  end
  -- a player's script, as a queue of (delay, fn)
  local queue={}
  local function after(d,fn) table.insert(queue,{at=t+d,fn=fn}) end
  local stick=V.zero
  local function hold(v) stick=v;a.move=v end
  local function plan()
   local to=flat(b.root.Position-a.root.Position)
   local gap=to.Magnitude
   local dir=if gap>.1 then to.Unit else V.zero
   local roll=rng:NextNumber()
   if a.reaction then
    if roll<.4 then after(0,function() press("Dodge") end) end
    after(.15,plan);return
   end
   if gap>9 then
    hold(dir);a.sprinting=true
    if gap<14 and roll<.4 then
     -- jump in and strike on the way down
     after(0,function() press("Jump") end)
     after(.25,function() press(if rng:NextNumber()<.5 then "Attack" else "Heavy") end)
     after(.5,function() press("Attack") end)
     after(.75,function() press("Heavy") end)
     after(1.0,plan);return
    end
    after(.12,plan);return
   end
   a.sprinting=false
   hold(if gap>4 then dir else V.zero)
   if roll<.12 then
    -- mash one button, as a person does when it works
    local key=({"Attack","Heavy","Attack","Jump"})[rng:NextInteger(1,4)]
    for i=0,5 do after(i*.13,function() press(key) end) end
    after(.9,plan);return
   elseif roll<.22 then
    after(0,function() press("Technique"..rng:NextInteger(1,math.min(#(a.def.Techniques or {"x"}),4))) end)
    after(.7,plan);return
   elseif roll<.32 then
    -- jump and attack straight down
    after(0,function() press("Jump") end)
    after(.18,function() press("Attack") end)
    after(.42,function() press("Attack") end)
    after(.66,function() press("Attack") end)
    after(1.0,function() hold(dir) end)
    after(1.1,plan);return
   elseif roll<.4 then
    after(0,function() hold(V.new(-dir.Z,0,dir.X));press("Dodge") end)
    after(.5,plan);return
   end
   -- a string, sometimes a route, sometimes a heavy
   local n=rng:NextInteger(2,4)
   for i=1,n do after((i-1)*.22,function()
    if i==3 and rng:NextNumber()<.4 then hold(if rng:NextNumber()<.5 then dir else -dir) end
    press("Attack") end) end
   if rng:NextNumber()<.4 then after(n*.22,function() press("Heavy") end) end
   after(n*.22+.3,function() hold(dir) end)
   after(n*.22+.35,plan)
  end
  plan()
  local last=a.root.Position
  local stillFor,ghostFor,since,lastKey,stunFor=0,0,0,nil,0
  local wasDead=false
  while t<duration do
   if match.phase~="Duel" then match.phase="Duel" end
   -- keep both alive: a KO ends nothing here (the KO beat is measured elsewhere)
   for _,f in {a,b} do if f.health<f.def.Health*.25 then f.health=f.def.Health;f.hum.Health=f.health end end
   -- the stick is held between presses, as on a pad
   a.move=stick
   table.sort(queue,function(x,y) return x.at<y.at end)
   while queue[1] and queue[1].at<=t do table.remove(queue,1).fn() end
   if a.state=="Defeated" then wasDead=true end
   -- eaten: refused, then free again within 0.25 s, and nothing came out
   if a.state=="Neutral" and not a.reaction and a.health>0 and not a.latePress then
    for _,p in pendingRefused do if t-p.t<=.25 then row.eaten+=1;inc(row.eatenWhy,p.why.."/"..p.action) end end
    table.clear(pendingRefused)
   end
   bot:update(c.now);H.step(c,DT);t+=DT
   local pos=a.root.Position
   local moved=(flat(pos)-flat(last)).Magnitude
   last=pos
   -- freeze: the player asks to move, nothing holds him, and he does not move
   local free=a.state=="Neutral" and not a.reaction and not a.airborne and stick.Magnitude>.5
   if free and moved<.02 then stillFor+=DT else
    if stillFor>=.3 then row.freezes+=1;inc(row.freezeWhere,string.format("%s hold=%s",tostring(a.attackName or "-"),tostring((a.airHold or 0)>c.now)))
     if #row.examples<12 then table.insert(row.examples,string.format("%.1fs FREEZE %.2fs (Neutral, stick held)",t,stillFor)) end end
    stillFor=0
   end
   -- ghost air: flagged airborne while standing on the floor
   if a.airborne and pos.Y<3.15 and math.abs(a.root.AssemblyLinearVelocity.Y)<1 then ghostFor+=DT
    if ghostFor>.25 and ghostFor<.27 and DEBUG_GHOST then print(string.format("GHOST %s t=%.2f state=%s atk=%s react=%s Y=%.2f vy=%.2f since=%s takeoff=%.2f hold=%.2f grounded=%s",id,t,a.state,tostring(a.attackName),tostring(a.reaction),pos.Y,a.root.AssemblyLinearVelocity.Y,tostring(a.airSince and c.now-a.airSince),(a.takeoffUntil or 0)-c.now,(a.airHold or 0)-c.now,tostring(Motor.grounded(a,c)))) end
   else
    if ghostFor>.25 then row.ghost+=1;inc(row.ghostWhere,tostring(a.reaction or a.state))
     if os.getenv and false then end end
    ghostFor=0
   end
   -- stuck: one state/reaction for > 2 s
   local key=tostring(a.state).."/"..tostring(a.reaction)
   if key~=lastKey then lastKey=key;since=t end
   if a.state~="Neutral" and a.state~="Guarding" and a.state~="Defeated" and t-since>2 then
    row.stuck+=1;inc(row.stuckWhere,key);since=t
   end
   -- stun: time without control in a reaction
   if a.reaction then row.stun+=DT;stunFor+=DT else row.longestStun=math.max(row.longestStun,stunFor);stunFor=0 end
  end
  row.time+=duration
 end
 local minutes=row.time/60
 print(string.format("\n== %s  (%.0f s)  presses %d, dead %d (%.0f%%), refused while free %d (%.0f%%)",
  id,row.time,row.presses,row.dead,row.dead/math.max(1,row.presses)*100,row.free,row.free/math.max(1,row.presses)*100))
 print("  dead by reason@state: "..list(row.reasons,10))
 print("  refused while free:  "..list(row.freeReasons,8))
 print(string.format("  freezes %d (%.1f/min)  %s",row.freezes,row.freezes/minutes,list(row.freezeWhere,4)))
 print(string.format("  ghost air %d  %s | stuck>2s %d  %s",row.ghost,list(row.ghostWhere,4),row.stuck,list(row.stuckWhere,4)))
 print(string.format("  in a reaction %.0f%% of the time, longest %.2f s",row.stun/row.time*100,row.longestStun))
 for _,e in row.examples do print("   · "..e) end
 ALL.eaten=(ALL.eaten or 0)+row.eaten;for k,v in row.eatenWhy do ALL.eatenWhy=ALL.eatenWhy or {};inc(ALL.eatenWhy,k,v) end
 ALL.presses+=row.presses;ALL.dead+=row.dead;ALL.free+=row.free;ALL.freezes+=row.freezes;ALL.ghost+=row.ghost;ALL.stuck+=row.stuck;ALL.minutes+=minutes
 for k,v in row.reasons do inc(ALL.reasons,k,v) end
 for k,v in row.freeReasons do inc(ALL.freeReasons,k,v) end
end end
print(string.format("\nALL %.0f min: presses %d, dead %.0f%%, refused while free %.0f%%, freezes %.1f/min, ghost air %d, stuck %d",
 ALL.minutes,ALL.presses,ALL.dead/math.max(1,ALL.presses)*100,ALL.free/math.max(1,ALL.presses)*100,ALL.freezes/ALL.minutes,ALL.ghost,ALL.stuck))
print(string.format("ALL eaten %d (%.0f%% of presses): %s",ALL.eaten or 0,(ALL.eaten or 0)/math.max(1,ALL.presses)*100,list(ALL.eatenWhy or {},12)))
print("ALL dead: "..list(ALL.reasons,14))
print("ALL refused while free: "..list(ALL.freeReasons,12))

if GATE then
 local eaten=(ALL.eaten or 0)/math.max(1,ALL.presses)
 local problems={}
 if eaten>.035 then table.insert(problems,string.format("%.1f%% of presses eaten",eaten*100)) end
 if ALL.freezes>0 then table.insert(problems,ALL.freezes.." freezes") end
 if ALL.ghost>0 then table.insert(problems,ALL.ghost.." ghost airborne") end
 if ALL.stuck>0 then table.insert(problems,ALL.stuck.." stuck states") end
 if #problems>0 then error("player control: "..table.concat(problems,", "),0) end
 print(string.format("NinjaDuel player control: PASS (%d presses, %.1f%% eaten, no freeze, no ghost air, no stuck state; headless pad player vs AI, 8 fighters)",ALL.presses,eaten*100))
end
