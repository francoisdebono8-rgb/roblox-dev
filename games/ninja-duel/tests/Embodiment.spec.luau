-- Ninja Embodiment (DEC-027): shared systems that change what the game is.
-- EMB-002 contextual action resolver; later blocks add their own cases here.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Context=H.load("Shared/ActionContext")
local Attacks=H.load("Shared/Attacks")
local Graphs=H.load("Shared/MoveGraphs")

local function situation(over)
 local s={pos=V.new(0,3,4),look=V.new(0,0,-1),vel=V.zero,airborne=false,
  target={pos=V.new(0,3,0),look=V.new(0,0,1),airborne=false,down=false,guarding=false}}
 for k,v in over or {} do
  if k=="target" then for tk,tv in v do s.target[tk]=tv end else s[k]=v end
 end
 return Context.read(s)
end

test("the situation is read from the bodies, deterministically",function()
 local x=situation()
 assert(math.abs(x.dist-4)<1e-6 and x.facingDot>.99,"face to face at 4 studs")
 assert(Context.resolve(x,Graphs.Flashstep,Attacks)==nil,"face to face, still, in reach: the plain strike")
 -- The same situation, twice: the same answer.
 local back=situation({target={look=V.new(0,0,-1)}})
 local m1,t1=Context.resolve(back,Graphs.Flashstep,Attacks)
 local m2,t2=Context.resolve(back,Graphs.Flashstep,Attacks)
 assert(m1==m2 and t1==t2 and t1=="back",tostring(t1))
end)

test("behind, at the flank, out of a run, inside arm's length, at the edge of reach, falling onto him",function()
 local cases={
  {situation({target={look=V.new(0,0,-1)}}),"back","BackStrike"},
  {situation({target={look=V.new(1,0,0)}}),"flank",Graphs.Flashstep.routes.side},
  {situation({pos=V.new(0,3,7),vel=V.new(0,0,-18)}),"run","DashAttack"},
  {situation({pos=V.new(0,3,2.4)}),"close",Graphs.Flashstep.heavyAfterOne},
  {situation({pos=V.new(0,3,8)}),"reach","DashAttack"}, -- (default plain reach 6.8 here)
  {situation({pos=V.new(0,7.5,2),airborne=true,vel=V.new(0,-20,0)}),"drop","DropStrike"},
 }
 for _,case in cases do
  local move,tag=Context.resolve(case[1],Graphs.Flashstep,Attacks)
  assert(tag==case[2] and move==case[3],string.format("expected %s/%s, got %s/%s",case[2],case[3],tostring(tag),tostring(move)))
 end
end)

test("a fighter's body answers the same situation in its own way",function()
 local flank=situation({target={look=V.new(1,0,0)}})
 local seen={}
 for _,id in {"Flashstep","Mirage","Lion","GentleFist"} do
  local move=Context.resolve(flank,Graphs[id],Attacks)
  assert(move,id.." has nothing at the flank")
  seen[move]=true
 end
 local n=0 for _ in seen do n+=1 end
 assert(n>=3,"four fighters at the flank play fewer than three different strikes")
 -- A declared answer wins over the default, false declines the situation.
 local graph={context={close="PalmThrust",reach=false},routes={}}
 assert(Context.resolve(situation({pos=V.new(0,3,2.4)}),graph,Attacks)=="PalmThrust")
 assert(Context.resolve(situation({pos=V.new(0,3,8)}),graph,Attacks)==nil,"a declined situation still struck")
end)

test("the strike input in the game resolves from the situation, not the counter",function()
 local Brawler=H.load("Server/Brawler")
 local function opener(setup)
  local c,a,b=H.duel("Flashstep","Mirage")
  setup(c,a,b)
  assert(c:request(a,"Attack"),"press refused")
  return a.attackName
 end
 -- His back is turned.
 assert(opener(function(c,a,b)
  c:relocate(a,V.new(0,3,4));c:relocate(b,V.new(0,3,0))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-1))
 end)=="BackStrike","from behind")
 -- Face to face at three and a half studs: the plain opener.
 assert(opener(function(c,a,b)
  c:relocate(a,V.new(0,3,3.6));c:relocate(b,V.new(0,3,0))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 end)=="Light1","face to face")
 -- Inside arm's length.
 assert(opener(function(c,a,b)
  c:relocate(a,V.new(0,3,2.4));c:relocate(b,V.new(0,3,0))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 end)==Graphs.Flashstep.heavyAfterOne,"close")
 -- Falling onto a grounded body.
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(a,V.new(0,8,2));c:relocate(b,V.new(0,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(0,8,0))
 a.airborne=true;a.root.AssemblyLinearVelocity=V.new(0,-22,0)
 assert(c:request(a,"Attack"))
 assert(a.attackName=="DropStrike","falling onto him: "..tostring(a.attackName))
 assert(not a.airHold or a.airHold<=c.now,"the drop strike holds the body in the air")
end)

