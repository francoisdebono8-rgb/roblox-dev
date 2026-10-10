-- Not a test: AI-vs-AI balance matrix (single rounds, several seeds).
-- lune run tests/Balance.sim.luau [seeds]
local H=require("./Harness")
local V=H.V
-- The harness Random always answers .5; the matrix needs real seeded rolls.
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
local ids={"Flashstep","Mirage","GentleFist","Sand"}
local seeds=4
local wins,time={}, {}
for _,x in ids do wins[x]={};time[x]={} for _,y in ids do wins[x][y]=0;time[x][y]=0 end end
for _,x in ids do for _,y in ids do if x~=y then
 for seed=1,seeds do
  H.clearWalls()
  local c,a,b,match=H.duel(x,y)
  c:relocate(a,V.new(0,3,9));c:relocate(b,V.new(0,3,-9))
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local t=0
  while match.phase=="Duel" and t<120 do one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02 end
  local winner=if a.health<=0 then y elseif b.health<=0 then x elseif a.health/a.def.Health>b.health/b.def.Health then x else y
  if winner==x then wins[x][y]+=1 end
  time[x][y]+=t/seeds
 end
end end end
print("row beats column (of "..seeds.."), mean duration s")
local head="           ";for _,y in ids do head..=string.format("%-12s",y) end;print(head)
for _,x in ids do
 local line=string.format("%-11s",x)
 for _,y in ids do line..=if x==y then string.format("%-12s","-") else string.format("%-12s",wins[x][y].." "..string.format("%.0fs",time[x][y])) end
 print(line)
end
for _,x in ids do local w,n=0,0 for _,y in ids do if x~=y then w+=wins[x][y]+(seeds-wins[y][x]);n+=2*seeds end end print(string.format("%-11s %.0f%%",x,100*w/n)) end
