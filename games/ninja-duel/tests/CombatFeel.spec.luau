-- Combat convergence breakthrough (docs/archive/requests/2026-10-25-combat-convergence-breakthrough.md):
-- the systemic fixes found in Studio frame-by-frame strips, held headless.
-- The look itself is judged in Studio; these guard the mechanics under it.
local H=require("./Harness")
local V=H.V
local Vector3=H.roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Motion=H.load("Client/VelmoraMotionEngine")
local AXIS_Y=H.roblox.CFrame.identity.UpVector
local function frame(model,actor,dt)
 Motion.tick(dt or 1/60)
 return Motion.present(model,actor,{},dt or 1/60)
end
local function body(a,over)
 local out={fighterId=a.fighterId,state="Neutral",health=100,attackElapsed=0,reactionElapsed=0,airborne=false,
  velocity=Vector3.zero,speed=0,landing=false}
 for k,v in over or {} do out[k]=v end
 return out
end
local function deg(cf,axis) return math.deg(math.acos(math.clamp(cf:VectorToObjectSpace(AXIS_Y):Dot(axis or AXIS_Y),-1,1))) end

test("a jab to the body folds the whole body, not just the head (it reads at game speed)",function()
 local c,a=H.duel("Mirage","Leaf")
 Motion.reset(a.model)
 for _=1,10 do frame(a.model,body(a)) end
 local most=0
 for i=1,14 do
  frame(a.model,body(a,{reaction="HitStun",reactionElapsed=i/60,hitStrength=5/26,hitAngle=0,hitZone="body",hitKind="strike"}))
  local torso=a.model.joints.Waist and a.model.joints.Waist.Transform or a.model.joints.Root.Transform
  most=math.max(most,deg(torso)+deg(a.model.joints.Root.Transform))
 end
 assert(most>30,string.format("a jab still barely moves the body (%.0f degrees)",most))
end)

test("a knockback takes the body off its feet: thrown back nearly flat while it flies",function()
 local c,a=H.duel("Mirage","Leaf")
 Motion.reset(a.model)
 for _=1,10 do frame(a.model,body(a)) end
 local lowest=1
 for i=1,20 do
  frame(a.model,body(a,{reaction="Knockback",reactionElapsed=i/60,airborne=true,velocity=V.new(0,8,30),hitStrength=12/26,hitAngle=0,hitKind="strike"}))
  lowest=math.min(lowest,a.model.joints.Root.Transform:VectorToObjectSpace(AXIS_Y).Y)
 end
 assert(lowest<.75,string.format("the knocked-back body stays upright (up.y %.2f)",lowest))
end)

test("a strike already out is committed: it does not steer onto a body that slipped aside",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(0,3,7));c:relocate(b,V.new(0,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 assert(c:request(a,"Heavy"))
 local n=0
 repeat H.step(c,.01);n+=1 until a.state=="Active" or n>80
 assert(a.state=="Active","the heavy never came out")
 local dir=a.travelDirection
 -- The body steps aside as the blow comes out.
 c:relocate(b,V.new(5,3,0))
 for _=1,6 do H.step(c,.01) end
 assert(a.travelDirection:Dot(dir)>.99,"the committed strike steered onto the moved body")
end)

test("a strike's startup turns the body at a bounded rate (no root snap)",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(5,3,0))
 -- Facing 90 degrees away from the opponent.
 a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position+V.new(0,0,-1))
 assert(c:request(a,"Attack"))
 local before=a.root.CFrame.LookVector
 H.step(c,.02)
 local turned=math.deg(math.acos(math.clamp(a.root.CFrame.LookVector:Dot(before),-1,1)))
 assert(turned<=900*.02+1,string.format("the startup snapped %.0f degrees in 20 ms",turned))
end)

test("an air swing holds the body for the swing, not through its recovery (no hover)",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(0,12,3));c:relocate(b,V.new(0,12,0))
 a.airborne=true
 assert(c:request(a,"Attack"))
 local spec=a.pending and a.pending.spec
 assert(spec and spec.air,"no air swing ("..tostring(a.attackName)..")")
 local hold=a.airHold-c.now
 assert(hold<=spec.startup+spec.active+.07,string.format("the air hold runs into the recovery (%.2f s)",hold))
end)

test("a blocked blow skids the guard back over several frames instead of moving it in one",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(a,V.new(0,3,2.25));c:relocate(b,V.new(0,3,-2.25))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 assert(c:request(b,"Guard"));H.step(c,.3)
 assert(c:request(a,"Attack"))
 local start=b.root.Position
 local biggest,moved=0,0
 local last=b.root.Position
 for _=1,80 do
  H.step(c,.01)
  local step=(b.root.Position-last).Magnitude;last=b.root.Position
  biggest=math.max(biggest,step)
 end
 moved=(b.root.Position-start).Magnitude
 assert(moved>.2,"setup: the guard was not pushed (state "..tostring(b.state)..", blocked "..tostring(a.hitBlocked)..")")
 assert(biggest<moved*.6,string.format("the guard moved %.2f of %.2f studs in one frame",biggest,moved))
end)

test("a landed blow's spark sits on the struck side and height, not in the chest centre",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(0,3,3.6));c:relocate(b,V.new(0,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 local serial=c.impactSerial or 0
 assert(c:request(a,"Attack"))
 local hit
 for _=1,60 do
  H.step(c,.01)
  for _,impact in c.impacts or {} do if impact.serial>serial and impact.style=="light" then hit=impact end end
  if hit then break end
 end
 assert(hit,"setup: the jab never landed")
 local off=hit.position-b.root.Position
 assert(off.Z>.3,"the spark is not on the side facing the striker")
end)

print(string.format("NinjaDuel combat feel (convergence): %d PASS (headless; the look is a Studio check)",passed))
