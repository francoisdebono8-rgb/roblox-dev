-- The locked ten of the roster (DEC-022): each one's own mechanics, checked
-- headless beyond the Tier A floor (Roster.spec), and the generic family
-- fields they introduced (Families: Poison, PullTo, Teleport InZone/Heal,
-- Burst Leave, Buff OnHit; ToolMastery Projectile/Contact; Attacks riders).
-- Feel and looks stay Studio checks.
local H=require("./Harness")
local V=H.V
local Roster=H.load("Shared/Roster")
local Fighters=H.fighters
local MoveGraphs=H.load("Shared/MoveGraphs")
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
local function press(c,a,action,stick,aim)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim)
 a.move=V.zero
 return ok,reason
end
local function run(c,seconds,each)
 for _=1,math.ceil(seconds/.01) do H.step(c,.01);if each then each() end end
end
local function slot(id,tech)
 for i,spec in Fighters[id].Techniques do if spec.Id==tech then return "Technique"..i,spec end end
 error(id.." has no "..tech)
end
local NEW={"Mirror","Mist","Bone","Flicker","Serpent","Medic","Clay","Puppet","Rinnegan","Ink"}
local listed={}
for _,id in Roster do listed[id]=true end
local function each(fn) for _,id in NEW do if listed[id] then fn(id) end end end

test("direction + light before the first confirmed hit is the plain opener, never a route",function()
 each(function(id)
  for _,dir in {"forward","back","side"} do
   local c,a,b=H.duel(id,"Leaf");place(c,a,b,3.4);b.health=999
   local stick=if dir=="forward" then flat(b.root.Position-a.root.Position).Unit elseif dir=="back" then flat(a.root.Position-b.root.Position).Unit else a.root.CFrame.RightVector
   assert(press(c,a,"Attack",stick),id..": opener refused")
   assert(a.attackName=="Light1" or a.attackName=="DashAttack",id..": "..dir.." + light from neutral gave "..tostring(a.attackName))
   local routes=MoveGraphs[id].routes
   for _,r in routes do assert(a.attackName~=r or r=="Light1",id..": a route opened before any hit") end
  end
 end)
end)

test("Haku: senbon that slow, a mirror step that strikes harder inside his dome",function()
 if not listed.Mirror then return end
 local c,a,b=H.duel("Mirror","Leaf");place(c,a,b,12);b.health=999
 assert(press(c,a,"Tool",nil,b.root.Position))
 local slowed=false
 -- (The headless world has no ray hits on bodies: the needles get a body's width.)
 run(c,.8,function()
  for _,p in c.projectiles do if p.a==a then assert(p.kind=="senbon","Haku threw "..p.kind);p.radius=1 end end
  if (b.slowUntil or 0)>c.now then slowed=true end
 end)
 assert(slowed,"Haku's senbon did not slow")
 -- Mirror step outside then inside the dome: the arrival strike is harder inside.
 local function stepDamage(inside)
  local c2,a2,b2=H.duel("Mirror","Leaf");place(c2,a2,b2,14);b2.health=999;a2.chakra=999
  if inside then
   local s=slot("Mirror","IceMirrors")
   assert(press(c2,a2,s,nil,b2.root.Position));run(c2,1.4)
   a2.cooldowns={}
  end
  local before=b2.health
  local s=slot("Mirror","MirrorStep")
  assert(press(c2,a2,s,nil,b2.root.Position))
  local most=0
  run(c2,.8,function() most=math.max(most,before-b2.health) end)
  return most
 end
 local out,inn=stepDamage(false),stepDamage(true)
 assert(out>0,"the mirror step did not land")
 assert(inn>out*1.3,string.format("inside the dome %.1f vs outside %.1f",inn,out))
end)

test("Zabuza: the Silent Killing out of his mist is far harder; the Water Prison holds",function()
 if not listed.Mist then return end
 local function kill(mist)
  local c,a,b=H.duel("Mist","Leaf");place(c,a,b,10);b.health=999;a.chakra=999
  if mist then assert(press(c,a,slot("Mist","HiddenMist")));run(c,1.2);a.cooldowns={} end
  local before=b.health
  assert(press(c,a,slot("Mist","SilentKilling"),nil,b.root.Position))
  local behind=false
  run(c,.9,function()
   local look=flat(b.root.CFrame.LookVector)
   if look.Magnitude>0 and look.Unit:Dot(flat(a.root.Position-b.root.Position).Unit)<-.2 then behind=true end
  end)
  return before-b.health,behind
 end
 local plain,behind=kill(false)
 local misted=kill(true)
 assert(behind,"Zabuza did not reach the back")
 assert(plain>0 and misted>plain*1.4,string.format("mist %.1f vs plain %.1f",misted,plain))
end)

test("Kimimaro: bone armour, finger bullets, the Larch leaves the floor spiked",function()
 if not listed.Bone then return end
 local c,a,b=H.duel("Leaf","Bone");place(c,a,b,3.4);b.health=999
 local c2,a2,b2=H.duel("Leaf","Leaf");place(c2,a2,b2,3.4);b2.health=999
 assert(press(c,a,"Attack"));assert(press(c2,a2,"Attack"))
 run(c,.4);run(c2,.4)
 assert(999-b.health<999-b2.health,"Kimimaro's bones took nothing off the blow")
 local c3,a3,b3=H.duel("Bone","Leaf");place(c3,a3,b3,12)
 assert(press(c3,a3,"Tool",nil,b3.root.Position))
 local bone=false
 run(c3,.2,function() for _,p in c3.projectiles do if p.kind=="bone" then bone=true end end end)
 assert(bone,"his tool is not a bone bullet")
 local c4,a4,b4=H.duel("Bone","Leaf");place(c4,a4,b4,4);a4.chakra=999
 assert(press(c4,a4,slot("Bone","Larch")));run(c4,.5)
 local spiked=false
 for _,h in c4.hazards do if h.a==a4 and h.look=="bones" then spiked=true end end
 assert(spiked,"the Larch left no spikes")
end)

print(string.format("NinjaDuel roster 20 (locked ten): %d PASS (headless mechanics; feel and looks are Studio checks)",passed))
