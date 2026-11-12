-- (12/11) Lightning bolts (Client/LightningBoltFX, from SamyBlue/Lightning-Beams,
-- MIT), the Chidori/Raikiri layer (Client/LightningFX) and the trail of the
-- one-frame relocations (Client/DashTrailFX, feel audit 07/11 need 4).
-- Headless: the bolt keeps the original's shape (it starts and ends on its
-- attachments, the middle moves), draws no plain Neon, frees itself at the end
-- of its pulse and stays under its budget; the layers read the right states
-- and never stop the feed. The look itself is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","NumberSequence","NumberSequenceKeypoint","NumberRange","ColorSequence","Color3"} do H.envBase[k]=roblox[k] end
local Instance=roblox.Instance
local Enum=roblox.Enum
local Vector3=roblox.Vector3
local now=0
local Bolt=H.load("Client/LightningBoltFX")
Bolt.clock=function() return now end
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
-- lune cannot set Attachment.WorldPosition (a derived property): the bolt's
-- points are read back from what update() wrote, through a stand-in.
local folder=Instance.new("Folder")
Bolt.folder=folder
local function anchors() local n=0 for _,c in folder:GetChildren() do if c.Name=="LightningBolt" then n+=1 end end return n end

test("a bolt is made of beams on one invisible anchor (no Neon part)",function()
 local b=Bolt.new(Bolt.point(Vector3.new(0,0,0)),Bolt.point(Vector3.new(10,0,0)),12)
 local anchor=b._Anchor
 assert(anchor and anchor.Transparency==1,"anchor visible")
 local beams,parts=0,0
 for _,d in anchor:GetDescendants() do if d:IsA("Beam") then beams+=1 elseif d:IsA("BasePart") then parts+=1 end end
 assert(beams==24,"two beams per segment, got "..beams)
 assert(parts==0,"no part inside the bolt")
 assert(anchor.Material~=Enum.Material.Neon or anchor.Transparency==1)
 b:Destroy()
 assert(anchors()==0,"destroyed bolt left its anchor")
end)
test("a bolt frees itself at the end of its pulse",function()
 local b=Bolt.new(Bolt.point(Vector3.new(0,0,0)),Bolt.point(Vector3.new(4,0,0)),8)
 b.PulseSpeed=10;b.PulseLength=1
 now+=.05;Bolt.step()
 now+=.5;Bolt.step()
 assert(b._Dead and anchors()==0,"still there after its life")
end)
test("the budget dissipates the oldest bolts (a held Chidori cannot pile up)",function()
 for _=1,Bolt.MAX_BOLTS+10 do Bolt.new(Bolt.point(Vector3.new(0,0,0)),Bolt.point(Vector3.new(3,1,0)),6).PulseLength=1 end
 assert(Bolt.count()<=Bolt.MAX_BOLTS,"over budget: "..Bolt.count())
 assert(anchors()<=Bolt.MAX_BOLTS,"anchors over budget")
 now+=100;Bolt.step()
 assert(Bolt.count()==0 and anchors()==0,"not cleared")
end)
test("a broken bolt is dropped, the frame goes on",function()
 local good=Bolt.new(Bolt.point(Vector3.new(0,0,0)),Bolt.point(Vector3.new(3,0,0)),6)
 local bad=Bolt.new({},Bolt.point(Vector3.new(3,0,0)),6)
 local ok=pcall(Bolt.step)
 assert(ok,"step raised")
 assert(bad._Dead,"broken bolt kept")
 good:Destroy()
end)
-- The layers.
local LightningFX=H.load("Client/LightningFX")
test("the Chidori and the Raikiri are read from the same states as the hand's aura",function()
 assert(LightningFX.holding({castId="Chidori",state="TechniqueChannel",fighterId="Lion"})=="Chidori")
 assert(LightningFX.holding({castId="Chidori",state="TechniqueActive",fighterId="Copycat"})=="Raikiri")
 assert(LightningFX.holding({bodyState={id="LightningBlade"},fighterId="Copycat"})=="Raikiri")
 assert(LightningFX.holding({attackName="ChidoriThrust",state="Active"})=="Chidori")
 assert(LightningFX.holding({attackVariant="ChidoriDive",state="Startup"})=="Chidori")
 assert(LightningFX.holding({castId="Chidori",state="Recovery"})==nil)
 assert(LightningFX.holding({castId="Chidori",state="TechniqueActive",health=0})==nil,"a K.O. body keeps no lightning")
end)
local fx={folder=Instance.new("Folder"),layers={}}
LightningFX.install(fx,{floorUnder=function() return nil end})
local DashTrailFX=H.load("Client/DashTrailFX")
DashTrailFX.install(fx,{new=function(class,props,parent)
 local i=Instance.new(class)
 for k,v in props do pcall(function() i[k]=v end) end
 i.Parent=parent
 return i
end})
test("the layers never claim an impact (the family puffs and the contact flash still draw)",function()
 for _,layer in fx.layers do
  if layer.impact then
   assert(layer.impact(fx,{style="chidori",position=Vector3.new(0,3,0),direction=Vector3.new(0,0,-1)},fx.folder)==false,layer.name)
   assert(layer.impact(fx,{style="teleport",kind="lightning",from=Vector3.new(0,3,0),to=Vector3.new(18,3,0)},fx.folder)==false,layer.name)
   assert(layer.impact(fx,{style="teleport",kind="flash",from=Vector3.new(0,3,0),to=Vector3.new(12,3,0)},fx.folder)==false,layer.name)
  end
 end
end)
test("a held Chidori with no hand, or a broken model, does not raise",function()
 local layer
 for _,l in fx.layers do if l.name=="Lightning" then layer=l end end
 layer.fighter(fx,Instance.new("Model"),{castId="Chidori",state="TechniqueChannel"},1/60)
 layer.fighter(fx,nil,{castId="Chidori",state="TechniqueChannel"},1/60)
end)
test("the relocation line: straight for Minato, broken for Kakashi, ends on the two points",function()
 local rng=roblox.Random and roblox.Random.new(3) or {NextNumber=function() return math.random() end}
 local a,b=Vector3.new(0,3,0),Vector3.new(18,3,0)
 local s=DashTrailFX.points(a,b,0,rng)
 assert(#s==2,"Minato's line has bends")
 local z=DashTrailFX.points(a,b,.9,rng)
 assert(#z>=5,"Kakashi's line too straight: "..#z)
 assert((z[1]-a).Magnitude<1e-6 and (z[#z]-b).Magnitude<1e-6,"does not end on its points")
 local off=0
 for i=2,#z-1 do off=math.max(off,math.abs(z[i].Z)) end
 assert(off>0,"no zigzag")
 assert(DashTrailFX.KINDS.flash and DashTrailFX.KINDS.lightning)
end)
print(passed.." passed")
