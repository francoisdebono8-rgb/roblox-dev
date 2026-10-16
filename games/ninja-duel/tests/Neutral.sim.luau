-- Not a test: AI-vs-AI fight rhythm (mission convergence §8). For every ordered
-- matchup, a 60 s fight with both fighters kept alive (health only: chakra and
-- cooldowns stay real), sampled at 10 Hz. Reports what a minute of AI combat is
-- made of: distances, engagements, airborne time and the verbs actually used.
-- lune run tests/Neutral.sim.luau [seeds] [seconds]
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local process=require("@lune/process")
local seeds=tonumber(process.args[1]) or 2
local duration=tonumber(process.args[2]) or 60
local ids={"Flashstep","Mirage","GentleFist","Lion"}
local VERBS={"Attack","Heavy","Grab","Tool","Technique","Guard","Dodge","Substitute","Jump","Pursuit","Feint"}
local EVENTS={"Hit","GuardHit","Parry","Evaded","FeintStep","LaunchHit","Chase","WallSplat","Riposte"}
local total={samples=0,close=0,mid=0,far=0,vfar=0,air=0,guard=0,engage=0,minutes=0,verbs={},events={}}
for _,e in EVENTS do total.events[e]=0 end
for _,v in VERBS do total.verbs[v]=0 end
local function verbOf(action) return if string.match(action,"^Technique") then "Technique" else action end
for _,x in ids do for _,y in ids do if x~=y then
 local row={samples=0,close=0,mid=0,far=0,vfar=0,air=0,guard=0,engage=0,verbs={}}
 for _,v in VERBS do row.verbs[v]=0 end
 for seed=1,seeds do
  H.clearWalls()
  local c,a,b,match=H.duel(x,y)
  c:relocate(a,V.new(0,3,12));c:relocate(b,V.new(0,3,-12))
  -- Count every accepted request, whoever issued it.
  local request=c.request
  c.request=function(self,actor,action,...)
   local ok,reason=request(self,actor,action,...)
   if ok then local v=verbOf(action);if row.verbs[v] then row.verbs[v]+=1 end end
   return ok,reason
  end
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local before=table.clone(match.events)
  local t,nextSample,wasClose=0,0,false
  while t<duration do
   if match.phase~="Duel" then match.phase="Duel" end
   for _,f in {a,b} do if f.health<f.def.Health*.3 then f.health=f.def.Health;f.hum.Health=f.health end end
   one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
   if t>=nextSample then
    nextSample+=.1
    row.samples+=1
    local d=(V.new(a.root.Position.X,0,a.root.Position.Z)-V.new(b.root.Position.X,0,b.root.Position.Z)).Magnitude
    if d<7 then row.close+=1 elseif d<16 then row.mid+=1 elseif d<36 then row.far+=1 else row.vfar+=1 end
    if d<9 and not wasClose then row.engage+=1 end
    wasClose=d<9
    for _,f in {a,b} do
     if f.airborne then row.air+=.5 end
     if f.state=="Guarding" then row.guard+=.5 end
    end
   end
  end
  for _,e in EVENTS do total.events[e]+=(match.events[e] or 0)-(before[e] or 0) end
 end
 local n=math.max(1,row.samples);local minutes=seeds*duration/60
 local verbs={}
 for _,v in VERBS do table.insert(verbs,string.format("%s %.0f",v,row.verbs[v]/minutes/2)) end
 print(string.format("%-10s vs %-10s close %2.0f%% mid %2.0f%% far %2.0f%% vfar %2.0f%% | air %2.0f%% guard %2.0f%% engage/min %4.1f | per fighter/min: %s",
  x,y,row.close/n*100,row.mid/n*100,row.far/n*100,row.vfar/n*100,row.air/n*100,row.guard/n*100,row.engage/minutes,table.concat(verbs,", ")))
 for _,k in {"samples","close","mid","far","vfar","air","guard","engage"} do total[k]+=row[k] end
 total.minutes+=minutes
 for _,v in VERBS do total.verbs[v]+=row.verbs[v] end
end end end
local n=math.max(1,total.samples)
local verbs={}
for _,v in VERBS do table.insert(verbs,string.format("%s %.1f",v,total.verbs[v]/total.minutes/2)) end
print(string.format("ALL: close %.0f%% mid %.0f%% far %.0f%% vfar %.0f%% | air %.0f%% guard %.0f%% | engage/min %.1f",
 total.close/n*100,total.mid/n*100,total.far/n*100,total.vfar/n*100,total.air/n*100,total.guard/n*100,total.engage/total.minutes))
print("ALL per fighter per minute: "..table.concat(verbs,", "))
local evs={}
for _,e in EVENTS do table.insert(evs,string.format("%s %.1f",e,total.events[e]/total.minutes/2)) end
print("ALL events per fighter per minute: "..table.concat(evs,", "))
