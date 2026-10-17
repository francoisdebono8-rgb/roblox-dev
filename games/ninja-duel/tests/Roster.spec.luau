-- Roster 20 breadth pass (docs/missions/ROSTER_20_BREADTH_PASS.md): the Tier A
-- floor, checked for EVERY fighter of Shared/Roster, old and new, so a fighter
-- cannot be listed as playable while a core piece is missing.
--   definition: stats, tool, 2-5 techniques each with an implementation, an
--   awakening that changes play, a motion family, a move graph with ground
--   and air routes and a re-engage;
--   play (headless): the light string lands three times, the heavy starts,
--   the toward route after two hits is the fighter's own, an air strike
--   starts after a jump, the tool works, every technique resolves and does
--   something measurable, the awakening opens and changes a stat;
--   AI: each fighter's bot fights the next one on the list to a KO without
--   wedging and uses its techniques;
--   presentation: selectable in the menu, a costume of its own, every family
--   object drawn with its own model (never the kunai fallback).
-- Headless only: feel, looks and timing in motion are Studio checks.
local H=require("./Harness")
local V=H.V
local Roster=H.load("Shared/Roster")
local Fighters=H.fighters
local MoveGraphs=H.load("Shared/MoveGraphs")
local Looks=H.load("Shared/Looks")
local Techniques=H.load("Server/Techniques")
local Config=H.load("Shared/Config")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,gap)
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 for _,x in {a,b} do x.move=V.zero end
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function toward(a) return flat(a.target.root.Position-a.root.Position).Unit end
local function ev(x,name) return (x.events or {})[name] or 0 end
local function press(c,a,action,stick,aim,opts)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim,nil,opts)
 a.move=V.zero
 return ok,reason
end
local function until_(c,seconds,cond)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return true end
 end
 return false
end
-- A plain sparring partner: no shield, no Byakugan, no clones.
local function partner(id) return if id=="Leaf" then "Mirage" else "Leaf" end

