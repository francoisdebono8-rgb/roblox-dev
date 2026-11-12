-- Feel audit of 07/11, M3 (docs/reports/feel-audit-2026-11-07/AUDIT.md):
-- victims turned round at once (Itachi 176 deg, Kakashi in HitStun 155 deg in
-- one frame: both caught by an ultimate; Sasuke grabbed from behind, 179 deg,
-- fixed by lot 1).
--   1. Shared/ReactionSides.Grabbed (set by the ANIMATEUR) is only true with
--      the hold's back and side clips for every fighter.
--   2. The client picks the back or side clip of a throw (Launched,
--      Knockback) and of a hold as soon as it exists, the frontal one until.
--   3. With the hold's clips in, the held body is not hauled round.
--   4. A body caught by an ultimate is turned at Ultimates.VICTIM_TURN, never
--      in one frame.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local ReactionSides=H.load("Shared/ReactionSides")
local Authored=H.load("Client/AuthoredMotion")
local Motion=H.load("Client/VelmoraMotionEngine")
local Brawler=H.load("Server/Brawler")
local Ultimates=H.load("Server/Ultimates")
local function yaw(a) local l=a.root.CFrame.LookVector return math.atan2(-l.X,-l.Z) end
local function turned(y0,y1) local d=(y1-y0)%(2*math.pi) if d>math.pi then d-=2*math.pi end return math.abs(math.deg(d)) end

test("the hold is marked with back and side clips only when every fighter has them",function()
 local fighters={}
 for id in H.fighters do if Authored.has(id..".Hit.Body") then table.insert(fighters,id) end end
 assert(#fighters>=8,"fixture: "..#fighters.." fighters with authored reactions")
 if ReactionSides.Grabbed==true then
  for _,id in fighters do
   for _,clip in ReactionSides.Clips.Grabbed do
    assert(Authored.has(id.."."..clip),"Grabbed is marked true but "..id.."."..clip.." is missing")
   end
  end
 end
 -- HitStun's back and side clips are in (ANIM-005): the reference the others follow.
 for _,id in fighters do
  for _,clip in ReactionSides.Clips.HitStun do assert(Authored.has(id.."."..clip),id.."."..clip.." is missing") end
 end
end)

test("the client plays a throw's or a hold's back or side clip as soon as it exists",function()
 assert(Motion._authoredReaction,"the engine does not expose its reaction choice")
 local extra={}
 local has,sample=Authored.has,Authored.sample
 Authored.has=function(name) return extra[name]~=nil or has(name) end
 Authored.sample=function(name,t) return sample(extra[name] or name,t) end
 local ok,err=pcall(function()
  local function clip(reaction,angle,airborne)
   local _,_,name=Motion._authoredReaction({fighterId="Lion",id="t",reaction=reaction,reactionElapsed=.1,hitAngle=angle,airborne=airborne,hitTwist=1})
   -- (".L": the mirrored side, part of the clip's identity)
   return if name then (string.gsub(name,"%.L$","")) else nil
  end
  -- Before the ANIMATEUR's clips: the frontal ones (the hold: procedural).
  assert(clip("Launched",180,true)=="Launched","from behind, before the clip: "..tostring(clip("Launched",180,true)))
  assert(clip("Knockback",90,true)=="Knockback","from the side, before the clip: "..tostring(clip("Knockback",90,true)))
  assert(clip("Grabbed",180,false)==nil,"the hold has no clip yet but played "..tostring(clip("Grabbed",180,false)))
  -- Delivered (stood in for by the frontal clips' frames).
  extra["Lion.Launched.Back"]="Lion.Launched";extra["Lion.Launched.Side"]="Lion.Launched"
  extra["Lion.Knockback.Side"]="Lion.Knockback";extra["Lion.Grabbed.Back"]="Lion.Launched"
  assert(clip("Launched",180,true)=="Launched.Back","from behind: "..tostring(clip("Launched",180,true)))
  assert(clip("Juggled",-95,true)=="Launched.Side","from the side: "..tostring(clip("Juggled",-95,true)))
  assert(clip("Launched",10,true)=="Launched","from the front: "..tostring(clip("Launched",10,true)))
  assert(clip("Knockback",90,true)=="Knockback.Side","thrown from the side: "..tostring(clip("Knockback",90,true)))
  assert(clip("Knockback",180,true)=="Knockback","thrown from behind, no Back clip yet: "..tostring(clip("Knockback",180,true)))
  assert(clip("Grabbed",180,false)=="Grabbed.Back","held from behind: "..tostring(clip("Grabbed",180,false)))
 end)
 Authored.has,Authored.sample=has,sample
 assert(ok,err)
end)

test("with the hold's clips in, a body grabbed from behind is not hauled round",function()
 local function grabbed()
  local c,a,b=H.duel("Legion","Lion")
  b.ai=nil;a.ai=nil
  c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-2.6))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-1)) -- his back to a
  local y0=yaw(b)
  assert(c:request(a,"Grab"),"setup: the grab was refused")
  local most,held=0,false
  for _=1,40 do H.step(c,.01);if b.grabbedBy then held=true;most=math.max(most,turned(y0,yaw(b))) end end
  assert(held,"setup: the grab did not hold")
  return most
 end
 assert(grabbed()>=60,"setup: without the clips the held body is no longer hauled round")
 ReactionSides.Grabbed=true
 local ok,result=pcall(grabbed)
 ReactionSides.Grabbed=false
 assert(ok,result)
 assert(result<=2,string.format("with the hold's clips the held body still turned %.0f deg",result))
end)

test("a body caught by an ultimate is turned at a rate, never in one frame",function()
 for _,id in {"Flashstep","Legion","Copycat"} do
  local c,a,b=H.duel(id,"Mirage")
  a.ai=nil;b.ai=nil
  c:relocate(a,V.new(0,3,2));c:relocate(b,V.new(0,3,-2))
  a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
  b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-1)) -- caught from behind
  b.health=999;a.ultimate=100
  assert(c:request(a,"Ultimate"),id..": the ultimate was refused")
  local worst,caught=0,false
  local last=yaw(b)
  for _=1,300 do
   H.step(c,.01)
   if b.ultimateHeld then caught=true;worst=math.max(worst,turned(last,yaw(b))) end
   last=yaw(b)
  end
  assert(caught,id..": the ultimate did not catch")
  assert(worst<=(Ultimates.VICTIM_TURN or 900)*.01+1,string.format("%s: the caught body turned %.0f deg in one 10 ms step",id,worst))
 end
end)

print(string.format("NinjaDuel reaction sides (feel audit M3): %d PASS (headless; the look is a Studio check)",passed))
