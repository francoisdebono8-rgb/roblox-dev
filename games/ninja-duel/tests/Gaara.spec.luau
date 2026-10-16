-- Fourth prototype: Gaara of the Sand. Automatic sand shield, long sand
-- lashes, the Sand Pillar heavy, the sand body-flicker, Sand Coffin,
-- Sand Shuriken, Desert Wave, the sand bullet and AI duels.
local H=require("./Harness")
local V=H.V
local AI=H.load("Server/AI")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
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

test("sand shield: stops a strike by itself, a charge at a time, and comes back",function()
 local c,a,b=H.duel("Flashstep","Sand")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(b.shieldCharges==3,"shield not charged at the start")
 assert(c:request(a,"Attack"))
 until_(c,.5,function() return ((b.events or {}).SandShield or 0)>0 end,"the shield never answered")
 assert(b.health==b.def.Health,"a strike went through a charged shield")
 assert(b.shieldCharges==2,"a light strike did not cost exactly one charge ("..b.shieldCharges..")")
 until_(c,b.def.SandShield.Regen+.5,function() return b.shieldCharges==3 end,"the charge never came back")
end)

test("sand shield: a heavy blow breaks it outright and opens him",function()
 local c,a,b=H.duel("Flashstep","Sand")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Heavy"))
 until_(c,.8,function() return ((b.events or {}).SandShield or 0)>0 end,"the heavy never met the shield")
 assert(b.shieldCharges==0,"the heavy did not break the shield")
 assert(b.state=="Stunned","a broken shield did not open him ("..b.state..")")
 -- Empty: the next blow lands.
 b.state="Neutral";b.untilTime=c.now;a.state="Neutral";a.untilTime=c.now;a.pending=nil
 local health=b.health
 assert(c:damage(a,b,5,false,false),"a blow against an empty shield did not land")
 assert(b.health<health)
end)

test("sand shield: never while he attacks or recovers (the whiff is the opening)",function()
 local c,a,b=H.duel("Flashstep","Sand")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 b.state="Recovery";b.untilTime=c.now+1
 local health=b.health
 assert(c:damage(a,b,5,false,false),"a punish on his recovery was shielded")
 assert(b.health<health and b.shieldCharges==3)
end)

test("sand lashes reach where a fist does not",function()
 local c,a,b=H.duel("Sand","Flashstep")
 place(c,a,b,V.new(0,3,4),V.new(0,3,-4))
 assert(c:request(a,"Attack"))
 until_(c,.6,function() return b.health<b.def.Health end,"the lash never reached 8 studs")
 -- Minato's fist at the same distance does not.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,4.6),V.new(0,3,-4.6))
 x.def=table.clone(x.def);x.def.CombatTravel=0
 assert(c2:request(x,"Attack"))
 H.step(c2,.6)
 assert(y.health==y.def.Health,"a punch reached 9 studs")
end)

test("his heavy is the Sand Pillar: sand erupts under the opponent at range",function()
 local c,a,b=H.duel("Sand","Flashstep")
 place(c,a,b,V.new(0,3,5),V.new(0,3,-5))
 assert(c:request(a,"Heavy"))
 assert(a.attackName=="SandPillar","the heavy is "..tostring(a.attackName))
 until_(c,.8,function() return b.reaction=="Launched" end,"the pillar did not launch at 10 studs")
end)

test("sand body-flicker: the dodge is an instant reposition",function()
 local c,a,b=H.duel("Sand","Flashstep")
 place(c,a,b,V.new(0,3,4),V.new(0,3,-4))
 local from=a.root.Position
 local warp=a.warpSerial or 0
 a.move=V.new(1,0,0)
 assert(c:request(a,"Dodge"),"flicker refused")
 local moved=(a.root.Position-from).Magnitude
 assert(moved>8,"the flicker moved only "..string.format("%.1f",moved))
 assert(a.warpSerial==warp+1,"the flicker is not drawn as a warp")
 assert(a.invulnerableUntil>c.now)
end)

