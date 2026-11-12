-- Feel audit of 07/11, M5 "jutsu de déplacement sans trajet": the ANIMATEUR
-- needs to know when a body travels on its own (a teleport jutsu, a signature
-- dash) and when it arrives, before making the trails and arrival poses.
-- Combat:travelStart / travelArrive -> a.travel, the duel state's `travel`
-- (Combat:travelView) and impacts "travel" (depart, arrive).
--   1. Lightning Strike (Minato) and Lightning Cut (Kakashi): from, to, the
--      jutsu's Id, arrived at once; gone from the state Travel.Show s later.
--   2. A signature dash (the re-entry rush): departs with its style's name and
--      a planned arrival, arrives at its end.
--   3. A blow taken on the way ends it.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Config=H.load("Shared/Config")
local Brawler=H.load("Server/Brawler")
local function flat(v) return V.new(v.X,0,v.Z) end
local function impacts(c,phase)
 local out={}
 for _,e in c.impacts or {} do if e.style=="travel" and e.phase==phase then table.insert(out,e) end end
 return out
end

test("Lightning Strike and Lightning Cut say where from, where to, and that they arrived",function()
 for _,case in {{"Flashstep","LightningStrike"},{"Copycat","LightningCut"}} do
  local c,a,b=H.duel(case[1],"Mirage")
  a.ai=nil;b.ai=nil
  c:relocate(a,V.new(0,3,8));c:relocate(b,V.new(0,3,-8))
  a.chakra=100
  local from=a.root.Position
  assert(c:request(a,H.slot(a,case[2]),b.root.Position),case[2]..": refused")
  local view
  for _=1,60 do H.step(c,.01);view=c:travelView(a);if view then break end end
  assert(view,case[2]..": no travel in the duel state")
  assert(view.kind=="teleport" and view.id==case[2],string.format("%s: travel %s / %s",case[2],tostring(view.kind),tostring(view.id)))
  assert(flat(view.from-from).Magnitude<.5,case[2]..": the travel does not start where he stood")
  assert(flat(view.to-a.root.Position).Magnitude<.5,case[2]..": the travel does not end where he is")
  assert(flat(view.to-view.from).Magnitude>8,case[2]..": a travel of "..flat(view.to-view.from).Magnitude.." studs")
  assert(view.arrived~=nil and view.arriveIn==0,case[2]..": a teleport has not arrived")
  assert(#impacts(c,"depart")==1 and #impacts(c,"arrive")==1,case[2]..": the depart / arrive impacts are missing")
  H.step(c,Config.Travel.Show+.2)
  assert(c:travelView(a)==nil,case[2]..": still in the state long after the arrival")
 end
end)

test("a signature dash departs with its style, is on its way, then arrives",function()
 local c,a,b=H.duel("Lion","Mirage")
 a.ai=nil;b.ai=nil
 c:relocate(a,V.new(0,3,14));c:relocate(b,V.new(0,3,-14))
 a.locked=true;a.chakra=100
 assert(c:request(a,"Pursuit"),"the dash was refused")
 local view=c:travelView(a)
 assert(view and view.kind=="dash" and type(view.id)=="string","no dash in the duel state")
 assert(view.arrived==nil and view.arriveIn>0,"the dash arrived at its start")
 local style=Brawler.reentry(a).name
 assert(view.id==(style or "Rush"),"the dash is named "..tostring(view.id).." not its style "..tostring(style))
 local arrived
 for _=1,80 do H.step(c,.01);local v=c:travelView(a);if v and v.arrived then arrived=v;break end end
 assert(arrived,"the dash never arrived")
 assert(flat(arrived.to-a.root.Position).Magnitude<.6,"the arrival is not where the body stopped")
 assert(flat(arrived.to-arrived.from).Magnitude>6,"a dash of "..flat(arrived.to-arrived.from).Magnitude.." studs")
end)

test("a blow taken on the way ends the travel",function()
 local c,a,b=H.duel("Lion","Mirage")
 a.ai=nil;b.ai=nil
 c:relocate(a,V.new(0,3,14));c:relocate(b,V.new(0,3,-14))
 a.locked=true;a.chakra=100
 assert(c:request(a,"Pursuit"),"the dash was refused")
 H.step(c,.03)
 assert(c:travelView(a),"setup: no dash")
 Brawler.react(c,a,"HitStun",V.new(0,0,0),.3,b)
 assert(c:travelView(a)==nil,"the travel outlived the blow")
end)

print(string.format("NinjaDuel travel (feel audit M5, for the ANIMATEUR's arrivals): %d PASS",passed))
