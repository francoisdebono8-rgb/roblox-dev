-- (DEC-040, 14/11) The ninja outfit's modelled pieces (Shared/OutfitMeshes,
-- data from tools/blender/outfit_models.py): every Shop outfit item has its
-- model, each piece sits on a real R15 body part, is painted by a colour slot
-- the item colours (or a listed new slot), decodes, and fits its part.
local H=require("./Harness")
local roblox=require("@lune/roblox")
for _,k in {"Instance","Vector3","Color3","CFrame","Enum"} do H.envBase[k]=roblox[k] end
local MeshKit=H.load("Client/MeshKit")
local Outfit=H.load("Shared/OutfitMeshes")
local Shop=H.load("Shared/Shop")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
test("every outfit item of the Shop that is worn has its model",function()
 local n=0
 for _,item in Shop.Items do
  if item.pieces and not item.none then
   assert(Outfit.forItem(item.id),"no model for "..item.id);n+=1
  end
 end
 assert(n>=20,"too few outfit items: "..n)
end)
test("each piece: a real body part, a slot the item colours, a sound mesh that fits its part",function()
 for id,model in Outfit.Items do
  local item=Shop.item(id)
  assert(item,"unknown Shop item "..id)
  for _,p in Outfit.Models[model] do
   local ref=Outfit.Ref[p.on]
   assert(ref,id..": unknown body part "..tostring(p.on))
   assert((item.colors and item.colors[p.slot]) or (Outfit.NewSlots[model] and Outfit.NewSlots[model][p.slot]),id..": slot "..p.slot.." has no colour")
   local pos,col,tri=MeshKit.unpack(p)
   assert(#pos==p.n and #tri==p.m*3,id.." counts")
   for _,i in tri do assert(i>=1 and i<=p.n,id.." bad index") end
   -- close to its part: within 2.2 part sizes of its centre (coat tails hang below)
   local o=roblox.Vector3.new(p.o[1],p.o[2],p.o[3])
   assert(math.abs(o.X)<ref.X*1.1 and math.abs(o.Z)<ref.Z*1.1 and math.abs(o.Y)<ref.Y*2.2+1.2,id.."/"..p.name.." far from its part")
  end
 end
end)
test("left and right are mirrors: a sleeve on each arm, a leg piece on each leg",function()
 for id,model in Outfit.Items do
  local count={}
  for _,p in Outfit.Models[model] do count[p.on]=(count[p.on] or 0)+1 end
  for on,k in count do
   local other=if string.sub(on,1,5)=="Right" then "Left"..string.sub(on,6) elseif string.sub(on,1,4)=="Left" then "Right"..string.sub(on,5) else nil
   if other then assert(count[other]==k,id..": "..on.." "..k.." vs "..other.." "..tostring(count[other])) end
  end
 end
end)
print("NinjaDuel outfit meshes: "..passed.." PASS")
