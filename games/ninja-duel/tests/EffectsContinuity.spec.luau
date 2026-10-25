-- Lifecycle regressions in a fight: a tool release, its contact, another
-- snapshot, then the next round must never create a duplicate or early flash.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error(name..": "..tostring(err),0) end
 passed+=1;print("PASS "..name)
end
local function scene(fn)
 local instance,restore=H.stubScene()
 local now=100
 H.workspace.GetServerTimeNow=function() return now end
 local sounds={}
 H.envBase.Instance={new=function(class)
  local obj=instance(class)
  if obj:IsA("BasePart") then obj.Transparency=0 end
  if class=="Sound" then obj.Play=function(self) table.insert(sounds,self) end end
  return obj
 end}
 local FX=H.load("Client/Effects")
 local fx=FX.new()
 local ok,err=pcall(fn,FX,fx,instance,function(t) now=t end,sounds)
 restore()
 assert(ok,err)
end
local function packet(projectiles,epoch)
 return {phase="Duel",epoch=epoch or 1,projectiles=projectiles or {},hazards={}}
end
local function flight(id,kind)
 return {id=id,kind=kind or "fireball",origin=V.new(15,5,20),direction=V.zAxis,speed=54,born=100,range=40,radius=2.4,growth=2.2}
end

test("a staged flight is located but silent and dark until its visual release",function()
 scene(function(FX,fx,_,setNow,sounds)
  fx:sync(packet({flight(1)}))
  local entry=fx.projectiles[1]
  assert((entry.root.Position-entry.data.origin).Magnitude<.001,"flight starts away from its origin")
  local switches=0
  for _,v in entry.switches do switches+=1;assert(v.object.Enabled==false,"staged effect is emitting") end
  assert(switches>=4,"fireball has no staged emitters/light")
  assert(#sounds==0,"release sound leads the hand")
  setNow(100+FX.DELAY-.001);fx:stepProjectiles(1/60)
  assert(entry.hidden and #sounds==0,"flight revealed before its release")
  setNow(100+FX.DELAY+.001);fx:stepProjectiles(1/60)
  assert(not entry.hidden and #sounds==1,"release did not reveal/sound once")
  for _,v in entry.switches do assert(v.object.Enabled==v.enabled,"release lost effect's authored state") end
  setNow(100+FX.DELAY+.02);fx:stepProjectiles(1/60)
  assert(#sounds==1,"flight sound repeats each frame")
 end)
end)

test("infused flights activate their staged chakra only when released",function()
 scene(function(FX,fx,_,setNow)
  local p=flight(1,"kunai");p.infusion="Fire"
  fx:sync(packet({p}))
  local entry=fx.projectiles[1]
  assert(entry.decor and #entry.decor.emitters>0,"infusion has no emitter")
  for _,emitter in entry.decor.emitters do assert(emitter.Enabled==false,"infusion starts before release") end
  setNow(100+FX.DELAY+.001);fx:stepProjectiles(1/60)
  for _,emitter in entry.decor.emitters do assert(emitter.Enabled==true,"released infusion stays disabled") end
 end)
end)

test("contact before spawn and stale snapshots cannot replay a projectile",function()
 scene(function(_,fx,_,_,sounds)
  -- A close throw can be born and hit inside one network interval.
  fx:sync(packet())
  fx:finishProjectile(7)
  fx:sync(packet({flight(7,"kunai")}))
  assert(fx.projectiles[7]==nil,"contacted flight was resurrected")
  fx:sync(packet({flight(8,"kunai")}))
  assert(fx.projectiles[8],"next legitimate flight was suppressed")
  fx:finishProjectile(8)
  fx:sync(packet({flight(8,"kunai")}))
  assert(fx.projectiles[8]==nil and #sounds==0,"silent spent flight reappeared or sounded")
  for i=10,400 do fx:finishProjectile(i) end
  assert(#fx.finishedOrder<=256,"flight tombstones are unbounded")
  fx:sync(packet({flight(7,"kunai")},2))
  assert(fx.projectiles[7],"new duel cannot reuse its projectile IDs")
 end)
end)

test("each world layer advances once per rendered frame",function()
 scene(function(FX,fx)
  local old=FX.layers
  local count,elapsed=0,0
  FX.layers={{frame=function(_,_,dt) count+=1;elapsed+=dt end}}
  local ok,err=pcall(function()for _=1,60 do fx:update(packet(),1/60,nil) end end)
  FX.layers=old
  assert(ok,err)
  assert(count==60 and math.abs(elapsed-1)<.001,"world effects run faster than the fight")
 end)
end)

test("epoch reset removes owned body effects and restores same-rig wear",function()
 scene(function(_,fx,instance)
  local model=instance("Model");model.Parent=instance("Folder")
  local torso=instance("Part");torso.Parent=model
  local original=H.roblox.Color3.fromRGB(80,90,100);torso.Color=H.roblox.Color3.fromRGB(40,40,40)
  local a0=instance("Attachment");a0.Parent=torso
  local a1=instance("Attachment");a1.Parent=torso
  local trail=instance("Trail");trail.Attachment0=a0;trail.Attachment1=a1;trail.Parent=torso
  local light=instance("PointLight");light.Parent=torso
  local mantle=instance("Attachment");mantle.Parent=torso
  local chidori=instance("Attachment");chidori.Parent=torso
  local mouth=instance("Attachment");mouth.Parent=torso
  local wear=instance("Part");wear.Name="BattleWear";wear.Parent=model
  local authored=instance("Part");authored.Name="ByakuganVein";authored.Parent=model
  fx.auras[model]={trail=trail,eyeLight=light,mantle={attachment=mantle},chidori={attachment=chidori},mouthAttachment=mouth,cloth={[torso]=original},wear=1}
  fx:reset()
  assert(next(fx.auras)==nil,"old rig state survived reset")
  for _,obj in {trail,a0,a1,light,mantle,chidori,mouth,wear} do assert(obj.Parent==nil,"owned body effect survived reset") end
  assert(torso.Color==original and authored.Parent==model,"reset damaged authored rig appearance")
 end)
end)

test("losing a held technique dissipates without inventing a hit flash",function()
 scene(function(_,fx,instance)
  local model=instance("Model");model.Parent=instance("Folder")
  for _,name in {"HumanoidRootPart","UpperTorso","RightHand","Head"} do
   local p=instance("Part");p.Name=name;p.CFrame=H.C.new(0,3,0);p.Parent=model
  end
  local actor={fighterId="Flashstep",health=100,maxHealth=100,state="TechniqueChannel",castId="BurstStrike"}
  fx:fighter(model,actor,1/60)
  assert(fx.rasengan[model],"charge never formed")
  local before=#fx.folder:GetChildren()
  actor.state="Neutral";actor.castId=nil
  fx:fighter(model,actor,1/60)
  assert(fx.rasengan[model]==nil,"charge stayed in the hand after cancellation")
  assert(#fx.folder:GetChildren()==before,"cancelled charge emitted a fake hit flash")
  actor.fighterId="Lion";actor.state="TechniqueChannel";actor.castId="Chidori"
  fx:fighter(model,actor,1/60)
  local charge=fx.auras[model].chidori
  assert(charge,"Chidori never formed")
  actor.state="Neutral";actor.castId=nil
  fx:fighter(model,actor,1/60)
  assert(charge.light.Enabled==false,"cancelled technique left a live hand light")
 end)
end)

test("fighter effects can follow the body's visual actor clock",function()
 scene(function(_,fx,instance)
  local folder=instance("Folder");local model=instance("Model");model.Name="A";model.Parent=folder
  local raw={id="A",castElapsed=.2};local visual={id="A",castElapsed=.14}
  local received
  fx.fighter=function(_,_,actor) received=actor end
  fx.seal=function() end
  local data=packet();data.human=raw
  fx:update(data,1/60,folder,{human=visual})
  assert(received==visual,"held construct clock differs from its casting body")
 end)
end)

test("ordinary tools have a hand model across families and volleys follow their actual releases",function()
 scene(function(_,_,instance)
  local Motion=H.load("Client/VelmoraMotionEngine")
  local function rig()
   local m=instance("Model")
   for _,name in {"LeftHand","RightHand"} do local p=instance("Part");p.Name=name;p.CFrame=H.C.new(4,5,6);p.Parent=m end
   return m
  end
  for _,id in {"Mist","Serpent","Rinnegan","Ink","Rival","Sapling","Professor"} do
   local m=rig();local kind=if id=="Professor" then "Shuriken" else "Kunai"
   Motion.weapon(m,{fighterId=id,state="Neutral",throwKind=kind,throwElapsed=.02,throwRelease=.1,throwCount=1})
   assert(Motion.weaponState(m).visible,id.." has no object in its throwing hand")
   Motion.weapon(m,{fighterId=id,state="Neutral",throwKind=kind,throwElapsed=.11,throwRelease=.1,throwCount=1})
   assert(not Motion.weaponState(m).visible,id.." retains a released tool")
  end
  local m=rig()
  for _,sample in {{.02,true},{.131,false},{.16,true},{.181,false},{.21,true},{.231,false}} do
   Motion.weapon(m,{fighterId="Mirage",state="Neutral",throwKind="Shuriken",throwElapsed=sample[1],throwRelease=.13,throwCount=3,throwInterval=.05})
   assert(Motion.weaponState(m).visible==sample[2],"volley hand disagrees with release at "..sample[1])
  end
  for _,id in {"Bone","Mirror","Clay","Puppet"} do
   local m=rig()
   Motion.weapon(m,{fighterId=id,state="Neutral",throwKind="Kunai",throwElapsed=.02,throwRelease=.1})
   assert(not Motion.weaponState(m).visible,id.." replaced its family tool with steel")
  end
 end)
end)

print(string.format("NinjaDuel effects continuity: %d PASS",passed))
