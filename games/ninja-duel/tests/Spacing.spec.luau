-- Feel audit of 07/11, M2 (docs/reports/feel-audit-2026-11-07/AUDIT.md):
-- bodies inside each other. 7 episodes a minute closer than 2.2 studs root to
-- root, and Sasuke standing in Naruto lying on the floor (capture sn1).
--   1. Two standing bodies brought inside a body width are out of it in one
--      frame, not eased 0.35 studs a frame.
--   2. A standing body on a lying one (on its chest or its head, 3 studs
--      from its root) is moved off it; the lying body does not slide.
--   3. A dodge still passes through.
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
-- The audit's figures, not read from Config: the test must also fail on the old code.
local B={Floor=2.5,Gap=3,LyingHalf=2.8,LyingGap=2.0}
assert(Config.Bodies==nil or (Config.Bodies.Floor==B.Floor and Config.Bodies.LyingGap==B.LyingGap and Config.Bodies.LyingHalf==B.LyingHalf),"Config.Bodies changed: update the test")
local function flat(v) return V.new(v.X,0,v.Z) end
local function gapOf(a,b) return flat(b.root.Position-a.root.Position).Magnitude end
local function still(c,a,b)
 for _,x in {a,b} do x.ai=nil;x.move=V.new(0,0,0) end
end

test("two standing bodies brought 1.2 studs apart are a body width apart the next frame",function()
 local c,a,b=H.duel("Lion","Legion")
 still(c,a,b)
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-1.2))
 H.step(c,.01)
 assert(gapOf(a,b)>=B.Floor-.05,string.format("one frame later the bodies are still %.2f studs apart (floor %.1f)",gapOf(a,b),B.Floor))
 H.step(c,.3)
 assert(gapOf(a,b)>=B.Floor-.05 and gapOf(a,b)<=B.Gap+.2,string.format("settled %.2f studs apart",gapOf(a,b)))
end)

test("a standing body on a lying one is moved off it; the lying body does not slide",function()
 for _,spot in {{"on his chest",-1.6},{"on his head",-3.2},{"on his legs",2.4}} do
  local c,a,b=H.duel("Lion","Legion")
  still(c,a,b)
  c:relocate(b,V.new(0,3,0))
  -- b lies on the floor, facing -Z (head behind him, +Z; feet ahead, -Z)
  b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-1))
  b.reaction="Knockdown";b.groundPose="Knockdown";b.airborne=false
  b.reactionStartedAt=c.now;b.reactionUntil=c.now+5
  c:relocate(a,V.new(.3,3,-spot[2]))
  local lyingAt=b.root.Position
  H.step(c,.05)
  local rel=flat(a.root.Position-b.root.Position)
  local along=math.clamp(rel:Dot(V.new(0,0,-1)),-B.LyingHalf,B.LyingHalf)
  local off=(rel-V.new(0,0,-1)*along).Magnitude
  assert(off>=B.LyingGap-.05,string.format("standing %s: still %.2f studs from the lying body's line",spot[1],off))
  assert(flat(b.root.Position-lyingAt).Magnitude<.05,string.format("standing %s: the lying body slid %.2f studs",spot[1],flat(b.root.Position-lyingAt).Magnitude))
 end
end)

test("a dodge still passes through the other body",function()
 local c,a,b=H.duel("Lion","Legion")
 still(c,a,b)
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(0,3,-1.2))
 a.state="Dodging"
 local before=gapOf(a,b)
 c:separate()
 assert(gapOf(a,b)<B.Floor-.3,string.format("a dodging body was thrown out to %.2f studs (from %.2f)",gapOf(a,b),before))
end)

print(string.format("NinjaDuel spacing (feel audit M2): %d PASS (headless; the look is a Studio check)",passed))
