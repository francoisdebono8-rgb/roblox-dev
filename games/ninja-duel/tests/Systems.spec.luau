-- Final-phase systems: chakra dash, awakening, throw break and Flow strikes.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,pa,pb)
 c:relocate(a,pa);c:relocate(b,pb)
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return end
 end
 error(message)
end

test("chakra dash: E from neutral bursts at the opponent and a strike on arrival is the dash attack",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,10),V.new(0,3,-10))
 local chakra=a.chakra
 assert(c:request(a,"Pursuit"),"chakra dash refused")
 assert(a.state=="Rush","not a chakra dash ("..a.state..")")
 assert(math.abs(chakra-a.chakra-Config.Rush.Cost)<.01,"cost not paid")
 until_(c,.6,function() return a.state~="Rush" end,"the dash never ended")
 local gap=(a.root.Position-b.root.Position).Magnitude
 assert(gap<5,"the dash stopped too far ("..string.format("%.1f",gap)..")")
 assert(c:request(a,"Attack"))
 assert(a.attackName=="DashAttack","arrival strike is "..tostring(a.attackName))
 -- Too close: refused.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,2.5),V.new(0,3,-2.5))
 assert(not c2:request(x,"Pursuit"),"chakra dash point blank")
end)

test("awakening: only below a third of health, once per match, and it changes the fighter",function()
 local c,a,b=H.duel("GentleFist","Flashstep")
 place(c,a,b,V.new(0,3,4),V.new(0,3,-4))
 assert(not c:request(a,"Awaken"),"awakened at full health")
 a.health=a.def.Health*.3
 assert(c:request(a,"Awaken"),"awakening refused at low health")
 assert(a.awakenUntil>c.now and a.awakened)
 H.step(c,.5)
 assert(not c:request(a,"Awaken"),"awakened twice")
 -- Byakugan full field: no blind spot while awakened (the shockwave pushed
 -- the opponent away; set the duel up again with Neji's back turned).
 H.step(c,1)
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position+(a.root.Position-b.root.Position))
 a.state="Neutral";a.untilTime=c.now;a.invulnerableUntil=0
 assert(c:request(a,"Guard"));H.step(c,.25)
 assert(c:request(b,"Attack"))
 H.step(c,.35)
 assert(a.impactStyle=="block","the blind spot survived the awakening")
 -- Minato's awakening returns techniques almost at once.
 local c2,m,i=H.duel("Flashstep","Mirage")
 m.health=m.def.Health*.2
 assert(c2:request(m,"Awaken"))
 H.step(c2,.5)
 -- (Stage 6) the Quickstep is gone at 13: the Wind Cut shows the reduction.
 assert(c2:request(m,H.slot(m,"WindCut"),i.root.Position),"Wind Cut refused")
 local cd=m.cooldowns.WindCut-c2.now
 local spec;for _,t in m.def.Techniques do if t.Id=="WindCut" then spec=t end end
 assert(cd<spec.Cooldown*.6,"awakened cooldown not reduced ("..string.format("%.2f",cd)..")")
end)

test("throw break: grab back right as you are seized and the throw is broken",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,1.9),V.new(0,3,-1.9))
 assert(c:request(a,"Grab"))
 until_(c,.4,function() return b.reaction=="Grabbed" end,"the grab never connected")
 assert(c:request(b,"Grab"),"throw break refused")
 assert(not a.grabVictim and not b.grabbedBy and b.reaction==nil,"the grab survived the break")
 assert((b.events.ThrowBreak or 0)==1)
 -- Too late: the throw goes through.
 local c2,x,y=H.duel("Mirage","Flashstep")
 place(c2,x,y,V.new(0,3,1.9),V.new(0,3,-1.9))
 assert(c2:request(x,"Grab"))
 until_(c2,.4,function() return y.reaction=="Grabbed" end,"the grab never connected")
 H.step(c2,Config.ThrowBreak+.05)
 assert(not c2:request(y,"Grab"),"a late throw break was accepted")
end)

test("flow: a chain pressed on the beat lands harder; mashed early presses do not",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Attack"))
 until_(c,.5,function() return a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt end,"the chain never opened")
 assert(c:request(a,"Attack"))
 assert(a.pending and a.pending.flow,"a press on the beat was not a Flow strike")
 until_(c,.4,function() return (a.events.Flow or 0)>0 end,"the Flow strike never paid off")
 -- Mash: the second press goes in during the first swing's startup.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c2:request(x,"Attack"))
 assert(c2:request(x,"Attack"))
 until_(c2,.8,function() return x.attackName=="Light2" end,"the mashed press never chained")
 assert(not x.pending.flow,"a mashed press became a Flow strike")
end)

test("riposte: a clean block or a perfect dodge turns the next press into an instant counter that opens the string",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(b,"Guard"));H.step(c,.3)
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return b.impactStyle=="block" end,"the strike was not blocked")
 assert(c:request(b,"Attack"),"riposte refused")
 assert(b.attackName=="Riposte","after a block the press is "..tostring(b.attackName))
 assert(b.pending.spec.startup<=.06,"the riposte is not instant")
 -- Too late: an ordinary press.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c2:request(y,"Guard"));H.step(c2,.3)
 assert(c2:request(x,"Attack"))
 until_(c2,.4,function() return y.impactStyle=="block" end,"the strike was not blocked")
 H.step(c2,.5)
 c2:request(y,"GuardOff")
 assert(c2:request(y,"Attack"))
 assert(y.attackName~="Riposte","a late press was still a riposte")
end)

print("NinjaDuel final systems: "..passed.." PASS")
