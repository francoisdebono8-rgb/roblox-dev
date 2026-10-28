-- ChakraFlow (Freedom, user 28/10 "la liberté, c'est les infusions de
-- chakra"): hold the modifier alone, the next action is infused, whatever it
-- is and wherever the body is.
local H=require("./Harness")
local V=H.V
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
local Flow=H.load("Server/ChakraFlow")

-- Damage a light does to a standing body, loaded or not.
local function lightDamage(id,loaded)
 local c,a,b=H.duel(id,"Flashstep")
 place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
 b.ai=nil
 if loaded then assert(c:request(a,"ChakraLoad"),id.." could not load") end
 local health=b.health
 assert(c:request(a,"Attack"),id.." light refused")
 for _=1,60 do H.step(c,.01) end
 return health-b.health,c,a,b
end

test("load: the modifier held alone loads the fighter's own nature; it spends with the next strike",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
 assert(c:request(a,"ChakraLoad"))
 assert(a.chakraLoad and a.chakraLoad.nature=="Lightning","Sasuke's load is "..tostring(a.chakraLoad and a.chakraLoad.nature))
 local chakra=a.chakra
 assert(c:request(a,"Attack"))
 assert(a.pending.chakraFlow=="Lightning","the strike did not take the load")
 assert(a.chakraLoad==nil,"the load outlived the strike")
 assert(chakra-a.chakra>=Flow.Tune.Strike-.01,"the infused strike cost nothing")
 -- the load expires unused
 local c2,x,y=H.duel("Mirage","Flashstep")
 place(c2,x,y,V.new(0,3,10),V.new(0,3,-10))
 assert(c2:request(x,"ChakraLoad"))
 H.step(c2,Flow.Tune.Life+.2)
 assert(Flow.active(c2,x)==nil,"the load never expired")
end)

test("strike: an infused light hits harder and reaches further",function()
 local plain=lightDamage("Lion",false)
 local infused=lightDamage("Lion",true)
 assert(plain>0,"setup: the plain light missed")
 assert(infused>plain*1.15,("infused %.1f vs plain %.1f"):format(infused,plain))
end)

test("natures: fire burns on, the gentle fist closes a point, wind throws further",function()
 -- fire: chips after the blow
 local _,c,a,b=lightDamage("Mirage",true)
 local after=b.health
 H.step(c,1.2)
 assert(b.health<after,"Itachi's infused strike did not burn on")
 -- wind (Naruto): the impulse is scaled past the common infusion
 local c2,x,y=H.duel("Legion","Flashstep")
 place(c2,x,y,V.new(0,3,10),V.new(0,3,-10))
 assert(c2:request(x,"ChakraLoad"));assert(c2:request(x,"Heavy"))
 local spec=x.pending.spec
 local base=H.Attacks.Heavy
 assert(spec.impulse.Magnitude>base.impulse.Magnitude*1.5,"the wind heavy throws no further")
 assert(spec.range>base.range+2,"the wind blade reaches no further")
end)

test("leap: a loaded jump goes higher than a plain one",function()
 local function apex(loaded)
  local c,a,b=H.duel("Legion","Flashstep")
  place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
  if loaded then assert(c:request(a,"ChakraLoad")) end
  assert(c:request(a,"Jump"),"jump refused")
  return a.root.AssemblyLinearVelocity.Y,a
 end
 local plain=apex(false)
 local leap,a=apex(true)
 assert(leap>plain*1.2,("leap %.1f vs plain %.1f"):format(leap,plain))
 assert(a.chakraLoad==nil,"the leap did not spend the load")
end)

test("dash: loaded, the dodge dashes at him on the ground (no sprint, no lock) and in the air",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 a.sprinting=false;a.locked=true
 assert(c:request(a,"ChakraLoad"))
 assert(c:request(a,"Dodge"),"loaded dodge refused")
 assert(a.state=="Rush","the loaded dodge is "..tostring(a.state).." not a chakra dash")
 -- air: a jump, the load, the dodge = the chase at him
 local c2,x,y=H.duel("Lion","Flashstep")
 place(c2,x,y,V.new(0,3,14),V.new(0,3,-14))
 assert(c2:request(x,"Jump"));H.step(c2,.15)
 assert(x.airborne,"setup: not airborne")
 assert(c2:request(x,"ChakraLoad"))
 assert(c2:request(x,"Dodge"),"loaded air dodge refused")
 assert(x.state=="Pursuit","the loaded air dodge is "..tostring(x.state).." not an air chakra dash")
 -- unloaded, the dodge stays a dodge
 local c3,p,q=H.duel("Lion","Flashstep")
 place(c3,p,q,V.new(0,3,14),V.new(0,3,-14))
 c3:request(p,"Dodge")
 assert(p.state~="Rush" and p.state~="Pursuit","a plain dodge dashed")
end)

test("tool: loaded, the tool is the fighter's chakra throw without the chord",function()
 local c,a,b=H.duel("Flashstep","GentleFist")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 assert(c:request(a,"ChakraLoad"))
 assert(c:request(a,"Tool",b.root.Position),"loaded tool refused")
 local infused
 for _=1,30 do H.step(c,.01);for _,p in c.projectiles do if p.a==a and p.infusion then infused=p.infusion end end end
 assert(infused,"the loaded throw carried no chakra")
end)

test("snapshot: the load and the infused strike reach the client",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
 assert(c:request(a,"ChakraLoad"))
 local s=H.snapshot and H.snapshot(c)
 if s then
  local me=s.human or s.bot
  assert(me.chakraLoad=="Lightning" or (s.bot and s.bot.chakraLoad=="Lightning"),"the load is not in the snapshot")
 end
 local seen=false
 for _,i in c.impacts or {} do if i.style=="chakraload" then seen=true end end
 assert(seen,"no load impact for the client")
end)

test("client: the load glows, the infused limbs pour, every nature's contact, the leap and the dash draw (stub scene)",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  local layer
  for _,l in FX.layers do if l.name=="ChakraFlow" then layer=l end end
  assert(layer,"the ChakraFlow layer is not installed")
  local folder=instance("Folder")
  local m=instance("Model");m.Name="A";m.Parent=folder
  for _,n in {"HumanoidRootPart","UpperTorso","RightHand","LeftHand","RightFoot","LeftFoot","Head"} do
   local p=instance("Part");p.Name=n;p.CFrame=H.C.new(V.new(0,3,0));p.Size=V.new(1,1,1);p.Transparency=0;p.Parent=m
  end
  local actor={id="A",fighterId="Lion",chakraLoad="Lightning",state="Neutral"}
  layer.fighter(fx,m,actor,1/60)
  local root=m:FindFirstChild("HumanoidRootPart")
  local aura=root:FindFirstChild("ChakraFlowAura")
  assert(aura,"no aura on the loaded body")
  assert(aura:FindFirstChild("Rise").Enabled==true,"the aura is not rising")
  -- the strike out: the limbs pour, the load spent
  actor.chakraLoad=nil;actor.infused="Lightning";actor.attackName="Light1";actor.state="Active"
  layer.fighter(fx,m,actor,1/60)
  assert(aura:FindFirstChild("Rise").Enabled==false,"the aura outlived the load")
  local limb=m:FindFirstChild("RightHand"):FindFirstChild("ChakraFlowLimb")
  assert(limb and limb:FindFirstChild("Infused").Enabled==true,"the striking hand does not pour chakra")
  actor.state="Recovery";layer.fighter(fx,m,actor,1/60)
  assert(limb:FindFirstChild("Infused").Enabled==false,"the hand still pours after the strike")
  for _,nature in {"Lightning","Fire","Wind","GentleFist","Sand","Strength","Chakra","Unknown"} do
   for _,style in {"chakraload","chakrastrike","chakrahit","chakraleap","chakradash"} do
    layer.impact(fx,{style=style,position=V.new(0,3,0),nature=nature,owner="A",victim="B",direction=V.zAxis,heavy=true,guarded=nature=="Wind",air=nature=="Fire"},folder)
   end
  end
  assert(layer.impact(fx,{style="slam",position=V.zero},folder)==false,"the layer swallowed another style")
 end)
 restore()
 assert(ok,err)
end)

print("NinjaDuel chakra flow: "..passed.." PASS")
