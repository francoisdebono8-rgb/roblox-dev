-- Not a test: the CM's QA of 14/11 (docs/reports/qa-combats-2026-11-14), in
-- numbers, on the six AI-vs-AI fights it reviewed (several seeds each):
--   D1 body strikes that land with the limb more than a stud short of the
--      body (roots more than contact + 2 apart);
--   D3 time two standing bodies spend closer than Config.Bodies.Floor;
--   D5 how long both AIs wait before the first strike, jutsu or approach.
-- lune run tests/QACombats.sim.luau [seeds]
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local Config=H.load("Shared/Config")
Config.DamageScale=H.GameDamageScale
local fights={{"Lion","Mirage"},{"Sand","Flashstep"},{"Legion","Copycat"},{"Leaf","Mirage"},{"GentleFist","Flashstep"},{"Lion","Copycat"}}
local seeds=tonumber((...)) or 3
local total={strikes=0,short=0,inside=0,time=0,wait=0,fights=0}
local deep
for _,pair in fights do
 local x,y=pair[1],pair[2]
 local strikes,short,inside,time,wait=0,0,0,0,0
 local worst={}
 for seed=1,seeds do
  H.clearWalls()
  local c,a,b,match=H.duel(x,y)
  local damage=c.damage
  c.damage=function(self,attacker,victim,amount,heavy,readEligible)
   local p=attacker.pending
   if readEligible and not self.thrownHit and p and p.kind=="Brawl" then
    local from=self.hitOrigin or attacker.root.Position
    local d=(victim.root.Position-from)*V.new(1,0,1)
    local over=d.Magnitude-(p.spec.contact or 3.6)
    strikes+=1
    -- (the CM's measure is limb to body: the limb ends about contact + 0.25
    -- from the root and a body's surface is ~0.75 from its root, so a limb a
    -- stud short is the roots ~2 studs past contact)
    if over>2 then short+=1;table.insert(worst,string.format("%s %s %.1f",attacker.fighterId,p.name,over)) end
   end
   return damage(self,attacker,victim,amount,heavy,readEligible)
  end
  -- as a real duel starts them (Matches:start): StartDistance each side, facing
  c:relocate(a,match.origin+V.new(0,3,Config.StartDistance));c:relocate(b,match.origin+V.new(0,3,-Config.StartDistance))
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local t,first=0,nil
  local acted=nil
  local request=c.request
  c.request=function(self,actor,action,...)
   local ok,r=request(self,actor,action,...)
   if ok and not acted and action~="Move" and action~="Guard" and action~="GuardEnd" then acted=t end
   return ok,r
  end
  local start=(a.root.Position-b.root.Position).Magnitude
  while match.phase=="Duel" and t<60 do
   one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
   local d=(b.root.Position-a.root.Position)
   local flat=V.new(d.X,0,d.Z).Magnitude
   local standing=not a.airborne and not b.airborne and math.abs(d.Y)<2 and a.state~="Dodging" and b.state~="Dodging" and not a.reaction and not b.reaction
   if standing and flat<Config.Bodies.Floor-.05 then inside+=.02 end
   if flat<2.2 and math.abs(d.Y)<2.5 then deep=(deep or 0)+.02 end
   if not first and (acted or (a.root.Position-b.root.Position).Magnitude<start-3) then first=t end
  end
  time+=t;wait+=(first or t)
 end
 total.strikes+=strikes;total.short+=short;total.inside+=inside;total.time+=time;total.wait+=wait;total.fights+=seeds
 print(string.format("%s vs %s: D1 %d/%d blows landing with the limb >1 stud short | D3 %.1f s of %.0f inside each other (any state < 2.2: %.1f s) | D5 first move after %.1f s",
  x,y,short,strikes,inside,time,deep or 0,wait/seeds));deep=0
 if #worst>0 then print("   e.g. "..table.concat(worst,", ",1,math.min(#worst,6))) end
end
print(string.format("ALL: D1 %d/%d short (%.0f%%) | D3 %.1f s inside per minute | D5 first move after %.1f s on average",
 total.short,total.strikes,100*total.short/math.max(1,total.strikes),60*total.inside/total.time,total.wait/total.fights))
