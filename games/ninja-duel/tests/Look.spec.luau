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
-- (14/11) the values live in Shared/Look (server and client apply them).
local src=fs.readFile("src/Shared/Look.luau")
local function has(want) return string.find(src,want,1,true)~=nil end

test("the look keeps the world's shadows on and the validated light",function()
 for _,want in {"Brightness=2.4,ExposureCompensation=-.35,GlobalShadows=true","EnvironmentDiffuseScale=.5,EnvironmentSpecularScale=.4,ShadowSoftness=.18",
  "Ambient=rgb(60,56,72),OutdoorAmbient=rgb(96,92,112)"} do
  assert(has(want),"Look.LIGHT no longer sets "..want)
 end
 -- Applied as a whole table on Lighting (each key, written only if it differs).
 assert(has("for k,v in Look.values(studio) do set(lighting,k,v) end"),"Look no longer applies LIGHT")
end)

test("the bloom, grade, air and rays are the validated ones",function()
 for _,want in {"Intensity=.3,Size=22,Threshold=2.2","Saturation=.22,Contrast=.26,Brightness=-.02,TintColor=rgb(255,246,236)","Glare=.2,Haze=1.1","Intensity=.04,Spread=.75"} do
  assert(string.find(src,want,1,true),"Look no longer sets "..want)
 end
end)

-- (14/11, François: « les lumières n'apparaissent pas au même moment ») one
-- light: the server applies the client's look at its start; its arena build
-- no longer brings another sun; the client holds it on any change, and the
-- menu's studio goes through it.
test("one light: the server's start and arena use the client's look, held on every change",function()
 local main=fs.readFile("src/Server/Main.server.luau")
 assert(string.find(main,'require(Shared:WaitForChild("Look")).apply()',1,true),"the server no longer applies the look at its start")
 local world=fs.readFile("src/Server/World.luau")
 assert(not string.find(world,"ClockTime=14.6",1,true),"the arena brings its own sun again")
 assert(string.find(world,"Look.apply(",1,true),"the arena no longer applies the look")
 local client=fs.readFile("src/Client/WorldLook.luau")
 assert(string.find(client,"GetPropertyChangedSignal(k):Connect(hold)",1,true),"the client no longer holds the look on a change")
 local stage=fs.readFile("src/Client/MenuStage.luau")
 assert(string.find(stage,"WorldLook.setStudio(on)",1,true),"the menu's studio writes the lighting itself again")
end)

-- (14/11) the first screens load behind a curtain (Client/Curtain).
test("the curtain lifts once the first screens are fetched and the models built (the village dressed)",function()
 local H=require("./Harness")
 local Curtain=H.load("Client/Curtain")
 assert(not Curtain.ready({fetched=false}),"lifted before the first screens were fetched")
 assert(Curtain.ready({fetched=true}),"no models to wait for, yet still down")
 assert(not Curtain.ready({fetched=true,meshes="loading"}),"lifted while the models were built")
 assert(not Curtain.ready({fetched=true,meshes="ready",hub=true,dressed=false}),"lifted before the village was dressed")
 assert(Curtain.ready({fetched=true,meshes="ready",hub=true,dressed=true}))
 assert(Curtain.ready({fetched=true,meshes="failed"}),"a failed build holds the curtain")
 local later=Curtain.later({TEX={a="rbxassetid://1",b="rbxasset://textures/x.dds"}},"shared")
 assert(#later==2 and later[1]=="rbxassetid://1" and later[2]=="shared","the effects' images to fetch after")
 assert(Curtain.MAX<=8,"the curtain may hold too long")
 local main=fs.readFile("src/Client/Main.client.luau")
 local at=string.find(main,'require(script.Parent.Curtain).start(',1,true)
 assert(at and at<string.find(main,"local UI=require",1,true),"the curtain is not up first")
 local dress=fs.readFile("src/Client/HubDress.luau")
 assert(not string.find(dress,"task.wait(1)",1,true),"the village is dressed in waves again")
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