-- EMB-003 -------------------------------------------------------------------
local Config=H.load("Shared/Config")
local function jabbed()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(a,V.new(0,3,3.6));c:relocate(b,V.new(0,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 assert(c:request(a,"Attack"))
 local n=0
 repeat H.step(c,.005);n+=1 until b.reaction=="HitStun" or n>120
 assert(b.reaction=="HitStun","setup: the jab did not land ("..tostring(b.reaction)..")")
 return c,a,b
end

test("an ordinary blow takes control for a moment: early the dodge is the substitution, past its share the body answers",function()
 local c,a,b=jabbed()
 -- At once: no say yet (the guard is refused, the dodge is the substitution).
 assert(not c:request(b,"Guard"),"guarded straight out of the blow")
 local charges=b.subCharges
 assert(c:request(b,"Dodge"),"no substitution out of the blow")
 assert(b.subCharges==charges-1,"the early dodge was not the substitution")
 -- Past the share: the guard comes back up (guard stamina), no charge spent.
 local c2,x,y=jabbed()
 local tune=Config.Agency
 H.step(c2,math.max(tune.Min,(y.reactionUntil-y.reactionStartedAt)*tune.Stand)+.01)
 local stamina,charges2=y.stamina,y.subCharges
 assert(c2:request(y,"Guard"),"no guard recovery past the share")
 assert(y.reaction==nil and y.state=="Guarding","the body is still reacting")
 assert(y.stamina==stamina-tune.GuardCost and y.subCharges==charges2,"the guard recovery's price is wrong")
 -- Or a step out of it (chakra).
 local c3,p,q=jabbed()
 H.step(c3,math.max(tune.Min,(q.reactionUntil-q.reactionStartedAt)*tune.Stand)+.01)
 local chakra=q.chakra
 q.move=V.new(1,0,0)
 assert(c3:request(q,"Dodge"),"no step out past the share")
 assert(q.reaction==nil and q.state=="Dodging" and q.chakra<=chakra-tune.StepCost,"the step out did not happen or cost nothing")
end)

test("a body in an air string rights itself past its share; the string drops it after a few blows",function()
 local Brawler=H.load("Server/Brawler")
 local c,a,b=H.duel("Lion","Mirage")
 c:relocate(a,V.new(0,14,3.6));c:relocate(b,V.new(0,14,0))
 a.airborne=true
 Brawler.react(c,b,"Juggled",V.new(0,15,8),.62,a)
 H.step(c,.62*Config.Agency.Air+.02)
 local chakra=b.chakra
 assert(c:request(b,"Dodge"),"no air recovery past the share")
 assert(b.reaction==nil and b.airRecoverUsed and b.chakra==chakra-Config.Agency.AirCost,"not righted in the air")
 assert(b.root.AssemblyLinearVelocity.Y>0,"the recovery did not lift the body")
 -- A second one in the same air time is refused (it is the substitution then).
 Brawler.react(c,b,"Juggled",V.new(0,15,8),.62,a)
 H.step(c,.62*Config.Agency.Air+.02)
 assert(Brawler.recoverable(c,b)==nil,"a second air recovery in one air time")
 -- The air string's own limit.
 local c2,x,y=H.duel("Lion","Mirage")
 c2:relocate(x,V.new(0,20,3.4));c2:relocate(y,V.new(0,20,0))
 x.root.CFrame=H.C.lookAt(x.root.Position,y.root.Position)
 x.airborne=true;y.airborne=true
 local limited=false
 for k=1,Config.Agency.AirHits+2 do
  Brawler.react(c2,y,"Juggled",V.new(0,0,0),.6,x)
  local p={name="Air1",kind="Brawl",spec=Attacks.Air1}
  -- Each blow lands through the real contact path.
  x.pending=nil
  Brawler.start(c2,x,if k%2==1 then "Air1" else "Air2")
  for _=1,40 do H.step(c2,.01);if (y.airStringHits or 0)>=k or y.reaction=="Knockdown" then break end end
  c2:relocate(x,y.root.Position+V.new(0,0,3.4));x.root.CFrame=H.C.lookAt(x.root.Position,y.root.Position)
  x.airborne=true
  if y.reaction=="Knockdown" then limited=true;break end
 end
 assert(limited,"the air string never dropped the body ("..tostring(y.airStringHits).." air hits)")
end)

print(string.format("NinjaDuel embodiment: %d PASS (headless; the freedom is a Studio check)",passed))