test("Sand Coffin binds, then buries; a substitution escapes the burial",function()
 local c,a,b=H.duel("Sand","Flashstep")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8))
 assert(c:request(a,"Technique1",b.root.Position),"Sand Coffin refused")
 until_(c,1.4,function() return b.reaction=="Bound" end,"the sand never bound him")
 local health=b.health
 until_(c,1.4,function() return b.health<health end,"the burial never came")
 assert(health-b.health>=12,"the burial was too light ("..(health-b.health)..")")
 H.step(c,.05)
 assert(b.reaction=="Knockdown","the burial did not knock down")
 -- Escape: substitute while bound.
 local c2,x,y=H.duel("Sand","Flashstep")
 place(c2,x,y,V.new(0,3,8),V.new(0,3,-8))
 assert(c2:request(x,"Technique1",y.root.Position))
 until_(c2,1.4,function() return y.reaction=="Bound" end,"the sand never bound him")
 local bound=y.health
 assert(c2:request(y,"Substitute"),"no substitution out of the coffin")
 H.step(c2,1.5)
 assert(bound-y.health<5,"the burial still landed after the substitution")
end)

test("Desert Wave swallows blades and throws a close attacker away",function()
 local c,a,b=H.duel("Sand","Mirage")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-3))
 c:projectile(b,a.root.Position,60,30,3,"shuriken")
 assert(c:request(a,"Technique3"),"Desert Wave refused")
 until_(c,.8,function() return b.reaction=="Knockback" end,"the close attacker was not thrown away")
 for _,p in c.projectiles do assert(p.a~=b,"a blade survived the wave") end
end)

test("the sand bullet: his tool is a fast sand projectile",function()
 local c,a,b=H.duel("Sand","Flashstep")
 place(c,a,b,V.new(0,3,10),V.new(0,3,-10))
 assert(c:request(a,"Tool",b.root.Position),"sand bullet refused")
 local seen=false
 until_(c,.6,function()
  for _,p in c.projectiles do if p.kind=="sand" then seen=true end end
  return seen
 end,"no sand projectile")
end)

