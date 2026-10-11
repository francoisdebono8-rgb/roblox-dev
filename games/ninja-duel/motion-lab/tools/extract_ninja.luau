-- Build-time extraction of TRUSTED repository code. Never shipped/executed in plugin.
local fs=require("@lune/fs");local serde=require("@lune/serde")
local H=require("../../tests/Harness")
local source=fs.readFile("src/Client/VelmoraMotionEngine.luau")
assert(source:match("return Motion%s*$"),"Motion source contract changed")
source=source:gsub("return Motion%s*$","return {stances=STANCE,clips=CLIPS,gaits=GAIT}")
local fn=assert(loadstring(source,"MotionLabBuildExtraction"))
setfenv(fn,setmetatable({require=H.load,script={Parent={}}},{__index=function(_,k)return H.envBase[k] or getfenv()[k]end}))
local data=fn();data.fighters={};data.attacks={}
for id,f in H.load("Shared/Fighters") do data.fighters[id]={name=f.Name,attackProfile=f.AttackProfile} end
for id,a in H.load("Shared/Attacks") do data.attacks[id]={startup=a.startup,active=a.active,recovery=a.recovery} end
fs.writeFile("motion-lab/ForgeMotionLab/Modules/NinjaSources.luau",'-- Generated from current Ninja Duel definitions; data only.\nreturn game:GetService("HttpService"):JSONDecode([==[\n'..serde.encode("json",data)..'\n]==])\n')
print("Extracted authored stances, clips, gaits and timing definitions")
