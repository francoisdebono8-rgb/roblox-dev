-- Mission FEEL (05/11), pass A: a simulated novice against the AI, headless.
-- The novice presses what a newcomer presses (light most, a heavy, a dodge,
-- the signature, a guard when hit), at a human rhythm (0.12-0.35 s), through
-- the real Combat:request with playerInput (late presses, the escape grace).
-- Prints what was asked and what came of it, with the refusal reasons, the
-- time the body could not act, and the hits both ways. Run from the game
-- folder: lune run tools/feel/novice.luau [fighter] [opponent] [level] [seed]
local H=require("../../tests/Harness")
local V=H.V
local AI=H.load("Server/AI")
local args=require("@lune/process").args
local fighter,other,level,seed=args[1] or "GentleFist",args[2] or "Flashstep",args[3] or "easy",tonumber(args[4]) or 1
local c,a,b=H.duel(fighter,other)
a.playerInput=true
c:relocate(a,V.new(0,3,8));c:relocate(b,V.new(0,3,-8))
local ai=AI.new(c,b,seed+10,level)
local rng={state=seed*7919+13}
function rng:NextNumber(lo,hi)
 self.state=(self.state*1103515245+12345)%2147483648
 local u=self.state/2147483648
 if lo then return lo+(hi-lo)*u end
 return u
end
local asked,results,reasons={},{},{}
local noControl,frames,committed=0,0,0
local nextPress=0
local guardUntil=0
local hpA,hpB=a.health,b.health
local signature="Technique2"
local DT=1/60
for f=1,60*60 do
 H.step(c,DT);ai:update(c.now)
 frames+=1
 if a.reaction or a.state=="Stunned" then noControl+=1
 elseif a.state~="Neutral" and a.state~="Guarding" then committed+=1 end
 local d=b.root.Position-a.root.Position;local flat=V.new(d.X,0,d.Z)
 a.move=if flat.Magnitude>5 then flat.Unit else V.zero
 a.sprinting=flat.Magnitude>14
 if guardUntil>0 and c.now>=guardUntil then guardUntil=0;c:request(a,"GuardOff") end
 if c.now>=nextPress and a.health>0 and b.health>0 then
  nextPress=c.now+rng:NextNumber(.12,.35)
  local action
  if a.reaction and rng:NextNumber()<.5 then action=if rng:NextNumber()<.5 then "Dodge" else "Attack"
  elseif flat.Magnitude>9 then action=if rng:NextNumber()<.2 then signature elseif rng:NextNumber()<.25 then "Tool" else nil
  else
   local r=rng:NextNumber()
   action=if r<.6 then "Attack" elseif r<.75 then "Heavy" elseif r<.85 then "Dodge" elseif r<.9 then signature else "Guard"
  end
  if action then
   asked[action]=(asked[action] or 0)+1
   local ok,why=c:request(a,action,b.root.Position)
   local key=action..":"..(if ok==false then tostring(why) elseif why then tostring(why) else "ok")
   results[key]=(results[key] or 0)+1
   if ok==false then reasons[tostring(why)]=(reasons[tostring(why)] or 0)+1 end
   if action=="Guard" and ok~=false then guardUntil=c.now+.4 end
  end
 end
 if a.health<=0 or b.health<=0 then break end
end
local function sorted(t) local l={} for k,v in t do table.insert(l,{k,v}) end table.sort(l,function(x,y) return x[2]>y[2] end) return l end
print(("%s vs %s (%s AI, seed %d): %.1f s, novice hp %.0f -> %.0f, AI hp %.0f -> %.0f, taking blows %.0f%%, in his own moves %.0f%%"):format(
 fighter,other,level,seed,frames*DT,hpA,a.health,hpB,b.health,100*noControl/frames,100*committed/frames))
local total,refused=0,0
for k,v in asked do total+=v end
for _,e in sorted(reasons) do refused+=e[2] end
print(("  presses %d, refused %d (%.0f%%)"):format(total,refused,100*refused/math.max(total,1)))
for _,e in sorted(results) do print(("    %-32s %d"):format(e[1],e[2])) end
