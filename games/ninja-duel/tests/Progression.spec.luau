-- Fighter progression (PROG-001/002/003): skill-tree integrity, build
-- validation, ranked budgets, AI budget builds, and the hooks through which a
-- build changes real combat behaviour. A 0-SP build must be today's fighter.
local H=require("./Harness")
local V=H.V
local SkillBuilds=H.load("Server/SkillBuilds")
local SkillTrees=H.load("Server/SkillTrees")
local MoveGraphs=H.load("Shared/MoveGraphs")
local AI=H.load("Server/AI")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local CORE4={"Flashstep","Mirage","GentleFist","Lion"}
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
-- Deep comparison; returns the first differing path.
local function diff(x,y,path)
 path=path or "root"
 if type(x)~=type(y) then return path..": "..type(x).." vs "..type(y) end
 if type(x)~="table" then if x~=y then return path..": "..tostring(x).." vs "..tostring(y) end return nil end
 for k,v in x do local d=diff(v,y[k],path.."."..tostring(k));if d then return d end end
 for k in y do if x[k]==nil then return path.."."..tostring(k)..": missing" end end
 return nil
end
local function kit(fighter,nodes) return assert(SkillBuilds.build(fighter,nodes)) end
-- Run a clean string until the chain is open (Recovery + chainOpen).
local function confirmHit(c,a)
 assert(c:request(a,"Attack"),"opening strike refused")
 for _=1,90 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0) then return end end
 error("the string never opened ("..tostring(a.state)..")")
end

