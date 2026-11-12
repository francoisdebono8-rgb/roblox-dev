-- Not a test: the QA test of b822ee5 (12/11) in numbers, AI against AI on
-- the four pairs it filmed (95 s rounds, several seeds): what each bot uses
-- (techniques by id, blades, wall dives, teleports, clone switches), the
-- longest run of one move, the time to a K.O., and how far from the middle
-- the fight is. lune run tests/AIVariety.sim.luau [seeds]
local H=require("./Harness")
local V=H.V
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local AI=H.load("Server/AI")
H.load("Shared/Config").DamageScale=H.GameDamageScale
local Copy=H.load("Server/Copy")
local pairs4={{"Lion","Sand"},{"Legion","GentleFist"},{"Leaf","Flashstep"},{"Copycat","Mirage"}}
local seeds=tonumber((...)) or 3
local function label(c,a,action)
 if string.sub(action,1,9)=="Technique" then
  local slot=tonumber(string.sub(action,10))
  local spec=slot and (Copy.slotSpec(c,a,slot) or a.def.Techniques[slot])
  return spec and spec.Id or action
 elseif string.sub(action,1,4)=="Seal" then
  local spec=a.def.SealJutsu and a.def.SealJutsu[tonumber(string.sub(action,5)) or 0]
  return "Seal:"..(spec and spec.Id or action)
 elseif action=="Attack" and a.wall then return "WallDive"
 elseif action=="Tool" then return "Tool" end
 return nil
end
for _,pair in pairs4 do
 local x,y=pair[1],pair[2]
 local uses={[x]={},[y]={}}
 local kos,ko,far,samples,edge=0,0,0,0,0
 for seed=1,seeds do
  H.clearWalls()
  local c,a,b,match=H.duel(x,y)
  c:relocate(a,V.new(0,3,24));c:relocate(b,V.new(0,3,-24))
  local request=c.request
  c.request=function(self,actor,action,...)
   local ok,r=request(self,actor,action,...)
   if ok then
    local name=label(self,actor,action)
    if name then local u=uses[actor.fighterId];u[name]=(u[name] or 0)+1 end
   end
   return ok,r
  end
  local one,two=AI.new(c,a,seed*7),AI.new(c,b,seed*13+1)
  local t=0
  while match.phase=="Duel" and t<95 do
   one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
   local mid=(a.root.Position+b.root.Position)/2-match.origin
   local r=V.new(mid.X,0,mid.Z).Magnitude
   far+=r;samples+=1;if r>70 then edge+=1 end
  end
  if a.health<=0 or b.health<=0 then kos+=1;ko+=t end
  -- signatures placed this match (per seed)
  for _,actor in {a,b} do
   local missing={}
   for _,spec in actor.def.Techniques do
    if not (one.placed and one.actor==actor and one.placed[spec.Id]) and not (two.placed and two.actor==actor and two.placed[spec.Id]) then table.insert(missing,spec.Id) end
   end
   if #missing>0 then print(string.format("    seed %d %s never placed: %s",seed,actor.fighterId,table.concat(missing,", "))) end
  end
 end
 print(string.format("%s vs %s: K.O. %d/%d (mean %.0f s), fight centre mean %.0f studs from the middle, %.0f%% of the time beyond 70",
  x,y,kos,seeds,if kos>0 then ko/kos else 0,far/samples,100*edge/samples))
 for _,id in {x,y} do
  local list={}
  for name,n in uses[id] do table.insert(list,{name,n}) end
  table.sort(list,function(p,q) return p[2]>q[2] end)
  local line=""
  for _,p in list do line..=string.format("%s %.1f  ",p[1],p[2]/seeds) end
  print("  "..id..": "..line)
 end
end
