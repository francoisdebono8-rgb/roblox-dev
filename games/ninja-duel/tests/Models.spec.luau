-- (13/11) The modelled props (Client/MeshKit, data from tools/blender/fx_models.py):
-- every packed mesh decodes to what was written, and without the engine's
-- EditableMesh (headless) nothing is built and callers keep their primitives.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","Vector3","Color3","CFrame","Enum"} do H.envBase[k]=roblox[k] end
local MeshKit=H.load("Client/MeshKit")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
test("the props the game asks for are all modelled",function()
 for _,name in {"Kunai","MarkedKunai","Shuriken","Tanto","SandCoffin","SandPillar","SandClump","WaterDragonHead","WaterDragonSeg","EarthDragonHead","EarthDragonSeg"} do
  assert(MeshKit.Data[name],"missing model "..name)
 end
end)
test("every piece decodes: counts, bounds, triangles, colours",function()
 local pieces=0
 for name,list in MeshKit.Data do
  for _,spec in list do
   local pos,col,tri=MeshKit.unpack(spec)
   assert(#pos==spec.n and #col==spec.n and #tri==spec.m*3,name.."/"..spec.name.." counts")
   for _,p in pos do
    assert(math.abs(p.X)<=spec.h[1]+1e-3 and math.abs(p.Y)<=spec.h[2]+1e-3 and math.abs(p.Z)<=spec.h[3]+1e-3,name.." vertex outside its bounds")
   end
   for _,i in tri do assert(i>=1 and i<=spec.n,name.." bad index") end
   assert(spec.m>=8,name.." has almost no faces")
   pieces+=1
  end
 end
 assert(pieces>=12,"too few pieces: "..pieces)
end)
test("weapons keep the part-built frames: grip at the origin, point to the front (-z)",function()
 local function extent(name)
  local lo,hi=math.huge,-math.huge
  for _,spec in MeshKit.Data[name] do
   lo=math.min(lo,spec.o[3]-spec.h[3]);hi=math.max(hi,spec.o[3]+spec.h[3])
  end
  return lo,hi
 end
 local lo,hi=extent("Kunai")
 assert(lo<-.9 and lo>-1.1 and hi>.6 and hi<.75,("kunai %.2f..%.2f"):format(lo,hi))
 lo,hi=extent("Tanto")
 assert(lo<-1.85 and hi>.5,("tanto %.2f..%.2f"):format(lo,hi))
end)
test("headless: nothing is built, model() is nil (primitives kept)",function()
 MeshKit.prepare()
 assert(MeshKit.model("Kunai")==nil)
 assert(not MeshKit.has("Kunai"))
end)
print(passed.." passed")