-- Tree integrity ------------------------------------------------------------
test("CORE4 skill trees are valid, complete and bounded (120-150 SP to max)",function()
 for _,id in CORE4 do
  local errors=SkillBuilds.checkTree(id)
  assert(#errors==0,table.concat(errors," | "))
  local design=SkillBuilds.maxCost(id,false)
  assert(design>=120 and design<=150,id.." design max "..design)
  local majors=0;local wiredMajors=0
  for _,node in SkillTrees[id].Nodes do
   if node.Major then majors+=1;if SkillBuilds.wired(id,node.Id) then wiredMajors+=1 end end
  end
  assert(wiredMajors>=3,id.." has "..wiredMajors.." wired major nodes")
  print(string.format("  %-10s %2d nodes, %d major (%d wired), design max %d SP, playable max %d SP, unwired: %s",
   id,#SkillTrees[id].Nodes,majors,wiredMajors,design,SkillBuilds.maxCost(id,true),table.concat(SkillBuilds.unwired(id),",")))
 end
end)

test("tree checker rejects broken data: unbounded stat, replaced base route, cycle, typo, major without behaviour",function()
 local original=SkillTrees.Flashstep.Nodes
 local function with(mutate)
  local nodes=SkillBuilds.copy(original)
  mutate(nodes)
  SkillTrees.Flashstep.Nodes=nodes
  local ok,errors=pcall(SkillBuilds.checkTree,"Flashstep")
  SkillTrees.Flashstep.Nodes=original
  assert(ok,errors)
  return table.concat(errors," | ")
 end
 local function byId(nodes,id) for _,n in nodes do if n.Id==id then return n end end end
 assert(with(function(n) byId(n,"Endurance").Effects={{"def.Health","add",40}} end):find("x base"),"an oversized health stat passed")
 assert(with(function(n) byId(n,"SpikeAnchor").Effects={{"graph.onRoute.Launcher","set","floorSeal"}} end):find("replace part of the base kit"),"a node replaced a base payoff")
 assert(with(function(n) byId(n,"SealInk").Requires={"KunaiRecall"} end):find("cycle"),"a prerequisite cycle passed")
 assert(with(function(n) byId(n,"SealCraft").Effects={{"tech.MarkedBlade.Cooldwn","mul",.9}} end):find("not read by the runtime"),"a typo passed")
 assert(with(function(n) byId(n,"StringFlash").Effects={{"tech.Flashstep.Cost","add",-1}} end):find("must add behaviour"),"a numeric major passed")
 assert(with(function(n) byId(n,"Endurance").Effects={{"def.GuardStrength","add",.1}} end)~="","a dead field passed")
 assert(#SkillBuilds.checkTree("Flashstep")==0,"the original tree was not restored")
end)

test("0-SP build is exactly today's kit (definition and move graph)",function()
 for _,id in CORE4 do
  local base=SkillBuilds.apply(id,{})
  assert(base.spent==0 and #base.nodes==0)
  local d=diff(base.def,H.fighters[id]);assert(not d,id.." def differs: "..tostring(d))
  d=diff(base.graph,MoveGraphs[id]);assert(not d,id.." graph differs: "..tostring(d))
  assert(base.def~=H.fighters[id],"the kit must be a copy, never the shared definition")
  -- Every wired node changes the kit; nothing leaks into the shared tables.
  for _,node in SkillTrees[id].Nodes do
   local with=SkillBuilds.apply(id,{node.Id})
   assert(diff(with.def,base.def) or diff(with.graph,base.graph),id.."."..node.Id.." changes nothing")
  end
  d=diff(SkillBuilds.apply(id,{}).def,H.fighters[id]);assert(not d,"a build leaked into Fighters: "..tostring(d))
 end
 -- Without a kit the actor still uses the shared tables themselves.
 local c,a=H.duel("Flashstep","Mirage")
 assert(a.def==H.fighters.Flashstep and a.graph==nil and a.build==nil,"an actor without a build is not the canonical fighter")
end)

-- AI against AI, with and without 0-SP kits: every recorded tick must match.
local function replay(first,second,kits)
 local c,a,b,match=H.duel(first,second,kits)
 place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
 -- Locked like both fighters of a real match (Matches:start): faceLocked turns them.
 a.locked=true;b.locked=true
 local one,two=AI.new(c,a,7),AI.new(c,b,11)
 local trace={}
 for step=1,1500 do
  if match.phase~="Duel" then break end
  one:update(c.now);two:update(c.now)
  H.step(c,.01)
  if step%5==0 then
   for _,x in {a,b} do
    local p=x.root.Position
    table.insert(trace,string.format("%d %s %.4f %.4f %.4f %.4f %.4f %s %s %s",step,x.id,p.X,p.Y,p.Z,x.health,x.chakra,x.state,tostring(x.attackName),tostring(x.reaction)))
   end
  end
 end
 return trace,a,b
end
test("0-SP builds replay AI duels tick for tick like no build at all",function()
 local busy=0
 for _,pair in {{"Flashstep","Mirage"},{"GentleFist","Lion"},{"Mirage","Lion"},{"Lion","Flashstep"}} do
  local plain=replay(pair[1],pair[2])
  local built=replay(pair[1],pair[2],{A=SkillBuilds.apply(pair[1],{}),B=SkillBuilds.apply(pair[2],{})})
  assert(#plain==#built and #plain>100,"trace length differs")
  for i,line in plain do assert(line==built[i],pair[1].." vs "..pair[2].." diverged at "..i..": "..line.." / "..built[i]) end
  for _,line in plain do if not string.find(line," Neutral ",1,true) then busy+=1 end end
 end
 assert(busy>20,"the AIs barely acted ("..busy..")")
end)

-- A fixed script of real requests (strings, routes, heavy, every technique,
-- tools, guard, dodge, substitution) against a scripted opponent.
local SCRIPT={
 {0,"place"},{1,"A","Attack"},{28,"A","Attack"},{56,"A","Attack","toward"},{110,"A","Pursuit"},
 {200,"place"},{201,"A","Attack"},{229,"A","Heavy"},{300,"A","Technique1"},{360,"A","Tool"},
 {420,"place"},{421,"B","Attack"},{423,"A","Guard"},{470,"A","GuardOff"},{480,"A","Dodge","side"},
 {560,"place"},{561,"A","Technique2"},{640,"A","Attack"},{700,"A","Technique3"},{800,"place"},{801,"A","Technique4"},
 {900,"A","Technique5"},{1000,"place"},{1001,"B","Attack"},{1012,"A","Substitute"},{1060,"A","Attack"},
 {1100,"place"},{1101,"A","Attack"},{1129,"A","Attack","side"},{1170,"A","Attack","back"},{1240,"A","Tool","back"},
}
local function gauntlet(fighter,kits)
 local c,a,b,match=H.duel(fighter,"Flashstep",kits)
 a.locked=true;b.locked=true
 local trace={}
 local cursor=1
 for step=0,1400 do
  if match.phase~="Duel" then break end
  while SCRIPT[cursor] and SCRIPT[cursor][1]==step do
   local entry=SCRIPT[cursor];cursor+=1
   if entry[2]=="place" then
    place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
    for _,x in {a,b} do x.move=V.zero end
   else
    local x=if entry[2]=="A" then a else b
    local toward=(x.target.root.Position-x.root.Position)*V.new(1,0,1)
    x.move=if entry[4]=="toward" then toward.Unit elseif entry[4]=="back" then -toward.Unit elseif entry[4]=="side" then V.new(-toward.Unit.Z,0,toward.Unit.X) else V.zero
    local ok,reason=c:request(x,entry[3],x.target.root.Position)
    table.insert(trace,string.format("%d %s %s %s %s",step,entry[2],entry[3],tostring(ok),tostring(reason)))
   end
  end
  H.step(c,.01)
  for _,x in {a,b} do
   local p=x.root.Position
   table.insert(trace,string.format("%d %s %.4f %.4f %.4f %.4f %.4f %s %s %s %d",step,x.id,p.X,p.Y,p.Z,x.health,x.chakra,x.state,tostring(x.attackName),tostring(x.reaction),#x.anchors))
  end
 end
 return trace,a,b
end
test("0-SP builds replay a scripted gauntlet of every action exactly like no build",function()
 for _,id in CORE4 do
  local plain,a,b=gauntlet(id)
  local built=gauntlet(id,{A=SkillBuilds.apply(id,{}),B=SkillBuilds.apply("Flashstep",{})})
  assert(#plain==#built,id..": trace length differs")
  for i,line in plain do assert(line==built[i],id.." diverged at line "..i..": "..line.." / "..built[i]) end
  local events=a.events or {}
  assert((events.Damage or 0)>=3 and (events.Technique or 0)>=2,id..": the gauntlet exercised too little ("..tostring(events.Damage).." hits, "..tostring(events.Technique).." techniques)")
  print(string.format("  %-10s %d lines identical, %d hits, %d techniques, %d routes",id,#plain,events.Damage or 0,events.Technique or 0,events.Route or 0))
 end
end)

-- Build validation and ranked budgets -----------------------------------------
test("build validation: unknown, duplicate, missing prerequisite, exclusive pair, locked, over budget",function()
 local function refused(nodes,opts,pattern)
  local ok,reason=SkillBuilds.validate("Flashstep",nodes,opts)
  assert(not ok,"accepted "..table.concat(nodes,","));assert(string.find(reason,pattern,1,true),reason)
 end
 refused({"Nope"},nil,"Unknown node")
 refused({"SealInk","SealInk"},nil,"Duplicate")
 refused({"KunaiRecall"},nil,"requires SealInk")
 refused({"FlashEconomy","AirSwitchSeal","SpikeAnchor"},nil,"Exclusive choice AirSeal")
 refused({"AirExit","FlashEconomy"},nil,"requires one of")
 refused({"SealInk","KunaiRecall"},{unlocked={SealInk=true}},"Node locked: KunaiRecall")
 refused({"FlashEconomy","StringFlash","SealInk","KunaiRecall","QuickstepCut","DeepReserves","Endurance","QuickHands"},{budget=50},"budget is 50")
 local ok,total=SkillBuilds.validate("Flashstep",{"KunaiRecall","SealInk"},{budget=14})
 assert(ok and total==14,"a valid build listed out of order was refused")
 assert(not SkillBuilds.validate("Flashstep","SealInk"),"a non-list build passed")
 assert(not SkillBuilds.validate("Sand",{}),"a fighter without a tree accepted a build")
 -- Same nodes in any order give the same kit (effects stack in tree order).
 assert(not diff(kit("Mirage",{"QuickRead","EconomicRead","ReadCancel"}).def,kit("Mirage",{"ReadCancel","EconomicRead","QuickRead"}).def),"order changed the kit")
end)

test("ranked brackets: 50/80/100/120+, a player only activates the bracket budget whatever he unlocked",function()
 assert(#SkillBuilds.checkBrackets()==0,table.concat(SkillBuilds.checkBrackets()," | "))
 local budgets={}
 for _,bracket in SkillBuilds.Brackets do budgets[bracket.Id]=bracket.Budget end
 assert(budgets.Fundamentals==50 and budgets.Identity==80 and budgets.Advanced==100 and budgets.Endgame>=120)
 assert(#SkillBuilds.checkBrackets({{Id="A",Budget=80,Enabled=true},{Id="B",Budget=50,Enabled=true}})>0,"decreasing budgets accepted")
 for _,id in CORE4 do
  -- Everything unlocked: the full tree is available, the bracket still caps it.
  local unlocked={}
  for _,node in SkillTrees[id].Nodes do unlocked[node.Id]=true end
  local full=SkillBuilds.maximalBuilds(id,true)[1]
  local kit,reason=SkillBuilds.admit("Fundamentals",id,full,unlocked)
  assert(not kit and string.find(reason,"budget is 50",1,true),id..": the full tree entered the 50 SP queue ("..tostring(reason)..")")
  assert(SkillBuilds.admit("Endgame",id,full,unlocked,{allowClosed=true}),id..": the full tree does not fit the endgame bracket")
  assert(not SkillBuilds.admit("Endgame",id,full,unlocked),"a closed bracket admitted a build")
  assert(not SkillBuilds.admit("Nope",id,{},unlocked),"unknown bracket")
 end
end)

test("a node whose hook is not wired stays data-only: no activation, no unlock, outside the playable max",function()
 local spec=SkillBuilds.OPTIONAL["tech.Chidori.WallCharge"]
 spec.Wired=false
 local ok,err=pcall(function()
  assert(not SkillBuilds.wired("Lion","WallChidori") and table.find(SkillBuilds.unwired("Lion"),"WallChidori"),"the node still reads as wired")
  local okBuild,reason=SkillBuilds.validate("Lion",{"ChidoriFocus","WallChidori"})
  assert(not okBuild and string.find(reason,"not available yet",1,true),"an unwired node was activated")
  assert(SkillBuilds.validate("Lion",{"ChidoriFocus","WallChidori"},{allowUnwired=true}),"design tooling cannot preview it")
  assert(SkillBuilds.maxCost("Lion",true)==SkillBuilds.maxCost("Lion",false)-12,"the playable maximum still counts it")
  assert(#SkillBuilds.checkTree("Lion")==0,"an unwired node made the tree invalid")
  local Profiles=H.load("Server/ProfileSchema")
  local p=Profiles.new("dev_unwired")
  p=Profiles.apply(p,1,"grant",{fighter="Lion",amount=30})
  p=Profiles.apply(p,2,"unlock",{fighter="Lion",node="ChidoriFocus"})
  local unlocked,why=pcall(Profiles.apply,p,3,"unlock",{fighter="Lion",node="WallChidori"})
  assert(not unlocked and string.find(tostring(why),"not available yet",1,true),"an unwired node could be bought")
 end)
 spec.Wired=nil
 assert(ok,err)
 assert(SkillBuilds.wired("Lion","WallChidori"),"the hook was not restored")
end)

-- Build application: every hook changes real behaviour, only with its node --
local Techniques=H.load("Server/Techniques")
local Brawler=H.load("Server/Brawler")
-- Two fighters facing at a short gap, the first one with a build.
local function duelWith(first,second,nodes,secondNodes,gap)
 local c,a,b,match=H.duel(first,second,{A=nodes and kit(first,nodes),B=secondNodes and kit(second,secondNodes)})
 gap=gap or 4.5
 place(c,a,b,V.new(0,3,gap/2),V.new(0,3,-gap/2))
 return c,a,b,match
end
local function anchorsOn(a,b)
 local body,planted={}, {}
 for _,entry in a.anchors or {} do if entry.actor and entry.actor==b then table.insert(body,entry) elseif not entry.actor then table.insert(planted,entry) end end
 return body,planted
end
-- An air hit, then the stick picks the air route (Branches air grammar setup).
local function airRoute(c,a,b,stick)
 place(c,a,b,V.new(0,3,1.5),V.new(0,3,-1.5))
 for _,x in {a,b} do c:relocate(x,x.root.Position+V.new(0,7,0));x.airborne=true;x.airHold=c.now+1 end
 b.reaction="Juggled";b.reactionUntil=c.now+1;b.reactionVelocity=V.zero
 assert(c:request(a,"Attack"),"air strike refused")
 local open=false
 for _=1,60 do H.step(c,.01);b.reactionVelocity=V.zero;if a.chainOpen and c.now>=a.chainAt then open=true;break end end
 assert(open,"the air string never opened")
 a.move=if stick=="back" then -a.root.CFrame.LookVector else a.root.CFrame.RightVector
 assert(c:request(a,"Attack"),"air route refused")
 local name=a.attackName
 for _=1,60 do H.step(c,.01);if (a.events.Hit or 0)>=2 then break end end
 return name
end

test("Minato · Cut and Flash: a clean string cancels into Flying Thunder God, only with the node and a seal",function()
 local function attempt(nodes,seal)
  local c,a,b=duelWith("Flashstep","Mirage",nodes)
  if seal then Techniques.plant(c,a,V.new(20,0,0),V.yAxis) end
  confirmHit(c,a)
  local ok=c:request(a,"Technique2")
  return ok,c,a,b
 end
 local ok,c,a=attempt({"FlashEconomy","StringFlash"},true)
 assert(ok,"the string did not cancel into the teleport")
 assert(a.untilTime-c.now<=.07,"the cancel slowed the teleport down to "..string.format("%.2f",a.untilTime-c.now))
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival")
 assert(a.root.Position.X>15,"did not arrive on the seal")
 assert(a.chakra<=a.def.Chakra-14+.5,"FTG cost the node price")
 assert(not attempt({"FlashEconomy"},true),"a string cancelled into a teleport without the node")
 local refused,c2,x=attempt({"FlashEconomy","StringFlash"},false)
 assert(not refused and x.chainOpen and x.state=="Recovery","with no seal the cancel must be refused and keep the string")
end)

test("Minato · Switch Seal and Spike Anchor: the air routes leave seals (exclusive choice)",function()
 local c,a,b=duelWith("Flashstep","Mirage",{"FlashEconomy","AirSwitchSeal"})
 assert(airRoute(c,a,b,"side")=="AirSwitch")
 local body=anchorsOn(a,b)
 assert(#body==1 and body[1].expires-c.now<1.8,"the air switch left no short body seal")
 local c2,x,y=duelWith("Flashstep","Mirage",{"FlashEconomy","SpikeAnchor"})
 assert(airRoute(c2,x,y,"back")=="AirSpike")
 local _,planted=anchorsOn(x,y)
 assert(#planted==1,"the air spike planted no floor seal")
 local c3,m,n=duelWith("Flashstep","Mirage",{"FlashEconomy"})
 airRoute(c3,m,n,"side")
 local b3,p3=anchorsOn(m,n)
 assert(#b3==0 and #p3==0,"the base air switch sealed something")
 assert(not SkillBuilds.validate("Flashstep",{"FlashEconomy","AirSwitchSeal","SpikeAnchor"}),"both air seals at once")
end)

test("Minato · Kunai Recall and Seal Ink: run over a planted kunai to pick it up; seals hold 15 s",function()
 local c,a,b=duelWith("Flashstep","Mirage",{"SealInk","KunaiRecall"},nil,12)
 local entry=Techniques.plant(c,a,V.new(8,0,0),V.yAxis)
 assert(math.abs(entry.expires-c.now-15)<.01,"Seal Ink did not lengthen the seal")
 a.chakra=40
 c:relocate(a,V.new(8,3,0));H.step(c,.2)
 assert(#a.anchors==1,"a fresh seal was picked up at once")
 H.step(c,.5)
 assert(#a.anchors==0,"standing on the kunai did not recover it")
 assert(a.chakra>=45,"no chakra came back ("..a.chakra..")")
 local c2,x=duelWith("Flashstep","Mirage",{},nil,12)
 local base=Techniques.plant(c2,x,V.new(8,0,0),V.yAxis)
 assert(math.abs(base.expires-c2.now-12)<.01,"a canonical seal no longer lasts 12 s")
 c2:relocate(x,V.new(8,3,0));H.step(c2,.8)
 assert(#x.anchors==1,"the base fighter picked a kunai up")
end)

test("Minato · Return Seal: a substitution leaves a seal where he stood",function()
 local function substitute(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes)
  local departure=a.root.Position
  assert(c:damage(b,a,5,false,false),"setup hit refused")
  assert(c:request(a,"Substitute"),"substitution refused")
  return a,departure
 end
 local a,departure=substitute({"SealCraft","ReturnSeal"})
 local _,planted=anchorsOn(a,nil)
 assert(#planted==1,"no seal at the departure")
 local flat=(planted[1].position-departure)*V.new(1,0,1)
 assert(flat.Magnitude<1,"the seal is not where he stood")
 local x=substitute({"SealCraft"})
 assert(#x.anchors==0,"the base substitution planted a seal")
end)

test("Minato · Quickstep Cut: a strike right after Quickstep cancels its recovery (heavy = launcher)",function()
 local function step(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes,nil,6)
  a.move=a.root.CFrame.RightVector
  assert(c:request(a,"Technique4"),"Quickstep refused")
  until_(c,.4,function() return a.state=="TechniqueRecovery" end,"no Quickstep recovery")
  a.move=V.zero
  return c:request(a,"Heavy"),a
 end
 local ok,a=step({"QuickstepCut"})
 assert(ok and a.attackName=="Launcher","the step did not convert into a launcher ("..tostring(a.attackName)..")")
 assert(not step({}),"the base Quickstep converted")
end)

test("Minato · Gale Chase: a Wind Cut that lands opens the chase window",function()
 local function gust(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes,nil,12)
  assert(c:request(a,"Technique5",b.root.Position),"Wind Cut refused")
  until_(c,1,function() return b.health<b.def.Health end,"the gust never landed")
  return a.pursuitUntil-c.now
 end
 assert(gust({"QuickstepCut","GaleChase"})>.5,"no chase window after the gust")
 assert(gust({})<=0,"the base gust opened a chase")
end)

test("Minato · Rasengan Drive: the plunging Rasengan spikes the body into a ground bounce",function()
 local function plunge(nodes)
  local c,x,y=duelWith("Flashstep","Mirage",nodes)
  c:relocate(x,V.new(0,15,3));c:relocate(y,V.new(0,13,-1))
  x.root.CFrame=H.C.lookAt(x.root.Position,y.root.Position*V.new(1,0,1)+V.new(0,15,0))
  x.airborne=true;x.airHold=c.now+1
  Brawler.react(c,y,"Juggled",V.zero,1.2,x)
  assert(c:request(x,"Technique3"),"airborne Rasengan refused")
  until_(c,.4,function() return x.attackVariant=="RasenganDrop" end,"no plunge")
  return x.pending.spec.reaction,c,y
 end
 local reaction,c,y=plunge({"RasenganFocus","RasenganDrive"})
 assert(reaction=="Spiked","the drive plunge does not spike ("..tostring(reaction)..")")
 local bounced=false
 for _=1,200 do H.step(c,.01);if (y.events or {}).GroundBounce then bounced=true;break end end
 assert(bounced,"the spiked body never bounced ("..tostring(y.reaction)..")")
 assert(plunge({"RasenganFocus"})=="Knockdown","the base plunge changed")
end)

test("Minato · Seal on the Parry: a parried strike seals the attacker for 1.8 s",function()
 local function parry(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes)
  assert(c:request(a,"Guard"))
  assert(c:request(b,"Attack"))
  until_(c,.4,function() return (a.events.Parry or 0)>0 end,"no parry")
  local body=anchorsOn(a,b)
  return body,c
 end
 local body,c=parry({"FlashEconomy","ParrySeal"})
 assert(#body==1 and math.abs(body[1].expires-c.now-1.8)<.3,"the parry left no short seal on the attacker")
 assert(#parry({"FlashEconomy"})==0,"the base parry sealed the attacker")
end)

test("Minato · Flow (awakening): a hit right after a teleport seals the body again",function()
 local function flow(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes)
  a.awakenUntil=c.now+12;a.awakened=true;a.teleportAt=c.now
  assert(c:request(a,"Attack"))
  until_(c,.4,function() return b.health<b.def.Health end,"the arrival strike never landed")
  return #anchorsOn(a,b)
 end
 assert(flow({"FlashEconomy","StringFlash","YellowFlow"})==1,"the awakened arrival hit did not reseal the body")
 assert(flow({"FlashEconomy","StringFlash"})==0,"a hit resealed without the awakening node")
end)

test("Minato · Air Exit: Tool during an air arrival plants a seal on the floor below",function()
 local function exit(nodes)
  local c,a,b=duelWith("Flashstep","Mirage",nodes,nil,14)
  c:relocate(b,V.new(0,13,-6));b.airborne=true
  Brawler.react(c,b,"Juggled",V.zero,2,a)
  Techniques.plant(c,a,b.root.Position,V.yAxis,b)
  assert(c:request(a,"Technique2"),"teleport refused")
  until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival")
  assert(a.airborne,"the arrival is not in the air")
  local ok=c:request(a,"Tool")
  local planted={}
  for _=1,100 do H.step(c,.01);local _,p=anchorsOn(a,b);planted=p;if #p>0 then break end end
  return ok,planted
 end
 local ok,planted=exit({"FlashEconomy","SpikeAnchor","AirExit"})
 assert(ok and #planted==1,"no seal planted below")
 -- The harness floor answers rays at its body reach (y=1.9), Studio at y=0.
 assert(planted[1].normal.Y>.9 and planted[1].surface.Y<2.5,"the seal is not on the floor ("..tostring(planted[1].surface)..")")
 assert(not exit({"FlashEconomy","SpikeAnchor"}),"the base arrival threw a tool")
end)

test("Itachi · Read Cancel: a clean string ends in the Read stance (exclusive with Patient Read)",function()
 local function cancel(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes)
  confirmHit(c,a)
  return c:request(a,"Technique1"),c,a,b
 end
 local ok,c,a,b=cancel({"QuickRead","ReadCancel"})
 assert(ok and a.untilTime-c.now<=.11,"the string did not end in the Read stance")
 until_(c,.3,function() return a.readUntil>c.now end,"no Read window")
 -- The retaliation is read: the attacker is exposed, Itachi gets the counter.
 b.reaction=nil;b.state="Neutral";b.untilTime=c.now;b.lockUntil=0
 assert(c:request(b,"Attack"),"retaliation refused")
 until_(c,.4,function() return (a.counterUntil or 0)>c.now end,"the retaliation was not read")
 assert(not cancel({"QuickRead"}),"a string ended in Read without the node")
 assert(not SkillBuilds.validate("Mirage",{"QuickRead","ReadCancel","PatientRead"}),"both Read styles at once")
end)

test("Itachi · Wall Palm: the counter palm drives the body into a wall 45 degrees off his line",function()
 local function palm(nodes)
  H.clearWalls();H.addWall(8)
  local c,a,b=duelWith("Mirage","Flashstep",nodes)
  confirmHit(c,a)
  assert(c:request(a,"Heavy"),"heavy refused")
  assert(a.attackName=="CounterPalm","heavy after one hit is "..tostring(a.attackName))
  for _=1,120 do H.step(c,.01);if b.reaction=="WallSplat" then return true end end
  return false
 end
 assert(palm({"FeintEcho","WallPalm"}),"the steered palm never splatted the body on the wall")
 assert(not palm({"FeintEcho"}),"the base palm reached a wall off its line")
end)

test("Itachi · Feint Echo: the feint step leaves a decoy; a swing at it is caught",function()
 local function echo(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes)
  confirmHit(c,a)
  a.move=a.root.CFrame.RightVector
  assert(c:request(a,"Attack"))
  assert(a.attackName=="FeintStep","side route is "..tostring(a.attackName))
  until_(c,.4,function() return (a.events.Hit or 0)>=2 end,"the feint step never landed")
  return c,a,b
 end
 local c,a,b=echo({"FeintEcho"})
 assert(b.illusionUntil>c.now and b.decoyPosition,"no decoy after the feint step")
 assert((b.decoyPosition-a.stepFrom).Magnitude<1,"the decoy is not where the step started")
 -- Swing at the decoy (the body is far away): the read is given away.
 until_(c,1,function() return b.reaction==nil and b.state=="Neutral" end,"victim stuck")
 c:relocate(b,b.root.Position+V.new(0,0,-14))
 assert(c:request(b,"Attack"))
 until_(c,.6,function() return (a.events.MirageCatch or 0)>0 end,"the whiff at the decoy was not caught")
 assert((a.counterUntil or 0)>c.now,"no punish window")
 local c2,x,y=echo({})
 assert(y.illusionUntil<=c2.now,"the base feint step left a decoy")
end)

test("Itachi · Ricochet Chase: a redirected blade that lands opens the chase window",function()
 local function blade(nodes,bounced)
  local c,a,b=duelWith("Mirage","Flashstep",nodes,nil,10)
  local p=c:projectile(a,b.root.Position,88,18,2.5,"shuriken",nil,{origin=b.root.Position+V.new(4,0,0)})
  p.bounced=bounced
  c:projectileHit(p,b,b.root.Position,V.xAxis)
  return a.pursuitUntil-c.now
 end
 assert(blade({"Precision","RicochetChase"},true)>.4,"a landed ricochet opened no chase")
 assert(blade({"Precision","RicochetChase"},false)<=0,"a plain blade opened a chase")
 assert(blade({"Precision"},true)<=0,"the base ricochet opened a chase")
end)

test("Itachi · Flank Blades: Shadow Shuriken's hidden blades come from the flanks, past a frontal guard",function()
 local function fan(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes,nil,14)
  assert(c:request(a,"Technique2",b.root.Position),"Shadow Shuriken refused")
  local hidden={}
  for _=1,90 do
   H.step(c,.01)
   for _,p in c.projectiles do
    local side=math.abs((p.origin-b.root.Position):Dot(V.xAxis))
    if p.a==a and side>4 and not table.find(hidden,p) then table.insert(hidden,p) end
   end
  end
  return hidden,c,a,b
 end
 local hidden,c,a,b=fan({"Precision","FlankBlades"})
 assert(#hidden==2,"expected two flank blades, got "..#hidden)
 assert(c:request(b,"Guard"));H.step(c,.25)
 local before=b.health
 c:projectileHit(hidden[1],b,b.root.Position,-hidden[1].direction)
 assert(b.impactStyle~="block" and b.health<before,"a flank blade was blocked by the frontal guard")
 assert(#fan({"Precision"})==0,"the base hidden blades came from the flanks")
end)

test("Itachi · Crow Counter: after the crow substitution the next strike is the counter palm",function()
 local function crow(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes)
  assert(c:damage(b,a,5,false,false))
  assert(c:request(a,"Substitute"))
  H.step(c,.16)
  assert(c:request(a,"Attack"),"strike after the crow refused")
  return a.attackName
 end
 assert(crow({"EconomicRead","CrowCounter"})=="CounterPalm","the crow did not open the counter palm")
 assert(crow({"EconomicRead"})~="CounterPalm","the base crow opened a counter")
end)

test("Itachi · Mirage Reflex (awakening): a Sharingan parry leaves a genjutsu decoy on the attacker",function()
 local function parry(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes)
  a.awakenUntil=c.now+12;a.awakened=true
  assert(c:request(a,"Guard"))
  assert(c:request(b,"Attack"))
  until_(c,.4,function() return (a.events.Parry or 0)>0 end,"no parry")
  return b.illusionUntil-c.now,b
 end
 local left,b=parry({"QuickRead","PatientRead","MirageReflex"})
 assert(left>1 and b.decoyPosition,"the awakened parry left no decoy")
 assert(parry({"QuickRead","PatientRead"})<=0,"the base parry left a decoy")
end)

test("Itachi · Fire Geometry: a shuriken crossing his burning ground ignites and leaves a patch",function()
 local function throw(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes,nil,12)
  c:addHazard(a,V.new(0,2,0),7.5,3,6,"Fire")
  local p=c:projectile(a,b.root.Position,84,62,2,"shuriken")
  H.step(c,.02)
  local damage=p.damage
  local hazards=#c.hazards
  c:projectileHit(p,b,b.root.Position,V.zAxis)
  return damage,#c.hazards-hazards
 end
 local damage,patches=throw({"FireTempo","FireGeometry"})
 assert(damage==3 and patches==1,"the blade did not ignite ("..damage.." damage, "..patches.." patch)")
 local baseDamage,basePatches=throw({"FireTempo"})
 assert(baseDamage==2 and basePatches==0,"the base blade caught fire")
end)

test("Itachi · Wide Fan: five shuriken in the air instead of three",function()
 local function air(nodes)
  local c,a,b=duelWith("Mirage","Flashstep",nodes,nil,12)
  c:relocate(a,a.root.Position+V.new(0,6,0));a.airborne=true;a.airHold=c.now+1
  assert(c:request(a,"Tool",b.root.Position),"air throw refused")
  local seen,count={},0
  for _=1,50 do H.step(c,.01);for _,p in c.projectiles do if p.a==a and not seen[p] then seen[p]=true;count+=1 end end end
  return count
 end
 assert(air({"WideFan"})==5,"the wide fan did not throw five")
 assert(air({})==3,"the base air fan changed")
end)

test("Neji · Kaiten Cancel / Palm Barrage: a clean string ends in Rotation or in the 64 Palms (exclusive)",function()
 local c,a,b=duelWith("GentleFist","Flashstep",{"PrecisePalms","KaitenCancel"})
 confirmHit(c,a)
 assert(c:request(a,"Technique1"),"the string did not cancel into Rotation")
 assert(a.untilTime-c.now<=.05,"Rotation lost its own wind-up")
 until_(c,.5,function() return b.reaction=="Knockback" end,"the dome did not throw the opponent out")
 local c2,x,y=duelWith("GentleFist","Flashstep",{"DeepPoints","PalmBarrage"})
 confirmHit(c2,x)
 assert(c2:request(x,"Technique3"),"the string did not cancel into the 64 Palms")
 assert(x.untilTime-c2.now<=.15,"the palms kept their full wind-up")
 until_(c2,2.5,function() return (y.sealedUntil or 0)>c2.now end,"the flurry never sealed")
 local c3,m=duelWith("GentleFist","Flashstep",{"PrecisePalms","DeepPoints"})
 confirmHit(c3,m)
 assert(not c3:request(m,"Technique1") and not c3:request(m,"Technique3"),"the base string cancelled into a technique")
 assert(not SkillBuilds.validate("GentleFist",{"PrecisePalms","DeepPoints","KaitenCancel","PalmBarrage"}),"both string enders at once")
end)

test("Neji · Trigram Rebound: the twin palm bounces a pinned body off the wall",function()
 local function rebound(nodes)
  H.clearWalls();H.addWall(14)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes)
  place(c,a,b,V.new(4,3,0),V.new(8,3,0))
  Brawler.react(c,b,"Knockback",V.new(52,10,0),.5,a)
  until_(c,.5,function() return b.reaction=="WallSplat" end,"no splat")
  place(c,a,b,V.new(b.root.Position.X-3.5,3,0),b.root.Position)
  b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position-V.xAxis)
  b.reactionUntil=c.now+.8
  local health=b.health
  Brawler.start(c,a,"PalmThrust")
  until_(c,.5,function() return b.health<health end,"the palm never reached the pinned body")
  return b.reaction
 end
 assert(rebound({"VacuumEconomy","TrigramRebound"})=="Launched","the palm did not bounce the body")
 assert(rebound({"VacuumEconomy"})=="WallSplat","the base palm bounced the body")
end)

test("Neji · Redirecting Palm: his parry turns the attacker aside, closes a point and opens the twin palm",function()
 local function parry(nodes)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes)
  assert(c:request(a,"Guard"))
  assert(c:request(b,"Attack"))
  until_(c,.4,function() return (a.events.Parry or 0)>0 end,"no parry")
  local toward=(a.root.Position-b.root.Position)*V.new(1,0,1)
  local facing=b.root.CFrame.LookVector:Dot(toward.Unit)
  assert(c:request(a,"Attack"))
  return b.tenketsu or 0,facing,a.attackName
 end
 local points,facing,move=parry({"NarrowBlindSpot","RedirectParry"})
 assert(points==1 and math.abs(facing)<.3 and move=="PalmThrust","redirect missing (points "..points..", facing "..string.format("%.2f",facing)..", "..tostring(move)..")")
 local basePoints,baseFacing,baseMove=parry({"NarrowBlindSpot"})
 assert(basePoints==0 and baseFacing>.8 and baseMove~="PalmThrust","the base parry redirected")
end)

test("Neji · Outside Step: his substitution reappears on the attacker's flank with a counter",function()
 local function sub(nodes)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes)
  assert(c:damage(b,a,5,false,false))
  assert(c:request(a,"Substitute"))
  local d=a.root.Position-b.root.Position
  return math.abs(d:Dot(b.root.CFrame.RightVector)),math.abs(d:Dot(b.root.CFrame.LookVector)),(a.counterUntil or 0)-c.now
 end
 local side,ahead,counter=sub({"NarrowBlindSpot","OutsideStep"})
 assert(side>4 and ahead<1.5 and counter>.3,string.format("not an outside step (side %.1f, ahead %.1f, counter %.2f)",side,ahead,counter))
 local baseSide,baseAhead,baseCounter=sub({"NarrowBlindSpot"})
 assert(baseAhead>6 and baseCounter<=0,"the base substitution changed")
end)

test("Neji · Sealing Palm: Vacuum Palm closes a chakra point at range",function()
 local function palm(nodes)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes,nil,10)
  assert(c:request(a,"Technique2",b.root.Position))
  until_(c,.8,function() return b.health<b.def.Health end,"the palm never landed")
  return b.tenketsu or 0
 end
 assert(palm({"VacuumEconomy","SealingPalm"})==1,"no chakra point closed by the palm")
 assert(palm({"VacuumEconomy"})==0,"the base palm closed a point")
end)

test("Neji · Returning Rotation and Wide Dome: blades fly back at the thrower; the dome reaches further",function()
 local function dome(nodes,gap)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes,nil,gap)
  assert(c:request(a,"Technique1"))
  until_(c,.2,function() return (a.rotationUntil or 0)>c.now end,"no dome")
  c:projectile(b,a.root.Position,40,30,3,"kunai")
  local back
  for _=1,40 do
   H.step(c,.01)
   for _,p in c.projectiles do if p.a==a and p.kind=="kunai" then back=p end end
   if back then break end
  end
  return back,c,a,b
 end
 local back,c,a,b=dome({"SwiftRotation","ReturningRotation"},10)
 assert(back,"the kunai did not come back")
 assert(back.direction:Dot((b.root.Position-back.origin).Unit)>.8,"the returned kunai does not fly at the thrower")
 assert(not dome({"SwiftRotation"},10),"the base dome returned a blade")
 local _,c2,x,y=dome({"WideDome"},7.8)
 assert(y.reaction=="Knockback" or (x.rotationHit or {})[y],"the wide dome missed at 7.8 studs")
 local _,c3,m,n=dome({},7.8)
 assert(not (m.rotationHit or {})[n],"the base dome reached 7.8 studs")
end)

test("Neji · Lingering Seal: after the 64 Palms the techniques stay sealed 4.5 s",function()
 local function seal(nodes)
  local c,a,b=duelWith("GentleFist","Mirage",nodes,nil,4)
  assert(c:request(a,"Technique3"))
  until_(c,2.2,function() return (b.sealedUntil or 0)>c.now end,"the flurry never finished")
  return b.sealedUntil-c.now
 end
 assert(math.abs(seal({"LingeringSeal"})-4.5)<.05,"the seal did not linger")
 assert(math.abs(seal({})-3.5)<.05,"the base seal changed")
end)

test("Neji · Full Field Points (awakening): palms close points through a guard",function()
 local function guarded(nodes)
  local c,a,b=duelWith("GentleFist","Flashstep",nodes)
  a.awakenUntil=c.now+12;a.awakened=true
  assert(c:request(b,"Guard"));H.step(c,.3)
  local chakra=b.chakra
  assert(c:request(a,"Attack"))
  until_(c,.4,function() return b.impactStyle=="block" end,"the palm was not guarded")
  return b.tenketsu or 0,chakra-b.chakra
 end
 local points,drain=guarded({"PrecisePalms","PointStep","FullFieldPoints"})
 assert(points==1 and drain>12,"the awakened palm did not reach the point ("..points..", "..drain..")")
 local basePoints,baseDrain=guarded({"PrecisePalms","PointStep"})
 assert(basePoints==0 and baseDrain<6,"the base guarded palm changed")
end)

test("Sasuke · Dancing Leaf Launcher: the heavy after two clean hits is the rising kick he follows",function()
 local function heavy(nodes)
  local c,a,b=duelWith("Lion","Mirage",nodes)
  confirmHit(c,a)
  assert(c:request(a,"Attack"),"second strike refused")
  for _=1,80 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt and a.combo>=2 then break end end
  assert(a.combo>=2,"the second chain never opened")
  a.move=V.zero
  assert(c:request(a,"Heavy"),"heavy refused")
  local name=a.attackName
  for _=1,80 do H.step(c,.01);if (a.events.ShadowLeaf or 0)>0 then break end end
  return name,(a.events.ShadowLeaf or 0)
 end
 local name,shadow=heavy({"DancingLeaf"})
 assert(name=="LionKick" and shadow>0,"the heavy launcher did not become the Dancing Leaf ("..tostring(name)..")")
 local baseName,baseShadow=heavy({})
 assert(baseName=="Launcher" and baseShadow==0,"the base heavy launcher changed")
end)

test("Sasuke · Sharingan Counter: a Sharingan parry makes the next strike the vault kick",function()
 local function counter(nodes)
  local c,a,b=duelWith("Lion","Flashstep",nodes)
  assert(c:request(a,"Guard"))
  assert(c:request(b,"Attack"))
  until_(c,.4,function() return (a.events.Parry or 0)>0 end,"no parry")
  assert(c:request(a,"Attack"))
  return a.attackName
 end
 assert(counter({"SharperEyes","SharinganCounter"})=="VaultKick","the parry did not open the vault kick")
 assert(counter({"SharperEyes"})~="VaultKick","the base parry opened a vault kick")
end)

test("Sasuke · Wire Cancel and Blocked Tool: a clean string into Wire Trap; a blocked string into a throw",function()
 local function wire(nodes)
  local c,a=duelWith("Lion","Flashstep",nodes)
  confirmHit(c,a)
  return c:request(a,"Technique3"),c,a
 end
 local ok,c,a=wire({"BlockedTool","WireCancel"})
 assert(ok and a.untilTime-c.now<=.15,"the string did not cancel into the wire")
 assert(not wire({"BlockedTool"}),"the base string cancelled into the wire")
 local function blocked(nodes)
  local c2,x,y=duelWith("Lion","Flashstep",nodes)
  assert(c2:request(y,"Guard"));H.step(c2,.3)
  assert(c2:request(x,"Attack"))
  until_(c2,.5,function() return x.state=="Recovery" and x.hitBlocked end,"the strike was not blocked")
  return c2:request(x,"Tool",y.root.Position)
 end
 assert(blocked({"BlockedTool"}),"no throw out of the blocked string")
 assert(not blocked({}),"the base blocked string threw")
end)

test("Sasuke · Wire Pin: a wire near a wall ties the body against it for longer",function()
 local function bind(nodes)
  H.clearWalls();H.addWall(8)
  local c,a,b=duelWith("Lion","Flashstep",nodes)
  place(c,a,b,V.new(-8,3,0),V.new(2,3,0))
  assert(c:request(a,"Technique3",b.root.Position),"Wire Trap refused")
  until_(c,.8,function() return b.reaction=="Bound" end,"the wire never bound")
  return b.root.Position.X,b.reactionUntil-c.now
 end
 local x,left=bind({"ShurikenFan","WirePin"})
 assert(x>5.5 and left>1.2,string.format("not tied to the wall (x %.1f, %.2f s)",x,left))
 local baseX,baseLeft=bind({"ShurikenFan"})
 assert(baseX<3 and baseLeft<=1.01,"the base wire changed")
end)

test("Sasuke · Wired Flames: the hidden blades bind, the Dragon Flame follows",function()
 local function flames(nodes)
  local c,a,b=duelWith("Lion","Mirage",nodes,nil,12)
  assert(c:request(a,"Technique2",b.root.Position),"Phoenix refused")
  local wires={}
  for _=1,70 do H.step(c,.01);for _,p in c.projectiles do if p.a==a and p.kind=="wire" and not table.find(wires,p) then table.insert(wires,p) end end end
  return wires,c,a,b
 end
 local wires,c,a,b=flames({"ShurikenFan","WiredFlames"})
 assert(#wires==2 and wires[1].riders.bind==.7,"the hidden blades carry no wire")
 b.reaction=nil;b.state="Neutral";b.invulnerableUntil=0
 c:projectileHit(wires[1],b,b.root.Position,V.zAxis)
 assert(b.reaction=="Bound" and math.abs(b.reactionUntil-c.now-.7)<.02,"the wired blade did not bind for 0.7 s")
 until_(c,.6,function() return a.state=="Neutral" or a.state=="TechniqueRecovery" end,"Sasuke still casting")
 local health=b.health
 assert(c:request(a,"Technique1"),"no Dragon Flame on the wired body")
 until_(c,.5,function() return b.health<health end,"the Dragon Flame never landed")
 assert(#flames({"ShurikenFan"})==0,"the base hidden blades carry wire")
end)

test("Sasuke · Blood for Chakra (awakening): the Curse Mark pays a missing Chidori with health",function()
 local function chidori(nodes)
  local c,a=duelWith("Lion","Mirage",nodes,nil,10)
  a.awakenUntil=c.now+12;a.awakened=true;a.chakra=5
  local health=a.health
  return c:request(a,"Technique4"),health-a.health,a
 end
 local ok,paid,a=chidori({"CurseControl","CurseBlood"})
 assert(ok and math.abs(paid-29)<.01 and a.chakra<1,"the Chidori was not paid with health ("..tostring(paid)..")")
 assert(not chidori({"CurseControl"}),"the base Curse Mark cast without chakra")
end)

test("Sasuke · Counter-Rush: right after a substitution E is a free chakra dash",function()
 local function rush(nodes)
  local c,a,b=duelWith("Lion","Flashstep",nodes)
  assert(c:damage(b,a,5,false,false))
  assert(c:request(a,"Substitute"))
  H.step(c,.16)
  a.chakra=0
  return c:request(a,"Pursuit"),a
 end
 local ok,a=rush({"DancingLeaf","CounterRush"})
 assert(ok and a.state=="Rush" and a.chakra<1,"no free counter-rush")
 assert(not rush({"DancingLeaf"}),"the base substitution gave a free dash")
end)

test("Sasuke · Wall Chidori: charged from a wall run it hangs on the wall and charges in 0.3 s",function()
 local function wall(nodes)
  local c,a,b=duelWith("Lion","Mirage",nodes,nil,12)
  local part=H.addWall(6)
  c:relocate(a,V.new(4.3,8,4));a.airborne=true
  a.wall={part=part,normal=-V.xAxis,untilTime=c.now+2}
  assert(c:request(a,"Technique4",b.root.Position),"Chidori refused on the wall")
  return a.untilTime-c.now,a,c
 end
 local charge,a,c=wall({"ChidoriFocus","WallChidori"})
 assert(math.abs(charge-.3)<.01 and a.wall==nil and a.airHold>c.now,"not a wall charge ("..string.format("%.2f",charge)..")")
 until_(c,.5,function() return a.attackName=="ChidoriThrust" end,"the thrust never left the wall")
 local baseCharge=wall({"ChidoriFocus"})
 assert(baseCharge>.45,"the base Chidori charged fast on a wall")
end)

test("Sasuke · Shuriken Fan: three shuriken in the air instead of two",function()
 local function air(nodes)
  local c,a,b=duelWith("Lion","Mirage",nodes,nil,12)
  c:relocate(a,a.root.Position+V.new(0,6,0));a.airborne=true;a.airHold=c.now+1
  assert(c:request(a,"Tool",b.root.Position))
  local seen,count={},0
  for _=1,50 do H.step(c,.01);for _,p in c.projectiles do if p.a==a and not seen[p] then seen[p]=true;count+=1 end end end
  return count
 end
 assert(air({"ShurikenFan"})==3 and air({})==2,"the air fan did not change from two to three")
end)

test("property and stat nodes are read by the live pipeline (cost, cooldown, channel, health, regen)",function()
 -- Read costs 12 instead of 14.
 local c,a=duelWith("Mirage","Flashstep",{"EconomicRead"})
 local chakra=a.chakra
 assert(c:request(a,"Technique1"));assert(math.abs(chakra-a.chakra-12)<.01,"Read cost "..(chakra-a.chakra))
 -- Rotation back after 5.22 s instead of 6.
 local c2,x=duelWith("GentleFist","Flashstep",{"SwiftRotation"})
 assert(c2:request(x,"Technique1"));assert(math.abs(x.cooldowns.Rotation-c2.now-5.22)<.01,"Rotation cooldown")
 -- Chidori charge 0.508 s instead of 0.62.
 local c3,s=duelWith("Lion","Mirage",{"ChidoriFocus"},nil,10)
 assert(c3:request(s,"Technique4"));assert(math.abs(s.untilTime-c3.now-.5084)<.01,"Chidori channel")
 -- Health and reserve on the actor and its humanoid; recovery per second.
 local c4,n=duelWith("GentleFist","Flashstep",{"Conditioning","ChakraReserve","ChakraControl"})
 assert(n.health==141 and n.hum.MaxHealth==141 and n.chakra==121,"stats not applied to the actor")
 n.chakra=50;H.step(c4,1)
 assert(math.abs(n.chakra-50-8.2)<.15,"regen "..(n.chakra-50))
end)

-- Presets: ranked example builds and AI budget builds ---------------------------
local BuildPresets=H.load("Server/BuildPresets")
local function everything(id)
 local unlocked={}
 for _,node in SkillTrees[id].Nodes do unlocked[node.Id]=true end
 return unlocked
end
-- Every leaf where the kit differs from the base kit must sit under a path an
-- active node declares: nothing else (no hidden stat) may change.
local function undeclaredChanges(id,kitValue)
 local declared={}
 for _,nodeId in kitValue.nodes do
  for _,effect in SkillBuilds.node(id,nodeId).Effects do
   local path=effect[1]
   local tech,field=string.match(path,"^tech%.([%w]+)%.(.+)$")
   if tech then
    for slot,spec in H.fighters[id].Techniques do if spec.Id==tech then path="def.Techniques."..slot.."."..field end end
   end
   table.insert(declared,path)
  end
 end
 local bad={}
 local function walk(x,y,path)
  if type(x)=="table" and type(y)=="table" then
   local keys={}
   for k in x do keys[k]=true end
   for k in y do keys[k]=true end
   for k in keys do walk(x[k],y[k],path.."."..tostring(k)) end
  elseif x~=y then
   local ok=false
   -- Under a declared path, or an optional table a declared path created.
   for _,prefix in declared do if string.sub(path,1,#prefix)==prefix or string.sub(prefix,1,#path+1)==path.."." then ok=true end end
   if not ok then table.insert(bad,path) end
  end
 end
 walk(kitValue.def,H.fighters[id],"def")
 walk(kitValue.graph,MoveGraphs[id],"graph")
 return bad
end

test("ranked example builds: one per bracket per fighter, admitted within the budget",function()
 for _,id in CORE4 do
  for _,bracket in SkillBuilds.Brackets do
   local nodes=BuildPresets.ranked(id,bracket.Id)
   assert(nodes,id.." has no "..bracket.Id.." example")
   local result,reason=SkillBuilds.admit(bracket.Id,id,nodes,everything(id),{allowClosed=true})
   assert(result,id.." "..bracket.Id..": "..tostring(reason))
   local floor=if bracket.Id=="Endgame" then 120 else bracket.Budget*.95
   assert(result.spent<=bracket.Budget and result.spent>=floor,id.." "..bracket.Id.." spends "..result.spent)
   local bad=undeclaredChanges(id,result)
   assert(#bad==0,id.." "..bracket.Id.." undeclared change: "..table.concat(bad,", "))
  end
 end
end)

test("AI budget builds: every tier valid, inside its SP range, cumulative, and nothing but tree nodes",function()
 for _,id in CORE4 do
  local previous=nil
  local playable=SkillBuilds.maxCost(id,true)
  for _,tier in BuildPresets.AITiers do
   local nodes=BuildPresets.ai(id,tier.Id)
   assert(nodes,id.." has no "..tier.Id.." preset")
   local result,reason=SkillBuilds.build(id,nodes)
   assert(result,id.." "..tier.Id..": "..tostring(reason))
   if tier.NearMax then assert(result.spent>=playable-tier.NearMax,id.." legendary spends "..result.spent.." of "..playable)
   else assert(result.spent>=tier.Min and result.spent<=tier.Max,id.." "..tier.Id.." spends "..result.spent) end
   -- No stat cheating: only what the chosen nodes declare differs from the base kit.
   local bad=undeclaredChanges(id,result)
   assert(#bad==0,id.." "..tier.Id.." changes "..table.concat(bad,", "))
   if previous then
    local set={}
    for _,n in result.nodes do set[n]=true end
    for _,n in previous do assert(set[n],id.." "..tier.Id.." drops "..n.." from the tier below") end
   end
   previous=result.nodes
  end
 end
 assert(BuildPresets.ai("Flashstep","Nope")==nil and BuildPresets.ai("Sand","Hard")==nil)
end)

test("AI with budget builds: legendary and hard presets fight without wedging",function()
 local hits=0
 for _,pair in {{"Flashstep","Mirage"},{"GentleFist","Lion"},{"Lion","Flashstep"},{"Mirage","GentleFist"}} do
  for _,tiers in {{"Legendary","Legendary"},{"Hard","Beginner"}} do
   local c,a,b,match=H.duel(pair[1],pair[2],{A=kit(pair[1],BuildPresets.ai(pair[1],tiers[1])),B=kit(pair[2],BuildPresets.ai(pair[2],tiers[2]))})
   place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
   a.locked=true;b.locked=true
   local one,two=AI.new(c,a,7),AI.new(c,b,11)
   local stuck={}
   for _=1,1500 do
    if match.phase~="Duel" then break end
    one:update(c.now);two:update(c.now)
    H.step(c,.01)
    for _,x in {a,b} do
     if x.state=="Neutral" then stuck[x]=0 else stuck[x]=(stuck[x] or 0)+.01 end
     assert(stuck[x]<4,pair[1].." vs "..pair[2].." ("..tiers[1].."/"..tiers[2].."): "..x.fighterId.." wedged in "..x.state)
    end
   end
   hits+=((a.events or {}).Damage or 0)+((b.events or {}).Damage or 0)
  end
 end
 assert(hits>0,"the budget AIs never exchanged a hit")
end)

H.workspace.GetServerTimeNow=function() return 100 end
local Matches=H.load("Server/Matches")
local World=H.load("Server/World")
test("match start: optional builds validated on the server; no option keeps today's fighters",function()
 local arena,rig=World.arena,World.rig
 World.arena=function() end
 World.rig=H.buildRig
 local ok,err=pcall(function()
  local folder=H.fakePart()
  local matches=setmetatable({remote={FireClient=function() end},folder=folder,sessions={},nextLane=0,epoch=0},Matches)
  local player={UserId=7}
  assert(matches:start(player,"Lion","Mirage",false),"plain start refused")
  local s=matches.sessions[player]
  assert(s.human.def==H.fighters.Lion and s.bot.def==H.fighters.Mirage and s.human.build==nil and s.bot.graph==nil,"a plain start carried a build")
  -- AI budget build.
  assert(matches:start(player,"Lion","Mirage",false,{bot={preset="Hard"}}),"AI preset refused")
  s=matches.sessions[player]
  assert(s.bot.build and s.bot.build.spent==69 and s.bot.def.Techniques[1].Active>1,"the bot did not get the Hard build")
  assert(s.human.build==nil,"the player got a build he did not ask for")
  -- Ranked: the player's build must fit the bracket and be unlocked.
  local identity=BuildPresets.ranked("Lion","Identity")
  local refused,reason=matches:start(player,"Lion","Mirage",false,{bracket="Fundamentals",player={nodes=identity,unlocked=everything("Lion")}})
  assert(not refused and string.find(reason,"budget is 50",1,true),"an 80 SP build entered the 50 SP bracket ("..tostring(reason)..")")
  refused,reason=matches:start(player,"Lion","Mirage",false,{player={nodes={"DancingLeaf"},unlocked={}}})
  assert(not refused and string.find(reason,"locked",1,true),"a locked node was activated")
  assert(not matches:start(player,"Lion","Mirage",false,{bot={preset="Impossible"}}),"unknown preset accepted")
  assert(not matches:start(player,"Lion","Mirage",false,{bracket="Identity",bot={preset="Boss"}}),"an 88 SP AI entered the 80 SP bracket")
  assert(matches.sessions[player].bot.build.spent==69,"a refused start replaced the running duel")
  assert(matches:start(player,"Lion","Mirage",false,{bracket="Identity",player={nodes=identity,unlocked=everything("Lion")},bot={preset="Hard"}}),"a valid ranked start refused")
  s=matches.sessions[player]
  assert(s.human.build.spent==80 and s.human.build.bracket=="Identity","the ranked build was not applied")
  -- A rematch keeps the same builds.
  s.phase="Result"
  matches:request(player,{action="Rematch",epoch=s.epoch})
  s=matches.sessions[player]
  assert(s.phase=="Duel" and s.human.build and s.human.build.spent==80 and s.bot.build.spent==69,"the rematch dropped the builds")
 end)
 World.arena,World.rig=arena,rig
 assert(ok,err)
end)

print("NinjaDuel progression: "..passed.." PASS (headless: tree data, validation and combat hooks; Studio feel not judged)")