test("AI duels: Gaara against every prodigy, both ways, without wedging",function()
 for _,pair in {{"Sand","Flashstep"},{"Flashstep","Sand"},{"Sand","Mirage"},{"Mirage","Sand"},{"Sand","GentleFist"},{"GentleFist","Sand"},{"Sand","Sand"}} do
  local c,a,b,match=H.duel(pair[1],pair[2])
  place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
  local one,two=AI.new(c,a,7),AI.new(c,b,11)
  local stuck={}
  local dealt={[a]=0,[b]=0}
  for _=1,1500 do
   if match.phase~="Duel" then break end
   local ha,hb=a.health,b.health
   one:update(c.now);two:update(c.now)
   H.step(c,.01)
   dealt[a]+=math.max(0,hb-b.health);dealt[b]+=math.max(0,ha-a.health)
   for _,x in {a,b} do
    if x.state=="Neutral" then stuck[x]=0 else stuck[x]=(stuck[x] or 0)+.01 end
    assert(stuck[x]<4,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
   end
  end
  print(string.format("  %s vs %s: dealt %.0f / %.0f",pair[1],pair[2],dealt[a],dealt[b]))
 end
end)

test("client: his sand is drawn as sand (flights, shield, flicker, coffin, Desert Wave, lashes, pillar, charges)",function()
 -- Before SandFX the sand bullet and Sand Coffin flew as kunai and none of
 -- his contacts (shield, flicker, burial, wall) drew anything.
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local Sand=H.load("Client/SandFX")
  local clock=50
  Sand.clock=function() return clock end
  local fx=FX.new()
  local folder=instance("Folder")
  local function body(id,at)
   local m=instance("Model");m.Name=id;m.Parent=folder
   for _,n in {"HumanoidRootPart","RightHand","LeftHand","UpperTorso"} do
    local p=instance("Part");p.Name=n;p.CFrame=H.C.lookAt(at,at-V.zAxis);p.Size=V.new(1,1,1);p.Transparency=0;p.Parent=m
   end
   return m
  end
  body("A",V.new(0,3,0));body("B",V.new(0,3,-8))
  local function named(name)
   local count=0
   for _,d in fx.folder:GetDescendants() do if d.Name==name then count+=1 end end
   return count
  end
  local data={phase="Duel",epoch=1,hazards={},projectiles={
    {id=1,kind="sand",origin=V.new(0,4,0),direction=-V.zAxis,speed=90,born=99,range=56,owner="A",radius=.6,growth=0},
    {id=2,kind="sandwave",origin=V.new(0,1,0),direction=-V.zAxis,speed=46,born=99,range=30,owner="A",radius=1.8,growth=.6}},
   human={id="A",fighterId="Sand",seals={},shield=3,shieldMax=3,state="Neutral",bound=false,health=140,maxHealth=140},
   bot={id="B",fighterId="Flashstep",seals={},state="Neutral",bound=true,reaction="Bound",health=125,maxHealth=125}}
  fx:sync(data)
  assert(fx.projectiles[1].model.Name=="SandBullet","the sand bullet flies as "..fx.projectiles[1].model.Name)
  assert(fx.projectiles[2].model.Name=="SandWave","the Sand Coffin wave flies as "..fx.projectiles[2].model.Name)
  for _=1,4 do fx:stepProjectiles(1/30) end
  -- Every sand contact is drawn by the sand layer, none falls through.
  for _,style in {"sandhit","sandburst","sandshield","sandflicker","sandburial","sandwall"} do
   for _,heavy in {false,true} do
    local before=#fx.folder:GetDescendants()
    fx:impact({style=style,position=V.new(0,3,-1.6),heavy=heavy,direction=-V.zAxis,to=V.new(10,3,0),owner="A",fighter="Sand",serial=1},folder)
    assert(#fx.folder:GetDescendants()>before,style.." drew nothing")
   end
  end
  -- A frame: the opponent held by sand gets the coffin (not the wire), Gaara
  -- his three shield charges.
  data.projectiles={}
  fx:update(data,1/60,folder)
  assert(named("SandCoffin")==1 and named("Binding")==0,"the sand bind is drawn as wire")
  assert(named("SandShieldCharges")==1,"no shield charges around him")
  -- A lash: out on the contact key, reaching the strike's range, gone after it.
  data.human.state="Startup";data.human.attackName="Light1";data.human.attackSerial=1;data.human.attackElapsed=0
  fx:update(data,1/60,folder)
  clock+=.16
  data.human.state="Active"
  fx:update(data,1/60,folder)
  local reach=0
  for _,d in fx.folder:GetDescendants() do
   if d.Name=="SandLash" then for _,ball in d:GetChildren() do reach=math.max(reach,(ball.Position-V.new(0,3,0)).Magnitude) end end
  end
  assert(reach>7,"the lash reached "..string.format("%.1f",reach).." studs")
  clock+=2;data.human.state="Neutral";data.human.attackName=nil
  fx:update(data,1/60,folder)
  assert(named("SandLash")==0,"the lash never went back")
  -- The Sand Pillar erupts under the opponent.
  data.human.state="Startup";data.human.attackName="SandPillar";data.human.attackSerial=2;data.human.attackElapsed=0
  fx:update(data,1/60,folder)
  assert(named("SandPillar")==0,"the pillar came before its contact")
  clock+=.3
  fx:update(data,1/60,folder)
  assert(named("SandPillar")==1,"no pillar")
  -- Released: the coffin crumbles.
  data.bot.bound=false;data.bot.reaction=nil
  fx:update(data,1/60,folder)
  assert(fx.sandState[folder:FindFirstChild("B")].coffin==nil,"the coffin outlived the bind")
 end)
 restore()
 assert(ok,err)
end)

print("NinjaDuel Gaara prototype: "..passed.." PASS")
