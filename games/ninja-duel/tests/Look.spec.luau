-- The game's light (Client/WorldLook), QA test of b822ee5 (12/11): the image
-- was burnt white, the world's shadows off. The setting François validated:
-- shadows on, Brightness 2.4, exposure -0.35, darker ambients, a bloom only on
-- what really shines. The built place carries GlobalShadows too (build.py).
local fs=require("@lune/fs")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local src=fs.readFile("src/Client/WorldLook.luau")
local function has(want) return string.find(src,want,1,true)~=nil end

test("the look keeps the world's shadows on and the validated light",function()
 for _,want in {"Brightness=2.4,ExposureCompensation=-.35,GlobalShadows=true","EnvironmentDiffuseScale=.5,EnvironmentSpecularScale=.4,ShadowSoftness=.18",
  "Ambient=rgb(60,56,72),OutdoorAmbient=rgb(96,92,112)"} do
  assert(has(want),"WorldLook's LIGHT no longer sets "..want)
 end
 -- Applied as a whole table on Lighting (each key, pcall'd).
 assert(has("for k,v in LIGHT do pcall(function() (Lighting::any)[k]=v end) end"),"WorldLook no longer applies LIGHT")
end)

test("the bloom, grade, air and rays are the validated ones",function()
 for _,want in {"Intensity=.3,Size=22,Threshold=2.2","Saturation=.22,Contrast=.26,Brightness=-.02,TintColor=rgb(255,246,236)","atmo.Glare=.2;atmo.Haze=1.1","Intensity=.04,Spread=.75"} do
  assert(string.find(src,want,1,true),"WorldLook no longer sets "..want)
 end
end)

test("the built places have the world's shadows on",function()
 for _,name in {"NinjaDuel","NinjaDuel-Debug","NinjaDuel-QA","NinjaDuel-Capture"} do
  local path="dist/"..name..".rbxlx"
  if fs.isFile(path) then
   local xml=fs.readFile(path)
   local lighting=string.match(xml,'<Item class="Lighting"[^>]*>.-</Properties>')
   assert(lighting and string.find(lighting,'<bool name="GlobalShadows">true</bool>',1,true),name..": GlobalShadows is not on in the built place")
  end
 end
end)

print(string.format("NinjaDuel look (light, QA 12/11): %d PASS",passed))
