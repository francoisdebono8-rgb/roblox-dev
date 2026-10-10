-- Not a test: where the damage comes from in AI duels of one fighter.
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local focus="Sand"
for _,y in {"Flashstep","Mirage","GentleFist"} do
 local by={};local shields=0;local seeds=3
 for seed=1,seeds do
  H.clearWalls()
  local c,a,b,match=H.duel(focus,y)
  c.damageLog={}
  c:relocate(a,V.new(0,3,9));c:relocate(b,V.new(0,3,-9))
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local t=0
  while match.phase=="Duel" and t<120 do one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02 end
  for _,e in c.damageLog do local k=e.by..":"..e.tag;by[k]=(by[k] or 0)+e.amount/seeds end
  shields+=((a.events or {}).SandShield or 0)/seeds
 end
 print("== "..focus.." vs "..y..string.format("  shield answers %.0f",shields))
 local keys={};for k in by do table.insert(keys,k) end;table.sort(keys,function(p,q) return by[p]>by[q] end)
 for _,k in keys do print(string.format("   %-28s %.0f",k,by[k])) end
end
