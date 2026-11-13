-- (13/11, issue #73) The Sharingan per fighter and per form, Kakashi's ONE
-- eye, Itachi's Mangekyō at its moments only, the soft burn under the Great
-- Fireball, the Chidori that stays in the hand, Kakashi's seals.
-- Headless: the settings, the drawings (real commas, counted), the tint on
-- one eye, the burn instead of the star, the riding points, the seal beats.
-- The look itself is a Studio check (medium shot, 8 studs).
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","UDim","UDim2","NumberSequence","NumberSequenceKeypoint","ColorSequence","NumberRange","Color3","Vector2"} do H.envBase[k]=roblox[k] end
local Instance=roblox.Instance
local Face=H.load("Shared/Face")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function visible(drawing)
 local n=0
 for _,c in drawing:GetChildren() do if c.Name=="Tomoe" and c.Visible then n+=1 end end
 return n
end
test("tomoe per fighter and per form (François 13/11)",function()
 assert(Face.tomoeFor("Lion")==2 and Face.tomoeFor("Copycat")==2,"Sasuke / Kakashi base")
 assert(Face.tomoeFor("Mirage")==3 and Face.tomoeFor("Flicker")==3 and Face.tomoeFor("Rival")==3,"Itachi / Shisui / Madara")
 assert(Face.tomoeFor("Lion",true)==3 and Face.tomoeFor("Copycat",true)==3,"awakened: 3 for now")
 assert(Face.tomoeFor("Sasuke")==2 and Face.tomoeFor("Shisui")==3 and Face.tomoeFor("Madara")==3,"by look name")
 assert(Face.SHARINGAN.Mirage.mangekyo==true,"Itachi has the Mangekyō")
 for id,s in Face.SHARINGAN do if id~="Mirage" then assert(not s.mangekyo,id.." has a Mangekyō") end end
 -- a setting: change it and it follows
 local keep=Face.SHARINGAN.Lion.awake
 Face.SHARINGAN.Lion.awake=2
 assert(Face.tomoeFor("Lion",true)==2,"the setting is not read")
 Face.SHARINGAN.Lion.awake=keep
end)
test("real commas: a head and a tapered tail, 1, 2 or 3 shown",function()
 local iris=Instance.new("Frame")
 local d=Face.drawSharingan(iris,2)
 assert(d.Name=="Sharingan" and d.Parent==iris)
 local heads=0
 for _,c in d:GetChildren() do
  if c.Name=="Tomoe" then
   heads+=1
   local tail=c:FindFirstChild("Tail")
   assert(tail and tail:FindFirstChildOfClass("UIGradient"),"a comma without its tapered tail")
  end
 end
 assert(heads==3,"three comma slots")
 assert(visible(d)==2,"2 commas: "..visible(d))
 Face.setTomoe(d,1);assert(visible(d)==1)
 Face.setTomoe(d,3);assert(visible(d)==3)
 assert(d:GetAttribute("Tomoe")==3)
end)
local function fakeFace(mangekyo)
 local face={eyes={}}
 for _,side in {-1,1} do
  local gui=Instance.new("SurfaceGui")
  local iris=Instance.new("Frame");iris.Parent=gui
  local pupil=Instance.new("Frame");pupil.Parent=iris
  local e={side=side,gui=gui,iris=iris,pupil=pupil,tomoe={},sharingan=Face.drawSharingan(iris,3)}
  if mangekyo then e.mangekyo=Face.drawMangekyo(iris) end
  table.insert(face.eyes,e)
 end
 return face
end
test("Kakashi: one eye, his left; the other stays his own",function()
 local face=fakeFace(false)
 local brown=face.eyes[2].iris.BackgroundColor3
 Face.tint(face,roblox.Color3.fromRGB(226,30,40),"sharingan",-1,2)
 local left,right=face.eyes[1],face.eyes[2]
 assert(left.sharingan.Visible and visible(left.sharingan)==2,"the left eye is not a 2-tomoe Sharingan")
 assert(not right.sharingan.Visible,"the right eye turned too")
 assert(right.iris.BackgroundColor3==brown,"the right eye changed colour")
 Face.tint(face,nil)
 assert(not left.sharingan.Visible,"not restored")
end)
test("Itachi: the Mangekyō replaces the commas, only when asked",function()
 local face=fakeFace(true)
 Face.tint(face,roblox.Color3.fromRGB(214,30,36),"sharingan",nil,3)
 for _,e in face.eyes do assert(e.sharingan.Visible and not e.mangekyo.Visible,"Mangekyō shown in the normal Sharingan") end
 Face.tint(face,roblox.Color3.fromRGB(230,24,32),"mangekyo")
 for _,e in face.eyes do assert(e.mangekyo.Visible and not e.sharingan.Visible and not e.pupil.Visible,"no Mangekyō") end
 -- a face without one (Sasuke) asked for it gets 3 commas, never a pinwheel
 local plain=fakeFace(false)
 Face.tint(plain,roblox.Color3.fromRGB(230,24,32),"mangekyo")
 for _,e in plain.eyes do assert(e.sharingan.Visible and visible(e.sharingan)==3) end
end)
test("the Mangekyō has its moment and goes",function()
 local now=10
 local clock=function() return now end
 local model=Instance.new("Model")
 assert(not Face.mangekyoOn(model,clock))
 Face.mangekyoFor(model,3,clock)
 now=12;assert(Face.mangekyoOn(model,clock),"off during the Tsukuyomi")
 now=13.1;assert(not Face.mangekyoOn(model,clock),"still on after it")
end)
test("the code calls: Itachi's Tsukuyomi, Kakashi's one eye, no black star",function()
 local fs=require("@lune/fs")
 local ult=fs.readFile("src/Client/UltimateFX.luau")
 assert(string.find(ult,"Face.mangekyoFor(ctx.casterModel",1,true),"the ultimate's eye does not turn")
 local fx=fs.readFile("src/Client/Effects.luau")
 assert(string.find(fx,'local only=if id=="Copycat" then -1 else nil',1,true),"Kakashi's tint is not one eye")
 assert(string.find(fx,"LockedToPart=true},at)",1,true),"the Chidori sparks are left behind at a run")
 local kit=fs.readFile("src/Client/VfxKit.luau")
 assert(string.find(kit,'if texture=="scorch" then return Kit.burn(',1,true),"the scorch is still the radial star")
end)
local LightningFX=H.load("Client/LightningFX")
test("the Chidori's arcs ride on the hand",function()
 local hand={CFrame=roblox.CFrame.new(0,3,0)}
 local p=LightningFX.onPart(hand,roblox.Vector3.new(0,-.35,0))
 assert((p.WorldPosition-roblox.Vector3.new(0,2.65,0)).Magnitude<1e-4)
 hand.CFrame=roblox.CFrame.new(20,3,5)
 assert((p.WorldPosition-roblox.Vector3.new(20,2.65,5)).Magnitude<1e-4,"the point stayed where the hand was")
end)
local SealFX=H.load("Client/SealFX")
test("Kakashi's seals: woven in the channel of a seal jutsu, by nature",function()
 assert(SealFX.weaving({fighterId="Copycat",state="TechniqueChannel",castId="EarthDragon"})=="earth")
 assert(SealFX.weaving({fighterId="Copycat",state="TechniqueChannel",castId="WaterDragon"})=="water")
 assert(SealFX.weaving({fighterId="Copycat",state="TechniqueActive",castId="EarthDragon"})==nil,"glow after the channel")
 assert(SealFX.weaving({fighterId="Lion",state="TechniqueChannel",castId="EarthDragon"})==nil,"not Kakashi")
 assert(SealFX.weaving({fighterId="Copycat",state="TechniqueChannel",castId="EarthDragon",health=0})==nil,"a K.O. body")
end)
print(passed.." passed")
