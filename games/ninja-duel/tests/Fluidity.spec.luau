-- Fluidity audit (user 29/10: "je pouvais plus bouger", "c'est plein de bugs
-- et d'incohérences", "audit tout ce qui pourrait impacter la fluidité"). Each
-- test holds one cause found by the audit (docs/reports/2026-10-29-fluidity-audit.md)
-- and by tests/Control.sim.luau (a scripted pad player against the AI).
local H=require("./Harness")
local V=H.V
local passed,failed=0,0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else failed+=1;print("FAIL "..name..": "..tostring(err)) end
end
local Brawler=H.load("Server/Brawler")
local Config=H.load("Shared/Config")
local Tune=H.load("Shared/VelmoraCombatConfig")
local function duel(x,y,gap)
 local c,a,b=H.duel(x or "Lion",y or "Mirage")
 c:relocate(a,V.new(0,3,gap or 3));c:relocate(b,V.new(0,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(0,3,0))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(0,3,gap or 3))
 a.ai=nil;b.ai=nil;a.playerInput=true
 return c,a,b
end
local function stepUntil(c,cond,limit)
 for _=1,math.ceil((limit or 2)/.01) do if cond() then return true end H.step(c,.01) end
 return cond()
end

test("a press made just before the body is free comes out (late press)",function()
 local c,a=duel("Lion","Mirage",20)
 assert(c:request(a,"Heavy"),"heavy refused")
 assert(stepUntil(c,function() return a.state=="Recovery" end),"no recovery")
 -- 0.1 s before the end of a whiffed heavy (no cancel): the jump is refused now...
 stepUntil(c,function() return a.untilTime-c.now<=.1 end)
 local ok,reason=c:request(a,"Jump")
 assert(ok==false and reason=="Committed","the jump in the recovery was "..tostring(ok).." "..tostring(reason))
 -- ...and comes out on the first free frame
 assert(stepUntil(c,function() return a.airborne end,.3),"the late jump never came out")
end)

test("a late press is a moment, not a queue: an old press does not fire",function()
 local c,a=duel("Lion","Mirage",20)
 assert(c:request(a,"Heavy"))
 assert(stepUntil(c,function() return a.state=="Recovery" end))
 local ok=c:request(a,"Jump");assert(ok==false)
 local left=a.untilTime-c.now
 assert(left>Config.Late.Own+.05,"fixture: the recovery is already ending ("..left..")")
 stepUntil(c,function() return a.state=="Neutral" end,2)
 H.step(c,.1)
 assert(not a.airborne,"a jump pressed "..string.format("%.2f",left).." s before the end fired")
end)

test("past a strike's cancel point the jump leaves the recovery (it was refused 'Airborne' standing)",function()
 local c,a=duel("Lion","Mirage",20)
 assert(c:request(a,"Attack"))
 assert(stepUntil(c,function() return a.state=="Recovery" and a.recoveryCancelAt and c.now>=a.recoveryCancelAt end,1),"no cancel point reached")
 local ok,reason=c:request(a,"Jump")
 assert(ok~=false,"jump refused past the cancel point: "..tostring(reason))
 H.step(c,.05)
 assert(a.airborne,"no jump")
end)

test("the press gate is a flood guard: a hand's second press is never dropped",function()
 for family,gap in Tune.Rates do assert(gap<=.08,family.." gap "..gap.." drops a deliberate second press") end
end)

test("a guard walks: the stick moves a guarding body at the guard's speed",function()
 local c,a,b=duel("Lion","Mirage",8)
 a.guardWanted=true
 assert(c:request(a,"Guard"))
 assert(a.state=="Guarding","no guard")
 local start=a.root.Position
 a.move=V.new(1,0,0)
 for _=1,40 do a.move=V.new(1,0,0);H.step(c,.01) end
 local moved=(V.new(a.root.Position.X,0,a.root.Position.Z)-V.new(start.X,0,start.Z)).Magnitude
 assert(a.state=="Guarding","the guard dropped")
 assert(moved>1,"a guarding body did not move ("..string.format("%.2f",moved).." studs in 0.4 s)")
 assert(moved<=Config.GuardSpeed*.4+.3,"the guard walked faster than GuardSpeed ("..moved..")")
end)

test("a guard cannot loop: an empty guard does not come back up on its own",function()
 local c,a=duel("Lion","Mirage",8)
 a.guardWanted=true;a.stamina=10
 H.step(c,.05)
 assert(a.state~="Guarding","the held guard came back up on an empty tank")
 a.stamina=60
 H.step(c,.05)
 assert(a.state=="Guarding","the held guard did not come back once rested")
end)

test("a jump-in strike with no air hold keeps falling while it swings",function()
 local c,a,b=duel("Lion","Mirage",4)
 -- the jump's swing is spent (no hold for a second one), the body falling
 -- near a body in the air (a grounded one is a dive or a drop strike)
 c:relocate(b,V.new(0,7,0));b.airborne=true
 c:relocate(a,V.new(0,8,5));a.airborne=true;a.airHold=0;a.airSwingUsed=true;a.airCombo=0
 a.root.AssemblyLinearVelocity=V.new(0,-20,0)
 assert(c:request(a,"Attack"))
 assert(a.attackName~="WallDive" and (a.airHold or 0)<=c.now,"fixture: "..tostring(a.attackName).." with a hold")
 -- (headless there is no solver: the fall is the speed the body keeps)
 H.step(c,.03)
 assert(a.root.AssemblyLinearVelocity.Y<-5,string.format("the swing hovered (vertical speed %.2f)",a.root.AssemblyLinearVelocity.Y))
end)

test("a chase that starts on the floor is not landed on its first frame",function()
 local c,a,b=duel("Lion","Mirage",4)
 Brawler.react(c,b,"Launched",V.new(0,45,0),1.2,a)
 a.pursuitUntil=c.now+1
 local ok,reason=c:request(a,"Pursuit")
 assert(ok,"chase refused: "..tostring(reason))
 H.step(c,.02)
 assert(a.airborne and a.state=="Pursuit","the chase was landed at once ("..tostring(a.state)..")")
end)

test("knocked down, the body is not free until it is up (a strike at the wake-up whiffed)",function()
 local c,a,b=duel()
 b.reaction="Knockdown";b.reactionUntil=c.now-.01;b.airborne=false
 assert(not Brawler.free(b,c.now),"a body at the end of its knockdown counts as free")
 b.reaction="Wakeup";b.reactionUntil=c.now+.2
 assert(not Brawler.free(b,c.now))
end)

test("a dodge pressed while getting up is the dodge after it, not a refused substitution",function()
 local c,a,b=duel("Lion","Mirage",6)
 b.playerInput=true
 Brawler.react(c,b,"Knockdown",V.zero,.3,a);b.airborne=false
 H.step(c,.25)
 local ok,reason=c:request(b,"Dodge")
 assert(ok==false and reason=="Reacting","the dodge on the floor was "..tostring(ok).." "..tostring(reason))
 assert(stepUntil(c,function() return b.state=="Dodging" end,.6),"the dodge never came out after the wake-up")
end)

test("a flight that ends in the air hands its speed on (no stop then drop)",function()
 local c,a,b=duel()
 c:relocate(b,V.new(0,15,-6))
 Brawler.react(c,b,"Juggled",V.new(0,-12,9),.05,a);b.airborne=true
 H.step(c,.06)
 assert(b.reaction==nil,"the reaction did not end")
 local v=b.root.AssemblyLinearVelocity
 assert(V.new(v.X,0,v.Z).Magnitude>4,"the body stopped dead in the air ("..tostring(v)..")")
end)

test("a hit ends the run's hand-back (the body lurched after the stun)",function()
 local c,a,b=duel()
 b.strikeCarry={dir=V.new(1,0,0),speed=27,at=c.now}
 Brawler.react(c,b,"HitStun",V.zero,.2,a)
 assert(b.strikeCarry==nil,"the run's carry outlived the hit")
end)

test("a volley of light blades is one flinch, not a lock (user 29/10 playtest: Itachi's shurikens)",function()
 local c,a,b=duel("Lion","Mirage",10)
 local health=a.health
 local stunned=0
 for i=1,6 do
  -- headless the blade is resolved where it lands (Combat:projectileHit)
  local p=c:projectile(b,a.root.Position,80,40,2,"shuriken")
  c:projectileHit(p,a,a.root.Position,-p.direction)
  for _=1,10 do H.step(c,.01);if a.state=="Stunned" then stunned+=.01 end end
 end
 for _=1,40 do H.step(c,.01);if a.state=="Stunned" then stunned+=.01 end end
 assert(a.health<health-6,"fixture: the blades did not land ("..(health-a.health)..")")
 assert(stunned<=.3,string.format("six blades held the body stunned %.2f s",stunned))
 -- a real blow still stuns after a volley
 local before=a.state
 c:damage(b,a,9,false,true)
 assert(a.state=="Stunned","a strike after the volley did not stun ("..tostring(before)..")")
end)

if failed>0 then error(failed.." fluidity test(s) failed",0) end
print(string.format("NinjaDuel fluidity: %d PASS (headless; the feel itself is a Studio check)",passed))
