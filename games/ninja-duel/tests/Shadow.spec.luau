-- (12/11) The game casts shadows: effects of light cast none, rocks and
-- debris keep theirs (Client/ShadowFX). Headless: the rule on parts and
-- models, and the solid effects that must ask for their shadow.
local H=require("./Harness")
local roblox=require("@lune/roblox")
local fs=require("@lune/fs")
H.envBase.Instance=roblox.Instance
local Instance=roblox.Instance
local ShadowFX=H.load("Client/ShadowFX")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function part(parent,name)
 local p=Instance.new("Part");p.Name=name or "Part";p.CastShadow=true;p.Parent=parent;return p
end
test("a light part in the effects folder casts no shadow",function()
 local folder=Instance.new("Folder")
 local orb=part(folder,"KatonOrb")
 local inner=Instance.new("Model");inner.Parent=folder
 local bolt=part(inner,"Bolt")
 ShadowFX.watch(folder)
 assert(orb.CastShadow==false,"orb casts a shadow")
 assert(bolt.CastShadow==false,"nested light casts a shadow")
end)
test("a rock (KeepShadow on it or on its model) keeps its shadow",function()
 local folder=Instance.new("Folder")
 local rock=part(folder,"Rock");rock:SetAttribute("KeepShadow",true)
 local dog=Instance.new("Model");dog:SetAttribute("KeepShadow",true);dog.Parent=folder
 local leg=part(dog,"Leg")
 ShadowFX.watch(folder)
 assert(rock.CastShadow==true and leg.CastShadow==true,"solid effect lost its shadow")
 local later=part(folder,"Pebble");later.CastShadow=false
 ShadowFX.keep(later)
 assert(later.CastShadow==true and later:GetAttribute("KeepShadow")==true,"keep() did not set it")
 ShadowFX.apply(later,folder)
 assert(later.CastShadow==true,"the guard took it back")
end)
test("light helpers outside the folder",function()
 local p=part(nil,"Anchor")
 ShadowFX.light(p)
 assert(p.CastShadow==false)
 assert(ShadowFX.keep(nil)==nil and ShadowFX.light(nil)==nil,"nil not tolerated")
end)
test("the solid effects ask for their shadow",function()
 local function has(path,needle) return string.find(fs.readFile(path),needle,1,true)~=nil end
 assert(has("src/Client/ChakraFlowFX.luau",'rock.Name="ChakraPebble";ShadowFX.keep(rock)'),"pebbles")
 assert(has("src/Client/ChakraFlowFX.luau","ShadowFX.keep(spike)"),"earth spike")
 assert(has("src/Client/GroundFX.luau",'block.Name="GroundBlock";ShadowFX.keep(block)'),"ground blocks")
 assert(has("src/Client/HoundFX.luau",'m:SetAttribute("KeepShadow",true)'),"hounds")
 assert(has("src/Client/Effects.luau",'pcall(holder.SetAttribute,holder,"KeepShadow",true)'),"substitution log")
 assert(has("src/Client/Effects.luau","ShadowFX).watch(folder)"),"the guard is not installed")
 -- (13/11 integration with #77) The ultimates' rocks are modelled now and all
 -- come from one helper, UltimateFX.stone: it keeps the shadow of both kinds.
 local ultimate=fs.readFile("src/Client/UltimateFX.luau")
 assert(string.find(ultimate,"return ShadowFX.keep(r)",1,true) and string.find(ultimate,"return ShadowFX.keep(K.block(parent",1,true),"ultimate rocks: the stone helper does not keep their shadow")
 local _,stones=string.gsub(ultimate,"[^%w]stone%(","")
 assert(stones>=2,"the crater's and the gates' rocks no longer come from the stone helper: "..stones)
end)
print(passed.." passed")
