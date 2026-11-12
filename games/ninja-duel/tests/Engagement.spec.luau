-- Mission « game feel » (07/11), lot 1 « orientation » : what the Studio audit
-- measured (docs/reports/feel-audit-2026-11-07/AUDIT.md), held headless.
--   1. A free player's blow faces the body it is thrown at by its first
--      active frame (audit: blows out at 45-86 deg off the body they hit).
--   2. Engaged up close, the free body keeps its chest on the opponent
--      between two blows instead of swinging back to the lens.
--   3. A blow lands only on what is in front of it (contact cone +-60 deg,
--      was +-87: a fist going forward knocked down a body beside it).
--   4. A body grabbed from behind is hauled round, not spun in one frame
--      (audit: 179 deg in one frame).
-- Headless mechanics only: the look is a Studio check.
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
local function off(a,b)
 local to=flat(b.root.Position-a.root.Position)
 local lv=flat(a.root.CFrame.LookVector)
 return math.deg(math.acos(math.clamp(to.Unit:Dot(lv.Unit),-1,1)))
end
local function yaw(a) local l=a.root.CFrame.LookVector return math.atan2(-l.X,-l.Z) end
local function turned(y0,y1) local d=(y1-y0)%(2*math.pi) if d>math.pi then d-=2*math.pi end return math.abs(math.deg(d)) end
-- A free (unlocked) player body, `away` degrees off the opponent standing
-- `gap` studs in front, the mouse lens looking along that facing.
local function freePair(id,gap,away)
 local c,a,b=H.duel(id,"Mirage")
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-gap));b.ai=nil
 a.locked=false;a.playerInput=true
 local r=math.rad(away)
 local face=V.new(math.sin(r),0,-math.cos(r))
 a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position+face)
 a.look=face
 return c,a,b
end

test("a free player's blow comes out facing the body it is thrown at (lens looking elsewhere)",function()
 for _,id in {"Flashstep","Lion","Leaf","Legion","Copycat"} do
  for _,setup in {{4.5,150},{5,110},{6,70}} do
   local gap,away=setup[1],setup[2]
   local c,a,b=freePair(id,gap,away)
   local hp=b.health
   assert(c:request(a,"Attack"),id..": the press was refused")
   local worst=nil
   for _=1,80 do
    H.step(c,.01)
    if a.state=="Active" and worst==nil then worst=off(a,b) end
    if a.state=="Recovery" or b.health<hp then break end
   end
   assert(worst~=nil or b.health<hp,id..": the blow never came out")
   assert((worst or 0)<=25,string.format("%s: a jab pressed %d deg off at %.1f studs came out still %.0f deg off",id,away,gap,worst or -1))
   assert(b.health<hp,string.format("%s: a jab pressed %d deg off at %.1f studs missed",id,away,gap))
  end
 end
end)

test("engaged up close, the free body keeps its chest on him between two blows; out of the exchange it follows the lens",function()
 local c,a,b=freePair("Lion",4.5,0)
 assert(c:request(a,"Attack"))
 for _=1,80 do H.step(c,.01);if a.state=="Neutral" then break end end
 -- The player turns the lens away (the mouse) right after his blow.
 local r=math.rad(140)
 a.look=V.new(math.sin(r),0,-math.cos(r))
 for _=1,40 do H.step(c,.01) end
 assert(off(a,b)<=20,string.format("0.4 s after his blow the body swung back to the lens (%.0f deg off him)",off(a,b)))
 -- Long after the exchange, the lens decides again (DEC-031: free).
 for _=1,120 do H.step(c,.01) end
 assert(off(a,b)>=100,string.format("1.6 s after the exchange the body is still glued to him (%.0f deg off)",off(a,b)))
end)

test("a free body facing away turns to a blow wound up at it close by",function()
 local c,a,b=freePair("Lion",4.5,160)
 b.locked=true
 assert(c:request(b,"Attack"),"the opponent's press was refused")
 local start=off(a,b)
 for _=1,12 do H.step(c,.01) end
 assert(off(a,b)<start-30,string.format("a body 160 deg away did not start turning to the blow coming at it (%.0f -> %.0f)",start,off(a,b)))
end)

test("a blow lands only on what is in front of it",function()
 -- A jab that cannot turn (a heavy body's weight at zero, started directly:
 -- no side route) at a body standing 75 deg to its side, well inside the
 -- old +-87 deg cone; and the same jab at a body 20 deg off.
 local function jab(side)
  local c,a,b=H.duel("Lion","Mirage")
  b.ai=nil;a.ai=nil
  c:relocate(a,V.new(0,3,0))
  local r=math.rad(side)
  c:relocate(b,V.new(math.sin(r)*3.6,3,-math.cos(r)*3.6))
  a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position+V.new(0,0,-1))
  a.locked=true
  a.def=table.clone(a.def);a.def.StrikeTurnScale=0
  assert(c:targetValid(a,b,6,Config.Contact.Facing)==(side<=55),string.format("the contact cone says %s for a body %d deg off",tostring(c:targetValid(a,b,6,Config.Contact.Facing)),side))
  local hp=b.health
  Brawler.start(c,a,"Light1")
  for _=1,80 do H.step(c,.01);if a.state=="Recovery" or b.health<hp then break end end
  return b.health<hp
 end
 assert(not jab(75),"a jab going straight ahead hit a body 75 deg to its side")
 assert(jab(20),"a jab at a body 20 deg off missed")
end)

test("a body grabbed from behind is hauled round to the grabber, not spun in one frame",function()
 -- (12/11) Only while the hold has no back/side clips (Shared/ReactionSides
 -- .Grabbed); with them the body keeps its facing (tests/ReactionSides).
 local Sides=H.load("Shared/ReactionSides");local was=Sides.Grabbed.Lion;Sides.Grabbed.Lion=nil
 local ok,err=pcall(function()
 local c,a,b=H.duel("Legion","Lion")
 b.ai=nil;a.ai=nil
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-2.6))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 -- b turns his back on a
 b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-1))
 assert(c:request(a,"Grab"),"the grab was refused")
 local worst,held=0,false
 local last=yaw(b)
 for _=1,60 do
  H.step(c,.01)
  local now=yaw(b)
  if b.grabbedBy then held=true;worst=math.max(worst,turned(last,now)) end
  last=now
 end
 assert(held,"the grab did not hold the body")
 assert(worst<=Brawler.GRAB_TURN*.01+1,string.format("the held body turned %.0f deg in one 10 ms step",worst))
 assert(off(b,a)<=25,string.format("0.6 s into the hold the body still does not face the grabber (%.0f deg off)",off(b,a)))
 end)
 Sides.Grabbed.Lion=was
 assert(ok,err)
end)

print(string.format("NinjaDuel engagement (game feel lot 1): %d PASS (headless; the look is a Studio check)",passed))
