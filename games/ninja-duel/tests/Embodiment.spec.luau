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

-- EMB-004 -------------------------------------------------------------------
local World=H.load("Server/WorldReaction")
local Enum=require("@lune/roblox").Enum
local function surface(material,size,breakable)
 local part=H.fakePart(V.new(10,size.Y/2,0))
 part.Size=size;part.Anchored=true;part.Material=Enum.Material[material];part.Name="Prop"
 part.Parent={Name="Arena"}
 if breakable then part:SetAttribute("WorldBreakable",true) end
 return part
end
local function hitOn(part,energy,contact,element,at)
 return {part=part,position=at or V.new(8.7,3,0),normal=V.new(-1,0,0),energy=energy,contact=contact,element=element,direction=V.new(1,0,0)}
end

test("the material decides the mark, the same blow twice deepens one mark",function()
 local c=H.duel("Flashstep","Mirage")
 local wood,stone,earth=surface("Wood",V.new(2.6,30,2.6)),surface("Slate",V.new(7,4,4)),H.ground
 assert(World.impact(c,hitOn(wood,30,"blunt")).scar=="crack")
 assert(World.impact(c,hitOn(wood,30,"pierce",nil,V.new(8.7,6,0))).scar=="puncture")
 assert(World.impact(c,hitOn(stone,30,"pierce")).scar=="chip")
 local fire=World.impact(c,hitOn(stone,40,"blast","fire",V.new(8.7,1,1)))
 assert(fire.scar=="crater" and fire.element=="fire")
 assert(World.impact(c,{part=earth,position=V.new(0,0,0),normal=V.yAxis,energy=50,contact="blunt"}).scar=="crater")
 local w=World.state(c)
 local kinds={}
 for _,scar in w.scars do kinds[scar.kind]=(kinds[scar.kind] or 0)+1 end
 assert(kinds.crack==1 and kinds.puncture==1 and kinds.chip==1 and kinds.crater==2 and kinds.scorch==1,"marks: crack "..tostring(kinds.crack).." puncture "..tostring(kinds.puncture).." chip "..tostring(kinds.chip).." crater "..tostring(kinds.crater).." scorch "..tostring(kinds.scorch))
 -- A blade that stays in wood is a world fact; in stone it is not.
 assert(#w.embeds==1 and w.embeds[1].part==wood,"embeds")
 -- The same blow at the same place: one deeper mark, not two parts.
 local before=#w.scars
 local first=World.impact(c,hitOn(wood,30,"blunt"))
 assert(#w.scars==before and w.stats.merged>=1,"the repeated blow stacked a new mark")
 -- Too little energy marks nothing.
 assert(World.impact(c,hitOn(stone,2,"blunt",nil,V.new(8.7,2,-1)))==nil)
end)

test("the arena's memory is bounded: oldest marks leave first",function()
 local c=H.duel("Flashstep","Mirage")
 local Config=H.load("Shared/Config")
 local parts={}
 for k=1,Config.World.MaxScars+12 do
  World.impact(c,{part=H.ground,position=V.new(k*6,0,0),normal=V.yAxis,energy=40,contact="blunt"})
 end
 local w=World.state(c)
 assert(#w.scars==Config.World.MaxScars,"scar count "..#w.scars)
 assert(w.scars[1].position.X>12*6,"the oldest marks were kept")
 assert(w.stats.scars==Config.World.MaxScars+12)
end)

test("a breakable trunk cracks, then falls; the stadium wall only carries its marks",function()
 local c=H.duel("Flashstep","Mirage")
 local Brawler=H.load("Server/Brawler")
 local trunk=surface("Wood",V.new(2.6,30,2.6),true);trunk.Name="Field tree"
 local wall=surface("Concrete",V.new(2,40,60));wall:SetAttribute("NinjaWall",true)
 local states={}
 for k=1,12 do
  local r=World.impact(c,hitOn(trunk,60,"blunt"))
  states[r.state]=true
  if r.broken then break end
 end
 assert(states.Cracked and trunk:GetAttribute("WorldState")=="Broken","the trunk never broke")
 assert(trunk.Size.Y<3 and not Brawler.splatSurface(trunk),"the stump still takes a splat")
 assert(World.state(c).stats.breaks==1)
 for _,scar in World.state(c).scars do assert(scar.surface~=trunk,"a mark of the standing trunk floats where it was") end
 for _=1,40 do World.impact(c,hitOn(wall,80,"blast")) end
 assert(wall:GetAttribute("WorldState")=="Cracked","the wall broke or never cracked: "..tostring(wall:GetAttribute("WorldState")))
end)

test("a body thrown into a worn tree goes through it; into a sound one, it splats and marks it",function()
 local Brawler=H.load("Server/Brawler")
 local Config=H.load("Shared/Config")
 local function throw(worn)
  H.clearWalls()
  local c,a,b=H.duel("Lion","Mirage")
  local tree=H.addWall(8)
  tree.Name="Field tree";tree.Material=Enum.Material.Wood;tree.Size=V.new(2.6,30,2.6);tree.CFrame=H.C.new(V.new(9.3,15,0))
  tree:SetAttribute("NinjaWall",nil);tree:SetAttribute("WorldBreakable",true)
  if worn then local rec=World.record(c,tree);rec.integrity=8 end
  c:relocate(a,V.new(-3,3,0));c:relocate(b,V.new(2,7,0))
  b.airborne=true
  Brawler.react(c,b,"Knockback",V.new(44,8,0),.8,a)
  local through=false
  for k=1,60 do H.step(c,.01);if b.root.Position.X>9.5 then through=true;break end;if b.reaction=="WallSplat" then break end end
  H.clearWalls()
  return c,b,tree,through
 end
 local c1,b1,tree1,through1=throw(false)
 assert(b1.reaction=="WallSplat" and not through1,"a sound tree did not stop the body ("..tostring(b1.reaction)..")")
 assert(#World.state(c1).scars>=1 and World.record(c1,tree1).integrity<World.record(c1,tree1).max,"the splat left no mark")
 local c2,b2,tree2,through2=throw(true)
 assert(tree2:GetAttribute("WorldState")=="Broken","the worn tree held")
 assert(through2 and b2.reaction~="WallSplat","the body did not carry on through ("..tostring(b2.reaction)..")")
 assert(c2.match.events.SmashThrough==1,"no SmashThrough event")
end)

test("blades, fire and a swing that met the world leave their own marks",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local trunk=surface("Wood",V.new(2.6,30,2.6),true)
 local hit={Instance=trunk,Position=V.new(8.7,3,0),Normal=V.new(-1,0,0)}
 assert(World.projectile(c,{kind="kunai",damage=2,a=a,direction=V.new(1,0,0)},hit).scar=="puncture")
 local fire=World.projectile(c,{kind="fireball",damage=12,radius=2.4,a=a,direction=V.new(1,0,0)},{Instance=trunk,Position=V.new(8.7,5,0),Normal=V.new(-1,0,0)})
 assert(fire.element=="fire" and fire.wear>fire.wear*0+30,"a fireball barely touched the trunk")
 -- A declared world contact wins (a family projectile, a technique).
 assert(World.projectile(c,{kind="anything",world={contact="energy",element="lightning"},damage=8,a=a},{Instance=trunk,Position=V.new(8.7,8,0),Normal=V.new(-1,0,0)}).scar=="hole")
 -- A swing that whiffs into a wall in front of it.
 H.clearWalls()
 local wall=H.addWall(2.2);wall.Material=Enum.Material.Concrete
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(-40,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(5,3,0))
 a.target=b
 local before=World.state(c).stats.impacts
 assert(c:request(a,"Attack"))
 for _=1,80 do H.step(c,.01) end
 H.clearWalls()
 assert(World.state(c).stats.impacts>before,"the whiffed swing never met the wall")
end)

-- Perception -----------------------------------------------------------------
local Perception=H.load("Server/Perception")

test("the space is read: a surface at his back changes the strike, and ends a string",function()
 local Brawler=H.load("Server/Brawler")
 -- Pure: the wall situation and its default, and `only`.
 local x=situation();x.wallBehind=5
 local move,tag=Context.resolve(x,Graphs.Flashstep,Attacks)
 assert(tag=="wall" and move=="Light3","wall situation: "..tostring(tag).."/"..tostring(move))
 assert(Context.resolve(situation({target={look=V.new(0,0,-1)}}),Graphs.Flashstep,Attacks,{wall=true})==nil,"only= let another situation through")
 -- In the game: his back to the wall, the opener is the drive, and it puts him in it.
 H.clearWalls()
 local c,a,b=H.duel("Flashstep","Mirage")
 H.addWall(8)
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(3.6,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 local seen=Perception.read(c,a)
 assert(seen.behindTarget and math.abs(seen.behindTarget.distance-4.4)<.2 and seen.behindTarget.kind=="wall","perception: "..tostring(seen.behindTarget and seen.behindTarget.distance))
 assert(c:request(a,"Attack") and a.attackName=="Light3","opener with his back to the wall: "..tostring(a.attackName))
 local splat=false
 for _=1,120 do H.step(c,.01);if b.reaction=="WallSplat" then splat=true;break end end
 assert(splat,"the drive did not put him on the wall ("..tostring(b.reaction)..")")
 H.clearWalls()
 -- Inside a string: no wall, a light; the wall appears behind him, the next press ends the string into it.
 local function jabX()
  local c,a,b=H.duel("Flashstep","Mirage")
  c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(3.6,3,0))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
  assert(c:request(a,"Attack") and a.attackName=="Light1","setup: the opener in the open is "..tostring(a.attackName))
  local n=0
  repeat H.step(c,.005);n+=1 until b.reaction=="HitStun" or n>120
  return c,a,b
 end
 local c2,x2,y2=jabX()
 assert(x2.combo==1,"setup: no confirmed jab")
 H.step(c2,x2.untilTime-c2.now+.01)
 H.addWall(y2.root.Position.X+5)
 x2.perception=nil
 assert(c2:request(x2,"Attack") and x2.attackName=="Light3","inside the string with a wall behind him: "..tostring(x2.attackName))
 H.clearWalls()
 local c3,x3,y3=jabX()
 H.step(c3,x3.untilTime-c3.now+.01)
 assert(c3:request(x3,"Attack") and x3.attackName=="Light2","inside the string in the open: "..tostring(x3.attackName))
end)

test("the space is read: broken scenery is no surface; the bot brings him to a wall and leaves a corner",function()
 local AI=H.load("Server/AI")
 local trunk=H.fakePart(V.new(0,10,0));trunk.Name="Field tree"
 assert(Perception.surface(trunk))
 trunk:SetAttribute("WorldState","Broken")
 assert(not Perception.surface(trunk),"a stump is still a surface")
 -- Herding: a wall six studs past him, the bot at his side.
 H.clearWalls()
 local c,a,b=H.duel("Mirage","Flashstep")
 H.addWall(10)
 c:relocate(b,V.new(4,3,0));c:relocate(a,V.new(4,3,7))
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 a.def=table.clone(a.def);a.def.Techniques={}
 local bot=AI.new(c,a,7)
 -- A pressing bot (not probing at range, not breathing).
 bot.probing=false;bot.modeUntil=math.huge
 local function side() local d=a.root.Position-b.root.Position;d=V.new(d.X,0,d.Z).Unit;return d:Dot(V.new(-1,0,0)) end
 local before=side()
 local herded=false
 for _=1,100 do
  bot:update(c.now)
  H.step(c,.02)
  if c.match.events["Perceive:herd:wall"] then herded=true end
  if side()>.8 then break end
 end
 H.clearWalls()
 assert(herded,"the bot never read the wall near him")
 assert(side()>before+.5,string.format("the bot did not circle to the far side (%.2f -> %.2f)",before,side()))
 -- Its own back to the wall: it slips out sideways instead of trading there.
 local c2,x,y=H.duel("Mirage","Flashstep")
 H.addWall(10)
 c2:relocate(x,V.new(8,3,0));c2:relocate(y,V.new(2,3,0))
 x.def=table.clone(x.def);x.def.Techniques={}
 local bot2=AI.new(c2,x,3);bot2.probing=false;bot2.modeUntil=math.huge
 for _=1,40 do bot2:update(c2.now);H.step(c2,.02) end
 H.clearWalls()
 assert(c2.match.events["Perceive:corner"],"the cornered bot never read its own back")
 assert(math.abs(x.root.Position.Z)>1.5 or x.root.Position.X<6.5,"still pinned in the corner: "..tostring(x.root.Position))
end)

print(string.format("NinjaDuel embodiment: %d PASS (headless; the freedom is a Studio check)",passed))
