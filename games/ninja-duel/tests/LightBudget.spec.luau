-- (OUTILLEUR, F7, 08/11) At most 8 effect lights lit at once, never with a
-- shadow; decor lights are not touched (Client/LightBudgetFX).
local H=require("./Harness")
local roblox=require("@lune/roblox")
local LB=H.load("Client/LightBudgetFX")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Instance,Vector3=roblox.Instance,roblox.Vector3

test("the budget keeps the brightest, widest, nearest lights and ignores those at 0",function()
 local list={}
 for i=1,19 do table.insert(list,{light=i,brightness=i/10,range=10,distance=0}) end
 table.insert(list,{light="dark",brightness=0,range=40,distance=0})
 local keep=LB.choose(list,8)
 local n=0 for _ in keep do n+=1 end
 assert(n==8,"kept "..n)
 assert(keep[19] and keep[12] and not keep[11] and not keep["dark"],"wrong lights kept")
 local near=LB.choose({{light="far",brightness=2,range=10,distance=300},{light="near",brightness=1.5,range=10,distance=2}},1)
 assert(near.near and not near.far,"a far light took the place of a near one")
end)

test("19 effect lights in a duel: 8 lit, no shadow; when they go out the others come back",function()
 local lights={}
 for i=1,19 do
  local part=Instance.new("Part");part.Position=Vector3.new(i,0,0)
  local l=Instance.new("PointLight");l.Brightness=1+i*.1;l.Range=10;l.Shadows=true;l.Parent=part
  -- (headless: the ancestry test needs a real workspace; tracked directly)
  LB.tracked[l]=true
  table.insert(lights,l)
 end
 LB.step(Vector3.new(0,0,0))
 local lit=0
 for _,l in lights do if l.Enabled then lit+=1 end; assert(l.Shadows==false,"an effect light still casts a shadow") end
 assert(lit==LB.MAX,"lit "..lit)
 for i=12,19 do lights[i].Brightness=0 end -- the eight brightest go out
 LB.step(Vector3.new(0,0,0))
 lit=0
 for i=1,11 do if lights[i].Enabled then lit+=1 end end
 assert(lit==8,"the waiting lights did not come back ("..lit..")")
 for i=1,19 do LB.tracked[lights[i]]=nil end
end)

test("decor lights are not effect lights",function()
 local ws=Instance.new("Model");ws.Name="ws"
 local light=Instance.new("PointLight")
 assert(LB.isEffectLight(light)==false,"a loose light counted")
end)
print(string.format("NinjaDuel light budget: %d PASS",passed))
