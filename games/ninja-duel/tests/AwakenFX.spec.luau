-- Lot 3 animation (08/11): each awakening keeps its own look for the whole
-- state (Client/AwakenFX). Headless: every beta fighter has a recipe, the
-- state builds once (not every frame), uses no plain Neon, and goes away
-- when the awakening ends. The look itself is a Studio check.
local H=require("./Harness")
local roblox=require("@lune/roblox")
-- (real Roblox instances here: the layer sets emitter properties)
local saved={}
for _,k in {"Instance","NumberSequence","NumberSequenceKeypoint","NumberRange","ColorSequence","Color3"} do saved[k]=H.envBase[k];H.envBase[k]=roblox[k] end
local AwakenFX=H.load("Client/AwakenFX")
local Instance=roblox.Instance
local Enum=roblox.Enum
local Vector3=roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local BETA={"Lion","Legion","Sand","Leaf","GentleFist","Mirage","Copycat","Flashstep"}
local PARTS={"HumanoidRootPart","Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
 "LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
local function body()
 local model=Instance.new("Model")
 for _,name in PARTS do local p=Instance.new("Part");p.Name=name;p.Size=Vector3.new(1,1,1);p.Parent=model end
 return model
end
local function count(model,enabledOnly)
 local n=0
 for _,d in model:GetDescendants() do if d:IsA("ParticleEmitter") and (not enabledOnly or d.Enabled) then n+=1 end end
 return n
end
local layer
local fx={folder=Instance.new("Folder"),auras={},layers={}}
AwakenFX.install(fx,{floorUnder=function() return nil end})
layer=fx.layers[1]

test("every beta fighter's awakening has its own look",function()
 for _,id in BETA do assert(AwakenFX.RECIPES[id] and AwakenFX.RECIPES[id].hold,id..": no recipe") end
end)
test("the look is built once, held through the state, and cleared when it ends",function()
 for _,id in BETA do
  local model=body()
  local actor={fighterId=id,awaken=8,health=50,events={Awaken=1},speed=30,gate=2}
  layer.fighter(fx,model,actor,1/60)
  local first=count(model)
  assert(first>0,id..": nothing on the body")
  for _=1,30 do layer.fighter(fx,model,actor,1/60) end
  assert(count(model)==first,id..": rebuilt while it lasts ("..first.." -> "..count(model)..")")
  actor.awaken=0
  layer.fighter(fx,model,actor,1/60)
  assert(count(model,true)==0,id..": still burning after the awakening")
 end
end)
test("no plain Neon in the awakenings (VFX bible, 06/11)",function()
 for _,id in BETA do
  local model=body()
  layer.fighter(fx,model,{fighterId=id,awaken=8,health=50,events={Awaken=2}},1/60)
  for _,d in model:GetDescendants() do if d:IsA("BasePart") then assert(d.Material~=Enum.Material.Neon,id..": Neon part "..d.Name) end end
  for _,d in fx.folder:GetDescendants() do if d:IsA("BasePart") then assert(d.Transparency>=1 or d.Material~=Enum.Material.Neon,id..": Neon in the entry") end end
 end
end)
test("a fault in a recipe never stops the frame",function()
 local saved=AwakenFX.RECIPES.Lion.hold
 AwakenFX.RECIPES.Lion.hold=function() error("boom") end
 local ok=pcall(layer.fighter,fx,body(),{fighterId="Lion",awaken=8,health=50,events={Awaken=3}},1/60)
 AwakenFX.RECIPES.Lion.hold=saved
 assert(ok,"the error reached Effects")
end)
test("the images are fetched at start; one Roblox will not serve gets a built-in stand-in",function()
 local list=AwakenFX.preloadList()
 assert(#list>=10,"preload list too short ("..#list..")")
 local spark=AwakenFX.ID.spark
 local provider={PreloadAsync=function(_,ids,cb)
  for _,id in ids do if cb then cb(id,if id==spark then Enum.AssetFetchStatus.Failure else Enum.AssetFetchStatus.Success) end end
 end}
 H.envBase.task=H.envBase.task or {}
 local failed=AwakenFX.preload(provider)
 assert(#failed==1 and failed[1]==spark,"failure not kept")
 local part=Instance.new("Part")
 local e=AwakenFX.emitter(part,"spark",{Rate=1})
 assert(e.Texture~=spark and string.find(e.Texture,"rbxasset://",1,true),"no stand-in for an image that fails")
 AwakenFX.failed[spark]=nil
end)
for k,v in saved do H.envBase[k]=v end
print(string.format("NinjaDuel awakenings: %d PASS (headless; the look is a Studio check)",passed))