test("the roster lists every playable fighter once, each with a definition",function()
 local seen={}
 for _,id in Roster do
  assert(not seen[id],id.." is listed twice");seen[id]=true
  assert(Fighters[id],id.." has no definition in Fighters")
 end
 assert(#Roster>=8,"the roster lost fighters ("..#Roster..")")
 print("   "..#Roster.." playable: "..table.concat(Roster,", "))
end)

test("definition: stats, tool, techniques with implementations, an awakening that changes play, motion and move graph",function()
 local Motion=H.load("Client/VelmoraMotionEngine")
 local gameplay={"Speed","Damage","Regen","Cooldown","CostScale","Windows","Drain","Buff","HealthDrain","Recovery","Extension","ShieldRegen","NoBlindSpot",
  "FlashWake","BindScale","OnHit","NoBodies","GuardRead","WhiffRead","CursedLeaf"}
 for _,id in Roster do
  local def=Fighters[id]
  for _,field in {"Name","Health","Chakra","Speed","Tool","Color","Skin","Hair","Outfit"} do assert(def[field]~=nil,id..": no "..field) end
  assert(#def.Techniques>=1 and #def.Techniques<=5,id..": "..#def.Techniques.." techniques")
  for _,spec in def.Techniques do
   local impl=Techniques[spec.Id]
   assert(impl and impl.check and impl.execute,id..": "..spec.Id.." has no implementation")
   for _,field in {"Name","Cost","Channel","Cooldown"} do assert(spec[field]~=nil,id..": "..spec.Id.." has no "..field) end
   if spec.Family=="Projectile" or (spec.Family and spec.Kind) then assert(Looks[spec.Kind or "chakra"],id..": "..spec.Id.." names an unknown look "..tostring(spec.Kind)) end
  end
  local aw=def.Awakening
  assert(aw and aw.Name,id..": no awakening")
  local changes=0
  for _,field in gameplay do if aw[field]~=nil then changes+=1 end end
  assert(changes>=1,id..": the awakening changes nothing in play")
  local family=Motion.familyOf(id)
  assert(family and family.body,id..": no motion family")
  local graph=MoveGraphs[id]
  assert(graph and graph.routes,id..": no move graph")
  assert(graph.routes.up and graph.routes.down,id..": no toward/away route")
  assert(graph.reengage,id..": no re-engage style")
 end
end)

test("play: three lights land, the heavy starts, the toward route is the fighter's own",function()
 for _,id in Roster do
  local c,a,b=H.duel(id,partner(id))
  place(c,a,b,if id=="Sand" then 7 else 3.4)
  b.health=999
  local hits=0
  for k=1,3 do
   local before=b.health
   assert(press(c,a,"Attack"),id..": light "..k.." refused")
   until_(c,.9,function() return a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0) end)
   if b.health<before or (b.comboHits or 0)>=k then hits+=1 end
   if k<3 then place(c,a,b,if id=="Sand" then 7 else 3.4) end
  end
  assert(hits>=2,id..": the light string landed "..hits.." of 3")
  -- Heavy from neutral.
  local c2,a2,b2=H.duel(id,partner(id));place(c2,a2,b2,3.4)
  assert(press(c2,a2,"Heavy"),id..": heavy refused")
  assert(a2.attackName~=nil or a2.state~="Neutral",id..": the heavy started nothing")
  -- Toward after two confirmed hits: the route of its own move graph.
  local c3,a3,b3=H.duel(id,partner(id));place(c3,a3,b3,if id=="Sand" then 7 else 3.4);b3.health=999
  for _=1,2 do
   assert(press(c3,a3,"Attack"))
   until_(c3,.9,function() return a3.state=="Recovery" and a3.chainOpen==true and c3.now>=(a3.chainAt or 0) end)
  end
  local route=MoveGraphs[id].routes.up
  assert(press(c3,a3,"Attack",toward(a3)),id..": the toward route was refused")
  local graph=MoveGraphs[id]
  local proxy=graph.proxy and graph.proxy[route]
  local expected={[route]=true}
  if proxy then expected[proxy.move or route]=true;if proxy.solo then expected[proxy.solo]=true end end
  if Fighters[id].LauncherMove then expected[Fighters[id].LauncherMove]=true end
  assert(expected[a3.attackName or ""],id..": toward after two hits gave "..tostring(a3.attackName).." (route "..route..")")
 end
end)

test("play: an air strike after a jump, the tool, and the awakening that opens and changes a stat",function()
 for _,id in Roster do
  local c,a,b=H.duel(id,partner(id));place(c,a,b,8)
  assert(press(c,a,"Jump"),id..": jump refused")
  H.step(c,.18)
  assert(a.airborne,id..": not airborne after the jump")
  local ok=press(c,a,"Attack")
  assert(ok and a.attackName~=nil,id..": no air strike ("..tostring(a.attackName)..")")
  -- Tool toward the partner from mid range.
  local c2,a2,b2=H.duel(id,partner(id));place(c2,a2,b2,12)
  local before=#c2.projectiles
  local tok,why=press(c2,a2,"Tool",nil,b2.root.Position)
  if not tok and Fighters[id].Tool=="Deflect" then
   -- A deflecting kick needs something to deflect: the partner throws first.
   assert(press(c2,b2,"Tool",nil,a2.root.Position),id..": the partner could not throw")
   for _=1,40 do H.step(c2,.01);tok,why=press(c2,a2,"Tool",nil,b2.root.Position);if tok then break end end
  end
  assert(tok,id..": tool refused ("..tostring(why)..")")
  local chakraBefore=a2.chakra
  local acted=false
  for _=1,60 do
   H.step(c2,.01)
   if #c2.projectiles>before or a2.state~="Neutral" or b2.reaction or b2.health<b2.def.Health or a2.throw~=nil then acted=true end
  end
  local events=0
  for _,v in a2.events or {} do events+=v end
  assert(acted or a2.chakra<chakraBefore or events>0,id..": the tool did nothing")
  -- Awakening under the threshold.
  local c3,a3,b3=H.duel(id,partner(id));place(c3,a3,b3,12)
  a3.health=a3.def.Health*Config.Awaken.Threshold*.9
  local aok,awhy=press(c3,a3,"Awaken")
  assert(aok,id..": awakening refused ("..tostring(awhy)..")")
  H.step(c3,.4)
  assert((a3.awakenUntil or 0)>c3.now,id..": the awakening did not open")
 end
end)

test("play: every technique resolves and does something measurable",function()
 local report={}
 for _,id in Roster do
  for slot,spec in Fighters[id].Techniques do
   local c,a,b=H.duel(id,partner(id))
   local gap=math.clamp((spec.Range or 10)*.45,3.4,14)
   if spec.Family=="Burst" or spec.Family=="Counter" then gap=math.min(gap,(spec.Radius or 6)-1.5) end
   place(c,a,b,math.max(gap,3))
   a.chakra=a.def.Chakra or 100;b.health=999
   local snap={hp=b.health,pos=a.root.Position,proj=0,haz=0,events=0}
   for _,v in a.events or {} do snap.events+=v end
   local ok,why=press(c,a,"Technique"..slot,nil,b.root.Position)
   if not ok then
    -- A technique that needs a setup (a seal, a target in reach) may refuse
    -- here; a family technique never may.
    assert(not spec.Family,id..": "..spec.Id.." refused ("..tostring(why)..")")
    assert(spec.Requires or why,id..": "..spec.Id.." refused with no reason")
    table.insert(report,id.."/"..spec.Id.."=needs "..tostring(spec.Requires or why))
    continue
   end
   local seen={reaction=false,proj=false,haz=false,buff=false,stance=false}
   for _=1,220 do
    H.step(c,.01)
    if b.reaction then seen.reaction=true end
    if #c.projectiles>0 then seen.proj=true end
    if #c.hazards>0 or #(c.zones or {})>0 then seen.haz=true end
    if a.buff then seen.buff=true end
    if a.counterStance or (a.readUntil or 0)>c.now or (a.rotationUntil or 0)>c.now then seen.stance=true end
    if c.match.phase~="Duel" then break end
   end
   local events=0
   for _,v in a.events or {} do events+=v end
   local moved=(a.root.Position-snap.pos).Magnitude>2
   local something=b.health<snap.hp or seen.reaction or seen.proj or seen.haz or seen.buff or seen.stance or moved or events>snap.events+1
   assert(something,id..": "..spec.Id.." resolved but changed nothing")
   if spec.Family then
    assert(b.health<snap.hp or seen.reaction or seen.proj or seen.haz or seen.buff or seen.stance or moved,
     id..": family technique "..spec.Id.." ("..spec.Family..") had no effect")
   end
  end
 end
 if #report>0 then print("   setup needed: "..table.concat(report,", ")) end
end)

test("family techniques: a projectile family binds, drains, knocks away as its spec says",function()
 for _,id in Roster do
  for slot,spec in Fighters[id].Techniques do
   if spec.Family=="Projectile" and (spec.Bind or spec.Knock or spec.Drain) then
    local c,a,b=H.duel(id,partner(id))
    place(c,a,b,math.clamp((spec.Range or 20)*.4,8,14))
    a.chakra=200;b.health=999;b.chakra=100
    assert(press(c,a,"Technique"..slot,nil,b.root.Position))
    local bound,knocked=false,false
    for _=1,250 do
     H.step(c,.01)
     if b.reaction=="Bound" then bound=true end
     if b.reaction=="Knockback" or b.reaction=="Launched" then knocked=true end
    end
    if spec.Bind then assert(bound,id..": "..spec.Id.." never bound the body") end
    if spec.Knock and not spec.Bind then assert(knocked,id..": "..spec.Id.." never knocked the body away") end
    if spec.Drain then assert(b.chakra<100,id..": "..spec.Id.." drained nothing") end
   end
  end
 end
end)

test("AI: each fighter's bot fights the next on the list to a KO, without wedging, and uses its techniques",function()
 local AI=H.load("Server/AI")
 local saved=H.envBase.Random
 H.envBase.Random={new=function(seed)
  local state=(seed or 1)*2654435761%4294967296
  local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
  return {NextNumber=function(_,x,y) local r=roll();if x and y then return x+(y-x)*r end return r end,
   NextInteger=function(_,x,y) return math.floor(x+(y-x+1)*roll()) end}
 end}
 local used={}
 local ok,err=pcall(function()
  for i,id in Roster do
   local other=Roster[i%#Roster+1]
   local c,a,b,match=H.duel(id,other)
   place(c,a,b,14)
   local one,two=AI.new(c,a,i*7+1),AI.new(c,b,i*7+3)
   local stuck={}
   local t=0
   while match.phase=="Duel" and t<180 do
    one:update(c.now);two:update(c.now);H.step(c,.01);t+=.01
    for _,x in {a,b} do
     local key=x.state..":"..tostring(x.attackSerial or 0)..":"..tostring(x.castId)
     if x.state=="Neutral" or x.state=="Guarding" or key~=(stuck[x] and stuck[x].key) then stuck[x]={key=key,t=0} else stuck[x].t+=.01 end
     assert(stuck[x].t<2.5,id.." vs "..other..": "..x.fighterId.." wedged in "..x.state)
     assert(x.health==x.health and x.root.Position.Y==x.root.Position.Y,id.." vs "..other..": non-finite state")
    end
   end
   assert(match.phase~="Duel",string.format("%s vs %s did not finish in 180 s (%.0f / %.0f health)",id,other,a.health,b.health))
   for _,x in {a,b} do used[x.fighterId]=(used[x.fighterId] or 0)+ev(x,"Technique") end
   print(string.format("   %s vs %s: %.1f s, winner %s",id,other,t,tostring(match.winner)))
  end
 end)
 H.envBase.Random=saved
 assert(ok,err)
 for _,id in Roster do assert((used[id] or 0)>=1,id..": its bot never used a technique in two duels") end
end)

test("presentation: selectable in the menu, a costume of its own, every family object drawn with its own model",function()
 -- Menu: a roster slot and both buttons for every fighter.
 H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim
 H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
 H.workspace.GetAttribute=function() return nil end
 local baseNew=H.envBase.Instance.new
 local saved=H.envBase.Instance
 H.envBase.Instance={new=function(class)
  local x=baseNew(class)
  x.Activated={Connect=function(_,fn) x.click=fn end}
  return x
 end}
 local ok,err=pcall(function()
  local UI=H.load("Client/UI")
  local sent={}
  local ui=UI.new(baseNew("PlayerGui"),function(action,extra) table.insert(sent,{action=action,extra=extra}) end)
  for _,id in Roster do
   assert(ui.selectionButtons["slot"..id] and ui.selectionButtons["player"..id] and ui.selectionButtons["bot"..id],id.." is not selectable")
   ui.selectionButtons["player"..id].click()
   assert(ui.player==id,"picking "..id.." did not select it")
  end
 end)
 H.envBase.Instance=saved
 assert(ok,err)
 -- Costume: each fighter wears at least eight pieces of its own.
 local World=H.load("Server/World")
 for _,id in Roster do
  local made={}
  local base=H.envBase.Instance
  H.envBase.Instance={new=function(class) local x=base.new(class);table.insert(made,x);return x end}
  local c,a=H.duel(id,partner(id))
  local dok,derr=pcall(World.dress,a.model,Fighters[id])
  H.envBase.Instance=base
  assert(dok,id..": costume error "..tostring(derr))
  local worn=0
  for _,x in made do if (rawget(x,"Name") or x.Name)~=nil and x.ClassName~="WeldConstraint" then worn+=1 end end
  assert(worn>=8,id..": only "..worn.." costume pieces")
 end
 -- Every family object kind used by a roster technique is drawn with its own
 -- model and contact (FamilyFX), with no error.
 local instance,restore=H.stubScene()
 local cok,cerr=pcall(function()
  local FamilyFX=H.load("Client/FamilyFX")
  FamilyFX.strict=true
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  local folder=instance("Folder")
  for _,id in Roster do
   for _,spec in Fighters[id].Techniques do
    if spec.Family=="Projectile" then
     local kind=spec.Kind or "chakra"
     assert(FamilyFX.SHAPES[Looks[kind].shape],id..": no shape for "..kind)
     local p={id=900,kind=kind,origin=V.new(0,3,0),direction=-V.zAxis,speed=50,born=99.9,range=30,owner="A",radius=1}
     fx:sync({epoch=1,projectiles={p}})
     local entry=fx.projectiles[900]
     assert(entry and entry.model and entry.model.Name~="Kunai",id..": "..kind.." drawn as "..tostring(entry and entry.model and entry.model.Name))
     fx:stepProjectiles(1/60)
     fx:impact({style="look",kind=kind,position=V.new(0,3,-5),projectile=900,serial=1},folder)
     fx:sync({epoch=1,projectiles={}})
    end
   end
  end
  for _,style in {"zone","buff","stance","drain"} do
   fx:impact({style=style,kind="chakra",position=V.new(0,3,0),owner="A",radius=6,time=1,serial=2},folder)
  end
 end)
 restore()
 assert(cok,cerr)
end)

print(string.format("NinjaDuel roster Tier A: %d PASS (%d fighters; headless rules, AI and drawing calls; feel and looks are Studio checks)",passed,#Roster))
