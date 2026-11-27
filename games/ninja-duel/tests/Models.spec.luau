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
 for _,name in {"Kunai","MarkedKunai","Shuriken","Tanto","SandCoffin","SandPillar","SandClump","WaterDragonHead","WaterDragonSeg","EarthDragonHead","EarthDragonSeg","Rock","Katana","TsukuyomiCross","BandageWrap","Trigrams","GroundCrack","GroundCrater","LegWeight","Ninken1","NinkenLeg4","FumaShuriken","ExplosiveTag","EarthWall","EarthHand","FlameMidLion","FlameOuter","KunaiRing","KunaiLong","Shuriken6","Shuriken8"} do
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
-- (26/11, read in a Play: 3 hair styles never built, « EditableMesh … memory
-- budget limits ») a refusal passes: the mesh is asked again, then given up
test("a mesh the memory budget refuses is asked again after a pause, then given up",function()
 local calls,paused=0,{}
 local em=MeshKit.editable(function() calls+=1;if calls<3 then return nil end;return "mesh" end,function(t) table.insert(paused,t) end)
 assert(em=="mesh" and calls==3 and #paused==2,"not asked again: "..calls)
 calls,paused=0,{}
 local none=MeshKit.editable(function() calls+=1;error("budget") end,function(t) table.insert(paused,t) end)
 assert(none==nil and calls==#MeshKit.RETRY+1 and #paused==#MeshKit.RETRY,"never given up: "..calls)
 local total=0;for _,t in MeshKit.RETRY do total+=t end
 assert(total<8 and MeshKit.SLOTS>=1 and MeshKit.SLOTS<=MeshKit.WORKERS,"too long a wait, or no slot")
end)
test("headless: nothing is built, model() is nil (primitives kept)",function()
 MeshKit.prepare()
 assert(MeshKit.model("Kunai")==nil)
 assert(not MeshKit.has("Kunai"))
end)
-- (27/11, passe 4: the Hokage cliff unseen from the village) A piece of the
-- village faces where it is seen from: the cliff's front faces the village
-- (+z, the gate's side), as built (MeshKit.FLIP turns a piece exported inside out)
test("the Hokage cliff faces the village",function()
 local spec
 for _,s in MeshKit.Data.HokageCliff or {} do if s.name=="Cliff" then spec=s end end
 assert(spec,"no cliff")
 assert(spec.flip==true and spec.asset==nil,"the cliff is not built turned (its published mesh is inside out)")
 local pos,_,tri=MeshKit.unpack(spec)
 local toward,away=0,0
 for k=1,#tri,3 do
  local a,b,c=tri[k],tri[k+1],tri[k+2]
  if spec.flip then b,c=c,b end
  local n=(pos[b]-pos[a]):Cross(pos[c]-pos[a])
  if n.Magnitude>1e-9 then
   local z=n.Unit.Z
   if z>.5 then toward+=n.Magnitude elseif z<-.5 then away+=n.Magnitude end
  end
 end
 assert(toward>away*4,string.format("the cliff's face looks away from the village: %.0f toward, %.0f away",toward,away))
end)
print(passed.." passed")
