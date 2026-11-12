-- Feel audit of 07/11, M1 (docs/reports/feel-audit-2026-11-07/AUDIT.md):
-- glissades. The body moved under a fixed pose: 14 studs/s at the end of a
-- blow, up to 33-40 studs/s for a guard pushed back. The speeds now follow the
-- step speeds the ANIMATEUR gives (Shared/StepSpeeds):
--   1. none given: the old speeds (no change before his clips);
--   2. a Recovery speed given: the end of a blow walks no faster;
--   3. a GuardSkid speed given: the guard skids no faster, over the same
--      distance.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local StepSpeeds=H.load("Shared/StepSpeeds")
local function flat(v) return V.new(v.X,0,v.Z) end

-- The fastest the body is asked to walk during the recovery of a whiffed jab,
-- the stick held sideways.
local function recoveryWalk(id)
 local c,a,b=H.duel(id,"Legion")
 b.ai=nil;a.ai=nil
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-30))
 a.playerInput=true
 assert(c:request(a,"Attack"),"setup: the jab was refused")
 local fastest,frames=0,0
 for _=1,120 do
  if a.state=="Recovery" or a.state=="Active" then a.move=V.new(1,0,0) end
  H.step(c,.01)
  if a.state=="Recovery" then
   -- What the engine asks the body to walk at (the humanoid's speed).
   frames+=1
   fastest=math.max(fastest,a.hum.WalkSpeed)
  end
  if frames>0 and a.state=="Neutral" then break end
 end
 assert(frames>3,"setup: the jab had no recovery")
 return fastest
end

-- The fastest a guard pushed back skids, and how far it went.
local function guardSkid(id)
 local c,a,b=H.duel("Legion",id)
 a.ai=nil;b.ai=nil
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-8))
 c:setState(b,"Guarding",0);b.guardHeld=true
 b.guardSlide={dir=V.new(0,0,-1),remaining=4,speed=40} -- the Rasengan's push on a guard
 local start=b.root.Position
 local fastest=0
 for _=1,100 do
  local before=b.root.Position
  H.step(c,.01)
  fastest=math.max(fastest,flat(b.root.Position-before).Magnitude/.01)
 end
 return fastest,flat(b.root.Position-start).Magnitude
end

test("no step speed given: the old speeds",function()
 local walk=recoveryWalk("Lion")
 assert(walk>11,string.format("the end of a blow walked at %.1f studs/s, not the old 14",walk))
 local skid,dist=guardSkid("Lion")
 assert(skid>30 and dist>3.8,string.format("the guard skidded %.1f studs at %.1f studs/s, not the old 4 at 40",dist,skid))
end)

test("a Recovery step speed given: the end of a blow walks no faster than the legs",function()
 StepSpeeds.Recovery.Lion=6
 local ok,err=pcall(function()
  local walk=recoveryWalk("Lion")
  assert(walk<=6.3,string.format("the end of a blow walked at %.1f studs/s with legs at 6",walk))
  local other=recoveryWalk("Mirage")
  assert(other>11,string.format("another fighter's end of a blow (%.1f studs/s) followed Sasuke's legs",other))
 end)
 StepSpeeds.Recovery.Lion=nil
 assert(ok,err)
end)

test("a GuardSkid step speed given: the guard skids no faster, over the same distance",function()
 StepSpeeds.Default.GuardSkid=12
 local ok,err=pcall(function()
  local skid,dist=guardSkid("Lion")
  assert(skid<=12.3,string.format("the guard skidded at %.1f studs/s with feet at 12",skid))
  assert(dist>3.8,string.format("the guard skidded %.1f studs, not the push's 4",dist))
 end)
 StepSpeeds.Default.GuardSkid=nil
 assert(ok,err)
end)

print(string.format("NinjaDuel step speeds (feel audit M1): %d PASS (headless; the look is a Studio check)",passed))
